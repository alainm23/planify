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
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include "camel-mbox-folder.h"
#include "camel-mbox-store.h"

#define d(x)

G_DEFINE_TYPE (CamelMboxStore, camel_mbox_store, CAMEL_TYPE_LOCAL_STORE)

static const gchar *extensions[] = {
	".msf",
	".ev-summary",
	".ev-summary-meta",
	".ibex.index",
	".ibex.index.data",
	".cmeta",
	".lock",
	".db",
	".journal"
};

/* used to find out where we've visited already */
struct _inode {
	dev_t dnode;
	ino_t inode;
};

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

static gboolean
ignore_file (const gchar *filename,
             gboolean sbd)
{
	gint flen, len, i;

	/* TODO: Should probably just be 1 regex */
	flen = strlen (filename);
	if (flen > 0 && filename[flen - 1] == '~')
		return TRUE;

	for (i = 0; i < G_N_ELEMENTS (extensions); i++) {
		len = strlen (extensions[i]);
		if (len < flen && !strcmp (filename + flen - len, extensions[i]))
			return TRUE;
	}

	if (sbd && flen > 4 && !strcmp (filename + flen - 4, ".sbd"))
		return TRUE;

	return FALSE;
}

/* NB: duplicated in maildir store */
static void
fill_fi (CamelStore *store,
         CamelFolderInfo *fi,
         guint32 flags)
{
	CamelFolder *folder;

	fi->unread = -1;
	fi->total = -1;
	folder = camel_object_bag_peek (camel_store_get_folders_bag (store), fi->full_name);
	if (folder) {
		if ((flags & CAMEL_STORE_FOLDER_INFO_FAST) == 0)
			camel_folder_refresh_info_sync (folder, NULL, NULL);
		fi->unread = camel_folder_get_unread_message_count (folder);
		fi->total = camel_folder_get_message_count (folder);
		g_object_unref (folder);
	} else {
		CamelLocalStore *local_store;
		gchar *folderpath;
		CamelMboxSummary *mbs;

		local_store = CAMEL_LOCAL_STORE (store);

		/* This should be fast enough not
		 * to have to test for INFO_FAST. */
		folderpath = camel_local_store_get_full_path (
			local_store, fi->full_name);

		mbs = (CamelMboxSummary *) camel_mbox_summary_new (
			NULL, folderpath, NULL);
		/* FIXME[disk-summary] track exception */
		if (camel_folder_summary_header_load ((CamelFolderSummary *) mbs, store, fi->full_name, NULL)) {
			fi->unread = camel_folder_summary_get_unread_count (
				(CamelFolderSummary *) mbs);
			fi->total = camel_folder_summary_get_saved_count (
				(CamelFolderSummary *) mbs);
		}

		g_object_unref (mbs);
		g_free (folderpath);
	}

	if (camel_local_store_is_main_store (CAMEL_LOCAL_STORE (store)) && fi->full_name
	    && (fi->flags & CAMEL_FOLDER_TYPE_MASK) == CAMEL_FOLDER_TYPE_NORMAL)
		fi->flags =
			(fi->flags & ~CAMEL_FOLDER_TYPE_MASK) |
			camel_local_store_get_folder_type_by_full_name (
			CAMEL_LOCAL_STORE (store), fi->full_name);
}

