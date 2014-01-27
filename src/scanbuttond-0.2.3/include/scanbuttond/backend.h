// backend.h: specification of the mandatory backend functions
// This file is part of scanbuttond.
// Copyleft )c( 2004-2005 by Bernhard Stiftner
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

#ifndef __BACKEND_H_INCLUDED
#define __BACKEND_H_INCLUDED

#include "scanbuttond/scanbuttond.h"

/**
 * \file backend.h
 * \brief Backend function specification.
 *
 * This file specifies which functions a scanbuttond backend has to
 * provide and how it is supposed to interact with with the rest
 * of the system.
 */

/**
 * Gets the name of this backend.
 * \return the backend name
 */
const char* scanbtnd_get_backend_name(void);

/**
 * Initializes the backend.
 * This function makes the backend ready to operate and searches for supported
 * devices (see scanbtnd_get_supported_devices()).
 * \return 0 if successful, <0 otherwise
 */
int scanbtnd_init(void);

/**
 * Refreshes the list of supported devices.
 * After this function has been called, scanbtnd_get_supported_devices() 
 * should only return devices which are currently present on this system.
 * \return 0 if successful, <0 otherwise
 */
int scanbtnd_rescan(void);

/**
 * Returns a list of devices which are currently driven by this backend.
 * The devices are stored in a single-linked list.
 * Note that the device list does not automagically refresh after pluggin in or
 * unplugging a device. You have to explicitly call scanbtnd_rescan() to do
 * that.
 * \return a linked list of supported scanner devices
 */
const scanner_t* scanbtnd_get_supported_devices(void);

/**
 * Opens the given scanner device.
 * This function must be called before using scanbtnd_get_button().
 * After calling this function, it is usually not possible for another process
 * to access the scanner until scanbtnd_close() is called.
 * \param scanner the scanner device to be opened
 * \return 0 if successful, <0 otherwise
 * \retval -ENODEV if the device is no longer present (or the device list has to 
 *         be refreshed). In this case, call scanbtnd_rescan() and try again.
 * \retval -EBUSY if the device is currently used by another process.
 * \retval -EINVAL if the device is already open
 * \retval -ENOSYS if there is no connection method to communicate with the device
 */
int scanbtnd_open(scanner_t* scanner);

/**
 * Closes the given scanner device.
 * This function must be called when you've finished querying the scanner button
 * status using scanbtnd_get_button().
 * After calling this function, other processes may access the device again.
 * \param scanner the scanner device to be closed
 * \return 0 if successful, <0 otherwise
 * \retval -EINVAL if the device is already closed
 * \retval -ENOSYS if there is no connection method to communicate with the device
 */
int scanbtnd_close(scanner_t* scanner);

/**
 * Queries the scanner's button status.
 * \param scanner the scanner device
 * \return the number of the currently pressed button, 0 if no button is currently
 * pressed, or <0 if there was an error.
 * \retval -EINVAL if the scanner device has not been opened before
 */
int scanbtnd_get_button(scanner_t* scanner);

/**
 * Gets the SANE device name of this scanner.
 * The returned string should look like "epson:libusb:003:017".
 * \param scanner the scanner device
 * \return the SANE device name, or NULL if the SANE device name cannot be determined.
 */
const char* scanbtnd_get_sane_device_descriptor(scanner_t* scanner);

/**
 * Shuts down this backend.
 * Cleans up some internal data structures and frees some memory.
 * \return 0 if successful, <0 otherwise
 */
int scanbtnd_exit(void);

#endif
