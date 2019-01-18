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

#ifndef _DEE_SERIALIZABLE_H_
#define _DEE_SERIALIZABLE_H_

#include <glib.h>
#include <glib-object.h>
#include <dee-model.h>

G_BEGIN_DECLS

#define DEE_TYPE_SERIALIZABLE (dee_serializable_get_type ())

#define DEE_SERIALIZABLE(obj) \
        (G_TYPE_CHECK_INSTANCE_CAST ((obj), DEE_TYPE_SERIALIZABLE, DeeSerializable))

#define DEE_IS_SERIALIZABLE(obj) \
       (G_TYPE_CHECK_INSTANCE_TYPE ((obj), DEE_TYPE_SERIALIZABLE))

#define DEE_SERIALIZABLE_GET_IFACE(obj) \
       (G_TYPE_INSTANCE_GET_INTERFACE(obj, dee_serializable_get_type (), DeeSerializableIface))

typedef struct _DeeSerializableIface DeeSerializableIface;
typedef struct _DeeSerializable DeeSerializable;

/**
 * DeeSerializableParseFunc:
 * @data: A #GVariant with type signature as passed to
 *        dee_serializable_register_parser() when the parser was registered.
 *        The variant is not referenced.
 *
 * Return value: (transfer full): A newly constructed #GObject of the #GType
 *               used when registering the parser. Note that since
 *               the environment guarantees that the input data is valid
 *               according to the registration information this function
 *               can not fail. Thus %NULL is not a valid return value.
 */
typedef GObject* (*DeeSerializableParseFunc) (GVariant *data);

struct _DeeSerializableIface
{
  GTypeInterface g_iface;

  /*< public >*/
  GVariant*       (*serialize)         (DeeSerializable *self);

  /*< private >*/
  void     (*_dee_serializable_1) (void);
  void     (*_dee_serializable_2) (void);
  void     (*_dee_serializable_3) (void);
  void     (*_dee_serializable_4) (void);
  void     (*_dee_serializable_5) (void);
};

GType           dee_serializable_get_type          (void);

void            dee_serializable_register_parser   (GType                     type,
                                                    const GVariantType       *vtype,
                                                    DeeSerializableParseFunc  parse_func);

GObject*        dee_serializable_parse             (GVariant        *data,
                                                    GType            type);

GObject*        dee_serializable_parse_external    (GVariant        *data);

GVariant*       dee_serializable_externalize       (DeeSerializable *self);

GVariant*       dee_serializable_serialize         (DeeSerializable *self);

G_END_DECLS

#endif /* _HAVE_DEE_SERIALIZABLE_H */
