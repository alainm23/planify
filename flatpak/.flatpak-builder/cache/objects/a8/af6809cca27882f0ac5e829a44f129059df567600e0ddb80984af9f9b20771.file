/*
 * e-dbus-server.c
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

/**
 * SECTION: e-dbus-server
 * @include: libebackend/libebackend.h
 * @short_description: An abstract base class for a D-Bus server
 **/

#include "evolution-data-server-config.h"

#include <glib.h>

#ifdef G_OS_UNIX
#include <glib-unix.h>
#endif

#include <libedataserver/libedataserver.h>

#include <libebackend/e-backend-enumtypes.h>

#include "e-dbus-server.h"

#define E_DBUS_SERVER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_DBUS_SERVER, EDBusServerPrivate))

#define INACTIVITY_TIMEOUT 10  /* seconds */

struct _EDBusServerPrivate {
	GMainLoop *main_loop;
	guint bus_owner_id;
	guint hang_up_id;
	guint terminate_id;

	guint inactivity_timeout_id;
	guint use_count;
	gboolean wait_for_client;
	EDBusServerExitCode exit_code;

	GMutex property_lock;

	GFileMonitor *directory_monitor;
};

enum {
	BUS_ACQUIRED,
	BUS_NAME_ACQUIRED,
	BUS_NAME_LOST,
	RUN_SERVER,
	QUIT_SERVER,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

static GHashTable *loaded_modules;
G_LOCK_DEFINE_STATIC (loaded_modules);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE (
	EDBusServer, e_dbus_server, G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (E_TYPE_EXTENSIBLE, NULL))

static void
dbus_server_bus_acquired_cb (GDBusConnection *connection,
                             const gchar *bus_name,
                             EDBusServer *server)
{
	g_signal_emit (server, signals[BUS_ACQUIRED], 0, connection);
}

static void
dbus_server_name_acquired_cb (GDBusConnection *connection,
                              const gchar *bus_name,
                              EDBusServer *server)
{
	g_signal_emit (server, signals[BUS_NAME_ACQUIRED], 0, connection);
}

static void
dbus_server_name_lost_cb (GDBusConnection *connection,
                          const gchar *bus_name,
                          EDBusServer *server)
{
	g_signal_emit (server, signals[BUS_NAME_LOST], 0, connection);
}

static gboolean
dbus_server_inactivity_timeout_cb (gpointer user_data)
{
	EDBusServer *server = E_DBUS_SERVER (user_data);

	e_dbus_server_quit (server, E_DBUS_SERVER_EXIT_NORMAL);

	return FALSE;
}

#ifdef G_OS_UNIX
static gboolean
dbus_server_hang_up_cb (gpointer user_data)
{
	EDBusServer *server = E_DBUS_SERVER (user_data);

	e_source_registry_debug_print ("Received hang up signal.\n");
	e_dbus_server_quit (server, E_DBUS_SERVER_EXIT_RELOAD);

	return FALSE;
}

static gboolean
dbus_server_terminate_cb (gpointer user_data)
{
	EDBusServer *server = E_DBUS_SERVER (user_data);

	e_source_registry_debug_print ("Received terminate signal.\n");
	e_dbus_server_quit (server, E_DBUS_SERVER_EXIT_NORMAL);

	return FALSE;
}
#endif

static void
dbus_server_finalize (GObject *object)
{
	EDBusServerPrivate *priv;

	priv = E_DBUS_SERVER_GET_PRIVATE (object);

	g_main_loop_unref (priv->main_loop);

	if (priv->bus_owner_id > 0)
		g_bus_unown_name (priv->bus_owner_id);

	if (priv->hang_up_id > 0)
		g_source_remove (priv->hang_up_id);

	if (priv->terminate_id > 0)
		g_source_remove (priv->terminate_id);

	if (priv->inactivity_timeout_id > 0)
		g_source_remove (priv->inactivity_timeout_id);

	g_mutex_clear (&priv->property_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_dbus_server_parent_class)->finalize (object);
}

static void
dbus_server_dispose (GObject *object)
{
	EDBusServer *server = E_DBUS_SERVER (object);

	g_clear_object (&server->priv->directory_monitor);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_dbus_server_parent_class)->dispose (object);
}

