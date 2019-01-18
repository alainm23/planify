/*
 * base-connection.c - Source for TpBaseConnection
 *
 * Copyright © 2005-2010 Collabora Ltd.
 * Copyright © 2005-2009 Nokia Corporation
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
 * SECTION:base-connection
 * @title: TpBaseConnection
 * @short_description: base class for #TpSvcConnection implementations
 * @see_also: #TpBaseConnectionManager, #TpSvcConnection
 *
 * This base class makes it easier to write #TpSvcConnection implementations
 * by managing connection status, channel factories and handle tracking.
 * A subclass should often not need to implement any of the Connection
 * methods itself.
 *
 * However, methods may be reimplemented if needed: for instance, Gabble
 * overrides RequestHandles so it can validate MUC rooms, which must be done
 * asynchronously.
 */

/**
 * TpBaseConnectionProc:
 * @self: The connection object
 *
 * Signature of a virtual method on #TpBaseConnection that takes no
 * additional parameters and returns nothing.
 */

/**
 * TpBaseConnectionStartConnectingImpl:
 * @self: The connection object
 * @error: Set to the error if %FALSE is returned
 *
 * Signature of an implementation of the start_connecting method
 * of #TpBaseConnection.
 *
 * On entry, the implementation may assume that it is in state NEW.
 *
 * If %TRUE is returned, the Connect D-Bus method succeeds; the
 * implementation must either have already set the status to CONNECTED by
 * calling tp_base_connection_change_status(), or have arranged for a
 * status change to either state DISCONNECTED or CONNECTED to be signalled by
 * calling tp_base_connection_change_status() at some later time.
 * If the status is still NEW after returning %TRUE, #TpBaseConnection will
 * automatically change it to CONNECTING for reason REQUESTED.
 *
 * If %FALSE is returned, the error will be raised from Connect as an
 * exception. If the status is not DISCONNECTED after %FALSE is returned,
 * #TpBaseConnection will automatically change it to DISCONNECTED
 * with a reason appropriate to the error; NetworkError results in
 * NETWORK_ERROR, PermissionDenied results in AUTHENTICATION_FAILED, and all
 * other errors currently result in NONE_SPECIFIED.
 *
 * All except the simplest connection managers are expected to implement this
 * asynchronously, returning %TRUE in most cases and changing the status
 * to CONNECTED or DISCONNECTED later.
 *
 * Returns: %FALSE if failure has already occurred, else %TRUE.
 */

/**
 * TpBaseConnectionCreateHandleReposImpl: (skip)
 * @self: The connection object
 * @repos: An array of pointers to be filled in; the implementation
 *         may assume all are initially NULL.
 *
 * Signature of an implementation of the create_handle_repos method
 * of #TpBaseConnection.
 */

/**
 * TpBaseConnectionCreateChannelFactoriesImpl:
 * @self: The implementation, a subclass of TpBaseConnection
 *
 * Signature of an implementation of the create_channel_factories method
 * of #TpBaseConnection.
 *
 * Returns: (transfer full): a GPtrArray of objects implementing
 *  #TpChannelFactoryIface which, between them, implement all channel types
 *  this Connection supports.
 */

/**
 * TpBaseConnectionCreateChannelManagersImpl:
 * @self: The implementation, a subclass of TpBaseConnection
 *
 * Signature of an implementation of the create_channel_managers method
 * of #TpBaseConnection.
 *
 * Returns: (transfer full): a GPtrArray of objects implementing
 *  #TpChannelManager which, between them, implement all channel types this
 *  Connection supports.
 */

/**
 * TpBaseConnectionGetUniqueConnectionNameImpl:
 * @self: The implementation, a subclass of TpBaseConnection
 *
 * Signature of the @get_unique_connection_name virtual method
 * on #TpBaseConnection.
 *
 * Returns: (transfer full): a name for this connection which will be unique
 *  within this connection manager process, as a string which the caller must
 *  free with #g_free.
 */

/**
 * TpBaseConnectionGetInterfacesImpl:
 * @self: a #TpBaseConnection
 *
 * Signature of an implementation of
 * #TpBaseConnectionClass.get_interfaces_always_present virtual
 * function.
 *
 * Implementation must first chainup on parent class implementation and then
 * add extra interfaces into the #GPtrArray.
 *
 * |[
 * static GPtrArray *
 * my_connection_get_interfaces_always_present (TpBaseConnection *self)
 * {
 *   GPtrArray *interfaces;
 *
 *   interfaces = TP_BASE_CONNECTION_CLASS (
 *       my_connection_parent_class)->get_interfaces_always_present (self);
 *
 *   g_ptr_array_add (interfaces, TP_IFACE_BADGERS);
 *
 *   return interfaces;
 * }
 * ]|
 *
 * Returns: (transfer container): a #GPtrArray of static strings for D-Bus
 *   interfaces implemented by this client.
 *
 * Since: 0.19.4
 */

/**
 * TpBaseConnectionClass:
 * @parent_class: The superclass' structure
 * @create_handle_repos: Fill in suitable handle repositories in the
 *  given array for all those handle types this Connection supports.
 *  Must be set by subclasses to a non-%NULL value; the function must create
 *  at least a CONTACT handle repository (failing to do so will cause a crash).
 * @create_channel_factories: Create an array of channel factories for this
 *  Connection. At least one of this or @create_channel_managers must be set by
 *  subclasses to a non-%NULL value; in new code, setting this to %NULL and
 *  using channel managers exclusively is recommended.
 * @get_unique_connection_name: Construct a unique name for this connection
 *  (for example using the protocol's format for usernames). If %NULL (the
 *  default), a unique name will be generated. Subclasses should usually
 *  override this to get more obvious names, to aid debugging and prevent
 *  multiple connections to the same account.
 * @connecting: If set by subclasses, will be called just after the state
 *  changes to CONNECTING. May be %NULL if nothing special needs to happen.
 * @connected: If set by subclasses, will be called just after the state
 *  changes to CONNECTED. May be %NULL if nothing special needs to happen.
 * @disconnected: If set by subclasses, will be called just after the state
 *  changes to DISCONNECTED. May be %NULL if nothing special needs to happen.
 * @shut_down: Called after disconnected() is called, to clean up the
 *  connection. Must start the shutdown process for the underlying
 *  network connection, and arrange for tp_base_connection_finish_shutdown()
 *  to be called after the underlying connection has been closed. May not
 *  be left as %NULL.
 * @start_connecting: Asynchronously start connecting - called to implement
 *  the Connect D-Bus method. See #TpBaseConnectionStartConnectingImpl for
 *  details. May not be left as %NULL.
 * @get_interfaces_always_present: Returns a #GPtrArray of extra D-Bus
 *  interfaces which are always implemented by instances of this class,
 *  which may be filled in by subclasses. The default is to list no
 *  additional interfaces. Individual instances may detect which
 *  additional interfaces they support and signal them before going
 *  to state CONNECTED by calling tp_base_connection_add_interfaces().
 * @create_channel_managers: Create an array of channel managers for this
 *  Connection. At least one of this or @create_channel_factories must be set
 *  by subclasses to a non-%NULL value. Since: 0.7.15
 *
 * The class of a #TpBaseConnection. Many members are virtual methods etc.
 * to be filled in in the subclass' class_init function.
 */

/**
 * TP_INTERNAL_CONNECTION_STATUS_NEW: (skip)
 *
 * A special value for #TpConnectionStatus, used within GLib connection
 * managers to indicate that the connection is disconnected because
 * connection has never been attempted (as distinct from disconnected
 * after connection has started, either by user request or an error).
 *
 * Must never be visible on the D-Bus - %TP_CONNECTION_STATUS_DISCONNECTED
 * is sent instead.
 */

/**
 * TpBaseConnection:
 *
 * Data structure representing a generic #TpSvcConnection implementation.
 *
 * Since 0.19.1, accessing the fields of this structure is deprecated.
 * Use tp_base_connection_get_bus_name(), tp_base_connection_get_object_path(),
 * tp_base_connection_get_status(), tp_base_connection_get_self_handle()
 * instead.
 */

/**
 * TpChannelManagerIter: (skip)
 *
 * An iterator over the #TpChannelManager objects known to a #TpBaseConnection.
 * It has no public fields.
 *
 * Use tp_base_connection_channel_manager_iter_init() to start iteration and
 * tp_base_connection_channel_manager_iter_next() to continue.
 *
 * Since: 0.7.15
 */

/**
 * TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED: (skip)
 * @conn: A TpBaseConnection
 * @context: A DBusGMethodInvocation
 *
 * If @conn is not in state #TP_CONNECTION_STATUS_CONNECTED, complete the
 * D-Bus method invocation @context by raising the Telepathy error
 * #TP_ERROR_DISCONNECTED, and return from the current function (which
 * must be void). For use in D-Bus method implementations.
 */

#include "config.h"

#include <telepathy-glib/base-connection.h>
#include <telepathy-glib/base-connection-internal.h>

#include <string.h>

#include <dbus/dbus-glib-lowlevel.h>

#include <telepathy-glib/channel-factory-iface.h>
#include <telepathy-glib/channel-manager.h>
#include <telepathy-glib/connection-manager.h>
#include <telepathy-glib/contacts-mixin.h>
#include <telepathy-glib/dbus-properties-mixin.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-internal.h>
#include <telepathy-glib/exportable-channel.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/svc-generic.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CONNECTION
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/variant-util-internal.h"

static void conn_iface_init (gpointer, gpointer);
static void requests_iface_init (gpointer, gpointer);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE(TpBaseConnection,
    tp_base_connection,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CONNECTION,
      conn_iface_init);
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_DBUS_PROPERTIES,
      tp_dbus_properties_mixin_iface_init);
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CONNECTION_INTERFACE_REQUESTS,
      requests_iface_init))

enum
{
    PROP_PROTOCOL = 1,
    PROP_SELF_HANDLE,
    PROP_SELF_ID,
    PROP_INTERFACES,
    PROP_DBUS_STATUS,
    PROP_DBUS_DAEMON,
    PROP_HAS_IMMORTAL_HANDLES,
    PROP_ACCOUNT_PATH_SUFFIX,
    N_PROPS
};

/* signal enum */
enum
{
    INVALID_SIGNAL,
    SHUTDOWN_FINISHED,
    CLIENTS_INTERESTED,
    CLIENTS_UNINTERESTED,
    N_SIGNALS
};

static guint signals[N_SIGNALS] = {0};

typedef struct _ChannelRequest ChannelRequest;

typedef enum {
    METHOD_REQUEST_CHANNEL,
    METHOD_CREATE_CHANNEL,
    METHOD_ENSURE_CHANNEL,
    NUM_METHODS
} ChannelRequestMethod;

struct _ChannelRequest
{
  DBusGMethodInvocation *context;
  ChannelRequestMethod method;

  gchar *channel_type;
  guint handle_type;
  guint handle;
  /* always TRUE for CREATE; always FALSE for ENSURE */
  unsigned suppress_handler : 1;

  /* only meaningful for METHOD_ENSURE_CHANNEL; only true if this is the first
   * request to be satisfied with a particular channel, and no other request
   * satisfied by that channel has a different method.
   */
  unsigned yours : 1;
};

static ChannelRequest *
channel_request_new (DBusGMethodInvocation *context,
                     ChannelRequestMethod method,
                     const char *channel_type,
                     guint handle_type,
                     guint handle,
                     gboolean suppress_handler)
{
  ChannelRequest *ret;

  g_assert (NULL != context);
  g_assert (NULL != channel_type);
  g_assert (method < NUM_METHODS);

  ret = g_slice_new0 (ChannelRequest);
  ret->context = context;
  ret->method = method;
  ret->channel_type = g_strdup (channel_type);
  ret->handle_type = handle_type;
  ret->handle = handle;
  ret->suppress_handler = suppress_handler;
  ret->yours = FALSE;

  DEBUG("New channel request at %p: ctype=%s htype=%d handle=%d suppress=%d",
        ret, channel_type, handle_type, handle, suppress_handler);

  return ret;
}

static void
channel_request_free (ChannelRequest *request)
{
  g_assert (NULL == request->context);
  DEBUG("Freeing channel request at %p: ctype=%s htype=%d handle=%d "
        "suppress=%d", request, request->channel_type, request->handle_type,
        request->handle, request->suppress_handler);
  g_free (request->channel_type);
  g_slice_free (ChannelRequest, request);
}

static void
channel_request_cancel (gpointer data, gpointer user_data)
{
  ChannelRequest *request = (ChannelRequest *) data;
  GError error = { TP_ERROR, TP_ERROR_DISCONNECTED,
      "unable to service this channel request, we're disconnecting!" };

  DEBUG ("cancelling request at %p for %s/%u/%u", request,
      request->channel_type, request->handle_type, request->handle);

  dbus_g_method_return_error (request->context, &error);
  request->context = NULL;

  channel_request_free (request);
}

struct _TpBaseConnectionPrivate
{
  const gchar *self_id;

  /* Telepathy properties */
  gchar *protocol;

  /* if TRUE, the object has gone away */
  gboolean dispose_has_run;
  /* array of (TpChannelFactoryIface *) */
  GPtrArray *channel_factories;
  /* array of (TpChannelManager *) */
  GPtrArray *channel_managers;
  /* array of (ChannelRequest *) */
  GPtrArray *channel_requests;

  TpHandleRepoIface *handles[TP_NUM_HANDLE_TYPES];

  /* Created in constructed, this is an array of static strings which
   * represent the interfaces on this connection.
   *
   * Note that this is a GArray of gchar*, not a GPtrArray,
   * so that we can use GArray's convenient auto-null-termination. */
  GArray *interfaces;

  /* Array of DBusGMethodInvocation * representing Disconnect calls.
   * If NULL and we are in a state != DISCONNECTED, then we have not started
   * shutting down yet.
   * If NULL and we are in state DISCONNECTED, then we have finished shutting
   * down.
   * If not NULL, we are trying to shut down (and must be in state
   * DISCONNECTED). */
  GPtrArray *disconnect_requests;

  TpDBusDaemon *bus_proxy;
  /* TRUE after constructor() returns */
  gboolean been_constructed;
  /* TRUE if on D-Bus */
  gboolean been_registered;

  /* g_strdup (unique name) => gsize total count
   *
   * This is derivable from @client_interests: e.g. if
   *    client_interests = { LOCATION => { ":1.23" => 5, ":1.42" => 2 },
   *                         MAIL_NOTIFICATION => { ":1.23" => 1 } }
   * then it implies
   *    interested_clients = { ":1.23" => 6, ":1.42" => 2 }
   */
  GHashTable *interested_clients;
  /* GQuark iface => GHashTable {
   *    unique name borrowed from interested_clients => gsize count } */
  GHashTable *client_interests;

  gchar *account_path_suffix;
};

static const gchar * const *tp_base_connection_get_interfaces (
    TpBaseConnection *self);

static gboolean
tp_base_connection_ensure_dbus (TpBaseConnection *self,
    GError **error)
{
  if (self->priv->bus_proxy == NULL)
    {
      self->priv->bus_proxy = tp_dbus_daemon_dup (error);

      if (self->priv->bus_proxy == NULL)
        return FALSE;
    }

  return TRUE;
}

