/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-store.c : Abstract class for an email store
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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 *          Dan Winship <danw@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <glib/gi18n-lib.h>

#include "camel-async-closure.h"
#include "camel-db.h"
#include "camel-debug.h"
#include "camel-folder.h"
#include "camel-network-service.h"
#include "camel-offline-store.h"
#include "camel-session.h"
#include "camel-store.h"
#include "camel-store-settings.h"
#include "camel-subscribable.h"
#include "camel-vtrash-folder.h"

#define d(x)
#define w(x)

#define CAMEL_STORE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_STORE, CamelStorePrivate))

typedef struct _AsyncContext AsyncContext;
typedef struct _SignalClosure SignalClosure;

struct _CamelStorePrivate {
	CamelDB *cdb;
	CamelObjectBag *folders;
	guint32 flags; /* bit-or of CamelStoreFlags */
	guint32 permissions; /* bit-or of CamelStorePermissionFlags */

	GMutex signal_emission_lock;
	gboolean folder_info_stale_scheduled;
	volatile gint maintenance_lock;
};

struct _AsyncContext {
	gchar *folder_name_1;
	gchar *folder_name_2;
	gboolean expunge;
	guint32 flags;
	GHashTable *save_setup;
};

struct _SignalClosure {
	GWeakRef store;
	CamelFolder *folder;
	CamelFolderInfo *folder_info;
	gchar *folder_name;
};

enum {
	FOLDER_CREATED,
	FOLDER_DELETED,
	FOLDER_INFO_STALE,
	FOLDER_OPENED,
	FOLDER_RENAMED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];
static GInitableIface *parent_initable_interface;

/* Forward Declarations */
static void camel_store_initable_init (GInitableIface *iface);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE (
	CamelStore, camel_store, CAMEL_TYPE_SERVICE,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE, camel_store_initable_init))

G_DEFINE_BOXED_TYPE (CamelFolderInfo,
		camel_folder_info,
		camel_folder_info_clone,
		camel_folder_info_free)

static void
async_context_free (AsyncContext *async_context)
{
	if (async_context->save_setup) {
		g_hash_table_destroy (async_context->save_setup);
		async_context->save_setup = NULL;
	}

	g_free (async_context->folder_name_1);
	g_free (async_context->folder_name_2);

	g_slice_free (AsyncContext, async_context);
}

static void
signal_closure_free (SignalClosure *signal_closure)
{
	g_weak_ref_clear (&signal_closure->store);

	if (signal_closure->folder != NULL)
		g_object_unref (signal_closure->folder);

	if (signal_closure->folder_info != NULL)
		camel_folder_info_free (signal_closure->folder_info);

	g_free (signal_closure->folder_name);

	g_slice_free (SignalClosure, signal_closure);
}

static gboolean
store_emit_folder_created_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	CamelStore *store;

	store = g_weak_ref_get (&signal_closure->store);

	if (store != NULL) {
		g_signal_emit (
			store,
			signals[FOLDER_CREATED], 0,
			signal_closure->folder_info);
		g_object_unref (store);
	}

	return FALSE;
}

static gboolean
store_emit_folder_deleted_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	CamelStore *store;

	store = g_weak_ref_get (&signal_closure->store);

	if (store != NULL) {
		g_signal_emit (
			store,
			signals[FOLDER_DELETED], 0,
			signal_closure->folder_info);
		g_object_unref (store);
	}

	return FALSE;
}

static gboolean
store_emit_folder_opened_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	CamelStore *store;

	store = g_weak_ref_get (&signal_closure->store);

	if (store != NULL) {
		g_signal_emit (
			store,
			signals[FOLDER_OPENED], 0,
			signal_closure->folder);
		g_object_unref (store);
	}

	return FALSE;
}

static gboolean
store_emit_folder_renamed_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	CamelStore *store;

	store = g_weak_ref_get (&signal_closure->store);

	if (store != NULL) {
		g_signal_emit (
			store,
			signals[FOLDER_RENAMED], 0,
			signal_closure->folder_name,
			signal_closure->folder_info);
		g_object_unref (store);
	}

	return FALSE;
}

static gboolean
store_emit_folder_info_stale_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	CamelStore *store;

	store = g_weak_ref_get (&signal_closure->store);

	if (store != NULL) {
		g_mutex_lock (&store->priv->signal_emission_lock);
		store->priv->folder_info_stale_scheduled = FALSE;
		g_mutex_unlock (&store->priv->signal_emission_lock);

		g_signal_emit (store, signals[FOLDER_INFO_STALE], 0);

		g_object_unref (store);
	}

	return FALSE;
}

/*
 * ignore_no_such_table_exception:
 * Clears the error 'error' when it's the 'no such table' error.
 */
static void
ignore_no_such_table_exception (GError **error)
{
	if (error == NULL || *error == NULL)
		return;

	if (g_ascii_strncasecmp ((*error)->message, "no such table", 13) == 0)
		g_clear_error (error);
}

static CamelFolder *
store_get_special (CamelStore *store,
                   CamelVTrashFolderType type)
{
	CamelFolder *folder;
	GPtrArray *folders;
	gint i;

	folder = camel_vtrash_folder_new (store, type);

	if (store->priv->folders) {
		folders = camel_object_bag_list (store->priv->folders);
		for (i = 0; i < folders->len; i++) {
			if (!CAMEL_IS_VTRASH_FOLDER (folders->pdata[i]))
				camel_vee_folder_add_folder ((CamelVeeFolder *) folder, (CamelFolder *) folders->pdata[i], NULL);
			g_object_unref (folders->pdata[i]);
		}
		g_ptr_array_free (folders, TRUE);
	}

	return folder;
}

static gboolean
store_maybe_connect_sync (CamelStore *store,
                          GCancellable *cancellable,
                          GError **error)
{
	CamelService *service;
	CamelServiceConnectionStatus status;
	CamelSession *session;
	gboolean connect = FALSE;
	gboolean success = TRUE;

	/* This is meant to recover from dropped connections
	 * when the CamelService is online but disconnected. */

	service = CAMEL_SERVICE (store);
	session = camel_service_ref_session (service);
	status = camel_service_get_connection_status (service);
	connect = session && camel_session_get_online (session) && (status != CAMEL_SERVICE_CONNECTED);
	g_clear_object (&session);

	if (connect && CAMEL_IS_NETWORK_SERVICE (store)) {
		/* Disregard errors here.  Just want to
		 * know whether to attempt a connection. */
		connect = camel_network_service_can_reach_sync (
			CAMEL_NETWORK_SERVICE (service), cancellable, NULL);
	}

	if (connect && CAMEL_IS_OFFLINE_STORE (store)) {
		CamelOfflineStore *offline_store;

		offline_store = CAMEL_OFFLINE_STORE (store);
		if (!camel_offline_store_get_online (offline_store))
			connect = FALSE;
	}

	if (connect) {
		GError *local_error = NULL;

		success = camel_service_connect_sync (service, cancellable, &local_error);

		if (local_error) {
			if (local_error->domain == G_IO_ERROR ||
			    g_error_matches (local_error, CAMEL_SERVICE_ERROR, CAMEL_SERVICE_ERROR_UNAVAILABLE)) {
				/* Ignore I/O errors, treat it as being offline */
				success = TRUE;
				g_clear_error (&local_error);
			} else {
				g_propagate_error (error, local_error);
			}
		}
	}

	return success;
}

static void
store_finalize (GObject *object)
{
	CamelStore *store = CAMEL_STORE (object);

	if (store->priv->folders)
		camel_object_bag_destroy (store->priv->folders);

	g_clear_object (&store->priv->cdb);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_store_parent_class)->finalize (object);
}

static void
store_dispose (GObject *object)
{
	CamelStore *store = CAMEL_STORE (object);

	if (store->priv->folders) {
		camel_object_bag_destroy (store->priv->folders);
		store->priv->folders = NULL;
	}

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (camel_store_parent_class)->dispose (object);
}

static void
store_constructed (GObject *object)
{
	CamelStore *store;
	CamelStoreClass *class;

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (camel_store_parent_class)->constructed (object);

	store = CAMEL_STORE (object);
	class = CAMEL_STORE_GET_CLASS (store);

	g_return_if_fail (class != NULL);
	g_return_if_fail (class->hash_folder_name != NULL);
	g_return_if_fail (class->equal_folder_name != NULL);

	store->priv->folders = camel_object_bag_new (
		class->hash_folder_name,
		class->equal_folder_name,
		(CamelCopyFunc) g_strdup, g_free);
}

static gboolean
store_can_refresh_folder (CamelStore *store,
                          CamelFolderInfo *info,
                          GError **error)
{
	return ((info->flags & CAMEL_FOLDER_TYPE_MASK) == CAMEL_FOLDER_TYPE_INBOX);
}

static CamelFolder *
store_get_inbox_folder_sync (CamelStore *store,
                             GCancellable *cancellable,
                             GError **error)
{
	CamelStoreClass *class;
	CamelFolder *folder;

	class = CAMEL_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_folder_sync != NULL, NULL);

	/* Assume the inbox's name is "inbox" and open with default flags. */
	folder = class->get_folder_sync (store, "inbox", 0, cancellable, error);
	CAMEL_CHECK_GERROR (store, get_folder_sync, folder != NULL, error);

	return folder;
}

static CamelFolder *
store_get_junk_folder_sync (CamelStore *store,
                            GCancellable *cancellable,
                            GError **error)
{
	return store_get_special (store, CAMEL_VTRASH_FOLDER_JUNK);
}

static CamelFolder *
store_get_trash_folder_sync (CamelStore *store,
                             GCancellable *cancellable,
                             GError **error)
{
	return store_get_special (store, CAMEL_VTRASH_FOLDER_TRASH);
}

