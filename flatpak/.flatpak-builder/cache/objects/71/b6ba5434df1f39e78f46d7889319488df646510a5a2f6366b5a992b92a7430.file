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
 * SECTION: e-cal-meta-backend
 * @include: libedata-cal/libedata-cal.h
 * @short_description: An #ECalBackend descendant for calendar backends
 *
 * The #ECalMetaBackend is an abstract #ECalBackend descendant which
 * aims to implement all evolution-data-server internals for the backend
 * itself and lefts the backend do as minimum work as possible, like
 * loading and saving components, listing available components and so on,
 * thus the backend implementation can focus on things like converting
 * (possibly) remote data into iCalendar objects and back.
 *
 * As the #ECalMetaBackend uses an #ECalCache, the offline support
 * is provided by default.
 *
 * The structure is thread safe.
 **/

#include "evolution-data-server-config.h"

#include <glib.h>
#include <glib/gi18n-lib.h>

#include "e-cal-backend-sexp.h"
#include "e-cal-backend-sync.h"
#include "e-cal-backend-util.h"
#include "e-cal-meta-backend.h"

#define ECMB_KEY_SYNC_TAG		"ecmb::sync-tag"
#define ECMB_KEY_EVER_CONNECTED		"ecmb::ever-connected"
#define ECMB_KEY_CONNECTED_WRITABLE	"ecmb::connected-writable"

#define LOCAL_PREFIX "file://"

/* How many times can repeat an operation when credentials fail. */
#define MAX_REPEAT_COUNT 3

/* How long to wait for credentials, in seconds, during the operation repeat cycle */
#define MAX_WAIT_FOR_CREDENTIALS_SECS 60

struct _ECalMetaBackendPrivate {
	GMutex connect_lock;
	GMutex property_lock;
	GMutex wait_credentials_lock;
	GCond wait_credentials_cond;
	guint wait_credentials_stamp;
	GError *create_cache_error;
	ECalCache *cache;
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
	gulong get_timezone_id;
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

/* To be able to call the ECalBackend implementation, which stores zones only in the memory */
static icaltimezone *	(* ecmb_timezone_cache_parent_get_timezone) (ETimezoneCache *cache,
								     const gchar *tzid);
static GList *		(* ecmb_timezone_cache_parent_list_timezones) (ETimezoneCache *cache);

/* Forward Declarations */
static void e_cal_meta_backend_timezone_cache_init (ETimezoneCacheInterface *iface);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE (ECalMetaBackend, e_cal_meta_backend, E_TYPE_CAL_BACKEND_SYNC,
	G_IMPLEMENT_INTERFACE (E_TYPE_TIMEZONE_CACHE, e_cal_meta_backend_timezone_cache_init))

G_DEFINE_BOXED_TYPE (ECalMetaBackendInfo, e_cal_meta_backend_info, e_cal_meta_backend_info_copy, e_cal_meta_backend_info_free)

static void ecmb_schedule_source_changed (ECalMetaBackend *meta_backend);
static void ecmb_schedule_go_offline (ECalMetaBackend *meta_backend);
static gboolean ecmb_load_component_wrapper_sync (ECalMetaBackend *meta_backend,
						  ECalCache *cal_cache,
						  const gchar *uid,
						  const gchar *preloaded_object,
						  const gchar *preloaded_extra,
						  gchar **out_new_uid,
						  GCancellable *cancellable,
						  GError **error);
static gboolean ecmb_save_component_wrapper_sync (ECalMetaBackend *meta_backend,
						  ECalCache *cal_cache,
						  gboolean overwrite_existing,
						  EConflictResolution conflict_resolution,
						  const GSList *in_instances,
						  const gchar *extra,
						  const gchar *orig_uid,
						  gboolean *out_requires_put,
						  gchar **out_new_uid,
						  gchar **out_new_extra,
						  GCancellable *cancellable,
						  GError **error);

/**
 * e_cal_meta_backend_info_new:
 * @uid: a component UID; cannot be %NULL
 * @revision: (nullable): the component revision; can be %NULL
 * @object: (nullable): the component object as an iCalendar string; can be %NULL
 * @extra: (nullable): extra backend-specific data; can be %NULL
 *
 * Creates a new #ECalMetaBackendInfo prefilled with the given values.
 *
 * Returns: (transfer full): A new #ECalMetaBackendInfo. Free it with
 *    e_cal_meta_backend_info_free(), when no longer needed.
 *
 * Since: 3.26
 **/
ECalMetaBackendInfo *
e_cal_meta_backend_info_new (const gchar *uid,
			     const gchar *revision,
			     const gchar *object,
			     const gchar *extra)
{
	ECalMetaBackendInfo *info;

	g_return_val_if_fail (uid != NULL, NULL);

	info = g_new0 (ECalMetaBackendInfo, 1);
	info->uid = g_strdup (uid);
	info->revision = g_strdup (revision);
	info->object = g_strdup (object);
	info->extra = g_strdup (extra);

	return info;
}

/**
 * e_cal_meta_backend_info_copy:
 * @src: (nullable): a source ECalMetaBackendInfo to copy, or %NULL
 *
 * Returns: (transfer full): Copy of the given @src. Free it with
 *    e_cal_meta_backend_info_free() when no longer needed.
 *    If the @src is %NULL, then returns %NULL as well.
 *
 * Since: 3.26
 **/
ECalMetaBackendInfo *
e_cal_meta_backend_info_copy (const ECalMetaBackendInfo *src)
{
	if (!src)
		return NULL;

	return e_cal_meta_backend_info_new (src->uid, src->revision, src->object, src->extra);
}

/**
 * e_cal_meta_backend_info_free:
 * @ptr: (nullable): an #ECalMetaBackendInfo
 *
 * Frees the @ptr structure, previously allocated with e_cal_meta_backend_info_new()
 * or e_cal_meta_backend_info_copy().
 *
 * Since: 3.26
 **/
void
e_cal_meta_backend_info_free (gpointer ptr)
{
	ECalMetaBackendInfo *info = ptr;

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
ecmb_create_view_cancellable (ECalMetaBackend *meta_backend,
			      EDataCalView *view)
{
	GCancellable *cancellable;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), NULL);
	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), NULL);

	g_mutex_lock (&meta_backend->priv->property_lock);

	cancellable = g_cancellable_new ();
	g_hash_table_insert (meta_backend->priv->view_cancellables, view, g_object_ref (cancellable));

	g_mutex_unlock (&meta_backend->priv->property_lock);

	return cancellable;
}

static GCancellable *
ecmb_steal_view_cancellable (ECalMetaBackend *meta_backend,
			     EDataCalView *view)
{
	GCancellable *cancellable;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), NULL);
	g_return_val_if_fail (E_IS_DATA_CAL_VIEW (view), NULL);

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
ecmb_update_connection_values (ECalMetaBackend *meta_backend)
{
	ESource *source;

	g_return_if_fail (E_IS_CAL_META_BACKEND (meta_backend));

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

	e_cal_meta_backend_set_ever_connected (meta_backend, TRUE);
	e_cal_meta_backend_set_connected_writable (meta_backend, e_cal_backend_get_writable (E_CAL_BACKEND (meta_backend)));
}

static gboolean
ecmb_gather_locally_cached_objects_cb (ECalCache *cal_cache,
				       const gchar *uid,
				       const gchar *rid,
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
			e_cal_component_id_new (uid, rid),
			g_strdup (revision));
	}

	return TRUE;
}

static gboolean
ecmb_get_changes_sync (ECalMetaBackend *meta_backend,
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

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_created_objects, FALSE);
	g_return_val_if_fail (out_modified_objects, FALSE);
	g_return_val_if_fail (out_removed_objects, FALSE);

	*out_created_objects = NULL;
	*out_modified_objects = NULL;
	*out_removed_objects = NULL;

	if (!e_backend_get_online (E_BACKEND (meta_backend)))
		return TRUE;

	if (!e_cal_meta_backend_ensure_connected_sync (meta_backend, cancellable, error) ||
	    !e_cal_meta_backend_list_existing_sync (meta_backend, out_new_sync_tag, &existing_objects, cancellable, error)) {
		return FALSE;
	}

	success = e_cal_meta_backend_split_changes_sync (meta_backend, existing_objects, out_created_objects,
		out_modified_objects, out_removed_objects, cancellable, error);

	g_slist_free_full (existing_objects, e_cal_meta_backend_info_free);

	return success;
}

static gboolean
ecmb_search_sync (ECalMetaBackend *meta_backend,
		  const gchar *expr,
		  GSList **out_icalstrings,
		  GCancellable *cancellable,
		  GError **error)
{
	ECalCache *cal_cache;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_icalstrings != NULL, FALSE);

	*out_icalstrings = NULL;
	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);

	g_return_val_if_fail (cal_cache != NULL, FALSE);

	success = e_cal_cache_search (cal_cache, expr, out_icalstrings, cancellable, error);

	if (success) {
		GSList *link;

		for (link = *out_icalstrings; link; link = g_slist_next (link)) {
			ECalCacheSearchData *search_data = link->data;
			gchar *icalstring = NULL;

			if (search_data) {
				icalstring = g_strdup (search_data->object);
				e_cal_cache_search_data_free (search_data);
			}

			link->data = icalstring;
		}
	}

	g_object_unref (cal_cache);

	return success;
}

static gboolean
ecmb_search_components_sync (ECalMetaBackend *meta_backend,
			     const gchar *expr,
			     GSList **out_components,
			     GCancellable *cancellable,
			     GError **error)
{
	ECalCache *cal_cache;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_components != NULL, FALSE);

	*out_components = NULL;

	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (cal_cache != NULL, FALSE);

	success = e_cal_cache_search_components (cal_cache, expr, out_components, cancellable, error);

	g_object_unref (cal_cache);

	return success;
}

static gboolean
ecmb_requires_reconnect (ECalMetaBackend *meta_backend)
{
	ESource *source;
	gboolean requires = FALSE;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

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
ecmb_get_ssl_error_details (ECalMetaBackend *meta_backend,
			    gchar **out_certificate_pem,
			    GTlsCertificateFlags *out_certificate_errors)
{
	return FALSE;
}

static void
ecmb_start_view_thread_func (ECalBackend *cal_backend,
			     gpointer user_data,
			     GCancellable *cancellable,
			     GError **error)
{
	EDataCalView *view = user_data;
	ECalBackendSExp *sexp;
	GSList *components = NULL;
	const gchar *expr = NULL;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_CAL_META_BACKEND (cal_backend));
	g_return_if_fail (E_IS_DATA_CAL_VIEW (view));

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return;

	/* Fill the view with known (locally stored) components satisfying the expression */
	sexp = e_data_cal_view_get_sexp (view);
	if (sexp)
		expr = e_cal_backend_sexp_text (sexp);

	if (e_cal_meta_backend_search_components_sync (E_CAL_META_BACKEND (cal_backend), expr, &components, cancellable, &local_error) && components) {
		if (!g_cancellable_is_cancelled (cancellable))
			e_data_cal_view_notify_components_added (view, components);

		g_slist_free_full (components, g_object_unref);
	}

	e_data_cal_view_notify_complete (view, local_error);

	g_clear_error (&local_error);
}

static gboolean
ecmb_upload_local_changes_sync (ECalMetaBackend *meta_backend,
				ECalCache *cal_cache,
				EConflictResolution conflict_resolution,
				GCancellable *cancellable,
				GError **error)
{
	GSList *offline_changes, *link;
	GHashTable *covered_uids;
	ECache *cache;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), FALSE);

	cache = E_CACHE (cal_cache);
	covered_uids = g_hash_table_new (g_str_hash, g_str_equal);

	offline_changes = e_cal_cache_get_offline_changes (cal_cache, cancellable, error);
	for (link = offline_changes; link && success; link = g_slist_next (link)) {
		ECalCacheOfflineChange *change = link->data;
		gchar *extra = NULL;

		success = !g_cancellable_set_error_if_cancelled (cancellable, error);
		if (!success)
			break;

		if (!change || g_hash_table_contains (covered_uids, change->uid))
			continue;

		g_hash_table_insert (covered_uids, change->uid, NULL);

		if (!e_cal_cache_get_component_extra (cal_cache, change->uid, NULL, &extra, cancellable, NULL))
			extra = NULL;

		if (change->state == E_OFFLINE_STATE_LOCALLY_CREATED ||
		    change->state == E_OFFLINE_STATE_LOCALLY_MODIFIED) {
			GSList *instances = NULL;

			success = e_cal_cache_get_components_by_uid (cal_cache, change->uid, &instances, cancellable, error);
			if (success) {
				success = ecmb_save_component_wrapper_sync (meta_backend, cal_cache,
					change->state == E_OFFLINE_STATE_LOCALLY_MODIFIED,
					conflict_resolution, instances, extra, change->uid, NULL, NULL, NULL, cancellable, error);
			}

			g_slist_free_full (instances, g_object_unref);
		} else if (change->state == E_OFFLINE_STATE_LOCALLY_DELETED) {
			GError *local_error = NULL;

			success = e_cal_meta_backend_remove_component_sync (meta_backend, conflict_resolution,
				change->uid, extra, change->object, cancellable, &local_error);

			if (!success) {
				if (g_error_matches (local_error, E_DATA_CAL_ERROR, ObjectNotFound)) {
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

	g_slist_free_full (offline_changes, e_cal_cache_offline_change_free);
	g_hash_table_destroy (covered_uids);

	if (success)
		success = e_cache_clear_offline_changes (cache, cancellable, error);

	return success;
}

static gboolean
ecmb_maybe_remove_from_cache (ECalMetaBackend *meta_backend,
			      ECalCache *cal_cache,
			      ECacheOfflineFlag offline_flag,
			      const gchar *uid,
			      GCancellable *cancellable,
			      GError **error)
{
	ECalBackend *cal_backend;
	GSList *comps = NULL, *link;
	GError *local_error = NULL;

	g_return_val_if_fail (uid != NULL, FALSE);

	if (!e_cal_cache_get_components_by_uid (cal_cache, uid, &comps, cancellable, &local_error)) {
		if (g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND)) {
			g_clear_error (&local_error);
			return TRUE;
		}

		g_propagate_error (error, local_error);
		return FALSE;
	}

	cal_backend = E_CAL_BACKEND (meta_backend);

	for (link = comps; link; link = g_slist_next (link)) {
		ECalComponent *comp = link->data;
		ECalComponentId *id;

		g_warn_if_fail (E_IS_CAL_COMPONENT (comp));

		if (!E_IS_CAL_COMPONENT (comp))
			continue;

		id = e_cal_component_get_id (comp);
		if (id) {
			if (!e_cal_cache_delete_attachments (cal_cache, e_cal_component_get_icalcomponent (comp), cancellable, error) ||
			    !e_cal_cache_remove_component (cal_cache, id->uid, id->rid, offline_flag, cancellable, error)) {
				e_cal_component_free_id (id);
				g_slist_free_full (comps, g_object_unref);

				return FALSE;
			}

			e_cal_backend_notify_component_removed (cal_backend, id, comp, NULL);
			e_cal_component_free_id (id);
		}
	}

	g_slist_free_full (comps, g_object_unref);

	return TRUE;
}

static gboolean
ecmb_refresh_internal_sync (ECalMetaBackend *meta_backend,
			    gboolean with_connection_error,
			    GCancellable *cancellable,
			    GError **error)
{
	ECalCache *cal_cache;
	gboolean success = FALSE, repeat = TRUE, is_repeat = FALSE;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		goto done;

	if (!e_backend_get_online (E_BACKEND (meta_backend)) ||
	    !e_cal_meta_backend_ensure_connected_sync (meta_backend, cancellable, with_connection_error ? error : NULL) ||
	    !e_backend_get_online (E_BACKEND (meta_backend))) { /* Failed connecting moves backend to offline */
		g_mutex_lock (&meta_backend->priv->property_lock);
		meta_backend->priv->refresh_after_authenticate = TRUE;
		g_mutex_unlock (&meta_backend->priv->property_lock);
		goto done;
	}

	g_mutex_lock (&meta_backend->priv->property_lock);
	meta_backend->priv->refresh_after_authenticate = FALSE;
	g_mutex_unlock (&meta_backend->priv->property_lock);

	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	if (!cal_cache) {
		g_warn_if_reached ();
		goto done;
	}

	if (with_connection_error) {
		/* Skip upload when not initiated by the user (as part of the Refresh operation) */
		success = TRUE;
	} else {
		GError *local_error = NULL;

		success = ecmb_upload_local_changes_sync (meta_backend, cal_cache, E_CONFLICT_RESOLUTION_FAIL, cancellable, &local_error);
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

		last_sync_tag = e_cache_dup_key (E_CACHE (cal_cache), ECMB_KEY_SYNC_TAG, NULL);
		if (last_sync_tag && !*last_sync_tag) {
			g_free (last_sync_tag);
			last_sync_tag = NULL;
		}

		success = e_cal_meta_backend_get_changes_sync (meta_backend, last_sync_tag, is_repeat, &new_sync_tag, &repeat,
			&created_objects, &modified_objects, &removed_objects, cancellable, &local_error);

		if (local_error) {
			if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_HOST_NOT_FOUND))
				e_backend_set_online (E_BACKEND (meta_backend), FALSE);

			g_propagate_error (error, local_error);
			local_error = NULL;
			success = FALSE;
		}

		if (success) {
			success = e_cal_meta_backend_process_changes_sync (meta_backend, created_objects, modified_objects,
				removed_objects, cancellable, error);
		}

		if (success && new_sync_tag)
			e_cache_set_key (E_CACHE (cal_cache), ECMB_KEY_SYNC_TAG, new_sync_tag, NULL);

		g_slist_free_full (created_objects, e_cal_meta_backend_info_free);
		g_slist_free_full (modified_objects, e_cal_meta_backend_info_free);
		g_slist_free_full (removed_objects, e_cal_meta_backend_info_free);
		g_free (last_sync_tag);
		g_free (new_sync_tag);

		is_repeat = TRUE;
	}

	g_object_unref (cal_cache);

 done:
	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->refresh_cancellable == cancellable)
		g_clear_object (&meta_backend->priv->refresh_cancellable);

	g_mutex_unlock (&meta_backend->priv->property_lock);

	g_signal_emit (meta_backend, signals[REFRESH_COMPLETED], 0, NULL);

	return success;
}

