/*
 * channel-request.c - proxy for a request to the Telepathy channel dispatcher
 *
 * Copyright (C) 2009 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2009 Nokia Corporation
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

#include "config.h"

#include "telepathy-glib/channel-request.h"

#include <telepathy-glib/account-manager.h>
#include <telepathy-glib/automatic-proxy-factory.h>
#include <telepathy-glib/channel.h>
#include <telepathy-glib/connection.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_DISPATCHER
#include "telepathy-glib/dbus-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/deprecated-internal.h"
#include "telepathy-glib/proxy-internal.h"
#include "telepathy-glib/simple-client-factory-internal.h"
#include "telepathy-glib/variant-util-internal.h"
#include "telepathy-glib/_gen/tp-cli-channel-request-body.h"

/**
 * SECTION:channel-request
 * @title: TpChannelRequest
 * @short_description: proxy object for a request to the Telepathy channel
 *  dispatcher
 * @see_also: #TpChannelDispatcher
 *
 * Requesting a channel from the channel dispatcher can take some time, so an
 * object is created in the channel dispatcher to represent each request.
 * Objects of the #TpChannelRequest class provide access to one of those
 * objects.
 */

/**
 * TpChannelRequest:
 *
 * Requesting a channel from the channel dispatcher can take some time, so an
 * object is created in the channel dispatcher to represent each request. This
 * proxy represents one of those objects.
 *
 * Any client can call tp_cli_channel_request_call_cancel() at any time to
 * attempt to cancel the request.
 *
 * On success, the #TpChannelRequest::succeeded signal will be emitted.
 * Immediately after that, the #TpProxy::invalidated signal will be emitted,
 * with the domain %TP_DBUS_ERRORS and the error code
 * %TP_DBUS_ERROR_OBJECT_REMOVED (this is not an error condition, it merely
 * indicates that the channel request no longer exists).
 *
 * On failure, the #TpProxy::invalidated signal will be emitted with some
 * other suitable error, usually from the %TP_ERROR domain.
 *
 * If the channel dispatcher crashes or exits, the #TpProxy::invalidated
 * signal will be emitted with the domain %TP_DBUS_ERRORS and the error code
 * %TP_DBUS_ERROR_NAME_OWNER_LOST.
 *
 * Creating a #TpChannelRequest directly is deprecated: it
 * should only be created via a #TpAccountChannelRequest
 * or a #TpBaseClient.
 *
 * Since 0.16, #TpChannelRequest always has a non-%NULL #TpProxy:factory,
 * and its #TpProxy:factory will be propagated to the #TpAccount,
 * #TpConnection and #TpChannel.
 *
 * Since: 0.7.32
 */

/**
 * TpChannelRequestClass:
 *
 * The class of a #TpChannelRequest.
 */

enum {
  SIGNAL_SUCCEEDED,
  SIGNAL_SUCCEEDED_WITH_CHANNEL,
  N_SIGNALS
};

enum {
  PROP_CHANNEL_FACTORY = 1,
  PROP_IMMUTABLE_PROPERTIES,
  PROP_IMMUTABLE_PROPERTIES_VARDICT,
  PROP_ACCOUNT,
  PROP_USER_ACTION_TIME,
  PROP_PREFERRED_HANDLER,
  PROP_HINTS,
  PROP_HINTS_VARDICT
};

static guint signals[N_SIGNALS] = { 0 };

struct _TpChannelRequestPrivate {
    GHashTable *immutable_properties;

    TpClientChannelFactory *channel_factory;
    gboolean succeeded_with_chan_fired;
    TpAccount *account;
};

G_DEFINE_TYPE (TpChannelRequest, tp_channel_request, TP_TYPE_PROXY)

static void
tp_channel_request_init (TpChannelRequest *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_CHANNEL_REQUEST,
      TpChannelRequestPrivate);
}

