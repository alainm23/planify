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

/**
 * SECTION:call-channel
 * @title: TpCallChannel
 * @short_description: proxy object for a call channel
 *
 * #TpCallChannel is a sub-class of #TpChannel providing convenient API
 * to make calls
 */

/**
 * TpCallChannel:
 *
 * Data structure representing a #TpCallChannel.
 *
 * Since: 0.17.5
 */

/**
 * TpCallChannelClass:
 *
 * The class of a #TpCallChannel.
 *
 * Since: 0.17.5
 */

#include "config.h"

#include "telepathy-glib/call-channel.h"

#include <config.h>

#include <telepathy-glib/call-content.h>
#include <telepathy-glib/call-misc.h>
#include <telepathy-glib/call-stream.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CALL
#include "telepathy-glib/automatic-client-factory-internal.h"
#include "telepathy-glib/call-internal.h"
#include "telepathy-glib/channel-internal.h"
#include "telepathy-glib/connection-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/proxy-internal.h"
#include "telepathy-glib/util-internal.h"

G_DEFINE_TYPE (TpCallChannel, tp_call_channel, TP_TYPE_CHANNEL)

struct _TpCallChannelPrivate
{
  /* Array of TpCallContents */
  GPtrArray *contents;
  TpCallState state;
  TpCallFlags flags;
  GHashTable *state_details;
  TpCallStateReason *state_reason;
  gboolean hardware_streaming;
  /* TpContact -> TpCallMemberFlags */
  GHashTable *members;
  gboolean initial_audio;
  gboolean initial_video;
  gchar *initial_audio_name;
  gchar *initial_video_name;
  gboolean mutable_contents;
  TpLocalHoldState hold_state;
  TpLocalHoldStateReason hold_state_reason;

  GSimpleAsyncResult *core_result;
  gboolean properties_retrieved;
  gboolean initial_members_retrieved;
  gboolean hold_state_retrieved;
};

enum /* props */
{
  PROP_CONTENTS = 1,
  PROP_STATE,
  PROP_FLAGS,
  PROP_STATE_DETAILS,
  PROP_STATE_REASON,
  PROP_HARDWARE_STREAMING,
  PROP_INITIAL_AUDIO,
  PROP_INITIAL_VIDEO,
  PROP_INITIAL_AUDIO_NAME,
  PROP_INITIAL_VIDEO_NAME,
  PROP_MUTABLE_CONTENTS,
  PROP_HOLD_STATE,
  PROP_HOLD_STATE_REASON,
};

enum /* signals */
{
  CONTENT_ADDED,
  CONTENT_REMOVED,
  STATE_CHANGED,
  MEMBERS_CHANGED,
  LAST_SIGNAL
};

static guint _signals[LAST_SIGNAL] = { 0, };

static TpCallContent *
_tp_call_content_new (TpCallChannel *self,
    const gchar *object_path)
{
  return g_object_new (TP_TYPE_CALL_CONTENT,
      "bus-name", tp_proxy_get_bus_name (self),
      "dbus-daemon", tp_proxy_get_dbus_daemon (self),
      "dbus-connection", tp_proxy_get_dbus_connection (self),
      "object-path", object_path,
      "connection", tp_channel_get_connection ((TpChannel *) self),
      "channel", self,
      "factory", tp_proxy_get_factory (self),
      NULL);
}

/**
 * TpCallStateReason:
 * @actor: the contact responsible for the change, or 0 if no contact was
 *  responsible
 * @reason: the reason for the change. If
 *  #TP_CALL_STATE_CHANGE_REASON_USER_REQUESTED then the @actor member will
 *  dictate whether it was the local user or a remote contact responsible
 * @dbus_reason: A specific reason for the change, which may be a D-Bus error in
 *  the Telepathy namespace, a D-Bus error in any other namespace
 *  (for implementation-specific errors), or the empty string to indicate that
 *  the state change was not an error
 * @message: A developer readable debug message giving the reason for the state
 *  change.
 *
 * Data structure representing the reason for a call state change.
 *
 * Since: 0.17.5
 */

static TpCallStateReason *
_tp_call_state_reason_new_full (TpHandle actor,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message)
{
  TpCallStateReason *r;

  r = g_slice_new0 (TpCallStateReason);
  r->actor = actor;
  r->reason = reason;
  r->dbus_reason = g_strdup (dbus_reason);
  r->message = g_strdup (message);
  r->ref_count = 1;

  return r;
}

TpCallStateReason *
_tp_call_state_reason_new (const GValueArray *value_array)
{
  TpHandle handle;
  TpCallStateChangeReason reason;
  const gchar *dbus_reason;
  const gchar *message;

  tp_value_array_unpack ((GValueArray *) value_array, 4,
      &handle,
      &reason,
      &dbus_reason,
      &message);

  return _tp_call_state_reason_new_full (handle, reason, dbus_reason, message);
}

TpCallStateReason *
_tp_call_state_reason_ref (TpCallStateReason *r)
{
  g_atomic_int_inc (&r->ref_count);
  return r;
}

void
_tp_call_state_reason_unref (TpCallStateReason *r)
{
  g_return_if_fail (r != NULL);

  if (g_atomic_int_dec_and_test (&r->ref_count))
    {
      g_free (r->dbus_reason);
      g_free (r->message);
      g_slice_free (TpCallStateReason, r);
    }
}

G_DEFINE_BOXED_TYPE (TpCallStateReason, tp_call_state_reason,
    _tp_call_state_reason_ref, _tp_call_state_reason_unref);

/* Convert GHashTable<TpHandle, anything> to GHashTable<TpContact, anything>.
 * Assuming value does not need to be copied */
GHashTable *
_tp_call_members_convert_table (TpConnection *connection,
    GHashTable *table,
    GHashTable *identifiers)
{
  GHashTable *result;
  GHashTableIter iter;
  gpointer key, value;

  result = g_hash_table_new_full (NULL, NULL, g_object_unref, NULL);

  g_hash_table_iter_init (&iter, table);
  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      TpHandle handle = GPOINTER_TO_UINT (key);
      const gchar *id;
      TpContact *contact;

      id = g_hash_table_lookup (identifiers, key);
      if (id == NULL)
        {
          DEBUG ("Missing identifier for member %u - broken CM", handle);
          continue;
        }

      contact = tp_connection_dup_contact_if_possible (connection, handle, id);
      if (contact == NULL)
        {
          DEBUG ("Can't create contact for (%u, %s) pair - CM does not have "
              "immutable handles?", handle, id);
          continue;
        }

      g_hash_table_insert (result, contact, value);
    }

  return result;
}

