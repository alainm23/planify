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

#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include "camel-local-private.h"
#include "camel-win32.h"

#include "camel-spool-summary.h"

#define io(x)
#define d(x) /*(printf("%s(%d): ", __FILE__, __LINE__),(x))*/

#define CAMEL_SPOOL_SUMMARY_VERSION (0x400)

static gint	spool_summary_load		(CamelLocalSummary *cls,
						 gint forceindex,
						 GError **error);
static gint	spool_summary_check		(CamelLocalSummary *cls,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);

static gint	spool_summary_sync_full		(CamelMboxSummary *cls,
						 gboolean expunge,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);
static gint	spool_summary_need_index	(void);

G_DEFINE_TYPE (CamelSpoolSummary, camel_spool_summary, CAMEL_TYPE_MBOX_SUMMARY)

static void
camel_spool_summary_class_init (CamelSpoolSummaryClass *class)
{
	CamelFolderSummaryClass *folder_summary_class;
	CamelLocalSummaryClass *local_summary_class;
	CamelMboxSummaryClass *mbox_summary_class;

	folder_summary_class = CAMEL_FOLDER_SUMMARY_CLASS (class);
	folder_summary_class->sort_by = "bdata";
	folder_summary_class->collate = "spool_frompos_sort";

	local_summary_class = CAMEL_LOCAL_SUMMARY_CLASS (class);
	local_summary_class->load = spool_summary_load;
	local_summary_class->check = spool_summary_check;
	local_summary_class->need_index = spool_summary_need_index;

	mbox_summary_class = CAMEL_MBOX_SUMMARY_CLASS (class);
	mbox_summary_class->sync_full = spool_summary_sync_full;
}

static void
camel_spool_summary_init (CamelSpoolSummary *spool_summary)
{
	CamelFolderSummary *folder_summary;

	folder_summary = CAMEL_FOLDER_SUMMARY (spool_summary);

	/* message info size is from mbox parent */

	/* and a unique file version */
	camel_folder_summary_set_version (folder_summary, camel_folder_summary_get_version (folder_summary) + CAMEL_SPOOL_SUMMARY_VERSION);
}

CamelSpoolSummary *
camel_spool_summary_new (CamelFolder *folder,
                         const gchar *mbox_name)
{
	CamelSpoolSummary *new;

	new = g_object_new (CAMEL_TYPE_SPOOL_SUMMARY, "folder", folder, NULL);
	if (folder) {
		CamelStore *parent_store;

		parent_store = camel_folder_get_parent_store (folder);
		camel_db_set_collate (camel_store_get_db (parent_store), "bdata", "spool_frompos_sort", (CamelDBCollate) camel_local_frompos_sort);
	}
	camel_local_summary_construct ((CamelLocalSummary *) new, mbox_name, NULL);
	camel_folder_summary_load ((CamelFolderSummary *) new, NULL);
	return new;
}

static gint
spool_summary_load (CamelLocalSummary *cls,
                    gint forceindex,
                    GError **error)
{
	/* if not loading, then rescan mbox file content */
	camel_local_summary_check_force (cls);

	return 0;
}

