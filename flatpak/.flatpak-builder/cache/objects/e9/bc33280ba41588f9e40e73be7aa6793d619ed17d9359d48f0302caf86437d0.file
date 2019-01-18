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

#include <dirent.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include "camel-mh-folder.h"
#include "camel-mh-settings.h"
#include "camel-mh-store.h"
#include "camel-mh-summary.h"

#define d(x)

G_DEFINE_TYPE (CamelMhStore, camel_mh_store, CAMEL_TYPE_LOCAL_STORE)

enum {
	UPDATE_NONE,
	UPDATE_ADD,
	UPDATE_REMOVE,
	UPDATE_RENAME
};

/* update the .folders file if it exists, or create it if it doesn't */
static void
folders_update (const gchar *root,
                gint mode,
                const gchar *folder,
                const gchar *new,
                GCancellable *cancellable)
{
	gchar *tmp, *tmpnew, *line = NULL;
	gsize tmpnew_len = 0;
	CamelStream *stream, *in = NULL, *out = NULL;
	gchar *folder_newline;
	gint flen = strlen (folder);

	folder_newline = g_strdup_printf ("%s\n", folder);

	tmpnew_len = strlen (root) + 16;
	tmpnew = g_alloca (tmpnew_len);
	g_snprintf (
		tmpnew, tmpnew_len,
		"%s" G_DIR_SEPARATOR_S ".folders~", root);

	out = camel_stream_fs_new_with_name (
		tmpnew, O_WRONLY | O_CREAT | O_TRUNC, 0666, NULL);
	if (out == NULL)
		goto fail;

	tmp = g_alloca (tmpnew_len);
	g_snprintf (
		tmp, tmpnew_len,
		"%s" G_DIR_SEPARATOR_S ".folders", root);
	stream = camel_stream_fs_new_with_name (tmp, O_RDONLY, 0, NULL);
	if (stream) {
		in = camel_stream_buffer_new (stream, CAMEL_STREAM_BUFFER_READ);
		g_object_unref (stream);
	}
	if (in == NULL || stream == NULL) {
		if (mode == UPDATE_ADD) {
			gint ret;

			ret = camel_stream_write_string (
				out, folder_newline, cancellable, NULL);

			if (ret == -1)
				goto fail;
		}
		goto done;
	}

	while ((line = camel_stream_buffer_read_line ((CamelStreamBuffer *) in, cancellable, NULL))) {
		gint copy = TRUE;

		switch (mode) {
		case UPDATE_REMOVE:
			if (strcmp (line, folder) == 0)
				copy = FALSE;
			break;
		case UPDATE_RENAME:
			if (strncmp (line, folder, flen) == 0
			    && (line[flen] == 0 || line[flen] == '/')) {
				if (camel_stream_write (out, new, strlen (new), cancellable, NULL) == -1
				    || camel_stream_write (out, line + flen, strlen (line) - flen, cancellable, NULL) == -1
				    || camel_stream_write (out, "\n", 1, cancellable, NULL) == -1)
					goto fail;
				copy = FALSE;
			}
			break;
		case UPDATE_ADD: {
			gint cmp = strcmp (line, folder);

			if (cmp > 0) {
				gint ret;

				/* found insertion point */
				ret = camel_stream_write_string (
					out, folder_newline, cancellable, NULL);

				if (ret == -1)
					goto fail;
				mode = UPDATE_NONE;
			} else if (cmp == 0) {
				/* already there */
				mode = UPDATE_NONE;
			}
			break; }
		case UPDATE_NONE:
			break;
		}

		if (copy) {
			gchar *string;
			gint ret;

			string = g_strdup_printf ("%s\n", line);
			ret = camel_stream_write_string (
				out, string, cancellable, NULL);
			g_free (string);

			if (ret == -1)
				goto fail;
		}

		g_free (line);
		line = NULL;
	}

	/* add to end? */
	if (mode == UPDATE_ADD) {
		gint ret;

		ret = camel_stream_write_string (
			out, folder_newline, cancellable, NULL);

		if (ret == -1)
			goto fail;
	}

	if (camel_stream_close (out, cancellable, NULL) == -1)
		goto fail;

done:
	if (g_rename (tmpnew, tmp) == -1) {
		g_warning ("%s: Failed to rename '%s' to '%s': %s", G_STRFUNC, tmpnew, tmp, g_strerror (errno));
	}
fail:
	unlink (tmpnew);		/* remove it if its there */
	g_free (line);
	if (in)
		g_object_unref (in);
	if (out)
		g_object_unref (out);

	g_free (folder_newline);
}

