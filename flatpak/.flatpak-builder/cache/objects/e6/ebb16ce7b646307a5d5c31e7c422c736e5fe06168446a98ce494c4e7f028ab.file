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
 * SECTION:dee-sequence-model
 * @short_description: A #DeeModel<!-- --> implementation backed by a #GSequence
 * @include: dee.h
 *
 * #DeeSequenceModel is an implementation of the #DeeModel<!-- --> interface
 * backed by a #GSequence. It extends #DeeSerializableModel so that you may use
 * it as back end model for a #DeeSharedModel.
 *
 * The implementation is backed by a #GSequence giving a good tradeoff between
 * random access time versus random- insertion and deletion times. Notably the
 * dee_model_insert_sorted() and dee_model_find_sorted() methods use the
 * underlying tree structure to guarantee a <emphasis>O(log(N))</emphasis>
 * profile.
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <memory.h>
#include <time.h>
#include <unistd.h>

#include "dee-model.h"
#include "dee-serializable-model.h"
#include "dee-sequence-model.h"
#include "dee-marshal.h"
#include "trace-log.h"

static void dee_sequence_model_model_iface_init (DeeModelIface *iface);

G_DEFINE_TYPE_WITH_CODE (DeeSequenceModel,
                         dee_sequence_model,
                         DEE_TYPE_SERIALIZABLE_MODEL,
                         G_IMPLEMENT_INTERFACE (DEE_TYPE_MODEL,
                                                dee_sequence_model_model_iface_init));

#define DEE_SEQUENCE_MODEL_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_SEQUENCE_MODEL, DeeSequenceModelPrivate))

/* Signal ids for emitting row update signals a just a smidgeon faster */
static guint sigid_row_added;
static guint sigid_row_removed;
static guint sigid_row_changed;

/**
 * DeeSequenceModelPrivate:
 *
 * Ignore this structure.
 */
struct _DeeSequenceModelPrivate
{
  /* Row data is is an array of gpointers. The last pointer in the array
   * points to the list of tags for the row. All items before are straight
   * old GVariants */
  GSequence *sequence;

  /* The tag registry. The data members of the list simply contain the
   * GDestroyNotify for the tag. The tag handle is the offset into the
   * list + 1. We need the +1 to discern the first tag from a NULL pointer.
   * We can use offsets as we expect only very few tags per model */
  GSList    *tags;

  /* Flag marking if we are in a transaction */
  gboolean   setting_many;
};

/*
 * DeeModel forward declarations
 */
static guint          dee_sequence_model_get_n_rows     (DeeModel *self);

static DeeModelIter*  dee_sequence_model_append_row  (DeeModel  *self,
                                                      GVariant **row_members);

static DeeModelIter*  dee_sequence_model_prepend_row  (DeeModel  *self,
                                                       GVariant **row_members);

static DeeModelIter*  dee_sequence_model_insert_row_before (DeeModel     *self,
                                                            DeeModelIter *iter,
                                                            GVariant **row_members);

static DeeModelIter*  dee_sequence_model_find_row_sorted (DeeModel           *self,
                                                          GVariant          **row_spec,
                                                          DeeCompareRowFunc   cmp_func,
                                                          gpointer            user_data,
                                                          gboolean           *out_was_found);

static void           dee_sequence_model_remove         (DeeModel     *self,
                                                         DeeModelIter *iter);

static void           dee_sequence_model_set_row     (DeeModel       *self,
                                                      DeeModelIter   *iter,
                                                      GVariant      **row_members);

static void           dee_sequence_model_set_value      (DeeModel       *self,
                                                         DeeModelIter   *iter,
                                                         guint           column,
                                                         GVariant       *value);

static void           dee_sequence_model_set_value_silently (DeeModel       *self,
                                                             DeeModelIter   *iter,
                                                             guint           column,
                                                             const gchar    *col_schema,
                                                             GVariant       *value);


static GVariant*     dee_sequence_model_get_value      (DeeModel     *self,
                                                        DeeModelIter *iter,
                                                        guint         column);

static GVariant**    dee_sequence_model_get_row        (DeeModel     *self,
                                                        DeeModelIter *iter,
                                                        GVariant    **out_row_members);

static DeeModelIter* dee_sequence_model_get_first_iter  (DeeModel     *self);

static DeeModelIter* dee_sequence_model_get_last_iter   (DeeModel     *self);

static DeeModelIter* dee_sequence_model_get_iter_at_row (DeeModel     *self,
                                                         guint          row);

