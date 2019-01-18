/*
 * Base class for Client implementations
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
 * SECTION:base-client
 * @title: TpBaseClient
 * @short_description: base class for Telepathy clients on D-Bus
 *
 * This base class makes it easier to write #TpSvcClient
 * implementations. Subclasses should usually pass the filters they
 * want and override the D-Bus methods they implement.
 *
 * For many applications, the provided #TpSimpleObserver, #TpSimpleApprover
 * and #TpSimpleHandler subclasses can be used instead of deriving from this
 * class.
 */

/**
 * TpBaseClient:
 *
 * Data structure representing a generic #TpSvcClient implementation.
 *
 * Since: 0.11.5
 */

/**
 * TpBaseClientClass:
 * @parent_class: the parent class
 * @observe_channels: the function called to observe newly-created channels
 *  matching this client's observer filter (since 0.11.13)
 * @add_dispatch_operation: the function called to request user approval of
 *  unrequested (incoming) channels matching this client's approver filter
 *  (since 0.11.13)
 * @handle_channels: the function called to handle channels matching this
 *  client's handler filter (since 0.11.13)
 *
 * The class of a #TpBaseClient.
 *
 * The virtual methods @observe_channels, @add_dispatch_operation and
 * @handle_channels can be also implemented by calling
 * tp_base_client_implement_observe_channels(),
 * tp_base_client_implement_add_dispatch_operation() and
 * tp_base_client_implement_handle_channels(). This is compatible with
 * telepathy-glib versions older than 0.11.13.
 *
 * Since: 0.11.5
 */

/**
 * TpBaseClientClassObserveChannelsImpl:
 * @client: a #TpBaseClient instance
 * @account: a #TpAccount with %TP_ACCOUNT_FEATURE_CORE, and any other
 *  features added via tp_base_client_add_account_features() or
 *  tp_simple_client_factory_add_account_features(), prepared if
 *  possible
 * @connection: a #TpConnection with %TP_CONNECTION_FEATURE_CORE,
 *  and any other features added via tp_base_client_add_connection_features(),
 *  or tp_simple_client_factory_add_connection_features(), prepared if possible
 * @channels: (element-type TelepathyGLib.Channel): a #GList of #TpChannel,
 *  each with %TP_CHANNEL_FEATURE_CORE, and any other features added via
 *  tp_base_client_add_channel_features() or
 *  tp_simple_client_factory_add_channel_features(), prepared if possible
 * @dispatch_operation: (allow-none): a #TpChannelDispatchOperation or %NULL;
 *  the dispatch_operation is not guaranteed to be prepared
 * @requests: (element-type TelepathyGLib.ChannelRequest): a #GList of
 *  #TpChannelRequest having their object-path defined but are not guaranteed
 *  to be prepared.
 * @context: a #TpObserveChannelsContext representing the context of this
 *  D-Bus call
 *
 * Signature of the implementation of the ObserveChannels method.
 *
 * This function must call either tp_observe_channels_context_accept(),
 * tp_observe_channels_context_delay() or tp_observe_channels_context_fail()
 * on @context before it returns.
 *
 * Since: 0.11.5
 */

/**
 * TpBaseClientClassAddDispatchOperationImpl:
 * @client: a #TpBaseClient instance
 * @account: a #TpAccount with %TP_ACCOUNT_FEATURE_CORE, and any other
 *  features added via tp_base_client_add_account_features() or
 *  tp_simple_client_factory_add_account_features(), prepared if
 *  possible
 * @connection: a #TpConnection with %TP_CONNECTION_FEATURE_CORE,
 *  and any other features added via tp_base_client_add_connection_features(),
 *  or tp_simple_client_factory_add_connection_features(), prepared if possible
 * @channels: (element-type TelepathyGLib.Channel): a #GList of #TpChannel,
 *  each with %TP_CHANNEL_FEATURE_CORE, and any other features added via
 *  tp_base_client_add_channel_features() or
 *  tp_simple_client_factory_add_channel_features(), prepared if possible
 * @dispatch_operation: a #TpChannelDispatchOperation having
 * %TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE prepared if possible
 * @context: a #TpObserveChannelsContext representing the context of this
 *  D-Bus call
 *
 * Signature of the implementation of the AddDispatchOperation method.
 *
 * This function must call either tp_add_dispatch_operation_context_accept(),
 * tp_add_dispatch_operation_context_delay() or
 * tp_add_dispatch_operation_context_fail() on @context before it returns.
 *
 * The implementation can then use
 * tp_channel_dispatch_operation_handle_with_async() to approve handling of the
 * channels, or tp_channel_dispatch_operation_claim_async() to take
 * responsibility for handling or closing them".
 *
 * Since: 0.11.5
 */

/**
 * TpBaseClientClassHandleChannelsImpl:
 * @client: a #TpBaseClient instance
 * @account: a #TpAccount with %TP_ACCOUNT_FEATURE_CORE, and any other
 *  features added via tp_base_client_add_account_features() or
 *  tp_simple_client_factory_add_account_features(), prepared if
 *  possible
 * @connection: a #TpConnection with %TP_CONNECTION_FEATURE_CORE,
 *  and any other features added via tp_base_client_add_connection_features(),
 *  or tp_simple_client_factory_add_connection_features(), prepared if possible
 * @channels: (element-type TelepathyGLib.Channel): a #GList of #TpChannel,
 *  each with %TP_CHANNEL_FEATURE_CORE, and any other features added via
 *  tp_base_client_add_channel_features() or
 *  tp_simple_client_factory_add_channel_features(), prepared if possible
 * @requests_satisfied: (element-type TelepathyGLib.ChannelRequest): a #GList of
 *  #TpChannelRequest having their object-path defined but are not guaranteed
 *  to be prepared.
 * @user_action_time: the time at which user action occurred, or one of the
 *  special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
 *  %TP_USER_ACTION_TIME_CURRENT_TIME
 *  (see #TpAccountChannelRequest:user-action-time for details)
 * @context: a #TpHandleChannelsContext representing the context of this
 *  D-Bus call
 *
 * Signature of the implementation of the HandleChannels method.
 *
 * This function must call either tp_handle_channels_context_accept(),
 * tp_handle_channels_context_delay() or tp_handle_channels_context_fail()
 * on @context before it returns.
 *
 * Since: 0.11.6
 */

/**
 * TpBaseClientDelegatedChannelsCb:
 * @client: a #TpBaseClient instance
 * @channels: (element-type TelepathyGLib.Channel): a #GPtrArray of #TpChannel
 * @user_data: arbitrary user-supplied data passed to
 * tp_base_client_set_delegated_channels_callback()
 *
 * Called when a client asked us to delegate @channels to another Handler.
 * When this function is called @client is not longer handling @channels.
 *
 * Since: 0.15.3
 */

#include "config.h"

#include "telepathy-glib/base-client.h"
#include "telepathy-glib/base-client-internal.h"

#include <stdarg.h>
#include <string.h>                     /* for G_VA_COPY */

#include <dbus/dbus.h>
#include <dbus/dbus-glib-lowlevel.h>

#include <telepathy-glib/add-dispatch-operation-context-internal.h>
#include <telepathy-glib/automatic-proxy-factory.h>
#include <telepathy-glib/channel-dispatch-operation-internal.h>
#include <telepathy-glib/channel-dispatcher.h>
#include <telepathy-glib/channel-request.h>
#include <telepathy-glib/channel.h>
#include <telepathy-glib/dbus-internal.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/handle-channels-context-internal.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/observe-channels-context-internal.h>
#include <telepathy-glib/svc-client.h>
#include <telepathy-glib/svc-generic.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CLIENT
#include "telepathy-glib/connection-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/deprecated-internal.h"
#include "telepathy-glib/simple-client-factory-internal.h"
#include "telepathy-glib/util-internal.h"
#include "telepathy-glib/variant-util-internal.h"

static void observer_iface_init (gpointer, gpointer);
static void approver_iface_init (gpointer, gpointer);
static void handler_iface_init (gpointer, gpointer);
static void requests_iface_init (gpointer, gpointer);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE(TpBaseClient, tp_base_client, G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_DBUS_PROPERTIES,
      tp_dbus_properties_mixin_iface_init);
    G_IMPLEMENT_INTERFACE(TP_TYPE_SVC_CLIENT, NULL);
    G_IMPLEMENT_INTERFACE(TP_TYPE_SVC_CLIENT_OBSERVER, observer_iface_init);
    G_IMPLEMENT_INTERFACE(TP_TYPE_SVC_CLIENT_APPROVER, approver_iface_init);
    G_IMPLEMENT_INTERFACE(TP_TYPE_SVC_CLIENT_HANDLER, handler_iface_init);
    G_IMPLEMENT_INTERFACE(TP_TYPE_SVC_CLIENT_INTERFACE_REQUESTS,
      requests_iface_init))

enum {
    PROP_DBUS_DAEMON = 1,
    PROP_ACCOUNT_MANAGER,
    PROP_FACTORY,
    PROP_NAME,
    PROP_UNIQUIFY_NAME,
    PROP_CHANNEL_FACTORY,
    N_PROPS
};

enum {
  SIGNAL_REQUEST_ADDED,
  SIGNAL_REQUEST_REMOVED,
  N_SIGNALS
};

static guint signals[N_SIGNALS] = { 0 };

static dbus_int32_t clients_slot = -1;

typedef enum {
    CLIENT_IS_OBSERVER = 1 << 0,
    CLIENT_IS_APPROVER = 1 << 1,
    CLIENT_IS_HANDLER = 1 << 2,
    CLIENT_HANDLER_WANTS_REQUESTS = 1 << 3,
    CLIENT_HANDLER_BYPASSES_APPROVAL = 1 << 4,
    CLIENT_OBSERVER_RECOVER = 1 << 5,
    CLIENT_OBSERVER_DELAYS_APPROVERS = 1 << 6,
} ClientFlags;

struct _TpBaseClientPrivate
{
  TpSimpleClientFactory *factory;
  TpDBusDaemon *dbus;
  gchar *name;
  gboolean uniquify_name;
  /* reffed */
  DBusConnection *libdbus;

  gboolean registered;
  ClientFlags flags;
  /* array of TP_HASH_TYPE_CHANNEL_CLASS */
  GPtrArray *observer_filters;
  /* array of TP_HASH_TYPE_CHANNEL_CLASS */
  GPtrArray *approver_filters;
  /* array of TP_HASH_TYPE_CHANNEL_CLASS */
  GPtrArray *handler_filters;
  /* array of g_strdup(token), plus NULL included in length */
  GPtrArray *handler_caps;

  GList *pending_requests;
  /* Channels actually handled by THIS observer.
   * borrowed path (gchar *) => reffed TpChannel */
  GHashTable *my_chans;

  gchar *bus_name;
  gchar *object_path;

  TpAccountManager *account_mgr;
  TpAccount *only_for_account;
  TpClientChannelFactory *channel_factory;

  /* array of GQuark or NULL */
  GArray *account_features;
  GArray *connection_features;
  GArray *channel_features;

  TpBaseClientDelegatedChannelsCb delegated_channels_cb;
  gpointer delegated_channels_data;
  GDestroyNotify delegated_channels_destroy;
};

/*
 * _tp_base_client_set_only_for_account:
 *
 * Set the account to be used for this TpBaseClient. Channels from any other
 * account will be rejected.
 *
 * This is for internal use by TpAccountChannelRequest, which sets up a
 * temporary Handler solely to be the preferred handler for that request.
 * See https://bugs.freedesktop.org/show_bug.cgi?id=29614
 */
void
_tp_base_client_set_only_for_account (TpBaseClient *self,
    TpAccount *account)
{
  g_return_if_fail (self->priv->only_for_account == NULL);
  g_return_if_fail (tp_proxy_get_factory (account) == self->priv->factory);

  self->priv->only_for_account = g_object_ref (account);
}

static TpAccount *
tp_base_client_dup_account (TpBaseClient *self,
    const gchar *path,
    GError **error)
{
  if (self->priv->only_for_account != NULL)
    {
      if (G_UNLIKELY (tp_strdiff (tp_proxy_get_object_path (
                self->priv->only_for_account), path)))
        {
          g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
              "This client only deals with channels from account %s",
              tp_proxy_get_object_path (self->priv->only_for_account));
          return NULL;
        }

      return g_object_ref (self->priv->only_for_account);
    }

  return tp_simple_client_factory_ensure_account (self->priv->factory,
      path, NULL, error);
}

static GHashTable *
_tp_base_client_copy_filter (GHashTable *filter)
{
  GHashTable *copy;

  copy = g_hash_table_new_full (g_str_hash, g_str_equal, g_free,
      (GDestroyNotify) tp_g_value_slice_free);
  tp_g_hash_table_update (copy, filter, (GBoxedCopyFunc) g_strdup,
      (GBoxedCopyFunc) tp_g_value_slice_dup);
  return copy;
}

/**
 * tp_base_client_add_observer_filter:
 * @self: a #TpBaseClient
 * @filter: (transfer none) (element-type utf8 GObject.Value):
 * a %TP_HASH_TYPE_CHANNEL_CLASS
 *
 * Register a new channel class as Observer.ObserverChannelFilter.
 * The #TpBaseClientClass.observe_channels virtual method will be called
 * whenever a new channel's properties match the ones in @filter.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.observe_channels.
 *
 * Since: 0.11.5
 */
