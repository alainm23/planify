/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
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

/**
 * SECTION: e-cache
 * @include: libebackend/libebackend.h
 * @short_description: An SQLite data cache
 *
 * The #ECache is an abstract class which consists of the common
 * parts which can be used by its descendants. It also allows
 * storing offline state for the stored objects.
 *
 * The API is thread safe, with special considerations to be made
 * around e_cache_lock() and e_cache_unlock() for
 * the sake of isolating transactions across threads.
 **/

#include "evolution-data-server-config.h"

#include <errno.h>
#include <sqlite3.h>

#include <glib.h>
#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include <camel/camel.h>
#include <libedataserver/libedataserver.h>

#include "e-sqlite3-vfs.h"

#include "e-cache.h"

#define E_CACHE_KEY_VERSION	"version"
#define E_CACHE_KEY_REVISION	"revision"

/* The number of SQLite virtual machine instructions that are
 * evaluated at a time, the user passed GCancellable is
 * checked between each batch of evaluated instructions.
 */
#define E_CACHE_CANCEL_BATCH_SIZE	200

/* How many rows to read when e_cache_foreach_update() */
#define E_CACHE_UPDATE_BATCH_SIZE	100

struct _ECachePrivate {
	gchar *filename;
	sqlite3 *db;

	GRecMutex lock;			/* Main API lock */
	guint32 in_transaction;		/* Nested transaction counter */
	ECacheLockType lock_type;	/* The lock type acquired for the current transaction */
	GCancellable *cancellable;	/* User passed GCancellable, we abort an operation if cancelled */

	guint32 revision_change_frozen;
	gint revision_counter;
	gint64 last_revision_time;
	gboolean needs_revision_change;
};

