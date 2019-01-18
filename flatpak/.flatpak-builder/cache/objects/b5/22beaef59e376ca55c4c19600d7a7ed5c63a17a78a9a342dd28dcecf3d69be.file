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

#include "camel-string-utils.h"

#include "camel-name-value-array.h"

G_DEFINE_BOXED_TYPE (CamelNameValueArray,
		camel_name_value_array,
		camel_name_value_array_copy,
		camel_name_value_array_free)

typedef struct _CamelNameValuePair {
	gchar *name;
	gchar *value;
} CamelNameValuePair;

static void
free_name_value_content (gpointer ptr)
{
	CamelNameValuePair *pair = ptr;

	if (pair) {
		g_free (pair->name);
		g_free (pair->value);

		pair->name = NULL;
		pair->value = NULL;
	}
}

/**
 * camel_name_value_array_new:
 *
 * Creates a new #CamelNameValueArray. The returned pointer should be freed
 * with camel_name_value_array_free() when no longer needed.
 *
 * Returns: (transfer full): A new #CamelNameValueArray.
 *
 * See: camel_name_value_array_new_sized, camel_name_value_array_copy
 *
 * Since: 3.24
 **/
CamelNameValueArray *
camel_name_value_array_new (void)
{
	GArray *arr;

	arr = g_array_new (FALSE, FALSE, sizeof (CamelNameValuePair));
	g_array_set_clear_func (arr, free_name_value_content);

	return (CamelNameValueArray *) arr;
}

/**
 * camel_name_value_array_new_sized:
 * @reserve_size: an array size to reserve
 *
 * Creates a new #CamelNameValueArray, which has reserved @reserve_size
 * elements. This value doesn't influence the camel_name_value_array_get_length(),
 * which returns zero on the array returned from this function. The returned
 * pointer should be freed with camel_name_value_array_free() when no longer needed.
 *
 * Returns: (transfer full): A new #CamelNameValueArray.
 *
 * See: camel_name_value_array_new, camel_name_value_array_copy
 *
 * Since: 3.24
 **/
CamelNameValueArray *
camel_name_value_array_new_sized (guint reserve_size)
{
	GArray *arr;

	arr = g_array_sized_new (FALSE, FALSE, sizeof (CamelNameValuePair), reserve_size);
	g_array_set_clear_func (arr, free_name_value_content);

	return (CamelNameValueArray *) arr;
}

/**
 * camel_name_value_array_copy:
 * @array: (nullable): a #CamelNameValueArray
 *
 * Creates a new copy of the @array. The returned pointer should be freed
 * with camel_name_value_array_free() when no longer needed.
 *
 * Returns: (transfer full): A new copy of the @array.
 *
 * See: camel_name_value_array_new, camel_name_value_array_new_sized
 *
 * Since: 3.24
 **/
CamelNameValueArray *
camel_name_value_array_copy (const CamelNameValueArray *array)
{
	CamelNameValueArray *copy;
	guint ii, len;

	if (!array)
		return NULL;

	len = camel_name_value_array_get_length (array);
	copy = camel_name_value_array_new_sized (len);

	for (ii = 0; ii < len; ii++) {
		const gchar *name = NULL, *value = NULL;

		if (camel_name_value_array_get (array, ii, &name, &value))
			camel_name_value_array_append (copy, name, value);
	}

	return copy;
}

/**
 * camel_name_value_array_free:
 * @array: (nullable): a #CamelNameValueArray, or %NULL
 *
 * Frees the @array, previously allocated by camel_name_value_array_new(),
 * camel_name_value_array_new_sized() or camel_name_value_array_copy().
 * If the @array is %NULL, then does nothing.
 *
 * Since: 3.24
 **/
void
camel_name_value_array_free (CamelNameValueArray *array)
{
	if (array)
		g_array_free ((GArray *) array, TRUE);
}

/**
 * camel_name_value_array_get_length:
 * @array: (nullable): a #CamelNameValueArray
 *
 * Returns: Length of the @array, aka how many elements are stored in the @array.
 *
 * Since: 3.24
 **/
guint
camel_name_value_array_get_length (const CamelNameValueArray *array)
{
	GArray *arr = (GArray *) array;

	if (!array)
		return 0;

	return arr->len;
}

