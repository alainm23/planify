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
#include <sys/types.h>

#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include "camel-maildir-folder.h"
#include "camel-maildir-store.h"
#include "camel-maildir-summary.h"

#define d(x)

#define CAMEL_MAILDIR_STORE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MAILDIR_STORE, CamelMaildirStorePrivate))

/* after the space is a version of the folder structure */
#define MAILDIR_CONTENT_VERSION_STR  "maildir++ 1"
#define MAILDIR_CONTENT_VERSION			1

#define HIER_SEP "."
#define HIER_SEP_CHAR '.'

#define CHECK_MKDIR(x,d) G_STMT_START { \
	gint mkdir_ret = (x); \
	if (mkdir_ret == -1 && errno != EEXIST) { \
		g_debug ("%s: mkdir of '%s' failed: %s", G_STRFUNC, (d), g_strerror (errno)); \
	} \
	} G_STMT_END

struct _CamelMaildirStorePrivate {
	gboolean already_migrated;
	gboolean can_escape_dots;
};

static CamelFolder * maildir_store_get_folder_sync (CamelStore *store, const gchar *folder_name, CamelStoreGetFolderFlags flags,
						GCancellable *cancellable, GError **error);
static CamelFolderInfo *maildir_store_create_folder_sync (CamelStore *store, const gchar *parent_name, const gchar *folder_name,
						GCancellable *cancellable, GError **error);
static gboolean maildir_store_delete_folder_sync (CamelStore * store, const gchar *folder_name, GCancellable *cancellable, GError **error);

static gchar *maildir_full_name_to_dir_name (gboolean can_escape_dots, const gchar *full_name);
static gchar *maildir_dir_name_to_fullname (gboolean can_escape_dots, const gchar *dir_name);
static gchar *maildir_get_full_path (CamelLocalStore *ls, const gchar *full_name);
static gchar *maildir_get_meta_path (CamelLocalStore *ls, const gchar *full_name, const gchar *ext);
static void maildir_migrate_hierarchy (CamelMaildirStore *mstore, gint maildir_version, GCancellable *cancellable, GError **error);
static gboolean maildir_version_requires_migrate (const gchar *meta_filename, gboolean *file_exists, gint *maildir_version);

G_DEFINE_TYPE (CamelMaildirStore, camel_maildir_store, CAMEL_TYPE_LOCAL_STORE)

/* This fixes up some historical cruft of names starting with "./" */
static const gchar *
md_canon_name (const gchar *a)
{
	if (a != NULL) {
		if (a[0] == '/')
			a++;
		if (a[0] == '.' && a[1] == '/')
			a+=2;
	}

	return a;
}

static CamelFolderInfo *
maildir_store_create_folder_sync (CamelStore *store,
                                  const gchar *parent_name,
                                  const gchar *folder_name,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	CamelFolder *folder;
	CamelFolderInfo *info = NULL;
	gchar *name = NULL, *fullname = NULL;
	gchar *path;
	struct stat st;

	/* This is a pretty hacky version of create folder, but should basically work */

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	if (!g_path_is_absolute (path)) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Store root %s is not an absolute path"), path);
		goto exit;
	}

	if (folder_name && !CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots && strchr (folder_name, HIER_SEP_CHAR)) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_INVALID,
			_("Cannot create folder containing “%s”"), HIER_SEP);
		goto exit;
	}

	if ((!parent_name || !*parent_name) && !g_ascii_strcasecmp (folder_name, "Inbox")) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Folder %s already exists"), folder_name);
		goto exit;
	}

	if (parent_name && *parent_name) {
		fullname = g_strdup_printf ("%s/%s", parent_name, folder_name);
		name = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots, fullname);
		g_free (fullname);
	} else
		name = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots, folder_name);

	fullname = g_build_filename (path, name, NULL);

	g_free (name);
	name = NULL;

	if (g_stat (fullname, &st) == 0) {
		g_set_error (
			error, G_IO_ERROR, G_IO_ERROR_EXISTS,
			_("Folder %s already exists"), folder_name);
		goto exit;

	} else if (errno != ENOENT) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Cannot get folder: %s: %s"),
			folder_name, g_strerror (errno));
		goto exit;
	}

	g_free (fullname);
	fullname = NULL;

	if (parent_name && *parent_name)
		name = g_strdup_printf ("%s/%s", parent_name, folder_name);
	else
		name = g_strdup_printf ("%s", folder_name);

	folder = maildir_store_get_folder_sync (
		store, name, CAMEL_STORE_FOLDER_CREATE, cancellable, error);
	if (folder) {
		g_object_unref (folder);
		info = CAMEL_STORE_GET_CLASS (store)->get_folder_info_sync (
			store, name, 0, cancellable, error);
	}

exit:
	g_free (fullname);
	g_free (name);
	g_free (path);

	return info;
}

