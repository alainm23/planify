/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-imap-store.c : class for a imap store
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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <sys/types.h>
#ifdef _WIN32
#include <winsock2.h>
#else
#include <sys/socket.h>
#include <netinet/in.h>
#endif
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include "camel-imapx-conn-manager.h"
#include "camel-imapx-folder.h"
#include "camel-imapx-job.h"
#include "camel-imapx-server.h"
#include "camel-imapx-settings.h"
#include "camel-imapx-store.h"
#include "camel-imapx-summary.h"
#include "camel-imapx-utils.h"

/* Specified in RFC 2060 section 2.1 */
#define IMAP_PORT 143
#define IMAPS_PORT 993

#define FINFO_REFRESH_INTERVAL 60

#define CAMEL_IMAPX_STORE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_IMAPX_STORE, CamelIMAPXStorePrivate))

#define e(...) camel_imapx_debug(extra, __VA_ARGS__)

struct _CamelIMAPXStorePrivate {
	CamelIMAPXConnManager *conn_man;

	CamelIMAPXServer *connecting_server;
	gboolean is_concurrent_connection;

	GMutex server_lock;

	GHashTable *quota_info;
	GMutex quota_info_lock;

	GMutex settings_lock;
	CamelSettings *settings;
	gulong settings_notify_handler_id;

	/* Used for synchronizing get_folder_info_sync(). */
	GMutex get_finfo_lock;
	time_t last_refresh_time;
	volatile gint syncing_folders;

	CamelIMAPXNamespaceResponse *namespaces;
	GMutex namespaces_lock;

	GHashTable *mailboxes;
	GMutex mailboxes_lock;

	gboolean bodystructure_enabled;
};

enum {
	PROP_0,
	PROP_CONNECTABLE,
	PROP_HOST_REACHABLE,
	PROP_CONN_MANAGER
};

enum {
	MAILBOX_CREATED,
	MAILBOX_RENAMED,
	MAILBOX_UPDATED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

static GInitableIface *parent_initable_interface;

/* Forward Declarations */
static void camel_imapx_store_initable_init (GInitableIface *iface);
static void camel_network_service_init (CamelNetworkServiceInterface *iface);
static void camel_subscribable_init (CamelSubscribableInterface *iface);

G_DEFINE_TYPE_WITH_CODE (
	CamelIMAPXStore,
	camel_imapx_store,
	CAMEL_TYPE_OFFLINE_STORE,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		camel_imapx_store_initable_init)
	G_IMPLEMENT_INTERFACE (
		CAMEL_TYPE_NETWORK_SERVICE,
		camel_network_service_init)
	G_IMPLEMENT_INTERFACE (
		CAMEL_TYPE_SUBSCRIBABLE,
		camel_subscribable_init))

static guint
imapx_name_hash (gconstpointer key)
{
	const gchar *mailbox = key;

	if (camel_imapx_mailbox_is_inbox (mailbox))
		mailbox = "INBOX";

	return g_str_hash (mailbox);
}

static gboolean
imapx_name_equal (gconstpointer a,
                  gconstpointer b)
{
	const gchar *mailbox_a = a;
	const gchar *mailbox_b = b;

	if (camel_imapx_mailbox_is_inbox (mailbox_a))
		mailbox_a = "INBOX";

	if (camel_imapx_mailbox_is_inbox (mailbox_b))
		mailbox_b = "INBOX";

	return g_str_equal (mailbox_a, mailbox_b);
}

static void
imapx_store_update_store_flags (CamelStore *store)
{
	CamelService *service;
	CamelSettings *settings;
	CamelIMAPXSettings *imapx_settings;
	guint32 store_flags;

	service = CAMEL_SERVICE (store);
	settings = camel_service_ref_settings (service);
	imapx_settings = CAMEL_IMAPX_SETTINGS (settings);
	store_flags = camel_store_get_flags (store);

	if (camel_imapx_settings_get_use_real_junk_path (imapx_settings)) {
		store_flags &= ~CAMEL_STORE_VJUNK;
		store_flags |= CAMEL_STORE_REAL_JUNK_FOLDER;
	} else {
		store_flags |= CAMEL_STORE_VJUNK;
		store_flags &= ~CAMEL_STORE_REAL_JUNK_FOLDER;
	}

	if (camel_imapx_settings_get_use_real_trash_path (imapx_settings))
		store_flags &= ~CAMEL_STORE_VTRASH;
	else
		store_flags |= CAMEL_STORE_VTRASH;

	camel_store_set_flags (store, store_flags);

	g_object_unref (settings);
}

static void
imapx_store_update_folder_flags (CamelStore *store)
{
	CamelSettings *settings;
	gboolean filter_all;
	gboolean filter_inbox;
	gboolean filter_junk;
	gboolean filter_junk_inbox;
	GPtrArray *folders;
	gint ii;

	g_return_if_fail (CAMEL_IS_IMAPX_STORE (store));

	settings = camel_service_ref_settings (CAMEL_SERVICE (store));

	g_object_get (
		settings,
		"filter-all", &filter_all,
		"filter-inbox", &filter_inbox,
		"filter-junk", &filter_junk,
		"filter-junk-inbox", &filter_junk_inbox,
		NULL);

	g_object_unref (settings);

	folders = camel_store_dup_opened_folders (store);
	if (!folders)
		return;

	for (ii = 0; ii < folders->len; ii++) {
		CamelFolder *folder = g_ptr_array_index (folders, ii);
		guint32 flags;

		if (!CAMEL_IS_IMAPX_FOLDER (folder))
			continue;

		flags = camel_folder_get_flags (folder) & (~(CAMEL_FOLDER_FILTER_RECENT | CAMEL_FOLDER_FILTER_JUNK));

		if (filter_all)
			flags |= CAMEL_FOLDER_FILTER_RECENT;

		if (camel_imapx_mailbox_is_inbox (camel_folder_get_full_name (folder))) {
			if (filter_inbox)
				flags |= CAMEL_FOLDER_FILTER_RECENT;

			if (filter_junk)
				flags |= CAMEL_FOLDER_FILTER_JUNK;
		} else {
			gboolean apply_filters = FALSE;

			if (filter_junk && !filter_junk_inbox)
				flags |= CAMEL_FOLDER_FILTER_JUNK;

			g_object_get (G_OBJECT (folder), "apply-filters", &apply_filters, NULL);

			if (apply_filters)
				flags |= CAMEL_FOLDER_FILTER_RECENT;
		}

		camel_folder_set_flags (folder, flags);
	}

	g_ptr_array_foreach (folders, (GFunc) g_object_unref, NULL);
	g_ptr_array_free (folders, TRUE);
}

static void
imapx_store_update_folder_cache_expire (CamelStore *store)
{
	CamelSettings *settings;
	gboolean offline_limit_by_age = FALSE;
	CamelTimeUnit offline_limit_unit;
	gint offline_limit_value;
	time_t when = (time_t) 0;
	GPtrArray *folders;
	gint ii;

	g_return_if_fail (CAMEL_IS_IMAPX_STORE (store));

	settings = camel_service_ref_settings (CAMEL_SERVICE (store));

	g_object_get (
		settings,
		"limit-by-age", &offline_limit_by_age,
		"limit-unit", &offline_limit_unit,
		"limit-value", &offline_limit_value,
		NULL);

	g_object_unref (settings);

	folders = camel_store_dup_opened_folders (store);
	if (!folders)
		return;

	if (offline_limit_by_age)
		when = camel_time_value_apply (when, offline_limit_unit, offline_limit_value);

	if (when <= (time_t) 0)
		when = (time_t) -1;

	for (ii = 0; ii < folders->len; ii++) {
		CamelFolder *folder = g_ptr_array_index (folders, ii);

		if (!CAMEL_IS_IMAPX_FOLDER (folder))
			continue;

		camel_imapx_folder_update_cache_expire (folder, when);
	}

	g_ptr_array_foreach (folders, (GFunc) g_object_unref, NULL);
	g_ptr_array_free (folders, TRUE);
}

static void
imapx_store_settings_notify_cb (CamelSettings *settings,
                                GParamSpec *pspec,
                                CamelStore *store)
{
	gboolean folder_info_stale = g_str_equal (pspec->name, "use-subscriptions");

	if (g_str_equal (pspec->name, "use-real-junk-path") ||
	    g_str_equal (pspec->name, "use-real-trash-path") ||
	    g_str_equal (pspec->name, "real-junk-path") ||
	    g_str_equal (pspec->name, "real-trash-path")) {
		imapx_store_update_store_flags (store);
		folder_info_stale = TRUE;
	} else if (g_str_equal (pspec->name, "filter-all") ||
		   g_str_equal (pspec->name, "filter-inbox") ||
		   g_str_equal (pspec->name, "filter-junk") ||
		   g_str_equal (pspec->name, "filter-junk-inbox")) {
		imapx_store_update_folder_flags (store);
	} else if (g_str_equal (pspec->name, "limit-by-age") ||
		   g_str_equal (pspec->name, "limit-unit") ||
		   g_str_equal (pspec->name, "limit-value")) {
		imapx_store_update_folder_cache_expire (store);
	}

	if (folder_info_stale)
		camel_store_folder_info_stale (store);
}

static CamelFolderInfo *
imapx_store_build_folder_info (CamelIMAPXStore *imapx_store,
                               const gchar *folder_path,
                               CamelFolderInfoFlags flags)
{
	CamelStore *store = (CamelStore *) imapx_store;
	CamelSettings *settings;
	CamelFolderInfo *fi;
	const gchar *name;

	/* Do not inherit folder types, because those are advertised by the server,
	   while it might not always match what the user has set. In that case
	   there could be for example two Trash folders highlighted in the UI,
	   while only one of them would be the correct one. */
	flags = flags & ~CAMEL_FOLDER_TYPE_MASK;

	store = CAMEL_STORE (imapx_store);
	settings = camel_service_ref_settings (CAMEL_SERVICE (store));

	fi = camel_folder_info_new ();
	fi->full_name = g_strdup (folder_path);
	fi->flags = flags;
	fi->unread = -1;
	fi->total = -1;

	name = strrchr (fi->full_name, '/');
	if (name == NULL)
		name = fi->full_name;
	else
		name++;

	if (camel_imapx_mailbox_is_inbox (fi->full_name)) {
		fi->display_name = g_strdup (_("Inbox"));
		fi->flags |= CAMEL_FOLDER_SYSTEM;
		fi->flags |= CAMEL_FOLDER_TYPE_INBOX;
	} else {
		fi->display_name = g_strdup (name);
	}

	if ((camel_store_get_flags (store) & CAMEL_STORE_VTRASH) == 0) {
		const gchar *trash_path;

		trash_path = camel_imapx_settings_get_real_trash_path (
			CAMEL_IMAPX_SETTINGS (settings));
		if (g_strcmp0 (trash_path, folder_path) == 0)
			fi->flags |= CAMEL_FOLDER_TYPE_TRASH;
	}

	if ((camel_store_get_flags (store) & CAMEL_STORE_REAL_JUNK_FOLDER) != 0) {
		const gchar *junk_path;

		junk_path = camel_imapx_settings_get_real_junk_path (
			CAMEL_IMAPX_SETTINGS (settings));
		if (g_strcmp0 (junk_path, folder_path) == 0)
			fi->flags |= CAMEL_FOLDER_TYPE_JUNK;
	}

	g_object_unref (settings);

	return fi;
}

static void
imapx_store_rename_folder_info (CamelIMAPXStore *imapx_store,
                                const gchar *old_folder_path,
                                const gchar *new_folder_path)
{
	GPtrArray *array;
	gint olen = strlen (old_folder_path);
	guint ii;

	array = camel_store_summary_array (imapx_store->summary);

	for (ii = 0; ii < array->len; ii++) {
		CamelStoreInfo *si;
		CamelIMAPXStoreInfo *imapx_si;
		const gchar *path;
		gchar *new_path;
		gchar *new_mailbox_name;

		si = g_ptr_array_index (array, ii);
		path = camel_store_info_path (imapx_store->summary, si);

		/* We need to adjust not only the entry for the renamed
		 * folder, but also the entries for all the descendants
		 * of the renamed folder. */

		if (!g_str_has_prefix (path, old_folder_path))
			continue;

		if (strlen (path) > olen)
			new_path = g_strdup_printf (
				"%s/%s", new_folder_path, path + olen + 1);
		else
			new_path = g_strdup (new_folder_path);

		camel_store_info_set_string (
			imapx_store->summary, si,
			CAMEL_STORE_INFO_PATH, new_path);

		imapx_si = (CamelIMAPXStoreInfo *) si;
		g_warn_if_fail (imapx_si->separator != '\0');

		new_mailbox_name =
			camel_imapx_folder_path_to_mailbox (
			new_path, imapx_si->separator);

		/* Takes ownership of new_mailbox_name. */
		g_free (imapx_si->mailbox_name);
		imapx_si->mailbox_name = new_mailbox_name;

		camel_store_summary_touch (imapx_store->summary);

		g_free (new_path);
	}

	camel_store_summary_array_free (imapx_store->summary, array);
}

static void
imapx_store_rename_storage_path (CamelIMAPXStore *imapx_store,
                                 const gchar *old_mailbox,
                                 const gchar *new_mailbox)
{
	CamelService *service;
	const gchar *user_cache_dir;
	gchar *root_storage_path;
	gchar *old_storage_path;
	gchar *new_storage_path;

	service = CAMEL_SERVICE (imapx_store);
	user_cache_dir = camel_service_get_user_cache_dir (service);
	root_storage_path = g_build_filename (user_cache_dir, "folders", NULL);

	old_storage_path =
		imapx_path_to_physical (root_storage_path, old_mailbox);
	new_storage_path =
		imapx_path_to_physical (root_storage_path, new_mailbox);

	if (g_rename (old_storage_path, new_storage_path) == -1 && errno != ENOENT) {
		g_warning (
			"Could not rename message cache "
			"'%s' to '%s: %s: cache reset",
			old_storage_path,
			new_storage_path,
			g_strerror (errno));
	}

	g_free (root_storage_path);
	g_free (old_storage_path);
	g_free (new_storage_path);
}

static void
imapx_store_add_mailbox_to_folder (CamelIMAPXStore *store,
                                   CamelIMAPXMailbox *mailbox)
{
	CamelIMAPXFolder *folder;
	gchar *folder_path;

	/* Add the CamelIMAPXMailbox to a cached CamelIMAPXFolder. */

	folder_path = camel_imapx_mailbox_dup_folder_path (mailbox);

	folder = camel_object_bag_get (camel_store_get_folders_bag (CAMEL_STORE (store)), folder_path);

	if (folder != NULL) {
		camel_imapx_folder_set_mailbox (folder, mailbox);
		g_object_unref (folder);
	}

	g_free (folder_path);
}

static CamelStoreInfoFlags
imapx_store_mailbox_attributes_to_flags (CamelIMAPXMailbox *mailbox)
{
	CamelStoreInfoFlags store_info_flags = 0;
	const gchar *attribute;

	attribute = CAMEL_IMAPX_LIST_ATTR_NOSELECT;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute) &&
	    !camel_imapx_mailbox_is_inbox (camel_imapx_mailbox_get_name (mailbox)))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_NOSELECT;

	attribute = CAMEL_IMAPX_LIST_ATTR_NOINFERIORS;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_NOINFERIORS;

	attribute = CAMEL_IMAPX_LIST_ATTR_HASCHILDREN;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_CHILDREN;

	attribute = CAMEL_IMAPX_LIST_ATTR_HASNOCHILDREN;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_NOCHILDREN;

	attribute = CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_SUBSCRIBED;

	/* XXX Does "\Marked" mean CAMEL_STORE_INFO_FOLDER_FLAGGED?
	 *     Who the heck knows; the enum value is undocumented. */

	attribute = CAMEL_IMAPX_LIST_ATTR_FLAGGED;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_FLAGGED;

	attribute = CAMEL_IMAPX_LIST_ATTR_ALL;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_TYPE_ALL;

	attribute = CAMEL_IMAPX_LIST_ATTR_ARCHIVE;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_TYPE_ARCHIVE;

	attribute = CAMEL_IMAPX_LIST_ATTR_DRAFTS;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_TYPE_DRAFTS;

	attribute = CAMEL_IMAPX_LIST_ATTR_JUNK;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_TYPE_JUNK;

	attribute = CAMEL_IMAPX_LIST_ATTR_SENT;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_TYPE_SENT;

	attribute = CAMEL_IMAPX_LIST_ATTR_TRASH;
	if (camel_imapx_mailbox_has_attribute (mailbox, attribute))
		store_info_flags |= CAMEL_STORE_INFO_FOLDER_TYPE_TRASH;

	return store_info_flags;
}