enum {
	BEFORE_PUT,
	BEFORE_REMOVE,
	REVISION_CHANGED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_QUARK (e-cache-error-quark, e_cache_error)

G_DEFINE_ABSTRACT_TYPE (ECache, e_cache, G_TYPE_OBJECT)

G_DEFINE_BOXED_TYPE (ECacheColumnValues, e_cache_column_values, e_cache_column_values_copy, e_cache_column_values_free)
G_DEFINE_BOXED_TYPE (ECacheOfflineChange, e_cache_offline_change, e_cache_offline_change_copy, e_cache_offline_change_free)
G_DEFINE_BOXED_TYPE (ECacheColumnInfo, e_cache_column_info, e_cache_column_info_copy, e_cache_column_info_free)

/**
 * e_cache_column_values_new:
 *
 * Creates a new #ECacheColumnValues to store values for additional columns.
 * The column names are compared case insensitively.
 *
 * Returns: (transfer full): a new #ECacheColumnValues. Free with e_cache_column_values_free(),
 *    when no longer needed.
 *
 * Since: 3.26
 **/
ECacheColumnValues *
e_cache_column_values_new (void)
{
	return (ECacheColumnValues *) g_hash_table_new_full (camel_strcase_hash, camel_strcase_equal, g_free, g_free);
}

/**
 * e_cache_column_values_copy:
 * @other_columns: (nullable): an #ECacheColumnValues
 *
 * Returns: (transfer full): Copy of the @other_columns. Free with
 *    e_cache_column_values_free(), when no longer needed.
 *
 * Since: 3.26
 **/
ECacheColumnValues *
e_cache_column_values_copy (ECacheColumnValues *other_columns)
{
	GHashTableIter iter;
	gpointer name, value;
	ECacheColumnValues *copy;

	if (!other_columns)
		return NULL;

	copy = e_cache_column_values_new ();

	e_cache_column_values_init_iter (other_columns, &iter);
	while (g_hash_table_iter_next (&iter, &name, &value)) {
		e_cache_column_values_put (copy, name, value);
	}

	return copy;
}

/**
 * e_cache_column_values_free:
 * @other_columns: (nullable): an #ECacheColumnValues
 *
 * Frees previously allocated @other_columns with
 * e_cache_column_values_new() or e_cache_column_values_copy().
 *
 * Since: 3.26
 **/
void
e_cache_column_values_free (ECacheColumnValues *other_columns)
{
	if (other_columns)
		g_hash_table_destroy ((GHashTable *) other_columns);
}

/**
 * e_cache_column_values_put:
 * @other_columns: an #ECacheColumnValues
 * @name: a column name
 * @value: (nullable): a column value
 *
 * Puts the @value for column @name. If contains a value for the same
 * column, then it is replaced. This creates a copy of both @name
 * and @value.
 *
 * Since: 3.26
 **/
void
e_cache_column_values_put (ECacheColumnValues *other_columns,
			   const gchar *name,
			   const gchar *value)
{
	GHashTable *hash_table = (GHashTable *) other_columns;

	g_return_if_fail (other_columns != NULL);
	g_return_if_fail (name != NULL);

	g_hash_table_insert (hash_table, g_strdup (name), g_strdup (value));
}

/**
 * e_cache_column_values_take_value:
 * @other_columns: an #ECacheColumnValues
 * @name: a column name
 * @value: (nullable) (in) (transfer full): a column value
 *
 * Puts the @value for column @name. If contains a value for the same
 * column, then it is replaced. This creates a copy of the @name, but
 * takes owner ship of the @value.
 *
 * Since: 3.26
 **/
void
e_cache_column_values_take_value (ECacheColumnValues *other_columns,
				  const gchar *name,
				  gchar *value)
{
	GHashTable *hash_table = (GHashTable *) other_columns;

	g_return_if_fail (other_columns != NULL);
	g_return_if_fail (name != NULL);

	g_hash_table_insert (hash_table, g_strdup (name), value);
}

/**
 * e_cache_column_values_take:
 * @other_columns: an #ECacheColumnValues
 * @name: (in) (transfer full): a column name
 * @value: (nullable) (in) (transfer full): a column value
 *
 * Puts the @value for column @name. If contains a value for the same
 * column, then it is replaced. This creates takes ownership of both
 * the @name and the @value.
 *
 * Since: 3.26
 **/
void
e_cache_column_values_take (ECacheColumnValues *other_columns,
			    gchar *name,
			    gchar *value)
{
	GHashTable *hash_table = (GHashTable *) other_columns;

	g_return_if_fail (other_columns != NULL);
	g_return_if_fail (name != NULL);

	g_hash_table_insert (hash_table, name, value);
}

/**
 * e_cache_column_values_contains:
 * @other_columns: an #ECacheColumnValues
 * @name: a column name
 *
 * Returns: Whether @other_columns contains column named @name.
 *
 * Since: 3.26
 **/
gboolean
e_cache_column_values_contains (ECacheColumnValues *other_columns,
				const gchar *name)
{
	GHashTable *hash_table = (GHashTable *) other_columns;

	g_return_val_if_fail (other_columns != NULL, FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	return g_hash_table_contains (hash_table, name);
}

/**
 * e_cache_column_values_remove:
 * @other_columns: an #ECacheColumnValues
 * @name: a column name
 *
 * Removes value for the column named @name from @other_columns.
 *
 * Returns: Whether such column existed and had been removed.
 *
 * Since: 3.26
 **/
gboolean
e_cache_column_values_remove (ECacheColumnValues *other_columns,
			      const gchar *name)
{
	GHashTable *hash_table = (GHashTable *) other_columns;

	g_return_val_if_fail (other_columns != NULL, FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	return g_hash_table_remove (hash_table, name);
}

/**
 * e_cache_column_values_remove_all:
 * @other_columns: an #ECacheColumnValues
 *
 * Removes all values from the @other_columns, leaving it empty.
 *
 * Since: 3.26
 **/
void
e_cache_column_values_remove_all (ECacheColumnValues *other_columns)
{
	GHashTable *hash_table = (GHashTable *) other_columns;

	g_return_if_fail (other_columns != NULL);

	g_hash_table_remove_all (hash_table);
}

/**
 * e_cache_column_values_lookup:
 * @other_columns: an #ECacheColumnValues
 * @name: a column name
 *
 * Looks up currently stored value for the column named @name.
 * As the values can be %NULL one cannot distinguish between
 * a column which doesn't have stored any value and a column
 * which has stored %NULL value. Use e_cache_column_values_contains()
 * to check whether such column exitst in the @other_columns.
 * The returned pointer is owned by @other_columns and is valid until
 * the value is overwritten of the @other_columns freed.
 *
 * Returns: Stored value for the column named @name, or %NULL, if
 *    no such column values is stored.
 *
 * Since: 3.26
 **/
const gchar *
e_cache_column_values_lookup (ECacheColumnValues *other_columns,
			      const gchar *name)
{
	GHashTable *hash_table = (GHashTable *) other_columns;

	g_return_val_if_fail (other_columns != NULL, NULL);
	g_return_val_if_fail (name != NULL, NULL);

	return g_hash_table_lookup (hash_table, name);
}

/**
 * e_cache_column_values_get_size:
 * @other_columns: an #ECacheColumnValues
 *
 * Returns: How many columns are stored in the @other_columns.
 *
 * Since: 3.26
 **/
guint
e_cache_column_values_get_size (ECacheColumnValues *other_columns)
{
	GHashTable *hash_table = (GHashTable *) other_columns;

	g_return_val_if_fail (other_columns != NULL, 0);

	return g_hash_table_size (hash_table);
}

/**
 * e_cache_column_values_init_iter:
 * @other_columns: an #ECacheColumnValues
 * @iter: a #GHashTableIter
 *
 * Initialized the @iter, thus the @other_columns can be traversed
 * with g_hash_table_iter_next(). The key is a column name and
 * the value is the corresponding column value.
 *
 * Since: 3.26
 **/
void
e_cache_column_values_init_iter (ECacheColumnValues *other_columns,
				 GHashTableIter *iter)
{
	GHashTable *hash_table = (GHashTable *) other_columns;

	g_return_if_fail (other_columns != NULL);
	g_return_if_fail (iter != NULL);

	g_hash_table_iter_init (iter, hash_table);
}

/**
 * e_cache_offline_change_new:
 * @uid: a unique object identifier
 * @revision: (nullable): a revision of the object
 * @object: (nullable): object itself
 * @state: an #EOfflineState
 *
 * Creates a new #ECacheOfflineChange with the offline @state
 * information for the given @uid.
 *
 * Returns: (transfer full): A new #ECacheOfflineChange. Free it with
 *    e_cache_offline_change_free() when no longer needed.
 *
 * Since: 3.26
 **/
ECacheOfflineChange *
e_cache_offline_change_new (const gchar *uid,
			    const gchar *revision,
			    const gchar *object,
			    EOfflineState state)
{
	ECacheOfflineChange *change;

	g_return_val_if_fail (uid != NULL, NULL);

	change = g_new0 (ECacheOfflineChange, 1);
	change->uid = g_strdup (uid);
	change->revision = g_strdup (revision);
	change->object = g_strdup (object);
	change->state = state;

	return change;
}

/**
 * e_cache_offline_change_copy:
 * @change: (nullable): a source #ECacheOfflineChange to copy, or %NULL
 *
 * Returns: (transfer full): Copy of the given @change. Free it with
 *    e_cache_offline_change_free() when no longer needed.
 *    If the @change is %NULL, then returns %NULL as well.
 *
 * Since: 3.26
 **/
ECacheOfflineChange *
e_cache_offline_change_copy (const ECacheOfflineChange *change)
{
	if (!change)
		return NULL;

	return e_cache_offline_change_new (change->uid, change->revision, change->object, change->state);
}

/**
 * e_cache_offline_change_free:
 * @change: (nullable): an #ECacheOfflineChange
 *
 * Frees the @change structure, previously allocated with e_cache_offline_change_new()
 * or e_cache_offline_change_copy().
 *
 * Since: 3.26
 **/
void
e_cache_offline_change_free (gpointer change)
{
	ECacheOfflineChange *chng = change;

	if (chng) {
		g_free (chng->uid);
		g_free (chng->revision);
		g_free (chng->object);
		g_free (chng);
	}
}

/**
 * e_cache_column_info_new:
 * @name: a column name
 * @type: a column type
 * @index_name: (nullable): an index name for this column, or %NULL
 *
 * Returns: (transfer full): A new #ECacheColumnInfo. Free it with
 *    e_cache_column_info_free() when no longer needed.
 *
 * Since: 3.26
 **/
ECacheColumnInfo *
e_cache_column_info_new (const gchar *name,
			 const gchar *type,
			 const gchar *index_name)
{
	ECacheColumnInfo *info;

	g_return_val_if_fail (name != NULL, NULL);
	g_return_val_if_fail (type != NULL, NULL);

	info = g_new0 (ECacheColumnInfo, 1);
	info->name = g_strdup (name);
	info->type = g_strdup (type);
	info->index_name = g_strdup (index_name);

	return info;
}

/**
 * e_cache_column_info_copy:
 * @info: (nullable): a source #ECacheColumnInfo to copy, or %NULL
 *
 * Returns: (transfer full): Copy of the given @info. Free it with
 *    e_cache_column_info_free() when no longer needed.
 *    If the @info is %NULL, then returns %NULL as well.
 *
 * Since: 3.26
 **/
ECacheColumnInfo *
e_cache_column_info_copy (const ECacheColumnInfo *info)
{
	if (!info)
		return NULL;

	return e_cache_column_info_new (info->name, info->type, info->index_name);
}

/**
 * e_cache_column_info_free:
 * @info: (nullable): an #ECacheColumnInfo
 *
 * Frees the @info structure, previously allocated with e_cache_column_info_new()
 * or e_cache_column_info_copy().
 *
 * Since: 3.26
 **/
void
e_cache_column_info_free (gpointer info)
{
	ECacheColumnInfo *nfo = info;

	if (nfo) {
		g_free (nfo->name);
		g_free (nfo->type);
		g_free (nfo->index_name);
		g_free (nfo);
	}
}

#define E_CACHE_SET_ERROR_FROM_SQLITE(error, code, message, stmt) \
	G_STMT_START { \
		if (code == SQLITE_CONSTRAINT) { \
			g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_CONSTRAINT, message); \
		} else if (code == SQLITE_ABORT || code == SQLITE_INTERRUPT) { \
			g_set_error (error, G_IO_ERROR, G_IO_ERROR_CANCELLED, "Operation cancelled: %s", message); \
		} else { \
			gchar *valid_utf8 = e_util_utf8_make_valid (stmt); \
			g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_ENGINE, \
				"SQLite error code '%d': %s (statement:%s)", code, message, valid_utf8 ? valid_utf8 : stmt); \
			g_free (valid_utf8); \
		} \
	} G_STMT_END

struct CacheSQLiteExecData {
	ECache *cache;
	ECacheSelectFunc callback;
	gpointer user_data;
};

static gint
e_cache_sqlite_exec_cb (gpointer user_data,
			gint ncols,
			gchar **column_values,
			gchar **column_names)
{
	struct CacheSQLiteExecData *cse = user_data;

	g_return_val_if_fail (cse != NULL, SQLITE_MISUSE);
	g_return_val_if_fail (cse->callback != NULL, SQLITE_MISUSE);

	if (!cse->callback (cse->cache, ncols, (const gchar **) column_names, (const gchar **) column_values, cse->user_data))
		return SQLITE_ABORT;

	return SQLITE_OK;
}

static gboolean
e_cache_sqlite_exec_internal (ECache *cache,
			      const gchar *stmt,
			      ECacheSelectFunc callback,
			      gpointer user_data,
			      GCancellable *cancellable,
			      GError **error)
{
	struct CacheSQLiteExecData cse;
	GCancellable *previous_cancellable;
	gchar *errmsg = NULL;
	gint ret = -1, retries = 0;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (stmt != NULL, FALSE);

	g_rec_mutex_lock (&cache->priv->lock);

	previous_cancellable = cache->priv->cancellable;
	if (cancellable)
		cache->priv->cancellable = cancellable;

	cse.cache = cache;
	cse.callback = callback;
	cse.user_data = user_data;

	ret = sqlite3_exec (cache->priv->db, stmt, callback ? e_cache_sqlite_exec_cb : NULL, &cse, &errmsg);

	while (ret == SQLITE_BUSY || ret == SQLITE_LOCKED || ret == -1) {
		/* try for ~15 seconds, then give up */
		if (retries > 150)
			break;
		retries++;

		if (errmsg) {
			sqlite3_free (errmsg);
			errmsg = NULL;
		}
		g_thread_yield ();
		g_usleep (100 * 1000); /* Sleep for 100 ms */

		ret = sqlite3_exec (cache->priv->db, stmt, callback ? e_cache_sqlite_exec_cb : NULL, &cse, &errmsg);
	}

	cache->priv->cancellable = previous_cancellable;

	g_rec_mutex_unlock (&cache->priv->lock);

	if (ret != SQLITE_OK) {
		E_CACHE_SET_ERROR_FROM_SQLITE (error, ret, errmsg, stmt);
		sqlite3_free (errmsg);
		return FALSE;
	}

	if (errmsg)
		sqlite3_free (errmsg);

	return TRUE;
}

static gboolean
e_cache_sqlite_exec_printf (ECache *cache,
			    const gchar *format,
			    ECacheSelectFunc callback,
			    gpointer user_data,
			    GCancellable *cancellable,
			    GError **error,
			    ...)
{
	gboolean success;
	va_list args;
	gchar *stmt;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (format != NULL, FALSE);

	va_start (args, error);
	stmt = sqlite3_vmprintf (format, args);

	success = e_cache_sqlite_exec_internal (cache, stmt, callback, user_data, cancellable, error);

	sqlite3_free (stmt);
	va_end (args);

	return success;
}

static gboolean
e_cache_read_key_value (ECache *cache,
			gint ncols,
			const gchar **column_names,
			const gchar **column_values,
			gpointer user_data)
{
	gchar **pvalue = user_data;

	g_return_val_if_fail (ncols == 1, FALSE);
	g_return_val_if_fail (column_names != NULL, FALSE);
	g_return_val_if_fail (column_values != NULL, FALSE);
	g_return_val_if_fail (pvalue != NULL, FALSE);

	if (!*pvalue)
		*pvalue = g_strdup (column_values[0]);

	return TRUE;
}

static gchar *
e_cache_build_user_key (const gchar *key)
{
	return g_strconcat ("user::", key, NULL);
}

static gboolean
e_cache_set_key_internal (ECache *cache,
			  gboolean is_user_key,
			  const gchar *key,
			  const gchar *value,
			  GError **error)
{
	gchar *tmp = NULL;
	const gchar *usekey;
	gboolean success;

	if (is_user_key) {
		tmp = e_cache_build_user_key (key);
		usekey = tmp;
	} else {
		usekey = key;
	}

	if (value) {
		success = e_cache_sqlite_exec_printf (cache,
			"INSERT or REPLACE INTO " E_CACHE_TABLE_KEYS " (key, value) VALUES (%Q, %Q)",
			NULL, NULL, NULL, error,
			usekey, value);
	} else {
		success = e_cache_sqlite_exec_printf (cache,
			"DELETE FROM " E_CACHE_TABLE_KEYS " WHERE key = %Q",
			NULL, NULL, NULL, error,
			usekey);
	}

	g_free (tmp);

	return success;
}

static gchar *
e_cache_dup_key_internal (ECache *cache,
			  gboolean is_user_key,
			  const gchar *key,
			  GError **error)
{
	gchar *tmp = NULL;
	const gchar *usekey;
	gchar *value = NULL;

	if (is_user_key) {
		tmp = e_cache_build_user_key (key);
		usekey = tmp;
	} else {
		usekey = key;
	}

	if (!e_cache_sqlite_exec_printf (cache,
		"SELECT value FROM " E_CACHE_TABLE_KEYS " WHERE key = %Q",
		e_cache_read_key_value, &value, NULL, error,
		usekey)) {
		g_warn_if_fail (value == NULL);
	}

	g_free (tmp);

	return value;
}

static gint
e_cache_check_cancelled_cb (gpointer user_data)
{
	ECache *cache = user_data;

	/* Do not use E_IS_CACHE() here, for performance reasons */
	g_return_val_if_fail (cache != NULL, SQLITE_ABORT);

	if (cache->priv->cancellable &&
	    g_cancellable_is_cancelled (cache->priv->cancellable)) {
		return SQLITE_ABORT;
	}

	return SQLITE_OK;
}

static gboolean
e_cache_init_sqlite (ECache *cache,
		     const gchar *filename,
		     GCancellable *cancellable,
		     GError **error)
{
	gint ret;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (filename != NULL, FALSE);
	g_return_val_if_fail (cache->priv->filename == NULL, FALSE);

	cache->priv->filename = g_strdup (filename);

	ret = sqlite3_open (filename, &cache->priv->db);
	if (ret != SQLITE_OK) {
		if (!cache->priv->db) {
			g_set_error_literal (error, E_CACHE_ERROR, E_CACHE_ERROR_LOAD, _("Out of memory"));
		} else {
			const gchar *errmsg = sqlite3_errmsg (cache->priv->db);

			g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_ENGINE,
				_("Can’t open database %s: %s"), filename, errmsg);

			sqlite3_close (cache->priv->db);
			cache->priv->db = NULL;
		}

		return FALSE;
	}

	/* Handle GCancellable */
	sqlite3_progress_handler (
		cache->priv->db,
		E_CACHE_CANCEL_BATCH_SIZE,
		e_cache_check_cancelled_cb,
		cache);

	return e_cache_sqlite_exec_internal (cache, "ATTACH DATABASE ':memory:' AS mem", NULL, NULL, cancellable, error) &&
		e_cache_sqlite_exec_internal (cache, "PRAGMA foreign_keys = ON",          NULL, NULL, cancellable, error) &&
		e_cache_sqlite_exec_internal (cache, "PRAGMA case_sensitive_like = ON",   NULL, NULL, cancellable, error);
}

static gboolean
e_cache_garther_column_names_cb (ECache *cache,
				 gint ncols,
				 const gchar *column_names[],
				 const gchar *column_values[],
				 gpointer user_data)
{
	GHashTable *known_columns = user_data;
	gint ii;

	g_return_val_if_fail (known_columns != NULL, FALSE);
	g_return_val_if_fail (column_names != NULL, FALSE);
	g_return_val_if_fail (column_values != NULL, FALSE);

	for (ii = 0; ii < ncols; ii++) {
		if (column_names[ii] && camel_strcase_equal (column_names[ii], "name")) {
			if (column_values[ii])
				g_hash_table_insert (known_columns, g_strdup (column_values[ii]), NULL);
			break;
		}
	}

	return TRUE;
}

