/*
 * run.c - entry point for telepathy-glib connection managers
 * Copyright (C) 2005, 2007 Collabora Ltd.
 * Copyright (C) 2005, 2007 Nokia Corporation
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/**
 * SECTION:run
 * @title: Connection manager life cycle
 * @short_description: entry point for telepathy-glib connection managers
 *
 * tp_run_connection_manager() provides a convenient entry point for
 * telepathy-glib connection managers. It initializes most of the
 * functionality the CM will need, constructs a connection manager object
 * and lets it run.
 *
 * This function also manages the connection manager's lifetime - if there
 * are no new connections for a while, it times out and exits.
 */

#include "config.h"

#include <telepathy-glib/run.h>

#include <dbus/dbus-glib.h>
#include <dbus/dbus-glib-lowlevel.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#define DEBUG_FLAG TP_DEBUG_MANAGER
#include "debug-internal.h"
#include <telepathy-glib/base-connection-manager.h>
#include <telepathy-glib/debug.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/util.h>
#include <telepathy-glib/dbus.h>

#ifdef HAVE_EXECINFO_H
#include <execinfo.h>
#endif /* HAVE_EXECINFO_H */

#ifdef HAVE_SIGNAL_H
#include <signal.h>
#endif /* HAVE_SIGNAL_H */

static GMainLoop *mainloop = NULL;
static TpBaseConnectionManager *manager = NULL;
static gboolean connections_exist = FALSE;
static guint timeout_id = 0;

static void
quit_loop (void)
{
  g_object_unref (manager);
  manager = NULL;
  g_main_loop_quit (mainloop);
}

static gboolean
kill_connection_manager (gpointer data)
{
  if (!_TP_DEBUG_IS_PERSISTENT && !connections_exist)
    {
      g_debug ("no connections, and timed out");
      quit_loop ();
    }

  timeout_id = 0;
  return G_SOURCE_REMOVE;
}

static void
new_connection (TpBaseConnectionManager *conn,
                gchar *bus_name,
                gchar *object_path,
                gchar *proto)
{
  connections_exist = TRUE;

  if (0 != timeout_id)
    {
      g_source_remove (timeout_id);
      timeout_id = 0;
    }
}

#define DIE_TIME 5000

static void
no_more_connections (TpBaseConnectionManager *conn)
{
  connections_exist = FALSE;

  if (0 != timeout_id)
    {
      g_source_remove (timeout_id);
    }

  timeout_id = g_timeout_add (DIE_TIME, kill_connection_manager, NULL);
}

#ifdef ENABLE_BACKTRACE
static void
print_backtrace (void)
{
#if defined (HAVE_BACKTRACE) && defined (HAVE_BACKTRACE_SYMBOLS_FD)
  void *array[20];
  size_t size;

#define MSG "\n########## Backtrace (version " VERSION ") ##########\n"
  write (STDERR_FILENO, MSG, strlen (MSG));
#undef MSG

  size = backtrace (array, 20);
  backtrace_symbols_fd (array, size, STDERR_FILENO);
#endif /* HAVE_BACKTRACE && HAVE_BACKTRACE_SYMBOLS_FD */
}

static void
critical_handler (const gchar *log_domain,
                  GLogLevelFlags log_level,
                  const gchar *message,
                  gpointer user_data)
{
  g_log_default_handler (log_domain, log_level, message, user_data);
  print_backtrace ();
}

#ifdef HAVE_SIGNAL
static void
segv_handler (int sig)
{
#define MSG "caught SIGSEGV\n"
  write (STDERR_FILENO, MSG, strlen (MSG));
#undef MSG

  print_backtrace ();
  abort ();
}
#endif /* HAVE_SIGNAL */

#endif /* ENABLE_BACKTRACE */

static void
add_signal_handlers (void)
{
#if defined (HAVE_SIGNAL) && defined (ENABLE_BACKTRACE)
  signal (SIGSEGV, segv_handler);
#endif /* HAVE_SIGNAL && ENABLE_BACKTRACE */
}

static DBusHandlerResult
dbus_filter_function (DBusConnection *connection,
                      DBusMessage *message,
                      void *user_data)
{
  if (dbus_message_is_signal (message, DBUS_INTERFACE_LOCAL, "Disconnected") &&
      !tp_strdiff (dbus_message_get_path (message), DBUS_PATH_LOCAL))
    {
      g_message ("Got disconnected from the session bus");
      quit_loop ();
    }

  return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
}

