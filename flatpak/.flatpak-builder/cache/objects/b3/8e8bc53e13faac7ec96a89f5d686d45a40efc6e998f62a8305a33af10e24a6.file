/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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
 */

#include "evolution-data-server-config.h"

#include <locale.h>
#include <libintl.h>
#include <glib/gi18n.h>

#include <libedataserver/libedataserver.h>
#include <libedataserverui/libedataserverui.h>

#include "e-alarm-notify.h"

#ifdef G_OS_UNIX
#include <glib-unix.h>

static gboolean
handle_term_signal (gpointer data)
{
	g_application_quit (data);

	return FALSE;
}
#endif

gint
main (gint argc,
      gchar **argv)
{
	EAlarmNotify *alarm_notify;
	gint exit_status;
	GError *error = NULL;

#ifdef G_OS_WIN32
	e_util_win32_initialize ();
#endif

	setlocale (LC_ALL, "");
	bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
	bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
	textdomain (GETTEXT_PACKAGE);

	/* Workaround https://bugzilla.gnome.org/show_bug.cgi?id=674885 */
	g_type_ensure (G_TYPE_DBUS_CONNECTION);
	g_type_ensure (G_TYPE_DBUS_PROXY);
	g_type_ensure (G_BUS_TYPE_SESSION);

	gtk_init (&argc, &argv);

	if (error != NULL) {
		g_printerr ("%s\n", error->message);
		exit (EXIT_FAILURE);
	}

	e_xml_initialize_in_main ();

	alarm_notify = e_alarm_notify_new (NULL, &error);

	if (error != NULL) {
		g_printerr ("%s\n", error->message);
		g_error_free (error);
		exit (EXIT_FAILURE);
	}

	g_application_register (G_APPLICATION (alarm_notify), NULL, &error);

	if (error != NULL) {
		g_printerr ("%s\n", error->message);
		g_error_free (error);
		g_object_unref (alarm_notify);
		exit (EXIT_FAILURE);
	}

	if (g_application_get_is_remote (G_APPLICATION (alarm_notify))) {
		g_object_unref (alarm_notify);
		return 0;
	}

#ifdef G_OS_UNIX
	g_unix_signal_add_full (
		G_PRIORITY_DEFAULT, SIGTERM,
		handle_term_signal, alarm_notify, NULL);
#endif

	exit_status = g_application_run (G_APPLICATION (alarm_notify), argc, argv);

	g_object_unref (alarm_notify);

	return exit_status;
}
