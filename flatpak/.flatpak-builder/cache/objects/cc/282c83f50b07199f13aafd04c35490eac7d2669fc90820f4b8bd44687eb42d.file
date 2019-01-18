/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 * Copyright (C) 2012 Intel Corporation
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
 * Authors: Nat Friedman (nat@ximian.com)
 *          Tristan Van Berkom <tristanvb@openismus.com>
 */

#if !defined (__LIBEBOOK_CONTACTS_H_INSIDE__) && !defined (LIBEBOOK_CONTACTS_COMPILATION)
#error "Only <libebook-contacts/libebook-contacts.h> should be included directly."
#endif

#ifndef __E_BOOK_CONTACTS_TYPES_H__
#define __E_BOOK_CONTACTS_TYPES_H__

#include <libebook-contacts/e-contact.h>

/**
 * E_BOOK_CLIENT_ERROR:
 *
 * Error domain for #EBookClient errors
 *
 * Since: 3.2
 **/
#define E_BOOK_CLIENT_ERROR e_book_client_error_quark ()

G_BEGIN_DECLS

/**
 * EBookClientViewFlags:
 * @E_BOOK_CLIENT_VIEW_FLAGS_NONE:
 *   Symbolic value for no flags
 * @E_BOOK_CLIENT_VIEW_FLAGS_NOTIFY_INITIAL:
 *   If this flag is set then all contacts matching the view's query will
 *   be sent as notifications when starting the view, otherwise only future
 *   changes will be reported.  The default for a #EBookClientView is %TRUE.
 *
 * Flags that control the behaviour of an #EBookClientView.
 *
 * Since: 3.4
 */
typedef enum {
	E_BOOK_CLIENT_VIEW_FLAGS_NONE = 0,
	E_BOOK_CLIENT_VIEW_FLAGS_NOTIFY_INITIAL = (1 << 0),
} EBookClientViewFlags;

/**
 * EBookClientError:
 * @E_BOOK_CLIENT_ERROR_NO_SUCH_BOOK: Requested book did not exist
 * @E_BOOK_CLIENT_ERROR_CONTACT_NOT_FOUND: Contact referred to was not found
 * @E_BOOK_CLIENT_ERROR_CONTACT_ID_ALREADY_EXISTS: Tried to add a contact which already exists
 * @E_BOOK_CLIENT_ERROR_NO_SUCH_SOURCE: Referred #ESource does not exist
 * @E_BOOK_CLIENT_ERROR_NO_SPACE: Out of disk space
 *
 * Error codes returned by #EBookClient APIs, if an #EClientError was not available.
 *
 * Since: 3.2
 **/
typedef enum {
	E_BOOK_CLIENT_ERROR_NO_SUCH_BOOK,
	E_BOOK_CLIENT_ERROR_CONTACT_NOT_FOUND,
	E_BOOK_CLIENT_ERROR_CONTACT_ID_ALREADY_EXISTS,
	E_BOOK_CLIENT_ERROR_NO_SUCH_SOURCE,
	E_BOOK_CLIENT_ERROR_NO_SPACE
} EBookClientError;

/**
 * EDataBookStatus:
 * @E_DATA_BOOK_STATUS_SUCCESS: No error
 * @E_DATA_BOOK_STATUS_BUSY: Backend was busy
 * @E_DATA_BOOK_STATUS_REPOSITORY_OFFLINE: Offsite repository was not online
 * @E_DATA_BOOK_STATUS_PERMISSION_DENIED: Permission denied
 * @E_DATA_BOOK_STATUS_CONTACT_NOT_FOUND: Contact referred to was not found
 * @E_DATA_BOOK_STATUS_CONTACTID_ALREADY_EXISTS: Tried to add a contact which already exists
 * @E_DATA_BOOK_STATUS_AUTHENTICATION_FAILED: Authentication failure
 * @E_DATA_BOOK_STATUS_AUTHENTICATION_REQUIRED: Authentication required for this operation
 * @E_DATA_BOOK_STATUS_UNSUPPORTED_FIELD: An unsupported #EContactField was specified for a given operation
 * @E_DATA_BOOK_STATUS_UNSUPPORTED_AUTHENTICATION_METHOD: The authentication method is unsupported
 * @E_DATA_BOOK_STATUS_TLS_NOT_AVAILABLE: TLS was not available
 * @E_DATA_BOOK_STATUS_NO_SUCH_BOOK: Book did not exist
 * @E_DATA_BOOK_STATUS_BOOK_REMOVED: Book was removed
 * @E_DATA_BOOK_STATUS_OFFLINE_UNAVAILABLE: XXX Document me
 * @E_DATA_BOOK_STATUS_SEARCH_SIZE_LIMIT_EXCEEDED: Exceeded limit of seach size
 * @E_DATA_BOOK_STATUS_SEARCH_TIME_LIMIT_EXCEEDED: Exceeded time limit for seach
 * @E_DATA_BOOK_STATUS_INVALID_QUERY: Given search espression is invalid
 * @E_DATA_BOOK_STATUS_QUERY_REFUSED: Given search espression was refused
 * @E_DATA_BOOK_STATUS_COULD_NOT_CANCEL: Unable to cancel an operation
 * @E_DATA_BOOK_STATUS_OTHER_ERROR: An other error occurred
 * @E_DATA_BOOK_STATUS_INVALID_SERVER_VERSION: Invalid server version
 * @E_DATA_BOOK_STATUS_NO_SPACE: Disk space insufficient
 * @E_DATA_BOOK_STATUS_INVALID_ARG: Invalid argument
 * @E_DATA_BOOK_STATUS_NOT_SUPPORTED: Unsupported operation
 * @E_DATA_BOOK_STATUS_NOT_OPENED: Tried to access a book which is not yet open
 * @E_DATA_BOOK_STATUS_OUT_OF_SYNC: Out of sync state
 *
 * Error codes for the #E_DATA_BOOK_ERROR domain, these are used
 * in the backend.
 *
 * Since: 3.6
 **/
