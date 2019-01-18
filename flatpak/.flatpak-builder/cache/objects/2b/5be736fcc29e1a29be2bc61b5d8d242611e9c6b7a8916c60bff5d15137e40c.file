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
 * SECTION:dee-tree-index
 * @short_description: A #DeeTreeIndex backed by a balanced binary tree
 * @include: dee.h
 *
 * #DeeTreeIndex is an implementation of #DeeIndex which is backed
 * by a balanced binary tree. This means that it in addition to
 * #DEE_TERM_MATCH_EXACT also supports #DEE_TERM_MATCH_PREFIX as a flag in
 * dee_index_lookup().
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>

#include "dee-tree-index.h"
#include "dee-result-set.h"
#include "dee-glist-result-set.h"
#include "trace-log.h"

G_DEFINE_TYPE (DeeTreeIndex, dee_tree_index, DEE_TYPE_INDEX);

#define DEE_TREE_INDEX_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_TREE_INDEX, DeeTreeIndexPrivate))

/*
 * FORWARDS
 */
typedef struct
{
  /* The term string is owned by the DeeTermList of the index */
  const gchar *term;

  /* Cached collation key for the term string */
  const gchar *col_key;

  /* Maps row iter -> pointer to guint with ref count */
  GHashTable  *rows;
} Term;

/*
 * DeeIndex API forwards
 */

static DeeResultSet* dee_tree_index_lookup (DeeIndex         *self,
                                            const gchar      *term,
                                            DeeTermMatchFlag  flags);

static void     dee_tree_index_foreach (DeeIndex         *self,
                                        const gchar      *start_term,
                                        DeeIndexIterFunc  func,
                                        gpointer          userdata);

static guint    dee_tree_index_get_n_terms (DeeIndex *self);

static guint    dee_tree_index_get_n_rows (DeeIndex *self);

static guint    dee_tree_index_get_n_rows_for_term (DeeIndex    *self,
                                                    const gchar *term);

static guint    dee_tree_index_get_supported_term_match_flags (DeeIndex *self);


/*
 * Private functions
 */
static void     on_row_added (DeeIndex      *self,
                              DeeModelIter  *iter,
                              DeeModel      *model);

static void     on_row_removed (DeeIndex      *self,
                                DeeModelIter  *iter,
                                DeeModel      *model);

static void     on_row_changed (DeeIndex      *self,
                                DeeModelIter  *iter,
                                DeeModel      *model);

static Term*    term_new        (const gchar   *term,
                                 const gchar   *col_key);

static void     term_destroy    (Term* term);

static void     term_ref_row    (Term *term,
                                 DeeModelIter *iter);

static void     term_unref_row  (Term *term,
                                 DeeModelIter *iter);

static guint    term_n_rows     (Term *term);

static GList*   term_rows       (Term *term);

static gint     term_cmp        (Term        *term,
                                 Term        *other,
                                 DeeAnalyzer *analyzer);

static GSequenceIter* find_term       (GSequence   *terms,
                                       const gchar *term,
                                       const gchar *col_key,
                                       DeeAnalyzer *analyzer);

static GSequenceIter* find_term_real (GSequence        *terms,
                                      const gchar      *term,
                                      const gchar      *col_key,
                                      DeeAnalyzer      *analyzer,
                                      DeeTermMatchFlag  flags);
/*
 * Term impl. term and colkeys are owned by our analyzer
 */
static Term*
term_new (const gchar *term, const gchar *col_key)
{
  Term *self;

  g_return_val_if_fail (term != NULL, NULL);
  g_return_val_if_fail (col_key != NULL, NULL);

  self = g_slice_new (Term);
  self->term = term;
  self->col_key = col_key;
  self->rows = g_hash_table_new_full (g_direct_hash, g_direct_equal,
                                      NULL, (GDestroyNotify) g_free);

  return self;
}

static void
term_destroy (Term* term)
{
  g_hash_table_unref (term->rows);
  g_slice_free (Term, term);
}

