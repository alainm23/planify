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
 *          Jeffrey Stedfast <fejj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <inttypes.h>

#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include "camel-mbox-folder.h"
#include "camel-mbox-message-info.h"
#include "camel-mbox-store.h"
#include "camel-mbox-summary.h"

#ifndef O_BINARY
#define O_BINARY 0
#endif

#define d(x) /*(printf("%s(%d): ", __FILE__, __LINE__),(x))*/

G_DEFINE_TYPE (CamelMboxFolder, camel_mbox_folder, CAMEL_TYPE_LOCAL_FOLDER)

static gint
mbox_folder_cmp_uids (CamelFolder *folder,
                      const gchar *uid1,
                      const gchar *uid2)
{
	CamelMboxMessageInfo *a, *b;
	goffset aoffset, boffset;
	gint res;

	g_return_val_if_fail (folder != NULL, 0);
	g_return_val_if_fail (camel_folder_get_folder_summary (folder) != NULL, 0);

	a = (CamelMboxMessageInfo *) camel_folder_summary_get (camel_folder_get_folder_summary (folder), uid1);
	b = (CamelMboxMessageInfo *) camel_folder_summary_get (camel_folder_get_folder_summary (folder), uid2);

	if (!a || !b) {
		/* It's not a problem when one of the messages is not in the summary */
		if (a)
			g_object_unref (a);
		if (b)
			g_object_unref (b);

		if (a == b)
			return 0;
		if (!a)
			return -1;
		return 1;
	}

	aoffset = camel_mbox_message_info_get_offset (a);
	boffset = camel_mbox_message_info_get_offset (b);

	res = aoffset < boffset ? -1 : aoffset == boffset ? 0 : 1;

	g_clear_object (&a);
	g_clear_object (&b);

	return res;
}

static void
mbox_folder_sort_uids (CamelFolder *folder,
                       GPtrArray *uids)
{
	g_return_if_fail (camel_mbox_folder_parent_class != NULL);
	g_return_if_fail (folder != NULL);

	if (uids && uids->len > 1)
		camel_folder_summary_prepare_fetch_all (camel_folder_get_folder_summary (folder), NULL);

	CAMEL_FOLDER_CLASS (camel_mbox_folder_parent_class)->sort_uids (folder, uids);
}

static gchar *
mbox_folder_get_filename (CamelFolder *folder,
                          const gchar *uid,
                          GError **error)
{
	CamelLocalFolder *lf = (CamelLocalFolder *) folder;
	CamelMboxMessageInfo *info;
	gchar *filename = NULL;

	d (printf ("Getting message %s\n", uid));

	camel_local_folder_lock_changes (lf);

	/* lock the folder first, burn if we can't, need write lock for summary check */
	if (camel_local_folder_lock (lf, CAMEL_LOCK_WRITE, error) == -1) {
		camel_local_folder_unlock_changes (lf);
		return NULL;
	}

	/* check for new messages always */
	if (camel_local_summary_check ((CamelLocalSummary *) camel_folder_get_folder_summary (folder), lf->changes, NULL, error) == -1) {
		camel_local_folder_unlock (lf);
		camel_local_folder_unlock_changes (lf);
		return NULL;
	}

	/* get the message summary info */
	info = (CamelMboxMessageInfo *) camel_folder_summary_get (camel_folder_get_folder_summary (folder), uid);

	if (info == NULL) {
		set_cannot_get_message_ex (
			error, CAMEL_FOLDER_ERROR_INVALID_UID,
			uid, lf->folder_path, _("No such message"));
	} else {
		goffset frompos;

		frompos = camel_mbox_message_info_get_offset (info);
		g_clear_object (&info);

		if (frompos != -1)
			filename = g_strdup_printf ("%s%s!%" G_GINT64_FORMAT, lf->folder_path, G_DIR_SEPARATOR_S, (gint64) frompos);
	}

	/* and unlock now we're finished with it */
	camel_local_folder_unlock (lf);
	camel_local_folder_unlock_changes (lf);

	return filename;
}