static CamelFolder *
maildir_store_get_folder_sync (CamelStore *store,
                               const gchar *folder_name,
                               CamelStoreGetFolderFlags flags,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelStoreClass *store_class;
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	CamelMaildirStore *maildir_store;
	gchar *name, *tmp, *cur, *new, *dir_name;
	gchar *path;
	struct stat st;
	CamelFolder *folder = NULL;

	g_return_val_if_fail (CAMEL_IS_MAILDIR_STORE (store), NULL);

	maildir_store = CAMEL_MAILDIR_STORE (store);

	if (!maildir_store->priv->already_migrated &&
	    maildir_store->priv->can_escape_dots) {
		CamelFolderInfo *folder_info;

		/* Not interested in any errors here, this is to invoke folder
		   content migration only. */
		folder_info = camel_store_get_folder_info_sync (store, NULL, CAMEL_STORE_FOLDER_INFO_RECURSIVE, cancellable, NULL);
		if (folder_info)
			camel_folder_info_free (folder_info);
	}

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	folder_name = md_canon_name (folder_name);
	dir_name = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots, folder_name);

	/* maildir++ directory names start with a '.' */
	name = g_build_filename (path, dir_name, NULL);

	g_free (dir_name);
	g_free (path);

	/* Chain up to parent's get_folder() method. */
	store_class = CAMEL_STORE_CLASS (camel_maildir_store_parent_class);
	if (!store_class->get_folder_sync (store, name, flags, cancellable, error)) {
		g_free (name);
		return NULL;
	}

	tmp = g_strdup_printf ("%s/tmp", name);
	cur = g_strdup_printf ("%s/cur", name);
	new = g_strdup_printf ("%s/new", name);

	if (!g_ascii_strcasecmp (folder_name, "Inbox")) {
		/* special case "." (aka inbox), may need to be created */
		if (g_stat (tmp, &st) != 0 || !S_ISDIR (st.st_mode)
		    || g_stat (cur, &st) != 0 || !S_ISDIR (st.st_mode)
		    || g_stat (new, &st) != 0 || !S_ISDIR (st.st_mode)) {
			if ((g_mkdir (tmp, 0700) != 0 && errno != EEXIST)
			    || (g_mkdir (cur, 0700) != 0 && errno != EEXIST)
			    || (g_mkdir (new, 0700) != 0 && errno != EEXIST)) {
				g_set_error (
					error, G_IO_ERROR,
					g_io_error_from_errno (errno),
					_("Cannot create folder “%s”: %s"),
					folder_name, g_strerror (errno));
				rmdir (tmp);
				rmdir (cur);
				rmdir (new);
				goto fail;
			}
		}
		folder = camel_maildir_folder_new (store, folder_name, flags, cancellable, error);
	} else if (g_stat (name, &st) == -1) {
		/* folder doesn't exist, see if we should create it */
		if (errno != ENOENT) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Cannot get folder “%s”: %s"),
				folder_name, g_strerror (errno));
		} else if ((flags & CAMEL_STORE_FOLDER_CREATE) == 0) {
			g_set_error (
				error, CAMEL_STORE_ERROR,
				CAMEL_STORE_ERROR_NO_FOLDER,
				_("Cannot get folder “%s”: folder does not exist."),
				folder_name);
		} else {
			if ((g_mkdir (name, 0700) != 0 && errno != EEXIST)
			    || (g_mkdir (tmp, 0700) != 0 && errno != EEXIST)
			    || (g_mkdir (cur, 0700) != 0 && errno != EEXIST)
			    || (g_mkdir (new, 0700) != 0 && errno != EEXIST)) {
				g_set_error (
					error, G_IO_ERROR,
					g_io_error_from_errno (errno),
					_("Cannot create folder “%s”: %s"),
					folder_name, g_strerror (errno));
				rmdir (tmp);
				rmdir (cur);
				rmdir (new);
				rmdir (name);
			} else {
				folder = camel_maildir_folder_new (store, folder_name, flags, cancellable, error);
			}
		}
	} else if (!S_ISDIR (st.st_mode)
		   || g_stat (tmp, &st) != 0 || !S_ISDIR (st.st_mode)
		   || g_stat (cur, &st) != 0 || !S_ISDIR (st.st_mode)
		   || g_stat (new, &st) != 0 || !S_ISDIR (st.st_mode)) {
		/* folder exists, but not maildir */
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot get folder “%s”: not a maildir directory."),
			name);
	} else {
		folder = camel_maildir_folder_new (store, folder_name, flags, cancellable, error);
	}
fail:
	g_free (name);
	g_free (tmp);
	g_free (cur);
	g_free (new);

	return folder;
}