static void
dbus_server_constructed (GObject *object)
{
	e_dbus_server_load_modules (E_DBUS_SERVER (object));

	e_extensible_load_extensions (E_EXTENSIBLE (object));

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_dbus_server_parent_class)->constructed (object);
}

static void
dbus_server_bus_acquired (EDBusServer *server,
                          GDBusConnection *connection)
{
	if (server->priv->use_count == 0 && !server->priv->wait_for_client) {
		server->priv->inactivity_timeout_id =
			e_named_timeout_add_seconds (
				INACTIVITY_TIMEOUT, (GSourceFunc)
				dbus_server_inactivity_timeout_cb,
				server);
	}
}

static void
dbus_server_bus_name_acquired (EDBusServer *server,
                               GDBusConnection *connection)
{
	EDBusServerClass *class;

	class = E_DBUS_SERVER_GET_CLASS (server);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->bus_name != NULL);

	e_source_registry_debug_print ("Bus name '%s' acquired.\n", class->bus_name);
}

static void
dbus_server_bus_name_lost (EDBusServer *server,
                           GDBusConnection *connection)
{
	EDBusServerClass *class;

	class = E_DBUS_SERVER_GET_CLASS (server);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->bus_name != NULL);

	e_source_registry_debug_print ("Bus name '%s' lost.\n", class->bus_name);

	e_dbus_server_quit (server, E_DBUS_SERVER_EXIT_NORMAL);
}

static EDBusServerExitCode
dbus_server_run_server (EDBusServer *server)
{
	EDBusServerClass *class;

	/* Try to acquire the well-known bus name. */

	class = E_DBUS_SERVER_GET_CLASS (server);
	g_return_val_if_fail (class != NULL, E_DBUS_SERVER_EXIT_NONE);
	g_return_val_if_fail (class->bus_name != NULL, E_DBUS_SERVER_EXIT_NONE);

	server->priv->bus_owner_id = g_bus_own_name (
		G_BUS_TYPE_SESSION,
		class->bus_name,
		G_BUS_NAME_OWNER_FLAGS_REPLACE |
		G_BUS_NAME_OWNER_FLAGS_ALLOW_REPLACEMENT,
		(GBusAcquiredCallback) dbus_server_bus_acquired_cb,
		(GBusNameAcquiredCallback) dbus_server_name_acquired_cb,
		(GBusNameLostCallback) dbus_server_name_lost_cb,
		g_object_ref (server),
		(GDestroyNotify) g_object_unref);

	g_main_loop_run (server->priv->main_loop);

	return server->priv->exit_code;
}

static void
dbus_server_quit_server (EDBusServer *server,
                         EDBusServerExitCode code)
{
	/* If we're reloading, voluntarily relinquish our bus
	 * name to avoid triggering a "bus-name-lost" signal. */
	if (code == E_DBUS_SERVER_EXIT_RELOAD) {
		if (server->priv->bus_owner_id) {
			g_bus_unown_name (server->priv->bus_owner_id);
			server->priv->bus_owner_id = 0;
		}
	}

	server->priv->exit_code = code;
	g_main_loop_quit (server->priv->main_loop);
}

static void
ignore_log (const gchar *log_domain,
            GLogLevelFlags log_level,
            const gchar *message,
            gpointer user_data)
{
	/* Avoid printing of trivial messages while running test
	 * cases.  Only print warnings, criticals and errors. */
	if ((log_level & (G_LOG_FLAG_FATAL     |
			  G_LOG_LEVEL_ERROR    |
			  G_LOG_LEVEL_CRITICAL |
			  G_LOG_LEVEL_WARNING)) != 0)
		g_log_default_handler (log_domain, log_level, message, user_data);
}