/* Convert GArray<TpHandle> to GPtrArray<TpContact>.
 * Assuming the TpContact already exists. */
GPtrArray *
_tp_call_members_convert_array (TpConnection *connection,
    const GArray *array)
{
  GPtrArray *result;
  guint i;

  result = g_ptr_array_new_full (array->len, g_object_unref);

  for (i = 0; i < array->len; i++)
    {
      TpHandle handle = g_array_index (array, TpHandle, i);
      TpContact *contact;

      /* The contact is supposed to already exists */
      contact = tp_connection_dup_contact_if_possible (connection,
          handle, NULL);
      if (contact == NULL)
        {
          DEBUG ("No TpContact found for handle %u", handle);
          continue;
        }

      g_ptr_array_add (result, contact);
    }

  return result;
}

static TpCallContent *
ensure_content (TpCallChannel *self,
    const gchar *object_path)
{
  TpCallContent *content;
  guint i;

  for (i = 0; i < self->priv->contents->len; i++)
    {
      content = g_ptr_array_index (self->priv->contents, i);

      if (!tp_strdiff (tp_proxy_get_object_path (content), object_path))
          return content;
    }

  DEBUG ("Content added: %s", object_path);

  content = _tp_call_content_new (self, object_path);
  g_ptr_array_add (self->priv->contents, content);
  g_signal_emit (self, _signals[CONTENT_ADDED], 0, content);

  return content;
}

static void
content_added_cb (TpChannel *channel,
    const gchar *object_path,
    gpointer user_data,
    GObject *weak_object)
{
  TpCallChannel *self = (TpCallChannel *) channel;

  if (!self->priv->properties_retrieved)
    return;

  ensure_content (self, object_path);
}

static void
content_removed_cb (TpChannel *channel,
    const gchar *object_path,
    const GValueArray *reason,
    gpointer user_data,
    GObject *weak_object)
{
  TpCallChannel *self = (TpCallChannel *) channel;
  guint i;

  if (!self->priv->properties_retrieved)
    return;

  for (i = 0; i < self->priv->contents->len; i++)
    {
      TpCallContent *content = g_ptr_array_index (self->priv->contents, i);

      if (!tp_strdiff (tp_proxy_get_object_path (content), object_path))
        {
          TpCallStateReason *r;

          DEBUG ("Content removed: %s", object_path);

          r = _tp_call_state_reason_new (reason);

          g_object_ref (content);
          g_ptr_array_remove_index_fast (self->priv->contents, i);
          g_signal_emit (self, _signals[CONTENT_REMOVED], 0, content, r);
          g_signal_emit_by_name (content, "removed");
          g_object_unref (content);

          _tp_call_state_reason_unref (r);

          return;
        }
    }

  DEBUG ("Content '%s' removed but not found", object_path);
}

static const gchar *
call_state_to_string (TpCallState state)
{
  switch (state)
    {
      case TP_CALL_STATE_UNKNOWN:
        return "unknown";
      case TP_CALL_STATE_PENDING_INITIATOR:
        return "pending-initiator";
      case TP_CALL_STATE_INITIALISING:
        return "initialising";
      case TP_CALL_STATE_INITIALISED:
        return "initialised";
      case TP_CALL_STATE_ACCEPTED:
        return "accepted";
      case TP_CALL_STATE_ACTIVE:
        return "active";
      case TP_CALL_STATE_ENDED:
        return "ended";
    }
  return "invalid";
}

static void
call_state_changed_cb (TpChannel *channel,
    guint state,
    guint flags,
    const GValueArray *reason,
    GHashTable *details,
    gpointer user_data,
    GObject *weak_object)
{
  TpCallChannel *self = (TpCallChannel *) channel;

  if (!self->priv->properties_retrieved)
    return;

  DEBUG ("Call state changed to %s (flags: %u)", call_state_to_string (state),
      flags);

  tp_clear_pointer (&self->priv->state_reason, _tp_call_state_reason_unref);
  tp_clear_pointer (&self->priv->state_details, g_hash_table_unref);

  self->priv->state = state;
  self->priv->flags = flags;
  self->priv->state_reason = _tp_call_state_reason_new (reason);
  self->priv->state_details = g_hash_table_ref (details);

  g_object_notify ((GObject *) self, "state");
  g_object_notify ((GObject *) self, "flags");
  g_object_notify ((GObject *) self, "state-reason");
  g_object_notify ((GObject *) self, "state-details");

  g_signal_emit (self, _signals[STATE_CHANGED], 0, self->priv->state,
      self->priv->flags, self->priv->state_reason, self->priv->state_details);
}

typedef struct
{
  TpCallChannel *self;
  GHashTable *updates;
  GPtrArray *removed;
  TpCallStateReason *reason;
} UpdateCallMembersData;


static void
channel_maybe_core_prepared (TpCallChannel *self)
{
  if (self->priv->core_result == NULL)
    return;

  if (self->priv->initial_members_retrieved &&
      self->priv->properties_retrieved &&
      self->priv->hold_state_retrieved)
    {
      g_simple_async_result_complete (self->priv->core_result);
      g_clear_object (&self->priv->core_result);
    }
}

static void
update_call_members_prepared_cb (GObject *object,
    GAsyncResult *result,
    gpointer user_data)
{
  UpdateCallMembersData *data = user_data;
  TpCallChannel *self = data->self;
  GError *error = NULL;

  if (!_tp_channel_contacts_queue_prepare_finish ((TpChannel *) self,
      result, NULL, &error))
    {
      DEBUG ("Error preparing call members: %s", error->message);
      g_clear_error (&error);
    }

  tp_g_hash_table_update (self->priv->members, data->updates,
      g_object_ref, NULL);

  if (data->removed != NULL)
    {
      guint i;

      for (i = 0; i < data->removed->len; i++)
        {
          g_hash_table_remove (self->priv->members,
              g_ptr_array_index (data->removed, i));
        }
    }

  if (!self->priv->initial_members_retrieved)
    {
      self->priv->initial_members_retrieved = TRUE;

      channel_maybe_core_prepared (self);
    }
  else
    {
      g_signal_emit (self, _signals[MEMBERS_CHANGED], 0,
          data->updates, data->removed, data->reason);
    }

  tp_clear_pointer (&data->updates, g_hash_table_unref);
  tp_clear_pointer (&data->removed, g_ptr_array_unref);
  tp_clear_pointer (&data->reason, _tp_call_state_reason_unref);
  g_slice_free (UpdateCallMembersData, data);
}