static void
fill_fi (CamelStore *store,
         CamelFolderInfo *fi,
         guint32 flags,
         GCancellable *cancellable)
{
	CamelLocalStore *local_store;
	CamelFolder *folder;

	local_store = CAMEL_LOCAL_STORE (store);
	folder = camel_object_bag_peek (camel_store_get_folders_bag (store), fi->full_name);

	if (folder != NULL) {
		fi->unread = camel_folder_get_unread_message_count (folder);
		fi->total = camel_folder_get_message_count (folder);
		g_object_unref (folder);
	} else {
		CamelLocalSettings *local_settings;
		CamelSettings *settings;
		CamelService *service;
		CamelFolderSummary *s;
		gchar *folderpath;
		gchar *path;

		service = CAMEL_SERVICE (store);

		settings = camel_service_ref_settings (service);

		local_settings = CAMEL_LOCAL_SETTINGS (settings);
		path = camel_local_settings_dup_path (local_settings);

		g_object_unref (settings);

		/* This should be fast enough not to have to test for INFO_FAST */

		/* We could: if we have no folder, and FAST isn't specified,
		 * perform a full scan of all messages for their status flags.
		 * But its probably not worth it as we need to read the top of
		 * every file, i.e. very very slow */

		folderpath = g_strdup_printf ("%s/%s", path, fi->full_name);
		s = (CamelFolderSummary *) camel_mh_summary_new (NULL, folderpath, NULL);
		if (camel_folder_summary_header_load (s, store, fi->full_name, NULL)) {
			fi->unread = camel_folder_summary_get_unread_count (s);
			fi->total = camel_folder_summary_get_saved_count (s);
		}
		g_object_unref (s);
		g_free (folderpath);

		g_free (path);
	}

	if (camel_local_store_is_main_store (local_store) && fi->full_name
	    && (fi->flags & CAMEL_FOLDER_TYPE_MASK) == CAMEL_FOLDER_TYPE_NORMAL)
		fi->flags =
			(fi->flags & ~CAMEL_FOLDER_TYPE_MASK) |
			camel_local_store_get_folder_type_by_full_name (
				local_store, fi->full_name);
}

static CamelFolderInfo *
folder_info_new (CamelStore *store,
                 const gchar *root,
                 const gchar *path,
                 guint32 flags,
                 GCancellable *cancellable)
{
	/* FIXME Need to set fi->flags = CAMEL_FOLDER_NOSELECT
	 *       (and possibly others) when appropriate. */
	CamelFolderInfo *fi;
	gchar *base;

	base = strrchr (path, '/');

	/* Build the folder info structure. */
	fi = camel_folder_info_new ();
	fi->full_name = g_strdup (path);
	fi->display_name = g_strdup (base ? base + 1 : path);
	fill_fi (store, fi, flags, cancellable);

	return fi;
}

/* used to find out where we've visited already */
struct _inode {
	dev_t dnode;
	ino_t inode;
};

/* Scan path, under root, for directories to add folders for.  Both
 * root and path should have a trailing "/" if they aren't empty. */