static gboolean
maildir_store_delete_folder_sync (CamelStore *store,
                                  const gchar *folder_name,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	gchar *name, *tmp, *cur, *new, *dir_name;
	gchar *path;
	struct stat st;
	gboolean success = TRUE;

	if (g_ascii_strcasecmp (folder_name, "Inbox") == 0) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Cannot delete folder: %s: Invalid operation"),
			_("Inbox"));
		return FALSE;
	}

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	/* maildir++ directory names start with a '.' */
	dir_name = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots, folder_name);
	name = g_build_filename (path, dir_name, NULL);
	g_free (dir_name);

	g_free (path);

	tmp = g_strdup_printf ("%s/tmp", name);
	cur = g_strdup_printf ("%s/cur", name);
	new = g_strdup_printf ("%s/new", name);

	if (g_stat (name, &st) == -1 || !S_ISDIR (st.st_mode)
	    || g_stat (tmp, &st) == -1 || !S_ISDIR (st.st_mode)
	    || g_stat (cur, &st) == -1 || !S_ISDIR (st.st_mode)
	    || g_stat (new, &st) == -1 || !S_ISDIR (st.st_mode)) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not delete folder “%s”: %s"),
			folder_name, errno ? g_strerror (errno) :
			_("not a maildir directory"));
	} else {
		gint err = 0;

		/* remove subdirs first - will fail if not empty */
		if (rmdir (cur) == -1 || rmdir (new) == -1) {
			err = errno;
		} else {
			DIR *dir;
			struct dirent *d;

			/* for tmp (only), its contents is irrelevant */
			dir = opendir (tmp);
			if (dir) {
				while ((d = readdir (dir))) {
					gchar *name = d->d_name, *file;

					if (!strcmp (name, ".") || !strcmp (name, ".."))
						continue;
					file = g_strdup_printf ("%s/%s", tmp, name);
					unlink (file);
					g_free (file);
				}
				closedir (dir);
			}
			if (rmdir (tmp) == -1 || rmdir (name) == -1)
				err = errno;
		}

		if (err != 0) {
			/* easier just to mkdir all (and let them fail), than remember what we got to */
			CHECK_MKDIR (g_mkdir (name, 0700), name);
			CHECK_MKDIR (g_mkdir (cur, 0700), cur);
			CHECK_MKDIR (g_mkdir (new, 0700), new);
			CHECK_MKDIR (g_mkdir (tmp, 0700), tmp);
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (err),
				_("Could not delete folder “%s”: %s"),
				folder_name, g_strerror (err));
		} else {
			CamelStoreClass *store_class;

			/* Chain up to parent's delete_folder() method. */
			store_class = CAMEL_STORE_CLASS (camel_maildir_store_parent_class);
			success = store_class->delete_folder_sync (
				store, folder_name, cancellable, error);
		}
	}

	g_free (name);
	g_free (tmp);
	g_free (cur);
	g_free (new);

	return success;
}

static void
fill_fi (CamelStore *store,
         CamelFolderInfo *fi,
         guint32 flags,
         GCancellable *cancellable)
{
	CamelFolder *folder;

	folder = camel_object_bag_peek (camel_store_get_folders_bag (store), fi->full_name);
	if (folder) {
		if ((flags & CAMEL_STORE_FOLDER_INFO_FAST) == 0)
			camel_folder_refresh_info_sync (folder, cancellable, NULL);
		fi->unread = camel_folder_get_unread_message_count (folder);
		fi->total = camel_folder_get_message_count (folder);
		g_object_unref (folder);
	} else {
		CamelLocalSettings *local_settings;
		CamelSettings *settings;
		CamelService *service;
		gchar *folderpath, *dir_name;
		CamelFolderSummary *s;
		gchar *root;

		service = CAMEL_SERVICE (store);

		settings = camel_service_ref_settings (service);

		local_settings = CAMEL_LOCAL_SETTINGS (settings);
		root = camel_local_settings_dup_path (local_settings);

		g_object_unref (settings);

		/* This should be fast enough not to have to test for INFO_FAST */
		dir_name = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots, fi->full_name);

		if (!strcmp (dir_name, "."))
			folderpath = g_strdup (root);
		else
			folderpath = g_build_filename (root, dir_name, NULL);

		g_free (root);

		s = (CamelFolderSummary *) camel_maildir_summary_new (NULL, folderpath, NULL);
		if (camel_folder_summary_header_load (s, store, fi->full_name, NULL)) {
			fi->unread = camel_folder_summary_get_unread_count (s);
			fi->total = camel_folder_summary_get_saved_count (s);
		}
		g_object_unref (s);
		g_free (folderpath);
		g_free (dir_name);
	}

	if (camel_local_store_is_main_store (CAMEL_LOCAL_STORE (store)) && fi->full_name
	    && (fi->flags & CAMEL_FOLDER_TYPE_MASK) == CAMEL_FOLDER_TYPE_NORMAL)
		fi->flags = (fi->flags & ~CAMEL_FOLDER_TYPE_MASK)
			    | camel_local_store_get_folder_type_by_full_name (CAMEL_LOCAL_STORE (store), fi->full_name);
}

