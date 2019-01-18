/*
 * base-call-stream.c - Source for TpBaseCallStream
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

/**
 * SECTION:base-call-stream
 * @title: TpBaseCallStream
 * @short_description: base class for #TpSvcCallStream implementations
 * @see_also: #TpSvcCallStream, #TpBaseCallChannel and #TpBaseCallContent
 *
 * This base class makes it easier to write #TpSvcCallStream
 * implementations by implementing its properties, and some of its methods.
 *
 * Subclasses should fill in #TpBaseCallStreamClass.get_interfaces,
 * #TpBaseCallStreamClass.request_receiving and
 * #TpBaseCallStreamClass.set_sending virtual function.
 *
 * Since: 0.17.5
 */

/**
 * TpBaseCallStream:
 *
 * A base class for call stream implementations
 *
 * Since: 0.17.5
 */

/**
 * TpBaseCallStreamClass:
 * @get_interfaces: extra interfaces provided by this stream (this SHOULD NOT
 *  include %TP_IFACE_CALL_STREAM itself). Implementation must first chainup on
 *  parent class implementation then add extra interfaces into the #GPtrArray.
 * @request_receiving: optional (see #TpBaseCallStream:can-request-receiving);
 *  virtual method called when user requested receiving from the given remote
 *  contact.
 * @set_sending: mandatory; virtual method called when user requested to
 *  start/stop sending to remote contacts.
 *
 * The class structure for #TpBaseCallStream
 *
 * Since: 0.17.5
 */

/**
 * TpBaseCallStreamGetInterfacesFunc:
 * @self: a #TpBaseCallStream
 *
 * Signature of an implementation of #TpBaseCallStreamClass.get_interfaces.
 *
 * Returns: a #GPtrArray containing static strings.
 * Since: 0.17.5
 */

/**
 * TpBaseCallStreamSetSendingFunc:
 * @self: a #TpBaseCallStream
 * @sending: whether or not user would like to be sending
 * @error: a #GError to fill
 *
 * Signature of an implementation of #TpBaseCallStreamClass.set_sending.
 *
 * Returns: %TRUE on success, %FALSE otherwise.
 * Since: 0.17.5
 */

/**
 * TpBaseCallStreamRequestReceivingFunc:
 * @self: a #TpBaseCallStream
 * @contact: the contact from who user wants to start or stop receiving
 * @receive: wheter or not user would like to be receiving
 * @error: a #GError to fill
 *
 * Signature of an implementation of #TpBaseCallStreamClass.request_receiving.
 *
 * Returns: %TRUE on success, %FALSE otherwise.
 * Since: 0.17.5
 */

#include "config.h"

#include "base-call-stream.h"

#define DEBUG_FLAG TP_DEBUG_CALL

#include "telepathy-glib/base-call-channel.h"
#include "telepathy-glib/base-call-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/dbus.h"
#include "telepathy-glib/gtypes.h"
#include "telepathy-glib/interfaces.h"
#include "telepathy-glib/svc-call.h"
#include "telepathy-glib/svc-generic.h"
#include "telepathy-glib/util.h"

static void call_stream_iface_init (gpointer g_iface, gpointer iface_data);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE (TpBaseCallStream, tp_base_call_stream,
    G_TYPE_OBJECT,

    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_DBUS_PROPERTIES,
        tp_dbus_properties_mixin_iface_init)
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CALL_STREAM, call_stream_iface_init)
    )

enum
{
  PROP_OBJECT_PATH = 1,
  PROP_CONNECTION,
  PROP_CONTENT,
  PROP_CHANNEL,

  /* Call interface properties */
  PROP_INTERFACES,
  PROP_REMOTE_MEMBERS,
  PROP_REMOTE_MEMBER_IDENTIFIERS,
  PROP_LOCAL_SENDING_STATE,
  PROP_CAN_REQUEST_RECEIVING,
};

struct _TpBaseCallStreamPrivate
{
  gchar *object_path;
  TpBaseConnection *conn;

