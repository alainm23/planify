/*
 * base-media-call-channel.c - Source for TpBaseMediaCallChannel
 * Copyright © 2011 Collabora Ltd.
 * @author Olivier Crete <olivier.crete@collabora.com>
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
 * SECTION:base-media-call-channel
 * @title: TpBaseMediaCallChannel
 * @short_description: base class for #TpSvcChannelTypeCall RTP media implementations
 * @see_also: #TpBaseCallChannel, #TpBaseMediaCallContent, #TpBaseMediaCallStream
 *
 * This is a base class for connection managers that use standard RTP media.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallChannel:
 *
 * A base class for call channel implementations with standard RTP
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallChannelClass:
 * @hold_state_changed: optional; virtual method called when the hold state
 *  changed
 * @accept: optional; virtual method called when the call is locally accepted
 *  and contents are ready. This replaces #TpBaseCallChannelClass.accept.
 *
 * The class structure for #TpBaseMediaCallChannel
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallChannelVoidFunc:
 * @self: a #TpBaseMediaCallChannel
 *
 * Signature of an implementation of #TpBaseMediaCallChannelClass.accept.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseMediaCallChannelHoldStateChangedFunc:
 * @self: a #TpBaseMediaCallChannel
 * @hold_state: the new #TpLocalHoldState
 * @hold_state_reason: the #TpLocalHoldStateReason for this change
 *
 * Signature of an implementation of
 * #TpBaseMediaCallChannelClass.hold_state_changed.
 *
 * Since: 0.17.5
 */

#include "config.h"

#include "base-media-call-channel.h"

#define DEBUG_FLAG TP_DEBUG_CALL

#include "telepathy-glib/base-call-content.h"
#include "telepathy-glib/base-call-internal.h"
#include "telepathy-glib/base-media-call-stream.h"
#include "telepathy-glib/base-connection.h"
#include "telepathy-glib/channel-iface.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/dbus.h"
#include "telepathy-glib/enums.h"
#include "telepathy-glib/gtypes.h"
#include "telepathy-glib/interfaces.h"
#include "telepathy-glib/svc-call.h"
#include "telepathy-glib/svc-channel.h"
#include "telepathy-glib/svc-properties-interface.h"
#include "telepathy-glib/util.h"

static void hold_iface_init (gpointer g_iface, gpointer iface_data);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE (TpBaseMediaCallChannel,
    tp_base_media_call_channel, TP_TYPE_BASE_CALL_CHANNEL,

    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL_INTERFACE_HOLD,
        hold_iface_init)
)

/* private structure */
struct _TpBaseMediaCallChannelPrivate
{
  TpLocalHoldState hold_state;
  TpLocalHoldStateReason hold_state_reason;

  gboolean accepted;
};

/* properties */
enum
{
  LAST_PROPERTY
};

static GPtrArray *
tp_base_media_call_channel_get_interfaces (TpBaseChannel *base)
{
  GPtrArray *interfaces;

  interfaces = TP_BASE_CHANNEL_CLASS (
      tp_base_media_call_channel_parent_class)->get_interfaces (base);

  g_ptr_array_add (interfaces, TP_IFACE_CHANNEL_INTERFACE_HOLD);
  g_ptr_array_add (interfaces, TP_IFACE_CHANNEL_INTERFACE_DTMF);

  return interfaces;
}

static void
call_members_changed_cb (TpBaseMediaCallChannel *self,
    GHashTable *updates,
    GHashTable *identifiers,
    GArray *removed,
    GValueArray *reason,
    gpointer user_data)
{
  TpBaseCallChannel *bcc = TP_BASE_CALL_CHANNEL (self);
  GList *l, *l2;
  GHashTable *call_members = tp_base_call_channel_get_call_members (bcc);

  /* check for remote hold */

  for (l = tp_base_call_channel_get_contents (bcc); l != NULL; l = l->next)
    {
      for (l2 = tp_base_call_content_get_streams (l->data);
           l2 != NULL; l2 = l2->next)
        {
          TpBaseMediaCallStream *stream = TP_BASE_MEDIA_CALL_STREAM (l2->data);
          GHashTable *remote_members = _tp_base_call_stream_get_remote_members (
              TP_BASE_CALL_STREAM (stream));
          gboolean all_held = TRUE;
          GHashTableIter iter;
          gpointer contact;

          g_hash_table_iter_init (&iter, remote_members);
          while (g_hash_table_iter_next (&iter, &contact, NULL))
            {
              gpointer value;

              if (g_hash_table_lookup_extended (call_members, contact, NULL,
                      &value))
                {
                  TpCallMemberFlags flags = GPOINTER_TO_UINT (value);
                  if ((flags & TP_CALL_MEMBER_FLAG_HELD) == 0)
                    all_held = FALSE;
                }
            }

          _tp_base_media_call_stream_set_remotely_held (stream, all_held);
        }
    }
}

