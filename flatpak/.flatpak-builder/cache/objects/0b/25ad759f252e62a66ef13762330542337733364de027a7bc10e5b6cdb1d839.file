/* e-book-backend-carddav.h - CardDAV contact backend.
 *
 * Copyright (C) 2008 Matthias Braun <matze@braunis.de>
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
 * Authors: Matthias Braun <matze@braunis.de>
 */

#ifndef E_BOOK_BACKEND_CARDDAV_H
#define E_BOOK_BACKEND_CARDDAV_H

#include <libedata-book/libedata-book.h>

/* Standard GObject macros */
#define E_TYPE_BOOK_BACKEND_CARDDAV \
	(e_book_backend_carddav_get_type ())
#define E_BOOK_BACKEND_CARDDAV(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_BOOK_BACKEND_CARDDAV, EBookBackendCardDAV))
#define E_BOOK_BACKEND_CARDDAV_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_BOOK_BACKEND_CARDDAV, EBookBackendCardDAVClass))
#define E_IS_BOOK_BACKEND_CARDDAV(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_BOOK_BACKEND_CARDDAV))
#define E_IS_BOOK_BACKEND_CARDDAV_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_BOOK_BACKEND_CARDDAV))
#define E_BOOK_BACKEND_CARDDAV_GET_CLASS(cls) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_BOOK_BACKEND_CARDDAV, EBookBackendCardDAVClass))

G_BEGIN_DECLS

typedef struct _EBookBackendCardDAV EBookBackendCardDAV;
typedef struct _EBookBackendCardDAVClass EBookBackendCardDAVClass;
typedef struct _EBookBackendCardDAVPrivate EBookBackendCardDAVPrivate;

struct _EBookBackendCardDAV {
	EBookMetaBackend parent;
	EBookBackendCardDAVPrivate *priv;
};

struct _EBookBackendCardDAVClass {
	EBookMetaBackendClass parent_class;
};

GType		e_book_backend_carddav_get_type	(void);

G_END_DECLS

#endif /* E_BOOK_BACKEND_CARDDAV_H */
