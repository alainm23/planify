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
 * SECTION:dee-index
 * @short_description: An inverted index interface for smart access to a #DeeModel
 * @include: dee.h
 *
 * #DeeIndex is an interface for doing key based access to a #DeeModel.
 * A key in the index is known as a <emphasis>term</emphasis> and each term is
 * mapped to a set of matching #DeeModelIter<!-- -->s.
 *
 * The terms are calculated by means of a #DeeAnalyzer which extracts a set of
 * terms from a given row in the model adding these terms to a #DeeTermList.
 * There is a suite of analyzers shipped with Dee, which you can browse in the
 * <link linkend="dee-1.0-Analyzers.top_of_page">Analyzers section</link>.
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h> // memcpy()

#include "dee-model.h"
#include "dee-index.h"
#include "dee-marshal.h"
#include "trace-log.h"

G_DEFINE_ABSTRACT_TYPE (DeeIndex, dee_index, G_TYPE_OBJECT);

#define DEE_INDEX_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_INDEX, DeeIndexPrivate))

/**
 * DeeIndexPrivate:
 *
 * Ignore this structure.
 **/
struct _DeeIndexPrivate
{
  DeeModel       *model;
  DeeAnalyzer    *analyzer;
  DeeModelReader *reader;
};

enum
{
  PROP_0,
  PROP_MODEL,
  PROP_ANALYZER,
  PROP_READER
};

/* GObject stuff */
static void
dee_index_finalize (GObject *object)
{
  DeeIndexPrivate *priv = DEE_INDEX (object)->priv;

  if (priv->model)
    {
      g_object_unref (priv->model);
      priv->model = NULL;
    }
  if (priv->analyzer)
    {
      g_object_unref (priv->analyzer);
      priv->analyzer = NULL;
    }
  if (priv->reader)
    {
      dee_model_reader_destroy (priv->reader);
      g_free (priv->reader);
      priv->reader = NULL;
    }

  G_OBJECT_CLASS (dee_index_parent_class)->finalize (object);
}

static void
dee_index_set_property (GObject       *object,
                        guint          id,
                        const GValue  *value,
                        GParamSpec    *pspec)
{
  DeeIndexPrivate  *priv = DEE_INDEX (object)->priv;
  DeeModelReader   *reader;

  switch (id)
  {
    case PROP_MODEL:
      priv->model = DEE_MODEL (g_value_dup_object (value));
      break;
    case PROP_ANALYZER:
      priv->analyzer = DEE_ANALYZER (g_value_dup_object(value));
      break;
    case PROP_READER:
      priv->reader = g_new0 (DeeModelReader, 1);
      reader = (DeeModelReader*) g_value_get_pointer (value);
      memcpy (priv->reader, reader, sizeof (DeeModelReader));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
  }
}

static void
dee_index_get_property (GObject     *object,
                        guint        id,
                        GValue      *value,
                        GParamSpec  *pspec)
{
  DeeIndexPrivate *priv = DEE_INDEX (object)->priv;

  switch (id)
  {
    case PROP_MODEL:
      g_value_set_object (value, priv->model);
      break;
    case PROP_ANALYZER:
      g_value_set_object (value, priv->analyzer);
      break;
    case PROP_READER:
      g_value_set_pointer (value, priv->reader);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
  }
}

static void
dee_index_class_init (DeeIndexClass *klass)
{
  GParamSpec    *pspec;
  GObjectClass  *obj_class = G_OBJECT_CLASS (klass);

  obj_class->finalize     = dee_index_finalize;
  obj_class->get_property = dee_index_get_property;
  obj_class->set_property = dee_index_set_property;

  /**
   * DeeIndex:model:
   *
   * The #DeeModel being indexed
   */
  pspec = g_param_spec_object ("model", "Model",
                               "The model being indexed",
                               DEE_TYPE_MODEL,
                               G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                               | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_MODEL, pspec);

  /**
   * DeeIndex:analyzer:
   *
   * The #DeeAnalyzer used to analyze terms extracted by the model reader
   *
   * Type: DeeAnalyzer
   */
  pspec = g_param_spec_object("analyzer", "Analyzer",
                               "Analyzing terms extracted by the reader",
                               DEE_TYPE_ANALYZER,
                               G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                               | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_ANALYZER, pspec);

  /**
     * DeeIndex:reader:
     *
     * The #DeeModelReader used to extract terms from rows in the model
     *
     * Type: DeeModelReader
     */
    pspec = g_param_spec_pointer("reader", "Reader",
                                 "The reader extracting terms for each row",
                                 G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY
                                 | G_PARAM_STATIC_STRINGS);
    g_object_class_install_property (obj_class, PROP_READER, pspec);

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeIndexPrivate));
}

static void
dee_index_init (DeeIndex *self)
{
  self->priv = DEE_INDEX_GET_PRIVATE (self);
}

/**
 * dee_index_lookup:
 * @self: The index to perform the lookup in
 * @term: The term to look up on
 * @flags: A bitmask of #DeeTermMatchFlag<!-- --> to control how matching is
 *         done
 *
 * Returns: (transfer full): A #DeeResultSet. Free with g_object_unref().
 */
DeeResultSet*
dee_index_lookup (DeeIndex          *self,
                  const gchar       *term,
                  DeeTermMatchFlag  flags)
{
  DeeIndexClass *klass;
  
  g_return_val_if_fail (DEE_IS_INDEX (self), NULL);

  klass = DEE_INDEX_GET_CLASS (self);

  return (* klass->lookup) (self, term, flags);
}

