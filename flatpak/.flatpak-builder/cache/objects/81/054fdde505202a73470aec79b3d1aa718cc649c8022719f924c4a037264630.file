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
 * SECTION: e-book-meta-backend
 * @include: libedata-book/libedata-book.h
 * @short_description: An #EBookBackend descendant for book backends
 *
 * The #EBookMetaBackend is an abstract #EBookBackend descendant which
 * aims to implement all evolution-data-server internals for the backend
 * itself and lefts the backend do as minimum work as possible, like
 * loading and saving contacts, listing available contacts and so on,
 * thus the backend implementation can focus on things like converting
 * (possibly) remote data into vCard objects and back.
 *
 * As the #EBookMetaBackend uses an #EBookCache, the offline support
 * is provided by default.
 *
 * The structure is thread safe.
 **/

#include "evolution-data-server-config.h"

#include <glib.h>
#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include "e-book-backend-sexp.h"
#include "e-book-backend.h"
#include "e-data-book-cursor-cache.h"
#include "e-data-book-factory.h"

#include "e-book-meta-backend.h"

#define EBMB_KEY_SYNC_TAG		"ebmb::sync-tag"
#define EBMB_KEY_EVER_CONNECTED		"ebmb::ever-connected"
#define EBMB_KEY_CONNECTED_WRITABLE	"ebmb::connected-writable"

#define LOCAL_PREFIX "file://"

/* How many times can repeat an operation when credentials fail. */
#define MAX_REPEAT_COUNT 3

/* How long to wait for credentials, in seconds, during the operation repeat cycle */
#define MAX_WAIT_FOR_CREDENTIALS_SECS 60

struct _EBookMetaBackendPrivate {
	GMutex connect_lock;
	GMutex property_lock;
	GMutex wait_credentials_lock;
	GCond wait_credentials_cond;
	guint wait_credentials_stamp;
	GError *create_cache_error;
	EBookCache *cache;
	ENamedParameters *last_credentials;
	GHashTable *view_cancellables;
	GCancellable *refresh_cancellable;	/* Set when refreshing the content */
	GCancellable *source_changed_cancellable; /* Set when processing source changed signal */
	GCancellable *go_offline_cancellable;	/* Set when going offline */
	gboolean current_online_state;		/* The only state of the internal structures;
						   used to detect false notifications on EBackend::online */
	gulong source_changed_id;
	gulong notify_online_id;
	gulong revision_changed_id;
	guint refresh_timeout_id;

	gboolean refresh_after_authenticate;
	gint ever_connected;
	gint connected_writable;

	/* Last successful connect data, for some extensions */
	guint16 authentication_port;
	gchar *authentication_host;
	gchar *authentication_user;
	gchar *authentication_method;
	gchar *authentication_proxy_uid;
	gchar *authentication_credential_name;
	SoupURI *webdav_soup_uri;

	GSList *cursors;
};

enum {
	PROP_0,
	PROP_CACHE
};

enum {
	REFRESH_COMPLETED,
	SOURCE_CHANGED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_ABSTRACT_TYPE (EBookMetaBackend, e_book_meta_backend, E_TYPE_BOOK_BACKEND)

G_DEFINE_BOXED_TYPE (EBookMetaBackendInfo, e_book_meta_backend_info, e_book_meta_backend_info_copy, e_book_meta_backend_info_free)

static void ebmb_schedule_source_changed (EBookMetaBackend *meta_backend);
static void ebmb_schedule_go_offline (EBookMetaBackend *meta_backend);
static gboolean ebmb_save_contact_wrapper_sync (EBookMetaBackend *meta_backend,
						EBookCache *book_cache,
						gboolean overwrite_existing,
						EConflictResolution conflict_resolution,
						/* const */ EContact *in_contact,
						const gchar *extra,
						const gchar *orig_uid,
						gboolean *out_requires_put,
						gchar **out_new_uid,
						gchar **out_new_extra,
						GCancellable *cancellable,
						GError **error);

/**
 * e_book_meta_backend_info_new:
 * @uid: a contact UID; cannot be %NULL
 * @revision: (nullable): the contact revision; can be %NULL
 * @object: (nullable): the contact object as a vCard string; can be %NULL
 * @extra: (nullable): extra backend-specific data; can be %NULL
 *
 * Creates a new #EBookMetaBackendInfo prefilled with the given values.
 *
 * Returns: (transfer full): A new #EBookMetaBackendInfo. Free it with
 *    e_book_meta_backend_info_free(), when no longer needed.
 *
 * Since: 3.26
 **/
EBookMetaBackendInfo *
e_book_meta_backend_info_new (const gchar *uid,
			      const gchar *revision,
			      const gchar *object,
			      const gchar *extra)
{
	EBookMetaBackendInfo *info;

	g_return_val_if_fail (uid != NULL, NULL);

	info = g_new0 (EBookMetaBackendInfo, 1);
	info->uid = g_strdup (uid);
	info->revision = g_strdup (revision);
	info->object = g_strdup (object);
	info->extra = g_strdup (extra);

	return info;
}

/**
 * e_book_meta_backend_info_copy:
 * @src: (nullable): a source EBookMetaBackendInfo to copy, or %NULL
 *
 * Returns: (transfer full): Copy of the given @src. Free it with
 *    e_book_meta_backend_info_free() when no longer needed.
 *    If the @src is %NULL, then returns %NULL as well.
 *
 * Since: 3.26
 **/
EBookMetaBackendInfo *
e_book_meta_backend_info_copy (const EBookMetaBackendInfo *src)
{
	if (!src)
		return NULL;

	return e_book_meta_backend_info_new (src->uid, src->revision, src->object, src->extra);
}

/**
 * e_book_meta_backend_info_free:
 * @ptr: (nullable): an #EBookMetaBackendInfo
 *
 * Frees the @ptr structure, previously allocated with e_book_meta_backend_info_new()
 * or e_book_meta_backend_info_copy().
 *
 * Since: 3.26
 **/
void
e_book_meta_backend_info_free (gpointer ptr)
{
	EBookMetaBackendInfo *info = ptr;

	if (info) {
		g_free (info->uid);
		g_free (info->revision);
		g_free (info->object);
		g_free (info->extra);
		g_free (info);
	}
}

/* Unref returned cancellable with g_object_unref(), when done with it */
static GCancellable *
ebmb_create_view_cancellable (EBookMetaBackend *meta_backend,
			      EDataBookView *view)
{
	GCancellable *cancellable;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), NULL);
	g_return_val_if_fail (E_IS_DATA_BOOK_VIEW (view), NULL);

	g_mutex_lock (&meta_backend->priv->property_lock);

	cancellable = g_cancellable_new ();
	g_hash_table_insert (meta_backend->priv->view_cancellables, view, g_object_ref (cancellable));

	g_mutex_unlock (&meta_backend->priv->property_lock);

	return cancellable;
}

static GCancellable *
ebmb_steal_view_cancellable (EBookMetaBackend *meta_backend,
			     EDataBookView *view)
{
	GCancellable *cancellable;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), NULL);
	g_return_val_if_fail (E_IS_DATA_BOOK_VIEW (view), NULL);

	g_mutex_lock (&meta_backend->priv->property_lock);

	cancellable = g_hash_table_lookup (meta_backend->priv->view_cancellables, view);
	if (cancellable) {
		g_object_ref (cancellable);
		g_hash_table_remove (meta_backend->priv->view_cancellables, view);
	}

	g_mutex_unlock (&meta_backend->priv->property_lock);

	return cancellable;
}

static void
ebmb_update_connection_values (EBookMetaBackend *meta_backend)
{
	ESource *source;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (meta_backend));

	source = e_backend_get_source (E_BACKEND (meta_backend));

	g_mutex_lock (&meta_backend->priv->property_lock);

	meta_backend->priv->authentication_port = 0;
	g_clear_pointer (&meta_backend->priv->authentication_host, g_free);
	g_clear_pointer (&meta_backend->priv->authentication_user, g_free);
	g_clear_pointer (&meta_backend->priv->authentication_method, g_free);
	g_clear_pointer (&meta_backend->priv->authentication_proxy_uid, g_free);
	g_clear_pointer (&meta_backend->priv->authentication_credential_name, g_free);
	g_clear_pointer (&meta_backend->priv->webdav_soup_uri, (GDestroyNotify) soup_uri_free);

	if (source && e_source_has_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
		ESourceAuthentication *auth_extension;

		auth_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);

		meta_backend->priv->authentication_port = e_source_authentication_get_port (auth_extension);
		meta_backend->priv->authentication_host = e_source_authentication_dup_host (auth_extension);
		meta_backend->priv->authentication_user = e_source_authentication_dup_user (auth_extension);
		meta_backend->priv->authentication_method = e_source_authentication_dup_method (auth_extension);
		meta_backend->priv->authentication_proxy_uid = e_source_authentication_dup_proxy_uid (auth_extension);
		meta_backend->priv->authentication_credential_name = e_source_authentication_dup_credential_name (auth_extension);
	}

	if (source && e_source_has_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND)) {
		ESourceWebdav *webdav_extension;

		webdav_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);

		meta_backend->priv->webdav_soup_uri = e_source_webdav_dup_soup_uri (webdav_extension);
	}

	g_mutex_unlock (&meta_backend->priv->property_lock);

	e_book_meta_backend_set_ever_connected (meta_backend, TRUE);
	e_book_meta_backend_set_connected_writable (meta_backend, e_book_backend_get_writable (E_BOOK_BACKEND (meta_backend)));
}

static gboolean
ebmb_gather_locally_cached_objects_cb (EBookCache *book_cache,
				       const gchar *uid,
				       const gchar *revision,
				       const gchar *object,
				       const gchar *extra,
				       EOfflineState offline_state,
				       gpointer user_data)
{
	GHashTable *locally_cached = user_data;

	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (locally_cached != NULL, FALSE);

	if (offline_state == E_OFFLINE_STATE_SYNCED) {
		g_hash_table_insert (locally_cached,
			g_strdup (uid),
			g_strdup (revision));
	}

	return TRUE;
}

static gboolean
ebmb_get_changes_sync (EBookMetaBackend *meta_backend,
		       const gchar *last_sync_tag,
		       gboolean is_repeat,
		       gchar **out_new_sync_tag,
		       gboolean *out_repeat,
		       GSList **out_created_objects,
		       GSList **out_modified_objects,
		       GSList **out_removed_objects,
		       GCancellable *cancellable,
		       GError **error)
{
	GSList *existing_objects = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_created_objects, FALSE);
	g_return_val_if_fail (out_modified_objects, FALSE);
	g_return_val_if_fail (out_removed_objects, FALSE);

	*out_created_objects = NULL;
	*out_modified_objects = NULL;
	*out_removed_objects = NULL;

	if (!e_backend_get_online (E_BACKEND (meta_backend)))
		return TRUE;

	if (!e_book_meta_backend_ensure_connected_sync (meta_backend, cancellable, error) ||
	    !e_book_meta_backend_list_existing_sync (meta_backend, out_new_sync_tag, &existing_objects, cancellable, error)) {
		return FALSE;
	}

	success = e_book_meta_backend_split_changes_sync (meta_backend, existing_objects, out_created_objects,
		out_modified_objects, out_removed_objects, cancellable, error);

	g_slist_free_full (existing_objects, e_book_meta_backend_info_free);

	return success;
}

static gboolean
ebmb_search_sync (EBookMetaBackend *meta_backend,
		  const gchar *expr,
		  gboolean meta_contact,
		  GSList **out_contacts,
		  GCancellable *cancellable,
		  GError **error)
{
	EBookCache *book_cache;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_contacts != NULL, FALSE);

	*out_contacts = NULL;
	book_cache = e_book_meta_backend_ref_cache (meta_backend);

	g_return_val_if_fail (book_cache != NULL, FALSE);

	success = e_book_cache_search (book_cache, expr, meta_contact, out_contacts, cancellable, error);

	if (success) {
		GSList *link;

		for (link = *out_contacts; link; link = g_slist_next (link)) {
			EBookCacheSearchData *search_data = link->data;
			EContact *contact = NULL;

			if (search_data) {
				contact = e_contact_new_from_vcard_with_uid (search_data->vcard, search_data->uid);
				e_book_cache_search_data_free (search_data);
			}

			link->data = contact;
		}
	}

	g_object_unref (book_cache);

	return success;
}

static gboolean
ebmb_search_uids_sync (EBookMetaBackend *meta_backend,
		       const gchar *expr,
		       GSList **out_uids,
		       GCancellable *cancellable,
		       GError **error)
{
	EBookCache *book_cache;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_uids != NULL, FALSE);

	*out_uids = NULL;

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, FALSE);

	success = e_book_cache_search_uids (book_cache, expr, out_uids, cancellable, error);

	g_object_unref (book_cache);

	return success;
}

static gboolean
ebmb_requires_reconnect (EBookMetaBackend *meta_backend)
{
	ESource *source;
	gboolean requires = FALSE;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	source = e_backend_get_source (E_BACKEND (meta_backend));
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
		ESourceAuthentication *auth_extension;

		auth_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);

		e_source_extension_property_lock (E_SOURCE_EXTENSION (auth_extension));

		requires = meta_backend->priv->authentication_port != e_source_authentication_get_port (auth_extension) ||
			g_strcmp0 (meta_backend->priv->authentication_host, e_source_authentication_get_host (auth_extension)) != 0 ||
			g_strcmp0 (meta_backend->priv->authentication_user, e_source_authentication_get_user (auth_extension)) != 0 ||
			g_strcmp0 (meta_backend->priv->authentication_method, e_source_authentication_get_method (auth_extension)) != 0 ||
			g_strcmp0 (meta_backend->priv->authentication_proxy_uid, e_source_authentication_get_proxy_uid (auth_extension)) != 0 ||
			g_strcmp0 (meta_backend->priv->authentication_credential_name, e_source_authentication_get_credential_name (auth_extension)) != 0;

		e_source_extension_property_unlock (E_SOURCE_EXTENSION (auth_extension));
	}

	if (!requires && e_source_has_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND)) {
		ESourceWebdav *webdav_extension;
		SoupURI *soup_uri;

		webdav_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
		soup_uri = e_source_webdav_dup_soup_uri (webdav_extension);

		requires = (!meta_backend->priv->webdav_soup_uri && soup_uri) ||
			(soup_uri && meta_backend->priv->webdav_soup_uri &&
			!soup_uri_equal (meta_backend->priv->webdav_soup_uri, soup_uri));

		if (soup_uri)
			soup_uri_free (soup_uri);
	}

	g_mutex_unlock (&meta_backend->priv->property_lock);

	return requires;
}

static gboolean
ebmb_get_ssl_error_details (EBookMetaBackend *meta_backend,
			    gchar **out_certificate_pem,
			    GTlsCertificateFlags *out_certificate_errors)
{
	return FALSE;
}

static GSList * /* gchar * */
ebmb_gather_photos_local_filenames (EBookMetaBackend *meta_backend,
				    EContact *contact)
{
	EBookCache *book_cache;
	GList *attributes, *link;
	GSList *filenames = NULL;
	gchar *cache_path;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), NULL);
	g_return_val_if_fail (E_IS_CONTACT (contact), NULL);

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, NULL);

	cache_path = g_path_get_dirname (e_cache_get_filename (E_CACHE (book_cache)));

	g_object_unref (book_cache);

	attributes = e_vcard_get_attributes (E_VCARD (contact));

	for (link = attributes; link; link = g_list_next (link)) {
		EVCardAttribute *attr = link->data;
		const gchar *attr_name;
		GList *values;

		attr_name = e_vcard_attribute_get_name (attr);
		if (!attr_name || (
		    g_ascii_strcasecmp (attr_name, EVC_PHOTO) != 0 &&
		    g_ascii_strcasecmp (attr_name, EVC_LOGO) != 0)) {
			continue;
		}

		values = e_vcard_attribute_get_param (attr, EVC_VALUE);
		if (values && g_ascii_strcasecmp (values->data, "uri") == 0) {
			const gchar *url;

			url = e_vcard_attribute_get_value (attr);
			if (url && g_str_has_prefix (url, LOCAL_PREFIX)) {
				gchar *filename;

				filename = g_filename_from_uri (url, NULL, NULL);
				if (filename && g_str_has_prefix (filename, cache_path))
					filenames = g_slist_prepend (filenames, filename);
				else
					g_free (filename);
			}
		}
	}

	g_free (cache_path);

	return filenames;
}

