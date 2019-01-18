/*
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

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include "e-book-contacts-types.h"

G_DEFINE_QUARK (e-book-client-error-quark, e_book_client_error)

/**
 * e_book_client_error_to_string:
 * @code: an #EBookClientError code
 *
 * Get localized human readable description of the given error code.
 *
 * Returns: Localized human readable description of the given error code
 *
 * Since: 3.2
 **/
const gchar *
e_book_client_error_to_string (EBookClientError code)
{
	switch (code) {
	case E_BOOK_CLIENT_ERROR_NO_SUCH_BOOK:
		return _("No such book");
	case E_BOOK_CLIENT_ERROR_CONTACT_NOT_FOUND:
		return _("Contact not found");
	case E_BOOK_CLIENT_ERROR_CONTACT_ID_ALREADY_EXISTS:
		return _("Contact ID already exists");
	case E_BOOK_CLIENT_ERROR_NO_SUCH_SOURCE:
		return _("No such source");
	case E_BOOK_CLIENT_ERROR_NO_SPACE:
		return _("No space");
	}

	return _("Unknown error");
}

/**
 * e_book_client_error_create:
 * @code: an #EBookClientError code to create
 * @custom_msg: custom message to use for the error; can be %NULL
 *
 * Returns: a new #GError containing an E_BOOK_CLIENT_ERROR of the given
 * @code. If the @custom_msg is NULL, then the error message is
 * the one returned from e_book_client_error_to_string() for the @code,
 * otherwise the given message is used.
 *
 * Returned pointer should be freed with g_error_free().
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Just use the #GError API directly.
 **/
GError *
e_book_client_error_create (EBookClientError code,
                            const gchar *custom_msg)
{
	return g_error_new_literal (E_BOOK_CLIENT_ERROR, code, custom_msg ? custom_msg : e_book_client_error_to_string (code));
}