static gboolean       dee_sequence_model_get_bool       (DeeModel    *self,
                                                         DeeModelIter *iter,
                                                         guint         column);

static guchar         dee_sequence_model_get_uchar      (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static gint32         dee_sequence_model_get_int32     (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static guint32        dee_sequence_model_get_uint32    (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static gint64         dee_sequence_model_get_int64      (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static guint64        dee_sequence_model_get_uint64     (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static gdouble        dee_sequence_model_get_double     (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static const gchar*   dee_sequence_model_get_string     (DeeModel     *self,
                                                         DeeModelIter *iter,
                                                         guint          column);

static DeeModelIter* dee_sequence_model_next            (DeeModel     *self,
                                                         DeeModelIter *iter);

static DeeModelIter* dee_sequence_model_prev            (DeeModel     *self,
                                                         DeeModelIter *iter);

static gboolean       dee_sequence_model_is_first       (DeeModel     *self,
                                                         DeeModelIter *iter);

static gboolean       dee_sequence_model_is_last        (DeeModel     *self,
                                                         DeeModelIter *iter);

static guint          dee_sequence_model_get_position   (DeeModel     *self,
                                                         DeeModelIter *iter);

static DeeModelTag*   dee_sequence_model_register_tag    (DeeModel       *self,
                                                          GDestroyNotify  tag_destroy);

static gpointer       dee_sequence_model_get_tag         (DeeModel       *self,
                                                          DeeModelIter   *iter,
                                                          DeeModelTag    *tag);

static void           dee_sequence_model_set_tag         (DeeModel       *self,
                                                          DeeModelIter   *iter,
                                                          DeeModelTag    *tag,
                                                          gpointer        value);

/*
 * Private forwards
 */
static gpointer *     dee_sequence_model_create_empty_row (DeeModel *self);

static void           dee_sequence_model_free_row (DeeSequenceModel *self,
                                                   GSequenceIter    *iter);

static void           dee_sequence_model_find_tag (DeeSequenceModel  *self,
                                                   DeeModelIter      *iter,
                                                   DeeModelTag       *tag,
                                                   GSList           **out_row_tag,
                                                   GSList           **out_tag);

/* GObject Init */
static void
dee_sequence_model_finalize (GObject *object)
{
  DeeSequenceModel        *self = DEE_SEQUENCE_MODEL (object);
  DeeSequenceModelPrivate *priv = self->priv;
  GSequenceIter           *iter, *end;

  /* Free row data */
  end = g_sequence_get_end_iter (priv->sequence);
  iter = g_sequence_get_begin_iter (priv->sequence);
  while (iter != end)
    {
      dee_sequence_model_free_row (self, iter);
      iter = g_sequence_iter_next (iter);
    }

  /* Free our GSequence */
  g_sequence_free (priv->sequence);
  priv->sequence = NULL;

  /* Free the tag registry. The list members need no freeing,
   * they are just function pointers */
  g_slist_free (priv->tags);
  priv->tags = NULL;

  G_OBJECT_CLASS (dee_sequence_model_parent_class)->finalize (object);
}

static void
dee_sequence_model_set_property (GObject      *object,
                                 guint         id,
                                 const GValue *value,
                                 GParamSpec   *pspec)
{
  switch (id)
    {
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_sequence_model_get_property (GObject    *object,
                                 guint       id,
                                 GValue     *value,
                                 GParamSpec *pspec)
{
  switch (id)
    {
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_sequence_model_class_init (DeeSequenceModelClass *klass)
{
  GObjectClass  *obj_class = G_OBJECT_CLASS (klass);

  obj_class->finalize     = dee_sequence_model_finalize;  
  obj_class->set_property = dee_sequence_model_set_property;
  obj_class->get_property = dee_sequence_model_get_property;

  /* Find signal ids for the model modification signals */
  sigid_row_added = g_signal_lookup ("row-added", DEE_TYPE_MODEL);
  sigid_row_removed = g_signal_lookup ("row-removed", DEE_TYPE_MODEL);
  sigid_row_changed = g_signal_lookup ("row-changed", DEE_TYPE_MODEL);

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeSequenceModelPrivate));
}

static void
dee_sequence_model_model_iface_init (DeeModelIface *iface)
{
  iface->get_n_rows           = dee_sequence_model_get_n_rows;
  iface->prepend_row          = dee_sequence_model_prepend_row;
  iface->append_row           = dee_sequence_model_append_row;
  iface->insert_row_before    = dee_sequence_model_insert_row_before;
  iface->find_row_sorted      = dee_sequence_model_find_row_sorted;
  iface->remove               = dee_sequence_model_remove;
  iface->set_row              = dee_sequence_model_set_row;
  iface->set_value            = dee_sequence_model_set_value;
  iface->get_value            = dee_sequence_model_get_value;
  iface->get_row              = dee_sequence_model_get_row;
  iface->get_first_iter       = dee_sequence_model_get_first_iter;
  iface->get_last_iter        = dee_sequence_model_get_last_iter;
  iface->get_iter_at_row      = dee_sequence_model_get_iter_at_row;
  iface->get_bool             = dee_sequence_model_get_bool;
  iface->get_uchar            = dee_sequence_model_get_uchar;
  iface->get_int32            = dee_sequence_model_get_int32;
  iface->get_uint32           = dee_sequence_model_get_uint32;
  iface->get_int64            = dee_sequence_model_get_int64;
  iface->get_uint64           = dee_sequence_model_get_uint64;
  iface->get_double           = dee_sequence_model_get_double;
  iface->get_string           = dee_sequence_model_get_string;
  iface->next                 = dee_sequence_model_next;
  iface->prev                 = dee_sequence_model_prev;
  iface->is_first             = dee_sequence_model_is_first;
  iface->is_last              = dee_sequence_model_is_last;
  iface->get_position         = dee_sequence_model_get_position;
  iface->register_tag         = dee_sequence_model_register_tag;
  iface->get_tag              = dee_sequence_model_get_tag;
  iface->set_tag              = dee_sequence_model_set_tag;
}

static void
dee_sequence_model_init (DeeSequenceModel *model)
{
  DeeSequenceModelPrivate *priv;

  priv = model->priv = DEE_SEQUENCE_MODEL_GET_PRIVATE (model);
  priv->sequence = g_sequence_new (NULL);
  priv->tags = NULL;
  priv->setting_many = FALSE;
}

/* Private Methods */

/*
 * DeeModel Interface Implementation
 */

static guint
dee_sequence_model_get_n_rows (DeeModel *self)
{
  DeeSequenceModelPrivate *priv;

  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), 0);
  priv = ((DeeSequenceModel *) self)->priv;

  return g_sequence_get_length (priv->sequence);
}

static DeeModelIter*
dee_sequence_model_prepend_row (DeeModel  *self,
                                GVariant **row_members)
{
  DeeSequenceModel        *_self = (DeeSequenceModel *) self;
  DeeSequenceModelPrivate *priv;
  DeeModelIter            *iter;
  gpointer                *row;

  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (_self), NULL);
  g_return_val_if_fail (row_members != NULL, NULL);

  priv = _self->priv;
  row = dee_sequence_model_create_empty_row (self);
  iter = (DeeModelIter*) g_sequence_prepend (priv->sequence, row);
  
  priv->setting_many = TRUE;
  dee_model_set_row (self, iter, row_members);
  priv->setting_many = FALSE;

  dee_serializable_model_inc_seqnum (self);
  g_signal_emit (self, sigid_row_added, 0, iter);
  
  return iter;
}

static DeeModelIter*
dee_sequence_model_append_row (DeeModel  *self,
                               GVariant **row_members)
{
  DeeSequenceModel        *_self = (DeeSequenceModel *) self;
  DeeSequenceModelPrivate *priv;
  DeeModelIter            *iter;
  gpointer                *row;

  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (_self), NULL);
  g_return_val_if_fail (row_members != NULL, NULL);

  priv = _self->priv;
  row = dee_sequence_model_create_empty_row (self);
  iter = (DeeModelIter*) g_sequence_append (priv->sequence, row);
  
  priv->setting_many = TRUE;
  dee_model_set_row (self, iter, row_members);
  priv->setting_many = FALSE;

  dee_serializable_model_inc_seqnum (self);
  g_signal_emit (self, sigid_row_added, 0, iter);
  
  return iter;
}

static DeeModelIter*
dee_sequence_model_insert_row_before (DeeModel      *self,
                                      DeeModelIter  *iter,
                                      GVariant     **row_members)
{
  DeeSequenceModelPrivate *priv;
  gpointer                *row;

  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), NULL);
  g_return_val_if_fail (iter != NULL, NULL);
  g_return_val_if_fail (row_members != NULL, NULL);

  priv = DEE_SEQUENCE_MODEL (self)->priv;
  row = dee_sequence_model_create_empty_row (self);
  iter = (DeeModelIter*) g_sequence_insert_before ((GSequenceIter *) iter,
                                                   row);

  priv->setting_many = TRUE;
  dee_model_set_row (self, iter, row_members);
  priv->setting_many = FALSE;

  dee_serializable_model_inc_seqnum (self);
  g_signal_emit (self, sigid_row_added, 0, iter);
  
  return iter;
}

/* logN search using the tree structure of GSeq */
static DeeModelIter*
dee_sequence_model_find_row_sorted (DeeModel           *self,
                                    GVariant          **row_spec,
                                    DeeCompareRowFunc   cmp_func,
                                    gpointer            user_data,
                                    gboolean           *out_was_found)
{
  DeeSequenceModelPrivate *priv;
  GSequenceIter           *iter;

  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), NULL);
  g_return_val_if_fail (row_spec != NULL, NULL);
  g_return_val_if_fail (cmp_func != NULL, NULL);

  priv = DEE_SEQUENCE_MODEL (self)->priv;
  iter = g_sequence_search (priv->sequence, row_spec,
                            (GCompareDataFunc)cmp_func, user_data);

  /* Kinda awkward - if we did find the row then GSequence has placed just
   * after the row we wanted. If we did not find it, then we're in the right
   * place */
  if (!g_sequence_iter_is_begin (iter))
    {
      GSequenceIter *jter = g_sequence_iter_prev (iter);
      if (cmp_func (g_sequence_get (jter), row_spec, user_data) == 0)
        {
          if (out_was_found != NULL) *out_was_found = TRUE;
          return (DeeModelIter *) jter;
        }
    }

  if (out_was_found != NULL) *out_was_found = FALSE;

  return (DeeModelIter *) iter;
}

