/*
 * e-cache-reaper.c
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
#include <time.h>
#include <glib/gstdio.h>

#include <libebackend/libebackend.h>

#include "e-cache-reaper.h"
#include "e-cache-reaper-utils.h"

/* Where abandoned directories go to die. */
#define TRASH_DIRECTORY_NAME "trash"

/* XXX These intervals are rather arbitrary and prone to bikeshedding.
 *     It's just what I decided on.  On startup we wait an hour to reap
 *     abandoned directories, and thereafter repeat every 24 hours. */
#define INITIAL_INTERVAL_SECONDS  ( 1 * (60 * 60))
#define REGULAR_INTERVAL_SECONDS  (24 * (60 * 60))

/* XXX Similarly, these expiry times are rather arbitrary and prone to
 *     bikeshedding.  Most importantly, the expiry for data directories
 *     should be far more conservative (longer) than cache directories.
 *     Cache directories are disposable, data directories are not, so
 *     we want to let abandoned data directories linger longer. */

/* Minimum days for a data directory
 * to live in trash before reaping it. */
#define DATA_EXPIRY_IN_DAYS 28

/* Minimum days for a cache directory
 * to live in trash before reaping it. */
#define CACHE_EXPIRY_IN_DAYS 7

struct _ECacheReaper {
	EExtension parent;

	guint n_data_directories;
	GFile **data_directories;
	GFile **data_trash_directories;

	guint n_cache_directories;
	GFile **cache_directories;
	GFile **cache_trash_directories;

	guint reaping_timeout_id;

	GSList *private_directories;
};

struct _ECacheReaperClass {
	EExtensionClass parent_class;
};

G_DEFINE_DYNAMIC_TYPE_EXTENDED (ECacheReaper, e_cache_reaper, E_TYPE_EXTENSION, 0,
	G_IMPLEMENT_INTERFACE_DYNAMIC (E_TYPE_EXTENSIBLE, NULL))

static ESourceRegistryServer *
cache_reaper_get_server (ECacheReaper *extension)
{
	EExtensible *extensible;

	extensible = e_extension_get_extensible (E_EXTENSION (extension));

	return E_SOURCE_REGISTRY_SERVER (extensible);
}

static gboolean
cache_reaper_make_directory_and_parents (GFile *directory,
                                         GCancellable *cancellable,
                                         GError **error)
{
	gboolean success;
	GError *local_error = NULL;

	/* XXX Maybe add some function like this to libedataserver.
	 *     It's annoying to always have to check for and clear
	 *     G_IO_ERROR_EXISTS when ensuring a directory exists. */

	success = g_file_make_directory_with_parents (
		directory, cancellable, &local_error);

	if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_EXISTS))
		g_clear_error (&local_error);

	if (local_error != NULL) {
		gchar *path;

		g_propagate_error (error, local_error);

		path = g_file_get_path (directory);
		g_prefix_error (
			error, "Failed to make directory '%s': ", path);
		g_free (path);
	}

	return success;
}

static void
cache_reaper_trash_directory_reaped (GObject *source_object,
                                     GAsyncResult *result,
                                     gpointer unused)
{
	GFile *trash_directory;
	GError *error = NULL;

	trash_directory = G_FILE (source_object);

	e_reap_trash_directory_finish (trash_directory, result, &error);

	/* Ignore cancellations. */
	if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
		/* do nothing */

	} else if (error != NULL) {
		gchar *path;

		path = g_file_get_path (trash_directory);
		g_warning ("Failed to reap '%s': %s", path, error->message);
		g_free (path);
	}

	g_clear_error (&error);
}

