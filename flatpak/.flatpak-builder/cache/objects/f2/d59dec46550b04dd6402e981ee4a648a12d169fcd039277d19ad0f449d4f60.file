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
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include "camel-spool-folder.h"
#include "camel-spool-settings.h"
#include "camel-spool-store.h"

#define CAMEL_SPOOL_STORE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SPOOL_STORE, CamelSpoolStorePrivate))

#define d(x)

typedef enum _camel_spool_store_t {
	CAMEL_SPOOL_STORE_INVALID,
	CAMEL_SPOOL_STORE_MBOX,	/* a single mbox */
	CAMEL_SPOOL_STORE_ELM	/* elm/pine/etc tree of mbox files in folders */
} camel_spool_store_t;

struct _CamelSpoolStorePrivate {
	gint placeholder;  /* for future expansion */
};

G_DEFINE_TYPE (
	CamelSpoolStore,
	camel_spool_store,
	CAMEL_TYPE_MBOX_STORE)

static camel_spool_store_t
spool_store_get_type (CamelSpoolStore *spool_store,
                      GError **error)
{
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	camel_spool_store_t type;
	struct stat st;
	gchar *path;

	service = CAMEL_SERVICE (spool_store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	/* Check the path for validity while we have the opportunity. */

	if (path == NULL || *path != '/') {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Store root %s is not an absolute path"),
			(path != NULL) ? path : "(null)");
		type = CAMEL_SPOOL_STORE_INVALID;

	} else if (g_stat (path, &st) == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Spool “%s” cannot be opened: %s"),
			path, g_strerror (errno));
		type = CAMEL_SPOOL_STORE_INVALID;

	} else if (S_ISREG (st.st_mode)) {
		type = CAMEL_SPOOL_STORE_MBOX;

	} else if (S_ISDIR (st.st_mode)) {
		type = CAMEL_SPOOL_STORE_ELM;

	} else {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Spool “%s” is not a regular file or directory"),
			path);
		type = CAMEL_SPOOL_STORE_INVALID;
	}

	g_free (path);

	return type;
}

/* partially copied from mbox */
static void
spool_fill_fi (CamelStore *store,
               CamelFolderInfo *fi,
               guint32 flags,
               GCancellable *cancellable)
{
	CamelFolder *folder;

	fi->unread = -1;
	fi->total = -1;
	folder = camel_object_bag_peek (camel_store_get_folders_bag (store), fi->full_name);
	if (folder) {
		if ((flags & CAMEL_STORE_FOLDER_INFO_FAST) == 0)
			camel_folder_refresh_info_sync (folder, cancellable, NULL);
		fi->unread = camel_folder_get_unread_message_count (folder);
		fi->total = camel_folder_get_message_count (folder);
		g_object_unref (folder);
	}
}

static CamelFolderInfo *
spool_new_fi (CamelStore *store,
              CamelFolderInfo *parent,
              CamelFolderInfo **fip,
              const gchar *full,
              guint32 flags)
{
	CamelFolderInfo *fi;
	const gchar *name;

	name = strrchr (full, '/');
	if (name)
		name++;
	else
		name = full;

	fi = camel_folder_info_new ();
	fi->full_name = g_strdup (full);
	fi->display_name = g_strdup (name);
	fi->unread = -1;
	fi->total = -1;
	fi->flags = flags;

	fi->parent = parent;
	fi->next = *fip;
	*fip = fi;

	return fi;
}

/* used to find out where we've visited already */
struct _inode {
	dev_t dnode;
	ino_t inode;
};

