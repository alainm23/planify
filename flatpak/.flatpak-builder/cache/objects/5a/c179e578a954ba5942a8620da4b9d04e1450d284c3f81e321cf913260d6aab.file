/*
 * evolution-source-registry-autoconfig.c
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
#include <string.h>
#include <glib/gstdio.h>

#include <libebackend/libebackend.h>
#include <camel/camel.h>

#include "evolution-source-registry-methods.h"

typedef struct _MergeSourceData {
	gchar *source_filename;
	gchar *path;
	GKeyFile *key_file;
} MergeSourceData;

typedef void (*MergeSourcePopulateHashtableFunc)(GHashTable *source,
						 GKeyFile *key_file,
						 const gchar *basename,
						 const gchar *filename);

static void
e_autoconfig_free_merge_source_data (gpointer mem)
{
	MergeSourceData *source_data = (MergeSourceData *) mem;

	if (source_data == NULL)
		return;

	g_free (source_data->source_filename);
	g_free (source_data->path);
	g_key_file_unref (source_data->key_file);
	g_free (source_data);
}

static void
populate_hashtable_autoconfig (GHashTable *sources,
                               GKeyFile *key_file,
                               const gchar *basename,
                               const gchar *filename)
{
	MergeSourceData *data;
	GError *local_error = NULL;
	gchar *uid, *val;

	val = g_key_file_get_value (key_file, E_SOURCE_EXTENSION_AUTOCONFIG, "Revision", &local_error);
	if (val == NULL) {
		e_source_registry_debug_print (
					"Autoconfig: Failed to read '%s': %s.\n",
					filename,
					local_error->message);
		g_error_free (local_error);
		return;
	}
	g_free (val);

	uid = g_strndup (basename, strlen (basename) - 7);

	data = g_new0 (MergeSourceData, 1);
	data->key_file = g_key_file_ref (key_file);
	data->path = g_strdup (filename);

	g_hash_table_insert (sources, uid, data);
	e_source_registry_debug_print (
				"Autoconfig: Found autoconfig source '%s'.\n",
				filename);
}

static void
populate_hashtable_home (GHashTable *sources,
                         GKeyFile *key_file,
                         const gchar *basename,
                         const gchar *filename)
{
	MergeSourceData *data;
	gchar *uid;

	if (!g_key_file_has_group (key_file, E_SOURCE_EXTENSION_AUTOCONFIG))
		return;

	uid = g_strndup (basename, strlen (basename) - 7);

	data = g_new0 (MergeSourceData, 1);
	data->key_file = g_key_file_ref (key_file);
	data->path = g_strdup (filename);
	g_hash_table_insert (sources, uid, data);
}

static gboolean
e_autoconfig_read_directory (const gchar *path,
			     GHashTable *sources,
			     MergeSourcePopulateHashtableFunc func,
			     GError **error)
{
	GDir *dir;
	const gchar *basename;

	dir = g_dir_open (path, 0, error);
	if (dir == NULL) {
		return FALSE;
	}

	while ((basename = g_dir_read_name (dir)) != NULL) {
		GKeyFile *key_file;
		gchar *filename;

		if (!g_str_has_suffix (basename, ".source"))
			continue;

		filename = g_build_filename (path, basename, NULL);

		key_file = g_key_file_new ();
		if (!g_key_file_load_from_file (key_file, filename, G_KEY_FILE_NONE, error)) {
			g_prefix_error (error, "Failed to load key file '%s': ", filename);
			g_free (filename);
			g_dir_close (dir);
			g_key_file_unref (key_file);
			return FALSE;
		}

		func (sources, key_file, basename, filename);
		g_free (filename);
		g_key_file_unref (key_file);
	}

	g_dir_close (dir);

	return TRUE;
}

static gchar *
autoconfig_build_signature_filename (const gchar *path,
				     const gchar *source_filename)
{
	const gchar *use_path;
	gchar *filename, *tmp_basename, *tmp_path = NULL;

	tmp_basename = g_path_get_basename (source_filename);
	g_return_val_if_fail (tmp_basename != NULL, NULL);
	g_return_val_if_fail (g_str_has_suffix (tmp_basename, ".source"), NULL);

	/* Remove the ".source" extension */
	tmp_basename[strlen (tmp_basename) - 7] = '\0';

	if (path) {
		use_path = path;
	} else {
		const gchar *config_dir = e_get_user_config_dir ();

		tmp_path = g_build_filename (config_dir, "signatures", NULL);
		g_mkdir_with_parents (tmp_path, 0700);

		use_path = tmp_path;
	}

	filename = g_build_filename (use_path, tmp_basename, NULL);

	g_free (tmp_basename);
	g_free (tmp_path);

	return filename;
}

