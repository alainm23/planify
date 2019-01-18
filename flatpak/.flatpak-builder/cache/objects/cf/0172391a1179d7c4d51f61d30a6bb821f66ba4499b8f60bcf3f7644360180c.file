/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-imap-folder.c : class for a imap folder
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

#include <errno.h>
#include <glib/gi18n-lib.h>

#include "camel-imapx-folder.h"
#include "camel-imapx-search.h"
#include "camel-imapx-server.h"
#include "camel-imapx-settings.h"
#include "camel-imapx-store.h"
#include "camel-imapx-summary.h"
#include "camel-imapx-utils.h"

#include <stdlib.h>
#include <string.h>

#define d(...) camel_imapx_debug(debug, '?', __VA_ARGS__)

#define CAMEL_IMAPX_FOLDER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_IMAPX_FOLDER, CamelIMAPXFolderPrivate))

struct _CamelIMAPXFolderPrivate {
	GMutex property_lock;
	GWeakRef mailbox;

	GMutex move_to_hash_table_lock;
	GHashTable *move_to_real_junk_uids;
	GHashTable *move_to_real_trash_uids;
	GHashTable *move_to_inbox_uids;

	gboolean check_folder;
};

/* The custom property ID is a CamelArg artifact.
 * It still identifies the property in state files. */
enum {
	PROP_0,
	PROP_MAILBOX,
	PROP_APPLY_FILTERS = 0x2501,
	PROP_CHECK_FOLDER = 0x2502
};

G_DEFINE_TYPE (CamelIMAPXFolder, camel_imapx_folder, CAMEL_TYPE_OFFLINE_FOLDER)

static gboolean imapx_folder_get_apply_filters (CamelIMAPXFolder *folder);

void
camel_imapx_folder_claim_move_to_real_junk_uids (CamelIMAPXFolder *folder,
						 GPtrArray *out_uids_to_copy)
{
	GList *keys;

	g_mutex_lock (&folder->priv->move_to_hash_table_lock);

	keys = g_hash_table_get_keys (folder->priv->move_to_real_junk_uids);
	g_hash_table_steal_all (folder->priv->move_to_real_junk_uids);

	g_mutex_unlock (&folder->priv->move_to_hash_table_lock);

	while (keys != NULL) {
		g_ptr_array_add (out_uids_to_copy, keys->data);
		keys = g_list_delete_link (keys, keys);
	}
}

void
camel_imapx_folder_claim_move_to_real_trash_uids (CamelIMAPXFolder *folder,
						  GPtrArray *out_uids_to_copy)
{
	GList *keys;

	g_mutex_lock (&folder->priv->move_to_hash_table_lock);

	keys = g_hash_table_get_keys (folder->priv->move_to_real_trash_uids);
	g_hash_table_steal_all (folder->priv->move_to_real_trash_uids);

	g_mutex_unlock (&folder->priv->move_to_hash_table_lock);

	while (keys != NULL) {
		g_ptr_array_add (out_uids_to_copy, keys->data);
		keys = g_list_delete_link (keys, keys);
	}
}

void
camel_imapx_folder_claim_move_to_inbox_uids (CamelIMAPXFolder *folder,
					     GPtrArray *out_uids_to_copy)
{
	GList *keys;

	g_mutex_lock (&folder->priv->move_to_hash_table_lock);

	keys = g_hash_table_get_keys (folder->priv->move_to_inbox_uids);
	g_hash_table_steal_all (folder->priv->move_to_inbox_uids);

	g_mutex_unlock (&folder->priv->move_to_hash_table_lock);

	while (keys != NULL) {
		g_ptr_array_add (out_uids_to_copy, keys->data);
		keys = g_list_delete_link (keys, keys);
	}
}

static gboolean
imapx_folder_get_apply_filters (CamelIMAPXFolder *folder)
{
	g_return_val_if_fail (folder != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_FOLDER (folder), FALSE);

	return folder->apply_filters;
}

static void
imapx_folder_set_apply_filters (CamelIMAPXFolder *folder,
                                gboolean apply_filters)
{
	g_return_if_fail (folder != NULL);
	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (folder));

	if (folder->apply_filters == apply_filters)
		return;

	folder->apply_filters = apply_filters;

	g_object_notify (G_OBJECT (folder), "apply-filters");
}

