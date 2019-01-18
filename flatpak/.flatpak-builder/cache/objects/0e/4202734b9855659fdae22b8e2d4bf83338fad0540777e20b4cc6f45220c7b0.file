/*
 * Copyright (C) 2011 Canonical, Ltd.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License
 * version 3.0 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see
 * <http://www.gnu.org/licenses/>.
 *
 * Authored by: Michal Hruby <michal.hruby@canonical.com>
 *
 */
/**
 * SECTION:dee-client
 * @short_description: Creates a client object you can use to connect
 *                     to a #DeeServer.
 * @include: dee.h
 *
 * #DeeClient is the endpoint for connecting to #DeeServer.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <gio/gio.h>

#include "dee-client.h"
#include "dee-server.h"
#include "dee-marshal.h"
#include "trace-log.h"

G_DEFINE_TYPE (DeeClient, dee_client, DEE_TYPE_PEER)

#define GET_PRIVATE(o) \
      (G_TYPE_INSTANCE_GET_PRIVATE ((o), DEE_TYPE_CLIENT, DeeClientPrivate))

/**
 * DeeClientPrivate:
 *
 * Ignore this structure.
 **/
struct _DeeClientPrivate
{
  GDBusConnection *connection;
  GCancellable    *cancellable;
  gchar           *bus_address;

  guint            peer_found_timer_id;
  gulong           closed_signal_handler_id;
};

/* Globals */
enum
{
  PROP_0,
  PROP_BUS_ADDRESS
};

enum
{
  LAST_SIGNAL
};

//static guint32 _server_signals[LAST_SIGNAL] = { 0 };

/* Forwards */
static gboolean     dee_client_is_swarm_leader     (DeePeer *peer);

static const gchar* dee_client_get_swarm_leader    (DeePeer *peer);

static GSList*      dee_client_get_connections     (DeePeer *peer);

static gchar**      dee_client_list_peers          (DeePeer *peer);

static void         connecting_finished            (GObject *object,
                                                    GAsyncResult *res,
                                                    gpointer user_data);

static void         connection_closed              (GDBusConnection *connection,
                                                    gboolean         remote_peer_vanished,
                                                    GError          *error,
                                                    DeeClient       *client);

