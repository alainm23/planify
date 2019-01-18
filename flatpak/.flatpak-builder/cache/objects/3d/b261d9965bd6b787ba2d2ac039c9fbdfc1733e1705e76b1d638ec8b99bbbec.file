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

#include <geocode-glib/geocode-error.h>

/**
 * SECTION:geocode-error
 * @short_description: Error helper functions
 * @include: geocode-glib/geocode-glib.h
 *
 * Contains helper functions for reporting errors to the user.
 **/

/**
 * geocode_error_quark:
 *
 * Gets the geocode-glib error quark.
 *
 * Return value: a #GQuark.
 **/
GQuark
geocode_error_quark (void)
{
	static GQuark quark;
	if (!quark)
		quark = g_quark_from_static_string ("geocode_error");

	return quark;
}