static void
imapx_folder_set_property (GObject *object,
                           guint property_id,
                           const GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_APPLY_FILTERS:
			imapx_folder_set_apply_filters (
				CAMEL_IMAPX_FOLDER (object),
				g_value_get_boolean (value));
			return;

		case PROP_CHECK_FOLDER:
			camel_imapx_folder_set_check_folder (
				CAMEL_IMAPX_FOLDER (object),
				g_value_get_boolean (value));
			return;

		case PROP_MAILBOX:
			camel_imapx_folder_set_mailbox (
				CAMEL_IMAPX_FOLDER (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
imapx_folder_get_property (GObject *object,
                           guint property_id,
                           GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_APPLY_FILTERS:
			g_value_set_boolean (
				value,
				imapx_folder_get_apply_filters (
				CAMEL_IMAPX_FOLDER (object)));
			return;

		case PROP_CHECK_FOLDER:
			g_value_set_boolean (
				value,
				camel_imapx_folder_get_check_folder (
				CAMEL_IMAPX_FOLDER (object)));
			return;

		case PROP_MAILBOX:
			g_value_take_object (
				value,
				camel_imapx_folder_ref_mailbox (
				CAMEL_IMAPX_FOLDER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
imapx_folder_dispose (GObject *object)
{
	CamelIMAPXFolder *folder = CAMEL_IMAPX_FOLDER (object);
	CamelStore *store;

	if (folder->cache != NULL) {
		g_object_unref (folder->cache);
		folder->cache = NULL;
	}

	if (folder->search != NULL) {
		g_object_unref (folder->search);
		folder->search = NULL;
	}

	store = camel_folder_get_parent_store (CAMEL_FOLDER (folder));
	if (store != NULL) {
		camel_store_summary_disconnect_folder_summary (
			CAMEL_IMAPX_STORE (store)->summary,
			camel_folder_get_folder_summary (CAMEL_FOLDER (folder)));
	}

	g_weak_ref_set (&folder->priv->mailbox, NULL);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_imapx_folder_parent_class)->dispose (object);
}

static void
imapx_folder_finalize (GObject *object)
{
	CamelIMAPXFolder *folder = CAMEL_IMAPX_FOLDER (object);

	g_mutex_clear (&folder->search_lock);
	g_mutex_clear (&folder->stream_lock);

	g_mutex_clear (&folder->priv->property_lock);

	g_mutex_clear (&folder->priv->move_to_hash_table_lock);
	g_hash_table_destroy (folder->priv->move_to_real_junk_uids);
	g_hash_table_destroy (folder->priv->move_to_real_trash_uids);
	g_hash_table_destroy (folder->priv->move_to_inbox_uids);

	g_weak_ref_clear (&folder->priv->mailbox);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_imapx_folder_parent_class)->finalize (object);
}

/* Algorithm for selecting a folder:
 *
 *  - If uidvalidity == old uidvalidity
 *    and exsists == old exists
 *    and recent == old recent
 *    and unseen == old unseen
 *    Assume our summary is correct
 *  for each summary item
 *    mark the summary item as 'old/not updated'
 *  rof
 *  fetch flags from 1:*
 *  for each fetch response
 *    info = summary[index]
 *    if info.uid != uid
 *      info = summary_by_uid[uid]
 *    fi
 *    if info == NULL
 *      create new info @ index
 *    fi
 *    if got.flags
 *      update flags
 *    fi
 *    if got.header
 *      update based on header
 *      mark as retrieved
 *    else if got.body
 *      update based on imap body
 *      mark as retrieved
 *    fi
 *
 *  Async fetch response:
 *    info = summary[index]
 *    if info == null
 *       if uid == null
 *          force resync/select?
 *       info = empty @ index
 *    else if uid && info.uid != uid
 *       force a resync?
 *       return
 *    fi
 *
 *    if got.flags {
 *      info.flags = flags
 *    }
 *    if got.header {
 *      info.init (header)
 *      info.empty = false
 *    }
 *
 * info.state - 2 bit field in flags
 *   0 = empty, nothing set
 *   1 = uid & flags set
 *   2 = update required
 *   3 = up to date
 */

static void
imapx_search_free (CamelFolder *folder,
                   GPtrArray *uids)
{
	CamelIMAPXFolder *imapx_folder;

	imapx_folder = CAMEL_IMAPX_FOLDER (folder);

	g_return_if_fail (imapx_folder->search);

	g_mutex_lock (&imapx_folder->search_lock);

	camel_folder_search_free_result (imapx_folder->search, uids);

	g_mutex_unlock (&imapx_folder->search_lock);
}

static GPtrArray *
imapx_search_by_uids (CamelFolder *folder,
                      const gchar *expression,
                      GPtrArray *uids,
                      GCancellable *cancellable,
                      GError **error)
{
	CamelIMAPXFolder *imapx_folder;
	CamelIMAPXSearch *imapx_search;
	GPtrArray *matches;

	if (uids->len == 0)
		return g_ptr_array_new ();

	imapx_folder = CAMEL_IMAPX_FOLDER (folder);

	g_mutex_lock (&imapx_folder->search_lock);

	imapx_search = CAMEL_IMAPX_SEARCH (imapx_folder->search);

	camel_folder_search_set_folder (imapx_folder->search, folder);
	camel_imapx_search_set_cancellable_and_error (imapx_search, cancellable, error);

	matches = camel_folder_search_search (
		imapx_folder->search, expression, uids, cancellable, error);

	camel_imapx_search_set_cancellable_and_error (imapx_search, NULL, NULL);

	g_mutex_unlock (&imapx_folder->search_lock);

	return matches;
}

static guint32
imapx_count_by_expression (CamelFolder *folder,
                           const gchar *expression,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelIMAPXFolder *imapx_folder;
	CamelIMAPXSearch *imapx_search;
	guint32 matches;

	imapx_folder = CAMEL_IMAPX_FOLDER (folder);

	g_mutex_lock (&imapx_folder->search_lock);

	imapx_search = CAMEL_IMAPX_SEARCH (imapx_folder->search);

	camel_folder_search_set_folder (imapx_folder->search, folder);
	camel_imapx_search_set_cancellable_and_error (imapx_search, cancellable, error);

	matches = camel_folder_search_count (
		imapx_folder->search, expression, cancellable, error);

	camel_imapx_search_set_cancellable_and_error (imapx_search, NULL, NULL);

	g_mutex_unlock (&imapx_folder->search_lock);

	return matches;
}

static GPtrArray *
imapx_search_by_expression (CamelFolder *folder,
                            const gchar *expression,
                            GCancellable *cancellable,
                            GError **error)
{
	CamelIMAPXFolder *imapx_folder;
	CamelIMAPXSearch *imapx_search;
	GPtrArray *matches;

	imapx_folder = CAMEL_IMAPX_FOLDER (folder);

	g_mutex_lock (&imapx_folder->search_lock);

	imapx_search = CAMEL_IMAPX_SEARCH (imapx_folder->search);

	camel_folder_search_set_folder (imapx_folder->search, folder);
	camel_imapx_search_set_cancellable_and_error (imapx_search, cancellable, error);

	matches = camel_folder_search_search (
		imapx_folder->search, expression, NULL, cancellable, error);

	camel_imapx_search_set_cancellable_and_error (imapx_search, NULL, NULL);

	g_mutex_unlock (&imapx_folder->search_lock);

	return matches;
}

static GPtrArray *
imapx_get_uncached_uids (CamelFolder *folder,
			 GPtrArray *uids,
			 GError **error)
{
	CamelIMAPXFolder *imapx_folder;
	GPtrArray *result;
	guint ii;

	g_return_val_if_fail (CAMEL_IS_IMAPX_FOLDER (folder), NULL);
	g_return_val_if_fail (uids != NULL, NULL);

	imapx_folder = CAMEL_IMAPX_FOLDER (folder);

	result = g_ptr_array_sized_new (uids->len);

	for (ii = 0; ii < uids->len; ii++) {
		const gchar *uid = uids->pdata[ii];
		GIOStream *io_stream;

		/* Assume that UIDs with existing stream are valid;
		   the imapx_get_message_cached() can fail with broken files, but it's rather unlikely. */
		io_stream = camel_data_cache_get (imapx_folder->cache, "cur", uid, NULL);
		if (io_stream)
			g_object_unref (io_stream);
		else
			g_ptr_array_add (result, (gpointer) camel_pstring_strdup (uid));
	}

	return result;
}

static gchar *
imapx_get_filename (CamelFolder *folder,
                    const gchar *uid,
                    GError **error)
{
	CamelIMAPXFolder *imapx_folder;

	imapx_folder = CAMEL_IMAPX_FOLDER (folder);

	return camel_data_cache_get_filename (
		imapx_folder->cache, "cache", uid);
}

static gboolean
imapx_append_message_sync (CamelFolder *folder,
                           CamelMimeMessage *message,
                           CamelMessageInfo *info,
                           gchar **appended_uid,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelStore *store;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox = NULL;
	gboolean success = FALSE;

	if (appended_uid != NULL)
		*appended_uid = NULL;

	store = camel_folder_get_parent_store (folder);

	imapx_store = CAMEL_IMAPX_STORE (store);
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	mailbox = camel_imapx_folder_list_mailbox (
		CAMEL_IMAPX_FOLDER (folder), cancellable, error);

	if (mailbox == NULL)
		goto exit;

	success = camel_imapx_conn_manager_append_message_sync (
		conn_man, mailbox, camel_folder_get_folder_summary (folder),
		CAMEL_IMAPX_FOLDER (folder)->cache, message,
		info, appended_uid, cancellable, error);

exit:
	g_clear_object (&mailbox);

	return success;
}

static gboolean
imapx_expunge_sync (CamelFolder *folder,
                    GCancellable *cancellable,
                    GError **error)
{
	CamelStore *store;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox = NULL;
	GError *local_error = NULL;
	gboolean success = FALSE;

	store = camel_folder_get_parent_store (folder);

	imapx_store = CAMEL_IMAPX_STORE (store);
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	mailbox = camel_imapx_folder_list_mailbox (
		CAMEL_IMAPX_FOLDER (folder), cancellable, error);

	if (mailbox == NULL)
		goto exit;

	if ((camel_store_get_flags (store) & CAMEL_STORE_VTRASH) == 0) {
		CamelFolder *trash;
		const gchar *full_name;

		full_name = camel_folder_get_full_name (folder);

		trash = camel_store_get_trash_folder_sync (store, cancellable, &local_error);

		if (local_error == NULL && trash && (folder == trash || g_ascii_strcasecmp (full_name, camel_folder_get_full_name (trash)) == 0)) {
			CamelFolderSummary *folder_summary;
			CamelMessageInfo *info;
			GPtrArray *known_uids;
			gint ii;

			folder_summary = camel_folder_get_folder_summary (folder);
			camel_folder_summary_lock (folder_summary);

			camel_folder_summary_prepare_fetch_all (folder_summary, NULL);
			known_uids = camel_folder_summary_get_array (folder_summary);

			/* it's a real trash folder, thus delete all mails from there */
			for (ii = 0; known_uids && ii < known_uids->len; ii++) {
				info = camel_folder_summary_get (camel_folder_get_folder_summary (folder), g_ptr_array_index (known_uids, ii));
				if (info) {
					camel_message_info_set_flags (info, CAMEL_MESSAGE_DELETED, CAMEL_MESSAGE_DELETED);
					g_clear_object (&info);
				}
			}

			camel_folder_summary_unlock (folder_summary);

			camel_folder_summary_free_array (known_uids);
		}

		g_clear_object (&trash);
		g_clear_error (&local_error);
	}

	success = camel_imapx_conn_manager_expunge_sync (conn_man, mailbox, cancellable, error);

exit:
	g_clear_object (&mailbox);

	return success;
}

static CamelMimeMessage *
imapx_message_from_stream_sync (CamelIMAPXFolder *imapx_folder,
				CamelStream *stream,
				GCancellable *cancellable,
				GError **error)
{
	CamelMimeMessage *msg;

	g_return_val_if_fail (CAMEL_IS_IMAPX_FOLDER (imapx_folder), NULL);

	if (!stream)
		return NULL;

	msg = camel_mime_message_new ();

	g_mutex_lock (&imapx_folder->stream_lock);

	/* Make sure the stream is at the beginning. It can be, when there are two
	   concurrent requests for a message, they both use the same underlying stream
	   from the local cache (encapsulated in the CamelStream), where one reads
	   it completely and lefts it at the end, thus the second caller reads
	   the stream from a wrong position. */
	g_seekable_seek (G_SEEKABLE (stream), 0, G_SEEK_SET, cancellable, NULL);

	if (!camel_data_wrapper_construct_from_stream_sync (CAMEL_DATA_WRAPPER (msg), stream, cancellable, error))
		g_clear_object (&msg);

	g_mutex_unlock (&imapx_folder->stream_lock);

	return msg;
}

static CamelMimeMessage *
imapx_get_message_cached (CamelFolder *folder,
			  const gchar *message_uid,
			  GCancellable *cancellable)
{
	CamelIMAPXFolder *imapx_folder;
	CamelMimeMessage *msg = NULL;
	CamelStream *stream = NULL;
	GIOStream *base_stream;

	g_return_val_if_fail (CAMEL_IS_IMAPX_FOLDER (folder), NULL);
	g_return_val_if_fail (message_uid != NULL, NULL);

	imapx_folder = CAMEL_IMAPX_FOLDER (folder);

	base_stream = camel_data_cache_get (imapx_folder->cache, "cur", message_uid, NULL);
	if (base_stream != NULL) {
		stream = camel_stream_new (base_stream);
		g_object_unref (base_stream);
	}

	if (stream != NULL) {
		msg = imapx_message_from_stream_sync (imapx_folder, stream, cancellable, NULL);

		g_object_unref (stream);
	}

	return msg;
}

static CamelMimeMessage *
imapx_get_message_sync (CamelFolder *folder,
                        const gchar *uid,
                        GCancellable *cancellable,
                        GError **error)
{
	CamelMimeMessage *msg = NULL;
	CamelStream *stream;
	CamelStore *store;
	CamelIMAPXFolder *imapx_folder;
	GIOStream *base_stream;
	const gchar *path = NULL;
	gboolean offline_message = FALSE;

	imapx_folder = CAMEL_IMAPX_FOLDER (folder);
	store = camel_folder_get_parent_store (folder);

	if (!strchr (uid, '-'))
		path = "cur";
	else {
		path = "new";
		offline_message = TRUE;
	}

	base_stream = camel_data_cache_get (
		imapx_folder->cache, path, uid, NULL);
	if (base_stream != NULL) {
		stream = camel_stream_new (base_stream);
		g_object_unref (base_stream);
	} else {
		CamelIMAPXConnManager *conn_man;
		CamelIMAPXMailbox *mailbox;

		if (offline_message) {
			g_set_error (
				error, CAMEL_FOLDER_ERROR,
				CAMEL_FOLDER_ERROR_INVALID_UID,
				"Offline message vanished from disk: %s", uid);
			return NULL;
		}

		conn_man = camel_imapx_store_get_conn_manager (CAMEL_IMAPX_STORE (store));

		mailbox = camel_imapx_folder_list_mailbox (
			CAMEL_IMAPX_FOLDER (folder), cancellable, error);

		if (mailbox == NULL)
			return NULL;

		stream = camel_imapx_conn_manager_get_message_sync (
			conn_man, mailbox, camel_folder_get_folder_summary (folder),
			CAMEL_IMAPX_FOLDER (folder)->cache, uid,
			cancellable, error);

		g_clear_object (&mailbox);
	}

	if (stream != NULL) {
		msg = imapx_message_from_stream_sync (imapx_folder, stream, cancellable, error);

		g_object_unref (stream);
	}

	if (msg != NULL) {
		CamelMessageInfo *mi;

		mi = camel_folder_summary_get (camel_folder_get_folder_summary (folder), uid);
		if (mi != NULL) {
			CamelMessageFlags flags;
			gboolean has_attachment;

			flags = camel_message_info_get_flags (mi);
			has_attachment = camel_mime_message_has_attachment (msg);
			if (((flags & CAMEL_MESSAGE_ATTACHMENTS) && !has_attachment) ||
			    ((flags & CAMEL_MESSAGE_ATTACHMENTS) == 0 && has_attachment)) {
				camel_message_info_set_flags (
					mi, CAMEL_MESSAGE_ATTACHMENTS,
					has_attachment ? CAMEL_MESSAGE_ATTACHMENTS : 0);
			}

			g_clear_object (&mi);
		}
	}

	return msg;
}

static CamelFolderQuotaInfo *
imapx_get_quota_info_sync (CamelFolder *folder,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelStore *store;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox = NULL;
	CamelFolderQuotaInfo *quota_info = NULL;
	gchar **quota_roots;
	gboolean success = FALSE;

	store = camel_folder_get_parent_store (folder);

	imapx_store = CAMEL_IMAPX_STORE (store);
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	mailbox = camel_imapx_folder_list_mailbox (
		CAMEL_IMAPX_FOLDER (folder), cancellable, error);
	if (mailbox == NULL)
		goto exit;

	success = camel_imapx_conn_manager_update_quota_info_sync (conn_man, mailbox, cancellable, error);

	if (!success)
		goto exit;

	quota_roots = camel_imapx_mailbox_dup_quota_roots (mailbox);

	/* XXX Just return info for the first quota root, I guess. */
	if (quota_roots != NULL && quota_roots[0] != NULL) {
		quota_info = camel_imapx_store_dup_quota_info (
			CAMEL_IMAPX_STORE (store), quota_roots[0]);
	}

	g_strfreev (quota_roots);

	if (quota_info == NULL)
		g_set_error (
			error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
			/* Translators: The first “%s” is replaced with an account name and the second “%s”
			   is replaced with a full path name. The spaces around “:” are intentional, as
			   the whole “%s : %s” is meant as an absolute identification of the folder. */
			_("No quota information available for folder “%s : %s”"),
			camel_service_get_display_name (CAMEL_SERVICE (store)),
			camel_folder_get_full_name (folder));

exit:
	g_clear_object (&mailbox);

	return quota_info;
}

static gboolean
imapx_purge_message_cache_sync (CamelFolder *folder,
                                gchar *start_uid,
                                gchar *end_uid,
                                GCancellable *cancellable,
                                GError **error)
{
	/* Not Implemented for now. */
	return TRUE;
}

static gboolean
imapx_refresh_info_sync (CamelFolder *folder,
                         GCancellable *cancellable,
                         GError **error)
{
	CamelStore *store;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox = NULL;
	gboolean success = FALSE;

	store = camel_folder_get_parent_store (folder);

	/* Not connected, thus skip the operation */
	if (!camel_offline_store_get_online (CAMEL_OFFLINE_STORE (store)))
		return TRUE;

	imapx_store = CAMEL_IMAPX_STORE (store);
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	mailbox = camel_imapx_folder_list_mailbox (CAMEL_IMAPX_FOLDER (folder), cancellable, error);

	if (mailbox) {
		success = camel_imapx_conn_manager_refresh_info_sync (conn_man, mailbox, cancellable, error);
	}

	g_clear_object (&mailbox);

	return success;
}

static gboolean
imapx_synchronize_sync (CamelFolder *folder,
                        gboolean expunge,
                        GCancellable *cancellable,
                        GError **error)
{
	CamelStore *store;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox = NULL;
	gboolean success = FALSE;

	store = camel_folder_get_parent_store (folder);

	/* Not connected, thus skip the operation */
	if (!camel_offline_store_get_online (CAMEL_OFFLINE_STORE (store)))
		return TRUE;

	imapx_store = CAMEL_IMAPX_STORE (store);
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	mailbox = camel_imapx_folder_list_mailbox (CAMEL_IMAPX_FOLDER (folder), cancellable, error);

	/* Do not update mailboxes on exit which were not entered yet */
	if (mailbox == NULL || (camel_application_is_exiting &&
	    camel_imapx_mailbox_get_permanentflags (mailbox) == ~0)) {
		success = mailbox != NULL;
	} else {
		success = camel_imapx_conn_manager_sync_changes_sync (conn_man, mailbox, cancellable, error);
		if (success && expunge && camel_folder_summary_get_deleted_count (camel_folder_get_folder_summary (folder)) > 0) {
			success = camel_imapx_conn_manager_expunge_sync (conn_man, mailbox, cancellable, error);
		}
	}

	g_clear_object (&mailbox);

	return success;
}

static gboolean
imapx_synchronize_message_sync (CamelFolder *folder,
                                const gchar *uid,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelStore *store;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox = NULL;
	gboolean success = FALSE;

	store = camel_folder_get_parent_store (folder);

	imapx_store = CAMEL_IMAPX_STORE (store);
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	mailbox = camel_imapx_folder_list_mailbox (
		CAMEL_IMAPX_FOLDER (folder), cancellable, error);

	if (mailbox == NULL)
		goto exit;

	success = camel_imapx_conn_manager_sync_message_sync (
		conn_man, mailbox, camel_folder_get_folder_summary (folder),
		CAMEL_IMAPX_FOLDER (folder)->cache, uid,
		cancellable, error);

exit:
	g_clear_object (&mailbox);

	return success;
}

static gboolean
imapx_transfer_messages_to_sync (CamelFolder *source,
                                 GPtrArray *uids,
                                 CamelFolder *dest,
                                 gboolean delete_originals,
                                 GPtrArray **transferred_uids,
                                 GCancellable *cancellable,
                                 GError **error)
{
	CamelStore *store;
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *src_mailbox = NULL;
	CamelIMAPXMailbox *dst_mailbox = NULL;
	gboolean success = FALSE;

	store = camel_folder_get_parent_store (source);

	imapx_store = CAMEL_IMAPX_STORE (store);
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);

	src_mailbox = camel_imapx_folder_list_mailbox (
		CAMEL_IMAPX_FOLDER (source), cancellable, error);

	if (src_mailbox == NULL)
		goto exit;

	dst_mailbox = camel_imapx_folder_list_mailbox (
		CAMEL_IMAPX_FOLDER (dest), cancellable, error);

	if (dst_mailbox == NULL)
		goto exit;

	success = camel_imapx_conn_manager_copy_message_sync (
		conn_man, src_mailbox, dst_mailbox, uids,
		delete_originals, FALSE, cancellable, error);

exit:
	g_clear_object (&src_mailbox);
	g_clear_object (&dst_mailbox);

	return success;
}

typedef struct _RemoveCacheFiles {
	CamelIMAPXFolder *imapx_folder;
	GSList *uids;
} RemoveCacheFiles;

static void
remove_cache_files_free (gpointer ptr)
{
	RemoveCacheFiles *rcf = ptr;

	if (rcf) {
		g_clear_object (&rcf->imapx_folder);
		g_slist_free_full (rcf->uids, (GDestroyNotify) camel_pstring_free);
		g_free (rcf);
	}
}

static void
imapx_folder_remove_cache_files_thread (CamelSession *session,
					GCancellable *cancellable,
					gpointer user_data,
					GError **error)
{
	RemoveCacheFiles *rcf = user_data;
	GSList *link;
	guint len, index;

	g_return_if_fail (rcf != NULL);
	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (rcf->imapx_folder));
	g_return_if_fail (rcf->uids != NULL);

	len = g_slist_length (rcf->uids);

	for (index = 1, link = rcf->uids;
	     link && !g_cancellable_set_error_if_cancelled (cancellable, error);
	     index++, link = g_slist_next (link)) {
		const gchar *message_uid = link->data;

		if (message_uid) {
			camel_data_cache_remove (rcf->imapx_folder->cache, "tmp", message_uid, NULL);
			camel_data_cache_remove (rcf->imapx_folder->cache, "cur", message_uid, NULL);

			camel_operation_progress (cancellable, index * 100 / len);
		}
	}
}

static void
imapx_folder_changed (CamelFolder *folder,
		      CamelFolderChangeInfo *info)
{
	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (folder));

	if (info && info->uid_removed && info->uid_removed->len) {
		CamelIMAPXFolder *imapx_folder;
		GSList *removed_uids = NULL;
		guint ii;

		imapx_folder = CAMEL_IMAPX_FOLDER (folder);

		g_mutex_lock (&imapx_folder->priv->move_to_hash_table_lock);

		for (ii = 0; ii < info->uid_removed->len; ii++) {
			const gchar *message_uid = info->uid_removed->pdata[ii];

			if (!message_uid)
				continue;

			g_hash_table_remove (imapx_folder->priv->move_to_real_trash_uids, message_uid);
			g_hash_table_remove (imapx_folder->priv->move_to_real_junk_uids, message_uid);
			g_hash_table_remove (imapx_folder->priv->move_to_inbox_uids, message_uid);

			removed_uids = g_slist_prepend (removed_uids, (gpointer) camel_pstring_strdup (message_uid));
		}

		g_mutex_unlock (&imapx_folder->priv->move_to_hash_table_lock);

		if (removed_uids) {
			CamelSession *session = NULL;
			CamelStore *parent_store;

			parent_store = camel_folder_get_parent_store (folder);
			if (parent_store)
				session = camel_service_ref_session (CAMEL_SERVICE (parent_store));

			if (session) {
				RemoveCacheFiles *rcf;
				gchar *description;

				rcf = g_new0 (RemoveCacheFiles, 1);
				rcf->imapx_folder = g_object_ref (imapx_folder);
				rcf->uids = removed_uids;

				removed_uids = NULL; /* transfer ownership to 'rcf' */

				/* Translators: The first “%s” is replaced with an account name and the second “%s”
				   is replaced with a full path name. The spaces around “:” are intentional, as
				   the whole “%s : %s” is meant as an absolute identification of the folder. */
				description = g_strdup_printf (_("Removing stale cache files in folder “%s : %s”"),
					camel_service_get_display_name (CAMEL_SERVICE (parent_store)),
					camel_folder_get_full_name (CAMEL_FOLDER (imapx_folder)));

				camel_session_submit_job (session, description,
					imapx_folder_remove_cache_files_thread, rcf, remove_cache_files_free);

				g_free (description);
			}

			g_slist_free_full (removed_uids, (GDestroyNotify) camel_pstring_free);
		}
	}

	/* Chain up to parent's method. */
	CAMEL_FOLDER_CLASS (camel_imapx_folder_parent_class)->changed (folder, info);
}

static guint32
imapx_get_permanent_flags (CamelFolder *folder)
{
	return CAMEL_MESSAGE_ANSWERED |
		CAMEL_MESSAGE_DELETED |
		CAMEL_MESSAGE_DRAFT |
		CAMEL_MESSAGE_FLAGGED |
		CAMEL_MESSAGE_SEEN |
		CAMEL_MESSAGE_USER;
}

static void
imapx_rename (CamelFolder *folder,
              const gchar *new_name)
{
	CamelStore *store;
	CamelIMAPXStore *imapx_store;
	const gchar *folder_name;

	store = camel_folder_get_parent_store (folder);
	imapx_store = CAMEL_IMAPX_STORE (store);

	camel_store_summary_disconnect_folder_summary (
		imapx_store->summary, camel_folder_get_folder_summary (folder));

	/* Chain up to parent's rename() method. */
	CAMEL_FOLDER_CLASS (camel_imapx_folder_parent_class)->
		rename (folder, new_name);

	folder_name = camel_folder_get_full_name (folder);

	camel_store_summary_connect_folder_summary (
		imapx_store->summary, folder_name, camel_folder_get_folder_summary (folder));
}

static void
camel_imapx_folder_class_init (CamelIMAPXFolderClass *class)
{
	GObjectClass *object_class;
	CamelFolderClass *folder_class;

	g_type_class_add_private (class, sizeof (CamelIMAPXFolderPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = imapx_folder_set_property;
	object_class->get_property = imapx_folder_get_property;
	object_class->dispose = imapx_folder_dispose;
	object_class->finalize = imapx_folder_finalize;

	folder_class = CAMEL_FOLDER_CLASS (class);
	folder_class->get_permanent_flags = imapx_get_permanent_flags;
	folder_class->rename = imapx_rename;
	folder_class->search_by_expression = imapx_search_by_expression;
	folder_class->search_by_uids = imapx_search_by_uids;
	folder_class->count_by_expression = imapx_count_by_expression;
	folder_class->get_uncached_uids = imapx_get_uncached_uids;
	folder_class->search_free = imapx_search_free;
	folder_class->get_filename = imapx_get_filename;
	folder_class->append_message_sync = imapx_append_message_sync;
	folder_class->expunge_sync = imapx_expunge_sync;
	folder_class->get_message_cached = imapx_get_message_cached;
	folder_class->get_message_sync = imapx_get_message_sync;
	folder_class->get_quota_info_sync = imapx_get_quota_info_sync;
	folder_class->purge_message_cache_sync = imapx_purge_message_cache_sync;
	folder_class->refresh_info_sync = imapx_refresh_info_sync;
	folder_class->synchronize_sync = imapx_synchronize_sync;
	folder_class->synchronize_message_sync = imapx_synchronize_message_sync;
	folder_class->transfer_messages_to_sync = imapx_transfer_messages_to_sync;
	folder_class->changed = imapx_folder_changed;

	g_object_class_install_property (
		object_class,
		PROP_APPLY_FILTERS,
		g_param_spec_boolean (
			"apply-filters",
			"Apply Filters",
			_("Apply message _filters to this folder"),
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			CAMEL_PARAM_PERSISTENT));

	g_object_class_install_property (
		object_class,
		PROP_CHECK_FOLDER,
		g_param_spec_boolean (
			"check-folder",
			"Check Folder",
			_("Always check for _new mail in this folder"),
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			CAMEL_PARAM_PERSISTENT));

	g_object_class_install_property (
		object_class,
		PROP_MAILBOX,
		g_param_spec_object (
			"mailbox",
			"Mailbox",
			"IMAP mailbox for this folder",
			CAMEL_TYPE_IMAPX_MAILBOX,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));
}

static void
camel_imapx_folder_init (CamelIMAPXFolder *imapx_folder)
{
	CamelFolder *folder = CAMEL_FOLDER (imapx_folder);
	GHashTable *move_to_real_junk_uids;
	GHashTable *move_to_real_trash_uids;

	move_to_real_junk_uids = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) camel_pstring_free,
		(GDestroyNotify) NULL);

	move_to_real_trash_uids = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) camel_pstring_free,
		(GDestroyNotify) NULL);

	imapx_folder->priv = CAMEL_IMAPX_FOLDER_GET_PRIVATE (imapx_folder);

	camel_folder_set_flags (folder, camel_folder_get_flags (folder) | CAMEL_FOLDER_HAS_SUMMARY_CAPABILITY);

	camel_folder_set_lock_async (folder, TRUE);

	g_mutex_init (&imapx_folder->priv->property_lock);

	g_mutex_init (&imapx_folder->priv->move_to_hash_table_lock);
	imapx_folder->priv->move_to_real_junk_uids = move_to_real_junk_uids;
	imapx_folder->priv->move_to_real_trash_uids = move_to_real_trash_uids;
	imapx_folder->priv->move_to_inbox_uids = g_hash_table_new_full (g_str_hash, g_str_equal, (GDestroyNotify) camel_pstring_free, NULL);

	g_mutex_init (&imapx_folder->search_lock);
	g_mutex_init (&imapx_folder->stream_lock);

	g_weak_ref_init (&imapx_folder->priv->mailbox, NULL);
}

