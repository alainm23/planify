/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016 Richard Hughes <richard@hughsie.com>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA
 */

#if !defined (__APPSTREAM_H) && !defined (AS_COMPILATION)
#error "Only <appstream.h> can be included directly."
#endif

#ifndef __AS_CONTENT_RATING_H
#define __AS_CONTENT_RATING_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_CONTENT (as_content_rating_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsContentRating, as_content_rating, AS, CONTENT_RATING, GObject)

struct _AsContentRatingClass
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
 * AsContentRatingValue:
 * @AS_CONTENT_RATING_VALUE_UNKNOWN:		Unknown value
 * @AS_CONTENT_RATING_VALUE_NONE:		None
 * @AS_CONTENT_RATING_VALUE_MILD:		A small amount
 * @AS_CONTENT_RATING_VALUE_MODERATE:		A moderate amount
 * @AS_CONTENT_RATING_VALUE_INTENSE:		An intense amount
 *
 * The specified level of an content_rating rating ID.
 **/
typedef enum {
	AS_CONTENT_RATING_VALUE_UNKNOWN,
	AS_CONTENT_RATING_VALUE_NONE,
	AS_CONTENT_RATING_VALUE_MILD,
	AS_CONTENT_RATING_VALUE_MODERATE,
	AS_CONTENT_RATING_VALUE_INTENSE,
	/*< private >*/
	AS_CONTENT_RATING_VALUE_LAST
} AsContentRatingValue;

const gchar		*as_content_rating_value_to_string (AsContentRatingValue value);
AsContentRatingValue	 as_content_rating_value_from_string (const gchar *value);

AsContentRating		*as_content_rating_new (void);

const gchar		*as_content_rating_get_kind (AsContentRating *content_rating);
void			as_content_rating_set_kind (AsContentRating *content_rating,
						    const gchar *kind);

guint			as_content_rating_get_minimum_age (AsContentRating *content_rating);

AsContentRatingValue	as_content_rating_get_value (AsContentRating *content_rating,
						     const gchar *id);
void			as_content_rating_set_value (AsContentRating *content_rating,
						     const gchar *id,
						     AsContentRatingValue value);

G_END_DECLS

#endif /* __AS_CONTENT_RATING_H */
