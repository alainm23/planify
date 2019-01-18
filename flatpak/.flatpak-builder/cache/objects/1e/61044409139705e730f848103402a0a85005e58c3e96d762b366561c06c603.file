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
 * SECTION:dee-analyzer
 * @short_description: Primary gateway for data indexing
 * @include: dee.h
 *
 * A #DeeAnalyzer takes a text stream, splits it into tokens, and runs the
 * tokens through a series of filtering steps. Optionally outputs collation
 * keys for the terms.
 *
 * One of the important use cases of analyzers in Dee is as vessel for the
 * indexing logic for creating a #DeeIndex from a #DeeModel.
 *
 * The recommended way to implement your own custom analyzers are by either
 * adding term filters to a #DeeAnalyzer or #DeeTextAnalyzer instance with
 * dee_analyzer_add_term_filter() and/or
 * derive your own subclass that overrides the dee_analyzer_tokenize() method.
 * Should you have very special requirements it is possible to reimplement
 * all aspects of the analyzer class though.
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h>
#include "dee-analyzer.h"

G_DEFINE_TYPE (DeeAnalyzer,
               dee_analyzer,
               G_TYPE_OBJECT);

#define DEE_ANALYZER_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_ANALYZER, DeeAnalyzerPrivate))

typedef struct {
  DeeTermFilterFunc filter_func;
  gpointer          data;
  GDestroyNotify    destroy;
} DeeTermFilter;

/**
 * DeeAnalyzerPrivate:
 *
 * Ignore this structure.
 **/
struct _DeeAnalyzerPrivate
{
  /* A list of DeeTermFilters */
  GSList *term_filters;

  DeeTermList *term_pool;
};

enum
{
  PROP_0,
};

/*
 * DeeAnalyzer forward declarations
 */
static void           dee_analyzer_analyze_real          (DeeAnalyzer   *self,
                                                          const gchar   *data,
                                                          DeeTermList   *terms_out,
                                                          DeeTermList   *colkeys_out);

static void           dee_analyzer_tokenize_real         (DeeAnalyzer   *self,
                                                          const gchar   *data,
                                                          DeeTermList   *terms_out);

static void          dee_analyzer_add_term_filter_real   (DeeAnalyzer       *self,
                                                          DeeTermFilterFunc  filter_func,
                                                          gpointer           filter_data,
                                                          GDestroyNotify     filter_destroy);

static gchar*         dee_analyzer_collate_key_real      (DeeAnalyzer   *self,
                                                          const gchar   *data);

static gint           dee_analyzer_collate_cmp_real      (DeeAnalyzer   *self,
                                                          const gchar   *key1,
                                                          const gchar   *key2);

/* Private forward declarations */
void                  _dee_analyzer_term_filter_free      (DeeTermFilter *filter);

DeeTermFilter*        _dee_analyzer_term_filter_new       (DeeTermFilterFunc filter_func,
                                                           gpointer          data,
                                                           GDestroyNotify    destroy);

void
_dee_analyzer_term_filter_free (DeeTermFilter *filter)
{
  if (filter->destroy)
    filter->destroy (filter->data);

  g_slice_free (DeeTermFilter, filter);
}

DeeTermFilter*
_dee_analyzer_term_filter_new (DeeTermFilterFunc filter_func,
                               gpointer          data,
                               GDestroyNotify    destroy)
{
  DeeTermFilter *self;

  self = g_slice_new (DeeTermFilter);
  self->filter_func = filter_func;
  self->data = data;
  self->destroy = destroy;

  return self;
}


/* GObject stuff */
static void
dee_analyzer_finalize (GObject *object)
{
  DeeAnalyzerPrivate *priv = DEE_ANALYZER (object)->priv;

  g_slist_free_full (priv->term_filters,
                     (GDestroyNotify) _dee_analyzer_term_filter_free);
  priv->term_filters = NULL;

  if (priv->term_pool)
    {
      g_object_unref (priv->term_pool);
      priv->term_pool = NULL;
    }

  G_OBJECT_CLASS (dee_analyzer_parent_class)->finalize (object);
}

static void
dee_analyzer_set_property (GObject       *object,
                           guint          id,
                           const GValue  *value,
                           GParamSpec    *pspec)
{
  //DeeAnalyzerPrivate *priv = DEE_ANALYZER (object)->priv;
  
  switch (id)
  {
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
  }
}

static void
dee_analyzer_get_property (GObject     *object,
                           guint        id,
                           GValue      *value,
                           GParamSpec  *pspec)
{
  switch (id)
  {
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
  }
}

static void
dee_analyzer_class_init (DeeAnalyzerClass *klass)
{
  GObjectClass  *obj_class = G_OBJECT_CLASS (klass);

  obj_class->finalize     = dee_analyzer_finalize;
  obj_class->get_property = dee_analyzer_get_property;
  obj_class->set_property = dee_analyzer_set_property;

  klass->analyze = dee_analyzer_analyze_real;
  klass->tokenize = dee_analyzer_tokenize_real;
  klass->add_term_filter = dee_analyzer_add_term_filter_real;
  klass->collate_key = dee_analyzer_collate_key_real;
  klass->collate_cmp = dee_analyzer_collate_cmp_real;

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeAnalyzerPrivate));
}