static void
update_call_members (TpCallChannel *self,
    GHashTable *updates,
    GPtrArray *removed,
    TpCallStateReason *reason)
{
  GHashTableIter iter;
  gpointer key, value;
  GPtrArray *contacts;
  UpdateCallMembersData *data;

  /* We want to expose only prepared contacts. Collect TpContact objects and
   * prepared them in the channel's queue to make sure it does not reorder
   * events.
   * Applications where delay to display the call is critical shouldn't set
   * contact features on the factory, in which case this becomes no-op.
   */

  contacts = g_ptr_array_new_full (g_hash_table_size (updates),
      g_object_unref);

  g_hash_table_iter_init (&iter, updates);
  while (g_hash_table_iter_next (&iter, &key, &value))
    g_ptr_array_add (contacts, g_object_ref (key));

  data = g_slice_new0 (UpdateCallMembersData);
  data->self = self;
  data->updates = g_hash_table_ref (updates);
  data->removed = removed != NULL ? g_ptr_array_ref (removed) : NULL;
  data->reason = reason != NULL ? _tp_call_state_reason_ref (reason) : NULL;

  _tp_channel_contacts_queue_prepare_async ((TpChannel *) self,
      contacts, update_call_members_prepared_cb, data);
}

static void
call_members_changed_cb (TpChannel *channel,
    GHashTable *updates,
    GHashTable *identifiers,
    const GArray *removed,
    const GValueArray *reason,
    gpointer user_data,
    GObject *weak_object)
{
  TpCallChannel *self = (TpCallChannel *) channel;
  TpConnection *connection;
  GHashTable *updates_contacts;
  GPtrArray *removed_contacts;
  TpCallStateReason *r;

  DEBUG ("Call members: %d changed, %d removed",
      g_hash_table_size (updates), removed->len);

  connection = tp_channel_get_connection (channel);
  updates_contacts = _tp_call_members_convert_table (connection,
      updates, identifiers);
  removed_contacts = _tp_call_members_convert_array (connection,
      removed);
  r = _tp_call_state_reason_new (reason);

  update_call_members (self, updates_contacts, removed_contacts, r);

  g_hash_table_unref (updates_contacts);
  g_ptr_array_unref (removed_contacts);
  _tp_call_state_reason_unref (r);
}

static void
got_all_properties_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpCallChannel *self = (TpCallChannel *) proxy;
  TpConnection *connection;
  GPtrArray *contents;
  GHashTable *members;
  GHashTable *identifiers;
  GHashTable *contacts;
  guint i;

  if (error != NULL)
    {
      DEBUG ("Could not get the call channel properties: %s", error->message);
      g_simple_async_result_set_from_error (self->priv->core_result, error);
      g_simple_async_result_complete (self->priv->core_result);
      g_clear_object (&self->priv->core_result);
      return;
    }

  connection = tp_channel_get_connection ((TpChannel *) self);
  g_assert (tp_connection_has_immortal_handles (connection));

  self->priv->properties_retrieved = TRUE;

  contents = tp_asv_get_boxed (properties,
      "Contents", TP_ARRAY_TYPE_OBJECT_PATH_LIST);
  self->priv->state = tp_asv_get_uint32 (properties,
      "CallState", NULL);
  self->priv->flags = tp_asv_get_uint32 (properties,
      "CallFlags", NULL);
  self->priv->state_details = g_hash_table_ref (tp_asv_get_boxed (properties,
      "CallStateDetails", TP_HASH_TYPE_STRING_VARIANT_MAP));
  self->priv->state_reason = _tp_call_state_reason_new (tp_asv_get_boxed (properties,
      "CallStateReason", TP_STRUCT_TYPE_CALL_STATE_REASON));
  members = tp_asv_get_boxed (properties,
      "CallMembers", TP_HASH_TYPE_CALL_MEMBER_MAP);
  identifiers = tp_asv_get_boxed (properties,
      "MemberIdentifiers", TP_HASH_TYPE_HANDLE_IDENTIFIER_MAP);

  contacts = _tp_call_members_convert_table (connection, members, identifiers);
  update_call_members (self, contacts, NULL, NULL);
  g_hash_table_unref (contacts);

  for (i = 0; i < contents->len; i++)
    {
      const gchar *object_path = g_ptr_array_index (contents, i);

      DEBUG ("Initial content added: %s", object_path);

      g_ptr_array_add (self->priv->contents,
          _tp_call_content_new (self, object_path));
    }

  /* core_result will be complete in update_call_members_prepared_cb() when
   * the initial members are prepared or when the hold state is retrived. */
}

static void
hold_state_changed_cb (TpChannel *proxy,
    guint arg_HoldState,
    guint arg_Reason,
    gpointer user_data, GObject *weak_object)
{
  TpCallChannel *self = TP_CALL_CHANNEL (proxy);

  if (!self->priv->hold_state_retrieved)
    return;

  self->priv->hold_state = arg_HoldState;
  self->priv->hold_state_reason = arg_Reason;

  g_object_notify (G_OBJECT (proxy), "hold-state");
  g_object_notify (G_OBJECT (proxy), "hold-state-reason");
}

static void
got_hold_state_cb (TpChannel *proxy, guint arg_HoldState, guint arg_Reason,
    const GError *error, gpointer user_data, GObject *weak_object)
{
  TpCallChannel *self = TP_CALL_CHANNEL (proxy);

  if (error != NULL)
    {
      DEBUG ("Could not get the call channel hold state: %s", error->message);
      g_simple_async_result_set_from_error (self->priv->core_result, error);
      g_simple_async_result_complete (self->priv->core_result);
      g_clear_object (&self->priv->core_result);
      return;
    }

  self->priv->hold_state = arg_HoldState;
  self->priv->hold_state_reason = arg_Reason;
  self->priv->hold_state_retrieved = TRUE;

  channel_maybe_core_prepared (self);
}

