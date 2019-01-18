/*
 * simple-password-manager.c - Source for TpSimplePasswordManager
 * Copyright (C) 2010 Collabora Ltd.
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
 * SECTION:simple-password-manager
 * @title: TpSimplePasswordManager
 * @short_description: a simple X-TELEPATHY-PASSWORD channel manager
 *
 * This class makes it easy to implement the X-TELEPATHY-PASSWORD SASL
 * mechanism in a connection manger. It implements the
 * #TpChannelManager interface and pops up a ServerAuthentication
 * channel when tp_simple_password_manager_prompt_async() is called to
 * enable a channel handler to pass in the password using the
 * appropriate D-Bus methods.
 *
 * This channel manager is only useful for connection managers only
 * wanting to implement the X-TELEPATHY-PASSWORD SASL mechanism in
 * authentication channels. For connections with more SASL mechanisms,
 * the channel manager and channel itself should be reimplemented to
 * support the desired mechanisms.
 *
 * A new #TpSimplePasswordManager object should be created in the
 * #TpBaseConnectionClass->create_channel_managers implementation and
 * added to the #GPtrArray of channel managers. Then, in the
 * #TpBaseConnectionClass->start_connecting implementation, once the
 * connection status has been changed to CONNECTING, the connection
 * should check whether a password parameter was given when creating
 * the connection through RequestConnection. If a password is present,
 * the connection should go ahead and use it. If it is not present,
 * tp_simple_password_manager_prompt_async() should be called.
 *
 * Once a password is retrieved using the server authentication
 * channel, or an error is occurred, the callback that was passed to
 * tp_simple_password_manager_prompt_async() is called and the
 * connection should call tp_simple_password_manager_prompt_finish()
 * to get the result of the process. If the #GString returned from
 * said finish function is non-#NULL, the connection can then proceed
 * with that password, otherwise the connection must deal with the
 * error reached.
 *
 * Since: 0.13.8
 */

/**
 * TpSimplePasswordManager:
 *
 * A helper channel manager to manage X-TELEPATHY-PASSWORD
 * ServerAuthentication channels.
 *
 * Since: 0.13.8
 */

#include "config.h"

#include "telepathy-glib/simple-password-manager.h"

#include <telepathy-glib/channel-manager.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_SASL
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/base-password-channel.h"
#include "telepathy-glib/util-internal.h"

static void channel_manager_iface_init (gpointer, gpointer);
static void tp_simple_password_manager_close_all (TpSimplePasswordManager *self);
static void tp_simple_password_manager_constructed (GObject *object);

G_DEFINE_TYPE_WITH_CODE (TpSimplePasswordManager, tp_simple_password_manager,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE (TP_TYPE_CHANNEL_MANAGER,
        channel_manager_iface_init));

/* properties */
enum
{
  PROP_CONNECTION = 1,
  LAST_PROPERTY
};

struct _TpSimplePasswordManagerPrivate
{
  TpBaseConnection *conn;
  guint status_changed_id;

  TpBasePasswordChannel *channel;

  gboolean dispose_has_run;
};

static void
tp_simple_password_manager_init (TpSimplePasswordManager *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_SIMPLE_PASSWORD_MANAGER, TpSimplePasswordManagerPrivate);
}

static void
tp_simple_password_manager_dispose (GObject *object)
{
  TpSimplePasswordManager *self = TP_SIMPLE_PASSWORD_MANAGER (object);
  TpSimplePasswordManagerPrivate *priv = self->priv;

  if (priv->dispose_has_run)
    return;

  DEBUG ("dispose called");
  priv->dispose_has_run = TRUE;

  tp_simple_password_manager_close_all (self);

  if (priv->status_changed_id != 0)
    {
      g_signal_handler_disconnect (priv->conn,
          priv->status_changed_id);
      priv->status_changed_id = 0;
    }

  if (G_OBJECT_CLASS (tp_simple_password_manager_parent_class)->dispose)
    G_OBJECT_CLASS (tp_simple_password_manager_parent_class)->dispose (object);
}

static void
tp_simple_password_manager_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpSimplePasswordManager *self = TP_SIMPLE_PASSWORD_MANAGER (object);
  TpSimplePasswordManagerPrivate *priv = self->priv;

  switch (property_id)
    {
    case PROP_CONNECTION:
      g_value_set_object (value, priv->conn);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}