static gboolean
cache_reaper_reap_trash_directories (gpointer user_data)
{
	ECacheReaper *extension = E_CACHE_REAPER (user_data);
	guint ii;

	g_debug ("Reaping abandoned data directories");

	for (ii = 0; ii < extension->n_data_directories; ii++)
		e_reap_trash_directory (
			extension->data_trash_directories[ii],
			DATA_EXPIRY_IN_DAYS,
			G_PRIORITY_LOW, NULL,
			cache_reaper_trash_directory_reaped,
			NULL);

	g_debug ("Reaping abandoned cache directories");

	for (ii = 0; ii < extension->n_cache_directories; ii++)
		e_reap_trash_directory (
			extension->cache_trash_directories[ii],
			CACHE_EXPIRY_IN_DAYS,
			G_PRIORITY_LOW, NULL,
			cache_reaper_trash_directory_reaped,
			NULL);

	/* Always explicitly reschedule since the initial
	 * interval is different than the regular interval. */
	extension->reaping_timeout_id =
		e_named_timeout_add_seconds (
			REGULAR_INTERVAL_SECONDS,
			cache_reaper_reap_trash_directories,
			extension);

	return FALSE;
}

static void
cache_reaper_move_directory (GFile *source_directory,
                             GFile *target_directory)
{
	GFileType file_type;
	GError *error = NULL;

	/* Make sure the source directory is really a directory. */

	file_type = g_file_query_file_type (
		source_directory,
		G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS, NULL);

	if (file_type == G_FILE_TYPE_DIRECTORY) {
		g_file_move (
			source_directory,
			target_directory,
			G_FILE_COPY_NOFOLLOW_SYMLINKS,
			NULL, NULL, NULL, &error);

		/* Update the target directory's modification time.
		 * This step is not critical, do not set the GError. */
		if (error == NULL) {
			time_t now = time (NULL);

			g_file_set_attribute (
				target_directory,
				G_FILE_ATTRIBUTE_TIME_MODIFIED,
				G_FILE_ATTRIBUTE_TYPE_UINT64,
				&now, G_FILE_QUERY_INFO_NONE,
				NULL, NULL);
		}
	}

	if (error != NULL) {
		gchar *path;

		path = g_file_get_path (source_directory);
		g_warning ("Failed to move '%s': %s", path, error->message);
		g_free (path);

		g_error_free (error);
	}
}

static gboolean
cache_reaper_skip_directory (ECacheReaper *cache_reaper,
			     const gchar *name)
{
	GSList *link;

	/* Skip the trash directory, obviously. */
	if (g_strcmp0 (name, TRASH_DIRECTORY_NAME) == 0)
		return TRUE;

	/* Also skip directories named "system".  For backward
	 * compatibility, data directories for built-in sources
	 * are named "system" instead of "system-address-book"
	 * or "system-calendar" or what have you. */
	if (g_strcmp0 (name, "system") == 0)
		return TRUE;

	for (link = cache_reaper->private_directories; link; link = g_slist_next (link)) {
		if (g_strcmp0 (name, link->data) == 0) {
			return TRUE;
		}
	}

	return FALSE;
}

static void
cache_reaper_scan_directory (ECacheReaper *extension,
                             GFile *base_directory,
                             GFile *trash_directory)
{
	GFileEnumerator *file_enumerator;
	ESourceRegistryServer *server;
	GFileInfo *file_info;
	GError *error = NULL;

	server = cache_reaper_get_server (extension);

	file_enumerator = g_file_enumerate_children (
		base_directory,
		G_FILE_ATTRIBUTE_STANDARD_NAME,
		G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS,
		NULL, &error);

	if (error != NULL) {
		g_warn_if_fail (file_enumerator == NULL);
		goto exit;
	}

	g_return_if_fail (G_IS_FILE_ENUMERATOR (file_enumerator));

	file_info = g_file_enumerator_next_file (
		file_enumerator, NULL, &error);

	while (file_info != NULL) {
		ESource *source;
		const gchar *name;

		name = g_file_info_get_name (file_info);

		if (cache_reaper_skip_directory (extension, name))
			goto next;

		source = e_source_registry_server_ref_source (server, name);

		if (source == NULL) {
			GFile *source_directory;
			GFile *target_directory;

			source_directory = g_file_get_child (
				base_directory, name);
			target_directory = g_file_get_child (
				trash_directory, name);

			cache_reaper_move_directory (
				source_directory, target_directory);

			g_object_unref (source_directory);
			g_object_unref (target_directory);
		} else {
			g_object_unref (source);
		}

next:
		g_object_unref (file_info);

		file_info = g_file_enumerator_next_file (
			file_enumerator, NULL, &error);
	}

	g_object_unref (file_enumerator);

exit:
	if (error != NULL) {
		gchar *path;

		path = g_file_get_path (base_directory);
		g_warning ("Failed to scan '%s': %s", path, error->message);
		g_free (path);

		g_error_free (error);
	}
}