static void
_tp_call_channel_prepare_core_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpCallChannel *self = (TpCallChannel *) proxy;
  TpChannel *channel = (TpChannel *) self;

  tp_cli_channel_type_call_connect_to_content_added (channel,
      content_added_cb, NULL, NULL, NULL, NULL);
  tp_cli_channel_type_call_connect_to_content_removed (channel,
      content_removed_cb, NULL, NULL, NULL, NULL);
  tp_cli_channel_type_call_connect_to_call_state_changed (channel,
      call_state_changed_cb, NULL, NULL, NULL, NULL);
  tp_cli_channel_type_call_connect_to_call_members_changed (channel,
      call_members_changed_cb, NULL, NULL, NULL, NULL);

  g_assert (self->priv->core_result == NULL);
  self->priv->core_result = g_simple_async_result_new ((GObject *) self,
      callback, user_data, _tp_call_channel_prepare_core_async);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CHANNEL_TYPE_CALL,
      got_all_properties_cb, NULL, NULL, NULL);

  if (tp_proxy_has_interface_by_id (proxy,
          TP_IFACE_QUARK_CHANNEL_INTERFACE_HOLD))
    {
      tp_cli_channel_interface_hold_connect_to_hold_state_changed (channel,
          hold_state_changed_cb, NULL, NULL, NULL, NULL);

      tp_cli_channel_interface_hold_call_get_hold_state (channel, -1,
          got_hold_state_cb, NULL, NULL, NULL);
    }
}

static void
tp_call_channel_constructed (GObject *obj)
{
  TpCallChannel *self = (TpCallChannel *) obj;
  GHashTable *properties = _tp_channel_get_immutable_properties (
      (TpChannel *) self);

  G_OBJECT_CLASS (tp_call_channel_parent_class)->constructed (obj);

  /* We can already set immutable properties */
  self->priv->hardware_streaming = tp_asv_get_boolean (properties,
        TP_PROP_CHANNEL_TYPE_CALL_HARDWARE_STREAMING, NULL);
  self->priv->initial_audio = tp_asv_get_boolean (properties,
        TP_PROP_CHANNEL_TYPE_CALL_INITIAL_AUDIO, NULL);
  self->priv->initial_video = tp_asv_get_boolean (properties,
        TP_PROP_CHANNEL_TYPE_CALL_INITIAL_VIDEO, NULL);
  self->priv->initial_audio_name = g_strdup (tp_asv_get_string (properties,
        TP_PROP_CHANNEL_TYPE_CALL_INITIAL_AUDIO_NAME));
  self->priv->initial_video_name = g_strdup (tp_asv_get_string (properties,
        TP_PROP_CHANNEL_TYPE_CALL_INITIAL_VIDEO_NAME));
  self->priv->mutable_contents = tp_asv_get_boolean (properties,
        TP_PROP_CHANNEL_TYPE_CALL_MUTABLE_CONTENTS, NULL);

  if (!self->priv->initial_audio)
    tp_clear_pointer (&self->priv->initial_audio_name, g_free);
  if (!self->priv->initial_video)
    tp_clear_pointer (&self->priv->initial_video_name, g_free);
}

static void
tp_call_channel_dispose (GObject *obj)
{
  TpCallChannel *self = (TpCallChannel *) obj;

  g_assert (self->priv->core_result == NULL);

  tp_clear_pointer (&self->priv->contents, g_ptr_array_unref);
  tp_clear_pointer (&self->priv->state_details, g_hash_table_unref);
  tp_clear_pointer (&self->priv->state_reason, _tp_call_state_reason_unref);
  tp_clear_pointer (&self->priv->members, g_hash_table_unref);
  tp_clear_pointer (&self->priv->initial_audio_name, g_free);
  tp_clear_pointer (&self->priv->initial_video_name, g_free);

  G_OBJECT_CLASS (tp_call_channel_parent_class)->dispose (obj);
}