static void
dee_analyzer_init (DeeAnalyzer *self)
{
  DeeAnalyzerPrivate *priv;

  priv = self->priv = DEE_ANALYZER_GET_PRIVATE (self);
  
  priv->term_filters = NULL;
  priv->term_pool = (DeeTermList*) g_object_new (DEE_TYPE_TERM_LIST, NULL);
}

/*
 * Default implementations
 */
static void
dee_analyzer_analyze_real (DeeAnalyzer   *self,
                           const gchar   *data,
                           DeeTermList   *terms_out,
                           DeeTermList   *colkeys_out)
{
  DeeAnalyzerPrivate *priv;
  GSList             *iter;
  DeeTermList        *in, *out, *tmp, *tmp_term_pool;
  gint                i;
  gchar              *colkey;
  const gchar        *term;

  g_return_if_fail (DEE_IS_ANALYZER (self));
  g_return_if_fail (data != NULL);

  priv = self->priv;

  dee_term_list_clear (priv->term_pool);
  tmp_term_pool = dee_term_list_clone (priv->term_pool);

  if (terms_out)
    dee_term_list_clear (terms_out);
  if (colkeys_out)
    dee_term_list_clear (colkeys_out);

  dee_analyzer_tokenize (self, data, priv->term_pool);

  /* Run terms through all filters. Result is that we'll have
   * the final terms in the 'in' term list */
  in = priv->term_pool;
  out = tmp_term_pool;
  for (iter = priv->term_filters; iter; iter = iter->next)
    {
      DeeTermFilter *filter = (DeeTermFilter*) iter->data;
      filter->filter_func (in, out, filter->data);

      /* Clear and swap in/out buffers */
      tmp = dee_term_list_clear (in);
      in = out;
      out = tmp;
    }

  /* Copy terms to output and generate colkeys if requested */
  for (i = 0; i < dee_term_list_num_terms (in); i++)
    {
      term = dee_term_list_get_term (in, i);
      if (terms_out)
        dee_term_list_add_term (terms_out, term);
      if (colkeys_out)
        {
          colkey = dee_analyzer_collate_key (self, term);
          dee_term_list_add_term (colkeys_out, colkey);
          g_free (colkey);
        }
    }

  g_object_unref (tmp_term_pool);
}

/* Default tokenization is a no-op */
static void
dee_analyzer_tokenize_real (DeeAnalyzer   *self,
                            const gchar   *data,
                            DeeTermList   *terms_out)
{
  g_return_if_fail (DEE_IS_ANALYZER (self));
  g_return_if_fail (data != NULL);
  g_return_if_fail (DEE_IS_TERM_LIST (terms_out));

  dee_term_list_add_term (terms_out, data);
}

static void
dee_analyzer_add_term_filter_real (DeeAnalyzer       *self,
                                   DeeTermFilterFunc  filter_func,
                                   gpointer           filter_data,
                                   GDestroyNotify     filter_destroy)
{
  DeeAnalyzerPrivate *priv;

  g_return_if_fail (DEE_IS_ANALYZER (self));
  g_return_if_fail (filter_func != NULL);

  priv = self->priv;
  priv->term_filters = g_slist_append (priv->term_filters,
                                 _dee_analyzer_term_filter_new(filter_func,
                                                               filter_data,
                                                               filter_destroy));
}

static gchar*
dee_analyzer_collate_key_real (DeeAnalyzer   *self,
                               const gchar   *data)
{
  g_return_val_if_fail (DEE_IS_ANALYZER (self), NULL);
  g_return_val_if_fail (data != NULL, NULL);

  return g_strdup (data);
}

gint
dee_analyzer_collate_cmp_real (DeeAnalyzer   *self,
                               const gchar   *key1,
                               const gchar   *key2)
{
  g_return_val_if_fail (DEE_IS_ANALYZER (self), 0);
  g_return_val_if_fail (key1 != NULL, 0);
  g_return_val_if_fail (key2 != NULL, 0);

  return strcmp (key1, key2);
}

/*
 * Public API
 */

/**
 * dee_analyzer_analyze:
 * @self: The analyzer to use
 * @data: The input data to analyze
 * @terms_out: (allow-none): A #DeeTermList to place the generated terms in.
 *                           If %NULL to terms are generated
 * @colkeys_out: (allow-none): A #DeeTermList to place generated collation keys in.
 *                             If %NULL no collation keys are generated
 *
 * Extract terms and or collation keys from some input data (which is normally,
 * but not necessarily, a UTF-8 string).
 *
 * The terms and corresponding collation keys will be written in order to the
 * provided #DeeTermList<!-- -->s.
 *
 * Implementation notes for subclasses:
 * The analysis process must call dee_analyzer_tokenize() and run the tokens
 * through all term filters added with dee_analyzer_add_term_filter().
 * Collation keys must be generated with dee_analyzer_collate_key().
 */
