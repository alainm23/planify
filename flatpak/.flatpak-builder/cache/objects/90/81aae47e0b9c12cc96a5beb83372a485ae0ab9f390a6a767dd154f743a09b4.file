/*
 * account.c - proxy for an account in the Telepathy account manager
 *
 * Copyright © 2009–2012 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright © 2009–2010 Nokia Corporation
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

#include <string.h>

#include "telepathy-glib/account-internal.h"
#include "telepathy-glib/account.h"

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_ACCOUNTS
#include "telepathy-glib/connection-internal.h"
#include "telepathy-glib/dbus-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/proxy-internal.h"
#include "telepathy-glib/simple-client-factory-internal.h"
#include "telepathy-glib/util-internal.h"
#include "telepathy-glib/variant-util-internal.h"

#include "telepathy-glib/_gen/tp-cli-account-body.h"

/**
 * SECTION:account
 * @title: TpAccount
 * @short_description: proxy object for an account in the Telepathy account
 *  manager
 * @see_also: #TpAccountManager
 *
 * The Telepathy Account Manager stores the user's configured real-time
 * communication accounts. The #TpAccount object represents a stored account.
 *
 * Since: 0.7.32
 */

/**
 * TpAccount:
 *
 * The Telepathy Account Manager stores the user's configured real-time
 * communication accounts. This object represents a stored account.
 *
 * If this account is deleted from the account manager, the
 * #TpProxy::invalidated signal will be emitted
 * with the domain %TP_DBUS_ERRORS and the error code
 * %TP_DBUS_ERROR_OBJECT_REMOVED.
 *
 * One can connect to the #GObject::notify signal to get change notifications
 * for many of the properties on this object. Refer to each property's
 * documentation for whether it can be used in this way.
 *
 * #TpAccount objects should normally be obtained from the #TpAccountManager.
 *
 * Since 0.16, #TpAccount always has a non-%NULL #TpProxy:factory, and its
 * #TpProxy:factory will be propagated to its #TpConnection
 * (if any). If a #TpAccount is created without going via the
 * #TpAccountManager or specifying a #TpProxy:factory, the default
 * is to use a new #TpAutomaticClientFactory.
 *
 * Since: 0.7.32
 */

/**
 * TpAccountClass:
 *
 * The class of a #TpAccount.
 */

struct _TpAccountPrivate {
  gboolean dispose_has_run;

  TpConnection *connection;
  gchar *connection_object_path;

  TpConnectionStatus connection_status;
  TpConnectionStatusReason reason;
  gchar *error;
  GHashTable *error_details;

  TpConnectionPresenceType cur_presence;
  gchar *cur_status;
  gchar *cur_message;

  TpConnectionPresenceType requested_presence;
  gchar *requested_status;
  gchar *requested_message;

  TpConnectionPresenceType auto_presence;
  gchar *auto_status;
  gchar *auto_message;

  gboolean changing_presence;
  gboolean connect_automatically;
  gboolean has_been_online;

  gchar *normalized_name;
  gchar *nickname;

  gboolean enabled;
  gboolean valid;
  gboolean removed;

  gchar *cm_name;
  gchar *proto_name;
  gchar *icon_name;
  gchar *service;

  gchar *display_name;
  GStrv supersedes;

  GHashTable *parameters;

  gchar *storage_provider;
  GValue *storage_identifier;
  TpStorageRestrictionFlags storage_restrictions;

  GStrv uri_schemes;

  gboolean connection_prepared;
};

G_DEFINE_TYPE (TpAccount, tp_account, TP_TYPE_PROXY)

/* signals */
enum {
  STATUS_CHANGED,
  PRESENCE_CHANGED,
  AVATAR_CHANGED,
  LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

/* properties */
enum {
  PROP_ENABLED = 1,
  PROP_CHANGING_PRESENCE,
  PROP_CURRENT_PRESENCE_TYPE,
  PROP_CURRENT_STATUS,
  PROP_CURRENT_STATUS_MESSAGE,
  PROP_CONNECTION_STATUS,
  PROP_CONNECTION_STATUS_REASON,
  PROP_CONNECTION_ERROR,
  PROP_CONNECTION_ERROR_DETAILS,
  PROP_CONNECTION,
  PROP_DISPLAY_NAME,
  PROP_CONNECTION_MANAGER,
  PROP_CM_NAME,
  PROP_PROTOCOL,
  PROP_PROTOCOL_NAME,
  PROP_ICON_NAME,
  PROP_CONNECT_AUTOMATICALLY,
  PROP_HAS_BEEN_ONLINE,
  PROP_SERVICE,
  PROP_VALID,
  PROP_REQUESTED_PRESENCE_TYPE,
  PROP_REQUESTED_STATUS,
  PROP_REQUESTED_STATUS_MESSAGE,
  PROP_NICKNAME,
  PROP_AUTOMATIC_PRESENCE_TYPE,
  PROP_AUTOMATIC_STATUS,
  PROP_AUTOMATIC_STATUS_MESSAGE,
  PROP_NORMALIZED_NAME,
  PROP_STORAGE_PROVIDER,
  PROP_STORAGE_IDENTIFIER,
  PROP_STORAGE_IDENTIFIER_VARIANT,
  PROP_STORAGE_RESTRICTIONS,
  PROP_SUPERSEDES,
  PROP_URI_SCHEMES,
  N_PROPS
};

static void tp_account_prepare_connection_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);

static void tp_account_prepare_addressing_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);

static void tp_account_prepare_storage_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);

static gboolean
connection_is_internal (TpAccount *self)
{
  if (!tp_proxy_is_prepared (self, TP_ACCOUNT_FEATURE_CONNECTION))
    return FALSE;

  return !self->priv->connection_prepared;
}

/**
 * TP_ACCOUNT_FEATURE_CORE:
 *
 * Expands to a call to a function that returns a quark for the "core" feature
 * on a #TpAccount.
 *
 * When this feature is prepared, the basic properties of the Account have
 * been retrieved and are available for use, and change-notification has been
 * set up.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.9.0
 */

/**
 * TP_ACCOUNT_FEATURE_CONNECTION:
 *
 * Expands to a call to a function that returns a quark for the "connection"
 * feature on a #TpAccount.
 *
 * When this feature is prepared, it is guaranteed that #TpAccount:connection
 * will always be either %NULL or prepared. The account's #TpProxy:factory
 * will be used to create the #TpConnection object and to determine its
 * desired connection features. Change notification of the
 * #TpAccount:connection property will be delayed until all features (at least
 * %TP_CONNECTION_FEATURE_CORE) are prepared. See
 * tp_simple_client_factory_add_account_features() to define which features
 * needs to be prepared.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.15.5
 */

/**
 * TP_ACCOUNT_FEATURE_STORAGE:
 *
 * Expands to a call to a function that returns a quark for the "storage"
 * feature on a #TpAccount.
 *
 * When this feature is prepared, the Account.Interface.Storage properties have
 * been retrieved and are available for use.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.13.2
 */

/**
 * TP_ACCOUNT_FEATURE_ADDRESSING:
 *
 * Expands to a call to a function that returns a quark for the "addressing"
 * feature on a #TpAccount.
 *
 * When this feature is prepared, the list of URI schemes from
 * Account.Interface.Addressing has been retrieved and is available for use.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.13.8
 */

/**
 * tp_account_get_feature_quark_core:
 *
 * <!-- -->
 *
 * Returns: the quark used for representing the core feature of a
 *          #TpAccount
 *
 * Since: 0.9.0
 */
GQuark
tp_account_get_feature_quark_core (void)
{
  return g_quark_from_static_string ("tp-account-feature-core");
}

/**
 * tp_account_get_feature_quark_connection:
 *
 * <!-- -->
 *
 * Returns: the quark used for representing the connection feature of a
 *          #TpAccount
 *
 * Since: 0.15.5
 */
GQuark
tp_account_get_feature_quark_connection (void)
{
  return g_quark_from_static_string ("tp-account-feature-connection");
}

/**
 * tp_account_get_feature_quark_storage:
 *
 * <!-- -->
 *
 * Returns: the quark used for representing the storage interface of a
 *          #TpAccount
 *
 * Since: 0.13.2
 */
GQuark
tp_account_get_feature_quark_storage (void)
{
  return g_quark_from_static_string ("tp-account-feature-storage");
}

GQuark
tp_account_get_feature_quark_addressing (void)
{
  return g_quark_from_static_string ("tp-account-feature-addressing");
}

enum {
    FEAT_CORE,
    FEAT_CONNECTION,
    FEAT_ADDRESSING,
    FEAT_STORAGE,
    N_FEAT
};

static const TpProxyFeature *
_tp_account_list_features (TpProxyClass *cls G_GNUC_UNUSED)
{
  static TpProxyFeature features[N_FEAT + 1] = { { 0 } };

  if (G_UNLIKELY (features[0].name == 0))
    {
      features[FEAT_CORE].name = TP_ACCOUNT_FEATURE_CORE;
      features[FEAT_CORE].core = TRUE;
      /* no need for a prepare_async function - the constructor starts it */

      features[FEAT_CONNECTION].name = TP_ACCOUNT_FEATURE_CONNECTION;
      features[FEAT_CONNECTION].prepare_async =
        tp_account_prepare_connection_async;

      features[FEAT_ADDRESSING].name = TP_ACCOUNT_FEATURE_ADDRESSING;
      features[FEAT_ADDRESSING].prepare_async =
        tp_account_prepare_addressing_async;

      features[FEAT_STORAGE].name = TP_ACCOUNT_FEATURE_STORAGE;
      features[FEAT_STORAGE].prepare_async =
        tp_account_prepare_storage_async;

      /* assert that the terminator at the end is there */
      g_assert (features[N_FEAT].name == 0);
    }

  return features;
}

static void
tp_account_init (TpAccount *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_ACCOUNT,
      TpAccountPrivate);

  self->priv->connection_status = TP_CONNECTION_STATUS_DISCONNECTED;
  self->priv->error = g_strdup (TP_ERROR_STR_DISCONNECTED);
  self->priv->error_details = g_hash_table_new_full (g_str_hash, g_str_equal,
      g_free, (GDestroyNotify) tp_g_value_slice_free);
  self->priv->supersedes = g_new0 (gchar *, 1);
}

static void
_tp_account_invalidated_cb (TpAccount *self,
    guint domain,
    guint code,
    gchar *message)
{
  TpAccountPrivate *priv = self->priv;

  /* The connection will get disconnected as a result of account deletion,
   * but by then we will no longer be telling the API user about changes -
   * so claim the disconnection already happened (see fd.o#25149) */
  if (priv->connection_status != TP_CONNECTION_STATUS_DISCONNECTED)
    {
      priv->connection_status = TP_CONNECTION_STATUS_DISCONNECTED;
      tp_clear_pointer (&priv->error, g_free);
      g_hash_table_remove_all (priv->error_details);

      if (domain == TP_DBUS_ERRORS && code == TP_DBUS_ERROR_OBJECT_REMOVED)
        {
          /* presumably the user asked for it to be deleted... */
          priv->reason = TP_CONNECTION_STATUS_REASON_REQUESTED;
          priv->error = g_strdup (TP_ERROR_STR_CANCELLED);
          g_hash_table_insert (priv->error_details,
              g_strdup ("debug-message"),
              tp_g_value_slice_new_static_string ("TpAccount was removed"));
        }
      else
        {
          gchar *s;

          priv->reason = TP_CONNECTION_STATUS_REASON_NONE_SPECIFIED;
          priv->error = g_strdup (TP_ERROR_STR_DISCONNECTED);
          s = g_strdup_printf ("TpAccount was invalidated: %s #%u: %s",
              g_quark_to_string (domain), code, message);
          g_hash_table_insert (priv->error_details,
              g_strdup ("debug-message"),
              tp_g_value_slice_new_take_string (s));
        }

      g_object_notify ((GObject *) self, "connection-status");
      g_object_notify ((GObject *) self, "connection-status-reason");
      g_object_notify ((GObject *) self, "connection-error");
      g_object_notify ((GObject *) self, "connection-error-details");
    }
}

static void
_tp_account_removed_cb (TpAccount *self,
    gpointer unused G_GNUC_UNUSED,
    GObject *object G_GNUC_UNUSED)
{
  GError e = { TP_DBUS_ERRORS, TP_DBUS_ERROR_OBJECT_REMOVED,
               "Account removed" };

  if (self->priv->removed)
    return;

  self->priv->removed = TRUE;

  tp_proxy_invalidate ((TpProxy *) self, &e);
}

static void
set_connection_prepare_cb (GObject *object,
    GAsyncResult *res,
    gpointer user_data)
{
  TpConnection *connection = (TpConnection *) object;
  TpAccount *self = user_data;
  GError *error = NULL;

  if (!tp_proxy_prepare_finish (object, res, &error))
    {
      DEBUG ("Error preparing connection: %s", error->message);
      g_clear_error (&error);
      goto OUT;
    }

  /* Connection could have changed again while we were preparing it */
  if (self->priv->connection == connection)
    {
      self->priv->connection_prepared = TRUE;
      g_object_notify ((GObject *) self, "connection");
    }

OUT:
  g_object_unref (self);
}

static void _tp_account_set_connection (TpAccount *account, const gchar *path);

static void
connection_invalidated_cb (TpConnection *connection,
    guint domain,
    gint code,
    gchar *message,
    TpAccount *account)
{
  _tp_account_set_connection (account, "/");
}

