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
 * Authors: Chris Toshok (toshok@ximian.com)
 */

#if !defined (__LIBEBOOK_H_INSIDE__) && !defined (LIBEBOOK_COMPILATION)
#error "Only <libebook/libebook.h> should be included directly."
#endif

#ifndef EDS_DISABLE_DEPRECATED

/* Do not generate bindings. */
#ifndef __GI_SCANNER__

#ifndef __E_BOOK_H__
#define __E_BOOK_H__

#include <libedataserver/libedataserver.h>

#include <libebook-contacts/libebook-contacts.h>
#include <libebook/e-book-view.h>
#include <libebook/e-book-types.h>

#define E_TYPE_BOOK        (e_book_get_type ())
#define E_BOOK(o)          (G_TYPE_CHECK_INSTANCE_CAST ((o), E_TYPE_BOOK, EBook))
#define E_BOOK_CLASS(k)    (G_TYPE_CHECK_CLASS_CAST ((k), E_TYPE_BOOK, EBookClass))
#define E_IS_BOOK(o)       (G_TYPE_CHECK_INSTANCE_TYPE ((o), E_TYPE_BOOK))
#define E_IS_BOOK_CLASS(k) (G_TYPE_CHECK_CLASS_TYPE ((k), E_TYPE_BOOK))
#define E_BOOK_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), E_TYPE_BOOK, EBookClass))

G_BEGIN_DECLS

typedef struct _EBook        EBook;
typedef struct _EBookClass   EBookClass;
typedef struct _EBookPrivate EBookPrivate;

typedef void (*EBookCallback) (EBook *book, EBookStatus status, gpointer closure);

/**
 * EBookAsyncCallback:
 * @book: an #EBook
 * @error: a #GError or %NULL
 * @closure: the callback closure
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use #EBookClient instead 
 **/
typedef void (*EBookAsyncCallback) (EBook *book, const GError *error, gpointer closure);

/**
 * EBookOpenProgressCallback:
 * @book: an #EBook
 * @status_message: a status message
 * @percent: percent complete (0 - 100)
 * @closure: the callback closure
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use #EBookClient instead
 **/
typedef void (*EBookOpenProgressCallback)     (EBook          *book,
					       const gchar     *status_message,
					       gshort           percent,
					       gpointer        closure);
typedef void (*EBookIdCallback)       (EBook *book, EBookStatus status, const gchar *id, gpointer closure);
typedef void (*EBookContactCallback)  (EBook *book, EBookStatus status, EContact *contact, gpointer closure);
typedef void (*EBookListCallback)     (EBook *book, EBookStatus status, GList *list, gpointer closure);
typedef void (*EBookBookViewCallback) (EBook *book, EBookStatus status, EBookView *book_view, gpointer closure);
typedef void (*EBookEListCallback)   (EBook *book, EBookStatus status, EList *list, gpointer closure);

/**
 * EBookIdAsyncCallback:
 * @book: an #EBook
 * @error: a #GError or %NULL
 * @id: a contact ID
 * @closure: the callback closure
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use #EBookClient instead
 **/
typedef void (*EBookIdAsyncCallback)       (EBook *book, const GError *error, const gchar *id, gpointer closure);

/**
 * EBookContactAsyncCallback:
 * @book: an #EBook
 * @error: a #GError or %NULL
 * @contact: an #EContact or %NULL
 * @closure: the callback closure
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use #EBookClient instead
 **/
typedef void (*EBookContactAsyncCallback)  (EBook *book, const GError *error, EContact *contact, gpointer closure);

/**
 * EBookListAsyncCallback:
 * @book: an #EBook
 * @error: a #GError or %NULL
 * @list: a #GList of results
 * @closure: the callback closure
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use #EBookClient instead
 **/
typedef void (*EBookListAsyncCallback)     (EBook *book, const GError *error, GList *list, gpointer closure);

/**
 * EBookBookViewAsyncCallback:
 * @book: an #EBook
 * @error: a #GError or %NULL
 * @book_view: an #EBookView
 * @closure: the callback closure
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use #EBookClient instead
 **/
typedef void (*EBookBookViewAsyncCallback) (EBook *book, const GError *error, EBookView *book_view, gpointer closure);

/**
 * EBookEListAsyncCallback:
 * @book: an #EBook
 * @error: a #GError or %NULL
 * @list: an #EList of results
 * @closure: the callback closure
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use #EBookClient instead
 **/
