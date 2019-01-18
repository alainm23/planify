/*
 * handle-set.c - a set which refs a handle when inserted
 *
 * Copyright (C) 2005,2006,2007 Collabora Ltd.
 * Copyright (C) 2005,2006,2007 Nokia Corporation
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

#include "config.h"

/* there is no handle-set.h - handle set and handle repo have a circular
 * dependency, so they share a header */
#include <telepathy-glib/handle-repo.h>

#include <glib.h>

#include <telepathy-glib/intset.h>
#define DEBUG_FLAG TP_DEBUG_HANDLES
#include "debug-internal.h"

/**
 * TpHandleSet:
 *
 * A set of handles. This is similar to a #TpIntset (and implemented using
 * one), but adding a handle to the set also references it.
 */
struct _TpHandleSet
{
  TpHandleRepoIface *repo;
  TpIntset *intset;
};

/**
 * TP_TYPE_HANDLE_SET: (skip)
 *
 * The boxed type of a #TpHandleSet.
 *
 * Since: 0.11.6
 */

G_DEFINE_BOXED_TYPE (TpHandleSet, tp_handle_set, tp_handle_set_copy,
    tp_handle_set_destroy)

/**
 * tp_handle_set_new: (skip)
 * @repo: #TpHandleRepoIface that holds the handles to be reffed by this set
 *
 * Creates a new #TpHandleSet
 *
 * Returns: (transfer full): A new #TpHandleSet
 */
TpHandleSet *
tp_handle_set_new (TpHandleRepoIface *repo)
{
  TpHandleSet *set;
  g_assert (repo != NULL);

  set = g_slice_new0 (TpHandleSet);
  set->intset = tp_intset_new ();
  set->repo = repo;

  return set;
}

/**
 * tp_handle_set_new_from_array: (skip)
 * @repo: #TpHandleRepoIface that holds the handles to be reffed by this set
 * @array: (element-type uint): array of handles to be referenced by this set
 *
 * Creates a new #TpHandleSet
 *
 * Returns: (transfer full): A new #TpHandleSet
 *
 * Since: 0.11.7
 */
TpHandleSet *
tp_handle_set_new_from_array (TpHandleRepoIface *repo,
    const GArray *array)
{
  TpHandleSet *set = tp_handle_set_new (repo);
  TpIntset *tmp = tp_intset_from_array (array);

  tp_intset_destroy (tp_handle_set_update (set, tmp));
  tp_intset_destroy (tmp);
  return set;
}

static void
freer (TpHandleSet *set, TpHandle handle, gpointer userdata)
{
  tp_handle_set_remove (set, handle);
}

/**
 * tp_handle_set_destroy: (skip)
 * @set:#TpHandleSet to destroy
 *
 * Delete a #TpHandleSet and unreference any handles that it holds
 */
void
tp_handle_set_destroy (TpHandleSet *set)
{
  tp_handle_set_foreach (set, freer, NULL);
  tp_intset_destroy (set->intset);
  g_slice_free (TpHandleSet, set);
}

/**
 * tp_handle_set_clear: (skip)
 * @set:#TpHandleSet to clear
 *
 * Remove every handle from @set, releasing the references it holds.
 *
 * Since: 0.11.6
 */
void
tp_handle_set_clear (TpHandleSet *set)
{
  tp_handle_set_foreach (set, freer, NULL);
  g_assert (tp_handle_set_is_empty (set));
}

/**
 * tp_handle_set_is_empty: (skip)
 * @set:#TpHandleSet to check
 *
 * Return the same thing as <code>(tp_handle_set_size (set) == 0)</code>,
 * but calculated more efficiently.
 *
 * Returns: %TRUE if the set has no members
 *
 * Since: 0.11.6
 */
gboolean
tp_handle_set_is_empty (const TpHandleSet *set)
{
  return tp_intset_is_empty (set->intset);
}

/**
 * tp_handle_set_peek: (skip)
 * @set:#TpHandleSet to peek at
 *
 * <!--Returns: says it all, this comment is just to keep gtkdoc happy-->
 *
 * Returns: (transfer none): the underlying #TpIntset used by this #TpHandleSet
 */
TpIntset *
tp_handle_set_peek (TpHandleSet *set)
{
  return set->intset;
}

/**
 * tp_handle_set_add: (skip)
 * @set: #TpHandleSet to add this handle to
 * @handle: handle to add
 *
 * Add a handle to a #TpHandleSet, and reference it in the attached
 * #TpHandleRepoIface
 *
 */
void
tp_handle_set_add (TpHandleSet *set, TpHandle handle)
{
  g_return_if_fail (set != NULL);
  g_return_if_fail (handle != 0);

  tp_intset_add (set->intset, handle);
}