static void
tp_call_channel_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpCallChannel *self = (TpCallChannel *) object;

  switch (property_id)
    {
      case PROP_CONTENTS:
        g_value_set_boxed (value, self->priv->contents);
        break;

      case PROP_STATE:
        g_value_set_uint (value, self->priv->state);
        break;

      case PROP_FLAGS:
        g_value_set_uint (value, self->priv->flags);
        break;

      case PROP_STATE_DETAILS:
        g_value_set_boxed (value, self->priv->state_details);
        break;

      case PROP_STATE_REASON:
        g_value_set_boxed (value, self->priv->state_reason);
        break;

      case PROP_HARDWARE_STREAMING:
        g_value_set_boolean (value, self->priv->hardware_streaming);
        break;

      case PROP_INITIAL_AUDIO:
        g_value_set_boolean (value, self->priv->initial_audio);
        break;

      case PROP_INITIAL_VIDEO:
        g_value_set_boolean (value, self->priv->initial_video);
        break;

      case PROP_INITIAL_AUDIO_NAME:
        g_value_set_string (value, self->priv->initial_audio_name);
        break;

      case PROP_INITIAL_VIDEO_NAME:
        g_value_set_string (value, self->priv->initial_video_name);
        break;

      case PROP_MUTABLE_CONTENTS:
        g_value_set_boolean (value, self->priv->mutable_contents);
        break;

      case PROP_HOLD_STATE:
        g_value_set_uint (value, self->priv->hold_state);
        break;

      case PROP_HOLD_STATE_REASON:
        g_value_set_uint (value, self->priv->hold_state_reason);
        break;

     default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

enum {
    FEAT_CORE,
    N_FEAT
};

static const TpProxyFeature *
tp_call_channel_list_features (TpProxyClass *cls G_GNUC_UNUSED)
{
  static TpProxyFeature features[N_FEAT + 1] = { { 0 } };

  if (G_LIKELY (features[0].name != 0))
    return features;

  /* started from constructed */
  features[FEAT_CORE].name = TP_CALL_CHANNEL_FEATURE_CORE;
  features[FEAT_CORE].prepare_async = _tp_call_channel_prepare_core_async;
  features[FEAT_CORE].core = TRUE;

  /* assert that the terminator at the end is there */
  g_assert (features[N_FEAT].name == 0);

  return features;
}

static void
tp_call_channel_class_init (TpCallChannelClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);
  TpProxyClass *proxy_class = (TpProxyClass *) klass;
  GParamSpec *param_spec;

  gobject_class->constructed = tp_call_channel_constructed;
  gobject_class->get_property = tp_call_channel_get_property;
  gobject_class->dispose = tp_call_channel_dispose;

  proxy_class->list_features = tp_call_channel_list_features;

  g_type_class_add_private (gobject_class, sizeof (TpCallChannelPrivate));

  /* FIXME: Should be annoted with
   *
   * Type: GLib.PtrArray<TelepathyGLib.CallContent>
   * Transfer: container
   *
   * But it does not work (bgo#663846) and makes gtkdoc fail myserably.
   */

  /**
   * TpCallChannel:contents:
   *
   * #GPtrArray of #TpCallContent objects. The list of content objects that are
   * part of this call.
   *
   * It is NOT guaranteed that %TP_CALL_CONTENT_FEATURE_CORE is prepared on
   * those objects.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("contents", "Contents",
      "The content objects of this call",
      G_TYPE_PTR_ARRAY,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_CONTENTS, param_spec);

  /**
   * TpCallChannel:state:
   *
   * A #TpCallState specifying the state of the call.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("state", "Call state",
      "The state of the call",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_STATE, param_spec);

  /**
   * TpCallChannel:flags:
   *
   * A #TpCallFlags specifying the flags of the call state.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("flags", "Call flags",
      "The flags of the call",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_FLAGS, param_spec);

  /**
   * TpCallChannel:state-details:
   *
   * Detailed infoermation about #TpCallChannel:state. It is a #GHashTable
   * mapping gchar*->GValue, it can be accessed using the tp_asv_* functions.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("state-details", "State details",
      "The details of the call",
      G_TYPE_HASH_TABLE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class,
      PROP_STATE_DETAILS, param_spec);

  /**
   * TpCallChannel:state-reason:
   *
   * Reason why #TpCallChannel:state last changed.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("state-reason", "State reason",
      "The reason of the call's state",
      TP_TYPE_CALL_STATE_REASON,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class,
      PROP_STATE_REASON, param_spec);

  /**
   * TpCallChannel:hardware-streaming:
   *
   * Whether or not the streaming is done by dedicated hardware.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("hardware-streaming", "Hardware streaming",
      "Hardware streaming",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class,
      PROP_HARDWARE_STREAMING, param_spec);

  /**
   * TpCallChannel:initial-audio:
   *
   * Whether or not the Call was started with audio.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("initial-audio", "Initial audio",
      "Initial audio",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class,
      PROP_INITIAL_AUDIO, param_spec);

  /**
   * TpCallChannel:initial-video:
   *
   * Whether or not the Call was started with video.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("initial-video", "Initial video",
      "Initial video",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class,
      PROP_INITIAL_VIDEO, param_spec);

  /**
   * TpCallChannel:initial-audio-name:
   *
   * If #TpCallChannel:initial-audio is set to %TRUE, then this property will
   * is the name of the intial audio content, %NULL otherwise.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_string ("initial-audio-name", "Initial audio name",
      "Initial audio name",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class,
      PROP_INITIAL_AUDIO_NAME, param_spec);

  /**
   * TpCallChannel:initial-video-name:
   *
   * If #TpCallChannel:initial-video is set to %TRUE, then this property will
   * is the name of the intial video content, %NULL otherwise.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_string ("initial-video-name", "Initial video name",
      "Initial video name",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class,
      PROP_INITIAL_VIDEO_NAME, param_spec);

  /**
   * TpCallChannel:mutable-contents:
   *
   * Whether or not call contents can be added or removed.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("mutable-contents", "Mutable contents",
      "Mutable contents",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class,
      PROP_MUTABLE_CONTENTS, param_spec);


  /**
   * TpCallChannel:hold-state:
   *
   * A #TpLocalHoldState specifying if the Call is currently held
   *
   * Since: 0.17.6
   */
  param_spec = g_param_spec_uint ("hold-state", "Hold State",
      "The Hold state of the call",
      0, G_MAXUINT, TP_LOCAL_HOLD_STATE_UNHELD,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_HOLD_STATE, param_spec);


  /**
   * TpCallChannel:hold-state-reason:
   *
   * A #TpLocalHoldStateReason specifying why the Call is currently held.
   *
   * Since: 0.17.6
   */
  param_spec = g_param_spec_uint ("hold-state-reason", "Hold State Reason",
      "The reason for the current hold state",
      0, G_MAXUINT, TP_LOCAL_HOLD_STATE_REASON_NONE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_HOLD_STATE_REASON,
      param_spec);


  /**
   * TpCallChannel::content-added:
   * @self: the #TpCallChannel
   * @content: the newly added #TpCallContent
   *
   * The ::content-added signal is emitted whenever a
   * #TpCallContent is added to @self.
   *
   * It is NOT guaranteed that %TP_CALL_CONTENT_FEATURE_CORE is prepared on
   * @content.
   *
   * Since: 0.17.5
   */
  _signals[CONTENT_ADDED] = g_signal_new ("content-added",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      1, G_TYPE_OBJECT);

  /**
   * TpCallChannel::content-removed:
   * @self: the #TpCallChannel
   * @content: the newly removed #TpCallContent
   * @reason: a #TpCallStateReason
   *
   * The ::content-removed signal is emitted whenever a
   * #TpCallContent is removed from @self.
   *
   * It is NOT guaranteed that %TP_CALL_CONTENT_FEATURE_CORE is prepared on
   * @content.
   *
   * Since: 0.17.5
   */
  _signals[CONTENT_REMOVED] = g_signal_new ("content-removed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      2, G_TYPE_OBJECT, TP_TYPE_CALL_STATE_REASON);

  /**
   * TpCallChannel::state-changed:
   * @self: the #TpCallChannel
   * @state: the new #TpCallState
   * @flags: the new #TpCallFlags
   * @reason: the #TpCallStateReason for the change
   * @details: (element-type utf8 GObject.Value): additional details as a
   *   #GHashTable readable using the tp_asv_* functions.
   *
   * The ::state-changed signal is emitted whenever the
   * call state changes.
   *
   * Since: 0.17.5
   */
  _signals[STATE_CHANGED] = g_signal_new ("state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      4, G_TYPE_UINT, G_TYPE_UINT, TP_TYPE_CALL_STATE_REASON,
      G_TYPE_HASH_TABLE);

  /**
   * TpCallChannel::members-changed:
   * @self: the #TpCallChannel
   * @updates: (type GLib.HashTable) (element-type TelepathyGLib.Contact uint):
   *   #GHashTable mapping #TpContact to its new #TpCallMemberFlags
   * @removed: (type GLib.PtrArray) (element-type TelepathyGLib.Contact):
   *  #GPtrArray of #TpContact removed from the call members
   * @reason: the #TpCallStateReason for the change
   *
   * The ::members-changed signal is emitted whenever the call's members
   * changes.
   *
   * The #TpContact objects are guaranteed to have all of the features
   * previously passed to tp_simple_client_factory_add_contact_features()
   * prepared.
   *
   * Since: 0.17.5
   */
  _signals[MEMBERS_CHANGED] = g_signal_new ("members-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      3, G_TYPE_HASH_TABLE, G_TYPE_PTR_ARRAY, TP_TYPE_CALL_STATE_REASON);
}

static void
tp_call_channel_init (TpCallChannel *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), TP_TYPE_CALL_CHANNEL,
      TpCallChannelPrivate);

  self->priv->contents = g_ptr_array_new_with_free_func (g_object_unref);
  self->priv->members = g_hash_table_new_full (NULL, NULL,
      g_object_unref, NULL);
}

