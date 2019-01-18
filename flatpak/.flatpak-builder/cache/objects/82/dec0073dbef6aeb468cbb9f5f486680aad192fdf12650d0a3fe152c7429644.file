/*
 * module-webdav-backend.c
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

#include "evolution-data-server-config.h"

#include <libebackend/libebackend.h>
#include <libedataserver/libedataserver.h>

/* Standard GObject macros */
#define E_TYPE_WEBDAV_BACKEND \
	(e_webdav_backend_get_type ())
#define E_WEBDAV_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_WEBDAV_BACKEND, EWebDAVBackend))
#define E_IS_WEBDAV_BACKEND(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_WEBDAV_BACKEND))

typedef struct _EWebDAVBackend EWebDAVBackend;
typedef struct _EWebDAVBackendClass EWebDAVBackendClass;

typedef struct _EWebDAVBackendFactory EWebDAVBackendFactory;
typedef struct _EWebDAVBackendFactoryClass EWebDAVBackendFactoryClass;

struct _EWebDAVBackend {
	EWebDAVCollectionBackend parent;
};

struct _EWebDAVBackendClass {
	EWebDAVCollectionBackendClass parent_class;
};

struct _EWebDAVBackendFactory {
	ECollectionBackendFactory parent;
};

struct _EWebDAVBackendFactoryClass {
	ECollectionBackendFactoryClass parent_class;
};

/* Module Entry Points */
void e_module_load (GTypeModule *type_module);
void e_module_unload (GTypeModule *type_module);

/* Forward Declarations */
GType e_webdav_backend_get_type (void);
GType e_webdav_backend_factory_get_type (void);

G_DEFINE_DYNAMIC_TYPE (
	EWebDAVBackend,
	e_webdav_backend,
	E_TYPE_WEBDAV_COLLECTION_BACKEND)

G_DEFINE_DYNAMIC_TYPE (
	EWebDAVBackendFactory,
	e_webdav_backend_factory,
	E_TYPE_COLLECTION_BACKEND_FACTORY)

static ESourceAuthenticationResult
webdav_backend_authenticate_sync (EBackend *backend,
				    const ENamedParameters *credentials,
				    gchar **out_certificate_pem,
				    GTlsCertificateFlags *out_certificate_errors,
				    GCancellable *cancellable,
				    GError **error)
{
	ESourceCollection *collection_extension;
	ESource *source;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), E_SOURCE_AUTHENTICATION_ERROR);

	source = e_backend_get_source (backend);

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_GOA)) {
		ESourceGoa *goa_extension;

		goa_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_GOA);

		return e_webdav_collection_backend_discover_sync (E_WEBDAV_COLLECTION_BACKEND (backend),
			e_source_goa_get_calendar_url (goa_extension),
			e_source_goa_get_contacts_url (goa_extension),
			credentials, out_certificate_pem, out_certificate_errors, cancellable, error);
	}

	collection_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_COLLECTION);

	return e_webdav_collection_backend_discover_sync (E_WEBDAV_COLLECTION_BACKEND (backend),
		e_source_collection_get_calendar_url (collection_extension),
		e_source_collection_get_contacts_url (collection_extension),
		credentials, out_certificate_pem, out_certificate_errors, cancellable, error);
}

static void
e_webdav_backend_class_init (EWebDAVBackendClass *class)
{
	EBackendClass *backend_class;

	backend_class = E_BACKEND_CLASS (class);
	backend_class->authenticate_sync = webdav_backend_authenticate_sync;
}

static void
e_webdav_backend_class_finalize (EWebDAVBackendClass *class)
{
}

static void
e_webdav_backend_init (EWebDAVBackend *backend)
{
}

static void
e_webdav_backend_factory_class_init (EWebDAVBackendFactoryClass *class)
{
	ECollectionBackendFactoryClass *factory_class;

	factory_class = E_COLLECTION_BACKEND_FACTORY_CLASS (class);
	factory_class->factory_name = "webdav";
	factory_class->backend_type = E_TYPE_WEBDAV_BACKEND;
}

static void
e_webdav_backend_factory_class_finalize (EWebDAVBackendFactoryClass *class)
{
}

static void
e_webdav_backend_factory_init (EWebDAVBackendFactory *factory)
{
}

G_MODULE_EXPORT void
e_module_load (GTypeModule *type_module)
{
	e_webdav_backend_register_type (type_module);
	e_webdav_backend_factory_register_type (type_module);
}

G_MODULE_EXPORT void
e_module_unload (GTypeModule *type_module)
{
}