/**
 * dee_index_lookup_one:
 * @self: The index to do the lookup in
 * @term: The exact term to match
 *
 * Convenience function in for cases where you have a priori guarantee that
 * a dee_index_lookup() call will return exactly 0 or 1 row. If the lookup
 * returns more than 1 row a warning will be printed on standard error and
 * %NULL will be returned.
 *
 * The typical use case for this function is if you need something akin to
 * a primary key in a relational database.
 *
 * Return value: (transfer none): A #DeeModelIter pointing to the matching
 *               row or %NULL in case no rows matches @term
 */
DeeModelIter*
dee_index_lookup_one (DeeIndex    *self,
                      const gchar *term)
{
  DeeResultSet *results;
  DeeModelIter *iter;

  g_return_val_if_fail (DEE_IS_INDEX (self), NULL);

  results = dee_index_lookup (self, term, DEE_TERM_MATCH_EXACT);

  if (!dee_result_set_has_next (results))
    {
      g_object_unref (results);
      return NULL;
    }

  iter = dee_result_set_next (results);

  if (dee_result_set_has_next (results))
    {
      g_warning ("dee_index_lookup_one(index, '%s') expects exactly 0 or 1"
                 " rows in the result set. Found %u",
                 term, dee_result_set_get_n_rows (results));
      g_object_unref (results);
      return NULL;
    }

  g_object_unref (results);
  return iter;

}

/**
 * dee_index_foreach:
 * @self: The index to iterate over
 * @start_term: The term to start from or %NULL to iterate over all terms
 * @func: (scope call): Called for each term in the index
 * @userdata: (closure): Arbitrary data to pass back to @func
 *
 * Iterate over an index optionally starting from some given term. Note that
 * unordered indexes (like #DeeHashIndex) has undefined behaviour with
 * this method.
 */
void
dee_index_foreach (DeeIndex         *self,
                   const gchar      *start_term,
                   DeeIndexIterFunc  func,
                   gpointer          userdata)
{
  DeeIndexClass *klass;

  g_return_if_fail (DEE_IS_INDEX (self));

  klass = DEE_INDEX_GET_CLASS (self);

  (* klass->foreach) (self, start_term, func, userdata);
}

/**
 * dee_index_get_model:
 * @self: The index to get the model for
 *
 * Get the model being indexed by this index
 *
 * Returns: (transfer none): The #DeeModel being indexed by this index
 */
DeeModel*
dee_index_get_model (DeeIndex *self)
{
  g_return_val_if_fail (DEE_IS_INDEX (self), NULL);

  return self->priv->model;
}

/**
 * dee_index_get_analyzer:
 * @self: The index to get the analyzer for
 *
 * Get the analyzer being used to analyze terms extracted with the
 * #DeeModelReader used by this index.
 *
 * Returns: (transfer none): The #DeeAnalyzer used to analyze terms with
 */
DeeAnalyzer*
dee_index_get_analyzer (DeeIndex *self)
{
  g_return_val_if_fail (DEE_IS_INDEX (self), NULL);

  return self->priv->analyzer;
}

/**
 * dee_index_get_reader:
 * @self: The index to get the reader for
 *
 * Get the reader being used to extract terms from rows in the model
 *
 * Returns: (transfer none): The #DeeModelReader used to extract terms with
 */
DeeModelReader*
dee_index_get_reader (DeeIndex *self)
{
  g_return_val_if_fail (DEE_IS_INDEX (self), NULL);

  return self->priv->reader;
}

/**
 * dee_index_get_n_terms:
 * @self: The index to get the number of terms for
 *
 * Get the number of terms in the index
 *
 * Returns: The number of unique terms in the index
 */
guint
dee_index_get_n_terms (DeeIndex *self)
{
  DeeIndexClass *klass;

  g_return_val_if_fail (DEE_IS_INDEX (self), 0);

  klass = DEE_INDEX_GET_CLASS (self);

  return (* klass->get_n_terms) (self);
}

/**
 * dee_index_get_n_rows:
 * @self: The index to get the number of rows for
 *
 * Get the number of indexed rows. A row is only indexed if it has at least one
 * term associated with it. If the analyzer has returned 0 terms then the row
 * is omitted from the index.
 *
 * Returns: The number of rows in the index. Note that this may less than or
 *          equal to dee_model_get_n_rows().
 */
guint
dee_index_get_n_rows (DeeIndex *self)
{
  DeeIndexClass *klass;

  g_return_val_if_fail (DEE_IS_INDEX (self), 0);

  klass = DEE_INDEX_GET_CLASS (self);

  return (* klass->get_n_rows) (self);
}

/**
 * dee_index_get_n_rows_for_term:
 * @self: The index to inspect
 * @term: The term to look for
 *
 * Get the number of rows that matches a given term
 *
 * Returns: The number of rows in the index registered for the given term
 */
guint
dee_index_get_n_rows_for_term (DeeIndex *self,
                               const gchar   *term)
{
  DeeIndexClass *klass;

  g_return_val_if_fail (DEE_IS_INDEX (self), 0);

  klass = DEE_INDEX_GET_CLASS (self);

  return (* klass->get_n_rows_for_term) (self, term);
}

/**
 * dee_index_get_supported_term_match_flags:
 * @self: The index to inspect
 *
 * Get the #DeeTermMatchFlag<!-- --> supported by this #DeeIndex instance
 *
 * Returns: A bit mask of the acceptedd #DeeTermMatchFlag<!-- -->s
 */
guint
dee_index_get_supported_term_match_flags (DeeIndex *self)
{
  DeeIndexClass *klass;

  g_return_val_if_fail (DEE_IS_INDEX (self), 0);

  klass = DEE_INDEX_GET_CLASS (self);

  return (* klass->get_supported_term_match_flags) (self);
}