TpCallChannel *
_tp_call_channel_new_with_factory (TpSimpleClientFactory *factory,
    TpConnection *conn,
    const gchar *object_path,
    const GHashTable *immutable_properties,
    GError **error)
{
  TpProxy *conn_proxy = (TpProxy *) conn;

  g_return_val_if_fail (TP_IS_CONNECTION (conn), NULL);
  g_return_val_if_fail (object_path != NULL, NULL);
  g_return_val_if_fail (immutable_properties != NULL, NULL);

  if (!tp_dbus_check_valid_object_path (object_path, error))
      return NULL;

  return g_object_new (TP_TYPE_CALL_CHANNEL,
      "connection", conn,
      "dbus-daemon", conn_proxy->dbus_daemon,
      "bus-name", conn_proxy->bus_name,
      "object-path", object_path,
      "handle-type", (guint) TP_UNKNOWN_HANDLE_TYPE,
      "channel-properties", immutable_properties,
      "factory", factory,
      NULL);
}

/**
 * TP_CALL_CHANNEL_FEATURE_CORE:
 *
 * Expands to a call to a function that returns a quark for the "core"
 * feature on a #TpCallChannel.
 *
 * One can ask for a feature to be prepared using the tp_proxy_prepare_async()
 * function, and waiting for it to trigger the callback.
 */
GQuark
tp_call_channel_get_feature_quark_core (void)
{
  return g_quark_from_static_string ("tp-call-channel-feature-core");
}

/**
 * tp_call_channel_get_contents:
 * @self: a #TpCallChannel
 *
 * <!-- -->
 *
 * Returns: (transfer none) (type GLib.PtrArray) (element-type TelepathyGLib.CallContent):
 *  the value of #TpCallChannel:contents
 * Since: 0.17.5
 */
GPtrArray *
tp_call_channel_get_contents (TpCallChannel *self)
{
  g_return_val_if_fail (TP_IS_CALL_CHANNEL (self), NULL);

  return self->priv->contents;
}

/**
 * tp_call_channel_get_state:
 * @self: a #TpCallChannel
 * @flags: (out) (allow-none) (transfer none): a place to set the value of
 *  #TpCallChannel:flags
 * @details: (out) (allow-none) (transfer none): a place to set the value of
 *  #TpCallChannel:state-details
 * @reason: (out) (allow-none) (transfer none): a place to set the value of
 *  #TpCallChannel:state-reason
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallChannel:state
 * Since: 0.17.5
 */
TpCallState
tp_call_channel_get_state (TpCallChannel *self,
    TpCallFlags *flags,
    GHashTable **details,
    TpCallStateReason **reason)
{
  g_return_val_if_fail (TP_IS_CALL_CHANNEL (self), TP_CALL_STATE_UNKNOWN);

  if (flags != NULL)
    *flags = self->priv->flags;
  if (details != NULL)
    *details = self->priv->state_details;
  if (reason != NULL)
    *reason = self->priv->state_reason;

  return self->priv->state;
}

/**
 * tp_call_channel_has_hardware_streaming:
 * @self: a #TpCallChannel
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallChannel:hardware-streaming
 * Since: 0.17.5
 */
gboolean
tp_call_channel_has_hardware_streaming (TpCallChannel *self)
{
  g_return_val_if_fail (TP_IS_CALL_CHANNEL (self), FALSE);

  return self->priv->hardware_streaming;
}

/**
 * tp_call_channel_has_initial_audio:
 * @self: a #TpCallChannel
 * @initial_audio_name: (out) (allow-none) (transfer none): a place to set the
 *  value of #TpCallChannel:initial-audio-name
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallChannel:initial-audio
 * Since: 0.17.5
 */
gboolean
tp_call_channel_has_initial_audio (TpCallChannel *self,
    const gchar **initial_audio_name)
{
  g_return_val_if_fail (TP_IS_CALL_CHANNEL (self), FALSE);

  if (initial_audio_name != NULL)
    *initial_audio_name = self->priv->initial_audio_name;

  return self->priv->initial_audio;
}

/**
 * tp_call_channel_has_initial_video:
 * @self: a #TpCallChannel
 * @initial_video_name: (out) (allow-none) (transfer none): a place to set the
 *  value of #TpCallChannel:initial-video-name
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallChannel:initial-video
 * Since: 0.17.5
 */
gboolean
tp_call_channel_has_initial_video (TpCallChannel *self,
    const gchar **initial_video_name)
{
  g_return_val_if_fail (TP_IS_CALL_CHANNEL (self), FALSE);

  if (initial_video_name != NULL)
    *initial_video_name = self->priv->initial_video_name;

  return self->priv->initial_video;
}