static void
ecmb_refresh_thread_func (ECalBackend *cal_backend,
			  gpointer user_data,
			  GCancellable *cancellable,
			  GError **error)
{
	ECalMetaBackend *meta_backend;

	g_return_if_fail (E_IS_CAL_META_BACKEND (cal_backend));

	meta_backend = E_CAL_META_BACKEND (cal_backend);

	ecmb_refresh_internal_sync (meta_backend, FALSE, cancellable, error);
}

static void
ecmb_source_refresh_timeout_cb (ESource *source,
				gpointer user_data)
{
	GWeakRef *weak_ref = user_data;
	ECalMetaBackend *meta_backend;

	g_return_if_fail (weak_ref != NULL);

	meta_backend = g_weak_ref_get (weak_ref);
	if (meta_backend) {
		e_cal_meta_backend_schedule_refresh (meta_backend);
		g_object_unref (meta_backend);
	}
}

static void
ecmb_source_changed_thread_func (ECalBackend *cal_backend,
				 gpointer user_data,
				 GCancellable *cancellable,
				 GError **error)
{
	ECalMetaBackend *meta_backend;

	g_return_if_fail (E_IS_CAL_META_BACKEND (cal_backend));

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return;

	meta_backend = E_CAL_META_BACKEND (cal_backend);

	g_mutex_lock (&meta_backend->priv->property_lock);
	if (!meta_backend->priv->refresh_timeout_id) {
		ESource *source = e_backend_get_source (E_BACKEND (meta_backend));

		if (e_source_has_extension (source, E_SOURCE_EXTENSION_REFRESH)) {
			meta_backend->priv->refresh_timeout_id = e_source_refresh_add_timeout (source, NULL,
				ecmb_source_refresh_timeout_cb, e_weak_ref_new (meta_backend), (GDestroyNotify) e_weak_ref_free);
		}
	}
	g_mutex_unlock (&meta_backend->priv->property_lock);

	g_signal_emit (meta_backend, signals[SOURCE_CHANGED], 0, NULL);

	if (e_backend_get_online (E_BACKEND (meta_backend)) &&
	    e_cal_meta_backend_requires_reconnect (meta_backend)) {
		gboolean can_refresh;

		g_mutex_lock (&meta_backend->priv->connect_lock);
		can_refresh = e_cal_meta_backend_disconnect_sync (meta_backend, cancellable, error);
		g_mutex_unlock (&meta_backend->priv->connect_lock);

		if (can_refresh)
			e_cal_meta_backend_schedule_refresh (meta_backend);
	}

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->source_changed_cancellable == cancellable)
		g_clear_object (&meta_backend->priv->source_changed_cancellable);

	g_mutex_unlock (&meta_backend->priv->property_lock);
}

static void
ecmb_go_offline_thread_func (ECalBackend *cal_backend,
			     gpointer user_data,
			     GCancellable *cancellable,
			     GError **error)
{
	ECalMetaBackend *meta_backend;

	g_return_if_fail (E_IS_CAL_META_BACKEND (cal_backend));

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return;

	meta_backend = E_CAL_META_BACKEND (cal_backend);

	g_mutex_lock (&meta_backend->priv->connect_lock);
	e_cal_meta_backend_disconnect_sync (meta_backend, cancellable, error);
	g_mutex_unlock (&meta_backend->priv->connect_lock);

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->go_offline_cancellable == cancellable)
		g_clear_object (&meta_backend->priv->go_offline_cancellable);

	g_mutex_unlock (&meta_backend->priv->property_lock);
}

static ECalComponent *
ecmb_find_in_instances (const GSList *instances, /* ECalComponent * */
			const gchar *uid,
			const gchar *rid)
{
	GSList *link;

	for (link = (GSList *) instances; link; link = g_slist_next (link)) {
		ECalComponent *comp = link->data;
		ECalComponentId *id;

		if (!comp)
			continue;

		id = e_cal_component_get_id (comp);
		if (!id)
			continue;

		if (g_strcmp0 (id->uid, uid) == 0 &&
		    g_strcmp0 (id->rid, rid) == 0) {
			e_cal_component_free_id (id);
			return comp;
		}

		e_cal_component_free_id (id);
	}

	return NULL;
}

static gboolean
ecmb_put_one_component (ECalMetaBackend *meta_backend,
			ECalCache *cal_cache,
			ECacheOfflineFlag offline_flag,
			ECalComponent *comp,
			const gchar *extra,
			GSList **inout_cache_instances,
			GCancellable *cancellable,
			GError **error)
{
	gboolean success = TRUE;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (inout_cache_instances != NULL, FALSE);

	if (e_cal_component_has_attachments (comp)) {
		success = e_cal_meta_backend_store_inline_attachments_sync (meta_backend,
			e_cal_component_get_icalcomponent (comp), cancellable, error);
		e_cal_component_rescan (comp);
	}

	success = success && e_cal_cache_put_component (cal_cache, comp, extra, offline_flag, cancellable, error);

	if (success) {
		ECalComponent *existing = NULL;
		ECalComponentId *id;

		id = e_cal_component_get_id (comp);
		if (id) {
			existing = ecmb_find_in_instances (*inout_cache_instances, id->uid, id->rid);

			e_cal_component_free_id (id);
		}

		if (existing) {
			e_cal_backend_notify_component_modified (E_CAL_BACKEND (meta_backend), existing, comp);
			*inout_cache_instances = g_slist_remove (*inout_cache_instances, existing);

			g_clear_object (&existing);
		} else {
			e_cal_backend_notify_component_created (E_CAL_BACKEND (meta_backend), comp);
		}
	}

	return success;
}

static gboolean
ecmb_put_instances (ECalMetaBackend *meta_backend,
		    ECalCache *cal_cache,
		    const gchar *uid,
		    ECacheOfflineFlag offline_flag,
		    const GSList *new_instances, /* ECalComponent * */
		    const gchar *extra,
		    GCancellable *cancellable,
		    GError **error)
{
	GSList *cache_instances = NULL, *link;
	gboolean success = TRUE;
	GError *local_error = NULL;

	if (!e_cal_cache_get_components_by_uid (cal_cache, uid, &cache_instances, cancellable, &local_error)) {
		if (g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND)) {
			g_clear_error (&local_error);
		} else {
			g_propagate_error (error, local_error);

			return FALSE;
		}
	}

	for (link = (GSList *) new_instances; link && success; link = g_slist_next (link)) {
		ECalComponent *comp = link->data;

		success = ecmb_put_one_component (meta_backend, cal_cache, offline_flag, comp, extra, &cache_instances, cancellable, error);
	}

	/* What left got removed from the remote side, notify about it */
	if (success && cache_instances) {
		ECalBackend *cal_backend = E_CAL_BACKEND (meta_backend);
		GSList *link;

		for (link = cache_instances; link && success; link = g_slist_next (link)) {
			ECalComponent *comp = link->data;
			ECalComponentId *id;

			id = e_cal_component_get_id (comp);
			if (!id)
				continue;

			success = e_cal_cache_delete_attachments (cal_cache, e_cal_component_get_icalcomponent (comp), cancellable, error);
			if (!success)
				break;

			success = e_cal_cache_remove_component (cal_cache, id->uid, id->rid, offline_flag, cancellable, error);

			e_cal_backend_notify_component_removed (cal_backend, id, comp, NULL);

			e_cal_component_free_id (id);
		}
	}

	g_slist_free_full (cache_instances, g_object_unref);

	return success;
}

static void
ecmb_gather_timezones (ECalMetaBackend *meta_backend,
		       ETimezoneCache *timezone_cache,
		       icalcomponent *icalcomp)
{
	icalcomponent *subcomp;
	icaltimezone *zone;

	g_return_if_fail (E_IS_CAL_META_BACKEND (meta_backend));
	g_return_if_fail (E_IS_TIMEZONE_CACHE (timezone_cache));
	g_return_if_fail (icalcomp != NULL);

	zone = icaltimezone_new ();

	for (subcomp = icalcomponent_get_first_component (icalcomp, ICAL_VTIMEZONE_COMPONENT);
	     subcomp;
	     subcomp = icalcomponent_get_next_component (icalcomp, ICAL_VTIMEZONE_COMPONENT)) {
		icalcomponent *clone;

		clone = icalcomponent_new_clone (subcomp);

		if (icaltimezone_set_component (zone, clone)) {
			if (icaltimezone_get_tzid (zone))
				e_timezone_cache_add_timezone (timezone_cache, zone);
		} else {
			icalcomponent_free (clone);
		}
	}

	icaltimezone_free (zone, TRUE);
}

static gboolean
ecmb_load_component_wrapper_sync (ECalMetaBackend *meta_backend,
				  ECalCache *cal_cache,
				  const gchar *uid,
				  const gchar *preloaded_object,
				  const gchar *preloaded_extra,
				  gchar **out_new_uid,
				  GCancellable *cancellable,
				  GError **error)
{
	ECacheOfflineFlag offline_flag = E_CACHE_IS_ONLINE;
	icalcomponent *icalcomp = NULL;
	GSList *new_instances = NULL;
	gchar *extra = NULL;
	const gchar *loaded_uid = NULL;
	gboolean success = TRUE;
	GError *local_error = NULL;

	if (preloaded_object && *preloaded_object) {
		icalcomp = icalcomponent_new_from_string (preloaded_object);
		if (!icalcomp) {
			g_propagate_error (error, e_data_cal_create_error_fmt (InvalidObject, _("Preloaded object for UID “%s” is invalid"), uid));
			return FALSE;
		}
	} else if (!e_cal_meta_backend_ensure_connected_sync (meta_backend, cancellable, error) ||
		   !e_cal_meta_backend_load_component_sync (meta_backend, uid, preloaded_extra, &icalcomp, &extra, cancellable, error)) {
		g_free (extra);
		return FALSE;
	} else if (!icalcomp) {
		g_propagate_error (error, e_data_cal_create_error_fmt (InvalidObject, _("Received object for UID “%s” is invalid"), uid));
		g_free (extra);
		return FALSE;
	}

	if (icalcomponent_isa (icalcomp) == ICAL_VCALENDAR_COMPONENT) {
		icalcomponent_kind kind;
		icalcomponent *subcomp;

		ecmb_gather_timezones (meta_backend, E_TIMEZONE_CACHE (meta_backend), icalcomp);

		kind = e_cal_backend_get_kind (E_CAL_BACKEND (meta_backend));

		for (subcomp = icalcomponent_get_first_component (icalcomp, kind);
		     subcomp && success;
		     subcomp = icalcomponent_get_next_component (icalcomp, kind)) {
			ECalComponent *comp = e_cal_component_new_from_icalcomponent (icalcomponent_new_clone (subcomp));

			if (comp) {
				new_instances = g_slist_prepend (new_instances, comp);

				if (!loaded_uid)
					loaded_uid = icalcomponent_get_uid (e_cal_component_get_icalcomponent (comp));
			}
		}
	} else {
		ECalComponent *comp = e_cal_component_new_from_icalcomponent (icalcomp);

		icalcomp = NULL;

		if (comp) {
			new_instances = g_slist_prepend (new_instances, comp);

			if (!loaded_uid)
				loaded_uid = icalcomponent_get_uid (e_cal_component_get_icalcomponent (comp));
		}
	}

	if (new_instances) {
		new_instances = g_slist_reverse (new_instances);

		success = ecmb_put_instances (meta_backend, cal_cache, loaded_uid ? loaded_uid : uid, offline_flag,
			new_instances, extra ? extra : preloaded_extra, cancellable, &local_error);

		if (success && out_new_uid)
			*out_new_uid = g_strdup (loaded_uid ? loaded_uid : uid);
	} else {
		g_propagate_error (error, e_data_cal_create_error_fmt (InvalidObject, _("Received object for UID “%s” doesn’t contain any expected component"), uid));
		success = FALSE;
	}

	g_slist_free_full (new_instances, g_object_unref);
	if (icalcomp)
		icalcomponent_free (icalcomp);
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
ecmb_save_component_wrapper_sync (ECalMetaBackend *meta_backend,
				  ECalCache *cal_cache,
				  gboolean overwrite_existing,
				  EConflictResolution conflict_resolution,
				  const GSList *in_instances,
				  const gchar *extra,
				  const gchar *orig_uid,
				  gboolean *out_requires_put,
				  gchar **out_new_uid,
				  gchar **out_new_extra,
				  GCancellable *cancellable,
				  GError **error)
{
	GSList *link, *instances = NULL;
	gchar *new_uid = NULL, *new_extra = NULL;
	gboolean has_attachments = FALSE, success = TRUE;
	GError *local_error = NULL;

	if (out_requires_put)
		*out_requires_put = TRUE;

	if (out_new_uid)
		*out_new_uid = NULL;

	for (link = (GSList *) in_instances; link && !has_attachments; link = g_slist_next (link)) {
		has_attachments = e_cal_component_has_attachments (link->data);
	}

	if (has_attachments) {
		instances = g_slist_copy ((GSList *) in_instances);

		for (link = instances; link; link = g_slist_next (link)) {
			ECalComponent *comp = link->data;

			if (success && e_cal_component_has_attachments (comp)) {
				comp = e_cal_component_clone (comp);
				link->data = comp;

				success = e_cal_meta_backend_inline_local_attachments_sync (meta_backend,
					e_cal_component_get_icalcomponent (comp), cancellable, error);
				e_cal_component_rescan (comp);
			} else {
				g_object_ref (comp);
			}
		}
	}

	success = success && e_cal_meta_backend_save_component_sync (meta_backend, overwrite_existing, conflict_resolution,
		instances ? instances : in_instances, extra, &new_uid, &new_extra, cancellable, &local_error);

	if (success && new_uid && *new_uid) {
		gchar *loaded_uid = NULL;

		success = ecmb_load_component_wrapper_sync (meta_backend, cal_cache, new_uid, NULL,
			new_extra ? new_extra : extra, &loaded_uid, cancellable, error);

		if (success && g_strcmp0 (loaded_uid, orig_uid) != 0)
			success = ecmb_maybe_remove_from_cache (meta_backend, cal_cache, E_CACHE_IS_ONLINE, orig_uid, cancellable, error);

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

	g_slist_free_full (instances, g_object_unref);

	if (local_error) {
		if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_HOST_NOT_FOUND))
			e_backend_set_online (E_BACKEND (meta_backend), FALSE);

		g_propagate_error (error, local_error);
		success = FALSE;
	}

	return success;
}

static void
ecmb_open_sync (ECalBackendSync *sync_backend,
		EDataCal *cal,
		GCancellable *cancellable,
		gboolean only_if_exists,
		GError **error)
{
	ECalMetaBackend *meta_backend;
	ESource *source;

	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));

	if (e_cal_backend_is_opened (E_CAL_BACKEND (sync_backend)))
		return;

	meta_backend = E_CAL_META_BACKEND (sync_backend);
	if (meta_backend->priv->create_cache_error) {
		g_propagate_error (error, meta_backend->priv->create_cache_error);
		meta_backend->priv->create_cache_error = NULL;
		return;
	}

	source = e_backend_get_source (E_BACKEND (sync_backend));

	if (!meta_backend->priv->source_changed_id) {
		meta_backend->priv->source_changed_id = g_signal_connect_swapped (source, "changed",
			G_CALLBACK (ecmb_schedule_source_changed), meta_backend);
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND)) {
		ESourceWebdav *webdav_extension;

		webdav_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
		e_source_webdav_unset_temporary_ssl_trust (webdav_extension);
	}

	if (e_cal_meta_backend_get_ever_connected (meta_backend)) {
		e_cal_backend_set_writable (E_CAL_BACKEND (meta_backend),
			e_cal_meta_backend_get_connected_writable (meta_backend));
	} else {
		if (!e_cal_meta_backend_ensure_connected_sync (meta_backend, cancellable, error)) {
			g_mutex_lock (&meta_backend->priv->property_lock);
			meta_backend->priv->refresh_after_authenticate = TRUE;
			g_mutex_unlock (&meta_backend->priv->property_lock);

			return;
		}
	}

	e_cal_meta_backend_schedule_refresh (E_CAL_META_BACKEND (sync_backend));
}

static void
ecmb_refresh_sync (ECalBackendSync *sync_backend,
		   EDataCal *cal,
		   GCancellable *cancellable,
		   GError **error)
{
	ECalMetaBackend *meta_backend;
	EBackend *backend;

	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));

	meta_backend = E_CAL_META_BACKEND (sync_backend);
	backend = E_BACKEND (meta_backend);

	if (!e_backend_get_online (backend) &&
	    e_backend_is_destination_reachable (backend, cancellable, NULL))
		e_backend_set_online (backend, TRUE);

	if (!e_backend_get_online (backend))
		return;

	if (e_cal_meta_backend_ensure_connected_sync (meta_backend, cancellable, error))
		e_cal_meta_backend_schedule_refresh (meta_backend);
}

static void
ecmb_get_object_sync (ECalBackendSync *sync_backend,
		      EDataCal *cal,
		      GCancellable *cancellable,
		      const gchar *uid,
		      const gchar *rid,
		      gchar **calobj,
		      GError **error)
{
	ECalMetaBackend *meta_backend;
	ECalCache *cal_cache;
	gboolean success;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));
	g_return_if_fail (uid && *uid);
	g_return_if_fail (calobj != NULL);

	meta_backend = E_CAL_META_BACKEND (sync_backend);
	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);

	g_return_if_fail (cal_cache != NULL);

	if (rid && *rid) {
		success = e_cal_cache_get_component_as_string (cal_cache, uid, rid, calobj, cancellable, &local_error);
	} else {
		GSList *components = NULL;

		success = e_cal_cache_get_components_by_uid (cal_cache, uid, &components, cancellable, &local_error);
		if (success) {
			icalcomponent *icalcomp;

			icalcomp = e_cal_meta_backend_merge_instances (meta_backend, components, FALSE);
			if (icalcomp) {
				*calobj = icalcomponent_as_ical_string_r (icalcomp);

				icalcomponent_free (icalcomp);
			} else {
				g_set_error (&local_error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND, _("Object “%s” not found"), uid);
				success = FALSE;
			}
		}

		g_slist_free_full (components, g_object_unref);
	}

	if (!success &&
	    g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND)) {
		gchar *loaded_uid = NULL;
		gboolean found = FALSE;

		g_clear_error (&local_error);

		/* Ignore errors here, just try whether it's on the remote side, but not in the local cache */
		if (e_backend_get_online (E_BACKEND (meta_backend)) &&
		    e_cal_meta_backend_ensure_connected_sync (meta_backend, cancellable, NULL) &&
		    ecmb_load_component_wrapper_sync (meta_backend, cal_cache, uid, NULL, NULL, &loaded_uid, cancellable, NULL)) {
			found = e_cal_cache_get_component_as_string (cal_cache, loaded_uid, rid, calobj, cancellable, NULL);
		}

		if (!found)
			g_propagate_error (error, e_data_cal_create_error (ObjectNotFound, NULL));

		g_free (loaded_uid);
	} else if (local_error) {
		g_propagate_error (error, e_data_cal_create_error (OtherError, local_error->message));
		g_clear_error (&local_error);
	}

	g_object_unref (cal_cache);
}

