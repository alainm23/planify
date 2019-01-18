/*
 * Copyright (C) 2010-2012 Canonical, Ltd.
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
 * Authored by:
 *               Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 *               Neil Jagdish Patel <neil.patel@canonical.com>
 *               Michal Hruby <michal.hruby@canonical.com>
 */

/**
 * SECTION:dee-shared-model
 * @short_description: A #DeeModel that can synchronize with other
 *    #DeeSharedModel objects across D-Bus.
 * @include: dee.h
 *
 * #DeeSharedModel is created with a name (usually namespaced and unique to
 * your program(s)) which is used to locate other #DeeSharedModels created
 * with the same name through D-Bus, and will keep synchronized  with them.
 *
 * This allows to you build MVC programs with a sane model API, but have the
 * controller (or multiple views) in a separate process.
 *
 * Before you modify the contents of the shared model it is important that
 * you wait for the model to synchronize with its peers. The normal way to do
 * this is to wait for the &quot;notify::synchronized&quot; signal.
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <memory.h>
#include <time.h>
#include <unistd.h>

#include "dee-peer.h"
#include "dee-model.h"
#include "dee-proxy-model.h"
#include "dee-sequence-model.h"
#include "dee-shared-model.h"
#include "dee-serializable-model.h"
#include "dee-serializable.h"
#include "dee-marshal.h"
#include "trace-log.h"
#include "com.canonical.Dee.Model-xml.h"

static void dee_shared_model_serializable_iface_init (DeeSerializableIface *iface);

static void dee_shared_model_model_iface_init        (DeeModelIface *iface);

G_DEFINE_TYPE_WITH_CODE (DeeSharedModel,
                         dee_shared_model,
                         DEE_TYPE_PROXY_MODEL,
                         G_IMPLEMENT_INTERFACE (DEE_TYPE_SERIALIZABLE,
                                                dee_shared_model_serializable_iface_init)
                         G_IMPLEMENT_INTERFACE (DEE_TYPE_MODEL,
                                                dee_shared_model_model_iface_init));

#define DEE_SHARED_MODEL_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_SHARED_MODEL, DeeSharedModelPrivate))

#define COMMIT_VARIANT_TYPE   G_VARIANT_TYPE("(sasaavauay(tt))")
#define COMMIT_TUPLE_ITEMS    6
#define CLONE_VARIANT_TYPE    G_VARIANT_TYPE("(sasaavauay(tt)a{sv})")
#define CLONE_TUPLE_ITEMS     7

/**
 * DeeSharedModelPrivate:
 *
 * Ignore this structure.
 **/
struct _DeeSharedModelPrivate
{
  DeePeer    *swarm;
  GSList     *connections;
  gchar      *model_path;

  guint64     last_committed_seqnum;
  /* Buffer of DeeSharedModelRevisions that we keep in order to batch
   * our DBus signals. The invariant is that all buffered revisions
   * are of the same type */
  GSList     *revision_queue;
  guint       revision_queue_timeout_id;
  guint       acquisition_timer_id;
  gulong      swarm_leader_handler;
  gulong      connection_acquired_handler;
  gulong      connection_closed_handler;
  GArray     *connection_infos;

  gboolean    synchronized;
  gboolean    found_first_peer;
  gboolean    suppress_remote_signals;
  gboolean    clone_in_progress;

  DeeSharedModelAccessMode access_mode;
  DeeSharedModelFlushMode flush_mode;
};

typedef struct
{
  /* The revision type is: ROWS_ADDED, ROWS_REMOVED, or ROWS_CHANGED */
  guchar      change_type;
  guint32     pos;
  guint64     seqnum;
  GVariant  **row;
  DeeModel   *model;
} DeeSharedModelRevision;

typedef struct
{
  GDBusConnection *connection;
  guint            signal_subscription_id;
  guint            registration_id;
} DeeConnectionInfo;
/* Globals */
static GQuark           dee_shared_model_error_quark       = 0;

enum
{
  PROP_0,
  PROP_PEER,
  PROP_SYNCHRONIZED,
  PROP_DISABLE_REMOTE_WRITES,
  PROP_ACCESS_MODE,
  PROP_FLUSH_MODE,
};

typedef enum
{
  CHANGE_TYPE_ADD    = '\x00',
  CHANGE_TYPE_REMOVE = '\x01',
  CHANGE_TYPE_CHANGE = '\x02',
  CHANGE_TYPE_CLEAR  = '\x03',
} ChangeType;


enum
{
  /* Public signal */
  BEGIN_TRANSACTION,
  END_TRANSACTION,

  LAST_SIGNAL
};

static guint32 _signals[LAST_SIGNAL] = { 0 };

/* Forwards */
static void     on_connection_acquired                 (DeeSharedModel  *self,
                                                        GDBusConnection *connection,
                                                        DeePeer         *peer);

static void     on_connection_closed                   (DeeSharedModel  *self,
                                                        GDBusConnection *connection,
                                                        DeePeer         *peer);

static void     commit_transaction                     (DeeSharedModel *self,
                                                        const gchar    *sender_name,
                                                        GVariant       *transaction);

static void     on_clone_received                      (GObject      *source_object,
                                                        GAsyncResult *res,
                                                        gpointer      user_data);

static void     clone_leader                           (DeeSharedModel *self);

static void     on_dbus_signal_received                (GDBusConnection *connection,
                                                        const gchar     *sender_name,
                                                        const gchar     *object_path,
                                                        const gchar     *interface_name,
                                                        const gchar     *signal_name,
                                                        GVariant        *parameters,
                                                        gpointer         user_data);

static void     on_leader_changed                      (DeeSharedModel  *self);

static DeeSharedModelRevision*
                dee_shared_model_revision_new    (ChangeType         type,
                                                  guint32            pos,
                                                  guint64            seqnum,
                                                  GVariant         **row,
                                                  DeeModel          *model);

static void     dee_shared_model_revision_free  (DeeSharedModelRevision *rev);

static gboolean flush_revision_queue_timeout_cb  (DeeModel         *self);
static guint    flush_revision_queue             (DeeModel         *self);

static void     enqueue_revision                 (DeeModel          *self,
                                                  ChangeType         type,
                                                  guint32            pos,
                                                  guint64            seqnum,
                                                  GVariant         **row);

static void     dee_shared_model_parse_vardict_schemas (DeeModel *model,
                                                        GVariantIter *iter,
                                                        guint n_cols);

static void        on_self_row_added             (DeeModel     *self,
                                                  DeeModelIter *iter);

static void        on_self_row_removed           (DeeModel     *self,
                                                  DeeModelIter *iter);

static void        on_self_row_changed           (DeeModel     *self,
                                                  DeeModelIter *iter);

static void        reset_model                   (DeeModel       *self);

static void        invalidate_peer               (DeeSharedModel  *self,
                                                  const gchar     *sender_name,
                                                  GDBusConnection *except);

static gboolean    on_invalidate                 (DeeSharedModel  *self);


/* Create a new revision. The revision will own @row */
static DeeSharedModelRevision*
dee_shared_model_revision_new (ChangeType type,
                               guint32    pos,
                               guint64    seqnum,
                               GVariant **row,
                               DeeModel  *model)
{
  DeeSharedModelRevision *rev;

  g_return_val_if_fail (type != CHANGE_TYPE_REMOVE &&
      type != CHANGE_TYPE_CLEAR ? row != NULL : TRUE, NULL);

  rev = g_slice_new (DeeSharedModelRevision);
  rev->change_type = (guchar) type;
  rev->pos = pos;
  rev->seqnum = seqnum;
  rev->row = row;
  rev->model = model;

  return rev;
}

/* Free all resources owned by a revision, and the revision itself */
static void
dee_shared_model_revision_free (DeeSharedModelRevision *rev)
{
  guint n_cols, i;
  gsize row_slice_size;

  g_return_if_fail (rev != NULL);

  n_cols = dee_model_get_n_columns (rev->model);
  row_slice_size = n_cols * sizeof(gpointer);

  for (i = 0; i < n_cols && rev->row != NULL; i++)
    g_variant_unref (rev->row[i]);

  g_slice_free1 (row_slice_size, rev->row);
  g_slice_free (DeeSharedModelRevision, rev);
}

static gboolean
flush_revision_queue_timeout_cb (DeeModel *self)
{
  DeeSharedModelPrivate  *priv;
  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self), FALSE);
  priv = DEE_SHARED_MODEL (self)->priv;

  priv->revision_queue_timeout_id = 0;
  flush_revision_queue (self);

  return FALSE;
}

/* Emit all queued revisions in one signal on the bus.
 * Clears the revision_queue_timeout  if there is one set.
 * Returns the number of flushed revisions */
