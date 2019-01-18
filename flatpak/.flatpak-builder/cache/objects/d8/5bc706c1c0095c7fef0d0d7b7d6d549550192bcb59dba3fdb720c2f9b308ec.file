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
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include "camel-mbox-message-info.h"
#include "camel-mbox-summary.h"
#include "camel-local-private.h"

#define io(x)
#define d(x) /*(printf("%s(%d): ", __FILE__, __LINE__),(x))*/

/* This uses elm/pine style "Status" & "X-Status" headers */

#define CAMEL_MBOX_SUMMARY_VERSION (1)

#define CHECK_CALL(x) G_STMT_START { \
	if ((x) == -1) { \
		g_debug ("%s: Call of '" #x "' failed: %s", G_STRFUNC, g_strerror (errno)); \
	} \
	} G_STMT_END

typedef struct _CamelMboxMessageContentInfo CamelMboxMessageContentInfo;

struct _CamelMboxMessageContentInfo {
	CamelMessageContentInfo info;
};

static CamelFIRecord *
		summary_header_save		(CamelFolderSummary *,
						 GError **error);
static gboolean	summary_header_load		(CamelFolderSummary *,
						 CamelFIRecord *);
static CamelMessageInfo *
		message_info_new_from_headers	(CamelFolderSummary *,
						 const CamelNameValueArray *);
static CamelMessageInfo *
		message_info_new_from_parser	(CamelFolderSummary *,
						 CamelMimeParser *);

static gchar *	mbox_summary_encode_x_evolution	(CamelLocalSummary *cls,
						 const CamelMessageInfo *mi);

static gint	mbox_summary_check		(CamelLocalSummary *cls,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);
static gint	mbox_summary_sync		(CamelLocalSummary *cls,
						 gboolean expunge,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);
static CamelMessageInfo *
		mbox_summary_add		(CamelLocalSummary *cls,
						 CamelMimeMessage *msg,
						 const CamelMessageInfo *info,
						 CamelFolderChangeInfo *ci,
						 GError **error);
static gint	mbox_summary_sync_quick		(CamelMboxSummary *cls,
						 gboolean expunge,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);
static gint	mbox_summary_sync_full		(CamelMboxSummary *cls,
						 gboolean expunge,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);

/* Which status flags are stored in each separate header */
#define STATUS_XSTATUS \
	(CAMEL_MESSAGE_FLAGGED | CAMEL_MESSAGE_ANSWERED | CAMEL_MESSAGE_DELETED)
#define STATUS_STATUS (CAMEL_MESSAGE_SEEN)

static void encode_status (guint32 flags, gchar status[8]);
static guint32 decode_status (const gchar *status);

G_DEFINE_TYPE (
	CamelMboxSummary,
	camel_mbox_summary,
	CAMEL_TYPE_LOCAL_SUMMARY)

static void
camel_mbox_summary_class_init (CamelMboxSummaryClass *class)
{
	CamelFolderSummaryClass *folder_summary_class;
	CamelLocalSummaryClass *local_summary_class;

	folder_summary_class = CAMEL_FOLDER_SUMMARY_CLASS (class);
	folder_summary_class->message_info_type = CAMEL_TYPE_MBOX_MESSAGE_INFO;
	folder_summary_class->sort_by = "bdata";
	folder_summary_class->collate = "mbox_frompos_sort";
	folder_summary_class->summary_header_load = summary_header_load;
	folder_summary_class->summary_header_save = summary_header_save;
	folder_summary_class->message_info_new_from_headers = message_info_new_from_headers;
	folder_summary_class->message_info_new_from_parser = message_info_new_from_parser;

	local_summary_class = CAMEL_LOCAL_SUMMARY_CLASS (class);
	local_summary_class->encode_x_evolution = mbox_summary_encode_x_evolution;
	local_summary_class->check = mbox_summary_check;
	local_summary_class->sync = mbox_summary_sync;
	local_summary_class->add = mbox_summary_add;

	class->sync_quick = mbox_summary_sync_quick;
	class->sync_full = mbox_summary_sync_full;
}

static void
camel_mbox_summary_init (CamelMboxSummary *mbox_summary)
{
	CamelFolderSummary *folder_summary;

	folder_summary = CAMEL_FOLDER_SUMMARY (mbox_summary);

	/* and a unique file version */
	camel_folder_summary_set_version (folder_summary, camel_folder_summary_get_version (folder_summary) + CAMEL_MBOX_SUMMARY_VERSION);
}

/**
 * camel_mbox_summary_new:
 * @folder: a parent #CamelFolder
 * @mbox_name: filename of the mbox
 * @index: (nullable): an optional #CamelIndex to use, or %NULL
 *
 * Create a new #CamelMboxSummary object.
 *
 * Returns: (transfer full): A new #CamelMboxSummary object
 **/
CamelMboxSummary *
camel_mbox_summary_new (CamelFolder *folder,
                        const gchar *mbox_name,
                        CamelIndex *index)
{
	CamelMboxSummary *new;

	new = g_object_new (CAMEL_TYPE_MBOX_SUMMARY, "folder", folder, NULL);
	if (folder) {
		CamelStore *parent_store;

		parent_store = camel_folder_get_parent_store (folder);

		/* Set the functions for db sorting */
		camel_db_set_collate (camel_store_get_db (parent_store), "bdata", "mbox_frompos_sort", (CamelDBCollate) camel_local_frompos_sort);
	}
	camel_local_summary_construct ((CamelLocalSummary *) new, mbox_name, index);
	return new;
}

void camel_mbox_summary_xstatus (CamelMboxSummary *mbs, gint state)
{
	mbs->xstatus = state;
}

