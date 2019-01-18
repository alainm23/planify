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

/**
 * SECTION:call-stream
 * @title: TpCallStream
 * @short_description: proxy object for a call stream
 *
 * #TpCallStream is a sub-class of #TpProxy providing convenient API
 * to represent #TpCallChannel's stream.
 */

/**
 * TpCallStream:
 *
 * Data structure representing a #TpCallStream.
 *
 * Since: 0.17.5
 */

/**
 * TpCallStreamClass:
 *
 * The class of a #TpCallStream.
 *
 * Since: 0.17.5
 */

#include "config.h"

#include "telepathy-glib/call-stream.h"

#include <telepathy-glib/call-misc.h>
#include <telepathy-glib/call-content.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CALL
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/call-internal.h"
#include "telepathy-glib/proxy-internal.h"
#include "telepathy-glib/util-internal.h"

#include "_gen/tp-cli-call-stream-body.h"

G_DEFINE_TYPE (TpCallStream, tp_call_stream, TP_TYPE_PROXY)

struct _TpCallStreamPrivate
{
  TpConnection *connection;

  TpCallContent *content;

  /* TpContact -> TpSendingState */
  GHashTable *remote_members;
  TpSendingState local_sending_state;
  gboolean can_request_receiving;

  gboolean properties_retrieved;
};

enum
{
  PROP_CONNECTION = 1,
  PROP_LOCAL_SENDING_STATE,
  PROP_CAN_REQUEST_RECEIVING,
  PROP_CONTENT
};

enum /* signals */
{
  LOCAL_SENDING_STATE_CHANGED,
  REMOTE_MEMBERS_CHANGED,
  LAST_SIGNAL
};

static guint _signals[LAST_SIGNAL] = { 0, };

static void
update_remote_members (TpCallStream *self,
    GHashTable *updates,
    GPtrArray *removed)
{
  if (updates != NULL)
    {
      tp_g_hash_table_update (self->priv->remote_members, updates,
          g_object_ref, NULL);
    }

  if (removed != NULL)
    {
      guint i;

      for (i = 0; i < removed->len; i++)
        {
          g_hash_table_remove (self->priv->remote_members,
              g_ptr_array_index (removed, i));
        }
    }
}

static void
remote_members_changed_cb (TpCallStream *self,
    GHashTable *updates,
    GHashTable *identifiers,
    const GArray *removed,
    const GValueArray *reason,
    gpointer user_data,
    GObject *weak_object)
{
  GHashTable *updates_contacts;
  GPtrArray *removed_contacts;
  TpCallStateReason *r;

  if (!self->priv->properties_retrieved)
    return;

  DEBUG ("Remote members: %d updated, %d removed",
      g_hash_table_size (updates), removed->len);

  updates_contacts = _tp_call_members_convert_table (self->priv->connection,
      updates, identifiers);
  removed_contacts = _tp_call_members_convert_array (self->priv->connection,
      removed);
  r = _tp_call_state_reason_new (reason);

  update_remote_members (self, updates_contacts, removed_contacts);

  g_signal_emit (self, _signals[REMOTE_MEMBERS_CHANGED], 0,
      updates_contacts, removed_contacts, r);

  g_hash_table_unref (updates_contacts);
  g_ptr_array_unref (removed_contacts);
  _tp_call_state_reason_unref (r);
}

static void
local_sending_state_changed_cb (TpCallStream *self,
    guint state,
    const GValueArray *reason,
    gpointer user_data,
    GObject *weak_object)
{
  TpCallStateReason *r;

  if (!self->priv->properties_retrieved)
    return;

  self->priv->local_sending_state = state;
  g_object_notify (G_OBJECT (self), "local-sending-state");

  r = _tp_call_state_reason_new (reason);
  g_signal_emit (self, _signals[LOCAL_SENDING_STATE_CHANGED], 0,
      self->priv->local_sending_state, r);
  _tp_call_state_reason_unref (r);
}