/**
 * tp_handle_set_remove: (skip)
 * @set: #TpHandleSet to remove this handle from
 * @handle: handle to remove
 *
 * Remove a handle from a #TpHandleSet, and unreference it in the attached
 * #TpHandleRepoIface
 *
 * Returns: FALSE if the handle was invalid, or was not in this set
 */

gboolean
tp_handle_set_remove (TpHandleSet *set, TpHandle handle)
{
  g_return_val_if_fail (set != NULL, FALSE);
  g_return_val_if_fail (handle != 0, FALSE);

  return tp_intset_remove (set->intset, handle);
}

/**
 * tp_handle_set_is_member: (skip)
 * @set: A #TpHandleSet
 * @handle: handle to check
 *
 * Check if the handle is in this set
 *
 * Returns: TRUE if the handle is in this set
 *
 */
gboolean
tp_handle_set_is_member (const TpHandleSet *set,
    TpHandle handle)
{
  return tp_intset_is_member (set->intset, handle);
}

typedef struct __foreach_data
{
  TpHandleSet *set;
  TpHandleSetMemberFunc func;
  gpointer userdata;
} _foreach_data;

static void
foreach_helper (guint i, gpointer userdata)
{
  _foreach_data *data = userdata;

  data->func (data->set, i, data->userdata);
}

/**
 * TpHandleSetMemberFunc: (skip)
 * @set: The set of handles on which tp_handle_set_foreach() was called
 * @handle: A handle in the set
 * @userdata: Arbitrary user data as supplied to tp_handle_set_foreach()
 *
 * Signature of the callback used to iterate over the handle set in
 * tp_handle_set_foreach().
 */

/**
 * tp_handle_set_foreach: (skip)
 * @set: A set of handles
 * @func: (scope call): A callback
 * @user_data: Arbitrary data to pass to @func
 *
 * Call @func(@set, @handle, @userdata) for each handle in @set.
 */
void
tp_handle_set_foreach (TpHandleSet *set, TpHandleSetMemberFunc func,
    gpointer user_data)
{
  _foreach_data data = {set, func, user_data};
  tp_intset_foreach (set->intset, foreach_helper, &data);
}

/**
 * tp_handle_set_size: (skip)
 * @set: A set of handles
 *
 * <!--no further documentation needed-->
 *
 * Returns: the number of handles in this set
 */
int
tp_handle_set_size (const TpHandleSet *set)
{
  return tp_intset_size (set->intset);
}

/**
 * tp_handle_set_to_array: (skip)
 * @set: A handle set
 *
 * <!--Returns: says it all, this comment is just to keep gtkdoc happy-->
 *
 * Returns: (element-type uint): a newly-allocated GArray of guint representing
 * the handles in the set
 */
GArray *
tp_handle_set_to_array (const TpHandleSet *set)
{
  g_return_val_if_fail (set != NULL, NULL);

  return tp_intset_to_array (set->intset);
}

/**
 * tp_handle_set_to_identifier_map:
 * @self: a handle set
 *
 * Returns a dictionary mapping each handle in @self to the corresponding
 * identifier, as if retrieved by calling tp_handle_inspect() on each handle.
 * The type of the returned value is described as
 * <code>Handle_Identifier_Map</code> in the Telepathy specification.
 *
 * Returns: (transfer full) (element-type TpHandle utf8): a map from the
 *  handles in @self to the corresponding identifier.
 */
GHashTable *
tp_handle_set_to_identifier_map (
    TpHandleSet *self)
{
  /* We don't bother dupping the strings: they remain valid as long as the
   * connection's alive and hence the repo exists.
   */
  GHashTable *map = g_hash_table_new (NULL, NULL);
  TpIntsetFastIter iter;
  TpHandle handle;

  g_return_val_if_fail (self != NULL, map);

  tp_intset_fast_iter_init (&iter, self->intset);
  while (tp_intset_fast_iter_next (&iter, &handle))
    {
      if (handle == 0 || !tp_handle_is_valid (self->repo, handle, NULL))
        {
          WARNING ("handle set %p contains invalid handle #%u", self, handle);
        }
      else
        {
          g_hash_table_insert (map, GUINT_TO_POINTER (handle),
              (gchar *) tp_handle_inspect (self->repo, handle));
        }
    }

  return map;
}

/**
 * tp_handle_set_copy: (skip)
 * @other: another handle set
 *
 * Creates a new #TpHandleSet with the same contents as @other.
 *
 * Returns: a new set
 *
 * Since: 0.11.6
 */
