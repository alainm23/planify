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
 * Authored by:
 *               Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

/**
 * SECTION:dee-filter-model
 * @short_description: A #DeeModel that contains a filtered subset of
 *                     another #DeeModel
 * @include: dee.h
 *
 * A #DeeFilterModel should be regarded as a view on a specific subset of
 * of another #DeeModel, filtered according to a given "filtering rule".
 *
 * Filter models re-use the #DeeModelIter<!-- -->s of the back end model they
 * filter. This means that any iter from the filter model can be used directly
 * on the back end model. This is a powerful invariant, but implies the
 * restriction that a row in the filter model contains the exact same data
 * as the corresponding row in the back end model (ie. you can not apply
 * a "transfomation map" to the filtered data).
 *
 * The reuse of row iters also minimizes the amount of memory shuffling needed
 * to set up a filter model. The filtering functions, #DeeFilterMapFunc and
 * #DeeFilterMapNotify, has also been designed to minimize the amount of work
 * done to create a filter model. So if the filter functions are written
 * optimally the resulting filter models should be cheap to construct.
 *
 * Another important feature of the filter model is also that the rows 
 * need not be in the same order as the original rows in the back end model.
 *
 * There is a suite of filters shipped with Dee which you can browse in the
 * <link linkend="dee-1.0-Filters.top_of_page">Filters section</link>.
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h> // memcpy()

#include "dee-peer.h"
#include "dee-model.h"
#include "dee-filter.h"
#include "dee-proxy-model.h"
#include "dee-filter-model.h"
#include "dee-serializable-model.h"
#include "dee-sequence-model.h"
#include "dee-marshal.h"
#include "trace-log.h"

static void dee_filter_model_model_iface_init (DeeModelIface *iface);

G_DEFINE_TYPE_WITH_CODE (DeeFilterModel,
                         dee_filter_model,
                         DEE_TYPE_PROXY_MODEL,
                         G_IMPLEMENT_INTERFACE (DEE_TYPE_MODEL,
                                                dee_filter_model_model_iface_init));

#define DEE_FILTER_MODEL_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_FILTER_MODEL, DeeFilterModelPrivate))

/**
 * DeeFilterModelPrivate:
 *
 * Ignore this structure.
 **/
struct _DeeFilterModelPrivate
{
  DeeFilter  *filter;
  DeeModel   *orig_model;

  /* Map of orig_model iters to our own internal GSequenceIters for iter_list */
  GHashTable *iter_map;
  
  /* Sequence use to keep track of the sorting of iters from iter_map  */
  GSequence  *iter_list;
  
  /* When TRUE signals from orig_model will not be forwarded or checked
   * via the filter->map_notify function */
  gboolean    ignore_orig_signals;
  
  gulong      on_orig_row_added_id;
  gulong      on_orig_row_removed_id;
  gulong      on_orig_row_changed_id;
  gulong      on_orig_changeset_started_id;
  gulong      on_orig_changeset_finished_id;
};

enum
{
  PROP_0,
  PROP_FILTER,
};

/*
 * DeeModel forward declarations
 */
static void           dee_filter_model_set_schema_full  (DeeModel           *self,
                                                         const gchar* const *schema,
                                                         guint               n_columns);

static guint          dee_filter_model_get_n_rows     (DeeModel *self);

static DeeModelIter*  dee_filter_model_append_row  (DeeModel  *self,
                                                    GVariant **row_members);

static DeeModelIter*  dee_filter_model_prepend_row (DeeModel *self,
                                                    GVariant **row_members);

static DeeModelIter*  dee_filter_model_insert_row_before (DeeModel     *self,
                                                          DeeModelIter *iter,
                                                          GVariant **row_members);

static DeeModelIter* dee_filter_model_find_row_sorted (DeeModel           *self,
                                                       GVariant          **row_spec,
                                                       DeeCompareRowFunc   cmp_func,
                                                       gpointer            user_data,
                                                       gboolean           *out_was_found);

static void           dee_filter_model_remove         (DeeModel     *self,
                                                       DeeModelIter *iter);

static DeeModelIter* dee_filter_model_get_first_iter  (DeeModel     *self);

static DeeModelIter* dee_filter_model_get_iter_at_row (DeeModel     *self,
                                                       guint          row);

