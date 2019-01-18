/*
 * e-source-address-book.h
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
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_ADDRESS_BOOK_H
#define E_SOURCE_ADDRESS_BOOK_H

#include <libedataserver/e-source-backend.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_ADDRESS_BOOK \
	(e_source_address_book_get_type ())
#define E_SOURCE_ADDRESS_BOOK(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_ADDRESS_BOOK, ESourceAddressBook))
#define E_SOURCE_ADDRESS_BOOK_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_ADDRESS_BOOK, ESourceAddressBookClass))
#define E_IS_SOURCE_ADDRESS_BOOK(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_ADDRESS_BOOK))
#define E_IS_SOURCE_ADDRESS_BOOK_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_ADDRESS_BOOK))
#define E_SOURCE_ADDRESS_BOOK_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_ADDRESS_BOOK, ESourceAddressBookClass))

/**
 * E_SOURCE_EXTENSION_ADDRESS_BOOK:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceAddressBook.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_ADDRESS_BOOK "Address Book"

G_BEGIN_DECLS

typedef struct _ESourceAddressBook ESourceAddressBook;
typedef struct _ESourceAddressBookClass ESourceAddressBookClass;
typedef struct _ESourceAddressBookPrivate ESourceAddressBookPrivate;

/**
 * ESourceAddressBook:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceAddressBook {
	/*< private >*/
	ESourceBackend parent;
	ESourceAddressBookPrivate *priv;
};

struct _ESourceAddressBookClass {
	ESourceBackendClass parent_class;
};

GType		e_source_address_book_get_type	(void) G_GNUC_CONST;

G_END_DECLS

#endif /* E_SOURCE_ADDRESS_BOOK_H */