static void
got_all_properties_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpCallStream *self = (TpCallStream *) proxy;
  const gchar * const *interfaces;
  GHashTable *remote_members;
  GHashTable *identifiers;
  GHashTable *contacts;

  if (error != NULL)
    {
      DEBUG ("Could not get the call stream properties: %s", error->message);
      _tp_proxy_set_feature_prepared (proxy,
          TP_CALL_STREAM_FEATURE_CORE, FALSE);
      return;
    }

  self->priv->properties_retrieved = TRUE;

  interfaces = tp_asv_get_boxed (properties,
      "Interfaces", G_TYPE_STRV);
  remote_members = tp_asv_get_boxed (properties,
      "RemoteMembers", TP_HASH_TYPE_CONTACT_SENDING_STATE_MAP),
  identifiers = tp_asv_get_boxed (properties,
      "RemoteMemberIdentifiers", TP_HASH_TYPE_HANDLE_IDENTIFIER_MAP);
  self->priv->local_sending_state = tp_asv_get_uint32 (properties,
      "LocalSendingState", NULL);
  self->priv->can_request_receiving = tp_asv_get_boolean (properties,
      "CanRequestReceiving", NULL);

  tp_proxy_add_interfaces ((TpProxy *) self, interfaces);

  contacts = _tp_call_members_convert_table (self->priv->connection,
      remote_members, identifiers);
  update_remote_members (self, contacts, NULL);
  g_hash_table_unref (contacts);

  _tp_proxy_set_feature_prepared (proxy, TP_CALL_STREAM_FEATURE_CORE, TRUE);
}

static void
tp_call_stream_constructed (GObject *obj)
{
  TpCallStream *self = (TpCallStream *) obj;

  ((GObjectClass *) tp_call_stream_parent_class)->constructed (obj);

  /* Connect signals for mutable properties */
  tp_cli_call_stream_connect_to_remote_members_changed (self,
      remote_members_changed_cb, NULL, NULL, G_OBJECT (self), NULL);
  tp_cli_call_stream_connect_to_local_sending_state_changed (self,
      local_sending_state_changed_cb, NULL, NULL, G_OBJECT (self), NULL);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CALL_STREAM,
      got_all_properties_cb, NULL, NULL, G_OBJECT (self));
}

static void
tp_call_stream_dispose (GObject *object)
{
  TpCallStream *self = (TpCallStream *) object;

  g_clear_object (&self->priv->content);
  g_clear_object (&self->priv->connection);
  tp_clear_pointer (&self->priv->remote_members, g_hash_table_unref);

  G_OBJECT_CLASS (tp_call_stream_parent_class)->dispose (object);
}

