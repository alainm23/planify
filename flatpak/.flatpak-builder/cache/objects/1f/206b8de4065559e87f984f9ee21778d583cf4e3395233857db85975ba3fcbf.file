/*
 * object for HandleChannels calls context
 *
 * Copyright © 2010 Collabora Ltd.
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
 * SECTION: handle-channels-context
 * @title: TpHandleChannelsContext
 * @short_description: context of a Handler.HandleChannels() call
 *
 * Object used to represent the context of a Handler.HandleChannels()
 * D-Bus call on a #TpBaseClient.
 *
 * Since: 0.11.6
 */

/**
 * TpHandleChannelsContext:
 *
 * Data structure representing the context of a Handler.HandleChannels()
 * call.
 *
 * Since: 0.11.6
 */

/**
 * TpHandleChannelsContextClass:
 *
 * The class of a #TpHandleChannelsContext.
 *
 * Since: 0.11.6
 */

#include "config.h"

#include "telepathy-glib/handle-channels-context.h"
#include "telepathy-glib/handle-channels-context-internal.h"

#include <telepathy-glib/channel.h>
#include <telepathy-glib/channel-request.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/util-internal.h>

#define DEBUG_FLAG TP_DEBUG_CLIENT
#include "telepathy-glib/debug-internal.h"

struct _TpHandleChannelsContextClass {
    /*<private>*/
    GObjectClass parent_class;
};

G_DEFINE_TYPE(TpHandleChannelsContext,
    tp_handle_channels_context, G_TYPE_OBJECT)

enum {
    PROP_ACCOUNT = 1,
    PROP_CONNECTION,
    PROP_CHANNELS,
    PROP_REQUESTS_SATISFIED,
    PROP_USER_ACTION_TIME,
    PROP_HANDLER_INFO,
    PROP_DBUS_CONTEXT,
    N_PROPS
};

enum {
  SIGNAL_DONE,
  N_SIGNALS
};

static guint signals[N_SIGNALS] = { 0 };

struct _TpHandleChannelsContextPrivate
{
  TpHandleChannelsContextState state;
  GSimpleAsyncResult *result;
  DBusGMethodInvocation *dbus_context;

  /* Number of calls we are waiting they return. Once they have all returned
   * the context is considered as prepared */
  guint num_pending;
};

static void
tp_handle_channels_context_init (TpHandleChannelsContext *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_HANDLE_CHANNELS_CONTEXT,
      TpHandleChannelsContextPrivate);

  self->priv->state = TP_HANDLE_CHANNELS_CONTEXT_STATE_NONE;
}

static void
tp_handle_channels_context_dispose (GObject *object)
{
  TpHandleChannelsContext *self = TP_HANDLE_CHANNELS_CONTEXT (
      object);
  void (*dispose) (GObject *) =
    G_OBJECT_CLASS (tp_handle_channels_context_parent_class)->dispose;

  if (self->priv->state == TP_HANDLE_CHANNELS_CONTEXT_STATE_NONE ||
      self->priv->state == TP_HANDLE_CHANNELS_CONTEXT_STATE_DELAYED)
    {
      GError error = { TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
          "Disposing the TpHandleChannelsContext" };

      WARNING ("Disposing a context in the %s state",
          self->priv->state == TP_HANDLE_CHANNELS_CONTEXT_STATE_NONE ?
          "none": "delayed");

      tp_handle_channels_context_fail (self, &error);
    }

  if (self->account != NULL)
    {
      g_object_unref (self->account);
      self->account = NULL;
    }

  if (self->connection != NULL)
    {
      g_object_unref (self->connection);
      self->connection = NULL;
    }

  if (self->channels != NULL)
    {
      g_ptr_array_unref (self->channels);
      self->channels = NULL;
    }

  if (self->requests_satisfied != NULL)
    {
      g_ptr_array_foreach (self->requests_satisfied, (GFunc) g_object_unref,
          NULL);
      g_ptr_array_unref (self->requests_satisfied);
      self->requests_satisfied = NULL;
    }

  if (self->handler_info != NULL)
    {
      g_hash_table_unref (self->handler_info);
      self->handler_info = NULL;
    }

  if (self->priv->result != NULL)
    {
      g_object_unref (self->priv->result);
      self->priv->result = NULL;
    }

  if (dispose != NULL)
    dispose (object);
}

