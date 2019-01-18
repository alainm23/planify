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

#ifndef __AS_CATEGORY_H
#define __AS_CATEGORY_H

#include <glib-object.h>

G_BEGIN_DECLS

typedef struct _AsComponent AsComponent;

#define AS_TYPE_CATEGORY (as_category_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsCategory, as_category, AS, CATEGORY, GObject)

struct _AsCategoryClass
{
	GObjectClass parent_class;
	/*< private >*/
	void (*_as_reserved1)	(void);
	void (*_as_reserved2)	(void);
	void (*_as_reserved3)	(void);
	void (*_as_reserved4)	(void);
};

AsCategory		*as_category_new (void);

const gchar		*as_category_get_id (AsCategory *category);
void			as_category_set_id (AsCategory *category,
						const gchar *id);

const gchar		*as_category_get_name (AsCategory *category);
void			as_category_set_name (AsCategory *category,
						const gchar *value);

const gchar		*as_category_get_summary (AsCategory *category);
void			as_category_set_summary (AsCategory *category,
						const gchar *value);

const gchar		*as_category_get_icon (AsCategory *category);
void			as_category_set_icon (AsCategory *category,
						const gchar* value);

GPtrArray		*as_category_get_children (AsCategory *category);
gboolean		as_category_has_children (AsCategory *category);
void			as_category_add_child (AsCategory *category,
					       AsCategory *subcat);
void			as_category_remove_child (AsCategory *category,
						  AsCategory *subcat);

GPtrArray		*as_category_get_desktop_groups (AsCategory *category);
void			as_category_add_desktop_group (AsCategory *category,
							const gchar *group_name);

GPtrArray		*as_category_get_components (AsCategory *category);
void			as_category_add_component (AsCategory *category,
						   AsComponent *cpt);
gboolean		as_category_has_component (AsCategory *category,
						   AsComponent *cpt);

GPtrArray		*as_get_default_categories (gboolean with_special);

G_END_DECLS

#endif /* __AS_CATEGORY_H */
