/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; fill-column: 160 -*- */
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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#include <glib/gi18n-lib.h>

#include "camel-nntp-folder.h"
#include "camel-nntp-settings.h"
#include "camel-nntp-store.h"
#include "camel-nntp-stream.h"
#include "camel-nntp-summary.h"

#define w(x)
#define io(x)
#define d(x) /*(printf ("%s (%d): ", __FILE__, __LINE__),(x))*/
#define dd(x) (camel_debug ("nntp")?(x):0)

#define CAMEL_NNTP_SUMMARY_VERSION (1)

#define CAMEL_NNTP_SUMMARY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_NNTP_SUMMARY, CamelNNTPSummaryPrivate))

struct _CamelNNTPSummaryPrivate {
	gchar *uid;
	guint last_full_resync;
	guint last_limit_latest;

	struct _xover_header *xover; /* xoverview format */
	gint xover_setup;
};

static CamelMessageInfo * message_info_new_from_headers (CamelFolderSummary *, const CamelNameValueArray *);
static gboolean summary_header_load (CamelFolderSummary *s, CamelFIRecord *mir);
static CamelFIRecord * summary_header_save (CamelFolderSummary *s, GError **error);

G_DEFINE_TYPE (CamelNNTPSummary, camel_nntp_summary, CAMEL_TYPE_FOLDER_SUMMARY)

static void
camel_nntp_summary_class_init (CamelNNTPSummaryClass *class)
{
	CamelFolderSummaryClass *folder_summary_class;

	g_type_class_add_private (class, sizeof (CamelNNTPSummaryPrivate));

	folder_summary_class = CAMEL_FOLDER_SUMMARY_CLASS (class);
	folder_summary_class->message_info_new_from_headers = message_info_new_from_headers;
	folder_summary_class->summary_header_load = summary_header_load;
	folder_summary_class->summary_header_save = summary_header_save;
}

static void
camel_nntp_summary_init (CamelNNTPSummary *nntp_summary)
{
	CamelFolderSummary *summary = CAMEL_FOLDER_SUMMARY (nntp_summary);

	nntp_summary->priv = CAMEL_NNTP_SUMMARY_GET_PRIVATE (nntp_summary);

	/* and a unique file version */
	camel_folder_summary_set_version (summary, camel_folder_summary_get_version (summary) + CAMEL_NNTP_SUMMARY_VERSION);
}

CamelNNTPSummary *
camel_nntp_summary_new (CamelFolder *folder)
{
	CamelNNTPSummary *cns;

	cns = g_object_new (CAMEL_TYPE_NNTP_SUMMARY, "folder", folder, NULL);

	return cns;
}

static CamelMessageInfo *
message_info_new_from_headers (CamelFolderSummary *summary,
			       const CamelNameValueArray *headers)
{
	CamelMessageInfo *mi;
	CamelNNTPSummary *cns = (CamelNNTPSummary *) summary;

	/* error to call without this setup */
	if (cns->priv->uid == NULL)
		return NULL;

	mi = CAMEL_FOLDER_SUMMARY_CLASS (camel_nntp_summary_parent_class)->message_info_new_from_headers (summary, headers);
	if (mi) {
		camel_message_info_set_uid (mi, cns->priv->uid);
		g_free (cns->priv->uid);
		cns->priv->uid = NULL;
	}

	return mi;
}

static gboolean
summary_header_load (CamelFolderSummary *s,
		     CamelFIRecord *mir)
{
	CamelNNTPSummary *cns = CAMEL_NNTP_SUMMARY (s);
	gchar *part;

	if (!CAMEL_FOLDER_SUMMARY_CLASS (camel_nntp_summary_parent_class)->summary_header_load (s, mir))
		return FALSE;

	part = mir->bdata;

	cns->version = camel_util_bdata_get_number (&part, 0);
	cns->high = camel_util_bdata_get_number (&part, 0);
	cns->low = camel_util_bdata_get_number (&part, 0);
	cns->priv->last_full_resync = camel_util_bdata_get_number (&part, 0);
	cns->priv->last_limit_latest = camel_util_bdata_get_number (&part, 0);

	return TRUE;
}

