/*
 * channel-dispatch-operation.c - proxy for incoming channels seeking approval
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

#include "telepathy-glib/channel-dispatch-operation.h"
#include "telepathy-glib/channel-dispatch-operation-internal.h"

#include <telepathy-glib/base-client-internal.h>
#include <telepathy-glib/channel.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-internal.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/util.h>
#include <telepathy-glib/util-internal.h>

#define DEBUG_FLAG TP_DEBUG_DISPATCHER
#include "telepathy-glib/dbus-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/simple-client-factory-internal.h"

#include "telepathy-glib/_gen/tp-cli-channel-dispatch-operation-body.h"

/**
 * SECTION:channel-dispatch-operation
 * @title: TpChannelDispatchOperation
 * @short_description: proxy object for a to the Telepathy channel
 *  dispatcher
 * @see_also: #TpChannelDispatcher
 *
 * One of the channel dispatcher's functions is to offer incoming channels to
 * Approver clients for approval. Approvers respond to the channel dispatcher
 * via a #TpChannelDispatchOperation object.
 */

/**
 * TpChannelDispatchOperation:
 *
 * One of the channel dispatcher's functions is to offer incoming channels to
 * Approver clients for approval. An approver should generally ask the user
 * whether they want to participate in the requested communication channels
 * (join the chat or chatroom, answer the call, accept the file transfer, or
 * whatever is appropriate). A collection of channels offered in this way
 * is represented by a ChannelDispatchOperation object.
 *
 * If the user wishes to accept the communication channels, the approver
 * should call tp_cli_channel_dispatch_operation_call_handle_with() to
 * indicate the user's or approver's preferred handler for the channels (the
 * empty string indicates no particular preference, and will cause any
 * suitable handler to be used).
 *
 * If the user wishes to reject the communication channels, or if the user
 * accepts the channels and the approver will handle them itself, the approver
 * should call tp_cli_channel_dispatch_operation_call_claim(). If this method
 * succeeds, the approver immediately has control over the channels as their
 * primary handler, and may do anything with them (in particular, it may close
 * them in whatever way seems most appropriate).
 *
 * There are various situations in which the channel dispatch operation will
 * be closed, causing the #TpProxy::invalidated signal to be emitted. If this
 * happens, the approver should stop prompting the user.
 *
 * Because all approvers are launched simultaneously, the user might respond
 * to another approver; if this happens, the #TpProxy::invalidated signal
 * will be emitted with the domain %TP_DBUS_ERRORS and the error code
 * %TP_DBUS_ERROR_OBJECT_REMOVED.
 *
 * If a channel closes, the #TpChannelDispatchOperation::channel-lost signal
 * is emitted. If all channels
 * close, there is nothing more to dispatch, so the #TpProxy::invalidated
 * signal will be emitted with the domain %TP_DBUS_ERRORS and the error code
 * %TP_DBUS_ERROR_OBJECT_REMOVED.
 *
 * If the channel dispatcher crashes or exits, the #TpProxy::invalidated
 * signal will be emitted with the domain %TP_DBUS_ERRORS and the error code
 * %TP_DBUS_ERROR_NAME_OWNER_LOST. In a high-quality implementation, the
 * dispatcher should be restarted, at which point it will create new
 * channel dispatch operations for any undispatched channels, and the approver
 * will be notified again.
 *
 * Creating a #TpChannelDispatchOperation directly is deprecated: it
 * should only be created via a #TpBaseClient.
 *
 * Since 0.16, #TpChannelDispatchOperation always has a non-%NULL
 * #TpProxy:factory, which will be propagated to the #TpAccount,
 * #TpConnection and #TpChannel.
 *
 * Since: 0.7.32
 */

/**
 * TpChannelDispatchOperationClass:
 *
 * The class of a #TpChannelDispatchOperation.
 */

struct _TpChannelDispatchOperationPrivate {
  TpConnection *connection;
  TpAccount *account;
  GPtrArray *channels;
  GStrv possible_handlers;
  GHashTable *immutable_properties;
};

enum
{
  PROP_CONNECTION = 1,
  PROP_ACCOUNT,
  PROP_CHANNELS,
  PROP_POSSIBLE_HANDLERS,
  PROP_CDO_PROPERTIES,
  N_PROPS
};

enum {
  SIGNAL_CHANNEL_LOST,
  N_SIGNALS
};

static guint signals[N_SIGNALS] = { 0 };

G_DEFINE_TYPE (TpChannelDispatchOperation, tp_channel_dispatch_operation,
    TP_TYPE_PROXY)

static void
tp_channel_dispatch_operation_init (TpChannelDispatchOperation *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_CHANNEL_DISPATCH_OPERATION, TpChannelDispatchOperationPrivate);

  self->priv->immutable_properties = g_hash_table_new_full (g_str_hash,
      g_str_equal, g_free, (GDestroyNotify) tp_g_value_slice_free);
}

static void
tp_channel_dispatch_operation_finished_cb (TpChannelDispatchOperation *self,
    gpointer unused G_GNUC_UNUSED,
    GObject *object G_GNUC_UNUSED)
{
  GError e = { TP_DBUS_ERRORS, TP_DBUS_ERROR_OBJECT_REMOVED,
      "ChannelDispatchOperation finished and was removed" };

  tp_proxy_invalidate ((TpProxy *) self, &e);
}

static void
tp_channel_dispatch_operation_channel_lost_cb (TpChannelDispatchOperation *self,
    const gchar *path,
    const gchar *dbus_error,
    const gchar *message,
    gpointer unused G_GNUC_UNUSED,
    GObject *object G_GNUC_UNUSED)
{
  guint i;

  if (self->priv->channels == NULL)
    /* We didn't fetch channels yet */
    return;

  for (i = 0; i < self->priv->channels->len; i++)
    {
      TpChannel *channel = g_ptr_array_index (self->priv->channels, i);

      if (!tp_strdiff (tp_proxy_get_object_path (channel), path))
        {
          GError *error = NULL;

          /* Removing the channel from the array will unref it, add an extra
           * ref as we'll need it to fire the signal */
          g_object_ref (channel);

          g_ptr_array_remove (self->priv->channels, channel);

          tp_proxy_dbus_error_to_gerror (self, dbus_error, message, &error);

          g_signal_emit (self, signals[SIGNAL_CHANNEL_LOST], 0, channel,
              error->domain, error->code, error->message);

          g_object_notify ((GObject *) self, "channels");

          g_object_unref (channel);
          g_error_free (error);
          return;
        }
    }

  DEBUG ("Don't know this channel: %s", path);
}

