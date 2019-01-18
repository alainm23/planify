/*
 * contact-search.c - a representation for an ongoing search for contacts
 *
 * Copyright (C) 2010-2011 Collabora Ltd.
 *
 * The code contained in this file is free software; you can redistribute
 * it and/or modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either version
 * 2.1 of the License, or (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this code; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "config.h"

#include "telepathy-glib/contact-search.h"

#include <telepathy-glib/contact-search-result.h>
#include <telepathy-glib/contact-search-internal.h>
#include <telepathy-glib/account-channel-request.h>
#include <telepathy-glib/channel.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CHANNEL
#include "telepathy-glib/channel-internal.h"
#include "telepathy-glib/debug-internal.h"

#include "_gen/telepathy-interfaces.h"

/**
 * SECTION:contact-search
 * @title: TpContactSearch
 * @short_description: object for a Telepathy contact search channel
 * @see_also: #TpChannel
 *
 * #TpContactSearch objects represent ongoing searches for contacts. They
 * implement the #GAsyncInitable interface, so the initialization may fail.
 *
 * In normal circumstances, after creating a #TpContactSearch object, you
 * would connect to the #TpContactSearch::search-results-received signal
 * to get search results when a search happens. You would then call
 * tp_contact_search_get_search_keys() to get the search keys, and then
 * do a search using tp_contact_search_start(). When results are found,
 * the #TpContactSearch::search-results-received callback will be called.
 *
 * You can check the search state by looking at the
 * #TpContactSearch:state property. If you want to be notified about
 * changes, connect to the notify::state signal, see
 * #GObject::notify for details.
 *
 * You can search as many times as you want on a #TpContactSearch object,
 * but you need to call tp_contact_search_reset_async() between searches.
 *
 * Since: 0.13.11
 */

/**
 * TpContactSearchClass:
 *
 * The class of a #TpContactSearch.
 *
 * Since: 0.13.11
 */

/**
 * TpContactSearch:
 *
 * An object for Telepathy contact searches.
 * There are no interesting public struct fields.
 *
 * Since: 0.13.11
 */