static gboolean
store_synchronize_sync (CamelStore *store,
                        gboolean expunge,
                        GCancellable *cancellable,
                        GError **error)
{
	GPtrArray *folders;
	gboolean success = TRUE;
	gint ii;
	GError *local_error = NULL;

	if (expunge) {
		/* ensure all folders are used when expunging */
		CamelFolderInfo *root, *fi;

		(void) g_atomic_int_add (&store->priv->maintenance_lock, 1);

		folders = g_ptr_array_new ();
		root = camel_store_get_folder_info_sync (
			store, NULL,
			CAMEL_STORE_FOLDER_INFO_RECURSIVE |
			CAMEL_STORE_FOLDER_INFO_SUBSCRIBED |
			CAMEL_STORE_FOLDER_INFO_NO_VIRTUAL,
			NULL, NULL);
		fi = root;
		while (fi != NULL) {
			CamelFolderInfo *next;

			if ((fi->flags & CAMEL_FOLDER_NOSELECT) == 0) {
				CamelFolder *folder;

				folder = camel_store_get_folder_sync (
					store, fi->full_name, 0, NULL, NULL);
				if (folder != NULL)
					g_ptr_array_add (folders, folder);
			}

			/* pick the next */
			next = fi->child;
			if (next == NULL)
				next = fi->next;
			if (next == NULL) {
				next = fi->parent;
				while (next != NULL) {
					if (next->next != NULL) {
						next = next->next;
						break;
					}

					next = next->parent;
				}
			}

			fi = next;
		}

		camel_folder_info_free (root);
	} else if (store->priv->folders) {
		/* sync only folders opened until now */
		folders = camel_object_bag_list (store->priv->folders);
	} else {
		folders = g_ptr_array_new ();
	}

	/* We don't sync any vFolders, that is used to update certain
	 * vfolder queries mainly, and we're really only interested in
	 * storing/expunging the physical mails. */
	for (ii = 0; ii < folders->len; ii++) {
		CamelFolder *folder = folders->pdata[ii];

		if (camel_folder_get_folder_summary (folder))
			camel_folder_summary_save (camel_folder_get_folder_summary (folder), NULL);

		if (!CAMEL_IS_VEE_FOLDER (folder) && local_error == NULL) {
			camel_folder_synchronize_sync (
				folder, expunge, cancellable, &local_error);
			ignore_no_such_table_exception (&local_error);
		}
		g_object_unref (folder);
	}

	/* Unlock it before the call, thus it's actually done. */
	if (expunge)
		(void) g_atomic_int_add (&store->priv->maintenance_lock, -1);

	if (!local_error && expunge) {
		camel_store_maybe_run_db_maintenance (store, &local_error);
	}

	if (local_error != NULL) {
		g_propagate_error (error, local_error);
		success = FALSE;
	}

	g_ptr_array_free (folders, TRUE);

	return success;
}

static gboolean
store_initial_setup_sync (CamelStore *store,
			  GHashTable *out_save_setup,
			  GCancellable *cancellable,
			  GError **error)
{
	return TRUE;
}

static gboolean
store_initable_init (GInitable *initable,
                     GCancellable *cancellable,
                     GError **error)
{
	CamelStore *store;
	CamelService *service;
	const gchar *user_dir;
	gchar *filename;

	store = CAMEL_STORE (initable);

	/* Chain up to parent interface's init() method. */
	if (!parent_initable_interface->init (initable, cancellable, error))
		return FALSE;

	service = CAMEL_SERVICE (initable);
	if ((store->priv->flags & CAMEL_STORE_USE_CACHE_DIR) != 0)
		user_dir = camel_service_get_user_cache_dir (service);
	else
		user_dir = camel_service_get_user_data_dir (service);

	if (g_mkdir_with_parents (user_dir, S_IRWXU) == -1) {
		g_set_error_literal (
			error, G_FILE_ERROR,
			g_file_error_from_errno (errno),
			g_strerror (errno));
		return FALSE;
	}

	/* This is for reading from the store */
	filename = g_build_filename (user_dir, CAMEL_DB_FILE, NULL);
	store->priv->cdb = camel_db_new (filename, error);
	g_free (filename);

	if (store->priv->cdb == NULL)
		return FALSE;

	if (camel_db_create_folders_table (store->priv->cdb, error))
		return FALSE;

	return TRUE;
}

static void
camel_store_class_init (CamelStoreClass *class)
{
	GObjectClass *object_class;
	CamelServiceClass *service_class;

	g_type_class_add_private (class, sizeof (CamelStorePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = store_finalize;
	object_class->dispose = store_dispose;
	object_class->constructed = store_constructed;

	service_class = CAMEL_SERVICE_CLASS (class);
	service_class->settings_type = CAMEL_TYPE_STORE_SETTINGS;

	class->hash_folder_name = g_str_hash;
	class->equal_folder_name = g_str_equal;
	class->can_refresh_folder = store_can_refresh_folder;

	class->get_inbox_folder_sync = store_get_inbox_folder_sync;
	class->get_junk_folder_sync = store_get_junk_folder_sync;
	class->get_trash_folder_sync = store_get_trash_folder_sync;
	class->synchronize_sync = store_synchronize_sync;
	class->initial_setup_sync = store_initial_setup_sync;

	signals[FOLDER_CREATED] = g_signal_new (
		"folder-created",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (CamelStoreClass, folder_created),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		CAMEL_TYPE_FOLDER_INFO);

	signals[FOLDER_DELETED] = g_signal_new (
		"folder-deleted",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (CamelStoreClass, folder_deleted),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		CAMEL_TYPE_FOLDER_INFO);

	/**
	 * CamelStore::folder-info-stale:
	 * @store: the #CamelStore that received the signal
	 *
	 * This signal indicates significant changes have occurred to
	 * the folder hierarchy of @store, and that previously fetched
	 * #CamelFolderInfo data should be considered stale.
	 *
	 * Applications should handle this signal by replacing cached
	 * #CamelFolderInfo data for @store with fresh data by way of
	 * camel_store_get_folder_info().
	 *
	 * More often than not this signal will be emitted as a result of
	 * user preference changes rather than actual server-side changes.
	 * For example, a user may change a preference that reveals a set
	 * of folders previously hidden from view, or that alters whether
	 * to augment the @store with virtual Junk and Trash folders.
	 **/
	signals[FOLDER_INFO_STALE] = g_signal_new (
		"folder-info-stale",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (CamelStoreClass, folder_info_stale),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);

	signals[FOLDER_OPENED] = g_signal_new (
		"folder-opened",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (CamelStoreClass, folder_opened),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		CAMEL_TYPE_FOLDER);

	signals[FOLDER_RENAMED] = g_signal_new (
		"folder-renamed",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (CamelStoreClass, folder_renamed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 2,
		G_TYPE_STRING,
		CAMEL_TYPE_FOLDER_INFO);
}

static void
camel_store_initable_init (GInitableIface *iface)
{
	parent_initable_interface = g_type_interface_peek_parent (iface);

	iface->init = store_initable_init;
}

static void
camel_store_init (CamelStore *store)
{
	store->priv = CAMEL_STORE_GET_PRIVATE (store);

	/* Default CamelStore capabilities:
	 *
	 *  - Include a virtual Junk folder.
	 *  - Include a virtual Trash folder.
	 *  - Allow creating/deleting/renaming folders.
	 */
	store->priv->flags =
		CAMEL_STORE_VJUNK |
		CAMEL_STORE_VTRASH |
		CAMEL_STORE_CAN_EDIT_FOLDERS;

	store->priv->permissions = CAMEL_STORE_READ | CAMEL_STORE_WRITE;
	store->priv->maintenance_lock = 0;
}

G_DEFINE_QUARK (camel-store-error-quark, camel_store_error)

/**
 * camel_store_get_db:
 * @store: a #CamelStore
 *
 * Returns: (transfer none): A #CamelDB instance associated with this @store.
 *
 * Since: 3.24
 **/
CamelDB *
camel_store_get_db (CamelStore *store)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);

	return store->priv->cdb;
}

/**
 * camel_store_get_folders_bag:
 * @store: a #CamelStore
 *
 * Returns: (transfer none): a #CamelObjectBag of opened #CamelFolder<!-- -->s
 *
 * Since: 3.24
 **/
CamelObjectBag *
camel_store_get_folders_bag (CamelStore *store)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);

	return store->priv->folders;
}

/**
 * camel_store_dup_opened_folders:
 * @store: a #CamelStore
 *
 * Returns a #GPtrArray of all the opened folders for the @store. The caller owns
 * both the array and the folder references, so to free the array use:
 *
 * |[
 *     g_ptr_array_foreach (array, (GFunc) g_object_unref, NULL);
 *     g_ptr_array_free (array, TRUE);
 * ]|
 *
 * Returns: (element-type CamelFolder) (transfer full): an array with all currently
 *   opened folders for the @store.
 *
 * Since: 3.24
 **/
GPtrArray *
camel_store_dup_opened_folders (CamelStore *store)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);
	g_return_val_if_fail (store->priv->folders != NULL, NULL);

	return camel_object_bag_list (store->priv->folders);
}

/**
 * camel_store_get_flags:
 * @store: a #CamelStore
 *
 * Returns: bit-or of #CamelStoreFlags set for the @store
 *
 * Since: 3.24
 **/
guint32
camel_store_get_flags (CamelStore *store)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), 0);

	return store->priv->flags;
}

/**
 * camel_store_set_flags:
 * @store: a #CamelStore
 * @flags: bit-or of #CamelStoreFlags
 *
 * Sets flags for the @store, a bit-or of #CamelStoreFlags.
 *
 * Since: 3.24
 **/
void
camel_store_set_flags (CamelStore *store,
		       guint32 flags)
{
	g_return_if_fail (CAMEL_IS_STORE (store));

	store->priv->flags = flags;
}

/**
 * camel_store_get_permissions:
 * @store: a #CamelStore
 *
 * Returns: Permissions of the @store, a bit-or of #CamelStorePermissionFlags
 *
 * Since: 3.24
 **/
guint32
camel_store_get_permissions (CamelStore *store)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), 0);

	return store->priv->permissions;
}

/**
 * camel_store_set_permissions:
 * @store: a #CamelStore
 * @permissions: permissions of the @store, a bit-or of #CamelStorePermissionFlags
 *
 * Sets permissions for the @store, a bit-or of #CamelStorePermissionFlags
 *
 * Since: 3.24
 **/
void
camel_store_set_permissions (CamelStore *store,
			     guint32 permissions)
{
	g_return_if_fail (CAMEL_IS_STORE (store));

	store->priv->permissions = permissions;
}

/**
 * camel_store_folder_created:
 * @store: a #CamelStore
 * @folder_info: information about the created folder
 *
 * Emits the #CamelStore::folder-created signal from an idle source on
 * the main loop.  The idle source's priority is #G_PRIORITY_HIGH_IDLE.
 *
 * This function is only intended for Camel providers.
 *
 * Since: 2.32
 **/
