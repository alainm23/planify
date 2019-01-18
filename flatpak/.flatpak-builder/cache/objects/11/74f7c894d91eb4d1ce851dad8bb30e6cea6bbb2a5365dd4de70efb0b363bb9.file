/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2017 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_VARIANT_CACHE_H
#define __AS_VARIANT_CACHE_H

#include <glib-object.h>

G_BEGIN_DECLS
#pragma GCC visibility push(hidden)

/* version of the cache the current implementation supports */
#define CACHE_FORMAT_VERSION 1

guint32			as_variant_get_dict_uint32 (GVariantDict *dict,
						    const gchar *key);
const gchar		**as_variant_get_dict_strv (GVariantDict *dict,
						  const gchar *key, GVariant **var);
const gchar		*as_variant_get_dict_str (GVariantDict *dict,
						  const gchar *key,
						  GVariant **var);

const gchar		*as_variant_get_mstring (GVariant **var);

GVariant		*as_variant_mstring_new (const gchar *str);
const gchar		*as_variant_get_dict_mstr (GVariantDict *dict,
						   const gchar *key,
						   GVariant **var);

gint			as_variant_get_dict_int32 (GVariantDict *dict,
						   const gchar *key);

GVariant		*as_variant_from_string_ptrarray (GPtrArray *strarray);

void			as_variant_to_string_ptrarray (GVariant *var,
						       GPtrArray *dest);
void			as_variant_to_string_ptrarray_by_dict (GVariantDict *dict,
							        const gchar *key,
								GPtrArray *dest);

void			as_variant_builder_add_kv (GVariantBuilder *builder,
						   const gchar *key,
						   GVariant *value);

#pragma GCC visibility pop
G_END_DECLS

#endif /* __AS_VARIANT_CACHE_H */
