// snapscan.c: Snapscan device backend
// This file is part of scanbuttond.
// Copyleft )c( 2005-2006 by Bernhard Stiftner
// Thanks to J. Javier Maestro for sniffing the button codes ;-)
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
#include "snapscan.h"

static char* backend_name = "Snapscan USB";

#define NUM_SUPPORTED_USB_DEVICES 3

static int supported_usb_devices[NUM_SUPPORTED_USB_DEVICES][3] = {
	{ 0x04b8, 0x0121, 4 },	// Epson Perfection 2480
	{ 0x04b8, 0x011f, 4 },	// Epson Perfection 1670
	{ 0x04b8, 0x0122, 4 }	// Epson Perfection 3490
};

// TODO: check if this backend really works on the Epson 2580 too...
static char* usb_device_descriptions[NUM_SUPPORTED_USB_DEVICES][2] = {
	   { "Epson", "Perfection 2480 / 2580" },
	   { "Epson", "Perfection 1670" },
	   { "Epson", "Perfection 3490" }
};


libusb_handle_t* libusb_handle;
scanner_t* snapscan_scanners = NULL;


// returns -1 if the scanner is unsupported, or the index of the
// corresponding vendor-product pair in the supported_usb_devices array.
int snapscan_match_libusb_scanner(libusb_device_t* device)
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


void snapscan_attach_libusb_scanner(libusb_device_t* device)
{
	const char* descriptor_prefix = "snapscan:libusb:";
	int index = snapscan_match_libusb_scanner(device);
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
	scanner->next = snapscan_scanners;
	snapscan_scanners = scanner;
}


void snapscan_detach_scanners(void)
{
	scanner_t* next;
	while (snapscan_scanners != NULL) {
		next = snapscan_scanners->next;
		free(snapscan_scanners->sane_device);
		free(snapscan_scanners);
		snapscan_scanners = next;
	}
}


void snapscan_scan_devices(libusb_device_t* devices)
{
	int index;
	libusb_device_t* device = devices;
	while (device != NULL) {
		index = snapscan_match_libusb_scanner(device);
		if (index >= 0) 
			snapscan_attach_libusb_scanner(device);
		device = device->next;
	}
}


int snapscan_init_libusb(void)
{
	libusb_device_t* devices;

	libusb_handle = libusb_init();
	devices = libusb_get_devices(libusb_handle);
	snapscan_scan_devices(devices);
	return 0;
}


const char* scanbtnd_get_backend_name(void)
{
	return backend_name;
}


int scanbtnd_init(void)
{
	snapscan_scanners = NULL;

	syslog(LOG_INFO, "snapscan-backend: init");
	return snapscan_init_libusb();
}


int scanbtnd_rescan(void)
{
	libusb_device_t* devices;

	snapscan_detach_scanners();
	snapscan_scanners = NULL;
	libusb_rescan(libusb_handle);
	devices = libusb_get_devices(libusb_handle);
	snapscan_scan_devices(devices);
	return 0;
}


const scanner_t* scanbtnd_get_supported_devices(void)
{
	return snapscan_scanners;
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


int snapscan_read(scanner_t* scanner, void* buffer, int bytecount)
{
	switch (scanner->connection) {
		case CONNECTION_LIBUSB:
			return libusb_read((libusb_device_t*)scanner->internal_dev_ptr, 
				buffer, bytecount);
			break;
	}
	return -1;
}


int snapscan_write(scanner_t* scanner, void* buffer, int bytecount)
{
	switch (scanner->connection) {
		case CONNECTION_LIBUSB:
			return libusb_write((libusb_device_t*)scanner->internal_dev_ptr, 
				buffer, bytecount);
			break;
	}
	return -1;
}

void snapscan_flush(scanner_t* scanner)
{
	switch (scanner->connection) {
		case CONNECTION_LIBUSB:
			libusb_flush((libusb_device_t*)scanner->internal_dev_ptr);
			break;
	}
}



int scanbtnd_get_button(scanner_t* scanner)
{
	unsigned char bytes[255];
	int num_bytes;
	int button = 0;

	bytes[0] = 0x03;
	bytes[1] = 0x00;
	bytes[2] = 0x00;
	bytes[3] = 0x00;
	bytes[4] = 0x14;
	bytes[5] = 0x00;

	if (!scanner->is_open)
		return -EINVAL;

	num_bytes = snapscan_write(scanner, (void*)bytes, 6);
	if (num_bytes != 6) {
		snapscan_flush(scanner);
		return 0;
	}

	num_bytes = snapscan_read(scanner, (void*)bytes, 8);
	if (num_bytes != 8 || bytes[0] != 0xF9) {
		snapscan_flush(scanner);
		return 0;
	}

	num_bytes = snapscan_read(scanner, (void*)bytes, 20);
	if (num_bytes != 20 || bytes[0] != 0xF0) {
		snapscan_flush(scanner); 
		return 0;
	}
	if (bytes[2] == 0x06) {
		switch (bytes[18] & 0xF0) {
			case 0x10: button = 1; break;
			case 0x20: button = 2; break;
			case 0x40: button = 3; break;
			case 0x80: button = 4; break;
			default: button = 0; break;
		}
	}

	num_bytes = snapscan_read(scanner, (void*)bytes, 8);
	if (num_bytes != 8 || bytes[0] != 0xFB) {
		snapscan_flush(scanner);
		return 0;
	}

	return button;
}


const char* scanbtnd_get_sane_device_descriptor(scanner_t* scanner)
{
	return scanner->sane_device;
}


int scanbtnd_exit(void)
{
	syslog(LOG_INFO, "snapscan-backend: exit");
	snapscan_detach_scanners();
	libusb_exit(libusb_handle);
	return 0;
}