static void
tp_base_connection_get_property (GObject *object,
                                 guint property_id,
                                 GValue *value,
                                 GParamSpec *pspec)
{
  TpBaseConnection *self = (TpBaseConnection *) object;
  TpBaseConnectionPrivate *priv = self->priv;

  switch (property_id)
    {
    case PROP_PROTOCOL:
      g_value_set_string (value, priv->protocol);
      break;

    case PROP_SELF_HANDLE:
      g_value_set_uint (value, self->self_handle);
      break;

    case PROP_SELF_ID:
      g_value_set_string (value, self->priv->self_id);
      break;

    case PROP_INTERFACES:
      g_value_set_boxed (value, tp_base_connection_get_interfaces (self));
      break;

    case PROP_DBUS_STATUS:
      g_value_set_uint (value, tp_base_connection_get_status (self));
      break;

    case PROP_DBUS_DAEMON:
      g_value_set_object (value, self->priv->bus_proxy);
      break;

    case PROP_HAS_IMMORTAL_HANDLES:
      g_value_set_boolean (value, TRUE);
      break;

    case PROP_ACCOUNT_PATH_SUFFIX:
      g_value_set_string (value, self->priv->account_path_suffix);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
tp_base_connection_set_property (GObject      *object,
                                 guint         property_id,
                                 const GValue *value,
                                 GParamSpec   *pspec)
{
  TpBaseConnection *self = (TpBaseConnection *) object;
  TpBaseConnectionPrivate *priv = self->priv;

  switch (property_id) {
    case PROP_PROTOCOL:
      g_free (priv->protocol);
      priv->protocol = g_value_dup_string (value);
      g_assert (priv->protocol != NULL);
      break;

    case PROP_SELF_HANDLE:
      tp_base_connection_set_self_handle (self, g_value_get_uint (value));
      break;

    case PROP_DBUS_DAEMON:
        {
          TpDBusDaemon *dbus_daemon = g_value_get_object (value);

          g_assert (self->priv->bus_proxy == NULL);     /* construct-only */

          if (dbus_daemon != NULL)
            self->priv->bus_proxy = g_object_ref (dbus_daemon);
        }
      break;

    case PROP_ACCOUNT_PATH_SUFFIX:
      g_assert (self->priv->account_path_suffix == NULL); /* construct-only */
      self->priv->account_path_suffix = g_value_dup_string (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}

static void tp_base_connection_interested_name_owner_changed_cb (
    TpDBusDaemon *it,
    const gchar *unique_name,
    const gchar *new_owner,
    gpointer user_data);

static void
tp_base_connection_unregister (TpBaseConnection *self)
{
  TpBaseConnectionPrivate *priv = self->priv;

  if (priv->bus_proxy != NULL)
    {
      GHashTableIter iter;
      gpointer k;

      if (priv->been_registered)
        {
          tp_dbus_daemon_unregister_object (priv->bus_proxy, self);

          if (self->bus_name != NULL)
            tp_dbus_daemon_release_name (priv->bus_proxy, self->bus_name, NULL);

          priv->been_registered = FALSE;
        }

      g_hash_table_iter_init (&iter, self->priv->interested_clients);

      while (g_hash_table_iter_next (&iter, &k, NULL))
        {
          tp_dbus_daemon_cancel_name_owner_watch (priv->bus_proxy, k,
              tp_base_connection_interested_name_owner_changed_cb, self);
          g_hash_table_iter_remove (&iter);
        }
    }
}

static void
tp_base_connection_dispose (GObject *object)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (object);
  TpBaseConnectionPrivate *priv = self->priv;
  guint i;

  if (priv->dispose_has_run)
    return;

  priv->dispose_has_run = TRUE;

  g_assert ((self->status == TP_CONNECTION_STATUS_DISCONNECTED) ||
            (self->status == TP_INTERNAL_CONNECTION_STATUS_NEW));

  tp_base_connection_unregister (self);

  tp_clear_object (&priv->bus_proxy);

  g_ptr_array_foreach (priv->channel_factories, (GFunc) g_object_unref, NULL);
  g_ptr_array_unref (priv->channel_factories);
  priv->channel_factories = NULL;

  g_ptr_array_foreach (priv->channel_managers, (GFunc) g_object_unref, NULL);
  g_ptr_array_unref (priv->channel_managers);
  priv->channel_managers = NULL;

  if (priv->channel_requests)
    {
      g_assert (priv->channel_requests->len == 0);
      g_ptr_array_unref (priv->channel_requests);
      priv->channel_requests = NULL;
    }

  for (i = 0; i < TP_NUM_HANDLE_TYPES; i++)
    tp_clear_object (priv->handles + i);

  if (priv->interfaces)
    {
      g_array_unref (priv->interfaces);
    }

  if (G_OBJECT_CLASS (tp_base_connection_parent_class)->dispose)
    G_OBJECT_CLASS (tp_base_connection_parent_class)->dispose (object);
}

static void
tp_base_connection_finalize (GObject *object)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (object);
  TpBaseConnectionPrivate *priv = self->priv;

  g_free (priv->protocol);
  g_free (self->bus_name);
  g_free (self->object_path);
  g_hash_table_unref (priv->client_interests);
  g_hash_table_unref (priv->interested_clients);
  g_free (priv->account_path_suffix);

  G_OBJECT_CLASS (tp_base_connection_parent_class)->finalize (object);
}


/**
 * exportable_channel_get_old_info:
 * @channel: a channel
 * @object_path_out:  address at which to store the channel's object path,
 *                    which the caller should g_free()
 * @channel_type_out: address at which to store the channel's type, which the
 *                    caller should g_free()
 * @handle_type_out:  address at which to store the channel's associated handle
 *                    type
 * @handle_out:       address at which to store the channel's associated
 *                    handle, if any.  This is a borrowed reference; the caller
 *                    does not need to tp_handle_unref() it.
 *
 * Given a new-style exportable channel, as used by the Requests interface's
 * API, fetches the information needed for the old-style ListChannels method
 * on Connections.
 */
static void
exportable_channel_get_old_info (TpExportableChannel *channel,
                                 gchar **object_path_out,
                                 gchar **channel_type_out,
                                 guint *handle_type_out,
                                 guint *handle_out)
{
  gchar *object_path;
  GHashTable *channel_properties;
  gboolean valid;

  g_object_get (channel,
      "object-path", &object_path,
      "channel-properties", &channel_properties,
      NULL);

  g_assert (object_path != NULL);
  g_assert (tp_dbus_check_valid_object_path (object_path, NULL));

  if (object_path_out != NULL)
    *object_path_out = object_path;
  else
    g_free (object_path);

  if (channel_type_out != NULL)
    {
      *channel_type_out = g_strdup (tp_asv_get_string (channel_properties,
          TP_PROP_CHANNEL_CHANNEL_TYPE));
      g_assert (*channel_type_out != NULL);
      g_assert (tp_dbus_check_valid_interface_name (*channel_type_out, NULL));
    }

  if (handle_type_out != NULL)
    {
      *handle_type_out = tp_asv_get_uint32 (channel_properties,
          TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, &valid);
      g_assert (valid);
    }

  if (handle_out != NULL)
    {
      *handle_out = tp_asv_get_uint32 (channel_properties,
          TP_PROP_CHANNEL_TARGET_HANDLE, &valid);
      g_assert (valid);

      if (handle_type_out != NULL)
        {
          if (*handle_type_out == TP_HANDLE_TYPE_NONE)
            g_assert (*handle_out == 0);
          else
            g_assert (*handle_out != 0);
        }
    }

  g_hash_table_unref (channel_properties);
}


/*
 * get_channel_details:
 * @obj: a channel, which must implement one of #TpExportableChannel and
 *       #TpChannelIface
 *
 * Returns: (oa{sv}: o.fd.T.Conn.Iface.Requests.Channel_Details), suitable for
 *          inclusion in the NewChannels signal.
 */
static GValueArray *
get_channel_details (GObject *obj)
{
  GValueArray *structure;
  GHashTable *table;
  GValue *value;
  gchar *object_path;

  g_object_get (obj,
      "object-path", &object_path,
      NULL);

  g_assert (TP_IS_EXPORTABLE_CHANNEL (obj) || TP_IS_CHANNEL_IFACE (obj));

  if (TP_IS_EXPORTABLE_CHANNEL (obj))
    {
      g_object_get (obj,
          "channel-properties", &table,
          NULL);
    }
  else
    {
     table = g_hash_table_new_full (g_str_hash, g_str_equal,
          NULL, (GDestroyNotify) tp_g_value_slice_free);

      value = tp_g_value_slice_new (G_TYPE_UINT);
      g_object_get_property (obj, "handle", value);
      g_hash_table_insert (table, TP_PROP_CHANNEL_TARGET_HANDLE, value);

      value = tp_g_value_slice_new (G_TYPE_UINT);
      g_object_get_property (obj, "handle-type", value);
      g_hash_table_insert (table, TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, value);

      value = tp_g_value_slice_new (G_TYPE_STRING);
      g_object_get_property (obj, "channel-type", value);
      g_hash_table_insert (table, TP_PROP_CHANNEL_CHANNEL_TYPE, value);
    }

  structure = tp_value_array_build (2,
      DBUS_TYPE_G_OBJECT_PATH, object_path,
      TP_HASH_TYPE_QUALIFIED_PROPERTY_VALUE_MAP, table,
      G_TYPE_INVALID);

  g_free (object_path);
  g_hash_table_unref (table);

  return structure;
}


static GPtrArray *
find_matching_channel_requests (TpBaseConnection *conn,
                                const gchar *channel_type,
                                guint handle_type,
                                guint handle,
                                ChannelRequest *channel_request,
                                gboolean *suppress_handler)
{
  TpBaseConnectionPrivate *priv = conn->priv;
  GPtrArray *requests;
  guint i;

  requests = g_ptr_array_sized_new (1);

  if (handle_type == 0)
    {
      /* It's an anonymous channel, which can only satisfy the request for
       * which it was created (or if it's returned as EXISTING, it can only
       * satisfy the request for which it was returned as EXISTING).
       */
      g_assert (handle == 0);
      g_assert (channel_request == NULL ||
          tp_g_ptr_array_contains (priv->channel_requests, channel_request));

      if (channel_request)
        {
          g_ptr_array_add (requests, channel_request);

          if (suppress_handler && channel_request->suppress_handler)
            *suppress_handler = TRUE;
        }

      /* whether we've put any matches in requests or not */
      return requests;
    }

  /* for identifiable channels (those which are to a particular handle),
   * satisfy any queued requests.
   */
  for (i = 0; i < priv->channel_requests->len; i++)
    {
      ChannelRequest *request = g_ptr_array_index (priv->channel_requests, i);

      if (tp_strdiff (request->channel_type, channel_type))
        continue;

      if (handle_type != request->handle_type)
        continue;

      if (handle != request->handle)
        continue;

      if (request->suppress_handler && suppress_handler)
        *suppress_handler = TRUE;

      g_ptr_array_add (requests, request);
    }

  /* if this channel was created or returned as a result of a particular
   * request, that request had better be among the matching ones in the queue
   */
  g_assert (channel_request == NULL ||
      tp_g_ptr_array_contains (requests, channel_request));

  return requests;
}


static void
satisfy_request (TpBaseConnection *conn,
                 ChannelRequest *request,
                 GObject *channel,
                 const gchar *object_path)
{
  TpBaseConnectionPrivate *priv = conn->priv;

  DEBUG ("completing queued request %p with success, "
      "channel_type=%s, handle_type=%u, "
      "handle=%u, suppress_handler=%u", request, request->channel_type,
      request->handle_type, request->handle, request->suppress_handler);

  switch (request->method)
    {
    case METHOD_REQUEST_CHANNEL:
      tp_svc_connection_return_from_request_channel (request->context,
          object_path);
      break;

    case METHOD_CREATE_CHANNEL:
        {
          GHashTable *properties;

          g_assert (TP_IS_EXPORTABLE_CHANNEL (channel));
          g_object_get (channel,
              "channel-properties", &properties,
              NULL);
          tp_svc_connection_interface_requests_return_from_create_channel (
              request->context, object_path, properties);
          g_hash_table_unref (properties);
        }
        break;

    case METHOD_ENSURE_CHANNEL:
        {
          GHashTable *properties;

          g_assert (TP_IS_EXPORTABLE_CHANNEL (channel));
          g_object_get (channel,
              "channel-properties", &properties,
              NULL);
          tp_svc_connection_interface_requests_return_from_ensure_channel (
              request->context, request->yours, object_path, properties);
          g_hash_table_unref (properties);
        }
        break;

    default:
      g_assert_not_reached ();
    }
  request->context = NULL;

  g_ptr_array_remove (priv->channel_requests, request);

  channel_request_free (request);
}


static void
factory_satisfy_requests (TpBaseConnection *conn,
                          TpChannelFactoryIface *factory,
                          TpChannelIface *chan,
                          ChannelRequest *channel_request,
                          gboolean is_new)
{
  gchar *object_path = NULL, *channel_type = NULL;
  guint handle_type = 0, handle = 0;
  gboolean suppress_handler = FALSE;
  GPtrArray *tmp;
  guint i;

  g_object_get (chan,
      "object-path", &object_path,
      "channel-type", &channel_type,
      "handle-type", &handle_type,
      "handle", &handle,
      NULL);

  DEBUG ("called for %s", object_path);

  tmp = find_matching_channel_requests (conn, channel_type, handle_type,
                                        handle, channel_request,
                                        &suppress_handler);

  for (i = 0; i < tmp->len; i++)
    satisfy_request (conn, g_ptr_array_index (tmp, i), G_OBJECT (chan),
        object_path);

  if (is_new)
    {
      GPtrArray *array = g_ptr_array_sized_new (1);

      g_ptr_array_add (array, get_channel_details (G_OBJECT (chan)));
      tp_svc_connection_interface_requests_emit_new_channels (conn, array);
      tp_value_array_free (g_ptr_array_index (array, 0));
      g_ptr_array_unref (array);

      tp_svc_connection_emit_new_channel (conn, object_path, channel_type,
          handle_type, handle, suppress_handler);
    }

  g_ptr_array_unref (tmp);

  g_free (object_path);
  g_free (channel_type);
}


static void
fail_channel_request (TpBaseConnection *conn,
                      ChannelRequest *request,
                      GError *error)
{
  TpBaseConnectionPrivate *priv = conn->priv;

  DEBUG ("completing queued request %p with error, channel_type=%s, "
      "handle_type=%u, handle=%u, suppress_handler=%u",
      request, request->channel_type,
      request->handle_type, request->handle, request->suppress_handler);

  dbus_g_method_return_error (request->context, error);
  request->context = NULL;

  g_ptr_array_remove (priv->channel_requests, request);

  channel_request_free (request);
}


/* Channel factory signal handlers */

static void
factory_channel_closed_cb (GObject *channel,
                           TpBaseConnection *conn)
{
  gchar *object_path;

  g_object_get (channel,
      "object-path", &object_path,
      NULL);

  tp_svc_connection_interface_requests_emit_channel_closed (conn,
      object_path);

  g_free (object_path);
}

static void
factory_new_channel_cb (TpChannelFactoryIface *factory,
                        GObject *chan,
                        ChannelRequest *channel_request,
                        gpointer data)
{
  factory_satisfy_requests (TP_BASE_CONNECTION (data), factory,
      TP_CHANNEL_IFACE (chan), channel_request, TRUE);

  g_signal_connect (chan, "closed", (GCallback) factory_channel_closed_cb,
      data);
}


static void
factory_channel_error_cb (TpChannelFactoryIface *factory,
                          GObject *chan,
                          GError *error,
                          ChannelRequest *channel_request,
                          gpointer data)
{
  TpBaseConnection *conn = TP_BASE_CONNECTION (data);
  gchar *channel_type = NULL;
  guint handle_type = 0, handle = 0;
  GPtrArray *tmp;
  guint i;

  DEBUG ("channel_type=%s, handle_type=%u, handle=%u, error_code=%u, "
      "error_message=\"%s\"", channel_type, handle_type, handle,
      error->code, error->message);

  g_object_get (chan,
      "channel-type", &channel_type,
      "handle-type", &handle_type,
      "handle", &handle,
      NULL);

  tmp = find_matching_channel_requests (conn, channel_type, handle_type,
                                        handle, channel_request, NULL);

  for (i = 0; i < tmp->len; i++)
    fail_channel_request (conn, g_ptr_array_index (tmp, i), error);

  g_ptr_array_unref (tmp);
  g_free (channel_type);
}


/* Channel manager signal handlers */

typedef struct {
    TpBaseConnection *self;
    /* borrowed TpExportableChannel => itself if suppress_handler,
     * omitted otherwise */
    GHashTable *suppress_handler;
} ManagerNewChannelContext;

static void
manager_new_channel (gpointer key,
                     gpointer value,
                     gpointer data)
{
  TpExportableChannel *channel = TP_EXPORTABLE_CHANNEL (key);
  GSList *request_tokens = value;
  ManagerNewChannelContext *context = data;
  TpBaseConnection *self = TP_BASE_CONNECTION (context->self);
  gchar *object_path;
  GSList *iter;
  gboolean suppress_handler = FALSE;
  gboolean satisfies_create_channel = FALSE;
  gboolean satisfies_request_channel = FALSE;
  ChannelRequest *first_ensure = NULL;

  g_object_get (channel,
      "object-path", &object_path,
      NULL);

  /* suppress_handler on Connection.NewChannel should be TRUE if:
   *   - any satisfied requests were calls to CreateChannel; or
   *   - at least one satisfied RequestChannel call had suppress_handler=TRUE;
   *     or
   *   - any EnsureChannel call will receive Yours=TRUE (that is, if the
   *     channel satisfies no CreateChannel or RequestChannel calls).
   *
   * So, it should be FALSE if:
   *   - all the requests were RequestChannel(..., suppress_handler=FALSE) or
   *     EnsureChannel and there was at least one RequestChannel; or
   *   - no requests were satisfied by the channel.
   */
  for (iter = request_tokens; iter != NULL; iter = iter->next)
    {
      ChannelRequest *request = iter->data;

      switch (request->method)
        {
          case METHOD_REQUEST_CHANNEL:
            satisfies_request_channel = TRUE;
            if (request->suppress_handler)
              {
                suppress_handler = TRUE;
                goto break_loop_early;
              }
            break;

          case METHOD_CREATE_CHANNEL:
            satisfies_create_channel = TRUE;
            goto break_loop_early;
            break;

          case METHOD_ENSURE_CHANNEL:
            if (first_ensure == NULL)
              first_ensure = request;
            break;

          case NUM_METHODS:
            g_assert_not_reached ();
        }

    }
break_loop_early:

  /* put the channel in the suppress_handler hash table if it needs
   * suppress_handler set when signalling NewChannel */
  if (request_tokens != NULL &&
      (satisfies_create_channel || !satisfies_request_channel))
    suppress_handler = TRUE;

  if (suppress_handler)
    g_hash_table_insert (context->suppress_handler, channel, channel);

  /* If the only type of request satisfied by this new channel is
   * EnsureChannel, give exactly one request Yours=True.
   * If other kinds of requests are involved, don't give anyone Yours=True.
   */
  if (!satisfies_request_channel
      && !satisfies_create_channel
      && first_ensure != NULL)
    {
      first_ensure->yours = TRUE;
    }


  for (iter = request_tokens; iter != NULL; iter = iter->next)
    {
      satisfy_request (self, iter->data, G_OBJECT (channel),
          object_path);
    }

  g_free (object_path);
}


static void
manager_new_channels_cb (TpChannelManager *manager,
                         GHashTable *channels,
                         TpBaseConnection *self)
{
  GPtrArray *array;
  ManagerNewChannelContext context = { self, g_hash_table_new (NULL, NULL) };
  GHashTableIter iter;
  gpointer key, value;

  g_assert (TP_IS_CHANNEL_MANAGER (manager));
  g_assert (TP_IS_BASE_CONNECTION (self));

  /* satisfy the RequestChannel/CreateChannel/EnsureChannel calls; as
   * a side-effect, fill in context.suppress_handler with those channels
   * that will have to be signalled with suppress_handler = TRUE */
  g_hash_table_foreach (channels, manager_new_channel, &context);

  /* Emit NewChannels */
  array = g_ptr_array_sized_new (g_hash_table_size (channels));
  g_hash_table_iter_init (&iter, channels);

  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      g_ptr_array_add (array, get_channel_details (G_OBJECT (key)));
    }

  tp_svc_connection_interface_requests_emit_new_channels (self,
      array);

  g_ptr_array_foreach (array, (GFunc) tp_value_array_free, NULL);
  g_ptr_array_unref (array);

  /* Emit NewChannel */
  g_hash_table_iter_init (&iter, channels);

  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      gboolean suppress_handler = (
          g_hash_table_lookup (context.suppress_handler, key) != NULL);
      gchar *object_path, *channel_type;
      guint handle_type, handle;

      exportable_channel_get_old_info (TP_EXPORTABLE_CHANNEL (key),
          &object_path, &channel_type, &handle_type, &handle);

      tp_svc_connection_emit_new_channel (self, object_path, channel_type,
          handle_type, handle, suppress_handler);

      g_free (object_path);
      g_free (channel_type);
    }

  g_hash_table_unref (context.suppress_handler);
}


