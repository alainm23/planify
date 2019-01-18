/*<private_header>*/
/*
 * internal-dbus-glib.h - private header for dbus-glib glue
 *
 * Copyright (C) 2007 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2007 Nokia Corporation
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA
 *
 */

#ifndef __TP_INTERNAL_DBUS_GLIB_H__
#define __TP_INTERNAL_DBUS_GLIB_H__

G_BEGIN_DECLS

gboolean _tp_dbus_daemon_get_name_owner (TpDBusDaemon *self, gint timeout_ms,
    const gchar *well_known_name, gchar **unique_name, GError **error);

void _tp_register_dbus_glib_marshallers (void);

DBusGConnection *_tp_dbus_starter_bus_conn (GError **error)
  G_GNUC_WARN_UNUSED_RESULT;

gboolean _tp_dbus_daemon_is_the_shared_one (TpDBusDaemon *self);

G_END_DECLS

#endif /* __TP_INTERNAL_DBUS_GLIB_H__ */