static CamelFolderInfo *
scan_dir (CamelStore *store,
          GHashTable *visited,
          CamelFolderInfo *parent,
          const gchar *root,
          const gchar *name,
          guint32 flags,
          GError **error)
{
	CamelFolderInfo *folders, *tail, *fi;
	GHashTable *folder_hash;
	const gchar *dent;
	GDir *dir;

	tail = folders = NULL;

	if (!(dir = g_dir_open (root, 0, NULL)))
		return NULL;

	folder_hash = g_hash_table_new (g_str_hash, g_str_equal);

	/* FIXME: it would be better if we queue'd up the recursive
	 * scans till the end so that we can limit the number of
	 * directory descriptors open at any given time... */

	while ((dent = g_dir_read_name (dir))) {
		gchar *short_name, *full_name, *path, *ext;
		struct stat st;

		if (dent[0] == '.')
			continue;

		if (ignore_file (dent, FALSE))
			continue;

		path = g_strdup_printf ("%s/%s", root, dent);
		if (g_stat (path, &st) == -1) {
			g_free (path);
			continue;
		}
#ifndef G_OS_WIN32
		if (S_ISDIR (st.st_mode)) {
			struct _inode in = { st.st_dev, st.st_ino };

			if (g_hash_table_lookup (visited, &in)) {
				g_free (path);
				continue;
			}
		}
#endif
		short_name = g_strdup (dent);
		if ((ext = strrchr (short_name, '.')) && !strcmp (ext, ".sbd"))
			*ext = '\0';

		if (name != NULL)
			full_name = g_strdup_printf ("%s/%s", name, short_name);
		else
			full_name = g_strdup (short_name);

		if ((fi = g_hash_table_lookup (folder_hash, short_name)) != NULL) {
			g_free (short_name);
			g_free (full_name);

			if (S_ISDIR (st.st_mode)) {
				fi->flags = (fi->flags & ~CAMEL_FOLDER_NOCHILDREN) | CAMEL_FOLDER_CHILDREN;
			} else {
				fi->flags &= ~CAMEL_FOLDER_NOSELECT;
			}
		} else {
			fi = camel_folder_info_new ();
			fi->parent = parent;

			fi->full_name = full_name;
			fi->display_name = short_name;
			fi->unread = -1;
			fi->total = -1;

			if (S_ISDIR (st.st_mode))
				fi->flags = CAMEL_FOLDER_NOSELECT;
			else
				fi->flags = CAMEL_FOLDER_NOCHILDREN;

			if (tail == NULL)
				folders = fi;
			else
				tail->next = fi;

			tail = fi;

			g_hash_table_insert (folder_hash, fi->display_name, fi);
		}

		if (!S_ISDIR (st.st_mode)) {
			fill_fi (store, fi, flags);
		} else if ((flags & CAMEL_STORE_FOLDER_INFO_RECURSIVE)) {
			struct _inode in = { st.st_dev, st.st_ino };

			if (g_hash_table_lookup (visited, &in) == NULL) {
#ifndef G_OS_WIN32
				struct _inode *inew = g_new (struct _inode, 1);

				*inew = in;
				g_hash_table_insert (visited, inew, inew);
#endif
				if ((fi->child = scan_dir (store, visited, fi, path, fi->full_name, flags, error)))
					fi->flags |= CAMEL_FOLDER_CHILDREN;
				else
					fi->flags = (fi->flags & ~CAMEL_FOLDER_CHILDREN) | CAMEL_FOLDER_NOCHILDREN;
			}
		}

		g_free (path);
	}

	g_dir_close (dir);

	g_hash_table_destroy (folder_hash);

	return folders;
}

static gint
xrename (CamelStore *store,
         const gchar *old_name,
         const gchar *new_name,
         const gchar *ext,
         gboolean missingok)
{
	CamelLocalStore *ls = (CamelLocalStore *) store;
	gchar *oldpath, *newpath;
	struct stat st;
	gint ret = -1;

	if (ext != NULL) {
		oldpath = camel_local_store_get_meta_path (ls, old_name, ext);
		newpath = camel_local_store_get_meta_path (ls, new_name, ext);
	} else {
		oldpath = camel_local_store_get_full_path (ls, old_name);
		newpath = camel_local_store_get_full_path (ls, new_name);
	}

	if (g_stat (oldpath, &st) == -1) {
		if (missingok && errno == ENOENT) {
			ret = 0;
		} else {
			ret = -1;
		}
#ifndef G_OS_WIN32
	} else if (S_ISDIR (st.st_mode)) {
		/* use rename for dirs */
		if (g_rename (oldpath, newpath) == 0 || g_stat (newpath, &st) == 0) {
			ret = 0;
		} else {
			ret = -1;
		}
	} else if (link (oldpath, newpath) == 0 /* and link for files */
		   ||(g_stat (newpath, &st) == 0 && st.st_nlink == 2)) {
		if (unlink (oldpath) == 0) {
			ret = 0;
		} else {
			unlink (newpath);
			ret = -1;
		}
	} else {
		ret = -1;
#else
	} else if ((!g_file_test (newpath, G_FILE_TEST_EXISTS) || g_remove (newpath) == 0) &&
		   g_rename (oldpath, newpath) == 0) {
		ret = 0;
	} else {
		ret = -1;
#endif
	}

	g_free (oldpath);
	g_free (newpath);

	return ret;
}