void
camel_store_folder_created (CamelStore *store,
                            CamelFolderInfo *folder_info)
{
	CamelSession *session;
	SignalClosure *signal_closure;

	g_return_if_fail (CAMEL_IS_STORE (store));
	g_return_if_fail (folder_info != NULL);

	session = camel_service_ref_session (CAMEL_SERVICE (store));
	if (!session)
		return;

	signal_closure = g_slice_new0 (SignalClosure);
	g_weak_ref_init (&signal_closure->store, store);
	signal_closure->folder_info = camel_folder_info_clone (folder_info);

	/* Prioritize ahead of GTK+ redraws. */
	camel_session_idle_add (
		session, G_PRIORITY_HIGH_IDLE,
		store_emit_folder_created_cb,
		signal_closure,
		(GDestroyNotify) signal_closure_free);

	g_object_unref (session);
}

/**
 * camel_store_folder_deleted:
 * @store: a #CamelStore
 * @folder_info: information about the deleted folder
 *
 * Emits the #CamelStore::folder-deleted signal from an idle source on
 * the main loop.  The idle source's priority is #G_PRIORITY_HIGH_IDLE.
 *
 * This function is only intended for Camel providers.
 *
 * Since: 2.32
 **/
void
camel_store_folder_deleted (CamelStore *store,
                            CamelFolderInfo *folder_info)
{
	CamelSession *session;
	SignalClosure *signal_closure;

	g_return_if_fail (CAMEL_IS_STORE (store));
	g_return_if_fail (folder_info != NULL);

	session = camel_service_ref_session (CAMEL_SERVICE (store));
	if (!session)
		return;

	signal_closure = g_slice_new0 (SignalClosure);
	g_weak_ref_init (&signal_closure->store, store);
	signal_closure->folder_info = camel_folder_info_clone (folder_info);

	/* Prioritize ahead of GTK+ redraws. */
	camel_session_idle_add (
		session, G_PRIORITY_HIGH_IDLE,
		store_emit_folder_deleted_cb,
		signal_closure,
		(GDestroyNotify) signal_closure_free);

	g_object_unref (session);
}

/**
 * camel_store_folder_opened:
 * @store: a #CamelStore
 * @folder: the #CamelFolder that was opened
 *
 * Emits the #CamelStore::folder-opened signal from an idle source on
 * the main loop.  The idle source's priority is #G_PRIORITY_HIGH_IDLE.
 *
 * This function is only intended for Camel providers.
 *
 * Since: 3.0
 **/
void
camel_store_folder_opened (CamelStore *store,
                           CamelFolder *folder)
{
	CamelSession *session;
	SignalClosure *signal_closure;

	g_return_if_fail (CAMEL_IS_STORE (store));
	g_return_if_fail (CAMEL_IS_FOLDER (folder));

	session = camel_service_ref_session (CAMEL_SERVICE (store));
	if (!session)
		return;

	signal_closure = g_slice_new0 (SignalClosure);
	g_weak_ref_init (&signal_closure->store, store);
	signal_closure->folder = g_object_ref (folder);

	/* Prioritize ahead of GTK+ redraws. */
	camel_session_idle_add (
		session, G_PRIORITY_HIGH_IDLE,
		store_emit_folder_opened_cb,
		signal_closure,
		(GDestroyNotify) signal_closure_free);

	g_object_unref (session);
}

/**
 * camel_store_folder_renamed:
 * @store: a #CamelStore
 * @old_name: the old name of the folder
 * @folder_info: information about the renamed folder
 *
 * Emits the #CamelStore::folder-renamed signal from an idle source on
 * the main loop.  The idle source's priority is #G_PRIORITY_HIGH_IDLE.
 *
 * This function is only intended for Camel providers.
 *
 * Since: 2.32
 **/
void
camel_store_folder_renamed (CamelStore *store,
                            const gchar *old_name,
                            CamelFolderInfo *folder_info)
{
	CamelSession *session;
	SignalClosure *signal_closure;

	g_return_if_fail (CAMEL_IS_STORE (store));
	g_return_if_fail (old_name != NULL);
	g_return_if_fail (folder_info != NULL);

	session = camel_service_ref_session (CAMEL_SERVICE (store));
	if (!session)
		return;

	signal_closure = g_slice_new0 (SignalClosure);
	g_weak_ref_init (&signal_closure->store, store);
	signal_closure->folder_info = camel_folder_info_clone (folder_info);
	signal_closure->folder_name = g_strdup (old_name);

	/* Prioritize ahead of GTK+ redraws. */
	camel_session_idle_add (
		session, G_PRIORITY_HIGH_IDLE,
		store_emit_folder_renamed_cb,
		signal_closure,
		(GDestroyNotify) signal_closure_free);

	g_object_unref (session);
}

/**
 * camel_store_folder_info_stale:
 * @store: a #CamelStore
 *
 * Emits the #CamelStore::folder-info-stale signal from an idle source
 * on the main loop.  The idle source's priority is #G_PRIORITY_LOW.
 *
 * See the #CamelStore::folder-info-stale documentation for details on
 * when to use this signal.
 *
 * This function is only intended for Camel providers.
 *
 * Since: 3.10
 **/
void
camel_store_folder_info_stale (CamelStore *store)
{
	CamelSession *session;

	g_return_if_fail (CAMEL_IS_STORE (store));

	session = camel_service_ref_session (CAMEL_SERVICE (store));
	if (!session)
		return;

	g_mutex_lock (&store->priv->signal_emission_lock);

	/* Handling this signal is probably going to be expensive for
	 * applications so try and accumulate multiple calls into one
	 * signal emission if we can.  Hence the G_PRIORITY_LOW. */
	if (!store->priv->folder_info_stale_scheduled) {
		SignalClosure *signal_closure;

		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->store, store);

		camel_session_idle_add (
			session, G_PRIORITY_LOW,
			store_emit_folder_info_stale_cb,
			signal_closure,
			(GDestroyNotify) signal_closure_free);

		store->priv->folder_info_stale_scheduled = TRUE;
	}

	g_mutex_unlock (&store->priv->signal_emission_lock);

	g_object_unref (session);
}

static void
add_special_info (CamelStore *store,
                  CamelFolderInfo *info,
                  const gchar *name,
                  const gchar *translated,
                  gboolean unread_count,
                  CamelFolderInfoFlags flags)
{
	CamelFolderInfo *fi, *vinfo, *parent;

	g_return_if_fail (CAMEL_IS_STORE (store));
	g_return_if_fail (info != NULL);

	parent = NULL;
	for (fi = info; fi; fi = fi->next) {
		if (!strcmp (fi->full_name, name))
			break;
		parent = fi;
	}

	if (fi) {
		/* We're going to replace the physical Trash/Junk
		 * folder with our vTrash/vJunk folder. */
		vinfo = fi;
		g_free (vinfo->full_name);
		g_free (vinfo->display_name);
	} else {
		g_return_if_fail (parent != NULL);

		/* There wasn't a Trash/Junk folder so create a new
		 * folder entry. */
		vinfo = camel_folder_info_new ();

		vinfo->flags |=
			CAMEL_FOLDER_NOINFERIORS |
			CAMEL_FOLDER_SUBSCRIBED;

		/* link it into the right spot */
		vinfo->next = parent->next;
		parent->next = vinfo;
	}

	/* Fill in the new fields */
	vinfo->flags |= flags;
	vinfo->full_name = g_strdup (name);
	vinfo->display_name = g_strdup (translated);

	if (!unread_count)
		vinfo->unread = -1;
}

static void
dump_fi (CamelFolderInfo *fi,
         gint depth)
{
	gchar *s;

	s = g_alloca (depth + 1);
	memset (s, ' ', depth);
	s[depth] = 0;

	while (fi) {
		printf ("%sfull_name: %s\n", s, fi->full_name);
		printf ("%sflags: %08x\n", s, fi->flags);
		dump_fi (fi->child, depth + 2);
		fi = fi->next;
	}
}

/**
 * camel_folder_info_free:
 * @fi: a #CamelFolderInfo
 *
 * Frees @fi.
 **/
void
camel_folder_info_free (CamelFolderInfo *fi)
{
	if (fi != NULL) {
		camel_folder_info_free (fi->next);
		camel_folder_info_free (fi->child);
		g_free (fi->full_name);
		g_free (fi->display_name);
		g_slice_free (CamelFolderInfo, fi);
	}
}

/**
 * camel_folder_info_new:
 *
 * Allocates a new #CamelFolderInfo instance.  Free it with
 * camel_folder_info_free().
 *
 * Returns: a new #CamelFolderInfo instance
 *
 * Since: 2.22
 **/
CamelFolderInfo *
camel_folder_info_new (void)
{
	return g_slice_new0 (CamelFolderInfo);
}

static gint
folder_info_cmp (gconstpointer ap,
                 gconstpointer bp)
{
	const CamelFolderInfo *a = ((CamelFolderInfo **) ap)[0];
	const CamelFolderInfo *b = ((CamelFolderInfo **) bp)[0];

	return strcmp (a->full_name, b->full_name);
}

/**
 * camel_folder_info_build:
 * @folders: (element-type CamelFolderInfo): an array of #CamelFolderInfo
 * @namespace_: an ignorable prefix on the folder names
 * @separator: the hieararchy separator character
 * @short_names: %TRUE if the (short) name of a folder is the part after
 * the last @separator in the full name. %FALSE if it is the full name.
 *
 * This takes an array of folders and attaches them together according
 * to the hierarchy described by their full_names and @separator. If
 * @namespace_ is non-%NULL, then it will be ignored as a full_name
 * prefix, for purposes of comparison. If necessary,
 * camel_folder_info_build() will create additional #CamelFolderInfo with
 * %NULL urls to fill in gaps in the tree. The value of @short_names
 * is used in constructing the names of these intermediate folders.
 *
 * NOTE: This is deprected, do not use this.
 * FIXME: remove this/move it to imap, which is the only user of it now.
 *
 * Deprecated:
 * Returns: the top level of the tree of linked folder info.
 **/
