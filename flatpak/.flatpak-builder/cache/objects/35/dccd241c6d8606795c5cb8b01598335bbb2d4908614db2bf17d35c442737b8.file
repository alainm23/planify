/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-pop3-folder.c : class for a pop3 folder
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
 * Authors: Dan Winship <danw@ximian.com>
 *          Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <stdlib.h>
#include <string.h>

#include <glib/gi18n-lib.h>

#include "camel-pop3-folder.h"
#include "camel-pop3-store.h"
#include "camel-pop3-settings.h"

#define d(x) if (camel_debug("pop3")) x;

typedef struct _CamelPOP3FolderInfo CamelPOP3FolderInfo;

struct _CamelPOP3FolderInfo {
	guint32 id;
	guint32 size;
	guint32 flags;
	guint32 index;		/* index of request */
	gchar *uid;
	struct _CamelPOP3Command *cmd;
	struct _CamelStream *stream;
};

G_DEFINE_TYPE (CamelPOP3Folder, camel_pop3_folder, CAMEL_TYPE_FOLDER)

static void
cmd_uidl (CamelPOP3Engine *pe,
          CamelPOP3Stream *stream,
          GCancellable *cancellable,
          GError **error,
          gpointer data)
{
	gint ret;
	guint len;
	guchar *line;
	gchar uid[1025];
	guint id;
	CamelPOP3FolderInfo *fi;
	CamelPOP3Folder *folder = data;

	do {
		ret = camel_pop3_stream_line (stream, &line, &len, cancellable, error);
		if (ret >= 0) {
			if (strlen ((gchar *) line) > 1024)
				line[1024] = 0;
			if (sscanf ((gchar *) line, "%u %s", &id, uid) == 2) {
				fi = g_hash_table_lookup (folder->uids_id, GINT_TO_POINTER (id));
				if (fi) {
					camel_operation_progress (cancellable, (fi->index + 1) * 100 / folder->uids->len);
					fi->uid = g_strdup (uid);
					g_hash_table_insert (folder->uids_fi, fi->uid, fi);
				} else {
					g_warning ("ID %u (uid: %s) not in previous LIST output", id, uid);
				}
			}
		}
	} while (ret > 0);
}

/* create a uid from md5 of 'top' output */
static void
cmd_builduid (CamelPOP3Engine *pe,
              CamelPOP3Stream *stream,
              GCancellable *cancellable,
              GError **error,
              gpointer data)
{
	GChecksum *checksum;
	CamelPOP3FolderInfo *fi = data;
	CamelNameValueArray *h;
	CamelMimeParser *mp;
	guint8 *digest;
	gsize length;
	guint ii;
	const gchar *header_name = NULL, *header_value = NULL;

	length = g_checksum_type_get_length (G_CHECKSUM_MD5);
	digest = g_alloca (length);

	/* TODO; somehow work out the limit and use that for proper progress reporting
	 * We need a pointer to the folder perhaps? */
	/* camel_operation_progress (cancellable, fi->id); */

	checksum = g_checksum_new (G_CHECKSUM_MD5);
	mp = camel_mime_parser_new ();
	camel_mime_parser_init_with_stream (mp, (CamelStream *) stream, NULL);
	switch (camel_mime_parser_step (mp, NULL, NULL)) {
	case CAMEL_MIME_PARSER_STATE_HEADER:
	case CAMEL_MIME_PARSER_STATE_MESSAGE:
	case CAMEL_MIME_PARSER_STATE_MULTIPART:
		h = camel_mime_parser_dup_headers (mp);
		for (ii = 0; camel_name_value_array_get (h, ii, &header_name, &header_value); ii++) {
			if (g_ascii_strcasecmp (header_name, "status") != 0
			    && g_ascii_strcasecmp (header_name, "x-status") != 0) {
				g_checksum_update (checksum, (guchar *) header_name, -1);
				g_checksum_update (checksum, (guchar *) header_value, -1);
			}
		}

		camel_name_value_array_free (h);
	default:
		break;
	}
	g_object_unref (mp);
	g_checksum_get_digest (checksum, digest, &length);
	g_checksum_free (checksum);

	fi->uid = g_base64_encode ((guchar *) digest, length);

	d (printf ("building uid for id '%d' = '%s'\n", fi->id, fi->uid));
}

static void
cmd_list (CamelPOP3Engine *pe,
          CamelPOP3Stream *stream,
          GCancellable *cancellable,
          GError **error,
          gpointer data)
{
	gint ret;
	guint len, id, size;
	guchar *line;
	CamelFolder *folder = data;
	CamelPOP3FolderInfo *fi;
	CamelPOP3Folder *pop3_folder;

	g_return_if_fail (pe != NULL);

	pop3_folder = (CamelPOP3Folder *) folder;

	do {
		ret = camel_pop3_stream_line (stream, &line, &len, cancellable, error);
		if (ret >= 0) {
			if (sscanf ((gchar *) line, "%u %u", &id, &size) == 2) {
				fi = g_malloc0 (sizeof (*fi));
				fi->size = size;
				fi->id = id;
				fi->index = ((CamelPOP3Folder *) folder)->uids->len;
				if ((pe->capa & CAMEL_POP3_CAP_UIDL) == 0)
					fi->cmd = camel_pop3_engine_command_new (
						pe,
						CAMEL_POP3_COMMAND_MULTI,
						cmd_builduid, fi,
						cancellable, error,
						"TOP %u 0\r\n", id);
				g_ptr_array_add (pop3_folder->uids, fi);
				g_hash_table_insert (
					pop3_folder->uids_id,
					GINT_TO_POINTER (id), fi);
			}
		}
	} while (ret > 0);
}

