/*
 * base-media-call-stream.h - Header for TpBaseMediaCallStream
 * Copyright (C) 2009-2011 Collabora Ltd.
 * @author Sjoerd Simons <sjoerd.simons@collabora.co.uk>
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

#ifndef __TP_BASE_MEDIA_CALL_STREAM_H__
#define __TP_BASE_MEDIA_CALL_STREAM_H__

#include <telepathy-glib/base-call-stream.h>
#include <telepathy-glib/call-stream-endpoint.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

typedef struct _TpBaseMediaCallStream TpBaseMediaCallStream;
typedef struct _TpBaseMediaCallStreamPrivate TpBaseMediaCallStreamPrivate;
typedef struct _TpBaseMediaCallStreamClass TpBaseMediaCallStreamClass;

typedef gboolean (*TpBaseMediaCallStreamFinishInitialCandidatesFunc) (
    TpBaseMediaCallStream *self,
    GError **error);
typedef GPtrArray *(*TpBaseMediaCallStreamAddCandidatesFunc) (
    TpBaseMediaCallStream *self,
    const GPtrArray *candidates,
    GError **error);
typedef void (*TpBaseMediaCallStreamReportFailureFunc) (
    TpBaseMediaCallStream *self,
    TpStreamFlowState old_state,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message);

typedef void (*TpBaseMediaCallStreamRequestReceivingFunc) (
    TpBaseMediaCallStream *self,
    TpHandle contact,
    gboolean receive);
typedef gboolean (*TpBaseMediaCallStreamSetSendingFunc) (
    TpBaseMediaCallStream *self,
    gboolean sending,
    GError **error);

struct _TpBaseMediaCallStreamClass {
  /*<private>*/
  TpBaseCallStreamClass parent_class;

  /*< public >*/
  TpBaseMediaCallStreamReportFailureFunc report_sending_failure;
  TpBaseMediaCallStreamReportFailureFunc report_receiving_failure;
  TpBaseMediaCallStreamAddCandidatesFunc add_local_candidates;
  TpBaseMediaCallStreamFinishInitialCandidatesFunc finish_initial_candidates;

  TpBaseMediaCallStreamRequestReceivingFunc request_receiving;
  TpBaseMediaCallStreamSetSendingFunc set_sending;

  /*<private>*/
  gpointer future[4];
};

struct _TpBaseMediaCallStream {
  /*<private>*/
  TpBaseCallStream parent;

  TpBaseMediaCallStreamPrivate *priv;
};

_TP_AVAILABLE_IN_0_18
GType tp_base_media_call_stream_get_type (void);

/* TYPE MACROS */
#define TP_TYPE_BASE_MEDIA_CALL_STREAM \
  (tp_base_media_call_stream_get_type ())
#define TP_BASE_MEDIA_CALL_STREAM(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_BASE_MEDIA_CALL_STREAM, TpBaseMediaCallStream))
#define TP_BASE_MEDIA_CALL_STREAM_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), TP_TYPE_BASE_MEDIA_CALL_STREAM, \
    TpBaseMediaCallStreamClass))
#define TP_IS_BASE_MEDIA_CALL_STREAM(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_BASE_MEDIA_CALL_STREAM))
#define TP_IS_BASE_MEDIA_CALL_STREAM_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_BASE_MEDIA_CALL_STREAM))
#define TP_BASE_MEDIA_CALL_STREAM_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_BASE_MEDIA_CALL_STREAM, \
    TpBaseMediaCallStreamClass))

_TP_AVAILABLE_IN_0_18
void tp_base_media_call_stream_set_relay_info (TpBaseMediaCallStream *self,
    GPtrArray *relays);
_TP_AVAILABLE_IN_0_18
void tp_base_media_call_stream_set_stun_servers (TpBaseMediaCallStream *self,
    GPtrArray *stun_servers);
_TP_AVAILABLE_IN_0_18
void tp_base_media_call_stream_add_endpoint (TpBaseMediaCallStream *self,
    TpCallStreamEndpoint *endpoint);
_TP_AVAILABLE_IN_0_18
void tp_base_media_call_stream_remove_endpoint (TpBaseMediaCallStream *self,
    TpCallStreamEndpoint *endpoint);
_TP_AVAILABLE_IN_0_18
GList *tp_base_media_call_stream_get_endpoints (TpBaseMediaCallStream *self);
_TP_AVAILABLE_IN_0_18
const gchar *tp_base_media_call_stream_get_username (
    TpBaseMediaCallStream *self);
_TP_AVAILABLE_IN_0_18
const gchar *tp_base_media_call_stream_get_password (
    TpBaseMediaCallStream *self);
_TP_AVAILABLE_IN_0_18
TpStreamFlowState tp_base_media_call_stream_get_sending_state (
    TpBaseMediaCallStream *self);
_TP_AVAILABLE_IN_0_18
TpStreamFlowState tp_base_media_call_stream_get_receiving_state (
    TpBaseMediaCallStream *self);
_TP_AVAILABLE_IN_0_18
void tp_base_media_call_stream_update_receiving_state (
    TpBaseMediaCallStream *self);
_TP_AVAILABLE_IN_0_18
void tp_base_media_call_stream_update_sending_state (
    TpBaseMediaCallStream *self);
_TP_AVAILABLE_IN_0_18
void tp_base_media_call_stream_set_local_sending (TpBaseMediaCallStream *self,
    gboolean sending);
_TP_AVAILABLE_IN_0_18
gboolean tp_base_media_call_stream_get_local_sending (
    TpBaseMediaCallStream *self);
_TP_AVAILABLE_IN_0_18
GPtrArray *tp_base_media_call_stream_get_local_candidates (
    TpBaseMediaCallStream *self);

G_END_DECLS

#endif /* #ifndef __TP_BASE_MEDIA_CALL_STREAM_H__*/
