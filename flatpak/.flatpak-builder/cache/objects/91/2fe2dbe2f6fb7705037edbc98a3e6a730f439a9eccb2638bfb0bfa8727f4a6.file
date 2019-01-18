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

#include "e-list-iterator.h"
#include "e-list.h"

static void        e_list_iterator_invalidate (EIterator *iterator);
static gboolean    e_list_iterator_is_valid   (EIterator *iterator);
static void        e_list_iterator_set        (EIterator  *iterator,
					       gconstpointer object);
static void        e_list_iterator_remove     (EIterator  *iterator);
static void        e_list_iterator_insert     (EIterator  *iterator,
					       gconstpointer object,
					       gboolean    before);
static gboolean    e_list_iterator_prev       (EIterator  *iterator);
static gboolean    e_list_iterator_next       (EIterator  *iterator);
static void        e_list_iterator_reset      (EIterator *iterator);
static void        e_list_iterator_last       (EIterator *iterator);
static gconstpointer e_list_iterator_get        (EIterator *iterator);
static void        e_list_iterator_dispose    (GObject *object);

G_DEFINE_TYPE (EListIterator, e_list_iterator, E_TYPE_ITERATOR)

static void
e_list_iterator_class_init (EListIteratorClass *class)
{
	GObjectClass *object_class;
	EIteratorClass *iterator_class;

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = e_list_iterator_dispose;

	iterator_class = E_ITERATOR_CLASS (class);
	iterator_class->invalidate = e_list_iterator_invalidate;
	iterator_class->get = e_list_iterator_get;
	iterator_class->reset = e_list_iterator_reset;
	iterator_class->last = e_list_iterator_last;
	iterator_class->next = e_list_iterator_next;
	iterator_class->prev = e_list_iterator_prev;
	iterator_class->remove = e_list_iterator_remove;
	iterator_class->insert = e_list_iterator_insert;
	iterator_class->set = e_list_iterator_set;
	iterator_class->is_valid = e_list_iterator_is_valid;
}

/**
 * e_list_iterator_init:
 */
static void
e_list_iterator_init (EListIterator *list)
{
}

EIterator *
e_list_iterator_new (EList *list)
{
	EListIterator *iterator = NULL;

	g_return_val_if_fail (list != NULL, NULL);
	g_return_val_if_fail (E_IS_LIST (list), NULL);

	iterator = g_object_new (E_TYPE_LIST_ITERATOR, NULL);
	if (!iterator)
		return NULL;
	iterator->list = list;
	g_object_ref (list);
	iterator->iterator = list->list;

	return E_ITERATOR (iterator);
}

/*
 * Virtual functions:
 */
static void
e_list_iterator_dispose (GObject *object)
{
	EListIterator *iterator = E_LIST_ITERATOR (object);
	e_list_remove_iterator (iterator->list, E_ITERATOR (iterator));
	g_object_unref (iterator->list);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_list_iterator_parent_class)->dispose (object);
}

static gconstpointer
e_list_iterator_get (EIterator *_iterator)
{
	EListIterator *iterator = E_LIST_ITERATOR (_iterator);
	if (iterator->iterator)
		return iterator->iterator->data;
	else
		return NULL;
}

static void
e_list_iterator_reset (EIterator *_iterator)
{
	EListIterator *iterator = E_LIST_ITERATOR (_iterator);
	iterator->iterator = iterator->list->list;
}

static void
e_list_iterator_last (EIterator *_iterator)
{
	EListIterator *iterator = E_LIST_ITERATOR (_iterator);
	iterator->iterator = g_list_last (iterator->list->list);
}

static gboolean
e_list_iterator_next (EIterator *_iterator)
{
	EListIterator *iterator = E_LIST_ITERATOR (_iterator);
	if (iterator->iterator)
		iterator->iterator = g_list_next (iterator->iterator);
	else
		iterator->iterator = iterator->list->list;
	return (iterator->iterator != NULL);
}

static gboolean
e_list_iterator_prev (EIterator *_iterator)
{
	EListIterator *iterator = E_LIST_ITERATOR (_iterator);
	if (iterator->iterator)
		iterator->iterator = g_list_previous (iterator->iterator);
	else
		iterator->iterator = g_list_last (iterator->list->list);
	return (iterator->iterator != NULL);
}

static void
e_list_iterator_insert (EIterator *_iterator,
                        gconstpointer object,
                        gboolean before)
{
	EListIterator *iterator = E_LIST_ITERATOR (_iterator);
	gpointer data;
	if (iterator->list->copy)
		data = iterator->list->copy (object, iterator->list->closure);
	else
		data = (gpointer) object;
	if (iterator->iterator) {
		if (before) {
			iterator->list->list = g_list_first (g_list_prepend (iterator->iterator, data));
			iterator->iterator = iterator->iterator->prev;
		} else {
			if (iterator->iterator->next)
				iterator->iterator->next = g_list_prepend (iterator->iterator->next, data);
			else
				iterator->iterator = g_list_append (iterator->iterator, data);
			iterator->iterator = iterator->iterator->next;
		}
		e_list_invalidate_iterators (iterator->list, E_ITERATOR (iterator));
	} else {
		if (before) {
			iterator->list->list = g_list_append (iterator->list->list, data);
			iterator->iterator = g_list_last (iterator->list->list);
		} else {
			iterator->list->list = g_list_prepend (iterator->list->list, data);
			iterator->iterator = iterator->list->list;
		}
		e_list_invalidate_iterators (iterator->list, E_ITERATOR (iterator));
	}
}

static void
e_list_iterator_remove (EIterator *_iterator)
{
	EListIterator *iterator = E_LIST_ITERATOR (_iterator);
	if (iterator->iterator) {
		e_list_remove_link (iterator->list, iterator->iterator);
	}
}

static void
e_list_iterator_set (EIterator *_iterator,
                     gconstpointer object)
{
	EListIterator *iterator = E_LIST_ITERATOR (_iterator);
	if (iterator->iterator) {
		if (iterator->list->free)
			iterator->list->free (iterator->iterator->data, iterator->list->closure);
		if (iterator->list->copy)
			iterator->iterator->data = iterator->list->copy (object, iterator->list->closure);
		else
			iterator->iterator->data = (gpointer) object;
	}
}

static gboolean
e_list_iterator_is_valid (EIterator *_iterator)
{
	EListIterator *iterator = E_LIST_ITERATOR (_iterator);
	return iterator->iterator != NULL;
}

static void
e_list_iterator_invalidate (EIterator *_iterator)
{
	EListIterator *iterator = E_LIST_ITERATOR (_iterator);
	iterator->iterator = NULL;
}
