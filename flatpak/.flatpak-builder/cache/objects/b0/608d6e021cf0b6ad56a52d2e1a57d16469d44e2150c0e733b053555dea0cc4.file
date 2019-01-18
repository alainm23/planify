/*
 * connection.c - proxy for a Telepathy connection
 *
 * Copyright (C) 2007-2011 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2007-2011 Nokia Corporation
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

#include "telepathy-glib/connection.h"

#include <string.h>

#include <dbus/dbus-protocol.h>

#include <telepathy-glib/connection-manager.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/handle.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CONNECTION
#include "telepathy-glib/capabilities-internal.h"
#include "telepathy-glib/connection-internal.h"
#include "telepathy-glib/connection-contact-list.h"
#include "telepathy-glib/dbus-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/proxy-internal.h"
#include "telepathy-glib/simple-client-factory-internal.h"
#include "telepathy-glib/contact-internal.h"
#include "telepathy-glib/util-internal.h"
#include "telepathy-glib/variant-util-internal.h"

#include "_gen/tp-cli-connection-body.h"

/**
 * SECTION:connection
 * @title: TpConnection
 * @short_description: proxy object for a Telepathy connection
 * @see_also: #TpConnectionManager, #TpChannel
 *
 * #TpConnection objects represent Telepathy instant messaging connections
 * accessed via D-Bus.
 *
 * #TpConnection objects should be obtained from a #TpAccount, unless you
 * are implementing a lower-level Telepathy component (such as the account
 * manager service itself).
 *
 * Since 0.16, #TpConnection always has a non-%NULL #TpProxy:factory, and its
 * #TpProxy:factory will be propagated to its #TpChannel objects
 * (if any). Similarly, the #TpProxy:factory<!-- -->'s features
 * will be used for #TpContact objects.
 * If a #TpConnection is created without going via the
 * #TpAccount or specifying a #TpProxy:factory, the default
 * is to use a new #TpAutomaticClientFactory.
 *
 * Since: 0.7.1
 */

/**
 * TP_CONNECTION_FEATURE_CORE:
 *
 * Expands to a call to a function that returns a quark for the "core" feature
 * on a #TpConnection.
 *
 * When this feature is prepared, the basic properties of the Connection have
 * been retrieved and are available for use, and change-notification has been
 * set up for those that can change.
 *
 * Specifically, this implies that:
 *
 * <itemizedlist>
 *  <listitem>#TpConnection:status has a value other than
 *    %TP_UNKNOWN_CONNECTION_STATUS, and #TpConnection:status-reason is
 *    the reason for changing to that status</listitem>
 *  <listitem>interfaces that are always available have been added to the
 *    #TpProxy:interfaces (although the set of interfaces is not guaranteed
 *    to be complete until #TpConnection:status becomes
 *    %TP_CONNECTION_STATUS_CONNECTED))</listitem>
 * </itemizedlist>
 *
 * <note>
 *  <title>prepared does not imply connected</title>
 *  <para>Unlike the older #TpConnection:connection-ready mechanism, this
 *    feature does not imply that the connection has successfully connected.
 *    It only implies that an initial status (disconnected, connecting or
 *    connected) has been discovered. %TP_CONNECTION_FEATURE_CONNECTED
 *    is the closest equivalent of #TpConnection:connection-ready.</para>
 * </note>
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.11.3
 */

GQuark
tp_connection_get_feature_quark_core (void)
{
  return g_quark_from_static_string ("tp-connection-feature-core");
}

/**
 * TP_CONNECTION_FEATURE_CONNECTED:
 *
 * Expands to a call to a function that returns a #GQuark representing the
 * "connected" feature.
 *
 * When this feature is prepared, it means that the connection has become
 * connected to the appropriate real-time communications service, and all
 * information requested via other features has been updated accordingly.
 * In particular, the following aspects of %TP_CONNECTION_FEATURE_CORE
 * will be up to date:
 *
 * <itemizedlist>
 *  <listitem>#TpConnection:status is
 *    %TP_CONNECTION_STATUS_CONNECTED</listitem>
 *  <listitem>#TpConnection:self-handle is valid and non-zero</listitem>
 *  <listitem>#TpConnection:self-contact is non-%NULL</listitem>
 *  <listitem>all interfaces have been added to the set of
 *    #TpProxy:interfaces, and that set will not change again</listitem>
 * </itemizedlist>
 *
 * <note>
 *   <title>Someone still has to call Connect()</title>
 *   <para>Requesting this feature via tp_proxy_prepare_async() means that
 *     you want to wait for the connection to connect, but it doesn't actually
 *     start the process of connecting. For connections associated with
 *     a #TpAccount, the account manager service is responsible for
 *     doing that, but if you are constructing connections directly
 *     (e.g. if you are implementing an account manager), you must
 *     tp_cli_connection_call_connect() separately.
 *     </para>
 * </note>
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.11.3
 */

GQuark
tp_connection_get_feature_quark_connected (void)
{
  return g_quark_from_static_string ("tp-connection-feature-connected");
}

/**
 * TP_CONNECTION_FEATURE_CAPABILITIES:
 *
 * Expands to a call to a function that returns a #GQuark representing the
 * "capabilities" feature.
 *
 * When this feature is prepared, the Requests.RequestableChannelClasses
 * property of the Connection has been retrieved.
 * In particular, the %TpConnection:capabilities property has been set.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.11.3
 */

GQuark
tp_connection_get_feature_quark_capabilities (void)
{
  return g_quark_from_static_string ("tp-connection-feature-capabilities");
}

/**
 * TP_CONNECTION_FEATURE_BALANCE:
 *
 * Expands to a call to a function that returns a #GQuark representing the
 * "balance" feature.
 *
 * When this feature is prepared, the Balance.AccountBalance and
 * Balance.ManageCreditURI properties of the Connection have been retrieved.
 * In particular, the %TpConnection:balance, %TpConnection:balance-scale,
 * %TpConnection:balance-currency and %TpConnection:balance-uri properties
 * have been set and the TpConnection::balance-changed: will be emitted
 * when they are changed.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.15.1
 */

GQuark
tp_connection_get_feature_quark_balance (void)
{
  return g_quark_from_static_string ("tp-connection-feature-balance");
}

/**
 * TP_ERRORS_DISCONNECTED:
 *
 * #GError domain representing a Telepathy connection becoming disconnected.
 * The @code in a #GError with this domain must be a member of
 * #TpConnectionStatusReason.
 *
 * This macro expands to a function call returning a #GQuark.
 *
 * Since 0.7.24, this error domain is only used if a connection manager emits
 * a #TpConnectionStatusReason not known to telepathy-glib.
 *
 * Since: 0.7.1
 */
GQuark
tp_errors_disconnected_quark (void)
{
  static GQuark q = 0;

  if (q == 0)
    q = g_quark_from_static_string ("tp_errors_disconnected_quark");

  return q;
}

/**
 * TP_UNKNOWN_CONNECTION_STATUS:
 *
 * An invalid connection status used in #TpConnection to indicate that the
 * status has not yet been discovered.
 *
 * Since: 0.7.1
 */

/**
 * TpConnectionClass:
 * @parent_class: the parent class
 *
 * The class of a #TpConnection. In addition to @parent_class there are four
 * pointers reserved for possible future use.
 *
 * (Changed in 0.7.12: the layout of the structure is visible, allowing
 * subclassing.)
 *
 * Since: 0.7.1
 */

/**
 * TpConnection:
 *
 * A proxy object for a Telepathy connection. There are no interesting
 * public struct fields.
 *
 * (Changed in 0.7.12: the layout of the structure is visible, allowing
 * subclassing.)
 *
 * Since: 0.7.1
 */

/* properties */
enum
{
  PROP_STATUS = 1,
  PROP_STATUS_REASON,
  PROP_CONNECTION_MANAGER_NAME,
  PROP_CM_NAME,
  PROP_PROTOCOL_NAME,
  PROP_CONNECTION_READY,
  PROP_SELF_CONTACT,
  PROP_SELF_HANDLE,
  PROP_CAPABILITIES,
  PROP_BALANCE,
  PROP_BALANCE_SCALE,
  PROP_BALANCE_CURRENCY,
  PROP_BALANCE_URI,
  PROP_CONTACT_LIST_STATE,
  PROP_CONTACT_LIST_PERSISTS,
  PROP_CAN_CHANGE_CONTACT_LIST,
  PROP_REQUEST_USES_MESSAGE,
  PROP_DISJOINT_GROUPS,
  PROP_GROUP_STORAGE,
  PROP_CONTACT_GROUPS,
  PROP_CAN_REPORT_ABUSIVE,
  PROP_BLOCKED_CONTACTS,
  N_PROPS
};

enum {
  SIGNAL_BALANCE_CHANGED,
  SIGNAL_GROUPS_CREATED,
  SIGNAL_GROUPS_REMOVED,
  SIGNAL_GROUP_RENAMED,
  SIGNAL_CONTACT_LIST_CHANGED,
  SIGNAL_BLOCKED_CONTACTS_CHANGED,
  N_SIGNALS
};

static guint signals[N_SIGNALS] = { 0 };

G_DEFINE_TYPE (TpConnection,
    tp_connection,
    TP_TYPE_PROXY)

static void
tp_connection_get_property (GObject *object,
                            guint property_id,
                            GValue *value,
                            GParamSpec *pspec)
{
  TpConnection *self = TP_CONNECTION (object);

  /* Deprecated properties uses deprecated getters */
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  switch (property_id)
    {
    case PROP_CONNECTION_MANAGER_NAME:
      g_value_set_string (value, self->priv->cm_name);
      break;
    case PROP_CM_NAME:
      g_value_set_string (value, self->priv->cm_name);
      break;
    case PROP_PROTOCOL_NAME:
      g_value_set_string (value, self->priv->proto_name);
      break;
    case PROP_CONNECTION_READY:
      g_value_set_boolean (value, self->priv->ready);
      break;
    case PROP_STATUS:
      g_value_set_uint (value, self->priv->status);
      break;
    case PROP_STATUS_REASON:
      g_value_set_uint (value, self->priv->status_reason);
      break;
    case PROP_SELF_CONTACT:
      g_value_set_object (value, tp_connection_get_self_contact (self));
      break;
    case PROP_SELF_HANDLE:
      g_value_set_uint (value, tp_connection_get_self_handle (self));
      break;
    case PROP_CAPABILITIES:
      g_value_set_object (value, self->priv->capabilities);
      break;
    case PROP_BALANCE:
      g_value_set_int (value, self->priv->balance);
      break;
    case PROP_BALANCE_SCALE:
      g_value_set_uint (value, self->priv->balance_scale);
      break;
    case PROP_BALANCE_CURRENCY:
      g_value_set_string (value, self->priv->balance_currency);
      break;
    case PROP_BALANCE_URI:
      g_value_set_string (value, self->priv->balance_uri);
      break;
    case PROP_CONTACT_LIST_STATE:
      g_value_set_uint (value, self->priv->contact_list_state);
      break;
    case PROP_CONTACT_LIST_PERSISTS:
      g_value_set_boolean (value, self->priv->contact_list_persists);
      break;
    case PROP_CAN_CHANGE_CONTACT_LIST:
      g_value_set_boolean (value, self->priv->can_change_contact_list);
      break;
    case PROP_REQUEST_USES_MESSAGE:
      g_value_set_boolean (value, self->priv->request_uses_message);
      break;
    case PROP_DISJOINT_GROUPS:
      g_value_set_boolean (value, self->priv->disjoint_groups);
      break;
    case PROP_GROUP_STORAGE:
      g_value_set_uint (value, self->priv->group_storage);
      break;
    case PROP_CONTACT_GROUPS:
      g_value_set_boxed (value, self->priv->contact_groups);
      break;
    case PROP_CAN_REPORT_ABUSIVE:
      g_value_set_boolean (value, tp_connection_can_report_abusive (self));
      break;
    case PROP_BLOCKED_CONTACTS:
      g_value_set_boxed (value, tp_connection_get_blocked_contacts (self));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
  G_GNUC_END_IGNORE_DEPRECATIONS
}

static void
tp_connection_unpack_balance (TpConnection *self,
    GValueArray *balance_s)
{
  gint balance = 0;
  guint scale = G_MAXUINT32;
  const char *currency = "";
  gboolean changed = FALSE;

  if (balance_s == NULL)
    goto finally;

  tp_value_array_unpack (balance_s, 3,
      &balance, &scale, &currency);

finally:

  g_object_freeze_notify ((GObject *) self);

  if (self->priv->balance != balance)
    {
      self->priv->balance = balance;
      g_object_notify ((GObject *) self, "balance");
      changed = TRUE;
    }

  if (self->priv->balance_scale != scale)
    {
      self->priv->balance_scale = scale;
      g_object_notify ((GObject *) self, "balance-scale");
      changed = TRUE;
    }

  if (tp_strdiff (self->priv->balance_currency, currency))
    {
      g_free (self->priv->balance_currency);
      self->priv->balance_currency = g_strdup (currency);
      g_object_notify ((GObject *) self, "balance-currency");
      changed = TRUE;
    }

  g_object_thaw_notify ((GObject *) self);

  if (changed)
    {
      g_signal_emit (self, signals[SIGNAL_BALANCE_CHANGED], 0,
          balance, scale, currency);
    }
}

static void
tp_connection_get_balance_cb (TpProxy *proxy,
    GHashTable *props,
    const GError *in_error,
    gpointer user_data,
    GObject *weak_obj)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result = user_data;
  GValueArray *balance = NULL;

  if (in_error != NULL)
    {
      DEBUG ("Failed to get Balance properties: %s", in_error->message);
      g_simple_async_result_set_from_error (result, in_error);
      goto finally;
    }

  balance =
    tp_asv_get_boxed (props, "AccountBalance", TP_STRUCT_TYPE_CURRENCY_AMOUNT);
  self->priv->balance_uri =
    g_strdup (tp_asv_get_string (props, "ManageCreditURI"));

  g_object_freeze_notify ((GObject *) self);

  tp_connection_unpack_balance (self, balance);

  _tp_proxy_set_feature_prepared (proxy, TP_CONNECTION_FEATURE_BALANCE,
      TRUE);

  g_object_notify ((GObject *) self, "balance-uri");

  g_object_thaw_notify ((GObject *) self);

finally:
  g_simple_async_result_complete_in_idle (result);
}

