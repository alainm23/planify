/*
 * object used to request a channel from a TpAccount
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
 * SECTION: account-channel-request
 * @title: TpAccountChannelRequest
 * @short_description: Object used to request a channel from a #TpAccount
 *
 * A #TpAccountChannelRequest object is used to request a channel using the
 * ChannelDispatcher. Once created, use one of the create or ensure async
 * method to actually request the channel.
 *
 * Note that each #TpAccountChannelRequest object can only be used to create
 * one channel. You can't call a create or ensure method more than once on the
 * same #TpAccountChannelRequest.
 *
 * Once the channel has been created you can use the
 * TpAccountChannelRequest::re-handled: signal to be notified when the channel
 * has to be re-handled. This can be useful for example to move its window
 * to the foreground, if applicable.
 *
 * Using this object is appropriate for most channel types.
 * For a contact search channel, use tp_contact_search_new_async() instead.
 *
 * Since: 0.11.12
 */

/**
 * TpAccountChannelRequest:
 *
 * Data structure representing a #TpAccountChannelRequest object.
 *
 * Since: 0.11.12
 */

/**
 * TpAccountChannelRequestClass:
 *
 * The class of a #TpAccountChannelRequest.
 *
 * Since: 0.11.12
 */

/**
 * TpAccountChannelRequestDelegatedChannelCb:
 * @request: a #TpAccountChannelRequest instance
 * @channel: a #TpChannel
 * @user_data: arbitrary user-supplied data passed to
 * tp_account_channel_request_set_delegated_channel_callback()
 *
 * Called when a client asked us to delegate @channel to another Handler.
 * When this function is called you are no longer handling @channel.
 *
 * Since: 0.15.3
 */

#include "config.h"

#include "telepathy-glib/account-channel-request.h"
#include "telepathy-glib/account-channel-request-internal.h"

#include <telepathy-glib/automatic-proxy-factory.h>
#include "telepathy-glib/base-client-internal.h"
#include <telepathy-glib/channel-dispatcher.h>
#include <telepathy-glib/channel-request.h>
#include <telepathy-glib/channel.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/simple-handler.h>
#include <telepathy-glib/util.h>
#include <telepathy-glib/util-internal.h>
#include <telepathy-glib/variant-util-internal.h>

#define DEBUG_FLAG TP_DEBUG_CLIENT
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/deprecated-internal.h"
#include "telepathy-glib/simple-client-factory-internal.h"

struct _TpAccountChannelRequestClass {
    /*<private>*/
    GObjectClass parent_class;
};

struct _TpAccountChannelRequest {
  /*<private>*/
  GObject parent;
  TpAccountChannelRequestPrivate *priv;
};

G_DEFINE_TYPE(TpAccountChannelRequest,
    tp_account_channel_request, G_TYPE_OBJECT)

enum {
    PROP_ACCOUNT = 1,
    PROP_REQUEST,
    PROP_REQUEST_VARDICT,
    PROP_USER_ACTION_TIME,
    PROP_CHANNEL_REQUEST,
    N_PROPS
};

enum {
  SIGNAL_RE_HANDLED,
  N_SIGNALS
};

static guint signals[N_SIGNALS] = { 0 };

typedef enum
{
  ACTION_TYPE_FORGET,
  ACTION_TYPE_HANDLE,
  ACTION_TYPE_OBSERVE
} ActionType;

struct _TpAccountChannelRequestPrivate
{
  TpAccount *account;
  /* dup'd string => slice-allocated GValue
   *
   * Do not use tp_asv_new() and friends, because they expect static
   * string keys. */
  GHashTable *request;
  gint64 user_action_time;

  TpBaseClient *handler;
  gboolean ensure;
  GCancellable *cancellable;
  GSimpleAsyncResult *result;
  TpChannelRequest *chan_request;
  gulong invalidated_sig;
  gulong succeeded_chan_sig;
  gulong cancel_id;
  TpChannel *channel;
  TpHandleChannelsContext *handle_context;
  TpDBusDaemon *dbus;
  TpClientChannelFactory *factory;
  GHashTable *hints;

  /* TRUE if the channel has been requested (an _async function has been called
   * on the TpAccountChannelRequest) */
  gboolean requested;

  ActionType action_type;

  TpAccountChannelRequestDelegatedChannelCb delegated_channel_cb;
  gpointer delegated_channel_data;
  GDestroyNotify delegated_channel_destroy;
};

static void
tp_account_channel_request_init (TpAccountChannelRequest *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_ACCOUNT_CHANNEL_REQUEST,
      TpAccountChannelRequestPrivate);
}

static void
request_disconnect (TpAccountChannelRequest *self)
{
  if (self->priv->invalidated_sig == 0)
    return;

  g_assert (self->priv->chan_request != NULL);

  g_signal_handler_disconnect (self->priv->chan_request,
      self->priv->invalidated_sig);
  self->priv->invalidated_sig = 0;

  g_signal_handler_disconnect (self->priv->chan_request,
      self->priv->succeeded_chan_sig);
  self->priv->succeeded_chan_sig = 0;
}

static void
tp_account_channel_request_dispose (GObject *object)
{
  TpAccountChannelRequest *self = TP_ACCOUNT_CHANNEL_REQUEST (
      object);
  void (*dispose) (GObject *) =
    G_OBJECT_CLASS (tp_account_channel_request_parent_class)->dispose;

  request_disconnect (self);

  if (self->priv->cancel_id != 0)
    g_cancellable_disconnect (self->priv->cancellable, self->priv->cancel_id);

  tp_clear_object (&self->priv->account);
  tp_clear_pointer (&self->priv->request, g_hash_table_unref);
  tp_clear_object (&self->priv->handler);
  tp_clear_object (&self->priv->cancellable);
  tp_clear_object (&self->priv->result);
  tp_clear_object (&self->priv->chan_request);
  tp_clear_object (&self->priv->channel);
  tp_clear_object (&self->priv->handle_context);
  tp_clear_object (&self->priv->dbus);
  tp_clear_object (&self->priv->factory);
  tp_clear_pointer (&self->priv->hints, g_hash_table_unref);

  if (self->priv->delegated_channel_destroy != NULL)
    {
      self->priv->delegated_channel_destroy (
          self->priv->delegated_channel_data);
      self->priv->delegated_channel_destroy = NULL;
    }

  if (dispose != NULL)
    dispose (object);
}

static void
tp_account_channel_request_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpAccountChannelRequest *self = TP_ACCOUNT_CHANNEL_REQUEST (
      object);

  switch (property_id)
    {
      case PROP_ACCOUNT:
        g_value_set_object (value, self->priv->account);
        break;

      case PROP_REQUEST:
        g_value_set_boxed (value, self->priv->request);
        break;

      case PROP_REQUEST_VARDICT:
        g_value_take_variant (value,
            tp_account_channel_request_dup_request (self));
        break;

      case PROP_USER_ACTION_TIME:
        g_value_set_int64 (value, self->priv->user_action_time);
        break;

      case PROP_CHANNEL_REQUEST:
        g_value_set_object (value, self->priv->chan_request);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_account_channel_request_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpAccountChannelRequest *self = TP_ACCOUNT_CHANNEL_REQUEST (
      object);

  switch (property_id)
    {
      case PROP_ACCOUNT:
        self->priv->account = g_value_dup_object (value);
        break;

      case PROP_REQUEST:
        /* If this property remains unset, GObject will set it to a NULL
         * value. Ignore that, so request-vardict can be set instead. */
        if (g_value_get_boxed (value) == NULL)
          return;

        /* Construct-only and mutually exclusive with request-vardict */
        g_return_if_fail (self->priv->request == NULL);

        /* We do not use tp_asv_new() and friends, because in principle,
         * the request can contain user-defined keys. */
        self->priv->request = g_hash_table_new_full (g_str_hash, g_str_equal,
            g_free, (GDestroyNotify) tp_g_value_slice_free);
        tp_g_hash_table_update (self->priv->request,
            g_value_get_boxed (value),
            (GBoxedCopyFunc) g_strdup,
            (GBoxedCopyFunc) tp_g_value_slice_dup);
        break;

      case PROP_REQUEST_VARDICT:
          {
            GHashTable *hash;

            /* If this property remains unset, GObject will set it to a NULL
             * value. Ignore that, so request can be set instead. */
            if (g_value_get_variant (value) == NULL)
              return;

            /* Construct-only and mutually exclusive with request */
            g_return_if_fail (self->priv->request == NULL);

            hash = _tp_asv_from_vardict (g_value_get_variant (value));
            self->priv->request = g_hash_table_new_full (g_str_hash,
                g_str_equal, g_free, (GDestroyNotify) tp_g_value_slice_free);

            tp_g_hash_table_update (self->priv->request,
                hash, (GBoxedCopyFunc) g_strdup,
                (GBoxedCopyFunc) tp_g_value_slice_dup);
            g_hash_table_unref (hash);
          }
        break;

      case PROP_USER_ACTION_TIME:
        self->priv->user_action_time = g_value_get_int64 (value);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
  }
}

static void
tp_account_channel_request_constructed (GObject *object)
{
  TpAccountChannelRequest *self = TP_ACCOUNT_CHANNEL_REQUEST (
      object);
  void (*chain_up) (GObject *) =
    ((GObjectClass *)
      tp_account_channel_request_parent_class)->constructed;

  if (chain_up != NULL)
    chain_up (object);

  g_assert (self->priv->account != NULL);
  g_assert (self->priv->request != NULL);

  self->priv->dbus = g_object_ref (tp_proxy_get_dbus_daemon (
        self->priv->account));
}