static guint
flush_revision_queue (DeeModel *self)
{
  DeeSharedModelPrivate  *priv;
  DeeSharedModelRevision *rev;
  GError                 *error;
  GSList                 *iter;
  GSList                 *connection_iter;
  GVariant               *schema;
  GVariant               *transaction_variant;
  GVariantBuilder         aav, au, ay, transaction;
  guint64                 seqnum_begin = 0, seqnum_end = 0;
  guint                   n_cols, i;

  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self), 0);
  priv = DEE_SHARED_MODEL (self)->priv;

  /* If we are not connected yet, this should be a no-op.
   * There are two cases to consider:
   * 1) We are building a model before we are even connected.
   *    This only makes sense if we are sure to become leaders,
   *    we'll assume the programmer knows this
   * 2) We are resetting the model - no problem
   */
  if (priv->connections == NULL)
    {
      trace_object (self, "Flushing revision queue, without a connection. "
                          "This will blow up unless you are the leader model");
      g_slist_foreach (priv->revision_queue,
                       (GFunc) dee_shared_model_revision_free,
                       NULL);
      g_slist_free (priv->revision_queue);
      priv->revision_queue = NULL;
    }

  /* Clear the current timeout if we have one running */
  if (priv->revision_queue_timeout_id != 0)
    {
      g_source_remove (priv->revision_queue_timeout_id);
      priv->revision_queue_timeout_id = 0;
    }

  /* If we don't have anything queued up, just return. It's assumed beyond
   * this point that it is non-empty */
  if (priv->revision_queue == NULL)
    {
      priv->last_committed_seqnum = dee_serializable_model_get_seqnum (self);
      return 0;
    }

  /* Since we always prepend to the queue we need to reverse it */
  priv->revision_queue = g_slist_reverse (priv->revision_queue);

  n_cols = dee_model_get_n_columns (self);

  /* We know that the revision_queue is non-empty at this point. We peek the
   * first element and assume that the last seqnum before this transaction
   * started was the seqnum in the first revision - 1. */
  seqnum_end = ((DeeSharedModelRevision *) priv->revision_queue->data)->seqnum - 1;
  seqnum_begin = priv->last_committed_seqnum;

  g_variant_builder_init (&aav, G_VARIANT_TYPE ("aav"));
  g_variant_builder_init (&au, G_VARIANT_TYPE ("au"));
  g_variant_builder_init (&ay, G_VARIANT_TYPE ("ay"));
  for (iter = priv->revision_queue; iter; iter = iter->next)
    {
      gboolean is_remove;
      gboolean sequential_revnum;

      rev = (DeeSharedModelRevision*) iter->data;
      is_remove = rev->change_type == CHANGE_TYPE_REMOVE ||
        rev->change_type == CHANGE_TYPE_CLEAR;
      /* Clears are "compressed" so they don't require sequential revnums */
      sequential_revnum = rev->change_type != CHANGE_TYPE_CLEAR;

      /* Sanity check our seqnums */
      if (sequential_revnum && rev->seqnum != seqnum_end + 1)
        {
          g_critical ("Internal accounting error of DeeSharedModel@%p. Seqnums "
                      "not sequential: "
                      "%"G_GUINT64_FORMAT" != %"G_GUINT64_FORMAT" + 1",
                      self, rev->seqnum, seqnum_end);
          return 0;
        }
      seqnum_end = rev->seqnum;

      if ((is_remove) != (rev->row == NULL))
        {
          g_critical ("Internal accounting error is DeeSharedModel@%p. "
                      "Transaction row payload must be empty iff the change"
                      "type is is a removal", self);
        }

      /* Build the variants for this change */
      g_variant_builder_open (&aav, G_VARIANT_TYPE ("av"));
      for (i = 0; i < n_cols && !is_remove; i++)
        {
          g_variant_builder_add_value (&aav,
                                       g_variant_new_variant (rev->row[i]));
        }
      g_variant_builder_close (&aav);
      g_variant_builder_add (&au, "u", rev->pos);
      g_variant_builder_add (&ay, "y", (guchar) rev->change_type);

      /* Free the revisions while we are traversing the linked list anyway */
      dee_shared_model_revision_free (rev);
    }

  /* Collect the schema */
  schema = g_variant_new_strv (dee_model_get_schema(self, NULL), -1);

  /* Build the Commit message */
  g_variant_builder_init (&transaction, COMMIT_VARIANT_TYPE);
  g_variant_builder_add (&transaction, "s", dee_peer_get_swarm_name (priv->swarm));
  g_variant_builder_add_value (&transaction, schema);
  g_variant_builder_add_value (&transaction, g_variant_builder_end (&aav));
  g_variant_builder_add_value (&transaction, g_variant_builder_end (&au));
  g_variant_builder_add_value (&transaction, g_variant_builder_end (&ay));
  g_variant_builder_add_value (&transaction,
                               g_variant_new ("(tt)", seqnum_begin, seqnum_end));

  transaction_variant = g_variant_builder_end (&transaction);

  /* Throw a Commit signal */
  for (connection_iter = priv->connections; connection_iter != NULL;
       connection_iter = connection_iter->next)
    {
      error = NULL;
      g_dbus_connection_emit_signal((GDBusConnection*) connection_iter->data,
                                    NULL,
                                    priv->model_path,
                                    "com.canonical.Dee.Model",
                                    "Commit",
                                    transaction_variant,
                                    &error);

      if (error != NULL)
        {
          g_critical ("Failed to emit DBus signal "
                      "com.canonical.Dee.Model.Commit: %s", error->message);
          g_error_free (error);
        }
    }

  trace_object (self, "Flushed %"G_GUINT64_FORMAT" revisions. "
                "Seqnum range %"G_GUINT64_FORMAT"-%"G_GUINT64_FORMAT,
                seqnum_end - seqnum_begin, seqnum_begin, seqnum_end);

  /* Free and reset the queue. Note that we freed the individual revisions while
   * we constructed the Commit message */
  g_slist_free (priv->revision_queue);
  priv->revision_queue = NULL;

  priv->last_committed_seqnum = seqnum_end;

  return seqnum_end - seqnum_begin; // Very theoretical overflow possible here...
}

/* Prepare a revision to be emitted as a signal on the bus. The revisions
 * are queued up so that we can emit them in batches. Steals the ref on the
 * row array and assumes the refs on the variants as well */
static void
enqueue_revision (DeeModel  *self,
                  ChangeType type,
                  guint32    pos,
                  guint64    seqnum,
                  GVariant **row)
{
  DeeSharedModelPrivate  *priv;
  DeeSharedModelRevision *rev;

  g_return_if_fail (DEE_IS_SHARED_MODEL (self));
  priv = DEE_SHARED_MODEL (self)->priv;

  rev = dee_shared_model_revision_new (type, pos, seqnum, row, self);

  priv->revision_queue = g_slist_prepend (priv->revision_queue, rev);

  /* Flush the revision queue once in idle */
  if (priv->revision_queue_timeout_id == 0 &&
      priv->flush_mode == DEE_SHARED_MODEL_FLUSH_MODE_AUTOMATIC)
    {
      priv->revision_queue_timeout_id =
        g_idle_add ((GSourceFunc)flush_revision_queue_timeout_cb, self);
    }
}

/* GObject stuff */
static void
dee_shared_model_finalize (GObject *object)
{
  guint i;
  DeeSharedModelPrivate *priv = DEE_SHARED_MODEL (object)->priv;

  /* Flush any pending revisions */
  if (priv->revision_queue != NULL)
    {
      flush_revision_queue (DEE_MODEL(object));
      priv->revision_queue = NULL;
    }

  if (priv->acquisition_timer_id != 0)
    {
      g_source_remove (priv->acquisition_timer_id);
      priv->acquisition_timer_id = 0;
    }

  if (priv->connection_acquired_handler)
    {
      g_signal_handler_disconnect (priv->swarm,
                                   priv->connection_acquired_handler);
      priv->connection_acquired_handler = 0;
    }

  if (priv->connection_closed_handler)
    {
      g_signal_handler_disconnect (priv->swarm, priv->connection_closed_handler);
      priv->connection_closed_handler = 0;
    }

  if (priv->connection_infos != NULL)
    {
      for (i = 0; i < priv->connection_infos->len; i++)
        {
          DeeConnectionInfo *info;
          info = &g_array_index (priv->connection_infos, DeeConnectionInfo, i);
          g_dbus_connection_unregister_object (info->connection,
                                               info->registration_id);
          g_dbus_connection_signal_unsubscribe (info->connection,
                                                info->signal_subscription_id);
        }

      g_array_unref (priv->connection_infos);
      priv->connection_infos = NULL;
    }
  if (priv->swarm_leader_handler != 0)
    {
      g_signal_handler_disconnect (priv->swarm, priv->swarm_leader_handler);
      priv->swarm_leader_handler = 0;
    }
  if (priv->model_path)
      {
        g_free (priv->model_path);
      }
  if (priv->connections)
    {
      g_slist_free (priv->connections);
      priv->connections = NULL;
    }
  if (priv->swarm)
    {
      g_object_unref (priv->swarm);
      priv->swarm = NULL;
    }

  G_OBJECT_CLASS (dee_shared_model_parent_class)->finalize (object);
}

static void
dee_shared_model_set_property (GObject      *object,
                               guint         id,
                               const GValue *value,
                               GParamSpec   *pspec)
{
  DeeSharedModelPrivate *priv;

  priv = DEE_SHARED_MODEL (object)->priv;

  switch (id)
  {
    case PROP_PEER:
      if (priv->swarm != NULL)
        g_object_unref (priv->swarm);
      priv->swarm = g_value_dup_object (value);
      break;
    case PROP_SYNCHRONIZED:
      g_critical ("Trying to set read only property DeeSharedModel:synchronized");
      break;
    case PROP_ACCESS_MODE:
      priv->access_mode = g_value_get_enum (value);
      break;
    case PROP_FLUSH_MODE:
      priv->flush_mode = g_value_get_enum (value);
      if (priv->flush_mode != DEE_SHARED_MODEL_FLUSH_MODE_AUTOMATIC &&
          priv->revision_queue_timeout_id != 0)
        {
          g_source_remove (priv->revision_queue_timeout_id);
          priv->revision_queue_timeout_id = 0;
        }
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
  }
}

static void
dee_shared_model_get_property (GObject    *object,
                               guint       id,
                               GValue     *value,
                               GParamSpec *pspec)
{
  DeeSharedModelPrivate *priv;

  priv = DEE_SHARED_MODEL (object)->priv;

  switch (id)
  {
    case PROP_PEER:
      g_value_set_object (value, priv->swarm);
      break;
    case PROP_SYNCHRONIZED:
      g_value_set_boolean (value, priv->synchronized);
      break;
    case PROP_ACCESS_MODE:
      g_value_set_enum (value, priv->access_mode);
      break;
    case PROP_FLUSH_MODE:
      g_value_set_enum (value, priv->flush_mode);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
  }
}

