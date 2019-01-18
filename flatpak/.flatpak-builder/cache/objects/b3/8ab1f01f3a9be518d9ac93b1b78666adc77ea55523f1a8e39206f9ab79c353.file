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
 * SECTION:dee-proxy-model
 * @short_description: A model that wraps another underlying #DeeModel
 * @include: dee.h
 *
 * #DeeProxyModel wraps another #DeeModel instance and use it as a back end
 * by proxuing all method calls down to the back end.
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <memory.h>
#include <time.h>
#include <unistd.h>

#include "dee-model.h"
#include "dee-proxy-model.h"
#include "dee-serializable-model.h"
#include "dee-marshal.h"
#include "trace-log.h"

static void dee_proxy_model_model_iface_init (DeeModelIface *iface);

G_DEFINE_TYPE_WITH_CODE (DeeProxyModel,
                         dee_proxy_model,
                         DEE_TYPE_SERIALIZABLE_MODEL,
                         G_IMPLEMENT_INTERFACE (DEE_TYPE_MODEL,
                                                dee_proxy_model_model_iface_init));

#define DEE_PROXY_MODEL_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_PROXY_MODEL, DeeProxyModelPrivate))

enum
{
  PROP_0,
  PROP_BACK_END,
  PROP_PROXY_SIGNALS,
  PROP_INHERIT_SEQNUMS
};

/**
 * DeeProxyModelPrivate:
 *
 * Ignore this structure.
 */
struct _DeeProxyModelPrivate
{
  /* The backend model holding the actual data */
  DeeModel  *back_end;
  
  /* Whether to use the seqnums of the backend model (if it's versioned),
   * or to use our own seqnums */
  gboolean   inherit_seqnums;
  
  /* Whether or not to automatically forward signals from the back end */
  gboolean   proxy_signals;
  
  /* Signals handlers for relaying signals from the back end */
  gulong     row_added_handler;
  gulong     row_removed_handler;
  gulong     row_changed_handler;
  gulong     changeset_started_handler;
  gulong     changeset_finished_handler;
};

#define DEE_PROXY_MODEL_BACK_END(model) (DEE_PROXY_MODEL(model)->priv->back_end)
#define SUPER_CLASS DEE_SERIALIZABLE_MODEL_CLASS (dee_proxy_model_parent_class)

/*
 * DeeModel forward declarations
 */
static void           dee_proxy_model_set_schema_full (DeeModel           *self,
                                                       const gchar* const *schema,
                                                       guint               num_columns);

static const gchar* const* dee_proxy_model_get_schema (DeeModel *self,
                                                       guint    *num_columns);

static const gchar*   dee_proxy_model_get_column_schema (DeeModel *self,
                                                         guint      column);

static const gchar*   dee_proxy_model_get_field_schema  (DeeModel    *self,
                                                         const gchar *field_name,
                                                         guint       *out_column);

static gint           dee_proxy_model_get_column_index (DeeModel    *self,
                                                        const gchar *column_name);

static void           dee_proxy_model_set_column_names (DeeModel     *self,
                                                        const gchar **column_names,
                                                        guint         num_columns);

static const gchar**  dee_proxy_model_get_column_names (DeeModel *self,
                                                        guint    *num_columns);

static void           dee_proxy_model_register_vardict_schema (DeeModel   *self,
                                                               guint       column,
                                                               GHashTable *schema);

static GHashTable*    dee_proxy_model_get_vardict_schema (DeeModel   *self,
                                                          guint       column);

static guint          dee_proxy_model_get_n_columns  (DeeModel *self);

static guint          dee_proxy_model_get_n_rows     (DeeModel *self);

static void           dee_proxy_model_clear          (DeeModel *self);

static DeeModelIter*  dee_proxy_model_append_row  (DeeModel  *self,
                                                   GVariant **row_members);

static DeeModelIter*  dee_proxy_model_prepend_row  (DeeModel  *self,
                                                    GVariant **row_members);