void
tp_base_client_add_observer_filter (TpBaseClient *self,
    GHashTable *filter)
{
  g_return_if_fail (filter != NULL);
  tp_base_client_take_observer_filter (self,
      _tp_base_client_copy_filter (filter));
}

/**
 * tp_base_client_take_observer_filter: (skip)
 * @self: a client
 * @filter: (transfer full) (element-type utf8 GObject.Value):
 * a %TP_HASH_TYPE_CHANNEL_CLASS, ownership of which is taken by @self
 *
 * The same as tp_base_client_add_observer_filter(), but ownership of @filter
 * is taken by @self. This makes it convenient to call using tp_asv_new():
 *
 * |[
 * tp_base_client_take_observer_filter (client,
 *    tp_asv_new (
 *        TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING,
 *            TP_IFACE_CHANNEL_TYPE_TEXT,
 *        TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, G_TYPE_UINT,
 *            TP_HANDLE_TYPE_CONTACT,
 *        ...));
 * ]|
 *
 * Since: 0.11.5
 */
void
tp_base_client_take_observer_filter (TpBaseClient *self,
    GHashTable *filter)
{
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);
  g_return_if_fail (cls->observe_channels != NULL);

  self->priv->flags |= CLIENT_IS_OBSERVER;
  g_ptr_array_add (self->priv->observer_filters, filter);
}

/**
 * tp_base_client_add_observer_filter_vardict:
 * @self: a client
 * @filter: (transfer none): a variant of type %G_VARIANT_TYPE_VARDICT
 *
 * Register a new channel class as Observer.ObserverChannelFilter.
 * The #TpBaseClientClass.observe_channels virtual method will be called
 * whenever a new channel's properties match the ones in @filter.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.observe_channels.
 *
 * If the variant is floating (see g_variant_ref_sink()), ownership
 * will be taken, allowing for uses like this:
 *
 * |[
 * tp_base_client_add_observer_filter_vardict (client,
 *    g_variant_new_parsed ("{ %s: <%s>, %s: <%u>, ... }",
 *        TP_PROP_CHANNEL_CHANNEL_TYPE, TP_IFACE_CHANNEL_TYPE_TEXT,
 *        TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, (guint32) TP_HANDLE_TYPE_CONTACT,
 *        ...));
 * ]|
 *
 * Since: 0.19.10
 */
void
tp_base_client_add_observer_filter_vardict (TpBaseClient *self,
    GVariant *filter)
{
  g_return_if_fail (g_variant_is_of_type (filter, G_VARIANT_TYPE_VARDICT));

  g_variant_ref_sink (filter);
  tp_base_client_take_observer_filter (self, _tp_asv_from_vardict (filter));
  g_variant_unref (filter);
}

/**
 * tp_base_client_set_observer_recover:
 * @self: a #TpBaseClient
 * @recover: the value of the Observer.Recover property
 *
 * Set whether the channel dispatcher should attempt to recover
 * this Observer if it crashes. (This is implemented by setting
 * the value of its Recover D-Bus property.)
 *
 * Normally, Observers are only notified when new channels
 * appear. If an Observer is set to recover, when it registers with
 * tp_base_client_register(), it will also be told about any channels
 * that already existed before it started.
 *
 * For Observers that are activatable as a D-Bus service, if the
 * Observer exits or crashes while there are any channels that match
 * its filter, it will automatically be restarted by service-activation.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.observe_channels.
 *
 * Since: 0.11.5
 */
void
tp_base_client_set_observer_recover (TpBaseClient *self,
    gboolean recover)
{
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);
  g_return_if_fail (cls->observe_channels != NULL);

  if (recover)
    {
      self->priv->flags |= (CLIENT_IS_OBSERVER | CLIENT_OBSERVER_RECOVER);
    }
  else
    {
      self->priv->flags |= CLIENT_IS_OBSERVER;
      self->priv->flags &= ~CLIENT_OBSERVER_RECOVER;
    }
}

/**
 * tp_base_client_set_observer_delay_approvers:
 * @self: a #TpBaseClient
 * @delay: the value of the Observer.DelayApprovers property
 *
 * Set whether the channel dispatcher should wait for
 * tp_observe_channels_context_accept() or tp_observe_channels_context_fail()
 * to be called before calling
 * #TpBaseClientClass.add_dispatch_operation on appropriate Approvers.
 *
 * This is implemented by setting the value of the DelayApprovers
 * D-Bus property.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.observe_channels.
 *
 * Since: 0.13.16
 */
void
tp_base_client_set_observer_delay_approvers (TpBaseClient *self,
    gboolean delay)
{
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);
  g_return_if_fail (cls->observe_channels != NULL);

  if (delay)
    {
      self->priv->flags |= (CLIENT_IS_OBSERVER |
          CLIENT_OBSERVER_DELAYS_APPROVERS);
    }
  else
    {
      self->priv->flags |= CLIENT_IS_OBSERVER;
      self->priv->flags &= ~CLIENT_OBSERVER_DELAYS_APPROVERS;
    }
}

/**
 * tp_base_client_add_approver_filter:
 * @self: a #TpBaseClient
 * @filter: (transfer none) (element-type utf8 GObject.Value):
 * a %TP_HASH_TYPE_CHANNEL_CLASS
 *
 * Register a new channel class as Approver.ApproverChannelFilter.
 * The #TpBaseClientClass.add_dispatch_operation virtual method will be called
 * whenever a new channel's properties match the ones in @filter.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.add_dispatch_operation.
 *
 * Since: 0.11.5
 */
void
tp_base_client_add_approver_filter (TpBaseClient *self,
    GHashTable *filter)
{
  g_return_if_fail (filter != NULL);
  tp_base_client_take_approver_filter (self,
      _tp_base_client_copy_filter (filter));
}

/**
 * tp_base_client_take_approver_filter: (skip)
 * @self: a client
 * @filter: (transfer full) (element-type utf8 GObject.Value):
 * a %TP_HASH_TYPE_CHANNEL_CLASS, ownership of which is taken by @self
 *
 * The same as tp_base_client_add_approver_filter(), but ownership of @filter
 * is taken by @self. This makes it convenient to call using tp_asv_new():
 *
 * |[
 * tp_base_client_take_approver_filter (client,
 *    tp_asv_new (
 *        TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING,
 *            TP_IFACE_CHANNEL_TYPE_TEXT,
 *        TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, G_TYPE_UINT,
 *            TP_HANDLE_TYPE_CONTACT,
 *        ...));
 * ]|
 *
 * Since: 0.11.5
 */
void
tp_base_client_take_approver_filter (TpBaseClient *self,
    GHashTable *filter)
{
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);
  g_return_if_fail (cls->add_dispatch_operation != NULL);

  self->priv->flags |= CLIENT_IS_APPROVER;
  g_ptr_array_add (self->priv->approver_filters, filter);
}

/**
 * tp_base_client_add_approver_filter_vardict:
 * @self: a client
 * @filter: (transfer none): a variant of type %G_VARIANT_TYPE_VARDICT
 *
 * Register a new channel class as Approver.ApproverChannelFilter.
 * The #TpBaseClientClass.add_dispatch_operation virtual method will be called
 * whenever a new channel's properties match the ones in @filter.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.add_dispatch_operation.
 *
 * If the variant is floating (see g_variant_ref_sink()), ownership
 * will be taken. See tp_base_client_add_observer_filter_vardict() for
 * more details.
 *
 * Since: 0.19.10
 */
void
tp_base_client_add_approver_filter_vardict (TpBaseClient *self,
    GVariant *filter)
{
  g_return_if_fail (g_variant_is_of_type (filter, G_VARIANT_TYPE_VARDICT));

  g_variant_ref_sink (filter);
  tp_base_client_take_approver_filter (self, _tp_asv_from_vardict (filter));
  g_variant_unref (filter);
}

/**
 * tp_base_client_be_a_handler:
 * @self: a #TpBaseClient
 *
 * Register @self as a Client.Handler with an empty list of filters.
 * This is useful if you want to create a client that only handle channels
 * for which it's the PreferredHandler.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.handle_channels.
 *
 * Since: 0.11.6
 */
void
tp_base_client_be_a_handler (TpBaseClient *self)
{
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);
  g_return_if_fail (cls->handle_channels != NULL);

  self->priv->flags |= CLIENT_IS_HANDLER;
}

/**
 * tp_base_client_add_handler_filter:
 * @self: a #TpBaseClient
 * @filter: (transfer none) (element-type utf8 GObject.Value):
 * a %TP_HASH_TYPE_CHANNEL_CLASS
 *
 * Register a new channel class as Handler.HandlerChannelFilter.
 * The #TpBaseClientClass.handle_channels virtual method will be called
 * whenever a new channel's properties match the ones in @filter.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.handle_channels.
 *
 * Since: 0.11.6
 */
void
tp_base_client_add_handler_filter (TpBaseClient *self,
    GHashTable *filter)
{
  g_return_if_fail (filter != NULL);

  tp_base_client_take_handler_filter (self,
      _tp_base_client_copy_filter (filter));
}

/**
 * tp_base_client_take_handler_filter: (skip)
 * @self: a #TpBaseClient
 * @filter: (transfer full) (element-type utf8 GObject.Value):
 * a %TP_HASH_TYPE_CHANNEL_CLASS, ownership of which is taken by @self
 *
 * The same as tp_base_client_add_handler_filter(), but ownership of @filter
 * is taken by @self. This makes it convenient to call using tp_asv_new():
 *
 * |[
 * tp_base_client_take_handler_filter (client,
 *    tp_asv_new (
 *        TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING,
 *            TP_IFACE_CHANNEL_TYPE_TEXT,
 *        TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, G_TYPE_UINT,
 *            TP_HANDLE_TYPE_CONTACT,
 *        ...));
 * ]|
 *
 * Since: 0.11.6
 */
void
tp_base_client_take_handler_filter (TpBaseClient *self,
    GHashTable *filter)
{
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);
  g_return_if_fail (cls->handle_channels != NULL);

  self->priv->flags |= CLIENT_IS_HANDLER;
  g_ptr_array_add (self->priv->handler_filters, filter);
}

/**
 * tp_base_client_add_handler_filter_vardict:
 * @self: a client
 * @filter: (transfer none): a variant of type %G_VARIANT_TYPE_VARDICT
 *
 * Register a new channel class as Handler.HandlerChannelFilter.
 * The #TpBaseClientClass.handle_channels virtual method will be called
 * whenever a new channel's properties match the ones in @filter.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.handle_channels.
 *
 * If the variant is floating (see g_variant_ref_sink()), ownership
 * will be taken. See tp_base_client_add_observer_filter_vardict() for
 * more details.
 *
 * Since: 0.19.10
 */
void
tp_base_client_add_handler_filter_vardict (TpBaseClient *self,
    GVariant *filter)
{
  g_return_if_fail (g_variant_is_of_type (filter, G_VARIANT_TYPE_VARDICT));

  g_variant_ref_sink (filter);
  tp_base_client_take_handler_filter (self, _tp_asv_from_vardict (filter));
  g_variant_unref (filter);
}

/**
 * tp_base_client_set_handler_bypass_approval:
 * @self: a #TpBaseClient
 * @bypass_approval: the value of the Handler.BypassApproval property
 *
 * Set whether the channels destined for this handler are automatically
 * handled, without invoking approvers.
 * (This is implemented by setting the value of its BypassApproval
 * D-Bus property.)
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.handle_channels.
 *
 * Since: 0.11.6
 */
void
tp_base_client_set_handler_bypass_approval (TpBaseClient *self,
    gboolean bypass_approval)
{
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);
  g_return_if_fail (cls->handle_channels != NULL);

  if (bypass_approval)
    {
      self->priv->flags |= (CLIENT_IS_HANDLER |
          CLIENT_HANDLER_BYPASSES_APPROVAL);
    }
  else
    {
      self->priv->flags |= CLIENT_IS_HANDLER;
      self->priv->flags &= ~CLIENT_HANDLER_BYPASSES_APPROVAL;
    }
}

/**
 * tp_base_client_set_handler_request_notification:
 * @self: a #TpBaseClient
 *
 * Indicate that @self is a Handler willing to be notified about requests for
 * channels that it is likely to be asked to handle. This means that the
 * #TpBaseClient::request-added and #TpBaseClient::request-removed signals will
 * be fired and tp_base_client_get_pending_requests() will return the list of
 * pending requests.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.handle_channels.
 *
 * Since: 0.11.6
 */
void
tp_base_client_set_handler_request_notification (TpBaseClient *self)
{
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);
  g_return_if_fail (cls->handle_channels != NULL);

  self->priv->flags |= (CLIENT_IS_HANDLER | CLIENT_HANDLER_WANTS_REQUESTS);
}

static void
_tp_base_client_add_handler_capability (TpBaseClient *self,
    const gchar *token)
{
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);

  g_return_if_fail (cls->handle_channels != NULL);

  self->priv->flags |= CLIENT_IS_HANDLER;

  g_assert (g_ptr_array_index (self->priv->handler_caps,
        self->priv->handler_caps->len - 1) == NULL);
  g_ptr_array_index (self->priv->handler_caps,
      self->priv->handler_caps->len - 1) = g_strdup (token);
  g_ptr_array_add (self->priv->handler_caps, NULL);
}

