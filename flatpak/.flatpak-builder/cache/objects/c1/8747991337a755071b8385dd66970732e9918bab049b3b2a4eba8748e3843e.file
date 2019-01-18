/*
 * e-source-address-book.c
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

/**
 * SECTION: e-source-address-book
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for an address book
 *
 * The #ESourceAddressBook extension identifies the #ESource as an
 * address book.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceAddressBook *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_ADDRESS_BOOK);
 * ]|
 **/

#include "e-source-address-book.h"

#include <libedataserver/e-data-server-util.h>

G_DEFINE_TYPE (
	ESourceAddressBook,
	e_source_address_book,
	E_TYPE_SOURCE_BACKEND)

static void
e_source_address_book_class_init (ESourceAddressBookClass *class)
{
	ESourceExtensionClass *extension_class;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_ADDRESS_BOOK;
}

static void
e_source_address_book_init (ESourceAddressBook *extension)
{
}