static void
tp_connection_balance_changed_cb (TpConnection *self,
    const GValueArray *balance,
    gpointer user_data,
    GObject *weak_obj)
{
  tp_connection_unpack_balance (self, (GValueArray *) balance);
}

static void
tp_connection_prepare_balance_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result;

  result = g_simple_async_result_new ((GObject *) proxy, callback, user_data,
      tp_connection_prepare_balance_async);

  g_assert (self->priv->balance_currency == NULL);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CONNECTION_INTERFACE_BALANCE,
      tp_connection_get_balance_cb, result, g_object_unref, NULL);

  tp_cli_connection_interface_balance_connect_to_balance_changed (self,
      tp_connection_balance_changed_cb,
      NULL, NULL, NULL, NULL);
}

static void
tp_connection_get_rcc_cb (TpProxy *proxy,
    const GValue *value,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result;

  if (error != NULL)
    {
      DEBUG ("Failed to get RequestableChannelClasses property, using an "
          "empty set: %s", error->message);

      /* it's NULL-safe */
      self->priv->capabilities = _tp_capabilities_new (NULL, FALSE);
      goto finally;
    }

  g_assert (self->priv->capabilities == NULL);

  if (!G_VALUE_HOLDS (value, TP_ARRAY_TYPE_REQUESTABLE_CHANNEL_CLASS_LIST))
    {
      DEBUG ("RequestableChannelClasses is not of type a(a{sv}as), using an "
          "empty set: %s", G_VALUE_TYPE_NAME (value));

      /* it's NULL-safe */
      self->priv->capabilities = _tp_capabilities_new (NULL, FALSE);
      goto finally;
    }

  DEBUG ("CAPABILITIES ready");

  self->priv->capabilities = _tp_capabilities_new (g_value_get_boxed (value),
      FALSE);

finally:
  while ((result = g_queue_pop_head (&self->priv->capabilities_queue)) != NULL)
    {
      g_simple_async_result_complete_in_idle (result);
      g_object_unref (result);
    }

  g_object_notify ((GObject *) self, "capabilities");
}

static void
_tp_connection_do_get_capabilities_async (TpConnection *self,
    GSimpleAsyncResult *result)
{
  if (self->priv->capabilities != NULL)
    {
      /* been there, done that, bored now */
      g_simple_async_result_complete_in_idle (result);
      g_object_unref (result);
    }
  else
    {
      g_queue_push_tail (&self->priv->capabilities_queue, result);
      if (g_queue_get_length (&self->priv->capabilities_queue) == 1)
        {
          DEBUG ("%s: Retrieving capabilities",
            tp_proxy_get_object_path (self));

          /* We don't check whether we actually have this interface here. The
           * quark is dbus properties quark is guaranteed to be on every
           * TpProxy and only very very old CMs won't have Requests, in case
           * someone still has such a relic we'll we'll just handle it when
           * they reply to us with an error */
          tp_cli_dbus_properties_call_get (self, -1,
            TP_IFACE_CONNECTION_INTERFACE_REQUESTS,
              "RequestableChannelClasses",
            tp_connection_get_rcc_cb, NULL, NULL, NULL);
        }
    }
}

void
_tp_connection_get_capabilities_async (TpConnection *self,
  GAsyncReadyCallback callback,
  gpointer user_data)
{
  GSimpleAsyncResult *result;

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      _tp_connection_get_capabilities_async);
  _tp_connection_do_get_capabilities_async (self, result);
}

gboolean
_tp_connection_get_capabilities_finish (TpConnection *self,
  GAsyncResult *result, GError **error)
{
  _tp_implement_finish_void (self, _tp_connection_get_capabilities_async);
}

static void
tp_connection_prepare_capabilities_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result;

  DEBUG ("%s: Preparing capabilities", tp_proxy_get_object_path (self));

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      tp_connection_prepare_capabilities_async);

  _tp_connection_do_get_capabilities_async (self, result);
}

static void
signal_connected (TpConnection *self)
{
  /* we shouldn't have gone to status CONNECTED for any reason
   * that isn't REQUESTED :-) */
  DEBUG ("%s (%p): CORE and CONNECTED ready",
    tp_proxy_get_object_path (self), self);
  self->priv->status = TP_CONNECTION_STATUS_CONNECTED;
  self->priv->status_reason = TP_CONNECTION_STATUS_REASON_REQUESTED;
  self->priv->ready = TRUE;

  _tp_proxy_set_feature_prepared ((TpProxy *) self,
      TP_CONNECTION_FEATURE_CONNECTED, TRUE);
  _tp_proxy_set_feature_prepared ((TpProxy *) self,
      TP_CONNECTION_FEATURE_CORE, TRUE);

  g_object_notify ((GObject *) self, "status");
  g_object_notify ((GObject *) self, "status-reason");
  g_object_notify ((GObject *) self, "connection-ready");
}

static void
will_announced_connected_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpConnection *self = (TpConnection *) source;
  GError *error = NULL;

  if (!_tp_proxy_will_announce_connected_finish ((TpProxy *) self, result,
        &error))
    {
      DEBUG ("_tp_connection_prepare_contact_info_async failed: %s",
          error->message);

      g_error_free (error);
    }

  if (tp_proxy_get_invalidated (self) != NULL)
    {
      DEBUG ("Connection has been invalidated; we're done");
      return;
    }

  signal_connected (self);
}

static void
tp_connection_continue_introspection (TpConnection *self)
{
  if (tp_proxy_get_invalidated (self) != NULL)
    {
      DEBUG ("Already invalidated: not becoming ready");
      return;
    }

  if (self->priv->introspect_needed == NULL)
    {
      if (!self->priv->introspecting_after_connected)
        {
          /* Introspection will restart when we become CONNECTED */
          DEBUG ("CORE ready, but not CONNECTED");
          _tp_proxy_set_feature_prepared ((TpProxy *) self,
            TP_CONNECTION_FEATURE_CORE, TRUE);
          return;
        }

      /* We'll announce CONNECTED state soon, but first give a chance to
       * prepared feature to be updated, if needed */
      _tp_proxy_will_announce_connected_async ((TpProxy *) self,
          will_announced_connected_cb, NULL);
    }
  else
    {
      TpConnectionProc next = self->priv->introspect_needed->data;

      self->priv->introspect_needed = g_list_delete_link (
          self->priv->introspect_needed,
          self->priv->introspect_needed);
      next (self);
    }
}

static void
got_contact_attribute_interfaces (TpProxy *proxy,
                                  const GValue *value,
                                  const GError *error,
                                  gpointer user_data G_GNUC_UNUSED,
                                  GObject *weak_object G_GNUC_UNUSED)
{
  TpConnection *self = TP_CONNECTION (proxy);
  GArray *arr;

  g_assert (self->priv->introspection_call != NULL);
  self->priv->introspection_call = NULL;

  if (error == NULL && G_VALUE_HOLDS (value, G_TYPE_STRV))
    {
      gchar **interfaces = g_value_get_boxed (value);
      gchar **iter;

      arr = g_array_sized_new (FALSE, FALSE, sizeof (GQuark),
          interfaces == NULL ? 0 : g_strv_length (interfaces));

      if (interfaces != NULL)
        {
          for (iter = interfaces; *iter != NULL; iter++)
            {
              if (tp_dbus_check_valid_interface_name (*iter, NULL))
                {
                  GQuark q = g_quark_from_string (*iter);

                  DEBUG ("%p: ContactAttributeInterfaces has %s", self,
                      *iter);
                  g_array_append_val (arr, q);
                }
              else
                {
                  DEBUG ("%p: ignoring invalid interface: %s", self,
                      *iter);
                }
            }
        }
    }
  else
    {
      if (error == NULL)
        DEBUG ("%p: ContactAttributeInterfaces had wrong type %s, "
            "ignoring", self, G_VALUE_TYPE_NAME (value));
      else
        DEBUG ("%p: Get(Contacts, ContactAttributeInterfaces) failed with "
            "%s %d: %s", self, g_quark_to_string (error->domain), error->code,
            error->message);

      arr = g_array_sized_new (FALSE, FALSE, sizeof (GQuark), 0);
    }

  g_assert (self->priv->contact_attribute_interfaces == NULL);
  self->priv->contact_attribute_interfaces = arr;
  self->priv->ready_enough_for_contacts = TRUE;

  tp_connection_continue_introspection (self);
}

static void
introspect_contacts (TpConnection *self)
{
  /* "This cannot change during the lifetime of the Connection." -- tp-spec */
  if (self->priv->contact_attribute_interfaces != NULL)
    {
      tp_connection_continue_introspection (self);
      return;
    }

  g_assert (self->priv->introspection_call == NULL);
  self->priv->introspection_call = tp_cli_dbus_properties_call_get (self, -1,
       TP_IFACE_CONNECTION_INTERFACE_CONTACTS, "ContactAttributeInterfaces",
       got_contact_attribute_interfaces, NULL, NULL, NULL);
}

static void
tp_connection_set_self_contact (TpConnection *self,
    TpContact *contact)
{
  if (contact != self->priv->self_contact)
    {
      TpContact *tmp = self->priv->self_contact;

      self->priv->self_contact = g_object_ref (contact);
      tp_clear_object (&tmp);
      g_object_notify ((GObject *) self, "self-contact");
      g_object_notify ((GObject *) self, "self-handle");
    }

  if (self->priv->introspecting_self_contact)
    {
      self->priv->introspecting_self_contact = FALSE;
      tp_connection_continue_introspection (self);
    }
}

static void
tp_connection_got_self_contact_cb (TpConnection *self,
    guint n_contacts,
    TpContact * const *contacts,
    guint n_failed,
    const TpHandle *failed,
    const GError *error,
    gpointer unused_data G_GNUC_UNUSED,
    GObject *unused_object G_GNUC_UNUSED)
{
  if (n_contacts != 0)
    {
      g_assert (n_contacts == 1);
      g_assert (n_failed == 0);
      g_assert (error == NULL);

      if (tp_contact_get_handle (contacts[0]) ==
          self->priv->last_known_self_handle)
        {
          tp_connection_set_self_contact (self, contacts[0]);
        }
      else
        {
          DEBUG ("SelfHandle is now %u, ignoring contact object for %u",
              self->priv->last_known_self_handle,
              tp_contact_get_handle (contacts[0]));
        }
    }
  else if (error != NULL)
    {
      /* Unrecoverable error: we were probably invalidated, but in case
       * we weren't... */
      DEBUG ("Failed to hold the handle from GetSelfHandle(): %s",
          error->message);
      tp_proxy_invalidate ((TpProxy *) self, error);
    }
  else if (n_failed == 1 && failed[0] != self->priv->last_known_self_handle)
    {
      /* Since we tried to make the TpContact, our self-handle has changed,
       * so it doesn't matter that we couldn't make a TpContact for the old
       * one - carry on and make a TpContact for the new one instead. */
      DEBUG ("Failed to hold handle %u from GetSelfHandle(), but it's "
          "changed to %u anyway, so never mind", failed[0],
          self->priv->last_known_self_handle);
    }
  else
    {
      GError e = { TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
          "The handle from GetSelfHandle() was considered invalid" };

      DEBUG ("%s", e.message);
      tp_proxy_invalidate ((TpProxy *) self, &e);
    }
}

static void
get_self_contact (TpConnection *self)
{
  TpSimpleClientFactory *factory;
  GArray *features;

  factory = tp_proxy_get_factory (self);
  features = tp_simple_client_factory_dup_contact_features (factory, self);

  /* FIXME: We should use tp_simple_client_factory_ensure_contact(), but that would
   * require immortal-handles and spec change to give the self identifier. */
  /* This relies on the special case in tp_connection_get_contacts_by_handle()
   * which makes it start working slightly early. */
   G_GNUC_BEGIN_IGNORE_DEPRECATIONS
   tp_connection_get_contacts_by_handle (self,
       1, &self->priv->last_known_self_handle,
      features->len, (TpContactFeature *) features->data,
      tp_connection_got_self_contact_cb, NULL, NULL, NULL);
   G_GNUC_END_IGNORE_DEPRECATIONS

  g_array_unref (features);
}

static void
introspect_self_contact (TpConnection *self)
{
  self->priv->introspecting_self_contact = TRUE;
  get_self_contact (self);
}

static void
got_self_handle (TpConnection *self,
                 guint self_handle,
                 const GError *error,
                 gpointer user_data G_GNUC_UNUSED,
                 GObject *user_object G_GNUC_UNUSED)
{
  g_assert (self->priv->introspection_call != NULL);
  self->priv->introspection_call = NULL;

  if (error != NULL)
    {
      DEBUG ("%p: GetSelfHandle() failed: %s", self, error->message);
      tp_proxy_invalidate ((TpProxy *) self, error);
      return;
    }

  if (self_handle == 0)
    {
      GError e = { TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
          "GetSelfHandle() returned 0" };
      DEBUG ("%s", e.message);
      tp_proxy_invalidate ((TpProxy *) self, &e);
      return;
    }

  self->priv->last_known_self_handle = self_handle;
  self->priv->introspect_needed = g_list_append (self->priv->introspect_needed,
    introspect_self_contact);
  tp_connection_continue_introspection (self);
}

static void
on_self_handle_changed (TpConnection *self,
                        guint self_handle,
                        gpointer user_data G_GNUC_UNUSED,
                        GObject *user_object G_GNUC_UNUSED)
{
  if (self_handle == 0)
    {
      DEBUG ("Ignoring alleged change of self-handle to %u", self_handle);
      return;
    }

  if (self->priv->last_known_self_handle == 0)
    {
      /* We're going to call GetAll(Connection) anyway, or if the CM
       * is sufficiently deficient, GetSelfHandle(). */
      DEBUG ("Ignoring early self-handle change to %u, we'll pick it up later",
          self_handle);
      return;
    }

  DEBUG ("SelfHandleChanged to %u, I wonder what that means?", self_handle);
  self->priv->last_known_self_handle = self_handle;
  get_self_contact (self);
}

