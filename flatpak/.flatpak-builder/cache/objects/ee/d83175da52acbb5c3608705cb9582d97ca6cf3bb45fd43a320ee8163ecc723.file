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
 * Authored by:
 *               Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

/**
 * SECTION:dee-hash-index
 * @short_description: A #DeeHashIndex implementation doing lookups in a hash map
 * @include: dee.h
 *
 * #DeeHashIndex is an implementation of #DeeHashIndex which is backed
 * by a hashmap. This means that it only supports the #DEE_TERM_MATCH_EXACT
 * flag in dee_hash_index_lookup().
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "dee-hash-index.h"
#include "dee-result-set.h"
#include "dee-glist-result-set.h"
#include "trace-log.h"

G_DEFINE_TYPE (DeeHashIndex, dee_hash_index, DEE_TYPE_INDEX);

#define DEE_HASH_INDEX_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_HASH_INDEX, DeeHashIndexPrivate))

/*
 * FORWARDS
 */
static DeeResultSet* dee_hash_index_lookup (DeeIndex         *self,
                                            const gchar      *term,
                                            DeeTermMatchFlag  flags);

static void     dee_hash_index_foreach (DeeIndex         *self,
                                        const gchar      *start_term,
                                        DeeIndexIterFunc  func,
                                        gpointer          userdata);

static guint    dee_hash_index_get_n_terms (DeeIndex *self);

static guint    dee_hash_index_get_n_rows (DeeIndex *self);

static guint    dee_hash_index_get_n_rows_for_term (DeeIndex    *self,
                                                    const gchar *term);

static guint    dee_hash_index_get_supported_term_match_flags (DeeIndex *self);

static void     on_row_added (DeeIndex      *self,
                              DeeModelIter  *iter,
                              DeeModel      *model);

static void     on_row_removed (DeeIndex      *self,
                                DeeModelIter  *iter,
                                DeeModel      *model);

static void     on_row_changed (DeeIndex      *self,
                                DeeModelIter  *iter,
                                DeeModel      *model);

/*
 * GOBJECT STUFF
 */

struct _DeeHashIndexPrivate
{
  /* Holds map of term -> GHashTable<DeeModelIter,NULL>.
   * The term keys are owned by term_list */
  GHashTable *terms;

  /* Holds map of DeeModelIter -> GPtrArray<term>.
   * The terms are owned by term_list */
  GHashTable *row_terms;

  /* All terms are stored here */
  DeeTermList *term_list;

  gulong      on_row_added_handler;
  gulong      on_row_removed_handler;
  gulong      on_row_changed_handler;
};

enum
{
  PROP_0,
};

/* GObject stuff */
static void
dee_hash_index_finalize (GObject *object)
{
  DeeHashIndexPrivate *priv = DEE_HASH_INDEX (object)->priv;
  DeeModel *model = dee_index_get_model (DEE_INDEX (object));

  if (priv->on_row_added_handler)
    g_signal_handler_disconnect(model, priv->on_row_added_handler);
  if (priv->on_row_removed_handler)
      g_signal_handler_disconnect(model, priv->on_row_removed_handler);
  if (priv->on_row_changed_handler)
      g_signal_handler_disconnect(model, priv->on_row_changed_handler);

  if (priv->terms)
    {
      g_hash_table_unref (priv->terms);
      priv->terms = NULL;
    }
  if (priv->row_terms)
      {
        g_hash_table_unref (priv->row_terms);
        priv->row_terms = NULL;
      }
  if (priv->term_list)
      {
        g_object_unref (priv->term_list);
        priv->term_list = NULL;
      }

  G_OBJECT_CLASS (dee_hash_index_parent_class)->finalize (object);
}

static void
dee_hash_index_constructed (GObject *object)
{
  DeeHashIndexPrivate *priv = DEE_HASH_INDEX (object)->priv;
  DeeIndex            *self = DEE_INDEX (object);
  DeeModel            *model = dee_index_get_model (self);
  DeeModelIter        *iter;

  /* Listen for changes in the model so we automagically pick those up */
  priv->on_row_added_handler = g_signal_connect_swapped (model, "row-added",
                                                         G_CALLBACK (on_row_added),
                                                         self);

  priv->on_row_removed_handler = g_signal_connect_swapped (model, "row-removed",
                                                           G_CALLBACK (on_row_removed),
                                                           self);

  priv->on_row_changed_handler = g_signal_connect_swapped (model, "row-changed",
                                                           G_CALLBACK (on_row_changed),
                                                           self);

  /* Index existing rows in the model */
  iter = dee_model_get_first_iter (model);
  while (!dee_model_is_last (model, iter))
    {
      on_row_added (self, iter, model);
      iter = dee_model_next (model, iter);
    }
}

