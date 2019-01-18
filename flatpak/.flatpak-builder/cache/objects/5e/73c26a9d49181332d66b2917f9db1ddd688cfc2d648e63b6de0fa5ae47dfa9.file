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
 * SECTION:dee-term-list
 * @short_description: A simple collection type representing a list of indexed terms for a row in a #DeeIndex
 * @include: dee.h
 *
 * #DeeTermList is a simple list type containing the indexed terms of a row
 * in a #DeeModel as recorded in a #DeeIndex. The terms are extracted from the
 * model by using a #DeeAnalyzer.
 *
 * The default implementation of #DeeTermList stores all terms in a string pool
 * and reuses terms from that string pool for the entire lifetime of the
 * term list. That is, even if you call dee_term_list_clear() on it. This
 * behaviour will save a lot of reallocations and g_strdup()<!-- -->s provided
 * there is reuse in the terms over time.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h> /* memcpy() */

#include "dee-term-list.h"
#include "trace-log.h"

G_DEFINE_TYPE (DeeTermList, dee_term_list, G_TYPE_OBJECT);

#define DEE_TERM_LIST_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_TERM_LIST, DeeTermListPrivate))

/*
 * FORWARDS
 */
static const gchar* dee_term_list_get_term_real        (DeeTermList *self,
                                                        guint        n);

static DeeTermList* dee_term_list_add_term_real        (DeeTermList *self,
                                                        const gchar *term);

static guint        dee_term_list_num_terms_real       (DeeTermList *self);

static DeeTermList* dee_term_list_clear_real           (DeeTermList     *self);

static DeeTermList* dee_term_list_clone_real           (DeeTermList     *self);

/*
 * GOBJECT VOODOO
 */

/**
 * DeeTermListPrivate:
 *
 * Ignore this structure.
 **/
struct _DeeTermListPrivate
{
  /* String pool - reused to minimize strdup()ing. Allocated lazily to make
   * clone more efficient. Chunk are shared with clones and since GStringChunk
   * is not ref counted we use a GObject instance to help with that */
  GStringChunk *chunk;

  /* Dummy helper object to implement ref counting on our string chunk */
  GObject *chunk_counter;

  /* The actual terms, in order. The strings are stored in priv->chunk
   * so they shouldn't be freed by this instance. Allocated lazily to make
   * cloning more efficient */
  GPtrArray    *terms;
};

enum
{
  PROP_0,
};

#define CHECK_LAZY_SETUP(term_list) \
  if (G_UNLIKELY(term_list->priv->chunk == NULL)) \
    { \
      /* The number 64 is chosen as a an estimate of the length of URIs to files
       * under the user's home dir somewhere */ \
      term_list->priv->chunk = g_string_chunk_new (64); \
\
      /* Create dummy ref count on chunk_counter  */ \
      term_list->priv->chunk_counter = g_object_new (G_TYPE_OBJECT, NULL); \
      g_object_set_data_full (term_list->priv->chunk_counter, \
                              "chunk", \
                              term_list->priv->chunk, \
                              (GDestroyNotify) g_string_chunk_free);\
\
      /* Making room for 10 terms by default is probably sane */ \
      term_list->priv->terms = g_ptr_array_sized_new (10); \
    }

/* GObject stuff */
static void
dee_term_list_finalize (GObject *object)
{
  DeeTermListPrivate *priv = DEE_TERM_LIST (object)->priv;

  if (priv->chunk_counter)
    {
      g_object_unref (priv->chunk_counter);
      priv->chunk = NULL;
      priv->chunk_counter = NULL;
    }

  if (priv->terms)
    {
      g_ptr_array_unref (priv->terms);
      priv->terms = NULL;
    }

  G_OBJECT_CLASS (dee_term_list_parent_class)->finalize (object);
}

static void
dee_term_list_class_init (DeeTermListClass *klass)
{
  // GParamSpec    *pspec;
  GObjectClass  *obj_class = G_OBJECT_CLASS (klass);

  obj_class->finalize     = dee_term_list_finalize;

  klass->get_term  = dee_term_list_get_term_real;
  klass->add_term  = dee_term_list_add_term_real;
  klass->num_terms = dee_term_list_num_terms_real;
  klass->clear     = dee_term_list_clear_real;
  klass->clone     = dee_term_list_clone_real;

  /*
  pspec = g_param_spec_pointer ("filter", "Filter",
                                "Filtering rules applied to the original model",
                                G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                                | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_FILTER, pspec);
  */

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeTermListPrivate));
}

static void
dee_term_list_init (DeeTermList *self)
{
  DeeTermListPrivate *priv;

  priv = self->priv = DEE_TERM_LIST_GET_PRIVATE (self);

  /* The chunk and terms are allocated lazily, to make clone() work more
   * eficiently */
  priv->chunk = NULL;
  priv->terms = NULL;
}

/*
 * API
 */

/**
 * dee_term_list_get_term:
 * @self: The term list to get the @n<!-- -->th term from
 * @n: The (zero based) offset into the term list
 *
 * Get the n'th term in the list.
 *
 * Note that in the default implementation it is guaranteed that the returned
 * string is valid for the entire lifetime of the #DeeTermList.
 *
 * Returns: The @n<!-- -->th string held in the term list
 */
const gchar*
dee_term_list_get_term (DeeTermList *self,
                        guint        n)
{
  DeeTermListClass *klass;

  g_return_val_if_fail (DEE_IS_TERM_LIST (self), NULL);

  klass = DEE_TERM_LIST_GET_CLASS (self);

  return (* klass->get_term) (self, n);
}

