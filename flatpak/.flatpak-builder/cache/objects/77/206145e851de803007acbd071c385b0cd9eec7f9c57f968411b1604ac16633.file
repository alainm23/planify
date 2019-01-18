/*
 * dbus-tube-channel.h - high level API for DBusTube channels
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
 * SECTION:dbus-tube-channel
 * @title: TpDBusTubeChannel
 * @short_description: proxy object for D-Bus tube channels
 *
 * #TpDBusTubeChannel provides API for working with D-Bus tube channels, which
 * allow applications to open D-Bus connections to a contact or chat room.
 *
 * To create a new outgoing D-Bus tube channel, do something like:
 *
 * |[
 * GHashTable *request_properties = tp_asv_new (
 *     TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING, TP_IFACE_CHANNEL_TYPE_DBUS_TUBE,
 *     TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, G_TYPE_UINT, TP_HANDLE_TYPE_CONTACT,
 *     TP_PROP_CHANNEL_TARGET_ID, G_TYPE_STRING, tp_contact_get_identifier (contact),
 *     TP_PROP_CHANNEL_TYPE_DBUS_TUBE_SERVICE_NAME, G_TYPE_STRING, "com.example.walrus",
 *     NULL);
 * TpAccountChannelRequest *req = tp_account_channel_request_new (account,
 *     request_properties, TP_USER_ACTION_TIME_NOT_USER_ACTION);
 * tp_account_channel_request_create_and_handle_channel_async (req, NULL, callback, NULL);
 *
 * // ...
 *
 * static void
 * callback (
 *     GObject *source,
 *     GAsyncResult *result,
 *     gpointer user_data)
 * {
 *   TpAccountChannelRequest *req = TP_ACCOUNT_CHANNEL_REQUEST (source);
 *   TpChannel *channel;
 *   GError *error = NULL;
 *
 *   channel = tp_account_channel_request_create_and_handle_channel_finish (req, result, &error);
 *   tp_dbus_tube_channel_offer_async (TP_DBUS_TUBE_CHANNEL (channel), NULL, offer_callback, NULL);
 * }
 * ]|
 *
 * You can find a fuller example in the <ulink
 * url="http://cgit.freedesktop.org/telepathy/telepathy-glib/tree/examples/client/dbus-tubes/">examples/client/dbus-tubes</ulink>
 * directory.
 *
 * Since: 0.18.0
 */

/**
 * TpDBusTubeChannel:
 *
 * Data structure representing a #TpDBusTubeChannel.
 *
 * Since: 0.18.0
 */

/**
 * TpDBusTubeChannelClass:
 *
 * The class of a #TpDBusTubeChannel.
 *
 * Since: 0.18.0
 */

#include "config.h"

#include "telepathy-glib/dbus-tube-channel.h"

#include <telepathy-glib/contact.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/gnio-util.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/util-internal.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CHANNEL
#include "telepathy-glib/automatic-client-factory-internal.h"
#include "telepathy-glib/channel-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/variant-util-internal.h"

#include <stdio.h>
#include <glib/gstdio.h>

G_DEFINE_TYPE (TpDBusTubeChannel, tp_dbus_tube_channel, TP_TYPE_CHANNEL)

struct _TpDBusTubeChannelPrivate
{
  GHashTable *parameters;
  TpTubeChannelState state;

  GSimpleAsyncResult *result;
  gchar *address;
};

enum
{
  PROP_SERVICE_NAME = 1,
  PROP_PARAMETERS,
  PROP_PARAMETERS_VARDICT
};

static void
tp_dbus_tube_channel_dispose (GObject *obj)
{
  TpDBusTubeChannel *self = (TpDBusTubeChannel *) obj;

  tp_clear_pointer (&self->priv->parameters, g_hash_table_unref);
  /* If priv->result isn't NULL, it owns a ref to self. */
  g_warn_if_fail (self->priv->result == NULL);
  tp_clear_pointer (&self->priv->address, g_free);

  G_OBJECT_CLASS (tp_dbus_tube_channel_parent_class)->dispose (obj);
}

