/*
 * stream-tube-channel.h - high level API for StreamTube channels
 *
 * Copyright (C) 2010 Collabora Ltd. <http://www.collabora.co.uk/>
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

#ifndef __TP_STREAM_TUBE_CHANNEL_H__
#define __TP_STREAM_TUBE_CHANNEL_H__

#include <telepathy-glib/channel.h>

G_BEGIN_DECLS

/* Forward declaration of a subclass - from stream-tube-connection.h */
typedef struct _TpStreamTubeConnection TpStreamTubeConnection;

#define TP_TYPE_STREAM_TUBE_CHANNEL (tp_stream_tube_channel_get_type ())
#define TP_STREAM_TUBE_CHANNEL(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_STREAM_TUBE_CHANNEL, TpStreamTubeChannel))
#define TP_STREAM_TUBE_CHANNEL_CLASS(obj) (G_TYPE_CHECK_CLASS_CAST ((obj), TP_TYPE_STREAM_TUBE_CHANNEL, TpStreamTubeChannelClass))
#define TP_IS_STREAM_TUBE_CHANNEL(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_STREAM_TUBE_CHANNEL))
#define TP_IS_STREAM_TUBE_CHANNEL_CLASS(obj) (G_TYPE_CHECK_CLASS_TYPE ((obj), TP_TYPE_STREAM_TUBE_CHANNEL))
#define TP_STREAM_TUBE_CHANNEL_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_STREAM_TUBE_CHANNEL, TpStreamTubeChannelClass))

typedef struct _TpStreamTubeChannel TpStreamTubeChannel;
typedef struct _TpStreamTubeChannelClass TpStreamTubeChannelClass;
typedef struct _TpStreamTubeChannelPrivate TpStreamTubeChannelPrivate;

struct _TpStreamTubeChannel
{
  /*<private>*/
  TpChannel parent;
  TpStreamTubeChannelPrivate *priv;
};

struct _TpStreamTubeChannelClass
{
  /*<private>*/
  TpChannelClass parent_class;
  GCallback _padding[7];
};

GType tp_stream_tube_channel_get_type (void);

_TP_DEPRECATED_IN_0_20_FOR(tp_simple_client_factory_ensure_channel)
TpStreamTubeChannel *tp_stream_tube_channel_new (TpConnection *conn,
    const gchar *object_path,
    const GHashTable *immutable_properties,
    GError **error);

const gchar * tp_stream_tube_channel_get_service (TpStreamTubeChannel *self);

GHashTable * tp_stream_tube_channel_get_parameters (TpStreamTubeChannel *self);

_TP_AVAILABLE_IN_0_20
GVariant *tp_stream_tube_channel_dup_parameters_vardict (
    TpStreamTubeChannel *self);

/* Incoming tube methods */

void tp_stream_tube_channel_accept_async (TpStreamTubeChannel *self,
    GAsyncReadyCallback callback,
    gpointer user_data);

TpStreamTubeConnection * tp_stream_tube_channel_accept_finish (
    TpStreamTubeChannel *self,
    GAsyncResult *result,
    GError **error);

/* Outgoing tube methods */

void tp_stream_tube_channel_offer_async (TpStreamTubeChannel *self,
    GHashTable *params,
    GAsyncReadyCallback callback,
    gpointer user_data);

gboolean tp_stream_tube_channel_offer_finish (TpStreamTubeChannel *self,
    GAsyncResult *result,
    GError **error);

G_END_DECLS

#endif