static void
cache_reaper_scan_data_directories (ECacheReaper *extension)
{
	guint ii;

	/* Scan the base data directories for unrecognized subdirectories.
	 * The subdirectories are named after data source UIDs, so compare
	 * their names to registered data sources and move any unrecognized
	 * subdirectories to the "trash" subdirectory to be reaped later. */

	g_debug ("Scanning data directories");

	for (ii = 0; ii < extension->n_data_directories; ii++)
		cache_reaper_scan_directory (
			extension,
			extension->data_directories[ii],
			extension->data_trash_directories[ii]);
}

static void
cache_reaper_scan_cache_directories (ECacheReaper *extension)
{
	guint ii;

	/* Scan the base cache directories for unrecognized subdirectories.
	 * The subdirectories are named after data source UIDs, so compare
	 * their names to registered data sources and move any unrecognized
	 * subdirectories to the "trash" subdirectory to be reaped later. */

	g_debug ("Scanning cache directories");

	for (ii = 0; ii < extension->n_cache_directories; ii++)
		cache_reaper_scan_directory (
			extension,
			extension->cache_directories[ii],
			extension->cache_trash_directories[ii]);
}

static void
cache_reaper_move_to_trash (ECacheReaper *extension,
                            ESource *source,
                            GFile *base_directory,
                            GFile *trash_directory)
{
	GFile *source_directory;
	GFile *target_directory;
	const gchar *uid;

	uid = e_source_get_uid (source);

	source_directory = g_file_get_child (base_directory, uid);
	target_directory = g_file_get_child (trash_directory, uid);

	/* This is a no-op if the source directory does not exist. */
	cache_reaper_move_directory (source_directory, target_directory);

	g_object_unref (source_directory);
	g_object_unref (target_directory);
}

static void
cache_reaper_recover_from_trash (ECacheReaper *extension,
                                 const gchar *directory_uid,
                                 GFile *base_directory,
                                 GFile *trash_directory)
{
	GFile *source_directory;
	GFile *target_directory;

	source_directory = g_file_get_child (trash_directory, directory_uid);
	target_directory = g_file_get_child (base_directory, directory_uid);

	/* This is a no-op if the source directory does not exist. */
	cache_reaper_move_directory (source_directory, target_directory);

	g_object_unref (source_directory);
	g_object_unref (target_directory);
}

static void
cache_reaper_recover_for_uid (ECacheReaper *extension,
			      const gchar *uid)
{
	guint ii;

	/* The Cache Reaper is not too proud to dig through the
	 * trash on the off chance the newly-added source has a
	 * recoverable data or cache directory. */

	for (ii = 0; ii < extension->n_data_directories; ii++)
		cache_reaper_recover_from_trash (
			extension, uid,
			extension->data_directories[ii],
			extension->data_trash_directories[ii]);

	for (ii = 0; ii < extension->n_cache_directories; ii++)
		cache_reaper_recover_from_trash (
			extension, uid,
			extension->cache_directories[ii],
			extension->cache_trash_directories[ii]);
}

static void
cache_reaper_files_loaded_cb (ESourceRegistryServer *server,
                              ECacheReaper *extension)
{
	GSList *link;

	cache_reaper_scan_data_directories (extension);
	cache_reaper_scan_cache_directories (extension);

	/* Schedule the initial reaping. */
	if (extension->reaping_timeout_id == 0) {
		extension->reaping_timeout_id =
			e_named_timeout_add_seconds (
				INITIAL_INTERVAL_SECONDS,
				cache_reaper_reap_trash_directories,
				extension);
	}

	for (link = extension->private_directories; link; link = g_slist_next (link)) {
		const gchar *directory = link->data;

		if (directory && *directory)
			cache_reaper_recover_for_uid (extension, directory);
	}
}