CamelFolder *
camel_imapx_folder_new (CamelStore *store,
                        const gchar *folder_dir,
                        const gchar *folder_name,
                        GError **error)
{
	CamelFolder *folder;
	CamelFolderSummary *folder_summary;
	CamelService *service;
	CamelSettings *settings;
	CamelIMAPXFolder *imapx_folder;
	const gchar *short_name;
	gchar *state_file;
	gboolean filter_all;
	gboolean filter_inbox;
	gboolean filter_junk;
	gboolean filter_junk_inbox;
	gboolean offline_limit_by_age = FALSE;
	CamelTimeUnit offline_limit_unit;
	gint offline_limit_value;
	time_t when = (time_t) 0;
	guint32 add_folder_flags = 0;

	d ("opening imap folder '%s'\n", folder_dir);

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	g_object_get (
		settings,
		"filter-all", &filter_all,
		"filter-inbox", &filter_inbox,
		"filter-junk", &filter_junk,
		"filter-junk-inbox", &filter_junk_inbox,
		"limit-by-age", &offline_limit_by_age,
		"limit-unit", &offline_limit_unit,
		"limit-value", &offline_limit_value,
		NULL);

	g_object_unref (settings);

	short_name = strrchr (folder_name, '/');
	if (short_name)
		short_name++;
	else
		short_name = folder_name;

	folder = g_object_new (
		CAMEL_TYPE_IMAPX_FOLDER,
		"display-name", short_name,
		"full_name", folder_name,
		"parent-store", store, NULL);

	folder_summary = camel_imapx_summary_new (folder);
	if (!folder_summary) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Could not create folder summary for %s"),
			short_name);
		g_object_unref (folder);
		return NULL;
	}

	camel_folder_take_folder_summary (folder, folder_summary);

	imapx_folder = CAMEL_IMAPX_FOLDER (folder);
	imapx_folder->cache = camel_data_cache_new (folder_dir, error);
	if (imapx_folder->cache == NULL) {
		g_prefix_error (
			error, _("Could not create cache for %s: "),
			short_name);
		g_object_unref (folder);
		return NULL;
	}

	state_file = g_build_filename (folder_dir, "cmeta", NULL);
	camel_object_set_state_filename (CAMEL_OBJECT (folder), state_file);
	g_free (state_file);
	camel_object_state_read (CAMEL_OBJECT (folder));

	if (offline_limit_by_age)
		when = camel_time_value_apply (when, offline_limit_unit, offline_limit_value);

	if (when <= (time_t) 0)
		when = (time_t) -1;

	camel_imapx_folder_update_cache_expire (folder, when);

	camel_binding_bind_property (store, "online",
		imapx_folder->cache, "expire-enabled",
		G_BINDING_SYNC_CREATE);

	imapx_folder->search = camel_imapx_search_new (CAMEL_IMAPX_STORE (store));

	if (filter_all)
		add_folder_flags |= CAMEL_FOLDER_FILTER_RECENT;

	if (camel_imapx_mailbox_is_inbox (folder_name)) {
		if (filter_inbox)
			add_folder_flags |= CAMEL_FOLDER_FILTER_RECENT;

		if (filter_junk)
			add_folder_flags |= CAMEL_FOLDER_FILTER_JUNK;
	} else {
		if (filter_junk && !filter_junk_inbox)
			add_folder_flags |= CAMEL_FOLDER_FILTER_JUNK;

		if (imapx_folder_get_apply_filters (imapx_folder))
			add_folder_flags |= CAMEL_FOLDER_FILTER_RECENT;
	}

	camel_folder_set_flags (folder, camel_folder_get_flags (folder) | add_folder_flags);

	camel_store_summary_connect_folder_summary (
		CAMEL_IMAPX_STORE (store)->summary,
		folder_name, camel_folder_get_folder_summary (folder));

	return folder;
}

