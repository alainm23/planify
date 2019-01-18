/*
 * e-book-client.h
 *
 * Copyright (C) 2011 Red Hat, Inc. (www.redhat.com)
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
 */

#if !defined (__LIBEBOOK_H_INSIDE__) && !defined (LIBEBOOK_COMPILATION)
#error "Only <libebook/libebook.h> should be included directly."
#endif

#ifndef E_BOOK_CLIENT_H
#define E_BOOK_CLIENT_H

#include <libedataserver/libedataserver.h>

#include <libebook/e-book-client-view.h>
#include <libebook/e-book-client-cursor.h>
#include <libebook-contacts/libebook-contacts.h>

/* Standard GObject macros */
#define E_TYPE_BOOK_CLIENT \
	(e_book_client_get_type ())
#define E_BOOK_CLIENT(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_BOOK_CLIENT, EBookClient))
#define E_BOOK_CLIENT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_BOOK_CLIENT, EBookClientClass))
#define E_IS_BOOK_CLIENT(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_BOOK_CLIENT))
#define E_IS_BOOK_CLIENT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_BOOK_CLIENT))
#define E_BOOK_CLIENT_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_BOOK_CLIENT, EBookClientClass))

/**
 * BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS: (value "required-fields")
 *
 * FIXME: Document me.
 *
 * Since: 3.2
 **/
#define BOOK_BACKEND_PROPERTY_REQUIRED_FIELDS		"required-fields"

/**
 * BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS: (value "supported-fields")
 *
 * FIXME: Document me.
 *
 * Since: 3.2
 **/
#define BOOK_BACKEND_PROPERTY_SUPPORTED_FIELDS		"supported-fields"

G_BEGIN_DECLS

typedef struct _EBookClient EBookClient;
typedef struct _EBookClientClass EBookClientClass;
typedef struct _EBookClientPrivate EBookClientPrivate;

/**
 * EBookClient:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.2
 **/
struct _EBookClient {
	/*< private >*/
	EClient parent;
	EBookClientPrivate *priv;
};

/**
 * EBookClientClass:
 *
 * Class structure for the #EBookClient class.
 *
 * Since: 3.2
 **/
struct _EBookClientClass {
	/*< private >*/
	EClientClass parent_class;
};

GType		e_book_client_get_type		(void) G_GNUC_CONST;
EClient *	e_book_client_connect_sync	(ESource *source,
						 guint32 wait_for_connected_seconds,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_connect		(ESource *source,
						 guint32 wait_for_connected_seconds,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
EClient *	e_book_client_connect_finish	(GAsyncResult *result,
						 GError **error);
EClient *	e_book_client_connect_direct_sync
						(ESourceRegistry *registry,
						 ESource *source,
						 guint32 wait_for_connected_seconds,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_connect_direct	(ESource *source,
						 guint32 wait_for_connected_seconds,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
EClient *	e_book_client_connect_direct_finish
						(GAsyncResult *result,
						 GError **error);
gboolean	e_book_client_get_self		(ESourceRegistry *registry,
						 EContact **out_contact,
						 EBookClient **out_client,
						 GError **error);
gboolean	e_book_client_set_self		(EBookClient *client,
						 EContact *contact,
						 GError **error);
gboolean	e_book_client_is_self		(EContact *contact);
void		e_book_client_add_contact	(EBookClient *client,
						 EContact *contact,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_add_contact_finish
						(EBookClient *client,
						 GAsyncResult *result,
						 gchar **out_added_uid,
						 GError **error);
gboolean	e_book_client_add_contact_sync	(EBookClient *client,
						 EContact *contact,
						 gchar **out_added_uid,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_add_contacts	(EBookClient *client,
						 GSList *contacts,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_add_contacts_finish
						(EBookClient *client,
						 GAsyncResult *result,
						 GSList **out_added_uids,
						 GError **error);
gboolean	e_book_client_add_contacts_sync	(EBookClient *client,
						 GSList *contacts,
						 GSList **out_added_uids,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_modify_contact	(EBookClient *client,
						 EContact *contact,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_modify_contact_finish
						(EBookClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_book_client_modify_contact_sync
						(EBookClient *client,
						 EContact *contact,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_modify_contacts	(EBookClient *client,
						 GSList *contacts,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_modify_contacts_finish
						(EBookClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_book_client_modify_contacts_sync
						(EBookClient *client,
						 GSList *contacts,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_remove_contact	(EBookClient *client,
						 EContact *contact,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_remove_contact_finish
						(EBookClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_book_client_remove_contact_sync
						(EBookClient *client,
						 EContact *contact,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_remove_contact_by_uid
						(EBookClient *client,
						 const gchar *uid,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_remove_contact_by_uid_finish
						(EBookClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_book_client_remove_contact_by_uid_sync
						(EBookClient *client,
						 const gchar *uid,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_remove_contacts	(EBookClient *client,
						 const GSList *uids,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_remove_contacts_finish
						(EBookClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_book_client_remove_contacts_sync
						(EBookClient *client,
						 const GSList *uids,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_get_contact	(EBookClient *client,
						 const gchar *uid,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_get_contact_finish
						(EBookClient *client,
						 GAsyncResult *result,
						 EContact **out_contact,
						 GError **error);
gboolean	e_book_client_get_contact_sync	(EBookClient *client,
						 const gchar *uid,
						 EContact **out_contact,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_get_contacts	(EBookClient *client,
						 const gchar *sexp,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_get_contacts_finish
						(EBookClient *client,
						 GAsyncResult *result,
						 GSList **out_contacts,
						 GError **error);
gboolean	e_book_client_get_contacts_sync	(EBookClient *client,
						 const gchar *sexp,
						 GSList **out_contacts,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_get_contacts_uids	(EBookClient *client,
						 const gchar *sexp,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_get_contacts_uids_finish
						(EBookClient *client,
						 GAsyncResult *result,
						 GSList **out_contact_uids,
						 GError **error);
gboolean	e_book_client_get_contacts_uids_sync
						(EBookClient *client,
						 const gchar *sexp,
						 GSList **out_contact_uids,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_get_view		(EBookClient *client,
						 const gchar *sexp,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_get_view_finish	(EBookClient *client,
						 GAsyncResult *result,
						 EBookClientView **out_view,
						 GError **error);
gboolean	e_book_client_get_view_sync	(EBookClient *client,
						 const gchar *sexp,
						 EBookClientView **out_view,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_client_get_cursor	(EBookClient *client,
						 const gchar *sexp,
						 const EContactField *sort_fields,
						 const EBookCursorSortType *sort_types,
						 guint n_fields,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_book_client_get_cursor_finish	(EBookClient *client,
						 GAsyncResult *result,
						 EBookClientCursor **out_cursor,
						 GError **error);
gboolean	e_book_client_get_cursor_sync	(EBookClient *client,
						 const gchar *sexp,
						 const EContactField *sort_fields,
						 const EBookCursorSortType *sort_types,
						 guint n_fields,
						 EBookClientCursor **out_cursor,
						 GCancellable *cancellable,
						 GError **error);
const gchar *	e_book_client_get_locale	(EBookClient *client);

#ifndef EDS_DISABLE_DEPRECATED
/**
 * BOOK_BACKEND_PROPERTY_SUPPORTED_AUTH_METHODS: (value "supported-auth-methods")
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: The property is no longer supported.
 **/
#define BOOK_BACKEND_PROPERTY_SUPPORTED_AUTH_METHODS	"supported-auth-methods"

EBookClient *	e_book_client_new		(ESource *source,
						 GError **error);
#endif /* E_BOOK_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* E_BOOK_CLIENT_H */