/* GObject methods */
static void
dee_client_get_property (GObject *object, guint property_id,
                         GValue *value, GParamSpec *pspec)
{
  DeeClientPrivate *priv;

  priv = DEE_CLIENT (object)->priv;

  switch (property_id)
    {
      case PROP_BUS_ADDRESS:
        g_value_set_string (value, priv->bus_address);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}

static void
dee_client_set_property (GObject *object, guint property_id,
                              const GValue *value, GParamSpec *pspec)
{
  DeeClientPrivate *priv;

  priv = DEE_CLIENT (object)->priv;

  switch (property_id)
    {
      case PROP_BUS_ADDRESS:
        if (priv->bus_address) g_free (priv->bus_address);
        priv->bus_address = g_value_dup_string (value);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}

static void
dee_client_constructed (GObject *self)
{
  DeeClientPrivate *priv;
  const gchar      *swarm_name;
  GDBusConnectionFlags flags;

  priv = DEE_CLIENT (self)->priv;

  /* we should chain up the constructed method here, but peer does things we
   * don't want to, so not chaining up... */

  swarm_name = dee_peer_get_swarm_name (DEE_PEER (self));
  if (swarm_name == NULL)
    {
      g_critical ("DeeClient created without a swarm name. You must specify "
                  "a non-NULL swarm name");
      return;
    }

  if (!priv->bus_address)
    {
      priv->bus_address = dee_server_bus_address_for_name (swarm_name, TRUE);
    }

  flags = G_DBUS_CONNECTION_FLAGS_AUTHENTICATION_CLIENT;
  priv->cancellable = g_cancellable_new ();
  g_dbus_connection_new_for_address (priv->bus_address,
                                     flags,
                                     NULL, // AuthObserver
                                     priv->cancellable,
                                     connecting_finished,
                                     self);
}

static void
dee_client_finalize (GObject *object)
{
  DeeClientPrivate *priv;

  priv = DEE_CLIENT (object)->priv;

  if (priv->cancellable)
    {
      g_cancellable_cancel (priv->cancellable);
      g_object_unref (priv->cancellable);
    }

  if (priv->closed_signal_handler_id)
    {
      g_signal_handler_disconnect (priv->connection,
                                   priv->closed_signal_handler_id);
      priv->closed_signal_handler_id = 0;
    }

  if (priv->connection)
    {
      g_object_unref (priv->connection);
    }

  if (priv->peer_found_timer_id)
    {
      g_source_remove (priv->peer_found_timer_id);
      priv->peer_found_timer_id = 0;
    }

  if (priv->bus_address)
    {
      g_free (priv->bus_address);
    }

  G_OBJECT_CLASS (dee_client_parent_class)->finalize (object);
}

static void
dee_client_class_init (DeeClientClass *klass)
{
  GParamSpec   *pspec;
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  DeePeerClass *peer_class = DEE_PEER_CLASS (klass);

  g_type_class_add_private (klass, sizeof (DeeClientPrivate));

  object_class->constructed    = dee_client_constructed;
  object_class->get_property   = dee_client_get_property;
  object_class->set_property   = dee_client_set_property;
  object_class->finalize       = dee_client_finalize;

  peer_class->is_swarm_leader  = dee_client_is_swarm_leader;
  peer_class->get_swarm_leader = dee_client_get_swarm_leader;
  peer_class->get_connections  = dee_client_get_connections;
  peer_class->list_peers       = dee_client_list_peers;

  /**
   * DeeClient::bus-address:
   *
   * D-Bus address the client will connect to. If you do not specify this
   * property #DeeClient will use dee_server_bus_address_for_name() using
   * current swarm name to determine the value of this property.
   */
  pspec = g_param_spec_string ("bus-address", "Bus address",
                               "Bus address to use for the connection",
                               NULL,
                               G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                               | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_BUS_ADDRESS, pspec);
}

static void
dee_client_init (DeeClient *self)
{
  self->priv = GET_PRIVATE (self);
}

/**
 * dee_client_new:
 * @swarm_name: Name of swarm to join.
 *
 * Creates a new instance of #DeeClient and tries to connect to #DeeServer
 * created using dee_server_new(). The #DeePeer:swarm-leader property will
 * be set once the client connects.
 *
 * Return value: (transfer full): A newly constructed #DeeClient.
 */
DeeClient*
dee_client_new (const gchar* swarm_name)
{
  g_return_val_if_fail (swarm_name != NULL, NULL);

  return DEE_CLIENT (g_object_new (DEE_TYPE_CLIENT,
                                   "swarm-name", swarm_name, NULL));
}

/**
 * dee_client_new_for_address:
 * @swarm_name: Name of swarm to join.
 * @bus_address: D-Bus address to use when connecting to the server.
 *
 * Creates a new instance of #DeeClient and tries to connect to @bus_address.
 * The #DeePeer:swarm-leader property will be set once the client connects.
 *
 * Return value: (transfer full): A newly constructed #DeeClient.
 */
DeeClient*
dee_client_new_for_address (const gchar* swarm_name,
                            const gchar* bus_address)
{
  g_return_val_if_fail (swarm_name != NULL, NULL);

  return DEE_CLIENT (g_object_new (DEE_TYPE_CLIENT, 
                                   "swarm-name", swarm_name,
                                   "bus-address", bus_address, NULL));
}

/* Private Methods */

static gboolean
dee_client_is_swarm_leader (DeePeer *peer)
{
  return FALSE;
}

static const gchar*
dee_client_get_swarm_leader (DeePeer *peer)
{
  DeeClientPrivate *priv;

  priv = DEE_CLIENT (peer)->priv;
  return priv->connection ? g_dbus_connection_get_guid (priv->connection) : NULL;
}

static GSList*
dee_client_get_connections (DeePeer *peer)
{
  DeeClientPrivate *priv;
  GSList *list = NULL;

  priv = DEE_CLIENT (peer)->priv;

  if (priv->connection)
    {
      list = g_slist_append (list, priv->connection);
    }

  return list;
}

static gchar**
dee_client_list_peers (DeePeer *peer)
{
  DeeClientPrivate *priv;
  gchar **result;
  int i = 0;

  priv = DEE_CLIENT (peer)->priv;

  result = g_new (gchar*, priv->connection ? 2 : 1);

  if (priv->connection)
    {
      result[i++] = g_strdup (g_dbus_connection_get_guid (priv->connection));
    }
  result[i] = NULL;

  return result;
}

static gboolean
emit_peer_found (gpointer user_data)
{
  g_return_val_if_fail (DEE_IS_CLIENT (user_data), FALSE);

  DeeClientPrivate *priv = DEE_CLIENT (user_data)->priv;

  g_signal_emit_by_name (user_data, "peer-found",
                         g_dbus_connection_get_guid (priv->connection));

  priv->peer_found_timer_id = 0;

  return FALSE;
}

static void
connecting_finished (GObject *object, GAsyncResult *res, gpointer user_data)
{
  GDBusConnection  *connection;
  DeeClient        *self;
  DeeClientPrivate *priv;
  GError           *error = NULL;

  connection = g_dbus_connection_new_for_address_finish (res, &error);

  if (error)
    {
      if (!g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
        {
          g_warning ("Unable to connect to server: %s", error->message);
          // swarm-leader will be set to NULL for unsuccessful connections
          g_object_notify (G_OBJECT (user_data), "swarm-leader");
        }
      /* Don't touch the object in case we were cancelled, it's most likely
       * unreffed by now */

      g_error_free (error);
      return;
    }

  self = DEE_CLIENT (user_data);
  priv = self->priv;
  priv->connection = connection;

  g_object_unref (priv->cancellable);
  priv->cancellable = NULL;

  priv->closed_signal_handler_id = g_signal_connect (connection, "closed",
      G_CALLBACK (connection_closed), self);

  g_object_notify (G_OBJECT (user_data), "swarm-leader");

  g_signal_emit_by_name (user_data, "connection-acquired", connection);

  // FIXME: we might want to call some List method (same as DeePeer), so far
  // we'll just simulate an async method (tests expect this anyway)
  priv->peer_found_timer_id = g_idle_add_full (G_PRIORITY_DEFAULT,
                                               emit_peer_found, user_data,
                                               NULL);
}

static void
connection_closed (GDBusConnection *connection, gboolean remote_peer_vanished,
                   GError *error, DeeClient *client)
{
  DeeClientPrivate *priv;

  g_return_if_fail (DEE_IS_CLIENT (client));

  priv = client->priv;
  priv->connection = NULL;

  g_signal_handler_disconnect (connection, priv->closed_signal_handler_id);
  priv->closed_signal_handler_id = 0;

  trace_object (client, "Connection [%p] closed", connection);
  
  /* Let's do reverse order of connecting_finished */
  g_signal_emit_by_name (client, "peer-lost",
                         g_dbus_connection_get_guid (connection));
  g_signal_emit_by_name (client, "connection-closed", connection);

  g_object_notify (G_OBJECT (client), "swarm-leader");

  g_object_unref (connection);
}

