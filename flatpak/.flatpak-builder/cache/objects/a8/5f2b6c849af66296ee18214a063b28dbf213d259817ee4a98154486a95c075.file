/*
 * Copyright (C) 2009 Canonical, Ltd.
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

#ifndef _HAVE_DEE_MODEL_H
#define _HAVE_DEE_MODEL_H

#include <glib.h>
#include <gio/gio.h>
#include <glib-object.h>

G_BEGIN_DECLS

#define DEE_TYPE_MODEL_ITER (dee_model_iter_get_type ())

#define DEE_TYPE_MODEL (dee_model_get_type ())

#define DEE_MODEL(obj) \
        (G_TYPE_CHECK_INSTANCE_CAST ((obj), DEE_TYPE_MODEL, DeeModel))

#define DEE_IS_MODEL(obj) \
        (G_TYPE_CHECK_INSTANCE_TYPE ((obj), DEE_TYPE_MODEL))

#define DEE_MODEL_GET_IFACE(obj) \
        (G_TYPE_INSTANCE_GET_INTERFACE(obj, dee_model_get_type (), DeeModelIface))

typedef struct _DeeModelIface DeeModelIface;
typedef struct _DeeModel DeeModel;

/**
 * DeeModelIter:
 *
 * The DeeModelIter structure is private and should only be used with the
 * provided #DeeModel API. It is owned by DeeModel and should not be freed.
 **/
typedef struct _DeeModelIter DeeModelIter;

/**
 * DeeModelTag:
 *
 * The DeeModelTag structure is private and should only be used with the
 * provided #DeeModel API. It is owned by DeeModel and should not be freed.
 **/
typedef struct _DeeModelTag DeeModelTag;

/**
 * DeeCompareRowFunc:
 * @row1: (array): The model being indexed
 * @row2: (array): The row to extract terms for
 * @user_data: (closure): User data to pass to comparison function
 *
 * Compares @row1 and @row2. Mainly used with dee_model_insert_sorted() and
 * dee_model_find_sorted().
 *
 * Returns: -1, 0, or 1 if @row1 is respectively less than, equal, or greater
 * than @row2.
 */
typedef gint          (*DeeCompareRowFunc) (GVariant** row1,
                                            GVariant** row2,
                                            gpointer user_data);

/**
 * DeeCompareRowSizedFunc:
 * @row1: (array length=row1_length): Row data
 * @row1_length: The number of elements in row1 array
 * @row2: (array length=row2_length): Row data to compare with
 * @row2_length: The number of elements in row2 array
 * @user_data: (closure): User data passed to comparison function
 *
 * Compares @row1 and @row2. Mainly used with 
 * dee_model_insert_row_sorted_with_sizes() and
 * dee_model_find_row_sorted_with_sizes().
 *
 * Returns: -1, 0, or 1 if @row1 is respectively less than, equal, or greater
 * than @row2.
 */
typedef gint          (*DeeCompareRowSizedFunc) (GVariant** row1,
                                                 guint row1_length,
                                                 GVariant** row2,
                                                 guint row2_length,
                                                 gpointer user_data);

struct _DeeModelIface
{
  GTypeInterface g_iface;

  /* Signals */
  void           (*row_added)       (DeeModel     *self,
                                     DeeModelIter *iter);

  void           (*row_removed)     (DeeModel     *self,
                                     DeeModelIter *iter);

  void           (*row_changed)     (DeeModel     *self,
                                     DeeModelIter *iter);

  /*< public >*/
  void           (*set_schema_full)     (DeeModel          *self,
                                         const char* const *column_schemas,
                                         guint              num_columns);

  const gchar* const* (*get_schema)     (DeeModel     *self,
                                         guint        *num_columns);

  const gchar*   (*get_column_schema)   (DeeModel     *self,
                                         guint         column);

  const gchar*   (*get_field_schema)    (DeeModel     *self,
                                         const gchar  *field_name,
                                         guint        *out_column);

  gint           (*get_column_index)    (DeeModel     *self,
                                         const gchar  *column_name);

  void           (*set_column_names_full) (DeeModel     *self,
                                           const gchar **column_names,
                                           guint         num_columns);

  const gchar**  (*get_column_names)    (DeeModel    *self,
                                         guint       *num_columns);

  void           (*register_vardict_schema)    (DeeModel    *self,
                                                guint        num_column,
                                                GHashTable  *schemas);