TpHandleSet *
tp_handle_set_copy (const TpHandleSet *other)
{
  g_return_val_if_fail (other != NULL, NULL);

  return tp_handle_set_new_from_intset (other->repo, other->intset);
}

/**
 * tp_handle_set_new_containing: (skip)
 * @repo: #TpHandleRepoIface that holds the handles to be reffed by this set
 * @handle: a valid handle
 *
 * Creates a new #TpHandleSet from a specified handle repository and single
 * handle.
 *
 * Returns: (transfer full): A new #TpHandleSet
 *
 * Since: 0.13.0
 */
TpHandleSet *
tp_handle_set_new_containing (TpHandleRepoIface *repo,
    TpHandle handle)
{
  TpHandleSet *set = tp_handle_set_new (repo);

  tp_handle_set_add (set, handle);
  return set;
}

/**
 * tp_handle_set_new_from_intset: (skip)
 * @repo: #TpHandleRepoIface that holds the handles to be reffed by this set
 * @intset: a set of handles, which must all be valid
 *
 * Creates a new #TpHandleSet from a specified handle repository and
 * set of handles.
 *
 * Returns: (transfer full): A new #TpHandleSet
 *
 * Since: 0.13.0
 */
TpHandleSet *
tp_handle_set_new_from_intset (TpHandleRepoIface *repo,
    const TpIntset *intset)
{
  TpHandleSet *set;

  g_return_val_if_fail (repo != NULL, NULL);
  g_return_val_if_fail (intset != NULL, NULL);

  set = g_slice_new0 (TpHandleSet);
  set->repo = repo;
  set->intset = tp_intset_copy (intset);
  return set;
}

/**
 * tp_handle_set_update: (skip)
 * @set: a #TpHandleSet to update
 * @add: a #TpIntset of handles to add
 *
 * Add a set of handles to a handle set, referencing those which are not
 * already members. The TpIntset returned must be freed with tp_intset_destroy.
 *
 * Returns: the handles which were added (some subset of @add)
 */
TpIntset *
tp_handle_set_update (TpHandleSet *set, const TpIntset *add)
{
  TpIntset *ret, *tmp;

  g_return_val_if_fail (set != NULL, NULL);
  g_return_val_if_fail (add != NULL, NULL);

  /* reference each of ADD - CURRENT */
  ret = tp_intset_difference (add, set->intset);

  /* update CURRENT to be the union of CURRENT and ADD */
  tmp = tp_intset_union (add, set->intset);
  tp_intset_destroy (set->intset);
  set->intset = tmp;

  return ret;
}

/**
 * tp_handle_set_difference_update: (skip)
 * @set: a #TpHandleSet to update
 * @remove: a #TpIntset of handles to remove
 *
 * Remove a set of handles from a handle set, dereferencing those which are
 * members. The TpIntset returned must be freed with tp_intset_destroy.
 *
 * If you want to be able to inspect the handles in the set returned,
 * you must ensure that this function does not cause their refcount to drop
 * to zero, for instance by temporarily taking a reference to all the
 * handles in @remove, calling this function, doing something with the
 * result and discarding the temporary references.
 *
 * Returns: the handles which were dereferenced and removed (some subset
 *  of @remove).
 */
TpIntset *
tp_handle_set_difference_update (TpHandleSet *set, const TpIntset *remove)
{
  TpIntset *ret, *tmp;

  g_return_val_if_fail (set != NULL, NULL);
  g_return_val_if_fail (remove != NULL, NULL);

  /* dereference each of REMOVE n CURRENT */
  ret = tp_intset_intersection (remove, set->intset);

  /* update CURRENT to be CURRENT - REMOVE */
  tmp = tp_intset_difference (set->intset, remove);
  tp_intset_destroy (set->intset);
  set->intset = tmp;

  return ret;
}

/**
 * tp_handle_set_dump:
 * @self: a handle set
 *
 * Format a #TpHandleSet for debug output.
 *
 * Returns: (transfer full) (type utf8): a string representation of the
 *  handle set suitable for debug output
 */
gchar *
tp_handle_set_dump (const TpHandleSet *self)
{
  TpIntsetFastIter iter;
  guint handle;
  GString *string = g_string_new ("{ ");

  tp_intset_fast_iter_init (&iter, self->intset);

  while (tp_intset_fast_iter_next (&iter, &handle))
    {
      if (handle == 0 || !tp_handle_is_valid (self->repo, handle, NULL))
        {
          g_string_append_printf (string, "#%u <invalid>, ", handle);
        }
      else
        {
          g_string_append_printf (string, "#%u '%s', ", handle,
              tp_handle_inspect (self->repo, handle));
        }
    }

  g_string_append_c (string, '}');

  return g_string_free (string, FALSE);
}
