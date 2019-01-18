/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2016 Red Hat, Inc. (www.redhat.com)
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <string.h>

#include "camel-named-flags.h"

G_DEFINE_BOXED_TYPE (CamelNamedFlags,
		camel_named_flags,
		camel_named_flags_copy,
		camel_named_flags_free)

/**
 * camel_named_flags_new:
 *
 * Creates a new #CamelNamedFlags.
 *
 * Returns: (transfer full): A newly allocated #CamelNamedFlags.
 *    Free it with camel_named_flags_free() when done with it.
 *
 * Since: 3.24
 **/
CamelNamedFlags *
camel_named_flags_new (void)
{
	return (CamelNamedFlags *) g_ptr_array_new_with_free_func (g_free);
}

/**
 * camel_named_flags_new_sized:
 * @reserve_size: an array size to reserve
 *
 * Created a new #CamelNamedFlags, which has reserved @reserve_size
 * elements. This value doesn't influence the camel_named_flags_get_length(),
 * which returns zero on the array returned from this function.
 *
 * Returns: (transfer full): A newly allocated #CamelNameValueArray.
 *    Free it with camel_named_flags_free() when done with it.
 *
 * See: camel_name_value_array_new, camel_name_value_array_copy
 *
 * Since: 3.24
 **/
CamelNamedFlags *
camel_named_flags_new_sized (guint reserve_size)
{
	return (CamelNamedFlags *) g_ptr_array_new_full (reserve_size, g_free);
}

/**
 * camel_named_flags_copy:
 * @named_flags: (nullable): a #CamelNamedFlags
 *
 * Creates a copy of the @named_flags and returns it.
 *
 * Returns: (transfer full): A newly allocated #CamelNamedFlags.
 *    Free it with camel_named_flags_free() when done with it.
 *
 * Since: 3.24
 **/
CamelNamedFlags *
camel_named_flags_copy (const CamelNamedFlags *named_flags)
{
	const GPtrArray *src = (const GPtrArray *) named_flags;
	GPtrArray *arr;
	guint ii;

	if (!src)
		return NULL;

	arr = (GPtrArray *) camel_named_flags_new_sized (src->len);
	for (ii = 0; ii < src->len; ii++) {
		const gchar *name = g_ptr_array_index (src, ii);

		if (name && *name)
			g_ptr_array_add (arr, g_strdup (name));
	}

	return (CamelNamedFlags *) arr;
}

/**
 * camel_named_flags_free:
 * @named_flags: (nullable): a #CamelNamedFlags, or %NULL
 *
 * Frees memory associated iwth the @named_flags. Does nothing,
 * if @named_flags is %NULL.
 *
 * Since: 3.24
 **/
void
camel_named_flags_free (CamelNamedFlags *named_flags)
{
	if (named_flags)
		g_ptr_array_unref ((GPtrArray *) named_flags);
}

static guint
camel_named_flags_find (const CamelNamedFlags *named_flags,
			const gchar *name)
{
	GPtrArray *arr = (GPtrArray *) named_flags;
	guint ii;

	g_return_val_if_fail (named_flags != NULL, (guint) -1);
	g_return_val_if_fail (name != NULL, (guint) -1);

	for (ii = 0; ii < arr->len; ii++) {
		const gchar *nm = g_ptr_array_index (arr, ii);

		if (g_strcmp0 (nm, name) == 0)
			return ii;
	}

	return (guint) -1;
}

/**
 * camel_named_flags_insert:
 * @named_flags: a #CamelNamedFlags
 * @name: name of the flag
 *
 * Inserts a flag named @name into the @named_flags, if it is not included
 * already (comparing case sensitively), or does nothing otherwise.
 *
 * Returns: %TRUE the flag named @name was inserted; %FALSE otherwise.
 *
 * Since: 3.24
 **/