static DeeModelIter*  dee_proxy_model_insert_row  (DeeModel  *self,
                                                   guint      pos,
                                                   GVariant **row_members);

static DeeModelIter*  dee_proxy_model_insert_row_before (DeeModel      *self,
                                                         DeeModelIter  *iter,
                                                         GVariant     **row_members);

static DeeModelIter*  dee_proxy_model_insert_row_sorted (DeeModel           *self,
                                                         GVariant          **row_spec,
                                                         DeeCompareRowFunc   cmp_func,
                                                         gpointer            user_data);

static DeeModelIter*  dee_proxy_model_find_row_sorted (DeeModel           *self,
                                                       GVariant          **row_spec,
                                                       DeeCompareRowFunc   cmp_func,
                                                       gpointer            user_data,
                                                       gboolean           *out_was_found);

static void           dee_proxy_model_remove         (DeeModel     *self,
                                                      DeeModelIter *iter);

static void           dee_proxy_model_set_value      (DeeModel       *self,
                                                      DeeModelIter   *iter,
                                                      guint           column,
                                                      GVariant       *value);

static void           dee_proxy_model_set_row     (DeeModel       *self,
                                                   DeeModelIter   *iter,
                                                   GVariant      **row_members);

static GVariant*      dee_proxy_model_get_value      (DeeModel     *self,
                                                      DeeModelIter *iter,
                                                      guint          column);

static DeeModelIter* dee_proxy_model_get_first_iter  (DeeModel     *self);

static DeeModelIter* dee_proxy_model_get_last_iter   (DeeModel     *self);

static DeeModelIter* dee_proxy_model_get_iter_at_row (DeeModel     *self,
                                                      guint          row);

static gboolean       dee_proxy_model_get_bool       (DeeModel     *self,
                                                      DeeModelIter *iter,
                                                      guint          column);

static guchar         dee_proxy_model_get_uchar      (DeeModel     *self,
                                                      DeeModelIter *iter,
                                                      guint          column);

static gint32         dee_proxy_model_get_int32        (DeeModel     *self,
                                                        DeeModelIter *iter,
                                                        guint         column);

static guint32        dee_proxy_model_get_uint32     (DeeModel     *self,
                                                      DeeModelIter *iter,
                                                      guint         column);

static gint64         dee_proxy_model_get_int64      (DeeModel     *self,
                                                      DeeModelIter *iter,
                                                      guint          column);

static guint64        dee_proxy_model_get_uint64     (DeeModel     *self,
                                                      DeeModelIter *iter,
                                                      guint          column);

static gdouble        dee_proxy_model_get_double     (DeeModel     *self,
                                                      DeeModelIter *iter,
                                                      guint          column);

static const gchar*   dee_proxy_model_get_string     (DeeModel     *self,
                                                      DeeModelIter *iter,
                                                      guint         column);

static DeeModelIter* dee_proxy_model_next            (DeeModel     *self,
                                                      DeeModelIter *iter);

static DeeModelIter* dee_proxy_model_prev            (DeeModel     *self,
                                                      DeeModelIter *iter);

static gboolean       dee_proxy_model_is_first       (DeeModel     *self,
                                                      DeeModelIter *iter);

static gboolean       dee_proxy_model_is_last        (DeeModel     *self,
                                                      DeeModelIter *iter);

static guint          dee_proxy_model_get_position   (DeeModel     *self,
                                                      DeeModelIter *iter);

static DeeModelTag*   dee_proxy_model_register_tag   (DeeModel       *self,
                                                      GDestroyNotify  tag_destroy);

static gpointer       dee_proxy_model_get_tag        (DeeModel       *self,
                                                      DeeModelIter   *iter,
                                                      DeeModelTag    *tag);

static void           dee_proxy_model_set_tag        (DeeModel       *self,
                                                      DeeModelIter   *iter,
                                                      DeeModelTag    *tag,
                                                      gpointer        value);

static void           dee_proxy_model_begin_changeset (DeeModel *self);