static gchar *
mbox_summary_encode_x_evolution (CamelLocalSummary *cls,
                                 const CamelMessageInfo *mi)
{
	const gchar *p, *uidstr;
	guint32 uid, flags;

	/* This is busted, it is supposed to encode ALL DATA */
	p = uidstr = camel_message_info_get_uid (mi);
	while (*p && isdigit (*p))
		p++;

	flags = camel_message_info_get_flags (mi);

	if (*p == 0 && sscanf (uidstr, "%u", &uid) == 1) {
		return g_strdup_printf ("%08x-%04x", uid, flags & 0xffff);
	} else {
		return g_strdup_printf ("%s-%04x", uidstr, flags & 0xffff);
	}
}

static gboolean
summary_header_load (CamelFolderSummary *s,
		     struct _CamelFIRecord *fir)
{
	CamelMboxSummary *mbs = CAMEL_MBOX_SUMMARY (s);
	gchar *part;

	if (!CAMEL_FOLDER_SUMMARY_CLASS (camel_mbox_summary_parent_class)->summary_header_load (s, fir))
		return FALSE;

	part = fir->bdata;
	if (part) {
		mbs->version = camel_util_bdata_get_number (&part, 0);
		mbs->folder_size = camel_util_bdata_get_number (&part, 0);
	}

	return TRUE;
}

static CamelFIRecord *
summary_header_save (CamelFolderSummary *s,
		     GError **error)
{
	CamelFolderSummaryClass *folder_summary_class;
	CamelMboxSummary *mbs = CAMEL_MBOX_SUMMARY (s);
	struct _CamelFIRecord *fir;
	gchar *tmp;

	/* Chain up to parent's summary_header_save() method. */
	folder_summary_class = CAMEL_FOLDER_SUMMARY_CLASS (camel_mbox_summary_parent_class);
	fir = folder_summary_class->summary_header_save (s, error);
	if (fir) {
		tmp = fir->bdata;
		fir->bdata = g_strdup_printf ("%s %d %d", tmp ? tmp : "", CAMEL_MBOX_SUMMARY_VERSION, (gint) mbs->folder_size);
		g_free (tmp);
	}

	return fir;
}

static CamelMessageInfo *
message_info_new_from_headers (CamelFolderSummary *summary,
			       const CamelNameValueArray *headers)
{
	CamelMessageInfo *mi;
	CamelMboxSummary *mbs = (CamelMboxSummary *) summary;

	mi = CAMEL_FOLDER_SUMMARY_CLASS (camel_mbox_summary_parent_class)->message_info_new_from_headers (summary, headers);
	if (mi) {
		const gchar *xev, *uid;
		CamelMessageInfo *info = NULL;
		gint add = 0;	/* bitmask of things to add, 1 assign uid, 2, just add as new, 4 = recent */
		const gchar *status = NULL, *xstatus = NULL;
		guint32 flags = 0;

		if (mbs->xstatus) {
			/* check for existance of status & x-status headers */
			status = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Status");
			if (status)
				flags = decode_status (status);
			xstatus = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "X-Status");
			if (xstatus)
				flags |= decode_status (xstatus);
		}

		/* if we have an xev header, use it, else assign a new one */
		xev = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "X-Evolution");
		if (xev != NULL
		    && camel_local_summary_decode_x_evolution ((CamelLocalSummary *) summary, xev, mi) == 0) {
			uid = camel_message_info_get_uid (mi);
			d (printf ("found valid x-evolution: %s\n", uid));
			/* If one is there, it should be there already */
			info = camel_folder_summary_peek_loaded (summary, uid);
			if (info) {
				if ((camel_message_info_get_flags (info) & CAMEL_MESSAGE_FOLDER_NOTSEEN)) {
					camel_message_info_set_flags (info, CAMEL_MESSAGE_FOLDER_NOTSEEN, 0);
					g_clear_object (&mi);
					mi = info;
				} else {
					add = 7;
					d (printf ("seen '%s' before, adding anew\n", uid));
					g_clear_object (&info);
				}
			} else {
				add = 2;
				d (printf ("but isn't present in summary\n"));
			}
		} else {
			d (printf ("didn't find x-evolution\n"));
			add = 7;
		}

		if ((add & 1) != 0) {
			gchar *new_uid = camel_folder_summary_next_uid_string (summary);

			camel_message_info_set_flags (mi, CAMEL_MESSAGE_FOLDER_FLAGGED | CAMEL_MESSAGE_FOLDER_NOXEV, CAMEL_MESSAGE_FOLDER_FLAGGED | CAMEL_MESSAGE_FOLDER_NOXEV);
			camel_message_info_set_uid (mi, new_uid);

			g_free (new_uid);
		} else {
			camel_folder_summary_set_next_uid (summary, strtoul (camel_message_info_get_uid (mi), NULL, 10));
		}

		if (mbs->xstatus && (add & 2) != 0) {
			/* use the status as the flags when we read it the first time */
			if (status)
				camel_message_info_set_flags (mi, STATUS_STATUS, flags);
			if (xstatus)
				camel_message_info_set_flags (mi, STATUS_XSTATUS, flags);
		}

		if (mbs->changes) {
			if (add&2)
				camel_folder_change_info_add_uid (mbs->changes, camel_message_info_get_uid (mi));
			if ((add&4) && status == NULL)
				camel_folder_change_info_recent_uid (mbs->changes, camel_message_info_get_uid (mi));
		}

		camel_mbox_message_info_set_offset (CAMEL_MBOX_MESSAGE_INFO (mi), -1);
	}

	return (CamelMessageInfo *) mi;
}