static gboolean
mbox_folder_append_message_sync (CamelFolder *folder,
                                 CamelMimeMessage *message,
                                 CamelMessageInfo *info,
                                 gchar **appended_uid,
                                 GCancellable *cancellable,
                                 GError **error)
{
	CamelLocalFolder *lf = (CamelLocalFolder *) folder;
	CamelStream *output_stream = NULL, *filter_stream = NULL;
	CamelMimeFilter *filter_from;
	CamelMboxSummary *mbs = (CamelMboxSummary *) camel_folder_get_folder_summary (folder);
	CamelMessageInfo *mi = NULL;
	gchar *fromline = NULL;
	struct stat st;
	gint retval;
	gboolean has_attachment;
#if 0
	gchar *xev;
#endif

	camel_local_folder_lock_changes (lf);

	/* If we can't lock, dont do anything */
	if (camel_local_folder_lock (lf, CAMEL_LOCK_WRITE, error) == -1) {
		camel_local_folder_unlock_changes (lf);
		return FALSE;
	}

	d (printf ("Appending message\n"));

	/* first, check the summary is correct (updates folder_size too) */
	retval = camel_local_summary_check ((CamelLocalSummary *) camel_folder_get_folder_summary (folder), lf->changes, cancellable, error);
	if (retval == -1)
		goto fail;

	/* add it to the summary/assign the uid, etc */
	mi = camel_local_summary_add ((CamelLocalSummary *) camel_folder_get_folder_summary (folder), message, info, lf->changes, error);
	if (mi == NULL)
		goto fail;

	d (printf ("Appending message: uid is %s\n", camel_message_info_get_uid (mi)));

	has_attachment = camel_mime_message_has_attachment (message);
	if (((camel_message_info_get_flags (mi) & CAMEL_MESSAGE_ATTACHMENTS) && !has_attachment) ||
	    ((camel_message_info_get_flags (mi) & CAMEL_MESSAGE_ATTACHMENTS) == 0 && has_attachment)) {
		camel_message_info_set_flags (mi, CAMEL_MESSAGE_ATTACHMENTS, has_attachment ? CAMEL_MESSAGE_ATTACHMENTS : 0);
	}

	output_stream = camel_stream_fs_new_with_name (
		lf->folder_path, O_WRONLY | O_APPEND |
		O_LARGEFILE, 0666, error);
	if (output_stream == NULL) {
		g_prefix_error (
			error, _("Cannot open mailbox: %s: "),
			lf->folder_path);
		goto fail;
	}

	/* and we need to set the frompos/XEV explicitly */
	camel_mbox_message_info_set_offset (CAMEL_MBOX_MESSAGE_INFO (mi), mbs->folder_size);
#if 0
	xev = camel_local_summary_encode_x_evolution ((CamelLocalSummary *) camel_folder_get_folder_summary (folder), mi);
	if (xev) {
		/* the x-ev header should match the 'current' flags, no problem, so store as much */
		camel_medium_set_header ((CamelMedium *) message, "X-Evolution", xev);
		camel_mesage_info_set_flags (mi, CAMEL_MESSAGE_FOLDER_NOXEV | CAMEL_MESSAGE_FOLDER_FLAGGED, 0);
		g_free (xev);
	}
#endif

	/* we must write this to the non-filtered stream ... */
	fromline = camel_mime_message_build_mbox_from (message);
	if (camel_stream_write (output_stream, fromline, strlen (fromline), cancellable, error) == -1)
		goto fail_write;

	/* and write the content to the filtering stream, that translates '\nFrom' into '\n>From' */
	filter_stream = camel_stream_filter_new (output_stream);
	filter_from = camel_mime_filter_from_new ();
	camel_stream_filter_add ((CamelStreamFilter *) filter_stream, filter_from);
	g_object_unref (filter_from);

	if (camel_data_wrapper_write_to_stream_sync (
		(CamelDataWrapper *) message, filter_stream, cancellable, error) == -1 ||
	    camel_stream_write (filter_stream, "\n", 1, cancellable, error) == -1 ||
	    camel_stream_flush (filter_stream, cancellable, error) == -1)
		goto fail_write;

	/* filter stream ref's the output stream itself, so we need to unref it too */
	g_object_unref (filter_stream);
	g_object_unref (output_stream);
	g_free (fromline);

	/* now we 'fudge' the summary  to tell it its uptodate, because its idea of uptodate has just changed */
	/* the stat really shouldn't fail, we just wrote to it */
	if (g_stat (lf->folder_path, &st) == 0) {
		camel_folder_summary_set_timestamp (CAMEL_FOLDER_SUMMARY (mbs), st.st_mtime);
		mbs->folder_size = st.st_size;
	}

	/* unlock as soon as we can */
	camel_local_folder_unlock (lf);

	camel_local_folder_unlock_changes (lf);
	camel_local_folder_claim_changes (lf);

	if (appended_uid)
		*appended_uid = g_strdup(camel_message_info_get_uid(mi));

	g_clear_object (&mi);

	return TRUE;

fail_write:
	g_prefix_error (
		error, _("Cannot append message to mbox file: %s: "),
		lf->folder_path);

	if (output_stream) {
		gint fd;

		fd = camel_stream_fs_get_fd (CAMEL_STREAM_FS (output_stream));
		if (fd != -1) {
			/* reset the file to original size */
			do {
				retval = ftruncate (fd, mbs->folder_size);
			} while (retval == -1 && errno == EINTR);
		}

		g_object_unref (output_stream);
	}

	if (filter_stream)
		g_object_unref (filter_stream);

	g_free (fromline);

	/* remove the summary info so we are not out-of-sync with the mbox */
	camel_folder_summary_remove (CAMEL_FOLDER_SUMMARY (mbs), mi);

	/* and tell the summary it's up-to-date */
	if (g_stat (lf->folder_path, &st) == 0) {
		camel_folder_summary_set_timestamp (CAMEL_FOLDER_SUMMARY (mbs), st.st_mtime);
		mbs->folder_size = st.st_size;
	}

fail:
	/* make sure we unlock the folder - before we start triggering events into appland */
	camel_local_folder_unlock (lf);

	camel_local_folder_unlock_changes (lf);
	/* cascade the changes through, anyway, if there are any outstanding */
	camel_local_folder_claim_changes (lf);

	g_clear_object (&mi);

	return FALSE;
}

