// mustek.c : scanbuttond backend for mustek/gt68xx devices
// This file is part of scanbuttond.
// Copyleft )c( 2006 by Bernhard Stiftner
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
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <syslog.h>
#include "scanbuttond/scanbuttond.h"
#include "scanbuttond/libusbi.h"
#include "mustek.h"

static char* backend_name = "Mustek USB";

#define NUM_SUPPORTED_USB_DEVICES 1

static int supported_usb_devices[NUM_SUPPORTED_USB_DEVICES][3] = {
	// vendor, product, num_buttons
	{ 0x055f, 0x0409, 5 } // Mustek BearPaw 2448TA
};

static char* usb_device_descriptions[NUM_SUPPORTED_USB_DEVICES][2] = {
	{ "Mustek", "BearPaw 2448TA"}
};


libusb_handle_t* libusb_handle;
scanner_t* mustek_scanners = NULL;


// returns -1 if the scanner is unsupported, or the index of the
// corresponding vendor-product pair in the supported_usb_devices array.
int mustek_match_libusb_scanner(libusb_device_t* device)
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


void mustek_attach_libusb_scanner(libusb_device_t* device)
{
	const char* descriptor_prefix = "mustek:libusb:";
	int index = mustek_match_libusb_scanner(device);
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
	scanner->next = mustek_scanners;
	mustek_scanners = scanner;
}


void mustek_detach_scanners(void)
{
	scanner_t* next;
	while (mustek_scanners != NULL) {
		next = mustek_scanners->next;
		free(mustek_scanners->sane_device);
		free(mustek_scanners);
		mustek_scanners = next;
	}
}


void mustek_scan_devices(libusb_device_t* devices)
{
	int index;
	libusb_device_t* device = devices;
	while (device != NULL) {
		index = mustek_match_libusb_scanner(device);
		if (index >= 0)
			mustek_attach_libusb_scanner(device);
		device = device->next;
	}
}


int mustek_init_libusb(void)
{
	libusb_device_t* devices;

	libusb_handle = libusb_init();
	devices = libusb_get_devices(libusb_handle);
	mustek_scan_devices(devices);
	return 0;
}


const char* scanbtnd_get_backend_name(void)
{
	return backend_name;
}


int scanbtnd_init(void)
{
	mustek_scanners = NULL;

	syslog(LOG_INFO, "mustek-backend: init");
	return mustek_init_libusb();
}


int scanbtnd_rescan(void)
{
	libusb_device_t *devices;

	mustek_detach_scanners();
	mustek_scanners = NULL;
	libusb_rescan(libusb_handle);
	devices = libusb_get_devices(libusb_handle);
	mustek_scan_devices(devices);
	return 0;
}


const scanner_t* scanbtnd_get_supported_devices(void)
{
	return mustek_scanners;
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


int mustek_read(scanner_t* scanner, void* buffer, int bytecount)
{
	switch (scanner->connection) {
		case CONNECTION_LIBUSB:
			return libusb_read((libusb_device_t*)scanner->internal_dev_ptr, 
				buffer, bytecount);
			break;
	}
	return -1;
}


int mustek_write(scanner_t* scanner, void* buffer, int bytecount)
{
	switch (scanner->connection) {
		case CONNECTION_LIBUSB:
			return libusb_write((libusb_device_t*)scanner->internal_dev_ptr, 
				buffer, bytecount);
			break;
	}
	return -1;
}


void mustek_flush(scanner_t* scanner)
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

	bytes[0] = 0x74; // check function key

	if (!scanner->is_open)
		return -EINVAL;

	num_bytes = mustek_write(scanner, (void*)bytes, 1);
	if (num_bytes != 1) {
		mustek_flush(scanner);
		return 0;
	}
	num_bytes = mustek_read(scanner, (void*)bytes, 4);
	if (num_bytes != 4) {
		mustek_flush(scanner);
		return 0;
	}
	switch (bytes[2]) {
	case 0x10: // scan button
		return 1;
	case 0x14: // copy
		return 2;
	case 0x12: // fax
		return 3;
	case 0x18: // email
		return 4;
	case 0x11: // panel
		return 5;
	}
	return 0;
}


const char* scanbtnd_get_sane_device_descriptor(scanner_t* scanner)
{
	return scanner->sane_device;
}


int scanbtnd_exit(void)
{
	syslog(LOG_INFO, "mustek-backend: exit");
	mustek_detach_scanners();
	libusb_exit(libusb_handle);
	return 0;
}