  /* TpHandle -> TpSendingState */
  GHashTable *remote_members;

  TpSendingState local_sending_state;

  /* Borrowed */
  TpBaseCallChannel *channel;
  TpBaseCallContent *content;
};

static void
tp_base_call_stream_init (TpBaseCallStream *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_BASE_CALL_STREAM, TpBaseCallStreamPrivate);

  self->priv->remote_members = g_hash_table_new (g_direct_hash, g_direct_equal);
}

static void
tp_base_call_stream_constructed (GObject *obj)
{
  TpBaseCallStream *self = TP_BASE_CALL_STREAM (obj);
  TpDBusDaemon *bus = tp_base_connection_get_dbus_daemon (
      (TpBaseConnection *) self->priv->conn);

  if (G_OBJECT_CLASS (tp_base_call_stream_parent_class)->constructed != NULL)
    G_OBJECT_CLASS (tp_base_call_stream_parent_class)->constructed (obj);

  /* register object on the bus */
  DEBUG ("Registering %s", self->priv->object_path);
  tp_dbus_daemon_register_object (bus, self->priv->object_path, obj);
}

static GPtrArray *
tp_base_call_stream_get_interfaces (TpBaseCallStream *self)
{
  return g_ptr_array_new ();
}

static void
tp_base_call_stream_dispose (GObject *object)
{
  TpBaseCallStream *self = TP_BASE_CALL_STREAM (object);
  TpDBusDaemon *bus = tp_base_connection_get_dbus_daemon (
      (TpBaseConnection *) self->priv->conn);

  tp_dbus_daemon_unregister_object (bus, G_OBJECT (self));

  tp_clear_object (&self->priv->conn);

  if (G_OBJECT_CLASS (tp_base_call_stream_parent_class)->dispose != NULL)
    G_OBJECT_CLASS (tp_base_call_stream_parent_class)->dispose (object);
}

static void
tp_base_call_stream_finalize (GObject *object)
{
  TpBaseCallStream *self = TP_BASE_CALL_STREAM (object);

  /* free any data held directly by the object here */
  g_free (self->priv->object_path);
  g_hash_table_unref (self->priv->remote_members);

  if (G_OBJECT_CLASS (tp_base_call_stream_parent_class)->finalize != NULL)
    G_OBJECT_CLASS (tp_base_call_stream_parent_class)->finalize (object);
}

