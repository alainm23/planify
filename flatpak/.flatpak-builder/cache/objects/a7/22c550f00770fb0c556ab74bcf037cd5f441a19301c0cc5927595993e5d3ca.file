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

#ifndef _HAVE_DEE_HASH_INDEX_H
#define _HAVE_DEE_HASH_INDEX_H

#include <glib.h>
#include <glib-object.h>
#include <dee-model.h>
#include <dee-index.h>
#include <dee-term-list.h>

G_BEGIN_DECLS

#define DEE_TYPE_HASH_INDEX (dee_hash_index_get_type ())

#define DEE_HASH_INDEX(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_HASH_INDEX, DeeHashIndex))

#define DEE_HASH_INDEX_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_HASH_INDEX, DeeHashIndexClass))

#define DEE_IS_HASH_INDEX(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_HASH_INDEX))

#define DEE_IS_HASH_INDEX_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_HASH_INDEX))

#define DEE_HASH_INDEX_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DBUS_TYPE_HASH_INDEX, DeeHashIndexClass))

typedef struct _DeeHashIndexClass DeeHashIndexClass;
typedef struct _DeeHashIndex DeeHashIndex;
typedef struct _DeeHashIndexPrivate DeeHashIndexPrivate;

/**
 * DeeHashIndex:
 *
 * All fields in the DeeHashIndex structure are private and should never be
 * accessed directly
 */
struct _DeeHashIndex
{
  /*< private >*/
  DeeIndex          parent;

  DeeHashIndexPrivate *priv;
};

struct _DeeHashIndexClass
{
  DeeIndexClass     parent_class;
};

GType                dee_hash_index_get_type          (void);

DeeHashIndex*        dee_hash_index_new               (DeeModel       *model,
                                                       DeeAnalyzer    *analyzer,
                                                       DeeModelReader *reader);

G_END_DECLS

#endif /* _HAVE_DEE_HASH_INDEX_H */
