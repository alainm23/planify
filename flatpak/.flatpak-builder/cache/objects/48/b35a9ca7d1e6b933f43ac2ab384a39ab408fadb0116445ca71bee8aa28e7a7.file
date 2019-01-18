/*
 * small-set - a set optimized for fast iteration when there are few items
 *
 * Copyright © 2013 Intel Corporation
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 *
 * Authors:
 *      Simon McVittie <simon.mcvittie@collabora.co.uk>
 */

#include "folks/small-set.h"
#include "folks/small-set-internal.h"

/*
 * FolksSmallSet:
 *
 * FolksSmallSet is a wrapper around an array, designed to be used for
 * sets with zero or few items. If necessary, it can be used
 * as a read-only, Gee-compatible wrapper around a separately-maintained
 * GPtrArray.
 *
 * Memory efficiency: this is about as small as you're going to get, given
 * the constraints of libgee.
 *
 * Performance: iteration is very fast, iterating over a read-only view is
 * very fast, copying an existing set is quite fast, foreach is quite fast.
 * Everything else scales up poorly with large numbers of elements:
 * adding, removing and testing membership are all O(n). The intention is
 * that if n can be large, you should use HashSet or something.
 *
 * The constructor takes a hash function but does not use it, making it
 * a drop-in replacement for HashSet. In theory we could use the hash function
 * for faster de-duplication when taking a union of sets, if that would be
 * helpful.
 */

struct _FolksSmallSetClass {
    /*<private>*/
    GeeAbstractSetClass parent_class;
};

typedef enum {
    /* Iteration has started (we called next() at least once).
     * get() is valid, unless REMOVED is also set. */
    ITER_STARTED = (1 << 0),
    /* The item pointed to has been removed. get() is invalid
     * until the next call to next(). */
    ITER_REMOVED = (1 << 1),
} IterFlags;

struct _FolksSmallSetIterator {
    GObject parent_instance;
    FolksSmallSet *set;
    guint i;
    IterFlags flags;
};

struct _FolksSmallSetIteratorClass {
    GObjectClass parent_class;
};

static void traversable_iface_init (GeeTraversableIface *iface);

G_DEFINE_TYPE_WITH_CODE (FolksSmallSet, folks_small_set,
    GEE_TYPE_ABSTRACT_SET,
    G_IMPLEMENT_INTERFACE (GEE_TYPE_TRAVERSABLE, traversable_iface_init);
    G_IMPLEMENT_INTERFACE (GEE_TYPE_ITERABLE, NULL);
    G_IMPLEMENT_INTERFACE (GEE_TYPE_COLLECTION, NULL);
    G_IMPLEMENT_INTERFACE (GEE_TYPE_SET, NULL))

/*
 * Returns: (transfer none): self[i]
 */
static inline gconstpointer
_get (FolksSmallSet *self,
    guint i)
{
  return g_ptr_array_index (self->items, i);
}

/*
 * Returns: (transfer full): self[i]
 */
static inline gpointer
_dup (FolksSmallSet *self,
    guint i)
{
  if (self->item_dup == NULL)
    return (gpointer) _get (self, i);

  return self->item_dup ((gpointer) _get (self, i));
}

/*
 * @position: (out): i such that item_equals (self[i], item)
 * Returns: %FALSE if there is no such i
 */
static inline gboolean
_find (FolksSmallSet *self,
    gconstpointer item,
    guint *position)
{
  guint i;

  /* If we're a read-only view of something with complicated comparator
   * functions, we need to use that version's comparators, because we
   * can't copy delegates */
  if (self->rw_version != NULL)
    {
      g_assert (self->items == self->rw_version->items);
      self = self->rw_version;
    }

  for (i = 0; i < self->items->len; i++)
    {
      gconstpointer candidate = _get (self, i);
      gboolean equal;

      if (self->item_equals == NULL ||
          self->item_equals == (GeeEqualDataFunc) g_direct_equal)
        equal = (candidate == item);
      else
        equal = self->item_equals (candidate, item, self->item_equals_data);

      if (equal)
        {
          if (position != NULL)
            *position = i;

          return TRUE;
        }
    }

  return FALSE;
}