static void
dee_sequence_model_remove (DeeModel     *self,
                           DeeModelIter *iter_)
{
  DeeSequenceModel        *_self = (DeeSequenceModel *)self;
  GSequenceIter           *iter = (GSequenceIter *)iter_;

  g_return_if_fail (DEE_IS_SEQUENCE_MODEL (_self));
  g_return_if_fail (iter != NULL);
  g_return_if_fail (!g_sequence_iter_is_end (iter));

  if (iter)
    {
      /* Emit the removed signal while the iter is still valid,
       * but after we increased the seqnum */
      dee_serializable_model_inc_seqnum (self);
      g_signal_emit (self, sigid_row_removed, 0, iter_);
      dee_sequence_model_free_row (_self, iter);
      g_sequence_remove (iter);
    }
  else
    {
      g_warning ("Unable to remove row '%p': does not exists", iter_);
    }
}

static void
dee_sequence_model_set_value (DeeModel      *self,
                              DeeModelIter  *iter,
                              guint          column,
                              GVariant      *value)
{
  DeeSequenceModel        *_self = (DeeSequenceModel *)self;
  DeeSequenceModelPrivate *priv;

  g_return_if_fail (DEE_IS_SEQUENCE_MODEL (_self));
  g_return_if_fail (iter != NULL);
  g_return_if_fail (value != NULL);
  g_return_if_fail (column < dee_model_get_n_columns (self));
  
  priv = _self->priv;
  
  dee_sequence_model_set_value_silently (self, iter, column,
      dee_model_get_column_schema (self, column), value);
  
  if (priv->setting_many == FALSE)
    {
      dee_serializable_model_inc_seqnum (self);
      g_signal_emit (self, sigid_row_changed, 0, iter);
    }
}

