/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2014-2016 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_PROVIDED_H
#define __AS_PROVIDED_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_PROVIDED (as_provided_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsProvided, as_provided, AS, PROVIDED, GObject)

struct _AsProvidedClass
{
	GObjectClass		parent_class;
	/*< private >*/
	void (*_as_reserved1)	(void);
	void (*_as_reserved2)	(void);
	void (*_as_reserved3)	(void);
	void (*_as_reserved4)	(void);
	void (*_as_reserved5)	(void);
	void (*_as_reserved6)	(void);
};

/**
 * AsProvidedKind:
 * @AS_PROVIDED_KIND_UNKNOWN:		Unknown kind
 * @AS_PROVIDED_KIND_LIBRARY:		A shared library
 * @AS_PROVIDED_KIND_BINARY:		A binary installed into a directory in PATH
 * @AS_PROVIDED_KIND_MIMETYPE:		Provides a handler for a mimetype
 * @AS_PROVIDED_KIND_FONT:		A font
 * @AS_PROVIDED_KIND_MODALIAS:		A modalias
 * @AS_PROVIDED_KIND_PYTHON_2:		A Python2 module
 * @AS_PROVIDED_KIND_PYTHON:		A Python3 module
 * @AS_PROVIDED_KIND_DBUS_SYSTEM:	A DBus service name on the system bus.
 * @AS_PROVIDED_KIND_DBUS_USER:		A DBus service name on the user/session bus.
 * @AS_PROVIDED_KIND_FIRMWARE_RUNTIME:	Firmware flashed at runtime.
 * @AS_PROVIDED_KIND_FIRMWARE_FLASHED:	Firmware flashed permanently to the device.
 * @AS_PROVIDED_KIND_ID:		An AppStream component
 *
 * Type of the public interface components can provide.
 **/
typedef enum  {
	AS_PROVIDED_KIND_UNKNOWN,
	AS_PROVIDED_KIND_LIBRARY,
	AS_PROVIDED_KIND_BINARY,
	AS_PROVIDED_KIND_MIMETYPE,
	AS_PROVIDED_KIND_FONT,
	AS_PROVIDED_KIND_MODALIAS,
	AS_PROVIDED_KIND_PYTHON_2,
	AS_PROVIDED_KIND_PYTHON,
	AS_PROVIDED_KIND_DBUS_SYSTEM,
	AS_PROVIDED_KIND_DBUS_USER,
	AS_PROVIDED_KIND_FIRMWARE_RUNTIME,
	AS_PROVIDED_KIND_FIRMWARE_FLASHED,
	AS_PROVIDED_KIND_ID,
	/*< private >*/
	AS_PROVIDED_KIND_LAST
} AsProvidedKind;

const gchar		*as_provided_kind_to_string (AsProvidedKind kind);
AsProvidedKind		as_provided_kind_from_string (const gchar *kind_str);
const gchar		*as_provided_kind_to_l10n_string (AsProvidedKind kind);

AsProvided		*as_provided_new (void);

AsProvidedKind		as_provided_get_kind (AsProvided *prov);
void			as_provided_set_kind (AsProvided *prov,
						AsProvidedKind kind);

GPtrArray		*as_provided_get_items (AsProvided *prov);
void			as_provided_add_item (AsProvided *prov,
						const gchar *item);
gboolean		as_provided_has_item (AsProvided *prov,
						const gchar *item);

G_END_DECLS

#endif /* __AS_PROVIDED_H */