static void
folks_small_set_configure (FolksSmallSet *self,
    GType item_type,
    GBoxedCopyFunc item_dup,
    GDestroyNotify item_free,
    GeeHashDataFunc item_hash,
    gpointer item_hash_data,
    GDestroyNotify item_hash_data_free,
    GeeEqualDataFunc item_equals,
    gpointer item_equals_data,
    GDestroyNotify item_equals_data_free)
{
  /* We bypass properties because this entire class exists for performance
   * reasons, and it isn't intended to be subclassed or anything. */
  self->item_type = item_type;
  self->item_dup = item_dup;
  self->item_free = item_free;

  if (item_hash == NULL)
    {
      self->item_hash = gee_functions_get_hash_func_for (self->item_type,
          &self->item_hash_data, &self->item_hash_data_free);
    }
  else
    {
      self->item_hash = item_hash;
      self->item_hash_data = item_hash_data;
      self->item_hash_data_free = item_hash_data_free;
    }

  if (item_equals == NULL)
    {
      self->item_equals = gee_functions_get_equal_func_for (self->item_type,
          &self->item_equals_data, &self->item_equals_data_free);
    }
  else
    {
      self->item_equals = item_equals;
      self->item_equals_data = item_equals_data;
      self->item_equals_data_free = item_equals_data_free;
    }
}

/*
 * Returns: (transfer full): a new read-only view
 */
static FolksSmallSet *
_read_only_view (FolksSmallSet *self)
{
  FolksSmallSet *other;

  g_return_val_if_fail (FOLKS_IS_SMALL_SET (self), NULL);

  /* if we're already read-only, we are our own read-only view */
  if (self->flags & FOLKS_SMALL_SET_FLAG_READ_ONLY)
    return g_object_ref (self);

  /* if we're not, make a new one */
  other = g_object_new (FOLKS_TYPE_SMALL_SET,
      NULL);
  other->items = g_ptr_array_ref (self->items);
  other->flags = FOLKS_SMALL_SET_FLAG_READ_ONLY;

  folks_small_set_configure (other, self->item_type, self->item_dup,
      self->item_free, NULL, NULL, NULL, NULL, NULL, NULL);

  if (self->item_hash_data == NULL &&
      self->item_hash_data_free == NULL &&
      self->item_equals_data == NULL &&
      self->item_equals_data_free == NULL)
    {
      /* they're simple enough functions to be copied */
      other->item_hash = self->item_hash;
      other->item_equals = self->item_equals;
    }
  else
    {
      /* we need to use this one's comparator functions */
      other->rw_version = g_object_ref (self);
    }

  /* FIXME: benchmark whether giving self a weak ref to other is a
   * performance win or not */

  return other;
}

/* Covariance? We've heard of it */
#define abstract_set_get_read_only_view \
    ((GeeSet * (*) (GeeAbstractSet *)) _read_only_view)
#define abstract_collection_get_read_only_view \
    ((GeeCollection * (*) (GeeAbstractCollection *)) _read_only_view)

static gint
folks_small_set_get_size (GeeAbstractCollection *collection)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (collection);

  g_return_val_if_fail (self != NULL, 0);
  g_return_val_if_fail (self->items->len <= G_MAXINT, G_MAXINT);

  return (gint) self->items->len;
}

static gboolean
folks_small_set_get_read_only (GeeAbstractCollection *collection)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (collection);

  g_return_val_if_fail (self != NULL, TRUE);

  return ((self->flags & FOLKS_SMALL_SET_FLAG_READ_ONLY) != 0);
}

/*
 * This is deliberately the same signature as HashSet(), even though
 * we don't (currently) use the hashing function.
 *
 * Returns: (transfer full):
 */