static CamelFIRecord *
summary_header_save (CamelFolderSummary *s,
		     GError **error)
{
	CamelNNTPSummary *cns = CAMEL_NNTP_SUMMARY (s);
	struct _CamelFIRecord *fir;

	fir = CAMEL_FOLDER_SUMMARY_CLASS (camel_nntp_summary_parent_class)->summary_header_save (s, error);
	if (!fir)
		return NULL;
	fir->bdata = g_strdup_printf ("%d %u %u %u %u", CAMEL_NNTP_SUMMARY_VERSION, cns->high, cns->low, cns->priv->last_full_resync, cns->priv->last_limit_latest);

	return fir;
}

/* ********************************************************************** */

/* Note: This will be called from camel_nntp_command, so only use camel_nntp_raw_command */
static gint
add_range_xover (CamelNNTPSummary *cns,
                 CamelNNTPStore *nntp_store,
                 guint high,
                 guint low,
                 CamelFolderChangeInfo *changes,
                 GCancellable *cancellable,
                 GError **error)
{
	CamelNNTPCapabilities capability = CAMEL_NNTP_CAPABILITY_OVER;
	CamelNNTPStream *nntp_stream;
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	CamelService *service;
	CamelFolderSummary *s;
	CamelNameValueArray *headers = NULL;
	gchar *line, *tab;
	gchar *host;
	guint len;
	gint ret;
	guint n, count, total, size;
	gboolean folder_filter_recent;
	struct _xover_header *xover;

	s = (CamelFolderSummary *) cns;
	folder_filter_recent = camel_folder_summary_get_folder (s) &&
		(camel_folder_get_flags (camel_folder_summary_get_folder (s)) & CAMEL_FOLDER_FILTER_RECENT) != 0;

	service = CAMEL_SERVICE (nntp_store);

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);

	g_object_unref (settings);

	camel_operation_push_message (
		cancellable, _("%s: Scanning new messages"), host);

	g_free (host);

	if (camel_nntp_store_has_capabilities (nntp_store, capability))
		ret = camel_nntp_raw_command_auth (
			nntp_store, cancellable, error,
			&line, "over %r", low, high);
	else
		ret = -1;
	if (ret != 224) {
		camel_nntp_store_remove_capabilities (nntp_store, capability);
		ret = camel_nntp_raw_command_auth (
			nntp_store, cancellable, error,
			&line, "xover %r", low, high);
	}

	if (ret != 224) {
		camel_operation_pop_message (cancellable);
		if (ret != -1)
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Unexpected server response from xover: %s"), line);
		return -1;
	}

	nntp_stream = camel_nntp_store_ref_stream (nntp_store);

	count = 0;
	total = high - low + 1;
	headers = camel_name_value_array_new ();
	while ((ret = camel_nntp_stream_line (nntp_stream, (guchar **) &line, &len, cancellable, error)) > 0) {
		camel_operation_progress (cancellable, (count * 100) / total);
		count++;
		n = strtoul (line, &tab, 10);
		if (*tab != '\t')
			continue;
		tab++;
		xover = nntp_store->xover;
		size = 0;
		for (; tab[0] && xover; xover = xover->next) {
			line = tab;
			tab = strchr (line, '\t');
			if (tab)
				*tab++ = 0;
			else
				tab = line + strlen (line);

			/* do we care about this column? */
			if (xover->name) {
				line += xover->skip;
				if (line < tab) {
					camel_name_value_array_append (headers, xover->name, line);
					switch (xover->type) {
					case XOVER_STRING:
						break;
					case XOVER_MSGID:
						cns->priv->uid = g_strdup_printf ("%u,%s", n, line);
						break;
					case XOVER_SIZE:
						size = strtoul (line, NULL, 10);
						break;
					}
				}
			}
		}

		/* skip headers we don't care about, incase the server doesn't actually send some it said it would. */
		while (xover && xover->name == NULL)
			xover = xover->next;

		/* truncated line? ignore? */
		if (xover == NULL) {
			if (!camel_folder_summary_check_uid (s, cns->priv->uid)) {
				CamelMessageInfo *mi;

				mi = camel_folder_summary_info_new_from_headers (s, headers);
				camel_message_info_set_size (mi, size);
				camel_folder_summary_add (s, mi, FALSE);

				cns->high = n;
				camel_folder_change_info_add_uid (changes, camel_message_info_get_uid (mi));
				if (folder_filter_recent)
					camel_folder_change_info_recent_uid (changes, camel_message_info_get_uid (mi));
				g_clear_object (&mi);
			} else if (cns->high < n) {
				cns->high = n;
			}
		}

		if (cns->priv->uid) {
			g_free (cns->priv->uid);
			cns->priv->uid = NULL;
		}

		camel_name_value_array_clear (headers);
	}

	camel_name_value_array_free (headers);
	g_clear_object (&nntp_stream);

	camel_operation_pop_message (cancellable);

	return ret;
}

