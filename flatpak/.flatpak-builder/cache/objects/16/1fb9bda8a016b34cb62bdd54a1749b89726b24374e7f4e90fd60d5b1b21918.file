/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
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
 */

#if !defined (__LIBEDATA_BOOK_H_INSIDE__) && !defined (LIBEDATA_BOOK_COMPILATION)
#error "Only <libedata-book/libedata-book.h> should be included directly."
#endif

#ifndef E_BOOK_META_BACKEND_H
#define E_BOOK_META_BACKEND_H

#include <libebackend/libebackend.h>
#include <libedata-book/e-book-backend.h>
#include <libedata-book/e-book-cache.h>
#include <libebook-contacts/libebook-contacts.h>

/* Standard GObject macros */
#define E_TYPE_BOOK_META_BACKEND \
	(e_book_meta_backend_get_type ())
#define E_BOOK_META_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_BOOK_META_BACKEND, EBookMetaBackend))
#define E_BOOK_META_BACKEND_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_BOOK_META_BACKEND, EBookMetaBackendClass))
#define E_IS_BOOK_META_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_BOOK_META_BACKEND))
#define E_IS_BOOK_META_BACKEND_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_BOOK_META_BACKEND))
#define E_BOOK_META_BACKEND_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_BOOK_META_BACKEND, EBookMetaBackendClass))

G_BEGIN_DECLS

typedef struct _EBookMetaBackendInfo {
	gchar *uid;
	gchar *revision;
	gchar *object;
	gchar *extra;
} EBookMetaBackendInfo;

#define E_TYPE_BOOK_META_BACKEND_INFO (e_book_meta_backend_info_get_type ())

GType		e_book_meta_backend_info_get_type
						(void) G_GNUC_CONST;
EBookMetaBackendInfo *
		e_book_meta_backend_info_new	(const gchar *uid,
						 const gchar *revision,
						 const gchar *object,
						 const gchar *extra);
EBookMetaBackendInfo *
		e_book_meta_backend_info_copy	(const EBookMetaBackendInfo *src);
void		e_book_meta_backend_info_free	(gpointer ptr /* EBookMetaBackendInfo * */);

typedef struct _EBookMetaBackend EBookMetaBackend;
typedef struct _EBookMetaBackendClass EBookMetaBackendClass;
typedef struct _EBookMetaBackendPrivate EBookMetaBackendPrivate;

/**
 * EBookMetaBackend:
 *
 * Contains only private data that should be read and manipulated using
 * the functions below.
 *
 * Since: 3.26
 **/
struct _EBookMetaBackend {
	/*< private >*/
	EBookBackend parent;
	EBookMetaBackendPrivate *priv;
};

/**
 * EBookMetaBackendClass:
 *
 * Class structure for the #EBookMetaBackend class.
 *
 * Since: 3.26
 */
struct _EBookMetaBackendClass {
	/*< private >*/
	EBookBackendClass parent_class;

	/* For Direct Read Access */
	const gchar *backend_module_filename;
	const gchar *backend_factory_type_name;

