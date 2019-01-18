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

#ifndef _HAVE_DEE_FILTERS_H
#define _HAVE_DEE_FILTERS_H

#include <glib.h>
#include <glib-object.h>
#include <dee-filter-model.h>

G_BEGIN_DECLS

/**
 * DeeFilterMapFunc:
 * @orig_model: The model containing the original data to filter
 * @filter_model: The model that will contain the filtered results. The
 *                filter func must iterate over @orig_model and add all relevant
 *                rows to @filter_model. This model is guaranteed to be empty
 *                when the filter func is invoked
 * @user_data: (closure): User data passed together with the filter func
 *
 * Function used to collect the rows from a model that should be included in
 * a #DeeFilterModel. To add rows to @filter_model use the methods
 * dee_filter_model_append_iter(), dee_filter_model_prepend_iter(),
 * dee_filter_model_insert_iter(), and dee_filter_model_insert_iter_before().
 *
 * The iteration over the original model is purposely left to the map func
 * in order to allow optimized iterations if the the caller has a priori
 * knowledge of the sorting and grouping of the data in the original model.
 */
typedef void (*DeeFilterMapFunc) (DeeModel       *orig_model,
                                  DeeFilterModel *filter_model,
                                  gpointer        user_data);

/**
 * DeeFilterMapNotify:
 * @orig_model: The model containing the added row
 * @orig_iter: A #DeeModelIter pointing to the new row in @orig_model
 * @filter_model: The model that was also passed to the #DeeModelMapFunc
 *                of the #DeeFilter this functions is a part of
 * @user_data: (closure): User data for the #DeeFilter
 *
 * Callback invoked when a row is added to @orig_model. To add rows to
 * @filter_model use the methods dee_filter_model_append_iter(),
 * dee_filter_model_prepend_iter(), dee_filter_model_insert_iter(),
 * and dee_filter_model_insert_iter_before().
 *
 * Returns: %TRUE if @orig_iter was added to @filter_model
 */
typedef gboolean (*DeeFilterMapNotify) (DeeModel          *orig_model,
                                        DeeModelIter      *orig_iter,
                                        DeeFilterModel    *filter_model,
                                        gpointer           user_data);

/**
 * DeeFilter:
 * @map_func: (scope notified): The #DeeModelMapFunc used to construct
 *                              the initial contents of a #DeeFilterModel
 * @map_notify: (scope notified): Callback invoked when the original model changes
 * @destroy: Callback for freeing the @user_data
 * @userdata (closure): Free form user data associated with the filter.
 *                       This pointer will be passed to @map_func and @map_notify
 *
 * Structure encapsulating the mapping logic used to construct a #DeeFilterModel
 */
struct _DeeFilter
{
  DeeFilterMapFunc   map_func;
  DeeFilterMapNotify map_notify;
  GDestroyNotify     destroy;
  gpointer           userdata;

  /*< private >*/
  gpointer          _padding_1;
  gpointer          _padding_2;
  gpointer          _padding_3;
  gpointer          _padding_4;
};

gboolean dee_filter_notify         (DeeFilter      *filter,
                                    DeeModelIter   *orig_iter,
                                    DeeModel       *orig_model,
                                    DeeFilterModel *filter_model);

void dee_filter_map                (DeeFilter      *filter,
                                    DeeModel       *orig_model,
                                    DeeFilterModel *filter_model);

void dee_filter_destroy            (DeeFilter      *filter);

void dee_filter_new                (DeeFilterMapFunc   map_func,
                                    DeeFilterMapNotify map_notify,
                                    gpointer           userdata,
                                    GDestroyNotify     destroy,
                                    DeeFilter         *out_filter);

void dee_filter_new_sort           (DeeCompareRowFunc cmp_row,
                                    gpointer          cmp_user_data,
                                    GDestroyNotify    cmp_destroy,
                                    DeeFilter        *out_filter);

void dee_filter_new_collator       (guint       column,
                                    DeeFilter  *out_filter);

void dee_filter_new_collator_desc  (guint       column,
                                    DeeFilter  *out_filter);

void dee_filter_new_for_key_column (guint        column,
                                    const gchar *key,
                                    DeeFilter   *out_filter);

void dee_filter_new_for_any_column (guint        column,
                                    GVariant    *value,
                                    DeeFilter   *out_filter);

void dee_filter_new_regex          (guint        column,
                                    GRegex      *regex,
                                    DeeFilter   *out_filter);

G_END_DECLS

#endif /* _HAVE_DEE_FILTERS_H */