static void
dee_sequence_model_set_row (DeeModel      *self,
                            DeeModelIter  *iter,
                            GVariant      **row_members)
{
  DeeSequenceModel        *_self = (DeeSequenceModel *)self;
  DeeSequenceModelPrivate *priv;
  guint                    i, n_cols;
  const gchar *const      *schema;

  g_return_if_fail (DEE_IS_SEQUENCE_MODEL (_self));
  g_return_if_fail (iter != NULL);
  g_return_if_fail (row_members != NULL);

  priv = _self->priv;
  schema = dee_model_get_schema (self, &n_cols);

  for (i = 0; i < n_cols; i++)
    {
      dee_sequence_model_set_value_silently (self, iter, i, schema[i],
                                             row_members[i]);
    }

  if (priv->setting_many == FALSE)
    {
      dee_serializable_model_inc_seqnum (self);
      g_signal_emit (self, sigid_row_changed, 0, iter);
    }
}

static void
dee_sequence_model_set_value_silently (DeeModel      *self,
                                       DeeModelIter  *iter,
                                       guint          column,
                                       const gchar   *col_schema,
                                       GVariant      *value)
{
  gpointer                *row;

  g_return_if_fail (g_variant_type_equal (g_variant_get_type (value),
                                          G_VARIANT_TYPE (col_schema)));

  row = g_sequence_get ((GSequenceIter *) iter);

  if (G_UNLIKELY (row == NULL))
      {
        g_critical ("Unable to set value. NULL row data in DeeSequenceModel@%p "
                    "at position %u. The row has probably been removed",
                    self, dee_model_get_position (self, iter));
        return;
      }

  if (row[column] != NULL)
    g_variant_unref (row[column]);

  row[column] = g_variant_ref_sink (value);
}