/* returns number of records found at or below this level */
static gint
scan_dir (CamelStore *store,
          GHashTable *visited,
          const gchar *root,
          const gchar *path,
          guint32 flags,
          CamelFolderInfo *parent,
          CamelFolderInfo **fip,
          GCancellable *cancellable,
          GError **error)
{
	DIR *dir;
	struct dirent *d;
	gchar *name, *tmp, *fname;
	gsize name_len;
	CamelFolderInfo *fi = NULL;
	struct stat st;
	CamelFolder *folder;
	gchar from[80];
	FILE *fp;

	d (printf ("checking dir '%s' part '%s' for mbox content\n", root, path));

	/* look for folders matching the right structure, recursively */
	if (path) {
		name_len = strlen (root) + strlen (path) + 2;
		name = alloca (name_len);
		g_snprintf (name, name_len, "%s/%s", root, path);
	} else
		name = (gchar *) root;  /* XXX casting away const */

	if (g_stat (name, &st) == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not scan folder “%s”: %s"),
			name, g_strerror (errno));
	} else if (S_ISREG (st.st_mode)) {
		/* incase we start scanning from a file.  messy duplication :-/ */
		if (path) {
			fi = spool_new_fi (
				store, parent, fip, path,
				CAMEL_FOLDER_NOINFERIORS |
				CAMEL_FOLDER_NOCHILDREN);
			spool_fill_fi (store, fi, flags, cancellable);
		}
		return 0;
	}

	dir = opendir (name);
	if (dir == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not scan folder “%s”: %s"),
			name, g_strerror (errno));
		return -1;
	}

	if (path != NULL) {
		fi = spool_new_fi (
			store, parent, fip, path,
			CAMEL_FOLDER_NOSELECT);
		fip = &fi->child;
		parent = fi;
	}

	while ((d = readdir (dir))) {
		if (strcmp (d->d_name, ".") == 0
		    || strcmp (d->d_name, "..") == 0)
			continue;

		tmp = g_strdup_printf ("%s/%s", name, d->d_name);
		if (g_stat (tmp, &st) == 0) {
			if (path)
				fname = g_strdup_printf (
					"%s/%s", path, d->d_name);
			else
				fname = g_strdup (d->d_name);

			if (S_ISREG (st.st_mode)) {
				gint isfolder = FALSE;

				/* first, see if we already have it open */
				folder = camel_object_bag_peek (camel_store_get_folders_bag (store), fname);
				if (folder == NULL) {
					fp = fopen (tmp, "r");
					if (fp != NULL) {
						isfolder = (st.st_size == 0
							    || (fgets (from, sizeof (from), fp) != NULL
								&& strncmp (from, "From ", 5) == 0));
						fclose (fp);
					}
				}

				if (folder != NULL || isfolder) {
					fi = spool_new_fi (
						store, parent, fip, fname,
						CAMEL_FOLDER_NOINFERIORS |
						CAMEL_FOLDER_NOCHILDREN);
					spool_fill_fi (
						store, fi, flags, cancellable);
				}
				if (folder)
					g_object_unref (folder);

			} else if (S_ISDIR (st.st_mode)) {
				struct _inode in = { st.st_dev, st.st_ino };

				/* see if we've visited already */
				if (g_hash_table_lookup (visited, &in) == NULL) {
					struct _inode *inew = g_malloc (sizeof (*inew));

					*inew = in;
					g_hash_table_insert (visited, inew, inew);

					if (scan_dir (store, visited, root, fname, flags, parent, fip, cancellable, error) == -1) {
						g_free (tmp);
						g_free (fname);
						closedir (dir);
						return -1;
					}
				}
			}
			g_free (fname);

		}
		g_free (tmp);
	}
	closedir (dir);

	return 0;
}

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

static CamelFolderInfo *
get_folder_info_elm (CamelStore *store,
                     const gchar *top,
                     guint32 flags,
                     GCancellable *cancellable,
                     GError **error)
{
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	CamelFolderInfo *fi = NULL;
	GHashTable *visited;
	gchar *path;

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	visited = g_hash_table_new (inode_hash, inode_equal);

	if (scan_dir (
		store, visited, path, top, flags,
		NULL, &fi, cancellable, error) == -1 && fi != NULL) {
		camel_folder_info_free (fi);
		fi = NULL;
	}

	g_hash_table_foreach (visited, inode_free, NULL);
	g_hash_table_destroy (visited);

	g_free (path);

	return fi;
}

static CamelFolderInfo *
get_folder_info_mbox (CamelStore *store,
                      const gchar *top,
                      guint32 flags,
                      GCancellable *cancellable,
                      GError **error)
{
	CamelFolderInfo *fi = NULL, *fip = NULL;

	if (top == NULL || strcmp (top, "INBOX") == 0) {
		fi = spool_new_fi (
			store, NULL, &fip, "INBOX",
			CAMEL_FOLDER_NOINFERIORS |
			CAMEL_FOLDER_NOCHILDREN |
			CAMEL_FOLDER_SYSTEM);
		g_free (fi->display_name);
		fi->display_name = g_strdup (_("Inbox"));
		spool_fill_fi (store, fi, flags, cancellable);
	}

	return fi;
}

