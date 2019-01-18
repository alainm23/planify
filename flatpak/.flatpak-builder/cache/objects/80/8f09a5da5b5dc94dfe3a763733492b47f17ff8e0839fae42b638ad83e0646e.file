/*
 * stream-tube-channel.h - high level API for StreamTube channels
 *
 * Copyright (C) 2010 Collabora Ltd. <http://www.collabora.co.uk/>
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
 * SECTION:stream-tube-channel
 * @title: TpStreamTubeChannel
 * @short_description: proxy object for a stream tube channel
 *
 * #TpStreamTubeChannel is a sub-class of #TpChannel providing convenient API
 * to offer and accept a stream tube.
 *
 * Since: 0.13.2
 */

/**
 * TpStreamTubeChannel:
 *
 * Data structure representing a #TpStreamTubeChannel.
 *
 * Since: 0.13.2
 */

/**
 * TpStreamTubeChannelClass:
 *
 * The class of a #TpStreamTubeChannel.
 *
 * Since: 0.13.2
 */

#include "config.h"

#include "telepathy-glib/stream-tube-channel.h"

#include <telepathy-glib/contact.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/gnio-util.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/stream-tube-connection-internal.h>
#include <telepathy-glib/util-internal.h>
#include <telepathy-glib/util.h>
#include <telepathy-glib/variant-util-internal.h>

#define DEBUG_FLAG TP_DEBUG_CHANNEL
#include "telepathy-glib/channel-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/automatic-client-factory-internal.h"

#include <stdio.h>
#include <glib/gstdio.h>

#ifdef HAVE_GIO_UNIX
#include <gio/gunixsocketaddress.h>
#include <gio/gunixconnection.h>
#endif /* HAVE_GIO_UNIX */

G_DEFINE_TYPE (TpStreamTubeChannel, tp_stream_tube_channel, TP_TYPE_CHANNEL)

/* Used to store the data of a NewRemoteConnection signal while we are waiting
 * for the TCP connection identified by this signal */
typedef struct
{
  TpHandle handle;
  GValue *param;
  guint connection_id;
  gboolean rejected;
} SigWaitingConn;

static SigWaitingConn *
sig_waiting_conn_new (TpHandle handle,
    const GValue *param,
    guint connection_id,
    gboolean rejected)
{
  SigWaitingConn *ret = g_slice_new0 (SigWaitingConn);

  ret->handle = handle;
  ret->param = tp_g_value_slice_dup (param);
  ret->connection_id = connection_id;
  ret->rejected = rejected;
  return ret;
}

static void
sig_waiting_conn_free (SigWaitingConn *sig)
{
  g_assert (sig != NULL);

  tp_g_value_slice_free (sig->param);
  g_slice_free (SigWaitingConn, sig);
}

typedef struct
{
  GSocketConnection *conn;
  /* Used only with TP_SOCKET_ACCESS_CONTROL_CREDENTIALS to store the byte
   * read with the credentials. */
  guchar byte;
} ConnWaitingSig;

static ConnWaitingSig *
conn_waiting_sig_new (GSocketConnection *conn,
    guchar byte)
{
  ConnWaitingSig *ret = g_slice_new0 (ConnWaitingSig);

  ret->conn = g_object_ref (conn);
  ret->byte = byte;
  return ret;
}

static void
conn_waiting_sig_free (ConnWaitingSig *c)
{
  g_assert (c != NULL);

  g_object_unref (c->conn);
  g_slice_free (ConnWaitingSig, c);
}

struct _TpStreamTubeChannelPrivate
{
  GHashTable *parameters;

  /* Offering side */
  GSocketService *service;
  GSocketAddress *address;
  gchar *unix_tmpdir;
  /* GSocketConnection we have accepted but are still waiting a
   * NewRemoteConnection to identify them. Owned ConnWaitingSig. */
  GSList *conn_waiting_sig;
  /* NewRemoteConnection signals we have received but didn't accept their TCP
   * connection yet. Owned SigWaitingConn. */
  GSList *sig_waiting_conn;

  /* Accepting side */
  GSocket *client_socket;
  /* The access_control_param we passed to Accept */
  GValue *access_control_param;
  /* Connection to the CM while we are waiting for its
   * ID (NewLocalConnection) */
  GSocketConnection *local_conn_waiting_id;
  /* ID received from NewLocalConnection stored while the connection has not
   * be connected yet. */
  guint local_conn_id;
  /* TRUE if local_conn_id is meaningfull (0 can be a valid ID so we can't use
   * it to check if NewLocalConnection has been received :\ ) */
  gboolean local_conn_id_set;

  TpSocketAddressType socket_type;
  TpSocketAccessControl access_control;

  GSimpleAsyncResult *result;

  /* (guint) connection ID => weakly reffed TpStreamTubeConnection */
  GHashTable *tube_connections;
};

enum
{
  PROP_SERVICE = 1,
  PROP_PARAMETERS,
  PROP_PARAMETERS_VARDICT
};

enum /* signals */
{
  INCOMING,
  LAST_SIGNAL
};

static guint _signals[LAST_SIGNAL] = { 0, };

static void
remote_connection_destroyed_cb (gpointer user_data,
    GObject *conn)
{
  /* The GSocketConnection has been destroyed, removing it from the hash */
  TpStreamTubeChannel *self = user_data;
  GHashTableIter iter;
  gpointer value;

  g_hash_table_iter_init (&iter, self->priv->tube_connections);
  while (g_hash_table_iter_next (&iter, NULL, &value))
    {
      if (value == conn)
        {
          g_hash_table_iter_remove (&iter);
          break;
        }
    }
}