/* Note: This will be called from camel_nntp_command, so only use camel_nntp_raw_command */
static gint
add_range_head (CamelNNTPSummary *cns,
                CamelNNTPStore *nntp_store,
                guint high,
                guint low,
                CamelFolderChangeInfo *changes,
                GCancellable *cancellable,
                GError **error)
{
	CamelNNTPStream *nntp_stream;
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	CamelService *service;
	CamelFolderSummary *s;
	gint ret = -1;
	gchar *line, *msgid;
	guint i, n, count, total;
	CamelMessageInfo *mi;
	CamelMimeParser *mp;
	gchar *host;
	gboolean folder_filter_recent;

	s = (CamelFolderSummary *) cns;
	folder_filter_recent = camel_folder_summary_get_folder (s) &&
		(camel_folder_get_flags (camel_folder_summary_get_folder (s)) & CAMEL_FOLDER_FILTER_RECENT) != 0;

	mp = camel_mime_parser_new ();

	service = CAMEL_SERVICE (nntp_store);

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);

	g_object_unref (settings);

	camel_operation_push_message (
		cancellable, _("%s: Scanning new messages"), host);

	g_free (host);

	nntp_stream = camel_nntp_store_ref_stream (nntp_store);

	count = 0;
	total = high - low + 1;
	for (i = low; i < high + 1; i++) {
		camel_operation_progress (cancellable, (count * 100) / total);
		count++;
		ret = camel_nntp_raw_command_auth (
			nntp_store, cancellable, error, &line, "head %u", i);
		/* unknown article, ignore */
		if (ret == 423)
			continue;
		else if (ret == -1)
			goto error;
		else if (ret != 221) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Unexpected server response from head: %s"),
				line);
			goto ioerror;
		}
		line += 3;
		n = strtoul (line, &line, 10);
		if (n != i)
			g_warning ("retrieved message '%u' when i expected '%u'?\n", n, i);

		/* FIXME: use camel-mime-utils.c function for parsing msgid? */
		if ((msgid = strchr (line, '<')) && (line = strchr (msgid + 1, '>'))) {
			line[1] = 0;
			cns->priv->uid = g_strdup_printf ("%u,%s\n", n, msgid);
			if (!camel_folder_summary_check_uid (s, cns->priv->uid)) {
				if (camel_mime_parser_init_with_stream (mp, CAMEL_STREAM (nntp_stream), error) == -1)
					goto error;
				mi = camel_folder_summary_info_new_from_parser (s, mp);
				camel_folder_summary_add (s, mi, FALSE);
				while (camel_mime_parser_step (mp, NULL, NULL) != CAMEL_MIME_PARSER_STATE_EOF)
					;
				if (mi == NULL) {
					goto error;
				}
				cns->high = i;
				camel_folder_change_info_add_uid (changes, camel_message_info_get_uid (mi));
				if (folder_filter_recent)
					camel_folder_change_info_recent_uid (changes, camel_message_info_get_uid (mi));
				g_clear_object (&mi);
			}
			if (cns->priv->uid) {
				g_free (cns->priv->uid);
				cns->priv->uid = NULL;
			}
		}
	}

	ret = 0;

error:
	if (ret == -1) {
		if (errno == EINTR)
			g_set_error (
				error, G_IO_ERROR,
				G_IO_ERROR_CANCELLED,
				_("Cancelled"));
		else
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Operation failed: %s"),
				g_strerror (errno));
	}

ioerror:
	if (cns->priv->uid) {
		g_free (cns->priv->uid);
		cns->priv->uid = NULL;
	}
	g_object_unref (mp);

	g_clear_object (&nntp_stream);

	camel_operation_pop_message (cancellable);

	return ret;
}

