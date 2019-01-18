/*<private_header>*/
/*
 * Object representing a connection on a Stream Tube (internal)
 *
 * Copyright (C) 2009 Collabora Ltd. <http://www.collabora.co.uk/>
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

#ifndef __TP_STREAM_TUBE_CONNECTION_INTERNAL_H__
#define __TP_STREAM_TUBE_CONNECTION_INTERNAL_H__

#include <glib.h>
#include <gio/gio.h>

#include "stream-tube-connection.h"

G_BEGIN_DECLS

struct _TpStreamTubeConnection {
  /*<private>*/
  GObject parent;

  TpStreamTubeConnectionPrivate *priv;
};

TpStreamTubeConnection * _tp_stream_tube_connection_new (
    GSocketConnection *socket_connection,
    TpStreamTubeChannel *channel);

void _tp_stream_tube_connection_set_contact (TpStreamTubeConnection *self,
    TpContact *contact);

void _tp_stream_tube_connection_fire_closed (TpStreamTubeConnection *self,
    GError *error);

G_END_DECLS

#endif
