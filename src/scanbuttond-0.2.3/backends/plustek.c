// plustek.c: Plustek device backend
// This file is part of scanbuttond.
// Copyleft )c( 2005 by Hans Verkuil
// Copyleft )c( 2005-2006 by Bernhard Stiftner
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation; either version 2 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <syslog.h>
#include "scanbuttond/scanbuttond.h"
#include "scanbuttond/libusbi.h"
#include "plustek.h"

static char* backend_name = "Plustek USB";

#define NUM_SUPPORTED_USB_DEVICES 8

static int supported_usb_devices[NUM_SUPPORTED_USB_DEVICES][3] = {
	// vendor, product, num_buttons
	{ 0x04a9, 0x2207, 1 },	// CanoScan N1220U
	{ 0x04a9, 0x2208, 1 },	// CanoScan CanoScan D660U
	{ 0x04a9, 0x2206, 1 },	// CanoScan N650U
	{ 0x04a9, 0x220d, 3 },	// CanoScan LiDE 20
	{ 0x04a9, 0x2220, 3 },  // CanoScan LiDE 25
	{ 0x04a9, 0x220e, 3 },	// CanoScan LiDE 30
	{ 0x04b8, 0x011d, 4 },  // Epson Perfection 1260
	{ 0x03f0, 0x0605, 2 }   // HP ScanJet 2200c (maybe only 1 button?)
};

static char* usb_device_descriptions[NUM_SUPPORTED_USB_DEVICES][2] = {
	{ "Canon", "CanoScan N1220U" },
	{ "Canon", "CanoScan D660U"  },
	{ "Canon", "CanoScan N650U" },
	{ "Canon", "CanoScan LiDE 20" },
	{ "Canon", "CanoScan LiDE 25" },
	{ "Canon", "CanoScan LiDE 30" },
	{ "Epson", "Perfection 1260" },
	{ "Hewlett-Packard", "ScanJet 2200c" }
};


libusb_handle_t* libusb_handle;
scanner_t* plustek_scanners = NULL;


// returns -1 if the scanner is unsupported, or the index of the
// corresponding vendor-product pair in the supported_usb_devices array.
int plustek_match_libusb_scanner(libusb_device_t* device)
{
	int index;
	for (index = 0; index < NUM_SUPPORTED_USB_DEVICES; index++) {
		if (supported_usb_devices[index][0] == device->vendorID &&
				  supported_usb_devices[index][1] == device->productID) {
			break;
		}
	}
	if (index >= NUM_SUPPORTED_USB_DEVICES) return -1;
	return index;
}


void plustek_attach_libusb_scanner(libusb_device_t* device)
{
	const char* descriptor_prefix = "plustek:libusb:";
	int index = plustek_match_libusb_scanner(device);
	if (index < 0) return; // unsupported
	scanner_t* scanner = (scanner_t*)malloc(sizeof(scanner_t));
	scanner->vendor = usb_device_descriptions[index][0];
	scanner->product = usb_device_descriptions[index][1];
	scanner->connection = CONNECTION_LIBUSB;
	scanner->internal_dev_ptr = (void*)device;
	scanner->lastbutton = 0;
	scanner->sane_device = (char*)malloc(strlen(device->location) +
		strlen(descriptor_prefix) + 1);
	strcpy(scanner->sane_device, descriptor_prefix);
	strcat(scanner->sane_device, device->location);
	scanner->num_buttons = supported_usb_devices[index][2];
	scanner->is_open = 0;
	scanner->next = plustek_scanners;
	plustek_scanners = scanner;
}


void plustek_detach_scanners(void)
{
	scanner_t* next;
	while (plustek_scanners != NULL) {
		next = plustek_scanners->next;
		free(plustek_scanners->sane_device);
		free(plustek_scanners);
		plustek_scanners = next;
	}
}


void plustek_scan_devices(libusb_device_t* devices)
{
	int index;
	libusb_device_t* device = devices;
	while (device != NULL) {
		index = plustek_match_libusb_scanner(device);
		if (index >= 0) 
			plustek_attach_libusb_scanner(device);
		device = device->next;
	}
}


int plustek_init_libusb(void)
{
	libusb_device_t* devices;

	libusb_handle = libusb_init();
	devices = libusb_get_devices(libusb_handle);
	plustek_scan_devices(devices);
	return 0;
}


const char* scanbtnd_get_backend_name(void)
{
	return backend_name;
}


int scanbtnd_init(void)
{
	plustek_scanners = NULL;

	syslog(LOG_INFO, "plustek-backend: init");
	return plustek_init_libusb();
}


int scanbtnd_rescan(void)
{
	libusb_device_t* devices;

	plustek_detach_scanners();
	plustek_scanners = NULL;
	libusb_rescan(libusb_handle);
	devices = libusb_get_devices(libusb_handle);
	plustek_scan_devices(devices);
	return 0;
}


const scanner_t* scanbtnd_get_supported_devices(void)
{
	return plustek_scanners;
}