/**
 * tp_call_channel_has_mutable_contents:
 * @self: a #TpCallChannel
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallChannel:mutable-contents
 * Since: 0.17.5
 */
gboolean
tp_call_channel_has_mutable_contents (TpCallChannel *self)
{
  g_return_val_if_fail (TP_IS_CALL_CHANNEL (self), FALSE);

  return self->priv->mutable_contents;
}

/**
 * tp_call_channel_get_members:
 * @self: a #TpCallChannel
 *
 * Get the members of this call.
 *
 * The #TpContact objects are guaranteed to have all of the features
 * previously passed to tp_simple_client_factory_add_contact_features()
 * prepared.
 *
 * Returns: (transfer none) (type GLib.HashTable) (element-type TelepathyGLib.Contact uint):
 *  #GHashTable mapping #TpContact to its new #TpCallMemberFlags
 * Since: 0.17.5
 */
GHashTable *
tp_call_channel_get_members (TpCallChannel *self)
{
  g_return_val_if_fail (TP_IS_CALL_CHANNEL (self), NULL);

  return self->priv->members;
}

/**
 * tp_call_channel_has_dtmf:
 * @self: a #TpCallChannel
 *
 * Whether or not @self can send DTMF tones using
 * tp_call_channel_send_tones_async(). To be able to send DTMF tones, at least
 * one of @self's #TpCallChannel:contents must implement
 * %TP_IFACE_CALL_CONTENT_INTERFACE_DTMF interface.
 *
 * Returns: whether or not @self can send DTMF tones.
 * Since: 0.17.5
 */
gboolean
tp_call_channel_has_dtmf (TpCallChannel *self)
{
  guint i;

  g_return_val_if_fail (TP_IS_CALL_CHANNEL (self), FALSE);

  for (i = 0; i < self->priv->contents->len; i++)
    {
      TpCallContent *content = g_ptr_array_index (self->priv->contents, i);

      if (tp_proxy_has_interface_by_id (content,
              TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_DTMF))
        return TRUE;
    }

  return FALSE;
}


/**
 * tp_call_channel_has_hold:
 * @self: a #TpCallChannel
 *
 * Whether or not @self has the %TP_IFACE_CHANNEL_INTERFACE_HOLD
 * interfaces
 *
 * Returns: whether or not @self supports Hold
 * Since: 0.17.6
 */
gboolean
tp_call_channel_has_hold (TpCallChannel *self)
{
  g_return_val_if_fail (TP_IS_CALL_CHANNEL (self), FALSE);
  g_return_val_if_fail (
      tp_proxy_is_prepared (self, TP_CALL_CHANNEL_FEATURE_CORE), FALSE);

  return tp_proxy_has_interface_by_id (self,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_HOLD);
}

static void
generic_async_cb (TpChannel *channel,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Error: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
    }

  g_simple_async_result_complete (result);
}

/**
 * tp_call_channel_set_ringing_async:
 * @self: a #TpCallChannel
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Indicate that the local user has been alerted about the incoming call.
 *
 * Since: 0.17.5
 */
void
tp_call_channel_set_ringing_async (TpCallChannel *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CALL_CHANNEL (self));

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_call_channel_set_ringing_async);

  tp_cli_channel_type_call_call_set_ringing (TP_CHANNEL (self), -1,
      generic_async_cb, result, g_object_unref, G_OBJECT (self));
}

/**
 * tp_call_channel_set_ringing_finish:
 * @self: a #TpCallChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_call_channel_set_ringing_async().
 *
 * Since: 0.17.5
 */
gboolean
tp_call_channel_set_ringing_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_call_channel_set_ringing_async);
}

/**
 * tp_call_channel_set_queued_async:
 * @self: a #TpCallChannel
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Notifies the CM that the local user is already in a call, so this call has
 * been put in a call-waiting style queue.
 *
 * Since: 0.17.5
 */
void
tp_call_channel_set_queued_async (TpCallChannel *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CALL_CHANNEL (self));

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_call_channel_set_queued_async);

  tp_cli_channel_type_call_call_set_queued (TP_CHANNEL (self), -1,
      generic_async_cb, result, g_object_unref, G_OBJECT (self));
}

/**
 * tp_call_channel_set_queued_finish:
 * @self: a #TpCallChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_call_channel_set_queued_async().
 *
 * Since: 0.17.5
 */
gboolean
tp_call_channel_set_queued_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_call_channel_set_queued_async);
}

/**
 * tp_call_channel_accept_async:
 * @self: a #TpCallChannel
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * For incoming calls with #TpCallChannel:state set to
 * %TP_CALL_STATE_INITIALISED, accept the incoming call. This changes
 * #TpCallChannel:state to %TP_CALL_STATE_ACCEPTED.
 *
 * For outgoing calls with #TpCallChannel:state set to
 * %TP_CALL_STATE_PENDING_INITIATOR, actually call the remote contact; this
 * changes #TpCallChannel:state to
 * %TP_CALL_STATE_INITIALISING.
 *
 * Since: 0.17.5
 */
void
tp_call_channel_accept_async (TpCallChannel *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CALL_CHANNEL (self));

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_call_channel_accept_async);

  tp_cli_channel_type_call_call_accept (TP_CHANNEL (self), -1,
      generic_async_cb, result, g_object_unref, G_OBJECT (self));
}

/**
 * tp_call_channel_accept_finish:
 * @self: a #TpCallChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_call_channel_accept_async().
 *
 * Since: 0.17.5
 */
gboolean
tp_call_channel_accept_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_call_channel_accept_async);
}

/**
 * tp_call_channel_hangup_async:
 * @self: a #TpCallChannel
 * @reason: a TpCallStateChangeReason
 * @detailed_reason: a more specific reason for the call hangup, if one is
 *  available, or an empty or %NULL string otherwise
 * @message: a human-readable message to be sent to the remote contact(s)
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Request that the call is ended. All contents will be removed from @self so
 * that the #TpCallChannel:contents property will be the empty list.
 *
 * Since: 0.17.5
 */
