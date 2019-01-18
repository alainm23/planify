/*
 * account-request.c - object for a currently non-existent account to create
 *
 * Copyright © 2012 Collabora Ltd. <http://www.collabora.co.uk/>
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

#include "telepathy-glib/account-request.h"

#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/util.h>
#include <telepathy-glib/simple-client-factory.h>

#define DEBUG_FLAG TP_DEBUG_ACCOUNTS
#include "telepathy-glib/dbus-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/util-internal.h"
#include "telepathy-glib/variant-util-internal.h"

/**
 * SECTION:account-request
 * @title: TpAccountRequest
 * @short_description: object for a currently non-existent account in
 *   order to create easily without speaking fluent D-Bus
 * @see_also: #TpAccountManager
 *
 * This is a convenience object to aid in the creation of accounts on
 * a #TpAccountManager without having to construct #GHashTables with
 * well-known keys. For example:
 *
 * |[
 * static void created_cb (GObject *object, GAsyncResult *res, gpointer user_data);
 *
 * static void
 * create_acount (void)
 * {
 *   TpAccountManager *am = tp_account_manager_dup ();
 *   TpAccountRequest *req;
 *
 *   req = tp_account_request_new (am, "gabble", "jabber", "Work Jabber account");
 *
 *   tp_account_request_set_parameter (req, "account", "walter.white@lospollos.lit");
 *
 *   // ...
 *
 *   tp_account_request_create_account_async (req, created_cb, NULL);
 *   g_object_unref (req);
 *   g_object_unref (am);
 * }
 *
 * static void
 * created_cb (GObject *object,
 *     GAsyncResult *result,
 *     gpointer user_data)
 * {
 *   TpAccountRequest *req = TP_ACCOUNT_REQUEST (object);
 *   TpAccount *account;
 *   GError *error = NULL;
 *
 *   account = tp_account_request_create_account_finish (req, result, &error);
 *
 *   if (account == NULL)
 *     {
 *       g_error ("Failed to create account: %s\n", error->message);
 *       g_clear_error (&error);
 *       return;
 *     }
 *
 *   // ...
 *
 *   g_object_unref (account);
 * }
 * ]|
 *
 *
 * Since: 0.19.1
 */

/**
 * TpAccountRequest:
 *
 * An object for representing a currently non-existent account which
 * is to be created on a #TpAccountManager.
 *
 * Since: 0.19.1
 */

/**
 * TpAccountRequestClass:
 *
 * The class of a #TpAccountRequest.
 */

struct _TpAccountRequestPrivate {
  TpAccountManager *account_manager;

  GSimpleAsyncResult *result;
  gboolean created;

  gchar *cm_name;
  gchar *proto_name;
  gchar *display_name;

  GHashTable *parameters;
  GHashTable *properties;
};

G_DEFINE_TYPE (TpAccountRequest, tp_account_request, G_TYPE_OBJECT)

/* properties */
enum {
  PROP_ACCOUNT_MANAGER = 1,
  PROP_CONNECTION_MANAGER,
  PROP_PROTOCOL,
  PROP_DISPLAY_NAME,
  PROP_PARAMETERS,
  PROP_PROPERTIES,
  PROP_ICON_NAME,
  PROP_NICKNAME,
  PROP_REQUESTED_PRESENCE_TYPE,
  PROP_REQUESTED_STATUS,
  PROP_REQUESTED_STATUS_MESSAGE,
  PROP_AUTOMATIC_PRESENCE_TYPE,
  PROP_AUTOMATIC_STATUS,
  PROP_AUTOMATIC_STATUS_MESSAGE,
  PROP_ENABLED,
  PROP_CONNECT_AUTOMATICALLY,
  PROP_SUPERSEDES,
  PROP_AVATAR,
  PROP_AVATAR_MIME_TYPE,
  PROP_SERVICE,
  PROP_STORAGE_PROVIDER,
  N_PROPS
};

static void
tp_account_request_init (TpAccountRequest *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_ACCOUNT_REQUEST,
      TpAccountRequestPrivate);
}

static void
tp_account_request_constructed (GObject *object)
{
  TpAccountRequest *self = TP_ACCOUNT_REQUEST (object);
  TpAccountRequestPrivate *priv = self->priv;
  void (*chain_up) (GObject *) =
    ((GObjectClass *) tp_account_request_parent_class)->constructed;

  if (chain_up != NULL)
    chain_up (object);

  g_assert (priv->account_manager != NULL);
  g_assert (priv->cm_name != NULL);
  g_assert (priv->proto_name != NULL);
  g_assert (priv->display_name != NULL);

  priv->parameters = g_hash_table_new_full (g_str_hash, g_str_equal,
      g_free, (GDestroyNotify) tp_g_value_slice_free);

  priv->properties = tp_asv_new (NULL, NULL);
}