typedef void (*EBookEListAsyncCallback)   (EBook *book, const GError *error, EList *list, gpointer closure);

/**
 * EBook:
 *
 * The deprecated API for accessing the addressbook
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use #EBookClient instead 
 */
struct _EBook {
	/*< private >*/
	GObject       parent;
	EBookPrivate *priv;
};

/**
 * EBookClass:
 * @writable_status: deprecated
 * @connection_status: deprecated
 * @backend_died: deprecated
 *
 * Class structure for the deprecated API for accessing the addressbook
 *
 * Since: 2.32
 *
 * Deprecated: 3.2: Use #EBookClient instead 
 */
struct _EBookClass {
	/*< private >*/
	GObjectClass parent;

	/*< public >*/
	/*
	 * Signals.
	 */
	void (* writable_status) (EBook *book, gboolean writable);
	void (* connection_status) (EBook *book, gboolean connected);
	void (* backend_died)    (EBook *book);

	/*< private >*/
	/* Padding for future expansion */
	void (*_ebook_reserved0) (void);
	void (*_ebook_reserved1) (void);
	void (*_ebook_reserved2) (void);
	void (*_ebook_reserved3) (void);
	void (*_ebook_reserved4) (void);
};

/* Creating a new addressbook. */
EBook    *e_book_new                       (ESource *source, GError **error);

/* loading addressbooks */
gboolean e_book_open                       (EBook       *book,
					    gboolean     only_if_exists,
					    GError     **error);

gboolean    e_book_async_open                 (EBook         *book,
					    gboolean       only_if_exists,
					    EBookCallback  open_response,
					    gpointer       closure);

gboolean e_book_open_async                 (EBook              *book,
					    gboolean            only_if_exists,
					    EBookAsyncCallback  open_response,
					    gpointer            closure);

gboolean e_book_remove                     (EBook       *book,
					    GError     **error);
gboolean    e_book_async_remove               (EBook   *book,
					    EBookCallback cb,
					    gpointer closure);

gboolean e_book_remove_async               (EBook             *book,
					    EBookAsyncCallback cb,
					    gpointer           closure);

gboolean e_book_get_required_fields       (EBook       *book,
					    GList      **fields,
					    GError     **error);

gboolean e_book_async_get_required_fields (EBook              *book,
					    EBookEListCallback  cb,
					    gpointer            closure);

gboolean e_book_get_required_fields_async (EBook                  *book,
					   EBookEListAsyncCallback cb,
					   gpointer                closure);

gboolean e_book_get_supported_fields       (EBook       *book,
					    GList      **fields,
					    GError     **error);

gboolean    e_book_async_get_supported_fields (EBook              *book,
					    EBookEListCallback  cb,
					    gpointer            closure);

gboolean e_book_get_supported_fields_async (EBook                  *book,
					    EBookEListAsyncCallback cb,
					    gpointer                closure);

gboolean e_book_get_supported_auth_methods       (EBook       *book,
						  GList      **auth_methods,
						  GError     **error);

gboolean    e_book_async_get_supported_auth_methods (EBook              *book,
						  EBookEListCallback  cb,
						  gpointer            closure);

gboolean e_book_get_supported_auth_methods_async (EBook                  *book,
						  EBookEListAsyncCallback cb,
						  gpointer                closure);

/* Fetching contacts. */
gboolean e_book_get_contact                (EBook       *book,
					    const gchar  *id,
					    EContact   **contact,
					    GError     **error);

gboolean     e_book_async_get_contact         (EBook                 *book,
					    const gchar            *id,
					    EBookContactCallback   cb,
					    gpointer               closure);

gboolean  e_book_get_contact_async      (EBook                    *book,
					 const gchar              *id,
					 EBookContactAsyncCallback cb,
					 gpointer                  closure);

/* Deleting contacts. */
gboolean e_book_remove_contact             (EBook       *book,
					    const gchar  *id,
					    GError     **error);

gboolean    e_book_async_remove_contact       (EBook                 *book,
					    EContact              *contact,
					    EBookCallback          cb,
					    gpointer               closure);
gboolean    e_book_async_remove_contact_by_id (EBook                 *book,
					    const gchar           *id,
					    EBookCallback          cb,
					    gpointer               closure);

gboolean e_book_remove_contact_async        (EBook                *book,
					    EContact              *contact,
					    EBookAsyncCallback     cb,
					    gpointer               closure);