static void
manager_request_already_satisfied_cb (TpChannelManager *manager,
                                      gpointer request_token,
                                      TpExportableChannel *channel,
                                      TpBaseConnection *self)
{
  gchar *object_path;

  g_assert (TP_IS_CHANNEL_MANAGER (manager));
  g_assert (TP_IS_EXPORTABLE_CHANNEL (channel));
  g_assert (TP_IS_BASE_CONNECTION (self));

  g_object_get (channel,
      "object-path", &object_path,
      NULL);

  satisfy_request (self, request_token, G_OBJECT (channel), object_path);
  g_free (object_path);
}


static void
manager_request_failed_cb (TpChannelManager *manager,
                           gpointer request_token,
                           guint domain,
                           gint code,
                           gchar *message,
                           TpBaseConnection *self)
{
  GError error = { domain, code, message };

  g_assert (TP_IS_CHANNEL_MANAGER (manager));
  g_assert (domain > 0);
  g_assert (message != NULL);
  g_assert (TP_IS_BASE_CONNECTION (self));

  fail_channel_request (self, request_token, &error);
}


static void
manager_channel_closed_cb (TpChannelManager *manager,
                           const gchar *path,
                           TpBaseConnection *self)
{
  g_assert (TP_IS_CHANNEL_MANAGER (manager));
  g_assert (path != NULL);
  g_assert (TP_IS_BASE_CONNECTION (self));

  tp_svc_connection_interface_requests_emit_channel_closed (self, path);
}

/*
 * Set the @handle_type'th handle repository, which must be %NULL, to
 * @handle_repo. This method can only be called from code run during the
 * constructor(), after handle repository instantiation (in practice, this
 * means it can only be called from the @create_channel_managers callback).
 */
void
_tp_base_connection_set_handle_repo (TpBaseConnection *self,
    TpHandleType handle_type,
    TpHandleRepoIface *handle_repo)
{
  g_return_if_fail (TP_IS_BASE_CONNECTION (self));
  g_return_if_fail (!self->priv->been_constructed);
  g_return_if_fail (tp_handle_type_is_valid (handle_type, NULL));
  g_return_if_fail (self->priv->handles[TP_HANDLE_TYPE_CONTACT] != NULL);
  g_return_if_fail (self->priv->handles[handle_type] == NULL);
  g_return_if_fail (TP_IS_HANDLE_REPO_IFACE (handle_repo));

  self->priv->handles[handle_type] = g_object_ref (handle_repo);
}

static void
tp_base_connection_create_interfaces_array (TpBaseConnection *self)
{
  TpBaseConnectionPrivate *priv = self->priv;
  TpBaseConnectionClass *klass = TP_BASE_CONNECTION_GET_CLASS (self);
  GPtrArray *always;
  guint i;

  g_assert (priv->interfaces == NULL);

  always = klass->get_interfaces_always_present (self);

  priv->interfaces = g_array_sized_new (TRUE, FALSE, sizeof (gchar *),
      always->len);
  for (i = 0; i < always->len; i++)
    {
      g_array_append_val (priv->interfaces,
          g_ptr_array_index (always, i));
    }

  g_ptr_array_unref (always);
}

static GObject *
tp_base_connection_constructor (GType type, guint n_construct_properties,
    GObjectConstructParam *construct_params)
{
  guint i;
  TpBaseConnection *self = TP_BASE_CONNECTION (
      G_OBJECT_CLASS (tp_base_connection_parent_class)->constructor (
        type, n_construct_properties, construct_params));
  TpBaseConnectionPrivate *priv = self->priv;
  TpBaseConnectionClass *cls = TP_BASE_CONNECTION_GET_CLASS (self);

  g_assert (cls->create_handle_repos != NULL);
  g_assert (cls->create_channel_factories != NULL ||
            cls->create_channel_managers  != NULL);
  g_assert (cls->shut_down != NULL);
  g_assert (cls->start_connecting != NULL);

  /* if we fail to connect to D-Bus here, we'll return an error from
   * register */
  tp_base_connection_ensure_dbus (self, NULL);

  (cls->create_handle_repos) (self, priv->handles);

  /* a connection that doesn't support contacts is no use to anyone */
  g_assert (priv->handles[TP_HANDLE_TYPE_CONTACT] != NULL);

  if (cls->create_channel_factories != NULL)
    priv->channel_factories = cls->create_channel_factories (self);
  else
    priv->channel_factories = g_ptr_array_sized_new (0);

  if (cls->create_channel_managers != NULL)
    priv->channel_managers = cls->create_channel_managers (self);
  else
    priv->channel_managers = g_ptr_array_sized_new (0);

  for (i = 0; i < priv->channel_factories->len; i++)
    {
      GObject *factory = g_ptr_array_index (priv->channel_factories, i);
      g_signal_connect (factory, "new-channel", G_CALLBACK
          (factory_new_channel_cb), self);
      g_signal_connect (factory, "channel-error", G_CALLBACK
          (factory_channel_error_cb), self);
    }

  for (i = 0; i < priv->channel_managers->len; i++)
    {
      TpChannelManager *manager = TP_CHANNEL_MANAGER (
          g_ptr_array_index (priv->channel_managers, i));

      g_signal_connect (manager, "new-channels",
          (GCallback) manager_new_channels_cb, self);
      g_signal_connect (manager, "request-already-satisfied",
          (GCallback) manager_request_already_satisfied_cb, self);
      g_signal_connect (manager, "request-failed",
          (GCallback) manager_request_failed_cb, self);
      g_signal_connect (manager, "channel-closed",
          (GCallback) manager_channel_closed_cb, self);
    }

  tp_base_connection_create_interfaces_array (self);

  priv->been_constructed = TRUE;

  return (GObject *) self;
}

/**
 * tp_base_connection_add_possible_client_interest:
 * @self: a connection
 * @token: a quark corresponding to a D-Bus interface, or a token
 *  representing part of a D-Bus interface, for which this connection wishes
 *  to be notified when clients register an interest
 *
 * Add @token to the set of tokens for which this connection will emit
 * #TpBaseConnection::clients-interested and
 * #TpBaseConnection::clients-uninterested.
 *
 * This method must be called from the #GObjectClass<!--
 * -->.constructed or #GObjectClass<!-- -->.constructor callback
 * (otherwise, it will run too late to be useful).
 */
void
tp_base_connection_add_possible_client_interest (TpBaseConnection *self,
    GQuark token)
{
  gpointer p = GUINT_TO_POINTER (token);

  g_return_if_fail (TP_IS_BASE_CONNECTION (self));
  g_return_if_fail (self->status == TP_INTERNAL_CONNECTION_STATUS_NEW);

  if (g_hash_table_lookup (self->priv->client_interests, p) == NULL)
    g_hash_table_insert (self->priv->client_interests, p,
        g_hash_table_new (g_str_hash, g_str_equal));
}

/* D-Bus properties for the Requests interface */

static void
factory_get_channel_details_foreach (TpChannelIface *chan,
                                     gpointer data)
{
  GPtrArray *details = data;

  g_ptr_array_add (details, get_channel_details (G_OBJECT (chan)));
}


static void
manager_get_channel_details_foreach (TpExportableChannel *chan,
                                     gpointer data)
{
  GPtrArray *details = data;

  g_ptr_array_add (details, get_channel_details (G_OBJECT (chan)));
}


static GPtrArray *
conn_requests_get_channel_details (TpBaseConnection *self)
{
  TpBaseConnectionPrivate *priv = self->priv;
  /* guess that each ChannelManager and each ChannelFactory has two
   * channels, on average */
  GPtrArray *details = g_ptr_array_sized_new (priv->channel_managers->len * 2
      + priv->channel_factories->len * 2);
  guint i;

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  for (i = 0; i < priv->channel_factories->len; i++)
    {
      TpChannelFactoryIface *factory = TP_CHANNEL_FACTORY_IFACE (
          g_ptr_array_index (priv->channel_factories, i));

      tp_channel_factory_iface_foreach (factory,
          factory_get_channel_details_foreach, details);
    }
  G_GNUC_END_IGNORE_DEPRECATIONS

  for (i = 0; i < priv->channel_managers->len; i++)
    {
      TpChannelManager *manager = TP_CHANNEL_MANAGER (
          g_ptr_array_index (priv->channel_managers, i));

      tp_channel_manager_foreach_channel (manager,
          manager_get_channel_details_foreach, details);
    }

  return details;
}


static void
get_requestables_foreach (TpChannelManager *manager,
                          GHashTable *fixed_properties,
                          const gchar * const *allowed_properties,
                          gpointer user_data)
{
  GPtrArray *details = user_data;

  g_ptr_array_add (details, tp_value_array_build (2,
        TP_HASH_TYPE_CHANNEL_CLASS, fixed_properties,
        G_TYPE_STRV, allowed_properties,
        G_TYPE_INVALID));
}


static GPtrArray *
conn_requests_get_requestables (TpBaseConnection *self)
{
  TpBaseConnectionPrivate *priv = self->priv;
  /* generously guess that each ChannelManager has about 2 ChannelClasses */
  GPtrArray *details = g_ptr_array_sized_new (priv->channel_managers->len * 2);
  guint i;

  for (i = 0; i < priv->channel_managers->len; i++)
    {
      TpChannelManager *manager = TP_CHANNEL_MANAGER (
          g_ptr_array_index (priv->channel_managers, i));

      tp_channel_manager_foreach_channel_class (manager,
          get_requestables_foreach, details);
    }

  return details;
}


static void
conn_requests_get_dbus_property (GObject *object,
                                 GQuark interface,
                                 GQuark name,
                                 GValue *value,
                                 gpointer unused G_GNUC_UNUSED)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (object);

  g_return_if_fail (interface == TP_IFACE_QUARK_CONNECTION_INTERFACE_REQUESTS);

  if (name == g_quark_from_static_string ("Channels"))
    {
      g_value_take_boxed (value, conn_requests_get_channel_details (self));
    }
  else if (name == g_quark_from_static_string ("RequestableChannelClasses"))
    {
      g_value_take_boxed (value, conn_requests_get_requestables (self));
    }
  else
    {
      g_return_if_reached ();
    }
}

static GPtrArray *
tp_base_connection_get_interfaces_always_present (TpBaseConnection *self)
{
  GPtrArray *interfaces = g_ptr_array_new ();
  const gchar **ptr;

  /* copy the klass->interfaces_always_present property for backwards
   * compatibility */
  for (ptr = TP_BASE_CONNECTION_GET_CLASS (self)->interfaces_always_present;
       ptr != NULL && *ptr != NULL;
       ptr++)
    {
      g_ptr_array_add (interfaces, (gchar *) *ptr);
    }

  return interfaces;
}