static void
e_autoconfig_clean_orphans (GHashTable *autoconfig_sources,
			    GHashTable *home_sources)
{
	GList *keys;
	GList *index;

	keys = g_hash_table_get_keys (home_sources);

	for (index = keys; index != NULL; index = g_list_next (index)) {
		gchar *key = index->data;
		if (!g_hash_table_contains (autoconfig_sources, key)) {
			MergeSourceData *data = g_hash_table_lookup (home_sources, key);
			if (data != NULL) {
				/* if we fail to remove it, keep going */
				if (g_unlink (data->path) == -1) {
					e_source_registry_debug_print (
						"Autoconfig: Error removing orphan source '%s': %s.\n",
						data->path,
						g_strerror (errno));
				} else {
					e_source_registry_debug_print (
						"Autoconfig: Removed orphan source '%s'.\n",
						data->path);
				}

				g_hash_table_remove (home_sources, data->path);

				if (g_key_file_has_group (data->key_file, E_SOURCE_EXTENSION_MAIL_SIGNATURE)) {
					gchar *filename;

					filename = autoconfig_build_signature_filename (NULL, data->path);
					if (filename && g_file_test (filename, G_FILE_TEST_EXISTS)) {
						if (g_unlink (filename) == -1) {
							e_source_registry_debug_print (
								"Autoconfig: Error removing orphan signature '%s': %s.\n",
								filename,
								g_strerror (errno));
						} else {
							e_source_registry_debug_print (
								"Autoconfig: Removed orphan signature '%s'.\n",
								filename);
						}
					} else if (filename) {
						e_source_registry_debug_print (
							"Autoconfig: Error removing orphan signature '%s': File not found.\n",
							filename);
					}

					g_free (filename);
				}
			}
		}
	}

	g_list_free (keys);
}

typedef struct _ReplaceVariablesData {
	const gchar *source_path;
	GHashTable *user_variables;
} ReplaceVariablesData;

static gboolean
e_autoconfig_replace_vars_eval_cb (const GMatchInfo *match_info,
				   GString *result,
				   gpointer user_data)
{
	gchar *var_name;
	const gchar *val = NULL;
	ReplaceVariablesData *rvd = user_data;

	g_return_val_if_fail (rvd != NULL, FALSE);

	var_name = g_match_info_fetch (match_info, 1);

	if (var_name) {
		val = g_hash_table_lookup (rvd->user_variables, var_name);

		if (!val)
			val = g_getenv (var_name);
	}

	if (val != NULL) {
		g_string_append (result, val);
	} else {
		/* env var will be replaced by an empty string */
		e_source_registry_debug_print (
			"Autoconfig: Variable '${%s}' not found, used in '%s'.\n",
			var_name,
			rvd->source_path);
	}

	g_free (var_name);

	return FALSE;
}