static DeeModelIter* dee_filter_model_next            (DeeModel     *self,
                                                       DeeModelIter *iter);

static DeeModelIter* dee_filter_model_prev            (DeeModel     *self,
                                                       DeeModelIter *iter);

static gboolean      dee_filter_model_is_first        (DeeModel     *self,
                                                       DeeModelIter *iter);

static guint         dee_filter_model_get_position    (DeeModel     *self,
                                                       DeeModelIter *iter);

/* Private forward declarations */
static gboolean    dee_filter_model_is_empty     (DeeModel       *self);

static void        on_orig_model_row_added       (DeeFilterModel *self,
                                                  DeeModelIter   *iter);

static void        on_orig_model_row_removed     (DeeFilterModel *self,
                                                  DeeModelIter   *iter);

static void        on_orig_model_row_changed     (DeeFilterModel *self,
                                                  DeeModelIter   *iter);

static void        on_orig_model_changeset_started  (DeeFilterModel *self,
                                                     DeeModel       *iter);

static void        on_orig_model_changeset_finished (DeeFilterModel *self,
                                                     DeeModel       *iter);

/* GObject stuff */
static void
dee_filter_model_finalize (GObject *object)
{
  DeeFilterModelPrivate *priv = DEE_FILTER_MODEL (object)->priv;

  if (priv->filter)
    {
      dee_filter_destroy (priv->filter);
      g_free (priv->filter);
      priv->filter = NULL;
    }
  
  if (priv->iter_map)
    {
      g_hash_table_destroy (priv->iter_map);
      priv->iter_map = NULL;
    }
  if (priv->iter_list)
    {
      g_sequence_free (priv->iter_list);
      priv->iter_list = NULL;
    }
  
  if (priv->on_orig_row_added_id != 0)
    g_signal_handler_disconnect (priv->orig_model, priv->on_orig_row_added_id);
  if (priv->on_orig_row_removed_id != 0)
    g_signal_handler_disconnect (priv->orig_model, priv->on_orig_row_removed_id);
  if (priv->on_orig_row_changed_id != 0)
    g_signal_handler_disconnect (priv->orig_model, priv->on_orig_row_changed_id);
  if (priv->on_orig_changeset_started_id != 0)
    g_signal_handler_disconnect (priv->orig_model, priv->on_orig_changeset_started_id);
  if (priv->on_orig_changeset_finished_id != 0)
    g_signal_handler_disconnect (priv->orig_model, priv->on_orig_changeset_finished_id);

  priv->on_orig_row_added_id = 0;
  priv->on_orig_row_removed_id = 0;
  priv->on_orig_row_changed_id = 0;
  priv->on_orig_changeset_started_id = 0;
  priv->on_orig_changeset_finished_id = 0;

  if (priv->orig_model)
    {
      g_object_unref (priv->orig_model);
      priv->orig_model = NULL;
    }

  G_OBJECT_CLASS (dee_filter_model_parent_class)->finalize (object);
}

static void
dee_filter_model_constructed (GObject *object)
{
  DeeFilterModelPrivate *priv = DEE_FILTER_MODEL (object)->priv;
  
  if (priv->filter == NULL)
    {
      g_critical ("You must set the 'filter' property when "
                  "creating a DeeFilterModel");
      return;
    }
 
  /* This will return a new reference on back-end */
  g_object_get (object, "back-end", &(priv->orig_model), NULL);
  
  /* Map the end iter of the orig_model to the end iter of our iter list */
  g_hash_table_insert (priv->iter_map,
                       dee_model_get_last_iter (priv->orig_model),
                       g_sequence_get_end_iter (priv->iter_list));
  
  /* Apply filter to orig_model in order to fill this model */
  dee_filter_map (priv->filter, priv->orig_model, DEE_FILTER_MODEL (object));
  
  /* Listen for changes to orig_model */
  priv->on_orig_row_added_id =
    g_signal_connect_swapped (priv->orig_model, "row-added",
                              G_CALLBACK (on_orig_model_row_added), object);

  priv->on_orig_row_removed_id =
    g_signal_connect_swapped (priv->orig_model, "row-removed",
                              G_CALLBACK (on_orig_model_row_removed), object);

  priv->on_orig_row_changed_id =
    g_signal_connect_swapped (priv->orig_model, "row-changed",
                              G_CALLBACK (on_orig_model_row_changed), object);

  priv->on_orig_changeset_started_id =
    g_signal_connect_swapped (priv->orig_model, "changeset-started",
                              G_CALLBACK (on_orig_model_changeset_started),
                              object);

  priv->on_orig_changeset_finished_id =
    g_signal_connect_swapped (priv->orig_model, "changeset-finished",
                              G_CALLBACK (on_orig_model_changeset_finished),
                              object);

  if (G_OBJECT_CLASS (dee_filter_model_parent_class)->constructed)
    G_OBJECT_CLASS (dee_filter_model_parent_class)->constructed (object);
}

