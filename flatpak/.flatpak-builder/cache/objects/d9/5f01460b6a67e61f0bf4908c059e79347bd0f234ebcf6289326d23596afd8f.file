/*
 * evolution-source-registry.c
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include "evolution-data-server-config.h"

#include <locale.h>
#include <stdlib.h>
#include <glib/gi18n.h>

#if defined (ENABLE_MAINTAINER_MODE) && defined (HAVE_GTK)
#include <gtk/gtk.h>
#endif

#include <libedataserver/libedataserver.h>
#include <libebackend/libebackend.h>

#include "evolution-source-registry-resource.h"
#include "evolution-source-registry-methods.h"

#define RESOURCE_PATH_RO_SOURCES "/org/gnome/evolution-data-server/ro-sources"
#define RESOURCE_PATH_RW_SOURCES "/org/gnome/evolution-data-server/rw-sources"

static gboolean opt_disable_migration = FALSE;

static GOptionEntry entries[] = {
	{ "disable-migration", 'd', 0, G_OPTION_ARG_NONE, &opt_disable_migration,
	  N_("Don’t migrate user data from previous versions of Evolution"), NULL },
	{ NULL }
};

static void
evolution_source_registry_load_error (ESourceRegistryServer *server,
                                      GFile *file,
                                      const GError *error)
{
	gchar *uri = g_file_get_uri (file);

	g_printerr (
		"** Failed to load key file at '%s': %s\n",
		uri, error->message);

	g_free (uri);
}

static gboolean
evolution_source_registry_load_all (ESourceRegistryServer *server,
                                    GError **error)
{
	ESourcePermissionFlags flags;
	GResource *resource;
	const gchar *path;
	gboolean success;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY_SERVER (server), FALSE);

	/* Load the user's sources directory first so that user-specific
	 * data sources overshadow predefined data sources with identical
	 * UIDs.  The 'local' data source is one such example. */

	path = e_server_side_source_get_user_dir ();
	flags = E_SOURCE_PERMISSION_REMOVABLE |
		E_SOURCE_PERMISSION_WRITABLE;
	success = e_source_registry_server_load_directory (
		server, path, flags, error);
	g_prefix_error (error, "%s: ", path);

	if (!success)
		return FALSE;

	resource = evolution_source_registry_get_resource ();

	path = RESOURCE_PATH_RO_SOURCES;
	flags = E_SOURCE_PERMISSION_NONE;
	success = e_source_registry_server_load_resource (
		server, resource, path, flags, error);
	g_prefix_error (error, "%s: ", path);

	if (!success)
		return FALSE;

	path = RESOURCE_PATH_RW_SOURCES;
	flags = E_SOURCE_PERMISSION_WRITABLE;
	success = e_source_registry_server_load_resource (
		server, resource, path, flags, error);
	g_prefix_error (error, "%s: ", path);

	if (!success)
		return FALSE;

	/* Migrate proxy settings from Evolution. */
	if (!opt_disable_migration)
		evolution_source_registry_migrate_proxies (server);

	/* Signal that all files are now loaded.  One thing this
	 * does is tell the cache-reaper module to start scanning
	 * for orphaned cache directories. */
	g_signal_emit_by_name (server, "files-loaded");

	return TRUE;
}

static void
evolution_source_registry_load_sources (ESourceRegistryServer *server,
					GDBusConnection *connection)
{
	GError *error = NULL;

	if (!evolution_source_registry_merge_autoconfig_sources (server, &error)) {
		e_source_registry_debug_print (
			"Autoconfig: evolution_source_registry_merge_autoconfig_sources() failed: %s",
			error ? error->message : "Unknown error");
	}

	g_clear_error (&error);

	/* Failure here is fatal.  Don't even try to keep going. */
	evolution_source_registry_load_all (server, &error);

	if (error != NULL) {
		g_printerr ("%s\n", error->message);
		g_object_unref (server);
		exit (EXIT_FAILURE);
	}
}