static void
tp_stream_tube_channel_dispose (GObject *obj)
{
  TpStreamTubeChannel *self = (TpStreamTubeChannel *) obj;

  if (self->priv->service != NULL)
    {
      g_socket_service_stop (self->priv->service);

      tp_clear_object (&self->priv->service);
    }

  tp_clear_object (&self->priv->result);
  tp_clear_pointer (&self->priv->parameters, g_hash_table_unref);

  g_slist_foreach (self->priv->conn_waiting_sig, (GFunc) conn_waiting_sig_free,
      NULL);
  tp_clear_pointer (&self->priv->conn_waiting_sig, g_slist_free);

  g_slist_foreach (self->priv->sig_waiting_conn, (GFunc) sig_waiting_conn_free,
      NULL);
  tp_clear_pointer (&self->priv->sig_waiting_conn, g_slist_free);

  if (self->priv->tube_connections != NULL)
    {
      GHashTableIter iter;
      gpointer conn;

      g_hash_table_iter_init (&iter, self->priv->tube_connections);
      while (g_hash_table_iter_next (&iter, NULL, &conn))
        {
          g_object_weak_unref (conn, remote_connection_destroyed_cb, self);
        }

      g_hash_table_unref (self->priv->tube_connections);
      self->priv->tube_connections = NULL;
    }

  if (self->priv->address != NULL)
    {
#ifdef HAVE_GIO_UNIX
      /* check if we need to remove the temporary file we created */
      if (G_IS_UNIX_SOCKET_ADDRESS (self->priv->address))
        {
          const gchar *path;

          path = g_unix_socket_address_get_path (
              G_UNIX_SOCKET_ADDRESS (self->priv->address));
          g_unlink (path);
        }
#endif /* HAVE_GIO_UNIX */

      g_object_unref (self->priv->address);
      self->priv->address = NULL;
    }

    if (self->priv->unix_tmpdir != NULL)
      {
        g_rmdir (self->priv->unix_tmpdir);
        g_free (self->priv->unix_tmpdir);
        self->priv->unix_tmpdir = NULL;
      }

  tp_clear_pointer (&self->priv->access_control_param, tp_g_value_slice_free);
  tp_clear_object (&self->priv->local_conn_waiting_id);
  tp_clear_object (&self->priv->client_socket);

  G_OBJECT_CLASS (tp_stream_tube_channel_parent_class)->dispose (obj);
}

static void
tp_stream_tube_channel_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpStreamTubeChannel *self = (TpStreamTubeChannel *) object;

  switch (property_id)
    {
      case PROP_SERVICE:
        g_value_set_string (value, tp_stream_tube_channel_get_service (self));
        break;

      case PROP_PARAMETERS:
        g_value_set_boxed (value, self->priv->parameters);
        break;

      case PROP_PARAMETERS_VARDICT:
        g_value_take_variant (value,
            tp_stream_tube_channel_dup_parameters_vardict (self));
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
    }
}

static void
connection_closed_cb (TpChannel *channel,
    guint connection_id,
    const gchar *err,
    const gchar *message,
    gpointer user_data,
    GObject *weak_object)
{
  TpStreamTubeChannel *self = (TpStreamTubeChannel *) weak_object;
  TpStreamTubeConnection *tube_conn;
  GError *error = NULL;

  DEBUG ("Got ConnectionClosed signal on connection %u: %s (%s)",
      connection_id, err, message);

  tube_conn = g_hash_table_lookup (self->priv->tube_connections,
      GUINT_TO_POINTER (connection_id));
  if (tube_conn == NULL)
    {
      DEBUG ("No connection with ID %u; ignoring", connection_id);
      return;
    }

  tp_proxy_dbus_error_to_gerror (self, err, message, &error);

  _tp_stream_tube_connection_fire_closed (tube_conn, error);

  g_error_free (error);
}

static void
tp_stream_tube_channel_constructed (GObject *obj)
{
  TpStreamTubeChannel *self = (TpStreamTubeChannel *) obj;
  void (*chain_up) (GObject *) =
    ((GObjectClass *) tp_stream_tube_channel_parent_class)->constructed;
  TpChannel *chan = (TpChannel *) obj;
  GHashTable *props;
  GError *err = NULL;

  if (chain_up != NULL)
    chain_up (obj);

  if (tp_channel_get_channel_type_id (chan) !=
      TP_IFACE_QUARK_CHANNEL_TYPE_STREAM_TUBE)
    {
      GError error = { TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
          "Channel is not a stream tube" };

      DEBUG ("Channel is not a stream tube: %s", tp_channel_get_channel_type (
            chan));

      tp_proxy_invalidate (TP_PROXY (self), &error);
      return;
    }

  props = _tp_channel_get_immutable_properties (TP_CHANNEL (self));

  if (tp_asv_get_string (props, TP_PROP_CHANNEL_TYPE_STREAM_TUBE_SERVICE)
      == NULL)
    {
      GError error = { TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
          "Tube doesn't have StreamTube.Service property" };

      DEBUG ("%s", error.message);

      tp_proxy_invalidate (TP_PROXY (self), &error);
      return;
    }

   /*  Tube.Parameters is immutable for incoming tubes. For outgoing ones,
    *  it's defined when offering the tube. */
  if (!tp_channel_get_requested (TP_CHANNEL (self)))
    {
      GHashTable *params;

      params = tp_asv_get_boxed (props,
          TP_PROP_CHANNEL_INTERFACE_TUBE_PARAMETERS,
          TP_HASH_TYPE_STRING_VARIANT_MAP);

      if (params == NULL)
        {
          DEBUG ("Incoming tube doesn't have Tube.Parameters property");

          self->priv->parameters = tp_asv_new (NULL, NULL);
        }
      else
        {
          self->priv->parameters = g_boxed_copy (
              TP_HASH_TYPE_STRING_VARIANT_MAP, params);
        }
    }

  tp_cli_channel_type_stream_tube_connect_to_connection_closed (
      TP_CHANNEL (self), connection_closed_cb, NULL, NULL,
      G_OBJECT (self), &err);

  if (err != NULL)
    {
      DEBUG ("Failed to connect to ConnectionClosed signal: %s",
          err->message);

      g_error_free (err);
    }
}