static void
cmd_tocache (CamelPOP3Engine *pe,
             CamelPOP3Stream *stream,
             GCancellable *cancellable,
             GError **error,
             gpointer data)
{
	CamelPOP3FolderInfo *fi = data;
	gchar buffer[2048];
	gint w = 0, n;
	GError *local_error = NULL;

	/* What if it fails? */

	/* We write an '*' to the start of the stream to say its not complete yet */
	/* This should probably be part of the cache code */
	if ((n = camel_stream_write (fi->stream, "*", 1, cancellable, &local_error)) == -1)
		goto done;

	while ((n = camel_stream_read ((CamelStream *) stream, buffer, sizeof (buffer), cancellable, &local_error)) > 0) {
		n = camel_stream_write (fi->stream, buffer, n, cancellable, &local_error);
		if (n == -1)
			break;

		w += n;
		if (w > fi->size)
			w = fi->size;
		if (fi->size != 0)
			camel_operation_progress (cancellable, (w * 100) / fi->size);
	}

	/* it all worked, output a '#' to say we're a-ok */
	if (local_error == NULL) {
		g_seekable_seek (
			G_SEEKABLE (fi->stream),
			0, G_SEEK_SET, cancellable, NULL);
		camel_stream_write (fi->stream, "#", 1, cancellable, &local_error);
	}

done:
	if (local_error != NULL) {
		g_propagate_error (error, local_error);
	}

	g_object_unref (fi->stream);
	fi->stream = NULL;
}

static void
pop3_folder_dispose (GObject *object)
{
	CamelPOP3Folder *pop3_folder = CAMEL_POP3_FOLDER (object);
	CamelPOP3Store *pop3_store = NULL;
	CamelStore *parent_store;

	parent_store = camel_folder_get_parent_store (CAMEL_FOLDER (object));
	if (parent_store)
		pop3_store = CAMEL_POP3_STORE (parent_store);

	if (pop3_folder->uids) {
		gint i;
		CamelPOP3FolderInfo **fi = (CamelPOP3FolderInfo **) pop3_folder->uids->pdata;
		gboolean is_online = camel_service_get_connection_status (CAMEL_SERVICE (parent_store)) == CAMEL_SERVICE_CONNECTED;

		for (i = 0; i < pop3_folder->uids->len; i++, fi++) {
			if (fi[0]->cmd && pop3_store && is_online) {
				CamelPOP3Engine *pop3_engine;

				pop3_engine = camel_pop3_store_ref_engine (pop3_store);

				while (camel_pop3_engine_iterate (pop3_engine, fi[0]->cmd, NULL, NULL) > 0)
					;
				camel_pop3_engine_command_free (pop3_engine, fi[0]->cmd);

				g_clear_object (&pop3_engine);
			}

			g_free (fi[0]->uid);
			g_free (fi[0]);
		}

		g_ptr_array_free (pop3_folder->uids, TRUE);
		pop3_folder->uids = NULL;
	}

	if (pop3_folder->uids_fi) {
		g_hash_table_destroy (pop3_folder->uids_fi);
		pop3_folder->uids_fi = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_pop3_folder_parent_class)->dispose (object);
}

static gint
pop3_folder_get_message_count (CamelFolder *folder)
{
	CamelPOP3Folder *pop3_folder = CAMEL_POP3_FOLDER (folder);

	return pop3_folder->uids->len;
}

static GPtrArray *
pop3_folder_get_uids (CamelFolder *folder)
{
	CamelPOP3Folder *pop3_folder = CAMEL_POP3_FOLDER (folder);
	GPtrArray *uids = g_ptr_array_new ();
	CamelPOP3FolderInfo **fi = (CamelPOP3FolderInfo **) pop3_folder->uids->pdata;
	gint i;

	for (i = 0; i < pop3_folder->uids->len; i++,fi++) {
		if (fi[0]->uid)
			g_ptr_array_add (uids, fi[0]->uid);
	}

	return uids;
}

static GPtrArray *
pop3_get_uncached_uids (CamelFolder *folder,
                        GPtrArray *uids,
                        GError **error)
{
	CamelPOP3Folder *pop3_folder;
	CamelPOP3Store *pop3_store;
	GPtrArray *uncached_uids;
	gint ii;

	g_return_val_if_fail (CAMEL_IS_POP3_FOLDER (folder), NULL);
	g_return_val_if_fail (uids != NULL, NULL);

	pop3_folder = CAMEL_POP3_FOLDER (folder);
	pop3_store = CAMEL_POP3_STORE (camel_folder_get_parent_store (folder));

	uncached_uids = g_ptr_array_new ();

	for (ii = 0; ii < uids->len; ii++) {
		const gchar *uid = uids->pdata[ii];
		CamelPOP3FolderInfo *fi;
		gboolean uid_is_cached = FALSE;

		fi = g_hash_table_lookup (pop3_folder->uids_fi, uid);

		if (fi != NULL) {
			uid_is_cached = camel_pop3_store_cache_has (
				pop3_store, fi->uid);
		}

		if (!uid_is_cached) {
			g_ptr_array_add (
				uncached_uids, (gpointer)
				camel_pstring_strdup (uid));
		}
	}

	return uncached_uids;
}

