/*
 * Copyright (C) 2010-2011 Canonical, Ltd.
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
 * Authored by Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

#if !defined (_DEE_H_INSIDE) && !defined (DEE_COMPILATION)
#error "Only <dee.h> can be included directly."
#endif

#ifndef _HAVE_DEE_INDEX_H
#define _HAVE_DEE_INDEX_H

#include <glib.h>
#include <glib-object.h>
#include <dee-model.h>
#include <dee-model-reader.h>
#include <dee-term-list.h>
#include <dee-result-set.h>
#include <dee-analyzer.h>

G_BEGIN_DECLS

#define DEE_TYPE_INDEX (dee_index_get_type ())

#define DEE_INDEX(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_INDEX, DeeIndex))

#define DEE_INDEX_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_INDEX, DeeIndexClass))

#define DEE_IS_INDEX(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_INDEX))

#define DEE_IS_INDEX_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_INDEX))

#define DEE_INDEX_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DBUS_TYPE_INDEX, DeeIndexClass))

typedef struct _DeeIndexClass DeeIndexClass;
typedef struct _DeeIndex DeeIndex;
typedef struct _DeeIndexPrivate DeeIndexPrivate;

/**
 * DeeIndexIterFunc:
 * @key: A key in the index being traversed
 * @rows: A #DeeResultSet. Do not free or modify.
 * @userdata: (closure): The pointer passed to dee_index_foreach()
 *
 * The signature of the function passed to dee_index_foreach().
 *
 * Be cautious if you plan on modifying the rows in the model via the
 * DeeModelIter<!-- -->s you find. Your code may have to be reentrant since
 * the index may change in reaction to the changes in the model. It's not
 * impossible to do this in a non-broken manner, but it may likely require
 * you calling dee_model_freeze_signals() and dee_model_thaw_signals() at
 * strategic points.
 *
 * Returns: %FALSE if iteration should stop, %TRUE if it should continue
 */
typedef gboolean        (*DeeIndexIterFunc) (const gchar  *key,
                                             DeeResultSet *rows,
                                             gpointer      userdata);

/**
 * DeeTermMatchFlag:
 * @DEE_TERM_MATCH_EXACT: Match terms byte for byte as specified in the
 *                        query string
 * @DEE_TERM_MATCH_PREFIX: Match if the indexed term begins with the byte string
 *                         being queried by. This is also sometimes known as
 *                         truncated- or wildcard queries
 *
 * Flags passed to dee_index_lookup() to control how matching is done.
 * Note that it is not required that index backends support more than just
 * #DEE_TERM_MATCH_EXACT.
 *
 * You can query for the supported flags with
 * dee_index_get_supported_term_match_flags().
 */
typedef enum
{
  DEE_TERM_MATCH_EXACT = 1 << 0,
  DEE_TERM_MATCH_PREFIX = 1 << 1
} DeeTermMatchFlag;

/**
 * DeeIndex:
 *
 * All fields in the DeeIndex structure are private and should never be
 * accessed directly
 */
struct _DeeIndex
{
  /*< private >*/
  GObject          parent;

  DeeIndexPrivate *priv;
};

struct _DeeIndexClass
{
  GObjectClass     parent_class;

  /*< public >*/
  DeeResultSet*  (* lookup)             (DeeIndex         *self,
                                         const gchar      *term,
                                         DeeTermMatchFlag  flags);

  void           (* foreach)            (DeeIndex          *self,
                                         const gchar       *start_term,
                                         DeeIndexIterFunc   func,
                                         gpointer           userdata);

  guint          (* get_n_terms)        (DeeIndex     *self);

  guint          (* get_n_rows)         (DeeIndex     *self);

  guint          (* get_n_rows_for_term)(DeeIndex     *self,
                                         const gchar       *term);

  guint          (*get_supported_term_match_flags) (DeeIndex *self);

  /*< private >*/
  void     (*_dee_index_1) (void);
  void     (*_dee_index_2) (void);
  void     (*_dee_index_3) (void);
  void     (*_dee_index_4) (void);
  void     (*_dee_index_5) (void);
};

GType                dee_index_get_type           (void);

DeeResultSet*        dee_index_lookup             (DeeIndex         *self,
                                                   const gchar      *term,
                                                   DeeTermMatchFlag  flags);

DeeModelIter*        dee_index_lookup_one         (DeeIndex         *self,
                                                   const gchar      *term);

void                 dee_index_foreach            (DeeIndex         *self,
                                                   const gchar      *start_term,
                                                   DeeIndexIterFunc  func,
                                                   gpointer          userdata);

DeeModel*            dee_index_get_model          (DeeIndex *self);

DeeAnalyzer*         dee_index_get_analyzer       (DeeIndex *self);

DeeModelReader*      dee_index_get_reader         (DeeIndex *self);

guint                dee_index_get_n_terms        (DeeIndex *self);

guint                dee_index_get_n_rows         (DeeIndex *self);

guint                dee_index_get_n_rows_for_term (DeeIndex *self,
                                                    const gchar   *term);

guint                dee_index_get_supported_term_match_flags (DeeIndex *self);

G_END_DECLS

#endif /* _HAVE_DEE_INDEX_H */