static void
tp_stream_tube_channel_class_init (TpStreamTubeChannelClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);
  GParamSpec *param_spec;

  gobject_class->constructed = tp_stream_tube_channel_constructed;
  gobject_class->get_property = tp_stream_tube_channel_get_property;
  gobject_class->dispose = tp_stream_tube_channel_dispose;

  /**
   * TpStreamTubeChannel:service:
   *
   * A string representing the service name that will be used over the tube.
   *
   * Since: 0.13.2
   */
  param_spec = g_param_spec_string ("service", "Service",
      "The service of the stream tube",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_SERVICE, param_spec);

  /**
   * TpStreamTubeChannel:parameters:
   *
   * A string to #GValue #GHashTable representing the parameters of the tube.
   *
   * Will be %NULL for outgoing tubes until the tube has been offered.
   *
   * In high-level language bindings, use
   * #TpStreamTubeChannel:parameters-vardict or
   * tp_stream_tube_channel_dup_parameters_vardict() to get the same
   * information in a more convenient format.
   *
   * Since: 0.13.2
   */
  param_spec = g_param_spec_boxed ("parameters", "Parameters",
      "The parameters of the stream tube",
      TP_HASH_TYPE_STRING_VARIANT_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_PARAMETERS, param_spec);

  /**
   * TpStreamTubeChannel:parameters-vardict:
   *
   * A %G_VARIANT_TYPE_VARDICT representing the parameters of the tube.
   *
   * Will be %NULL for outgoing tubes until the tube has been offered.
   *
   * Since: 0.19.10
   */
  param_spec = g_param_spec_variant ("parameters-vardict", "Parameters",
      "The parameters of the stream tube",
      G_VARIANT_TYPE_VARDICT, NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (gobject_class, PROP_PARAMETERS_VARDICT,
      param_spec);

  /**
   * TpStreamTubeChannel::incoming:
   * @self: the #TpStreamTubeChannel
   * @tube_connection: the #TpStreamTubeConnection for the connection
   *
   * The ::incoming signal is emitted on offered Tubes when a new incoming
   * connection is made from a remote user (one accepting the Tube).
   *
   * Consumers of this signal must take their own references to
   * @tube_connection
   */
  _signals[INCOMING] = g_signal_new ("incoming",
      G_OBJECT_CLASS_TYPE (klass),
      G_SIGNAL_RUN_LAST,
      0, NULL, NULL, NULL,
      G_TYPE_NONE,
      1, TP_TYPE_STREAM_TUBE_CONNECTION);

  g_type_class_add_private (gobject_class, sizeof (TpStreamTubeChannelPrivate));
}

static void
tp_stream_tube_channel_init (TpStreamTubeChannel *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), TP_TYPE_STREAM_TUBE_CHANNEL,
      TpStreamTubeChannelPrivate);

  self->priv->tube_connections = g_hash_table_new (NULL, NULL);
}


/**
 * tp_stream_tube_channel_new:
 * @conn: a #TpConnection; may not be %NULL
 * @object_path: the object path of the channel; may not be %NULL
 * @immutable_properties: (transfer none) (element-type utf8 GObject.Value):
 *  the immutable properties of the channel,
 *  as signalled by the NewChannel D-Bus signal or returned by the
 *  CreateChannel and EnsureChannel D-Bus methods: a mapping from
 *  strings (D-Bus interface name + "." + property name) to #GValue instances
 * @error: used to indicate the error if %NULL is returned
 *
 * Creates a new #TpStreamTubeChannel proxy object from the provided path and
 * properties. Most developers will not need to use this function; use
 * #TpAutomaticProxyFactory to automatically create #TpStreamTubeChannel proxy
 * objects.
 *
 * Returns: (transfer full): a newly-created #TpStreamTubeChannel proxy
 *
 * Since: 0.13.2
 * Deprecated: Use tp_simple_client_factory_ensure_channel() instead.
 */
TpStreamTubeChannel *
tp_stream_tube_channel_new (TpConnection *conn,
    const gchar *object_path,
    const GHashTable *immutable_properties,
    GError **error)
{
  return _tp_stream_tube_channel_new_with_factory (NULL, conn, object_path,
      immutable_properties, error);
}

TpStreamTubeChannel *
_tp_stream_tube_channel_new_with_factory (
    TpSimpleClientFactory *factory,
    TpConnection *conn,
    const gchar *object_path,
    const GHashTable *immutable_properties,
    GError **error)
{
  TpProxy *conn_proxy = (TpProxy *) conn;

  g_return_val_if_fail (TP_IS_CONNECTION (conn), NULL);
  g_return_val_if_fail (object_path != NULL, NULL);
  g_return_val_if_fail (immutable_properties != NULL, NULL);

  if (!tp_dbus_check_valid_object_path (object_path, error))
    return NULL;

  return g_object_new (TP_TYPE_STREAM_TUBE_CHANNEL,
      "connection", conn,
       "dbus-daemon", conn_proxy->dbus_daemon,
       "bus-name", conn_proxy->bus_name,
       "object-path", object_path,
       "handle-type", (guint) TP_UNKNOWN_HANDLE_TYPE,
       "channel-properties", immutable_properties,
       "factory", factory,
       NULL);
}

static void
operation_failed (TpStreamTubeChannel *self,
    const GError *error)
{
  g_simple_async_result_set_from_error (self->priv->result, error);

  g_simple_async_result_complete_in_idle (self->priv->result);
  tp_clear_object (&self->priv->result);
}

static void
complete_accept_operation (TpStreamTubeChannel *self,
    TpStreamTubeConnection *tube_conn)
{
  g_simple_async_result_set_op_res_gpointer (self->priv->result,
      g_object_ref (tube_conn), g_object_unref);
  g_simple_async_result_complete (self->priv->result);
  tp_clear_object (&self->priv->result);
}