void
dee_analyzer_analyze (DeeAnalyzer   *self,
                      const gchar   *data,
                      DeeTermList   *terms_out,
                      DeeTermList   *colkeys_out)
{
  DeeAnalyzerClass *klass;

  g_return_if_fail (DEE_IS_ANALYZER (self));

  klass = DEE_ANALYZER_GET_CLASS (self);

  (* klass->analyze) (self, data, terms_out, colkeys_out);
}

/**
 * dee_analyzer_tokenize:
 * @self: The analyzer to use
 * @data: The input data to analyze
 * @terms_out:  A #DeeTermList to place the generated tokens in.
 *
 * Tokenize some input data (which is normally, but not necessarily,
 * a UTF-8 string).
 *
 * Tokenization splits the input data into constituents (in most cases words),
 * but does not run it through any of the term filters set for the analyzer.
 * It is undefined if the tokenization process itself does any normalization.
 */
void
dee_analyzer_tokenize (DeeAnalyzer   *self,
                       const gchar   *data,
                       DeeTermList   *terms_out)
{
  DeeAnalyzerClass *klass;

  g_return_if_fail (DEE_IS_ANALYZER (self));

  klass = DEE_ANALYZER_GET_CLASS (self);

  (* klass->tokenize) (self, data, terms_out);
}

/**
 * dee_analyzer_add_term_filter:
 * @self: The analyzer to add a term filter to
 * @filter_func: (scope notified): Function to call
 * @filter_data: (closure): Data to pass to @filter_func when it is invoked
 * @filter_destroy: (allow-none): Called on @filter_data when the #DeeAnalyzer
 *                                owning the filter is destroyed
 *
 * Register a #DeeTermFilterFunc to be called whenever dee_analyzer_analyze()
 * is called.
 *
 * Term filters can be used to normalize, add, or remove terms from an input
 * data stream.
 */
void
dee_analyzer_add_term_filter (DeeAnalyzer       *self,
                              DeeTermFilterFunc  filter_func,
                              gpointer           filter_data,
                              GDestroyNotify     filter_destroy)
{
  DeeAnalyzerClass *klass;

  g_return_if_fail (DEE_IS_ANALYZER (self));

  klass = DEE_ANALYZER_GET_CLASS (self);

  (* klass->add_term_filter) (self, filter_func, filter_data, filter_destroy);
}

/**
 * dee_analyzer_collate_key:
 * @self: The analyzer to generate a collation key with
 * @data: The input data to generate a collation key for
 *
 * Generate a collation key for a set of input data (usually a UTF-8 string
 * passed through tokenization and term filters of the analyzer).
 *
 * The default implementation just calls g_strdup().
 *
 * Returns: A newly allocated collation key. Use dee_analyzer_collate_cmp() or
 *          dee_analyzer_collate_cmp_func() to compare collation keys. Free
 *          with g_free().
 */
gchar*
dee_analyzer_collate_key (DeeAnalyzer   *self,
                          const gchar   *data)
{
  DeeAnalyzerClass *klass;

  g_return_val_if_fail (DEE_IS_ANALYZER (self), NULL);

  klass = DEE_ANALYZER_GET_CLASS (self);

  return (* klass->collate_key) (self, data);
}

/**
 * dee_analyzer_collate_cmp:
 * @self: The analyzer to use when comparing collation keys
 * @key1: The first collation key to compare
 * @key2: The second collation key to compare
 *
 * Compare collation keys generated by dee_analyzer_collate_key() with similar
 * semantics as strcmp(). See also dee_analyzer_collate_cmp_func() if you
 * need a version of this function that works as a #GCompareDataFunc.
 *
 * The default implementation in #DeeAnalyzer just uses strcmp().
 *
 * Returns: -1, 0 or 1, if @key1 is &lt;, == or &gt; than @key2.
 */
gint
dee_analyzer_collate_cmp (DeeAnalyzer   *self,
                          const gchar   *key1,
                          const gchar   *key2)
{
  DeeAnalyzerClass *klass;

  g_return_val_if_fail (DEE_IS_ANALYZER (self), 0);

  klass = DEE_ANALYZER_GET_CLASS (self);

  return (* klass->collate_cmp) (self, key1, key2);
}

/**
 * dee_analyzer_collate_cmp_func:
 * @key1: The first key to compare
 * @key2: The second key to compare
 * @analyzer: The #DeeAnalyzer to use for the comparison
 *
 * A #GCompareDataFunc using a #DeeAnalyzer to compare the keys. This is just
 * a convenience wrapper around dee_analyzer_collate_cmp().
 *
 * Returns: -1, 0 or 1, if @key1 is &lt;, == or &gt; than @key2.
 */
gint
dee_analyzer_collate_cmp_func (const gchar *key1,
                               const gchar *key2,
                               gpointer     analyzer)
{
  return dee_analyzer_collate_cmp ((DeeAnalyzer*)analyzer, key1, key2);
}

DeeAnalyzer*
dee_analyzer_new (void)
{
  return (DeeAnalyzer*) g_object_new (DEE_TYPE_ANALYZER, NULL);
}