/**
 * tp_base_client_add_handler_capability:
 * @self: a client, which must not have been registered with
 *  tp_base_client_register() yet
 * @token: a capability token as defined by the Telepathy D-Bus API
 *  Specification
 *
 * Add one capability token to this client, as if via
 * tp_base_client_add_handler_capabilities().
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.handle_channels.
 *
 * Since: 0.11.6
 */
void
tp_base_client_add_handler_capability (TpBaseClient *self,
    const gchar *token)
{
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);
  g_return_if_fail (cls->handle_channels != NULL);

  _tp_base_client_add_handler_capability (self, token);
}

/**
 * tp_base_client_add_handler_capabilities:
 * @self: a client, which must not have been registered with
 *  tp_base_client_register() yet
 * @tokens: (array zero-terminated=1) (element-type utf8): capability
 *  tokens as defined by the Telepathy D-Bus API Specification
 *
 * Add several capability tokens to this client. These are used to signal
 * that Telepathy connection managers should advertise certain capabilities
 * to other contacts, such as the ability to receive audio/video calls using
 * particular streaming protocols and codecs.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.handle_channels.
 *
 * Since: 0.11.6
 */
void
tp_base_client_add_handler_capabilities (TpBaseClient *self,
    const gchar * const *tokens)
{
  const gchar * const *iter;

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);

  if (tokens == NULL)
    return;

  for (iter = tokens; *iter != NULL; iter++)
    _tp_base_client_add_handler_capability (self, *iter);
}

/**
 * tp_base_client_add_handler_capabilities_varargs: (skip)
 * @self: a client, which must not have been registered with
 *  tp_base_client_register() yet
 * @first_token: a capability token from the Telepathy D-Bus API Specification
 * @...: more tokens, ending with %NULL
 *
 * Convenience C API equivalent to calling
 * tp_base_client_add_handler_capability() for each capability token.
 *
 * This method may only be called before tp_base_client_register() is
 * called, and may only be called on objects whose class implements
 * #TpBaseClientClass.handle_channels.
 *
 * Since: 0.11.6
 */
void
tp_base_client_add_handler_capabilities_varargs (TpBaseClient *self,
    const gchar *first_token, ...)
{
  va_list ap;
  const gchar *token;

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);

  va_start (ap, first_token);

  for (token = first_token; token != NULL; token = va_arg (ap, gchar *))
    _tp_base_client_add_handler_capability (self, token);

  va_end (ap);
}

/**
 * tp_base_client_register:
 * @self: a #TpBaseClient, which must not have been registered with
 *  tp_base_client_register() yet
 * @error: used to indicate the error if %FALSE is returned
 *
 * Publish @self as an available client. After this method is called, as long
 * as it continues to exist, it will receive and process whatever events were
 * requested via the various filters.
 *
 * Methods that set the filters and other immutable state, such as
 * tp_base_client_add_observer_filter(), cannot be called after this one.
 *
 * Returns: %TRUE if the client was registered successfully
 *
 * Since: 0.11.5
 */
gboolean
tp_base_client_register (TpBaseClient *self,
    GError **error)
{
  GHashTable *clients;

  g_return_val_if_fail (TP_IS_BASE_CLIENT (self), FALSE);
  g_return_val_if_fail (!self->priv->registered, FALSE);
  /* Client should at least be an Observer, Approver or Handler */
  g_return_val_if_fail (self->priv->flags != 0, FALSE);

  DEBUG ("request name %s", self->priv->bus_name);

  if (!tp_dbus_daemon_request_name (self->priv->dbus, self->priv->bus_name,
        TRUE, error))
    {
      DEBUG ("Failed to register bus name %s", self->priv->bus_name);
      return FALSE;
    }

  tp_dbus_daemon_register_object (self->priv->dbus, self->priv->object_path,
      G_OBJECT (self));

  self->priv->registered = TRUE;

  if (!(self->priv->flags & CLIENT_IS_HANDLER))
    return TRUE;

  /* Client is an handler */
  self->priv->libdbus = dbus_connection_ref (
      dbus_g_connection_get_connection (
        tp_proxy_get_dbus_connection (self->priv->dbus)));

  /* one ref per TpBaseClient with CLIENT_IS_HANDLER, released
   * in tp_base_client_unregister() */
  if (!dbus_connection_allocate_data_slot (&clients_slot))
    ERROR ("Out of memory");

  clients = dbus_connection_get_data (self->priv->libdbus, clients_slot);

  if (clients == NULL)
    {
      /* Map DBusConnection to the self->priv->my_chans hash table owned by
       * the client using this DBusConnection.

       * borrowed client path => borrowed (GHashTable *) */
      clients = g_hash_table_new (g_str_hash, g_str_equal);

      dbus_connection_set_data (self->priv->libdbus, clients_slot, clients,
          (DBusFreeFunction) g_hash_table_unref);
    }

  g_hash_table_insert (clients, self->priv->object_path, self->priv->my_chans);

  return TRUE;
}

/**
 * tp_base_client_get_pending_requests:
 * @self: a #TpBaseClient
 *
 * Only works if tp_base_client_set_handler_request_notification() has been
 * called.
 * Returns the list of requests @self is likely be asked to handle.
 *
 * Returns: (transfer container) (element-type TelepathyGLib.ChannelRequest): a
 * #GList of #TpChannelRequest
 *
 * Since: 0.11.6
 * Deprecated: Since 0.19.9. New code should use
 *  tp_base_client_dup_pending_requests() instead.
 */
GList *
tp_base_client_get_pending_requests (TpBaseClient *self)
{
  g_return_val_if_fail (self->priv->flags & CLIENT_IS_HANDLER, NULL);

  return g_list_copy (self->priv->pending_requests);
}

/**
 * tp_base_client_get_handled_channels:
 * @self: a #TpBaseClient
 *
 * Returns the set of channels currently handled by this base client or by any
 * other #TpBaseClient with which it shares a unique name.
 *
 * Returns: (transfer container) (element-type TelepathyGLib.Channel): the
 * handled channels
 *
 * Since: 0.11.6
 * Deprecated: Since 0.19.9. New code should use
 *  tp_base_client_dup_handled_channels() instead.
 */
GList *
tp_base_client_get_handled_channels (TpBaseClient *self)
{
  GList *result = NULL;
  GHashTable *clients;
  GHashTableIter iter;
  gpointer value;
  GHashTable *set;

  g_return_val_if_fail (self->priv->flags & CLIENT_IS_HANDLER, NULL);

  if (clients_slot == -1)
    return NULL;

  set = g_hash_table_new (g_str_hash, g_str_equal);

  clients = dbus_connection_get_data (self->priv->libdbus, clients_slot);

  g_hash_table_iter_init (&iter, clients);
  while (g_hash_table_iter_next (&iter, NULL, &value))
    {
      GHashTable *chans = value;

      tp_g_hash_table_update (set, chans, NULL, NULL);
    }

  result = g_hash_table_get_values (set);
  g_hash_table_unref (set);

  return result;
}

/**
 * tp_base_client_dup_pending_requests:
 * @self: a #TpBaseClient
 *
 * Only works if tp_base_client_set_handler_request_notification() has been
 * called.
 * Returns the list of requests @self is likely be asked to handle.
 *
 * Returns: (transfer full) (element-type TelepathyGLib.ChannelRequest): a
 * #GList of #TpChannelRequest
 *
 * Since: 0.19.9
 */
GList *
tp_base_client_dup_pending_requests (TpBaseClient *self)
{
  g_return_val_if_fail (self->priv->flags & CLIENT_IS_HANDLER, NULL);

  return _tp_g_list_copy_deep (self->priv->pending_requests,
      (GCopyFunc) g_object_ref, NULL);
}

/**
 * tp_base_client_dup_handled_channels:
 * @self: a #TpBaseClient
 *
 * Returns the set of channels currently handled by this base client or by any
 * other #TpBaseClient with which it shares a unique name.
 *
 * Returns: (transfer full) (element-type TelepathyGLib.Channel): the
 * handled channels
 *
 * Since: 0.19.9
 */
GList *
tp_base_client_dup_handled_channels (TpBaseClient *self)
{
  GList *ret;

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  ret = tp_base_client_get_handled_channels (self);
  G_GNUC_END_IGNORE_DEPRECATIONS
  g_list_foreach (ret, (GFunc) g_object_ref, NULL);

  return ret;
}

static void
tp_base_client_init (TpBaseClient *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_BASE_CLIENT,
      TpBaseClientPrivate);

  /* wild guess: most clients won't need more than one of each filter */
  self->priv->observer_filters = g_ptr_array_new_with_free_func (
      (GDestroyNotify) g_hash_table_unref);
  self->priv->approver_filters = g_ptr_array_new_with_free_func (
      (GDestroyNotify) g_hash_table_unref);
  self->priv->handler_filters = g_ptr_array_new_with_free_func (
      (GDestroyNotify) g_hash_table_unref);
  self->priv->handler_caps = g_ptr_array_new_with_free_func (g_free);
  g_ptr_array_add (self->priv->handler_caps, NULL);

  self->priv->my_chans = g_hash_table_new_full (g_str_hash, g_str_equal,
      NULL, g_object_unref);

  self->priv->account_features = g_array_new (TRUE, FALSE, sizeof (GQuark));
  self->priv->connection_features = g_array_new (TRUE, FALSE, sizeof (GQuark));
  self->priv->channel_features = g_array_new (TRUE, FALSE, sizeof (GQuark));
}

static void
tp_base_client_dispose (GObject *object)
{
  TpBaseClient *self = TP_BASE_CLIENT (object);
  void (*dispose) (GObject *) =
    G_OBJECT_CLASS (tp_base_client_parent_class)->dispose;

  tp_base_client_unregister (self);

  tp_clear_object (&self->priv->dbus);
  tp_clear_object (&self->priv->account_mgr);
  tp_clear_object (&self->priv->factory);
  tp_clear_object (&self->priv->only_for_account);
  tp_clear_object (&self->priv->channel_factory);

  g_list_free_full (self->priv->pending_requests, g_object_unref);
  self->priv->pending_requests = NULL;

  if (self->priv->my_chans != NULL &&
      g_hash_table_size (self->priv->my_chans) > 0)
    WARNING ("TpBaseClient is still handling %d channels at dispose",
        g_hash_table_size (self->priv->my_chans));

  tp_clear_pointer (&self->priv->my_chans, g_hash_table_unref);

  if (self->priv->delegated_channels_destroy != NULL)
    {
      self->priv->delegated_channels_destroy (
          self->priv->delegated_channels_data);
      self->priv->delegated_channels_destroy = NULL;
    }

  if (dispose != NULL)
    dispose (object);
}

static void
tp_base_client_finalize (GObject *object)
{
  TpBaseClient *self = TP_BASE_CLIENT (object);
  void (*finalize) (GObject *) =
    G_OBJECT_CLASS (tp_base_client_parent_class)->finalize;

  g_free (self->priv->name);

  g_ptr_array_unref (self->priv->observer_filters);
  g_ptr_array_unref (self->priv->approver_filters);
  g_ptr_array_unref (self->priv->handler_filters);
  g_ptr_array_unref (self->priv->handler_caps);

  g_free (self->priv->bus_name);
  g_free (self->priv->object_path);

  tp_clear_pointer (&self->priv->account_features, g_array_unref);
  tp_clear_pointer (&self->priv->connection_features, g_array_unref);
  tp_clear_pointer (&self->priv->channel_features, g_array_unref);

  if (finalize != NULL)
    finalize (object);
}