  GHashTable*    (*get_vardict_schema)  (DeeModel    *self,
                                         guint        num_column);

  guint          (*get_n_columns)   (DeeModel *self);

  guint          (*get_n_rows)      (DeeModel *self);

  DeeModelIter*  (*append_row)    (DeeModel  *self,
                                   GVariant **row_members);

  DeeModelIter*  (*prepend_row)   (DeeModel  *self,
                                   GVariant **row_members);

  DeeModelIter*  (*insert_row)    (DeeModel  *self,
                                   guint      pos,
                                   GVariant **row_members);

  DeeModelIter*  (*insert_row_before) (DeeModel      *self,
                                       DeeModelIter  *iter,
                                       GVariant     **row_members);

  DeeModelIter*  (*insert_row_sorted)  (DeeModel           *self,
                                        GVariant          **row_members,
                                        DeeCompareRowFunc   cmp_func,
                                        gpointer            user_data);

  DeeModelIter*  (*find_row_sorted)    (DeeModel           *self,
                                        GVariant          **row_spec,
                                        DeeCompareRowFunc   cmp_func,
                                        gpointer            user_data,
                                        gboolean           *out_was_found);

  void           (*remove)          (DeeModel     *self,
                                     DeeModelIter *iter);

  void           (*clear)           (DeeModel *self);

  void           (*set_value)       (DeeModel       *self,
                                     DeeModelIter   *iter,
                                     guint           column,
                                     GVariant       *value);
  
  void           (*set_row)         (DeeModel       *self,
                                     DeeModelIter   *iter,
                                     GVariant      **row_members);

  GVariant*      (*get_value)       (DeeModel     *self,
                                     DeeModelIter *iter,
                                     guint         column);

  GVariant*      (*get_value_by_name) (DeeModel     *self,
                                       DeeModelIter *iter,
                                       const gchar  *column_name);

  DeeModelIter* (*get_first_iter)  (DeeModel     *self);

  DeeModelIter* (*get_last_iter)   (DeeModel     *self);

  DeeModelIter* (*get_iter_at_row) (DeeModel     *self,
                                    guint          row);

  gboolean       (*get_bool)        (DeeModel     *self,
                                     DeeModelIter *iter,
                                     guint         column);

  guchar         (*get_uchar)       (DeeModel     *self,
                                     DeeModelIter *iter,
                                     guint         column);

  gint32         (*get_int32)       (DeeModel     *self,
                                     DeeModelIter *iter,
                                     guint         column);

  guint32        (*get_uint32)      (DeeModel     *self,
                                     DeeModelIter *iter,
                                     guint         column);

  gint64         (*get_int64)       (DeeModel     *self,
                                     DeeModelIter *iter,
                                     guint         column);

  guint64        (*get_uint64)      (DeeModel     *self,
                                     DeeModelIter *iter,
                                     guint         column);

  gdouble        (*get_double)      (DeeModel     *self,
                                     DeeModelIter *iter,
                                     guint         column);

  const gchar*   (*get_string)      (DeeModel     *self,
                                     DeeModelIter *iter,
                                     guint         column);

  DeeModelIter*  (*next)            (DeeModel     *self,
                                     DeeModelIter *iter);

  DeeModelIter*  (*prev)            (DeeModel     *self,
                                     DeeModelIter *iter);

  gboolean       (*is_first)        (DeeModel     *self,
                                     DeeModelIter *iter);

  gboolean       (*is_last)         (DeeModel     *self,
                                     DeeModelIter *iter);

  guint          (*get_position)    (DeeModel     *self,
                                     DeeModelIter *iter);

  DeeModelTag*   (*register_tag)    (DeeModel       *self,
                                     GDestroyNotify  tag_destroy);

  gpointer       (*get_tag)         (DeeModel       *self,
                                     DeeModelIter   *iter,
                                     DeeModelTag    *tag);

  void           (*set_tag)         (DeeModel       *self,
                                     DeeModelIter   *iter,
                                     DeeModelTag    *tag,
                                     gpointer        value);
  
  GVariant**     (*get_row)         (DeeModel       *self,
                                     DeeModelIter   *iter,
                                     GVariant      **out_row_members);

  void           (*begin_changeset)    (DeeModel    *self);

  void           (*end_changeset)      (DeeModel    *self);

