/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2008 Novell, Inc.
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#include "camel-object-bag.h"

#include <glib-object.h>

typedef struct _KeyReservation KeyReservation;

struct _KeyReservation {
	gpointer key;
	gint waiters;
	GThread *owner;
	GCond cond;
};

struct _CamelObjectBag {
	GHashTable *key_table;
	GHashTable *object_table;
	GEqualFunc key_equal_func;
	CamelCopyFunc key_copy_func;
	GFreeFunc key_free_func;
	GList *reserved;  /* list of KeyReservations */
	GMutex mutex;
};

static KeyReservation *
key_reservation_new (CamelObjectBag *bag,
                     gconstpointer key)
{
	KeyReservation *reservation;

	reservation = g_slice_new0 (KeyReservation);
	reservation->key = bag->key_copy_func (key);
	reservation->owner = g_thread_self ();
	g_cond_init (&reservation->cond);

	bag->reserved = g_list_prepend (bag->reserved, reservation);

	return reservation;
}

static KeyReservation *
key_reservation_lookup (CamelObjectBag *bag,
                        gconstpointer key)
{
	GList *iter;

	/* XXX Might be easier to use a GHashTable for reservations. */
	for (iter = bag->reserved; iter != NULL; iter = iter->next) {
		KeyReservation *reservation = iter->data;
		if (bag->key_equal_func (reservation->key, key))
			return reservation;
	}

	return NULL;
}

static void
key_reservation_free (CamelObjectBag *bag,
                      KeyReservation *reservation)
{
	/* Make sure the reservation is actually in the object bag. */
	g_return_if_fail (key_reservation_lookup (bag, reservation->key) != NULL);

	bag->reserved = g_list_remove (bag->reserved, reservation);

	bag->key_free_func (reservation->key);
	g_cond_clear (&reservation->cond);
	g_slice_free (KeyReservation, reservation);
}

static void
object_bag_unreserve (CamelObjectBag *bag,
                      gconstpointer key)
{
	KeyReservation *reservation;

	reservation = key_reservation_lookup (bag, key);
	g_return_if_fail (reservation != NULL);
	g_return_if_fail (reservation->owner == g_thread_self ());

	if (reservation->waiters > 0) {
		reservation->owner = NULL;
		g_cond_signal (&reservation->cond);
	} else
		key_reservation_free (bag, reservation);
}

/* Ick. We need to store the original gobject pointer too, since that's
 * used as the key in one of the hash tables. So to clean up after the
 * object dies and the GWeakRef starts returning NULL, we'll need to
 * know where it *was*. This is safe because we'll always check and
 * avoid adding a duplicate. But still, ick. */
typedef struct {
	GWeakRef ref;
	gpointer obj;
	CamelObjectBag *bag;
} ObjRef;

static void
object_bag_notify (CamelObjectBag *bag,
                   GObject *where_the_object_was)
{
	gconstpointer key;

	g_mutex_lock (&bag->mutex);

	key = g_hash_table_lookup (bag->key_table, where_the_object_was);
	if (key != NULL) {
		g_hash_table_remove (bag->key_table, where_the_object_was);
		g_hash_table_remove (bag->object_table, key);
	}

	g_mutex_unlock (&bag->mutex);
}

/* Properly destroy an ObjRef as it's freed from the hash table */
static void
wref_free_func (gpointer p)
{
	ObjRef *ref = p;
	GObject *obj = g_weak_ref_get (&ref->ref);

	if (obj) {
		/* The object is being removed from the bag while it's
		 * still alive, e.g. by camel_object_bag_remove()
		 * or camel_object_bag_destroy(). Drop the weak_ref. */
		g_object_weak_unref (
			obj, (GWeakNotify) object_bag_notify,
			ref->bag);
		g_object_unref (obj);
	}
	g_weak_ref_clear (&ref->ref);
	g_slice_free (ObjRef, ref);
}

/**
 * camel_object_bag_new: (skip)
 * @key_hash_func: (scope call): a hashing function for keys
 * @key_equal_func: (scope call): a comparison function for keys
 * @key_copy_func: (scope call): a function to copy keys
 * @key_free_func: (scope call): a function to free keys
 *
 * Returns a new object bag.  Object bags are keyed hash tables of objects
 * that can be updated atomically using transaction semantics.  Use
 * camel_object_bag_destroy() to free the object bag.
 *
 * Returns: a newly-allocated #CamelObjectBag
 **/