static void
tp_base_call_stream_get_property (
    GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpBaseCallStream *self = TP_BASE_CALL_STREAM (object);
  TpBaseCallStreamClass *klass = TP_BASE_CALL_STREAM_GET_CLASS (self);

  switch (property_id)
    {
      case PROP_CONNECTION:
        g_value_set_object (value, self->priv->conn);
        break;
      case PROP_OBJECT_PATH:
        g_value_set_string (value, self->priv->object_path);
        break;
      case PROP_CONTENT:
        g_value_set_object (value, self->priv->content);
        break;
      case PROP_CHANNEL:
        g_value_set_object (value, self->priv->channel);
        break;
      case PROP_REMOTE_MEMBERS:
        g_value_set_boxed (value, self->priv->remote_members);
        break;
      case PROP_REMOTE_MEMBER_IDENTIFIERS:
        {
          GHashTable *identifiers;

          identifiers = _tp_base_call_dup_member_identifiers (self->priv->conn,
              self->priv->remote_members);
          g_value_set_boxed (value, identifiers);

          g_hash_table_unref (identifiers);
          break;
        }
      case PROP_LOCAL_SENDING_STATE:
        g_value_set_uint (value, self->priv->local_sending_state);
        break;
      case PROP_CAN_REQUEST_RECEIVING:
        {
          g_value_set_boolean (value, klass->request_receiving != NULL);
          break;
        }
      case PROP_INTERFACES:
        {
          GPtrArray *interfaces = klass->get_interfaces (self);

          g_ptr_array_add (interfaces, NULL);
          g_value_set_boxed (value, interfaces->pdata);
          g_ptr_array_unref (interfaces);
          break;
        }
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_base_call_stream_set_property (
    GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpBaseCallStream *self = TP_BASE_CALL_STREAM (object);

  switch (property_id)
    {
      case PROP_CONNECTION:
        self->priv->conn = g_value_dup_object (value);
        g_assert (self->priv->conn != NULL);
        break;
      case PROP_CONTENT:
        {
          TpBaseCallContent *content = g_value_get_object (value);
          if (content)
            _tp_base_call_stream_set_content (self, content);
        }
        break;
      case PROP_OBJECT_PATH:
        g_free (self->priv->object_path);
        self->priv->object_path = g_value_dup_string (value);
        break;
      case PROP_LOCAL_SENDING_STATE:
        self->priv->local_sending_state = g_value_get_uint (value);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
tp_base_call_stream_class_init (TpBaseCallStreamClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GParamSpec *param_spec;
  static TpDBusPropertiesMixinPropImpl stream_props[] = {
    { "Interfaces", "interfaces", NULL },
    { "RemoteMembers", "remote-members", NULL },
    { "RemoteMemberIdentifiers", "remote-member-identifiers", NULL },
    { "LocalSendingState", "local-sending-state", NULL },
    { "CanRequestReceiving", "can-request-receiving", NULL },
    { NULL }
  };
  static TpDBusPropertiesMixinIfaceImpl prop_interfaces[] = {
      { TP_IFACE_CALL_STREAM,
        tp_dbus_properties_mixin_getter_gobject_properties,
        NULL,
        stream_props,
      },
      { NULL }
  };

  g_type_class_add_private (klass, sizeof (TpBaseCallStreamPrivate));

  object_class->constructed = tp_base_call_stream_constructed;
  object_class->dispose = tp_base_call_stream_dispose;
  object_class->finalize = tp_base_call_stream_finalize;
  object_class->set_property = tp_base_call_stream_set_property;
  object_class->get_property = tp_base_call_stream_get_property;

  klass->get_interfaces = tp_base_call_stream_get_interfaces;

  /**
   * TpBaseCallStream:connection:
   *
   * #TpBaseConnection object that owns this call stream.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_object ("connection", "TpBaseConnection object",
      "Tp connection object that owns this call stream",
      TP_TYPE_BASE_CONNECTION,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONNECTION, param_spec);

  /**
   * TpBaseCallStream:object-path:
   *
   * The D-Bus object path used for this object on the bus.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_string ("object-path", "D-Bus object path",
      "The D-Bus object path used for this object on the bus.",
      NULL,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_OBJECT_PATH, param_spec);

  /**
   * TpBaseCallStream:content:
   *
   * #TpBaseCallContent object that owns this call stream.
   *
   * Since: 0.17.6
   */
  param_spec = g_param_spec_object ("content", "TpBaseCallContent object",
      "Tp Content object that owns this call stream",
      TP_TYPE_BASE_CALL_CONTENT,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONTENT, param_spec);

  /**
   * TpBaseCallStream:channel:
   *
   * #TpBaseChannel object that owns this call stream.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_object ("channel", "TpBaseCallChannel object",
      "Tp base call channel object that owns this call stream",
      TP_TYPE_BASE_CALL_CHANNEL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CHANNEL, param_spec);

  /**
   * TpBaseCallStream:interfaces:
   *
   * Additional interfaces implemented by this stream.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("interfaces", "Interfaces",
      "Stream interfaces",
      G_TYPE_STRV,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INTERFACES,
      param_spec);

  /**
   * TpBaseCallStream:remote-members:
   *
   * #GHashTable mapping contact #TpHandle to their #TpSendingState.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("remote-members", "Remote members",
      "Remote member map",
      TP_HASH_TYPE_CONTACT_SENDING_STATE_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_REMOTE_MEMBERS,
      param_spec);

  /**
   * TpBaseCallStream:remote-member-identifiers:
   *
   * #GHashTable mapping contact #TpHandle to their identifies.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boxed ("remote-member-identifiers",
      "RemoteMemberIdentifiers", "The remote members identifiers",
      TP_HASH_TYPE_HANDLE_IDENTIFIER_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_REMOTE_MEMBER_IDENTIFIERS,
      param_spec);

  /**
   * TpBaseCallStream:local-sending-state:
   *
   * The local #TpSendingState.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_uint ("local-sending-state", "LocalSendingState",
      "Local sending state",
      TP_SENDING_STATE_NONE, TP_NUM_SENDING_STATES, TP_SENDING_STATE_NONE,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_LOCAL_SENDING_STATE,
      param_spec);

  /**
   * TpBaseCallStream:can-request-receiving:
   *
   * Whether or not user can request receiving from remote contact using the
   * RequestSending DBus method call. The value is determined by whether or not
   * #TpBaseCallStreamClass.request_receiving is implemented.
   *
   * Since: 0.17.5
   */
  param_spec = g_param_spec_boolean ("can-request-receiving",
      "CanRequestReceiving",
      "If true, the user can request that a remote contact starts sending on"
      "this stream.",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CAN_REQUEST_RECEIVING,
      param_spec);

  klass->dbus_props_class.interfaces = prop_interfaces;
  tp_dbus_properties_mixin_class_init (object_class,
      G_STRUCT_OFFSET (TpBaseCallStreamClass, dbus_props_class));
}

/**
 * tp_base_call_stream_get_connection:
 * @self: a #TpBaseCallStream
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallStream:connection
 * Since: 0.17.5
 */
TpBaseConnection *
tp_base_call_stream_get_connection (TpBaseCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_STREAM (self), NULL);

  return self->priv->conn;
}

/**
 * tp_base_call_stream_get_object_path:
 * @self: a #TpBaseCallStream
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallStream:object-path
 * Since: 0.17.5
 */
const gchar *
tp_base_call_stream_get_object_path (TpBaseCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_STREAM (self), NULL);

  return self->priv->object_path;
}

/**
 * tp_base_call_stream_get_local_sending_state:
 * @self: a #TpBaseCallStream
 *
 * <!-- -->
 *
 * Returns: the value of #TpBaseCallStream:local-sending-state
 * Since: 0.17.5
 */
TpSendingState
tp_base_call_stream_get_local_sending_state (TpBaseCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_STREAM (self), TP_SENDING_STATE_NONE);

  return self->priv->local_sending_state;
}

/**
 * tp_base_call_stream_update_local_sending_state:
 * @self: a #TpBaseCallStream
 * @new_state: the new local #TpSendingState
 * @actor_handle: the contact responsible for the change, or 0 if no contact was
 *  responsible.
 * @reason: the #TpCallStateChangeReason of the change
 * @dbus_reason: a specific reason for the change, which may be a D-Bus error in
 *  the Telepathy namespace, a D-Bus error in any other namespace (for
 *  implementation-specific errors), or the empty string to indicate that the
 *  state change was not an error.
 * @message: an optional debug message, to expediate debugging the potentially
 *  many processes involved in a call.
 *
 * Update the local sending state, emitting LocalSendingStateChanged
 * DBus signal if needed.
 *
 * Returns: %TRUE if state was updated, %FALSE if it was already set to
 *  @new_state.
 * Since: 0.17.5
 */
gboolean
tp_base_call_stream_update_local_sending_state (TpBaseCallStream *self,
    TpSendingState new_state,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message)
{
  GValueArray *reason_array;

  g_return_val_if_fail (TP_IS_BASE_CALL_STREAM (self), FALSE);

  if (new_state == TP_SENDING_STATE_SENDING &&
      self->priv->channel != NULL &&
      !tp_base_call_channel_is_accepted (self->priv->channel) &&
      !tp_base_channel_is_requested (TP_BASE_CHANNEL (self->priv->channel)))
    new_state = TP_SENDING_STATE_PENDING_SEND;

  if (self->priv->local_sending_state == new_state)
    return FALSE;

  DEBUG ("Updating local sending state: %d => %d for stream %s",
      self->priv->local_sending_state, new_state, self->priv->object_path);

  self->priv->local_sending_state = new_state;
  g_object_notify (G_OBJECT (self), "local-sending-state");

  reason_array = _tp_base_call_state_reason_new (actor_handle, reason,
      dbus_reason, message);

  tp_svc_call_stream_emit_local_sending_state_changed (
      TP_SVC_CALL_STREAM (self), new_state, reason_array);

  tp_value_array_free (reason_array);

  return TRUE;
}

/**
 * tp_base_call_stream_get_remote_sending_state:
 * @self: a #TpBaseCallStream
 * @contact: the #TpHandle of a member contact
 *
 * <!-- -->
 *
 * Returns: the #TpSendingState of @contact.
 * Since: 0.17.5
 */
TpSendingState
tp_base_call_stream_get_remote_sending_state (TpBaseCallStream *self,
  TpHandle contact)
{
  gpointer state_p;

  g_return_val_if_fail (TP_IS_BASE_CALL_STREAM (self), TP_SENDING_STATE_NONE);

  state_p = g_hash_table_lookup (self->priv->remote_members,
      GUINT_TO_POINTER (contact));

  return GPOINTER_TO_UINT (state_p);
}

/**
 * tp_base_call_stream_update_remote_sending_state:
 * @self: a #TpBaseCallStream
 * @contact: the #TpHandle to update or add to members
 * @new_state: the new sending state of @contact
 * @actor_handle: the contact responsible for the change, or 0 if no contact was
 *  responsible.
 * @reason: the #TpCallStateChangeReason of the change
 * @dbus_reason: a specific reason for the change, which may be a D-Bus error in
 *  the Telepathy namespace, a D-Bus error in any other namespace (for
 *  implementation-specific errors), or the empty string to indicate that the
 *  state change was not an error.
 * @message: an optional debug message, to expediate debugging the potentially
 *  many processes involved in a call.
 *
 * If @contact is not member, add it. Otherwise update its sending state. Emits
 * RemoteMemberChanged DBus signal if needed.
 *
 * Returns: %TRUE if state was updated, %FALSE if it was already set to
 *  @new_state.
 * Since: 0.17.5
 */
gboolean
tp_base_call_stream_update_remote_sending_state (TpBaseCallStream *self,
    TpHandle contact,
    TpSendingState new_state,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message)
{
  gpointer old_state_p = NULL;
  TpSendingState old_state;
  gboolean exists;
  GHashTable *updates;
  GHashTable *identifiers;
  GArray *removed_empty;
  GValueArray *reason_array;

  g_return_val_if_fail (TP_IS_BASE_CALL_STREAM (self), FALSE);

  if (new_state == TP_SENDING_STATE_SENDING &&
      self->priv->channel != NULL &&
      tp_base_channel_is_requested (TP_BASE_CHANNEL (self->priv->channel)) &&
      !tp_base_call_channel_is_accepted (self->priv->channel))
    new_state = TP_SENDING_STATE_PENDING_SEND;

  exists = g_hash_table_lookup_extended (self->priv->remote_members,
      GUINT_TO_POINTER (contact), NULL, &old_state_p);
  old_state = GPOINTER_TO_UINT (old_state_p);

  if (exists && old_state == new_state)
    return FALSE;

  DEBUG ("Updating remote member %d state: %d => %d for stream %s",
      contact, old_state, new_state, self->priv->object_path);

  g_hash_table_insert (self->priv->remote_members,
      GUINT_TO_POINTER (contact),
      GUINT_TO_POINTER (new_state));
  g_object_notify (G_OBJECT (self), "remote-members");

  updates = g_hash_table_new (g_direct_hash, g_direct_equal);
  g_hash_table_insert (updates,
      GUINT_TO_POINTER (contact),
      GUINT_TO_POINTER (new_state));
  identifiers = _tp_base_call_dup_member_identifiers (self->priv->conn, updates);
  removed_empty = g_array_new (FALSE, FALSE, sizeof (TpHandle));
  reason_array = _tp_base_call_state_reason_new (actor_handle, reason,
      dbus_reason, message);

  tp_svc_call_stream_emit_remote_members_changed (self, updates, identifiers,
      removed_empty, reason_array);

  g_array_unref (removed_empty);
  tp_value_array_free (reason_array);
  g_hash_table_unref (updates);
  g_hash_table_unref (identifiers);

  return TRUE;
}

/**
 * tp_base_call_stream_remove_member:
 * @self: a #TpBaseCallStream
 * @contact: the #TpHandle to remove from members
 * @actor_handle: the contact responsible for the change, or 0 if no contact was
 *  responsible.
 * @reason: the #TpCallStateChangeReason of the change
 * @dbus_reason: a specific reason for the change, which may be a D-Bus error in
 *  the Telepathy namespace, a D-Bus error in any other namespace (for
 *  implementation-specific errors), or the empty string to indicate that the
 *  state change was not an error.
 * @message: an optional debug message, to expediate debugging the potentially
 *  many processes involved in a call.
 *
 * Remove @contact from stream members, emitting RemoteMembersChanged DBus
 * signal if needed. Do nothing if @contact is not member.
 *
 * Returns: %TRUE if @contact was removed, %FALSE if it was not member.
 * Since: 0.17.5
 */
gboolean
tp_base_call_stream_remove_member (TpBaseCallStream *self,
    TpHandle contact,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message)
{
  GHashTable *empty_table;
  GArray *removed_array;
  GValueArray *reason_array;

  g_return_val_if_fail (TP_IS_BASE_CALL_STREAM (self), FALSE);

  if (!g_hash_table_remove (self->priv->remote_members,
          GUINT_TO_POINTER (contact)))
    return FALSE;
  g_object_notify (G_OBJECT (self), "remote-members");

  empty_table = g_hash_table_new (g_direct_hash, g_direct_equal);
  removed_array = g_array_sized_new (FALSE, TRUE, sizeof (TpHandle), 1);
  g_array_append_val (removed_array, contact);
  reason_array = _tp_base_call_state_reason_new (actor_handle, reason,
      dbus_reason, message);

  tp_svc_call_stream_emit_remote_members_changed (self, empty_table,
      empty_table, removed_array, reason_array);

  tp_value_array_free (reason_array);
  g_hash_table_unref (empty_table);
  g_array_unref (removed_array);

  return TRUE;
}

static void
tp_base_call_stream_set_sending_dbus (TpSvcCallStream *iface,
    gboolean sending,
    DBusGMethodInvocation *context)
{
  TpBaseCallStream *self = TP_BASE_CALL_STREAM (iface);
  GError *error = NULL;

  if (_tp_base_call_stream_set_sending (TP_BASE_CALL_STREAM (iface), sending,
          tp_base_channel_get_self_handle ((TpBaseChannel *) self->priv->channel),
          TP_CALL_STATE_CHANGE_REASON_USER_REQUESTED, "",
          "User changed the sending state", &error))
    {
      tp_svc_call_stream_return_from_set_sending (context);
    }
  else
    {
      dbus_g_method_return_error (context, error);
    }

  g_clear_error (&error);
}

static void
tp_base_call_stream_request_receiving (TpSvcCallStream *iface,
    TpHandle contact,
    gboolean receiving,
    DBusGMethodInvocation *context)
{
  TpBaseCallStream *self = TP_BASE_CALL_STREAM (iface);
  TpBaseCallStreamClass *klass = TP_BASE_CALL_STREAM_GET_CLASS (self);
  GError *error = NULL;
  TpSendingState remote_sending_state;
  gboolean can_request_receiving;

  g_object_get (self, "can-request-receiving", &can_request_receiving, NULL);
  if (!can_request_receiving)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_NOT_CAPABLE,
          "The contact does not support requesting to receive");
      goto error;
    }

  if (!g_hash_table_lookup_extended (self->priv->remote_members,
          GUINT_TO_POINTER (contact), NULL, (gpointer *) &remote_sending_state))
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Contact %u is not member of this stream", contact);
      goto error;
    }

  if (klass->request_receiving == NULL)
    {
      g_set_error_literal (&error, TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
          "This CM does not implement request_receiving");
      goto error;
    }


  /* Determine if there is a state change for our receiving side
   * aka remote sending
   */
  switch (remote_sending_state)
    {
      case TP_SENDING_STATE_NONE:
      case TP_SENDING_STATE_PENDING_STOP_SENDING:
        if (!receiving)
          goto out;
        break;
      case TP_SENDING_STATE_SENDING:
      case TP_SENDING_STATE_PENDING_SEND:
        if (receiving)
          goto out;
        break;
      default:
        g_assert_not_reached ();
    }

  if (!klass->request_receiving (self, contact, receiving, &error))
    goto error;

