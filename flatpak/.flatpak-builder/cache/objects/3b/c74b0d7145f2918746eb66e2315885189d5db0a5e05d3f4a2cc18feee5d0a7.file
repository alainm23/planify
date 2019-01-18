/*
 * Object representing a connection on a Stream Tube
 *
 * Copyright © 2010 Collabora Ltd.
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

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_STREAM_TUBE_CONNECTION_H__
#define __TP_STREAM_TUBE_CONNECTION_H__

#include <glib-object.h>
#include <gio/gio.h>

#include <telepathy-glib/contact.h>
#include <telepathy-glib/stream-tube-channel.h>

G_BEGIN_DECLS

/* TpStreamTubeConnection is defined in stream-tube-channel.h to break
 * circular includes */
typedef struct _TpStreamTubeConnectionClass TpStreamTubeConnectionClass;
typedef struct _TpStreamTubeConnectionPrivate TpStreamTubeConnectionPrivate;

GType tp_stream_tube_connection_get_type (void);

#define TP_TYPE_STREAM_TUBE_CONNECTION \
  (tp_stream_tube_connection_get_type ())
#define TP_STREAM_TUBE_CONNECTION(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_STREAM_TUBE_CONNECTION, \
                               TpStreamTubeConnection))
#define TP_STREAM_TUBE_CONNECTION_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_STREAM_TUBE_CONNECTION, \
                            TpStreamTubeConnectionClass))
#define TP_IS_STREAM_TUBE_CONNECTION(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_STREAM_TUBE_CONNECTION))
#define TP_IS_STREAM_TUBE_CONNECTION_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_STREAM_TUBE_CONNECTION))
#define TP_STREAM_TUBE_CONNECTION_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_STREAM_TUBE_CONNECTION, \
                              TpStreamTubeConnectionClass))

GSocketConnection * tp_stream_tube_connection_get_socket_connection (
    TpStreamTubeConnection *self);

TpStreamTubeChannel * tp_stream_tube_connection_get_channel (
    TpStreamTubeConnection *self);

TpContact * tp_stream_tube_connection_get_contact (
    TpStreamTubeConnection *self);

G_END_DECLS

#endif