#define GET_PRESENCE_VALUE(key, offset, type) \
  G_STMT_START { \
  GValueArray *_arr = tp_asv_get_boxed (self->priv->properties, \
      key, TP_STRUCT_TYPE_SIMPLE_PRESENCE); \
  if (_arr != NULL) \
    g_value_set_##type (value, g_value_get_##type (_arr->values + offset)); \
  } G_STMT_END

static void
tp_account_request_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpAccountRequest *self = TP_ACCOUNT_REQUEST (object);

  switch (prop_id)
    {
    case PROP_ACCOUNT_MANAGER:
      g_value_set_object (value, self->priv->account_manager);
      break;
    case PROP_CONNECTION_MANAGER:
      g_value_set_string (value, self->priv->cm_name);
      break;
    case PROP_PROTOCOL:
      g_value_set_string (value, self->priv->proto_name);
      break;
    case PROP_DISPLAY_NAME:
      g_value_set_string (value, self->priv->display_name);
      break;
    case PROP_PARAMETERS:
      g_value_take_variant (value, _tp_asv_to_vardict (self->priv->parameters));
      break;
    case PROP_PROPERTIES:
      g_value_take_variant (value, _tp_asv_to_vardict (self->priv->properties));
      break;
    case PROP_ICON_NAME:
      g_value_set_string (value,
          tp_asv_get_string (self->priv->properties,
              TP_PROP_ACCOUNT_ICON));
      break;
    case PROP_NICKNAME:
      g_value_set_string (value,
          tp_asv_get_string (self->priv->properties,
              TP_PROP_ACCOUNT_NICKNAME));
      break;
    case PROP_REQUESTED_PRESENCE_TYPE:
      GET_PRESENCE_VALUE (TP_PROP_ACCOUNT_REQUESTED_PRESENCE, 0, uint);
      break;
    case PROP_REQUESTED_STATUS:
      GET_PRESENCE_VALUE (TP_PROP_ACCOUNT_REQUESTED_PRESENCE, 1, string);
      break;
    case PROP_REQUESTED_STATUS_MESSAGE:
      GET_PRESENCE_VALUE (TP_PROP_ACCOUNT_REQUESTED_PRESENCE, 2, string);
      break;
    case PROP_AUTOMATIC_PRESENCE_TYPE:
      GET_PRESENCE_VALUE (TP_PROP_ACCOUNT_AUTOMATIC_PRESENCE, 0, uint);
      break;
    case PROP_AUTOMATIC_STATUS:
      GET_PRESENCE_VALUE (TP_PROP_ACCOUNT_AUTOMATIC_PRESENCE, 1, string);
      break;
    case PROP_AUTOMATIC_STATUS_MESSAGE:
      GET_PRESENCE_VALUE (TP_PROP_ACCOUNT_AUTOMATIC_PRESENCE, 2, string);
      break;
    case PROP_ENABLED:
      g_value_set_boolean (value,
          tp_asv_get_boolean (self->priv->properties,
              TP_PROP_ACCOUNT_ENABLED, NULL));
      break;
    case PROP_CONNECT_AUTOMATICALLY:
      g_value_set_boolean (value,
          tp_asv_get_boolean (self->priv->properties,
              TP_PROP_ACCOUNT_CONNECT_AUTOMATICALLY,
              NULL));
      break;
    case PROP_SUPERSEDES:
      {
        GPtrArray *array = tp_asv_get_boxed (self->priv->properties,
            TP_PROP_ACCOUNT_SUPERSEDES,
            TP_ARRAY_TYPE_OBJECT_PATH_LIST);

        if (array != NULL)
          {
            /* add the NULL-termination to make it a real GStrv */
            g_ptr_array_add (array, NULL);
            g_value_set_boxed (value, array->pdata);
            g_ptr_array_remove_index (array, (array->len - 1));
          }
        else
          {
            g_value_set_boxed (value, NULL);
          }
      }
      break;
    case PROP_AVATAR:
      {
        GValueArray *array = tp_asv_get_boxed (self->priv->properties,
            TP_PROP_ACCOUNT_INTERFACE_AVATAR_AVATAR,
            TP_STRUCT_TYPE_AVATAR);

        if (array != NULL)
          g_value_set_boxed (value, g_value_get_boxed (array->values));
      }
      break;
    case PROP_AVATAR_MIME_TYPE:
      {
        GValueArray *array = tp_asv_get_boxed (self->priv->properties,
            TP_PROP_ACCOUNT_INTERFACE_AVATAR_AVATAR,
            TP_STRUCT_TYPE_AVATAR);

        if (array != NULL)
          g_value_set_string (value, g_value_get_string (array->values + 1));
      }
      break;
    case PROP_SERVICE:
      g_value_set_string (value, tp_asv_get_string (self->priv->properties,
            TP_PROP_ACCOUNT_SERVICE));
      break;
    case PROP_STORAGE_PROVIDER:
      g_value_set_string (value, tp_asv_get_string (self->priv->properties,
            TP_PROP_ACCOUNT_INTERFACE_STORAGE_STORAGE_PROVIDER));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
      break;
    }
}