static void
introspect_self_handle (TpConnection *self)
{
  if (!self->priv->introspecting_after_connected)
    {
      tp_connection_continue_introspection (self);
      return;
    }

  g_assert (self->priv->introspection_call == NULL);
  self->priv->introspection_call = tp_cli_connection_call_get_self_handle (
      self, -1, got_self_handle, NULL, NULL, NULL);
}

/* Appending callbacks to self->priv->introspect_needed relies on this */
G_STATIC_ASSERT (sizeof (TpConnectionProc) <= sizeof (gpointer));

static void
tp_connection_add_interfaces_from_introspection (TpConnection *self,
                                                 const gchar **interfaces)
{
  TpProxy *proxy = (TpProxy *) self;

  tp_proxy_add_interfaces (proxy, interfaces);

  if (tp_proxy_has_interface_by_id (proxy,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS))
    {
      self->priv->introspect_needed = g_list_append (
          self->priv->introspect_needed, introspect_contacts);
    }
  else
    {
      self->priv->ready_enough_for_contacts = TRUE;
    }
}

static void
tp_connection_got_interfaces_cb (TpConnection *self,
                                 const gchar **interfaces,
                                 const GError *error,
                                 gpointer user_data,
                                 GObject *user_object)
{
  g_assert (self->priv->introspection_call != NULL);
  self->priv->introspection_call = NULL;

  if (error != NULL)
    {
      DEBUG ("%p: GetInterfaces() failed, assuming no interfaces: %s",
          self, error->message);
      interfaces = NULL;
    }

  DEBUG ("%p: Introspected interfaces", self);

  if (tp_proxy_get_invalidated (self) != NULL)
    {
      DEBUG ("%p: already invalidated, not trying to become ready: %s",
          self, tp_proxy_get_invalidated (self)->message);
      return;
    }

  g_assert (self->priv->introspect_needed == NULL);

  if (interfaces != NULL)
    tp_connection_add_interfaces_from_introspection (self, interfaces);

  self->priv->introspect_needed = g_list_append (self->priv->introspect_needed,
    introspect_self_handle);

  /* FIXME: give subclasses a chance to influence the definition of "ready"
   * now that we have our interfaces? */

  tp_connection_continue_introspection (self);
}

static void
_tp_connection_got_properties (TpProxy *proxy,
    GHashTable *asv,
    const GError *error,
    gpointer unused G_GNUC_UNUSED,
    GObject *unused_object G_GNUC_UNUSED);

static void
tp_connection_status_changed (TpConnection *self,
                              guint status,
                              guint reason)
{
  DEBUG ("%p: %d -> %d because %d", self, self->priv->status, status, reason);

  if (status == TP_CONNECTION_STATUS_CONNECTED)
    {
      if (self->priv->introspection_call != NULL &&
          !self->priv->introspecting_after_connected)
        {
          /* We thought we knew what was going on, but now the connection has
           * gone to CONNECTED and all bets are off. Start again! */
          DEBUG ("Cancelling pre-CONNECTED introspection and starting again");
          tp_proxy_pending_call_cancel (self->priv->introspection_call);
          self->priv->introspection_call = NULL;
          g_list_free (self->priv->introspect_needed);
          self->priv->introspect_needed = NULL;
        }

      self->priv->introspecting_after_connected = TRUE;

      /* we defer the perceived change to CONNECTED until ready */
      if (self->priv->introspection_call == NULL)
        {
          self->priv->introspection_call =
            tp_cli_dbus_properties_call_get_all (self, -1,
              TP_IFACE_CONNECTION, _tp_connection_got_properties, NULL, NULL, NULL);
        }
    }
  else
    {
      self->priv->status = status;
      self->priv->status_reason = reason;
      g_object_notify ((GObject *) self, "status");
      g_object_notify ((GObject *) self, "status-reason");
    }
}

static void
tp_connection_connection_error_cb (TpConnection *self,
                                   const gchar *error_name,
                                   GHashTable *details,
                                   gpointer user_data,
                                   GObject *weak_object)
{
  g_free (self->priv->connection_error);
  self->priv->connection_error = g_strdup (error_name);

  if (self->priv->connection_error_details != NULL)
    g_hash_table_unref (self->priv->connection_error_details);

  self->priv->connection_error_details = g_boxed_copy (
      TP_HASH_TYPE_STRING_VARIANT_MAP, details);
}

void
_tp_connection_status_reason_to_gerror (TpConnectionStatusReason reason,
    TpConnectionStatus prev_status,
    const gchar **ret_str,
    GError **error)
{
  TpError code;
  const gchar *message;

  switch (reason)
    {
    case TP_CONNECTION_STATUS_REASON_NONE_SPECIFIED:
      code = TP_ERROR_DISCONNECTED;
      message = "Disconnected for unspecified reason";
      break;

    case TP_CONNECTION_STATUS_REASON_REQUESTED:
      code = TP_ERROR_CANCELLED;
      message = "User requested disconnection";
      break;

    case TP_CONNECTION_STATUS_REASON_NETWORK_ERROR:
      code = TP_ERROR_NETWORK_ERROR;
      message = "Network error";
      break;

    case TP_CONNECTION_STATUS_REASON_ENCRYPTION_ERROR:
      code = TP_ERROR_ENCRYPTION_ERROR;
      message = "Encryption error";
      break;

    case TP_CONNECTION_STATUS_REASON_NAME_IN_USE:
      if (prev_status == TP_CONNECTION_STATUS_CONNECTED)
        {
          code = TP_ERROR_CONNECTION_REPLACED;
          message = "Connection replaced";
        }
      else
        {
          /* If the connection was with register=TRUE, we should ideally use
           * REGISTRATION_EXISTS; but we can't actually tell that from here,
           * so we'll have to rely on CMs supporting in-band registration
           * (Gabble) to emit ConnectionError */
          code = TP_ERROR_ALREADY_CONNECTED;
          message = "Already connected (or if registering, registration "
            "already exists)";
        }
      break;

    case TP_CONNECTION_STATUS_REASON_CERT_NOT_PROVIDED:
      code = TP_ERROR_CERT_NOT_PROVIDED;
      message = "Server certificate not provided";
      break;

    case TP_CONNECTION_STATUS_REASON_CERT_UNTRUSTED:
      code = TP_ERROR_CERT_UNTRUSTED;
      message = "Server certificate CA not trusted";
      break;

    case TP_CONNECTION_STATUS_REASON_CERT_EXPIRED:
      code = TP_ERROR_CERT_EXPIRED;
      message = "Server certificate expired";
      break;

    case TP_CONNECTION_STATUS_REASON_CERT_NOT_ACTIVATED:
      code = TP_ERROR_CERT_NOT_ACTIVATED;
      message = "Server certificate not valid yet";
      break;

    case TP_CONNECTION_STATUS_REASON_CERT_HOSTNAME_MISMATCH:
      code = TP_ERROR_CERT_HOSTNAME_MISMATCH;
      message = "Server certificate has wrong hostname";
      break;

    case TP_CONNECTION_STATUS_REASON_CERT_FINGERPRINT_MISMATCH:
      code = TP_ERROR_CERT_FINGERPRINT_MISMATCH;
      message = "Server certificate fingerprint mismatch";
      break;

    case TP_CONNECTION_STATUS_REASON_CERT_SELF_SIGNED:
      code = TP_ERROR_CERT_SELF_SIGNED;
      message = "Server certificate is self-signed";
      break;

    case TP_CONNECTION_STATUS_REASON_CERT_OTHER_ERROR:
      code = TP_ERROR_CERT_INVALID;
      message = "Unspecified server certificate error";
      break;

    default:
      g_set_error (error, TP_ERRORS_DISCONNECTED, reason,
          "Unknown disconnection reason");

      if (ret_str != NULL)
        *ret_str = TP_ERROR_STR_DISCONNECTED;

      return;
    }

  g_set_error (error, TP_ERROR, code, "%s", message);

  if (ret_str != NULL)
    *ret_str = tp_error_get_dbus_name (code);
}

static void
tp_connection_status_changed_cb (TpConnection *self,
                                 guint status,
                                 guint reason,
                                 gpointer user_data,
                                 GObject *weak_object)
{
  TpConnectionStatus prev_status = self->priv->status;

  /* The status is initially attempted to be discovered starting in the
   * constructor. If we don't have the reply for that call yet, ignore this
   * signal StatusChanged in order to run the interface introspection only one
   * time. We will get the initial introspection reply later anyway. */
  if (self->priv->status != TP_UNKNOWN_CONNECTION_STATUS)
    {
      tp_connection_status_changed (self, status, reason);
    }

  /* we only want to run this in response to a StatusChanged signal,
   * not if the initial status is DISCONNECTED */

  if (status == TP_CONNECTION_STATUS_DISCONNECTED)
    {
      GError *error = NULL;

      if (self->priv->connection_error == NULL)
        {
          _tp_connection_status_reason_to_gerror (reason, prev_status,
              NULL, &error);
        }
      else
        {
          g_assert (self->priv->connection_error_details != NULL);
          tp_proxy_dbus_error_to_gerror (self, self->priv->connection_error,
              tp_asv_get_string (self->priv->connection_error_details,
                "debug-message"), &error);

          /* ... but if we don't know anything about that D-Bus error
           * name, we can still be more helpful by deriving an error code from
           * TpConnectionStatusReason */
          if (g_error_matches (error, TP_DBUS_ERRORS,
                TP_DBUS_ERROR_UNKNOWN_REMOTE_ERROR))
            {
              GError *from_csr = NULL;

              _tp_connection_status_reason_to_gerror (reason, prev_status,
                  NULL, &from_csr);
              error->domain = from_csr->domain;
              error->code = from_csr->code;
              g_error_free (from_csr);
            }
        }

      tp_proxy_invalidate ((TpProxy *) self, error);
      g_error_free (error);
    }
}

static void
tp_connection_got_status_cb (TpConnection *self,
                             guint status,
                             const GError *error,
                             gpointer unused,
                             GObject *user_object)
{
  DEBUG ("%p", self);

  g_assert (self->priv->introspection_call != NULL);
  self->priv->introspection_call = NULL;

  if (error == NULL)
    {
      DEBUG ("%p: Initial status is %d", self, status);
      tp_connection_status_changed (self, status,
          TP_CONNECTION_STATUS_REASON_NONE_SPECIFIED);

      /* try introspecting before CONNECTED - it might work... */
      if (status != TP_CONNECTION_STATUS_CONNECTED &&
          self->priv->introspection_call == NULL)
        {
          self->priv->introspection_call =
            tp_cli_connection_call_get_interfaces (self, -1,
                tp_connection_got_interfaces_cb, NULL, NULL, NULL);
        }
    }
  else
    {
      DEBUG ("%p: GetStatus() failed with %s %d \"%s\"",
          self, g_quark_to_string (error->domain), error->code,
          error->message);
    }
}

static void
tp_connection_invalidated (TpConnection *self)
{
  if (self->priv->introspection_call != NULL)
    {
      DEBUG ("Cancelling introspection");
      tp_proxy_pending_call_cancel (self->priv->introspection_call);
      self->priv->introspection_call = NULL;
    }

  /* Drop the ref we have on all roster contacts, this is to break the refcycle
   * we have between TpConnection and TpContact, otherwise self would never
   * run dispose.
   * Note that invalidated is also called from dispose, so self->priv->roster
   * could already be NULL.
   *
   * FIXME: When we decide to break tp-glib API/guarantees, we should stop
   * TpContact taking a strong ref on its TpConnection and force user to keep
   * a ref on the TpConnection to use its TpContact, this would avoid the
   * refcycle completely. */
  if (self->priv->roster != NULL)
    g_hash_table_remove_all (self->priv->roster);
  g_clear_object (&self->priv->self_contact);
  tp_clear_pointer (&self->priv->blocked_contacts, g_ptr_array_unref);
}

static gboolean
_tp_connection_extract_properties (TpConnection *self,
    GHashTable *asv,
    guint32 *status,
    guint32 *self_handle,
    const gchar ***interfaces)
{
  gboolean sufficient;

  /* has_immortal_handles is a bitfield, so we can't pass a pointer to it */
  if (tp_asv_get_boolean (asv, "HasImmortalHandles", NULL))
    self->priv->has_immortal_handles = TRUE;

  *status = tp_asv_get_uint32 (asv, "Status", &sufficient);

  if (!sufficient
      || *status > TP_CONNECTION_STATUS_DISCONNECTED)
    return FALSE;

  *interfaces = (const gchar **) tp_asv_get_strv (asv, "Interfaces");

  if (*interfaces == NULL)
    return FALSE;

  if (*status == TP_CONNECTION_STATUS_CONNECTED)
    {
      *self_handle = tp_asv_get_uint32 (asv, "SelfHandle", &sufficient);

      if (!sufficient || *self_handle == 0)
        return FALSE;
    }
  else
    {
      *self_handle = 0;
    }

  return TRUE;
}

