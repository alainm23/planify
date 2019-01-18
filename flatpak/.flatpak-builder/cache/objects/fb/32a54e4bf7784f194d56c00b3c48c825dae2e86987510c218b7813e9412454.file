/*
 * tp-channel-factory-iface.h - Headers for Telepathy Channel Factory interface
 *
 * Copyright (C) 2006 Collabora Ltd.
 * Copyright (C) 2006 Nokia Corporation
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

#ifndef __TP_CHANNEL_FACTORY_IFACE_H__
#define __TP_CHANNEL_FACTORY_IFACE_H__

#include <glib-object.h>

#include <telepathy-glib/channel-iface.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/handle.h>

G_BEGIN_DECLS

#ifndef TP_DISABLE_DEPRECATED

#define TP_TYPE_CHANNEL_FACTORY_IFACE (tp_channel_factory_iface_get_type ())

#define TP_CHANNEL_FACTORY_IFACE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
  TP_TYPE_CHANNEL_FACTORY_IFACE, TpChannelFactoryIface))

#define TP_IS_CHANNEL_FACTORY_IFACE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
  TP_TYPE_CHANNEL_FACTORY_IFACE))

#define TP_CHANNEL_FACTORY_IFACE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE ((obj), \
  TP_TYPE_CHANNEL_FACTORY_IFACE, TpChannelFactoryIfaceClass))

/**
 * TpChannelFactoryIface:
 *
 * Opaque typedef representing any channel factory implementation.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
typedef struct _TpChannelFactoryIface TpChannelFactoryIface;

/* documented below */
typedef struct _TpChannelFactoryIfaceClass TpChannelFactoryIfaceClass;

/**
 * TpChannelFactoryRequestStatus:
 * @TP_CHANNEL_FACTORY_REQUEST_STATUS_NOT_IMPLEMENTED: Same as the Telepathy
 *  error NotImplemented. The connection will try the next factory in its
 *  list; if all return this, the overall result of the request will be
 *  NotImplemented. *@ret and *@error are not set
 * @TP_CHANNEL_FACTORY_REQUEST_STATUS_NOT_AVAILABLE: Same as the Telepathy
 *  error NotAvailable. *@ret and *@error are not set
 * @TP_CHANNEL_FACTORY_REQUEST_STATUS_INVALID_HANDLE: Same as the Telepathy
 *  error InvalidHandle. *@ret and *@error are not set
 * @TP_CHANNEL_FACTORY_REQUEST_STATUS_ERROR: An error other than the above.
 *  *@ret is not set, *@error is set
 * @TP_CHANNEL_FACTORY_REQUEST_STATUS_CREATED: A new channel was created
 *  (possibly in response to more than one request). new-channel has already
 *  been emitted and *@ret is set to the new channel.
 * @TP_CHANNEL_FACTORY_REQUEST_STATUS_QUEUED: A new channel will be created,
 *  or was created but is not ready yet. Either new-channel or channel-error
 *  will be emitted later. *@ret and *@error are not set.
 * @TP_CHANNEL_FACTORY_REQUEST_STATUS_EXISTING: An existing channel
 *  satisfies the request: new-channel was not emitted. *@ret is set to the
 *  existing channel.
 *
 * Indicates the result of a channel request.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
typedef enum { /*< skip >*/
  TP_CHANNEL_FACTORY_REQUEST_STATUS_NOT_IMPLEMENTED = 0,
  TP_CHANNEL_FACTORY_REQUEST_STATUS_NOT_AVAILABLE,
  TP_CHANNEL_FACTORY_REQUEST_STATUS_INVALID_HANDLE,
  TP_CHANNEL_FACTORY_REQUEST_STATUS_ERROR,
  TP_CHANNEL_FACTORY_REQUEST_STATUS_CREATED,
  TP_CHANNEL_FACTORY_REQUEST_STATUS_QUEUED,
  TP_CHANNEL_FACTORY_REQUEST_STATUS_EXISTING
} TpChannelFactoryRequestStatus;

