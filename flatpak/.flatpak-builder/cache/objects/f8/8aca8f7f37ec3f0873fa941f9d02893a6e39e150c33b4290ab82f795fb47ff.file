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

#include "e-list.h"
#include "e-list-iterator.h"

G_DEFINE_TYPE (EList, e_list, G_TYPE_OBJECT)

static void
list_dispose (GObject *object)
{
	EList *list = E_LIST (object);

	if (list->free)
		g_list_foreach (list->list, (GFunc) list->free, list->closure);
	g_list_free (list->list);
	list->list = NULL;

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_list_parent_class)->dispose (object);
}

static void
e_list_class_init (EListClass *class)
{
	GObjectClass *object_class;

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = list_dispose;
}

/**
 * e_list_init:
 */
static void
e_list_init (EList *list)
{
}

/**
 * e_list_new:
 * @copy: (scope call): the copy func
 * @free: (scope call): the free func
 * @closure: user data
 *
 * Returns: (transfer full): The new #EList.
 **/
EList *
e_list_new (EListCopyFunc copy,
            EListFreeFunc free,
            gpointer closure)
{
	EList *list = g_object_new (E_TYPE_LIST, NULL);
	e_list_construct (list, copy, free, closure);
	return list;
}

/**
 * e_list_construct:
 * @list: The #EList.
 * @copy: (scope call): the copy func
 * @free: (scope call): the free func
 * @closure: user data
 *
 **/
void
e_list_construct (EList *list,
                  EListCopyFunc copy,
                  EListFreeFunc free,
                  gpointer closure)
{
	list->copy = copy;
	list->free = free;
	list->closure = closure;
}

/**
 * e_list_duplicate:
 * @list: The #EList object.
 *
 * Returns: (transfer full): The duplicated #EList.
 **/
EList *
e_list_duplicate (EList *list)
{
	EList *dupe = g_object_new (E_TYPE_LIST, NULL);

	dupe->copy = list->copy;
	dupe->free = list->free;
	dupe->closure = list->closure;
	dupe->list = g_list_copy (list->list);
	if (dupe->copy) {
		GList *listlist;
		for (listlist = dupe->list; listlist; listlist = listlist->next) {
			listlist->data = dupe->copy (listlist->data, dupe->closure);
		}
	}
	return dupe;
}

/**
 * e_list_get_iterator:
 * @list: The #EList object.
 *
 * Returns: (transfer none): the #EIterator.
 **/
EIterator *
e_list_get_iterator (EList *list)
{
	EIterator *iterator = NULL;
	g_return_val_if_fail (list != NULL, NULL);
	iterator = e_list_iterator_new (list);
	if (iterator)
		list->iterators = g_list_append (list->iterators, iterator);
	return iterator;
}

gint
e_list_length (EList *list)
{
	return g_list_length (list->list);
}

void
e_list_append (EList *list,
               gconstpointer data)
{
	e_list_invalidate_iterators (list, NULL);
	if (list->copy)
		list->list = g_list_append (
			list->list, list->copy (data, list->closure));
	else
		list->list = g_list_append (list->list, (gpointer) data);
}

void
e_list_remove (EList *list,
               gconstpointer data)
{
	GList *link;
	link = g_list_find (list->list, data);
	if (link)
		e_list_remove_link (list, link);
}

void
e_list_invalidate_iterators (EList *list,
                             EIterator *skip)
{
	GList *iterators = list->iterators;
	for (; iterators; iterators = iterators->next) {
		if (iterators->data != skip) {
			e_iterator_invalidate (E_ITERATOR (iterators->data));
		}
	}
}

/* FIXME: This doesn't work properly if the iterator is the first
 * iterator in the list.  Well, the iterator doesn't continue on after
 * the next time next is called, at least. */
/**
 * e_list_remove_link: (skip)
 * @list:
 * @link:
 */
void
e_list_remove_link (EList *list,
                    GList *link)
{
	GList *iterators = list->iterators;
	for (; iterators; iterators = iterators->next) {
		if (((EListIterator *) iterators->data)->iterator == link) {
			e_iterator_prev (iterators->data);
		}
	}
	if (list->free)
		list->free (link->data, list->closure);
	list->list = g_list_remove_link (list->list, link);
	g_list_free_1 (link);
}

void
e_list_remove_iterator (EList *list,
                        EIterator *iterator)
{
	list->iterators = g_list_remove (list->iterators, iterator);
}