static CamelFolder *
mbox_store_get_folder_sync (CamelStore *store,
                            const gchar *folder_name,
                            CamelStoreGetFolderFlags flags,
                            GCancellable *cancellable,
                            GError **error)
{
	CamelStoreClass *store_class;
	CamelLocalStore *local_store;
	struct stat st;
	gchar *name;

	/* Chain up to parent's get_folder_sync() method. */
	store_class = CAMEL_STORE_CLASS (camel_mbox_store_parent_class);
	if (!store_class->get_folder_sync (store, folder_name, flags, cancellable, error))
		return NULL;

	local_store = CAMEL_LOCAL_STORE (store);
	name = camel_local_store_get_full_path (local_store, folder_name);

	if (g_stat (name, &st) == -1) {
		gchar *basename;
		gchar *dirname;
		gint fd;

		if (errno != ENOENT) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Cannot get folder “%s”: %s"),
				folder_name, g_strerror (errno));
			g_free (name);
			return NULL;
		}

		if ((flags & CAMEL_STORE_FOLDER_CREATE) == 0) {
			g_set_error (
				error, CAMEL_STORE_ERROR,
				CAMEL_STORE_ERROR_NO_FOLDER,
				_("Cannot get folder “%s”: folder does not exist."),
				folder_name);
			g_free (name);
			return NULL;
		}

		/* sanity check the folder name */
		basename = g_path_get_basename (folder_name);

		if (basename[0] == '.' || ignore_file (basename, TRUE)) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Cannot create a folder by this name."));
			g_free (name);
			g_free (basename);
			return NULL;
		}
		g_free (basename);

		dirname = g_path_get_dirname (name);
		if (g_mkdir_with_parents (dirname, 0700) == -1 && errno != EEXIST) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Cannot create folder “%s”: %s"),
				folder_name, g_strerror (errno));
			g_free (dirname);
			g_free (name);
			return NULL;
		}

		g_free (dirname);

		fd = g_open (
			name,
			O_LARGEFILE |
			O_WRONLY |
			O_CREAT |
			O_APPEND |
			O_BINARY, 0666);

		if (fd == -1) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Cannot create folder “%s”: %s"),
				folder_name, g_strerror (errno));
			g_free (name);
			return NULL;
		}

		g_free (name);
		close (fd);
	} else if (!S_ISREG (st.st_mode)) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot get folder “%s”: not a regular file."),
			folder_name);
		g_free (name);
		return NULL;
	} else
		g_free (name);

	return camel_mbox_folder_new (store, folder_name, flags, cancellable, error);
}

static CamelFolderInfo *
mbox_store_get_folder_info_sync (CamelStore *store,
                                 const gchar *top,
                                 CamelStoreGetFolderInfoFlags flags,
                                 GCancellable *cancellable,
                                 GError **error)
{
	CamelLocalStore *local_store;
	GHashTable *visited;
#ifndef G_OS_WIN32
	struct _inode *inode;
#endif
	gchar *path, *subdir;
	CamelFolderInfo *fi;
	gchar *basename;
	struct stat st;

	if (top == NULL)
		top = "";

	local_store = CAMEL_LOCAL_STORE (store);
	path = camel_local_store_get_full_path (local_store, top);

	if (*top == '\0') {
		/* requesting root dir scan */
		if (g_stat (path, &st) == -1 || !S_ISDIR (st.st_mode)) {
			g_free (path);
			return NULL;
		}

		visited = g_hash_table_new (inode_hash, inode_equal);
#ifndef G_OS_WIN32
		inode = g_malloc0 (sizeof (*inode));
		inode->dnode = st.st_dev;
		inode->inode = st.st_ino;

		g_hash_table_insert (visited, inode, inode);
#endif
		fi = scan_dir (store, visited, NULL, path, NULL, flags, error);
		g_hash_table_foreach (visited, inode_free, NULL);
		g_hash_table_destroy (visited);
		g_free (path);

		return fi;
	}

	/* requesting scan of specific folder */
	if (g_stat (path, &st) == -1 || !S_ISREG (st.st_mode)) {
		gchar *test_if_subdir = g_strdup_printf ("%s.sbd", path);

		if (g_stat (test_if_subdir, &st) == -1) {
			g_free (path);
			g_free (test_if_subdir);
			return NULL;
		}
		g_free (test_if_subdir);
	}

	visited = g_hash_table_new (inode_hash, inode_equal);

	basename = g_path_get_basename (top);

	fi = camel_folder_info_new ();
	fi->parent = NULL;
	fi->full_name = g_strdup (top);
	fi->display_name = basename;
	fi->unread = -1;
	fi->total = -1;

	fill_fi (store, fi, flags);

	subdir = g_strdup_printf ("%s.sbd", path);
	if (g_stat (subdir, &st) == 0) {
		if  (S_ISDIR (st.st_mode))
			fi->child = scan_dir (store, visited, fi, subdir, top, flags, error);
	}

	if (fi->child)
		fi->flags |= CAMEL_FOLDER_CHILDREN;
	else
		fi->flags |= CAMEL_FOLDER_NOCHILDREN;

	g_free (subdir);

	g_hash_table_foreach (visited, inode_free, NULL);
	g_hash_table_destroy (visited);
	g_free (path);

	return fi;
}