static void
ebmb_start_view_thread_func (EBookBackend *book_backend,
			     gpointer user_data,
			     GCancellable *cancellable,
			     GError **error)
{
	EDataBookView *view = user_data;
	EBookBackendSExp *sexp;
	GSList *contacts = NULL;
	const gchar *expr = NULL;
	gboolean meta_contact = FALSE;
	GHashTable *fields_of_interest;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (book_backend));
	g_return_if_fail (E_IS_DATA_BOOK_VIEW (view));

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return;

	/* Fill the view with known (locally stored) contacts satisfying the expression */
	sexp = e_data_book_view_get_sexp (view);
	if (sexp)
		expr = e_book_backend_sexp_text (sexp);

	fields_of_interest = e_data_book_view_get_fields_of_interest (view);
	if (fields_of_interest && g_hash_table_size (fields_of_interest) == 2) {
		GHashTableIter iter;
		gpointer key, value;

		meta_contact = TRUE;

		g_hash_table_iter_init (&iter, fields_of_interest);
		while (g_hash_table_iter_next (&iter, &key, &value)) {
			const gchar *field_name = key;
			EContactField field = e_contact_field_id (field_name);

			if (field != E_CONTACT_UID &&
			    field != E_CONTACT_REV) {
				meta_contact = FALSE;
				break;
			}
		}
	}

	if (e_book_meta_backend_search_sync (E_BOOK_META_BACKEND (book_backend), expr, meta_contact, &contacts, cancellable, &local_error) && contacts) {
		if (!g_cancellable_is_cancelled (cancellable)) {
			GSList *link;

			for (link = contacts; link; link = g_slist_next (link)) {
				EContact *contact = link->data;
				gchar *vcard;

				if (!contact)
					continue;

				vcard = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);
				e_data_book_view_notify_update_prefiltered_vcard (view,
					e_contact_get_const (contact, E_CONTACT_UID),
					vcard);

				g_free (vcard);
			}
		}

		g_slist_free_full (contacts, g_object_unref);
	}

	e_data_book_view_notify_complete (view, local_error);

	g_clear_error (&local_error);
}

static gboolean
ebmb_upload_local_changes_sync (EBookMetaBackend *meta_backend,
				EBookCache *book_cache,
				EConflictResolution conflict_resolution,
				GCancellable *cancellable,
				GError **error)
{
	GSList *offline_changes, *link;
	GHashTable *covered_uids;
	ECache *cache;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (E_IS_BOOK_CACHE (book_cache), FALSE);

	cache = E_CACHE (book_cache);
	covered_uids = g_hash_table_new (g_str_hash, g_str_equal);

	offline_changes = e_cache_get_offline_changes (cache, cancellable, error);
	for (link = offline_changes; link && success; link = g_slist_next (link)) {
		ECacheOfflineChange *change = link->data;
		gchar *extra = NULL;

		success = !g_cancellable_set_error_if_cancelled (cancellable, error);
		if (!success)
			break;

		if (!change || g_hash_table_contains (covered_uids, change->uid))
			continue;

		g_hash_table_insert (covered_uids, change->uid, NULL);

		if (!e_book_cache_get_contact_extra (book_cache, change->uid, &extra, cancellable, NULL))
			extra = NULL;

		if (change->state == E_OFFLINE_STATE_LOCALLY_CREATED ||
		    change->state == E_OFFLINE_STATE_LOCALLY_MODIFIED) {
			EContact *contact = NULL;

			success = e_book_cache_get_contact (book_cache, change->uid, FALSE, &contact, cancellable, error);
			if (success) {
				success = ebmb_save_contact_wrapper_sync (meta_backend, book_cache,
					change->state == E_OFFLINE_STATE_LOCALLY_MODIFIED,
					conflict_resolution, contact, extra, change->uid, NULL, NULL, NULL, cancellable, error);
			}

			g_clear_object (&contact);
		} else if (change->state == E_OFFLINE_STATE_LOCALLY_DELETED) {
			GError *local_error = NULL;

			success = e_book_meta_backend_remove_contact_sync (meta_backend, conflict_resolution,
				change->uid, extra, change->object, cancellable, &local_error);

			if (!success) {
				if (g_error_matches (local_error, E_DATA_BOOK_ERROR, E_DATA_BOOK_STATUS_CONTACT_NOT_FOUND)) {
					g_clear_error (&local_error);
					success = TRUE;
				} else if (local_error) {
					g_propagate_error (error, local_error);
				}
			}
		} else {
			g_warn_if_reached ();
		}

		g_free (extra);
	}

	g_slist_free_full (offline_changes, e_cache_offline_change_free);
	g_hash_table_destroy (covered_uids);

	if (success)
		success = e_cache_clear_offline_changes (cache, cancellable, error);

	return success;
}

static void
ebmb_foreach_cursor (EBookMetaBackend *meta_backend,
		     EContact *contact,
		     void (* func) (EDataBookCursor *cursor, EContact *contact))
{
	GSList *link;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (meta_backend));
	g_return_if_fail (func != NULL);

	g_mutex_lock (&meta_backend->priv->property_lock);

	for (link = meta_backend->priv->cursors; link; link = g_slist_next (link)) {
		EDataBookCursor *cursor = link->data;

		func (cursor, contact);
	}

	g_mutex_unlock (&meta_backend->priv->property_lock);
}

static gboolean
ebmb_maybe_remove_from_cache (EBookMetaBackend *meta_backend,
			      EBookCache *book_cache,
			      ECacheOfflineFlag offline_flag,
			      const gchar *uid,
			      GCancellable *cancellable,
			      GError **error)
{
	EBookBackend *book_backend;
	EContact *contact = NULL;
	GSList *local_photos, *link;
	GError *local_error = NULL;

	g_return_val_if_fail (uid != NULL, FALSE);

	if (!e_book_cache_get_contact (book_cache, uid, FALSE, &contact, cancellable, &local_error)) {
		if (g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND)) {
			g_clear_error (&local_error);
			return TRUE;
		}

		g_propagate_error (error, local_error);
		return FALSE;
	}

	book_backend = E_BOOK_BACKEND (meta_backend);

	if (!e_book_cache_remove_contact (book_cache, uid, offline_flag, cancellable, error)) {
		g_object_unref (contact);
		return FALSE;
	}

	local_photos = ebmb_gather_photos_local_filenames (meta_backend, contact);
	for (link = local_photos; link; link = g_slist_next (link)) {
		const gchar *filename = link->data;

		if (filename && g_unlink (filename) == -1) {
			/* Ignore these errors */
		}
	}

	g_slist_free_full (local_photos, g_free);

	e_book_backend_notify_remove (book_backend, uid);

	ebmb_foreach_cursor (meta_backend, contact, e_data_book_cursor_contact_removed);

	g_object_unref (contact);

	return TRUE;
}

static gboolean
ebmb_refresh_internal_sync (EBookMetaBackend *meta_backend,
			    gboolean with_connection_error,
			    GCancellable *cancellable,
			    GError **error)
{
	EBookCache *book_cache;
	gboolean success = FALSE, repeat = TRUE, is_repeat = FALSE;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		goto done;

	if (!e_backend_get_online (E_BACKEND (meta_backend)) ||
	    !e_book_meta_backend_ensure_connected_sync (meta_backend, cancellable, with_connection_error ? error : NULL) ||
	    !e_backend_get_online (E_BACKEND (meta_backend))) { /* Failed connecting moves backend to offline */
		g_mutex_lock (&meta_backend->priv->property_lock);
		meta_backend->priv->refresh_after_authenticate = TRUE;
		g_mutex_unlock (&meta_backend->priv->property_lock);
		goto done;
	}

	g_mutex_lock (&meta_backend->priv->property_lock);
	meta_backend->priv->refresh_after_authenticate = FALSE;
	g_mutex_unlock (&meta_backend->priv->property_lock);

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	if (!book_cache) {
		g_warn_if_reached ();
		goto done;
	}

	if (with_connection_error) {
		/* Skip upload when not initiated by the user (as part of the Refresh operation) */
		success = TRUE;
	} else {
		GError *local_error = NULL;

		success = ebmb_upload_local_changes_sync (meta_backend, book_cache, E_CONFLICT_RESOLUTION_FAIL, cancellable, &local_error);

		if (local_error) {
			if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_HOST_NOT_FOUND))
				e_backend_set_online (E_BACKEND (meta_backend), FALSE);

			g_propagate_error (error, local_error);
			success = FALSE;
		}
	}

	while (repeat && success &&
	       !g_cancellable_set_error_if_cancelled (cancellable, error)) {
		GSList *created_objects = NULL, *modified_objects = NULL, *removed_objects = NULL;
		gchar *last_sync_tag, *new_sync_tag = NULL;
		GError *local_error = NULL;

		repeat = FALSE;

		last_sync_tag = e_cache_dup_key (E_CACHE (book_cache), EBMB_KEY_SYNC_TAG, NULL);
		if (last_sync_tag && !*last_sync_tag) {
			g_free (last_sync_tag);
			last_sync_tag = NULL;
		}

		success = e_book_meta_backend_get_changes_sync (meta_backend, last_sync_tag, is_repeat, &new_sync_tag, &repeat,
			&created_objects, &modified_objects, &removed_objects, cancellable, &local_error);

		if (local_error) {
			if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_HOST_NOT_FOUND))
				e_backend_set_online (E_BACKEND (meta_backend), FALSE);

			g_propagate_error (error, local_error);
			local_error = NULL;
			success = FALSE;
		}

		if (success) {
			success = e_book_meta_backend_process_changes_sync (meta_backend, created_objects, modified_objects,
				removed_objects, cancellable, error);
		}

		if (success && new_sync_tag)
			e_cache_set_key (E_CACHE (book_cache), EBMB_KEY_SYNC_TAG, new_sync_tag, NULL);

		g_slist_free_full (created_objects, e_book_meta_backend_info_free);
		g_slist_free_full (modified_objects, e_book_meta_backend_info_free);
		g_slist_free_full (removed_objects, e_book_meta_backend_info_free);
		g_free (last_sync_tag);
		g_free (new_sync_tag);

		is_repeat = TRUE;
	}

	g_object_unref (book_cache);

 done:
	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->refresh_cancellable == cancellable)
		g_clear_object (&meta_backend->priv->refresh_cancellable);

	g_mutex_unlock (&meta_backend->priv->property_lock);

	g_signal_emit (meta_backend, signals[REFRESH_COMPLETED], 0, NULL);

	return success;
}

static void
ebmb_refresh_thread_func (EBookBackend *book_backend,
			  gpointer user_data,
			  GCancellable *cancellable,
			  GError **error)
{
	EBookMetaBackend *meta_backend;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (book_backend));

	meta_backend = E_BOOK_META_BACKEND (book_backend);

	ebmb_refresh_internal_sync (meta_backend, FALSE, cancellable, error);
}

static void
ebmb_source_refresh_timeout_cb (ESource *source,
				gpointer user_data)
{
	GWeakRef *weak_ref = user_data;
	EBookMetaBackend *meta_backend;

	g_return_if_fail (weak_ref != NULL);

	meta_backend = g_weak_ref_get (weak_ref);
	if (meta_backend) {
		e_book_meta_backend_schedule_refresh (meta_backend);
		g_object_unref (meta_backend);
	}
}

static void
ebmb_source_changed_thread_func (EBookBackend *book_backend,
				 gpointer user_data,
				 GCancellable *cancellable,
				 GError **error)
{
	EBookMetaBackend *meta_backend;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (book_backend));

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return;

	meta_backend = E_BOOK_META_BACKEND (book_backend);

	g_mutex_lock (&meta_backend->priv->property_lock);
	if (!meta_backend->priv->refresh_timeout_id) {
		ESource *source = e_backend_get_source (E_BACKEND (meta_backend));

		if (e_source_has_extension (source, E_SOURCE_EXTENSION_REFRESH)) {
			meta_backend->priv->refresh_timeout_id = e_source_refresh_add_timeout (source, NULL,
				ebmb_source_refresh_timeout_cb, e_weak_ref_new (meta_backend), (GDestroyNotify) e_weak_ref_free);
		}
	}
	g_mutex_unlock (&meta_backend->priv->property_lock);

	g_signal_emit (meta_backend, signals[SOURCE_CHANGED], 0, NULL);

	if (e_backend_get_online (E_BACKEND (meta_backend)) &&
	    e_book_meta_backend_requires_reconnect (meta_backend)) {
		gboolean can_refresh;

		g_mutex_lock (&meta_backend->priv->connect_lock);
		can_refresh = e_book_meta_backend_disconnect_sync (meta_backend, cancellable, error);
		g_mutex_unlock (&meta_backend->priv->connect_lock);

		if (can_refresh)
			e_book_meta_backend_schedule_refresh (meta_backend);
	}

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->source_changed_cancellable == cancellable)
		g_clear_object (&meta_backend->priv->source_changed_cancellable);

	g_mutex_unlock (&meta_backend->priv->property_lock);
}

static void
ebmb_go_offline_thread_func (EBookBackend *book_backend,
			     gpointer user_data,
			     GCancellable *cancellable,
			     GError **error)
{
	EBookMetaBackend *meta_backend;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (book_backend));

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return;

	meta_backend = E_BOOK_META_BACKEND (book_backend);

	g_mutex_lock (&meta_backend->priv->connect_lock);
	e_book_meta_backend_disconnect_sync (meta_backend, cancellable, error);
	g_mutex_unlock (&meta_backend->priv->connect_lock);

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->go_offline_cancellable == cancellable)
		g_clear_object (&meta_backend->priv->go_offline_cancellable);

	g_mutex_unlock (&meta_backend->priv->property_lock);
}

static gboolean
ebmb_put_contact (EBookMetaBackend *meta_backend,
		  EBookCache *book_cache,
		  ECacheOfflineFlag offline_flag,
		  EContact *contact,
		  const gchar *extra,
		  GCancellable *cancellable,
		  GError **error)
{
	EContact *existing_contact = NULL;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	success = e_book_meta_backend_store_inline_photos_sync (meta_backend, contact, cancellable, error);

	if (success && e_book_cache_get_contact (book_cache,
		e_contact_get_const (contact, E_CONTACT_UID), FALSE, &existing_contact, cancellable, NULL)) {
		GSList *old_photos, *new_photos, *link;

		old_photos = ebmb_gather_photos_local_filenames (meta_backend, existing_contact);
		if (old_photos) {
			GHashTable *photos_hash;

			photos_hash = g_hash_table_new (g_str_hash, g_str_equal);

			new_photos = ebmb_gather_photos_local_filenames (meta_backend, contact);

			for (link = new_photos; link; link = g_slist_next (link)) {
				const gchar *filename = link->data;

				if (filename)
					g_hash_table_insert (photos_hash, (gpointer) filename, NULL);
			}

			for (link = old_photos; link; link = g_slist_next (link)) {
				const gchar *filename = link->data;

				if (filename && !g_hash_table_contains (photos_hash, filename)) {
					if (g_unlink (filename) == -1) {
						/* Ignore these errors */
					}
				}
			}

			g_slist_free_full (old_photos, g_free);
			g_slist_free_full (new_photos, g_free);
			g_hash_table_destroy (photos_hash);
		}
	}

	success = success && e_book_cache_put_contact (book_cache, contact, extra, offline_flag, cancellable, error);

	if (success)
		e_book_backend_notify_update (E_BOOK_BACKEND (meta_backend), contact);

	g_clear_object (&existing_contact);

	return success;
}

static gboolean
ebmb_load_contact_wrapper_sync (EBookMetaBackend *meta_backend,
				EBookCache *book_cache,
				const gchar *uid,
				const gchar *preloaded_object,
				const gchar *preloaded_extra,
				gchar **out_new_uid,
				GCancellable *cancellable,
				GError **error)
{
	ECacheOfflineFlag offline_flag = E_CACHE_IS_ONLINE;
	EContact *contact = NULL;
	gchar *extra = NULL;
	gboolean success = TRUE;
	GError *local_error = NULL;

	if (preloaded_object && *preloaded_object) {
		contact = e_contact_new_from_vcard_with_uid (preloaded_object, uid);
		if (!contact) {
			g_propagate_error (error, e_data_book_create_error_fmt (E_DATA_BOOK_STATUS_INVALID_ARG, _("Preloaded object for UID “%s” is invalid"), uid));
			return FALSE;
		}
	} else if (!e_book_meta_backend_ensure_connected_sync (meta_backend, cancellable, error) ||
		!e_book_meta_backend_load_contact_sync (meta_backend, uid, preloaded_extra, &contact, &extra, cancellable, error)) {
		g_free (extra);
		return FALSE;
	} else if (!contact) {
		g_propagate_error (error, e_data_book_create_error_fmt (E_DATA_BOOK_STATUS_INVALID_ARG, _("Received object for UID “%s” is invalid"), uid));
		g_free (extra);
		return FALSE;
	}

	success = ebmb_put_contact (meta_backend, book_cache, offline_flag,
		contact, extra ? extra : preloaded_extra, cancellable, &local_error);

	if (success && out_new_uid)
		*out_new_uid = e_contact_get (contact, E_CONTACT_UID);

	g_object_unref (contact);
	g_free (extra);

	if (local_error) {
		if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_HOST_NOT_FOUND))
			e_backend_set_online (E_BACKEND (meta_backend), FALSE);

		g_propagate_error (error, local_error);
		success = FALSE;
	}

	return success;
}