static gboolean
iterate_connections (DeeSharedModel *self)
{
  DeeSharedModelPrivate *priv;
  GSList                *connections_list, *iter;

  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self), FALSE);
  priv = self->priv;

  /* unblock the handlers */
  g_signal_handler_unblock (priv->swarm, priv->connection_acquired_handler);
  g_signal_handler_unblock (priv->swarm, priv->connection_closed_handler);
  connections_list = dee_peer_get_connections (priv->swarm);

  for (iter = connections_list; iter != NULL; iter = iter->next)
    {
      on_connection_acquired (self, (GDBusConnection*) iter->data, priv->swarm);
    }

  g_slist_free (connections_list);
  priv->acquisition_timer_id = 0;

  return FALSE;
}

static void
dee_shared_model_constructed (GObject *object)
{
  DeeSharedModel        *self;
  DeeSharedModelPrivate *priv;
  gchar                 *dummy;
  GSList                *connections_list;

  /* GObjectClass has NULL 'constructed' member, but we add this check for
   * future robustness if we ever move to another base class */
  if (G_OBJECT_CLASS (dee_shared_model_parent_class)->constructed != NULL)
    G_OBJECT_CLASS (dee_shared_model_parent_class)->constructed (object);

  self = DEE_SHARED_MODEL (object);
  priv = self->priv;

  if (priv->swarm == NULL)
    {
      g_critical ("You must create a DeeSharedModel with a DeePeer "
                  "in the 'peer' property");
      return;
    }

  /* Create a canonical object path from the well known swarm name */
  dummy = g_strdup (dee_peer_get_swarm_name (priv->swarm));
  priv->model_path = g_strconcat ("/com/canonical/dee/model/",
                                  g_strdelimit (dummy, ".", '/'),
                                  NULL);
  g_free (dummy);

  priv->swarm_leader_handler =
    g_signal_connect_swapped (priv->swarm, "notify::swarm-leader",
                              G_CALLBACK (on_leader_changed), self);

  priv->connection_acquired_handler =
    g_signal_connect_swapped (priv->swarm, "connection-acquired",
                              G_CALLBACK (on_connection_acquired), self);

  priv->connection_closed_handler =
    g_signal_connect_swapped (priv->swarm, "connection-closed",
                              G_CALLBACK (on_connection_closed), self);

  /* we don't want to invoke on_connection_acquired from here, it would mean
   * emitting important signal when inside g_object_new, so block the handlers
   * and call on_connection_acquired in idle callback */
  connections_list = dee_peer_get_connections (priv->swarm);
  if (g_slist_length (connections_list) > 0)
    {
      g_signal_handler_block (priv->swarm, priv->connection_acquired_handler);
      g_signal_handler_block (priv->swarm, priv->connection_closed_handler);

      priv->acquisition_timer_id = g_idle_add_full (G_PRIORITY_DEFAULT,
          (GSourceFunc) iterate_connections, self, NULL);
    }
  g_slist_free (connections_list);
}

static void
dee_shared_model_class_init (DeeSharedModelClass *klass)
{
  GParamSpec    *pspec;
  GObjectClass  *obj_class = G_OBJECT_CLASS (klass);

  obj_class->finalize     = dee_shared_model_finalize;
  obj_class->set_property = dee_shared_model_set_property;
  obj_class->get_property = dee_shared_model_get_property;
  obj_class->constructed  = dee_shared_model_constructed;

  /**
   * DeeSharedModel:peer:
   *
   * The #DeePeer that this model uses to connect to the swarm
   */
  pspec = g_param_spec_object ("peer", "Peer",
                               "The peer object that monitors the swarm",
                               DEE_TYPE_PEER,
                               G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                               | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_PEER, pspec);

  /**
   * DeeSharedModel:synchronized:
   *
   * Boolean property defining whether or not the model has synchronized with
   * its peers (if any) yet.
   *
   * You should not modify a #DeeSharedModel that is not synchronized. Before
   * modifying the model in any way (except calling dee_model_set_schema())
   * you should wait for it to become synchronized.
   */
  pspec = g_param_spec_boolean("synchronized", "Synchronized",
                               "Whether the model is synchronized with its peers",
                               FALSE,
                               G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_SYNCHRONIZED, pspec);

  /**
   * DeeSharedModel:access-mode:
   *
   * Enumeration defining behavior of this model when trying to write to it.
   *
   * Setting this to #DEE_SHARED_MODEL_ACCESS_MODE_LEADER_WRITABLE is useful
   * when one process is considered an "owner" of a model and all the other
   * peers are supposed to only synchronize it for reading.
   *
   * See also DeePeer:swarm-owner property to ensure ownership of a swarm.
   */
  pspec = g_param_spec_enum ("access-mode", "Access Mode",
                             "Access mode used by this shared model",
                             DEE_TYPE_SHARED_MODEL_ACCESS_MODE,
                             DEE_SHARED_MODEL_ACCESS_MODE_WORLD_WRITABLE,
                             G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                             | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_ACCESS_MODE, pspec);

  /**
   * DeeSharedModel:flush-mode:
   *
   * Enumeration defining the flushing behavior.
   *
   * Setting this to #DEE_SHARED_MODEL_FLUSH_MODE_MANUAL will disable 
   * automatic flushing that usually happens when the application's main event
   * loop is idle. Automatic flushing should be primarily disabled when 
   * a shared model is used from multiple threads, or when not using #GMainLoop.
   * When disabled, dee_shared_model_flush_revision_queue() needs to be called
   * explicitely.
   */
  pspec = g_param_spec_enum ("flush-mode", "Flush mode",
                             "Determines whether flushes occur automatically",
                             DEE_TYPE_SHARED_MODEL_FLUSH_MODE,
                             DEE_SHARED_MODEL_FLUSH_MODE_AUTOMATIC,
                             G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_FLUSH_MODE, pspec);

  /**
   * DeeSharedModel::begin-transaction:
   * @model: The shared model the signal is emitted on
   * @begin_seqnum: The seqnum the model has now
   * @end_seqnum: The seqnum the model will have after the transaction is applied
   *
   * Emitted right before a remote transaction will be committed to the model.
   */
  _signals[BEGIN_TRANSACTION] =
    g_signal_new ("begin-transaction",
                  DEE_TYPE_SHARED_MODEL,
                  G_SIGNAL_RUN_LAST,
                  0,
                  NULL, NULL,
                  _dee_marshal_VOID__UINT64_UINT64,
                  G_TYPE_NONE, 2,
                  G_TYPE_UINT64, G_TYPE_UINT64);

  /**
   * DeeSharedModel::end-transaction:
   * @model: The shared model the signal is emitted on
   * @begin_seqnum: The seqnum the model had before the transaction was applied
   * @end_seqnum: The seqnum the model has now
   *
   * Emitted right after a remote transaction has been committed to the model.
   */
  _signals[END_TRANSACTION] =
    g_signal_new ("end-transaction",
                  DEE_TYPE_SHARED_MODEL,
                  G_SIGNAL_RUN_LAST,
                  0,
                  NULL, NULL,
                  _dee_marshal_VOID__UINT64_UINT64,
                  G_TYPE_NONE, 2,
                  G_TYPE_UINT64, G_TYPE_UINT64);

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeSharedModelPrivate));

  /* Runtime-check that our defines are correct */
  g_assert (g_variant_type_n_items (CLONE_VARIANT_TYPE) == CLONE_TUPLE_ITEMS);
  g_assert (g_variant_type_n_items (COMMIT_VARIANT_TYPE) == COMMIT_TUPLE_ITEMS);
}

static void
dee_shared_model_init (DeeSharedModel *self)
{
  DeeSharedModelPrivate *priv;

  priv = self->priv = DEE_SHARED_MODEL_GET_PRIVATE (self);

  priv->swarm = NULL;
  priv->model_path = NULL;

  priv->last_committed_seqnum = 0;
  priv->revision_queue = NULL;
  priv->revision_queue_timeout_id = 0;
  priv->swarm_leader_handler = 0;

  priv->synchronized = FALSE;
  priv->found_first_peer = FALSE;
  priv->suppress_remote_signals = FALSE;

  if (!dee_shared_model_error_quark)
    dee_shared_model_error_quark = g_quark_from_string ("dbus-model-error");

  priv->connections = NULL;
  priv->connection_infos = g_array_new (FALSE, TRUE, sizeof (DeeConnectionInfo));

  /* Connect to our own signals so we can queue up revisions to be emitted
   * on the bus */
  g_signal_connect (self, "row-added", G_CALLBACK (on_self_row_added), NULL);
  g_signal_connect (self, "row-removed", G_CALLBACK (on_self_row_removed), NULL);
  g_signal_connect (self, "row-changed", G_CALLBACK (on_self_row_changed), NULL);
}