static gchar *
pop3_folder_get_filename (CamelFolder *folder,
                          const gchar *uid,
                          GError **error)
{
	CamelStore *parent_store;
	CamelPOP3Folder *pop3_folder;
	CamelPOP3Store *pop3_store;
	CamelDataCache *pop3_cache;
	CamelPOP3FolderInfo *fi;
	gchar *filename;

	parent_store = camel_folder_get_parent_store (folder);

	pop3_folder = CAMEL_POP3_FOLDER (folder);
	pop3_store = CAMEL_POP3_STORE (parent_store);

	fi = g_hash_table_lookup (pop3_folder->uids_fi, uid);
	if (fi == NULL) {
		g_set_error (
			error, CAMEL_FOLDER_ERROR,
			CAMEL_FOLDER_ERROR_INVALID_UID,
			_("No message with UID %s"), uid);
		return NULL;
	}

	pop3_cache = camel_pop3_store_ref_cache (pop3_store);
	if (!pop3_cache) {
		g_warn_if_reached ();
		return NULL;
	}

	filename = camel_data_cache_get_filename (
		pop3_cache, "cache", fi->uid);
	g_clear_object (&pop3_cache);

	return filename;
}

static gboolean
pop3_folder_set_message_flags (CamelFolder *folder,
                               const gchar *uid,
                               guint32 flags,
                               guint32 set)
{
	CamelPOP3Folder *pop3_folder = CAMEL_POP3_FOLDER (folder);
	CamelPOP3FolderInfo *fi;
	gboolean res = FALSE;

	fi = g_hash_table_lookup (pop3_folder->uids_fi, uid);
	if (fi) {
		guint32 new = (fi->flags & ~flags) | (set & flags);

		if (fi->flags != new) {
			fi->flags = new;
			res = TRUE;
		}
	}

	return res;
}