static CamelFolderInfo *
mbox_store_create_folder_sync (CamelStore *store,
                               const gchar *parent_name,
                               const gchar *folder_name,
                               GCancellable *cancellable,
                               GError **error)
{
	/* FIXME This is almost an exact copy of
	 *       CamelLocalStore::create_folder() except that we use
	 *       different path schemes - need to find a way to share
	 *       parent's code? */
	CamelLocalSettings *local_settings;
	CamelLocalStore *local_store;
	CamelFolderInfo *info = NULL;
	CamelSettings *settings;
	CamelService *service;
	gchar *root_path = NULL;
	gchar *name = NULL;
	gchar *path = NULL;
	gchar *dir;
	CamelFolder *folder;
	struct stat st;

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	root_path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	local_store = CAMEL_LOCAL_STORE (store);

	if (!g_path_is_absolute (root_path)) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Store root %s is not an absolute path"),
			root_path);
		goto exit;
	}

	if (folder_name[0] == '.' || ignore_file (folder_name, TRUE)) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot create a folder by this name."));
		goto exit;
	}

	if (parent_name && *parent_name)
		name = g_strdup_printf ("%s/%s", parent_name, folder_name);
	else
		name = g_strdup (folder_name);

	path = camel_local_store_get_full_path (local_store, name);

	dir = g_path_get_dirname (path);
	if (g_mkdir_with_parents (dir, 0777) == -1 && errno != EEXIST) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Cannot create directory “%s”: %s."),
			dir, g_strerror (errno));
		g_free (dir);
		goto exit;
	}

	g_free (dir);

	if (g_stat (path, &st) == 0 || errno != ENOENT) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Cannot create folder: %s: %s"),
			path, errno ? g_strerror (errno) :
			_("Folder already exists"));
		goto exit;
	}

	folder = CAMEL_STORE_GET_CLASS (store)->get_folder_sync (
		store, name, CAMEL_STORE_FOLDER_CREATE, cancellable, error);
	if (folder) {
		g_object_unref (folder);
		info = CAMEL_STORE_GET_CLASS (store)->get_folder_info_sync (
			store, name, 0, cancellable, error);
	}

exit:
	g_free (root_path);
	g_free (name);
	g_free (path);

	return info;
}