  void           (*changeset_started)  (DeeModel    *self);

  void           (*changeset_finished) (DeeModel    *self);

  /*< private >*/
  void     (*_dee_model_1) (void);
  void     (*_dee_model_2) (void);
  void     (*_dee_model_3) (void);
};

GType           dee_model_iter_get_type         (void);

/**
 * dee_model_get_type:
 *
 * The GType of #DeeModel
 *
 * Return value: the #GType of #DeeModel
 **/
GType           dee_model_get_type              (void);

void            dee_model_set_schema            (DeeModel    *self,
                                                 ...) G_GNUC_NULL_TERMINATED;

void            dee_model_set_schema_full       (DeeModel           *self,
                                                 const gchar* const *column_schemas,
                                                 guint               num_columns);

const gchar* const* dee_model_get_schema     (DeeModel    *self,
                                              guint       *num_columns);

const gchar*    dee_model_get_column_schema  (DeeModel    *self,
                                              guint        column);

const gchar*    dee_model_get_field_schema   (DeeModel    *self,
                                              const gchar *field_name,
                                              guint       *out_column);

gint            dee_model_get_column_index   (DeeModel     *self,
                                              const gchar  *column_name);

void            dee_model_set_column_names      (DeeModel     *self,
                                                 const gchar  *first_column_name,
                                                 ...) G_GNUC_NULL_TERMINATED;

void            dee_model_set_column_names_full (DeeModel     *self,
                                                 const gchar **column_names,
                                                 guint         num_columns);

const gchar**   dee_model_get_column_names      (DeeModel     *self,
                                                 guint        *num_columns);

void            dee_model_register_vardict_schema (DeeModel    *self,
                                                   guint        column,
                                                   GHashTable  *schemas);

GHashTable*     dee_model_get_vardict_schema    (DeeModel    *self,
                                                 guint        column);

guint           dee_model_get_n_columns   (DeeModel *self);

guint           dee_model_get_n_rows      (DeeModel *self);

DeeModelIter*   dee_model_append          (DeeModel *self,
                                           ...);

DeeModelIter*   dee_model_append_row      (DeeModel  *self,
                                           GVariant **row_members);

DeeModelIter*   dee_model_prepend         (DeeModel *self,
                                           ...);

DeeModelIter*   dee_model_prepend_row     (DeeModel  *self,
                                           GVariant **row_members);

DeeModelIter*   dee_model_insert           (DeeModel *self,
                                            guint     pos,
                                            ...);

DeeModelIter*   dee_model_insert_row       (DeeModel  *self,
                                            guint      pos,
                                            GVariant **row_members);

DeeModelIter*   dee_model_insert_before    (DeeModel     *self,
                                            DeeModelIter *iter,
                                            ...);

DeeModelIter*   dee_model_insert_row_before (DeeModel     *self,
                                             DeeModelIter *iter,
                                             GVariant    **row_members);

DeeModelIter*   dee_model_insert_row_sorted (DeeModel           *self,
                                             GVariant          **row_members,
                                             DeeCompareRowFunc   cmp_func,
                                             gpointer            user_data);

DeeModelIter*   dee_model_insert_row_sorted_with_sizes (DeeModel              *self,
                                                        GVariant             **row_members,
                                                        DeeCompareRowSizedFunc cmp_func,
                                                        gpointer               user_data);

DeeModelIter*   dee_model_insert_sorted (DeeModel           *self,
                                         DeeCompareRowFunc   cmp_func,
                                         gpointer            user_data,
                                         ...);

DeeModelIter*  dee_model_find_row_sorted    (DeeModel           *self,
                                             GVariant          **row_spec,
                                             DeeCompareRowFunc   cmp_func,
                                             gpointer            user_data,
                                             gboolean           *out_was_found);

DeeModelIter*  dee_model_find_row_sorted_with_sizes (DeeModel               *self,
                                                     GVariant             **row_spec,
                                                     DeeCompareRowSizedFunc cmp_func,
                                                     gpointer               user_data,
                                                     gboolean               *out_was_found);

DeeModelIter*   dee_model_find_sorted    (DeeModel           *self,
                                          DeeCompareRowFunc   cmp_func,
                                          gpointer            user_data,
                                          gboolean           *out_was_found,
                                          ...);

void            dee_model_remove          (DeeModel     *self,
                                           DeeModelIter *iter);

