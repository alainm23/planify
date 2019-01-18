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
 * Authored by Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

#if !defined (_DEE_H_INSIDE) && !defined (DEE_COMPILATION)
#error "Only <dee.h> can be included directly."
#endif

#ifndef _HAVE_DEE_TREE_INDEX_H
#define _HAVE_DEE_TREE_INDEX_H

#include <glib.h>
#include <glib-object.h>
#include <dee-model.h>
#include <dee-index.h>
#include <dee-analyzer.h>

G_BEGIN_DECLS

#define DEE_TYPE_TREE_INDEX (dee_tree_index_get_type ())

#define DEE_TREE_INDEX(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_TREE_INDEX, DeeTreeIndex))

#define DEE_TREE_INDEX_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_TREE_INDEX, DeeTreeIndexClass))

#define DEE_IS_TREE_INDEX(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_TREE_INDEX))

#define DEE_IS_TREE_INDEX_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_TREE_INDEX))

#define DEE_TREE_INDEX_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DBUS_TYPE_TREE_INDEX, DeeTreeIndexClass))

typedef struct _DeeTreeIndexClass DeeTreeIndexClass;
typedef struct _DeeTreeIndex DeeTreeIndex;
typedef struct _DeeTreeIndexPrivate DeeTreeIndexPrivate;

/**
 * DeeTreeIndex:
 *
 * All fields in the DeeTreeIndex structure are private and should never be
 * accessed directly
 */
struct _DeeTreeIndex
{
  /*< private >*/
  DeeIndex          parent;

  DeeTreeIndexPrivate *priv;
};

struct _DeeTreeIndexClass
{
  DeeIndexClass     parent_class;
};

GType                dee_tree_index_get_type          (void);

DeeTreeIndex*        dee_tree_index_new               (DeeModel       *model,
                                                       DeeAnalyzer    *analyzer,
                                                       DeeModelReader *reader);

G_END_DECLS

#endif /* _HAVE_DEE_TREE_INDEX_H */