static void
handle_dbus_method_call (GDBusConnection       *connection,
                         const gchar           *sender,
                         const gchar           *object_path,
                         const gchar           *interface_name,
                         const gchar           *method_name,
                         GVariant              *parameters,
                         GDBusMethodInvocation *invocation,
                         gpointer               user_data)
{
  GVariant              *retval;

  g_return_if_fail (DEE_IS_SHARED_MODEL (user_data));

  if (g_strcmp0 ("Clone", method_name) == 0)
    {
      /* If we have anything in the rev queue it wont validate against the
       * seqnum for the cloned model. So flush the rev queue before answering
       * the Clone call */
      flush_revision_queue (DEE_MODEL (user_data));

      /* We return a special error if we have no schema. It's legal for the
       * leader to expect the schema from the slaves */
      if (dee_model_get_n_columns (DEE_MODEL (user_data)) == 0)
        {
          g_dbus_method_invocation_return_dbus_error (invocation,
                                                      "com.canonical.Dee.Model.NoSchemaError",
                                                      "No schema defined");
        }
      else
        {
          // FIXME: It can be expensive to build the clone. Perhaps thread this?
          retval = dee_serializable_serialize (DEE_SERIALIZABLE (user_data));
          g_dbus_method_invocation_return_value (invocation, retval);
          /* dee_serializable_serialize returns full ref, unref it */
          g_variant_unref (retval);
        }
    }
  else if (g_strcmp0 ("Invalidate", method_name) == 0)
    {
      on_invalidate (DEE_SHARED_MODEL (user_data));
      g_dbus_method_invocation_return_value (invocation, NULL);
    }
  else
    {
      g_warning ("Unknown DBus method call %s.%s from %s on DeeSharedModel",
                 interface_name, method_name, sender);
    }
}

static const GDBusInterfaceVTable model_interface_vtable =
{
  handle_dbus_method_call,
  NULL,
  NULL
};

static void
on_connection_acquired (DeeSharedModel *self,
                        GDBusConnection *connection,
                        DeePeer *peer)
{
  DeeSharedModelPrivate *priv;
  DeeConnectionInfo      connection_info;
  GDBusNodeInfo         *model_introspection_data;
  guint                  dbus_signal_handler;
  guint                  model_registration_id;

  /* Keep the parsed introspection data of the Model interface around */
  static GDBusInterfaceInfo *model_interface_info = NULL;

  g_return_if_fail (DEE_IS_SHARED_MODEL (self));

  priv = self->priv;

  if (connection == NULL)
    {
      g_warning ("Internal error in DeeSharedModel. %s called with NULL "
                 "connection", __func__);
      return;
    }

  /* Update our list of connections */
  if (priv->connections) g_slist_free (priv->connections);
  priv->connections = dee_peer_get_connections (priv->swarm);

  /* Listen for changes from the peers in the same swarm.
   * We do this by matching arg0 with the swarm name */
  dbus_signal_handler = g_dbus_connection_signal_subscribe (
                                         connection,
                                         NULL,                // sender
                                         "com.canonical.Dee.Model", // iface
                                         NULL,                // member
                                         NULL,                // object path
                                         dee_peer_get_swarm_name (priv->swarm), // arg0
                                         G_DBUS_SIGNAL_FLAGS_NONE,
                                         on_dbus_signal_received,
                                         self,                // user data
                                         NULL);               // user data destroy

  /* Load com.canonical.Dee.Model introspection XML on first run */
  if (model_interface_info == NULL)
    {
      model_introspection_data = g_dbus_node_info_new_for_xml (
                                             com_canonical_Dee_Model_xml, NULL);
      model_interface_info = g_dbus_node_info_lookup_interface (
                                                     model_introspection_data,
                                                     "com.canonical.Dee.Model");

      g_dbus_interface_info_ref (model_interface_info);
      g_dbus_node_info_unref (model_introspection_data);
    }

  /* Export the model on the bus */
  model_registration_id =
      g_dbus_connection_register_object (connection,
                                         priv->model_path, /* object path */
                                         model_interface_info,
                                         &model_interface_vtable,
                                         self,  /* user_data */
                                         NULL,  /* user_data_free_func */
                                         NULL); /* GError** */

  connection_info.connection = connection;
  connection_info.signal_subscription_id = dbus_signal_handler;
  connection_info.registration_id = model_registration_id;
  g_array_append_val (priv->connection_infos, connection_info);

  /* If we are swarm leaders and we have column type info we are ready by now.
   * Otherwise we will be ready when we receive the model clone from the leader
   */
  if (dee_peer_is_swarm_leader (priv->swarm))
    {
      if (dee_model_get_n_columns (DEE_MODEL (self)) > 0 && !priv->synchronized)
        {
          priv->synchronized = TRUE;
          g_object_notify (G_OBJECT (self), "synchronized");
        }
    }
  else if (dee_peer_get_swarm_leader (priv->swarm) != NULL)
    {
      /* There is a leader and it's not us.
       * Start cloning the model of the leader */

      clone_leader (self);
    }
  else
    {
      // FIXME: There's no known leader, peer should soon emit notify::swarm-leader
    }
}

static void
on_connection_closed (DeeSharedModel  *self,
                      GDBusConnection *connection,
                      DeePeer         *peer)
{
  DeeSharedModelPrivate *priv;
  guint i;

  g_return_if_fail (DEE_IS_SHARED_MODEL (self));

  priv = self->priv;

  /* Update our list of connections */
  if (priv->connections) g_slist_free (priv->connections);
  priv->connections = dee_peer_get_connections (priv->swarm);

  /* Disconnect signals etc */
  for (i = 0; i < priv->connection_infos->len; i++)
    {
      DeeConnectionInfo *info;
      info = &g_array_index (priv->connection_infos, DeeConnectionInfo, i);
      if (info->connection == connection)
        {
          g_dbus_connection_unregister_object (info->connection,
                                               info->registration_id);
          g_dbus_connection_signal_unsubscribe (info->connection,
                                                info->signal_subscription_id);
          /* remove the item */
          g_array_remove_index (priv->connection_infos, i);
          break;
        }
    }
}

/* Callback for clone_leader() */
static void
on_clone_received (GObject      *source_object,
                   GAsyncResult *res,
                   gpointer      user_data)
{
  DeeModel              *model;
  DeeSharedModel        *self;
  DeeSharedModelPrivate *priv;
  GVariant              *data, *transaction;
  GError                *error;
  GWeakRef              *weak_ref;
  gchar                 *dbus_error;

  weak_ref = (GWeakRef*) user_data;
  self = (DeeSharedModel*) g_weak_ref_get (weak_ref);
  if (self == NULL)
    {
      g_weak_ref_clear (weak_ref);
      g_free (weak_ref);
      return;
    }
  priv = self->priv;

  error = NULL;
  data = g_dbus_connection_call_finish (G_DBUS_CONNECTION (source_object),
                                        res, &error);

  if (error != NULL)
    {
      dbus_error = g_dbus_error_get_remote_error (error);
      if (g_strcmp0 (dbus_error, "com.canonical.Dee.Model.NoSchemaError") == 0)
        {
          trace_object (self, "Got Clone reply from leader, but leader has no schema");
          g_error_free (error);
          g_free (dbus_error);
        }
      else
        {
          g_critical ("Failed to clone model from leader: %s", error->message);
          g_error_free (error);
          g_free (dbus_error);
          goto clone_recieved_out;
        }
    }

  /* The data will be NULL if we received a com.canonical.Dee.Model.NoSchemaError,
   * but in that case we should still consider our selves synchronized */
  if (data != NULL)
    {
      const gchar **column_names;
      guint         i, n_column_names;
      GVariant     *vardict;
      GVariantIter *iter;

      model = DEE_MODEL (self);
      /* Guard against a race where we might inadvertedly have accepted a Commit
       * before receiving the initial Clone */
      if (dee_model_get_n_columns (model) > 0)
        {
          priv->suppress_remote_signals = TRUE;
          reset_model (model);
          priv->suppress_remote_signals = FALSE;
        }

      /* Support both the 1.0 Clone signature as well as the 1.2 */
      if (g_variant_type_equal (g_variant_get_type (data),
                                CLONE_VARIANT_TYPE))
        {
          GVariant *transaction_members[COMMIT_TUPLE_ITEMS];
          guint n_elements;

          n_elements = G_N_ELEMENTS (transaction_members);

          for (i = 0; i < n_elements; i++)
            transaction_members[i] = g_variant_get_child_value (data, i);

          transaction = g_variant_new_tuple (transaction_members, n_elements);
          transaction = g_variant_ref_sink (transaction);

          vardict = g_variant_get_child_value (data, 6);

          if (g_variant_lookup (vardict, "column-names", "^a&s", &column_names))
            n_column_names = g_strv_length ((gchar**) column_names);
          else
            column_names = NULL;
          if (!g_variant_lookup (vardict, "fields", "a(uss)", &iter))
            iter = NULL;

          for (i = 0; i < n_elements; i++)
            g_variant_unref (transaction_members[i]);
        }
      else if (g_variant_type_equal (g_variant_get_type (data),
                                     COMMIT_VARIANT_TYPE))
        {
          transaction = g_variant_ref (data);
          vardict = NULL;
        }
      else
        {
          g_critical ("Unable to Clone model: Unrecognized schema");
          goto clone_recieved_out;
        }

      /* We use the swarm name as sender_name here, because DBus passes us the
      * unique name of the swarm leader here and we want to indicate in the debug
      * messages that the transaction came from the leader */
      commit_transaction (self,
                          dee_shared_model_get_swarm_name (self),
                          transaction);

      if (vardict)
        {
          if (column_names && n_column_names > 0
              && dee_model_get_column_names (model, NULL) == NULL)
            {
              dee_model_set_column_names_full (model, column_names, n_column_names);

              if (iter != NULL)
                {
                  dee_shared_model_parse_vardict_schemas (model, iter,
                                                          n_column_names);
                  g_variant_iter_free (iter);
                }
            }
          g_free (column_names);
          g_variant_unref (vardict);
        }

      g_variant_unref (transaction);
      g_variant_unref (data);
    }

  /* If we where invalidated before, we should be fine now */
  if (!priv->synchronized)
    {
      priv->synchronized = TRUE;
      g_object_notify (G_OBJECT (self), "synchronized");
    }

clone_recieved_out:
  priv->clone_in_progress = FALSE;

  g_object_unref (self); // weak ref got us a strong reference
  g_weak_ref_clear (weak_ref);
  g_free (weak_ref);
}

