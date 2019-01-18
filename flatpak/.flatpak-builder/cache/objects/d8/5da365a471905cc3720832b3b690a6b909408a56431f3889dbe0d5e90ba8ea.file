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

#ifndef _DEE_RESULT_SET_H_
#define _DEE_RESULT_SET_H_

#include <glib.h>
#include <glib-object.h>
#include <dee-model.h>

G_BEGIN_DECLS

#define DEE_TYPE_RESULT_SET (dee_result_set_get_type ())

#define DEE_RESULT_SET(obj) \
        (G_TYPE_CHECK_INSTANCE_CAST ((obj), DEE_TYPE_RESULT_SET, DeeResultSet))

#define DEE_IS_RESULT_SET(obj) \
       (G_TYPE_CHECK_INSTANCE_TYPE ((obj), DEE_TYPE_RESULT_SET))

#define DEE_RESULT_SET_GET_IFACE(obj) \
       (G_TYPE_INSTANCE_GET_INTERFACE(obj, dee_result_set_get_type (), DeeResultSetIface))

typedef struct _DeeResultSetIface DeeResultSetIface;
typedef struct _DeeResultSet DeeResultSet;


struct _DeeResultSetIface
{
  GTypeInterface g_iface;

  /*< public >*/
  guint           (*get_n_rows)        (DeeResultSet *self);

  DeeModelIter*   (*next)              (DeeResultSet *self);

  gboolean        (*has_next)          (DeeResultSet *self);
  
  DeeModelIter*   (*peek)              (DeeResultSet *self);

  void            (*seek)              (DeeResultSet *self,
                                        guint         pos);

  guint           (*tell)              (DeeResultSet *self);

  DeeModel*       (*get_model)         (DeeResultSet *self);

  /*< private >*/
  void     (*_dee_result_set_1) (void);
  void     (*_dee_result_set_2) (void);
  void     (*_dee_result_set_3) (void);
  void     (*_dee_result_set_4) (void);
  void     (*_dee_result_set_5) (void);
};

GType           dee_result_set_get_type          (void);

guint           dee_result_set_get_n_rows        (DeeResultSet *self);

DeeModelIter*   dee_result_set_next              (DeeResultSet *self);

gboolean        dee_result_set_has_next          (DeeResultSet *self);

DeeModelIter*   dee_result_set_peek              (DeeResultSet *self);

void            dee_result_set_seek              (DeeResultSet *self,
                                                  guint         pos);

guint           dee_result_set_tell              (DeeResultSet *self);

DeeModel*       dee_result_set_get_model         (DeeResultSet *self);

#define _vala_dee_result_set_next_value(rs) (dee_result_set_has_next(rs) ? dee_result_set_next(rs) : NULL)
#define _vala_dee_result_set_iterator(rs) ((DeeResultSet*)g_object_ref(rs))

G_END_DECLS

#endif /* _HAVE_DEE_RESULT_SET_H */