static gboolean
ebmb_save_contact_wrapper_sync (EBookMetaBackend *meta_backend,
				EBookCache *book_cache,
				gboolean overwrite_existing,
				EConflictResolution conflict_resolution,
				/* const */ EContact *in_contact,
				const gchar *extra,
				const gchar *orig_uid,
				gboolean *out_requires_put,
				gchar **out_new_uid,
				gchar **out_new_extra,
				GCancellable *cancellable,
				GError **error)
{
	EContact *contact;
	gchar *new_uid = NULL, *new_extra = NULL;
	gboolean success = TRUE;
	GError *local_error = NULL;

	if (out_requires_put)
		*out_requires_put = TRUE;

	if (out_new_uid)
		*out_new_uid = NULL;

	contact = e_contact_duplicate (in_contact);

	success = e_book_meta_backend_inline_local_photos_sync (meta_backend, contact, cancellable, error);

	success = success && e_book_meta_backend_save_contact_sync (meta_backend, overwrite_existing, conflict_resolution,
		contact, extra, &new_uid, &new_extra, cancellable, &local_error);

	if (success && new_uid && *new_uid) {
		gchar *loaded_uid = NULL;

		success = ebmb_load_contact_wrapper_sync (meta_backend, book_cache, new_uid, NULL,
			new_extra ? new_extra : extra, &loaded_uid, cancellable, error);

		if (success && g_strcmp0 (loaded_uid, orig_uid) != 0)
			success = ebmb_maybe_remove_from_cache (meta_backend, book_cache, E_CACHE_IS_ONLINE, orig_uid, cancellable, error);

		if (success && out_new_uid)
			*out_new_uid = loaded_uid;
		else
			g_free (loaded_uid);

		if (out_requires_put)
			*out_requires_put = FALSE;
	}

	g_free (new_uid);

	if (success && out_new_extra)
		*out_new_extra = new_extra;
	else
		g_free (new_extra);
	g_object_unref (contact);

	if (local_error) {
		if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_HOST_NOT_FOUND))
			e_backend_set_online (E_BACKEND (meta_backend), FALSE);

		g_propagate_error (error, local_error);
		success = FALSE;
	}

	return success;
}

static gchar *
ebmb_get_backend_property (EBookBackend *book_backend,
			   const gchar *prop_name)
{
	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), NULL);
	g_return_val_if_fail (prop_name != NULL, NULL);

	if (g_str_equal (prop_name, BOOK_BACKEND_PROPERTY_REVISION)) {
		EBookCache *book_cache;
		gchar *revision = NULL;

		book_cache = e_book_meta_backend_ref_cache (E_BOOK_META_BACKEND (book_backend));
		if (book_cache) {
			revision = e_cache_dup_revision (E_CACHE (book_cache));
			g_object_unref (book_cache);
		} else {
			g_warn_if_reached ();
		}

		return revision;
	} else if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_CAPABILITIES)) {
		return g_strdup (e_book_meta_backend_get_capabilities (E_BOOK_META_BACKEND (book_backend)));
	} else  if (g_str_equal (prop_name, BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS)) {
		return g_strdup (e_contact_field_name (E_CONTACT_FILE_AS));
	} else if (g_str_equal (prop_name, BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS)) {
		GString *fields;
		gint ii;

		fields = g_string_sized_new (1024);

		/* Claim to support everything by default */
		for (ii = 1; ii < E_CONTACT_FIELD_LAST; ii++) {
			if (fields->len > 0)
				g_string_append_c (fields, ',');
			g_string_append (fields, e_contact_field_name (ii));
		}

		return g_string_free (fields, FALSE);
	}

	/* Chain up to parent's method. */
	return E_BOOK_BACKEND_CLASS (e_book_meta_backend_parent_class)->get_backend_property (book_backend, prop_name);
}

static gboolean
ebmb_open_sync (EBookBackend *book_backend,
		GCancellable *cancellable,
		GError **error)
{
	EBookMetaBackend *meta_backend;
	ESource *source;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), FALSE);

	if (e_book_backend_is_opened (book_backend))
		return TRUE;

	meta_backend = E_BOOK_META_BACKEND (book_backend);
	if (meta_backend->priv->create_cache_error) {
		g_propagate_error (error, meta_backend->priv->create_cache_error);
		meta_backend->priv->create_cache_error = NULL;
		return FALSE;
	}

	source = e_backend_get_source (E_BACKEND (book_backend));

	if (!meta_backend->priv->source_changed_id) {
		meta_backend->priv->source_changed_id = g_signal_connect_swapped (source, "changed",
			G_CALLBACK (ebmb_schedule_source_changed), meta_backend);
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND)) {
		ESourceWebdav *webdav_extension;

		webdav_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
		e_source_webdav_unset_temporary_ssl_trust (webdav_extension);
	}

	if (e_book_meta_backend_get_ever_connected (meta_backend)) {
		e_book_backend_set_writable (E_BOOK_BACKEND (meta_backend),
			e_book_meta_backend_get_connected_writable (meta_backend));
	} else {
		if (!e_book_meta_backend_ensure_connected_sync (meta_backend, cancellable, error)) {
			g_mutex_lock (&meta_backend->priv->property_lock);
			meta_backend->priv->refresh_after_authenticate = TRUE;
			g_mutex_unlock (&meta_backend->priv->property_lock);

			return FALSE;
		}
	}

	e_book_meta_backend_schedule_refresh (E_BOOK_META_BACKEND (book_backend));

	return TRUE;
}

static gboolean
ebmb_refresh_sync (EBookBackend *book_backend,
		   GCancellable *cancellable,
		   GError **error)
{
	EBookMetaBackend *meta_backend;
	EBackend *backend;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), FALSE);

	meta_backend = E_BOOK_META_BACKEND (book_backend);
	backend = E_BACKEND (meta_backend);

	if (!e_backend_get_online (backend) &&
	    e_backend_is_destination_reachable (backend, cancellable, NULL))
		e_backend_set_online (backend, TRUE);

	if (!e_backend_get_online (backend))
		return TRUE;

	success = e_book_meta_backend_ensure_connected_sync (meta_backend, cancellable, error);

	if (success)
		e_book_meta_backend_schedule_refresh (meta_backend);

	return success;
}

static gboolean
ebmb_create_contact_sync (EBookMetaBackend *meta_backend,
			  EBookCache *book_cache,
			  ECacheOfflineFlag *offline_flag,
			  EConflictResolution conflict_resolution,
			  EContact *contact,
			  gchar **out_new_uid,
			  EContact **out_new_contact,
			  GCancellable *cancellable,
			  GError **error)
{
	const gchar *uid;
	gchar *new_uid = NULL, *new_extra = NULL;
	gboolean success, requires_put = TRUE;

	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	uid = e_contact_get_const (contact, E_CONTACT_UID);
	if (!uid) {
		gchar *new_uid;

		new_uid = e_util_generate_uid ();
		if (!new_uid) {
			g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_INVALID_ARG, NULL));
			return FALSE;
		}

		e_contact_set (contact, E_CONTACT_UID, new_uid);
		uid = e_contact_get_const (contact, E_CONTACT_UID);

		g_free (new_uid);
	}

	if (e_cache_contains (E_CACHE (book_cache), uid, E_CACHE_EXCLUDE_DELETED)) {
		g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_CONTACTID_ALREADY_EXISTS, NULL));
		return FALSE;
	}

	if (*offline_flag == E_CACHE_OFFLINE_UNKNOWN) {
		if (e_backend_get_online (E_BACKEND (meta_backend)) &&
		    e_book_meta_backend_ensure_connected_sync (meta_backend, cancellable, NULL)) {
			*offline_flag = E_CACHE_IS_ONLINE;
		} else {
			*offline_flag = E_CACHE_IS_OFFLINE;
		}
	}

	if (*offline_flag == E_CACHE_IS_ONLINE) {
		if (!ebmb_save_contact_wrapper_sync (meta_backend, book_cache, FALSE, conflict_resolution, contact, NULL, uid,
			&requires_put, &new_uid, &new_extra, cancellable, error)) {
			return FALSE;
		}
	}

	if (requires_put) {
		success = e_book_cache_put_contact (book_cache, contact, new_extra, *offline_flag, cancellable, error);
		if (success)
			e_book_backend_notify_update (E_BOOK_BACKEND (meta_backend), contact);
	} else {
		success = TRUE;
	}

	if (success) {
		if (out_new_uid)
			*out_new_uid = g_strdup (new_uid ? new_uid : uid);
		if (out_new_contact) {
			if (new_uid) {
				if (!e_book_cache_get_contact (book_cache, new_uid, FALSE, out_new_contact, cancellable, NULL))
					*out_new_contact = g_object_ref (contact);
			} else {
				*out_new_contact = g_object_ref (contact);
			}
		}
	}

	g_free (new_uid);
	g_free (new_extra);

	return success;
}

static gboolean
ebmb_create_contacts_sync (EBookBackend *book_backend,
			   const gchar * const *vcards,
			   GQueue *out_contacts,
			   GCancellable *cancellable,
			   GError **error)
{
	EBookMetaBackend *meta_backend;
	EBookCache *book_cache;
	ECacheOfflineFlag offline_flag = E_CACHE_OFFLINE_UNKNOWN;
	EConflictResolution conflict_resolution = E_CONFLICT_RESOLUTION_FAIL;
	gint ii;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), FALSE);
	g_return_val_if_fail (vcards != NULL, FALSE);
	g_return_val_if_fail (out_contacts != NULL, FALSE);

	if (!e_book_backend_get_writable (book_backend)) {
		g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_PERMISSION_DENIED, NULL));
		return FALSE;
	}

	meta_backend = E_BOOK_META_BACKEND (book_backend);
	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, FALSE);

	for (ii = 0; vcards[ii] && success; ii++) {
		EContact *contact, *new_contact = NULL;

		if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
			success = FALSE;
			break;
		}

		contact = e_contact_new_from_vcard (vcards[ii]);
		if (!contact) {
			g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_INVALID_ARG, NULL));
			success = FALSE;
			break;
		}

		success = ebmb_create_contact_sync (meta_backend, book_cache, &offline_flag, conflict_resolution,
			contact, NULL, &new_contact, cancellable, error);

		if (success) {
			ebmb_foreach_cursor (meta_backend, new_contact, e_data_book_cursor_contact_added);

			g_queue_push_tail (out_contacts, new_contact);
		}

		g_object_unref (contact);
	}

	g_object_unref (book_cache);

	if (!success) {
		g_queue_foreach (out_contacts, (GFunc) g_object_unref, NULL);
		g_queue_clear (out_contacts);
	}

	return success;
}

static gboolean
ebmb_modify_contact_sync (EBookMetaBackend *meta_backend,
			  EBookCache *book_cache,
			  ECacheOfflineFlag *offline_flag,
			  EConflictResolution conflict_resolution,
			  EContact *contact,
			  EContact **out_new_contact,
			  GCancellable *cancellable,
			  GError **error)
{
	const gchar *uid;
	EContact *existing_contact = NULL;
	gchar *extra = NULL, *new_uid = NULL, *new_extra = NULL;
	gboolean success = TRUE, requires_put = TRUE;
	GError *local_error = NULL;

	g_return_val_if_fail (contact != NULL, FALSE);

	uid = e_contact_get_const (contact, E_CONTACT_UID);
	if (!uid) {
		g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_INVALID_ARG, NULL));
		return FALSE;
	}

	if (!e_book_cache_get_contact (book_cache, uid, FALSE, &existing_contact, cancellable, &local_error)) {
		if (g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND)) {
			g_clear_error (&local_error);
			local_error = e_data_book_create_error (E_DATA_BOOK_STATUS_CONTACT_NOT_FOUND, NULL);
		}

		g_propagate_error (error, local_error);

		return FALSE;
	}

	if (!e_book_cache_get_contact_extra (book_cache, uid, &extra, cancellable, NULL))
		extra = NULL;

	if (success && *offline_flag == E_CACHE_OFFLINE_UNKNOWN) {
		if (e_backend_get_online (E_BACKEND (meta_backend)) &&
		    e_book_meta_backend_ensure_connected_sync (meta_backend, cancellable, NULL)) {
			*offline_flag = E_CACHE_IS_ONLINE;
		} else {
			*offline_flag = E_CACHE_IS_OFFLINE;
		}
	}

	if (success && *offline_flag == E_CACHE_IS_ONLINE) {
		success = ebmb_save_contact_wrapper_sync (meta_backend, book_cache, TRUE, conflict_resolution,
			contact, extra, uid, &requires_put, &new_uid, &new_extra, cancellable, error);
	}

	if (success && requires_put)
		success = ebmb_put_contact (meta_backend, book_cache, *offline_flag, contact, new_extra ? new_extra : extra, cancellable, error);

	if (success && out_new_contact) {
		if (new_uid) {
			if (!e_book_cache_get_contact (book_cache, new_uid, FALSE, out_new_contact, cancellable, NULL))
				*out_new_contact = NULL;
		} else {
			*out_new_contact = g_object_ref (contact);
		}
	}

	g_clear_object (&existing_contact);
	g_free (new_extra);
	g_free (new_uid);
	g_free (extra);

	return success;
}

static gboolean
ebmb_modify_contacts_sync (EBookBackend *book_backend,
			   const gchar * const *vcards,
			   GQueue *out_contacts,
			   GCancellable *cancellable,
			   GError **error)
{
	EBookMetaBackend *meta_backend;
	EBookCache *book_cache;
	ECacheOfflineFlag offline_flag = E_CACHE_OFFLINE_UNKNOWN;
	EConflictResolution conflict_resolution = E_CONFLICT_RESOLUTION_FAIL;
	gint ii;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), FALSE);
	g_return_val_if_fail (vcards != NULL, FALSE);
	g_return_val_if_fail (out_contacts != NULL, FALSE);

	if (!e_book_backend_get_writable (book_backend)) {
		g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_PERMISSION_DENIED, NULL));
		return FALSE;
	}

	meta_backend = E_BOOK_META_BACKEND (book_backend);
	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, FALSE);

	for (ii = 0; vcards[ii] && success; ii++) {
		EContact *contact, *new_contact = NULL;

		if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
			success = FALSE;
			break;
		}

		contact = e_contact_new_from_vcard (vcards[ii]);
		if (!contact) {
			g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_INVALID_ARG, NULL));
			success = FALSE;
			break;
		}

		success = ebmb_modify_contact_sync (meta_backend, book_cache, &offline_flag, conflict_resolution,
			contact, &new_contact, cancellable, error);

		if (success && new_contact) {
			ebmb_foreach_cursor (meta_backend, contact, e_data_book_cursor_contact_removed);
			ebmb_foreach_cursor (meta_backend, new_contact, e_data_book_cursor_contact_added);

			g_queue_push_tail (out_contacts, g_object_ref (new_contact));
		}

		g_clear_object (&new_contact);
		g_object_unref (contact);
	}

	g_object_unref (book_cache);

	if (!success) {
		g_queue_foreach (out_contacts, (GFunc) g_object_unref, NULL);
		g_queue_clear (out_contacts);
	}

	return success;
}