#undef GET_PRESENCE_VALUE

static void
tp_account_request_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpAccountRequest *self = TP_ACCOUNT_REQUEST (object);
  TpAccountRequestPrivate *priv = self->priv;

  switch (property_id)
    {
    case PROP_ACCOUNT_MANAGER:
      g_assert (priv->account_manager == NULL);
      priv->account_manager = g_value_dup_object (value);
      break;
    case PROP_CONNECTION_MANAGER:
      g_assert (priv->cm_name == NULL);
      priv->cm_name = g_value_dup_string (value);
      break;
    case PROP_PROTOCOL:
      g_assert (priv->proto_name == NULL);
      priv->proto_name = g_value_dup_string (value);
      break;
    case PROP_DISPLAY_NAME:
      g_assert (priv->display_name == NULL);
      priv->display_name = g_value_dup_string (value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}

static void
tp_account_request_dispose (GObject *object)
{
  TpAccountRequest *self = TP_ACCOUNT_REQUEST (object);
  TpAccountRequestPrivate *priv = self->priv;

  g_clear_object (&priv->account_manager);

  tp_clear_pointer (&priv->parameters, g_hash_table_unref);
  tp_clear_pointer (&priv->properties, g_hash_table_unref);

  /* release any references held by the object here */

  if (G_OBJECT_CLASS (tp_account_request_parent_class)->dispose != NULL)
    G_OBJECT_CLASS (tp_account_request_parent_class)->dispose (object);
}

static void
tp_account_request_finalize (GObject *object)
{
  TpAccountRequest *self = TP_ACCOUNT_REQUEST (object);
  TpAccountRequestPrivate *priv = self->priv;

  tp_clear_pointer (&priv->cm_name, g_free);
  tp_clear_pointer (&priv->proto_name, g_free);
  tp_clear_pointer (&priv->display_name, g_free);

  /* free any data held directly by the object here */

  if (G_OBJECT_CLASS (tp_account_request_parent_class)->finalize != NULL)
    G_OBJECT_CLASS (tp_account_request_parent_class)->finalize (object);
}

static void
tp_account_request_class_init (TpAccountRequestClass *klass)
{
  GObjectClass *object_class = (GObjectClass *) klass;

  g_type_class_add_private (klass, sizeof (TpAccountRequestPrivate));

  object_class->constructed = tp_account_request_constructed;
  object_class->get_property = tp_account_request_get_property;
  object_class->set_property = tp_account_request_set_property;
  object_class->dispose = tp_account_request_dispose;
  object_class->finalize = tp_account_request_finalize;

  /**
   * TpAccountRequest:account-manager:
   *
   * The #TpAccountManager to create the account on.
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_ACCOUNT_MANAGER,
      g_param_spec_object ("account-manager",
          "Account manager",
          "The account's account manager",
          TP_TYPE_ACCOUNT_MANAGER,
          G_PARAM_STATIC_STRINGS | G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * TpAccountRequest:connection-manager:
   *
   * The account's connection manager name.
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_CONNECTION_MANAGER,
      g_param_spec_string ("connection-manager",
          "Connection manager",
          "The account's connection manager name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * TpAccountRequest:protocol:
   *
   * The account's machine-readable protocol name, such as "jabber", "msn" or
   * "local-xmpp". Recommended names for most protocols can be found in the
   * Telepathy D-Bus Interface Specification.
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_PROTOCOL,
      g_param_spec_string ("protocol",
          "Protocol",
          "The account's protocol name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * TpAccountRequest:display-name:
   *
   * The account's display name. To change this property use
   * tp_account_request_set_display_name().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_DISPLAY_NAME,
      g_param_spec_string ("display-name",
          "DisplayName",
          "The account's display name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * TpAccountRequest:parameters:
   *
   * The account's connection parameters. To add a parameter, use
   * tp_account_request_set_parameter() or another convience function.
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_PARAMETERS,
      g_param_spec_variant ("parameters",
          "Parameters",
          "Connection parameters of the account",
          G_VARIANT_TYPE_VARDICT, NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:properties:
   *
   * The account's properties.
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_PROPERTIES,
      g_param_spec_variant ("properties",
          "Properties",
          "Account properties",
          G_VARIANT_TYPE_VARDICT, NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:icon-name:
   *
   * The account's icon name. To change this propery, use
   * tp_account_request_set_icon_name().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_ICON_NAME,
      g_param_spec_string ("icon-name",
          "Icon",
          "The account's icon name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:nickname:
   *
   * The account's nickname. To change this property use
   * tp_account_request_set_nickname().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_NICKNAME,
      g_param_spec_string ("nickname",
          "Nickname",
          "The account's nickname",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:requested-presence-type:
   *
   * The account's requested presence type (a
   * #TpConnectionPresenceType). To change this property use
   * tp_account_request_set_requested_presence().
   *
   * Since: 0.19.1
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
   * TpAccountRequest:requested-status:
   *
   * The requested Status string of the account. To change this
   * property use tp_account_request_set_requested_presence().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_REQUESTED_STATUS,
      g_param_spec_string ("requested-status",
          "RequestedStatus",
          "The account's requested status string",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:requested-status-message:
   *
   * The requested status message message of the account. To change
   * this property use tp_account_request_set_requested_presence().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_REQUESTED_STATUS_MESSAGE,
      g_param_spec_string ("requested-status-message",
          "RequestedStatusMessage",
          "The requested Status message string of the account",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:automatic-presence-type:
   *
   * The account's automatic presence type (a
   * #TpConnectionPresenceType). To change this property use
   * tp_account_request_set_automatic_presence().
   *
   * When the account is put online automatically, for instance to
   * make a channel request or because network connectivity becomes
   * available, the automatic presence type, status and message will
   * be copied to their "requested" counterparts.
   *
   * Since: 0.19.1
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
   * TpAccountRequest:automatic-status:
   *
   * The string status name to use in conjunction with the
   * #TpAccountRequest:automatic-presence-type. To change this property
   * use tp_account_request_set_automatic_presence().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_AUTOMATIC_STATUS,
      g_param_spec_string ("automatic-status",
          "AutomaticPresence status",
          "Presence status used to put the account online automatically",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:automatic-status-message:
   *
   * The user-defined message to use in conjunction with the
   * #TpAccount:automatic-presence-type. To change this property use
   * tp_account_request_set_automatic_presence().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_AUTOMATIC_STATUS_MESSAGE,
      g_param_spec_string ("automatic-status-message",
          "AutomaticPresence message",
          "User-defined message used to put the account online automatically",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:enabled:
   *
   * Whether the account is enabled or not. To change this property
   * use tp_account_request_set_enabled().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_ENABLED,
      g_param_spec_boolean ("enabled",
          "Enabled",
          "Whether this account is enabled or not",
          FALSE,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:connect-automatically:
   *
   * Whether the account should connect automatically or not. To change this
   * property, use tp_account_request_set_connect_automatically().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_CONNECT_AUTOMATICALLY,
      g_param_spec_boolean ("connect-automatically",
          "ConnectAutomatically",
          "Whether this account should connect automatically or not",
          FALSE,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:supersedes:
   *
   * The object paths of previously-active accounts superseded by this one.
   * For instance, this can be used in a logger to read old logs for an
   * account that has been migrated from one connection manager to another.
   *
   * To add to this property use tp_account_request_add_supersedes().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_SUPERSEDES,
      g_param_spec_boxed ("supersedes",
        "Supersedes",
        "Accounts superseded by this one",
        G_TYPE_STRV,
        G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:avatar:
   *
   * The avatar set on the account. The avatar's mime type can be read
   * in the #TpAccountRequest:avatar-mime-type property. To change this
   * property, use tp_account_request_set_avatar().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_AVATAR,
      g_param_spec_boxed ("avatar",
        "Avatar",
        "The account's avatar data",
        G_TYPE_ARRAY,
        G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:avatar-mime-type:
   *
   * The mime type of the #TpAccountRequest:avatar property. To change
   * this property, use tp_account_request_set_avatar().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_AVATAR_MIME_TYPE,
      g_param_spec_string ("avatar-mime-type",
          "Avatar mime type",
          "The account's avatar's mime type",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:service:
   *
   * A string describing the service of the account, which must
   * consist only of ASCII letters, numbers and hyphen/minus signs,
   * and start with a letter (matching the requirements for
   * Protocol). To change this property, use
   * tp_account_request_set_service().
   *
   * Since: 0.19.1
   */
  g_object_class_install_property (object_class, PROP_SERVICE,
      g_param_spec_string ("service",
          "Service",
          "The account's service",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpAccountRequest:storage-provider:
   *
   * The account's storage provider. To change this property use
   * tp_account_request_set_storage_provider().
   *
   * Since: 0.19.4
   */
  g_object_class_install_property (object_class, PROP_STORAGE_PROVIDER,
      g_param_spec_string ("storage-provider",
          "Storage Provider",
          "The account's storage provider",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));
}

/**
 * tp_account_request_new:
 * @account_manager: the #TpAccountManager to create the account on
 * @manager: the name of the connection manager
 * @protocol: the name of the protocol on @manager
 * @display_name: the user-visible name of this account
 *
 * Convenience function to create a new account request object which
 * will assist in the creation of a new account on @account_manager,
 * using connection manager @manager, and protocol @protocol.
 *
 * Returns: (transfer full): a new reference to an account request
 *   object, or %NULL if any argument is incorrect
 *
 * Since: 0.19.1
 */
TpAccountRequest *
tp_account_request_new (TpAccountManager *account_manager,
    const gchar *manager,
    const gchar *protocol,
    const gchar *display_name)
{
  g_return_val_if_fail (TP_IS_ACCOUNT_MANAGER (account_manager), NULL);
  g_return_val_if_fail (manager != NULL, NULL);
  g_return_val_if_fail (protocol != NULL, NULL);

  return g_object_new (TP_TYPE_ACCOUNT_REQUEST,
      "account-manager", account_manager,
      "connection-manager", manager,
      "protocol", protocol,
      "display-name", display_name,
      NULL);
}

/**
 * tp_account_request_new_from_protocol:
 * @account_manager: the #TpAccountManager to create the account on
 * @protocol: a #TpProtocol
 * @display_name: the user-visible name of this account
 *
 * Convenience function to create a new #TpAccountRequest object using
 * a #TpProtocol instance, instead of specifying connection manager
 * and protocol name specifically. See tp_account_request_new() for
 * more details.
 *
 * Returns: (transfer full): a new reference to an account request
 *   object, or %NULL if any argument is incorrect
 *
 * Since: 0.19.1
 */
TpAccountRequest *
tp_account_request_new_from_protocol (TpAccountManager *account_manager,
    TpProtocol *protocol,
    const gchar *display_name)
{
  g_return_val_if_fail (TP_IS_ACCOUNT_MANAGER (account_manager), NULL);
  g_return_val_if_fail (TP_IS_PROTOCOL (protocol), NULL);

  return g_object_new (TP_TYPE_ACCOUNT_REQUEST,
      "account-manager", account_manager,
      "connection-manager", tp_protocol_get_cm_name (protocol),
      "protocol", tp_protocol_get_name (protocol),
      "display-name", display_name,
      NULL);
}

/**
 * tp_account_request_set_display_name:
 * @self: a #TpAccountRequest
 * @name: a display name for the account
 *
 * Set the display name for the new account, @self, to @name. Use the
 * #TpAccountRequest:display-name property to read the current display
 * name.
 *
 * Since: 0.19.1
 */
void
tp_account_request_set_display_name (TpAccountRequest *self,
    const gchar *name)
{
  TpAccountRequestPrivate *priv;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));
  g_return_if_fail (name != NULL);

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  g_free (priv->display_name);
  priv->display_name = g_strdup (name);
}

/**
 * tp_account_request_set_icon_name:
 * @self: a #TpAccountRequest
 * @icon: an icon name for the account
 *
 * Set the icon name for the new account, @self, to @icon. Use the
 * #TpAccountRequest:icon-name property to read the current icon name.
 *
 * Since: 0.19.1
 */
void
tp_account_request_set_icon_name (TpAccountRequest *self,
    const gchar *icon)
{
  TpAccountRequestPrivate *priv;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));
  g_return_if_fail (icon != NULL);

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  tp_asv_set_string (priv->properties, TP_PROP_ACCOUNT_ICON, icon);
}

