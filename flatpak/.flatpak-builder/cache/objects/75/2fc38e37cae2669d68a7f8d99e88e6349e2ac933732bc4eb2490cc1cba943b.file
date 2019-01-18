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
 * Authored by Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

#if !defined (_DEE_H_INSIDE) && !defined (DEE_COMPILATION)
#error "Only <dee.h> can be included directly."
#endif

#ifndef _HAVE_DEE_ANALYZER_H
#define _HAVE_DEE_ANALYZER_H

#include <glib.h>
#include <glib-object.h>

#include <dee-model.h>
#include <dee-term-list.h>

G_BEGIN_DECLS

#define DEE_TYPE_ANALYZER (dee_analyzer_get_type ())

#define DEE_ANALYZER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_ANALYZER, DeeAnalyzer))

#define DEE_ANALYZER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_ANALYZER, DeeAnalyzerClass))

#define DEE_IS_ANALYZER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_ANALYZER))

#define DEE_IS_ANALYZER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_ANALYZER))

#define DEE_ANALYZER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DEE_TYPE_ANALYZER, DeeAnalyzerClass))

typedef struct _DeeAnalyzer DeeAnalyzer;
typedef struct _DeeAnalyzerClass DeeAnalyzerClass;
typedef struct _DeeAnalyzerPrivate DeeAnalyzerPrivate;

/**
 * DeeCollatorFunc:
 * @input: The string to produce a collation key for
 * @data: (closure): User data set when registering the collator
 *
 * A collator takes an input string, most often a term produced from a
 * #DeeAnalyzer, and outputs a collation key.
 *
 * Returns: (transfer full): The collation key. Free with g_free() when done
 *                           using it.
 */
typedef gchar* (*DeeCollatorFunc) (const gchar *input,
                                   gpointer     data);

/**
 * DeeTermFilterFunc:
 * @terms_in: A #DeeTermList with the terms to filter
 * @terms_out: A #DeeTermList to write the filtered terms to
 * @filter_data: (closure): User data set when registering the filter
 *
 * A term filter takes a list of terms and runs it through a filtering and/or
 * set of transformations and stores the output in a #DeeTermList.
 *
 * You can register term filters on a #DeeAnalyzer with
 * dee_analyzer_add_term_filter().
 *
 * Returns: Nothing. Output is stored in @terms_out.
 */
typedef void (*DeeTermFilterFunc) (DeeTermList *terms_in,
                                   DeeTermList *terms_out,
                                   gpointer     filter_data);

/**
 * DeeAnalyzer:
 *
 * All fields in the DeeAnalyzer structure are private and should never be
 * accessed directly
 */
struct _DeeAnalyzer
{
  /*< private >*/
  GObject          parent;

  DeeAnalyzerPrivate *priv;
};

struct _DeeAnalyzerClass
{
  /*< private >*/
  GObjectClass parent_class;

  void         (*analyze)                      (DeeAnalyzer   *self,
                                                const gchar   *data,
                                                DeeTermList   *terms_out,
                                                DeeTermList   *colkeys_out);

  void         (*tokenize)                      (DeeAnalyzer   *self,
                                                 const gchar   *data,
                                                 DeeTermList   *terms_out);

  void         (*add_term_filter)              (DeeAnalyzer       *self,
                                                DeeTermFilterFunc  filter_func,
                                                gpointer           filter_data,
                                                GDestroyNotify     filter_destroy);

  gchar*       (*collate_key)                  (DeeAnalyzer   *self,
                                                const gchar   *data);

  gint         (*collate_cmp)                  (DeeAnalyzer   *self,
                                                const gchar   *key1,
                                                const gchar   *key2);


  /*< private >*/
  void (*_dee_analyzer_1) (void);
  void (*_dee_analyzer_2) (void);
  void (*_dee_analyzer_3) (void);
  void (*_dee_analyzer_4) (void);
};

/**
 * dee_analyzer_get_type:
 *
 * The GType of #DeeAnalyzer
 *
 * Return value: the #GType of #DeeAnalyzer
 **/
GType                 dee_analyzer_get_type        (void);

void                  dee_analyzer_analyze         (DeeAnalyzer   *self,
                                                    const gchar   *data,
                                                    DeeTermList   *terms_out,
                                                    DeeTermList   *colkeys_out);

void                  dee_analyzer_tokenize        (DeeAnalyzer   *self,
                                                    const gchar   *data,
                                                    DeeTermList   *terms_out);

void                  dee_analyzer_add_term_filter (DeeAnalyzer       *self,
                                                    DeeTermFilterFunc  filter_func,
                                                    gpointer           filter_data,
                                                    GDestroyNotify     filter_destroy);

gchar*                dee_analyzer_collate_key     (DeeAnalyzer   *self,
                                                    const gchar   *data);

gint                  dee_analyzer_collate_cmp     (DeeAnalyzer   *self,
                                                    const gchar   *key1,
                                                    const gchar   *key2);

gint                  dee_analyzer_collate_cmp_func (const gchar *key1,
                                                     const gchar *key2,
                                                     gpointer     analyzer);

DeeAnalyzer*          dee_analyzer_new             (void);

G_END_DECLS

#endif /* _HAVE_DEE_ANALYZER_H */