FolksSmallSet *
folks_small_set_new (GType item_type,
    GBoxedCopyFunc item_dup,
    GDestroyNotify item_free,
    GeeHashDataFunc item_hash,
    gpointer item_hash_data,
    GDestroyNotify item_hash_data_free,
    GeeEqualDataFunc item_equals,
    gpointer item_equals_data,
    GDestroyNotify item_equals_data_free)
{
  FolksSmallSet *self = g_object_new (FOLKS_TYPE_SMALL_SET,
      NULL);

  /* We bypass properties because this entire class exists for performance
   * reasons, and it isn't intended to be subclassed or anything. */
  folks_small_set_configure (self, item_type, item_dup, item_free,
      item_hash, item_hash_data, item_hash_data_free,
      item_equals, item_equals_data, item_equals_data_free);
  self->items = g_ptr_array_new_full (0, item_free);
  self->flags = 0;

  return self;
}

/*
 * Returns: (transfer full):
 */
FolksSmallSet *
folks_small_set_empty (GType item_type,
    GBoxedCopyFunc item_dup,
    GDestroyNotify item_free)
{
  FolksSmallSet *self = g_object_new (FOLKS_TYPE_SMALL_SET,
      NULL);

  self->items = g_ptr_array_new_full (0, item_free);
  self->item_type = item_type;
  self->flags = FOLKS_SMALL_SET_FLAG_READ_ONLY;

  return self;
}

/*
 * @arr: (transfer container): must have @item_free as its free-function
 * Returns: (transfer full):
 */
FolksSmallSet *
_folks_small_set_new_take_array (GPtrArray *arr,
    GType item_type,
    GBoxedCopyFunc item_dup,
    GDestroyNotify item_free)
{
  FolksSmallSet *self = g_object_new (FOLKS_TYPE_SMALL_SET,
      NULL);

  folks_small_set_configure (self, item_type, item_dup, item_free,
      NULL, NULL, NULL,
      NULL, NULL, NULL);
  self->items = arr;
  self->flags = FOLKS_SMALL_SET_FLAG_READ_ONLY;

  return self;
}

/*
 * Returns: (transfer full):
 */
FolksSmallSet *
folks_small_set_copy (GeeIterable *iterable,
    GeeHashDataFunc item_hash,
    gpointer item_hash_data,
    GDestroyNotify item_hash_data_free,
    GeeEqualDataFunc item_equals,
    gpointer item_equals_data,
    GDestroyNotify item_equals_data_free)
{
  FolksSmallSet *self;
  GeeIterator *iter;
  GeeTraversableIface *traversable_iface;
  GType item_type;
  GBoxedCopyFunc item_dup;
  GDestroyNotify item_free;

  /* Deliberately not allowing for subclasses here: this class is not
   * subclassable, and it's slower if we do check for subclasses. */
  if (G_OBJECT_TYPE (iterable) == FOLKS_TYPE_SMALL_SET)
    {
      /* Fast path: copy the items directly from the other one. */
      FolksSmallSet *other = (FolksSmallSet *) iterable;
      guint i;

      self = g_object_new (FOLKS_TYPE_SMALL_SET,
          NULL);
      folks_small_set_configure (self,
          other->item_type, other->item_dup, other->item_free,
          item_hash, item_hash_data, item_hash_data_free,
          item_equals, item_equals_data, item_equals_data_free);
      self->items = g_ptr_array_new_full (other->items->len,
          other->item_free);
      self->flags = 0;

      for (i = 0; i < other->items->len; i++)
        g_ptr_array_add (self->items, _dup (other, i));

      return self;
    }

  traversable_iface = GEE_TRAVERSABLE_GET_INTERFACE (iterable);
  g_assert (traversable_iface != NULL);
  item_type = traversable_iface->get_g_type ((GeeTraversable *) iterable);
  item_dup = traversable_iface->get_g_dup_func ((GeeTraversable *) iterable);
  item_free = traversable_iface->get_g_destroy_func ((GeeTraversable *) iterable);

  self = folks_small_set_new (item_type, item_dup, item_free,
      item_hash, item_hash_data, item_hash_data_free,
      item_equals, item_equals_data, item_equals_data_free);
  iter = gee_iterable_iterator (iterable);

  if (GEE_IS_SET (iterable))
    {
      /* If it's a set, then we don't need to worry about de-duplicating
       * the items. Just copy them in. */
      while (gee_iterator_next (iter))
        {
          g_ptr_array_add (self->items, gee_iterator_get (iter));
        }
    }
  else
    {
      /* Do it the hard way: there might be duplicates. */
      while (gee_iterator_next (iter))
        {
          gpointer item = gee_iterator_get (iter);

          if (_find (self, item, NULL))
            {
              if (item_free != NULL)
                item_free (item);
            }
          else
            {
              g_ptr_array_add (self->items, item);
            }
        }
    }
  return self;
}