static gboolean
ebmb_remove_contact_sync (EBookMetaBackend *meta_backend,
			  EBookCache *book_cache,
			  ECacheOfflineFlag *offline_flag,
			  EConflictResolution conflict_resolution,
			  const gchar *uid,
			  GCancellable *cancellable,
			  GError **error)
{
	EContact *existing_contact = NULL;
	gchar *extra = NULL;
	gboolean success = TRUE;
	GError *local_error = NULL;

	g_return_val_if_fail (uid != NULL, FALSE);

	if (!e_book_cache_get_contact (book_cache, uid, FALSE, &existing_contact, cancellable, &local_error)) {
		if (g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND)) {
			g_clear_error (&local_error);
			local_error = e_data_book_create_error (E_DATA_BOOK_STATUS_CONTACT_NOT_FOUND, NULL);
		}

		g_propagate_error (error, local_error);

		return FALSE;
	}

	if (*offline_flag == E_CACHE_OFFLINE_UNKNOWN) {
		if (e_backend_get_online (E_BACKEND (meta_backend)) &&
		    e_book_meta_backend_ensure_connected_sync (meta_backend, cancellable, NULL)) {
			*offline_flag = E_CACHE_IS_ONLINE;
		} else {
			*offline_flag = E_CACHE_IS_OFFLINE;
		}
	}

	if (!e_book_cache_get_contact_extra (book_cache, uid, &extra, cancellable, NULL))
		extra = NULL;

	if (*offline_flag == E_CACHE_IS_ONLINE) {
		gchar *vcard_string = NULL;

		g_warn_if_fail (e_book_cache_get_vcard (book_cache, uid, FALSE, &vcard_string, cancellable, NULL));

		success = e_book_meta_backend_remove_contact_sync (meta_backend, conflict_resolution, uid, extra, vcard_string, cancellable, &local_error);

		g_free (vcard_string);

		if (local_error) {
			if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_HOST_NOT_FOUND))
				e_backend_set_online (E_BACKEND (meta_backend), FALSE);

			g_propagate_error (error, local_error);
			success = FALSE;
		}
	}

	success = success && ebmb_maybe_remove_from_cache (meta_backend, book_cache, *offline_flag, uid, cancellable, error);

	g_clear_object (&existing_contact);
	g_free (extra);

	return success;
}

static gboolean
ebmb_remove_contacts_sync (EBookBackend *book_backend,
			   const gchar * const *uids,
			   GCancellable *cancellable,
			   GError **error)
{
	EBookMetaBackend *meta_backend;
	EBookCache *book_cache;
	ECacheOfflineFlag offline_flag = E_CACHE_OFFLINE_UNKNOWN;
	EConflictResolution conflict_resolution = E_CONFLICT_RESOLUTION_FAIL;
	gint ii;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), FALSE);
	g_return_val_if_fail (uids != NULL, FALSE);

	if (!e_book_backend_get_writable (book_backend)) {
		g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_PERMISSION_DENIED, NULL));
		return FALSE;
	}

	meta_backend = E_BOOK_META_BACKEND (book_backend);
	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, FALSE);

	for (ii = 0; uids[ii] && success; ii++) {
		const gchar *uid = uids[ii];

		if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
			success = FALSE;
			break;
		}

		if (!uid) {
			g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_INVALID_ARG, NULL));
			success = FALSE;
			break;
		}

		success = ebmb_remove_contact_sync (meta_backend, book_cache, &offline_flag, conflict_resolution, uid, cancellable, error);
	}

	g_object_unref (book_cache);

	return success;
}

static EContact *
ebmb_get_contact_sync (EBookBackend *book_backend,
		       const gchar *uid,
		       GCancellable *cancellable,
		       GError **error)
{
	EBookMetaBackend *meta_backend;
	EBookCache *book_cache;
	EContact *contact = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), NULL);
	g_return_val_if_fail (uid && *uid, NULL);

	meta_backend = E_BOOK_META_BACKEND (book_backend);
	book_cache = e_book_meta_backend_ref_cache (meta_backend);

	g_return_val_if_fail (book_cache != NULL, NULL);

	if (!e_book_cache_get_contact (book_cache, uid, FALSE, &contact, cancellable, &local_error) &&
	    g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND)) {
		gchar *loaded_uid = NULL;
		gboolean found = FALSE;

		g_clear_error (&local_error);

		/* Ignore errors here, just try whether it's on the remote side, but not in the local cache */
		if (e_backend_get_online (E_BACKEND (meta_backend)) &&
		    e_book_meta_backend_ensure_connected_sync (meta_backend, cancellable, NULL) &&
		    ebmb_load_contact_wrapper_sync (meta_backend, book_cache, uid, NULL, NULL, &loaded_uid, cancellable, NULL)) {
			found = e_book_cache_get_contact (book_cache, loaded_uid, FALSE, &contact, cancellable, NULL);
		}

		if (!found)
			g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_CONTACT_NOT_FOUND, NULL));

		g_free (loaded_uid);
	} else if (local_error) {
		g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_OTHER_ERROR, local_error->message));
		g_clear_error (&local_error);
	}

	g_object_unref (book_cache);

	return contact;
}

static gboolean
ebmb_get_contact_list_sync (EBookBackend *book_backend,
			    const gchar *query,
			    GQueue *out_contacts,
			    GCancellable *cancellable,
			    GError **error)
{
	GSList *contacts = NULL, *link;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), FALSE);
	g_return_val_if_fail (out_contacts != NULL, FALSE);

	success = e_book_meta_backend_search_sync (E_BOOK_META_BACKEND (book_backend), query, FALSE, &contacts, cancellable, error);
	if (success) {
		for (link = contacts; link; link = g_slist_next (link)) {
			EContact *contact = link->data;

			g_queue_push_tail (out_contacts, g_object_ref (contact));
		}

		g_slist_free_full (contacts, g_object_unref);
	}

	return success;
}

static gboolean
ebmb_get_contact_list_uids_sync (EBookBackend *book_backend,
				 const gchar *query,
				 GQueue *out_uids,
				 GCancellable *cancellable,
				 GError **error)
{
	GSList *uids = NULL, *link;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), FALSE);
	g_return_val_if_fail (out_uids != NULL, FALSE);

	success = e_book_meta_backend_search_uids_sync (E_BOOK_META_BACKEND (book_backend), query, &uids, cancellable, error);
	if (success) {
		for (link = uids; link; link = g_slist_next (link)) {
			gchar *uid = link->data;

			g_queue_push_tail (out_uids, uid);
			link->data = NULL;
		}

		g_slist_free_full (uids, g_free);
	}

	return success;
}

static void
ebmb_start_view (EBookBackend *book_backend,
		 EDataBookView *view)
{
	GCancellable *cancellable;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (book_backend));

	cancellable = ebmb_create_view_cancellable (E_BOOK_META_BACKEND (book_backend), view);

	e_book_backend_schedule_custom_operation (book_backend, cancellable,
		ebmb_start_view_thread_func, g_object_ref (view), g_object_unref);

	g_object_unref (cancellable);
}

static void
ebmb_stop_view (EBookBackend *book_backend,
		EDataBookView *view)
{
	GCancellable *cancellable;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (book_backend));

	cancellable = ebmb_steal_view_cancellable (E_BOOK_META_BACKEND (book_backend), view);
	if (cancellable) {
		g_cancellable_cancel (cancellable);
		g_object_unref (cancellable);
	}
}

static EDataBookDirect *
ebmb_get_direct_book (EBookBackend *book_backend)
{
	EBookMetaBackendClass *klass;
	EBookCache *book_cache;
	EDataBookDirect *direct_book;
	const gchar *cache_filename;
	gchar *backend_path;
	gchar *dirname;
	const gchar *modules_env;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), NULL);

	klass = E_BOOK_META_BACKEND_GET_CLASS (book_backend);
	g_return_val_if_fail (klass != NULL, NULL);

	if (!klass->backend_module_filename ||
	    !klass->backend_factory_type_name)
		return NULL;

	book_cache = e_book_meta_backend_ref_cache (E_BOOK_META_BACKEND (book_backend));
	g_return_val_if_fail (book_cache != NULL, NULL);

	cache_filename = e_cache_get_filename (E_CACHE (book_cache));
	dirname = g_path_get_dirname (cache_filename);

	modules_env = g_getenv (EDS_ADDRESS_BOOK_MODULES);

	/* Support in-tree testing / relocated modules */
	if (modules_env) {
		backend_path = g_build_filename (modules_env, klass->backend_module_filename, NULL);
	} else {
		backend_path = g_build_filename (BACKENDDIR, klass->backend_module_filename, NULL);
	}

	direct_book = e_data_book_direct_new (backend_path, klass->backend_factory_type_name, dirname);

	g_object_unref (book_cache);
	g_free (backend_path);
	g_free (dirname);

	return direct_book;
}

static void
ebmb_configure_direct (EBookBackend *book_backend,
		       const gchar *base_directory)
{
	EBookMetaBackend *meta_backend;
	EBookCache *book_cache;
	const gchar *cache_filename;
	gchar *dirname;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (book_backend));

	if (!base_directory)
		return;

	meta_backend = E_BOOK_META_BACKEND (book_backend);

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_if_fail (book_cache != NULL);

	cache_filename = e_cache_get_filename (E_CACHE (book_cache));
	dirname = g_path_get_dirname (cache_filename);

	/* Did path for the cache change? Change the cache as well */
	if (dirname && !g_str_equal (base_directory, dirname) &&
	    !g_str_has_prefix (dirname, base_directory)) {
		gchar *filename = g_path_get_basename (cache_filename);
		gchar *new_cache_filename;
		EBookCache *new_cache;
		ESource *source;

		new_cache_filename = g_build_filename (base_directory, filename, NULL);
		source = e_backend_get_source (E_BACKEND (book_backend));

		g_clear_error (&meta_backend->priv->create_cache_error);

		new_cache = e_book_cache_new (new_cache_filename, source, NULL, &meta_backend->priv->create_cache_error);
		g_prefix_error (&meta_backend->priv->create_cache_error, _("Failed to create cache “%s”:"), new_cache_filename);

		if (new_cache) {
			e_book_meta_backend_set_cache (meta_backend, new_cache);
			g_clear_object (&new_cache);
		}

		g_free (new_cache_filename);
		g_free (filename);
	}

	g_free (dirname);
	g_object_unref (book_cache);
}

static gboolean
ebmb_set_locale (EBookBackend *book_backend,
		 const gchar *locale,
		 GCancellable *cancellable,
		 GError **error)
{
	EBookMetaBackend *meta_backend;
	EBookCache *book_cache;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), FALSE);

	meta_backend = E_BOOK_META_BACKEND (book_backend);

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, FALSE);

	success = e_book_cache_set_locale (book_cache, locale, cancellable, error);
	if (success) {
		GSList *link;

		g_mutex_lock (&meta_backend->priv->property_lock);

		for (link = meta_backend->priv->cursors; success && link; link = g_slist_next (link)) {
			EDataBookCursor *cursor = link->data;

			success = e_data_book_cursor_load_locale (cursor, NULL, cancellable, error);
		}

		g_mutex_unlock (&meta_backend->priv->property_lock);
	}

	g_object_unref (book_cache);

	return success;
}

static gchar *
ebmb_dup_locale (EBookBackend *book_backend)
{
	EBookMetaBackend *meta_backend;
	EBookCache *book_cache;
	gchar *locale;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), NULL);

	meta_backend = E_BOOK_META_BACKEND (book_backend);

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, NULL);

	locale = e_book_cache_dup_locale (book_cache);

	g_object_unref (book_cache);

	return locale;
}

static EDataBookCursor *
ebmb_create_cursor (EBookBackend *book_backend,
		    EContactField *sort_fields,
		    EBookCursorSortType *sort_types,
		    guint n_fields,
		    GError **error)
{
	EBookMetaBackend *meta_backend;
	EBookCache *book_cache;
	EDataBookCursor *cursor;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), NULL);

	meta_backend = E_BOOK_META_BACKEND (book_backend);

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, NULL);

	cursor = e_data_book_cursor_cache_new (book_backend, book_cache, sort_fields, sort_types, n_fields, error);

	if (cursor) {
		g_mutex_lock (&meta_backend->priv->property_lock);

		meta_backend->priv->cursors = g_slist_prepend (meta_backend->priv->cursors, cursor);

		g_mutex_unlock (&meta_backend->priv->property_lock);
	}

	g_object_unref (book_cache);

	return cursor;
}

static gboolean
ebmb_delete_cursor (EBookBackend *book_backend,
		    EDataBookCursor *cursor,
		    GError **error)
{
	EBookMetaBackend *meta_backend;
	GSList *link;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (book_backend), FALSE);

	meta_backend = E_BOOK_META_BACKEND (book_backend);

	g_mutex_lock (&meta_backend->priv->property_lock);

	link = g_slist_find (meta_backend->priv->cursors, cursor);

	if (link) {
		meta_backend->priv->cursors = g_slist_remove (meta_backend->priv->cursors, cursor);
		g_object_unref (cursor);
	} else {
		g_set_error_literal (
			error,
			E_CLIENT_ERROR,
			E_CLIENT_ERROR_INVALID_ARG,
			_("Requested to delete an unrelated cursor"));
	}

	g_mutex_unlock (&meta_backend->priv->property_lock);

	return link != NULL;
}

static ESourceAuthenticationResult
ebmb_authenticate_sync (EBackend *backend,
			const ENamedParameters *credentials,
			gchar **out_certificate_pem,
			GTlsCertificateFlags *out_certificate_errors,
			GCancellable *cancellable,
			GError **error)
{
	EBookMetaBackend *meta_backend;
	ESourceAuthenticationResult auth_result = E_SOURCE_AUTHENTICATION_UNKNOWN;
	gboolean success, refresh_after_authenticate = FALSE;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (backend), E_SOURCE_AUTHENTICATION_ERROR);

	meta_backend = E_BOOK_META_BACKEND (backend);

	if (!e_backend_get_online (E_BACKEND (meta_backend))) {
		g_set_error_literal (error, E_CLIENT_ERROR, E_CLIENT_ERROR_REPOSITORY_OFFLINE,
			e_client_error_to_string (E_CLIENT_ERROR_REPOSITORY_OFFLINE));

		g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
		meta_backend->priv->wait_credentials_stamp++;
		g_cond_broadcast (&meta_backend->priv->wait_credentials_cond);
		g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);

		return E_SOURCE_AUTHENTICATION_ERROR;
	}

	g_mutex_lock (&meta_backend->priv->connect_lock);

	e_source_set_connection_status (e_backend_get_source (backend), E_SOURCE_CONNECTION_STATUS_CONNECTING);

	/* Always disconnect first, then provide new credentials. */
	e_book_meta_backend_disconnect_sync (meta_backend, cancellable, NULL);

	success = e_book_meta_backend_connect_sync (meta_backend, credentials, &auth_result,
		out_certificate_pem, out_certificate_errors, cancellable, error);

	if (success) {
		ebmb_update_connection_values (meta_backend);
		auth_result = E_SOURCE_AUTHENTICATION_ACCEPTED;

		e_source_set_connection_status (e_backend_get_source (backend), E_SOURCE_CONNECTION_STATUS_CONNECTED);
	} else {
		if (auth_result == E_SOURCE_AUTHENTICATION_UNKNOWN)
			auth_result = E_SOURCE_AUTHENTICATION_ERROR;

		e_source_set_connection_status (e_backend_get_source (backend), E_SOURCE_CONNECTION_STATUS_DISCONNECTED);
	}
	g_mutex_unlock (&meta_backend->priv->connect_lock);

	g_mutex_lock (&meta_backend->priv->property_lock);

	e_named_parameters_free (meta_backend->priv->last_credentials);
	if (success) {
		meta_backend->priv->last_credentials = e_named_parameters_new_clone (credentials);

		refresh_after_authenticate = meta_backend->priv->refresh_after_authenticate;
		meta_backend->priv->refresh_after_authenticate = FALSE;
	} else {
		meta_backend->priv->last_credentials = NULL;
	}

	g_mutex_unlock (&meta_backend->priv->property_lock);

	g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
	meta_backend->priv->wait_credentials_stamp++;
	g_cond_broadcast (&meta_backend->priv->wait_credentials_cond);
	g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);

	if (refresh_after_authenticate)
		e_book_meta_backend_schedule_refresh (meta_backend);

	return auth_result;
}

static void
ebmb_schedule_source_changed (EBookMetaBackend *meta_backend)
{
	GCancellable *cancellable;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (meta_backend));

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->source_changed_cancellable) {
		/* Already updating */
		g_mutex_unlock (&meta_backend->priv->property_lock);
		return;
	}

	cancellable = g_cancellable_new ();
	meta_backend->priv->source_changed_cancellable = g_object_ref (cancellable);

	g_mutex_unlock (&meta_backend->priv->property_lock);

	e_book_backend_schedule_custom_operation (E_BOOK_BACKEND (meta_backend), cancellable,
		ebmb_source_changed_thread_func, NULL, NULL);

	g_object_unref (cancellable);
}