static void
_tp_account_set_connection (TpAccount *account,
    const gchar *path)
{
  TpAccountPrivate *priv = account->priv;
  gboolean had_public_connection;
  gboolean have_public_connection;
  GError *error = NULL;

  if (priv->connection != NULL)
    {
      const gchar *current;

      /* Do nothing if we already have a connection for the same path */
      current = tp_proxy_get_object_path (priv->connection);
      if (!tp_strdiff (current, path))
        return;

      g_signal_handlers_disconnect_by_func (priv->connection,
          connection_invalidated_cb, account);
    }

  had_public_connection = (priv->connection != NULL &&
      !connection_is_internal (account));

  tp_clear_object (&account->priv->connection);
  g_free (priv->connection_object_path);
  priv->connection_object_path = g_strdup (path);
  priv->connection_prepared = FALSE;

  /* The account has no connection */
  if (!tp_strdiff ("/", path))
    {
      /* Do not emit change notifications if the connection was not yet made
       * public */
      if (had_public_connection)
        g_object_notify (G_OBJECT (account), "connection");

      return;
    }

  priv->connection = tp_simple_client_factory_ensure_connection (
      tp_proxy_get_factory (account), path, NULL, &error);

  if (priv->connection == NULL)
    {
      DEBUG ("Failed to create a new TpConnection: %s",
          error->message);
      g_error_free (error);
    }
  else
    {
      tp_g_signal_connect_object (priv->connection, "invalidated",
          G_CALLBACK (connection_invalidated_cb), account, 0);

      _tp_connection_set_account (priv->connection, account);
      if (tp_proxy_is_prepared (account, TP_ACCOUNT_FEATURE_CONNECTION))
        {
          GArray *features;

          features = tp_simple_client_factory_dup_connection_features (
              tp_proxy_get_factory (account), priv->connection);

          tp_proxy_prepare_async (priv->connection, (GQuark *) features->data,
              set_connection_prepare_cb, g_object_ref (account));

          g_array_unref (features);
        }
    }

  have_public_connection = (priv->connection != NULL &&
      !connection_is_internal (account));

  /* Do not emit signal if connection wasn't public and still isn't */
  if (had_public_connection || have_public_connection)
    g_object_notify (G_OBJECT (account), "connection");
}

static void
_tp_account_got_all_storage_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *object)
{
  TpAccount *self = TP_ACCOUNT (proxy);
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    DEBUG ("Error getting Storage properties: %s", error->message);

  if (properties == NULL)
    self->priv->storage_provider = NULL;
  else
    self->priv->storage_provider = g_strdup (tp_asv_get_string (properties,
          "StorageProvider"));

  if (!tp_str_empty (self->priv->storage_provider))
    {
      self->priv->storage_identifier = tp_g_value_slice_dup (
          tp_asv_get_boxed (properties, "StorageIdentifier", G_TYPE_VALUE));
      self->priv->storage_restrictions = tp_asv_get_uint32 (properties,
          "StorageRestrictions", NULL);
    }

  /* if the StorageProvider isn't known, set it to the empty string */
  if (self->priv->storage_provider == NULL)
    self->priv->storage_provider = g_strdup ("");

  g_simple_async_result_complete_in_idle (result);
}

static void
tp_account_prepare_storage_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpAccount *self = TP_ACCOUNT (proxy);
  GSimpleAsyncResult *result;

  result = g_simple_async_result_new ((GObject *) proxy, callback, user_data,
      tp_account_prepare_storage_async);

  g_assert (self->priv->storage_provider == NULL);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_ACCOUNT_INTERFACE_STORAGE,
      _tp_account_got_all_storage_cb, result, g_object_unref, G_OBJECT (self));
}

static void
_tp_account_update (TpAccount *account,
    GHashTable *properties)
{
  TpProxy *proxy = TP_PROXY (account);
  TpAccountPrivate *priv = account->priv;
  GValueArray *arr;
  TpConnectionStatus old_s = priv->connection_status;
  gboolean status_changed = FALSE;
  gboolean presence_changed = FALSE;
  const gchar *status;
  const gchar *message;

  tp_proxy_add_interfaces (proxy, tp_asv_get_strv (properties, "Interfaces"));

  if (g_hash_table_lookup (properties, "ConnectionStatus") != NULL)
    {
      priv->connection_status =
        tp_asv_get_uint32 (properties, "ConnectionStatus", NULL);

      if (old_s != priv->connection_status)
        status_changed = TRUE;
    }

  if (g_hash_table_lookup (properties, "ConnectionStatusReason") != NULL)
    {
      TpConnectionStatusReason old = priv->reason;

      priv->reason =
        tp_asv_get_uint32 (properties, "ConnectionStatusReason", NULL);

      if (old != priv->reason)
        status_changed = TRUE;
    }

  if (g_hash_table_lookup (properties, "ConnectionError") != NULL)
    {
      const gchar *new_error = tp_asv_get_string (properties,
          "ConnectionError");

      if (tp_str_empty (new_error))
        new_error = NULL;

      if (tp_strdiff (new_error, priv->error))
        {
          tp_clear_pointer (&priv->error, g_free);
          priv->error = g_strdup (new_error);
          status_changed = TRUE;
        }
    }

  if (g_hash_table_lookup (properties, "ConnectionErrorDetails") != NULL)
    {
      const GHashTable *details = tp_asv_get_boxed (properties,
          "ConnectionErrorDetails", TP_HASH_TYPE_STRING_VARIANT_MAP);

      if ((details != NULL && tp_asv_size (details) > 0) ||
          tp_asv_size (priv->error_details) > 0)
        {
          g_hash_table_remove_all (priv->error_details);

          if (details != NULL)
            tp_g_hash_table_update (priv->error_details,
                (GHashTable *) details,
                (GBoxedCopyFunc) g_strdup,
                (GBoxedCopyFunc) tp_g_value_slice_dup);

          status_changed = TRUE;
        }
    }

  if (status_changed)
    {
      if (priv->connection_status == TP_CONNECTION_STATUS_CONNECTED)
        {
          /* our connection status is CONNECTED - clear any error we may
           * have recorded previously */
          g_hash_table_remove_all (priv->error_details);
          tp_clear_pointer (&priv->error, g_free);
        }
      else if (priv->error == NULL)
        {
          /* our connection status is worse than CONNECTED but the
           * AccountManager didn't tell us why, so attempt to guess
           * a detailed error from the status reason */
          const gchar *guessed = NULL;

          _tp_connection_status_reason_to_gerror (priv->reason,
              old_s, &guessed, NULL);

          if (guessed == NULL)
            guessed = TP_ERROR_STR_DISCONNECTED;

          priv->error = g_strdup (guessed);
        }
    }

  if (g_hash_table_lookup (properties, "CurrentPresence") != NULL)
    {
      presence_changed = TRUE;
      arr = tp_asv_get_boxed (properties, "CurrentPresence",
          TP_STRUCT_TYPE_SIMPLE_PRESENCE);

      tp_value_array_unpack (arr, 3,
          &priv->cur_presence,
          &status,
          &message);
      g_free (priv->cur_status);
      priv->cur_status = g_strdup (status);
      g_free (priv->cur_message);
      priv->cur_message = g_strdup (message);
    }

  if (g_hash_table_lookup (properties, "RequestedPresence") != NULL)
    {
      arr = tp_asv_get_boxed (properties, "RequestedPresence",
          TP_STRUCT_TYPE_SIMPLE_PRESENCE);

      tp_value_array_unpack (arr, 3,
          &priv->requested_presence,
          &status,
          &message);
      g_free (priv->requested_status);
      priv->requested_status = g_strdup (status);
      g_free (priv->requested_message);
      priv->requested_message = g_strdup (message);

      g_object_notify (G_OBJECT (account), "requested-presence-type");
      g_object_notify (G_OBJECT (account), "requested-status");
      g_object_notify (G_OBJECT (account), "requested-status-message");
    }

  if (g_hash_table_lookup (properties, "AutomaticPresence") != NULL)
    {
      arr = tp_asv_get_boxed (properties, "AutomaticPresence",
          TP_STRUCT_TYPE_SIMPLE_PRESENCE);

      tp_value_array_unpack (arr, 3,
          &priv->auto_presence,
          &status,
          &message);
      g_free (priv->auto_status);
      priv->auto_status = g_strdup (status);
      g_free (priv->auto_message);
      priv->auto_message = g_strdup (message);

      g_object_notify (G_OBJECT (account), "automatic-presence-type");
      g_object_notify (G_OBJECT (account), "automatic-status");
      g_object_notify (G_OBJECT (account), "automatic-status-message");
    }

  if (g_hash_table_lookup (properties, "DisplayName") != NULL)
    {
      gchar *old = priv->display_name;

      priv->display_name =
        g_strdup (tp_asv_get_string (properties, "DisplayName"));

      if (tp_strdiff (old, priv->display_name))
        g_object_notify (G_OBJECT (account), "display-name");

      g_free (old);
    }

  if (g_hash_table_lookup (properties, "Nickname") != NULL)
    {
      gchar *old = priv->nickname;

      priv->nickname = g_strdup (tp_asv_get_string (properties, "Nickname"));

      if (tp_strdiff (old, priv->nickname))
        g_object_notify (G_OBJECT (account), "nickname");

      g_free (old);
    }

  if (g_hash_table_lookup (properties, "Supersedes") != NULL)
    {
      GStrv old = priv->supersedes;
      GPtrArray *new_arr = tp_asv_get_boxed (properties, "Supersedes",
          TP_ARRAY_TYPE_OBJECT_PATH_LIST);
      gboolean changed = FALSE;
      guint i;

      if (new_arr == NULL)
        {
          priv->supersedes = g_new0 (gchar *, 1);
        }
      else
        {
          priv->supersedes = g_new0 (gchar *, new_arr->len + 1);

          for (i = 0; i < new_arr->len; i++)
            priv->supersedes[i] = g_strdup (g_ptr_array_index (new_arr, i));
        }

      if (new_arr == NULL || new_arr->len == 0)
        {
          changed = (old != NULL && *old != NULL);
        }
      else if (old == NULL || *old == NULL ||
          g_strv_length (old) != new_arr->len)
        {
          changed = TRUE;
        }
      else
        {
          for (i = 0; i < new_arr->len; i++)
            {
              if (tp_strdiff (old[i], priv->supersedes[i]))
                {
                  changed = TRUE;
                  break;
                }
            }
        }

      if (changed)
        g_object_notify (G_OBJECT (account), "supersedes");

      g_strfreev (old);
    }

  if (g_hash_table_lookup (properties, "NormalizedName") != NULL)
    {
      gchar *old = priv->normalized_name;

      priv->normalized_name = g_strdup (tp_asv_get_string (properties,
            "NormalizedName"));

      if (tp_strdiff (old, priv->normalized_name))
        g_object_notify (G_OBJECT (account), "normalized-name");

      g_free (old);
    }

  if (g_hash_table_lookup (properties, "Icon") != NULL)
    {
      const gchar *icon_name;
      gchar *old = priv->icon_name;

      icon_name = tp_asv_get_string (properties, "Icon");

      if (tp_str_empty (icon_name))
        priv->icon_name = g_strdup_printf ("im-%s", priv->proto_name);
      else
        priv->icon_name = g_strdup (icon_name);

      if (tp_strdiff (old, priv->icon_name))
        g_object_notify (G_OBJECT (account), "icon-name");

      g_free (old);
    }

  if (g_hash_table_lookup (properties, "Enabled") != NULL)
    {
      gboolean enabled = tp_asv_get_boolean (properties, "Enabled", NULL);
      if (priv->enabled != enabled)
        {
          priv->enabled = enabled;
          g_object_notify (G_OBJECT (account), "enabled");
        }
    }

  if (g_hash_table_lookup (properties, "Service") != NULL)
    {
      const gchar *service;
      gchar *old = priv->service;

      service = tp_asv_get_string (properties, "Service");

      if (tp_str_empty (service))
        priv->service = g_strdup (priv->proto_name);
      else
        priv->service = g_strdup (service);

      if (tp_strdiff (old, priv->service))
        g_object_notify (G_OBJECT (account), "service");

      g_free (old);
    }

  if (g_hash_table_lookup (properties, "Valid") != NULL)
    {
      gboolean old = priv->valid;

      priv->valid = tp_asv_get_boolean (properties, "Valid", NULL);

      if (old != priv->valid)
        g_object_notify (G_OBJECT (account), "valid");
    }

  if (g_hash_table_lookup (properties, "Parameters") != NULL)
    {
      GHashTable *parameters;

      parameters = tp_asv_get_boxed (properties, "Parameters",
          TP_HASH_TYPE_STRING_VARIANT_MAP);

      if (priv->parameters != NULL)
        g_hash_table_unref (priv->parameters);

      priv->parameters = g_boxed_copy (TP_HASH_TYPE_STRING_VARIANT_MAP,
          parameters);
      /* this isn't a property, so we don't notify */
    }

  if (status_changed)
    {
      g_signal_emit (account, signals[STATUS_CHANGED], 0,
          old_s, priv->connection_status, priv->reason, priv->error,
          priv->error_details);

      g_object_notify (G_OBJECT (account), "connection-status");
      g_object_notify (G_OBJECT (account), "connection-status-reason");
      g_object_notify (G_OBJECT (account), "connection-error");
      g_object_notify (G_OBJECT (account), "connection-error-details");
    }

  if (presence_changed)
    {
      g_signal_emit (account, signals[PRESENCE_CHANGED], 0,
          priv->cur_presence, priv->cur_status, priv->cur_message);
      g_object_notify (G_OBJECT (account), "current-presence-type");
      g_object_notify (G_OBJECT (account), "current-status");
      g_object_notify (G_OBJECT (account), "current-status-message");
    }

  if (g_hash_table_lookup (properties, "Connection") != NULL)
    {
      const gchar *path = tp_asv_get_object_path (properties, "Connection");

      _tp_account_set_connection (account, path);
    }

  if (g_hash_table_lookup (properties, "ChangingPresence") != NULL)
    {
      gboolean old = priv->changing_presence;

      priv->changing_presence =
        tp_asv_get_boolean (properties, "ChangingPresence", NULL);

      if (old != priv->changing_presence)
        g_object_notify (G_OBJECT (account), "changing-presence");
    }

  if (g_hash_table_lookup (properties, "ConnectAutomatically") != NULL)
    {
      gboolean old = priv->connect_automatically;

      priv->connect_automatically =
        tp_asv_get_boolean (properties, "ConnectAutomatically", NULL);

      if (old != priv->connect_automatically)
        g_object_notify (G_OBJECT (account), "connect-automatically");
    }

  if (g_hash_table_lookup (properties, "HasBeenOnline") != NULL)
    {
      gboolean old = priv->has_been_online;

      priv->has_been_online =
        tp_asv_get_boolean (properties, "HasBeenOnline", NULL);

      if (old != priv->has_been_online)
        g_object_notify (G_OBJECT (account), "has-been-online");
    }

  _tp_proxy_set_feature_prepared (proxy, TP_ACCOUNT_FEATURE_CORE, TRUE);
}