CamelFolderInfo *
camel_folder_info_build (GPtrArray *folders,
                         const gchar *namespace_,
                         gchar separator,
                         gboolean short_names)
{
	CamelFolderInfo *fi, *pfi, *top = NULL, *tail = NULL;
	GHashTable *hash;
	gchar *p, *pname;
	gint i, nlen;

	if (!folders || !folders->len) {
		g_warn_if_fail (folders != NULL);
		return NULL;
	}

	if (!folders->pdata) {
		g_warn_if_fail (folders->pdata != NULL);
		return NULL;
	}

	if (namespace_ == NULL)
		namespace_ = "";
	nlen = strlen (namespace_);

	qsort (folders->pdata, folders->len, sizeof (folders->pdata[0]), folder_info_cmp);

	/* Hash the folders. */
	hash = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);
	for (i = 0; i < folders->len; i++) {
		fi = folders->pdata[i];
		g_hash_table_insert (hash, g_strdup (fi->full_name), fi);
	}

	/* Now find parents. */
	for (i = 0; i < folders->len; i++) {
		fi = folders->pdata[i];
		if (!strncmp (namespace_, fi->full_name, nlen)
		    && (p = strrchr (fi->full_name + nlen, separator))) {
			pname = g_strndup (fi->full_name, p - fi->full_name);
			pfi = g_hash_table_lookup (hash, pname);
			if (pfi) {
				g_free (pname);
			} else {
				/* we are missing a folder in the heirarchy so
				 * create a fake folder node */

				pfi = camel_folder_info_new ();

				if (short_names) {
					pfi->display_name = strrchr (pname, separator);
					if (pfi->display_name != NULL)
						pfi->display_name = g_strdup (pfi->display_name + 1);
					else
						pfi->display_name = g_strdup (pname);
				} else
					pfi->display_name = g_strdup (pname);

				pfi->full_name = g_strdup (pname);

				/* Since this is a "fake" folder
				 * node, it is not selectable. */
				pfi->flags |= CAMEL_FOLDER_NOSELECT;

				g_hash_table_insert (hash, pname, pfi);
				g_ptr_array_add (folders, pfi);
			}
			tail = (CamelFolderInfo *) &pfi->child;
			while (tail->next)
				tail = tail->next;
			tail->next = fi;
			fi->parent = pfi;
		} else if (!top || !g_ascii_strcasecmp (fi->full_name, "Inbox"))
			top = fi;
	}
	g_hash_table_destroy (hash);

	/* Link together the top-level folders */
	tail = top;
	for (i = 0; i < folders->len; i++) {
		fi = folders->pdata[i];

		if (fi->child)
			fi->flags &= ~CAMEL_FOLDER_NOCHILDREN;

		if (fi->parent || fi == top)
			continue;
		if (tail == NULL) {
			tail = fi;
			top = fi;
		} else {
			tail->next = fi;
			tail = fi;
		}
	}

	return top;
}

static CamelFolderInfo *
folder_info_clone_rec (CamelFolderInfo *fi,
                       CamelFolderInfo *parent)
{
	CamelFolderInfo *info;

	info = camel_folder_info_new ();
	info->parent = parent;
	info->full_name = g_strdup (fi->full_name);
	info->display_name = g_strdup (fi->display_name);
	info->unread = fi->unread;
	info->flags = fi->flags;

	if (fi->next)
		info->next = folder_info_clone_rec (fi->next, parent);
	else
		info->next = NULL;

	if (fi->child)
		info->child = folder_info_clone_rec (fi->child, info);
	else
		info->child = NULL;

	return info;
}

/**
 * camel_folder_info_clone:
 * @fi: a #CamelFolderInfo
 *
 * Clones @fi recursively.
 *
 * Returns: the cloned #CamelFolderInfo tree.
 **/
CamelFolderInfo *
camel_folder_info_clone (CamelFolderInfo *fi)
{
	if (fi == NULL)
		return NULL;

	return folder_info_clone_rec (fi, NULL);
}

/**
 * camel_store_can_refresh_folder
 * @store: a #CamelStore
 * @info: a #CamelFolderInfo
 * @error: return location for a #GError, or %NULL
 *
 * Returns if this folder (param info) should be checked for new mail or not.
 * It should not look into sub infos (info->child) or next infos, it should
 * return value only for the actual folder info.
 * Default behavior is that all Inbox folders are intended to be refreshed.
 *
 * Returns: whether folder should be checked for new mails
 *
 * Since: 2.22
 **/
gboolean
camel_store_can_refresh_folder (CamelStore *store,
                                CamelFolderInfo *info,
                                GError **error)
{
	CamelStoreClass *class;

	g_return_val_if_fail (CAMEL_IS_STORE (store), FALSE);
	g_return_val_if_fail (info != NULL, FALSE);

	class = CAMEL_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->can_refresh_folder != NULL, FALSE);

	return class->can_refresh_folder (store, info, error);
}

/**
 * camel_store_get_folder_sync:
 * @store: a #CamelStore
 * @folder_name: name of the folder to get
 * @flags: folder flags (create, save body index, etc)
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets a specific folder object from @store by name.
 *
 * Returns: (transfer full) (nullable): the requested #CamelFolder object, or
 * %NULL on error
 *
 * Since: 3.0
 **/
CamelFolder *
camel_store_get_folder_sync (CamelStore *store,
                             const gchar *folder_name,
                             CamelStoreGetFolderFlags flags,
                             GCancellable *cancellable,
                             GError **error)
{
	CamelStoreClass *class;
	CamelFolder *folder = NULL;
	CamelVeeFolder *vjunk = NULL;
	CamelVeeFolder *vtrash = NULL;
	gboolean create_folder = FALSE;
	gboolean folder_name_is_vjunk;
	gboolean folder_name_is_vtrash;
	gboolean store_uses_vjunk;
	gboolean store_uses_vtrash;

	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);
	g_return_val_if_fail (folder_name != NULL, NULL);

	class = CAMEL_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, NULL);

try_again:
	/* Try cache first. */
	folder = store->priv->folders ? camel_object_bag_reserve (store->priv->folders, folder_name) : NULL;
	if (folder != NULL) {
		if ((flags & CAMEL_STORE_FOLDER_INFO_REFRESH) != 0)
			camel_folder_prepare_content_refresh (folder);

		return folder;
	}

	store_uses_vjunk =
		((store->priv->flags & CAMEL_STORE_VJUNK) != 0);
	store_uses_vtrash =
		((store->priv->flags & CAMEL_STORE_VTRASH) != 0);
	folder_name_is_vjunk =
		store_uses_vjunk &&
		(strcmp (folder_name, CAMEL_VJUNK_NAME) == 0);
	folder_name_is_vtrash =
		store_uses_vtrash &&
		(strcmp (folder_name, CAMEL_VTRASH_NAME) == 0);

	if (flags & CAMEL_STORE_IS_MIGRATING) {
		if (folder_name_is_vtrash) {
			if (store->priv->folders != NULL)
				camel_object_bag_abort (
					store->priv->folders, folder_name);
			return NULL;
		}

		if (folder_name_is_vjunk) {
			if (store->priv->folders != NULL)
				camel_object_bag_abort (
					store->priv->folders, folder_name);
			return NULL;
		}
	}

	if (folder_name_is_vtrash)
		g_return_val_if_fail (class->get_trash_folder_sync != NULL, NULL);
	else if (folder_name_is_vjunk)
		g_return_val_if_fail (class->get_junk_folder_sync != NULL, NULL);
	else
		g_return_val_if_fail (class->get_folder_sync != NULL, NULL);

	camel_operation_push_message (
		cancellable, _("Opening folder “%s”"), folder_name);

	if (folder_name_is_vtrash) {
		folder = class->get_trash_folder_sync (
			store, cancellable, error);
		CAMEL_CHECK_GERROR (
			store, get_trash_folder_sync,
			folder != NULL, error);
	} else if (folder_name_is_vjunk) {
		folder = class->get_junk_folder_sync (
			store, cancellable, error);
		CAMEL_CHECK_GERROR (
			store, get_junk_folder_sync,
			folder != NULL, error);
	} else {
		GError *local_error = NULL;

		/* If CAMEL_STORE_FOLDER_CREATE flag is set, note it and
		 * strip it so subclasses never receive it.  We'll handle
		 * it ourselves below. */
		create_folder = ((flags & CAMEL_STORE_FOLDER_CREATE) != 0);
		flags &= ~CAMEL_STORE_FOLDER_CREATE;

		folder = class->get_folder_sync (
			store, folder_name, flags,
			cancellable, &local_error);
		CAMEL_CHECK_LOCAL_GERROR (
			store, get_folder_sync,
			folder != NULL, local_error);

		/* XXX This depends on subclasses setting this error code
		 *     consistently.  Do they?  I guess we'll find out... */
		create_folder &= g_error_matches (
			local_error,
			CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER);

		if (create_folder)
			g_clear_error (&local_error);

		if (local_error != NULL)
			g_propagate_error (error, local_error);

		if (folder != NULL && store_uses_vjunk && store->priv->folders)
			vjunk = camel_object_bag_get (
				store->priv->folders, CAMEL_VJUNK_NAME);

		if (folder != NULL && store_uses_vtrash && store->priv->folders)
			vtrash = camel_object_bag_get (
				store->priv->folders, CAMEL_VTRASH_NAME);
	}

	/* Release the folder name reservation before adding the
	 * folder to the virtual Junk and Trash folders, just to
	 * reduce the chance of deadlock. */
	if (store->priv->folders) {
		if (folder != NULL)
			camel_object_bag_add (store->priv->folders, folder_name, folder);
		else
			camel_object_bag_abort (store->priv->folders, folder_name);
	}

	/* If this is a normal folder and the store uses a
	 * virtual Junk folder, let the virtual Junk folder
	 * track this folder. */
	if (vjunk != NULL) {
		camel_vee_folder_add_folder (vjunk, folder, NULL);
		g_object_unref (vjunk);
	}

	/* If this is a normal folder and the store uses a
	 * virtual Trash folder, let the virtual Trash folder
	 * track this folder. */
	if (vtrash != NULL) {
		camel_vee_folder_add_folder (vtrash, folder, NULL);
		g_object_unref (vtrash);
	}

	camel_operation_pop_message (cancellable);

	if (folder != NULL)
		camel_store_folder_opened (store, folder);

	/* Handle CAMEL_STORE_FOLDER_CREATE flag. */
	if (create_folder) {
		CamelFolderInfo *folder_info;
		gchar *reversed_name;
		gchar **child_and_parent;

		g_warn_if_fail (folder == NULL);
		g_return_val_if_fail (class->create_folder_sync != NULL, NULL);

		/* XXX GLib lacks a rightmost string splitting function,
		 *     so we'll reverse the string and use g_strsplit(). */
		reversed_name = g_strreverse (g_strdup (folder_name));
		child_and_parent = g_strsplit (reversed_name, "/", 2);
		g_return_val_if_fail (child_and_parent[0] != NULL, NULL);

		/* Element 0 is the new folder name.
		 * Element 1 is the parent path, or NULL. */

		/* XXX Reverse the child and parent names back. */
		g_strreverse (child_and_parent[0]);
		if (child_and_parent[1] != NULL)
			g_strreverse (child_and_parent[1]);

		/* Call the method directly to avoid the queuing
		 * behavior of camel_store_create_folder_sync(). */
		folder_info = class->create_folder_sync (
			store,
			child_and_parent[1],
			child_and_parent[0],
			cancellable, error);
		CAMEL_CHECK_GERROR (
			store, create_folder_sync,
			folder_info != NULL, error);

		g_strfreev (child_and_parent);
		g_free (reversed_name);

		/* If we successfully created the folder, retry the
		 * method without the CAMEL_STORE_FOLDER_CREATE flag. */
		if (folder_info != NULL) {
			camel_folder_info_free (folder_info);
			goto try_again;
		}
	}

	if (folder && (flags & CAMEL_STORE_FOLDER_INFO_REFRESH) != 0)
		camel_folder_prepare_content_refresh (folder);

	return folder;
}

