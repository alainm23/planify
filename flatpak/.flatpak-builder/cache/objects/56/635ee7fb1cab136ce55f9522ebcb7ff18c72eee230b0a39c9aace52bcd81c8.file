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

#include "as-variant-cache.h"

#include "as-utils.h"
#include "as-utils-private.h"
#include "as-component-private.h"

/**
 * SECTION:as-variant-cache
 * @short_description: Helper functions for AppStream's GVariant-based on-disk serialization.
 * @include: appstream.h
 */

#define CACHE_FORMAT_VERSION 1

/**
 * as_variant_get_dict_uint32:
 *
 * Get a an uint32 from a dictionary.
 */
guint32
as_variant_get_dict_uint32 (GVariantDict *dict, const gchar *key)
{
	g_autoptr(GVariant) val = NULL;
	val = g_variant_dict_lookup_value (dict,
					   key,
					   G_VARIANT_TYPE_UINT32);
	return g_variant_get_uint32 (val);
}

/**
 * as_variant_get_dict_str:
 *
 * Get a string from a GVariant dictionary.
 */
const gchar*
as_variant_get_dict_str (GVariantDict *dict, const gchar *key, GVariant **var)
{
	*var = g_variant_dict_lookup_value (dict,
					   key,
					   G_VARIANT_TYPE_STRING);
	return g_variant_get_string (*var, NULL);
}

/**
 * as_variant_get_dict_strv:
 *
 * Get a strv from a dictionary.
 *
 * returns: (transfer container): A gchar**
 */
const gchar**
as_variant_get_dict_strv (GVariantDict *dict, const gchar *key, GVariant **var)
{
	*var = g_variant_dict_lookup_value (dict,
					   key,
					   G_VARIANT_TYPE_STRING_ARRAY);
	return g_variant_get_strv (*var, NULL);
}

/**
 * as_variant_maybe_string_new:
 *
 * Create a string wrapped in a maybe GVariant.
 */
const gchar*
as_variant_get_mstring (GVariant **var)
{
	GVariant *tmp;

	if (*var == NULL)
		return NULL;

	tmp = g_variant_get_maybe (*var);
	if (tmp == NULL)
		return NULL;
	g_variant_unref (*var);
	*var = tmp;

	return g_variant_get_string (*var, NULL);
}

/**
 * as_variant_mstring_new:
 *
 * Create a string wrapped in a maybe GVariant.
 */
GVariant*
as_variant_mstring_new (const gchar *str)
{
	GVariant *res;

	if (str == NULL)
		res = g_variant_new_maybe (G_VARIANT_TYPE_STRING, NULL);
	else
		res = g_variant_new_maybe (G_VARIANT_TYPE_STRING,
					g_variant_new_string (str));
	return res;
}

/**
 * as_variant_get_dict_mstr:
 *
 * Get a string wrapped in a maybe GVariant from a dictionary.
 */
const gchar*
as_variant_get_dict_mstr (GVariantDict *dict, const gchar *key, GVariant **var)
{
	*var = g_variant_dict_lookup_value (dict,
					   key,
					   G_VARIANT_TYPE_MAYBE);
	return as_variant_get_mstring (var);
}

/**
 * as_variant_get_dict_int32:
 *
 * Get a an uint32 from a dictionary.
 */
gint
as_variant_get_dict_int32 (GVariantDict *dict, const gchar *key)
{
	g_autoptr(GVariant) val = NULL;
	val = g_variant_dict_lookup_value (dict,
					   key,
					   G_VARIANT_TYPE_INT32);
	return g_variant_get_int32 (val);
}

/**
 * as_variant_from_string_ptrarray:
 *
 * Add key/value pair with a string key and variant value.
 */
GVariant*
as_variant_from_string_ptrarray (GPtrArray *strarray)
{
	GVariantBuilder ab;
	guint i;

	if ((strarray == NULL) || (strarray->len == 0))
		return NULL;

	g_variant_builder_init (&ab, G_VARIANT_TYPE_STRING_ARRAY);
	for (i = 0; i < strarray->len; i++) {
		const gchar *str = (const gchar*) g_ptr_array_index (strarray, i);
		g_variant_builder_add_value (&ab, g_variant_new_string (str));
	}

	return g_variant_builder_end (&ab);
}

/**
 * as_variant_to_string_ptrarray:
 *
 * Add contents of array-type variant to string list.
 */
void
as_variant_to_string_ptrarray (GVariant *var, GPtrArray *dest)
{
	GVariant *child;
	GVariantIter iter;

	g_variant_iter_init (&iter, var);
	while ((child = g_variant_iter_next_value (&iter))) {
		g_ptr_array_add (dest, g_variant_dup_string (child, NULL));
		g_variant_unref (child);
	}
}

/**
 * as_variant_to_string_ptrarray_by_dict:
 *
 * Add contents of array-type variant to string list using a dictionary key
 * to get the source variant.
 */
void
as_variant_to_string_ptrarray_by_dict (GVariantDict *dict, const gchar *key, GPtrArray *dest)
{
	g_autoptr(GVariant) var = NULL;

	var = g_variant_dict_lookup_value (dict, key, G_VARIANT_TYPE_STRING_ARRAY);
	if (var != NULL)
		as_variant_to_string_ptrarray (var, dest);
}

/**
 * as_variant_builder_add_kv:
 *
 * Add key/value pair with a string key and variant value.
 */
void
as_variant_builder_add_kv (GVariantBuilder *builder, const gchar *key, GVariant *value)
{
	if (value == NULL)
		return;
	g_variant_builder_add (builder, "{sv}", key, value);
}