static GVariant*
dee_sequence_model_peek_value (DeeModel     *self,
                               DeeModelIter *iter,
                               guint         column)
{
  gpointer         *row;

  row = g_sequence_get ((GSequenceIter *) iter);
  if (G_UNLIKELY (row == NULL))
    {
      g_critical ("Unable to get value. NULL row data in DeeSequenceModel@%p "
                  "at position %u. The row has probably been removed",
                  self, dee_model_get_position (self, iter));
      return NULL;
    }
  
  return row[column];
}

static GVariant*
dee_sequence_model_get_value (DeeModel     *self,
                              DeeModelIter *iter,
                              guint         column)
{
  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), NULL);
  g_return_val_if_fail (iter != NULL, NULL);
  g_return_val_if_fail (column < dee_model_get_n_columns (self), NULL);

  GVariant *val = dee_sequence_model_peek_value (self, iter, column);

  if (G_UNLIKELY (val == NULL))
    {
      g_critical ("Unable to get value. Column %i in DeeSequenceModel@%p"
                  " holds a NULL value in row %u",
                  column, self, dee_model_get_position (self, iter));
      return NULL;
    }

  return g_variant_ref (val);
}

static GVariant**
dee_sequence_model_get_row (DeeModel      *self,
                            DeeModelIter  *iter,
                            GVariant     **out_row_members)
{
  guint            col, n_cols;

  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), NULL);

  n_cols = dee_model_get_n_columns (self);

  if (out_row_members == NULL)
    out_row_members = g_new0 (GVariant*, n_cols + 1);

  /* We use peek_value() here because it saves us from some expensive checks
   * compared to get_value(), that we can guarantee from this call site anyway
   */
  for (col = 0; col < n_cols; col++)
    out_row_members[col] = g_variant_ref (
                               dee_sequence_model_peek_value (self, iter, col));

  return out_row_members;
}

static DeeModelIter*
dee_sequence_model_get_first_iter (DeeModel     *self)
{
  DeeSequenceModel *_self = (DeeSequenceModel *)self;
  
  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (_self), NULL);

  return (DeeModelIter *) g_sequence_get_begin_iter (_self->priv->sequence);
}

static DeeModelIter*
dee_sequence_model_get_last_iter (DeeModel *self)
{
  DeeSequenceModel *_self = (DeeSequenceModel *)self;

  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (_self), NULL);

  return (DeeModelIter *) g_sequence_get_end_iter (_self->priv->sequence);
}

static DeeModelIter*
dee_sequence_model_get_iter_at_row (DeeModel *self, guint row)
{
  DeeSequenceModel *_self = (DeeSequenceModel *)self;
  
  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), NULL);

  return (DeeModelIter *) g_sequence_get_iter_at_pos (_self->priv->sequence,
                                                      row);
}

static gboolean
dee_sequence_model_get_bool (DeeModel    *self,
                             DeeModelIter *iter,
                             guint         column)
{
  GVariant *val = dee_sequence_model_peek_value (self, iter, column);

  if (G_UNLIKELY (val == NULL))
    {
      g_critical ("Unable to get boolean. Column %i in DeeSequenceModel@%p"
                  " holds a NULL value in row %u",
                  column, self, dee_model_get_position (self, iter));
      return FALSE;
    }

  return g_variant_get_boolean (val);
}

static guchar
dee_sequence_model_get_uchar (DeeModel     *self,
                              DeeModelIter *iter,
                              guint          column)
{
  GVariant *val = dee_sequence_model_peek_value (self, iter, column);;

  if (G_UNLIKELY (val == NULL))
    {
      g_critical ("Unable to get byte. Column %i in DeeSequenceModel@%p"
                  " holds a NULL value in row %u",
                  column, self, dee_model_get_position (self, iter));
      return '\0';
    }

  return g_variant_get_byte (val);
}

