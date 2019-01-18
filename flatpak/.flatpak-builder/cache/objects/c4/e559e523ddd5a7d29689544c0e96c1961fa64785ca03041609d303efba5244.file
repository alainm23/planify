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
 * Authors: Michael Zucchi <notzed@ximian.com>
 *          Dan Winship <danw@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#include <camel/camel.h>

#include "camel-imapx-message-info.h"
#include "camel-imapx-summary.h"

/* Don't do DB sort. Its pretty slow to load */
/* #define SORT_DB 1 */

#define CAMEL_IMAPX_SUMMARY_VERSION (4)

G_DEFINE_TYPE (
	CamelIMAPXSummary,
	camel_imapx_summary,
	CAMEL_TYPE_FOLDER_SUMMARY)

static gboolean
imapx_summary_summary_header_load (CamelFolderSummary *s,
				   CamelFIRecord *mir)
{
	gboolean success;

	/* Chain up to parent's summary_header_load() method. */
	success = CAMEL_FOLDER_SUMMARY_CLASS (camel_imapx_summary_parent_class)->summary_header_load (s, mir);

	if (success) {
		CamelIMAPXSummary *ims;
		gchar *part = mir->bdata;

		ims = CAMEL_IMAPX_SUMMARY (s);

		ims->version = camel_util_bdata_get_number (&part, 0);
		ims->validity = camel_util_bdata_get_number (&part, 0);

		if (ims->version >= 4) {
			ims->uidnext = camel_util_bdata_get_number (&part, 0);
			ims->modseq = camel_util_bdata_get_number (&part, 0);
		}

		if (ims->version > CAMEL_IMAPX_SUMMARY_VERSION) {
			g_warning ("Unknown summary version\n");
			errno = EINVAL;
			success = FALSE;
		}
	}

	return success;
}

static CamelFIRecord *
imapx_summary_summary_header_save (CamelFolderSummary *s,
				   GError **error)
{
	struct _CamelFIRecord *fir;

	/* Chain up to parent's summary_header_save() method. */
	fir = CAMEL_FOLDER_SUMMARY_CLASS (camel_imapx_summary_parent_class)->summary_header_save (s, error);

	if (fir != NULL) {
		CamelIMAPXSummary *ims;

		ims = CAMEL_IMAPX_SUMMARY (s);

		fir->bdata = g_strdup_printf (
			"%d"
			" %" G_GUINT64_FORMAT
			" %" G_GUINT32_FORMAT
			" %" G_GUINT64_FORMAT,
			CAMEL_IMAPX_SUMMARY_VERSION,
			ims->validity,
			ims->uidnext,
			ims->modseq);
	}

	return fir;
}

static void
camel_imapx_summary_class_init (CamelIMAPXSummaryClass *class)
{
	CamelFolderSummaryClass *folder_summary_class;

	folder_summary_class = CAMEL_FOLDER_SUMMARY_CLASS (class);
	folder_summary_class->message_info_type = CAMEL_TYPE_IMAPX_MESSAGE_INFO;
#ifdef SORT_DB
	folder_summary_class->sort_by = "uid";
	folder_summary_class->collate = "imapx_uid_sort";
#endif
	folder_summary_class->summary_header_load = imapx_summary_summary_header_load;
	folder_summary_class->summary_header_save = imapx_summary_summary_header_save;
}

static void
camel_imapx_summary_init (CamelIMAPXSummary *obj)
{
}

#ifdef SORT_DB
static gint
sort_uid_cmp (gpointer enc,
              gint len1,
              gpointer data1,
              gint len2,
              gpointer data2)
{
	static gchar *sa1 = NULL, *sa2 = NULL;
	static gint l1 = 0, l2 = 0;
	guint64 a1, a2;

	if (l1 < len1 + 1) {
		sa1 = g_realloc (sa1, len1 + 1);
		l1 = len1 + 1;
	}
	if (l2 < len2 + 1) {
		sa2 = g_realloc (sa2, len2 + 1);
		l2 = len2 + 1;
	}
	strncpy (sa1, data1, len1); sa1[len1] = 0;
	strncpy (sa2, data2, len2); sa2[len2] = 0;

	a1 = g_ascii_strtoull (sa1, NULL, 10);
	a2 = g_ascii_strtoull (sa2, NULL, 10);

	return (a1 < a2) ? -1 : (a1 > a2) ? 1 : 0;
}
#endif

/**
 * camel_imapx_summary_new:
 * @folder: Parent folder.
 *
 * This will create a new CamelIMAPXSummary object and read in the
 * summary data from disk, if it exists.
 *
 * Returns: A new CamelIMAPXSummary object.
 **/
CamelFolderSummary *
camel_imapx_summary_new (CamelFolder *folder)
{
#ifdef SORT_DB
	CamelStore *parent_store;
#endif
	CamelFolderSummary *summary;
	GError *local_error = NULL;

	summary = g_object_new (CAMEL_TYPE_IMAPX_SUMMARY, "folder", folder, NULL);

#ifdef SORT_DB
	parent_store = camel_folder_get_parent_store (folder);
	camel_db_set_collate (camel_store_get_db (parent_store), "uid", "imapx_uid_sort", (CamelDBCollate) sort_uid_cmp);
#endif

	if (!camel_folder_summary_load (summary, &local_error)) {
		/* FIXME: Isn't this dangerous ? We clear the summary
		if it cannot be loaded, for some random reason.
		We need to pass the error and find out why it is not loaded etc. ? */
		camel_folder_summary_clear (summary, NULL);
		g_message ("Unable to load summary: %s\n", local_error->message);
		g_clear_error (&local_error);
	}

	return summary;
}