/**
 * camel_imapx_folder_ref_mailbox:
 * @folder: a #CamelIMAPXFolder
 *
 * Returns the #CamelIMAPXMailbox for @folder from the current IMAP server
 * connection, or %NULL if @folder's #CamelFolder:parent-store is disconnected
 * from the IMAP server.
 *
 * The returned #CamelIMAPXMailbox is referenced for thread-safety and
 * should be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelIMAPXMailbox, or %NULL
 *
 * Since: 3.12
 **/
CamelIMAPXMailbox *
camel_imapx_folder_ref_mailbox (CamelIMAPXFolder *folder)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_FOLDER (folder), NULL);

	return g_weak_ref_get (&folder->priv->mailbox);
}

/**
 * camel_imapx_folder_set_mailbox:
 * @folder: a #CamelIMAPXFolder
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Sets the #CamelIMAPXMailbox for @folder from the current IMAP server
 * connection.  Note that #CamelIMAPXFolder only holds a weak reference
 * on its #CamelIMAPXMailbox so that when the IMAP server connection is
 * lost, all mailbox instances are automatically destroyed.
 *
 * Since: 3.12
 **/
void
camel_imapx_folder_set_mailbox (CamelIMAPXFolder *folder,
                                CamelIMAPXMailbox *mailbox)
{
	CamelIMAPXSummary *imapx_summary;
	guint32 uidvalidity;

	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (folder));
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	g_weak_ref_set (&folder->priv->mailbox, mailbox);

	imapx_summary = CAMEL_IMAPX_SUMMARY (camel_folder_get_folder_summary (CAMEL_FOLDER (folder)));
	uidvalidity = camel_imapx_mailbox_get_uidvalidity (mailbox);

	if (uidvalidity > 0 && uidvalidity != imapx_summary->validity)
		camel_imapx_folder_invalidate_local_cache (folder, uidvalidity);

	g_object_notify (G_OBJECT (folder), "mailbox");
}