static gint32
dee_sequence_model_get_int32 (DeeModel     *self,
                              DeeModelIter *iter,
                              guint          column)
{
  GVariant *val = dee_sequence_model_peek_value (self, iter, column);;

  if (G_UNLIKELY (val == NULL))
    {
      g_critical ("Unable to get int32. Column %i in DeeSequenceModel@%p"
                  " holds a NULL value in row %u",
                  column, self, dee_model_get_position (self, iter));
      return 0;
    }

  return g_variant_get_int32 (val);
}

static guint32
dee_sequence_model_get_uint32 (DeeModel     *self,
                               DeeModelIter *iter,
                               guint          column)
{
  GVariant *val = dee_sequence_model_peek_value (self, iter, column);;

  if (G_UNLIKELY (val == NULL))
    {
      g_critical ("Unable to get uint32. Column %i in DeeSequenceModel@%p"
                  " holds a NULL value in row %u",
                  column, self, dee_model_get_position (self, iter));
      return 0;
    }

  return g_variant_get_uint32 (val);
}

static gint64
dee_sequence_model_get_int64 (DeeModel     *self,
                              DeeModelIter *iter,
                              guint          column)
{
  GVariant *val = dee_sequence_model_peek_value (self, iter, column);;

  if (G_UNLIKELY (val == NULL))
    {
      g_critical ("Unable to get int64. Column %i in DeeSequenceModel@%p"
                  " holds a NULL value in row %u",
                  column, self, dee_model_get_position (self, iter));
      return G_GINT64_CONSTANT (0);
    }

  return g_variant_get_int64 (val);
}

static guint64
dee_sequence_model_get_uint64 (DeeModel     *self,
                               DeeModelIter *iter,
                               guint          column)
{
  GVariant *val = dee_sequence_model_peek_value (self, iter, column);;

  if (G_UNLIKELY (val == NULL))
    {
      g_critical ("Unable to get uint64. Column %i in DeeSequenceModel@%p"
                  " holds a NULL value in row %u",
                  column, self, dee_model_get_position (self, iter));
      return G_GUINT64_CONSTANT (0);
    }

  return g_variant_get_uint64 (val);
}

static gdouble
dee_sequence_model_get_double (DeeModel     *self,
                               DeeModelIter *iter,
                               guint          column)
{
  GVariant *val = dee_sequence_model_peek_value (self, iter, column);;

  if (G_UNLIKELY (val == NULL))
    {
      g_critical ("Unable to get double. Column %i in DeeSequenceModel@%p"
                  " holds a NULL value in row %u",
                  column, self, dee_model_get_position (self, iter));
      return 0;
    }

  return g_variant_get_double (val);
}

static const gchar*
dee_sequence_model_get_string     (DeeModel     *self,
                                   DeeModelIter *iter,
                                   guint          column)
{
  GVariant *val = dee_sequence_model_peek_value (self, iter, column);;

  if (G_UNLIKELY (val == NULL))
    {
      g_critical ("Unable to get string. Column %i in DeeSequenceModel@%p"
                  " holds a NULL value in row %u",
                  column, self, dee_model_get_position (self, iter));
      return NULL;
    }

  return g_variant_get_string (val, NULL);
}

static DeeModelIter*
dee_sequence_model_next (DeeModel     *self,
                         DeeModelIter *iter)
{
  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), NULL);
  g_return_val_if_fail (iter, NULL);
  g_return_val_if_fail (!g_sequence_iter_is_end ((GSequenceIter*) iter), NULL);

  return (DeeModelIter *) g_sequence_iter_next ((GSequenceIter *)iter);
}

static DeeModelIter*
dee_sequence_model_prev (DeeModel     *self,
                         DeeModelIter *iter)
{
  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), NULL);
  g_return_val_if_fail (iter, NULL);
  g_return_val_if_fail (!g_sequence_iter_is_begin ((GSequenceIter*) iter), NULL);

  return (DeeModelIter *) g_sequence_iter_prev ((GSequenceIter *)iter);
}

static gboolean
dee_sequence_model_is_first (DeeModel     *self,
                             DeeModelIter *iter)
{
  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), FALSE);
  g_return_val_if_fail (iter, FALSE);

  return g_sequence_iter_is_begin ((GSequenceIter *)iter);
}