static CamelFolderInfo *
get_folder_info_offline (CamelStore *store,
			 const gchar *top,
			 CamelStoreGetFolderInfoFlags flags,
			 GCancellable *cancellable,
			 GError **error);

static gboolean
imapx_store_mailbox_has_children (CamelIMAPXStore *imapx_store,
				  CamelIMAPXMailbox *mailbox)
{
	CamelFolderInfo *fi;
	gchar *folder_path;
	gboolean has_children;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store), FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	folder_path = camel_imapx_mailbox_dup_folder_path (mailbox);
	if (!folder_path)
		return FALSE;

	fi = get_folder_info_offline (CAMEL_STORE (imapx_store), folder_path, CAMEL_STORE_FOLDER_INFO_RECURSIVE | CAMEL_STORE_FOLDER_INFO_NO_VIRTUAL, NULL, NULL);

	has_children = fi && fi->child;

	if (fi)
		camel_folder_info_free (fi);
	g_free (folder_path);

	return has_children;
}

static void
imapx_store_process_mailbox_attributes (CamelIMAPXStore *store,
                                        CamelIMAPXMailbox *mailbox,
                                        const gchar *oldname)
{
	CamelFolderInfo *fi;
	CamelIMAPXStoreInfo *si;
	CamelStoreInfoFlags flags;
	CamelSettings *settings;
	gboolean use_subscriptions;
	gboolean mailbox_is_subscribed;
	gboolean mailbox_is_nonexistent;
	gboolean mailbox_was_in_summary;
	gboolean mailbox_was_subscribed;
	gboolean emit_folder_created_subscribed = FALSE;
	gboolean emit_folder_unsubscribed_deleted = FALSE;
	gboolean emit_folder_renamed = FALSE;
	gchar *folder_path;
	const gchar *mailbox_name;
	gchar separator;

	settings = camel_service_ref_settings (CAMEL_SERVICE (store));
	use_subscriptions = camel_imapx_settings_get_use_subscriptions (
		CAMEL_IMAPX_SETTINGS (settings));
	g_object_unref (settings);

	mailbox_name = camel_imapx_mailbox_get_name (mailbox);
	separator = camel_imapx_mailbox_get_separator (mailbox);

	mailbox_is_subscribed =
		camel_imapx_mailbox_has_attribute (
		mailbox, CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED) ||
		camel_imapx_mailbox_is_inbox (mailbox_name);

	mailbox_is_nonexistent =
		camel_imapx_mailbox_has_attribute (
		mailbox, CAMEL_IMAPX_LIST_ATTR_NONEXISTENT);

	/* XXX The flags type transforms from CamelStoreInfoFlags
	 *     to CamelFolderInfoFlags about half-way through this.
	 *     We should really eliminate the confusing redundancy. */
	flags = imapx_store_mailbox_attributes_to_flags (mailbox);

	/* Summary retains ownership of the returned CamelStoreInfo. */
	si = camel_imapx_store_summary_mailbox (store->summary, mailbox_name);
	if (!si && oldname)
		si = camel_imapx_store_summary_mailbox (store->summary, oldname);
	if (si != NULL) {
		mailbox_was_in_summary = TRUE;
		if (si->info.flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED)
			mailbox_was_subscribed = TRUE;
		else
			mailbox_was_subscribed = FALSE;
	} else {
		/* XXX Shouldn't this take a GError if it can fail? */
		si = camel_imapx_store_summary_add_from_mailbox (
			store->summary, mailbox);
		g_return_if_fail (si != NULL);
		mailbox_was_in_summary = FALSE;
		mailbox_was_subscribed = FALSE;
	}

	/* Check whether the flags disagree. */
	if (si->info.flags != flags) {
		si->info.flags = flags;
		camel_store_summary_touch (store->summary);
	}

	folder_path = camel_imapx_mailbox_to_folder_path (mailbox_name, separator);
	fi = imapx_store_build_folder_info (store, folder_path, (CamelFolderInfoFlags) flags);

	camel_store_summary_info_unref (store->summary, (CamelStoreInfo *) si);

	/* Figure out which signals to emit, if any. */
	if (use_subscriptions || camel_imapx_namespace_get_category (camel_imapx_mailbox_get_namespace (mailbox)) != CAMEL_IMAPX_NAMESPACE_PERSONAL) {
		/* If we are honoring folder subscriptions, then
		 * subscription changes are equivalent to folder
		 * creation / deletion as far as we're concerned. */
		if (mailbox_is_subscribed && !mailbox_is_nonexistent) {
			if (oldname != NULL) {
				emit_folder_renamed = TRUE;
			} else if (!mailbox_was_subscribed) {
				emit_folder_created_subscribed = TRUE;
			}
		}
		if (!mailbox_is_subscribed && mailbox_was_subscribed)
			emit_folder_unsubscribed_deleted = TRUE;
		if (mailbox_is_nonexistent && mailbox_was_subscribed && !mailbox_is_subscribed)
			emit_folder_unsubscribed_deleted = TRUE;
	} else {
		if (!mailbox_is_nonexistent) {
			if (oldname != NULL) {
				emit_folder_renamed = TRUE;
			} else if (!mailbox_was_in_summary) {
				emit_folder_created_subscribed = TRUE;
			}
		}
		if (mailbox_is_nonexistent && mailbox_was_in_summary && !imapx_store_mailbox_has_children (store, mailbox))
			emit_folder_unsubscribed_deleted = TRUE;
	}

	/* Suppress all signal emissions when synchronizing folders. */
	if (g_atomic_int_get (&store->priv->syncing_folders) > 0) {
		emit_folder_created_subscribed = FALSE;
		emit_folder_unsubscribed_deleted = FALSE;
		emit_folder_renamed = FALSE;
	} else {
		/* At most one signal emission flag should be set. */
		g_warn_if_fail (
			(emit_folder_created_subscribed ? 1 : 0) +
			(emit_folder_unsubscribed_deleted ? 1 : 0) +
			(emit_folder_renamed ? 1 : 0) <= 1);
	}

	if (emit_folder_created_subscribed) {
		camel_store_folder_created (
			CAMEL_STORE (store), fi);
		camel_subscribable_folder_subscribed (
			CAMEL_SUBSCRIBABLE (store), fi);
	}

	if (emit_folder_unsubscribed_deleted) {
		camel_subscribable_folder_unsubscribed (
			CAMEL_SUBSCRIBABLE (store), fi);
		camel_store_folder_deleted (
			CAMEL_STORE (store), fi);
	}

	if (emit_folder_renamed) {
		gchar *old_folder_path;
		gchar *new_folder_path;

		old_folder_path = camel_imapx_mailbox_to_folder_path (
			oldname, separator);
		new_folder_path = camel_imapx_mailbox_to_folder_path (
			mailbox_name, separator);

		imapx_store_rename_folder_info (
			store, old_folder_path, new_folder_path);
		imapx_store_rename_storage_path (
			store, old_folder_path, new_folder_path);

		camel_store_folder_renamed (CAMEL_STORE (store), old_folder_path, fi);

		g_free (old_folder_path);
		g_free (new_folder_path);
	}

	camel_folder_info_free (fi);
	g_free (folder_path);
}

static void
imapx_store_process_mailbox_status (CamelIMAPXStore *imapx_store,
                                    CamelIMAPXMailbox *mailbox)
{
	CamelStore *store;
	CamelFolder *folder;
	gchar *folder_path;

	folder_path = camel_imapx_mailbox_dup_folder_path (mailbox);
	store = CAMEL_STORE (imapx_store);

	/* Update only already opened folders */
	folder = camel_object_bag_reserve (camel_store_get_folders_bag (store), folder_path);
	if (folder != NULL) {
		CamelIMAPXFolder *imapx_folder;
		CamelIMAPXSummary *imapx_summary;
		guint32 uidvalidity;

		imapx_folder = CAMEL_IMAPX_FOLDER (folder);
		imapx_summary = CAMEL_IMAPX_SUMMARY (camel_folder_get_folder_summary (folder));

		uidvalidity = camel_imapx_mailbox_get_uidvalidity (mailbox);

		if (uidvalidity > 0 && uidvalidity != imapx_summary->validity)
			camel_imapx_folder_invalidate_local_cache (
				imapx_folder, uidvalidity);

		g_object_unref (folder);
	} else {
		camel_object_bag_abort (camel_store_get_folders_bag (store), folder_path);
	}

	g_free (folder_path);
}

static void
imapx_store_connect_to_settings (CamelStore *store)
{
	CamelIMAPXStorePrivate *priv;
	CamelSettings *settings;
	gulong handler_id;

	/* XXX I considered calling camel_store_folder_info_stale()
	 *     here, but I suspect it would create unnecessary extra
	 *     work for applications during startup since the signal
	 *     is not emitted immediately.
	 *
	 *     Let's just say whomever replaces the settings object
	 *     in a CamelService is reponsible for deciding whether
	 *     camel_store_folder_info_stale() should be called. */

	priv = CAMEL_IMAPX_STORE_GET_PRIVATE (store);

	settings = camel_service_ref_settings (CAMEL_SERVICE (store));

	g_mutex_lock (&priv->settings_lock);

	if (priv->settings != NULL) {
		g_signal_handler_disconnect (
			priv->settings,
			priv->settings_notify_handler_id);
		priv->settings_notify_handler_id = 0;
		g_clear_object (&priv->settings);
	}

	priv->settings = g_object_ref (settings);

	handler_id = g_signal_connect (
		settings, "notify",
		G_CALLBACK (imapx_store_settings_notify_cb), store);
	priv->settings_notify_handler_id = handler_id;

	g_mutex_unlock (&priv->settings_lock);

	g_object_unref (settings);
}