/**
 * camel_imapx_folder_list_mailbox:
 * @folder: a #CamelIMAPXFolder
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Ensures that @folder's #CamelIMAPXFolder:mailbox property is set,
 * going so far as to issue a LIST command if necessary (but should
 * be a rarely needed last resort).
 *
 * If @folder's #CamelFolder:parent-store is disconnected from the IMAP
 * server or an error occurs during the LIST command, the function sets
 * @error and returns %NULL.
 *
 * The returned #CamelIMAPXMailbox is referenced for thread-safety and
 * should be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelIMAPXMailbox, or %NULL
 *
 * Since: 3.12
 **/
CamelIMAPXMailbox *
camel_imapx_folder_list_mailbox (CamelIMAPXFolder *folder,
                                 GCancellable *cancellable,
                                 GError **error)
{
	CamelIMAPXStore *imapx_store;
	CamelIMAPXConnManager *conn_man;
	CamelIMAPXMailbox *mailbox;
	CamelStore *parent_store;
	CamelStoreInfo *store_info;
	CamelIMAPXStoreInfo *imapx_store_info;
	gchar *folder_path = NULL;
	gchar *mailbox_name = NULL;
	gchar *pattern;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_FOLDER (folder), FALSE);

	/* First check if we already have a mailbox. */

	mailbox = camel_imapx_folder_ref_mailbox (folder);
	if (mailbox != NULL)
		goto exit;

	/* Obtain the mailbox name from the store summary. */

	folder_path = camel_folder_dup_full_name (CAMEL_FOLDER (folder));
	parent_store = camel_folder_get_parent_store (CAMEL_FOLDER (folder));

	imapx_store = CAMEL_IMAPX_STORE (parent_store);

	store_info = camel_store_summary_path (
		imapx_store->summary, folder_path);

	/* This should never fail.  We needed the CamelStoreInfo
	 * to instantiate the CamelIMAPXFolder in the first place. */
	g_return_val_if_fail (store_info != NULL, FALSE);

	imapx_store_info = (CamelIMAPXStoreInfo *) store_info;
	mailbox_name = g_strdup (imapx_store_info->mailbox_name);

	camel_store_summary_info_unref (imapx_store->summary, store_info);

	/* See if the CamelIMAPXStore already has the mailbox. */

	mailbox = camel_imapx_store_ref_mailbox (imapx_store, mailbox_name);
	if (mailbox != NULL) {
		camel_imapx_folder_set_mailbox (folder, mailbox);
		goto exit;
	}

	/* Last resort is to issue a LIST command.  Maintainer should
	 * monitor IMAP logs to make sure this is rarely if ever used. */

	pattern = camel_utf8_utf7 (mailbox_name);

	/* This creates a mailbox instance from the LIST response. */
	conn_man = camel_imapx_store_get_conn_manager (imapx_store);
	success = camel_imapx_conn_manager_list_sync (conn_man, pattern, 0, cancellable, error);

	g_free (pattern);

	if (!success)
		goto exit;

	/* This might still return NULL if the mailbox has a
	 * /NonExistent attribute.  Otherwise this should work. */
	mailbox = camel_imapx_store_ref_mailbox (imapx_store, mailbox_name);
	if (mailbox != NULL) {
		camel_imapx_folder_set_mailbox (folder, mailbox);
	} else {
		g_set_error (
			error, CAMEL_FOLDER_ERROR,
			CAMEL_FOLDER_ERROR_INVALID_STATE,
			/* Translators: The first “%s” is replaced with an account name and the second “%s”
			   is replaced with a full path name. The spaces around “:” are intentional, as
			   the whole “%s : %s” is meant as an absolute identification of the folder. */
			_("No IMAP mailbox available for folder “%s : %s”"),
			camel_service_get_display_name (CAMEL_SERVICE (parent_store)),
			camel_folder_get_full_name (CAMEL_FOLDER (folder)));
	}