/* perform a full sync */
static gint
spool_summary_sync_full (CamelMboxSummary *cls,
                         gboolean expunge,
                         CamelFolderChangeInfo *changeinfo,
                         GCancellable *cancellable,
                         GError **error)
{
	gint fd = -1, fdout = -1;
	gchar tmpname[64] = { '\0' };
	gchar *buffer, *p;
	goffset spoollen, outlen;
	gint size, sizeout;
	struct stat st;
	guint32 flags = (expunge ? 1 : 0);

	d (printf ("performing full summary/sync\n"));

	camel_operation_push_message (cancellable, _("Storing folder"));

	fd = open (((CamelLocalSummary *) cls)->folder_path, O_RDWR | O_LARGEFILE);
	if (fd == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not open file: %s: %s"),
			((CamelLocalSummary *) cls)->folder_path,
			g_strerror (errno));
		camel_operation_pop_message (cancellable);
		return -1;
	}

	g_snprintf (tmpname, sizeof (tmpname), "/tmp/spool.camel.XXXXXX");
	fdout = g_mkstemp (tmpname);

	d (printf ("Writing tmp file to %s\n", tmpname));
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

	/* sync out content */
	if (fsync (fdout) == -1) {
		g_warning ("Cannot synchronize temporary folder: %s", g_strerror (errno));
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not synchronize temporary folder %s: %s"),
			((CamelLocalSummary *) cls)->folder_path,
			g_strerror (errno));
		goto error;
	}

	/* see if we can write this much to the spool file */
	if (fstat (fd, &st) == -1) {
		g_warning ("Cannot synchronize temporary folder: %s", g_strerror (errno));
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not synchronize temporary folder %s: %s"),
			((CamelLocalSummary *) cls)->folder_path,
			g_strerror (errno));
		goto error;
	}
	spoollen = st.st_size;

	if (fstat (fdout, &st) == -1) {
		g_warning ("Cannot synchronize temporary folder: %s", g_strerror (errno));
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not synchronize temporary folder %s: %s"),
			((CamelLocalSummary *) cls)->folder_path,
			g_strerror (errno));
		goto error;
	}
	outlen = st.st_size;

	/* I think this is the right way to do this - checking that the file will fit the new data */
	if (outlen > 0
	    && (lseek (fd, outlen - 1, SEEK_SET) == -1
		|| write (fd, "", 1) != 1
		|| fsync (fd) == -1
		|| lseek (fd, 0, SEEK_SET) == -1
		|| lseek (fdout, 0, SEEK_SET) == -1)) {
		g_warning ("Cannot synchronize spool folder: %s", g_strerror (errno));
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not synchronize spool folder %s: %s"),
			((CamelLocalSummary *) cls)->folder_path,
			g_strerror (errno));
		/* incase we ran out of room, remove any trailing space first */
		if (ftruncate (fd, spoollen) == -1) {
			g_debug ("%s: Failed to call ftruncate: %s", G_STRFUNC, g_strerror (errno));
		}
		goto error;
	}

	/* now copy content back */
	buffer = g_malloc (8192);
	size = 1;
	while (size > 0) {
		do {
			size = read (fdout, buffer, 8192);
		} while (size == -1 && errno == EINTR);

		if (size > 0) {
			p = buffer;
			do {
				sizeout = write (fd, p, size);
				if (sizeout > 0) {
					p+= sizeout;
					size -= sizeout;
				}
			} while ((sizeout == -1 && errno == EINTR) && size > 0);
			size = sizeout;
		}

		if (size == -1) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Could not synchronize spool folder %s: %s\n"
				"Folder may be corrupt, copy saved in “%s”"),
				((CamelLocalSummary *) cls)->folder_path,
				g_strerror (errno), tmpname);
			/* so we dont delete it */
			tmpname[0] = '\0';
			g_free (buffer);
			goto error;
		}
	}

	g_free (buffer);

	d (printf ("Closing folders\n"));

	if (ftruncate (fd, outlen) == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not synchronize spool folder %s: %s\n"
			"Folder may be corrupt, copy saved in “%s”"),
			((CamelLocalSummary *) cls)->folder_path,
			g_strerror (errno), tmpname);
		tmpname[0] = '\0';
		goto error;
	}

	if (close (fd) == -1) {
		g_warning ("Cannot close source folder: %s", g_strerror (errno));
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not synchronize spool folder %s: %s\n"
			"Folder may be corrupt, copy saved in “%s”"),
			((CamelLocalSummary *) cls)->folder_path,
			g_strerror (errno), tmpname);
		tmpname[0] = '\0';
		fd = -1;
		goto error;
	}

	close (fdout);

	if (tmpname[0] != '\0')
		unlink (tmpname);

	camel_operation_pop_message (cancellable);

	return 0;
 error:
	if (fd != -1)
		close (fd);

	if (fdout != -1)
		close (fdout);

	if (tmpname[0] != '\0')
		unlink (tmpname);

	camel_operation_pop_message (cancellable);

	return -1;
}

static gint
spool_summary_check (CamelLocalSummary *cls,
                     CamelFolderChangeInfo *changeinfo,
                     GCancellable *cancellable,
                     GError **error)
{
	gint i;
	gboolean work;
	struct stat st;
	CamelFolderSummary *s = (CamelFolderSummary *) cls;
	GPtrArray *known_uids;

	if (CAMEL_LOCAL_SUMMARY_CLASS (camel_spool_summary_parent_class)->check (cls, changeinfo, cancellable, error) == -1)
		return -1;

	/* check to see if we need to copy/update the file; missing xev headers prompt this */
	work = FALSE;
	camel_folder_summary_prepare_fetch_all (s, error);
	known_uids = camel_folder_summary_get_array (s);
	for (i = 0; !work && known_uids && i < known_uids->len; i++) {
		CamelMessageInfo *info = camel_folder_summary_get (s, g_ptr_array_index (known_uids, i));
		g_return_val_if_fail (info, -1);
		work = (camel_message_info_get_flags (info) & (CAMEL_MESSAGE_FOLDER_NOXEV)) != 0;
		g_clear_object (&info);
	}
	camel_folder_summary_free_array (known_uids);

	/* if we do, then write out the headers using sync_full, etc */
	if (work) {
		d (printf ("Have to add new headers, re-syncing from the start to accomplish this\n"));
		if (CAMEL_MBOX_SUMMARY_GET_CLASS (cls)->sync_full (
			CAMEL_MBOX_SUMMARY (cls), FALSE,
			changeinfo, cancellable, error) == -1)
			return -1;

		if (g_stat (cls->folder_path, &st) == -1) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Unknown error: %s"),
				g_strerror (errno));
			return -1;
		}

		((CamelMboxSummary *) cls)->folder_size = st.st_size;
		camel_folder_summary_set_timestamp (CAMEL_FOLDER_SUMMARY (cls), st.st_mtime);
	}

	return 0;
}

static gint
spool_summary_need_index (void)
{
	return 0;
}
