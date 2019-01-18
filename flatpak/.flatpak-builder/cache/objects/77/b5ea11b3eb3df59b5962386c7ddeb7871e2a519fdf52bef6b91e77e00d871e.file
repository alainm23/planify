/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Christopher James Lahey <clahey@umich.edu>
 */

#include "evolution-data-server-config.h"

#include "e-iterator.h"

enum {
	INVALIDATE,
	LAST_SIGNAL
};

static guint e_iterator_signals[LAST_SIGNAL] = { 0, };

G_DEFINE_TYPE (EIterator, e_iterator, G_TYPE_OBJECT)

static void
e_iterator_class_init (EIteratorClass *class)
{
	GObjectClass *object_class;

	object_class = G_OBJECT_CLASS (class);

	e_iterator_signals[INVALIDATE] = g_signal_new (
		"invalidate",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EIteratorClass, invalidate),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);
}

static void
e_iterator_init (EIterator *card)
{
}

/*
 * Virtual functions:
 *
 */

/**
 * e_iterator_get:
 * @iterator: an #EIterator
 *
 * Returns: (transfer none): the iterator value
 **/
gconstpointer
e_iterator_get (EIterator *iterator)
{
	if (E_ITERATOR_GET_CLASS (iterator)->get)
		return E_ITERATOR_GET_CLASS (iterator)->get (iterator);
	else
		return NULL;
}

/**
 * e_iterator_reset:
 * @iterator: an #EIterator
 *
 * Resets the iterator to the beginning.
 **/
void
e_iterator_reset (EIterator *iterator)
{
	if (E_ITERATOR_GET_CLASS (iterator)->reset)
		E_ITERATOR_GET_CLASS (iterator)->reset (iterator);
}

/**
 * e_iterator_last:
 * @iterator: an #EIterator
 *
 * Moves the iterator to the last item.
 **/
void
e_iterator_last (EIterator *iterator)
{
	if (E_ITERATOR_GET_CLASS (iterator)->last)
		E_ITERATOR_GET_CLASS (iterator)->last (iterator);
}

/**
 * e_iterator_next:
 * @iterator: an #EIterator
 *
 * Moves the iterator to the next item.
 *
 * Returns: Whether succeeded
 **/
gboolean
e_iterator_next (EIterator *iterator)
{
	if (E_ITERATOR_GET_CLASS (iterator)->next)
		return E_ITERATOR_GET_CLASS (iterator)->next (iterator);
	else
		return FALSE;
}

/**
 * e_iterator_prev:
 * @iterator: an #EIterator
 *
 * Moves the iterator to the previous item.
 *
 * Returns: Whether succeeded
 **/
gboolean
e_iterator_prev (EIterator *iterator)
{
	if (E_ITERATOR_GET_CLASS (iterator)->prev)
		return E_ITERATOR_GET_CLASS (iterator)->prev (iterator);
	else
		return FALSE;
}

/**
 * e_iterator_delete:
 * @iterator: an #EIterator
 *
 * Deletes the item in the current position of the iterator.
 **/
void
e_iterator_delete (EIterator *iterator)
{
	if (E_ITERATOR_GET_CLASS (iterator)->remove)
		E_ITERATOR_GET_CLASS (iterator)->remove (iterator);
}

/**
 * e_iterator_insert:
 * @iterator: an #EIterator
 * @object: an object to insert
 * @before: where to insert the object
 *
 * Inserts the @object before or after the current position of the iterator.
 **/
void
e_iterator_insert (EIterator *iterator,
                   gconstpointer object,
                   gboolean before)
{
	if (E_ITERATOR_GET_CLASS (iterator)->insert)
		E_ITERATOR_GET_CLASS (iterator)->insert (iterator, object, before);
}

/**
 * e_iterator_set:
 * @iterator: an #EIterator
 * @object: an object to set
 *
 * Sets value of the current position of the iterator to the @object.
 **/
void
e_iterator_set (EIterator *iterator,
                gconstpointer object)
{
	if (E_ITERATOR_GET_CLASS (iterator)->set)
		E_ITERATOR_GET_CLASS (iterator)->set (iterator, object);
}

/**
 * e_iterator_is_valid:
 * @iterator: an #EIterator
 *
 * Returns: whether the iterator is valid.
 **/
gboolean
e_iterator_is_valid (EIterator *iterator)
{
	if (!iterator)
		return FALSE;

	if (E_ITERATOR_GET_CLASS (iterator)->is_valid)
		return E_ITERATOR_GET_CLASS (iterator)->is_valid (iterator);
	else
		return FALSE;
}

/**
 * e_iterator_invalidate:
 * @iterator: an #EIterator
 *
 * Invalidates the iterator.
 **/
void
e_iterator_invalidate (EIterator *iterator)
{
	g_return_if_fail (iterator != NULL);
	g_return_if_fail (E_IS_ITERATOR (iterator));

	g_signal_emit (iterator, e_iterator_signals[INVALIDATE], 0);
}
