/*
 * Simple implementation of an Handler
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
 * SECTION: simple-handler
 * @title: TpSimpleHandler
 * @short_description: a subclass of #TpBaseClient implementing
 * a simple Handler
 *
 * This class makes it easier to construct a #TpSvcClient implementing the
 * #TpSvcClientHandler interface.
 *
 * A typical simple handler would look liks this:
 * |[
 * static void
 * my_handle_channels (TpSimpleHandler *handler,
 *    TpAccount *account,
 *    TpConnection *connection,
 *    GList *channels,
 *    GList *requests_satisfied,
 *    gint64 user_action_time,
 *    GList *requests,
 *    TpHandleChannelsContext *context,
 *    gpointer user_data)
 * {
 *  /<!-- -->* start handling the channels here *<!-- -->/
 *
 *  tp_handle_channels_context_accept (context);
 * }
 *
 * factory = tp_automatic_client_factory_new (dbus);
 * client = tp_simple_handler_new_with_factory (factory, FALSE, FALSE,
 *     "MyHandler", FALSE, my_handle_channels, user_data);
 * g_object_unref (factory);
 *
 * tp_base_client_take_handler_filter (client, tp_asv_new (
 *      TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING, TP_IFACE_CHANNEL_TYPE_TEXT,
 *      TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, G_TYPE_UINT, TP_HANDLE_TYPE_CONTACT,
 *      NULL));
 *
 * tp_base_client_register (client, NULL);
 * ]|
 *
 * See examples/client/text-handler.c for a complete example.
 *
 * Since: 0.11.6
 */

/**
 * TpSimpleHandler:
 *
 * Data structure representing a simple Handler implementation.
 *
 * Since: 0.11.6
 */

/**
 * TpSimpleHandlerClass:
 *
 * The class of a #TpSimpleHandler.
 *
 * Since: 0.11.6
 */

/**
 * TpSimpleHandlerHandleChannelsImpl:
 * @handler: a #TpSimpleHandler instance
 * @account: a #TpAccount having %TP_ACCOUNT_FEATURE_CORE prepared if possible
 * @connection: a #TpConnection having %TP_CONNECTION_FEATURE_CORE prepared
 * if possible
 * @channels: (element-type TelepathyGLib.Channel): a #GList of #TpChannel,
 *  all having %TP_CHANNEL_FEATURE_CORE prepared if possible
 * @requests_satisfied: (element-type TelepathyGLib.ChannelRequest): a #GList of
 * #TpChannelRequest having their object-path defined but are not guaranteed
 * to be prepared.
 * @user_action_time: the time at which user action occurred, or one of the
 *  special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
 *  %TP_USER_ACTION_TIME_CURRENT_TIME
 *  (see #TpAccountChannelRequest:user-action-time for details)
 * @context: a #TpHandleChannelsContext representing the context of this
 *  D-Bus call
 * @user_data: arbitrary user-supplied data passed to tp_simple_handler_new()
 *
 * Signature of the implementation of the HandleChannels method.
 *
 * This function must call either tp_handle_channels_context_accept(),
 * tp_handle_channels_context_delay() or tp_handle_channels_context_fail()
 * on @context before it returns.
 *
 * Since: 0.11.6
 */

#include "config.h"

#include "telepathy-glib/simple-handler.h"

#define DEBUG_FLAG TP_DEBUG_CLIENT
#include "telepathy-glib/debug-internal.h"

G_DEFINE_TYPE(TpSimpleHandler, tp_simple_handler, TP_TYPE_BASE_CLIENT)

enum {
    PROP_BYPASS_APPROVAL = 1,
    PROP_REQUESTS,
    PROP_CALLBACK,
    PROP_USER_DATA,
    PROP_DESTROY,
    N_PROPS
};

struct _TpSimpleHandlerPrivate
{
  TpSimpleHandlerHandleChannelsImpl callback;
  gpointer user_data;
  GDestroyNotify destroy;
};

static void
tp_simple_handler_init (TpSimpleHandler *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_SIMPLE_HANDLER,
      TpSimpleHandlerPrivate);
}