static void
new_local_connection_with_contact (TpConnection *conn,
    guint n_contacts,
    TpContact * const *contacts,
    guint n_failed,
    const TpHandle *failed,
    const GError *in_error,
    gpointer user_data,
    GObject *obj)
{
  TpStreamTubeChannel *self = (TpStreamTubeChannel *) obj;
  TpContact *contact;
  TpStreamTubeConnection *tube_conn = user_data;

  if (in_error != NULL)
    {
      DEBUG ("Failed to prepare TpContact: %s", in_error->message);
      return;
    }

  if (n_failed > 0)
    {
      DEBUG ("Failed to prepare TpContact (InvalidHandle)");
      return;
    }

  contact = contacts[0];
  _tp_stream_tube_connection_set_contact (tube_conn, contact);

  complete_accept_operation (self, tube_conn);
}

static void
new_local_connection_identified (TpStreamTubeChannel *self,
    GSocketConnection *conn,
    guint connection_id)
{
  TpHandle initiator_handle;
  TpStreamTubeConnection *tube_conn;
  TpConnection *connection;
  GArray *features;

  tube_conn = _tp_stream_tube_connection_new (conn, self);

  g_hash_table_insert (self->priv->tube_connections,
      GUINT_TO_POINTER (connection_id), tube_conn);

  g_object_weak_ref (G_OBJECT (tube_conn), remote_connection_destroyed_cb,
      self);

  /* We are accepting a tube so the contact of the connection is the
   * initiator of the tube */
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  initiator_handle = tp_channel_get_initiator_handle (TP_CHANNEL (self));

  connection = tp_channel_get_connection (TP_CHANNEL (self));
  features = tp_simple_client_factory_dup_contact_features (
      tp_proxy_get_factory (connection), connection);

  /* Pass ownership of tube_conn to the function */
  tp_connection_get_contacts_by_handle (connection,
      1, &initiator_handle,
      features->len, (TpContactFeature *) features->data,
      new_local_connection_with_contact,
      tube_conn, g_object_unref, G_OBJECT (self));
  G_GNUC_END_IGNORE_DEPRECATIONS

  g_array_unref (features);
}

#ifdef HAVE_GIO_UNIX
static void
send_credentials_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpStreamTubeChannel *self = user_data;
  GError *error = NULL;

  if (!tp_unix_connection_send_credentials_with_byte_finish (
          (GSocketConnection *) source, result, &error))
    {
      DEBUG ("Failed to send credentials: %s", error->message);

      operation_failed (self, error);
      g_clear_error (&error);
    }
}
#endif

static void
client_socket_connected (TpStreamTubeChannel *self)
{
  GSocketConnection *conn;

  conn = g_socket_connection_factory_create_connection (
      self->priv->client_socket);
  g_assert (conn);

  DEBUG ("Stream Tube socket connected");

#ifdef HAVE_GIO_UNIX
  if (self->priv->access_control == TP_SOCKET_ACCESS_CONTROL_CREDENTIALS)
    {
      guchar byte;

      byte = g_value_get_uchar (self->priv->access_control_param);
      tp_unix_connection_send_credentials_with_byte_async (conn, byte, NULL,
          send_credentials_cb, self);
    }
#endif

  if (self->priv->local_conn_id_set)
    {
      new_local_connection_identified (self, conn, self->priv->local_conn_id);

      self->priv->local_conn_id_set = FALSE;
    }
  else
    {
      /* Wait for NewLocalConnection signal */

      /* This assume that we never connect more than once. Or at least that we
       * wait to have identify a connection before making a new connection. */
      g_assert (self->priv->local_conn_waiting_id == NULL);
      self->priv->local_conn_waiting_id = g_object_ref (conn);
    }

  g_object_unref (conn);
}

static gboolean
client_socket_cb (GSocket *socket,
    GIOCondition condition,
    TpStreamTubeChannel *self)
{
  GError *error = NULL;

  if (!g_socket_check_connect_result (socket, &error))
    {
      DEBUG ("Failed to connect to socket: %s", error->message);

      operation_failed (self, error);
      g_error_free (error);
      return FALSE;
    }

  client_socket_connected (self);

  return FALSE;
}

static void
new_local_connection_cb (TpChannel *proxy,
    guint connection_id,
    gpointer user_data,
    GObject *weak_object)
{
  TpStreamTubeChannel *self = (TpStreamTubeChannel *) weak_object;

  if (self->priv->local_conn_waiting_id != NULL)
    {
      /* We got the ID of the connection */

      new_local_connection_identified (self, self->priv->local_conn_waiting_id,
          connection_id);

      tp_clear_object (&self->priv->local_conn_waiting_id);
      return;
    }

  /* Wait that the connection is connected */
  self->priv->local_conn_id = connection_id;
  self->priv->local_conn_id_set = TRUE;
}