static void
recursive_scan (CamelStore *store,
                CamelFolderInfo **fip,
                CamelFolderInfo *parent,
                GHashTable *visited,
                const gchar *root,
                const gchar *path,
                guint32 flags,
                GCancellable *cancellable)
{
	gchar *fullpath, *tmp;
	gsize fullpath_len;
	DIR *dp;
	struct dirent *d;
	struct stat st;
	CamelFolderInfo *fi;
	struct _inode in, *inew;

	/* Open the specified directory. */
	if (path[0]) {
		fullpath_len = strlen (root) + strlen (path) + 2;
		fullpath = alloca (fullpath_len);
		g_snprintf (fullpath, fullpath_len, "%s/%s", root, path);
	} else
		fullpath = (gchar *) root;

	if (g_stat (fullpath, &st) == -1 || !S_ISDIR (st.st_mode))
		return;

	in.dnode = st.st_dev;
	in.inode = st.st_ino;

	/* see if we've visited already */
	if (g_hash_table_lookup (visited, &in) != NULL)
		return;

	inew = g_malloc (sizeof (*inew));
	*inew = in;
	g_hash_table_insert (visited, inew, inew);

	/* link in ... */
	fi = folder_info_new (store, root, path, flags, cancellable);
	fi->parent = parent;
	fi->next = *fip;
	*fip = fi;

	if (((flags & CAMEL_STORE_FOLDER_INFO_RECURSIVE) || parent == NULL)) {
		/* now check content for possible other directories */
		dp = opendir (fullpath);
		if (dp == NULL)
			return;

		/* Look for subdirectories to add and scan. */
		while ((d = readdir (dp)) != NULL) {
			/* Skip current and parent directory. */
			if (strcmp (d->d_name, ".") == 0
			    || strcmp (d->d_name, "..") == 0)
				continue;

			/* skip fully-numerical entries (i.e. mh messages) */
			strtoul (d->d_name, &tmp, 10);
			if (*tmp == 0)
				continue;

			/* Otherwise, treat at potential node, and recurse,
			 * a bit more expensive than needed, but tough! */
			if (path[0]) {
				tmp = g_strdup_printf ("%s/%s", path, d->d_name);
				recursive_scan (
					store, &fi->child, fi, visited,
					root, tmp, flags, cancellable);
				g_free (tmp);
			} else {
				recursive_scan (
					store, &fi->child, fi, visited,
					root, d->d_name, flags, cancellable);
			}
		}

		closedir (dp);
	}
}

/* scan a .folders file */
static void
folders_scan (CamelStore *store,
              const gchar *root,
              const gchar *top,
              CamelFolderInfo **fip,
              guint32 flags,
              GCancellable *cancellable)
{
	CamelFolderInfo *fi;
	gchar  line[512], *path, *tmp;
	gsize tmp_len;
	CamelStream *stream, *in;
	struct stat st;
	GPtrArray *folders;
	GHashTable *visited;
	gint len;

	tmp_len = strlen (root) + 16;
	tmp = g_alloca (tmp_len);
	g_snprintf (tmp, tmp_len, "%s/.folders", root);
	stream = camel_stream_fs_new_with_name (tmp, 0, O_RDONLY, NULL);
	if (stream == NULL)
		return;

	in = camel_stream_buffer_new (stream, CAMEL_STREAM_BUFFER_READ);
	g_object_unref (stream);
	if (in == NULL)
		return;

	visited = g_hash_table_new (g_str_hash, g_str_equal);
	folders = g_ptr_array_new ();

	while ((len = camel_stream_buffer_gets (
		(CamelStreamBuffer *) in, line,
		sizeof (line), cancellable, NULL)) > 0) {

		/* ignore blank lines */
		if (len <= 1)
			continue;

		/* Check for invalidly long lines,
		 * we abort everything and fallback. */
		if (line[len - 1] != '\n') {
			gint i;

			for (i = 0; i < folders->len; i++)
				camel_folder_info_free (folders->pdata[i]);
			g_ptr_array_set_size (folders, 0);
			break;
		}
		line[len - 1] = 0;

		/* check for \r ? */

		if (top && top[0]) {
			gint toplen = strlen (top);

			/* check is dir or subdir */
			if (strncmp (top, line, toplen) != 0
			    || (line[toplen] != 0 && line[toplen] != '/'))
				continue;

			/* check is not sub-subdir if not recursive */
			if ((flags & CAMEL_STORE_FOLDER_INFO_RECURSIVE) == 0
			    && (tmp = strrchr (line, '/'))
			    && tmp > line + toplen)
				continue;
		}

		if (g_hash_table_lookup (visited, line) != NULL)
			continue;

		tmp = g_strdup (line);
		g_hash_table_insert (visited, tmp, tmp);

		path = g_strdup_printf ("%s/%s", root, line);
		if (g_stat (path, &st) == 0 && S_ISDIR (st.st_mode)) {
			fi = folder_info_new (
				store, root, line, flags, cancellable);
			g_ptr_array_add (folders, fi);
		}
		g_free (path);
	}

	if (folders->len)
		*fip = camel_folder_info_build(folders, top, '/', TRUE);
	g_ptr_array_free (folders, TRUE);

	g_hash_table_foreach (visited, (GHFunc) g_free, NULL);
	g_hash_table_destroy (visited);

	g_object_unref (in);
}

