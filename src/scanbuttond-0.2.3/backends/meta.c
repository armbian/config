// meta.c: meta backend ("dynamic backend loader")
// This file is part of scanbuttond.
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
#include <syslog.h>
#include <dlfcn.h>
#include <errno.h>
#include "scanbuttond/common.h"
#include "scanbuttond/scanbuttond.h"
#include "scanbuttond/libusbi.h"
#include "meta.h"

#define MAX_CONFIG_LINE 255
#define MAX_SCANNERS_PER_BACKEND 16

static char* backend_name = "Dynamic Module Loader";
static char* config_file = STRINGIFY(CFG_DIR) "/meta.conf";
static char* lib_dir = STRINGIFY(LIB_DIR);

libusb_handle_t* libusb_handle;
scanner_t* meta_scanners = NULL;
backend_t* meta_backends = NULL;


const char* scanbtnd_get_backend_name(void)
{
	return backend_name;
}


void meta_attach_scanner(scanner_t* scanner, backend_t* backend)
{
	scanner_t* dev = (scanner_t*)malloc(sizeof(scanner_t));
	dev->vendor = scanner->vendor;
	dev->product = scanner->product;
	dev->connection = scanner->connection;
	dev->internal_dev_ptr = scanner->internal_dev_ptr;
	dev->sane_device = scanner->sane_device;
	dev->meta_info = (void*)backend;
	dev->lastbutton = scanner->lastbutton;
	dev->num_buttons = scanner->num_buttons;
	dev->is_open = scanner->is_open;
	dev->next = meta_scanners;
	meta_scanners = dev;
	syslog(LOG_INFO, "meta-backend: attached scanner \"%s %s\"",
		   scanner->vendor, scanner->product);
}


void meta_attach_scanners(scanner_t* devices, backend_t* backend)
{
	scanner_t* dev = devices;
	int count = 0;
	while (dev != NULL) {
		if (count >= MAX_SCANNERS_PER_BACKEND) {
			syslog(LOG_WARNING, "meta-backend: refusing to attach scanner \"%s %s\": Too many scanners!",
				   dev->vendor, dev->product);
			return;
		}
		meta_attach_scanner(dev, backend);
		dev = dev->next;
		count++;
	}
}


void meta_detach_scanner(scanner_t* scanner, scanner_t* prev_scanner)
{
	syslog(LOG_INFO, "meta-backend: detaching scanner: \"%s %s\"",
		   scanner->vendor, scanner->product);
	if (prev_scanner != NULL)
		prev_scanner->next = scanner->next;
	else if (scanner == meta_scanners)
		meta_scanners = scanner->next;
	else
		syslog(LOG_WARNING, "meta-backend: detach scanner: invalid arguments!");
	free(scanner);
}


void meta_detach_scanners(void)
{
	while (meta_scanners != NULL) {
		meta_detach_scanner(meta_scanners, NULL);
	}
}


int meta_attach_backend(backend_t* backend)
{
  // don't load another meta backend
	if (strcmp(backend->scanbtnd_get_backend_name(), scanbtnd_get_backend_name())==0) {
		syslog(LOG_WARNING, "meta-backend: refusing to load another meta backend!");
		return -1;
	}
	syslog(LOG_INFO, "meta-backend: attaching backend: %s",
		   backend->scanbtnd_get_backend_name());
	backend->next = meta_backends;
	meta_backends = backend;
	backend->scanbtnd_init();
	return 0;
}


void meta_detach_backend(backend_t* backend, backend_t* prev_backend)
{
	if (prev_backend != NULL)
		prev_backend->next = backend->next;
	else if (backend == meta_backends)
		meta_backends = backend->next;
	else
		syslog(LOG_WARNING, "meta-backend: detach backend: invalid arguments!");
	backend->scanbtnd_exit();
	unload_backend(backend);
}


void meta_detach_backends(void)
{
	while (meta_backends != NULL) {
		meta_detach_backend(meta_backends, NULL);
	}
}


backend_t* meta_lookup_backend(scanner_t* scanner)
{
	return (backend_t*)scanner->meta_info;
}


void meta_strip_newline(char* str)
{
	int len = strlen(str);
	if (len == 0) return;
	if (str[len-1] != '\n') return;
	str[len-1] = 0;
}


int scanbtnd_init(void)
{
	meta_scanners = NULL;
	meta_backends = NULL;

	syslog(LOG_INFO, "meta-backend: init");
	libusb_handle = libusb_init();

	// read config file
	char lib[MAX_CONFIG_LINE];
	backend_t* backend;
	FILE* f = fopen(config_file, "r");
	if (f == NULL) {
		syslog(LOG_ERR, "meta-backend: config file \"%s\" not found.",
			   config_file);
		return -1;
	}
	while (fgets(lib, MAX_CONFIG_LINE, f)) {
		meta_strip_newline(lib);
		if (strlen(lib)==0) continue;
		char* libpath = (char*)malloc(strlen(lib) + strlen(lib_dir) + 2);
		strcpy(libpath, lib_dir);
		strcat(libpath, "/");
		strcat(libpath, lib);
		backend = load_backend(libpath);
		free(libpath);
		if (backend != NULL && meta_attach_backend(backend)==0) {
			meta_attach_scanners(backend->scanbtnd_get_supported_devices(),
				backend);
		}
	}
	fclose(f);

	return 0;
}


int scanbtnd_rescan(void)
{
	backend_t* backend;

	meta_detach_scanners();
	meta_scanners = NULL;

	backend = meta_backends;
	while (backend != NULL) {
		backend->scanbtnd_rescan();
		meta_attach_scanners(backend->scanbtnd_get_supported_devices(),
							 backend);
		backend = backend->next;
	}

	return 0;
}


const scanner_t* scanbtnd_get_supported_devices(void)
{
	return meta_scanners;
}


int scanbtnd_open(scanner_t* scanner)
{
  // if devices have been added/removed, return -ENODEV to
  // make scanbuttond update its device list
	if (libusb_get_changed_device_count() != 0) {
		return -ENODEV;
	}
	backend_t* backend = meta_lookup_backend(scanner);
	if (backend == NULL) return -1;
	return backend->scanbtnd_open(scanner);
}


int scanbtnd_close(scanner_t* scanner)
{
	backend_t* backend = meta_lookup_backend(scanner);
	if (backend == NULL) return -1;
	return backend->scanbtnd_close(scanner);
}


int scanbtnd_get_button(scanner_t* scanner)
{
	backend_t* backend = meta_lookup_backend(scanner);
	if (backend == NULL) return 0;
	return backend->scanbtnd_get_button(scanner);
}


const char* scanbtnd_get_sane_device_descriptor(scanner_t* scanner)
{
	backend_t* backend = meta_lookup_backend(scanner);
	if (backend == NULL) return NULL;
	return backend->scanbtnd_get_sane_device_descriptor(scanner);
}


int scanbtnd_exit(void)
{
	syslog(LOG_INFO, "meta-backend: exit");
	meta_detach_scanners();
	meta_detach_backends();
	libusb_exit(libusb_handle);
	return 0;
}