static void
tp_channel_dispatch_operation_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpChannelDispatchOperation *self = TP_CHANNEL_DISPATCH_OPERATION (object);

  switch (property_id)
    {
    case PROP_CONNECTION:
      g_value_set_object (value, self->priv->connection);
      break;

    case PROP_ACCOUNT:
      g_value_set_object (value, self->priv->account);
      break;

    case PROP_CHANNELS:
      g_value_set_boxed (value, self->priv->channels);
      break;

    case PROP_POSSIBLE_HANDLERS:
      g_value_set_boxed (value, self->priv->possible_handlers);
      break;

    case PROP_CDO_PROPERTIES:
      g_value_set_boxed (value, self->priv->immutable_properties);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}

static void
maybe_set_connection (TpChannelDispatchOperation *self,
    const gchar *path)
{
  GError *error = NULL;

  if (self->priv->connection != NULL)
    return;

  if (path == NULL)
    return;

  self->priv->connection = tp_simple_client_factory_ensure_connection (
      tp_proxy_get_factory (self), path, NULL, &error);
  if (self->priv->connection == NULL)
    {
      DEBUG ("Failed to create connection %s: %s", path, error->message);
      g_error_free (error);
      return;
    }

  g_object_notify ((GObject *) self, "connection");

  if (g_hash_table_lookup (self->priv->immutable_properties,
        TP_PROP_CHANNEL_DISPATCH_OPERATION_CONNECTION) != NULL)
    return;

  g_hash_table_insert (self->priv->immutable_properties,
      g_strdup (TP_PROP_CHANNEL_DISPATCH_OPERATION_CONNECTION),
      tp_g_value_slice_new_boxed (DBUS_TYPE_G_OBJECT_PATH, path));
}

static void
maybe_set_account (TpChannelDispatchOperation *self,
    const gchar *path)
{
  GError *error = NULL;

  if (self->priv->account != NULL)
    return;

  if (path == NULL)
    return;

  self->priv->account = tp_simple_client_factory_ensure_account (
      tp_proxy_get_factory (self), path, NULL, &error);
  if (self->priv->account == NULL)
    {
      DEBUG ("Failed to create account %s: %s", path, error->message);
      g_error_free (error);
      return;
    }

  g_object_notify ((GObject *) self, "account");

  if (g_hash_table_lookup (self->priv->immutable_properties,
        TP_PROP_CHANNEL_DISPATCH_OPERATION_ACCOUNT) != NULL)
    return;

  g_hash_table_insert (self->priv->immutable_properties,
      g_strdup (TP_PROP_CHANNEL_DISPATCH_OPERATION_ACCOUNT),
      tp_g_value_slice_new_boxed (DBUS_TYPE_G_OBJECT_PATH, path));
}

static void
maybe_set_possible_handlers (TpChannelDispatchOperation *self,
    GStrv handlers)
{
  if (self->priv->possible_handlers != NULL)
    return;

  if (handlers == NULL)
    return;

  self->priv->possible_handlers = g_strdupv (handlers);

  g_object_notify ((GObject *) self, "possible-handlers");

  if (g_hash_table_lookup (self->priv->immutable_properties,
        TP_PROP_CHANNEL_DISPATCH_OPERATION_POSSIBLE_HANDLERS) != NULL)
    return;

  g_hash_table_insert (self->priv->immutable_properties,
      g_strdup (TP_PROP_CHANNEL_DISPATCH_OPERATION_POSSIBLE_HANDLERS),
      tp_g_value_slice_new_boxed (G_TYPE_STRV, handlers));
}

static void
maybe_set_interfaces (TpChannelDispatchOperation *self,
    const gchar **interfaces)
{
  if (interfaces == NULL)
    return;

  tp_proxy_add_interfaces ((TpProxy *) self, interfaces);

  g_hash_table_insert (self->priv->immutable_properties,
      g_strdup (TP_PROP_CHANNEL_DISPATCH_OPERATION_INTERFACES),
      tp_g_value_slice_new_boxed (G_TYPE_STRV, interfaces));
}

