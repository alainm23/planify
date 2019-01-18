/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2013 Intel Corporation
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
 *
 * Authors: Tristan Van Berkom <tristanvb@openismus.com>
 */

/**
 * SECTION: e-data-book-cursor-cache
 * @include: libedata-book/libedata-book.h
 * @short_description: The SQLite cursor implementation
 *
 * This cursor implementation can be used with any backend which
 * stores contacts using #EBookCache.
 */

#include "evolution-data-server-config.h"

#include <glib/gi18n.h>

#include "e-data-book-cursor-cache.h"

struct _EDataBookCursorCachePrivate {
	EBookCache *book_cache;
	EBookCacheCursor *cursor;
};

enum {
	PROP_0,
	PROP_BOOK_CACHE,
	PROP_CURSOR,
};

G_DEFINE_TYPE (EDataBookCursorCache, e_data_book_cursor_cache, E_TYPE_DATA_BOOK_CURSOR);

static gboolean
edbcc_set_sexp (EDataBookCursor *cursor,
		const gchar *sexp,
		GError **error)
{
	EDataBookCursorCache *cache_cursor;
	gboolean success;
	GError *local_error = NULL;

	cache_cursor = E_DATA_BOOK_CURSOR_CACHE (cursor);

	success = e_book_cache_cursor_set_sexp (cache_cursor->priv->book_cache, cache_cursor->priv->cursor, sexp, &local_error);

	if (!success) {
		if (g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_INVALID_QUERY)) {
			g_set_error_literal (error, E_CLIENT_ERROR, E_CLIENT_ERROR_INVALID_QUERY, local_error->message);
			g_clear_error (&local_error);
		} else {
			g_propagate_error (error, local_error);
		}
	}

	return success;
}

static gboolean
convert_origin (EBookCursorOrigin src_origin,
		EBookCacheCursorOrigin *dest_origin,
		GError **error)
{
	gboolean success = TRUE;

	switch (src_origin) {
	case E_BOOK_CURSOR_ORIGIN_CURRENT:
		*dest_origin = E_BOOK_CACHE_CURSOR_ORIGIN_CURRENT;
		break;
	case E_BOOK_CURSOR_ORIGIN_BEGIN:
		*dest_origin = E_BOOK_CACHE_CURSOR_ORIGIN_BEGIN;
		break;
	case E_BOOK_CURSOR_ORIGIN_END:
		*dest_origin = E_BOOK_CACHE_CURSOR_ORIGIN_END;
		break;
	default:
		g_set_error_literal (error, E_CLIENT_ERROR, E_CLIENT_ERROR_INVALID_ARG, _("Unrecognized cursor origin"));
		success = FALSE;
		break;
	}

	return success;
}

static void
convert_flags (EBookCursorStepFlags src_flags,
	       EBookCacheCursorStepFlags *dest_flags)
{
	if (src_flags & E_BOOK_CURSOR_STEP_MOVE)
		*dest_flags |= E_BOOK_CACHE_CURSOR_STEP_MOVE;

	if (src_flags & E_BOOK_CURSOR_STEP_FETCH)
		*dest_flags |= E_BOOK_CACHE_CURSOR_STEP_FETCH;
}