static void
_channel_accepted (TpChannel *channel,
    const GValue *addressv,
    const GError *in_error,
    gpointer user_data,
    GObject *obj)
{
  TpStreamTubeChannel *self = (TpStreamTubeChannel *) obj;
  GSocketAddress *remote_address;
  GError *error = NULL;

  if (in_error != NULL)
    {
      DEBUG ("Failed to Accept Stream Tube: %s", in_error->message);

      operation_failed (self, in_error);
      return;
    }

  tp_cli_channel_type_stream_tube_connect_to_new_local_connection (
      TP_CHANNEL (self), new_local_connection_cb, NULL, NULL,
      G_OBJECT (self), &error);

  if (error != NULL)
    {
      DEBUG ("Failed to connect to NewLocalConnection signal");
      operation_failed (self, error);

      g_error_free (error);
      return;
    }

  remote_address = tp_g_socket_address_from_variant (self->priv->socket_type,
      addressv, &error);
  if (error != NULL)
    {
      DEBUG ("Failed to convert address: %s", error->message);

      operation_failed (self, error);
      g_error_free (error);
      return;
    }

  /* Connect to CM */
  g_socket_set_blocking (self->priv->client_socket, FALSE);
  g_socket_connect (self->priv->client_socket, remote_address, NULL, &error);

  if (error == NULL)
    {
      /* Socket is connected */
      client_socket_connected (self);
      goto out;
    }
  else if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_PENDING))
    {
      /* We have to wait that the socket is connected */
      GSource *source;

      source = g_socket_create_source (self->priv->client_socket,
          G_IO_OUT, NULL);

      g_source_attach (source, g_main_context_get_thread_default ());

      g_source_set_callback (source, (GSourceFunc) client_socket_cb,
          self, NULL);

      g_error_free (error);
      g_source_unref (source);
    }
  else
    {
      DEBUG ("Failed to connect to CM: %s", error->message);

      operation_failed (self, error);

      g_error_free (error);
    }

out:
  g_object_unref (remote_address);
}


/**
 * tp_stream_tube_channel_accept_async:
 * @self: an incoming #TpStreamTubeChannel
 * @callback: a callback to call when the tube has been accepted
 * @user_data: data to pass to @callback
 *
 * Accept an incoming stream tube. When the tube has been accepted, @callback
 * will be called. You can then call tp_stream_tube_channel_accept_finish()
 * to get a #TpStreamTubeConnection connected to the tube.
 *
 * Since: 0.13.2
 */
void
tp_stream_tube_channel_accept_async (TpStreamTubeChannel *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GHashTable *properties;
  GHashTable *supported_sockets;
  GError *error = NULL;

  g_return_if_fail (TP_IS_STREAM_TUBE_CHANNEL (self));
  g_return_if_fail (self->priv->result == NULL);

  if (self->priv->access_control_param != NULL)
    {
      g_simple_async_report_error_in_idle (G_OBJECT (self), callback, user_data,
          TP_ERROR, TP_ERROR_INVALID_ARGUMENT, "Tube has already be accepted");

      return;
    }

  self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_stream_tube_channel_accept_async);

  properties = _tp_channel_get_immutable_properties (TP_CHANNEL (self));
  supported_sockets = tp_asv_get_boxed (properties,
      TP_PROP_CHANNEL_TYPE_STREAM_TUBE_SUPPORTED_SOCKET_TYPES,
      TP_HASH_TYPE_SUPPORTED_SOCKET_MAP);

  if (!_tp_set_socket_address_type_and_access_control_type (supported_sockets,
      &self->priv->socket_type, &self->priv->access_control, &error))
    {
      operation_failed (self, error);

      g_clear_error (&error);
      return;
    }

  DEBUG ("Using socket type %u with access control %u", self->priv->socket_type,
      self->priv->access_control);

  self->priv->client_socket = _tp_create_client_socket (self->priv->socket_type,
      &error);

  if (error != NULL)
    {
      DEBUG ("Failed to create socket: %s", error->message);

      operation_failed (self, error);
      g_clear_error (&error);
      return;
    }

  switch (self->priv->access_control)
    {
      case TP_SOCKET_ACCESS_CONTROL_LOCALHOST:
        /* Put a dummy value */
        self->priv->access_control_param = tp_g_value_slice_new_uint (0);
        break;

      case TP_SOCKET_ACCESS_CONTROL_PORT:
        {
          GSocketAddress *addr;
          guint16 port;

          addr = g_socket_get_local_address (self->priv->client_socket, &error);
          if (addr == NULL)
            {
              DEBUG ("Failed to get local address of client socket: %s",
                  error->message);

              operation_failed (self, error);
              g_error_free (error);
              return;
            }

          port = g_inet_socket_address_get_port (G_INET_SOCKET_ADDRESS (addr));
          self->priv->access_control_param = tp_g_value_slice_new_uint (port);

          g_object_unref (addr);
        }
        break;

      case TP_SOCKET_ACCESS_CONTROL_CREDENTIALS:
        self->priv->access_control_param = tp_g_value_slice_new_byte (
            g_random_int_range (0, G_MAXUINT8));
        break;

      default:
        g_assert_not_reached ();
    }

  /* Call Accept */
  tp_cli_channel_type_stream_tube_call_accept (TP_CHANNEL (self), -1,
      self->priv->socket_type, self->priv->access_control,
      self->priv->access_control_param, _channel_accepted,
      NULL, NULL, G_OBJECT (self));
}


/**
 * tp_stream_tube_channel_accept_finish:
 * @self: a #TpStreamTubeChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes accepting an incoming stream tube. The returned
 * #TpStreamTubeConnection can then be used to exchange data through the tube.
 *
 * Returns: (transfer full): a newly created #TpStreamTubeConnection
 *
 * Since: 0.13.2
 */
TpStreamTubeConnection *
tp_stream_tube_channel_accept_finish (TpStreamTubeChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_stream_tube_channel_accept_async, g_object_ref)
}

static void
_new_remote_connection_with_contact (TpConnection *conn,
    guint n_contacts,
    TpContact * const *contacts,
    guint n_failed,
    const TpHandle *failed,
    const GError *in_error,
    gpointer user_data,
    GObject *obj)
{
  TpStreamTubeChannel *self = (TpStreamTubeChannel *) obj;
  TpContact *contact;
  TpStreamTubeConnection *tube_conn = user_data;

  if (in_error != NULL)
    {
      DEBUG ("Failed to prepare TpContact: %s", in_error->message);
      return;
    }

  if (n_failed > 0)
    {
      DEBUG ("Failed to prepare TpContact (InvalidHandle)");
      return;
    }

  contact = contacts[0];

  _tp_stream_tube_connection_set_contact (tube_conn, contact);

  DEBUG ("Accepting incoming GIOStream from %s",
      tp_contact_get_identifier (contact));

  g_signal_emit (self, _signals[INCOMING], 0, tube_conn);

  /* anyone receiving the signal is required to hold their own reference */
}

