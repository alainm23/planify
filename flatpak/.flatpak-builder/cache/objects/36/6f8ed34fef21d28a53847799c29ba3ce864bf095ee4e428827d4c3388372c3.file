/* intset.c - Source for a set of unsigned integers (implemented as a
 * variable length bitfield)
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

/**
 * SECTION:intset
 * @title: TpIntset
 * @short_description: a set of unsigned integers
 * @see_also: #TpHandleSet
 *
 * A #TpIntset is a set of unsigned integers, implemented as a
 * dynamically-allocated sparse bitfield.
 */

#include "config.h"

#include <telepathy-glib/intset.h>
#include <telepathy-glib/util.h>

#include <string.h>
#include <glib.h>

/* On platforms with 64-bit pointers we could pack 64 bits into the values,
 * if count_bits32() is replaced with a 64-bit version. This doesn't work
 * yet. */
#undef USE_64_BITS

#ifdef USE_64_BITS
#   define BITFIELD_BITS 64
#   define BITFIELD_LOG2_BITS 6
#else
#   define BITFIELD_BITS 32
#   define BITFIELD_LOG2_BITS 5
#endif

G_STATIC_ASSERT (1 << BITFIELD_LOG2_BITS == BITFIELD_BITS);
G_STATIC_ASSERT (sizeof (gpointer) >= sizeof (gsize));
#define LOW_MASK (BITFIELD_BITS - 1)
#define HIGH_PART(x) (x & ~LOW_MASK)
#define LOW_PART(x) (x & LOW_MASK)

/**
 * TP_TYPE_INTSET:
 *
 * The boxed type of a #TpIntset.
 *
 * Since: 0.11.3
 */

GType
tp_intset_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      /* The "TpIntSet" type has to be registered for backwards compatibility.
       * The canonical name of the type is now "TpIntset"; see fdo#30134. */
      g_boxed_type_register_static (g_intern_static_string ("TpIntSet"),
          (GBoxedCopyFunc) tp_intset_copy,
          (GBoxedFreeFunc) tp_intset_destroy);
      type = g_boxed_type_register_static (g_intern_static_string ("TpIntset"),
          (GBoxedCopyFunc) tp_intset_copy,
          (GBoxedFreeFunc) tp_intset_destroy);
    }

  return type;
}

/**
 * TpIntFunc:
 * @i: The relevant integer
 * @userdata: Opaque user data
 *
 * A callback function acting on unsigned integers.
 */
/* (typedef, see header) */

/**
 * TpIntSetIter: (skip)
 *
 * Before 0.11.16, this was the name for <type>TpIntsetIter</type>, but
 * it's now just a backwards compatibility typedef.
 *
 * Deprecated: since 0.19.0. Use #TpIntsetFastIter instead
 */

/**
 * TpIntsetIter:
 * @set: The set iterated over.
 * @element: Must be (guint)(-1) before iteration starts. Set to the next
 *  element in the set by tp_intset_iter_next(); undefined after
 *  tp_intset_iter_next() returns %FALSE.
 *
 * A structure representing iteration over a set of integers. Must be
 * initialized with either TP_INTSET_ITER_INIT() or tp_intset_iter_init().
 *
 * Since 0.11.6, consider using #TpIntsetFastIter if iteration in
 * numerical order is not required.
 *
 * Before 0.11.16, this type was called <type>TpIntSetIter</type>,
 * which is now a backwards compatibility typedef.
 *
 * Deprecated: since 0.19.0. Use #TpIntsetFastIter instead
 */
/* (public, see header) */

/**
 * TP_INTSET_ITER_INIT:
 * @set: A set of integers
 *
 * A suitable static initializer for a #TpIntsetIter, to be used as follows:
 *
 * <informalexample><programlisting>
 * void
 * do_something (const TpIntset *intset)
 * {
 *   TpIntsetIter iter = TP_INTSET_ITER_INIT (intset);
 *   /<!-- -->* ... do something with iter ... *<!-- -->/
 * }
 * </programlisting></informalexample>
 *
 * Deprecated: since 0.19.0. Use #TpIntsetFastIter instead
 */
/* (macro, see header) */

/**
 * tp_intset_iter_init:
 * @iter: An integer set iterator to be initialized.
 * @set: An integer set to be used by that iterator
 *
 * Reset the iterator @iter to the beginning and make it iterate over @set.
 *
 * Deprecated: since 0.19.0. Use #TpIntsetFastIter instead
 */