static void
_tp_account_properties_changed (TpAccount *proxy,
    GHashTable *properties,
    gpointer user_data,
    GObject *weak_object)
{
  TpAccount *self = TP_ACCOUNT (weak_object);

  if (!tp_proxy_is_prepared (self, TP_ACCOUNT_FEATURE_CORE))
    return;

  _tp_account_update (self, properties);
}

static void
avatar_changed_cb (TpAccount *self,
    gpointer user_data,
    GObject *weak_object)
{
  g_signal_emit (self, signals[AVATAR_CHANGED], 0);
}

static void
_tp_account_got_all_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpAccount *self = TP_ACCOUNT (weak_object);

  DEBUG ("Got whole set of properties for %s",
      tp_proxy_get_object_path (self));

  if (error != NULL)
    {
      DEBUG ("Failed to get the initial set of account properties: %s",
          error->message);
      tp_proxy_invalidate ((TpProxy *) self, error);
      return;
    }

  _tp_account_update (self, properties);

  /* We can't try connecting this signal earlier as tp_proxy_add_interfaces()
   * has to be called first if we support the Avatar interface. */
  tp_cli_account_interface_avatar_connect_to_avatar_changed (self,
      avatar_changed_cb, NULL, NULL, G_OBJECT (self), NULL);
}

static void
addressing_props_changed (TpAccount *self,
    GHashTable *changed_properties)
{
  const gchar * const * v;

  if (self->priv->uri_schemes == NULL)
    /* We did not fetch the initial value yet, ignoring */
    return;

  v = tp_asv_get_strv (changed_properties, "URISchemes");
  if (v == NULL)
    return;

  g_strfreev (self->priv->uri_schemes);
  self->priv->uri_schemes = g_strdupv ((GStrv) v);

  g_object_notify (G_OBJECT (self), "uri-schemes");
}

static void
dbus_properties_changed_cb (TpProxy *proxy,
    const gchar *interface_name,
    GHashTable *changed_properties,
    const gchar **invalidated_properties,
    gpointer user_data,
    GObject *weak_object)
{
  TpAccount *self = TP_ACCOUNT (weak_object);

  if (!tp_strdiff (interface_name, TP_IFACE_ACCOUNT_INTERFACE_ADDRESSING))
    {
      addressing_props_changed (self, changed_properties);
    }
}

static void
_tp_account_constructed (GObject *object)
{
  TpAccount *self = TP_ACCOUNT (object);
  TpAccountPrivate *priv = self->priv;
  void (*chain_up) (GObject *) =
    ((GObjectClass *) tp_account_parent_class)->constructed;
  GError *error = NULL;
  TpProxySignalConnection *sc;

  if (chain_up != NULL)
    chain_up (object);

  g_return_if_fail (tp_proxy_get_dbus_daemon (self) != NULL);

  _tp_proxy_ensure_factory (self, NULL);

  sc = tp_cli_account_connect_to_removed (self, _tp_account_removed_cb,
      NULL, NULL, NULL, &error);

  if (sc == NULL)
    {
      CRITICAL ("Couldn't connect to Removed: %s", error->message);
      g_error_free (error);
    }

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  tp_account_parse_object_path (tp_proxy_get_object_path (self),
      &(priv->cm_name), &(priv->proto_name), NULL, NULL);
  G_GNUC_END_IGNORE_DEPRECATIONS

  priv->icon_name = g_strdup_printf ("im-%s", priv->proto_name);
  priv->service = g_strdup (priv->proto_name);

  g_signal_connect (self, "invalidated",
      G_CALLBACK (_tp_account_invalidated_cb), NULL);

  tp_cli_account_connect_to_account_property_changed (self,
      _tp_account_properties_changed, NULL, NULL, object, NULL);

  tp_cli_dbus_properties_connect_to_properties_changed (self,
      dbus_properties_changed_cb, NULL, NULL, object, NULL);

  tp_cli_dbus_properties_call_get_all (self, -1, TP_IFACE_ACCOUNT,
      _tp_account_got_all_cb, NULL, NULL, G_OBJECT (self));
}

static void
_tp_account_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpAccount *self = TP_ACCOUNT (object);

  switch (prop_id)
    {
    case PROP_ENABLED:
      g_value_set_boolean (value, self->priv->enabled);
      break;
    case PROP_CURRENT_PRESENCE_TYPE:
      g_value_set_uint (value, self->priv->cur_presence);
      break;
    case PROP_CURRENT_STATUS:
      g_value_set_string (value, self->priv->cur_status);
      break;
    case PROP_CURRENT_STATUS_MESSAGE:
      g_value_set_string (value, self->priv->cur_message);
      break;
    case PROP_CONNECTION_STATUS:
      g_value_set_uint (value, self->priv->connection_status);
      break;
    case PROP_CONNECTION_STATUS_REASON:
      g_value_set_uint (value, self->priv->reason);
      break;
    case PROP_CONNECTION_ERROR:
      g_value_set_string (value, self->priv->error);
      break;
    case PROP_CONNECTION_ERROR_DETAILS:
      g_value_set_boxed (value, self->priv->error_details);
      break;
    case PROP_CONNECTION:
      g_value_set_object (value,
          tp_account_get_connection (self));
      break;
    case PROP_DISPLAY_NAME:
      g_value_set_string (value,
          tp_account_get_display_name (self));
      break;
    case PROP_CONNECTION_MANAGER:
      g_value_set_string (value, self->priv->cm_name);
      break;
    case PROP_CM_NAME:
      g_value_set_string (value, self->priv->cm_name);
      break;
    case PROP_PROTOCOL:
      g_value_set_string (value, self->priv->proto_name);
      break;
    case PROP_PROTOCOL_NAME:
      g_value_set_string (value, self->priv->proto_name);
      break;
    case PROP_ICON_NAME:
      g_value_set_string (value, self->priv->icon_name);
      break;
    case PROP_CHANGING_PRESENCE:
      g_value_set_boolean (value, self->priv->changing_presence);
      break;
    case PROP_CONNECT_AUTOMATICALLY:
      g_value_set_boolean (value, self->priv->connect_automatically);
      break;
    case PROP_HAS_BEEN_ONLINE:
      g_value_set_boolean (value, self->priv->has_been_online);
      break;
    case PROP_SERVICE:
      g_value_set_string (value, self->priv->service);
      break;
    case PROP_VALID:
      g_value_set_boolean (value, self->priv->valid);
      break;
    case PROP_REQUESTED_PRESENCE_TYPE:
      g_value_set_uint (value, self->priv->requested_presence);
      break;
    case PROP_REQUESTED_STATUS:
      g_value_set_string (value, self->priv->requested_status);
      break;
    case PROP_REQUESTED_STATUS_MESSAGE:
      g_value_set_string (value, self->priv->requested_message);
      break;
    case PROP_NICKNAME:
      g_value_set_string (value, self->priv->nickname);
      break;
    case PROP_SUPERSEDES:
      g_value_set_boxed (value, self->priv->supersedes);
      break;
    case PROP_URI_SCHEMES:
      g_value_set_boxed (value, self->priv->uri_schemes);
      break;
    case PROP_AUTOMATIC_PRESENCE_TYPE:
      g_value_set_uint (value, self->priv->auto_presence);
      break;
    case PROP_AUTOMATIC_STATUS:
      g_value_set_string (value, self->priv->auto_status);
      break;
    case PROP_AUTOMATIC_STATUS_MESSAGE:
      g_value_set_string (value, self->priv->auto_message);
      break;
    case PROP_NORMALIZED_NAME:
      g_value_set_string (value,
          tp_account_get_normalized_name (self));
      break;
    case PROP_STORAGE_PROVIDER:
      g_value_set_string (value, self->priv->storage_provider);
      break;
    case PROP_STORAGE_IDENTIFIER:
      g_value_set_boxed (value, self->priv->storage_identifier);
      break;
    case PROP_STORAGE_IDENTIFIER_VARIANT:
      g_value_take_variant (value,
          tp_account_dup_storage_identifier_variant (self));
      break;
    case PROP_STORAGE_RESTRICTIONS:
      g_value_set_uint (value, self->priv->storage_restrictions);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
      break;
    }
}

static void
_tp_account_dispose (GObject *object)
{
  TpAccount *self = TP_ACCOUNT (object);
  TpAccountPrivate *priv = self->priv;

  if (priv->dispose_has_run)
    return;

  priv->dispose_has_run = TRUE;

  _tp_account_set_connection (self, "/");

  /* release any references held by the object here */
  if (G_OBJECT_CLASS (tp_account_parent_class)->dispose != NULL)
    G_OBJECT_CLASS (tp_account_parent_class)->dispose (object);
}

static void
_tp_account_finalize (GObject *object)
{
  TpAccount *self = TP_ACCOUNT (object);
  TpAccountPrivate *priv = self->priv;

  g_free (priv->connection_object_path);
  g_free (priv->cur_status);
  g_free (priv->cur_message);
  g_free (priv->requested_status);
  g_free (priv->requested_message);
  g_free (priv->error);
  g_free (priv->auto_status);
  g_free (priv->auto_message);
  g_free (priv->normalized_name);

  g_free (priv->nickname);
  g_strfreev (priv->supersedes);

  g_free (priv->cm_name);
  g_free (priv->proto_name);
  g_free (priv->icon_name);
  g_free (priv->display_name);
  g_free (priv->service);

  tp_clear_pointer (&priv->parameters, g_hash_table_unref);
  tp_clear_pointer (&priv->error_details, g_hash_table_unref);

  g_free (priv->storage_provider);
  tp_clear_pointer (&priv->storage_identifier, tp_g_value_slice_free);

  g_strfreev (priv->uri_schemes);

  /* free any data held directly by the object here */
  if (G_OBJECT_CLASS (tp_account_parent_class)->finalize != NULL)
    G_OBJECT_CLASS (tp_account_parent_class)->finalize (object);
}