int scanbtnd_open(scanner_t* scanner)
{
	int result = -ENOSYS;
	if (scanner->is_open)
		return -EINVAL;
	switch (scanner->connection) {
		case CONNECTION_LIBUSB:
			// if devices have been added/removed, return -ENODEV to
			// make scanbuttond update its device list
			if (libusb_get_changed_device_count() != 0)
				return -ENODEV;
			result = libusb_open((libusb_device_t*)scanner->internal_dev_ptr);
			break;
	}
	if (result == 0)
		scanner->is_open = 1;
	return result;
}


int scanbtnd_close(scanner_t* scanner)
{
	int result = -ENOSYS;
	if (!scanner->is_open)
		return -EINVAL;
	switch (scanner->connection) {
		case CONNECTION_LIBUSB:
			result = libusb_close((libusb_device_t*)scanner->internal_dev_ptr);
			break;
	}
	if (result == 0)
		scanner->is_open = 0;
	return result;
}


int plustek_read(scanner_t* scanner, void* buffer, int bytecount)
{
	switch (scanner->connection) {
		case CONNECTION_LIBUSB:
			return libusb_read((libusb_device_t*)scanner->internal_dev_ptr,
				buffer, bytecount);
			break;
	}
	return -1;
}


int plustek_write(scanner_t* scanner, void* buffer, int bytecount)
{
	switch (scanner->connection) {
		case CONNECTION_LIBUSB:
			return libusb_write((libusb_device_t*)scanner->internal_dev_ptr,
				buffer, bytecount);
			break;
	}
	return -1;
}

void plustek_flush(scanner_t* scanner)
{
	switch (scanner->connection) {
		case CONNECTION_LIBUSB:
			libusb_flush((libusb_device_t*)scanner->internal_dev_ptr);
			break;
	}
}


int scanbtnd_get_button(scanner_t* scanner)
{
	/*
	Note 1: I strongly suspect that the command 0x01 0x69 0x00 0x01 will return
	a button bitmask. For my Canon N1220U it returns 0x04, which happens to
	be the bit I have to test against to see if the scanner button was pressed.
	However, this has to be tested on other scanners to see if this is true.
	UPDATE by BS: The LIDE 20 also returns 0x04, but it has three buttons!
	So this guess is probably wrong. (Thanks to Christian Bucher for this info)
	
	Note 2: This works on my Canon N1220U. Whether this is Canon specific or
	if it works for all 'plustek usb' type scanners is something I don't know.

	Note 3: You must have run sane-find-scanner once. Sane apparently initializes
	something on the scanner allowing this to work. Otherwise all you get is 0x00.
	
	Note 4: by /cbx
	On my CanoScan LIDE20, the default value is $62 and the bits for the
	buttons are as follows:
	Scan: $72 ==> 0x10
	Copy: $6a ==> 0x08
	Mail: $66 ==> 0x04
	*/

	unsigned char bytes[255];
	int num_bytes;
	int button = 0;
	
	bytes[0] = 1;
	bytes[1] = 2;
	bytes[2] = 0;
	bytes[3] = 1;
	
	if (!scanner->is_open)
		return -EINVAL;

	num_bytes = plustek_write(scanner, (void*)bytes, 4);
	if (num_bytes != 4) {
		plustek_flush(scanner);
		return 0;
	}
	num_bytes = plustek_read(scanner, (void*)bytes, 1);
	if (num_bytes != 1) {
		plustek_flush(scanner);
		return 0;
	}
	
	// by BS: This is my first attempt to get rid of the 
	// hardcoded button bitmask. Note that I do not own any device
	// supported by this backend, so this code is based on guessing.
	// Tested on the LIDE 20, should work for 1-button devices, too.
	switch (scanner->num_buttons) {
	case 1:
		if ((bytes[0] & 0x04) != 0) button = 1;
		break;
	case 2:
		if ((bytes[0] & 0x08) != 0) button = 1;
		if ((bytes[0] & 0x04) != 0) button = 2;
		break;
	case 3: 
		if ((bytes[0] & 0x10) != 0) button = 1;
		if ((bytes[0] & 0x08) != 0) button = 2;
		if ((bytes[0] & 0x04) != 0) button = 3;
		break;	
	case 4: // only tested for the Epson Perfection 1260...
		// seems to be a bit odd compared to the other cases...
		if ((bytes[0] & 0x08) != 0) button = 1;
		if ((bytes[0] & 0x10) != 0) button = 2;
		if ((bytes[0] & 0x20) != 0) button = 3;
		if ((bytes[0] & 0x40) != 0) button = 4;
		break;
	}
	return button;
}


const char* scanbtnd_get_sane_device_descriptor(scanner_t* scanner)
{
	return scanner->sane_device;
}


int scanbtnd_exit(void)
{
	syslog(LOG_INFO, "plustek-backend: exit");
	plustek_detach_scanners();
	libusb_exit(libusb_handle);
	return 0;
}

