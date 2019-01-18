/*
 * Copyright (C) 2010 Canonical, Ltd.
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
 * Authors:
 *      Neil Jagdish Patel <neil.patel@canonical.com>
 *      Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 *
 */
/**
 * SECTION:dee-peer
 * @short_description: Finds other objects with the same swarm-name on the bus.
 * @include: dee.h
 *
 * #DeePeer allows you to build objects that can rendevouz on DBus
 * without the need for an central registration service. Think of it like
 * peer-to-peer for your application. The DBus session bus will also implicitly
 * elect a swarm leader - namely the one owning the swarm name on the bus, but
 * it's up to the consumer of this API to determine whether swarm leadership has
 * any concrete responsibilities associated.
 *
 * Peers find eachother through a well-known "swarm-name", which is a
 * well known DBus name, such as: org.myapp.MyPeers. Choose a namespaced
 * name that would not normally be used outside of your program.
 *
 * For example:
 * <informalexample><programlisting>
 * {
 *   DeePeer *peer;
 *
 *   peer = g_object_new (DBUS_TYPE_PEER,
 *                        "swarm-name", "org.myapp.MyPeers",
 *                        NULL);
 *
 *   g_signal_connect (peer, "peer-found",
 *                     G_CALLBACK (on_peer_found), NULL);
 *   g_signal_connect (peer, "peer-lost",
 *                     G_CALLBACK (on_peer_lost), NULL);
 * }
 * </programlisting></informalexample>
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <gio/gio.h>

#include "dee-peer.h"
#include "dee-marshal.h"
#include "trace-log.h"

G_DEFINE_TYPE (DeePeer, dee_peer, G_TYPE_OBJECT)

#define DEE_PEER_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_PEER, DeePeerPrivate))

#define _DeePeerIter GSequenceIter

/**
 * DeePeerPrivate:
 *
 * Ignore this structure.
 **/
struct _DeePeerPrivate
{
  GDBusConnection *connection;

  /* Used as a hash set with the unique addresses of the peers.
   * This hash table must be protected from concurrent access,
   * since it's used in the GDBus message dispatch thread */
  GHashTable *peers;
  
  /* A List with the string-formatted match rules we've installed */
  GSList *match_rules;
  
  /* The GDBus filter id, so we can uninstall our message filter again */
  guint   filter_id;

  /* GDBus id for the DBus signal subscriptions */
  guint   dbus_signals_id;

  /* The GDBus name owner id for g_bus_own_name() */
  guint   name_owner_id;

  /* The GDBus name watcher id from g_bus_watch_name() */
  guint name_watcher_id;

  /* Swarm related properties */
  gboolean     swarm_owner;
  const gchar *own_name;
  gchar       *swarm_name;
  gchar       *swarm_path;
  gchar       *swarm_leader;

  gboolean connected;
  gboolean is_swarm_leader;
  gboolean has_been_leader;
  gboolean is_first_name_check;

  GCancellable *list_cancellable;

  /* if priv->head_count != NULL it indicates that we are in
   * "head counting mode" in which case priv->head_count_source will be a
   * GSource id for a timeout that completes the head count */
  GSList *head_count;
  guint   head_count_source;

  /* Protecting the priv->peers table from concurrent access in
   * the GDBus message dispatch thread */
#if GLIB_CHECK_VERSION(2, 31, 16)
  GMutex lock_real;
#endif
  GMutex *lock;
};

/* Globals */
enum
{
  PROP_0,
  PROP_SWARM_NAME,
  PROP_SWARM_LEADER,
  PROP_SWARM_OWNER
};

enum
{
  PEER_FOUND,
  PEER_LOST,
  CONNECTION_ACQUIRED,
  CONNECTION_CLOSED,

  LAST_SIGNAL
};

static guint32 _peer_signals[LAST_SIGNAL] = { 0 };

/* Forwards */
static void                 remove_match_rule        (GDBusConnection *conn,
                                                      const gchar     *rule);

static void                 emit_peer_found          (DeePeer    *self,
                                                      const gchar *name);
                                                      
static void                 on_bus_acquired          (GDBusConnection *connection,
                                                      const gchar     *name,
                                                      gpointer         user_data);

static void                 on_leadership_lost       (GDBusConnection *connection,
                                                      const gchar     *name,
                                                      gpointer         user_data);

static void                 on_leadership_acquired   (GDBusConnection *connection,
                                                      const gchar     *name,
                                                      gpointer         user_data);

static void                 on_leadership_changed    (GDBusConnection *connection,
                                                      const gchar     *name,
                                                      const gchar     *name_owner,
                                                      gpointer         user_data);

static void                 on_join_received         (DeePeer    *self,
                                                      const gchar *peer_address);

static void                 on_bye_received          (DeePeer    *self,
                                                      const gchar *peer_address);

static void                 on_ping_received         (DeePeer    *self,
                                                      const gchar *leader_address);

static void                 on_pong_received         (DeePeer    *self,
                                                      const gchar *peer_address);

static void                 on_list_received         (GObject      *source_object,
                                                      GAsyncResult *res,
                                                      gpointer      user_data);

static void                 set_swarm_name           (DeePeer    *self,
                                                      const gchar *swarm_name);

static void                 emit_ping                (DeePeer    *self);

static void                 emit_pong                (DeePeer    *self);

static void                 on_dbus_peer_signal      (GDBusConnection *connection,
                                                      const gchar     *sender_name,
                                                      const gchar     *object_path,
                                                      const gchar     *interface_name,
                                                      const gchar     *signal_name,
                                                      GVariant        *parameters,
                                                      gpointer         user_data);

static GDBusMessage*        gdbus_message_filter    (GDBusConnection *connection,
                                                     GDBusMessage    *message,
                                                     gboolean         incoming,
                                                     gpointer         user_data);

static const gchar*  dee_peer_real_get_swarm_leader (DeePeer *self);

static gboolean      dee_peer_real_is_swarm_leader  (DeePeer *self);

static GSList*       dee_peer_real_get_connections  (DeePeer *self);

static gchar**       dee_peer_real_list_peers       (DeePeer *self);