static void
tp_base_connection_class_init (TpBaseConnectionClass *klass)
{
  static TpDBusPropertiesMixinPropImpl connection_properties[] = {
      { "SelfHandle", "self-handle", NULL },
      { "SelfID", "self-id", NULL },
      { "Status", "dbus-status", NULL },
      { "Interfaces", "interfaces", NULL },
      { "HasImmortalHandles", "has-immortal-handles", NULL },
      { NULL }
  };
  static TpDBusPropertiesMixinPropImpl requests_properties[] = {
        { "Channels", NULL, NULL },
        { "RequestableChannelClasses", NULL, NULL },
        { NULL }
  };
  GParamSpec *param_spec;
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (TpBaseConnectionPrivate));
  object_class->dispose = tp_base_connection_dispose;
  object_class->finalize = tp_base_connection_finalize;
  object_class->constructor = tp_base_connection_constructor;
  object_class->get_property = tp_base_connection_get_property;
  object_class->set_property = tp_base_connection_set_property;

  klass->get_interfaces_always_present =
    tp_base_connection_get_interfaces_always_present;

  /**
   * TpBaseConnection:protocol: (skip)
   *
   * Identifier used in the Telepathy protocol when this connection's protocol
   * name is required.
   */
  param_spec = g_param_spec_string ("protocol",
      "Telepathy identifier for protocol",
      "Identifier string used when the protocol name is required.",
      NULL,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PROTOCOL, param_spec);

  /**
   * TpBaseConnection:self-handle: (skip)
   *
   * The handle of type %TP_HANDLE_TYPE_CONTACT representing the local user.
   * Must be set nonzero by the subclass before moving to state CONNECTED.
   *
   * Since: 0.7.15
   */
  param_spec = g_param_spec_uint ("self-handle",
      "Connection.SelfHandle",
      "The handle of type %TP_HANDLE_TYPE_CONTACT representing the local user.",
      0, G_MAXUINT, 0,
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_SELF_HANDLE, param_spec);

  /**
   * TpBaseConnection:self-id: (skip)
   *
   * The identifier representing the local user. This is the result of
   * inspecting #TpBaseConnection:self-handle.
   *
   * Since: 0.21.2
   */
  param_spec = g_param_spec_string ("self-id",
      "Connection.SelfID",
      "The identifier representing the local user.",
      "",
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_SELF_ID, param_spec);

  /**
   * TpBaseConnection:interfaces: (skip)
   *
   * The set of D-Bus interfaces available on this Connection, other than
   * Connection itself.
   *
   * Since: 0.11.3
   */
  param_spec = g_param_spec_boxed ("interfaces",
      "Connection.Interfaces",
      "The set of D-Bus interfaces available on this Connection, other than "
      "Connection itself",
      G_TYPE_STRV,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INTERFACES, param_spec);

  /**
   * TpBaseConnection:dbus-status: (skip)
   *
   * The Connection.Status as visible on D-Bus, which is the same as
   * #TpBaseConnection<!-- -->.status except that
   * %TP_INTERNAL_CONNECTION_STATUS_NEW is replaced by
   * %TP_CONNECTION_STATUS_DISCONNECTED.
   *
   * The #GObject::notify signal is not currently emitted for this property.
   *
   * Since: 0.11.3
   */
  param_spec = g_param_spec_uint ("dbus-status",
      "Connection.Status",
      "The connection status as visible on D-Bus",
      TP_CONNECTION_STATUS_CONNECTED, TP_CONNECTION_STATUS_DISCONNECTED,
      TP_CONNECTION_STATUS_DISCONNECTED,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DBUS_STATUS, param_spec);

  /**
   * TpBaseConnection:dbus-daemon: (skip)
   *
   * #TpDBusDaemon object encapsulating this object's connection to D-Bus.
   * Read-only except during construction.
   *
   * If this property is %NULL or omitted during construction, the object will
   * automatically attempt to connect to the starter or session bus with
   * tp_dbus_daemon_dup() just after it is constructed; if this fails, this
   * property will remain %NULL, and tp_base_connection_register() will fail.
   *
   * Since: 0.11.3
   */
  g_object_class_install_property (object_class, PROP_DBUS_DAEMON,
      g_param_spec_object ("dbus-daemon", "D-Bus daemon",
        "The D-Bus daemon used by this object", TP_TYPE_DBUS_DAEMON,
        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  /**
   * TpBaseConnection:has-immortal-handles:
   *
   * This property is not useful to use directly. Its value is %TRUE, to
   * indicate that this version of telepathy-glib never unreferences handles
   * until the connection becomes disconnected.
   *
   * Since: 0.13.8
   */
  param_spec = g_param_spec_boolean ("has-immortal-handles",
      "Connection.HasImmortalHandles",
      "Always TRUE", TRUE, G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_HAS_IMMORTAL_HANDLES,
      param_spec);

  /**
   * TpBaseConnection:account-path-suffix:
   *
   * The suffix of the account object path such as
   * "gabble/jabber/chris_40example_2ecom0" for the account whose object path is
   * %TP_ACCOUNT_OBJECT_PATH_BASE + "gabble/jabber/chris_40example_2ecom0".
   * The same as returned by tp_account_get_path_suffix().
   *
   * It is given by the AccountManager in the connection parameters. Or %NULL if
   * the ConnectionManager or the AccountManager are too old.
   *
   * Since: 0.23.2
   */
  param_spec = g_param_spec_string ("account-path-suffix",
      "Account path suffix",
      "The suffix of the account path",
      NULL,
      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ACCOUNT_PATH_SUFFIX,
      param_spec);

  /* signal definitions */

  /**
   * TpBaseConnection::shutdown-finished: (skip)
   * @connection: the #TpBaseConnection
   *
   * Emitted by tp_base_connection_finish_shutdown() when the underlying
   * network connection has been closed; #TpBaseConnectionManager listens
   * for this signal and removes connections from its table of active
   * connections when it is received.
   */
  signals[SHUTDOWN_FINISHED] =
    g_signal_new ("shutdown-finished",
                  G_OBJECT_CLASS_TYPE (klass),
                  G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
                  0,
                  NULL, NULL, NULL,
                  G_TYPE_NONE, 0);

  /**
   * TpBaseConnection::clients-interested:
   * @connection: the #TpBaseConnection
   * @token: the interface or part of an interface in which clients are newly
   *  interested
   *
   * Emitted when a client becomes interested in any token that was added with
   * tp_base_connection_add_possible_client_interest().
   *
   * The "signal detail" is a GQuark representing @token. Modules implementing
   * an interface (Location, say) should typically connect to a detailed signal
   * like
   * "clients-interested::org.freedesktop.Telepathy.Connection.Interface.Location"
   * rather than receiving all emissions of this signal.
   */
  signals[CLIENTS_INTERESTED] =
    g_signal_new ("clients-interested",
                  G_OBJECT_CLASS_TYPE (klass),
                  G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
                  0,
                  NULL, NULL, NULL,
                  G_TYPE_NONE, 1, G_TYPE_STRING);

  /**
   * TpBaseConnection::clients-uninterested:
   * @connection: the #TpBaseConnection
   * @token: the interface or part of an interface in which clients are no
   *  longer interested
   *
   * Emitted when no more clients are interested in an interface added with
   * tp_base_connection_add_possible_client_interest(), for which
   * #TpBaseConnection::clients-interested was previously emitted.
   *
   * As with #TpBaseConnection::clients-interested, the "signal detail" is a
   * GQuark representing @token. Modules implementing an interface (Location,
   * say) should typically connect to a detailed signal like
   * "clients-uninterested::org.freedesktop.Telepathy.Connection.Interface.Location"
   * rather than receiving all emissions of this signal.
   */
  signals[CLIENTS_UNINTERESTED] =
    g_signal_new ("clients-uninterested",
                  G_OBJECT_CLASS_TYPE (klass),
                  G_SIGNAL_RUN_LAST | G_SIGNAL_DETAILED,
                  0,
                  NULL, NULL, NULL,
                  G_TYPE_NONE, 1, G_TYPE_STRING);

  tp_dbus_properties_mixin_class_init (object_class, 0);
  tp_dbus_properties_mixin_implement_interface (object_class,
      TP_IFACE_QUARK_CONNECTION,
      tp_dbus_properties_mixin_getter_gobject_properties, NULL,
      connection_properties);
  tp_dbus_properties_mixin_implement_interface (object_class,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_REQUESTS,
      conn_requests_get_dbus_property, NULL,
      requests_properties);
}

static void
tp_base_connection_init (TpBaseConnection *self)
{
  TpBaseConnectionPrivate *priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_BASE_CONNECTION, TpBaseConnectionPrivate);
  guint i;

  self->priv = priv;
  self->status = TP_INTERNAL_CONNECTION_STATUS_NEW;

  for (i = 0; i < TP_NUM_HANDLE_TYPES; i++)
    {
      priv->handles[i] = NULL;
    }

  priv->channel_requests = g_ptr_array_new ();
  priv->client_interests = g_hash_table_new_full (NULL, NULL, NULL,
      (GDestroyNotify) g_hash_table_unref);
  priv->interested_clients = g_hash_table_new_full (g_str_hash, g_str_equal,
      g_free, NULL);
}

static gchar *
squash_name (const gchar *name, guint length)
{
  GChecksum *checksum;
  gchar *squashed;

  g_assert (length >= 10);
  checksum = g_checksum_new (G_CHECKSUM_MD5);
  g_checksum_update (checksum, (guchar *) name, -1);
  squashed = g_strdup_printf (
      "%.*s_%.8s", length - 9, name, g_checksum_get_string (checksum));
  g_checksum_free (checksum);
  return squashed;
}

/**
 * tp_base_connection_register:
 * @self: A connection
 * @cm_name: The name of the connection manager in the Telepathy protocol
 * @bus_name: (out): Used to return the bus name corresponding to the connection
 *  if %TRUE is returned. To be freed by the caller.
 * @object_path: (out): Used to return the object path of the connection if
 *  %TRUE is returned. To be freed by the caller.
 * @error: Used to return an error if %FALSE is returned; may be %NULL
 *
 * Make the connection object appear on the bus, returning the bus
 * name and object path used. If %TRUE is returned, the connection owns the
 * bus name, and will release it when destroyed.
 *
 * Since 0.11.11, @bus_name and @object_path may be %NULL if the
 * strings are not needed.
 *
 * Returns: %TRUE on success, %FALSE on error.
 */
gboolean
tp_base_connection_register (TpBaseConnection *self,
                             const gchar *cm_name,
                             gchar **bus_name,
                             gchar **object_path,
                             GError **error)
{
  TpBaseConnectionClass *cls = TP_BASE_CONNECTION_GET_CLASS (self);
  TpBaseConnectionPrivate *priv = self->priv;
  gchar *tmp;
  gchar *safe_proto;
  gchar *unique_name;
  guint prefix_length;
  const guint dbus_max_name_length = 255;

  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self), FALSE);
  g_return_val_if_fail (cm_name != NULL, FALSE);
  g_return_val_if_fail (!self->priv->been_registered, FALSE);

  if (tp_connection_manager_check_valid_protocol_name (priv->protocol, NULL))
    {
      safe_proto = g_strdelimit (g_strdup (priv->protocol), "-", '_');
    }
  else
    {
      WARNING ("Protocol name %s is not valid - should match "
          "[A-Za-z][A-Za-z0-9-]+", priv->protocol);
      safe_proto = tp_escape_as_identifier (priv->protocol);
    }

  /* Plus two for the dots. */
  prefix_length = strlen (TP_CONN_BUS_NAME_BASE) +
      strlen (cm_name) + strlen (safe_proto) + 2;

  if (cls->get_unique_connection_name)
    {

      tmp = cls->get_unique_connection_name (self);
      g_assert (tmp != NULL);
      unique_name = tp_escape_as_identifier (tmp);
      g_free (tmp);

      if (prefix_length + strlen (unique_name) > dbus_max_name_length)
        {
          /* Is prefix is too long to make reasonable bus name? Ten = one
           * character of the original unique name plus underscore plus
           * 8-character hash.
           */
          if (prefix_length >= dbus_max_name_length - 10)
            {
              WARNING (
                  "Couldn't fit CM name + protocol name + unique name into "
                  "255 characters.");
              g_free (unique_name);
              return FALSE;
            }

          tmp = unique_name;
          unique_name = squash_name (
              tmp, dbus_max_name_length - prefix_length);
          g_free (tmp);
        }
    }
  else
    {
      unique_name = g_strdup_printf ("_%p", self);
    }

  if (!tp_base_connection_ensure_dbus (self, error))
    {
      g_free (safe_proto);
      g_free (unique_name);
      return FALSE;
    }

  self->bus_name = g_strdup_printf (TP_CONN_BUS_NAME_BASE "%s.%s.%s",
      cm_name, safe_proto, unique_name);
  g_assert (strlen (self->bus_name) <= 255);
  self->object_path = g_strdup_printf (TP_CONN_OBJECT_PATH_BASE "%s/%s/%s",
      cm_name, safe_proto, unique_name);

  g_free (safe_proto);
  g_free (unique_name);

  if (!tp_dbus_daemon_request_name (priv->bus_proxy, self->bus_name, FALSE,
        error))
    {
      g_free (self->bus_name);
      self->bus_name = NULL;
      return FALSE;
    }

  DEBUG ("%p: bus name %s; object path %s", self, self->bus_name,
      self->object_path);
  tp_dbus_daemon_register_object (priv->bus_proxy, self->object_path, self);
  self->priv->been_registered = TRUE;

  if (bus_name != NULL)
    *bus_name = g_strdup (self->bus_name);

  if (object_path != NULL)
    *object_path = g_strdup (self->object_path);

  return TRUE;
}

static void
tp_base_connection_close_all_channels (TpBaseConnection *self)
{
  TpBaseConnectionPrivate *priv = self->priv;

  /* We deliberately don't iterate over channel managers here -
   * they don't need this, and are expected to listen to
   * TpSvcConnection::status-changed on the connection for themselves.
   */

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  /* trigger close_all on all channel factories */
  g_ptr_array_foreach (priv->channel_factories, (GFunc)
      tp_channel_factory_iface_close_all, NULL);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

/* D-Bus methods on Connection interface ----------------------------*/

static inline TpConnectionStatusReason
conn_status_reason_from_g_error (GError *error)
{
  if (error->domain == TP_ERROR)
    {
      switch (error->code)
        {
#define OBVIOUS_MAPPING(x) \
        case TP_ERROR_ ## x: \
          return TP_CONNECTION_STATUS_REASON_ ## x

          OBVIOUS_MAPPING (NETWORK_ERROR);
          OBVIOUS_MAPPING (ENCRYPTION_ERROR);
          OBVIOUS_MAPPING (AUTHENTICATION_FAILED);
          OBVIOUS_MAPPING (CERT_NOT_PROVIDED);
          OBVIOUS_MAPPING (CERT_UNTRUSTED);
          OBVIOUS_MAPPING (CERT_EXPIRED);
          OBVIOUS_MAPPING (CERT_NOT_ACTIVATED);
          OBVIOUS_MAPPING (CERT_FINGERPRINT_MISMATCH);
          OBVIOUS_MAPPING (CERT_HOSTNAME_MISMATCH);
          OBVIOUS_MAPPING (CERT_SELF_SIGNED);
#undef OBVIOUS_MAPPING

        case TP_ERROR_PERMISSION_DENIED:
        case TP_ERROR_DOES_NOT_EXIST:
          return TP_CONNECTION_STATUS_REASON_AUTHENTICATION_FAILED;

        case TP_ERROR_CERT_INVALID:
          return TP_CONNECTION_STATUS_REASON_CERT_OTHER_ERROR;

        case TP_ERROR_CANCELLED:
          return TP_CONNECTION_STATUS_REASON_REQUESTED;

        case TP_ERROR_ENCRYPTION_NOT_AVAILABLE:
          return TP_CONNECTION_STATUS_REASON_ENCRYPTION_ERROR;

        case TP_ERROR_REGISTRATION_EXISTS:
        case TP_ERROR_ALREADY_CONNECTED:
        case TP_ERROR_CONNECTION_REPLACED:
          return TP_CONNECTION_STATUS_REASON_NAME_IN_USE;

        case TP_ERROR_CONNECTION_REFUSED:
        case TP_ERROR_CONNECTION_FAILED:
        case TP_ERROR_CONNECTION_LOST:
        case TP_ERROR_SERVICE_BUSY:
          return TP_CONNECTION_STATUS_REASON_NETWORK_ERROR;

        /* current status: all TP_ERRORs up to and including
         * TP_ERROR_RESOURCE_UNAVAILABLE have been looked at */
        }
    }

  return TP_CONNECTION_STATUS_REASON_NONE_SPECIFIED;
}

static void
tp_base_connection_connect (TpSvcConnection *iface,
                            DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (iface);
  TpBaseConnectionClass *cls = TP_BASE_CONNECTION_GET_CLASS (self);
  GError *error = NULL;

  g_assert (TP_IS_BASE_CONNECTION (self));

  if (self->status == TP_INTERNAL_CONNECTION_STATUS_NEW)
    {
      if (cls->start_connecting (self, &error))
        {
          if (self->status == TP_INTERNAL_CONNECTION_STATUS_NEW)
            {
              tp_base_connection_change_status (self,
                TP_CONNECTION_STATUS_CONNECTING,
                TP_CONNECTION_STATUS_REASON_REQUESTED);
            }
        }
      else
        {
          if (self->status != TP_CONNECTION_STATUS_DISCONNECTED)
            {
              tp_base_connection_change_status (self,
                TP_CONNECTION_STATUS_DISCONNECTED,
                conn_status_reason_from_g_error (error));
            }
          dbus_g_method_return_error (context, error);
          g_error_free (error);
          return;
        }
    }
  tp_svc_connection_return_from_connect (context);
}

static void
tp_base_connection_disconnect (TpSvcConnection *iface,
                               DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (iface);

  g_assert (TP_IS_BASE_CONNECTION (self));

  if (self->priv->disconnect_requests != NULL)
    {
      g_assert (self->status == TP_CONNECTION_STATUS_DISCONNECTED);
      g_ptr_array_add (self->priv->disconnect_requests, context);
      return;
    }

  if (self->status == TP_CONNECTION_STATUS_DISCONNECTED)
    {
      /* status DISCONNECTED and disconnect_requests NULL => already dead */
      tp_svc_connection_return_from_disconnect (context);
      return;
    }

  self->priv->disconnect_requests = g_ptr_array_sized_new (1);
  g_ptr_array_add (self->priv->disconnect_requests, context);

  tp_base_connection_change_status (self,
      TP_CONNECTION_STATUS_DISCONNECTED,
      TP_CONNECTION_STATUS_REASON_REQUESTED);
}

static const gchar * const *
tp_base_connection_get_interfaces (TpBaseConnection *self)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self), NULL);

  return (const gchar * const *)(self->priv->interfaces->data);
}

