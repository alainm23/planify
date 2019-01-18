/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2014 Red Hat, Inc. (www.redhat.com)
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
 */

#if !defined (__LIBEDATA_BOOK_H_INSIDE__) && !defined (LIBEDATA_BOOK_COMPILATION)
#error "Only <libedata-book/libedata-book.h> should be included directly."
#endif

#ifndef E_SUBPROCESS_BOOK_FACTORY_H
#define E_SUBPROCESS_BOOK_FACTORY_H

#include <libebackend/libebackend.h>

/* Standard GObject macros */
#define E_TYPE_SUBPROCESS_BOOK_FACTORY \
	(e_subprocess_book_factory_get_type ())
#define E_SUBPROCESS_BOOK_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SUBPROCESS_BOOK_FACTORY, ESubprocessBookFactory))
#define E_SUBPROCESS_BOOK_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SUBPROCESS_BOOK_FACTORY, ESubprocessBookFactoryClass))
#define E_IS_SUBPROCESS_BOOK_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SUBPROCESS_BOOK_FACTORY))
#define E_IS_SUBPROCESS_BOOK_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SUBPROCESS_BOOK_FACTORY))
#define E_SUBPROCESS_BOOK_FACTORY_GET_CLASS(cls) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SUBPROCESS_BOOK_FACTORY, ESubprocessBookFactoryClass))

G_BEGIN_DECLS

typedef struct _ESubprocessBookFactory ESubprocessBookFactory;
typedef struct _ESubprocessBookFactoryClass ESubprocessBookFactoryClass;
typedef struct _ESubprocessBookFactoryPrivate ESubprocessBookFactoryPrivate;

struct _ESubprocessBookFactory {
	ESubprocessFactory parent;
	ESubprocessBookFactoryPrivate *priv;
};

struct _ESubprocessBookFactoryClass {
	ESubprocessFactoryClass parent_class;
};

GType		e_subprocess_book_factory_get_type	(void) G_GNUC_CONST;
ESubprocessBookFactory *
		e_subprocess_book_factory_new		(GCancellable *cancellable,
							 GError **error);

G_END_DECLS

#endif /* E_SUBPROCESS_BOOK_FACTORY_H */