out:
  tp_svc_call_stream_return_from_request_receiving (context);
  return;

error:
  dbus_g_method_return_error (context, error);
  g_clear_error (&error);
}

static void
call_stream_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcCallStreamClass *klass =
    (TpSvcCallStreamClass *) g_iface;

#define IMPLEMENT(x, suffix) tp_svc_call_stream_implement_##x (\
    klass, tp_base_call_stream_##x##suffix)
  IMPLEMENT(set_sending, _dbus);
  IMPLEMENT(request_receiving,);
#undef IMPLEMENT
}

/* These functions are used only internally */

void
_tp_base_call_stream_set_content (TpBaseCallStream *self,
    TpBaseCallContent *content)
{
  g_return_if_fail (TP_IS_BASE_CALL_STREAM (self));
  g_return_if_fail (TP_IS_BASE_CALL_CONTENT (content));
  g_return_if_fail (self->priv->content == NULL ||
      self->priv->content == content);

  self->priv->content = content;
  self->priv->channel = _tp_base_call_content_get_channel (content);

  g_object_notify (G_OBJECT (self), "content");
  g_object_notify (G_OBJECT (self), "channel");
}

TpBaseCallContent *
_tp_base_call_stream_get_content (TpBaseCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_STREAM (self), NULL);
  g_return_val_if_fail (self->priv->content != NULL, NULL);

  return self->priv->content;
}