static void
tp_channel_dispatch_operation_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpChannelDispatchOperation *self = TP_CHANNEL_DISPATCH_OPERATION (object);

  switch (property_id)
    {
      case PROP_ACCOUNT:
        g_assert (self->priv->account == NULL);     /* construct-only */
        self->priv->account = g_value_dup_object (value);
        break;

      case PROP_CONNECTION:
        g_assert (self->priv->connection == NULL);  /* construct-only */
        self->priv->connection = g_value_dup_object (value);
        break;

      case PROP_CHANNELS:
        g_assert (self->priv->channels == NULL);  /* construct-only */
        _tp_channel_dispatch_operation_ensure_channels (self,
            g_value_get_boxed (value));
        break;

      case PROP_CDO_PROPERTIES:
        {
          GHashTable *asv = g_value_get_boxed (value);

          if (asv == NULL)
            return;

          tp_g_hash_table_update (self->priv->immutable_properties,
              asv, (GBoxedCopyFunc) g_strdup,
              (GBoxedCopyFunc) tp_g_value_slice_dup);
        }
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_channel_dispatch_operation_constructed (GObject *object)
{
  TpChannelDispatchOperation *self = TP_CHANNEL_DISPATCH_OPERATION (object);
  void (*chain_up) (GObject *) =
    ((GObjectClass *) tp_channel_dispatch_operation_parent_class)->constructed;
  GError *error = NULL;
  TpProxySignalConnection *sc;

  if (chain_up != NULL)
    chain_up (object);

  g_return_if_fail (tp_proxy_get_dbus_daemon (self) != NULL);

  _tp_proxy_ensure_factory (self, NULL);

  maybe_set_connection (self,
      tp_asv_get_boxed (self->priv->immutable_properties,
        TP_PROP_CHANNEL_DISPATCH_OPERATION_CONNECTION,
        DBUS_TYPE_G_OBJECT_PATH));

  maybe_set_account (self,
      tp_asv_get_boxed (self->priv->immutable_properties,
        TP_PROP_CHANNEL_DISPATCH_OPERATION_ACCOUNT,
        DBUS_TYPE_G_OBJECT_PATH));

  maybe_set_possible_handlers (self,
      tp_asv_get_boxed (self->priv->immutable_properties,
        TP_PROP_CHANNEL_DISPATCH_OPERATION_POSSIBLE_HANDLERS,
        G_TYPE_STRV));

  maybe_set_interfaces (self,
      tp_asv_get_boxed (self->priv->immutable_properties,
        TP_PROP_CHANNEL_DISPATCH_OPERATION_INTERFACES,
        G_TYPE_STRV));

  sc = tp_cli_channel_dispatch_operation_connect_to_finished (self,
      tp_channel_dispatch_operation_finished_cb, NULL, NULL, NULL, &error);

  if (sc == NULL)
    {
      CRITICAL ("Couldn't connect to Finished: %s", error->message);
      g_error_free (error);
      g_assert_not_reached ();
      return;
    }

  sc = tp_cli_channel_dispatch_operation_connect_to_channel_lost (self,
      tp_channel_dispatch_operation_channel_lost_cb, NULL, NULL, NULL, &error);

  if (sc == NULL)
    {
      g_critical ("Couldn't connect to ChannelLost: %s", error->message);
      g_error_free (error);
      g_assert_not_reached ();
      return;
    }
}

static void
tp_channel_dispatch_operation_dispose (GObject *object)
{
  TpChannelDispatchOperation *self = TP_CHANNEL_DISPATCH_OPERATION (object);
  void (*dispose) (GObject *) =
    G_OBJECT_CLASS (tp_channel_dispatch_operation_parent_class)->dispose;

  if (self->priv->connection != NULL)
    {
      g_object_unref (self->priv->connection);
      self->priv->connection = NULL;
    }

  if (self->priv->account != NULL)
    {
      g_object_unref (self->priv->account);
      self->priv->account = NULL;
    }

  if (self->priv->channels != NULL)
    {
      /* channels array has 'g_object_unref' has free_func */
      g_ptr_array_unref (self->priv->channels);
      self->priv->channels = NULL;
    }

  g_strfreev (self->priv->possible_handlers);
  self->priv->possible_handlers = NULL;

  if (self->priv->immutable_properties != NULL)
    {
      g_hash_table_unref (self->priv->immutable_properties);
      self->priv->immutable_properties = NULL;
    }

  if (dispose != NULL)
    dispose (object);
}

static TpChannel *
look_for_channel_having_path (GPtrArray *array,
    const gchar *path)
{
  guint i;

  for (i = 0; i < array->len; i++)
    {
      TpChannel *channel = g_ptr_array_index (array, i);

      if (!tp_strdiff (tp_proxy_get_object_path (channel), path))
        return channel;
    }

  return NULL;
}

static void
update_channels_array (TpChannelDispatchOperation *self,
    GPtrArray *channels)
{
  guint i;
  GPtrArray *old = NULL;

  if (self->priv->channels != NULL)
    {
      /* We received an initial list of channels during creation. Remove those
       * which are not in the Channels property any more. */
      old = self->priv->channels;
    }

  self->priv->channels = g_ptr_array_new_full (channels->len,
      g_object_unref);

  for (i = 0; i < channels->len; i++)
    {
      const gchar *path;
      GHashTable *chan_props;
      TpChannel *channel = NULL;
      GError *err = NULL;

      tp_value_array_unpack (g_ptr_array_index (channels, i), 2,
            &path, &chan_props);

      if (old != NULL)
        channel = look_for_channel_having_path (old, path);

      if (channel != NULL)
        {
          g_object_ref (channel);
        }
      else
        {
          channel = tp_simple_client_factory_ensure_channel (
              tp_proxy_get_factory (self), self->priv->connection,
              path, chan_props, &err);

          if (channel == NULL)
            {
              DEBUG ("Failed to create channel %s: %s", path, err->message);
              g_error_free (err);
              continue;
            }
        }

      g_ptr_array_add (self->priv->channels, channel);
    }

  if (old != NULL)
    {
      g_ptr_array_unref (old);
    }
}

static void
get_dispatch_operation_prop_cb (TpProxy *proxy,
    GHashTable *props,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpChannelDispatchOperation *self = (TpChannelDispatchOperation *) proxy;
  GSimpleAsyncResult *result = user_data;
  gboolean prepared = TRUE;
  GPtrArray *channels;
  GError *e = NULL;

  if (error != NULL)
    {
      DEBUG ("Failed to fetch ChannelDispatchOperation properties: %s",
          error->message);

      prepared = FALSE;
      e = g_error_copy (error);
      goto out;
    }

  /* Connection */
  maybe_set_connection (self, tp_asv_get_boxed (props, "Connection",
        DBUS_TYPE_G_OBJECT_PATH));

  if (self->priv->connection == NULL)
    {
      e = g_error_new_literal (TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Mandatory 'Connection' property is missing");
      DEBUG ("%s", e->message);

      prepared = FALSE;
      goto out;
    }

  /* Account */
  maybe_set_account (self, tp_asv_get_boxed (props, "Account",
        DBUS_TYPE_G_OBJECT_PATH));

  if (self->priv->account == NULL)
    {
      e = g_error_new_literal (TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Mandatory 'Account' property is missing");
      DEBUG ("%s", e->message);

      prepared = FALSE;
      goto out;
    }

  /* PossibleHandlers */
  maybe_set_possible_handlers (self, tp_asv_get_boxed (props,
        "PossibleHandlers", G_TYPE_STRV));

  if (self->priv->possible_handlers == NULL)
    {
      e = g_error_new_literal (TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Mandatory 'PossibleHandlers' property is missing");
      DEBUG ("%s", e->message);

      prepared = FALSE;
      goto out;
    }

  maybe_set_interfaces (self, tp_asv_get_boxed (props,
        "Interfaces", G_TYPE_STRV));

  /* set channels (not an immutable property) */
  channels = tp_asv_get_boxed (props, "Channels",
      TP_ARRAY_TYPE_CHANNEL_DETAILS_LIST);
  if (channels == NULL)
    {
      e = g_error_new_literal (TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Mandatory 'Channels' property is missing");
      DEBUG ("%s", e->message);

      prepared = FALSE;
      goto out;
    }

  update_channels_array (self, channels);

  g_object_notify ((GObject *) self, "channels");
  g_object_notify ((GObject *) self, "cdo-properties");

out:
  if (e != NULL)
    g_simple_async_result_set_from_error (result, e);

  g_simple_async_result_complete_in_idle (result);

  if (!prepared)
    {
      tp_proxy_invalidate ((TpProxy *) self, e);
      g_error_free (e);
    }
}

static void
prepare_core_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpChannelDispatchOperation *self = (TpChannelDispatchOperation *) proxy;
  GSimpleAsyncResult *result;

  result = g_simple_async_result_new ((GObject *) proxy, callback, user_data,
      prepare_core_async);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CHANNEL_DISPATCH_OPERATION,
      get_dispatch_operation_prop_cb,
      result, g_object_unref, NULL);
}

enum {
    FEAT_CORE,
    N_FEAT
};

static const TpProxyFeature *
tp_channel_dispatch_operation_list_features (TpProxyClass *cls G_GNUC_UNUSED)
{
  static TpProxyFeature features[N_FEAT + 1] = { { 0 } };

  if (G_LIKELY (features[0].name != 0))
    return features;

  features[FEAT_CORE].name = TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE;
  features[FEAT_CORE].core = TRUE;
  features[FEAT_CORE].prepare_async = prepare_core_async;

  /* assert that the terminator at the end is there */
  g_assert (features[N_FEAT].name == 0);

  return features;
}

static void
tp_channel_dispatch_operation_class_init (TpChannelDispatchOperationClass *klass)
{
  TpProxyClass *proxy_class = (TpProxyClass *) klass;
  GObjectClass *object_class = (GObjectClass *) klass;
  GParamSpec *param_spec;

  g_type_class_add_private (klass, sizeof (TpChannelDispatchOperationPrivate));

  object_class->get_property = tp_channel_dispatch_operation_get_property;
  object_class->set_property = tp_channel_dispatch_operation_set_property;
  object_class->constructed = tp_channel_dispatch_operation_constructed;
  object_class->dispose = tp_channel_dispatch_operation_dispose;

  /**
   * TpChannelDispatchOperation:connection:
   *
   * The #TpConnection with which the channels are associated.
   *
   * Read-only except during construction.
   *
   * This is not guaranteed to be set until tp_proxy_prepare_async() has
   * finished preparing %TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_object ("connection", "TpConnection",
      "The TpConnection of this channel dispatch operation",
      TP_TYPE_CONNECTION,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONNECTION,
      param_spec);

  /**
   * TpChannelDispatchOperation:account:
   *
   * The #TpAccount with which the connection and channels are associated.
   *
   * Read-only except during construction.
   *
   * This is not guaranteed to be set until tp_proxy_prepare_async() has
   * finished preparing %TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_object ("account", "TpAccount",
      "The TpAccount of this channel dispatch operation",
      TP_TYPE_ACCOUNT,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ACCOUNT,
      param_spec);

  /**
   * TpChannelDispatchOperation:channels:
   *
   * A #GPtrArray containing the #TpChannel to be dispatched.
   *
   * Read-only.
   *
   * This is not guaranteed to be set until tp_proxy_prepare_async() has
   * finished preparing %TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_boxed ("channels", "GPtrArray of TpChannel",
      "The TpChannel to be dispatched",
      G_TYPE_PTR_ARRAY,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CHANNELS,
      param_spec);

  /**
   * TpChannelDispatchOperation:possible-handlers:
   *
   * A #GStrv containing the well known bus names (starting
   * with TP_CLIENT_BUS_NAME_BASE) of the possible Handlers for
   * the channels
   *
   * Read-only except during construction.
   *
   * This is not guaranteed to be set until tp_proxy_prepare_async() has
   * finished preparing %TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_boxed ("possible-handlers", "Possible handlers",
      "Possible handlers for the channels",
      G_TYPE_STRV,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_POSSIBLE_HANDLERS,
      param_spec);

  /**
   * TpChannelDispatchOperation:cdo-properties:
   *
   * The immutable D-Bus properties of this ChannelDispatchOperation,
   * represented by a #GHashTable where the keys are D-Bus
   * interface name + "." + property name, and the values are #GValue instances.
   *
   * Read-only except during construction. If this is not provided
   * during construction, it is not guaranteed to be set until
   * tp_proxy_prepare_async() has finished preparing
   * %TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE.
   *
   * Since: 0.11.5
   */
  param_spec = g_param_spec_boxed ("cdo-properties",
      "Immutable D-Bus properties",
      "A map D-Bus interface + \".\" + property name => GValue",
      TP_HASH_TYPE_QUALIFIED_PROPERTY_VALUE_MAP,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class,
      PROP_CDO_PROPERTIES, param_spec);

 /**
   * TpChannelDispatchOperation::channel-lost:
   * @self: a #TpChannelDispatchOperation
   * @channel: the #TpChannel that closed
   * @domain: domain of a #GError indicating why the channel has been closed
   * @code: error code of a #GError indicating why the channel has been closed
   * @message: a message associated with the error
   *
   * Emitted when a channel has closed before it could be claimed or handled.
   *
   * Since: 0.11.5
   */
  signals[SIGNAL_CHANNEL_LOST] = g_signal_new (
      "channel-lost", G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 4,
      TP_TYPE_CHANNEL, G_TYPE_UINT, G_TYPE_INT, G_TYPE_STRING);

  proxy_class->interface = TP_IFACE_QUARK_CHANNEL_DISPATCH_OPERATION;
  proxy_class->must_have_unique_name = TRUE;
  proxy_class->list_features = tp_channel_dispatch_operation_list_features;

  tp_channel_dispatch_operation_init_known_interfaces ();
}

/**
 * tp_channel_dispatch_operation_init_known_interfaces:
 *
 * Ensure that the known interfaces for TpChannelDispatchOperation have been
 * set up. This is done automatically when necessary, but for correct
 * overriding of library interfaces by local extensions, you should
 * call this function before calling
 * tp_proxy_or_subclass_hook_on_interface_add() with first argument
 * %TP_TYPE_CHANNEL_DISPATCH_OPERATION.
 *
 * Since: 0.7.32
 */
void
tp_channel_dispatch_operation_init_known_interfaces (void)
{
  static gsize once = 0;

  if (g_once_init_enter (&once))
    {
      GType tp_type = TP_TYPE_CHANNEL_DISPATCH_OPERATION;

      tp_proxy_init_known_interfaces ();
      tp_proxy_or_subclass_hook_on_interface_add (tp_type,
          tp_cli_channel_dispatch_operation_add_signals);
      tp_proxy_subclass_add_error_mapping (tp_type,
          TP_ERROR_PREFIX, TP_ERROR, TP_TYPE_ERROR);

      g_once_init_leave (&once, 1);
    }
}

/**
 * tp_channel_dispatch_operation_new:
 * @bus_daemon: Proxy for the D-Bus daemon
 * @object_path: The non-NULL object path of this channel dispatch operation
 * @immutable_properties: As many as are known of the immutable D-Bus
 *  properties of this channel dispatch operation, or %NULL if none are known
 * @error: Used to raise an error if %NULL is returned
 *
 * Convenience function to create a new channel dispatch operation proxy.
 *
 * The @immutable_properties argument is not yet used.
 *
 * Returns: a new reference to an channel dispatch operation proxy, or %NULL if
 *    @object_path is not syntactically valid or the channel dispatcher is not
 *    running
 * Deprecated: Since 0.19.9. New code should get
 *  #TpChannelDispatchOperation objects from a #TpBaseClient
 */
TpChannelDispatchOperation *
tp_channel_dispatch_operation_new (TpDBusDaemon *bus_daemon,
    const gchar *object_path,
    GHashTable *immutable_properties,
    GError **error)
{
  return _tp_channel_dispatch_operation_new_with_factory (NULL, bus_daemon,
      object_path, immutable_properties, error);
}

TpChannelDispatchOperation *
_tp_channel_dispatch_operation_new_with_factory (TpSimpleClientFactory *factory,
    TpDBusDaemon *bus_daemon,
    const gchar *object_path,
    GHashTable *immutable_properties,
    GError **error)
{
  TpChannelDispatchOperation *self;
  gchar *unique_name;

  g_return_val_if_fail (bus_daemon != NULL, NULL);
  g_return_val_if_fail (object_path != NULL, NULL);
  g_return_val_if_fail (error == NULL || *error == NULL, NULL);

  if (!tp_dbus_check_valid_object_path (object_path, error))
    return NULL;

  if (!_tp_dbus_daemon_get_name_owner (bus_daemon, -1,
      TP_CHANNEL_DISPATCHER_BUS_NAME, &unique_name, error))
    return NULL;

  self = TP_CHANNEL_DISPATCH_OPERATION (g_object_new (
        TP_TYPE_CHANNEL_DISPATCH_OPERATION,
        "dbus-daemon", bus_daemon,
        "bus-name", unique_name,
        "object-path", object_path,
        "cdo-properties", immutable_properties,
        "factory", factory,
        NULL));

  g_free (unique_name);

  return self;
}

/**
 * TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE:
 *
 * Expands to a call to a function that returns a quark for the "core" feature
 * on a #TpChannelDispatchOperation.
 *
 * When this feature is prepared, the basic properties of the
 * ChannelDispatchOperation have been retrieved and are available for use.
 *
 * Specifically, this implies that:
 *
 * - #TpChannelDispatchOperation:connection is set (but
 *   TP_CONNECTION_FEATURE_CORE is not necessarily prepared)
 * - #TpChannelDispatchOperation:account is set (but
 *   TP_ACCOUNT_FEATURE_CORE is not necessarily prepared)
 * - #TpChannelDispatchOperation:channels is set (but
 *   TP_CHANNEL_FEATURE_CORE is not necessarily prepared)
 * - #TpChannelDispatchOperation:possible-handlers is set
 * - any extra interfaces will have been set up in TpProxy (i.e.
 *   #TpProxy:interfaces contains at least all extra ChannelDispatchOperation
 *   interfaces)
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.11.5
 */
GQuark
tp_channel_dispatch_operation_get_feature_quark_core (void)
{
  return g_quark_from_static_string (
      "tp-channel-dispatch-operation-feature-core");
}

/**
 * tp_channel_dispatch_operation_borrow_connection: (skip)
 * @self: a #TpChannelDispatchOperation
 *
 * Returns the #TpConnection of this ChannelDispatchOperation.
 * The returned pointer is only valid while @self is valid - reference
 * it with g_object_ref() if needed.
 *
 * Returns: (transfer none): the value of #TpChannelDispatchOperation:connection
 *
 * Since: 0.11.5
 * Deprecated: Since 0.19.9. New code should use
 *  tp_channel_dispatch_operation_get_connection() instead.
 */
TpConnection *
tp_channel_dispatch_operation_borrow_connection (
    TpChannelDispatchOperation *self)
{
  return self->priv->connection;
}

/**
 * tp_channel_dispatch_operation_borrow_account: (skip)
 * @self: a #TpChannelDispatchOperation
 *
 * Returns the #TpAccount of this ChannelDispatchOperation.
 * The returned pointer is only valid while @self is valid - reference
 * it with g_object_ref() if needed.
 *
 * Returns: (transfer none): the value of #TpChannelDispatchOperation:account
 *
 * Since: 0.11.5
 * Deprecated: Since 0.19.9. New code should use
 *  tp_channel_dispatch_operation_get_account() instead.
 */
TpAccount *
tp_channel_dispatch_operation_borrow_account (
    TpChannelDispatchOperation *self)
{
  return self->priv->account;
}

/**
 * tp_channel_dispatch_operation_borrow_channels: (skip)
 * @self: a #TpChannelDispatchOperation
 *
 * Returns a #GPtrArray containing the #TpChannel of this
 * ChannelDispatchOperation.
 * The returned array and its #TpChannel are only valid while @self is
 * valid - copy array and reference channels with g_object_ref() if needed.
 *
 * Returns: (transfer none): the value of #TpChannelDispatchOperation:channels
 *
 * Since: 0.11.5
 * Deprecated: Since 0.19.9. New code should use
 *  tp_channel_dispatch_operation_get_channels() instead.
 */
GPtrArray *
tp_channel_dispatch_operation_borrow_channels (
    TpChannelDispatchOperation *self)
{
  return self->priv->channels;
}

/**
 * tp_channel_dispatch_operation_borrow_possible_handlers: (skip)
 * @self: a #TpChannelDispatchOperation
 *
 * Returns a #GStrv containing the possible handlers of this
 * ChannelDispatchOperation.
 * The returned array and its strings are only valid while @self is
 * valid - copy it with g_strdupv if needed.
 *
 * Returns: (transfer none): the value of
 * #TpChannelDispatchOperation:possible-handlers
 *
 * Since: 0.11.5
 * Deprecated: Since 0.19.9. New code should use
 *  tp_channel_dispatch_operation_get_possible_handlers() instead.
 */
GStrv
tp_channel_dispatch_operation_borrow_possible_handlers (
    TpChannelDispatchOperation *self)
{
  return self->priv->possible_handlers;
}

/**
 * tp_channel_dispatch_operation_borrow_immutable_properties: (skip)
 * @self: a #TpChannelDispatchOperation
 *
 * Returns the immutable D-Bus properties of this channel.
 * The returned hash table is only valid while @self is valid - reference
 * it with g_hash_table_ref() if needed.
 *
 * Returns: (transfer none) (element-type utf8 GObject.Value): the value of
 * #TpChannelDispatchOperation:cdo-properties
 *
 * Since: 0.11.5
 * Deprecated: Since 0.19.9. New code should use individual property
 *  getters like tp_channel_dispatch_operation_get_connection(),
 *  tp_channel_dispatch_operation_get_account(),
 *  tp_channel_dispatch_operation_get_channels(), or
 *  tp_channel_dispatch_operation_get_possible_handlers() instead.
 */
GHashTable *
tp_channel_dispatch_operation_borrow_immutable_properties (
    TpChannelDispatchOperation *self)
{
  return self->priv->immutable_properties;
}

/**
 * tp_channel_dispatch_operation_get_connection: (skip)
 * @self: a #TpChannelDispatchOperation
 *
 * Returns the #TpConnection of this ChannelDispatchOperation.
 * The returned pointer is only valid while @self is valid - reference
 * it with g_object_ref() if needed.
 *
 * Returns: (transfer none): the value of #TpChannelDispatchOperation:connection
 *
 * Since: 0.19.9
 */
TpConnection *
tp_channel_dispatch_operation_get_connection (
    TpChannelDispatchOperation *self)
{
  return self->priv->connection;
}

/**
 * tp_channel_dispatch_operation_get_account: (skip)
 * @self: a #TpChannelDispatchOperation
 *
 * Returns the #TpAccount of this ChannelDispatchOperation.
 * The returned pointer is only valid while @self is valid - reference
 * it with g_object_ref() if needed.
 *
 * Returns: (transfer none): the value of #TpChannelDispatchOperation:account
 *
 * Since: 0.19.9
 */
TpAccount *
tp_channel_dispatch_operation_get_account (
    TpChannelDispatchOperation *self)
{
  return self->priv->account;
}

/**
 * tp_channel_dispatch_operation_get_channels:
 * @self: a #TpChannelDispatchOperation
 *
 * Returns a #GPtrArray containing the #TpChannel of this
 * ChannelDispatchOperation.
 * The returned array and its #TpChannel are only valid while @self is
 * valid - copy array and reference channels with g_object_ref() if needed.
 *
 * Returns: (transfer none) (element-type TelepathyGLib.Channel): the value
 *  of #TpChannelDispatchOperation:channels
 *
 * Since: 0.19.9
 */
GPtrArray *
tp_channel_dispatch_operation_get_channels (
    TpChannelDispatchOperation *self)
{
  return self->priv->channels;
}

/**
 * tp_channel_dispatch_operation_get_possible_handlers: (skip)
 * @self: a #TpChannelDispatchOperation
 *
 * Returns a #GStrv containing the possible handlers of this
 * ChannelDispatchOperation.
 * The returned array and its strings are only valid while @self is
 * valid - copy it with g_strdupv if needed.
 *
 * Returns: (transfer none): the value of
 * #TpChannelDispatchOperation:possible-handlers
 *
 * Since: 0.19.9
 */
GStrv
tp_channel_dispatch_operation_get_possible_handlers (
    TpChannelDispatchOperation *self)
{
  return self->priv->possible_handlers;
}

static void
handle_with_cb (TpChannelDispatchOperation *self,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("HandleWith failed: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
    }

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/**
 * tp_channel_dispatch_operation_handle_with_async:
 * @self: a #TpChannelDispatchOperation
 * @handler: (allow-none): The well-known bus name (starting with
 * #TP_CLIENT_BUS_NAME_BASE) of the channel handler that should handle the
 * channel, or %NULL if the client has no preferred channel handler
 * @callback: a callback to call when the call returns
 * @user_data: data to pass to @callback
 *
 * Called by an approver to accept a channel bundle and request that the
 * given handler be used to handle it.
 *
 * If successful, this method will cause the #TpProxy::invalidated signal
 * to be emitted with the TP_DBUS_ERROR_OBJECT_REMOVED error code.
 *
 * However, this method may fail because the dispatch has already been
 * completed and the object has already gone. If this occurs, it indicates
 * that another approver has asked for the bundle to be handled by a
 * particular handler. The approver MUST NOT attempt to interact with
 * the channels further in this case, unless it is separately
 * invoked as the handler.
 *
 * Approvers which are also channel handlers SHOULD use
 * tp_channel_dispatch_operation_claim_async() instead
 * of tp_channel_dispatch_operation_handle_with_async() to request
 * that they can handle a channel bundle themselves.
 *
 * Since: 0.11.5
 */
void
tp_channel_dispatch_operation_handle_with_async (
    TpChannelDispatchOperation *self,
    const gchar *handler,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (self));

  result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data, tp_channel_dispatch_operation_handle_with_async);

  tp_cli_channel_dispatch_operation_call_handle_with (self, -1,
      handler != NULL ? handler: "",
      handle_with_cb, result, NULL, G_OBJECT (self));
}

/**
 * tp_channel_dispatch_operation_handle_with_finish:
 * @self: a #TpChannelDispatchOperation
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async call to HandleWith().
 *
 * Returns: %TRUE if the HandleWith() call was successful, otherwise %FALSE
 *
 * Since: 0.11.5
 */
gboolean
tp_channel_dispatch_operation_handle_with_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self,
      tp_channel_dispatch_operation_handle_with_async);
}