static gchar *
spool_store_get_name (CamelService *service,
                      gboolean brief)
{
	CamelLocalSettings *local_settings;
	CamelSpoolStore *spool_store;
	CamelSettings *settings;
	gchar *name;
	gchar *path;

	spool_store = CAMEL_SPOOL_STORE (service);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	if (brief)
		return path;

	switch (spool_store_get_type (spool_store, NULL)) {
		case CAMEL_SPOOL_STORE_MBOX:
			name = g_strdup_printf (
				_("Spool mail file %s"), path);
			break;
		case CAMEL_SPOOL_STORE_ELM:
			name = g_strdup_printf (
				_("Spool folder tree %s"), path);
			break;
		default:
			name = g_strdup (_("Invalid spool"));
			break;
	}

	g_free (path);

	return name;
}

static CamelFolder *
spool_store_get_folder_sync (CamelStore *store,
                             const gchar *folder_name,
                             CamelStoreGetFolderFlags flags,
                             GCancellable *cancellable,
                             GError **error)
{
	CamelLocalSettings *local_settings;
	CamelSpoolStore *spool_store;
	CamelSettings *settings;
	CamelService *service;
	CamelFolder *folder = NULL;
	camel_spool_store_t type;
	struct stat st;
	gchar *name;
	gchar *path;

	d (printf ("opening folder %s on path %s\n", folder_name, path));

	spool_store = CAMEL_SPOOL_STORE (store);
	type = spool_store_get_type (spool_store, error);

	if (type == CAMEL_SPOOL_STORE_INVALID)
		return NULL;

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	/* we only support an 'INBOX' in mbox mode */
	if (type == CAMEL_SPOOL_STORE_MBOX) {
		if (strcmp (folder_name, "INBOX") != 0) {
			g_set_error (
				error, CAMEL_STORE_ERROR,
				CAMEL_STORE_ERROR_NO_FOLDER,
				_("Folder “%s/%s” does not exist."),
				path, folder_name);
		} else {
			folder = camel_spool_folder_new (
				store, folder_name, flags, cancellable, error);
		}
	} else {
		name = g_build_filename (path, folder_name, NULL);
		if (g_stat (name, &st) == -1) {
			if (errno != ENOENT) {
				g_set_error (
					error, G_IO_ERROR,
					g_io_error_from_errno (errno),
					_("Could not open folder “%s”:\n%s"),
					folder_name, g_strerror (errno));
			} else if ((flags & CAMEL_STORE_FOLDER_CREATE) == 0) {
				g_set_error (
					error, CAMEL_STORE_ERROR,
					CAMEL_STORE_ERROR_NO_FOLDER,
					_("Folder “%s” does not exist."),
					folder_name);
			} else {
				gint fd = creat (name, 0600);
				if (fd == -1) {
					g_set_error (
						error, G_IO_ERROR,
						g_io_error_from_errno (errno),
						_("Could not create folder “%s”:\n%s"),
						folder_name, g_strerror (errno));
				} else {
					close (fd);
					folder = camel_spool_folder_new (
						store, folder_name, flags,
						cancellable, error);
				}
			}
		} else if (!S_ISREG (st.st_mode)) {
			g_set_error (
				error, CAMEL_STORE_ERROR,
				CAMEL_STORE_ERROR_NO_FOLDER,
				_("“%s” is not a mailbox file."), name);
		} else {
			folder = camel_spool_folder_new (
				store, folder_name, flags, cancellable, error);
		}
		g_free (name);
	}

	g_free (path);

	return folder;
}

static CamelFolderInfo *
spool_store_get_folder_info_sync (CamelStore *store,
                                  const gchar *top,
                                  CamelStoreGetFolderInfoFlags flags,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelSpoolStore *spool_store;
	CamelFolderInfo *folder_info = NULL;

	spool_store = CAMEL_SPOOL_STORE (store);

	switch (spool_store_get_type (spool_store, error)) {
		case CAMEL_SPOOL_STORE_MBOX:
			folder_info = get_folder_info_mbox (
				store, top, flags, cancellable, error);
			break;

		case CAMEL_SPOOL_STORE_ELM:
			folder_info = get_folder_info_elm (
				store, top, flags, cancellable, error);
			break;

		default:
			break;
	}

	return folder_info;
}