static void
tp_simple_password_manager_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpSimplePasswordManager *self = TP_SIMPLE_PASSWORD_MANAGER (object);
  TpSimplePasswordManagerPrivate *priv = self->priv;

  switch (property_id)
    {
    case PROP_CONNECTION:
      priv->conn = g_value_get_object (value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}

static void
tp_simple_password_manager_class_init (
    TpSimplePasswordManagerClass *tp_simple_password_manager_class)
{
  GObjectClass *object_class = G_OBJECT_CLASS (tp_simple_password_manager_class);
  GParamSpec *param_spec;

  g_type_class_add_private (tp_simple_password_manager_class,
      sizeof (TpSimplePasswordManagerPrivate));

  object_class->constructed = tp_simple_password_manager_constructed;
  object_class->dispose = tp_simple_password_manager_dispose;

  object_class->get_property = tp_simple_password_manager_get_property;
  object_class->set_property = tp_simple_password_manager_set_property;

  param_spec = g_param_spec_object ("connection",
      "TpBaseConnection object",
      "The connection object that owns this channel manager",
      TP_TYPE_BASE_CONNECTION,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONNECTION, param_spec);

}

static void
tp_simple_password_manager_close_all (TpSimplePasswordManager *self)
{
  TpSimplePasswordManagerPrivate *priv = self->priv;

  if (priv->channel == NULL)
    return;

  DEBUG ("closing %p", priv->channel);
  tp_base_channel_close (TP_BASE_CHANNEL (priv->channel));

  /* priv->channel gets unreffed and set to NULL in the closed
   * callback below. */
}

static void
connection_status_changed_cb (TpBaseConnection *conn,
    guint status,
    guint reason,
    TpSimplePasswordManager *self)
{
  switch (status)
    {
    case TP_CONNECTION_STATUS_DISCONNECTED:
      tp_simple_password_manager_close_all (self);
      break;
    }
}

static void
tp_simple_password_manager_constructed (GObject *object)
{
  void (*chain_up) (GObject *) =
      G_OBJECT_CLASS (tp_simple_password_manager_parent_class)->constructed;
  TpSimplePasswordManager *self = TP_SIMPLE_PASSWORD_MANAGER (object);
  TpSimplePasswordManagerPrivate *priv = self->priv;

  if (chain_up != NULL)
    chain_up (object);

  tp_g_signal_connect_object (priv->conn,
      "status-changed", G_CALLBACK (connection_status_changed_cb),
      object, 0);
}

static void
tp_simple_password_manager_foreach_channel (TpChannelManager *manager,
    TpExportableChannelFunc foreach,
    gpointer user_data)
{
  TpSimplePasswordManager *self = TP_SIMPLE_PASSWORD_MANAGER (manager);
  TpSimplePasswordManagerPrivate *priv = self->priv;

  if (priv->channel != NULL
      && !tp_base_channel_is_destroyed (TP_BASE_CHANNEL (priv->channel)))
    {
      foreach (TP_EXPORTABLE_CHANNEL (priv->channel), user_data);
    }
}

static void
channel_manager_iface_init (gpointer g_iface,
    gpointer iface_data)
{
  TpChannelManagerIface *iface = g_iface;

  iface->foreach_channel = tp_simple_password_manager_foreach_channel;

  /* these channels are not requestable */
  iface->foreach_channel_class = NULL;
  iface->request_channel = NULL;
  iface->create_channel = NULL;
  iface->ensure_channel = NULL;
}

/**
 * tp_simple_password_manager_new:
 * @connection: a #TpBaseConnection
 *
 * Creates a new simple server authentication channel manager.
 *
 * Returns: a new reference to a server authentication channel
 *  manager.
 */
TpSimplePasswordManager *
tp_simple_password_manager_new (TpBaseConnection *connection)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION (connection), NULL);

  return g_object_new (TP_TYPE_SIMPLE_PASSWORD_MANAGER,
      "connection", connection,
      NULL);
}

static void
tp_simple_password_manager_channel_closed_cb (GObject *chan,
    TpSimplePasswordManager *manager)
{
  tp_channel_manager_emit_channel_closed_for_object (manager,
      TP_EXPORTABLE_CHANNEL (chan));

  tp_clear_object (&manager->priv->channel);
}

static void
free_gstring (gpointer p)
{
  g_string_free (p, TRUE);
}