/**
 * dee_term_list_add_term:
 * @self: The term list to add a term to
 * @term: The term to add
 *
 * Add a term to the termlist. Note that it is possible to add a term multiple
 * times. The effect of this is determined by the #DeeModelIndex consuming the
 * #DeeTermList.
 *
 * Returns: (transfer none): Always returns @self
 */
DeeTermList*
dee_term_list_add_term (DeeTermList *self,
                        const gchar *term)
{
  DeeTermListClass *klass;

  g_return_val_if_fail (DEE_IS_TERM_LIST (self), NULL);
  g_return_val_if_fail (term != NULL, NULL);

  klass = DEE_TERM_LIST_GET_CLASS (self);

  return (* klass->add_term) (self, term);
}

/**
 * dee_term_list_num_terms:
 * @self: The term list to check the number of terms in
 *
 * Returns: The number of terms in the term list
 */
guint
dee_term_list_num_terms (DeeTermList *self)
{
  DeeTermListClass *klass;

  g_return_val_if_fail (DEE_IS_TERM_LIST (self), 0);

  klass = DEE_TERM_LIST_GET_CLASS (self);

  return (* klass->num_terms) (self);
}

/**
 * dee_term_list_clear:
 * @self: The term list to clear
 *
 * Remove all terms from a term list making it ready for reuse. Note that
 * term list implementations will often have optimized memory allocation
 * schemes so reuse is often more efficient than allocating a new term list
 * each time you need it.
 *
 * Returns: (transfer none): Always returns @self
 */
DeeTermList*
dee_term_list_clear (DeeTermList     *self)
{
  DeeTermListClass *klass;

  g_return_val_if_fail (DEE_IS_TERM_LIST (self), NULL);

  klass = DEE_TERM_LIST_GET_CLASS (self);

  return (* klass->clear) (self);
}

/**
 * dee_term_list_clone:
 * @self: The term list to clone
 *
 * Create a copy of @self that shares the underlying string pool and containing
 * a list of terms as currently set in @self.
 *
 * Subsequently freeing the original and keeping the clone around is not a
 * problem. The clone works as a standalone term list. The only gotcha may be
 * threading issues because of concurrent access to the shared string pool.
 *
 * Creating a clone very efficient since only very little memory allocation
 * is required. It's advised that you use a clone instead a new instance
 * whenever you work over a common corpus of strings.
 *
 * It is also worth noting that terms obtained from the original term list
 * and a clone can be compared directly as pointers (fx. with g_direct_equal()).
 * This is because they share the underlying string pool.
 *
 * Returns: (transfer full): A newly allocated term list.
 *                           Free with g_object_unref().
 */
DeeTermList*
dee_term_list_clone (DeeTermList *self)
{
  DeeTermListClass *klass;

  g_return_val_if_fail (DEE_IS_TERM_LIST (self), NULL);

  klass = DEE_TERM_LIST_GET_CLASS (self);

  return (* klass->clone) (self);
}

/*
 * IMPLEMENTATION
 */

static const gchar*
dee_term_list_get_term_real (DeeTermList *self,
                             guint        n)
{
  DeeTermListPrivate *priv;

  g_return_val_if_fail (DEE_IS_TERM_LIST(self), NULL);

  CHECK_LAZY_SETUP (self);

  priv = self->priv;
  g_return_val_if_fail (n < priv->terms->len, NULL);

  return g_ptr_array_index (priv->terms, n);
}

static DeeTermList*
dee_term_list_add_term_real (DeeTermList *self,
                             const gchar *term)
{
  DeeTermListPrivate *priv;
  gchar              *cterm;

  g_return_val_if_fail (DEE_IS_TERM_LIST(self), NULL);
  g_return_val_if_fail (term != NULL, NULL);

  CHECK_LAZY_SETUP (self);

  priv = self->priv;
  cterm = g_string_chunk_insert_const (priv->chunk, term);

  g_ptr_array_add (priv->terms, cterm);

  return self;
}

static guint
dee_term_list_num_terms_real (DeeTermList *self)
{
  DeeTermListPrivate *priv;

  g_return_val_if_fail (DEE_IS_TERM_LIST(self), 0);

  CHECK_LAZY_SETUP (self);

  priv = self->priv;
  return priv->terms->len;
}

static DeeTermList*
dee_term_list_clear_real (DeeTermList *self)
{
  /*
   * The idea here is that we clear only the term list (priv->terms),
   * but not the string pool (priv->chunk). This will work well assuming that
   * there is a fair deal of reuse in the term.
   */
  DeeTermListPrivate *priv;
  guint               i;

  g_return_val_if_fail (DEE_IS_TERM_LIST(self), NULL);

  CHECK_LAZY_SETUP (self);

  priv = self->priv;

  if (priv->terms->len == 0)
    return self;

  /* Clear the term list backwards to avoid memory shuffling */
  for (i = priv->terms->len; i > 0; i--)
    g_ptr_array_remove_index_fast (priv->terms, i - 1);

  return self;
}

static DeeTermList*
dee_term_list_clone_real (DeeTermList     *self)
{
  DeeTermListPrivate *priv, *clone_priv;
  DeeTermList        *clone;

  g_return_val_if_fail (DEE_IS_TERM_LIST(self), NULL);

  CHECK_LAZY_SETUP (self);

  priv = self->priv;

  clone = (DeeTermList*) g_object_new (DEE_TYPE_TERM_LIST, NULL);
  clone_priv = clone->priv;
  clone_priv->chunk = priv->chunk;
  clone_priv->chunk_counter = g_object_ref (priv->chunk_counter);
  clone_priv->terms = g_ptr_array_sized_new (priv->terms->len);

  memcpy (clone_priv->terms->pdata, priv->terms->pdata,
          sizeof (gpointer) * priv->terms->len);
  clone_priv->terms->len = priv->terms->len;

  return clone;
}