static gchar *
e_autoconfig_replace_vars (const gchar *old,
			   const gchar *source_path,
			   GHashTable *user_variables)
{
	GRegex *regex;
	gchar *new;
	ReplaceVariablesData rvd;
	GError *local_error = NULL;

	g_return_val_if_fail (old != NULL, NULL);

	regex = g_regex_new ("\\$\\{(\\w+)\\}", 0, 0, NULL);

	g_return_val_if_fail (regex != NULL, g_strdup (old));

	rvd.source_path = source_path;
	rvd.user_variables = user_variables;

	new = g_regex_replace_eval (
				regex,
				old,
				-1,
				0,
				0,
				e_autoconfig_replace_vars_eval_cb,
				&rvd,
				&local_error);

	g_regex_unref (regex);

	if (new == NULL) {
		e_source_registry_debug_print (
			"Autoconfig: Replacing variables failed: %s.\n",
			local_error ? local_error->message : "Unknown error");
		g_error_free (local_error);
		return g_strdup (old);
	}

	return new;
}

static void
e_autoconfig_copy_source (MergeSourceData *target,
			  MergeSourceData *source,
			  GHashTable *user_variables)
{
	gchar **groups = NULL;
	gsize ngroups;
	gint ii;

	groups = g_key_file_get_groups (source->key_file, &ngroups);

	for (ii = 0; ii < ngroups; ii++) {
		gsize nkeys;
		gint jj;
		gchar **keys;

		keys = g_key_file_get_keys (source->key_file, groups[ii], &nkeys, NULL);

		for (jj = 0; jj < nkeys; jj++) {
			gchar *new_val;
			gchar *val = g_key_file_get_value (source->key_file, groups[ii], keys[jj], NULL);

			new_val = e_autoconfig_replace_vars (val, source->path, user_variables);

			g_free (val);

			g_key_file_set_value (target->key_file, groups[ii], keys[jj], new_val);

			g_free (new_val);
		}
		g_strfreev (keys);
	}

	g_strfreev (groups);
}

static gboolean
e_autoconfig_merge_source (GHashTable *home_sources,
			   const gchar *key,
			   MergeSourceData *autoconfig_key_file,
			   GList **key_files_to_copy,
			   GHashTable *user_variables,
			   GError **error)
{
	GKeyFile *new_keyfile;
	MergeSourceData *home_key_file;
	MergeSourceData *new_data;
	gboolean skip_copy;
	gchar *autoconfig_revision, *home_revision;

	g_return_val_if_fail (key_files_to_copy != NULL, FALSE);

	home_key_file = g_hash_table_lookup (home_sources, key);

	autoconfig_revision = g_key_file_get_value (
				autoconfig_key_file->key_file,
				E_SOURCE_EXTENSION_AUTOCONFIG,
				"Revision",
				error);
	if (autoconfig_revision == NULL) {
		g_prefix_error (
			error,
			"Failed to get revision of key file '%s': ",
			autoconfig_key_file->path);
		return FALSE;
	}

	home_revision = g_key_file_get_value (
				home_key_file->key_file,
				E_SOURCE_EXTENSION_AUTOCONFIG,
				"Revision",
				error);
	if (home_revision == NULL) {
		g_prefix_error (
			error,
			"Failed to get revision of key file '%s': ",
			home_key_file->path);
		g_free (autoconfig_revision);
		return FALSE;
	}

	skip_copy = g_strcmp0 (autoconfig_revision, home_revision) == 0;

	if (skip_copy) {
		e_source_registry_debug_print (
			"Autoconfig: Skipping update, revisions of '%s' and '%s' are the same ('%s').\n",
			home_key_file->path,
			autoconfig_key_file->path,
			home_revision);
		g_free (autoconfig_revision);
		g_free (home_revision);
		return TRUE;
	}

	e_source_registry_debug_print (
		"Autoconfig: Going to update '%s' (Revision '%s') with '%s' (Revision '%s').\n",
		home_key_file->path,
		home_revision,
		autoconfig_key_file->path,
		autoconfig_revision);

	g_free (autoconfig_revision);
	g_free (home_revision);

	new_keyfile = g_key_file_new ();

	if (!g_key_file_load_from_file (new_keyfile, home_key_file->path, G_KEY_FILE_NONE, error)) {
		g_prefix_error (
			error,
			"Failed to load key file '%s': ",
			home_key_file->path);
		g_key_file_unref (new_keyfile);
		return FALSE;
	}

	new_data = g_new0 (MergeSourceData, 1);
	new_data->source_filename = g_strdup (autoconfig_key_file->path);
	new_data->path = g_strdup (home_key_file->path);
	new_data->key_file = new_keyfile;

	e_autoconfig_copy_source (new_data, autoconfig_key_file, user_variables);

	*key_files_to_copy = g_list_prepend (*key_files_to_copy, new_data);

	return TRUE;
}

