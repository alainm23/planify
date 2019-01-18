/*
 * base-call-stream.h - Header for TpBaseCallStream
 * Copyright © 2009–2011 Collabora Ltd.
 * @author Sjoerd Simons <sjoerd.simons@collabora.co.uk>
 * @author Will Thompson <will.thompson@collabora.co.uk>
 * @author Xavier Claessens <xavier.claessens@collabora.co.uk>
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

#ifndef TP_BASE_CALL_STREAM_H
#define TP_BASE_CALL_STREAM_H

#include <glib-object.h>

#include <telepathy-glib/base-connection.h>
#include <telepathy-glib/dbus-properties-mixin.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

typedef struct _TpBaseCallStream TpBaseCallStream;
typedef struct _TpBaseCallStreamPrivate TpBaseCallStreamPrivate;
typedef struct _TpBaseCallStreamClass TpBaseCallStreamClass;

typedef GPtrArray * (*TpBaseCallStreamGetInterfacesFunc) (
    TpBaseCallStream *self);
typedef gboolean (*TpBaseCallStreamSetSendingFunc) (TpBaseCallStream *self,
    gboolean sending,
    GError **error);
typedef gboolean (*TpBaseCallStreamRequestReceivingFunc) (TpBaseCallStream *self,
    TpHandle contact,
    gboolean receive,
    GError **error);

struct _TpBaseCallStreamClass {
  /*<private>*/
  GObjectClass parent_class;

  TpDBusPropertiesMixinClass dbus_props_class;

  /*< public >*/
  TpBaseCallStreamRequestReceivingFunc request_receiving;
  TpBaseCallStreamSetSendingFunc set_sending;
  TpBaseCallStreamGetInterfacesFunc get_interfaces;

  /*<private>*/
  gpointer future[4];
};

struct _TpBaseCallStream {
  /*<private>*/
  GObject parent;

  TpBaseCallStreamPrivate *priv;
};

_TP_AVAILABLE_IN_0_18
GType tp_base_call_stream_get_type (void);

/* TYPE MACROS */
#define TP_TYPE_BASE_CALL_STREAM \
  (tp_base_call_stream_get_type ())
#define TP_BASE_CALL_STREAM(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_BASE_CALL_STREAM, TpBaseCallStream))
#define TP_BASE_CALL_STREAM_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), TP_TYPE_BASE_CALL_STREAM, \
    TpBaseCallStreamClass))
#define TP_IS_BASE_CALL_STREAM(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_BASE_CALL_STREAM))
#define TP_IS_BASE_CALL_STREAM_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_BASE_CALL_STREAM))
#define TP_BASE_CALL_STREAM_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_BASE_CALL_STREAM, \
    TpBaseCallStreamClass))

_TP_AVAILABLE_IN_0_18
TpBaseConnection *tp_base_call_stream_get_connection (
    TpBaseCallStream *self);
_TP_AVAILABLE_IN_0_18
const gchar *tp_base_call_stream_get_object_path (
    TpBaseCallStream *self);

_TP_AVAILABLE_IN_0_18
TpSendingState tp_base_call_stream_get_local_sending_state (
    TpBaseCallStream *self);
_TP_AVAILABLE_IN_0_18
gboolean tp_base_call_stream_update_local_sending_state (
    TpBaseCallStream *self,
    TpSendingState new_state,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message);

_TP_AVAILABLE_IN_0_18
TpSendingState tp_base_call_stream_get_remote_sending_state (
    TpBaseCallStream *self,
    TpHandle contact);
_TP_AVAILABLE_IN_0_18
gboolean tp_base_call_stream_update_remote_sending_state (
    TpBaseCallStream *self,
    TpHandle contact,
    TpSendingState new_state,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message);
_TP_AVAILABLE_IN_0_18
gboolean tp_base_call_stream_remove_member (
    TpBaseCallStream *self,
    TpHandle contact,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message);

G_END_DECLS

#endif
