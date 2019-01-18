/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016-2018 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "config.h"
#include "as-distro-extras.h"

/**
 * SECTION:as-distro-extras
 * @short_description: Private helper methods to integrate AppStream better with distros
 * @include: appstream.h
 *
 * This module mainly contains distribution-specific, non-public helper methods.
 */

#include <glib.h>
#include <glib/gstdio.h>
#include <gio/gio.h>
#include <glib/gi18n-lib.h>
#include <errno.h>

#include "as-utils.h"
#include "as-utils-private.h"
#include "as-pool-private.h"

#define YAML_SEPARATOR "---"
/* Compilers will optimise this to a constant */
#define YAML_SEPARATOR_LEN strlen(YAML_SEPARATOR)

static const gchar *apt_lists_dir = "/var/lib/apt/lists/";
static const gchar *appstream_yml_target = "/var/lib/app-info/yaml";
static const gchar *appstream_icons_target = "/var/lib/app-info/icons";

static const gchar* const default_icon_sizes[] = { "48x48", "48x48@2", "64x64", "64x64@2", "128x128", "128x128@2", NULL };


/**
 * directory_is_empty:
 *
 * Quickly check if a directory is empty.
 */
static gboolean
directory_is_empty (const gchar *dirname)
{
	gint n = 0;
	struct dirent *d;
	DIR *dir = opendir (dirname);

	if (dir == NULL)
		return TRUE;

	while ((d = readdir (dir)) != NULL) {
		if (++n > 2)
			break;
	}

	closedir (dir);

	/* empty directory contains . and .. */
	if (n <= 2)
		return TRUE;
	else
		return 0;
}

/**
 * as_get_yml_data_origin:
 *
 * Extract the data origin from the AppStream YAML file.
 * We don't use the #AsYAMLData loader, because it is much
 * slower than just loading the initial parts of the file and
 * extracting the origin manually.
 */
static gchar*
as_get_yml_data_origin (const gchar *fname)
{
	const gchar *data;
	GZlibDecompressor *zdecomp;
	g_autoptr(GFileInputStream) fistream = NULL;
	g_autoptr(GMemoryOutputStream) mem_os = NULL;
	g_autoptr(GInputStream) conv_stream = NULL;
	g_autoptr(GFile) file = NULL;
	g_autofree gchar *str = NULL;
	g_auto(GStrv) strv = NULL;
	GError *err;
	guint i;
	gchar *start, *end;
	gchar *origin = NULL;

	file = g_file_new_for_path (fname);
	fistream = g_file_read (file, NULL, &err);

	if (!fistream) {
		g_critical ("Unable to open file '%s' for reading: %s, skipping.", fname, err->message);
		g_error_free (err);
		return NULL;
	}

	mem_os = (GMemoryOutputStream*) g_memory_output_stream_new (NULL, 0, g_realloc, g_free);
	zdecomp = g_zlib_decompressor_new (G_ZLIB_COMPRESSOR_FORMAT_GZIP);
	conv_stream = g_converter_input_stream_new (G_INPUT_STREAM (fistream), G_CONVERTER (zdecomp));
	g_object_unref (zdecomp);

	g_output_stream_splice (G_OUTPUT_STREAM (mem_os), conv_stream, 0, NULL, NULL);
	data = (const gchar*) g_memory_output_stream_get_data (mem_os);

	/* faster than a regular expression?
	 * Get the first YAML document, then extract the origin string.
	 */
	if (data == NULL)
		return NULL;
	/* start points to the start of the document, i.e. "File:" normally */
	start = g_strstr_len (data, 400, YAML_SEPARATOR) + YAML_SEPARATOR_LEN;
	if (start[0] == '\0')
		return NULL;
	/* Find the end of the first document - can be NULL if there is only one,
	 * for example if we're given YAML for an empty archive */
	end = g_strstr_len (start, -1, YAML_SEPARATOR);
	str = g_strndup (start, strlen(start) - (end ? strlen(end) : 0));

	strv = g_strsplit (str, "\n", -1);
	for (i = 0; strv[i] != NULL; i++) {
		g_auto(GStrv) strv2 = NULL;
		if (!g_str_has_prefix (strv[i], "Origin:"))
			continue;

		strv2 = g_strsplit (strv[i], ":", 2);
		g_strstrip (strv2[1]);
		origin = g_strdup (strv2[1]);

		/* remove quotes, in case the string is quoted */
		if ((g_str_has_prefix (origin, "\"")) && (g_str_has_suffix (origin, "\""))) {
			g_autofree gchar *tmp = NULL;

			tmp = origin;
			origin = g_strndup (tmp + 1, strlen (tmp) - 2);
		}

		break;
	}

	return origin;
}

/**
 * as_extract_icon_cache_tarball:
 */