void
tp_intset_iter_init (
    TpIntsetIter *iter,
    const TpIntset *set)
{
  g_return_if_fail (iter != NULL);
  iter->set = set;
  iter->element = (guint)(-1);
}

/**
 * tp_intset_iter_reset:
 * @iter: An integer set iterator to be reset.
 *
 * Reset the iterator @iter to the beginning. It must already be associated
 * with a set.
 *
 * Deprecated: since 0.19.0. Use #TpIntsetFastIter instead
 */
void
tp_intset_iter_reset (TpIntsetIter *iter)
{
  g_return_if_fail (iter != NULL);
  g_return_if_fail (iter->set != NULL);
  iter->element = (guint)(-1);
}

/**
 * TpIntset:
 *
 * Opaque type representing a set of unsigned integers.
 *
 * Before 0.11.16, this type was called <type>TpIntSet</type>, which is
 * now a backwards compatibility typedef.
 */

struct _TpIntset
{
  /* HIGH_PART(n) => bitfield where bit LOW_PART(n) is set if n is present.
   *
   * For instance, when using 32-bit values, the set { 5, 23 } is represented
   * by the map { 0 => (1 << 23 | 1 << 5) }, and the set { 1, 32, 42 } is
   * represented by the map { 0 => (1 << 1), 32 => (1 << 10 | 1 << 0) }. */
  GHashTable *table;
  guint largest_ever;
};

/*
 * Update @set's largest_ever member to be at least as large as everything
 * that could be encoded in the hash table key @key.
 *
 * We could use g_bit_nth_msf (value, BITFIELD_BITS) instead of LOW_MASK if we
 * wanted to get largest_ever exactly right, but we just need something
 * reasonable to make TpIntsetIter terminate early, and carrying on for up to
 * BITFIELD_BITS extra iterations isn't a problem.
 */
static inline void
intset_update_largest_ever (TpIntset *set,
    gpointer key)
{
  guint upper_bound = GPOINTER_TO_UINT (key) | LOW_MASK;

  if (set->largest_ever < upper_bound)
    set->largest_ever = upper_bound;
}

/**
 * tp_intset_sized_new:
 * @size: ignored (it was previously 1 more than the largest integer you
 *  expect to store)
 *
 * Allocate a new integer set.
 *
 * Returns: a new, empty integer set to be destroyed with tp_intset_destroy()
 */
TpIntset *
tp_intset_sized_new (guint size G_GNUC_UNUSED)
{
  return tp_intset_new ();
}

/**
 * tp_intset_new:
 *
 * Allocate a new integer set.
 *
 * Returns: a new, empty integer set to be destroyed with tp_intset_destroy()
 */
TpIntset *
tp_intset_new ()
{
  TpIntset *set = g_slice_new (TpIntset);

  set->table = g_hash_table_new (NULL, NULL);
  set->largest_ever = 0;
  return set;
}

/**
 * tp_intset_new_containing:
 * @element: integer to add to a new set
 *
 * Allocate a new integer set containing the given integer.
 *
 * Returns: a new integer set containing @element, to be destroyed with
 * tp_intset_destroy()
 *
 * Since: 0.7.26
 */
TpIntset *
tp_intset_new_containing (guint element)
{
  TpIntset *ret = tp_intset_new ();

  tp_intset_add (ret, element);

  return ret;
}

/**
 * tp_intset_destroy:
 * @set: set
 *
 * Free all memory used by the set.
 */
void
tp_intset_destroy (TpIntset *set)
{
  g_return_if_fail (set != NULL);

  g_hash_table_unref (set->table);
  g_slice_free (TpIntset, set);
}

/**
 * tp_intset_clear:
 * @set: set
 *
 * Unset every integer in the set.
 */
void
tp_intset_clear (TpIntset *set)
{
  g_return_if_fail (set != NULL);

  g_hash_table_remove_all (set->table);
}

/**
 * tp_intset_add:
 * @set: set
 * @element: integer to add
 *
 * Add an integer into a TpIntset.
 */