/**
 * tp_account_request_set_nickname:
 * @self: a #TpAccountRequest
 * @nickname: a nickname for the account
 *
 * Set the nickname for the new account, @self, to @nickname. Use the
 * #TpAccountRequest:nickname property to read the current nickname.
 *
 * Since: 0.19.1
 */
void
tp_account_request_set_nickname (TpAccountRequest *self,
    const gchar *nickname)
{
  TpAccountRequestPrivate *priv;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));
  g_return_if_fail (nickname != NULL);

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  tp_asv_set_string (priv->properties, TP_PROP_ACCOUNT_NICKNAME, nickname);
}

/**
 * tp_account_request_set_requested_presence:
 * @self: a #TpAccountRequest
 * @presence: the requested presence type
 * @status: the requested presence status
 * @message: the requested presence message
 *
 * Set the requested presence for the new account, @self, to the type
 * (@presence, @status), with message @message. Use the
 * #TpAccountRequest:requested-presence-type,
 * #TpAccountRequest:requested-status, and
 * #TpAccountRequest:requested-status-message properties to read the
 * current requested presence.
 *
 * Since: 0.19.1
 */
void
tp_account_request_set_requested_presence (TpAccountRequest *self,
    TpConnectionPresenceType presence,
    const gchar *status,
    const gchar *message)
{
  TpAccountRequestPrivate *priv;
  GValue *value;
  GValueArray *arr;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  value = tp_g_value_slice_new_take_boxed (TP_STRUCT_TYPE_SIMPLE_PRESENCE,
      dbus_g_type_specialized_construct (TP_STRUCT_TYPE_SIMPLE_PRESENCE));
  arr = (GValueArray *) g_value_get_boxed (value);

  g_value_set_uint (arr->values, presence);
  g_value_set_string (arr->values + 1, status);
  g_value_set_string (arr->values + 2, message);

  g_hash_table_insert (priv->properties,
      TP_PROP_ACCOUNT_REQUESTED_PRESENCE, value);
}