static void
ecmb_get_object_list_sync (ECalBackendSync *sync_backend,
			   EDataCal *cal,
			   GCancellable *cancellable,
			   const gchar *sexp,
			   GSList **calobjs,
			   GError **error)
{
	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));
	g_return_if_fail (calobjs != NULL);

	*calobjs = NULL;

	e_cal_meta_backend_search_sync (E_CAL_META_BACKEND (sync_backend), sexp, calobjs, cancellable, error);
}

static gboolean
ecmb_add_free_busy_instance_cb (icalcomponent *icalcomp,
				struct icaltimetype instance_start,
				struct icaltimetype instance_end,
				gpointer user_data,
				GCancellable *cancellable,
				GError **error)
{
	icalcomponent *vfreebusy = user_data;
	icalproperty *prop, *classification;
	icalparameter *param;
	struct icalperiodtype ipt;

	ipt.start = instance_start;
	ipt.end = instance_end;
	ipt.duration = icaldurationtype_null_duration ();

        /* Add busy information to the VFREEBUSY component */
	prop = icalproperty_new (ICAL_FREEBUSY_PROPERTY);
	icalproperty_set_freebusy (prop, ipt);

	param = icalparameter_new_fbtype (ICAL_FBTYPE_BUSY);
	icalproperty_add_parameter (prop, param);

	classification = icalcomponent_get_first_property (icalcomp, ICAL_CLASS_PROPERTY);
	if (!classification || icalproperty_get_class (classification) == ICAL_CLASS_PUBLIC) {
		const gchar *str;

		str = icalcomponent_get_summary (icalcomp);
		if (str && *str) {
			param = icalparameter_new_x (str);
			icalparameter_set_xname (param, "X-SUMMARY");
			icalproperty_add_parameter (prop, param);
		}

		str = icalcomponent_get_location (icalcomp);
		if (str && *str) {
			param = icalparameter_new_x (str);
			icalparameter_set_xname (param, "X-LOCATION");
			icalproperty_add_parameter (prop, param);
		}
	}

	icalcomponent_add_property (vfreebusy, prop);

	return TRUE;
}

static void
ecmb_get_free_busy_sync (ECalBackendSync *sync_backend,
			 EDataCal *cal,
			 GCancellable *cancellable,
			 const GSList *users,
			 time_t start,
			 time_t end,
			 GSList **out_freebusy,
			 GError **error)
{
	ECalMetaBackend *meta_backend;
	ECalCache *cal_cache;
	GSList *link, *components = NULL;
	gchar *cal_email_address, *mailto;
	icalcomponent *vfreebusy, *icalcomp;
	icalproperty *prop;
	icaltimezone *utc_zone;

	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));
	g_return_if_fail (out_freebusy != NULL);

	meta_backend = E_CAL_META_BACKEND (sync_backend);

	*out_freebusy = NULL;

	if (!users)
		return;

	cal_email_address = e_cal_backend_get_backend_property (E_CAL_BACKEND (meta_backend), CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS);
	if (!cal_email_address)
		return;

	for (link = (GSList *) users; link; link = g_slist_next (link)) {
		const gchar *user = link->data;

		if (user && g_ascii_strcasecmp (user, cal_email_address) == 0)
			break;
	}

	if (!link) {
		g_free (cal_email_address);
		return;
	}

	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	if (!cal_cache) {
		g_warn_if_reached ();
		g_free (cal_email_address);
		return;
	}

	if (!e_cal_cache_get_components_in_range (cal_cache, start, end, &components, cancellable, error)) {
		g_clear_object (&cal_cache);
		g_free (cal_email_address);
		return;
	}

	vfreebusy = icalcomponent_new_vfreebusy ();

	mailto = g_strconcat ("mailto:", cal_email_address, NULL);
	prop = icalproperty_new_organizer (mailto);
	g_free (mailto);

	if (prop)
		icalcomponent_add_property (vfreebusy, prop);

	utc_zone = icaltimezone_get_utc_timezone ();
	icalcomponent_set_dtstart (vfreebusy, icaltime_from_timet_with_zone (start, FALSE, utc_zone));
	icalcomponent_set_dtend (vfreebusy, icaltime_from_timet_with_zone (end, FALSE, utc_zone));

	for (link = components; link; link = g_slist_next (link)) {
		ECalComponent *comp = link->data;

		if (!E_IS_CAL_COMPONENT (comp)) {
			g_warn_if_reached ();
			continue;
		}

		icalcomp = e_cal_component_get_icalcomponent (comp);
		if (!icalcomp)
			continue;

		/* If the event is TRANSPARENT, skip it. */
		prop = icalcomponent_get_first_property (icalcomp, ICAL_TRANSP_PROPERTY);
		if (prop) {
			icalproperty_transp transp_val = icalproperty_get_transp (prop);
			if (transp_val == ICAL_TRANSP_TRANSPARENT ||
			    transp_val == ICAL_TRANSP_TRANSPARENTNOCONFLICT)
				continue;
		}

		if (!e_cal_recur_generate_instances_sync (icalcomp,
			icaltime_from_timet_with_zone (start, FALSE, NULL),
			icaltime_from_timet_with_zone (end, FALSE, NULL),
			ecmb_add_free_busy_instance_cb, vfreebusy,
			e_cal_cache_resolve_timezone_cb, cal_cache,
			utc_zone, cancellable, error)) {
			break;
		}
	}

	*out_freebusy = g_slist_prepend (*out_freebusy, icalcomponent_as_ical_string_r (vfreebusy));

	g_slist_free_full (components, g_object_unref);
	icalcomponent_free (vfreebusy);
	g_object_unref (cal_cache);
	g_free (cal_email_address);
}

static gboolean
ecmb_create_object_sync (ECalMetaBackend *meta_backend,
			 ECalCache *cal_cache,
			 ECacheOfflineFlag *offline_flag,
			 EConflictResolution conflict_resolution,
			 ECalComponent *comp,
			 gchar **out_new_uid,
			 ECalComponent **out_new_comp,
			 GCancellable *cancellable,
			 GError **error)
{
	icalcomponent *icalcomp;
	struct icaltimetype itt;
	const gchar *uid;
	gchar *new_uid = NULL, *new_extra = NULL;
	gboolean success, requires_put = TRUE;

	g_return_val_if_fail (comp != NULL, FALSE);

	icalcomp = e_cal_component_get_icalcomponent (comp);
	if (!icalcomp) {
		g_propagate_error (error, e_data_cal_create_error (InvalidObject, NULL));
		return FALSE;
	}

	uid = icalcomponent_get_uid (icalcomp);
	if (!uid) {
		gchar *new_uid;

		new_uid = e_util_generate_uid ();
		if (!new_uid) {
			g_propagate_error (error, e_data_cal_create_error (InvalidObject, NULL));
			return FALSE;
		}

		icalcomponent_set_uid (icalcomp, new_uid);
		uid = icalcomponent_get_uid (icalcomp);

		g_free (new_uid);
	}

	if (e_cal_cache_contains (cal_cache, uid, NULL, E_CACHE_EXCLUDE_DELETED)) {
		g_propagate_error (error, e_data_cal_create_error (ObjectIdAlreadyExists, NULL));
		return FALSE;
	}

	/* Set the created and last modified times on the component, if not there already */
	itt = icaltime_current_time_with_zone (icaltimezone_get_utc_timezone ());

	if (!icalcomponent_get_first_property (icalcomp, ICAL_CREATED_PROPERTY)) {
		/* Update both when CREATED is missing, to make sure the LAST-MODIFIED
		   is not before CREATED */
		e_cal_component_set_created (comp, &itt);
		e_cal_component_set_last_modified (comp, &itt);
	} else if (!icalcomponent_get_first_property (icalcomp, ICAL_LASTMODIFIED_PROPERTY)) {
		e_cal_component_set_last_modified (comp, &itt);
	}

	if (*offline_flag == E_CACHE_OFFLINE_UNKNOWN) {
		if (e_backend_get_online (E_BACKEND (meta_backend)) &&
		    e_cal_meta_backend_ensure_connected_sync (meta_backend, cancellable, NULL)) {
			*offline_flag = E_CACHE_IS_ONLINE;
		} else {
			*offline_flag = E_CACHE_IS_OFFLINE;
		}
	}

	if (*offline_flag == E_CACHE_IS_ONLINE) {
		GSList *instances;

		instances = g_slist_prepend (NULL, comp);

		if (!ecmb_save_component_wrapper_sync (meta_backend, cal_cache, FALSE, conflict_resolution, instances, NULL, uid,
			&requires_put, &new_uid, &new_extra, cancellable, error)) {
			g_slist_free (instances);
			return FALSE;
		}

		g_slist_free (instances);
	}

	if (requires_put) {
		success = e_cal_cache_put_component (cal_cache, comp, new_extra, *offline_flag, cancellable, error);
		if (success && !out_new_comp) {
			e_cal_backend_notify_component_created (E_CAL_BACKEND (meta_backend), comp);
		}
	} else {
		success = TRUE;
	}

	if (success) {
		if (out_new_uid)
			*out_new_uid = g_strdup (new_uid ? new_uid : icalcomponent_get_uid (e_cal_component_get_icalcomponent (comp)));
		if (out_new_comp) {
			if (new_uid) {
				if (!e_cal_cache_get_component (cal_cache, new_uid, NULL, out_new_comp, cancellable, NULL))
					*out_new_comp = g_object_ref (comp);
			} else {
				*out_new_comp = g_object_ref (comp);
			}
		}
	}

	g_free (new_uid);
	g_free (new_extra);

	return success;
}

static void
ecmb_create_objects_sync (ECalBackendSync *sync_backend,
			  EDataCal *cal,
			  GCancellable *cancellable,
			  const GSList *calobjs,
			  GSList **out_uids,
			  GSList **out_new_components,
			  GError **error)
{
	ECalMetaBackend *meta_backend;
	ECalCache *cal_cache;
	ECacheOfflineFlag offline_flag = E_CACHE_OFFLINE_UNKNOWN;
	EConflictResolution conflict_resolution = E_CONFLICT_RESOLUTION_FAIL;
	icalcomponent_kind backend_kind;
	GSList *link;
	gboolean success = TRUE;

	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));
	g_return_if_fail (calobjs != NULL);
	g_return_if_fail (out_uids != NULL);
	g_return_if_fail (out_new_components != NULL);

	if (!e_cal_backend_get_writable (E_CAL_BACKEND (sync_backend))) {
		g_propagate_error (error, e_data_cal_create_error (PermissionDenied, NULL));
		return;
	}

	meta_backend = E_CAL_META_BACKEND (sync_backend);
	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	g_return_if_fail (cal_cache != NULL);

	backend_kind = e_cal_backend_get_kind (E_CAL_BACKEND (meta_backend));

	for (link = (GSList *) calobjs; link && success; link = g_slist_next (link)) {
		ECalComponent *comp, *new_comp = NULL;
		gchar *new_uid = NULL;

		if (g_cancellable_set_error_if_cancelled (cancellable, error))
			break;

		comp = e_cal_component_new_from_string (link->data);
		if (!comp ||
		    !e_cal_component_get_icalcomponent (comp) ||
		    backend_kind != icalcomponent_isa (e_cal_component_get_icalcomponent (comp))) {
			g_clear_object (&comp);

			g_propagate_error (error, e_data_cal_create_error (InvalidObject, NULL));
			break;
		}

		success = ecmb_create_object_sync (meta_backend, cal_cache, &offline_flag, conflict_resolution,
			comp, &new_uid, &new_comp, cancellable, error);

		if (success) {
			*out_uids = g_slist_prepend (*out_uids, new_uid);
			*out_new_components = g_slist_prepend (*out_new_components, new_comp);
		}

		g_object_unref (comp);
	}

	*out_uids = g_slist_reverse (*out_uids);
	*out_new_components = g_slist_reverse (*out_new_components);

	g_object_unref (cal_cache);
}

static gboolean
ecmb_modify_object_sync (ECalMetaBackend *meta_backend,
			 ECalCache *cal_cache,
			 ECacheOfflineFlag *offline_flag,
			 EConflictResolution conflict_resolution,
			 ECalObjModType mod,
			 ECalComponent *comp,
			 ECalComponent **out_old_comp,
			 ECalComponent **out_new_comp,
			 GCancellable *cancellable,
			 GError **error)
{
	struct icaltimetype itt;
	ECalComponentId *id;
	ECalComponent *old_comp = NULL, *new_comp = NULL, *master_comp, *existing_comp = NULL;
	GSList *instances = NULL;
	gchar *extra = NULL, *new_uid = NULL, *new_extra = NULL;
	gboolean success = TRUE, requires_put = TRUE;
	GError *local_error = NULL;

	g_return_val_if_fail (comp != NULL, FALSE);

	id = e_cal_component_get_id (comp);
	if (!id) {
		g_propagate_error (error, e_data_cal_create_error (InvalidObject, NULL));
		return FALSE;
	}

	if (!e_cal_cache_get_components_by_uid (cal_cache, id->uid, &instances, cancellable, &local_error)) {
		if (g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND)) {
			g_clear_error (&local_error);
			local_error = e_data_cal_create_error (ObjectNotFound, NULL);
		}

		g_propagate_error (error, local_error);
		e_cal_component_free_id (id);

		return FALSE;
	}

	master_comp = ecmb_find_in_instances (instances, id->uid, NULL);
	if (e_cal_component_is_instance (comp)) {
		/* Set detached instance as the old object */
		existing_comp = ecmb_find_in_instances (instances, id->uid, id->rid);

		if (!existing_comp && mod == E_CAL_OBJ_MOD_ONLY_THIS) {
			g_propagate_error (error, e_data_cal_create_error (ObjectNotFound, NULL));

			g_slist_free_full (instances, g_object_unref);
			e_cal_component_free_id (id);

			return FALSE;
		}
	}

	if (!existing_comp)
		existing_comp = master_comp;

	if (!e_cal_cache_get_component_extra (cal_cache, id->uid, id->rid, &extra, cancellable, NULL) && id->rid) {
		if (!e_cal_cache_get_component_extra (cal_cache, id->uid, NULL, &extra, cancellable, NULL))
			extra = NULL;
	}

	/* Set the last modified time on the component */
	itt = icaltime_current_time_with_zone (icaltimezone_get_utc_timezone ());
	e_cal_component_set_last_modified (comp, &itt);

	/* Remember old and new components */
	if (out_old_comp && existing_comp)
		old_comp = e_cal_component_clone (existing_comp);

	if (out_new_comp)
		new_comp = e_cal_component_clone (comp);

	switch (mod) {
	case E_CAL_OBJ_MOD_ONLY_THIS:
	case E_CAL_OBJ_MOD_THIS:
		if (e_cal_component_is_instance (comp)) {
			if (existing_comp != master_comp) {
				instances = g_slist_remove (instances, existing_comp);
				g_clear_object (&existing_comp);
			}
		} else {
			instances = g_slist_remove (instances, master_comp);
			g_clear_object (&master_comp);
			existing_comp = NULL;
		}

		instances = g_slist_append (instances, e_cal_component_clone (comp));
		break;
	case E_CAL_OBJ_MOD_ALL:
		e_cal_recur_ensure_end_dates (comp, TRUE, e_cal_cache_resolve_timezone_simple_cb, cal_cache);

		/* Replace master object */
		instances = g_slist_remove (instances, master_comp);
		g_clear_object (&master_comp);
		existing_comp = NULL;

		instances = g_slist_prepend (instances, e_cal_component_clone (comp));
		break;
	case E_CAL_OBJ_MOD_THIS_AND_PRIOR:
	case E_CAL_OBJ_MOD_THIS_AND_FUTURE:
		if (e_cal_component_is_instance (comp) && master_comp) {
			struct icaltimetype rid, master_dtstart;
			icalcomponent *icalcomp = e_cal_component_get_icalcomponent (comp);
			icalcomponent *split_icalcomp;
			icalproperty *prop;

			rid = icalcomponent_get_recurrenceid (icalcomp);

			if (mod == E_CAL_OBJ_MOD_THIS_AND_FUTURE &&
			    e_cal_util_is_first_instance (master_comp, icalcomponent_get_recurrenceid (icalcomp),
				e_cal_cache_resolve_timezone_simple_cb, cal_cache)) {
				icalproperty *prop = icalcomponent_get_first_property (icalcomp, ICAL_RECURRENCEID_PROPERTY);

				if (prop)
					icalcomponent_remove_property (icalcomp, prop);

				e_cal_component_rescan (comp);

				/* Then do it like for "mod_all" */
				e_cal_recur_ensure_end_dates (comp, TRUE, e_cal_cache_resolve_timezone_simple_cb, cal_cache);

				/* Replace master */
				instances = g_slist_remove (instances, master_comp);
				g_clear_object (&master_comp);
				existing_comp = NULL;

				instances = g_slist_prepend (instances, e_cal_component_clone (comp));

				if (out_new_comp) {
					g_clear_object (&new_comp);
					new_comp = e_cal_component_clone (comp);
				}
				break;
			}

			prop = icalcomponent_get_first_property (icalcomp, ICAL_RECURRENCEID_PROPERTY);
			if (prop)
				icalcomponent_remove_property (icalcomp, prop);
			e_cal_component_rescan (comp);

			master_dtstart = icalcomponent_get_dtstart (e_cal_component_get_icalcomponent (master_comp));
			split_icalcomp = e_cal_util_split_at_instance (icalcomp, rid, master_dtstart);
			if (split_icalcomp) {
				rid = icaltime_convert_to_zone (rid, icaltimezone_get_utc_timezone ());
				e_cal_util_remove_instances (e_cal_component_get_icalcomponent (master_comp), rid, mod);
				e_cal_component_rescan (master_comp);
				e_cal_recur_ensure_end_dates (master_comp, TRUE, e_cal_cache_resolve_timezone_simple_cb, cal_cache);

				if (out_new_comp) {
					g_clear_object (&new_comp);
					new_comp = e_cal_component_clone (master_comp);
				}
			}

			if (split_icalcomp) {
				gchar *new_uid;

				new_uid = e_util_generate_uid ();
				icalcomponent_set_uid (split_icalcomp, new_uid);
				g_free (new_uid);

				g_warn_if_fail (e_cal_component_set_icalcomponent (comp, split_icalcomp));

				e_cal_recur_ensure_end_dates (comp, TRUE, e_cal_cache_resolve_timezone_simple_cb, cal_cache);

				success = ecmb_create_object_sync (meta_backend, cal_cache, offline_flag, E_CONFLICT_RESOLUTION_FAIL,
					comp, NULL, NULL, cancellable, error);
			}
		} else {
			/* Replace master */
			instances = g_slist_remove (instances, master_comp);
			g_clear_object (&master_comp);
			existing_comp = NULL;

			instances = g_slist_prepend (instances, e_cal_component_clone (comp));
		}
		break;
	}

	if (success && *offline_flag == E_CACHE_OFFLINE_UNKNOWN) {
		if (e_backend_get_online (E_BACKEND (meta_backend)) &&
		    e_cal_meta_backend_ensure_connected_sync (meta_backend, cancellable, NULL)) {
			*offline_flag = E_CACHE_IS_ONLINE;
		} else {
			*offline_flag = E_CACHE_IS_OFFLINE;
		}
	}

	if (success && *offline_flag == E_CACHE_IS_ONLINE) {
		success = ecmb_save_component_wrapper_sync (meta_backend, cal_cache, TRUE, conflict_resolution,
			instances, extra, id->uid, &requires_put, &new_uid, &new_extra, cancellable, error);
	}

	if (success && requires_put)
		success = ecmb_put_instances (meta_backend, cal_cache, id->uid, *offline_flag, instances, new_extra ? new_extra : extra, cancellable, error);

	if (!success) {
		g_clear_object (&old_comp);
		g_clear_object (&new_comp);
	}

	if (out_old_comp)
		*out_old_comp = old_comp;
	if (out_new_comp) {
		if (new_uid) {
			if (!e_cal_cache_get_component (cal_cache, new_uid, id->rid, out_new_comp, cancellable, NULL))
				*out_new_comp = NULL;
		} else {
			*out_new_comp = new_comp ? g_object_ref (new_comp) : NULL;
		}
	}

	g_slist_free_full (instances, g_object_unref);
	e_cal_component_free_id (id);
	g_clear_object (&new_comp);
	g_free (new_extra);
	g_free (new_uid);
	g_free (extra);

	return success;
}