static void
_tp_connection_got_properties (TpProxy *proxy,
    GHashTable *asv,
    const GError *error,
    gpointer unused G_GNUC_UNUSED,
    GObject *unused_object G_GNUC_UNUSED)
{
  TpConnection *self = TP_CONNECTION (proxy);
  guint32 status;
  guint32 self_handle;
  const gchar **interfaces;

  if (tp_proxy_get_invalidated (self) != NULL)
    {
      DEBUG ("%p: already invalidated, not trying to become ready: %s",
          self, tp_proxy_get_invalidated (self)->message);
      return;
    }

  if (self->priv->introspection_call)
    self->priv->introspection_call = NULL;

  if (error == NULL &&
      _tp_connection_extract_properties (
        self,
        asv,
        &status,
        &self_handle,
        &interfaces))
    {
      tp_connection_add_interfaces_from_introspection (self, interfaces);

      if (status == TP_CONNECTION_STATUS_CONNECTED)
        {
          self->priv->introspecting_after_connected = TRUE;
          self->priv->last_known_self_handle = self_handle;

          self->priv->introspect_needed = g_list_append (
              self->priv->introspect_needed, introspect_self_contact);
        }
      else
        {
          tp_connection_status_changed (self, status,
              TP_CONNECTION_STATUS_REASON_NONE_SPECIFIED);
        }

      tp_connection_continue_introspection (self);
      return;
    }
  else if (error != NULL)
    {
      DEBUG ("GetAll failed: %s", error->message);
    }


  DEBUG ("Could not extract all required properties from GetAll return, "
         "will use 0.18 API instead");

  if (self->priv->introspection_call == NULL)
    {
      if (self->priv->status == TP_UNKNOWN_CONNECTION_STATUS &&
          !self->priv->introspecting_after_connected)
        {
          /* get my initial status */
          DEBUG ("Calling GetStatus");
          self->priv->introspection_call =
            tp_cli_connection_call_get_status (self, -1,
              tp_connection_got_status_cb, NULL, NULL, NULL);
        }
      else
        {
          self->priv->introspection_call =
            tp_cli_connection_call_get_interfaces (self, -1,
                tp_connection_got_interfaces_cb, NULL, NULL, NULL);
        }
    }
}

static gboolean _tp_connection_parse (const gchar *path_or_bus_name,
    char delimiter,
    gchar **protocol,
    gchar **cm_name);

static void
tp_connection_constructed (GObject *object)
{
  GObjectClass *object_class = (GObjectClass *) tp_connection_parent_class;
  TpConnection *self = TP_CONNECTION (object);
  const gchar *object_path;

  if (object_class->constructed != NULL)
    object_class->constructed (object);

  DEBUG ("%s (%p) constructed", tp_proxy_get_object_path (object), object);

  _tp_proxy_ensure_factory (self, NULL);

  /* Connect to my own StatusChanged signal.
   * The connection hasn't had a chance to become invalid yet, so we can
   * assume that this signal connection will work */
  tp_cli_connection_connect_to_status_changed (self,
      tp_connection_status_changed_cb, NULL, NULL, NULL, NULL);
  tp_cli_connection_connect_to_connection_error (self,
      tp_connection_connection_error_cb, NULL, NULL, NULL, NULL);

  /* We need to connect to SelfHandleChanged early, too, so that we're
   * already connected before we GetAll */
  tp_cli_connection_connect_to_self_handle_changed (self,
      on_self_handle_changed, NULL, NULL, NULL, NULL);

  object_path = tp_proxy_get_object_path (TP_PROXY (self));
  g_assert (_tp_connection_parse (object_path, '/',
      &(self->priv->proto_name), &(self->priv->cm_name)));

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CONNECTION, _tp_connection_got_properties, NULL, NULL, NULL);

  /* Give a chance to TpAccount to know about invalidated connection before we
   * unref all roster contacts. This is to let applications properly remove all
   * contacts at once instead of getting weak notify on each. */
  g_signal_connect_after (self, "invalidated",
      G_CALLBACK (tp_connection_invalidated), NULL);
}

static void
tp_connection_init (TpConnection *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_CONNECTION,
      TpConnectionPrivate);

  self->priv->status = TP_UNKNOWN_CONNECTION_STATUS;
  self->priv->status_reason = TP_CONNECTION_STATUS_REASON_NONE_SPECIFIED;
  self->priv->contacts = g_hash_table_new (g_direct_hash, g_direct_equal);
  self->priv->introspection_call = NULL;
  self->priv->interests = tp_intset_new ();
  self->priv->contact_groups = g_ptr_array_new_with_free_func (g_free);
  g_ptr_array_add (self->priv->contact_groups, NULL);
  self->priv->roster = g_hash_table_new_full (g_direct_hash, g_direct_equal,
      NULL, g_object_unref);
  self->priv->contacts_changed_queue = g_queue_new ();

  g_queue_init (&self->priv->capabilities_queue);

  self->priv->blocked_contacts = g_ptr_array_new_with_free_func (
      g_object_unref);

  self->priv->blocked_changed_queue = g_queue_new ();
}

static void
tp_connection_finalize (GObject *object)
{
  TpConnection *self = TP_CONNECTION (object);

  DEBUG ("%p", self);

  tp_clear_pointer (&self->priv->cm_name, g_free);
  tp_clear_pointer (&self->priv->proto_name, g_free);

  /* not true unless we were finalized before we were ready */
  if (self->priv->introspect_needed != NULL)
    {
      g_list_free (self->priv->introspect_needed);
      self->priv->introspect_needed = NULL;
    }

  if (self->priv->contact_attribute_interfaces != NULL)
    {
      g_array_unref (self->priv->contact_attribute_interfaces);
      self->priv->contact_attribute_interfaces = NULL;
    }

  g_free (self->priv->connection_error);
  self->priv->connection_error = NULL;

  if (self->priv->connection_error_details != NULL)
    {
      g_hash_table_unref (self->priv->connection_error_details);
      self->priv->connection_error_details = NULL;
    }

  if (self->priv->avatar_request_queue != NULL)
    {
      g_array_unref (self->priv->avatar_request_queue);
      self->priv->avatar_request_queue = NULL;
    }

  if (self->priv->avatar_request_idle_id != 0)
    {
      g_source_remove (self->priv->avatar_request_idle_id);
      self->priv->avatar_request_idle_id = 0;
    }

  tp_contact_info_spec_list_free (self->priv->contact_info_supported_fields);
  self->priv->contact_info_supported_fields = NULL;

  tp_clear_pointer (&self->priv->balance_currency, g_free);
  tp_clear_pointer (&self->priv->balance_uri, g_free);
  tp_clear_pointer (&self->priv->cm_name, g_free);
  tp_clear_pointer (&self->priv->proto_name, g_free);

  ((GObjectClass *) tp_connection_parent_class)->finalize (object);
}

static void
contact_notify_disposed (gpointer k G_GNUC_UNUSED,
    gpointer v,
    gpointer d G_GNUC_UNUSED)
{
  _tp_contact_connection_disposed (v);
}


static void
tp_connection_dispose (GObject *object)
{
  TpConnection *self = TP_CONNECTION (object);

  DEBUG ("%p", object);

  if (self->priv->account != NULL)
    {
      g_object_remove_weak_pointer ((GObject *) self->priv->account,
          (gpointer) &self->priv->account);
      self->priv->account = NULL;
    }

  tp_clear_pointer (&self->priv->contact_groups, g_ptr_array_unref);
  tp_clear_pointer (&self->priv->roster, g_hash_table_unref);
  tp_clear_pointer (&self->priv->contacts_changed_queue,
      _tp_connection_contacts_changed_queue_free);
  tp_clear_pointer (&self->priv->blocked_changed_queue,
      _tp_connection_blocked_changed_queue_free);

  if (self->priv->contacts != NULL)
    {
      g_hash_table_foreach (self->priv->contacts, contact_notify_disposed,
          NULL);
      tp_clear_pointer (&self->priv->contacts, g_hash_table_unref);
    }

  tp_clear_object (&self->priv->capabilities);
  tp_clear_pointer (&self->priv->avatar_requirements,
      tp_avatar_requirements_destroy);

  if (self->priv->interests != NULL)
    {
      guint size = tp_intset_size (self->priv->interests);

      /* Before freeing the set of tokens in which we declared an
       * interest, cancel those interests. We'll still get the signals
       * if there's another interested TpConnection in this process,
       * because the CM uses distributed refcounting. */
      if (size > 0)
        {
          TpIntsetFastIter iter;
          GPtrArray *strings;
          guint element;

          strings = g_ptr_array_sized_new (size + 1);

          tp_intset_fast_iter_init (&iter, self->priv->interests);

          while (tp_intset_fast_iter_next (&iter, &element))
            g_ptr_array_add (strings,
                (gchar *) g_quark_to_string (element));

          g_ptr_array_add (strings, NULL);

          /* no callback - if the CM replies, we'll ignore it anyway */
          tp_cli_connection_call_remove_client_interest (self, -1,
              (const gchar **) strings->pdata, NULL, NULL, NULL, NULL);
          g_ptr_array_unref (strings);
        }

      tp_intset_destroy (self->priv->interests);
      self->priv->interests = NULL;
    }

  tp_clear_pointer (&self->priv->blocked_contacts, g_ptr_array_unref);
  g_clear_object (&self->priv->self_contact);

  ((GObjectClass *) tp_connection_parent_class)->dispose (object);
}

enum {
    FEAT_CORE,
    FEAT_CONNECTED,
    FEAT_CAPABILITIES,
    FEAT_AVATAR_REQUIREMENTS,
    FEAT_CONTACT_INFO,
    FEAT_BALANCE,
    FEAT_CONTACT_LIST,
    FEAT_CONTACT_LIST_PROPS,
    FEAT_CONTACT_GROUPS,
    FEAT_CONTACT_BLOCKING,
    FEAT_ALIASING,
    N_FEAT
};

static const TpProxyFeature *
tp_connection_list_features (TpProxyClass *cls G_GNUC_UNUSED)
{
  static TpProxyFeature features[N_FEAT + 1] = { { 0 } };
  static GQuark need_requests[2] = {0, 0};
  static GQuark need_avatars[2] = {0, 0};
  static GQuark need_contact_info[2] = {0, 0};
  static GQuark need_balance[2] = {0, 0};
  static GQuark need_contact_list[3] = {0, 0, 0};
  static GQuark need_contact_groups[2] = {0, 0};
  static GQuark need_contact_blocking[2] = {0, 0};
  static GQuark depends_contact_list[2] = {0, 0};
  static GQuark need_aliasing[2] = {0, 0};

  if (G_LIKELY (features[0].name != 0))
    return features;

  features[FEAT_CORE].name = TP_CONNECTION_FEATURE_CORE;
  features[FEAT_CORE].core = TRUE;

  features[FEAT_CONNECTED].name = TP_CONNECTION_FEATURE_CONNECTED;

  features[FEAT_CAPABILITIES].name = TP_CONNECTION_FEATURE_CAPABILITIES;
  features[FEAT_CAPABILITIES].prepare_async =
      tp_connection_prepare_capabilities_async;
  need_requests[0] = TP_IFACE_QUARK_CONNECTION_INTERFACE_REQUESTS;
  features[FEAT_CAPABILITIES].interfaces_needed = need_requests;

  features[FEAT_AVATAR_REQUIREMENTS].name = TP_CONNECTION_FEATURE_AVATAR_REQUIREMENTS;
  features[FEAT_AVATAR_REQUIREMENTS].prepare_async =
    _tp_connection_prepare_avatar_requirements_async;
  need_avatars[0] = TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS;
  features[FEAT_AVATAR_REQUIREMENTS].interfaces_needed = need_avatars;

  features[FEAT_CONTACT_INFO].name = TP_CONNECTION_FEATURE_CONTACT_INFO;
  features[FEAT_CONTACT_INFO].prepare_async =
    _tp_connection_prepare_contact_info_async;
  need_contact_info[0] = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO;
  features[FEAT_CONTACT_INFO].interfaces_needed = need_contact_info;

  features[FEAT_BALANCE].name = TP_CONNECTION_FEATURE_BALANCE;
  features[FEAT_BALANCE].prepare_async = tp_connection_prepare_balance_async;
  need_balance[0] = TP_IFACE_QUARK_CONNECTION_INTERFACE_BALANCE;
  features[FEAT_BALANCE].interfaces_needed = need_balance;

  features[FEAT_CONTACT_LIST].name = TP_CONNECTION_FEATURE_CONTACT_LIST;
  features[FEAT_CONTACT_LIST].prepare_async = _tp_connection_prepare_contact_list_async;
  need_contact_list[0] = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST;
  need_contact_list[1] = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS;
  features[FEAT_CONTACT_LIST].interfaces_needed = need_contact_list;
  depends_contact_list[0] = TP_CONNECTION_FEATURE_CONTACT_LIST_PROPERTIES;
  features[FEAT_CONTACT_LIST].depends_on = depends_contact_list;

  features[FEAT_CONTACT_LIST_PROPS].name = TP_CONNECTION_FEATURE_CONTACT_LIST_PROPERTIES;
  features[FEAT_CONTACT_LIST_PROPS].prepare_async = _tp_connection_prepare_contact_list_props_async;
  features[FEAT_CONTACT_LIST_PROPS].interfaces_needed = need_contact_list;

  features[FEAT_CONTACT_GROUPS].name = TP_CONNECTION_FEATURE_CONTACT_GROUPS;
  features[FEAT_CONTACT_GROUPS].prepare_async = _tp_connection_prepare_contact_groups_async;
  need_contact_groups[0] = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS;
  features[FEAT_CONTACT_GROUPS].interfaces_needed = need_contact_groups;

  features[FEAT_CONTACT_BLOCKING].name = TP_CONNECTION_FEATURE_CONTACT_BLOCKING;
  features[FEAT_CONTACT_BLOCKING].prepare_async = _tp_connection_prepare_contact_blocking_async;
  need_contact_blocking[0] = TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_BLOCKING;
  features[FEAT_CONTACT_BLOCKING].interfaces_needed = need_contact_blocking;

  features[FEAT_ALIASING].name = TP_CONNECTION_FEATURE_ALIASING;
  features[FEAT_ALIASING].prepare_async = _tp_connection_prepare_aliasing_async;
  need_aliasing[0] = TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING;
  features[FEAT_ALIASING].interfaces_needed = need_aliasing;

  /* assert that the terminator at the end is there */
  g_assert (features[N_FEAT].name == 0);

  return features;
}