static void
claim_cb (TpChannelDispatchOperation *self,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Claim failed: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
    }

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/**
 * tp_channel_dispatch_operation_claim_async:
 * @self: a #TpChannelDispatchOperation
 * @callback: a callback to call when the call returns
 * @user_data: data to pass to @callback
 *
 * Called by an approver to claim channels for handling internally.
 * If this method is called successfully, the process calling this
 * method becomes the handler for the channel.
 *
 * If successful, this method will cause the #TpProxy::invalidated signal
 * to be emitted, in the same way as for
 * tp_channel_dispatch_operation_handle_with_async().
 *
 * This method may fail because the dispatch operation has already
 * been completed. Again, see tp_channel_dispatch_operation_handle_with_async()
 * for more details. The approver MUST NOT attempt to interact with
 * the channels further in this case.
 *
 * Since: 0.11.5
 * Deprecated: since 0.15.0. Use
 * tp_channel_dispatch_operation_claim_with_async()
 */
void
tp_channel_dispatch_operation_claim_async (
    TpChannelDispatchOperation *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (self));

  result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data, tp_channel_dispatch_operation_claim_async);

  tp_cli_channel_dispatch_operation_call_claim (self, -1,
      claim_cb, result, NULL, G_OBJECT (self));
}

/**
 * tp_channel_dispatch_operation_claim_finish:
 * @self: a #TpChannelDispatchOperation
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async call to Claim().
 *
 * Returns: %TRUE if the Claim() call was successful, otherwise %FALSE
 *
 * Since: 0.11.5
 * Deprecated: since 0.15.0. Use
 * tp_channel_dispatch_operation_claim_with_finish()
 */