static void
e_autoconfig_generate_source_from_autoconfig (const gchar *key,
					      MergeSourceData *autoconfig_key_file,
					      GList **key_files_to_copy,
					      GHashTable *user_variables)
{
	GKeyFile *new_keyfile;
	MergeSourceData *new_data;
	gchar *dest_source_filename, *dest_source_path;

	g_return_if_fail (key_files_to_copy != NULL);

	dest_source_filename = g_strdup_printf ("%s.source", key);
	dest_source_path = g_build_filename (
					e_server_side_source_get_user_dir (),
					dest_source_filename,
					NULL);

	g_free (dest_source_filename);

	/* If we're here it means there was no file in home sources with an
	 * Autoconfig section that corresponds with autoconfig_key_file.
	 * In the unlikely event there's an existing file in home sources with
	 * the same name as autoconfig_key file, let's not include it in the
	 * list of files to copy to avoid data loss. */
	if (g_file_test (dest_source_path, G_FILE_TEST_EXISTS)) {
		e_source_registry_debug_print (
			"Autoconfig: Skipping '%s' due to an existing '%s' without '%s' section.\n",
			autoconfig_key_file->path, dest_source_path, E_SOURCE_EXTENSION_AUTOCONFIG);
		g_free (dest_source_path);
		return;
	}

	new_keyfile = g_key_file_new ();

	new_data = g_new0 (MergeSourceData, 1);
	new_data->source_filename = g_strdup (autoconfig_key_file->path);
	new_data->path = dest_source_path;
	new_data->key_file = new_keyfile;

	e_autoconfig_copy_source (new_data, autoconfig_key_file, user_variables);

	*key_files_to_copy = g_list_prepend (*key_files_to_copy, new_data);

	e_source_registry_debug_print (
		"Autoconfig: New source '%s'. It will be copied to '%s'.\n",
		autoconfig_key_file->path,
		new_data->path);
}

static GList *
e_autoconfig_merge_sources (GHashTable *autoconfig_sources,
			    GHashTable *home_sources,
			    GHashTable *user_variables)
{
	GHashTableIter iter;
	GList *key_files_to_copy = NULL;
	gpointer key, value;

	e_autoconfig_clean_orphans (autoconfig_sources, home_sources);

	g_hash_table_iter_init (&iter, autoconfig_sources);
	while (g_hash_table_iter_next (&iter, &key, &value)) {
		MergeSourceData *autoconfig_key_file = value;

		if (g_hash_table_contains (home_sources, key)) {
			GError *local_error = NULL;

			if (!e_autoconfig_merge_source (home_sources, key, autoconfig_key_file, &key_files_to_copy, user_variables, &local_error)) {
				e_source_registry_debug_print (
					"Autoconfig: Merge source failed: %s.\n",
					local_error ? local_error->message : "Unknown error");
				g_clear_error (&local_error);
				continue;
			}
		} else {
			e_autoconfig_generate_source_from_autoconfig (key, autoconfig_key_file, &key_files_to_copy, user_variables);
		}
	}

	return key_files_to_copy;
}

static gboolean
e_autoconfig_write_key_file (MergeSourceData *key_file_data,
			     GError **error)
{
	return g_key_file_save_to_file (key_file_data->key_file, key_file_data->path, error);
}

