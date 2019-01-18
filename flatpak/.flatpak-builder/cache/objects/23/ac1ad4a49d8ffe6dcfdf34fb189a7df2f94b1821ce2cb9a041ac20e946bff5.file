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
 * SECTION:dee-filter
 * @title: Filters
 * @short_description: A suite of simple #DeeFilter<!-- -->s for use with #DeeFilterModel<!-- -->s
 * @include: dee.h
 *
 * #DeeFilter<!-- -->s are used together with #DeeFilterModel<!-- -->s to build
 * "views" of some original #DeeModel. An example could be to build a view
 * of a model that exposes the rows of the original model sorted by a given
 * column (leaving the original model unaltered):
 * |[
 *   DeeModel  *model, *view;
 *   DeeFilter *collator;
 *
 *   // Create and populate a model with some unsorted rows
 *   model = dee_sequence_model_new ();
 *   dee_model_set_schema (model, "i", "s", NULL);
 *   dee_model_append (model, 27, "Foo");
 *   dee_model_append (model, 68, "Bar");
 *
 *   // Create a collator for column 1
 *   collator = dee_filter_new_collator (1);
 *
 *   // Create the sorted view
 *   view = dee_filter_model_new (collator, model);
 *   g_free (collator);
 *
 *   // When accessing the view the row with 'Bar' will be first
 * ]|
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <string.h> // memset()

#include "dee-filter-model.h"
#include "dee-filter.h"
#include "trace-log.h"

typedef struct {
  guint             n_cols;
  DeeCompareRowFunc cmp;
  gpointer          user_data;
  GDestroyNotify    destroy;
  GVariant        **row_buf;
} SortFilter;

/* The CollatorFilter stores collation keys for the columns in a DeeModelTag */
typedef struct {
  guint        column;
  DeeModelTag *collation_key_tag;
} CollatorFilter;

typedef struct {
  guint        column;
  gchar       *key;
} KeyFilter;

typedef struct {
  guint        column;
  GRegex      *regex;
} RegexFilter;

typedef struct {
  guint        column;
  GVariant    *value;
} ValueFilter;

/*
 * Private impl
 */

static gboolean
_dee_filter_sort_map_notify (DeeModel *orig_model,
                             DeeModelIter *orig_iter,
                             DeeFilterModel *filter_model,
                             gpointer user_data)
{
  DeeModelIter   *pos_iter;
  SortFilter     *filter;
  guint           i;
  gboolean        was_found;

  g_return_val_if_fail (user_data != NULL, FALSE);

  filter = (SortFilter *) user_data;

  dee_model_get_row (orig_model, orig_iter, filter->row_buf);

  pos_iter = dee_model_find_row_sorted (DEE_MODEL (filter_model),
                                        filter->row_buf,
                                        filter->cmp,
                                        filter->user_data,
                                        &was_found);

  dee_filter_model_insert_iter_before (filter_model, orig_iter, pos_iter);

  for (i = 0; i < filter->n_cols; i++) g_variant_unref (filter->row_buf[i]);

  return was_found;
}

static void
_dee_filter_sort_map_func (DeeModel *orig_model,
                           DeeFilterModel *filter_model,
                           gpointer user_data)
{
  DeeModelIter   *iter, *end;
  SortFilter     *filter;

  g_return_if_fail (user_data != NULL);

  filter = (SortFilter *) user_data;
  filter->n_cols = dee_model_get_n_columns (orig_model);
  filter->row_buf = g_new0(GVariant*, filter->n_cols);

  iter = dee_model_get_first_iter (orig_model);
  end = dee_model_get_last_iter (orig_model);
  while (iter != end)
    {
      _dee_filter_sort_map_notify (orig_model, iter, filter_model, filter);
      iter = dee_model_next (orig_model, iter);
    }
}

static gint
_cmp_collate_asc (GVariant **row1, GVariant **row2, gpointer user_data)
{
  guint col = GPOINTER_TO_UINT (user_data);

  return g_utf8_collate (g_variant_get_string (row1[col], NULL),
                         g_variant_get_string (row2[col], NULL));
}

static gint
_cmp_collate_desc (GVariant **row1, GVariant **row2, gpointer user_data)
{
  guint col = GPOINTER_TO_UINT (user_data);

  return  - g_utf8_collate (g_variant_get_string (row1[col], NULL),
                            g_variant_get_string (row2[col], NULL));
}