static void
ebmb_schedule_go_offline (EBookMetaBackend *meta_backend)
{
	GCancellable *cancellable;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (meta_backend));

	g_mutex_lock (&meta_backend->priv->property_lock);

	/* Cancel anything ongoing now, but disconnect in a dedicated thread */
	if (meta_backend->priv->refresh_cancellable) {
		g_cancellable_cancel (meta_backend->priv->refresh_cancellable);
		g_clear_object (&meta_backend->priv->refresh_cancellable);
	}

	if (meta_backend->priv->source_changed_cancellable) {
		g_cancellable_cancel (meta_backend->priv->source_changed_cancellable);
		g_clear_object (&meta_backend->priv->source_changed_cancellable);
	}

	if (meta_backend->priv->go_offline_cancellable) {
		/* Already going offline */
		g_mutex_unlock (&meta_backend->priv->property_lock);
		return;
	}

	cancellable = g_cancellable_new ();
	meta_backend->priv->go_offline_cancellable = g_object_ref (cancellable);

	g_mutex_unlock (&meta_backend->priv->property_lock);

	e_book_backend_schedule_custom_operation (E_BOOK_BACKEND (meta_backend), cancellable,
		ebmb_go_offline_thread_func, NULL, NULL);

	g_object_unref (cancellable);
}

static void
ebmb_notify_online_cb (GObject *object,
		       GParamSpec *param,
		       gpointer user_data)
{
	EBookMetaBackend *meta_backend = user_data;
	gboolean new_value;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (meta_backend));

	new_value = e_backend_get_online (E_BACKEND (meta_backend));
	if (!new_value == !meta_backend->priv->current_online_state)
		return;

	meta_backend->priv->current_online_state = new_value;

	if (new_value)
		e_book_meta_backend_schedule_refresh (meta_backend);
	else
		ebmb_schedule_go_offline (meta_backend);
}

static void
ebmb_cancel_view_cb (gpointer key,
		     gpointer value,
		     gpointer user_data)
{
	GCancellable *cancellable = value;

	g_return_if_fail (G_IS_CANCELLABLE (cancellable));

	g_cancellable_cancel (cancellable);
}

static void
ebmb_wait_for_credentials_cancelled_cb (GCancellable *cancellable,
					gpointer user_data)
{
	EBookMetaBackend *meta_backend = user_data;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (meta_backend));

	g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
	g_cond_broadcast (&meta_backend->priv->wait_credentials_cond);
	g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);
}

static gboolean
ebmb_maybe_wait_for_credentials (EBookMetaBackend *meta_backend,
				 guint wait_credentials_stamp,
				 const GError *op_error,
				 GCancellable *cancellable)
{
	EBackend *backend;
	ESourceCredentialsReason reason = E_SOURCE_CREDENTIALS_REASON_UNKNOWN;
	gchar *certificate_pem = NULL;
	GTlsCertificateFlags certificate_errors = 0;
	gboolean got_credentials = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	if (!op_error || g_cancellable_is_cancelled (cancellable))
		return FALSE;

	if (g_error_matches (op_error, E_DATA_BOOK_ERROR, E_DATA_BOOK_STATUS_TLS_NOT_AVAILABLE) &&
	    e_book_meta_backend_get_ssl_error_details (meta_backend, &certificate_pem, &certificate_errors)) {
		reason = E_SOURCE_CREDENTIALS_REASON_SSL_FAILED;
	} else if (g_error_matches (op_error, E_DATA_BOOK_ERROR, E_DATA_BOOK_STATUS_AUTHENTICATION_REQUIRED)) {
		reason = E_SOURCE_CREDENTIALS_REASON_REQUIRED;
	} else if (g_error_matches (op_error, E_DATA_BOOK_ERROR, E_DATA_BOOK_STATUS_AUTHENTICATION_FAILED)) {
		reason = E_SOURCE_CREDENTIALS_REASON_REJECTED;
	}

	if (reason == E_SOURCE_CREDENTIALS_REASON_UNKNOWN)
		return FALSE;

	backend = E_BACKEND (meta_backend);

	g_mutex_lock (&meta_backend->priv->wait_credentials_lock);

	if (wait_credentials_stamp != meta_backend->priv->wait_credentials_stamp ||
	    e_backend_credentials_required_sync (backend, reason, certificate_pem, certificate_errors,
		op_error, cancellable, &local_error)) {
		gint64 wait_end_time;
		gulong handler_id;

		wait_end_time = g_get_monotonic_time () + MAX_WAIT_FOR_CREDENTIALS_SECS * G_TIME_SPAN_SECOND;

		handler_id = cancellable ? g_signal_connect (cancellable, "cancelled",
			G_CALLBACK (ebmb_wait_for_credentials_cancelled_cb), meta_backend) : 0;

		while (wait_credentials_stamp == meta_backend->priv->wait_credentials_stamp &&
		       !g_cancellable_is_cancelled (cancellable)) {
			if (!g_cond_wait_until (&meta_backend->priv->wait_credentials_cond, &meta_backend->priv->wait_credentials_lock, wait_end_time))
				break;
		}

		if (handler_id)
			g_signal_handler_disconnect (cancellable, handler_id);

		if (wait_credentials_stamp != meta_backend->priv->wait_credentials_stamp)
			got_credentials = e_source_get_connection_status (e_backend_get_source (backend)) == E_SOURCE_CONNECTION_STATUS_CONNECTED;
	} else {
		g_warning ("%s: Failed to call credentials required: %s", G_STRFUNC, local_error ? local_error->message : "Unknown error");
	}

	g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);

	g_clear_error (&local_error);
	g_free (certificate_pem);

	return got_credentials;
}

static void
e_book_meta_backend_set_property (GObject *object,
				  guint property_id,
				  const GValue *value,
				  GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CACHE:
			e_book_meta_backend_set_cache (
				E_BOOK_META_BACKEND (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_book_meta_backend_get_property (GObject *object,
				  guint property_id,
				  GValue *value,
				  GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CACHE:
			g_value_take_object (
				value,
				e_book_meta_backend_ref_cache (
				E_BOOK_META_BACKEND (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_book_meta_backend_constructed (GObject *object)
{
	EBookMetaBackend *meta_backend = E_BOOK_META_BACKEND (object);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_book_meta_backend_parent_class)->constructed (object);

	meta_backend->priv->current_online_state = e_backend_get_online (E_BACKEND (meta_backend));

	meta_backend->priv->notify_online_id = g_signal_connect (meta_backend, "notify::online",
		G_CALLBACK (ebmb_notify_online_cb), meta_backend);

	if (!meta_backend->priv->cache) {
		EBookCache *cache;
		ESource *source;
		gchar *filename;

		source = e_backend_get_source (E_BACKEND (meta_backend));
		filename = g_build_filename (e_book_backend_get_cache_dir (E_BOOK_BACKEND (meta_backend)), "cache.db", NULL);
		cache = e_book_cache_new (filename, source, NULL, &meta_backend->priv->create_cache_error);
		g_prefix_error (&meta_backend->priv->create_cache_error, _("Failed to create cache “%s”:"), filename);

		g_free (filename);

		if (cache) {
			e_book_meta_backend_set_cache (meta_backend, cache);
			g_clear_object (&cache);
		}
	}
}

static void
e_book_meta_backend_dispose (GObject *object)
{
	EBookMetaBackend *meta_backend = E_BOOK_META_BACKEND (object);
	ESource *source = e_backend_get_source (E_BACKEND (meta_backend));

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->cursors) {
		g_slist_free_full (meta_backend->priv->cursors, g_object_unref);
		meta_backend->priv->cursors = NULL;
	}

	if (meta_backend->priv->refresh_timeout_id) {
		if (source)
			e_source_refresh_remove_timeout (source, meta_backend->priv->refresh_timeout_id);
		meta_backend->priv->refresh_timeout_id = 0;
	}

	if (meta_backend->priv->source_changed_id) {
		if (source)
			g_signal_handler_disconnect (source, meta_backend->priv->source_changed_id);
		meta_backend->priv->source_changed_id = 0;
	}

	if (meta_backend->priv->notify_online_id) {
		g_signal_handler_disconnect (meta_backend, meta_backend->priv->notify_online_id);
		meta_backend->priv->notify_online_id = 0;
	}

	if (meta_backend->priv->revision_changed_id) {
		if (meta_backend->priv->cache)
			g_signal_handler_disconnect (meta_backend->priv->cache, meta_backend->priv->revision_changed_id);
		meta_backend->priv->revision_changed_id = 0;
	}

	g_hash_table_foreach (meta_backend->priv->view_cancellables, ebmb_cancel_view_cb, NULL);

	if (meta_backend->priv->refresh_cancellable) {
		g_cancellable_cancel (meta_backend->priv->refresh_cancellable);
		g_clear_object (&meta_backend->priv->refresh_cancellable);
	}

	if (meta_backend->priv->source_changed_cancellable) {
		g_cancellable_cancel (meta_backend->priv->source_changed_cancellable);
		g_clear_object (&meta_backend->priv->source_changed_cancellable);
	}

	if (meta_backend->priv->go_offline_cancellable) {
		g_cancellable_cancel (meta_backend->priv->go_offline_cancellable);
		g_clear_object (&meta_backend->priv->go_offline_cancellable);
	}

	e_named_parameters_free (meta_backend->priv->last_credentials);
	meta_backend->priv->last_credentials = NULL;

	g_mutex_unlock (&meta_backend->priv->property_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_book_meta_backend_parent_class)->dispose (object);
}

static void
e_book_meta_backend_finalize (GObject *object)
{
	EBookMetaBackend *meta_backend = E_BOOK_META_BACKEND (object);

	g_clear_object (&meta_backend->priv->cache);
	g_clear_object (&meta_backend->priv->refresh_cancellable);
	g_clear_object (&meta_backend->priv->source_changed_cancellable);
	g_clear_object (&meta_backend->priv->go_offline_cancellable);
	g_clear_error (&meta_backend->priv->create_cache_error);
	g_clear_pointer (&meta_backend->priv->authentication_host, g_free);
	g_clear_pointer (&meta_backend->priv->authentication_user, g_free);
	g_clear_pointer (&meta_backend->priv->authentication_method, g_free);
	g_clear_pointer (&meta_backend->priv->authentication_proxy_uid, g_free);
	g_clear_pointer (&meta_backend->priv->authentication_credential_name, g_free);
	g_clear_pointer (&meta_backend->priv->webdav_soup_uri, (GDestroyNotify) soup_uri_free);

	g_mutex_clear (&meta_backend->priv->connect_lock);
	g_mutex_clear (&meta_backend->priv->property_lock);
	g_mutex_clear (&meta_backend->priv->wait_credentials_lock);
	g_cond_clear (&meta_backend->priv->wait_credentials_cond);
	g_hash_table_destroy (meta_backend->priv->view_cancellables);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_book_meta_backend_parent_class)->finalize (object);
}

static void
e_book_meta_backend_class_init (EBookMetaBackendClass *klass)
{
	GObjectClass *object_class;
	EBackendClass *backend_class;
	EBookBackendClass *book_backend_class;

	g_type_class_add_private (klass, sizeof (EBookMetaBackendPrivate));

	klass->backend_factory_type_name = NULL;
	klass->backend_module_filename = NULL;
	klass->get_changes_sync = ebmb_get_changes_sync;
	klass->search_sync = ebmb_search_sync;
	klass->search_uids_sync = ebmb_search_uids_sync;
	klass->requires_reconnect = ebmb_requires_reconnect;
	klass->get_ssl_error_details = ebmb_get_ssl_error_details;

	book_backend_class = E_BOOK_BACKEND_CLASS (klass);
	book_backend_class->get_backend_property = ebmb_get_backend_property;
	book_backend_class->open_sync = ebmb_open_sync;
	book_backend_class->refresh_sync = ebmb_refresh_sync;
	book_backend_class->create_contacts_sync = ebmb_create_contacts_sync;
	book_backend_class->modify_contacts_sync = ebmb_modify_contacts_sync;
	book_backend_class->remove_contacts_sync = ebmb_remove_contacts_sync;
	book_backend_class->get_contact_sync = ebmb_get_contact_sync;
	book_backend_class->get_contact_list_sync = ebmb_get_contact_list_sync;
	book_backend_class->get_contact_list_uids_sync = ebmb_get_contact_list_uids_sync;
	book_backend_class->start_view = ebmb_start_view;
	book_backend_class->stop_view = ebmb_stop_view;
	book_backend_class->get_direct_book = ebmb_get_direct_book;
	book_backend_class->configure_direct = ebmb_configure_direct;
	book_backend_class->set_locale = ebmb_set_locale;
	book_backend_class->dup_locale = ebmb_dup_locale;
	book_backend_class->create_cursor = ebmb_create_cursor;
	book_backend_class->delete_cursor = ebmb_delete_cursor;

	backend_class = E_BACKEND_CLASS (klass);
	backend_class->authenticate_sync = ebmb_authenticate_sync;

	object_class = G_OBJECT_CLASS (klass);
	object_class->set_property = e_book_meta_backend_set_property;
	object_class->get_property = e_book_meta_backend_get_property;
	object_class->constructed = e_book_meta_backend_constructed;
	object_class->dispose = e_book_meta_backend_dispose;
	object_class->finalize = e_book_meta_backend_finalize;

	/**
	 * EBookMetaBackend:cache:
	 *
	 * The #EBookCache being used for this meta backend.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_CACHE,
		g_param_spec_object (
			"cache",
			"Cache",
			"Book Cache",
			E_TYPE_BOOK_CACHE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/* This signal is meant for testing purposes mainly */
	signals[REFRESH_COMPLETED] = g_signal_new (
		"refresh-completed",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST,
		0,
		NULL, NULL, NULL,
		G_TYPE_NONE, 0, G_TYPE_NONE);

	/**
	 * EBookMetaBackend::source-changed
	 *
	 * This signal is emitted whenever the underlying backend #ESource
	 * changes. Unlike the #ESource's 'changed' signal this one is
	 * tight to the #EBookMetaBackend itself and is emitted from
	 * a dedicated thread, thus it doesn't block the main thread.
	 *
	 * Since: 3.26
	 **/
	signals[SOURCE_CHANGED] = g_signal_new (
		"source-changed",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookMetaBackendClass, source_changed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0, G_TYPE_NONE);
}

static void
e_book_meta_backend_init (EBookMetaBackend *meta_backend)
{
	meta_backend->priv = G_TYPE_INSTANCE_GET_PRIVATE (meta_backend, E_TYPE_BOOK_META_BACKEND, EBookMetaBackendPrivate);

	g_mutex_init (&meta_backend->priv->connect_lock);
	g_mutex_init (&meta_backend->priv->property_lock);
	g_mutex_init (&meta_backend->priv->wait_credentials_lock);
	g_cond_init (&meta_backend->priv->wait_credentials_cond);

	meta_backend->priv->view_cancellables = g_hash_table_new_full (g_direct_hash, g_direct_equal, NULL, g_object_unref);
	meta_backend->priv->current_online_state = FALSE;
	meta_backend->priv->refresh_after_authenticate = FALSE;
	meta_backend->priv->ever_connected = -1;
	meta_backend->priv->connected_writable = -1;
}

/**
 * e_book_meta_backend_get_capabilities:
 * @meta_backend: an #EBookMetaBackend
 *
 * Returns: an #EBookBackend::capabilities property to be used by
 *    the descendant in conjunction to the descendant's capabilities
 *    in the result of e_book_backend_get_backend_property() with
 *    #CLIENT_BACKEND_PROPERTY_CAPABILITIES.
 *
 * Since: 3.26
 **/
const gchar *
e_book_meta_backend_get_capabilities (EBookMetaBackend *meta_backend)
{
	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), NULL);

	return "refresh-supported" ","
		"bulk-adds" ","
		"bulk-modifies" ","
		"bulk-removes";
}

/**
 * e_book_meta_backend_set_ever_connected:
 * @meta_backend: an #EBookMetaBackend
 * @value: value to set
 *
 * Sets whether the @meta_backend ever made a successful connection
 * to its destination.
 *
 * This is used by the @meta_backend itself, during the opening phase,
 * when it had not been connected yet, then it does so immediately, to
 * eventually report settings error easily.
 *
 * Since: 3.26
 **/
void
e_book_meta_backend_set_ever_connected (EBookMetaBackend *meta_backend,
					gboolean value)
{
	EBookCache *book_cache;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (meta_backend));

	if ((value ? 1 : 0) == meta_backend->priv->ever_connected)
		return;

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	meta_backend->priv->ever_connected = value ? 1 : 0;
	e_cache_set_key_int (E_CACHE (book_cache), EBMB_KEY_EVER_CONNECTED, meta_backend->priv->ever_connected, NULL);
	g_clear_object (&book_cache);
}

/**
 * e_book_meta_backend_get_ever_connected:
 * @meta_backend: an #EBookMetaBackend
 *
 * Returns: Whether the @meta_backend ever made a successful connection
 *    to its destination.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_get_ever_connected (EBookMetaBackend *meta_backend)
{
	gboolean result;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	if (meta_backend->priv->ever_connected == -1) {
		EBookCache *book_cache;

		book_cache = e_book_meta_backend_ref_cache (meta_backend);
		result = e_cache_get_key_int (E_CACHE (book_cache), EBMB_KEY_EVER_CONNECTED, NULL) == 1;
		g_clear_object (&book_cache);

		meta_backend->priv->ever_connected = result ? 1 : 0;
	} else {
		result = meta_backend->priv->ever_connected == 1;
	}

	return result;
}

/**
 * e_book_meta_backend_set_connected_writable:
 * @meta_backend: an #EBookMetaBackend
 * @value: value to set
 *
 * Sets whether the @meta_backend connected to a writable destination.
 * This value has meaning only if e_book_meta_backend_get_ever_connected()
 * is %TRUE.
 *
 * This is used by the @meta_backend itself, during the opening phase,
 * to set the backend writable or not also in the offline mode.
 *
 * Since: 3.26
 **/
void
e_book_meta_backend_set_connected_writable (EBookMetaBackend *meta_backend,
					    gboolean value)
{
	EBookCache *book_cache;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (meta_backend));

	if ((value ? 1 : 0) == meta_backend->priv->connected_writable)
		return;

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	meta_backend->priv->connected_writable = value ? 1 : 0;
	e_cache_set_key_int (E_CACHE (book_cache), EBMB_KEY_CONNECTED_WRITABLE, meta_backend->priv->connected_writable, NULL);
	g_clear_object (&book_cache);
}

