/*
 * Copyright (C) 2014 Red Hat, Inc. (www.redhat.com)
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

#include <e-dbus-subprocess-backend.h>
#include <libebackend/libebackend.h>
#include <libedataserver/libedataserver.h>
#include <libedata-book/libedata-book.h>

typedef struct _SubprocessData SubprocessData;

struct _SubprocessData {
	GMainLoop *loop;
	GDBusObjectManagerServer *manager;
	ESubprocessBookFactory *subprocess_book_factory;
};

static const gchar *factory_name = NULL;
static const gchar *bus_name = NULL;
static const gchar *path = NULL;

static GOptionEntry entries[] = {
	{ "factory", 'f', 0, G_OPTION_ARG_STRING, &factory_name, "Just for easier debugging", NULL },
	{ "bus-name", 'b', 0, G_OPTION_ARG_STRING, &bus_name, NULL, NULL },
	{ "own-path", 'p', 0, G_OPTION_ARG_STRING, &path, NULL, NULL },
	{ NULL }
};

static void
prepare_shutdown_and_quit (ESubprocessBookFactory *subprocess_book_factory,
			   SubprocessData *sd)
{
	e_subprocess_factory_call_backends_prepare_shutdown (E_SUBPROCESS_FACTORY (subprocess_book_factory));

	if (sd->loop) {
		g_main_loop_quit (sd->loop);
		sd->loop = NULL;
	}
}

static gboolean
subprocess_backend_handle_create_cb (EDBusSubprocessBackend *proxy,
				     GDBusMethodInvocation *invocation,
				     const gchar *uid,
				     const gchar *backend_factory_type_name,
				     const gchar *module_filename,
				     ESubprocessBookFactory *subprocess_book_factory)
{
	gchar *object_path = NULL;
	GDBusConnection *connection;
	GError *error = NULL;

	connection = g_dbus_method_invocation_get_connection (invocation);

	object_path = e_subprocess_factory_open_backend (
		E_SUBPROCESS_FACTORY (subprocess_book_factory),
		connection,
		uid,
		backend_factory_type_name,
		module_filename,
		G_DBUS_INTERFACE_SKELETON (proxy),
		NULL,
		&error);

	if (object_path != NULL) {
		e_dbus_subprocess_backend_complete_create (proxy, invocation, object_path);
		g_free (object_path);
	} else {
		g_dbus_method_invocation_take_error (invocation, error);
	}

	return TRUE;
}

static gboolean
subprocess_backend_handle_close_cb (EDBusSubprocessBackend *proxy,
				    GDBusMethodInvocation *invocation,
				    SubprocessData *sd)
{
	prepare_shutdown_and_quit (sd->subprocess_book_factory, sd);

	return TRUE;
}

static void
on_bus_acquired (GDBusConnection *connection,
		 const gchar *name,
		 SubprocessData *sd)
{
	EDBusSubprocessBackend *proxy;
	EDBusSubprocessObjectSkeleton *object;

	object = e_dbus_subprocess_object_skeleton_new (path);

	proxy = e_dbus_subprocess_backend_skeleton_new ();
	e_dbus_subprocess_object_skeleton_set_backend (object, proxy);

	g_signal_connect (
		proxy, "handle-create",
		G_CALLBACK (subprocess_backend_handle_create_cb),
		sd->subprocess_book_factory);

	g_signal_connect (
		proxy, "handle-close",
		G_CALLBACK (subprocess_backend_handle_close_cb),
		sd);

	g_dbus_object_manager_server_export (sd->manager, G_DBUS_OBJECT_SKELETON (object));
	g_object_unref (proxy);
	g_object_unref (object);

	g_dbus_object_manager_server_set_connection (sd->manager, connection);
}

static void
vanished_cb (GDBusConnection *connection,
	     const gchar *name,
	     SubprocessData *sd)
{
	prepare_shutdown_and_quit (sd->subprocess_book_factory, sd);
}

gint
main (gint argc,
      gchar **argv)
{
	guint id;
	guint watched_id;
	ESubprocessBookFactory *subprocess_book_factory;
	GMainLoop *loop;
	GDBusObjectManagerServer *manager;
	GOptionContext *context;
	SubprocessData sd;
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

	loop = g_main_loop_new (NULL, FALSE);

	manager = g_dbus_object_manager_server_new ("/org/gnome/evolution/dataserver/Subprocess/Backend");

	subprocess_book_factory = e_subprocess_book_factory_new (NULL, NULL);

	sd.loop = loop;
	sd.manager = manager;
	sd.subprocess_book_factory = subprocess_book_factory;

	/* Watch the factory name and close the subprocess if the factory dies/crashes */
	watched_id = g_bus_watch_name (
		G_BUS_TYPE_SESSION,
		ADDRESS_BOOK_DBUS_SERVICE_NAME,
		G_BUS_NAME_WATCHER_FLAGS_NONE,
		NULL,
		(GBusNameVanishedCallback) vanished_cb,
		&sd,
		NULL);

	id = g_bus_own_name (
		G_BUS_TYPE_SESSION,
		bus_name,
		G_BUS_NAME_OWNER_FLAGS_NONE,
		(GBusAcquiredCallback) on_bus_acquired,
		NULL,
		NULL,
		&sd,
		NULL);

	g_main_loop_run (loop);

	g_bus_unown_name (id);
	g_bus_unwatch_name (watched_id);

	g_clear_object (&subprocess_book_factory);
	g_clear_object (&manager);
	g_main_loop_unref (loop);

	return 0;
}