/**
 * tp_account_request_set_automatic_presence:
 * @self: a #TpAccountRequest
 * @presence: the automatic presence type
 * @status: the automatic presence status
 * @message: the automatic presence message
 *
 * Set the automatic presence for the new account, @self, to the type
 * (@presence, @status), with message @message. Use the
 * #TpAccountRequest:automatic-presence-type,
 * #TpAccountRequest:automatic-status, and
 * #TpAccountRequest:automatic-status-message properties to read the
 * current automatic presence.
 *
 * Since: 0.19.1
 */
void
tp_account_request_set_automatic_presence (TpAccountRequest *self,
    TpConnectionPresenceType presence,
    const gchar *status,
    const gchar *message)
{
  TpAccountRequestPrivate *priv;
  GValue *value;
  GValueArray *arr;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  value = tp_g_value_slice_new_take_boxed (TP_STRUCT_TYPE_SIMPLE_PRESENCE,
      dbus_g_type_specialized_construct (TP_STRUCT_TYPE_SIMPLE_PRESENCE));
  arr = (GValueArray *) g_value_get_boxed (value);

  g_value_set_uint (arr->values, presence);
  g_value_set_string (arr->values + 1, status);
  g_value_set_string (arr->values + 2, message);

  g_hash_table_insert (priv->properties,
      TP_PROP_ACCOUNT_AUTOMATIC_PRESENCE, value);
}

