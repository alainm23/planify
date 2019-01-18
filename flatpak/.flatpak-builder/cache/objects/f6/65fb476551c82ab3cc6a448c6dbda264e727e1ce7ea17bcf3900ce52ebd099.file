/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2016 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_DISTRODETAILS_H
#define __AS_DISTRODETAILS_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_DISTRO_DETAILS (as_distro_details_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsDistroDetails, as_distro_details, AS, DISTRO_DETAILS, GObject)

struct _AsDistroDetailsClass
{
	GObjectClass parent_class;
	/*< private >*/
	void (*_as_reserved1)	(void);
	void (*_as_reserved2)	(void);
	void (*_as_reserved3)	(void);
	void (*_as_reserved4)	(void);
	void (*_as_reserved5)	(void);
	void (*_as_reserved6)	(void);
};

AsDistroDetails		*as_distro_details_new (void);

const gchar		*as_distro_details_get_id (AsDistroDetails *distro);
const gchar		*as_distro_details_get_name (AsDistroDetails *distro);
const gchar		*as_distro_details_get_version (AsDistroDetails *distro);

gchar			*as_distro_details_get_str (AsDistroDetails *distro,
							const gchar *key);
gboolean		as_distro_details_get_bool (AsDistroDetails *distro,
							const gchar *key,
							gboolean default_val);

G_END_DECLS

#endif /* __AS_DISTRODETAILS_H */
