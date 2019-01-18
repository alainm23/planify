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

#ifndef _DEE_GLIST_RESULT_SET_H_
#define _DEE_GLIST_RESULT_SET_H_

#include <glib.h>
#include <glib-object.h>
#include <dee-model.h>
#include <dee-result-set.h>

G_BEGIN_DECLS

#define DEE_TYPE_GLIST_RESULT_SET (dee_glist_result_set_get_type ())

#define DEE_GLIST_RESULT_SET(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_GLIST_RESULT_SET, DeeGListResultSet))
        
#define DEE_GLIST_RESULT_SET_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_GLIST_RESULT_SET, DeeGListResultSetClass))
        
#define DEE_IS_GLIST_RESULT_SET(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_GLIST_RESULT_SET))
        
#define DEE_IS_GLIST_RESULT_SET_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_GLIST_RESULT_SET))
        
#define DEE_GLIST_RESULT_SET_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DEE_TYPE_GLIST_RESULT_SET, DeeGListResultSetClass))

typedef struct _DeeGListResultSet DeeGListResultSet;
typedef struct _DeeGListResultSetClass DeeGListResultSetClass;

struct _DeeGListResultSet
{
  GObject  parent_instance;
};

struct _DeeGListResultSetClass
{
  GObjectClass  parent_class;
};

GType         dee_glist_result_set_get_type (void);

DeeResultSet* dee_glist_result_set_new (GList    *rows,
                                        DeeModel *model,
                                        GObject  *row_owner);

G_END_DECLS

#endif /* _DEE_GLIST_RESULT_SET_H_ */