exit:
	g_free (folder_path);
	g_free (mailbox_name);

	return mailbox;
}

/**
 * camel_imapx_folder_copy_message_map:
 * @folder: a #CamelIMAPXFolder
 *
 * Returns a #GSequence of 32-bit integers representing the locally cached
 * mapping of message sequence numbers to unique identifiers.
 *
 * Free the returns #GSequence with g_sequence_free().
 *
 * Returns: a #GSequence
 *
 * Since: 3.12
 **/
GSequence *
camel_imapx_folder_copy_message_map (CamelIMAPXFolder *folder)
{
	CamelFolderSummary *summary;
	GSequence *message_map;
	GPtrArray *array;
	guint ii;

	g_return_val_if_fail (CAMEL_IS_IMAPX_FOLDER (folder), NULL);

	summary = camel_folder_get_folder_summary (CAMEL_FOLDER (folder));
	array = camel_folder_summary_get_array (summary);
	camel_folder_sort_uids (CAMEL_FOLDER (folder), array);

	message_map = g_sequence_new (NULL);

	for (ii = 0; ii < array->len; ii++) {
		guint32 uid = strtoul (array->pdata[ii], NULL, 10);
		g_sequence_append (message_map, GUINT_TO_POINTER (uid));
	}

	camel_folder_summary_free_array (array);

	return message_map;
}

