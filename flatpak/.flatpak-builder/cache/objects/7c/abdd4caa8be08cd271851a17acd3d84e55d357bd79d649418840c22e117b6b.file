/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016 Matthias Klumpp <matthias@tenstral.net>
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

#if !defined (__APPSTREAM_H) && !defined (AS_COMPILATION)
#error "Only <appstream.h> can be included directly."
#endif

#ifndef __AS_CHECKSUM_H
#define __AS_CHECKSUM_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_CHECKSUM (as_checksum_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsChecksum, as_checksum, AS, CHECKSUM, GObject)

struct _AsChecksumClass
{
	GObjectClass parent_class;
	/*< private >*/
	void (*_as_reserved1) (void);
	void (*_as_reserved2) (void);
	void (*_as_reserved3) (void);
	void (*_as_reserved4) (void);
	void (*_as_reserved5) (void);
	void (*_as_reserved6) (void);
};

/**
 * AsChecksumKind:
 * @AS_CHECKSUM_KIND_NONE:	No checksum
 * @AS_CHECKSUM_KIND_SHA1:	SHA1
 * @AS_CHECKSUM_KIND_SHA256:	SHA256
 *
 * Checksums supported by #AsRelease
 **/
typedef enum  {
	AS_CHECKSUM_KIND_NONE,
	AS_CHECKSUM_KIND_SHA1,
	AS_CHECKSUM_KIND_SHA256,
	/*< private >*/
	AS_CHECKSUM_KIND_LAST
} AsChecksumKind;

const gchar		*as_checksum_kind_to_string (AsChecksumKind kind);
AsChecksumKind		as_checksum_kind_from_string (const gchar *kind_str);

AsChecksum		*as_checksum_new (void);

AsChecksumKind		as_checksum_get_kind (AsChecksum *cs);
void			as_checksum_set_kind (AsChecksum *cs,
						AsChecksumKind kind);

const gchar		*as_checksum_get_value (AsChecksum *cs);
void			as_checksum_set_value (AsChecksum *cs,
						const gchar *value);

G_END_DECLS

#endif /* __AS_CHECKSUM_H */