static void
tp_dbus_tube_channel_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpDBusTubeChannel *self = (TpDBusTubeChannel *) object;

  switch (property_id)
    {
      case PROP_SERVICE_NAME:
        g_value_set_string (value,
            tp_dbus_tube_channel_get_service_name (self));
        break;

      case PROP_PARAMETERS:
        g_value_set_boxed (value, self->priv->parameters);
        break;

      case PROP_PARAMETERS_VARDICT:
        g_value_take_variant (value,
            tp_dbus_tube_channel_dup_parameters_vardict (self));
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
complete_operation (TpDBusTubeChannel *self)
{
  TpDBusTubeChannelPrivate *priv = self->priv;
  GSimpleAsyncResult *result = priv->result;

  /* This dance is to ensure that we don't accidentally manipulate priv->result
   * while calling out to user code. For instance, someone might call
   * tp_proxy_invalidate() on us, which winds up landing us in here via our
   * handler for that signal.
   */
  g_assert (priv->result != NULL);
  result = priv->result;
  priv->result = NULL;
  g_simple_async_result_complete (result);
  g_object_unref (result);
}

static void
dbus_connection_new_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpDBusTubeChannel *self = user_data;
  GDBusConnection *conn;
  GError *error = NULL;

  conn = g_dbus_connection_new_for_address_finish (result, &error);
  if (conn == NULL)
    {
      DEBUG ("Failed to create GDBusConnection: %s", error->message);
      g_simple_async_result_take_error (self->priv->result, error);
    }
  else
    {
      g_simple_async_result_set_op_res_gpointer (self->priv->result,
          conn, g_object_unref);
    }

  complete_operation (self);
}

static void
check_tube_open (TpDBusTubeChannel *self)
{
  if (self->priv->result == NULL)
    return;

  if (self->priv->address == NULL)
    return;

  if (self->priv->state != TP_TUBE_CHANNEL_STATE_OPEN)
    return;

  DEBUG ("Tube %s opened: %s", tp_proxy_get_object_path (self),
      self->priv->address);

  g_dbus_connection_new_for_address (self->priv->address,
      G_DBUS_CONNECTION_FLAGS_AUTHENTICATION_CLIENT, NULL,
      NULL, dbus_connection_new_cb, self);
}

static void
dbus_tube_invalidated_cb (
    TpProxy *proxy,
    guint domain,
    gint code,
    gchar *message,
    gpointer user_data)
{
  TpDBusTubeChannel *self = TP_DBUS_TUBE_CHANNEL (proxy);
  TpDBusTubeChannelPrivate *priv = self->priv;
  GError error = { domain, code, message };

  if (priv->result != NULL)
    {
      DEBUG ("Tube invalidated: '%s'; failing pending offer/accept method call",
          message);
      g_simple_async_result_set_from_error (priv->result, &error);
      complete_operation (self);
    }
}

static void
tube_state_changed_cb (TpChannel *channel,
    TpTubeChannelState state,
    gpointer user_data,
    GObject *weak_object)
{
  TpDBusTubeChannel *self = (TpDBusTubeChannel *) channel;

  self->priv->state = state;

  check_tube_open (self);
}

