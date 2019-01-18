/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * The Evolution addressbook client object.
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
 */

#if !defined (__LIBEBOOK_H_INSIDE__) && !defined (LIBEBOOK_COMPILATION)
#error "Only <libebook/libebook.h> should be included directly."
#endif

#ifndef EDS_DISABLE_DEPRECATED

/* Do not generate bindings. */
#ifndef __GI_SCANNER__

#ifndef E_BOOK_VIEW_H
#define E_BOOK_VIEW_H

#include <glib-object.h>
#include "e-book-types.h"

/* Standard GObject macros */
#define E_TYPE_BOOK_VIEW \
	(e_book_view_get_type ())
#define E_BOOK_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_BOOK_VIEW, EBookView))
#define E_BOOK_VIEW_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_BOOK_VIEW, EBookViewClass))
#define E_IS_BOOK_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_BOOK_VIEW))
#define E_IS_BOOK_VIEW_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_BOOK_VIEW))
#define E_BOOK_VIEW_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_BOOK_VIEW, EBookViewClass))

G_BEGIN_DECLS

typedef struct _EBookView EBookView;
typedef struct _EBookViewClass EBookViewClass;
typedef struct _EBookViewPrivate EBookViewPrivate;

struct _EBook;

/**
 * EBookView:
 *
 * Deprecated: 3.2: Use #EBookClientView instead.
 */
struct _EBookView {
	/*< private >*/
	GObject parent;
	EBookViewPrivate *priv;
};

/**
 * EBookViewClass:
 * @contacts_changed: Signal emitted when contacts in the view are modified
 * @contacts_removed: Signal emitted when contacts are removed from the view
 * @contacts_added: Signal emitted when contacts are added in the view
 * @sequence_complete: Notification that loading a view has completed, after calling e_book_view_start()
 * @view_complete: Notification that loading a view has completed, after calling e_book_view_start()
 * @status_message: Signal emitted intermittently while loading a view after calling e_book_view_start()
 *
 * Deprecated: 3.2: Use #EBookClientView instead.
 */
struct _EBookViewClass {
	/*< private >*/
	GObjectClass parent_class;

	/*< public >*/
	/* Signals */
	void		(*contacts_changed)	(EBookView *book_view,
						 const GList *contacts);
	void		(*contacts_removed)	(EBookView *book_view,
						 const GList *ids);
	void		(*contacts_added)	(EBookView *book_view,
						 const GList *contacts);
	void		(*sequence_complete)	(EBookView *book_view,
						 EBookViewStatus status);
	void		(*view_complete)	(EBookView *book_view,
						 EBookViewStatus status,
						 const gchar *error_msg);
	void		(*status_message)	(EBookView *book_view,
						 const gchar *message);

	/*< private >*/
	/* Padding for future expansion */
	void		(*_ebook_reserved0)	(void);
	void		(*_ebook_reserved1)	(void);
	void		(*_ebook_reserved2)	(void);
	void		(*_ebook_reserved3)	(void);
	void		(*_ebook_reserved4)	(void);
};

GType		e_book_view_get_type		(void);
struct _EBook *	e_book_view_get_book		(EBookView *book_view);
void		e_book_view_start		(EBookView *book_view);
void		e_book_view_stop		(EBookView *book_view);

G_END_DECLS

#endif /* E_BOOK_VIEW_H */

#endif /* __GI_SCANNER__ */

#endif /* EDS_DISABLE_DEPRECATED */
