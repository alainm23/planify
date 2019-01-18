/*
 * debug-client.c - proxy for Telepathy debug objects
 *
 * Copyright © 2010 Collabora Ltd. <http://www.collabora.co.uk/>
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

#include <telepathy-glib/debug-client.h>
#include <telepathy-glib/debug-message-internal.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_DEBUGGER
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/proxy-internal.h"
#include "telepathy-glib/util-internal.h"

#include "telepathy-glib/_gen/tp-cli-debug-body.h"

/**
 * SECTION:debug-client
 * @title: TpDebugClient
 * @short_description: proxy objects for Telepathy debug information
 * @see_also: #TpProxy
 *
 * This module provides access to the auxiliary objects used to
 * implement #TpSvcDebug.
 *
 * Since: 0.19.0
 */

/**
 * TpDebugClientClass:
 *
 * The class of a #TpDebugClient.
 *
 * Since: 0.19.0
 */
struct _TpDebugClientClass {
    TpProxyClass parent_class;
    /*<private>*/
    gpointer priv;
};

/**
 * TpDebugClient:
 *
 * A proxy object for the debug interface of a Telepathy component.
 *
 * Since: 0.19.0
 */
struct _TpDebugClient {
    TpProxy parent;
    /*<private>*/
    TpDebugClientPrivate *priv;
};

struct _TpDebugClientPrivate {
    gboolean enabled;
};

static const TpProxyFeature *tp_debug_client_list_features (
    TpProxyClass *klass);
static void tp_debug_client_prepare_core (TpDebugClient *self);
static void name_owner_changed_cb (TpDBusDaemon *bus,
    const gchar *name,
    const gchar *new_owner,
    gpointer user_data);

G_DEFINE_TYPE (TpDebugClient, tp_debug_client, TP_TYPE_PROXY)

enum
{
  PROP_ENABLED = 1
};

enum {
  SIG_NEW_DEBUG_MESSAGE,
  LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

static void
tp_debug_client_init (TpDebugClient *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_DEBUG_CLIENT,
      TpDebugClientPrivate);
}