static void
e_dbus_server_class_init (EDBusServerClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EDBusServerPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = dbus_server_finalize;
	object_class->dispose = dbus_server_dispose;
	object_class->constructed = dbus_server_constructed;

	class->bus_acquired = dbus_server_bus_acquired;
	class->bus_name_acquired = dbus_server_bus_name_acquired;
	class->bus_name_lost = dbus_server_bus_name_lost;
	class->run_server = dbus_server_run_server;
	class->quit_server = dbus_server_quit_server;

	/**
	 * EDBusServer::bus-acquired:
	 * @server: the #EDBusServer which emitted the signal
	 * @connection: the #GDBusConnection to the session bus
	 *
	 * Emitted when @server acquires a connection to the session bus.
	 **/
	signals[BUS_ACQUIRED] = g_signal_new (
		"bus-acquired",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EDBusServerClass, bus_acquired),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_DBUS_CONNECTION);

	/**
	 * EDBusServer::bus-name-acquired:
	 * @server: the #EDBusServer which emitted the signal
	 * @connection: the #GDBusConnection to the session bus
	 *
	 * Emitted when @server acquires its well-known session bus name.
	 **/
	signals[BUS_NAME_ACQUIRED] = g_signal_new (
		"bus-name-acquired",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EDBusServerClass, bus_name_acquired),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_DBUS_CONNECTION);

	/**
	 * EDBusServer::bus-name-lost:
	 * @server: the #EDBusServer which emitted the signal
	 * @connection: the #GDBusconnection to the session bus,
	 *              or %NULL if the connection has been closed
	 *
	 * Emitted when @server loses its well-known session bus name
	 * or the session bus connection has been closed.
	 **/
	signals[BUS_NAME_LOST] = g_signal_new (
		"bus-name-lost",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EDBusServerClass, bus_name_lost),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_DBUS_CONNECTION);

	/**
	 * EDBusServer::run-server:
	 * @server: the #EDBusServer which emitted the signal
	 *
	 * Emitted to request that @server start its main loop and
	 * attempt to acquire its well-known session bus name.
	 *
	 * Returns: an #EDBusServerExitCode
	 **/
	signals[RUN_SERVER] = g_signal_new (
		"run-server",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EDBusServerClass, run_server),
		NULL, NULL, NULL,
		E_TYPE_DBUS_SERVER_EXIT_CODE, 0);

	/**
	 * EDBusServer::quit-server:
	 * @server: the #EDBusServer which emitted the signal
	 * @code: an #EDBusServerExitCode
	 *
	 * Emitted to request that @server quit its main loop.
	 **/
	signals[QUIT_SERVER] = g_signal_new (
		"quit-server",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EDBusServerClass, quit_server),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		E_TYPE_DBUS_SERVER_EXIT_CODE);

	if (g_getenv ("EDS_TESTING") != NULL)
		g_log_set_default_handler (ignore_log, NULL);
}

static void
e_dbus_server_init (EDBusServer *server)
{
#if !GLIB_CHECK_VERSION(2, 58, 0)
	/* Workaround glib bug https://bugzilla.gnome.org/show_bug.cgi?id=793727
	   Do not place this into class_init(), otherwise it can trigger
	   deadlock under _g_dbus_initialize () at gdbusprivate.c:1950 */
	g_network_monitor_get_default ();
#endif

	server->priv = E_DBUS_SERVER_GET_PRIVATE (server);
	server->priv->main_loop = g_main_loop_new (NULL, FALSE);
	server->priv->wait_for_client = FALSE;

	g_mutex_init (&server->priv->property_lock);

#ifdef G_OS_UNIX
	server->priv->hang_up_id = g_unix_signal_add (
		SIGHUP, dbus_server_hang_up_cb, server);
	server->priv->terminate_id = g_unix_signal_add (
		SIGTERM, dbus_server_terminate_cb, server);
#endif
}