static void async_initable_iface_init (GAsyncInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (TpContactSearch,
    tp_contact_search,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE (G_TYPE_ASYNC_INITABLE, async_initable_iface_init))

struct _TpContactSearchPrivate
{
  TpAccount *account;
  TpChannel *channel;
  TpChannelContactSearchState state;
  gchar *server;
  guint limit;
  const gchar * const *keys;

  GCancellable *cancellable;
  GSimpleAsyncResult *async_res;
};

enum /* properties */
{
  PROP_0,
  PROP_ACCOUNT,
  PROP_SERVER,
  PROP_LIMIT,
  PROP_STATE,
};

enum /* signals */
{
  SEARCH_RESULTS_RECEIVED,
  LAST_SIGNAL
};

static guint _signals[LAST_SIGNAL] = { 0, };

static void
close_search_channel (TpContactSearch *self)
{
  if (self->priv->channel != NULL)
    {
      DEBUG ("Closing existing search channel");

      tp_cli_channel_call_close (self->priv->channel,
          -1, NULL, NULL, NULL, NULL);
      tp_clear_object (&self->priv->channel);
    }
}

static void
_search_state_changed (TpChannel *channel,
    guint state,
    const gchar *error,
    GHashTable *details,
    gpointer user_data,
    GObject *weak_object)
{
  TpContactSearch *self = TP_CONTACT_SEARCH (weak_object);

  if (self->priv->state != state)
    {
      DEBUG ("SearchStateChanged: %u", state);
      self->priv->state = state;
      g_object_notify (weak_object, "state");
    }
}

static void
_search_results_received (TpChannel *channel,
    GHashTable *result,
    gpointer user_data,
    GObject *object)
{
  GHashTableIter iter;
  gchar *contact;
  GPtrArray *info;
  GList *results = NULL;

  g_hash_table_iter_init (&iter, result);
  while (g_hash_table_iter_next (&iter, (gpointer) &contact, (gpointer) &info))
    {
      TpContactSearchResult *search_result;
      char *field;
      char **parameters;
      char **values;
      gint i;

      search_result = _tp_contact_search_result_new (contact);

      for (i = info->len - 1; i >= 0; i--)
        {
          TpContactInfoField *contact_field;
          tp_value_array_unpack (g_ptr_array_index (info, i), 3,
              &field, &parameters, &values);

          contact_field = tp_contact_info_field_new (field, parameters, values);
          _tp_contact_search_result_insert_field (search_result, contact_field);
        }
      results = g_list_prepend (results, search_result);
    }

  DEBUG ("SearchResultsReceived (%i results)", g_hash_table_size (result));
  g_signal_emit (object, _signals[SEARCH_RESULTS_RECEIVED], 0, results);

  g_list_free_full (results, g_object_unref);
}

static void
_create_search_channel_cb (GObject *source_object,
    GAsyncResult *result,
    gpointer user_data)
{
  TpAccountChannelRequest *channel_request;
  TpContactSearch *self = TP_CONTACT_SEARCH (user_data);
  GHashTable *properties;
  GError *error = NULL;
  const gchar *server;
  guint limit;
  gboolean valid;

  channel_request = TP_ACCOUNT_CHANNEL_REQUEST (source_object);

  self->priv->channel =
      tp_account_channel_request_create_and_handle_channel_finish (
          channel_request, result, NULL, &error);

  if (self->priv->channel == NULL)
    {
      DEBUG ("Failed to create search channel: %s", error->message);
      goto out;
    }

  DEBUG ("Got channel: %s", tp_proxy_get_object_path (self->priv->channel));

  if (tp_cli_channel_type_contact_search_connect_to_search_result_received (
          self->priv->channel, _search_results_received,
          NULL, NULL, G_OBJECT (self), &error) == NULL ||
      tp_cli_channel_type_contact_search_connect_to_search_state_changed (
          self->priv->channel, _search_state_changed,
          NULL, NULL, G_OBJECT (self), &error) == NULL)
    {
      DEBUG ("Failed to connect to signals: %s", error->message);
      goto out;
    }

  properties = _tp_channel_get_immutable_properties (self->priv->channel);

  self->priv->keys = tp_asv_get_strv (properties,
      TP_PROP_CHANNEL_TYPE_CONTACT_SEARCH_AVAILABLE_SEARCH_KEYS);
  server = tp_asv_get_string (properties,
      TP_PROP_CHANNEL_TYPE_CONTACT_SEARCH_SERVER);
  if (g_strcmp0 (server, self->priv->server) != 0)
    {
      g_free (self->priv->server);
      self->priv->server = g_strdup (server);
      g_object_notify (G_OBJECT (self), "server");
    }
  limit = tp_asv_get_uint32 (properties,
      TP_PROP_CHANNEL_TYPE_CONTACT_SEARCH_LIMIT, &valid);
  if (valid && limit != self->priv->limit)
    {
      self->priv->limit = limit;
      g_object_notify (G_OBJECT (self), "limit");
    }

  self->priv->state = TP_CHANNEL_CONTACT_SEARCH_STATE_NOT_STARTED;
  g_object_notify (G_OBJECT (self), "state");

 out:
  if (error != NULL)
    {
      g_simple_async_result_set_from_error (self->priv->async_res, error);
      g_error_free (error);
      /* This function is safe if self->priv->channel is NULL. */
      close_search_channel (self);
    }

  g_simple_async_result_complete (self->priv->async_res);
  tp_clear_object (&self->priv->async_res);
}

static void
tp_contact_search_open_new_channel (TpContactSearch *self)
{
  GHashTable *request;
  TpAccountChannelRequest *channel_request;

  close_search_channel (self);

  DEBUG ("Requesting new search channel");

  request = tp_asv_new (
      TP_PROP_CHANNEL_CHANNEL_TYPE,
      G_TYPE_STRING,
      TP_IFACE_CHANNEL_TYPE_CONTACT_SEARCH,
      NULL);

  if (self->priv->server != NULL)
    tp_asv_set_string (request,
        TP_PROP_CHANNEL_TYPE_CONTACT_SEARCH_SERVER,
        self->priv->server);

  if (self->priv->limit != 0)
    tp_asv_set_uint32 (request,
      TP_PROP_CHANNEL_TYPE_CONTACT_SEARCH_LIMIT,
      self->priv->limit);

  channel_request = tp_account_channel_request_new (self->priv->account,
      request,
      TP_USER_ACTION_TIME_NOT_USER_ACTION);

  tp_account_channel_request_create_and_handle_channel_async (
      channel_request,
      self->priv->cancellable,
      _create_search_channel_cb,
      G_OBJECT (self));
  g_object_unref (channel_request);

  g_hash_table_unref (request);
}

static void
tp_contact_search_set_property (GObject *object,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpContactSearch *self = TP_CONTACT_SEARCH (object);

  switch (prop_id)
    {
      case PROP_ACCOUNT:
        g_assert (self->priv->account == NULL); /* construct-only */
        self->priv->account = g_value_dup_object (value);
        break;

      case PROP_SERVER:
        g_assert (self->priv->server == NULL); /* construct-only */
        self->priv->server = g_value_dup_string (value);
        break;

      case PROP_LIMIT:
        self->priv->limit = g_value_get_uint (value);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (self, prop_id, pspec);
        break;
    }
}

static void
tp_contact_search_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpContactSearch *self = TP_CONTACT_SEARCH (object);

  switch (prop_id)
    {
      case PROP_ACCOUNT:
        g_value_set_object (value, self->priv->account);
        break;

      case PROP_SERVER:
        g_value_set_string (value, self->priv->server);
        break;

      case PROP_LIMIT:
        g_value_set_uint (value, self->priv->limit);
        break;

      case PROP_STATE:
        g_value_set_uint (value, self->priv->state);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
        break;
    }
}