static void
tp_handle_channels_context_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpHandleChannelsContext *self = TP_HANDLE_CHANNELS_CONTEXT (
      object);

  switch (property_id)
    {
      case PROP_ACCOUNT:
        g_value_set_object (value, self->account);
        break;

      case PROP_CONNECTION:
        g_value_set_object (value, self->connection);
        break;

      case PROP_CHANNELS:
        g_value_set_boxed (value, self->channels);
        break;

      case PROP_REQUESTS_SATISFIED:
        g_value_set_boxed (value, self->requests_satisfied);
        break;

      case PROP_USER_ACTION_TIME:
        g_value_set_int64 (value, self->user_action_time);
        break;

      case PROP_HANDLER_INFO:
        g_value_set_boxed (value, self->handler_info);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_handle_channels_context_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpHandleChannelsContext *self = TP_HANDLE_CHANNELS_CONTEXT (
      object);

  switch (property_id)
    {
      case PROP_ACCOUNT:
        self->account = g_value_dup_object (value);
        break;

      case PROP_CONNECTION:
        self->connection = g_value_dup_object (value);
        break;

      case PROP_CHANNELS:
        self->channels = g_value_dup_boxed (value);
        break;

      case PROP_REQUESTS_SATISFIED:
        self->requests_satisfied = g_value_dup_boxed (value);
        g_ptr_array_foreach (self->requests_satisfied, (GFunc) g_object_ref,
            NULL);
        break;

      case PROP_USER_ACTION_TIME:
        self->user_action_time = g_value_get_int64 (value);
        break;

      case PROP_HANDLER_INFO:
        self->handler_info = g_value_dup_boxed (value);
        break;

      case PROP_DBUS_CONTEXT:
        self->priv->dbus_context = g_value_get_pointer (value);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_handle_channels_context_constructed (GObject *object)
{
  TpHandleChannelsContext *self = TP_HANDLE_CHANNELS_CONTEXT (
      object);
  void (*chain_up) (GObject *) =
    ((GObjectClass *)
      tp_handle_channels_context_parent_class)->constructed;

  if (chain_up != NULL)
    chain_up (object);

  g_assert (self->account != NULL);
  g_assert (self->connection != NULL);
  g_assert (self->channels != NULL);
  g_assert (self->requests_satisfied != NULL);
  g_assert (self->handler_info != NULL);
  g_assert (self->priv->dbus_context != NULL);
}

static void
tp_handle_channels_context_class_init (
    TpHandleChannelsContextClass *cls)
{
  GObjectClass *object_class = G_OBJECT_CLASS (cls);
  GParamSpec *param_spec;

  g_type_class_add_private (cls, sizeof (TpHandleChannelsContextPrivate));

  object_class->get_property = tp_handle_channels_context_get_property;
  object_class->set_property = tp_handle_channels_context_set_property;
  object_class->constructed = tp_handle_channels_context_constructed;
  object_class->dispose = tp_handle_channels_context_dispose;

 /**
   * TpHandleChannelsContext:account:
   *
   * A #TpAccount object representing the Account of the DispatchOperation
   * that has been passed to HandleChannels.
   * Read-only except during construction.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_object ("account", "TpAccount",
      "The TpAccount of the context",
      TP_TYPE_ACCOUNT,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ACCOUNT,
      param_spec);

  /**
   * TpHandleChannelsContext:connection:
   *
   * A #TpConnection object representing the Connection of the DispatchOperation
   * that has been passed to HandleChannels.
   * Read-only except during construction.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_object ("connection", "TpConnection",
      "The TpConnection of the context",
      TP_TYPE_CONNECTION,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONNECTION,
      param_spec);

  /**
   * TpHandleChannelsContext:channels:
   *
   * A #GPtrArray containing #TpChannel objects representing the channels
   * that have been passed to HandleChannels.
   * Read-only except during construction.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_boxed ("channels", "GPtrArray of TpChannel",
      "The TpChannels that have been passed to HandleChannels",
      G_TYPE_PTR_ARRAY,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CHANNELS,
      param_spec);

  /**
   * TpHandleChannelsContext:requests-satisfied:
   *
   * A #GPtrArray containing #TpChannelRequest objects representing the
   * requests that have been passed to HandleChannels.
   * Read-only except during construction.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_boxed ("requests-satisfied",
     "GPtrArray of TpChannelRequest",
     "The TpChannelRequest that has been passed to "
     "HandleChannels",
     G_TYPE_PTR_ARRAY,
     G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_REQUESTS_SATISFIED,
      param_spec);

  /**
   * TpHandleChannelsContext:user-action-time:
   *
   * The time at which user action occurred, or one of the
   * special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
   * %TP_USER_ACTION_TIME_CURRENT_TIME
   * (see #TpAccountChannelRequest:user-action-time for details)
   *
   * Read-only except during construction.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_int64 ("user-action-time",
     "User action time",
     "The User_Action_Time that has been passed to HandleChannels",
     0, G_MAXINT64, 0,
     G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_USER_ACTION_TIME,
      param_spec);

  /**
   * TpHandleChannelsContext:handler-info:
   *
   * A #GHashTable where the keys are string and values are GValue instances.
   * It represents the Handler_info hash table that has been passed to
   * HandleChannels.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_boxed ("handler-info", "Handler info",
      "The Handler that has been passed to ObserveChannels",
      TP_HASH_TYPE_STRING_VARIANT_MAP,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_HANDLER_INFO,
      param_spec);

  /**
   * TpHandleChannelsContext:dbus-context: (skip)
   *
   * The #DBusGMethodInvocation representing the D-Bus context of the
   * HandleChannels call.
   * Can only be written during construction.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_pointer ("dbus-context", "D-Bus context",
      "The DBusGMethodInvocation associated with the HandleChannels call",
      G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DBUS_CONTEXT,
      param_spec);

 /**
   * TpHandleChannelsContext::done:
   * @self: a #TpHandleChannelsContext
   *
   * Emitted when tp_handle_channels_context_accept has been called on @self.
   *
   * Since: 0.11.6
   */
  signals[SIGNAL_DONE] = g_signal_new (
      "done", G_OBJECT_CLASS_TYPE (cls),
      G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 0);

}

TpHandleChannelsContext * _tp_handle_channels_context_new (
    TpAccount *account,
    TpConnection *connection,
    GPtrArray *channels,
    GPtrArray *requests_satisfied,
    guint64 user_action_time,
    GHashTable *handler_info,
    DBusGMethodInvocation *dbus_context)
{
  return g_object_new (TP_TYPE_HANDLE_CHANNELS_CONTEXT,
      "account", account,
      "connection", connection,
      "channels", channels,
      "requests-satisfied", requests_satisfied,
      "user-action-time", user_action_time,
      "handler-info", handler_info,
      "dbus-context", dbus_context,
      NULL);
}

/**
 * tp_handle_channels_context_accept:
 * @self: a #TpHandleChannelsContext
 *
 * Called by #TpBaseClientClassAddDispatchOperationImpl when it's done so
 * the D-Bus method can return.
 *
 * The caller is responsible for closing channels with
 * tp_cli_channel_call_close() when it has finished handling them.
 *
 * Since: 0.11.6
 */
void
tp_handle_channels_context_accept (TpHandleChannelsContext *self)
{
  g_return_if_fail (self->priv->state ==
      TP_HANDLE_CHANNELS_CONTEXT_STATE_NONE
      || self->priv->state == TP_HANDLE_CHANNELS_CONTEXT_STATE_DELAYED);
  g_return_if_fail (self->priv->dbus_context != NULL);

  self->priv->state = TP_HANDLE_CHANNELS_CONTEXT_STATE_DONE;
  dbus_g_method_return (self->priv->dbus_context);

  self->priv->dbus_context = NULL;

  g_signal_emit (self, signals[SIGNAL_DONE], 0);
}

/**
 * tp_handle_channels_context_fail:
 * @self: a #TpHandleChannelsContext
 * @error: the error to return from the method
 *
 * Called by #TpBaseClientClassAddDispatchOperationImpl to raise a D-Bus error.
 *
 * Since: 0.11.6
 */
void
tp_handle_channels_context_fail (TpHandleChannelsContext *self,
    const GError *error)
{
  g_return_if_fail (self->priv->state ==
      TP_HANDLE_CHANNELS_CONTEXT_STATE_NONE
      || self->priv->state == TP_HANDLE_CHANNELS_CONTEXT_STATE_DELAYED);
  g_return_if_fail (self->priv->dbus_context != NULL);

  self->priv->state = TP_HANDLE_CHANNELS_CONTEXT_STATE_FAILED;
  dbus_g_method_return_error (self->priv->dbus_context, error);

  self->priv->dbus_context = NULL;
}

/**
 * tp_handle_channels_context_delay:
 * @self: a #TpHandleChannelsContext
 *
 * Called by #TpBaseClientClassAddDispatchOperationImpl to indicate that it
 * implements the method in an async way. The caller must take a reference
 * to the #TpHandleChannelsContext before calling this function, and
 * is responsible for calling either
 * tp_handle_channels_context_accept() or
 * tp_handle_channels_context_fail() later.
 *
 * Since: 0.11.6
 */
void
tp_handle_channels_context_delay (TpHandleChannelsContext *self)
{
  g_return_if_fail (self->priv->state ==
      TP_HANDLE_CHANNELS_CONTEXT_STATE_NONE);

  self->priv->state = TP_HANDLE_CHANNELS_CONTEXT_STATE_DELAYED;
}

TpHandleChannelsContextState
_tp_handle_channels_context_get_state (
    TpHandleChannelsContext *self)
{
  return self->priv->state;
}

static gboolean
context_is_prepared (TpHandleChannelsContext *self)
{
  return self->priv->num_pending == 0;
}

static void
context_check_prepare (TpHandleChannelsContext *self)
{
  if (!context_is_prepared (self))
    return;

  /*  is prepared */
  g_simple_async_result_complete (self->priv->result);

  g_object_unref (self->priv->result);
  self->priv->result = NULL;
}

static void
account_prepare_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpHandleChannelsContext *self = user_data;
  GError *error = NULL;

  if (self->priv->result == NULL)
    goto out;

  if (!tp_proxy_prepare_finish (source, result, &error))
    {
      DEBUG ("Failed to prepare account: %s", error->message);
      g_error_free (error);
    }

  self->priv->num_pending--;
  context_check_prepare (self);

out:
  g_object_unref (self);
}

static void
conn_prepare_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpHandleChannelsContext *self = user_data;
  GError *error = NULL;

  if (self->priv->result == NULL)
    goto out;

  if (!tp_proxy_prepare_finish (source, result, &error))
    {
      DEBUG ("Failed to prepare connection: %s", error->message);
      g_error_free (error);
    }

  self->priv->num_pending--;
  context_check_prepare (self);

out:
  g_object_unref (self);
}