/**
 * TpChannelFactoryIfaceProc:
 * @self: An object implementing #TpChannelFactoryIface
 *
 * A virtual method on a channel factory that takes no extra parameters
 * and returns nothing.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
typedef void (*TpChannelFactoryIfaceProc) (TpChannelFactoryIface *self);

/**
 * TpChannelFactoryIfaceRequestImpl:
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
 * Signature of an implementation of RequestChannel.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 *
 * Returns: one of the values of #TpChannelFactoryRequestStatus, and
 *          behaves as documented for that return value
 */
typedef TpChannelFactoryRequestStatus (*TpChannelFactoryIfaceRequestImpl) (
    TpChannelFactoryIface *self, const gchar *chan_type,
    TpHandleType handle_type, guint handle, gpointer request,
    TpChannelIface **ret, GError **error);

/**
 * TpChannelFactoryIfaceForeachImpl:
 * @self: An object implementing #TpChannelFactoryIface
 * @func: A function
 * @data: Arbitrary data to pass to @func as the second argument
 *
 * Signature of an implementation of foreach, which must call
 * func(channel, data) for each channel managed by this factory.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
typedef void (*TpChannelFactoryIfaceForeachImpl) (TpChannelFactoryIface *self,
    TpChannelFunc func, gpointer data);

/**
 * TpChannelFactoryIfaceClass:
 * @parent_class: Fields shared with GTypeInterface
 * @close_all: Close all channels and shut down the channel factory. It is not
 *  expected to be usable afterwards. This is called when the connection goes
 *  to disconnected state, before emitting the StatusChanged signal or calling
 *  disconnected(). Must be filled in by implementations.
 * @connecting: Called just after the connection goes from disconnected to
 *  connecting state. May be NULL if nothing special needs to happen.
 * @connected: Called just after the connection goes from connecting to
 *  connected state. May be NULL if nothing special needs to happen.
 * @disconnected: Called just after the connection goes to disconnected state.
 *  This is always called after @close_all. May be NULL if nothing special
 *  needs to happen.
 * @foreach: Call func(channel, data) for each channel managed by this
 *  factory. Must be filled in by implementations.
 * @request: Respond to a request for a channel. Must be filled in by
 *  implementations. See #TpChannelFactoryIfaceRequestImpl for details.
 *
 * The class structure and vtable for a channel factory implementation.
 *
 * Deprecated since version 0.11.7. Use #TpChannelManager instead.
 *
 * Deprecated: 0.11.7
 */
struct _TpChannelFactoryIfaceClass {
  GTypeInterface parent_class;

  TpChannelFactoryIfaceProc close_all;
  TpChannelFactoryIfaceProc connecting;
  TpChannelFactoryIfaceProc connected;
  TpChannelFactoryIfaceProc disconnected;
  TpChannelFactoryIfaceForeachImpl foreach;
  TpChannelFactoryIfaceRequestImpl request;
} _TP_GNUC_DEPRECATED;

GType tp_channel_factory_iface_get_type (void);

_TP_DEPRECATED
void tp_channel_factory_iface_close_all (TpChannelFactoryIface *self);

_TP_DEPRECATED
void tp_channel_factory_iface_connecting (TpChannelFactoryIface *self);

_TP_DEPRECATED
void tp_channel_factory_iface_connected (TpChannelFactoryIface *self);

_TP_DEPRECATED
void tp_channel_factory_iface_disconnected (TpChannelFactoryIface *self);

_TP_DEPRECATED
void tp_channel_factory_iface_foreach (TpChannelFactoryIface *self,
    TpChannelFunc func, gpointer data);

_TP_DEPRECATED
TpChannelFactoryRequestStatus tp_channel_factory_iface_request (
    TpChannelFactoryIface *self, const gchar *chan_type,
    TpHandleType handle_type, guint handle, gpointer request,
    TpChannelIface **ret, GError **error);

_TP_DEPRECATED
void tp_channel_factory_iface_emit_new_channel (gpointer instance,
    TpChannelIface *channel, gpointer request);

_TP_DEPRECATED
void tp_channel_factory_iface_emit_channel_error (gpointer instance,
    TpChannelIface *channel, GError *error, gpointer request);

#endif /* not TP_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* __TP_CHANNEL_FACTORY_IFACE_H__ */