static gboolean
e_cache_init_tables (ECache *cache,
		     const GSList *other_columns,
		     GCancellable *cancellable,
		     GError **error)
{
	GHashTable *known_columns;
	GString *objects_stmt;
	const GSList *link;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (cache->priv->db != NULL, FALSE);

	if (!e_cache_sqlite_exec_internal (cache,
		"CREATE TABLE IF NOT EXISTS " E_CACHE_TABLE_KEYS " ("
		"key TEXT PRIMARY KEY,"
		"value TEXT)",
		NULL, NULL, cancellable, error)) {
		return FALSE;
	}

	objects_stmt = g_string_new ("");

	g_string_append (objects_stmt, "CREATE TABLE IF NOT EXISTS " E_CACHE_TABLE_OBJECTS " ("
		E_CACHE_COLUMN_UID " TEXT PRIMARY KEY,"
		E_CACHE_COLUMN_REVISION " TEXT,"
		E_CACHE_COLUMN_OBJECT " TEXT,"
		E_CACHE_COLUMN_STATE " INTEGER");

	for (link = other_columns; link; link = g_slist_next (link)) {
		const ECacheColumnInfo *info = link->data;

		if (!info)
			continue;

		g_string_append (objects_stmt, ",");
		g_string_append (objects_stmt, info->name);
		g_string_append (objects_stmt, " ");
		g_string_append (objects_stmt, info->type);
	}

	g_string_append (objects_stmt, ")");

	if (!e_cache_sqlite_exec_internal (cache, objects_stmt->str, NULL, NULL, cancellable, error)) {
		g_string_free (objects_stmt, TRUE);

		return FALSE;
	}

	g_string_free (objects_stmt, TRUE);

	/* Verify that all other columns are there and remove those unused */
	known_columns = g_hash_table_new_full (camel_strcase_hash, camel_strcase_equal, g_free, NULL);

	if (!e_cache_sqlite_exec_internal (cache, "PRAGMA table_info (" E_CACHE_TABLE_OBJECTS ")",
		e_cache_garther_column_names_cb, known_columns, cancellable, error)) {
		g_string_free (objects_stmt, TRUE);

		return FALSE;
	}

	g_hash_table_remove (known_columns, E_CACHE_COLUMN_UID);
	g_hash_table_remove (known_columns, E_CACHE_COLUMN_REVISION);
	g_hash_table_remove (known_columns, E_CACHE_COLUMN_OBJECT);
	g_hash_table_remove (known_columns, E_CACHE_COLUMN_STATE);

	for (link = other_columns; link; link = g_slist_next (link)) {
		const ECacheColumnInfo *info = link->data;

		if (!info)
			continue;

		if (g_hash_table_remove (known_columns, info->name))
			continue;

		if (!e_cache_sqlite_exec_printf (cache,
			"ALTER TABLE " E_CACHE_TABLE_OBJECTS " ADD COLUMN %Q %s",
			NULL, NULL, cancellable, error,
			info->name, info->type)) {
			g_hash_table_destroy (known_columns);

			return FALSE;
		}
	}

	g_hash_table_destroy (known_columns);

	for (link = other_columns; link; link = g_slist_next (link)) {
		const ECacheColumnInfo *info = link->data;

		if (!info || !info->index_name)
			continue;

		if (!e_cache_sqlite_exec_printf (cache,
			"CREATE INDEX IF NOT EXISTS %Q ON " E_CACHE_TABLE_OBJECTS " (%s)",
			NULL, NULL, cancellable, error,
			info->index_name, info->name)) {
			return FALSE;
		}
	}

	return TRUE;
}

/**
 * e_cache_initialize_sync:
 * @cache: an #ECache
 * @filename: a filename of an SQLite database to use
 * @other_columns: (element-type ECacheColumnInfo) (nullable): an optional
 *    #GSList with additional columns to add to the objects table
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Initializes the @cache and opens the @filename database.
 * This should be called by the descendant.
 *
 * The @other_columns are added to the objects table (@E_CACHE_TABLE_OBJECTS).
 * Values for these columns are returned by e_cache_get()
 * and can be stored with e_cache_put().
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_initialize_sync (ECache *cache,
			 const gchar *filename,
			 const GSList *other_columns,
			 GCancellable *cancellable,
			 GError **error)
{
	gchar *dirname;
	gboolean success;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (cache->priv->filename == NULL, FALSE);

	/* Ensure existance of the directories leading up to 'filename' */
	dirname = g_path_get_dirname (filename);
	if (g_mkdir_with_parents (dirname, 0777) < 0) {
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_LOAD,
			_("Can not make parent directory: %s"),
			g_strerror (errno));
		g_free (dirname);

		return FALSE;
	}

	g_free (dirname);

	g_rec_mutex_lock (&cache->priv->lock);

	success = e_cache_init_sqlite (cache, filename, cancellable, error) &&
		e_cache_init_tables (cache, other_columns, cancellable, error);

	g_rec_mutex_unlock (&cache->priv->lock);

	return success;
}

/**
 * e_cache_get_filename:
 * @cache: an #ECache
 *
 * Returns: a filename of the @cache, with which it had been initialized.
 *
 * Since: 3.26
 **/
const gchar *
e_cache_get_filename (ECache *cache)
{
	g_return_val_if_fail (E_IS_CACHE (cache), NULL);

	return cache->priv->filename;
}

/**
 * e_cache_get_version:
 * @cache: an #ECache
 *
 * Returns: A cache data version. This is meant to be used by the descendants.
 *
 * Since: 3.26
 **/
gint
e_cache_get_version (ECache *cache)
{
	gchar *value;
	gint version = -1;

	g_return_val_if_fail (E_IS_CACHE (cache), -1);

	value = e_cache_dup_key_internal (cache, FALSE, E_CACHE_KEY_VERSION, NULL);

	if (value) {
		version = g_ascii_strtoll (value, NULL, 10);
		g_free (value);
	}

	return version;
}

/**
 * e_cache_set_version:
 * @cache: an #ECache
 * @version: a cache data version to set
 *
 * Sets a cache data version. This is meant to be used by the descendants.
 * The @version should be greater than zero.
 *
 * Since: 3.26
 **/
void
e_cache_set_version (ECache *cache,
		     gint version)
{
	gchar *value;

	g_return_if_fail (E_IS_CACHE (cache));
	g_return_if_fail (version > 0);

	value = g_strdup_printf ("%d", version);
	e_cache_set_key_internal (cache, FALSE, E_CACHE_KEY_VERSION, value, NULL);
	g_free (value);
}

/**
 * e_cache_dup_revision:
 * @cache: an #ECache
 *
 * Returns: (transfer full): A revision of the whole @cache. This is meant to be
 *    used by the descendants. Free the returned pointer with g_free(), when no
 *    longer needed.
 *
 * Since: 3.26
 **/
gchar *
e_cache_dup_revision (ECache *cache)
{
	g_return_val_if_fail (E_IS_CACHE (cache), NULL);

	return e_cache_dup_key_internal (cache, FALSE, E_CACHE_KEY_REVISION, NULL);
}

/**
 * e_cache_set_revision:
 * @cache: an #ECache
 * @revision: (nullable): a revision to set; use %NULL to unset it
 *
 * Sets the @revision of the whole @cache. This is not meant to be
 * used by the descendants, because the revision is updated automatically
 * when needed. The descendants can listen to "revision-changed" signal.
 *
 * Since: 3.26
 **/
void
e_cache_set_revision (ECache *cache,
		      const gchar *revision)
{
	g_return_if_fail (E_IS_CACHE (cache));

	e_cache_set_key_internal (cache, FALSE, E_CACHE_KEY_REVISION, revision, NULL);

	g_signal_emit (cache, signals[REVISION_CHANGED], 0, NULL);
}

/**
 * e_cache_change_revision:
 * @cache: an #ECache
 *
 * Instructs the @cache to change its revision. In case the revision
 * change is frozen with e_cache_freeze_revision_change() it notes to
 * change the revision once the revision change is fully thaw.
 *
 * Since: 3.26
 **/
void
e_cache_change_revision (ECache *cache)
{
	g_return_if_fail (E_IS_CACHE (cache));

	g_rec_mutex_lock (&cache->priv->lock);

	if (e_cache_is_revision_change_frozen (cache)) {
		cache->priv->needs_revision_change = TRUE;
	} else {
		gchar time_string[100] = { 0 };
		const struct tm *tm = NULL;
		time_t t;
		gint64 revision_time;
		gchar *revision;

		revision_time = g_get_real_time () / (1000 * 1000);
		t = (time_t) revision_time;

		if (revision_time != cache->priv->last_revision_time) {
			cache->priv->revision_counter = 0;
			cache->priv->last_revision_time = revision_time;
		}

		tm = gmtime (&t);
		if (tm)
			strftime (time_string, 100, "%Y-%m-%dT%H:%M:%SZ", tm);

		revision = g_strdup_printf ("%s(%d)", time_string, cache->priv->revision_counter++);

		e_cache_set_revision (cache, revision);

		g_free (revision);
	}

	g_rec_mutex_unlock (&cache->priv->lock);
}

/**
 * e_cache_freeze_revision_change:
 * @cache: an #ECache
 *
 * Freezes automatic revision change for the @cache. The function
 * can be called multiple times, but each such call requires its
 * pair function e_cache_thaw_revision_change() call. See also
 * e_cache_change_revision().
 *
 * Since: 3.26
 **/
void
e_cache_freeze_revision_change (ECache *cache)
{
	g_return_if_fail (E_IS_CACHE (cache));

	g_rec_mutex_lock (&cache->priv->lock);

	cache->priv->revision_change_frozen++;
	g_warn_if_fail (cache->priv->revision_change_frozen != 0);

	g_rec_mutex_unlock (&cache->priv->lock);
}

/**
 * e_cache_thaw_revision_change:
 * @cache: an #ECache
 *
 * Thaws automatic revision change for the @cache. It's the pair
 * function of e_cache_freeze_revision_change().
 *
 * Since: 3.26
 **/
void
e_cache_thaw_revision_change (ECache *cache)
{
	g_return_if_fail (E_IS_CACHE (cache));

	g_rec_mutex_lock (&cache->priv->lock);

	if (!cache->priv->revision_change_frozen) {
		g_warn_if_fail (cache->priv->revision_change_frozen > 0);
	} else {
		cache->priv->revision_change_frozen--;
		if (!cache->priv->revision_change_frozen &&
		    cache->priv->needs_revision_change) {
			cache->priv->needs_revision_change = FALSE;
			e_cache_change_revision (cache);
		}
	}

	g_rec_mutex_unlock (&cache->priv->lock);
}

/**
 * e_cache_is_revision_change_frozen:
 * @cache: an #ECache
 *
 * Returns: Whether automatic revision change for the @cache
 *    is currently frozen.
 *
 * Since: 3.26
 **/
gboolean
e_cache_is_revision_change_frozen (ECache *cache)
{
	gboolean frozen;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);

	g_rec_mutex_lock (&cache->priv->lock);
	frozen = cache->priv->revision_change_frozen > 0;
	g_rec_mutex_unlock (&cache->priv->lock);

	return frozen;
}

/**
 * e_cache_erase:
 * @cache: an #ECache
 *
 * Erases the cache and all of its content from the disk.
 * The only valid operation after this is to free the @cache.
 *
 * Since: 3.26
 **/
void
e_cache_erase (ECache *cache)
{
	ECacheClass *klass;

	g_return_if_fail (E_IS_CACHE (cache));

	if (!cache->priv->db)
		return;

	klass = E_CACHE_GET_CLASS (cache);
	g_return_if_fail (klass != NULL);

	if (klass->erase)
		klass->erase (cache);

	sqlite3_close (cache->priv->db);
	cache->priv->db = NULL;

	g_unlink (cache->priv->filename);

	g_free (cache->priv->filename);
	cache->priv->filename = NULL;
}