static void
tp_base_connection_dbus_get_interfaces (TpSvcConnection *iface,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_return_from_get_interfaces (context,
      (const gchar **) tp_base_connection_get_interfaces (
        (TpBaseConnection *) iface));
}

static void
tp_base_connection_get_protocol (TpSvcConnection *iface,
                                 DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (iface);
  TpBaseConnectionPrivate *priv;

  g_assert (TP_IS_BASE_CONNECTION (self));

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (self, context);

  priv = self->priv;

  tp_svc_connection_return_from_get_protocol (context, priv->protocol);
}

static void
tp_base_connection_dbus_get_self_handle (TpSvcConnection *iface,
                                         DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (iface);

  g_assert (TP_IS_BASE_CONNECTION (self));

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (self, context);

  tp_svc_connection_return_from_get_self_handle (
      context, self->self_handle);
}

/**
 * tp_base_connection_get_status:
 * @self: the connection
 *
 * Return the status of this connection, as set by
 * tp_base_connection_change_status() or similar functions like
 * tp_base_connection_disconnect_with_dbus_error().
 *
 * Like the corresponding D-Bus property, this method returns
 * %TP_CONNECTION_STATUS_DISCONNECTED in two situations:
 * either the connection is newly-created (and has never emitted
 * #TpSvcConnection::status-changed), or D-Bus clients have already been
 * told that it has been destroyed (by the Disconnect D-Bus method,
 * a failed attempt to connect, or loss of an established connection).
 * Use tp_base_connection_is_destroyed() to distinguish between the two.
 *
 * Returns: the value of #TpBaseConnection:dbus-status
 * Since: 0.19.1
 */
TpConnectionStatus
tp_base_connection_get_status (TpBaseConnection *self)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self),
      TP_CONNECTION_STATUS_DISCONNECTED);

  if (self->status == TP_INTERNAL_CONNECTION_STATUS_NEW)
    {
      return TP_CONNECTION_STATUS_DISCONNECTED;
    }
  else
    {
      return self->status;
    }
}

/**
 * tp_base_connection_is_destroyed:
 * @self: the connection
 *
 * Return whether this connection has already emitted the D-Bus signal
 * indicating that it has been destroyed.
 *
 * In particular, this can be used to distinguish between the two reasons
 * why tp_base_connection_get_status() would return
 * %TP_CONNECTION_STATUS_DISCONNECTED: it will return %FALSE if the
 * connection is newly-created, and %TRUE if the Disconnect D-Bus method
 * has been called, an attempt to connect has failed, or an established
 * connection has encountered an error.
 *
 * Returns: %TRUE if this connection is disappearing from D-Bus
 * Since: 0.19.1
 */
gboolean
tp_base_connection_is_destroyed (TpBaseConnection *self)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self), TRUE);

  /* in particular return FALSE if the status is NEW */
  return (self->status == TP_CONNECTION_STATUS_DISCONNECTED);
}

/**
 * tp_base_connection_check_connected:
 * @self: the connection
 * @error: used to raise %TP_ERROR_DISCONNECTED if %FALSE is returned
 *
 * Return whether this connection is fully active and connected.
 * If it is not, raise %TP_ERROR_DISCONNECTED.
 *
 * This is equivalent to checking whether tp_base_connection_get_status()
 * returns %TP_CONNECTION_STATUS_CONNECTED; it is provided because methods
 * on the connection often need to make this check, and return a
 * #GError if it fails.
 *
 * Returns: %TRUE if this connection is connected
 * Since: 0.19.1
 */
gboolean
tp_base_connection_check_connected (TpBaseConnection *self,
    GError **error)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self), FALSE);

  if (self->status == TP_CONNECTION_STATUS_CONNECTED)
    return TRUE;

  g_set_error_literal (error, TP_ERROR, TP_ERROR_DISCONNECTED,
      "Connection is disconnected");
  return FALSE;
}

static void
tp_base_connection_dbus_get_status (TpSvcConnection *iface,
    DBusGMethodInvocation *context)
{
  tp_svc_connection_return_from_get_status (
      context, tp_base_connection_get_status (
        (TpBaseConnection *) iface));
}

static void
tp_base_connection_hold_handles (TpSvcConnection *iface,
                                 guint handle_type,
                                 const GArray *handles,
                                 DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (iface);
  TpBaseConnectionPrivate *priv;
  GError *error = NULL;

  g_assert (TP_IS_BASE_CONNECTION (self));

  priv = self->priv;

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (self, context);

  if (!tp_handles_supported_and_valid (priv->handles,
        handle_type, handles, FALSE, &error))
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  tp_svc_connection_return_from_hold_handles (context);
}

static void
tp_base_connection_inspect_handles (TpSvcConnection *iface,
                                    guint handle_type,
                                    const GArray *handles,
                                    DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (iface);
  TpBaseConnectionPrivate *priv = self->priv;
  GError *error = NULL;
  const gchar **ret;
  guint i;

  g_assert (TP_IS_BASE_CONNECTION (self));

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (self, context);

  if (!tp_handles_supported_and_valid (priv->handles,
        handle_type, handles, FALSE, &error))
    {
      dbus_g_method_return_error (context, error);

      g_error_free (error);

      return;
    }

  ret = g_new (const gchar *, handles->len + 1);

  for (i = 0; i < handles->len; i++)
    {
      TpHandle handle;
      const gchar *tmp;

      handle = g_array_index (handles, TpHandle, i);
      tmp = tp_handle_inspect (priv->handles[handle_type], handle);
      g_assert (tmp != NULL);

      ret[i] = tmp;
    }

  ret[i] = NULL;

  tp_svc_connection_return_from_inspect_handles (context, ret);

  g_free (ret);
}

/*
 * list_channel_factory_foreach_one:
 * @chan: a channel
 * @data: a GPtrArray in which channel information should be stored
 *
 * Called by the exported ListChannels function for each channel in a channel
 * factory, this should add to the GPtrArray (in the data pointer) a
 * GValueArray containing the following:
 *  a D-Bus object path for the channel object on this service
 *  a D-Bus interface name representing the channel type
 *  an integer representing the handle type this channel communicates with,
 *    or zero
 *  an integer handle representing the contact, room or list this channel
 *    communicates with, or zero
 */
static void
list_channel_factory_foreach_one (TpChannelIface *chan,
                                  gpointer data)
{
  GObject *channel = G_OBJECT (chan);
  GPtrArray *values = (GPtrArray *) data;
  gchar *path, *type;
  guint handle_type, handle;
  GValue *entry = tp_dbus_specialized_value_slice_new
      (TP_STRUCT_TYPE_CHANNEL_INFO);

  g_object_get (channel,
      "object-path", &path,
      "channel-type", &type,
      "handle-type", &handle_type,
      "handle", &handle,
      NULL);

  dbus_g_type_struct_set (entry,
      0, path,
      1, type,
      2, handle_type,
      3, handle,
      G_MAXUINT);

  g_ptr_array_add (values, entry);

  g_free (path);
  g_free (type);
}


/*
 * list_channel_manager_foreach_one:
 * @chan: a channel
 * @data: a GPtrArray in which channel information should be stored
 *
 * Called by the exported ListChannels function for each channel in a channel
 * manager, this should add to the GPtrArray (in the data pointer) a
 * GValueArray containing the following:
 *  a D-Bus object path for the channel object on this service
 *  a D-Bus interface name representing the channel type
 *  an integer representing the handle type this channel communicates with,
 *    or zero
 *  an integer handle representing the contact, room or list this channel
 *    communicates with, or zero
 */
static void
list_channel_manager_foreach_one (TpExportableChannel *channel,
                                  gpointer data)
{
  GPtrArray *values = (GPtrArray *) data;
  gchar *path, *type;
  guint handle_type, handle;
  GValue *entry = tp_dbus_specialized_value_slice_new
      (TP_STRUCT_TYPE_CHANNEL_INFO);

  g_assert (TP_IS_EXPORTABLE_CHANNEL (channel));

  exportable_channel_get_old_info (channel, &path, &type, &handle_type,
      &handle);

  dbus_g_type_struct_set (entry,
      0, path,
      1, type,
      2, handle_type,
      3, handle,
      G_MAXUINT);

  g_ptr_array_add (values, entry);

  g_free (path);
  g_free (type);
}


static void
tp_base_connection_list_channels (TpSvcConnection *iface,
                                  DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (iface);
  TpBaseConnectionPrivate *priv;
  GPtrArray *channels, *values;
  guint i;

  g_assert (TP_IS_BASE_CONNECTION (self));

  priv = self->priv;

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (self, context);

  /* I think on average, each factory will have 2 channels :D */
  values = g_ptr_array_sized_new (priv->channel_factories->len * 2
      + priv->channel_managers->len * 2);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  for (i = 0; i < priv->channel_factories->len; i++)
    {
      TpChannelFactoryIface *factory = g_ptr_array_index
        (priv->channel_factories, i);

      tp_channel_factory_iface_foreach (factory,
          list_channel_factory_foreach_one, values);
    }
  G_GNUC_END_IGNORE_DEPRECATIONS

  for (i = 0; i < priv->channel_managers->len; i++)
    {
      TpChannelManager *manager = g_ptr_array_index
        (priv->channel_managers, i);

      tp_channel_manager_foreach_channel (manager,
          list_channel_manager_foreach_one, values);
    }

  channels = g_ptr_array_sized_new (values->len);

  for (i = 0; i < values->len; i++)
    {
      g_ptr_array_add (channels, g_value_get_boxed (g_ptr_array_index
            (values, i)));
    }

  tp_svc_connection_return_from_list_channels (context, channels);

  g_ptr_array_unref (channels);
  for (i = 0; i < values->len; i++)
    {
      tp_g_value_slice_free (g_ptr_array_index (values, i));
    }
  g_ptr_array_unref (values);
}

static void
tp_base_connection_request_channel (TpSvcConnection *iface,
                                    const gchar *type,
                                    guint handle_type,
                                    guint handle,
                                    gboolean suppress_handler,
                                    DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (iface);
  TpBaseConnectionPrivate *priv;
  TpChannelFactoryRequestStatus status =
    TP_CHANNEL_FACTORY_REQUEST_STATUS_NOT_IMPLEMENTED;
  GError *error = NULL;
  guint i;
  ChannelRequest *request;
  GHashTable *request_properties;
  gboolean claimed_by_channel_manager = FALSE;
  TpHandleRepoIface *handle_repo = NULL;

  g_assert (TP_IS_BASE_CONNECTION (self));

  priv = self->priv;

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (self, context);

  if (handle_type == TP_HANDLE_TYPE_NONE)
    {
      if (handle != 0)
        {
          GError e = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
              "When handle type is NONE, handle must be 0" };

          dbus_g_method_return_error (context, &e);
          return;
        }
    }
  else
    {
      handle_repo = tp_base_connection_get_handles (self,
          handle_type);

      if (handle_repo == NULL)
        {
          GError e = { TP_ERROR, TP_ERROR_NOT_AVAILABLE,
              "Handle type not supported by this connection manager" };

          dbus_g_method_return_error (context, &e);
          return;
        }

      if (!tp_handle_is_valid (handle_repo, handle, &error))
        {
          dbus_g_method_return_error (context, error);
          g_error_free (error);
          return;
        }
    }

  request = channel_request_new (context, METHOD_REQUEST_CHANNEL,
      type, handle_type, handle, suppress_handler);
  g_ptr_array_add (priv->channel_requests, request);

  /* First try the channel managers */

  request_properties = tp_asv_new (
      TP_PROP_CHANNEL_CHANNEL_TYPE, G_TYPE_STRING, type,
      TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, G_TYPE_UINT, handle_type,
      NULL);

  if (handle != 0)
    {
      tp_asv_set_uint32 (request_properties,
          TP_PROP_CHANNEL_TARGET_HANDLE, handle);
      g_assert (handle_repo != NULL);
      tp_asv_set_string (request_properties,
          TP_PROP_CHANNEL_TARGET_ID,
          tp_handle_inspect (handle_repo, handle));
    }

  for (i = 0; i < priv->channel_managers->len; i++)
    {
      TpChannelManager *manager = TP_CHANNEL_MANAGER (
          g_ptr_array_index (priv->channel_managers, i));

      if (tp_channel_manager_request_channel (manager, request,
            request_properties))
        {
          claimed_by_channel_manager = TRUE;
          break;
        }
    }

  g_hash_table_unref (request_properties);

  if (claimed_by_channel_manager)
    return;

  /* OK, none of them wanted it. Now try the channel factories */

  for (i = 0; i < priv->channel_factories->len; i++)
    {
      TpChannelFactoryIface *factory = g_ptr_array_index
        (priv->channel_factories, i);
      TpChannelFactoryRequestStatus cur_status;
      TpChannelIface *chan = NULL;

      G_GNUC_BEGIN_IGNORE_DEPRECATIONS
      cur_status = tp_channel_factory_iface_request (factory, type,
          (TpHandleType) handle_type, handle, request, &chan, &error);
      G_GNUC_END_IGNORE_DEPRECATIONS

      switch (cur_status)
        {
        case TP_CHANNEL_FACTORY_REQUEST_STATUS_EXISTING:
          {
            g_assert (NULL != chan);
            factory_satisfy_requests (self, factory, chan, request, FALSE);
            /* factory_satisfy_requests should remove the request */
            g_assert (!tp_g_ptr_array_contains (priv->channel_requests,
                  request));
            return;
          }
        case TP_CHANNEL_FACTORY_REQUEST_STATUS_CREATED:
          g_assert (NULL != chan);
          /* the signal handler should have completed the queued request
           * and freed the ChannelRequest already */
          g_assert (!tp_g_ptr_array_contains (priv->channel_requests,
                request));
          return;
        case TP_CHANNEL_FACTORY_REQUEST_STATUS_QUEUED:
          DEBUG ("queued request, channel_type=%s, handle_type=%u, "
              "handle=%u, suppress_handler=%u", type, handle_type,
              handle, suppress_handler);
          return;
        case TP_CHANNEL_FACTORY_REQUEST_STATUS_ERROR:
          /* pass through error */
          goto ERROR;
        default:
          /* always return the most specific error */
          if (cur_status > status)
            status = cur_status;
        }
    }

  switch (status)
    {
      case TP_CHANNEL_FACTORY_REQUEST_STATUS_INVALID_HANDLE:
        DEBUG ("invalid handle %u", handle);

        error = g_error_new (TP_ERROR, TP_ERROR_INVALID_HANDLE,
                             "invalid handle %u", handle);

        break;

      case TP_CHANNEL_FACTORY_REQUEST_STATUS_NOT_AVAILABLE:
        DEBUG ("requested channel is unavailable with "
                 "handle type %u", handle_type);

        error = g_error_new (TP_ERROR, TP_ERROR_NOT_AVAILABLE,
                             "requested channel is not available with "
                             "handle type %u", handle_type);

        break;

      case TP_CHANNEL_FACTORY_REQUEST_STATUS_NOT_IMPLEMENTED:
        DEBUG ("unsupported channel type %s", type);

        error = g_error_new (TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
                             "unsupported channel type %s", type);

        break;

      default:
        g_assert_not_reached ();
    }