static void
tp_dbus_tube_channel_constructed (GObject *obj)
{
  TpDBusTubeChannel *self = (TpDBusTubeChannel *) obj;
  void (*chain_up) (GObject *) =
    ((GObjectClass *) tp_dbus_tube_channel_parent_class)->constructed;
  TpChannel *chan = (TpChannel *) obj;
  GHashTable *props;

  if (chain_up != NULL)
    chain_up (obj);

  if (tp_channel_get_channel_type_id (chan) !=
      TP_IFACE_QUARK_CHANNEL_TYPE_DBUS_TUBE)
    {
      GError error = { TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
          "Channel is not a D-Bus tube" };

      DEBUG ("Channel is not a D-Bus tube: %s", tp_channel_get_channel_type (
            chan));

      tp_proxy_invalidate (TP_PROXY (self), &error);
      return;
    }

  props = _tp_channel_get_immutable_properties (TP_CHANNEL (self));

  if (tp_asv_get_string (props, TP_PROP_CHANNEL_TYPE_DBUS_TUBE_SERVICE_NAME)
      == NULL)
    {
      GError error = { TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
          "Tube doesn't have DBusTube.ServiceName property" };

      DEBUG ("%s", error.message);

      tp_proxy_invalidate (TP_PROXY (self), &error);
      return;
    }

   /*  Tube.Parameters is immutable for incoming tubes. For outgoing ones,
    *  it's defined when offering the tube. */
  if (!tp_channel_get_requested (TP_CHANNEL (self)))
    {
      GHashTable *params;

      params = tp_asv_get_boxed (props,
          TP_PROP_CHANNEL_INTERFACE_TUBE_PARAMETERS,
          TP_HASH_TYPE_STRING_VARIANT_MAP);

      if (params == NULL)
        {
          DEBUG ("Incoming tube doesn't have Tube.Parameters property");

          self->priv->parameters = tp_asv_new (NULL, NULL);
        }
      else
        {
          self->priv->parameters = g_boxed_copy (
              TP_HASH_TYPE_STRING_VARIANT_MAP, params);
        }
    }

  g_signal_connect (self, "invalidated",
      G_CALLBACK (dbus_tube_invalidated_cb), NULL);
}

static void
get_state_cb (TpProxy *proxy,
    const GValue *value,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpDBusTubeChannel *self = (TpDBusTubeChannel *) proxy;
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Failed to get Tube.State property: %s", error->message);

      g_simple_async_result_set_error (result, error->domain, error->code,
          "Failed to get Tube.State property: %s", error->message);
    }
  else
    {
      self->priv->state = g_value_get_uint (value);
    }

  g_simple_async_result_complete (result);
}

static void
tp_dbus_tube_channel_prepare_core_feature_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  GError *error = NULL;
  TpChannel *chan = (TpChannel *) proxy;

  result = g_simple_async_result_new ((GObject *) proxy, callback, user_data,
      tp_dbus_tube_channel_prepare_core_feature_async);

  if (tp_cli_channel_interface_tube_connect_to_tube_channel_state_changed (chan,
        tube_state_changed_cb, proxy, NULL, NULL, &error) == NULL)
    {
      WARNING ("Failed to connect to TubeChannelStateChanged on %s: %s",
          tp_proxy_get_object_path (proxy), error->message);
      g_error_free (error);
    }

  tp_cli_dbus_properties_call_get (proxy, -1,
      TP_IFACE_CHANNEL_INTERFACE_TUBE, "State",
      get_state_cb, result, g_object_unref, G_OBJECT (proxy));
}

enum {
    FEAT_CORE,
    N_FEAT
};

static const TpProxyFeature *
tp_dbus_tube_channel_list_features (TpProxyClass *cls G_GNUC_UNUSED)
{
  static TpProxyFeature features[N_FEAT + 1] = { { 0 } };

  if (G_LIKELY (features[0].name != 0))
    return features;

  features[FEAT_CORE].name =
    TP_DBUS_TUBE_CHANNEL_FEATURE_CORE;
  features[FEAT_CORE].prepare_async =
    tp_dbus_tube_channel_prepare_core_feature_async;
  features[FEAT_CORE].core = TRUE;

  /* assert that the terminator at the end is there */
  g_assert (features[N_FEAT].name == 0);

  return features;
}

