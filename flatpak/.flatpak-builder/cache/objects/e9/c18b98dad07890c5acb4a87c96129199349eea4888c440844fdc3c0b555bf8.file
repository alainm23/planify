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

#ifndef E_LIST_H
#define E_LIST_H

#include <stdio.h>
#include <time.h>
#include <libedataserver/e-iterator.h>

/* Standard GObject macros */
#define E_TYPE_LIST \
	(e_list_get_type ())
#define E_LIST(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_LIST, EList))
#define E_LIST_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_LIST, EListClass))
#define E_IS_LIST(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_LIST))
#define E_IS_LIST_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_LIST))
#define E_LIST_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_LIST, EListClass))

G_BEGIN_DECLS

typedef struct _EList EList;
typedef struct _EListClass EListClass;

typedef gpointer	(*EListCopyFunc)	(gconstpointer data,
						 gpointer closure);
typedef void		(*EListFreeFunc)	(gpointer data,
						 gpointer closure);

struct _EList {
	GObject parent;

	GList *list;
	GList *iterators;
	EListCopyFunc copy;
	EListFreeFunc free;
	gpointer closure;
};

struct _EListClass {
	GObjectClass parent_class;
};

GType		e_list_get_type			(void) G_GNUC_CONST;
EList *		e_list_new			(EListCopyFunc copy,
						 EListFreeFunc free,
						 gpointer closure);
void		e_list_construct		(EList *list,
						 EListCopyFunc copy,
						 EListFreeFunc free,
						 gpointer closure);
EList *		e_list_duplicate		(EList *list);
EIterator *	e_list_get_iterator		(EList *list);
void		e_list_append			(EList *list,
						 gconstpointer data);
void		e_list_remove			(EList *list,
						 gconstpointer data);
gint		e_list_length			(EList *list);

/* For iterators to call. */
void		e_list_remove_link		(EList *list,
						 GList *link);
void		e_list_remove_iterator		(EList *list,
						 EIterator *iterator);
void		e_list_invalidate_iterators	(EList *list,
						 EIterator *skip);

G_END_DECLS

#endif /* E_LIST_H */

#endif /* __GI_SCANNER__ */

#endif /* EDS_DISABLE_DEPRECATED */