static void
tp_connection_class_init (TpConnectionClass *klass)
{
  GParamSpec *param_spec;
  TpProxyClass *proxy_class = (TpProxyClass *) klass;
  GObjectClass *object_class = (GObjectClass *) klass;

  tp_connection_init_known_interfaces ();

  g_type_class_add_private (klass, sizeof (TpConnectionPrivate));

  object_class->constructed = tp_connection_constructed;
  object_class->get_property = tp_connection_get_property;
  object_class->dispose = tp_connection_dispose;
  object_class->finalize = tp_connection_finalize;

  proxy_class->interface = TP_IFACE_QUARK_CONNECTION;
  /* If you change this, you must also change TpChannel to stop asserting
   * that its connection has a unique name */
  proxy_class->must_have_unique_name = TRUE;
  proxy_class->list_features = tp_connection_list_features;

  /**
   * TpConnection:status:
   *
   * This connection's status, or %TP_UNKNOWN_CONNECTION_STATUS if we don't
   * know yet.
   *
   * To wait for a valid status (and other properties), call
   * tp_proxy_prepare_async() with the feature %TP_CONNECTION_FEATURE_CORE.
   *
   * Since version 0.11.3, the change to status
   * %TP_CONNECTION_STATUS_CONNECTED is delayed slightly, until introspection
   * of the connection has finished.
   */
  param_spec = g_param_spec_uint ("status", "Status",
      "The status of this connection", 0, G_MAXUINT32,
      TP_UNKNOWN_CONNECTION_STATUS,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_STATUS,
      param_spec);

  /**
   * TpConnection:connection-manager-name:
   *
   * This connection's connection manager name.
   *
   * Since: 0.13.16
   * Deprecated: Use #TpConnection:cm-name instead.
   */
  g_object_class_install_property (object_class, PROP_CONNECTION_MANAGER_NAME,
      g_param_spec_string ("connection-manager-name",
          "Connection manager name",
          "The connection's connection manager name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpConnection:cm-name:
   *
   * This connection's connection manager name.
   *
   * Since: 0.19.3
   */
  g_object_class_install_property (object_class, PROP_CM_NAME,
      g_param_spec_string ("cm-name",
          "Connection manager name",
          "The connection's connection manager name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpConnection:protocol-name:
   *
   * The connection's machine-readable protocol name, such as "jabber",
   * "msn" or "local-xmpp". Recommended names for most protocols can be
   * found in the Telepathy D-Bus Interface Specification.
   *
   * Since: 0.13.16
   *
   */
  g_object_class_install_property (object_class, PROP_PROTOCOL_NAME,
      g_param_spec_string ("protocol-name",
          "Protocol name",
          "The connection's protocol name",
          NULL,
          G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  /**
   * TpConnection:self-handle:
   *
   * The %TP_HANDLE_TYPE_CONTACT handle of the local user on this connection,
   * or 0 if we don't know yet or if the connection has become invalid.
   *
   * This may change if the local user's unique identifier changes (for
   * instance by using /nick on IRC), in which case #GObject::notify will be
   * emitted.
   *
   * To wait for a valid self-handle (and other properties), call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONNECTED.
   *
   * Deprecated: Use #TpConnection:self-contact instead.
   */
  param_spec = g_param_spec_uint ("self-handle", "Self handle",
      "The local user's Contact handle on this connection", 0, G_MAXUINT32,
      0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_SELF_HANDLE,
      param_spec);

  /**
   * TpConnection:self-contact:
   *
   * A #TpContact representing the local user on this connection,
   * or %NULL if not yet available.
   *
   * If the local user's unique identifier changes (for instance by using
   * /nick on IRC), this property will change to a different #TpContact object
   * representing the new identifier, and #GObject::notify will be emitted.
   *
   * The #TpContact object is guaranteed to have all of the features previously
   * passed to tp_simple_client_factory_add_contact_features() prepared.
   *
   * To wait for a non-%NULL self-contact (and other properties), call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONNECTED.
   *
   * Since: 0.13.9
   */
  param_spec = g_param_spec_object ("self-contact", "Self contact",
      "The local user's Contact object on this connection", TP_TYPE_CONTACT,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_SELF_CONTACT,
      param_spec);

  /**
   * TpConnection:status-reason:
   *
   * To wait for a valid status (and other properties), call
   * tp_proxy_prepare_async() with the feature %TP_CONNECTION_FEATURE_CORE.
   *
   * The reason why #TpConnection:status changed to its current value,
   * or TP_CONNECTION_STATUS_REASON_NONE_SPECIFIED if unknown.
   * know yet.
   */
  param_spec = g_param_spec_uint ("status-reason", "Last status change reason",
      "The reason why #TpConnection:status changed to its current value",
      0, G_MAXUINT32, TP_CONNECTION_STATUS_REASON_NONE_SPECIFIED,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_STATUS_REASON,
      param_spec);

  /**
   * TpConnection:connection-ready:
   *
   * Initially %FALSE; changes to %TRUE when the connection has gone to
   * CONNECTED status, introspection has finished and it's ready for use.
   *
   * By the time this property becomes %TRUE, any extra interfaces will
   * have been set up and the #TpProxy:interfaces property will have been
   * populated.
   *
   * This is similar to %TP_CONNECTION_FEATURE_CONNECTED, except that once
   * it has changed to %TRUE, it remains %TRUE even if the connection has
   * been invalidated.
   *
   * Deprecated: 0.17.6: use tp_proxy_is_prepared() with
   *  %TP_CHANNEL_FEATURE_CONNECTED for checks, or tp_proxy_prepare_async() for
   *  notification
   */
  param_spec = g_param_spec_boolean ("connection-ready", "Connection ready?",
      "Initially FALSE; changes to TRUE when introspection finishes", FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS | G_PARAM_DEPRECATED);
  g_object_class_install_property (object_class, PROP_CONNECTION_READY,
      param_spec);

 /**
   * TpConnection:capabilities:
   *
   * The %TpCapabilities object representing the capabilities of this
   * connection, or NULL if we don't know yet.
   *
   * To wait for valid capability information, call tp_proxy_prepare_async()
   * with the feature %TP_CONNECTION_FEATURE_CAPABILITIES.
   */
  param_spec = g_param_spec_object ("capabilities", "Capabilities",
      "A TpCapabilities object representing the capabilities of the connection",
      TP_TYPE_CAPABILITIES,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CAPABILITIES,
      param_spec);

  /**
   * TpConnection:balance:
   *
   * The Amount field of the Balance.AccountBalance property.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature %TP_CONNECTION_FEATURE_BALANCE.
   *
   * See Also: tp_connection_get_balance()
   */
  param_spec = g_param_spec_int ("balance", "Balance Amount",
      "The Amount field of the Account Balance",
      G_MININT32, G_MAXINT32, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_BALANCE,
      param_spec);

  /**
   * TpConnection:balance-scale:
   *
   * The Scale field of the Balance.AccountBalance property.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature %TP_CONNECTION_FEATURE_BALANCE.
   *
   * See Also: tp_connection_get_balance()
   */
  param_spec = g_param_spec_uint ("balance-scale", "Balance Scale",
      "The Scale field of the Account Balance",
      0, G_MAXUINT32, G_MAXUINT32,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_BALANCE_SCALE,
      param_spec);

  /**
   * TpConnection:balance-currency:
   *
   * The Currency field of the Balance.AccountBalance property.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature %TP_CONNECTION_FEATURE_BALANCE.
   *
   * See Also: tp_connection_get_balance()
   */
  param_spec = g_param_spec_string ("balance-currency", "Balance Currency",
      "The Currency field of the Account Balance",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_BALANCE_CURRENCY,
      param_spec);

  /**
   * TpConnection:balance-uri:
   *
   * The Balance.ManageCreditURI property.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature %TP_CONNECTION_FEATURE_BALANCE.
   */
  param_spec = g_param_spec_string ("balance-uri", "Balance URI",
      "The URI for managing the account balance",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_BALANCE_URI,
      param_spec);

  /**
   * TpConnection::balance-changed:
   * @self: a channel
   * @balance: the value of the #TpConnection:balance property
   * @balance_scale: the value of the #TpConnection:balance-scale property
   * @balance_currency: the value of the #TpConnection:balance-currency property
   *
   * Emitted when at least one of the #TpConnection:balance,
   * #TpConnection:balance-scale or #TpConnection:balance-currency
   * property is changed.
   *
   * For this signal to be emitted, you must first call
   * tp_proxy_prepare_async() with the feature %TP_CONNECTION_FEATURE_BALANCE.
   *
   * Since: 0.15.1
   */
  signals[SIGNAL_BALANCE_CHANGED] = g_signal_new ("balance-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 3, G_TYPE_INT, G_TYPE_UINT, G_TYPE_STRING);

  /**
   * TpConnection:contact-list-state:
   *
   * The progress made in retrieving the contact list.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_LIST_PROPERTIES or
   * %TP_CONNECTION_FEATURE_CONTACT_LIST.
   *
   * Since: 0.15.5
   */
  param_spec = g_param_spec_uint ("contact-list-state", "ContactList state",
      "The state of the contact list",
      0, G_MAXUINT, TP_CONTACT_LIST_STATE_NONE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONTACT_LIST_STATE,
      param_spec);

  /**
   * TpConnection:contact-list-persists:
   *
   * If true, presence subscriptions (in both directions) on this connection are
   * stored by the server or other infrastructure.
   *
   * If false, presence subscriptions on this connection are not stored.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_LIST_PROPERTIES or
   * %TP_CONNECTION_FEATURE_CONTACT_LIST.
   *
   * Since: 0.15.5
   */
  param_spec = g_param_spec_boolean ("contact-list-persists",
      "ContactList persists", "Whether the contact list persists",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONTACT_LIST_PERSISTS,
      param_spec);

  /**
   * TpConnection:can-change-contact-list:
   *
   * If true, presence subscription and publication can be changed using the
   * RequestSubscription, AuthorizePublication and RemoveContacts methods.
   *
   * Rational: link-local XMPP, presence is implicitly published to everyone in
   * the local subnet, so the user cannot control their presence publication.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_LIST_PROPERTIES or
   * %TP_CONNECTION_FEATURE_CONTACT_LIST.
   *
   * Since: 0.15.5
   */
  param_spec = g_param_spec_boolean ("can-change-contact-list",
      "ContactList can change", "Whether the contact list can change",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CAN_CHANGE_CONTACT_LIST,
      param_spec);

  /**
   * TpConnection:request-uses-message:
   *
   * If true, the Message parameter to RequestSubscription is likely to be
   * significant, and user interfaces SHOULD prompt the user for a message to
   * send with the request; a message such as "I would like to add you to my
   * contact list", translated into the local user's language, might make a
   * suitable default.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_LIST_PROPERTIES or
   * %TP_CONNECTION_FEATURE_CONTACT_LIST.
   *
   * Since: 0.15.5
   */
  param_spec = g_param_spec_boolean ("request-uses-message",
      "Request Uses Message", "Whether request uses message",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_REQUEST_USES_MESSAGE,
      param_spec);

  /**
   * TpConnection:disjoint-groups:
   *
   * True if each contact can be in at most one group; false if each contact
   * can be in many groups.
   *
   * This property cannot change after the connection has moved to the
   * %TP_CONNECTION_STATUS_CONNECTED state. Until then, its value is undefined,
   * and it may change at any time, without notification.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_GROUPS.
   *
   * Since: 0.15.5
   */
  param_spec = g_param_spec_boolean ("disjoint-groups",
      "Disjoint Groups", "Whether groups are disjoint",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DISJOINT_GROUPS,
      param_spec);

  /**
   * TpConnection:group-storage:
   *
   * Indicates the extent to which contacts' groups can be set and stored.
   *
   * This property cannot change after the connection has moved to the
   * %TP_CONNECTION_STATUS_CONNECTED state. Until then, its value is undefined,
   * and it may change at any time, without notification.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_GROUPS.
   *
   * Since: 0.15.5
   */
  param_spec = g_param_spec_uint ("group-storage",
      "Group Storage", "Group storage capabilities",
      0, G_MAXUINT, TP_CONTACT_METADATA_STORAGE_TYPE_NONE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_GROUP_STORAGE,
      param_spec);

  /**
   * TpConnection:contact-groups:
   *
   * The names of all groups that currently exist. This may be a larger set than
   * the union of all #TpContact:contact-groups properties, if the connection
   * allows groups to be empty.
   *
   * This property's value is not meaningful until the
   * #TpConnection:contact-list-state property has become
   * %TP_CONTACT_LIST_STATE_SUCCESS.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_GROUPS.
   *
   * Since: 0.15.5
   */
  param_spec = g_param_spec_boxed ("contact-groups",
      "Contact Groups",
      "All existing contact groups",
      G_TYPE_STRV,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONTACT_GROUPS,
      param_spec);

  /**
   * TpConnection:can-report-abusive:
   *
   * If this property is %TRUE, contacts may be reported as abusive to the
   * server administrators by setting report_abusive to %TRUE when calling
   * tp_connection_block_contacts_async().
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_BLOCKING.
   *
   * Since: 0.17.0
   */
  param_spec = g_param_spec_boolean ("can-report-abusive",
      "Can report abusive",
      "Can report abusive",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CAN_REPORT_ABUSIVE,
      param_spec);

  /**
   * TpConnection:blocked-contacts:
   *
   * A #GPtrArray of blocked #TpContact. Changes are notified using the
   * #TpConnection::blocked-contacts-changed signal.
   *
   * These TpContact objects have been prepared with the desired features.
   * See tp_simple_client_factory_add_contact_features() to define which
   * features needs to be prepared on them.
   *
   * For this property to be valid, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_BLOCKING.
   *
   * Since: 0.17.0
   */
  param_spec = g_param_spec_boxed ("blocked-contacts",
      "blocked contacts",
      "Blocked contacts",
      G_TYPE_PTR_ARRAY,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_BLOCKED_CONTACTS,
      param_spec);

  /**
   * TpConnection::groups-created:
   * @self: a #TpConnection
   * @added: a #GStrv with the names of the new groups.
   *
   * Emitted when new, empty groups are created. This will often be followed by
   * #TpContact::contact-groups-changed signals that add some members. When this
   * signal is emitted, #TpConnection:contact-groups property is already
   * updated.
   *
   * For this signal to be emited, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_GROUPS.
   *
   * Since: 0.15.5
   */
  signals[SIGNAL_GROUPS_CREATED] = g_signal_new (
      "groups-created",
      G_TYPE_FROM_CLASS (object_class),
      G_SIGNAL_RUN_LAST,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 1, G_TYPE_STRV);

  /**
   * TpConnection::groups-removed:
   * @self: A #TpConnection
   * @added: A #GStrv with the names of the groups.
   *
   * Emitted when one or more groups are removed. If they had members at the
   * time that they were removed, then immediately after this signal is emitted,
   * #TpContact::contact-groups-changed signals that their members were removed.
   * When this signal is emitted, #TpConnection:contact-groups property is
   * already updated.
   *
   * For this signal to be emited, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_GROUPS.
   *
   * Since: 0.15.5
   */
  signals[SIGNAL_GROUPS_REMOVED] = g_signal_new (
      "groups-removed",
      G_TYPE_FROM_CLASS (object_class),
      G_SIGNAL_RUN_LAST,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 1, G_TYPE_STRV);

  /**
   * TpConnection::group-renamed:
   * @self: a #TpConnection
   * @old_name: the old name of the group.
   * @new_name: the new name of the group.
   *
   * Emitted when a group is renamed, in protocols where this can be
   * distinguished from group creation, removal and membership changes.
   *
   * Immediately after this signal is emitted, #TpConnection::groups-created
   * signal the creation of a group with the new name, and
   * #TpConnection::groups-removed signal the removal of a group with the old
   * name.
   * If the group was not empty, immediately after those signals are emitted,
   * #TpContact::contact-groups-changed signal that the members of that group
   * were removed from the old name and added to the new name.
   *
   * When this signal is emitted, #TpConnection:contact-groups property is
   * already updated.
   *
   * For this signal to be emited, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_GROUPS.
   *
   * Since: 0.15.5
   */
  signals[SIGNAL_GROUP_RENAMED] = g_signal_new (
      "group-renamed",
      G_TYPE_FROM_CLASS (object_class),
      G_SIGNAL_RUN_LAST,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 2, G_TYPE_STRING, G_TYPE_STRING);
  /**
   * TpConnection::contact-list-changed:
   * @self: a #TpConnection
   * @added: (type GLib.PtrArray) (element-type TelepathyGLib.Contact):
   *  a #GPtrArray of #TpContact added to contacts list
   * @removed: (type GLib.PtrArray) (element-type TelepathyGLib.Contact):
   *  a #GPtrArray of #TpContact removed from contacts list
   *
   * Notify of changes in the list of contacts as returned by
   * tp_connection_dup_contact_list(). It is guaranteed that all contacts have
   * desired features prepared. See
   * tp_simple_client_factory_add_contact_features() to define which features
   * needs to be prepared.
   *
   * This signal is also emitted for the initial set of contacts once retrieved.
   *
   * For this signal to be emitted, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_LIST.
   *
   * Since: 0.15.5
   */
  signals[SIGNAL_CONTACT_LIST_CHANGED] = g_signal_new (
      "contact-list-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 2, G_TYPE_PTR_ARRAY, G_TYPE_PTR_ARRAY);

  /**
   * TpConnection::blocked-contacts-changed:
   * @self: a #TpConnection
   * @added: (type GLib.PtrArray) (element-type TelepathyGLib.Contact):
   *  a #GPtrArray of #TpContact which have been blocked
   * @removed: (type GLib.PtrArray) (element-type TelepathyGLib.Contact):
   *  a #GPtrArray of #TpContact which are no longer blocked
   *
   * Notify of changes in #TpConnection:blocked-contacts.
   *  It is guaranteed that all contacts have desired features prepared. See
   * tp_simple_client_factory_add_contact_features() to define which features
   * needs to be prepared.
   *
   * This signal is also emitted for the initial set of blocked contacts once
   * retrieved.
   *
   * For this signal to be emitted, you must first call
   * tp_proxy_prepare_async() with the feature
   * %TP_CONNECTION_FEATURE_CONTACT_BLOCKING.
   *
   * Since: 0.17.0
   */
  signals[SIGNAL_BLOCKED_CONTACTS_CHANGED] = g_signal_new (
      "blocked-contacts-changed",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 2, G_TYPE_PTR_ARRAY, G_TYPE_PTR_ARRAY);

}

/**
 * tp_connection_new:
 * @dbus: a D-Bus daemon; may not be %NULL
 * @bus_name: (allow-none): the well-known or unique name of the connection
 *  process; if well-known, this function will make a blocking call to the bus
 *  daemon to resolve the unique name. May be %NULL if @object_path is not, in
 *  which case a well-known name will be derived from @object_path.
 * @object_path: (allow-none): the object path of the connection process.
 *  May be %NULL if @bus_name is a well-known name, in which case the object
 *  path will be derived from @bus_name.
 * @error: used to indicate the error if %NULL is returned
 *
 * <!-- -->
 *
 * Returns: a new connection proxy, or %NULL if unique-name resolution
 *  fails or on invalid arguments
 *
 * Since: 0.7.1
 * Deprecated: Use tp_simple_client_factory_ensure_connection() instead.
 */
TpConnection *
tp_connection_new (TpDBusDaemon *dbus,
                   const gchar *bus_name,
                   const gchar *object_path,
                   GError **error)
{
  return _tp_connection_new_with_factory (NULL, dbus, bus_name, object_path,
      error);
}

TpConnection *
_tp_connection_new_with_factory (TpSimpleClientFactory *factory,
    TpDBusDaemon *dbus,
    const gchar *bus_name,
    const gchar *object_path,
    GError **error)
{
  gchar *dup_path = NULL;
  gchar *dup_name = NULL;
  gchar *dup_unique_name = NULL;
  TpConnection *ret = NULL;

  g_return_val_if_fail (TP_IS_DBUS_DAEMON (dbus), NULL);
  g_return_val_if_fail (object_path != NULL ||
                        (bus_name != NULL && bus_name[0] != ':'), NULL);

  if (object_path == NULL)
    {
      dup_path = g_strdelimit (g_strdup_printf ("/%s", bus_name), ".", '/');
      object_path = dup_path;
    }
  else if (bus_name == NULL)
    {
      dup_name = g_strdelimit (g_strdup (object_path + 1), "/", '.');
      bus_name = dup_name;
    }

  if (!_tp_connection_parse (object_path, '/', NULL, NULL))
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_OBJECT_PATH,
          "Connection object path is not in the right format");
      goto finally;
    }

  if (!tp_dbus_check_valid_bus_name (bus_name,
        TP_DBUS_NAME_TYPE_NOT_BUS_DAEMON, error))
    goto finally;

  /* Resolve unique name if necessary */
  if (bus_name[0] != ':')
    {
      if (!_tp_dbus_daemon_get_name_owner (dbus, 2000, bus_name,
          &dup_unique_name, error))
        goto finally;

      bus_name = dup_unique_name;

      if (!tp_dbus_check_valid_bus_name (bus_name,
          TP_DBUS_NAME_TYPE_UNIQUE, error))
        goto finally;
    }

  if (!tp_dbus_check_valid_object_path (object_path, error))
    goto finally;

  ret = TP_CONNECTION (g_object_new (TP_TYPE_CONNECTION,
        "dbus-daemon", dbus,
        "bus-name", bus_name,
        "object-path", object_path,
        "factory", factory,
        NULL));

finally:
  g_free (dup_path);
  g_free (dup_name);
  g_free (dup_unique_name);

  return ret;
}

/**
 * tp_connection_get_account:
 * @self: a connection
 *
 * Return the the #TpAccount associated with this connection. Will return %NULL
 * if @self was not acquired from a #TpAccount via tp_account_get_connection(),
 * or if the account object got finalized in the meantime (#TpConnection does
 * not keep a strong ref on its #TpAccount).
 *
 * Returns: (transfer none): the account associated with this connection, or
 * %NULL.
 *
 * Since: 0.15.5
 */
TpAccount *
tp_connection_get_account (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);

  return self->priv->account;
}

void
_tp_connection_set_account (TpConnection *self,
    TpAccount *account)
{
  if (self->priv->account == account)
    return;

  g_assert (self->priv->account == NULL);
  g_assert (account != NULL);

  self->priv->account = account;
  g_object_add_weak_pointer ((GObject *) account,
      (gpointer) &self->priv->account);
}

/**
 * tp_connection_get_self_handle:
 * @self: a connection
 *
 * Return the %TP_HANDLE_TYPE_CONTACT handle of the local user on this
 * connection, or 0 if the self-handle is not known yet or the connection
 * has become invalid (the TpProxy::invalidated signal).
 *
 * The returned handle is not necessarily valid forever (the
 * notify::self-handle signal will be emitted if it changes, which can happen
 * on protocols such as IRC). Construct a #TpContact object if you want to
 * track the local user's identifier in the protocol, or other information
 * like their presence status, over time.
 *
 * Returns: the value of the TpConnection:self-handle property
 *
 * Since: 0.7.26
 * Deprecated: Use tp_connection_get_self_contact() instead.
 */
TpHandle
tp_connection_get_self_handle (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), 0);

  if (self->priv->self_contact == NULL)
    return 0;

  return tp_contact_get_handle (self->priv->self_contact);
}

/**
 * tp_connection_get_status:
 * @self: a connection
 * @reason: (out): a TpConnectionStatusReason, or %NULL
 *
 * If @reason is not %NULL it is set to the reason why "status" changed to its
 * current value, or %TP_CONNECTION_STATUS_REASON_NONE_SPECIFIED if unknown.
 *
 * Returns: This connection's status, or %TP_UNKNOWN_CONNECTION_STATUS if we
 * don't know yet.
 *
 * Since: 0.7.14
 */
TpConnectionStatus
tp_connection_get_status (TpConnection *self,
                          TpConnectionStatusReason *reason)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), TP_UNKNOWN_CONNECTION_STATUS);

  if (reason != NULL)
    *reason = self->priv->status_reason;

  return self->priv->status;
}