static void
tp_call_stream_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpCallStream *self = (TpCallStream *) object;
  TpCallStreamPrivate *priv = self->priv;

  switch (property_id)
    {
      case PROP_CONNECTION:
        g_value_set_object (value, self->priv->connection);
        break;
      case PROP_LOCAL_SENDING_STATE:
        g_value_set_uint (value, priv->local_sending_state);
        break;
      case PROP_CAN_REQUEST_RECEIVING:
        g_value_set_boolean (value, priv->can_request_receiving);
        break;
      case PROP_CONTENT:
        g_value_set_object (value, self->priv->content);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_call_stream_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpCallStream *self = (TpCallStream *) object;

  switch (property_id)
    {
      case PROP_CONNECTION:
        g_assert (self->priv->connection == NULL); /* construct-only */
        self->priv->connection = g_value_dup_object (value);
        break;
      case PROP_CONTENT:
        g_assert (self->priv->content == NULL); /* construct-only */
        self->priv->content = g_value_dup_object (value);
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
tp_call_stream_list_features (TpProxyClass *cls G_GNUC_UNUSED)
{
  static TpProxyFeature features[N_FEAT + 1] = { { 0 } };

  if (G_LIKELY (features[0].name != 0))
    return features;

  /* started from constructed */
  features[FEAT_CORE].name = TP_CALL_STREAM_FEATURE_CORE;
  features[FEAT_CORE].core = TRUE;

  /* assert that the terminator at the end is there */
  g_assert (features[N_FEAT].name == 0);

  return features;
}

static void
tp_call_stream_class_init (TpCallStreamClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);
  TpProxyClass *proxy_class = (TpProxyClass *) klass;
  GParamSpec *param_spec;

  gobject_class->constructed = tp_call_stream_constructed;
  gobject_class->get_property = tp_call_stream_get_property;
  gobject_class->set_property = tp_call_stream_set_property;
  gobject_class->dispose = tp_call_stream_dispose;

  proxy_class->list_features = tp_call_stream_list_features;
  proxy_class->interface = TP_IFACE_QUARK_CALL_STREAM;

  g_type_class_add_private (gobject_class, sizeof (TpCallStreamPrivate));
  tp_call_stream_init_known_interfaces ();

  /**
   * TpCallStream:connection:
   *
   * The #TpConnection of the call.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_object ("connection", "Connection",
      "The connection of this stream",
      TP_TYPE_CONNECTION,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_CONNECTION,
      param_spec);

  /**
   * TpCallStream:local-sending-state:
   *
   * The local user's sending state, from #TpSendingState.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("local-sending-state", "LocalSendingState",
      "Local sending state",
      0, G_MAXUINT, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_LOCAL_SENDING_STATE,
      param_spec);

  /**
   * TpCallStream:can-request-receiving:
   *
   * If %TRUE, the user can request that a remote contact starts sending on this
   * stream.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("can-request-receiving",
      "CanRequestReceiving",
      "If true, the user can request that a remote contact starts sending on"
      "this stream.",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_CAN_REQUEST_RECEIVING,
      param_spec);

  /**
   * TpCallStream:content:
   *
   * The Content that this streams belongs to
   *
   * Since: 0.17.6
   */
  param_spec = g_param_spec_object ("content",
      "Content",
      "The content that this Stream belongs to",
      TP_TYPE_CALL_CONTENT,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_CONTENT,
      param_spec);

  /**
   * TpCallStream::local-sending-state-changed:
   * @self: the #TpCallStream
   * @state: the new #TpSendingState
   * @reason: the #TpCallStateReason for the change
   *
   * The ::local-sending-state-changed signal is emitted whenever the
   * stream sending state changes.
   *
   * Since: 0.17.5
   */
  _signals[LOCAL_SENDING_STATE_CHANGED] = g_signal_new ("local-sending-state-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      2, G_TYPE_UINT, TP_TYPE_CALL_STATE_REASON);

  /**
   * TpCallStream::remote-members-changed:
   * @self: the #TpCallStream
   * @updates: (type GLib.HashTable) (element-type TelepathyGLib.Contact uint):
   *   #GHashTable mapping #TpContact to its new #TpSendingState
   * @removed: (type GLib.PtrArray) (element-type TelepathyGLib.Contact):
   *  #GPtrArray of #TpContact removed from remote contacts
   * @reason: the #TpCallStateReason for the change
   *
   * The ::remote-members-changed signal is emitted whenever the
   * stream's remote members changes.
   *
   * It is NOT guaranteed that #TpContact objects have any feature prepared.
   *
   * Since: 0.17.5
   */
  _signals[REMOTE_MEMBERS_CHANGED] = g_signal_new ("remote-members-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      3, G_TYPE_HASH_TABLE, G_TYPE_PTR_ARRAY, TP_TYPE_CALL_STATE_REASON);
}

static void
tp_call_stream_init (TpCallStream *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), TP_TYPE_CALL_STREAM,
      TpCallStreamPrivate);

  self->priv->remote_members = g_hash_table_new_full (NULL, NULL,
      g_object_unref, NULL);
}

/**
 * tp_call_stream_init_known_interfaces:
 *
 * Ensure that the known interfaces for #TpCallStream have been set up.
 * This is done automatically when necessary, but for correct
 * overriding of library interfaces by local extensions, you should
 * call this function before calling
 * tp_proxy_or_subclass_hook_on_interface_add() with first argument
 * %TP_TYPE_CALL_STREAM.
 *
 * Since: 0.17.5
 */
void
tp_call_stream_init_known_interfaces (void)
{
  static gsize once = 0;

  if (g_once_init_enter (&once))
    {
      GType tp_type = TP_TYPE_CALL_STREAM;

      tp_proxy_init_known_interfaces ();
      tp_proxy_or_subclass_hook_on_interface_add (tp_type,
          tp_cli_call_stream_add_signals);
      tp_proxy_subclass_add_error_mapping (tp_type,
          TP_ERROR_PREFIX, TP_ERROR, TP_TYPE_ERROR);

      g_once_init_leave (&once, 1);
    }
}

/**
 * TP_CALL_STREAM_FEATURE_CORE:
 *
 * Expands to a call to a function that returns a quark for the "core"
 * feature on a #TpCallStream.
 *
 * One can ask for a feature to be prepared using the tp_proxy_prepare_async()
 * function, and waiting for it to trigger the callback.
 */
GQuark
tp_call_stream_get_feature_quark_core (void)
{
  return g_quark_from_static_string ("tp-call-stream-feature-core");
}

/**
 * tp_call_stream_get_local_sending_state:
 * @self: a #TpCallStream
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallStream:local-sending-state
 * Since: 0.17.5
 */
TpSendingState
tp_call_stream_get_local_sending_state (TpCallStream *self)
{
  g_return_val_if_fail (TP_IS_CALL_STREAM (self), TP_SENDING_STATE_NONE);

  return self->priv->local_sending_state;
}

/**
 * tp_call_stream_can_request_receiving:
 * @self: a #TpCallStream
 *
 * <!-- -->
 *
 * Returns: the value of #TpCallStream:can-request-receiving
 * Since: 0.17.5
 */
gboolean
tp_call_stream_can_request_receiving (TpCallStream *self)
{
  g_return_val_if_fail (TP_IS_CALL_STREAM (self), FALSE);

  return self->priv->can_request_receiving;
}

/**
 * tp_call_stream_get_remote_members:
 * @self: a #TpCallStream
 *
 * Get the remote contacts to who this stream is connected, mapped to their
 * sending state.
 *
 * It is NOT guaranteed that #TpContact objects have any feature prepared.
 *
 * Returns: (transfer none) (type GLib.HashTable) (element-type TelepathyGLib.Contact uint):
 *  #GHashTable mapping #TpContact to its new #TpSendingState
 * Since: 0.17.5
 */
GHashTable *
tp_call_stream_get_remote_members (TpCallStream *self)
{
  g_return_val_if_fail (TP_IS_CALL_STREAM (self), NULL);

  return self->priv->remote_members;
}

static void
generic_async_cb (TpCallStream *self,
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
 * tp_call_stream_set_sending_async:
 * @self: a #TpCallStream
 * @send: the requested sending state
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Set the stream to start or stop sending media from the local user to other
 * contacts.
 *
 * If @send is %TRUE, #TpCallStream:local-sending-state should change to
 * %TP_SENDING_STATE_SENDING, if it isn't already.
 * If @send is %FALSE, #TpCallStream:local-sending-state should change to
 * %TP_SENDING_STATE_NONE, if it isn't already.
 *
 * Since: 0.17.5
 */
void
tp_call_stream_set_sending_async (TpCallStream *self,
    gboolean send,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CALL_STREAM (self));

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_call_stream_set_sending_async);

  tp_cli_call_stream_call_set_sending (self, -1, send,
      generic_async_cb, result, g_object_unref, G_OBJECT (self));
}