void
tp_intset_add (TpIntset *set,
    guint element)
{
  gpointer key = GSIZE_TO_POINTER ((gsize) HIGH_PART (element));
  gsize bit = LOW_PART (element);
  gpointer old_value, new_value;

  g_return_if_fail (set != NULL);

  old_value = g_hash_table_lookup (set->table, key);
  new_value = GSIZE_TO_POINTER (GPOINTER_TO_SIZE (old_value) | (1 << bit));

  if (old_value != new_value)
    g_hash_table_insert (set->table, key, new_value);

  if (element > set->largest_ever)
    set->largest_ever = element;
}

/**
 * tp_intset_remove:
 * @set: set
 * @element: integer to add
 *
 * Remove an integer from a TpIntset
 *
 * Returns: %TRUE if @element was previously in @set
 */
gboolean
tp_intset_remove (TpIntset *set,
    guint element)
{
  gpointer key = GSIZE_TO_POINTER ((gsize) HIGH_PART (element));
  gsize bit = LOW_PART (element);
  gpointer old_value, new_value;

  g_return_val_if_fail (set != NULL, FALSE);

  old_value = g_hash_table_lookup (set->table, key);
  new_value = GSIZE_TO_POINTER (GPOINTER_TO_SIZE (old_value) & ~ (1 << bit));

  if (old_value != new_value)
    {
      if (new_value == NULL)
        g_hash_table_remove (set->table, key);
      else
        g_hash_table_insert (set->table, key, new_value);

      return TRUE;
    }

  return FALSE;
}

static inline gboolean
_tp_intset_is_member (const TpIntset *set,
    guint element)
{
  gpointer key = GSIZE_TO_POINTER ((gsize) HIGH_PART (element));
  gsize bit = LOW_PART (element);
  gpointer value;

  value = g_hash_table_lookup (set->table, key);
  return ((GPOINTER_TO_SIZE (value) & (1 << bit)) != 0);
}

/**
 * tp_intset_is_member:
 * @set: set
 * @element: integer to test
 *
 * Tests if @element is a member of @set
 *
 * Returns: %TRUE if @element is in @set
 */
gboolean
tp_intset_is_member (const TpIntset *set, guint element)
{
  g_return_val_if_fail (set != NULL, FALSE);

  return _tp_intset_is_member (set, element);
}

/**
 * tp_intset_foreach:
 * @set: set
 * @func: (scope call): @TpIntFunc to use to iterate the set
 * @userdata: user data to pass to each call of @func
 *
 * Call @func(element, @userdata) for each element of @set, in order.
 */

void
tp_intset_foreach (const TpIntset *set,
    TpIntFunc func,
    gpointer userdata)
{
  gsize high_part, low_part;

  g_return_if_fail (set != NULL);
  g_return_if_fail (func != NULL);

  for (high_part = 0;
      high_part <= set->largest_ever;
      high_part += BITFIELD_BITS)
    {
      gsize entry = GPOINTER_TO_SIZE (g_hash_table_lookup (set->table,
            GSIZE_TO_POINTER (high_part)));

      if (entry == 0)
        continue;

      for (low_part = 0; low_part < BITFIELD_BITS; low_part++)
        {
          if (entry & (1 << low_part))
            {
              func (high_part + low_part, userdata);
            }
        }
    }
}

static void
addint (guint i, gpointer data)
{
  GArray *array = (GArray *) data;
  g_array_append_val (array, i);
}

/**
 * tp_intset_to_array:
 * @set: set to convert
 *
 * <!--Returns: says it all-->
 *
 * Returns: (element-type uint) (transfer full): a GArray of guint (which must
 *  be freed by the caller) containing the same integers as @set.
 */
GArray *
tp_intset_to_array (const TpIntset *set)
{
  GArray *array;

  g_return_val_if_fail (set != NULL, NULL);

  array = g_array_new (FALSE, TRUE, sizeof (guint));

  tp_intset_foreach (set, addint, array);

  return array;
}


/**
 * tp_intset_from_array:
 * @array: (element-type uint): An array of guint
 *
 * <!--Returns: says it all-->
 *
 * Returns: A set containing the same integers as @array.
 */

TpIntset *
tp_intset_from_array (const GArray *array)
{
  TpIntset *set;
  guint i;

  g_return_val_if_fail (array != NULL, NULL);

  set = tp_intset_new ();

  for (i = 0; i < array->len; i++)
    {
      tp_intset_add (set, g_array_index (array, guint, i));
    }

  return set;
}

/* these magic numbers would need adjusting for 64-bit storage */
G_STATIC_ASSERT (BITFIELD_BITS == 32);

