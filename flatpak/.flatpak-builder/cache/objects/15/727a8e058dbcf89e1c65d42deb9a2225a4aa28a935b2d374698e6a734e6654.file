/*
 * evolution-source-registry-migrate-basedir.c
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
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <glib/gstdio.h>
#include <libedataserver/libedataserver.h>

#include "evolution-source-registry-methods.h"

static gboolean
migrate_rename (const gchar *old_filename,
                const gchar *new_filename)
{
	gboolean old_filename_is_dir;
	gboolean old_filename_exists;
	gboolean new_filename_exists;
	gboolean success = TRUE;

	old_filename_is_dir = g_file_test (old_filename, G_FILE_TEST_IS_DIR);
	old_filename_exists = g_file_test (old_filename, G_FILE_TEST_EXISTS);
	new_filename_exists = g_file_test (new_filename, G_FILE_TEST_EXISTS);

	if (!old_filename_exists)
		return TRUE;

	e_source_registry_debug_print ("  mv %s %s\n", old_filename, new_filename);

	/* It's safe to go ahead and move directories because rename()
	 * will fail if the new directory already exists with content.
	 * With regular files we have to be careful not to overwrite
	 * new files with old files. */
	if (old_filename_is_dir || !new_filename_exists) {
		if (g_rename (old_filename, new_filename) < 0) {
			g_printerr ("  FAILED: %s\n", g_strerror (errno));
			success = FALSE;
		}
	} else {
		g_printerr ("  FAILED: Destination file already exists\n");
		success = FALSE;
	}

	return success;
}

static gboolean
migrate_rmdir (const gchar *dirname)
{
	GDir *dir = NULL;
	gboolean success = TRUE;

	if (g_file_test (dirname, G_FILE_TEST_IS_DIR)) {
		e_source_registry_debug_print ("  rmdir %s\n", dirname);
		if (g_rmdir (dirname) < 0) {
			g_printerr ("  FAILED: %s", g_strerror (errno));
			if (errno == ENOTEMPTY) {
				dir = g_dir_open (dirname, 0, NULL);
				g_printerr (" (contents follows)");
			}
			g_printerr ("\n");
			success = FALSE;
		}
	}

	/* List the directory's contents to aid debugging. */
	if (dir != NULL) {
		const gchar *basename;

		/* Align the filenames beneath the error message. */
		while ((basename = g_dir_read_name (dir)) != NULL)
			e_source_registry_debug_print ("          %s\n", basename);

		g_dir_close (dir);
	}

	return success;
}

static void
migrate_process_corrections (GHashTable *corrections)
{
	GHashTableIter iter;
	gpointer old_filename;
	gpointer new_filename;

	g_hash_table_iter_init (&iter, corrections);

	while (g_hash_table_iter_next (&iter, &old_filename, &new_filename)) {
		migrate_rename (old_filename, new_filename);
		g_hash_table_iter_remove (&iter);
	}
}

static gboolean
migrate_move_contents (const gchar *src_directory,
                       const gchar *dst_directory)
{
	GDir *dir;
	GHashTable *corrections;
	const gchar *basename;

	dir = g_dir_open (src_directory, 0, NULL);
	if (dir == NULL)
		return FALSE;

	/* This is to avoid renaming files while we're iterating over the
	 * directory.  POSIX says the outcome of that is unspecified. */
	corrections = g_hash_table_new_full (
		g_str_hash, g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_free);

	g_mkdir_with_parents (dst_directory, 0700);

	while ((basename = g_dir_read_name (dir)) != NULL) {
		gchar *old_filename;
		gchar *new_filename;

		old_filename = g_build_filename (src_directory, basename, NULL);
		new_filename = g_build_filename (dst_directory, basename, NULL);

		g_hash_table_insert (corrections, old_filename, new_filename);
	}

	g_dir_close (dir);

	migrate_process_corrections (corrections);
	g_hash_table_destroy (corrections);

	/* It's tempting to want to remove the source directory here.
	 * Don't.  We might be iterating over the source directory's
	 * parent directory, and removing the source directory would
	 * screw up the iteration. */

	return TRUE;
}