void            dee_model_clear           (DeeModel *self);

void            dee_model_set             (DeeModel     *self,
                                           DeeModelIter *iter,
                                           ...);

void            dee_model_set_value       (DeeModel       *self,
                                           DeeModelIter   *iter,
                                           guint           column,
                                           GVariant       *value);

void            dee_model_set_row         (DeeModel       *self,
                                           DeeModelIter   *iter,
                                           GVariant      **row_members);

void            dee_model_get             (DeeModel     *self,
                                           DeeModelIter *iter,
                                           ...);

GVariant**      dee_model_get_row         (DeeModel      *self,
                                           DeeModelIter  *iter,
                                           GVariant     **out_row_members);

GVariant*       dee_model_get_value       (DeeModel     *self,
                                           DeeModelIter *iter,
                                           guint         column);

GVariant*       dee_model_get_value_by_name (DeeModel     *self,
                                             DeeModelIter *iter,
                                             const gchar  *column_name);

DeeModelIter*   dee_model_get_first_iter  (DeeModel     *self);

DeeModelIter*   dee_model_get_last_iter   (DeeModel     *self);

DeeModelIter*   dee_model_get_iter_at_row (DeeModel     *self,
                                           guint         row);

gboolean        dee_model_get_bool        (DeeModel     *self,
                                           DeeModelIter *iter,
                                           guint         column);

guchar          dee_model_get_uchar       (DeeModel     *self,
                                           DeeModelIter *iter,
                                           guint         column);

gint32          dee_model_get_int32       (DeeModel     *self,
                                           DeeModelIter *iter,
                                           guint         column);

guint32         dee_model_get_uint32      (DeeModel     *self,
                                           DeeModelIter *iter,
                                           guint         column);

gint64          dee_model_get_int64       (DeeModel     *self,
                                           DeeModelIter *iter,
                                           guint         column);

guint64         dee_model_get_uint64      (DeeModel     *self,
                                           DeeModelIter *iter,
                                           guint         column);

gdouble         dee_model_get_double      (DeeModel     *self,
                                           DeeModelIter *iter,
                                           guint         column);

const gchar *   dee_model_get_string      (DeeModel     *self,
                                           DeeModelIter *iter,
                                           guint         column);

DeeModelIter *  dee_model_next            (DeeModel     *self,
                                           DeeModelIter *iter);

DeeModelIter *  dee_model_prev            (DeeModel     *self,
                                           DeeModelIter *iter);

gboolean        dee_model_is_first        (DeeModel     *self,
                                           DeeModelIter *iter);

gboolean        dee_model_is_last         (DeeModel     *self,
                                           DeeModelIter *iter);

guint           dee_model_get_position    (DeeModel     *self,
                                           DeeModelIter *iter);

DeeModelTag*    dee_model_register_tag    (DeeModel       *self,
                                           GDestroyNotify  tag_destroy);

gpointer        dee_model_get_tag         (DeeModel       *self,
                                           DeeModelIter   *iter,
                                           DeeModelTag    *tag);

void            dee_model_set_tag         (DeeModel       *self,
                                           DeeModelIter   *iter,
                                           DeeModelTag    *tag,
                                           gpointer        value);

void            dee_model_clear_tag       (DeeModel       *self,
                                           DeeModelIter   *iter,
                                           DeeModelTag    *tag);

void            dee_model_begin_changeset (DeeModel       *self);

void            dee_model_end_changeset   (DeeModel       *self);

GVariant**      dee_model_build_row       (DeeModel  *self,
                                           GVariant **out_row_members,
                                           ...);

GVariant**      dee_model_build_named_row (DeeModel    *self,
                                           GVariant   **out_row_members,
                                           const gchar *first_column_name,
                                           ...) G_GNUC_NULL_TERMINATED;

GVariant**      dee_model_build_named_row_valist (DeeModel    *self,
                                                  GVariant   **out_row_members,
                                                  const gchar *first_column_name,
                                                  va_list *args);

GVariant**      dee_model_build_named_row_sunk   (DeeModel    *self,
                                                  GVariant   **out_row_members,
                                                  guint       *out_array_length,
                                                  const gchar *first_column_name,
                                                  ...) G_GNUC_NULL_TERMINATED;

G_END_DECLS

#endif /* _HAVE_DEE_MODEL_H */