gboolean
camel_named_flags_insert (CamelNamedFlags *named_flags,
			  const gchar *name)
{
	GPtrArray *arr = (GPtrArray *) named_flags;
	guint index;

	g_return_val_if_fail (named_flags != NULL, FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	index = camel_named_flags_find (named_flags, name);

	/* already there */
	if (index != (guint) -1)
		return FALSE;

	g_ptr_array_add (arr, g_strdup (name));

	return TRUE;
}

/**
 * camel_named_flags_remove:
 * @named_flags: a #CamelNamedFlags
 * @name: name of the flag
 *
 * Removes a flag named @name from the @named_flags.
 *
 * Returns: %TRUE when the @named_flags contained a flag named @name,
 *    comparing case sensitively, and it was removed; %FALSE otherwise.
 *
 * Since: 3.24
 **/
gboolean
camel_named_flags_remove (CamelNamedFlags *named_flags,
			  const gchar *name)
{
	GPtrArray *arr = (GPtrArray *) named_flags;
	guint index;

	g_return_val_if_fail (named_flags != NULL, FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	index = camel_named_flags_find (named_flags, name);

	/* not there */
	if (index == (guint) -1)
		return FALSE;

	g_ptr_array_remove_index (arr, index);

	return TRUE;
}

/**
 * camel_named_flags_contains:
 * @named_flags: a #CamelNamedFlags
 * @name: name of the flag
 *
 * Returns: Whether the @named_flags contains a flag named @name,
 *    comparing case sensitively.
 *
 * Since: 3.24
 **/
gboolean
camel_named_flags_contains (const CamelNamedFlags *named_flags,
			    const gchar *name)
{
	g_return_val_if_fail (named_flags != NULL, FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	return camel_named_flags_find (named_flags, name) != (guint) -1;
}

/**
 * camel_named_flags_clear:
 * @named_flags: a #CamelNamedFlags
 *
 * Removes all the elements of the array.
 *
 * Since: 3.24
 **/
void
camel_named_flags_clear (CamelNamedFlags *named_flags)
{
	GPtrArray *arr = (GPtrArray *) named_flags;

	g_return_if_fail (named_flags != NULL);

	if (arr->len)
		g_ptr_array_remove_range (arr, 0, arr->len);
}

/**
 * camel_named_flags_get_length:
 * @named_flags: (nullable): a #CamelNamedFlags
 *
 * Returns: Length of the array, aka how many named flags are stored there.
 *
 * Since: 3.24
 **/
guint
camel_named_flags_get_length (const CamelNamedFlags *named_flags)
{
	const GPtrArray *arr = (const GPtrArray *) named_flags;

	if (!named_flags)
		return 0;

	return arr->len;
}

/**
 * camel_named_flags_get:
 * @named_flags: a #CamelNamedFlags
 * @index: an index of an element
 *
 * Returns: (transfer none) (nullable): Name of the flag in at the given @index,
 *   or %NULL on error.
 *
 * Since: 3.24
 **/
const gchar *
camel_named_flags_get (const CamelNamedFlags *named_flags,
		       guint index)
{
	const GPtrArray *arr = (const GPtrArray *) named_flags;

	g_return_val_if_fail (named_flags != NULL, NULL);

	if (index >= camel_named_flags_get_length (named_flags))
		return NULL;

	return g_ptr_array_index (arr, index);
}

/**
 * camel_named_flags_equal:
 * @named_flags_a: (nullable): the first #CamelNamedFlags
 * @named_flags_b: (nullable): the second #CamelNamedFlags
 *
 * Compares content of the two #CamelNamedFlags and returns whether
 * they equal. Note this is an expensive operation for large sets.
 *
 * Returns: Whether the two #CamelNamedFlags have the same content.
 *
 * Since: 3.24
 **/
gboolean
camel_named_flags_equal (const CamelNamedFlags *named_flags_a,
			 const CamelNamedFlags *named_flags_b)
{
	guint ii, len;

	if (named_flags_a == named_flags_b)
		return TRUE;

	if (!named_flags_a || !named_flags_b)
		return camel_named_flags_get_length (named_flags_a) == camel_named_flags_get_length (named_flags_b);

	len = camel_named_flags_get_length (named_flags_a);
	if (len != camel_named_flags_get_length (named_flags_b))
		return FALSE;

	for (ii = 0; ii < len; ii++) {
		if (!camel_named_flags_contains (named_flags_a, camel_named_flags_get (named_flags_b, ii)))
			return FALSE;
	}

	return TRUE;
}