/**
 * camel_name_value_array_get:
 * @array: a #CamelNameValueArray
 * @index: an index
 * @out_name: (out) (nullable): A place to store the name of the element, or %NULL
 * @out_value: (out) (nullable): A place to store the value of the element, or %NULL
 *
 * Returns the name and the value of the element at index @index. Either
 * of the @out_name and @out_value can be %NULL, to not return that part.
 *
 * Returns: %TRUE on success, %FALSE otherwise.
 *
 * See: camel_name_value_array_get_name, camel_name_value_array_get_value, camel_name_value_array_get_named
 *
 * Since: 3.24
 **/
gboolean
camel_name_value_array_get (const CamelNameValueArray *array,
			    guint index,
			    const gchar **out_name,
			    const gchar **out_value)
{
	GArray *arr = (GArray *) array;
	CamelNameValuePair *pair;

	g_return_val_if_fail (array != NULL, FALSE);

	if (index >= camel_name_value_array_get_length (array))
		return FALSE;

	pair = &g_array_index (arr, CamelNameValuePair, index);

	if (out_name)
		*out_name = pair->name;
	if (out_value)
		*out_value= pair->value;

	return TRUE;
}

static guint
camel_name_value_array_find_named (const CamelNameValueArray *array,
				   CamelCompareType compare_type,
				   const gchar *name)
{
	GArray *arr = (GArray *) array;
	gboolean case_sensitive;
	gint ii;

	g_return_val_if_fail (array != NULL, (guint) -1);
	g_return_val_if_fail (name != NULL, (guint) -1);

	case_sensitive = compare_type == CAMEL_COMPARE_CASE_SENSITIVE;

	for (ii = 0; ii < arr->len; ii++) {
		CamelNameValuePair *pair = &g_array_index (arr, CamelNameValuePair, ii);

		if ((case_sensitive && g_strcmp0 (name, pair->name) == 0) ||
		    (!case_sensitive && pair->name && camel_strcase_equal (name, pair->name))) {
			return ii;
		}
	}

	return (guint) -1;
}

/**
 * camel_name_value_array_get_named:
 * @array: a #CamelNameValueArray
 * @compare_type: a compare type, one of #CamelCompareType
 * @name: a name
 *
 * Returns the value of the first element named @name, or %NULL when there
 * is no element of such @name in the @array. The @compare_type determines
 * how to compare the names.
 *
 * Returns: (transfer none) (nullable): Value of the first element named @name, or %NULL.
 *
 * See: camel_name_value_array_get, camel_name_value_array_get_name
 *
 * Since: 3.24
 **/
const gchar *
camel_name_value_array_get_named (const CamelNameValueArray *array,
				  CamelCompareType compare_type,
				  const gchar *name)
{
	guint index;

	g_return_val_if_fail (array != NULL, NULL);
	g_return_val_if_fail (name != NULL, NULL);

	index = camel_name_value_array_find_named (array, compare_type, name);
	if (index == (guint) -1)
		return NULL;

	return camel_name_value_array_get_value (array, index);
}

/**
 * camel_name_value_array_get_name:
 * @array: a #CamelNameValueArray
 * @index: an index
 *
 * Returns the name of the element at index @index.
 *
 * Returns: (transfer none) (nullable): Name of the element at the given @index,
 *    or %NULL on error.
 *
 * See: camel_name_value_array_get, camel_name_value_array_get_value
 *
 * Since: 3.24
 **/
const gchar *
camel_name_value_array_get_name (const CamelNameValueArray *array,
				 guint index)
{
	const gchar *name = NULL;

	g_return_val_if_fail (array != NULL, NULL);

	if (!camel_name_value_array_get (array, index, &name, NULL))
		return NULL;

	return name;
}

/**
 * camel_name_value_array_get_value:
 * @array: a #CamelNameValueArray
 * @index: an index
 *
 * Returns the value of the element at index @index.
 *
 * Returns: (transfer none) (nullable): Value of the element at the given @index,
 *    or %NULL on error.
 *
 * See: camel_name_value_array_get, camel_name_value_array_get_name
 *
 * Since: 3.24
 **/
const gchar *
camel_name_value_array_get_value (const CamelNameValueArray *array,
				  guint index)
{
	const gchar *value = NULL;

	g_return_val_if_fail (array != NULL, NULL);

	if (!camel_name_value_array_get (array, index, NULL, &value))
		return NULL;

	return value;
}