static CamelFolderInfo *
scan_fi (CamelStore *store,
         guint32 flags,
         const gchar *full,
         const gchar *name,
         GCancellable *cancellable)
{
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	CamelFolderInfo *fi;
	gchar *tmp, *cur, *new, *dir_name;
	gchar *path;
	struct stat st;

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	g_return_val_if_fail (path != NULL, NULL);

	fi = camel_folder_info_new ();
	fi->full_name = g_strdup (full);
	fi->display_name = g_strdup (name);

	fi->unread = -1;
	fi->total = -1;

	/* we only calculate nochildren properly if we're recursive */
	if (((flags & CAMEL_STORE_FOLDER_INFO_RECURSIVE) != 0))
		fi->flags = CAMEL_FOLDER_NOCHILDREN;

	dir_name = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots, fi->full_name);
	d (printf ("Adding maildir info: '%s' '%s' '%s'\n", fi->name, dir_name, fi->uri));

	tmp = g_build_filename (path, dir_name, "tmp", NULL);
	cur = g_build_filename (path, dir_name, "cur", NULL);
	new = g_build_filename (path, dir_name, "new", NULL);

	if (!(g_stat (cur, &st) == 0 && S_ISDIR (st.st_mode)
	      && g_stat (new, &st) == 0 && S_ISDIR (st.st_mode)
	      /* Create 'tmp' dir on demand, if other directories are there,
		 because some backup tools can drop the 'tmp' directory. */
	      && ((g_stat (tmp, &st) == 0 && S_ISDIR (st.st_mode)) || g_mkdir (tmp, 0700) == 0)))
		fi->flags |= CAMEL_FOLDER_NOSELECT;

	g_free (new);
	g_free (cur);
	g_free (tmp);
	g_free (dir_name);

	fill_fi (store, fi, flags, cancellable);

	g_free (path);

	return fi;
}

/* Folder names begin with a dot */
static gchar *
maildir_full_name_to_dir_name (gboolean can_escape_dots,
			       const gchar *full_name)
{
	gchar *path;

	if (g_ascii_strcasecmp (full_name, "Inbox") == 0) {
		path = g_strdup (".");
	} else {
		if (g_ascii_strncasecmp (full_name, "Inbox/", 6) == 0)
			path = g_strconcat ("/", full_name + 5, NULL);
		else
			path = g_strconcat ("/", full_name, NULL);

		if (can_escape_dots && (strchr (path, HIER_SEP_CHAR) || strchr (path, '_'))) {
			GString *tmp = g_string_new ("");
			const gchar *pp;

			for (pp = path; *pp; pp++) {
				if (*pp == HIER_SEP_CHAR || *pp == '_')
					g_string_append_printf (tmp, "_%02X", *pp);
				else
					g_string_append_c (tmp, *pp);
			}

			g_free (path);
			path = g_string_free (tmp, FALSE);
		}

		g_strdelimit (path, "/", HIER_SEP_CHAR);
	}

	return path;
}

static gchar *
maildir_dir_name_to_fullname (gboolean can_escape_dots,
			      const gchar *dir_name)
{
	gchar *full_name;

	if (!g_ascii_strncasecmp (dir_name, "..", 2))
		full_name = g_strconcat ("Inbox/", dir_name + 2, NULL);
	else
		full_name = g_strdup (dir_name + 1);

	g_strdelimit (full_name, HIER_SEP, '/');

	if (can_escape_dots && strchr (full_name, '_')) {
		gint ii, jj;

		for (ii = 0, jj = 0; full_name[ii]; ii++, jj++) {
			if (full_name[ii] == '_' && g_ascii_isxdigit (full_name[ii + 1]) && g_ascii_isxdigit (full_name[ii + 2])) {
				full_name[jj] = 16 * g_ascii_xdigit_value (full_name[ii + 1]) + g_ascii_xdigit_value (full_name[ii + 2]);
				ii += 2;
			} else if (ii != jj) {
				full_name[jj] = full_name[ii];
			}
		}

		full_name[jj] = '\0';
	}

	return full_name;
}