static CamelMimeMessage *
pop3_folder_get_message_internal_sync (CamelFolder *folder,
				       const gchar *uid,
				       gboolean already_locked,
				       GCancellable *cancellable,
				       GError **error)
{
	CamelStore *parent_store;
	CamelMimeMessage *message = NULL;
	CamelPOP3Store *pop3_store;
	CamelPOP3Folder *pop3_folder;
	CamelPOP3Engine *pop3_engine;
	CamelPOP3Command *pcr;
	CamelPOP3FolderInfo *fi;
	gchar buffer[1];
	gint i = -1, last;
	CamelStream *stream = NULL;
	CamelService *service;
	CamelSettings *settings;
	gboolean auto_fetch;

	g_return_val_if_fail (uid != NULL, NULL);

	parent_store = camel_folder_get_parent_store (folder);

	pop3_folder = CAMEL_POP3_FOLDER (folder);
	pop3_store = CAMEL_POP3_STORE (parent_store);

	service = CAMEL_SERVICE (parent_store);

	settings = camel_service_ref_settings (service);

	g_object_get (
		settings,
		"auto-fetch", &auto_fetch,
		NULL);

	g_object_unref (settings);

	fi = g_hash_table_lookup (pop3_folder->uids_fi, uid);
	if (fi == NULL) {
		g_set_error (
			error, CAMEL_FOLDER_ERROR,
			CAMEL_FOLDER_ERROR_INVALID_UID,
			_("No message with UID %s"), uid);
		return NULL;
	}

	if (camel_service_get_connection_status (CAMEL_SERVICE (parent_store)) != CAMEL_SERVICE_CONNECTED) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		return NULL;
	}

	/* Sigh, most of the crap in this function is so that the cancel button
	 * returns the proper exception code.  Sigh. */

	camel_operation_push_message (
		cancellable, _("Retrieving POP message %d"), fi->id);

	pop3_engine = camel_pop3_store_ref_engine (pop3_store);

	if (!already_locked && !camel_pop3_engine_busy_lock (pop3_engine, cancellable, error))
		goto fail;

	/* If we have an oustanding retrieve message running, wait for that to complete
	 * & then retrieve from cache, otherwise, start a new one, and similar */

	if (fi->cmd != NULL) {
		while ((i = camel_pop3_engine_iterate (pop3_engine, fi->cmd, cancellable, error)) > 0)
			;

		/* getting error code? */
		/*g_warn_if_fail (fi->cmd->state == CAMEL_POP3_COMMAND_DATA);*/
		camel_pop3_engine_command_free (pop3_engine, fi->cmd);
		fi->cmd = NULL;

		if (i == -1) {
			g_prefix_error (
				error, _("Cannot get message %s: "), uid);
			if (!already_locked)
				camel_pop3_engine_busy_unlock (pop3_engine);
			goto fail;
		}
	}

	/* check to see if we have safely written flag set */
	stream = camel_pop3_store_cache_get (pop3_store, fi->uid, NULL);
	if (!stream) {
		GError *local_error = NULL;

		/* Initiate retrieval, if disk backing fails, use a memory backing */
		stream = camel_pop3_store_cache_add (pop3_store, fi->uid, NULL);
		if (stream == NULL)
			stream = camel_stream_mem_new ();

		/* ref it, the cache storage routine unref's when done */
		fi->stream = g_object_ref (stream);
		pcr = camel_pop3_engine_command_new (
			pop3_engine,
			CAMEL_POP3_COMMAND_MULTI,
			cmd_tocache, fi,
			cancellable, &local_error,
			"RETR %u\r\n", fi->id);

		if (local_error) {
			if (pcr)
				camel_pop3_engine_command_free (pop3_engine, pcr);

			g_propagate_error (error, local_error);
			g_prefix_error (
				error, _("Cannot get message %s: "), uid);
			goto done;
		}

		/* Also initiate retrieval of some of the following
		 * messages, assume we'll be receiving them. */
		if (auto_fetch) {
			/* This should keep track of the last one retrieved,
			 * also how many are still oustanding incase of random
			 * access on large folders. */
			i = fi->index + 1;
			last = MIN (i + 10, pop3_folder->uids->len);
			for (; i < last; i++) {
				CamelPOP3FolderInfo *pfi = pop3_folder->uids->pdata[i];

				if (pfi->uid && !pfi->cmd && !camel_pop3_store_cache_has (pop3_store, pfi->uid)) {
					pfi->stream = camel_pop3_store_cache_add (
						pop3_store, pfi->uid, NULL);
					if (pfi->stream != NULL) {
						pfi->cmd = camel_pop3_engine_command_new (
							pop3_engine,
							CAMEL_POP3_COMMAND_MULTI,
							cmd_tocache, pfi,
							cancellable, &local_error,
							"RETR %u\r\n", pfi->id);

						if (local_error) {
							if (pcr)
								camel_pop3_engine_command_free (pop3_engine, pcr);

							g_propagate_error (error, local_error);
							g_prefix_error (
								error, _("Cannot get message %s: "), uid);
							goto done;
						}
					}
				}
			}
		}

		/* now wait for the first one to finish */
		while (!local_error && (i = camel_pop3_engine_iterate (pop3_engine, pcr, cancellable, &local_error)) > 0)
			;

		/* getting error code? */
		/*g_warn_if_fail (pcr->state == CAMEL_POP3_COMMAND_DATA);*/
		camel_pop3_engine_command_free (pop3_engine, pcr);
		g_seekable_seek (
			G_SEEKABLE (stream), 0, G_SEEK_SET, NULL, NULL);

		/* Check to see we have safely written flag set */
		if (i == -1 || local_error) {
			g_propagate_error (error, local_error);
			g_prefix_error (
				error, _("Cannot get message %s: "), uid);
			goto done;
		}

		if (camel_stream_read (stream, buffer, 1, cancellable, error) == -1)
			goto done;

		if (buffer[0] != '#') {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Cannot get message %s: %s"), uid,
				_("Unknown reason"));
			goto done;
		}
	}

	message = camel_mime_message_new ();
	if (stream != NULL && !camel_data_wrapper_construct_from_stream_sync (
		CAMEL_DATA_WRAPPER (message), stream, cancellable, error)) {
		g_prefix_error (error, _("Cannot get message %s: "), uid);
		g_object_unref (message);
		message = NULL;
	} else {
		/* because the UID in the local store doesn't match with the UID in the pop3 store */
		camel_medium_add_header (CAMEL_MEDIUM (message), "X-Evolution-POP3-UID", uid);
	}
done:
	if (!already_locked)
		camel_pop3_engine_busy_unlock (pop3_engine);
	g_clear_object (&stream);
fail:
	g_clear_object (&pop3_engine);

	camel_operation_pop_message (cancellable);

	return message;
}

static CamelMimeMessage *
pop3_folder_get_message_sync (CamelFolder *folder,
                              const gchar *uid,
                              GCancellable *cancellable,
                              GError **error)
{
	return pop3_folder_get_message_internal_sync (folder, uid, FALSE, cancellable, error);
}