static inline guint
count_bits32 (guint32 n)
{
  n = n - ((n >> 1) & 033333333333) - ((n >> 2) & 011111111111);
  return ((n + (n >> 3)) & 030707070707) % 63;
}

/**
 * tp_intset_size:
 * @set: A set of integers
 *
 * <!--Returns: says it all-->
 *
 * Returns: The number of integers in @set
 */

guint
tp_intset_size (const TpIntset *set)
{
  guint count = 0;
  gpointer entry;
  GHashTableIter iter;

  g_return_val_if_fail (set != NULL, 0);

  g_hash_table_iter_init (&iter, (GHashTable *) set->table);

  while (g_hash_table_iter_next (&iter, NULL, &entry))
    {
      count += count_bits32 (GPOINTER_TO_SIZE (entry));
    }

  return count;
}

/**
 * tp_intset_is_empty:
 * @set: a set of integers
 *
 * Return the same thing as <code>(tp_intset_size (set) == 0)</code>,
 * but calculated more efficiently.
 *
 * Returns: %TRUE if @set is empty
 *
 * Since: 0.11.6
 */
gboolean
tp_intset_is_empty (const TpIntset *set)
{
  g_return_val_if_fail (set != NULL, TRUE);
  return (g_hash_table_size (set->table) == 0);
}

/**
 * tp_intset_is_equal:
 * @left: A set of integers
 * @right: A set of integers
 *
 * <!--Returns: says it all-->
 *
 * Returns: %TRUE if @left and @right contain the same bits
 */

gboolean
tp_intset_is_equal (const TpIntset *left,
    const TpIntset *right)
{
  gpointer key, value;
  GHashTableIter iter;

  g_return_val_if_fail (left != NULL, FALSE);
  g_return_val_if_fail (right != NULL, FALSE);

  if (g_hash_table_size (left->table) != g_hash_table_size (right->table))
    return FALSE;

  g_hash_table_iter_init (&iter, (GHashTable *) left->table);

  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      if (g_hash_table_lookup (right->table, key) != value)
        {
          return FALSE;
        }
    }

  return TRUE;
}


/**
 * tp_intset_copy:
 * @orig: A set of integers
 *
 * <!--Returns: says it all-->
 *
 * Returns: A set containing the same integers as @orig, to be freed with
 * tp_intset_destroy() by the caller
 */

TpIntset *
tp_intset_copy (const TpIntset *orig)
{
  gpointer key, value;
  GHashTableIter iter;
  TpIntset *ret;

  g_return_val_if_fail (orig != NULL, NULL);

  ret = tp_intset_new ();

  g_hash_table_iter_init (&iter, (GHashTable *) orig->table);

  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      intset_update_largest_ever (ret, key);
      g_hash_table_insert (ret->table, key, value);
    }

  return ret;
}


/**
 * tp_intset_intersection:
 * @left: The left operand
 * @right: The right operand
 *
 * <!--Returns: says it all-->
 *
 * Returns: The set of those integers which are in both @left and @right
 * (analogous to the bitwise operation left & right), to be freed with
 * tp_intset_destroy() by the caller
 */

TpIntset *
tp_intset_intersection (const TpIntset *left, const TpIntset *right)
{
  gpointer key, value;
  GHashTableIter iter;
  TpIntset *ret;

  ret = tp_intset_new ();

  g_hash_table_iter_init (&iter, (GHashTable *) left->table);

  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      gsize v = GPOINTER_TO_SIZE (value);

      v &= GPOINTER_TO_SIZE (g_hash_table_lookup (right->table, key));

      if (v != 0)
        {
          intset_update_largest_ever (ret, key);
          g_hash_table_insert (ret->table, key, GSIZE_TO_POINTER (v));
        }
    }

  return ret;
}

/**
 * tp_intset_union:
 * @left: The left operand
 * @right: The right operand
 *
 * <!--Returns: says it all-->
 *
 * Returns: The set of those integers which are in either @left or @right
 * (analogous to the bitwise operation left | right), to be freed with
 * tp_intset_destroy() by the caller
 */

TpIntset *
tp_intset_union (const TpIntset *left, const TpIntset *right)
{
  TpIntset *ret;

  ret = tp_intset_copy (left);
  tp_intset_union_update (ret, right);

  return ret;
}

/**
 * tp_intset_union_update:
 * @self: the set to change
 * @other: members to add
 *
 * Add each integer in @other to @self, analogous to the bitwise operation
 * self |= other.
 *
 * Since: 0.13.10
 */