static void
migrate_fix_exchange_bug (const gchar *old_base_dir)
{
	GDir *dir;
	GHashTable *corrections;
	const gchar *basename;
	gchar *exchange_dir;
	gchar *old_cache_dir;

	/* The exchange backend mistakenly cached calendar attachments in
	 * ~/.evolution/exchange instead of ~/.evolution/cache/calendar.
	 * Fix that before we migrate the cache directory. */

	exchange_dir = g_build_filename (old_base_dir, "exchange", NULL);
	old_cache_dir = g_build_filename (old_base_dir, "cache", "calendar", NULL);

	dir = g_dir_open (exchange_dir, 0, NULL);
	if (dir == NULL)
		goto exit;

	/* This is to avoid renaming files while we're iterating over the
	 * directory.  POSIX says the outcome of that is unspecified. */
	corrections = g_hash_table_new_full (
		g_str_hash, g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_free);

	while ((basename = g_dir_read_name (dir)) != NULL) {
		gchar *old_filename;
		gchar *new_filename;

		if (!g_str_has_prefix (basename, "exchange___"))
			continue;

		old_filename = g_build_filename (exchange_dir, basename, NULL);
		new_filename = g_build_filename (old_cache_dir, basename, NULL);

		g_hash_table_insert (corrections, old_filename, new_filename);
	}

	g_dir_close (dir);

	migrate_process_corrections (corrections);
	g_hash_table_destroy (corrections);

exit:
	g_free (exchange_dir);
	g_free (old_cache_dir);
}

static void
migrate_fix_memos_cache_bug (const gchar *old_base_dir)
{
	gchar *src_directory;
	gchar *dst_directory;

	/* Some calendar backends cached memo data under
	 * ~/.evolution/cache/journal instead of ~/.evolution/cache/memos.
	 * Fix that before we migrate the cache directory. */

	src_directory = g_build_filename (old_base_dir, "cache", "journal", NULL);
	dst_directory = g_build_filename (old_base_dir, "cache", "memos", NULL);

	migrate_move_contents (src_directory, dst_directory);
	migrate_rmdir (src_directory);

	g_free (src_directory);
	g_free (dst_directory);
}

static void
migrate_fix_groupwise_bug (const gchar *old_base_dir)
{
	GDir *dir;
	GHashTable *corrections;
	const gchar *basename;
	gchar *old_data_dir;
	gchar *old_cache_dir;

	/* The groupwise backend mistakenly put its addressbook
	 * cache files in ~/.evolution/addressbook instead of
	 * ~/.evolution/cache/addressbook.  Fix that before
	 * we migrate the cache directory. */

	old_data_dir = g_build_filename (old_base_dir, "addressbook", NULL);
	old_cache_dir = g_build_filename (old_base_dir, "cache", "addressbook", NULL);

	dir = g_dir_open (old_data_dir, 0, NULL);
	if (dir == NULL)
		goto exit;

	/* This is to avoid renaming files while we're iterating over the
	 * directory.  POSIX says the outcome of that is unspecified. */
	corrections = g_hash_table_new_full (
		g_str_hash, g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_free);

	while ((basename = g_dir_read_name (dir)) != NULL) {
		gchar *old_filename;
		gchar *new_filename;

		if (!g_str_has_prefix (basename, "groupwise___"))
			continue;

		old_filename = g_build_filename (old_data_dir, basename, NULL);
		new_filename = g_build_filename (old_cache_dir, basename, NULL);

		g_hash_table_insert (corrections, old_filename, new_filename);
	}

	g_dir_close (dir);

	migrate_process_corrections (corrections);
	g_hash_table_destroy (corrections);

exit:
	g_free (old_data_dir);
	g_free (old_cache_dir);
}

static void
migrate_to_user_cache_dir (const gchar *old_base_dir)
{
	const gchar *new_cache_dir;
	gchar *old_cache_dir;
	gchar *src_directory;
	gchar *dst_directory;

	old_cache_dir = g_build_filename (old_base_dir, "cache", NULL);
	new_cache_dir = e_get_user_cache_dir ();

	e_source_registry_debug_print ("Migrating cached backend data\n");

	/* We don't want to move the source directory directly because the
	 * destination directory may already exist with content.  Instead
	 * we want to merge the content of the source directory into the
	 * destination directory.
	 *
	 * For example, given:
	 *
	 *    $(src_directory)/A   and   $(dst_directory)/B
	 *    $(src_directory)/C
	 *
	 * we want to end up with:
	 *
	 *    $(dst_directory)/A
	 *    $(dst_directory)/B
	 *    $(dst_directory)/C
	 *
	 * Any name collisions will be left in the source directory.
	 */

	src_directory = g_build_filename (old_cache_dir, "addressbook", NULL);
	dst_directory = g_build_filename (new_cache_dir, "addressbook", NULL);

	migrate_move_contents (src_directory, dst_directory);
	migrate_rmdir (src_directory);

	g_free (src_directory);
	g_free (dst_directory);

	src_directory = g_build_filename (old_cache_dir, "calendar", NULL);
	dst_directory = g_build_filename (new_cache_dir, "calendar", NULL);

	migrate_move_contents (src_directory, dst_directory);
	migrate_rmdir (src_directory);

	g_free (src_directory);
	g_free (dst_directory);

	src_directory = g_build_filename (old_cache_dir, "memos", NULL);
	dst_directory = g_build_filename (new_cache_dir, "memos", NULL);

	migrate_move_contents (src_directory, dst_directory);
	migrate_rmdir (src_directory);

	g_free (src_directory);
	g_free (dst_directory);

	src_directory = g_build_filename (old_cache_dir, "tasks", NULL);
	dst_directory = g_build_filename (new_cache_dir, "tasks", NULL);

	migrate_move_contents (src_directory, dst_directory);
	migrate_rmdir (src_directory);

	g_free (src_directory);
	g_free (dst_directory);

	/* Try to remove the old cache directory.  Good chance this will
	 * fail on the first try, since Evolution puts stuff here too. */
	migrate_rmdir (old_cache_dir);

	g_free (old_cache_dir);
}