static void
_dee_filter_key_map_func (DeeModel *orig_model,
                          DeeFilterModel *filter_model,
                          gpointer user_data)
{
  DeeModelIter   *iter, *end;
  KeyFilter      *filter;
  guint           column;
  const gchar    *key, *val;

  g_return_if_fail (user_data != NULL);

  filter = (KeyFilter *) user_data;
  key = filter->key;
  column = filter->column;

  iter = dee_model_get_first_iter (orig_model);
  end = dee_model_get_last_iter (orig_model);
  while (iter != end)
    {
      val = dee_model_get_string (orig_model, iter, column);
      if (g_strcmp0 (key, val) == 0)
        {
          dee_filter_model_append_iter (filter_model, iter);
        }
      iter = dee_model_next (orig_model, iter);
    }
}

static gboolean
_dee_filter_key_map_notify (DeeModel *orig_model,
                            DeeModelIter *orig_iter,
                            DeeFilterModel *filter_model,
                            gpointer user_data)
{
  KeyFilter      *filter;
  const gchar    *val;

  g_return_val_if_fail (user_data != NULL, FALSE);

  filter = (KeyFilter *) user_data;
  val = dee_model_get_string (orig_model, orig_iter, filter->column);

  /* Ignore rows that don't match the key */
  if (g_strcmp0 (filter->key, val) != 0)
    return FALSE;

  dee_filter_model_insert_iter_with_original_order (filter_model, orig_iter);
  return TRUE;
}

static void
_dee_filter_value_map_func (DeeModel *orig_model,
                            DeeFilterModel *filter_model,
                            gpointer user_data)
{
  DeeModelIter   *iter, *end;
  ValueFilter    *filter;
  GVariant       *val;

  g_return_if_fail (user_data != NULL);

  filter = (ValueFilter *) user_data;

  iter = dee_model_get_first_iter (orig_model);
  end = dee_model_get_last_iter (orig_model);
  while (iter != end)
    {
      val = dee_model_get_value (orig_model, iter, filter->column);
      if (g_variant_equal (filter->value, val))
        {
          dee_filter_model_append_iter (filter_model, iter);
        }
      iter = dee_model_next (orig_model, iter);
    }
}

static gboolean
_dee_filter_value_map_notify (DeeModel *orig_model,
                              DeeModelIter *orig_iter,
                              DeeFilterModel *filter_model,
                              gpointer user_data)
{
  ValueFilter    *filter;
  GVariant       *val;

  g_return_val_if_fail (user_data != NULL, FALSE);

  filter = (ValueFilter *) user_data;
  val = dee_model_get_value (orig_model, orig_iter, filter->column);

  /* Ignore rows that don't match the value */
  if (!g_variant_equal (filter->value, val))
    return FALSE;

  dee_filter_model_insert_iter_with_original_order (filter_model, orig_iter);
  return TRUE;
}

static void
_dee_filter_regex_map_func (DeeModel *orig_model,
                            DeeFilterModel *filter_model,
                            gpointer user_data)
{
  DeeModelIter   *iter, *end;
  RegexFilter    *filter;
  guint           column;
  GRegex         *regex;
  const gchar    *val;

  g_return_if_fail (user_data != NULL);

  filter = (RegexFilter *) user_data;
  regex = filter->regex;
  column = filter->column;

  iter = dee_model_get_first_iter (orig_model);
  end = dee_model_get_last_iter (orig_model);
  while (iter != end)
    {
      val = dee_model_get_string (orig_model, iter, column);
      if (g_regex_match (regex, val, 0, NULL))
        {
          dee_filter_model_append_iter (filter_model, iter);
        }
      iter = dee_model_next (orig_model, iter);
    }
}

static gboolean
_dee_filter_regex_map_notify (DeeModel *orig_model,
                              DeeModelIter *orig_iter,
                              DeeFilterModel *filter_model,
                              gpointer user_data)
{
  RegexFilter    *filter;
  const gchar    *val;

  g_return_val_if_fail (user_data != NULL, FALSE);

  filter = (RegexFilter *) user_data;
  val = dee_model_get_string (orig_model, orig_iter, filter->column);

  /* Ignore rows that don't match the key */
  if (!g_regex_match (filter->regex, val, 0, NULL))
    return FALSE;

  dee_filter_model_insert_iter_with_original_order (filter_model, orig_iter);
  return TRUE;
}

static void
sort_filter_free (SortFilter *filter)
{
  if (filter->destroy != NULL)
    filter->destroy (filter->user_data);

  g_free (filter->row_buf);
  g_free (filter);
}

static void
key_filter_free (KeyFilter *filter)
{
  g_free (filter->key);
  g_free (filter);
}

static void
value_filter_free (ValueFilter *filter)
{
  g_variant_unref (filter->value);
  g_free (filter);
}

static void
regex_filter_free (RegexFilter *filter)
{
  g_regex_unref (filter->regex);
  g_free (filter);
}

