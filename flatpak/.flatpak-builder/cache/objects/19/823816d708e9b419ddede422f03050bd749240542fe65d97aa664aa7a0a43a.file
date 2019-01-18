/*
 * Copyright (C) 2016 Red Hat, Inc. (www.redhat.com)
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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_NETWORK_MONITOR_H
#define E_NETWORK_MONITOR_H

#include <gio/gio.h>

/* Standard GObject macros */
#define E_TYPE_NETWORK_MONITOR \
	(e_network_monitor_get_type ())
#define E_NETWORK_MONITOR(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_NETWORK_MONITOR, ENetworkMonitor))
#define E_NETWORK_MONITOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_NETWORK_MONITOR, ENetworkMonitorClass))
#define E_IS_NETWORK_MONITOR(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_NETWORK_MONITOR))
#define E_IS_NETWORK_MONITOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_NETWORK_MONITOR))
#define E_NETWORK_MONITOR_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_NETWORK_MONITOR, ENetworkMonitorClass))

G_BEGIN_DECLS

typedef struct _ENetworkMonitor ENetworkMonitor;
typedef struct _ENetworkMonitorClass ENetworkMonitorClass;
typedef struct _ENetworkMonitorPrivate ENetworkMonitorPrivate;

/**
 * E_NETWORK_MONITOR_ALWAYS_ONLINE_NAME: (value "always-online")
 *
 * A special name, which can be used as a GIO name in the call
 * to e_network_monitor_set_gio_name(), which is used to report
 * the the network as always reachable.
 *
 * Since: 3.22
 **/
#define E_NETWORK_MONITOR_ALWAYS_ONLINE_NAME "always-online"

/**
 * ENetworkMonitor:
 *
 * Contains only private data that should be read and manipulated using
 * the functions below. Implements #GNetworkMonitorInterface.
 *
 * Since: 3.22
 **/
struct _ENetworkMonitor {
	/*< private >*/
	GObject parent;
	ENetworkMonitorPrivate *priv;
};

struct _ENetworkMonitorClass {
	GObjectClass parent_class;
};

GType		e_network_monitor_get_type		(void) G_GNUC_CONST;
GNetworkMonitor *
		e_network_monitor_get_default		(void);
GSList *	e_network_monitor_list_gio_names	(ENetworkMonitor *network_monitor);
gchar *		e_network_monitor_dup_gio_name		(ENetworkMonitor *network_monitor);
void		e_network_monitor_set_gio_name		(ENetworkMonitor *network_monitor,
							 const gchar *gio_name);

G_END_DECLS

#endif /* E_NETWORK_MONITOR_H */