/**
 * camel_imapx_folder_add_move_to_real_junk:
 * @folder: a #CamelIMAPXFolder
 * @message_uid: a message UID
 *
 * Adds @message_uid to a pool of messages to be moved to a real junk
 * folder the next time @folder is explicitly synchronized by way of
 * camel_folder_synchronize() or camel_folder_synchronize_sync().
 *
 * This only applies when using a real folder to track junk messages,
 * as specified by the #CamelIMAPXSettings:use-real-junk-path setting.
 *
 * Since: 3.8
 **/
void
camel_imapx_folder_add_move_to_real_junk (CamelIMAPXFolder *folder,
                                          const gchar *message_uid)
{
	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (folder));
	g_return_if_fail (message_uid != NULL);
	g_return_if_fail (camel_folder_summary_check_uid (camel_folder_get_folder_summary (CAMEL_FOLDER (folder)), message_uid));

	g_mutex_lock (&folder->priv->move_to_hash_table_lock);

	g_hash_table_remove (folder->priv->move_to_real_trash_uids, message_uid);
	g_hash_table_remove (folder->priv->move_to_inbox_uids, message_uid);

	g_hash_table_add (
		folder->priv->move_to_real_junk_uids,
		(gpointer) camel_pstring_strdup (message_uid));

	g_mutex_unlock (&folder->priv->move_to_hash_table_lock);
}