static void
dee_filter_model_set_property (GObject       *object,
                               guint          id,
                               const GValue  *value,
                               GParamSpec    *pspec)
{
  DeeFilterModelPrivate *priv = DEE_FILTER_MODEL (object)->priv;
  

  switch (id)
    {
    case PROP_FILTER:
      priv->filter = g_new0 (DeeFilter, 1);
      memcpy (priv->filter, g_value_get_pointer (value), sizeof (DeeFilter));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_filter_model_get_property (GObject     *object,
                               guint        id,
                               GValue      *value,
                               GParamSpec  *pspec)
{
  switch (id)
    {
    case PROP_FILTER:
      g_value_set_pointer (value, DEE_FILTER_MODEL (object)->priv->filter);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_filter_model_class_init (DeeFilterModelClass *klass)
{
  GParamSpec    *pspec;
  GObjectClass  *obj_class = G_OBJECT_CLASS (klass);

  obj_class->finalize     = dee_filter_model_finalize;
  obj_class->constructed  = dee_filter_model_constructed; 
  obj_class->get_property = dee_filter_model_get_property;
  obj_class->set_property = dee_filter_model_set_property;

  /**
   * DeeFilterModel:filter:
   *
   * Property holding the #DeeFilter used to filter the model
   * defined in the #DeeFilterModel:back-end property.
   * 
   * Type: DeeFilter
   */
  pspec = g_param_spec_pointer ("filter", "Filter",
                                "Filtering rules applied to the original model",
                                G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                                | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_FILTER, pspec);

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeFilterModelPrivate));
}

static void
dee_filter_model_init (DeeFilterModel *self)
{
  DeeFilterModelPrivate *priv;

  priv = self->priv = DEE_FILTER_MODEL_GET_PRIVATE (self);
  
  priv->iter_map = g_hash_table_new (g_direct_hash, g_direct_equal);
  priv->iter_list = g_sequence_new (NULL);
  
  priv->ignore_orig_signals = FALSE;
  priv->on_orig_row_added_id = 0;
  priv->on_orig_row_removed_id = 0;
  priv->on_orig_row_changed_id = 0;
  priv->on_orig_changeset_started_id = 0;
  priv->on_orig_changeset_finished_id = 0;
}

static void
dee_filter_model_model_iface_init (DeeModelIface *iface)
{
  /* Override column spec setters as that would cause a mess... */
  iface->set_schema_full      = dee_filter_model_set_schema_full;
  iface->get_n_rows           = dee_filter_model_get_n_rows;
  iface->prepend_row          = dee_filter_model_prepend_row;
  iface->append_row           = dee_filter_model_append_row;
  iface->insert_row_before    = dee_filter_model_insert_row_before;
  iface->find_row_sorted      = dee_filter_model_find_row_sorted;
  iface->remove               = dee_filter_model_remove;
  iface->get_first_iter       = dee_filter_model_get_first_iter;
  iface->get_iter_at_row      = dee_filter_model_get_iter_at_row;
  iface->next                 = dee_filter_model_next;
  iface->prev                 = dee_filter_model_prev;
  iface->is_first             = dee_filter_model_is_first;
  iface->get_position         = dee_filter_model_get_position;
}

/*
 * Public API
 */

/**
 * dee_filter_model_new:
 * @filter: Structure containing the logic used to create the filter model.
 *          The filter model will create it's own copy of @filter so unless
 *          @filter is allocated statically or on the stack you need to free it
 *          after calling this method.
 * @orig_model: The back end model. This will be set as the
 *              #DeeProxyModel:back-end property
 *
 * Returns: (transfer full) (type DeeFilterModel): A newly allocated #DeeFilterModel. Free with g_object_unref().
 */
DeeModel*
dee_filter_model_new (DeeModel  *orig_model,
                      DeeFilter *filter)
{
  DeeModel  *self;
  
  self = DEE_MODEL (g_object_new (DEE_TYPE_FILTER_MODEL,
                                  "filter", filter,
                                  "back-end", orig_model,
                                  "proxy-signals", FALSE,
                                  "inherit-seqnums", FALSE,
                                  NULL));

  return self;
}

/**
 * dee_filter_model_contains:
 * @self: The #DeeFilterModel to check
 * @iter: (transfer none):The #DeeModelIter to check
 *
 * Check if @iter from the back end model is mapped in @self.
 * 
 * Returns: %TRUE if and only if @iter is contained in @self. 
 */
gboolean
dee_filter_model_contains (DeeFilterModel *self,
                           DeeModelIter   *iter)
{
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), FALSE);
  
  return g_hash_table_lookup (self->priv->iter_map, iter) != NULL;
}