static void           dee_proxy_model_end_changeset   (DeeModel *self);

/*
 * Callbacks for relaying signals from the back end model
 */
static void           on_back_end_row_added          (DeeProxyModel *self,
                                                      DeeModelIter  *iter);   

static void           on_back_end_row_removed        (DeeProxyModel *self,
                                                      DeeModelIter  *iter);

static void           on_back_end_row_changed        (DeeProxyModel *self,
                                                      DeeModelIter  *iter);

static void           on_back_end_changeset_started  (DeeProxyModel *self,
                                                      DeeModel *model);

static void           on_back_end_changeset_finished (DeeProxyModel *self,
                                                      DeeModel *model);

/*
 * Overrides for DeeSerializableModel
 */

static guint64   dee_proxy_model_get_seqnum  (DeeModel     *self);

static void      dee_proxy_model_set_seqnum  (DeeModel     *self,
                                              guint64       seqnum);

static guint64   dee_proxy_model_inc_seqnum  (DeeModel     *self);

/* GObject Init */
static void
dee_proxy_model_finalize (GObject *object)
{
  DeeProxyModelPrivate *priv = DEE_PROXY_MODEL (object)->priv;
  
  if (priv->back_end)
    {
      if (priv->row_added_handler != 0)
        g_signal_handler_disconnect (priv->back_end, priv->row_added_handler);
      if (priv->row_removed_handler != 0)
        g_signal_handler_disconnect (priv->back_end, priv->row_removed_handler);
      if (priv->row_changed_handler != 0)
        g_signal_handler_disconnect (priv->back_end, priv->row_changed_handler);
      if (priv->changeset_started_handler != 0)
        g_signal_handler_disconnect (priv->back_end, priv->changeset_started_handler);
      if (priv->changeset_finished_handler != 0)
        g_signal_handler_disconnect (priv->back_end, priv->changeset_finished_handler);

      g_object_unref (priv->back_end);
    }
  
  G_OBJECT_CLASS (dee_proxy_model_parent_class)->finalize (object);
}

/* GObject Post-Init. Properties has been set */
static void
dee_proxy_model_constructed (GObject *object)
{
  DeeProxyModelPrivate *priv = DEE_PROXY_MODEL (object)->priv;
  
  if (priv->back_end == NULL)
  {
    g_critical ("You must set the 'back-end' property of "
                "the DeeProxyModel upon creation.");
    return;
  }

  /* Connect to signals on the back-end model so we can relay them */
  if (priv->proxy_signals)
    {
      priv->row_added_handler =
        g_signal_connect_swapped (priv->back_end, "row-added",
                                  G_CALLBACK (on_back_end_row_added), object);
      priv->row_removed_handler =
        g_signal_connect_swapped (priv->back_end, "row-removed",
                                  G_CALLBACK (on_back_end_row_removed), object);
      priv->row_changed_handler =
        g_signal_connect_swapped (priv->back_end, "row-changed",
                                  G_CALLBACK (on_back_end_row_changed), object);

      priv->changeset_started_handler =
        g_signal_connect_swapped (priv->back_end, "changeset-started",
                                  G_CALLBACK (on_back_end_changeset_started),
                                  object);

      priv->changeset_finished_handler =
        g_signal_connect_swapped (priv->back_end, "changeset-finished",
                                  G_CALLBACK (on_back_end_changeset_finished),
                                  object);
    }
  
  /* GObjectClass has NULL 'constructed' member, but we add this check for
   * future robustness if we ever move to another base class */
  if (G_OBJECT_CLASS (dee_proxy_model_parent_class)->constructed != NULL)
    G_OBJECT_CLASS (dee_proxy_model_parent_class)->constructed (object);
}

