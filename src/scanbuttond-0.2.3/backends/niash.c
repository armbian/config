// niash.c: Niash device backend
// This file is part of scanbuttond.
// Copyleft )c( 2005 by Bernhard Stiftner
// Copyleft )c( 2005 by Dirk Wriedt
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
#include "niash.h"

static char* backend_name = "Niash USB";

#define NUM_SUPPORTED_USB_DEVICES 4

static int supported_usb_devices[NUM_SUPPORTED_USB_DEVICES][3] = {
	// vendor, product, num_buttons
	{ 0x06bd, 0x0100, 4 },	// Agfa Snapscan Touch
	{ 0x03f0, 0x0205, 2 },	// HP Scanjet 3300c
	{ 0x03f0, 0x0405, 3 },	// HP Scanjet 3400c
	{ 0x03f0, 0x0305, 3 }	// HP Scanjet 4300c
};

// TODO: check if this backend really works on the Epson 2580 too...
static char* usb_device_descriptions[NUM_SUPPORTED_USB_DEVICES][2] = {
	{ "Agfa", "Snapscan Touch" },
	{ "Hewlett-Packard", "Scanjet 3300c" },
	{ "Hewlett-Packard", "Scanjet 3400c" },
	{ "Hewlett-Packard", "Scanjet 4300c" }
};


libusb_handle_t* libusb_handle;
scanner_t* niash_scanners = NULL;


// returns -1 if the scanner is unsupported, or the index of the
// corresponding vendor-product pair in the supported_usb_devices array.
int niash_match_libusb_scanner(libusb_device_t* device)
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


// TODO: check if the descriptor matches the SANE device name!
void niash_attach_libusb_scanner(libusb_device_t* device)
{
	const char* descriptor_prefix = "niash:libusb:";
	int index = niash_match_libusb_scanner(device);
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
	scanner->next = niash_scanners;
	niash_scanners = scanner;
}


void niash_detach_scanners(void)
{
	scanner_t* next;
	while (niash_scanners != NULL) {
		next = niash_scanners->next;
		free(niash_scanners->sane_device);
		free(niash_scanners);
		niash_scanners = next;
	}
}


void niash_scan_devices(libusb_device_t* devices)
{
	int index;
	libusb_device_t* device = devices;
	while (device != NULL) {
		index = niash_match_libusb_scanner(device);
		if (index >= 0) 
			niash_attach_libusb_scanner(device);
		device = device->next;
	}
}


int niash_init_libusb(void)
{
	libusb_device_t* devices;

	libusb_handle = libusb_init();
	devices = libusb_get_devices(libusb_handle);
	niash_scan_devices(devices);
	return 0;
}


const char* scanbtnd_get_backend_name(void)
{
	return backend_name;
}


int scanbtnd_init(void)
{
	niash_scanners = NULL;

	syslog(LOG_INFO, "niash-backend: init");
	return niash_init_libusb();
}


int scanbtnd_rescan(void)
{
	libusb_device_t* devices;

	niash_detach_scanners();
	niash_scanners = NULL;
	libusb_rescan(libusb_handle);
	devices = libusb_get_devices(libusb_handle);
	niash_scan_devices(devices);
	return 0;
}


const scanner_t* scanbtnd_get_supported_devices(void)
{
	return niash_scanners;
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


int niash_control_msg(scanner_t* scanner, int requesttype, int request,
					  int value, int index, void* buffer, int bytecount)
{
	switch (scanner->connection) {
		case CONNECTION_LIBUSB:
			return libusb_control_msg((libusb_device_t*)scanner->internal_dev_ptr,
									   requesttype, request, value, index, buffer,
									   bytecount);
			break;
	}
	return -1;
}


int scanbtnd_get_button(scanner_t* scanner)
{
	unsigned char bytes[255];
	int value[255];
	int requesttype[255];
	int num_bytes;
	int button;
	int i;

	if (!scanner->is_open)
		return -EINVAL;

	/*
	The button status seems to be held in Register 0x2e of the
	scanner's USB - IEEE1284 bridge
	I checked the usb sniffer logs against hp3300c_xfer.h (hp3300 sane backend)
	and learned that the requests being submitted by the windows driver for
	my Agfa Snapscan Touch seem to follow this schema:

	request value                data   datasize
	0x40    SPP_CONTROL   (0x87) 0x14        1
	0x40    EPP_ADDR      (0x83) 0x2e        1
	0x40    SPP_CONTROL   (0x87) 0x34        1
	0xc0    EPP_DATA_READ (0x84) returned    1
	0x40    SPP_CONTROL   (0x87) 0x14        1

	The register can be read by setting the address with an EPP_ADDR call,
	then issuing an EPP_DATA_READ call.
	I don't know what the last request is for.
	*/

	requesttype[0]=0x40; bytes[0] = 0x14; value[0]=0x87; /* SPP_CONTROL */
	requesttype[1]=0x40; bytes[1] = 0x2e; value[1]=0x83; /* EPP_ADDR */
	requesttype[2]=0x40; bytes[2] = 0x34; value[2]=0x87; /* SPP_CONTROL */
	requesttype[3]=0xc0; bytes[3] = 0xff; value[3]=0x84; /* EPP_DATA_READ */
	requesttype[4]=0x40; bytes[4] = 0x14; value[4]=0x87; /* SPP_CONTROL */
	for(i=0;i<5;i++) {
		num_bytes=niash_control_msg(scanner, requesttype[i], 0x0c, value[i], 0, (void*)&bytes + i, 0x01);
		if (num_bytes < 0 ) return 0;
	}
	switch (bytes[3]) {
		case 0x02: button = 1; break;
		case 0x04: button = 2; break;
		case 0x08: button = 3; break;
		case 0x10: button = 4; break;
		default: button = 0; break;
	};

	return button;
}


const char* scanbtnd_get_sane_device_descriptor(scanner_t* scanner)
{
	return scanner->sane_device;
}


int scanbtnd_exit(void)
{
	syslog(LOG_INFO, "niash-backend: exit");
	niash_detach_scanners();
	libusb_exit(libusb_handle);
	return 0;
}