static void
tp_base_media_call_channel_try_accept (TpBaseMediaCallChannel *self)
{
  TpBaseCallChannel *bcc = TP_BASE_CALL_CHANNEL (self);
  TpBaseMediaCallChannelClass *klass =
      TP_BASE_MEDIA_CALL_CHANNEL_GET_CLASS (self);
  GList *l;
  gboolean notready = FALSE;

  if (self->priv->accepted)
    return;

  for (l = tp_base_call_channel_get_contents (bcc); l; l = l->next)
    notready |= !_tp_base_media_call_content_ready_to_accept (l->data);

  if (notready && !_tp_base_media_channel_is_held (self))
    return;

  if (klass->accept != NULL)
    klass->accept (self);

  TP_BASE_CALL_CHANNEL_CLASS (tp_base_media_call_channel_parent_class)->accept (bcc);

  self->priv->accepted = TRUE;
}

static void
streams_changed_cb (GObject *stream,
    gpointer spec,
    TpBaseMediaCallChannel *self)
{
  tp_base_media_call_channel_try_accept (self);

  if (self->priv->accepted)
    g_signal_handlers_disconnect_by_func (stream, streams_changed_cb, self);
}

static void
wait_for_streams_to_be_receiving (TpBaseMediaCallChannel *self)
{
  TpBaseCallChannel *bcc = TP_BASE_CALL_CHANNEL (self);
  GList *l;

  for (l = tp_base_call_channel_get_contents (bcc); l; l = l->next)
    {
      TpBaseCallContent *content = l->data;
      GList *l_stream;

      if (tp_base_call_content_get_disposition (content) !=
              TP_CALL_CONTENT_DISPOSITION_INITIAL)
        continue;

      for (l_stream = tp_base_call_content_get_streams (content);
           l_stream;
           l_stream = l_stream->next)
        {
          TpBaseCallStream *stream = l_stream->data;

          g_signal_connect (stream, "notify::receiving-state",
              G_CALLBACK (streams_changed_cb), self);
          g_signal_connect (stream, "notify::remote-members",
              G_CALLBACK (streams_changed_cb), self);
        }
    }
}

static void
tp_base_media_call_channel_accept (TpBaseCallChannel *bcc)
{
  TpBaseMediaCallChannel *self = TP_BASE_MEDIA_CALL_CHANNEL (bcc);

  tp_base_media_call_channel_try_accept (self);

  if (!self->priv->accepted)
    wait_for_streams_to_be_receiving (self);
}

static void
tp_base_media_call_channel_remote_accept (TpBaseCallChannel *self)
{
  g_list_foreach (tp_base_call_channel_get_contents (self),
      (GFunc) _tp_base_media_call_content_remote_accepted, NULL);
}

static gboolean
tp_base_media_call_channel_is_connected (TpBaseCallChannel *self)
{
  GList *l;

  g_return_val_if_fail (TP_IS_BASE_MEDIA_CALL_CHANNEL (self), FALSE);

  for (l = tp_base_call_channel_get_contents (self); l != NULL; l = l->next)
    {
      GList *streams = tp_base_call_content_get_streams (l->data);

      for (; streams != NULL; streams = streams->next)
        {
          GList *endpoints;
          gboolean has_connected_endpoint = FALSE;

          endpoints = tp_base_media_call_stream_get_endpoints (streams->data);
          for (; endpoints != NULL; endpoints = endpoints->next)
            {
              TpStreamEndpointState state = tp_call_stream_endpoint_get_state (
                  endpoints->data, TP_STREAM_COMPONENT_DATA);

              if (state == TP_STREAM_ENDPOINT_STATE_PROVISIONALLY_CONNECTED ||
                  state == TP_STREAM_ENDPOINT_STATE_FULLY_CONNECTED)
                {
                  has_connected_endpoint = TRUE;
                  break;
                }
            }
          if (!has_connected_endpoint)
            return FALSE;
        }
    }

  return TRUE;
}