enum {
    PROP_0,
    PROP_G_TYPE,
    PROP_G_DUP_FUNC,
    PROP_G_DESTROY_FUNC,
    N_PROPERTIES
};

static void
folks_small_set_init (FolksSmallSet *self)
{
}

static void
folks_small_set_dispose (GObject *obj)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (obj);

  g_clear_object (&self->rw_version);

  if ((self->flags & FOLKS_SMALL_SET_FLAG_READ_ONLY) == 0)
    g_ptr_array_set_size (self->items, 0);

  ((GObjectClass *) folks_small_set_parent_class)->dispose (obj);
}

static void
folks_small_set_finalize (GObject *obj)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (obj);

  g_ptr_array_unref (self->items);

  if (self->item_hash_data_free != NULL)
    self->item_hash_data_free (self->item_hash_data);

  if (self->item_equals_data_free != NULL)
    self->item_equals_data_free (self->item_equals_data);

  ((GObjectClass *) folks_small_set_parent_class)->finalize (obj);
}

static GType
folks_small_set_get_g_type (GeeTraversable *traversable)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (traversable);

  return self->item_type;
}

static GBoxedCopyFunc
folks_small_set_get_g_dup_func (GeeTraversable *traversable)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (traversable);

  return self->item_dup;
}

static GDestroyNotify
folks_small_set_get_g_destroy_func (GeeTraversable *traversable)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (traversable);

  return self->item_free;
}

/*
 * Call @f for each element, until it returns %FALSE.
 *
 * Overridden because we can do better than allocating a new GObject,
 * which is what Gee would do.
 *
 * Returns: %FALSE if @f returns %FALSE, or %TRUE if we reached the
 *    end of the set.
 */
static gboolean
folks_small_set_foreach (GeeTraversable *traversable,
    GeeForallFunc f,
    gpointer user_data)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (traversable);
  guint i;

  g_return_val_if_fail (self != NULL, FALSE);

  for (i = 0; i < self->items->len; i++)
    {
      /* Yes, GeeForallFunc receives a new copy/ref, astonishing though
       * that may seem to C programmers. */
      if (!f (_dup (self, i), user_data))
        return FALSE;
    }

  return TRUE;
}

static void
traversable_iface_init (GeeTraversableIface *iface)
{
  iface->get_g_type = folks_small_set_get_g_type;
  iface->get_g_dup_func = folks_small_set_get_g_dup_func;
  iface->get_g_destroy_func = folks_small_set_get_g_destroy_func;
  iface->foreach = folks_small_set_foreach;
}

static GeeIterator *
folks_small_set_iterator (GeeAbstractCollection *collection)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (collection);
  FolksSmallSetIterator *iter;

  g_return_val_if_fail (self != NULL, NULL);

  iter = g_object_new (FOLKS_TYPE_SMALL_SET_ITERATOR,
      NULL);

  iter->set = g_object_ref (self);
  iter->flags = 0;
  return (GeeIterator *) iter;
}

static gboolean
folks_small_set_contains (GeeAbstractCollection *collection,
    gconstpointer item)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (collection);

  g_return_val_if_fail (self != NULL, FALSE);

  return _find (self, item, NULL);
}

/*
 * Add @item.
 *
 * Returns: %TRUE if it was not already there.
 */
static gboolean
folks_small_set_add (GeeAbstractCollection *collection,
    gconstpointer item)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (collection);
  gpointer copy;

  g_return_val_if_fail (self != NULL, FALSE);
  g_return_val_if_fail ((self->flags & FOLKS_SMALL_SET_FLAG_READ_ONLY) == 0, FALSE);

  if (_find (self, item, NULL))
    return FALSE;

  if (self->item_dup == NULL)
    copy = (gpointer) item;
  else
    copy = self->item_dup ((gpointer) item);

  g_ptr_array_add (self->items, copy);
  return TRUE;
}