static void
ecmb_modify_objects_sync (ECalBackendSync *sync_backend,
			  EDataCal *cal,
			  GCancellable *cancellable,
			  const GSList *calobjs,
			  ECalObjModType mod,
			  GSList **out_old_components,
			  GSList **out_new_components,
			  GError **error)
{
	ECalMetaBackend *meta_backend;
	ECalCache *cal_cache;
	ECacheOfflineFlag offline_flag = E_CACHE_OFFLINE_UNKNOWN;
	EConflictResolution conflict_resolution = E_CONFLICT_RESOLUTION_FAIL;
	icalcomponent_kind backend_kind;
	GSList *link;
	gboolean success = TRUE;

	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));
	g_return_if_fail (calobjs != NULL);
	g_return_if_fail (out_old_components != NULL);
	g_return_if_fail (out_new_components != NULL);

	if (!e_cal_backend_get_writable (E_CAL_BACKEND (sync_backend))) {
		g_propagate_error (error, e_data_cal_create_error (PermissionDenied, NULL));
		return;
	}

	meta_backend = E_CAL_META_BACKEND (sync_backend);
	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	g_return_if_fail (cal_cache != NULL);

	backend_kind = e_cal_backend_get_kind (E_CAL_BACKEND (meta_backend));

	for (link = (GSList *) calobjs; link && success; link = g_slist_next (link)) {
		ECalComponent *comp, *old_comp = NULL, *new_comp = NULL;

		if (g_cancellable_set_error_if_cancelled (cancellable, error))
			break;

		comp = e_cal_component_new_from_string (link->data);
		if (!comp ||
		    !e_cal_component_get_icalcomponent (comp) ||
		    backend_kind != icalcomponent_isa (e_cal_component_get_icalcomponent (comp))) {
			g_propagate_error (error, e_data_cal_create_error (InvalidObject, NULL));
			break;
		}

		success = ecmb_modify_object_sync (meta_backend, cal_cache, &offline_flag, conflict_resolution,
			mod, comp, &old_comp, &new_comp, cancellable, error);

		if (success) {
			*out_old_components = g_slist_prepend (*out_old_components, old_comp);
			*out_new_components = g_slist_prepend (*out_new_components, new_comp);
		}

		g_object_unref (comp);
	}

	*out_old_components = g_slist_reverse (*out_old_components);
	*out_new_components = g_slist_reverse (*out_new_components);

	g_object_unref (cal_cache);
}

static gboolean
ecmb_remove_object_sync (ECalMetaBackend *meta_backend,
			 ECalCache *cal_cache,
			 ECacheOfflineFlag *offline_flag,
			 EConflictResolution conflict_resolution,
			 ECalObjModType mod,
			 const gchar *uid,
			 const gchar *rid,
			 ECalComponent **out_old_comp,
			 ECalComponent **out_new_comp,
			 GCancellable *cancellable,
			 GError **error)
{
	struct icaltimetype itt;
	ECalComponent *old_comp = NULL, *new_comp = NULL, *master_comp, *existing_comp = NULL;
	GSList *instances = NULL;
	gboolean success = TRUE;
	GError *local_error = NULL;

	g_return_val_if_fail (uid != NULL, FALSE);

	if (rid && !*rid)
		rid = NULL;

	if ((mod == E_CAL_OBJ_MOD_THIS_AND_PRIOR ||
	    mod == E_CAL_OBJ_MOD_THIS_AND_FUTURE) && !rid) {
		/* Require Recurrence-ID for these types */
		g_propagate_error (error, e_data_cal_create_error (ObjectNotFound, NULL));
		return FALSE;
	}

	if (!e_cal_cache_get_components_by_uid (cal_cache, uid, &instances, cancellable, &local_error)) {
		if (g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND)) {
			g_clear_error (&local_error);
			local_error = e_data_cal_create_error (ObjectNotFound, NULL);
		}

		g_propagate_error (error, local_error);

		return FALSE;
	}

	master_comp = ecmb_find_in_instances (instances, uid, NULL);
	if (rid) {
		/* Set detached instance as the old object */
		existing_comp = ecmb_find_in_instances (instances, uid, rid);
	}

	if (!existing_comp)
		existing_comp = master_comp;

	/* Pick the first instance in case there's no master component */
	if (!existing_comp)
		existing_comp = instances->data;

	/* Remember old and new components */
	if (out_old_comp && existing_comp)
		old_comp = e_cal_component_clone (existing_comp);

	if (*offline_flag == E_CACHE_OFFLINE_UNKNOWN) {
		if (e_backend_get_online (E_BACKEND (meta_backend)) &&
		    e_cal_meta_backend_ensure_connected_sync (meta_backend, cancellable, NULL)) {
			*offline_flag = E_CACHE_IS_ONLINE;
		} else {
			*offline_flag = E_CACHE_IS_OFFLINE;
		}
	}

	switch (mod) {
	case E_CAL_OBJ_MOD_ALL:
		/* Will remove the whole component below */
		break;
	case E_CAL_OBJ_MOD_ONLY_THIS:
	case E_CAL_OBJ_MOD_THIS:
		if (rid) {
			if (existing_comp != master_comp) {
				/* When it's the last detached instance, then remove all */
				if (instances && instances->data == existing_comp && !instances->next) {
					mod = E_CAL_OBJ_MOD_ALL;
					break;
				}

				instances = g_slist_remove (instances, existing_comp);
				g_clear_object (&existing_comp);
			}

			if (existing_comp == master_comp && master_comp && mod == E_CAL_OBJ_MOD_ONLY_THIS) {
				success = FALSE;
				g_propagate_error (error, e_data_cal_create_error (ObjectNotFound, NULL));
			} else {
				itt = icaltime_from_string (rid);
				if (!itt.zone) {
					ECalComponentDateTime dt;

					e_cal_component_get_dtstart (master_comp, &dt);
					if (dt.value && dt.tzid) {
						icaltimezone *zone = e_cal_cache_resolve_timezone_simple_cb (dt.tzid, cal_cache);

						if (zone)
							itt = icaltime_convert_to_zone (itt, zone);
					}
					e_cal_component_free_datetime (&dt);

					itt = icaltime_convert_to_zone (itt, icaltimezone_get_utc_timezone ());
				}

				if (master_comp)
					e_cal_util_remove_instances (e_cal_component_get_icalcomponent (master_comp), itt, mod);
			}

			if (success && out_new_comp && (master_comp || existing_comp))
				new_comp = e_cal_component_clone (master_comp ? master_comp : existing_comp);
		} else {
			mod = E_CAL_OBJ_MOD_ALL;
		}
		break;
	case E_CAL_OBJ_MOD_THIS_AND_PRIOR:
	case E_CAL_OBJ_MOD_THIS_AND_FUTURE:
		if (master_comp) {
			time_t fromtt, instancett;
			GSList *link, *previous = instances;

			itt = icaltime_from_string (rid);
			if (!itt.zone) {
				ECalComponentDateTime dt;

				e_cal_component_get_dtstart (master_comp, &dt);
				if (dt.value && dt.tzid) {
					icaltimezone *zone = e_cal_cache_resolve_timezone_simple_cb (dt.tzid, cal_cache);

					if (zone)
						itt = icaltime_convert_to_zone (itt, zone);
				}
				e_cal_component_free_datetime (&dt);

				itt = icaltime_convert_to_zone (itt, icaltimezone_get_utc_timezone ());
			}

			e_cal_util_remove_instances (e_cal_component_get_icalcomponent (master_comp), itt, mod);

			fromtt = icaltime_as_timet (itt);

			/* Remove detached instances */
			for (link = instances; link && fromtt > 0;) {
				ECalComponent *comp = link->data;
				ECalComponentRange range;

				if (!e_cal_component_is_instance (comp)) {
					previous = link;
					link = g_slist_next (link);
					continue;
				}

				e_cal_component_get_recurid (comp, &range);
				if (range.datetime.value)
					instancett = icaltime_as_timet (*range.datetime.value);
				else
					instancett = 0;
				e_cal_component_free_range (&range);

				if (instancett > 0 && (
				    (mod == E_CAL_OBJ_MOD_THIS_AND_PRIOR && instancett <= fromtt) ||
				    (mod == E_CAL_OBJ_MOD_THIS_AND_FUTURE && instancett >= fromtt))) {
					GSList *prev_instances = instances;

					instances = g_slist_remove (instances, comp);
					g_clear_object (&comp);

					/* Restart the lookup */
					if (previous == prev_instances)
						previous = instances;

					link = previous;
				} else {
					previous = link;
					link = g_slist_next (link);
				}
			}
		} else {
			mod = E_CAL_OBJ_MOD_ALL;
		}
		break;
	}

	if (success) {
		gchar *extra = NULL;

		if (!e_cal_cache_get_component_extra (cal_cache, uid, NULL, &extra, cancellable, NULL))
			extra = NULL;

		if (mod == E_CAL_OBJ_MOD_ALL) {
			if (*offline_flag == E_CACHE_IS_ONLINE) {
				gchar *ical_string = NULL;

				/* Use the master object, if exists */
				if (e_cal_cache_get_component_as_string (cal_cache, uid, NULL, &ical_string, cancellable, NULL)) {
					success = e_cal_meta_backend_remove_component_sync (meta_backend, conflict_resolution, uid, extra, ical_string, cancellable, &local_error);

					g_free (ical_string);
				} else {
					/* If no master object is available, then delete with the first instance */
					GSList *link;

					for (link = instances; link && success; link = g_slist_next (link)) {
						ECalComponent *comp = link->data;
						ECalComponentId *id;
						gchar *comp_extra = NULL;

						if (!comp)
							continue;

						id = e_cal_component_get_id (comp);
						if (!id)
							continue;

						if (!e_cal_cache_get_component_extra (cal_cache, id->uid, id->rid, &comp_extra, cancellable, NULL)) {
							comp_extra = NULL;
							if (g_cancellable_set_error_if_cancelled (cancellable, &local_error)) {
								success = FALSE;
								e_cal_component_free_id (id);
								break;
							}

							g_warn_if_reached ();
						}

						ical_string = e_cal_component_get_as_string (comp);

						/* This pretends the first instance is the master object and the implementations should count with it */
						success = e_cal_meta_backend_remove_component_sync (meta_backend, conflict_resolution, id->uid, comp_extra, ical_string, cancellable, &local_error);

						e_cal_component_free_id (id);
						g_clear_pointer (&ical_string, g_free);
						g_free (comp_extra);

						/* Stop with the first instance */
						break;
					}
				}

				if (local_error) {
					if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_HOST_NOT_FOUND))
						e_backend_set_online (E_BACKEND (meta_backend), FALSE);

					g_propagate_error (error, local_error);
					success = FALSE;
				}
			}

			success = success && ecmb_maybe_remove_from_cache (meta_backend, cal_cache, *offline_flag, uid, cancellable, error);
		} else {
			gboolean requires_put = TRUE;
			gchar *new_uid = NULL, *new_extra = NULL;

			if (master_comp) {
				icalcomponent *icalcomp = e_cal_component_get_icalcomponent (master_comp);

				icalcomponent_set_sequence (icalcomp, icalcomponent_get_sequence (icalcomp) + 1);

				e_cal_component_rescan (master_comp);

				/* Set the last modified time on the component */
				itt = icaltime_current_time_with_zone (icaltimezone_get_utc_timezone ());
				e_cal_component_set_last_modified (master_comp, &itt);
			}

			if (*offline_flag == E_CACHE_IS_ONLINE) {
				success = ecmb_save_component_wrapper_sync (meta_backend, cal_cache, TRUE, conflict_resolution,
					instances, extra, uid, &requires_put, &new_uid, &new_extra, cancellable, error);
			}

			if (success && requires_put)
				success = ecmb_put_instances (meta_backend, cal_cache, uid, *offline_flag, instances, new_extra ? new_extra : extra, cancellable, error);

			if (success && new_uid && !requires_put) {
				g_clear_object (&new_comp);

				if (!e_cal_cache_get_component (cal_cache, new_uid, NULL, &new_comp, cancellable, NULL))
					new_comp = NULL;
			}

			g_free (new_uid);
			g_free (new_extra);
		}

		g_free (extra);
	}

	if (!success) {
		g_clear_object (&old_comp);
		g_clear_object (&new_comp);
	}

	if (out_old_comp)
		*out_old_comp = old_comp;
	if (out_new_comp)
		*out_new_comp = new_comp;

	g_slist_free_full (instances, g_object_unref);

	return success;
}

static void
ecmb_remove_objects_sync (ECalBackendSync *sync_backend,
			  EDataCal *cal,
			  GCancellable *cancellable,
			  const GSList *ids,
			  ECalObjModType mod,
			  GSList **out_old_components,
			  GSList **out_new_components,
			  GError **error)
{
	ECalMetaBackend *meta_backend;
	ECalCache *cal_cache;
	ECacheOfflineFlag offline_flag = E_CACHE_OFFLINE_UNKNOWN;
	EConflictResolution conflict_resolution = E_CONFLICT_RESOLUTION_FAIL;
	GSList *link;
	gboolean success = TRUE;

	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));
	g_return_if_fail (ids != NULL);
	g_return_if_fail (out_old_components != NULL);
	g_return_if_fail (out_new_components != NULL);

	if (!e_cal_backend_get_writable (E_CAL_BACKEND (sync_backend))) {
		g_propagate_error (error, e_data_cal_create_error (PermissionDenied, NULL));
		return;
	}

	meta_backend = E_CAL_META_BACKEND (sync_backend);
	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	g_return_if_fail (cal_cache != NULL);

	for (link = (GSList *) ids; link && success; link = g_slist_next (link)) {
		ECalComponent *old_comp = NULL, *new_comp = NULL;
		ECalComponentId *id = link->data;

		if (g_cancellable_set_error_if_cancelled (cancellable, error))
			break;

		if (!id) {
			g_propagate_error (error, e_data_cal_create_error (InvalidObject, NULL));
			break;
		}

		success = ecmb_remove_object_sync (meta_backend, cal_cache, &offline_flag, conflict_resolution,
			mod, id->uid, id->rid, &old_comp, &new_comp, cancellable, error);

		if (success) {
			*out_old_components = g_slist_prepend (*out_old_components, old_comp);
			*out_new_components = g_slist_prepend (*out_new_components, new_comp);
		}
	}

	*out_old_components = g_slist_reverse (*out_old_components);
	*out_new_components = g_slist_reverse (*out_new_components);

	g_object_unref (cal_cache);
}