/* Note: This will be called from camel_nntp_command, so only use camel_nntp_raw_command */
static GHashTable *
nntp_get_existing_article_numbers (CamelNNTPSummary *cns,
				   CamelNNTPStore *nntp_store,
				   const gchar *full_name,
				   guint limit_from,
				   guint total,
				   GCancellable *cancellable,
				   GError **error)
{
	CamelNNTPStream *nntp_stream;
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	CamelService *service;
	GHashTable *existing_articles = NULL;
	gint ret = -1;
	gchar *line = NULL;
	gchar *host;
	guint len, count;

	service = CAMEL_SERVICE (nntp_store);

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);

	g_object_unref (settings);

	camel_operation_push_message (cancellable, _("%s: Scanning existing messages"), host);

	g_free (host);

	nntp_stream = camel_nntp_store_ref_stream (nntp_store);

	if (limit_from)
		ret = camel_nntp_raw_command_auth (nntp_store, cancellable, error, &line, "listgroup %s %u-", full_name, limit_from);
	else
		ret = camel_nntp_raw_command_auth (nntp_store, cancellable, error, &line, "listgroup %s", full_name);
	if (ret != 211) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Unexpected server response from listgroup: %s"),
			line);
		goto ioerror;
	}

	count = 0;

	while ((ret = camel_nntp_stream_line (nntp_stream, (guchar **) &line, &len, cancellable, error)) > 0) {
		guint nn;

		if (len == 1 && g_ascii_strncasecmp (line, ".", len) == 0)
			break;

		if (total > 0)
			camel_operation_progress (cancellable, (count * 100) / total);
		count++;

		nn = strtoul (line, NULL, 10);
		if (nn) {
			if (!existing_articles)
				existing_articles = g_hash_table_new (g_direct_hash, g_direct_equal);

			g_hash_table_insert (existing_articles, GUINT_TO_POINTER (nn), NULL);
		}
	}

	ret = 0;

 ioerror:

	g_clear_object (&nntp_stream);

	camel_operation_pop_message (cancellable);

	return existing_articles;
}

static guint
nntp_summary_get_current_date_mark (void)
{
	GDate date;

	g_date_clear (&date, 1);
	g_date_set_time_t (&date, time (NULL));

	return g_date_get_year (&date) * 10000 + g_date_get_month (&date) * 100 + g_date_get_day (&date);
}