static void
tp_account_class_init (TpAccountClass *klass)
{
  TpProxyClass *proxy_class = (TpProxyClass *) klass;
  GObjectClass *object_class = (GObjectClass *) klass;

  g_type_class_add_private (klass, sizeof (TpAccountPrivate));

  object_class->constructed = _tp_account_constructed;
  object_class->get_property = _tp_account_get_property;
  object_class->dispose = _tp_account_dispose;
  object_class->finalize = _tp_account_finalize;

  /**
   * TpAccount:enabled:
   *
   * Whether this account is enabled or not.
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is FALSE.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_ENABLED,
      g_param_spec_boolean ("enabled",
          "Enabled",
          "Whether this account is enabled or not",
          FALSE,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:current-presence-type:
   *
   * The account connection's current presence type
   * (a %TpConnectionPresenceType).
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail. Change notifications for current-presence-type,
   * current-status and current-status-message are always emitted together,
   * so it is sufficient to connect to one of the notification signals.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %TP_CONNECTION_PRESENCE_TYPE_UNSET.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_CURRENT_PRESENCE_TYPE,
      g_param_spec_uint ("current-presence-type",
          "Presence",
          "The account connection's current presence type",
          0,
          TP_NUM_CONNECTION_PRESENCE_TYPES,
          TP_CONNECTION_PRESENCE_TYPE_UNSET,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:current-status:
   *
   * The current Status string of the account.
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail. Change notifications for current-presence-type,
   * current-status and current-status-message are always emitted together,
   * so it is sufficient to connect to one of the notification signals.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_CURRENT_STATUS,
      g_param_spec_string ("current-status",
          "Current Status",
          "The Status string of the account",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:current-status-message:
   *
   * The current status message message of the account.
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail. Change notifications for current-presence-type,
   * current-status and current-status-message are always emitted together,
   * so it is sufficient to connect to one of the notification signals.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_CURRENT_STATUS_MESSAGE,
      g_param_spec_string ("current-status-message",
          "current-status-message",
          "The Status message string of the account",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:changing-presence:
   *
   * %TRUE if an attempt is currently being made to change the account's
   * presence (#TpAccount:current-presence-type, #TpAccount:current-status
   * and #TpAccount:current-status-message) to match its requested presence
   * (#TpAccount:requested-presence-type, #TpAccount:requested-status
   * and #TpAccount:requested-status-message).
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %FALSE.
   *
   * Since: 0.11.6
   */
  g_object_class_install_property (object_class, PROP_CHANGING_PRESENCE,
      g_param_spec_boolean ("changing-presence",
          "Changing Presence",
          "TRUE if presence is changing",
          FALSE,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:connection-status:
   *
   * The account's connection status type (a %TpConnectionStatus).
   *
   * One can receive change notifications on this property by connecting
   * to the #TpAccount::status-changed signal, or by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %TP_CONNECTION_STATUS_DISCONNECTED.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_CONNECTION_STATUS,
      g_param_spec_uint ("connection-status",
          "ConnectionStatus",
          "The account's connection status type",
          0,
          TP_NUM_CONNECTION_STATUSES,
          TP_CONNECTION_STATUS_DISCONNECTED,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:connection-status-reason:
   *
   * The account's connection status reason (a %TpConnectionStatusReason).
   *
   * One can receive change notifications on this property by connecting
   * to the #TpAccount::status-changed signal, or by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %TP_CONNECTION_STATUS_REASON_NONE_SPECIFIED.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_CONNECTION_STATUS_REASON,
      g_param_spec_uint ("connection-status-reason",
          "ConnectionStatusReason",
          "The account's connection status reason",
          0,
          TP_NUM_CONNECTION_STATUS_REASONS,
          TP_CONNECTION_STATUS_REASON_NONE_SPECIFIED,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:connection-error:
   *
   * The D-Bus error name for the last disconnection or connection failure,
   * (in particular, %TP_ERROR_STR_CANCELLED if it was disconnected by user
   * request), or %NULL if the account is connected.
   *
   * One can receive change notifications on this property by connecting
   * to the #TpAccount::status-changed signal, or by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.11.7
   */
  g_object_class_install_property (object_class, PROP_CONNECTION_ERROR,
      g_param_spec_string ("connection-error",
          "ConnectionError",
          "The account's last connection error",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:connection-error-details:
   *
   * A map from string to #GValue containing extensible error details
   * related to #TpAccount:connection-error. Functions like tp_asv_get_string()
   * can be used to read from this map.
   *
   * The keys for this map are defined by
   * <ulink url="http://telepathy.freedesktop.org/spec/">the Telepathy D-Bus
   * Interface Specification</ulink>. They will typically include
   * <literal>debug-message</literal>, which is a debugging message in the C
   * locale, analogous to #GError<!-- -->.message.
   *
   * One can receive change notifications on this property by connecting
   * to the #TpAccount::status-changed signal, or by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * an empty map.
   *
   * Since: 0.11.7
   */
  g_object_class_install_property (object_class, PROP_CONNECTION_ERROR_DETAILS,
      g_param_spec_boxed ("connection-error-details",
          "ConnectionErrorDetails",
          "Extensible details of the account's last connection error",
          G_TYPE_HASH_TABLE,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:connection:
   *
   * The connection of the account, or %NULL if account is offline.
   * Note that the returned #TpConnection is not guaranteed to have any
   * features pre-prepared (not even %TP_CONNECTION_FEATURE_CORE) unless
   * %TP_ACCOUNT_FEATURE_CONNECTION has been prepared on the account
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail. If %TP_ACCOUNT_FEATURE_CONNECTION has been prepared, this signal
   * will be delayed until the connection is ready.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_CONNECTION,
      g_param_spec_object ("connection",
          "Connection",
          "The account's connection",
          TP_TYPE_CONNECTION,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:display-name:
   *
   * The account's display name, from the DisplayName property.
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_DISPLAY_NAME,
      g_param_spec_string ("display-name",
          "DisplayName",
          "The account's display name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:connection-manager:
   *
   * The account's connection manager name.
   *
   * Since: 0.9.0
   * Deprecated: Use #TpAccount:cm-name instead.
   */
  g_object_class_install_property (object_class, PROP_CONNECTION_MANAGER,
      g_param_spec_string ("connection-manager",
          "Connection manager",
          "The account's connection manager name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:protocol:
   *
   * The account's machine-readable protocol name, such as "jabber", "msn" or
   * "local-xmpp". Recommended names for most protocols can be found in the
   * Telepathy D-Bus Interface Specification.
   *
   * Since: 0.9.0
   * Deprecated: Use #TpAccount:protocol-name instead.
   */
  g_object_class_install_property (object_class, PROP_PROTOCOL,
      g_param_spec_string ("protocol",
          "Protocol",
          "The account's protocol name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:cm-name:
   *
   * The account's connection manager name.
   *
   * Since: 0.19.3
   */
  g_object_class_install_property (object_class, PROP_CM_NAME,
      g_param_spec_string ("cm-name",
          "Connection manager",
          "The account's connection manager name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:protocol-name:
   *
   * The account's machine-readable protocol name, such as "jabber", "msn" or
   * "local-xmpp". Recommended names for most protocols can be found in the
   * Telepathy D-Bus Interface Specification.
   *
   * Since: 0.19.3
   */
  g_object_class_install_property (object_class, PROP_PROTOCOL_NAME,
      g_param_spec_string ("protocol-name",
          "Protocol",
          "The account's protocol name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:service:
   *
   * A machine-readable name identifying a specific service to which this
   * account connects, or a copy of #TpAccount:protocol if there is no more
   * specific service.
   *
   * Well-known names for various services can be found in the Telepathy D-Bus
   * Interface Specification.
   *
   * For instance, accounts for the "jabber" protocol should have the service
   * names "google-talk", "ovi-chat", "facebook" and "lj-talk" for accounts
   * that connect to Google Talk, Ovi Chat, Facebook and Livejournal,
   * respectively, and this property will be "jabber" for accounts that
   * connect to a generic Jabber server.
   *
   * To change this property, use
   * tp_account_set_service_async().
   *
   * Since: 0.11.9
   */
  g_object_class_install_property (object_class, PROP_SERVICE,
      g_param_spec_string ("service",
          "Service",
          "The account's service name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:icon-name:
   *
   * The account's icon name. To change this propery, use
   * tp_account_set_icon_name_async().
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_ICON_NAME,
      g_param_spec_string ("icon-name",
          "Icon",
          "The account's icon name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:connect-automatically:
   *
   * Whether the account should connect automatically or not. To change this
   * property, use tp_account_set_connect_automatically_async().
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %FALSE.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_CONNECT_AUTOMATICALLY,
      g_param_spec_boolean ("connect-automatically",
          "ConnectAutomatically",
          "Whether this account should connect automatically or not",
          FALSE,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:has-been-online:
   *
   * Whether this account has been online or not.
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %FALSE.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_HAS_BEEN_ONLINE,
      g_param_spec_boolean ("has-been-online",
          "HasBeenOnline",
          "Whether this account has been online or not",
          FALSE,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:valid:
   *
   * Whether this account is valid.
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %FALSE.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_VALID,
      g_param_spec_boolean ("valid",
          "Valid",
          "Whether this account is valid",
          FALSE,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:requested-presence-type:
   *
   * The account's requested presence type (a #TpConnectionPresenceType).
   *
   * Since 0.13.8,
   * one can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail. Change notifications for requested-presence-type,
   * requested-status and requested-status-message are always emitted together,
   * so it is sufficient to connect to one of the notification signals.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_REQUESTED_PRESENCE_TYPE,
      g_param_spec_uint ("requested-presence-type",
          "RequestedPresence",
          "The account's requested presence type",
          0,
          TP_NUM_CONNECTION_PRESENCE_TYPES,
          TP_CONNECTION_PRESENCE_TYPE_UNSET,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:requested-status:
   *
   * The requested Status string of the account.
   *
   * Since 0.13.8,
   * one can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail. Change notifications for requested-presence-type,
   * requested-status and requested-status-message are always emitted together,
   * so it is sufficient to connect to one of the notification signals.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_REQUESTED_STATUS,
      g_param_spec_string ("requested-status",
          "RequestedStatus",
          "The account's requested status string",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:requested-status-message:
   *
   * The requested status message message of the account.
   *
   * Since 0.13.8,
   * one can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail. Change notifications for requested-presence-type,
   * requested-status and requested-status-message are always emitted together,
   * so it is sufficient to connect to one of the notification signals.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_REQUESTED_STATUS_MESSAGE,
      g_param_spec_string ("requested-status-message",
          "RequestedStatusMessage",
          "The requested Status message string of the account",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:nickname:
   *
   * The nickname that should be set for the user on this account.
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.9.0
   */
  g_object_class_install_property (object_class, PROP_NICKNAME,
      g_param_spec_string ("nickname",
          "Nickname",
          "The account's nickname",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:automatic-presence-type:
   *
   * The account's automatic presence type (a #TpConnectionPresenceType).
   *
   * When the account is put online automatically, for instance to make a
   * channel request or because network connectivity becomes available,
   * the automatic presence type, status and message will be copied to
   * their "requested" counterparts.
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail. Change notifications for automatic-presence-type,
   * automatic-status and automatic-status-message are always emitted together,
   * so it is sufficient to connect to one of the notification signals.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %TP_CONNECTION_PRESENCE_TYPE_UNSET.
   *
   * Since: 0.13.8
   */
  g_object_class_install_property (object_class, PROP_AUTOMATIC_PRESENCE_TYPE,
      g_param_spec_uint ("automatic-presence-type",
          "AutomaticPresence type",
          "Presence type used to put the account online automatically",
          0,
          TP_NUM_CONNECTION_PRESENCE_TYPES,
          TP_CONNECTION_PRESENCE_TYPE_UNSET,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:automatic-status:
   *
   * The string status name to use in conjunction with the
   * #TpAccount:automatic-presence-type.
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail. Change notifications for automatic-presence-type,
   * automatic-status and automatic-status-message are always emitted together,
   * so it is sufficient to connect to one of the notification signals.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.13.8
   */
  g_object_class_install_property (object_class, PROP_AUTOMATIC_STATUS,
      g_param_spec_string ("automatic-status",
          "AutomaticPresence status",
          "Presence status used to put the account online automatically",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:automatic-status-message:
   *
   * The user-defined message to use in conjunction with the
   * #TpAccount:automatic-presence-type.
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail. Change notifications for automatic-presence-type,
   * automatic-status and automatic-status-message are always emitted together,
   * so it is sufficient to connect to one of the notification signals.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.13.8
   */
  g_object_class_install_property (object_class, PROP_AUTOMATIC_STATUS_MESSAGE,
      g_param_spec_string ("automatic-status-message",
          "AutomaticPresence message",
          "User-defined message used to put the account online automatically",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:normalized-name:
   *
   * The normalized form of the user's own unique identifier on this
   * protocol. For example, on XMPP accounts this is the user's JID; on
   * ICQ this is the user's UIN; and so on.
   *
   * One can receive change notifications on this property by connecting
   * to the #GObject::notify signal and using this property as the signal
   * detail.
   *
   * This is not guaranteed to have been retrieved until
   * tp_proxy_prepare_async() has finished; until then, the value is
   * %NULL.
   *
   * Since: 0.13.8
   */
  g_object_class_install_property (object_class, PROP_NORMALIZED_NAME,
      g_param_spec_string ("normalized-name",
          "NormalizedName",
          "The normalized identifier of the user",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:storage-provider:
   *
   * The storage provider for this account.
   *
   * The name of the account storage implementation. When this
   * is the empty string the account is internally stored.
   *
   * This property cannot change once an Account has been created.
   *
   * This is not guaranteed to have been retrieved until the
   * %TP_ACCOUNT_FEATURE_STORAGE feature has been prepared; until then,
   * the value is %NULL.
   *
   * Since: 0.13.2
   */
  g_object_class_install_property (object_class, PROP_STORAGE_PROVIDER,
      g_param_spec_string ("storage-provider",
        "StorageProvider",
        "The storage provider for this account",
        NULL,
        G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:storage-identifier:
   *
   * The storage identifier for this account.
   *
   * A provider-specific variant type used to identify this account with the
   * provider. This value will be %NULL if #TpAccount:storage-provider is
   * an empty string.
   *
   * This property cannot change once an Account has been created.
   *
   * This is not guaranteed to have been retrieved until the
   * %TP_ACCOUNT_FEATURE_STORAGE feature has been prepared; until then,
   * the value is %NULL.
   *
   * Since: 0.13.2
   */
  g_object_class_install_property (object_class, PROP_STORAGE_IDENTIFIER,
      g_param_spec_boxed ("storage-identifier",
        "StorageIdentifier",
        "The storage identifier for this account",
        G_TYPE_VALUE,
        G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:storage-identifier-variant:
   *
   * Provider-specific information used to identify this
   * account. Use g_variant_get_type() to check that the type
   * is what you expect. For instance, if you use a
   * #TpAccount:storage-provider with numeric identifiers for accounts,
   * this variant might have type %G_VARIANT_TYPE_UINT32;
   * if the storage provider has string-based identifiers, it should
   * have type %G_VARIANT_TYPE_STRING.
   *
   * This property cannot change once an Account has been created.
   *
   * This is not guaranteed to have been retrieved until the
   * %TP_ACCOUNT_FEATURE_STORAGE feature has been prepared; until then,
   * the value is %NULL.
   *
   * Since: 0.13.2
   */
  g_object_class_install_property (object_class,
      PROP_STORAGE_IDENTIFIER_VARIANT,
      g_param_spec_variant ("storage-identifier-variant",
        "StorageIdentifier as variant",
        "The storage identifier for this account",
        G_VARIANT_TYPE_ANY,
        NULL,
        G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:storage-restrictions:
   *
   * The storage restrictions for this account.
   *
   * A bitfield of #TpStorageRestrictionFlags that give the limitations of
   * this account imposed by the storage provider. This value will be 0
   * if #TpAccount:storage-provider is an empty string.
   *
   * This property cannot change once an Account has been created.
   *
   * This is not guaranteed to have been retrieved until the
   * %TP_ACCOUNT_FEATURE_STORAGE feature has been prepared; until then,
   * the value is 0.
   *
   * Since: 0.13.2
   */
  g_object_class_install_property (object_class, PROP_STORAGE_RESTRICTIONS,
      g_param_spec_uint ("storage-restrictions",
        "StorageRestrictions",
        "The storage restrictions for this account",
        0, G_MAXUINT, 0,
        G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:supersedes:
   *
   * The object paths of previously-active accounts superseded by this one.
   * For instance, this can be used in a logger to read old logs for an
   * account that has been migrated from one connection manager to another.
   *
   * This is not guaranteed to have been retrieved until the
   * %TP_ACCOUNT_FEATURE_CORE feature has been prepared; until then,
   * the value is NULL.
   *
   * Since: 0.17.5
   */
  g_object_class_install_property (object_class, PROP_SUPERSEDES,
      g_param_spec_boxed ("supersedes",
        "Supersedes",
        "Accounts superseded by this one",
        G_TYPE_STRV,
        G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount:uri-schemes:
   *
   * If the %TP_ACCOUNT_FEATURE_ADDRESSING feature has been prepared
   * successfully, a list of additional URI schemes for which this
   * account should be used if possible. Otherwise %NULL.
   *
   * For instance, a SIP or Skype account might have "tel" in this list if the
   * user would like to use that account to call phone numbers.
   *
   * This list should not contain the primary URI scheme(s) for the account's
   * protocol (for instance, "xmpp" for XMPP, or "sip" or "sips" for SIP),
   * since it should be assumed to be useful for those schemes in any case.
   *
   * The notify::uri-schemes signal cannot be relied on if the Account Manager
   * is Mission Control version 5.14.0 or older.
   *
   * Since: 0.21.0
   */
  g_object_class_install_property (object_class, PROP_URI_SCHEMES,
      g_param_spec_boxed ("uri-schemes",
        "URISchemes",
        "URISchemes",
        G_TYPE_STRV,
        G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccount::status-changed:
   * @account: the #TpAccount
   * @old_status: old #TpAccount:connection-status
   * @new_status: new #TpAccount:connection-status
   * @reason: the #TpAccount:connection-status-reason
   * @dbus_error_name: (allow-none): the #TpAccount:connection-error
   * @details: (element-type utf8 GObject.Value): the
   *  #TpAccount:connection-error-details
   *
   * Emitted when the connection status on the account changes.
   *
   * The @dbus_error_name and @details parameters were present, but
   * non-functional (always %NULL), in older versions. They have been
   * available with their current behaviour since version 0.11.7.
   *
   * Since: 0.9.0
   */
  signals[STATUS_CHANGED] = g_signal_new ("status-changed",
      G_TYPE_FROM_CLASS (object_class),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE, 5, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING,
      G_TYPE_HASH_TABLE);

  /**
   * TpAccount::presence-changed:
   * @account: the #TpAccount
   * @presence: the new presence
   * @status: the new presence status
   * @status_message: the new presence status message
   *
   * Emitted when the presence of the account changes.
   *
   * Since: 0.9.0
   */
  signals[PRESENCE_CHANGED] = g_signal_new ("presence-changed",
      G_TYPE_FROM_CLASS (object_class),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE, 3, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING);

  /**
   * TpAccount::avatar-changed:
   * @self: a #TpAccount
   *
   * Emitted when the avatar changes. Call tp_account_get_avatar_async()
   * to get the new avatar data.
   *
   * Since: 0.23.0
   */
  signals[AVATAR_CHANGED] = g_signal_new ("avatar-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      0);

  proxy_class->interface = TP_IFACE_QUARK_ACCOUNT;
  proxy_class->list_features = _tp_account_list_features;
  tp_account_init_known_interfaces ();
}

/**
 * tp_account_init_known_interfaces:
 *
 * Ensure that the known interfaces for TpAccount have been set up.
 * This is done automatically when necessary, but for correct
 * overriding of library interfaces by local extensions, you should
 * call this function before calling
 * tp_proxy_or_subclass_hook_on_interface_add() with first argument
 * %TP_TYPE_ACCOUNT.
 *
 * Since: 0.7.32
 */
void
tp_account_init_known_interfaces (void)
{
  static gsize once = 0;

  if (g_once_init_enter (&once))
    {
      GType tp_type = TP_TYPE_ACCOUNT;

      tp_proxy_init_known_interfaces ();
      tp_proxy_or_subclass_hook_on_interface_add (tp_type,
          tp_cli_account_add_signals);
      tp_proxy_subclass_add_error_mapping (tp_type,
          TP_ERROR_PREFIX, TP_ERROR, TP_TYPE_ERROR);

      g_once_init_leave (&once, 1);
    }
}

/**
 * tp_account_new:
 * @bus_daemon: Proxy for the D-Bus daemon
 * @object_path: The non-NULL object path of this account
 * @error: Used to raise an error if @object_path is not valid
 *
 * Convenience function to create a new account proxy. The returned #TpAccount
 * is not guaranteed to be ready at the point of return.
 *
 * Returns: a new reference to an account proxy, or %NULL if @object_path is
 *    not valid
 * Deprecated: Use tp_simple_client_factory_ensure_account() instead.
 */
TpAccount *
tp_account_new (TpDBusDaemon *bus_daemon,
    const gchar *object_path,
    GError **error)
{
  return _tp_account_new_with_factory (NULL, bus_daemon, object_path, error);
}

TpAccount *
_tp_account_new_with_factory (TpSimpleClientFactory *factory,
    TpDBusDaemon *bus_daemon,
    const gchar *object_path,
    GError **error)
{
  TpAccount *self;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (bus_daemon), NULL);
  g_return_val_if_fail (object_path != NULL, NULL);
  g_return_val_if_fail (error == NULL || *error == NULL, NULL);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  if (!tp_account_parse_object_path (object_path, NULL, NULL, NULL, error))
    return NULL;
  G_GNUC_END_IGNORE_DEPRECATIONS

  self = TP_ACCOUNT (g_object_new (TP_TYPE_ACCOUNT,
          "dbus-daemon", bus_daemon,
          "dbus-connection", ((TpProxy *) bus_daemon)->dbus_connection,
          "bus-name", TP_ACCOUNT_MANAGER_BUS_NAME,
          "object-path", object_path,
          "factory", factory,
          NULL));

  return self;
}

static gchar *
unescape_protocol (gchar *protocol)
{
  if (strstr (protocol, "_2d") != NULL)
    {
      /* Work around MC5 bug where it escapes with tp_escape_as_identifier
       * rather than doing it properly. MC5 saves the object path in your
       * config, so if you've ever used a buggy MC5, the path will be wrong
       * forever.
       */
      gchar **chunks = g_strsplit (protocol, "_2d", 0);
      gchar *new = g_strjoinv ("-", chunks);

      g_strfreev (chunks);
      g_free (protocol);
      protocol = new;
    }

  g_strdelimit (protocol, "_", '-');

  return protocol;
}

/**
 * tp_account_get_connection:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: (transfer none): the same as the #TpAccount:connection property
 *
 * Since: 0.9.0
 **/
TpConnection *
tp_account_get_connection (TpAccount *account)
{
  TpAccountPrivate *priv;

  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  priv = account->priv;

  /* If we want to expose only prepared connection */
  if (connection_is_internal (account))
    return NULL;

  return priv->connection;
}

/**
 * tp_account_ensure_connection:
 * @account: a #TpAccount
 * @path: the path to connection object for #TpAccount
 *
 * Set the connection of the account by specifying the connection object path.
 * This function does not return a new ref and it is not guaranteed that the
 * returned #TpConnection object is ready.
 *
 * The use-case for this function is in a HandleChannels callback and you
 * already know the object path for the connection, so you can let @account
 * create its #TpConnection and return it for use.
 *
 * Returns: (transfer none): the connection of the account, or %NULL if either
 *  the object path @path is invalid or it is the null-value "/"
 *
 * Since: 0.9.0
 * Deprecated: New code should use tp_simple_client_factory_ensure_connection()
 *  instead.
 **/
TpConnection *
tp_account_ensure_connection (TpAccount *account,
    const gchar *path)
{
  TpAccountPrivate *priv;

  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  priv = account->priv;

  /* double-check that the object path is valid */
  if (!tp_dbus_check_valid_object_path (path, NULL))
    return NULL;

  /* Should be a full object path, not the special "/" value */
  if (!tp_strdiff (path, "/"))
    return NULL;

  _tp_account_set_connection (account, path);

  return priv->connection;
}

/**
 * tp_account_get_path_suffix:
 * @account: a #TpAccount
 *
 * Returns the portion of @account's object path after the standard
 * #TP_ACCOUNT_OBJECT_PATH_BASE prefix, of the form "cm/protocol/acct". This
 * string uniquely identifies the account.
 *
 * This function is only intended to be used when printing debug messages or in
 * tools for developer. For a string suitable for displaying to the user, see
 * tp_account_get_display_name(). To retrieve the connection manager and
 * protocol name parts of the object path, see
 * tp_account_get_connection_manager() and tp_account_get_protocol(). For
 * persistent identification of the account, use tp_proxy_get_object_path().
 *
 * Returns: a suffix of @account's object path, for debugging purposes.
 * Since: 0.13.9
 */
const gchar *
tp_account_get_path_suffix (TpAccount *account)
{
  const gchar *path;

  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  path = tp_proxy_get_object_path (account);
  g_return_val_if_fail (g_str_has_prefix (path, TP_ACCOUNT_OBJECT_PATH_BASE),
      path);

  return path + strlen (TP_ACCOUNT_OBJECT_PATH_BASE);
}

/**
 * tp_account_get_display_name:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:display-name property
 *
 * Since: 0.9.0
 **/
const gchar *
tp_account_get_display_name (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  return account->priv->display_name;
}

/**
 * tp_account_is_valid:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:valid property
 *
 * Since: 0.9.0
 */
gboolean
tp_account_is_valid (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), FALSE);

  return account->priv->valid;
}

/**
 * tp_account_get_connection_manager:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:connection-manager property
 *
 * Since: 0.9.0
 * Deprecated: Use tp_account_get_cm_name() instead.
 */
const gchar *
tp_account_get_connection_manager (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  return account->priv->cm_name;
}

/**
 * tp_account_get_protocol:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:protocol property
 *
 * Since: 0.9.0
 * Deprecated: Use tp_account_get_cm_name() instead.
 */
const gchar *
tp_account_get_protocol (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  return account->priv->proto_name;
}

/**
 * tp_account_get_cm_name:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:cm-name property
 *
 * Since: 0.19.3
 */
const gchar *
tp_account_get_cm_name (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  return account->priv->cm_name;
}

/**
 * tp_account_get_protocol_name:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:protocol-name property
 *
 * Since: 0.19.3
 */
const gchar *
tp_account_get_protocol_name (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  return account->priv->proto_name;
}

/**
 * tp_account_get_service:
 * @self: an account
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:service property
 *
 * Since: 0.11.9
 */
const gchar *
tp_account_get_service (TpAccount *self)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), NULL);

  return self->priv->service;
}

/**
 * tp_account_get_icon_name:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:icon-name property
 *
 * Since: 0.9.0
 */
const gchar *
tp_account_get_icon_name (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  return account->priv->icon_name;
}

/**
 * tp_account_get_parameters:
 * @account: a #TpAccount
 *
 * Returns the parameters of the account, in a hash table where each string
 * is the parameter name (account, password, require-encryption etc.), and
 * each value is a #GValue. Using the tp_asv_get family of functions
 * (tp_asv_get_uint32(), tp_asv_get_string() etc.) to access the parameters is
 * recommended.
 *
 * The allowed parameters depend on the connection manager, and can be found
 * via tp_connection_manager_get_protocol() and
 * tp_connection_manager_protocol_get_param(). Well-known parameters are
 * listed
 * <ulink url="http://telepathy.freedesktop.org/spec/org.freedesktop.Telepathy.ConnectionManager.html#org.freedesktop.Telepathy.ConnectionManager.RequestConnection">in
 * the Telepathy D-Bus Interface Specification</ulink>.
 *
 * Returns: (transfer none) (element-type utf8 GObject.Value): the hash table of
 *  parameters on @account
 *
 * Since: 0.9.0
 */
const GHashTable *
tp_account_get_parameters (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  return account->priv->parameters;
}

/**
 * tp_account_dup_parameters_vardict:
 * @account: a #TpAccount
 *
 * Returns the parameters of the account, in a variant of type
 * %G_VARIANT_TYPE_VARDICT where the keys
 * are parameter names (account, password, require-encryption etc.).
 * Use g_variant_lookup() or g_variant_lookup_value() for convenient
 * access to the values.
 *
 * The allowed parameters depend on the connection manager, and can be found
 * via tp_connection_manager_get_protocol() and
 * tp_connection_manager_protocol_get_param(). Well-known parameters are
 * listed
 * <ulink url="http://telepathy.freedesktop.org/spec/org.freedesktop.Telepathy.ConnectionManager.html#org.freedesktop.Telepathy.ConnectionManager.RequestConnection">in
 * the Telepathy D-Bus Interface Specification</ulink>.
 *
 * Returns: (transfer full): the dictionary of
 *  parameters on @account, of type %G_VARIANT_TYPE_VARDICT
 *
 * Since: 0.17.6
 */
GVariant *
tp_account_dup_parameters_vardict (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  return _tp_asv_to_vardict (account->priv->parameters);
}

/**
 * tp_account_is_enabled:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:enabled property
 *
 * Since: 0.9.0
 */
gboolean
tp_account_is_enabled (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), FALSE);

  return account->priv->enabled;
}

static void
_tp_account_property_set_cb (TpProxy *proxy,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Failed to set property: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
    }

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/**
 * tp_account_set_enabled_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async set of the Enabled property.
 *
 * Returns: %TRUE if the set was successful, otherwise %FALSE
 *
 * Since: 0.9.0
 */
gboolean
tp_account_set_enabled_finish (TpAccount *account,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (account, tp_account_set_enabled_finish);
}

/**
 * tp_account_set_enabled_async:
 * @account: a #TpAccount
 * @enabled: the new enabled value of @account
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous set of the Enabled property of @account. When the
 * operation is finished, @callback will be called. You can then call
 * tp_account_set_enabled_finish() to get the result of the operation.
 *
 * Since: 0.9.0
 */
void
tp_account_set_enabled_async (TpAccount *account,
    gboolean enabled,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GValue value = {0, };
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_ACCOUNT (account));

  result = g_simple_async_result_new (G_OBJECT (account),
      callback, user_data, tp_account_set_enabled_finish);

  g_value_init (&value, G_TYPE_BOOLEAN);
  g_value_set_boolean (&value, enabled);

  tp_cli_dbus_properties_call_set (TP_PROXY (account),
      -1, TP_IFACE_ACCOUNT, "Enabled", &value,
      _tp_account_property_set_cb, result, NULL, G_OBJECT (account));

  g_value_reset (&value);
}

static void
_tp_account_void_cb (TpAccount *proxy,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    g_simple_async_result_set_from_error (result, error);

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/**
 * tp_account_reconnect_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to be filled
 *
 * Finishes an async reconnect of @account.
 *
 * Returns: %TRUE if the reconnect call was successful, otherwise %FALSE
 *
 * Since: 0.9.0
 */
gboolean
tp_account_reconnect_finish (TpAccount *account,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (account, tp_account_reconnect_finish);
}

/**
 * tp_account_reconnect_async:
 * @account: a #TpAccount
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous reconnect of @account. When the operation is
 * finished, @callback will be called. You can then call
 * tp_account_reconnect_finish() to get the result of the operation.
 *
 * Since: 0.9.0
 */
void
tp_account_reconnect_async (TpAccount *account,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_ACCOUNT (account));

  result = g_simple_async_result_new (G_OBJECT (account),
      callback, user_data, tp_account_reconnect_finish);

  tp_cli_account_call_reconnect (account, -1, _tp_account_void_cb,
      result, NULL, G_OBJECT (account));
}

/**
 * tp_account_set_automatic_presence_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an asynchronous request to change the automatic presence of
 * @account.
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE
 *
 * Since: 0.13.8
 */
gboolean
tp_account_set_automatic_presence_finish (TpAccount *account,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (account, tp_account_set_automatic_presence_async)
}

/**
 * tp_account_set_automatic_presence_async:
 * @account: a #TpAccount
 * @type: the requested presence
 * @status: a status message to set, or %NULL
 * @message: a message for the change, or %NULL
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous change of @account's automatic presence. When the
 * operation is finished, @callback will be called. You can then call
 * tp_account_set_automatic_presence_finish() to get the result of the
 * operation.
 *
 * Since: 0.13.8
 */
void
tp_account_set_automatic_presence_async (TpAccount *account,
    TpConnectionPresenceType type,
    const gchar *status,
    const gchar *message,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GValue value = {0, };
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_ACCOUNT (account));

  result = g_simple_async_result_new (G_OBJECT (account),
      callback, user_data, tp_account_set_automatic_presence_async);

  g_value_init (&value, TP_STRUCT_TYPE_SIMPLE_PRESENCE);
  g_value_take_boxed (&value, tp_value_array_build (3,
        G_TYPE_UINT, type,
        G_TYPE_STRING, status,
        G_TYPE_STRING, message,
        G_TYPE_INVALID));

  tp_cli_dbus_properties_call_set (TP_PROXY (account), -1,
      TP_IFACE_ACCOUNT, "AutomaticPresence", &value,
      _tp_account_property_set_cb, result, NULL, G_OBJECT (account));

  g_value_unset (&value);
}

/**
 * tp_account_request_presence_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async presence change request on @account.
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE
 *
 * Since: 0.9.0
 */
gboolean
tp_account_request_presence_finish (TpAccount *account,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (account, tp_account_request_presence_finish);
}

/**
 * tp_account_request_presence_async:
 * @account: a #TpAccount
 * @type: the requested presence
 * @status: a status message to set, or %NULL
 * @message: a message for the change, or %NULL
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous change of presence on @account. When the
 * operation is finished, @callback will be called. You can then call
 * tp_account_request_presence_finish() to get the result of the operation.
 *
 * Since: 0.9.0
 */
void
tp_account_request_presence_async (TpAccount *account,
    TpConnectionPresenceType type,
    const gchar *status,
    const gchar *message,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GValue value = {0, };
  GValueArray *arr;
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_ACCOUNT (account));

  result = g_simple_async_result_new (G_OBJECT (account),
      callback, user_data, tp_account_request_presence_finish);

  g_value_init (&value, TP_STRUCT_TYPE_SIMPLE_PRESENCE);
  g_value_take_boxed (&value, dbus_g_type_specialized_construct (
          TP_STRUCT_TYPE_SIMPLE_PRESENCE));
  arr = (GValueArray *) g_value_get_boxed (&value);

  g_value_set_uint (arr->values, type);
  g_value_set_static_string (arr->values + 1, status);
  g_value_set_static_string (arr->values + 2, message);

  tp_cli_dbus_properties_call_set (TP_PROXY (account), -1,
      TP_IFACE_ACCOUNT, "RequestedPresence", &value,
      _tp_account_property_set_cb, result, NULL, G_OBJECT (account));

  g_value_unset (&value);
}

static void
_tp_account_updated_cb (TpAccount *proxy,
    const gchar **reconnect_required,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = G_SIMPLE_ASYNC_RESULT (user_data);

  if (error != NULL)
    g_simple_async_result_set_from_error (result, error);
  else
    g_simple_async_result_set_op_res_gpointer (result,
        g_strdupv ((GStrv) reconnect_required), (GDestroyNotify) g_strfreev);

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (G_OBJECT (result));
}

/**
 * tp_account_update_parameters_async:
 * @account: a #TpAccount
 * @parameters: (element-type utf8 GObject.Value) (transfer none): new
 *  parameters to set on @account
 * @unset_parameters: list of parameters to unset on @account
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous update of parameters of @account. When the
 * operation is finished, @callback will be called. You can then call
 * tp_account_update_parameters_finish() to get the result of the operation.
 *
 * Since: 0.9.0
 */
void
tp_account_update_parameters_async (TpAccount *account,
    GHashTable *parameters,
    const gchar **unset_parameters,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_ACCOUNT (account));

  result = g_simple_async_result_new (G_OBJECT (account),
      callback, user_data, tp_account_update_parameters_finish);

  tp_cli_account_call_update_parameters (account, -1, parameters,
      unset_parameters, _tp_account_updated_cb, result,
      NULL, G_OBJECT (account));
}

/**
 * tp_account_update_parameters_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @reconnect_required: (out) (array zero-terminated=1) (transfer full): a #GStrv to
 *  fill with properties that need a reconnect to take effect
 * @error: a #GError to fill
 *
 * Finishes an async update of the parameters on @account.
 *
 * Returns: %TRUE if the request succeeded, otherwise %FALSE
 *
 * Since: 0.9.0
 */
gboolean
tp_account_update_parameters_finish (TpAccount *account,
    GAsyncResult *result,
    gchar ***reconnect_required,
    GError **error)
{
  _tp_implement_finish_copy_pointer (account,
      tp_account_update_parameters_finish, g_strdupv,
      reconnect_required);
}

/**
 * tp_account_update_parameters_vardict_async:
 * @account: a #TpAccount
 * @parameters: (transfer none): a variant of type %G_VARIANT_TYPE_VARDICT
 *  containing new parameters to set on @account
 * @unset_parameters: (array zero-terminated=1): list of parameters to unset on @account
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous update of parameters of @account. When the
 * operation is finished, @callback will be called. You can then call
 * tp_account_update_parameters_finish() to get the result of the operation.
 *
 * If @parameters is a floating reference (see g_variant_ref_sink()),
 * ownership of @parameters is taken by this function. This means
 * you can pass the result of g_variant_new() or g_variant_new_parsed()
 * directly to this function without additional reference-count management.
 *
 * Since: 0.17.6
 */
void
tp_account_update_parameters_vardict_async (TpAccount *account,
    GVariant *parameters,
    const gchar **unset_parameters,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GHashTable *hash;

  hash = _tp_asv_from_vardict (parameters);

  g_variant_ref_sink (parameters);

  tp_account_update_parameters_async (account, hash,
      unset_parameters, callback, user_data);
  g_variant_unref (parameters);
  g_hash_table_unref (hash);
}

/**
 * tp_account_update_parameters_vardict_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @reconnect_required: (out) (type GStrv) (transfer full): a #GStrv to
 *  fill with properties that need a reconnect to take effect
 * @error: a #GError to fill
 *
 * Finishes an async update of the parameters on @account.
 *
 * Returns: %TRUE if the request succeeded, otherwise %FALSE
 *
 * Since: 0.17.6
 */
gboolean
tp_account_update_parameters_vardict_finish (TpAccount *account,
    GAsyncResult *result,
    gchar ***reconnect_required,
    GError **error)
{
  /* share an implementation with the non-vardict version */
  return tp_account_update_parameters_finish (account, result,
      reconnect_required, error);
}

/**
 * tp_account_set_display_name_async:
 * @account: a #TpAccount
 * @display_name: a new display name, or %NULL to unset the display name
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous set of the DisplayName property of @account. When
 * the operation is finished, @callback will be called. You can then call
 * tp_account_set_display_name_finish() to get the result of the operation.
 *
 * Since: 0.9.0
 */
void
tp_account_set_display_name_async (TpAccount *account,
    const char *display_name,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  GValue value = {0, };
  const gchar *display_name_set;

  g_return_if_fail (TP_IS_ACCOUNT (account));

  if (display_name == NULL)
    display_name_set = "";
  else
    display_name_set = display_name;

  result = g_simple_async_result_new (G_OBJECT (account), callback,
      user_data, tp_account_set_display_name_finish);

  g_value_init (&value, G_TYPE_STRING);
  g_value_set_string (&value, display_name_set);

  tp_cli_dbus_properties_call_set (account, -1, TP_IFACE_ACCOUNT,
      "DisplayName", &value, _tp_account_property_set_cb, result, NULL,
      G_OBJECT (account));

  g_value_unset (&value);
}

/**
 * tp_account_set_display_name_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async set of the DisplayName property.
 *
 * Returns: %TRUE if the call was successful, otherwise %FALSE
 *
 * Since: 0.9.0
 */
gboolean
tp_account_set_display_name_finish (TpAccount *account,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (account, tp_account_set_display_name_finish);
}

/**
 * tp_account_set_service_async:
 * @self: a #TpAccount
 * @service: a new service name, or %NULL or the empty string to unset the
 *  service name (which will result in the #TpAccount:service property
 *  becoming the same as #TpAccount:protocol)
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous set of the Service property on @self. When
 * the operation is finished, @callback will be called. You can then call
 * tp_account_set_service_finish() to get the result of the operation.
 *
 * Since: 0.11.9
 */
void
tp_account_set_service_async (TpAccount *self,
    const char *service,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  GValue value = {0, };

  g_return_if_fail (TP_IS_ACCOUNT (self));

  if (service == NULL)
    service = "";

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_account_set_service_async);

  g_value_init (&value, G_TYPE_STRING);
  g_value_set_string (&value, service);

  tp_cli_dbus_properties_call_set (self, -1, TP_IFACE_ACCOUNT,
      "Service", &value, _tp_account_property_set_cb, result, NULL,
      G_OBJECT (self));

  g_value_unset (&value);
}

/**
 * tp_account_set_service_finish:
 * @self: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async set of the Service parameter.
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE
 *
 * Since: 0.11.9
 */
gboolean
tp_account_set_service_finish (TpAccount *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_account_set_service_async);
}

/**
 * tp_account_set_icon_name_async:
 * @account: a #TpAccount
 * @icon_name: a new icon name, or %NULL to unset the icon name
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous set of the Icon property of @account. When
 * the operation is finished, @callback will be called. You can then call
 * tp_account_set_icon_name_finish() to get the result of the operation.
 *
 * Since: 0.9.0
 */
void
tp_account_set_icon_name_async (TpAccount *account,
    const char *icon_name,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  GValue value = {0, };
  const char *icon_name_set;

  g_return_if_fail (TP_IS_ACCOUNT (account));

  if (icon_name == NULL)
    /* settings an empty icon name is allowed */
    icon_name_set = "";
  else
    icon_name_set = icon_name;

  result = g_simple_async_result_new (G_OBJECT (account), callback,
      user_data, tp_account_set_icon_name_finish);

  g_value_init (&value, G_TYPE_STRING);
  g_value_set_string (&value, icon_name_set);

  tp_cli_dbus_properties_call_set (account, -1, TP_IFACE_ACCOUNT,
      "Icon", &value, _tp_account_property_set_cb, result, NULL,
      G_OBJECT (account));

  g_value_unset (&value);
}

/**
 * tp_account_set_icon_name_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async set of the Icon parameter.
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE
 *
 * Since: 0.9.0
 */
gboolean
tp_account_set_icon_name_finish (TpAccount *account,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (account, tp_account_set_icon_name_finish);
}

/**
 * tp_account_remove_async:
 * @account: a #TpAccount
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous removal of @account. When the operation is
 * finished, @callback will be called. You can then call
 * tp_account_remove_finish() to get the result of the operation.
 *
 * Since: 0.9.0
 */
void
tp_account_remove_async (TpAccount *account,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_ACCOUNT (account));

  result = g_simple_async_result_new (G_OBJECT (account),
      callback, user_data, tp_account_remove_finish);

  tp_cli_account_call_remove (account, -1, _tp_account_void_cb, result, NULL,
      G_OBJECT (account));
}

/**
 * tp_account_remove_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async removal of @account.
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE
 *
 * Since: 0.9.0
 */
gboolean
tp_account_remove_finish (TpAccount *account,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (account, tp_account_remove_finish);
}

/**
 * tp_account_get_changing_presence:
 * @self: an account
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:changing-presence property
 *
 * Since: 0.11.6
 */
gboolean
tp_account_get_changing_presence (TpAccount *self)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), FALSE);

  return self->priv->changing_presence;
}

/**
 * tp_account_get_connect_automatically:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:connect-automatically property
 *
 * Since: 0.9.0
 */
gboolean
tp_account_get_connect_automatically (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), FALSE);

  return account->priv->connect_automatically;
}

/**
 * tp_account_set_connect_automatically_async:
 * @account: a #TpAccount
 * @connect_automatically: new value for the parameter
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous set of the ConnectAutomatically property of
 * @account. When the operation is finished, @callback will be called. You can
 * then call tp_account_set_display_name_finish() to get the result of the
 * operation.
 *
 * Since: 0.9.0
 */
void
tp_account_set_connect_automatically_async (TpAccount *account,
    gboolean connect_automatically,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  GValue value = {0, };

  g_return_if_fail (TP_IS_ACCOUNT (account));

  result = g_simple_async_result_new (G_OBJECT (account), callback,
      user_data, tp_account_set_connect_automatically_finish);

  g_value_init (&value, G_TYPE_BOOLEAN);
  g_value_set_boolean (&value, connect_automatically);

  tp_cli_dbus_properties_call_set (account, -1, TP_IFACE_ACCOUNT,
      "ConnectAutomatically", &value, _tp_account_property_set_cb, result,
      NULL, G_OBJECT (account));

  g_value_unset (&value);
}

/**
 * tp_account_set_connect_automatically_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async set of the ConnectAutomatically property.
 *
 * Returns: %TRUE if the call was successful, otherwise %FALSE
 *
 * Since: 0.9.0
 */
gboolean
tp_account_set_connect_automatically_finish (TpAccount *account,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (account,
      tp_account_set_connect_automatically_finish);
}

/**
 * tp_account_get_has_been_online:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:has-been-online property
 *
 * Since: 0.9.0
 */
gboolean
tp_account_get_has_been_online (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), FALSE);

  return account->priv->has_been_online;
}

/**
 * tp_account_get_connection_status:
 * @account: a #TpAccount
 * @reason: (out): a #TpConnectionStatusReason to fill, or %NULL
 *
 * Gets the connection status and reason from @account. The two values
 * are the same as the #TpAccount:connection-status and
 * #TpAccount:connection-status-reason properties.
 *
 * Returns: the same as the #TpAccount:connection-status property
 *
 * Since: 0.9.0
 */
TpConnectionStatus
tp_account_get_connection_status (TpAccount *account,
    TpConnectionStatusReason *reason)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account),
      TP_CONNECTION_STATUS_DISCONNECTED); /* there's no _UNSET */

  if (reason != NULL)
    *reason = account->priv->reason;

  return account->priv->connection_status;
}

/**
 * tp_account_get_current_presence:
 * @account: a #TpAccount
 * @status: (out) (transfer full): return location for the current status
 * @status_message: (out) (transfer full): return location for the current
 *  status message
 *
 * Gets the current presence, status and status message of @account. These
 * values are the same as the #TpAccount:current-presence-type,
 * #TpAccount:current-status and #TpAccount:current-status-message properties.
 *
 * Returns: the same as the #TpAccount:current-presence-type property
 *
 * Since: 0.9.0
 */
TpConnectionPresenceType
tp_account_get_current_presence (TpAccount *account,
    gchar **status,
    gchar **status_message)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account),
      TP_CONNECTION_PRESENCE_TYPE_UNSET);

  if (status != NULL)
    *status = g_strdup (account->priv->cur_status);

  if (status_message != NULL)
    *status_message = g_strdup (account->priv->cur_message);

  return account->priv->cur_presence;
}

/**
 * tp_account_get_requested_presence:
 * @account: a #TpAccount
 * @status: (out) (transfer none): return location for the requested status
 * @status_message: (out) (transfer full): return location for the requested
 *  status message
 *
 * Gets the requested presence, status and status message of @account. These
 * values are the same as the #TpAccount:requested-presence-type,
 * #TpAccount:requested-status and #TpAccount:requested-status-message
 * properties.
 *
 * Returns: the same as the #TpAccount:requested-presence-type property
 *
 * Since: 0.9.0
 */
TpConnectionPresenceType
tp_account_get_requested_presence (TpAccount *account,
    gchar **status,
    gchar **status_message)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account),
      TP_CONNECTION_PRESENCE_TYPE_UNSET);

  if (status != NULL)
    *status = g_strdup (account->priv->requested_status);

  if (status_message != NULL)
    *status_message = g_strdup (account->priv->requested_message);

  return account->priv->requested_presence;
}

/**
 * tp_account_get_nickname:
 * @account: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:nickname property
 *
 * Since: 0.9.0
 */
const gchar *
tp_account_get_nickname (TpAccount *account)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);

  return account->priv->nickname;
}

/**
 * tp_account_set_nickname_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async nickname change request on @account.
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE
 *
 * Since: 0.9.0
 */
gboolean
tp_account_set_nickname_finish (TpAccount *account,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (account, tp_account_set_nickname_finish);
}

/**
 * tp_account_set_nickname_async:
 * @account: a #TpAccount
 * @nickname: a new nickname to set
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous change of the Nickname parameter on @account. When
 * the operation is finished, @callback will be called. You can then call
 * tp_account_set_nickname_finish() to get the result of the operation.
 *
 * Since: 0.9.0
 */
void
tp_account_set_nickname_async (TpAccount *account,
    const gchar *nickname,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GValue value = {0, };
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_ACCOUNT (account));
  g_return_if_fail (nickname != NULL);

  result = g_simple_async_result_new (G_OBJECT (account),
      callback, user_data, tp_account_set_nickname_finish);

  if (nickname == NULL)
    {
      g_simple_async_report_error_in_idle (G_OBJECT (account),
          callback, user_data, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
          "Can't set an empty nickname");
      return;
    }

  g_value_init (&value, G_TYPE_STRING);
  g_value_set_string (&value, nickname);

  tp_cli_dbus_properties_call_set (TP_PROXY (account), -1,
      TP_IFACE_ACCOUNT, "Nickname", &value,
      _tp_account_property_set_cb, result, NULL, G_OBJECT (account));

  g_value_unset (&value);
}

/**
 * tp_account_get_supersedes:
 * @self: a #TpAccount
 *
 * Return the same thing as the #TpAccount:supersedes property, in a way
 * that may be more convenient for C code.
 *
 * The returned pointers are not guaranteed to remain valid after the
 * main loop has been re-entered.
 *
 * Returns: (transfer none): the same as the #TpAccount:supersedes property
 *
 * Since: 0.17.5
 */
const gchar * const *
tp_account_get_supersedes (TpAccount *self)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), NULL);

  return (const gchar * const *) self->priv->supersedes;
}

static void
_tp_account_got_avatar_cb (TpProxy *proxy,
    const GValue *out_Value,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = G_SIMPLE_ASYNC_RESULT (user_data);

  if (error != NULL)
    {
      DEBUG ("Failed to get avatar: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
    }
  else if (!G_VALUE_HOLDS (out_Value, TP_STRUCT_TYPE_AVATAR))
    {
      DEBUG ("Avatar had wrong type: %s", G_VALUE_TYPE_NAME (out_Value));
      g_simple_async_result_set_error (result, TP_ERROR, TP_ERROR_CONFUSED,
          "Incorrect type for Avatar property");
    }
  else
    {
      GValueArray *avatar;
      GArray *res;
      const GArray *tmp;
      const gchar *mime_type;

      avatar = g_value_get_boxed (out_Value);
      tp_value_array_unpack (avatar, 2,
          &tmp,
          &mime_type);

      res = g_array_sized_new (FALSE, FALSE, 1, tmp->len);
      g_array_append_vals (res, tmp->data, tmp->len);
      g_simple_async_result_set_op_res_gpointer (result, res,
          (GDestroyNotify) g_array_unref);
    }

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/**
 * tp_account_get_avatar_async:
 * @account: a #TpAccount
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous get of @account's avatar. When
 * the operation is finished, @callback will be called. You can then call
 * tp_account_get_avatar_finish() to get the result of the operation.
 *
 * Since: 0.9.0
 */
void
tp_account_get_avatar_async (TpAccount *account,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_ACCOUNT (account));

  result = g_simple_async_result_new (G_OBJECT (account),
      callback, user_data, tp_account_get_avatar_finish);

  tp_cli_dbus_properties_call_get (account, -1,
      TP_IFACE_ACCOUNT_INTERFACE_AVATAR, "Avatar", _tp_account_got_avatar_cb,
      result, NULL, G_OBJECT (account));
}

/**
 * tp_account_get_avatar_finish:
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async get operation of @account's avatar.
 *
 * Beware that the returned value is only valid until @result is freed.
 * Copy it with g_array_ref() if you need to keep it for longer.
 *
 * Returns: (element-type guchar) (transfer none): a #GArray of #guchar
 *  containing the bytes of the account's avatar, or %NULL on failure
 *
 * Since: 0.9.0
 */
const GArray *
tp_account_get_avatar_finish (TpAccount *account,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (account,
      tp_account_get_avatar_finish, /* do not copy */);
}

/**
 * tp_account_is_prepared: (skip)
 * @account: a #TpAccount
 * @feature: a feature which is required
 *
 * <!-- -->
 *
 * Returns: the same thing as tp_proxy_is_prepared()
 *
 * Since: 0.9.0
 * Deprecated: since 0.23.0, use tp_proxy_is_prepared() instead.
 */
gboolean
tp_account_is_prepared (TpAccount *account,
    GQuark feature)
{
  return tp_proxy_is_prepared (account, feature);
}

/**
 * tp_account_prepare_async: (skip)
 * @account: a #TpAccount
 * @features: a 0-terminated list of features, or %NULL
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous preparation of @account with the features specified
 * by @features. When the operation is finished, @callback will be called. You
 * can then call tp_account_prepare_finish() to get the result of the
 * operation.
 *
 * If @features is %NULL, then @callback will be called when the implied
 * %TP_ACCOUNT_FEATURE_CORE feature is ready.
 *
 * If %NULL is given to @callback, then no callback will be called when the
 * operation is finished. Instead, it will simply set @features on @manager.
 * Note that if @callback is %NULL, then @user_data must also be %NULL.
 *
 * Since 0.11.3, this is equivalent to calling the new function
 * tp_proxy_prepare_async() with the same arguments.
 *
 * Since: 0.9.0
 * Deprecated: since 0.15.6, use tp_proxy_prepare_async() instead.
 */
void
tp_account_prepare_async (TpAccount *account,
    const GQuark *features,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  tp_proxy_prepare_async (account, features, callback, user_data);
}

/**
 * tp_account_prepare_finish: (skip)
 * @account: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async preparation of the account @account.
 *
 * Returns: %TRUE if the preparation was successful, otherwise %FALSE
 *
 * Since: 0.9.0
 * Deprecated: since 0.15.6, use tp_proxy_prepare_finish() instead.
 */
gboolean
tp_account_prepare_finish (TpAccount *account,
    GAsyncResult *result,
    GError **error)
{
  return tp_proxy_prepare_finish (account, result, error);
}

static void
set_or_free (gchar **target,
    gchar *source)
{
  if (target != NULL)
    *target = source;
  else
    g_free (source);
}

/**
 * tp_account_parse_object_path:
 * @object_path: a Telepathy Account's object path
 * @cm: (out) (transfer full): location at which to store the account's
 *  connection manager's name
 * @protocol: (out) (transfer full): location at which to store the account's
 *  protocol
 * @account_id: (out) (transfer full): location at which to store the account's
 *  unique identifier
 * @error: location at which to return an error
 *
 * Validates and parses a Telepathy Account's object path, extracting the
 * connection manager's name, the protocol, and the account's unique identifier
 * from the path. This includes replacing underscores with hyphens in the
 * protocol name, as defined in the Account specification.
 *
 * Any of the out parameters may be %NULL if not needed. If %TRUE is returned,
 * the caller is responsible for freeing the strings stored in any non-%NULL
 * out parameters, using g_free().
 *
 * Returns: %TRUE if @object_path was successfully parsed; %FALSE and sets
 *          @error otherwise.
 *
 * Since: 0.9.0
 * Deprecated: Use tp_account_get_protocol() and
 *  tp_account_get_connection_manager() instead.
 */
gboolean
tp_account_parse_object_path (const gchar *object_path,
    gchar **cm,
    gchar **protocol,
    gchar **account_id,
    GError **error)
{
  const gchar *suffix;
  gchar **segments;

  if (!tp_dbus_check_valid_object_path (object_path, error))
    return FALSE;

  if (!g_str_has_prefix (object_path, TP_ACCOUNT_OBJECT_PATH_BASE))
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Account path does not start with the right prefix: %s",
          object_path);
      return FALSE;
    }

  suffix = object_path + strlen (TP_ACCOUNT_OBJECT_PATH_BASE);

  segments = g_strsplit (suffix, "/", 0);

  if (g_strv_length (segments) != 3)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Account path '%s' is malformed: should have 3 trailing components, "
          "not %u", object_path, g_strv_length (segments));
      goto free_segments_and_fail;
    }

  if (!g_ascii_isalpha (segments[0][0]))
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Account path '%s' is malformed: CM name should start with a letter",
          object_path);
      goto free_segments_and_fail;
    }

  if (!g_ascii_isalpha (segments[1][0]))
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Account path '%s' is malformed: "
          "protocol name should start with a letter",
          object_path);
      goto free_segments_and_fail;
    }

  if (!g_ascii_isalpha (segments[2][0]) && segments[2][0] != '_')
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Account path '%s' is malformed: "
          "account ID should start with a letter or underscore",
          object_path);
      goto free_segments_and_fail;
    }

  set_or_free (cm, segments[0]);
  set_or_free (protocol, unescape_protocol (segments[1]));
  set_or_free (account_id, segments[2]);

  /* Not g_strfreev because we stole or freed the individual strings */
  g_free (segments);
  return TRUE;

free_segments_and_fail:
  g_strfreev (segments);
  return FALSE;
}

/**
 * _tp_account_refresh_properties:
 * @account: a #TpAccount
 *
 * Refreshes @account's hashtable of properties with what actually exists on
 * the account manager.
 *
 * Since: 0.9.0
 */
void
_tp_account_refresh_properties (TpAccount *account)
{
  g_return_if_fail (TP_IS_ACCOUNT (account));

  tp_cli_dbus_properties_call_get_all (account, -1, TP_IFACE_ACCOUNT,
      _tp_account_got_all_cb, NULL, NULL, G_OBJECT (account));
}

/**
 * tp_account_set_avatar_finish:
 * @self: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes an async avatar change request on @account.
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE
 *
 * Since: 0.11.1
 */
gboolean
tp_account_set_avatar_finish (TpAccount *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_account_set_avatar_async);
}

/**
 * tp_account_set_avatar_async:
 * @self: a #TpAccount
 * @avatar: (allow-none) (array length=len): a new avatar to set; can be %NULL
 *  only if @len equals 0
 * @len: the length of the new avatar
 * @mime_type: (allow-none): the MIME type of the new avatar; can be %NULL
 *  only if @len equals 0
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous change of the Avatar parameter on @self. When
 * the operation is finished, @callback will be called. You can then call
 * tp_account_set_avatar_finish() to get the result of the operation.
 *
 * If @len equals 0, the avatar is cleared.
 *
 * Since: 0.11.1
 */
void
tp_account_set_avatar_async (TpAccount *self,
    const guchar *avatar,
    gsize len,
    const gchar *mime_type,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GValue value = {0, };
  GSimpleAsyncResult *result;
  GValueArray *arr;
  GArray *tmp;

  g_return_if_fail (TP_IS_ACCOUNT (self));
  g_return_if_fail (avatar != NULL || len == 0);
  g_return_if_fail (mime_type != NULL || len == 0);

  result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data, tp_account_set_avatar_async);

  tmp = g_array_new (FALSE, FALSE, sizeof (guchar));

  if (len > 0)
    g_array_append_vals (tmp, avatar, len);

  arr = tp_value_array_build (2,
      TP_TYPE_UCHAR_ARRAY, tmp,
      G_TYPE_STRING, mime_type,
      G_TYPE_INVALID);

  g_value_init (&value, TP_STRUCT_TYPE_AVATAR);
  g_value_take_boxed (&value, arr);

  tp_cli_dbus_properties_call_set (self, -1,
      TP_IFACE_ACCOUNT_INTERFACE_AVATAR, "Avatar", &value,
      _tp_account_property_set_cb, result, NULL, NULL);

  g_value_unset (&value);
}

/**
 * tp_account_get_detailed_error: (skip)
 * @self: an account
 * @details: (out) (allow-none) (element-type utf8 GObject.Value) (transfer none):
 *  optionally used to return a map from string to #GValue, which must not be
 *  modified, destroyed or unreffed by the caller
 *
 * If the account's connection is not connected, return the D-Bus error name
 * with which it last disconnected or failed to connect (in particular, this
 * is %TP_ERROR_STR_CANCELLED if it was disconnected by a user request).
 * This is the same as #TpAccount:connection-error.
 *
 * If @details is not %NULL, it will be used to return additional details about
 * the error (the same as #TpAccount:connection-error-details).
 *
 * Otherwise, return %NULL, without altering @details.
 *
 * The returned string and @details may become invalid when the main loop is
 * re-entered or the account is destroyed.
 *
 * Returns: (transfer none) (allow-none): a D-Bus error name, or %NULL.
 *
 * Since: 0.11.7
 */
const gchar *
tp_account_get_detailed_error (TpAccount *self,
    const GHashTable **details)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), NULL);

  if (self->priv->connection_status == TP_CONNECTION_STATUS_CONNECTED)
    return NULL;

  if (details != NULL)
    *details = self->priv->error_details;

  return self->priv->error;
}