/* Helper for camel_store_get_folder() */
static void
store_get_folder_thread (GTask *task,
                         gpointer source_object,
                         gpointer task_data,
                         GCancellable *cancellable)
{
	CamelFolder *folder;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	folder = camel_store_get_folder_sync (
		CAMEL_STORE (source_object),
		async_context->folder_name_1,
		async_context->flags,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_warn_if_fail (folder == NULL);
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (
			task, folder,
			(GDestroyNotify) g_object_unref);
	}
}

/**
 * camel_store_get_folder:
 * @store: a #CamelStore
 * @folder_name: name of the folder to get
 * @flags: folder flags (create, save body index, etc)
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously gets a specific folder object from @store by name.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_store_get_folder_finish() to get the result of the operation.
 *
 * Since: 3.0
 **/
void
camel_store_get_folder (CamelStore *store,
                        const gchar *folder_name,
                        CamelStoreGetFolderFlags flags,
                        gint io_priority,
                        GCancellable *cancellable,
                        GAsyncReadyCallback callback,
                        gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_STORE (store));
	g_return_if_fail (folder_name != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->folder_name_1 = g_strdup (folder_name);
	async_context->flags = flags;

	task = g_task_new (store, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_store_get_folder);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, store_get_folder_thread);

	g_object_unref (task);
}

/**
 * camel_store_get_folder_finish:
 * @store: a #CamelStore
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_store_get_folder().
 *
 * Returns: (transfer full) (nullable): the requested #CamelFolder object, or
 * %NULL on error
 *
 * Since: 3.0
 **/
CamelFolder *
camel_store_get_folder_finish (CamelStore *store,
                               GAsyncResult *result,
                               GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);
	g_return_val_if_fail (g_task_is_valid (result, store), NULL);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_store_get_folder), NULL);

	return g_task_propagate_pointer (G_TASK (result), error);
}

/**
 * camel_store_get_folder_info_sync:
 * @store: a #CamelStore
 * @top: (nullable): the name of the folder to start from
 * @flags: various CAMEL_STORE_FOLDER_INFO_* flags to control behavior
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * This fetches information about the folder structure of @store,
 * starting with @top, and returns a tree of #CamelFolderInfo
 * structures. If @flags includes %CAMEL_STORE_FOLDER_INFO_SUBSCRIBED,
 * only subscribed folders will be listed.   If the store doesn't support
 * subscriptions, then it will list all folders.  If @flags includes
 * %CAMEL_STORE_FOLDER_INFO_RECURSIVE, the returned tree will include
 * all levels of hierarchy below @top. If not, it will only include
 * the immediate subfolders of @top. If @flags includes
 * %CAMEL_STORE_FOLDER_INFO_FAST, the unread_message_count fields of
 * some or all of the structures may be set to -1, if the store cannot
 * determine that information quickly.  If @flags includes
 * %CAMEL_STORE_FOLDER_INFO_NO_VIRTUAL, don't include special virtual
 * folders (such as vTrash or vJunk).
 *
 * The returned #CamelFolderInfo tree should be freed with
 * camel_folder_info_free().
 *
 * The CAMEL_STORE_FOLDER_INFO_FAST flag should be considered
 * deprecated; most backends will behave the same whether it is
 * supplied or not.  The only guaranteed way to get updated folder
 * counts is to both open the folder and invoke camel_folder_refresh_info() it.
 *
 * Returns: (nullable): a #CamelFolderInfo tree, or %NULL on error
 *
 * Since: 3.0
 **/
CamelFolderInfo *
camel_store_get_folder_info_sync (CamelStore *store,
                                  const gchar *top,
                                  CamelStoreGetFolderInfoFlags flags,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelStoreClass *class;
	CamelFolderInfo *info;
	gboolean allow_virtual;
	gboolean start_at_root;
	gboolean store_has_vtrash;
	gboolean store_has_vjunk;
	gchar *name;

	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);

	class = CAMEL_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_folder_info_sync != NULL, NULL);

	name = camel_service_get_name (CAMEL_SERVICE (store), TRUE);
	camel_operation_push_message (
		cancellable, _("Scanning folders in “%s”"), name);
	g_free (name);

	/* Recover from a dropped connection, unless we're offline. */
	if (!store_maybe_connect_sync (store, cancellable, error)) {
		camel_operation_pop_message (cancellable);
		return NULL;
	}

	info = class->get_folder_info_sync (
		store, top, flags, cancellable, error);
	if ((flags & CAMEL_STORE_FOLDER_INFO_SUBSCRIBED) == 0)
		CAMEL_CHECK_GERROR (
			store, get_folder_info_sync, info != NULL, error);

	/* For readability. */
	allow_virtual = ((flags & CAMEL_STORE_FOLDER_INFO_NO_VIRTUAL) == 0);
	start_at_root = (top == NULL || *top == '\0');
	store_has_vtrash = ((store->priv->flags & CAMEL_STORE_VTRASH) != 0);
	store_has_vjunk = ((store->priv->flags & CAMEL_STORE_VJUNK) != 0);

	if (info != NULL && start_at_root && allow_virtual) {
		if (store_has_vtrash) {
			/* Add the virtual Trash folder. */
			add_special_info (
				store,
				info,
				CAMEL_VTRASH_NAME,
				_("Trash"),
				FALSE,
				CAMEL_FOLDER_VIRTUAL |
				CAMEL_FOLDER_SYSTEM |
				CAMEL_FOLDER_VTRASH |
				CAMEL_FOLDER_TYPE_TRASH);
		}

		if (store_has_vjunk) {
			/* Add the virtual Junk folder. */
			add_special_info (
				store,
				info,
				CAMEL_VJUNK_NAME,
				_("Junk"),
				TRUE,
				CAMEL_FOLDER_VIRTUAL |
				CAMEL_FOLDER_SYSTEM |
				CAMEL_FOLDER_VTRASH |
				CAMEL_FOLDER_TYPE_JUNK);
		}

	} else if (info == NULL && !start_at_root && allow_virtual) {
		CamelFolderInfo *root_info = NULL;
		gboolean start_at_vtrash;
		gboolean start_at_vjunk;

		start_at_vtrash =
			store_has_vtrash &&
			g_str_equal (top, CAMEL_VTRASH_NAME);

		start_at_vjunk =
			store_has_vjunk &&
			g_str_equal (top, CAMEL_VJUNK_NAME);

		if (start_at_vtrash) {
			root_info = class->get_folder_info_sync (
				store, NULL,
				flags & (~CAMEL_STORE_FOLDER_INFO_RECURSIVE),
				cancellable, error);
			if (root_info != NULL)
				add_special_info (
					store,
					root_info,
					CAMEL_VTRASH_NAME,
					_("Trash"),
					FALSE,
					CAMEL_FOLDER_VIRTUAL |
					CAMEL_FOLDER_SYSTEM |
					CAMEL_FOLDER_VTRASH |
					CAMEL_FOLDER_TYPE_TRASH);

		} else if (start_at_vjunk) {
			root_info = class->get_folder_info_sync (
				store, NULL,
				flags & (~CAMEL_STORE_FOLDER_INFO_RECURSIVE),
				cancellable, error);
			if (root_info != NULL)
				add_special_info (
					store,
					root_info,
					CAMEL_VJUNK_NAME,
					_("Junk"),
					TRUE,
					CAMEL_FOLDER_VIRTUAL |
					CAMEL_FOLDER_SYSTEM |
					CAMEL_FOLDER_VTRASH |
					CAMEL_FOLDER_TYPE_JUNK);
		}

		if (root_info != NULL) {
			info = root_info->next;
			root_info->next = NULL;
			info->next = NULL;
			info->parent = NULL;

			camel_folder_info_free (root_info);
		}
	}

	camel_operation_pop_message (cancellable);

	if (camel_debug_start ("store:folder_info")) {
		const gchar *uid;

		uid = camel_service_get_uid (CAMEL_SERVICE (store));
		printf (
			"Get folder info(%p:%s, '%s') =\n",
			(gpointer) store, uid, top ? top : "<null>");
		dump_fi (info, 2);
		camel_debug_end ();
	}

	return info;
}

/* Helper for camel_store_get_folder_info() */
static void
store_get_folder_info_thread (GTask *task,
                              gpointer source_object,
                              gpointer task_data,
                              GCancellable *cancellable)
{
	CamelFolderInfo *folder_info;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	folder_info = camel_store_get_folder_info_sync (
		CAMEL_STORE (source_object),
		async_context->folder_name_1,
		async_context->flags,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_warn_if_fail (folder_info == NULL);
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (
			task, folder_info,
			(GDestroyNotify) camel_folder_info_free);
	}
}

/**
 * camel_store_get_folder_info:
 * @store: a #CamelStore
 * @top: (nullable): the name of the folder to start from
 * @flags: various CAMEL_STORE_FOLDER_INFO_* flags to control behavior
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously fetches information about the folder structure of @store,
 * starting with @top.  For details of the behavior, see
 * camel_store_get_folder_info_sync().
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_store_get_folder_info_finish() to get the result of
 * the operation.
 *
 * Since: 3.0
 **/