static void
hcc_channel_prepare_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpHandleChannelsContext *self = user_data;
  GError *error = NULL;

  if (self->priv->result == NULL)
    goto out;

  if (!tp_proxy_prepare_finish (source, result, &error))
    {
      DEBUG ("Failed to prepare channel: %s", error->message);

      g_error_free (error);
    }

  self->priv->num_pending--;
  context_check_prepare (self);

out:
  g_object_unref (self);
}

static void
context_prepare (TpHandleChannelsContext *self,
    const GQuark *account_features,
    const GQuark *connection_features,
    const GQuark *channel_features)
{
  guint i;

  self->priv->num_pending = 2;

  tp_proxy_prepare_async (self->account, account_features,
      account_prepare_cb, g_object_ref (self));

  tp_proxy_prepare_async (self->connection, connection_features,
      conn_prepare_cb, g_object_ref (self));

  for (i = 0; i < self->channels->len; i++)
    {
      TpChannel *channel = g_ptr_array_index (self->channels, i);

      self->priv->num_pending++;

      tp_proxy_prepare_async (channel, channel_features,
          hcc_channel_prepare_cb, g_object_ref (self));
    }
}

void
_tp_handle_channels_context_prepare_async (
    TpHandleChannelsContext *self,
    const GQuark *account_features,
    const GQuark *connection_features,
    const GQuark *channel_features,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  g_return_if_fail (TP_IS_HANDLE_CHANNELS_CONTEXT (self));
  /* This is only used once, by TpBaseClient, so for simplicity, we only
   * allow one asynchronous preparation */
  g_return_if_fail (self->priv->result == NULL);

  self->priv->result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data, _tp_handle_channels_context_prepare_async);

  context_prepare (self, account_features, connection_features,
      channel_features);
}