ERROR:
  g_assert (error != NULL);
  dbus_g_method_return_error (request->context, error);
  request->context = NULL;
  g_error_free (error);

  g_ptr_array_remove (priv->channel_requests, request);
  channel_request_free (request);
}

static void
tp_base_connection_release_handles (TpSvcConnection *iface,
                                    guint handle_type,
                                    const GArray * handles,
                                    DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (iface);
  TpBaseConnectionPrivate *priv = self->priv;
  GError *error = NULL;

  g_assert (TP_IS_BASE_CONNECTION (self));

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (self, context);

  if (!tp_handles_supported_and_valid (priv->handles,
        handle_type, handles, FALSE, &error))
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  tp_svc_connection_return_from_release_handles (context);
}

typedef struct
{
  GArray *handles;
  guint n_pending;
  DBusGMethodInvocation *context;
} RequestHandlesData;

typedef struct
{
  RequestHandlesData *request;
  guint pos;
} EnsureHandleData;

static void
ensure_handle_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpHandleRepoIface *repo = (TpHandleRepoIface *) source;
  EnsureHandleData *data = user_data;
  RequestHandlesData *request = data->request;
  TpHandle handle;
  GError *error = NULL;

  /* If another tp_handle_ensure_async() already failed, ignore others */
  if (request->context == NULL)
    goto out;

  handle = tp_handle_ensure_finish (repo, result, &error);
  if (handle == 0)
    {
      dbus_g_method_return_error (request->context, error);
      request->context = NULL;
      g_clear_error (&error);
    }
  else
    {
      TpHandle *handle_p;

      handle_p = &g_array_index (request->handles, TpHandle, data->pos);
      g_assert (*handle_p == 0);
      *handle_p = handle;
    }

out:
  request->n_pending--;
  if (request->n_pending == 0)
    {
      if (request->context != NULL)
        {
          tp_svc_connection_return_from_request_handles (request->context,
              request->handles);
        }
      g_array_unref (request->handles);
      g_slice_free (RequestHandlesData, request);
    }

  g_slice_free (EnsureHandleData, data);
}

/**
 * tp_base_connection_dbus_request_handles: (skip)
 * @iface: A pointer to #TpBaseConnection, cast to a pointer to
 *  #TpSvcConnection
 * @handle_type: The handle type (#TpHandleType) as a guint
 * @names: A strv of handle names
 * @context: The dbus-glib method invocation context
 *
 * Implements D-Bus method RequestHandles on interface
 * org.freedesktop.Telepathy.Connection.
 *
 * This was exported so subclasses could use it as a basis for their
 * reimplementations, but reimplementing the method is now deprecated.
 *
 * Deprecated: 0.19.0
 */
void
tp_base_connection_dbus_request_handles (TpSvcConnection *iface,
                                         guint handle_type,
                                         const gchar **names,
                                         DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (iface);
  TpHandleRepoIface *handle_repo = tp_base_connection_get_handles (self,
      handle_type);
  guint count, i;
  GError *error = NULL;
  RequestHandlesData *request;

  g_return_if_fail (TP_IS_BASE_CONNECTION (self));

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (self, context);

  if (!tp_handle_type_is_valid (handle_type, &error))
    {
      g_assert (error != NULL);
      goto error;
    }

  if (handle_repo == NULL)
    {
      DEBUG ("unimplemented handle type %u", handle_type);

      error = g_error_new (TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
                          "unimplemented handle type %u", handle_type);
      goto error;
    }

  count = g_strv_length ((GStrv) names);

  if (count == 0)
    {
      GArray *tmp = g_array_sized_new (FALSE, TRUE, sizeof (guint), 0);
      tp_svc_connection_return_from_request_handles (context, tmp);
      g_array_unref (tmp);
      return;
    }

  request = g_slice_new0 (RequestHandlesData);
  request->handles = g_array_sized_new (FALSE, TRUE, sizeof (guint), count);
  request->n_pending = count;
  request->context = context;

  /* _sized_new() just pre-allocates memory, but handles->len is still 0 */
  g_array_set_size (request->handles, count);

  for (i = 0; i < count; i++)
    {
      EnsureHandleData *data;

      data = g_slice_new0 (EnsureHandleData);
      data->request = request;
      data->pos = i;

      tp_handle_ensure_async (handle_repo, self, names[i], NULL,
          ensure_handle_cb, data);
    }

  return;

error:
  dbus_g_method_return_error (context, error);
  g_error_free (error);
}

/**
 * tp_base_connection_get_handles:
 * @self: A connection
 * @handle_type: The handle type
 *
 * <!---->
 *
 * Returns: (transfer none): the handle repository corresponding to the given
 * handle type, or #NULL if it's unsupported or invalid.
 */
TpHandleRepoIface *
tp_base_connection_get_handles (TpBaseConnection *self,
                                TpHandleType handle_type)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self), NULL);

  if (handle_type >= TP_NUM_HANDLE_TYPES)
    return NULL;

  return self->priv->handles[handle_type];
}


/**
 * tp_base_connection_get_self_handle: (skip)
 * @self: A connection
 *
 * Returns the #TpBaseConnection:self-handle property, which is guaranteed not
 * to be 0 once the connection has moved to the CONNECTED state.
 *
 * Returns: the current self handle of the connection.
 *
 * Since: 0.7.15
 */
TpHandle
tp_base_connection_get_self_handle (TpBaseConnection *self)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self), 0);

  return self->self_handle;
}

/**
 * tp_base_connection_set_self_handle:
 * @self: A connection
 * @self_handle: The new self handle for the connection.
 *
 * Sets the #TpBaseConnection:self-handle property.  self_handle may not be 0
 * once the connection has moved to the CONNECTED state.
 *
 * Since: 0.7.15
 */
void
tp_base_connection_set_self_handle (TpBaseConnection *self,
                                    TpHandle self_handle)
{
  if (self->status == TP_CONNECTION_STATUS_CONNECTED)
    g_return_if_fail (self_handle != 0);

  if (self->self_handle == self_handle)
    return;

  self->self_handle = self_handle;
  self->priv->self_id = NULL;

  if (self_handle != 0)
    {
      self->priv->self_id = tp_handle_inspect (
          self->priv->handles[TP_HANDLE_TYPE_CONTACT], self_handle);
    }

  tp_svc_connection_emit_self_handle_changed (self, self->self_handle);

  tp_svc_connection_emit_self_contact_changed (self,
      self->self_handle, self->priv->self_id);

  g_object_notify ((GObject *) self, "self-handle");
  g_object_notify ((GObject *) self, "self-id");
}


/**
 * tp_base_connection_finish_shutdown: (skip)
 * @self: The connection
 *
 * Tell the connection manager that this Connection has been disconnected,
 * has emitted StatusChanged and is ready to be removed from D-Bus.
 */
void tp_base_connection_finish_shutdown (TpBaseConnection *self)
{
  GPtrArray *contexts;
  guint i;

  g_return_if_fail (TP_IS_BASE_CONNECTION (self));
  g_return_if_fail (self->status == TP_CONNECTION_STATUS_DISCONNECTED);
  g_return_if_fail (self->priv->disconnect_requests != NULL);

  contexts = self->priv->disconnect_requests;
  self->priv->disconnect_requests = NULL;

  for (i = 0; i < contexts->len; i++)
    {
      tp_svc_connection_return_from_disconnect (g_ptr_array_index (contexts,
            i));
    }

  g_ptr_array_unref (contexts);

  g_signal_emit (self, signals[SHUTDOWN_FINISHED], 0);
}

/**
 * tp_base_connection_disconnect_with_dbus_error: (skip)
 * @self: The connection
 * @error_name: The D-Bus error with which the connection changed status to
 *              Disconnected
 * @details: Further details of the error, as a hash table where the keys
 *           are strings as defined in the Telepathy specification, and the
 *           values are #GValue<!-- -->s. %NULL is allowed, and treated as
 *           an empty hash table.
 * @reason: The reason code to use in the StatusChanged signal
 *          (a less specific, non-extensible version of @error_name)
 *
 * Changes the #TpBaseConnection<!-- -->.status of @self to
 * %TP_CONNECTION_STATUS_DISCONNECTED, as if by a call to
 * tp_base_connection_change_status(), but additionally emits the
 * <code>ConnectionError</code> D-Bus signal to provide more details about the
 * error.
 *
 * Well-known keys for @details are documented in the Telepathy specification's
 * <ulink url='http://telepathy.freedesktop.org/spec/Connection.html#Signal:ConnectionError'>definition
 * of the ConnectionError signal</ulink>, and include:
 *
 * <itemizedlist>
 * <listitem><code>"debug-message"</code>, whose value should have type
 *    #G_TYPE_STRING, for debugging information about the
 *    disconnection which should not be shown to the user</listitem>
 * <listitem><code>"server-message"</code>, whose value should also have type
 *    #G_TYPE_STRING, for a human-readable error message from the server (in an
 *    unspecified language) explaining why the user was
 *    disconnected.</listitem>
 * </itemizedlist>
 *
 * Since: 0.7.24
 */
void
tp_base_connection_disconnect_with_dbus_error (TpBaseConnection *self,
                                               const gchar *error_name,
                                               GHashTable *details,
                                               TpConnectionStatusReason reason)
{
  GHashTable *dup_ = NULL;

  g_return_if_fail (TP_IS_BASE_CONNECTION (self));
  g_return_if_fail (tp_dbus_check_valid_interface_name (error_name, NULL));

  if (details == NULL)
    {
      dup_ = g_hash_table_new (g_str_hash, g_str_equal);
      details = dup_;
    }

  tp_svc_connection_emit_connection_error (self, error_name, details);
  tp_base_connection_change_status (self, TP_CONNECTION_STATUS_DISCONNECTED,
      reason);

  if (dup_ != NULL)
    g_hash_table_unref (dup_);
}

/**
 * tp_base_connection_disconnect_with_dbus_error_vardict: (skip)
 * @self: The connection
 * @error_name: The D-Bus error with which the connection changed status to
 *              Disconnected
 * @details: Further details of the error, as a variant of
 *           type %G_VARIANT_TYPE_VARDICT. The keys
 *           are strings as defined in the Telepathy specification, and the
 *           values are of type %G_VARIANT_TYPE_VARIANT.
 *           %NULL is allowed, and treated as an empty dictionary.
 * @reason: The reason code to use in the StatusChanged signal
 *          (a less specific, non-extensible version of @error_name)
 *
 * Changes the #TpBaseConnection<!-- -->.status of @self to
 * %TP_CONNECTION_STATUS_DISCONNECTED, as if by a call to
 * tp_base_connection_change_status(), but additionally emits the
 * <code>ConnectionError</code> D-Bus signal to provide more details about the
 * error.
 *
 * Well-known keys for @details are documented in the Telepathy specification's
 * <ulink url='http://telepathy.freedesktop.org/spec/Connection.html#Signal:ConnectionError'>definition
 * of the ConnectionError signal</ulink>, and include:
 *
 * <itemizedlist>
 * <listitem><code>"debug-message"</code>, whose value should have type
 *    #G_TYPE_STRING, for debugging information about the
 *    disconnection which should not be shown to the user</listitem>
 * <listitem><code>"server-message"</code>, whose value should also have type
 *    #G_TYPE_STRING, for a human-readable error message from the server (in an
 *    unspecified language) explaining why the user was
 *    disconnected.</listitem>
 * </itemizedlist>
 *
 * Since: 0.7.24
 */
void
tp_base_connection_disconnect_with_dbus_error_vardict (TpBaseConnection *self,
    const gchar *error_name,
    GVariant *details,
    TpConnectionStatusReason reason)
{
  GHashTable *hash;

  g_return_if_fail (TP_IS_BASE_CONNECTION (self));
  g_return_if_fail (tp_dbus_check_valid_interface_name (error_name, NULL));

  if (details == NULL)
    {
      hash = g_hash_table_new (g_str_hash, g_str_equal);
    }
  else
    {
      hash = _tp_asv_from_vardict (details);
    }

  tp_svc_connection_emit_connection_error (self, error_name, hash);
  tp_base_connection_change_status (self, TP_CONNECTION_STATUS_DISCONNECTED,
      reason);

  g_hash_table_unref (hash);
}

/**
 * tp_base_connection_change_status:
 * @self: The connection
 * @status: The new status
 * @reason: The reason for the status change
 *
 * Change the status of the connection. The allowed state transitions are:
 *
 * <itemizedlist>
 * <listitem>#TP_INTERNAL_CONNECTION_STATUS_NEW →
 *    #TP_CONNECTION_STATUS_CONNECTING</listitem>
 * <listitem>#TP_CONNECTION_STATUS_CONNECTING →
 *    #TP_CONNECTION_STATUS_CONNECTED</listitem>
 * <listitem>#TP_INTERNAL_CONNECTION_STATUS_NEW →
 *    #TP_CONNECTION_STATUS_CONNECTED (exactly equivalent to both of the above
 *    one after the other; see below)</listitem>
 * <listitem>anything except #TP_CONNECTION_STATUS_DISCONNECTED →
 *    #TP_CONNECTION_STATUS_DISCONNECTED</listitem>
 * </itemizedlist>
 *
 * Before the transition to #TP_CONNECTION_STATUS_CONNECTED, the implementation
 * must have discovered the handle for the local user and passed it to
 * tp_base_connection_set_self_handle().
 *
 * Changing from NEW to CONNECTED is implemented by doing the transition from
 * NEW to CONNECTING, followed by the transition from CONNECTING to CONNECTED;
 * it's exactly equivalent to calling tp_base_connection_change_status for
 * those two transitions one after the other.
 *
 * Any other valid transition does the following, in this order:
 *
 * <itemizedlist>
 * <listitem>Update #TpBaseConnection<!-- -->.status;</listitem>
 * <listitem>If the new state is #TP_CONNECTION_STATUS_DISCONNECTED, call
 *    tp_channel_factory_iface_close_all() on all channel factories</listitem>
 * <listitem>Emit the D-Bus StatusChanged signal;</listitem>
 * <listitem>Call #TpBaseConnectionClass.connecting,
 *    #TpBaseConnectionClass.connected or #TpBaseConnectionClass.disconnected
 *    as appropriate;</listitem>
 * <listitem>Call the channel factories' status change callbacks;</listitem>
 * <listitem>If the new state is #TP_CONNECTION_STATUS_DISCONNECTED, call the
 *    subclass' #TpBaseConnectionClass.shut_down callback.</listitem>
 * </itemizedlist>
 *
 * To provide more details about what happened when moving to @status
 * #TP_CONNECTION_STATUS_DISCONNECTED due to an error, consider calling
 * tp_base_connection_disconnect_with_dbus_error() instead of this function.
 *
 * Changed in 0.7.35: the @self_handle member of #TpBaseConnection was
 * previously set to 0 at this stage. It now remains non-zero until the object
 * is disposed.
 */