static void
tp_account_channel_request_class_init (
    TpAccountChannelRequestClass *cls)
{
  GObjectClass *object_class = G_OBJECT_CLASS (cls);
  GParamSpec *param_spec;

  g_type_class_add_private (cls, sizeof (TpAccountChannelRequestPrivate));

  object_class->get_property = tp_account_channel_request_get_property;
  object_class->set_property = tp_account_channel_request_set_property;
  object_class->constructed = tp_account_channel_request_constructed;
  object_class->dispose = tp_account_channel_request_dispose;

  /**
   * TpAccountChannelRequest:account:
   *
   * The #TpAccount used to request the channel.
   * Read-only except during construction.
   *
   * This property can't be %NULL.
   *
   * Since: 0.11.12
   */
  param_spec = g_param_spec_object ("account", "TpAccount",
      "The TpAccount used to request the channel",
      TP_TYPE_ACCOUNT,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ACCOUNT,
      param_spec);

  /**
   * TpAccountChannelRequest:request:
   *
   * The desired D-Bus properties for the channel, represented as a
   * #GHashTable where the keys are strings and the values are #GValue.
   *
   * When constructing a new object, one of
   * #TpAccountChannelRequest:request or
   * #TpAccountChannelRequest:request-vardict must be set to a non-%NULL
   * value, and the other must remain unspecified.
   *
   * Since: 0.11.12
   */
  param_spec = g_param_spec_boxed ("request", "GHashTable",
      "A dictionary containing desirable properties for the channel",
      TP_HASH_TYPE_STRING_VARIANT_MAP,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_REQUEST,
      param_spec);

  /**
   * TpAccountChannelRequest:request-vardict:
   *
   * The desired D-Bus properties for the channel.
   *
   * When constructing a new object, one of
   * #TpAccountChannelRequest:request or
   * #TpAccountChannelRequest:request-vardict must be set to a non-%NULL
   * value, and the other must remain unspecified.
   *
   * Since: 0.19.10
   */
  param_spec = g_param_spec_variant ("request-vardict", "Request",
      "A dictionary containing desirable properties for the channel",
      G_VARIANT_TYPE_VARDICT, NULL,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_REQUEST_VARDICT,
      param_spec);

  /**
   * TpAccountChannelRequest:user-action-time:
   *
   * The user action time that will be passed to the channel dispatcher when
   * requesting the channel.
   *
   * This may be the time at which user action occurred, or one of the special
   * values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
   * %TP_USER_ACTION_TIME_CURRENT_TIME.
   *
   * If %TP_USER_ACTION_TIME_NOT_USER_ACTION, the action doesn't involve any
   * user action. Clients should avoid stealing focus when presenting the
   * channel.
   *
   * If %TP_USER_ACTION_TIME_CURRENT_TIME, clients SHOULD behave as though the
   * user action happened at the current time, e.g. a client may
   * request that its window gains focus.
   *
   * On X11-based systems, GDK 2, GDK 3, Clutter 1.0 etc.,
   * tp_user_action_time_from_x11() can be used to convert an X11 timestamp to
   * a Telepathy user action time.
   *
   * If the channel request succeeds, this user action time will be passed on
   * to the channel's handler. If the handler is a GUI, it may use
   * tp_user_action_time_should_present() to decide whether to bring its
   * window to the foreground.
   *
   * Since: 0.11.12
   */
  param_spec = g_param_spec_int64 ("user-action-time", "user action time",
      "UserActionTime",
      G_MININT64, G_MAXINT64, 0,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_USER_ACTION_TIME,
      param_spec);

  /**
   * TpAccountChannelRequest:channel-request:
   *
   * The #TpChannelRequest used to request the channel, or %NULL if the
   * channel has not be requested yet.
   *
   * This can be useful for example to compare with the #TpChannelRequest
   * objects received from the requests_satisfied argument of
   * #TpSimpleHandlerHandleChannelsImpl to check if the client is asked to
   * handle the channel it just requested.
   *
   * Note that the #TpChannelRequest objects may be different while still
   * representing the same ChannelRequest on D-Bus. You have to compare
   * them using their object paths (tp_proxy_get_object_path()).
   *
   * Since 0.13.13
   */
  param_spec = g_param_spec_object ("channel-request", "channel request",
      "TpChannelRequest",
      TP_TYPE_CHANNEL_REQUEST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CHANNEL_REQUEST,
      param_spec);

 /**
   * TpAccountChannelRequest::re-handled:
   * @self: a #TpAccountChannelRequest
   * @channel: the #TpChannel being re-handled
   * @user_action_time: the time at which user action occurred, or one of the
   *  special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
   *  %TP_USER_ACTION_TIME_CURRENT_TIME; see
   *  #TpAccountChannelRequest:user-action-time
   * @context: a #TpHandleChannelsContext representing the context of
   * the HandleChannels() call.
   *
   * Emitted when the channel created using @self has been "re-handled".
   *
   * This means that a Telepathy client has made another request for a
   * matching channel using an "ensure" API like
   * tp_account_channel_request_ensure_channel_async(), while the channel
   * still exists. Instead of creating a new channel, the channel dispatcher
   * notifies the existing handler of @channel, resulting in this signal.
   *
   * Most GUI handlers should respond to this signal by checking
   * @user_action_time, and if appropriate, moving to the foreground.
   *
   * @context can be used to obtain extensible information about the channel
   * via tp_handle_channels_context_get_handler_info(), and any similar methods
   * that are added in future. It is not valid for the receiver of this signal
   * to call tp_handle_channels_context_accept(),
   * tp_handle_channels_context_delay() or tp_handle_channels_context_fail().
   *
   * Since: 0.11.12
   */
  signals[SIGNAL_RE_HANDLED] = g_signal_new (
      "re-handled", G_OBJECT_CLASS_TYPE (cls),
      G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 3, TP_TYPE_CHANNEL, G_TYPE_INT64,
      TP_TYPE_HANDLE_CHANNELS_CONTEXT);
}

/**
 * tp_account_channel_request_new:
 * @account: a #TpAccount
 * @request: (transfer none) (element-type utf8 GObject.Value): the requested
 *  properties of the channel (see #TpAccountChannelRequest:request)
 * @user_action_time: the time of the user action that caused this request,
 *  or one of the special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
 *  %TP_USER_ACTION_TIME_CURRENT_TIME (see
 *  #TpAccountChannelRequest:user-action-time)
 *
 * Convenience function to create a new #TpAccountChannelRequest object.
 *
 * Returns: a new #TpAccountChannelRequest object
 *
 * Since: 0.11.12
 */
TpAccountChannelRequest *
tp_account_channel_request_new (
    TpAccount *account,
    GHashTable *request,
    gint64 user_action_time)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);
  g_return_val_if_fail (request != NULL, NULL);

  return g_object_new (TP_TYPE_ACCOUNT_CHANNEL_REQUEST,
      "account", account,
      "request", request,
      "user-action-time", user_action_time,
      NULL);
}

/**
 * tp_account_channel_request_new_vardict:
 * @account: a #TpAccount
 * @request: the requested
 *  properties of the channel (see #TpAccountChannelRequest:request)
 *  as a %G_VARIANT_TYPE_VARDICT
 * @user_action_time: the time of the user action that caused this request,
 *  or one of the special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
 *  %TP_USER_ACTION_TIME_CURRENT_TIME (see
 *  #TpAccountChannelRequest:user-action-time)
 *
 * Convenience function to create a new #TpAccountChannelRequest object.
 *
 * If @request is a floating reference, this function will
 * take ownership of it, much like g_variant_ref_sink(). See documentation of
 * that function for details.
 *
 * Returns: a new #TpAccountChannelRequest object
 *
 * Since: 0.19.10
 */
TpAccountChannelRequest *
tp_account_channel_request_new_vardict (
    TpAccount *account,
    GVariant *request,
    gint64 user_action_time)
{
  TpAccountChannelRequest *ret;

  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);
  g_return_val_if_fail (request != NULL, NULL);
  g_return_val_if_fail (g_variant_is_of_type (request, G_VARIANT_TYPE_VARDICT),
      NULL);

  g_variant_ref_sink (request);

  ret = g_object_new (TP_TYPE_ACCOUNT_CHANNEL_REQUEST,
      "account", account,
      "request-vardict", request,
      "user-action-time", user_action_time,
      NULL);
  g_variant_unref (request);
  return ret;
}

/**
 * tp_account_channel_request_get_account:
 * @self: a #TpAccountChannelRequest
 *
 * Return the #TpAccountChannelRequest:account construct-only property
 *
 * Returns: (transfer none): the value of #TpAccountChannelRequest:account
 *
 * Since: 0.11.12
 */
TpAccount *
tp_account_channel_request_get_account (
    TpAccountChannelRequest *self)
{
  return self->priv->account;
}

/**
 * tp_account_channel_request_get_request:
 * @self: a #TpAccountChannelRequest
 *
 * Return the #TpAccountChannelRequest:request construct-only property
 *
 * Returns: (transfer none): the value of #TpAccountChannelRequest:request
 *
 * Since: 0.11.12
 */
GHashTable *
tp_account_channel_request_get_request (
    TpAccountChannelRequest *self)
{
  return self->priv->request;
}

/**
 * tp_account_channel_request_dup_request:
 * @self: a #TpAccountChannelRequest
 *
 * Return the #TpAccountChannelRequest:request-vardict construct-only
 * property.
 *
 * Returns: (transfer full): the value of
 *  #TpAccountChannelRequest:request-vardict
 *
 * Since: 0.19.10
 */
GVariant *
tp_account_channel_request_dup_request (
    TpAccountChannelRequest *self)
{
  g_return_val_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self), NULL);

  return _tp_asv_to_vardict (self->priv->request);
}

/**
 * tp_account_channel_request_get_user_action_time:
 * @self: a #TpAccountChannelRequest
 *
 * Return the #TpAccountChannelRequest:user-action-time construct-only property
 *
 * Returns: the value of #TpAccountChannelRequest:user-action-time
 *
 * Since: 0.11.12
 */
gint64
tp_account_channel_request_get_user_action_time (
    TpAccountChannelRequest *self)
{
  return self->priv->user_action_time;
}

