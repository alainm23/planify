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

#ifndef E_ITERATOR_H
#define E_ITERATOR_H

#include <stdio.h>
#include <time.h>
#include <glib-object.h>

/* Standard GObject macros */
#define E_TYPE_ITERATOR \
	(e_iterator_get_type ())
#define E_ITERATOR(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_ITERATOR, EIterator))
#define E_ITERATOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_ITERATOR, EIteratorClass))
#define E_IS_ITERATOR(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_ITERATOR))
#define E_IS_ITERATOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_ITERATOR))
#define E_ITERATOR_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_ITERATOR, EIteratorClass))

G_BEGIN_DECLS

typedef struct _EIterator EIterator;
typedef struct _EIteratorClass EIteratorClass;

/**
 * EIterator:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 **/
struct _EIterator {
	/*< private >*/
	GObject parent;
};

struct _EIteratorClass {
	GObjectClass parent_class;

	/* Signals */
	void		(*invalidate)		(EIterator *iterator);

	/* Methods */
	gconstpointer	(*get)			(EIterator *iterator);
	void		(*reset)		(EIterator *iterator);
	void		(*last)			(EIterator *iterator);
	gboolean	(*next)			(EIterator *iterator);
	gboolean	(*prev)			(EIterator *iterator);
	void		(*remove)		(EIterator *iterator);
	void		(*insert)		(EIterator *iterator,
						 gconstpointer object,
						 gboolean before);
	void		(*set)			(EIterator *iterator,
						 gconstpointer object);
	gboolean	(*is_valid)		(EIterator *iterator);
};

GType		e_iterator_get_type		(void) G_GNUC_CONST;
gconstpointer	e_iterator_get			(EIterator *iterator);
void		e_iterator_reset		(EIterator *iterator);
void		e_iterator_last			(EIterator *iterator);
gboolean	e_iterator_next			(EIterator *iterator);
gboolean	e_iterator_prev			(EIterator *iterator);
void		e_iterator_delete		(EIterator *iterator);
void		e_iterator_insert		(EIterator *iterator,
						 gconstpointer object,
						 gboolean before);
void		e_iterator_set			(EIterator *iterator,
						 gconstpointer object);
gboolean	e_iterator_is_valid		(EIterator *iterator);
void		e_iterator_invalidate		(EIterator *iterator);

G_END_DECLS

#endif /* E_ITERATOR_H */

#endif /* __GI_SCANNER__ */

#endif /* EDS_DISABLE_DEPRECATED */