static gboolean
pop3_folder_refresh_info_sync (CamelFolder *folder,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelStore *parent_store;
	CamelPOP3Store *pop3_store;
	CamelPOP3Folder *pop3_folder = (CamelPOP3Folder *) folder;
	CamelPOP3Engine *pop3_engine;
	CamelPOP3Command *pcl, *pcu = NULL;
	gboolean success = TRUE;
	GError *local_error = NULL;
	gint i;

	parent_store = camel_folder_get_parent_store (folder);
	pop3_store = CAMEL_POP3_STORE (parent_store);

	if (camel_service_get_connection_status (CAMEL_SERVICE (parent_store)) != CAMEL_SERVICE_CONNECTED) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		return FALSE;
	}

	pop3_engine = camel_pop3_store_ref_engine (pop3_store);

	if (!camel_pop3_engine_busy_lock (pop3_engine, cancellable, error)) {
		g_clear_object (&pop3_engine);
		return FALSE;
	}

	camel_operation_push_message (
		cancellable, _("Retrieving POP summary"));

	/* Get rid of the old cache */
	if (pop3_folder->uids) {
		gint i;
		CamelPOP3FolderInfo *last_fi;

		if (pop3_folder->uids->len) {
			last_fi = pop3_folder->uids->pdata[pop3_folder->uids->len - 1];
			if (last_fi)
				pop3_folder->latest_id = last_fi->id;
			else
				pop3_folder->latest_id = -1;
		} else
			pop3_folder->latest_id = -1;

		for (i = 0; i < pop3_folder->uids->len; i++) {
			CamelPOP3FolderInfo *fi = pop3_folder->uids->pdata[i];
			if (fi->cmd) {
				camel_pop3_engine_command_free (pop3_engine, fi->cmd);
				fi->cmd = NULL;
			}
			g_free (fi->uid);
			g_free (fi);
		}

		g_ptr_array_free (pop3_folder->uids, TRUE);
	}

	if (pop3_folder->uids_fi) {
		g_hash_table_destroy (pop3_folder->uids_fi);
		pop3_folder->uids_fi = NULL;
	}

	/* Get a new working set. */
	pop3_folder->uids = g_ptr_array_new ();
	pop3_folder->uids_fi = g_hash_table_new (g_str_hash, g_str_equal);

	/* only used during setup */
	pop3_folder->uids_id = g_hash_table_new (NULL, NULL);

	pcl = camel_pop3_engine_command_new (
		pop3_engine,
		CAMEL_POP3_COMMAND_MULTI,
		cmd_list, folder,
		cancellable, &local_error,
		"LIST\r\n");
	if (!local_error && pop3_engine && (pop3_engine->capa & CAMEL_POP3_CAP_UIDL) != 0)
		pcu = camel_pop3_engine_command_new (
			pop3_engine,
			CAMEL_POP3_COMMAND_MULTI,
			cmd_uidl, folder,
			cancellable, &local_error,
			"UIDL\r\n");
	while (!local_error && (i = camel_pop3_engine_iterate (pop3_engine, NULL, cancellable, &local_error)) > 0)
		;

	if (local_error) {
		g_propagate_error (error, local_error);
		g_prefix_error (error, _("Cannot get POP summary: "));
		success = FALSE;
	} else if (i == -1) {
		g_set_error_literal (error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, _("Cannot get POP summary: "));
		success = FALSE;
	}

	/* TODO: check every id has a uid & commands returned OK too? */

	if (pcl) {
		if (success && pcl->state == CAMEL_POP3_COMMAND_ERR) {
			success = FALSE;

			if (pcl->error_str)
				g_set_error_literal (error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, pcl->error_str);
			else
				g_set_error_literal (error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, _("Cannot get POP summary: "));
		}

		camel_pop3_engine_command_free (pop3_engine, pcl);
	}

	if (pcu) {
		if (success && pcu->state == CAMEL_POP3_COMMAND_ERR) {
			success = FALSE;

			if (pcu->error_str)
				g_set_error_literal (error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, pcu->error_str);
			else
				g_set_error_literal (error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, _("Cannot get POP summary: "));
		}

		camel_pop3_engine_command_free (pop3_engine, pcu);
	} else {
		for (i = 0; i < pop3_folder->uids->len; i++) {
			CamelPOP3FolderInfo *fi = pop3_folder->uids->pdata[i];
			if (fi->cmd) {
				if (success && fi->cmd->state == CAMEL_POP3_COMMAND_ERR) {
					success = FALSE;

					if (fi->cmd->error_str)
						g_set_error_literal (error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, fi->cmd->error_str);
					else
						g_set_error_literal (error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, _("Cannot get POP summary: "));
				}

				camel_pop3_engine_command_free (pop3_engine, fi->cmd);
				fi->cmd = NULL;
			}
			if (fi->uid) {
				g_hash_table_insert (pop3_folder->uids_fi, fi->uid, fi);
			}
		}
	}

	/* dont need this anymore */
	g_hash_table_destroy (pop3_folder->uids_id);
	pop3_folder->uids_id = NULL;

	camel_pop3_engine_busy_unlock (pop3_engine);
	g_clear_object (&pop3_engine);

	camel_operation_pop_message (cancellable);

	return success;
}

static guint32
pop3_folder_get_current_time_mark (void)
{
	GDate date;

	g_date_clear (&date, 1);
	g_date_set_time_t (&date, time (NULL));

	return g_date_get_julian (&date);
}

static gboolean
pop3_folder_cache_foreach_remove_cb (CamelDataCache *cache,
				     const gchar *filename,
				     gpointer user_data)
{
	GHashTable *filenames = user_data;

	g_return_val_if_fail (filenames != NULL, FALSE);

	return !g_hash_table_contains (filenames, filename);
}