static void
tp_channel_request_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpChannelRequest *self = TP_CHANNEL_REQUEST (object);

  switch (property_id)
    {
      case PROP_CHANNEL_FACTORY:
        tp_clear_object (&self->priv->channel_factory);
        self->priv->channel_factory = g_value_dup_object (value);
        break;

      case PROP_IMMUTABLE_PROPERTIES:
        g_assert (self->priv->immutable_properties == NULL);
        self->priv->immutable_properties = g_value_dup_boxed (value);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_channel_request_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpChannelRequest *self = TP_CHANNEL_REQUEST (object);

  switch (property_id)
    {
      case PROP_CHANNEL_FACTORY:
        g_value_set_object (value, self->priv->channel_factory);
        break;

      case PROP_IMMUTABLE_PROPERTIES:
        g_value_set_boxed (value, self->priv->immutable_properties);
        break;

      case PROP_IMMUTABLE_PROPERTIES_VARDICT:
        g_value_take_variant (value,
            tp_channel_request_dup_immutable_properties (self));
        break;

      case PROP_ACCOUNT:
        g_value_set_object (value, tp_channel_request_get_account (self));
        break;

      case PROP_USER_ACTION_TIME:
        g_value_set_int64 (value,
            tp_channel_request_get_user_action_time (self));
        break;

      case PROP_PREFERRED_HANDLER:
        g_value_set_string (value,
            tp_channel_request_get_preferred_handler (self));
        break;

      case PROP_HINTS:
        g_value_set_boxed (value, tp_channel_request_get_hints (self));
        break;

      case PROP_HINTS_VARDICT:
        g_value_take_variant (value, tp_channel_request_dup_hints (self));
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_channel_request_failed_cb (TpChannelRequest *self,
    const gchar *error_name,
    const gchar *message,
    gpointer unused G_GNUC_UNUSED,
    GObject *object G_GNUC_UNUSED)
{
  GError *error = NULL;

  tp_proxy_dbus_error_to_gerror (self, error_name, message, &error);
  tp_proxy_invalidate ((TpProxy *) self, error);
  g_error_free (error);
}

static void
tp_channel_request_succeeded_cb (TpChannelRequest *self,
    gpointer unused G_GNUC_UNUSED,
    GObject *object G_GNUC_UNUSED)
{
  GError e = { TP_DBUS_ERRORS, TP_DBUS_ERROR_OBJECT_REMOVED,
      "ChannelRequest succeeded and was removed" };

  if (!self->priv->succeeded_with_chan_fired)
    {
      DEBUG ("MC is too old and didn't fired SucceededWithChannel");

      g_signal_emit (self, signals[SIGNAL_SUCCEEDED_WITH_CHANNEL], 0,
          NULL, NULL);

      self->priv->succeeded_with_chan_fired = TRUE;
    }

  /* Fire the old legacy signal as well */
  g_signal_emit (self, signals[SIGNAL_SUCCEEDED], 0);

  tp_proxy_invalidate ((TpProxy *) self, &e);
}

static void
tp_channel_request_succeeded_with_channel_cb (TpChannelRequest *self,
    const gchar *conn_path,
    GHashTable *conn_props,
    const gchar *chan_path,
    GHashTable *chan_props,
    gpointer unused G_GNUC_UNUSED,
    GObject *object G_GNUC_UNUSED)
{
  TpConnection *connection;
  TpChannel *channel;
  GError *error = NULL;

  connection = tp_simple_client_factory_ensure_connection (
      tp_proxy_get_factory (self), conn_path, NULL, &error);
  if (connection == NULL)
    {
      DEBUG ("Failed to create TpConnection: %s", error->message);
      g_error_free (error);
      return;
    }

  if (self->priv->channel_factory != NULL)
    channel = tp_client_channel_factory_create_channel (
        self->priv->channel_factory, connection, chan_path, chan_props, &error);
  else
    channel = tp_simple_client_factory_ensure_channel (tp_proxy_get_factory (self),
        connection, chan_path, chan_props, &error);
  if (channel == NULL)
    {
      DEBUG ("Failed to create TpChannel: %s", error->message);
      g_error_free (error);
      g_object_unref (connection);
      return;
    }

  g_signal_emit (self, signals[SIGNAL_SUCCEEDED_WITH_CHANNEL], 0,
      connection, channel);

  self->priv->succeeded_with_chan_fired = TRUE;

  g_object_unref (connection);
  g_object_unref (channel);
}

static void
tp_channel_request_constructed (GObject *object)
{
  TpChannelRequest *self = TP_CHANNEL_REQUEST (object);
  void (*chain_up) (GObject *) =
    ((GObjectClass *) tp_channel_request_parent_class)->constructed;
  GError *error = NULL;
  TpProxySignalConnection *sc;

  if (chain_up != NULL)
    chain_up (object);

  g_return_if_fail (tp_proxy_get_dbus_daemon (self) != NULL);

  _tp_proxy_ensure_factory (self, NULL);

  sc = tp_cli_channel_request_connect_to_failed (self,
      tp_channel_request_failed_cb, NULL, NULL, NULL, &error);

  if (sc == NULL)
    {
      CRITICAL ("Couldn't connect to Failed: %s", error->message);
      g_error_free (error);
      g_assert_not_reached ();
      return;
    }

  sc = tp_cli_channel_request_connect_to_succeeded (self,
      tp_channel_request_succeeded_cb, NULL, NULL, NULL, &error);

  if (sc == NULL)
    {
      CRITICAL ("Couldn't connect to Succeeded: %s", error->message);
      g_error_free (error);
      g_assert_not_reached ();
      return;
    }

  sc = tp_cli_channel_request_connect_to_succeeded_with_channel (self,
      tp_channel_request_succeeded_with_channel_cb, NULL, NULL, NULL, &error);

  if (sc == NULL)
    {
      DEBUG ("Couldn't connect to SucceededWithChannel: %s", error->message);
      g_error_free (error);
      return;
    }
}

static void
tp_channel_request_dispose (GObject *object)
{
  TpChannelRequest *self = TP_CHANNEL_REQUEST (object);
  void (*dispose) (GObject *) =
    G_OBJECT_CLASS (tp_channel_request_parent_class)->dispose;

  tp_clear_pointer (&self->priv->immutable_properties, g_hash_table_unref);

  tp_clear_object (&self->priv->channel_factory);
  tp_clear_object (&self->priv->account);

  if (dispose != NULL)
    dispose (object);
}

static void
tp_channel_request_class_init (TpChannelRequestClass *klass)
{
  TpProxyClass *proxy_class = (TpProxyClass *) klass;
  GObjectClass *object_class = (GObjectClass *) klass;
  GParamSpec *param_spec;

  g_type_class_add_private (klass, sizeof (TpChannelRequestPrivate));

  object_class->set_property = tp_channel_request_set_property;
  object_class->get_property = tp_channel_request_get_property;
  object_class->constructed = tp_channel_request_constructed;
  object_class->dispose = tp_channel_request_dispose;

  proxy_class->interface = TP_IFACE_QUARK_CHANNEL_REQUEST;
  tp_channel_request_init_known_interfaces ();
  proxy_class->must_have_unique_name = TRUE;

  /**
   * TpChannelRequest:channel-factory:
   *
   * The object implementing the #TpClientChannelFactoryInterface interface
   * that will be used to create channel proxies when the
   * #TpChannelRequest::succeeded-with-channel signal is fired.
   * This property can be changed using
   * tp_channel_request_set_channel_factory().
   *
   * If no channel factory is specified then #TpAutomaticProxyFactory is used.
   *
   * Since: 0.13.14
   * Deprecated: since 0.15.5. Use #TpProxy:factory instead.
   */
  param_spec = g_param_spec_object ("channel-factory", "Channel factory",
      "Object implementing TpClientChannelFactoryInterface",
      G_TYPE_OBJECT,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CHANNEL_FACTORY,
      param_spec);

  /**
   * TpChannelRequest:immutable-properties:
   *
   * The immutable D-Bus properties of this channel request, represented by a
   * #GHashTable where the keys are D-Bus interface name + "." + property
   * name, and the values are #GValue instances.
   *
   * Note that this property is set only if the immutable properties have been
   * set during the construction of the #TpChannelRequest.
   *
   * Read-only except during construction.
   *
   * Since: 0.13.14
   */
  param_spec = g_param_spec_boxed ("immutable-properties",
      "Immutable D-Bus properties",
      "A map D-Bus interface + \".\" + property name => GValue",
      TP_HASH_TYPE_QUALIFIED_PROPERTY_VALUE_MAP,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_IMMUTABLE_PROPERTIES,
      param_spec);

  /**
   * TpChannelRequest:immutable-properties-vardict:
   *
   * The immutable D-Bus properties of this channel request, represented by a
   * %G_VARIANT_TYPE_VARDICT where the keys are
   * D-Bus interface name + "." + property name.
   *
   * Note that this property is set only if the immutable properties have been
   * set during the construction of the #TpChannelRequest.
   *
   * Read-only except during construction.
   *
   * Since: 0.19.10
   */
  param_spec = g_param_spec_variant ("immutable-properties-vardict",
      "Immutable D-Bus properties",
      "A map D-Bus interface + \".\" + property name => variant",
      G_VARIANT_TYPE_VARDICT, NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
      PROP_IMMUTABLE_PROPERTIES_VARDICT, param_spec);

  /**
   * TpChannelRequest:account:
   *
   * The #TpAccount on which this request was made, not guaranteed
   * to be prepared.
   *
   * Read-only.
   *
   * Since: 0.15.3
   */
  param_spec = g_param_spec_object ("account", "Account", "Account",
      TP_TYPE_ACCOUNT,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ACCOUNT, param_spec);

  /**
   * TpChannelRequest:user-action-time:
   *
   * The time at which user action occurred, or
   * #TP_USER_ACTION_TIME_NOT_USER_ACTION if this channel request is
   * for some reason not involving user action.
   *
   * Read-only.
   *
   * Since: 0.15.3
   */
  param_spec = g_param_spec_int64 ("user-action-time", "UserActionTime",
      "UserActionTime",
      0, G_MAXINT64, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_USER_ACTION_TIME,
      param_spec);

  /**
   * TpChannelRequest:preferred-handler:
   *
   * Either the well-known bus name (starting with #TP_CLIENT_BUS_NAME_BASE)
   * of the preferred handler for this channel request,
   * or %NULL to indicate that any handler would be acceptable.
   *
   * Read-only.
   *
   * Since: 0.15.3
   */
  param_spec = g_param_spec_string ("preferred-handler", "PreferredHandler",
      "PreferredHandler",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PREFERRED_HANDLER,
      param_spec);

  /**
   * TpChannelRequest:hints:
   *
   * A #TP_HASH_TYPE_STRING_VARIANT_MAP of metadata provided by
   * the channel requester; or %NULL if #TpChannelRequest:immutable-properties
   * is not defined or if no hints has been defined.
   *
   * Read-only.
   *
   * Since: 0.13.14
   */
  param_spec = g_param_spec_boxed ("hints", "Hints", "Hints",
      TP_HASH_TYPE_STRING_VARIANT_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_HINTS, param_spec);

  /**
   * TpChannelRequest:hints-vardict:
   *
   * A %G_VARIANT_TYPE_VARDICT of metadata provided by
   * the channel requester; or %NULL if #TpChannelRequest:immutable-properties
   * is not defined or if no hints have been defined.
   *
   * Read-only.
   *
   * Since: 0.19.10
   */
  param_spec = g_param_spec_variant ("hints-vardict", "Hints", "Hints",
      G_VARIANT_TYPE_VARDICT, NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_HINTS_VARDICT,
      param_spec);

  /**
   * TpChannelRequest::succeeded:
   * @self: the channel request proxy
   *
   * Emitted when the channel request succeeds.
   *
   * Deprecated: since 0.13.14. Use
   * #TpChannelRequest::succeeded-with-channel, which provides the resulting
   * channel, instead.
   */
  signals[SIGNAL_SUCCEEDED] = g_signal_new ("succeeded",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 0);

  /**
   * TpChannelRequest::succeeded-with-channel:
   * @self: the channel request proxy
   * @connection: the #TpConnection of @channel, or %NULL
   * @channel: the #TpChannel created, or %NULL
   *
   * Emitted when the channel request succeeds.
   *
   * With telepathy-mission-control version 5.7.1 and earlier, @connection and
   * @channel will be %NULL. When using newer versions, they will be correctly
   * set to the newly-created channel, and the connection which owns it.
   *
   * The #TpChannel is created using #TpChannelRequest:channel-factory or
   * #TpProxy:factory but the features of the factory are NOT prepared.
   * It's up to the user to prepare the features returned by
   * tp_simple_client_factory_dup_channel_features() himself.
   *
   * Since: 0.13.14
   */
  signals[SIGNAL_SUCCEEDED_WITH_CHANNEL] = g_signal_new (
      "succeeded-with-channel",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 2, TP_TYPE_CONNECTION, TP_TYPE_CHANNEL);
}

/**
 * tp_channel_request_init_known_interfaces:
 *
 * Ensure that the known interfaces for TpChannelRequest have been set up.
 * This is done automatically when necessary, but for correct
 * overriding of library interfaces by local extensions, you should
 * call this function before calling
 * tp_proxy_or_subclass_hook_on_interface_add() with first argument
 * %TP_TYPE_CHANNEL_REQUEST.
 *
 * Since: 0.7.32
 */
void
tp_channel_request_init_known_interfaces (void)
{
  static gsize once = 0;

  if (g_once_init_enter (&once))
    {
      GType tp_type = TP_TYPE_CHANNEL_REQUEST;

      tp_proxy_init_known_interfaces ();
      tp_proxy_or_subclass_hook_on_interface_add (tp_type,
          tp_cli_channel_request_add_signals);
      tp_proxy_subclass_add_error_mapping (tp_type,
          TP_ERROR_PREFIX, TP_ERROR, TP_TYPE_ERROR);

      g_once_init_leave (&once, 1);
    }
}

/**
 * tp_channel_request_new:
 * @bus_daemon: Proxy for the D-Bus daemon
 * @object_path: The non-NULL object path of this channel request
 * @immutable_properties: As many as are known of the immutable D-Bus
 *  properties of this channel request, or %NULL if none are known
 * @error: Used to raise an error if %NULL is returned
 *
 * Convenience function to create a new channel request proxy.
 *
 * If the channel request was newly created, the client making the request
 * is responsible for calling tp_cli_channel_request_call_proceed() when it
 * is ready for the channel request to proceed.
 *
 * Returns: a new reference to an channel request proxy, or %NULL if
 *    @object_path is not syntactically valid or the channel dispatcher is
 *    not running
 * Deprecated: Since 0.19.9. New code should get #TpChannelRequest objects
 *  from a #TpBaseClient
 */
TpChannelRequest *
tp_channel_request_new (TpDBusDaemon *bus_daemon,
    const gchar *object_path,
    GHashTable *immutable_properties,
    GError **error)
{
  return _tp_channel_request_new_with_factory (NULL, bus_daemon, object_path,
      immutable_properties, error);
}

TpChannelRequest *
_tp_channel_request_new_with_factory (TpSimpleClientFactory *factory,
    TpDBusDaemon *bus_daemon,
    const gchar *object_path,
    GHashTable *immutable_properties,
    GError **error)
{
  TpChannelRequest *self;
  gchar *unique_name;

  g_return_val_if_fail (bus_daemon != NULL, NULL);
  g_return_val_if_fail (object_path != NULL, NULL);
  g_return_val_if_fail (error == NULL || *error == NULL, NULL);

  if (!tp_dbus_check_valid_object_path (object_path, error))
    return NULL;

  if (!_tp_dbus_daemon_get_name_owner (bus_daemon, -1,
      TP_CHANNEL_DISPATCHER_BUS_NAME, &unique_name, error))
    return NULL;

  self = TP_CHANNEL_REQUEST (g_object_new (TP_TYPE_CHANNEL_REQUEST,
        "dbus-daemon", bus_daemon,
        "dbus-connection", ((TpProxy *) bus_daemon)->dbus_connection,
        "bus-name", unique_name,
        "object-path", object_path,
        "immutable-properties", immutable_properties,
        "factory", factory,
        NULL));

  g_free (unique_name);

  return self;
}

/**
 * tp_channel_request_set_channel_factory:
 * @self: a #TpChannelRequest
 * @factory: an object implementing the #TpClientChannelFactoryInterface
 * interface
 *
 * Change the value of the #TpChannelRequest:channel-factory property.
 *
 * Since: 0.13.14
 * Deprecated: since 0.15.5. Use #TpProxy:factory instead.
 */
void
tp_channel_request_set_channel_factory (TpChannelRequest *self,
    TpClientChannelFactory *factory)
{
  _tp_channel_request_set_channel_factory (self, factory);
}

void
_tp_channel_request_set_channel_factory (TpChannelRequest *self,
    TpClientChannelFactory *factory)
{
  tp_clear_object (&self->priv->channel_factory);

  if (factory != NULL)
    self->priv->channel_factory = g_object_ref (factory);
  g_object_notify (G_OBJECT (self), "channel-factory");
}

/**
 * tp_channel_request_get_immutable_properties:
 * @self: a #TpChannelRequest
 *
 * Return the #TpChannelRequest:immutable-properties construct-only property
 *
 * Returns: (transfer none): the value of
 * #TpChannelRequest:immutable-properties
 *
 * Since: 0.13.14
 */
const GHashTable *
tp_channel_request_get_immutable_properties (TpChannelRequest *self)
{
  g_return_val_if_fail (TP_IS_CHANNEL_REQUEST (self), NULL);

  return self->priv->immutable_properties;
}

/**
 * tp_channel_request_dup_immutable_properties:
 * @self: a #TpChannelRequest
 *
 * Return the #TpChannelRequest:immutable-properties-vardict property.
 *
 * Returns: (transfer full): the value of
 * #TpChannelRequest:immutable-properties-vardict
 *
 * Since: 0.19.10
 */
GVariant *
tp_channel_request_dup_immutable_properties (TpChannelRequest *self)
{
  g_return_val_if_fail (TP_IS_CHANNEL_REQUEST (self), NULL);

  if (self->priv->immutable_properties == NULL)
    return NULL;

  return _tp_asv_to_vardict (self->priv->immutable_properties);
}

void
_tp_channel_request_ensure_immutable_properties (TpChannelRequest *self,
    GHashTable *immutable_properties)
{
  if (self->priv->immutable_properties == NULL && immutable_properties != NULL)
    {
      self->priv->immutable_properties = g_hash_table_ref (immutable_properties);
      g_object_notify ((GObject *) self, "immutable-properties");
    }
}

/**
 * tp_channel_request_get_account:
 * @self: a #tpchannelrequest
 *
 * Return the value of the #TpChannelRequest:account construct-only property
 *
 * returns: (transfer none): the value of #TpChannelRequest:account
 *
 * since: 0.15.3
 */
TpAccount *
tp_channel_request_get_account (TpChannelRequest *self)
{
  g_return_val_if_fail (TP_IS_CHANNEL_REQUEST (self), NULL);

  /* lazily initialize self->priv->account */
  if (self->priv->account == NULL)
    {
      const gchar *path;

      if (self->priv->immutable_properties == NULL)
        return NULL;

      path = tp_asv_get_object_path (self->priv->immutable_properties,
          TP_PROP_CHANNEL_REQUEST_ACCOUNT);
      if (path == NULL)
        return NULL;

      self->priv->account = tp_simple_client_factory_ensure_account (
          tp_proxy_get_factory (self), path, NULL, NULL);
    }

  return self->priv->account;
}

/**
 * tp_channel_request_get_user_action_time:
 * @self: a #tpchannelrequest
 *
 * return the #TpChannelRequest:user-action-time construct-only property
 *
 * returns: the value of #TpChannelRequest:user-action-time
 *
 * since: 0.15.3
 */
gint64
tp_channel_request_get_user_action_time (TpChannelRequest *self)
{
  g_return_val_if_fail (TP_IS_CHANNEL_REQUEST (self), 0);

  if (self->priv->immutable_properties == NULL)
    return 0;

  return tp_asv_get_int64 (self->priv->immutable_properties,
      TP_PROP_CHANNEL_REQUEST_USER_ACTION_TIME, NULL);
}

/**
 * tp_channel_request_get_preferred_handler:
 * @self: a #tpchannelrequest
 *
 * return the #TpChannelRequest:preferred-handler construct-only property
 *
 * returns: the value of #TpChannelRequest:preferred-handler
 *
 * since: 0.15.3
 */
const gchar *
tp_channel_request_get_preferred_handler (TpChannelRequest *self)
{
  g_return_val_if_fail (TP_IS_CHANNEL_REQUEST (self), NULL);

  if (self->priv->immutable_properties == NULL)
    return NULL;

  return tp_asv_get_string (self->priv->immutable_properties,
      TP_PROP_CHANNEL_REQUEST_PREFERRED_HANDLER);
}

/**
 * tp_channel_request_get_hints:
 * @self: a #TpChannelRequest
 *
 * Return the #TpChannelRequest:hints property
 *
 * Returns: (transfer none): the value of
 * #TpChannelRequest:hints
 *
 * Since: 0.13.14
 */
const GHashTable *
tp_channel_request_get_hints (TpChannelRequest *self)
{
  g_return_val_if_fail (TP_IS_CHANNEL_REQUEST (self), NULL);

  if (self->priv->immutable_properties == NULL)
    return NULL;

  return tp_asv_get_boxed (self->priv->immutable_properties,
      TP_PROP_CHANNEL_REQUEST_HINTS, TP_HASH_TYPE_STRING_VARIANT_MAP);
}

/**
 * tp_channel_request_dup_hints:
 * @self: a #TpChannelRequest
 *
 * Return the #TpChannelRequest:hints-vardict property
 *
 * Returns: (transfer full): the value of #TpChannelRequest:hints-vardict
 *
 * Since: 0.19.10
 */
GVariant *
tp_channel_request_dup_hints (TpChannelRequest *self)
{
  const GHashTable *hints;

  g_return_val_if_fail (TP_IS_CHANNEL_REQUEST (self), NULL);

  hints = tp_channel_request_get_hints (self);

  if (hints == NULL)
    return NULL;

  return _tp_asv_to_vardict (hints);
}
