/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 *
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <string.h>

#include "camel-string-utils.h"

gint
camel_strcase_equal (gconstpointer a,
                     gconstpointer b)
{
	return (g_ascii_strcasecmp ((const gchar *) a, (const gchar *) b) == 0);
}

guint
camel_strcase_hash (gconstpointer v)
{
	const gchar *p = (gchar *) v;
	guint h = 0, g;

	for (; *p != '\0'; p++) {
		h = (h << 4) + g_ascii_toupper (*p);
		if ((g = h & 0xf0000000)) {
			h = h ^ (g >> 24);
			h = h ^ g;
		}
	}

	return h;
}

gchar *
camel_strstrcase (const gchar *haystack,
                  const gchar *needle)
{
	/* find the needle in the haystack neglecting case */
	const gchar *ptr;
	guint len;

	g_return_val_if_fail (haystack != NULL, NULL);
	g_return_val_if_fail (needle != NULL, NULL);

	len = strlen (needle);
	if (len > strlen (haystack))
		return NULL;

	if (len == 0)
		return (gchar *) haystack;

	for (ptr = haystack; *(ptr + len - 1) != '\0'; ptr++)
		if (!g_ascii_strncasecmp (ptr, needle, len))
			return (gchar *) ptr;

	return NULL;
}

const gchar *
camel_strdown (gchar *str)
{
	register gchar *s = str;

	while (*s) {
		if (*s >= 'A' && *s <= 'Z')
			*s += 0x20;
		s++;
	}

	return str;
}

/* working stuff for pstrings */
static GMutex string_pool_lock;
static GHashTable *string_pool = NULL;

typedef struct _StringPoolNode StringPoolNode;

struct _StringPoolNode {
	gchar *string;
	gulong ref_count;
};

static StringPoolNode *
string_pool_node_new (gchar *string)
{
	StringPoolNode *node;

	node = g_slice_new (StringPoolNode);
	node->string = string;  /* takes ownership */
	node->ref_count = 1;

	return node;
}

static void
string_pool_node_free (StringPoolNode *node)
{
	g_free (node->string);

	g_slice_free (StringPoolNode, node);
}

static guint
string_pool_node_hash (const StringPoolNode *node)
{
	return g_str_hash (node->string);
}

static gboolean
string_pool_node_equal (const StringPoolNode *node_a,
                        const StringPoolNode *node_b)
{
	return g_str_equal (node_a->string, node_b->string);
}

static void
string_pool_init (void)
{
	if (G_UNLIKELY (string_pool == NULL))
		string_pool = g_hash_table_new_full (
			(GHashFunc) string_pool_node_hash,
			(GEqualFunc) string_pool_node_equal,
			(GDestroyNotify) string_pool_node_free,
			(GDestroyNotify) NULL);
}

/**
 * camel_pstring_add:
 * @string: string to add to the string pool
 * @own: whether the string pool will own the memory pointed to by
 *       @string, if @string is not yet in the pool
 *
 * Add @string to the pool.
 *
 * The %NULL and empty strings are special cased to constant values.
 *
 * Unreference the returned string with camel_pstring_free().
 *
 * Returns: a canonicalized copy of @string
 **/
const gchar *
camel_pstring_add (gchar *string,
                   gboolean own)
{
	StringPoolNode static_node = { string, };
	StringPoolNode *node;
	const gchar *interned;

	if (string == NULL)
		return NULL;

	if (*string == '\0') {
		if (own)
			g_free (string);
		return "";
	}

	g_mutex_lock (&string_pool_lock);

	string_pool_init ();

	node = g_hash_table_lookup (string_pool, &static_node);

	if (node != NULL) {
		node->ref_count++;
		if (own)
			g_free (string);
	} else {
		if (!own)
			string = g_strdup (string);
		node = string_pool_node_new (string);
		g_hash_table_add (string_pool, node);
	}

	interned = node->string;

	g_mutex_unlock (&string_pool_lock);

	return interned;
}

/**
 * camel_pstring_peek:
 * @string: string to fetch from the string pool
 *
 * Returns the canonicalized copy of @string without increasing its
 * reference count in the string pool.  If necessary, @string is first
 * added to the string pool.
 *
 * The %NULL and empty strings are special cased to constant values.
 *
 * Returns: a canonicalized copy of @string
 *
 * Since: 2.24
 **/