gboolean
tp_channel_dispatch_operation_claim_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_channel_dispatch_operation_claim_async);
}

/* FIXME: This is temporary solution to share TpChannel objects until
 * TpSimpleClientFactory can be used for that */
void
_tp_channel_dispatch_operation_ensure_channels (TpChannelDispatchOperation *self,
    GPtrArray *channels)
{
  guint i;

  if (self->priv->channels != NULL || channels == NULL)
    return;

  /* Do not just ref the GPtrArray because we'll modify its content */
  self->priv->channels = g_ptr_array_new_full (channels->len,
      g_object_unref);

  for (i = 0; i < channels->len; i++)
    g_ptr_array_add (self->priv->channels,
        g_object_ref (g_ptr_array_index (channels, i)));
}

/**
 * tp_channel_dispatch_operation_handle_with_time_async:
 * @self: a #TpChannelDispatchOperation
 * @handler: (allow-none): The well-known bus name (starting with
 * #TP_CLIENT_BUS_NAME_BASE) of the channel handler that should handle the
 * channel, or %NULL if the client has no preferred channel handler
 * @user_action_time: the time at which user action occurred, or one of the
 *  special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
 *  %TP_USER_ACTION_TIME_CURRENT_TIME
 * @callback: a callback to call when the call returns
 * @user_data: data to pass to @callback
 *
 * A variant of tp_channel_dispatch_operation_handle_with_async()
 * allowing the approver to pass an user action time.
 * This timestamp will be passed to the Handler when HandleChannels is called.
 *
 * If an X server timestamp for the user action causing this method call is
 * available, @user_action_time should be this timestamp (for instance, the
 * result of gdk_event_get_time() if it is not %GDK_CURRENT_TIME). Otherwise, it
 * may be %TP_USER_ACTION_TIME_NOT_USER_ACTION to behave as if there was no
 * user action or it happened a long time ago, or
 * %TP_USER_ACTION_TIME_CURRENT_TIME to have the Handler behave as though the
 * user action had just happened (resembling, but not numerically equal to,
 * %GDK_CURRENT_TIME).
 *
 * This method has been introduced in telepathy-mission-control 5.5.0.
 *
 * Since: 0.11.7
 */