/**
 * tp_account_request_set_enabled:
 * @self: a #TpAccountRequest
 * @enabled: %TRUE if the account is to be enabled
 *
 * Set the enabled property of the account on creation to
 * @enabled. Use the #TpAccountRequest:enabled property to read the
 * current enabled value.
 *
 * Since: 0.19.1
 */
void
tp_account_request_set_enabled (TpAccountRequest *self,
    gboolean enabled)
{
  TpAccountRequestPrivate *priv;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  tp_asv_set_boolean (priv->properties, TP_PROP_ACCOUNT_ENABLED, enabled);
}

/**
 * tp_account_request_set_connect_automatically:
 * @self: a #TpAccountRequest
 * @connect_automatically: %TRUE if the account is to connect automatically
 *
 * Set the connect automatically property of the account on creation
 * to @connect_automatically so that the account is brought online to
 * the automatic presence. Use the
 * #TpAccountRequest:connect-automatically property to read the current
 * connect automatically value.
 *
 * Since: 0.19.1
 */
void
tp_account_request_set_connect_automatically (TpAccountRequest *self,
    gboolean connect_automatically)
{
  TpAccountRequestPrivate *priv;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  tp_asv_set_boolean (priv->properties,
      TP_PROP_ACCOUNT_CONNECT_AUTOMATICALLY,
      connect_automatically);
}

/**
 * tp_account_request_add_supersedes:
 * @self: a #TpAccountRequest
 * @superseded_path: an account object path to add to the supersedes
 *   list
 *
 * Add an account object path to the list of superseded accounts which
 * this new account will supersede. Use the
 * #TpAccountRequest:supersedes property to read the current list of
 * superseded accounts.
 *
 * Since: 0.19.1
 */
void
tp_account_request_add_supersedes (TpAccountRequest *self,
    const gchar *superseded_path)
{
  TpAccountRequestPrivate *priv;
  GPtrArray *array;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));
  g_return_if_fail (g_variant_is_object_path (superseded_path));

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  array = tp_asv_get_boxed (priv->properties,
      TP_PROP_ACCOUNT_SUPERSEDES,
      TP_ARRAY_TYPE_OBJECT_PATH_LIST);

  if (array == NULL)
    {
      array = g_ptr_array_new ();

      tp_asv_take_boxed (priv->properties,
          TP_PROP_ACCOUNT_SUPERSEDES,
          TP_ARRAY_TYPE_OBJECT_PATH_LIST, array);
    }

  g_ptr_array_add (array, g_strdup (superseded_path));
}