static void
tp_simple_handler_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpBaseClient *base = TP_BASE_CLIENT (object);
  TpSimpleHandler *self = TP_SIMPLE_HANDLER (object);

  switch (property_id)
    {
      case PROP_BYPASS_APPROVAL:
        tp_base_client_set_handler_bypass_approval (base,
            g_value_get_boolean (value));
        break;

      case PROP_REQUESTS:
        if (g_value_get_boolean (value))
          tp_base_client_set_handler_request_notification (base);
        break;

      case PROP_CALLBACK:
        self->priv->callback = g_value_get_pointer (value);
        break;

      case PROP_USER_DATA:
        self->priv->user_data = g_value_get_pointer (value);
        break;

      case PROP_DESTROY:
        self->priv->destroy = g_value_get_pointer (value);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_simple_handler_constructed (GObject *object)
{
  TpSimpleHandler *self = TP_SIMPLE_HANDLER (object);
  void (*chain_up) (GObject *) =
    ((GObjectClass *) tp_simple_handler_parent_class)->constructed;

  g_assert (self->priv->callback != NULL);

  if (chain_up != NULL)
    chain_up (object);
}

static void
tp_simple_handler_dispose (GObject *object)
{
  TpSimpleHandler *self = TP_SIMPLE_HANDLER (object);
  void (*dispose) (GObject *) =
    G_OBJECT_CLASS (tp_simple_handler_parent_class)->dispose;

  if (self->priv->destroy != NULL)
    {
      self->priv->destroy (self->priv->user_data);
      self->priv->destroy = NULL;
    }

  if (dispose != NULL)
    dispose (object);
}

static void
handle_channels (
    TpBaseClient *client,
    TpAccount *account,
    TpConnection *connection,
    GList *channels,
    GList *requests_satisfied,
    gint64 user_action_time,
    TpHandleChannelsContext *context)
{
  TpSimpleHandler *self = TP_SIMPLE_HANDLER (client);

  self->priv->callback (self, account, connection, channels,
      requests_satisfied, user_action_time, context, self->priv->user_data);
}

static void
tp_simple_handler_class_init (TpSimpleHandlerClass *cls)
{
  GObjectClass *object_class = G_OBJECT_CLASS (cls);
  TpBaseClientClass *base_clt_cls = TP_BASE_CLIENT_CLASS (cls);
  GParamSpec *param_spec;

  g_type_class_add_private (cls, sizeof (TpSimpleHandlerPrivate));

  object_class->set_property = tp_simple_handler_set_property;
  object_class->constructed = tp_simple_handler_constructed;
  object_class->dispose = tp_simple_handler_dispose;

  /**
   * TpSimpleHandler:bypass-approval:
   *
   * The value of the Handler.BypassApproval D-Bus property.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_boolean ("bypass-approval", "bypass approval",
      "Handler.BypassApproval",
      FALSE,
      G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_BYPASS_APPROVAL,
      param_spec);

  /**
   * TpSimpleHandler:requests:
   *
   * If %TRUE, the Handler will implement the Requests interface
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_boolean ("requests", "requests",
      "Requests",
      FALSE,
      G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_REQUESTS,
      param_spec);

  /**
   * TpSimpleHandler:callback:
   *
   * The #TpSimpleHandlerHandleChannelsImpl callback implementing the
   * HandleChannels D-Bus method.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_pointer ("callback",
      "Callback",
      "Function called when HandleChannels is called",
      G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CALLBACK,
      param_spec);

  /**
   * TpSimpleHandler:user-data:
   *
   * The user-data pointer passed to #TpSimpleHandler:callback.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_pointer ("user-data", "user data",
      "pointer passed as user-data when HandleChannels is called",
      G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_USER_DATA,
      param_spec);

  /**
   * TpSimpleHandler:destroy:
   *
   * The #GDestroyNotify function called to free #TpSimpleHandler:user-data
   * when the #TpSimpleHandler is destroyed.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_pointer ("destroy", "destroy",
      "function called to destroy the user-data when destroying the handler",
      G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DESTROY,
      param_spec);

  base_clt_cls->handle_channels = handle_channels;
}

/**
 * tp_simple_handler_new:
 * @dbus: a #TpDBusDaemon object, may not be %NULL
 * @bypass_approval: the value of the Handler.BypassApproval D-Bus property
 * (see tp_base_client_set_handler_bypass_approval() for details)
 * @requests: whether this handler should implement Requests (see
 * tp_base_client_set_handler_request_notification() for details)
 * @name: the name of the Handler (see #TpBaseClient:name for details)
 * @uniquify: the value of the #TpBaseClient:uniquify-name property
 * @callback: the function called when HandleChannels is called
 * @user_data: arbitrary user-supplied data passed to @callback
 * @destroy: called with @user_data as its argument when the #TpSimpleHandler
 * is destroyed
 *
 * Convenient function to create a new #TpSimpleHandler instance.
 *
 * If @dbus is not the result of tp_dbus_daemon_dup(), you should call
 * tp_simple_handler_new_with_am() instead, so that #TpAccount,
 * #TpConnection and #TpContact instances can be shared between modules.
 *
 * Returns: (type TelepathyGLib.SimpleHandler): a new #TpSimpleHandler
 *
 * Since: 0.11.6
 * Deprecated: New code should use tp_simple_handler_new_with_am() instead.
 */
TpBaseClient *
tp_simple_handler_new (TpDBusDaemon *dbus,
    gboolean bypass_approval,
    gboolean requests,
    const gchar *name,
    gboolean uniquify,
    TpSimpleHandlerHandleChannelsImpl callback,
    gpointer user_data,
    GDestroyNotify destroy)
{
  return g_object_new (TP_TYPE_SIMPLE_HANDLER,
      "dbus-daemon", dbus,
      "bypass-approval", bypass_approval,
      "requests", requests,
      "name", name,
      "uniquify-name", uniquify,
      "callback", callback,
      "user-data", user_data,
      "destroy", destroy,
      NULL);
}

/**
 * tp_simple_handler_new_with_am:
 * @account_manager: an account manager, which may not be %NULL
 * @bypass_approval: the value of the Handler.BypassApproval D-Bus property
 * (see tp_base_client_set_handler_bypass_approval() for details)
 * @requests: whether this handler should implement Requests (see
 * tp_base_client_set_handler_request_notification() for details)
 * @name: the name of the Handler (see #TpBaseClient:name for details)
 * @uniquify: the value of the #TpBaseClient:uniquify-name property
 * @callback: the function called when HandleChannels is called
 * @user_data: arbitrary user-supplied data passed to @callback
 * @destroy: called with @user_data as its argument when the #TpSimpleHandler
 * is destroyed
 *
 * Convenient function to create a new #TpSimpleHandler instance with a
 * specified #TpAccountManager.
 *
 * It is not necessary to prepare any features on @account_manager before
 * calling this function.
 *
 * Returns: (type TelepathyGLib.SimpleHandler): a new #TpSimpleHandler
 *
 * Since: 0.11.14
 */
TpBaseClient *
tp_simple_handler_new_with_am (TpAccountManager *account_manager,
    gboolean bypass_approval,
    gboolean requests,
    const gchar *name,
    gboolean uniquify,
    TpSimpleHandlerHandleChannelsImpl callback,
    gpointer user_data,
    GDestroyNotify destroy)
{
  return g_object_new (TP_TYPE_SIMPLE_HANDLER,
      "account-manager", account_manager,
      "bypass-approval", bypass_approval,
      "requests", requests,
      "name", name,
      "uniquify-name", uniquify,
      "callback", callback,
      "user-data", user_data,
      "destroy", destroy,
      NULL);
}

/**
 * tp_simple_handler_new_with_factory:
 * @factory: a #TpSimpleClientFactory, which may not be %NULL
 * @bypass_approval: the value of the Handler.BypassApproval D-Bus property
 * (see tp_base_client_set_handler_bypass_approval() for details)
 * @requests: whether this handler should implement Requests (see
 * tp_base_client_set_handler_request_notification() for details)
 * @name: the name of the Handler (see #TpBaseClient:name for details)
 * @uniquify: the value of the #TpBaseClient:uniquify-name property
 * @callback: the function called when HandleChannels is called
 * @user_data: arbitrary user-supplied data passed to @callback
 * @destroy: called with @user_data as its argument when the #TpSimpleHandler
 * is destroyed
 *
 * Convenient function to create a new #TpSimpleHandler instance with a
 * specified #TpSimpleClientFactory.
 *
 * Returns: (type TelepathyGLib.SimpleHandler): a new #TpSimpleHandler
 *
 * Since: 0.15.5
 */
TpBaseClient *
tp_simple_handler_new_with_factory (TpSimpleClientFactory *factory,
    gboolean bypass_approval,
    gboolean requests,
    const gchar *name,
    gboolean uniquify,
    TpSimpleHandlerHandleChannelsImpl callback,
    gpointer user_data,
    GDestroyNotify destroy)
{
  return g_object_new (TP_TYPE_SIMPLE_HANDLER,
      "factory", factory,
      "bypass-approval", bypass_approval,
      "requests", requests,
      "name", name,
      "uniquify-name", uniquify,
      "callback", callback,
      "user-data", user_data,
      "destroy", destroy,
      NULL);
}