/**
 * e_book_meta_backend_get_connected_writable:
 * @meta_backend: an #EBookMetaBackend
 *
 * This value has meaning only if e_book_meta_backend_get_ever_connected()
 * is %TRUE.
 *
 * Returns: Whether the @meta_backend connected to a writable destination.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_get_connected_writable (EBookMetaBackend *meta_backend)
{
	gboolean result;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	if (meta_backend->priv->connected_writable == -1) {
		EBookCache *book_cache;

		book_cache = e_book_meta_backend_ref_cache (meta_backend);
		result = e_cache_get_key_int (E_CACHE (book_cache), EBMB_KEY_CONNECTED_WRITABLE, NULL) == 1;
		g_clear_object (&book_cache);

		meta_backend->priv->connected_writable = result ? 1 : 0;
	} else {
		result = meta_backend->priv->connected_writable == 1;
	}

	return result;
}

/**
 * e_book_meta_backend_dup_sync_tag:
 * @meta_backend: an #EBookMetaBackend
 *
 * Returns the last known synchronization tag, the same as used to
 * call e_book_meta_backend_get_changes_sync().
 *
 * Free the returned string with g_free(), when no longer needed.
 *
 * Returns: (transfer full) (nullable): The last known synchronization tag,
 *    or %NULL, when none is stored.
 *
 * Since: 3.28
 **/
gchar *
e_book_meta_backend_dup_sync_tag (EBookMetaBackend *meta_backend)
{
	EBookCache *book_cache;
	gchar *sync_tag;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), NULL);

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	if (!book_cache)
		return NULL;

	sync_tag = e_cache_dup_key (E_CACHE (book_cache), EBMB_KEY_SYNC_TAG, NULL);
	if (sync_tag && !*sync_tag) {
		g_free (sync_tag);
		sync_tag = NULL;
	}

	g_clear_object (&book_cache);

	return sync_tag;
}

static void
ebmb_cache_revision_changed_cb (ECache *cache,
				gpointer user_data)
{
	EBookMetaBackend *meta_backend = user_data;
	gchar *revision;

	g_return_if_fail (E_IS_CACHE (cache));
	g_return_if_fail (E_IS_BOOK_META_BACKEND (meta_backend));

	revision = e_cache_dup_revision (cache);
	if (revision) {
		e_book_backend_notify_property_changed (E_BOOK_BACKEND (meta_backend),
			BOOK_BACKEND_PROPERTY_REVISION, revision);
		g_free (revision);
	}
}

/**
 * e_book_meta_backend_set_cache:
 * @meta_backend: an #EBookMetaBackend
 * @cache: an #EBookCache to use
 *
 * Sets the @cache as the cache to be used by the @meta_backend.
 * By default, a cache.db in EBookBackend::cache-dir is created
 * in the constructed method. This function can be used to override
 * the default.
 *
 * Note the @meta_backend adds its own reference to the @cache.
 *
 * Since: 3.26
 **/
void
e_book_meta_backend_set_cache (EBookMetaBackend *meta_backend,
			       EBookCache *cache)
{
	g_return_if_fail (E_IS_BOOK_META_BACKEND (meta_backend));
	g_return_if_fail (E_IS_BOOK_CACHE (cache));

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->cache == cache) {
		g_mutex_unlock (&meta_backend->priv->property_lock);
		return;
	}

	g_clear_error (&meta_backend->priv->create_cache_error);

	if (meta_backend->priv->cache) {
		g_signal_handler_disconnect (meta_backend->priv->cache,
			meta_backend->priv->revision_changed_id);
	}

	g_clear_object (&meta_backend->priv->cache);
	meta_backend->priv->cache = g_object_ref (cache);

	meta_backend->priv->revision_changed_id = g_signal_connect_object (meta_backend->priv->cache,
		"revision-changed", G_CALLBACK (ebmb_cache_revision_changed_cb), meta_backend, 0);

	g_mutex_unlock (&meta_backend->priv->property_lock);

	g_object_notify (G_OBJECT (meta_backend), "cache");
}

/**
 * e_book_meta_backend_ref_cache:
 * @meta_backend: an #EBookMetaBackend
 *
 * Returns: (transfer full): Referenced #EBookCache, which is used by @meta_backend.
 *    Unref it with g_object_unref(), when no longer needed.
 *
 * Since: 3.26
 **/
EBookCache *
e_book_meta_backend_ref_cache (EBookMetaBackend *meta_backend)
{
	EBookCache *cache;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), NULL);

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->cache)
		cache = g_object_ref (meta_backend->priv->cache);
	else
		cache = NULL;

	g_mutex_unlock (&meta_backend->priv->property_lock);

	return cache;
}

static gchar *
ebmb_get_mime_type (const gchar *url,
		    const gchar *content,
		    gsize content_len)
{
	gchar *content_type, *filename = NULL, *mime_type = NULL;

	if (url) {
		filename = g_filename_from_uri (url, NULL, NULL);
		if (filename) {
			gchar *extension;

			/* When storing inline attachments to the local file,
			   the file extension is the mime type as stored in the attribute */
			extension = strrchr (filename, '.');
			if (extension)
				extension++;

			if (extension) {
				mime_type = g_uri_unescape_string (extension, NULL);
				if (mime_type && !strchr (mime_type, '/')) {
					gchar *tmp;

					tmp = g_strconcat ("image/", mime_type, NULL);

					g_free (mime_type);
					mime_type = tmp;
				}

				content_type = g_content_type_from_mime_type (mime_type);

				if (!content_type) {
					g_free (mime_type);
					mime_type = NULL;
				}

				g_free (content_type);
			}
		}
	}

	if (!mime_type) {
		content_type = g_content_type_guess (filename, (const guchar *) content, content_len, NULL);

		if (content_type)
			mime_type = g_content_type_get_mime_type (content_type);

		g_free (content_type);
	}

	g_free (filename);

	return mime_type;
}

/**
 * e_book_meta_backend_inline_local_photos_sync:
 * @meta_backend: an #EBookMetaBackend
 * @contact: an #EContact to work with
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Changes all URL photos and logos which point to a local file in @contact
 * to inline type, aka adds the file content into the @contact.
 * This is called automatically before e_book_meta_backend_save_contact_sync().
 *
 * The reverse operation is e_book_meta_backend_store_inline_photos_sync().
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_inline_local_photos_sync (EBookMetaBackend *meta_backend,
					      EContact *contact,
					      GCancellable *cancellable,
					      GError **error)
{
	GList *attributes, *link;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	attributes = e_vcard_get_attributes (E_VCARD (contact));

	for (link = attributes; link; link = g_list_next (link)) {
		EVCardAttribute *attr = link->data;
		const gchar *attr_name;
		GList *values;

		attr_name = e_vcard_attribute_get_name (attr);
		if (!attr_name || (
		    g_ascii_strcasecmp (attr_name, EVC_PHOTO) != 0 &&
		    g_ascii_strcasecmp (attr_name, EVC_LOGO) != 0)) {
			continue;
		}

		values = e_vcard_attribute_get_param (attr, EVC_VALUE);
		if (values && g_ascii_strcasecmp (values->data, "uri") == 0) {
			gchar *url;

			url = e_vcard_attribute_get_value (attr);
			if (url && g_str_has_prefix (url, LOCAL_PREFIX)) {
				GFile *file;
				gchar *basename;
				gchar *content;
				gsize len;

				file = g_file_new_for_uri (url);
				basename = g_file_get_basename (file);
				if (g_file_load_contents (file, cancellable, &content, &len, NULL, error)) {
					gchar *mime_type;
					const gchar *image_type, *pp;

					mime_type = ebmb_get_mime_type (url, content, len);
					if (mime_type && (pp = strchr (mime_type, '/'))) {
						image_type = pp + 1;
					} else {
						image_type = "X-EVOLUTION-UNKNOWN";
					}

					e_vcard_attribute_remove_param (attr, EVC_TYPE);
					e_vcard_attribute_remove_param (attr, EVC_ENCODING);
					e_vcard_attribute_remove_param (attr, EVC_VALUE);
					e_vcard_attribute_remove_values (attr);

					e_vcard_attribute_add_param_with_value (attr, e_vcard_attribute_param_new (EVC_TYPE), image_type);
					e_vcard_attribute_add_param_with_value (attr, e_vcard_attribute_param_new (EVC_ENCODING), "b");
					e_vcard_attribute_add_value_decoded (attr, content, len);

					g_free (mime_type);
					g_free (content);
				} else {
					success = FALSE;
				}

				g_object_unref (file);
				g_free (basename);
			}

			g_free (url);
		}
	}

	return success;
}

static gchar *
ebmb_create_photo_local_filename (EBookMetaBackend *meta_backend,
				  const gchar *uid,
				  const gchar *attr_name,
				  gint fileindex,
				  const gchar *type)
{
	EBookCache *book_cache;
	gchar *local_filename, *cache_path, *checksum, *prefix, *extension, *filename;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), NULL);
	g_return_val_if_fail (uid != NULL, NULL);
	g_return_val_if_fail (attr_name != NULL, NULL);

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, NULL);

	cache_path = g_path_get_dirname (e_cache_get_filename (E_CACHE (book_cache)));
	checksum = g_compute_checksum_for_string (G_CHECKSUM_SHA1, uid, -1);
	prefix = g_strdup_printf ("%s-%s-%d", attr_name, checksum, fileindex);

	if (type && *type)
		extension = g_uri_escape_string (type, NULL, TRUE);
	else
		extension = NULL;

	filename = g_strconcat (prefix, extension ? "." : NULL, extension, NULL);

	local_filename = g_build_filename (cache_path, filename, NULL);

	g_object_unref (book_cache);
	g_free (cache_path);
	g_free (checksum);
	g_free (prefix);
	g_free (extension);
	g_free (filename);

	return local_filename;
}

/**
 * e_book_meta_backend_store_inline_photos_sync:
 * @meta_backend: an #EBookMetaBackend
 * @contact: an #EContact to work with
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Changes all inline photos and logos to URL type in @contact, which
 * will point to a local file instead, beside the cache file.
 * This is called automatically after e_book_meta_backend_load_contact_sync().
 *
 * The reverse operation is e_book_meta_backend_inline_local_photos_sync().
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_store_inline_photos_sync (EBookMetaBackend *meta_backend,
					      EContact *contact,
					      GCancellable *cancellable,
					      GError **error)
{
	gint fileindex;
	GList *attributes, *link;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);

	attributes = e_vcard_get_attributes (E_VCARD (contact));

	for (link = attributes, fileindex = 0; link; link = g_list_next (link), fileindex++) {
		EVCardAttribute *attr = link->data;
		const gchar *attr_name;
		GList *values;

		attr_name = e_vcard_attribute_get_name (attr);
		if (!attr_name || (
		    g_ascii_strcasecmp (attr_name, EVC_PHOTO) != 0 &&
		    g_ascii_strcasecmp (attr_name, EVC_LOGO) != 0)) {
			continue;
		}

		values = e_vcard_attribute_get_param (attr, EVC_ENCODING);
		if (values && (g_ascii_strcasecmp (values->data, "b") == 0 || g_ascii_strcasecmp (values->data, "base64") == 0)) {
			values = e_vcard_attribute_get_values_decoded (attr);
			if (values && values->data) {
				const GString *decoded = values->data;
				gchar *local_filename;

				if (!decoded->len)
					continue;

				values = e_vcard_attribute_get_param (attr, EVC_TYPE);

				local_filename = ebmb_create_photo_local_filename (meta_backend, e_contact_get_const (contact, E_CONTACT_UID),
					attr_name, fileindex, values ? values->data : NULL);
				if (local_filename &&
				    g_file_set_contents (local_filename, decoded->str, decoded->len, error)) {
					gchar *url;

					e_vcard_attribute_remove_param (attr, EVC_TYPE);
					e_vcard_attribute_remove_param (attr, EVC_ENCODING);
					e_vcard_attribute_remove_param (attr, EVC_VALUE);
					e_vcard_attribute_remove_values (attr);

					url = g_filename_to_uri (local_filename, NULL, NULL);

					e_vcard_attribute_add_param_with_value (attr, e_vcard_attribute_param_new (EVC_VALUE), "uri");
					e_vcard_attribute_add_value (attr, url);

					g_free (url);
				} else {
					success = FALSE;
				}

				g_free (local_filename);
			}
		}
	}

	return success;
}

/**
 * e_book_meta_backend_empty_cache_sync:
 * @meta_backend: an #EBookMetaBackend
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Empties the local cache by removing all known contacts from it
 * and notifies about such removal any opened views.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_empty_cache_sync (EBookMetaBackend *meta_backend,
				      GCancellable *cancellable,
				      GError **error)
{
	EBookBackend *book_backend;
	EBookCache *book_cache;
	GSList *uids = NULL, *link;
	gchar *cache_path, *cache_filename;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, FALSE);

	e_cache_lock (E_CACHE (book_cache), E_CACHE_LOCK_WRITE);

	book_backend = E_BOOK_BACKEND (meta_backend);

	success = e_book_cache_search_uids (book_cache, NULL, &uids, cancellable, error);
	if (success)
		success = e_cache_remove_all (E_CACHE (book_cache), cancellable, error);

	e_cache_unlock (E_CACHE (book_cache), success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	cache_path = g_path_get_dirname (e_cache_get_filename (E_CACHE (book_cache)));
	cache_filename = g_path_get_basename (e_cache_get_filename (E_CACHE (book_cache)));

	g_object_unref (book_cache);

	if (success) {
		GDir *dir;

		for (link = uids; link; link = g_slist_next (link)) {
			const gchar *uid = link->data;

			if (!uid)
				continue;

			e_book_backend_notify_remove (book_backend, uid);
		}

		g_mutex_lock (&meta_backend->priv->property_lock);

		for (link = meta_backend->priv->cursors; link; link = g_slist_next (link)) {
			EDataBookCursor *cursor = link->data;

			e_data_book_cursor_recalculate (cursor, cancellable, NULL);
		}

		g_mutex_unlock (&meta_backend->priv->property_lock);

		/* Remove also all photos and logos stored beside the cache */
		dir = g_dir_open (cache_path, 0, NULL);
		if (dir) {
			const gchar *filename;

			while (filename = g_dir_read_name (dir), filename) {
				if ((g_str_has_prefix (filename, EVC_PHOTO) ||
				    g_str_has_prefix (filename, EVC_LOGO)) &&
				    g_strcmp0 (cache_filename, filename) != 0) {
					if (g_unlink (filename) == -1) {
						/* Something failed, ignore the error */
					}
				}
			}

			g_dir_close (dir);
		}
	}

	g_slist_free_full (uids, g_free);
	g_free (cache_filename);
	g_free (cache_path);

	return success;
}