/**
 * tp_call_stream_set_sending_finish:
 * @self: a #TpCallStream
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_call_stream_set_sending_async().
 *
 * Since: 0.17.5
 */
gboolean
tp_call_stream_set_sending_finish (TpCallStream *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_call_stream_set_sending_async);
}

/**
 * tp_call_stream_request_receiving_async:
 * @self: a #TpCallStream
 * @contact: contact from which sending is requested
 * @receive: the requested receiving state
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Request that a remote contact stops or starts sending on this stream.
 *
 * The #TpCallStream:can-request-receiving property defines whether the protocol
 * allows the local user to request the other side start sending on this stream.
 *
 * If @receive is %TRUE, request that the given contact starts to send media.
 * If @receive is %FALSE, request that the given contact stops sending media.
 *
 * Since: 0.17.5
 */
void
tp_call_stream_request_receiving_async (TpCallStream *self,
    TpContact *contact,
    gboolean receive,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CALL_STREAM (self));
  g_return_if_fail (TP_IS_CONTACT (contact));
  g_return_if_fail (tp_contact_get_connection (contact) ==
      self->priv->connection);

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_call_stream_set_sending_async);

  tp_cli_call_stream_call_request_receiving (self, -1,
      tp_contact_get_handle (contact), receive,
      generic_async_cb, result, g_object_unref, G_OBJECT (self));
}

/**
 * tp_call_stream_request_receiving_finish:
 * @self: a #TpCallStream
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_call_stream_request_receiving_async().
 *
 * Since: 0.17.5
 */
gboolean
tp_call_stream_request_receiving_finish (TpCallStream *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_call_stream_request_receiving_async);
}