static gint
scan_dirs (CamelStore *store,
           guint32 flags,
           gboolean can_inbox_sibling,
           CamelFolderInfo **topfi,
           GCancellable *cancellable,
           GError **error)
{
	CamelLocalSettings *local_settings;
	CamelMaildirStore *maildir_store;
	CamelSettings *settings;
	CamelService *service;
	CamelFolderInfo *fi;
	GPtrArray *folders;
	gint res = -1;
	DIR *dir;
	struct dirent *d;
	gchar *path;

	service = CAMEL_SERVICE (store);
	maildir_store = CAMEL_MAILDIR_STORE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	g_return_val_if_fail (path != NULL, -1);

	folders = g_ptr_array_new ();
	if (!g_ascii_strcasecmp ((*topfi)->full_name, "Inbox"))
		g_ptr_array_add (folders, (*topfi));

	dir = opendir (path);
	if (dir == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not scan folder “%s”: %s"),
			path, g_strerror (errno));
		goto exit;
	}

	if (!maildir_store->priv->already_migrated &&
	    maildir_store->priv->can_escape_dots) {
		gchar *meta_path = NULL, *ptr;
		gint maildir_version = 0;
		gboolean file_exists = FALSE, requires_migrate;

		meta_path = maildir_get_meta_path ((CamelLocalStore *) store, "?", "maildir++");
		ptr = strrchr (meta_path, '?');
		if (!ptr) {
			g_warn_if_reached ();
			closedir (dir);
			res = -1;

			goto exit;
		}

		maildir_store->priv->already_migrated = TRUE;

		/* Do not migrate folders out of user's data data, which is completely
		   handled by Camel/Evolution, thus these tweaks can be done there. */
		maildir_store->priv->can_escape_dots = g_str_has_prefix (meta_path, camel_service_get_user_data_dir (service));

		/* cannot pass dot inside maildir_get_meta_path(), because it escapes it */
		ptr[0] = '.';

		requires_migrate = maildir_version_requires_migrate (meta_path, &file_exists, &maildir_version);
		if (file_exists) {
			/* Users can enable dot escaping by adding ..maildir++ file into the root Maildir folder */
			maildir_store->priv->can_escape_dots = TRUE;
		}

		if (requires_migrate && maildir_store->priv->can_escape_dots)
			maildir_migrate_hierarchy ((CamelMaildirStore *) store, maildir_version, cancellable, error);

		g_free (meta_path);
	}

	while ((d = readdir (dir))) {
		gchar *full_name, *filename;
		const gchar *short_name;
		struct stat st;

		if (strcmp (d->d_name, "tmp") == 0
				|| strcmp (d->d_name, "cur") == 0
				|| strcmp (d->d_name, "new") == 0
				|| strcmp (d->d_name, ".#evolution") == 0
				|| strcmp (d->d_name, ".") == 0
				|| strcmp (d->d_name, "..") == 0
				|| !g_str_has_prefix (d->d_name, "."))

				continue;

		filename = g_build_filename (path, d->d_name, NULL);
		if (!(g_stat (filename, &st) == 0 && S_ISDIR (st.st_mode))) {
			g_free (filename);
			continue;
		}
		g_free (filename);
		full_name = maildir_dir_name_to_fullname (maildir_store->priv->can_escape_dots, d->d_name);
		short_name = strrchr (full_name, '/');
		if (!short_name)
			short_name = full_name;
		else
			short_name++;

		if ((g_ascii_strcasecmp ((*topfi)->full_name, "Inbox") != 0
		    && (!g_str_has_prefix (full_name, (*topfi)->full_name) ||
			(full_name[strlen ((*topfi)->full_name)] != '\0' &&
			 full_name[strlen ((*topfi)->full_name)] != '/')))
		    || (!can_inbox_sibling
		    && g_ascii_strcasecmp ((*topfi)->full_name, "Inbox") == 0
		    && (!g_str_has_prefix (full_name, (*topfi)->full_name) ||
			(full_name[strlen ((*topfi)->full_name)] != '\0' &&
			 full_name[strlen ((*topfi)->full_name)] != '/')))) {
			g_free (full_name);
			continue;
		}

		fi = scan_fi (store, flags, full_name, short_name, cancellable);
		g_free (full_name);

		g_ptr_array_add (folders, fi);
	}

	closedir (dir);

	if (folders->len != 0) {
		if (!g_ascii_strcasecmp ((*topfi)->full_name, "Inbox")) {
			*topfi = camel_folder_info_build (folders, "", '/', TRUE);
		} else {
			CamelFolderInfo *old_topfi = *topfi;

			*topfi = camel_folder_info_build (folders, (*topfi)->full_name, '/', TRUE);
			camel_folder_info_free (old_topfi);
		}

		fi = *topfi;

		if (fi && (flags & CAMEL_STORE_FOLDER_INFO_RECURSIVE) != 0) {
			while (fi) {
				if (fi->child) {
					fi->flags = fi->flags & (~CAMEL_FOLDER_NOCHILDREN);
					fi->flags = fi->flags | CAMEL_FOLDER_CHILDREN;

					fi = fi->child;
				} else if (fi->next) {
					fi = fi->next;
				} else {
					while (fi) {
						fi = fi->parent;
						if (fi && fi->next) {
							fi = fi->next;
							break;
						}
					}
				}
			}
		}

		res = 0;
	} else
		res = -1;

exit:
	g_ptr_array_free (folders, TRUE);

	g_free (path);

	return res;
}

static guint
maildir_store_hash_folder_name (gconstpointer a)
{
	return g_str_hash (md_canon_name (a));
}

static gboolean
maildir_store_equal_folder_name (gconstpointer a,
                                 gconstpointer b)
{
	return g_str_equal (md_canon_name (a), md_canon_name (b));
}

static CamelFolderInfo *
maildir_store_get_folder_info_sync (CamelStore *store,
                                    const gchar *top,
                                    CamelStoreGetFolderInfoFlags flags,
                                    GCancellable *cancellable,
                                    GError **error)
{
	CamelFolderInfo *fi = NULL;

	if (top == NULL || top[0] == 0) {
		/* create a dummy "." parent inbox, use to scan, then put back at the top level */
		fi = scan_fi (store, flags, "Inbox", _("Inbox"), cancellable);
		if (scan_dirs (store, flags, TRUE, &fi, cancellable, error) == -1)
			goto fail;

		fi->flags |= CAMEL_FOLDER_SYSTEM | CAMEL_FOLDER_TYPE_INBOX;
	} else if (!strcmp (top, ".")) {
		fi = scan_fi (store, flags, "Inbox", _("Inbox"), cancellable);
		fi->flags |= CAMEL_FOLDER_SYSTEM | CAMEL_FOLDER_TYPE_INBOX;
	} else {
		const gchar *name = strrchr (top, '/');

		fi = scan_fi (store, flags, top, name ? name + 1 : top, cancellable);
		if (g_strcmp0 (fi->full_name, CAMEL_VTRASH_NAME) != 0 &&
		    g_strcmp0 (fi->full_name, CAMEL_VJUNK_NAME) != 0 &&
		    scan_dirs (store, flags, FALSE, &fi, cancellable, error) == -1)
			goto fail;
	}

	return fi;

fail:
	camel_folder_info_free (fi);

	return NULL;
}