static gboolean
ecmb_receive_object_sync (ECalMetaBackend *meta_backend,
			  ECalCache *cal_cache,
			  ECacheOfflineFlag *offline_flag,
			  EConflictResolution conflict_resolution,
			  ECalComponent *comp,
			  icalproperty_method method,
			  GCancellable *cancellable,
			  GError **error)
{
	ESourceRegistry *registry;
	ECalBackend *cal_backend;
	gboolean is_declined, is_in_cache;
	ECalObjModType mod;
	ECalComponentId *id;
	gboolean success = FALSE;

	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	id = e_cal_component_get_id (comp);

	if (!id && method == ICAL_METHOD_PUBLISH) {
		gchar *new_uid;

		new_uid = e_util_generate_uid ();
		e_cal_component_set_uid (comp, new_uid);
		g_free (new_uid);

		id = e_cal_component_get_id (comp);
	}

	if (!id) {
		g_propagate_error (error, e_data_cal_create_error (InvalidObject, NULL));
		return FALSE;
	}

	cal_backend = E_CAL_BACKEND (meta_backend);
	registry = e_cal_backend_get_registry (cal_backend);

	/* Just to check whether component exists in the cache */
	is_in_cache = e_cal_cache_contains (cal_cache, id->uid, NULL, E_CACHE_EXCLUDE_DELETED) ||
		(id->rid && *id->rid && e_cal_cache_contains (cal_cache, id->uid, id->rid, E_CACHE_EXCLUDE_DELETED));

	/* For cases when there's no master object in the cache */
	if (!is_in_cache) {
		GSList *icalstrings = NULL;

		if (e_cal_cache_get_components_by_uid_as_string (cal_cache, id->uid, &icalstrings, cancellable, NULL)) {
			is_in_cache = icalstrings && icalstrings->data;
			g_slist_free_full (icalstrings, g_free);
		}
	}

	mod = e_cal_component_is_instance (comp) ? E_CAL_OBJ_MOD_THIS : E_CAL_OBJ_MOD_ALL;

	switch (method) {
	case ICAL_METHOD_PUBLISH:
	case ICAL_METHOD_REQUEST:
	case ICAL_METHOD_REPLY:
		is_declined = e_cal_backend_user_declined (registry, e_cal_component_get_icalcomponent (comp));
		if (is_in_cache) {
			if (!is_declined) {
				success = ecmb_modify_object_sync (meta_backend, cal_cache, offline_flag, conflict_resolution,
					mod, comp, NULL, NULL, cancellable, error);
			} else {
				success = ecmb_remove_object_sync (meta_backend, cal_cache, offline_flag, conflict_resolution,
					mod, id->uid, id->rid, NULL, NULL, cancellable, error);
			}
		} else if (!is_declined) {
			success = ecmb_create_object_sync (meta_backend, cal_cache, offline_flag, conflict_resolution,
				comp, NULL, NULL, cancellable, error);
		}
		break;
	case ICAL_METHOD_CANCEL:
		if (is_in_cache) {
			success = ecmb_remove_object_sync (meta_backend, cal_cache, offline_flag, conflict_resolution,
				E_CAL_OBJ_MOD_THIS, id->uid, id->rid, NULL, NULL, cancellable, error);
		} else {
			g_propagate_error (error, e_data_cal_create_error (ObjectNotFound, NULL));
		}
		break;

	default:
		g_propagate_error (error, e_data_cal_create_error (UnsupportedMethod, NULL));
		break;
	}

	e_cal_component_free_id (id);

	return success;
}

static void
ecmb_receive_objects_sync (ECalBackendSync *sync_backend,
			   EDataCal *cal,
			   GCancellable *cancellable,
			   const gchar *calobj,
			   GError **error)
{
	ECalMetaBackend *meta_backend;
	ECacheOfflineFlag offline_flag = E_CACHE_OFFLINE_UNKNOWN;
	EConflictResolution conflict_resolution = E_CONFLICT_RESOLUTION_FAIL;
	ECalCache *cal_cache;
	ECalComponent *comp;
	icalcomponent *icalcomp, *subcomp;
	icalcomponent_kind kind;
	icalproperty_method top_method;
	GSList *comps = NULL, *link;
	gboolean success = TRUE;

	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));
	g_return_if_fail (calobj != NULL);

	if (!e_cal_backend_get_writable (E_CAL_BACKEND (sync_backend))) {
		g_propagate_error (error, e_data_cal_create_error (PermissionDenied, NULL));
		return;
	}

	meta_backend = E_CAL_META_BACKEND (sync_backend);
	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	g_return_if_fail (cal_cache != NULL);

	icalcomp = icalparser_parse_string (calobj);
	if (!icalcomp) {
		g_propagate_error (error, e_data_cal_create_error (InvalidObject, NULL));
		g_object_unref (cal_cache);
		return;
	}

	kind = e_cal_backend_get_kind (E_CAL_BACKEND (meta_backend));

	if (icalcomponent_isa (icalcomp) == ICAL_VCALENDAR_COMPONENT) {
		for (subcomp = icalcomponent_get_first_component (icalcomp, kind);
		     subcomp && success;
		     subcomp = icalcomponent_get_next_component (icalcomp, kind)) {
			comp = e_cal_component_new_from_icalcomponent (icalcomponent_new_clone (subcomp));

			if (comp)
				comps = g_slist_prepend (comps, comp);
		}
	} else if (icalcomponent_isa (icalcomp) == kind) {
		comp = e_cal_component_new_from_icalcomponent (icalcomponent_new_clone (icalcomp));

		if (comp)
			comps = g_slist_prepend (comps, comp);
	}

	if (!comps) {
		g_propagate_error (error, e_data_cal_create_error (InvalidObject, NULL));
		icalcomponent_free (icalcomp);
		g_object_unref (cal_cache);
		return;
	}

	comps = g_slist_reverse (comps);

	if (icalcomponent_isa (icalcomp) == ICAL_VCALENDAR_COMPONENT)
		ecmb_gather_timezones (meta_backend, E_TIMEZONE_CACHE (meta_backend), icalcomp);

	if (icalcomponent_get_first_property (icalcomp, ICAL_METHOD_PROPERTY))
		top_method = icalcomponent_get_method (icalcomp);
	else
		top_method = ICAL_METHOD_PUBLISH;

	for (link = comps; link && success; link = g_slist_next (link)) {
		ECalComponent *comp = link->data;
		icalproperty_method method;

		subcomp = e_cal_component_get_icalcomponent (comp);

		if (icalcomponent_get_first_property (subcomp, ICAL_METHOD_PROPERTY)) {
			method = icalcomponent_get_method (subcomp);
		} else {
			method = top_method;
		}

		success = ecmb_receive_object_sync (meta_backend, cal_cache, &offline_flag, conflict_resolution,
			comp, method, cancellable, error);
	}

	g_slist_free_full (comps, g_object_unref);
	icalcomponent_free (icalcomp);
	g_object_unref (cal_cache);
}

static void
ecmb_send_objects_sync (ECalBackendSync *sync_backend,
			EDataCal *cal,
			GCancellable *cancellable,
			const gchar *calobj,
			GSList **out_users,
			gchar **out_modified_calobj,
			GError **error)
{
	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));
	g_return_if_fail (calobj != NULL);
	g_return_if_fail (out_users != NULL);
	g_return_if_fail (out_modified_calobj != NULL);

	*out_users = NULL;
	*out_modified_calobj = g_strdup (calobj);
}

static void
ecmb_add_attachment_uris (ECalComponent *comp,
			  GSList **out_uris)
{
	icalcomponent *icalcomp;
	icalproperty *prop;

	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (out_uris != NULL);

	icalcomp = e_cal_component_get_icalcomponent (comp);
	g_return_if_fail (icalcomp != NULL);

	for (prop = icalcomponent_get_first_property (icalcomp, ICAL_ATTACH_PROPERTY);
	     prop;
	     prop = icalcomponent_get_next_property (icalcomp, ICAL_ATTACH_PROPERTY)) {
		icalattach *attach = icalproperty_get_attach (prop);

		if (attach && icalattach_get_is_url (attach)) {
			const gchar *url;

			url = icalattach_get_url (attach);
			if (url) {
				gsize buf_size;
				gchar *buf;

				buf_size = strlen (url);
				buf = g_malloc0 (buf_size + 1);

				icalvalue_decode_ical_string (url, buf, buf_size);

				*out_uris = g_slist_prepend (*out_uris, g_strdup (buf));

				g_free (buf);
			}
		}
	}
}

static void
ecmb_get_attachment_uris_sync (ECalBackendSync *sync_backend,
			       EDataCal *cal,
			       GCancellable *cancellable,
			       const gchar *uid,
			       const gchar *rid,
			       GSList **out_uris,
			       GError **error)
{
	ECalMetaBackend *meta_backend;
	ECalCache *cal_cache;
	ECalComponent *comp;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));
	g_return_if_fail (uid != NULL);
	g_return_if_fail (out_uris != NULL);

	*out_uris = NULL;

	meta_backend = E_CAL_META_BACKEND (sync_backend);
	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	g_return_if_fail (cal_cache != NULL);

	if (rid && *rid) {
		if (e_cal_cache_get_component (cal_cache, uid, rid, &comp, cancellable, &local_error) && comp) {
			ecmb_add_attachment_uris (comp, out_uris);
			g_object_unref (comp);
		}
	} else {
		GSList *comps = NULL, *link;

		if (e_cal_cache_get_components_by_uid (cal_cache, uid, &comps, cancellable, &local_error)) {
			for (link = comps; link; link = g_slist_next (link)) {
				comp = link->data;

				ecmb_add_attachment_uris (comp, out_uris);
			}

			g_slist_free_full (comps, g_object_unref);
		}
	}

	g_object_unref (cal_cache);

	*out_uris = g_slist_reverse (*out_uris);

	if (local_error) {
		if (g_error_matches (local_error, E_CACHE_ERROR, E_CACHE_ERROR_NOT_FOUND)) {
			g_clear_error (&local_error);
			local_error = e_data_cal_create_error (ObjectNotFound, NULL);
		}

		g_propagate_error (error, local_error);
	}
}

static void
ecmb_discard_alarm_sync (ECalBackendSync *sync_backend,
			 EDataCal *cal,
			 GCancellable *cancellable,
			 const gchar *uid,
			 const gchar *rid,
			 const gchar *auid,
			 GError **error)
{
	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));
	g_return_if_fail (uid != NULL);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return;

	g_set_error_literal (error, E_CLIENT_ERROR, E_CLIENT_ERROR_NOT_SUPPORTED,
		e_client_error_to_string (E_CLIENT_ERROR_NOT_SUPPORTED));
}

static void
ecmb_get_timezone_sync (ECalBackendSync *sync_backend,
			EDataCal *cal,
			GCancellable *cancellable,
			const gchar *tzid,
			gchar **tzobject,
			GError **error)
{
	icaltimezone *zone;
	gchar *timezone_str = NULL;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));
	g_return_if_fail (tzid != NULL);
	g_return_if_fail (tzobject != NULL);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return;

	zone = e_timezone_cache_get_timezone (E_TIMEZONE_CACHE (sync_backend), tzid);
	if (zone) {
		icalcomponent *icalcomp;

		icalcomp = icaltimezone_get_component (zone);

		if (!icalcomp) {
			local_error = e_data_cal_create_error (InvalidObject, NULL);
		} else {
			timezone_str = icalcomponent_as_ical_string_r (icalcomp);
		}
	}

	if (!local_error && !timezone_str)
		local_error = e_data_cal_create_error (ObjectNotFound, NULL);

	*tzobject = timezone_str;

	if (local_error)
		g_propagate_error (error, local_error);
}

static void
ecmb_add_timezone_sync (ECalBackendSync *sync_backend,
			EDataCal *cal,
			GCancellable *cancellable,
			const gchar *tzobject,
			GError **error)
{
	icalcomponent *tz_comp;

	g_return_if_fail (E_IS_CAL_META_BACKEND (sync_backend));

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return;

	if (!tzobject || !*tzobject) {
		g_propagate_error (error, e_data_cal_create_error (InvalidObject, NULL));
		return;
	}

	tz_comp = icalparser_parse_string (tzobject);
	if (!tz_comp ||
	    icalcomponent_isa (tz_comp) != ICAL_VTIMEZONE_COMPONENT) {
		g_propagate_error (error, e_data_cal_create_error (InvalidObject, NULL));
	} else {
		icaltimezone *zone;

		zone = icaltimezone_new ();
		icaltimezone_set_component (zone, tz_comp);

		tz_comp = NULL;

		/* Add it only to memory, do not store it persistently into the ECalCache */
		e_timezone_cache_add_timezone (E_TIMEZONE_CACHE (sync_backend), zone);
		icaltimezone_free (zone, 1);
	}

	if (tz_comp)
		icalcomponent_free (tz_comp);
}

static gchar *
ecmb_get_backend_property (ECalBackend *cal_backend,
			   const gchar *prop_name)
{
	g_return_val_if_fail (E_IS_CAL_META_BACKEND (cal_backend), NULL);
	g_return_val_if_fail (prop_name != NULL, NULL);

	if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_REVISION)) {
		ECalCache *cal_cache;
		gchar *revision = NULL;

		cal_cache = e_cal_meta_backend_ref_cache (E_CAL_META_BACKEND (cal_backend));
		if (cal_cache) {
			revision = e_cache_dup_revision (E_CACHE (cal_cache));
			g_object_unref (cal_cache);
		} else {
			g_warn_if_reached ();
		}

		return revision;
	} else if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_DEFAULT_OBJECT)) {
		ECalComponent *comp;
		gchar *prop_value;

		comp = e_cal_component_new ();

		switch (e_cal_backend_get_kind (cal_backend)) {
		case ICAL_VEVENT_COMPONENT:
			e_cal_component_set_new_vtype (comp, E_CAL_COMPONENT_EVENT);
			break;
		case ICAL_VTODO_COMPONENT:
			e_cal_component_set_new_vtype (comp, E_CAL_COMPONENT_TODO);
			break;
		case ICAL_VJOURNAL_COMPONENT:
			e_cal_component_set_new_vtype (comp, E_CAL_COMPONENT_JOURNAL);
			break;
		default:
			g_object_unref (comp);
			return NULL;
		}

		prop_value = e_cal_component_get_as_string (comp);

		g_object_unref (comp);

		return prop_value;
	} else if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_CAPABILITIES)) {
		return g_strdup (e_cal_meta_backend_get_capabilities (E_CAL_META_BACKEND (cal_backend)));
	}

	/* Chain up to parent's method. */
	return E_CAL_BACKEND_CLASS (e_cal_meta_backend_parent_class)->get_backend_property (cal_backend, prop_name);
}

static void
ecmb_start_view (ECalBackend *cal_backend,
		 EDataCalView *view)
{
	GCancellable *cancellable;

	g_return_if_fail (E_IS_CAL_META_BACKEND (cal_backend));

	cancellable = ecmb_create_view_cancellable (E_CAL_META_BACKEND (cal_backend), view);

	e_cal_backend_schedule_custom_operation (cal_backend, cancellable,
		ecmb_start_view_thread_func, g_object_ref (view), g_object_unref);

	g_object_unref (cancellable);
}

static void
ecmb_stop_view (ECalBackend *cal_backend,
		EDataCalView *view)
{
	GCancellable *cancellable;

	g_return_if_fail (E_IS_CAL_META_BACKEND (cal_backend));

	cancellable = ecmb_steal_view_cancellable (E_CAL_META_BACKEND (cal_backend), view);
	if (cancellable) {
		g_cancellable_cancel (cancellable);
		g_object_unref (cancellable);
	}
}

static ESourceAuthenticationResult
ecmb_authenticate_sync (EBackend *backend,
			const ENamedParameters *credentials,
			gchar **out_certificate_pem,
			GTlsCertificateFlags *out_certificate_errors,
			GCancellable *cancellable,
			GError **error)
{
	ECalMetaBackend *meta_backend;
	ESourceAuthenticationResult auth_result = E_SOURCE_AUTHENTICATION_UNKNOWN;
	gboolean success, refresh_after_authenticate = FALSE;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (backend), E_SOURCE_AUTHENTICATION_ERROR);

	meta_backend = E_CAL_META_BACKEND (backend);

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
	e_cal_meta_backend_disconnect_sync (meta_backend, cancellable, NULL);

	success = e_cal_meta_backend_connect_sync (meta_backend, credentials, &auth_result,
		out_certificate_pem, out_certificate_errors, cancellable, error);

	if (success) {
		ecmb_update_connection_values (meta_backend);
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
		e_cal_meta_backend_schedule_refresh (meta_backend);

	return auth_result;
}

static void
ecmb_schedule_source_changed (ECalMetaBackend *meta_backend)
{
	GCancellable *cancellable;

	g_return_if_fail (E_IS_CAL_META_BACKEND (meta_backend));

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->source_changed_cancellable) {
		/* Already updating */
		g_mutex_unlock (&meta_backend->priv->property_lock);
		return;
	}

	cancellable = g_cancellable_new ();
	meta_backend->priv->source_changed_cancellable = g_object_ref (cancellable);

	g_mutex_unlock (&meta_backend->priv->property_lock);

	e_cal_backend_schedule_custom_operation (E_CAL_BACKEND (meta_backend), cancellable,
		ecmb_source_changed_thread_func, NULL, NULL);

	g_object_unref (cancellable);
}

static void
ecmb_schedule_go_offline (ECalMetaBackend *meta_backend)
{
	GCancellable *cancellable;

	g_return_if_fail (E_IS_CAL_META_BACKEND (meta_backend));

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

	e_cal_backend_schedule_custom_operation (E_CAL_BACKEND (meta_backend), cancellable,
		ecmb_go_offline_thread_func, NULL, NULL);

	g_object_unref (cancellable);
}

static void
ecmb_notify_online_cb (GObject *object,
		       GParamSpec *param,
		       gpointer user_data)
{
	ECalMetaBackend *meta_backend = user_data;
	gboolean new_value;

	g_return_if_fail (E_IS_CAL_META_BACKEND (meta_backend));

	new_value = e_backend_get_online (E_BACKEND (meta_backend));
	if (!new_value == !meta_backend->priv->current_online_state)
		return;

	meta_backend->priv->current_online_state = new_value;

	if (new_value)
		e_cal_meta_backend_schedule_refresh (meta_backend);
	else
		ecmb_schedule_go_offline (meta_backend);
}

static void
ecmb_cancel_view_cb (gpointer key,
		     gpointer value,
		     gpointer user_data)
{
	GCancellable *cancellable = value;

	g_return_if_fail (G_IS_CANCELLABLE (cancellable));

	g_cancellable_cancel (cancellable);
}

static void
ecmb_wait_for_credentials_cancelled_cb (GCancellable *cancellable,
					gpointer user_data)
{
	ECalMetaBackend *meta_backend = user_data;

	g_return_if_fail (E_IS_CAL_META_BACKEND (meta_backend));

	g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
	g_cond_broadcast (&meta_backend->priv->wait_credentials_cond);
	g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);
}

