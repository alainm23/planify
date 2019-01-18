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

#ifndef __AS_BUNDLE_H
#define __AS_BUNDLE_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_BUNDLE (as_bundle_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsBundle, as_bundle, AS, BUNDLE, GObject)

struct _AsBundleClass
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
 * AsBundleKind:
 * @AS_BUNDLE_KIND_UNKNOWN:	Type invalid or not known
 * @AS_BUNDLE_KIND_PACKAGE:	A native package (currently not used)
 * @AS_BUNDLE_KIND_LIMBA:	A Limba bundle
 * @AS_BUNDLE_KIND_FLATPAK:	A Flatpak bundle
 * @AS_BUNDLE_KIND_APPIMAGE:	An AppImageKit bundle
 * @AS_BUNDLE_KIND_SNAP:	A Snap/Snappy bundle
 *
 * The bundle type.
 **/
typedef enum {
	AS_BUNDLE_KIND_UNKNOWN,
	AS_BUNDLE_KIND_PACKAGE,
	AS_BUNDLE_KIND_LIMBA,
	AS_BUNDLE_KIND_FLATPAK,
	AS_BUNDLE_KIND_APPIMAGE,
	AS_BUNDLE_KIND_SNAP,
	/*< private >*/
	AS_BUNDLE_KIND_LAST
} AsBundleKind;

const gchar	*as_bundle_kind_to_string (AsBundleKind kind);
AsBundleKind	as_bundle_kind_from_string (const gchar *bundle_str);

AsBundle	*as_bundle_new (void);

AsBundleKind	 as_bundle_get_kind (AsBundle *bundle);
void		 as_bundle_set_kind (AsBundle *bundle,
					AsBundleKind kind);

const gchar	*as_bundle_get_id (AsBundle *bundle);
void		 as_bundle_set_id (AsBundle *bundle,
					const gchar *id);

G_END_DECLS

#endif /* __AS_BUNDLE_H */