/**
 * dee_filter_model_append_iter:
 * @self:
 * @iter:
 *
 * Includes @iter from the back end model in the filtered model, appending
 * it to the end of the filtered rows.
 *
 * This method is usually called when implementing #DeeFilterMapFunc or
 * #DeeFilterMapNotify methods.
 *
 * Return value: (transfer none): Always returns @iter
 */
DeeModelIter*
dee_filter_model_append_iter (DeeFilterModel *self,
                              DeeModelIter   *iter)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  g_return_val_if_fail (!dee_model_is_last ((DeeModel*)self, iter), NULL);
  
  priv = self->priv;
  seq_iter = g_hash_table_lookup (priv->iter_map, iter);
  
  if (seq_iter != NULL)
    {
      g_critical ("Iter already present in DeeFilterModel");
      return NULL;
    }
  
  seq_iter = g_sequence_append (priv->iter_list, iter);
  g_hash_table_insert (priv->iter_map, iter, seq_iter);

  dee_serializable_model_inc_seqnum (DEE_MODEL (self));
  g_signal_emit_by_name (self, "row-added", iter);
  
  return iter;
}

/**
 * dee_filter_model_prepend_iter:
 * @self:
 * @iter:
 *
 * Includes @iter from the back end model in the filtered model, prepending
 * it to the beginning of the filtered rows.
 *
 * This method is usually called when implementing #DeeFilterMapFunc or
 * #DeeFilterMapNotify methods.
 *
 * Return value: (transfer none): Always returns @iter
 */
DeeModelIter*
dee_filter_model_prepend_iter (DeeFilterModel *self,
                               DeeModelIter   *iter)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  
  priv = self->priv;
  seq_iter = g_hash_table_lookup (priv->iter_map, iter);
  
  if (seq_iter != NULL)
    {
      g_critical ("Iter already present in DeeFilterModel");
      return NULL;
    }
  
  seq_iter = g_sequence_prepend (priv->iter_list, iter);
  g_hash_table_insert (priv->iter_map, iter, seq_iter);

  dee_serializable_model_inc_seqnum (DEE_MODEL (self));
  g_signal_emit_by_name (self, "row-added", iter);
  
  return iter;
}

/**
 * dee_filter_model_insert_iter:
 * @self:
 * @iter:
 * @pos:
 *
 * Includes @iter from the back end model in the filtered model, inserting it at
 * @pos pushing other rows down.
 *
 * This method is usually called when implementing #DeeFilterMapFunc or
 * #DeeFilterMapNotify methods.
 *
 * Return value: (transfer none): Always returns @iter
 */
DeeModelIter*
dee_filter_model_insert_iter (DeeFilterModel *self,                                                        
                              DeeModelIter   *iter,
                              guint           pos)
{
  DeeModelIter          *pos_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  
  pos_iter = dee_model_get_iter_at_row (DEE_MODEL (self), pos);
  
  return dee_filter_model_insert_iter_before (self, iter, pos_iter);
}

/**
 * dee_filter_model_insert_iter_before:
 * @self:
 * @iter:
 * @pos:
 *
 * Includes @iter from the back end model in the filtered model, inserting it at
 * the position before @pos pushing other rows down.
 *
 * This method is usually called when implementing #DeeFilterMapFunc or
 * #DeeFilterMapNotify methods.
 *
 * Return value: (transfer none): Always returns @iter
 */