void
tp_channel_dispatch_operation_handle_with_time_async (
    TpChannelDispatchOperation *self,
    const gchar *handler,
    gint64 user_action_time,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (self));

  result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data,
      tp_channel_dispatch_operation_handle_with_time_async);

  tp_cli_channel_dispatch_operation_call_handle_with_time (self, -1,
      handler != NULL ? handler: "", user_action_time,
      handle_with_cb, result, NULL, G_OBJECT (self));
}

/**
 * tp_channel_dispatch_operation_handle_with_time_finish:
 * @self: a #TpChannelDispatchOperation
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async call to HandleWithTime().
 *
 * Returns: %TRUE if the HandleWithTime() call was successful, otherwise %FALSE
 *
 * Since: 0.11.7
 */
gboolean
  tp_channel_dispatch_operation_handle_with_time_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self,
      tp_channel_dispatch_operation_handle_with_time_async);
}

static void
claim_with_cb (TpChannelDispatchOperation *self,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;
  TpBaseClient *client;

  client = g_simple_async_result_get_op_res_gpointer (result);

  _tp_base_client_now_handling_channels (client, self->priv->channels);

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/**
 * tp_channel_dispatch_operation_claim_with_async:
 * @self: a #TpChannelDispatchOperation
 * @client: the #TpBaseClient claiming @self
 * @callback: a callback to call when the call returns
 * @user_data: data to pass to @callback
 *
 * Called by an approver to claim channels for handling internally.
 * If this method is called successfully, the process calling this
 * method becomes the handler for the channel.
 *
 * If successful, this method will cause the #TpProxy::invalidated signal
 * to be emitted, in the same way as for
 * tp_channel_dispatch_operation_handle_with_async().
 *
 * This method may fail because the dispatch operation has already
 * been completed. Again, see tp_channel_dispatch_operation_handle_with_async()
 * for more details. The approver MUST NOT attempt to interact with
 * the channels further in this case.
 *
 * This is an improved version of tp_channel_dispatch_operation_claim_async()
 * as it tells @client about the new channels being handled.
 *
 * %TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE feature must be prepared before
 * calling this function.
 *
 * Since: 0.15.0
 */
void
tp_channel_dispatch_operation_claim_with_async (
    TpChannelDispatchOperation *self,
    TpBaseClient *client,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (self));
  g_return_if_fail (tp_proxy_is_prepared (self,
      TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE));

  result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data,
      tp_channel_dispatch_operation_claim_with_async);

  g_simple_async_result_set_op_res_gpointer (result, g_object_ref (client),
      g_object_unref);

  tp_cli_channel_dispatch_operation_call_claim (self, -1,
      claim_with_cb, result, NULL, G_OBJECT (self));
}

