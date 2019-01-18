/*
 * evolution-addressbook-factory.c
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
#include <libedata-book/libedata-book.h>

static gboolean opt_keep_running = FALSE;
static gboolean opt_wait_for_client = FALSE;
static gint opt_backend_per_process = -1;

static GOptionEntry entries[] = {

	{ "keep-running", 'r', 0, G_OPTION_ARG_NONE, &opt_keep_running,
	  N_("Keep running after the last client is closed"), NULL },
	{ "wait-for-client", 'w', 0, G_OPTION_ARG_NONE, &opt_wait_for_client,
	  N_("Wait running until at least one client is connected"), NULL },
	{ "backend-per-process", 'b', 0, G_OPTION_ARG_INT, &opt_backend_per_process,
	  N_("Overrides compile-time backend per process option; use 1 to enable, 0 to disable, any other value is to use compile-time option"), NULL },
	{ NULL }
};

gint
main (gint argc,
      gchar **argv)
{
	GOptionContext *context;
	EDBusServer *server;
	EDBusServerExitCode exit_code;
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
	server = e_data_book_factory_new (opt_backend_per_process, NULL, &error);

	if (error != NULL) {
		g_printerr ("%s\n", error->message);
		exit (EXIT_FAILURE);
	}

	g_debug ("Server is up and running...");

	/* This SHOULD keep the server's use
	 * count from ever reaching zero. */
	if (opt_keep_running)
		e_dbus_server_hold (server);

	exit_code = e_dbus_server_run (server, opt_wait_for_client);

	g_object_unref (server);

	if (exit_code == E_DBUS_SERVER_EXIT_RELOAD) {
		g_debug ("Reloading...");
		goto reload;
	}

	g_debug ("Bye.");

	return 0;
}