DeeModelIter*
dee_filter_model_insert_iter_before (DeeFilterModel *self,
                                     DeeModelIter   *iter,
                                     DeeModelIter   *pos)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  
  priv = self->priv;
  
  seq_iter = g_hash_table_lookup (priv->iter_map, iter);
  if (seq_iter != NULL)
    {
      g_critical ("Iter already present in DeeFilterModel");
      return NULL;
    }
  
  seq_iter = g_hash_table_lookup (priv->iter_map, pos);
  if (seq_iter == NULL)
    {
      g_critical ("Can not insert iter. Position iter not "
                  "present in DeeFilterModel");
      return NULL;
    }
  
  seq_iter = g_sequence_insert_before (seq_iter, iter);
  g_hash_table_insert (priv->iter_map, iter, seq_iter);

  dee_serializable_model_inc_seqnum (DEE_MODEL (self));
  g_signal_emit_by_name (self, "row-added", iter);
  
  return iter;
}

/**
 * dee_filter_model_insert_iter_with_original_order:
 * 
 * @self: A #DeeFilterModel instance
 * @iter: Iterator
 *
 * Inserts @iter in @self in a way that is consistent with the ordering of the
 * rows in the original #DeeModel behind @self. THis method assumes that @self
 * is already ordered this way. If that's not the case then this method has
 * undefined behaviour.
 *
 * This method is mainly intended as a helper for #DeeFilterMapNotify functions
 * of #DeeFilter implementations that creates filter models sorted in
 * accordance with the original models.
 *
 * Return value: (transfer none): Always returns @iter
 */
DeeModelIter*
dee_filter_model_insert_iter_with_original_order (DeeFilterModel *self,
                                                  DeeModelIter   *iter)
{
  DeeFilterModelPrivate *priv;
  DeeModel              *orig_model;
  DeeModelIter          *probe, *end;

  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  g_return_val_if_fail (iter != NULL, NULL);

  priv = self->priv;
  orig_model = priv->orig_model;

  /* We find the first row *after* iter which is both in orig_model and the
   * filter model and insert iter *before* that row  in the filter model.
   * This should assure the sorting is consistent between the models
   * (assuming it already was consistent before we started) */
  probe = dee_model_next (orig_model, iter);
  end = dee_model_get_last_iter (orig_model);
  while (probe != end)
    {
      if (dee_filter_model_contains (self, probe))
        {
          dee_filter_model_insert_iter_before (self, iter, probe);
          return iter;
        }
      probe = dee_model_next (orig_model, probe);
    }

  /* We made it to the end without finding a suitable place,
   * so just append it */
  return dee_filter_model_append_iter (self, iter);
}

/*
 * Private impl
 */

static gboolean
dee_filter_model_is_empty (DeeModel       *self)
{
  DeeFilterModelPrivate *priv;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), FALSE);
  
  priv = DEE_FILTER_MODEL (self)->priv;
  return g_sequence_get_begin_iter (priv->iter_list) ==
                      g_sequence_get_end_iter (priv->iter_list);
}

static void
on_orig_model_row_added (DeeFilterModel *self,
                         DeeModelIter  *iter)
{
  DeeFilterModelPrivate *priv;
  
  priv = self->priv;
  
  if (priv->ignore_orig_signals)
    return;
  
  dee_filter_notify (priv->filter, iter, priv->orig_model, self);
  
}

static void
on_orig_model_row_removed (DeeFilterModel *self,
                           DeeModelIter  *iter)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *seq_iter;
  
  priv = self->priv;
  
  if (priv->ignore_orig_signals)
    return;
  
  seq_iter = g_hash_table_lookup (priv->iter_map, iter);
  
  if (seq_iter != NULL)
    {
      /* Emit signal before we delete it from our records */
      dee_serializable_model_inc_seqnum (DEE_MODEL (self));
      g_signal_emit_by_name (self, "row-removed", iter);
      g_hash_table_remove (priv->iter_map, iter);
      g_sequence_remove (seq_iter);
    }
}

static void
on_orig_model_row_changed (DeeFilterModel *self,
                           DeeModelIter  *iter)
{
  DeeFilterModelPrivate *priv;
  
  priv = self->priv;
  
  if (priv->ignore_orig_signals)
    return;
  
  if (dee_filter_model_contains (self, iter))
    {
      dee_serializable_model_inc_seqnum (DEE_MODEL (self));
      g_signal_emit_by_name (self, "row-changed", iter);
    }
}