static void
imapx_store_set_property (GObject *object,
                          guint property_id,
                          const GValue *value,
                          GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONNECTABLE:
			camel_network_service_set_connectable (
				CAMEL_NETWORK_SERVICE (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
imapx_store_get_property (GObject *object,
                          guint property_id,
                          GValue *value,
                          GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONNECTABLE:
			g_value_take_object (
				value,
				camel_network_service_ref_connectable (
				CAMEL_NETWORK_SERVICE (object)));
			return;

		case PROP_HOST_REACHABLE:
			g_value_set_boolean (
				value,
				camel_network_service_get_host_reachable (
				CAMEL_NETWORK_SERVICE (object)));
			return;

		case PROP_CONN_MANAGER:
			g_value_set_object (
				value,
				camel_imapx_store_get_conn_manager (
				CAMEL_IMAPX_STORE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
imapx_store_dispose (GObject *object)
{
	CamelIMAPXStore *imapx_store = CAMEL_IMAPX_STORE (object);

	/* Force disconnect so we don't have it run later,
	 * after we've cleaned up some stuff. */
	if (imapx_store->priv->conn_man != NULL) {
		camel_service_disconnect_sync (CAMEL_SERVICE (imapx_store), FALSE, NULL, NULL);
		g_clear_object (&imapx_store->priv->conn_man);
	}

	if (imapx_store->priv->settings_notify_handler_id > 0) {
		g_signal_handler_disconnect (
			imapx_store->priv->settings,
			imapx_store->priv->settings_notify_handler_id);
		imapx_store->priv->settings_notify_handler_id = 0;
	}

	g_clear_object (&imapx_store->summary);

	g_clear_object (&imapx_store->priv->connecting_server);
	g_clear_object (&imapx_store->priv->settings);
	g_clear_object (&imapx_store->priv->namespaces);

	g_hash_table_remove_all (imapx_store->priv->mailboxes);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_imapx_store_parent_class)->dispose (object);
}

static void
imapx_store_finalize (GObject *object)
{
	CamelIMAPXStorePrivate *priv;

	priv = CAMEL_IMAPX_STORE_GET_PRIVATE (object);

	g_mutex_clear (&priv->get_finfo_lock);
	g_mutex_clear (&priv->server_lock);

	g_hash_table_destroy (priv->quota_info);
	g_mutex_clear (&priv->quota_info_lock);

	g_mutex_clear (&priv->settings_lock);

	g_mutex_clear (&priv->namespaces_lock);

	g_hash_table_destroy (priv->mailboxes);
	g_mutex_clear (&priv->mailboxes_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_imapx_store_parent_class)->finalize (object);
}

static void
imapx_store_notify (GObject *object,
                    GParamSpec *pspec)
{
	if (g_str_equal (pspec->name, "settings")) {
		imapx_store_connect_to_settings (CAMEL_STORE (object));
		imapx_store_update_store_flags (CAMEL_STORE (object));
	}

	/* Chain up to parent's notify() method. */
	G_OBJECT_CLASS (camel_imapx_store_parent_class)->
		notify (object, pspec);
}

static gchar *
imapx_get_name (CamelService *service,
                gboolean brief)
{
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	gchar *host;
	gchar *user;
	gchar *name;

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	user = camel_network_settings_dup_user (network_settings);

	g_object_unref (settings);

	if (brief)
		name = g_strdup_printf (
			_("IMAP server %s"), host);
	else
		name = g_strdup_printf (
			_("IMAP service for %s on %s"), user, host);

	g_free (host);
	g_free (user);

	return name;
}

static gboolean
imapx_connect_sync (CamelService *service,
                    GCancellable *cancellable,
                    GError **error)
{
	CamelIMAPXStore *imapx_store;
	CamelIMAPXMailbox *mailbox;

	/* Chain up to parent's method. */
	if (!CAMEL_SERVICE_CLASS (camel_imapx_store_parent_class)->connect_sync (service, cancellable, error))
		return FALSE;

	imapx_store = CAMEL_IMAPX_STORE (service);

	if (!camel_imapx_conn_manager_connect_sync (imapx_store->priv->conn_man, cancellable, error))
		return FALSE;

	mailbox = camel_imapx_store_ref_mailbox (imapx_store, "INBOX");
	if (!mailbox) {
		/* No INBOX can mean no LIST being done yet, but INBOX is important,
		   thus look for it. */
		camel_imapx_conn_manager_list_sync (imapx_store->priv->conn_man, "INBOX", 0, cancellable, NULL);

		mailbox = camel_imapx_store_ref_mailbox (imapx_store, "INBOX");
	}

	if (mailbox) {
		/* To eventually start IDLE/NOTIFY listener */
		if (!camel_imapx_conn_manager_noop_sync (imapx_store->priv->conn_man, mailbox, cancellable, error)) {
			g_clear_object (&mailbox);
			return FALSE;
		}

		g_clear_object (&mailbox);
	}

	return TRUE;
}

static gboolean
imapx_disconnect_sync (CamelService *service,
                       gboolean clean,
                       GCancellable *cancellable,
                       GError **error)
{
	CamelIMAPXStorePrivate *priv;

	priv = CAMEL_IMAPX_STORE_GET_PRIVATE (service);

	if (priv->conn_man != NULL)
		camel_imapx_conn_manager_disconnect_sync (priv->conn_man, cancellable, error);

	g_mutex_lock (&priv->server_lock);

	g_clear_object (&priv->connecting_server);

	g_mutex_unlock (&priv->server_lock);

	/* Chain up to parent's method. */
	return CAMEL_SERVICE_CLASS (camel_imapx_store_parent_class)->disconnect_sync (service, clean, cancellable, error);
}

static CamelAuthenticationResult
imapx_authenticate_sync (CamelService *service,
                         const gchar *mechanism,
                         GCancellable *cancellable,
                         GError **error)
{
	CamelIMAPXStorePrivate *priv;
	CamelIMAPXServer *imapx_server;
	CamelAuthenticationResult result;

	priv = CAMEL_IMAPX_STORE_GET_PRIVATE (service);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return CAMEL_AUTHENTICATION_ERROR;

	/* This should have been set for us by connect_sync(). */
	g_mutex_lock (&priv->server_lock);
	if (!priv->connecting_server) {
		g_mutex_unlock (&priv->server_lock);

		g_set_error_literal (error, CAMEL_SERVICE_ERROR, CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			_("No IMAPx connection object provided"));

		return CAMEL_AUTHENTICATION_ERROR;
	}

	imapx_server = g_object_ref (priv->connecting_server);
	g_mutex_unlock (&priv->server_lock);

	result = camel_imapx_server_authenticate_sync (
		imapx_server, mechanism, cancellable, error);

	g_clear_object (&imapx_server);

	return result;
}

CamelServiceAuthType camel_imapx_password_authtype = {
	N_("Password"),

	N_("This option will connect to the IMAP server using a "
	   "plaintext password."),

	"",
	TRUE
};

static GList *
imapx_query_auth_types_sync (CamelService *service,
                             GCancellable *cancellable,
                             GError **error)
{
	CamelIMAPXStore *imapx_store;
	GList *sasl_types = NULL;
	CamelIMAPXServer *server;
	const struct _capability_info *cinfo;

	imapx_store = CAMEL_IMAPX_STORE (service);

	server = camel_imapx_server_new (imapx_store);
	camel_imapx_server_set_tagprefix (server, 'Z');

	g_signal_emit_by_name (imapx_store->priv->conn_man, "connection-created", 0, server);

	if (!camel_imapx_server_query_auth_types_sync (server, cancellable, error))
		goto exit;

	cinfo = camel_imapx_server_get_capability_info (server);

	if (cinfo && cinfo->auth_types) {
		GHashTableIter iter;
		gpointer key;

		g_hash_table_iter_init (&iter, cinfo->auth_types);
		while (g_hash_table_iter_next (&iter, &key, NULL)) {
			CamelServiceAuthType *auth_type;

			auth_type = camel_sasl_authtype (key);
			if (auth_type)
				sasl_types = g_list_prepend (sasl_types, auth_type);
		}
	}

	sasl_types = g_list_prepend (sasl_types, &camel_imapx_password_authtype);

exit:
	g_object_unref (server);

	return sasl_types;
}

static CamelFolder *
get_folder_offline (CamelStore *store,
                    const gchar *folder_name,
                    CamelStoreGetFolderFlags flags,
                    GError **error)
{
	CamelIMAPXStore *imapx_store = CAMEL_IMAPX_STORE (store);
	CamelFolder *new_folder = NULL;
	CamelStoreInfo *si;
	CamelService *service;
	const gchar *user_cache_dir;

	service = CAMEL_SERVICE (store);
	user_cache_dir = camel_service_get_user_cache_dir (service);

	if (g_ascii_strcasecmp (folder_name, "INBOX") == 0)
		folder_name = "INBOX";

	si = camel_store_summary_path (imapx_store->summary, folder_name);

	if (si != NULL) {
		gchar *base_dir;
		gchar *folder_dir;

		base_dir = g_build_filename (user_cache_dir, "folders", NULL);
		folder_dir = imapx_path_to_physical (base_dir, folder_name);
		new_folder = camel_imapx_folder_new (
			store, folder_dir, folder_name, error);
		g_free (folder_dir);
		g_free (base_dir);

		camel_store_summary_info_unref (imapx_store->summary, si);
	} else {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("No such folder %s"), folder_name);
	}

	return new_folder;
}

static void
fill_fi (CamelStore *store,
         CamelFolderInfo *fi)
{
	CamelFolder *folder;

	folder = camel_object_bag_peek (camel_store_get_folders_bag (store), fi->full_name);
	if (folder) {
		CamelIMAPXFolder *imapx_folder;
		CamelIMAPXSummary *ims;
		CamelIMAPXMailbox *mailbox;

		if (camel_folder_get_folder_summary (folder))
			ims = CAMEL_IMAPX_SUMMARY (camel_folder_get_folder_summary (folder));
		else
			ims = (CamelIMAPXSummary *) camel_imapx_summary_new (folder);

		imapx_folder = CAMEL_IMAPX_FOLDER (folder);
		mailbox = camel_imapx_folder_ref_mailbox (imapx_folder);

		fi->unread = camel_folder_summary_get_unread_count ((CamelFolderSummary *) ims);
		fi->total = camel_folder_summary_get_saved_count ((CamelFolderSummary *) ims);

		g_clear_object (&mailbox);

		if (!camel_folder_get_folder_summary (folder))
			g_object_unref (ims);
		g_object_unref (folder);
	}
}

static void
imapx_delete_folder_from_cache (CamelIMAPXStore *imapx_store,
                                const gchar *folder_path,
				gboolean save_summary)
{
	gchar *state_file;
	gchar *folder_dir, *storage_path;
	CamelFolderInfo *fi;
	CamelService *service;
	const gchar *user_cache_dir;

	service = CAMEL_SERVICE (imapx_store);
	user_cache_dir = camel_service_get_user_cache_dir (service);

	storage_path = g_build_filename (user_cache_dir, "folders", NULL);
	folder_dir = imapx_path_to_physical (storage_path, folder_path);
	g_free (storage_path);
	if (g_access (folder_dir, F_OK) != 0) {
		g_free (folder_dir);
		goto event;
	}

	/* Delete summary and all the data */
	state_file = g_build_filename (folder_dir, "cmeta", NULL);
	g_unlink (state_file);
	g_free (state_file);

	camel_db_delete_folder (camel_store_get_db (CAMEL_STORE (imapx_store)), folder_path, NULL);
	g_rmdir (folder_dir);

	state_file = g_build_filename (folder_dir, "subfolders", NULL);
	g_rmdir (state_file);
	g_free (state_file);

	g_rmdir (folder_dir);
	g_free (folder_dir);

event:
	camel_store_summary_remove_path (imapx_store->summary, folder_path);
	if (save_summary)
		camel_store_summary_save (imapx_store->summary);

	fi = imapx_store_build_folder_info (imapx_store, folder_path, 0);
	camel_subscribable_folder_unsubscribed (CAMEL_SUBSCRIBABLE (imapx_store), fi);
	camel_store_folder_deleted (CAMEL_STORE (imapx_store), fi);
	camel_folder_info_free (fi);
}

static CamelFolderInfo *
get_folder_info_offline (CamelStore *store,
                         const gchar *top,
                         CamelStoreGetFolderInfoFlags flags,
			 GCancellable *cancellable,
                         GError **error)
{
	CamelIMAPXStore *imapx_store = CAMEL_IMAPX_STORE (store);
	CamelService *service;
	CamelSettings *settings;
	gboolean include_inbox = FALSE;
	CamelFolderInfo *fi;
	GPtrArray *folders;
	GPtrArray *array;
	gboolean use_subscriptions;
	gint top_len;
	guint ii;

	if (g_strcmp0 (top, CAMEL_VTRASH_NAME) == 0 ||
	    g_strcmp0 (top, CAMEL_VJUNK_NAME) == 0) {
		CamelFolder *vfolder;

		vfolder = camel_store_get_folder_sync (store, top, 0, cancellable, error);
		if (!vfolder)
			return NULL;

		fi = imapx_store_build_folder_info (imapx_store, top, 0);
		fi->unread = camel_folder_summary_get_unread_count (camel_folder_get_folder_summary (vfolder));
		fi->total = camel_folder_summary_get_saved_count (camel_folder_get_folder_summary (vfolder));

		if (g_strcmp0 (top, CAMEL_VTRASH_NAME) == 0)
			fi->flags = (fi->flags & ~CAMEL_FOLDER_TYPE_MASK) |
				CAMEL_FOLDER_VIRTUAL |
				CAMEL_FOLDER_VTRASH |
				CAMEL_FOLDER_TYPE_TRASH;
		else
			fi->flags = (fi->flags & ~CAMEL_FOLDER_TYPE_MASK) |
				CAMEL_FOLDER_VIRTUAL |
				CAMEL_FOLDER_TYPE_JUNK;

		g_object_unref (vfolder);

		return fi;
	}

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	use_subscriptions = camel_imapx_settings_get_use_subscriptions (
		CAMEL_IMAPX_SETTINGS (settings));

	g_object_unref (settings);

	/* FIXME: obey other flags */

	folders = g_ptr_array_new ();

	if (top == NULL || top[0] == '\0') {
		include_inbox = TRUE;
		top = "";
	}

	top_len = strlen (top);

	/* folder_info_build will insert parent nodes as necessary and mark
	 * them as noselect, which is information we actually don't have at
	 * the moment. So let it do the right thing by bailing out if it's
	 * not a folder we're explicitly interested in. */

	array = camel_store_summary_array (imapx_store->summary);

	for (ii = 0; ii < array->len; ii++) {
		CamelStoreInfo *si;
		const gchar *folder_path;
		gboolean si_is_inbox;
		gboolean si_is_match;

		si = g_ptr_array_index (array, ii);
		folder_path = camel_store_info_path (imapx_store->summary, si);
		si_is_inbox = (g_ascii_strcasecmp (folder_path, "INBOX") == 0);

		/* Filter by folder path. */
		si_is_match =
			(include_inbox && si_is_inbox) ||
			(g_str_has_prefix (folder_path, top) && (top_len == 0 ||
			!folder_path[top_len] || folder_path[top_len] == '/'));

		if (!si_is_match)
			continue;

		/* Filter by subscription flags.
		 *
		 * Skip the folder if:
		 *   The user only wants to see subscribed folders
		 *   AND the folder is not subscribed
		 *   AND the caller only wants SUBSCRIBED folder info
		 *   AND the caller does NOT want a SUBSCRIPTION_LIST
		 *
		 * Note that having both SUBSCRIBED and SUBSCRIPTION_LIST
		 * flags set is contradictory.  SUBSCRIPTION_LIST wins in
		 * that case.
		 */
		si_is_match =
			!use_subscriptions ||
			(si->flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED) ||
			!(flags & CAMEL_STORE_FOLDER_INFO_SUBSCRIBED) ||
			(flags & CAMEL_STORE_FOLDER_INFO_SUBSCRIPTION_LIST);

		if (!si_is_match)
			continue;

		if (!use_subscriptions && !(si->flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED) &&
		    !(flags & CAMEL_STORE_FOLDER_INFO_SUBSCRIPTION_LIST)) {
			CamelIMAPXMailbox *mailbox;

			mailbox = camel_imapx_store_ref_mailbox (imapx_store, ((CamelIMAPXStoreInfo *) si)->mailbox_name);
			if (!mailbox || camel_imapx_namespace_get_category (camel_imapx_mailbox_get_namespace (mailbox)) != CAMEL_IMAPX_NAMESPACE_PERSONAL) {
				/* Skip unsubscribed mailboxes which are not in the Personal namespace */
				g_clear_object (&mailbox);
				continue;
			}

			g_clear_object (&mailbox);
		}

		fi = imapx_store_build_folder_info (imapx_store, folder_path, 0);
		fi->unread = si->unread;
		fi->total = si->total;

		/* Do not inherit folder types, because those are advertised by the server,
		   while it might not always match what the user has set. In that case
		   there could be for example two Trash folders highlighted in the UI,
		   while only one of them would be the correct one. */
		if ((fi->flags & CAMEL_FOLDER_TYPE_MASK) != 0) {
			fi->flags =
				(fi->flags & CAMEL_FOLDER_TYPE_MASK) |
				(si->flags & ~CAMEL_FOLDER_TYPE_MASK);
		} else {
			fi->flags = si->flags & ~CAMEL_FOLDER_TYPE_MASK;
		}

		/* blah, this gets lost somewhere, i can't be bothered finding out why */
		if (si_is_inbox) {
			fi->flags =
				(fi->flags & ~CAMEL_FOLDER_TYPE_MASK) |
				CAMEL_FOLDER_TYPE_INBOX;
			fi->flags |= CAMEL_FOLDER_SYSTEM;
		}

		if (!(si->flags & CAMEL_FOLDER_NOSELECT))
			fill_fi ((CamelStore *) imapx_store, fi);

		if (!fi->child)
			fi->flags |= CAMEL_FOLDER_NOCHILDREN;

		if (fi->unread == -1 && fi->total == -1) {
			CamelIMAPXMailbox *mailbox;

			mailbox = camel_imapx_store_ref_mailbox (imapx_store, ((CamelIMAPXStoreInfo *) si)->mailbox_name);

			if (mailbox) {
				fi->unread = camel_imapx_mailbox_get_unseen (mailbox);
				fi->total = camel_imapx_mailbox_get_messages (mailbox);
			}

			g_clear_object (&mailbox);
		}

		g_ptr_array_add (folders, fi);
	}

	camel_store_summary_array_free (imapx_store->summary, array);

	fi = camel_folder_info_build (folders, top, '/', TRUE);

	g_ptr_array_free (folders, TRUE);

	return fi;
}

static void
collect_folder_info_for_list (CamelIMAPXStore *imapx_store,
                              CamelIMAPXMailbox *mailbox,
                              GHashTable *folder_info_results)
{
	CamelIMAPXStoreInfo *si;
	CamelFolderInfo *fi;
	const gchar *folder_path;
	const gchar *mailbox_name;

	mailbox_name = camel_imapx_mailbox_get_name (mailbox);

	si = camel_imapx_store_summary_mailbox (
		imapx_store->summary, mailbox_name);
	g_return_if_fail (si != NULL);

	folder_path = camel_store_info_path (
		imapx_store->summary, (CamelStoreInfo *) si);
	fi = imapx_store_build_folder_info (imapx_store, folder_path, 0);

	/* Takes ownership of the CamelFolderInfo. */
	g_hash_table_insert (folder_info_results, g_strdup (mailbox_name), fi);

	camel_store_summary_info_unref (imapx_store->summary, (CamelStoreInfo *) si);
}

static gboolean
fetch_folder_info_for_pattern (CamelIMAPXConnManager *conn_man,
                               CamelIMAPXNamespace *namespace,
                               const gchar *pattern,
                               CamelStoreGetFolderInfoFlags flags,
                               GHashTable *folder_info_results,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelIMAPXStore *imapx_store;
	GList *list, *link;
	GError *local_error = NULL;
	gboolean success;

	imapx_store = camel_imapx_conn_manager_ref_store (conn_man);

	success = camel_imapx_conn_manager_list_sync (conn_man, pattern, flags, cancellable, &local_error);

	if (!success) {
		if (!g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED) &&
		    camel_imapx_namespace_get_category (namespace) != CAMEL_IMAPX_NAMESPACE_PERSONAL) {
			CamelIMAPXMailbox *inbox;

			/* Ignore errors for non-personal namespaces; one such error can be:
			   "NO LIST failed: wildcards not permitted in username" */
			g_clear_error (&local_error);

			/* Eventually run NOOP, to enable IDLE listening, which did not start
			   due to the error. */
			inbox = camel_imapx_store_ref_mailbox (imapx_store, "INBOX");
			if (inbox) {
				camel_imapx_conn_manager_noop_sync (conn_man, inbox, cancellable, NULL);
				g_clear_object (&inbox);
			}

			g_clear_object (&imapx_store);

			return TRUE;
		} else if (local_error) {
			g_propagate_error (error, local_error);
		}

		g_clear_object (&imapx_store);

		return FALSE;
	}

	list = camel_imapx_store_list_mailboxes (imapx_store, namespace, pattern);

	for (link = list; link != NULL; link = g_list_next (link)) {
		CamelIMAPXMailbox *mailbox;

		mailbox = CAMEL_IMAPX_MAILBOX (link->data);

		collect_folder_info_for_list (
			imapx_store, mailbox, folder_info_results);
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);

	g_object_unref (imapx_store);

	return TRUE;
}

static gboolean
fetch_folder_info_for_inbox (CamelIMAPXConnManager *conn_man,
                             CamelStoreGetFolderInfoFlags flags,
                             GHashTable *folder_info_results,
                             GCancellable *cancellable,
                             GError **error)
{
	CamelIMAPXStore *imapx_store;
	gboolean success;

	imapx_store = camel_imapx_conn_manager_ref_store (conn_man);

	success = camel_imapx_conn_manager_list_sync (conn_man, "INBOX", flags, cancellable, error);

	if (success) {
		CamelIMAPXMailbox *mailbox;

		mailbox = camel_imapx_store_ref_mailbox (imapx_store, "INBOX");
		g_return_val_if_fail (mailbox != NULL, FALSE);

		collect_folder_info_for_list (
			imapx_store, mailbox, folder_info_results);
	}

	g_object_unref (imapx_store);

	return success;
}

static gboolean
fetch_folder_info_for_namespace_category (CamelIMAPXStore *imapx_store,
					  CamelIMAPXConnManager *conn_man,
                                          CamelIMAPXNamespaceCategory category,
                                          CamelStoreGetFolderInfoFlags flags,
                                          GHashTable *folder_info_results,
                                          GCancellable *cancellable,
                                          GError **error)
{
	CamelIMAPXNamespaceResponse *namespace_response;
	GList *list, *link;
	gboolean success = TRUE;

	namespace_response = camel_imapx_store_ref_namespaces (imapx_store);
	if (!namespace_response)
		return TRUE;

	list = camel_imapx_namespace_response_list (namespace_response);

	for (link = list; link != NULL; link = g_list_next (link)) {
		CamelIMAPXNamespace *namespace;
		CamelIMAPXNamespaceCategory ns_category;
		const gchar *ns_prefix;
		gchar *pattern;

		namespace = CAMEL_IMAPX_NAMESPACE (link->data);
		ns_category = camel_imapx_namespace_get_category (namespace);
		ns_prefix = camel_imapx_namespace_get_prefix (namespace);

		if ((flags & (CAMEL_STORE_FOLDER_INFO_SUBSCRIPTION_LIST | CAMEL_STORE_FOLDER_INFO_SUBSCRIBED)) == 0 && ns_category != category)
			continue;

		pattern = g_strdup_printf ("%s*", ns_prefix);

		success = fetch_folder_info_for_pattern (
			conn_man, namespace, pattern, flags,
			folder_info_results, cancellable, error);

		g_free (pattern);

		if (!success)
			break;
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);

	g_object_unref (namespace_response);

	return success;
}

static gboolean
fetch_folder_info_from_folder_path (CamelIMAPXStore *imapx_store,
				    CamelIMAPXConnManager *conn_man,
                                    const gchar *folder_path,
                                    CamelStoreGetFolderInfoFlags flags,
                                    GHashTable *folder_info_results,
                                    GCancellable *cancellable,
                                    GError **error)
{
	CamelIMAPXNamespaceResponse *namespace_response;
	CamelIMAPXNamespace *namespace;
	gchar *mailbox_name;
	gchar *utf7_mailbox_name;
	gchar *pattern;
	gchar separator;
	gboolean success = FALSE;

	namespace_response = camel_imapx_store_ref_namespaces (imapx_store);
	if (!namespace_response)
		return TRUE;

	/* Find a suitable IMAP namespace for the folder path. */
	namespace = camel_imapx_namespace_response_lookup_for_path (
		namespace_response, folder_path);
	if (namespace == NULL) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_INVALID,
			_("No IMAP namespace for folder path “%s”"),
			folder_path);
		goto exit;
	}

	/* Convert the folder path to a mailbox name. */
	separator = camel_imapx_namespace_get_separator (namespace);
	mailbox_name = g_strdelimit (g_strdup (folder_path), "/", separator);

	utf7_mailbox_name = camel_utf8_utf7 (mailbox_name);
	pattern = g_strdup_printf ("%s*", utf7_mailbox_name);

	success = fetch_folder_info_for_pattern (
		conn_man, namespace, pattern, flags,
		folder_info_results, cancellable, error);

	g_free (pattern);
	g_free (utf7_mailbox_name);
	g_free (mailbox_name);

exit:
	g_clear_object (&namespace);
	g_clear_object (&namespace_response);

	return success;
}

static void
imapx_store_mark_mailbox_unknown_cb (gpointer key,
				     gpointer value,
				     gpointer user_data)
{
	CamelIMAPXMailbox *mailbox = value;

	g_return_if_fail (mailbox != NULL);

	camel_imapx_mailbox_set_state (mailbox, CAMEL_IMAPX_MAILBOX_STATE_UNKNOWN);
}

static gboolean
imapx_store_remove_unknown_mailboxes_cb (gpointer key,
					 gpointer value,
					 gpointer user_data)
{
	CamelIMAPXMailbox *mailbox = value;
	CamelIMAPXStore *imapx_store = user_data;
	CamelStoreInfo *si;

	g_return_val_if_fail (mailbox != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store), FALSE);

	if (camel_imapx_mailbox_get_state (mailbox) == CAMEL_IMAPX_MAILBOX_STATE_CREATED) {
		CamelSettings *settings;
		CamelFolderInfo *fi;
		gchar *folder_path;
		gboolean use_subscriptions;

		settings = camel_service_ref_settings (CAMEL_SERVICE (imapx_store));
		use_subscriptions = camel_imapx_settings_get_use_subscriptions (CAMEL_IMAPX_SETTINGS (settings));
		g_object_unref (settings);

		folder_path = camel_imapx_mailbox_dup_folder_path (mailbox);
		fi = imapx_store_build_folder_info (imapx_store, folder_path,
			(CamelFolderInfoFlags) imapx_store_mailbox_attributes_to_flags (mailbox));
		camel_store_folder_created (CAMEL_STORE (imapx_store), fi);
		if ((fi->flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED) != 0 || !use_subscriptions)
			camel_subscribable_folder_subscribed (CAMEL_SUBSCRIBABLE (imapx_store), fi);
		camel_folder_info_free (fi);
		g_free (folder_path);
	}

	if (camel_imapx_mailbox_get_state (mailbox) != CAMEL_IMAPX_MAILBOX_STATE_UNKNOWN) {
		return FALSE;
	}

	si = (CamelStoreInfo *) camel_imapx_store_summary_mailbox (imapx_store->summary, camel_imapx_mailbox_get_name (mailbox));
	if (si) {
		const gchar *si_path;
		gchar *dup_folder_path;

		si_path = camel_store_info_path (imapx_store->summary, si);
		dup_folder_path = g_strdup (si_path);

		if (dup_folder_path != NULL) {
			imapx_delete_folder_from_cache (imapx_store, dup_folder_path, FALSE);
			g_free (dup_folder_path);
		} else {
			camel_store_summary_remove (imapx_store->summary, si);
		}

		camel_store_summary_info_unref (imapx_store->summary, si);
	}

	return TRUE;
}

