/*
 * Header file for TpHeap - a heap queue
 *
 * Copyright (C) 2006 Nokia Corporation. All rights reserved.
 *
 * Contact: Olli Salli (Nokia-M/Helsinki) <olli.salli@nokia.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_HEAP_H__
#define __TP_HEAP_H__

#include <glib.h>

G_BEGIN_DECLS

typedef struct _TpHeap TpHeap;

TpHeap *tp_heap_new (GCompareFunc comparator, GDestroyNotify destructor)
  G_GNUC_WARN_UNUSED_RESULT;
void tp_heap_destroy (TpHeap *heap);
void tp_heap_clear (TpHeap *heap);

void tp_heap_add (TpHeap *heap, gpointer element);
void tp_heap_remove (TpHeap *heap, gpointer element);
gpointer tp_heap_peek_first (TpHeap *heap);
gpointer tp_heap_extract_first (TpHeap *heap);

guint tp_heap_size (TpHeap *heap);

G_END_DECLS

#endif