static void
on_orig_model_changeset_started (DeeFilterModel *self,
                                 DeeModel *model)
{
  DeeFilterModelPrivate *priv;
  
  priv = self->priv;
  
  if (priv->ignore_orig_signals)
    return;

  /* this can end up being an empty changeset, but that's ok */
  g_signal_emit_by_name (self, "changeset-started");
}

static void
on_orig_model_changeset_finished (DeeFilterModel *self,
                                  DeeModel *model)
{
  DeeFilterModelPrivate *priv;
  
  priv = self->priv;
  
  if (priv->ignore_orig_signals)
    return;
  
  g_signal_emit_by_name (self, "changeset-finished");
}

/*
 * DeeModel Interface Implementation
 */

static void
dee_filter_model_set_schema_full (DeeModel *self,
                                  const gchar* const *schema,
                                  guint     n_columns)
{
  g_return_if_fail (DEE_IS_FILTER_MODEL (self));

  g_critical ("You can not set the schema on a DeeFilterModel. "
              "It will always inherit the ones on the original model");
  return;
}

/* FALL THROUGH: dee_filter_model_get_schema() */

/* FALL THROUGH: dee_filter_model_get_column_schema() */

/* FALL THROUGH: dee_filter_model_get_n_columns() */

static guint
dee_filter_model_get_n_rows (DeeModel *self)
{
  DeeFilterModelPrivate *priv;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), 0);
  
  priv = DEE_FILTER_MODEL (self)->priv;
  return g_hash_table_size (priv->iter_map) - 1;
}

/* FALL THROUGH: dee_filter_model_get_column_schema() */

/* FALL THROUGH: dee_filter_model_clear() */

static DeeModelIter*
dee_filter_model_prepend_row (DeeModel *self,
                              GVariant **row_members)
{
  DeeFilterModelPrivate *priv;
  DeeModelIter          *iter;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  
  priv = DEE_FILTER_MODEL (self)->priv;
  
  /* If the filter model already contains some rows, then insert the new row
   * in the orig model at the position of the first row in the filtered model.
   * If it's empty we prepend the row to the orig model */
  if (dee_filter_model_is_empty (self))
    {
      priv->ignore_orig_signals = TRUE;
      iter = dee_model_prepend_row (priv->orig_model, row_members);
      priv->ignore_orig_signals = FALSE;
    }
  else
    {
      iter = dee_model_get_first_iter (self);
      priv->ignore_orig_signals = TRUE;
      iter = dee_model_insert_row_before (priv->orig_model, iter, row_members);
      priv->ignore_orig_signals = FALSE;
    }
  
  seq_iter = g_sequence_prepend (priv->iter_list, iter);
  g_hash_table_insert (priv->iter_map, iter, seq_iter);

  dee_serializable_model_inc_seqnum (self);
  g_signal_emit_by_name (self, "row-added", iter);
  
  return iter;
}

static DeeModelIter*
dee_filter_model_append_row (DeeModel  *self,
                             GVariant **row_members)
{
  DeeFilterModelPrivate *priv;
  DeeModelIter          *iter;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  
  priv = DEE_FILTER_MODEL (self)->priv;
  
  /* If the filter model already contains some rows, then insert the new row
   * in the orig model at the position of the last row in the filtered model.
   * If it's empty we append the row to the orig model */
  priv->ignore_orig_signals = TRUE;
  if (dee_filter_model_is_empty (self))
    {
      iter = dee_model_append_row (priv->orig_model, row_members);
    }
  else
    {
      iter = dee_model_get_last_iter (self);
      iter = dee_model_insert_row_before (priv->orig_model,
                                          iter, row_members);
    }
  priv->ignore_orig_signals = FALSE;
  
  seq_iter = g_sequence_append (priv->iter_list, iter);
  g_hash_table_insert (priv->iter_map, iter, seq_iter);

  dee_serializable_model_inc_seqnum (self);
  g_signal_emit_by_name (self, "row-added", iter);
  
  return iter;
}

/* FALL THROUGH: dee_filter_model_insert_valist() */