/* Send a Clone message to the swarm leader */
static void
clone_leader (DeeSharedModel *self)
{
  DeeSharedModelPrivate *priv;
  GSList                *iter;

  g_return_if_fail (DEE_IS_SHARED_MODEL (self));
  g_return_if_fail (dee_peer_get_swarm_leader (self->priv->swarm) != NULL);
  g_return_if_fail (self->priv->revision_queue == NULL);
  g_return_if_fail (dee_model_get_n_rows (DEE_MODEL (self)) == 0);

  priv = self->priv;

  trace_object (self, "Cloning leader '%s'",
                dee_shared_model_get_swarm_name (self));

  /* This shouldn't really happen when we have multiple connections, but let's
   * have it here for consistency */
  for (iter = priv->connections; iter != NULL; iter = iter->next)
    {
      GWeakRef *weak_ref;
      weak_ref = g_new (GWeakRef, 1);
      g_weak_ref_init (weak_ref, self);
      g_dbus_connection_call((GDBusConnection*) iter->data,
                             dee_shared_model_get_swarm_name (self), // name
                             priv->model_path,                       // obj path
                             "com.canonical.Dee.Model",              // iface
                             "Clone",                                // member
                             NULL,                                   // args
                             NULL,                                   // ret type
                             G_DBUS_CALL_FLAGS_NONE,
                             -1,                                     // timeout
                             NULL,                                   // cancel
                             on_clone_received,                      // cb
                             weak_ref);                              // userdata

      priv->clone_in_progress = TRUE;
    }
}

static void
on_dbus_signal_received (GDBusConnection *connection,
                         const gchar     *sender_name,
                         const gchar     *object_path,
                         const gchar     *interface_name,
                         const gchar     *signal_name,
                         GVariant        *parameters,
                         gpointer         user_data)
{
  DeeSharedModel *model;
  const gchar    *unique_name;
  gboolean        forced_ignore;
  gboolean        disable_write;

  g_return_if_fail (DEE_IS_SHARED_MODEL (user_data));

  unique_name = g_dbus_connection_get_unique_name (connection);

  trace_object (user_data, "%s: sender: %s, our unique_name: %s",
      __func__, sender_name, unique_name);

  /* Ignore signals from our selves. We may get those because of the way
   * we set up the match rules */
  if (unique_name != NULL && g_strcmp0 (sender_name, unique_name) == 0)
    return;

  if (g_strcmp0 (signal_name, "Commit") == 0)
    {
      model = DEE_SHARED_MODEL (user_data);

      /* If we're waiting for Clone(), we can just ignore Commits coming
       * meanwhile, this way we'll prevent unnecessary invalidation */
      if (model->priv->clone_in_progress) return;

      /* Similarly if we receive a Commit before knowing who's the swarm leader
       * (can happen even before Clone() request, ignore the commit */
      if (model->priv->synchronized == FALSE &&
          dee_peer_get_swarm_leader (model->priv->swarm) == NULL)
        return;

      disable_write = model->priv->access_mode ==
        DEE_SHARED_MODEL_ACCESS_MODE_LEADER_WRITABLE;
      forced_ignore = dee_peer_is_swarm_leader (model->priv->swarm) &&
        disable_write;

      if (!disable_write)
        {
          commit_transaction (model, sender_name, parameters);
        }
      else if (!forced_ignore)
        {
          /* remote writes are disabled, but we're not leader - commit anyway */
          g_warning ("Tried to prevent remote write, but SharedModel[%p] is "
                     "not owned by peer named %s.",
                     model, dee_peer_get_swarm_name (model->priv->swarm));
          commit_transaction (model, sender_name, parameters);
        }

      if (forced_ignore)
        {
          /* invalidate all the peers if remote writes are disabled */
          invalidate_peer (model, sender_name, NULL);
        }
      else if (g_slist_length (model->priv->connections) > 1)
        {
          /* this is a server and a client (non-leader) just committed a change
           * to the model, let's invalidate all other clients */
          invalidate_peer (model, sender_name, connection);
        }
    }
  else
    g_warning ("Unexpected signal %s.%s from %s",
               interface_name, signal_name, sender_name);
}


static void
on_leader_changed (DeeSharedModel  *self)
{
  DeeSharedModelPrivate *priv;

  priv = self->priv;

  if (dee_shared_model_is_leader (self))
    {
      /* The leader is the authoritative data source so if we are not
       * synchronized we will now be by very definition */
      if (!priv->synchronized)
        {
          priv->synchronized = TRUE;
          g_object_notify (G_OBJECT (self), "synchronized");
        }
    }
  else
    {
      if (!priv->synchronized)
        {
          clone_leader (self);
        }
    }
}

static void
commit_transaction (DeeSharedModel *self,
                    const gchar    *sender_name,
                    GVariant       *transaction)
{
  DeeSharedModelPrivate *priv;
  GVariantIter           iter;
  GVariant              *schema, *row, **row_buf, *val, *aav, *au, *ay, *tt;
  const gchar          **column_schemas;
  gsize                  column_schemas_len;
  gchar                 *swarm_name;
  guint64                seqnum_before, seqnum_after, current_seqnum;
  guint64                n_rows, n_cols, model_n_rows;
  guint32                pos;
  guchar                 change_type;
  gint                   i, j;
  gboolean               transaction_error;

  g_return_if_fail (DEE_IS_SHARED_MODEL (self));
  g_return_if_fail (transaction != NULL);

  g_variant_ref_sink (transaction);

  priv = self->priv;
  g_variant_iter_init (&iter, transaction);

  /* The transaction should have signature '(sasaavauay(tt)'.
   * Make sure it at least looks right */
  if (g_strcmp0 (g_variant_get_type_string (transaction),  "(sasaavauay(tt))") != 0)
    {
      g_critical ("Unexpected format for Commit message '%s' from %s. "
                  "Expected '(sasaavauay(tt))'",
                  g_variant_get_type_string (transaction), sender_name);
      g_variant_unref (transaction);
      return;
    }

  /* Assert that this is a Commit for the right swarm name */
  g_variant_iter_next (&iter, "s", &swarm_name);
  if (g_strcmp0 (swarm_name, dee_peer_get_swarm_name (priv->swarm)) != 0)
    {
      g_critical ("Error in internal message routing. "
                  "Unexpected swarm name '%s' on Commit from %s."
                  "Expected '%s'",
                  swarm_name, sender_name,
                  dee_peer_get_swarm_name (priv->swarm));
      g_variant_unref (transaction);
      g_free (swarm_name);
      return;
    }

  g_free (swarm_name);
  /* If the model has no schema then use the one received in the transaction */
  schema = g_variant_iter_next_value (&iter);
  n_cols = dee_model_get_n_columns (DEE_MODEL (self));
  if (n_cols == 0)
    {
      column_schemas = g_variant_get_strv (schema, &column_schemas_len);
      if (column_schemas != NULL)
        {
          n_cols = column_schemas_len;
          dee_model_set_schema_full (DEE_MODEL(self), column_schemas, n_cols);
          g_free (column_schemas);
        }
      else
        {
          g_warning ("Received transaction before the model schema has been set"
                      " and none received from leader");
          g_variant_unref (transaction);
          g_variant_unref (schema);
          return;
        }
    }
  g_variant_unref (schema);

  /* Parse the rest of the transaction */
  aav = g_variant_iter_next_value (&iter);
  au = g_variant_iter_next_value (&iter);
  ay = g_variant_iter_next_value (&iter);
  tt = g_variant_iter_next_value (&iter);

  /* Validate that the seqnums are as we expect */
  g_variant_get (tt, "(tt)", &seqnum_before, &seqnum_after);
  g_variant_unref (tt);

  transaction_error = FALSE;
  /* If this is our first transaction we accept anything, if not the
   * incoming seqnums must align with our own records */
  current_seqnum = dee_serializable_model_get_seqnum (DEE_MODEL (self));

  if (current_seqnum != 0 && current_seqnum != seqnum_before)
    {
      g_warning ("Transaction from %s is in the %s. Expected seqnum %"G_GUINT64_FORMAT
                 ", but got %"G_GUINT64_FORMAT". Ignoring transaction.",
                 sender_name,
                 current_seqnum < seqnum_before ? "future" : "past",
                 current_seqnum, seqnum_before);
      transaction_error = TRUE;
    }

  /* Check that the lengths of all the arrays match up */
  n_rows = g_variant_n_children (aav);

  if (n_rows != g_variant_n_children (au))
    {
      g_warning ("Commit from %s has illegal position vector",
                 sender_name);
      transaction_error = TRUE;
    }
  if (n_rows != g_variant_n_children (ay))
    {
      g_warning ("Commit from %s has illegal change type vector",
                 sender_name);
      transaction_error = TRUE;
    }
  if (n_rows > (seqnum_after - seqnum_before))
    {
      g_warning ("Commit from %s has illegal seqnum count.",
                 sender_name);
      transaction_error = TRUE;
    }

  if (transaction_error)
    {
      if (dee_shared_model_is_leader (self))
        {
          g_warning ("Invalidating %s", sender_name);
          invalidate_peer (self, sender_name, NULL);
        }
      else
        {
          if (sender_name == NULL ||
              !g_strcmp0 (sender_name, dee_peer_get_swarm_leader (priv->swarm)))
            {
              // leader sent an invalid transaction?
              // let's just invalidate ourselves
              g_warning ("Errornous transaction came from swarm leader, re-syncing model.");
              on_invalidate (self);
            }
        }

      g_variant_unref (transaction);
      g_variant_unref (aav);
      g_variant_unref (au);
      g_variant_unref (ay);
      return;
    }

  /* Allocate an array on the stack as a temporary row data buffer */
  row_buf = g_alloca (n_cols * sizeof (gpointer));

  trace_object (self, "Applying transaction of %i rows", n_rows);

  /* Phew. Finally. We're ready to merge the changes */
  g_signal_emit_by_name (self, "changeset-started");
  g_signal_emit (self, _signals[BEGIN_TRANSACTION], 0, seqnum_before, seqnum_after);
  priv->suppress_remote_signals = TRUE;
  for (i = 0; i < n_rows; i++) /* Begin outer loop */
    {
      model_n_rows = dee_model_get_n_rows (DEE_MODEL (self));

      g_variant_get_child (au, i, "u", &pos);
      g_variant_get_child (ay, i, "y", &change_type);

      /* Before parsing the row data we check if it's a remove,
       * because in that case we might as well not parse the
       * row data at all */
      if (change_type == CHANGE_TYPE_REMOVE)
        {
          dee_model_remove (DEE_MODEL (self),
                            dee_model_get_iter_at_row (DEE_MODEL (self), pos));
          model_n_rows--;
          continue;
        }

      if (change_type == CHANGE_TYPE_CLEAR)
        {
          dee_model_clear (DEE_MODEL (self));
          model_n_rows = 0;
          continue;
        }

      /* It's an Add or Change so parse the row data */
      row = g_variant_get_child_value (aav, i);

      /* Add and Change rows must have the correct number of columns */
      if (g_variant_n_children (row) != n_cols)
        {
          g_critical ("Commit from %s contains rows of illegal length. "
                      "The model may have been left in a dirty state",
                      sender_name);
          /* cleanup */
          g_variant_unref (row);
          continue;
        }

      /* Read the row cells into our stack allocated row buffer.
       * Note that g_variant_get_child_value() returns a strong ref,
       * not a floating one */
      for (j = 0; j < n_cols; j++)
        {
          val = g_variant_get_child_value (row, j); // val is now a 'v'
          row_buf[j] = g_variant_get_child_value (val, 0); // unbox the 'v'
          g_variant_unref (val);
        }

      if (change_type == CHANGE_TYPE_ADD)
        {
          if (pos == 0)
            dee_model_prepend_row (DEE_MODEL (self), row_buf);
          else if (pos >= model_n_rows)
            dee_model_append_row (DEE_MODEL (self), row_buf);
          else if (pos < model_n_rows)
            dee_model_insert_row (DEE_MODEL (self), pos, row_buf);

        }
      else if (change_type == CHANGE_TYPE_CHANGE)
        {
          dee_model_set_row (DEE_MODEL (self),
                             dee_model_get_iter_at_row (DEE_MODEL (self), pos),
                             row_buf);
        }
      else
        {
          g_critical ("Unknown change type %i from %s. The model may have "
                      "been left in a dirty state", change_type, sender_name);
          // FIXME: continue looping or bail out?
        }

      /* Free the variants in the row_buf. */
      for (j = 0; j < n_cols; j++)
        g_variant_unref (row_buf[j]);

      g_variant_unref (row);
    } /* End outer loop */
  priv->suppress_remote_signals = FALSE;

  g_variant_unref (transaction);
  g_variant_unref (aav);
  g_variant_unref (au);
  g_variant_unref (ay);

  /* We must manually override the seqnum in case we started off from
   * zero our selves, but the transaction was a later snapshot */
  dee_serializable_model_set_seqnum (DEE_MODEL (self), seqnum_after);

  priv->last_committed_seqnum = seqnum_after;

  g_signal_emit (self, _signals[END_TRANSACTION], 0, seqnum_before, seqnum_after);
  g_signal_emit_by_name (self, "changeset-finished");
}