/**
 * tp_account_request_set_avatar:
 * @self: a #TpAccountRequest
 * @avatar: (allow-none) (array length=len): a new avatar to set; can
 *   be %NULL only if %len equals 0
 * @len: the length of the new avatar
 * @mime_type: (allow-none): the MIME type of the new avatar; can be %NULL
 *  only if @len equals 0
 *
 * Set the avatar of the account @self to @avatar. Use the
 * #TpAccountRequest:avatar and #TpAccountRequest:avatar-mime-type
 * properties to read the current avatar.
 *
 * Since: 0.19.1
 */
void
tp_account_request_set_avatar (TpAccountRequest *self,
    const guchar *avatar,
    gsize len,
    const gchar *mime_type)
{
  TpAccountRequestPrivate *priv;
  GArray *tmp;
  GValueArray *arr;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));
  g_return_if_fail (avatar != NULL || len == 0);
  g_return_if_fail (mime_type != NULL || len == 0);

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  tmp = g_array_new (FALSE, FALSE, sizeof (guchar));

  if (len > 0)
    g_array_append_vals (tmp, avatar, len);

  arr = tp_value_array_build (2,
      TP_TYPE_UCHAR_ARRAY, tmp,
      G_TYPE_STRING, mime_type,
      G_TYPE_INVALID);

  g_array_unref (tmp);

  tp_asv_take_boxed (priv->properties,
      TP_PROP_ACCOUNT_INTERFACE_AVATAR_AVATAR,
      TP_STRUCT_TYPE_AVATAR, arr);
}

/**
 * tp_account_request_set_service:
 * @self: a #TpAccountRequest
 * @service: the service name for
 *
 * Set the service property of the account to @service. Use the
 * #TpAccountRequest:service property to read the current value.
 *
 * Since: 0.19.1
 */
void
tp_account_request_set_service (TpAccountRequest *self,
    const gchar *service)
{
  TpAccountRequestPrivate *priv;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));
  g_return_if_fail (service != NULL);

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  tp_asv_set_string (priv->properties,
      TP_PROP_ACCOUNT_SERVICE, service);
}

/**
 * tp_account_request_set_storage_provider:
 * @self: a #TpAccountRequest
 * @provider: the name of an account storage implementation
 *
 * Set the account storage to use when creating the account. Use the
 * #TpAccountRequest:storage-provider property to read the current value.
 *
 * Since: 0.19.4
 */
void
tp_account_request_set_storage_provider (TpAccountRequest *self,
    const gchar *provider)
{
  TpAccountRequestPrivate *priv;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  tp_asv_set_string (priv->properties,
      TP_PROP_ACCOUNT_INTERFACE_STORAGE_STORAGE_PROVIDER, provider);
}

/**
 * tp_account_request_set_parameter:
 * @self: a #TpAccountRequest
 * @key: the parameter key
 * @value: (transfer none): a variant containing the parameter value
 *
 * Set an account parameter, @key, to @value. Use the
 * #TpAccountRequest:parameters property to read the current list of
 * set parameters.
 *
 * Parameters can be unset using tp_account_request_unset_parameter().
 *
 * Since: 0.19.1
 */
void
tp_account_request_set_parameter (TpAccountRequest *self,
    const gchar *key,
    GVariant *value)
{
  TpAccountRequestPrivate *priv;
  GValue one = G_VALUE_INIT, *two;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));
  g_return_if_fail (key != NULL);
  g_return_if_fail (value != NULL);

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  dbus_g_value_parse_g_variant (value, &one);
  two = tp_g_value_slice_dup (&one);

  g_hash_table_insert (priv->parameters, g_strdup (key), two);

  g_value_unset (&one);
}

/**
 * tp_account_request_unset_parameter:
 * @self: a #TpAccountRequest
 * @key: the parameter key
 *
 * Unset the account parameter @key which has previously been set
 * using tp_account_request_set_parameter() or another convenience
 * function.
 *
 * Since: 0.19.1
 */
void
tp_account_request_unset_parameter (TpAccountRequest *self,
    const gchar *key)
{
  TpAccountRequestPrivate *priv;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));
  g_return_if_fail (key != NULL);

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  g_hash_table_remove (priv->parameters, key);
}

/**
 * tp_account_request_set_parameter_string: (skip)
 * @self: a #TpAccountRequest
 * @key: the parameter key
 * @value: the parameter value
 *
 * Convenience function to set an account parameter string value. See
 * tp_account_request_set_parameter() for more details.
 *
 * Since: 0.19.1
 */