static gboolean
imapx_store_mailbox_is_unknown (CamelIMAPXStore *imapx_store,
				GPtrArray *store_infos,
				const CamelIMAPXStoreInfo *to_check)
{
	CamelIMAPXMailbox *mailbox;
	gboolean is_unknown;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store), FALSE);
	g_return_val_if_fail (store_infos != NULL, FALSE);

	if (!to_check || !to_check->mailbox_name || !*to_check->mailbox_name)
		return FALSE;

	mailbox = camel_imapx_store_ref_mailbox (imapx_store, to_check->mailbox_name);

	is_unknown = mailbox && camel_imapx_mailbox_get_state (mailbox) == CAMEL_IMAPX_MAILBOX_STATE_UNKNOWN;

	if (!mailbox && to_check->separator) {
		CamelSettings *settings;
		gboolean use_subscriptions;
		gchar *mailbox_with_separator;
		gint ii;

		settings = camel_service_ref_settings (CAMEL_SERVICE (imapx_store));
		use_subscriptions = camel_imapx_settings_get_use_subscriptions (CAMEL_IMAPX_SETTINGS (settings));
		g_object_unref (settings);

		mailbox_with_separator = g_strdup_printf ("%s%c", to_check->mailbox_name, to_check->separator);

		for (ii = 0; ii < store_infos->len; ii++) {
			CamelIMAPXStoreInfo *si;

			si = g_ptr_array_index (store_infos, ii);

			if (si->mailbox_name && g_str_has_prefix (si->mailbox_name, mailbox_with_separator) && (
			    !use_subscriptions || (((CamelStoreInfo *) si)->flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED) != 0)) {
				/* This can be a 'virtual' parent folder of some subscribed subfolder */
				break;
			}
		}

		is_unknown = ii == store_infos->len;

		g_free (mailbox_with_separator);
	}

	g_clear_object (&mailbox);

	return is_unknown;
}

static gboolean
sync_folders (CamelIMAPXStore *imapx_store,
              const gchar *root_folder_path,
              CamelStoreGetFolderInfoFlags flags,
	      gboolean initial_setup,
              GCancellable *cancellable,
              GError **error)
{
	CamelIMAPXConnManager *conn_man;
	GHashTable *folder_info_results;
	gboolean update_folder_list;
	gboolean success;

	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	/* mailbox name -> CamelFolderInfo */
	folder_info_results = g_hash_table_new_full (
		(GHashFunc) imapx_name_hash,
		(GEqualFunc) imapx_name_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) camel_folder_info_free);

	/* This suppresses CamelStore signal emissions
	 * in imapx_store_process_mailbox_attributes(). */
	g_atomic_int_inc (&imapx_store->priv->syncing_folders);

	update_folder_list = !initial_setup && (!root_folder_path || !*root_folder_path);

	if (update_folder_list) {
		g_mutex_lock (&imapx_store->priv->mailboxes_lock);
		g_hash_table_foreach (imapx_store->priv->mailboxes, imapx_store_mark_mailbox_unknown_cb, imapx_store);
		g_mutex_unlock (&imapx_store->priv->mailboxes_lock);
	}

	if (root_folder_path != NULL && *root_folder_path != '\0') {
		success = fetch_folder_info_from_folder_path (
			imapx_store, conn_man, root_folder_path, flags,
			folder_info_results, cancellable, error);
	} else {
		gboolean have_folder_info_for_inbox;

		success = fetch_folder_info_for_namespace_category (
			imapx_store, conn_man, CAMEL_IMAPX_NAMESPACE_PERSONAL, flags |
			(update_folder_list ? CAMEL_STORE_FOLDER_INFO_SUBSCRIBED : 0),
			folder_info_results, cancellable, error);

		have_folder_info_for_inbox =
			g_hash_table_contains (folder_info_results, "INBOX");

		/* XXX Slight hack, mainly for Courier servers.  If INBOX
		 *     is not included in any defined personal namespaces,
		 *     then LIST it explicitly. */
		if (success && !have_folder_info_for_inbox)
			success = fetch_folder_info_for_inbox (
				conn_man, flags, folder_info_results,
				cancellable, error);
	}

	/* Don't need to test for zero, just decrement atomically. */
	(void) g_atomic_int_dec_and_test (&imapx_store->priv->syncing_folders);

	if (!success)
		goto exit;

	if (update_folder_list) {
		g_mutex_lock (&imapx_store->priv->mailboxes_lock);
		g_hash_table_foreach_remove (imapx_store->priv->mailboxes, imapx_store_remove_unknown_mailboxes_cb, imapx_store);
		g_mutex_unlock (&imapx_store->priv->mailboxes_lock);
	}

	if (!root_folder_path || !*root_folder_path) {
		GPtrArray *array;
		guint ii;

		/* Finally update store's summary */
		array = camel_store_summary_array (imapx_store->summary);
		for (ii = 0; array && ii < array->len; ii++) {
			CamelStoreInfo *si;
			const gchar *si_path;

			si = g_ptr_array_index (array, ii);
			si_path = camel_store_info_path (imapx_store->summary, si);

			if (imapx_store_mailbox_is_unknown (imapx_store, array, (CamelIMAPXStoreInfo *) si)) {
				gchar *dup_folder_path = g_strdup (si_path);

				if (dup_folder_path != NULL) {
					/* Do not unsubscribe from it, it influences UI for non-subscribable folders */
					imapx_delete_folder_from_cache (imapx_store, dup_folder_path, FALSE);
					g_free (dup_folder_path);
				} else {
					camel_store_summary_remove (imapx_store->summary, si);
				}
			}
		}

		camel_store_summary_array_free (imapx_store->summary, array);
	}

	camel_store_summary_save (imapx_store->summary);

exit:
	g_hash_table_destroy (folder_info_results);

	return success;
}

static void
imapx_refresh_finfo (CamelSession *session,
                     GCancellable *cancellable,
                     CamelIMAPXStore *store,
                     GError **error)
{
	CamelService *service;
	const gchar *display_name;

	service = CAMEL_SERVICE (store);
	display_name = camel_service_get_display_name (service);

	camel_operation_push_message (
		cancellable, _("Retrieving folder list for “%s”"),
		display_name);

	if (!camel_offline_store_get_online (CAMEL_OFFLINE_STORE (store)))
		goto exit;

	if (!camel_service_connect_sync (
		CAMEL_SERVICE (store), cancellable, error))
		goto exit;

	sync_folders (store, NULL, 0, FALSE, cancellable, error);

	camel_store_summary_save (store->summary);

exit:
	camel_operation_pop_message (cancellable);
}

static void
discover_inbox (CamelIMAPXStore *imapx_store,
                GCancellable *cancellable)
{
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox = NULL;
	const gchar *attribute;

	conn_man = camel_imapx_store_get_conn_manager (imapx_store);
	mailbox = camel_imapx_store_ref_mailbox (imapx_store, "INBOX");

	if (mailbox == NULL)
		return;

	attribute = CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED;
	if (!camel_imapx_mailbox_has_attribute (mailbox, attribute)) {
		GError *local_error = NULL;
		gboolean success;

		success = camel_imapx_conn_manager_subscribe_mailbox_sync (conn_man, mailbox, cancellable, &local_error);
		if (!success && !g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
			g_warning ("%s: Failed to subscribe INBOX: %s", G_STRFUNC, local_error ? local_error->message : "Unknown error");
		}

		g_clear_error (&local_error);
	}

	g_clear_object (&mailbox);
}

static gboolean
imapx_can_refresh_folder (CamelStore *store,
                          CamelFolderInfo *info,
                          GError **error)
{
	CamelService *service;
	CamelSettings *settings;
	CamelStoreClass *store_class;
	gboolean check_all;
	gboolean check_subscribed;
	gboolean subscribed;
	gboolean res;
	GError *local_error = NULL;

	store_class = CAMEL_STORE_CLASS (camel_imapx_store_parent_class);

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	check_all = camel_imapx_settings_get_check_all (
		CAMEL_IMAPX_SETTINGS (settings));

	check_subscribed = camel_imapx_settings_get_check_subscribed (
		CAMEL_IMAPX_SETTINGS (settings));

	g_object_unref (settings);

	subscribed = ((info->flags & CAMEL_FOLDER_SUBSCRIBED) != 0);

	res = store_class->can_refresh_folder (store, info, &local_error) ||
		check_all || (check_subscribed && subscribed);

	if (!res && !local_error) {
		CamelFolder *folder;

		folder = camel_store_get_folder_sync (store, info->full_name, 0, NULL, &local_error);
		if (folder && CAMEL_IS_IMAPX_FOLDER (folder))
			res = camel_imapx_folder_get_check_folder (CAMEL_IMAPX_FOLDER (folder));

		g_clear_object (&folder);
	}

	if (local_error != NULL)
		g_propagate_error (error, local_error);

	return res;
}

static CamelFolder *
imapx_store_get_folder_sync (CamelStore *store,
                             const gchar *folder_name,
                             CamelStoreGetFolderFlags flags,
                             GCancellable *cancellable,
                             GError **error)
{
	CamelFolder *folder;
	CamelSettings *settings;
	gboolean use_real_junk_path = FALSE;
	gboolean use_real_trash_path = FALSE;

	/* XXX This should be taken care of before we get this far. */
	if (*folder_name == '/')
		folder_name++;

	folder = get_folder_offline (store, folder_name, flags, error);

	/* Configure the folder flags according to IMAPX settings.
	 *
	 * XXX Since this is only done when the folder is first created,
	 *     a restart is required to pick up changes to real Junk/Trash
	 *     folder settings.  Need to think of a better way.
	 *
	 *     Perhaps have CamelStoreSettings grow junk and trash path
	 *     string properties, and eliminate the CAMEL_FOLDER_IS_JUNK
	 *     and CAMEL_FOLDER_IS_TRASH flags.  Then add functions like
	 *     camel_folder_is_junk() and camel_folder_is_trash(), which
	 *     compare their own full name against CamelStoreSettings.
	 *
	 *     Something to think about...
	 */

	settings = camel_service_ref_settings (CAMEL_SERVICE (store));

	if (folder != NULL) {
		use_real_junk_path =
			camel_imapx_settings_get_use_real_junk_path (
			CAMEL_IMAPX_SETTINGS (settings));
		use_real_trash_path =
			camel_imapx_settings_get_use_real_trash_path (
			CAMEL_IMAPX_SETTINGS (settings));
	}

	if (use_real_junk_path) {
		gchar *real_junk_path;

		real_junk_path =
			camel_imapx_settings_dup_real_junk_path (
			CAMEL_IMAPX_SETTINGS (settings));

		/* So we can safely compare strings. */
		if (real_junk_path == NULL)
			real_junk_path = g_strdup ("");

		if (g_ascii_strcasecmp (real_junk_path, folder_name) == 0)
			camel_folder_set_flags (folder, camel_folder_get_flags (folder) | CAMEL_FOLDER_IS_JUNK);

		g_free (real_junk_path);
	}

	if (use_real_trash_path) {
		gchar *real_trash_path;

		real_trash_path =
			camel_imapx_settings_dup_real_trash_path (
			CAMEL_IMAPX_SETTINGS (settings));

		/* So we can safely compare strings. */
		if (real_trash_path == NULL)
			real_trash_path = g_strdup ("");

		if (g_ascii_strcasecmp (real_trash_path, folder_name) == 0)
			camel_folder_set_flags (folder, camel_folder_get_flags (folder) | CAMEL_FOLDER_IS_TRASH);

		g_free (real_trash_path);
	}

	g_object_unref (settings);

	return folder;
}

