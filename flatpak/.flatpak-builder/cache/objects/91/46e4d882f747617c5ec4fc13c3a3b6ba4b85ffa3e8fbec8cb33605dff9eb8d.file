/*
 * channel-dispatcher.h - proxy for the Telepathy channel dispatcher
 *
 * Copyright (C) 2009 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2009 Nokia Corporation
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

#ifndef TP_CHANNEL_DISPATCHER_H
#define TP_CHANNEL_DISPATCHER_H

#include <telepathy-glib/channel.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/proxy.h>

G_BEGIN_DECLS


typedef struct _TpChannelDispatcher TpChannelDispatcher;
typedef struct _TpChannelDispatcherClass TpChannelDispatcherClass;
typedef struct _TpChannelDispatcherPrivate TpChannelDispatcherPrivate;
typedef struct _TpChannelDispatcherClassPrivate TpChannelDispatcherClassPrivate;

struct _TpChannelDispatcher {
    /*<private>*/
    TpProxy parent;
    TpChannelDispatcherPrivate *priv;
};

struct _TpChannelDispatcherClass {
    /*<private>*/
    TpProxyClass parent_class;
    GCallback _padding[7];
    TpChannelDispatcherClassPrivate *priv;
};

GType tp_channel_dispatcher_get_type (void);

#define TP_TYPE_CHANNEL_DISPATCHER \
  (tp_channel_dispatcher_get_type ())
#define TP_CHANNEL_DISPATCHER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CHANNEL_DISPATCHER, \
                               TpChannelDispatcher))
#define TP_CHANNEL_DISPATCHER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_CHANNEL_DISPATCHER, \
                            TpChannelDispatcherClass))
#define TP_IS_CHANNEL_DISPATCHER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CHANNEL_DISPATCHER))
#define TP_IS_CHANNEL_DISPATCHER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_CHANNEL_DISPATCHER))
#define TP_CHANNEL_DISPATCHER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CHANNEL_DISPATCHER, \
                              TpChannelDispatcherClass))

TpChannelDispatcher *tp_channel_dispatcher_new (TpDBusDaemon *bus_daemon)
    G_GNUC_WARN_UNUSED_RESULT;

void tp_channel_dispatcher_init_known_interfaces (void);

_TP_AVAILABLE_IN_0_16
void tp_channel_dispatcher_present_channel_async (TpChannelDispatcher *self,
    TpChannel *channel,
    gint64 user_action_time,
    GAsyncReadyCallback callback,
    gpointer user_data);

_TP_AVAILABLE_IN_0_16
gboolean tp_channel_dispatcher_present_channel_finish (
    TpChannelDispatcher *self,
    GAsyncResult *result,
    GError **error);

G_END_DECLS

#include <telepathy-glib/_gen/tp-cli-channel-dispatcher.h>

#endif
