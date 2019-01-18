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
 * Authors: Jeffrey Stedfast <fejj@novell.com>
 */

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include "camel-debug.h"
#include "camel-folder.h"
#include "camel-network-service.h"
#include "camel-offline-folder.h"
#include "camel-offline-settings.h"
#include "camel-offline-store.h"
#include "camel-session.h"

#define CAMEL_OFFLINE_STORE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_OFFLINE_STORE, CamelOfflineStorePrivate))

struct _CamelOfflineStorePrivate {
	/* XXX The online flag stores whether the user has selected online or
	 *     offline mode, but fetching the flag through the "get" function
	 *     also takes into account CamelNetworkService's "host-reachable"
	 *     property.  So it's possible to set the "online" state to TRUE,
	 *     but then immediately read back FALSE.  Kinda weird, but mainly
	 *     for temporary backward-compability. */
	gboolean online;
};

enum {
	PROP_0,
	PROP_ONLINE
};

G_DEFINE_TYPE (CamelOfflineStore, camel_offline_store, CAMEL_TYPE_STORE)

static void
offline_store_downsync_folders_sync (CamelStore *store,
				     GCancellable *cancellable,
				     GError **error)
{
	GPtrArray *folders;
	guint ii;

	g_return_if_fail (CAMEL_IS_OFFLINE_STORE (store));

	folders = camel_offline_store_dup_downsync_folders (CAMEL_OFFLINE_STORE (store));

	if (camel_debug ("downsync"))
		printf ("[downsync] %p (%s): got %d folders to downsync\n", store, camel_service_get_display_name (CAMEL_SERVICE (store)), folders ? folders->len : -1);

	if (!folders)
		return;

	for (ii = 0; ii < folders->len && !g_cancellable_is_cancelled (cancellable); ii++) {
		CamelFolder *folder = folders->pdata[ii];
		CamelOfflineFolder *offline_folder;
		GError *local_error = NULL;

		if (!CAMEL_IS_OFFLINE_FOLDER (folder)) {
			if (camel_debug ("downsync"))
				printf ("[downsync]    %p: [%d] not an offline folder\n", store, ii);
			continue;
		}

		offline_folder = CAMEL_OFFLINE_FOLDER (folder);

		if (!camel_offline_folder_can_downsync (offline_folder)) {
			if (camel_debug ("downsync"))
				printf ("[downsync]    %p: [%d] skipping folder '%s', not for downsync\n", store, ii, camel_folder_get_full_name (folder));
			continue;
		}

		if (!camel_offline_folder_downsync_sync (offline_folder, NULL, cancellable, &local_error)) {
			if (camel_debug ("downsync"))
				printf ("[downsync]    %p: [%d] failed to downsync folder '%s'; cancelled:%d error: %s\n", store, ii, camel_folder_get_full_name (folder), g_cancellable_is_cancelled (cancellable), local_error ? local_error->message : "Unknown error");
			if (local_error)
				g_propagate_error (error, local_error);
			break;
		}

		if (camel_debug ("downsync"))
			printf ("[downsync]    %p: [%d] finished downsync of folder '%s'\n", store, ii, camel_folder_get_full_name (folder));
	}

	g_ptr_array_foreach (folders, (GFunc) g_object_unref, NULL);
	g_ptr_array_free (folders, TRUE);
}

static void
offline_store_downsync_folders_thread (CamelSession *session,
				       GCancellable *cancellable,
				       gpointer user_data,
				       GError **error)
{
	CamelStore *store = user_data;

	offline_store_downsync_folders_sync (store, cancellable, error);
}

static void
offline_store_constructed (GObject *object)
{
	CamelOfflineStorePrivate *priv;
	CamelSession *session;

	priv = CAMEL_OFFLINE_STORE_GET_PRIVATE (object);

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (camel_offline_store_parent_class)->constructed (object);

	session = camel_service_ref_session (CAMEL_SERVICE (object));
	priv->online = session && camel_session_get_online (session);
	g_clear_object (&session);
}