static void
pop3_folder_maybe_expunge_cache (CamelPOP3Folder *pop3_folder)
{
	CamelService *service;
	CamelSettings *settings;
	CamelDataCache *pop3_cache;
	GHashTable *filenames;
	guint32 last_cache_expunge, current_time;
	gint ii;

	g_return_if_fail (CAMEL_IS_POP3_FOLDER (pop3_folder));

	service = CAMEL_SERVICE (camel_folder_get_parent_store (CAMEL_FOLDER (pop3_folder)));
	g_return_if_fail (CAMEL_IS_SERVICE (service));

	/* Expunge local cache only if online, which should guarantee that
	   the 'pop3_folder->uids' is properly populated. */
	if (camel_service_get_connection_status (service) != CAMEL_SERVICE_CONNECTED)
		return;

	pop3_cache = camel_pop3_store_ref_cache (CAMEL_POP3_STORE (service));
	g_return_if_fail (CAMEL_IS_DATA_CACHE (pop3_cache));

	settings = camel_service_ref_settings (service);

	last_cache_expunge = camel_pop3_settings_get_last_cache_expunge (CAMEL_POP3_SETTINGS (settings));
	current_time = pop3_folder_get_current_time_mark ();

	if (last_cache_expunge + 7 > current_time && current_time >= last_cache_expunge) {
		d (printf ("%s: No need to expunge cache yet; last did %d, now is %d\n", G_STRFUNC, last_cache_expunge, current_time));
		g_clear_object (&pop3_cache);
		g_clear_object (&settings);
		return;
	}

	d (printf ("%s: Going to expunge cache; last did %d, now is %d\n", G_STRFUNC, last_cache_expunge, current_time));
	camel_pop3_settings_set_last_cache_expunge (CAMEL_POP3_SETTINGS (settings), current_time);
	g_clear_object (&settings);

	filenames = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);

	for (ii = 0; ii < pop3_folder->uids->len; ii++) {
		CamelPOP3FolderInfo *fi = pop3_folder->uids->pdata[ii];
		gchar *filename;

		if (!fi || !fi->uid)
			continue;

		filename = camel_data_cache_get_filename (pop3_cache, "cache", fi->uid);
		if (filename)
			g_hash_table_insert (filenames, filename, NULL);
	}

	d (printf ("%s: Recognized %d downloaded messages\n", G_STRFUNC, g_hash_table_size (filenames)));
	camel_data_cache_foreach_remove	(pop3_cache, "cache", pop3_folder_cache_foreach_remove_cb, filenames);

	g_hash_table_destroy (filenames);
	g_clear_object (&pop3_cache);
}

static gboolean
pop3_folder_synchronize_sync (CamelFolder *folder,
                              gboolean expunge,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelService *service;
	CamelSettings *settings;
	CamelStore *parent_store;
	CamelPOP3Folder *pop3_folder;
	CamelPOP3Store *pop3_store;
	CamelDataCache *pop3_cache;
	CamelPOP3Engine *pop3_engine;
	CamelPOP3FolderInfo *fi;
	gint delete_after_days;
	gboolean delete_expunged;
	gboolean keep_on_server;
	gboolean is_online;
	gint i;

	parent_store = camel_folder_get_parent_store (folder);

	pop3_folder = CAMEL_POP3_FOLDER (folder);
	pop3_store = CAMEL_POP3_STORE (parent_store);

	service = CAMEL_SERVICE (parent_store);
	is_online = camel_service_get_connection_status (service) == CAMEL_SERVICE_CONNECTED;

	settings = camel_service_ref_settings (service);

	g_object_get (
		settings,
		"delete-after-days", &delete_after_days,
		"delete-expunged", &delete_expunged,
		"keep-on-server", &keep_on_server,
		NULL);

	g_object_unref (settings);

	if (is_online && delete_after_days > 0 && !expunge && !g_cancellable_is_cancelled (cancellable)) {
		camel_operation_push_message (
			cancellable, _("Expunging old messages"));

		camel_pop3_folder_delete_old (
			folder, delete_after_days, cancellable, error);

		camel_operation_pop_message (cancellable);
	}

	if (g_cancellable_is_cancelled (cancellable)) {
		if (error && !*error) {
			/* coverity[unchecked_value] */
			if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
				;
			}
		}
		return FALSE;
	}

	if (!expunge || (keep_on_server && !delete_expunged)) {
		pop3_folder_maybe_expunge_cache (pop3_folder);
		return TRUE;
	}

	if (!is_online) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		return FALSE;
	}

	camel_operation_push_message (
		cancellable, _("Expunging deleted messages"));

	pop3_cache = camel_pop3_store_ref_cache (pop3_store);
	pop3_engine = camel_pop3_store_ref_engine (pop3_store);

	if (!camel_pop3_engine_busy_lock (pop3_engine, cancellable, error)) {
			g_clear_object (&pop3_cache);
			g_clear_object (&pop3_engine);

			camel_operation_pop_message (cancellable);

			return FALSE;
	}

	for (i = 0; i < pop3_folder->uids->len; i++) {
		if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
			camel_pop3_engine_busy_unlock (pop3_engine);
			g_clear_object (&pop3_cache);
			g_clear_object (&pop3_engine);

			camel_operation_pop_message (cancellable);

			return FALSE;
		}

		fi = pop3_folder->uids->pdata[i];
		/* busy already?  wait for that to finish first */
		if (fi->cmd) {
			while (camel_pop3_engine_iterate (pop3_engine, fi->cmd, cancellable, NULL) > 0)
				;
			camel_pop3_engine_command_free (pop3_engine, fi->cmd);
			fi->cmd = NULL;
		}

		if (fi->flags & CAMEL_MESSAGE_DELETED) {
			fi->cmd = camel_pop3_engine_command_new (
				pop3_engine,
				0, NULL, NULL,
				cancellable, NULL,
				"DELE %u\r\n", fi->id);

			/* also remove from cache */
			if (pop3_cache != NULL && fi->uid)
				camel_data_cache_remove (pop3_cache, "cache", fi->uid, NULL);
		}
	}

	for (i = 0; i < pop3_folder->uids->len; i++) {
		if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
			camel_pop3_engine_busy_unlock (pop3_engine);
			g_clear_object (&pop3_cache);
			g_clear_object (&pop3_engine);

			camel_operation_pop_message (cancellable);

			return FALSE;
		}

		fi = pop3_folder->uids->pdata[i];
		/* wait for delete commands to finish */
		if (fi->cmd) {
			while (camel_pop3_engine_iterate (pop3_engine, fi->cmd, cancellable, NULL) > 0)
				;
			camel_pop3_engine_command_free (pop3_engine, fi->cmd);
			fi->cmd = NULL;
		}
		camel_operation_progress (
			cancellable, (i + 1) * 100 / pop3_folder->uids->len);
	}

	camel_pop3_engine_busy_unlock (pop3_engine);
	g_clear_object (&pop3_cache);
	g_clear_object (&pop3_engine);

	pop3_folder_maybe_expunge_cache (pop3_folder);

	camel_operation_pop_message (cancellable);

	return camel_pop3_store_expunge (pop3_store, cancellable, error);
}