static gboolean
dee_sequence_model_is_last (DeeModel     *self,
                            DeeModelIter *iter)
{
  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), FALSE);
  g_return_val_if_fail (iter, FALSE);

  return g_sequence_iter_is_end ((GSequenceIter *)iter);
}

static guint
dee_sequence_model_get_position (DeeModel     *self,
                                 DeeModelIter *iter)
{
  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), FALSE);
  g_return_val_if_fail (iter, FALSE);

  return g_sequence_iter_get_position ((GSequenceIter *)iter);
}

static DeeModelTag*
dee_sequence_model_register_tag (DeeModel       *self,
                                 GDestroyNotify  tag_destroy)
{
  DeeSequenceModelPrivate *priv;
  GSequenceIter           *iter, *end;
  gpointer                *row;
  guint                    tag_handle, n_cols;

  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), NULL);

  priv = DEE_SEQUENCE_MODEL (self)->priv;

  /* Register the tag. Multiple iterations of the tags list is not
   * a big deal here because we only expect very few tags per model */
  priv->tags = g_slist_append (priv->tags, tag_destroy);
  tag_handle = g_slist_length (priv->tags);

  /* Update all existing rows to have this tag */
  n_cols = dee_model_get_n_columns (self);
  end = g_sequence_get_end_iter (priv->sequence);
  iter = g_sequence_get_begin_iter (priv->sequence);
  while (iter != end)
    {
      row = g_sequence_get (iter);
      row[n_cols] = g_slist_append (row[n_cols], NULL);
      iter = g_sequence_iter_next (iter);
    }

  return (DeeModelTag *) GUINT_TO_POINTER (tag_handle);
}

static gpointer
dee_sequence_model_get_tag (DeeModel       *self,
                            DeeModelIter   *iter,
                            DeeModelTag    *tag)
{
  DeeSequenceModel        *_self;
  GSList                  *row_tag_l, *tag_l;

  g_return_val_if_fail (DEE_IS_SEQUENCE_MODEL (self), NULL);
  g_return_val_if_fail (iter != NULL, NULL);
  g_return_val_if_fail (tag != NULL, NULL);

  _self = DEE_SEQUENCE_MODEL (self);
  dee_sequence_model_find_tag (_self, iter, tag, &row_tag_l, &tag_l);

  if (row_tag_l == NULL || tag_l == NULL)
    {
      g_critical ("Failed to get tag %u on %s@%p",
                  GPOINTER_TO_UINT (tag), G_OBJECT_TYPE_NAME (self), self);
      return NULL;
    }

  return row_tag_l->data;
}

void
dee_sequence_model_set_tag (DeeModel       *self,
                            DeeModelIter   *iter,
                            DeeModelTag    *tag,
                            gpointer        value)
{
  DeeSequenceModel        *_self;
  GSList                  *row_tag_l, *tag_l;
  GDestroyNotify           destroy;
  gpointer                 old_value;

  g_return_if_fail (DEE_IS_SEQUENCE_MODEL (self));
  g_return_if_fail (iter != NULL);
  g_return_if_fail (tag != NULL);

  _self = DEE_SEQUENCE_MODEL (self);
  dee_sequence_model_find_tag (_self, iter, tag, &row_tag_l, &tag_l);

  if (row_tag_l == NULL || tag_l == NULL)
    {
      g_critical ("Failed to set tag %u on %s@%p",
                  GPOINTER_TO_UINT (tag), G_OBJECT_TYPE_NAME (self), self);
      return;
    }

  destroy = (GDestroyNotify) tag_l->data;
  old_value = row_tag_l->data;

  if (destroy && old_value)
    {
      destroy (old_value);
    }

  row_tag_l->data = value;
}

/*
 * Private methods
 */
 /* Create an array with the right amount of elements, all set to NULL */
static gpointer*
dee_sequence_model_create_empty_row (DeeModel *self)
{
  DeeSequenceModelPrivate *priv;
  gpointer                *row;
  guint                    n_columns;
  GSList                  *tag_iter;

  /* The row tags are stored as a GSList on the n_columns+1 index of the row.
   * Zeroing the memory below is important since it gives us an empty GSList
   * for the tags on the final position */
  priv = ((DeeSequenceModel *)self)->priv;
  n_columns = dee_model_get_n_columns (self);
  row = g_slice_alloc0 (sizeof (gpointer) * (n_columns + 1));

  /* Populate the row tag list to have the same length as our tag registry */
  for (tag_iter = priv->tags; tag_iter; tag_iter = tag_iter->next)
    {
      row[n_columns] =
              g_slist_prepend (row[n_columns], NULL);
    }

  return row;
}

