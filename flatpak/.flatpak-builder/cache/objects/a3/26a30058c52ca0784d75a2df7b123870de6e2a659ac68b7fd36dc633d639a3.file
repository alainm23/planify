/*
 * e-collection-backend.h
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

#if !defined (__LIBEBACKEND_H_INSIDE__) && !defined (LIBEBACKEND_COMPILATION)
#error "Only <libebackend/libebackend.h> should be included directly."
#endif

#ifndef E_COLLECTION_BACKEND_H
#define E_COLLECTION_BACKEND_H

#include <libebackend/e-backend.h>

/* Standard GObject macros */
#define E_TYPE_COLLECTION_BACKEND \
	(e_collection_backend_get_type ())
#define E_COLLECTION_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_COLLECTION_BACKEND, ECollectionBackend))
#define E_COLLECTION_BACKEND_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_COLLECTION_BACKEND, ECollectionBackendClass))
#define E_IS_COLLECTION_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_COLLECTION_BACKEND))
#define E_IS_COLLECTION_BACKEND_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_COLLECTION_BACKEND))
#define E_COLLECTION_BACKEND_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_COLLECTION_BACKEND, ECollectionBackendClass))

G_BEGIN_DECLS

struct _ESourceRegistryServer;

typedef struct _ECollectionBackend ECollectionBackend;
typedef struct _ECollectionBackendClass ECollectionBackendClass;
typedef struct _ECollectionBackendPrivate ECollectionBackendPrivate;

/**
 * ECollectionBackend:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ECollectionBackend {
	/*< private >*/
	EBackend parent;
	ECollectionBackendPrivate *priv;
};

struct _ECollectionBackendClass {
	/*< private >*/
	EBackendClass parent_class;

	/* Methods */
	void		(*populate)		(ECollectionBackend *backend);
	gchar *		(*dup_resource_id)	(ECollectionBackend *backend,
						 ESource *child_source);

	/* Signals */
	void		(*child_added)		(ECollectionBackend *backend,
						 ESource *child_source);
	void		(*child_removed)	(ECollectionBackend *backend,
						 ESource *child_source);

	/* More Methods (grouped separately to preserve the ABI) */
	gboolean	(*create_resource_sync)	(ECollectionBackend *backend,
						 ESource *source,
						 GCancellable *cancellable,
						 GError **error);
	void		(*create_resource)	(ECollectionBackend *backend,
						 ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*create_resource_finish)
						(ECollectionBackend *backend,
						 GAsyncResult *result,
						 GError **error);
	gboolean	(*delete_resource_sync)	(ECollectionBackend *backend,
						 ESource *source,
						 GCancellable *cancellable,
						 GError **error);
	void		(*delete_resource)	(ECollectionBackend *backend,
						 ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	gboolean	(*delete_resource_finish)
						(ECollectionBackend *backend,
						 GAsyncResult *result,
						 GError **error);

	/*< private >*/
	gpointer reserved[10];
};

GType		e_collection_backend_get_type	(void) G_GNUC_CONST;
ESource *	e_collection_backend_new_child	(ECollectionBackend *backend,
						 const gchar *resource_id);
gboolean	e_collection_backend_is_new_source
						(ECollectionBackend *backend,
						 ESource *source);
GProxyResolver *
		e_collection_backend_ref_proxy_resolver
						(ECollectionBackend *backend);
struct _ESourceRegistryServer *
		e_collection_backend_ref_server	(ECollectionBackend *backend);
const gchar *	e_collection_backend_get_cache_dir
						(ECollectionBackend *backend);
gchar *		e_collection_backend_dup_resource_id
						(ECollectionBackend *backend,
						 ESource *child_source);
GList *		e_collection_backend_claim_all_resources
						(ECollectionBackend *backend);
GList *		e_collection_backend_list_calendar_sources
						(ECollectionBackend *backend);
GList *		e_collection_backend_list_contacts_sources
						(ECollectionBackend *backend);
GList *		e_collection_backend_list_mail_sources
						(ECollectionBackend *backend);
gboolean	e_collection_backend_create_resource_sync
						(ECollectionBackend *backend,
						 ESource *source,
						 GCancellable *cancellable,
						 GError **error);
void		e_collection_backend_create_resource
						(ECollectionBackend *backend,
						 ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_collection_backend_create_resource_finish
						(ECollectionBackend *backend,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_collection_backend_delete_resource_sync
						(ECollectionBackend *backend,
						 ESource *source,
						 GCancellable *cancellable,
						 GError **error);
void		e_collection_backend_delete_resource
						(ECollectionBackend *backend,
						 ESource *source,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_collection_backend_delete_resource_finish
						(ECollectionBackend *backend,
						 GAsyncResult *result,
						 GError **error);
void		e_collection_backend_authenticate_children
						(ECollectionBackend *backend,
						 const ENamedParameters *credentials);
void		e_collection_backend_schedule_populate
						(ECollectionBackend *backend);

G_END_DECLS

#endif /* E_COLLECTION_BACKEND_H */