static void
cache_reaper_source_added_cb (ESourceRegistryServer *server,
                              ESource *source,
                              ECacheReaper *extension)
{
	cache_reaper_recover_for_uid (extension, e_source_get_uid (source));
}

static void
cache_reaper_source_removed_cb (ESourceRegistryServer *server,
                                ESource *source,
                                ECacheReaper *extension)
{
	guint ii;

	/* Stage the removed source's cache directory for reaping
	 * by moving it to the "trash" directory.
	 *
	 * Do NOT do this for data directories.  Cache directories
	 * are disposable and can be regenerated from the canonical
	 * data source, but data directories ARE the canonical data
	 * source so we want to be more conservative with them.  If
	 * the removed source has a data directory, we will move it
	 * to the "trash" directory on next registry startup, which
	 * may correspond with the next desktop session startup. */

	for (ii = 0; ii < extension->n_cache_directories; ii++)
		cache_reaper_move_to_trash (
			extension, source,
			extension->cache_directories[ii],
			extension->cache_trash_directories[ii]);
}

static void
cache_reaper_finalize (GObject *object)
{
	ECacheReaper *extension;
	guint ii;

	extension = E_CACHE_REAPER (object);

	for (ii = 0; ii < extension->n_data_directories; ii++) {
		g_object_unref (extension->data_directories[ii]);
		g_object_unref (extension->data_trash_directories[ii]);
	}

	g_free (extension->data_directories);
	g_free (extension->data_trash_directories);

	for (ii = 0; ii < extension->n_cache_directories; ii++) {
		g_object_unref (extension->cache_directories[ii]);
		g_object_unref (extension->cache_trash_directories[ii]);
	}

	g_free (extension->cache_directories);
	g_free (extension->cache_trash_directories);

	if (extension->reaping_timeout_id > 0)
		g_source_remove (extension->reaping_timeout_id);

	g_slist_free_full (extension->private_directories, g_free);
	extension->private_directories = NULL;

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_cache_reaper_parent_class)->finalize (object);
}

static void
cache_reaper_constructed (GObject *object)
{
	EExtension *extension;
	EExtensible *extensible;

	extension = E_EXTENSION (object);
	extensible = e_extension_get_extensible (extension);

	g_signal_connect (
		extensible, "files-loaded",
		G_CALLBACK (cache_reaper_files_loaded_cb), extension);

	g_signal_connect (
		extensible, "source-added",
		G_CALLBACK (cache_reaper_source_added_cb), extension);

	g_signal_connect (
		extensible, "source-removed",
		G_CALLBACK (cache_reaper_source_removed_cb), extension);

	e_extensible_load_extensions (E_EXTENSIBLE (object));

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_cache_reaper_parent_class)->constructed (object);
}

static void
e_cache_reaper_class_init (ECacheReaperClass *class)
{
	GObjectClass *object_class;
	EExtensionClass *extension_class;

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = cache_reaper_finalize;
	object_class->constructed = cache_reaper_constructed;

	extension_class = E_EXTENSION_CLASS (class);
	extension_class->extensible_type = E_TYPE_SOURCE_REGISTRY_SERVER;
}

static void
e_cache_reaper_class_finalize (ECacheReaperClass *class)
{
}

