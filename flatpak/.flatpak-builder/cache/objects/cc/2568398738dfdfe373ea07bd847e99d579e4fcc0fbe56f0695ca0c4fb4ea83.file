/*
 *  objects for AddDispatchOperation calls
 *
 * Copyright © 2010 Collabora Ltd. <http://www.collabora.co.uk/>
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
 * SECTION:add-dispatch-operation-context
 * @title: TpAddDispatchOperationContext
 * @short_description: context of a Approver.AddDispatchOperation() call
 *
 * Object used to represent the context of a Approver.AddDispatchOperation()
 * D-Bus call on a #TpBaseClient.
 */

/**
 * TpAddDispatchOperationContext:
 *
 * Data structure representing the context of a Approver.AddDispatchOperation()
 * call.
 *
 * Since: 0.11.5
 */

/**
 * TpAddDispatchOperationContextClass:
 *
 * The class of a #TpAddDispatchOperationContext.
 *
 * Since: 0.11.5
 */

#include "config.h"

#include "telepathy-glib/add-dispatch-operation-context-internal.h"
#include "telepathy-glib/add-dispatch-operation-context.h"

#include <telepathy-glib/channel.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/gtypes.h>

#define DEBUG_FLAG TP_DEBUG_CLIENT
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/util-internal.h"

struct _TpAddDispatchOperationContextClass {
    /*<private>*/
    GObjectClass parent_class;
};

G_DEFINE_TYPE(TpAddDispatchOperationContext,
    tp_add_dispatch_operation_context, G_TYPE_OBJECT)

enum {
    PROP_ACCOUNT = 1,
    PROP_CONNECTION,
    PROP_CHANNELS,
    PROP_DISPATCH_OPERATION,
    PROP_DBUS_CONTEXT,
    N_PROPS
};

struct _TpAddDispatchOperationContextPrivate
{
  TpAddDispatchOperationContextState state;
  GSimpleAsyncResult *result;
  DBusGMethodInvocation *dbus_context;

  /* Number of calls we are waiting they return. Once they have all returned
   * the context is considered as prepared */
  guint num_pending;
};

static void
tp_add_dispatch_operation_context_init (TpAddDispatchOperationContext *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_ADD_DISPATCH_OPERATION_CONTEXT,
      TpAddDispatchOperationContextPrivate);

  self->priv->state = TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_NONE;
}