void
tp_base_connection_change_status (TpBaseConnection *self,
                                  TpConnectionStatus status,
                                  TpConnectionStatusReason reason)
{
  TpBaseConnectionPrivate *priv;
  TpBaseConnectionClass *klass;
  TpConnectionStatus prev_status;

  g_assert (TP_IS_BASE_CONNECTION (self));

  priv = self->priv;
  klass = TP_BASE_CONNECTION_GET_CLASS (self);

  if (self->status == TP_INTERNAL_CONNECTION_STATUS_NEW
      && status == TP_CONNECTION_STATUS_CONNECTED)
    {
      /* going straight from NEW to CONNECTED would cause confusion, so before
       * we do anything else, go via CONNECTING */
      DEBUG("from NEW to CONNECTED: going via CONNECTING first");
      tp_base_connection_change_status (self, TP_CONNECTION_STATUS_CONNECTING,
          reason);
    }

  DEBUG("was %u, now %u, for reason %u", self->status, status, reason);
  g_return_if_fail (status != TP_INTERNAL_CONNECTION_STATUS_NEW);

  if (self->status == status)
    {
      WARNING ("attempted to re-emit the current status %u, reason %u",
          status, reason);
      return;
    }

  prev_status = self->status;

  /* make appropriate assertions about our state */
  switch (status)
    {
    case TP_CONNECTION_STATUS_DISCONNECTED:
      /* you can go from any state to DISCONNECTED, except DISCONNECTED;
       * and we already warned and returned if that was the case, so
       * nothing to do here */
      break;
    case TP_CONNECTION_STATUS_CONNECTED:
      /* you can only go to CONNECTED if you're CONNECTING (or NEW, but we
       * covered that by forcing a transition to CONNECTING above) */
      g_return_if_fail (prev_status == TP_CONNECTION_STATUS_CONNECTING);
      /* by the time we go CONNECTED we must have the self handle */
      g_return_if_fail (self->self_handle != 0);
      break;
    case TP_CONNECTION_STATUS_CONNECTING:
      /* you can't go CONNECTING if a connection attempt has been made
       * before */
      g_return_if_fail (prev_status == TP_INTERNAL_CONNECTION_STATUS_NEW);
      break;
    default:
      CRITICAL ("invalid connection status %d", status);
      return;
    }

  /* now that we've finished return_if_fail'ing, we can start to make
   * the actual changes */
  self->status = status;

  /* ref self in case user callbacks unref us */
  g_object_ref (self);

  if (status == TP_CONNECTION_STATUS_DISCONNECTED)
    {
      /* the presence of this array indicates that we are shutting down */
      if (self->priv->disconnect_requests == NULL)
        self->priv->disconnect_requests = g_ptr_array_sized_new (0);

      /* remove all channels and shut down all factories, so we don't get
       * any race conditions where method calls are delivered to a channel
       * after we've started disconnecting
       */
      tp_base_connection_close_all_channels (self);
    }

  DEBUG("emitting status-changed to %u, for reason %u", status, reason);
  tp_svc_connection_emit_status_changed (self, status, reason);

  /* tell subclass and factories about the state change. In the case of
   * disconnection, shut down afterwards */
  switch (status)
    {
    case TP_CONNECTION_STATUS_CONNECTING:
      if (klass->connecting)
        (klass->connecting) (self);
      G_GNUC_BEGIN_IGNORE_DEPRECATIONS
      g_ptr_array_foreach (priv->channel_factories, (GFunc)
          tp_channel_factory_iface_connecting, NULL);
      G_GNUC_END_IGNORE_DEPRECATIONS
      break;

    case TP_CONNECTION_STATUS_CONNECTED:
      /* the implementation should have ensured we have a valid self_handle
       * before changing the state to CONNECTED */

      g_assert (self->self_handle != 0);
      g_assert (tp_handle_is_valid (priv->handles[TP_HANDLE_TYPE_CONTACT],
                self->self_handle, NULL));
      if (klass->connected)
        (klass->connected) (self);
      G_GNUC_BEGIN_IGNORE_DEPRECATIONS
      g_ptr_array_foreach (priv->channel_factories, (GFunc)
          tp_channel_factory_iface_connected, NULL);
      G_GNUC_END_IGNORE_DEPRECATIONS
      break;

    case TP_CONNECTION_STATUS_DISCONNECTED:
      /* cancel all queued channel requests that weren't already cancelled by
       * the channel managers.
       */
      if (priv->channel_requests->len > 0)
        {
          g_ptr_array_foreach (priv->channel_requests, (GFunc)
            channel_request_cancel, NULL);
          g_ptr_array_remove_range (priv->channel_requests, 0,
            priv->channel_requests->len);
        }

      if (prev_status != TP_INTERNAL_CONNECTION_STATUS_NEW)
        {
          if (klass->disconnected)
            (klass->disconnected) (self);
          G_GNUC_BEGIN_IGNORE_DEPRECATIONS
          g_ptr_array_foreach (priv->channel_factories, (GFunc)
              tp_channel_factory_iface_disconnected, NULL);
          G_GNUC_END_IGNORE_DEPRECATIONS
        }
      (klass->shut_down) (self);
      tp_base_connection_unregister (self);
      break;

    default:
      g_assert_not_reached ();
    }

  g_object_unref (self);
}


/**
 * tp_base_connection_add_interfaces: (skip)
 * @self: A TpBaseConnection in state #TP_INTERNAL_CONNECTION_STATUS_NEW
 *  or #TP_CONNECTION_STATUS_CONNECTING
 * @interfaces: A %NULL-terminated array of D-Bus interface names, which
 *  must remain valid at least until the connection enters state
 *  #TP_CONNECTION_STATUS_DISCONNECTED (in practice, you should either
 *  use static strings, or use strdup'd strings and free them in the dispose
 *  callback).
 *
 * Add some interfaces to the list supported by this Connection. If you're
 * going to call this function at all, you must do so before moving to state
 * CONNECTED (or DISCONNECTED); if you don't call it, only the set of
 * interfaces always present (@get_interfaces_always_present in
 * #TpBaseConnectionClass) will be supported.
 */
void
tp_base_connection_add_interfaces (TpBaseConnection *self,
                                   const gchar **interfaces)
{
  TpBaseConnectionPrivate *priv = self->priv;

  g_return_if_fail (TP_IS_BASE_CONNECTION (self));
  g_return_if_fail (self->status != TP_CONNECTION_STATUS_CONNECTED);
  g_return_if_fail (self->status != TP_CONNECTION_STATUS_DISCONNECTED);

  for (; interfaces != NULL && *interfaces != NULL; interfaces++)
    g_array_append_val (priv->interfaces, *interfaces);
}

static void
tp_base_connection_interested_name_owner_changed_cb (
    TpDBusDaemon *it G_GNUC_UNUSED,
    const gchar *unique_name,
    const gchar *new_owner,
    gpointer user_data)
{
  TpBaseConnection *self = user_data;
  GHashTableIter iter;
  gpointer q, hash;

  /* We don't care about the initial report that :1.42 is owned by :1.42. */
  if (!tp_str_empty (new_owner))
    return;

  /* Failing that, @unique_name must have crashed... */

  g_hash_table_iter_init (&iter, self->priv->client_interests);

  while (g_hash_table_iter_next (&iter, &q, &hash))
    {
      if (g_hash_table_remove (hash, unique_name) &&
          g_hash_table_size (hash) == 0)
        {
          const gchar *s = g_quark_to_string (GPOINTER_TO_UINT (q));

          DEBUG ("%s was the last client interested in %s", unique_name, s);
          g_signal_emit (self, signals[CLIENTS_UNINTERESTED],
              (GQuark) GPOINTER_TO_UINT (q), s);
        }
    }

  /* this has to be done last, because the keys in the other hashes are
   * borrowed from here */
  g_hash_table_remove (self->priv->interested_clients, unique_name);

  tp_dbus_daemon_cancel_name_owner_watch (self->priv->bus_proxy,
      unique_name, tp_base_connection_interested_name_owner_changed_cb, self);
}

static void
tp_base_connection_add_client_interest_impl (TpBaseConnection *self,
    const gchar *unique_name,
    const gchar * const *interests,
    gboolean only_if_uninterested)
{
  gpointer name_in_hash, count_p;
  gsize total;
  const gchar * const *interest;
  gboolean was_there;

  if (g_hash_table_lookup_extended (self->priv->interested_clients,
        unique_name, &name_in_hash, &count_p))
    {
      total = GPOINTER_TO_SIZE (count_p);
      was_there = TRUE;
    }
  else
    {
      name_in_hash = g_strdup (unique_name);
      total = 0;
      g_hash_table_insert (self->priv->interested_clients, name_in_hash,
          GSIZE_TO_POINTER (total));
      was_there = FALSE;
    }

  for (interest = interests; *interest != NULL; interest++)
    {
      GQuark q = g_quark_try_string (*interest);
      GHashTable *clients;
      gsize count;

      if (q == 0)
        {
          /* we can only declare an interest in known quarks, so clearly this
           * one is not useful */
          continue;
        }

      clients = g_hash_table_lookup (self->priv->client_interests,
            GUINT_TO_POINTER (q));

      if (clients == NULL)
        {
          /* declaring an interest in this token has no effect */
          continue;
        }

      count = GPOINTER_TO_SIZE (g_hash_table_lookup (clients, unique_name));

      if (count > 0 && only_if_uninterested)
        {
          /* that client is already interested - nothing to do */
          continue;
        }

      /* name_in_hash is borrowed from interested_clients so we have to
       * keep using the same one */
      g_hash_table_insert (clients, name_in_hash,
          GSIZE_TO_POINTER (++count));
      total++;

      if (count == 1 && g_hash_table_size (clients) == 1)
        {
          /* Transition from 0 to 1 interests in total; the signal detail is
           * the token. */
          DEBUG ("%s is the first to be interested in %s", unique_name,
              *interest);
          g_signal_emit (self, signals[CLIENTS_INTERESTED], q, *interest);
        }
    }

  if (total > 0)
    {
      /* name_in_hash is borrowed by client_interests so we have to keep
       * using the same one */
      g_hash_table_steal (self->priv->interested_clients, name_in_hash);
      g_hash_table_insert (self->priv->interested_clients, name_in_hash,
          GSIZE_TO_POINTER (total));

      if (!was_there)
        {
          tp_dbus_daemon_watch_name_owner (self->priv->bus_proxy, unique_name,
              tp_base_connection_interested_name_owner_changed_cb, self, NULL);
        }
    }
  else
    {
      g_hash_table_remove (self->priv->interested_clients, unique_name);

      tp_dbus_daemon_cancel_name_owner_watch (self->priv->bus_proxy,
          unique_name, tp_base_connection_interested_name_owner_changed_cb,
          self);
    }
}

/**
 * tp_base_connection_add_client_interest:
 * @self: a #TpBaseConnection
 * @unique_name: the unique bus name of a D-Bus client
 * @token: a D-Bus interface or a token representing part of an interface,
 *  added with tp_base_connection_add_possible_client_interest()
 * @only_if_uninterested: only add to the interest count if the client is not
 *  already interested (appropriate for APIs that implicitly subscribe on first
 *  use if this has not been done already, like Location)
 *
 * Add a "client interest" for @token on behalf of the given client.
 *
 * This emits #TpBaseConnection::clients-interested if this was the first
 * time a client expressed an interest in this token.
 */
void
tp_base_connection_add_client_interest (TpBaseConnection *self,
    const gchar *unique_name,
    const gchar *token,
    gboolean only_if_uninterested)
{
  const gchar * tokens[2] = { NULL, NULL };

  tokens[0] = token;
  tp_base_connection_add_client_interest_impl (self, unique_name, tokens,
      only_if_uninterested);
}

static void
tp_base_connection_dbus_add_client_interest (TpSvcConnection *svc,
    const gchar **interests,
    DBusGMethodInvocation *context)
{
  TpBaseConnection *self = (TpBaseConnection *) svc;
  gchar *unique_name = NULL;

  g_return_if_fail (TP_IS_BASE_CONNECTION (self));
  g_return_if_fail (self->priv->bus_proxy != NULL);

  if (interests == NULL || interests[0] == NULL)
    goto finally;

  unique_name = dbus_g_method_get_sender (context);

  tp_base_connection_add_client_interest_impl (self, unique_name,
      (const gchar * const *) interests, FALSE);

finally:
  tp_svc_connection_return_from_add_client_interest (context);
  g_free (unique_name);
}

static void
tp_base_connection_dbus_remove_client_interest (TpSvcConnection *svc,
    const gchar **interests,
    DBusGMethodInvocation *context)
{
  gchar *unique_name = NULL;
  const gchar **interest;
  TpBaseConnection *self = (TpBaseConnection *) svc;
  gpointer name_in_hash, count_p;
  gsize total;

  g_return_if_fail (TP_IS_BASE_CONNECTION (self));
  g_return_if_fail (self->priv->bus_proxy != NULL);

  if (interests == NULL || interests[0] == NULL)
    goto finally;

  unique_name = dbus_g_method_get_sender (context);

  /* this method isn't really meant to fail, so we might as well return now */

  if (!g_hash_table_lookup_extended (self->priv->interested_clients,
        unique_name, &name_in_hash, &count_p))
    {
      /* unique_name doesn't own any client interests. Strictly speaking this
       * is an error, but it's probably ignoring the reply anyway, so we
       * won't tell it. */
      goto finally;
    }

  total = GPOINTER_TO_SIZE (count_p);

  for (interest = interests; *interest != NULL; interest++)
    {
      GQuark q = g_quark_try_string (*interest);
      GHashTable *clients;
      gsize count;

      if (q == 0)
        {
          /* we can only declare an interest in known quarks, so clearly this
           * one is not useful */
          continue;
        }

      clients = g_hash_table_lookup (self->priv->client_interests,
            GUINT_TO_POINTER (q));

      if (clients == NULL)
        {
          /* declaring an interest in this token has no effect */
          continue;
        }

      count = GPOINTER_TO_SIZE (g_hash_table_lookup (clients, unique_name));

      if (count == 0)
        {
          /* strictly speaking, this is an error, but nobody will be waiting
           * for a reply anyway */
          DEBUG ("unable to decrement %s interest in %s past zero",
              unique_name, *interest);
          continue;
        }

      total--;

      if (count == 1)
        {
          g_hash_table_remove (clients, unique_name);

          if (g_hash_table_size (clients) == 0)
            {
              /* transition from 1 to 0 total interest-counts */
              DEBUG ("%s was the last client interested in %s", unique_name,
                  *interest);
              g_signal_emit (self, signals[CLIENTS_UNINTERESTED], q,
                  *interest);
            }
        }
      else
        {
          /* name_in_hash is borrowed from interested_clients so we have to
           * keep using the same one */
          g_hash_table_insert (clients, name_in_hash,
              GSIZE_TO_POINTER (--count));
        }
    }

  if (total == 0)
    {
      g_hash_table_remove (self->priv->interested_clients, unique_name);

      tp_dbus_daemon_cancel_name_owner_watch (self->priv->bus_proxy,
          unique_name, tp_base_connection_interested_name_owner_changed_cb,
          self);
    }

finally:
  tp_svc_connection_return_from_remove_client_interest (context);
  g_free (unique_name);
}

static void
conn_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcConnectionClass *klass = g_iface;

#define IMPLEMENT(prefix,x) tp_svc_connection_implement_##x (klass, \
    tp_base_connection_##prefix##x)
  IMPLEMENT(,connect);
  IMPLEMENT(,disconnect);
  IMPLEMENT(dbus_,get_interfaces);
  IMPLEMENT(,get_protocol);
  IMPLEMENT(dbus_,get_self_handle);
  IMPLEMENT(dbus_,get_status);
  IMPLEMENT(,hold_handles);
  IMPLEMENT(,inspect_handles);
  IMPLEMENT(,list_channels);
  IMPLEMENT(,request_channel);
  IMPLEMENT(,release_handles);
G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  IMPLEMENT(dbus_,request_handles);
G_GNUC_END_IGNORE_DEPRECATIONS
  IMPLEMENT(dbus_,add_client_interest);
  IMPLEMENT(dbus_,remove_client_interest);
#undef IMPLEMENT
}


/* The handling of calls to Connection.Interface.Requests.CreateChannel is
 * split into three chained functions, which each call the next function in
 * the chain unless an error has occured.
 */
static void conn_requests_check_basic_properties (TpBaseConnection *self,
    GHashTable *requested_properties, ChannelRequestMethod method,
    DBusGMethodInvocation *context);

static void
conn_requests_requestotron_validate_handle (TpBaseConnection *self,
    GHashTable *requested_properties, ChannelRequestMethod method,
    const gchar *type, TpHandleType target_handle_type,
    TpHandle target_handle, const gchar *target_id,
    DBusGMethodInvocation *context);

static void conn_requests_offer_request (TpBaseConnection *self,
    GHashTable *requested_properties, ChannelRequestMethod method,
    const gchar *type, TpHandleType target_handle_type,
    TpHandle target_handle, DBusGMethodInvocation *context);


#define RETURN_INVALID_ARGUMENT(message) \
  G_STMT_START { \
    GError e = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT, message }; \
    dbus_g_method_return_error (context, &e); \
    return; \
  } G_STMT_END


static void
conn_requests_requestotron (TpBaseConnection *self,
                            GHashTable *requested_properties,
                            ChannelRequestMethod method,
                            DBusGMethodInvocation *context)
{
  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (self, context);

  /* Call the first function in the chain handling incoming requests; it will
   * call the next steps.
   */
  conn_requests_check_basic_properties (self, requested_properties, method,
      context);
}