static void
tp_contact_search_dispose (GObject *object)
{
  TpContactSearch *self = TP_CONTACT_SEARCH (object);

  close_search_channel (self);
  g_object_unref (self->priv->account);
  g_object_unref (self->priv->cancellable);

  G_OBJECT_CLASS (tp_contact_search_parent_class)->dispose (object);
}

static void
tp_contact_search_class_init (TpContactSearchClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  gobject_class->set_property = tp_contact_search_set_property;
  gobject_class->get_property = tp_contact_search_get_property;
  gobject_class->dispose = tp_contact_search_dispose;

  /**
   * TpContactSearch:account:
   *
   * This search's account.
   *
   * Since: 0.13.11
   */
  g_object_class_install_property (gobject_class,
      PROP_ACCOUNT,
      g_param_spec_object ("account",
        "Account",
        "A #TpAccount used to create search channels",
        TP_TYPE_ACCOUNT,
        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  /**
   * TpContactSearch:server:
   *
   * The search server. This is only supported by some protocols;
   * use tp_capabilities_supports_contact_search() to check if it's
   * supported.
   *
   * To change the server after the object has been constructed,
   * use tp_contact_search_reset_async().
   *
   * Since: 0.13.11
   */
  g_object_class_install_property (gobject_class,
      PROP_SERVER,
      g_param_spec_string ("server",
        "Server",
        "The server on which to search for contacts",
        NULL,
        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  /**
   * TpContactSearch:limit:
   *
   * The maximum number of results that the server should return.
   * This is only supported by some protocols; use
   * tp_capabilities_supports_contact_search() to check if it's
   * supported.
   *
   * To change the limit after the object has been constructed,
   * use tp_contact_search_reset_async().
   *
   * Since: 0.13.11
   */
  g_object_class_install_property (gobject_class,
      PROP_LIMIT,
      g_param_spec_uint ("limit",
        "Limit",
        "The maximum number of results to be returned by the server",
        0,
        G_MAXUINT32,
        0,
        G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  /**
   * TpContactSearch:state:
   *
   * This search's state, as a %TpChannelContactSearchState.
   *
   * Since: 0.13.11
   */
  g_object_class_install_property (gobject_class,
      PROP_STATE,
      g_param_spec_uint ("state",
        "State",
        "The search's state",
        0,
        G_MAXUINT32,
        TP_CHANNEL_CONTACT_SEARCH_STATE_NOT_STARTED,
        G_PARAM_READABLE | G_PARAM_STATIC_STRINGS));

  /**
   * TpContactSearch::search-results-received:
   * @self: a contact search
   * @results: (type GLib.List) (element-type TelepathyGLib.ContactSearchResult):
   * a #GList with the search results
   *
   * Emitted when search results are received. Note that this signal may
   * be emitted multiple times for the same search.
   *
   * Since: 0.13.11
   */
  _signals[SEARCH_RESULTS_RECEIVED] = g_signal_new ("search-results-received",
      G_TYPE_FROM_CLASS (klass),
      G_SIGNAL_RUN_LAST,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE,
      1, G_TYPE_POINTER);

  g_type_class_add_private (gobject_class,
      sizeof (TpContactSearchPrivate));
}

static void
tp_contact_search_init (TpContactSearch *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_CONTACT_SEARCH,
      TpContactSearchPrivate);

  self->priv->cancellable = g_cancellable_new ();
}

/**
 * tp_contact_search_new_async:
 * @account: an account for the contact search
 * @server: the server on which to search for contacts, or %NULL
 * @limit: The maximum number of results the server should return,
 * or 0 for the server default.
 * @callback: a #GAsyncReadyCallback to call when the initialization
 * is finished
 * @user_data: data to pass to the callback function
 *
 * <!-- -->
 *
 * Since: 0.13.11
 */
void
tp_contact_search_new_async (TpAccount *account,
    const gchar *server,
    guint limit,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  g_return_if_fail (TP_IS_ACCOUNT (account));

  g_async_initable_new_async (TP_TYPE_CONTACT_SEARCH,
      G_PRIORITY_DEFAULT,
      NULL,
      callback,
      user_data,
      "account", account,
      "server", server,
      "limit", limit,
      NULL);
}

/**
 * tp_contact_search_new_finish:
 * @result: the #GAsyncResult from the callback
 * @error: a #GError location to store an error, or %NULL
 *
 * <!-- -->
 *
 * Returns: (transfer full): a new contact search object, or %NULL
 * in case of error.
 *
 * Since: 0.13.11
 */
TpContactSearch *
tp_contact_search_new_finish (GAsyncResult *result,
    GError **error)
{
  GObject *object, *source_object;

  source_object = g_async_result_get_source_object (result);

  object = g_async_initable_new_finish (G_ASYNC_INITABLE (source_object),
      result, error);
  g_object_unref (source_object);

  if (object != NULL)
    return TP_CONTACT_SEARCH (object);
  else
    return NULL;
}

/**
 * tp_contact_search_reset_async:
 * @self: the #TpContactSearch to reset
 * @server: the server on which to search for contacts, or %NULL
 * @limit: The maximum number of results the server should return,
 * or 0 for the server default.
 * @callback: a #GAsyncReadyCallback to call when the initialization
 * is finished
 * @user_data: data to pass to the callback function
 *
 * Resets the contact search object so a new search can be performed.
 * If another tp_contact_search_reset_async() call is in progress,
 * it will be cancelled and tp_contact_search_reset_finish() will
 * return an appropriate error.
 *
 * Since: 0.13.11
 */
void
tp_contact_search_reset_async (TpContactSearch *self,
    const gchar *server,
    guint limit,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  g_return_if_fail (TP_IS_CONTACT_SEARCH (self));

  if (self->priv->async_res != NULL)
    {
      g_cancellable_cancel (self->priv->cancellable);
      g_object_unref (self->priv->cancellable);

      self->priv->cancellable = g_cancellable_new ();
    }

  g_return_if_fail (self->priv->async_res == NULL);

  g_free (self->priv->server);
  self->priv->server = g_strdup (server);
  self->priv->limit = limit;

  self->priv->async_res = g_simple_async_result_new (G_OBJECT (self),
      callback,
      user_data,
      tp_contact_search_reset_async);

  tp_contact_search_open_new_channel (self);
}

/**
 * tp_contact_search_reset_finish:
 * @self: the #TpContactSearch that is being reset
 * @result: the #GAsyncResult from the callback
 * @error: a #GError location to store an error, or %NULL
 *
 * <!-- -->
 *
 * Returns: (transfer none): the new search keys, or %NULL
 * in case of error.
 *
 * Since: 0.13.11
 */
const gchar * const *
tp_contact_search_reset_finish (TpContactSearch *self,
    GAsyncResult *result,
    GError      **error)
{
  GSimpleAsyncResult *simple;

  g_return_val_if_fail (g_simple_async_result_is_valid (result,
                            G_OBJECT (self),
                            tp_contact_search_reset_async),
      FALSE);

  simple = (GSimpleAsyncResult *) result;

  if (g_simple_async_result_propagate_error (simple, error))
    return NULL;

  return self->priv->keys;
}

/**
 * tp_contact_search_start:
 * @self: a #TpContactSearch
 * @criteria: (transfer none) (element-type utf8 utf8): a map
 * from keys returned by tp_contact_search_get_search_keys()
 * to values to search for
 *
 * Starts a search for the keys specified in @criteria. Connect
 * to the #TpContactSearch::search-results-received signal
 * before calling this function.
 *
 * Before searching again on the same #TpContactSearch, you must
 * call tp_contact_search_reset_async().
 *
 * Since: 0.13.11
 */
void
tp_contact_search_start (TpContactSearch *self,
    GHashTable *criteria)
{
  g_return_if_fail (TP_IS_CONTACT_SEARCH (self));
  g_return_if_fail (TP_IS_CHANNEL (self->priv->channel));
  g_return_if_fail (self->priv->state ==
      TP_CHANNEL_CONTACT_SEARCH_STATE_NOT_STARTED);

  tp_cli_channel_type_contact_search_call_search (self->priv->channel,
      -1, criteria, NULL, NULL, NULL, NULL);
}

/**
 * tp_contact_search_get_search_keys:
 * @self: the contact search object to get the keys from
 *
 * Get the search keys for a contact search.
 * The keys are vCard field names in lower case, except when
 * they're one of the special cases from telepathy-spec like
 * "tel;cell" or "x-n-given". See the
 * <ulink url="http://telepathy.freedesktop.org/spec/Channel_Type_Contact_Search.html">
 * Channel.Type.ContactSearch interface</ulink>
 * for a list of the special cases.
 *
 * Returns: (transfer none): the new search keys, or %NULL.
 *
 * Since: 0.13.11
 */
const gchar * const *
tp_contact_search_get_search_keys (TpContactSearch *self)
{
  g_return_val_if_fail (TP_IS_CONTACT_SEARCH (self), NULL);

  return self->priv->keys;
}

/**
 * tp_contact_search_get_account:
 * @self: a contact search object
 *
 * <!-- -->
 *
 * Returns: (transfer none): The TpContactSearch:account property
 *
 * Since: 0.13.11
 */
TpAccount *
tp_contact_search_get_account (TpContactSearch *self)
{
  g_return_val_if_fail (TP_IS_CONTACT_SEARCH (self), NULL);

  return self->priv->account;
}

/**
 * tp_contact_search_get_server:
 * @self: a contact search object
 *
 * <!-- -->
 *
 * Returns: The TpContactSearch:server property
 *
 * Since: 0.13.11
 */
const gchar *
tp_contact_search_get_server (TpContactSearch *self)
{
  g_return_val_if_fail (TP_IS_CONTACT_SEARCH (self), NULL);

  return self->priv->server;
}

/**
 * tp_contact_search_get_limit:
 * @self: a contact search object
 *
 * <!-- -->
 *
 * Returns: The TpContactSearch:limit property
 *
 * Since: 0.13.11
 */
guint
tp_contact_search_get_limit (TpContactSearch *self)
{
  g_return_val_if_fail (TP_IS_CONTACT_SEARCH (self), 0);

  return self->priv->limit;
}

static void
contact_search_init_async (GAsyncInitable *initable,
    gint io_priority,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpContactSearch *self = TP_CONTACT_SEARCH (initable);

  self->priv->async_res = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data, tp_contact_search_new_async);

  tp_contact_search_open_new_channel (self);
}

static gboolean
contact_search_init_finish (GAsyncInitable *initable,
    GAsyncResult *res,
    GError **error)
{
  if (g_simple_async_result_propagate_error (G_SIMPLE_ASYNC_RESULT (res),
          error))
    return FALSE;

  return TRUE;
}

static void
async_initable_iface_init (GAsyncInitableIface *iface)
{
  iface->init_async = contact_search_init_async;
  iface->init_finish = contact_search_init_finish;
}
