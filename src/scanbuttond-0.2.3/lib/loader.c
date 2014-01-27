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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <syslog.h>
#include <dlfcn.h>
#include <errno.h>
#include "scanbuttond/loader.h"

backend_t* load_backend(const char* filename)
{
	char* error;
	void* dll_handle = dlopen(filename, RTLD_NOW|RTLD_LOCAL);
	if (!dll_handle) {
		syslog(LOG_ERR, "loader: failed to load \"%s\". Error message: \"%s\"",
			   filename, dlerror());
		return NULL;
	}
	dlerror();  // Clear any existing error
	backend_t* backend = (backend_t*)malloc(sizeof(backend_t));
	backend->handle = dll_handle;
	backend->scanbtnd_get_backend_name = dlsym(dll_handle, "scanbtnd_get_backend_name");
	if ((error = dlerror()) != NULL) {
		syslog(LOG_ERR, "loader: dlsym failed! Error message \"%s\"", error);
		dlclose(dll_handle);
		free(backend);
		return NULL;
	}
	backend->scanbtnd_init = dlsym(dll_handle, "scanbtnd_init");
	if ((error = dlerror()) != NULL) {
		syslog(LOG_ERR, "loader: dlsym failed! Error message \"%s\"", error);
		dlclose(dll_handle);
		free(backend);
		return NULL;
	}
	backend->scanbtnd_rescan = dlsym(dll_handle, "scanbtnd_rescan");
	if ((error = dlerror()) != NULL) {
		syslog(LOG_ERR, "loader: dlsym failed! Error message \"%s\"", error);
		dlclose(dll_handle);
		free(backend);
		return NULL;
	}
	backend->scanbtnd_get_supported_devices = dlsym(dll_handle, "scanbtnd_get_supported_devices");
	if ((error = dlerror()) != NULL) {
		syslog(LOG_ERR, "loader: dlsym failed! Error message \"%s\"", error);
		dlclose(dll_handle);
		free(backend);
		return NULL;
	}
	backend->scanbtnd_open = dlsym(dll_handle, "scanbtnd_open");
	if ((error = dlerror()) != NULL) {
		syslog(LOG_ERR, "loader: dlsym failed! Error message \"%s\"", error);
		dlclose(dll_handle);
		free(backend);
		return NULL;
	}
	backend->scanbtnd_close = dlsym(dll_handle, "scanbtnd_close");
	if ((error = dlerror()) != NULL) {
		syslog(LOG_ERR, "loader: dlsym failed! Error message \"%s\"", error);
		dlclose(dll_handle);
		free(backend);
		return NULL;
	}
	backend->scanbtnd_get_button = dlsym(dll_handle, "scanbtnd_get_button");
	if ((error = dlerror()) != NULL) {
		syslog(LOG_ERR, "loader: dlsym failed! Error message \"%s\"", error);
		dlclose(dll_handle);
		free(backend);
		return NULL;
	}
	backend->scanbtnd_get_sane_device_descriptor = dlsym(dll_handle, "scanbtnd_get_sane_device_descriptor");
	if ((error = dlerror()) != NULL) {
		syslog(LOG_ERR, "loader: dlsym failed! Error message \"%s\"", error);
		dlclose(dll_handle);
		free(backend);
		return NULL;
	}
	backend->scanbtnd_exit = dlsym(dll_handle, "scanbtnd_exit");
	if ((error = dlerror()) != NULL) {
		syslog(LOG_ERR, "loader: dlsym failed! Error message \"%s\"", error);
		dlclose(dll_handle);
		free(backend);
		return NULL;
	}

	return backend;
}


void unload_backend(backend_t* backend)
{
	dlclose(backend->handle);
	free(backend);
}