static void
tp_base_client_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpBaseClient *self = TP_BASE_CLIENT (object);

  switch (property_id)
    {
      case PROP_DBUS_DAEMON:
        g_value_set_object (value, self->priv->dbus);
        break;

      case PROP_ACCOUNT_MANAGER:
        g_value_set_object (value, self->priv->account_mgr);
        break;

      case PROP_FACTORY:
        g_value_set_object (value, self->priv->factory);
        break;

      case PROP_NAME:
        g_value_set_string (value, self->priv->name);
        break;

      case PROP_UNIQUIFY_NAME:
        g_value_set_boolean (value, self->priv->uniquify_name);
        break;

      case PROP_CHANNEL_FACTORY:
        g_value_set_object (value, self->priv->channel_factory);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_base_client_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpBaseClient *self = TP_BASE_CLIENT (object);

  switch (property_id)
    {
      case PROP_DBUS_DAEMON:
        g_assert (self->priv->dbus == NULL);    /* construct-only */
        self->priv->dbus = g_value_dup_object (value);
        break;

      case PROP_ACCOUNT_MANAGER:
        g_assert (self->priv->account_mgr == NULL); /* construct-only */
        self->priv->account_mgr = g_value_dup_object (value);
        break;

      case PROP_FACTORY:
        g_assert (self->priv->factory == NULL); /* construct-only */
        self->priv->factory = g_value_dup_object (value);
        break;

      case PROP_NAME:
        g_assert (self->priv->name == NULL);    /* construct-only */
        self->priv->name = g_value_dup_string (value);
        break;

      case PROP_UNIQUIFY_NAME:
        self->priv->uniquify_name = g_value_get_boolean (value);
        break;

      case PROP_CHANNEL_FACTORY:
        g_assert (self->priv->channel_factory == NULL);    /* construct-only */
        self->priv->channel_factory = g_value_dup_object (value);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_base_client_constructed (GObject *object)
{
  TpBaseClient *self = TP_BASE_CLIENT (object);
  void (*chain_up) (GObject *) =
    ((GObjectClass *) tp_base_client_parent_class)->constructed;
  GString *string;
  static guint unique_counter = 0;

  if (chain_up != NULL)
    chain_up (object);

  /* What we really need is a factory. For historical reasons,
   * constructor could get a TpDBusDaemon or a TpAccountManager.
   * We need to do some fallbacks for compatibility... */
  if (self->priv->account_mgr == NULL &&
      self->priv->factory == NULL)
    {
      /* This case happens only from deprecated API, for compatibility we still
       * need to create a TpAccountManager even if a factory would be enough */

      g_assert (self->priv->dbus != NULL);

      if (_tp_dbus_daemon_is_the_shared_one (self->priv->dbus))
        {
          /* The AM is guaranteed to be the one from
           * tp_account_manager_dup() */
          self->priv->account_mgr = tp_account_manager_dup ();
        }
      else
        {
          /* No guarantee, create a new AM */
          self->priv->account_mgr = tp_account_manager_new (self->priv->dbus);
        }
    }

  if (self->priv->factory == NULL)
    {
      g_assert (self->priv->account_mgr != NULL);

      self->priv->factory = tp_proxy_get_factory (self->priv->account_mgr);
      g_object_ref (self->priv->factory);
    }

  if (self->priv->dbus == NULL)
    {
      g_assert (self->priv->factory != NULL);

      self->priv->dbus = tp_simple_client_factory_get_dbus_daemon (
          self->priv->factory);
      g_object_ref (self->priv->dbus);
    }

  g_assert (tp_simple_client_factory_get_dbus_daemon (self->priv->factory) ==
      self->priv->dbus);

  /* Bus name */
  g_assert (self->priv->name != NULL);
  string = g_string_new (TP_CLIENT_BUS_NAME_BASE);
  g_string_append (string, self->priv->name);

  if (self->priv->uniquify_name)
    {
      gchar *unique;

      unique = tp_escape_as_identifier (tp_dbus_daemon_get_unique_name (
            self->priv->dbus));

      g_string_append_printf (string, ".%s.n%u", unique, unique_counter++);
      g_free (unique);
    }

  /* Object path */
  self->priv->object_path = g_strdup_printf ("/%s", string->str);
  g_strdelimit (self->priv->object_path, ".", '/');

  self->priv->bus_name = g_string_free (string, FALSE);
}

typedef enum {
    DP_INTERFACES,
    DP_APPROVER_CHANNEL_FILTER,
    DP_HANDLER_CHANNEL_FILTER,
    DP_BYPASS_APPROVAL,
    DP_CAPABILITIES,
    DP_HANDLED_CHANNELS,
    DP_OBSERVER_CHANNEL_FILTER,
    DP_OBSERVER_RECOVER,
    DP_OBSERVER_DELAY_APPROVERS,
} ClientDBusProp;

static void
tp_base_client_get_dbus_properties (GObject *object,
    GQuark iface,
    GQuark name,
    GValue *value,
    gpointer getter_data)
{
  TpBaseClient *self = TP_BASE_CLIENT (object);
  ClientDBusProp which = GPOINTER_TO_INT (getter_data);

  switch (which)
    {
    case DP_INTERFACES:
        {
          GPtrArray *arr = g_ptr_array_sized_new (5);

          if (self->priv->flags & CLIENT_IS_OBSERVER)
            g_ptr_array_add (arr, g_strdup (TP_IFACE_CLIENT_OBSERVER));

          if (self->priv->flags & CLIENT_IS_APPROVER)
            g_ptr_array_add (arr, g_strdup (TP_IFACE_CLIENT_APPROVER));

          if (self->priv->flags & CLIENT_IS_HANDLER)
            g_ptr_array_add (arr, g_strdup (TP_IFACE_CLIENT_HANDLER));

          if (self->priv->flags & CLIENT_HANDLER_WANTS_REQUESTS)
            g_ptr_array_add (arr, g_strdup (
                  TP_IFACE_CLIENT_INTERFACE_REQUESTS));

          g_ptr_array_add (arr, NULL);
          g_value_take_boxed (value, g_ptr_array_free (arr, FALSE));
        }
      break;

    case DP_OBSERVER_CHANNEL_FILTER:
      g_value_set_boxed (value, self->priv->observer_filters);
      break;

    case DP_APPROVER_CHANNEL_FILTER:
      g_value_set_boxed (value, self->priv->approver_filters);
      break;

    case DP_HANDLER_CHANNEL_FILTER:
      g_value_set_boxed (value, self->priv->handler_filters);
      break;

    case DP_BYPASS_APPROVAL:
      g_value_set_boolean (value,
          (self->priv->flags & CLIENT_HANDLER_BYPASSES_APPROVAL) != 0);
      break;

    case DP_CAPABILITIES:
      /* this is already NULL-terminated */
      g_value_set_boxed (value, (GStrv) self->priv->handler_caps->pdata);
      break;

    case DP_HANDLED_CHANNELS:
        {
          GList *channels = tp_base_client_dup_handled_channels (self);
          GList *iter;
          GPtrArray *arr = g_ptr_array_sized_new (g_list_length (channels));

          for (iter = channels; iter != NULL; iter = iter->next)
            g_ptr_array_add (arr,
                g_strdup (tp_proxy_get_object_path (iter->data)));

          g_value_take_boxed (value, arr);
          g_list_free_full (channels, g_object_unref);
        }
      break;

    case DP_OBSERVER_RECOVER:
      g_value_set_boolean (value,
          (self->priv->flags & CLIENT_OBSERVER_RECOVER) != 0);
      break;

    case DP_OBSERVER_DELAY_APPROVERS:
      g_value_set_boolean (value,
          (self->priv->flags & CLIENT_OBSERVER_DELAYS_APPROVERS) != 0);
      break;

    default:
      g_assert_not_reached ();
    }
}

static void
tp_base_client_class_init (TpBaseClientClass *cls)
{
  GParamSpec *param_spec;
  static TpDBusPropertiesMixinPropImpl client_properties[] = {
        { "Interfaces", GINT_TO_POINTER (DP_INTERFACES) },
        { NULL }
  };
  static TpDBusPropertiesMixinPropImpl handler_properties[] = {
        { "HandlerChannelFilter",
          GINT_TO_POINTER (DP_HANDLER_CHANNEL_FILTER) },
        { "BypassApproval",
          GINT_TO_POINTER (DP_BYPASS_APPROVAL) },
        { "Capabilities",
          GINT_TO_POINTER (DP_CAPABILITIES) },
        { "HandledChannels",
          GINT_TO_POINTER (DP_HANDLED_CHANNELS) },
        { NULL }
  };
  static TpDBusPropertiesMixinPropImpl approver_properties[] = {
        { "ApproverChannelFilter",
          GINT_TO_POINTER (DP_APPROVER_CHANNEL_FILTER) },
        { NULL }
  };
  static TpDBusPropertiesMixinPropImpl observer_properties[] = {
        { "ObserverChannelFilter",
          GINT_TO_POINTER (DP_OBSERVER_CHANNEL_FILTER) },
        { "Recover",
          GINT_TO_POINTER (DP_OBSERVER_RECOVER) },
        { "DelayApprovers",
          GINT_TO_POINTER (DP_OBSERVER_DELAY_APPROVERS) },
        { NULL }
  };
  static TpDBusPropertiesMixinIfaceImpl prop_ifaces[] = {
        { TP_IFACE_CLIENT, tp_base_client_get_dbus_properties, NULL,
          client_properties },
        { TP_IFACE_CLIENT_OBSERVER, tp_base_client_get_dbus_properties, NULL,
          observer_properties },
        { TP_IFACE_CLIENT_APPROVER, tp_base_client_get_dbus_properties, NULL,
          approver_properties },
        { TP_IFACE_CLIENT_HANDLER, tp_base_client_get_dbus_properties, NULL,
          handler_properties },
        { NULL }
  };
  GObjectClass *object_class = G_OBJECT_CLASS (cls);

  g_type_class_add_private (cls, sizeof (TpBaseClientPrivate));

  object_class->get_property = tp_base_client_get_property;
  object_class->set_property = tp_base_client_set_property;
  object_class->constructed = tp_base_client_constructed;
  object_class->dispose = tp_base_client_dispose;
  object_class->finalize = tp_base_client_finalize;

  /**
   * TpBaseClient:dbus-daemon:
   *
   * #TpDBusDaemon object encapsulating this object's connection to D-Bus.
   * Read-only except during construction.
   *
   * This property can't be %NULL after construction.
   *
   * Since 0.11.14 this property may be %NULL or unspecified in
   * g_object_new(), but only if #TpBaseClient:account-manager is provided
   * instead, in which case its #TpProxy:dbus-daemon property will be
   * used.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_object ("dbus-daemon", "TpDBusDaemon object",
      "The dbus daemon associated with this client",
      TP_TYPE_DBUS_DAEMON,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DBUS_DAEMON, param_spec);

  /**
   * TpBaseClient:account-manager:
   *
   * Account manager for this base client, used to look up or create
   * #TpAccount objects. This may be specified in the constructor in order
   * to get existing #TpAccount objects.
   *
   * It is not guaranteed that any of its features have been prepared, and
   * it is not necessary to wait for any features before specifying this
   * property in the constructor.
   *
   * Clients that interact with the #TpAccount should usually
   * set this property instead of #TpBaseClient:dbus-daemon. Doing this
   * will ensure that each account, connection or contact is represented by
   * a single #TpAccount, #TpConnection or #TpContact object, shared between
   * all the cooperating modules that have the same #TpAccountManager.
   *
   * If the #TpBaseClient:dbus-daemon is set to the result of
   * tp_dbus_daemon_dup(), then this property defaults to
   * the result of tp_account_manager_dup().
   *
   * This property may be %NULL initially, but will always be non-%NULL
   * after the #TpBaseClient has been constructed.
   *
   * It is an error to specify both a non-%NULL account manager, and a
   * non-%NULL #TpBaseClient:dbus-daemon that is not the same as the
   * account manager's #TpProxy:dbus-daemon.
   *
   * Since: 0.11.14
   * Deprecated: New code should not use this property, it may be %NULL in
   *  the case @self was constructed with a #TpSimpleClientFactory.
   */
  param_spec = g_param_spec_object ("account-manager", "TpAccountManager",
      "The TpAccountManager used look up or create TpAccount objects",
      TP_TYPE_ACCOUNT_MANAGER,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ACCOUNT_MANAGER,
      param_spec);

  /**
   * TpBaseClient:factory:
   *
   * Factory for this base client, used to look up or create
   * #TpAccount objects.
   *
   * Since: 0.15.5
   */
  param_spec = g_param_spec_object ("factory", "TpSimpleClientFactory",
      "The TpSimpleClientFactory used look up or create TpAccount objects",
      TP_TYPE_SIMPLE_CLIENT_FACTORY,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_FACTORY,
      param_spec);

  /**
   * TpBaseClient:name:
   *
   * The name of the client. This is used to register the D-Bus service name
   * and object path of the service.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.5
   */
 param_spec = g_param_spec_string ("name", "name",
      "The name of the client",
      NULL,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_NAME, param_spec);

  /**
   * TpBaseClient:uniquify-name:
   *
   * If %TRUE, tp_base_client_register() will append an unique token to the
   * service bus name and object path to ensure they are unique.
   *
   * Since: 0.11.5
   */
 param_spec = g_param_spec_boolean ("uniquify-name", "Uniquify name",
      "if TRUE, append a unique token to the name",
      FALSE,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_UNIQUIFY_NAME,
      param_spec);

  /**
   * TpBaseClient:channel-factory:
   *
   * The object implementing the #TpClientChannelFactoryInterface interface
   * that will be used to create channel proxies. While
   * tp_base_client_register() has not yet been called, this property can be
   * changed using tp_base_client_set_channel_factory().
   *
   * If no channel factory is specified then #TpAutomaticProxyFactory is used.
   *
   * Since: 0.13.2
   * Deprecated: since 0.15.5. The factory is taken from
   *  #TpBaseClient:account-manager.
   */
  param_spec = g_param_spec_object ("channel-factory", "Channel factory",
      "Object implementing TpClientChannelFactoryInterface",
      G_TYPE_OBJECT,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CHANNEL_FACTORY,
      param_spec);

 /**
   * TpBaseClient::request-added:
   * @self: a #TpBaseClient
   * @account: the #TpAccount on which the request was made,
   *  with %TP_ACCOUNT_FEATURE_CORE, and any other features added via
   *  tp_base_client_add_account_features() or
   *  tp_simple_client_factory_add_account_features(), prepared if possible
   * @request: a #TpChannelRequest having its object-path defined but
   * is not guaranteed to be prepared.
   *
   * Emitted when a channels have been requested, and that if the
   * request is successful, they will probably be handled by this Handler.
   *
   * This signal is only fired if
   * tp_base_client_set_handler_request_notification() has been called
   * on @self previously.
   *
   * Since: 0.11.6
   */
  signals[SIGNAL_REQUEST_ADDED] = g_signal_new (
      "request-added", G_OBJECT_CLASS_TYPE (cls),
      G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 2,
      TP_TYPE_ACCOUNT, TP_TYPE_CHANNEL_REQUEST);

 /**
   * TpBaseClient::request-removed:
   * @self: a #TpBaseClient
   * @request: the #TpChannelRequest being removed
   * @error: the name of the D-Bus error with which the request failed.
   * @message: any message supplied with the D-Bus error.
   *
   * Emitted when a request has failed and should be disregarded.
   *
   * This signal is only fired if
   * tp_base_client_set_handler_request_notification() has been called
   * on @self previously.
   *
   * Since: 0.11.6
   */
  signals[SIGNAL_REQUEST_REMOVED] = g_signal_new (
      "request-removed", G_OBJECT_CLASS_TYPE (cls),
      G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 3,
      TP_TYPE_CHANNEL_REQUEST, G_TYPE_STRING, G_TYPE_STRING);

  cls->dbus_properties_class.interfaces = prop_ifaces;
  tp_dbus_properties_mixin_class_init (object_class,
      G_STRUCT_OFFSET (TpBaseClientClass, dbus_properties_class));
}

static GList *
ptr_array_to_list (GPtrArray *arr)
{
  guint i;
  GList *result = NULL;

  for (i = 0; i < arr->len; i++)
    result = g_list_prepend (result, g_ptr_array_index (arr, i));

  return g_list_reverse (result);
}

static void
context_prepare_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpBaseClient *self = user_data;
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);
  TpObserveChannelsContext *ctx = TP_OBSERVE_CHANNELS_CONTEXT (source);
  GError *error = NULL;
  GList *channels_list, *requests_list;

  if (!_tp_observe_channels_context_prepare_finish (ctx, result, &error))
    {
      DEBUG ("Failed to prepare TpObserveChannelsContext: %s", error->message);
      tp_observe_channels_context_fail (ctx, error);
      g_error_free (error);
      return;
    }

  channels_list = ptr_array_to_list (ctx->channels);
  requests_list = ptr_array_to_list (ctx->requests);

  cls->observe_channels (self, ctx->account, ctx->connection,
      channels_list, ctx->dispatch_operation, requests_list, ctx);

  g_list_free (channels_list);
  g_list_free (requests_list);

  if (_tp_observe_channels_context_get_state (ctx) ==
      TP_OBSERVE_CHANNELS_CONTEXT_STATE_NONE)
    {
      error = g_error_new (TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
          "Implementation of ObserveChannels in %s didn't call "
          "tp_observe_channels_context_{accept,fail,delay}",
          G_OBJECT_TYPE_NAME (self));

      CRITICAL ("%s", error->message);

      tp_observe_channels_context_fail (ctx, error);
      g_error_free (error);
    }
}