typedef enum {
	E_DATA_BOOK_STATUS_SUCCESS,
	E_DATA_BOOK_STATUS_BUSY,
	E_DATA_BOOK_STATUS_REPOSITORY_OFFLINE,
	E_DATA_BOOK_STATUS_PERMISSION_DENIED,
	E_DATA_BOOK_STATUS_CONTACT_NOT_FOUND,
	E_DATA_BOOK_STATUS_CONTACTID_ALREADY_EXISTS,
	E_DATA_BOOK_STATUS_AUTHENTICATION_FAILED,
	E_DATA_BOOK_STATUS_AUTHENTICATION_REQUIRED,
	E_DATA_BOOK_STATUS_UNSUPPORTED_FIELD,
	E_DATA_BOOK_STATUS_UNSUPPORTED_AUTHENTICATION_METHOD,
	E_DATA_BOOK_STATUS_TLS_NOT_AVAILABLE,
	E_DATA_BOOK_STATUS_NO_SUCH_BOOK,
	E_DATA_BOOK_STATUS_BOOK_REMOVED,
	E_DATA_BOOK_STATUS_OFFLINE_UNAVAILABLE,
	E_DATA_BOOK_STATUS_SEARCH_SIZE_LIMIT_EXCEEDED,
	E_DATA_BOOK_STATUS_SEARCH_TIME_LIMIT_EXCEEDED,
	E_DATA_BOOK_STATUS_INVALID_QUERY,
	E_DATA_BOOK_STATUS_QUERY_REFUSED,
	E_DATA_BOOK_STATUS_COULD_NOT_CANCEL,
	E_DATA_BOOK_STATUS_OTHER_ERROR,
	E_DATA_BOOK_STATUS_INVALID_SERVER_VERSION,
	E_DATA_BOOK_STATUS_NO_SPACE,
	E_DATA_BOOK_STATUS_INVALID_ARG,
	E_DATA_BOOK_STATUS_NOT_SUPPORTED,
	E_DATA_BOOK_STATUS_NOT_OPENED,
	E_DATA_BOOK_STATUS_OUT_OF_SYNC
} EDataBookStatus;

/**
 * EBookIndexType:
 * @E_BOOK_INDEX_PREFIX: An index suitable for searching contacts with a prefix pattern
 * @E_BOOK_INDEX_SUFFIX: An index suitable for searching contacts with a suffix pattern
 * @E_BOOK_INDEX_PHONE: An index suitable for searching contacts for phone numbers.
 * <note><para>Phone numbers must be convertible into FQTN according to E.164 to be
 * stored in this index. The number "+9999999" for instance won't be stored because
 * the country calling code "+999" currently is not assigned.</para></note>
 * @E_BOOK_INDEX_SORT_KEY: Indicates that a given #EContactField should be usable as a sort key.
 *
 * The type of index defined by e_source_backend_summary_setup_set_indexed_fields()
 */
typedef enum {
	E_BOOK_INDEX_PREFIX = 0,
	E_BOOK_INDEX_SUFFIX,
	E_BOOK_INDEX_PHONE,
	E_BOOK_INDEX_SORT_KEY
} EBookIndexType;