static void
complete_result (TpAccountChannelRequest *self)
{
  g_assert (self->priv->result != NULL);

  request_disconnect (self);

  g_simple_async_result_complete_in_idle (self->priv->result);

  tp_clear_object (&self->priv->result);
}

static void
request_fail (TpAccountChannelRequest *self,
    const GError *error)
{
  g_simple_async_result_set_from_error (self->priv->result, error);
  complete_result (self);
}

static void
handle_request_complete (TpAccountChannelRequest *self,
    TpChannel *channel,
    TpHandleChannelsContext *handle_context)
{
  self->priv->channel = g_object_ref (channel);
  self->priv->handle_context = g_object_ref (handle_context);

  complete_result (self);
}

static void
acr_channel_invalidated_cb (TpProxy *chan,
    guint domain,
    gint code,
    gchar *message,
    TpAccountChannelRequest *self)
{
  /* Channel has been destroyed, we can remove the Handler */
  DEBUG ("Channel has been invalidated (%s), unref ourself", message);
  g_object_unref (self);
}

static void
handle_channels (TpSimpleHandler *handler,
    TpAccount *account,
    TpConnection *connection,
    GList *channels,
    GList *requests_satisfied,
    gint64 user_action_time,
    TpHandleChannelsContext *context,
    gpointer user_data)
{
  TpAccountChannelRequest *self = user_data;
  TpChannel *channel;

  if (G_UNLIKELY (g_list_length (channels) != 1))
    {
      GError error = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "We are supposed to handle only one channel" };

      tp_handle_channels_context_fail (context, &error);

      request_fail (self, &error);
      return;
    }

  tp_handle_channels_context_accept (context);

  if (self->priv->result == NULL)
    {
      /* We are re-handling the channel, no async request to complete */
      g_signal_emit (self, signals[SIGNAL_RE_HANDLED], 0, self->priv->channel,
          user_action_time, context);

      return;
    }

  /* Request succeeded */
  channel = channels->data;

  if (tp_proxy_get_invalidated (channel) == NULL)
    {
      /* Keep the handler alive while the channel is valid so keep a ref on
       * ourself until the channel is invalidated */
      g_object_ref (self);

      g_signal_connect (channel, "invalidated",
          G_CALLBACK (acr_channel_invalidated_cb), self);
    }

  handle_request_complete (self, channel, context);
}

static void
channel_prepare_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpAccountChannelRequest *self = user_data;
  GError *error = NULL;

  if (!tp_proxy_prepare_finish (source, result, &error))
    {
      DEBUG ("Failed to prepare channel: %s", error->message);
      g_error_free (error);
    }

  g_simple_async_result_set_op_res_gpointer (self->priv->result,
    g_object_ref (source), g_object_unref);

  complete_result (self);
}

static void
acr_channel_request_proceed_cb (TpChannelRequest *request,
  const GError *error,
  gpointer user_data,
  GObject *weak_object)
{
  TpAccountChannelRequest *self = user_data;

  if (error != NULL)
    {
      DEBUG ("Proceed failed: %s", error->message);

      request_fail (self, error);
      return;
    }

  if (self->priv->action_type == ACTION_TYPE_HANDLE)
    DEBUG ("Proceed succeeded; waiting for the channel to be handled");
  else
    DEBUG ("Proceed succeeded; waiting for the Succeeded signal");
}

static void
acr_channel_request_invalidated_cb (TpProxy *proxy,
    guint domain,
    gint code,
    gchar *message,
    TpAccountChannelRequest *self)
{
  GError error = { domain, code, message };

  if (g_error_matches (&error, TP_DBUS_ERRORS, TP_DBUS_ERROR_OBJECT_REMOVED))
    {
      /* Object has been removed without error, so ChannelRequest succeeded */
      return;
    }

  DEBUG ("ChannelRequest has been invalidated: %s", message);

  request_fail (self, &error);
}

static void
acr_channel_request_succeeded_with_channel (TpChannelRequest *chan_req,
    TpConnection *connection,
    TpChannel *channel,
    TpAccountChannelRequest *self)
{
  if (channel != NULL)
    self->priv->channel = g_object_ref (channel);

  /* ChannelRequest succeeded */
  if (self->priv->action_type == ACTION_TYPE_HANDLE)
    {
      GError err = { TP_ERROR, TP_ERROR_NOT_YOURS,
          "Another Handler is handling this channel" };

      if (self->priv->result == NULL)
        /* Our handler has been called, all good */
        return;

      /* Our handler hasn't be called but the channel request is complete.
       * That means another handler handled the channels so we don't own it. */
      request_fail (self, &err);
    }
  else if (self->priv->action_type == ACTION_TYPE_OBSERVE)
    {
      GArray *features;

      if (self->priv->channel == NULL)
        {
          GError err = { TP_ERROR, TP_ERROR_CONFUSED,
              "Channel has been created but MC didn't give it back to us" };

          DEBUG ("%s", err.message);

          request_fail (self, &err);
          return;
        }

      /* Operation will be complete once the channel have been prepared */
      if (self->priv->factory != NULL)
        features = tp_client_channel_factory_dup_channel_features (
            self->priv->factory, self->priv->channel);
      else
        features = tp_simple_client_factory_dup_channel_features (
            tp_proxy_get_factory (self->priv->account), self->priv->channel);
      g_assert (features != NULL);

      tp_proxy_prepare_async (self->priv->channel, (GQuark *) features->data,
          channel_prepare_cb, self);

      g_array_unref (features);
    }
  else
    {
      /* We don't have to handle the channel so we're done */
      complete_result (self);
    }
}

static void
acr_channel_request_cancel_cb (TpChannelRequest *request,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  /* Don't do anything, we rely on the invalidation of the channel request to
   * complete the operation */
  if (error != NULL)
    {
      DEBUG ("ChannelRequest.Cancel() failed: %s", error->message);
      return;
    }

  DEBUG ("ChannelRequest.Cancel() succeeded");
}

static void
acr_operation_cancelled_cb (GCancellable *cancellable,
    TpAccountChannelRequest *self)
{
  if (self->priv->chan_request == NULL)
    {
      DEBUG ("ChannelRequest has been invalidated, we can't cancel any more");
      return;
    }

  DEBUG ("Operation has been cancelled, cancel the channel request");

  tp_cli_channel_request_call_cancel (self->priv->chan_request, -1,
      acr_channel_request_cancel_cb, self, NULL, G_OBJECT (self));
}

static void
acr_request_cb (TpChannelDispatcher *cd,
    const gchar *channel_request_path,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpAccountChannelRequest *self = user_data;
  GError *err = NULL;

  if (error != NULL)
    {
      DEBUG ("%s failed: %s",
          self->priv->ensure ? "EnsureChannel" : "CreateChannel",
          error->message);

      request_fail (self, error);
      return;
    }

  DEBUG ("Got ChannelRequest: %s", channel_request_path);

  self->priv->chan_request = _tp_simple_client_factory_ensure_channel_request (
      tp_proxy_get_factory (self->priv->account), channel_request_path, NULL,
      &err);
  if (self->priv->chan_request == NULL)
    {
      DEBUG ("Failed to create ChannelRequest: %s", err->message);
      goto fail;
    }

  _tp_channel_request_set_channel_factory (self->priv->chan_request,
      self->priv->factory);

  self->priv->invalidated_sig = g_signal_connect (self->priv->chan_request,
      "invalidated", G_CALLBACK (acr_channel_request_invalidated_cb), self);

  self->priv->succeeded_chan_sig = g_signal_connect (self->priv->chan_request,
      "succeeded-with-channel",
      G_CALLBACK (acr_channel_request_succeeded_with_channel), self);

  if (self->priv->cancellable != NULL)
    {
      self->priv->cancel_id = g_cancellable_connect (self->priv->cancellable,
          G_CALLBACK (acr_operation_cancelled_cb), self, NULL);

      /* We just aborted the operation so we're done */
      if (g_cancellable_is_cancelled (self->priv->cancellable))
        return;
    }

  DEBUG ("Calling ChannelRequest.Proceed()");

  tp_cli_channel_request_call_proceed (self->priv->chan_request, -1,
      acr_channel_request_proceed_cb, self, NULL, G_OBJECT (self));

  return;

fail:
  request_fail (self, err);
  g_error_free (err);
}

static void
delegated_channels_cb (TpBaseClient *client,
    GPtrArray *channels,
    gpointer user_data)
{
  TpAccountChannelRequest *self = user_data;
  TpChannel *channel;

  g_return_if_fail (channels->len == 1);

  /* TpBaseClient is supposed to check we are actually handling the channel
   * before calling this callback so we can assert that's the right one. */
  channel = g_ptr_array_index (channels, 0);
  g_return_if_fail (TP_IS_CHANNEL (channel));
  g_return_if_fail (!tp_strdiff (tp_proxy_get_object_path (channel),
      tp_proxy_get_object_path (self->priv->channel)));

  self->priv->delegated_channel_cb (self, channel,
      self->priv->delegated_channel_data);
}

static gboolean
going_to_request (TpAccountChannelRequest *self,
    ActionType action_type,
    gboolean ensure,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  g_return_val_if_fail (!self->priv->requested, FALSE);
  self->priv->requested = TRUE;

  self->priv->action_type = action_type;

  if (g_cancellable_is_cancelled (cancellable))
    {
      g_simple_async_report_error_in_idle (G_OBJECT (self), callback,
          user_data, G_IO_ERROR, G_IO_ERROR_CANCELLED,
          "Operation has been cancelled");
      return FALSE;
    }

  if (cancellable != NULL)
    self->priv->cancellable = g_object_ref (cancellable);

  self->priv->ensure = ensure;

  /* Set TargetHandleType: TP_HANDLE_TYPE_NONE if no TargetHandleType has been
   * defined. */
  if (g_hash_table_lookup (self->priv->request,
        TP_PROP_CHANNEL_TARGET_HANDLE_TYPE) == NULL)
    {
      g_hash_table_insert (self->priv->request,
          g_strdup (TP_PROP_CHANNEL_TARGET_HANDLE_TYPE),
          tp_g_value_slice_new_uint (TP_HANDLE_TYPE_NONE));
    }

  return TRUE;
}