static gint
edbcc_step (EDataBookCursor *cursor,
	    const gchar *revision_guard,
	    EBookCursorStepFlags flags,
	    EBookCursorOrigin origin,
	    gint count,
	    GSList **results,
	    GCancellable *cancellable,
	    GError **error)
{
	EDataBookCursorCache *cache_cursor;
	GSList *local_results = NULL, *local_converted_results = NULL, *link;
	EBookCacheCursorOrigin cache_origin = E_BOOK_CACHE_CURSOR_ORIGIN_CURRENT;
	EBookCacheCursorStepFlags cache_flags = 0;
	gchar *revision = NULL;
	gboolean success = TRUE;
	gint n_results = -1;

	cache_cursor = E_DATA_BOOK_CURSOR_CACHE (cursor);

	if (!convert_origin (origin, &cache_origin, error))
		return FALSE;

	convert_flags (flags, &cache_flags);

	/* Here we check the EBookCache revision
	 * against the revision_guard with an atomic transaction
	 * with the cache.
	 *
	 * The addressbook modifications and revision changes
	 * are also atomically committed to the SQLite.
	 */
	e_cache_lock (E_CACHE (cache_cursor->priv->book_cache), E_CACHE_LOCK_READ);

	if (revision_guard)
		revision = e_cache_dup_revision (E_CACHE (cache_cursor->priv->book_cache));

	if (revision_guard &&
	    g_strcmp0 (revision, revision_guard) != 0) {
		g_set_error_literal (error, E_CLIENT_ERROR, E_CLIENT_ERROR_OUT_OF_SYNC,
			_("Out of sync revision while moving cursor"));
		success = FALSE;
	}

	if (success) {
		GError *local_error = NULL;

		n_results = e_book_cache_cursor_step (
			cache_cursor->priv->book_cache,
			cache_cursor->priv->cursor,
			cache_flags,
			cache_origin,
			count,
			&local_results,
			cancellable,
			&local_error);

		if (n_results < 0) {

			/* Convert the SQLite backend error to an EClient error */
			if (g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_END_OF_LIST)) {
				g_set_error_literal (error, E_CLIENT_ERROR, E_CLIENT_ERROR_QUERY_REFUSED, local_error->message);
				g_clear_error (&local_error);
			} else {
				g_propagate_error (error, local_error);
			}

			success = FALSE;
		}
	}

	e_cache_unlock (E_CACHE (cache_cursor->priv->book_cache), E_CACHE_UNLOCK_NONE);

	for (link = local_results; link; link = link->next) {
		EBookCacheSearchData *data = link->data;

		local_converted_results = g_slist_prepend (local_converted_results, data->vcard);
		data->vcard = NULL;
	}

	g_slist_free_full (local_results, e_book_cache_search_data_free);

	if (results)
		*results = g_slist_reverse (local_converted_results);
	else
		g_slist_free_full (local_converted_results, g_free);

	g_free (revision);

	if (success)
		return n_results;

	return -1;
}

static gboolean
edbcc_set_alphabetic_index (EDataBookCursor *cursor,
			    gint index,
			    const gchar *locale,
			    GError **error)
{
	EDataBookCursorCache *cache_cursor;
	gchar *current_locale;

	cache_cursor = E_DATA_BOOK_CURSOR_CACHE (cursor);

	current_locale = e_book_cache_dup_locale (cache_cursor->priv->book_cache);

	/* Locale mismatch, need to report error */
	if (g_strcmp0 (current_locale, locale) != 0) {
		g_set_error_literal (error, E_CLIENT_ERROR, E_CLIENT_ERROR_OUT_OF_SYNC,
			_("Alphabetic index was set for incorrect locale"));
		g_free (current_locale);

		return FALSE;
	}

	e_book_cache_cursor_set_target_alphabetic_index (
		cache_cursor->priv->book_cache,
		cache_cursor->priv->cursor,
		index);

	g_free (current_locale);

	return TRUE;
}

static gboolean
edbcc_get_position (EDataBookCursor *cursor,
		    gint *total,
		    gint *position,
		    GCancellable *cancellable,
		    GError **error)
{
	EDataBookCursorCache *cache_cursor;

	cache_cursor = E_DATA_BOOK_CURSOR_CACHE (cursor);

	return e_book_cache_cursor_calculate (
		cache_cursor->priv->book_cache,
		cache_cursor->priv->cursor,
		total,
		position,
		cancellable,
		error);
}

static gint
edbcc_compare_contact (EDataBookCursor *cursor,
		       EContact *contact,
		       gboolean *matches_sexp)
{
	EDataBookCursorCache *cache_cursor;

	cache_cursor = E_DATA_BOOK_CURSOR_CACHE (cursor);

	return e_book_cache_cursor_compare_contact (
		cache_cursor->priv->book_cache,
		cache_cursor->priv->cursor,
		contact,
		matches_sexp);
}

static gboolean
edbcc_load_locale (EDataBookCursor *cursor,
		   gchar **out_locale,
		   GError **error)
{
	EDataBookCursorCache *cache_cursor;

	g_return_val_if_fail (E_IS_DATA_BOOK_CURSOR_CACHE (cursor), FALSE);
	g_return_val_if_fail (out_locale != NULL, FALSE);

	cache_cursor = E_DATA_BOOK_CURSOR_CACHE (cursor);

	*out_locale = e_book_cache_dup_locale (cache_cursor->priv->book_cache);

	return TRUE;
}