static gboolean
sig_match_conn (TpStreamTubeChannel *self,
    SigWaitingConn *sig,
    ConnWaitingSig *c)
{
  if (self->priv->access_control == TP_SOCKET_ACCESS_CONTROL_PORT)
    {
      /* Use the port to identify the connection */
      guint port;
      GSocketAddress *address;
      GError *error = NULL;

      address = g_socket_connection_get_remote_address (c->conn, &error);
      if (address == NULL)
        {
          DEBUG ("Failed to get connection address: %s", error->message);

          g_error_free (error);
          return FALSE;
        }

      dbus_g_type_struct_get (sig->param, 1, &port, G_MAXINT);

      if (port == g_inet_socket_address_get_port (
            G_INET_SOCKET_ADDRESS (address)))
        {
          DEBUG ("Identified connection %u using port %u",
              port, sig->connection_id);

          g_object_unref (address);
          return TRUE;
        }

      g_object_unref (address);
    }
  else if (self->priv->access_control == TP_SOCKET_ACCESS_CONTROL_CREDENTIALS)
    {
      guchar byte;

      byte = g_value_get_uchar (sig->param);

      return byte == c->byte;
    }
  else
    {
      DEBUG ("Can't properly identify connection as we are using "
          "access control %u. Assume it's the head of the list",
          self->priv->access_control);

      return TRUE;
    }

  return FALSE;
}

static gboolean
can_identify_contact (TpStreamTubeChannel *self)
{
  TpHandleType handle_type;

  tp_channel_get_handle (TP_CHANNEL (self), &handle_type);

  /* With contact stream tube, it's always the same contact connecting to the
   * tube */
  if (handle_type == TP_HANDLE_TYPE_CONTACT)
    return TRUE;

  /* Room stream tube, we need either the Credentials or Port access control
   * to properly identify connections. */
  if (self->priv->access_control == TP_SOCKET_ACCESS_CONTROL_CREDENTIALS ||
      self->priv->access_control == TP_SOCKET_ACCESS_CONTROL_PORT)
    return TRUE;

  return FALSE;
}

static void
connection_identified (TpStreamTubeChannel *self,
    GSocketConnection *conn,
    TpHandle handle,
    guint connection_id)
{
  TpStreamTubeConnection *tube_conn;

  tube_conn = _tp_stream_tube_connection_new (conn, self);

  g_hash_table_insert (self->priv->tube_connections,
      GUINT_TO_POINTER (connection_id), tube_conn);

  g_object_weak_ref (G_OBJECT (tube_conn), remote_connection_destroyed_cb,
      self);

  if (can_identify_contact (self))
    {
      TpConnection *connection;
      GArray *features;

      connection = tp_channel_get_connection (TP_CHANNEL (self));
      features = tp_simple_client_factory_dup_contact_features (
          tp_proxy_get_factory (connection), connection);

      /* Spec does not give the id with the handle */
      G_GNUC_BEGIN_IGNORE_DEPRECATIONS
      /* Pass the ref on tube_conn to the function */
      tp_connection_get_contacts_by_handle (connection,
          1, &handle,
          features->len, (TpContactFeature *) features->data,
          _new_remote_connection_with_contact,
          tube_conn, g_object_unref, G_OBJECT (self));
       G_GNUC_END_IGNORE_DEPRECATIONS

      g_array_unref (features);
    }
  else
    {
      g_signal_emit (self, _signals[INCOMING], 0, tube_conn);

      g_object_unref (tube_conn);
    }
}

static void
stream_tube_connection_closed_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  GError *error = NULL;

  if (!g_io_stream_close_finish (G_IO_STREAM (source), result, &error))
    {
      DEBUG ("Failed to close connection: %s", error->message);

      g_error_free (error);
      return;
    }
}

static void
connection_rejected (TpStreamTubeChannel *self,
    GSocketConnection *conn,
    TpHandle handle,
    guint connection_id)
{
  DEBUG ("Reject connection %u with contact %u", connection_id, handle);

  g_io_stream_close_async (G_IO_STREAM (conn), G_PRIORITY_DEFAULT, NULL,
      stream_tube_connection_closed_cb, self);
}

static void
_new_remote_connection (TpChannel *channel,
    guint handle,
    const GValue *param,
    guint connection_id,
    gpointer user_data,
    GObject *obj)
{
  TpStreamTubeChannel *self = (TpStreamTubeChannel *) obj;
  GSList *l;
  ConnWaitingSig *found_conn = NULL;
  SigWaitingConn *sig;
  TpHandle chan_handle;
  TpHandleType handle_type;
  gboolean rejected = FALSE;

  chan_handle = tp_channel_get_handle (channel, &handle_type);
  if (handle_type == TP_HANDLE_TYPE_CONTACT &&
      handle != chan_handle)
    {
      DEBUG ("CM claimed that handle %u connected to the stream tube, "
          "but as a contact stream tube we should only get connection from "
          "handle %u", handle, chan_handle);

      rejected = TRUE;
    }

  sig = sig_waiting_conn_new (handle, param, connection_id, rejected);

  for (l = self->priv->conn_waiting_sig; l != NULL && found_conn == NULL;
      l = g_slist_next (l))
    {
      ConnWaitingSig *conn = l->data;

      if (sig_match_conn (self, sig, conn))
        found_conn = conn;

    }

  if (found_conn == NULL)
    {
      DEBUG ("Didn't find any connection for %u. Waiting for more",
          connection_id);

      /* Pass ownership of sig to the list */
      self->priv->sig_waiting_conn = g_slist_append (
          self->priv->sig_waiting_conn, sig);
      return;
    }

  /* We found a connection */
  self->priv->conn_waiting_sig = g_slist_remove (
      self->priv->conn_waiting_sig, found_conn);

  if (rejected)
    connection_rejected (self, found_conn->conn, handle, connection_id);
  else
    connection_identified (self, found_conn->conn, handle, connection_id);

  sig_waiting_conn_free (sig);
  conn_waiting_sig_free (found_conn);
}