static void
migrate_to_user_data_dir (const gchar *old_base_dir)
{
	const gchar *new_data_dir;
	gchar *src_directory;
	gchar *dst_directory;

	new_data_dir = e_get_user_data_dir ();

	e_source_registry_debug_print ("Migrating local backend data\n");

	/* We don't want to move the source directory directly because the
	 * destination directory may already exist with content.  Instead
	 * we want to merge the content of the source directory into the
	 * destination directory.
	 *
	 * For example, given:
	 *
	 *    $(src_directory)/A   and   $(dst_directory)/B
	 *    $(src_directory)/C
	 *
	 * we want to end up with:
	 *
	 *    $(dst_directory)/A
	 *    $(dst_directory)/B
	 *    $(dst_directory)/C
	 *
	 * Any name collisions will be left in the source directory.
	 */

	src_directory = g_build_filename (old_base_dir, "addressbook", "local", NULL);
	dst_directory = g_build_filename (new_data_dir, "addressbook", NULL);

	migrate_move_contents (src_directory, dst_directory);
	migrate_rmdir (src_directory);

	g_free (src_directory);
	g_free (dst_directory);

	src_directory = g_build_filename (old_base_dir, "calendar", "local", NULL);
	dst_directory = g_build_filename (new_data_dir, "calendar", NULL);

	migrate_move_contents (src_directory, dst_directory);
	migrate_rmdir (src_directory);

	g_free (src_directory);
	g_free (dst_directory);

	src_directory = g_build_filename (old_base_dir, "memos", "local", NULL);
	dst_directory = g_build_filename (new_data_dir, "memos", NULL);

	migrate_move_contents (src_directory, dst_directory);
	migrate_rmdir (src_directory);

	g_free (src_directory);
	g_free (dst_directory);

	src_directory = g_build_filename (old_base_dir, "tasks", "local", NULL);
	dst_directory = g_build_filename (new_data_dir, "tasks", NULL);

	migrate_move_contents (src_directory, dst_directory);
	migrate_rmdir (src_directory);

	g_free (src_directory);
	g_free (dst_directory);

	/* XXX This is not really the right place to be migrating
	 *     exchange data, but since we already cleaned out the
	 *     cached attachment files from this directory, may as
	 *     well move the user accounts too while we're at it. */

	src_directory = g_build_filename (old_base_dir, "exchange", NULL);
	dst_directory = g_build_filename (new_data_dir, "exchange", NULL);

	migrate_move_contents (src_directory, dst_directory);
	migrate_rmdir (src_directory);

	g_free (src_directory);
	g_free (dst_directory);
}

void
evolution_source_registry_migrate_basedir (void)
{
	const gchar *home_dir;
	gchar *old_base_dir;

	/* XXX This blocks, but it's all just local directory
	 *     renames so it should be nearly instantaneous. */

	home_dir = g_get_home_dir ();
	old_base_dir = g_build_filename (home_dir, ".evolution", NULL);

	/* Is there even anything to migrate? */
	if (!g_file_test (old_base_dir, G_FILE_TEST_IS_DIR))
		goto exit;

	/* Miscellaneous tweaks before we start. */
	migrate_fix_exchange_bug (old_base_dir);
	migrate_fix_memos_cache_bug (old_base_dir);
	migrate_fix_groupwise_bug (old_base_dir);

	migrate_to_user_cache_dir (old_base_dir);
	migrate_to_user_data_dir (old_base_dir);

	/* Try to remove the old base directory.  Good chance this will
	 * fail on the first try, since Evolution puts stuff here too. */
	migrate_rmdir (old_base_dir);

exit:
	g_free (old_base_dir);
}