static void
conn_requests_check_basic_properties (TpBaseConnection *self,
                                      GHashTable *requested_properties,
                                      ChannelRequestMethod method,
                                      DBusGMethodInvocation *context)
{
  /* Step 1:
   *  Check that ChannelType, TargetHandleType, TargetHandle, TargetID have
   *  the correct types, and that ChannelType is not omitted.
   */
  const gchar *type;
  TpHandleType target_handle_type;
  TpHandle target_handle;
  const gchar *target_id;
  gboolean valid;

  type = tp_asv_get_string (requested_properties,
        TP_PROP_CHANNEL_CHANNEL_TYPE);

  if (type == NULL)
    RETURN_INVALID_ARGUMENT ("ChannelType is required");

  target_handle_type = tp_asv_get_uint32 (requested_properties,
      TP_PROP_CHANNEL_TARGET_HANDLE_TYPE, &valid);

  /* Allow TargetHandleType to be missing, but not to be otherwise broken */
  if (!valid && tp_asv_lookup (requested_properties,
          TP_PROP_CHANNEL_TARGET_HANDLE_TYPE) != NULL)
    RETURN_INVALID_ARGUMENT (
        "TargetHandleType must be an integer in range 0 to 2**32-1");

  target_handle = tp_asv_get_uint32 (requested_properties,
      TP_PROP_CHANNEL_TARGET_HANDLE, &valid);

  /* Allow TargetHandle to be missing, but not to be otherwise broken */
  if (!valid && tp_asv_lookup (requested_properties,
          TP_PROP_CHANNEL_TARGET_HANDLE) != NULL)
    RETURN_INVALID_ARGUMENT (
      "TargetHandle must be an integer in range 1 to 2**32-1");

  /* TargetHandle may not be 0 */
  if (valid && target_handle == 0)
    RETURN_INVALID_ARGUMENT ("TargetHandle may not be 0");

  target_id = tp_asv_get_string (requested_properties,
      TP_PROP_CHANNEL_TARGET_ID);

  /* Allow TargetID to be missing, but not to be otherwise broken */
  if (target_id == NULL && tp_asv_lookup (requested_properties,
          TP_PROP_CHANNEL_TARGET_ID) != NULL)
    RETURN_INVALID_ARGUMENT ("TargetID must be a string");

  if (tp_asv_lookup (requested_properties, TP_PROP_CHANNEL_INITIATOR_HANDLE)
      != NULL)
    RETURN_INVALID_ARGUMENT ("InitiatorHandle may not be requested");

  if (tp_asv_lookup (requested_properties, TP_PROP_CHANNEL_INITIATOR_ID)
      != NULL)
    RETURN_INVALID_ARGUMENT ("InitiatorID may not be requested");

  if (tp_asv_lookup (requested_properties, TP_PROP_CHANNEL_REQUESTED)
      != NULL)
    RETURN_INVALID_ARGUMENT ("Requested may not be requested");

  conn_requests_requestotron_validate_handle (self,
      requested_properties, method,
      type, target_handle_type, target_handle, target_id,
      context);
}


/*
 * @target_handle: non-zero if a TargetHandle property was in the request;
 *                 zero if TargetHandle was not in the request.
 */
static void
conn_requests_requestotron_validate_handle (TpBaseConnection *self,
                                            GHashTable *requested_properties,
                                            ChannelRequestMethod method,
                                            const gchar *type,
                                            TpHandleType target_handle_type,
                                            TpHandle target_handle,
                                            const gchar *target_id,
                                            DBusGMethodInvocation *context)
{
  /* Step 2: Validate the supplied set of Handle properties */
  TpHandleRepoIface *handles = NULL;
  GHashTable *altered_properties = NULL;
  GValue *target_handle_value = NULL;
  GValue *target_id_value = NULL;

  /* Handle type 0 cannot have a handle */
  if (target_handle_type == TP_HANDLE_TYPE_NONE && target_handle != 0)
    RETURN_INVALID_ARGUMENT (
        "When TargetHandleType is NONE, TargetHandle must be omitted");

  /* Handle type 0 cannot have a target id */
  if (target_handle_type == TP_HANDLE_TYPE_NONE && target_id != NULL)
    RETURN_INVALID_ARGUMENT (
      "When TargetHandleType is NONE, TargetID must be omitted");

  if (target_handle_type != TP_HANDLE_TYPE_NONE)
    {
      GError *error = NULL;

      if (target_handle == 0 && target_id == NULL)
        RETURN_INVALID_ARGUMENT ("When TargetHandleType is not None, either "
            "TargetHandle or TargetID must also be given");

      if (target_handle != 0 && target_id != NULL)
        RETURN_INVALID_ARGUMENT (
            "TargetHandle and TargetID must not both be given");

      handles = tp_base_connection_get_handles (self, target_handle_type);

      if (handles == NULL)
        {
          GError e = { TP_ERROR, TP_ERROR_NOT_AVAILABLE,
              "Handle type not supported by this connection manager" };

          dbus_g_method_return_error (context, &e);
          return;
        }

      if (target_handle == 0)
        {
          /* Turn TargetID into TargetHandle */
          target_handle = tp_handle_ensure (handles, target_id, NULL, &error);

          if (target_handle == 0)
            {
              /* tp_handle_ensure can return any error in any domain; force
               * the domain and code to be as documented for CreateChannel.
               */
              error->domain = TP_ERROR;
              error->code = TP_ERROR_INVALID_HANDLE;
              dbus_g_method_return_error (context, error);
              g_error_free (error);
              return;
            }

          altered_properties = g_hash_table_new_full (g_str_hash, g_str_equal,
              NULL, NULL);
          tp_g_hash_table_update (altered_properties, requested_properties,
              NULL, NULL);

          target_handle_value = tp_g_value_slice_new_uint (target_handle);
          g_hash_table_insert (altered_properties,
              TP_PROP_CHANNEL_TARGET_HANDLE, target_handle_value);

          requested_properties = altered_properties;
        }
      else
        {
          /* Check the supplied TargetHandle is valid */
          if (!tp_handle_is_valid (handles, target_handle, &error))
            {
              error->domain = TP_ERROR;
              error->code = TP_ERROR_INVALID_HANDLE;
              dbus_g_method_return_error (context, error);
              g_error_free (error);
              return;
            }

          altered_properties = g_hash_table_new_full (g_str_hash, g_str_equal,
              NULL, NULL);
          tp_g_hash_table_update (altered_properties, requested_properties,
              NULL, NULL);

          target_id_value = tp_g_value_slice_new_string (
              tp_handle_inspect (handles, target_handle));
          g_hash_table_insert (altered_properties,
              TP_PROP_CHANNEL_TARGET_ID,
              target_id_value);

          requested_properties = altered_properties;
        }
    }

  conn_requests_offer_request (self, requested_properties, method, type,
      target_handle_type, target_handle, context);

  /* If we made a new table, we should destroy it, and whichever of the GValues
   * holding TargetHandle or TargetID we filled in.  The other GValues are
   * borrowed from the supplied requested_properties table.
   */
  if (altered_properties != NULL)
    {
      g_hash_table_unref (altered_properties);

      if (target_handle_value != NULL)
        tp_g_value_slice_free (target_handle_value);

      if (target_id_value != NULL)
        tp_g_value_slice_free (target_id_value);
    }
}


static void
conn_requests_offer_request (TpBaseConnection *self,
                             GHashTable *requested_properties,
                             ChannelRequestMethod method,
                             const gchar *type,
                             TpHandleType target_handle_type,
                             TpHandle target_handle,
                             DBusGMethodInvocation *context)
{
  /* Step 3: offer the incoming, vaguely sanitized request to the channel
   * managers.
   */
  TpBaseConnectionPrivate *priv = self->priv;
  TpChannelManagerRequestFunc func;
  ChannelRequest *request;
  gboolean suppress_handler;
  guint i;

  switch (method)
    {
    case METHOD_CREATE_CHANNEL:
      func = tp_channel_manager_create_channel;
      suppress_handler = TRUE;
      break;

    case METHOD_ENSURE_CHANNEL:
      func = tp_channel_manager_ensure_channel;
      suppress_handler = FALSE;
      break;

    default:
      g_assert_not_reached ();
    }

  request = channel_request_new (context, method,
      type, target_handle_type, target_handle, suppress_handler);
  g_ptr_array_add (priv->channel_requests, request);

  for (i = 0; i < priv->channel_managers->len; i++)
    {
      TpChannelManager *manager = TP_CHANNEL_MANAGER (
          g_ptr_array_index (priv->channel_managers, i));

      if (func (manager, request, requested_properties))
        return;
    }

  /* Nobody accepted the request */
  tp_dbus_g_method_return_not_implemented (context);
  request->context = NULL;

  g_ptr_array_remove (priv->channel_requests, request);
  channel_request_free (request);
}


static void
conn_requests_create_channel (TpSvcConnectionInterfaceRequests *svc,
                              GHashTable *requested_properties,
                              DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (svc);

  conn_requests_requestotron (self, requested_properties,
      METHOD_CREATE_CHANNEL, context);
}


static void
conn_requests_ensure_channel (TpSvcConnectionInterfaceRequests *svc,
                              GHashTable *requested_properties,
                              DBusGMethodInvocation *context)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (svc);

  conn_requests_requestotron (self, requested_properties,
      METHOD_ENSURE_CHANNEL, context);
}


static void
requests_iface_init (gpointer g_iface,
                     gpointer iface_data G_GNUC_UNUSED)
{
  TpSvcConnectionInterfaceRequestsClass *iface = g_iface;

#define IMPLEMENT(x) \
    tp_svc_connection_interface_requests_implement_##x (\
        iface, conn_requests_##x)
  IMPLEMENT (create_channel);
  IMPLEMENT (ensure_channel);
#undef IMPLEMENT
}


/**
 * tp_base_connection_channel_manager_iter_init: (skip)
 * @iter: an uninitialized #TpChannelManagerIter
 * @self: a connection
 *
 * Initializes an iterator over the #TpChannelManager objects known to
 * @self.  It is intended to be used as followed:
 *
 * <informalexample><programlisting>
 * TpChannelManagerIter iter;
 * TpChannelManager *manager;
 *
 * tp_base_connection_channel_manager_iter_init (&amp;iter, base_conn);
 * while (tp_base_connection_channel_manager_iter_next (&amp;iter, &amp;manager))
 *   {
 *     ...do something with manager...
 *   }
 * </programlisting></informalexample>
 *
 * Since: 0.7.15
 */
void
tp_base_connection_channel_manager_iter_init (TpChannelManagerIter *iter,
                                              TpBaseConnection *self)
{
  g_return_if_fail (TP_IS_BASE_CONNECTION (self));

  iter->self = self;
  iter->index = 0;
}


/**
 * tp_base_connection_channel_manager_iter_next: (skip)
 * @iter: an initialized #TpChannelManagerIter
 * @manager_out: a location to store the channel manager, or %NULL.
 *
 * Advances @iter, and retrieves the #TpChannelManager it now points to.  If
 * there are no more channel managers, @manager_out is not set and %FALSE is
 * returned.
 *
 * Returns: %FALSE if there are no more channel managers; else %TRUE.
 *
 * Since: 0.7.15
 */
gboolean
tp_base_connection_channel_manager_iter_next (TpChannelManagerIter *iter,
                                              TpChannelManager **manager_out)
{
  TpBaseConnectionPrivate *priv;

  /* Check the caller initialized the iterator properly. */
  g_assert (TP_IS_BASE_CONNECTION (iter->self));

  priv = iter->self->priv;

  /* Be noisy if something's gone really wrong */
  g_return_val_if_fail (iter->index <= priv->channel_managers->len, FALSE);

  if (iter->index == priv->channel_managers->len)
    return FALSE;

  if (manager_out != NULL)
    *manager_out = TP_CHANNEL_MANAGER (
        g_ptr_array_index (priv->channel_managers, iter->index));

  iter->index++;
  return TRUE;
}


static void
tp_base_connection_fill_contact_attributes (GObject *obj,
  const GArray *contacts, GHashTable *attributes_hash)
{
  TpBaseConnection *self = TP_BASE_CONNECTION (obj);
  TpBaseConnectionPrivate *priv = self->priv;
  guint i;

  for (i = 0; i < contacts->len; i++)
    {
      TpHandle handle;
      const gchar *tmp;

      handle = g_array_index (contacts, TpHandle, i);
      tmp = tp_handle_inspect (priv->handles[TP_HANDLE_TYPE_CONTACT], handle);
      g_assert (tmp != NULL);

      tp_contacts_mixin_set_contact_attribute (attributes_hash,
          handle, TP_TOKEN_CONNECTION_CONTACT_ID,
          tp_g_value_slice_new_string (tmp));
    }
}

/**
 * tp_base_connection_register_with_contacts_mixin: (skip)
 * @self: An instance of the #TpBaseConnections that uses the Contacts
 * mixin
 *
 * Register the Connection interface with the Contacts interface to make it
 * inspectable. The Contacts mixin should be initialized before this function
 * is called
 */
void
tp_base_connection_register_with_contacts_mixin (TpBaseConnection *self)
{
  g_return_if_fail (TP_IS_BASE_CONNECTION (self));

  tp_contacts_mixin_add_contact_attributes_iface (G_OBJECT (self),
      TP_IFACE_CONNECTION,
      tp_base_connection_fill_contact_attributes);
}

/**
 * tp_base_connection_get_dbus_daemon: (skip)
 * @self: the connection manager
 *
 * <!-- -->
 *
 * Returns: (transfer none): the value of the
 *  #TpBaseConnectionManager:dbus-daemon property. The caller must reference
 *  the returned object with g_object_ref() if it will be kept.
 *
 * Since: 0.11.3
 */
TpDBusDaemon *
tp_base_connection_get_dbus_daemon (TpBaseConnection *self)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self), NULL);

  return self->priv->bus_proxy;
}

gpointer
_tp_base_connection_find_channel_manager (TpBaseConnection *self,
    GType type)
{
  guint i;

  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self), NULL);

  for (i = 0; i < self->priv->channel_managers->len; i++)
    {
      gpointer manager = g_ptr_array_index (self->priv->channel_managers, i);

      if (g_type_is_a (G_OBJECT_TYPE (manager), type))
        {
          return manager;
        }
    }

  return NULL;
}

/**
 * tp_base_connection_get_bus_name:
 * @self: the connection
 *
 * Return the bus name starting with %TP_CONN_BUS_NAME_BASE that represents
 * this connection on D-Bus.
 *
 * The returned string belongs to the #TpBaseConnection and must be copied
 * by the caller if it will be kept.
 *
 * If this connection has never been present on D-Bus
 * (tp_base_connection_register() has never been called), return %NULL
 * instead.
 *
 * Returns: (allow-none) (transfer none): the bus name of this connection,
 *  or %NULL
 * Since: 0.19.1
 */
const gchar *
tp_base_connection_get_bus_name (TpBaseConnection *self)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self), NULL);

  return self->bus_name;
}

/**
 * tp_base_connection_get_object_path:
 * @self: the connection
 *
 * Return the object path starting with %TP_CONN_OBJECT_PATH_BASE that
 * represents this connection on D-Bus.
 *
 * The returned string belongs to the #TpBaseConnection and must be copied
 * by the caller if it will be kept.
 *
 * If this connection has never been present on D-Bus
 * (tp_base_connection_register() has never been called), return %NULL
 * instead.
 *
 * Returns: (allow-none) (transfer none): the object path of this connection,
 *  or %NULL
 * Since: 0.19.1
 */
const gchar *
tp_base_connection_get_object_path (TpBaseConnection *self)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self), NULL);

  return self->object_path;
}

/**
 * tp_base_connection_get_account_path_suffix:
 * @self: the connection
 *
 * <!-- -->
 *
 * Returns: the same value has the #TpBaseConnection:account-path-suffix
 *  property.
 * Since: 0.23.2
 */
const gchar *
tp_base_connection_get_account_path_suffix (TpBaseConnection *self)
{
  g_return_val_if_fail (TP_IS_BASE_CONNECTION (self), NULL);

  return self->priv->account_path_suffix;
}
