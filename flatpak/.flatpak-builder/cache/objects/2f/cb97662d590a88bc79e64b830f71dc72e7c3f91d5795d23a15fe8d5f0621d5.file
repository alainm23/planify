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
 * Authors: Chris Lahey <clahey@ximian.com>
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef EDS_DISABLE_DEPRECATED

/* Do not generate bindings. */
#ifndef __GI_SCANNER__

#ifndef E_LIST_ITERATOR_H
#define E_LIST_ITERATOR_H

#include <stdio.h>
#include <time.h>

#include <libedataserver/e-list.h>
#include <libedataserver/e-iterator.h>

/* Standard GObject macros */
#define E_TYPE_LIST_ITERATOR \
	(e_list_iterator_get_type ())
#define E_LIST_ITERATOR(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_LIST_ITERATOR, EListIterator))
#define E_LIST_ITERATOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_LIST_ITERATOR, EListIteratorClass))
#define E_IS_LIST_ITERATOR(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_LIST_ITERATOR))
#define E_IS_LIST_ITERATOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_LIST_ITERATOR))
#define E_LIST_ITERATOR_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_LIST_ITERATOR, EListIteratorClass))

G_BEGIN_DECLS

typedef struct _EListIterator EListIterator;
typedef struct _EListIteratorClass EListIteratorClass;

struct _EListIterator {
	EIterator parent;

	EList *list;
	GList *iterator;
};

struct _EListIteratorClass {
	EIteratorClass parent_class;
};

GType		e_list_iterator_get_type	(void) G_GNUC_CONST;
EIterator *	e_list_iterator_new		(EList *list);

G_END_DECLS

#endif /* E_LIST_ITERATOR_H */

#endif /* __GI_SCANNER__ */

#endif /* EDS_DISABLE_DEPRECATED */