static void
on_self_row_added (DeeModel *self, DeeModelIter *iter)
{
  DeeSharedModelPrivate *priv;
  gsize                  row_slice_size;
  guint32                pos;
  GVariant             **row;

  priv = DEE_SHARED_MODEL (self)->priv;

  if (!priv->suppress_remote_signals)
    {
      row_slice_size = dee_model_get_n_columns(self) * sizeof (gpointer);
      row = g_slice_alloc (row_slice_size);

      pos = dee_model_get_position (self, iter);
      enqueue_revision (self,
                        CHANGE_TYPE_ADD,
                        pos,
                        dee_serializable_model_get_seqnum (self),
                        dee_model_get_row (self, iter, row));
    }
}

static void
on_self_row_removed (DeeModel *self, DeeModelIter *iter)
{
  DeeSharedModelPrivate *priv;
  guint32 pos;

  priv = DEE_SHARED_MODEL (self)->priv;

  if (!priv->suppress_remote_signals)
    {
      pos = dee_model_get_position (self, iter);
      enqueue_revision (self,
                        CHANGE_TYPE_REMOVE,
                        pos,
                        dee_serializable_model_get_seqnum (self),
                        NULL);
    }
}

static void
on_self_row_changed (DeeModel *self, DeeModelIter *iter)
{
  DeeSharedModelPrivate *priv;
  guint32                pos;
  gsize                  row_slice_size;
  GVariant             **row;

  priv = DEE_SHARED_MODEL (self)->priv;

  if (!priv->suppress_remote_signals)
    {
      row_slice_size = dee_model_get_n_columns(self) * sizeof (gpointer);
      row = g_slice_alloc (row_slice_size);

      pos = dee_model_get_position (self, iter);
      enqueue_revision (self,
                        CHANGE_TYPE_CHANGE,
                        pos,
                        dee_serializable_model_get_seqnum (self),
                        dee_model_get_row (self, iter, row));
    }
}

/* Clears all data in the model and resets it to start from scratch */
static void
reset_model (DeeModel *self)
{
  g_return_if_fail (DEE_IS_SHARED_MODEL (self));

  /* Make sure we don't have any buffered signals awaiting emission */
  flush_revision_queue (self);

  /* Emit 'removed' on all rows and free old row data */
  dee_model_clear (self);

  dee_serializable_model_set_seqnum (self, 0);
}

/* Call DBus method com.canonical.Dee.Model.Invalidate() on @sender_name */
static void
invalidate_peer (DeeSharedModel  *self,
                 const gchar     *sender_name,
                 GDBusConnection *except)
{
  DeeSharedModelPrivate *priv;
  GSList                *iter;

  g_return_if_fail (DEE_IS_SHARED_MODEL (self));

  if (!dee_shared_model_is_leader (self))
    {
      g_critical ("Internal error in DeeSharedModel. "
                  "Non-leader model tried to invalidate a peer");
      return;
    }

  priv = self->priv;

  // invalidate peers on all connections
  for (iter = priv->connections; iter != NULL; iter = iter->next)
    {
      if (iter->data == except) continue;
      g_dbus_connection_call ((GDBusConnection*) iter->data,
                              sender_name,
                              priv->model_path,
                              "com.canonical.Dee.Model",
                              "Invalidate",
                              NULL,                      /* params */
                              NULL,                      /* reply type */
                              G_DBUS_CALL_FLAGS_NONE,
                              -1,                        /* timeout */
                              NULL,                      /* cancel */
                              NULL,                      /* cb */
                              NULL);                     /* user data */
    }
}

/* Public Methods */

GType dee_shared_model_access_mode_get_type (void)
{
  static GType shared_model_access_mode_type = 0;
  if (shared_model_access_mode_type == 0)
    {
      static const GEnumValue values[] =
      {
        {
          DEE_SHARED_MODEL_ACCESS_MODE_WORLD_WRITABLE,
          "DEE_SHARED_MODEL_ACCESS_MODE_WORLD_WRITABLE",
          "world-writable"
        },
        {
          DEE_SHARED_MODEL_ACCESS_MODE_LEADER_WRITABLE,
          "DEE_SHARED_MODEL_ACCESS_MODE_LEADER_WRITABLE",
          "leader-writable"
        },
        {
          0, NULL, NULL
        }
      };
      shared_model_access_mode_type =
        g_enum_register_static ("DeeSharedModelAccessMode", values);
    }

  return shared_model_access_mode_type;
}

GType dee_shared_model_flush_mode_get_type (void)
{
  static GType shared_model_flush_mode_type = 0;
  if (shared_model_flush_mode_type == 0)
    {
      static const GEnumValue values[] =
      {
        {
          DEE_SHARED_MODEL_FLUSH_MODE_AUTOMATIC,
          "DEE_SHARED_MODEL_FLUSH_MODE_AUTOMATIC",
          "automatic"
        },
        {
          DEE_SHARED_MODEL_FLUSH_MODE_MANUAL,
          "DEE_SHARED_MODEL_FLUSH_MODE_MANUAL",
          "manual"
        },
        {
          0, NULL, NULL
        }
      };
      shared_model_flush_mode_type =
        g_enum_register_static ("DeeSharedModelFlushMode", values);
    }

  return shared_model_flush_mode_type;
}

/**
 * dee_shared_model_new:
 * @name: A well known name to publish this model under. Models sharing this name
 *        will synchronize with each other
 *
 * Create a new empty shared model without any column schema associated.
 * The column schema will be set in one of two ways: firstly you may set it
 * manually with dee_model_set_schema() or secondly it will be set once
 * the first rows are exchanged with a peer model.
 *
 * A #DeeSharedModel with a schema manually set has to be created before
 * creating more #DeeSharedModel with the same @name.
 *
 * A shared model created with this constructor will store row data in a
 * suitably picked memory backed model.
 *
 * Return value: (transfer full) (type DeeSharedModel): a new #DeeSharedModel
 */
DeeModel*
dee_shared_model_new (const gchar *name)
{
  DeeModel *self;

  g_return_val_if_fail (name != NULL, NULL);

  self = dee_shared_model_new_with_back_end(name,
                                            dee_sequence_model_new ());

  return self;
}

