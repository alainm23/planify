/*
 * Simple implementation of an Approver
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
 * SECTION: simple-approver
 * @title: TpSimpleApprover
 * @short_description: a subclass of #TpBaseClient implementing
 * a simple Approver
 *
 * This class makes it easier to construct a #TpSvcClient implementing the
 * #TpSvcClientApprover interface.
 *
 * A typical simple approver would look liks this:
 * |[
 * static void
 * my_add_dispatch_operation (TpSimpleApprover *approver,
 *    TpAccount *account,
 *    TpConnection *connection,
 *    GList *channels,
 *    TpChannelDispatchOperation *dispatch_operation,
 *    TpAddDispatchOperationContext *context,
 *    gpointer user_data)
 * {
 *  /<!-- -->* call tp_channel_dispatch_operation_handle_with_async()
 *  if wanting to approve the channels *<!-- -->/
 *
 *  tp_add_dispatch_operation_context_accept (context);
 * }
 *
 * factory = tp_automatic_client_factory_new (dbus);
 * client = tp_simple_approver_new_with_factory (factory, "MyApprover", FALSE,
 *    my_add_dispatch_operation, user_data);
 * g_object_unref (factory);
 *
 * tp_base_client_take_approver_filter (client, tp_asv_new (
 *      TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING, TP_IFACE_CHANNEL_TYPE_TEXT,
 *      TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, G_TYPE_UINT, TP_HANDLE_TYPE_CONTACT,
 *      NULL));
 *
 * tp_base_client_register (client, NULL);
 * ]|
 *
 * See examples/client/text-approver.c for a complete example.
 */

/**
 * TpSimpleApprover:
 *
 * Data structure representing a simple Approver implementation.
 *
 * Since: 0.11.5
 */

/**
 * TpSimpleApproverClass:
 *
 * The class of a #TpSimpleApprover.
 *
 * Since: 0.11.5
 */

/**
 * TpSimpleApproverAddDispatchOperationImpl:
 * @approver: a #TpSimpleApprover instance
 * @account: a #TpAccount having %TP_ACCOUNT_FEATURE_CORE prepared if possible
 * @connection: a #TpConnection having %TP_CONNECTION_FEATURE_CORE prepared
 * if possible
 * @channels: (element-type TelepathyGLib.Channel): a #GList of #TpChannel,
 *  all having %TP_CHANNEL_FEATURE_CORE prepared
 * @dispatch_operation: (allow-none): a #TpChannelDispatchOperation or %NULL;
 *  the dispatch_operation is not guaranteed to be prepared
 * @context: a #TpAddDispatchOperationContext representing the context of this
 *  D-Bus call
 * @user_data: arbitrary user-supplied data passed to tp_simple_approver_new()
 *
 * Signature of the implementation of the AddDispatchOperation method.
 *
 * This function must call either tp_add_dispatch_operation_context_accept(),
 * tp_add_dispatch_operation_context_delay() or
 * tp_add_dispatch_operation_context_fail() on @context before it returns.
 *
 * Since: 0.11.5
 */

#include "config.h"

#include "telepathy-glib/simple-approver.h"

#define DEBUG_FLAG TP_DEBUG_CLIENT
#include "telepathy-glib/debug-internal.h"

G_DEFINE_TYPE(TpSimpleApprover, tp_simple_approver, TP_TYPE_BASE_CLIENT)

enum {
    PROP_CALLBACK = 1,
    PROP_USER_DATA,
    PROP_DESTROY,
    N_PROPS
};

struct _TpSimpleApproverPrivate
{
  TpSimpleApproverAddDispatchOperationImpl callback;
  gpointer user_data;
  GDestroyNotify destroy;
};

static void
tp_simple_approver_init (TpSimpleApprover *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_SIMPLE_APPROVER,
      TpSimpleApproverPrivate);
}