static CamelFolder *
spool_store_get_inbox_folder_sync (CamelStore *store,
                                   GCancellable *cancellable,
                                   GError **error)
{
	CamelSpoolStore *spool_store;
	CamelFolder *folder = NULL;

	spool_store = CAMEL_SPOOL_STORE (store);

	switch (spool_store_get_type (spool_store, error)) {
		case CAMEL_SPOOL_STORE_MBOX:
			folder = spool_store_get_folder_sync (
				store, "INBOX", CAMEL_STORE_FOLDER_CREATE,
				cancellable, error);
			break;

		case CAMEL_SPOOL_STORE_ELM:
			g_set_error (
				error, CAMEL_STORE_ERROR,
				CAMEL_STORE_ERROR_NO_FOLDER,
				_("Store does not support an INBOX"));
			break;

		default:
			break;
	}

	return folder;
}

/* default implementation, only delete metadata */
static gboolean
spool_store_delete_folder_sync (CamelStore *store,
                                const gchar *folder_name,
                                GCancellable *cancellable,
                                GError **error)
{
	g_set_error (
		error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
		_("Spool folders cannot be deleted"));

	return FALSE;
}

/* default implementation, rename all */
static gboolean
spool_store_rename_folder_sync (CamelStore *store,
                                const gchar *old,
                                const gchar *new,
                                GCancellable *cancellable,
                                GError **error)
{
	g_set_error (
		error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
		_("Spool folders cannot be renamed"));

	return FALSE;
}

static gchar *
spool_store_get_full_path (CamelLocalStore *local_store,
                           const gchar *full_name)
{
	CamelLocalSettings *local_settings;
	CamelSpoolStore *spool_store;
	CamelSettings *settings;
	CamelService *service;
	gchar *full_path;
	gchar *path;

	service = CAMEL_SERVICE (local_store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	spool_store = CAMEL_SPOOL_STORE (local_store);

	switch (spool_store_get_type (spool_store, NULL)) {
		case CAMEL_SPOOL_STORE_MBOX:
			full_path = g_strdup (path);
			break;

		case CAMEL_SPOOL_STORE_ELM:
			full_path = g_build_filename (path, full_name, NULL);
			break;

		default:
			full_path = NULL;
			break;
	}

	g_free (path);

	return full_path;
}

static gchar *
spool_store_get_meta_path (CamelLocalStore *ls,
                           const gchar *full_name,
                           const gchar *ext)
{
	CamelService *service;
	const gchar *user_data_dir;
	gchar *path, *key;

	service = CAMEL_SERVICE (ls);
	user_data_dir = camel_service_get_user_data_dir (service);

	key = camel_file_util_safe_filename (full_name);
	path = g_strdup_printf ("%s/%s%s", user_data_dir, key, ext);
	g_free (key);

	return path;
}

static void
camel_spool_store_class_init (CamelSpoolStoreClass *class)
{
	CamelServiceClass *service_class;
	CamelStoreClass *store_class;
	CamelLocalStoreClass *local_store_class;

	g_type_class_add_private (class, sizeof (CamelSpoolStorePrivate));

	service_class = CAMEL_SERVICE_CLASS (class);
	service_class->settings_type = CAMEL_TYPE_SPOOL_SETTINGS;
	service_class->get_name = spool_store_get_name;

	store_class = CAMEL_STORE_CLASS (class);
	store_class->get_folder_sync = spool_store_get_folder_sync;
	store_class->get_folder_info_sync = spool_store_get_folder_info_sync;
	store_class->get_inbox_folder_sync = spool_store_get_inbox_folder_sync;
	store_class->delete_folder_sync = spool_store_delete_folder_sync;
	store_class->rename_folder_sync = spool_store_rename_folder_sync;

	local_store_class = CAMEL_LOCAL_STORE_CLASS (class);
	local_store_class->get_full_path = spool_store_get_full_path;
	local_store_class->get_meta_path = spool_store_get_meta_path;
}

static void
camel_spool_store_init (CamelSpoolStore *spool_store)
{
	spool_store->priv = CAMEL_SPOOL_STORE_GET_PRIVATE (spool_store);
}
