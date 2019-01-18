/*
 * channel-dispatch-operation.h - proxy for channels awaiting approval
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

#ifndef TP_CHANNEL_DISPATCH_OPERATION_H
#define TP_CHANNEL_DISPATCH_OPERATION_H

#include <telepathy-glib/account.h>
#include <telepathy-glib/base-client.h>
#include <telepathy-glib/connection.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/proxy.h>

G_BEGIN_DECLS


/* TpChannelDispatchOperation is defined in base-client.h */
typedef struct _TpChannelDispatchOperationClass
    TpChannelDispatchOperationClass;
typedef struct _TpChannelDispatchOperationPrivate
    TpChannelDispatchOperationPrivate;
typedef struct _TpChannelDispatchOperationClassPrivate
    TpChannelDispatchOperationClassPrivate;

struct _TpChannelDispatchOperation {
    /*<private>*/
    TpProxy parent;
    TpChannelDispatchOperationPrivate *priv;
};

struct _TpChannelDispatchOperationClass {
    /*<private>*/
    TpProxyClass parent_class;
    GCallback _padding[7];
    TpChannelDispatchOperationClassPrivate *priv;
};

GType tp_channel_dispatch_operation_get_type (void);

#define TP_TYPE_CHANNEL_DISPATCH_OPERATION \
  (tp_channel_dispatch_operation_get_type ())
#define TP_CHANNEL_DISPATCH_OPERATION(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CHANNEL_DISPATCH_OPERATION, \
                               TpChannelDispatchOperation))
#define TP_CHANNEL_DISPATCH_OPERATION_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_CHANNEL_DISPATCH_OPERATION, \
                            TpChannelDispatchOperationClass))
#define TP_IS_CHANNEL_DISPATCH_OPERATION(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CHANNEL_DISPATCH_OPERATION))
#define TP_IS_CHANNEL_DISPATCH_OPERATION_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_CHANNEL_DISPATCH_OPERATION))
#define TP_CHANNEL_DISPATCH_OPERATION_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CHANNEL_DISPATCH_OPERATION, \
                              TpChannelDispatchOperationClass))

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20
TpChannelDispatchOperation *tp_channel_dispatch_operation_new (
    TpDBusDaemon *bus_daemon, const gchar *object_path,
    GHashTable *immutable_properties, GError **error)
  G_GNUC_WARN_UNUSED_RESULT;
#endif

void tp_channel_dispatch_operation_init_known_interfaces (void);

#define TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE \
  tp_channel_dispatch_operation_get_feature_quark_core ()

GQuark tp_channel_dispatch_operation_get_feature_quark_core (void) G_GNUC_CONST;

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20_FOR(tp_channel_dispatch_operation_get_connection)
TpConnection * tp_channel_dispatch_operation_borrow_connection (
    TpChannelDispatchOperation *self);

_TP_DEPRECATED_IN_0_20_FOR(tp_channel_dispatch_operation_get_account)
TpAccount * tp_channel_dispatch_operation_borrow_account (
    TpChannelDispatchOperation *self);

_TP_DEPRECATED_IN_0_20_FOR(tp_channel_dispatch_operation_get_channels)
GPtrArray * tp_channel_dispatch_operation_borrow_channels (
    TpChannelDispatchOperation *self);

_TP_DEPRECATED_IN_0_20_FOR(tp_channel_dispatch_operation_get_possible_handlers)
GStrv tp_channel_dispatch_operation_borrow_possible_handlers (
    TpChannelDispatchOperation *self);

_TP_DEPRECATED_IN_0_20
GHashTable * tp_channel_dispatch_operation_borrow_immutable_properties (
    TpChannelDispatchOperation *self);
#endif

_TP_AVAILABLE_IN_0_20
TpConnection * tp_channel_dispatch_operation_get_connection (
    TpChannelDispatchOperation *self);

_TP_AVAILABLE_IN_0_20
TpAccount * tp_channel_dispatch_operation_get_account (
    TpChannelDispatchOperation *self);

_TP_AVAILABLE_IN_0_20
GPtrArray * tp_channel_dispatch_operation_get_channels (
    TpChannelDispatchOperation *self);

_TP_AVAILABLE_IN_0_20
GStrv tp_channel_dispatch_operation_get_possible_handlers (
    TpChannelDispatchOperation *self);

void tp_channel_dispatch_operation_handle_with_async (
    TpChannelDispatchOperation *self,
    const gchar *handler,
    GAsyncReadyCallback callback,
    gpointer user_data);

gboolean tp_channel_dispatch_operation_handle_with_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error);

void tp_channel_dispatch_operation_claim_async (
    TpChannelDispatchOperation *self,
    GAsyncReadyCallback callback,
    gpointer user_data);

gboolean tp_channel_dispatch_operation_claim_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error);

void tp_channel_dispatch_operation_handle_with_time_async (
    TpChannelDispatchOperation *self,
    const gchar *handler,
    gint64 user_action_time,
    GAsyncReadyCallback callback,
    gpointer user_data);

gboolean tp_channel_dispatch_operation_handle_with_time_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_16
void tp_channel_dispatch_operation_claim_with_async (
    TpChannelDispatchOperation *self,
    TpBaseClient *client,
    GAsyncReadyCallback callback,
    gpointer user_data);

_TP_AVAILABLE_IN_0_16
gboolean tp_channel_dispatch_operation_claim_with_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error);

/* Reject API */

_TP_AVAILABLE_IN_0_16
void tp_channel_dispatch_operation_close_channels_async (
    TpChannelDispatchOperation *self,
    GAsyncReadyCallback callback,
    gpointer user_data);

_TP_AVAILABLE_IN_0_16
gboolean tp_channel_dispatch_operation_close_channels_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_16
void tp_channel_dispatch_operation_leave_channels_async (
    TpChannelDispatchOperation *self,
    TpChannelGroupChangeReason reason,
    const gchar *message,
    GAsyncReadyCallback callback,
    gpointer user_data);

_TP_AVAILABLE_IN_0_16
gboolean tp_channel_dispatch_operation_leave_channels_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_16
void tp_channel_dispatch_operation_destroy_channels_async (
    TpChannelDispatchOperation *self,
    GAsyncReadyCallback callback,
    gpointer user_data);

_TP_AVAILABLE_IN_0_16
gboolean tp_channel_dispatch_operation_destroy_channels_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error);

G_END_DECLS

#include <telepathy-glib/_gen/tp-cli-channel-dispatch-operation.h>

#endif