static void
_channel_offered (TpChannel *channel,
    const GError *in_error,
    gpointer user_data,
    GObject *obj)
{
  TpStreamTubeChannel *self = (TpStreamTubeChannel *) obj;

  if (in_error != NULL)
    {
      DEBUG ("Failed to Offer Stream Tube: %s", in_error->message);

      operation_failed (self, in_error);
      return;
    }

  DEBUG ("Stream Tube offered");

  g_simple_async_result_complete_in_idle (self->priv->result);
  tp_clear_object (&self->priv->result);
}


static void
_offer_with_address (TpStreamTubeChannel *self,
    GHashTable *params)
{
  GValue *addressv = NULL;
  GError *error = NULL;

  addressv = tp_address_variant_from_g_socket_address (self->priv->address,
      &self->priv->socket_type, &error);
  if (error != NULL)
    {
      operation_failed (self, error);

      g_clear_error (&error);
      goto finally;
    }

  /* Connect the NewRemoteConnection signal */
  tp_cli_channel_type_stream_tube_connect_to_new_remote_connection (
      TP_CHANNEL (self), _new_remote_connection,
      NULL, NULL, G_OBJECT (self), &error);
  if (error != NULL)
    {
      operation_failed (self, error);

      g_clear_error (&error);
      goto finally;
    }

  g_assert (self->priv->parameters == NULL);
  if (params != NULL)
    self->priv->parameters = g_hash_table_ref (params);
  else
    self->priv->parameters = tp_asv_new (NULL, NULL);

  g_object_notify (G_OBJECT (self), "parameters");
  g_object_notify (G_OBJECT (self), "parameters-vardict");

  /* Call Offer */
  tp_cli_channel_type_stream_tube_call_offer (TP_CHANNEL (self), -1,
      self->priv->socket_type, addressv, self->priv->access_control,
      self->priv->parameters, _channel_offered, NULL, NULL, G_OBJECT (self));

finally:
  if (addressv != NULL)
    tp_g_value_slice_free (addressv);
}

static SigWaitingConn *
find_sig_for_conn (TpStreamTubeChannel *self,
    ConnWaitingSig *c)
{
  GSList *l;

  for (l = self->priv->sig_waiting_conn; l != NULL; l = g_slist_next (l))
    {
      SigWaitingConn *sig = l->data;

      if (sig_match_conn (self, sig, c))
        return sig;
    }

  return NULL;
}

static void
credentials_received (TpStreamTubeChannel *self,
    GSocketConnection *conn,
    guchar byte)
{
  SigWaitingConn *sig;
  ConnWaitingSig *c;

  c = conn_waiting_sig_new (conn, byte);

  sig = find_sig_for_conn (self, c);
  if (sig == NULL)
    {
      DEBUG ("Can't identify the connection, wait for NewRemoteConnection sig");

      /* Pass ownership to the list */
      self->priv->conn_waiting_sig = g_slist_append (
          self->priv->conn_waiting_sig, c);

      return;
    }

  /* Connection has been identified */
  self->priv->sig_waiting_conn = g_slist_remove (self->priv->sig_waiting_conn,
      sig);

  if (sig->rejected)
    connection_rejected (self, conn, sig->handle, sig->connection_id);
  else
    connection_identified (self, conn, sig->handle, sig->connection_id);

  sig_waiting_conn_free (sig);
  conn_waiting_sig_free (c);
}

#ifdef HAVE_GIO_UNIX
static void
receive_credentials_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpStreamTubeChannel *self = user_data;
  GSocketConnection *conn = (GSocketConnection *) source;
  GCredentials *creds;
  guchar byte;
  uid_t uid;
  GError *error = NULL;

  creds = tp_unix_connection_receive_credentials_with_byte_finish (conn, result,
      &byte, &error);

  if (creds == NULL)
    {
      DEBUG ("Failed to receive credentials: %s", error->message);
      g_error_free (error);
      return;
    }

  uid = g_credentials_get_unix_user (creds, &error);
  if (uid != geteuid ())
    {
      DEBUG ("Wrong credentials received (user: %u)", uid);
      return;
    }

  credentials_received (self, conn, byte);

  g_object_unref (creds);
}
#endif

static void
service_incoming_cb (GSocketService *service,
    GSocketConnection *conn,
    GObject *source_object,
    gpointer user_data)
{
  TpStreamTubeChannel *self = user_data;

  DEBUG ("New incoming connection");

#ifdef HAVE_GIO_UNIX
  /* Check the credentials if needed */
  if (self->priv->access_control == TP_SOCKET_ACCESS_CONTROL_CREDENTIALS)
    {
      tp_unix_connection_receive_credentials_with_byte_async (conn, NULL,
          receive_credentials_cb, self);
      return;
    }
#endif

  credentials_received (self, conn, 0);
}

/**
 * tp_stream_tube_channel_offer_async:
 * @self: an outgoing #TpStreamTubeChannel
 * @params: (allow-none) (transfer none): parameters of the tube, or %NULL
 * @callback: a callback to call when the tube has been offered
 * @user_data: data to pass to @callback
 *
 * Offer an outgoing stream tube. When the tube has been offered, @callback
 * will be called. You can then call tp_stream_tube_channel_offer_finish()
 * to get the result of the operation.
 *
 * You have to connect to the #TpStreamTubeChannel::incoming signal to get a
 * #TpStreamTubeConnection each time a contact establishes a connection to
 * the tube.
 *
 * Since: 0.13.2
 */