/**
 * tp_connection_get_connection_manager_name:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: the same as the #TpConnection:connection-manager-name property
 *
 * Since: 0.13.16
 * Deprecated: Use tp_connection_get_cm_name() instead.
 *
 */
const gchar *
tp_connection_get_connection_manager_name (TpConnection *self)
{
    g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);

    return self->priv->cm_name;
}

/**
 * tp_connection_get_cm_name:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: the same as the #TpConnection:cm-name property
 *
 * Since: 0.19.3
 *
 */
const gchar *
tp_connection_get_cm_name (TpConnection *self)
{
    g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);

    return self->priv->cm_name;
}

/**
 * tp_connection_get_protocol_name:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: the same as the #TpConnection:protocol-name property
 *
 * Since: 0.13.16
 *
 */
const gchar *
tp_connection_get_protocol_name (TpConnection *self)
{
    g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);

    return self->priv->proto_name;
}

/**
 * tp_connection_run_until_ready: (skip)
 * @self: a connection
 * @connect: if %TRUE, call Connect() if it appears to be necessary;
 *  if %FALSE, rely on Connect() to be called by another client
 * @error: if not %NULL and %FALSE is returned, used to raise an error
 * @loop: if not %NULL, a #GMainLoop is placed here while it is being run
 *  (so calling code can call g_main_loop_quit() to abort), and %NULL is
 *  placed here after the loop has been run
 *
 * If @self is connected and ready for use, return immediately. Otherwise,
 * call Connect() (unless @connect is %FALSE) and re-enter the main loop
 * until the connection becomes invalid, the connection connects successfully
 * and is introspected, or the main loop stored via @loop is cancelled.
 *
 * Returns: %TRUE if the connection is now connected and ready for use,
 *  %FALSE if the connection has become invalid.
 *
 * Since: 0.7.1
 * Deprecated: 0.11.0: Use tp_proxy_prepare_async() and re-enter the main
 *  loop yourself, or restructure your program in such a way as to avoid
 *  re-entering the main loop.
 */

typedef struct {
    GMainLoop *loop;
    TpProxyPendingCall *pc;
    GError *connect_error /* gets initialized */;
} RunUntilReadyData;

static void
run_until_ready_ret (TpConnection *self,
                     const GError *error,
                     gpointer user_data,
                     GObject *weak_object)
{
  RunUntilReadyData *data = user_data;

  if (error != NULL)
    {
      g_main_loop_quit (data->loop);
      data->connect_error = g_error_copy (error);
    }
}

static void
run_until_ready_destroy (gpointer p)
{
  RunUntilReadyData *data = p;

  data->pc = NULL;
}

gboolean
tp_connection_run_until_ready (TpConnection *self,
                               gboolean connect,
                               GError **error,
                               GMainLoop **loop)
{
  TpProxy *as_proxy = (TpProxy *) self;
  gulong invalidated_id, ready_id;
  RunUntilReadyData data = { NULL, NULL, NULL };

  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  if (as_proxy->invalidated)
    goto raise_invalidated;

  if (self->priv->ready)
    return TRUE;

  data.loop = g_main_loop_new (NULL, FALSE);

  invalidated_id = g_signal_connect_swapped (self, "invalidated",
      G_CALLBACK (g_main_loop_quit), data.loop);
  ready_id = g_signal_connect_swapped (self, "notify::connection-ready",
      G_CALLBACK (g_main_loop_quit), data.loop);

  if (self->priv->status != TP_CONNECTION_STATUS_CONNECTED &&
      connect)
    {
      data.pc = tp_cli_connection_call_connect (self, -1,
          run_until_ready_ret, &data,
          run_until_ready_destroy, NULL);
    }

  if (data.connect_error == NULL)
    {
      if (loop != NULL)
        *loop = data.loop;

      g_main_loop_run (data.loop);

      if (loop != NULL)
        *loop = NULL;
    }

  if (data.pc != NULL)
    tp_proxy_pending_call_cancel (data.pc);

  g_signal_handler_disconnect (self, invalidated_id);
  g_signal_handler_disconnect (self, ready_id);
  g_main_loop_unref (data.loop);

  if (data.connect_error != NULL)
    {
      g_propagate_error (error, data.connect_error);
      return FALSE;
    }

  if (as_proxy->invalidated != NULL)
    goto raise_invalidated;

  if (self->priv->ready)
    return TRUE;

  g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_CANCELLED,
      "tp_connection_run_until_ready() cancelled");
  return FALSE;