static gboolean
e_cache_count_rows_cb (ECache *cache,
		       gint ncols,
		       const gchar **column_names,
		       const gchar **column_values,
		       gpointer user_data)
{
	guint *pnrows = user_data;

	g_return_val_if_fail (pnrows != NULL, FALSE);

	*pnrows = (*pnrows) + 1;

	return TRUE;
}

/**
 * e_cache_contains:
 * @cache: an #ECache
 * @uid: a unique identifier of an object
 * @deleted_flag: one of #ECacheDeletedFlag enum
 *
 * Checkes whether the @cache contains an object with
 * the given @uid.
 *
 * Returns: Whether the the object had been found.
 *
 * Since: 3.26
 **/
gboolean
e_cache_contains (ECache *cache,
		  const gchar *uid,
		  ECacheDeletedFlag deleted_flag)
{
	guint nrows = 0;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	if (deleted_flag == E_CACHE_INCLUDE_DELETED) {
		e_cache_sqlite_exec_printf (cache,
			"SELECT " E_CACHE_COLUMN_UID " FROM " E_CACHE_TABLE_OBJECTS
			" WHERE " E_CACHE_COLUMN_UID " = %Q"
			" LIMIT 2",
			e_cache_count_rows_cb, &nrows, NULL, NULL,
			uid);
	} else {
		e_cache_sqlite_exec_printf (cache,
			"SELECT " E_CACHE_COLUMN_UID " FROM " E_CACHE_TABLE_OBJECTS
			" WHERE " E_CACHE_COLUMN_UID " = %Q AND " E_CACHE_COLUMN_STATE " != %d"
			" LIMIT 2",
			e_cache_count_rows_cb, &nrows, NULL, NULL,
			uid, E_OFFLINE_STATE_LOCALLY_DELETED);
	}

	g_warn_if_fail (nrows <= 1);

	return nrows > 0;
}

struct GetObjectData {
	gchar *object;
	gchar **out_revision;
	ECacheColumnValues **out_other_columns;
};

static gboolean
e_cache_get_object_cb (ECache *cache,
		       gint ncols,
		       const gchar **column_names,
		       const gchar **column_values,
		       gpointer user_data)
{
	struct GetObjectData *gd = user_data;
	gint ii;

	g_return_val_if_fail (gd != NULL, FALSE);
	g_return_val_if_fail (column_names != NULL, FALSE);
	g_return_val_if_fail (column_values != NULL, FALSE);

	for (ii = 0; ii < ncols; ii++) {
		if (g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_UID) == 0 ||
		    g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_STATE) == 0) {
			/* Skip these two */
		} else if (g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_REVISION) == 0) {
			if (gd->out_revision)
				*gd->out_revision = g_strdup (column_values[ii]);
		} else if (g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_OBJECT) == 0) {
			gd->object = g_strdup (column_values[ii]);
		} else if (gd->out_other_columns) {
			if (!*gd->out_other_columns)
				*gd->out_other_columns = e_cache_column_values_new ();

			e_cache_column_values_put (*gd->out_other_columns, column_names[ii], column_values[ii]);
		} else if (gd->object && (!gd->out_revision || *gd->out_revision)) {
			/* Short-break the cycle when the other columns are not requested and
			   the object/revision values were already read. */
			break;
		}
	}

	return TRUE;
}