static CamelMessageInfo *
message_info_new_from_parser (CamelFolderSummary *s,
                              CamelMimeParser *mp)
{
	CamelMessageInfo *mi;

	mi = CAMEL_FOLDER_SUMMARY_CLASS (camel_mbox_summary_parent_class)->message_info_new_from_parser (s, mp);
	if (mi) {
		camel_mbox_message_info_set_offset (CAMEL_MBOX_MESSAGE_INFO (mi), camel_mime_parser_tell_start_from (mp));
	}

	return mi;
}

/* like summary_rebuild, but also do changeinfo stuff (if supplied) */
static gint
summary_update (CamelLocalSummary *cls,
                goffset offset,
                CamelFolderChangeInfo *changeinfo,
                GCancellable *cancellable,
                GError **error)
{
	gint i;
	CamelFolderSummary *s = (CamelFolderSummary *) cls;
	CamelMboxSummary *mbs = (CamelMboxSummary *) cls;
	CamelMimeParser *mp;
	CamelMessageInfo *mi;
	CamelStore *parent_store;
	const gchar *full_name;
	gint fd;
	gint ok = 0;
	struct stat st;
	goffset size = 0;
	GList *del = NULL;
	GPtrArray *known_uids;

	d (printf ("Calling summary update, from pos %d\n", (gint) offset));

	cls->index_force = FALSE;

	camel_operation_push_message (cancellable, _("Storing folder"));

	camel_folder_summary_lock (s);
	fd = g_open (cls->folder_path, O_LARGEFILE | O_RDONLY | O_BINARY, 0);
	if (fd == -1) {
		d (printf ("%s failed to open: %s\n", cls->folder_path, g_strerror (errno)));
		camel_folder_summary_unlock (s);
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not open folder: %s: %s"),
			cls->folder_path, g_strerror (errno));
		camel_operation_pop_message (cancellable);
		return -1;
	}

	if (fstat (fd, &st) == 0)
		size = st.st_size;

	mp = camel_mime_parser_new ();
	camel_mime_parser_init_with_fd (mp, fd);
	camel_mime_parser_scan_from (mp, TRUE);
	camel_mime_parser_seek (mp, offset, SEEK_SET);

	if (offset > 0) {
		if (camel_mime_parser_step (mp, NULL, NULL) == CAMEL_MIME_PARSER_STATE_FROM
		    && camel_mime_parser_tell_start_from (mp) == offset) {
			camel_mime_parser_unstep (mp);
		} else {
			g_warning ("The next message didn't start where I expected, building summary from start");
			camel_mime_parser_drop_step (mp);
			offset = 0;
			camel_mime_parser_seek (mp, offset, SEEK_SET);
		}
	}

	/* we mark messages as to whether we've seen them or not.
	 * If we're not starting from the start, we must be starting
	 * from the old end, so everything must be treated as new */
	camel_folder_summary_prepare_fetch_all (s, NULL);
	known_uids = camel_folder_summary_get_array (s);
	for (i = 0; known_uids && i < known_uids->len; i++) {
		mi = camel_folder_summary_get (s, g_ptr_array_index (known_uids, i));
		camel_message_info_set_flags (mi, CAMEL_MESSAGE_FOLDER_NOTSEEN, offset == 0 ? CAMEL_MESSAGE_FOLDER_NOTSEEN : 0);
		g_clear_object (&mi);
	}
	camel_folder_summary_free_array (known_uids);
	mbs->changes = changeinfo;

	while (camel_mime_parser_step (mp, NULL, NULL) == CAMEL_MIME_PARSER_STATE_FROM) {
		CamelMessageInfo *info;
		goffset pc = camel_mime_parser_tell_start_from (mp) + 1;
		gint progress;

		/* To avoid a division by zero if the fstat()
		 * call above failed. */
		size = MAX (size, pc);
		progress = (size > 0) ? (gint) (((gfloat) pc / size) * 100) : 0;

		camel_operation_progress (cancellable, progress);

		info = camel_folder_summary_info_new_from_parser (s, mp);
		camel_folder_summary_add (s, info, FALSE);
		g_clear_object (&info);

		g_warn_if_fail (camel_mime_parser_step (mp, NULL, NULL) == CAMEL_MIME_PARSER_STATE_FROM_END);
	}

	g_object_unref (mp);

	known_uids = camel_folder_summary_get_array (s);
	for (i = 0; known_uids && i < known_uids->len; i++) {
		const gchar *uid;

		uid = g_ptr_array_index (known_uids, i);
		if (!uid)
			continue;

		mi = camel_folder_summary_get (s, uid);
		/* must've dissapeared from the file? */
		if (!mi || (camel_message_info_get_flags (mi) & CAMEL_MESSAGE_FOLDER_NOTSEEN) != 0) {
			d (printf ("uid '%s' vanished, removing", uid));
			if (changeinfo)
				camel_folder_change_info_remove_uid (changeinfo, uid);
			del = g_list_prepend (del, (gpointer) camel_pstring_strdup (uid));
			if (mi)
				camel_folder_summary_remove (s, mi);
		}

		g_clear_object (&mi);
	}

	if (known_uids)
		camel_folder_summary_free_array (known_uids);

	/* Delete all in one transaction */
	full_name = camel_folder_get_full_name (camel_folder_summary_get_folder (s));
	parent_store = camel_folder_get_parent_store (camel_folder_summary_get_folder (s));
	camel_db_delete_uids (camel_store_get_db (parent_store), full_name, del, NULL);
	g_list_foreach (del, (GFunc) camel_pstring_free, NULL);
	g_list_free (del);

	mbs->changes = NULL;

	/* update the file size/mtime in the summary */
	if (ok != -1) {
		if (g_stat (cls->folder_path, &st) == 0) {
			camel_folder_summary_touch (s);
			mbs->folder_size = st.st_size;
			camel_folder_summary_set_timestamp (s, st.st_mtime);
		}
	}

	camel_operation_pop_message (cancellable);
	camel_folder_summary_unlock (s);

	return ok;
}

