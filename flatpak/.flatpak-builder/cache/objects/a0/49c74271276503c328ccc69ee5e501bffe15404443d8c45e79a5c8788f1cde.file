/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2013 Intel Corporation
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
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
 * Authors: Tristan Van Berkom <tristanvb@openismus.com>
 */

#if !defined (__LIBEDATA_BOOK_H_INSIDE__) && !defined (LIBEDATA_BOOK_COMPILATION)
#error "Only <libedata-book/libedata-book.h> should be included directly."
#endif

#ifndef E_DATA_BOOK_CURSOR_CACHE_H
#define E_DATA_BOOK_CURSOR_CACHE_H

#include <libedata-book/e-data-book-cursor.h>
#include <libedata-book/e-book-cache.h>
#include <libedata-book/e-book-backend.h>

#define E_TYPE_DATA_BOOK_CURSOR_CACHE        (e_data_book_cursor_cache_get_type ())
#define E_DATA_BOOK_CURSOR_CACHE(o)          (G_TYPE_CHECK_INSTANCE_CAST ((o), E_TYPE_DATA_BOOK_CURSOR_CACHE, EDataBookCursorCache))
#define E_DATA_BOOK_CURSOR_CACHE_CLASS(k)    (G_TYPE_CHECK_CLASS_CAST((k), E_TYPE_DATA_BOOK_CURSOR_CACHE, EDataBookCursorCacheClass))
#define E_IS_DATA_BOOK_CURSOR_CACHE(o)       (G_TYPE_CHECK_INSTANCE_TYPE ((o), E_TYPE_DATA_BOOK_CURSOR_CACHE))
#define E_IS_DATA_BOOK_CURSOR_CACHE_CLASS(k) (G_TYPE_CHECK_CLASS_TYPE ((k), E_TYPE_DATA_BOOK_CURSOR_CACHE))
#define E_DATA_BOOK_CURSOR_CACHE_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS ((o), E_TYPE_DATA_BOOK_CURSOR_CACHE, EDataBookCursorCacheClass))

G_BEGIN_DECLS

typedef struct _EDataBookCursorCache EDataBookCursorCache;
typedef struct _EDataBookCursorCacheClass EDataBookCursorCacheClass;
typedef struct _EDataBookCursorCachePrivate EDataBookCursorCachePrivate;

/**
 * EDataBookCursorCache:
 *
 * An opaque handle for the #EBookCache cursor instance.
 *
 * Since: 3.26
 */
struct _EDataBookCursorCache {
	/*< private >*/
	EDataBookCursor parent;
	EDataBookCursorCachePrivate *priv;
};

/**
 * EDataBookCursorCacheClass:
 *
 * The #EBookCache cursor class structure.
 *
 * Since: 3.26
 */
struct _EDataBookCursorCacheClass {
	/*< private >*/
	EDataBookCursorClass parent;
};

GType		e_data_book_cursor_cache_get_type	(void);
EDataBookCursor *
		e_data_book_cursor_cache_new		(EBookBackend *book_backend,
							 EBookCache *book_cache,
							 const EContactField *sort_fields,
							 const EBookCursorSortType *sort_types,
							 guint n_fields,
							 GError **error);

G_END_DECLS

#endif /* E_DATA_BOOK_CURSOR_CACHE_H */