static CamelFolder *
maildir_store_get_inbox_sync (CamelStore *store,
                              GCancellable *cancellable,
                              GError **error)
{
	return camel_store_get_folder_sync (
		store, "Inbox", CAMEL_STORE_FOLDER_CREATE, cancellable, error);
}

static gboolean
rename_traverse_fi (CamelStore *store,
                    CamelStoreClass *store_class,
                    CamelFolderInfo *fi,
                    const gchar *old_full_name_prefix,
                    const gchar *new_full_name_prefix,
                    GCancellable *cancellable,
                    GError **error)
{
	gint old_prefix_len = strlen (old_full_name_prefix);
	gboolean ret = TRUE;

	while (fi && ret) {
		if (fi->full_name && g_str_has_prefix (fi->full_name, old_full_name_prefix)) {
			gchar *new_full_name, *old_dir, *new_dir;

			new_full_name = g_strconcat (new_full_name_prefix, fi->full_name + old_prefix_len, NULL);
			old_dir = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots, fi->full_name);
			new_dir = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots, new_full_name);

			/* Chain up to parent's rename_folder_sync() method. */
			ret = store_class->rename_folder_sync (store, old_dir, new_dir, cancellable, error);

			g_free (old_dir);
			g_free (new_dir);
			g_free (new_full_name);
		}

		if (fi->child && !rename_traverse_fi (store, store_class, fi->child, old_full_name_prefix, new_full_name_prefix, cancellable, error))
			return FALSE;

		fi = fi->next;
	}

	return ret;
}

static gboolean
maildir_store_rename_folder_sync (CamelStore *store,
                                  const gchar *old,
                                  const gchar *new,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelStoreClass *store_class;
	gboolean ret;
	gchar *old_dir, *new_dir;
	CamelFolderInfo *subfolders;

	if (strcmp (old, ".") == 0) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Cannot rename folder: %s: Invalid operation"),
			_("Inbox"));
		return FALSE;
	}

	if (!g_ascii_strcasecmp (new, "Inbox")) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_NO_FOLDER,
			_("Folder %s already exists"), new);
		return FALSE;
	}

	if (new && !CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots && strchr (new, HIER_SEP_CHAR)) {
		g_set_error (
			error, CAMEL_STORE_ERROR,
			CAMEL_STORE_ERROR_INVALID,
			_("Cannot create folder containing “%s”"), HIER_SEP);
		return FALSE;
	}

	subfolders = maildir_store_get_folder_info_sync (
		store, old,
		CAMEL_STORE_FOLDER_INFO_RECURSIVE |
		CAMEL_STORE_FOLDER_INFO_NO_VIRTUAL,
		cancellable, NULL);

	old_dir = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots, old);
	new_dir = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (store)->priv->can_escape_dots, new);

	/* Chain up to parent's rename_folder_sync() method. */
	store_class = CAMEL_STORE_CLASS (camel_maildir_store_parent_class);
	ret = store_class->rename_folder_sync (
		store, old_dir, new_dir, cancellable, error);

	if (subfolders) {
		if (ret)
			ret = rename_traverse_fi (
				store, store_class,
				subfolders->child,
				old, new,
				cancellable, error);

		camel_folder_info_free (subfolders);
	}

	g_free (old_dir);
	g_free (new_dir);

	return ret;
}

static void
camel_maildir_store_class_init (CamelMaildirStoreClass *class)
{
	CamelStoreClass *store_class;
	CamelLocalStoreClass *local_class;

	g_type_class_add_private (class, sizeof (CamelMaildirStorePrivate));

	store_class = CAMEL_STORE_CLASS (class);
	store_class->hash_folder_name = maildir_store_hash_folder_name;
	store_class->equal_folder_name = maildir_store_equal_folder_name;
	store_class->create_folder_sync = maildir_store_create_folder_sync;
	store_class->get_folder_sync = maildir_store_get_folder_sync;
	store_class->get_folder_info_sync = maildir_store_get_folder_info_sync;
	store_class->get_inbox_folder_sync = maildir_store_get_inbox_sync;
	store_class->delete_folder_sync = maildir_store_delete_folder_sync;
	store_class->rename_folder_sync = maildir_store_rename_folder_sync;

	local_class = CAMEL_LOCAL_STORE_CLASS (class);
	local_class->get_full_path = maildir_get_full_path;
	local_class->get_meta_path = maildir_get_meta_path;
}

static void
camel_maildir_store_init (CamelMaildirStore *maildir_store)
{
	maildir_store->priv = CAMEL_MAILDIR_STORE_GET_PRIVATE (maildir_store);
	maildir_store->priv->already_migrated = FALSE;
	maildir_store->priv->can_escape_dots = TRUE;
}

static gchar *
maildir_get_full_path (CamelLocalStore *ls,
                       const gchar *full_name)
{
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	gchar *filename;
	gchar *dir_name;
	gchar *path;

	service = CAMEL_SERVICE (ls);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	dir_name = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (ls)->priv->can_escape_dots, full_name);
	filename = g_build_filename (path, dir_name, NULL);
	g_free (dir_name);

	g_free (path);

	return filename;
}

