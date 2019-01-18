/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2013 Intel Corporation
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

#if !defined (__LIBEBOOK_H_INSIDE__) && !defined (LIBEBOOK_COMPILATION)
#error "Only <libebook/libebook.h> should be included directly."
#endif

#ifndef E_BOOK_CLIENT_CURSOR_H
#define E_BOOK_CLIENT_CURSOR_H

#include <glib-object.h>
#include <libebook-contacts/libebook-contacts.h>

/* Standard GObject macros */
#define E_TYPE_BOOK_CLIENT_CURSOR \
	(e_book_client_cursor_get_type ())
#define E_BOOK_CLIENT_CURSOR(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_BOOK_CLIENT_CURSOR, EBookClientCursor))
#define E_BOOK_CLIENT_CURSOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_BOOK_CLIENT_CURSOR, EBookClientCursorClass))
#define E_IS_BOOK_CLIENT_CURSOR(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_BOOK_CLIENT_CURSOR))
#define E_IS_BOOK_CLIENT_CURSOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_BOOK_CLIENT_CURSOR))
#define E_BOOK_CLIENT_CURSOR_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_BOOK_CLIENT_CURSOR, EBookClientCursorClass))

G_BEGIN_DECLS

typedef struct _EBookClientCursor EBookClientCursor;
typedef struct _EBookClientCursorClass EBookClientCursorClass;
typedef struct _EBookClientCursorPrivate EBookClientCursorPrivate;

struct _EBookClient;

/**
 * EBookClientCursor:
 *
 * Contains only private data.
 *
 * Since: 3.12
 */
struct _EBookClientCursor {
	/*< private >*/
	GObject parent;
	EBookClientCursorPrivate *priv;
};

/**
 * EBookClientCursorClass:
 * @refresh: The class handler for the #EBookClientCursor::refresh signal
 *
 * The cursor class structure.
 *
 * Since: 3.12
 */
struct _EBookClientCursorClass {
	/*< private >*/
	GObjectClass parent_class;

	/*< public >*/

	/* Signals */
	void		(* refresh) (EBookClientCursor *cursor);
};

GType		e_book_client_cursor_get_type	(void) G_GNUC_CONST;
struct _EBookClient *
		e_book_client_cursor_ref_client	(EBookClientCursor *cursor);
const gchar * const *
		e_book_client_cursor_get_alphabet
						(EBookClientCursor *cursor,
						 gint *n_labels,
						 gint *underflow,
						 gint *inflow,
						 gint *overflow);
gint		e_book_client_cursor_get_total	(EBookClientCursor *cursor);
gint		e_book_client_cursor_get_position
						(EBookClientCursor *cursor);
void		e_book_client_cursor_set_sexp	(EBookClientCursor *cursor,
						 const gchar *sexp,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_cursor_set_sexp_finish
						(EBookClientCursor *cursor,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_book_client_cursor_set_sexp_sync
						(EBookClientCursor *cursor,
						 const gchar *sexp,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_cursor_step	(EBookClientCursor *cursor,
						 EBookCursorStepFlags flags,
						 EBookCursorOrigin origin,
						 gint count,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gint		e_book_client_cursor_step_finish
						(EBookClientCursor *cursor,
						 GAsyncResult *result,
						 GSList **out_contacts,
						 GError **error);
gint		e_book_client_cursor_step_sync	(EBookClientCursor *cursor,
						 EBookCursorStepFlags flags,
						 EBookCursorOrigin origin,
						 gint count,
						 GSList **out_contacts,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_cursor_set_alphabetic_index
						(EBookClientCursor *cursor,
						 gint index,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_cursor_set_alphabetic_index_finish
						(EBookClientCursor *cursor,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_book_client_cursor_set_alphabetic_index_sync
						(EBookClientCursor *cursor,
						 gint index,
						 GCancellable *cancellable,
						 GError **error);
gint		e_book_client_cursor_get_contact_alphabetic_index
						(EBookClientCursor *cursor,
						 EContact *contact);

G_END_DECLS

#endif /* E_BOOK_CLIENT_CURSOR_H */