/**
 * e_book_meta_backend_schedule_refresh:
 * @meta_backend: an #EBookMetaBackend
 *
 * Schedules refresh of the content of the @meta_backend. If there's any
 * already scheduled, then the function does nothing.
 *
 * Use e_book_meta_backend_refresh_sync() to refresh the @meta_backend
 * immediately.
 *
 * Since: 3.26
 **/
void
e_book_meta_backend_schedule_refresh (EBookMetaBackend *meta_backend)
{
	GCancellable *cancellable;

	g_return_if_fail (E_IS_BOOK_META_BACKEND (meta_backend));

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->refresh_cancellable) {
		/* Already refreshing the content */
		g_mutex_unlock (&meta_backend->priv->property_lock);
		return;
	}

	cancellable = g_cancellable_new ();
	meta_backend->priv->refresh_cancellable = g_object_ref (cancellable);

	g_mutex_unlock (&meta_backend->priv->property_lock);

	e_book_backend_schedule_custom_operation (E_BOOK_BACKEND (meta_backend), cancellable,
		ebmb_refresh_thread_func, NULL, NULL);

	g_object_unref (cancellable);
}

/**
 * e_book_meta_backend_refresh_sync:
 * @meta_backend: an #EBookMetaBackend
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Refreshes the @meta_backend immediately. To just schedule refresh
 * operation call e_book_meta_backend_schedule_refresh().
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_refresh_sync (EBookMetaBackend *meta_backend,
				  GCancellable *cancellable,
				  GError **error)
{
	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	return ebmb_refresh_internal_sync (meta_backend, TRUE, cancellable, error);
}

/**
 * e_book_meta_backend_ensure_connected_sync:
 * @meta_backend: an #EBookMetaBackend
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Ensures that the @meta_backend is connected to its destination.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_ensure_connected_sync (EBookMetaBackend *meta_backend,
					   GCancellable *cancellable,
					   GError **error)
{
	ENamedParameters *credentials;
	ESource *source;
	ESourceAuthenticationResult auth_result = E_SOURCE_AUTHENTICATION_UNKNOWN;
	ESourceCredentialsReason creds_reason = E_SOURCE_CREDENTIALS_REASON_ERROR;
	gchar *certificate_pem = NULL;
	GTlsCertificateFlags certificate_errors = 0;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	if (!e_backend_get_online (E_BACKEND (meta_backend))) {
		g_set_error_literal (error, E_CLIENT_ERROR, E_CLIENT_ERROR_REPOSITORY_OFFLINE,
			e_client_error_to_string (E_CLIENT_ERROR_REPOSITORY_OFFLINE));

		return FALSE;
	}

	g_mutex_lock (&meta_backend->priv->property_lock);
	credentials = e_named_parameters_new_clone (meta_backend->priv->last_credentials);
	g_mutex_unlock (&meta_backend->priv->property_lock);

	g_mutex_lock (&meta_backend->priv->connect_lock);

	source = e_backend_get_source (E_BACKEND (meta_backend));

	if (e_source_get_connection_status (source) != E_SOURCE_CONNECTION_STATUS_CONNECTED)
		e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_CONNECTING);

	if (e_book_meta_backend_connect_sync (meta_backend, credentials, &auth_result, &certificate_pem, &certificate_errors,
		cancellable, &local_error)) {
		ebmb_update_connection_values (meta_backend);
		e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_CONNECTED);
		g_mutex_unlock (&meta_backend->priv->connect_lock);
		e_named_parameters_free (credentials);

		return TRUE;
	}

	e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);

	g_mutex_unlock (&meta_backend->priv->connect_lock);

	e_named_parameters_free (credentials);

	g_warn_if_fail (auth_result != E_SOURCE_AUTHENTICATION_ACCEPTED);

	if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_HOST_NOT_FOUND)) {
		e_backend_set_online (E_BACKEND (meta_backend), FALSE);
		g_propagate_error (error, local_error);
		g_free (certificate_pem);

		return FALSE;
	}

	switch (auth_result) {
	case E_SOURCE_AUTHENTICATION_UNKNOWN:
		if (local_error)
			g_propagate_error (error, local_error);
		g_free (certificate_pem);
		return FALSE;
	case E_SOURCE_AUTHENTICATION_ERROR:
		creds_reason = E_SOURCE_CREDENTIALS_REASON_ERROR;
		break;
	case E_SOURCE_AUTHENTICATION_ERROR_SSL_FAILED:
		creds_reason = E_SOURCE_CREDENTIALS_REASON_SSL_FAILED;
		break;
	case E_SOURCE_AUTHENTICATION_ACCEPTED:
		g_warn_if_reached ();
		break;
	case E_SOURCE_AUTHENTICATION_REJECTED:
		creds_reason = E_SOURCE_CREDENTIALS_REASON_REJECTED;
		break;
	case E_SOURCE_AUTHENTICATION_REQUIRED:
		creds_reason = E_SOURCE_CREDENTIALS_REASON_REQUIRED;
		break;
	}

	e_backend_schedule_credentials_required (E_BACKEND (meta_backend), creds_reason, certificate_pem, certificate_errors,
		local_error, cancellable, G_STRFUNC);

	g_clear_error (&local_error);
	g_free (certificate_pem);

	return FALSE;
}

/**
 * e_book_meta_backend_split_changes_sync:
 * @meta_backend: an #EBookMetaBackend
 * @objects: (inout caller-allocates) (element-type EBookMetaBackendInfo):
 *    a #GSList of #EBookMetaBackendInfo object infos to split
 * @out_created_objects: (out) (element-type EBookMetaBackendInfo) (transfer full):
 *    a #GSList of #EBookMetaBackendInfo object infos which had been created
 * @out_modified_objects: (out) (element-type EBookMetaBackendInfo) (transfer full):
 *    a #GSList of #EBookMetaBackendInfo object infos which had been modified
 * @out_removed_objects: (out) (element-type EBookMetaBackendInfo) (transfer full) (nullable):
 *    a #GSList of #EBookMetaBackendInfo object infos which had been removed;
 *    it can be %NULL, to not gather list of removed object infos
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Splits @objects into created/modified/removed lists according to current local
 * cache content. Only the @out_removed_objects can be %NULL, others cannot.
 * The function modifies @objects by moving its 'data' to corresponding out
 * lists and sets the @objects 'data' to %NULL.
 *
 * Each output #GSList should be freed with
 * g_slist_free_full (objects, e_book_meta_backend_info_free);
 * when no longer needed.
 *
 * The caller is still responsible to free @objects as well.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_split_changes_sync (EBookMetaBackend *meta_backend,
					GSList *objects,
					GSList **out_created_objects,
					GSList **out_modified_objects,
					GSList **out_removed_objects,
					GCancellable *cancellable,
					GError **error)
{
	GHashTable *locally_cached; /* EContactId * ~> gchar *revision */
	GHashTableIter iter;
	GSList *link;
	EBookCache *book_cache;
	gpointer key, value;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_created_objects, FALSE);
	g_return_val_if_fail (out_modified_objects, FALSE);

	*out_created_objects = NULL;
	*out_modified_objects = NULL;

	if (out_removed_objects)
		*out_removed_objects = NULL;

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, FALSE);

	locally_cached = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);

	if (!e_book_cache_search_with_callback (book_cache, NULL,
		ebmb_gather_locally_cached_objects_cb, locally_cached, cancellable, error)) {
		g_hash_table_destroy (locally_cached);
		g_object_unref (book_cache);
		return FALSE;
	}

	for (link = objects; link; link = g_slist_next (link)) {
		EBookMetaBackendInfo *nfo = link->data;

		if (!nfo)
			continue;

		if (!g_hash_table_contains (locally_cached, nfo->uid)) {
			link->data = NULL;

			*out_created_objects = g_slist_prepend (*out_created_objects, nfo);
		} else {
			const gchar *local_revision = g_hash_table_lookup (locally_cached, nfo->uid);

			if (g_strcmp0 (local_revision, nfo->revision) != 0) {
				link->data = NULL;

				*out_modified_objects = g_slist_prepend (*out_modified_objects, nfo);
			}

			g_hash_table_remove (locally_cached, nfo->uid);
		}
	}

	if (out_removed_objects) {
		/* What left in the hash table is removed from the remote side */
		g_hash_table_iter_init (&iter, locally_cached);
		while (g_hash_table_iter_next (&iter, &key, &value)) {
			const gchar *uid = key;
			const gchar *revision = value;
			EBookMetaBackendInfo *nfo;

			if (!uid) {
				g_warn_if_reached ();
				continue;
			}

			nfo = e_book_meta_backend_info_new (uid, revision, NULL, NULL);
			*out_removed_objects = g_slist_prepend (*out_removed_objects, nfo);
		}

		*out_removed_objects = g_slist_reverse (*out_removed_objects);
	}

	g_hash_table_destroy (locally_cached);
	g_object_unref (book_cache);

	*out_created_objects = g_slist_reverse (*out_created_objects);
	*out_modified_objects = g_slist_reverse (*out_modified_objects);

	return TRUE;
}

/**
 * e_book_meta_backend_process_changes_sync:
 * @meta_backend: an #EBookMetaBackend
 * @created_objects: (element-type EBookMetaBackendInfo) (nullable):
 *    a #GSList of #EBookMetaBackendInfo object infos which had been created
 * @modified_objects: (element-type EBookMetaBackendInfo) (nullable):
 *    a #GSList of #EBookMetaBackendInfo object infos which had been modified
 * @removed_objects: (element-type EBookMetaBackendInfo) (nullable):
 *    a #GSList of #EBookMetaBackendInfo object infos which had been removed
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Processes given changes by updating local cache content accordingly.
 * The @meta_backend processes the changes like being online and particularly
 * requires to be online to load created and modified objects when needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_process_changes_sync (EBookMetaBackend *meta_backend,
					  const GSList *created_objects,
					  const GSList *modified_objects,
					  const GSList *removed_objects,
					  GCancellable *cancellable,
					  GError **error)
{
	EBookCache *book_cache;
	GHashTable *covered_uids;
	GString *invalid_objects = NULL;
	GSList *link;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	book_cache = e_book_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (book_cache != NULL, FALSE);

	covered_uids = g_hash_table_new (g_str_hash, g_str_equal);

	/* Removed objects first */
	for (link = (GSList *) removed_objects; link && success; link = g_slist_next (link)) {
		EBookMetaBackendInfo *nfo = link->data;

		if (!nfo) {
			g_warn_if_reached ();
			continue;
		}

		success = ebmb_maybe_remove_from_cache (meta_backend, book_cache, E_CACHE_IS_ONLINE, nfo->uid, cancellable, error);
	}

	/* Then modified objects */
	for (link = (GSList *) modified_objects; link && success; link = g_slist_next (link)) {
		EBookMetaBackendInfo *nfo = link->data;
		GError *local_error = NULL;

		if (!nfo || !nfo->uid) {
			g_warn_if_reached ();
			continue;
		}

		if (!*nfo->uid ||
		    g_hash_table_contains (covered_uids, nfo->uid))
			continue;

		g_hash_table_insert (covered_uids, nfo->uid, NULL);

		success = ebmb_load_contact_wrapper_sync (meta_backend, book_cache, nfo->uid, nfo->object, nfo->extra, NULL, cancellable, &local_error);

		/* Do not stop on invalid objects, just notify about them later, and load as many as possible */
		if (!success && g_error_matches (local_error, E_DATA_BOOK_ERROR, E_DATA_BOOK_STATUS_INVALID_ARG)) {
			if (!invalid_objects) {
				invalid_objects = g_string_new (local_error->message);
			} else {
				g_string_append_c (invalid_objects, '\n');
				g_string_append (invalid_objects, local_error->message);
			}
			g_clear_error (&local_error);
			success = TRUE;
		} else if (local_error) {
			g_propagate_error (error, local_error);
		}
	}

	g_hash_table_remove_all (covered_uids);

	/* Finally created objects */
	for (link = (GSList *) created_objects; link && success; link = g_slist_next (link)) {
		EBookMetaBackendInfo *nfo = link->data;
		GError *local_error = NULL;

		if (!nfo || !nfo->uid) {
			g_warn_if_reached ();
			continue;
		}

		if (!*nfo->uid)
			continue;

		success = ebmb_load_contact_wrapper_sync (meta_backend, book_cache, nfo->uid, nfo->object, nfo->extra, NULL, cancellable, &local_error);

		/* Do not stop on invalid objects, just notify about them later, and load as many as possible */
		if (!success && g_error_matches (local_error, E_DATA_BOOK_ERROR, E_DATA_BOOK_STATUS_INVALID_ARG)) {
			if (!invalid_objects) {
				invalid_objects = g_string_new (local_error->message);
			} else {
				g_string_append_c (invalid_objects, '\n');
				g_string_append (invalid_objects, local_error->message);
			}
			g_clear_error (&local_error);
			success = TRUE;
		} else if (local_error) {
			g_propagate_error (error, local_error);
		}
	}

	g_hash_table_destroy (covered_uids);

	if (invalid_objects) {
		e_book_backend_notify_error (E_BOOK_BACKEND (meta_backend), invalid_objects->str);

		g_string_free (invalid_objects, TRUE);
	}

	g_clear_object (&book_cache);

	return success;
}

