/*
 * TpHeap - a heap queue
 *
 * Copyright (C) 2006, 2007 Nokia Corporation. All rights reserved.
 * Copyright (C) 2007 Collabora Ltd. <http://www.collabora.co.uk/>
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

/**
 * SECTION:heap
 * @title: TpHeap
 * @short_description: a heap queue of pointers
 *
 * A heap queue of pointers.
 */

#include "config.h"

#include <telepathy-glib/heap.h>

#include <glib.h>

#define DEFAULT_SIZE 64

/**
 * TpHeap:
 *
 * Structure representing the heap queue. All fields are private.
 */
struct _TpHeap
{
  GPtrArray *data;
  GCompareFunc comparator;
  GDestroyNotify destructor;
};

/**
 * tp_heap_new:
 * @comparator: Comparator by which to order the pointers in the heap
 * @destructor: Function to call on the pointers when the heap is destroyed
 *  or cleared, or %NULL if this is not needed
 *
 * <!--Returns: says it all-->
 *
 * Returns: A new, empty heap queue.
 */
TpHeap *
tp_heap_new (GCompareFunc comparator, GDestroyNotify destructor)
{
  TpHeap *ret = g_slice_new (TpHeap);
  g_assert (comparator != NULL);

  ret->data = g_ptr_array_sized_new (DEFAULT_SIZE);
  ret->comparator = comparator;
  ret->destructor = destructor;

  return ret;
}

/**
 * tp_heap_destroy:
 * @heap: The heap queue
 *
 * Destroy a #TpHeap. The destructor, if any, is called on all items.
 */
void
tp_heap_destroy (TpHeap * heap)
{
  g_return_if_fail (heap != NULL);

  if (heap->destructor)
    {
      guint i;

      for (i = 0; i < heap->data->len; i++)
        {
          (heap->destructor) (g_ptr_array_index (heap->data, i));
        }
    }

  g_ptr_array_unref (heap->data);
  g_slice_free (TpHeap, heap);
}

/**
 * tp_heap_clear:
 * @heap: The heap queue
 *
 * Remove all items from a #TpHeap. The destructor, if any, is called on all
 * items.
 */
void
tp_heap_clear (TpHeap *heap)
{
  g_return_if_fail (heap != NULL);

  if (heap->destructor)
    {
      guint i;

      for (i = 0; i < heap->data->len; i++)
        {
          (heap->destructor) (g_ptr_array_index (heap->data, i));
        }
    }

  g_ptr_array_unref (heap->data);
  heap->data = g_ptr_array_sized_new (DEFAULT_SIZE);
}

#define HEAP_INDEX(heap, index) (g_ptr_array_index ((heap)->data, (index)-1))

/**
 * tp_heap_add:
 * @heap: The heap queue
 * @element: An element
 *
 * Add element to the heap queue, maintaining correct order.
 */
void
tp_heap_add (TpHeap *heap, gpointer element)
{
  guint m;

  g_return_if_fail (heap != NULL);

  g_ptr_array_add (heap->data, element);
  m = heap->data->len;
  while (m != 1)
    {
      gpointer parent = HEAP_INDEX (heap, m / 2);

      if (heap->comparator (element, parent) < 0)
        {
          HEAP_INDEX (heap, m / 2) = element;
          HEAP_INDEX (heap, m) = parent;
          m /= 2;
        }
      else
        break;
    }
}

/**
 * tp_heap_peek_first:
 * @heap: The heap queue
 *
 * <!--Returns: says it all-->
 *
 * Returns: The first item in the queue, or %NULL if the queue is empty
 */
gpointer
tp_heap_peek_first (TpHeap *heap)
{
  g_return_val_if_fail (heap != NULL, NULL);

  if (heap->data->len > 0)
    return HEAP_INDEX (heap, 1);
  else
    return NULL;
}

/*
 * extract_element:
 * @heap: The heap queue
 * @index: The index into the queue
 *
 * Remove the element at 1-based index @index from the queue and return it.
 * The destructor, if any, is not called.
 *
 * Returns: The element with 1-based index @index
 */
static gpointer
extract_element (TpHeap * heap, int index)
{
  gpointer ret;

  g_return_val_if_fail (heap != NULL, NULL);

  if (heap->data->len > 0)
    {
      guint m = heap->data->len;
      guint i = 1, j;
      ret = HEAP_INDEX (heap, index);

      HEAP_INDEX (heap, index) = HEAP_INDEX (heap, m);

      while (i * 2 <= m)
        {
          /* select the child which is supposed to come FIRST */
          if ((i * 2 + 1 <= m)
              && (heap->
                  comparator (HEAP_INDEX (heap, i * 2),
                              HEAP_INDEX (heap, i * 2 + 1)) > 0))
            j = i * 2 + 1;
          else
            j = i * 2;

          if (heap->comparator (HEAP_INDEX (heap, i), HEAP_INDEX (heap, j)) >
              0)
            {
              gpointer tmp = HEAP_INDEX (heap, i);
              HEAP_INDEX (heap, i) = HEAP_INDEX (heap, j);
              HEAP_INDEX (heap, j) = tmp;
              i = j;
            }
          else
            break;
        }

      g_ptr_array_remove_index (heap->data, m - 1);
    }
  else
    ret = NULL;

  return ret;
}

/**
 * tp_heap_remove:
 * @heap: The heap queue
 * @element: An element in the heap
 *
 * Remove @element from @heap, if it's present. The destructor, if any,
 * is not called.
 */
void
tp_heap_remove (TpHeap *heap, gpointer element)
{
    guint i;

    g_return_if_fail (heap != NULL);

    for (i = 1; i <= heap->data->len; i++)
      {
          if (element == HEAP_INDEX (heap, i))
            {
              extract_element (heap, i);
              break;
            }
      }
}

/**
 * tp_heap_extract_first:
 * @heap: The heap queue
 *
 * Remove and return the first element in the queue. The destructor, if any,
 * is not called.
 *
 * Returns: the removed element
 */
gpointer
tp_heap_extract_first (TpHeap * heap)
{
  g_return_val_if_fail (heap != NULL, NULL);

  if (heap->data->len == 0)
      return NULL;

  return extract_element (heap, 1);
}

/**
 * tp_heap_size:
 * @heap: The heap queue
 *
 * <!--Returns: says it all-->
 *
 * Returns: The number of items in @heap
 */
guint
tp_heap_size (TpHeap *heap)
{
  g_return_val_if_fail (heap != NULL, 0);

  return heap->data->len;
}