/**
 * camel_name_value_array_append:
 * @array: a #CamelNameValueArray
 * @name: a name
 * @value: a value
 *
 * Appends a new element of the name @name and the value @value
 * at the end of @array.
 *
 * See: camel_name_value_array_set_named
 *
 * Since: 3.24
 **/
void
camel_name_value_array_append (CamelNameValueArray *array,
			       const gchar *name,
			       const gchar *value)
{
	GArray *arr = (GArray *) array;
	CamelNameValuePair pair;

	g_return_if_fail (array != NULL);
	g_return_if_fail (name != NULL);
	g_return_if_fail (value != NULL);

	pair.name = g_strdup (name);
	pair.value = g_strdup (value);

	g_array_append_val (arr, pair);
}

static gboolean
camel_name_value_array_set_internal (CamelNameValueArray *array,
				     guint index,
				     const gchar *name,
				     const gchar *value)
{
	GArray *arr = (GArray *) array;
	CamelNameValuePair *pair;
	gboolean changed = FALSE;

	g_return_val_if_fail (array != NULL, FALSE);
	g_return_val_if_fail (index < camel_name_value_array_get_length (array), FALSE);

	pair = &g_array_index (arr, CamelNameValuePair, index);

	if (name && g_strcmp0 (pair->name, name) != 0) {
		g_free (pair->name);
		pair->name = g_strdup (name);
		changed = TRUE;
	}

	if (value && g_strcmp0 (pair->value, value) != 0) {
		g_free (pair->value);
		pair->value = g_strdup (value);
		changed = TRUE;
	}

	return changed;
}

/**
 * camel_name_value_array_set:
 * @array: a #CamelNameValueArray
 * @index: an index
 * @name: a name
 * @value: a value
 *
 * Sets both the @name and the @value of the element at index @index.
 *
 * Returns: Whether the @array changed.
 *
 * See: camel_name_value_array_append, camel_name_value_array_set_name, camel_name_value_array_set_value
 *
 * Since: 3.24
 **/
gboolean
camel_name_value_array_set (CamelNameValueArray *array,
			    guint index,
			    const gchar *name,
			    const gchar *value)
{
	g_return_val_if_fail (array != NULL, FALSE);
	g_return_val_if_fail (index < camel_name_value_array_get_length (array), FALSE);
	g_return_val_if_fail (name != NULL, FALSE);
	g_return_val_if_fail (value != NULL, FALSE);

	return camel_name_value_array_set_internal (array, index, name, value);
}

/**
 * camel_name_value_array_set_name:
 * @array: a #CamelNameValueArray
 * @index: an index
 * @name: a name
 *
 * Sets the @name of the element at index @index.
 *
 * Returns: Whether the @array changed.
 *
 * See: camel_name_value_array_set, camel_name_value_array_set_value
 *
 * Since: 3.24
 **/