static void
request_and_handle_channel_async (TpAccountChannelRequest *self,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data,
    gboolean ensure)
{
  GError *error = NULL;
  TpChannelDispatcher *cd;

  if (!going_to_request (self, ACTION_TYPE_HANDLE, ensure, cancellable,
        callback, user_data))
    return;

  /* Create a temp handler */
  self->priv->handler = tp_simple_handler_new_with_factory (
      tp_proxy_get_factory (self->priv->account), TRUE, FALSE,
      "TpGLibRequestAndHandle", TRUE, handle_channels, self, NULL);
  _tp_base_client_set_only_for_account (self->priv->handler,
      self->priv->account);

  _tp_base_client_set_channel_factory (self->priv->handler,
      self->priv->factory);

  if (self->priv->delegated_channel_cb != NULL)
    {
      tp_base_client_set_delegated_channels_callback (self->priv->handler,
          delegated_channels_cb, self, NULL);
    }

  if (!tp_base_client_register (self->priv->handler, &error))
    {
      DEBUG ("Failed to register temp handler: %s", error->message);

      g_simple_async_report_gerror_in_idle (G_OBJECT (self), callback,
          user_data, error);

      g_error_free (error);
      return;
    }

  cd = tp_channel_dispatcher_new (self->priv->dbus);

  if (ensure)
    {
      self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
          user_data,
          tp_account_channel_request_ensure_and_handle_channel_async);

      if (self->priv->hints == NULL)
        {
          tp_cli_channel_dispatcher_call_ensure_channel (cd, -1,
              tp_proxy_get_object_path (self->priv->account),
              self->priv->request, self->priv->user_action_time,
              tp_base_client_get_bus_name (self->priv->handler),
              acr_request_cb, self, NULL, G_OBJECT (self));
        }
      else
        {
          tp_cli_channel_dispatcher_call_ensure_channel_with_hints (cd, -1,
              tp_proxy_get_object_path (self->priv->account),
              self->priv->request, self->priv->user_action_time,
              tp_base_client_get_bus_name (self->priv->handler),
              self->priv->hints,
              acr_request_cb, self, NULL, G_OBJECT (self));
        }
    }
  else
    {
      self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
          user_data,
          tp_account_channel_request_create_and_handle_channel_async);

      if (self->priv->hints == NULL)
        {
          tp_cli_channel_dispatcher_call_create_channel (cd, -1,
              tp_proxy_get_object_path (self->priv->account),
              self->priv->request,
              self->priv->user_action_time,
              tp_base_client_get_bus_name (self->priv->handler),
              acr_request_cb, self, NULL, G_OBJECT (self));
        }
      else
        {
          tp_cli_channel_dispatcher_call_create_channel_with_hints (cd, -1,
              tp_proxy_get_object_path (self->priv->account),
              self->priv->request,
              self->priv->user_action_time,
              tp_base_client_get_bus_name (self->priv->handler),
              self->priv->hints,
              acr_request_cb, self, NULL, G_OBJECT (self));
        }
    }

  g_object_unref (cd);
}

static TpChannel *
request_and_handle_channel_finish (TpAccountChannelRequest *self,
    GAsyncResult *result,
    TpHandleChannelsContext **context,
    gpointer source_tag,
    GError **error)
{
  GSimpleAsyncResult *simple;

  g_return_val_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self), NULL);
  g_return_val_if_fail (G_IS_SIMPLE_ASYNC_RESULT (result), NULL);

  simple = G_SIMPLE_ASYNC_RESULT (result);

  if (g_simple_async_result_propagate_error (simple, error))
    return FALSE;

  g_return_val_if_fail (g_simple_async_result_is_valid (result,
          G_OBJECT (self), source_tag),
      NULL);

  if (context != NULL)
    *context = g_object_ref (self->priv->handle_context);

  return g_object_ref (self->priv->channel);
}

/**
 * tp_account_channel_request_create_and_handle_channel_async:
 * @self: a #TpAccountChannelRequest
 * @cancellable: optional #GCancellable object, %NULL to ignore
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Asynchronously calls CreateChannel on the ChannelDispatcher to create a
 * channel with the properties defined in #TpAccountChannelRequest:request
 * that you are going to handle yourself.
 * When the operation is finished, @callback will be called. You can then call
 * tp_account_channel_request_create_and_handle_channel_finish() to get the
 * result of the operation.
 *
 * (Behind the scenes, this works by creating a temporary #TpBaseClient, then
 * acting like tp_account_channel_request_create_channel_async() with the
 * temporary #TpBaseClient as the @preferred_handler.)
 *
 * The caller is responsible for closing the channel with
 * tp_cli_channel_call_close() when it has finished handling it.
 *
 * Since: 0.11.12
 */
void
tp_account_channel_request_create_and_handle_channel_async (
    TpAccountChannelRequest *self,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  request_and_handle_channel_async (self, cancellable, callback, user_data,
      FALSE);
}

/**
 * tp_account_channel_request_create_and_handle_channel_finish:
 * @self: a #TpAccountChannelRequest
 * @result: a #GAsyncResult
 * @context: (out) (allow-none) (transfer full): pointer used to return a
 *  reference to the context of the HandleChannels() call, or %NULL
 * @error: a #GError to fill
 *
 * Finishes an async channel creation started using
 * tp_account_channel_request_create_and_handle_channel_async().
 *
 * See tp_account_channel_request_ensure_and_handle_channel_finish()
 * for details of how @context can be used.
 *
 * The caller is responsible for closing the channel with
 * tp_cli_channel_call_close() when it has finished handling it.
 *
 * Returns: (transfer full) (allow-none): a new reference on a #TpChannel if the
 * channel was successfully created and you are handling it, otherwise %NULL.
 *
 * Since: 0.11.12
 */
TpChannel *
tp_account_channel_request_create_and_handle_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    TpHandleChannelsContext **context,
    GError **error)
{
  return request_and_handle_channel_finish (self, result, context,
      tp_account_channel_request_create_and_handle_channel_async, error);
}

/**
 * tp_account_channel_request_ensure_and_handle_channel_async:
 * @self: a #TpAccountChannelRequest
 * @cancellable: optional #GCancellable object, %NULL to ignore
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Asynchronously calls EnsureChannel on the ChannelDispatcher to create a
 * channel with the properties defined in #TpAccountChannelRequest:request
 * that you are going to handle yourself.
 * When the operation is finished, @callback will be called. You can then call
 * tp_account_channel_request_ensure_and_handle_channel_finish() to get the
 * result of the operation.
 *
 * If the channel already exists and is already being handled, or if a
 * newly created channel is sent to a different handler, this operation
 * will fail with the error %TP_ERROR_NOT_YOURS. The other handler
 * will be notified that the channel was requested again (for instance
 * with #TpAccountChannelRequest::re-handled,
 * #TpBaseClientClassHandleChannelsImpl or #TpSimpleHandler:callback),
 * and can move its window to the foreground, if applicable.
 *
 * (Behind the scenes, this works by creating a temporary #TpBaseClient, then
 * acting like tp_account_channel_request_ensure_channel_async() with the
 * temporary #TpBaseClient as the @preferred_handler.)
 *
 * Since: 0.11.12
 */
void
tp_account_channel_request_ensure_and_handle_channel_async (
    TpAccountChannelRequest *self,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  request_and_handle_channel_async (self, cancellable, callback, user_data,
      TRUE);
}

/**
 * tp_account_channel_request_ensure_and_handle_channel_finish:
 * @self: a #TpAccountChannelRequest
 * @result: a #GAsyncResult
 * @context: (out) (allow-none) (transfer full): pointer used to return a
 *  reference to the context of the HandleChannels() call, or %NULL
 * @error: a #GError to fill
 *
 * Finishes an async channel creation started using
 * tp_account_channel_request_ensure_and_handle_channel_async().
 *
 * If the channel already exists and is already being handled, or if a
 * newly created channel is sent to a different handler, this operation
 * will fail with the error %TP_ERROR_NOT_YOURS.
 *
 * @context can be used to obtain extensible information about the channel
 * via tp_handle_channels_context_get_handler_info(), and any similar methods
 * that are added in future. It is not valid for the caller of this method
 * to call tp_handle_channels_context_accept(),
 * tp_handle_channels_context_delay() or tp_handle_channels_context_fail().
 *
 * Returns: (transfer full) (allow-none): a new reference on a #TpChannel if the
 * channel was successfully created and you are handling it, otherwise %NULL.
 *
 * Since: 0.11.12
 */
TpChannel *
tp_account_channel_request_ensure_and_handle_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    TpHandleChannelsContext **context,
    GError **error)
{
  return request_and_handle_channel_finish (self, result, context,
      tp_account_channel_request_ensure_and_handle_channel_async, error);
}

/* Request and forget API */