static void
dee_hash_index_class_init (DeeHashIndexClass *klass)
{
  GObjectClass       *obj_class = G_OBJECT_CLASS (klass);
  DeeIndexClass *idx_class = DEE_INDEX_CLASS (klass);

  obj_class->finalize     = dee_hash_index_finalize;
  obj_class->constructed  = dee_hash_index_constructed;

  idx_class->lookup      = dee_hash_index_lookup;
  idx_class->foreach     = dee_hash_index_foreach;
  idx_class->get_n_terms = dee_hash_index_get_n_terms;
  idx_class->get_n_rows  = dee_hash_index_get_n_rows;
  idx_class->get_n_rows_for_term = dee_hash_index_get_n_rows_for_term;
  idx_class->get_supported_term_match_flags  = dee_hash_index_get_supported_term_match_flags;

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeHashIndexPrivate));
}

static void
dee_hash_index_init (DeeHashIndex *self)
{
  self->priv = DEE_HASH_INDEX_GET_PRIVATE (self);

  self->priv->terms = g_hash_table_new (g_str_hash, g_str_equal);
  self->priv->row_terms = g_hash_table_new_full(g_direct_hash, g_direct_equal,
                                                NULL, (GDestroyNotify) g_ptr_array_unref);
  self->priv->term_list = g_object_new (DEE_TYPE_TERM_LIST, NULL);
}

/*
 * IMPLEMENTATION
 */

static DeeResultSet*
dee_hash_index_lookup (DeeIndex          *self,
                       const gchar       *term,
                       DeeTermMatchFlag   flags)
{
  DeeHashIndexPrivate *priv;
  GHashTable          *term_data;
  
  g_return_val_if_fail (DEE_IS_HASH_INDEX (self), NULL);
  g_return_val_if_fail (term != NULL, NULL);

  if (flags != DEE_TERM_MATCH_EXACT)
    g_warning ("The DeeHashIndex only supports exact matching of terms");

  priv = DEE_HASH_INDEX (self)->priv;
  term_data = g_hash_table_lookup (priv->terms, term);

  if (term_data == NULL)
    return dee_glist_result_set_new (NULL, /* The empty GList */
                                      dee_index_get_model (self),
                                      NULL);

  return dee_glist_result_set_new (g_hash_table_get_keys(term_data),
                                    dee_index_get_model (self),
                                    G_OBJECT (self));
}

static void
dee_hash_index_foreach (DeeIndex         *self,
                        const gchar      *start_term,
                        DeeIndexIterFunc  func,
                        gpointer          userdata)
{
  DeeResultSet *results;

  g_return_if_fail (DEE_IS_HASH_INDEX (self));
  g_return_if_fail (func != NULL);

  if (start_term == NULL)
    return;

  results = dee_index_lookup (self, start_term, DEE_TERM_MATCH_EXACT);

  if (results != NULL)
    func (start_term, results, userdata);

  g_object_unref (results);

  return;
}

static guint
dee_hash_index_get_n_terms (DeeIndex *self)
{
  DeeHashIndexPrivate *priv;

  g_return_val_if_fail (DEE_IS_HASH_INDEX (self), 0);

  priv = DEE_HASH_INDEX (self)->priv;
  return g_hash_table_size(priv->terms);
}

static guint
dee_hash_index_get_n_rows (DeeIndex *self)
{
  DeeHashIndexPrivate *priv;

  g_return_val_if_fail (DEE_IS_HASH_INDEX (self), 0);

  priv = DEE_HASH_INDEX (self)->priv;
  return g_hash_table_size(priv->row_terms);
}

static guint
dee_hash_index_get_n_rows_for_term (DeeIndex    *self,
                                    const gchar *term)
{
  DeeHashIndexPrivate *priv;
  GHashTable               *term_data;

  g_return_val_if_fail (DEE_IS_HASH_INDEX (self), 0);
  g_return_val_if_fail (term != NULL, 0);

  priv = DEE_HASH_INDEX (self)->priv;
  term_data = g_hash_table_lookup (priv->terms, term);

  if (term_data == NULL)
    return 0;

  return g_hash_table_size (term_data);
}

