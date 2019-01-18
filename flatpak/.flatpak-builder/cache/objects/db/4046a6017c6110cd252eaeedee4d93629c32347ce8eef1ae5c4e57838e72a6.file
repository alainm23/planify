/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016 Lucas Moura <lucas.moura128@gmail.com>
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

#ifndef __AS_SUGGESTED_H
#define __AS_SUGGESTED_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_SUGGESTED (as_suggested_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsSuggested, as_suggested, AS, SUGGESTED, GObject)

struct _AsSuggestedClass
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
 * AsSuggestedKind:
 * @AS_SUGGESTED_KIND_UNKNOWN:		Unknown suggested kind
 * @AS_SUGGESTED_KIND_UPSTREAM:		Suggestions provided by the upstream project.
 * @AS_SUGGESTED_KIND_HEURISTIC:	Suggestions provided by automatic heuristics.
 *
 * The suggested type.
 **/
typedef enum  {
	AS_SUGGESTED_KIND_UNKNOWN,
	AS_SUGGESTED_KIND_UPSTREAM,
	AS_SUGGESTED_KIND_HEURISTIC,
	/*< private >*/
	AS_SUGGESTED_KIND_LAST
} AsSuggestedKind;

AsSuggestedKind			as_suggested_kind_from_string (const gchar *kind_str);
const gchar			*as_suggested_kind_to_string (AsSuggestedKind kind);

AsSuggested			*as_suggested_new (void);

AsSuggestedKind			as_suggested_get_kind (AsSuggested *suggested);
void				as_suggested_set_kind (AsSuggested *suggested,
							AsSuggestedKind kind);

GPtrArray			*as_suggested_get_ids (AsSuggested *suggested);
void				as_suggested_add_id (AsSuggested *suggested,
							const gchar *cid);

gboolean			as_suggested_is_valid (AsSuggested *suggested);

G_END_DECLS

#endif /* __AS_SUGGESTED_H */