/**
 * camel_imapx_folder_add_move_to_real_trash:
 * @folder: a #CamelIMAPXFolder
 * @message_uid: a message UID
 *
 * Adds @message_uid to a pool of messages to be moved to a real trash
 * folder the next time @folder is explicitly synchronized by way of
 * camel_folder_synchronize() or camel_folder_synchronize_sync().
 *
 * This only applies when using a real folder to track deleted messages,
 * as specified by the #CamelIMAPXSettings:use-real-trash-path setting.
 *
 * Since: 3.8
 **/
void
camel_imapx_folder_add_move_to_real_trash (CamelIMAPXFolder *folder,
                                           const gchar *message_uid)
{
	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (folder));
	g_return_if_fail (message_uid != NULL);
	g_return_if_fail (camel_folder_summary_check_uid (camel_folder_get_folder_summary (CAMEL_FOLDER (folder)), message_uid));

	g_mutex_lock (&folder->priv->move_to_hash_table_lock);

	g_hash_table_remove (folder->priv->move_to_real_junk_uids, message_uid);
	g_hash_table_remove (folder->priv->move_to_inbox_uids, message_uid);

	g_hash_table_add (
		folder->priv->move_to_real_trash_uids,
		(gpointer) camel_pstring_strdup (message_uid));

	g_mutex_unlock (&folder->priv->move_to_hash_table_lock);
}

/*
 * camel_imapx_folder_add_move_to_inbox:
 * @folder: a #CamelIMAPXFolder
 * @message_uid: a message UID
 *
 * Adds @message_uid to a pool of messages to be moved to the Inbox
 * folder the next time @folder is explicitly synchronized by way of
 * camel_folder_synchronize() or camel_folder_synchronize_sync().
 *
 * Since: 3.28
 */
void
camel_imapx_folder_add_move_to_inbox (CamelIMAPXFolder *folder,
				      const gchar *message_uid)
{
	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (folder));
	g_return_if_fail (message_uid != NULL);
	g_return_if_fail (camel_folder_summary_check_uid (camel_folder_get_folder_summary (CAMEL_FOLDER (folder)), message_uid));

	g_mutex_lock (&folder->priv->move_to_hash_table_lock);

	g_hash_table_remove (folder->priv->move_to_real_trash_uids, message_uid);
	g_hash_table_remove (folder->priv->move_to_real_junk_uids, message_uid);

	g_hash_table_add (
		folder->priv->move_to_inbox_uids,
		(gpointer) camel_pstring_strdup (message_uid));

	g_mutex_unlock (&folder->priv->move_to_hash_table_lock);
}

/**
 * camel_imapx_folder_invalidate_local_cache:
 * @folder: a #CamelIMAPXFolder
 * @new_uidvalidity: the new UIDVALIDITY value
 *
 * Call this function when the IMAP server reports a different UIDVALIDITY
 * value than what is presently cached.  This means all cached message UIDs
 * are now invalid and must be discarded.
 *
 * The local cache for @folder is reset and the @new_uidvalidity value is
 * recorded in the newly-reset cache.
 *
 * Since: 3.10
 **/
void
camel_imapx_folder_invalidate_local_cache (CamelIMAPXFolder *folder,
                                           guint64 new_uidvalidity)
{
	CamelFolderSummary *summary;
	CamelFolderChangeInfo *changes;
	GPtrArray *array;
	guint ii;

	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (folder));
	g_return_if_fail (new_uidvalidity > 0);

	summary = camel_folder_get_folder_summary (CAMEL_FOLDER (folder));

	changes = camel_folder_change_info_new ();
	array = camel_folder_summary_get_array (summary);

	for (ii = 0; ii < array->len; ii++) {
		const gchar *uid = array->pdata[ii];
		camel_folder_change_info_change_uid (changes, uid);
	}

	CAMEL_IMAPX_SUMMARY (summary)->validity = new_uidvalidity;
	camel_folder_summary_touch (summary);
	camel_folder_summary_save (summary, NULL);

	camel_data_cache_clear (folder->cache, "cache");
	camel_data_cache_clear (folder->cache, "cur");

	camel_folder_changed (CAMEL_FOLDER (folder), changes);

	camel_folder_change_info_free (changes);
	camel_folder_summary_free_array (array);
}

gboolean
camel_imapx_folder_get_check_folder (CamelIMAPXFolder *folder)
{
	g_return_val_if_fail (folder != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_IMAPX_FOLDER (folder), FALSE);

	return folder->priv->check_folder;
}

void
camel_imapx_folder_set_check_folder (CamelIMAPXFolder *folder,
				     gboolean check_folder)
{
	g_return_if_fail (folder != NULL);
	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (folder));

	if (folder->priv->check_folder == check_folder)
		return;

	folder->priv->check_folder = check_folder;

	g_object_notify (G_OBJECT (folder), "check-folder");
}

void
camel_imapx_folder_update_cache_expire (CamelFolder *folder,
					time_t expire_when)
{
	CamelIMAPXFolder *imapx_folder;

	g_return_if_fail (CAMEL_IS_IMAPX_FOLDER (folder));

	imapx_folder = CAMEL_IMAPX_FOLDER (folder);

	if (camel_offline_folder_can_downsync (CAMEL_OFFLINE_FOLDER (folder))) {
		/* Ensure cache will expire when set up, otherwise
		 * it causes redownload of messages too soon. */
		camel_data_cache_set_expire_age (imapx_folder->cache, expire_when);
		camel_data_cache_set_expire_access (imapx_folder->cache, expire_when);
	} else {
		/* Set cache expiration for one week. */
		camel_data_cache_set_expire_age (imapx_folder->cache, 60 * 60 * 24 * 7);
		camel_data_cache_set_expire_access (imapx_folder->cache, 60 * 60 * 24 * 7);
	}
}