static gboolean
ecmb_maybe_wait_for_credentials (ECalMetaBackend *meta_backend,
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

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

	if (!op_error || g_cancellable_is_cancelled (cancellable))
		return FALSE;

	if (g_error_matches (op_error, E_DATA_CAL_ERROR, TLSNotAvailable) &&
	    e_cal_meta_backend_get_ssl_error_details (meta_backend, &certificate_pem, &certificate_errors)) {
		reason = E_SOURCE_CREDENTIALS_REASON_SSL_FAILED;
	} else if (g_error_matches (op_error, E_DATA_CAL_ERROR, AuthenticationRequired)) {
		reason = E_SOURCE_CREDENTIALS_REASON_REQUIRED;
	} else if (g_error_matches (op_error, E_DATA_CAL_ERROR, AuthenticationFailed)) {
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
			G_CALLBACK (ecmb_wait_for_credentials_cancelled_cb), meta_backend) : 0;

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

static icaltimezone *
ecmb_get_cached_timezone (ETimezoneCache *cache,
			  const gchar *tzid)
{
	ECalCache *cal_cache;
	icaltimezone *zone;

	if (ecmb_timezone_cache_parent_get_timezone) {
		zone = ecmb_timezone_cache_parent_get_timezone (cache, tzid);

		if (zone)
			return zone;
	}

	cal_cache = e_cal_meta_backend_ref_cache (E_CAL_META_BACKEND (cache));
	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), NULL);

	zone = e_timezone_cache_get_timezone (E_TIMEZONE_CACHE (cal_cache), tzid);

	g_clear_object (&cal_cache);

	return zone;
}

static GList *
ecmb_list_cached_timezones (ETimezoneCache *cache)
{
	ECalCache *cal_cache;
	GList *zones;

	cal_cache = e_cal_meta_backend_ref_cache (E_CAL_META_BACKEND (cache));
	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), NULL);

	zones = e_timezone_cache_list_timezones (E_TIMEZONE_CACHE (cal_cache));

	g_clear_object (&cal_cache);

	if (ecmb_timezone_cache_parent_list_timezones) {
		GList *backend_zones;

		backend_zones = ecmb_timezone_cache_parent_list_timezones (E_TIMEZONE_CACHE (cache));

		/* There can be duplicates in the 'zones' GList, but let's make it no big deal */
		if (backend_zones)
			zones = g_list_concat (zones, backend_zones);
	}

	return zones;
}

static void
e_cal_meta_backend_set_property (GObject *object,
				 guint property_id,
				 const GValue *value,
				 GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CACHE:
			e_cal_meta_backend_set_cache (
				E_CAL_META_BACKEND (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_cal_meta_backend_get_property (GObject *object,
				 guint property_id,
				 GValue *value,
				 GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CACHE:
			g_value_take_object (
				value,
				e_cal_meta_backend_ref_cache (
				E_CAL_META_BACKEND (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_cal_meta_backend_constructed (GObject *object)
{
	ECalMetaBackend *meta_backend = E_CAL_META_BACKEND (object);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_cal_meta_backend_parent_class)->constructed (object);

	meta_backend->priv->current_online_state = e_backend_get_online (E_BACKEND (meta_backend));

	meta_backend->priv->notify_online_id = g_signal_connect (meta_backend, "notify::online",
		G_CALLBACK (ecmb_notify_online_cb), meta_backend);

	if (!meta_backend->priv->cache) {
		ECalCache *cache;
		gchar *filename;

		filename = g_build_filename (e_cal_backend_get_cache_dir (E_CAL_BACKEND (meta_backend)), "cache.db", NULL);
		cache = e_cal_cache_new (filename, NULL, &meta_backend->priv->create_cache_error);
		g_prefix_error (&meta_backend->priv->create_cache_error, _("Failed to create cache “%s”:"), filename);

		g_free (filename);

		if (cache) {
			e_cal_meta_backend_set_cache (meta_backend, cache);
			g_clear_object (&cache);
		}
	}
}

static void
e_cal_meta_backend_dispose (GObject *object)
{
	ECalMetaBackend *meta_backend = E_CAL_META_BACKEND (object);
	ESource *source = e_backend_get_source (E_BACKEND (meta_backend));

	g_mutex_lock (&meta_backend->priv->property_lock);

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

	if (meta_backend->priv->get_timezone_id) {
		if (meta_backend->priv->cache)
			g_signal_handler_disconnect (meta_backend->priv->cache, meta_backend->priv->get_timezone_id);
		meta_backend->priv->get_timezone_id = 0;
	}

	g_hash_table_foreach (meta_backend->priv->view_cancellables, ecmb_cancel_view_cb, NULL);

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
	G_OBJECT_CLASS (e_cal_meta_backend_parent_class)->dispose (object);
}

static void
e_cal_meta_backend_finalize (GObject *object)
{
	ECalMetaBackend *meta_backend = E_CAL_META_BACKEND (object);

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
	G_OBJECT_CLASS (e_cal_meta_backend_parent_class)->finalize (object);
}

static void
e_cal_meta_backend_class_init (ECalMetaBackendClass *klass)
{
	GObjectClass *object_class;
	EBackendClass *backend_class;
	ECalBackendClass *cal_backend_class;
	ECalBackendSyncClass *cal_backend_sync_class;

	g_type_class_add_private (klass, sizeof (ECalMetaBackendPrivate));

	klass->get_changes_sync = ecmb_get_changes_sync;
	klass->search_sync = ecmb_search_sync;
	klass->search_components_sync = ecmb_search_components_sync;
	klass->requires_reconnect = ecmb_requires_reconnect;
	klass->get_ssl_error_details = ecmb_get_ssl_error_details;

	cal_backend_sync_class = E_CAL_BACKEND_SYNC_CLASS (klass);
	cal_backend_sync_class->open_sync = ecmb_open_sync;
	cal_backend_sync_class->refresh_sync = ecmb_refresh_sync;
	cal_backend_sync_class->get_object_sync = ecmb_get_object_sync;
	cal_backend_sync_class->get_object_list_sync = ecmb_get_object_list_sync;
	cal_backend_sync_class->get_free_busy_sync = ecmb_get_free_busy_sync;
	cal_backend_sync_class->create_objects_sync = ecmb_create_objects_sync;
	cal_backend_sync_class->modify_objects_sync = ecmb_modify_objects_sync;
	cal_backend_sync_class->remove_objects_sync = ecmb_remove_objects_sync;
	cal_backend_sync_class->receive_objects_sync = ecmb_receive_objects_sync;
	cal_backend_sync_class->send_objects_sync = ecmb_send_objects_sync;
	cal_backend_sync_class->get_attachment_uris_sync = ecmb_get_attachment_uris_sync;
	cal_backend_sync_class->discard_alarm_sync = ecmb_discard_alarm_sync;
	cal_backend_sync_class->get_timezone_sync = ecmb_get_timezone_sync;
	cal_backend_sync_class->add_timezone_sync = ecmb_add_timezone_sync;

	cal_backend_class = E_CAL_BACKEND_CLASS (klass);
	cal_backend_class->get_backend_property = ecmb_get_backend_property;
	cal_backend_class->start_view = ecmb_start_view;
	cal_backend_class->stop_view = ecmb_stop_view;

	backend_class = E_BACKEND_CLASS (klass);
	backend_class->authenticate_sync = ecmb_authenticate_sync;

	object_class = G_OBJECT_CLASS (klass);
	object_class->set_property = e_cal_meta_backend_set_property;
	object_class->get_property = e_cal_meta_backend_get_property;
	object_class->constructed = e_cal_meta_backend_constructed;
	object_class->dispose = e_cal_meta_backend_dispose;
	object_class->finalize = e_cal_meta_backend_finalize;

	/**
	 * ECalMetaBackend:cache:
	 *
	 * The #ECalCache being used for this meta backend.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_CACHE,
		g_param_spec_object (
			"cache",
			"Cache",
			"Calendar Cache",
			E_TYPE_CAL_CACHE,
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
	 * ECalMetaBackend::source-changed
	 *
	 * This signal is emitted whenever the underlying backend #ESource
	 * changes. Unlike the #ESource's 'changed' signal this one is
	 * tight to the #ECalMetaBackend itself and is emitted from
	 * a dedicated thread, thus it doesn't block the main thread.
	 *
	 * Since: 3.26
	 **/
	signals[SOURCE_CHANGED] = g_signal_new (
		"source-changed",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ECalMetaBackendClass, source_changed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0, G_TYPE_NONE);
}

static void
e_cal_meta_backend_init (ECalMetaBackend *meta_backend)
{
	meta_backend->priv = G_TYPE_INSTANCE_GET_PRIVATE (meta_backend, E_TYPE_CAL_META_BACKEND, ECalMetaBackendPrivate);

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

static void
e_cal_meta_backend_timezone_cache_init (ETimezoneCacheInterface *iface)
{
	ecmb_timezone_cache_parent_get_timezone = iface->get_timezone;
	ecmb_timezone_cache_parent_list_timezones = iface->list_timezones;

	/* leave the iface->add_timezone as it was, to have them in memory only */
	iface->get_timezone = ecmb_get_cached_timezone;
	iface->list_timezones = ecmb_list_cached_timezones;
}

/**
 * e_cal_meta_backend_get_capabilities:
 * @meta_backend: an #ECalMetaBackend
 *
 * Returns: an #ECalBackend::capabilities property to be used by
 *    the descendant in conjunction to the descendant's capabilities
 *    in the result of e_cal_backend_get_backend_property() with
 *    #CLIENT_BACKEND_PROPERTY_CAPABILITIES.
 *
 * Since: 3.26
 **/
const gchar *
e_cal_meta_backend_get_capabilities (ECalMetaBackend *meta_backend)
{
	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), NULL);

	return CAL_STATIC_CAPABILITY_REFRESH_SUPPORTED ","
		CAL_STATIC_CAPABILITY_BULK_ADDS ","
		CAL_STATIC_CAPABILITY_BULK_MODIFIES ","
		CAL_STATIC_CAPABILITY_BULK_REMOVES;
}

/**
 * e_cal_meta_backend_set_ever_connected:
 * @meta_backend: an #ECalMetaBackend
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
e_cal_meta_backend_set_ever_connected (ECalMetaBackend *meta_backend,
				       gboolean value)
{
	ECalCache *cal_cache;

	g_return_if_fail (E_IS_CAL_META_BACKEND (meta_backend));

	if ((value ? 1 : 0) == meta_backend->priv->ever_connected)
		return;

	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	meta_backend->priv->ever_connected = value ? 1 : 0;
	e_cache_set_key_int (E_CACHE (cal_cache), ECMB_KEY_EVER_CONNECTED, meta_backend->priv->ever_connected, NULL);
	g_clear_object (&cal_cache);
}

/**
 * e_cal_meta_backend_get_ever_connected:
 * @meta_backend: an #ECalMetaBackend
 *
 * Returns: Whether the @meta_backend ever made a successful connection
 *    to its destination.
 *
 * Since: 3.26
 **/
gboolean
e_cal_meta_backend_get_ever_connected (ECalMetaBackend *meta_backend)
{
	gboolean result;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

	if (meta_backend->priv->ever_connected == -1) {
		ECalCache *cal_cache;

		cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
		result = e_cache_get_key_int (E_CACHE (cal_cache), ECMB_KEY_EVER_CONNECTED, NULL) == 1;
		g_clear_object (&cal_cache);

		meta_backend->priv->ever_connected = result ? 1 : 0;
	} else {
		result = meta_backend->priv->ever_connected == 1;
	}

	return result;
}

/**
 * e_cal_meta_backend_set_connected_writable:
 * @meta_backend: an #ECalMetaBackend
 * @value: value to set
 *
 * Sets whether the @meta_backend connected to a writable destination.
 * This value has meaning only if e_cal_meta_backend_get_ever_connected()
 * is %TRUE.
 *
 * This is used by the @meta_backend itself, during the opening phase,
 * to set the backend writable or not also in the offline mode.
 *
 * Since: 3.26
 **/
void
e_cal_meta_backend_set_connected_writable (ECalMetaBackend *meta_backend,
					   gboolean value)
{
	ECalCache *cal_cache;

	g_return_if_fail (E_IS_CAL_META_BACKEND (meta_backend));

	if ((value ? 1 : 0) == meta_backend->priv->connected_writable)
		return;

	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	meta_backend->priv->connected_writable = value ? 1 : 0;
	e_cache_set_key_int (E_CACHE (cal_cache), ECMB_KEY_CONNECTED_WRITABLE, meta_backend->priv->connected_writable, NULL);
	g_clear_object (&cal_cache);
}

/**
 * e_cal_meta_backend_get_connected_writable:
 * @meta_backend: an #ECalMetaBackend
 *
 * This value has meaning only if e_cal_meta_backend_get_ever_connected()
 * is %TRUE.
 *
 * Returns: Whether the @meta_backend connected to a writable destination.
 *
 * Since: 3.26
 **/
gboolean
e_cal_meta_backend_get_connected_writable (ECalMetaBackend *meta_backend)
{
	gboolean result;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

	if (meta_backend->priv->connected_writable == -1) {
		ECalCache *cal_cache;

		cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
		result = e_cache_get_key_int (E_CACHE (cal_cache), ECMB_KEY_CONNECTED_WRITABLE, NULL) == 1;
		g_clear_object (&cal_cache);

		meta_backend->priv->connected_writable = result ? 1 : 0;
	} else {
		result = meta_backend->priv->connected_writable == 1;
	}

	return result;
}

/**
 * e_cal_meta_backend_dup_sync_tag:
 * @meta_backend: an #ECalMetaBackend
 *
 * Returns the last known synchronization tag, the same as used to
 * call e_cal_meta_backend_get_changes_sync().
 *
 * Free the returned string with g_free(), when no longer needed.
 *
 * Returns: (transfer full) (nullable): The last known synchronization tag,
 *    or %NULL, when none is stored.
 *
 * Since: 3.28
 **/
gchar *
e_cal_meta_backend_dup_sync_tag (ECalMetaBackend *meta_backend)
{
	ECalCache *cal_cache;
	gchar *sync_tag;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), NULL);

	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	if (!cal_cache)
		return NULL;

	sync_tag = e_cache_dup_key (E_CACHE (cal_cache), ECMB_KEY_SYNC_TAG, NULL);
	if (sync_tag && !*sync_tag) {
		g_free (sync_tag);
		sync_tag = NULL;
	}

	g_clear_object (&cal_cache);

	return sync_tag;
}

static void
ecmb_cache_revision_changed_cb (ECache *cache,
				gpointer user_data)
{
	ECalMetaBackend *meta_backend = user_data;
	gchar *revision;

	g_return_if_fail (E_IS_CACHE (cache));
	g_return_if_fail (E_IS_CAL_META_BACKEND (meta_backend));

	revision = e_cache_dup_revision (cache);
	if (revision) {
		e_cal_backend_notify_property_changed (E_CAL_BACKEND (meta_backend),
			CAL_BACKEND_PROPERTY_REVISION, revision);
		g_free (revision);
	}
}

static icaltimezone *
ecmb_cache_get_timezone_cb (ECalCache *cal_cache,
			    const gchar *tzid,
			    gpointer user_data)
{
	ECalMetaBackend *meta_backend = user_data;

	g_return_val_if_fail (E_IS_CAL_CACHE (cal_cache), NULL);
	g_return_val_if_fail (tzid != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), NULL);

	return e_timezone_cache_get_timezone (E_TIMEZONE_CACHE (meta_backend), tzid);
}

/**
 * e_cal_meta_backend_set_cache:
 * @meta_backend: an #ECalMetaBackend
 * @cache: an #ECalCache to use
 *
 * Sets the @cache as the cache to be used by the @meta_backend.
 * By default, a cache.db in ECalBackend::cache-dir is created
 * in the constructed method. This function can be used to override
 * the default.
 *
 * Note the @meta_backend adds its own reference to the @cache.
 *
 * Since: 3.26
 **/
void
e_cal_meta_backend_set_cache (ECalMetaBackend *meta_backend,
			      ECalCache *cache)
{
	g_return_if_fail (E_IS_CAL_META_BACKEND (meta_backend));
	g_return_if_fail (E_IS_CAL_CACHE (cache));

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->cache == cache) {
		g_mutex_unlock (&meta_backend->priv->property_lock);
		return;
	}

	g_clear_error (&meta_backend->priv->create_cache_error);

	if (meta_backend->priv->cache) {
		g_signal_handler_disconnect (meta_backend->priv->cache,
			meta_backend->priv->revision_changed_id);
		g_signal_handler_disconnect (meta_backend->priv->cache,
			meta_backend->priv->get_timezone_id);
	}

	g_clear_object (&meta_backend->priv->cache);
	meta_backend->priv->cache = g_object_ref (cache);

	meta_backend->priv->revision_changed_id = g_signal_connect_object (meta_backend->priv->cache,
		"revision-changed", G_CALLBACK (ecmb_cache_revision_changed_cb), meta_backend, 0);

	meta_backend->priv->get_timezone_id = g_signal_connect_object (meta_backend->priv->cache,
		"get-timezone", G_CALLBACK (ecmb_cache_get_timezone_cb), meta_backend, 0);

	g_mutex_unlock (&meta_backend->priv->property_lock);

	g_object_notify (G_OBJECT (meta_backend), "cache");
}

/**
 * e_cal_meta_backend_ref_cache:
 * @meta_backend: an #ECalMetaBackend
 *
 * Returns: (transfer full): Referenced #ECalCache, which is used by @meta_backend.
 *    Unref it with g_object_unref() when no longer needed.
 *
 * Since: 3.26
 **/
ECalCache *
e_cal_meta_backend_ref_cache (ECalMetaBackend *meta_backend)
{
	ECalCache *cache;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), NULL);

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->cache)
		cache = g_object_ref (meta_backend->priv->cache);
	else
		cache = NULL;

	g_mutex_unlock (&meta_backend->priv->property_lock);

	return cache;
}

static gint
sort_master_first_cb (gconstpointer a,
		      gconstpointer b)
{
	icalcomponent *ca, *cb;

	ca = e_cal_component_get_icalcomponent ((ECalComponent *) a);
	cb = e_cal_component_get_icalcomponent ((ECalComponent *) b);

	if (!ca) {
		if (!cb)
			return 0;
		else
			return -1;
	} else if (!cb) {
		return 1;
	}

	return icaltime_compare (icalcomponent_get_recurrenceid (ca), icalcomponent_get_recurrenceid (cb));
}

typedef struct {
	ETimezoneCache *timezone_cache;
	gboolean replace_tzid_with_location;
	icalcomponent *vcalendar;
	icalcomponent *icalcomp;
} ForeachTzidData;