static DeeModelIter*
dee_filter_model_insert_row_before (DeeModel      *self,
                                    DeeModelIter  *iter,
                                    GVariant     **row_members)
{
  DeeFilterModelPrivate *priv;
  DeeModelIter          *new_iter;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  
  priv = DEE_FILTER_MODEL (self)->priv;
  
  seq_iter = g_hash_table_lookup (priv->iter_map, iter);
  if (seq_iter == NULL)
    {
      g_critical ("DeeFilterModel can not insert before unknown iter");
      return NULL;
    }
  
  priv->ignore_orig_signals = TRUE;
  new_iter = dee_model_insert_row_before (priv->orig_model, iter, row_members);
  priv->ignore_orig_signals = FALSE;
  
  seq_iter = g_sequence_insert_before (seq_iter, new_iter);
  g_hash_table_insert (priv->iter_map, new_iter, seq_iter);

  dee_serializable_model_inc_seqnum (self);
  g_signal_emit_by_name (self, "row-added", new_iter);
  
  return iter;
}

typedef struct {
  DeeCompareRowFunc  cmp;
  gpointer           user_data;
  guint              n_cols;
  GVariant         **row_buf;
  DeeModel          *model;
} CmpDispatchData;

static gint
_dispatch_cmp_func (DeeModelIter *iter,
                    GVariant **row_spec,
                    CmpDispatchData *data)
{
  gint result, i;

  dee_model_get_row (data->model, iter, data->row_buf);
  result = data->cmp (data->row_buf, row_spec, data->user_data);

  for (i = 0; i < data->n_cols; i++) g_variant_unref (data->row_buf[i]);

  return result;
}

static DeeModelIter*
dee_filter_model_find_row_sorted   (DeeModel           *self,
                                    GVariant          **row_spec,
                                    DeeCompareRowFunc   cmp_func,
                                    gpointer            user_data,
                                    gboolean           *out_was_found)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *iter;
  CmpDispatchData        data;
  guint                  row_size, n_cols, i;

  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  g_return_val_if_fail (row_spec != NULL, NULL);
  g_return_val_if_fail (cmp_func != NULL, NULL);

  priv = DEE_FILTER_MODEL (self)->priv;

  if (out_was_found != NULL) *out_was_found = FALSE;

  n_cols = dee_model_get_n_columns (self);
  row_size = sizeof (gpointer) * n_cols;

  data.cmp = cmp_func;
  data.user_data = user_data;
  data.n_cols = n_cols;
  data.row_buf = g_alloca (row_size);
  data.model = self;

  iter = g_sequence_search (priv->iter_list, row_spec,
                            (GCompareDataFunc)_dispatch_cmp_func, &data);

  /* Kinda awkward - if we did find the row then GSequence has placed just
   * after the row we wanted. If we did not find it, then we're in the right
   * place */
  if (!g_sequence_iter_is_begin (iter))
    {
      GSequenceIter *jter = g_sequence_iter_prev (iter);

      dee_model_get_row (self, g_sequence_get (jter), data.row_buf);

      if (cmp_func (data.row_buf, row_spec, user_data) == 0)
        {
          if (out_was_found != NULL) *out_was_found = TRUE;
          iter = jter;
        }

      for (i = 0; i < n_cols; i++) g_variant_unref (data.row_buf[i]);
    }

  if (g_sequence_iter_is_end (iter))
    return dee_model_get_last_iter (self);
  else
    return (DeeModelIter *) g_sequence_get (iter);
}

static void
dee_filter_model_remove (DeeModel     *self,
                         DeeModelIter *iter)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *seq_iter;
  
  g_return_if_fail (DEE_IS_FILTER_MODEL (self));
  
  priv = DEE_FILTER_MODEL (self)->priv;
  seq_iter = g_hash_table_lookup (priv->iter_map, iter);
  if (seq_iter == NULL)
    {
      g_critical ("Can not remove unknown iter from DeeFilterModel");
      return;
    }
  
  g_hash_table_remove (priv->iter_map, iter);
  g_sequence_remove (seq_iter);
  
  priv->ignore_orig_signals = TRUE;
  dee_model_remove (priv->orig_model, iter);
  priv->ignore_orig_signals = FALSE;
}

/* FALL THROUGH: dee_filter_model_set_valist() */

/* FALL THROUGH: dee_filter_model_set_value() */