static void
tp_base_media_call_channel_class_init (TpBaseMediaCallChannelClass *klass)
{
  TpBaseChannelClass *base_channel_class = TP_BASE_CHANNEL_CLASS (klass);
  TpBaseCallChannelClass *base_call_channel_class =
      TP_BASE_CALL_CHANNEL_CLASS (klass);

  g_type_class_add_private (klass, sizeof (TpBaseMediaCallChannelPrivate));

  base_channel_class->get_interfaces = tp_base_media_call_channel_get_interfaces;

  base_call_channel_class->accept = tp_base_media_call_channel_accept;
  base_call_channel_class->remote_accept =
      tp_base_media_call_channel_remote_accept;
  base_call_channel_class->is_connected =
      tp_base_media_call_channel_is_connected;
}

static void
tp_base_media_call_channel_init (TpBaseMediaCallChannel *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_BASE_MEDIA_CALL_CHANNEL, TpBaseMediaCallChannelPrivate);

  self->priv->hold_state = TP_LOCAL_HOLD_STATE_UNHELD;
  self->priv->hold_state_reason = TP_LOCAL_HOLD_STATE_REASON_REQUESTED;

  g_signal_connect (self, "call-members-changed",
      G_CALLBACK (call_members_changed_cb), NULL);
}

static void update_hold_state (TpBaseMediaCallChannel *self);

static void
set_hold_state (TpBaseMediaCallChannel *self,
    TpLocalHoldState hold_state,
    TpLocalHoldStateReason hold_state_reason)
{
  TpBaseMediaCallChannelClass *klass =
      TP_BASE_MEDIA_CALL_CHANNEL_GET_CLASS (self);
  gboolean changed;

  g_return_if_fail (hold_state_reason < TP_NUM_LOCAL_HOLD_STATE_REASONS);

  changed = (self->priv->hold_state != hold_state);

  self->priv->hold_state = hold_state;
  self->priv->hold_state_reason = hold_state_reason;

  if (changed)
    {
      if (klass->hold_state_changed != NULL)
        klass->hold_state_changed (self, hold_state, hold_state_reason);

      tp_svc_channel_interface_hold_emit_hold_state_changed (self, hold_state,
          hold_state_reason);

      update_hold_state (self);
    }
}

static void
update_hold_state (TpBaseMediaCallChannel *self)
{
  TpBaseCallChannel *bcc = TP_BASE_CALL_CHANNEL (self);
  GList *l, *l2;
  gboolean is_started = TRUE;
  gboolean is_stopped = TRUE;
  TpLocalHoldState new_hold_state = self->priv->hold_state;

  if (self->priv->hold_state != TP_LOCAL_HOLD_STATE_PENDING_HOLD &&
      self->priv->hold_state != TP_LOCAL_HOLD_STATE_PENDING_UNHOLD)
    return;

  if (!tp_base_call_channel_is_accepted (TP_BASE_CALL_CHANNEL (self)))
    goto done;

  for (l = tp_base_call_channel_get_contents (bcc); l != NULL; l = l->next)
    {
      for (l2 = tp_base_call_content_get_streams (l->data);
           l2 != NULL; l2 = l2->next)
        {
          TpBaseMediaCallStream *stream = TP_BASE_MEDIA_CALL_STREAM (l2->data);
          GHashTable *members = _tp_base_call_stream_get_remote_members (
              TP_BASE_CALL_STREAM (stream));
          TpSendingState local = tp_base_call_stream_get_local_sending_state (
              TP_BASE_CALL_STREAM (stream));
          GHashTableIter iter;
          gpointer key, value;
          gboolean wants_receive = FALSE;

          g_hash_table_iter_init (&iter, members);
          while (g_hash_table_iter_next (&iter, &key, &value))
            {
              TpSendingState member_state = GPOINTER_TO_INT (value);

              if (member_state == TP_SENDING_STATE_PENDING_SEND ||
                  member_state == TP_SENDING_STATE_SENDING)
                {
                  wants_receive = TRUE;
                  break;
                }
            }

          tp_base_media_call_stream_update_receiving_state (stream);
          tp_base_media_call_stream_update_sending_state (stream);

          if (tp_base_media_call_stream_get_sending_state (stream) !=
                  TP_STREAM_FLOW_STATE_STOPPED ||
              tp_base_media_call_stream_get_receiving_state (stream) !=
                  TP_STREAM_FLOW_STATE_STOPPED)
            is_stopped = FALSE;
          if ((tp_base_media_call_stream_get_sending_state (stream) !=
                  TP_STREAM_FLOW_STATE_STARTED &&
                  local == TP_SENDING_STATE_SENDING) ||
              (tp_base_media_call_stream_get_receiving_state (stream) !=
                  TP_STREAM_FLOW_STATE_STARTED &&
                  wants_receive))
            is_started = FALSE;
        }
    }

done:

  if (self->priv->hold_state == TP_LOCAL_HOLD_STATE_PENDING_HOLD &&
      is_stopped)
      new_hold_state = TP_LOCAL_HOLD_STATE_HELD;
  else if (self->priv->hold_state == TP_LOCAL_HOLD_STATE_PENDING_UNHOLD &&
      is_started)
      new_hold_state = TP_LOCAL_HOLD_STATE_UNHELD;

  if (new_hold_state != self->priv->hold_state)
    set_hold_state (self, new_hold_state, self->priv->hold_state_reason);
}