/* GObject methods */
static void
dee_peer_dispose (GObject *object)
{
  DeePeerPrivate *priv;
  GSList *match_iter;

  priv = DEE_PEER (object)->priv;

  /* Remove match rules from the bus, and free the string repr. of the rule  */
  if (priv->connection)
    {
      /* Uninstall filter.
       * Implementation note: We must remove the filter and signal listener
       * _before_ dropping the swarm name because gdbus currently does a
       * sync dbus call to release the name which makes us race against
       * getting a NameOwnerChanged */
      /* The removal of the filter rules also has to be done in dispose,
       * not finalize, cause the filter callback can ref this object and
       * therefore postpone finalization, although that shouldn't happen,
       * as this uses locking and the call will not return until all current
       * invocations of the filter callback finish. */
      g_dbus_connection_remove_filter (priv->connection, priv->filter_id);
      
      for (match_iter = priv->match_rules;
           match_iter != NULL;
           match_iter = match_iter->next)
        {
          remove_match_rule (priv->connection, match_iter->data);
          g_free (match_iter->data);
        }

      /* Stop listening for signals */
      if (priv->dbus_signals_id != 0)
        {
          g_dbus_connection_signal_unsubscribe (priv->connection,
                                                priv->dbus_signals_id);
          priv->dbus_signals_id = 0;
        }

      g_object_unref (priv->connection);
      priv->connection = NULL;
    }
  
  if (priv->match_rules)
    {
      g_slist_free (priv->match_rules);
      priv->match_rules = NULL;
    }

  /* Stop trying to own the swarm name.
   * See implementation note above */
  if (priv->name_owner_id != 0)
    {
      g_bus_unown_name (priv->name_owner_id);
      priv->name_owner_id = 0;
    }

  /* Stop listening for swarm leadership changes */
  if (priv->name_watcher_id != 0)
    {
      g_bus_unwatch_name (priv->name_watcher_id);
      priv->name_watcher_id = 0;
    }

  G_OBJECT_CLASS (dee_peer_parent_class)->dispose (object);
}

static void
dee_peer_finalize (GObject *object)
{
  DeePeerPrivate *priv;

  priv = DEE_PEER (object)->priv;

  if (priv->list_cancellable != NULL)
    {
      g_cancellable_cancel (priv->list_cancellable);
      g_object_unref (priv->list_cancellable);
      priv->list_cancellable = NULL;
    }

  /* Free resources */
  if (priv->swarm_name)
    {
      g_free (priv->swarm_name);
      priv->swarm_name = NULL;
    }
  if (priv->swarm_path)
    {
      g_free (priv->swarm_path);
      priv->swarm_path = NULL;
    }
  if (priv->swarm_leader)
    {
      g_free (priv->swarm_leader);
      priv->swarm_leader = NULL;
    }
  if (priv->peers)
    {
      g_hash_table_destroy (priv->peers);
      priv->peers = NULL;
    }
  if (priv->lock != NULL)
    {
#if GLIB_CHECK_VERSION(2, 31, 16)
      g_mutex_clear (priv->lock);
#else
      g_mutex_free (priv->lock);
#endif
      priv->lock = NULL;
    }
  if (priv->head_count != NULL)
    {
      g_slist_foreach(priv->head_count, (GFunc) g_free, NULL);
      g_slist_free (priv->head_count);
      priv->head_count = NULL;
    }
  if (priv->head_count_source != 0)
    {
      g_source_remove (priv->head_count_source);
      priv->head_count_source = 0;
    }
  
  G_OBJECT_CLASS (dee_peer_parent_class)->finalize (object);
}

static void
dee_peer_constructed (GObject *self)
{
  DeePeerPrivate    *priv;
  GBusNameOwnerFlags flags;

  priv = DEE_PEER (self)->priv;
  
  if (priv->swarm_name == NULL)
    {
      g_critical ("DeePeer created without a swarm name. You must specify "
                  "a non-NULL swarm name");
      return;
    }
  
  /* Contend to be swarm leaders. Pick me! Pick me! */
  flags = priv->swarm_owner ?
    G_BUS_NAME_OWNER_FLAGS_REPLACE : G_BUS_NAME_OWNER_FLAGS_ALLOW_REPLACEMENT;

  priv->name_owner_id = g_bus_own_name (G_BUS_TYPE_SESSION,
                                        priv->swarm_name,      /* name to own */
                                        flags,
                                        on_bus_acquired,
                                        on_leadership_acquired,
                                        on_leadership_lost,
                                        self,                    /* user data */
                                        NULL);                   /* free func */

  /* Listen for changes in leadership */
  priv->name_watcher_id = g_bus_watch_name(G_BUS_TYPE_SESSION,
                                           priv->swarm_name,
                                           G_BUS_NAME_WATCHER_FLAGS_NONE,
                                           on_leadership_changed,
                                           NULL, /* name vanished cb */
                                           self, /* user data */
                                           NULL); /* user data free func */
}


