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

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <glib/gi18n-lib.h>

#include "camel-spool-folder.h"
#include "camel-spool-settings.h"
#include "camel-spool-store.h"
#include "camel-spool-summary.h"

#define d(x) /*(printf("%s(%d): ", __FILE__, __LINE__),(x))*/

G_DEFINE_TYPE (CamelSpoolFolder, camel_spool_folder, CAMEL_TYPE_MBOX_FOLDER)

static CamelLocalSummary *
spool_folder_create_summary (CamelLocalFolder *lf,
                             const gchar *folder,
                             CamelIndex *index)
{
	return (CamelLocalSummary *) camel_spool_summary_new (
		CAMEL_FOLDER (lf), folder);
}

static gint
spool_folder_lock (CamelLocalFolder *lf,
                   CamelLockType type,
                   GError **error)
{
	gint retry = 0;
	CamelMboxFolder *mf = (CamelMboxFolder *) lf;
	CamelSpoolFolder *sf = (CamelSpoolFolder *) lf;
	GError *local_error = NULL;

	mf->lockfd = open (lf->folder_path, O_RDWR | O_LARGEFILE, 0);
	if (mf->lockfd == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Cannot create folder lock on %s: %s"),
			lf->folder_path, g_strerror (errno));
		return -1;
	}

	while (retry < CAMEL_LOCK_RETRY) {
		if (retry > 0)
			sleep (CAMEL_LOCK_DELAY);

		g_clear_error (&local_error);

		if (camel_lock_fcntl (mf->lockfd, type, &local_error) == 0) {
			if (camel_lock_flock (mf->lockfd, type, &local_error) == 0) {
				if ((sf->lockid = camel_lock_helper_lock (lf->folder_path, &local_error)) != -1)
					return 0;
				camel_unlock_flock (mf->lockfd);
			}
			camel_unlock_fcntl (mf->lockfd);
		}
		retry++;
	}

	close (mf->lockfd);
	mf->lockfd = -1;

	if (local_error != NULL)
		g_propagate_error (error, local_error);

	return -1;
}

static void
spool_folder_unlock (CamelLocalFolder *lf)
{
	CamelMboxFolder *mf = (CamelMboxFolder *) lf;
	CamelSpoolFolder *sf = (CamelSpoolFolder *) lf;

	camel_lock_helper_unlock (sf->lockid);
	sf->lockid = -1;
	camel_unlock_flock (mf->lockfd);
	camel_unlock_fcntl (mf->lockfd);

	close (mf->lockfd);
	mf->lockfd = -1;
}

static void
camel_spool_folder_class_init (CamelSpoolFolderClass *class)
{
	CamelLocalFolderClass *local_folder_class;

	local_folder_class = CAMEL_LOCAL_FOLDER_CLASS (class);
	local_folder_class->create_summary = spool_folder_create_summary;
	local_folder_class->lock = spool_folder_lock;
	local_folder_class->unlock = spool_folder_unlock;
}

static void
camel_spool_folder_init (CamelSpoolFolder *spool_folder)
{
	spool_folder->lockid = -1;
}

CamelFolder *
camel_spool_folder_new (CamelStore *parent_store,
                        const gchar *full_name,
                        guint32 flags,
                        GCancellable *cancellable,
                        GError **error)
{
	CamelFolder *folder;
	CamelService *service;
	CamelSettings *settings;
	gboolean filter_inbox;
	gboolean use_xstatus_headers;
	gchar *basename;

	service = CAMEL_SERVICE (parent_store);

	settings = camel_service_ref_settings (service);

	filter_inbox = camel_store_settings_get_filter_inbox (
		CAMEL_STORE_SETTINGS (settings));

	use_xstatus_headers = camel_spool_settings_get_use_xstatus_headers (
		CAMEL_SPOOL_SETTINGS (settings));

	g_object_unref (settings);

	basename = g_path_get_basename (full_name);

	folder = g_object_new (
		CAMEL_TYPE_SPOOL_FOLDER,
		"display-name", basename, "full-name", full_name,
		"parent-store", parent_store, NULL);

	if (filter_inbox && strcmp (full_name, "INBOX") == 0)
		camel_folder_set_flags (folder, camel_folder_get_flags (folder) | CAMEL_FOLDER_FILTER_RECENT);
	flags &= ~CAMEL_STORE_FOLDER_BODY_INDEX;

	folder = (CamelFolder *) camel_local_folder_construct (
		(CamelLocalFolder *) folder, flags, cancellable, error);

	if (folder != NULL && use_xstatus_headers)
		camel_mbox_summary_xstatus (CAMEL_MBOX_SUMMARY (camel_folder_get_folder_summary (folder)), TRUE);

	g_free (basename);

	return folder;
}

