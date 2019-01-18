/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* e-file-cache.c
 *
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
 * Authors: Rodrigo Moya <rodrigo@ximian.com>
 */

/**
 * SECTION: e-file-cache
 * @short_description: Simple file-based hash table for strings
 *
 * An #EFileCache is a simple hash table of strings backed by an XML file
 * for permanent storage.  The XML file is written to disk with every unless
 * the cache is temporarily frozen with e_file_cache_freeze_changes().
 **/

#include "evolution-data-server-config.h"

#include <string.h>
#include <unistd.h>

#include <glib/gstdio.h>
#include <libedataserver/libedataserver.h>

#include "e-file-cache.h"

#define E_FILE_CACHE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_FILE_CACHE, EFileCachePrivate))

struct _EFileCachePrivate {
	gchar *filename;
	EXmlHash *xml_hash;
	gboolean dirty;
	guint32 frozen;
};

enum {
	PROP_0,
	PROP_FILENAME
};

G_DEFINE_TYPE (EFileCache, e_file_cache, G_TYPE_OBJECT)

static void
file_cache_set_filename (EFileCache *cache,
                         const gchar *filename)
{
	g_return_if_fail (filename != NULL);
	g_return_if_fail (cache->priv->filename == NULL);

	cache->priv->filename = g_strdup (filename);
}

