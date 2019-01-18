/*
 * Copyright (C) 2015 Red Hat, Inc. (www.redhat.com)
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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_CREDENTIALS_PROVIDER_H
#define E_SOURCE_CREDENTIALS_PROVIDER_H

#include <glib.h>
#include <glib-object.h>
#include <gio/gio.h>

#include <libedataserver/e-data-server-util.h>
#include <libedataserver/e-source.h>
#include <libedataserver/e-source-registry.h>
#include <libedataserver/e-source-credentials-provider-impl.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_CREDENTIALS_PROVIDER \
	(e_source_credentials_provider_get_type ())
#define E_SOURCE_CREDENTIALS_PROVIDER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_CREDENTIALS_PROVIDER, ESourceCredentialsProvider))
#define E_SOURCE_CREDENTIALS_PROVIDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_CREDENTIALS_PROVIDER, ESourceCredentialsProviderClass))
#define E_IS_SOURCE_CREDENTIALS_PROVIDER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_CREDENTIALS_PROVIDER))
#define E_IS_SOURCE_CREDENTIALS_PROVIDER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_CREDENTIALS_PROVIDER))
#define E_SOURCE_CREDENTIALS_PROVIDER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_CREDENTIALS_PROVIDER, ESourceCredentialsProviderClass))

G_BEGIN_DECLS

typedef struct _ESourceCredentialsProvider ESourceCredentialsProvider;
typedef struct _ESourceCredentialsProviderClass ESourceCredentialsProviderClass;
typedef struct _ESourceCredentialsProviderPrivate ESourceCredentialsProviderPrivate;

/**
 * ESourceCredentialsProvider:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.16
 **/
struct _ESourceCredentialsProvider {
	/*< private >*/
	GObject parent;
	ESourceCredentialsProviderPrivate *priv;
};

struct _ESourceCredentialsProviderClass {
	GObjectClass parent_class;

	ESource *	(*ref_source)	(ESourceCredentialsProvider *provider,
					 const gchar *uid);
};

GType		e_source_credentials_provider_get_type	(void) G_GNUC_CONST;
ESourceCredentialsProvider *
		e_source_credentials_provider_new	(ESourceRegistry *registry);
GObject *	e_source_credentials_provider_ref_registry
							(ESourceCredentialsProvider *provider);
gboolean	e_source_credentials_provider_register_impl
							(ESourceCredentialsProvider *provider,
							 ESourceCredentialsProviderImpl *provider_impl);
void		e_source_credentials_provider_unregister_impl
							(ESourceCredentialsProvider *provider,
							 ESourceCredentialsProviderImpl *provider_impl);
ESource *	e_source_credentials_provider_ref_source
							(ESourceCredentialsProvider *provider,
							 const gchar *uid);
ESource *	e_source_credentials_provider_ref_credentials_source
							(ESourceCredentialsProvider *provider,
							 ESource *source);
gboolean	e_source_credentials_provider_can_store	(ESourceCredentialsProvider *provider,
							 ESource *source);
gboolean	e_source_credentials_provider_can_prompt(ESourceCredentialsProvider *provider,
							 ESource *source);
gboolean	e_source_credentials_provider_lookup_sync
							(ESourceCredentialsProvider *provider,
							 ESource *source,
							 GCancellable *cancellable,
							 ENamedParameters **out_credentials,
							 GError **error);
void		e_source_credentials_provider_lookup	(ESourceCredentialsProvider *provider,
							 ESource *source,
							 GCancellable *cancellable,
							 GAsyncReadyCallback callback,
							 gpointer user_data);
gboolean	e_source_credentials_provider_lookup_finish
							(ESourceCredentialsProvider *provider,
							 GAsyncResult *result,
							 ENamedParameters **out_credentials,
							 GError **error);
gboolean	e_source_credentials_provider_store_sync(ESourceCredentialsProvider *provider,
							 ESource *source,
							 const ENamedParameters *credentials,
							 gboolean permanently,
							 GCancellable *cancellable,
							 GError **error);
void		e_source_credentials_provider_store	(ESourceCredentialsProvider *provider,
							 ESource *source,
							 const ENamedParameters *credentials,
							 gboolean permanently,
							 GCancellable *cancellable,
							 GAsyncReadyCallback callback,
							 gpointer user_data);
gboolean	e_source_credentials_provider_store_finish
							(ESourceCredentialsProvider *provider,
							 GAsyncResult *result,
							 GError **error);
gboolean	e_source_credentials_provider_delete_sync
							(ESourceCredentialsProvider *provider,
							 ESource *source,
							 GCancellable *cancellable,
							 GError **error);
void		e_source_credentials_provider_delete	(ESourceCredentialsProvider *provider,
							 ESource *source,
							 GCancellable *cancellable,
							 GAsyncReadyCallback callback,
							 gpointer user_data);
gboolean	e_source_credentials_provider_delete_finish
							(ESourceCredentialsProvider *provider,
							 GAsyncResult *result,
							 GError **error);

G_END_DECLS

#endif /* E_SOURCE_CREDENTIALS_PROVIDER_H */
