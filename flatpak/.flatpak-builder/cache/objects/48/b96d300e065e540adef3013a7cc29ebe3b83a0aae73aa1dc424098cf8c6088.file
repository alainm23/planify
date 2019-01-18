/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
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
 */

#include "eds-version.h"

const guint eds_major_version = EDS_MAJOR_VERSION;
const guint eds_minor_version = EDS_MINOR_VERSION;
const guint eds_micro_version = EDS_MICRO_VERSION;

/**
 * eds_check_version:
 * @required_major: the required major version
 * @required_minor: the required minor version
 * @required_micro: the required micro version
 *
 * Checks that the Evolution-Data-Server library in use is compatible with
 * the given version.  Generally you would pass in the constants
 * #EDS_MAJOR_VERSION, #EDS_MINOR_VERSION, #EDS_MICRO_VERSION as the three
 * arguments to this function.  That produces a check that the library in
 * use is compatible with the version of Evolution-Data-Server the
 * application or module was compiled against.
 *
 * Returns: %NULL if the Evolution-Data-Server library is compatible with
 * the given version, or a string describing the version mismatch.  The
 * returned string is owned by libedataserver and must not be modified or
 * freed.
 *
 * Since: 2.24
 **/
const gchar *
eds_check_version (guint required_major,
                   guint required_minor,
                   guint required_micro)
{
	gint eds_effective_micro = 100 * EDS_MINOR_VERSION + EDS_MICRO_VERSION;
	gint required_effective_micro = 100 * required_minor + required_micro;

	if (required_major > EDS_MAJOR_VERSION)
		return "EDS version too old (major mismatch)";
	if (required_major < EDS_MAJOR_VERSION)
		return "EDS version too new (major mismatch)";
	if (required_effective_micro > eds_effective_micro)
		return "EDS version too old (micro mismatch)";

	return NULL;
}