void
camel_store_get_folder_info (CamelStore *store,
                             const gchar *top,
                             CamelStoreGetFolderInfoFlags flags,
                             gint io_priority,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_STORE (store));

	async_context = g_slice_new0 (AsyncContext);
	async_context->folder_name_1 = g_strdup (top);
	async_context->flags = flags;

	task = g_task_new (store, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_store_get_folder_info);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, store_get_folder_info_thread);

	g_object_unref (task);
}

/**
 * camel_store_get_folder_info_finish:
 * @store: a #CamelStore
 * @result: a #GAsyncResult
 * @error: (nullable): return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_store_get_folder_info().
 * The returned #CamelFolderInfo tree should be freed with
 * camel_folder_info_free().
 *
 * Returns: (nullable): a #CamelFolderInfo tree, or %NULL on error
 *
 * Since: 3.0
 **/
CamelFolderInfo *
camel_store_get_folder_info_finish (CamelStore *store,
                                    GAsyncResult *result,
                                    GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);
	g_return_val_if_fail (g_task_is_valid (result, store), NULL);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_store_get_folder_info), NULL);

	return g_task_propagate_pointer (G_TASK (result), error);
}

/**
 * camel_store_get_inbox_folder_sync:
 * @store: a #CamelStore
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets the folder in @store into which new mail is delivered.
 *
 * Returns: (transfer full) (nullable): the inbox folder for @store, or %NULL on
 * error or if no such folder exists
 *
 * Since: 3.0
 **/
CamelFolder *
camel_store_get_inbox_folder_sync (CamelStore *store,
                                   GCancellable *cancellable,
                                   GError **error)
{
	CamelStoreClass *class;
	CamelFolder *folder;

	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);

	class = CAMEL_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_inbox_folder_sync != NULL, NULL);

	folder = class->get_inbox_folder_sync (store, cancellable, error);
	CAMEL_CHECK_GERROR (
		store, get_inbox_folder_sync, folder != NULL, error);

	return folder;
}

/* Helper for camel_store_get_inbox_folder() */
static void
store_get_inbox_folder_thread (GTask *task,
                               gpointer source_object,
                               gpointer task_data,
                               GCancellable *cancellable)
{
	CamelFolder *folder;
	GError *local_error = NULL;

	folder = camel_store_get_inbox_folder_sync (
		CAMEL_STORE (source_object),
		cancellable, &local_error);

	if (local_error != NULL) {
		g_warn_if_fail (folder == NULL);
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (
			task, folder,
			(GDestroyNotify) g_object_unref);
	}
}

/**
 * camel_store_get_inbox_folder:
 * @store: a #CamelStore
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously gets the folder in @store into which new mail is delivered.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_store_get_inbox_folder_finish() to get the result of
 * the operation.
 *
 * Since: 3.0
 **/
void
camel_store_get_inbox_folder (CamelStore *store,
                              gint io_priority,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GTask *task;

	g_return_if_fail (CAMEL_IS_STORE (store));

	task = g_task_new (store, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_store_get_inbox_folder);
	g_task_set_priority (task, io_priority);

	g_task_run_in_thread (task, store_get_inbox_folder_thread);

	g_object_unref (task);
}

/**
 * camel_store_get_inbox_folder_finish:
 * @store: a #CamelStore
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_store_get_inbox_folder().
 *
 * Returns: (transfer full) (nullable): the inbox folder for @store, or %NULL on
 * error or if no such folder exists
 *
 * Since: 3.0
 **/
CamelFolder *
camel_store_get_inbox_folder_finish (CamelStore *store,
                                     GAsyncResult *result,
                                     GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);
	g_return_val_if_fail (g_task_is_valid (result, store), NULL);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_store_get_inbox_folder), NULL);

	return g_task_propagate_pointer (G_TASK (result), error);
}

/**
 * camel_store_get_junk_folder_sync:
 * @store: a #CamelStore
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets the folder in @store into which junk is delivered.
 *
 * Returns: (transfer full) (nullable): the junk folder for @store, or %NULL on
 * error or if no such folder exists
 *
 * Since: 3.0
 **/
CamelFolder *
camel_store_get_junk_folder_sync (CamelStore *store,
                                  GCancellable *cancellable,
                                  GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);

	if ((store->priv->flags & CAMEL_STORE_VJUNK) == 0) {
		CamelStoreClass *class;
		CamelFolder *folder;

		class = CAMEL_STORE_GET_CLASS (store);
		g_return_val_if_fail (class != NULL, NULL);
		g_return_val_if_fail (class->get_junk_folder_sync != NULL, NULL);

		folder = class->get_junk_folder_sync (store, cancellable, error);
		CAMEL_CHECK_GERROR (
			store, get_junk_folder_sync, folder != NULL, error);

		return folder;
	}

	return camel_store_get_folder_sync (
		store, CAMEL_VJUNK_NAME, 0, cancellable, error);
}

/* Helper for camel_store_get_junk_folder() */
static void
store_get_junk_folder_thread (GTask *task,
                              gpointer source_object,
                              gpointer task_data,
                              GCancellable *cancellable)
{
	CamelFolder *folder;
	GError *local_error = NULL;

	folder = camel_store_get_junk_folder_sync (
		CAMEL_STORE (source_object),
		cancellable, &local_error);

	if (local_error != NULL) {
		g_warn_if_fail (folder == NULL);
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (
			task, folder,
			(GDestroyNotify) g_object_unref);
	}
}

/**
 * camel_store_get_junk_folder:
 * @store: a #CamelStore
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously gets the folder in @store into which junk is delivered.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_store_get_junk_folder_finish() to get the result of
 * the operation.
 *
 * Since: 3.0
 **/
void
camel_store_get_junk_folder (CamelStore *store,
                             gint io_priority,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data)
{
	GTask *task;

	g_return_if_fail (CAMEL_IS_STORE (store));

	task = g_task_new (store, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_store_get_junk_folder);
	g_task_set_priority (task, io_priority);

	g_task_run_in_thread (task, store_get_junk_folder_thread);

	g_object_unref (task);
}

/**
 * camel_store_get_junk_folder_finish:
 * @store: a #CamelStore
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_store_get_junk_folder().
 *
 * Returns: (transfer full) (nullable): the junk folder for @store, or %NULL on 
 * error or if no such folder exists
 *
 * Since: 3.0
 **/
CamelFolder *
camel_store_get_junk_folder_finish (CamelStore *store,
                                    GAsyncResult *result,
                                    GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);
	g_return_val_if_fail (g_task_is_valid (result, store), NULL);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_store_get_junk_folder), NULL);

	return g_task_propagate_pointer (G_TASK (result), error);
}

/**
 * camel_store_get_trash_folder_sync:
 * @store: a #CamelStore
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Gets the folder in @store into which trash is delivered.
 *
 * Returns: (transfer full) (nullable): the trash folder for @store, or %NULL on
 * error or if no such folder exists
 *
 * Since: 3.0
 **/
CamelFolder *
camel_store_get_trash_folder_sync (CamelStore *store,
                                   GCancellable *cancellable,
                                   GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);

	if ((store->priv->flags & CAMEL_STORE_VTRASH) == 0) {
		CamelStoreClass *class;
		CamelFolder *folder;

		class = CAMEL_STORE_GET_CLASS (store);
		g_return_val_if_fail (class != NULL, NULL);
		g_return_val_if_fail (class->get_trash_folder_sync != NULL, NULL);

		folder = class->get_trash_folder_sync (
			store, cancellable, error);
		CAMEL_CHECK_GERROR (
			store, get_trash_folder_sync, folder != NULL, error);

		return folder;
	}

	return camel_store_get_folder_sync (
		store, CAMEL_VTRASH_NAME, 0, cancellable, error);
}

/* Helper for camel_store_get_trash_folder() */
static void
store_get_trash_folder_thread (GTask *task,
                               gpointer source_object,
                               gpointer task_data,
                               GCancellable *cancellable)
{
	CamelFolder *folder;
	GError *local_error = NULL;

	folder = camel_store_get_trash_folder_sync (
		CAMEL_STORE (source_object),
		cancellable, &local_error);

	if (local_error != NULL) {
		g_warn_if_fail (folder == NULL);
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (
			task, folder,
			(GDestroyNotify) g_object_unref);
	}
}

/**
 * camel_store_get_trash_folder:
 * @store: a #CamelStore
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously gets the folder in @store into which trash is delivered.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_store_get_trash_folder_finish() to get the result of
 * the operation.
 *
 * Since: 3.0
 **/
void
camel_store_get_trash_folder (CamelStore *store,
                              gint io_priority,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GTask *task;

	g_return_if_fail (CAMEL_IS_STORE (store));

	task = g_task_new (store, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_store_get_trash_folder);
	g_task_set_priority (task, io_priority);

	g_task_run_in_thread (task, store_get_trash_folder_thread);

	g_object_unref (task);
}

/**
 * camel_store_get_trash_folder_finish:
 * @store: a #CamelStore
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_store_get_trash_folder().
 *
 * Returns: (transfer full) (nullable): the trash folder for @store, or %NULL on
 * error or if no such folder exists
 *
 * Since: 3.0
 **/
CamelFolder *
camel_store_get_trash_folder_finish (CamelStore *store,
                                     GAsyncResult *result,
                                     GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);
	g_return_val_if_fail (g_task_is_valid (result, store), NULL);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_store_get_trash_folder), NULL);

	return g_task_propagate_pointer (G_TASK (result), error);
}

/**
 * camel_store_create_folder_sync:
 * @store: a #CamelStore
 * @parent_name: (nullable): name of the new folder's parent, or %NULL
 * @folder_name: name of the folder to create
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new folder as a child of an existing folder.
 * @parent_name can be %NULL to create a new top-level folder.
 * The returned #CamelFolderInfo struct should be freed with
 * camel_folder_info_free().
 *
 * Returns: (nullable): info about the created folder, or %NULL on error
 *
 * Since: 3.0
 **/
CamelFolderInfo *
camel_store_create_folder_sync (CamelStore *store,
                                const gchar *parent_name,
                                const gchar *folder_name,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelAsyncClosure *closure;
	GAsyncResult *result;
	CamelFolderInfo *folder_info;

	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);
	g_return_val_if_fail (folder_name != NULL, NULL);

	closure = camel_async_closure_new ();

	camel_store_create_folder (
		store, parent_name, folder_name,
		G_PRIORITY_DEFAULT, cancellable,
		camel_async_closure_callback, closure);

	result = camel_async_closure_wait (closure);

	folder_info = camel_store_create_folder_finish (store, result, error);

	camel_async_closure_free (closure);

	return folder_info;
}