static gchar *
e_cache_get_object_internal (ECache *cache,
			     gboolean include_deleted,
			     const gchar *uid,
			     gchar **out_revision,
			     ECacheColumnValues **out_other_columns,
			     GCancellable *cancellable,
			     GError **error)
{
	struct GetObjectData gd;
	gboolean success;

	g_return_val_if_fail (E_IS_CACHE (cache), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	if (out_revision)
		*out_revision = NULL;

	if (out_other_columns)
		*out_other_columns = NULL;

	gd.object = NULL;
	gd.out_revision = out_revision;
	gd.out_other_columns = out_other_columns;

	if (include_deleted) {
		success = e_cache_sqlite_exec_printf (cache,
			"SELECT * FROM " E_CACHE_TABLE_OBJECTS
			" WHERE " E_CACHE_COLUMN_UID " = %Q",
			e_cache_get_object_cb, &gd, cancellable, error,
			uid);
	} else {
		success = e_cache_sqlite_exec_printf (cache,
			"SELECT * FROM " E_CACHE_TABLE_OBJECTS
			" WHERE " E_CACHE_COLUMN_UID " = %Q AND " E_CACHE_COLUMN_STATE " != %d",
			e_cache_get_object_cb, &gd, cancellable, error,
			uid, E_OFFLINE_STATE_LOCALLY_DELETED);
	}

	if (success && !gd.object)
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object “%s” not found"), uid);

	return gd.object;
}

/**
 * e_cache_get:
 * @cache: an #ECache
 * @uid: a unique identifier of an object
 * @out_revision: (out) (nullable) (transfer full): an out variable for a revision
 *    of the object, or %NULL to ignore
 * @out_other_columns: (out) (nullable) (transfer full): an out
 *    variable for #ECacheColumnValues other columns, as defined when creating the @cache, or %NULL to ignore
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Returns an object with the given @uid. This function does not consider locally
 * deleted objects. The @out_revision is set to the object revision, if not %NULL.
 * Free it with g_free() when no longer needed. Similarly the @out_other_columns
 * contains a column name to column value strings for additional columns which had
 * been requested when calling e_cache_initialize_sync(), if not %NULL.
 * Free the returned #ECacheColumnValues with e_cache_column_values_free(), when
 * no longer needed.
 *
 * Returns: (nullable) (transfer full): An object with the given @uid. Free it
 *    with g_free(), when no longer needed. Returns %NULL on error, like when
 *    the object could not be found.
 *
 * Since: 3.26
 **/
gchar *
e_cache_get (ECache *cache,
	     const gchar *uid,
	     gchar **out_revision,
	     ECacheColumnValues **out_other_columns,
	     GCancellable *cancellable,
	     GError **error)
{
	g_return_val_if_fail (E_IS_CACHE (cache), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	return e_cache_get_object_internal (cache, FALSE, uid, out_revision, out_other_columns, cancellable, error);
}

/**
 * e_cache_get_object_include_deleted:
 * @cache: an #ECache
 * @uid: a unique identifier of an object
 * @out_revision: (out) (nullable) (transfer full): an out variable for a revision
 *    of the object, or %NULL to ignore
 * @out_other_columns: (out) (nullable) (transfer full): an out
 *    variable for #ECacheColumnValues other columns, as defined when creating the @cache, or %NULL to ignore
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * The same as e_cache_get(), only considers also locally deleted objects.
 *
 * Returns: (nullable) (transfer full): An object with the given @uid. Free it
 *    with g_free(), when no longer needed. Returns %NULL on error, like when
 *    the object could not be found.
 *
 * Since: 3.30
 **/
gchar *
e_cache_get_object_include_deleted (ECache *cache,
				    const gchar *uid,
				    gchar **out_revision,
				    ECacheColumnValues **out_other_columns,
				    GCancellable *cancellable,
				    GError **error)
{
	g_return_val_if_fail (E_IS_CACHE (cache), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	return e_cache_get_object_internal (cache, TRUE, uid, out_revision, out_other_columns, cancellable, error);
}

static gboolean
e_cache_put_locked (ECache *cache,
		    const gchar *uid,
		    const gchar *revision,
		    const gchar *object,
		    ECacheColumnValues *other_columns,
		    EOfflineState offline_state,
		    gboolean is_replace,
		    GCancellable *cancellable,
		    GError **error)
{
	ECacheColumnValues *my_other_columns = NULL;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (object != NULL, FALSE);

	if (!other_columns) {
		my_other_columns = e_cache_column_values_new ();
		other_columns = my_other_columns;
	}

	g_signal_emit (cache,
		       signals[BEFORE_PUT],
		       0,
		       uid, revision, object, other_columns,
		       is_replace, cancellable, error,
		       &success);

	if (success) {
		ECacheClass *klass;

		klass = E_CACHE_GET_CLASS (cache);
		g_return_val_if_fail (klass != NULL, FALSE);
		g_return_val_if_fail (klass->put_locked != NULL, FALSE);

		success = klass->put_locked (cache, uid, revision, object, other_columns, offline_state, is_replace, cancellable, error);

		if (success)
			e_cache_change_revision (cache);
	}

	e_cache_column_values_free (my_other_columns);

	return success;
}

/**
 * e_cache_put:
 * @cache: an #ECache
 * @uid: a unique identifier of an object
 * @revision: (nullable): a revision of the object
 * @object: the object itself
 * @other_columns: (nullable): an #ECacheColumnValues with other columns to set; can be %NULL
 * @offline_flag: one of #ECacheOfflineFlag, whether putting this object in offline
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Stores an object into the cache. Depending on @offline_flag, this update
 * the object's offline state accordingly. When the @offline_flag is set
 * to %E_CACHE_IS_ONLINE, then it's set to #E_OFFLINE_STATE_SYNCED, like
 * to be fully synchronized with the server, regardless of its previous
 * offline state. Overwriting locally deleted object behaves like an addition
 * of a completely new object.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_put (ECache *cache,
	     const gchar *uid,
	     const gchar *revision,
	     const gchar *object,
	     ECacheColumnValues *other_columns,
	     ECacheOfflineFlag offline_flag,
	     GCancellable *cancellable,
	     GError **error)
{
	EOfflineState offline_state;
	gboolean success = TRUE, is_replace;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (object != NULL, FALSE);

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);

	if (offline_flag == E_CACHE_IS_ONLINE) {
		is_replace = e_cache_contains (cache, uid, E_CACHE_EXCLUDE_DELETED);
		offline_state = E_OFFLINE_STATE_SYNCED;
	} else {
		is_replace = e_cache_contains (cache, uid, E_CACHE_INCLUDE_DELETED);
		if (is_replace) {
			GError *local_error = NULL;

			offline_state = e_cache_get_offline_state (cache, uid, cancellable, &local_error);

			if (local_error) {
				success = FALSE;
				g_propagate_error (error, local_error);
			} else if (offline_state != E_OFFLINE_STATE_LOCALLY_CREATED) {
				offline_state = E_OFFLINE_STATE_LOCALLY_MODIFIED;
			}
		} else {
			offline_state = E_OFFLINE_STATE_LOCALLY_CREATED;
		}
	}

	success = success && e_cache_put_locked (cache, uid, revision, object, other_columns,
		offline_state, is_replace, cancellable, error);

	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	return success;
}

/**
 * e_cache_remove:
 * @cache: an #ECache
 * @uid: a unique identifier of an object
 * @offline_flag: one of #ECacheOfflineFlag, whether removing the object in offline
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Removes the object with the given @uid from the @cache. Based on the @offline_flag,
 * it can remove also any information about locally made offline changes. Removing
 * the object with %E_CACHE_IS_OFFLINE will still remember it for later use
 * with e_cache_get_offline_changes().
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_remove (ECache *cache,
		const gchar *uid,
		ECacheOfflineFlag offline_flag,
		GCancellable *cancellable,
		GError **error)
{
	ECacheClass *klass;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	klass = E_CACHE_GET_CLASS (cache);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->remove_locked != NULL, FALSE);

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);

	if (offline_flag == E_CACHE_IS_ONLINE) {
		success = klass->remove_locked (cache, uid, cancellable, error);
	} else {
		EOfflineState offline_state;

		offline_state = e_cache_get_offline_state (cache, uid, cancellable, error);
		if (offline_state == E_OFFLINE_STATE_UNKNOWN) {
			success = FALSE;
		} else if (offline_state == E_OFFLINE_STATE_LOCALLY_CREATED) {
			success = klass->remove_locked (cache, uid, cancellable, error);
		} else {
			g_signal_emit (cache,
				       signals[BEFORE_REMOVE],
				       0,
				       uid, cancellable, error,
				       &success);

			if (success) {
				success = e_cache_set_offline_state (cache, uid,
					E_OFFLINE_STATE_LOCALLY_DELETED, cancellable, error);
			}
		}
	}

	if (success)
		e_cache_change_revision (cache);

	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	return success;
}

/**
 * e_cache_remove_all:
 * @cache: an #ECache
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Removes all objects from the @cache in one call.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_remove_all (ECache *cache,
		    GCancellable *cancellable,
		    GError **error)
{
	ECacheClass *klass;
	GSList *uids = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);

	klass = E_CACHE_GET_CLASS (cache);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->remove_all_locked != NULL, FALSE);

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);

	success = e_cache_get_uids (cache, E_CACHE_INCLUDE_DELETED, &uids, NULL, cancellable, error);

	if (success && uids)
		success = klass->remove_all_locked (cache, uids, cancellable, error);

	if (success) {
		e_cache_sqlite_maybe_vacuum (cache, cancellable, NULL);
		e_cache_change_revision (cache);
	}

	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	g_slist_free_full (uids, g_free);

	return success;
}

static gboolean
e_cache_get_uint64_cb (ECache *cache,
		       gint ncols,
		       const gchar **column_names,
		       const gchar **column_values,
		       gpointer user_data)
{
	guint64 *pui64 = user_data;

	g_return_val_if_fail (pui64 != NULL, FALSE);

	if (ncols == 1) {
		*pui64 = column_values[0] ? g_ascii_strtoull (column_values[0], NULL, 10) : 0;
	} else {
		*pui64 = 0;
	}

	return TRUE;
}

static gboolean
e_cache_get_int64_cb (ECache *cache,
		      gint ncols,
		      const gchar **column_names,
		      const gchar **column_values,
		      gpointer user_data)
{
	gint64 *pi64 = user_data;

	g_return_val_if_fail (pi64 != NULL, FALSE);

	if (ncols == 1) {
		*pi64 = column_values[0] ? g_ascii_strtoll (column_values[0], NULL, 10) : 0;
	} else {
		*pi64 = 0;
	}

	return TRUE;
}

/**
 * e_cache_get_count:
 * @cache: an #ECache
 * @deleted_flag: one of #ECacheDeletedFlag enum
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Returns: Count of objects stored in the @cache.
 *
 * Since: 3.26
 **/
guint
e_cache_get_count (ECache *cache,
		   ECacheDeletedFlag deleted_flag,
		   GCancellable *cancellable,
		   GError **error)
{
	guint64 nobjects = 0;

	g_return_val_if_fail (E_IS_CACHE (cache), 0);

	if (deleted_flag == E_CACHE_INCLUDE_DELETED) {
		e_cache_sqlite_exec_printf (cache,
			"SELECT COUNT(*) FROM " E_CACHE_TABLE_OBJECTS,
			e_cache_get_uint64_cb, &nobjects, cancellable, error);
	} else {
		e_cache_sqlite_exec_printf (cache,
			"SELECT COUNT(*) FROM " E_CACHE_TABLE_OBJECTS
			" WHERE " E_CACHE_COLUMN_STATE " != %d",
			e_cache_get_uint64_cb, &nobjects, NULL, NULL,
			E_OFFLINE_STATE_LOCALLY_DELETED);
	}

	return nobjects;
}

struct GatherRowsData {
	GSList **out_uids;
	GSList **out_revisions;
	GSList **out_objects;
};

static gboolean
e_cache_gather_rows_data_cb (ECache *cache,
			     const gchar *uid,
			     const gchar *revision,
			     const gchar *object,
			     EOfflineState offline_state,
			     gint ncols,
			     const gchar *column_names[],
			     const gchar *column_values[],
			     gpointer user_data)
{
	struct GatherRowsData *gd = user_data;

	g_return_val_if_fail (gd != NULL, FALSE);

	if (gd->out_uids)
		*gd->out_uids = g_slist_prepend (*gd->out_uids, g_strdup (uid));

	if (gd->out_revisions)
		*gd->out_revisions = g_slist_prepend (*gd->out_revisions, g_strdup (revision));

	if (gd->out_objects)
		*gd->out_objects = g_slist_prepend (*gd->out_objects, g_strdup (object));

	return TRUE;
}

/**
 * e_cache_get_uids:
 * @cache: an #ECache
 * @deleted_flag: one of #ECacheDeletedFlag enum
 * @out_uids: (out) (transfer full) (element-type utf8): a pointer to #GSList to store the found uid to
 * @out_revisions: (out) (transfer full) (element-type utf8) (nullable): a pointer to #GSList to store
 *    the found revisions to, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets a list of unique object identifiers stored in the @cache, optionally
 * together with their revisions. The uids are not returned in any particular
 * order, but the position between @out_uids and @out_revisions matches
 * the same object.
 *
 * Both @out_uids and @out_revisions contain newly allocated #GSList, which
 * should be freed with g_slist_free_full (slist, g_free); when no longer needed.
 *
 * Returns: Whether succeeded. It doesn't necessarily mean that there was
 *    any object stored in the @cache.
 *
 * Since: 3.26
 **/
gboolean
e_cache_get_uids (ECache *cache,
		  ECacheDeletedFlag deleted_flag,
		  GSList **out_uids,
		  GSList **out_revisions,
		  GCancellable *cancellable,
		  GError **error)
{
	struct GatherRowsData gr;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (out_uids, FALSE);

	gr.out_uids = out_uids;
	gr.out_revisions = out_revisions;
	gr.out_objects = NULL;

	return e_cache_foreach (cache, deleted_flag, NULL,
		e_cache_gather_rows_data_cb, &gr, cancellable, error);
}

/**
 * e_cache_get_objects:
 * @cache: an #ECache
 * @deleted_flag: one of #ECacheDeletedFlag enum
 * @out_objects: (out) (transfer full) (element-type utf8): a pointer to #GSList to store the found objects to
 * @out_revisions: (out) (transfer full) (element-type utf8) (nullable): a pointer to #GSList to store
 *    the found revisions to, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets a list of objects stored in the @cache, optionally together with
 * their revisions. The uids are not returned in any particular order,
 * but the position between @out_objects and @out_revisions matches
 * the same object.
 *
 * Both @out_objects and @out_revisions contain newly allocated #GSList, which
 * should be freed with g_slist_free_full (slist, g_free); when no longer needed.
 *
 * Returns: Whether succeeded. It doesn't necessarily mean that there was
 *    any object stored in the @cache.
 *
 * Since: 3.26
 **/
gboolean
e_cache_get_objects (ECache *cache,
		     ECacheDeletedFlag deleted_flag,
		     GSList **out_objects,
		     GSList **out_revisions,
		     GCancellable *cancellable,
		     GError **error)
{
	struct GatherRowsData gr;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (out_objects, FALSE);

	gr.out_uids = NULL;
	gr.out_revisions = out_revisions;
	gr.out_objects = out_objects;

	return e_cache_foreach (cache, deleted_flag, NULL,
		e_cache_gather_rows_data_cb, &gr, cancellable, error);
}

struct ForeachData {
	gint uid_index;
	gint revision_index;
	gint object_index;
	gint state_index;
	ECacheForeachFunc func;
	gpointer user_data;
};

static gboolean
e_cache_foreach_cb (ECache *cache,
		    gint ncols,
		    const gchar *column_names[],
		    const gchar *column_values[],
		    gpointer user_data)
{
	struct ForeachData *fe = user_data;
	EOfflineState offline_state;

	g_return_val_if_fail (fe != NULL, FALSE);
	g_return_val_if_fail (fe->func != NULL, FALSE);
	g_return_val_if_fail (column_names != NULL, FALSE);
	g_return_val_if_fail (column_values != NULL, FALSE);

	if (fe->uid_index == -1 ||
	    fe->revision_index == -1 ||
	    fe->object_index == -1 ||
	    fe->state_index == -1) {
		gint ii;

		for (ii = 0; ii < ncols && (fe->uid_index == -1 ||
		     fe->revision_index == -1 ||
		     fe->object_index == -1 ||
		     fe->state_index == -1); ii++) {
			if (!column_names[ii])
				continue;

			if (fe->uid_index == -1 && g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_UID) == 0) {
				fe->uid_index = ii;
			} else if (fe->revision_index == -1 && g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_REVISION) == 0) {
				fe->revision_index = ii;
			} else if (fe->object_index == -1 && g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_OBJECT) == 0) {
				fe->object_index = ii;
			} else if (fe->state_index == -1 && g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_STATE) == 0) {
				fe->state_index = ii;
			}
		}
	}

	g_return_val_if_fail (fe->uid_index >= 0 && fe->uid_index < ncols, FALSE);
	g_return_val_if_fail (fe->revision_index >= 0 && fe->revision_index < ncols, FALSE);
	g_return_val_if_fail (fe->object_index >= 0 && fe->object_index < ncols, FALSE);
	g_return_val_if_fail (fe->state_index >= 0 && fe->state_index < ncols, FALSE);

	if (!column_values[fe->state_index])
		offline_state = E_OFFLINE_STATE_UNKNOWN;
	else
		offline_state = g_ascii_strtoull (column_values[fe->state_index], NULL, 10);

	return fe->func (cache, column_values[fe->uid_index], column_values[fe->revision_index], column_values[fe->object_index],
		offline_state, ncols, column_names, column_values, fe->user_data);
}

/**
 * e_cache_foreach:
 * @cache: an #ECache
 * @deleted_flag: one of #ECacheDeletedFlag enum
 * @where_clause: (nullable): an optional SQLite WHERE clause part, or %NULL
 * @func: an #ECacheForeachFunc function to call for each object
 * @user_data: user data for the @func
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Calls @func for each found object, which satisfies the criteria
 * for both @deleted_flag and @where_clause.
 *
 * Note the @func should not call any SQLite commands, because it's invoked
 * within a SELECT statement execution.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_foreach (ECache *cache,
		 ECacheDeletedFlag deleted_flag,
		 const gchar *where_clause,
		 ECacheForeachFunc func,
		 gpointer user_data,
		 GCancellable *cancellable,
		 GError **error)
{
	struct ForeachData fe;
	GString *stmt;
	gboolean success;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (func, FALSE);

	stmt = g_string_new ("SELECT * FROM " E_CACHE_TABLE_OBJECTS);

	if (where_clause) {
		g_string_append (stmt, " WHERE ");

		if (deleted_flag == E_CACHE_INCLUDE_DELETED) {
			g_string_append (stmt, where_clause);
		} else {
			g_string_append_printf (stmt, E_CACHE_COLUMN_STATE "!=%d AND (%s)",
				E_OFFLINE_STATE_LOCALLY_DELETED, where_clause);
		}
	} else if (deleted_flag != E_CACHE_INCLUDE_DELETED) {
		g_string_append_printf (stmt, " WHERE " E_CACHE_COLUMN_STATE "!=%d", E_OFFLINE_STATE_LOCALLY_DELETED);
	}

	fe.func = func;
	fe.user_data = user_data;
	fe.uid_index = -1;
	fe.revision_index = -1;
	fe.object_index = -1;
	fe.state_index = -1;

	success = e_cache_sqlite_exec_internal (cache, stmt->str, e_cache_foreach_cb, &fe, cancellable, error);

	g_string_free (stmt, TRUE);

	return success;
}

struct ForeachUpdateRowData {
	gchar *uid;
	gchar *revision;
	gchar *object;
	EOfflineState offline_state;
	gint ncols;
	GPtrArray *column_values;
};

static void
foreach_update_row_data_free (gpointer ptr)
{
	struct ForeachUpdateRowData *fr = ptr;

	if (fr) {
		g_free (fr->uid);
		g_free (fr->revision);
		g_free (fr->object);
		g_ptr_array_free (fr->column_values, TRUE);
		g_free (fr);
	}
}

struct ForeachUpdateData {
	gint uid_index;
	gint revision_index;
	gint object_index;
	gint state_index;
	GSList *rows; /* struct ForeachUpdateRowData * */
	GPtrArray *column_names;
};