/* Assumes we have the stream */
/* Note: This will be called from camel_nntp_command, so only use camel_nntp_raw_command */
gint
camel_nntp_summary_check (CamelNNTPSummary *cns,
                          CamelNNTPStore *store,
                          gchar *line,
                          CamelFolderChangeInfo *changes,
                          GCancellable *cancellable,
                          GError **error)
{
	CamelNNTPStoreSummary *nntp_store_summary;
	CamelStoreSummary *store_summary;
	CamelFolderSummary *s;
	gint ret = 0, i;
	guint n, f, l, limit_latest = 0;
	gint count;
	gchar *folder = NULL;
	CamelNNTPStoreInfo *si = NULL;
	CamelStore *parent_store;
	CamelSettings *settings;
	GPtrArray *known_uids;
	const gchar *full_name;

	s = (CamelFolderSummary *) cns;

	full_name = camel_folder_get_full_name (camel_folder_summary_get_folder (s));
	parent_store = camel_folder_get_parent_store (camel_folder_summary_get_folder (s));

	settings = camel_service_ref_settings (CAMEL_SERVICE (store));
	if (settings) {
		if (camel_nntp_settings_get_use_limit_latest (CAMEL_NNTP_SETTINGS (settings)))
			limit_latest = camel_nntp_settings_get_limit_latest (CAMEL_NNTP_SETTINGS (settings));

		g_object_unref (settings);
	}

	line +=3;
	n = strtoul (line, &line, 10);
	f = strtoul (line, &line, 10);
	l = strtoul (line, &line, 10);
	if (line[0] == ' ') {
		gchar *tmp;
		gsize tmp_len;

		folder = line + 1;
		tmp = strchr (folder, ' ');
		if (tmp)
			*tmp = 0;

		tmp_len = strlen (folder) + 1;
		tmp = g_alloca (tmp_len);
		g_strlcpy (tmp, folder, tmp_len);
		folder = tmp;
	}

	if (cns->low == f && cns->high == l && cns->priv->last_limit_latest >= limit_latest) {
		if (cns->priv->last_limit_latest != limit_latest) {
			cns->priv->last_limit_latest = limit_latest;

			camel_folder_summary_touch (s);
			camel_folder_summary_save (s, NULL);
		}

		dd (printf ("nntp_summary: no work to do!\n"));
		goto update;
	}

	/* Need to work out what to do with our messages */

	/* Check for messages no longer on the server */
	known_uids = camel_folder_summary_get_array (s);
	if (known_uids) {
		GList *removed = NULL;

		n = nntp_summary_get_current_date_mark ();

		if (n != cns->priv->last_full_resync) {
			GHashTable *existing_articles;
			guint first = f;

			/* Do full resync only once per day, not on every folder change */
			cns->priv->last_full_resync = n;

			if (limit_latest > 0 && l - first > limit_latest)
				first = l - limit_latest;

			/* Ignore errors, the worse is that some already deleted aricles will be still
			   in the local summary, which is not a big deal as no articles shown at all. */
			existing_articles = nntp_get_existing_article_numbers (cns, store, full_name, first == f ? 0 : first, l - first + 1, cancellable, NULL);
			if (existing_articles) {
				for (i = 0; i < known_uids->len; i++) {
					const gchar *uid;

					uid = g_ptr_array_index (known_uids, i);
					n = strtoul (uid, NULL, 10);

					if (!g_hash_table_contains (existing_articles, GUINT_TO_POINTER (n))) {
						camel_folder_change_info_remove_uid (changes, uid);
						removed = g_list_prepend (removed, (gpointer) camel_pstring_strdup (uid));
					}
				}

				g_hash_table_destroy (existing_articles);
			}
		} else if (cns->low != f) {
			for (i = 0; i < known_uids->len; i++) {
				const gchar *uid;

				uid = g_ptr_array_index (known_uids, i);
				n = strtoul (uid, NULL, 10);

				if (n < f || n > l)
					removed = g_list_prepend (removed, (gpointer) camel_pstring_strdup (uid));
			}
		}

		if (removed)
			camel_folder_summary_remove_uids (s, removed);

		g_list_free_full (removed, (GDestroyNotify) camel_pstring_free);

		camel_folder_summary_free_array (known_uids);
	}

	cns->low = f;

	if (cns->high < l || limit_latest != cns->priv->last_limit_latest) {
		if (limit_latest > 0 && l - f > limit_latest)
			f = l - limit_latest + 1;

		if (cns->high < f || limit_latest != cns->priv->last_limit_latest)
			cns->high = f - 1;

		if (store->xover)
			ret = add_range_xover (
				cns, store, l, cns->high + 1,
				changes, cancellable, error);
		else
			ret = add_range_head (
				cns, store, l, cns->high + 1,
				changes, cancellable, error);
	}

	cns->priv->last_limit_latest = limit_latest;

	/* TODO: not from here */
	camel_folder_summary_touch (s);
	camel_folder_summary_save (s, NULL);

update:
	/* update store summary if we have it */

	nntp_store_summary = camel_nntp_store_ref_summary (store);

	store_summary = CAMEL_STORE_SUMMARY (nntp_store_summary);

	if (folder != NULL)
		si = (CamelNNTPStoreInfo *)
			camel_store_summary_path (store_summary, folder);

	if (si != NULL) {
		guint32 unread = 0;

		count = camel_folder_summary_count (s);
		camel_db_count_unread_message_info (camel_store_get_db (parent_store), full_name, &unread, NULL);

		if (si->info.unread != unread
		    || si->info.total != count
		    || si->first != f
		    || si->last != l) {
			si->info.unread = unread;
			si->info.total = count;
			si->first = f;
			si->last = l;
			camel_store_summary_touch (store_summary);
			camel_store_summary_save (store_summary);
		}
		camel_store_summary_info_unref (
			store_summary, (CamelStoreInfo *) si);

	} else if (folder != NULL) {
		g_warning ("Group '%s' not present in summary", folder);

	} else {
		g_warning ("Missing group from group response");
	}

	g_clear_object (&nntp_store_summary);

	return ret;
}
