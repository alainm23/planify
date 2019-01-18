/*
 * tp-channel-factory-iface.c - Stubs for Telepathy Channel Factory interface
 *
 * Copyright (C) 2006-2008 Collabora Ltd.
 * Copyright (C) 2006-2008 Nokia Corporation
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
 * SECTION:channel-factory-iface
 * @title: TpChannelFactoryIface
 * @short_description: interface for channel allocation/tracking
 * @see_also: #TpSvcConnection, #TpChannelManager
 *
 * A channel factory is attached to a connection. It carries out channel
 * requests from the connection, and responds to channel-related events
 * on the underlying network connection (e.g. incoming calls).
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager, a newer
 * interface which can be used to implement modern D-Bus APIs, instead.
 *
 * Deprecated: 0.11.7
 */

#include "config.h"

#include <telepathy-glib/channel-factory-iface.h>

#include <glib-object.h>

#include <telepathy-glib/channel-iface.h>

enum {
    NEW_CHANNEL,
    CHANNEL_ERROR,
    N_SIGNALS
};

static guint signals[N_SIGNALS] = {0};

static void
tp_channel_factory_iface_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized) {
    initialized = TRUE;

    /**
     * TpChannelFactoryIface::new-channel:
     * @self: an object implementing #TpChannelFactoryIface
     * @channel: a new channel (an object implementing #TpChannelIface)
     * @request_context: a request context as passed to
     *  tp_channel_factory_iface_request(), or %NULL
     *
     * Emitted when a new channel has been created.
     *
     * If the @channel was created in response to a channel request, the
     * request was for a nonzero handle type, and the channel has zero handle
     * type, @request_context will be the request context passed to
     * tp_channel_factory_iface_request().
     *
     * Otherwise, request may either be %NULL or a request that led to
     * @channel's creation; callers are expected to determine which channels
     * satisfy which requests based on the handle and handle-type.
     */
    signals[NEW_CHANNEL] = g_signal_new ("new-channel",
                  G_OBJECT_CLASS_TYPE (klass),
                  G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
                  0,
                  NULL, NULL, NULL,
                  G_TYPE_NONE, 2, G_TYPE_OBJECT, G_TYPE_POINTER);

    /**
     * TpChannelFactoryIface::channel-error:
     * @self: an object implementing #TpChannelFactoryIface
     * @channel: an object implementing #TpChannelIface
     * @error: the #GError that made the channel request fail
     * @request_context: a request context as passed to
     *  tp_channel_factory_iface_request(), or %NULL
     *
     * Emitted when a new channel has been created, but an error occurred
     * before it could become useful.
     *
     * @request is the same as for #TpChannelFactoryIface::new-channel.
     */
    signals[CHANNEL_ERROR] = g_signal_new ("channel-error",
                  G_OBJECT_CLASS_TYPE (klass),
                  G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
                  0,
                  NULL, NULL, NULL,
                  G_TYPE_NONE,
                  3, G_TYPE_OBJECT, G_TYPE_POINTER, G_TYPE_POINTER);
  }
}

GType
tp_channel_factory_iface_get_type (void)
{
  static GType type = 0;

  if (type == 0) {
    static const GTypeInfo info = {
      sizeof (TpChannelFactoryIfaceClass),
      tp_channel_factory_iface_base_init,   /* base_init */
      NULL,   /* base_finalize */
      NULL,   /* class_init */
      NULL,   /* class_finalize */
      NULL,   /* class_data */
      0,
      0,      /* n_preallocs */
      NULL    /* instance_init */
    };

    type = g_type_register_static (G_TYPE_INTERFACE, "TpChannelFactoryIface",
        &info, 0);
  }

  return type;
}

