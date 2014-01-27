// loader.h: dynamic backend library loader
// This file is part of scanbuttond.
// Copyleft )c( 2005 by Bernhard Stiftner
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

#ifndef __LOADER_H_INCLUDED
#define __LOADER_H_INCLUDED

#include "scanbuttond/scanbuttond.h"

struct backend;
typedef struct backend backend_t;

struct backend {
	char* (*scanbtnd_get_backend_name)(void);
	int (*scanbtnd_init)(void);
	int (*scanbtnd_rescan)(void);
	scanner_t* (*scanbtnd_get_supported_devices)(void);
	int (*scanbtnd_open)(scanner_t* scanner);
	int (*scanbtnd_close)(scanner_t* scanner);
	int (*scanbtnd_get_button)(scanner_t* scanner);
	char* (*scanbtnd_get_sane_device_descriptor)(scanner_t* scanner);
	int (*scanbtnd_exit)(void);
	void* handle;  // handle for dlopen/dlsym/dlclose

	backend_t* next;
};

backend_t* load_backend(const char* filename);

void unload_backend(backend_t* backend);

#endif
