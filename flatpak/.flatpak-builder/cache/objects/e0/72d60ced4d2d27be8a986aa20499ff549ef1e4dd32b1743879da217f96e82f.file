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
 * Authored by Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

#if !defined (_DEE_H_INSIDE) && !defined (DEE_COMPILATION)
#error "Only <dee.h> can be included directly."
#endif

#ifndef _HAVE_DEE_SERIALIZABLE_MODEL_H
#define _HAVE_DEE_SERIALIZABLE_MODEL_H

#include <glib.h>
#include <glib-object.h>

#include <dee-model.h>

G_BEGIN_DECLS

#define DEE_TYPE_SERIALIZABLE_MODEL (dee_serializable_model_get_type ())

#define DEE_SERIALIZABLE_MODEL(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_SERIALIZABLE_MODEL, DeeSerializableModel))

#define DEE_SERIALIZABLE_MODEL_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_SERIALIZABLE_MODEL, DeeSerializableModelClass))

#define DEE_IS_SERIALIZABLE_MODEL(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_SERIALIZABLE_MODEL))

#define DEE_IS_SERIALIZABLE_MODEL_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_SERIALIZABLE_MODEL))

#define DEE_SERIALIZABLE_MODEL_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DBUS_TYPE_ABSTRACT_MODEL, DeeSerializableModelClass))

typedef struct _DeeSerializableModel DeeSerializableModel;
typedef struct _DeeSerializableModelClass DeeSerializableModelClass;
typedef struct _DeeSerializableModelPrivate DeeSerializableModelPrivate;

/**
 * DeeSerializableModel:
 *
 * All fields in the DeeSerializableModel structure are private and should never be
 * accessed directly
 */
struct _DeeSerializableModel
{
  /*< private >*/
  GObject          parent;

  DeeSerializableModelPrivate *priv;
};

struct _DeeSerializableModelClass
{
  /*< private >*/
  GObjectClass parent_class;

  /*< vatable >*/
  guint64          (* get_seqnum)      (DeeModel     *self);
  void             (* set_seqnum)      (DeeModel     *self,
                                        guint64       seqnum);
  guint64          (* inc_seqnum)      (DeeModel     *self);
                                             
  /*< private >*/
  void     (*_dee_serializable_model_1) (void);
  void     (*_dee_serializable_model_2) (void);
  void     (*_dee_serializable_model_3) (void);
  void     (*_dee_serializable_model_4) (void);
};

/**
 * dee_serializable_model_get_type:
 *
 * The GType of #DeeSerializableModel
 *
 * Return value: the #GType of #DeeSerializableModel
 **/
GType          dee_serializable_model_get_type          (void);

guint64        dee_serializable_model_get_seqnum        (DeeModel     *self);

void           dee_serializable_model_set_seqnum        (DeeModel     *self,
                                                         guint64       seqnum);

guint64        dee_serializable_model_inc_seqnum        (DeeModel     *self);

G_END_DECLS

#endif /* _HAVE_DEE_SERIALIZABLE_MODEL_H */
