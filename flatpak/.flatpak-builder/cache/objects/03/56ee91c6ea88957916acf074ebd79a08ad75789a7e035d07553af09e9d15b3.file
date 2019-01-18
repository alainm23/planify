/*
 * small-set - a set optimized for fast iteration when there are few items
 *
 * Copyright © 2013 Intel Corporation
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 *
 * Authors:
 *      Simon McVittie <simon.mcvittie@collabora.co.uk>
 */

#ifndef FOLKS_SMALL_SET_H
#define FOLKS_SMALL_SET_H

#include <glib.h>
#include <glib-object.h>
#include <gee.h>

G_BEGIN_DECLS

typedef struct _FolksSmallSet FolksSmallSet;
typedef struct _FolksSmallSetClass FolksSmallSetClass;

GType folks_small_set_get_type (void);

#define FOLKS_TYPE_SMALL_SET \
  (folks_small_set_get_type ())
#define FOLKS_SMALL_SET(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), FOLKS_TYPE_SMALL_SET, \
                               FolksSmallSet))
#define FOLKS_SMALL_SET_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), FOLKS_TYPE_SMALL_SET, \
                            FolksSmallSetClass))
#define FOLKS_IS_SMALL_SET(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), FOLKS_TYPE_SMALL_SET))
#define FOLKS_IS_SMALL_SET_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), FOLKS_TYPE_SMALL_SET))
#define FOLKS_SMALL_SET_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), FOLKS_TYPE_SMALL_SET, \
                              FolksSmallSetClass))

FolksSmallSet *
folks_small_set_new (GType item_type,
    GBoxedCopyFunc item_dup,
    GDestroyNotify item_free,
    GeeHashDataFunc item_hash,
    gpointer item_hash_data,
    GDestroyNotify item_hash_data_free,
    GeeEqualDataFunc item_equals,
    gpointer item_equals_data,
    GDestroyNotify item_equals_data_free);

FolksSmallSet *
folks_small_set_empty (GType item_type,
    GBoxedCopyFunc item_dup,
    GDestroyNotify item_free);

FolksSmallSet *folks_small_set_copy (GeeIterable *iterable,
    GeeHashDataFunc item_hash,
    gpointer item_hash_data,
    GDestroyNotify item_hash_data_free,
    GeeEqualDataFunc item_equals,
    gpointer item_equals_data,
    GDestroyNotify item_equals_data_free);

G_END_DECLS

#endif