/*
 * Remove @item.
 *
 * Returns: %TRUE if it was previously there.
 */
static gboolean
folks_small_set_remove (GeeAbstractCollection *collection,
    gconstpointer item)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (collection);

  g_return_val_if_fail (self != NULL, FALSE);
  g_return_val_if_fail ((self->flags & FOLKS_SMALL_SET_FLAG_READ_ONLY) == 0, FALSE);

  if (self->item_equals == NULL ||
      self->item_equals == (GeeEqualDataFunc) g_direct_equal)
    {
      if (g_ptr_array_remove_fast (self->items, (gpointer) item))
        return TRUE;
    }
  else
    {
      guint pos;

      if (_find (self, item, &pos))
        {
          g_ptr_array_remove_index_fast (self->items, pos);
          return TRUE;
        }
    }

  return FALSE;
}

/*
 * Remove all items.
 */
static void
folks_small_set_clear (GeeAbstractCollection *collection)
{
  FolksSmallSet *self = FOLKS_SMALL_SET (collection);

  g_return_if_fail (self != NULL);
  g_return_if_fail ((self->flags & FOLKS_SMALL_SET_FLAG_READ_ONLY) == 0);

  g_ptr_array_set_size (self->items, 0);
}

static void
folks_small_set_class_init (FolksSmallSetClass *cls)
{
  GObjectClass *object_class = G_OBJECT_CLASS (cls);
  GeeAbstractSetClass *as_class = GEE_ABSTRACT_SET_CLASS (cls);
  GeeAbstractCollectionClass *ac_class = GEE_ABSTRACT_COLLECTION_CLASS (cls);

  object_class->dispose = folks_small_set_dispose;
  object_class->finalize = folks_small_set_finalize;

  ac_class->contains = folks_small_set_contains;
  ac_class->add = folks_small_set_add;
  ac_class->remove = folks_small_set_remove;
  ac_class->clear = folks_small_set_clear;
  ac_class->iterator = folks_small_set_iterator;
  ac_class->get_size = folks_small_set_get_size;
  ac_class->get_read_only = folks_small_set_get_read_only;
  ac_class->get_read_only_view = abstract_collection_get_read_only_view;

  as_class->get_read_only_view = abstract_set_get_read_only_view;
}

/* ==== The iterator ==== */

static void iterator_iface_init (GeeIteratorIface *iface);
static void iterator_traversable_iface_init (GeeTraversableIface *iface);

G_DEFINE_TYPE_WITH_CODE (FolksSmallSetIterator, folks_small_set_iterator,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE (GEE_TYPE_TRAVERSABLE,
        iterator_traversable_iface_init);
    G_IMPLEMENT_INTERFACE (GEE_TYPE_ITERATOR, iterator_iface_init))

enum {
    ITER_PROP_0,
    ITER_PROP_VALID,
    ITER_PROP_READ_ONLY,
    ITER_PROP_G_TYPE,
    ITER_PROP_G_DUP_FUNC,
    ITER_PROP_G_DESTROY_FUNC,
    N_ITER_PROPERTIES
};

/*
 * Returns: (transfer full): self.get()
 */
static inline gpointer
_iterator_dup (FolksSmallSetIterator *self)
{
  return _dup (self->set, self->i);
}

static inline gboolean
_iterator_flag (FolksSmallSetIterator *self,
    IterFlags flag)
{
  return ((self->flags & flag) != 0);
}

static inline gboolean
_iterator_is_valid (FolksSmallSetIterator *self)
{
  return (_iterator_flag (self, ITER_STARTED) &&
      !_iterator_flag (self, ITER_REMOVED) &&
      self->i < self->set->items->len);
}

static inline gboolean
_iterator_has_next (FolksSmallSetIterator *self)
{
  if (_iterator_flag (self, ITER_STARTED))
    return ((self->i + 1) < self->set->items->len);
  else
    return (self->set->items->len > 0);
}