static void
term_ref_row (Term *term, DeeModelIter *iter)
{
  guint *ref_count;
  
  ref_count = g_hash_table_lookup (term->rows, iter);
  
  if (ref_count == NULL)
    {
      ref_count = g_new (guint, 1);
      *ref_count = 1;
      g_hash_table_insert (term->rows, iter, ref_count);
    }
  else
    {
      *ref_count = *ref_count + 1;
    }
}

static void
term_unref_row (Term *term, DeeModelIter *iter)
{
  guint *ref_count;
  
  ref_count = g_hash_table_lookup (term->rows, iter);
  
  if (ref_count == NULL)
    {
      g_critical ("Trying to unref unknown row %p for term '%s'",
                  iter, term->term);
    }
  else
    {
      *ref_count = *ref_count - 1;
      if (*ref_count == 0)
        {
          g_hash_table_remove(term->rows, iter);
        }
    }
}

static guint
term_n_rows (Term *term)
{
  return g_hash_table_size(term->rows);
}

static GList*
term_rows (Term *term)
{
  return g_hash_table_get_keys (term->rows);
}

static gint
term_cmp (Term *term, Term *other, DeeAnalyzer *analyzer)
{
  return dee_analyzer_collate_cmp (analyzer, term->col_key, other->col_key);
}

/* Search priv->terms for a string from priv->term_list.
 * ! Doesn't work for strings not in priv->term_list ! */
static GSequenceIter*
find_term (GSequence *terms, const gchar *term, const gchar *col_key,
           DeeAnalyzer *analyzer)
{
  return find_term_real (terms, term, col_key, analyzer, DEE_TERM_MATCH_EXACT);
}

static GSequenceIter*
find_term_real (GSequence        *terms,
                const gchar      *term,
                const gchar      *col_key,
                DeeAnalyzer      *analyzer,
                DeeTermMatchFlag  flags)
{
  Term           search_term, *term_result;
  GSequenceIter *found_iter, *iter, *previous, *begin, *end;

  begin = g_sequence_get_begin_iter (terms);
  end = g_sequence_get_end_iter (terms);

  /* If the index is empty don't bother searching */
  if (begin == end)
    return NULL;

  search_term.col_key = col_key;

  if (flags & DEE_TERM_MATCH_EXACT)
    {
      // FIXME: do we need to make sure this is the first iter?
      return g_sequence_lookup (terms, &search_term,
                                (GCompareDataFunc) term_cmp, analyzer);
    }
  else if (flags & DEE_TERM_MATCH_PREFIX)
    {
      found_iter = g_sequence_search (terms, &search_term,
                                      (GCompareDataFunc) term_cmp, analyzer);

      /* What can happen now is:
       * 1) found_iter has our prefix
       * 2) found_iter as well as the found_iter->previous have our prefix
       * 3) found_iter doesn't have it, but found_iter->previous does
       * 4) there isn't any nearby iter that has the prefix */
      previous = iter = found_iter;
      /* We might be placed after the iter we want */
      while (previous != begin)
        {
          previous = g_sequence_iter_prev (previous);
          term_result = g_sequence_get (previous);
          if (g_str_has_prefix (term_result->term, term)) iter = previous;
          else break;
        }
      if (iter == found_iter && iter != end)
        {
          /* We never checked this one */
          term_result = g_sequence_get (iter);
          if (g_str_has_prefix (term_result->term, term))
            return iter;
        }
      else
        return iter;
    }
  else
    {
      g_critical ("Unexpected term match flags %u", flags);
      return NULL;
    }

  return NULL;
}

/*
 * GOBJECT STUFF
 */

struct _DeeTreeIndexPrivate
{
  /* Holds Term instances as data members */
  GSequence *terms;