/**
 * e_dbus_server_run:
 * @server: an #EDBusServer
 * @wait_for_client: continue running until a client connects
 *
 * Emits the #EDBusServer::run signal.
 *
 * By default the @server will start its main loop and attempt to acquire
 * its well-known session bus name.  If the @server's main loop is already
 * running, the function will immediately return #E_DBUS_SERVER_EXIT_NONE.
 * Otherwise the function blocks until e_dbus_server_quit() is called.
 *
 * If @wait_for_client is %TRUE, the @server will continue running until
 * the first client connection is made instead of quitting on its own if
 * no client connection is made within the first few seconds.
 *
 * Returns: the exit code passed to e_dbus_server_quit()
 *
 * Since: 3.4
 **/
EDBusServerExitCode
e_dbus_server_run (EDBusServer *server,
                   gboolean wait_for_client)
{
	EDBusServerExitCode exit_code;

	g_return_val_if_fail (
		E_IS_DBUS_SERVER (server),
		E_DBUS_SERVER_EXIT_NONE);

	server->priv->wait_for_client = wait_for_client;

	if (g_main_loop_is_running (server->priv->main_loop))
		return E_DBUS_SERVER_EXIT_NONE;

	g_signal_emit (server, signals[RUN_SERVER], 0, &exit_code);

	return exit_code;
}

/**
 * e_dbus_server_quit:
 * @server: an #EDBusServer
 * @code: an #EDBusServerExitCode
 *
 * Emits the #EDBusServer::quit signal with the given @code.
 *
 * By default the @server will quit its main loop and cause
 * e_dbus_server_run() to return @code.
 *
 * Since: 3.4
 **/
void
e_dbus_server_quit (EDBusServer *server,
                    EDBusServerExitCode code)
{
	g_return_if_fail (E_IS_DBUS_SERVER (server));

	g_signal_emit (server, signals[QUIT_SERVER], 0, code);
}

/**
 * e_dbus_server_hold:
 * @server: an #EDBusServer
 *
 * Increases the use count of @server.
 *
 * Use this function to indicate that the server has a reason to continue
 * to run.  To cancel the hold, call e_dbus_server_release().
 *
 * Since: 3.4
 **/
void
e_dbus_server_hold (EDBusServer *server)
{
	g_return_if_fail (E_IS_DBUS_SERVER (server));

	g_mutex_lock (&server->priv->property_lock);

	if (server->priv->inactivity_timeout_id > 0) {
		g_source_remove (server->priv->inactivity_timeout_id);
		server->priv->inactivity_timeout_id = 0;
	}

	server->priv->use_count++;

	g_mutex_unlock (&server->priv->property_lock);
}

/**
 * e_dbus_server_release:
 * @server: an #EDBusServer
 *
 * Decreates the use count of @server.
 *
 * When the use count reaches zero, the server will stop running.
 *
 * Never call this function except to cancel the effect of a previous call
 * to e_dbus_server_hold().
 *
 * Since: 3.4
 **/
void
e_dbus_server_release (EDBusServer *server)
{
	g_return_if_fail (E_IS_DBUS_SERVER (server));
	g_return_if_fail (server->priv->use_count > 0);

	g_mutex_lock (&server->priv->property_lock);

	server->priv->use_count--;

	if (server->priv->use_count == 0) {
		server->priv->inactivity_timeout_id =
			e_named_timeout_add_seconds (
				INACTIVITY_TIMEOUT, (GSourceFunc)
				dbus_server_inactivity_timeout_cb,
				server);
	}

	g_mutex_unlock (&server->priv->property_lock);
}