static void
tp_dbus_tube_channel_class_init (TpDBusTubeChannelClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);
  GParamSpec *param_spec;
  TpProxyClass *proxy_class = (TpProxyClass *) klass;

  gobject_class->constructed = tp_dbus_tube_channel_constructed;
  gobject_class->get_property = tp_dbus_tube_channel_get_property;
  gobject_class->dispose = tp_dbus_tube_channel_dispose;

  proxy_class->list_features = tp_dbus_tube_channel_list_features;

  /**
   * TpDBusTubeChannel:service-name:
   *
   * A string representing the service name that will be used over the tube.
   *
   * Since: 0.18.0
   */
  param_spec = g_param_spec_string ("service-name", "Service Name",
      "The service name of the dbus tube",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_SERVICE_NAME,
      param_spec);

  /**
   * TpDBusTubeChannel:parameters:
   *
   * A string to #GValue #GHashTable representing the parameters of the tube.
   *
   * Will be %NULL for outgoing tubes until the tube has been offered.
   *
   * In high-level language bindings, use
   * tp_dbus_tube_channel_dup_parameters_vardict() to get the same information
   * in a more convenient format.
   *
   * Since: 0.18.0
   */
  param_spec = g_param_spec_boxed ("parameters", "Parameters",
      "The parameters of the dbus tube",
      TP_HASH_TYPE_STRING_VARIANT_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_PARAMETERS, param_spec);

  /**
   * TpDBusTubeChannel:parameters-vardict:
   *
   * A %G_VARIANT_TYPE_VARDICT representing the parameters of the tube.
   *
   * Will be %NULL for outgoing tubes until the tube has been offered.
   *
   * Since: 0.19.10
   */
  param_spec = g_param_spec_variant ("parameters-vardict", "Parameters",
      "The parameters of the D-Bus tube",
      G_VARIANT_TYPE_VARDICT, NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_PARAMETERS_VARDICT,
      param_spec);

  g_type_class_add_private (gobject_class, sizeof (TpDBusTubeChannelPrivate));
}

static void
tp_dbus_tube_channel_init (TpDBusTubeChannel *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), TP_TYPE_DBUS_TUBE_CHANNEL,
      TpDBusTubeChannelPrivate);
}