static void
as_extract_icon_cache_tarball (const gchar *asicons_target,
			       const gchar *origin,
			       const gchar *apt_basename,
			       const gchar *apt_lists_dir,
			       const gchar *icons_size)
{
	g_autofree gchar *escaped_size = NULL;
	g_autofree gchar *icons_tarball = NULL;
	g_autofree gchar *target_dir = NULL;
	g_autofree gchar *cmd = NULL;
	g_autofree gchar *stderr_txt = NULL;
	gint res;
	g_autoptr(GError) tmp_error = NULL;

	escaped_size = g_uri_escape_string (icons_size, NULL, FALSE);
	icons_tarball = g_strdup_printf ("%s/%sicons-%s.tar.gz", apt_lists_dir, apt_basename, escaped_size);
	if (!g_file_test (icons_tarball, G_FILE_TEST_EXISTS)) {
		/* no icons found, stop here */
		return;
	}

	target_dir = g_build_filename (asicons_target, origin, icons_size, NULL);
	if (g_mkdir_with_parents (target_dir, 0755) > 0) {
		g_debug ("Unable to create '%s': %s", target_dir, g_strerror (errno));
		return;
	}

	if (!as_utils_is_writable (target_dir)) {
		g_debug ("Unable to write to '%s': Can't add AppStream icon-cache from APT to the pool.", target_dir);
		return;
	}

	cmd = g_strdup_printf ("/bin/tar -xzf '%s' -C '%s'", icons_tarball, target_dir);
	g_spawn_command_line_sync (cmd, NULL, &stderr_txt, &res, &tmp_error);
	if (tmp_error != NULL) {
		g_debug ("Failed to run tar: %s", tmp_error->message);
	}
	if (res != 0) {
		g_debug ("Running tar failed with exit-code %i: %s", res, stderr_txt);
	}
}

/**
 * as_pool_check_file_newer_than_cache:
 */
static gboolean
as_pool_check_file_newer_than_cache (AsPool *pool, GPtrArray *file_list)
{
	guint i;

	for (i = 0; i < file_list->len; i++) {
		struct stat sb;
		const gchar *fname = (const gchar*) g_ptr_array_index (file_list, i);
		if (stat (fname, &sb) < 0)
			continue;
		if (sb.st_ctime > as_pool_get_cache_age (pool)) {
			/* we need to update the cache */
			return TRUE;
		}
	}

	return FALSE;
}

/**
 * as_pool_scan_apt:
 *
 * Scan for additional metadata in 3rd-party directories and move it to the right place.
 */
