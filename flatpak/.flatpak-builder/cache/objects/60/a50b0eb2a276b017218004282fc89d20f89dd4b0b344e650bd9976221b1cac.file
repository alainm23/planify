/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 8; tab-width: 8 -*- */
/* e-uid.c - Unique ID generator.
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Dan Winship <danw@ximian.com>
 */

#include "e-uid.h"

#include "e-data-server-util.h"

/**
 * e_uid_new:
 *
 * Generate a new unique string for use e.g. in account lists.
 *
 * Returns: The newly generated UID.  The caller should free the string
 * when it's done with it.
 *
 * Deprecated: 3.26: Use e_util_generate_uid() instead.
 **/
gchar *
e_uid_new (void)
{
	return e_util_generate_uid ();
}