static guint
dee_hash_index_get_supported_term_match_flags (DeeIndex *self)
{
  return DEE_TERM_MATCH_EXACT;
}

static void
on_row_added (DeeIndex      *self,
              DeeModelIter  *iter,
              DeeModel      *model)
{
  DeeHashIndexPrivate *priv;
  DeeAnalyzer         *analyzer;
  DeeModelReader      *reader;
  guint                i, num_terms;
  gchar               *term_stream;
  const gchar         *term;
  GHashTable          *term_data;
  GPtrArray           *row_term_data;


  priv = DEE_HASH_INDEX (self)->priv;
  analyzer = dee_index_get_analyzer (self);
  reader = dee_index_get_reader (self);

  dee_term_list_clear (priv->term_list);
  term_stream = dee_model_reader_read (reader, model, iter);
  dee_analyzer_analyze (analyzer, term_stream, priv->term_list, NULL); // FIXME: col keys?
  num_terms = dee_term_list_num_terms (priv->term_list);

  g_free (term_stream);

  if (num_terms == 0)
    return;

  /* Make sure we have row_terms registered for this iter */
  row_term_data = (GPtrArray*) g_hash_table_lookup (priv->row_terms, iter);
  if (row_term_data == NULL)
    {
      row_term_data = g_ptr_array_sized_new (num_terms);
      g_hash_table_insert (priv->row_terms, iter, row_term_data);
    }

  for (i = 0; i < num_terms; i++)
    {
      /* Important: The following works because @term lives in the scope
       * of priv->term_list. This makes the 'const gchar*' to 'gpointer'
       * casts valid. Yes, they even survive term_list.clear(). */
      term = dee_term_list_get_term (priv->term_list, i);

      /* Update priv->terms */
      term_data = g_hash_table_lookup (priv->terms, term);

      if (term_data == NULL)
        {
          term_data = g_hash_table_new (g_direct_hash, g_direct_equal);
          g_hash_table_insert (priv->terms, (gpointer) term, term_data);
        }

      /* Register the row for the term */
      g_hash_table_insert (term_data, iter, NULL);

      /* Update reverse map row -> terms */
      g_ptr_array_add(row_term_data, (gpointer) term);
    }
}

static void
on_row_removed (DeeIndex      *self,
                DeeModelIter  *iter,
                DeeModel      *model)
{
  DeeHashIndexPrivate *priv;
  GHashTable          *term_data;
  GPtrArray           *row_term_data;
  gint                 i;
  gchar               *term;

  priv = DEE_HASH_INDEX (self)->priv;
  row_term_data = (GPtrArray*) g_hash_table_lookup (priv->row_terms, iter);

  if (row_term_data == NULL)
    return;

  for (i = 0; i < row_term_data->len; i++)
    {
      term = g_ptr_array_index (row_term_data, i);
      term_data = g_hash_table_lookup (priv->terms, term);
      if (term_data == NULL)
        continue;
      g_hash_table_remove (term_data, iter);

      if (g_hash_table_size (term_data) == 0)
        g_hash_table_remove (priv->terms, term);
    }

  g_hash_table_remove (priv->row_terms, iter);
}

static void
on_row_changed (DeeIndex      *self,
                DeeModelIter  *iter,
                DeeModel      *model)
{
  on_row_removed (self, iter, model);
  on_row_added (self, iter, model);
}

/*
 * API
 */

/**
 * dee_hash_index_new:
 * @model: The model to index
 * @analyzer: The #DeeAnalyzer used to tokenize and filter the terms extracted
 *            by @reader
 * @reader: The #DeeModelReader used to extract terms from the model
 *
 * Create a new hash index.
 *
 * Returns: A newly allocated hash index. Free with g_object_unref().
 */
DeeHashIndex*
dee_hash_index_new (DeeModel       *model,
                    DeeAnalyzer    *analyzer,
                    DeeModelReader *reader)
{
  DeeHashIndex *self;

  g_return_val_if_fail (DEE_IS_MODEL (model), NULL);
  g_return_val_if_fail (DEE_IS_ANALYZER (analyzer), NULL);
  g_return_val_if_fail (reader != NULL, NULL);

  self = (DeeHashIndex*) g_object_new (DEE_TYPE_HASH_INDEX,
                                       "model", model,
                                       "analyzer", analyzer,
                                       "reader", reader,
                                       NULL);
  return self;
}