raise_invalidated:
  if (error != NULL)
    {
      g_return_val_if_fail (*error == NULL, FALSE);
      *error = g_error_copy (as_proxy->invalidated);
    }

  return FALSE;
}

/**
 * TpConnectionNameListCb:
 * @names: (array zero-terminated=1): %NULL-terminated array of @n
 *  connection bus names, or %NULL on error
 * @n: number of names (not including the final %NULL), or 0 on error
 * @cms: (array zero-terminated=1): %NULL-terminated array of @n
 *  connection manager names (e.g. "gabble") in the same order as @names, or
 *  %NULL on error
 * @protocols: (array zero-terminated=1): %NULL-terminated array of
 *  @n protocol names as defined in the Telepathy spec (e.g. "jabber") in the
 *  same order as @names, or %NULL on error
 * @error: %NULL on success, or an error that occurred
 * @user_data: user-supplied data
 * @weak_object: user-supplied weakly referenced object
 *
 * Signature of the callback supplied to tp_list_connection_names().
 *
 * Since: 0.7.1
 */

typedef struct {
    TpConnectionNameListCb callback;
    gpointer user_data;
    GDestroyNotify destroy;
} _ListContext;

static gboolean
_tp_connection_parse (const gchar *path_or_bus_name,
                      char delimiter,
                      gchar **protocol,
                      gchar **cm_name)
{
  const gchar *prefix;
  const gchar *cm_name_start;
  const gchar *protocol_start;
  const gchar *account_start;
  gchar *dup_cm_name = NULL;
  gchar *dup_protocol = NULL;

  g_return_val_if_fail (delimiter == '.' || delimiter == '/', FALSE);

  /* If CM respects the spec, object path and bus name should be in the form:
   * /org/freedesktop/Telepathy/Connection/cmname/proto/account
   * org.freedesktop.Telepathy.Connection.cmname.proto.account
   */
  if (delimiter == '.')
    prefix = TP_CONN_BUS_NAME_BASE;
  else
    prefix = TP_CONN_OBJECT_PATH_BASE;

  if (!g_str_has_prefix (path_or_bus_name, prefix))
    goto OUT;

  cm_name_start = path_or_bus_name + strlen (prefix);
  protocol_start = strchr (cm_name_start, delimiter);
  if (protocol_start == NULL)
    goto OUT;
  protocol_start++;

  account_start = strchr (protocol_start, delimiter);
  if (account_start == NULL)
    goto OUT;
  account_start++;

  dup_cm_name = g_strndup (cm_name_start, protocol_start - cm_name_start - 1);
  if (!tp_connection_manager_check_valid_name (dup_cm_name, NULL))
    {
      g_free (dup_cm_name);
      dup_cm_name = NULL;
      goto OUT;
    }

  dup_protocol = g_strndup (protocol_start, account_start - protocol_start - 1);
  if (!tp_strdiff (dup_protocol, "local_2dxmpp"))
    {
      /* the CM's telepathy-glib is older than 0.7.x, work around it.
       * FIXME: Remove this workaround in 0.9.x */
      g_free (dup_protocol);
      dup_protocol = g_strdup ("local-xmpp");
    }
  else
    {
      /* the real protocol name may have "-" in; bus names may not, but
       * they may have "_", so the Telepathy spec specifies replacement.
       * Here we need to undo that replacement */
      g_strdelimit (dup_protocol, "_", '-');
    }

  if (!tp_connection_manager_check_valid_protocol_name (dup_protocol, NULL))
    {
      g_free (dup_protocol);
      dup_protocol = NULL;
      goto OUT;
    }

OUT:

  if (dup_protocol == NULL || dup_cm_name == NULL)
    {
      g_free (dup_protocol);
      g_free (dup_cm_name);
      return FALSE;
    }

  if (cm_name != NULL)
    *cm_name = dup_cm_name;
  else
    g_free (dup_cm_name);

  if (protocol != NULL)
    *protocol = dup_protocol;
  else
    g_free (dup_protocol);

  return TRUE;
}

static void
tp_list_connection_names_helper (TpDBusDaemon *bus_daemon,
                                 const gchar * const *names,
                                 const GError *error,
                                 gpointer user_data,
                                 GObject *user_object)
{
  _ListContext *list_context = user_data;
  const gchar * const *iter;
  /* array of borrowed strings */
  GPtrArray *bus_names;
  /* array of dup'd strings */
  GPtrArray *cms;
  /* array of borrowed strings */
  GPtrArray *protocols;

  if (error != NULL)
    {
      list_context->callback (NULL, 0, NULL, NULL, error,
          list_context->user_data, user_object);
      return;
    }

  bus_names = g_ptr_array_new ();
  cms = g_ptr_array_new ();
  protocols = g_ptr_array_new ();

  for (iter = names; iter != NULL && *iter != NULL; iter++)
    {
      gchar *proto, *cm_name;

      if (_tp_connection_parse (*iter, '.', &proto, &cm_name))
        {
          /* the casts here are because g_ptr_array contains non-const pointers -
           * but in this case I'll only be passing pdata to a callback with const
           * arguments, so it's fine */
          g_ptr_array_add (bus_names, (gpointer) *iter);
          g_ptr_array_add (cms, cm_name);
          g_ptr_array_add (protocols, proto);
          continue;
        }
    }

  g_ptr_array_add (bus_names, NULL);
  g_ptr_array_add (cms, NULL);
  g_ptr_array_add (protocols, NULL);

  list_context->callback ((const gchar * const *) bus_names->pdata,
      bus_names->len - 1, (const gchar * const *) cms->pdata,
      (const gchar * const *) protocols->pdata,
      NULL, list_context->user_data, user_object);

  g_ptr_array_unref (bus_names);
  g_strfreev ((char **) g_ptr_array_free (cms, FALSE));
  g_strfreev ((char **) g_ptr_array_free (protocols, FALSE));
}

static void
list_context_free (gpointer p)
{
  _ListContext *list_context = p;

  if (list_context->destroy != NULL)
    list_context->destroy (list_context->user_data);

  g_slice_free (_ListContext, list_context);
}

/**
 * tp_list_connection_names:
 * @bus_daemon: proxy for the D-Bus daemon
 * @callback: callback to be called when listing the connections succeeds or
 *   fails; not called if the D-Bus connection fails completely or if the
 *   @weak_object goes away
 * @user_data: user-supplied data for the callback
 * @destroy: callback to destroy the user-supplied data, called after
 *   @callback, but also if the D-Bus connection fails or if the @weak_object
 *   goes away
 * @weak_object: (allow-none): if not %NULL, will be weakly referenced; the callback will
 *   not be called if the object has vanished
 *
 * List the bus names of all the connections that currently exist, together
 * with the connection manager name and the protocol name for each connection.
 * Call the callback when done.
 *
 * The bus names passed to the callback can be used to construct #TpConnection
 * objects for any connections that are of interest.
 *
 * Since: 0.7.1
 */
void
tp_list_connection_names (TpDBusDaemon *bus_daemon,
                          TpConnectionNameListCb callback,
                          gpointer user_data,
                          GDestroyNotify destroy,
                          GObject *weak_object)
{
  _ListContext *list_context = g_slice_new0 (_ListContext);

  g_return_if_fail (TP_IS_DBUS_DAEMON (bus_daemon));
  g_return_if_fail (callback != NULL);

  list_context->callback = callback;
  list_context->user_data = user_data;

  tp_dbus_daemon_list_names (bus_daemon, 2000,
      tp_list_connection_names_helper, list_context,
      list_context_free, weak_object);
}

static gpointer
tp_connection_once (gpointer data G_GNUC_UNUSED)
{
  GType type = TP_TYPE_CONNECTION;

  tp_proxy_init_known_interfaces ();

  tp_proxy_or_subclass_hook_on_interface_add (type,
      tp_cli_connection_add_signals);
  tp_proxy_subclass_add_error_mapping (type,
      TP_ERROR_PREFIX, TP_ERROR, TP_TYPE_ERROR);

  return NULL;
}

/**
 * tp_connection_init_known_interfaces:
 *
 * Ensure that the known interfaces for TpConnection have been set up.
 * This is done automatically when necessary, but for correct
 * overriding of library interfaces by local extensions, you should
 * call this function before calling
 * tp_proxy_or_subclass_hook_on_interface_add() with first argument
 * %TP_TYPE_CONNECTION.
 *
 * Since: 0.7.6
 */
void
tp_connection_init_known_interfaces (void)
{
  static GOnce once = G_ONCE_INIT;

  g_once (&once, tp_connection_once, NULL);
}

typedef struct {
    TpConnectionWhenReadyCb callback;
    gpointer user_data;
    gulong invalidated_id;
    gulong ready_id;
} CallWhenReadyContext;

static void
cwr_invalidated (TpConnection *self,
                 guint domain,
                 gint code,
                 gchar *message,
                 gpointer user_data)
{
  CallWhenReadyContext *ctx = user_data;
  GError e = { domain, code, message };

  DEBUG ("enter");

  g_assert (ctx->callback != NULL);

  ctx->callback (self, &e, ctx->user_data);

  g_signal_handler_disconnect (self, ctx->invalidated_id);
  g_signal_handler_disconnect (self, ctx->ready_id);

  ctx->callback = NULL;   /* poison it to detect errors */
  g_slice_free (CallWhenReadyContext, ctx);
}

static void
cwr_ready (TpConnection *self,
           GParamSpec *unused G_GNUC_UNUSED,
           gpointer user_data)
{
  CallWhenReadyContext *ctx = user_data;

  DEBUG ("enter");

  g_assert (ctx->callback != NULL);

  ctx->callback (self, NULL, ctx->user_data);

  g_signal_handler_disconnect (self, ctx->invalidated_id);
  g_signal_handler_disconnect (self, ctx->ready_id);

  ctx->callback = NULL;   /* poison it to detect errors */
  g_slice_free (CallWhenReadyContext, ctx);
}

/**
 * TpConnectionWhenReadyCb:
 * @connection: the connection (which may be in the middle of being disposed,
 *  if error is non-%NULL, error->domain is TP_DBUS_ERRORS and error->code is
 *  TP_DBUS_ERROR_PROXY_UNREFERENCED)
 * @error: %NULL if the connection is ready for use, or the error with which
 *  it was invalidated if it is now invalid
 * @user_data: whatever was passed to tp_connection_call_when_ready()
 *
 * Signature of a callback passed to tp_connection_call_when_ready(), which
 * will be called exactly once, when the connection becomes ready or
 * invalid (whichever happens first)
 *
 * Deprecated: 0.17.6
 */

/**
 * tp_connection_call_when_ready: (skip)
 * @self: a connection
 * @callback: called when the connection becomes ready or invalidated,
 *  whichever happens first
 * @user_data: arbitrary user-supplied data passed to the callback
 *
 * If @self is ready for use or has been invalidated, call @callback
 * immediately, then return. Otherwise, arrange
 * for @callback to be called when @self either becomes ready for use
 * or becomes invalid.
 *
 * Note that if the connection is not in state CONNECTED, the callback will
 * not be called until the connection either goes to state CONNECTED
 * or is invalidated (e.g. by going to state DISCONNECTED or by becoming
 * unreferenced). In particular, this method does not call Connect().
 * Call tp_cli_connection_call_connect() too, if you want to do that.
 *
 * Since: 0.7.7
 * Deprecated: 0.17.6: Use tp_proxy_prepare_async()
 */
void
tp_connection_call_when_ready (TpConnection *self,
                               TpConnectionWhenReadyCb callback,
                               gpointer user_data)
{
  TpProxy *as_proxy = (TpProxy *) self;

  g_return_if_fail (TP_IS_CONNECTION (self));
  g_return_if_fail (callback != NULL);

  if (self->priv->ready || as_proxy->invalidated != NULL)
    {
      DEBUG ("already ready or invalidated");
      callback (self, as_proxy->invalidated, user_data);
    }
  else
    {
      CallWhenReadyContext *ctx = g_slice_new (CallWhenReadyContext);

      DEBUG ("arranging callback later");

      ctx->callback = callback;
      ctx->user_data = user_data;
      ctx->invalidated_id = g_signal_connect (self, "invalidated",
          G_CALLBACK (cwr_invalidated), ctx);
      ctx->ready_id = g_signal_connect (self, "notify::connection-ready",
          G_CALLBACK (cwr_ready), ctx);
    }
}

static guint
get_presence_type_availability (TpConnectionPresenceType type)
{
  switch (type)
    {
      case TP_CONNECTION_PRESENCE_TYPE_UNSET:
        return 0;
      case TP_CONNECTION_PRESENCE_TYPE_UNKNOWN:
        return 1;
      case TP_CONNECTION_PRESENCE_TYPE_ERROR:
        return 2;
      case TP_CONNECTION_PRESENCE_TYPE_OFFLINE:
        return 3;
      case TP_CONNECTION_PRESENCE_TYPE_HIDDEN:
        return 4;
      case TP_CONNECTION_PRESENCE_TYPE_EXTENDED_AWAY:
        return 5;
      case TP_CONNECTION_PRESENCE_TYPE_AWAY:
        return 6;
      case TP_CONNECTION_PRESENCE_TYPE_BUSY:
        return 7;
      case TP_CONNECTION_PRESENCE_TYPE_AVAILABLE:
        return 8;
    }

  /* This is an unexpected presence type, treat it like UNKNOWN */
  return 1;
}

/**
 * tp_connection_presence_type_cmp_availability:
 * @p1: a #TpConnectionPresenceType
 * @p2: a #TpConnectionPresenceType
 *
 * Compares @p1 and @p2 like strcmp(). @p1 > @p2 means @p1 is more available
 * than @p2.
 *
 * The order used is: available > busy > away > xa > hidden > offline > error >
 * unknown > unset
 *
 * Returns: -1, 0 or 1, if @p1 is <, == or > than @p2.
 *
 * Since: 0.7.16
 */