static void
tp_simple_password_manager_channel_finished_cb (
    TpBasePasswordChannel *channel,
    const GString *str,
    guint domain,
    gint code,
    const gchar *message,
    gpointer user_data)
{
  GSimpleAsyncResult *result = user_data;

  if (domain > 0)
    {
      GError *error = g_error_new (domain, code, "%s", message);
      DEBUG ("Failed: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
      g_error_free (error);
    }
  else
    {
      g_simple_async_result_set_op_res_gpointer (
          result, g_boxed_copy (G_TYPE_GSTRING, str), free_gstring);
    }

  g_simple_async_result_complete (result);
  g_object_unref (result);
}

static void
tp_simple_password_manager_prompt_common_async (
    TpSimplePasswordManager *self,
    TpBasePasswordChannel *channel,
    GSimpleAsyncResult *result)
{
  TpSimplePasswordManagerPrivate *priv = self->priv;

  g_return_if_fail (channel != NULL);
  g_return_if_fail (TP_IS_SIMPLE_PASSWORD_MANAGER (self));
  g_return_if_fail (priv->channel == NULL);

  priv->channel = g_object_ref (channel);

  tp_g_signal_connect_object (priv->channel, "closed",
      G_CALLBACK (tp_simple_password_manager_channel_closed_cb), self, 0);
  tp_g_signal_connect_object (priv->channel, "finished",
      G_CALLBACK (tp_simple_password_manager_channel_finished_cb),
      g_object_ref (result), 0);

  tp_base_channel_register ((TpBaseChannel *) priv->channel);

  tp_channel_manager_emit_new_channel (self,
      TP_EXPORTABLE_CHANNEL (priv->channel), NULL);
}

/**
 * tp_simple_password_manager_prompt_for_channel_async:
 * @self: a #TpSimplePasswordManager
 * @channel: a #TpBasePasswordChannel
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Pops up a new server authentication channel and handles the
 * X-TELEPATHY-PASSWORD mechanism to obtain a password for the
 * connection.
 *
 * When the operation is finished, @callback will be called. You must then
 * call tp_simple_password_manager_prompt_for_channel_finish() to get the
 * result of the request.
 *
 * Most of the time, tp_simple_password_manager_prompt_async() should be used
 * instead.  This function enables applications to provide custom channels
 * instead of letting the password manager handle all of the channel details
 * automatically.  This may be useful if your SASL channel needs to implement
 * additional interfaces (such as Channel.Interface.CredentialsStorage)
 *
 * Since: 0.13.15
 */
void
tp_simple_password_manager_prompt_for_channel_async (
    TpSimplePasswordManager *self,
    TpBasePasswordChannel *channel,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result = g_simple_async_result_new (
       G_OBJECT (self), callback, user_data,
       tp_simple_password_manager_prompt_for_channel_async);

  tp_simple_password_manager_prompt_common_async (self, channel, result);

  g_object_unref (result);
}

/**
 * tp_simple_password_manager_prompt_async:
 * @self: a #TpSimplePasswordManager
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Pops up a new server authentication channel and handles the
 * X-TELEPATHY-PASSWORD mechanism to obtain a password for the
 * connection.
 *
 * When the operation is finished, @callback will be called. You must then
 * call tp_simple_password_manager_prompt_finish() to get the
 * result of the request.
 *
 * Since: 0.13.8
 */
void
tp_simple_password_manager_prompt_async (
    TpSimplePasswordManager *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpSimplePasswordManagerPrivate *priv = self->priv;
  gchar *object_path = g_strdup_printf ("%s/BasePasswordChannel",
      tp_base_connection_get_object_path (priv->conn));
  TpBasePasswordChannel *channel;
  GSimpleAsyncResult *result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data, tp_simple_password_manager_prompt_async);

  channel = g_object_new (TP_TYPE_BASE_PASSWORD_CHANNEL,
      "connection", priv->conn,
      "object-path", object_path,
      "handle", 0,
      "requested", FALSE,
      "initiator-handle", tp_base_connection_get_self_handle (priv->conn),
      NULL);

  tp_simple_password_manager_prompt_common_async (self, channel, result);

  g_free (object_path);
  g_object_unref (channel);
  g_object_unref (result);
}

/**
 * tp_simple_password_manager_prompt_finish:
 * @self: a #TpSimplePasswordManager
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Retrieve the value of the request begun with
 * tp_simple_password_manager_prompt_async().
 *
 * Returns: (transfer none): a #GString with the password (or byte-blob)
 * retrieved by @manager
 *
 * Since: 0.13.8
 */
const GString *
tp_simple_password_manager_prompt_finish (
    TpSimplePasswordManager *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_simple_password_manager_prompt_async, /* do not copy */);
}

/**
 * tp_simple_password_manager_prompt_for_channel_finish:
 * @self: a #TpSimplePasswordManager
 * @result: a #GAsyncResult
 * @channel: (transfer none): an output location to retrieve the custom
 * password channel that was passed to
 * tp_simple_password_manager_prompt_for_channel_async()
 * @error: a #GError to fill
 *
 * Retrieve the value of the request begun with
 * tp_simple_password_manager_prompt_for_channel_async().
 *
 * Returns: (transfer none): a #GString with the password (or byte-blob)
 * retrieved by @manager
 *
 * Since: 0.13.15
 */
const GString *
tp_simple_password_manager_prompt_for_channel_finish (
    TpSimplePasswordManager *self,
    GAsyncResult *result,
    TpBasePasswordChannel **channel,
    GError **error)
{
  TpSimplePasswordManagerPrivate *priv = self->priv;
  GSimpleAsyncResult *simple;

  g_return_val_if_fail (TP_IS_SIMPLE_PASSWORD_MANAGER (self), NULL);
  g_return_val_if_fail (G_IS_SIMPLE_ASYNC_RESULT (result), NULL);

  simple = G_SIMPLE_ASYNC_RESULT (result);

  if (g_simple_async_result_propagate_error (simple, error))
    return NULL;

  g_return_val_if_fail (g_simple_async_result_is_valid (result,
          G_OBJECT (self), tp_simple_password_manager_prompt_for_channel_async),
      NULL);

  if (channel != NULL)
    *channel = priv->channel;

  return g_simple_async_result_get_op_res_gpointer (simple);
}