/**
 * dee_shared_model_new_for_peer:
 * @peer: (transfer full): A #DeePeer instance.
 *
 * Create a new empty shared model without any column schema associated.
 * The column schema will be set in one of two ways: firstly you may set it
 * manually with dee_model_set_schema() or secondly it will be set once
 * the first rows are exchanged with a peer model.
 *
 * A #DeeSharedModel with a schema manually set has to be created before
 * creating more #DeeSharedModel with the same @name.
 *
 * A shared model created with this constructor will store row data in a
 * suitably picked memory backed model.
 *
 * Return value: (transfer full) (type DeeSharedModel): a new #DeeSharedModel
 */
DeeModel*
dee_shared_model_new_for_peer (DeePeer *peer)
{
  DeeModel *self;
  DeeModel *back_end;

  g_return_val_if_fail (peer != NULL, NULL);

  back_end = (DeeModel*) dee_sequence_model_new ();

  self = g_object_new (DEE_TYPE_SHARED_MODEL,
                       "back-end", back_end,
                       "peer", peer,
                       NULL);

  g_object_unref (back_end);
  g_object_unref (peer);

  return self;
}

/**
 * dee_shared_model_new_with_back_end:
 * @name: (transfer none): A well known name to publish this model under.
 *        Models sharing this name will synchronize with each other
 * @back_end: (transfer full): The #DeeModel that will actually store
 *            the model data. Ownership of the ref to @back_end is transfered to
 *            the shared model.
 *
 * Create a new shared model storing all data in @back_end.
 *
 * The model will start synchronizing with peer models as soon as possible and
 * the #DeeSharedModel:synchronized property will be set once finished.
 *
 * Return value: (transfer full) (type DeeSharedModel): a new #DeeSharedModel
 */
DeeModel*
dee_shared_model_new_with_back_end (const gchar *name, DeeModel *back_end)
{
  DeeModel *self;
  DeePeer  *swarm;

  g_return_val_if_fail (name != NULL, NULL);

  swarm = g_object_new (DEE_TYPE_PEER,
                        "swarm-name", name,
                        NULL);

  self = g_object_new (DEE_TYPE_SHARED_MODEL,
                       "back-end", back_end,
                       "peer", swarm,
                       NULL);

  g_object_unref (back_end);
  g_object_unref (swarm);

  return self;
}

/**
 * dee_shared_model_get_swarm_name:
 * @self: The model to get the name for
 *
 * Convenience function for accessing the #DeePeer:swarm-name property of the
 * #DeePeer defined in the #DeeSharedModel:peer property.
 *
 * Returns: The name of the swarm this model synchrnonizes with
 */
const gchar*
dee_shared_model_get_swarm_name (DeeSharedModel *self)
{
  DeeSharedModelPrivate *priv;

  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self), NULL);

  priv = self->priv;
  return dee_peer_get_swarm_name (priv->swarm);
}

/**
 * dee_shared_model_get_peer:
 * @self: The model to get the #DeePeer for
 *
 * Convenience function for accessing the #DeeSharedModel:peer property
 *
 * Returns: (transfer none): The #DeePeer used to interact with the peer models
 */
DeePeer*
dee_shared_model_get_peer (DeeSharedModel *self)
{
  DeeSharedModelPrivate *priv;

  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self), NULL);

  priv = self->priv;
  return priv->swarm;
}

/**
 * dee_shared_model_get_flush_mode:
 * @self: A #DeeSharedModel
 *
 * Convenience function for accessing the #DeeSharedModel:flush-mode property.
 *
 * Returns: (transfer none): The #DeeSharedModelFlushMode used by the model
 */
DeeSharedModelFlushMode
dee_shared_model_get_flush_mode (DeeSharedModel *self)
{
  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self),
                        DEE_SHARED_MODEL_FLUSH_MODE_MANUAL);

  return self->priv->flush_mode;
}

/**
 * dee_shared_model_set_flush_mode:
 * @self: A #DeeSharedModel
 * @mode: Flush mode to use
 *
 * Convenience function for setting the #DeeSharedModel:flush-mode property.
 */
void
dee_shared_model_set_flush_mode (DeeSharedModel *self,
                                 DeeSharedModelFlushMode mode)
{
  g_return_if_fail (DEE_IS_SHARED_MODEL (self));

  g_object_set (self, "flush-mode", mode, NULL);
}

/**
 * dee_shared_model_is_leader:
 * @self: The model to inspect
 *
 * Check if the model is the swarm leader. This is a convenience function for
 * accessing the #DeeSharedModel:peer property and checking if it's the swarm
 * leader.
 *
 * Returns: The value of dee_peer_is_swarm_leader() for the #DeePeer used by
 *          this shared model
 */
gboolean
dee_shared_model_is_leader (DeeSharedModel *self)
{
  DeeSharedModelPrivate *priv;

  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self), FALSE);

  priv = self->priv;
  return dee_peer_is_swarm_leader (priv->swarm);
}

/**
 * dee_shared_model_is_synchronized:
 * @self: The model to inspect
 *
 * Check if the model is synchronized with its peers. Before modifying a
 * shared model in any way (except dee_model_set_schema()) you should wait for
 * it to become synchronized. This is normally done by waiting for the
 * &quot;notify::synchronized&quot; signal.
 *
 * This method is purely a convenience function for accessing the
 * #DeeSharedModel:synchronized property.
 *
 * Returns: The value of the :synchronized property
 */
gboolean
dee_shared_model_is_synchronized (DeeSharedModel *self)
{
  DeeSharedModelPrivate *priv;

  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self), FALSE);

  priv = self->priv;
  return priv->synchronized;
}

/**
 * dee_shared_model_flush_revision_queue:
 * @self: The shared model to flush the revision queue on
 *
 * Expert: All changes to @self that has not yet been propagated to the peer
 * models are send. If you also want to block the mainloop until
 * all the underlying transport streams have been flushed use
 * dee_shared_model_flush_revision_queue_sync().
 *
 * Normally #DeeSharedModel collects changes to @self into batches and sends
 * them automatically to all peers. You can use this call to provide fine
 * grained control of exactly when changes to @self are synchronized to its
 * peers. This may for example be useful to improve the interactivity of your
 * application if you have a model-process which intermix small and light
 * changes with big and expensive changes. Using this call you can make sure
 * the model-process dispatches small changes more aggresively to the
 * view-process, while holding on to the expensive changes a bit longer.
 *
 * Return value: The number of revisions flushed.
 */
guint
dee_shared_model_flush_revision_queue (DeeSharedModel *self)
{
  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self), 0);

  return flush_revision_queue (DEE_MODEL (self));
}

/**
 * dee_shared_model_flush_revision_queue_sync:
 * @self: The shared model to flush the revision queue on
 *
 * Similar to dee_shared_model_flush_revision_queue(), but also blocks
 * the mainloop until all the underlying transport streams have been flushed.
 *
 * <emphasis>Important</emphasis>: This method <emphasis>may</emphasis> flush
 * your internal queue of DBus messages forcing them to be send before this call
 * returns.
 *
 * Return value: The number of revisions flushed.
 */
guint
dee_shared_model_flush_revision_queue_sync (DeeSharedModel *self)
{
  DeeSharedModelPrivate *priv;
  GError                *error;
  GSList                *iter;
  guint                  n_revisions;

  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self), 0);

  n_revisions = dee_shared_model_flush_revision_queue (self);
  priv = self->priv;

  for (iter = priv->connections; iter != NULL; iter = iter->next)
    {
      error = NULL;
      g_dbus_connection_flush_sync ((GDBusConnection*) iter->data, NULL, &error);
      if (error)
        {
          g_critical ("Error when flushing %u revisions of %s@%p: %s",
                      n_revisions, G_OBJECT_TYPE_NAME (self), self,
                      error->message);
          g_error_free (error);
          // continue, other connections may be working fine
        }
    }

  return n_revisions;
}

static void
dee_shared_model_clear (DeeModel *model)
{
  DeeSharedModel        *self;
  DeeSharedModelPrivate *priv;
  DeeModel              *backend;
  gboolean               was_suppressing;
  guint64                seqnum;
  guint                  n_rows;

  self = DEE_SHARED_MODEL (model);
  priv = self->priv;

  g_object_get (self, "back-end", &backend, NULL);

  was_suppressing = priv->suppress_remote_signals;
  seqnum = dee_serializable_model_get_seqnum (model);
  n_rows = dee_model_get_n_rows (model);

  if (!was_suppressing && n_rows > 0)
    {
      seqnum += n_rows;
      enqueue_revision (model,
                        CHANGE_TYPE_CLEAR,
                        0,
                        seqnum,
                        NULL);
    }
  /* make sure we don't enqueue lots of CHANGE_TYPE_REMOVE */
  priv->suppress_remote_signals = TRUE;

  /* Chain up to parent class impl. This handles the seqnums for us and the
   * backend alike. We just hook in before it, really, to player clever
   * tricks with the revision queue (inserting a CLEAR and not N*REMOVE) */
  ((DeeModelIface*) g_type_interface_peek_parent (DEE_MODEL_GET_IFACE(model)))->clear (model);

  priv->suppress_remote_signals = was_suppressing;

  g_object_unref (backend);
}

/*
 * Dbus Methods
 */