void
tp_intset_union_update (TpIntset *self,
    const TpIntset *other)
{
  gpointer key, value;
  GHashTableIter iter;

  g_hash_table_iter_init (&iter, (GHashTable *) other->table);

  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      gsize v = GPOINTER_TO_SIZE (value);

      intset_update_largest_ever (self, key);
      v |= GPOINTER_TO_SIZE (g_hash_table_lookup (self->table, key));
      g_hash_table_insert (self->table, key, GSIZE_TO_POINTER (v));
    }
}

/**
 * tp_intset_difference:
 * @left: The left operand
 * @right: The right operand
 *
 * <!--Returns: says it all-->
 *
 * Returns: The set of those integers which are in @left and not in @right
 * (analogous to the bitwise operation left & (~right)), to be freed with
 * tp_intset_destroy() by the caller
 */

TpIntset *
tp_intset_difference (const TpIntset *left, const TpIntset *right)
{
  TpIntset *ret;

  g_return_val_if_fail (left != NULL, NULL);
  g_return_val_if_fail (right != NULL, NULL);

  ret = tp_intset_copy (left);
  tp_intset_difference_update (ret, right);

  return ret;
}

/**
 * tp_intset_difference_update:
 * @self: the set to change
 * @other: members to remove
 *
 * Remove each integer in @other from @self, analogous to the bitwise
 * operation self &= (~other).
 *
 * Since: 0.13.10
 */
void
tp_intset_difference_update (TpIntset *self,
    const TpIntset *other)
{
  gpointer key, value;
  GHashTableIter iter;

  g_hash_table_iter_init (&iter, (GHashTable *) other->table);

  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      gsize v = GPOINTER_TO_SIZE (value);
      v = (GPOINTER_TO_SIZE (g_hash_table_lookup (self->table, key))) & ~v;

      /* No need to update largest_ever here - we're only deleting members. */

      if (v == 0)
        g_hash_table_remove (self->table, key);
      else
        g_hash_table_insert (self->table, key, GSIZE_TO_POINTER (v));
    }
}

/**
 * tp_intset_symmetric_difference:
 * @left: The left operand
 * @right: The right operand
 *
 * <!--Returns: says it all-->
 *
 * Returns: The set of those integers which are in either @left or @right
 * but not both (analogous to the bitwise operation left ^ right), to be freed
 * with tp_intset_destroy() by the caller
 */

TpIntset *
tp_intset_symmetric_difference (const TpIntset *left, const TpIntset *right)
{
  TpIntset *ret;
  gpointer key, value;
  GHashTableIter iter;

  g_return_val_if_fail (left != NULL, NULL);
  g_return_val_if_fail (right != NULL, NULL);

  ret = tp_intset_copy (left);

  g_hash_table_iter_init (&iter, (GHashTable *) right->table);

  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      gsize v = GPOINTER_TO_SIZE (value);
      v = v ^ GPOINTER_TO_SIZE (g_hash_table_lookup (ret->table, key));

      /* No need to update largest_ever here - we're only deleting members. */

      if (v == 0)
        g_hash_table_remove (ret->table, key);
      else
        g_hash_table_insert (ret->table, key, GSIZE_TO_POINTER (v));
    }

  return ret;
}

static void
_dump_foreach (guint i, gpointer data)
{
   GString *tmp = (GString *) data;

  if (tmp->len == 0)
    g_string_append_printf (tmp, "%u", i);
  else
    g_string_append_printf (tmp, " %u", i);
}

/**
 * tp_intset_dump:
 * @set: An integer set
 *
 * <!--Returns: says it all-->
 *
 * Returns: a string which the caller must free with g_free, listing the
 * numbers in @set in a human-readable format
 */
gchar *
tp_intset_dump (const TpIntset *set)
{
  GString *tmp = g_string_new ("");

  tp_intset_foreach (set, _dump_foreach, tmp);
  return g_string_free (tmp, FALSE);
}