static gboolean
e_autoconfig_write_signature (MergeSourceData *key_file_data,
			      GHashTable *user_variables,
			      GError **error)
{
	gchar *tmp, *signature_src, *signature_dest;
	gboolean success;
	GError *local_error = NULL;

	g_return_val_if_fail (key_file_data != NULL, FALSE);
	g_return_val_if_fail (key_file_data->source_filename != NULL, FALSE);
	g_return_val_if_fail (g_str_has_suffix (key_file_data->source_filename, ".source"), FALSE);

	/* filename with path, without the ".source" extension */
	tmp = g_strndup (key_file_data->source_filename, strlen (key_file_data->source_filename) - 7);

	signature_src = g_strconcat (tmp, ".signature", NULL);

	g_free (tmp);

	if (!g_file_test (signature_src, G_FILE_TEST_EXISTS)) {
		e_source_registry_debug_print ("Autoconfig: Missing signature file '%s', skipping it.", signature_src);
		g_free (signature_src);

		/* return TRUE, to keep going */
		return TRUE;
	}

	signature_dest = autoconfig_build_signature_filename (NULL, key_file_data->source_filename);

	tmp = NULL;

	success = g_file_get_contents (signature_src, &tmp, NULL, &local_error);
	if (success) {
		gchar *value;

		value = e_autoconfig_replace_vars (tmp, signature_src, user_variables);
		if (value) {
			success = g_file_set_contents (signature_dest, value, -1, &local_error);
			if (!success) {
				e_source_registry_debug_print ("Autoconfig: Failed to write signature file '%s': %s",
					signature_dest, local_error ? local_error->message : "Unknown error");
			}

			g_free (value);
		} else {
			success = FALSE;
			e_source_registry_debug_print ("Autoconfig: Failed to replace variables in signature file '%s'",
				signature_src);
		}
	} else {
		e_source_registry_debug_print ("Autoconfig: Failed to read signature file '%s': %s",
			signature_src, local_error ? local_error->message : "Unknown error");
	}

	if (success) {
		GStatBuf sb;

		if (g_stat (signature_src, &sb) != -1 &&
		    g_chmod (signature_dest, sb.st_mode) == -1) {
			e_source_registry_debug_print (
				"Autoconfig: Failed to chmod() for '%s': %s\n",
				signature_dest, g_strerror (errno));
		}
	}

	if (local_error)
		g_propagate_error (error, local_error);

	g_free (signature_src);
	g_free (signature_dest);
	g_free (tmp);

	if (success)
		success = e_autoconfig_write_key_file (key_file_data, error);

	return success;
}

static gboolean
e_autoconfig_write_key_files (GList *list,
			      GHashTable *user_variables,
			      GError **error)
{
	GList *index;
	gboolean success = TRUE;

	for (index = list; index && success; index = g_list_next (index)) {
		MergeSourceData *data;

		data = index->data;

		if (data == NULL)
			continue;

		if (g_key_file_has_group (data->key_file, E_SOURCE_EXTENSION_MAIL_SIGNATURE))
			success = e_autoconfig_write_signature (data, user_variables, error);
		else
			success = e_autoconfig_write_key_file (data, error);
	}

	return TRUE;
}

static GHashTable *
e_autoconfig_read_user_variables (GSettings *settings)
{
	GHashTable *variables;
	gchar **strv;
	gint ii;

	g_return_val_if_fail (G_IS_SETTINGS (settings), NULL);

	variables = g_hash_table_new_full (camel_strcase_hash, camel_strcase_equal, g_free, g_free);

	strv = g_settings_get_strv (settings, "autoconfig-variables");
	if (!strv || !strv[0]) {
		g_strfreev (strv);

		return variables;
	}

	for (ii = 0; strv[ii]; ii++) {
		const gchar *line = strv[ii];
		gchar *name, *value, *sep;

		if (!*line)
			continue;

		sep = strchr (line, '=');
		if (!sep || sep == line) {
			e_source_registry_debug_print ("Autoconfig: GSettings' autoconfig-variables line '%s' doesn't conform format 'name=value'.\n", line);
			continue;
		}

		name = g_strdup (line);
		sep = strchr (name, '=');
		if (!sep || sep == name) {
			g_free (name);
			g_warn_if_reached ();
			continue;
		}

		*sep = '\0';
		value = sep + 1;

		if (g_hash_table_contains (variables, name))
			e_source_registry_debug_print ("Autoconfig: GSettings' autoconfig-variables key contains multiple '%s' variables.\n", name);

		g_hash_table_insert (variables, name, g_strdup (value));
	}

	g_strfreev (strv);

	return variables;
}