void
tp_stream_tube_channel_offer_async (TpStreamTubeChannel *self,
    GHashTable *params,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GHashTable *properties;
  GHashTable *supported_sockets;
  GError *error = NULL;

  g_return_if_fail (TP_IS_STREAM_TUBE_CHANNEL (self));
  g_return_if_fail (self->priv->result == NULL);
  g_return_if_fail (tp_channel_get_requested (TP_CHANNEL (self)));

  if (self->priv->service != NULL)
    {
      g_critical ("Can't reoffer Tube!");
      return;
    }

  self->priv->result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_stream_tube_channel_offer_async);

  properties = _tp_channel_get_immutable_properties (TP_CHANNEL (self));
  supported_sockets = tp_asv_get_boxed (properties,
      TP_PROP_CHANNEL_TYPE_STREAM_TUBE_SUPPORTED_SOCKET_TYPES,
      TP_HASH_TYPE_SUPPORTED_SOCKET_MAP);

  if (!_tp_set_socket_address_type_and_access_control_type (supported_sockets,
      &self->priv->socket_type, &self->priv->access_control, &error))
    {
      operation_failed (self, error);

      g_clear_error (&error);
      return;
    }

  DEBUG ("Using socket type %u with access control %u", self->priv->socket_type,
      self->priv->access_control);

  self->priv->service = g_socket_service_new ();

  switch (self->priv->socket_type)
    {
#ifdef HAVE_GIO_UNIX
      case TP_SOCKET_ADDRESS_TYPE_UNIX:
        {
          self->priv->address = _tp_create_temp_unix_socket (
              self->priv->service, &self->priv->unix_tmpdir, &error);

          /* check there wasn't an error on the final attempt */
          if (self->priv->address == NULL)
            {
              operation_failed (self, error);

              g_clear_error (&error);
              return;
            }
        }

        break;
#endif /* HAVE_GIO_UNIX */

      case TP_SOCKET_ADDRESS_TYPE_IPV4:
      case TP_SOCKET_ADDRESS_TYPE_IPV6:
        {
          GInetAddress *localhost;
          GSocketAddress *in_address;

          localhost = g_inet_address_new_loopback (
              self->priv->socket_type == TP_SOCKET_ADDRESS_TYPE_IPV4 ?
              G_SOCKET_FAMILY_IPV4 : G_SOCKET_FAMILY_IPV6);
          in_address = g_inet_socket_address_new (localhost, 0);

          g_socket_listener_add_address (
              G_SOCKET_LISTENER (self->priv->service), in_address,
              G_SOCKET_TYPE_STREAM, G_SOCKET_PROTOCOL_DEFAULT,
              NULL, &self->priv->address, &error);

          g_object_unref (localhost);
          g_object_unref (in_address);

          if (error != NULL)
            {
              operation_failed (self, error);

              g_clear_error (&error);
              return;
            }

          break;
        }

      default:
        /* should have already errored */
        g_assert_not_reached ();
        break;
    }

  tp_g_signal_connect_object (self->priv->service, "incoming",
      G_CALLBACK (service_incoming_cb), self, 0);

  g_socket_service_start (self->priv->service);

  _offer_with_address (self, params);
}

/**
 * tp_stream_tube_channel_offer_finish:
 * @self: a #TpStreamTubeChannel
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes offering an outgoing stream tube.
 *
 * Returns: %TRUE when a Tube has been successfully offered; %FALSE otherwise
 *
 * Since: 0.13.2
 */
gboolean
tp_stream_tube_channel_offer_finish (TpStreamTubeChannel *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_stream_tube_channel_offer_async)
}

/**
 * tp_stream_tube_channel_get_service:
 * @self: a #TpStreamTubeChannel
 *
 * Return the #TpStreamTubeChannel:service property
 *
 * Returns: (transfer none): the value of #TpStreamTubeChannel:service
 *
 * Since: 0.13.2
 */
const gchar *
tp_stream_tube_channel_get_service (TpStreamTubeChannel *self)
{
  GHashTable *props;

  props = _tp_channel_get_immutable_properties (TP_CHANNEL (self));

  return tp_asv_get_string (props, TP_PROP_CHANNEL_TYPE_STREAM_TUBE_SERVICE);
}

/**
 * tp_stream_tube_channel_get_parameters: (skip)
 * @self: a #TpStreamTubeChannel
 *
 * Return the #TpStreamTubeChannel:parameters property
 *
 * Returns: (transfer none) (element-type utf8 GObject.Value):
 * the value of #TpStreamTubeChannel:parameters
 *
 * Since: 0.13.2
 */
GHashTable *
tp_stream_tube_channel_get_parameters (TpStreamTubeChannel *self)
{
  return self->priv->parameters;
}

/**
 * tp_stream_tube_channel_dup_parameters_vardict:
 * @self: a #TpStreamTubeChannel
 *
 * Return the parameters of the dbus-tube channel in a variant of
 * type %G_VARIANT_TYPE_VARDICT whose keys are strings representing
 * parameter names and values are variants representing corresponding
 * parameter values set by the offerer when offering this channel.
 *
 * The GVariant returned is %NULL if this is an outgoing tube that has not
 * yet been offered or the parameters property has not been set.
 *
 * Use g_variant_lookup(), g_variant_lookup_value(), or tp_vardict_get_uint32()
 * and similar functions for convenient access to the values.
 *
 * Returns: (transfer full): a new reference to a #GVariant
 *
 * Since: 0.19.10
 */
GVariant *
tp_stream_tube_channel_dup_parameters_vardict (TpStreamTubeChannel *self)
{
  g_return_val_if_fail (TP_IS_STREAM_TUBE_CHANNEL (self), NULL);

  if (self->priv->parameters == NULL)
      return NULL;

  return _tp_asv_to_vardict (self->priv->parameters);
}