void
as_pool_scan_apt (AsPool *pool, gboolean force, GError **error)
{
	g_autoptr(GPtrArray) yml_files = NULL;
	g_autoptr(GError) tmp_error = NULL;
	gboolean data_changed = FALSE;
	gboolean icons_available = FALSE;
	guint i;

	/* skip this step if the APT lists directory doesn't exist */
	if (!g_file_test (apt_lists_dir, G_FILE_TEST_IS_DIR)) {
		g_debug ("APT lists directory (%s) not found!", apt_lists_dir);
		return;
	}

	if (g_file_test (appstream_yml_target, G_FILE_TEST_IS_DIR)) {
		g_autoptr(GPtrArray) ytfiles = NULL;

		/* we can't modify the files here if we don't have write access */
		if (!as_utils_is_writable (appstream_yml_target)) {
			g_debug ("Unable to write to '%s': Can't add AppStream data from APT to the pool.", appstream_yml_target);
			return;
		}

		ytfiles = as_utils_find_files_matching (appstream_yml_target, "*", FALSE, &tmp_error);
		if (tmp_error != NULL) {
			g_warning ("Could not scan for broken symlinks in DEP-11 target: %s", tmp_error->message);
			return;
		}

		if (ytfiles != NULL) {
			for (i = 0; i < ytfiles->len; i++) {
				const gchar *fname = (const gchar*) g_ptr_array_index (ytfiles, i);
				if (!g_file_test (fname, G_FILE_TEST_EXISTS)) {
					g_remove (fname);
					data_changed = TRUE;
				}
			}
		}
	}

	yml_files = as_utils_find_files_matching (apt_lists_dir, "*Components-*.yml.gz", FALSE, &tmp_error);
	if (tmp_error != NULL) {
		g_warning ("Could not scan for APT-downloaded DEP-11 files: %s", tmp_error->message);
		return;
	}

	/* no data found? skip scan step */
	if (yml_files == NULL || yml_files->len <= 0) {
		g_debug ("Could not find DEP-11 data in APT directories.");
		return;
	}

	/* We have to check if our metadata is in the target directory at all, and - if not - trigger a cache refresh.
	 * This is needed because APT is putting files with the *server* ctime/mtime into it's lists directory,
	 * and that time might be lower than the time the metadata cache was last updated, which may result
	 * in no cache update being triggered at all.
	 *
	 * We also check for available icons, to install icons again if they were disabled (and removed) previously.
	 */
	for (i = 0; i < yml_files->len; i++) {
		g_autofree gchar *fbasename = NULL;
		g_autofree gchar *dest_fname = NULL;
		const gchar *fname = (const gchar*) g_ptr_array_index (yml_files, i);

		fbasename = g_path_get_basename (fname);
		dest_fname = g_build_filename (appstream_yml_target, fbasename, NULL);
		if (!g_file_test (dest_fname, G_FILE_TEST_EXISTS)) {
			data_changed = TRUE;
			g_debug ("File '%s' missing, cache update is needed.", dest_fname);
			break;
		}

		if (!icons_available) {
			g_autofree gchar *apt_basename = NULL;
			guint j;

			/* get base prefix for this file in the APT download cache */
			apt_basename = g_strndup (fbasename, strlen (fbasename) - strlen (g_strrstr (fbasename, "_") + 1));

			for (j = 0; default_icon_sizes[j] != NULL; j++) {
				g_autofree gchar *icons_tarball = NULL;

				/* NOTE: We would normally need to escape the "@" of HiDPI icons here, but since having only HiDPI icons is
				 * a case that never happens and the 64x64px icons are required to be present anyway, we ignore that fact. */
				icons_tarball = g_strdup_printf ("%s/%sicons-%s.tar.gz", apt_lists_dir, apt_basename, default_icon_sizes[j]);
				if (g_file_test (icons_tarball, G_FILE_TEST_EXISTS)) {
					icons_available = TRUE;
					break;
				}
			}
		}
	}

	/* get the last time we touched the database */
	if (!data_changed) {
		/* check if a data file was updated */
		data_changed = as_pool_check_file_newer_than_cache (pool, yml_files);

		/* check if we have no icons, but should have some */
		if (icons_available) {
			if (directory_is_empty (appstream_icons_target))
				data_changed = TRUE; /* we need to update, icons are missing */
		}
	}

	/* no changes means nothing to do here */
	if ((!data_changed) && (!force))
		return;

	/* this is not really great, but we simply can't detect if we should remove an icons folder or not,
	 * or which specific icons we should drop from a folder.
	 * So, we hereby simply "own" the icons directory and all it's contents, anything put in there by 3rd-parties will
	 * be deleted.
	 * (And there should actually be no cases 3rd-parties put icons there on a Debian machine, since metadata in packages
	 * will land in /usr/share/app-info anyway)
	 */
	as_utils_delete_dir_recursive (appstream_icons_target);
	if (g_mkdir_with_parents (appstream_yml_target, 0755) > 0) {
		g_debug ("Unable to create '%s': %s", appstream_yml_target, g_strerror (errno));
		return;
	}

	for (i = 0; i < yml_files->len; i++) {
		g_autofree gchar *fbasename = NULL;
		g_autofree gchar *dest_fname = NULL;
		g_autofree gchar *origin = NULL;
		g_autofree gchar *file_baseprefix = NULL;
		guint j;
		const gchar *fname = (const gchar*) g_ptr_array_index (yml_files, i);

		fbasename = g_path_get_basename (fname);
		dest_fname = g_build_filename (appstream_yml_target, fbasename, NULL);

		if (!g_file_test (fname, G_FILE_TEST_EXISTS)) {
			/* broken symlinks in the dest will have been removed earlier */
			g_debug ("File %s is a broken symlink, skipping.", fname);
			continue;
		} else if (!g_file_test (dest_fname, G_FILE_TEST_EXISTS)) {
			/* file not found, let's symlink */
			if (symlink (fname, dest_fname) != 0) {
				g_debug ("Unable to set symlink (%s -> %s): %s",
							fname,
							dest_fname,
							g_strerror (errno));
				continue;
			}
		} else if (!g_file_test (dest_fname, G_FILE_TEST_IS_SYMLINK)) {
			/* file found, but it isn't a symlink, try to rescue */
			g_debug ("Regular file '%s' found, which doesn't belong there. Removing it.", dest_fname);
			g_remove (dest_fname);
			continue;
		}

		/* get DEP-11 data origin */
		origin = as_get_yml_data_origin (dest_fname);
		if (origin == NULL) {
			g_warning ("No origin found for file %s", fbasename);
			continue;
		}

		/* get base prefix for this file in the APT download cache */
		file_baseprefix = g_strndup (fbasename, strlen (fbasename) - strlen (g_strrstr (fbasename, "_") + 1));

		/* extract icons to their destination (if they exist at all */
		for (j = 0; default_icon_sizes[j] != NULL; j++) {
			as_extract_icon_cache_tarball (appstream_icons_target,
							origin,
							file_baseprefix,
							apt_lists_dir,
							default_icon_sizes[j]);
		}
	}

	/* ensure the cache-rebuild process notices these changes */
	as_touch_location (appstream_yml_target);
}