static void
tp_add_dispatch_operation_context_dispose (GObject *object)
{
  TpAddDispatchOperationContext *self = TP_ADD_DISPATCH_OPERATION_CONTEXT (
      object);
  void (*dispose) (GObject *) =
    G_OBJECT_CLASS (tp_add_dispatch_operation_context_parent_class)->dispose;

  if (self->priv->state == TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_NONE ||
      self->priv->state == TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_DELAYED)
    {
      GError error = { TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
          "Disposing the TpAddDispatchOperationContext" };

      WARNING ("Disposing a context in the %s state",
          self->priv->state == TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_NONE ?
          "none": "delayed");

      tp_add_dispatch_operation_context_fail (self, &error);
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

  if (self->dispatch_operation != NULL)
    {
      g_object_unref (self->dispatch_operation);
      self->dispatch_operation = NULL;
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
tp_add_dispatch_operation_context_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpAddDispatchOperationContext *self = TP_ADD_DISPATCH_OPERATION_CONTEXT (
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

      case PROP_DISPATCH_OPERATION:
        g_value_set_object (value, self->dispatch_operation);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_add_dispatch_operation_context_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpAddDispatchOperationContext *self = TP_ADD_DISPATCH_OPERATION_CONTEXT (
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

      case PROP_DISPATCH_OPERATION:
        self->dispatch_operation = g_value_dup_object (value);
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
tp_add_dispatch_operation_context_constructed (GObject *object)
{
  TpAddDispatchOperationContext *self = TP_ADD_DISPATCH_OPERATION_CONTEXT (
      object);
  void (*chain_up) (GObject *) =
    ((GObjectClass *)
      tp_add_dispatch_operation_context_parent_class)->constructed;

  if (chain_up != NULL)
    chain_up (object);

  g_assert (self->account != NULL);
  g_assert (self->connection != NULL);
  g_assert (self->channels != NULL);
  g_assert (self->dispatch_operation != NULL);
  g_assert (self->priv->dbus_context != NULL);
}

static void
tp_add_dispatch_operation_context_class_init (
    TpAddDispatchOperationContextClass *cls)
{
  GObjectClass *object_class = G_OBJECT_CLASS (cls);
  GParamSpec *param_spec;

  g_type_class_add_private (cls, sizeof (TpAddDispatchOperationContextPrivate));

  object_class->get_property = tp_add_dispatch_operation_context_get_property;
  object_class->set_property = tp_add_dispatch_operation_context_set_property;
  object_class->constructed = tp_add_dispatch_operation_context_constructed;
  object_class->dispose = tp_add_dispatch_operation_context_dispose;

 /**
   * TpAddDispatchOperationContext:account:
   *
   * A #TpAccount object representing the Account of the DispatchOperation
   * that has been passed to AddDispatchOperation.
   * Read-only except during construction.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_object ("account", "TpAccount",
      "The TpAccount of the context",
      TP_TYPE_ACCOUNT,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ACCOUNT,
      param_spec);

  /**
   * TpAddDispatchOperationContext:connection:
   *
   * A #TpConnection object representing the Connection of the DispatchOperation
   * that has been passed to AddDispatchOperation.
   * Read-only except during construction.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_object ("connection", "TpConnection",
      "The TpConnection of the context",
      TP_TYPE_CONNECTION,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONNECTION,
      param_spec);

  /**
   * TpAddDispatchOperationContext:channels:
   *
   * A #GPtrArray containing #TpChannel objects representing the channels
   * that have been passed to AddDispatchOperation.
   * Read-only except during construction.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_boxed ("channels", "GPtrArray of TpChannel",
      "The TpChannels that have been passed to AddDispatchOperation",
      G_TYPE_PTR_ARRAY,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CHANNELS,
      param_spec);

  /**
   * TpAddDispatchOperationContext:dispatch-operation:
   *
   * A #TpChannelDispatchOperation object representing the
   * ChannelDispatchOperation that has been passed to AddDispatchOperation.
   * Read-only except during construction.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_object ("dispatch-operation",
     "TpChannelDispatchOperation",
     "The TpChannelDispatchOperation that has been passed to "
     "AddDispatchOperation",
     TP_TYPE_CHANNEL_DISPATCH_OPERATION,
     G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DISPATCH_OPERATION,
      param_spec);

  /**
   * TpAddDispatchOperationContext:dbus-context: (skip)
   *
   * The #DBusGMethodInvocation representing the D-Bus context of the
   * AddDispatchOperation call.
   * Can only be written during construction.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_pointer ("dbus-context", "D-Bus context",
      "The DBusGMethodInvocation associated with the AddDispatchOperation call",
      G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DBUS_CONTEXT,
      param_spec);
}

TpAddDispatchOperationContext *
_tp_add_dispatch_operation_context_new (
    TpAccount *account,
    TpConnection *connection,
    GPtrArray *channels,
    TpChannelDispatchOperation *dispatch_operation,
    DBusGMethodInvocation *dbus_context)
{
  return g_object_new (TP_TYPE_ADD_DISPATCH_OPERATION_CONTEXT,
      "account", account,
      "connection", connection,
      "channels", channels,
      "dispatch-operation", dispatch_operation,
      "dbus-context", dbus_context,
      NULL);
}

/**
 * tp_add_dispatch_operation_context_accept:
 * @self: a #TpAddDispatchOperationContext
 *
 * Called by #TpBaseClientClassAddDispatchOperationImpl when it's done so
 * the D-Bus method can return.
 *
 * Since: 0.11.5
 */
void
tp_add_dispatch_operation_context_accept (TpAddDispatchOperationContext *self)
{
  g_return_if_fail (self->priv->state ==
      TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_NONE
      || self->priv->state == TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_DELAYED);
  g_return_if_fail (self->priv->dbus_context != NULL);

  self->priv->state = TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_DONE;
  dbus_g_method_return (self->priv->dbus_context);

  self->priv->dbus_context = NULL;
}

/**
 * tp_add_dispatch_operation_context_fail:
 * @self: a #TpAddDispatchOperationContext
 * @error: the error to return from the method
 *
 * Called by #TpBaseClientClassAddDispatchOperationImpl to raise a D-Bus error.
 *
 * Since: 0.11.5
 */
void
tp_add_dispatch_operation_context_fail (TpAddDispatchOperationContext *self,
    const GError *error)
{
  g_return_if_fail (self->priv->state ==
      TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_NONE
      || self->priv->state == TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_DELAYED);
  g_return_if_fail (self->priv->dbus_context != NULL);

  self->priv->state = TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_FAILED;
  dbus_g_method_return_error (self->priv->dbus_context, error);

  self->priv->dbus_context = NULL;
}

/**
 * tp_add_dispatch_operation_context_delay:
 * @self: a #TpAddDispatchOperationContext
 *
 * Called by #TpBaseClientClassAddDispatchOperationImpl to indicate that it
 * implements the method in an async way. The caller must take a reference
 * to the #TpAddDispatchOperationContext before calling this function, and
 * is responsible for calling either
 * tp_add_dispatch_operation_context_accept() or
 * tp_add_dispatch_operation_context_fail() later.
 *
 * Since: 0.11.5
 */
void
tp_add_dispatch_operation_context_delay (TpAddDispatchOperationContext *self)
{
  g_return_if_fail (self->priv->state ==
      TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_NONE);

  self->priv->state = TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_DELAYED;
}

TpAddDispatchOperationContextState
_tp_add_dispatch_operation_context_get_state (
    TpAddDispatchOperationContext *self)
{
  return self->priv->state;
}

static gboolean
context_is_prepared (TpAddDispatchOperationContext *self)
{
  return self->priv->num_pending == 0;
}

static void
context_check_prepare (TpAddDispatchOperationContext *self)
{
  if (!context_is_prepared (self))
    return;

  /*  is prepared */
  g_simple_async_result_complete (self->priv->result);

  g_object_unref (self->priv->result);
  self->priv->result = NULL;
}

static void
cdo_prepare_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpAddDispatchOperationContext *self = user_data;
  GError *error = NULL;

  if (self->priv->result == NULL)
    goto out;

  if (!tp_proxy_prepare_finish (source, result, &error))
    {
      DEBUG ("Failed to prepare ChannelDispatchOperation: %s", error->message);

      g_error_free (error);
    }

  self->priv->num_pending--;
  context_check_prepare (self);

out:
  g_object_unref (self);
}

static void
account_prepare_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpAddDispatchOperationContext *self = user_data;
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
  TpAddDispatchOperationContext *self = user_data;
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
adoc_channel_prepare_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpAddDispatchOperationContext *self = user_data;
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
context_prepare (TpAddDispatchOperationContext *self,
    const GQuark *account_features,
    const GQuark *connection_features,
    const GQuark *channel_features)
{
  GQuark cdo_features[] = { TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE, 0 };
  guint i;

  self->priv->num_pending = 3;

  tp_proxy_prepare_async (self->account, account_features,
      account_prepare_cb, g_object_ref (self));

  tp_proxy_prepare_async (self->connection, connection_features,
      conn_prepare_cb, g_object_ref (self));

  tp_proxy_prepare_async (self->dispatch_operation, cdo_features,
      cdo_prepare_cb, g_object_ref (self));

  for (i = 0; i < self->channels->len; i++)
    {
      TpChannel *channel = g_ptr_array_index (self->channels, i);

      self->priv->num_pending++;

      tp_proxy_prepare_async (channel, channel_features,
          adoc_channel_prepare_cb, g_object_ref (self));
    }
}

void
_tp_add_dispatch_operation_context_prepare_async (
    TpAddDispatchOperationContext *self,
    const GQuark *account_features,
    const GQuark *connection_features,
    const GQuark *channel_features,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  g_return_if_fail (TP_IS_ADD_DISPATCH_OPERATION_CONTEXT (self));
  /* This is only used once, by TpBaseClient, so for simplicity, we only
   * allow one asynchronous preparation */
  g_return_if_fail (self->priv->result == NULL);

  self->priv->result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data, _tp_add_dispatch_operation_context_prepare_async);

  context_prepare (self, account_features, connection_features,
      channel_features);
}

gboolean
_tp_add_dispatch_operation_context_prepare_finish (
    TpAddDispatchOperationContext *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self,
      _tp_add_dispatch_operation_context_prepare_async);
}