static CamelFolderInfo *
imapx_store_get_folder_info_sync (CamelStore *store,
                                  const gchar *top,
                                  CamelStoreGetFolderInfoFlags flags,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelIMAPXStore *imapx_store;
	CamelFolderInfo *fi = NULL;
	CamelService *service;
	CamelSettings *settings;
	gboolean initial_setup = FALSE;
	gboolean use_subscriptions;

	service = CAMEL_SERVICE (store);
	imapx_store = CAMEL_IMAPX_STORE (store);

	settings = camel_service_ref_settings (service);

	use_subscriptions = camel_imapx_settings_get_use_subscriptions (
		CAMEL_IMAPX_SETTINGS (settings));

	g_object_unref (settings);

	if (top == NULL)
		top = "";

	g_mutex_lock (&imapx_store->priv->get_finfo_lock);

	if (!camel_offline_store_get_online (CAMEL_OFFLINE_STORE (store))) {
		fi = get_folder_info_offline (store, top, flags, cancellable, error);
		goto exit;
	}

	if (imapx_store->priv->last_refresh_time == 0 && !*top) {
		imapx_store->priv->last_refresh_time = time (NULL);
		initial_setup = TRUE;
	}

	/* XXX I don't know why the SUBSCRIBED flag matters here. */
	if (!initial_setup && (flags & CAMEL_STORE_FOLDER_INFO_SUBSCRIBED) != 0) {
		time_t time_since_last_refresh;

		time_since_last_refresh =
			time (NULL) - imapx_store->priv->last_refresh_time;

		if (time_since_last_refresh > FINFO_REFRESH_INTERVAL) {
			CamelSession *session;
			gchar *description;

			imapx_store->priv->last_refresh_time = time (NULL);

			session = camel_service_ref_session (service);
			if (session) {
				description = g_strdup_printf (_("Retrieving folder list for “%s”"), camel_service_get_display_name (service));

				camel_session_submit_job (
					session, description, (CamelSessionCallback)
					imapx_refresh_finfo,
					g_object_ref (store),
					(GDestroyNotify) g_object_unref);

				g_object_unref (session);
				g_free (description);
			}
		}
	}

	/* Avoid server interaction if the FAST flag is set. */
	if (!initial_setup && flags & CAMEL_STORE_FOLDER_INFO_FAST) {
		fi = get_folder_info_offline (store, top, flags, cancellable, error);
		goto exit;
	}

	if (!sync_folders (imapx_store, top, flags, initial_setup, cancellable, error))
		goto exit;

	camel_store_summary_save (imapx_store->summary);

	/* ensure the INBOX is subscribed if lsub was preferred*/
	if (initial_setup && use_subscriptions)
		discover_inbox (imapx_store, cancellable);

	fi = get_folder_info_offline (store, top, flags, cancellable, error);

exit:
	g_mutex_unlock (&imapx_store->priv->get_finfo_lock);

	return fi;
}

static CamelFolder *
imapx_store_get_junk_folder_sync (CamelStore *store,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelFolder *folder = NULL;
	CamelStoreClass *store_class;
	CamelSettings *settings;

	settings = camel_service_ref_settings (CAMEL_SERVICE (store));
	if (camel_imapx_settings_get_use_real_junk_path (CAMEL_IMAPX_SETTINGS (settings))) {
		gchar *real_junk_path;

		real_junk_path = camel_imapx_settings_dup_real_junk_path (CAMEL_IMAPX_SETTINGS (settings));
		if (real_junk_path) {
			folder = camel_store_get_folder_sync (store, real_junk_path, 0, cancellable, NULL);
			g_free (real_junk_path);
		}
	}
	g_object_unref (settings);

	if (folder)
		return folder;

	store_class = CAMEL_STORE_CLASS (camel_imapx_store_parent_class);
	folder = store_class->get_junk_folder_sync (store, cancellable, error);

	if (folder) {
		CamelObject *object = CAMEL_OBJECT (folder);
		CamelService *service;
		const gchar *user_cache_dir;
		gchar *state;

		service = CAMEL_SERVICE (store);
		user_cache_dir = camel_service_get_user_cache_dir (service);

		state = g_build_filename (
			user_cache_dir, "system", "Junk.cmeta", NULL);

		camel_object_set_state_filename (object, state);
		g_free (state);
		/* no defaults? */
		camel_object_state_read (object);
	}

	return folder;
}

static CamelFolder *
imapx_store_get_trash_folder_sync (CamelStore *store,
                                   GCancellable *cancellable,
                                   GError **error)
{
	CamelFolder *folder = NULL;
	CamelStoreClass *store_class;
	CamelSettings *settings;

	settings = camel_service_ref_settings (CAMEL_SERVICE (store));
	if (camel_imapx_settings_get_use_real_trash_path (CAMEL_IMAPX_SETTINGS (settings))) {
		gchar *real_trash_path;

		real_trash_path = camel_imapx_settings_dup_real_trash_path (CAMEL_IMAPX_SETTINGS (settings));
		if (real_trash_path) {
			folder = camel_store_get_folder_sync (store, real_trash_path, 0, cancellable, NULL);
			g_free (real_trash_path);
		}
	}
	g_object_unref (settings);

	if (folder)
		return folder;

	store_class = CAMEL_STORE_CLASS (camel_imapx_store_parent_class);
	folder = store_class->get_trash_folder_sync (store, cancellable, error);

	if (folder) {
		CamelObject *object = CAMEL_OBJECT (folder);
		CamelService *service;
		const gchar *user_cache_dir;
		gchar *state;

		service = CAMEL_SERVICE (store);
		user_cache_dir = camel_service_get_user_cache_dir (service);

		state = g_build_filename (
			user_cache_dir, "system", "Trash.cmeta", NULL);

		camel_object_set_state_filename (object, state);
		g_free (state);
		/* no defaults? */
		camel_object_state_read (object);
	}

	return folder;
}

static CamelFolderInfo *
imapx_store_create_folder_sync (CamelStore *store,
                                const gchar *parent_name,
                                const gchar *folder_name,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelIMAPXNamespaceResponse *namespace_response;
	CamelIMAPXNamespace *namespace;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelFolder *folder;
	CamelIMAPXMailbox *parent_mailbox = NULL;
	CamelFolderInfo *fi = NULL;
	GList *list;
	const gchar *namespace_prefix;
	const gchar *parent_mailbox_name;
	gchar *mailbox_name = NULL;
	gchar separator;
	gboolean success;

	imapx_store = CAMEL_IMAPX_STORE (store);
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	if (parent_name == NULL || *parent_name == '\0')
		goto check_namespace;

	/* Obtain the separator from the parent CamelIMAPXMailbox. */

	folder = camel_store_get_folder_sync (
		store, parent_name, 0, cancellable, error);

	if (folder != NULL) {
		parent_mailbox = camel_imapx_folder_list_mailbox (
			CAMEL_IMAPX_FOLDER (folder), cancellable, error);
		g_object_unref (folder);
	}

	if (parent_mailbox == NULL)
		goto exit;

	separator = camel_imapx_mailbox_get_separator (parent_mailbox);
	parent_mailbox_name = camel_imapx_mailbox_get_name (parent_mailbox);

	mailbox_name = g_strdup_printf (
		"%s%c%s", parent_mailbox_name, separator, folder_name);

	g_object_unref (parent_mailbox);

	goto check_separator;

check_namespace:

	/* Obtain the separator from the first personal namespace.
	 *
	 * FIXME The CamelFolder API provides no way to specify a
	 *       namespace prefix when creating a top-level mailbox,
	 *       This needs fixed to properly support IMAP namespaces.
	 */

	namespace_response = camel_imapx_store_ref_namespaces (imapx_store);
	g_return_val_if_fail (namespace_response != NULL, NULL);

	list = camel_imapx_namespace_response_list (namespace_response);
	g_return_val_if_fail (list != NULL, NULL);

	/* The namespace list is in the order received in the NAMESPACE
	 * response so the first element should be a personal namespace. */
	namespace = CAMEL_IMAPX_NAMESPACE (list->data);

	separator = camel_imapx_namespace_get_separator (namespace);
	namespace_prefix = camel_imapx_namespace_get_prefix (namespace);

	mailbox_name = g_strconcat (namespace_prefix, folder_name, NULL);

	g_list_free_full (list, (GDestroyNotify) g_object_unref);
	g_object_unref (namespace_response);

check_separator:

	if (strchr (folder_name, separator) != NULL) {
		g_set_error (
			error, CAMEL_FOLDER_ERROR,
			CAMEL_FOLDER_ERROR_INVALID_PATH,
			_("The folder name “%s” is invalid "
			"because it contains the character “%c”"),
			folder_name, separator);
		goto exit;
	}

	/* This also LISTs the mailbox after creating it, which
	 * triggers the CamelIMAPXStore::mailbox-created signal
	 * and all the local processing that goes along with it. */
	success = camel_imapx_conn_manager_create_mailbox_sync (conn_man, mailbox_name, cancellable, error);

	if (success) {
		fi = imapx_store_build_folder_info (
			imapx_store, folder_name,
			CAMEL_FOLDER_NOCHILDREN);
	}

exit:
	g_free (mailbox_name);

	return fi;
}

static gboolean
imapx_store_delete_folder_sync (CamelStore *store,
                                const gchar *folder_name,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelFolder *folder;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox = NULL;
	gboolean success = FALSE;

	folder = camel_store_get_folder_sync (
		store, folder_name, 0, cancellable, error);

	if (folder == NULL)
		return FALSE;

	imapx_store = CAMEL_IMAPX_STORE (store);
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	mailbox = camel_imapx_folder_list_mailbox (
		CAMEL_IMAPX_FOLDER (folder), cancellable, error);
	if (mailbox == NULL)
		goto exit;

	success = camel_imapx_conn_manager_delete_mailbox_sync (conn_man, mailbox, cancellable, error);

	if (success)
		imapx_delete_folder_from_cache (imapx_store, folder_name, TRUE);

exit:
	g_clear_object (&folder);
	g_clear_object (&mailbox);

	return success;
}

static gboolean
imapx_store_rename_folder_sync (CamelStore *store,
                                const gchar *old,
                                const gchar *new,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelFolder *folder;
	CamelService *service;
	CamelSettings *settings;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox = NULL;
	CamelIMAPXMailbox *cloned_mailbox;
	gchar *new_mailbox_name = NULL;
	gchar separator;
	gboolean use_subscriptions;
	gboolean success = FALSE;
	GError *local_error = NULL;

	service = CAMEL_SERVICE (store);
	imapx_store = CAMEL_IMAPX_STORE (store);

	settings = camel_service_ref_settings (service);

	use_subscriptions = camel_imapx_settings_get_use_subscriptions (
		CAMEL_IMAPX_SETTINGS (settings));

	g_object_unref (settings);

	/* This suppresses CamelStore signal emissions
	 * in imapx_store_process_mailbox_attributes(). */
	g_atomic_int_inc (&imapx_store->priv->syncing_folders);

	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	folder = camel_store_get_folder_sync (
		store, old, 0, cancellable, error);

	if (folder != NULL) {
		mailbox = camel_imapx_folder_list_mailbox (
			CAMEL_IMAPX_FOLDER (folder), cancellable, error);
		g_object_unref (folder);
	}

	if (mailbox == NULL)
		goto exit;

	/* Assume the renamed mailbox will remain in the same namespace,
	 * and therefore use the same separator character.  XXX I'm not
	 * sure if IMAP even allows inter-namespace mailbox renames. */
	separator = camel_imapx_mailbox_get_separator (mailbox);
	new_mailbox_name = camel_imapx_folder_path_to_mailbox (new, separator);

	if (use_subscriptions) {
		camel_imapx_conn_manager_unsubscribe_mailbox_sync (conn_man, mailbox, cancellable, &local_error);
		g_clear_error (&local_error);
	}

	success = camel_imapx_conn_manager_rename_mailbox_sync (conn_man, mailbox, new_mailbox_name, cancellable, &local_error);

	if (!success) {
		if (local_error)
			g_propagate_error (error, local_error);
		local_error = NULL;

		if (use_subscriptions) {
			gboolean success_2;

			success_2 = camel_imapx_conn_manager_subscribe_mailbox_sync (conn_man, mailbox, cancellable, &local_error);
			if (!success_2) {
				g_warning ("%s: Failed to subscribe '%s': %s", G_STRFUNC, camel_imapx_mailbox_get_name (mailbox),
					local_error ? local_error->message : "Unknown error");
			}
			g_clear_error (&local_error);
		}

		goto exit;
	}

	/* Rename summary, and handle broken server. */
	imapx_store_rename_folder_info (imapx_store, old, new);
	imapx_store_rename_storage_path (imapx_store, old, new);

	/* Create a cloned CamelIMAPXMailbox with the new mailbox name. */
	cloned_mailbox = camel_imapx_mailbox_clone (mailbox, new_mailbox_name);

	camel_imapx_folder_set_mailbox (CAMEL_IMAPX_FOLDER (folder), cloned_mailbox);

	if (use_subscriptions) {
		success = camel_imapx_conn_manager_subscribe_mailbox_sync (conn_man, cloned_mailbox, cancellable, error);
	}

	g_clear_object (&cloned_mailbox);

exit:
	g_free (new_mailbox_name);

	g_clear_object (&mailbox);

	/* This enables CamelStore signal emissions
	 * in imapx_store_process_mailbox_attributes() again. */
	(void) g_atomic_int_dec_and_test (&imapx_store->priv->syncing_folders);

	return success;
}

gboolean
camel_imapx_store_is_gmail_server (CamelIMAPXStore *imapx_store)
{
	CamelSettings *settings;
	gboolean is_gmail = FALSE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store), FALSE);

	settings = camel_service_ref_settings (CAMEL_SERVICE (imapx_store));
	if (CAMEL_IS_NETWORK_SETTINGS (settings)) {
		gchar *host;

		host = camel_network_settings_dup_host (CAMEL_NETWORK_SETTINGS (settings));

		is_gmail = host && (
			camel_strstrcase (host, ".gmail.com") != NULL ||
			camel_strstrcase (host, ".googlemail.com") != NULL);

		g_free (host);
	}

	g_clear_object (&settings);

	return is_gmail;
}

gboolean
camel_imapx_store_get_bodystructure_enabled (CamelIMAPXStore *store)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (store), FALSE);

	return store->priv->bodystructure_enabled;
}

void
camel_imapx_store_set_bodystructure_enabled (CamelIMAPXStore *store,
					     gboolean enabled)
{
	g_return_if_fail (CAMEL_IS_IMAPX_STORE (store));

	if ((!store->priv->bodystructure_enabled) != (!enabled))
		store->priv->bodystructure_enabled = enabled;
}

static gchar *
imapx_find_folder_for_initial_setup (CamelFolderInfo *root,
				     const gchar *path)
{
	CamelFolderInfo *finfo, *next;
	gchar *folder_fullname = NULL;
	gchar **path_parts;
	gint ii;

	if (!root || !path)
		return NULL;

	path_parts = g_strsplit (path, "/", -1);
	if (!path_parts)
		return NULL;

	finfo = root;

	for (ii = 0; path_parts[ii] && finfo; ii++) {
		gchar *folded_path;

		folded_path = g_utf8_casefold (path_parts[ii], -1);
		if (!folded_path)
			break;

		for (next = NULL; finfo; finfo = finfo->next) {
			gchar *folded_display_name;
			gint cmp;

			if ((finfo->flags & (CAMEL_FOLDER_NOSELECT | CAMEL_FOLDER_VIRTUAL)) != 0)
				continue;

			folded_display_name = g_utf8_casefold (finfo->display_name, -1);
			if (!folded_display_name)
				continue;

			cmp = g_utf8_collate (folded_path, folded_display_name);

			g_free (folded_display_name);

			if (cmp == 0) {
				next = finfo;
				break;
			}
		}

		g_free (folded_path);

		finfo = next;
		if (finfo) {
			if (path_parts[ii + 1])
				finfo = finfo->child;
			else
				folder_fullname = g_strdup (finfo->full_name);
		}
	}

	g_strfreev (path_parts);

	return folder_fullname;
}

