/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 * Copyright (C) 2006 OpenedHand Ltd
 * Copyright (C) 2009 Intel Corporation
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

#ifndef E_DATA_BOOK_FACTORY_H
#define E_DATA_BOOK_FACTORY_H

#include <libebackend/libebackend.h>

/* Standard GObject macros */
#define E_TYPE_DATA_BOOK_FACTORY \
	(e_data_book_factory_get_type ())
#define E_DATA_BOOK_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_DATA_BOOK_FACTORY, EDataBookFactory))
#define E_DATA_BOOK_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_DATA_BOOK_FACTORY, EDataBookFactoryClass))
#define E_IS_DATA_BOOK_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_DATA_BOOK_FACTORY))
#define E_IS_DATA_BOOK_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_DATA_BOOK_FACTORY))
#define E_DATA_BOOK_FACTORY_GET_CLASS(cls) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_DATA_BOOK_FACTORY, EDataBookFactoryClass))

/**
 * EDS_ADDRESS_BOOK_MODULES:
 *
 * This environment variable configures where the address book
 * factory loads it's backend modules from.
 */
#define EDS_ADDRESS_BOOK_MODULES "EDS_ADDRESS_BOOK_MODULES"

/**
 * EDS_SUBPROCESS_BOOK_PATH:
 *
 * This environment variable configures where the address book
 * factory subprocess is located in.
 */
#define EDS_SUBPROCESS_BOOK_PATH "EDS_SUBPROCESS_BOOK_PATH"

G_BEGIN_DECLS

typedef struct _EDataBookFactory EDataBookFactory;
typedef struct _EDataBookFactoryClass EDataBookFactoryClass;
typedef struct _EDataBookFactoryPrivate EDataBookFactoryPrivate;

struct _EDataBookFactory {
	EDataFactory parent;
	EDataBookFactoryPrivate *priv;
};

struct _EDataBookFactoryClass {
	EDataFactoryClass parent_class;
};

GType		e_data_book_factory_get_type	(void) G_GNUC_CONST;
EDBusServer *	e_data_book_factory_new		(gint backend_per_process,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* E_DATA_BOOK_FACTORY_H */
