/*
   Copyright 2011 Bastien Nocera

   The Gnome Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   The Gnome Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with the Gnome Library; see the file COPYING.LIB.  If not,
   write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301  USA.

   Authors: Bastien Nocera <hadess@hadess.net>

 */

#ifndef GEOCODE_ERROR_H
#define GEOCODE_ERROR_H

#include <glib.h>

G_BEGIN_DECLS

/**
 * GEOCODE_ERROR:
 *
 * Error domain for geocode-glib. Errors from this domain will be from
 * the #GeocodeError enumeration.
 * See #GError for more information on error domains.
 **/
#define GEOCODE_ERROR (geocode_error_quark ())

/**
 * GeocodeError:
 * @GEOCODE_ERROR_PARSE: An error occured parsing the response from the web service.
 * @GEOCODE_ERROR_NOT_SUPPORTED: The request made was not supported.
 * @GEOCODE_ERROR_NO_MATCHES: The requests made didn't have any matches.
 * @GEOCODE_ERROR_INVALID_ARGUMENTS: The request made contained invalid arguments.
 * @GEOCODE_ERROR_INTERNAL_SERVER: The server encountered an (possibly unrecoverable) internal error.
 *
 * Error codes returned by geocode-glib functions.
 **/
typedef enum {
	GEOCODE_ERROR_PARSE,
	GEOCODE_ERROR_NOT_SUPPORTED,
	GEOCODE_ERROR_NO_MATCHES,
	GEOCODE_ERROR_INVALID_ARGUMENTS,
	GEOCODE_ERROR_INTERNAL_SERVER
} GeocodeError;

GQuark geocode_error_quark (void);

G_END_DECLS

#endif /* GEOCODE_ERROR_H */