static void
tp_debug_client_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpDebugClient *self = TP_DEBUG_CLIENT (object);

  switch (property_id)
    {
      case PROP_ENABLED:
        g_value_set_boolean (value, self->priv->enabled);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
new_debug_message_cb (TpDebugClient *self,
    gdouble timestamp,
    const gchar *domain,
    TpDebugLevel level,
    const gchar *message,
    gpointer user_data,
    GObject *weak_object)
{
  TpDebugMessage *msg;

  msg = _tp_debug_message_new (timestamp, domain, level, message);

  g_signal_emit (self, signals[SIG_NEW_DEBUG_MESSAGE], 0, msg);
  g_object_unref (msg);
}

static void
tp_debug_client_constructed (GObject *object)
{
  TpDebugClient *self = TP_DEBUG_CLIENT (object);
  TpProxy *proxy = TP_PROXY (object);
  GObjectClass *parent_class = G_OBJECT_CLASS (tp_debug_client_parent_class);
  GError *error = NULL;

  if (parent_class->constructed != NULL)
    parent_class->constructed (object);

  tp_dbus_daemon_watch_name_owner (
      tp_proxy_get_dbus_daemon (proxy), tp_proxy_get_bus_name (proxy),
      name_owner_changed_cb, object, NULL);
  tp_debug_client_prepare_core (self);

  if (!tp_cli_debug_connect_to_new_debug_message (self, new_debug_message_cb,
        NULL, NULL, NULL, &error))
    {
      WARNING ("Failed to connect to NewDebugMessage: %s", error->message);
      g_error_free (error);
    }
}

static void
tp_debug_client_dispose (GObject *object)
{
  TpProxy *proxy = TP_PROXY (object);
  GObjectClass *parent_class = G_OBJECT_CLASS (tp_debug_client_parent_class);

  tp_dbus_daemon_cancel_name_owner_watch (
      tp_proxy_get_dbus_daemon (proxy), tp_proxy_get_bus_name (proxy),
      name_owner_changed_cb, object);

  if (parent_class->dispose != NULL)
    parent_class->dispose (object);
}

static void
tp_debug_client_class_init (TpDebugClientClass *klass)
{
  GObjectClass *object_class = (GObjectClass *) klass;
  TpProxyClass *proxy_class = (TpProxyClass *) klass;
  GParamSpec *spec;

  object_class->get_property = tp_debug_client_get_property;
  object_class->constructed = tp_debug_client_constructed;
  object_class->dispose = tp_debug_client_dispose;

  proxy_class->must_have_unique_name = TRUE;
  proxy_class->interface = TP_IFACE_QUARK_DEBUG;
  proxy_class->list_features = tp_debug_client_list_features;

  /**
   * TpDebugClient:enabled:
   *
   * %TRUE if debug messages are published on the bus.
   *
   * This property is meaningless until the
   * %TP_DEBUG_CLIENT_FEATURE_CORE feature has been prepared.
   *
   * Since: 0.19.0
   */
  spec = g_param_spec_boolean ("enabled", "enabled",
      "Enabled",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ENABLED, spec);

  /**
   * TpDebugClient::new-debug-message:
   * @self: a #TpDebugClient
   * @message: a #TpDebugMessage
   *
   * Emitted when a #TpDebugMessage is generated if the TpDebugMessage:enabled
   * property is set to %TRUE.
   *
   * Since: 0.19.0
   */
  signals[SIG_NEW_DEBUG_MESSAGE] = g_signal_new ("new-debug-message",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      1, TP_TYPE_DEBUG_MESSAGE);

  g_type_class_add_private (klass, sizeof (TpDebugClientPrivate));
  tp_debug_client_init_known_interfaces ();
}

GQuark
tp_debug_client_get_feature_quark_core (void)
{
  return g_quark_from_static_string ("tp-debug-client-feature-core");
}

static void
name_owner_changed_cb (
    TpDBusDaemon *bus,
    const gchar *name,
    const gchar *new_owner,
    gpointer user_data)
{
  TpDebugClient *self = TP_DEBUG_CLIENT (user_data);

  if (tp_str_empty (new_owner))
    {
      GError *error = g_error_new (TP_DBUS_ERRORS,
          TP_DBUS_ERROR_NAME_OWNER_LOST,
          "%s fell off the bus", name);

      DEBUG ("%s fell off the bus", name);
      tp_proxy_invalidate (TP_PROXY (self), error);
      g_error_free (error);
    }
}

static void
got_enabled_cb (
    TpProxy *proxy,
    const GValue *value,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpDebugClient *self = TP_DEBUG_CLIENT (proxy);

  if (error != NULL)
    {
      tp_proxy_invalidate (proxy, error);
    }
  else if (!G_VALUE_HOLDS_BOOLEAN (value))
    {
      GError *e = g_error_new (TP_ERROR,
          TP_ERROR_NOT_IMPLEMENTED,
          "this service doesn't implement the Debug interface correctly "
          "(the Enabled property is not a boolean, but a %s)",
          G_VALUE_TYPE_NAME (value));

      tp_proxy_invalidate (proxy, e);
      g_error_free (e);
    }
  else
    {
      self->priv->enabled = g_value_get_boolean (value);
      /* FIXME: we have no change notification for Enabled. */
      _tp_proxy_set_feature_prepared (proxy, TP_DEBUG_CLIENT_FEATURE_CORE,
          TRUE);
    }
}

static void
tp_debug_client_prepare_core (TpDebugClient *self)
{
  tp_cli_dbus_properties_call_get (self, -1, TP_IFACE_DEBUG, "Enabled",
      got_enabled_cb, NULL, NULL, NULL);
}

static const TpProxyFeature *
tp_debug_client_list_features (TpProxyClass *klass)
{
  static gsize once = 0;
  static TpProxyFeature features[] = {
      { 0, TRUE },
      { 0 }
  };

  if (g_once_init_enter (&once))
    {
      features[0].name = TP_DEBUG_CLIENT_FEATURE_CORE;
      g_once_init_leave (&once, 1);
    }

  return features;
}

/**
 * tp_debug_client_init_known_interfaces:
 *
 * Ensure that the known interfaces for TpDebugClient have been set up.
 * This is done automatically when necessary, but for correct
 * overriding of library interfaces by local extensions, you should
 * call this function before calling
 * tp_proxy_or_subclass_hook_on_interface_add() with first argument
 * %TP_TYPE_DEBUG_CLIENT.
 *
 * Since: 0.19.0
 */
void
tp_debug_client_init_known_interfaces (void)
{
  static gsize once = 0;

  if (g_once_init_enter (&once))
    {
      GType tp_type = TP_TYPE_DEBUG_CLIENT;

      tp_proxy_init_known_interfaces ();
      tp_proxy_or_subclass_hook_on_interface_add (tp_type,
          tp_cli_debug_add_signals);
      tp_proxy_subclass_add_error_mapping (tp_type,
          TP_ERROR_PREFIX, TP_ERROR, TP_TYPE_ERROR);

      g_once_init_leave (&once, 1);
    }
}

/**
 * tp_debug_client_new:
 * @dbus: a D-Bus daemon; may not be %NULL
 * @unique_name: the unique name of the process to be debugged; may not be
 *  %NULL or a well-known name
 * @error: used to raise an error if @unique_name is not valid
 *
 * <!-- -->
 *
 * Returns: a new debug client proxy, or %NULL on invalid arguments
 *
 * Since: 0.19.0
 */
TpDebugClient *
tp_debug_client_new (
    TpDBusDaemon *dbus,
    const gchar *unique_name,
    GError **error)
{
  if (!tp_dbus_check_valid_bus_name (unique_name,
          TP_DBUS_NAME_TYPE_UNIQUE, error))
    return NULL;

  return TP_DEBUG_CLIENT (g_object_new (TP_TYPE_DEBUG_CLIENT,
      "dbus-daemon", dbus,
      "bus-name", unique_name,
      "object-path", TP_DEBUG_OBJECT_PATH,
      NULL));
}

static void
set_enabled_cb (
    TpProxy *proxy,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = G_SIMPLE_ASYNC_RESULT (user_data);

  if (error != NULL)
    g_simple_async_result_set_from_error (result, error);

  g_simple_async_result_complete (result);
}

/**
 * tp_debug_client_set_enabled_async:
 * @self: a #TpDebugClient
 * @enabled: %TRUE if debug messages should be published on the bus, %FALSE
 * otherwise
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Enable or disable publishing of debug messages on the bus by the component
 * owning @self's bus name.
 *
 * Since: 0.19.0
 */
void
tp_debug_client_set_enabled_async (
    TpDebugClient *self,
    gboolean enabled,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data, tp_debug_client_set_enabled_async);
  GValue v = { 0, };

  g_value_init (&v, G_TYPE_BOOLEAN);
  g_value_set_boolean (&v, enabled);
  tp_cli_dbus_properties_call_set (self, -1, TP_IFACE_DEBUG, "Enabled", &v,
      set_enabled_cb, result, g_object_unref, NULL);
  g_value_unset (&v);
}