gboolean
_tp_handle_channels_context_prepare_finish (
    TpHandleChannelsContext *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, _tp_handle_channels_context_prepare_async);
}

/**
 * tp_handle_channels_context_get_handler_info:
 * @self: a channel-handling context
 *
 * Return any extra information that accompanied this request to handle
 * channels (the Handler_Info argument from the HandleChannels D-Bus method).
 * Well-known keys for this map will be defined by the Telepathy D-Bus
 * Interface Specification; at the time of writing, none have been defined.
 *
 * The returned hash table is only valid for as long as @self is.
 *
 * Returns: (transfer none) (element-type utf8 GObject.Value): extensible
 *  extra handler information, in a form suitable for use with
 *  tp_asv_get_string() etc.
 *
 * Since: 0.11.14
 */
const GHashTable *
tp_handle_channels_context_get_handler_info (TpHandleChannelsContext *self)
{
  g_return_val_if_fail (TP_IS_HANDLE_CHANNELS_CONTEXT (self), NULL);
  return self->handler_info;
}

/**
 * tp_handle_channels_context_get_requests:
 * @self: a channel-handling context
 *
 * Return a list of the #TpChannelRequest which have been satisfied by the
 * channels associated with #self.
 *
 * Returns: (transfer full) (element-type TelepathyGLib.ChannelRequest):
 *  a newly allocated #GList of reffed #TpChannelRequest.
 *
 * Since: 0.13.14
 */
GList *
tp_handle_channels_context_get_requests (
    TpHandleChannelsContext *self)
{
  GHashTable *request_props;

  request_props = tp_asv_get_boxed (self->handler_info, "request-properties",
      TP_HASH_TYPE_OBJECT_IMMUTABLE_PROPERTIES_MAP);
  if (request_props == NULL)
    return NULL;

  return _tp_create_channel_request_list (
      tp_proxy_get_factory (self->account), request_props);
}