/* FALL THROUGH: dee_filter_model_set_value_silently() */

/* FALL THROUGH: dee_filter_model_get_valist() */

/* FALL THROUGH: dee_filter_model_get_value() */

/* FALL THROUGH: dee_filter_model_get_bool() */

/* FALL THROUGH: dee_filter_model_get_uchar() */

/* FALL THROUGH: dee_filter_model_get_int() */

/* FALL THROUGH: dee_filter_model_get_uint() */

/* FALL THROUGH: dee_filter_model_get_int64() */

/* FALL THROUGH: dee_filter_model_get_uint64() */

/* FALL THROUGH: dee_filter_model_get_double() */

/* FALL THROUGH: dee_filter_model_get_string() */

static DeeModelIter*
dee_filter_model_get_first_iter (DeeModel *self)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  
  priv = DEE_FILTER_MODEL (self)->priv;  
  
  if (dee_filter_model_is_empty (self))
    return dee_model_get_last_iter (priv->orig_model);
  
  seq_iter = g_sequence_get_begin_iter (priv->iter_list);
  return (DeeModelIter*) g_sequence_get (seq_iter);
}

/* FALL THROUGH: dee_filter_model_get_last_iter() */

static DeeModelIter*
dee_filter_model_get_iter_at_row (DeeModel *self, guint row)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  
  priv = DEE_FILTER_MODEL (self)->priv;
  seq_iter = g_sequence_get_iter_at_pos (priv->iter_list, row);
  
  /* On out of bounds we return the end iter of the orig model */
  if (seq_iter == g_sequence_get_end_iter (priv->iter_list))
    return dee_model_get_last_iter (priv->orig_model);
  
  return (DeeModelIter*) g_sequence_get (seq_iter);
}

static DeeModelIter*
dee_filter_model_next (DeeModel     *self,
                       DeeModelIter *iter)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  g_return_val_if_fail (!dee_model_is_last (self, iter), NULL);
  
  priv = DEE_FILTER_MODEL (self)->priv;
  
  seq_iter = (GSequenceIter*) g_hash_table_lookup (priv->iter_map, iter);
  
  if (seq_iter == NULL)
    {
      g_critical ("Can not find next iter for unknown iter");
      return NULL;
    }
  
  seq_iter = g_sequence_iter_next (seq_iter);
  
  if (g_sequence_iter_is_end (seq_iter))
    return dee_model_get_last_iter (priv->orig_model);
  
  return g_sequence_get (seq_iter);
}

static DeeModelIter*
dee_filter_model_prev (DeeModel     *self,
                       DeeModelIter *iter)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), NULL);
  g_return_val_if_fail (!dee_model_is_first (self, iter), NULL);
  
  priv = DEE_FILTER_MODEL (self)->priv;
  seq_iter = (GSequenceIter*) g_hash_table_lookup (priv->iter_map, iter);
  
  if (seq_iter == NULL)
    {
      g_critical ("Can not find next iter for unknown iter");
      return NULL;
    }
  
  seq_iter = g_sequence_iter_prev (seq_iter);
  
  return g_sequence_get (seq_iter);
}

static gboolean
dee_filter_model_is_first (DeeModel *self, DeeModelIter *iter)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), -1);
  
  priv = DEE_FILTER_MODEL (self)->priv;
  
  if (dee_filter_model_is_empty (self))
    return iter == dee_model_get_last_iter (priv->orig_model);
    
  seq_iter = g_sequence_get_begin_iter (priv->iter_list);
  return g_sequence_get (seq_iter) == iter;
}

/* FALL THROUGH: dee_filter_model_is_last()*/

static guint
dee_filter_model_get_position (DeeModel     *self,
                               DeeModelIter *iter)
{
  DeeFilterModelPrivate *priv;
  GSequenceIter         *seq_iter;
  
  g_return_val_if_fail (DEE_IS_FILTER_MODEL (self), 0);
  
  priv = DEE_FILTER_MODEL (self)->priv;
  seq_iter = (GSequenceIter*) g_hash_table_lookup (priv->iter_map, iter);
  
  if (seq_iter == NULL)
    {
      g_critical ("Can not find next iter for unknown iter");
      return 0;
    }
  
  return (guint) ABS(g_sequence_iter_get_position (seq_iter));
}

