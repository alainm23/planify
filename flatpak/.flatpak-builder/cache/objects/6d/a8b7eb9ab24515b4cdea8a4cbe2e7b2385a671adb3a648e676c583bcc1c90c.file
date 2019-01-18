/* tp-intset.h - Headers for a Glib-link set of integers
 *
 * Copyright © 2005-2010 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright © 2005-2006 Nokia Corporation
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301 USA
 *
 */

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_INTSET_H__
#define __TP_INTSET_H__

#include <glib-object.h>

#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

#define TP_TYPE_INTSET (tp_intset_get_type ())
GType tp_intset_get_type (void);

typedef struct _TpIntset TpIntset;

#ifndef TP_DISABLE_DEPRECATED
/* See fdo#30134 for the reasoning behind the rename of TpIntSet to TpIntset */

/**
 * TpIntSet: (skip)
 *
 * Before 0.11.16, this was the name for <type>TpIntset</type>, but it's
 * now just a backwards compatibility typedef.
 */
typedef TpIntset TpIntSet;
#endif

typedef void (*TpIntFunc) (guint i, gpointer userdata);

TpIntset *tp_intset_new (void) G_GNUC_WARN_UNUSED_RESULT;
TpIntset *tp_intset_sized_new (guint size) G_GNUC_WARN_UNUSED_RESULT;
TpIntset *tp_intset_new_containing (guint element) G_GNUC_WARN_UNUSED_RESULT;
void tp_intset_destroy (TpIntset *set);
void tp_intset_clear (TpIntset *set);

void tp_intset_add (TpIntset *set, guint element);
gboolean tp_intset_remove (TpIntset *set, guint element);
gboolean tp_intset_is_member (const TpIntset *set, guint element)
  G_GNUC_WARN_UNUSED_RESULT;

void tp_intset_foreach (const TpIntset *set, TpIntFunc func,
    gpointer userdata);
GArray *tp_intset_to_array (const TpIntset *set) G_GNUC_WARN_UNUSED_RESULT;
TpIntset *tp_intset_from_array (const GArray *array) G_GNUC_WARN_UNUSED_RESULT;

gboolean tp_intset_is_empty (const TpIntset *set) G_GNUC_WARN_UNUSED_RESULT;
guint tp_intset_size (const TpIntset *set) G_GNUC_WARN_UNUSED_RESULT;

gboolean tp_intset_is_equal (const TpIntset *left, const TpIntset *right)
  G_GNUC_WARN_UNUSED_RESULT;

TpIntset *tp_intset_copy (const TpIntset *orig) G_GNUC_WARN_UNUSED_RESULT;
TpIntset *tp_intset_intersection (const TpIntset *left, const TpIntset *right)
  G_GNUC_WARN_UNUSED_RESULT;
TpIntset *tp_intset_union (const TpIntset *left, const TpIntset *right)
  G_GNUC_WARN_UNUSED_RESULT;
TpIntset *tp_intset_difference (const TpIntset *left, const TpIntset *right)
  G_GNUC_WARN_UNUSED_RESULT;
TpIntset *tp_intset_symmetric_difference (const TpIntset *left,
    const TpIntset *right) G_GNUC_WARN_UNUSED_RESULT;

gchar *tp_intset_dump (const TpIntset *set) G_GNUC_WARN_UNUSED_RESULT;

#ifndef TP_DISABLE_DEPRECATED
typedef struct {
    const TpIntset *set;
    guint element;
} TpIntsetIter;

typedef TpIntsetIter TpIntSetIter;

#define TP_INTSET_ITER_INIT(set) { (set), (guint)(-1) }

_TP_DEPRECATED_IN_0_20_FOR (tp_intset_fast_iter_init)
void tp_intset_iter_init (TpIntsetIter *iter, const TpIntset *set);

_TP_DEPRECATED_IN_0_20_FOR (tp_intset_fast_iter_init)
void tp_intset_iter_reset (TpIntsetIter *iter);

_TP_DEPRECATED_IN_0_20_FOR (tp_intset_fast_iter_next)
gboolean tp_intset_iter_next (TpIntsetIter *iter);
#endif

typedef struct {
    /*<private>*/
    gpointer _dummy[16];
} TpIntsetFastIter;

#ifndef TP_DISABLE_DEPRECATED
typedef TpIntsetFastIter TpIntSetFastIter;
#endif

void tp_intset_fast_iter_init (TpIntsetFastIter *iter,
    const TpIntset *set);

gboolean tp_intset_fast_iter_next (TpIntsetFastIter *iter,
    guint *output);

void tp_intset_union_update (TpIntset *self, const TpIntset *other);
void tp_intset_difference_update (TpIntset *self, const TpIntset *other);

G_END_DECLS

#endif /*__TP_INTSET_H__*/
