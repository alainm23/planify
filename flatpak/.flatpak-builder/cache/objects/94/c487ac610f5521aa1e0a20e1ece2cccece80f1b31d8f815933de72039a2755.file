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

#ifndef FOLKS_SMALL_SET_INTERNAL_H
#define FOLKS_SMALL_SET_INTERNAL_H

#include <folks/small-set.h>

G_BEGIN_DECLS

typedef struct _FolksSmallSetIterator FolksSmallSetIterator;
typedef struct _FolksSmallSetIteratorClass FolksSmallSetIteratorClass;

GType folks_small_set_iterator_get_type (void);

#define FOLKS_TYPE_SMALL_SET_ITERATOR \
  (folks_small_set_iterator_get_type ())
#define FOLKS_SMALL_SET_ITERATOR(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), FOLKS_TYPE_SMALL_SET_ITERATOR, \
                               FolksSmallSetIterator))
#define FOLKS_SMALL_SET_ITERATOR_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), FOLKS_TYPE_SMALL_SET_ITERATOR, \
                            FolksSmallSetIteratorClass))
#define FOLKS_IS_SMALL_SET_ITERATOR(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), FOLKS_TYPE_SMALL_SET_ITERATOR))
#define FOLKS_IS_SMALL_SET_ITERATOR_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), FOLKS_TYPE_SMALL_SET_ITERATOR))
#define FOLKS_SMALL_SET_ITERATOR_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), FOLKS_TYPE_SMALL_SET_ITERATOR, \
                              FolksSmallSetIteratorClass))

typedef enum {
    FOLKS_SMALL_SET_FLAG_READ_ONLY = (1 << 0),
} FolksSmallSetFlags;

/* This is in the (internal) header to allow inlining. */
struct _FolksSmallSet {
    /*<private>*/
    GeeAbstractSet parent_instance;

    GPtrArray *items;
    GType item_type;
    GBoxedCopyFunc item_dup;
    GDestroyNotify item_free;
    GeeHashDataFunc item_hash;
    gpointer item_hash_data;
    GDestroyNotify item_hash_data_free;
    GeeEqualDataFunc item_equals;
    gpointer item_equals_data;
    GDestroyNotify item_equals_data_free;

    FolksSmallSetFlags flags;
    FolksSmallSet *rw_version;
};

/* Syntactic sugar for iteration. The type must match the type
 * of the size property, which is signed, because Vala. */
static inline gconstpointer
folks_small_set_get (FolksSmallSet *self,
    gint i)
{
  g_return_val_if_fail (self != NULL, NULL);
  g_return_val_if_fail (i >= 0, NULL);
  g_return_val_if_fail ((guint) i < self->items->len, NULL);

  return g_ptr_array_index (self->items, i);
}

FolksSmallSet *
_folks_small_set_new_take_array (GPtrArray *arr,
    GType item_type,
    GBoxedCopyFunc item_dup,
    GDestroyNotify item_free);

G_END_DECLS

#endif
