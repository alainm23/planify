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
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#if !defined (G_OS_WIN32) && !defined (_POSIX_PATH_MAX)
#include <posix1_lim.h>
#endif

#include "camel-local-folder.h"
#include "camel-local-private.h"
#include "camel-local-store.h"
#include "camel-local-summary.h"

#define d(x) /*(printf("%s(%d): ", __FILE__, __LINE__),(x))*/

#ifndef PATH_MAX
#define PATH_MAX _POSIX_PATH_MAX
#endif

#define CAMEL_LOCAL_FOLDER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_LOCAL_FOLDER, CamelLocalFolderPrivate))

/* The custom property ID is a CamelArg artifact.
 * It still identifies the property in state files. */
enum {
	PROP_0,
	PROP_INDEX_BODY = 0x2400
};

G_DEFINE_TYPE (CamelLocalFolder, camel_local_folder, CAMEL_TYPE_FOLDER)

static void
local_folder_set_property (GObject *object,
                           guint property_id,
                           const GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_INDEX_BODY:
			camel_local_folder_set_index_body (
				CAMEL_LOCAL_FOLDER (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
local_folder_get_property (GObject *object,
                           guint property_id,
                           GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_INDEX_BODY:
			g_value_set_boolean (
				value, camel_local_folder_get_index_body (
				CAMEL_LOCAL_FOLDER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
local_folder_dispose (GObject *object)
{
	CamelFolder *folder;
	CamelLocalFolder *local_folder;

	folder = CAMEL_FOLDER (object);
	local_folder = CAMEL_LOCAL_FOLDER (object);

	if (camel_folder_get_folder_summary (folder)) {
		/* Something can hold the reference to the folder longer than
		   the parent store is alive, thus count with it. */
		if (camel_folder_get_parent_store (folder)) {
			camel_local_folder_lock_changes (local_folder);
			camel_local_summary_sync (
				CAMEL_LOCAL_SUMMARY (camel_folder_get_folder_summary (folder)),
				FALSE, local_folder->changes, NULL, NULL);
			camel_local_folder_unlock_changes (local_folder);
		}
	}

	g_clear_object (&local_folder->search);
	g_clear_object (&local_folder->index);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_local_folder_parent_class)->dispose (object);
}

static void
local_folder_finalize (GObject *object)
{
	CamelLocalFolder *local_folder;

	local_folder = CAMEL_LOCAL_FOLDER (object);

	while (local_folder->locked > 0)
		camel_local_folder_unlock (local_folder);

	g_free (local_folder->base_path);
	g_free (local_folder->folder_path);
	g_free (local_folder->index_path);

	camel_folder_change_info_free (local_folder->changes);

	g_mutex_clear (&local_folder->priv->search_lock);
	g_rec_mutex_clear (&local_folder->priv->changes_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_local_folder_parent_class)->finalize (object);
}

static void
local_folder_constructed (GObject *object)
{
	CamelLocalSettings *local_settings;
	CamelProvider *provider;
	CamelSettings *settings;
	CamelService *service;
	CamelFolder *folder;
	CamelStore *parent_store;
	const gchar *full_name;
	const gchar *tmp;
	gchar *description;
	gchar *root_path;
	gchar *path;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (camel_local_folder_parent_class)->constructed (object);

	folder = CAMEL_FOLDER (object);
	full_name = camel_folder_get_full_name (folder);
	parent_store = camel_folder_get_parent_store (folder);

	service = CAMEL_SERVICE (parent_store);
	provider = camel_service_get_provider (service);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	root_path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	if (root_path == NULL)
		return;

	path = g_strdup_printf ("%s/%s", root_path, full_name);

	if ((tmp = getenv ("HOME")) && strncmp (tmp, path, strlen (tmp)) == 0)
		description = g_strdup_printf (
			/* Translators: This is used for a folder description,
			 * for folders being under $HOME.  The first %s is replaced
			 * with a relative path under $HOME, the second %s is
			 * replaced with a protocol name, like mbox/maldir/... */
			_("~%s (%s)"),
			path + strlen (tmp),
			provider->protocol);
	else if ((tmp = "/var/spool/mail") && strncmp (tmp, path, strlen (tmp)) == 0)
		description = g_strdup_printf (
			/* Translators: This is used for a folder description, for
			 * folders being under /var/spool/mail.  The first %s is
			 * replaced with a relative path under /var/spool/mail,
			 * the second %s is replaced with a protocol name, like
			 * mbox/maldir/... */
			_("mailbox: %s (%s)"),
			path + strlen (tmp),
			provider->protocol);
	else if ((tmp = "/var/mail") && strncmp (tmp, path, strlen (tmp)) == 0)
		description = g_strdup_printf (
			/* Translators: This is used for a folder description, for
			 * folders being under /var/mail.  The first %s is replaced
			 * with a relative path under /var/mail, the second %s is
			 * replaced with a protocol name, like mbox/maldir/... */
			_("mailbox: %s (%s)"),
			path + strlen (tmp),
			provider->protocol);
	else
		description = g_strdup_printf (
			/* Translators: This is used for a folder description.
			 * The first %s is replaced with a folder's full path,
			 * the second %s is replaced with a protocol name, like
			 * mbox/maldir/... */
			_("%s (%s)"), path,
			provider->protocol);

	camel_folder_set_description (folder, description);

	g_free (description);
	g_free (root_path);
	g_free (path);
}

static guint32
local_folder_get_permanent_flags (CamelFolder *folder)
{
	return CAMEL_MESSAGE_ANSWERED |
		CAMEL_MESSAGE_DELETED |
		CAMEL_MESSAGE_DRAFT |
		CAMEL_MESSAGE_FLAGGED |
		CAMEL_MESSAGE_SEEN |
		CAMEL_MESSAGE_ANSWERED_ALL |
		CAMEL_MESSAGE_USER;
}

static GPtrArray *
local_folder_search_by_expression (CamelFolder *folder,
                                   const gchar *expression,
                                   GCancellable *cancellable,
                                   GError **error)
{
	CamelLocalFolder *local_folder = CAMEL_LOCAL_FOLDER (folder);
	GPtrArray *matches;

	CAMEL_LOCAL_FOLDER_LOCK (folder, search_lock);

	if (local_folder->search == NULL)
		local_folder->search = camel_folder_search_new ();

	camel_folder_search_set_folder (local_folder->search, folder);
	if (camel_local_folder_get_index_body (local_folder))
		camel_folder_search_set_body_index (local_folder->search, local_folder->index);
	else
		camel_folder_search_set_body_index (local_folder->search, NULL);
	matches = camel_folder_search_search (local_folder->search, expression, NULL, cancellable, error);

	CAMEL_LOCAL_FOLDER_UNLOCK (folder, search_lock);

	return matches;
}

static GPtrArray *
local_folder_search_by_uids (CamelFolder *folder,
                             const gchar *expression,
                             GPtrArray *uids,
                             GCancellable *cancellable,
                             GError **error)
{
	CamelLocalFolder *local_folder = CAMEL_LOCAL_FOLDER (folder);
	GPtrArray *matches;

	if (uids->len == 0)
		return g_ptr_array_new ();

	CAMEL_LOCAL_FOLDER_LOCK (folder, search_lock);

	if (local_folder->search == NULL)
		local_folder->search = camel_folder_search_new ();

	camel_folder_search_set_folder (local_folder->search, folder);
	if (camel_local_folder_get_index_body (local_folder))
		camel_folder_search_set_body_index (local_folder->search, local_folder->index);
	else
		camel_folder_search_set_body_index (local_folder->search, NULL);
	matches = camel_folder_search_search (local_folder->search, expression, uids, cancellable, error);

	CAMEL_LOCAL_FOLDER_UNLOCK (folder, search_lock);

	return matches;
}

static void
local_folder_search_free (CamelFolder *folder,
                          GPtrArray *result)
{
	CamelLocalFolder *local_folder = CAMEL_LOCAL_FOLDER (folder);

	/* we need to lock this free because of the way search_free_result works */
	/* FIXME: put the lock inside search_free_result */
	CAMEL_LOCAL_FOLDER_LOCK (folder, search_lock);

	camel_folder_search_free_result (local_folder->search, result);

	CAMEL_LOCAL_FOLDER_UNLOCK (folder, search_lock);
}

static void
local_folder_delete (CamelFolder *folder)
{
	CamelLocalFolder *lf = (CamelLocalFolder *) folder;

	if (lf->index)
		camel_index_delete (lf->index);

	CAMEL_FOLDER_CLASS (camel_local_folder_parent_class)->delete_ (folder);
}

static void
local_folder_rename (CamelFolder *folder,
                     const gchar *newname)
{
	CamelLocalFolder *lf = (CamelLocalFolder *) folder;
	gchar *statepath;
	CamelLocalStore *ls;
	CamelStore *parent_store;

	parent_store = camel_folder_get_parent_store (folder);
	ls = CAMEL_LOCAL_STORE (parent_store);

	d (printf ("renaming local folder paths to '%s'\n", newname));

	/* Sync? */

	g_free (lf->folder_path);
	g_free (lf->index_path);

	lf->folder_path = camel_local_store_get_full_path (ls, newname);
	lf->index_path = camel_local_store_get_meta_path (ls, newname, ".ibex");
	statepath = camel_local_store_get_meta_path (ls, newname, ".cmeta");
	camel_object_set_state_filename (CAMEL_OBJECT (lf), statepath);
	g_free (statepath);

	/* FIXME: Poke some internals, sigh */
	g_free (((CamelLocalSummary *) camel_folder_get_folder_summary (folder))->folder_path);
	((CamelLocalSummary *) camel_folder_get_folder_summary (folder))->folder_path = g_strdup (lf->folder_path);

	CAMEL_FOLDER_CLASS (camel_local_folder_parent_class)->rename (folder, newname);
}

static guint32
local_folder_count_by_expression (CamelFolder *folder,
                                  const gchar *expression,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelLocalFolder *local_folder = CAMEL_LOCAL_FOLDER (folder);
	gint matches;

	CAMEL_LOCAL_FOLDER_LOCK (folder, search_lock);

	if (local_folder->search == NULL)
		local_folder->search = camel_folder_search_new ();

	camel_folder_search_set_folder (local_folder->search, folder);
	if (camel_local_folder_get_index_body (local_folder))
		camel_folder_search_set_body_index (local_folder->search, local_folder->index);
	else
		camel_folder_search_set_body_index (local_folder->search, NULL);
	matches = camel_folder_search_count (local_folder->search, expression, cancellable, error);

	CAMEL_LOCAL_FOLDER_UNLOCK (folder, search_lock);

	return matches;
}

static GPtrArray *
local_folder_get_uncached_uids (CamelFolder *folder,
                                GPtrArray *uids,
                                GError **error)
{
	/* By default, we would have everything local.
	 * No need to fetch from anywhere. */
	return g_ptr_array_new ();
}

static gboolean
local_folder_expunge_sync (CamelFolder *folder,
                           GCancellable *cancellable,
                           GError **error)
{
	/* Just do a sync with expunge, serves the same purpose */
	/* call the callback directly, to avoid locking problems */
	return CAMEL_FOLDER_GET_CLASS (folder)->synchronize_sync (
		folder, TRUE, cancellable, error);
}

static gboolean
local_folder_refresh_info_sync (CamelFolder *folder,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelStore *parent_store;
	CamelLocalFolder *lf = (CamelLocalFolder *) folder;
	gboolean need_summary_check;

	parent_store = camel_folder_get_parent_store (folder);

	need_summary_check = camel_local_store_get_need_summary_check (
		CAMEL_LOCAL_STORE (parent_store));

	camel_local_folder_lock_changes (lf);
	if (need_summary_check &&
	    camel_local_summary_check ((CamelLocalSummary *) camel_folder_get_folder_summary (folder), lf->changes, cancellable, error) == -1) {
		camel_local_folder_unlock_changes (lf);
		return FALSE;
	}

	camel_local_folder_unlock_changes (lf);
	camel_local_folder_claim_changes (lf);

	return TRUE;
}

static gboolean
local_folder_synchronize_sync (CamelFolder *folder,
                               gboolean expunge,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelLocalFolder *lf = CAMEL_LOCAL_FOLDER (folder);
	gboolean success;

	d (printf ("local sync '%s' , expunge=%s\n", folder->full_name, expunge?"true":"false"));

	camel_local_folder_lock_changes (lf);

	if (camel_local_folder_lock (lf, CAMEL_LOCK_WRITE, error) == -1) {
		camel_local_folder_unlock_changes (lf);
		return FALSE;
	}

	camel_object_state_write (CAMEL_OBJECT (lf));

	/* if sync fails, we'll pass it up on exit through ex */
	success = (camel_local_summary_sync (
		(CamelLocalSummary *) camel_folder_get_folder_summary (folder),
		expunge, lf->changes, cancellable, error) == 0);
	camel_local_folder_unlock (lf);

	camel_local_folder_unlock_changes (lf);
	camel_local_folder_claim_changes (lf);

	return success;
}

static gint
local_folder_lock (CamelLocalFolder *lf,
                   CamelLockType type,
                   GError **error)
{
	return 0;
}

static void
local_folder_unlock (CamelLocalFolder *lf)
{
	/* nothing */
}

static void
camel_local_folder_class_init (CamelLocalFolderClass *class)
{
	GObjectClass *object_class;
	CamelFolderClass *folder_class;

	g_type_class_add_private (class, sizeof (CamelLocalFolderPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = local_folder_set_property;
	object_class->get_property = local_folder_get_property;
	object_class->dispose = local_folder_dispose;
	object_class->finalize = local_folder_finalize;
	object_class->constructed = local_folder_constructed;

	folder_class = CAMEL_FOLDER_CLASS (class);
	folder_class->get_permanent_flags = local_folder_get_permanent_flags;
	folder_class->search_by_expression = local_folder_search_by_expression;
	folder_class->search_by_uids = local_folder_search_by_uids;
	folder_class->search_free = local_folder_search_free;
	folder_class->delete_ = local_folder_delete;
	folder_class->rename = local_folder_rename;
	folder_class->count_by_expression = local_folder_count_by_expression;
	folder_class->get_uncached_uids = local_folder_get_uncached_uids;
	folder_class->expunge_sync = local_folder_expunge_sync;
	folder_class->refresh_info_sync = local_folder_refresh_info_sync;
	folder_class->synchronize_sync = local_folder_synchronize_sync;

	class->lock = local_folder_lock;
	class->unlock = local_folder_unlock;

	g_object_class_install_property (
		object_class,
		PROP_INDEX_BODY,
		g_param_spec_boolean (
			"index-body",
			"Index Body",
			_("_Index message body data"),
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			CAMEL_PARAM_PERSISTENT));
}

static void
camel_local_folder_init (CamelLocalFolder *local_folder)
{
	CamelFolder *folder = CAMEL_FOLDER (local_folder);

	local_folder->priv = CAMEL_LOCAL_FOLDER_GET_PRIVATE (local_folder);
	g_mutex_init (&local_folder->priv->search_lock);
	g_rec_mutex_init (&local_folder->priv->changes_lock);

	camel_folder_set_flags (folder, camel_folder_get_flags (folder) | CAMEL_FOLDER_HAS_SUMMARY_CAPABILITY);

	local_folder->search = NULL;
}

CamelLocalFolder *
camel_local_folder_construct (CamelLocalFolder *lf,
                              guint32 flags,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelFolder *folder;
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	gchar *statepath;
#ifndef G_OS_WIN32
#ifdef __GLIBC__
	gchar *folder_path;
#else
	gchar folder_path[PATH_MAX];
#endif
#endif
	gint forceindex;
	CamelLocalStore *ls;
	CamelStore *parent_store;
	const gchar *full_name;
	gboolean need_summary_check;
	gboolean filter_all = FALSE, filter_junk = TRUE;

	folder = CAMEL_FOLDER (lf);
	full_name = camel_folder_get_full_name (folder);
	parent_store = camel_folder_get_parent_store (folder);

	service = CAMEL_SERVICE (parent_store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	lf->base_path = camel_local_settings_dup_path (local_settings);
	filter_all = camel_local_settings_get_filter_all (local_settings);
	filter_junk = camel_local_settings_get_filter_junk (local_settings);

	g_object_unref (settings);

	ls = CAMEL_LOCAL_STORE (parent_store);
	need_summary_check = camel_local_store_get_need_summary_check (ls);

	filter_junk = filter_junk || camel_local_store_is_main_store (CAMEL_LOCAL_STORE (parent_store));
	if (filter_all || filter_junk) {
		camel_folder_set_flags (folder, camel_folder_get_flags (folder) |
			(filter_all ? CAMEL_FOLDER_FILTER_RECENT : 0) |
			(filter_junk ? CAMEL_FOLDER_FILTER_JUNK : 0));
	}

	lf->folder_path = camel_local_store_get_full_path (ls, full_name);
	lf->index_path = camel_local_store_get_meta_path (ls, full_name, ".ibex");
	statepath = camel_local_store_get_meta_path (ls, full_name, ".cmeta");

	camel_object_set_state_filename (CAMEL_OBJECT (lf), statepath);
	g_free (statepath);

	lf->flags = flags;

	if (camel_object_state_read (CAMEL_OBJECT (lf)) == -1) {
		/* No metadata - load defaults and persitify */
		camel_local_folder_set_index_body (lf, TRUE);
		camel_object_state_write (CAMEL_OBJECT (lf));
	}

	/* XXX Canonicalizing the folder path portably is a messy affair.
	 *     The proposed GLib function in [1] would be useful here.
	 *
	 *     [1] https://bugzilla.gnome.org/show_bug.cgi?id=111848
	 */
#ifndef G_OS_WIN32
	/* follow any symlinks to the mailbox */
#ifdef __GLIBC__
	if ((folder_path = realpath (lf->folder_path, NULL)) != NULL) {
#else
	if (realpath (lf->folder_path, folder_path) != NULL) {
#endif
		g_free (lf->folder_path);
		lf->folder_path = g_strdup (folder_path);
#ifdef __GLIBC__
		/* Not a typo.  Use free() here, not g_free().
		 * The path string was allocated by realpath(). */
		free (folder_path);
#endif
	}
#endif
	camel_local_folder_lock_changes (lf);

	lf->changes = camel_folder_change_info_new ();

	/* TODO: Remove the following line, it is a temporary workaround to remove
	 * the old-format 'ibex' files that might be lying around */
	g_unlink (lf->index_path);

	/* FIXME: Need to run indexing off of the setv method */

	/* if we have no/invalid index file, force it */
	forceindex = camel_text_index_check (lf->index_path) == -1;
	if (lf->flags & CAMEL_STORE_FOLDER_BODY_INDEX) {
		gint flag = O_RDWR | O_CREAT;

		if (forceindex)
			flag |= O_TRUNC;

		lf->index = (CamelIndex *) camel_text_index_new (lf->index_path, flag);
		if (lf->index == NULL) {
			/* yes, this isn't fatal at all */
			g_warning ("Could not open/create index file: %s: indexing not performed", g_strerror (errno));
			forceindex = FALSE;
			/* record that we dont have an index afterall */
			lf->flags &= ~CAMEL_STORE_FOLDER_BODY_INDEX;
		}
	} else {
		/* if we do have an index file, remove it (?) */
		if (forceindex == FALSE)
			camel_text_index_remove (lf->index_path);
		forceindex = FALSE;
	}

	camel_folder_take_folder_summary (folder, CAMEL_FOLDER_SUMMARY (CAMEL_LOCAL_FOLDER_GET_CLASS (lf)->create_summary (lf, lf->folder_path, lf->index)));
	if (!(flags & CAMEL_STORE_IS_MIGRATING) && !camel_local_summary_load ((CamelLocalSummary *) camel_folder_get_folder_summary (folder), forceindex, NULL)) {
		/* ? */
		if (need_summary_check &&
		    camel_local_summary_check ((CamelLocalSummary *) camel_folder_get_folder_summary (folder), lf->changes, cancellable, error) == 0) {
			/* we sync here so that any hard work setting up the folder isn't lost */
			if (camel_local_summary_sync ((CamelLocalSummary *) camel_folder_get_folder_summary (folder), FALSE, lf->changes, cancellable, error) == -1) {
				camel_local_folder_unlock_changes (lf);
				g_object_unref (folder);
				return NULL;
			}
		}
	}

	camel_local_folder_unlock_changes (lf);

	/* TODO: This probably shouldn't be here? */
	if ((flags & CAMEL_STORE_FOLDER_CREATE) != 0) {
		CamelFolderInfo *fi;

		/* Use 'recursive' mode, even for just created folder, to have set whether
		   the folder has children or not properly. */
		fi = camel_store_get_folder_info_sync (parent_store, full_name, CAMEL_STORE_FOLDER_INFO_RECURSIVE, NULL, NULL);
		g_return_val_if_fail (fi != NULL, lf);

		camel_store_folder_created (parent_store, fi);
		camel_folder_info_free (fi);
	}

	return lf;
}

gboolean
camel_local_folder_get_index_body (CamelLocalFolder *local_folder)
{
	g_return_val_if_fail (CAMEL_IS_LOCAL_FOLDER (local_folder), FALSE);

	return (local_folder->flags & CAMEL_STORE_FOLDER_BODY_INDEX);
}

void
camel_local_folder_set_index_body (CamelLocalFolder *local_folder,
                                   gboolean index_body)
{
	g_return_if_fail (CAMEL_IS_LOCAL_FOLDER (local_folder));

	if (index_body)
		local_folder->flags |= CAMEL_STORE_FOLDER_BODY_INDEX;
	else
		local_folder->flags &= ~CAMEL_STORE_FOLDER_BODY_INDEX;

	g_object_notify (G_OBJECT (local_folder), "index-body");
}

/* lock the folder, may be called repeatedly (with matching unlock calls),
 * with type the same or less than the first call */
gint
camel_local_folder_lock (CamelLocalFolder *lf,
                         CamelLockType type,
                         GError **error)
{
	if (lf->locked > 0) {
		/* lets be anal here - its important the code knows what its doing */
		g_return_val_if_fail (lf->locktype == type || lf->locktype == CAMEL_LOCK_WRITE, -1);
	} else {
		if (CAMEL_LOCAL_FOLDER_GET_CLASS (lf)->lock (lf, type, error) == -1)
			return -1;
		lf->locktype = type;
	}

	lf->locked++;

	return 0;
}

/* unlock folder */
gint
camel_local_folder_unlock (CamelLocalFolder *lf)
{
	g_return_val_if_fail (lf->locked > 0, -1);
	lf->locked--;
	if (lf->locked == 0)
		CAMEL_LOCAL_FOLDER_GET_CLASS (lf)->unlock (lf);

	return 0;
}

void
set_cannot_get_message_ex (GError **error,
                           gint err_code,
                           const gchar *msgID,
                           const gchar *folder_path,
                           const gchar *detailErr)
{
	g_set_error (
		error, CAMEL_ERROR, err_code,
		/* Translators: The first %s is replaced with a message ID,
		 * the second %s is replaced with the folder path,
		 * the third %s is replaced with a detailed error string */
		_("Cannot get message %s from folder %s\n%s"),
		msgID, folder_path, detailErr);
}

void
camel_local_folder_lock_changes (CamelLocalFolder *lf)
{
	g_return_if_fail (CAMEL_IS_LOCAL_FOLDER (lf));

	g_rec_mutex_lock (&lf->priv->changes_lock);
}

void
camel_local_folder_unlock_changes (CamelLocalFolder *lf)
{
	g_return_if_fail (CAMEL_IS_LOCAL_FOLDER (lf));

	g_rec_mutex_unlock (&lf->priv->changes_lock);
}

void
camel_local_folder_claim_changes (CamelLocalFolder *lf)
{
	CamelFolderChangeInfo *changes = NULL;

	g_return_if_fail (CAMEL_IS_LOCAL_FOLDER (lf));

	camel_local_folder_lock_changes (lf);

	if (lf->changes && camel_folder_change_info_changed (lf->changes)) {
		changes = lf->changes;
		lf->changes = camel_folder_change_info_new ();
	}

	camel_local_folder_unlock_changes (lf);

	if (changes) {
		camel_folder_changed (CAMEL_FOLDER (lf), changes);
		camel_folder_change_info_free (changes);
	}
}