/**
 * tp_account_dup_detailed_error_vardict:
 * @self: an account
 * @details: (out) (allow-none) (transfer full):
 *  optionally used to return a variant of type %G_VARIANT_TYPE_VARDICT,
 *  which must be unreffed by the caller with g_variant_unref()
 *
 * If the account's connection is not connected, return the D-Bus error name
 * with which it last disconnected or failed to connect (in particular, this
 * is %TP_ERROR_STR_CANCELLED if it was disconnected by a user request).
 * This is the same as #TpAccount:connection-error.
 *
 * If @details is not %NULL, it will be used to return additional details about
 * the error (the same as #TpAccount:connection-error-details).
 *
 * Otherwise, return %NULL, without altering @details.
 *
 * The returned string and @details may become invalid when the main loop is
 * re-entered or the account is destroyed.
 *
 * Returns: (transfer full) (allow-none): a D-Bus error name, or %NULL.
 *
 * Since: 0.17.6
 */
gchar *
tp_account_dup_detailed_error_vardict (TpAccount *self,
    GVariant **details)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), NULL);

  if (self->priv->connection_status == TP_CONNECTION_STATUS_CONNECTED)
    return NULL;

  if (details != NULL)
    *details = _tp_asv_to_vardict (self->priv->error_details);

  return g_strdup (self->priv->error);
}