gboolean
evolution_source_registry_merge_autoconfig_sources (ESourceRegistryServer *server,
						    GError **error)
{
	GHashTable *home_sources = NULL, *autoconfig_sources = NULL, *user_variables = NULL;
	GList *key_files_to_copy = NULL;
	GSettings *settings;
	GError *local_error = NULL;
	gboolean success = FALSE;
	const gchar * const *config_dirs;
	gchar *autoconfig_directory;
	gint ii;

	settings = g_settings_new ("org.gnome.evolution-data-server");

	autoconfig_sources = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, e_autoconfig_free_merge_source_data);

	config_dirs = g_get_system_config_dirs ();
	for (ii = 0; config_dirs[ii]; ii++) {
		gchar *path;

		path = g_build_filename (config_dirs[ii], "evolution-data-server", "autoconfig", NULL);
		success = e_autoconfig_read_directory (path, autoconfig_sources, populate_hashtable_autoconfig, &local_error);

		g_free (path);

		if (!success) {
			if (local_error != NULL &&
			    g_error_matches (local_error, G_FILE_ERROR, G_FILE_ERROR_NOENT)) {
				g_clear_error (&local_error);
				continue;
			}

			goto exit;
		}
	}

	autoconfig_directory = g_settings_get_string (settings, "autoconfig-directory");
	if (autoconfig_directory && *autoconfig_directory) {
		if (g_file_test (autoconfig_directory, G_FILE_TEST_IS_DIR)) {
			success = e_autoconfig_read_directory (autoconfig_directory, autoconfig_sources, populate_hashtable_autoconfig, &local_error);

			if (!success) {
				if (local_error != NULL &&
				    g_error_matches (local_error, G_FILE_ERROR, G_FILE_ERROR_NOENT)) {
					g_clear_error (&local_error);
				} else {
					g_free (autoconfig_directory);
					goto exit;
				}
			}
		} else {
			e_source_registry_debug_print ("Autoconfig: Skipping GSettings' autoconfig-directory '%s', either it doesn't exist, or it's currently unavailable.\n", autoconfig_directory);
		}
	}

	g_free (autoconfig_directory);

	home_sources = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, e_autoconfig_free_merge_source_data);

	success = e_autoconfig_read_directory (e_server_side_source_get_user_dir (), home_sources, populate_hashtable_home, &local_error);

	if (!success)
		goto exit;

	user_variables = e_autoconfig_read_user_variables (settings);
	g_warn_if_fail (user_variables != NULL);

	/* Add these last, to override any user-specified */
	g_hash_table_insert (user_variables, g_strdup ("USER"), g_strdup (g_get_user_name ()));
	g_hash_table_insert (user_variables, g_strdup ("REALNAME"), g_strdup (g_get_real_name ()));
	g_hash_table_insert (user_variables, g_strdup ("HOST"), g_strdup (g_get_host_name ()));

	key_files_to_copy = e_autoconfig_merge_sources (autoconfig_sources, home_sources, user_variables);

	success = e_autoconfig_write_key_files (key_files_to_copy, user_variables, error);

 exit:
	if (autoconfig_sources != NULL)
		g_hash_table_unref (autoconfig_sources);
	if (home_sources != NULL)
		g_hash_table_unref (home_sources);
	if (user_variables)
		g_hash_table_unref (user_variables);
	if (key_files_to_copy != NULL)
		g_list_free_full (key_files_to_copy, e_autoconfig_free_merge_source_data);
	g_clear_object (&settings);

	if (local_error != NULL)
		g_propagate_error (error, local_error);

	return success;
}