gboolean
camel_name_value_array_set_name (CamelNameValueArray *array,
				 guint index,
				 const gchar *name)
{
	g_return_val_if_fail (array != NULL, FALSE);
	g_return_val_if_fail (index < camel_name_value_array_get_length (array), FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	return camel_name_value_array_set_internal (array, index, name, NULL);
}

/**
 * camel_name_value_array_set_value:
 * @array: a #CamelNameValueArray
 * @index: an index
 * @value: a value
 *
 * Sets the @value of the element at index @index.
 *
 * Returns: Whether the @array changed.
 *
 * See: camel_name_value_array_set, camel_name_value_array_set_name
 *
 * Since: 3.24
 **/
gboolean
camel_name_value_array_set_value (CamelNameValueArray *array,
				  guint index,
				  const gchar *value)
{
	g_return_val_if_fail (array != NULL, FALSE);
	g_return_val_if_fail (index < camel_name_value_array_get_length (array), FALSE);
	g_return_val_if_fail (value != NULL, FALSE);

	return camel_name_value_array_set_internal (array, index, NULL, value);
}

/**
 * camel_name_value_array_set_named:
 * @array: a #CamelNameValueArray
 * @compare_type: a compare type, one of #CamelCompareType
 * @name: a name
 * @value: a value
 *
 * Finds an element named @name and sets its value to @value, or appends
 * a new element, in case no such named element exists in the @array yet.
 * In case there are more elements named with @name only the first
 * occurrence is changed. The @compare_type determines how to compare
 * the names.
 *
 * Returns: Whether the @array changed.
 *
 * See: camel_name_value_array_append, camel_name_value_array_set
 *
 * Since: 3.24
 **/
gboolean
camel_name_value_array_set_named (CamelNameValueArray *array,
				  CamelCompareType compare_type,
				  const gchar *name,
				  const gchar *value)
{
	gboolean changed = FALSE;
	guint index;

	g_return_val_if_fail (array != NULL, FALSE);
	g_return_val_if_fail (name != NULL, FALSE);
	g_return_val_if_fail (value != NULL, FALSE);

	index = camel_name_value_array_find_named (array, compare_type, name);
	if (index == (guint) -1) {
		camel_name_value_array_append (array, name, value);
		changed = TRUE;
	} else {
		changed = camel_name_value_array_set_value (array, index, value);
	}

	return changed;
}

/**
 * camel_name_value_array_remove:
 * @array: a #CamelNameValueArray
 * @index: an index to remove
 *
 * Removes element at index @index.
 *
 * Returns: Whether the element was removed.
 *
 * Since: 3.24
 **/
gboolean
camel_name_value_array_remove (CamelNameValueArray *array,
			       guint index)
{
	g_return_val_if_fail (array != NULL, FALSE);
	g_return_val_if_fail (index < camel_name_value_array_get_length (array), FALSE);

	g_array_remove_index ((GArray *) array, index);

	return TRUE;
}

/**
 * camel_name_value_array_remove_named:
 * @array: a #CamelNameValueArray
 * @compare_type: a compare type, one of #CamelCompareType
 * @name: a name to remove
 * @all_occurrences: whether to remove all occurrences of the @name
 *
 * Removes elements of the @array with the given @name.
 * The @compare_type determines hot to compare the names.
 * If the @all_occurrences is set to %TRUE, then every elements with the @name
 * are removed, otherwise only the first occurrence is removed.
 *
 * Returns: How many elements had been removed.
 *
 * Since: 3.24
 **/
guint
camel_name_value_array_remove_named (CamelNameValueArray *array,
				     CamelCompareType compare_type,
				     const gchar *name,
				     gboolean all_occurrences)
{
	guint index, removed = 0;

	g_return_val_if_fail (array != NULL, 0);
	g_return_val_if_fail (name != NULL, 0);

	while (index = camel_name_value_array_find_named (array, compare_type, name), index != (guint) -1) {
		if (!camel_name_value_array_remove (array, index))
			break;

		removed++;

		if (!all_occurrences)
			break;
	}

	return removed;
}

/**
 * camel_name_value_array_clear:
 * @array: a #CamelNameValueArray
 *
 * Removes all elements of the @array.
 *
 * Since: 3.24
 **/
void
camel_name_value_array_clear (CamelNameValueArray *array)
{
	GArray *arr = (GArray *) array;

	g_return_if_fail (array != NULL);

	g_array_remove_range (arr, 0, arr->len);
}

/**
 * camel_name_value_array_equal:
 * @array_a: (nullable): the first #CamelNameValueArray
 * @array_b: (nullable): the second #CamelNameValueArray
 * @compare_type: a compare type, one of #CamelCompareType
 *
 * Compares content of the two #CamelNameValueArray and returns whether
 * they equal. Note this is an expensive operation for large arrays.
 *
 * Returns: Whether the two #CamelNameValueArray have the same content.
 *
 * Since: 3.24
 **/
gboolean
camel_name_value_array_equal (const CamelNameValueArray *array_a,
			      const CamelNameValueArray *array_b,
			      CamelCompareType compare_type)
{
	guint ii, len;

	if (array_a == array_b)
		return TRUE;

	if (!array_a || !array_b)
		return camel_name_value_array_get_length (array_a) == camel_name_value_array_get_length (array_b);

	len = camel_name_value_array_get_length (array_a);
	if (len != camel_name_value_array_get_length (array_b))
		return FALSE;

	for (ii = 0; ii < len; ii++) {
		const gchar *value1, *value2;

		value1 = camel_name_value_array_get_value (array_a, ii);
		value2 = camel_name_value_array_get_named (array_b, compare_type,
			camel_name_value_array_get_name (array_a, ii));

		if (g_strcmp0 (value1, value2) != 0)
			return FALSE;
	}

	return TRUE;
}