/* Build a '(sasaavauay(tt))' suitable for sending in a Clone response */
static GVariant*
dee_shared_model_serialize (DeeSerializable *self)
{
  DeeSerializableIface   *serializable_model_iface;
  DeeModel               *_self;
  GVariantBuilder         au, ay, clone;
  GVariant               *schema, *aav, *tt, *hints, *serialized_model;
  guint                   i, n_rows;
  guint64                 last_seqnum;

  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self), NULL);

  serializable_model_iface = (DeeSerializableIface*)
    g_type_interface_peek_parent (DEE_SERIALIZABLE_GET_IFACE (self));

  serialized_model = serializable_model_iface->serialize (self);
  if (g_variant_is_floating (serialized_model))
    serialized_model = g_variant_ref_sink (serialized_model);

  g_return_val_if_fail (
      g_strcmp0 (g_variant_get_type_string (serialized_model),
                 "(asaav(tt)a{sv})") == 0, NULL);

  /* Expecting "(asaav(tt)a{sv})"
   *             ^ schema
   *               ^ row_data
   *                  ^ seqnums
   *                      ^ hints
   *
   * Now we'll transform this into our own schema "(sasaavauay(tt)a{sv})".
   */

  _self = DEE_MODEL (self);
  n_rows = dee_model_get_n_rows (_self);

  g_variant_builder_init (&au, G_VARIANT_TYPE ("au"));
  g_variant_builder_init (&ay, G_VARIANT_TYPE ("ay"));

  /* Clone the rows */
  for (i = 0; i < n_rows; i++)
    {
      g_variant_builder_add (&au, "u", i);
      g_variant_builder_add (&ay, "y", (guchar) CHANGE_TYPE_ADD);
    }

  schema = g_variant_get_child_value (serialized_model, 0);
  aav = g_variant_get_child_value (serialized_model, 1);
  hints = g_variant_get_child_value (serialized_model, 3);

  /* Collect the seqnums */
  last_seqnum = dee_serializable_model_get_seqnum (_self);
  tt = g_variant_new ("(tt)", last_seqnum - i, last_seqnum);//  FIXME last_committed_seqnum

  g_variant_builder_init (&clone, CLONE_VARIANT_TYPE);
  g_variant_builder_add (&clone, "s",
      dee_shared_model_get_swarm_name (DEE_SHARED_MODEL (self)));
  g_variant_builder_add_value (&clone, schema);
  g_variant_builder_add_value (&clone, aav);
  g_variant_builder_add_value (&clone, g_variant_builder_end (&au));
  g_variant_builder_add_value (&clone, g_variant_builder_end (&ay));
  g_variant_builder_add_value (&clone, tt);
  g_variant_builder_add_value (&clone, hints);

  trace_object (self, "Serialized %u rows. "
                "Seqnum range %"G_GUINT64_FORMAT"-%"G_GUINT64_FORMAT,
                i, last_seqnum - i, last_seqnum);

  g_variant_unref (schema);
  g_variant_unref (aav);
  g_variant_unref (hints);
  g_variant_unref (serialized_model);

  return g_variant_builder_end (&clone);
}

/* Handle an incoming Invalidate() message */
static gboolean
on_invalidate (DeeSharedModel   *self)
{
  DeeSharedModelPrivate *priv;

  g_return_val_if_fail (DEE_IS_SHARED_MODEL (self), FALSE);

  priv = self->priv;

  if (dee_peer_is_swarm_leader (priv->swarm))
    {
      g_warning ("Refusing to invalidate swarm leader");
      return FALSE;
    }

  trace_object (self, "Model invalidated");

  priv->synchronized = FALSE;
  priv->suppress_remote_signals = TRUE;
  reset_model (DEE_MODEL (self));
  clone_leader (self);
  priv->suppress_remote_signals = FALSE;

  return TRUE;
}

static void
dee_shared_model_parse_vardict_schemas (DeeModel *model,
                                        GVariantIter *iter,
                                        guint n_cols)
{
  GHashTable **vardict_schemas;
  gchar *field_name, *field_schema;
  guint column_index;

  vardict_schemas = g_alloca (n_cols * sizeof (GHashTable*));
  memset (vardict_schemas, 0, n_cols * sizeof (GHashTable*));

  while (g_variant_iter_next (iter, "(uss)",
                              &column_index, &field_name, &field_schema))
    {
      if (vardict_schemas[column_index] == NULL)
        {
          vardict_schemas[column_index] = g_hash_table_new_full (
              g_str_hash, g_str_equal, g_free, g_free);
        }

      // using g_variant_iter_next, so we own field_name & schema
      g_hash_table_insert (vardict_schemas[column_index],
                           field_name, field_schema);
    }
  for (column_index = 0; column_index < n_cols; column_index++)
    {
      if (vardict_schemas[column_index] == NULL) continue;
      dee_model_register_vardict_schema (model, column_index,
                                         vardict_schemas[column_index]);
      g_hash_table_unref (vardict_schemas[column_index]);
    }
}

static GObject*
dee_shared_model_parse_serialized (GVariant *data)
{
  DeeModel       *self;
  GVariant       *transaction, *vardict;
  GVariantIter   *vardict_schema_iter;
  const gchar   **column_names;
  gchar          *swarm_name;
  guint           i, n_cols;
  gsize           tuple_items;

  g_return_val_if_fail (data != NULL, NULL);

  // FIXME: this method doesn't consider DeePeer subclasses and naively uses
  // dee_shared_model_new() which in turn uses dee_peer_new(), if the model
  // was created with a DeeServer / DeeClient, it won't be possible to
  // deserialize the model into the original state

  tuple_items = g_variant_n_children (data);
  if (tuple_items == COMMIT_TUPLE_ITEMS) /* "(sasaavauay(tt))" */
    {
      transaction = g_variant_ref (data);
      vardict = NULL;
    }
  else if (tuple_items == CLONE_TUPLE_ITEMS) /* "(sasaavauay(tt)a{sv})" */
    {
      GVariant *transaction_members[COMMIT_TUPLE_ITEMS];
      guint n_elements;

      n_elements = G_N_ELEMENTS (transaction_members);

      for (i = 0; i < n_elements; i++)
        transaction_members[i] = g_variant_get_child_value (data, i);

      transaction = g_variant_new_tuple (transaction_members, n_elements);
      transaction = g_variant_ref_sink (transaction);

      vardict = g_variant_get_child_value (data, 6);
      if (!g_variant_lookup (vardict, "column-names", "^a&s", &column_names))
        column_names = NULL;
      if (!g_variant_lookup (vardict, "fields", "a(uss)", &vardict_schema_iter))
        vardict_schema_iter = NULL;

      for (i = 0; i < n_elements; i++)
        g_variant_unref (transaction_members[i]);
    }
  else
    {
      g_critical ("Unable to deserialize model: Unrecognized schema");
      return NULL;
    }

  g_variant_get_child (transaction, 0, "&s", &swarm_name);

  self = dee_shared_model_new (swarm_name);
  commit_transaction (DEE_SHARED_MODEL (self), swarm_name, transaction);

  if (vardict)
    {
      if (column_names)
        {
          n_cols = g_strv_length ((gchar**) column_names);
          if (n_cols > 0)
            dee_model_set_column_names_full (self, column_names, n_cols);
        }

      if (vardict_schema_iter != NULL)
        {
          dee_shared_model_parse_vardict_schemas (self, vardict_schema_iter, n_cols);
          g_variant_iter_free (vardict_schema_iter);
        }

      g_free (column_names);
      g_variant_unref (vardict);
    }

  g_variant_unref (transaction);

  return (GObject *) self;
}

static void
dee_shared_model_serializable_iface_init (DeeSerializableIface *iface)
{
  iface->serialize      = dee_shared_model_serialize;

  dee_serializable_register_parser (DEE_TYPE_SHARED_MODEL,
                                    COMMIT_VARIANT_TYPE,
                                    dee_shared_model_parse_serialized);
  dee_serializable_register_parser (DEE_TYPE_SHARED_MODEL,
                                    CLONE_VARIANT_TYPE,
                                    dee_shared_model_parse_serialized);
}

static void
dee_shared_model_model_iface_init (DeeModelIface *iface)
{
  DeeModelIface *proxy_model_iface;

  proxy_model_iface = (DeeModelIface*) g_type_interface_peek_parent (iface);

  /* we just need to override clear, but gobject is making this difficult */
  iface->set_schema_full      = proxy_model_iface->set_schema_full;
  iface->get_schema           = proxy_model_iface->get_schema;
  iface->get_column_schema    = proxy_model_iface->get_column_schema;
  iface->get_n_columns        = proxy_model_iface->get_n_columns;
  iface->get_n_rows           = proxy_model_iface->get_n_rows;
  iface->prepend_row          = proxy_model_iface->prepend_row;
  iface->append_row           = proxy_model_iface->append_row;
  iface->insert_row           = proxy_model_iface->insert_row;
  iface->insert_row_before    = proxy_model_iface->insert_row_before;
  iface->remove               = proxy_model_iface->remove;
  iface->set_value            = proxy_model_iface->set_value;
  iface->set_row              = proxy_model_iface->set_row;
  iface->get_value            = proxy_model_iface->get_value;
  iface->get_first_iter       = proxy_model_iface->get_first_iter;
  iface->get_last_iter        = proxy_model_iface->get_last_iter;
  iface->get_iter_at_row      = proxy_model_iface->get_iter_at_row;
  iface->get_bool             = proxy_model_iface->get_bool;
  iface->get_uchar            = proxy_model_iface->get_uchar;
  iface->get_int32            = proxy_model_iface->get_int32;
  iface->get_uint32           = proxy_model_iface->get_uint32;
  iface->get_int64            = proxy_model_iface->get_int64;
  iface->get_uint64           = proxy_model_iface->get_uint64;
  iface->get_double           = proxy_model_iface->get_double;
  iface->get_string           = proxy_model_iface->get_string;
  iface->next                 = proxy_model_iface->next;
  iface->prev                 = proxy_model_iface->prev;
  iface->is_first             = proxy_model_iface->is_first;
  iface->is_last              = proxy_model_iface->is_last;
  iface->get_position         = proxy_model_iface->get_position;
  iface->register_tag         = proxy_model_iface->register_tag;
  iface->get_tag              = proxy_model_iface->get_tag;
  iface->set_tag              = proxy_model_iface->set_tag;

  iface->clear                = dee_shared_model_clear;
}