static void
offline_store_get_property (GObject *object,
                            guint property_id,
                            GValue *value,
                            GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ONLINE:
			g_value_set_boolean (
				value, camel_offline_store_get_online (
				CAMEL_OFFLINE_STORE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
offline_store_notify (GObject *object,
                      GParamSpec *pspec)
{
	if (g_strcmp0 (pspec->name, "host-reachable") == 0)
		g_object_notify (object, "online");

	/* Chain up to parent's notify() method. */
	G_OBJECT_CLASS (camel_offline_store_parent_class)->
		notify (object, pspec);
}

static void
camel_offline_store_class_init (CamelOfflineStoreClass *class)
{
	GObjectClass *object_class;
	CamelServiceClass *service_class;

	g_type_class_add_private (class, sizeof (CamelOfflineStorePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->constructed = offline_store_constructed;
	object_class->get_property = offline_store_get_property;
	object_class->notify = offline_store_notify;

	service_class = CAMEL_SERVICE_CLASS (class);
	service_class->settings_type = CAMEL_TYPE_OFFLINE_SETTINGS;

	g_object_class_install_property (
		object_class,
		PROP_ONLINE,
		g_param_spec_boolean (
			"online",
			"Online",
			"Whether the store is online",
			FALSE,
			G_PARAM_READABLE));
}

static void
camel_offline_store_init (CamelOfflineStore *store)
{
	store->priv = CAMEL_OFFLINE_STORE_GET_PRIVATE (store);
}

/**
 * camel_offline_store_get_online:
 * @store: a #CamelOfflineStore
 *
 * Returns %TRUE if @store is online.
 *
 * Since: 2.24
 **/
gboolean
camel_offline_store_get_online (CamelOfflineStore *store)
{
	g_return_val_if_fail (CAMEL_IS_OFFLINE_STORE (store), 0);

	if (CAMEL_IS_NETWORK_SERVICE (store)) {
		CamelNetworkService *service;

		service = CAMEL_NETWORK_SERVICE (store);

		/* Always return FALSE if the remote host is not reachable. */
		if (!camel_network_service_get_host_reachable (service))
			return FALSE;
	}

	return store->priv->online;
}

/**
 * camel_offline_store_set_online_sync:
 * @store: a #CamelOfflineStore
 * @online: %TRUE for online, %FALSE for offline
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Sets the online/offline state of @store according to @online.
 *
 * Returns: Whether succeeded.
 *
 * See: camel_offline_store_set_online
 **/
gboolean
camel_offline_store_set_online_sync (CamelOfflineStore *store,
                                     gboolean online,
                                     GCancellable *cancellable,
                                     GError **error)
{
	CamelService *service;
	gboolean host_reachable = TRUE;
	gboolean store_is_online;
	gboolean success = TRUE;

	g_return_val_if_fail (CAMEL_IS_OFFLINE_STORE (store), FALSE);

	if (camel_offline_store_get_online (store) == online)
		return TRUE;

	service = CAMEL_SERVICE (store);

	if (CAMEL_IS_NETWORK_SERVICE (store)) {
		/* When going to set the 'online' state, then check with up-to-date
		   value, otherwise use the cached value. The cached value is
		   updated with few seconds timeout, thus it can be stale here. */
		if (online)
			host_reachable =
				camel_network_service_can_reach_sync (
				CAMEL_NETWORK_SERVICE (store),
				cancellable, NULL);
		else
			host_reachable =
				camel_network_service_get_host_reachable (
				CAMEL_NETWORK_SERVICE (store));
	}

	store_is_online = camel_offline_store_get_online (store);

	/* Returning to online mode is the simpler case. */
	if (!store_is_online) {
		store->priv->online = online;

		g_object_notify (G_OBJECT (store), "online");

		if (camel_service_get_connection_status (service) == CAMEL_SERVICE_CONNECTING)
			return TRUE;

		return camel_service_connect_sync (service, cancellable, error);
	}

	if (host_reachable) {
		CamelSession *session;

		session = camel_service_ref_session (service);
		host_reachable = session && camel_session_get_online (session);
		g_clear_object (&session);
	}

	if (host_reachable) {
		GPtrArray *folders;
		CamelSession *session;

		session = camel_service_ref_session (service);
		folders = session ? camel_offline_store_dup_downsync_folders (store) : NULL;

		/* Schedule job only if the store is going online, otherwise, when going offline,
		   the download could be cancelled due to the switch to the disconnect, thus
		   synchronize immediately. */
		if (folders && session && online) {
			gchar *description;

			description = g_strdup_printf (_("Syncing messages in account “%s” to disk"),
				camel_service_get_display_name (service));

			camel_session_submit_job (session, description,
				offline_store_downsync_folders_thread,
				g_object_ref (store), g_object_unref);

			g_free (description);
		} else if (folders && session) {
			GError *local_error = NULL;

			/* Ignore errors, because the move to offline won't fail here */
			offline_store_downsync_folders_sync (CAMEL_STORE (store), cancellable, &local_error);

			if (local_error && camel_debug ("downsync"))
				printf ("[downsync]    %p (%s): Finished with error when going offline: %s\n", store, camel_service_get_display_name (CAMEL_SERVICE (store)), local_error->message);

			g_clear_error (&local_error);
		}

		g_clear_object (&session);

		if (folders) {
			g_ptr_array_foreach (folders, (GFunc) g_object_unref, NULL);
			g_ptr_array_free (folders, TRUE);
		}

		camel_store_synchronize_sync (
			CAMEL_STORE (store), FALSE, cancellable, NULL);
	}

	/* Call camel_service_get_connection_status(), to have up-to-date information,
	   rather than "cached" from the top of the function, which can be obsolete. */
	if (!online &&
	    camel_service_get_connection_status (service) != CAMEL_SERVICE_DISCONNECTING &&
	    camel_service_get_connection_status (service) != CAMEL_SERVICE_DISCONNECTED) {
		success = camel_service_disconnect_sync (
			service, host_reachable, cancellable, error);
	}

	store->priv->online = online;

	g_object_notify (G_OBJECT (store), "online");

	return success;
}

static void
offline_store_set_online_thread (GTask *task,
				 gpointer source_object,
				 gpointer task_data,
				 GCancellable *cancellable)
{
	gboolean success, online;
	GError *local_error = NULL;

	online = GPOINTER_TO_INT (task_data) != 0;

	success = camel_offline_store_set_online_sync (CAMEL_OFFLINE_STORE (source_object), online, cancellable, &local_error);

	if (local_error) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_offline_store_set_online:
 * @store: a #CamelOfflineStore
 * @online: %TRUE for online, %FALSE for offline
 * @io_priority: the I/O priority for the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * An asynchronous variant of camel_offline_store_set_online_sync().
 * Call camel_offline_store_set_online_finish() from within the @callback.
 *
 * Since: 3.26
 **/
void
camel_offline_store_set_online (CamelOfflineStore *store,
				gboolean online,
				gint io_priority,
				GCancellable *cancellable,
				GAsyncReadyCallback callback,
				gpointer user_data)
{
	GTask *task;

	g_return_if_fail (CAMEL_IS_OFFLINE_STORE (store));

	task = g_task_new (store, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_offline_store_set_online);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (task, GINT_TO_POINTER (online ? 1 : 0), NULL);

	g_task_run_in_thread (task, offline_store_set_online_thread);

	g_object_unref (task);
}

/**
 * camel_offline_store_set_online_finish:
 * @store: a #CamelOfflineStore
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_offline_store_set_online().
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.26
 **/
gboolean
camel_offline_store_set_online_finish (CamelOfflineStore *store,
				       GAsyncResult *result,
				       GError **error)
{
	g_return_val_if_fail (CAMEL_IS_OFFLINE_STORE (store), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, store), FALSE);
	g_return_val_if_fail (g_async_result_is_tagged (result, camel_offline_store_set_online), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_offline_store_prepare_for_offline_sync:
 * @store: a #CamelOfflineStore
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Downloads messages for offline, when setup to do so and when
 * the host is reachable.
 *
 * Returns: whether succeeded
 *
 * Since: 2.22
 **/
gboolean
camel_offline_store_prepare_for_offline_sync (CamelOfflineStore *store,
                                              GCancellable *cancellable,
                                              GError **error)
{
	gboolean host_reachable = TRUE;
	gboolean store_is_online;

	g_return_val_if_fail (CAMEL_IS_OFFLINE_STORE (store), FALSE);

	store_is_online = camel_offline_store_get_online (store);

	if (store_is_online && CAMEL_IS_NETWORK_SERVICE (store)) {
		/* Check with up-to-date value. The cached value is updated with
		   few seconds timeout, thus it can be stale here. */
		host_reachable =
			camel_network_service_can_reach_sync (
			CAMEL_NETWORK_SERVICE (store),
			cancellable, NULL);
	}

	if (host_reachable && store_is_online) {
		GPtrArray *folders;
		guint ii;

		folders = camel_offline_store_dup_downsync_folders (store);

		for (ii = 0; folders && ii < folders->len; ii++) {
			CamelFolder *folder = folders->pdata[ii];
			CamelOfflineFolder *offline_folder;

			if (!CAMEL_IS_OFFLINE_FOLDER (folder))
				continue;

			offline_folder = CAMEL_OFFLINE_FOLDER (folder);

			if (camel_offline_folder_can_downsync (offline_folder))
				camel_offline_folder_downsync_sync (offline_folder, NULL, cancellable, NULL);
		}

		if (folders) {
			g_ptr_array_foreach (folders, (GFunc) g_object_unref, NULL);
			g_ptr_array_free (folders, TRUE);
		}
	}

	if (host_reachable)
		camel_store_synchronize_sync (
			CAMEL_STORE (store), FALSE, cancellable, NULL);

	return TRUE;
}

/**
 * camel_offline_store_requires_downsync:
 * @store: a #CamelOfflineStore
 *
 * Check whether the @store requires synchronization for offline usage.
 * This is not blocking, it only checks settings on the store and its
 * currently opened folders.
 *
 * Returns %TRUE if the @store requires synchronization for offline usage
 *
 * Since: 3.12
 **/
gboolean
camel_offline_store_requires_downsync (CamelOfflineStore *store)
{
	gboolean host_reachable = TRUE;
	gboolean store_is_online;
	gboolean sync_any_folder = FALSE;

	g_return_val_if_fail (CAMEL_IS_OFFLINE_STORE (store), FALSE);

	if (CAMEL_IS_NETWORK_SERVICE (store)) {
		host_reachable =
			camel_network_service_get_host_reachable (
			CAMEL_NETWORK_SERVICE (store));
	}

	store_is_online = camel_offline_store_get_online (store);

	if (!store_is_online)
		return FALSE;

	if (host_reachable) {
		CamelSession *session;

		session = camel_service_ref_session (CAMEL_SERVICE (store));
		host_reachable = session && camel_session_get_online (session);
		g_clear_object (&session);
	}

	if (host_reachable) {
		GPtrArray *folders;
		guint ii;

		folders = camel_offline_store_dup_downsync_folders (store);

		for (ii = 0; folders && ii < folders->len && !sync_any_folder; ii++) {
			CamelFolder *folder = folders->pdata[ii];

			if (!CAMEL_IS_OFFLINE_FOLDER (folder))
				continue;

			sync_any_folder = camel_offline_folder_can_downsync (CAMEL_OFFLINE_FOLDER (folder));
		}

		if (folders) {
			g_ptr_array_foreach (folders, (GFunc) g_object_unref, NULL);
			g_ptr_array_free (folders, TRUE);
		}
	}

	return sync_any_folder && host_reachable;
}

/**
 * camel_offline_store_dup_downsync_folders:
 * @store: a #CamelOfflineStore
 *
 * Returns a #GPtrArray of #CamelFolder objects which should be checked
 * for offline synchronization. Free the returned pointer with the below
 * calls, when no longer needed:
 *
 * |[
 *     g_ptr_array_foreach (array, (GFunc) g_object_unref, NULL);
 *     g_ptr_array_free (array, TRUE);
 * ]|
 *
 * Returns: (element-type CamelFolder) (transfer full): an array with folders
 *   to be checked for offline synchronization.
 *
 * Since: 3.28
 **/
GPtrArray *
camel_offline_store_dup_downsync_folders (CamelOfflineStore *store)
{
	CamelOfflineStoreClass *klass;

	g_return_val_if_fail (CAMEL_IS_OFFLINE_STORE (store), NULL);

	klass = CAMEL_OFFLINE_STORE_GET_CLASS (store);
	g_return_val_if_fail (klass != NULL, NULL);

	if (klass->dup_downsync_folders)
		return klass->dup_downsync_folders (store);

	return camel_store_dup_opened_folders (CAMEL_STORE (store));
}