static gint
mbox_summary_check (CamelLocalSummary *cls,
                    CamelFolderChangeInfo *changes,
                    GCancellable *cancellable,
                    GError **error)
{
	CamelMboxSummary *mbs = (CamelMboxSummary *) cls;
	CamelFolderSummary *s = (CamelFolderSummary *) cls;
	struct stat st;
	gint ret = 0;
	gint i;

	d (printf ("Checking summary\n"));

	camel_folder_summary_lock (s);

	/* check if the summary is up-to-date */
	if (g_stat (cls->folder_path, &st) == -1) {
		camel_folder_summary_clear (s, NULL);
		camel_folder_summary_unlock (s);
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Cannot check folder: %s: %s"),
			cls->folder_path, g_strerror (errno));
		return -1;
	}

	if (cls->check_force)
		mbs->folder_size = 0;
	cls->check_force = 0;

	if (st.st_size == 0) {
		GPtrArray *known_uids;

		/* empty?  No need to scan at all */
		d (printf ("Empty mbox, clearing summary\n"));
		camel_folder_summary_prepare_fetch_all (s, NULL);
		known_uids = camel_folder_summary_get_array (s);
		for (i = 0; known_uids && i < known_uids->len; i++) {
			CamelMessageInfo *info = camel_folder_summary_get (s, g_ptr_array_index (known_uids, i));

			if (info) {
				camel_folder_change_info_remove_uid (changes, camel_message_info_get_uid (info));
				g_clear_object (&info);
			}
		}
		camel_folder_summary_free_array (known_uids);
		camel_folder_summary_clear (s, NULL);
		ret = 0;
	} else {
		/* is the summary uptodate? */
		if (st.st_size != mbs->folder_size || st.st_mtime != camel_folder_summary_get_timestamp (s)) {
			if (mbs->folder_size < st.st_size) {
				/* this will automatically rescan from 0 if there is a problem */
				d (printf ("folder grew, attempting to rebuild from %d\n", mbs->folder_size));
				ret = summary_update (cls, mbs->folder_size, changes, cancellable, error);
			} else {
				d (printf ("folder shrank!  rebuilding from start\n"));
				 ret = summary_update (cls, 0, changes, cancellable, error);
			}
		} else {
			d (printf ("Folder unchanged, do nothing\n"));
		}
	}

	/* FIXME: move upstream? */

	if (ret != -1) {
		if (mbs->folder_size != st.st_size || camel_folder_summary_get_timestamp (s) != st.st_mtime) {
			mbs->folder_size = st.st_size;
			camel_folder_summary_set_timestamp (s, st.st_mtime);
			camel_folder_summary_touch (s);
		}
	}

	camel_folder_summary_unlock (s);

	return ret;
}

/* perform a full sync */
static gint
mbox_summary_sync_full (CamelMboxSummary *mbs,
                        gboolean expunge,
                        CamelFolderChangeInfo *changeinfo,
                        GCancellable *cancellable,
                        GError **error)
{
	CamelLocalSummary *cls = (CamelLocalSummary *) mbs;
	CamelFolderSummary *s = CAMEL_FOLDER_SUMMARY (mbs);
	gint fd = -1, fdout = -1;
	gchar *tmpname = NULL;
	gsize tmpname_len = 0;
	guint32 flags = (expunge ? 1 : 0), filemode = 0600;
	struct stat st;

	d (printf ("performing full summary/sync\n"));

	camel_operation_push_message (cancellable, _("Storing folder"));
	camel_folder_summary_lock (s);

	fd = g_open (cls->folder_path, O_LARGEFILE | O_RDONLY | O_BINARY, 0);
	if (fd == -1) {
		camel_folder_summary_unlock (s);
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not open file: %s: %s"),
			cls->folder_path, g_strerror (errno));
		camel_operation_pop_message (cancellable);
		return -1;
	}

	/* preserve attributes as set on the file previously */
	if (fstat (fd, &st) == 0)
		filemode = 07777 & st.st_mode;

	tmpname_len = strlen (cls->folder_path) + 5;
	tmpname = g_alloca (tmpname_len);
	g_snprintf (tmpname, tmpname_len, "%s.tmp", cls->folder_path);
	d (printf ("Writing temporary file to %s\n", tmpname));
	fdout = g_open (tmpname, O_LARGEFILE | O_WRONLY | O_CREAT | O_TRUNC | O_BINARY, filemode);
	if (fdout == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Cannot open temporary mailbox: %s"),
			g_strerror (errno));
		goto error;
	}

	if (camel_mbox_summary_sync_mbox (
		(CamelMboxSummary *) cls, flags, changeinfo,
		fd, fdout, cancellable, error) == -1)
		goto error;

	d (printf ("Closing folders\n"));

	if (close (fd) == -1) {
		g_warning ("Cannot close source folder: %s", g_strerror (errno));
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not close source folder %s: %s"),
			cls->folder_path, g_strerror (errno));
		fd = -1;
		goto error;
	}

	fd = -1;

	if (close (fdout) == -1) {
		g_warning ("Cannot close temporary folder: %s", g_strerror (errno));
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not close temporary folder: %s"),
			g_strerror (errno));
		fdout = -1;
		goto error;
	}

	fdout = -1;

	/* this should probably either use unlink/link/unlink, or recopy over
	 * the original mailbox, for various locking reasons/etc */
