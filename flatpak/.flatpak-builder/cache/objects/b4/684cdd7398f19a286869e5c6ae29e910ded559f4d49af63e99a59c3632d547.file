/*
 * call-stream.h - high level API for Call streams
 *
 * Copyright (C) 2011 Collabora Ltd. <http://www.collabora.co.uk/>
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

#ifndef __TP_CALL_STREAM_H__
#define __TP_CALL_STREAM_H__

#include <telepathy-glib/proxy.h>
#include <telepathy-glib/call-channel.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

#define TP_TYPE_CALL_STREAM (tp_call_stream_get_type ())
#define TP_CALL_STREAM(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CALL_STREAM, TpCallStream))
#define TP_CALL_STREAM_CLASS(obj) (G_TYPE_CHECK_CLASS_CAST ((obj), TP_TYPE_CALL_STREAM, TpCallStreamClass))
#define TP_IS_CALL_STREAM(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CALL_STREAM))
#define TP_IS_CALL_STREAM_CLASS(obj) (G_TYPE_CHECK_CLASS_TYPE ((obj), TP_TYPE_CALL_STREAM))
#define TP_CALL_STREAM_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CALL_STREAM, TpCallStreamClass))

typedef struct _TpCallStream TpCallStream;
typedef struct _TpCallStreamClass TpCallStreamClass;
typedef struct _TpCallStreamPrivate TpCallStreamPrivate;

struct _TpCallStream
{
  /*<private>*/
  TpProxy parent;
  TpCallStreamPrivate *priv;
};

struct _TpCallStreamClass
{
  /*<private>*/
  TpProxyClass parent_class;
  GCallback _padding[7];
};

_TP_AVAILABLE_IN_0_18
GType tp_call_stream_get_type (void);

_TP_AVAILABLE_IN_0_18
void tp_call_stream_init_known_interfaces (void);

#define TP_CALL_STREAM_FEATURE_CORE \
  tp_call_stream_get_feature_quark_core ()
_TP_AVAILABLE_IN_0_18
GQuark tp_call_stream_get_feature_quark_core (void) G_GNUC_CONST;

_TP_AVAILABLE_IN_0_18
TpSendingState tp_call_stream_get_local_sending_state (TpCallStream *self);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_stream_can_request_receiving (TpCallStream *self);
_TP_AVAILABLE_IN_0_18
GHashTable *tp_call_stream_get_remote_members (TpCallStream *self);

_TP_AVAILABLE_IN_0_18
void tp_call_stream_set_sending_async (TpCallStream *self,
    gboolean send,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_stream_set_sending_finish (TpCallStream *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_18
void tp_call_stream_request_receiving_async (TpCallStream *self,
    TpContact *contact,
    gboolean receive,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_stream_request_receiving_finish (TpCallStream *self,
    GAsyncResult *result,
    GError **error);

G_END_DECLS

#include <telepathy-glib/_gen/tp-cli-call-stream.h>

#endif
