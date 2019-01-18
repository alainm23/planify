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

#ifndef _HAVE_DEE_PROXY_MODEL_H
#define _HAVE_DEE_PROXY_MODEL_H

#include <glib.h>
#include <glib-object.h>

#include <dee-model.h>
#include <dee-serializable-model.h>

G_BEGIN_DECLS

#define DEE_TYPE_PROXY_MODEL (dee_proxy_model_get_type ())

#define DEE_PROXY_MODEL(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_PROXY_MODEL, DeeProxyModel))

#define DEE_PROXY_MODEL_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_PROXY_MODEL, DeeProxyModelClass))

#define DEE_IS_PROXY_MODEL(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_PROXY_MODEL))

#define DEE_IS_PROXY_MODEL_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_PROXY_MODEL))

#define DEE_PROXY_MODEL_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DBUS_TYPE_SEQUENCE_MODEL, DeeProxyModelClass))

typedef struct _DeeProxyModel DeeProxyModel;
typedef struct _DeeProxyModelClass DeeProxyModelClass;
typedef struct _DeeProxyModelPrivate DeeProxyModelPrivate;

/**
 * DeeProxyModel:
 *
 * All fields in the DeeProxyModel structure are private and should never be
 * accessed directly
 */
struct _DeeProxyModel
{
  /*< private >*/
  DeeSerializableModel     parent;

  DeeProxyModelPrivate *priv;
};

struct _DeeProxyModelClass
{
  /*< private >*/
  DeeSerializableModelClass parent_class;
                                             
  /*< private >*/
  void     (*_dee_proxy_model_1) (void);
  void     (*_dee_proxy_model_2) (void);
  void     (*_dee_proxy_model_3) (void);
  void     (*_dee_proxy_model_4) (void);
};

/**
 * dee_proxy_model_get_type:
 *
 * The GType of #DeeProxyModel
 *
 * Return value: the #GType of #DeeProxyModel
 **/
GType          dee_proxy_model_get_type               (void);

G_END_DECLS

#endif /* _HAVE_DEE_PROXY_MODEL_H */