static void
dbus_server_module_directory_changed_cb (GFileMonitor *monitor,
					 GFile *file,
					 GFile *other_file,
					 GFileMonitorEvent event_type,
					 gpointer user_data)
{
	EDBusServer *server;

	g_return_if_fail (E_IS_DBUS_SERVER (user_data));

	server = E_DBUS_SERVER (user_data);

	if (event_type == G_FILE_MONITOR_EVENT_CREATED ||
	    event_type == G_FILE_MONITOR_EVENT_DELETED ||
	    event_type == G_FILE_MONITOR_EVENT_MOVED_IN ||
	    event_type == G_FILE_MONITOR_EVENT_MOVED_OUT ||
	    event_type == G_FILE_MONITOR_EVENT_RENAMED) {
		gchar *filename;

		filename = g_file_get_path (file);

		if (event_type == G_FILE_MONITOR_EVENT_RENAMED && other_file) {
			G_LOCK (loaded_modules);
			if (!g_hash_table_contains (loaded_modules, filename)) {
				g_free (filename);
				filename = g_file_get_path (other_file);
				event_type = G_FILE_MONITOR_EVENT_CREATED;
			}
			G_UNLOCK (loaded_modules);
		}

		if (filename && g_str_has_suffix (filename, "." G_MODULE_SUFFIX)) {
			gboolean any_loaded = FALSE;

			if (event_type == G_FILE_MONITOR_EVENT_CREATED ||
			    event_type == G_FILE_MONITOR_EVENT_MOVED_IN) {
				G_LOCK (loaded_modules);

				if (!g_hash_table_contains (loaded_modules, filename)) {
					EModule *module;

					g_hash_table_add (loaded_modules, g_strdup (filename));

					module = e_module_load_file (filename);
					if (module) {
						any_loaded = TRUE;

						g_type_module_unuse ((GTypeModule *) module);
					}
				}

				G_UNLOCK (loaded_modules);
			}

			if (any_loaded)
				e_dbus_server_quit (server, E_DBUS_SERVER_EXIT_RELOAD);
		}

		g_free (filename);
	}
}

/**
 * e_dbus_server_load_modules:
 * @server: an #EDBusServer
 *
 * This function should be called once during @server initialization to
 * load all available library modules to extend the @server's functionality.
 *
 * Since: 3.4
 **/
void
e_dbus_server_load_modules (EDBusServer *server)
{
	EDBusServerClass *class;
	gboolean already_loaded;
	GList *list, *link;

	g_return_if_fail (E_IS_DBUS_SERVER (server));

	class = E_DBUS_SERVER_GET_CLASS (server);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->module_directory != NULL);

	/* This ensures a module directory is only loaded once. */
	G_LOCK (loaded_modules);
	if (loaded_modules == NULL)
		loaded_modules = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);
	already_loaded = g_hash_table_contains (loaded_modules, class->module_directory);
	if (!already_loaded)
		g_hash_table_add (loaded_modules, g_strdup (class->module_directory));
	G_UNLOCK (loaded_modules);

	if (!server->priv->directory_monitor) {
		GFile *dir_file;

		dir_file = g_file_new_for_path (class->module_directory);
		server->priv->directory_monitor = g_file_monitor_directory (dir_file, G_FILE_MONITOR_WATCH_MOVES, NULL, NULL);
		g_clear_object (&dir_file);

		if (server->priv->directory_monitor) {
			g_signal_connect (server->priv->directory_monitor, "changed",
				G_CALLBACK (dbus_server_module_directory_changed_cb), server);
		}
	}

	if (already_loaded)
		return;

	G_LOCK (loaded_modules);

	list = e_module_load_all_in_directory (class->module_directory);
	for (link = list; link; link = g_list_next (link)) {
		EModule *module = link->data;

		if (!module || !e_module_get_filename (module))
			continue;

		g_hash_table_add (loaded_modules, g_strdup (e_module_get_filename (module)));
	}

	G_UNLOCK (loaded_modules);

	g_list_free_full (list, (GDestroyNotify) g_type_module_unuse);
}