static gchar *
maildir_get_meta_path (CamelLocalStore *ls,
                       const gchar *full_name,
                       const gchar *ext)
{
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	gchar *filename;
	gchar *dir_name;
	gchar *path;
	gchar *tmp;

	service = CAMEL_SERVICE (ls);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	dir_name = maildir_full_name_to_dir_name (CAMEL_MAILDIR_STORE (ls)->priv->can_escape_dots, full_name);
	tmp = g_build_filename (path, dir_name, NULL);
	filename = g_strconcat (tmp, ext, NULL);
	g_free (tmp);
	g_free (dir_name);

	g_free (path);

	return filename;
}

/* Migration from old to maildir++ hierarchy */

struct _scan_node {
	CamelFolderInfo *fi;

	dev_t dnode;
	ino_t inode;
};

static guint
scan_hash (gconstpointer d)
{
	const struct _scan_node *v = d;

	return v->inode ^ v->dnode;
}

static gboolean
scan_equal (gconstpointer a,
            gconstpointer b)
{
	const struct _scan_node *v1 = a, *v2 = b;

	return v1->inode == v2->inode && v1->dnode == v2->dnode;
}

static void
scan_free (gpointer k,
           gpointer v,
           gpointer d)
{
	g_free (k);
}

static gint
scan_old_dir_info (CamelStore *store,
                   CamelFolderInfo *topfi,
                   GError **error)
{
	CamelLocalSettings *local_settings;
	CamelSettings *settings;
	CamelService *service;
	GQueue queue = G_QUEUE_INIT;
	struct _scan_node *sn;
	gchar *path;
	gchar *tmp;
	GHashTable *visited;
	struct stat st;
	gint res = -1;

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	local_settings = CAMEL_LOCAL_SETTINGS (settings);
	path = camel_local_settings_dup_path (local_settings);

	g_object_unref (settings);

	visited = g_hash_table_new (scan_hash, scan_equal);

	sn = g_malloc0 (sizeof (*sn));
	sn->fi = topfi;
	g_queue_push_tail (&queue, sn);
	g_hash_table_insert (visited, sn, sn);

	while (!g_queue_is_empty (&queue)) {
		gchar *name;
		DIR *dir;
		struct dirent *d;
		CamelFolderInfo *last;

		sn = g_queue_pop_head (&queue);

		last = (CamelFolderInfo *) &sn->fi->child;

		if (!strcmp (sn->fi->full_name, "."))
			name = g_strdup (path);
		else
			name = g_build_filename (path, sn->fi->full_name, NULL);

		dir = opendir (name);
		if (dir == NULL) {
			g_free (name);
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Could not scan folder “%s”: %s"),
				path, g_strerror (errno));
			goto exit;
		}

		while ((d = readdir (dir))) {
			if (strcmp (d->d_name, "tmp") == 0
			    || strcmp (d->d_name, "cur") == 0
			    || strcmp (d->d_name, "new") == 0
			    || strcmp (d->d_name, ".#evolution") == 0
			    || strcmp (d->d_name, ".") == 0
			    || strcmp (d->d_name, "..") == 0)
				continue;

			tmp = g_build_filename (name, d->d_name, NULL);
			if (stat (tmp, &st) == 0 && S_ISDIR (st.st_mode)) {
				struct _scan_node in;

				memset (&in, 0, sizeof (struct _scan_node));
				in.dnode = st.st_dev;
				in.inode = st.st_ino;

				/* see if we've visited already */
				if (g_hash_table_lookup (visited, &in) == NULL) {
					struct _scan_node *snew = g_malloc (sizeof (*snew));
					gchar *full;
					CamelFolderInfo *fi = NULL;

					snew->dnode = in.dnode;
					snew->inode = in.inode;

					if (!strcmp (sn->fi->full_name, "."))
						full = g_strdup (d->d_name);
					else
						full = g_strdup_printf ("%s/%s", sn->fi->full_name, d->d_name);

					fi = camel_folder_info_new ();
					fi->full_name = full;
					fi->display_name = g_strdup (d->d_name);
					snew->fi = fi;

					last->next = snew->fi;
					last = snew->fi;
					snew->fi->parent = sn->fi;

					g_hash_table_insert (visited, snew, snew);
					g_queue_push_tail (&queue, snew);
				}
			}
			g_free (tmp);
		}
		closedir (dir);
		g_free (name);
	}

	res = 0;

exit:
	g_hash_table_foreach (visited, scan_free, NULL);
	g_hash_table_destroy (visited);

	g_free (path);

	return res;
}