/**
 * EBookCursorSortType:
 * @E_BOOK_CURSOR_SORT_ASCENDING: Sort results in ascending order
 * @E_BOOK_CURSOR_SORT_DESCENDING: Sort results in descending order
 *
 * Specifies the sort order of an ordered query
 *
 * Since: 3.12
 */
typedef enum {
	E_BOOK_CURSOR_SORT_ASCENDING = 0,
	E_BOOK_CURSOR_SORT_DESCENDING
} EBookCursorSortType;

/**
 * EBookCursorOrigin:
 * @E_BOOK_CURSOR_ORIGIN_CURRENT:  The current cursor position
 * @E_BOOK_CURSOR_ORIGIN_BEGIN:    The beginning of the cursor results.
 * @E_BOOK_CURSOR_ORIGIN_END:      The ending of the cursor results.
 *
 * Specifies the start position to in the list of traversed contacts
 * in calls to e_book_client_cursor_step().
 *
 * When an #EBookClientCursor is created, the current position implied by %E_BOOK_CURSOR_ORIGIN_CURRENT
 * is the same as %E_BOOK_CURSOR_ORIGIN_BEGIN.
 *
 * Since: 3.12
 */
typedef enum {
	E_BOOK_CURSOR_ORIGIN_CURRENT,
	E_BOOK_CURSOR_ORIGIN_BEGIN,
	E_BOOK_CURSOR_ORIGIN_END
} EBookCursorOrigin;

/**
 * EBookCursorStepFlags:
 * @E_BOOK_CURSOR_STEP_MOVE:  The cursor position should be modified while stepping
 * @E_BOOK_CURSOR_STEP_FETCH: Traversed contacts should be listed and returned while stepping.
 *
 * Defines the behaviour of e_book_client_cursor_step().
 *
 * Since: 3.12
 */
typedef enum {
	E_BOOK_CURSOR_STEP_MOVE = (1 << 0),
	E_BOOK_CURSOR_STEP_FETCH = (1 << 1)
} EBookCursorStepFlags;

GQuark		e_book_client_error_quark	(void) G_GNUC_CONST;
const gchar *	e_book_client_error_to_string	(EBookClientError code);

#ifndef EDS_DISABLE_DEPRECATED

/**
 * EBookViewStatus:
 * @E_BOOK_VIEW_STATUS_OK: Ok
 * @E_BOOK_VIEW_STATUS_TIME_LIMIT_EXCEEDED: Time limit exceeded
 * @E_BOOK_VIEW_STATUS_SIZE_LIMIT_EXCEEDED: Size limit exceeded
 * @E_BOOK_VIEW_ERROR_INVALID_QUERY: Invalid search expression
 * @E_BOOK_VIEW_ERROR_QUERY_REFUSED: Search expression refused
 * @E_BOOK_VIEW_ERROR_OTHER_ERROR: Another error occurred
 *
 * Status messages used in notifications in the deprecated #EBookView class
 *
 * Deprecated: 3.2: Use #EBookClientView instead.
 */
typedef enum {
	E_BOOK_VIEW_STATUS_OK,
	E_BOOK_VIEW_STATUS_TIME_LIMIT_EXCEEDED,
	E_BOOK_VIEW_STATUS_SIZE_LIMIT_EXCEEDED,
	E_BOOK_VIEW_ERROR_INVALID_QUERY,
	E_BOOK_VIEW_ERROR_QUERY_REFUSED,
	E_BOOK_VIEW_ERROR_OTHER_ERROR
} EBookViewStatus;

/**
 * EBookChangeType:
 * @E_BOOK_CHANGE_CARD_ADDED: A vCard was added
 * @E_BOOK_CHANGE_CARD_DELETED: A vCard was deleted
 * @E_BOOK_CHANGE_CARD_MODIFIED: A vCard was modified
 *
 * The type of change in an #EBookChange
 *
 * Deprecated: 3.2
 */
typedef enum {
	E_BOOK_CHANGE_CARD_ADDED,
	E_BOOK_CHANGE_CARD_DELETED,
	E_BOOK_CHANGE_CARD_MODIFIED
} EBookChangeType;

/**
 * EBookChange:
 * @change_type: The #EBookChangeType
 * @contact: The #EContact which changed
 *
 * This is a part of the deprecated #EBook API.
 *
 * Deprecated: 3.2
 */
typedef struct {
	EBookChangeType  change_type;
	EContact        *contact;
} EBookChange;

GError *	e_book_client_error_create	(EBookClientError code,
						 const gchar *custom_msg);
#endif /* EDS_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* __E_BOOK_CONTACTS_TYPES_H__ */