  /* Holds map of DeeModelIter -> GPtrArray<Term> */
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
dee_tree_index_finalize (GObject *object)
{
  DeeTreeIndexPrivate *priv = DEE_TREE_INDEX (object)->priv;
  DeeModel *model = dee_index_get_model (DEE_INDEX (object));

  if (priv->on_row_added_handler)
    g_signal_handler_disconnect(model, priv->on_row_added_handler);
  if (priv->on_row_removed_handler)
    g_signal_handler_disconnect(model, priv->on_row_removed_handler);
  if (priv->on_row_changed_handler)
    g_signal_handler_disconnect(model, priv->on_row_changed_handler);

  if (priv->terms)
    {
      g_sequence_free (priv->terms);
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

  G_OBJECT_CLASS (dee_tree_index_parent_class)->finalize (object);
}

static void
dee_tree_index_constructed (GObject *object)
{
  DeeTreeIndexPrivate *priv = DEE_TREE_INDEX (object)->priv;
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
dee_tree_index_class_init (DeeTreeIndexClass *klass)
{
  GObjectClass  *obj_class = G_OBJECT_CLASS (klass);
  DeeIndexClass *idx_class = DEE_INDEX_CLASS (klass);

  obj_class->finalize     = dee_tree_index_finalize;
  obj_class->constructed  = dee_tree_index_constructed;

  idx_class->lookup      = dee_tree_index_lookup;
  idx_class->foreach     = dee_tree_index_foreach;
  idx_class->get_n_terms = dee_tree_index_get_n_terms;
  idx_class->get_n_rows  = dee_tree_index_get_n_rows;
  idx_class->get_n_rows_for_term = dee_tree_index_get_n_rows_for_term;
  idx_class->get_supported_term_match_flags  = dee_tree_index_get_supported_term_match_flags;

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeTreeIndexPrivate));
}

static void
dee_tree_index_init (DeeTreeIndex *self)
{
  self->priv = DEE_TREE_INDEX_GET_PRIVATE (self);

  self->priv->terms = g_sequence_new ((GDestroyNotify) term_destroy);
  self->priv->row_terms = g_hash_table_new_full(g_direct_hash, g_direct_equal,
                                                NULL, (GDestroyNotify) g_ptr_array_unref);
  self->priv->term_list = g_object_new (DEE_TYPE_TERM_LIST, NULL);
}

/*
 * IMPLEMENTATION
 */

static DeeResultSet*
dee_tree_index_lookup (DeeIndex          *self,
                       const gchar       *term,
                       DeeTermMatchFlag   flags)
{
  DeeTreeIndexPrivate *priv;
  DeeAnalyzer         *analyzer;
  GSequenceIter       *term_iter, *end;
  Term                *term_data;
  gchar               *col_key;
  
  g_return_val_if_fail (DEE_IS_TREE_INDEX (self), NULL);
  g_return_val_if_fail (term != NULL, NULL);

  priv = DEE_TREE_INDEX (self)->priv;
  analyzer = dee_index_get_analyzer (self);
  col_key = dee_analyzer_collate_key (analyzer, term);
  term_iter = find_term_real (priv->terms, term, col_key, analyzer, flags);
  g_free (col_key);

  if (term_iter == NULL ||
      term_iter == g_sequence_get_end_iter (priv->terms))
    {
      return dee_glist_result_set_new (NULL, /* The empty GList */
                                       dee_index_get_model (self),
                                       NULL);
    }

  if (flags & DEE_TERM_MATCH_EXACT)
    {
      term_data = g_sequence_get (term_iter);
      return dee_glist_result_set_new (term_rows (term_data),
                                        dee_index_get_model (self),
                                        G_OBJECT (self));
    }
  else if (flags & DEE_TERM_MATCH_PREFIX)
    {
      GList *iter;
      GList *buf = NULL;
      GHashTable *iter_set = g_hash_table_new (g_direct_hash, g_direct_equal);

      end = g_sequence_get_end_iter (priv->terms);
      term_data = g_sequence_get (term_iter);

      /* We can't use collation keys for prefix matching */
      while (g_str_has_prefix (term_data->term, term))
        {
          GList *rows = term_rows (term_data);
          iter = rows;
          /* There may be duplicated iters in the result list */
          while (iter != NULL)
            {
              if (g_hash_table_lookup_extended (iter_set, iter->data,
                                                NULL, NULL))
                {
                  GList *to_delete = iter;
                  iter = iter->next;
                  rows = g_list_delete_link (rows, to_delete);
                }
              else
                {
                  /* Add to the iter set */
                  g_hash_table_replace (iter_set, iter->data, iter->data);
                  iter = iter->next;
                }
            }
          buf = g_list_concat (buf, rows);

          term_iter = g_sequence_iter_next (term_iter);
          if (term_iter == end)
            break;
          term_data = g_sequence_get (term_iter);
        }

      g_hash_table_unref (iter_set);

      /* We use a dummy GObject to bolt ref counting onto the GList */
      GObject *buf_owner = g_object_new (G_TYPE_OBJECT, NULL);
      g_object_set_data_full (buf_owner, "buf",
                              buf, (GDestroyNotify) g_list_free);

      DeeResultSet *results = dee_glist_result_set_new (buf,
                                                         dee_index_get_model (self),
                                                         buf_owner);
      g_object_unref (buf_owner);
      return results;
    }
  else
    {
      g_critical ("Unexpected term match flags %u", flags);
      return NULL;
    }
}

static void
dee_tree_index_foreach (DeeIndex         *self,
                        const gchar      *start_term,
                        DeeIndexIterFunc  func,
                        gpointer          userdata)
{
  DeeTreeIndexPrivate *priv;
  DeeModel            *model;
  DeeAnalyzer         *analyzer;
  DeeResultSet        *results;
  GSequenceIter       *iter, *end;
  Term                *term_data;
  gchar               *col_key;

  g_return_if_fail (DEE_IS_TREE_INDEX (self));
  g_return_if_fail (func != NULL);

  priv = DEE_TREE_INDEX (self)->priv;
  model = dee_index_get_model (self);

  if (start_term == NULL)
    iter = g_sequence_get_begin_iter (priv->terms);
  else
    {
      analyzer = dee_index_get_analyzer (self);
      col_key = dee_analyzer_collate_key (analyzer, start_term);
      iter = find_term (priv->terms, start_term, col_key, analyzer);
      g_free (col_key);
      if (iter == NULL ||
          iter == g_sequence_get_end_iter (priv->terms))
        return;
    }

  end = g_sequence_get_end_iter (priv->terms);
  while (iter != end)
    {
      term_data = g_sequence_get (iter);
      results = dee_glist_result_set_new (term_rows (term_data),
                                           model,
                                           G_OBJECT (self));
      func (start_term, results, userdata);
      g_object_unref (results);

      iter = g_sequence_iter_next (iter);
    }
}

static guint
dee_tree_index_get_n_terms (DeeIndex *self)
{
  DeeTreeIndexPrivate *priv;

  g_return_val_if_fail (DEE_IS_TREE_INDEX (self), 0);

  priv = DEE_TREE_INDEX (self)->priv;
  return g_sequence_get_length(priv->terms);
}

static guint
dee_tree_index_get_n_rows (DeeIndex *self)
{
  DeeTreeIndexPrivate *priv;

  g_return_val_if_fail (DEE_IS_TREE_INDEX (self), 0);

  priv = DEE_TREE_INDEX (self)->priv;
  return g_hash_table_size(priv->row_terms);
}

static guint
dee_tree_index_get_n_rows_for_term (DeeIndex    *self,
                                    const gchar *term)
{
  DeeTreeIndexPrivate *priv;
  Term                *term_data;
  GSequenceIter       *term_iter;
  DeeAnalyzer         *analyzer;
  gchar               *col_key;

  g_return_val_if_fail (DEE_IS_TREE_INDEX (self), 0);
  g_return_val_if_fail (term != NULL, 0);

  priv = DEE_TREE_INDEX (self)->priv;
  analyzer = dee_index_get_analyzer (self);
  col_key = dee_analyzer_collate_key (analyzer, term);
  term_iter = find_term (priv->terms, term, col_key, analyzer);
  g_free (col_key);

  if (term_iter == NULL ||
      term_iter == g_sequence_get_end_iter (priv->terms))
    return 0;

  term_data = g_sequence_get (term_iter);
  return term_n_rows (term_data);
}

static guint
dee_tree_index_get_supported_term_match_flags (DeeIndex *self)
{
  return DEE_TERM_MATCH_EXACT | DEE_TERM_MATCH_PREFIX;
}

static void
on_row_added (DeeIndex      *self,
              DeeModelIter  *iter,
              DeeModel      *model)
{
  DeeTreeIndexPrivate *priv;
  DeeAnalyzer         *analyzer;
  DeeModelReader      *reader;
  DeeTermList         *col_keys;
  guint                i, num_terms;
  const gchar         *term, *colkey;
  gchar               *term_stream;
  GSequenceIter       *term_iter;
  Term                *term_data;
  GPtrArray           *row_term_data;


  priv = DEE_TREE_INDEX (self)->priv;
  analyzer = dee_index_get_analyzer (self);
  reader = dee_index_get_reader (self);

  dee_term_list_clear (priv->term_list);
  col_keys = dee_term_list_clone (priv->term_list);
  term_stream = dee_model_reader_read (reader, model, iter);
  dee_analyzer_analyze (analyzer, term_stream, priv->term_list, col_keys);
  num_terms = dee_term_list_num_terms (priv->term_list);

  if (num_terms == 0)
    {
      g_free (term_stream);
      g_object_unref (col_keys);
      return;
    }

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
      colkey = dee_term_list_get_term (col_keys, i);
      term = dee_term_list_get_term (priv->term_list, i);

      /* Update priv->terms */
      term_iter = find_term (priv->terms, term, colkey, analyzer);

      if (term_iter == NULL ||
          term_iter == g_sequence_get_end_iter (priv->terms))
        {
          term_data = term_new (term, colkey);
          g_sequence_insert_sorted (priv->terms, term_data,
                                    (GCompareDataFunc) term_cmp, analyzer);
        }
      else
        term_data = g_sequence_get (term_iter);

      /* Register the row for the term */
      term_ref_row (term_data, iter);

      /* Update reverse map row -> Terms */
      g_ptr_array_add(row_term_data, term_data);
    }