static void
dee_proxy_model_set_property (GObject       *object,
                              guint          id,
                              const GValue  *value,
                              GParamSpec    *pspec)
{
  DeeProxyModelPrivate *priv = DEE_PROXY_MODEL (object)->priv;

  switch (id)
    {
    case PROP_BACK_END:
      priv->back_end = g_value_dup_object (value);
      break;
    case PROP_PROXY_SIGNALS:
      priv->proxy_signals = g_value_get_boolean (value);
      break;
    case PROP_INHERIT_SEQNUMS:
      priv->inherit_seqnums = g_value_get_boolean (value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_proxy_model_get_property (GObject     *object,
                              guint        id,
                              GValue      *value,
                              GParamSpec  *pspec)
{
  switch (id)
    {
    case PROP_BACK_END:
      g_value_set_object (value, DEE_PROXY_MODEL (object)->priv->back_end);
      break;
    case PROP_PROXY_SIGNALS:
      g_value_set_boolean (value, DEE_PROXY_MODEL (object)->priv->proxy_signals);
      break;
    case PROP_INHERIT_SEQNUMS:
      g_value_set_boolean (value, DEE_PROXY_MODEL (object)->priv->inherit_seqnums);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_proxy_model_class_init (DeeProxyModelClass *klass)
{
  GObjectClass           *obj_class = G_OBJECT_CLASS (klass);
  DeeSerializableModelClass *dvm_class = DEE_SERIALIZABLE_MODEL_CLASS (klass);
  GParamSpec             *pspec;

  obj_class->finalize     = dee_proxy_model_finalize;
  obj_class->constructed  = dee_proxy_model_constructed;
  obj_class->set_property = dee_proxy_model_set_property;
  obj_class->get_property = dee_proxy_model_get_property;

  dvm_class->get_seqnum          = dee_proxy_model_get_seqnum;
  dvm_class->set_seqnum          = dee_proxy_model_set_seqnum;
  dvm_class->inc_seqnum          = dee_proxy_model_inc_seqnum;

  /**
   * DeeProxyModel:back-end:
   *
   * The backend model used by this proxy model.
   **/
  pspec = g_param_spec_object ("back-end", "Back end",
                               "Back end model",
                               DEE_TYPE_MODEL,
                               G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                               | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_BACK_END, pspec);
  
  /**
   * DeeProxyModel:proxy-signals:
   *
   * Boolean property defining whether or not to automatically forward signals
   * from the back end model. This is especially useful for sub classes wishing
   * to do their own more advanced signal forwarding.
   **/
  pspec = g_param_spec_boolean ("proxy-signals", "Proxy signals",
                                "Whether or not to automatically forward signals from the back end",
                                TRUE,
                                G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                                | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_PROXY_SIGNALS, pspec);

  /**
   * DeeProxyModel:inherit-seqnums:
   *
   * Boolean property defining whether sequence numbers will be inherited
   * from the back end model.
   * You will most likely want to set this property to false
   * if the implementation manipulates with the rows in the model and keep
   * track of seqnums yourself.
   **/
  pspec = g_param_spec_boolean ("inherit-seqnums", "Inherit seqnums",
                                "Whether or not to inherit seqnums",
                                TRUE,
                                G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                                | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_INHERIT_SEQNUMS, pspec);
  
  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeProxyModelPrivate));
}

static void
dee_proxy_model_model_iface_init (DeeModelIface *iface)
{
  iface->set_schema_full       = dee_proxy_model_set_schema_full;
  iface->get_schema            = dee_proxy_model_get_schema;
  iface->get_column_schema     = dee_proxy_model_get_column_schema;
  iface->get_column_index      = dee_proxy_model_get_column_index;
  iface->set_column_names_full = dee_proxy_model_set_column_names;
  iface->get_column_names      = dee_proxy_model_get_column_names;
  iface->get_field_schema      = dee_proxy_model_get_field_schema;
  iface->get_n_columns         = dee_proxy_model_get_n_columns;
  iface->get_n_rows            = dee_proxy_model_get_n_rows;
  iface->clear                 = dee_proxy_model_clear;
  iface->prepend_row           = dee_proxy_model_prepend_row;
  iface->append_row            = dee_proxy_model_append_row;
  iface->insert_row            = dee_proxy_model_insert_row;
  iface->insert_row_before     = dee_proxy_model_insert_row_before;
  iface->insert_row_sorted     = dee_proxy_model_insert_row_sorted;
  iface->find_row_sorted       = dee_proxy_model_find_row_sorted;
  iface->remove                = dee_proxy_model_remove;
  iface->set_value             = dee_proxy_model_set_value;
  iface->set_row               = dee_proxy_model_set_row;
  iface->get_value             = dee_proxy_model_get_value;
  iface->get_first_iter        = dee_proxy_model_get_first_iter;
  iface->get_last_iter         = dee_proxy_model_get_last_iter;
  iface->get_iter_at_row       = dee_proxy_model_get_iter_at_row;
  iface->get_bool              = dee_proxy_model_get_bool;
  iface->get_uchar             = dee_proxy_model_get_uchar;
  iface->get_int32             = dee_proxy_model_get_int32;
  iface->get_uint32            = dee_proxy_model_get_uint32;
  iface->get_int64             = dee_proxy_model_get_int64;
  iface->get_uint64            = dee_proxy_model_get_uint64;
  iface->get_double            = dee_proxy_model_get_double;
  iface->get_string            = dee_proxy_model_get_string;
  iface->next                  = dee_proxy_model_next;
  iface->prev                  = dee_proxy_model_prev;
  iface->is_first              = dee_proxy_model_is_first;
  iface->is_last               = dee_proxy_model_is_last;
  iface->get_position          = dee_proxy_model_get_position;
  iface->register_tag          = dee_proxy_model_register_tag;
  iface->get_tag               = dee_proxy_model_get_tag;
  iface->set_tag               = dee_proxy_model_set_tag;
  iface->begin_changeset       = dee_proxy_model_begin_changeset;
  iface->end_changeset         = dee_proxy_model_end_changeset;

  iface->register_vardict_schema = dee_proxy_model_register_vardict_schema;
  iface->get_vardict_schema      = dee_proxy_model_get_vardict_schema;
}

static void
dee_proxy_model_init (DeeProxyModel *model)
{
  DeeProxyModelPrivate *priv;

  priv = model->priv = DEE_PROXY_MODEL_GET_PRIVATE (model);
  priv->back_end = NULL;
  priv->inherit_seqnums = TRUE;
  
  priv->row_added_handler = 0;
  priv->row_removed_handler = 0;
  priv->row_changed_handler = 0;
  priv->changeset_started_handler = 0;
  priv->changeset_finished_handler = 0;
}

/*
 * DeeModel Interface Implementation
 */
static void
dee_proxy_model_set_schema_full (DeeModel           *self,
                                 const gchar* const *schema,
                                 guint               num_columns)
{
  g_return_if_fail (DEE_IS_PROXY_MODEL (self));

  dee_model_set_schema_full (DEE_PROXY_MODEL_BACK_END (self),
                             schema, num_columns);
}

static const gchar* const*
dee_proxy_model_get_schema (DeeModel *self,
                            guint    *num_columns)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);

  return dee_model_get_schema (DEE_PROXY_MODEL_BACK_END (self), num_columns);
}

static const gchar*
dee_proxy_model_get_column_schema (DeeModel *self,
                                   guint     column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_get_column_schema (DEE_PROXY_MODEL_BACK_END (self), column);
}

static const gchar*
dee_proxy_model_get_field_schema (DeeModel    *self,
                                  const gchar *field_name,
                                  guint       *out_column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_get_field_schema (DEE_PROXY_MODEL_BACK_END (self),
                                     field_name,
                                     out_column);
}

static gint
dee_proxy_model_get_column_index (DeeModel    *self,
                                  const gchar *column_name)
{
  DeeModelIface *iface;

  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), -1);

  iface = DEE_MODEL_GET_IFACE (DEE_PROXY_MODEL_BACK_END (self));

  return (* iface->get_column_index) (DEE_PROXY_MODEL_BACK_END (self),
                                      column_name);
}