static void
e_cache_reaper_init (ECacheReaper *extension)
{
	GFile *base_directory;
	const gchar *user_data_dir;
	const gchar *user_cache_dir;
	guint n_directories, ii;

	/* These are component names from which
	 * the data directory arrays are built. */
	const gchar *data_component_names[] = {
		"addressbook",
		"calendar",
		"mail",
		"memos",
		"tasks"
	};

	/* These are component names from which
	 * the cache directory arrays are built. */
	const gchar *cache_component_names[] = {
		"addressbook",
		"calendar",
		"mail",
		"memos",
		"sources",
		"tasks"
	};

	extension->private_directories = NULL;

	/* Setup base directories for data. */

	n_directories = G_N_ELEMENTS (data_component_names);

	extension->n_data_directories = n_directories;
	extension->data_directories = g_new0 (GFile *, n_directories);
	extension->data_trash_directories = g_new0 (GFile *, n_directories);

	user_data_dir = e_get_user_data_dir ();
	base_directory = g_file_new_for_path (user_data_dir);

	for (ii = 0; ii < n_directories; ii++) {
		GFile *data_directory;
		GFile *trash_directory;
		GError *error = NULL;

		data_directory = g_file_get_child (
			base_directory, data_component_names[ii]);
		trash_directory = g_file_get_child (
			data_directory, TRASH_DIRECTORY_NAME);

		/* Data directory is a parent of the trash
		 * directory so this is sufficient for both. */
		cache_reaper_make_directory_and_parents (
			trash_directory, NULL, &error);

		if (error != NULL) {
			g_warning ("%s: %s", G_STRFUNC, error->message);
			g_error_free (error);
		}

		extension->data_directories[ii] = data_directory;
		extension->data_trash_directories[ii] = trash_directory;
	}

	g_object_unref (base_directory);

	/* Setup base directories for cache. */

	n_directories = G_N_ELEMENTS (cache_component_names);

	extension->n_cache_directories = n_directories;
	extension->cache_directories = g_new0 (GFile *, n_directories);
	extension->cache_trash_directories = g_new0 (GFile *, n_directories);

	user_cache_dir = e_get_user_cache_dir ();
	base_directory = g_file_new_for_path (user_cache_dir);

	for (ii = 0; ii < n_directories; ii++) {
		GFile *cache_directory;
		GFile *trash_directory;
		GError *error = NULL;

		cache_directory = g_file_get_child (
			base_directory, cache_component_names[ii]);
		trash_directory = g_file_get_child (
			cache_directory, TRASH_DIRECTORY_NAME);

		/* Cache directory is a parent of the trash
		 * directory so this is sufficient for both. */
		cache_reaper_make_directory_and_parents (
			trash_directory, NULL, &error);

		if (error != NULL) {
			g_warning ("%s: %s", G_STRFUNC, error->message);
			g_error_free (error);
		}

		extension->cache_directories[ii] = cache_directory;
		extension->cache_trash_directories[ii] = trash_directory;
	}

	g_object_unref (base_directory);
}

/**
 * e_cache_reaper_add_private_directory:
 * @cache_reaper: an #ECacheReaper
 * @name: directory name
 *
 * Let's the @cache_reaper know about a private directory named @name,
 * thus it won't delete it from cache or data directories. The @name
 * is just a directory name, not a path.
 *
 * Since 3.18
 **/
void
e_cache_reaper_add_private_directory (ECacheReaper *cache_reaper,
				      const gchar *name)
{
	g_return_if_fail (E_IS_CACHE_REAPER (cache_reaper));
	g_return_if_fail (name != NULL);

	if (g_slist_find_custom (cache_reaper->private_directories, name, (GCompareFunc) g_strcmp0))
		return;

	cache_reaper->private_directories = g_slist_prepend (cache_reaper->private_directories, g_strdup (name));

	cache_reaper_recover_for_uid (cache_reaper, name);
}

/**
 * e_cache_reaper_remove_private_directory:
 * @cache_reaper: an #ECacheReaper
 * @name: directory name
 *
 * Remove private directory named @name from the list of private
 * directories in the @cache_reaper, previously added with
 * e_cache_reaper_add_private_directory().
 *
 * Since 3.18
 **/
void
e_cache_reaper_remove_private_directory (ECacheReaper *cache_reaper,
					 const gchar *name)
{
	GSList *link;
	gchar *saved_name;

	g_return_if_fail (E_IS_CACHE_REAPER (cache_reaper));
	g_return_if_fail (name != NULL);

	link = g_slist_find_custom (cache_reaper->private_directories, name, (GCompareFunc) g_strcmp0);
	if (!link)
		return;

	saved_name = link->data;

	cache_reaper->private_directories = g_slist_remove (cache_reaper->private_directories, saved_name);

	g_free (saved_name);
}

void
e_cache_reaper_type_register (GTypeModule *type_module)
{
	e_cache_reaper_register_type (type_module);
}