static gboolean
e_cache_foreach_update_cb (ECache *cache,
			   gint ncols,
			   const gchar *column_names[],
			   const gchar *column_values[],
			   gpointer user_data)
{
	struct ForeachUpdateData *fu = user_data;
	struct ForeachUpdateRowData *rd;
	EOfflineState offline_state;
	GPtrArray *cnames, *cvalues;
	gint ii;

	g_return_val_if_fail (fu != NULL, FALSE);
	g_return_val_if_fail (column_names != NULL, FALSE);
	g_return_val_if_fail (column_values != NULL, FALSE);

	if (fu->uid_index == -1 ||
	    fu->revision_index == -1 ||
	    fu->object_index == -1 ||
	    fu->state_index == -1) {
		gint ii;

		for (ii = 0; ii < ncols && (fu->uid_index == -1 ||
		     fu->revision_index == -1 ||
		     fu->object_index == -1 ||
		     fu->state_index == -1); ii++) {
			if (!column_names[ii])
				continue;

			if (fu->uid_index == -1 && g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_UID) == 0) {
				fu->uid_index = ii;
			} else if (fu->revision_index == -1 && g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_REVISION) == 0) {
				fu->revision_index = ii;
			} else if (fu->object_index == -1 && g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_OBJECT) == 0) {
				fu->object_index = ii;
			} else if (fu->state_index == -1 && g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_STATE) == 0) {
				fu->state_index = ii;
			}
		}
	}

	g_return_val_if_fail (fu->uid_index >= 0 && fu->uid_index < ncols, FALSE);
	g_return_val_if_fail (fu->revision_index >= 0 && fu->revision_index < ncols, FALSE);
	g_return_val_if_fail (fu->object_index >= 0 && fu->object_index < ncols, FALSE);
	g_return_val_if_fail (fu->state_index >= 0 && fu->state_index < ncols, FALSE);

	if (!column_values[fu->state_index])
		offline_state = E_OFFLINE_STATE_UNKNOWN;
	else
		offline_state = g_ascii_strtoull (column_values[fu->state_index], NULL, 10);

	cnames = fu->column_names ? NULL : g_ptr_array_new_full (ncols, g_free);
	cvalues = g_ptr_array_new_full (ncols, g_free);

	for (ii = 0; ii < ncols; ii++) {
		if (fu->uid_index == ii ||
		    fu->revision_index == ii ||
		    fu->object_index == ii ||
		    fu->state_index == ii) {
			continue;
		}

		if (cnames)
			g_ptr_array_add (cnames, g_strdup (column_names[ii]));

		g_ptr_array_add (cvalues, g_strdup (column_values[ii]));
	}

	rd = g_new0 (struct ForeachUpdateRowData, 1);
	rd->uid = g_strdup (column_values[fu->uid_index]);
	rd->revision = g_strdup (column_values[fu->revision_index]);
	rd->object = g_strdup (column_values[fu->object_index]);
	rd->offline_state = offline_state;
	rd->ncols = cvalues->len;
	rd->column_values = cvalues;

	if (cnames)
		fu->column_names = cnames;

	fu->rows = g_slist_prepend (fu->rows, rd);

	g_return_val_if_fail (fu->column_names && (gint) fu->column_names->len == rd->ncols, FALSE);

	return TRUE;
}

/**
 * e_cache_foreach_update:
 * @cache: an #ECache
 * @deleted_flag: one of #ECacheDeletedFlag enum
 * @where_clause: (nullable): an optional SQLite WHERE clause part, or %NULL
 * @func: an #ECacheUpdateFunc function to call for each object
 * @user_data: user data for the @func
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Calls @func for each found object, which satisfies the criteria for both
 * @deleted_flag and @where_clause, letting the caller update values where
 * necessary. The return value of @func is used to determine whether the call
 * was successful, not whether there are any changes to be saved. If anything
 * fails during the call then the all changes are reverted.
 *
 * When there are requested any changes by the @func, this function also
 * calls e_cache_copy_missing_to_column_values() to ensure no descendant
 * column data is lost.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_foreach_update (ECache *cache,
			ECacheDeletedFlag deleted_flag,
			const gchar *where_clause,
			ECacheUpdateFunc func,
			gpointer user_data,
			GCancellable *cancellable,
			GError **error)
{
	GString *stmt_begin;
	gchar *uid = NULL;
	gint n_results;
	gboolean has_where = TRUE;
	gboolean success;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (func, FALSE);

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);

	stmt_begin = g_string_new ("SELECT * FROM " E_CACHE_TABLE_OBJECTS);

	if (where_clause) {
		g_string_append (stmt_begin, " WHERE ");

		if (deleted_flag == E_CACHE_INCLUDE_DELETED) {
			g_string_append (stmt_begin, where_clause);
		} else {
			g_string_append_printf (stmt_begin, E_CACHE_COLUMN_STATE "!=%d AND (%s)",
				E_OFFLINE_STATE_LOCALLY_DELETED, where_clause);
		}
	} else if (deleted_flag != E_CACHE_INCLUDE_DELETED) {
		g_string_append_printf (stmt_begin, " WHERE " E_CACHE_COLUMN_STATE "!=%d", E_OFFLINE_STATE_LOCALLY_DELETED);
	} else {
		has_where = FALSE;
	}

	do {
		GString *stmt;
		GSList *link;
		struct ForeachUpdateData fu;

		fu.uid_index = -1;
		fu.revision_index = -1;
		fu.object_index = -1;
		fu.state_index = -1;
		fu.rows = NULL;
		fu.column_names = NULL;

		stmt = g_string_new (stmt_begin->str);

		if (uid) {
			if (has_where)
				g_string_append (stmt, " AND ");
			else
				g_string_append (stmt, " WHERE ");

			e_cache_sqlite_stmt_append_printf (stmt, E_CACHE_COLUMN_UID ">%Q", uid);
		}

		g_string_append_printf (stmt, " ORDER BY " E_CACHE_COLUMN_UID " ASC LIMIT %d", E_CACHE_UPDATE_BATCH_SIZE);

		success = e_cache_sqlite_exec_internal (cache, stmt->str, e_cache_foreach_update_cb, &fu, cancellable, error);

		g_string_free (stmt, TRUE);

		if (success) {
			n_results = 0;
			fu.rows = g_slist_reverse (fu.rows);

			for (link = fu.rows; success && link; link = g_slist_next (link), n_results++) {
				struct ForeachUpdateRowData *fr = link->data;

				success = fr && fr->column_values && fu.column_names;
				if (success) {
					gchar *new_revision = NULL;
					gchar *new_object = NULL;
					EOfflineState new_offline_state = fr->offline_state;
					ECacheColumnValues *new_other_columns = NULL;

					success = func (cache, fr->uid, fr->revision, fr->object, fr->offline_state,
						fr->ncols, (const gchar **) fu.column_names->pdata,
						(const gchar **) fr->column_values->pdata,
						&new_revision, &new_object, &new_offline_state, &new_other_columns,
						user_data);

					if (success && (
					    (new_revision && g_strcmp0 (new_revision, fr->revision) != 0) ||
					    (new_object && g_strcmp0 (new_object, fr->object) != 0) ||
					    (new_offline_state != fr->offline_state) ||
					    (new_other_columns && e_cache_column_values_get_size (new_other_columns) > 0))) {
						if (!new_other_columns)
							new_other_columns = e_cache_column_values_new ();

						e_cache_copy_missing_to_column_values (cache, fr->ncols,
							(const gchar **) fu.column_names->pdata,
							(const gchar **) fr->column_values->pdata,
							new_other_columns);

						success = e_cache_put_locked (cache,
							fr->uid,
							new_revision ? new_revision : fr->revision,
							new_object ? new_object : fr->object,
							new_other_columns,
							new_offline_state,
							TRUE, cancellable, error);
					}

					g_free (new_revision);
					g_free (new_object);
					e_cache_column_values_free (new_other_columns);

					if (!g_slist_next (link)) {
						g_free (uid);
						uid = g_strdup (fr->uid);
					}
				}
			}
		}

		g_slist_free_full (fu.rows, foreach_update_row_data_free);
		if (fu.column_names)
			g_ptr_array_free (fu.column_names, TRUE);
	} while (success && n_results == E_CACHE_UPDATE_BATCH_SIZE);

	g_string_free (stmt_begin, TRUE);
	g_free (uid);

	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	return success;
}

/**
 * e_cache_copy_missing_to_column_values:
 * @cache: an #ECache
 * @ncols: count of columns, items in column_names and column_values
 * @column_names: column names
 * @column_values: column values
 * @other_columns: (in out): an #ECacheColumnValues to fill
 *
 * Adds every column value which is not part of the @other_columns to it,
 * except of E_CACHE_COLUMN_UID, E_CACHE_COLUMN_REVISION, E_CACHE_COLUMN_OBJECT
 * and E_CACHE_COLUMN_STATE columns.
 *
 * This can be used within the callback of e_cache_foreach_update().
 *
 * Since: 3.32
 **/
void
e_cache_copy_missing_to_column_values (ECache *cache,
				       gint ncols,
				       const gchar *column_names[],
				       const gchar *column_values[],
				       ECacheColumnValues *other_columns)
{
	gint ii;

	g_return_if_fail (E_IS_CACHE (cache));
	g_return_if_fail (column_names != NULL);
	g_return_if_fail (column_values != NULL);
	g_return_if_fail (other_columns != NULL);

	for (ii = 0; ii < ncols; ii++) {
		if (column_names[ii] && column_values[ii] &&
		    !e_cache_column_values_contains (other_columns, column_names[ii]) &&
		    g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_UID) != 0 &&
		    g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_REVISION) != 0 &&
		    g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_OBJECT) != 0 &&
		    g_ascii_strcasecmp (column_names[ii], E_CACHE_COLUMN_STATE) != 0) {
			e_cache_column_values_put (other_columns, column_names[ii], column_values[ii]);
		}
	}
}

/**
 * e_cache_get_offline_state:
 * @cache: an #ECache
 * @uid: a unique identifier of an object
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Returns: Current offline state #EOfflineState for the given object.
 *    It returns %E_OFFLINE_STATE_UNKNOWN when the object could not be
 *    found or other error happened.
 *
 * Since: 3.26
 **/