static GArray *
dup_features_for_account (TpBaseClient *self,
    TpAccount *account)
{
  GArray *features;

  features = tp_simple_client_factory_dup_account_features (self->priv->factory,
      account);

  g_assert (features != NULL);

  /* Deprecated - Merge features set on self instead of factory */
  _tp_quark_array_merge (features,
      (GQuark *) self->priv->account_features->data,
      self->priv->account_features->len);

  return features;
}

static GArray *
dup_features_for_connection (TpBaseClient *self,
    TpConnection *connection)
{
  GArray *features;

  features = tp_simple_client_factory_dup_connection_features (
      self->priv->factory, connection);

  g_assert (features != NULL);

  /* Deprecated - Merge features set on self instead of factory */
  _tp_quark_array_merge (features,
      (GQuark *) self->priv->connection_features->data,
      self->priv->connection_features->len);

  return features;
}

static GArray *
dup_features_for_channel (TpBaseClient *self,
    TpChannel *channel)
{
  GArray *features;

  /* Use legacy channel factory if one is set */
  if (self->priv->channel_factory != NULL)
    features = tp_client_channel_factory_dup_channel_features (
        self->priv->channel_factory, channel);
  else
    features = tp_simple_client_factory_dup_channel_features (
        self->priv->factory, channel);

  g_assert (features != NULL);

  /* Deprecated - Merge features set on self instead of factory */
  _tp_quark_array_merge (features,
      (GQuark *) self->priv->channel_features->data,
      self->priv->channel_features->len);

  return features;
}

static TpChannel *
ensure_account_connection_channels (TpBaseClient *self,
    const gchar *account_path,
    const gchar *connection_path,
    const GPtrArray *channels_arr,
    TpAccount **account,
    TpConnection **connection,
    GPtrArray **channels,
    GError **error)
{
  TpChannel *channel = NULL;
  guint i;

  g_assert (account != NULL);
  g_assert (connection != NULL);
  g_assert (channels != NULL);

  *account = NULL;
  *connection = NULL;
  *channels = NULL;

  *account = tp_base_client_dup_account (self, account_path, error);
  if (*account == NULL)
    goto error;

  *connection = tp_simple_client_factory_ensure_connection (self->priv->factory,
      connection_path, NULL, error);
  if (*connection == NULL)
    goto error;

  /* fdo#51444: Custom TpChannel subclasses constructors may assume that the
   * Connection already knows its Account. If we don't do it here, it will be
   * done only when TP_ACCOUNT_FEATURE_CORE gets prepared on the Account. */
  _tp_connection_set_account (*connection, *account);

  if (channels_arr->len == 0)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Channels should contain at least one channel");
      goto error;
    }

  *channels = g_ptr_array_new_full (channels_arr->len, g_object_unref);
  for (i = 0; i < channels_arr->len; i++)
    {
      const gchar *chan_path;
      GHashTable *chan_props;

      tp_value_array_unpack (g_ptr_array_index (channels_arr, i), 2,
          &chan_path, &chan_props);

      /* Use legacy channel factory if one is set */
      if (self->priv->channel_factory != NULL)
        {
          channel = tp_client_channel_factory_create_channel (
              self->priv->channel_factory, *connection, chan_path, chan_props,
              error);
        }
      else
        {
          channel = tp_simple_client_factory_ensure_channel (
              self->priv->factory, *connection, chan_path, chan_props, error);
        }

      if (channel == NULL)
        goto error;

      g_ptr_array_add (*channels, channel);
    }

  /* FIXME: We will consider features set only for the last channel. This is
   * wrong in the case we receive multiple channels of different types.
   * It has always been like that, and multiple channel dispatch is being
   * deprecated. So let's just live with it. */
  return channel;

error:
  g_clear_object (account);
  g_clear_object (connection);
  tp_clear_pointer (channels, g_ptr_array_unref);

  return NULL;
}

static void
_tp_base_client_observe_channels (TpSvcClientObserver *iface,
    const gchar *account_path,
    const gchar *connection_path,
    const GPtrArray *channels_arr,
    const gchar *dispatch_operation_path,
    const GPtrArray *requests_arr,
    GHashTable *observer_info,
    DBusGMethodInvocation *context)
{
  TpBaseClient *self = TP_BASE_CLIENT (iface);
  TpObserveChannelsContext *ctx;
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);
  GError *error = NULL;
  TpAccount *account = NULL;
  TpConnection *connection = NULL;
  GPtrArray *channels = NULL, *requests = NULL;
  TpChannelDispatchOperation *dispatch_operation = NULL;
  guint i;
  TpChannel *channel = NULL;
  GArray *account_features;
  GArray *connection_features;
  GArray *channel_features;
  GHashTable *request_props;

  if (!(self->priv->flags & CLIENT_IS_OBSERVER))
    {
      /* Pretend that the method is not implemented if we are not supposed to
       * be an Observer. */
      tp_dbus_g_method_return_not_implemented (context);
      return;
    }

  if (cls->observe_channels == NULL)
    {
      WARNING ("class %s does not implement ObserveChannels",
          G_OBJECT_TYPE_NAME (self));

      tp_dbus_g_method_return_not_implemented (context);
      return;
    }

  channel = ensure_account_connection_channels (self, account_path,
      connection_path, channels_arr, &account, &connection, &channels, &error);
  if (channel == NULL)
    goto out;

  if (!tp_strdiff (dispatch_operation_path, "/"))
    {
      dispatch_operation = NULL;
    }
  else
    {
      dispatch_operation =
          _tp_simple_client_factory_ensure_channel_dispatch_operation (
              self->priv->factory, dispatch_operation_path, NULL, &error);
     if (dispatch_operation == NULL)
       {
         DEBUG ("Failed to create TpChannelDispatchOperation: %s",
             error->message);
         goto out;
        }
    }

  requests = g_ptr_array_new_full (requests_arr->len, g_object_unref);
  request_props = tp_asv_get_boxed (observer_info, "request-properties",
    TP_HASH_TYPE_OBJECT_IMMUTABLE_PROPERTIES_MAP);
  for (i = 0; i < requests_arr->len; i++)
    {
      const gchar *req_path = g_ptr_array_index (requests_arr, i);
      TpChannelRequest *request;
      GHashTable *props = NULL;

      if (request_props != NULL)
        props = g_hash_table_lookup (request_props, req_path);

      request = _tp_simple_client_factory_ensure_channel_request (
          self->priv->factory, req_path, props, &error);
      if (request == NULL)
        {
          DEBUG ("Failed to create TpChannelRequest: %s", error->message);
          goto out;
        }

      g_ptr_array_add (requests, request);
    }

  ctx = _tp_observe_channels_context_new (account, connection, channels,
      dispatch_operation, requests, observer_info, context);

  account_features = dup_features_for_account (self, account);
  connection_features = dup_features_for_connection (self, connection);
  channel_features = dup_features_for_channel (self, channel);

  _tp_observe_channels_context_prepare_async (ctx,
      (GQuark *) account_features->data,
      (GQuark *) connection_features->data,
      (GQuark *) channel_features->data,
      context_prepare_cb, self);

  g_object_unref (ctx);
  g_array_unref (account_features);
  g_array_unref (connection_features);
  g_array_unref (channel_features);

out:
  g_clear_object (&account);
  g_clear_object (&connection);

  if (channels != NULL)
    g_ptr_array_unref (channels);

  if (dispatch_operation != NULL)
    g_object_unref (dispatch_operation);

  if (requests != NULL)
    g_ptr_array_unref (requests);

  if (error == NULL)
    return;

  dbus_g_method_return_error (context, error);
  g_error_free (error);
}

static void
observer_iface_init (gpointer g_iface,
    gpointer unused G_GNUC_UNUSED)
{
#define IMPLEMENT(x) tp_svc_client_observer_implement_##x (\
  g_iface, _tp_base_client_##x)
  IMPLEMENT (observe_channels);
#undef IMPLEMENT
}

static void
add_dispatch_context_prepare_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpBaseClient *self = user_data;
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);
  TpAddDispatchOperationContext *ctx = TP_ADD_DISPATCH_OPERATION_CONTEXT (
      source);
  GError *error = NULL;
  GList *channels_list;

  if (!_tp_add_dispatch_operation_context_prepare_finish (ctx, result, &error))
    {
      DEBUG ("Failed to prepare TpAddDispatchOperationContext: %s",
          error->message);

      tp_add_dispatch_operation_context_fail (ctx, error);

      g_error_free (error);
      return;
    }

  channels_list = ptr_array_to_list (ctx->channels);

  cls->add_dispatch_operation (self, ctx->account, ctx->connection,
      channels_list, ctx->dispatch_operation, ctx);

  g_list_free (channels_list);

  if (_tp_add_dispatch_operation_context_get_state (ctx) ==
      TP_ADD_DISPATCH_OPERATION_CONTEXT_STATE_NONE)
    {
      error = g_error_new (TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
          "Implementation of AddDispatchOperation in %s didn't call "
          "tp_add_dispatch_operation_context_{accept,fail,delay}",
          G_OBJECT_TYPE_NAME (self));

      g_critical ("%s", error->message);

      tp_add_dispatch_operation_context_fail (ctx, error);
      g_error_free (error);
    }
}

static void
_tp_base_client_add_dispatch_operation (TpSvcClientApprover *iface,
    const GPtrArray *channels_arr,
    const gchar *dispatch_operation_path,
    GHashTable *properties,
    DBusGMethodInvocation *context)
{
  TpBaseClient *self = TP_BASE_CLIENT (iface);
  TpAddDispatchOperationContext *ctx;
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);
  const gchar *account_path;
  const gchar *connection_path;
  GError *error = NULL;
  TpAccount *account = NULL;
  TpConnection *connection = NULL;
  GPtrArray *channels = NULL;
  TpChannelDispatchOperation *dispatch_operation = NULL;
  TpChannel *channel = NULL;
  GArray *account_features;
  GArray *connection_features;
  GArray *channel_features;

  if (!(self->priv->flags & CLIENT_IS_APPROVER))
    {
      /* Pretend that the method is not implemented if we are not supposed to
       * be an Approver. */
      tp_dbus_g_method_return_not_implemented (context);
      return;
    }

  if (cls->add_dispatch_operation == NULL)
    {
      WARNING ("class %s does not implement AddDispatchOperation",
          G_OBJECT_TYPE_NAME (self));

      tp_dbus_g_method_return_not_implemented (context);
      return;
    }

  account_path = tp_asv_get_object_path (properties,
      TP_PROP_CHANNEL_DISPATCH_OPERATION_ACCOUNT);
  if (account_path == NULL)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Properties doesn't contain 'Account'");
      DEBUG ("%s", error->message);
      goto out;
    }

  connection_path = tp_asv_get_object_path (properties,
      TP_PROP_CHANNEL_DISPATCH_OPERATION_CONNECTION);
  if (connection_path == NULL)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Properties doesn't contain 'Connection'");
      DEBUG ("%s", error->message);
      goto out;
    }

  channel = ensure_account_connection_channels (self, account_path,
      connection_path, channels_arr, &account, &connection, &channels, &error);
  if (channel == NULL)
    goto out;

  /* FIXME: We will consider features set only for the first channel. This is
   * wrong in the case we receive multiple channels of different types.
   * It has always been like that, and multiple channel dispatch is being
   * deprecated. So let's just live with it. */
  channel = g_ptr_array_index (channels, 0);

  dispatch_operation =
      _tp_simple_client_factory_ensure_channel_dispatch_operation (
          self->priv->factory, dispatch_operation_path, properties, &error);
  if (dispatch_operation == NULL)
    {
      DEBUG ("Failed to create TpChannelDispatchOperation: %s", error->message);
      goto out;
    }

  _tp_channel_dispatch_operation_ensure_channels (dispatch_operation, channels);

  ctx = _tp_add_dispatch_operation_context_new (account, connection, channels,
      dispatch_operation, context);

  account_features = dup_features_for_account (self, account);
  connection_features = dup_features_for_connection (self, connection);
  channel_features = dup_features_for_channel (self, channel);

  _tp_add_dispatch_operation_context_prepare_async (ctx,
      (GQuark *) account_features->data,
      (GQuark *) connection_features->data,
      (GQuark *) channel_features->data,
      add_dispatch_context_prepare_cb, self);

  g_object_unref (ctx);
  g_array_unref (account_features);
  g_array_unref (connection_features);
  g_array_unref (channel_features);