static void
request_channel_async (TpAccountChannelRequest *self,
    const gchar *preferred_handler,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data,
    gboolean ensure)
{
  TpChannelDispatcher *cd;

  if (!going_to_request (self, ACTION_TYPE_FORGET, ensure, cancellable,
        callback, user_data))
    return;

  cd = tp_channel_dispatcher_new (self->priv->dbus);

  if (ensure)
    {
      self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
          user_data, tp_account_channel_request_ensure_channel_async);

      if (self->priv->hints == NULL)
        {
          tp_cli_channel_dispatcher_call_ensure_channel (cd, -1,
              tp_proxy_get_object_path (self->priv->account),
              self->priv->request,
              self->priv->user_action_time,
              preferred_handler == NULL ? "" : preferred_handler,
              acr_request_cb, self, NULL, G_OBJECT (self));
        }
      else
        {
          tp_cli_channel_dispatcher_call_ensure_channel_with_hints (cd, -1,
              tp_proxy_get_object_path (self->priv->account),
              self->priv->request,
              self->priv->user_action_time,
              preferred_handler == NULL ? "" : preferred_handler,
              self->priv->hints,
              acr_request_cb, self, NULL, G_OBJECT (self));
        }
    }
  else
    {
      self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
          user_data, tp_account_channel_request_create_channel_async);

      if (self->priv->hints == NULL)
        {
          tp_cli_channel_dispatcher_call_create_channel (cd, -1,
              tp_proxy_get_object_path (self->priv->account),
              self->priv->request,
              self->priv->user_action_time,
              preferred_handler == NULL ? "" : preferred_handler,
              acr_request_cb, self, NULL, G_OBJECT (self));
        }
      else
        {
          tp_cli_channel_dispatcher_call_create_channel_with_hints (cd, -1,
              tp_proxy_get_object_path (self->priv->account),
              self->priv->request,
              self->priv->user_action_time,
              preferred_handler == NULL ? "" : preferred_handler,
              self->priv->hints,
              acr_request_cb, self, NULL, G_OBJECT (self));
        }
    }

  g_object_unref (cd);
}

/**
 * tp_account_channel_request_create_channel_async:
 * @self: a #TpAccountChannelRequest
 * @preferred_handler: Either the well-known bus name (starting with
 * %TP_CLIENT_BUS_NAME_BASE) of the preferred handler for the channel,
 * or %NULL to indicate that any handler would be acceptable.
 * @cancellable: optional #GCancellable object, %NULL to ignore
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Asynchronously calls CreateChannel on the ChannelDispatcher to create a
 * channel with the properties defined in #TpAccountChannelRequest:request
 * and let the ChannelDispatcher dispatch it to an handler.
 * @callback will be called when the channel has been created and dispatched,
 * or the request has failed.
 * You can then call tp_account_channel_request_create_channel_finish() to
 * get the result of the operation.
 *
 * Since: 0.11.12
 */
void
tp_account_channel_request_create_channel_async (
    TpAccountChannelRequest *self,
    const gchar *preferred_handler,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  request_channel_async (self, preferred_handler, cancellable, callback,
      user_data, FALSE);
}

static gboolean
request_channel_finish (TpAccountChannelRequest *self,
    GAsyncResult *result,
    gpointer source_tag,
    GError **error)
{
  _tp_implement_finish_void (self, source_tag);
}

/**
 * tp_account_channel_request_create_channel_finish:
 * @self: a #TpAccountChannelRequest
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async channel creation started using
 * tp_account_channel_request_create_channel_async().
 *
 * Returns: %TRUE if the channel was successfully created and dispatched,
 * otherwise %FALSE.
 *
 * Since: 0.11.12
 */
gboolean
tp_account_channel_request_create_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    GError **error)
{
  return request_channel_finish (self, result,
      tp_account_channel_request_create_channel_async, error);
}

/**
 * tp_account_channel_request_ensure_channel_async:
 * @self: a #TpAccountChannelRequest
 * @preferred_handler: Either the well-known bus name (starting with
 * %TP_CLIENT_BUS_NAME_BASE) of the preferred handler for the channel,
 * or %NULL to indicate that any handler would be acceptable.
 * @cancellable: optional #GCancellable object, %NULL to ignore
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Asynchronously calls EnsureChannel on the ChannelDispatcher to create a
 * channel with the properties defined in #TpAccountChannelRequest:request
 * and let the ChannelDispatcher dispatch it to an handler.
 *
 * If a suitable channel already existed, its handler will be notified that
 * the channel was requested again (for instance with
 * #TpAccountChannelRequest::re-handled, #TpBaseClientClassHandleChannelsImpl
 * or #TpSimpleHandler:callback, if it is implemented using Telepathy-GLib),
 * so that it can re-present the window to the user, for example.
 * Otherwise, a new channel will be created and dispatched to a handler.
 *
 * @callback will be called when an existing channel's handler has been
 * notified, a new channel has been created and dispatched, or the request
 * has failed.
 * You can then call tp_account_channel_request_ensure_channel_finish() to
 * get the result of the operation.
 *
 * Since: 0.11.12
 */
void
tp_account_channel_request_ensure_channel_async (
    TpAccountChannelRequest *self,
    const gchar *preferred_handler,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  request_channel_async (self, preferred_handler, cancellable, callback,
      user_data, TRUE);
}

/**
 * tp_account_channel_request_ensure_channel_finish:
 * @self: a #TpAccountChannelRequest
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async channel creation started using
 * tp_account_channel_request_ensure_channel_async().
 *
 * Returns: %TRUE if the channel was successfully ensured and (re-)dispatched,
 * otherwise %FALSE.
 *
 * Since: 0.11.12
 */
gboolean
tp_account_channel_request_ensure_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    GError **error)
{
  return request_channel_finish (self, result,
      tp_account_channel_request_ensure_channel_async, error);
}

/**
 * tp_account_channel_request_set_channel_factory:
 * @self: a #TpAccountChannelRequest
 * @factory: a #TpClientChannelFactory
 *
 * Set @factory as the #TpClientChannelFactory that will be used to
 * create the channel requested by @self.
 * By default #TpAutomaticProxyFactory is used.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.13.2
 * Deprecated: since 0.15.5. The factory is taken from
 *  #TpAccountChannelRequest:account.
 */
void
tp_account_channel_request_set_channel_factory (TpAccountChannelRequest *self,
    TpClientChannelFactory *factory)
{
  _tp_account_channel_request_set_channel_factory (self, factory);
}

void
_tp_account_channel_request_set_channel_factory (TpAccountChannelRequest *self,
    TpClientChannelFactory *factory)
{
  g_return_if_fail (!self->priv->requested);

  tp_clear_object (&self->priv->factory);

  if (factory != NULL)
    self->priv->factory = g_object_ref (factory);
}


/**
 * tp_account_channel_request_get_channel_request:
 * @self: a #TpAccountChannelRequest
 *
 * Return the #TpAccountChannelRequest:channel-request property
 *
 * Returns: (transfer none): the value of
 * #TpAccountChannelRequest:channel-request
 *
 * Since: 0.13.13
 */
TpChannelRequest *
tp_account_channel_request_get_channel_request (TpAccountChannelRequest *self)
{
  return self->priv->chan_request;
}

static void
request_and_observe_channel_async (TpAccountChannelRequest *self,
    const gchar *preferred_handler,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data,
    gboolean ensure)
{
  TpChannelDispatcher *cd;

  if (!going_to_request (self, ACTION_TYPE_OBSERVE, ensure, cancellable,
        callback, user_data))
    return;

  cd = tp_channel_dispatcher_new (self->priv->dbus);

  if (self->priv->hints == NULL)
    self->priv->hints = g_hash_table_new (NULL, NULL);

  if (ensure)
    {
      self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
          user_data,
          tp_account_channel_request_ensure_and_observe_channel_async);

      tp_cli_channel_dispatcher_call_ensure_channel_with_hints (cd, -1,
          tp_proxy_get_object_path (self->priv->account), self->priv->request,
          self->priv->user_action_time,
          preferred_handler == NULL ? "" : preferred_handler,
          self->priv->hints,
          acr_request_cb, self, NULL, G_OBJECT (self));
    }
  else
    {
      self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
          user_data,
          tp_account_channel_request_create_and_observe_channel_async);

      tp_cli_channel_dispatcher_call_create_channel_with_hints (cd, -1,
          tp_proxy_get_object_path (self->priv->account), self->priv->request,
          self->priv->user_action_time,
          preferred_handler == NULL ? "" : preferred_handler,
          self->priv->hints,
          acr_request_cb, self, NULL, G_OBJECT (self));
    }

  g_object_unref (cd);
}

/**
 * tp_account_channel_request_create_and_observe_channel_async:
 * @self: a #TpAccountChannelRequest
 * @preferred_handler: Either the well-known bus name (starting with
 * %TP_CLIENT_BUS_NAME_BASE) of the preferred handler for the channel,
 * or %NULL to indicate that any handler would be acceptable.
 * @cancellable: optional #GCancellable object, %NULL to ignore
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Asynchronously calls CreateChannel on the ChannelDispatcher to create a
 * channel with the properties defined in #TpAccountChannelRequest:request
 * and let the ChannelDispatcher dispatch it to an handler.
 * @callback will be called when the channel has been created and dispatched,
 * or the request has failed.
 * You can then call tp_account_channel_request_create_channel_finish() to
 * get the result of the operation and a #TpChannel representing the channel
 * which has been created. Note that you are <emphasis>not</emphasis> handling
 * this channel and so should interact with the channel as an Observer.
 * See <ulink url="http://telepathy.freedesktop.org/doc/book/sect.channel-dispatcher.clients.html">
 * the Telepathy book</ulink> for details about how clients should interact
 * with channels.
 *
 * Since: 0.13.14
 */
void
tp_account_channel_request_create_and_observe_channel_async (
    TpAccountChannelRequest *self,
    const gchar *preferred_handler,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  request_and_observe_channel_async (self, preferred_handler, cancellable,
      callback, user_data, FALSE);
}

/**
 * tp_account_channel_request_create_and_observe_channel_finish:
 * @self: a #TpAccountChannelRequest
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async channel creation started using
 * tp_account_channel_request_create_and_observe_channel_async().
 *
 * Returns: (transfer full): a newly created #TpChannel if the channel was
 * successfully created and dispatched, otherwise %NULL.
 *
 * Since: 0.13.14
 */
TpChannel *
tp_account_channel_request_create_and_observe_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_account_channel_request_create_and_observe_channel_async,
      g_object_ref);
}

