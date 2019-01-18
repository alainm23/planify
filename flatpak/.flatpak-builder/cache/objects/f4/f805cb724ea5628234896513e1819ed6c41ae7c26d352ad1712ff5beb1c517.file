/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-nntp-folder.c : Class for a news folder
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
 * Authors : Chris Toshok <toshok@ximian.com>
 *           Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>

#include <glib/gi18n-lib.h>

#include "camel-nntp-folder.h"
#include "camel-nntp-private.h"
#include "camel-nntp-store.h"
#include "camel-nntp-summary.h"

#define CAMEL_NNTP_FOLDER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_NNTP_FOLDER, CamelNNTPFolderPrivate))

/* The custom property ID is a CamelArg artifact.
 * It still identifies the property in state files. */
enum {
	PROP_0,
	PROP_APPLY_FILTERS = 0x2501
};

G_DEFINE_TYPE (
	CamelNNTPFolder,
	camel_nntp_folder,
	CAMEL_TYPE_OFFLINE_FOLDER)

static gboolean
nntp_folder_get_apply_filters (CamelNNTPFolder *folder)
{
	g_return_val_if_fail (folder != NULL, FALSE);
	g_return_val_if_fail (CAMEL_IS_NNTP_FOLDER (folder), FALSE);

	return folder->priv->apply_filters;
}

static void
nntp_folder_set_apply_filters (CamelNNTPFolder *folder,
                               gboolean apply_filters)
{
	g_return_if_fail (folder != NULL);
	g_return_if_fail (CAMEL_IS_NNTP_FOLDER (folder));

	if (folder->priv->apply_filters == apply_filters)
		return;

	folder->priv->apply_filters = apply_filters;

	g_object_notify (G_OBJECT (folder), "apply-filters");
}