EOfflineState
e_cache_get_offline_state (ECache *cache,
			   const gchar *uid,
			   GCancellable *cancellable,
			   GError **error)
{
	EOfflineState offline_state = E_OFFLINE_STATE_UNKNOWN;
	gint64 value = offline_state;

	g_return_val_if_fail (E_IS_CACHE (cache), E_OFFLINE_STATE_UNKNOWN);
	g_return_val_if_fail (uid != NULL, E_OFFLINE_STATE_UNKNOWN);

	if (!e_cache_contains (cache, uid, E_CACHE_INCLUDE_DELETED)) {
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object “%s” not found"), uid);
		return offline_state;
	}

	if (e_cache_sqlite_exec_printf (cache,
		"SELECT " E_CACHE_COLUMN_STATE " FROM " E_CACHE_TABLE_OBJECTS
		" WHERE " E_CACHE_COLUMN_UID " = %Q",
		e_cache_get_int64_cb, &value, cancellable, error,
		uid)) {
		offline_state = value;
	}

	return offline_state;
}

/**
 * e_cache_set_offline_state:
 * @cache: an #ECache
 * @uid: a unique identifier of an object
 * @state: an #EOfflineState to set
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Sets an offline @state for the object identified by @uid.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_set_offline_state (ECache *cache,
			   const gchar *uid,
			   EOfflineState state,
			   GCancellable *cancellable,
			   GError **error)
{
	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	if (!e_cache_contains (cache, uid, E_CACHE_INCLUDE_DELETED)) {
		g_set_error (error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object “%s” not found"), uid);
		return FALSE;
	}

	return e_cache_sqlite_exec_printf (cache,
		"UPDATE " E_CACHE_TABLE_OBJECTS " SET " E_CACHE_COLUMN_STATE "=%d"
		" WHERE " E_CACHE_COLUMN_UID " = %Q",
		NULL, NULL, cancellable, error,
		state, uid);
}

static gboolean
e_cache_get_offline_changes_cb (ECache *cache,
				const gchar *uid,
				const gchar *revision,
				const gchar *object,
				EOfflineState offline_state,
				gint ncols,
				const gchar *column_names[],
				const gchar *column_values[],
				gpointer user_data)
{
	GSList **pchanges = user_data;

	g_return_val_if_fail (pchanges != NULL, FALSE);

	if (offline_state == E_OFFLINE_STATE_LOCALLY_CREATED ||
	    offline_state == E_OFFLINE_STATE_LOCALLY_MODIFIED ||
	    offline_state == E_OFFLINE_STATE_LOCALLY_DELETED) {
		*pchanges = g_slist_prepend (*pchanges, e_cache_offline_change_new (uid, revision, object, offline_state));
	}

	return TRUE;
}

/**
 * e_cache_get_offline_changes:
 * @cache: an #ECache
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gathers the list of all offline changes being done so far.
 * The returned #GSList contains #ECacheOfflineChange structure.
 * Use e_cache_clear_offline_changes() to clear all offline
 * changes at once.
 *
 * Returns: (transfer full) (element-type ECacheOfflineChange): A newly allocated list of all
 *    offline changes. Free it with g_slist_free_full (slist, e_cache_offline_change_free);
 *    when no longer needed.
 *
 * Since: 3.26
 **/
GSList *
e_cache_get_offline_changes (ECache *cache,
			     GCancellable *cancellable,
			     GError **error)
{
	GSList *changes = NULL;
	gchar *stmt;

	g_return_val_if_fail (E_IS_CACHE (cache), NULL);

	stmt = e_cache_sqlite_stmt_printf (E_CACHE_COLUMN_STATE "!=%d", E_OFFLINE_STATE_SYNCED);

	if (!e_cache_foreach (cache, E_CACHE_INCLUDE_DELETED, stmt, e_cache_get_offline_changes_cb, &changes, cancellable, error)) {
		g_slist_free_full (changes, e_cache_offline_change_free);
		changes = NULL;
	}

	e_cache_sqlite_stmt_free (stmt);

	return changes;
}

/**
 * e_cache_clear_offline_changes:
 * @cache: an #ECache
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Marks all objects as being fully synchronized with the server and
 * removes those which are marked as locally deleted.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_clear_offline_changes (ECache *cache,
			       GCancellable *cancellable,
			       GError **error)
{
	ECacheClass *klass;
	gboolean success;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);

	klass = E_CACHE_GET_CLASS (cache);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->clear_offline_changes_locked != NULL, FALSE);

	e_cache_lock (cache, E_CACHE_LOCK_WRITE);

	success = klass->clear_offline_changes_locked (cache, cancellable, error);

	e_cache_unlock (cache, success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	return success;
}

/**
 * e_cache_set_key:
 * @cache: an #ECache
 * @key: a key name
 * @value: (nullable): a value to set, or %NULL to delete the key
 * @error: return location for a #GError, or %NULL
 *
 * Sets a @value of the user @key, or deletes it, if the @value is %NULL.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_set_key (ECache *cache,
		 const gchar *key,
		 const gchar *value,
		 GError **error)
{
	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (key != NULL, FALSE);

	return e_cache_set_key_internal (cache, TRUE, key, value, error);
}

/**
 * e_cache_dup_key:
 * @cache: an #ECache
 * @key: a key name
 * @error: return location for a #GError, or %NULL
 *
 * Returns: (transfer full): a value of the @key. Free the returned string
 *    with g_free(), when no longer needed.
 *
 * Since: 3.26
 **/
gchar *
e_cache_dup_key (ECache *cache,
		 const gchar *key,
		 GError **error)
{
	g_return_val_if_fail (E_IS_CACHE (cache), NULL);
	g_return_val_if_fail (key != NULL, NULL);

	return e_cache_dup_key_internal (cache, TRUE, key, error);
}

/**
 * e_cache_set_key_int:
 * @cache: an #ECache
 * @key: a key name
 * @value: an integer value to set
 * @error: return location for a #GError, or %NULL
 *
 * Sets an integer @value for the user @key.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_set_key_int (ECache *cache,
		     const gchar *key,
		     gint value,
		     GError **error)
{
	gchar *str_value;
	gboolean success;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (key != NULL, FALSE);

	str_value = g_strdup_printf ("%d", value);
	success = e_cache_set_key (cache, key, str_value, error);
	g_free (str_value);

	return success;
}

/**
 * e_cache_get_key_int:
 * @cache: an #ECache
 * @key: a key name
 * @error: return location for a #GError, or %NULL
 *
 * Reads the user @key value as an integer.
 *
 * Returns: The user @key value or -1 on error.
 *
 * Since: 3.26
 **/
gint
e_cache_get_key_int (ECache *cache,
		     const gchar *key,
		     GError **error)
{
	gchar *str_value;
	gint value;

	g_return_val_if_fail (E_IS_CACHE (cache), -1);

	str_value = e_cache_dup_key (cache, key, error);
	if (!str_value)
		return -1;

	value = g_ascii_strtoll (str_value, NULL, 10);
	g_free (str_value);

	return value;
}

/**
 * e_cache_lock:
 * @cache: an #ECache
 * @lock_type: an #ECacheLockType
 *
 * Locks the @cache thus other threads cannot use it.
 * This can be called recursively within one thread.
 * Each call should have its pair e_cache_unlock().
 *
 * Since: 3.26
 **/
void
e_cache_lock (ECache *cache,
	      ECacheLockType lock_type)
{
	g_return_if_fail (E_IS_CACHE (cache));

	g_rec_mutex_lock (&cache->priv->lock);

	cache->priv->in_transaction++;
	g_return_if_fail (cache->priv->in_transaction > 0);

	if (cache->priv->in_transaction == 1) {
		/* It's important to make the distinction between a
		 * transaction which will read or one which will write.
		 *
		 * While it's not well documented, when receiving the SQLITE_BUSY
		 * error status, one can only safely retry at the beginning of
		 * the transaction.
		 *
		 * If a transaction is 'upgraded' to require a writer lock
		 * half way through the transaction and SQLITE_BUSY is returned,
		 * the whole transaction would need to be retried from the beginning.
		 */
		cache->priv->lock_type = lock_type;

		switch (lock_type) {
		case E_CACHE_LOCK_READ:
			e_cache_sqlite_exec_internal (cache, "BEGIN", NULL, NULL, NULL, NULL);
			break;
		case E_CACHE_LOCK_WRITE:
			e_cache_sqlite_exec_internal (cache, "BEGIN IMMEDIATE", NULL, NULL, NULL, NULL);
			break;
		}
	} else {
		/* Warn about cases where where a read transaction might be upgraded */
		if (lock_type == E_CACHE_LOCK_WRITE && cache->priv->lock_type == E_CACHE_LOCK_READ)
			g_warning (
				"A nested transaction wants to write, "
				"but the outermost transaction was started "
				"without a writer lock.");
	}
}

/**
 * e_cache_unlock:
 * @cache: an #ECache
 * @action: an #ECacheUnlockAction
 *
 * Unlocks the cache which was previouly locked with e_cache_lock().
 * The cache locked with #E_CACHE_LOCK_WRITE should use either
 * @action #E_CACHE_UNLOCK_COMMIT or #E_CACHE_UNLOCK_ROLLBACK,
 * while the #E_CACHE_LOCK_READ should use #E_CACHE_UNLOCK_NONE @action.
 *
 * Since: 3.26
 **/
void
e_cache_unlock (ECache *cache,
		ECacheUnlockAction action)
{
	g_return_if_fail (E_IS_CACHE (cache));
	g_return_if_fail (cache->priv->in_transaction > 0);

	cache->priv->in_transaction--;

	if (cache->priv->in_transaction == 0) {
		switch (action) {
		case E_CACHE_UNLOCK_NONE:
		case E_CACHE_UNLOCK_COMMIT:
			e_cache_sqlite_exec_internal (cache, "COMMIT", NULL, NULL, NULL, NULL);
			break;
		case E_CACHE_UNLOCK_ROLLBACK:
			e_cache_sqlite_exec_internal (cache, "ROLLBACK", NULL, NULL, NULL, NULL);
			break;
		}
	}

	g_rec_mutex_unlock (&cache->priv->lock);
}

/**
 * e_cache_get_sqlitedb:
 * @cache: an #ECache
 *
 * Returns: (transfer none): An SQLite3 database pointer. It is owned by the @cache.
 *
 * Since: 3.26
 **/
gpointer
e_cache_get_sqlitedb (ECache *cache)
{
	g_return_val_if_fail (E_IS_CACHE (cache), NULL);

	return cache->priv->db;
}

/**
 * e_cache_sqlite_exec:
 * @cache: an #ECache
 * @sql_stmt: an SQLite statement to execute
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Executes an SQLite statement. Use e_cache_sqlite_select() for
 * SELECT statements.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_sqlite_exec (ECache *cache,
		     const gchar *sql_stmt,
		     GCancellable *cancellable,
		     GError **error)
{
	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);

	return e_cache_sqlite_exec_internal (cache, sql_stmt, NULL, NULL, cancellable, error);
}

/**
 * e_cache_sqlite_select:
 * @cache: an #ECache
 * @sql_stmt: an SQLite SELECT statement to execute
 * @func: an #ECacheSelectFunc function to call for each row
 * @user_data: user data for @func
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Executes a SELECT statement @sql_stmt and calls @func for each row of the result.
 * Use e_cache_sqlite_exec() for statements which do not return row sets.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cache_sqlite_select (ECache *cache,
		       const gchar *sql_stmt,
		       ECacheSelectFunc func,
		       gpointer user_data,
		       GCancellable *cancellable,
		       GError **error)
{
	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (sql_stmt, FALSE);
	g_return_val_if_fail (func, FALSE);

	return e_cache_sqlite_exec_internal (cache, sql_stmt, func, user_data, cancellable, error);
}

/**
 * e_cache_sqlite_stmt_append_printf:
 * @stmt: a #GString statement to append to
 * @format: a printf-like format
 * @...: arguments for the @format
 *
 * Appends an SQLite statement fragment based on the @format and
 * its arguments to the @stmt.
 * The @format can contain any values recognized by sqlite3_mprintf().
 *
 * Since: 3.26
 **/