static void
hold_change_failed (TpBaseMediaCallChannel *self)
{
  TpBaseCallChannel *bcc = TP_BASE_CALL_CHANNEL (self);
  GList *l, *l2;

  if (self->priv->hold_state != TP_LOCAL_HOLD_STATE_PENDING_UNHOLD)
    return;

  set_hold_state (self, TP_LOCAL_HOLD_STATE_PENDING_HOLD,
      TP_LOCAL_HOLD_STATE_REASON_RESOURCE_NOT_AVAILABLE);

  for (l = tp_base_call_channel_get_contents (bcc); l != NULL; l = l->next)
    {
      for (l2 = tp_base_call_content_get_streams (l->data);
           l2 != NULL; l2 = l2->next)
        {
          TpBaseMediaCallStream *stream = TP_BASE_MEDIA_CALL_STREAM (l2->data);

          tp_base_media_call_stream_update_receiving_state (stream);
          tp_base_media_call_stream_update_sending_state (stream);
        }
    }

  /* Ensure we escape channel pending state if there is no more pending stream state
   * change. */
  update_hold_state (self);
}

static void
tp_base_media_call_channel_get_hold_state (
    TpSvcChannelInterfaceHold *hold_iface,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallChannel *self = TP_BASE_MEDIA_CALL_CHANNEL (hold_iface);

  tp_svc_channel_interface_hold_return_from_get_hold_state (context,
      self->priv->hold_state, self->priv->hold_state_reason);
}

static void
tp_base_media_call_channel_request_hold (
    TpSvcChannelInterfaceHold *hold_iface,
    gboolean hold,
    DBusGMethodInvocation *context)
{
  TpBaseMediaCallChannel *self = TP_BASE_MEDIA_CALL_CHANNEL (hold_iface);

  if ((hold && (self->priv->hold_state == TP_LOCAL_HOLD_STATE_HELD ||
              self->priv->hold_state == TP_LOCAL_HOLD_STATE_PENDING_HOLD)) ||
      (!hold && (self->priv->hold_state == TP_LOCAL_HOLD_STATE_UNHELD ||
          self->priv->hold_state == TP_LOCAL_HOLD_STATE_PENDING_UNHOLD)))
    {
      self->priv->hold_state_reason = TP_LOCAL_HOLD_STATE_REASON_REQUESTED;
      goto out;
    }

  if (hold)
    {
      set_hold_state (self, TP_LOCAL_HOLD_STATE_PENDING_HOLD,
          TP_LOCAL_HOLD_STATE_REASON_REQUESTED);
    }
  else
    {
      set_hold_state (self, TP_LOCAL_HOLD_STATE_PENDING_UNHOLD,
          TP_LOCAL_HOLD_STATE_REASON_REQUESTED);
    }

 out:
  tp_svc_channel_interface_hold_return_from_request_hold (context);
}