static gboolean
mbox_store_delete_folder_sync (CamelStore *store,
                               const gchar *folder_name,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelLocalStore *local_store;
	CamelFolderInfo *fi;
	CamelFolder *lf;
	gchar *name, *path;
	struct stat st;

	local_store = CAMEL_LOCAL_STORE (store);
	name = camel_local_store_get_full_path (local_store, folder_name);
	path = g_strdup_printf ("%s.sbd", name);

	if (g_rmdir (path) == -1 && errno != ENOENT) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not delete folder “%s”:\n%s"),
			folder_name, g_strerror (errno));
		g_free (path);
		g_free (name);
		return FALSE;
	}

	g_free (path);

	if (g_stat (name, &st) == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not delete folder “%s”:\n%s"),
			folder_name, g_strerror (errno));
		g_free (name);
		return FALSE;
	}

	if (!S_ISREG (st.st_mode)) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("“%s” is not a regular file."), name);
		g_free (name);
		return FALSE;
	}

	if (st.st_size != 0) {
		g_set_error (
			error, CAMEL_FOLDER_ERROR,
			CAMEL_FOLDER_ERROR_NON_EMPTY,
			_("Folder “%s” is not empty. Not deleted."),
			folder_name);
		g_free (name);
		return FALSE;
	}

	if (g_unlink (name) == -1 && errno != ENOENT) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not delete folder “%s”:\n%s"),
			name, g_strerror (errno));
		g_free (name);
		return FALSE;
	}

	/* FIXME: we have to do our own meta cleanup here rather than
	 * calling our parent class' delete_folder() method since our
	 * naming convention is different. Need to find a way for
	 * CamelLocalStore to be able to construct the folder & meta
	 * paths itself */
	path = camel_local_store_get_meta_path (
		local_store, folder_name, ".ev-summary");
	if (g_unlink (path) == -1 && errno != ENOENT) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not delete folder summary file “%s”: %s"),
			path, g_strerror (errno));
		g_free (path);
		g_free (name);
		return FALSE;
	}

	g_free (path);

	path = camel_local_store_get_meta_path (
		local_store, folder_name, ".ev-summary-meta");
	if (g_unlink (path) == -1 && errno != ENOENT) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not delete folder summary file “%s”: %s"),
			path, g_strerror (errno));
		g_free (path);
		g_free (name);
		return FALSE;
	}

	g_free (path);

	path = camel_local_store_get_meta_path (
		local_store, folder_name, ".ibex");
	if (camel_text_index_remove (path) == -1 && errno != ENOENT) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not delete folder index file “%s”: %s"),
			path, g_strerror (errno));
		g_free (path);
		g_free (name);
		return FALSE;
	}

	g_free (path);

	path = NULL;
	if ((lf = camel_store_get_folder_sync (store, folder_name, 0, cancellable, NULL))) {
		CamelObject *object = CAMEL_OBJECT (lf);
		const gchar *state_filename;

		state_filename = camel_object_get_state_filename (object);
		path = g_strdup (state_filename);

		camel_object_set_state_filename (object, NULL);

		g_object_unref (lf);
	}

	if (path == NULL)
		path = camel_local_store_get_meta_path (
			local_store, folder_name, ".cmeta");

	if (g_unlink (path) == -1 && errno != ENOENT) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not delete folder meta file “%s”: %s"),
			path, g_strerror (errno));

		g_free (path);
		g_free (name);
		return FALSE;
	}

	g_free (path);
	g_free (name);

	fi = camel_folder_info_new ();
	fi->full_name = g_strdup (folder_name);
	fi->display_name = g_path_get_basename (folder_name);
	fi->unread = -1;

	camel_store_folder_deleted (store, fi);
	camel_folder_info_free (fi);

	return TRUE;
}

static gboolean
mbox_store_rename_folder_sync (CamelStore *store,
                               const gchar *old,
                               const gchar *new,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelLocalStore *local_store;
	CamelLocalFolder *folder = NULL;
	gchar *oldibex, *newibex, *newdir;
	gint errnosav;

	if (new[0] == '.' || ignore_file (new, TRUE)) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("The new folder name is illegal."));
		return FALSE;
	}

	/* try to rollback failures, has obvious races */

	local_store = CAMEL_LOCAL_STORE (store);
	oldibex = camel_local_store_get_meta_path (local_store, old, ".ibex");
	newibex = camel_local_store_get_meta_path (local_store, new, ".ibex");

	newdir = g_path_get_dirname (newibex);
	if (g_mkdir_with_parents (newdir, 0700) == -1) {
		if (errno != EEXIST) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Could not rename “%s”: “%s”: %s"),
				old, new, g_strerror (errno));
			g_free (oldibex);
			g_free (newibex);
			g_free (newdir);

			return FALSE;
		}

		g_free (newdir);
		newdir = NULL;
	}

	folder = camel_object_bag_get (camel_store_get_folders_bag (store), old);
	if (folder && folder->index) {
		if (camel_index_rename (folder->index, newibex) == -1 && errno != ENOENT) {
			errnosav = errno;
			goto ibex_failed;
		}
	} else {
		/* TODO camel_text_index_rename should find out
		 *      if we have an active index itself? */
		if (camel_text_index_rename (oldibex, newibex) == -1 && errno != ENOENT) {
			errnosav = errno;
			goto ibex_failed;
		}
	}

	if (xrename (store, old, new, ".ev-summary", TRUE) == -1) {
		errnosav = errno;
		goto summary_failed;
	}

	if (xrename (store, old, new, ".ev-summary-meta", TRUE) == -1) {
		errnosav = errno;
		goto summary_failed;
	}

	if (xrename (store, old, new, ".cmeta", TRUE) == -1) {
		errnosav = errno;
		goto cmeta_failed;
	}

	if (xrename (store, old, new, ".sbd", TRUE) == -1) {
		errnosav = errno;
		goto subdir_failed;
	}

	if (xrename (store, old, new, NULL, FALSE) == -1) {
		errnosav = errno;
		goto base_failed;
	}

	g_free (oldibex);
	g_free (newibex);

	if (folder)
		g_object_unref (folder);

	return TRUE;