out:
  g_clear_object (&account);
  g_clear_object (&connection);

  if (channels != NULL)
    g_ptr_array_unref (channels);

  if (dispatch_operation != NULL)
    g_object_unref (dispatch_operation);

  if (error == NULL)
    return;

  dbus_g_method_return_error (context, error);
  g_error_free (error);

}

static void
approver_iface_init (gpointer g_iface,
    gpointer unused G_GNUC_UNUSED)
{
#define IMPLEMENT(x) tp_svc_client_approver_implement_##x (\
  g_iface, _tp_base_client_##x)
  IMPLEMENT (add_dispatch_operation);
#undef IMPLEMENT
}

static void
chan_invalidated_cb (TpChannel *channel,
    guint domain,
    gint code,
    gchar *message,
    TpBaseClient *self)
{
  DEBUG ("Channel (%p) %s has been invalidated (%s)",
      channel, tp_proxy_get_object_path (channel), message);

  if (!(domain == TP_DBUS_ERRORS && code == TP_DBUS_ERROR_PROXY_UNREFERENCED))
    {
      g_hash_table_remove (self->priv->my_chans, tp_proxy_get_object_path (
          channel));
    }
}

static void
add_handled_channels (TpBaseClient *self,
    GPtrArray *channels)
{
  guint i;

  for (i = 0; i < channels->len; i++)
    {
      TpChannel *channel = g_ptr_array_index (channels, i);

      if (tp_proxy_get_invalidated (channel) == NULL)
        {
          DEBUG ("Inserting Channel (%p) %s",
            channel, tp_proxy_get_object_path (channel));
          g_hash_table_replace (self->priv->my_chans,
              (gchar *) tp_proxy_get_object_path (channel),
              g_object_ref (channel));

          tp_g_signal_connect_object (channel, "invalidated",
              G_CALLBACK (chan_invalidated_cb), self, 0);
        }
    }
}

static void
ctx_done_cb (TpHandleChannelsContext *context,
    TpBaseClient *self)
{
  add_handled_channels (self, context->channels);
}

static void
delegate_to_preferred_handler_delegate_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpBaseClient *self = (TpBaseClient *) source;
  GError *error = NULL;
  GPtrArray *delegated;

  if (!tp_base_client_delegate_channels_finish (self, result, &delegated, NULL,
        &error))
    {
      DEBUG ("DelegateChannels failed; we are still handling channels: %s",
          error->message);

      g_error_free (error);
      return;
    }

  self->priv->delegated_channels_cb (self, delegated,
      self->priv->delegated_channels_data);

  g_ptr_array_unref (delegated);
}

static gboolean
delegate_channels_if_needed (TpBaseClient *self,
    TpHandleChannelsContext *ctx)
{
  GList *requests, *l;
  const gchar *handler_to_delegate = NULL;
  gint64 user_action_time = 0;
  guint i;
  GList *chans = NULL;
  gboolean delegate = FALSE;

  /* User has to explicitely enable this feature */
  if (self->priv->delegated_channels_cb == NULL)
    return FALSE;

  requests = tp_handle_channels_context_get_requests (ctx);
  for (l = requests; l != NULL; l = g_list_next (l))
    {
      TpChannelRequest *cr = l->data;
      const GHashTable *hints;
      gboolean should_delegate;

      hints = tp_channel_request_get_hints (cr);
      if (hints == NULL)
        continue;

      should_delegate = tp_asv_get_boolean (hints,
          "org.freedesktop.Telepathy.ChannelRequest.DelegateToPreferredHandler",
          NULL);

      if (!should_delegate)
        continue;

      /* As stated in the spec, we should use the first CR having the
       * DelegateToPreferredHandler hint */
      handler_to_delegate = tp_channel_request_get_preferred_handler (cr);
      user_action_time = tp_channel_request_get_user_action_time (cr);
    }

  if (handler_to_delegate == NULL)
      /* No need to delegate */
      goto out;

  if (!tp_strdiff (handler_to_delegate, self->priv->name))
    /* We are already the one handling the channels */
    goto out;

  /* We are supposed to delegate the channels; check if we are handling
   * them */
  for (i = 0; i < ctx->channels->len; i++)
    {
      TpChannel *channel = g_ptr_array_index (ctx->channels, i);

      if (!tp_base_client_is_handling_channel (self, channel))
        {
          /* Don't delegate as there is at least one channel we are not
           * handling */
          DEBUG ("We have been asked to delegate channels but we are "
              "not handling %s", tp_proxy_get_object_path (channel));
          goto out;
        }

      chans = g_list_prepend (chans, channel);
    }

  DEBUG ("Delegate channels as requested");
  delegate = TRUE;

  tp_base_client_delegate_channels_async (self, chans, user_action_time,
      handler_to_delegate, delegate_to_preferred_handler_delegate_cb, self);

  g_list_free (chans);

  tp_handle_channels_context_accept (ctx);

out:
  g_list_free_full (requests, g_object_unref);
  return delegate;
}

static void
handle_channels_context_prepare_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpBaseClient *self = user_data;
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);
  TpHandleChannelsContext *ctx = TP_HANDLE_CHANNELS_CONTEXT (source);
  GError *error = NULL;
  GList *channels_list, *requests_list;

  if (!_tp_handle_channels_context_prepare_finish (ctx, result, &error))
    {
      DEBUG ("Failed to prepare TpHandleChannelsContext: %s", error->message);
      tp_handle_channels_context_fail (ctx, error);
      g_error_free (error);
      return;
    }

  if (delegate_channels_if_needed (self, ctx))
      return;

  channels_list = ptr_array_to_list (ctx->channels);
  requests_list = ptr_array_to_list (ctx->requests_satisfied);

  tp_g_signal_connect_object (ctx, "done", G_CALLBACK (ctx_done_cb),
      self, 0);

  cls->handle_channels (self, ctx->account, ctx->connection,
      channels_list, requests_list, ctx->user_action_time, ctx);

  g_list_free (channels_list);
  g_list_free (requests_list);

  if (_tp_handle_channels_context_get_state (ctx) ==
      TP_HANDLE_CHANNELS_CONTEXT_STATE_NONE)
    {
      error = g_error_new (TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
          "Implementation of HandledChannels in %s didn't call "
          "tp_handle_channels_context_{accept,fail,delay}",
          G_OBJECT_TYPE_NAME (self));

      CRITICAL ("%s", error->message);

      tp_handle_channels_context_fail (ctx, error);
      g_error_free (error);
    }
}

static TpChannelRequest *
find_request_by_path (TpBaseClient *self,
    const gchar *path)
{
  GList *l;

  for (l = self->priv->pending_requests; l != NULL; l = g_list_next (l))
    {
      TpChannelRequest *request = l->data;

      if (!tp_strdiff (tp_proxy_get_object_path (request), path))
        return request;
    }

  return NULL;
}

static void
_tp_base_client_handle_channels (TpSvcClientHandler *iface,
    const gchar *account_path,
    const gchar *connection_path,
    const GPtrArray *channels_arr,
    const GPtrArray *requests_arr,
    guint64 user_action_time,
    GHashTable *handler_info,
    DBusGMethodInvocation *context)
{
  TpBaseClient *self = TP_BASE_CLIENT (iface);
  TpHandleChannelsContext *ctx;
  TpBaseClientClass *cls = TP_BASE_CLIENT_GET_CLASS (self);
  GError *error = NULL;
  TpAccount *account = NULL;
  TpConnection *connection = NULL;
  GPtrArray *channels = NULL, *requests = NULL;
  guint i;
  TpChannel *channel = NULL;
  GArray *account_features;
  GArray *connection_features;
  GArray *channel_features;
  GHashTable *request_props;

  if (!(self->priv->flags & CLIENT_IS_HANDLER))
    {
      /* Pretend that the method is not implemented if we are not supposed to
       * be an Handler. */
      tp_dbus_g_method_return_not_implemented (context);
      return;
    }

  if (cls->handle_channels == NULL)
    {
      DEBUG ("class %s does not implement HandleChannels",
          G_OBJECT_TYPE_NAME (self));

      tp_dbus_g_method_return_not_implemented (context);
      return;
    }

  channel = ensure_account_connection_channels (self, account_path,
      connection_path, channels_arr, &account, &connection, &channels, &error);
  if (channel == NULL)
    goto out;

  /* FIXME: We will consider features set only for the first channel. This is
   * wrong in the case we receive multiple channels of different types.
   * It has always been like that, and multiple channel dispatch is being
   * deprecated. So let's just live with it. */
  channel = g_ptr_array_index (channels, 0);

  requests = g_ptr_array_new_full (requests_arr->len, g_object_unref);
  request_props = tp_asv_get_boxed (handler_info, "request-properties",
    TP_HASH_TYPE_OBJECT_IMMUTABLE_PROPERTIES_MAP);
  for (i = 0; i < requests_arr->len; i++)
    {
      const gchar *req_path = g_ptr_array_index (requests_arr, i);
      TpChannelRequest *request;
      GHashTable *props = NULL;

      if (request_props != NULL)
        props = g_hash_table_lookup (request_props, req_path);

      request = find_request_by_path (self, req_path);
      if (request != NULL)
        {
          g_object_ref (request);
          _tp_channel_request_ensure_immutable_properties (request, props);
        }
      else
        {
          request = _tp_simple_client_factory_ensure_channel_request (
              self->priv->factory, req_path, props, &error);
          if (request == NULL)
            {
              DEBUG ("Failed to create TpChannelRequest: %s", error->message);
              goto out;
            }
        }

      g_ptr_array_add (requests, request);
    }

  ctx = _tp_handle_channels_context_new (account, connection, channels,
      requests, user_action_time, handler_info, context);

  account_features = dup_features_for_account (self, account);
  connection_features = dup_features_for_connection (self, connection);
  channel_features = dup_features_for_channel (self, channel);

  _tp_handle_channels_context_prepare_async (ctx,
      (GQuark *) account_features->data,
      (GQuark *) connection_features->data,
      (GQuark *) channel_features->data,
      handle_channels_context_prepare_cb, self);

  g_object_unref (ctx);
  g_array_unref (account_features);
  g_array_unref (connection_features);
  g_array_unref (channel_features);

out:
  g_clear_object (&account);
  g_clear_object (&connection);

  if (channels != NULL)
    g_ptr_array_unref (channels);

  if (requests != NULL)
    g_ptr_array_unref (requests);

  if (error == NULL)
    return;

  dbus_g_method_return_error (context, error);
  g_error_free (error);
}

static void
handler_iface_init (gpointer g_iface,
    gpointer unused G_GNUC_UNUSED)
{
#define IMPLEMENT(x) tp_svc_client_handler_implement_##x (\
  g_iface, _tp_base_client_##x)
  IMPLEMENT (handle_channels);
#undef IMPLEMENT
}

typedef struct
{
  TpBaseClient *self;
  TpChannelRequest *request;
} channel_request_prepare_account_ctx;

static channel_request_prepare_account_ctx *
channel_request_prepare_account_ctx_new (TpBaseClient *self,
    TpChannelRequest *request)
{
  channel_request_prepare_account_ctx *ctx = g_slice_new (
      channel_request_prepare_account_ctx);

  ctx->self = g_object_ref (self);
  ctx->request = g_object_ref (request);
  return ctx;
}

static void
channel_request_prepare_account_ctx_free (
    channel_request_prepare_account_ctx *ctx)
{
  g_object_unref (ctx->self);
  g_object_unref (ctx->request);

  g_slice_free (channel_request_prepare_account_ctx, ctx);
}

static void
channel_request_account_prepare_cb (GObject *account,
    GAsyncResult *result,
    gpointer user_data)
{
  channel_request_prepare_account_ctx *ctx = user_data;
  GError *error = NULL;

  if (!tp_proxy_prepare_finish (account, result, &error))
    {
      DEBUG ("Failed to prepare account: %s", error->message);
      g_error_free (error);
    }

  g_signal_emit (ctx->self, signals[SIGNAL_REQUEST_ADDED], 0, account,
      ctx->request);

  channel_request_prepare_account_ctx_free (ctx);
}

