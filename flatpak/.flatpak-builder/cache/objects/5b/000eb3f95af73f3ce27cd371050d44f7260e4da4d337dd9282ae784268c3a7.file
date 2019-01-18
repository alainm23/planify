/*
 * evolution-user-prompter.c
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
#include <libintl.h>
#include <glib/gi18n.h>

#include <libedataserver/libedataserver.h>

#include "prompt-user.h"

static gboolean opt_keep_running = FALSE;

static GOptionEntry entries[] = {

	{ "keep-running", 'r', 0, G_OPTION_ARG_NONE, &opt_keep_running,
	  N_("Keep running after the last client is closed"), NULL },
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

	prompt_user_init (&argc, &argv);

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
	server = e_user_prompter_server_new ();
	g_signal_connect (
		server, "prompt",
		G_CALLBACK (prompt_user_show), NULL);

	g_debug ("Prompter is up and running...");

	/* This SHOULD keep the server's use
	 * count from ever reaching zero. */
	if (opt_keep_running)
		e_dbus_server_hold (server);

	exit_code = e_dbus_server_run (server, TRUE);

	g_object_unref (server);

	if (exit_code == E_DBUS_SERVER_EXIT_RELOAD) {
		g_debug ("Reloading...");
		goto reload;
	}

	g_debug ("Bye.");

	return 0;
}