#ifdef G_OS_WIN32
	if (g_file_test (cls->folder_path,G_FILE_TEST_IS_REGULAR) && g_remove (cls->folder_path) == -1)
		g_warning ("Cannot remove %s: %s", cls->folder_path, g_strerror (errno));
#endif
	if (g_rename (tmpname, cls->folder_path) == -1) {
		g_warning ("Cannot rename folder: %s", g_strerror (errno));
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not rename folder: %s"),
			g_strerror (errno));
		goto error;
	}

	camel_operation_pop_message (cancellable);
	camel_folder_summary_unlock (s);

	return 0;
 error:
	if (fd != -1)
		close (fd);

	if (fdout != -1)
		close (fdout);

	g_unlink (tmpname);

	camel_operation_pop_message (cancellable);
	camel_folder_summary_unlock (s);

	return -1;
}

static gint
cms_sort_frompos (gconstpointer a,
                  gconstpointer b,
                  gpointer data)
{
	CamelFolderSummary *summary = (CamelFolderSummary *) data;
	CamelMboxMessageInfo *info1, *info2;
	goffset afrompos, bfrompos;
	gint ret = 0;

	/* Things are in memory already. Sorting speeds up syncing, if things are sorted by from pos. */
	info1 = (CamelMboxMessageInfo *) camel_folder_summary_get (summary, *(gchar **) a);
	info2 = (CamelMboxMessageInfo *) camel_folder_summary_get (summary, *(gchar **) b);

	afrompos = camel_mbox_message_info_get_offset (info1);
	bfrompos = camel_mbox_message_info_get_offset (info2);

	if (afrompos > bfrompos)
		ret = 1;
	else if  (afrompos < bfrompos)
		ret = -1;
	else
		ret = 0;

	g_clear_object (&info1);
	g_clear_object (&info2);

	return ret;

}

/* perform a quick sync - only system flags have changed */
static gint
mbox_summary_sync_quick (CamelMboxSummary *mbs,
                         gboolean expunge,
                         CamelFolderChangeInfo *changeinfo,
                         GCancellable *cancellable,
                         GError **error)
{
	CamelLocalSummary *cls = (CamelLocalSummary *) mbs;
	CamelFolderSummary *s = (CamelFolderSummary *) mbs;
	CamelMimeParser *mp = NULL;
	gint i;
	CamelMessageInfo *info = NULL;
	gint fd = -1, pfd;
	gchar *xevnew, *xevtmp;
	const gchar *xev;
	gint len;
	goffset lastpos;
	GPtrArray *summary = NULL;

	d (printf ("Performing quick summary sync\n"));

	camel_operation_push_message (cancellable, _("Storing folder"));
	camel_folder_summary_lock (s);

	fd = g_open (cls->folder_path, O_LARGEFILE | O_RDWR | O_BINARY, 0);
	if (fd == -1) {
		camel_folder_summary_unlock (s);
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not open file: %s: %s"),
			cls->folder_path, g_strerror (errno));

		camel_operation_pop_message (cancellable);
		return -1;
	}

	/* need to dup since mime parser closes its fd once it is finalized */
	pfd = dup (fd);
	if (pfd == -1) {
		camel_folder_summary_unlock (s);
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not store folder: %s"),
			g_strerror (errno));
		close (fd);
		return -1;
	}

	mp = camel_mime_parser_new ();
	camel_mime_parser_scan_from (mp, TRUE);
	camel_mime_parser_scan_pre_from (mp, TRUE);
	camel_mime_parser_init_with_fd (mp, pfd);

	/* Sync only the changes */
	summary = camel_folder_summary_get_changed ((CamelFolderSummary *) mbs);
	if (summary->len)
		g_ptr_array_sort_with_data (summary, cms_sort_frompos, mbs);

	for (i = 0; i < summary->len; i++) {
		goffset frompos;
		gint xevoffset;
		gint pc = (i + 1) * 100 / summary->len;

		camel_operation_progress (cancellable, pc);

		info = camel_folder_summary_get (s, summary->pdata[i]);

		d (printf ("Checking message %s %08x\n", camel_message_info_get_uid (info), camel_message_info_get_flags (info)));

		if (!camel_message_info_get_folder_flagged (info)) {
			g_clear_object (&info);
			continue;
		}

		frompos = camel_mbox_message_info_get_offset (CAMEL_MBOX_MESSAGE_INFO (info));

		d (printf ("Updating message %s: %d\n", camel_message_info_get_uid (info), (gint) frompos));

		camel_mime_parser_seek (mp, frompos, SEEK_SET);

		if (camel_mime_parser_step (mp, NULL, NULL) != CAMEL_MIME_PARSER_STATE_FROM) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("MBOX file is corrupted, please fix it. (Expected a From line, but didn’t get it.)"));
			goto error;
		}

		if (camel_mime_parser_tell_start_from (mp) != frompos) {
			g_warning (
				"Didn't get the next message where I expected (%d) got %d instead",
				(gint) frompos, (gint) camel_mime_parser_tell_start_from (mp));
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Summary and folder mismatch, even after a sync"));
			goto error;
		}

		if (camel_mime_parser_step (mp, NULL, NULL) == CAMEL_MIME_PARSER_STATE_FROM_END) {
			g_warning ("camel_mime_parser_step failed (2)");
			goto error;
		}

		xev = camel_mime_parser_header (mp, "X-Evolution", &xevoffset);
		if (xev == NULL || camel_local_summary_decode_x_evolution (cls, xev, NULL) == -1) {
			g_warning ("We're supposed to have a valid x-ev header, but we dont");
			goto error;
		}
		xevnew = camel_local_summary_encode_x_evolution (cls, info);
		/* SIGH: encode_param_list is about the only function which folds headers by itself.
		 * This should be fixed somehow differently (either parser doesn't fold headers,
		 * or param_list doesn't, or something */
		xevtmp = camel_header_unfold (xevnew);
		/* the raw header contains a leading ' ', so (dis)count that too */
		if (strlen (xev) - 1 != strlen (xevtmp)) {
			g_free (xevnew);
			g_free (xevtmp);
			g_warning ("Hmm, the xev headers shouldn't have changed size, but they did");
			goto error;
		}
		g_free (xevtmp);

		/* we write out the xevnew string, assuming its been folded identically to the original too! */

		lastpos = lseek (fd, 0, SEEK_CUR);
		CHECK_CALL (lseek (fd, xevoffset + strlen ("X-Evolution: "), SEEK_SET));
		do {
			len = write (fd, xevnew, strlen (xevnew));
		} while (len == -1 && errno == EINTR);

		if (lastpos != -1 && lseek (fd, lastpos, SEEK_SET) == (off_t) -1) {
			g_warning (
				"%s: Failed to rewind file to last position: %s",
				G_STRFUNC, g_strerror (errno));
		}
		g_free (xevnew);

		camel_mime_parser_drop_step (mp);
		camel_mime_parser_drop_step (mp);

		camel_message_info_set_flags (info, 0xffff, camel_message_info_get_flags (info));
		g_clear_object (&info);
	}

	d (printf ("Closing folders\n"));

	if (close (fd) == -1) {
		g_warning ("Cannot close source folder: %s", g_strerror (errno));
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not close source folder %s: %s"),
			cls->folder_path, g_strerror (errno));
		fd = -1;
		goto error;
	}

	g_ptr_array_foreach (summary, (GFunc) camel_pstring_free, NULL);
	g_ptr_array_free (summary, TRUE);
	g_object_unref (mp);

	camel_operation_pop_message (cancellable);
	camel_folder_summary_unlock (s);

	return 0;
 error:
	g_ptr_array_foreach (summary, (GFunc) camel_pstring_free, NULL);
	g_ptr_array_free (summary, TRUE);
	g_object_unref (mp);
	if (fd != -1)
		close (fd);
	if (info)
		g_clear_object (&info);

	camel_operation_pop_message (cancellable);
	camel_folder_summary_unlock (s);

	return -1;
}