static void
_tp_base_client_add_request (TpSvcClientInterfaceRequests *iface,
    const gchar *path,
    GHashTable *properties,
    DBusGMethodInvocation *context)
{
  TpBaseClient *self = TP_BASE_CLIENT (iface);
  TpChannelRequest *request;
  TpAccount *account = NULL;
  GError *error = NULL;
  channel_request_prepare_account_ctx *ctx;
  GArray *account_features;

  request = _tp_simple_client_factory_ensure_channel_request (
      self->priv->factory, path, properties, &error);
  if (request == NULL)
    {
      DEBUG ("Failed to create TpChannelRequest: %s", error->message);
      goto err;
    }

  path = tp_asv_get_object_path (properties, TP_PROP_CHANNEL_REQUEST_ACCOUNT);
  if (path == NULL)
    {
      error = g_error_new_literal (TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Mandatory 'Account' property is missing");

      DEBUG ("%s", error->message);
      goto err;
    }

  account = tp_base_client_dup_account (self, path, &error);

  if (account == NULL)
    goto err;

  self->priv->pending_requests = g_list_append (self->priv->pending_requests,
      request);

  ctx = channel_request_prepare_account_ctx_new (self, request);

  account_features = dup_features_for_account (self, account);

  tp_proxy_prepare_async (account,
      (GQuark *) account_features->data,
      channel_request_account_prepare_cb, ctx);

  g_array_unref (account_features);

  tp_svc_client_interface_requests_return_from_add_request (context);
  return;

err:
  g_clear_object (&account);

  dbus_g_method_return_error (context, error);
  g_error_free (error);
}

static void
_tp_base_client_remove_request (TpSvcClientInterfaceRequests *iface,
    const gchar *path,
    const gchar *error,
    const gchar *reason,
    DBusGMethodInvocation *context)
{
  TpBaseClient *self = TP_BASE_CLIENT (iface);
  TpChannelRequest *request;

  request = find_request_by_path (self, path);
  if (request == NULL)
    {
      GError err = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Uknown ChannelRequest" };

      dbus_g_method_return_error (context, &err);
      return;
    }

  self->priv->pending_requests = g_list_remove (self->priv->pending_requests,
      request);

  g_signal_emit (self, signals[SIGNAL_REQUEST_REMOVED], 0, request,
      error, reason);

  tp_svc_client_interface_requests_return_from_remove_request (context);
}

static void
requests_iface_init (gpointer g_iface,
    gpointer unused G_GNUC_UNUSED)
{
#define IMPLEMENT(x) tp_svc_client_interface_requests_implement_##x (\
  g_iface, _tp_base_client_##x)
  IMPLEMENT (add_request);
  IMPLEMENT (remove_request);
#undef IMPLEMENT
}

/**
 * tp_base_client_implement_observe_channels: (skip)
 * @klass: the #TpBaseClientClass of the object
 * @impl: the #TpBaseClientClassObserveChannelsImpl function implementing
 * ObserveChannels()
 *
 * Called by subclasses to define the actual implementation of the
 * ObserveChannels() D-Bus method.
 *
 * Since 0.11.13 this is exactly equivalent to setting the
 * #TpBaseClientClass.observe_channels function pointer.
 *
 * Since: 0.11.5
 */
void
tp_base_client_implement_observe_channels (TpBaseClientClass *cls,
    TpBaseClientClassObserveChannelsImpl impl)
{
  cls->observe_channels = impl;
}

/**
 * tp_base_client_get_bus_name:
 * @self: a #TpBaseClient
 *
 * Return the bus name of @self. Note that doesn't mean the client is
 * actually owning this name; for example if tp_base_client_register()
 * has not been called yet or failed.
 *
 * Returns: the bus name of the client
 *
 * Since: 0.11.5
 */
const gchar *
tp_base_client_get_bus_name (TpBaseClient *self)
{
  g_return_val_if_fail (TP_IS_BASE_CLIENT (self), NULL);
  return self->priv->bus_name;
}

/**
 * tp_base_client_get_object_path:
 * @self: a #TpBaseClient
 *
 * Return the object path of @self. Note that doesn't mean the client is
 * actually registered on this path; for example if tp_base_client_register()
 * has not been called yet or failed.
 *
 * Returns: the object path of the client
 *
 * Since: 0.11.5
 */
const gchar *
tp_base_client_get_object_path (TpBaseClient *self)
{
  g_return_val_if_fail (TP_IS_BASE_CLIENT (self), NULL);
  return self->priv->object_path;
}

/**
 * tp_base_client_get_name:
 * @self: a #TpBaseClient
 *
 * Return the #TpBaseClient:name construct-only property, which is used as
 * part of the bus name and object path.
 *
 * Returns: the value of #TpBaseClient:name
 * Since: 0.11.11
 */
const gchar *
tp_base_client_get_name (TpBaseClient *self)
{
  g_return_val_if_fail (TP_IS_BASE_CLIENT (self), NULL);
  return self->priv->name;
}

/**
 * tp_base_client_get_uniquify_name:
 * @self: a #TpBaseClient
 *
 * Return the #TpBaseClient:uniquify-name construct-only property; if this
 * is true, the bus name and object path will be made unique by appending
 * a suffix that includes the D-Bus unique name and a per-process counter.
 *
 * Returns: the value of #TpBaseClient:uniquify-name
 * Since: 0.11.11
 */
gboolean
tp_base_client_get_uniquify_name (TpBaseClient *self)
{
  g_return_val_if_fail (TP_IS_BASE_CLIENT (self), FALSE);
  return self->priv->uniquify_name;
}

/**
 * tp_base_client_get_dbus_daemon:
 * @self: a #TpBaseClient
 *
 * Return the #TpBaseClient:dbus-daemon construct-only property, which
 * represents the D-Bus connection used to export this client object.
 *
 * The returned object's reference count is not incremented, so it is not
 * necessarily valid after @self is destroyed.
 *
 * Returns: (transfer none): the value of #TpBaseClient:dbus-daemon
 * Since: 0.11.11
 */
TpDBusDaemon *
tp_base_client_get_dbus_daemon (TpBaseClient *self)
{
  g_return_val_if_fail (TP_IS_BASE_CLIENT (self), NULL);
  return self->priv->dbus;
}

/**
 * tp_base_client_get_account_manager: (skip)
 * @self: a #TpBaseClient
 *
 * Return the #TpBaseClient:account-manager construct-only property, which
 * is the account manager used to look up or create #TpAccount objects.
 *
 * The returned object's reference count is not incremented, so it is not
 * necessarily valid after @self is destroyed.
 *
 * It is not guaranteed that any particular features are prepared on this
 * object; enable and wait for features with tp_proxy_prepare_async().
 *
 * Returns: (transfer none): the value of #TpBaseClient:account-manager
 * Since: 0.11.14
 * Deprecated: New code should not use this function, it may return %NULL in
 *  the case @self was constructed with a #TpSimpleClientFactory.
 */
TpAccountManager *
tp_base_client_get_account_manager (TpBaseClient *self)
{
  g_return_val_if_fail (TP_IS_BASE_CLIENT (self), NULL);
  return self->priv->account_mgr;
}

/**
 * tp_base_client_implement_add_dispatch_operation: (skip)
 * @klass: the #TpBaseClientClass of the object
 * @impl: the #TpBaseClientClassAddDispatchOperationImpl function implementing
 * AddDispatchOperation()
 *
 * Called by subclasses to define the actual implementation of the
 * AddDispatchOperation() D-Bus method.
 *
 * Since 0.11.13 this is exactly equivalent to setting the
 * #TpBaseClientClass.add_dispatch_operation function pointer.
 *
 * Since: 0.11.5
 */
void
tp_base_client_implement_add_dispatch_operation (TpBaseClientClass *cls,
    TpBaseClientClassAddDispatchOperationImpl impl)
{
  cls->add_dispatch_operation = impl;
}

/**
 * tp_base_client_implement_handle_channels: (skip)
 * @klass: the #TpBaseClientClass of the object
 * @impl: the #TpBaseClientClassHandleChannelsImpl function implementing
 * HandleCHannels()
 *
 * Called by subclasses to define the actual implementation of the
 * HandleChannels() D-Bus method.
 *
 * Since 0.11.13 this is exactly equivalent to setting the
 * #TpBaseClientClass.handle_channels function pointer.
 *
 * Since: 0.11.6
 */
void
tp_base_client_implement_handle_channels (TpBaseClientClass *cls,
    TpBaseClientClassHandleChannelsImpl impl)
{
  cls->handle_channels = impl;
}

/**
 * tp_base_client_unregister:
 * @self: a client, which may already have been registered with
 *  tp_base_client_register(), or not
 *
 * Remove this client object from D-Bus, if tp_base_client_register()
 * has already been called.
 *
 * If the object is not registered, this method may be called, but has
 * no effect.
 *
 * Releasing the last reference to the object also has the same effect
 * as calling this method, but this method should be preferred, as it
 * has more deterministic behaviour.
 *
 * If the object still exists, tp_base_client_register() may be used to
 * attempt to register it again.
 *
 * Since: 0.11.6
 */
void
tp_base_client_unregister (TpBaseClient *self)
{
  GError *error = NULL;

  g_return_if_fail (TP_IS_BASE_CLIENT (self));

  if (!self->priv->registered)
    return;

  if (!tp_dbus_daemon_release_name (self->priv->dbus, self->priv->bus_name,
        &error))
    {
      WARNING ("Failed to release bus name (%s): %s", self->priv->bus_name,
          error->message);

      g_error_free (error);
    }

  tp_dbus_daemon_unregister_object (self->priv->dbus, self);

  if (self->priv->flags & CLIENT_IS_HANDLER)
    {
      GHashTable *clients;

      clients = dbus_connection_get_data (self->priv->libdbus, clients_slot);
      if (clients != NULL)
        g_hash_table_remove (clients, self->priv->object_path);

      dbus_connection_unref (self->priv->libdbus);
      self->priv->libdbus = NULL;

      dbus_connection_free_data_slot (&clients_slot);
    }

  self->priv->registered = FALSE;
}

/**
 * tp_base_client_add_account_features_varargs: (skip)
 * @self: a client
 * @feature: the first feature
 * @...: the second and subsequent features, if any, ending with 0
 *
 * The same as tp_base_client_add_account_features(), but with a more
 * convenient calling convention from C.
 *
 * Since: 0.11.14
 * Deprecated: New code should use
 *  tp_simple_client_factory_add_account_features_varargs() instead.
 */
void
tp_base_client_add_account_features_varargs (TpBaseClient *self,
    GQuark feature,
    ...)
{
  va_list ap;

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);

  va_start (ap, feature);
  _tp_quark_array_merge_valist (self->priv->account_features, feature, ap);
  va_end (ap);
}

/**
 * tp_base_client_add_connection_features_varargs: (skip)
 * @self: a client
 * @feature: the first feature
 * @...: the second and subsequent features, if any, ending with 0
 *
 * The same as tp_base_client_add_connection_features(), but with a more
 * convenient calling convention from C.
 *
 * Since: 0.11.14
 * Deprecated: New code should use
 *  tp_simple_client_factory_add_connection_features_varargs() instead.
 */
void
tp_base_client_add_connection_features_varargs (TpBaseClient *self,
    GQuark feature,
    ...)
{
  va_list ap;

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);

  va_start (ap, feature);
  _tp_quark_array_merge_valist (self->priv->connection_features, feature, ap);
  va_end (ap);
}

/**
 * tp_base_client_add_channel_features_varargs: (skip)
 * @self: a client
 * @feature: the first feature
 * @...: the second and subsequent features, if any, ending with 0
 *
 * The same as tp_base_client_add_channel_features(), but with a more
 * convenient calling convention from C.
 *
 * Since: 0.11.14
 * Deprecated: New code should use
 *  tp_simple_client_factory_add_channel_features_varargs() instead.
 */
void
tp_base_client_add_channel_features_varargs (TpBaseClient *self,
    GQuark feature,
    ...)
{
  va_list ap;

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);

  va_start (ap, feature);
  _tp_quark_array_merge_valist (self->priv->channel_features, feature, ap);
  va_end (ap);
}

/**
 * tp_base_client_add_account_features:
 * @self: a client
 * @features: (array length=n): the features
 * @n: the number of features, or -1 if @features is 0-terminated
 *
 * Request that the given features are prepared on each #TpAccount (in
 * addition to %TP_ACCOUNT_FEATURE_CORE) before calling
 * #TpBaseClientClass.observe_channels,
 * #TpBaseClientClass.add_dispatch_operation or
 * #TpBaseClientClass.handle_channels, or emitting
 * #TpBaseClient::request-added.
 *
 * Since: 0.11.14
 * Deprecated: New code should use
 *  tp_simple_client_factory_add_account_features() instead.
 */
void
tp_base_client_add_account_features (TpBaseClient *self,
    const GQuark *features,
    gssize n)
{
  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);

  _tp_quark_array_merge (self->priv->account_features, features, n);
}