CamelObjectBag *
camel_object_bag_new (GHashFunc key_hash_func,
                      GEqualFunc key_equal_func,
                      CamelCopyFunc key_copy_func,
                      GFreeFunc key_free_func)
{
	CamelObjectBag *bag;
	GHashTable *key_table;
	GHashTable *object_table;

	g_return_val_if_fail (key_hash_func != NULL, NULL);
	g_return_val_if_fail (key_equal_func != NULL, NULL);
	g_return_val_if_fail (key_copy_func != NULL, NULL);
	g_return_val_if_fail (key_free_func != NULL, NULL);

	/* Each key is shared between both hash tables, so only one
	 * table needs to be responsible for destroying keys. */

	key_table = g_hash_table_new (g_direct_hash, g_direct_equal);

	object_table = g_hash_table_new_full (
		key_hash_func, key_equal_func,
		(GDestroyNotify) key_free_func,
		(GDestroyNotify) wref_free_func);

	bag = g_slice_new0 (CamelObjectBag);
	bag->key_table = key_table;
	bag->object_table = object_table;
	bag->key_equal_func = key_equal_func;
	bag->key_copy_func = key_copy_func;
	bag->key_free_func = key_free_func;
	g_mutex_init (&bag->mutex);

	return bag;
}

/**
 * camel_object_bag_get:
 * @bag: a #CamelObjectBag
 * @key: a key
 *
 * Lookup an object by @key.  If the key is currently reserved, the function
 * will block until another thread commits or aborts the reservation.  The
 * caller owns the reference to the returned object.  Use g_object_unref ()
 * to unreference it.
 *
 * Returns: (transfer full) (nullable): the object corresponding to @key, or
 * %NULL if not found
 **/
gpointer
camel_object_bag_get (CamelObjectBag *bag,
                      gconstpointer key)
{
	KeyReservation *reservation;
	ObjRef *ref;
	gpointer object = NULL;

	g_return_val_if_fail (bag != NULL, NULL);
	g_return_val_if_fail (key != NULL, NULL);

	g_mutex_lock (&bag->mutex);

	/* Look for the key in the bag. */
	ref = g_hash_table_lookup (bag->object_table, key);
	if (ref != NULL) {
		object = g_weak_ref_get (&ref->ref);
		if (object != NULL) {
			g_mutex_unlock (&bag->mutex);
			return object;
		}

		/* Remove stale reference to dead object. */
		g_hash_table_remove (bag->key_table, ref->obj);
		g_hash_table_remove (bag->object_table, key);
	}

	/* Check if the key has been reserved. */
	reservation = key_reservation_lookup (bag, key);
	if (reservation == NULL) {
		/* No such key, so return NULL. */
		g_mutex_unlock (&bag->mutex);
		return NULL;
	}

	/* Wait for the key to be unreserved. */
	reservation->waiters++;
	while (reservation->owner != NULL)
		g_cond_wait (&reservation->cond, &bag->mutex);
	reservation->waiters--;

	/* Check if an object was added by another thread. */
	ref = g_hash_table_lookup (bag->object_table, key);
	if (ref != NULL) {
		object = g_weak_ref_get (&ref->ref);
		if (object == NULL) {
			/* Remove stale reference to dead object. */
			g_hash_table_remove (bag->key_table, ref->obj);
			g_hash_table_remove (bag->object_table, key);
		}
	}

	/* We're not reserving it. */
	reservation->owner = g_thread_self ();
	object_bag_unreserve (bag, key);

	g_mutex_unlock (&bag->mutex);

	return object;
}

/**
 * camel_object_bag_peek:
 * @bag: a #CamelObjectBag
 * @key: an unreserved key
 *
 * Returns the object for @key in @bag, ignoring any reservations.  If it
 * isn't committed, then it isn't considered.  This should only be used
 * where reliable transactional-based state is not required.
 *
 * Unlink other "peek" operations, the caller owns the returned object
 * reference.  Use g_object_unref () to unreference it.
 *
 * Returns: (transfer full) (nullable): the object for @key, or %NULL if @key
 * is reserved or not found
 **/
gpointer
camel_object_bag_peek (CamelObjectBag *bag,
                       gconstpointer key)
{
	gpointer object = NULL;
	ObjRef *ref;

	g_return_val_if_fail (bag != NULL, NULL);
	g_return_val_if_fail (key != NULL, NULL);

	g_mutex_lock (&bag->mutex);

	ref = g_hash_table_lookup (bag->object_table, key);
	if (ref != NULL)
		object = g_weak_ref_get (&ref->ref);

	g_mutex_unlock (&bag->mutex);

	return object;
}