static void
dee_proxy_model_set_column_names (DeeModel     *self,
                                  const gchar **column_names,
                                  guint         num_columns)
{
  g_return_if_fail (DEE_IS_PROXY_MODEL (self));

  dee_model_set_column_names_full (DEE_PROXY_MODEL_BACK_END (self),
                                   column_names, num_columns);
}

static const gchar**
dee_proxy_model_get_column_names (DeeModel *self,
                                  guint    *num_columns)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_get_column_names (DEE_PROXY_MODEL_BACK_END (self),
                                     num_columns);
}

static void
dee_proxy_model_register_vardict_schema (DeeModel   *self,
                                         guint       column,
                                         GHashTable *schema)
{
  g_return_if_fail (DEE_IS_PROXY_MODEL (self));

  dee_model_register_vardict_schema (DEE_PROXY_MODEL_BACK_END (self),
                                     column, schema);
}

static GHashTable*
dee_proxy_model_get_vardict_schema (DeeModel   *self,
                                    guint       column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_get_vardict_schema (DEE_PROXY_MODEL_BACK_END (self), column);
}

static guint
dee_proxy_model_get_n_columns (DeeModel *self)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);

  return dee_model_get_n_columns (DEE_PROXY_MODEL_BACK_END (self));
}

static guint
dee_proxy_model_get_n_rows (DeeModel *self)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);

  return dee_model_get_n_rows (DEE_PROXY_MODEL_BACK_END (self));
}

