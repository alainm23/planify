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
 *
 * Authors: Nat Friedman <nat@ximian.com>
 *          Ross Burton <ross@linux.intel.com>
 */

#if !defined (__LIBEDATA_BOOK_H_INSIDE__) && !defined (LIBEDATA_BOOK_COMPILATION)
#error "Only <libedata-book/libedata-book.h> should be included directly."
#endif

#ifndef E_DATA_BOOK_VIEW_H
#define E_DATA_BOOK_VIEW_H

#include <libebook-contacts/libebook-contacts.h>

#include <libedata-book/e-book-backend-sexp.h>

/* Standard GObject macros */
#define E_TYPE_DATA_BOOK_VIEW \
	(e_data_book_view_get_type ())
#define E_DATA_BOOK_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_DATA_BOOK_VIEW, EDataBookView))
#define E_DATA_BOOK_VIEW_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_DATA_BOOK_VIEW, EDataBookViewClass))
#define E_IS_DATA_BOOK_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_DATA_BOOK_VIEW))
#define E_IS_DATA_BOOK_VIEW_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_DATA_BOOK_VIEW))
#define E_DATA_BOOK_VIEW_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_DATA_BOOK_VIEW, EDataBookViewClass))

G_BEGIN_DECLS

struct _EBookBackend;

typedef struct _EDataBookView EDataBookView;
typedef struct _EDataBookViewClass EDataBookViewClass;
typedef struct _EDataBookViewPrivate EDataBookViewPrivate;

struct _EDataBookView {
	GObject parent;
	EDataBookViewPrivate *priv;
};

struct _EDataBookViewClass {
	GObjectClass parent;
};

GType		e_data_book_view_get_type	(void) G_GNUC_CONST;
EDataBookView *	e_data_book_view_new		(struct _EBookBackend *backend,
						 EBookBackendSExp *sexp,
						 GDBusConnection *connection,
						 const gchar *object_path,
						 GError **error);
struct _EBookBackend *
		e_data_book_view_get_backend	(EDataBookView *view);
GDBusConnection *
		e_data_book_view_get_connection	(EDataBookView *view);
const gchar *	e_data_book_view_get_object_path
						(EDataBookView *view);
EBookBackendSExp *
		e_data_book_view_get_sexp	(EDataBookView *view);
EBookClientViewFlags
		e_data_book_view_get_flags	(EDataBookView *view);
void		e_data_book_view_notify_update	(EDataBookView *view,
						 const EContact *contact);

void		e_data_book_view_notify_update_vcard
						(EDataBookView *view,
						 const gchar *id,
						 const gchar *vcard);
void		e_data_book_view_notify_update_prefiltered_vcard
						(EDataBookView *view,
						 const gchar *id,
						 const gchar *vcard);

void		e_data_book_view_notify_remove	(EDataBookView *view,
						 const gchar *id);
void		e_data_book_view_notify_complete
						(EDataBookView *view,
						 const GError *error);
void		e_data_book_view_notify_progress
						(EDataBookView *view,
						 guint percent,
						 const gchar *message);

GHashTable *	e_data_book_view_get_fields_of_interest
						(EDataBookView *view);

G_END_DECLS

#endif /* E_DATA_BOOK_VIEW_H */
