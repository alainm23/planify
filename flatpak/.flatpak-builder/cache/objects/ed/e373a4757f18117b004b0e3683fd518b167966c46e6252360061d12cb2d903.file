/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2014-2018 Matthias Klumpp <matthias@tenstral.net>
 * Copyright (C) 2014-2017 Richard Hughes <richard@hughsie.com>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * SECTION:as-tag
 * @short_description: Helper functions to convert to and from tag enums
 * @include: appstream.h
 *
 * These functions will convert a tag enum such as %AS_TAG_COMPONENT to
 * it's string form, and also vice-versa.
 *
 * These helper functions may be useful if implementing an AppStream parser.
 */

#include "as-tag.h"

#include <string.h>

#ifdef __clang__
#pragma clang diagnostic ignored "-Wmissing-field-initializers"
#endif

#pragma GCC visibility push(hidden)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wconversion"
#pragma GCC diagnostic ignored "-Wsign-conversion"
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
#include "as-tag-xml-private.h"
#include "as-tag-yaml-private.h"
#pragma GCC diagnostic pop
#pragma GCC visibility pop

/**
 * as_xml_tag_from_string:
 * @tag: the string.
 *
 * Converts the XML text representation to an enumerated value.
 *
 * Returns: a %AsTag, or %AS_TAG_UNKNOWN if not known.
 *
 * Since: 0.12.1
 **/
AsTag
as_xml_tag_from_string (const gchar *tag)
{
	const struct xml_tag_data *ky;
	AsTag etag = AS_TAG_UNKNOWN;

	/* invalid */
	if (tag == NULL)
		return AS_TAG_UNKNOWN;

	/* use a perfect hash */
	ky = _as_xml_tag_from_gperf (tag, strlen (tag));
	if (ky != NULL)
		etag = ky->etag;

	return etag;
}

/**
 * as_yaml_tag_from_string:
 * @tag: the string.
 *
 * Converts the YAML text representation to an enumerated value.
 *
 * Returns: a %AsTag, or %AS_TAG_UNKNOWN if not known.
 *
 * Since: 0.12.1
 **/
AsTag
as_yaml_tag_from_string (const gchar *tag)
{
	const struct yaml_tag_data *ky;
	AsTag etag = AS_TAG_UNKNOWN;

	/* invalid */
	if (tag == NULL)
		return AS_TAG_UNKNOWN;

	/* use a perfect hash */
	ky = _as_yaml_tag_from_gperf (tag, strlen (tag));
	if (ky != NULL)
		etag = ky->etag;

	return etag;
}