static void
dee_proxy_model_clear (DeeModel *self)
{
  g_return_if_fail (DEE_IS_PROXY_MODEL (self));

  dee_model_clear (DEE_PROXY_MODEL_BACK_END (self));
}

static DeeModelIter*
dee_proxy_model_prepend_row (DeeModel  *self,
                             GVariant **row_members)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_prepend_row (DEE_PROXY_MODEL_BACK_END (self), row_members);
}

static DeeModelIter*
dee_proxy_model_append_row (DeeModel  *self,
                            GVariant **row_members)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_append_row (DEE_PROXY_MODEL_BACK_END (self), row_members);
}

static DeeModelIter*
dee_proxy_model_insert_row (DeeModel  *self,
                            guint      pos,
                            GVariant **row_members)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_insert_row (DEE_PROXY_MODEL_BACK_END (self),
                               pos, row_members);
}

static DeeModelIter*
dee_proxy_model_insert_row_before (DeeModel      *self,
                                   DeeModelIter  *iter,
                                   GVariant     **row_members)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_insert_row_before (DEE_PROXY_MODEL_BACK_END (self),
                                      iter, row_members);
}

static DeeModelIter*
dee_proxy_model_insert_row_sorted (DeeModel           *self,
                                   GVariant          **row_spec,
                                   DeeCompareRowFunc   cmp_func,
                                   gpointer            user_data)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_insert_row_sorted (DEE_PROXY_MODEL_BACK_END (self),
                                      row_spec, cmp_func, user_data);
}

static DeeModelIter*
dee_proxy_model_find_row_sorted (DeeModel           *self,
                                 GVariant          **row_spec,
                                 DeeCompareRowFunc   cmp_func,
                                 gpointer            user_data,
                                 gboolean           *out_was_found)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_find_row_sorted (DEE_PROXY_MODEL_BACK_END (self),
                                    row_spec, cmp_func, user_data,
                                    out_was_found);
}

static void
dee_proxy_model_remove (DeeModel     *self,
                        DeeModelIter *iter)
{
  g_return_if_fail (DEE_IS_PROXY_MODEL (self));

  dee_model_remove (DEE_PROXY_MODEL_BACK_END (self), iter);
}

static void
dee_proxy_model_set_row (DeeModel       *self,
                         DeeModelIter   *iter,
                         GVariant      **row_members)
{
  g_return_if_fail (DEE_IS_PROXY_MODEL (self));

  dee_model_set_row (DEE_PROXY_MODEL_BACK_END (self), iter, row_members);
}