/**
 * tp_account_channel_request_ensure_and_observe_channel_async:
 * @self: a #TpAccountChannelRequest
 * @preferred_handler: Either the well-known bus name (starting with
 * %TP_CLIENT_BUS_NAME_BASE) of the preferred handler for the channel,
 * or %NULL to indicate that any handler would be acceptable.
 * @cancellable: optional #GCancellable object, %NULL to ignore
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Asynchronously calls EnsureChannel on the ChannelDispatcher to create a
 * channel with the properties defined in #TpAccountChannelRequest:request
 * and let the ChannelDispatcher dispatch it to an handler.
 * @callback will be called when the channel has been created and dispatched,
 * or the request has failed.
 * You can then call tp_account_channel_request_create_channel_finish() to
 * get the result of the operation and a #TpChannel representing the channel
 * which has been created. Note that you are <emphasis>not</emphasis> handling
 * this channel and so should interact with the channel as an Observer.
 * See <ulink url="http://telepathy.freedesktop.org/doc/book/sect.channel-dispatcher.clients.html">
 * the Telepathy book</ulink> for details about how clients should interact
 * with channels.
 *
 * If a suitable channel already existed, its handler will be notified that
 * the channel was requested again (for instance with
 * #TpAccountChannelRequest::re-handled, #TpBaseClientClassHandleChannelsImpl
 * or #TpSimpleHandler:callback, if it is implemented using Telepathy-GLib),
 * so that it can re-present the window to the user, for example.
 * Otherwise, a new channel will be created and dispatched to a handler.
 *
 * Since: 0.13.14
 */
void
tp_account_channel_request_ensure_and_observe_channel_async (
    TpAccountChannelRequest *self,
    const gchar *preferred_handler,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  request_and_observe_channel_async (self, preferred_handler, cancellable,
      callback, user_data, TRUE);
}

/**
 * tp_account_channel_request_ensure_and_observe_channel_finish:
 * @self: a #TpAccountChannelRequest
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async channel creation started using
 * tp_account_channel_request_create_and_observe_channel_async().
 *
 * Returns: (transfer full): a newly created #TpChannel if the channel was
 * successfully ensure and (re-)dispatched, otherwise %NULL.
 *
 * Since: 0.13.14
 */
TpChannel *
tp_account_channel_request_ensure_and_observe_channel_finish (
    TpAccountChannelRequest *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_account_channel_request_ensure_and_observe_channel_async,
      g_object_ref);
}

/**
 * tp_account_channel_request_set_hint:
 * @self: a #TpAccountChannelRequest
 * @key: the key used for the hint
 * @value: (transfer none): a variant containting the hint value
 *
 * Set additional information about the channel request, which will be used
 * in the resulting request's #TpChannelRequest:hints property.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.19.8
 */
void
tp_account_channel_request_set_hint (TpAccountChannelRequest *self,
    const gchar *key,
    GVariant *value)
{
  GValue one = G_VALUE_INIT, *two;

  g_return_if_fail (!self->priv->requested);
  g_return_if_fail (key != NULL);
  g_return_if_fail (value != NULL);

  if (self->priv->hints == NULL)
    self->priv->hints = tp_asv_new (NULL, NULL);

  dbus_g_value_parse_g_variant (value, &one);
  two = tp_g_value_slice_dup (&one);

  g_hash_table_insert (self->priv->hints, g_strdup (key), two);

  g_value_unset (&one);
}

/**
 * tp_account_channel_request_set_hints:
 * @self: a #TpAccountChannelRequest
 * @hints: a #TP_HASH_TYPE_STRING_VARIANT_MAP
 *
 * Set additional information about the channel request, which will be used
 * as the value for the resulting request's #TpChannelRequest:hints property.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * In high-level language bindings, use tp_account_channel_request_set_hint()
 * instead.
 *
 * Since: 0.13.14
 */
void
tp_account_channel_request_set_hints (TpAccountChannelRequest *self,
    GHashTable *hints)
{
  g_return_if_fail (!self->priv->requested);
  g_return_if_fail (hints != NULL);

  tp_clear_pointer (&self->priv->hints, g_hash_table_unref);
  self->priv->hints = g_hash_table_ref (hints);
}

/**
 * tp_account_channel_request_set_delegate_to_preferred_handler:
 * @self: a #TpAccountChannelRequest
 * @delegate: %TRUE to request to delegate channels
 *
 * If @delegate is %TRUE, asks to the client currently handling the channels to
 * delegate them to the preferred handler (passed when calling
 * tp_account_channel_request_ensure_channel_async() for example).
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.15.3
 */
void
tp_account_channel_request_set_delegate_to_preferred_handler (
    TpAccountChannelRequest *self,
    gboolean delegate)
{
  g_return_if_fail (!self->priv->requested);

  if (self->priv->hints == NULL)
    self->priv->hints = tp_asv_new (NULL, NULL);

  tp_asv_set_boolean (self->priv->hints,
      "org.freedesktop.Telepathy.ChannelRequest.DelegateToPreferredHandler",
      delegate);
}

/**
 * tp_account_channel_request_set_delegated_channel_callback:
 * @self: a #TpAccountChannelRequest
 * @callback: function called the channel requested using @self is
 * delegated, may not be %NULL
 * @user_data: arbitrary user-supplied data passed to @callback
 * @destroy: called with the @user_data as argument, when @self is destroyed
 *
 * Turn on support for
 * the org.freedesktop.Telepathy.ChannelRequest.DelegateToPreferredHandler
 * hint.
 *
 * When receiving a request containing this hint, @self will automatically
 * delegate the channel to the preferred handler of the request and then call
 * @callback to inform the client that it is no longer handling this channel.
 *
 * @callback may be called any time after (and only after) requesting and
 * handling the channel (i.e. you have called create_and_handle or
 * ensure_and_handle).
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * See also: tp_base_client_set_delegated_channels_callback()
 *
 * Since: 0.15.3
 */
void
tp_account_channel_request_set_delegated_channel_callback (
    TpAccountChannelRequest *self,
    TpAccountChannelRequestDelegatedChannelCb callback,
    gpointer user_data,
    GDestroyNotify destroy)
{
  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (!self->priv->requested);

  g_return_if_fail (self->priv->delegated_channel_cb == NULL);

  self->priv->delegated_channel_cb = callback;
  self->priv->delegated_channel_data = user_data;
  self->priv->delegated_channel_destroy = destroy;
}

TpBaseClient *
_tp_account_channel_request_get_client (TpAccountChannelRequest *self)
{
  g_return_val_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self), NULL);

  return self->priv->handler;
}

/**
 * tp_account_channel_request_set_target_contact:
 * @self: a #TpAccountChannelRequest
 * @contact: the contact to be contacted
 *
 * Configure this request to create a peer-to-peer channel with @contact as
 * the other peer.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.19.0
 */
void
tp_account_channel_request_set_target_contact (
    TpAccountChannelRequest *self,
    TpContact *contact)
{
  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (TP_IS_CONTACT (contact));
  g_return_if_fail (!self->priv->requested);

  /* Do not use tp_asv_set_uint32 or similar - the key is dup'd */
  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_TARGET_HANDLE_TYPE),
      tp_g_value_slice_new_uint (TP_HANDLE_TYPE_CONTACT));
  /* We use the ID because it persists across a disconnect/reconnect */
  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_TARGET_ID),
      tp_g_value_slice_new_string (tp_contact_get_identifier (contact)));
}

/**
 * tp_account_channel_request_set_target_id:
 * @self: a #TpAccountChannelRequest
 * @handle_type: the type of @identifier, typically %TP_HANDLE_TYPE_CONTACT
 *  or %TP_HANDLE_TYPE_ROOM
 * @identifier: the unique identifier of the contact, room etc. to be
 *  contacted
 *
 * Configure this request to create a channel with @identifier,
 * an identifier of type @handle_type.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.19.0
 */
void
tp_account_channel_request_set_target_id (
    TpAccountChannelRequest *self,
    TpHandleType handle_type,
    const gchar *identifier)
{
  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (identifier != NULL);
  g_return_if_fail (handle_type != TP_HANDLE_TYPE_NONE);
  g_return_if_fail (!self->priv->requested);

  /* Do not use tp_asv_set_uint32 or similar - the key is dup'd */
  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_TARGET_HANDLE_TYPE),
      tp_g_value_slice_new_uint (handle_type));
  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_TARGET_ID),
      tp_g_value_slice_new_string (identifier));
}

/**
 * tp_account_channel_request_new_text:
 * @account: a #TpAccount
 * @user_action_time: the time of the user action that caused this request,
 *  or one of the special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
 *  %TP_USER_ACTION_TIME_CURRENT_TIME (see
 *  #TpAccountChannelRequest:user-action-time)
 *
 * Convenience function to create a new #TpAccountChannelRequest object
 * which will yield a Text channel.
 *
 * After creating the request, you will also need to set the "target"
 * of the channel by calling one of the following functions:
 *
 * - tp_account_channel_request_set_target_contact()
 * - tp_account_channel_request_set_target_id()
 *
 * Returns: a new #TpAccountChannelRequest object
 *
 * Since: 0.19.0
 */
TpAccountChannelRequest *
tp_account_channel_request_new_text (
    TpAccount *account,
    gint64 user_action_time)
{
  TpAccountChannelRequest *self;
  GHashTable *request;

  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  request = tp_asv_new (
      TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING, TP_IFACE_CHANNEL_TYPE_TEXT,
      NULL);

  self = g_object_new (TP_TYPE_ACCOUNT_CHANNEL_REQUEST,
      "account", account,
      "request", request,
      "user-action-time", user_action_time,
      NULL);
  g_hash_table_unref (request);
  return self;
}