static void
dee_sequence_model_free_row (DeeSequenceModel *self,
                             GSequenceIter    *iter)
{
  DeeSequenceModelPrivate *priv;
  gpointer                *row;
  guint                    n_cols, i;
  GSList                  *tag_iter, *row_tag_iter, *dum;
  GDestroyNotify           destroy;

  priv = self->priv;
  row = g_sequence_get (iter);
  n_cols = dee_model_get_n_columns (DEE_MODEL (self));

  /* Free the row data */
  for (i = 0; i < n_cols; i++)
    g_variant_unref (row[i]);

  /* Free any row tags */
  row_tag_iter = row[n_cols];
  tag_iter = priv->tags;
  while (row_tag_iter && tag_iter)
    {
      destroy = (GDestroyNotify) tag_iter->data;
      if (destroy != NULL  && row_tag_iter->data != NULL)
        destroy (row_tag_iter->data);

      /* Free the GSList element for the row tag while we're here anyway */
      dum = row_tag_iter->next;
      g_slist_free_1 (row_tag_iter);
      row_tag_iter = dum;

      tag_iter = tag_iter->next;
    }

  if (row_tag_iter != NULL)
    {
      g_critical ("Internal error: Row tags leaked. "
                  "More row tags for this row than there are registered tags.");
    }
  else if (tag_iter != NULL)
    {
      g_critical ("Internal error: Row tags leaked. "
                  "More tags registered than there are tags for this row.");
    }

  /* Free the row itself */
  g_slice_free1 (sizeof (gpointer) * (n_cols + 1), row);

  /* Set the row data to NULL to help debugging for consumers accessing
   * removed rows*/
  g_sequence_set (iter, NULL);
}

static void
dee_sequence_model_find_tag (DeeSequenceModel  *self,
                             DeeModelIter      *iter,
                             DeeModelTag       *tag,
                             GSList           **out_row_tag,
                             GSList           **out_tag)
{
  DeeSequenceModelPrivate *priv;
  gpointer                *row;
  guint                    tag_offset, i, n_cols;
  GSList                  *row_tag_iter, *tag_iter;

  priv = self->priv;
  row = g_sequence_get ((GSequenceIter *) iter);
  n_cols = dee_model_get_n_columns (DEE_MODEL (self));
  tag_offset = GPOINTER_TO_UINT (tag);

  if (G_UNLIKELY (priv->sequence == NULL))
    {
      g_critical ("Access to freed DeeSequenceModel detected "
                  "when looking up tag on DeeSequenceModel@%p", self);
      goto not_found;
    }

  if (G_UNLIKELY (priv->tags == NULL))
    {
      g_critical ("Unable to look up tag. No tags registered on "
                  "DeeSequenceModel@%p", self);
      goto not_found;
    }

  if (G_UNLIKELY (row == NULL))
    {
      g_critical ("Unable to look up tag. No row data. "
                  "The row has probably been removed ");
            goto not_found;
    }

  /* Find tag at right offset */
  row_tag_iter = row[n_cols];
  tag_iter = priv->tags;
  i = 1; // remember 1-based offset for tag handles
  while (row_tag_iter && tag_iter && i < tag_offset)
    {
      row_tag_iter = row_tag_iter->next;
      tag_iter = tag_iter->next;
      i++;
    }

  if (i != tag_offset)
    {
      g_critical ("Unable to find tag %u for %s@%p",
                  tag_offset, G_OBJECT_TYPE_NAME (self), self);
      goto not_found;
    }

  *out_row_tag = row_tag_iter;
  *out_tag = tag_iter;
  return;

  not_found:
    *out_row_tag = NULL;
    *out_tag = NULL;
}

/*
 * Constructors
 */

/**
 * dee_sequence_model_new:
 *
 * Create a new #DeeSequenceModel. Before using it you must normally set a
 * schema on it by calling dee_model_set_schema().
 *
 * Return value: (transfer full) (type DeeSequenceModel): A newly created 
 *               #DeeSequenceModel. Free with g_object_unref().
 *
 */
DeeModel*
dee_sequence_model_new ()
{
  DeeModel *self;

  self = DEE_MODEL (g_object_new (DEE_TYPE_SEQUENCE_MODEL, NULL));
  return self;
}