  g_object_unref (col_keys);
}

static void
on_row_removed (DeeIndex      *self,
                DeeModelIter  *iter,
                DeeModel      *model)
{
  DeeTreeIndexPrivate *priv;
  DeeAnalyzer         *analyzer;
  Term                *term_data;
  GPtrArray           *row_term_data;
  gint                 i;
  GSequenceIter       *term_iter;

  priv = DEE_TREE_INDEX (self)->priv;
  analyzer = dee_index_get_analyzer (self);
  row_term_data = (GPtrArray*) g_hash_table_lookup (priv->row_terms, iter);

  /* We have no terms for this row */
  if (row_term_data == NULL)
    return;

  /* Iterate over all terms for this row and remove the row from those terms */
  for (i = 0; i < row_term_data->len; i++)
    {
      term_data = g_ptr_array_index (row_term_data, i);

      if (term_data == NULL)
        continue;

      term_unref_row (term_data, iter);

      /* If there are no more rows for this term
       * we can remove the term from the index altogether */
      if (term_n_rows (term_data) == 0)
        {
          /* Removing the term from the sequence also frees it */
          term_iter = find_term (priv->terms, term_data->term,
                                 term_data->col_key, analyzer);
          g_sequence_remove (term_iter);
        }
    }
  
  /* Remove the row from the reverse map row -> terms */
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
 * dee_tree_index_new:
 * @model: The model to index
 * @analyzer: The #DeeAnalyzer used to tokenize and filter the terms extracted
 *            by @reader
 * @reader: The #DeeModelReader used to extract terms from the model
 *
 * Create a new tree index.
 *
 * Returns: A newly allocated tree index. Free with g_object_unref().
 */
DeeTreeIndex*
dee_tree_index_new (DeeModel       *model,
                    DeeAnalyzer    *analyzer,
                    DeeModelReader *reader)
{
  DeeTreeIndex *self;

  g_return_val_if_fail (DEE_IS_MODEL (model), NULL);
  g_return_val_if_fail (DEE_IS_ANALYZER (analyzer), NULL);
  g_return_val_if_fail (reader != NULL, NULL);

  self = (DeeTreeIndex*) g_object_new (DEE_TYPE_TREE_INDEX,
                                       "model", model,
                                       "analyzer", analyzer,
                                       "reader", reader,
                                       NULL);

  return self;
}