/**
 * tp_account_channel_request_set_request_property:
 * @self: a #TpAccountChannelRequest
 * @name: a D-Bus property name
 * @value: an arbitrary value for the property
 *
 * Configure this channel request to include the given property, as
 * documented in the Telepathy D-Bus API Specification or an
 * implementation-specific extension.
 *
 * Using this method is not recommended, but it can be necessary for
 * experimental or implementation-specific interfaces.
 *
 * If the property is not supported by the protocol or channel type, the
 * channel request will fail. Use #TpCapabilities and the Telepathy
 * D-Bus API Specification to determine which properties are available.
 *
 * If @value is a floating reference, this method takes ownership of it
 * by using g_variant_ref_sink(). This allows convenient inline use of
 * #GVariant constructors:
 *
 * |[
 * tp_account_channel_request_set_request_property (acr, "com.example.Int",
 *     g_variant_new_int32 (17));
 * tp_account_channel_request_set_request_property (acr, "com.example.String",
 *     g_variant_new_string ("ferret"));
 * ]|
 *
 * It is an error to provide a @value which contains types not supported by
 * D-Bus.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.19.0
 */
void
tp_account_channel_request_set_request_property (
    TpAccountChannelRequest *self,
    const gchar *name,
    GVariant *value)
{
  GValue *v;

  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (!self->priv->requested);

  v = g_slice_new0 (GValue);
  dbus_g_value_parse_g_variant (value, v);

  g_hash_table_insert (self->priv->request, g_strdup (name), v);
}

/**
 * tp_account_channel_request_new_audio_call:
 * @account: a #TpAccount
 * @user_action_time: the time of the user action that caused this request,
 *  or one of the special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
 *  %TP_USER_ACTION_TIME_CURRENT_TIME (see
 *  #TpAccountChannelRequest:user-action-time)
 *
 * Convenience function to create a new #TpAccountChannelRequest object
 * which will yield a Call channel, initially carrying audio only.
 *
 * After creating the request, you will usually also need to set the "target"
 * of the channel by calling one of the following functions:
 *
 * - tp_account_channel_request_set_target_contact()
 * - tp_account_channel_request_set_target_id()
 *
 * To call a contact, either use
 * tp_account_channel_request_set_target_contact() or one of the generic
 * methods that takes a handle type argument. To check whether this
 * is possible, use tp_capabilities_supports_audio_call() with
 * @handle_type set to %TP_HANDLE_TYPE_CONTACT.
 *
 * <!-- reinstate this when we have CMs that actually allow it:
 * In some protocols it is possible to create a conference call which
 * takes place in a named chatroom, by calling
 * tp_account_channel_request_set_target_id() with @handle_type
 * set to %TP_HANDLE_TYPE_ROOM. To test whether this is possible, use
 * tp_capabilities_supports_audio_call() with @handle_type set to
 * %TP_HANDLE_TYPE_ROOM.
 * -->
 *
 * In some protocols, it is possible to create a Call channel without
 * setting a target at all, which will result in a new, empty
 * conference call. To test whether this is possible, use
 * tp_capabilities_supports_audio_call() with @handle_type set to
 * %TP_HANDLE_TYPE_NONE.
 *
 * Returns: a new #TpAccountChannelRequest object
 *
 * Since: 0.19.0
 */
TpAccountChannelRequest *
tp_account_channel_request_new_audio_call (
    TpAccount *account,
    gint64 user_action_time)
{
  TpAccountChannelRequest *self;
  GHashTable *request;

  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  request = tp_asv_new (
      TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING, TP_IFACE_CHANNEL_TYPE_CALL,
      TP_PROP_CHANNEL_TYPE_CALL_INITIAL_AUDIO, G_TYPE_BOOLEAN, TRUE,
      NULL);

  self = g_object_new (TP_TYPE_ACCOUNT_CHANNEL_REQUEST,
      "account", account,
      "request", request,
      "user-action-time", user_action_time,
      NULL);
  g_hash_table_unref (request);
  return self;
}

/**
 * tp_account_channel_request_new_audio_video_call:
 * @account: a #TpAccount
 * @user_action_time: the time of the user action that caused this request,
 *  or one of the special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
 *  %TP_USER_ACTION_TIME_CURRENT_TIME (see
 *  #TpAccountChannelRequest:user-action-time)
 *
 * Convenience function to create a new #TpAccountChannelRequest object
 * which will yield a Call channel, initially carrying both audio
 * and video.
 *
 * This is the same as tp_account_channel_request_new_audio_call(),
 * except that the channel will initially carry video as well as audio,
 * and instead of using tp_capabilities_supports_audio_call()
 * you should test capabilities with
 * tp_capabilities_supports_audio_video_call().
 *
 * See the documentation of tp_account_channel_request_new_audio_call()
 * for details of how to set the target (contact, chatroom etc.) for the call.
 *
 * Returns: a new #TpAccountChannelRequest object
 *
 * Since: 0.19.0
 */
TpAccountChannelRequest *
tp_account_channel_request_new_audio_video_call (
    TpAccount *account,
    gint64 user_action_time)
{
  TpAccountChannelRequest *self;
  GHashTable *request;

  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  request = tp_asv_new (
      TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING, TP_IFACE_CHANNEL_TYPE_CALL,
      TP_PROP_CHANNEL_TYPE_CALL_INITIAL_AUDIO, G_TYPE_BOOLEAN, TRUE,
      TP_PROP_CHANNEL_TYPE_CALL_INITIAL_VIDEO, G_TYPE_BOOLEAN, TRUE,
      NULL);

  self = g_object_new (TP_TYPE_ACCOUNT_CHANNEL_REQUEST,
      "account", account,
      "request", request,
      "user-action-time", user_action_time,
      NULL);
  g_hash_table_unref (request);
  return self;
}

/**
 * tp_account_channel_request_new_file_transfer:
 * @account: a #TpAccount
 * @filename: a suggested name for the file, which should not contain
 *  directories or directory separators (for example, if you are sending
 * a file called /home/user/monkey.pdf, set this to monkey.pdf)
 * @mime_type: (allow-none): the MIME type (content-type) of the file;
 *  a %NULL value is allowed, and is treated as
 *  "application/octet-stream"
 * @size: the file's size in bytes
 * @user_action_time: the time of the user action that caused this request,
 *  or one of the special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
 *  %TP_USER_ACTION_TIME_CURRENT_TIME (see
 *  #TpAccountChannelRequest:user-action-time)
 *
 * Convenience function to create a new #TpAccountChannelRequest object,
 * which will yield a FileTransfer channel to send a file to a contact.
 *
 * After creating the request, you will also need to set the "target"
 * of the channel by calling one of the following functions:
 *
 * - tp_account_channel_request_set_target_contact()
 * - tp_account_channel_request_set_target_id()
 *
 * Returns: a new #TpAccountChannelRequest object
 *
 * Since: 0.19.0
 */
TpAccountChannelRequest *
tp_account_channel_request_new_file_transfer (
    TpAccount *account,
    const gchar *filename,
    const gchar *mime_type,
    guint64 size,
    gint64 user_action_time)
{
  TpAccountChannelRequest *self;
  GHashTable *request;

  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);
  g_return_val_if_fail (!tp_str_empty (filename), NULL);
  g_return_val_if_fail (mime_type == NULL || mime_type[0] != '\0', NULL);

  if (mime_type == NULL)
    mime_type = "application/octet-stream";

  request = tp_asv_new (
      TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING,
          TP_IFACE_CHANNEL_TYPE_FILE_TRANSFER,
      TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_FILENAME, G_TYPE_STRING, filename,
      TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_CONTENT_TYPE, G_TYPE_STRING, mime_type,
      TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_SIZE, G_TYPE_UINT64, size,
      NULL);

  self = g_object_new (TP_TYPE_ACCOUNT_CHANNEL_REQUEST,
      "account", account,
      "request", request,
      "user-action-time", user_action_time,
      NULL);
  g_hash_table_unref (request);
  return self;
}

/**
 * tp_account_channel_request_set_file_transfer_description:
 * @self: a #TpAccountChannelRequest
 * @description: a description of the file
 *
 * Configure this channel request to provide the recipient of the file
 * with the given description.
 *
 * If file descriptions are not supported by the protocol, or if this
 * method is used on a request that is not actually a file transfer, the
 * channel request will fail. Use
 * tp_capabilities_supports_file_transfer_description() to determine
 * whether outgoing file transfers can have a description.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.19.0
 */
void
tp_account_channel_request_set_file_transfer_description (
    TpAccountChannelRequest *self,
    const gchar *description)
{
  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (!self->priv->requested);
  g_return_if_fail (description != NULL);

  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_DESCRIPTION),
      tp_g_value_slice_new_string (description));
}

/**
 * tp_account_channel_request_set_file_transfer_uri:
 * @self: a #TpAccountChannelRequest
 * @uri: the source URI for the file
 *
 * Configure this channel request to provide other local Telepathy
 * components with the URI of the file being sent. Unlike most
 * properties on a file transfer channel, this information is not
 * sent to the recipient of the file; instead, it is signalled on
 * D-Bus for use by other Telepathy components.
 *
 * The URI should usually be a <code>file</code> URI as defined by
 * <ulink url="http://www.apps.ietf.org/rfc/rfc1738.html#sec-3.10">RFC 1738
 * §3.10</ulink> (for instance, <code>file:///path/to/file</code> or
 * <code>file://localhost/path/to/file</code>). If a remote resource
 * is being transferred to a contact, it may have a different scheme,
 * such as <code>http</code>.
 *
 * Even if this method is used, the connection manager will not read
 * the file from disk: the handler for the channel is still
 * responsible for streaming the file. However, providing the URI
 * allows a local logger to log which file was transferred, for instance.
 *
 * If this functionality is not supported by the connection manager, or
 * if this method is used on a request that is not actually a file transfer,
 * the channel request will fail. Use
 * tp_capabilities_supports_file_transfer_uri() to determine
 * whether outgoing file transfers can have a URI.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.19.0
 */
void
tp_account_channel_request_set_file_transfer_uri (
    TpAccountChannelRequest *self,
    const gchar *uri)
{
  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (!self->priv->requested);
  g_return_if_fail (uri != NULL);

  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_URI),
      tp_g_value_slice_new_string (uri));
}