	/* Virtual methods */
	gboolean	(* connect_sync)	(EBookMetaBackend *meta_backend,
						 const ENamedParameters *credentials,
						 ESourceAuthenticationResult *out_auth_result,
						 gchar **out_certificate_pem,
						 GTlsCertificateFlags *out_certificate_errors,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(* disconnect_sync)	(EBookMetaBackend *meta_backend,
						 GCancellable *cancellable,
						 GError **error);

	gboolean	(* get_changes_sync)	(EBookMetaBackend *meta_backend,
						 const gchar *last_sync_tag,
						 gboolean is_repeat,
						 gchar **out_new_sync_tag,
						 gboolean *out_repeat,
						 GSList **out_created_objects, /* EBookMetaBackendInfo * */
						 GSList **out_modified_objects, /* EBookMetaBackendInfo * */
						 GSList **out_removed_objects, /* EBookMetaBackendInfo * */
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(* list_existing_sync)	(EBookMetaBackend *meta_backend,
						 gchar **out_new_sync_tag,
						 GSList **out_existing_objects, /* EBookMetaBackendInfo * */
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(* load_contact_sync)	(EBookMetaBackend *meta_backend,
						 const gchar *uid,
						 const gchar *extra,
						 EContact **out_contact,
						 gchar **out_extra,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(* save_contact_sync)	(EBookMetaBackend *meta_backend,
						 gboolean overwrite_existing,
						 EConflictResolution conflict_resolution,
						 /* const */ EContact *contact,
						 const gchar *extra,
						 gchar **out_new_uid,
						 gchar **out_new_extra,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(* remove_contact_sync)	(EBookMetaBackend *meta_backend,
						 EConflictResolution conflict_resolution,
						 const gchar *uid,
						 const gchar *extra,
						 const gchar *object,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(* search_sync)		(EBookMetaBackend *meta_backend,
						 const gchar *expr,
						 gboolean meta_contact,
						 GSList **out_contacts, /* EContact * */
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(* search_uids_sync)	(EBookMetaBackend *meta_backend,
						 const gchar *expr,
						 GSList **out_uids, /* gchar * */
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(* requires_reconnect)	(EBookMetaBackend *meta_backend);

	/* Signals */
	void		(* source_changed)	(EBookMetaBackend *meta_backend);

	gboolean	(* get_ssl_error_details)
						(EBookMetaBackend *meta_backend,
						 gchar **out_certificate_pem,
						 GTlsCertificateFlags *out_certificate_errors);

	/* Padding for future expansion */
	gpointer reserved[9];
};

GType		e_book_meta_backend_get_type	(void) G_GNUC_CONST;

const gchar *	e_book_meta_backend_get_capabilities
						(EBookMetaBackend *meta_backend);
void		e_book_meta_backend_set_ever_connected
						(EBookMetaBackend *meta_backend,
						 gboolean value);
gboolean	e_book_meta_backend_get_ever_connected
						(EBookMetaBackend *meta_backend);
void		e_book_meta_backend_set_connected_writable
						(EBookMetaBackend *meta_backend,
						 gboolean value);
gboolean	e_book_meta_backend_get_connected_writable
						(EBookMetaBackend *meta_backend);
gchar *		e_book_meta_backend_dup_sync_tag(EBookMetaBackend *meta_backend);
void		e_book_meta_backend_set_cache	(EBookMetaBackend *meta_backend,
						 EBookCache *cache);
EBookCache *	e_book_meta_backend_ref_cache	(EBookMetaBackend *meta_backend);
gboolean	e_book_meta_backend_inline_local_photos_sync
						(EBookMetaBackend *meta_backend,
						 EContact *contact,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_store_inline_photos_sync
						(EBookMetaBackend *meta_backend,
						 EContact *contact,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_empty_cache_sync
						(EBookMetaBackend *meta_backend,
						 GCancellable *cancellable,
						 GError **error);
void		e_book_meta_backend_schedule_refresh
						(EBookMetaBackend *meta_backend);
gboolean	e_book_meta_backend_refresh_sync
						(EBookMetaBackend *meta_backend,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_ensure_connected_sync
						(EBookMetaBackend *meta_backend,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_split_changes_sync
						(EBookMetaBackend *meta_backend,
						 GSList *objects, /* EBookMetaBackendInfo * */
						 GSList **out_created_objects, /* EBookMetaBackendInfo * */
						 GSList **out_modified_objects, /* EBookMetaBackendInfo * */
						 GSList **out_removed_objects, /* EBookMetaBackendInfo * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_process_changes_sync
						(EBookMetaBackend *meta_backend,
						 const GSList *created_objects, /* EBookMetaBackendInfo * */
						 const GSList *modified_objects, /* EBookMetaBackendInfo * */
						 const GSList *removed_objects, /* EBookMetaBackendInfo * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_connect_sync(EBookMetaBackend *meta_backend,
						 const ENamedParameters *credentials,
						 ESourceAuthenticationResult *out_auth_result,
						 gchar **out_certificate_pem,
						 GTlsCertificateFlags *out_certificate_errors,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_disconnect_sync
						(EBookMetaBackend *meta_backend,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_get_changes_sync
						(EBookMetaBackend *meta_backend,
						 const gchar *last_sync_tag,
						 gboolean is_repeat,
						 gchar **out_new_sync_tag,
						 gboolean *out_repeat,
						 GSList **out_created_objects, /* EBookMetaBackendInfo * */
						 GSList **out_modified_objects, /* EBookMetaBackendInfo * */
						 GSList **out_removed_objects, /* EBookMetaBackendInfo * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_list_existing_sync
						(EBookMetaBackend *meta_backend,
						 gchar **out_new_sync_tag,
						 GSList **out_existing_objects, /* EBookMetaBackendInfo * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_load_contact_sync
						(EBookMetaBackend *meta_backend,
						 const gchar *uid,
						 const gchar *extra,
						 EContact **out_contact,
						 gchar **out_extra,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_save_contact_sync
						(EBookMetaBackend *meta_backend,
						 gboolean overwrite_existing,
						 EConflictResolution conflict_resolution,
						 /* const */ EContact *contact,
						 const gchar *extra,
						 gchar **out_new_uid,
						 gchar **out_new_extra,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_remove_contact_sync
						(EBookMetaBackend *meta_backend,
						 EConflictResolution conflict_resolution,
						 const gchar *uid,
						 const gchar *extra,
						 const gchar *object,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_search_sync	(EBookMetaBackend *meta_backend,
						 const gchar *expr,
						 gboolean meta_contact,
						 GSList **out_contacts, /* EContact * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_search_uids_sync
						(EBookMetaBackend *meta_backend,
						 const gchar *expr,
						 GSList **out_uids, /* gchar * */
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_book_meta_backend_requires_reconnect
						(EBookMetaBackend *meta_backend);
gboolean	e_book_meta_backend_get_ssl_error_details
						(EBookMetaBackend *meta_backend,
						 gchar **out_certificate_pem,
						 GTlsCertificateFlags *out_certificate_errors);

G_END_DECLS

#endif /* E_BOOK_META_BACKEND_H */
