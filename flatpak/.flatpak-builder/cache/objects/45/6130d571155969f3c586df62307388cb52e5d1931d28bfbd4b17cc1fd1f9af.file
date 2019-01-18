/*
 * e-dbus-server.h
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

#if !defined (__LIBEBACKEND_H_INSIDE__) && !defined (LIBEBACKEND_COMPILATION)
#error "Only <libebackend/libebackend.h> should be included directly."
#endif

#ifndef E_DBUS_SERVER_H
#define E_DBUS_SERVER_H

#include <gio/gio.h>
#include <libebackend/e-backend-enums.h>

/* Standard GObject macros */
#define E_TYPE_DBUS_SERVER \
	(e_dbus_server_get_type ())
#define E_DBUS_SERVER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_DBUS_SERVER, EDBusServer))
#define E_DBUS_SERVER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_DBUS_SERVER, EDBusServerClass))
#define E_IS_DBUS_SERVER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_DBUS_SERVER))
#define E_IS_DBUS_SERVER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_DBUS_SERVER))
#define E_DBUS_SERVER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_DBUS_SERVER, EDBusServerClass))

G_BEGIN_DECLS

typedef struct _EDBusServer EDBusServer;
typedef struct _EDBusServerClass EDBusServerClass;
typedef struct _EDBusServerPrivate EDBusServerPrivate;

/**
 * EDBusServer:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.4
 **/
struct _EDBusServer {
	/*< private >*/
	GObject parent;
	EDBusServerPrivate *priv;
};

struct _EDBusServerClass {
	GObjectClass parent_class;

	const gchar *bus_name;
	const gchar *module_directory;

	/* Signals */
	void		(*bus_acquired)		(EDBusServer *server,
						 GDBusConnection *connection);
	void		(*bus_name_acquired)	(EDBusServer *server,
						 GDBusConnection *connection);
	void		(*bus_name_lost)	(EDBusServer *server,
						 GDBusConnection *connection);
	EDBusServerExitCode
			(*run_server)		(EDBusServer *server);
	void		(*quit_server)		(EDBusServer *server,
						 EDBusServerExitCode code);

	gpointer reserved[14];
};

GType		e_dbus_server_get_type		(void) G_GNUC_CONST;
EDBusServerExitCode
		e_dbus_server_run		(EDBusServer *server,
						 gboolean wait_for_client);
void		e_dbus_server_quit		(EDBusServer *server,
						 EDBusServerExitCode code);
void		e_dbus_server_hold		(EDBusServer *server);
void		e_dbus_server_release		(EDBusServer *server);
void		e_dbus_server_load_modules	(EDBusServer *server);

G_END_DECLS

#endif /* E_DBUS_SERVER_H */