/**
 * camel_object_bag_reserve:
 * @bag: a #CamelObjectBag
 * @key: the key to reserve
 *
 * Reserves @key in @bag.  If @key is already reserved in another thread,
 * then wait until the reservation has been committed.
 *
 * After reserving @key, you either get a reference to the object
 * corresponding to @key (similar to camel_object_bag_get()) or you get
 * %NULL, signifying that you MUST call either camel_object_bag_add() or
 * camel_object_bag_abort().
 *
 * Returns: (transfer full) (nullable): the object for @key, or %NULL if @key
 * is not found
 **/
gpointer
camel_object_bag_reserve (CamelObjectBag *bag,
                          gconstpointer key)
{
	KeyReservation *reservation;
	ObjRef *ref;
	gpointer object = NULL;

	g_return_val_if_fail (bag != NULL, NULL);
	g_return_val_if_fail (key != NULL, NULL);

	g_mutex_lock (&bag->mutex);

	/* If object for key already exists, return it immediately. */
	ref = g_hash_table_lookup (bag->object_table, key);
	if (ref != NULL) {
		object = g_weak_ref_get (&ref->ref);
		if (object != NULL) {
			g_mutex_unlock (&bag->mutex);
			return object;
		}

		/* Remove stale reference to dead object. */
		g_hash_table_remove (bag->key_table, ref->obj);
		g_hash_table_remove (bag->object_table, key);
	}

	/* If no such key exists in the bag, create a reservation. */
	reservation = key_reservation_lookup (bag, key);
	if (reservation == NULL) {
		key_reservation_new (bag, key);
		g_mutex_unlock (&bag->mutex);
		return NULL;
	}

	/* Wait for the reservation to be committed or aborted. */
	reservation->waiters++;
	while (reservation->owner != NULL)
		g_cond_wait (&reservation->cond, &bag->mutex);
	reservation->owner = g_thread_self ();
	reservation->waiters--;

	/* Check if the object was added by another thread. */
	ref = g_hash_table_lookup (bag->object_table, key);
	if (ref != NULL) {
		object = g_weak_ref_get (&ref->ref);
		if (object != NULL) {
			/* We have an object; no need to reserve the key. */
			object_bag_unreserve (bag, key);
		} else {
			/* Remove stale reference to dead object. */
			g_hash_table_remove (bag->key_table, ref->obj);
			g_hash_table_remove (bag->object_table, key);
		}
	}

	g_mutex_unlock (&bag->mutex);

	return object;
}

static gboolean
object_in_bag (CamelObjectBag *bag,
               gpointer object)
{
	gconstpointer key;
	ObjRef *ref;
	GObject *obj2;

	key = g_hash_table_lookup (bag->key_table, object);
	if (key == NULL)
		return FALSE;

	ref = g_hash_table_lookup (bag->object_table, key);
	if (ref == NULL)
		return FALSE;

	obj2 = g_weak_ref_get (&ref->ref);
	if (obj2 == NULL) {
		/* Remove stale reference to dead object. */
		g_hash_table_remove (bag->key_table, object);
		g_hash_table_remove (bag->object_table, key);
	} else {
		g_object_unref (obj2);
	}

	return obj2 == object;
}

/**
 * camel_object_bag_add:
 * @bag: a #CamelObjectBag
 * @key: a reserved key
 * @object: a #GObject
 *
 * Adds @object to @bag.  The @key MUST have been previously reserved using
 * camel_object_bag_reserve().
 **/
void
camel_object_bag_add (CamelObjectBag *bag,
                      gconstpointer key,
                      gpointer object)
{
	g_return_if_fail (bag != NULL);
	g_return_if_fail (key != NULL);
	g_return_if_fail (G_IS_OBJECT (object));

	g_mutex_lock (&bag->mutex);

	/* Check it's the *same* object, not an old one at the same address */
	if (!object_in_bag (bag, object)) {
		ObjRef *ref;
		gpointer copied_key;

		ref = g_slice_new (ObjRef);
		ref->bag = bag;
		/* We need to stash a 'raw' pointer since that's the key we use
		 * in the key_table */
		ref->obj = object;
		g_weak_ref_init (&ref->ref, object);
		copied_key = bag->key_copy_func (key);
		g_hash_table_insert (bag->key_table, object, copied_key);
		g_hash_table_insert (bag->object_table, copied_key, ref);
		object_bag_unreserve (bag, key);

		g_object_weak_ref (
			G_OBJECT (object),
			(GWeakNotify) object_bag_notify, bag);
	}

	g_mutex_unlock (&bag->mutex);
}

