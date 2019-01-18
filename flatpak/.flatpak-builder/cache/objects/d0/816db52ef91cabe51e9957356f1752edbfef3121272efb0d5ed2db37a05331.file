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
 * Authored by:
 *               Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

/**
 * SECTION:dee-glist-result-set
 * @short_description: Internal API do not use
 *
 * GList implementation of a #DeeResultSet on top of a #GList
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "dee-glist-result-set.h"

static void dee_glist_result_set_result_set_iface_init (DeeResultSetIface *iface);
G_DEFINE_TYPE_WITH_CODE (DeeGListResultSet,
                         dee_glist_result_set,
                         G_TYPE_OBJECT,
                         G_IMPLEMENT_INTERFACE (DEE_TYPE_RESULT_SET,
                                                dee_glist_result_set_result_set_iface_init))

#define DEE_GLIST_RESULT_SET_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_GLIST_RESULT_SET, DeeGListResultSetPrivate))

typedef struct
{
  GList    *rows;
  DeeModel *model;
  GList    *cursor;
  GObject  *row_owner;
  guint     pos;
  guint     n_rows;
  gboolean  n_rows_calculated;
} DeeGListResultSetPrivate;

/* GObject Init */
static void
dee_glist_result_set_finalize (GObject *object)
{
  DeeGListResultSetPrivate *priv;
  
  priv = DEE_GLIST_RESULT_SET_GET_PRIVATE (object);
  
  if (priv->model)
    g_object_unref (priv->model);
  if (priv->row_owner)
    g_object_unref (priv->row_owner);

  G_OBJECT_CLASS (dee_glist_result_set_parent_class)->finalize (object);
}

static void
dee_glist_result_set_class_init (DeeGListResultSetClass *klass)
{
  GObjectClass  *obj_class = G_OBJECT_CLASS (klass);

  obj_class->finalize     = dee_glist_result_set_finalize;

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeGListResultSetPrivate));
}

static void
dee_glist_result_set_init (DeeGListResultSet *self)
{
  DeeGListResultSetPrivate *priv;

  priv = DEE_GLIST_RESULT_SET_GET_PRIVATE (self);
  priv->pos = 0;
  priv->n_rows_calculated = FALSE;
}

static guint
dee_glist_result_set_get_n_rows (DeeResultSet *self)
{
  DeeGListResultSetPrivate *priv;
  
  g_return_val_if_fail (DEE_IS_GLIST_RESULT_SET (self), 0);
  
  priv = DEE_GLIST_RESULT_SET_GET_PRIVATE (self);
  
  if (!priv->n_rows_calculated)
    {
      priv->n_rows_calculated = TRUE;
      priv->n_rows = g_list_length (priv->rows);
    }
  
  return priv->n_rows;
}

static DeeModelIter*
dee_glist_result_set_next (DeeResultSet *self)
{
  DeeGListResultSetPrivate *priv;
  DeeModelIter *next;
  
  g_return_val_if_fail (DEE_IS_GLIST_RESULT_SET (self), NULL);
  g_return_val_if_fail (dee_result_set_has_next (self), NULL);
  
  priv = DEE_GLIST_RESULT_SET_GET_PRIVATE (self);
  next = dee_result_set_peek (self);
  priv->cursor = priv->cursor->next;
  priv->pos++;
  return next;
}

static gboolean
dee_glist_result_set_has_next (DeeResultSet *self)
{
  DeeGListResultSetPrivate *priv;
  
  g_return_val_if_fail (DEE_IS_GLIST_RESULT_SET (self), FALSE);
  
  priv = DEE_GLIST_RESULT_SET_GET_PRIVATE (self);

  return priv->cursor != NULL;
}

static DeeModelIter*
dee_glist_result_set_peek (DeeResultSet *self)
{
  DeeGListResultSetPrivate *priv;
  
  g_return_val_if_fail (DEE_IS_GLIST_RESULT_SET (self), NULL);
  
  priv = DEE_GLIST_RESULT_SET_GET_PRIVATE (self);

  if (priv->cursor == NULL)
    return NULL;
  
  return (DeeModelIter*) (priv->cursor->data);
}

static void
dee_glist_result_set_seek (DeeResultSet *self,
                           guint         pos)
{
  DeeGListResultSetPrivate *priv;
  
  g_return_if_fail (DEE_IS_GLIST_RESULT_SET (self));
  
  priv = DEE_GLIST_RESULT_SET_GET_PRIVATE (self);
  priv->cursor = g_list_nth (priv->rows, pos);
  priv->pos = pos;

  if (priv->cursor == NULL && pos != 0)
    {
      g_warning ("Illegal seek in DeeGListResultSet. Seeking 0");
      priv->cursor = priv->rows;
      priv->pos = 0;
    }
}

static guint
dee_glist_result_set_tell (DeeResultSet *self)
{
  DeeGListResultSetPrivate *priv;
  
  g_return_val_if_fail (DEE_IS_GLIST_RESULT_SET (self), 0);
  
  priv = DEE_GLIST_RESULT_SET_GET_PRIVATE (self);
  return priv->pos;
}

static DeeModel*
dee_glist_result_set_get_model (DeeResultSet *self)
{
  DeeGListResultSetPrivate *priv;

  g_return_val_if_fail (DEE_IS_GLIST_RESULT_SET (self), NULL);

  priv = DEE_GLIST_RESULT_SET_GET_PRIVATE (self);
  return priv->model;
}

static void
dee_glist_result_set_result_set_iface_init (DeeResultSetIface *iface)
{
  iface->get_n_rows        = dee_glist_result_set_get_n_rows;
  iface->next              = dee_glist_result_set_next;
  iface->has_next          = dee_glist_result_set_has_next;
  iface->peek              = dee_glist_result_set_peek;
  iface->seek              = dee_glist_result_set_seek;
  iface->tell              = dee_glist_result_set_tell;
  iface->get_model         = dee_glist_result_set_get_model;
}

/* Internal constructor. Takes a ref on @model, @rows are implicitly reffed
 * by reffing @row_owner. Row owner may be NULL, in which case we cross fingers
 * and trust the caller that @rows are not freed */
DeeResultSet*
dee_glist_result_set_new (GList    *rows,
                          DeeModel *model,
                          GObject  *row_owner)
{
  GObject                  *self;
  DeeGListResultSetPrivate *priv;

  self = g_object_new (DEE_TYPE_GLIST_RESULT_SET, NULL);
  priv = DEE_GLIST_RESULT_SET_GET_PRIVATE (self);
  priv->rows = rows;
  priv->cursor = rows;
  priv->model = g_object_ref (model);
  
  if (row_owner != NULL)
    priv->row_owner = g_object_ref (row_owner);

  return (DeeResultSet*)self;
}

