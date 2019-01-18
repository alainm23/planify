/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * A client-side GObject which exposes the
 * Evolution:BookListener interface.
 *
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
 * Authors: Nat Friedman (nat@ximian.com)
 *
 */

#if !defined (__LIBEBOOK_H_INSIDE__) && !defined (LIBEBOOK_COMPILATION)
#error "Only <libebook/libebook.h> should be included directly."
#endif

#ifndef __E_BOOK_TYPES_H__
#define __E_BOOK_TYPES_H__

#include <libebook-contacts/libebook-contacts.h>

G_BEGIN_DECLS

#ifndef EDS_DISABLE_DEPRECATED

/**
 * E_BOOK_ERROR:
 *
 * Error domain for the deprecated #EBook
 *
 * Deprecated: 3.2: Use #EBookClient and it's error codes instead
 */
#define E_BOOK_ERROR e_book_error_quark()

GQuark e_book_error_quark (void) G_GNUC_CONST;

/**
 * EBookStatus:
 *
 * Error codes for the #E_BOOK_ERROR error
 *
 * Deprecated: 3.2: Use #EBookClient and it's error codes instead
 */

/* Marked these all as private, since they are deprecated
 * and we just avoid gtk-doc warnings this way
 */
typedef enum { /*< private >*/
	E_BOOK_ERROR_OK,
	E_BOOK_ERROR_INVALID_ARG,
	E_BOOK_ERROR_BUSY,
	E_BOOK_ERROR_REPOSITORY_OFFLINE,
	E_BOOK_ERROR_NO_SUCH_BOOK,
	E_BOOK_ERROR_NO_SELF_CONTACT,
	E_BOOK_ERROR_SOURCE_NOT_LOADED,
	E_BOOK_ERROR_SOURCE_ALREADY_LOADED,
	E_BOOK_ERROR_PERMISSION_DENIED,
	E_BOOK_ERROR_CONTACT_NOT_FOUND,
	E_BOOK_ERROR_CONTACT_ID_ALREADY_EXISTS,
	E_BOOK_ERROR_PROTOCOL_NOT_SUPPORTED,
	E_BOOK_ERROR_CANCELLED,
	E_BOOK_ERROR_COULD_NOT_CANCEL,
	E_BOOK_ERROR_AUTHENTICATION_FAILED,
	E_BOOK_ERROR_AUTHENTICATION_REQUIRED,
	E_BOOK_ERROR_TLS_NOT_AVAILABLE,
	E_BOOK_ERROR_DBUS_EXCEPTION,
	E_BOOK_ERROR_NO_SUCH_SOURCE,
	E_BOOK_ERROR_OFFLINE_UNAVAILABLE,
	E_BOOK_ERROR_OTHER_ERROR,
	E_BOOK_ERROR_INVALID_SERVER_VERSION,
	E_BOOK_ERROR_UNSUPPORTED_AUTHENTICATION_METHOD,
	E_BOOK_ERROR_NO_SPACE,
	E_BOOK_ERROR_NOT_SUPPORTED
} EBookStatus;

/**
 * E_BOOK_ERROR_CORBA_EXCEPTION:
 *
 * A deprecated #EBookStatus
 *
 * Deprecated
 */
#define E_BOOK_ERROR_CORBA_EXCEPTION E_BOOK_ERROR_DBUS_EXCEPTION

#endif /* EDS_DISABLE_DEPRECATED  */

G_END_DECLS

#endif /* __E_BOOK_TYPES_H__ */