const gchar *
camel_pstring_peek (const gchar *string)
{
	StringPoolNode static_node = { (gchar *) string, };
	StringPoolNode *node;
	const gchar *interned;

	if (string == NULL)
		return NULL;

	if (*string == '\0')
		return "";

	g_mutex_lock (&string_pool_lock);

	string_pool_init ();

	node = g_hash_table_lookup (string_pool, &static_node);

	if (node == NULL) {
		node = string_pool_node_new (g_strdup (string));
		g_hash_table_add (string_pool, node);
	}

	interned = node->string;

	g_mutex_unlock (&string_pool_lock);

	return interned;
}

/**
 * camel_pstring_contains:
 * @string: string to look up in the string pool
 *
 * Returns whether the @string exists in the string pool.
 *
 * The %NULL and empty strings are special cased to constant values.
 *
 * Returns: Whether the @string exists in the string pool
 *
 * Since: 3.22
 **/
gboolean
camel_pstring_contains (const gchar *string)
{
	StringPoolNode static_node = { (gchar *) string, };
	gboolean contains;

	if (string == NULL)
		return FALSE;

	if (*string == '\0')
		return FALSE;

	g_mutex_lock (&string_pool_lock);

	string_pool_init ();

	contains = g_hash_table_contains (string_pool, &static_node);

	g_mutex_unlock (&string_pool_lock);

	return contains;
}

/**
 * camel_pstring_strdup:
 * @string: string to copy
 *
 * Create a new pooled string entry for @strings.  A pooled string
 * is a table where common strings are canonicalized.  They are also
 * reference counted and freed when no longer referenced.
 *
 * The %NULL and empty strings are special cased to constant values.
 *
 * Unreference the returned string with camel_pstring_free().
 *
 * Returns: a canonicalized copy of @string
 **/
const gchar *
camel_pstring_strdup (const gchar *string)
{
	return camel_pstring_add ((gchar *) string, FALSE);
}

/**
 * camel_pstring_free:
 * @string: string to free
 *
 * Unreferences a pooled string.  If the string's reference count drops to
 * zero it will be deallocated.  %NULL and the empty string are special cased.
 **/
void
camel_pstring_free (const gchar *string)
{
	StringPoolNode static_node = { (gchar *) string, };
	StringPoolNode *node;

	if (string_pool == NULL)
		return;

	if (string == NULL || *string == '\0')
		return;

	g_mutex_lock (&string_pool_lock);

	node = g_hash_table_lookup (string_pool, &static_node);

	if (node == NULL) {
		g_warning ("%s: String not in pool: %s", G_STRFUNC, string);
	} else if (node->string != string) {
		g_warning ("%s: String is not ours: %s", G_STRFUNC, string);
	} else if (node->ref_count == 0) {
		g_warning ("%s: Orphaned pool node: %s", G_STRFUNC, string);
	} else {
		node->ref_count--;
		if (node->ref_count == 0)
			g_hash_table_remove (string_pool, node);
	}

	g_mutex_unlock (&string_pool_lock);
}

/**
 * camel_pstring_dump_stat:
 *
 * Dumps to stdout memory statistic about the string pool.
 *
 * Since: 3.6
 **/
void
camel_pstring_dump_stat (void)
{
	g_mutex_lock (&string_pool_lock);

	g_print ("   String Pool Statistics: ");

	if (string_pool == NULL) {
		g_print ("Not used yet\n");
	} else {
		GHashTableIter iter;
		gchar *format_size;
		guint64 bytes = 0;
		gpointer key;

		g_hash_table_iter_init (&iter, string_pool);

		while (g_hash_table_iter_next (&iter, &key, NULL))
			bytes += strlen (((StringPoolNode *) key)->string);

		format_size = g_format_size_full (
			bytes, G_FORMAT_SIZE_LONG_FORMAT);

		g_print (
			"Holds %d strings totaling %s\n",
			g_hash_table_size (string_pool),
			format_size);

		g_free (format_size);
	}

	g_mutex_unlock (&string_pool_lock);
}
