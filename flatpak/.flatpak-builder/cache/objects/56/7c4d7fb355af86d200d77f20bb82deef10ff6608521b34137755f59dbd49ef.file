/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2011 Red Hat, Inc. (www.redhat.com)
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

#if !defined (__LIBEBOOK_H_INSIDE__) && !defined (LIBEBOOK_COMPILATION)
#error "Only <libebook/libebook.h> should be included directly."
#endif

#ifndef E_BOOK_CLIENT_VIEW_H
#define E_BOOK_CLIENT_VIEW_H

#include <glib-object.h>
#include <libebook-contacts/libebook-contacts.h>

/* Standard GObject macros */
#define E_TYPE_BOOK_CLIENT_VIEW \
	(e_book_client_view_get_type ())
#define E_BOOK_CLIENT_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_BOOK_CLIENT_VIEW, EBookClientView))
#define E_BOOK_CLIENT_VIEW_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_BOOK_CLIENT_VIEW, EBookClientViewClass))
#define E_IS_BOOK_CLIENT_VIEW(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_BOOK_CLIENT_VIEW))
#define E_IS_BOOK_CLIENT_VIEW_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_BOOK_CLIENT_VIEW))
#define E_BOOK_CLIENT_VIEW_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_BOOK_CLIENT_VIEW, EBookClientViewClass))

G_BEGIN_DECLS

typedef struct _EBookClientView EBookClientView;
typedef struct _EBookClientViewClass EBookClientViewClass;
typedef struct _EBookClientViewPrivate EBookClientViewPrivate;

struct _EBookClient;

/**
 * EBookClientView:
 *
 * Contains only private data the should be read and manipulated using the
 * functions below.
 *
 * Since: 3.2
 **/
struct _EBookClientView {
	/*< private >*/
	GObject parent;
	EBookClientViewPrivate *priv;
};

/**
 * EBookClientViewClass:
 * @objects_added: Signal emitted when contacts are added in the view
 * @objects_removed: Signal emitted when contacts are removed from the view
 * @objects_modified: Signal emitted when contacts in the view are modified
 * @progress: Signal emitted intermittently while loading a view after calling e_book_client_view_start()
 * @complete: Notification that loading a view has completed, after calling e_book_client_view_start()
 *
 * Class structure for the #EBookClient class.
 *
 * Since: 3.2
 **/
struct _EBookClientViewClass {
	/*< private >*/
	GObjectClass parent_class;

	/*< public >*/
	/* Signals */
	void		(*objects_added)	(EBookClientView *client_view,
						 const GSList *objects);
	void		(*objects_modified)	(EBookClientView *client_view,
						 const GSList *objects);
	void		(*objects_removed)	(EBookClientView *client_view,
						 const GSList *uids);
	void		(*progress)		(EBookClientView *client_view,
						 guint percent,
						 const gchar *message);
	void		(*complete)		(EBookClientView *client_view,
						 const GError *error);
};

GType		e_book_client_view_get_type	(void) G_GNUC_CONST;
struct _EBookClient *
		e_book_client_view_ref_client	(EBookClientView *client_view);
GDBusConnection *
		e_book_client_view_get_connection
						(EBookClientView *client_view);
const gchar *	e_book_client_view_get_object_path
						(EBookClientView *client_view);
gboolean	e_book_client_view_is_running	(EBookClientView *client_view);
void		e_book_client_view_set_fields_of_interest
						(EBookClientView *client_view,
						 const GSList *fields_of_interest,
						 GError **error);
void		e_book_client_view_start	(EBookClientView *client_view,
						 GError **error);
void		e_book_client_view_stop		(EBookClientView *client_view,
						 GError **error);
void		e_book_client_view_set_flags	(EBookClientView *client_view,
						 EBookClientViewFlags flags,
						 GError **error);

#ifndef EDS_DISABLE_DEPRECATED
struct _EBookClient *
		e_book_client_view_get_client	(EBookClientView *client_view);
#endif /* EDS_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* E_BOOK_CLIENT_VIEW_H */