TpDBusTubeChannel *
_tp_dbus_tube_channel_new_with_factory (
    TpSimpleClientFactory *factory,
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

  return g_object_new (TP_TYPE_DBUS_TUBE_CHANNEL,
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
 * tp_dbus_tube_channel_get_service_name:
 * @self: a #TpDBusTubeChannel
 *
 * Return the #TpDBusTubeChannel:service-name property
 *
 * Returns: (transfer none): the value of #TpDBusTubeChannel:service-name
 *
 * Since: 0.18.0
 */
const gchar *
tp_dbus_tube_channel_get_service_name (TpDBusTubeChannel *self)
{
  GHashTable *props;

  props = _tp_channel_get_immutable_properties (TP_CHANNEL (self));

  return tp_asv_get_string (props, TP_PROP_CHANNEL_TYPE_DBUS_TUBE_SERVICE_NAME);
}

/**
 * tp_dbus_tube_channel_get_parameters: (skip)
 * @self: a #TpDBusTubeChannel
 *
 * Return the #TpDBusTubeChannel:parameters property
 *
 * Returns: (transfer none) (element-type utf8 GObject.Value):
 * the value of #TpDBusTubeChannel:parameters
 *
 * Since: 0.18.0
 */
GHashTable *
tp_dbus_tube_channel_get_parameters (TpDBusTubeChannel *self)
{
  return self->priv->parameters;
}

/**
 * tp_dbus_tube_channel_dup_parameters_vardict:
 * @self: a #TpDBusTubeChannel
 *
 * Return the parameters of the dbus-tube channel in a variant of
 * type %G_VARIANT_TYPE_VARDICT whose keys are strings representing
 * parameter names and values are variants representing corresponding
 * parameter values set by the offerer when offering this channel.
 *
 * The GVariant returned is %NULL if this is an outgoing tube that has not
 * yet been offered or the parameters property has not been set.
 *
 * Use g_variant_lookup(), g_variant_lookup_value(), or tp_vardict_get_uint32()
 * and similar functions for convenient access to the values.
 *
 * Returns: (transfer full): a new reference to a #GVariant
 *
 * Since: 0.19.10
 */
GVariant *
tp_dbus_tube_channel_dup_parameters_vardict (TpDBusTubeChannel *self)
{
  g_return_val_if_fail (TP_IS_DBUS_TUBE_CHANNEL (self), NULL);

  if (self->priv->parameters == NULL)
      return NULL;

  return _tp_asv_to_vardict (self->priv->parameters);
}

/**
 * TP_DBUS_TUBE_CHANNEL_FEATURE_CORE:
 *
 * Expands to a call to a function that returns a quark representing the
 * core feature of a #TpDBusTubeChannel.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.18.0
 */
GQuark
tp_dbus_tube_channel_feature_quark_core (void)
{
  return g_quark_from_static_string ("tp-dbus-tube-channel-feature-core");
}

static void
dbus_tube_offer_cb (TpChannel *channel,
    const gchar *address,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpDBusTubeChannel *self = (TpDBusTubeChannel *) channel;

  if (error != NULL)
    {
      DEBUG ("Offer() failed: %s", error->message);

      g_simple_async_result_set_from_error (self->priv->result, error);
      complete_operation (self);
      return;
    }

  self->priv->address = g_strdup (address);

  /* We have to wait that the tube is opened before being allowed to use it */
  check_tube_open (self);
}

static void
proxy_prepare_offer_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpDBusTubeChannel *self = (TpDBusTubeChannel *) source;
  GHashTable *params = user_data;
  GError *error = NULL;

  if (!tp_proxy_prepare_finish (source, result, &error))
    {
      g_simple_async_result_take_error (self->priv->result, error);
      complete_operation (self);
      goto out;
    }

  if (self->priv->state != TP_TUBE_CHANNEL_STATE_NOT_OFFERED)
    {
      g_simple_async_result_set_error (self->priv->result, TP_ERROR,
          TP_ERROR_INVALID_ARGUMENT, "Tube is not in the NotOffered state");
      complete_operation (self);
      goto out;
    }

  g_assert (self->priv->parameters == NULL);
  if (params != NULL)
    self->priv->parameters = g_hash_table_ref (params);
  else
    self->priv->parameters = tp_asv_new (NULL, NULL);

  g_object_notify (G_OBJECT (self), "parameters");
  g_object_notify (G_OBJECT (self), "parameters-vardict");

  /* TODO: provide a way to use TP_SOCKET_ACCESS_CONTROL_LOCALHOST if you're in
   * an environment where you need to disable authentication. tp-glib can't
   * guess this for you.
   */
  tp_cli_channel_type_dbus_tube_call_offer (TP_CHANNEL (self), -1,
      self->priv->parameters, TP_SOCKET_ACCESS_CONTROL_CREDENTIALS,
      dbus_tube_offer_cb, NULL, NULL, G_OBJECT (self));

out:
  tp_clear_pointer (&params, g_hash_table_unref);
}

/**
 * tp_dbus_tube_channel_offer_async:
 * @self: an outgoing #TpDBusTubeChannel
 * @params: (allow-none) (transfer none): parameters of the tube, or %NULL
 * @callback: a callback to call when the tube has been offered
 * @user_data: data to pass to @callback
 *
 * Offer an outgoing D-Bus tube. When the tube has been offered and accepted
 * @callback will be called. You can then call
 * tp_dbus_tube_channel_offer_finish() to get the #GDBusConnection that will
 * be used to communicate through the tube.
 *
 * Since: 0.18.0
 */
void
tp_dbus_tube_channel_offer_async (TpDBusTubeChannel *self,
    GHashTable *params,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GQuark features[] = { TP_DBUS_TUBE_CHANNEL_FEATURE_CORE, 0 };

  g_return_if_fail (TP_IS_DBUS_TUBE_CHANNEL (self));
  g_return_if_fail (self->priv->result == NULL);
  g_return_if_fail (tp_channel_get_requested (TP_CHANNEL (self)));
  g_return_if_fail (self->priv->parameters == NULL);

  self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_dbus_tube_channel_offer_async);

  /* We need CORE to be prepared as we rely on State changes */
  tp_proxy_prepare_async (self, features, proxy_prepare_offer_cb,
      params != NULL ? g_hash_table_ref (params) : params);
}