/**
 * tp_run_connection_manager:
 * @prog_name: The program name to be used in debug messages etc.
 * @version: The program version
 * @construct_cm: A function which will return the connection manager
 *                object
 * @argc: The number of arguments passed to the program
 * @argv: The arguments passed to the program
 *
 * Run the connection manager by initializing libraries, constructing
 * a main loop, instantiating a connection manager and running the main
 * loop. When this function returns, the program should exit.
 *
 * If the connection manager does not create a connection within a
 * short arbitrary time (currently 5 seconds), either on startup or after
 * the last open connection is disconnected, and the PERSIST debug
 * flag is not set, return 0.
 *
 * If registering the connection manager on D-Bus fails, return 1.
 *
 * Returns: the status code with which the process should exit
 */

int
tp_run_connection_manager (const char *prog_name,
                           const char *version,
                           TpBaseConnectionManager *(*construct_cm) (void),
                           int argc,
                           char **argv)
{
  DBusConnection *connection = NULL;
  TpDBusDaemon *bus_daemon = NULL;
  GError *error = NULL;
  int ret = 1;

  add_signal_handlers ();

  g_set_prgname (prog_name);

#ifdef ENABLE_BACKTRACE
  g_log_set_handler ("GLib-GObject",
      G_LOG_LEVEL_CRITICAL | G_LOG_LEVEL_ERROR |
      G_LOG_FLAG_FATAL | G_LOG_FLAG_RECURSION,
      critical_handler, NULL);
  g_log_set_handler ("GLib",
      G_LOG_LEVEL_CRITICAL | G_LOG_LEVEL_ERROR |
      G_LOG_FLAG_FATAL | G_LOG_FLAG_RECURSION,
      critical_handler, NULL);
  g_log_set_handler ("tp-glib",
      G_LOG_LEVEL_CRITICAL | G_LOG_LEVEL_ERROR |
      G_LOG_FLAG_FATAL | G_LOG_FLAG_RECURSION,
      critical_handler, NULL);
  g_log_set_handler (NULL,
      G_LOG_LEVEL_CRITICAL | G_LOG_LEVEL_ERROR |
      G_LOG_FLAG_FATAL | G_LOG_FLAG_RECURSION,
      critical_handler, NULL);
#endif /* ENABLE_BACKTRACE */

  mainloop = g_main_loop_new (NULL, FALSE);

  bus_daemon = tp_dbus_daemon_dup (&error);

  if (bus_daemon == NULL)
    {
      WARNING ("%s", error->message);
      g_error_free (error);
      error = NULL;
      goto out;
    }

  manager = construct_cm ();

  g_signal_connect (manager, "new-connection",
      (GCallback) new_connection, NULL);

  g_signal_connect (manager, "no-more-connections",
      (GCallback) no_more_connections, NULL);

  /* It appears that dbus-glib registers a filter that wrongly returns
   * DBUS_HANDLER_RESULT_HANDLED for signals, so for *our* filter to have any
   * effect, we need to install it before calling
   * tp_base_connection_manager_register () */
  connection = dbus_g_connection_get_connection (
      ((TpProxy *) bus_daemon)->dbus_connection);
  dbus_connection_add_filter (connection, dbus_filter_function, NULL, NULL);
  dbus_connection_set_exit_on_disconnect (connection, FALSE);

  if (!tp_base_connection_manager_register (manager))
    {
      g_object_unref (manager);
      manager = NULL;
      goto out;
    }

  g_debug ("started version %s (telepathy-glib version %s)", version,
      VERSION);

  timeout_id = g_timeout_add (DIE_TIME, kill_connection_manager, NULL);

  g_main_loop_run (mainloop);

  g_message ("Exiting");

  ret = 0;

out:
  /* locals */
  if (connection != NULL)
    dbus_connection_remove_filter (connection, dbus_filter_function, NULL);

  if (bus_daemon != NULL)
    g_object_unref (bus_daemon);

  /* globals */
  if (timeout_id != 0)
    g_source_remove (timeout_id);

  if (mainloop != NULL)
    g_main_loop_unref (mainloop);

  mainloop = NULL;

  g_assert (manager == NULL);

  return ret;
}