static CamelMimeMessage *
mbox_folder_get_message_sync (CamelFolder *folder,
                              const gchar *uid,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelLocalFolder *lf = (CamelLocalFolder *) folder;
	CamelMimeMessage *message = NULL;
	CamelMboxMessageInfo *info;
	CamelMimeParser *parser = NULL;
	gint fd, retval;
	gint retried = FALSE;
	goffset frompos;

	d (printf ("Getting message %s\n", uid));

	camel_local_folder_lock_changes (lf);

	/* lock the folder first, burn if we can't, need write lock for summary check */
	if (camel_local_folder_lock (lf, CAMEL_LOCK_WRITE, error) == -1) {
		camel_local_folder_unlock_changes (lf);
		return NULL;
	}

	/* check for new messages always */
	if (camel_local_summary_check ((CamelLocalSummary *) camel_folder_get_folder_summary (folder), lf->changes, cancellable, error) == -1) {
		camel_local_folder_unlock (lf);
		camel_local_folder_unlock_changes (lf);
		return NULL;
	}

retry:
	/* get the message summary info */
	info = (CamelMboxMessageInfo *) camel_folder_summary_get (camel_folder_get_folder_summary (folder), uid);

	if (info == NULL) {
		set_cannot_get_message_ex (
			error, CAMEL_FOLDER_ERROR_INVALID_UID,
			uid, lf->folder_path, _("No such message"));
		goto fail;
	}

	frompos = camel_mbox_message_info_get_offset (CAMEL_MBOX_MESSAGE_INFO (info));
	g_clear_object (&info);

	if (frompos == -1)
		goto fail;

	/* we use an fd instead of a normal stream here - the reason is subtle, camel_mime_part will cache
	 * the whole message in memory if the stream is non-seekable (which it is when built from a parser
	 * with no stream).  This means we dont have to lock the mbox for the life of the message, but only
	 * while it is being created. */

	fd = g_open (lf->folder_path, O_LARGEFILE | O_RDONLY | O_BINARY, 0);
	if (fd == -1) {
		set_cannot_get_message_ex (
			error, CAMEL_ERROR_GENERIC,
			uid, lf->folder_path, g_strerror (errno));
		goto fail;
	}

	/* we use a parser to verify the message is correct, and in the correct position */
	parser = camel_mime_parser_new ();
	camel_mime_parser_init_with_fd (parser, fd);
	camel_mime_parser_scan_from (parser, TRUE);

	camel_mime_parser_seek (parser, frompos, SEEK_SET);
	if (camel_mime_parser_step (parser, NULL, NULL) != CAMEL_MIME_PARSER_STATE_FROM
	    || camel_mime_parser_tell_start_from (parser) != frompos) {

		g_warning ("Summary doesn't match the folder contents!  eek!\n"
			"  expecting offset %ld got %ld, state = %d", (glong) frompos,
			(glong) camel_mime_parser_tell_start_from (parser),
			camel_mime_parser_state (parser));

		g_object_unref (parser);
		parser = NULL;

		if (!retried) {
			retried = TRUE;
			camel_local_summary_check_force ((CamelLocalSummary *) camel_folder_get_folder_summary (folder));
			retval = camel_local_summary_check ((CamelLocalSummary *) camel_folder_get_folder_summary (folder), lf->changes, cancellable, error);
			if (retval != -1)
				goto retry;
		}

		set_cannot_get_message_ex (
			error, CAMEL_FOLDER_ERROR_INVALID,
			uid, lf->folder_path,
			_("The folder appears to be irrecoverably corrupted."));
		goto fail;
	}

	message = camel_mime_message_new ();
	if (!camel_mime_part_construct_from_parser_sync (
		(CamelMimePart *) message, parser, cancellable, error)) {
		g_prefix_error (
			error, _("Cannot get message %s from folder %s: "),
			uid, lf->folder_path);
		g_object_unref (message);
		message = NULL;
		goto fail;
	}

	camel_medium_remove_header ((CamelMedium *) message, "X-Evolution");

fail:
	/* and unlock now we're finished with it */
	camel_local_folder_unlock (lf);
	camel_local_folder_unlock_changes (lf);

	if (parser)
		g_object_unref (parser);

	/* use the opportunity to notify of changes (particularly if we had a rebuild) */
	camel_local_folder_claim_changes (lf);

	return message;
}