static void
nntp_folder_set_property (GObject *object,
                          guint property_id,
                          const GValue *value,
                          GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_APPLY_FILTERS:
			nntp_folder_set_apply_filters (
				CAMEL_NNTP_FOLDER (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
nntp_folder_get_property (GObject *object,
                          guint property_id,
                          GValue *value,
                          GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_APPLY_FILTERS:
			g_value_set_boolean (
				value, nntp_folder_get_apply_filters (
				CAMEL_NNTP_FOLDER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
nntp_folder_dispose (GObject *object)
{
	CamelFolder *folder;
	CamelStore *store;

	folder = CAMEL_FOLDER (object);
	camel_folder_summary_save (camel_folder_get_folder_summary (folder), NULL);

	store = camel_folder_get_parent_store (folder);
	if (store != NULL) {
		CamelNNTPStoreSummary *nntp_store_summary;

		nntp_store_summary = camel_nntp_store_ref_summary (
			CAMEL_NNTP_STORE (store));
		camel_store_summary_disconnect_folder_summary (
			CAMEL_STORE_SUMMARY (nntp_store_summary),
			camel_folder_get_folder_summary (folder));
		g_clear_object (&nntp_store_summary);
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_nntp_folder_parent_class)->dispose (object);
}

static void
nntp_folder_finalize (GObject *object)
{
	CamelNNTPFolder *nntp_folder = CAMEL_NNTP_FOLDER (object);

	if (nntp_folder->changes) {
		camel_folder_change_info_free (nntp_folder->changes);
		nntp_folder->changes = NULL;
	}

	g_mutex_clear (&nntp_folder->priv->search_lock);
	g_mutex_clear (&nntp_folder->priv->cache_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_nntp_folder_parent_class)->finalize (object);
}

gboolean
camel_nntp_folder_selected (CamelNNTPFolder *nntp_folder,
                            gchar *line,
                            GCancellable *cancellable,
                            GError **error)
{
	CamelFolder *folder;
	CamelStore *parent_store;
	gboolean res;

	folder = CAMEL_FOLDER (nntp_folder);
	parent_store = camel_folder_get_parent_store (folder);

	res = camel_nntp_summary_check (
		CAMEL_NNTP_SUMMARY (camel_folder_get_folder_summary (folder)),
		CAMEL_NNTP_STORE (parent_store),
		line, nntp_folder->changes,
		cancellable, error);

	if (camel_folder_change_info_changed (nntp_folder->changes)) {
		CamelFolderChangeInfo *changes;

		changes = nntp_folder->changes;
		nntp_folder->changes = camel_folder_change_info_new ();

		camel_folder_changed (CAMEL_FOLDER (nntp_folder), changes);
		camel_folder_change_info_free (changes);
	}

	return res;
}

static void
unset_flagged_flag (const gchar *uid,
                    CamelFolderSummary *summary)
{
	CamelMessageInfo *info;

	info = camel_folder_summary_get (summary, uid);
	if (info) {
		camel_message_info_set_folder_flagged (info, FALSE);
		g_clear_object (&info);
	}
}

static gchar *
nntp_get_filename (CamelFolder *folder,
                   const gchar *uid,
                   GError **error)
{
	CamelStore *parent_store;
	CamelDataCache *nntp_cache;
	CamelNNTPStore *nntp_store;
	gchar *article, *msgid;
	gsize article_len;
	gchar *filename;

	parent_store = camel_folder_get_parent_store (folder);
	nntp_store = CAMEL_NNTP_STORE (parent_store);

	article_len = strlen (uid) + 1;
	article = alloca (article_len);
	g_strlcpy (article, uid, article_len);
	msgid = strchr (article, ',');
	if (msgid == NULL) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Internal error: UID in invalid format: %s"), uid);
		return NULL;
	}
	*msgid++ = 0;

	nntp_cache = camel_nntp_store_ref_cache (nntp_store);
	filename = camel_data_cache_get_filename (nntp_cache, "cache", msgid);
	g_clear_object (&nntp_cache);

	return filename;
}

static CamelStream *
nntp_folder_download_message (CamelNNTPFolder *nntp_folder,
                              const gchar *id,
                              const gchar *msgid,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelFolder *folder;
	CamelStore *parent_store;
	CamelDataCache *nntp_cache;
	CamelNNTPStore *nntp_store;
	CamelNNTPStream *nntp_stream = NULL;
	CamelStream *stream = NULL;
	gint ret;
	gchar *line;

	folder = CAMEL_FOLDER (nntp_folder);
	parent_store = camel_folder_get_parent_store (folder);

	nntp_store = CAMEL_NNTP_STORE (parent_store);
	nntp_cache = camel_nntp_store_ref_cache (nntp_store);

	ret = camel_nntp_command (
		nntp_store, cancellable, error,
		nntp_folder, &nntp_stream, &line, "article %s", id);

	if (ret == 220) {
		GIOStream *base_stream;

		base_stream = camel_data_cache_add (
			nntp_cache, "cache", msgid, NULL);
		if (base_stream != NULL) {
			gboolean success;

			stream = camel_stream_new (base_stream);
			g_object_unref (base_stream);

			success = (camel_stream_write_to_stream (
				CAMEL_STREAM (nntp_stream),
				stream, cancellable, error) != -1);
			if (!success)
				goto fail;

			success = g_seekable_seek (
				G_SEEKABLE (stream), 0,
				G_SEEK_SET, cancellable, error);
			if (!success)
				goto fail;
		} else {
			stream = g_object_ref (nntp_stream);
		}

	} else if (ret == 423 || ret == 430) {
		g_set_error (
			error, CAMEL_FOLDER_ERROR,
			CAMEL_FOLDER_ERROR_INVALID_UID,
			_("Cannot get message %s: %s"), msgid, line);

	} else if (ret != -1) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot get message %s: %s"), msgid, line);
	}

	goto exit;

 fail:
	camel_data_cache_remove (nntp_cache, "cache", msgid, NULL);
	g_prefix_error (error, _("Cannot get message %s: "), msgid);

	g_clear_object (&stream);

 exit:
	if (nntp_stream)
		camel_nntp_stream_unlock (nntp_stream);

	g_clear_object (&nntp_cache);
	g_clear_object (&nntp_stream);

	return stream;
}

static GPtrArray *
nntp_folder_search_by_expression (CamelFolder *folder,
                                  const gchar *expression,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelNNTPFolder *nntp_folder = CAMEL_NNTP_FOLDER (folder);
	GPtrArray *matches;

	CAMEL_NNTP_FOLDER_LOCK (nntp_folder, search_lock);

	if (nntp_folder->search == NULL)
		nntp_folder->search = camel_folder_search_new ();

	camel_folder_search_set_folder (nntp_folder->search, folder);
	matches = camel_folder_search_search (nntp_folder->search, expression, NULL, cancellable, error);

	CAMEL_NNTP_FOLDER_UNLOCK (nntp_folder, search_lock);

	return matches;
}

static guint32
nntp_folder_count_by_expression (CamelFolder *folder,
                                 const gchar *expression,
                                 GCancellable *cancellable,
                                 GError **error)
{
	CamelNNTPFolder *nntp_folder = CAMEL_NNTP_FOLDER (folder);
	guint32 count;

	CAMEL_NNTP_FOLDER_LOCK (nntp_folder, search_lock);

	if (nntp_folder->search == NULL)
		nntp_folder->search = camel_folder_search_new ();

	camel_folder_search_set_folder (nntp_folder->search, folder);
	count = camel_folder_search_count (nntp_folder->search, expression, cancellable, error);

	CAMEL_NNTP_FOLDER_UNLOCK (nntp_folder, search_lock);

	return count;
}

static GPtrArray *
nntp_folder_search_by_uids (CamelFolder *folder,
                            const gchar *expression,
                            GPtrArray *uids,
                            GCancellable *cancellable,
                            GError **error)
{
	CamelNNTPFolder *nntp_folder = (CamelNNTPFolder *) folder;
	GPtrArray *matches;

	if (uids->len == 0)
		return g_ptr_array_new ();

	CAMEL_NNTP_FOLDER_LOCK (folder, search_lock);

	if (nntp_folder->search == NULL)
		nntp_folder->search = camel_folder_search_new ();

	camel_folder_search_set_folder (nntp_folder->search, folder);
	matches = camel_folder_search_search (nntp_folder->search, expression, uids, cancellable, error);

	CAMEL_NNTP_FOLDER_UNLOCK (folder, search_lock);

	return matches;
}

static void
nntp_folder_search_free (CamelFolder *folder,
                         GPtrArray *result)
{
	CamelNNTPFolder *nntp_folder = CAMEL_NNTP_FOLDER (folder);

	CAMEL_NNTP_FOLDER_LOCK (nntp_folder, search_lock);
	camel_folder_search_free_result (nntp_folder->search, result);
	CAMEL_NNTP_FOLDER_UNLOCK (nntp_folder, search_lock);
}

static gboolean
nntp_folder_append_message_sync (CamelFolder *folder,
                                 CamelMimeMessage *message,
                                 CamelMessageInfo *info,
                                 gchar **appended_uid,
                                 GCancellable *cancellable,
                                 GError **error)
{
	CamelStore *parent_store;
	CamelNNTPStore *nntp_store;
	CamelNNTPStream *nntp_stream = NULL;
	CamelStream *filtered_stream;
	CamelMimeFilter *crlffilter;
	gint ret;
	guint u, ii;
	CamelNameValueArray *previous_headers = NULL;
	const gchar *header_name = NULL, *header_value = NULL;
	const gchar *full_name;
	gchar *group, *line;
	gboolean success = TRUE;
	GError *local_error = NULL;

	full_name = camel_folder_get_full_name (folder);
	parent_store = camel_folder_get_parent_store (folder);

	nntp_store = CAMEL_NNTP_STORE (parent_store);

	/* send 'POST' command */
	ret = camel_nntp_command (nntp_store, cancellable, error, NULL, &nntp_stream, &line, "post");
	if (ret != 340) {
		if (ret == 440) {
			g_set_error (
				error, CAMEL_FOLDER_ERROR,
				CAMEL_FOLDER_ERROR_INSUFFICIENT_PERMISSION,
				_("Posting failed: %s"), line);
			success = FALSE;
		} else if (ret != -1) {
			g_set_error (
				error, CAMEL_ERROR,
				CAMEL_ERROR_GENERIC,
				_("Posting failed: %s"), line);
			success = FALSE;
		}
		goto exit;
	}

	/* the 'Newsgroups: ' header */
	group = g_strdup_printf ("Newsgroups: %s\r\n", full_name);

	/* remove mail 'To', 'Cc', and 'Bcc' headers */
	previous_headers = camel_medium_dup_headers (CAMEL_MEDIUM (message));
	camel_medium_remove_header (CAMEL_MEDIUM (message), "To");
	camel_medium_remove_header (CAMEL_MEDIUM (message), "Cc");
	camel_medium_remove_header (CAMEL_MEDIUM (message), "Bcc");

	/* setup stream filtering */
	filtered_stream = camel_stream_filter_new (CAMEL_STREAM (nntp_stream));
	crlffilter = camel_mime_filter_crlf_new (
		CAMEL_MIME_FILTER_CRLF_ENCODE,
		CAMEL_MIME_FILTER_CRLF_MODE_CRLF_DOTS);
	camel_stream_filter_add (
		CAMEL_STREAM_FILTER (filtered_stream), crlffilter);
	g_object_unref (crlffilter);

	/* write the message */
	if (local_error == NULL)
		camel_stream_write (
			CAMEL_STREAM (nntp_stream),
			group, strlen (group),
			cancellable, &local_error);
	if (local_error == NULL)
		camel_data_wrapper_write_to_stream_sync (
			CAMEL_DATA_WRAPPER (message),
			filtered_stream, cancellable, &local_error);
	if (local_error == NULL)
		camel_stream_flush (
			filtered_stream, cancellable, &local_error);
	if (local_error == NULL)
		camel_stream_write (
			CAMEL_STREAM (nntp_stream),
			"\r\n.\r\n", 5,
			cancellable, &local_error);
	if (local_error == NULL)
		camel_nntp_stream_line (
			nntp_stream, (guchar **) &line,
			&u, cancellable, &local_error);
	if (local_error == NULL && atoi (line) != 240)
		local_error = g_error_new_literal (
			CAMEL_ERROR, CAMEL_ERROR_GENERIC, line);

	if (local_error != NULL) {
		g_propagate_prefixed_error (
			error, local_error, _("Posting failed: "));
		success = FALSE;
	}

	g_object_unref (filtered_stream);
	g_free (group);
	/* restore the bcc headers */
	for (ii = 0; camel_name_value_array_get (previous_headers, ii, &header_name, &header_value); ii++) {
		if (!g_ascii_strcasecmp (header_name, "To") ||
		    !g_ascii_strcasecmp (header_name, "Cc") ||
		    !g_ascii_strcasecmp (header_name, "Bcc")) {
			camel_medium_add_header (CAMEL_MEDIUM (message), header_name, header_value);
		}
	}

	camel_name_value_array_free (previous_headers);

 exit:
	if (nntp_stream)
		camel_nntp_stream_unlock (nntp_stream);
	g_clear_object (&nntp_stream);

	return success;
}

static gboolean
nntp_folder_expunge_sync (CamelFolder *folder,
                          GCancellable *cancellable,
                          GError **error)
{
	CamelFolderSummary *summary;
	CamelFolderChangeInfo *changes;
	GPtrArray *known_uids;
	guint ii;

	summary = camel_folder_get_folder_summary (folder);

	camel_folder_summary_prepare_fetch_all (summary, NULL);
	known_uids = camel_folder_summary_get_array (summary);

	if (known_uids == NULL)
		return TRUE;

	changes = camel_folder_change_info_new ();

	for (ii = 0; ii < known_uids->len; ii++) {
		CamelMessageInfo *info;
		const gchar *uid;

		uid = g_ptr_array_index (known_uids, ii);
		info = camel_folder_summary_get (summary, uid);

		if (camel_message_info_get_flags (info) & CAMEL_MESSAGE_DELETED) {
			camel_folder_change_info_remove_uid (changes, uid);
			camel_folder_summary_remove (summary, info);
		}

		g_clear_object (&info);
	}

	camel_folder_summary_save (summary, NULL);
	camel_folder_changed (folder, changes);

	camel_folder_change_info_free (changes);
	camel_folder_summary_free_array (known_uids);

	return TRUE;
}

static CamelMimeMessage *
nntp_folder_get_message_cached (CamelFolder *folder,
				const gchar *uid,
				GCancellable *cancellable)
{
	CamelMimeMessage *message = NULL;
	CamelDataCache *nntp_cache;
	CamelNNTPStore *nntp_store;
	GIOStream *base_stream;
	gchar *article, *msgid;
	gsize article_len;

	g_return_val_if_fail (CAMEL_IS_NNTP_FOLDER (folder), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	article_len = strlen (uid) + 1;
	article = alloca (article_len);
	g_strlcpy (article, uid, article_len);
	msgid = strchr (article, ',');
	if (!msgid)
		return NULL;

	*msgid++ = 0;

	nntp_store = CAMEL_NNTP_STORE (camel_folder_get_parent_store (folder));

	/* Lookup in cache, NEWS is global messageid's so use a global cache path */
	nntp_cache = camel_nntp_store_ref_cache (nntp_store);
	base_stream = camel_data_cache_get (nntp_cache, "cache", msgid, NULL);
	g_clear_object (&nntp_cache);

	if (base_stream) {
		CamelStream *stream;

		stream = camel_stream_new (base_stream);
		g_object_unref (base_stream);

		message = camel_mime_message_new ();
		if (!camel_data_wrapper_construct_from_stream_sync (CAMEL_DATA_WRAPPER (message), stream, cancellable, NULL)) {
			g_object_unref (message);
			message = NULL;
		}

		g_object_unref (stream);
	}

	return message;
}

static CamelMimeMessage *
nntp_folder_get_message_sync (CamelFolder *folder,
                              const gchar *uid,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelStore *parent_store;
	CamelMimeMessage *message = NULL;
	CamelDataCache *nntp_cache;
	CamelNNTPStore *nntp_store;
	CamelFolderChangeInfo *changes;
	CamelNNTPFolder *nntp_folder;
	CamelStream *stream = NULL;
	GIOStream *base_stream;
	gchar *article, *msgid;
	gsize article_len;

	g_return_val_if_fail (CAMEL_IS_NNTP_FOLDER (folder), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	parent_store = camel_folder_get_parent_store (folder);

	nntp_folder = CAMEL_NNTP_FOLDER (folder);
	nntp_store = CAMEL_NNTP_STORE (parent_store);

	article_len = strlen (uid) + 1;
	article = alloca (article_len);
	g_strlcpy (article, uid, article_len);
	msgid = strchr (article, ',');
	if (msgid == NULL) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Internal error: UID in invalid format: %s"), uid);
		return NULL;
	}
	*msgid++ = 0;

	/* Lookup in cache, NEWS is global messageid's so use a global cache path */
	nntp_cache = camel_nntp_store_ref_cache (nntp_store);
	base_stream = camel_data_cache_get (nntp_cache, "cache", msgid, NULL);
	g_clear_object (&nntp_cache);

	if (base_stream != NULL) {
		stream = camel_stream_new (base_stream);
		g_object_unref (base_stream);
	} else {
		CamelServiceConnectionStatus connection_status;

		connection_status = camel_service_get_connection_status (
			CAMEL_SERVICE (parent_store));

		if (connection_status != CAMEL_SERVICE_CONNECTED) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_UNAVAILABLE,
				_("This message is not currently available"));
			goto fail;
		}

		stream = nntp_folder_download_message (nntp_folder, article, msgid, cancellable, error);
		if (stream == NULL)
			goto fail;
	}

	message = camel_mime_message_new ();
	if (!camel_data_wrapper_construct_from_stream_sync ((CamelDataWrapper *) message, stream, cancellable, error)) {
		g_prefix_error (error, _("Cannot get message %s: "), uid);
		g_object_unref (message);
		message = NULL;
	}

	g_object_unref (stream);
fail:
	if (camel_folder_change_info_changed (nntp_folder->changes)) {
		changes = nntp_folder->changes;
		nntp_folder->changes = camel_folder_change_info_new ();
	} else {
		changes = NULL;
	}

	if (changes) {
		camel_folder_changed (folder, changes);
		camel_folder_change_info_free (changes);
	}

	return message;
}

static gboolean
nntp_folder_refresh_info_sync (CamelFolder *folder,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelStore *parent_store;
	CamelNNTPStore *nntp_store;
	CamelFolderChangeInfo *changes = NULL;
	CamelNNTPFolder *nntp_folder;
	gchar *line;
	gboolean success;

	parent_store = camel_folder_get_parent_store (folder);

	nntp_folder = CAMEL_NNTP_FOLDER (folder);
	nntp_store = CAMEL_NNTP_STORE (parent_store);

	/* When invoked with no fmt, camel_nntp_command() just selects the folder
	 * and should return zero. */
	success = !camel_nntp_command (
		nntp_store, cancellable, error, nntp_folder, NULL, &line, NULL);

	if (camel_folder_change_info_changed (nntp_folder->changes)) {
		changes = nntp_folder->changes;
		nntp_folder->changes = camel_folder_change_info_new ();
	}

	if (changes) {
		camel_folder_changed (folder, changes);
		camel_folder_change_info_free (changes);
	}

	return success;
}

static gboolean
nntp_folder_synchronize_sync (CamelFolder *folder,
                              gboolean expunge,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelFolderSummary *summary;
	GPtrArray *changed;

	if (expunge) {
		if (!camel_folder_expunge_sync (folder, cancellable, error))
			return FALSE;
	}

	summary = camel_folder_get_folder_summary (folder);

	changed = camel_folder_summary_get_changed (summary);
	if (changed != NULL) {
		g_ptr_array_foreach (
			changed, (GFunc) unset_flagged_flag, summary);
		g_ptr_array_foreach (
			changed, (GFunc) camel_pstring_free, NULL);
		camel_folder_summary_touch (summary);
		g_ptr_array_free (changed, TRUE);
	}

	return camel_folder_summary_save (summary, error);
}

static gboolean
nntp_folder_transfer_messages_to_sync (CamelFolder *source,
                                       GPtrArray *uids,
                                       CamelFolder *dest,
                                       gboolean delete_originals,
                                       GPtrArray **transferred_uids,
                                       GCancellable *cancellable,
                                       GError **error)
{
	g_set_error (
		error, CAMEL_SERVICE_ERROR,
		CAMEL_SERVICE_ERROR_UNAVAILABLE,
		_("You cannot copy messages from a NNTP folder"));

	return FALSE;
}

static void
nntp_folder_changed (CamelFolder *folder,
		     CamelFolderChangeInfo *info)
{
	g_return_if_fail (CAMEL_IS_NNTP_FOLDER (folder));

	if (info && info->uid_removed && info->uid_removed->len) {
		CamelDataCache *nntp_cache;

		nntp_cache = camel_nntp_store_ref_cache (CAMEL_NNTP_STORE (camel_folder_get_parent_store (folder)));

		if (nntp_cache) {
			guint ii;

			for (ii = 0; ii < info->uid_removed->len; ii++) {
				const gchar *message_uid = info->uid_removed->pdata[ii], *real_uid;

				if (!message_uid)
					continue;

				real_uid = strchr (message_uid, ',');
				if (real_uid)
					camel_data_cache_remove (nntp_cache, "cache", real_uid + 1, NULL);
			}

			g_object_unref (nntp_cache);
		}
	}

	/* Chain up to parent's method. */
	CAMEL_FOLDER_CLASS (camel_nntp_folder_parent_class)->changed (folder, info);
}

static void
camel_nntp_folder_class_init (CamelNNTPFolderClass *class)
{
	GObjectClass *object_class;
	CamelFolderClass *folder_class;

	g_type_class_add_private (class, sizeof (CamelNNTPFolderPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = nntp_folder_set_property;
	object_class->get_property = nntp_folder_get_property;
	object_class->dispose = nntp_folder_dispose;
	object_class->finalize = nntp_folder_finalize;

	folder_class = CAMEL_FOLDER_CLASS (class);
	folder_class->search_by_expression = nntp_folder_search_by_expression;
	folder_class->count_by_expression = nntp_folder_count_by_expression;
	folder_class->search_by_uids = nntp_folder_search_by_uids;
	folder_class->search_free = nntp_folder_search_free;
	folder_class->get_filename = nntp_get_filename;
	folder_class->append_message_sync = nntp_folder_append_message_sync;
	folder_class->expunge_sync = nntp_folder_expunge_sync;
	folder_class->get_message_cached = nntp_folder_get_message_cached;
	folder_class->get_message_sync = nntp_folder_get_message_sync;
	folder_class->refresh_info_sync = nntp_folder_refresh_info_sync;
	folder_class->synchronize_sync = nntp_folder_synchronize_sync;
	folder_class->transfer_messages_to_sync = nntp_folder_transfer_messages_to_sync;
	folder_class->changed = nntp_folder_changed;

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
}

static void
camel_nntp_folder_init (CamelNNTPFolder *nntp_folder)
{
	nntp_folder->priv = CAMEL_NNTP_FOLDER_GET_PRIVATE (nntp_folder);

	nntp_folder->changes = camel_folder_change_info_new ();
	g_mutex_init (&nntp_folder->priv->search_lock);
	g_mutex_init (&nntp_folder->priv->cache_lock);
}

CamelFolder *
camel_nntp_folder_new (CamelStore *parent,
                       const gchar *folder_name,
                       GCancellable *cancellable,
                       GError **error)
{
	CamelFolder *folder;
	CamelNNTPFolder *nntp_folder;
	CamelNNTPStore *nntp_store;
	CamelNNTPStoreSummary *nntp_store_summary;
	gchar *storage_path, *root;
	CamelService *service;
	CamelSettings *settings;
	CamelStoreInfo *si;
	const gchar *user_cache_dir;
	gboolean subscribed = TRUE;
	gboolean filter_all = FALSE, filter_junk = TRUE;

	service = CAMEL_SERVICE (parent);
	user_cache_dir = camel_service_get_user_cache_dir (service);

	settings = camel_service_ref_settings (service);

	g_object_get (
		settings,
		"filter-all", &filter_all,
		"filter-junk", &filter_junk,
		NULL);

	g_object_unref (settings);

	folder = g_object_new (
		CAMEL_TYPE_NNTP_FOLDER,
		"display-name", folder_name,
		"full-name", folder_name,
		"parent-store", parent, NULL);
	nntp_folder = (CamelNNTPFolder *) folder;

	camel_folder_set_flags (folder, camel_folder_get_flags (folder) | CAMEL_FOLDER_HAS_SUMMARY_CAPABILITY);

	storage_path = g_build_filename (user_cache_dir, folder_name, NULL);
	root = g_strdup_printf ("%s.cmeta", storage_path);
	camel_object_set_state_filename (CAMEL_OBJECT (nntp_folder), root);
	camel_object_state_read (CAMEL_OBJECT (nntp_folder));
	g_free (root);
	g_free (storage_path);

	camel_folder_take_folder_summary (folder, (CamelFolderSummary *) camel_nntp_summary_new (folder));

	if (filter_all || nntp_folder_get_apply_filters (nntp_folder))
		camel_folder_set_flags (folder, camel_folder_get_flags (folder) | CAMEL_FOLDER_FILTER_RECENT);

	if (filter_junk)
		camel_folder_set_flags (folder, camel_folder_get_flags (folder) | CAMEL_FOLDER_FILTER_JUNK);

	camel_folder_summary_load (camel_folder_get_folder_summary (folder), NULL);

	nntp_store = CAMEL_NNTP_STORE (parent);
	nntp_store_summary = camel_nntp_store_ref_summary (nntp_store);

	si = camel_store_summary_path (
		CAMEL_STORE_SUMMARY (nntp_store_summary), folder_name);
	if (si != NULL) {
		subscribed =
			(si->flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED) != 0;
		camel_store_summary_info_unref (
			CAMEL_STORE_SUMMARY (nntp_store_summary), si);
	}

	camel_store_summary_connect_folder_summary (
		CAMEL_STORE_SUMMARY (nntp_store_summary),
		folder_name, camel_folder_get_folder_summary (folder));

	g_clear_object (&nntp_store_summary);

	if (subscribed &&
	    camel_service_get_connection_status (service) == CAMEL_SERVICE_CONNECTED &&
	    !camel_folder_refresh_info_sync (folder, cancellable, error)) {
		g_object_unref (folder);
		folder = NULL;
	}

	return folder;
}