/* FIXME: move to camel-local, this is shared with maildir code */
static guint
inode_hash (gconstpointer d)
{
	const struct _inode *v = d;

	return v->inode ^ v->dnode;
}

static gboolean
inode_equal (gconstpointer a,
             gconstpointer b)
{
	const struct _inode *v1 = a, *v2 = b;

	return v1->inode == v2->inode && v1->dnode == v2->dnode;
}

static void
inode_free (gpointer k,
            gpointer v,
            gpointer d)
{
	g_free (k);
}

static CamelFolder *
mh_store_get_folder_sync (CamelStore *store,
                          const gchar *folder_name,
                          CamelStoreGetFolderFlags flags,
                          GCancellable *cancellable,
                          GError **error)
{
	CamelStoreClass *store_class;
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	CamelFolder *folder = NULL;
	gboolean use_dot_folders;
	struct stat st;
	gchar *name;
	gchar *path;

	/* Chain up to parent's get_folder() method. */
	store_class = CAMEL_STORE_CLASS (camel_mh_store_parent_class);
	if (store_class->get_folder_sync (
		store, folder_name, flags, cancellable, error) == NULL)
		return NULL;

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	use_dot_folders = camel_mh_settings_get_use_dot_folders (
		CAMEL_MH_SETTINGS (settings));

	g_object_unref (settings);

	name = g_build_filename (path, folder_name, NULL);

	if (g_stat (name, &st) == -1) {
		if (errno != ENOENT) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Cannot get folder “%s”: %s"),
				folder_name, g_strerror (errno));
			goto exit;
		}

		if ((flags & CAMEL_STORE_FOLDER_CREATE) == 0) {
			g_set_error (
				error, CAMEL_STORE_ERROR,
				CAMEL_STORE_ERROR_NO_FOLDER,
				_("Cannot get folder “%s”: "
				"folder does not exist."),
				folder_name);
			goto exit;
		}

		if (g_mkdir (name, 0777) != 0) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Could not create folder “%s”: %s"),
				folder_name, g_strerror (errno));
			goto exit;
		}

		/* add to .folders if we are supposed to */
		/* FIXME: throw exception on error */
		if (use_dot_folders)
			folders_update (
				path, UPDATE_ADD, folder_name,
				NULL, cancellable);

	} else if (!S_ISDIR (st.st_mode)) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Cannot get folder “%s”: not a directory."),
			folder_name);
		goto exit;
	}

	folder = camel_mh_folder_new (
		store, folder_name, flags, cancellable, error);

exit:
	g_free (name);
	g_free (path);

	return folder;
}