static void
file_cache_set_property (GObject *object,
                         guint property_id,
                         const GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_FILENAME :
			file_cache_set_filename (
				E_FILE_CACHE (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
file_cache_get_property (GObject *object,
                         guint property_id,
                         GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_FILENAME :
			g_value_set_string (
				value,
				e_file_cache_get_filename (
				E_FILE_CACHE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
file_cache_finalize (GObject *object)
{
	EFileCachePrivate *priv;

	priv = E_FILE_CACHE_GET_PRIVATE (object);

	g_free (priv->filename);

	if (priv->xml_hash != NULL)
		e_xmlhash_destroy (priv->xml_hash);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_file_cache_parent_class)->finalize (object);
}

static void
file_cache_constructed (GObject *object)
{
	EFileCache *cache;
	const gchar *filename;
	gchar *dirname;

	cache = E_FILE_CACHE (object);

	filename = e_file_cache_get_filename (cache);

	/* Make sure the directory for the cache exists. */
	dirname = g_path_get_dirname (filename);
	g_mkdir_with_parents (dirname, 0700);
	g_free (dirname);

	cache->priv->xml_hash = e_xmlhash_new (filename);

	/* If opening the cache file fails, remove it and try again. */
	if (cache->priv->xml_hash == NULL) {
		g_unlink (filename);
		cache->priv->xml_hash = e_xmlhash_new (filename);
		if (cache->priv->xml_hash == NULL)
			g_warning (
				"%s: could not re-create cache file %s",
				G_STRFUNC, filename);
	}

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_file_cache_parent_class)->constructed (object);
}

static void
e_file_cache_class_init (EFileCacheClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EFileCachePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = file_cache_set_property;
	object_class->get_property = file_cache_get_property;
	object_class->finalize = file_cache_finalize;
	object_class->constructed = file_cache_constructed;

	/**
	 * EFileCache:filename
	 *
	 * The filename of the cache.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_FILENAME,
		g_param_spec_string (
			"filename",
			"Filename",
			"The filename of the cache",
			"",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));
}

static void
e_file_cache_init (EFileCache *cache)
{
	cache->priv = E_FILE_CACHE_GET_PRIVATE (cache);
}

/**
 * e_file_cache_new
 * @filename: filename where the cache is kept
 *
 * Creates a new #EFileCache object, which implements a cache of
 * objects.  Useful for remote backends.
 *
 * Returns: a new #EFileCache
 */
EFileCache *
e_file_cache_new (const gchar *filename)
{
	g_return_val_if_fail (filename != NULL, NULL);

	return g_object_new (E_TYPE_FILE_CACHE, "filename", filename, NULL);
}

/**
 * e_file_cache_remove:
 * @cache: an #EFileCache
 *
 * Remove the cache from disk.
 *
 * Returns: %TRUE if successful, %FALSE if a file error occurred
 */
gboolean
e_file_cache_remove (EFileCache *cache)
{
	EFileCachePrivate *priv;

	g_return_val_if_fail (E_IS_FILE_CACHE (cache), FALSE);

	priv = cache->priv;

	if (priv->filename) {
		gchar *dirname, *full_path;
		const gchar *fname;
		GDir *dir;
		gboolean success;

		/* remove all files in the directory */
		dirname = g_path_get_dirname (priv->filename);
		dir = g_dir_open (dirname, 0, NULL);
		if (dir) {
			while ((fname = g_dir_read_name (dir))) {
				full_path = g_build_filename (
					dirname, fname, NULL);
				if (g_unlink (full_path) != 0) {
					g_free (full_path);
					g_free (dirname);
					g_dir_close (dir);

					return FALSE;
				}

				g_free (full_path);
			}

			g_dir_close (dir);
		}

		/* remove the directory itself */
		success = g_rmdir (dirname) == 0;

		/* free all memory */
		g_free (dirname);
		g_free (priv->filename);
		priv->filename = NULL;

		e_xmlhash_destroy (priv->xml_hash);
		priv->xml_hash = NULL;

		return success;
	}

	return TRUE;
}

static void
add_key_to_slist (const gchar *key,
                  const gchar *value,
                  gpointer user_data)
{
	GSList **keys = user_data;

	*keys = g_slist_append (*keys, (gchar *) key);
}

/**
 * e_file_cache_clean:
 * @cache: an #EFileCache
 *
 * Clean up the cache's contents.
 *
 * Returns: %TRUE always
 */
gboolean
e_file_cache_clean (EFileCache *cache)
{
	GSList *keys = NULL;
	gboolean iFroze;

	g_return_val_if_fail (E_IS_FILE_CACHE (cache), FALSE);

	iFroze = !cache->priv->frozen;

	if (iFroze)
		e_file_cache_freeze_changes (cache);

	e_xmlhash_foreach_key (
		cache->priv->xml_hash,
		(EXmlHashFunc) add_key_to_slist, &keys);
	while (keys != NULL) {
		e_file_cache_remove_object (cache, (const gchar *) keys->data);
		keys = g_slist_remove (keys, keys->data);
	}

	if (iFroze)
		e_file_cache_thaw_changes (cache);

	return TRUE;
}

typedef struct {
	const gchar *key;
	gboolean found;
	const gchar *found_value;
} CacheFindData;

static void
find_object_in_hash (gpointer key,
                     gpointer value,
                     gpointer user_data)
{
	CacheFindData *find_data = user_data;

	if (find_data->found)
		return;

	if (!strcmp (find_data->key, (const gchar *) key)) {
		find_data->found = TRUE;
		find_data->found_value = (const gchar *) value;
	}
}

/**
 * e_file_cache_get_object:
 * @cache: an #EFileCache
 * @key: the hash key of the object to find
 *
 * Returns the object corresponding to @key.  If no such object exists
 * in @cache, the function returns %NULL.
 *
 * Returns: the object corresponding to @key
 */
const gchar *
e_file_cache_get_object (EFileCache *cache,
                         const gchar *key)
{
	CacheFindData find_data;

	g_return_val_if_fail (E_IS_FILE_CACHE (cache), NULL);
	g_return_val_if_fail (key != NULL, NULL);

	find_data.key = key;
	find_data.found = FALSE;
	find_data.found_value = NULL;

	e_xmlhash_foreach_key (
		cache->priv->xml_hash,
		(EXmlHashFunc) find_object_in_hash, &find_data);

	return find_data.found_value;
}

static void
add_object_to_slist (const gchar *key,
                     const gchar *value,
                     gpointer user_data)
{
	GSList **list = user_data;

	*list = g_slist_prepend (*list, (gchar *) value);
}

/**
 * e_file_cache_get_objects:
 * @cache: an #EFileCache
 *
 * Returns a list of objects in @cache.  The objects are owned by @cache and
 * must not be modified or freed.  Free the returned list with g_slist_free().
 *
 * Returns: a list of objects
 */
GSList *
e_file_cache_get_objects (EFileCache *cache)
{
	GSList *list = NULL;

	g_return_val_if_fail (E_IS_FILE_CACHE (cache), NULL);

	e_xmlhash_foreach_key (
		cache->priv->xml_hash,
		(EXmlHashFunc) add_object_to_slist, &list);

	return list;
}

/**
 * e_file_cache_get_keys:
 * @cache: an #EFileCache
 *
 * Returns a list of keys in @cache.  The keys are owned by @cache and must
 * not be modified or freed.  Free the returned list with g_slist_free().
 *
 * Returns: a list of keys
 */
GSList *
e_file_cache_get_keys (EFileCache *cache)
{
	GSList *list = NULL;

	g_return_val_if_fail (E_IS_FILE_CACHE (cache), NULL);

	e_xmlhash_foreach_key (
		cache->priv->xml_hash,
		(EXmlHashFunc) add_key_to_slist, &list);

	return list;
}

/**
 * e_file_cache_add_object:
 * @cache: an #EFileCache
 * @key: the hash key of the object to add
 * @value: the object to add
 *
 * Adds a new @key / @value entry to @cache.  If an object corresponding
 * to @key already exists in @cache, the function returns %FALSE.
 *
 * Returns: %TRUE if successful, %FALSE if @key already exists
 */
gboolean
e_file_cache_add_object (EFileCache *cache,
                         const gchar *key,
                         const gchar *value)
{
	g_return_val_if_fail (E_IS_FILE_CACHE (cache), FALSE);
	g_return_val_if_fail (key != NULL, FALSE);

	if (e_file_cache_get_object (cache, key))
		return FALSE;

	e_xmlhash_add (cache->priv->xml_hash, key, value);
	if (cache->priv->frozen)
		cache->priv->dirty = TRUE;
	else {
		e_xmlhash_write (cache->priv->xml_hash);
		cache->priv->dirty = FALSE;
	}

	return TRUE;
}

/**
 * e_file_cache_replace_object:
 * @cache: an #EFileCache
 * @key: the hash key of the object to replace
 * @new_value: the new object for @key
 *
 * Replaces the object corresponding to @key with @new_value.
 * If no such object exists in @cache, the function returns %FALSE.
 *
 * Returns: %TRUE if successful, %FALSE if @key was not found
 */
gboolean
e_file_cache_replace_object (EFileCache *cache,
                             const gchar *key,
                             const gchar *new_value)
{
	g_return_val_if_fail (E_IS_FILE_CACHE (cache), FALSE);
	g_return_val_if_fail (key != NULL, FALSE);

	if (!e_file_cache_get_object (cache, key))
		return FALSE;

	if (!e_file_cache_remove_object (cache, key))
		return FALSE;

	return e_file_cache_add_object (cache, key, new_value);
}

/**
 * e_file_cache_remove_object:
 * @cache: an #EFileCache
 * @key: the hash key of the object to remove
 *
 * Removes the object corresponding to @key from @cache.
 * If no such object exists in @cache, the function returns %FALSE.
 *
 * Returns: %TRUE if successful, %FALSE if @key was not found
 */
gboolean
e_file_cache_remove_object (EFileCache *cache,
                            const gchar *key)
{
	EFileCachePrivate *priv;

	g_return_val_if_fail (E_IS_FILE_CACHE (cache), FALSE);
	g_return_val_if_fail (key != NULL, FALSE);

	priv = cache->priv;

	if (!e_file_cache_get_object (cache, key))
		return FALSE;

	e_xmlhash_remove (priv->xml_hash, key);
	if (priv->frozen)
		priv->dirty = TRUE;
	else {
		e_xmlhash_write (priv->xml_hash);
		priv->dirty = FALSE;
	}

	return TRUE;
}

/**
 * e_file_cache_freeze_changes:
 * @cache: an #EFileCache
 *
 * Disables temporarily all writes to disk for @cache.
 */
void
e_file_cache_freeze_changes (EFileCache *cache)
{
	g_return_if_fail (E_IS_FILE_CACHE (cache));

	cache->priv->frozen++;
	g_return_if_fail (cache->priv->frozen > 0);
}

/**
 * e_file_cache_thaw_changes:
 * @cache: an #EFileCache
 *
 * Reverts the affects of e_file_cache_freeze_changes().
 * Each change to @cache is once again written to disk.
 */
void
e_file_cache_thaw_changes (EFileCache *cache)
{
	g_return_if_fail (E_IS_FILE_CACHE (cache));
	g_return_if_fail (cache->priv->frozen > 0);

	cache->priv->frozen--;
	if (!cache->priv->frozen && cache->priv->dirty) {
		e_xmlhash_write (cache->priv->xml_hash);
		cache->priv->dirty = FALSE;
	}
}

/**
 * e_file_cache_get_filename:
 * @cache: A %EFileCache object.
 *
 * Gets the name of the file where the cache is being stored.
 *
 * Returns: The name of the cache.
 */
const gchar *
e_file_cache_get_filename (EFileCache *cache)
{
	g_return_val_if_fail (E_IS_FILE_CACHE (cache), NULL);

	return cache->priv->filename;
}