/**
 * camel_object_bag_abort:
 * @bag: a #CamelObjectBag
 * @key: a reserved key
 *
 * Aborts a key reservation.
 **/
void
camel_object_bag_abort (CamelObjectBag *bag,
                        gconstpointer key)
{
	g_return_if_fail (bag != NULL);
	g_return_if_fail (key != NULL);

	g_mutex_lock (&bag->mutex);

	object_bag_unreserve (bag, key);

	g_mutex_unlock (&bag->mutex);
}

/**
 * camel_object_bag_rekey:
 * @bag: a #CamelObjectBag
 * @object: a #GObject
 * @new_key: a new key for @object
 *
 * Changes the key for @object to @new_key, atomically.
 *
 * It is considered a programming error if @object is not found in @bag.
 * In such case the function will emit a terminal warning and return.
 **/
void
camel_object_bag_rekey (CamelObjectBag *bag,
                        gpointer object,
                        gconstpointer new_key)
{
	gpointer key;
	ObjRef *ref;

	g_return_if_fail (bag != NULL);
	g_return_if_fail (G_IS_OBJECT (object));
	g_return_if_fail (new_key != NULL);

	g_mutex_lock (&bag->mutex);

	key = g_hash_table_lookup (bag->key_table, object);
	if (key != NULL) {
		/* Remove the old key. */
		ref = g_hash_table_lookup (bag->object_table, key);
		g_hash_table_steal (bag->object_table, key);
		g_hash_table_remove (bag->key_table, object);

		/* Insert the new key. */
		key = bag->key_copy_func (new_key);
		g_hash_table_insert (bag->object_table, key, ref);
		g_hash_table_insert (bag->key_table, object, key);
	} else
		g_warn_if_reached ();

	g_mutex_unlock (&bag->mutex);
}

/**
 * camel_object_bag_list:
 * @bag: a #CamelObjectBag
 *
 * Returns a #GPtrArray of all the objects in the bag.  The caller owns
 * both the array and the object references, so to free the array use:
 *
 * |[
 *     g_ptr_array_foreach (array, (GFunc) g_object_unref, NULL);
 *     g_ptr_array_free (array, TRUE);
 * ]|
 *
 * Returns: (element-type GObject) (transfer full): an array of objects in @bag
 **/
GPtrArray *
camel_object_bag_list (CamelObjectBag *bag)
{
	GPtrArray *array;
	GList *values;

	g_return_val_if_fail (bag != NULL, NULL);

	/* XXX Too bad we're not returning a GList; this would be trivial. */

	array = g_ptr_array_new ();

	g_mutex_lock (&bag->mutex);

	values = g_hash_table_get_values (bag->object_table);
	while (values != NULL) {
		ObjRef *ref = values->data;
		GObject *obj = g_weak_ref_get (&ref->ref);
		if (obj)
			g_ptr_array_add (array, obj);
		values = g_list_delete_link (values, values);
	}

	g_mutex_unlock (&bag->mutex);

	return array;
}

/**
 * camel_object_bag_remove:
 * @bag: a #CamelObjectBag
 * @object: a #GObject
 *
 * Removes @object from @bag.
 **/
void
camel_object_bag_remove (CamelObjectBag *bag,
                         gpointer object)
{
	gpointer key;

	g_return_if_fail (bag != NULL);
	g_return_if_fail (G_IS_OBJECT (object));

	g_mutex_lock (&bag->mutex);

	key = g_hash_table_lookup (bag->key_table, object);
	if (key != NULL) {
		g_hash_table_remove (bag->key_table, object);
		g_hash_table_remove (bag->object_table, key);
	}

	g_mutex_unlock (&bag->mutex);
}

/**
 * camel_object_bag_destroy:
 * @bag: a #CamelObjectBag
 *
 * Frees @bag.  As a precaution, the function will emit a warning to standard
 * error and return without freeing @bag if @bag still has reserved keys.
 **/
void
camel_object_bag_destroy (CamelObjectBag *bag)
{
	g_return_if_fail (bag != NULL);
	g_return_if_fail (bag->reserved == NULL);

	g_hash_table_destroy (bag->key_table);
	g_hash_table_destroy (bag->object_table);
	g_mutex_clear (&bag->mutex);
	g_slice_free (CamelObjectBag, bag);
}