void
tp_account_request_set_parameter_string (TpAccountRequest *self,
    const gchar *key,
    const gchar *value)
{
  TpAccountRequestPrivate *priv;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));
  g_return_if_fail (key != NULL);
  g_return_if_fail (value != NULL);

  priv = self->priv;

  g_return_if_fail (priv->result == NULL && !priv->created);

  g_hash_table_insert (priv->parameters, g_strdup (key),
      tp_g_value_slice_new_string (value));
}

static void
tp_account_request_account_prepared_cb (GObject *object,
    GAsyncResult *result,
    gpointer user_data)
{
  TpAccountRequest *self = user_data;
  TpAccountRequestPrivate *priv = self->priv;
  GError *error = NULL;

  if (!tp_proxy_prepare_finish (object, result, &error))
    {
      DEBUG ("Error preparing account: %s", error->message);
      g_simple_async_result_take_error (priv->result, error);
    }

  g_simple_async_result_complete (priv->result);
  g_clear_object (&priv->result);
}

static void
tp_account_request_create_account_cb (TpAccountManager *proxy,
    const gchar *account_path,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpAccountRequest *self = TP_ACCOUNT_REQUEST (weak_object);
  TpAccountRequestPrivate *priv = self->priv;
  GError *e = NULL;
  TpAccount *account;
  GArray *features;

  if (error != NULL)
    {
      DEBUG ("failed to create account: %s", error->message);
      g_simple_async_result_set_from_error (priv->result, error);
      g_simple_async_result_complete (priv->result);
      g_clear_object (&priv->result);
      return;
    }

  priv->created = TRUE;

  account = tp_simple_client_factory_ensure_account (
      tp_proxy_get_factory (proxy), account_path, NULL, &e);

  if (account == NULL)
    {
      g_simple_async_result_take_error (priv->result, e);
      g_simple_async_result_complete (priv->result);
      g_clear_object (&priv->result);
      return;
    }

  /* Give account's ref to the result */
  g_simple_async_result_set_op_res_gpointer (priv->result, account,
      g_object_unref);

  features = tp_simple_client_factory_dup_account_features (
      tp_proxy_get_factory (proxy), account);

  tp_proxy_prepare_async (account, (GQuark *) features->data,
      tp_account_request_account_prepared_cb, self);

  g_array_unref (features);
}

/**
 * tp_account_request_create_account_async:
 * @self: a #TpAccountRequest
 * @callback: a function to call when the account has been created
 * @user_data: user data to @callback
 *
 * Start an asynchronous operation to create the account @self on the
 * account manager.
 *
 * @callback will only be called when the newly created #TpAccount has
 * the %TP_ACCOUNT_FEATURE_CORE feature ready on it, so when calling
 * tp_account_request_create_account_finish(), one can guarantee this
 * feature.
 *
 * Since: 0.19.1
 */
void
tp_account_request_create_account_async (TpAccountRequest *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpAccountRequestPrivate *priv = self->priv;

  g_return_if_fail (TP_IS_ACCOUNT_REQUEST (self));

  priv = self->priv;

  if (priv->result != NULL)
    {
      g_simple_async_report_error_in_idle (G_OBJECT (self),
          callback, user_data,
          TP_ERROR, TP_ERROR_BUSY,
          "An account creation operation has already been started on this "
          "account request");
      return;
    }

  if (priv->created)
    {
      g_simple_async_report_error_in_idle (G_OBJECT (self),
          callback, user_data,
          TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "This account has already been created");
      return;
    }

  priv->result = g_simple_async_result_new (G_OBJECT (self), callback, user_data,
      tp_account_request_create_account_async);

  tp_cli_account_manager_call_create_account (priv->account_manager,
      -1, priv->cm_name, priv->proto_name, priv->display_name,
      priv->parameters, priv->properties,
      tp_account_request_create_account_cb, NULL, NULL, G_OBJECT (self));
}

/**
 * tp_account_request_create_account_finish:
 * @self: a #TpAccountRequest
 * @result: a #GAsyncResult
 * @error: something
 *
 * Finishes an asynchronous account creation operation and returns a
 * new ref to a #TpAccount object. The returned account will have the
 * features listed in tp_simple_client_factory_dup_account_features()
 * (with the proxy factory from #TpAccountRequest:account-manager)
 * prepared on it.
 *
 * Returns: (transfer full): a new ref to a #TpAccount, or %NULL
 *
 * Since: 0.19.1
 */
TpAccount *
tp_account_request_create_account_finish (TpAccountRequest *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_account_request_create_account_async, g_object_ref);
}