static void
imapx_check_initial_setup_group (CamelIMAPXStore *imapx_store,
				 CamelFolderInfo *finfo,
				 GHashTable *save_setup,
				 const gchar *list_attribute,
				 const gchar *main_key,
				 const gchar *additional_key,
				 const gchar *additional_key_value,
				 const gchar **names,
				 guint n_names)
{
	gchar *folder_fullname = NULL;
	gint ii;

	g_return_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store));
	g_return_if_fail (finfo != NULL);
	g_return_if_fail (save_setup != NULL);
	g_return_if_fail (main_key != NULL);
	g_return_if_fail (names != NULL);
	g_return_if_fail (n_names > 0);

	/* Prefer RFC 6154 "SPECIAL-USE" Flags, which are not locale sensitive */
	if (list_attribute) {
		CamelIMAPXNamespaceResponse *namespace_response;

		namespace_response = camel_imapx_store_ref_namespaces (imapx_store);
		if (namespace_response) {
			GList *namespaces, *mailboxes, *link;
			CamelIMAPXNamespace *user_namespace = NULL;

			namespaces = camel_imapx_namespace_response_list (namespace_response);
			for (link = namespaces; link && !user_namespace; link = g_list_next (link)) {
				CamelIMAPXNamespace *candidate = link->data;

				if (!candidate || camel_imapx_namespace_get_category (candidate) != CAMEL_IMAPX_NAMESPACE_PERSONAL)
					continue;

				user_namespace = candidate;
			}

			if (user_namespace) {
				mailboxes = camel_imapx_store_list_mailboxes (imapx_store, user_namespace, NULL);

				for (link = mailboxes; link && !folder_fullname; link = g_list_next (link)) {
					CamelIMAPXMailbox *mailbox = link->data;

					if (!mailbox || !camel_imapx_mailbox_has_attribute (mailbox, list_attribute))
						continue;

					folder_fullname = camel_imapx_mailbox_dup_folder_path (mailbox);
				}

				g_list_free_full (mailboxes, g_object_unref);
			}

			g_list_free_full (namespaces, g_object_unref);
			g_object_unref (namespace_response);
		}
	}

	/* First check the folder names in the user's locale */
	for (ii = 0; ii < n_names && !folder_fullname; ii++) {
		gchar *name;

		/* In the same level as the Inbox */
		folder_fullname = imapx_find_folder_for_initial_setup (finfo, g_dpgettext2 (GETTEXT_PACKAGE, "IMAPDefaults", names[ii]));

		if (folder_fullname)
			break;

		/* as a subfolder of the Inbox */
		name = g_strconcat ("INBOX/", g_dpgettext2 (GETTEXT_PACKAGE, "IMAPDefaults", names[ii]), NULL);
		folder_fullname = imapx_find_folder_for_initial_setup (finfo, name);
		g_free (name);
	}

	/* Then repeat with the english name (as written in the code) */
	for (ii = 0; ii < n_names && !folder_fullname; ii++) {
		gchar *name;

		/* Do not try the same folder name twice */
		if (g_strcmp0 (g_dpgettext2 (GETTEXT_PACKAGE, "IMAPDefaults", names[ii]), names[ii]) == 0)
			continue;

		folder_fullname = imapx_find_folder_for_initial_setup (finfo, names[ii]);

		if (folder_fullname)
			break;

		name = g_strconcat ("INBOX/", names[ii], NULL);
		folder_fullname = imapx_find_folder_for_initial_setup (finfo, name);
		g_free (name);
	}

	if (folder_fullname) {
		g_hash_table_insert (save_setup,
			g_strdup (main_key),
			g_strdup (folder_fullname));

		if (additional_key) {
			g_hash_table_insert (save_setup,
				g_strdup (additional_key),
				g_strdup (additional_key_value));
		}

		g_free (folder_fullname);
	}
}

static gboolean
imapx_initial_setup_sync (CamelStore *store,
			  GHashTable *save_setup,
			  GCancellable *cancellable,
			  GError **error)
{
	const gchar *draft_names[] = {
		/* Translators: The strings in "IMAPDefaults" context are folder names as can be presented
		   by the server; There's checked for the localized version of it and for the non-localized
		   version as well. It's always the folder name (eventually path) as provided by the server,
		   when returned in given localization. it can be checked semi-easily in the case of
		   the GMail variants, by changing the GMail interface language in the GMail Preferences. */
		NC_("IMAPDefaults", "[Gmail]/Drafts"),
		NC_("IMAPDefaults", "Drafts"),
		NC_("IMAPDefaults", "Draft")
	};
	const gchar *templates_names[] = {
		NC_("IMAPDefaults", "Templates")
	};
	const gchar *archive_names[] = {
		NC_("IMAPDefaults", "Archive")
	};
	const gchar *sent_names[] = {
		NC_("IMAPDefaults", "[Gmail]/Sent Mail"),
		NC_("IMAPDefaults", "Sent"),
		NC_("IMAPDefaults", "Sent Items"),
		NC_("IMAPDefaults", "Sent Messages")
	};
	const gchar *junk_names[] = {
		NC_("IMAPDefaults", "[Gmail]/Spam"),
		NC_("IMAPDefaults", "Junk"),
		NC_("IMAPDefaults", "Junk E-mail"),
		NC_("IMAPDefaults", "Junk Email"),
		NC_("IMAPDefaults", "Spam"),
		NC_("IMAPDefaults", "Bulk Mail")
	};
	const gchar *trash_names[] = {
		NC_("IMAPDefaults", "[Gmail]/Trash"),
		NC_("IMAPDefaults", "Trash"),
		NC_("IMAPDefaults", "Deleted Items"),
		NC_("IMAPDefaults", "Deleted Messages")
	};

	CamelIMAPXStore *imapx_store;
	CamelFolderInfo *finfo;
	GError *local_error = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (store), FALSE);
	g_return_val_if_fail (save_setup != NULL, FALSE);

	finfo = camel_store_get_folder_info_sync (store, NULL,
		CAMEL_STORE_FOLDER_INFO_RECURSIVE | CAMEL_STORE_FOLDER_INFO_NO_VIRTUAL,
		cancellable, &local_error);

	if (!finfo) {
		if (local_error) {
			g_propagate_error (error, local_error);
			return FALSE;
		}

		return TRUE;
	}

	imapx_store = CAMEL_IMAPX_STORE (store);

	imapx_check_initial_setup_group (imapx_store, finfo, save_setup,
		CAMEL_IMAPX_LIST_ATTR_DRAFTS,
		CAMEL_STORE_SETUP_DRAFTS_FOLDER, NULL, NULL,
		draft_names, G_N_ELEMENTS (draft_names));

	imapx_check_initial_setup_group (imapx_store, finfo, save_setup, NULL,
		CAMEL_STORE_SETUP_TEMPLATES_FOLDER, NULL, NULL,
		templates_names, G_N_ELEMENTS (templates_names));

	imapx_check_initial_setup_group (imapx_store, finfo, save_setup,
		CAMEL_IMAPX_LIST_ATTR_ARCHIVE,
		CAMEL_STORE_SETUP_ARCHIVE_FOLDER, NULL, NULL,
		archive_names, G_N_ELEMENTS (archive_names));

	/* Skip changing Sent folder for GMail, because GMail stores sent messages
	   automatically, thus it would make doubled copies on the server. */
	if (!camel_imapx_store_is_gmail_server (imapx_store)) {
		imapx_check_initial_setup_group (imapx_store, finfo, save_setup,
			CAMEL_IMAPX_LIST_ATTR_SENT,
			CAMEL_STORE_SETUP_SENT_FOLDER, NULL, NULL,
			sent_names, G_N_ELEMENTS (sent_names));
	}

	/* It's a folder path inside the account, thus not use the 'f' type, but the 's' type. */
	imapx_check_initial_setup_group (imapx_store, finfo, save_setup,
		CAMEL_IMAPX_LIST_ATTR_JUNK,
		"Backend:Imapx Backend:real-junk-path:s",
		"Backend:Imapx Backend:use-real-junk-path:b", "true",
		junk_names, G_N_ELEMENTS (junk_names));

	/* It's a folder path inside the account, thus not use the 'f' type, but the 's' type. */
	imapx_check_initial_setup_group (imapx_store, finfo, save_setup,
		CAMEL_IMAPX_LIST_ATTR_TRASH,
		"Backend:Imapx Backend:real-trash-path:s",
		"Backend:Imapx Backend:use-real-trash-path:b", "true",
		trash_names, G_N_ELEMENTS (trash_names));

	camel_folder_info_free (finfo);

	return TRUE;
}

static void
imapx_store_dup_downsync_folders_recurse (CamelStore *store,
					  CamelFolderInfo *info,
					  GPtrArray **inout_folders)
{
	while (info) {
		CamelFolder *folder;

		if (info->child)
			imapx_store_dup_downsync_folders_recurse (store, info->child, inout_folders);

		folder = camel_store_get_folder_sync (store, info->full_name, 0, NULL, NULL);
		if (folder && CAMEL_IS_IMAPX_FOLDER (folder) &&
		    camel_offline_folder_can_downsync (CAMEL_OFFLINE_FOLDER (folder))) {
			if (!*inout_folders)
				*inout_folders = g_ptr_array_sized_new (32);
			g_ptr_array_add (*inout_folders, g_object_ref (folder));
		}

		g_clear_object (&folder);

		info = info->next;
	}
}

static GPtrArray *
imapx_store_dup_downsync_folders (CamelOfflineStore *offline_store)
{
	CamelStore *store;
	CamelFolderInfo *fi;
	GPtrArray *folders = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (offline_store), NULL);

	store = CAMEL_STORE (offline_store);

	fi = get_folder_info_offline (store, NULL,
		CAMEL_STORE_FOLDER_INFO_RECURSIVE | CAMEL_STORE_FOLDER_INFO_NO_VIRTUAL,
		NULL, NULL);

	imapx_store_dup_downsync_folders_recurse (store, fi, &folders);

	camel_folder_info_free (fi);

	return folders;
}

static void
imapx_migrate_to_user_cache_dir (CamelService *service)
{
	const gchar *user_data_dir, *user_cache_dir;

	g_return_if_fail (service != NULL);
	g_return_if_fail (CAMEL_IS_SERVICE (service));

	user_data_dir = camel_service_get_user_data_dir (service);
	user_cache_dir = camel_service_get_user_cache_dir (service);

	g_return_if_fail (user_data_dir != NULL);
	g_return_if_fail (user_cache_dir != NULL);

	/* migrate only if the source directory exists and the destination doesn't */
	if (g_file_test (user_data_dir, G_FILE_TEST_EXISTS | G_FILE_TEST_IS_DIR) &&
	    !g_file_test (user_cache_dir, G_FILE_TEST_EXISTS | G_FILE_TEST_IS_DIR)) {
		gchar *parent_dir;

		parent_dir = g_path_get_dirname (user_cache_dir);
		g_mkdir_with_parents (parent_dir, S_IRWXU);
		g_free (parent_dir);

		if (g_rename (user_data_dir, user_cache_dir) == -1 && errno != ENOENT)
			g_debug ("%s: Failed to migrate '%s' to '%s': %s", G_STRFUNC, user_data_dir, user_cache_dir, g_strerror (errno));
	}
}

static gboolean
imapx_store_initable_init (GInitable *initable,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelIMAPXStore *imapx_store;
	CamelStore *store;
	CamelService *service;
	const gchar *user_cache_dir;
	gchar *summary;

	imapx_store = CAMEL_IMAPX_STORE (initable);
	store = CAMEL_STORE (initable);
	service = CAMEL_SERVICE (initable);

	camel_store_set_flags (store, camel_store_get_flags (store) | CAMEL_STORE_USE_CACHE_DIR | CAMEL_STORE_SUPPORTS_INITIAL_SETUP);
	imapx_migrate_to_user_cache_dir (service);

	/* Chain up to parent interface's init() method. */
	if (!parent_initable_interface->init (initable, cancellable, error))
		return FALSE;

	service = CAMEL_SERVICE (initable);
	user_cache_dir = camel_service_get_user_cache_dir (service);

	imapx_store->summary =
		g_object_new (CAMEL_TYPE_IMAPX_STORE_SUMMARY, NULL);

	summary = g_build_filename (user_cache_dir, ".ev-store-summary", NULL);
	camel_store_summary_set_filename (imapx_store->summary, summary);
	if (camel_store_summary_load (imapx_store->summary) == -1) {
		camel_store_summary_touch (imapx_store->summary);
		camel_store_summary_save (imapx_store->summary);
	}

	g_free (summary);

	return TRUE;
}

static const gchar *
imapx_store_get_service_name (CamelNetworkService *service,
                              CamelNetworkSecurityMethod method)
{
	const gchar *service_name;

	switch (method) {
		case CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT:
			service_name = "imaps";
			break;

		default:
			service_name = "imap";
			break;
	}

	return service_name;
}

static guint16
imapx_store_get_default_port (CamelNetworkService *service,
                              CamelNetworkSecurityMethod method)
{
	guint16 default_port;

	switch (method) {
		case CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT:
			default_port = IMAPS_PORT;
			break;

		default:
			default_port = IMAP_PORT;
			break;
	}

	return default_port;
}

static gboolean
imapx_store_folder_is_subscribed (CamelSubscribable *subscribable,
                                  const gchar *folder_name)
{
	CamelIMAPXStore *imapx_store;
	CamelStoreInfo *si;
	gint is_subscribed = FALSE;

	imapx_store = CAMEL_IMAPX_STORE (subscribable);

	if (folder_name && *folder_name == '/')
		folder_name++;

	if (g_ascii_strcasecmp (folder_name, "INBOX") == 0)
		folder_name = "INBOX";

	si = camel_store_summary_path (imapx_store->summary, folder_name);
	if (si != NULL) {
		if (si->flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED)
			is_subscribed = TRUE;
		camel_store_summary_info_unref (imapx_store->summary, si);
	}

	return is_subscribed;
}

static void
imapx_ensure_parents_subscribed (CamelIMAPXStore *imapx_store,
				 const gchar *folder_name)
{
	GSList *parents = NULL, *iter;
	CamelSubscribable *subscribable;
	CamelFolderInfo *fi;
	gchar *parent, *sep;

	g_return_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store));
	g_return_if_fail (folder_name != NULL);

	subscribable = CAMEL_SUBSCRIBABLE (imapx_store);

	if (folder_name && *folder_name == '/')
		folder_name++;

	parent = g_strdup (folder_name);
	while (sep = strrchr (parent, '/'), sep) {
		*sep = '\0';

		fi = camel_folder_info_new ();

		fi->display_name = strrchr (parent, '/');
		if (fi->display_name != NULL)
			fi->display_name = g_strdup (fi->display_name + 1);
		else
			fi->display_name = g_strdup (parent);

		fi->full_name = g_strdup (parent);

		/* Since this is a "fake" folder node, it is not selectable. */
		fi->flags |= CAMEL_FOLDER_NOSELECT;
		fi->unread = -1;
		fi->total = -1;

		parents = g_slist_prepend (parents, fi);
	}

	for (iter = parents; iter; iter = g_slist_next (iter)) {
		fi = iter->data;

		camel_subscribable_folder_subscribed (subscribable, fi);
		camel_folder_info_free (fi);
	}

	g_slist_free (parents);
	g_free (parent);
}

static gboolean
imapx_store_subscribe_folder_sync (CamelSubscribable *subscribable,
                                   const gchar *folder_name,
                                   GCancellable *cancellable,
                                   GError **error)
{
	CamelFolder *folder;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox = NULL;
	gboolean success = FALSE;

	imapx_store = CAMEL_IMAPX_STORE (subscribable);
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	folder = camel_store_get_folder_sync (
		CAMEL_STORE (subscribable),
		folder_name, 0, cancellable, error);

	if (folder != NULL) {
		mailbox = camel_imapx_folder_list_mailbox (
			CAMEL_IMAPX_FOLDER (folder), cancellable, error);
		g_object_unref (folder);
	}

	if (mailbox == NULL)
		goto exit;

	success = camel_imapx_conn_manager_subscribe_mailbox_sync (conn_man, mailbox, cancellable, error);

	if (success) {
		CamelFolderInfo *fi;

		/* without this the folder is not visible if parents are not subscribed */
		imapx_ensure_parents_subscribed (imapx_store, folder_name);

		fi = imapx_store_build_folder_info (
			CAMEL_IMAPX_STORE (subscribable), folder_name, 0);
		camel_subscribable_folder_subscribed (subscribable, fi);
		camel_folder_info_free (fi);
	}

exit:
	g_clear_object (&mailbox);

	return success;
}