base_failed:
	xrename (store, new, old, ".sbd", TRUE);
subdir_failed:
	xrename (store, new, old, ".cmeta", TRUE);
cmeta_failed:
	xrename (store, new, old, ".ev-summary", TRUE);
	xrename (store, new, old, ".ev-summary-meta", TRUE);
summary_failed:
	if (folder) {
		if (folder->index)
			camel_index_rename (folder->index, oldibex);
	} else
		camel_text_index_rename (newibex, oldibex);
ibex_failed:
	if (newdir) {
		/* newdir is only non-NULL if we needed to mkdir */
		g_rmdir (newdir);
		g_free (newdir);
	}

	g_set_error (
		error, G_IO_ERROR,
		g_io_error_from_errno (errnosav),
		_("Could not rename “%s” to %s: %s"),
		old, new, g_strerror (errnosav));

	g_free (newibex);
	g_free (oldibex);

	if (folder)
		g_object_unref (folder);

	return FALSE;
}

static gchar *
mbox_store_get_full_path (CamelLocalStore *ls,
                          const gchar *full_name)
{
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	GString *full_path;
	gchar *root_path;
	const gchar *cp;

	service = CAMEL_SERVICE (ls);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	root_path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	g_return_val_if_fail (root_path != NULL, NULL);

	full_path = g_string_new (root_path);

	/* Root path may or may not have a trailing separator. */
	if (!g_str_has_suffix (root_path, G_DIR_SEPARATOR_S))
		g_string_append_c (full_path, G_DIR_SEPARATOR);

	cp = full_name;
	while (*cp != '\0') {
		if (G_IS_DIR_SEPARATOR (*cp)) {
			g_string_append (full_path, ".sbd");
			g_string_append_c (full_path, *cp++);

			/* Skip extranaeous separators. */
			while (G_IS_DIR_SEPARATOR (*cp))
				cp++;
		} else {
			g_string_append_c (full_path, *cp++);
		}
	}

	g_free (root_path);

	return g_string_free (full_path, FALSE);
}

static gchar *
mbox_store_get_meta_path (CamelLocalStore *ls,
                          const gchar *full_name,
                          const gchar *ext)
{
/*#define USE_HIDDEN_META_FILES*/
#ifdef USE_HIDDEN_META_FILES
	gchar *name, *slash;
	gsize name_len;

	name_len = strlen (full_name) + strlen (ext) + 2;
	name = g_alloca (name_len);
	if ((slash = strrchr (full_name, '/')))
		g_snprintf (
			name, name_len, "%.*s.%s%s",
			slash - full_name + 1,
			full_name, slash + 1, ext);
	else
		g_snprintf (name, name_len, ".%s%s", full_name, ext);

	return mbox_store_get_full_path (ls, name);
#else
	gchar *full_path, *path;

	full_path = mbox_store_get_full_path (ls, full_name);
	path = g_strdup_printf ("%s%s", full_path, ext);
	g_free (full_path);

	return path;
#endif
}

static void
camel_mbox_store_class_init (CamelMboxStoreClass *class)
{
	CamelStoreClass *store_class;
	CamelLocalStoreClass *local_store_class;

	store_class = CAMEL_STORE_CLASS (class);
	store_class->get_folder_sync = mbox_store_get_folder_sync;
	store_class->get_folder_info_sync = mbox_store_get_folder_info_sync;
	store_class->create_folder_sync = mbox_store_create_folder_sync;
	store_class->delete_folder_sync = mbox_store_delete_folder_sync;
	store_class->rename_folder_sync = mbox_store_rename_folder_sync;

	local_store_class = CAMEL_LOCAL_STORE_CLASS (class);
	local_store_class->get_full_path = mbox_store_get_full_path;
	local_store_class->get_meta_path = mbox_store_get_meta_path;
}

static void
camel_mbox_store_init (CamelMboxStore *mbox_store)
{
}

