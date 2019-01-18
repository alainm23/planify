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

#ifndef __AS_TRANSLATION_H
#define __AS_TRANSLATION_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_TRANSLATION (as_translation_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsTranslation, as_translation, AS, TRANSLATION, GObject)

struct _AsTranslationClass
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
 * AsTranslationKind:
 * @AS_TRANSLATION_KIND_UNKNOWN:	Type invalid or not known
 * @AS_TRANSLATION_KIND_GETTEXT:	Gettext translation domain
 * @AS_TRANSLATION_KIND_QT:		Qt translation domain
 *
 * The translation type.
 **/
typedef enum {
	AS_TRANSLATION_KIND_UNKNOWN,
	AS_TRANSLATION_KIND_GETTEXT,
	AS_TRANSLATION_KIND_QT,
	/*< private >*/
	AS_TRANSLATION_KIND_LAST
} AsTranslationKind;

const gchar		*as_translation_kind_to_string (AsTranslationKind kind);
AsTranslationKind	as_translation_kind_from_string (const gchar *kind_str);

AsTranslation		*as_translation_new (void);

AsTranslationKind	as_translation_get_kind (AsTranslation *tr);
void			as_translation_set_kind (AsTranslation *tr,
						AsTranslationKind kind);

const gchar		*as_translation_get_id (AsTranslation *tr);
void			as_translation_set_id (AsTranslation *tr,
					       const gchar *id);

G_END_DECLS

#endif /* __AS_TRANSLATION_H */