/**
 * tp_account_get_storage_provider:
 * @self: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:storage-provider property
 *
 * Since: 0.13.2
 */
const gchar *
tp_account_get_storage_provider (TpAccount *self)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), NULL);

  return self->priv->storage_provider;
}

/* FIXME: in 1.0, remove */
/**
 * tp_account_get_storage_identifier:
 * @self: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:storage-identifier property
 *
 * Since: 0.13.2
 */
const GValue *
tp_account_get_storage_identifier (TpAccount *self)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), NULL);

  return self->priv->storage_identifier;
}

/* FIXME: in 1.0, rename to tp_account_get_storage_identifier */
/**
 * tp_account_dup_storage_identifier_variant:
 * @self: a #TpAccount
 *
 * Return provider-specific information used to identify this
 * account. Use g_variant_get_type() to check that the type
 * is what you expect; for instance, if the
 * #TpAccount:storage-provider has string-based user identifiers,
 * this variant should have type %G_VARIANT_TYPE_STRING.
 *
 * Returns: (transfer full): the same as the
 *  #TpAccount:storage-identifier-variant property
 *
 * Since: 0.13.2
 */
GVariant *
tp_account_dup_storage_identifier_variant (TpAccount *self)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), NULL);

  if (self->priv->storage_identifier == NULL)
    return NULL;

  return g_variant_ref_sink (dbus_g_value_build_g_variant (
        self->priv->storage_identifier));
}