static void
camel_pop3_folder_class_init (CamelPOP3FolderClass *class)
{
	GObjectClass *object_class;
	CamelFolderClass *folder_class;

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = pop3_folder_dispose;

	folder_class = CAMEL_FOLDER_CLASS (class);
	folder_class->get_message_count = pop3_folder_get_message_count;
	folder_class->get_uids = pop3_folder_get_uids;
	folder_class->free_uids = camel_folder_free_shallow;
	folder_class->get_uncached_uids = pop3_get_uncached_uids;
	folder_class->get_filename = pop3_folder_get_filename;
	folder_class->set_message_flags = pop3_folder_set_message_flags;
	folder_class->get_message_sync = pop3_folder_get_message_sync;
	folder_class->refresh_info_sync = pop3_folder_refresh_info_sync;
	folder_class->synchronize_sync = pop3_folder_synchronize_sync;
}

static void
camel_pop3_folder_init (CamelPOP3Folder *pop3_folder)
{
	pop3_folder->uids = g_ptr_array_new ();
	pop3_folder->uids_fi = g_hash_table_new (g_str_hash, g_str_equal);
}

CamelFolder *
camel_pop3_folder_new (CamelStore *parent,
                       GCancellable *cancellable,
                       GError **error)
{
	CamelFolder *folder;
	CamelPOP3Folder *pop3_folder;

	d (printf ("opening pop3 INBOX folder\n"));

	folder = g_object_new (
		CAMEL_TYPE_POP3_FOLDER,
		"full-name", "inbox", "display-name", "inbox",
		"parent-store", parent, NULL);

	pop3_folder = (CamelPOP3Folder *) folder;

	pop3_folder->fetch_more = 0;
	if (camel_service_get_connection_status (CAMEL_SERVICE (parent)) != CAMEL_SERVICE_CONNECTED)
		return folder;

	/* mt-ok, since we dont have the folder-lock for new() */
	if (!camel_folder_refresh_info_sync (folder, cancellable, error)) {
		g_object_unref (folder);
		folder = NULL;
	}

	return folder;
}

