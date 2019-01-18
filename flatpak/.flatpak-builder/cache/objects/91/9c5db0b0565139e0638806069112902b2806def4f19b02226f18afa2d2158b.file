/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourceversion.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2015 - Paolo Borelli <pborelli@gnome.org>
 *
 * GtkSourceView is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GtkSourceView is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourceversion.h"

/**
 * SECTION:version
 * @short_description: Macros and functions to check the GtkSourceView version
 **/

/**
 * gtk_source_get_major_version:
 *
 * Returns the major version number of the GtkSourceView library.
 * (e.g. in GtkSourceView version 3.20.0 this is 3.)
 *
 * This function is in the library, so it represents the GtkSourceView library
 * your code is running against. Contrast with the #GTK_SOURCE_MAJOR_VERSION
 * macro, which represents the major version of the GtkSourceView headers you
 * have included when compiling your code.
 *
 * Returns: the major version number of the GtkSourceView library
 *
 * Since: 3.20
 */
guint
gtk_source_get_major_version (void)
{
	return GTK_SOURCE_MAJOR_VERSION;
}

/**
 * gtk_source_get_minor_version:
 *
 * Returns the minor version number of the GtkSourceView library.
 * (e.g. in GtkSourceView version 3.20.0 this is 20.)
 *
 * This function is in the library, so it represents the GtkSourceView library
 * your code is running against. Contrast with the #GTK_SOURCE_MINOR_VERSION
 * macro, which represents the minor version of the GtkSourceView headers you
 * have included when compiling your code.
 *
 * Returns: the minor version number of the GtkSourceView library
 *
 * Since: 3.20
 */
guint
gtk_source_get_minor_version (void)
{
	return GTK_SOURCE_MINOR_VERSION;
}

/**
 * gtk_source_get_micro_version:
 *
 * Returns the micro version number of the GtkSourceView library.
 * (e.g. in GtkSourceView version 3.20.0 this is 0.)
 *
 * This function is in the library, so it represents the GtkSourceView library
 * your code is running against. Contrast with the #GTK_SOURCE_MICRO_VERSION
 * macro, which represents the micro version of the GtkSourceView headers you
 * have included when compiling your code.
 *
 * Returns: the micro version number of the GtkSourceView library
 *
 * Since: 3.20
 */
guint
gtk_source_get_micro_version (void)
{
	return GTK_SOURCE_MICRO_VERSION;
}

/**
 * gtk_source_check_version:
 * @major: the major version to check
 * @minor: the minor version to check
 * @micro: the micro version to check
 *
 * Like GTK_SOURCE_CHECK_VERSION, but the check for gtk_source_check_version is
 * at runtime instead of compile time. This is useful for compiling
 * against older versions of GtkSourceView, but using features from newer
 * versions.
 *
 * Returns: %TRUE if the version of the GtkSourceView currently loaded
 * is the same as or newer than the passed-in version.
 *
 * Since: 3.20
 */
gboolean
gtk_source_check_version (guint major,
                          guint minor,
                          guint micro)
{
	return GTK_SOURCE_CHECK_VERSION (major, minor, micro);
}