static void
tp_simple_approver_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpSimpleApprover *self = TP_SIMPLE_APPROVER (object);

  switch (property_id)
    {
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
tp_simple_approver_constructed (GObject *object)
{
  TpSimpleApprover *self = TP_SIMPLE_APPROVER (object);
  void (*chain_up) (GObject *) =
    ((GObjectClass *) tp_simple_approver_parent_class)->constructed;

  g_assert (self->priv->callback != NULL);

  if (chain_up != NULL)
    chain_up (object);
}

static void
tp_simple_approver_dispose (GObject *object)
{
  TpSimpleApprover *self = TP_SIMPLE_APPROVER (object);
  void (*dispose) (GObject *) =
    G_OBJECT_CLASS (tp_simple_approver_parent_class)->dispose;

  if (self->priv->destroy != NULL)
    {
      self->priv->destroy (self->priv->user_data);
      self->priv->destroy = NULL;
    }

  if (dispose != NULL)
    dispose (object);
}

static void
add_dispatch_operation (
    TpBaseClient *client,
    TpAccount *account,
    TpConnection *connection,
    GList *channels,
    TpChannelDispatchOperation *dispatch_operation,
    TpAddDispatchOperationContext *context)
{
  TpSimpleApprover *self = TP_SIMPLE_APPROVER (client);

  self->priv->callback (self, account, connection, channels, dispatch_operation,
      context, self->priv->user_data);
}

static void
tp_simple_approver_class_init (TpSimpleApproverClass *cls)
{
  GObjectClass *object_class = G_OBJECT_CLASS (cls);
  TpBaseClientClass *base_clt_cls = TP_BASE_CLIENT_CLASS (cls);
  GParamSpec *param_spec;

  g_type_class_add_private (cls, sizeof (TpSimpleApproverPrivate));

  object_class->set_property = tp_simple_approver_set_property;
  object_class->constructed = tp_simple_approver_constructed;
  object_class->dispose = tp_simple_approver_dispose;

  /**
   * TpSimpleApprover:callback:
   *
   * The #TpSimpleApproverAddDispatchOperationImpl callback implementing the
   * AddDispatchOperation D-Bus method.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_pointer ("callback",
      "Callback",
      "Function called when ApproverChannels is called",
      G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CALLBACK,
      param_spec);

  /**
   * TpSimpleApprover:user-data:
   *
   * The user-data pointer passed to #TpSimpleApprover:callback.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_pointer ("user-data", "user data",
      "pointer passed as user-data when ApproverChannels is called",
      G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_USER_DATA,
      param_spec);

  /**
   * TpSimpleApprover:destroy:
   *
   * The #GDestroyNotify function called to free #TpSimpleApprover:user-data
   * when the #TpSimpleApprover is destroyed.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_pointer ("destroy", "destroy",
      "function called to destroy the user-data when destroying the approver",
      G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DESTROY,
      param_spec);

  base_clt_cls->add_dispatch_operation = add_dispatch_operation;
}

/**
 * tp_simple_approver_new:
 * @dbus: a #TpDBusDaemon object, may not be %NULL
 * @name: the name of the Approver (see #TpBaseClient:name for details)
 * @uniquify: the value of the #TpBaseClient:uniquify-name property
 * @callback: the function called when AddDispatchOperation is called
 * @user_data: arbitrary user-supplied data passed to @callback
 * @destroy: called with @user_data as its argument when the #TpSimpleApprover
 * is destroyed
 *
 * Convenient function to create a new #TpSimpleApprover instance.
 *
 * If @dbus is not the result of tp_dbus_daemon_dup(), you should call
 * tp_simple_approver_new_with_am() instead, so that #TpAccount,
 * #TpConnection and #TpContact instances can be shared between modules.
 *
 * Returns: (type TelepathyGLib.SimpleApprover): a new #TpSimpleApprover
 *
 * Since: 0.11.5
 * Deprecated: New code should use tp_simple_approver_new_with_am() instead.
 */
TpBaseClient *
tp_simple_approver_new (TpDBusDaemon *dbus,
    const gchar *name,
    gboolean uniquify,
    TpSimpleApproverAddDispatchOperationImpl callback,
    gpointer user_data,
    GDestroyNotify destroy)
{
  return g_object_new (TP_TYPE_SIMPLE_APPROVER,
      "dbus-daemon", dbus,
      "name", name,
      "uniquify-name", uniquify,
      "callback", callback,
      "user-data", user_data,
      "destroy", destroy,
      NULL);
}

/**
 * tp_simple_approver_new_with_am:
 * @account_manager: an account manager, which may not be %NULL
 * @name: the name of the Approver (see #TpBaseClient:name for details)
 * @uniquify: the value of the #TpBaseClient:uniquify-name property
 * @callback: the function called when AddDispatchOperation is called
 * @user_data: arbitrary user-supplied data passed to @callback
 * @destroy: called with @user_data as its argument when the #TpSimpleApprover
 * is destroyed
 *
 * Convenient function to create a new #TpSimpleApprover instance with a
 * specified #TpAccountManager.
 *
 * It is not necessary to prepare any features on @account_manager before
 * calling this function.
 *
 * Returns: (type TelepathyGLib.SimpleApprover): a new #TpSimpleApprover
 *
 * Since: 0.11.14
 */
TpBaseClient *
tp_simple_approver_new_with_am (TpAccountManager *account_manager,
    const gchar *name,
    gboolean uniquify,
    TpSimpleApproverAddDispatchOperationImpl callback,
    gpointer user_data,
    GDestroyNotify destroy)
{
  return g_object_new (TP_TYPE_SIMPLE_APPROVER,
      "account-manager", account_manager,
      "name", name,
      "uniquify-name", uniquify,
      "callback", callback,
      "user-data", user_data,
      "destroy", destroy,
      NULL);
}

/**
 * tp_simple_approver_new_with_factory:
 * @factory: an #TpSimpleClientFactory, which may not be %NULL
 * @name: the name of the Approver (see #TpBaseClient:name for details)
 * @uniquify: the value of the #TpBaseClient:uniquify-name property
 * @callback: the function called when AddDispatchOperation is called
 * @user_data: arbitrary user-supplied data passed to @callback
 * @destroy: called with @user_data as its argument when the #TpSimpleApprover
 * is destroyed
 *
 * Convenient function to create a new #TpSimpleApprover instance with a
 * specified #TpSimpleClientFactory.
 *
 * Returns: (type TelepathyGLib.SimpleApprover): a new #TpSimpleApprover
 *
 * Since: 0.15.5
 */
TpBaseClient *
tp_simple_approver_new_with_factory (TpSimpleClientFactory *factory,
    const gchar *name,
    gboolean uniquify,
    TpSimpleApproverAddDispatchOperationImpl callback,
    gpointer user_data,
    GDestroyNotify destroy)
{
  return g_object_new (TP_TYPE_SIMPLE_APPROVER,
      "factory", factory,
      "name", name,
      "uniquify-name", uniquify,
      "callback", callback,
      "user-data", user_data,
      "destroy", destroy,
      NULL);
}