void
tp_call_channel_hangup_async (TpCallChannel *self,
    TpCallStateChangeReason reason,
    const gchar *detailed_reason,
    const gchar *message,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CALL_CHANNEL (self));

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_call_channel_hangup_async);

  tp_cli_channel_type_call_call_hangup (TP_CHANNEL (self), -1,
      reason, detailed_reason, message,
      generic_async_cb, result, g_object_unref, G_OBJECT (self));
}

/**
 * tp_call_channel_hangup_finish:
 * @self: a #TpCallChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_call_channel_hangup_async().
 *
 * Since: 0.17.5
 */
gboolean
tp_call_channel_hangup_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_call_channel_hangup_async);
}

static void
add_content_cb (TpChannel *channel,
    const gchar *object_path,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpCallChannel *self = (TpCallChannel *) channel;
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Error: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
    }
  else
    {
      g_simple_async_result_set_op_res_gpointer (result,
          g_object_ref (ensure_content (self, object_path)),
          g_object_unref);
    }

  g_simple_async_result_complete (result);
}

/**
 * tp_call_channel_add_content_async:
 * @self: a #TpCallChannel
 * @name: the suggested name of the content to add
 * @type: the media stream type of the content to be added to the call, from
 *  #TpMediaStreamType
 * @initial_direction: The initial direction of the content
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Request that a new Content of type @type is added to @self. Callers should
 * check the value of the #TpCallChannel:mutable-contents property before trying
 * to add another content as it might not be allowed.
 *
 * Since: 0.17.5
 */
void
tp_call_channel_add_content_async (TpCallChannel *self,
    const gchar *name,
    TpMediaStreamType type,
    TpMediaStreamDirection initial_direction,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CALL_CHANNEL (self));

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_call_channel_add_content_async);

  tp_cli_channel_type_call_call_add_content (TP_CHANNEL (self), -1,
      name, type, initial_direction,
      add_content_cb, result, g_object_unref, G_OBJECT (self));
}

/**
 * tp_call_channel_add_content_finish:
 * @self: a #TpCallChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_call_channel_add_content_async().
 *
 * The returned #TpCallContent is NOT guaranteed to have
 * %TP_CALL_CONTENT_FEATURE_CORE prepared.
 *
 * Returns: (transfer full): reference to the new #TpCallContent.
 * Since: 0.17.5
 */
TpCallContent *
tp_call_channel_add_content_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_call_channel_add_content_async, g_object_ref);
}

static void
send_tones_cb (GObject *source,
    GAsyncResult *res,
    gpointer user_data)
{
  GSimpleAsyncResult *result = user_data;
  guint count;
  GError *error = NULL;

  if (!tp_call_content_send_tones_finish ((TpCallContent *) source, res,
          &error))
    g_simple_async_result_take_error (result, error);

  /* Decrement the op count */
  count = GPOINTER_TO_UINT (g_simple_async_result_get_op_res_gpointer (result));
  g_simple_async_result_set_op_res_gpointer (result, GUINT_TO_POINTER (--count),
      NULL);

  if (count == 0)
    g_simple_async_result_complete (result);

  g_object_unref (result);
}

/**
 * tp_call_channel_send_tones_async:
 * @self: a #TpCallChannel
 * @tones: a string representation of one or more DTMF events.
 * @cancellable: optional #GCancellable object, %NULL to ignore
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Send @tones on every of @self's contents which have the
 * %TP_IFACE_CALL_CONTENT_INTERFACE_DTMF interface.
 *
 * For more details, see tp_call_content_send_tones_async().
 *
 * Since: 0.17.5
 */
void
tp_call_channel_send_tones_async (TpCallChannel *self,
    const gchar *tones,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  guint i;
  guint count = 0;

  g_return_if_fail (TP_IS_CALL_CHANNEL (self));
  g_return_if_fail (tp_call_channel_has_dtmf (self));

  result = g_simple_async_result_new (G_OBJECT (self), callback, user_data,
      tp_call_channel_send_tones_async);

  for (i = 0; i < self->priv->contents->len; i++)
    {
      TpCallContent *content = g_ptr_array_index (self->priv->contents, i);

      if (!tp_proxy_has_interface_by_id (content,
              TP_IFACE_QUARK_CALL_CONTENT_INTERFACE_DTMF))
        continue;

      count++;
      tp_call_content_send_tones_async (content, tones, cancellable,
          send_tones_cb, g_object_ref (result));
    }

  g_assert (count > 0);
  g_simple_async_result_set_op_res_gpointer (result,
      GUINT_TO_POINTER (count), NULL);

  g_object_unref (result);
}

/**
 * tp_call_channel_send_tones_finish:
 * @self: a #TpCallChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_call_channel_send_tones_async().
 *
 * Returns: %TRUE on success, %FALSE otherwise.
 * Since: 0.17.5
 */
gboolean
tp_call_channel_send_tones_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_call_channel_send_tones_async)
}

/**
 * tp_call_channel_request_hold_async:
 * @self: a #TpCallChannel
 * @hold: Whether to request a hold or a unhold
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Requests that the connection manager holds or unholds the call. Watch
 * #TpCallChannel:hold-state property to know when the channel goes on
 * hold or is unheld. Unholding may fail if the streaming implementation
 * can not obtain all the resources needed to restart the call.
 *
 * Since: 0.17.6
 */

void
tp_call_channel_request_hold_async (TpCallChannel *self,
    gboolean hold,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
    GSimpleAsyncResult *result;

    g_return_if_fail (TP_IS_CALL_CHANNEL (self));

    result = g_simple_async_result_new (G_OBJECT (self), callback, user_data,
        tp_call_channel_request_hold_async);

    if (tp_call_channel_has_hold (self))
      {
        tp_cli_channel_interface_hold_call_request_hold (TP_CHANNEL (self), -1,
            hold, generic_async_cb, g_object_ref (result), g_object_unref,
            G_OBJECT (self));
      }
    else
      {
        g_simple_async_result_set_error (result,
            TP_ERROR, TP_ERROR_NOT_CAPABLE,
            "Channel does NOT implement the Hold interface");
        g_simple_async_result_complete_in_idle (result);
      }

    g_object_unref (result);
}


/**
 * tp_call_channel_request_hold_finish:
 * @self: a #TpCallChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_call_channel_request_hold_async
 *
 * Since: 0.17.6
 */
gboolean
tp_call_channel_request_hold_finish (TpCallChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_call_channel_request_hold_async);
}