/**
 * tp_base_client_add_channel_features:
 * @self: a client
 * @features: (array length=n): the features
 * @n: the number of features, or -1 if @features is 0-terminated
 *
 * Request that the given features are prepared on each #TpChannel (in
 * addition to %TP_CHANNEL_FEATURE_CORE) before calling
 * #TpBaseClientClass.observe_channels,
 * #TpBaseClientClass.add_dispatch_operation or
 * #TpBaseClientClass.handle_channels.
 *
 * Since: 0.11.14
 * Deprecated: New code should use
 *  tp_simple_client_factory_add_channel_features() instead.
 */
void
tp_base_client_add_channel_features (TpBaseClient *self,
    const GQuark *features,
    gssize n)
{
  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);

  _tp_quark_array_merge (self->priv->channel_features, features, n);
}

/**
 * tp_base_client_add_connection_features:
 * @self: a client
 * @features: (array length=n): the features
 * @n: the number of features, or -1 if @features is 0-terminated
 *
 * Request that the given features are prepared on each #TpConnection (in
 * addition to %TP_CONNECTION_FEATURE_CORE) before calling
 * #TpBaseClientClass.observe_channels,
 * #TpBaseClientClass.add_dispatch_operation or
 * #TpBaseClientClass.handle_channels.
 *
 * Since: 0.11.14
 * Deprecated: New code should use
 *  tp_simple_client_factory_add_connection_features() instead.
 */
void
tp_base_client_add_connection_features (TpBaseClient *self,
    const GQuark *features,
    gssize n)
{
  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);

  _tp_quark_array_merge (self->priv->connection_features, features, n);
}

/**
 * tp_base_client_set_channel_factory:
 * @self: a #TpBaseClient
 * @factory: an object implementing the #TpClientChannelFactoryInterface
 * interface
 *
 * Change the value of the #TpBaseClient:channel-factory property.
 * It can't be changed once @self has been registered.
 *
 * Since: 0.13.2
 * Deprecated: since 0.15.5. The factory is taken from
 *  #TpBaseClient:account-manager.
 */
void
tp_base_client_set_channel_factory (TpBaseClient *self,
    TpClientChannelFactory *factory)
{
  _tp_base_client_set_channel_factory (self, factory);
}

void
_tp_base_client_set_channel_factory (TpBaseClient *self,
    TpClientChannelFactory *factory)
{
  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (!self->priv->registered);
  g_return_if_fail (factory == NULL || TP_IS_CLIENT_CHANNEL_FACTORY (factory));

  tp_clear_object (&self->priv->channel_factory);

  if (factory != NULL)
    self->priv->channel_factory = g_object_ref (factory);
  g_object_notify (G_OBJECT (self), "channel-factory");
}

/**
 * tp_base_client_get_channel_factory: (skip)
 * @self: a #TpBaseClient
 *
 * Return the #TpBaseClient:channel-factory property.
 *
 * Returns: the value of #TpBaseClient:channel-factory
 * Since: 0.13.2
 * Deprecated: since 0.15.5. The factory is taken from
 *  #TpBaseClient:account-manager.
 */
TpClientChannelFactory *
tp_base_client_get_channel_factory (TpBaseClient *self)
{
  g_return_val_if_fail (TP_IS_BASE_CLIENT (self), NULL);

  return self->priv->channel_factory;
}

/**
 * tp_base_client_is_handling_channel:
 * @self: a #TpBaseClient
 * @channel: a #TpChannel
 *
 * Check if @self is currently handling @channel.
 *
 * Returns: %TRUE if @self is handling @channel, %FALSE otherwise
 * Since: 0.14.5
 */
gboolean
tp_base_client_is_handling_channel (TpBaseClient *self,
    TpChannel *channel)
{
  GList *channels, *l;
  gboolean found = FALSE;

  g_return_val_if_fail (TP_IS_BASE_CLIENT (self), FALSE);
  g_return_val_if_fail (self->priv->flags & CLIENT_IS_HANDLER, FALSE);

  channels = tp_base_client_dup_handled_channels (self);
  for (l = channels; l != NULL && !found; l = g_list_next (l))
    {
      TpChannel *chan = l->data;

      if (!tp_strdiff (tp_proxy_get_object_path (channel),
            tp_proxy_get_object_path (chan)))
        found = TRUE;
    }

  g_list_free_full (channels, g_object_unref);
  return found;
}

void
_tp_base_client_now_handling_channels (TpBaseClient *self,
    GPtrArray *channels)
{
  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (channels != NULL);

  /* It only makes sense to update HandledChannels if the client is
   * a Handler */
  if (self->priv->flags & CLIENT_IS_HANDLER)
    add_handled_channels (self, channels);
}

typedef struct
{
  /* Array of reffed TpChannel */
  GPtrArray *channels;
  /* Array of reffed TpChannel */
  GPtrArray *delegated;
  /* reffed TpChannel => owned GError */
  GHashTable *not_delegated;
} DelegateChannelsCtx;

static DelegateChannelsCtx *
delegate_channels_ctx_new (GList *channels)
{
  DelegateChannelsCtx *ctx = g_slice_new0 (DelegateChannelsCtx);
  GList *l;

  ctx->channels = g_ptr_array_new_full (g_list_length (channels),
      g_object_unref);

  for (l = channels; l != NULL; l = g_list_next (l))
    {
      TpChannel *channel = l->data;

      g_return_val_if_fail (TP_IS_CHANNEL (channel), NULL);

      g_ptr_array_add (ctx->channels, g_object_ref (channel));
    }

  ctx->delegated = g_ptr_array_new_with_free_func (g_object_unref);
  ctx->not_delegated = g_hash_table_new_full (g_direct_hash, g_direct_equal,
      g_object_unref, (GDestroyNotify) g_error_free);

  return ctx;
}

static void
delegate_channels_ctx_free (DelegateChannelsCtx *ctx)
{
  g_ptr_array_unref (ctx->channels);
  g_ptr_array_unref (ctx->delegated);
  g_hash_table_unref (ctx->not_delegated);

  g_slice_free (DelegateChannelsCtx, ctx);
}

static gboolean
path_is_in_array (const GPtrArray *array,
    const gchar *path)
{
  guint i;

  for (i = 0; array->len; i++)
    {
      if (!tp_strdiff (g_ptr_array_index (array, i), path))
        return TRUE;
    }

  return FALSE;
}

static void
delegate_channels_cb (TpChannelDispatcher *cd,
    const GPtrArray *delegated,
    GHashTable *not_delegated,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;
  TpBaseClient *self = (TpBaseClient *) weak_object;

  if (error != NULL)
    {
      g_simple_async_result_set_from_error (result, error);
    }
  else
    {
      DelegateChannelsCtx *ctx;
      guint i;

      ctx = g_simple_async_result_get_op_res_gpointer (result);

      for (i = 0; i < ctx->channels->len; i++)
        {
          TpChannel *channel = g_ptr_array_index (ctx->channels, i);
          const gchar *path;
          GValueArray *v;
          const gchar *dbus_error, *msg;
          GError *err = NULL;

          path = tp_proxy_get_object_path (channel);

          if (path_is_in_array (delegated, path))
            {
              /* We are no longer handling this channel */
              g_hash_table_remove (self->priv->my_chans, path);

              g_ptr_array_add (ctx->delegated, g_object_ref (channel));
              continue;
            }

          v = g_hash_table_lookup (not_delegated, path);
          if (v == NULL)
            {
              DEBUG ("MC didn't tell us if we are still handling or not %s",
                  path);
              continue;
            }

          tp_value_array_unpack (v, 2, &dbus_error, &msg);

          tp_proxy_dbus_error_to_gerror (cd, dbus_error, msg, &err);

          /* Pass ownership of the error to the hash table */
          g_hash_table_insert (ctx->not_delegated, g_object_ref (channel),
              err);
        }
    }

  g_simple_async_result_complete_in_idle (result);
}

/**
 * tp_base_client_delegate_channels_async:
 * @self: a #TpBaseClient
 * @channels: (element-type TelepathyGLib.Channel): a #GList of #TpChannel
 * handled by @self
 * @user_action_time: the time at which user action occurred,
 * or #TP_USER_ACTION_TIME_NOT_USER_ACTION if this delegation request is
 * for some reason not involving user action.
 * @preferred_handler: Either the well-known bus name (starting with
 * %TP_CLIENT_BUS_NAME_BASE) of the preferred handler for the channels,
 * or %NULL to indicate that any handler but @self would be acceptable.
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Asynchronously calls DelegateChannels on the ChannelDispatcher to try
 * stopping handling @channels and pass them to another Handler.
 * You can then call tp_base_client_delegate_channels_finish() to
 * get the result of the operation.
 *
 * Since: 0.15.0
 */
void
tp_base_client_delegate_channels_async (TpBaseClient *self,
    GList *channels,
    gint64 user_action_time,
    const gchar *preferred_handler,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpChannelDispatcher *cd;
  GSimpleAsyncResult *result;
  DelegateChannelsCtx *ctx;
  GPtrArray *chans;
  GList *l;

  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (self->priv->flags & CLIENT_IS_HANDLER);

  cd = tp_channel_dispatcher_new (self->priv->dbus);

  chans = g_ptr_array_new_full (g_list_length (channels), g_free);

  for (l = channels; l != NULL; l = g_list_next (l))
    {
      TpChannel *channel = l->data;

      g_return_if_fail (TP_IS_CHANNEL (channel));

      g_ptr_array_add (chans, g_strdup (tp_proxy_get_object_path (channel)));
    }

  result = g_simple_async_result_new (G_OBJECT (self), callback, user_data,
      tp_base_client_delegate_channels_async);

  ctx = delegate_channels_ctx_new (channels);

  g_simple_async_result_set_op_res_gpointer (result, ctx,
      (GDestroyNotify) delegate_channels_ctx_free);

  /* DelegateChannels() can takes a while if, for example, some clients are
   * crashing and so MC has to wait for them to time out before calling the
   * next handler. Set a timeout of 2 minutes. */
  tp_cli_channel_dispatcher_call_delegate_channels (cd, 1000 * 60 * 2,
      chans, user_action_time,
      preferred_handler == NULL ? "" : preferred_handler,
      delegate_channels_cb, result, g_object_unref, G_OBJECT (self));

  g_object_unref (cd);
  g_ptr_array_unref (chans);
}

/**
 * tp_base_client_delegate_channels_finish:
 * @self: a #TpBaseClient
 * @result: a #GAsyncResult
 * @delegated: (out) (element-type TelepathyGLib.Channel) (transfer container):
 * if not %NULL, used to return a #GPtrArray containing the #TpChannel<!-- -->s
 * which have been properly delegated
 * @not_delegated: (out) (element-type TelepathyGLib.Channel GLib.Error) (transfer container):
 * if not not %NULL, used to return a #GHashTable mapping #TpChannel<!-- -->s
 * which have not been delegated to a #GError explaining the reason of
 * the failure
 * @error: a #GError to fill
 *
 * Finishes an async channels delegation request started using
 * tp_base_client_delegate_channels_async().
 *
 * Returns: %TRUE if the operation succeed, @delegated and @not_delegated
 * can be used to know the channels that @self is not handling any more,
 * otherwise %FALSE.
 *
 * Since: 0.15.0
 */
gboolean
tp_base_client_delegate_channels_finish (TpBaseClient *self,
    GAsyncResult *result,
    GPtrArray **delegated,
    GHashTable **not_delegated,
    GError **error)
{
  DelegateChannelsCtx *ctx;
  GSimpleAsyncResult *simple = G_SIMPLE_ASYNC_RESULT (result);

  ctx = g_simple_async_result_get_op_res_gpointer (simple);

  if (g_simple_async_result_propagate_error (simple, error))
    return FALSE;

  g_return_val_if_fail (g_simple_async_result_is_valid (result,
        G_OBJECT (self), tp_base_client_delegate_channels_async), FALSE);

  if (delegated != NULL)
    *delegated = g_ptr_array_ref (ctx->delegated);

  if (not_delegated != NULL)
    *not_delegated = g_hash_table_ref (ctx->not_delegated);

  return TRUE;
}

/**
 * tp_base_client_set_delegated_channels_callback:
 * @self: a #TpBaseClient implementing Handler
 * @callback: function called when channels currently handled by @self are
 * delegated, may not be %NULL
 * @user_data: arbitrary user-supplied data passed to @callback
 * @destroy: called with the @user_data as argument, when @self is destroyed
 *
 * Turn on support for
 * the org.freedesktop.Telepathy.ChannelRequest.DelegateToPreferredHandler
 * hint.
 *
 * When receiving a request containing this hint, @self will automatically
 * delegate the channels to the preferred handler of the request and then call
 * @callback to inform the client that it is no longer handling those
 * channels.
 *
 * Since: 0.15.3
 */
void
tp_base_client_set_delegated_channels_callback (TpBaseClient *self,
    TpBaseClientDelegatedChannelsCb callback,
    gpointer user_data,
    GDestroyNotify destroy)
{
  g_return_if_fail (TP_IS_BASE_CLIENT (self));
  g_return_if_fail (self->priv->flags & CLIENT_IS_HANDLER);
  g_return_if_fail (!self->priv->registered);

  g_return_if_fail (self->priv->delegated_channels_cb == NULL);

  self->priv->delegated_channels_cb = callback;
  self->priv->delegated_channels_data = user_data;
  self->priv->delegated_channels_destroy = destroy;
}