gboolean e_book_remove_contact_by_id_async (EBook                 *book,
					    const gchar           *id,
					    EBookAsyncCallback     cb,
					    gpointer               closure);

gboolean e_book_remove_contacts            (EBook       *book,
					    GList       *ids,
					    GError     **error);

gboolean    e_book_async_remove_contacts      (EBook                 *book,
					    GList                 *ids,
					    EBookCallback          cb,
					    gpointer               closure);

gboolean e_book_remove_contacts_async   (EBook                 *book,
					 GList                 *ids,
					 EBookAsyncCallback     cb,
					 gpointer               closure);

/* Adding contacts. */
gboolean e_book_add_contact                (EBook           *book,
					    EContact        *contact,
					    GError         **error);

gboolean e_book_async_add_contact          (EBook           *book,
					    EContact        *contact,
					    EBookIdCallback  cb,
					    gpointer         closure);

gboolean e_book_add_contact_async       (EBook                 *book,
					 EContact              *contact,
					 EBookIdAsyncCallback   cb,
					 gpointer               closure);

/* Modifying contacts. */
gboolean e_book_commit_contact             (EBook       *book,
					    EContact    *contact,
					    GError     **error);

gboolean e_book_async_commit_contact          (EBook                 *book,
					    EContact              *contact,
					    EBookCallback          cb,
					    gpointer               closure);

gboolean e_book_commit_contact_async    (EBook                 *book,
					 EContact              *contact,
					 EBookAsyncCallback     cb,
					 gpointer               closure);

/* Returns a live view of a query. */
gboolean e_book_get_book_view              (EBook       *book,
					    EBookQuery  *query,
					    GList       *requested_fields,
					    gint          max_results,
					    EBookView  **book_view,
					    GError     **error);

gboolean e_book_async_get_book_view           (EBook                 *book,
					    EBookQuery            *query,
					    GList                 *requested_fields,
					    gint                    max_results,
					    EBookBookViewCallback  cb,
					    gpointer               closure);

gboolean e_book_get_book_view_async     (EBook                     *book,
					 EBookQuery                *query,
					 GList                     *requested_fields,
					 gint                       max_results,
					 EBookBookViewAsyncCallback cb,
					 gpointer                   closure);

/* Returns a static snapshot of a query. */
gboolean e_book_get_contacts               (EBook       *book,
					    EBookQuery  *query,
					    GList      **contacts,
					    GError     **error);

gboolean     e_book_async_get_contacts        (EBook             *book,
					    EBookQuery        *query,
					    EBookListCallback  cb,
					    gpointer           closure);

gboolean  e_book_get_contacts_async     (EBook                 *book,
					 EBookQuery            *query,
					 EBookListAsyncCallback cb,
					 gpointer               closure);

/* Needed for syncing */
gboolean e_book_get_changes                (EBook       *book,
					    const gchar *changeid,
					    GList      **changes,
					    GError     **error);

gboolean    e_book_async_get_changes          (EBook             *book,
					    const gchar       *changeid,
					    EBookListCallback  cb,
					    gpointer           closure);

gboolean e_book_get_changes_async       (EBook                 *book,
					 const gchar           *changeid,
					 EBookListAsyncCallback cb,
					 gpointer               closure);

void     e_book_free_change_list           (GList       *change_list);

ESource    *e_book_get_source              (EBook       *book);

const gchar *e_book_get_static_capabilities (EBook    *book,
					    GError  **error);
gboolean    e_book_check_static_capability (EBook       *book,
					    const gchar  *cap);
gboolean    e_book_is_opened               (EBook       *book);
gboolean    e_book_is_writable             (EBook       *book);

gboolean    e_book_is_online               (EBook       *book);

/* Cancel a pending operation. */
gboolean    e_book_cancel                  (EBook   *book,
					    GError **error);

gboolean    e_book_cancel_async_op	   (EBook   *book,
					    GError **error);

/* Identity */
gboolean    e_book_get_self                (ESourceRegistry *registry, EContact **contact, EBook **book, GError **error);
gboolean    e_book_set_self                (EBook *book, EContact *contact, GError **error);
gboolean    e_book_is_self                 (EContact *contact);

GType        e_book_get_type                  (void);

G_END_DECLS

#endif /* __E_BOOK_H__ */

#endif /* __GI_SCANNER__ */

#endif /* EDS_DISABLE_DEPRECATED */