static void
folks_small_set_iterator_init (FolksSmallSetIterator *self)
{
  self->set = NULL;   /* fixed up by FolksSmallSet */
  self->flags = 0;
  self->i = G_MAXUINT;
}

static void
folks_small_set_iterator_get_property (GObject *obj,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (obj);

  switch (prop_id)
    {
      case ITER_PROP_VALID:
        g_value_set_boolean (value, _iterator_is_valid (self));
        break;

      case ITER_PROP_READ_ONLY:
        g_value_set_boolean (value, ((self->set->flags & FOLKS_SMALL_SET_FLAG_READ_ONLY) != 0));
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (obj, prop_id, pspec);
    }
}

static void
folks_small_set_iterator_set_property (GObject *obj,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec)
{
  switch (prop_id)
    {
      /* ignore useless construct-only property - we always use the set's */
      case ITER_PROP_G_TYPE:
      case ITER_PROP_G_DUP_FUNC:
      case ITER_PROP_G_DESTROY_FUNC:
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (obj, prop_id, pspec);
    }
}

static void
folks_small_set_iterator_finalize (GObject *obj)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (obj);

  g_object_unref (self->set);

  ((GObjectClass *) folks_small_set_iterator_parent_class)->finalize (obj);
}

static void
folks_small_set_iterator_class_init (FolksSmallSetIteratorClass *cls)
{
  GObjectClass *object_class = G_OBJECT_CLASS (cls);

  object_class->get_property = folks_small_set_iterator_get_property;
  object_class->set_property = folks_small_set_iterator_set_property;
  object_class->finalize = folks_small_set_iterator_finalize;

  g_object_class_install_property (object_class, ITER_PROP_VALID,
      g_param_spec_boolean ("valid", "Valid?", "TRUE if get() is valid",
        FALSE, G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  g_object_class_install_property (object_class, ITER_PROP_READ_ONLY,
      g_param_spec_boolean ("read-only", "Read-only?", "TRUE if read-only",
        FALSE, G_PARAM_STATIC_STRINGS | G_PARAM_READABLE));

  g_object_class_install_property (object_class, ITER_PROP_G_TYPE,
      g_param_spec_gtype ("g-type", "Item type", "GType of items", G_TYPE_NONE,
        G_PARAM_STATIC_STRINGS | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  g_object_class_install_property (object_class, ITER_PROP_G_DUP_FUNC,
      g_param_spec_pointer ("g-dup-func", "Item copy function",
            "Copies or refs an item",
        G_PARAM_STATIC_STRINGS | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  g_object_class_install_property (object_class, ITER_PROP_G_DESTROY_FUNC,
      g_param_spec_pointer ("g-destroy-func", "Item free function",
            "Frees or unrefs item",
        G_PARAM_STATIC_STRINGS | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));
}

/* ---- ... as Traversable ---- */

static gboolean
folks_small_set_iterator_foreach (GeeTraversable *traversable,
    GeeForallFunc f,
    gpointer user_data)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (traversable);

  g_return_val_if_fail (self != NULL, FALSE);
  g_return_val_if_fail (self->set != NULL, FALSE);

  if (!_iterator_flag (self, ITER_STARTED))
    {
      self->flags = ITER_STARTED;
      /* we will wrap around to 0 when we advance (ISO C guarantees that
       * unsigned arithmetic wraps around) */
      self->i = G_MAXUINT;
    }
  else if (!_iterator_flag (self, ITER_REMOVED))
    {
      /* Look at the current item before we advance.
       * Yes, GeeForallFunc receives a new copy/ref. */
      if (!f (_iterator_dup (self), user_data))
        return FALSE;
    }

  for (self->i++; self->i < self->set->items->len; self->i++)
    {
      /* back onto track, even if an item was removed */
      self->flags &= ~ITER_REMOVED;

      /* Yes, GeeForallFunc receives a new copy/ref. */
      if (!f (_iterator_dup (self), user_data))
        return FALSE;
    }

  return TRUE;
}

static GType
folks_small_set_iterator_get_g_type (GeeTraversable *traversable)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (traversable);

  g_return_val_if_fail (self != NULL, G_TYPE_INVALID);

  return self->set->item_type;
}

static GBoxedCopyFunc
folks_small_set_iterator_get_g_dup_func (GeeTraversable *traversable)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (traversable);

  g_return_val_if_fail (self != NULL, NULL);

  return self->set->item_dup;
}

static GDestroyNotify
folks_small_set_iterator_get_g_destroy_func (GeeTraversable *traversable)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (traversable);

  g_return_val_if_fail (self != NULL, NULL);

  return self->set->item_free;
}

static void
iterator_traversable_iface_init (GeeTraversableIface *iface)
{
  iface->foreach = folks_small_set_iterator_foreach;
  iface->get_g_type = folks_small_set_iterator_get_g_type;
  iface->get_g_dup_func = folks_small_set_iterator_get_g_dup_func;
  iface->get_g_destroy_func = folks_small_set_iterator_get_g_destroy_func;
}

/* ---- ... as Iterator ---- */

static gboolean
folks_small_set_iterator_next (GeeIterator *iter)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (iter);

  g_return_val_if_fail (self != NULL, FALSE);

  if (!_iterator_has_next (self))
    {
      return FALSE;
    }
  if (_iterator_flag (self, ITER_STARTED))
    {
      /* back onto track, even if an item was removed */
      self->flags &= ~ITER_REMOVED;
      self->i++;
    }
  else
    {
      self->flags = ITER_STARTED;
      self->i = 0;
    }

  g_assert (_iterator_is_valid (self));
  return TRUE;
}

static gboolean
folks_small_set_iterator_has_next (GeeIterator *iter)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (iter);

  g_return_val_if_fail (self != NULL, FALSE);
  return _iterator_has_next (self);
}