/**
 * tp_debug_client_set_enabled_finish:
 * @self: a #TpDebugClient
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_debug_client_set_enabled_async().
 *
 * Returns: %TRUE, if the operation suceeded, %FALSE otherwise
 * Since: 0.19.0
 */
gboolean
tp_debug_client_set_enabled_finish (
    TpDebugClient *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_debug_client_set_enabled_async)
}

/**
 * tp_debug_client_is_enabled:
 * @self: a #TpDebugClient
 *
 * Return the #TpDebugClient:enabled property
 *
 * Returns: the value of #TpDebugClient:enabled property
 *
 * Since: 0.19.0
 */
gboolean
tp_debug_client_is_enabled (TpDebugClient *self)
{
  return self->priv->enabled;
}

static void
get_messages_cb (TpDebugClient *self,
    const GPtrArray *messages,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;
  guint i;
  GPtrArray *messages_arr;

  if (error != NULL)
    {
      DEBUG ("GetMessages() failed: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
      goto out;
    }

  messages_arr = g_ptr_array_new_with_free_func (g_object_unref);

  for (i = 0; i < messages->len; i++)
    {
      TpDebugMessage *msg;
      gdouble timestamp;
      const gchar *domain, *message;
      TpDebugLevel level;

      tp_value_array_unpack (g_ptr_array_index (messages, i), 4,
          &timestamp, &domain, &level, &message);

      msg = _tp_debug_message_new (timestamp, domain, level, message);

      g_ptr_array_add (messages_arr, msg);
    }

  g_simple_async_result_set_op_res_gpointer (result, messages_arr,
      (GDestroyNotify) g_ptr_array_unref);

out:
  g_simple_async_result_complete (result);
}

/**
 * tp_debug_client_get_messages_async:
 * @self: a #TpDebugClient
 * @callback: callback to call when the messages have been retrieved
 * @user_data: data to pass to @callback
 *
 * Retrieve buffered messages from @self. Once @callback is called,
 * use tp_debug_client_get_messages_finish() to retrieve the #TpDebugMessage
 * objects.
 *
 * Since: 0.19.0
 */
void
tp_debug_client_get_messages_async (
    TpDebugClient *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data, tp_debug_client_set_enabled_async);

  tp_cli_debug_call_get_messages (self, -1, get_messages_cb,
      result, g_object_unref, NULL);
}

/**
 * tp_debug_client_get_messages_finish:
 * @self: a #TpDebugClient
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_debug_client_set_enabled_async().
 *
 * Returns: (transfer container) (type GLib.PtrArray) (element-type TelepathyGLib.DebugMessage):
 * a #GPtrArray of #TpDebugMessage, free with g_ptr_array_unref()
 *
 * Since: 0.19.0
 */
GPtrArray *
tp_debug_client_get_messages_finish (TpDebugClient *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_debug_client_set_enabled_async, g_ptr_array_ref)
}