/**
 * tp_channel_factory_iface_close_all:
 * @self: An object implementing #TpChannelFactoryIface
 *
 * Close all channels and shut down the channel factory. It is not expected
 * to be usable afterwards. This is called when the connection goes to
 * disconnected state, before either emitting the StatusChanged signal or
 * calling disconnected().
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
void
tp_channel_factory_iface_close_all (TpChannelFactoryIface *self)
{
  void (*virtual_method)(TpChannelFactoryIface *) =
    TP_CHANNEL_FACTORY_IFACE_GET_CLASS (self)->close_all;
  g_assert (virtual_method != NULL);
  virtual_method (self);
}

/**
 * tp_channel_factory_iface_connecting:
 * @self: An implementation of the channel factory interface
 *
 * Indicate that the connection has gone from disconnected to connecting
 * state.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
void
tp_channel_factory_iface_connecting (TpChannelFactoryIface *self)
{
  void (*virtual_method)(TpChannelFactoryIface *) =
    TP_CHANNEL_FACTORY_IFACE_GET_CLASS (self)->connecting;
  if (virtual_method)
    virtual_method (self);
}

/**
 * tp_channel_factory_iface_connected:
 * @self: An implementation of the channel factory interface
 *
 * Indicate that the connection has gone from connecting to connected state.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
void
tp_channel_factory_iface_connected (TpChannelFactoryIface *self)
{
  void (*virtual_method)(TpChannelFactoryIface *) =
    TP_CHANNEL_FACTORY_IFACE_GET_CLASS (self)->connected;
  if (virtual_method)
    virtual_method (self);
}

/**
 * tp_channel_factory_iface_disconnected:
 * @self: An implementation of the channel factory interface
 *
 * Indicate that the connection has become disconnected.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
void
tp_channel_factory_iface_disconnected (TpChannelFactoryIface *self)
{
  void (*virtual_method)(TpChannelFactoryIface *) =
    TP_CHANNEL_FACTORY_IFACE_GET_CLASS (self)->disconnected;
  if (virtual_method)
    virtual_method (self);
}

/**
 * tp_channel_factory_iface_foreach:
 * @self: An implementation of the channel factory interface
 * @func: A callback to be called once per channel
 * @data: Extra data to be passed to @func
 *
 * Call func(channel, data) for each channel managed by this factory.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
void
tp_channel_factory_iface_foreach (TpChannelFactoryIface *self,
                                  TpChannelFunc func,
                                  gpointer data)
{
  void (*virtual_method)(TpChannelFactoryIface *, TpChannelFunc, gpointer) =
    TP_CHANNEL_FACTORY_IFACE_GET_CLASS (self)->foreach;
  g_assert (virtual_method != NULL);
  virtual_method (self, func, data);
}

/**
 * tp_channel_factory_iface_request:
 * @self: An object implementing #TpChannelFactoryIface
 * @chan_type: The channel type, e.g. %TP_IFACE_CHANNEL_TYPE_TEXT
 * @handle_type: The handle type of the channel's associated handle,
 *               or 0 if the channel has no associated handle
 * @handle: The channel's associated handle, of type @handle_type,
 *          or 0 if the channel has no associated handle
 * @request: An opaque data structure representing the channel request;
 *           if this request is satisfied by a newly created channel,
 *           this structure MUST be included in the new-channel signal
 *           if the newly created channel has handle 0, and MAY be
 *           included in the signal if the newly created channel has
 *           nonzero handle.
 * @ret: Set to the new channel if it is available immediately, as
 *       documented in the description of #TpChannelFactoryRequestStatus
 * @error: Set to the error if the return is
 *         %TP_CHANNEL_FACTORY_REQUEST_STATUS_ERROR, unset otherwise
 *
 * Request a channel.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 *
 * Returns: one of the values of #TpChannelFactoryRequestStatus, and
 *          behaves as documented for that return value
 */
TpChannelFactoryRequestStatus
tp_channel_factory_iface_request (TpChannelFactoryIface *self,
                                  const gchar *chan_type,
                                  TpHandleType handle_type,
                                  TpHandle handle,
                                  gpointer request,
                                  TpChannelIface **ret,
                                  GError **error)
{
  TpChannelFactoryRequestStatus (*virtual_method) (TpChannelFactoryIface *,
      const gchar *, TpHandleType, guint, gpointer, TpChannelIface **,
      GError **) = TP_CHANNEL_FACTORY_IFACE_GET_CLASS (self)->request;
  g_assert (virtual_method != NULL);
  return virtual_method (self, chan_type, handle_type, handle, request,
      ret, error);
}

/**
 * tp_channel_factory_iface_emit_new_channel:
 * @instance: An object implementing #TpChannelFactoryIface
 * @channel: The new channel
 * @request: A request context as passed to tp_channel_factory_iface_request(),
 *           or %NULL
 *
 * Signal that a new channel has been created (new-channel signal).
 *
 * If the channel was created in response to a channel request, the request
 * was for a nonzero handle type, and the channel has zero handle type,
 * request will be the request context passed to
 * tp_channel_factory_iface_request().
 *
 * Otherwise, request may either be
 * %NULL or a request that led to the channel's creation; callers are expected
 * to determine which channels satisfy which requests based on the handle
 * and handle-type.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
void
tp_channel_factory_iface_emit_new_channel (gpointer instance,
                                           TpChannelIface *channel,
                                           gpointer context)
{
  g_signal_emit (instance, signals[NEW_CHANNEL], 0, channel, context);
}

/**
 * tp_channel_factory_iface_emit_channel_error:
 * @instance: An object implementing #TpChannelFactoryIface
 * @channel: The new channel
 * @error: The error that made the channel request fail
 * @request: A request context as passed to tp_channel_factory_iface_request(),
 *           or %NULL
 *
 * Signal that a new channel was created, but an error occurred before it
 * could become useful.
 *
 * request is as for tp_channel_factory_iface_emit_new_channel().
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
void
tp_channel_factory_iface_emit_channel_error (gpointer instance,
                                             TpChannelIface *channel,
                                             GError *error,
                                             gpointer context)
{
  g_signal_emit (instance, signals[CHANNEL_ERROR], 0, channel, error, context);
}