static gboolean
pop3_get_message_time_from_cache (CamelFolder *folder,
                                  const gchar *uid,
                                  time_t *message_time)
{
	CamelStore *parent_store;
	CamelPOP3Store *pop3_store;
	CamelStream *stream = NULL;
	gboolean res = FALSE;

	g_return_val_if_fail (folder != NULL, FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (message_time != NULL, FALSE);

	parent_store = camel_folder_get_parent_store (folder);
	pop3_store = CAMEL_POP3_STORE (parent_store);

	stream = camel_pop3_store_cache_get (pop3_store, uid, NULL);
	if (stream != NULL) {
		CamelMimeMessage *message;
		GError *error = NULL;

		message = camel_mime_message_new ();
		camel_data_wrapper_construct_from_stream_sync (
			(CamelDataWrapper *) message, stream, NULL, &error);
		if (error != NULL) {
			g_warning (_("Cannot get message %s: %s"), uid, error->message);
			g_error_free (error);

			g_object_unref (message);
			message = NULL;
		}

		if (message) {
			gint date_offset = 0;

			res = TRUE;
			*message_time = camel_mime_message_get_date (message, &date_offset) + date_offset;

			g_object_unref (message);
		}

		g_object_unref (stream);
	}

	return res;
}

gboolean
camel_pop3_folder_delete_old (CamelFolder *folder,
                              gint days_to_delete,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelStore *parent_store;
	CamelPOP3Folder *pop3_folder;
	CamelPOP3FolderInfo *fi;
	CamelPOP3Engine *pop3_engine;
	CamelPOP3Store *pop3_store;
	CamelDataCache *pop3_cache;
	CamelMimeMessage *message;
	time_t temp, message_time;
	gint i;

	parent_store = camel_folder_get_parent_store (folder);

	if (camel_service_get_connection_status (CAMEL_SERVICE (parent_store)) != CAMEL_SERVICE_CONNECTED) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		return FALSE;
	}

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return FALSE;

	pop3_folder = CAMEL_POP3_FOLDER (folder);
	pop3_store = CAMEL_POP3_STORE (parent_store);
	pop3_cache = camel_pop3_store_ref_cache (pop3_store);
	pop3_engine = camel_pop3_store_ref_engine (pop3_store);

	if (!camel_pop3_engine_busy_lock (pop3_engine, cancellable, error)) {
			g_clear_object (&pop3_cache);
			g_clear_object (&pop3_engine);

			return FALSE;
	}

	temp = time (&temp);

	d (printf ("%s(%d): pop3_folder->uids->len=[%d]\n", __FILE__, __LINE__, pop3_folder->uids->len));
	for (i = 0; i < pop3_folder->uids->len; i++) {
		message_time = 0;
		fi = pop3_folder->uids->pdata[i];

		if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
			camel_pop3_engine_busy_unlock (pop3_engine);
			g_clear_object (&pop3_cache);
			g_clear_object (&pop3_engine);

			return FALSE;
		}

		if (fi->cmd) {
			while (camel_pop3_engine_iterate (pop3_engine, fi->cmd, cancellable, NULL) > 0) {
				; /* do nothing - iterating until end */
			}

			camel_pop3_engine_command_free (pop3_engine, fi->cmd);
			fi->cmd = NULL;
		}

		/* continue, if message wasn't received yet */
		if (!fi->uid)
			continue;

		d (printf ("%s(%d): fi->uid=[%s]\n", __FILE__, __LINE__, fi->uid));
		if (!pop3_get_message_time_from_cache (folder, fi->uid, &message_time)) {
			d (printf ("could not get message time from cache, trying from pop3\n"));
			message = pop3_folder_get_message_internal_sync (
				folder, fi->uid, TRUE, cancellable, error);
			if (message) {
				gint date_offset = 0;
				message_time = camel_mime_message_get_date (message, &date_offset) + date_offset;
				g_object_unref (message);
			}
		}

		if (message_time) {
			gdouble time_diff = difftime (temp, message_time);
			gint day_lag = time_diff / (60 * 60 * 24);

			d (printf (
				"%s(%d): message_time= [%" G_GINT64_FORMAT "]\n",
				__FILE__, __LINE__, (gint64) message_time));
			d (printf (
				"%s(%d): day_lag=[%d] \t days_to_delete=[%d]\n",
				__FILE__, __LINE__, day_lag, days_to_delete));

			if (day_lag >= days_to_delete) {
				if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
					camel_pop3_engine_busy_unlock (pop3_engine);
					g_clear_object (&pop3_cache);
					g_clear_object (&pop3_engine);

					return FALSE;
				}

				if (fi->cmd) {
					while (camel_pop3_engine_iterate (pop3_engine, fi->cmd, cancellable, NULL) > 0) {
						; /* do nothing - iterating until end */
					}

					camel_pop3_engine_command_free (pop3_engine, fi->cmd);
					fi->cmd = NULL;
				}
				d (printf (
					"%s(%d): Deleting old messages\n",
					__FILE__, __LINE__));
				fi->cmd = camel_pop3_engine_command_new (
					pop3_engine,
					0, NULL, NULL,
					cancellable, NULL,
					"DELE %u\r\n", fi->id);
				/* also remove from cache */
				if (pop3_cache != NULL && fi->uid) {
					camel_data_cache_remove (pop3_cache, "cache", fi->uid, NULL);
				}
			}
		}
	}

	for (i = 0; i < pop3_folder->uids->len; i++) {
		if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
			camel_pop3_engine_busy_unlock (pop3_engine);
			g_clear_object (&pop3_cache);
			g_clear_object (&pop3_engine);

			return FALSE;
		}

		fi = pop3_folder->uids->pdata[i];
		/* wait for delete commands to finish */
		if (fi->cmd) {
			while (camel_pop3_engine_iterate (pop3_engine, fi->cmd, cancellable, NULL) > 0)
				;
			camel_pop3_engine_command_free (pop3_engine, fi->cmd);
			fi->cmd = NULL;
		}
		camel_operation_progress (
			cancellable, (i + 1) * 100 / pop3_folder->uids->len);
	}

	camel_pop3_engine_busy_unlock (pop3_engine);
	g_clear_object (&pop3_cache);
	g_clear_object (&pop3_engine);

	return camel_pop3_store_expunge (pop3_store, cancellable, error);
}