/**
 * e_book_meta_backend_connect_sync:
 * @meta_backend: an #EBookMetaBackend
 * @credentials: (nullable): an #ENamedParameters with previously used credentials, or %NULL
 * @out_auth_result: (out): an #ESourceAuthenticationResult with an authentication result
 * @out_certificate_pem: (out) (transfer full): a PEM encoded certificate on failure, or %NULL
 * @out_certificate_errors: (out): a #GTlsCertificateFlags on failure, or 0
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * This is called always before any operation which requires a connection
 * to the remote side. It can fail with an #E_CLIENT_ERROR_REPOSITORY_OFFLINE
 * error to indicate that the remote side cannot be currently reached. Other
 * errors are propagated to the caller/client side. This method is not called
 * when the backend is offline.
 *
 * The descendant should also call e_book_backend_set_writable() after successful
 * connect to the remote side. This value is stored for later use, when being
 * opened offline.
 *
 * The @credentials parameter consists of the previously used credentials.
 * It's always %NULL with the first connection attempt. To get the credentials,
 * just set the @out_auth_result to %E_SOURCE_AUTHENTICATION_REQUIRED for
 * the first time and the function will be called again once the credentials
 * are available. See the documentation of #ESourceAuthenticationResult for
 * other available results.
 *
 * The out parameters are passed to e_backend_schedule_credentials_required()
 * and are ignored when the descendant returns %TRUE, aka they are used
 * only if the connection fails. The @out_certificate_pem and @out_certificate_errors
 * should be used together and they can be left untouched if the failure reason was
 * not related to certificate. Use @out_auth_result %E_SOURCE_AUTHENTICATION_UNKNOWN
 * to indicate other error than @credentials error, otherwise the @error is used
 * according to @out_auth_result value.
 *
 * It is mandatory to implement this virtual method by the descendant.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_connect_sync (EBookMetaBackend *meta_backend,
				  const ENamedParameters *credentials,
				  ESourceAuthenticationResult *out_auth_result,
				  gchar **out_certificate_pem,
				  GTlsCertificateFlags *out_certificate_errors,
				  GCancellable *cancellable,
				  GError **error)
{
	EBookMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	klass = E_BOOK_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->connect_sync != NULL, FALSE);

	return klass->connect_sync (meta_backend, credentials, out_auth_result, out_certificate_pem, out_certificate_errors, cancellable, error);
}

/**
 * e_book_meta_backend_disconnect_sync:
 * @meta_backend: an #EBookMetaBackend
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * This is called when the backend goes into offline mode or
 * when the disconnect is required. The implementation should
 * not report any error when it is called and the @meta_backend
 * is not connected.
 *
 * It is mandatory to implement this virtual method by the descendant.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_disconnect_sync (EBookMetaBackend *meta_backend,
				     GCancellable *cancellable,
				     GError **error)
{
	EBookMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	klass = E_BOOK_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->disconnect_sync != NULL, FALSE);

	return klass->disconnect_sync (meta_backend, cancellable, error);
}

/**
 * e_book_meta_backend_get_changes_sync:
 * @meta_backend: an #EBookMetaBackend
 * @last_sync_tag: (nullable): optional sync tag from the last check
 * @is_repeat: set to %TRUE when this is the repeated call
 * @out_new_sync_tag: (out) (transfer full): new sync tag to store on success
 * @out_repeat: (out): whether to repeat this call again; default is %FALSE
 * @out_created_objects: (out) (element-type EBookMetaBackendInfo) (transfer full):
 *    a #GSList of #EBookMetaBackendInfo object infos which had been created since
 *    the last check
 * @out_modified_objects: (out) (element-type EBookMetaBackendInfo) (transfer full):
 *    a #GSList of #EBookMetaBackendInfo object infos which had been modified since
 *    the last check
 * @out_removed_objects: (out) (element-type EBookMetaBackendInfo) (transfer full):
 *    a #GSList of #EBookMetaBackendInfo object infos which had been removed since
 *    the last check
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gathers the changes since the last check which had been done
 * on the remote side.
 *
 * The @last_sync_tag can be used as a tag of the last check. This can be %NULL,
 * when there was no previous call or when the descendant doesn't store any
 * such tags. The @out_new_sync_tag can be populated with a value to be stored
 * and used the next time.
 *
 * The @out_repeat can be set to %TRUE when the descendant didn't finish
 * read of all the changes. In that case the @meta_backend calls this
 * function again with the @out_new_sync_tag as the @last_sync_tag, but also
 * notifies about the found changes immediately. The @is_repeat is set
 * to %TRUE as well in this case, otherwise it's %FALSE.
 *
 * The descendant can populate also EBookMetaBackendInfo::object of
 * the @out_created_objects and @out_modified_objects, if known, in which
 * case this will be used instead of loading it with e_book_meta_backend_load_contact_sync().
 *
 * It is optional to implement this virtual method by the descendant.
 * The default implementation calls e_book_meta_backend_list_existing_sync()
 * and then compares the list with the current content of the local cache
 * and populates the respective lists appropriately.
 *
 * Each output #GSList should be freed with
 * g_slist_free_full (objects, e_book_meta_backend_info_free);
 * when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_get_changes_sync (EBookMetaBackend *meta_backend,
				      const gchar *last_sync_tag,
				      gboolean is_repeat,
				      gchar **out_new_sync_tag,
				      gboolean *out_repeat,
				      GSList **out_created_objects,
				      GSList **out_modified_objects,
				      GSList **out_removed_objects,
				      GCancellable *cancellable,
				      GError **error)
{
	EBookMetaBackendClass *klass;
	gint repeat_count = 0;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_new_sync_tag != NULL, FALSE);
	g_return_val_if_fail (out_repeat != NULL, FALSE);
	g_return_val_if_fail (out_created_objects != NULL, FALSE);
	g_return_val_if_fail (out_created_objects != NULL, FALSE);
	g_return_val_if_fail (out_modified_objects != NULL, FALSE);
	g_return_val_if_fail (out_removed_objects != NULL, FALSE);

	klass = E_BOOK_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->get_changes_sync != NULL, FALSE);

	while (!success && repeat_count <= MAX_REPEAT_COUNT) {
		guint wait_credentials_stamp;

		g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
		wait_credentials_stamp = meta_backend->priv->wait_credentials_stamp;
		g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);

		g_clear_error (&local_error);
		repeat_count++;

		success = klass->get_changes_sync (meta_backend,
			last_sync_tag,
			is_repeat,
			out_new_sync_tag,
			out_repeat,
			out_created_objects,
			out_modified_objects,
			out_removed_objects,
			cancellable,
			&local_error);

		if (!success && repeat_count <= MAX_REPEAT_COUNT && !ebmb_maybe_wait_for_credentials (meta_backend, wait_credentials_stamp, local_error, cancellable))
			break;
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

/**
 * e_book_meta_backend_list_existing_sync:
 * @meta_backend: an #EBookMetaBackend
 * @out_new_sync_tag: (out) (transfer full): optional return location for a new sync tag
 * @out_existing_objects: (out) (element-type EBookMetaBackendInfo) (transfer full):
 *    a #GSList of #EBookMetaBackendInfo object infos which are stored on the remote side
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Used to get list of all existing objects on the remote side. The descendant
 * can optionally provide @out_new_sync_tag, which will be stored on success, if
 * not %NULL. The descendant can populate also EBookMetaBackendInfo::object of
 * the @out_existing_objects, if known, in which case this will be used instead
 * of loading it with e_book_meta_backend_load_contact_sync().
 *
 * It is mandatory to implement this virtual method by the descendant, unless
 * it implements its own #EBookMetaBackendClass.get_changes_sync().
 *
 * The @out_existing_objects #GSList should be freed with
 * g_slist_free_full (objects, e_book_meta_backend_info_free);
 * when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_list_existing_sync (EBookMetaBackend *meta_backend,
				        gchar **out_new_sync_tag,
				        GSList **out_existing_objects,
				        GCancellable *cancellable,
				        GError **error)
{
	EBookMetaBackendClass *klass;
	gint repeat_count = 0;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_existing_objects != NULL, FALSE);

	klass = E_BOOK_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->list_existing_sync != NULL, FALSE);


	while (!success && repeat_count <= MAX_REPEAT_COUNT) {
		guint wait_credentials_stamp;

		g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
		wait_credentials_stamp = meta_backend->priv->wait_credentials_stamp;
		g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);

		g_clear_error (&local_error);
		repeat_count++;

		success = klass->list_existing_sync (meta_backend, out_new_sync_tag, out_existing_objects, cancellable, &local_error);

		if (!success && repeat_count <= MAX_REPEAT_COUNT && !ebmb_maybe_wait_for_credentials (meta_backend, wait_credentials_stamp, local_error, cancellable))
			break;
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

/**
 * e_book_meta_backend_load_contact_sync:
 * @meta_backend: an #EBookMetaBackend
 * @uid: a contact UID
 * @extra: (nullable): optional extra data stored with the contact, or %NULL
 * @out_contact: (out) (transfer full): a loaded contact, as an #EContact
 * @out_extra: (out) (transfer full): an extra data to store to #EBookCache with this contact
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Loads a contact from the remote side.
 *
 * It is mandatory to implement this virtual method by the descendant.
 *
 * The returned @out_contact should be freed with g_object_unref(),
 * when no longer needed.
 *
 * The returned @out_extra should be freed with g_free(), when no longer
 * needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_load_contact_sync (EBookMetaBackend *meta_backend,
				       const gchar *uid,
				       const gchar *extra,
				       EContact **out_contact,
				       gchar **out_extra,
				       GCancellable *cancellable,
				       GError **error)
{
	EBookMetaBackendClass *klass;
	gint repeat_count = 0;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_contact != NULL, FALSE);
	g_return_val_if_fail (out_extra != NULL, FALSE);

	klass = E_BOOK_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->load_contact_sync != NULL, FALSE);


	while (!success && repeat_count <= MAX_REPEAT_COUNT) {
		guint wait_credentials_stamp;

		g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
		wait_credentials_stamp = meta_backend->priv->wait_credentials_stamp;
		g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);

		g_clear_error (&local_error);
		repeat_count++;

		success = klass->load_contact_sync (meta_backend, uid, extra, out_contact, out_extra, cancellable, &local_error);

		if (!success && repeat_count <= MAX_REPEAT_COUNT && !ebmb_maybe_wait_for_credentials (meta_backend, wait_credentials_stamp, local_error, cancellable))
			break;
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

/**
 * e_book_meta_backend_save_contact_sync:
 * @meta_backend: an #EBookMetaBackend
 * @overwrite_existing: %TRUE when can overwrite existing contacts, %FALSE otherwise
 * @conflict_resolution: one of #EConflictResolution, what to do on conflicts
 * @contact: an #EContact to save
 * @extra: (nullable): extra data saved with the contacts in an #EBookCache
 * @out_new_uid: (out) (transfer full): return location for the UID of the saved contact
 * @out_new_extra: (out) (transfer full): return location for the extra data to store with the contact
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Saves one contact into the remote side.  When the @overwrite_existing is %TRUE, then
 * the descendant can overwrite an object with the same UID on the remote side
 * (usually used for modify). The @conflict_resolution defines what to do when
 * the remote side had made any changes to the object since the last update.
 *
 * The @contact has already converted locally stored photos and logos
 * into inline variants, thus it's not needed to call
 * e_book_meta_backend_inline_local_photos_sync() by the descendant.
 *
 * The @out_new_uid can be populated with a UID of the saved contact as the server
 * assigned it to it. This UID, if set, is loaded from the remote side afterwards,
 * also to see whether any changes had been made to the contact by the remote side.
 *
 * The @out_new_extra can be populated with a new extra data to save with the contact.
 * Left it %NULL, to keep the same value as the @extra.
 *
 * The descendant can use an #E_CLIENT_ERROR_OUT_OF_SYNC error to indicate that
 * the save failed due to made changes on the remote side, and let the @meta_backend
 * resolve this conflict based on the @conflict_resolution on its own.
 * The #E_CLIENT_ERROR_OUT_OF_SYNC error should not be used when the descendant
 * is able to resolve the conflicts itself.
 *
 * It is mandatory to implement this virtual method by the writable descendant.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_save_contact_sync (EBookMetaBackend *meta_backend,
				       gboolean overwrite_existing,
				       EConflictResolution conflict_resolution,
				       /* const */ EContact *contact,
				       const gchar *extra,
				       gchar **out_new_uid,
				       gchar **out_new_extra,
				       GCancellable *cancellable,
				       GError **error)
{
	EBookMetaBackendClass *klass;
	gint repeat_count = 0;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);
	g_return_val_if_fail (out_new_uid != NULL, FALSE);
	g_return_val_if_fail (out_new_extra != NULL, FALSE);

	klass = E_BOOK_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);

	if (!klass->save_contact_sync) {
		g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_NOT_SUPPORTED, NULL));
		return FALSE;
	}


	while (!success && repeat_count <= MAX_REPEAT_COUNT) {
		guint wait_credentials_stamp;

		g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
		wait_credentials_stamp = meta_backend->priv->wait_credentials_stamp;
		g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);

		g_clear_error (&local_error);
		repeat_count++;

		success = klass->save_contact_sync (meta_backend,
			overwrite_existing,
			conflict_resolution,
			contact,
			extra,
			out_new_uid,
			out_new_extra,
			cancellable,
			&local_error);

		if (!success && repeat_count <= MAX_REPEAT_COUNT && !ebmb_maybe_wait_for_credentials (meta_backend, wait_credentials_stamp, local_error, cancellable))
			break;
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

/**
 * e_book_meta_backend_remove_contact_sync:
 * @meta_backend: an #EBookMetaBackend
 * @conflict_resolution: an #EConflictResolution to use
 * @uid: a contact UID
 * @extra: (nullable): extra data being saved with the contact in the local cache, or %NULL
 * @object: (nullable): corresponding vCard object, as stored in the local cache, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Removes a contact from the remote side. The @object is not %NULL when
 * it's removing locally deleted object in offline mode. Being it %NULL,
 * the descendant can obtain the object from the #EBookCache.
 *
 * It is mandatory to implement this virtual method by the writable descendant.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_remove_contact_sync (EBookMetaBackend *meta_backend,
					 EConflictResolution conflict_resolution,
					 const gchar *uid,
					 const gchar *extra,
					 const gchar *object,
					 GCancellable *cancellable,
					 GError **error)
{
	EBookMetaBackendClass *klass;
	gint repeat_count = 0;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	klass = E_BOOK_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);

	if (!klass->remove_contact_sync) {
		g_propagate_error (error, e_data_book_create_error (E_DATA_BOOK_STATUS_NOT_SUPPORTED, NULL));
		return FALSE;
	}


	while (!success && repeat_count <= MAX_REPEAT_COUNT) {
		guint wait_credentials_stamp;

		g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
		wait_credentials_stamp = meta_backend->priv->wait_credentials_stamp;
		g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);

		g_clear_error (&local_error);
		repeat_count++;

		success = klass->remove_contact_sync (meta_backend, conflict_resolution, uid, extra, object, cancellable, &local_error);

		if (!success && repeat_count <= MAX_REPEAT_COUNT && !ebmb_maybe_wait_for_credentials (meta_backend, wait_credentials_stamp, local_error, cancellable))
			break;
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

/**
 * e_book_meta_backend_search_sync:
 * @meta_backend: an #EBookMetaBackend
 * @expr: (nullable): a search expression, or %NULL
 * @meta_contact: %TRUE, when return #EContact filled with UID and REV only, %FALSE to return full contacts
 * @out_contacts: (out) (transfer full) (element-type EContact): return location for the found contacts as #EContact
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Searches @meta_backend with given expression @expr and returns
 * found contacts as a #GSList of #EContact @out_contacts.
 * Free the returned @out_contacts with g_slist_free_full (contacts, g_object_unref);
 * when no longer needed.
 * When the @expr is %NULL, all objects are returned. To get
 * UID-s instead, call e_book_meta_backend_search_uids_sync().
 *
 * It is optional to implement this virtual method by the descendant.
 * The default implementation searches @meta_backend's cache. It's also
 * not required to be online for searching, thus @meta_backend doesn't
 * ensure it.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_search_sync (EBookMetaBackend *meta_backend,
				 const gchar *expr,
				 gboolean meta_contact,
				 GSList **out_contacts,
				 GCancellable *cancellable,
				 GError **error)
{
	EBookMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_contacts != NULL, FALSE);

	klass = E_BOOK_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->search_sync != NULL, FALSE);

	return klass->search_sync (meta_backend, expr, meta_contact, out_contacts, cancellable, error);
}

/**
 * e_book_meta_backend_search_uids_sync:
 * @meta_backend: an #EBookMetaBackend
 * @expr: (nullable): a search expression, or %NULL
 * @out_uids: (out) (transfer full) (element-type utf8): return location for the found contact UID-s
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Searches @meta_backend with given expression @expr and returns
 * found contact UID-s as a #GSList @out_contacts.
 * Free the returned @out_uids with g_slist_free_full (uids, g_free);
 * when no longer needed.
 * When the @expr is %NULL, all UID-s are returned. To get #EContact(s)
 * instead, call e_book_meta_backend_search_sync().
 *
 * It is optional to implement this virtual method by the descendant.
 * The default implementation searches @meta_backend's cache. It's also
 * not required to be online for searching, thus @meta_backend doesn't
 * ensure it.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_search_uids_sync (EBookMetaBackend *meta_backend,
				      const gchar *expr,
				      GSList **out_uids,
				      GCancellable *cancellable,
				      GError **error)
{
	EBookMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_uids != NULL, FALSE);

	klass = E_BOOK_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->search_uids_sync != NULL, FALSE);

	return klass->search_uids_sync (meta_backend, expr, out_uids, cancellable, error);
}

/**
 * e_book_meta_backend_requires_reconnect:
 * @meta_backend: an #EBookMetaBackend
 *
 * Determines, whether current source content requires reconnect of the backend.
 *
 * It is optional to implement this virtual method by the descendant. The default
 * implementation compares %E_SOURCE_EXTENSION_AUTHENTICATION and
 * %E_SOURCE_EXTENSION_WEBDAV_BACKEND, if existing in the source,
 * with the values after the last successful connect and returns
 * %TRUE when they changed. It always return %TRUE when there was
 * no successful connect done yet.
 *
 * Returns: %TRUE, when reconnect is required, %FALSE otherwise.
 *
 * Since: 3.26
 **/
gboolean
e_book_meta_backend_requires_reconnect (EBookMetaBackend *meta_backend)
{
	EBookMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	klass = E_BOOK_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->requires_reconnect != NULL, FALSE);

	return klass->requires_reconnect (meta_backend);
}

/**
 * e_book_meta_backend_get_ssl_error_details:
 * @meta_backend: an #EBookMetaBackend
 * @out_certificate_pem: (out): SSL certificate encoded in PEM format
 * @out_certificate_errors: (out): bit-or of #GTlsCertificateFlags claiming the certificate errors
 *
 * It is optional to implement this virtual method by the descendants.
 * It is used to receive SSL error details when any online operation
 * returns E_DATA_BOOK_ERROR, E_DATA_BOOK_STATUS_TLS_NOT_AVAILABLE error.
 *
 * Returns: %TRUE, when the SSL error details had been available and
 *    the out parameters populated, %FALSE otherwise.
 *
 * Since: 3.28
 **/
gboolean
e_book_meta_backend_get_ssl_error_details (EBookMetaBackend *meta_backend,
					   gchar **out_certificate_pem,
					   GTlsCertificateFlags *out_certificate_errors)
{
	EBookMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_BOOK_META_BACKEND (meta_backend), FALSE);

	klass = E_BOOK_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->get_ssl_error_details != NULL, FALSE);

	return klass->get_ssl_error_details (meta_backend, out_certificate_pem, out_certificate_errors);
}