/**
 * tp_account_get_storage_restrictions:
 * @self: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: the same as the #TpAccount:storage-restrictions property
 *
 * Since: 0.13.2
 */
TpStorageRestrictionFlags
tp_account_get_storage_restrictions (TpAccount *self)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), 0);

  return self->priv->storage_restrictions;
}

static void
_tp_account_get_storage_specific_information_cb (TpProxy *self,
    const GValue *value,
    const GError *error,
    gpointer user_data,
    GObject *weak_obj)
{
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Failed to retrieve StorageSpecificInformation: %s",
          error->message);
      g_simple_async_result_set_from_error (result, error);
    }
  else
    {
      g_simple_async_result_set_op_res_gpointer (result,
          g_value_dup_boxed (value),
          (GDestroyNotify) g_hash_table_unref);
    }

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/* FIXME: in Telepathy 1.0, remove this */
/**
 * tp_account_get_storage_specific_information_async:
 * @self: a #TpAccount
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Makes an asynchronous request of @self's StorageSpecificInformation
 * property (part of the Account.Interface.Storage interface).
 *
 * When the operation is finished, @callback will be called. You must then
 * call tp_account_get_storage_specific_information_finish() to get the
 * result of the request.
 *
 * Since: 0.13.2
 */
void
tp_account_get_storage_specific_information_async (TpAccount *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_ACCOUNT (self));

  result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data, tp_account_get_storage_specific_information_async);

  tp_cli_dbus_properties_call_get (self, -1,
      TP_IFACE_ACCOUNT_INTERFACE_STORAGE, "StorageSpecificInformation",
      _tp_account_get_storage_specific_information_cb, result, NULL, NULL);
}

