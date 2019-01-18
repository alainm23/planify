/*
 * call-channel.h - high level API for Call channels
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

#ifndef __TP_CALL_CHANNEL_H__
#define __TP_CALL_CHANNEL_H__

#include <telepathy-glib/channel.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

#define TP_TYPE_CALL_CHANNEL (tp_call_channel_get_type ())
#define TP_CALL_CHANNEL(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CALL_CHANNEL, TpCallChannel))
#define TP_CALL_CHANNEL_CLASS(obj) (G_TYPE_CHECK_CLASS_CAST ((obj), TP_TYPE_CALL_CHANNEL, TpCallChannelClass))
#define TP_IS_CALL_CHANNEL(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CALL_CHANNEL))
#define TP_IS_CALL_CHANNEL_CLASS(obj) (G_TYPE_CHECK_CLASS_TYPE ((obj), TP_TYPE_CALL_CHANNEL))
#define TP_CALL_CHANNEL_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CALL_CHANNEL, TpCallChannelClass))

/* forward declaration, see call-content.h for the rest */
typedef struct _TpCallContent TpCallContent;

typedef struct _TpCallChannel TpCallChannel;
typedef struct _TpCallChannelClass TpCallChannelClass;
typedef struct _TpCallChannelPrivate TpCallChannelPrivate;

struct _TpCallChannel
{
  /*<private>*/
  TpChannel parent;
  TpCallChannelPrivate *priv;
};

struct _TpCallChannelClass
{
  /*<private>*/
  TpChannelClass parent_class;
  GCallback _padding[7];
};

_TP_AVAILABLE_IN_0_18
GType tp_call_channel_get_type (void);

typedef struct _TpCallStateReason TpCallStateReason;
struct _TpCallStateReason
{
  TpHandle actor;
  TpCallStateChangeReason reason;
  gchar *dbus_reason;
  gchar *message;

  /*<private>*/
  guint ref_count;
};

#define TP_TYPE_CALL_STATE_REASON (tp_call_state_reason_get_type ())
_TP_AVAILABLE_IN_0_18
GType tp_call_state_reason_get_type (void);

#define TP_CALL_CHANNEL_FEATURE_CORE \
  tp_call_channel_get_feature_quark_core ()
_TP_AVAILABLE_IN_0_18
GQuark tp_call_channel_get_feature_quark_core (void) G_GNUC_CONST;

_TP_AVAILABLE_IN_0_18
GPtrArray *tp_call_channel_get_contents (TpCallChannel *self);
_TP_AVAILABLE_IN_0_18
TpCallState tp_call_channel_get_state (TpCallChannel *self,
    TpCallFlags *flags,
    GHashTable **details,
    TpCallStateReason **reason);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_has_hardware_streaming (TpCallChannel *self);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_has_initial_audio (TpCallChannel *self,
    const gchar **initial_audio_name);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_has_initial_video (TpCallChannel *self,
    const gchar **initial_video_name);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_has_mutable_contents (TpCallChannel *self);
_TP_AVAILABLE_IN_0_18
GHashTable *tp_call_channel_get_members (TpCallChannel *self);

_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_has_dtmf (TpCallChannel *self);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_has_hold (TpCallChannel *self);

_TP_AVAILABLE_IN_0_18
void tp_call_channel_set_ringing_async (TpCallChannel *self,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_set_ringing_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_18
void tp_call_channel_set_queued_async (TpCallChannel *self,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_set_queued_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_18
void tp_call_channel_accept_async (TpCallChannel *self,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_accept_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_18
void tp_call_channel_hangup_async (TpCallChannel *self,
    TpCallStateChangeReason reason,
    const gchar *detailed_reason,
    const gchar *message,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_hangup_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_18
void tp_call_channel_add_content_async (TpCallChannel *self,
    const gchar *name,
    TpMediaStreamType type,
    TpMediaStreamDirection initial_direction,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
TpCallContent *tp_call_channel_add_content_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_18
void tp_call_channel_send_tones_async (TpCallChannel *self,
    const gchar *tones,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_send_tones_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_18
void tp_call_channel_request_hold_async (TpCallChannel *self,
    gboolean hold,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
gboolean tp_call_channel_request_hold_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error);

G_END_DECLS

#endif