/**
 * tp_dbus_tube_channel_offer_finish:
 * @self: a #TpDBusTubeChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes offering an outgoing D-Bus tube. The returned #GDBusConnection
 * is ready to be used to exchange data through the tube.
 *
 * Returns: (transfer full): a reference on a #GDBusConnection if the tube
 * has been successfully offered and opened; %NULL otherwise.
 *
 * Since: 0.18.0
 */
GDBusConnection *
tp_dbus_tube_channel_offer_finish (TpDBusTubeChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_dbus_tube_channel_offer_async, g_object_ref)
}

static void
dbus_tube_accept_cb (TpChannel *channel,
    const gchar *address,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpDBusTubeChannel *self = (TpDBusTubeChannel *) channel;

  if (error != NULL)
    {
      DEBUG ("Accept() failed: %s", error->message);

      g_simple_async_result_set_from_error (self->priv->result, error);
      complete_operation (self);
      return;
    }

  self->priv->address = g_strdup (address);

  /* We have to wait that the tube is opened before being allowed to use it */
  check_tube_open (self);
}

static void
proxy_prepare_accept_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpDBusTubeChannel *self = (TpDBusTubeChannel *) source;
  GError *error = NULL;

  if (!tp_proxy_prepare_finish (source, result, &error))
    {
      g_simple_async_result_take_error (self->priv->result, error);
      complete_operation (self);
      return;
    }

  if (self->priv->state != TP_TUBE_CHANNEL_STATE_LOCAL_PENDING)
    {
      g_simple_async_result_set_error (self->priv->result, TP_ERROR,
          TP_ERROR_INVALID_ARGUMENT, "Tube is not in the LocalPending state");
      complete_operation (self);
      return;
    }

  /* TODO: provide a way to use TP_SOCKET_ACCESS_CONTROL_LOCALHOST if you're in
   * an environment where you need to disable authentication. tp-glib can't
   * guess this for you.
   */
  tp_cli_channel_type_dbus_tube_call_accept (TP_CHANNEL (self), -1,
      TP_SOCKET_ACCESS_CONTROL_CREDENTIALS, dbus_tube_accept_cb,
      NULL, NULL, G_OBJECT (self));
}

/**
 * tp_dbus_tube_channel_accept_async:
 * @self: an incoming #TpDBusTubeChannel
 * @callback: a callback to call when the tube has been offered
 * @user_data: data to pass to @callback
 *
 * Accept an incoming D-Bus tube. When the tube has been accepted
 * @callback will be called. You can then call
 * tp_dbus_tube_channel_accept_finish() to get the #GDBusConnection that will
 * be used to communicate through the tube.
 *
 * Since: 0.18.0
 */
void
tp_dbus_tube_channel_accept_async (TpDBusTubeChannel *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GQuark features[] = { TP_DBUS_TUBE_CHANNEL_FEATURE_CORE, 0 };

  g_return_if_fail (TP_IS_DBUS_TUBE_CHANNEL (self));
  g_return_if_fail (self->priv->result == NULL);
  g_return_if_fail (!tp_channel_get_requested (TP_CHANNEL (self)));

  self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_dbus_tube_channel_accept_async);

  /* We need CORE to be prepared as we rely on State changes */
  tp_proxy_prepare_async (self, features, proxy_prepare_accept_cb, NULL);
}

/**
 * tp_dbus_tube_channel_accept_finish:
 * @self: a #TpDBusTubeChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes to accept an incoming D-Bus tube. The returned #GDBusConnection
 * is ready to be used to exchange data through the tube.
 *
 * Returns: (transfer full): a reference on a #GDBusConnection if the tube
 * has been successfully accepted and opened; %NULL otherwise.
 *
 * Since: 0.18.0
 */
GDBusConnection *
tp_dbus_tube_channel_accept_finish (TpDBusTubeChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_dbus_tube_channel_accept_async, g_object_ref)
}