/*
 * API
 */

/**
 * dee_filter_notify:
 * @filter: The filter to apply
 * @orig_iter: The #DeeModelIter added to @orig_model
 * @orig_model: The model that is being filtered
 * @filter_model: The #DeeFilterModel that holds the
 *                filtered subset of @orig_model
 *
 * Call the #DeeFilterMapNotify function of a #DeeFilter.
 * When using a #DeeFilterModel you should not call this method yourself.
 *
 * Returns: The return value from the #DeeFilterMapNotify. That is; %TRUE
 *          if @orig_iter was added to @filter_model
 */
gboolean
dee_filter_notify (DeeFilter      *filter,
                   DeeModelIter   *orig_iter,
                   DeeModel       *orig_model,
                   DeeFilterModel *filter_model)
{
  g_return_val_if_fail (filter != NULL, FALSE);

  return filter->map_notify (orig_model, orig_iter,
                             filter_model, filter->userdata);
}

/**
 * dee_filter_map:
 * @filter: The filter to apply
 * @orig_model: The model that is being filtered
 * @filter_model: The #DeeFilterModel that holds the
 *                filtered subset of @orig_model
 *
 * Call the #DeeFilterMapFunc function of a #DeeFilter.
 * When using a #DeeFilterModel you should not call this method yourself.
 */
void
dee_filter_map (DeeFilter      *filter,
                DeeModel       *orig_model,
                DeeFilterModel *filter_model)
{
  g_return_if_fail (filter != NULL);

  filter->map_func (orig_model, filter_model, filter->userdata);
}

/**
 * dee_filter_destroy:
 * @filter: The filter to destroy
 *
 * Call the #GDestroyNotify function on the userdata pointer of a #DeeFilter
 * (if the destroy member is set, that is).
 *
 * When using a #DeeFilterModel you should not call this method yourself.
 *
 * This method will not free the memory allocated for @filter.
 */
void
dee_filter_destroy (DeeFilter *filter)
{
  g_return_if_fail (filter != NULL);

  if (filter->destroy)
    filter->destroy (filter->userdata);
}

/**
 * dee_filter_new:
 * @map_func: (scope notified): The #DeeFilterMapFunc to use for the filter
 * @map_notify: (scope notified): The #DeeFilterMapNotify to use for the filter
 * @userdata: (closure): The user data to pass to @map_func and @map_notify
 * @destroy: (allow-none): The #GDestroyNotify to call on
 *                         @userdata when disposing of the filter
 * @out_filter: (out): A pointer to an uninitialized #DeeFilter struct.
 *                     This struct will zeroed and configured with the filter
 *                     parameters
 *
 * Create a new #DeeFilter with the given parameters. This call will zero
 * the @out_filter struct.
 *
 */
void
dee_filter_new (DeeFilterMapFunc   map_func,
                DeeFilterMapNotify map_notify,
                gpointer           userdata,
                GDestroyNotify     destroy,
                DeeFilter         *out_filter)
{
  g_return_if_fail (map_func != NULL);
  g_return_if_fail (map_notify != NULL);
  g_return_if_fail (out_filter != NULL);

  memset (out_filter, 0, sizeof (DeeFilter));

  out_filter->map_func = map_func;
  out_filter->map_notify = map_notify;
  out_filter->userdata = userdata;
  out_filter->destroy = destroy;
}

/**
 * dee_filter_new_sort:
 * @cmp_row: (scope notified): A #DeeCompareRowFunc to use for sorting
 * @cmp_user_data: (closure): User data passed to @cmp_row
 * @cmp_destroy: (allow-none): The #GDestroyNotify to call on
 *                         @cmp_user_data when disposing of the filter
 * @out_filter: (out): A pointer to an uninitialized #DeeFilter struct.
 *                     This struct will zeroed and configured with the filter
 *                     parameters
 *
 * Create a new #DeeFilter sorting a model according to a #DeeCompareRowFunc.
 *
 */
void
dee_filter_new_sort (DeeCompareRowFunc cmp_row,
                     gpointer          cmp_user_data,
                     GDestroyNotify    cmp_destroy,
                     DeeFilter        *out_filter)
{
  SortFilter *filter;

  filter = g_new0 (SortFilter, 1);
  filter->cmp = cmp_row;
  filter->user_data = cmp_user_data;
  filter->destroy = cmp_destroy;

  dee_filter_new (_dee_filter_sort_map_func,
                  _dee_filter_sort_map_notify,
                  filter,
                  (GDestroyNotify) sort_filter_free,
                  out_filter);
}