static gint
mbox_summary_sync (CamelLocalSummary *cls,
                   gboolean expunge,
                   CamelFolderChangeInfo *changeinfo,
                   GCancellable *cancellable,
                   GError **error)
{
	struct stat st;
	CamelMboxSummary *mbs = (CamelMboxSummary *) cls;
	CamelFolderSummary *s = (CamelFolderSummary *) cls;
	CamelStore *parent_store;
	const gchar *full_name;
	gint i;
	gint quick = TRUE, work = FALSE;
	gint ret;
	GPtrArray *summary = NULL;

	camel_folder_summary_lock (s);

	/* first, sync ourselves up, just to make sure */
	if (camel_local_summary_check (cls, changeinfo, cancellable, error) == -1) {
		camel_folder_summary_unlock (s);
		return -1;
	}

	full_name = camel_folder_get_full_name (camel_folder_summary_get_folder (s));
	parent_store = camel_folder_get_parent_store (camel_folder_summary_get_folder (s));

	/* Sync only the changes */

	summary = camel_folder_summary_get_changed ((CamelFolderSummary *) mbs);
	for (i = 0; i < summary->len; i++) {
		CamelMessageInfo *info = camel_folder_summary_get (s, summary->pdata[i]);

		if ((expunge && (camel_message_info_get_flags (info) & CAMEL_MESSAGE_DELETED) != 0) ||
		    (camel_message_info_get_flags (info) & (CAMEL_MESSAGE_FOLDER_NOXEV | CAMEL_MESSAGE_FOLDER_XEVCHANGE)) != 0)
			quick = FALSE;
		else
			work |= camel_message_info_get_folder_flagged (info);
		g_clear_object (&info);
	}

	g_ptr_array_foreach (summary, (GFunc) camel_pstring_free, NULL);
	g_ptr_array_free (summary, TRUE);

	if (quick && expunge) {
		guint32 dcount =0;

		if (camel_db_count_deleted_message_info (camel_store_get_db (parent_store), full_name, &dcount, error) == -1) {
			camel_folder_summary_unlock (s);
			return -1;
		}
		if (dcount)
			quick = FALSE;
	}

	/* yuck i hate this logic, but its to simplify the 'all ok, update summary' and failover cases */
	ret = -1;
	if (quick) {
		if (work) {
			ret = CAMEL_MBOX_SUMMARY_GET_CLASS (cls)->sync_quick (
				mbs, expunge, changeinfo, cancellable, NULL);
			if (ret == -1)
				g_warning ("failed a quick-sync, trying a full sync");
		} else {
			ret = 0;
		}
	}

	if (ret == -1)
		ret = CAMEL_MBOX_SUMMARY_GET_CLASS (cls)->sync_full (
			mbs, expunge, changeinfo, cancellable, error);
	if (ret == -1) {
		camel_folder_summary_unlock (s);
		return -1;
	}

	if (g_stat (cls->folder_path, &st) == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Unknown error: %s"), g_strerror (errno));
		camel_folder_summary_unlock (s);
		return -1;
	}

	if (mbs->folder_size != st.st_size || camel_folder_summary_get_timestamp (s) != st.st_mtime) {
		camel_folder_summary_set_timestamp (s, st.st_mtime);
		mbs->folder_size = st.st_size;
		camel_folder_summary_touch (s);
	}

	ret = CAMEL_LOCAL_SUMMARY_CLASS (camel_mbox_summary_parent_class)->sync (cls, expunge, changeinfo, cancellable, error);
	camel_folder_summary_unlock (s);

	return ret;
}