static void
add_timezone_cb (icalparameter *param,
                 gpointer user_data)
{
	icaltimezone *tz;
	const gchar *tzid;
	icalcomponent *vtz_comp;
	ForeachTzidData *f_data = user_data;

	tzid = icalparameter_get_tzid (param);
	if (!tzid)
		return;

	tz = icalcomponent_get_timezone (f_data->vcalendar, tzid);
	if (tz)
		return;

	tz = icalcomponent_get_timezone (f_data->icalcomp, tzid);
	if (!tz)
		tz = icaltimezone_get_builtin_timezone_from_tzid (tzid);
	if (!tz && f_data->timezone_cache)
		tz = e_timezone_cache_get_timezone (f_data->timezone_cache, tzid);
	if (!tz)
		return;

	if (f_data->replace_tzid_with_location) {
		const gchar *location;

		location = icaltimezone_get_location (tz);
		if (location && *location) {
			icalparameter_set_tzid (param, location);
			tzid = location;

			if (icalcomponent_get_timezone (f_data->vcalendar, tzid))
				return;
		}
	}

	vtz_comp = icaltimezone_get_component (tz);

	if (vtz_comp) {
		icalcomponent *clone = icalcomponent_new_clone (vtz_comp);

		if (f_data->replace_tzid_with_location) {
			icalproperty *prop;

			prop = icalcomponent_get_first_property (clone, ICAL_TZID_PROPERTY);
			if (prop) {
				icalproperty_set_tzid (prop, tzid);
			}
		}

		icalcomponent_add_component (f_data->vcalendar, clone);
	}
}

/**
 * e_cal_meta_backend_merge_instances:
 * @meta_backend: an #ECalMetaBackend
 * @instances: (element-type ECalComponent): component instances to merge
 * @replace_tzid_with_location: whether to replace TZID-s with locations
 *
 * Merges all the instances provided in @instances list into one VCALENDAR
 * object, which would eventually contain also all the used timezones.
 * The @instances list should contain the master object and eventually all
 * the detached instances for one component (they all have the same UID).
 *
 * Any TZID property parameters can be replaced with corresponding timezone
 * location, which will not influence the timezone itself.
 *
 * Returns: (transfer full): an #icalcomponent containing a VCALENDAR
 *    component which consists of all the given instances. Free
 *    the returned pointer with icalcomponent_free() when no longer needed.
 *
 * See: e_cal_meta_backend_save_component_sync()
 *
 * Since: 3.26
 **/
icalcomponent *
e_cal_meta_backend_merge_instances (ECalMetaBackend *meta_backend,
				    const GSList *instances,
				    gboolean replace_tzid_with_location)
{
	ForeachTzidData f_data;
	icalcomponent *vcalendar;
	GSList *link, *sorted;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), NULL);
	g_return_val_if_fail (instances != NULL, NULL);

	sorted = g_slist_sort (g_slist_copy ((GSList *) instances), sort_master_first_cb);

	vcalendar = e_cal_util_new_top_level ();

	f_data.timezone_cache = E_TIMEZONE_CACHE (meta_backend);
	f_data.replace_tzid_with_location = replace_tzid_with_location;
	f_data.vcalendar = vcalendar;

	for (link = sorted; link; link = g_slist_next (link)) {
		ECalComponent *comp = link->data;
		icalcomponent *icalcomp;

		if (!E_IS_CAL_COMPONENT (comp)) {
			g_warn_if_reached ();
			continue;
		}

		icalcomp = icalcomponent_new_clone (e_cal_component_get_icalcomponent (comp));
		icalcomponent_add_component (vcalendar, icalcomp);

		f_data.icalcomp = icalcomp;

		icalcomponent_foreach_tzid (icalcomp, add_timezone_cb, &f_data);
	}

	g_slist_free (sorted);

	return vcalendar;
}

static void
ecmb_remove_all_but_filename_parameter (icalproperty *prop)
{
	icalparameter *param;

	g_return_if_fail (prop != NULL);

	while (param = icalproperty_get_first_parameter (prop, ICAL_ANY_PARAMETER), param) {
		if (icalparameter_isa (param) == ICAL_FILENAME_PARAMETER) {
			param = icalproperty_get_next_parameter (prop, ICAL_ANY_PARAMETER);
			if (!param)
				break;
		}

		icalproperty_remove_parameter_by_ref (prop, param);
	}
}

/**
 * e_cal_meta_backend_inline_local_attachments_sync:
 * @meta_backend: an #ECalMetaBackend
 * @component: an icalcomponent to work with
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Changes all URL attachments which point to a local file in @component
 * to inline attachments, aka adds the file content into the @component.
 * It also populates FILENAME parameter on the attachment.
 * This is called automatically before e_cal_meta_backend_save_component_sync().
 *
 * The reverse operation is e_cal_meta_backend_store_inline_attachments_sync().
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_meta_backend_inline_local_attachments_sync (ECalMetaBackend *meta_backend,
						  icalcomponent *component,
						  GCancellable *cancellable,
						  GError **error)
{
	icalproperty *prop;
	const gchar *uid;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (component != NULL, FALSE);

	uid = icalcomponent_get_uid (component);

	for (prop = icalcomponent_get_first_property (component, ICAL_ATTACH_PROPERTY);
	     prop && success;
	     prop = icalcomponent_get_next_property (component, ICAL_ATTACH_PROPERTY)) {
		icalattach *attach;

		attach = icalproperty_get_attach (prop);
		if (icalattach_get_is_url (attach)) {
			const gchar *url;

			url = icalattach_get_url (attach);
			if (g_str_has_prefix (url, LOCAL_PREFIX)) {
				GFile *file;
				gchar *basename;
				gchar *content;
				gsize len;

				file = g_file_new_for_uri (url);
				basename = g_file_get_basename (file);
				if (g_file_load_contents (file, cancellable, &content, &len, NULL, error)) {
					icalattach *new_attach;
					icalparameter *param;
					gchar *base64;

					base64 = g_base64_encode ((const guchar *) content, len);
					new_attach = icalattach_new_from_data (base64, NULL, NULL);
					g_free (content);
					g_free (base64);

					ecmb_remove_all_but_filename_parameter (prop);

					icalproperty_set_attach (prop, new_attach);
					icalattach_unref (new_attach);

					param = icalparameter_new_value (ICAL_VALUE_BINARY);
					icalproperty_add_parameter (prop, param);

					param = icalparameter_new_encoding (ICAL_ENCODING_BASE64);
					icalproperty_add_parameter (prop, param);

					/* Preserve existing FILENAME parameter */
					if (!icalproperty_get_first_parameter (prop, ICAL_FILENAME_PARAMETER)) {
						const gchar *use_filename = basename;

						/* generated filename by Evolution */
						if (uid && g_str_has_prefix (use_filename, uid) &&
						    use_filename[strlen (uid)] == '-') {
							use_filename += strlen (uid) + 1;
						}

						param = icalparameter_new_filename (use_filename);
						icalproperty_add_parameter (prop, param);
					}
				} else {
					success = FALSE;
				}

				g_object_unref (file);
				g_free (basename);
			}
		}
	}

	return success;
}

/**
 * e_cal_meta_backend_store_inline_attachments_sync:
 * @meta_backend: an #ECalMetaBackend
 * @component: an icalcomponent to work with
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Changes all inline attachments to URL attachments in @component, which
 * will point to a local file instead. The function expects FILENAME parameter
 * to be set on the attachment as the file name of it.
 * This is called automatically after e_cal_meta_backend_load_component_sync().
 *
 * The reverse operation is e_cal_meta_backend_inline_local_attachments_sync().
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_meta_backend_store_inline_attachments_sync (ECalMetaBackend *meta_backend,
						  icalcomponent *component,
						  GCancellable *cancellable,
						  GError **error)
{
	gint fileindex;
	icalproperty *prop;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (component != NULL, FALSE);

	for (prop = icalcomponent_get_first_property (component, ICAL_ATTACH_PROPERTY), fileindex = 0;
	     prop && success;
	     prop = icalcomponent_get_next_property (component, ICAL_ATTACH_PROPERTY), fileindex++) {
		icalattach *attach;

		attach = icalproperty_get_attach (prop);
		if (!icalattach_get_is_url (attach)) {
			icalparameter *param;
			const gchar *basename;
			gsize len = -1;
			gchar *decoded = NULL;
			gchar *local_filename;

			param = icalproperty_get_first_parameter (prop, ICAL_FILENAME_PARAMETER);
			basename = param ? icalparameter_get_filename (param) : NULL;
			if (!basename || !*basename)
				basename = _("attachment.dat");

			local_filename = e_cal_backend_create_cache_filename (E_CAL_BACKEND (meta_backend), icalcomponent_get_uid (component), basename, fileindex);

			if (local_filename) {
				const gchar *content;

				content = (const gchar *) icalattach_get_data (attach);
				decoded = (gchar *) g_base64_decode (content, &len);

				if (g_file_set_contents (local_filename, decoded, len, error)) {
					icalattach *new_attach;
					gchar *url;

					ecmb_remove_all_but_filename_parameter (prop);

					url = g_filename_to_uri (local_filename, NULL, NULL);
					new_attach = icalattach_new_from_url (url);

					icalproperty_set_attach (prop, new_attach);

					icalattach_unref (new_attach);
					g_free (url);
				} else {
					success = FALSE;
				}

				g_free (decoded);
			}

			g_free (local_filename);
		}
	}

	return success;
}

/**
 * e_cal_meta_backend_gather_timezones_sync:
 * @meta_backend: an #ECalMetaBackend
 * @vcalendar: a VCALENDAR icalcomponent
 * @remove_existing: whether to remove any existing first
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Extracts all VTIMEZONE components from the @vcalendar and adds them
 * to the memory cache, thus they are available when needed. The function does
 * nothing when the @vcalendar doesn't hold a VCALENDAR component.
 *
 * Set the @remove_existing argument to %TRUE to remove all cached timezones
 * first and then add the existing in the @vcalendar, or set it to %FALSE
 * to preserver existing timezones and merge them with those in @vcalendar.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_meta_backend_gather_timezones_sync (ECalMetaBackend *meta_backend,
					  icalcomponent *vcalendar,
					  gboolean remove_existing,
					  GCancellable *cancellable,
					  GError **error)
{
	ECalCache *cal_cache;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (vcalendar != NULL, FALSE);

	if (icalcomponent_isa (vcalendar) != ICAL_VCALENDAR_COMPONENT)
		return TRUE;

	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (cal_cache != NULL, FALSE);

	e_cache_lock (E_CACHE (cal_cache), E_CACHE_LOCK_WRITE);

	if (remove_existing)
		success = e_cal_cache_remove_timezones (cal_cache, cancellable, error);

	if (success)
		ecmb_gather_timezones (meta_backend, E_TIMEZONE_CACHE (meta_backend), vcalendar);

	e_cache_unlock (E_CACHE (cal_cache), success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	g_object_unref (cal_cache);

	return TRUE;
}

/**
 * e_cal_meta_backend_empty_cache_sync:
 * @meta_backend: an #ECalMetaBackend
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Empties the local cache by removing all known components from it
 * and notifies about such removal any opened views. It removes also
 * all known time zones.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_meta_backend_empty_cache_sync (ECalMetaBackend *meta_backend,
				     GCancellable *cancellable,
				     GError **error)
{
	ECalBackend *cal_backend;
	ECalCache *cal_cache;
	GSList *ids = NULL, *link;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (cal_cache != NULL, FALSE);

	e_cache_lock (E_CACHE (cal_cache), E_CACHE_LOCK_WRITE);

	cal_backend = E_CAL_BACKEND (meta_backend);

	success = e_cal_cache_search_ids (cal_cache, NULL, &ids, cancellable, error);
	if (success)
		success = e_cache_remove_all (E_CACHE (cal_cache), cancellable, error);

	e_cache_unlock (E_CACHE (cal_cache), success ? E_CACHE_UNLOCK_COMMIT : E_CACHE_UNLOCK_ROLLBACK);

	g_object_unref (cal_cache);

	if (success) {
		for (link = ids; link; link = g_slist_next (link)) {
			ECalComponentId *id = link->data;

			if (!id)
				continue;

			e_cal_backend_notify_component_removed (cal_backend, id, NULL, NULL);
		}
	}

	g_slist_free_full (ids, (GDestroyNotify) e_cal_component_free_id);

	return success;
}

/**
 * e_cal_meta_backend_schedule_refresh:
 * @meta_backend: an #ECalMetaBackend
 *
 * Schedules refresh of the content of the @meta_backend. If there's any
 * already scheduled, then the function does nothing.
 *
 * Use e_cal_meta_backend_refresh_sync() to refresh the @meta_backend
 * immediately.
 *
 * Since: 3.26
 **/
void
e_cal_meta_backend_schedule_refresh (ECalMetaBackend *meta_backend)
{
	GCancellable *cancellable;

	g_return_if_fail (E_IS_CAL_META_BACKEND (meta_backend));

	g_mutex_lock (&meta_backend->priv->property_lock);

	if (meta_backend->priv->refresh_cancellable) {
		/* Already refreshing the content */
		g_mutex_unlock (&meta_backend->priv->property_lock);
		return;
	}

	cancellable = g_cancellable_new ();
	meta_backend->priv->refresh_cancellable = g_object_ref (cancellable);

	g_mutex_unlock (&meta_backend->priv->property_lock);

	e_cal_backend_schedule_custom_operation (E_CAL_BACKEND (meta_backend), cancellable,
		ecmb_refresh_thread_func, NULL, NULL);

	g_object_unref (cancellable);
}

/**
 * e_cal_meta_backend_refresh_sync:
 * @meta_backend: an #ECalMetaBackend
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Refreshes the @meta_backend immediately. To just schedule refresh
 * operation call e_cal_meta_backend_schedule_refresh().
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_meta_backend_refresh_sync (ECalMetaBackend *meta_backend,
				 GCancellable *cancellable,
				 GError **error)
{
	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

	return ecmb_refresh_internal_sync (meta_backend, TRUE, cancellable, error);
}

/**
 * e_cal_meta_backend_ensure_connected_sync:
 * @meta_backend: an #ECalMetaBackend
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
e_cal_meta_backend_ensure_connected_sync (ECalMetaBackend *meta_backend,
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

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

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

	if (e_cal_meta_backend_connect_sync (meta_backend, credentials, &auth_result, &certificate_pem, &certificate_errors,
		cancellable, &local_error)) {
		ecmb_update_connection_values (meta_backend);
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
 * e_cal_meta_backend_split_changes_sync:
 * @meta_backend: an #ECalMetaBackend
 * @objects: (inout caller-allocates) (element-type ECalMetaBackendInfo):
 *    a #GSList of #ECalMetaBackendInfo object infos to split
 * @out_created_objects: (out) (element-type ECalMetaBackendInfo) (transfer full):
 *    a #GSList of #ECalMetaBackendInfo object infos which had been created
 * @out_modified_objects: (out) (element-type ECalMetaBackendInfo) (transfer full):
 *    a #GSList of #ECalMetaBackendInfo object infos which had been modified
 * @out_removed_objects: (out) (element-type ECalMetaBackendInfo) (transfer full) (nullable):
 *    a #GSList of #ECalMetaBackendInfo object infos which had been removed;
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
 * g_slist_free_full (objects, e_cal_meta_backend_info_free);
 * when no longer needed.
 *
 * The caller is still responsible to free @objects as well.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_meta_backend_split_changes_sync (ECalMetaBackend *meta_backend,
				       GSList *objects,
				       GSList **out_created_objects,
				       GSList **out_modified_objects,
				       GSList **out_removed_objects,
				       GCancellable *cancellable,
				       GError **error)
{
	GHashTable *locally_cached; /* ECalComponentId * ~> gchar *revision */
	GHashTableIter iter;
	GSList *link;
	ECalCache *cal_cache;
	gpointer key, value;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_created_objects, FALSE);
	g_return_val_if_fail (out_modified_objects, FALSE);

	*out_created_objects = NULL;
	*out_modified_objects = NULL;

	if (out_removed_objects)
		*out_removed_objects = NULL;

	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (cal_cache != NULL, FALSE);

	locally_cached = g_hash_table_new_full (
		(GHashFunc) e_cal_component_id_hash,
		(GEqualFunc) e_cal_component_id_equal,
		(GDestroyNotify) e_cal_component_free_id,
		g_free);

	if (!e_cal_cache_search_with_callback (cal_cache, NULL,
		ecmb_gather_locally_cached_objects_cb, locally_cached, cancellable, error)) {
		g_hash_table_destroy (locally_cached);
		g_object_unref (cal_cache);
		return FALSE;
	}

	for (link = objects; link; link = g_slist_next (link)) {
		ECalMetaBackendInfo *nfo = link->data;
		ECalComponentId id;

		if (!nfo)
			continue;

		id.uid = nfo->uid;
		id.rid = NULL;

		if (!g_hash_table_contains (locally_cached, &id)) {
			link->data = NULL;

			*out_created_objects = g_slist_prepend (*out_created_objects, nfo);
		} else {
			const gchar *local_revision = g_hash_table_lookup (locally_cached, &id);

			if (g_strcmp0 (local_revision, nfo->revision) != 0) {
				link->data = NULL;

				*out_modified_objects = g_slist_prepend (*out_modified_objects, nfo);
			}

			g_hash_table_remove (locally_cached, &id);
		}
	}

	if (out_removed_objects) {
		/* What left in the hash table is removed from the remote side */
		g_hash_table_iter_init (&iter, locally_cached);
		while (g_hash_table_iter_next (&iter, &key, &value)) {
			const ECalComponentId *id = key;
			const gchar *revision = value;
			ECalMetaBackendInfo *nfo;

			if (!id) {
				g_warn_if_reached ();
				continue;
			}

			/* Skit detached instances, if the master object is still in the cache */
			if (id->rid && *id->rid) {
				ECalComponentId master_id;

				master_id.uid = id->uid;
				master_id.rid = NULL;

				if (!g_hash_table_contains (locally_cached, &master_id))
					continue;
			}

			nfo = e_cal_meta_backend_info_new (id->uid, revision, NULL, NULL);
			*out_removed_objects = g_slist_prepend (*out_removed_objects, nfo);
		}

		*out_removed_objects = g_slist_reverse (*out_removed_objects);
	}

	g_hash_table_destroy (locally_cached);
	g_object_unref (cal_cache);

	*out_created_objects = g_slist_reverse (*out_created_objects);
	*out_modified_objects = g_slist_reverse (*out_modified_objects);

	return TRUE;
}