gint
main (gint argc,
      gchar **argv)
{
	GOptionContext *context;
	EDBusServer *server;
	EDBusServerExitCode exit_code;
	GSettings *settings;
	GError *error = NULL;

#ifdef G_OS_WIN32
	e_util_win32_initialize ();
#endif

	setlocale (LC_ALL, "");
	bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
	bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");

	/* Workaround https://bugzilla.gnome.org/show_bug.cgi?id=674885 */
	g_type_ensure (G_TYPE_DBUS_CONNECTION);
	g_type_ensure (G_TYPE_DBUS_PROXY);
	g_type_ensure (G_BUS_TYPE_SESSION);

#if defined (ENABLE_MAINTAINER_MODE) && defined (HAVE_GTK)
	if (g_getenv ("EDS_TESTING") == NULL)
		/* This is only to load gtk-modules, like
		 * bug-buddy's gnomesegvhandler, if possible */
		gtk_init_check (&argc, &argv);
#endif

	context = g_option_context_new (NULL);
	g_option_context_add_main_entries (context, entries, GETTEXT_PACKAGE);
	g_option_context_parse (context, &argc, &argv, &error);
	g_option_context_free (context);

	if (error != NULL) {
		g_printerr ("%s\n", error->message);
		exit (EXIT_FAILURE);
	}

	e_xml_initialize_in_main ();

reload:

	settings = g_settings_new ("org.gnome.evolution-data-server");

	if (!opt_disable_migration && !g_settings_get_boolean (settings, "migrated")) {
		g_settings_set_boolean (settings, "migrated", TRUE);

		/* Migrate user data from ~/.evolution to XDG base directories. */
		evolution_source_registry_migrate_basedir ();

		/* Migrate ESource data from GConf XML blobs to key files.
		 * Do this AFTER XDG base directory migration since the key
		 * files are saved according to XDG base directory settings. */
		evolution_source_registry_migrate_sources ();
	} else if (opt_disable_migration) {
		e_source_registry_debug_print (" * Skipping old account data migration, disabled on command line\n");
	} else {
		e_source_registry_debug_print (" * Skipping old account data migration, already migrated\n");
	}

	g_object_unref (settings);

	server = e_source_registry_server_new ();

	g_signal_connect (
		server, "load-error", G_CALLBACK (
		evolution_source_registry_load_error),
		NULL);

	/* Postpone the sources load only after the D-Bus name is acquired */
	g_signal_connect (
		server, "bus-acquired",
		G_CALLBACK (evolution_source_registry_load_sources), NULL);

	/* Convert "imap" mail accounts to "imapx". */
	if (!opt_disable_migration) {
		g_signal_connect (
			server, "tweak-key-file", G_CALLBACK (
			evolution_source_registry_migrate_tweak_key_file),
			NULL);
	}

	g_debug ("Server is up and running...");

	/* Keep the server from quitting on its own.
	 * We don't have a way of tracking number of
	 * active clients, so once the server is up,
	 * it's up until the session bus closes. */
	e_dbus_server_hold (server);

	exit_code = e_dbus_server_run (server, FALSE);

	g_object_unref (server);

	if (exit_code == E_DBUS_SERVER_EXIT_RELOAD) {
		const gchar *config_dir;
		gchar *dirname;

		e_source_registry_debug_print ("Reloading...\n");

		/* It's possible the Reload is called after restore, where
		 * the ~/.config/evolution/sources directory can be missing,
		 * thus create it, because e_server_side_source_get_user_dir()
		 * may have its static variable already set to non-NULL value.
		*/
		config_dir = e_get_user_config_dir ();
		dirname = g_build_filename (config_dir, "sources", NULL);
		g_mkdir_with_parents (dirname, 0700);
		g_free (dirname);

		goto reload;
	}

	g_debug ("Bye.");

	return 0;
}
