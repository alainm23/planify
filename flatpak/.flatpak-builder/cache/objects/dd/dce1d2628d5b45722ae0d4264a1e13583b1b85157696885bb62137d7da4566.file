/*
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

#include <libebackend/libebackend.h>

#include "evolution-source-registry-methods.h"

static gboolean
evolution_source_registry_migrate_imap_to_imapx (ESourceRegistryServer *server,
                                                 GKeyFile *key_file,
                                                 const gchar *uid)
{
	GHashTable *settings;
	const gchar *group_name;
	gboolean backend_is_imap;
	gchar *trash_name;
	gchar *cache_dir;
	gchar *trash_dir;
	gchar *value;
	gint ii;

	const gchar *imap_keys[] = {
		"CheckAll",
		"CheckSubscribed",
		"FilterAll",
		"FilterJunk",
		"FilterJunkInbox",
		"Namespace",
		"RealJunkPath",
		"RealTrashPath",
		"ShellCommand",
		"UseNamespace",
		"UseRealJunkPath",
		"UseRealTrashPath",
		"UseShellCommand"
	};

	/* Convert mail accounts with BackendName=imap to imapx. */

	group_name = E_SOURCE_EXTENSION_MAIL_ACCOUNT;
	if (!g_key_file_has_group (key_file, group_name))
		return FALSE;

	value = g_key_file_get_string (
		key_file, group_name, "BackendName", NULL);
	backend_is_imap = (g_strcmp0 (value, "imap") == 0);
	g_free (value);

	if (!backend_is_imap)
		return FALSE;

	e_source_registry_debug_print ("Converting %s from IMAP to IMAPX\n", uid);

	g_key_file_set_string (key_file, group_name, "BackendName", "imapx");

	/* Gather IMAP backend settings into a hash table. */

	settings = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_free);

	group_name = e_source_camel_get_extension_name ("imap");

	if (g_key_file_has_group (key_file, group_name)) {
		gchar **keys;
		gint ii;

		keys = g_key_file_get_keys (
			key_file, group_name, NULL, NULL);

		for (ii = 0; keys != NULL && keys[ii] != NULL; ii++) {
			/* Hash table takes ownership of key and value. */
			value = g_key_file_get_value (
				key_file, group_name, keys[ii], NULL);
			g_hash_table_insert (settings, keys[ii], value);
			keys[ii] = NULL;
		}

		/* Use g_free() instead of g_strfreev() since we
		 * stripped the array of its strings.  It's just
		 * an array of NULL pointers now. */
		g_free (keys);

		g_key_file_remove_group (key_file, group_name, NULL);
	}

	/* Translate IMAP settings into IMAPX settings.  Fortunately
	 * all matching settings are identical in name and data type. */

	group_name = e_source_camel_get_extension_name ("imapx");

	for (ii = 0; ii < G_N_ELEMENTS (imap_keys); ii++) {
		value = g_hash_table_lookup (settings, imap_keys[ii]);
		if (value != NULL)
			g_key_file_set_value (
				key_file, group_name,
				imap_keys[ii], value);
	}

	g_hash_table_destroy (settings);

	/* Move the cache directory aside.  IMAPX has a different
	 * cache format, so the cache will need to be regenerated. */

	cache_dir = g_build_filename (
		e_get_user_cache_dir (), "mail", uid, NULL);

	/* Alter the name of the target directory so
	 * the cache reaper module does not restore it. */
	trash_name = g_strdup_printf ("%s_old_imap", uid);
	trash_dir = g_build_filename (
		e_get_user_cache_dir (), "mail", "trash", trash_name, NULL);
	g_free (trash_name);

	if (g_rename (cache_dir, trash_dir) == -1) {
		g_warning (
			"Failed to move '%s' to trash: %s",
			cache_dir, g_strerror (errno));
	}

	g_free (cache_dir);
	g_free (trash_dir);

	return TRUE;
}

static gboolean
evolution_source_registry_migrate_owncloud_to_webdav (ESourceRegistryServer *server,
						      GKeyFile *key_file,
						      const gchar *uid)
{
	gboolean modified = FALSE;

	g_return_val_if_fail (key_file != NULL, FALSE);

	if (g_key_file_has_group (key_file, E_SOURCE_EXTENSION_COLLECTION) &&
	    g_key_file_has_key (key_file, E_SOURCE_EXTENSION_COLLECTION, "BackendName", NULL)) {
		gchar *backend_name;

		backend_name = g_key_file_get_string (key_file, E_SOURCE_EXTENSION_COLLECTION, "BackendName", NULL);
		if (g_strcmp0 (backend_name, "owncloud") == 0) {
			g_key_file_set_string (key_file, E_SOURCE_EXTENSION_COLLECTION, "BackendName", "webdav");
			modified = TRUE;
		}

		g_free (backend_name);
	}

	return modified;
}

#define PRIMARY_GROUP_NAME	"Data Source"

static gboolean
evolution_source_registry_migrate_webdav_book_to_carddav (ESourceRegistryServer *server,
							  GKeyFile *key_file,
							  const gchar *uid)
{
	gboolean modified = FALSE;

	g_return_val_if_fail (key_file != NULL, FALSE);

	if (g_key_file_has_group (key_file, E_SOURCE_EXTENSION_ADDRESS_BOOK) &&
	    g_key_file_has_key (key_file, E_SOURCE_EXTENSION_ADDRESS_BOOK, "BackendName", NULL)) {
		gchar *backend_name;

		backend_name = g_key_file_get_string (key_file, E_SOURCE_EXTENSION_ADDRESS_BOOK, "BackendName", NULL);
		if (g_strcmp0 (backend_name, "webdav") == 0) {
			g_key_file_set_string (key_file, E_SOURCE_EXTENSION_ADDRESS_BOOK, "BackendName", "carddav");
			modified = TRUE;
		}

		g_free (backend_name);
	}

	if (g_key_file_has_group (key_file, PRIMARY_GROUP_NAME) &&
	    g_key_file_has_key (key_file, PRIMARY_GROUP_NAME, "Parent", NULL)) {
		gchar *parent;

		parent = g_key_file_get_string (key_file, PRIMARY_GROUP_NAME, "Parent", NULL);
		if (g_strcmp0 (parent, "webdav-stub") == 0) {
			g_key_file_set_string (key_file, PRIMARY_GROUP_NAME, "Parent", "carddav-stub");
			modified = TRUE;
		}

		g_free (parent);
	}

	return modified;
}

gboolean
evolution_source_registry_migrate_tweak_key_file (ESourceRegistryServer *server,
						  GKeyFile *key_file,
						  const gchar *uid)
{
	gboolean modified;

	modified = evolution_source_registry_migrate_imap_to_imapx (server, key_file, uid);
	modified = evolution_source_registry_migrate_owncloud_to_webdav (server, key_file, uid) || modified;
	modified = evolution_source_registry_migrate_webdav_book_to_carddav (server, key_file, uid) || modified;

	return modified;
}
