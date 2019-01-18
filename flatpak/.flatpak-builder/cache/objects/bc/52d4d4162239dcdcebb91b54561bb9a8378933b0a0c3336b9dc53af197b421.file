/*
 * e-cache-reaper-utils.c
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

#include "e-cache-reaper-utils.h"

#include <libedataserver/libedataserver.h>

#define REAPING_DIRECTORY_NAME ".reaping"

/* Helper for e_reap_trash_directory() */
static void
reap_trash_directory_thread (GSimpleAsyncResult *simple,
                             GObject *object,
                             GCancellable *cancellable)
{
	gssize expiry_in_days;
	GError *error = NULL;

	expiry_in_days = g_simple_async_result_get_op_res_gssize (simple);

	e_reap_trash_directory_sync (
		G_FILE (object),
		(gint) expiry_in_days,
		cancellable, &error);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);
}

gboolean
e_reap_trash_directory_sync (GFile *trash_directory,
                             gint expiry_in_days,
                             GCancellable *cancellable,
                             GError **error)
{
	GFileEnumerator *file_enumerator;
	GQueue directories = G_QUEUE_INIT;
	GFile *reaping_directory;
	GFileInfo *file_info;
	const gchar *attributes;
	gboolean success = TRUE;
	GError *local_error = NULL;

	g_return_val_if_fail (G_IS_FILE (trash_directory), FALSE);
	g_return_val_if_fail (expiry_in_days > 0, FALSE);

	reaping_directory = g_file_get_child (
		trash_directory, REAPING_DIRECTORY_NAME);

	attributes =
		G_FILE_ATTRIBUTE_STANDARD_NAME ","
		G_FILE_ATTRIBUTE_STANDARD_TYPE ","
		G_FILE_ATTRIBUTE_TIME_MODIFIED;

	file_enumerator = g_file_enumerate_children (
		trash_directory, attributes,
		G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS,
		cancellable, error);

	if (file_enumerator == NULL)
		return FALSE;

	file_info = g_file_enumerator_next_file (
		file_enumerator, cancellable, &local_error);

	while (file_info != NULL) {
		GFileType file_type;
		GTimeVal mtime;
		GDate *date_now;
		GDate *date_mtime;
		const gchar *name;
		gboolean reap_it;
		gint days_old;

		name = g_file_info_get_name (file_info);
		file_type = g_file_info_get_file_type (file_info);
		g_file_info_get_modification_time (file_info, &mtime);

		/* Calculate how many days ago the file was modified. */
		date_now = g_date_new ();
		g_date_set_time_t (date_now, time (NULL));
		date_mtime = g_date_new ();
		g_date_set_time_val (date_mtime, &mtime);
		days_old = g_date_days_between (date_mtime, date_now);
		g_date_free (date_mtime);
		g_date_free (date_now);

		reap_it =
			(file_type == G_FILE_TYPE_DIRECTORY) &&
			(days_old >= expiry_in_days);

		if (reap_it) {
			GFile *child;

			child = g_file_get_child (trash_directory, name);

			/* If we find an unfinished reaping directory, put
			 * it on the head of the queue so we reap it first. */
			if (g_file_equal (child, reaping_directory))
				g_queue_push_head (&directories, child);
			else
				g_queue_push_tail (&directories, child);
		}

		g_object_unref (file_info);

		file_info = g_file_enumerator_next_file (
			file_enumerator, cancellable, &local_error);
	}

	if (local_error != NULL) {
		g_propagate_error (error, local_error);
		success = FALSE;
	}

	g_object_unref (file_enumerator);

	/* Now delete the directories we've queued up. */
	while (success && !g_queue_is_empty (&directories)) {
		GFile *directory;

		directory = g_queue_pop_head (&directories);

		/* First we rename the directory to prevent it
		 * from being recovered while being deleted. */
		if (!g_file_equal (directory, reaping_directory))
			success = g_file_move (
				directory, reaping_directory,
				G_FILE_COPY_NONE, cancellable,
				NULL, NULL, error);

		if (success)
			success = e_file_recursive_delete_sync (
				reaping_directory, cancellable, error);

		g_object_unref (directory);
	}

	/* Flush the queue in case we aborted on an error. */
	while (!g_queue_is_empty (&directories))
		g_object_unref (g_queue_pop_head (&directories));

	g_object_unref (reaping_directory);

	return success;
}

void
e_reap_trash_directory (GFile *trash_directory,
                        gint expiry_in_days,
                        gint io_priority,
                        GCancellable *cancellable,
                        GAsyncReadyCallback callback,
                        gpointer user_data)
{
	GSimpleAsyncResult *simple;

	g_return_if_fail (G_IS_FILE (trash_directory));
	g_return_if_fail (expiry_in_days > 0);

	simple = g_simple_async_result_new (
		G_OBJECT (trash_directory), callback,
		user_data, e_reap_trash_directory);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gssize (simple, expiry_in_days);

	g_simple_async_result_run_in_thread (
		simple, reap_trash_directory_thread,
		io_priority, cancellable);

	g_object_unref (simple);
}

gboolean
e_reap_trash_directory_finish (GFile *trash_directory,
                               GAsyncResult *result,
                               GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (trash_directory),
		e_reap_trash_directory), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

