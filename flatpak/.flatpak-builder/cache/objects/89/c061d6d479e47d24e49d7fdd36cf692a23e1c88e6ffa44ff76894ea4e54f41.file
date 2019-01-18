/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2017 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_LAUNCHABLE_H
#define __AS_LAUNCHABLE_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_LAUNCHABLE (as_launchable_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsLaunchable, as_launchable, AS, LAUNCHABLE, GObject)

struct _AsLaunchableClass
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
 * AsLaunchableKind:
 * @AS_LAUNCHABLE_KIND_UNKNOWN:			Unknown kind
 * @AS_LAUNCHABLE_KIND_DESKTOP_ID:		Launch by desktop-id
 * @AS_LAUNCHABLE_KIND_SERVICE:			A systemd/SysV-init service name
 * @AS_LAUNCHABLE_KIND_COCKPIT_MANIFEST:	A Cockpit manifest / package name
 *
 * Type of launch system the entries belong to.
 **/
typedef enum  {
	AS_LAUNCHABLE_KIND_UNKNOWN,
	AS_LAUNCHABLE_KIND_DESKTOP_ID,
	AS_LAUNCHABLE_KIND_SERVICE,
	AS_LAUNCHABLE_KIND_COCKPIT_MANIFEST,
	AS_LAUNCHABLE_KIND_URL,
	/*< private >*/
	AS_LAUNCHABLE_KIND_LAST
} AsLaunchableKind;

const gchar		*as_launchable_kind_to_string (AsLaunchableKind kind);
AsLaunchableKind	as_launchable_kind_from_string (const gchar *kind_str);

AsLaunchable		*as_launchable_new (void);

AsLaunchableKind	as_launchable_get_kind (AsLaunchable *launch);
void			as_launchable_set_kind (AsLaunchable *launch,
						AsLaunchableKind kind);

GPtrArray		*as_launchable_get_entries (AsLaunchable *launch);
void			as_launchable_add_entry (AsLaunchable *launch,
						const gchar *entry);

G_END_DECLS

#endif /* __AS_LAUNCHABLE_H */