static void
hold_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcChannelInterfaceHoldClass *klass =
      (TpSvcChannelInterfaceHoldClass *) g_iface;

#define IMPLEMENT(x, suffix) tp_svc_channel_interface_hold_implement_##x (\
    klass, tp_base_media_call_channel_##x##suffix)
  IMPLEMENT(get_hold_state,);
  IMPLEMENT(request_hold,);
#undef IMPLEMENT
}

void
_tp_base_media_call_channel_endpoint_state_changed (
    TpBaseMediaCallChannel *self)
{
  TpBaseChannel *bc = TP_BASE_CHANNEL (self);
  TpBaseCallChannel *bcc = TP_BASE_CALL_CHANNEL (self);

  switch (tp_base_call_channel_get_state (bcc))
    {
    case TP_CALL_STATE_INITIALISING:
      if (_tp_base_call_channel_is_connected (bcc))
        {
          tp_base_call_channel_set_state (bcc, TP_CALL_STATE_INITIALISED,
              tp_base_channel_get_self_handle (bc),
              TP_CALL_STATE_CHANGE_REASON_PROGRESS_MADE, "",
              "There is a connected endpoint for each stream");
        }
      break;
    case TP_CALL_STATE_ACTIVE:
      if (!_tp_base_call_channel_is_connected (bcc))
        {
          tp_base_call_channel_set_state (bcc, TP_CALL_STATE_ACCEPTED,
              tp_base_channel_get_self_handle (bc),
              TP_CALL_STATE_CHANGE_REASON_CONNECTIVITY_ERROR,
              TP_ERROR_STR_CONNECTION_LOST,
              "There is no longer connected endpoint for each stream");
        }
      break;
    case TP_CALL_STATE_ACCEPTED:
      if (_tp_base_call_channel_is_connected (bcc))
        {
          tp_base_call_channel_set_state (bcc, TP_CALL_STATE_ACTIVE,
              tp_base_channel_get_self_handle (bc),
              TP_CALL_STATE_CHANGE_REASON_PROGRESS_MADE, "",
              "There is a connected endpoint for each stream");
        }
      break;
    default:
      break;
    }
}

gboolean
_tp_base_media_channel_is_held (TpBaseMediaCallChannel *self)
{
  switch (self->priv->hold_state)
    {
    case TP_LOCAL_HOLD_STATE_PENDING_HOLD:
    case TP_LOCAL_HOLD_STATE_HELD:
      return TRUE;
    case TP_LOCAL_HOLD_STATE_PENDING_UNHOLD:
    case TP_LOCAL_HOLD_STATE_UNHELD:
      return FALSE;
    default:
      g_assert_not_reached ();
      return FALSE;
    }
}

gboolean
_tp_base_media_call_channel_streams_sending_state_changed (
    TpBaseMediaCallChannel *self,
    gboolean success)
{
  gboolean was_held =
      (self->priv->hold_state != TP_LOCAL_HOLD_STATE_UNHELD);

  if (success)
    update_hold_state (self);
  else
    hold_change_failed (self);

  return was_held;
}

gboolean
_tp_base_media_call_channel_streams_receiving_state_changed (
    TpBaseMediaCallChannel *self,
    gboolean success)
{
  gboolean was_held =
      (self->priv->hold_state != TP_LOCAL_HOLD_STATE_UNHELD);

  if (success)
    update_hold_state (self);
  else
    hold_change_failed (self);

  return was_held;
}

/**
 * tp_base_media_call_channel_get_local_hold_state:
 * @channel: a #TpBaseMediaCallChannel
 * @reason: pointer to a location where to store the @reason, or %NULL
 *
 * <!-- -->
 *
 * Returns: The current hold state
 *
 * Since: 0.17.6
 */

TpLocalHoldState
tp_base_media_call_channel_get_local_hold_state (
    TpBaseMediaCallChannel *channel, TpLocalHoldStateReason *reason)
{
  g_return_val_if_fail (TP_IS_BASE_MEDIA_CALL_CHANNEL (channel),
      TP_LOCAL_HOLD_STATE_UNHELD);

  if (reason)
    *reason = channel->priv->hold_state_reason;

  return channel->priv->hold_state;
}