static CamelLocalSummary *
mbox_folder_create_summary (CamelLocalFolder *lf,
                            const gchar *folder,
                            CamelIndex *index)
{
	return (CamelLocalSummary *) camel_mbox_summary_new ((CamelFolder *) lf, folder, index);
}

static gint
mbox_folder_lock (CamelLocalFolder *lf,
                  CamelLockType type,
                  GError **error)
{
#ifndef G_OS_WIN32
	CamelMboxFolder *mf = (CamelMboxFolder *) lf;

	/* make sure we have matching unlocks for locks, camel-local-folder class should enforce this */
	g_return_val_if_fail (mf->lockfd == -1, -1);

	mf->lockfd = open (lf->folder_path, O_RDWR | O_LARGEFILE, 0);
	if (mf->lockfd == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Cannot create folder lock on %s: %s"),
			lf->folder_path, g_strerror (errno));
		return -1;
	}

	if (camel_lock_folder (lf->folder_path, mf->lockfd, type, error) == -1) {
		close (mf->lockfd);
		mf->lockfd = -1;
		return -1;
	}
#endif
	return 0;
}

static void
mbox_folder_unlock (CamelLocalFolder *lf)
{
#ifndef G_OS_WIN32
	CamelMboxFolder *mf = (CamelMboxFolder *) lf;

	g_return_if_fail (mf->lockfd != -1);
	if (mf->lockfd != -1) {
		camel_unlock_folder (lf->folder_path, mf->lockfd);
		close (mf->lockfd);
	}
	mf->lockfd = -1;
#endif
}

static void
camel_mbox_folder_class_init (CamelMboxFolderClass *class)
{
	CamelFolderClass *folder_class;
	CamelLocalFolderClass *local_folder_class;

	folder_class = CAMEL_FOLDER_CLASS (class);
	folder_class->cmp_uids = mbox_folder_cmp_uids;
	folder_class->sort_uids = mbox_folder_sort_uids;
	folder_class->get_filename = mbox_folder_get_filename;
	folder_class->append_message_sync = mbox_folder_append_message_sync;
	folder_class->get_message_sync = mbox_folder_get_message_sync;

	local_folder_class = CAMEL_LOCAL_FOLDER_CLASS (class);
	local_folder_class->create_summary = mbox_folder_create_summary;
	local_folder_class->lock = mbox_folder_lock;
	local_folder_class->unlock = mbox_folder_unlock;
}

static void
camel_mbox_folder_init (CamelMboxFolder *mbox_folder)
{
	mbox_folder->lockfd = -1;
}

CamelFolder *
camel_mbox_folder_new (CamelStore *parent_store,
                       const gchar *full_name,
                       guint32 flags,
                       GCancellable *cancellable,
                       GError **error)
{
	CamelFolder *folder;
	gchar *basename;

	basename = g_path_get_basename (full_name);

	folder = g_object_new (
		CAMEL_TYPE_MBOX_FOLDER,
		"display-name", basename, "full-name", full_name,
		"parent-store", parent_store, NULL);
	folder = (CamelFolder *) camel_local_folder_construct (
		(CamelLocalFolder *) folder, flags, cancellable, error);

	g_free (basename);

	return folder;
}