/* Helper for camel_store_create_folder() */
static void
store_create_folder_thread (GTask *task,
                            gpointer source_object,
                            gpointer task_data,
                            GCancellable *cancellable)
{
	CamelStore *store;
	CamelStoreClass *class;
	AsyncContext *async_context;
	CamelFolderInfo *folder_info;
	const gchar *parent_name;
	const gchar *folder_name;
	GError *local_error = NULL;

	store = CAMEL_STORE (source_object);
	async_context = (AsyncContext *) task_data;

	parent_name = async_context->folder_name_1;
	folder_name = async_context->folder_name_2;

	class = CAMEL_STORE_GET_CLASS (store);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->create_folder_sync != NULL);

	if (parent_name == NULL || *parent_name == '\0') {
		gboolean reserved_vfolder_name;

		reserved_vfolder_name =
			((store->priv->flags & CAMEL_STORE_VJUNK) &&
			g_str_equal (folder_name, CAMEL_VJUNK_NAME)) ||
			((store->priv->flags & CAMEL_STORE_VTRASH) &&
			g_str_equal (folder_name, CAMEL_VTRASH_NAME));

		if (reserved_vfolder_name) {
			g_task_return_new_error (
				task, CAMEL_STORE_ERROR,
				CAMEL_STORE_ERROR_INVALID,
				_("Cannot create folder: %s: folder exists"),
				folder_name);
			return;
		}
	}

	camel_operation_push_message (
		cancellable, _("Creating folder “%s”"), folder_name);

	folder_info = class->create_folder_sync (
		store, parent_name, folder_name, cancellable, &local_error);
	CAMEL_CHECK_LOCAL_GERROR (
		store, create_folder_sync, folder_info != NULL, local_error);

	camel_operation_pop_message (cancellable);

	if (local_error != NULL) {
		g_warn_if_fail (folder_info == NULL);
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (
			task, folder_info,
			(GDestroyNotify) camel_folder_info_free);
	}
}

/**
 * camel_store_create_folder:
 * @store: a #CamelStore
 * @parent_name: (nullable): name of the new folder's parent, or %NULL
 * @folder_name: name of the folder to create
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously creates a new folder as a child of an existing folder.
 * @parent_name can be %NULL to create a new top-level folder.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_store_create_folder_finish() to get the result of the operation.
 *
 * Since: 3.0
 **/
void
camel_store_create_folder (CamelStore *store,
                           const gchar *parent_name,
                           const gchar *folder_name,
                           gint io_priority,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
	GTask *task;
	CamelService *service;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_STORE (store));
	g_return_if_fail (folder_name != NULL);

	service = CAMEL_SERVICE (store);

	async_context = g_slice_new0 (AsyncContext);
	async_context->folder_name_1 = g_strdup (parent_name);
	async_context->folder_name_2 = g_strdup (folder_name);

	task = g_task_new (store, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_store_create_folder);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	camel_service_queue_task (
		service, task, store_create_folder_thread);

	g_object_unref (task);
}

/**
 * camel_store_create_folder_finish:
 * @store: a #CamelStore
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_store_create_folder().
 * The returned #CamelFolderInfo struct should be freed with
 * camel_folder_info_free().
 *
 * Returns: (nullable): info about the created folder, or %NULL on error
 *
 * Since: 3.0
 **/
CamelFolderInfo *
camel_store_create_folder_finish (CamelStore *store,
                                  GAsyncResult *result,
                                  GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), NULL);
	g_return_val_if_fail (g_task_is_valid (result, store), NULL);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_store_create_folder), NULL);

	return g_task_propagate_pointer (G_TASK (result), error);
}

/**
 * camel_store_delete_folder_sync:
 * @store: a #CamelStore
 * @folder_name: name of the folder to delete
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Deletes the folder described by @folder_name.  The folder must be empty.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.0
 **/
gboolean
camel_store_delete_folder_sync (CamelStore *store,
                                const gchar *folder_name,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_STORE (store), FALSE);
	g_return_val_if_fail (folder_name != NULL, FALSE);

	closure = camel_async_closure_new ();

	camel_store_delete_folder (
		store, folder_name,
		G_PRIORITY_DEFAULT, cancellable,
		camel_async_closure_callback, closure);

	result = camel_async_closure_wait (closure);

	success = camel_store_delete_folder_finish (store, result, error);

	camel_async_closure_free (closure);

	return success;
}

/* Helper for camel_store_delete_folder() */
static void
store_delete_folder_thread (GTask *task,
                            gpointer source_object,
                            gpointer task_data,
                            GCancellable *cancellable)
{
	CamelStore *store;
	CamelStoreClass *class;
	AsyncContext *async_context;
	const gchar *folder_name;
	gboolean reserved_vfolder_name;
	gboolean success;
	GError *local_error = NULL;

	store = CAMEL_STORE (source_object);
	async_context = (AsyncContext *) task_data;

	folder_name = async_context->folder_name_1;

	class = CAMEL_STORE_GET_CLASS (store);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->delete_folder_sync != NULL);

	reserved_vfolder_name =
		((store->priv->flags & CAMEL_STORE_VJUNK) &&
		g_str_equal (folder_name, CAMEL_VJUNK_NAME)) ||
		((store->priv->flags & CAMEL_STORE_VTRASH) &&
		g_str_equal (folder_name, CAMEL_VTRASH_NAME));

	if (reserved_vfolder_name) {
		g_task_return_new_error (
			task, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Cannot delete folder: %s: Invalid operation"),
			folder_name);
		return;
	}

	success = class->delete_folder_sync (
		store, folder_name, cancellable, &local_error);
	CAMEL_CHECK_LOCAL_GERROR (
		store, delete_folder_sync, success, local_error);

	/* ignore 'no such table' errors */
	if (local_error != NULL &&
	    g_ascii_strncasecmp (local_error->message, "no such table", 13) == 0)
		g_clear_error (&local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		camel_store_delete_cached_folder (store, folder_name);
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_store_delete_folder:
 * @store: a #CamelStore
 * @folder_name: name of the folder to delete
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously deletes the folder described by @folder_name.  The
 * folder must be empty.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_store_delete_folder_finish() to get the result of the operation.
 *
 * Since: 3.0
 **/
void
camel_store_delete_folder (CamelStore *store,
                           const gchar *folder_name,
                           gint io_priority,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
	GTask *task;
	CamelService *service;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_STORE (store));
	g_return_if_fail (folder_name != NULL);

	service = CAMEL_SERVICE (store);

	async_context = g_slice_new0 (AsyncContext);
	async_context->folder_name_1 = g_strdup (folder_name);

	task = g_task_new (store, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_store_delete_folder);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	camel_service_queue_task (
		service, task, store_delete_folder_thread);

	g_object_unref (task);
}

/**
 * camel_store_delete_folder_finish:
 * @store: a #CamelStore
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_store_delete_folder().
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_store_delete_folder_finish (CamelStore *store,
                                  GAsyncResult *result,
                                  GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, store), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_store_delete_folder), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_store_rename_folder_sync:
 * @store: a #CamelStore
 * @old_name: the current name of the folder
 * @new_name: the new name of the folder
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Renames the folder described by @old_name to @new_name.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_store_rename_folder_sync (CamelStore *store,
                                const gchar *old_name,
                                const gchar *new_name,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_STORE (store), FALSE);
	g_return_val_if_fail (old_name != NULL, FALSE);
	g_return_val_if_fail (new_name != NULL, FALSE);

	closure = camel_async_closure_new ();

	camel_store_rename_folder (
		store, old_name, new_name,
		G_PRIORITY_DEFAULT, cancellable,
		camel_async_closure_callback, closure);

	result = camel_async_closure_wait (closure);

	success = camel_store_rename_folder_finish (store, result, error);

	camel_async_closure_free (closure);

	return success;
}

/* Helper for camel_store_rename_folder() */
static void
store_rename_folder_thread (GTask *task,
                            gpointer source_object,
                            gpointer task_data,
                            GCancellable *cancellable)
{
	CamelStore *store;
	CamelStoreClass *class;
	CamelFolder *folder;
	GPtrArray *folders;
	const gchar *old_name;
	const gchar *new_name;
	gboolean reserved_vfolder_name;
	gboolean success;
	gsize old_name_len;
	guint ii;
	AsyncContext *async_context;
	GError *local_error = NULL;

	store = CAMEL_STORE (source_object);
	async_context = (AsyncContext *) task_data;

	old_name = async_context->folder_name_1;
	new_name = async_context->folder_name_2;

	class = CAMEL_STORE_GET_CLASS (store);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->rename_folder_sync != NULL);

	if (g_str_equal (old_name, new_name)) {
		g_task_return_boolean (task, TRUE);
		return;
	}

	reserved_vfolder_name =
		((store->priv->flags & CAMEL_STORE_VJUNK) &&
		g_str_equal (old_name, CAMEL_VJUNK_NAME)) ||
		((store->priv->flags & CAMEL_STORE_VTRASH) &&
		g_str_equal (old_name, CAMEL_VTRASH_NAME));

	if (reserved_vfolder_name) {
		g_task_return_new_error (
			task, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Cannot rename folder: %s: Invalid operation"),
			old_name);
		return;
	}

	old_name_len = strlen (old_name);

	/* If the folder is open (or any subfolders of the open folder)
	 * We need to rename them atomically with renaming the actual
	 * folder path. */
	folders = store->priv->folders ? camel_object_bag_list (store->priv->folders) : g_ptr_array_new ();
	for (ii = 0; ii < folders->len; ii++) {
		const gchar *full_name;
		gsize full_name_len;

		folder = folders->pdata[ii];
		full_name = camel_folder_get_full_name (folder);
		full_name_len = strlen (full_name);

		if ((full_name_len == old_name_len &&
		     strcmp (full_name, old_name) == 0)
		    || ((full_name_len > old_name_len)
			&& strncmp (full_name, old_name, old_name_len) == 0
			&& full_name[old_name_len] == '/')) {
			camel_folder_lock (folder);
		} else {
			g_ptr_array_remove_index_fast (folders, ii);
			ii--;
			g_object_unref (folder);
		}
	}

	/* Now try the real rename (will emit renamed signal) */
	success = class->rename_folder_sync (
		store, old_name, new_name, cancellable, &local_error);
	CAMEL_CHECK_LOCAL_GERROR (
		store, rename_folder_sync, success, local_error);

	/* If it worked, update all open folders/unlock them */
	if (success) {
		CamelStoreGetFolderInfoFlags flags;
		CamelFolderInfo *folder_info;

		flags = CAMEL_STORE_FOLDER_INFO_RECURSIVE;

		for (ii = 0; ii < folders->len; ii++) {
			const gchar *full_name;
			gchar *new;

			folder = folders->pdata[ii];
			full_name = camel_folder_get_full_name (folder);

			new = g_strdup_printf ("%s%s", new_name, full_name + strlen (old_name));
			if (store->priv->folders)
				camel_object_bag_rekey (store->priv->folders, folder, new);
			camel_folder_rename (folder, new);
			g_free (new);

			camel_folder_unlock (folder);
			g_object_unref (folder);
		}

		/* Emit renamed signal */
		if (CAMEL_IS_SUBSCRIBABLE (store))
			flags |= CAMEL_STORE_FOLDER_INFO_SUBSCRIBED;

		folder_info = class->get_folder_info_sync (
			store, new_name, flags, cancellable, &local_error);
		CAMEL_CHECK_LOCAL_GERROR (
			store, get_folder_info,
			folder_info != NULL, local_error);

		if (folder_info != NULL) {
			camel_store_folder_renamed (store, old_name, folder_info);
			camel_folder_info_free (folder_info);
		}
	} else {
		/* Failed, just unlock our folders for re-use */
		for (ii = 0; ii < folders->len; ii++) {
			folder = folders->pdata[ii];
			camel_folder_unlock (folder);
			g_object_unref (folder);
		}
	}

	g_ptr_array_free (folders, TRUE);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_store_rename_folder:
 * @store: a #CamelStore
 * @old_name: the current name of the folder
 * @new_name: the new name of the folder
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously renames the folder described by @old_name to @new_name.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_store_rename_folder_finish() to get the result of the operation.
 *
 * Since: 3.0
 **/