static CamelFolderInfo *
mh_store_get_folder_info_sync (CamelStore *store,
                               const gchar *top,
                               CamelStoreGetFolderInfoFlags flags,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelLocalSettings *local_settings;
	CamelService *service;
	CamelSettings *settings;
	CamelFolderInfo *fi = NULL;
	gboolean use_dot_folders;
	gchar *path;

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	use_dot_folders = camel_mh_settings_get_use_dot_folders (
		CAMEL_MH_SETTINGS (settings));

	g_object_unref (settings);

	/* use .folders if we are supposed to */
	if (use_dot_folders) {
		folders_scan (
			store, path, top, &fi, flags, cancellable);
	} else {
		GHashTable *visited;

		visited = g_hash_table_new (inode_hash, inode_equal);

		if (top == NULL)
			top = "";

		recursive_scan (
			store, &fi, NULL, visited,
			path, top, flags, cancellable);

		/* If we actually scanned from root,
		 * we have a "" root node we dont want. */
		if (fi != NULL && top[0] == 0) {
			CamelFolderInfo *rfi;

			rfi = fi;
			fi = rfi->child;
			rfi->child = NULL;
			camel_folder_info_free (rfi);
		}

		g_hash_table_foreach (visited, inode_free, NULL);
		g_hash_table_destroy (visited);
	}

	g_free (path);

	return fi;
}

static CamelFolder *
mh_store_get_inbox_sync (CamelStore *store,
                         GCancellable *cancellable,
                         GError **error)
{
	return mh_store_get_folder_sync (
		store, "inbox", 0, cancellable, error);
}

static gboolean
mh_store_delete_folder_sync (CamelStore *store,
                             const gchar *folder_name,
                             GCancellable *cancellable,
                             GError **error)
{
	CamelStoreClass *store_class;
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	gboolean use_dot_folders;
	gchar *name;
	gchar *path;

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	use_dot_folders = camel_mh_settings_get_use_dot_folders (
		CAMEL_MH_SETTINGS (settings));

	g_object_unref (settings);

	/* remove folder directory - will fail if not empty */
	name = g_build_filename (path, folder_name, NULL);
	if (rmdir (name) == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not delete folder “%s”: %s"),
			folder_name, g_strerror (errno));
		g_free (name);
		g_free (path);
		return FALSE;
	}
	g_free (name);

	/* remove from .folders if we are supposed to */
	if (use_dot_folders)
		folders_update (
			path, UPDATE_REMOVE, folder_name,
			NULL, cancellable);

	g_free (path);

	/* Chain up to parent's delete_folder() method. */
	store_class = CAMEL_STORE_CLASS (camel_mh_store_parent_class);
	return store_class->delete_folder_sync (
		store, folder_name, cancellable, error);
}

static gboolean
mh_store_rename_folder_sync (CamelStore *store,
                             const gchar *old,
                             const gchar *new,
                             GCancellable *cancellable,
                             GError **error)
{
	CamelStoreClass *store_class;
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	gboolean use_dot_folders;
	gboolean success;
	gchar *path;

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	use_dot_folders = camel_mh_settings_get_use_dot_folders (
		CAMEL_MH_SETTINGS (settings));

	g_object_unref (settings);

	/* Chain up to parent's rename_folder() method. */
	store_class = CAMEL_STORE_CLASS (camel_mh_store_parent_class);
	success = store_class->rename_folder_sync (
		store, old, new, cancellable, error);

	if (success && use_dot_folders) {
		/* yeah this is messy, but so is mh! */
		folders_update (
			path, UPDATE_RENAME, old, new, cancellable);
	}

	g_free (path);

	return success;
}

static void
camel_mh_store_class_init (CamelMhStoreClass *class)
{
	CamelServiceClass *service_class;
	CamelStoreClass *store_class;

	service_class = CAMEL_SERVICE_CLASS (class);
	service_class->settings_type = CAMEL_TYPE_MH_SETTINGS;

	store_class = CAMEL_STORE_CLASS (class);
	store_class->get_folder_sync = mh_store_get_folder_sync;
	store_class->get_folder_info_sync = mh_store_get_folder_info_sync;
	store_class->get_inbox_folder_sync = mh_store_get_inbox_sync;
	store_class->delete_folder_sync = mh_store_delete_folder_sync;
	store_class->rename_folder_sync = mh_store_rename_folder_sync;
}

static void
camel_mh_store_init (CamelMhStore *mh_store)
{
}