/**
 * tp_channel_dispatch_operation_claim_with_finish:
 * @self: a #TpChannelDispatchOperation
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async call to Claim() initiated using
 * tp_channel_dispatch_operation_claim_with_async().
 *
 * Returns: %TRUE if the Claim() call was successful, otherwise %FALSE
 *
 * Since: 0.15.0
 */
gboolean
tp_channel_dispatch_operation_claim_with_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, \
      tp_channel_dispatch_operation_claim_with_async)
}

static void
channel_close_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  GError *error = NULL;

  if (!tp_channel_close_finish (TP_CHANNEL (source), result, &error))
    {
      DEBUG ("Failed to close %s: %s", tp_proxy_get_object_path (source),
          error->message);

      g_error_free (error);
    }
}

static void
claim_close_channels_cb (TpChannelDispatchOperation *self,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;
  guint i;

  for (i = 0; i < self->priv->channels->len; i++)
    {
      TpChannel *channel = g_ptr_array_index (self->priv->channels, i);

      tp_channel_close_async (channel, channel_close_cb, NULL);
    }

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/**
 * tp_channel_dispatch_operation_close_channels_async:
 * @self: a #TpChannelDispatchOperation
 * @callback: a callback to call when the request has been satisfied
 * @user_data: data to pass to @callback
 *
 * Called by an approver to claim channels and close them all right away.
 * If this method is called successfully, @self has been claimed and
 * tp_channel_close_async() has been called on all of its channels.
 *
 * If successful, this method will cause the #TpProxy::invalidated signal
 * to be emitted, in the same way as for
 * tp_channel_dispatch_operation_handle_with_async().
 *
 * This method may fail because the dispatch operation has already
 * been completed. Again, see tp_channel_dispatch_operation_handle_with_async()
 * for more details.
 *
 * %TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE feature must be prepared before
 * calling this function.
 *
 * Since: 0.15.1
 */
void
tp_channel_dispatch_operation_close_channels_async (
    TpChannelDispatchOperation *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (self));
  g_return_if_fail (tp_proxy_is_prepared (self,
      TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE));

  result = g_simple_async_result_new (G_OBJECT (self), callback, user_data,
      tp_channel_dispatch_operation_close_channels_async);

  tp_cli_channel_dispatch_operation_call_claim (self, -1,
      claim_close_channels_cb, result, NULL, G_OBJECT (self));
}