/**
 * dee_filter_new_collator:
 * @column: The index of a column containing the strings to sort after
 * @out_filter: (out): A pointer to an uninitialized #DeeFilter struct.
 *                     This struct will zeroed and configured with the filter
 *                     parameters
 *
 * Create a #DeeFilter that takes string values from a column in the model
 * and builds a #DeeFilterModel with the rows sorted according to the
 * collation rules of the current locale.
 */
void
dee_filter_new_collator    (guint      column,
                            DeeFilter *out_filter)
{
  dee_filter_new_sort (_cmp_collate_asc, GUINT_TO_POINTER (column),
                       NULL, out_filter);
}

/**
 * dee_filter_new_collator_desc:
 * @column: The index of a column containing the strings to sort after
 * @out_filter: (out): A pointer to an uninitialized #DeeFilter struct.
 *                     This struct will zeroed and configured with the filter
 *                     parameters
 *
 * Create a #DeeFilter that takes string values from a column in the model
 * and builds a #DeeFilterModel with the rows sorted descending according to the
 * collation rules of the current locale.
 */
void
dee_filter_new_collator_desc    (guint      column,
                                 DeeFilter *out_filter)
{
  dee_filter_new_sort (_cmp_collate_desc, GUINT_TO_POINTER (column),
                       NULL, out_filter);
} 


/**
 * dee_filter_new_for_key_column:
 * @column: The index of a column containing the string key to match
 * @out_filter: (out): A pointer to an uninitialized #DeeFilter struct.
 *                     This struct will zeroed and configured with the filter
 *                     parameters
 *
 * Create a #DeeFilter that only includes rows from the original model
 * which has an exact match on some string column. A #DeeFilterModel created
 * with this filter will be ordered in accordance with its parent model.
 */
void
dee_filter_new_for_key_column    (guint        column,
                                  const gchar *key,
                                  DeeFilter   *out_filter)
{
  KeyFilter      *key_filter;

  g_return_if_fail (key != NULL);

  key_filter = g_new0 (KeyFilter, 1);
  key_filter->column = column;
  key_filter->key = g_strdup (key);

  dee_filter_new (_dee_filter_key_map_func,
                  _dee_filter_key_map_notify,
                  key_filter,
                  (GDestroyNotify) key_filter_free,
                  out_filter);
}

/**
 * dee_filter_new_for_any_column:
 * @column: The index of a column containing the string to match
 * @value: (transfer none): A #GVariant value columns must match exactly.
 *         The matching semantics are those of g_variant_equal(). If @value
 *         is floating the ownership will be transfered to the filter
 * @out_filter: (out): A pointer to an uninitialized #DeeFilter struct.
 *                     This struct will zeroed and configured with the filter
 *                     parameters
 *
 * Create a #DeeFilter that only includes rows from the original model
 * which match a variant value in a given column. A #DeeFilterModel
 * created with this filter will be ordered in accordance with its parent model.
 *
 * This method will work on any column, disregarding its schema, since the
 * value comparison is done using g_variant_equal(). This means you can use
 * this filter as a convenient fallback when there is no predefined filter
 * for your column type if raw performance is not paramount.
 */
void
dee_filter_new_for_any_column (guint      column,
                               GVariant  *value,
                               DeeFilter *out_filter)
{
  ValueFilter    *v_filter;

  g_return_if_fail (value != NULL);

  v_filter = g_new0 (ValueFilter, 1);
  v_filter->column = column;
  v_filter->value = g_variant_ref_sink (value);

  dee_filter_new (_dee_filter_value_map_func,
                  _dee_filter_value_map_notify,
                  v_filter,
                  (GDestroyNotify) value_filter_free,
                  out_filter);
}

/**
 * dee_filter_new_regex:
 * @column: The index of a column containing the string to match
 * @regex: (transfer none):The regular expression @column must match
 * @out_filter: (out): A pointer to an uninitialized #DeeFilter struct.
 *                     This struct will zeroed and configured with the filter
 *                     parameters
 *
 * Create a #DeeFilter that only includes rows from the original model
 * which match a regular expression on some string column. A #DeeFilterModel
 * created with this filter will be ordered in accordance with its parent model.
 */
void
dee_filter_new_regex (guint      column,
                      GRegex    *regex,
                      DeeFilter *out_filter)
{
  RegexFilter    *r_filter;

  g_return_if_fail (regex != NULL);

  r_filter = g_new0 (RegexFilter, 1);
  r_filter->column = column;
  r_filter->regex = g_regex_ref (regex);

  dee_filter_new (_dee_filter_regex_map_func,
                  _dee_filter_regex_map_notify,
                  r_filter,
                  (GDestroyNotify) regex_filter_free,
                  out_filter);
}