TpBaseCallChannel *
_tp_base_call_stream_get_channel (TpBaseCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_STREAM (self), NULL);

  return self->priv->channel;
}

gboolean
_tp_base_call_stream_set_sending (TpBaseCallStream *self,
    gboolean send,
    TpHandle actor_handle,
    TpCallStateChangeReason reason,
    const gchar *dbus_reason,
    const gchar *message,
    GError **error)
{
  TpBaseCallStreamClass *klass = TP_BASE_CALL_STREAM_GET_CLASS (self);

  /* Determine if there is a state change for our sending side */
  switch (self->priv->local_sending_state)
    {
      case TP_SENDING_STATE_NONE:
      case TP_SENDING_STATE_PENDING_SEND:
        if (!send)
          goto out;
        break;
      case TP_SENDING_STATE_SENDING:
      case TP_SENDING_STATE_PENDING_STOP_SENDING:
        if (send)
          goto out;
        break;
      default:
        g_assert_not_reached ();
    }

  if (klass->set_sending == NULL)
    {
      g_set_error_literal (error, TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
        "This CM does not implement SetSending");
      return FALSE;
    }

  if (!klass->set_sending (self, send, error))
    return FALSE;

out:
  tp_base_call_stream_update_local_sending_state (self,
      send ? TP_SENDING_STATE_SENDING : TP_SENDING_STATE_NONE,
      actor_handle, reason, dbus_reason, message);

  return TRUE;
}

GHashTable *
_tp_base_call_stream_get_remote_members (TpBaseCallStream *self)
{
  g_return_val_if_fail (TP_IS_BASE_CALL_STREAM (self), NULL);

  return self->priv->remote_members;
}