void
e_cache_sqlite_stmt_append_printf (GString *stmt,
				   const gchar *format,
				   ...)
{
	va_list args;
	gchar *tmp_stmt;

	g_return_if_fail (stmt != NULL);
	g_return_if_fail (format != NULL);

	va_start (args, format);
	tmp_stmt = sqlite3_vmprintf (format, args);
	va_end (args);

	g_string_append (stmt, tmp_stmt);

	sqlite3_free (tmp_stmt);
}

/**
 * e_cache_sqlite_stmt_printf:
 * @format: a printf-like format
 * @...: arguments for the @format
 *
 * Creates an SQLite statement based on the @format and its arguments.
 * The @format can contain any values recognized by sqlite3_mprintf().
 *
 * Returns: (transfer full): A new SQLite statement. Free the returned
 *    string with e_cache_sqlite_stmt_free() when no longer needed.
 *
 * Since: 3.26
 **/
gchar *
e_cache_sqlite_stmt_printf (const gchar *format,
			    ...)
{
	va_list args;
	gchar *stmt;

	g_return_val_if_fail (format != NULL, NULL);

	va_start (args, format);
	stmt = sqlite3_vmprintf (format, args);
	va_end (args);

	return stmt;
}

/**
 * e_cache_sqlite_stmt_free:
 * @stmt: a statement to free
 *
 * Frees a statement previously constructed with e_cache_sqlite_stmt_printf().
 *
 * Since: 3.26
 **/
void
e_cache_sqlite_stmt_free (gchar *stmt)
{
	if (stmt)
		sqlite3_free (stmt);
}

/**
 * e_cache_sqlite_maybe_vacuum:
 * @cache: an #ECache
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Runs vacuum (compacts the database file), if needed.
 *
 * Returns: Whether succeeded. It doesn't mean that the vacuum had been run,
 *    only that no error happened during the call.
 *
 * Since: 3.26
 **/
gboolean
e_cache_sqlite_maybe_vacuum (ECache *cache,
			     GCancellable *cancellable,
			     GError **error)
{
	guint64 page_count = 0, page_size = 0, freelist_count = 0;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);

	g_rec_mutex_lock (&cache->priv->lock);

	if (e_cache_sqlite_exec_internal (cache, "PRAGMA page_count;", e_cache_get_uint64_cb, &page_count, cancellable, &local_error) &&
	    e_cache_sqlite_exec_internal (cache, "PRAGMA page_size;", e_cache_get_uint64_cb, &page_size, cancellable, &local_error) &&
	    e_cache_sqlite_exec_internal (cache, "PRAGMA freelist_count;", e_cache_get_uint64_cb, &freelist_count, cancellable, &local_error)) {
		/* Vacuum, if there's more than 5% of the free pages, or when free pages use more than 10MB */
		success = !page_count || !freelist_count ||
			(freelist_count * page_size < 1024 * 1024 * 10 && freelist_count * 1000 / page_count <= 50) ||
			e_cache_sqlite_exec_internal (cache, "vacuum;", NULL, NULL, cancellable, &local_error);
	}

	g_rec_mutex_unlock (&cache->priv->lock);

	if (local_error) {
		g_propagate_error (error, local_error);
		success = FALSE;
	}

	return success;
}

static gboolean
e_cache_put_locked_default (ECache *cache,
			    const gchar *uid,
			    const gchar *revision,
			    const gchar *object,
			    ECacheColumnValues *other_columns,
			    EOfflineState offline_state,
			    gboolean is_replace,
			    GCancellable *cancellable,
			    GError **error)
{
	GString *statement, *other_names = NULL, *other_values = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (object != NULL, FALSE);

	statement = g_string_sized_new (255);

	e_cache_sqlite_stmt_append_printf (statement, "INSERT OR REPLACE INTO %Q ("
		E_CACHE_COLUMN_UID ","
		E_CACHE_COLUMN_REVISION ","
		E_CACHE_COLUMN_OBJECT ","
		E_CACHE_COLUMN_STATE,
		E_CACHE_TABLE_OBJECTS);

	if (other_columns) {
		GHashTableIter iter;
		gpointer key, value;

		e_cache_column_values_init_iter (other_columns, &iter);
		while (g_hash_table_iter_next (&iter, &key, &value)) {
			if (!other_names)
				other_names = g_string_new ("");
			g_string_append (other_names, ",");

			e_cache_sqlite_stmt_append_printf (other_names, "%Q", key);

			if (!other_values)
				other_values = g_string_new ("");

			g_string_append (other_values, ",");
			if (value) {
				e_cache_sqlite_stmt_append_printf (other_values, "%Q", value);
			} else {
				g_string_append (other_values, "NULL");
			}
		}
	}

	if (other_names)
		g_string_append (statement, other_names->str);

	g_string_append (statement, ") VALUES (");

	e_cache_sqlite_stmt_append_printf (statement, "%Q,%Q,%Q,%d", uid, revision ? revision : "", object, offline_state);

	if (other_values)
		g_string_append (statement, other_values->str);

	g_string_append (statement, ")");

	success = e_cache_sqlite_exec_internal (cache, statement->str, NULL, NULL, cancellable, error);

	if (other_names)
		g_string_free (other_names, TRUE);
	if (other_values)
		g_string_free (other_values, TRUE);
	g_string_free (statement, TRUE);

	return success;
}

static gboolean
e_cache_remove_locked_default (ECache *cache,
			       const gchar *uid,
			       GCancellable *cancellable,
			       GError **error)
{
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	g_signal_emit (cache,
		       signals[BEFORE_REMOVE],
		       0,
		       uid, cancellable, error,
		       &success);

	success = success && e_cache_sqlite_exec_printf (cache,
		"DELETE FROM " E_CACHE_TABLE_OBJECTS " WHERE " E_CACHE_COLUMN_UID " = %Q",
		NULL, NULL, cancellable, error,
		uid);

	return success;
}

static gboolean
e_cache_remove_all_locked_default (ECache *cache,
				   const GSList *uids,
				   GCancellable *cancellable,
				   GError **error)
{
	const GSList *link;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);

	for (link = uids; link && success; link = g_slist_next (link)) {
		const gchar *uid = link->data;

		g_signal_emit (cache,
			       signals[BEFORE_REMOVE],
			       0,
			       uid, cancellable, error,
			       &success);
	}

	if (success) {
		success = e_cache_sqlite_exec_printf (cache,
			"DELETE FROM " E_CACHE_TABLE_OBJECTS,
			NULL, NULL, cancellable, error);
	}

	return success;
}

static gboolean
e_cache_clear_offline_changes_locked_default (ECache *cache,
					      GCancellable *cancellable,
					      GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_CACHE (cache), FALSE);

	success = e_cache_sqlite_exec_printf (cache,
		"DELETE FROM " E_CACHE_TABLE_OBJECTS " WHERE " E_CACHE_COLUMN_STATE "=%d",
		NULL, NULL, cancellable, error,
		E_OFFLINE_STATE_LOCALLY_DELETED);

	success = success && e_cache_sqlite_exec_printf (cache,
		"UPDATE " E_CACHE_TABLE_OBJECTS " SET " E_CACHE_COLUMN_STATE "=%d"
		" WHERE " E_CACHE_COLUMN_STATE "!=%d",
		NULL, NULL, cancellable, error,
		E_OFFLINE_STATE_SYNCED, E_OFFLINE_STATE_SYNCED);

	return success;
}

static gboolean
e_cache_signals_accumulator (GSignalInvocationHint *ihint,
			     GValue *return_accu,
			     const GValue *handler_return,
			     gpointer data)
{
	gboolean handler_result;

	handler_result = g_value_get_boolean (handler_return);
	g_value_set_boolean (return_accu, handler_result);

	return handler_result;
}

static gboolean
e_cache_before_put_default (ECache *cache,
			    const gchar *uid,
			    const gchar *revision,
			    const gchar *object,
			    ECacheColumnValues *other_columns,
			    gboolean is_replace,
			    GCancellable *cancellable,
			    GError **error)
{
	return TRUE;
}

static gboolean
e_cache_before_remove_default (ECache *cache,
			       const gchar *uid,
			       GCancellable *cancellable,
			       GError **error)
{
	return TRUE;
}

static void
e_cache_finalize (GObject *object)
{
	ECache *cache = E_CACHE (object);

	g_free (cache->priv->filename);
	cache->priv->filename = NULL;

	if (cache->priv->db) {
		sqlite3_close (cache->priv->db);
		cache->priv->db = NULL;
	}

	g_rec_mutex_clear (&cache->priv->lock);

	g_warn_if_fail (cache->priv->cancellable == NULL);
	g_clear_object (&cache->priv->cancellable);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_cache_parent_class)->finalize (object);
}

static void
e_cache_class_init (ECacheClass *klass)
{
	GObjectClass *object_class;

	g_type_class_add_private (klass, sizeof (ECachePrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = e_cache_finalize;

	klass->put_locked = e_cache_put_locked_default;
	klass->remove_locked = e_cache_remove_locked_default;
	klass->remove_all_locked = e_cache_remove_all_locked_default;
	klass->clear_offline_changes_locked = e_cache_clear_offline_changes_locked_default;
	klass->before_put = e_cache_before_put_default;
	klass->before_remove = e_cache_before_remove_default;

	signals[BEFORE_PUT] = g_signal_new (
		"before-put",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ECacheClass, before_put),
		e_cache_signals_accumulator,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_BOOLEAN, 7,
		G_TYPE_STRING,
		G_TYPE_STRING,
		G_TYPE_STRING,
		G_TYPE_HASH_TABLE,
		G_TYPE_BOOLEAN,
		G_TYPE_CANCELLABLE,
		G_TYPE_POINTER);

	signals[BEFORE_REMOVE] = g_signal_new (
		"before-remove",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ECacheClass, before_remove),
		e_cache_signals_accumulator,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_BOOLEAN, 3,
		G_TYPE_STRING,
		G_TYPE_CANCELLABLE,
		G_TYPE_POINTER);

	signals[REVISION_CHANGED] = g_signal_new (
		"revision-changed",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ECacheClass, revision_changed),
		NULL,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_NONE, 0,
		G_TYPE_NONE);

	e_sqlite3_vfs_init ();
}

static void
e_cache_init (ECache *cache)
{
	cache->priv = G_TYPE_INSTANCE_GET_PRIVATE (cache, E_TYPE_CACHE, ECachePrivate);

	cache->priv->filename = NULL;
	cache->priv->db = NULL;
	cache->priv->cancellable = NULL;
	cache->priv->in_transaction = 0;
	cache->priv->revision_change_frozen = 0;
	cache->priv->revision_counter = 0;
	cache->priv->last_revision_time = 0;
	cache->priv->needs_revision_change = FALSE;

	g_rec_mutex_init (&cache->priv->lock);
}
