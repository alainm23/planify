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
 *
 */

#if !defined (__LIBEBACKEND_H_INSIDE__) && !defined (LIBEBACKEND_COMPILATION)
#error "Only <libebackend/libebackend.h> should be included directly."
#endif

#ifndef E_WEBDAV_COLLECTION_BACKEND_H
#define E_WEBDAV_COLLECTION_BACKEND_H

#include <libebackend/e-collection-backend.h>
#include <libedataserver/libedataserver.h>

/* Standard GObject macros */
#define E_TYPE_WEBDAV_COLLECTION_BACKEND \
	(e_webdav_collection_backend_get_type ())
#define E_WEBDAV_COLLECTION_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_WEBDAV_COLLECTION_BACKEND, EWebDAVCollectionBackend))
#define E_WEBDAV_COLLECTION_BACKEND_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_WEBDAV_COLLECTION_BACKEND, EWebDAVCollectionBackendClass))
#define E_IS_WEBDAV_COLLECTION_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_WEBDAV_COLLECTION_BACKEND))
#define E_IS_WEBDAV_COLLECTION_BACKEND_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_WEBDAV_COLLECTION_BACKEND))
#define E_WEBDAV_COLLECTION_BACKEND_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_WEBDAV_COLLECTION_BACKEND, EWebDAVCollectionBackendClass))

G_BEGIN_DECLS

typedef struct _EWebDAVCollectionBackend EWebDAVCollectionBackend;
typedef struct _EWebDAVCollectionBackendClass EWebDAVCollectionBackendClass;
typedef struct _EWebDAVCollectionBackendPrivate EWebDAVCollectionBackendPrivate;

/**
 * EWebDAVCollectionBackend:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.26
 **/
struct _EWebDAVCollectionBackend {
	/*< private >*/
	ECollectionBackend parent;
	EWebDAVCollectionBackendPrivate *priv;
};

struct _EWebDAVCollectionBackendClass {
	ECollectionBackendClass parent_class;

	gchar *		(* get_resource_id)	(EWebDAVCollectionBackend *webdav_backend,
						 ESource *source);
	gboolean	(* is_custom_source)	(EWebDAVCollectionBackend *webdav_backend,
						 ESource *source);
};

GType		e_webdav_collection_backend_get_type	(void);

gchar *		e_webdav_collection_backend_get_resource_id
						(EWebDAVCollectionBackend *webdav_backend,
						 ESource *source);
gboolean	e_webdav_collection_backend_is_custom_source
						(EWebDAVCollectionBackend *webdav_backend,
						 ESource *source);
ESourceAuthenticationResult
		e_webdav_collection_backend_discover_sync
						(EWebDAVCollectionBackend *webdav_backend,
						 const gchar *calendar_url,
						 const gchar *contacts_url,
						 const ENamedParameters *credentials,
						 gchar **out_certificate_pem,
						 GTlsCertificateFlags *out_certificate_errors,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* E_WEBDAV_COLLECTION_BACKEND_H */