/**
 * e_cal_meta_backend_process_changes_sync:
 * @meta_backend: an #ECalMetaBackend
 * @created_objects: (element-type ECalMetaBackendInfo) (nullable):
 *    a #GSList of #ECalMetaBackendInfo object infos which had been created
 * @modified_objects: (element-type ECalMetaBackendInfo) (nullable):
 *    a #GSList of #ECalMetaBackendInfo object infos which had been modified
 * @removed_objects: (element-type ECalMetaBackendInfo) (nullable):
 *    a #GSList of #ECalMetaBackendInfo object infos which had been removed
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
e_cal_meta_backend_process_changes_sync (ECalMetaBackend *meta_backend,
					 const GSList *created_objects,
					 const GSList *modified_objects,
					 const GSList *removed_objects,
					 GCancellable *cancellable,
					 GError **error)
{
	ECalCache *cal_cache;
	GHashTable *covered_uids;
	GString *invalid_objects = NULL;
	GSList *link;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (cal_cache != NULL, FALSE);

	covered_uids = g_hash_table_new (g_str_hash, g_str_equal);

	/* Removed objects first */
	for (link = (GSList *) removed_objects; link && success; link = g_slist_next (link)) {
		ECalMetaBackendInfo *nfo = link->data;

		if (!nfo) {
			g_warn_if_reached ();
			continue;
		}

		success = ecmb_maybe_remove_from_cache (meta_backend, cal_cache, E_CACHE_IS_ONLINE, nfo->uid, cancellable, error);
	}

	/* Then modified objects */
	for (link = (GSList *) modified_objects; link && success; link = g_slist_next (link)) {
		ECalMetaBackendInfo *nfo = link->data;
		GError *local_error = NULL;

		if (!nfo || !nfo->uid) {
			g_warn_if_reached ();
			continue;
		}

		if (!*nfo->uid ||
		    g_hash_table_contains (covered_uids, nfo->uid))
			continue;

		g_hash_table_insert (covered_uids, nfo->uid, NULL);

		success = ecmb_load_component_wrapper_sync (meta_backend, cal_cache, nfo->uid, nfo->object, nfo->extra, NULL, cancellable, &local_error);

		/* Do not stop on invalid objects, just notify about them later, and load as many as possible */
		if (!success && g_error_matches (local_error, E_DATA_CAL_ERROR, InvalidObject)) {
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
		ECalMetaBackendInfo *nfo = link->data;
		GError *local_error = NULL;

		if (!nfo || !nfo->uid) {
			g_warn_if_reached ();
			continue;
		}

		if (!*nfo->uid)
			continue;

		success = ecmb_load_component_wrapper_sync (meta_backend, cal_cache, nfo->uid, nfo->object, nfo->extra, NULL, cancellable, &local_error);

		/* Do not stop on invalid objects, just notify about them later, and load as many as possible */
		if (!success && g_error_matches (local_error, E_DATA_CAL_ERROR, InvalidObject)) {
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
		e_cal_backend_notify_error (E_CAL_BACKEND (meta_backend), invalid_objects->str);

		g_string_free (invalid_objects, TRUE);
	}

	g_clear_object (&cal_cache);

	return success;
}

/**
 * e_cal_meta_backend_connect_sync:
 * @meta_backend: an #ECalMetaBackend
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
 * The descendant should also call e_cal_backend_set_writable() after successful
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
e_cal_meta_backend_connect_sync (ECalMetaBackend *meta_backend,
				 const ENamedParameters *credentials,
				 ESourceAuthenticationResult *out_auth_result,
				 gchar **out_certificate_pem,
				 GTlsCertificateFlags *out_certificate_errors,
				 GCancellable *cancellable,
				 GError **error)
{
	ECalMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

	klass = E_CAL_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->connect_sync != NULL, FALSE);

	return klass->connect_sync (meta_backend, credentials, out_auth_result, out_certificate_pem, out_certificate_errors, cancellable, error);
}

/**
 * e_cal_meta_backend_disconnect_sync:
 * @meta_backend: an #ECalMetaBackend
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
e_cal_meta_backend_disconnect_sync (ECalMetaBackend *meta_backend,
				    GCancellable *cancellable,
				    GError **error)
{
	ECalMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

	klass = E_CAL_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->disconnect_sync != NULL, FALSE);

	return klass->disconnect_sync (meta_backend, cancellable, error);
}

/**
 * e_cal_meta_backend_get_changes_sync:
 * @meta_backend: an #ECalMetaBackend
 * @last_sync_tag: (nullable): optional sync tag from the last check
 * @is_repeat: set to %TRUE when this is the repeated call
 * @out_new_sync_tag: (out) (transfer full): new sync tag to store on success
 * @out_repeat: (out): whether to repeat this call again; default is %FALSE
 * @out_created_objects: (out) (element-type ECalMetaBackendInfo) (transfer full):
 *    a #GSList of #ECalMetaBackendInfo object infos which had been created since
 *    the last check
 * @out_modified_objects: (out) (element-type ECalMetaBackendInfo) (transfer full):
 *    a #GSList of #ECalMetaBackendInfo object infos which had been modified since
 *    the last check
 * @out_removed_objects: (out) (element-type ECalMetaBackendInfo) (transfer full):
 *    a #GSList of #ECalMetaBackendInfo object infos which had been removed since
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
 * The descendant can populate also ECalMetaBackendInfo::object of
 * the @out_created_objects and @out_modified_objects, if known, in which
 * case this will be used instead of loading it with e_cal_meta_backend_load_component_sync().
 *
 * It is optional to implement this virtual method by the descendant.
 * The default implementation calls e_cal_meta_backend_list_existing_sync()
 * and then compares the list with the current content of the local cache
 * and populates the respective lists appropriately.
 *
 * Each output #GSList should be freed with
 * g_slist_free_full (objects, e_cal_meta_backend_info_free);
 * when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_meta_backend_get_changes_sync (ECalMetaBackend *meta_backend,
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
	ECalMetaBackendClass *klass;
	gint repeat_count = 0;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_new_sync_tag != NULL, FALSE);
	g_return_val_if_fail (out_repeat != NULL, FALSE);
	g_return_val_if_fail (out_created_objects != NULL, FALSE);
	g_return_val_if_fail (out_created_objects != NULL, FALSE);
	g_return_val_if_fail (out_modified_objects != NULL, FALSE);
	g_return_val_if_fail (out_removed_objects != NULL, FALSE);

	klass = E_CAL_META_BACKEND_GET_CLASS (meta_backend);
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

		if (!success && repeat_count <= MAX_REPEAT_COUNT && !ecmb_maybe_wait_for_credentials (meta_backend, wait_credentials_stamp, local_error, cancellable))
			break;
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

/**
 * e_cal_meta_backend_list_existing_sync:
 * @meta_backend: an #ECalMetaBackend
 * @out_new_sync_tag: (out) (transfer full): optional return location for a new sync tag
 * @out_existing_objects: (out) (element-type ECalMetaBackendInfo) (transfer full):
 *    a #GSList of #ECalMetaBackendInfo object infos which are stored on the remote side
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Used to get list of all existing objects on the remote side. The descendant
 * can optionally provide @out_new_sync_tag, which will be stored on success, if
 * not %NULL. The descendant can populate also ECalMetaBackendInfo::object of
 * the @out_existing_objects, if known, in which case this will be used instead
 * of loading it with e_cal_meta_backend_load_component_sync().
 *
 * It is mandatory to implement this virtual method by the descendant, unless
 * it implements its own #ECalMetaBackendClass.get_changes_sync().
 *
 * The @out_existing_objects #GSList should be freed with
 * g_slist_free_full (objects, e_cal_meta_backend_info_free);
 * when no longer needed.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_meta_backend_list_existing_sync (ECalMetaBackend *meta_backend,
				       gchar **out_new_sync_tag,
				       GSList **out_existing_objects,
				       GCancellable *cancellable,
				       GError **error)
{
	ECalMetaBackendClass *klass;
	gint repeat_count = 0;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_existing_objects != NULL, FALSE);

	klass = E_CAL_META_BACKEND_GET_CLASS (meta_backend);
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

		if (!success && repeat_count <= MAX_REPEAT_COUNT && !ecmb_maybe_wait_for_credentials (meta_backend, wait_credentials_stamp, local_error, cancellable))
			break;
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

/**
 * e_cal_meta_backend_load_component_sync:
 * @meta_backend: an #ECalMetaBackend
 * @uid: a component UID
 * @extra: (nullable): optional extra data stored with the component, or %NULL
 * @out_component: (out) (transfer full): a loaded component, as icalcomponent
 * @out_extra: (out) (transfer full): an extra data to store to #ECalCache with this component
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Loads a component from the remote side. Any detached instances should be
 * returned together with the master object. The @out_component can be either
 * a VCALENDAR component, which would contain the master object and all of
 * its detached instances, eventually also used time zones, or the requested
 * component of type VEVENT, VJOURNAL or VTODO.
 *
 * It is mandatory to implement this virtual method by the descendant.
 *
 * The returned @out_component should be freed with icalcomponent_free(),
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
e_cal_meta_backend_load_component_sync (ECalMetaBackend *meta_backend,
					const gchar *uid,
					const gchar *extra,
					icalcomponent **out_component,
					gchar **out_extra,
					GCancellable *cancellable,
					GError **error)
{
	ECalMetaBackendClass *klass;
	gint repeat_count = 0;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_component != NULL, FALSE);
	g_return_val_if_fail (out_extra != NULL, FALSE);

	klass = E_CAL_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->load_component_sync != NULL, FALSE);


	while (!success && repeat_count <= MAX_REPEAT_COUNT) {
		guint wait_credentials_stamp;

		g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
		wait_credentials_stamp = meta_backend->priv->wait_credentials_stamp;
		g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);

		g_clear_error (&local_error);
		repeat_count++;

		success = klass->load_component_sync (meta_backend, uid, extra, out_component, out_extra, cancellable, &local_error);

		if (!success && repeat_count <= MAX_REPEAT_COUNT && !ecmb_maybe_wait_for_credentials (meta_backend, wait_credentials_stamp, local_error, cancellable))
			break;
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

/**
 * e_cal_meta_backend_save_component_sync:
 * @meta_backend: an #ECalMetaBackend
 * @overwrite_existing: %TRUE when can overwrite existing components, %FALSE otherwise
 * @conflict_resolution: one of #EConflictResolution, what to do on conflicts
 * @instances: (element-type ECalComponent): instances of the component to save
 * @extra: (nullable): extra data saved with the components in an #ECalCache
 * @out_new_uid: (out) (transfer full): return location for the UID of the saved component
 * @out_new_extra: (out) (transfer full): return location for the extra data to store with the component
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Saves one component into the remote side. The @instances contain the master
 * object and all the detached instances of the same component (all have the same UID).
 * When the @overwrite_existing is %TRUE, then the descendant can overwrite an object
 * with the same UID on the remote side (usually used for modify). The @conflict_resolution
 * defines what to do when the remote side had made any changes to the object since
 * the last update.
 *
 * The descendant can use e_cal_meta_backend_merge_instances() to merge
 * the instances into one VCALENDAR component, which will contain also
 * used time zones.
 *
 * The components in @instances have already converted locally stored attachments
 * into inline attachments, thus it's not needed to call
 * e_cal_meta_backend_inline_local_attachments_sync() by the descendant.
 *
 * The @out_new_uid can be populated with a UID of the saved component as the server
 * assigned it to it. This UID, if set, is loaded from the remote side afterwards,
 * also to see whether any changes had been made to the component by the remote side.
 *
 * The @out_new_extra can be populated with a new extra data to save with the component.
 * Left it %NULL, to keep the same value as the @extra.
 *
 * The descendant can use an #E_CLIENT_ERROR_OUT_OF_SYNC error to indicate that
 * the save failed due to made changes on the remote side, and let the @meta_backend
 * to resolve this conflict based on the @conflict_resolution on its own.
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
e_cal_meta_backend_save_component_sync (ECalMetaBackend *meta_backend,
					gboolean overwrite_existing,
					EConflictResolution conflict_resolution,
					const GSList *instances,
					const gchar *extra,
					gchar **out_new_uid,
					gchar **out_new_extra,
					GCancellable *cancellable,
					GError **error)
{
	ECalMetaBackendClass *klass;
	gint repeat_count = 0;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (instances != NULL, FALSE);
	g_return_val_if_fail (out_new_uid != NULL, FALSE);
	g_return_val_if_fail (out_new_extra != NULL, FALSE);

	klass = E_CAL_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);

	if (!klass->save_component_sync) {
		g_propagate_error (error, e_data_cal_create_error (NotSupported, NULL));
		return FALSE;
	}


	while (!success && repeat_count <= MAX_REPEAT_COUNT) {
		guint wait_credentials_stamp;

		g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
		wait_credentials_stamp = meta_backend->priv->wait_credentials_stamp;
		g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);

		g_clear_error (&local_error);
		repeat_count++;

		success = klass->save_component_sync (meta_backend,
			overwrite_existing,
			conflict_resolution,
			instances,
			extra,
			out_new_uid,
			out_new_extra,
			cancellable,
			&local_error);

		if (!success && repeat_count <= MAX_REPEAT_COUNT && !ecmb_maybe_wait_for_credentials (meta_backend, wait_credentials_stamp, local_error, cancellable))
			break;
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

/**
 * e_cal_meta_backend_remove_component_sync:
 * @meta_backend: an #ECalMetaBackend
 * @conflict_resolution: an #EConflictResolution to use
 * @uid: a component UID
 * @extra: (nullable): extra data being saved with the component in the local cache, or %NULL
 * @object: (nullable): corresponding iCalendar object, as stored in the local cache, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Removes a component from the remote side, with all its detached instances.
 * The @object is not %NULL when it's removing locally deleted object
 * in offline mode. Being it %NULL, the descendant can obtain the object
 * from the #ECalCache.
 *
 * It is mandatory to implement this virtual method by the writable descendant.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
e_cal_meta_backend_remove_component_sync (ECalMetaBackend *meta_backend,
					  EConflictResolution conflict_resolution,
					  const gchar *uid,
					  const gchar *extra,
					  const gchar *object,
					  GCancellable *cancellable,
					  GError **error)
{
	ECalMetaBackendClass *klass;
	gint repeat_count = 0;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	klass = E_CAL_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);

	if (!klass->remove_component_sync) {
		g_propagate_error (error, e_data_cal_create_error (NotSupported, NULL));
		return FALSE;
	}

	while (!success && repeat_count <= MAX_REPEAT_COUNT) {
		guint wait_credentials_stamp;

		g_mutex_lock (&meta_backend->priv->wait_credentials_lock);
		wait_credentials_stamp = meta_backend->priv->wait_credentials_stamp;
		g_mutex_unlock (&meta_backend->priv->wait_credentials_lock);

		g_clear_error (&local_error);
		repeat_count++;

		success = klass->remove_component_sync (meta_backend, conflict_resolution, uid, extra, object, cancellable, &local_error);

		if (!success && repeat_count <= MAX_REPEAT_COUNT && !ecmb_maybe_wait_for_credentials (meta_backend, wait_credentials_stamp, local_error, cancellable))
			break;
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return success;
}

/**
 * e_cal_meta_backend_search_sync:
 * @meta_backend: an #ECalMetaBackend
 * @expr: (nullable): a search expression, or %NULL
 * @out_icalstrings: (out) (transfer full) (element-type utf8): return location for the found components as iCal strings
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Searches @meta_backend with given expression @expr and returns
 * found components as a #GSList of iCal strings @out_icalstrings.
 * Free the returned @out_icalstrings with g_slist_free_full (icalstrings, g_free);
 * when no longer needed.
 * When the @expr is %NULL, all objects are returned. To get
 * #ECalComponent-s instead, call e_cal_meta_backend_search_components_sync().
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
e_cal_meta_backend_search_sync (ECalMetaBackend *meta_backend,
				const gchar *expr,
				GSList **out_icalstrings,
				GCancellable *cancellable,
				GError **error)
{
	ECalMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_icalstrings != NULL, FALSE);

	klass = E_CAL_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->search_sync != NULL, FALSE);

	return klass->search_sync (meta_backend, expr, out_icalstrings, cancellable, error);
}

/**
 * e_cal_meta_backend_search_components_sync:
 * @meta_backend: an #ECalMetaBackend
 * @expr: (nullable): a search expression, or %NULL
 * @out_components: (out) (transfer full) (element-type ECalComponent): return location for the found #ECalComponent-s
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Searches @meta_backend with given expression @expr and returns
 * found components as a #GSList of #ECalComponent @out_components.
 * Free the returned @out_components with g_slist_free_full (components, g_object_unref);
 * when no longer needed.
 * When the @expr is %NULL, all objects are returned. To get iCal
 * strings instead, call e_cal_meta_backend_search_sync().
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
e_cal_meta_backend_search_components_sync (ECalMetaBackend *meta_backend,
					   const gchar *expr,
					   GSList **out_components,
					   GCancellable *cancellable,
					   GError **error)
{
	ECalMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);
	g_return_val_if_fail (out_components != NULL, FALSE);

	klass = E_CAL_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->search_components_sync != NULL, FALSE);

	return klass->search_components_sync (meta_backend, expr, out_components, cancellable, error);
}

/**
 * e_cal_meta_backend_requires_reconnect:
 * @meta_backend: an #ECalMetaBackend
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
e_cal_meta_backend_requires_reconnect (ECalMetaBackend *meta_backend)
{
	ECalMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

	klass = E_CAL_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->requires_reconnect != NULL, FALSE);

	return klass->requires_reconnect (meta_backend);
}

/**
 * e_cal_meta_backend_get_ssl_error_details:
 * @meta_backend: an #ECalMetaBackend
 * @out_certificate_pem: (out): SSL certificate encoded in PEM format
 * @out_certificate_errors: (out): bit-or of #GTlsCertificateFlags claiming the certificate errors
 *
 * It is optional to implement this virtual method by the descendants.
 * It is used to receive SSL error details when any online operation
 * returns E_DATA_CAL_ERROR, TLSNotAvailable error.
 *
 * Returns: %TRUE, when the SSL error details had been available and
 *    the out parameters populated, %FALSE otherwise.
 *
 * Since: 3.28
 **/
gboolean
e_cal_meta_backend_get_ssl_error_details (ECalMetaBackend *meta_backend,
					  gchar **out_certificate_pem,
					  GTlsCertificateFlags *out_certificate_errors)
{
	ECalMetaBackendClass *klass;

	g_return_val_if_fail (E_IS_CAL_META_BACKEND (meta_backend), FALSE);

	klass = E_CAL_META_BACKEND_GET_CLASS (meta_backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->get_ssl_error_details != NULL, FALSE);

	return klass->get_ssl_error_details (meta_backend, out_certificate_pem, out_certificate_errors);
}