static gpointer
folks_small_set_iterator_get (GeeIterator *iter)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (iter);

  g_return_val_if_fail (self != NULL, NULL);
  g_return_val_if_fail (_iterator_flag (self, ITER_STARTED), NULL);
  g_return_val_if_fail (!_iterator_flag (self, ITER_REMOVED), NULL);

  return _iterator_dup (self);
}

static void
folks_small_set_iterator_remove (GeeIterator *iter)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (iter);

  g_return_if_fail (self != NULL);
  g_return_if_fail ((self->set->flags & FOLKS_SMALL_SET_FLAG_READ_ONLY) == 0);
  g_return_if_fail (_iterator_flag (self, ITER_STARTED));
  g_return_if_fail (!_iterator_flag (self, ITER_REMOVED));

  /* Suppose self->i == 5, i.e. we are pointing at pdata[5] in a list
   * of length 10. */

  /* Move pdata[9] to overwrite pdata[5] */
  g_ptr_array_remove_index_fast (self->set->items, self->i);

  /* Next time we advance the iterator, we want it to move to pdata[5];
   * so we need to move back one. i is unsigned, so it's OK if it underflows
   * to all-ones - ISO C guarantees that unsigned arithmetic wraps around. */
  self->i--;

  /* We're not allowed to get() until we're back on track, though. */
  self->flags |= ITER_REMOVED;
}

static gboolean
folks_small_set_iterator_get_valid (GeeIterator *iter)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (iter);

  g_return_val_if_fail (self != NULL, FALSE);

  return _iterator_is_valid (self);
}

static gboolean
folks_small_set_iterator_get_read_only (GeeIterator *iter)
{
  FolksSmallSetIterator *self = FOLKS_SMALL_SET_ITERATOR (iter);

  g_return_val_if_fail (self != NULL, TRUE);

  return ((self->set->flags & FOLKS_SMALL_SET_FLAG_READ_ONLY) != 0);
}

/* unfold, concat are inherited */

static void
iterator_iface_init (GeeIteratorIface *iface)
{
  iface->next = folks_small_set_iterator_next;
  iface->has_next = folks_small_set_iterator_has_next;
  iface->get = folks_small_set_iterator_get;
  iface->remove = folks_small_set_iterator_remove;
  iface->get_valid = folks_small_set_iterator_get_valid;
  iface->get_read_only = folks_small_set_iterator_get_read_only;
}