/**
 * tp_intset_iter_next:
 * @iter: An iterator originally initialized with TP_INTSET_INIT(set)
 *
 * If there are integers in (@iter->set) higher than (@iter->element), set
 * (iter->element) to the next one and return %TRUE. Otherwise return %FALSE.
 *
 * Usage:
 *
 * <informalexample><programlisting>
 * TpIntsetIter iter = TP_INTSET_INIT (intset);
 * while (tp_intset_iter_next (&amp;iter))
 * {
 *   printf ("%u is in the intset\n", iter.element);
 * }
 * </programlisting></informalexample>
 *
 * Since 0.11.6, consider using #TpIntsetFastIter if iteration in
 * numerical order is not required.
 *
 * Returns: %TRUE if (@iter->element) has been advanced
 */
gboolean
tp_intset_iter_next (TpIntsetIter *iter)
{
  g_return_val_if_fail (iter != NULL, FALSE);
  g_return_val_if_fail (iter->set != NULL, FALSE);

  do
    {
      if (iter->element == (guint)(-1))
        {
          /* only just started */
          iter->element = 0;
        }
      else
        {
          ++iter->element;
        }

      if (_tp_intset_is_member (iter->set, iter->element))
        {
          return TRUE;
        }
    }
  while (iter->element < iter->set->largest_ever &&
      iter->element != (guint)(-1));
  return FALSE;
}

/**
 * TpIntSetFastIter: (skip)
 *
 * Before 0.11.16, this was the name for <type>TpIntsetFastIter</type>,
 * but it's now just a backwards compatibility typedef.
 *
 * Deprecated: since 0.19.0. Use #TpIntsetFastIter instead
 */

/**
 * TpIntsetFastIter:
 *
 * An opaque structure representing iteration in undefined order over a set of
 * integers. Must be initialized with tp_intset_fast_iter_init().
 *
 * Before 0.11.16, this type was called <type>TpIntSetFastIter</type>,
 * which is now a backwards compatibility typedef.
 *
 * Usage is similar to #GHashTableIter:
 *
 * <informalexample><programlisting>
 * TpIntsetFastIter iter;
 * guint element;
 *
 * tp_intset_fast_iter_init (&amp;iter, intset);
 *
 * while (tp_intset_fast_iter_next (&amp;iter, &amp;element))
 * {
 *   printf ("%u is in the intset\n", element);
 * }
 * </programlisting></informalexample>
 *
 * Since: 0.11.6
 */

typedef struct {
    GHashTableIter hash_iter;
    gboolean ok;
    gsize high_part;
    gsize bitfield;
} RealFastIter;

G_STATIC_ASSERT (sizeof (TpIntsetFastIter) >= sizeof (RealFastIter));

/**
 * tp_intset_fast_iter_init:
 * @iter: an iterator
 * @set: a set
 *
 * Initialize @iter to iterate over @set in arbitrary order. @iter will become
 * invalid if @set is modified.
 *
 * Since: 0.11.6
 */
void
tp_intset_fast_iter_init (TpIntsetFastIter *iter,
    const TpIntset *set)
{
  RealFastIter *real = (RealFastIter *) iter;
  g_return_if_fail (set != NULL);
  g_return_if_fail (set->table != NULL);

  g_hash_table_iter_init (&real->hash_iter, (GHashTable *) set->table);
  real->bitfield = 0;
  real->high_part = 0;
  real->ok = TRUE;
}

/**
 * tp_intset_fast_iter_next:
 * @iter: an iterator
 * @output: a location to store a new integer, in arbitrary order
 *
 * Advances @iter and retrieves the integer it now points to. Iteration
 * is not necessarily in numerical order.
 *
 * Returns: %FALSE if the end of the set has been reached
 *
 * Since: 0.11.6
 */
gboolean
tp_intset_fast_iter_next (TpIntsetFastIter *iter,
    guint *output)
{
  RealFastIter *real = (RealFastIter *) iter;
  guint low_part;

  if (!real->ok)
    return FALSE;

  if (real->bitfield == 0)
    {
      gpointer k, v;

      real->ok = g_hash_table_iter_next (&real->hash_iter, &k, &v);

      if (!real->ok)
        return FALSE;

      real->high_part = GPOINTER_TO_SIZE (k);
      real->bitfield = GPOINTER_TO_SIZE (v);
      g_assert (real->bitfield != 0);
    }

  for (low_part = 0; low_part < BITFIELD_BITS; low_part++)
    {
      if (real->bitfield & (1 << low_part))
        {
          /* clear the bit so we won't return it again */
          real->bitfield -= (1 << low_part);

          if (output != NULL)
            *output = real->high_part | low_part;

          return TRUE;
        }
    }

  g_assert_not_reached ();
}