/**
 * tp_channel_dispatch_operation_close_channels_finish:
 * @self: a #TpChannelDispatchOperation
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async operation initiated using
 * tp_channel_dispatch_operation_close_channels_async().
 *
 * Returns: %TRUE if the Claim() call was successful and
 * Close() has at least been attempted on all the channels, otherwise %FALSE
 *
 * Since: 0.15.1
 */
gboolean
tp_channel_dispatch_operation_close_channels_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, \
      tp_channel_dispatch_operation_close_channels_async)
}

typedef struct
{
  TpChannelGroupChangeReason reason;
  gchar *message;
} LeaveChannelsCtx;

static LeaveChannelsCtx *
leave_channels_ctx_new (TpChannelGroupChangeReason reason,
    const gchar *message)
{
  LeaveChannelsCtx *ctx = g_slice_new (LeaveChannelsCtx);

  ctx->reason = reason;
  ctx->message = g_strdup (message);
  return ctx;
}

static void
leave_channels_ctx_free (LeaveChannelsCtx *ctx)
{
  g_free (ctx->message);
  g_slice_free (LeaveChannelsCtx, ctx);
}

static void
channel_leave_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  GError *error = NULL;

  if (!tp_channel_leave_finish (TP_CHANNEL (source), result, &error))
    {
      DEBUG ("Failed to leave %s: %s", tp_proxy_get_object_path (source),
          error->message);

      g_error_free (error);
    }
}

static void
claim_leave_channels_cb (TpChannelDispatchOperation *self,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;
  guint i;
  LeaveChannelsCtx *ctx;

  ctx = g_simple_async_result_get_op_res_gpointer (result);

  for (i = 0; i < self->priv->channels->len; i++)
    {
      TpChannel *channel = g_ptr_array_index (self->priv->channels, i);

      tp_channel_leave_async (channel, ctx->reason, ctx->message,
          channel_leave_cb, NULL);
    }

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/**
 * tp_channel_dispatch_operation_leave_channels_async:
 * @self: a #TpChannelDispatchOperation
 * @reason: the leave reason
 * @message: the leave message
 * @callback: a callback to call when the request has been satisfied
 * @user_data: data to pass to @callback
 *
 * Called by an approver to claim channels and leave them all right away.
 * If this method is called successfully, @self has been claimed and
 * tp_channel_leave_async() has been called on all of its channels.
 *
 * If successful, this method will cause the #TpProxy::invalidated signal
 * to be emitted, in the same way as for
 * tp_channel_dispatch_operation_handle_with_async().
 *
 * This method may fail because the dispatch operation has already
 * been completed. Again, see tp_channel_dispatch_operation_handle_with_async()
 * for more details.
 *
 * %TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE feature must be prepared before
 * calling this function.
 *
 * Since: 0.15.2
 */
void
tp_channel_dispatch_operation_leave_channels_async (
    TpChannelDispatchOperation *self,
    TpChannelGroupChangeReason reason,
    const gchar *message,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (self));
  g_return_if_fail (tp_proxy_is_prepared (self,
      TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE));

  result = g_simple_async_result_new (G_OBJECT (self), callback, user_data,
      tp_channel_dispatch_operation_leave_channels_async);

  g_simple_async_result_set_op_res_gpointer (result,
      leave_channels_ctx_new (reason, message),
      (GDestroyNotify) leave_channels_ctx_free);

  tp_cli_channel_dispatch_operation_call_claim (self, -1,
      claim_leave_channels_cb, result, NULL, G_OBJECT (self));
}

/**
 * tp_channel_dispatch_operation_leave_channels_finish:
 * @self: a #TpChannelDispatchOperation
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async operation initiated using
 * tp_channel_dispatch_operation_leave_channels_async().
 *
 * Returns: %TRUE if the Claim() call was successful and
 * tp_channel_leave_async() has at least been attempted on all the
 * channels, otherwise %FALSE
 *
 * Since: 0.15.2
 */
gboolean
tp_channel_dispatch_operation_leave_channels_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, \
      tp_channel_dispatch_operation_leave_channels_async)
}

static void
channel_destroy_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  GError *error = NULL;

  if (!tp_channel_destroy_finish (TP_CHANNEL (source), result, &error))
    {
      DEBUG ("Failed to destroy %s: %s", tp_proxy_get_object_path (source),
          error->message);

      g_error_free (error);
    }
}

static void
claim_destroy_channels_cb (TpChannelDispatchOperation *self,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;
  guint i;

  for (i = 0; i < self->priv->channels->len; i++)
    {
      TpChannel *channel = g_ptr_array_index (self->priv->channels, i);

      tp_channel_destroy_async (channel, channel_destroy_cb, NULL);
    }

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/**
 * tp_channel_dispatch_operation_destroy_channels_async:
 * @self: a #TpChannelDispatchOperation
 * @callback: a callback to call when the request has been satisfied
 * @user_data: data to pass to @callback
 *
 * Called by an approver to claim channels and destroy them all right away.
 * If this method is called successfully, @self has been claimed and
 * tp_channel_destroy_async() has been called on all of its channels.
 *
 * If successful, this method will cause the #TpProxy::invalidated signal
 * to be emitted, in the same way as for
 * tp_channel_dispatch_operation_handle_with_async().
 *
 * This method may fail because the dispatch operation has already
 * been completed. Again, see tp_channel_dispatch_operation_handle_with_async()
 * for more details.
 *
 * %TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE feature must be prepared before
 * calling this function.
 *
 * Since: 0.15.2
 */
void
tp_channel_dispatch_operation_destroy_channels_async (
    TpChannelDispatchOperation *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CHANNEL_DISPATCH_OPERATION (self));
  g_return_if_fail (tp_proxy_is_prepared (self,
      TP_CHANNEL_DISPATCH_OPERATION_FEATURE_CORE));

  result = g_simple_async_result_new (G_OBJECT (self), callback, user_data,
      tp_channel_dispatch_operation_destroy_channels_async);

  tp_cli_channel_dispatch_operation_call_claim (self, -1,
      claim_destroy_channels_cb, result, NULL, G_OBJECT (self));
}

/**
 * tp_channel_dispatch_operation_destroy_channels_finish:
 * @self: a #TpChannelDispatchOperation
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async operation initiated using
 * tp_channel_dispatch_operation_destroy_channels_async().
 *
 * Returns: %TRUE if the Claim() call was successful and
 * tp_channel_destroy_async() has at least been attempted on all the
 * channels, otherwise %FALSE
 *
 * Since: 0.15.2
 */
gboolean
tp_channel_dispatch_operation_destroy_channels_finish (
    TpChannelDispatchOperation *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, \
      tp_channel_dispatch_operation_destroy_channels_async)
}