static void
dee_peer_set_property (GObject       *object,
                       guint          id,
                       const GValue  *value,
                       GParamSpec    *pspec)
{
  DeePeerPrivate *priv = DEE_PEER (object)->priv;
  
  
  switch (id)
    {
    case PROP_SWARM_NAME:
      set_swarm_name (DEE_PEER (object), g_value_get_string (value));
      break;
    case PROP_SWARM_LEADER:
      g_free (priv->swarm_leader);
      priv->swarm_leader = g_value_dup_string (value);
      break;
    case PROP_SWARM_OWNER:
      priv->swarm_owner = g_value_get_boolean (value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_peer_get_property (GObject     *object,
                        guint        id,
                        GValue      *value,
                        GParamSpec  *pspec)
{
  switch (id)
    {
    case PROP_SWARM_NAME:
      g_value_set_string (value, DEE_PEER (object)->priv->swarm_name);
      break;
    case PROP_SWARM_LEADER:
      g_value_set_string (value, dee_peer_get_swarm_leader (DEE_PEER (object)));
      break;
    case PROP_SWARM_OWNER:
      g_value_set_boolean (value, DEE_PEER (object)->priv->swarm_owner);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_peer_class_init (DeePeerClass *klass)
{
  GObjectClass *obj_class = G_OBJECT_CLASS (klass);
  GParamSpec   *pspec;

  obj_class->dispose      = dee_peer_dispose;
  obj_class->finalize     = dee_peer_finalize;
  obj_class->set_property = dee_peer_set_property;
  obj_class->get_property = dee_peer_get_property;
  obj_class->constructed  = dee_peer_constructed;

  /* Virtual methods */
  klass->get_swarm_leader = dee_peer_real_get_swarm_leader;
  klass->is_swarm_leader  = dee_peer_real_is_swarm_leader;
  klass->get_connections  = dee_peer_real_get_connections;
  klass->list_peers       = dee_peer_real_list_peers;

  /* Add Signals */

  /**
   * DeePeer::peer-found:
   * @self: the #DeePeer on which the signal is emitted
   * @name: the DBus name of the object found
   *
   * Connect to this signal to be notified of existing and new peers that are
   *   in your swarm.
   **/
  _peer_signals[PEER_FOUND] =
    g_signal_new ("peer-found",
                  G_TYPE_FROM_CLASS (klass),
                  G_SIGNAL_RUN_LAST,
                  G_STRUCT_OFFSET (DeePeerClass, peer_found),
                  NULL, NULL,
                  g_cclosure_marshal_VOID__STRING,
                  G_TYPE_NONE, 1,
                  G_TYPE_STRING);

  /**
   * DeePeer::peer-lost:
   * @self: the #DeePeer on which the signal is emitted
   * @name: the DBus name of the object that disconnected
   *
   * Connect to this signal to be notified when peers disconnect from the swarm
   **/
  _peer_signals[PEER_LOST] =
    g_signal_new ("peer-lost",
                  G_TYPE_FROM_CLASS (klass),
                  G_SIGNAL_RUN_LAST,
                  G_STRUCT_OFFSET (DeePeerClass, peer_lost),
                  NULL, NULL,
                  g_cclosure_marshal_VOID__STRING,
                  G_TYPE_NONE, 1,
                  G_TYPE_STRING);
  
  /**
   * DeePeer::new-connection:
   * @self: the #DeePeer on which the signal is emitted
   * @connection: the new #GDBusConnection
   *
   * Connect to this signal to be notified when peers connect via 
   * new #GDBusConnection.
   **/
  _peer_signals[CONNECTION_ACQUIRED] =
    g_signal_new ("connection-acquired",
                  G_TYPE_FROM_CLASS (klass),
                  G_SIGNAL_RUN_LAST,
                  G_STRUCT_OFFSET (DeePeerClass, connection_acquired),
                  NULL, NULL,
                  g_cclosure_marshal_VOID__OBJECT,
                  G_TYPE_NONE, 1,
                  G_TYPE_DBUS_CONNECTION);
  
  /**
   * DeePeer::connection-closed:
   * @self: the #DeePeer on which the signal is emitted
   * @connection: the closed #GDBusConnection
   *
   * Connect to this signal to be notified when peers close
   * their #GDBusConnection.
   **/
  _peer_signals[CONNECTION_CLOSED] =
    g_signal_new ("connection-closed",
                  G_TYPE_FROM_CLASS (klass),
                  G_SIGNAL_RUN_LAST,
                  G_STRUCT_OFFSET (DeePeerClass, connection_closed),
                  NULL, NULL,
                  g_cclosure_marshal_VOID__OBJECT,
                  G_TYPE_NONE, 1,
                  G_TYPE_DBUS_CONNECTION);

  /* Add properties */
  /**
   * DeePeer::swarm-name:
   *
   * The name of the swarm that this peer is connected to. All swarm members
   * will try and own this name on the session bus. The one owning the name
   * is the swarm leader.
   */
  pspec = g_param_spec_string ("swarm-name", "Swarm Name",
                               "Well-known name to find other peers with",
                               NULL,
                               G_PARAM_READWRITE | G_PARAM_CONSTRUCT
                               | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_SWARM_NAME, pspec);

  /**
   * DeePeer::swarm-leader:
   *
   * The name of the swarm that this peer is connected to. All swarm members
   * will try and own this name on the session bus. The one owning the name
   * is the swarm leader.
   **/
  pspec = g_param_spec_string ("swarm-leader", "Swarm Leader",
                               "Unique DBus address of the swarm leader",
                               NULL,
                               G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_SWARM_LEADER, pspec);

  /**
   * DeePeer::swarm-owner:
   *
   * If set, this peer will try to become a leader of the swarm.
   *
   * Creating a #DeeSharedModel with a peer that successfully assumes ownership
   * of a swarm will skip cloning of the model, therefore you need to set
   * the schema and fill the model with data yourself.
   *
   * Setting this property to TRUE does NOT guarantee that this peer will
   * become a leader. You should always check the :swarm-leader property.
   **/
  pspec = g_param_spec_boolean ("swarm-owner", "Swarm Owner",
                                "Try to assume leadership of the swarm",
                                FALSE,
                                G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                                | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_SWARM_OWNER, pspec);

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeePeerPrivate));
}

static void
dee_peer_init (DeePeer *peer)
{
  DeePeerPrivate *priv;

  priv = peer->priv = DEE_PEER_GET_PRIVATE (peer);

  priv->swarm_name = NULL;
  priv->swarm_leader = NULL;
  priv->own_name = NULL;
  priv->match_rules = NULL;
  priv->peers = g_hash_table_new_full (g_str_hash,
                                       g_str_equal,
                                       (GDestroyNotify) g_free,
                                       NULL);
  
  priv->connected = FALSE;
  priv->is_swarm_leader = FALSE;
  priv->has_been_leader = FALSE;
  priv->is_first_name_check = TRUE;

  priv->list_cancellable = NULL;

#if GLIB_CHECK_VERSION(2, 31, 16)
  g_mutex_init (&priv->lock_real);
  priv->lock = &priv->lock_real;
#else
  priv->lock = g_mutex_new ();
#endif

  priv->head_count_source = 0;
}

/* Private Methods */


/* Async callback for com.canonical.Dee.Peer.List */
static void
on_list_received (GObject      *source_object,
                  GAsyncResult *res,
                  gpointer      user_data)
{
  DeePeer        *self;
  DeePeerPrivate *priv;
  GHashTable     *peers, *old_peers_ht;
  GSList         *new_peers, *iter;
  guint           i;
  GVariant       *val, *_val;
  const gchar    **names;
  gsize           n_names;
  GError         *error;
  GHashTableIter  hiter;
  gpointer        hkey, hval;

  error = NULL;
  _val = g_dbus_connection_call_finish (G_DBUS_CONNECTION (source_object),
                                        res, &error);
  if (error != NULL)
    {
      if (!g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
        {
          g_warning ("%s: Unable to list peers: %s", G_STRLOC, error->message);
        }
      g_error_free (error);
      return;
    }

  g_return_if_fail (DEE_IS_PEER (user_data));
  self = DEE_PEER (user_data);
  priv = self->priv;

  /* Unpack the wrapping struct from the reply */
  val = g_variant_get_child_value (_val, 0);
  g_variant_unref (_val);

  names = g_variant_get_strv (val, &n_names);
  trace_object (self, "Got list of %d peers", n_names);
  
  /* We diff the current list of peers against the new list
   * and emit signals accordingly. New peers are added to new_peers,
   * and lost peers will remain in priv->peers: */
  new_peers = NULL;
  peers = g_hash_table_new_full (g_str_hash,
                                 g_str_equal,
                                 (GDestroyNotify)g_free,
                                 NULL);

  g_mutex_lock (priv->lock);
  for (i = 0; i < n_names; i++)
    {
      g_hash_table_insert (peers, g_strdup (names[i]), NULL);
      if (!g_hash_table_remove (priv->peers, names[i]))
        {
          /* The peer was not previously known */
          new_peers = g_slist_prepend (new_peers, (gchar *) names[i]);
        }      
    }

  /* Signal about lost peers */
  g_hash_table_iter_init (&hiter, priv->peers);
  while (g_hash_table_iter_next (&hiter, &hkey, &hval))
    {
      g_signal_emit (self, _peer_signals[PEER_LOST], 0, hkey);
    }

  old_peers_ht = priv->peers;
  priv->peers = peers;
  g_mutex_unlock (priv->lock);

  /* Signal about new peers */
  for (iter = new_peers; iter; iter = iter->next)
    {
      emit_peer_found (self, (const gchar*)iter->data);
    }

  /* The return value of g_variant_get_strv() is a shallow copy */
  g_free (names);
  g_variant_unref (val);

  /* Free just the array, not the strings - they are owned by 'peers' now */
  g_slist_free (new_peers);
  g_hash_table_destroy (old_peers_ht);
}

/* Install a DBus match rule, async, described by a printf-like format string.
 * The match rule will be properly retracted when @self is finalized */
static void
install_match_rule (DeePeer *self, const char *rule, ...)
{
  DeePeerPrivate *priv;
  gchar          *f_rule;
  va_list         args;

  g_return_if_fail (DEE_IS_PEER (self));
  g_return_if_fail (rule != NULL);

  priv = self->priv;
  
	va_start (args, rule);
  f_rule = g_strdup_vprintf (rule, args);
  va_end (args);

  /* By setting the error argument to NULL libdbus will use async mode
   * for adding the match rule. We want that. */
  g_dbus_connection_call (priv->connection,
                          "org.freedesktop.DBus",
                          "/org/freedesktop/dbus",
                          "org.freedesktop.DBus",
                          "AddMatch",
                          g_variant_new ("(s)", f_rule),
                          NULL, /* reply type */
                          G_DBUS_CALL_FLAGS_NONE,
                          -1,
                          NULL,  /* cancellable */
                          NULL,  /* callback */
                          NULL); /* user_data */
  
  priv->match_rules = g_slist_prepend (priv->match_rules, f_rule);
}

static void
remove_match_rule (GDBusConnection *conn, const gchar *rule)
{
  g_dbus_connection_call (conn,
                          "org.freedesktop.DBus",
                          "/org/freedesktop/dbus",
                          "org.freedesktop.DBus",
                          "RemoveMatch",
                          g_variant_new ("(s)", rule),
                          NULL, /* reply type */
                          G_DBUS_CALL_FLAGS_NONE,
                          -1,
                          NULL,  /* cancellable */
                          NULL,  /* callback */
                          NULL); /* user_data */
}

static const gchar*
dee_peer_real_get_swarm_leader (DeePeer *self)
{
  return self->priv->swarm_leader;
}

static gboolean
dee_peer_real_is_swarm_leader (DeePeer *self)
{
  return self->priv->is_swarm_leader;
}

static GSList*
dee_peer_real_get_connections (DeePeer *self)
{
  GSList *list = NULL;

  if (self->priv->connection)
    {
      list = g_slist_append (list, self->priv->connection);
    }

  return list;
}

static gchar**
dee_peer_real_list_peers (DeePeer *self)
{
  DeePeerPrivate *priv;
  GHashTableIter iter;
  gpointer key, value;
  gchar **result;
  int i;

  priv = self->priv;
  i = 0;

  g_mutex_lock (priv->lock);
  result = g_new (gchar*, g_hash_table_size (priv->peers) + 1);
  g_hash_table_iter_init (&iter, priv->peers);
  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      result[i++] = g_strdup ((gchar*) key);
    }
  g_mutex_unlock (priv->lock);

  result[i] = NULL;

  return result;
}

/* Public Methods */

/**
 * dee_peer_new:
 * @swarm_name: The name of the swarm to join.
 *              Fx &quot;org.example.DataProviders&quot;
 *
 * Create a new #DeePeer. The peer will immediately connect to the swarm
 * and start the peer discovery.
 *
 * Return value: (transfer full): A newly constructed #DeePeer.
 *               Free with g_object_unref().
 */
DeePeer*
dee_peer_new (const gchar* swarm_name)
{
  g_return_val_if_fail (swarm_name != NULL, NULL);

  return g_object_new (DEE_TYPE_PEER, "swarm-name", swarm_name, NULL);
}

/**
 * dee_peer_is_swarm_leader:
 * @self: a #DeePeer
 *
 * Return value: %TRUE if and only if this peer owns the swarm name on
 *               the session bus
 */
gboolean
dee_peer_is_swarm_leader (DeePeer *self)
{
  g_return_val_if_fail (DEE_IS_PEER (self), FALSE);

  DeePeerClass *klass = DEE_PEER_GET_CLASS (self);
  return klass->is_swarm_leader (self);
}

/**
 * dee_peer_get_swarm_leader:
 * @self: a #DeePeer
 *
 * In case this peer is connected to a message bus, gets the unique DBus
 * address of the current swarm leader, otherwise returns id of the leader.
 *
 * Return value: Unique DBus address of the current swarm leader,
 *    possibly %NULL if the leader has not been detected yet
 */
const gchar*
dee_peer_get_swarm_leader (DeePeer *self)
{
  g_return_val_if_fail (DEE_IS_PEER (self), NULL);

  DeePeerClass *klass = DEE_PEER_GET_CLASS (self);
  return klass->get_swarm_leader (self);
}

/**
 * dee_peer_get_swarm_name:
 * @self: a #DeePeer
 *
 * Gets the unique name for this swarm. The swarm leader is the Peer owning
 * this name on the session bus.
 *
 * Return value: The swarm name
 **/
const gchar*
dee_peer_get_swarm_name (DeePeer *self)
{
  g_return_val_if_fail (DEE_IS_PEER (self), NULL);

  return self->priv->swarm_name;
}

/**
 * dee_peer_get_connections:
 * @self: a #DeePeer
 *
 * Gets list of #GDBusConnection instances used by this #DeePeer instance.
 *
 * Return value: (transfer container) (element-type Gio.DBusConnection): 
 *               List of connections.
 */
GSList*
dee_peer_get_connections (DeePeer *self)
{
  g_return_val_if_fail (DEE_IS_PEER (self), NULL);

  DeePeerClass *klass = DEE_PEER_GET_CLASS (self);
  return klass->get_connections (self);
}

/**
 * dee_peer_list_peers:
 * @self: a #DeePeer
 *
 * Gets list of all peers currently in this swarm.
 *
 * Return value: (transfer full): List of peers (free using g_strfreev()).
 */
gchar**
dee_peer_list_peers (DeePeer *self)
{
  g_return_val_if_fail (DEE_IS_PEER (self), NULL);

  DeePeerClass *klass = DEE_PEER_GET_CLASS (self);
  return klass->list_peers (self);
}

/**
 * dee_peer_is_swarm_owner:
 * @self: a #DeePeer
 *
 * Gets the value of the :swarm-owner property.
 *
 * Note that this does NOT mean that the peer is leader of the swarm! Check also
 * dee_peer_is_swarm_leader().
 *
 * Return value: TRUE if the :swarm-owner property was set during construction.
 */
gboolean
dee_peer_is_swarm_owner (DeePeer *self)
{
  g_return_val_if_fail (DEE_IS_PEER (self), FALSE);

  return self->priv->swarm_owner;
}

static void
emit_peer_found (DeePeer     *self,
                 const gchar *name)
{
  DeePeerPrivate *priv;

  g_return_if_fail (DEE_IS_PEER(self));
  g_return_if_fail (name != NULL);

  priv = self->priv;
  
  if (!g_str_equal (name, priv->own_name))
    {
      g_signal_emit (self, _peer_signals[PEER_FOUND], 0, name);
    }
}

static void
set_swarm_name (DeePeer    *self,
                const gchar *swarm_name)
{
  DeePeerPrivate *priv;
  gchar           *dummy;

  g_return_if_fail (DEE_IS_PEER (self));
  g_return_if_fail (swarm_name != NULL);
  priv = self->priv;

  if (priv->swarm_name)
    {
      g_warning ("%s: Unable to set previously set swarm_name (%s) to (%s)",
                 G_STRLOC,
                 priv->swarm_name,
                 swarm_name);
      return;
    }

  /* If swarm_name is org.example.MyService then the swarm_path will
   * become /com/canonical/dee/org/example/MyService. Note that
   * the actual object path of the peer is not used in the Swarm spec */
  
  priv->swarm_name = g_strdup (swarm_name);
  dummy = g_strdelimit (g_strdup(swarm_name), ".", '/');
  priv->swarm_path = g_strdup_printf ("/com/canonical/dee/peer/%s", dummy);

  g_free (dummy);
}

static void
dispose_weak_ref (gpointer data)
{
  GWeakRef *weak_ref = (GWeakRef*) data;
  g_weak_ref_clear (weak_ref);
  g_free (data);
}

/* Called when we get the bus connection the first time. */
static void
on_bus_acquired (GDBusConnection *connection,
                 const gchar     *name,
                 gpointer         user_data)
{
  DeePeer        *self;
  DeePeerPrivate *priv;
  GWeakRef       *weak_ref;
  GPtrArray      *ptr_array;
  
  g_return_if_fail (DEE_IS_PEER (user_data));

  self = DEE_PEER (user_data);
  priv = self->priv;
  priv->connection = g_object_ref (connection);
  priv->own_name = g_strdup (g_dbus_connection_get_unique_name (connection));

  g_signal_emit (self, _peer_signals[CONNECTION_ACQUIRED], 0, priv->connection);

  /* Using GPtrArray as a ref-count container for the weak ref */
  weak_ref = (GWeakRef*) g_new (GWeakRef, 1);
  g_weak_ref_init (weak_ref, self);
  ptr_array = g_ptr_array_new_full (1, dispose_weak_ref);
  g_ptr_array_add (ptr_array, weak_ref);

  /* FIXME: the last param should be g_ptr_array_unref, but there's a bug
   * in gio that can cause a crash, we'll rather have a small leak than
   * random crashes.
   * https://bugzilla.gnome.org/show_bug.cgi?id=704568 */
  priv->filter_id = g_dbus_connection_add_filter (priv->connection,
                                                  gdbus_message_filter,
                                                  ptr_array,
                                                  NULL);
  
  /* Detect when someone joins the swarm */
  install_match_rule (self,
                      "interface='org.freedesktop.DBus',"
                      "member='RequestName',"
                      "arg0='%s'",
                      priv->swarm_name);

  /* Listen for all signals on the Dee interface concerning this swarm */
  priv->dbus_signals_id =
      g_dbus_connection_signal_subscribe(priv->connection,
                                         NULL,                /* sender */
                                         DEE_PEER_DBUS_IFACE, /* iface */
                                         NULL,                /* member */
                                         NULL,                /* object path */
                                         priv->swarm_name,    /* arg0 */
                                         G_DBUS_SIGNAL_FLAGS_NONE,
                                         on_dbus_peer_signal,      /* callback */
                                         self,                /* user_data */
                                         NULL);               /* user data free */
}

static void
assume_leadership (DeePeer *self)
{
  DeePeerPrivate *priv;

  g_return_if_fail (DEE_IS_PEER (self));

  priv = self->priv;
  if (priv->is_swarm_leader)
    {
      trace_object (self, "Leadership acquired, but we are already leaders");
    }
  else
    {
      trace_object (self, "Got swarm leadership");

      /* The first time we become leaders we install a broad match rule
       * that triggers any time someone drops off the bus.
       * Please note that we don't bother cleaning up that rule in the
       * rare case we loose leadership (which only happens if someone
       * forcefully grabs the swarm name) */
      if (!priv->has_been_leader)
        {
          install_match_rule (self, "interface='org.freedesktop.DBus',"
                                    "member='NameOwnerChanged',"
                                    "arg2=''");
        }

      priv->is_swarm_leader = TRUE;
      priv->has_been_leader = TRUE;

      g_free (priv->swarm_leader);
      priv->swarm_leader = g_strdup (priv->own_name);

      /* Emit a Ping so we can do a head count */
      emit_ping (self);

      /* Signal emission must be a "tail call"
       * because we can in theory be finalized by
       * one of the callbacks */
      g_object_notify (G_OBJECT (self), "swarm-leader");
    }

}

/* GDBus callback from the name owner installed with g_bus_own_name().
 * Called when losing leadership. */
static void
on_leadership_lost (GDBusConnection *connection,
                    const gchar     *name,
                    gpointer         user_data)
{
  DeePeer        *self;
  DeePeerPrivate *priv;
  
  g_return_if_fail (DEE_IS_PEER (user_data));

  self = DEE_PEER (user_data);
  priv = self->priv;

  if (priv->is_swarm_leader)
    {      
      /* We signal the change of swarm leadership in on_ping_received(),
       * only at that point do we know the unique name of the new leader */
      trace_object (self, "Lost swarm leadership");      
      // FIXME. We ought to remove the Pong match rule, but it's not paramount
      priv->is_swarm_leader = FALSE;      
    }
  else
    {
      trace_object (self, "Did not become leader");
    }

  /* If this is the first time we are notified that we are not the leader
   * then request a roster from the leader */
  if (priv->is_first_name_check)
    {
      trace_object (self, "Requesting peer roster from leader");
      if (priv->list_cancellable)
        {
          g_cancellable_cancel (priv->list_cancellable);
          g_object_unref (priv->list_cancellable);
        }
      priv->list_cancellable = g_cancellable_new ();
      g_dbus_connection_call (priv->connection,
                              priv->swarm_name,
                              priv->swarm_path,
                              DEE_PEER_DBUS_IFACE,
                              "List",
                              g_variant_new ("()"),
                              NULL,                   /* reply type */
                              G_DBUS_CALL_FLAGS_NONE,
                              -1,
                              priv->list_cancellable, /* cancellable */
                              on_list_received,       /* callback */
                              self);                  /* user_data */
      priv->is_first_name_check = FALSE;
    }
}

/* GDBus callback from the name owner installed with g_bus_own_name().
 * Called when we become leaders. */
static void
on_leadership_acquired (GDBusConnection *connection,
                        const gchar     *name,
                        gpointer         user_data)
{
  g_return_if_fail (DEE_IS_PEER (user_data));

  assume_leadership (DEE_PEER (user_data));
}

/* Callback from the GDBus name watcher installed with g_bus_watch_name() */
static void
on_leadership_changed (GDBusConnection *connection,
                       const gchar     *name,
                       const gchar     *name_owner,
                       gpointer         user_data)
{
  DeePeer        *self;
  DeePeerPrivate *priv;

  g_return_if_fail (DEE_IS_PEER (user_data));

  self = DEE_PEER (user_data);
  priv = self->priv;

  /* Don't bother if we already know this leader */
  if (g_strcmp0 (priv->swarm_leader, name_owner) == 0)
    return;

  /* At this point we assume we have a new leader */
  if (g_strcmp0 (priv->own_name, name_owner) == 0)
    assume_leadership (self);
  else
    {
      g_free (priv->swarm_leader);
      priv->swarm_leader = g_strdup (name_owner);
      priv->is_swarm_leader = FALSE;
      g_object_notify (G_OBJECT (self), "swarm-leader");
    }
}

/* Callback from gdbus_message_filter() for custom match rules
 * Indicates that @peer_address joined the swarm.
 * This method is thread safe */
static void
on_join_received (DeePeer     *self,
                  const gchar *peer_address)
{
  DeePeerPrivate *priv;

  g_return_if_fail (DEE_IS_PEER (self));
  g_return_if_fail (peer_address != NULL);

  trace_object (self, "Found peer %s", peer_address);
  priv = self->priv;

  /* If the peer is already known it must have tried to acquire the swarm name
   * twice...  Just ignore it */
  g_mutex_lock (priv->lock);
  if (g_hash_table_lookup_extended (priv->peers, peer_address, NULL, NULL))
    {
      g_mutex_unlock (priv->lock);
      return;
    }

  g_hash_table_insert (priv->peers, g_strdup (peer_address), NULL);
  g_mutex_unlock (priv->lock);

  emit_peer_found (self, peer_address);
}

/* Callback from _gdbus_message_filter() for custom match rules
 * Indicates that @peer_address left the swarm */
static void
on_bye_received (DeePeer    *self,
                 const gchar *peer_address)
{
  DeePeerPrivate *priv;
  gboolean        removed;

  g_return_if_fail (DEE_IS_PEER (self));
  g_return_if_fail (peer_address != NULL);

  trace_object (self, "Bye %s", peer_address);
  priv = self->priv;
  
  g_mutex_lock (priv->lock);
  removed = g_hash_table_remove (self->priv->peers, peer_address);
  g_mutex_unlock (priv->lock);

  if (removed)
    {
      trace_object (self, "Leader said Bye to %s", peer_address);
      g_signal_emit (self, _peer_signals[PEER_LOST], 0, peer_address);
    }
  else
    {
      trace_object (self, "Unknown peer '%s' dropped out of the swarm",
                    peer_address);
    }

}

/* Broadcast a Bye signal to to notify the swarm that someone left.
 * Only call this method as swarm leader - that's the contract
 * of the Swarm spec.
 * This method is thread safe */
static void
emit_bye (DeePeer     *self,
          const gchar *peer_address)
{
  DeePeerPrivate *priv;

  g_return_if_fail (DEE_IS_PEER (self));
  g_return_if_fail (self->priv->is_swarm_leader);
  g_return_if_fail (self->priv->connection != NULL);
  g_return_if_fail (peer_address != NULL);

  trace_object (self, "Emit Bye(%s)", peer_address);

  g_signal_emit (self, _peer_signals[PEER_LOST], 0, peer_address);

  priv = self->priv;
  g_dbus_connection_emit_signal (priv->connection,
                                 NULL,                 /* destination */
                                 priv->swarm_path,     /* object path */
                                 DEE_PEER_DBUS_IFACE,  /* interface */
                                 "Bye",                /* signal name */
                                 g_variant_new ("(ss)",
                                                priv->swarm_name, peer_address),
                                 NULL);                /* error */
}

/* Timeout started when we receive a Ping. When this timeout triggers
 * we do a diff of priv->head_count and priv->peers and emit peer-lost
 * as appropriate. We don't need to emit peer-found because that is already
 * done in when receiving the Pongs from the peers */
static gboolean
on_head_count_complete (DeePeer *self)
{
  DeePeerPrivate *priv;
  GHashTable     *new_peers;
  gpointer        hkey, hval;
  GHashTableIter  hiter;
  GSList         *iter;

  g_return_val_if_fail (DEE_IS_PEER (self), FALSE);

  priv = self->priv;

  /* First we build a new_peers hash set with the names of the
   * head counted peers. Then we diff the old and the new peers
   * sets and emit peer-lost appropriately */
  new_peers = g_hash_table_new_full (g_str_hash,
                                       g_str_equal,
                                       (GDestroyNotify) g_free,
                                       NULL);

  /* Build new_peers hash set */
  iter = priv->head_count;
  for (iter = priv->head_count; iter; iter = iter->next)
    {
      g_hash_table_insert (new_peers, g_strdup (iter->data), NULL);
    }

  /* Emit peer-lost and Bye on peers that didn't emit Pong in due time */
  g_mutex_lock (priv->lock);
  g_hash_table_iter_init (&hiter, priv->peers);
  while (g_hash_table_iter_next (&hiter, &hkey, &hval))
    {
      if (!g_hash_table_lookup_extended (new_peers, hkey, NULL, NULL))
        {
          if (priv->is_swarm_leader)
            emit_bye (self, hkey);
          else
            g_signal_emit (self, _peer_signals[PEER_LOST], 0, hkey);

        }
    }

  /* Swap old and new peers hash sets */
  g_hash_table_destroy (priv->peers);
  priv->peers = new_peers;
  g_mutex_unlock (priv->lock);

  /* Unregister the head count timeout source. And reset head counting mode */
  priv->head_count_source = 0;
  g_slist_foreach (priv->head_count, (GFunc) g_free, NULL);
  g_slist_free (priv->head_count);
  priv->head_count = NULL;

  return FALSE;
}

/* Indicates that @leader_address send a Ping to the swarm to
 * initiate a head count */
static void
on_ping_received (DeePeer    *self,
                  const gchar *leader_address)
{
  DeePeerPrivate *priv;
  
  g_return_if_fail (DEE_IS_PEER (self));
  g_return_if_fail (leader_address != NULL);
  
  priv = self->priv;

  trace_object (self, "Got Ping from: %s", leader_address);

  /* When we receive a Ping (and note that the swarm leader will receive its
   * own Ping as well) we enter a "head count mode" where we will consider
   * all peers that haven't given us a Pong within a certain timeout for lost.
   *
   * We indicate that we are in head counting mode by setting
   * priv->head_count != NULL
   */
  if (priv->head_count)
    {
      g_slist_foreach (priv->head_count, (GFunc) g_free, NULL);
      g_slist_free (priv->head_count);
    }

  priv->head_count = g_slist_prepend (NULL, g_strdup (priv->own_name));
  if (priv->head_count_source != 0)
    {
      /* Reset the timer if we got another ping */
      g_source_remove (priv->head_count_source);
    }
  priv->head_count_source = g_timeout_add (500,
                                           (GSourceFunc) on_head_count_complete,
                                           self);

  /* The DeePeer protocol says we must respond with a Pong to any Ping */
  emit_pong(self);
}

/* Indicates that @peer_address has emitted a Pong  */
static void
on_pong_received (DeePeer    *self,
                  const gchar *peer_address)
{
  DeePeerPrivate *priv;

  g_return_if_fail (DEE_IS_PEER (self));
  g_return_if_fail (peer_address != NULL);

  priv = self->priv;
  trace_object (self, "Got pong %s", peer_address);
 
  g_mutex_lock (priv->lock);
  if (!g_hash_table_lookup_extended (priv->peers, peer_address, NULL, NULL))
    {
      g_hash_table_insert (priv->peers, g_strdup (peer_address), NULL);

      emit_peer_found (self, peer_address);
    }
  g_mutex_unlock (priv->lock);

  /* If we are in head counting mode register this Ping */
  if (priv->head_count)
    priv->head_count = g_slist_prepend (priv->head_count,
                                        g_strdup (peer_address));
}

static void
on_dbus_peer_signal (GDBusConnection *connection,
                    const gchar      *sender_name,
                    const gchar      *object_path,
                    const gchar      *interface_name,
                    const gchar      *signal_name,
                    GVariant         *parameters,
                    gpointer          user_data)
{
  DeePeer          *self;
  gchar            *peer_address = NULL;

  g_return_if_fail (DEE_IS_PEER (user_data));

  self = DEE_PEER (user_data);

  if (g_strcmp0 ("Bye", signal_name) == 0)
    {
      g_variant_get (parameters, "(ss)", NULL, &peer_address);
      on_bye_received (self, peer_address);
    }
  else if (g_strcmp0 ("Ping", signal_name) == 0)
    on_ping_received (self, sender_name);
  else if (g_strcmp0 ("Pong", signal_name) == 0)
    on_pong_received (self, sender_name);
  else
    g_critical ("Unexpected signal from peer %s: %s.%s",
                sender_name, interface_name, signal_name);
}

/* Broadcast a Ping signal to do a head-count on the swarm.
 * Only call this method as swarm leader - that's the contract
 * of the Swarm spec.
 * This method is thread safe */
static void
emit_ping (DeePeer    *self)
{
  DeePeerPrivate *priv;

  g_return_if_fail (DEE_IS_PEER (self));
  g_return_if_fail (self->priv->is_swarm_leader);
  g_return_if_fail (self->priv->connection != NULL);

  trace_object (self, "Emit ping");
  
  priv = self->priv;
  g_dbus_connection_emit_signal (priv->connection,
                                 NULL,                 /* destination */
                                 priv->swarm_path,     /* object path */
                                 DEE_PEER_DBUS_IFACE,  /* interface */
                                 "Ping",               /* signal name */
                                 g_variant_new ("(s)", priv->swarm_name),
                                 NULL);                /* error */
}

/* Broadcast a Pong signal as a response to a Ping.
 * This method is thread safe */
static void
emit_pong (DeePeer    *self)
{
  DeePeerPrivate *priv;

  g_return_if_fail (DEE_IS_PEER (self));
  g_return_if_fail (self->priv->connection != NULL);

  trace_object (self, "Emit pong");
  
  priv = self->priv;
  g_dbus_connection_emit_signal (priv->connection,
                                 NULL,                 /* destination */
                                 priv->swarm_path,     /* object path */
                                 DEE_PEER_DBUS_IFACE,  /* interface */
                                 "Pong",               /* signal name */
                                 g_variant_new ("(s)", priv->swarm_name),
                                 NULL);                /* error */
}

/* Return floating variant of type '(as)' with unique DBus names of all peers.
 * This method is thread safe */
static GVariant*
build_peer_list (DeePeer *self)
{
  DeePeerPrivate  *priv;
  GHashTableIter   iter;
  GVariantBuilder  b;
  gpointer         key, val;

  g_return_val_if_fail (DEE_IS_PEER (self), FALSE);

  priv = self->priv;

  g_variant_builder_init (&b, G_VARIANT_TYPE ("(as)"));
  g_variant_builder_open (&b, G_VARIANT_TYPE ("as"));

  g_mutex_lock (priv->lock);
  g_hash_table_iter_init (&iter, priv->peers);
  while (g_hash_table_iter_next (&iter, &key, &val))
  {
    g_variant_builder_add (&b, "s", key);
  }
  g_mutex_unlock (priv->lock);

  g_variant_builder_close (&b);
  return g_variant_builder_end (&b);
}

/* This method is thread safe */
static gboolean
check_method (GDBusMessage     *msg,
               const gchar      *iface,
               const gchar      *member,
               const gchar      *path)
{
  return msg != NULL &&
         G_DBUS_MESSAGE_TYPE_METHOD_CALL == g_dbus_message_get_message_type (msg) &&
         (iface == NULL || g_strcmp0 (g_dbus_message_get_interface (msg), iface) == 0) &&
         (member == NULL || g_strcmp0 (g_dbus_message_get_member (msg), member) == 0) &&
         (path == NULL || g_strcmp0 (g_dbus_message_get_path (msg), path) == 0);
}

/* This method is thread safe */
static gboolean
check_signal (GDBusMessage     *msg,
               const gchar      *iface,
               const gchar      *member,
               const gchar      *path)
{
  return msg != NULL &&
         G_DBUS_MESSAGE_TYPE_SIGNAL == g_dbus_message_get_message_type (msg) &&
         (iface == NULL || g_strcmp0 (g_dbus_message_get_interface (msg), iface) == 0) &&
         (member == NULL || g_strcmp0 (g_dbus_message_get_member (msg), member) == 0) &&
         (path == NULL || g_strcmp0 (g_dbus_message_get_path (msg), path) == 0);
}

/* Used to transfer data to the mainloop.
 * Use only for good, not evil, and only from gdbus_message_filter() */
static gboolean
transfer_to_mainloop (gpointer *args)
{
  GPtrArray *ptr_array;
  GWeakRef *weak_ref;
  GObject *object;
  GFunc cb = (GFunc) args[0];

  ptr_array = (GPtrArray*) args[1];
  weak_ref = (GWeakRef*) g_ptr_array_index (ptr_array, 0);

  object = (GObject*) g_weak_ref_get (weak_ref);
  if (object != NULL)
    {
      cb (object, args[2]);
      g_object_unref (object);
    }

  g_ptr_array_unref (ptr_array);
  g_free (args[2]);
  g_free (args);

  return FALSE;
}

/* Callback applied to all incoming DBus messages. We use this to grab
 * messages for our match rules and dispatch to the right on_*_received
 * function.
 * WARNING: This callback is run in the GDBus message handling thread -
 *          and NOT in the mainloop! */
static GDBusMessage*
gdbus_message_filter (GDBusConnection *connection,
                      GDBusMessage    *msg,
                      gboolean         incoming,
                      gpointer         user_data)
{
  DeePeer          *self;
  DeePeerPrivate   *priv;
  GVariant         *body;
  GDBusMessageType  msg_type;
  const gchar      *sender_address;
  gpointer         *data;
  GPtrArray        *ptr_array;
  GWeakRef         *weak_ref;

  ptr_array = (GPtrArray*) user_data;
  weak_ref = (GWeakRef*) g_ptr_array_index (ptr_array, 0);
  body = g_dbus_message_get_body (msg);
  sender_address = g_dbus_message_get_sender (msg);
  msg_type = g_dbus_message_get_message_type (msg);

  /* We have no business with outgoing messages */
  if (!incoming)
    return msg;

  /* We're only interested in method calls and signals */
  if (msg_type != G_DBUS_MESSAGE_TYPE_METHOD_CALL &&
      msg_type != G_DBUS_MESSAGE_TYPE_SIGNAL)
    return msg;

  /*trace ("FILTER: %p", user_data);
    trace ("Msg filter: From: %s, Iface: %s, Member: %s",
           dbus_message_get_sender (msg),
           dbus_message_get_interface (msg),
           dbus_message_get_member (msg));*/

  /* Important note: Apps consuming this lib will likely install custom match
   *                 rules which will trigger this filter. Hence we must do very
   *                 strict matching before we dispatch our methods */
  
  if (check_method (msg, "org.freedesktop.DBus", "RequestName", NULL) &&
      g_strcmp0 (sender_address, g_dbus_connection_get_unique_name (connection)) != 0 &&
      body != NULL)
    {
      gchar *swarm_name;

      self = (DeePeer*) g_weak_ref_get (weak_ref);
      if (self == NULL) return msg;
      priv = self->priv;

      g_variant_get (body, "(su)", &swarm_name, NULL);
      if (g_strcmp0 (swarm_name, priv->swarm_name) == 0)
        {
          /* Call on_join_received() in the main loop */
          data = g_new (gpointer, 3);
          data[0] = on_join_received;
          data[1] = g_ptr_array_ref (ptr_array);
          data[2] = g_strdup (sender_address);
          g_idle_add ((GSourceFunc) transfer_to_mainloop, data);
        }

      g_object_unref (self);
      g_free (swarm_name);
    }
  else if (check_signal (msg, "org.freedesktop.DBus", "NameOwnerChanged", NULL) && body != NULL)
    {
      gchar *old_address, *new_address, *peer_address;
      gboolean should_emit_bye;

      self = (DeePeer*) g_weak_ref_get (weak_ref);
      if (self == NULL) return msg;
      priv = self->priv;

      g_variant_get (body, "(sss)", &peer_address, &old_address, &new_address);

      /* Check if a known peer dropped off the bus and emit the Bye signal
       * if we are the swarm leaders */
      g_mutex_lock (priv->lock);
      should_emit_bye = priv->is_swarm_leader &&
                        g_strcmp0 (peer_address, old_address) == 0 &&
                        g_strcmp0 (new_address, "") == 0 &&
                        g_strcmp0 (peer_address, g_dbus_connection_get_unique_name (connection)) != 0 &&
                        g_hash_table_lookup_extended (priv->peers,
                                                      peer_address,
                                                      NULL,
                                                      NULL);
      g_mutex_unlock (priv->lock);

      if (should_emit_bye)
        {
          /* Call emit_bye() in the main loop */
          data = g_new (gpointer, 3);
          data[0] = emit_bye;
          data[1] = g_ptr_array_ref (ptr_array);
          data[2] = peer_address; // own
          g_idle_add ((GSourceFunc) transfer_to_mainloop, data);
          peer_address = NULL;
        }
      g_object_unref (self);
      g_free (old_address);
      g_free (new_address);
      g_free (peer_address);
    }
  else
    {
      self = (DeePeer*) g_weak_ref_get (weak_ref);
      if (self == NULL) return msg;
      priv = self->priv;

      if (check_method (msg, DEE_PEER_DBUS_IFACE, "List", priv->swarm_path))
        {
          /* We don't want to go through the whole GDBus
           * interface/introspection setup just to export the List method.
           * We just handle this particular method inline */
          GDBusMessage *reply;
          reply = g_dbus_message_new_method_reply (msg);
          g_dbus_message_set_body (reply, build_peer_list (self));
          g_dbus_connection_send_message (connection,
                                          reply,
                                          G_DBUS_SEND_MESSAGE_FLAGS_NONE,
                                          NULL,   /* out serial */
                                          NULL);  /* error */
          g_object_unref (reply);

          g_object_unref (self);
          /* Convince GDBus that we handled this message by returning NULL */
          return NULL;
        }
      g_object_unref (self);
    }

  return msg;
}
