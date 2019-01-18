/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2015 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_ICON_H
#define __AS_ICON_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_ICON (as_icon_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsIcon, as_icon, AS, ICON, GObject)

struct _AsIconClass
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
 * AsIconKind:
 * @AS_ICON_KIND_UNKNOWN:	Unknown icon kind
 * @AS_ICON_KIND_CACHED:	Icon in the internal caches
 * @AS_ICON_KIND_STOCK:		Stock icon name
 * @AS_ICON_KIND_LOCAL:		Local icon name
 * @AS_ICON_KIND_REMOTE:	Remote icon URL
 *
 * The icon type.
 **/
typedef enum  {
	AS_ICON_KIND_UNKNOWN,
	AS_ICON_KIND_CACHED,
	AS_ICON_KIND_STOCK,
	AS_ICON_KIND_LOCAL,
	AS_ICON_KIND_REMOTE,
	/*< private >*/
	AS_ICON_KIND_LAST
} AsIconKind;

AsIconKind	as_icon_kind_from_string (const gchar *kind_str);
const gchar	*as_icon_kind_to_string (AsIconKind kind);

AsIcon		*as_icon_new (void);

AsIconKind	 as_icon_get_kind (AsIcon *icon);
void		 as_icon_set_kind (AsIcon *icon,
					AsIconKind kind);

const gchar	*as_icon_get_name (AsIcon *icon);
void		 as_icon_set_name (AsIcon *icon,
					const gchar *name);

const gchar	*as_icon_get_url (AsIcon *icon);
void		 as_icon_set_url (AsIcon *icon,
					const gchar *url);

const gchar	*as_icon_get_filename (AsIcon *icon);
void		 as_icon_set_filename (AsIcon *icon,
					const gchar *filename);

guint		 as_icon_get_width (AsIcon *icon);
void		 as_icon_set_width (AsIcon *icon,
					guint width);

guint		 as_icon_get_height (AsIcon *icon);
void		 as_icon_set_height (AsIcon *icon,
					guint height);

guint		as_icon_get_scale (AsIcon *icon);
void		as_icon_set_scale (AsIcon *icon,
				   guint scale);

G_END_DECLS

#endif /* __AS_ICON_H */