static gboolean
imapx_store_unsubscribe_folder_sync (CamelSubscribable *subscribable,
                                     const gchar *folder_name,
                                     GCancellable *cancellable,
                                     GError **error)
{
	CamelFolder *folder;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox = NULL;
	gboolean success = FALSE;

	imapx_store = CAMEL_IMAPX_STORE (subscribable);
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	folder = camel_store_get_folder_sync (
		CAMEL_STORE (subscribable),
		folder_name, 0, cancellable, error);

	if (folder != NULL) {
		mailbox = camel_imapx_folder_list_mailbox (
			CAMEL_IMAPX_FOLDER (folder), cancellable, error);
		g_object_unref (folder);
	}

	if (mailbox == NULL)
		goto exit;

	success = camel_imapx_conn_manager_unsubscribe_mailbox_sync (conn_man, mailbox, cancellable, error);

	if (success) {
		CamelFolderInfo *fi;

		fi = imapx_store_build_folder_info (
			CAMEL_IMAPX_STORE (subscribable), folder_name, 0);
		camel_subscribable_folder_unsubscribed (subscribable, fi);
		camel_folder_info_free (fi);
	}

exit:
	g_clear_object (&mailbox);

	return success;
}

static void
imapx_store_mailbox_created (CamelIMAPXStore *imapx_store,
			     CamelIMAPXMailbox *mailbox)
{
	e (
		'*',
		"%s::mailbox-created (\"%s\")\n",
		G_OBJECT_TYPE_NAME (imapx_store),
		camel_imapx_mailbox_get_name (mailbox));

	imapx_store_add_mailbox_to_folder (imapx_store, mailbox);
	imapx_store_process_mailbox_attributes (imapx_store, mailbox, NULL);
}

static void
imapx_store_mailbox_renamed (CamelIMAPXStore *imapx_store,
			     CamelIMAPXMailbox *mailbox,
			     const gchar *oldname)
{
	e (
		'*',
		"%s::mailbox-renamed (\"%s\" -> \"%s\")\n",
		G_OBJECT_TYPE_NAME (imapx_store), oldname,
		camel_imapx_mailbox_get_name (mailbox));

	imapx_store_process_mailbox_attributes (imapx_store, mailbox, oldname);
	imapx_store_process_mailbox_status (imapx_store, mailbox);
}

static void
imapx_store_mailbox_updated (CamelIMAPXStore *imapx_store,
			     CamelIMAPXMailbox *mailbox)
{
	e (
		'*',
		"%s::mailbox-updated (\"%s\")\n",
		G_OBJECT_TYPE_NAME (imapx_store),
		camel_imapx_mailbox_get_name (mailbox));

	imapx_store_process_mailbox_attributes (imapx_store, mailbox, NULL);
	imapx_store_process_mailbox_status (imapx_store, mailbox);
}

static void
camel_imapx_store_class_init (CamelIMAPXStoreClass *class)
{
	GObjectClass *object_class;
	CamelServiceClass *service_class;
	CamelStoreClass *store_class;
	CamelOfflineStoreClass *offline_store_class;

	g_type_class_add_private (class, sizeof (CamelIMAPXStorePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = imapx_store_set_property;
	object_class->get_property = imapx_store_get_property;
	object_class->dispose = imapx_store_dispose;
	object_class->finalize = imapx_store_finalize;
	object_class->notify = imapx_store_notify;

	service_class = CAMEL_SERVICE_CLASS (class);
	service_class->settings_type = CAMEL_TYPE_IMAPX_SETTINGS;
	service_class->get_name = imapx_get_name;
	service_class->connect_sync = imapx_connect_sync;
	service_class->disconnect_sync = imapx_disconnect_sync;
	service_class->authenticate_sync = imapx_authenticate_sync;
	service_class->query_auth_types_sync = imapx_query_auth_types_sync;

	store_class = CAMEL_STORE_CLASS (class);
	store_class->hash_folder_name = imapx_name_hash;
	store_class->equal_folder_name = imapx_name_equal;
	store_class->can_refresh_folder = imapx_can_refresh_folder;
	store_class->get_folder_sync = imapx_store_get_folder_sync;
	store_class->get_folder_info_sync = imapx_store_get_folder_info_sync;
	store_class->get_junk_folder_sync = imapx_store_get_junk_folder_sync;
	store_class->get_trash_folder_sync = imapx_store_get_trash_folder_sync;
	store_class->create_folder_sync = imapx_store_create_folder_sync;
	store_class->delete_folder_sync = imapx_store_delete_folder_sync;
	store_class->rename_folder_sync = imapx_store_rename_folder_sync;
	store_class->initial_setup_sync = imapx_initial_setup_sync;

	offline_store_class = CAMEL_OFFLINE_STORE_CLASS (class);
	offline_store_class->dup_downsync_folders = imapx_store_dup_downsync_folders;

	class->mailbox_created = imapx_store_mailbox_created;
	class->mailbox_renamed = imapx_store_mailbox_renamed;
	class->mailbox_updated = imapx_store_mailbox_updated;

	g_object_class_install_property (
		object_class,
		PROP_CONN_MANAGER,
		g_param_spec_object (
			"conn-manager",
			"Connection Manager",
			"The Connection Manager being used for remote operations",
			CAMEL_TYPE_IMAPX_CONN_MANAGER,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	/* Inherited from CamelNetworkService. */
	g_object_class_override_property (
		object_class,
		PROP_CONNECTABLE,
		"connectable");

	/* Inherited from CamelNetworkService. */
	g_object_class_override_property (
		object_class,
		PROP_HOST_REACHABLE,
		"host-reachable");

	signals[MAILBOX_CREATED] = g_signal_new (
		"mailbox-created",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (CamelIMAPXStoreClass, mailbox_created),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		CAMEL_TYPE_IMAPX_MAILBOX);

	signals[MAILBOX_RENAMED] = g_signal_new (
		"mailbox-renamed",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (CamelIMAPXStoreClass, mailbox_renamed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 2,
		CAMEL_TYPE_IMAPX_MAILBOX,
		G_TYPE_STRING);

	signals[MAILBOX_UPDATED] = g_signal_new (
		"mailbox-updated",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (CamelIMAPXStoreClass, mailbox_updated),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		CAMEL_TYPE_IMAPX_MAILBOX);
}

static void
camel_imapx_store_initable_init (GInitableIface *iface)
{
	parent_initable_interface = g_type_interface_peek_parent (iface);

	iface->init = imapx_store_initable_init;
}

static void
camel_network_service_init (CamelNetworkServiceInterface *iface)
{
	iface->get_service_name = imapx_store_get_service_name;
	iface->get_default_port = imapx_store_get_default_port;
}

static void
camel_subscribable_init (CamelSubscribableInterface *iface)
{
	iface->folder_is_subscribed = imapx_store_folder_is_subscribed;
	iface->subscribe_folder_sync = imapx_store_subscribe_folder_sync;
	iface->unsubscribe_folder_sync = imapx_store_unsubscribe_folder_sync;
}

static void
camel_imapx_store_init (CamelIMAPXStore *store)
{
	store->priv = CAMEL_IMAPX_STORE_GET_PRIVATE (store);

	store->priv->conn_man = camel_imapx_conn_manager_new (CAMEL_STORE (store));

	g_mutex_init (&store->priv->get_finfo_lock);

	g_mutex_init (&store->priv->namespaces_lock);
	g_mutex_init (&store->priv->mailboxes_lock);
	/* Hash table key is owned by the CamelIMAPXMailbox. */
	store->priv->mailboxes = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, g_object_unref);

	/* Initialize to zero to ensure we always obtain fresh folder
	 * info on startup.  See imapx_store_get_folder_info_sync(). */
	store->priv->last_refresh_time = 0;

	g_mutex_init (&store->priv->server_lock);

	store->priv->quota_info = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) camel_folder_quota_info_free);
	g_mutex_init (&store->priv->quota_info_lock);

	g_mutex_init (&store->priv->settings_lock);

	store->priv->bodystructure_enabled = TRUE;

	imapx_utils_init ();

	g_signal_connect (
		store, "notify::settings",
		G_CALLBACK (imapx_store_update_store_flags), NULL);
}

CamelIMAPXConnManager *
camel_imapx_store_get_conn_manager (CamelIMAPXStore *store)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (store), NULL);

	return store->priv->conn_man;
}

/* The caller should hold the store->priv->server_lock already, when calling this */
void
camel_imapx_store_set_connecting_server (CamelIMAPXStore *store,
					 CamelIMAPXServer *server,
					 gboolean is_concurrent_connection)
{
	g_return_if_fail (CAMEL_IS_IMAPX_STORE (store));

	if (server)
		g_return_if_fail (CAMEL_IS_IMAPX_SERVER (server));

	g_mutex_lock (&store->priv->server_lock);

	if (store->priv->connecting_server != server) {
		g_clear_object (&store->priv->connecting_server);
		if (server)
			store->priv->connecting_server = g_object_ref (server);
	}

	store->priv->is_concurrent_connection = is_concurrent_connection;

	g_mutex_unlock (&store->priv->server_lock);
}

gboolean
camel_imapx_store_is_connecting_concurrent_connection (CamelIMAPXStore *imapx_store)
{
	gboolean res;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store), FALSE);

	g_mutex_lock (&imapx_store->priv->server_lock);
	res = imapx_store->priv->is_concurrent_connection;
	g_mutex_unlock (&imapx_store->priv->server_lock);

	return res;
}

/**
 * camel_imapx_store_ref_namespaces:
 * @imapx_store: a #CamelIMAPXStore
 *
 * Returns the #CamelIMAPXNamespaceResponse for @is. This is obtained
 * during the connection phase if the IMAP server lists the "NAMESPACE"
 * keyword in its CAPABILITY response, or else is fabricated from the
 * first LIST response.
 *
 * The returned #CamelIMAPXNamespaceResponse is reference for thread-safety
 * and must be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelIMAPXNamespaceResponse
 *
 * Since: 3.16
 **/
CamelIMAPXNamespaceResponse *
camel_imapx_store_ref_namespaces (CamelIMAPXStore *imapx_store)
{
	CamelIMAPXNamespaceResponse *namespaces = NULL;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store), NULL);

	g_mutex_lock (&imapx_store->priv->namespaces_lock);

	if (imapx_store->priv->namespaces != NULL)
		namespaces = g_object_ref (imapx_store->priv->namespaces);

	g_mutex_unlock (&imapx_store->priv->namespaces_lock);

	return namespaces;
}

void
camel_imapx_store_set_namespaces (CamelIMAPXStore *imapx_store,
				  CamelIMAPXNamespaceResponse *namespaces)
{
	CamelIMAPXSettings *imapx_settings;
	gboolean ignore_other_users_namespace, ignore_shared_folders_namespace;

	g_return_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store));
	if (namespaces)
		g_return_if_fail (CAMEL_IS_IMAPX_NAMESPACE_RESPONSE (namespaces));

	if (namespaces)
		g_object_ref (namespaces);

	imapx_settings = CAMEL_IMAPX_SETTINGS (camel_service_ref_settings (CAMEL_SERVICE (imapx_store)));

	g_mutex_lock (&imapx_store->priv->namespaces_lock);

	g_clear_object (&imapx_store->priv->namespaces);
	imapx_store->priv->namespaces = namespaces;

	if (camel_imapx_settings_get_use_namespace (imapx_settings)) {
		gchar *use_namespace = camel_imapx_settings_dup_namespace (imapx_settings);

		if (use_namespace && *use_namespace) {
			/* Overwrite personal namespaces to the given */
			GList *nslist, *link;
			gchar folder_sep = 0;
			CamelIMAPXNamespace *override_ns = NULL;

			nslist = camel_imapx_namespace_response_list (namespaces);
			for (link = nslist; link; link = g_list_next (link)) {
				CamelIMAPXNamespace *ns = link->data;

				if (!folder_sep)
					folder_sep = camel_imapx_namespace_get_separator (ns);

				if (camel_imapx_namespace_get_category (ns) == CAMEL_IMAPX_NAMESPACE_PERSONAL) {
					if (!override_ns) {
						override_ns = camel_imapx_namespace_new (
							CAMEL_IMAPX_NAMESPACE_PERSONAL,
							use_namespace,
							camel_imapx_namespace_get_separator (ns));
					}

					camel_imapx_namespace_response_remove (namespaces, ns);
				}
			}

			if (!override_ns) {
				override_ns = camel_imapx_namespace_new (
					CAMEL_IMAPX_NAMESPACE_PERSONAL,
					use_namespace,
					folder_sep);
			}

			camel_imapx_namespace_response_add (namespaces, override_ns);

			g_list_free_full (nslist, g_object_unref);
			g_clear_object (&override_ns);
		}

		g_free (use_namespace);
	}

	ignore_other_users_namespace = camel_imapx_settings_get_ignore_other_users_namespace (imapx_settings);
	ignore_shared_folders_namespace = camel_imapx_settings_get_ignore_shared_folders_namespace (imapx_settings);

	if (ignore_other_users_namespace || ignore_shared_folders_namespace) {
		GList *nslist, *link;

		nslist = camel_imapx_namespace_response_list (namespaces);
		for (link = nslist; link; link = g_list_next (link)) {
			CamelIMAPXNamespace *ns = link->data;

			if ((ignore_other_users_namespace && camel_imapx_namespace_get_category (ns) == CAMEL_IMAPX_NAMESPACE_OTHER_USERS) ||
			    (ignore_shared_folders_namespace && camel_imapx_namespace_get_category (ns) == CAMEL_IMAPX_NAMESPACE_SHARED)) {
				camel_imapx_namespace_response_remove (namespaces, ns);
			}
		}

		g_list_free_full (nslist, g_object_unref);
	}

	g_mutex_unlock (&imapx_store->priv->namespaces_lock);

	g_clear_object (&imapx_settings);
}

static void
imapx_store_add_mailbox_unlocked (CamelIMAPXStore *imapx_store,
				  CamelIMAPXMailbox *mailbox)
{
	const gchar *mailbox_name;

	/* Acquire "mailboxes_lock" before calling. */

	mailbox_name = camel_imapx_mailbox_get_name (mailbox);
	g_return_if_fail (mailbox_name != NULL);

	/* Use g_hash_table_replace() here instead of g_hash_table_insert().
	 * The hash table key is owned by the hash table value, so if we're
	 * replacing an existing table item we want to replace both the key
	 * and value to avoid data corruption. */
	g_hash_table_replace (
		imapx_store->priv->mailboxes,
		(gpointer) mailbox_name,
		g_object_ref (mailbox));
}

static gboolean
imapx_store_remove_mailbox_unlocked (CamelIMAPXStore *imapx_store,
				     CamelIMAPXMailbox *mailbox)
{
	const gchar *mailbox_name;

	/* Acquire "mailboxes_lock" before calling. */

	mailbox_name = camel_imapx_mailbox_get_name (mailbox);
	g_return_val_if_fail (mailbox_name != NULL, FALSE);

	return g_hash_table_remove (imapx_store->priv->mailboxes, mailbox_name);
}

static CamelIMAPXMailbox *
imapx_store_ref_mailbox_unlocked (CamelIMAPXStore *imapx_store,
				  const gchar *mailbox_name)
{
	CamelIMAPXMailbox *mailbox;

	/* Acquire "mailboxes_lock" before calling. */

	g_return_val_if_fail (mailbox_name != NULL, NULL);

	/* The INBOX mailbox is case-insensitive. */
	if (g_ascii_strcasecmp (mailbox_name, "INBOX") == 0)
		mailbox_name = "INBOX";

	mailbox = g_hash_table_lookup (imapx_store->priv->mailboxes, mailbox_name);

	/* Remove non-existent mailboxes as we find them. */
	if (mailbox != NULL && !camel_imapx_mailbox_exists (mailbox)) {
		imapx_store_remove_mailbox_unlocked (imapx_store, mailbox);
		mailbox = NULL;
	}

	if (mailbox != NULL)
		g_object_ref (mailbox);

	return mailbox;
}

static GList *
imapx_store_list_mailboxes_unlocked (CamelIMAPXStore *imapx_store,
				     CamelIMAPXNamespace *namespace,
				     const gchar *pattern)
{
	GHashTableIter iter;
	GList *list = NULL;
	gpointer value;

	/* Acquire "mailboxes_lock" before calling. */

	if (pattern == NULL)
		pattern = "*";

	g_hash_table_iter_init (&iter, imapx_store->priv->mailboxes);

	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		CamelIMAPXMailbox *mailbox;
		CamelIMAPXNamespace *mailbox_ns;

		mailbox = CAMEL_IMAPX_MAILBOX (value);
		mailbox_ns = camel_imapx_mailbox_get_namespace (mailbox);

		if (!camel_imapx_mailbox_exists (mailbox))
			continue;

		if (!camel_imapx_namespace_equal (namespace, mailbox_ns))
			continue;

		if (!camel_imapx_mailbox_matches (mailbox, pattern))
			continue;

		list = g_list_prepend (list, g_object_ref (mailbox));
	}

	/* Sort the list by mailbox name. */
	return g_list_sort (list, (GCompareFunc) camel_imapx_mailbox_compare);
}