gint
tp_connection_presence_type_cmp_availability (TpConnectionPresenceType p1,
                                              TpConnectionPresenceType p2)
{
  guint availability1;
  guint availability2;

  availability1 = get_presence_type_availability (p1);
  availability2 = get_presence_type_availability (p2);

  if (availability1 < availability2)
    return -1;

  if (availability1 > availability2)
    return +1;

  return 0;
}


/**
 * tp_connection_parse_object_path:
 * @self: a connection
 * @protocol: (out) (transfer full): If not NULL, used to return the protocol
 *  of the connection
 * @cm_name: (out) (transfer full): If not NULL, used to return the connection
 *  manager name of the connection
 *
 * If the object path of @connection is in the correct form, set
 * @protocol and @cm_name, return TRUE. Otherwise leave them unchanged and
 * return FALSE.
 *
 * Returns: TRUE if the object path was correctly parsed, FALSE otherwise.
 *
 * Since: 0.7.27
 * Deprecated: Use tp_connection_get_protocol_name() and
 *  tp_connection_get_connection_manager_name() instead.
 */
gboolean
tp_connection_parse_object_path (TpConnection *self,
                                 gchar **protocol,
                                 gchar **cm_name)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  if (protocol != NULL)
    *protocol = g_strdup (self->priv->proto_name);

  if (cm_name != NULL)
    *cm_name = g_strdup (self->priv->cm_name);

  return TRUE;
}

/* Can return a contact that's not meant to be visible to library users
 * because it lacks an identifier */
TpContact *
_tp_connection_lookup_contact (TpConnection *self,
                               TpHandle handle)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);

  return g_hash_table_lookup (self->priv->contacts, GUINT_TO_POINTER (handle));
}


/* this could be done with proper weak references, but we know that every
 * connection will weakly reference all its contacts, so we can just do this
 * explicitly in tp_contact_dispose */
void
_tp_connection_remove_contact (TpConnection *self,
                               TpHandle handle,
                               TpContact *contact)
{
  TpContact *mine;

  g_return_if_fail (TP_IS_CONNECTION (self));
  g_return_if_fail (TP_IS_CONTACT (contact));

  mine = g_hash_table_lookup (self->priv->contacts, GUINT_TO_POINTER (handle));
  g_return_if_fail (mine == contact);
  g_hash_table_remove (self->priv->contacts, GUINT_TO_POINTER (handle));
}


void
_tp_connection_add_contact (TpConnection *self,
                            TpHandle handle,
                            TpContact *contact)
{
  g_return_if_fail (TP_IS_CONNECTION (self));
  g_return_if_fail (TP_IS_CONTACT (contact));
  g_return_if_fail (g_hash_table_lookup (self->priv->contacts,
        GUINT_TO_POINTER (handle)) == NULL);

  g_hash_table_insert (self->priv->contacts, GUINT_TO_POINTER (handle),
      contact);

  /* Set TP_CONTACT_FEATURE_CONTACT_BLOCKING if possible */
  if (tp_proxy_is_prepared (self, TP_CONNECTION_FEATURE_CONTACT_BLOCKING))
    {
      _tp_connection_set_contact_blocked (self, contact);
    }
}


/**
 * tp_connection_is_ready: (skip)
 * @self: a connection
 *
 * Returns the same thing as the #TpConnection:connection-ready property.
 *
 * Returns: %TRUE if introspection has completed
 * Since: 0.7.17
 * Deprecated: 0.17.6: use tp_proxy_is_prepared() with
 *  %TP_CONNECTION_FEATURE_CONNECTED
 */
gboolean
tp_connection_is_ready (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  return self->priv->ready;
}

/**
 * tp_connection_get_capabilities:
 * @self: a connection
 *
 * <!-- -->
 *
 * Returns: (transfer none): the same #TpCapabilities as the
 * #TpConnection:capabilities property
 * Since: 0.11.3
 */
TpCapabilities *
tp_connection_get_capabilities (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  return self->priv->capabilities;
}

/**
 * tp_connection_get_detailed_error:
 * @self: a connection
 * @details: (out) (allow-none) (element-type utf8 GObject.Value) (transfer none):
 *  optionally used to return a map from string to #GValue, which must not be
 *  modified or destroyed by the caller
 *
 * If the connection has disconnected, return the D-Bus error name with which
 * it disconnected (in particular, this is %TP_ERROR_STR_CANCELLED if it was
 * disconnected by a user request).
 *
 * Otherwise, return %NULL, without altering @details.
 *
 * Returns: (transfer none) (allow-none): a D-Bus error name, or %NULL.
 *
 * Since: 0.11.4
 */
const gchar *
tp_connection_get_detailed_error (TpConnection *self,
    const GHashTable **details)
{
  TpProxy *proxy = (TpProxy *) self;

  if (proxy->invalidated == NULL)
    return NULL;

  if (self->priv->connection_error != NULL)
    {
      g_assert (self->priv->connection_error_details != NULL);

      if (details != NULL)
        *details = self->priv->connection_error_details;

      return self->priv->connection_error;
    }
  else
    {
      /* no detailed error, but we *have* been invalidated - guess one based
       * on the invalidation reason */

      if (details != NULL)
        {
          if (self->priv->connection_error_details == NULL)
            {
              self->priv->connection_error_details = tp_asv_new (
                  "debug-message", G_TYPE_STRING, proxy->invalidated->message,
                  NULL);
            }

          *details = self->priv->connection_error_details;
        }

      if (proxy->invalidated->domain == TP_ERROR)
        {
          return tp_error_get_dbus_name (proxy->invalidated->code);
        }
      else if (proxy->invalidated->domain == TP_DBUS_ERRORS)
        {
          switch (proxy->invalidated->code)
            {
            case TP_DBUS_ERROR_NAME_OWNER_LOST:
              /* the CM probably crashed */
              return DBUS_ERROR_NO_REPLY;
              break;

            case TP_DBUS_ERROR_OBJECT_REMOVED:
            case TP_DBUS_ERROR_UNKNOWN_REMOTE_ERROR:
            case TP_DBUS_ERROR_INCONSISTENT:
            /* ... and all other cases up to and including
             * TP_DBUS_ERROR_INCONSISTENT don't make sense in this context, so
             * just use the generic one for them too */
            default:
              return TP_ERROR_STR_DISCONNECTED;
            }
        }
      else
        {
          /* no idea what that means */
          return TP_ERROR_STR_DISCONNECTED;
        }
    }
}

/**
 * tp_connection_dup_detailed_error_vardict:
 * @self: a connection
 * @details: (out) (allow-none) (transfer full):
 *  optionally used to return a %G_VARIANT_TYPE_VARDICT with details
 *  of the error
 *
 * If the connection has disconnected, return the D-Bus error name with which
 * it disconnected (in particular, this is %TP_ERROR_STR_CANCELLED if it was
 * disconnected by a user request).
 *
 * Otherwise, return %NULL, without altering @details.
 *
 * Returns: (transfer full) (allow-none): a D-Bus error name, or %NULL.
 *
 * Since: 0.19.0
 */
gchar *
tp_connection_dup_detailed_error_vardict (TpConnection *self,
    GVariant **details)
{
  const GHashTable *asv;
  const gchar *error = tp_connection_get_detailed_error (self, &asv);

  if (error == NULL)
    return NULL;

  if (details != NULL)
    *details = _tp_asv_to_vardict (asv);

  return g_strdup (error);
}

/**
 * tp_connection_add_client_interest:
 * @self: a connection
 * @interested_in: a string identifying an interface or part of an interface
 *  to which this connection will subscribe
 *
 * Subscribe to any opt-in change notifications for @interested_in.
 *
 * For contact information, use #TpContact instead, which will call this
 * automatically.
 *
 * Since: 0.11.3
 */
void
tp_connection_add_client_interest (TpConnection *self,
    const gchar *interested_in)
{
  tp_connection_add_client_interest_by_id (self,
      g_quark_from_string (interested_in));
}

/**
 * tp_connection_add_client_interest_by_id: (skip)
 * @self: a connection
 * @interested_in: a quark identifying an interface or part of an interface
 *  to which this connection will subscribe
 *
 * Subscribe to any opt-in change notifications for @interested_in.
 *
 * Equivalent to, but a little more efficient than, calling
 * tp_connection_add_client_interest() for the string value of @interested_in.
 *
 * Since: 0.11.3
 */
void
tp_connection_add_client_interest_by_id (TpConnection *self,
    GQuark interested_in)
{
  TpProxy *proxy = (TpProxy *) self;
  const gchar *interest = g_quark_to_string (interested_in);
  const gchar *strv[2] = { interest, NULL };

  g_return_if_fail (TP_IS_CONNECTION (self));
  g_return_if_fail (interest != NULL);

  if (proxy->invalidated != NULL ||
      tp_intset_is_member (self->priv->interests, interested_in))
    return;

  tp_intset_add (self->priv->interests, interested_in);

  /* no-reply flag set, and we ignore any reply */
  tp_cli_connection_call_add_client_interest (self, -1,
      strv, NULL, NULL, NULL, NULL);
}

/**
 * tp_connection_has_immortal_handles:
 * @self: a connection
 *
 * Return %TRUE if this connection is known to not destroy handles
 * (#TpHandle) until it disconnects.
 *
 * On such connections, if you know that a handle maps to a particular
 * identifier now, then you can rely on that handle mapping to that
 * identifier for the whole lifetime of the connection.
 *
 * Returns: %TRUE if handles last as long as the connection itself
 */
gboolean
tp_connection_has_immortal_handles (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  return self->priv->has_immortal_handles;
}

/**
 * tp_connection_get_self_contact:
 * @self: a connection
 *
 * Return a #TpContact representing the local user on this connection.
 *
 * The returned object is not necessarily valid after the main loop is
 * re-entered; ref it with g_object_ref() if you want to keep it.
 *
 * Returns: (transfer none): the value of the TpConnection:self-contact
 *  property, which may be %NULL
 *
 * Since: 0.13.9
 */
TpContact *
tp_connection_get_self_contact (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);
  return self->priv->self_contact;
}

/**
 * tp_connection_bind_connection_status_to_property:
 * @self: a #TpConnection
 * @target: the target #GObject
 * @target_property: the property on @target to bind (must be %G_TYPE_BOOLEAN)
 * @invert: %TRUE if you wish to invert the value of @target_property
 *   (i.e. %FALSE if connected)
 *
 * Binds the :status of @self to the boolean property of another
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
tp_connection_bind_connection_status_to_property (TpConnection *self,
    gpointer target,
    const char *target_property,
    gboolean invert)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);

  return g_object_bind_property_full (self, "status",
      target, target_property,
      G_BINDING_SYNC_CREATE,
      _tp_bind_connection_status_to_boolean,
      NULL, GUINT_TO_POINTER (invert), NULL);
}

/**
 * tp_connection_get_balance:
 * @self: a #TpConnection
 * @balance: (out): a pointer to store the account balance (or %NULL)
 * @scale: (out): a pointer to store the balance scale (or %NULL)
 * @currency: (out) (transfer none): a pointer to store the balance
 *   currency (or %NULL)
 *
 * If @self has a valid account balance, returns %TRUE and sets the variables
 * pointed to by @balance, @scale and @currency to the appropriate fields
 * of the Balance.AccountBalance property.
 *
 * The monetary value of the balance is expressed as a fixed-point number,
 * @balance, with a decimal scale defined by @scale; for instance a @balance
 * of 1234 with @scale of 2 represents a value of "12.34" in the currency
 * represented by @currency.
 *
 * Requires %TP_CONNECTION_FEATURE_BALANCE to be prepared.
 *
 * Returns: %TRUE if the balance is valid (and the values set), %FALSE if the
 *   balance is invalid.
 * Since: 0.15.1
 */
gboolean
tp_connection_get_balance (TpConnection *self,
    gint *balance,
    guint *scale,
    const gchar **currency)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  if (self->priv->balance_currency == NULL)
    return FALSE;

  if (self->priv->balance == 0 &&
      self->priv->balance_scale == G_MAXUINT32 &&
      tp_str_empty (self->priv->balance_currency))
    return FALSE;

  if (balance != NULL)
    *balance = self->priv->balance;

  if (scale != NULL)
    *scale = self->priv->balance_scale;

  if (currency != NULL)
    *currency = self->priv->balance_currency;

  return TRUE;
}

/**
 * tp_connection_get_balance_uri:
 * @self: a #TpConnection
 *
 * The value of Balance.ManageCreditURI.
 *
 * Requires %TP_CONNECTION_FEATURE_BALANCE to be prepared.
 *
 * Returns: (transfer none): the #TpConnection:balance-uri property.
 * Since: 0.15.1
 */
const gchar *
tp_connection_get_balance_uri (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  return self->priv->balance_uri;
}

static void
_tp_connection_void_cb (TpConnection *proxy,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = G_SIMPLE_ASYNC_RESULT (user_data);

  if (error != NULL)
    g_simple_async_result_set_from_error (result, error);

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (G_OBJECT (result));
}

/**
 * tp_connection_disconnect_async:
 * @self: a #TpConnection
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Disconnect the connection.
 *
 * This method is intended for use by AccountManager implementations,
 * such as Mission Control. To disconnect a connection managed by an
 * AccountManager, either use tp_account_request_presence_async()
 * or tp_account_set_enabled_async(), depending whether the intention is
 * to put the account offline temporarily, or disable it longer-term.
 *
 * Since: 0.17.5
 */
void
tp_connection_disconnect_async (TpConnection *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  g_return_if_fail (TP_IS_CONNECTION (self));

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_connection_disconnect_async);

  tp_cli_connection_call_disconnect (self, -1, _tp_connection_void_cb, result,
      NULL, NULL);
}

/**
 * tp_connection_disconnect_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Interpret the result of tp_connection_disconnect_async().
 *
 * Returns: %TRUE if the call was successful, otherwise %FALSE
 *
 * Since: 0.17.5
 */
gboolean
tp_connection_disconnect_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_connection_disconnect_async);
}