gint
camel_mbox_summary_sync_mbox (CamelMboxSummary *cls,
                              guint32 flags,
                              CamelFolderChangeInfo *changeinfo,
                              gint fd,
                              gint fdout,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelMboxSummary *mbs = (CamelMboxSummary *) cls;
	CamelFolderSummary *s = (CamelFolderSummary *) mbs;
	CamelMimeParser *mp = NULL;
	CamelStore *parent_store;
	const gchar *full_name;
	gint i;
	CamelMessageInfo *info = NULL;
	gchar *buffer, *xevnew = NULL;
	gsize len;
	const gchar *fromline;
	gint lastdel = FALSE;
	gboolean touched = FALSE;
	GList *del = NULL;
	GPtrArray *known_uids = NULL;
	gchar statnew[8], xstatnew[8];

	d (printf ("performing full summary/sync\n"));

	camel_folder_summary_lock (s);

	/* need to dup this because the mime-parser owns the fd after we give it to it */
	fd = dup (fd);
	if (fd == -1) {
		camel_folder_summary_unlock (s);
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not store folder: %s"),
			g_strerror (errno));
		return -1;
	}

	mp = camel_mime_parser_new ();
	camel_mime_parser_scan_from (mp, TRUE);
	camel_mime_parser_scan_pre_from (mp, TRUE);
	camel_mime_parser_init_with_fd (mp, fd);

	camel_folder_summary_prepare_fetch_all (s, NULL);
	known_uids = camel_folder_summary_get_array (s);
	/* walk them in the same order as stored in the file */
	if (known_uids && known_uids->len)
		g_ptr_array_sort_with_data (known_uids, cms_sort_frompos, mbs);
	for (i = 0; known_uids && i < known_uids->len; i++) {
		gint pc = (i + 1) * 100 / known_uids->len;
		goffset frompos;

		camel_operation_progress (cancellable, pc);

		info = camel_folder_summary_get (s, g_ptr_array_index (known_uids, i));

		if (!info)
			continue;

		d (printf (
			"Looking at message %s\n",
			camel_message_info_get_uid (info)));

		frompos = camel_mbox_message_info_get_offset (CAMEL_MBOX_MESSAGE_INFO (info));

		d (printf (
			"seeking (%s) to %d\n",
			camel_message_info_get_uid (info),
			(gint) frompos));

		if (lastdel)
			camel_mime_parser_seek (mp, frompos, SEEK_SET);

		if (camel_mime_parser_step (mp, &buffer, &len) != CAMEL_MIME_PARSER_STATE_FROM) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("MBOX file is corrupted, please fix it. "
				"(Expected a From line, but didn’t get it.)"));
			goto error;
		}

		if (camel_mime_parser_tell_start_from (mp) != frompos) {
			g_warning (
				"Didn't get the next message where I expected (%d) got %d instead",
				(gint) frompos,
				(gint) camel_mime_parser_tell_start_from (mp));
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Summary and folder mismatch, even after a sync"));
			goto error;
		}

		lastdel = FALSE;
		if ((flags & 1) && (camel_message_info_get_flags (info) & CAMEL_MESSAGE_DELETED) != 0) {
			const gchar *uid = camel_message_info_get_uid (info);
			d (printf ("Deleting %s\n", uid));

			if (((CamelLocalSummary *) cls)->index)
				camel_index_delete_name (((CamelLocalSummary *) cls)->index, uid);

			/* remove it from the change list */
			camel_folder_change_info_remove_uid (changeinfo, uid);
			camel_folder_summary_remove (s, (CamelMessageInfo *) info);
			del = g_list_prepend (del, (gpointer) camel_pstring_strdup (uid));
			g_clear_object (&info);
			lastdel = TRUE;
			touched = TRUE;
		} else {
			/* otherwise, the message is staying, copy its From_ line across */
#if 0
			if (i > 0)
				write (fdout, "\n", 1);
#endif
			frompos = lseek (fdout, 0, SEEK_CUR);
			camel_mbox_message_info_set_offset (CAMEL_MBOX_MESSAGE_INFO (info), frompos);
			camel_message_info_set_dirty (info, TRUE);
			fromline = camel_mime_parser_from_line (mp);
			d (printf ("Saving %s:%d\n", camel_message_info_get_uid (info), frompos));
			g_warn_if_fail (write (fdout, fromline, strlen (fromline)) != -1);
		}

		if (info && (camel_message_info_get_flags (info) & (CAMEL_MESSAGE_FOLDER_NOXEV | CAMEL_MESSAGE_FOLDER_FLAGGED)) != 0) {
			CamelNameValueArray *header = NULL;
			d (printf ("Updating header for %s flags = %08x\n", camel_message_info_get_uid (info), camel_message_info_get_flags (info)));

			if (camel_mime_parser_step (mp, &buffer, &len) == CAMEL_MIME_PARSER_STATE_FROM_END) {
				g_warning ("camel_mime_parser_step failed (2)");
				goto error;
			}

			header = camel_mime_parser_dup_headers (mp);
			xevnew = camel_local_summary_encode_x_evolution ((CamelLocalSummary *) cls, info);
			if (mbs->xstatus) {
				guint32 info_flags = camel_message_info_get_flags (info);

				encode_status (info_flags & STATUS_STATUS, statnew);
				encode_status (info_flags & STATUS_XSTATUS, xstatnew);

				len = camel_local_summary_write_headers (fdout, header, xevnew, statnew, xstatnew);
			} else {
				len = camel_local_summary_write_headers (fdout, header, xevnew, NULL, NULL);
			}

			camel_name_value_array_free (header);
			if (len == -1) {
				d (printf ("Error writing to temporary mailbox\n"));
				g_set_error (
					error, G_IO_ERROR,
					g_io_error_from_errno (errno),
					_("Writing to temporary mailbox failed: %s"),
					g_strerror (errno));
				goto error;
			}
			camel_message_info_set_flags (info, 0xffff, camel_message_info_get_flags (info));
			g_free (xevnew);
			xevnew = NULL;
			camel_mime_parser_drop_step (mp);
		}

		camel_mime_parser_drop_step (mp);
		if (info) {
			d (printf ("looking for message content to copy across from %d\n", (gint) camel_mime_parser_tell (mp)));
			while (camel_mime_parser_step (mp, &buffer, &len) == CAMEL_MIME_PARSER_STATE_PRE_FROM) {
				/*d(printf("copying mbox contents to temporary: '%.*s'\n", len, buffer));*/
				if (write (fdout, buffer, len) != len) {
					g_set_error (
						error, G_IO_ERROR,
						g_io_error_from_errno (errno),
						_("Writing to temporary mailbox failed: %s: %s"),
						((CamelLocalSummary *) cls)->folder_path,
						g_strerror (errno));
					goto error;
				}
			}

			if (write (fdout, "\n", 1) != 1) {
				g_set_error (
					error, G_IO_ERROR,
					g_io_error_from_errno (errno),
					_("Writing to temporary mailbox failed: %s"),
					g_strerror (errno));
				goto error;
			}

			d (printf (
				"we are now at %d, from = %d\n",
				(gint) camel_mime_parser_tell (mp),
				(gint) camel_mime_parser_tell_start_from (mp)));
			camel_mime_parser_unstep (mp);
			g_clear_object (&info);
		}
	}

	full_name = camel_folder_get_full_name (camel_folder_summary_get_folder (s));
	parent_store = camel_folder_get_parent_store (camel_folder_summary_get_folder (s));
	camel_db_delete_uids (camel_store_get_db (parent_store), full_name, del, NULL);
	g_list_foreach (del, (GFunc) camel_pstring_free, NULL);
	g_list_free (del);