static CamelIMAPXMailbox *
imapx_store_create_mailbox_unlocked (CamelIMAPXStore *imapx_store,
				     CamelIMAPXListResponse *response)
{
	CamelIMAPXNamespaceResponse *namespace_response;
	CamelIMAPXNamespace *namespace;
	CamelIMAPXMailbox *mailbox = NULL;
	const gchar *mailbox_name;
	gchar separator;

	/* Acquire "mailboxes_lock" before calling. */

	namespace_response = camel_imapx_store_ref_namespaces (imapx_store);
	g_return_val_if_fail (namespace_response != NULL, FALSE);

	mailbox_name = camel_imapx_list_response_get_mailbox_name (response);
	separator = camel_imapx_list_response_get_separator (response);

	namespace = camel_imapx_namespace_response_lookup (
		namespace_response, mailbox_name, separator);

	if (namespace != NULL) {
		mailbox = camel_imapx_mailbox_new (response, namespace);
		imapx_store_add_mailbox_unlocked (imapx_store, mailbox);
		g_object_unref (namespace);

	/* XXX Slight hack, mainly for Courier servers.  If INBOX does
	 *     not match any defined namespace, just create one for it
	 *     on the fly.  The namespace response won't know about it. */
	} else if (camel_imapx_mailbox_is_inbox (mailbox_name)) {
		namespace = camel_imapx_namespace_new (
			CAMEL_IMAPX_NAMESPACE_PERSONAL, "", separator);
		mailbox = camel_imapx_mailbox_new (response, namespace);
		imapx_store_add_mailbox_unlocked (imapx_store, mailbox);
		g_object_unref (namespace);

	} else {
		g_warning (
			"%s: No matching namespace for \"%c\" %s",
			G_STRFUNC, separator, mailbox_name);
	}

	g_object_unref (namespace_response);

	return mailbox;
}

static CamelIMAPXMailbox *
imapx_store_rename_mailbox_unlocked (CamelIMAPXStore *imapx_store,
				     const gchar *old_mailbox_name,
				     const gchar *new_mailbox_name)
{
	CamelIMAPXMailbox *old_mailbox;
	CamelIMAPXMailbox *new_mailbox;
	CamelIMAPXNamespace *namespace;
	gsize old_mailbox_name_length;
	GList *list, *link;
	gchar separator;
	gchar *pattern;

	/* Acquire "mailboxes_lock" before calling. */

	g_return_val_if_fail (old_mailbox_name != NULL, NULL);
	g_return_val_if_fail (new_mailbox_name != NULL, NULL);

	old_mailbox = imapx_store_ref_mailbox_unlocked (imapx_store, old_mailbox_name);
	if (old_mailbox == NULL)
		return NULL;

	old_mailbox_name_length = strlen (old_mailbox_name);
	namespace = camel_imapx_mailbox_get_namespace (old_mailbox);
	separator = camel_imapx_mailbox_get_separator (old_mailbox);

	new_mailbox = camel_imapx_mailbox_clone (old_mailbox, new_mailbox_name);

	/* Add the new mailbox, remove the old mailbox.
	 * Note we still have a reference on the old mailbox. */
	imapx_store_add_mailbox_unlocked (imapx_store, new_mailbox);
	imapx_store_remove_mailbox_unlocked (imapx_store, old_mailbox);

	/* Rename any child mailboxes. */

	pattern = g_strdup_printf ("%s%c*", old_mailbox_name, separator);
	list = imapx_store_list_mailboxes_unlocked (imapx_store, namespace, pattern);

	for (link = list; link != NULL; link = g_list_next (link)) {
		CamelIMAPXMailbox *old_child;
		CamelIMAPXMailbox *new_child;
		const gchar *old_child_name;
		gchar *new_child_name;

		old_child = CAMEL_IMAPX_MAILBOX (link->data);
		old_child_name = camel_imapx_mailbox_get_name (old_child);

		/* Sanity checks. */
		g_warn_if_fail (
			old_child_name != NULL &&
			strlen (old_child_name) > old_mailbox_name_length &&
			old_child_name[old_mailbox_name_length] == separator);

		new_child_name = g_strconcat (
			new_mailbox_name,
			old_child_name + old_mailbox_name_length, NULL);

		new_child = camel_imapx_mailbox_clone (old_child, new_child_name);

		/* Add the new mailbox, remove the old mailbox.
		 * Note we still have a reference on the old mailbox. */
		imapx_store_add_mailbox_unlocked (imapx_store, new_child);
		imapx_store_remove_mailbox_unlocked (imapx_store, old_child);

		g_object_unref (new_child);
		g_free (new_child_name);
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);
	g_free (pattern);

	g_object_unref (old_mailbox);

	return new_mailbox;
}

/**
 * camel_imapx_store_ref_mailbox:
 * @imapx_store: a #CamelIMAPXStore
 * @mailbox_name: a mailbox name
 *
 * Looks up a #CamelIMAPXMailbox by its name. If no match is found, the function
 * returns %NULL.
 *
 * The returned #CamelIMAPXMailbox is referenced for thread-safety and
 * should be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: (nullable): a #CamelIMAPXMailbox, or %NULL
 *
 * Since: 3.16
 **/
CamelIMAPXMailbox *
camel_imapx_store_ref_mailbox (CamelIMAPXStore *imapx_store,
			       const gchar *mailbox_name)
{
	CamelIMAPXMailbox *mailbox;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store), NULL);
	g_return_val_if_fail (mailbox_name != NULL, NULL);

	g_mutex_lock (&imapx_store->priv->mailboxes_lock);

	mailbox = imapx_store_ref_mailbox_unlocked (imapx_store, mailbox_name);

	g_mutex_unlock (&imapx_store->priv->mailboxes_lock);

	return mailbox;
}

/**
 * camel_imapx_store_list_mailboxes:
 * @imapx_store: a #CamelIMAPXStore
 * @namespace_: a #CamelIMAPXNamespace
 * @pattern: mailbox name with possible wildcards, or %NULL
 *
 * Returns a list of #CamelIMAPXMailbox instances which match @namespace and
 * @pattern. The @pattern may contain wildcard characters '*' and '%', which
 * are interpreted similar to the IMAP LIST command. A %NULL @pattern lists
 * all mailboxes in @namespace; equivalent to passing "*".
 *
 * The mailboxes returned in the list are referenced for thread-safety.
 * They must each be unreferenced with g_object_unref() when finished with
 * them. Free the returned list itself with g_list_free().
 *
 * An easy way to free the list properly in one step is as follows:
 *
 * |[
 *   g_list_free_full (list, g_object_unref);
 * ]|
 *
 * Returns: a list of #CamelIMAPXMailbox instances
 *
 * Since: 3.16
 **/
GList *
camel_imapx_store_list_mailboxes (CamelIMAPXStore *imapx_store,
				  CamelIMAPXNamespace *namespace,
				  const gchar *pattern)
{
	GList *list;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store), NULL);
	g_return_val_if_fail (CAMEL_IS_IMAPX_NAMESPACE (namespace), NULL);

	g_mutex_lock (&imapx_store->priv->mailboxes_lock);

	list = imapx_store_list_mailboxes_unlocked (imapx_store, namespace, pattern);

	g_mutex_unlock (&imapx_store->priv->mailboxes_lock);

	return list;
}

void
camel_imapx_store_emit_mailbox_updated (CamelIMAPXStore *imapx_store,
					CamelIMAPXMailbox *mailbox)
{
	g_return_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store));
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	g_signal_emit (imapx_store, signals[MAILBOX_UPDATED], 0, mailbox);
}

void
camel_imapx_store_handle_mailbox_rename (CamelIMAPXStore *imapx_store,
					 CamelIMAPXMailbox *old_mailbox,
					 const gchar *new_mailbox_name)
{
	CamelIMAPXMailbox *new_mailbox;
	const gchar *old_mailbox_name;

	g_return_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store));
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (old_mailbox));
	g_return_if_fail (new_mailbox_name != NULL);

	old_mailbox_name = camel_imapx_mailbox_get_name (old_mailbox);

	g_mutex_lock (&imapx_store->priv->mailboxes_lock);
	new_mailbox = imapx_store_rename_mailbox_unlocked (
		imapx_store, old_mailbox_name, new_mailbox_name);
	g_mutex_unlock (&imapx_store->priv->mailboxes_lock);

	g_warn_if_fail (new_mailbox != NULL);

	g_signal_emit (
		imapx_store, signals[MAILBOX_RENAMED], 0,
		new_mailbox, old_mailbox_name);

	g_clear_object (&new_mailbox);
}

void
camel_imapx_store_handle_list_response (CamelIMAPXStore *imapx_store,
					CamelIMAPXServer *imapx_server,
					CamelIMAPXListResponse *response)
{
	CamelIMAPXMailbox *mailbox = NULL;
	const gchar *mailbox_name;
	const gchar *old_mailbox_name;
	gboolean emit_mailbox_created = FALSE;
	gboolean emit_mailbox_renamed = FALSE;
	gboolean emit_mailbox_updated = FALSE;

	g_return_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store));
	g_return_if_fail (CAMEL_IS_IMAPX_SERVER (imapx_server));
	g_return_if_fail (CAMEL_IS_IMAPX_LIST_RESPONSE (response));

	mailbox_name = camel_imapx_list_response_get_mailbox_name (response);
	old_mailbox_name = camel_imapx_list_response_get_oldname (response);

	/* Fabricate a CamelIMAPXNamespaceResponse if the server lacks the
	 * NAMESPACE capability and this is the first LIST / LSUB response. */
	if (camel_imapx_server_lack_capability (imapx_server, IMAPX_CAPABILITY_NAMESPACE)) {
		g_mutex_lock (&imapx_store->priv->namespaces_lock);
		if (imapx_store->priv->namespaces == NULL) {
			imapx_store->priv->namespaces = camel_imapx_namespace_response_faux_new (response);
		}
		g_mutex_unlock (&imapx_store->priv->namespaces_lock);
	}

	/* Create, rename, or update a corresponding CamelIMAPXMailbox. */
	g_mutex_lock (&imapx_store->priv->mailboxes_lock);
	if (old_mailbox_name != NULL) {
		mailbox = imapx_store_rename_mailbox_unlocked (
			imapx_store, old_mailbox_name, mailbox_name);
		emit_mailbox_renamed = (mailbox != NULL);
		if (mailbox && camel_imapx_mailbox_get_state (mailbox) == CAMEL_IMAPX_MAILBOX_STATE_UNKNOWN)
			camel_imapx_mailbox_set_state (mailbox, CAMEL_IMAPX_MAILBOX_STATE_RENAMED);
	}
	if (mailbox == NULL) {
		mailbox = imapx_store_ref_mailbox_unlocked (imapx_store, mailbox_name);
		emit_mailbox_updated = (mailbox != NULL);
		if (mailbox && camel_imapx_mailbox_get_state (mailbox) == CAMEL_IMAPX_MAILBOX_STATE_UNKNOWN)
			camel_imapx_mailbox_set_state (mailbox, CAMEL_IMAPX_MAILBOX_STATE_UPDATED);
	}
	if (mailbox == NULL) {
		mailbox = imapx_store_create_mailbox_unlocked (imapx_store, response);
		emit_mailbox_created = (mailbox != NULL);
		if (mailbox)
			camel_imapx_mailbox_set_state (mailbox, CAMEL_IMAPX_MAILBOX_STATE_CREATED);
	} else {
		camel_imapx_mailbox_handle_list_response (mailbox, response);
	}
	g_mutex_unlock (&imapx_store->priv->mailboxes_lock);

	if (emit_mailbox_created)
		g_signal_emit (imapx_store, signals[MAILBOX_CREATED], 0, mailbox);

	if (emit_mailbox_renamed)
		g_signal_emit (
			imapx_store, signals[MAILBOX_RENAMED], 0,
			mailbox, old_mailbox_name);

	if (emit_mailbox_updated)
		g_signal_emit (imapx_store, signals[MAILBOX_UPDATED], 0, mailbox);

	g_clear_object (&mailbox);
}

void
camel_imapx_store_handle_lsub_response (CamelIMAPXStore *imapx_store,
					CamelIMAPXServer *imapx_server,
					CamelIMAPXListResponse *response)
{
	CamelIMAPXMailbox *mailbox;
	const gchar *mailbox_name;
	gboolean emit_mailbox_updated = FALSE;

	g_return_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store));
	g_return_if_fail (CAMEL_IS_IMAPX_SERVER (imapx_server));
	g_return_if_fail (CAMEL_IS_IMAPX_LIST_RESPONSE (response));

	mailbox_name = camel_imapx_list_response_get_mailbox_name (response);

	/* Fabricate a CamelIMAPXNamespaceResponse if the server lacks the
	 * NAMESPACE capability and this is the first LIST / LSUB response. */
	if (camel_imapx_server_lack_capability (imapx_server, IMAPX_CAPABILITY_NAMESPACE)) {
		g_mutex_lock (&imapx_store->priv->namespaces_lock);
		if (imapx_store->priv->namespaces == NULL) {
			imapx_store->priv->namespaces = camel_imapx_namespace_response_faux_new (response);
		}
		g_mutex_unlock (&imapx_store->priv->namespaces_lock);
	}

	/* Update a corresponding CamelIMAPXMailbox.
	 *
	 * Note, don't create the CamelIMAPXMailbox like we do for a LIST
	 * response.  We always issue LIST before LSUB on a mailbox name,
	 * so if we don't already have a CamelIMAPXMailbox instance then
	 * this is a subscription on a non-existent mailbox.  Skip it. */
	g_mutex_lock (&imapx_store->priv->mailboxes_lock);
	mailbox = imapx_store_ref_mailbox_unlocked (imapx_store, mailbox_name);
	if (mailbox != NULL) {
		camel_imapx_mailbox_handle_lsub_response (mailbox, response);
		if (camel_imapx_mailbox_get_state (mailbox) == CAMEL_IMAPX_MAILBOX_STATE_UNKNOWN)
			camel_imapx_mailbox_set_state (mailbox, CAMEL_IMAPX_MAILBOX_STATE_UPDATED);
		emit_mailbox_updated = TRUE;
	}
	g_mutex_unlock (&imapx_store->priv->mailboxes_lock);

	if (emit_mailbox_updated)
		g_signal_emit (imapx_store, signals[MAILBOX_UPDATED], 0, mailbox);

	g_clear_object (&mailbox);
}

CamelFolderQuotaInfo *
camel_imapx_store_dup_quota_info (CamelIMAPXStore *store,
                                  const gchar *quota_root_name)
{
	CamelFolderQuotaInfo *info;

	g_return_val_if_fail (CAMEL_IS_IMAPX_STORE (store), NULL);
	g_return_val_if_fail (quota_root_name != NULL, NULL);

	g_mutex_lock (&store->priv->quota_info_lock);

	info = g_hash_table_lookup (
		store->priv->quota_info, quota_root_name);

	/* camel_folder_quota_info_clone() handles NULL gracefully. */
	info = camel_folder_quota_info_clone (info);

	g_mutex_unlock (&store->priv->quota_info_lock);

	return info;
}

void
camel_imapx_store_set_quota_info (CamelIMAPXStore *store,
                                  const gchar *quota_root_name,
                                  const CamelFolderQuotaInfo *info)
{
	g_return_if_fail (CAMEL_IS_IMAPX_STORE (store));
	g_return_if_fail (quota_root_name != NULL);

	g_mutex_lock (&store->priv->quota_info_lock);

	/* camel_folder_quota_info_clone() handles NULL gracefully. */
	g_hash_table_insert (
		store->priv->quota_info,
		g_strdup (quota_root_name),
		camel_folder_quota_info_clone (info));

	g_mutex_unlock (&store->priv->quota_info_lock);
}

/* for debugging purposes only */
void
camel_imapx_store_dump_queue_status (CamelIMAPXStore *imapx_store)
{
	g_return_if_fail (CAMEL_IS_IMAPX_STORE (imapx_store));

	camel_imapx_conn_manager_dump_queue_status (imapx_store->priv->conn_man);
}
