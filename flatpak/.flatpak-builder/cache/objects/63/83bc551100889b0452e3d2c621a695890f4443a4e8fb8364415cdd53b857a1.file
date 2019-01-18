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

#ifndef __AS_IMAGE_H
#define __AS_IMAGE_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_IMAGE (as_image_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsImage, as_image, AS, IMAGE, GObject)

struct _AsImageClass
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
 * AsImageKind:
 * @AS_IMAGE_KIND_UNKNOWN:	Type invalid or not known
 * @AS_IMAGE_KIND_SOURCE:	The source image at full resolution
 * @AS_IMAGE_KIND_THUMBNAIL:	A thumbnail at reduced resolution
 *
 * The image type.
 **/
typedef enum {
	AS_IMAGE_KIND_UNKNOWN,
	AS_IMAGE_KIND_SOURCE,
	AS_IMAGE_KIND_THUMBNAIL,
	/*< private >*/
	AS_IMAGE_KIND_LAST
} AsImageKind;

AsImageKind	 as_image_kind_from_string (const gchar *kind);
const gchar	*as_image_kind_to_string (AsImageKind kind);

AsImage		*as_image_new (void);

AsImageKind	 as_image_get_kind (AsImage *image);
void		 as_image_set_kind (AsImage *image,
					AsImageKind kind);

const gchar	*as_image_get_url (AsImage *image);
void		 as_image_set_url (AsImage *image,
					const gchar *url);

guint		 as_image_get_width (AsImage *image);
void		 as_image_set_width (AsImage *image,
					guint width);

guint		 as_image_get_height (AsImage *image);
void		 as_image_set_height (AsImage *image,
					guint height);

const gchar	*as_image_get_locale (AsImage *image);
void		 as_image_set_locale (AsImage *image,
				      const gchar *locale);

G_END_DECLS

#endif /* __AS_IMAGE_H */