/**
 * tp_account_channel_request_set_file_transfer_timestamp:
 * @self: a #TpAccountChannelRequest
 * @timestamp: the modification timestamp of the file, in seconds since the
 *  Unix epoch (the beginning of 1970 in the UTC time zone), as returned
 *  by g_date_time_to_unix()
 *
 * Configure this channel request to accompany the file transfer with
 * the given modification timestamp for the file.
 *
 * If file timestamps are not supported by the protocol, or if this
 * method is used on a request that is not actually a file transfer, the
 * channel request will fail. Use
 * tp_capabilities_supports_file_transfer_date() to determine
 * whether outgoing file transfers can have a timestamp.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.19.0
 */
void
tp_account_channel_request_set_file_transfer_timestamp (
    TpAccountChannelRequest *self,
    guint64 timestamp)
{
  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (!self->priv->requested);

  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_DATE),
      tp_g_value_slice_new_uint64 (timestamp));
}

/**
 * tp_account_channel_request_set_file_transfer_initial_offset:
 * @self: a #TpAccountChannelRequest
 * @offset: the offset into the file at which the transfer will start
 *
 * Configure this channel request to inform the recipient of the file
 * that this channel will not send the first @offset bytes of the file.
 * In some protocols, this can be used to resume an interrupted transfer.
 *
 * If this method is not called, the default is to start from the
 * beginning of the file (equivalent to @offset = 0).
 *
 * If offsets greater than 0 are not supported by the protocol, or if this
 * method is used on a request that is not actually a file transfer, the
 * channel request will fail. Use
 * tp_capabilities_supports_file_transfer_initial_offset() to determine
 * whether offsets greater than 0 are available.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.19.0
 */
void
tp_account_channel_request_set_file_transfer_initial_offset (
    TpAccountChannelRequest *self,
    guint64 offset)
{
  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (!self->priv->requested);

  if (offset == 0)
    {
      g_hash_table_remove (self->priv->request,
          TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_INITIAL_OFFSET);
    }
  else
    {
      g_hash_table_insert (self->priv->request,
          g_strdup (TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_INITIAL_OFFSET),
          tp_g_value_slice_new_uint64 (offset));
    }
}

/**
 * tp_account_channel_request_set_file_transfer_hash:
 * @self: a #TpAccountChannelRequest
 * @hash_type: a type of @hash
 * @hash: hash of the contents of the file transfer
 *
 * Configure this channel request to accompany the file transfer with
 * the hash of the file.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.23.2
 */
void
tp_account_channel_request_set_file_transfer_hash (
    TpAccountChannelRequest *self,
    TpFileHashType hash_type,
    const gchar *hash)
{
  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (!self->priv->requested);
  g_return_if_fail (hash_type < TP_NUM_FILE_HASH_TYPES);

  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_CONTENT_HASH_TYPE),
      tp_g_value_slice_new_uint (hash_type));

  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_TYPE_FILE_TRANSFER_CONTENT_HASH),
      tp_g_value_slice_new_string (hash));
}

/**
 * tp_account_channel_request_new_stream_tube:
 * @account: a #TpAccount
 * @service: the service name that will be used over the tube. It should be a
 * well-known TCP service name as defined by
 * http://www.iana.org/assignments/port-numbers or
 * http://www.dns-sd.org/ServiceTypes.html, for instance "rsync" or "daap".
 * @user_action_time: the time of the user action that caused this request,
 *  or one of the special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
 *  %TP_USER_ACTION_TIME_CURRENT_TIME (see
 *  #TpAccountChannelRequest:user-action-time)
 *
 * Convenience function to create a new #TpAccountChannelRequest object,
 * which will yield a StreamTube channel.
 *
 * After creating the request, you will also need to set the "target"
 * of the channel by calling one of the following functions:
 *
 * - tp_account_channel_request_set_target_contact()
 * - tp_account_channel_request_set_target_id()
 *
 * Returns: a new #TpAccountChannelRequest object
 *
 * Since: 0.23.2
 */
TpAccountChannelRequest *
tp_account_channel_request_new_stream_tube (TpAccount *account,
    const gchar *service,
    gint64 user_action_time)
{
  TpAccountChannelRequest *self;
  GHashTable *request;

  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);
  g_return_val_if_fail (!tp_str_empty (service), NULL);

  request = tp_asv_new (
      TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING,
          TP_IFACE_CHANNEL_TYPE_STREAM_TUBE,
      TP_PROP_CHANNEL_TYPE_STREAM_TUBE_SERVICE, G_TYPE_STRING, service,
      NULL);

  self = g_object_new (TP_TYPE_ACCOUNT_CHANNEL_REQUEST,
      "account", account,
      "request", request,
      "user-action-time", user_action_time,
      NULL);

  g_hash_table_unref (request);
  return self;
}

/**
 * tp_account_channel_request_new_dbus_tube:
 * @account: a #TpAccount
 * @service_name: the service name that will be used over the tube. It should be
 * @user_action_time: the time of the user action that caused this request,
 *  or one of the special values %TP_USER_ACTION_TIME_NOT_USER_ACTION or
 *  %TP_USER_ACTION_TIME_CURRENT_TIME (see
 *  #TpAccountChannelRequest:user-action-time)
 *
 * Convenience function to create a new #TpAccountChannelRequest object,
 * which will yield a DBusTube channel.
 *
 * After creating the request, you will also need to set the "target"
 * of the channel by calling one of the following functions:
 *
 * - tp_account_channel_request_set_target_contact()
 * - tp_account_channel_request_set_target_id()
 *
 * Returns: a new #TpAccountChannelRequest object
 *
 * Since: 0.23.2
 */
TpAccountChannelRequest *
tp_account_channel_request_new_dbus_tube (TpAccount *account,
    const gchar *service_name,
    gint64 user_action_time)
{
  TpAccountChannelRequest *self;
  GHashTable *request;

  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);
  g_return_val_if_fail (!tp_str_empty (service_name), NULL);

  request = tp_asv_new (
      TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING,
          TP_IFACE_CHANNEL_TYPE_DBUS_TUBE,
      TP_PROP_CHANNEL_TYPE_DBUS_TUBE_SERVICE_NAME, G_TYPE_STRING, service_name,
      NULL);

  self = g_object_new (TP_TYPE_ACCOUNT_CHANNEL_REQUEST,
      "account", account,
      "request", request,
      "user-action-time", user_action_time,
      NULL);

  g_hash_table_unref (request);
  return self;
}

/**
 * tp_account_channel_request_set_sms_channel:
 * @self: a #TpAccountChannelRequest
 * @is_sms_channel: #TRUE if the channel should use SMS
 *
 * If @is_sms_channel is set to #TRUE, messages sent and received on the
 * requested channel will be transmitted via SMS.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.23.2
 */
void
tp_account_channel_request_set_sms_channel (TpAccountChannelRequest *self,
    gboolean is_sms_channel)
{
  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (!self->priv->requested);

  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_INTERFACE_SMS_SMS_CHANNEL),
      tp_g_value_slice_new_boolean (is_sms_channel));
}

/**
 * tp_account_channel_request_set_conference_initial_channels:
 * @self: a #TpAccountChannelRequest
 * @channels: a #NULL-terminated array of channel paths
 *
 * Indicate that the channel which is going to be requested using @self
 * is an upgrade of the channels whose object paths is listed in @channels.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.23.2
 */
void
tp_account_channel_request_set_conference_initial_channels (
    TpAccountChannelRequest *self,
    const gchar * const * channels)
{
  GPtrArray *chans;
  guint i;

  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (!self->priv->requested);

  chans = g_ptr_array_new ();
  for (i = 0; channels != NULL && channels[i] != NULL; i++)
    g_ptr_array_add (chans, (gpointer) channels[i]);

  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_INTERFACE_CONFERENCE_INITIAL_CHANNELS),
      tp_g_value_slice_new_boxed (TP_ARRAY_TYPE_OBJECT_PATH_LIST, chans));

  g_ptr_array_unref (chans);
}

/**
 * tp_account_channel_request_set_initial_invitee_ids:
 * @self: a #TpAccountChannelRequest
 * @ids: a #NULL-terminated array of contact ids
 *
 * Indicate that the contacts listed in @ids have to be invited to the
 * conference represented by the channel which is going to be requested
 * using @self.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.23.2
 */
void
tp_account_channel_request_set_initial_invitee_ids (
    TpAccountChannelRequest *self,
    const gchar * const * ids)
{
  g_return_if_fail (TP_IS_ACCOUNT_CHANNEL_REQUEST (self));
  g_return_if_fail (!self->priv->requested);

  g_hash_table_insert (self->priv->request,
      g_strdup (TP_PROP_CHANNEL_INTERFACE_CONFERENCE_INITIAL_INVITEE_IDS),
      tp_g_value_slice_new_boxed (G_TYPE_STRV, ids));
}

/**
 * tp_account_channel_request_set_initial_invitees:
 * @self: a #TpAccountChannelRequest
 * @contacts: (element-type TelepathyGLib.Contact): a #GPtrArray of #TpContact
 *
 * Indicate that the contacts listed in @contacts have to be invited to the
 * conference represented by the channel which is going to be requested
 * using @self.
 *
 * This function can't be called once @self has been used to request a
 * channel.
 *
 * Since: 0.23.2
 */
void
tp_account_channel_request_set_initial_invitees (
    TpAccountChannelRequest *self,
    GPtrArray *contacts)
{
  guint i;
  GPtrArray *ids;

  g_return_if_fail (contacts != NULL);

  ids = g_ptr_array_new ();

  for (i = 0; i < contacts->len; i++)
    {
      TpContact *contact = g_ptr_array_index (contacts, i);

      g_ptr_array_add (ids, (gchar *) tp_contact_get_identifier (contact));
    }

  g_ptr_array_add (ids, NULL);

  tp_account_channel_request_set_initial_invitee_ids (self,
      (const gchar * const *) ids->pdata);

  g_ptr_array_unref (ids);
}