static void
dee_proxy_model_set_value (DeeModel      *self,
                           DeeModelIter  *iter,
                           guint          column,
                           GVariant      *value)
{
  g_return_if_fail (DEE_IS_PROXY_MODEL (self));

  dee_model_set_value (DEE_PROXY_MODEL_BACK_END (self), iter, column, value);
}

static GVariant*
dee_proxy_model_get_value (DeeModel     *self,
                           DeeModelIter *iter,
                           guint         column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_get_value (DEE_PROXY_MODEL_BACK_END (self), iter, column);
}

static gboolean
dee_proxy_model_get_bool (DeeModel      *self,
                          DeeModelIter  *iter,
                          guint          column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), FALSE);

  return dee_model_get_bool (DEE_PROXY_MODEL_BACK_END (self), iter, column);
}

static guchar
dee_proxy_model_get_uchar (DeeModel      *self,
                           DeeModelIter  *iter,
                           guint          column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);

  return dee_model_get_uchar (DEE_PROXY_MODEL_BACK_END (self), iter, column);
}

static gint32
dee_proxy_model_get_int32 (DeeModel        *self,
                           DeeModelIter    *iter,
                           guint            column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);

  return dee_model_get_int32 (DEE_PROXY_MODEL_BACK_END (self), iter, column);
}

static guint32
dee_proxy_model_get_uint32 (DeeModel      *self,
                            DeeModelIter  *iter,
                            guint          column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);

  return dee_model_get_uint32 (DEE_PROXY_MODEL_BACK_END (self), iter, column);
}


static gint64
dee_proxy_model_get_int64 (DeeModel      *self,
                           DeeModelIter  *iter,
                           guint          column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);

  return dee_model_get_int64 (DEE_PROXY_MODEL_BACK_END (self), iter, column);
}


static guint64
dee_proxy_model_get_uint64 (DeeModel      *self,
                            DeeModelIter  *iter,
                            guint          column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);

  return dee_model_get_uint64 (DEE_PROXY_MODEL_BACK_END (self), iter, column);
}

static gdouble
dee_proxy_model_get_double (DeeModel      *self,
                            DeeModelIter  *iter,
                            guint          column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);

  return dee_model_get_double (DEE_PROXY_MODEL_BACK_END (self), iter, column);
}

static const gchar*
dee_proxy_model_get_string (DeeModel      *self,
                            DeeModelIter  *iter,
                            guint          column)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_get_string (DEE_PROXY_MODEL_BACK_END (self), iter, column);
}

static DeeModelIter*
dee_proxy_model_get_first_iter (DeeModel     *self)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_get_first_iter (DEE_PROXY_MODEL_BACK_END (self));
}

static DeeModelIter*
dee_proxy_model_get_last_iter (DeeModel *self)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_get_last_iter (DEE_PROXY_MODEL_BACK_END (self));
}

static DeeModelIter*
dee_proxy_model_get_iter_at_row (DeeModel *self, guint row)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_get_iter_at_row (DEE_PROXY_MODEL_BACK_END (self), row);
}

static DeeModelIter*
dee_proxy_model_next (DeeModel     *self,
                      DeeModelIter *iter)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_next (DEE_PROXY_MODEL_BACK_END (self), iter);
}

static DeeModelIter*
dee_proxy_model_prev (DeeModel     *self,
                      DeeModelIter *iter)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_prev (DEE_PROXY_MODEL_BACK_END (self), iter);
}

static gboolean
dee_proxy_model_is_first (DeeModel     *self,
                          DeeModelIter *iter)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), FALSE);

  return dee_model_is_first (DEE_PROXY_MODEL_BACK_END (self), iter);
}

static gboolean
dee_proxy_model_is_last (DeeModel     *self,
                         DeeModelIter *iter)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), FALSE);

  return dee_model_is_last (DEE_PROXY_MODEL_BACK_END (self), iter);
}