#if 0
	/* if last was deleted, append the \n we removed */
	if (lastdel && count > 0)
		write (fdout, "\n", 1);
#endif

	g_object_unref (mp);

	/* clear working flags */
	for (i = 0; known_uids && i < known_uids->len; i++) {
		info = camel_folder_summary_get (s, g_ptr_array_index (known_uids, i));
		if (info) {
			camel_message_info_set_flags (info, CAMEL_MESSAGE_FOLDER_NOXEV | CAMEL_MESSAGE_FOLDER_FLAGGED | CAMEL_MESSAGE_FOLDER_XEVCHANGE, 0);
			g_clear_object (&info);
		}
	}

	camel_folder_summary_free_array (known_uids);

	if (touched)
		camel_folder_summary_header_save (s, NULL);

	camel_folder_summary_unlock (s);

	return 0;
 error:
	g_free (xevnew);
	g_object_unref (mp);
	g_clear_object (&info);

	camel_folder_summary_free_array (known_uids);
	camel_folder_summary_unlock (s);

	return -1;
}

static CamelMessageInfo *
mbox_summary_add (CamelLocalSummary *cls,
                  CamelMimeMessage *msg,
                  const CamelMessageInfo *info,
                  CamelFolderChangeInfo *ci,
                  GError **error)
{
	CamelLocalSummaryClass *local_summary_class;
	CamelMessageInfo *mi;

	/* Chain up to parent's add() method. */
	local_summary_class = CAMEL_LOCAL_SUMMARY_CLASS (camel_mbox_summary_parent_class);
	mi = local_summary_class->add (cls, msg, info, ci, error);
	if (mi && ((CamelMboxSummary *) cls)->xstatus) {
		gchar status[8];
		guint32 flags = camel_message_info_get_flags (mi);

		/* we snoop and add status/x-status headers to suit */
		encode_status (flags & STATUS_STATUS, status);
		camel_medium_set_header ((CamelMedium *) msg, "Status", status);
		encode_status (flags & STATUS_XSTATUS, status);
		camel_medium_set_header ((CamelMedium *) msg, "X-Status", status);
	}

	return mi;
}

static struct {
	gchar tag;
	guint32 flag;
} status_flags[] = {
	{ 'F', CAMEL_MESSAGE_FLAGGED },
	{ 'A', CAMEL_MESSAGE_ANSWERED },
	{ 'D', CAMEL_MESSAGE_DELETED },
	{ 'R', CAMEL_MESSAGE_SEEN },
};

static void
encode_status (guint32 flags,
               gchar status[8])
{
	gsize i;
	gchar *p;

	p = status;
	for (i = 0; i < G_N_ELEMENTS (status_flags); i++)
		if (status_flags[i].flag & flags)
			*p++ = status_flags[i].tag;
	*p++ = 'O';
	*p = '\0';
}

static guint32
decode_status (const gchar *status)
{
	const gchar *p;
	guint32 flags = 0;
	gsize i;
	gchar c;

	p = status;
	while ((c = *p++)) {
		for (i = 0; i < G_N_ELEMENTS (status_flags); i++)
			if (status_flags[i].tag == c)
				flags |= status_flags[i].flag;
	}

	return flags;
}