static void
e_data_book_cursor_cache_set_property (GObject *object,
				       guint property_id,
				       const GValue *value,
				       GParamSpec *pspec)
{
	EDataBookCursorCache *cache_cursor = E_DATA_BOOK_CURSOR_CACHE (object);

	switch (property_id) {

	case PROP_BOOK_CACHE:
		/* Construct-only, can only be set once */
		cache_cursor->priv->book_cache = g_value_dup_object (value);
		return;

	case PROP_CURSOR:
		/* Construct-only, can only be set once */
		cache_cursor->priv->cursor = g_value_get_pointer (value);
		return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_data_book_cursor_cache_dispose (GObject *object)
{
	EDataBookCursorCache *cache_cursor = E_DATA_BOOK_CURSOR_CACHE (object);

	if (cache_cursor->priv->book_cache) {
		if (cache_cursor->priv->cursor) {
			e_book_cache_cursor_free (cache_cursor->priv->book_cache, cache_cursor->priv->cursor);
			cache_cursor->priv->cursor = NULL;
		}

		g_clear_object (&cache_cursor->priv->book_cache);
	}

	/* Chain up to parent's method */
	G_OBJECT_CLASS (e_data_book_cursor_cache_parent_class)->dispose (object);
}

static void
e_data_book_cursor_cache_class_init (EDataBookCursorCacheClass *class)
{
	GObjectClass *object_class;
	EDataBookCursorClass *cursor_class;

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = e_data_book_cursor_cache_set_property;
	object_class->dispose = e_data_book_cursor_cache_dispose;

	cursor_class = E_DATA_BOOK_CURSOR_CLASS (class);
	cursor_class->set_sexp = edbcc_set_sexp;
	cursor_class->step = edbcc_step;
	cursor_class->set_alphabetic_index = edbcc_set_alphabetic_index;
	cursor_class->get_position = edbcc_get_position;
	cursor_class->compare_contact = edbcc_compare_contact;
	cursor_class->load_locale = edbcc_load_locale;

	g_object_class_install_property (
		object_class,
		PROP_BOOK_CACHE,
		g_param_spec_object (
			"book-cache",
			"Book Cache",
			"The EBookCache to use for queries",
			E_TYPE_BOOK_CACHE,
			G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (
		object_class,
		PROP_CURSOR,
		g_param_spec_pointer (
			"cursor",
			"Cursor",
			"The EBookCacheCursor pointer",
			G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

	g_type_class_add_private (class, sizeof (EDataBookCursorCachePrivate));
}

static void
e_data_book_cursor_cache_init (EDataBookCursorCache *cache_cursor)
{
	cache_cursor->priv = G_TYPE_INSTANCE_GET_PRIVATE (cache_cursor, E_TYPE_DATA_BOOK_CURSOR_CACHE, EDataBookCursorCachePrivate);
}

/**
 * e_data_book_cursor_cache_new:
 * @book_backend: the #EBookBackend creating this cursor
 * @book_cache: the #EBookCache object to base this cursor on
 * @sort_fields: (array length=n_fields): an array of #EContactFields as sort keys in order of priority
 * @sort_types: (array length=n_fields): an array of #EBookCursorSortTypes, one for each field in @sort_fields
 * @n_fields: the number of fields to sort results by.
 * @error: return location for a #GError, or %NULL
 *
 * Creates an #EDataBookCursor and implements all of the cursor methods
 * using the delegate @book_cache object.
 *
 * This is suitable cursor type for any backend which stores its contacts
 * using the #EBookCache object. The #EBookMetaBackend does that transparently.
 *
 * Returns: (transfer full): A newly created #EDataBookCursor, or %NULL if cursor creation failed.
 *
 * Since: 3.26
 */
EDataBookCursor *
e_data_book_cursor_cache_new (EBookBackend *book_backend,
			      EBookCache *book_cache,
			      const EContactField *sort_fields,
			      const EBookCursorSortType *sort_types,
			      guint n_fields,
			      GError **error)
{
	EDataBookCursor *cursor = NULL;
	EBookCacheCursor *cache_cursor;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_BACKEND (book_backend), NULL);
	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), NULL);

	cache_cursor = e_book_cache_cursor_new (
		book_cache, NULL,
		sort_fields,
		sort_types,
		n_fields,
		&local_error);

	if (cache_cursor) {
		cursor = g_object_new (E_TYPE_DATA_BOOK_CURSOR_CACHE,
			"book-cache", book_cache,
			"cursor", cache_cursor,
			NULL);

		/* Initially created cursors should have a position & total */
		if (!e_data_book_cursor_load_locale (E_DATA_BOOK_CURSOR (cursor), NULL, NULL, error))
			g_clear_object (&cursor);

	} else if (g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_INVALID_QUERY)) {
		g_set_error_literal (error, E_CLIENT_ERROR, E_CLIENT_ERROR_INVALID_QUERY, local_error->message);
		g_clear_error (&local_error);
	} else {
		g_propagate_error (error, local_error);
	}

	return cursor;
}