/* FIXME: in Telepathy 1.0, rename to ...get_storage_specific_information... */
/**
 * tp_account_dup_storage_specific_information_vardict_async:
 * @self: a #TpAccount
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Makes an asynchronous request of @self's StorageSpecificInformation
 * property (part of the Account.Interface.Storage interface).
 *
 * When the operation is finished, @callback will be called. You must then
 * call tp_account_dup_storage_specific_information_vardict_finish() to get the
 * result of the request.
 *
 * Since: 0.17.6
 */
void
tp_account_dup_storage_specific_information_vardict_async (TpAccount *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  /* we share an implementation */
  tp_account_get_storage_specific_information_async (self, callback,
      user_data);
}

/* FIXME: in Telepathy 1.0, remove this */
/**
 * tp_account_get_storage_specific_information_finish:
 * @self: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Retrieve the value of the request begun with
 * tp_account_get_storage_specific_information_async().
 *
 * Beware that the returned value is only valid until @result is freed.
 * Copy it with g_hash_table_ref() if you need to keep it for longer.
 *
 * Returns: (element-type utf8 GObject.Value) (transfer none): a #GHashTable
 *  of strings to GValues representing the D-Bus type a{sv}.
 *
 * Since: 0.13.2
 */
GHashTable *
tp_account_get_storage_specific_information_finish (TpAccount *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_account_get_storage_specific_information_async, /* do not copy */);
}

/* FIXME: in Telepathy 1.0, rename to ...get_storage_specific_information... */
/**
 * tp_account_dup_storage_specific_information_vardict_finish:
 * @self: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Retrieve the value of the request begun with
 * tp_account_dup_storage_specific_information_vardict_async().
 *
 * Returns: (transfer full): a map from strings to variants,
 *  of type %G_VARIANT_TYPE_VARDICT
 *
 * Since: 0.17.6
 */
GVariant *
tp_account_dup_storage_specific_information_vardict_finish (TpAccount *self,
    GAsyncResult *result,
    GError **error)
{
  /* we share the source tag with the non-vardict version */
  _tp_implement_finish_return_copy_pointer (self,
      tp_account_get_storage_specific_information_async, _tp_asv_to_vardict);
}

static void
_tp_account_got_all_addressing_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *object)
{
  TpAccount *self = TP_ACCOUNT (proxy);
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Error getting Addressing properties: %s", error->message);
    }
  else
    {
      self->priv->uri_schemes = g_strdupv (tp_asv_get_boxed (properties,
            "URISchemes", G_TYPE_STRV));
    }

  if (self->priv->uri_schemes == NULL)
    self->priv->uri_schemes = g_new0 (gchar *, 1);

  g_simple_async_result_complete_in_idle (result);
}

static void
connection_prepare_cb (GObject *object,
    GAsyncResult *res,
    gpointer user_data)
{
  TpConnection *connection = (TpConnection *) object;
  TpAccount *self = tp_connection_get_account (connection);
  GSimpleAsyncResult *result = user_data;
  GError *error = NULL;

  self->priv->connection_prepared = TRUE;

  if (!tp_proxy_prepare_finish (object, res, &error))
    {
      DEBUG ("Error preparing connection: %s", error->message);
      g_simple_async_result_take_error (result, error);
    }
  g_simple_async_result_complete (result);

  g_object_unref (result);
}

static void
tp_account_prepare_connection_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpAccount *self = TP_ACCOUNT (proxy);
  GSimpleAsyncResult *result;
  GArray *features;

  result = g_simple_async_result_new ((GObject *) proxy, callback, user_data,
      tp_account_prepare_connection_async);

  if (self->priv->connection == NULL)
    {
      g_simple_async_result_complete_in_idle (result);
      g_object_unref (result);
      return;
    }

  features = tp_simple_client_factory_dup_connection_features (
      tp_proxy_get_factory (self), self->priv->connection);

  tp_proxy_prepare_async (self->priv->connection, (GQuark *) features->data,
      connection_prepare_cb, result);

  g_array_unref (features);
}

static void
tp_account_prepare_addressing_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpAccount *self = TP_ACCOUNT (proxy);
  GSimpleAsyncResult *result;

  result = g_simple_async_result_new ((GObject *) proxy, callback, user_data,
      tp_account_prepare_addressing_async);

  g_assert (self->priv->uri_schemes == NULL);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_ACCOUNT_INTERFACE_ADDRESSING,
      _tp_account_got_all_addressing_cb, result, g_object_unref, NULL);
}

/**
 * tp_account_get_uri_schemes:
 * @self: a #TpAccount
 *
 * Return the #TpAccount:uri-schemes property
 *
 * Returns: (transfer none): the value of #TpAccount:uri_schemes property
 *
 * Since: 0.13.8
 */
const gchar * const *
tp_account_get_uri_schemes (TpAccount *self)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), NULL);

  return (const gchar * const *) self->priv->uri_schemes;
}

/**
 * tp_account_associated_with_uri_scheme:
 * @self: a #TpAccount
 * @scheme: (transfer none): a URI scheme such as "tel", "sip" or "xmpp"
 *
 * <!-- -->
 *
 * Returns: %TRUE if the result of tp_account_get_uri_schemes() would include
 *  @scheme
 *
 * Since: 0.13.8
 */
gboolean
tp_account_associated_with_uri_scheme (TpAccount *self,
    const gchar *scheme)
{
  return tp_strv_contains (tp_account_get_uri_schemes (self), scheme);
}

/**
 * tp_account_set_uri_scheme_association_async:
 * @self: a #TpAccount
 * @scheme: a non-%NULL URI scheme such as "tel"
 * @associate: %TRUE to use this account for @scheme, or %FALSE to not use it
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Add @scheme to the list of additional URI schemes that would be returned
 * by tp_account_get_uri_schemes(), or remove it from that list.
 *
 * @scheme should not be the primary URI scheme for the account's
 * protocol (for instance, "xmpp" for XMPP, or "sip" or "sips" for SIP),
 * since the account should be assumed to be useful for those schemes
 * regardless of the contents of the list.
 *
 * Calling this method does not require the %TP_ACCOUNT_FEATURE_ADDRESSING
 * feature to be enabled, but the change will not be reflected in the result
 * of tp_account_get_uri_schemes() or tp_account_associated_with_uri_scheme()
 * unless that feature has been enabled.
 *
 * Since: 0.13.8
 */
void
tp_account_set_uri_scheme_association_async (TpAccount *self,
    const gchar *scheme,
    gboolean associate,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_ACCOUNT (self));
  g_return_if_fail (scheme != NULL);

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_account_set_uri_scheme_association_async);

  tp_cli_account_interface_addressing_call_set_uri_scheme_association (
      self, -1, scheme, associate,
      _tp_account_void_cb, result, NULL, NULL);
}

/**
 * tp_account_set_uri_scheme_association_finish:
 * @self: a #TpAccount
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Interpret the result of tp_account_set_uri_scheme_association_async().
 *
 * Returns: %TRUE if the call was successful, otherwise %FALSE
 *
 * Since: 0.13.8
 */
gboolean
tp_account_set_uri_scheme_association_finish (TpAccount *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_account_set_uri_scheme_association_async);
}

/**
 * tp_account_get_automatic_presence:
 * @self: an account
 * @status: (out) (transfer none): return location for the presence status
 * @status_message: (out) (transfer full): return location for the
 *  user-defined message
 *
 * Gets the automatic presence, status and status message of @account. These
 * values are the same as the #TpAccount:automatic-presence-type,
 * #TpAccount:automatic-status and #TpAccount:automatic-status-message
 * properties, and are the values that will be used if the account should
 * be put online automatically.
 *
 * Returns: the same as the #TpAccount:automatic-presence-type property
 *
 * Since: 0.13.8
 */
TpConnectionPresenceType
tp_account_get_automatic_presence (TpAccount *self,
    gchar **status,
    gchar **status_message)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self),
      TP_CONNECTION_PRESENCE_TYPE_UNSET);

  if (status != NULL)
    *status = g_strdup (self->priv->auto_status);

  if (status_message != NULL)
    *status_message = g_strdup (self->priv->auto_message);

  return self->priv->auto_presence;
}

/**
 * tp_account_get_normalized_name:
 * @self: a #TpAccount
 *
 * <!-- -->
 *
 * Returns: (transfer none): the same as the #TpAccount:normalized-name
 *  property
 *
 * Since: 0.13.8
 **/
const gchar *
tp_account_get_normalized_name (TpAccount *self)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), NULL);

  return self->priv->normalized_name;
}

/**
 * tp_account_bind_connection_status_to_property:
 * @self: a #TpAccount
 * @target: the target #GObject
 * @target_property: the property on @target to bind (must be %G_TYPE_BOOLEAN)
 * @invert: %TRUE if you wish to invert the value of @target_property
 *   (i.e. %FALSE if connected)
 *
 * Binds the :connection-status of @self to the boolean property of another
 * object using a #GBinding such that the @target_property will be set to
 * %TRUE when @self is connected (and @invert is %FALSE).
 *
 * @target_property will be synchronised immediately (%G_BINDING_SYNC_CREATE).
 * @invert can be interpreted as analogous to %G_BINDING_INVERT_BOOLEAN.
 *
 * For instance, this function can be used to bind the GtkWidget:sensitive
 * property to only make a widget sensitive when the account is connected.
 *
 * See g_object_bind_property() for more information.
 *
 * Returns: (transfer none): the #GBinding instance representing the binding
 *   between the @self and the @target. The binding is released whenever the
 *   #GBinding reference count reaches zero.
 * Since: 0.13.16
 */
GBinding *
tp_account_bind_connection_status_to_property (TpAccount *self,
    gpointer target,
    const char *target_property,
    gboolean invert)
{
  g_return_val_if_fail (TP_IS_ACCOUNT (self), NULL);

  return g_object_bind_property_full (self, "connection-status",
      target, target_property,
      G_BINDING_SYNC_CREATE,
      _tp_bind_connection_status_to_boolean,
      NULL, GUINT_TO_POINTER (invert), NULL);
}