static void
maildir_maybe_rename_old_folder (CamelMaildirStore *mstore,
                                 CamelFolderInfo *fi,
                                 gint maildir_version,
                                 GCancellable *cancellable,
                                 GError **error)
{
	gchar *new_name = NULL;

	if (g_str_equal (fi->full_name, ".") || g_str_equal (fi->full_name, ".."))
		return;

	if (maildir_version == -1) {
		/* this is when maildir was not converted yet to maildir++ at all,
		 * the '_' and '.'  are still there and the dir separator is slash
		*/
		new_name = maildir_full_name_to_dir_name (mstore->priv->can_escape_dots, fi->full_name);
	} else if (maildir_version == 0) {
		/* this is a conversion with maildir folder being already there,
		 * only with no version; there should be escaped only '_', because
		 * the '.' is already garbled;
		 * fi->full_name is a dir name here
		*/
		gchar *full_name;

		if (!g_ascii_strncasecmp (fi->full_name, "..", 2))
			full_name = g_strconcat ("Inbox/", fi->full_name + 2, NULL);
		else if (fi->full_name[0] == '.')
			full_name = g_strdup (fi->full_name + 1);
		else
			full_name = g_strdup (fi->full_name);

		g_strdelimit (full_name, HIER_SEP, '/');

		new_name = maildir_full_name_to_dir_name (mstore->priv->can_escape_dots, full_name);

		g_free (full_name);
	} else {
		return;
	}

	if (!g_str_equal (fi->full_name, new_name)) {
		CamelStoreClass *store_class;
		GError *local_error = NULL;

		store_class = CAMEL_STORE_CLASS (camel_maildir_store_parent_class);
		/* Do not propagate these errors, only warn about them on console */
		store_class->rename_folder_sync ((CamelStore *) mstore, fi->full_name, new_name, cancellable, &local_error);

		if (local_error) {
			g_warning ("%s: Failed to rename '%s' to '%s': %s", G_STRFUNC, fi->full_name, new_name, local_error->message);
			g_error_free (local_error);
		}
	}

	g_free (new_name);
}

static void
traverse_rename_folder_info (CamelMaildirStore *mstore,
                             CamelFolderInfo *fi,
                             gint maildir_version,
                             GCancellable *cancellable,
                             GError **error)
{
	while (fi != NULL) {
		if (fi->child)
			traverse_rename_folder_info (mstore, fi->child, maildir_version, cancellable, error);

		maildir_maybe_rename_old_folder (mstore, fi, maildir_version, cancellable, error);

		fi = fi->next;
	}
}

static gboolean
maildir_version_requires_migrate (const gchar *meta_filename,
				  gboolean *file_exists,
                                  gint *maildir_version)
{
	FILE *metafile;
	gint cc;
	gint verpos = 0;
	gboolean res = FALSE;

	g_return_val_if_fail (meta_filename != NULL, FALSE);
	g_return_val_if_fail (file_exists != NULL, FALSE);
	g_return_val_if_fail (maildir_version != NULL, FALSE);

	/* nonexistent file is -1 */
	*maildir_version = -1;
	*file_exists = FALSE;

	if (!g_file_test (meta_filename, G_FILE_TEST_EXISTS))
		return TRUE;

	/* existing file without version is 0 */
	*maildir_version = 0;
	*file_exists = TRUE;

	metafile = fopen (meta_filename, "rb");
	if (!metafile)
		return FALSE;

	while (cc = fgetc (metafile), !res && !feof (metafile)) {
		if (verpos > 1 && MAILDIR_CONTENT_VERSION_STR[verpos - 1] == ' ') {
			if (cc >= '0' && cc <= '9') {
				(*maildir_version) = (*maildir_version) * 10 + cc - '0';
			} else if (cc == ' ' || cc == '\n' || cc == '\r' || cc == '\t') {
				break;
			} else {
				res = TRUE;
			}
		} else if (cc == MAILDIR_CONTENT_VERSION_STR[verpos]) {
			verpos++;
		} else {
			res = TRUE;
		}
	}

	fclose (metafile);

	return res || (*maildir_version) < MAILDIR_CONTENT_VERSION;
}

static void
maildir_migrate_hierarchy (CamelMaildirStore *mstore,
                           gint maildir_version,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelFolderInfo *topfi;
	gchar *meta_path = NULL, *ptr;

	g_return_if_fail (mstore->priv->can_escape_dots);

	topfi = camel_folder_info_new ();
	topfi->full_name = g_strdup (".");
	topfi->display_name = g_strdup ("Inbox");

	if (scan_old_dir_info ((CamelStore *) mstore, topfi, error) == -1) {
		g_warning ("%s: Failed to scan the old folder info", G_STRFUNC);
		goto done;
	}

	meta_path = maildir_get_meta_path ((CamelLocalStore *) mstore, "?", "maildir++");
	ptr = strrchr (meta_path, '?');
	g_return_if_fail (ptr != NULL);

	/* cannot pass dot inside maildir_get_meta_path(), because it is escaped */
	ptr[0] = '.';

	/* First create/overwrite the file, only then do the migration, otherwise,
	   if the file creation fails, the folder structure would be migrated repeatedly. */
	if (!g_file_set_contents (meta_path, MAILDIR_CONTENT_VERSION_STR, -1, error) || (error && *error)) {
		g_warning ("Failed to save the maildir version in ‘%s’.", meta_path);
		goto done;
	}

	if (maildir_version < 1) {
		traverse_rename_folder_info (mstore, topfi, maildir_version, cancellable, error);
	}

done:
	camel_folder_info_free (topfi);
	g_free (meta_path);
}