void
camel_store_rename_folder (CamelStore *store,
                           const gchar *old_name,
                           const gchar *new_name,
                           gint io_priority,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
	GTask *task;
	CamelService *service;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_STORE (store));
	g_return_if_fail (old_name != NULL);
	g_return_if_fail (new_name != NULL);

	service = CAMEL_SERVICE (store);

	async_context = g_slice_new0 (AsyncContext);
	async_context->folder_name_1 = g_strdup (old_name);
	async_context->folder_name_2 = g_strdup (new_name);

	task = g_task_new (store, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_store_rename_folder);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	camel_service_queue_task (
		service, task, store_rename_folder_thread);

	g_object_unref (task);
}

/**
 * camel_store_rename_folder_finish:
 * @store: a #CamelStore
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_store_rename_folder().
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_store_rename_folder_finish (CamelStore *store,
                                  GAsyncResult *result,
                                  GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, store), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_store_rename_folder), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_store_synchronize_sync:
 * @store: a #CamelStore
 * @expunge: whether to expunge after synchronizing
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Synchronizes any changes that have been made to @store and its folders
 * with the real store.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_store_synchronize_sync (CamelStore *store,
                              gboolean expunge,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelStoreClass *class;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_STORE (store), FALSE);

	class = CAMEL_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->synchronize_sync != NULL, FALSE);

	success = class->synchronize_sync (store, expunge, cancellable, error);
	CAMEL_CHECK_GERROR (store, synchronize_sync, success, error);

	return success;
}

/* Helper for camel_store_synchronize() */
static void
store_synchronize_thread (GTask *task,
                          gpointer source_object,
                          gpointer task_data,
                          GCancellable *cancellable)
{
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	success = camel_store_synchronize_sync (
		CAMEL_STORE (source_object),
		async_context->expunge,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_store_synchronize:
 * @store: a #CamelStore
 * @expunge: whether to expunge after synchronizing
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Synchronizes any changes that have been made to @store and its folders
 * with the real store asynchronously.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_store_synchronize_finish() to get the result of the operation.
 *
 * Since: 3.0
 **/
void
camel_store_synchronize (CamelStore *store,
                         gboolean expunge,
                         gint io_priority,
                         GCancellable *cancellable,
                         GAsyncReadyCallback callback,
                         gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_STORE (store));

	async_context = g_slice_new0 (AsyncContext);
	async_context->expunge = expunge;

	task = g_task_new (store, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_store_synchronize);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, store_synchronize_thread);

	g_object_unref (task);
}

/**
 * camel_store_synchronize_finish:
 * @store: a #CamelStore
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_store_synchronize().
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_store_synchronize_finish (CamelStore *store,
                                GAsyncResult *result,
                                GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, store), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_store_synchronize), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_store_initial_setup_sync:
 * @store: a #CamelStore
 * @out_save_setup: (out) (transfer container) (element-type utf8 utf8): setup values to save
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Runs initial setup for the @store. It's meant to preset some
 * values the first time the account connects to the server after
 * it had been created. The function should return %TRUE even if
 * it didn't populate anything. The default implementation does
 * just that.
 *
 * The save_setup result, if not %NULL, should be freed using
 * g_hash_table_destroy(). It's not an error to have it %NULL,
 * it only means the @store doesn't have anything to save.
 * Both the key and the value in the hash are newly allocated
 * UTF-8 strings, owned by the hash table.
 *
 * The @store advertises support of this function by including
 * CAMEL_STORE_SUPPORTS_INITIAL_SETUP in CamelStore::flags.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.20
 **/
gboolean
camel_store_initial_setup_sync (CamelStore *store,
				GHashTable **out_save_setup,
				GCancellable *cancellable,
				GError **error)
{
	GHashTable *save_setup;
	CamelStoreClass *class;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_STORE (store), FALSE);
	g_return_val_if_fail (out_save_setup != NULL, FALSE);

	*out_save_setup = NULL;

	class = CAMEL_STORE_GET_CLASS (store);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->initial_setup_sync != NULL, FALSE);

	save_setup = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);

	success = class->initial_setup_sync (store, save_setup, cancellable, error);

	if (!success || !g_hash_table_size (save_setup)) {
		g_hash_table_destroy (save_setup);
		save_setup = NULL;
	}

	CAMEL_CHECK_GERROR (store, initial_setup_sync, success, error);

	*out_save_setup = save_setup;

	return success;
}

static void
store_initial_setup_thread (GTask *task,
			    gpointer source_object,
			    gpointer task_data,
			    GCancellable *cancellable)
{
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	success = camel_store_initial_setup_sync (
		CAMEL_STORE (source_object),
		&async_context->save_setup,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_store_initial_setup:
 * @store: a #CamelStore
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Runs initial setup for the @store asynchronously.
 *
 * When the operation is finished, @callback will be called. You can then
 * call camel_store_initial_setup_finish() to get the result of the operation.
 *
 * The @store advertises support of this function by including
 * CAMEL_STORE_SUPPORTS_INITIAL_SETUP in CamelStore::flags.
 *
 * Since: 3.20
 **/
void
camel_store_initial_setup (CamelStore *store,
			   gint io_priority,
			   GCancellable *cancellable,
			   GAsyncReadyCallback callback,
			   gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_STORE (store));

	async_context = g_slice_new0 (AsyncContext);

	task = g_task_new (store, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_store_initial_setup);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, store_initial_setup_thread);

	g_object_unref (task);
}

/**
 * camel_store_initial_setup_finish:
 * @store: a #CamelStore
 * @result: a #GAsyncResult
 * @out_save_setup: (out) (transfer container) (element-type utf8 utf8): setup values to save
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_store_initial_setup().
 *
 * The save_setup result, if not %NULL, should be freed using
 * g_hash_table_destroy(). It's not an error to have it %NULL,
 * it only means the @store doesn't have anything to save.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.20
 **/
gboolean
camel_store_initial_setup_finish (CamelStore *store,
				  GAsyncResult *result,
				  GHashTable **out_save_setup,
				  GError **error)
{
	AsyncContext *async_context;

	g_return_val_if_fail (CAMEL_IS_STORE (store), FALSE);
	g_return_val_if_fail (out_save_setup != NULL, FALSE);
	g_return_val_if_fail (g_task_is_valid (result, store), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_store_initial_setup), FALSE);

	async_context = g_task_get_task_data (G_TASK (result));
	*out_save_setup = async_context->save_setup;
	async_context->save_setup = NULL;

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_store_maybe_run_db_maintenance:
 * @store: a #CamelStore instance
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Checks the state of the current CamelDB used for the @store and eventually
 * runs maintenance routines on it.
 *
 * Returns: Whether succeeded.
 *
 * Since: 3.16
 **/
gboolean
camel_store_maybe_run_db_maintenance (CamelStore *store,
				      GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STORE (store), FALSE);

	if (g_atomic_int_get (&store->priv->maintenance_lock) > 0)
		return TRUE;

	if (!store->priv->cdb)
		return TRUE;

	return camel_db_maybe_run_maintenance (store->priv->cdb, error);
}

/**
 * camel_store_delete_cached_folder:
 * @store: a #CamelStore
 * @folder_name: a folder full name to delete from the cache
 *
 * Deletes local data for the given @folder_name. The folder should
 * be part of the opened folders.
 *
 * It doesn't delete the folder in the store (server) as such.
 * Use camel_store_delete_folder(), or its synchronous variant,
 * if you want to do that instead.
 *
 * Since: 3.24
 **/
void
camel_store_delete_cached_folder (CamelStore *store,
				  const gchar *folder_name)
{
	CamelFolder *folder;
	CamelVeeFolder *vfolder;

	if (store->priv->folders == NULL)
		return;

	folder = camel_object_bag_get (store->priv->folders, folder_name);
	if (folder == NULL)
		return;

	if (store->priv->flags & CAMEL_STORE_VTRASH) {
		vfolder = camel_object_bag_get (
			store->priv->folders, CAMEL_VTRASH_NAME);
		if (vfolder != NULL) {
			camel_vee_folder_remove_folder (vfolder, folder, NULL);
			g_object_unref (vfolder);
		}
	}

	if (store->priv->flags & CAMEL_STORE_VJUNK) {
		vfolder = camel_object_bag_get (
			store->priv->folders, CAMEL_VJUNK_NAME);
		if (vfolder != NULL) {
			camel_vee_folder_remove_folder (vfolder, folder, NULL);
			g_object_unref (vfolder);
		}
	}

	camel_folder_delete (folder);

	camel_object_bag_remove (store->priv->folders, folder);
	g_object_unref (folder);
}