static guint
dee_proxy_model_get_position (DeeModel     *self,
                              DeeModelIter *iter)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);

  return dee_model_get_position (DEE_PROXY_MODEL_BACK_END (self), iter);
}

static DeeModelTag*
dee_proxy_model_register_tag    (DeeModel       *self,
                                 GDestroyNotify  tag_destroy)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_register_tag (DEE_PROXY_MODEL_BACK_END (self), tag_destroy);
}

static gpointer
dee_proxy_model_get_tag (DeeModel       *self,
                         DeeModelIter   *iter,
                         DeeModelTag    *tag)
{
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), NULL);

  return dee_model_get_tag (DEE_PROXY_MODEL_BACK_END (self), iter, tag);
}

static void
dee_proxy_model_set_tag (DeeModel       *self,
                         DeeModelIter   *iter,
                         DeeModelTag    *tag,
                         gpointer        value)
{
  g_return_if_fail (DEE_IS_PROXY_MODEL (self));

  return dee_model_set_tag (DEE_PROXY_MODEL_BACK_END (self), iter, tag, value);
}

static void
dee_proxy_model_begin_changeset (DeeModel *self)
{
  g_return_if_fail (DEE_IS_PROXY_MODEL (self));

  dee_model_begin_changeset (DEE_PROXY_MODEL_BACK_END (self));
}

static void
dee_proxy_model_end_changeset (DeeModel *self)
{
  g_return_if_fail (DEE_IS_PROXY_MODEL (self));

  dee_model_end_changeset (DEE_PROXY_MODEL_BACK_END (self));
}

/*
 * Relay signals from back end
 */

static void
on_back_end_row_added (DeeProxyModel *self,
                       DeeModelIter  *iter)
{
  g_signal_emit_by_name (self, "row-added", iter);
}

static void
on_back_end_row_removed (DeeProxyModel *self,
                         DeeModelIter  *iter)
{
  g_signal_emit_by_name (self, "row-removed", iter);
}

static void
on_back_end_row_changed (DeeProxyModel *self,
                         DeeModelIter  *iter)
{
  g_signal_emit_by_name (self, "row-changed", iter);
}

static void
on_back_end_changeset_started (DeeProxyModel *self,
                               DeeModel *model)
{
  g_signal_emit_by_name (self, "changeset-started");
}

static void
on_back_end_changeset_finished (DeeProxyModel *self,
                                DeeModel *model)
{
  g_signal_emit_by_name (self, "changeset-finished");
}

/*
 * Overrides for DeeSerializableModel
 */
static guint64
dee_proxy_model_get_seqnum (DeeModel     *self)
{
  DeeProxyModelPrivate *priv;
  
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);
  
  priv = DEE_PROXY_MODEL (self)->priv;

  if (priv->inherit_seqnums)
    return dee_serializable_model_get_seqnum (priv->back_end);
  else
    return SUPER_CLASS->get_seqnum (self);
}

static void
dee_proxy_model_set_seqnum  (DeeModel     *self,
                             guint64       seqnum)
{
  DeeProxyModelPrivate *priv;
  
  g_return_if_fail (DEE_IS_PROXY_MODEL (self));
  
  priv = DEE_PROXY_MODEL (self)->priv;

  if (priv->inherit_seqnums)
    dee_serializable_model_set_seqnum (priv->back_end, seqnum);
  else
    return SUPER_CLASS->set_seqnum (self, seqnum);
}

static guint64
dee_proxy_model_inc_seqnum (DeeModel     *self)
{
  DeeProxyModelPrivate *priv;
  
  g_return_val_if_fail (DEE_IS_PROXY_MODEL (self), 0);
  
  priv = DEE_PROXY_MODEL (self)->priv;

  if (priv->inherit_seqnums)
    return dee_serializable_model_inc_seqnum (priv->back_end);
  else
    return SUPER_CLASS->inc_seqnum (self);
}
