/*
 * e-source-registry-server.h
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

#ifndef E_SOURCE_REGISTRY_SERVER_H
#define E_SOURCE_REGISTRY_SERVER_H

#include <libedataserver/libedataserver.h>

#include <libebackend/e-backend-enums.h>
#include <libebackend/e-data-factory.h>
#include <libebackend/e-collection-backend.h>
#include <libebackend/e-collection-backend-factory.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_REGISTRY_SERVER \
	(e_source_registry_server_get_type ())
#define E_SOURCE_REGISTRY_SERVER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_REGISTRY_SERVER, ESourceRegistryServer))
#define E_SOURCE_REGISTRY_SERVER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_REGISTRY_SERVER, ESourceRegistryServerClass))
#define E_IS_SOURCE_REGISTRY_SERVER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_REGISTRY_SERVER))
#define E_IS_SOURCE_REGISTRY_SERVER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_REGISTRY_SERVER))
#define E_SOURCE_REGISTRY_SERVER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_REGISTRY_SERVER, ESourceRegistryServerClass))

/**
 * E_SOURCE_REGISTRY_SERVER_OBJECT_PATH:
 *
 * D-Bus object path of the data source server.
 *
 * Since: 3.6
 **/
#define E_SOURCE_REGISTRY_SERVER_OBJECT_PATH \
	"/org/gnome/evolution/dataserver/SourceManager"

/**
 * EDS_REGISTRY_MODULES:
 *
 * This environment variable configures where the registry
 * server loads it's backend modules from.
 */
#define EDS_REGISTRY_MODULES    "EDS_REGISTRY_MODULES"

G_BEGIN_DECLS

typedef struct _ESourceRegistryServer ESourceRegistryServer;
typedef struct _ESourceRegistryServerClass ESourceRegistryServerClass;
typedef struct _ESourceRegistryServerPrivate ESourceRegistryServerPrivate;

/**
 * ESourceRegistryServer:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceRegistryServer {
	/*< private >*/
	EDataFactory parent;
	ESourceRegistryServerPrivate *priv;
};

struct _ESourceRegistryServerClass {
	EDataFactoryClass parent_class;

	/* Signals */
	void		(*load_error)		(ESourceRegistryServer *server,
						 GFile *file,
						 const GError *error);
	void		(*files_loaded)		(ESourceRegistryServer *server);
	void		(*source_added)		(ESourceRegistryServer *server,
						 ESource *source);
	void		(*source_removed)	(ESourceRegistryServer *server,
						 ESource *source);
	gboolean	(*tweak_key_file)	(ESourceRegistryServer *server,
						 GKeyFile *key_file,
						 const gchar *uid);

	/* Reserved slots. */
	gpointer reserved[16];
};

GType		e_source_registry_server_get_type
						(void) G_GNUC_CONST;
EDBusServer *	e_source_registry_server_new	(void);
ESourceCredentialsProvider *
		e_source_registry_server_ref_credentials_provider
						(ESourceRegistryServer *server);
EOAuth2Services *
		e_source_registry_server_get_oauth2_services
						(ESourceRegistryServer *server);
void		e_source_registry_server_add_source
						(ESourceRegistryServer *server,
						 ESource *source);
void		e_source_registry_server_remove_source
						(ESourceRegistryServer *server,
						 ESource *source);
gboolean	e_source_registry_server_load_directory
						(ESourceRegistryServer *server,
						 const gchar *path,
						 ESourcePermissionFlags flags,
						 GError **error);
gboolean	e_source_registry_server_load_resource
						(ESourceRegistryServer *server,
						 GResource *resource,
						 const gchar *path,
						 ESourcePermissionFlags flags,
						 GError **error);
ESource *	e_source_registry_server_load_file
						(ESourceRegistryServer *server,
						 GFile *file,
						 ESourcePermissionFlags flags,
						 GError **error);
void		e_source_registry_server_load_error
						(ESourceRegistryServer *server,
						 GFile *file,
						 const GError *error);
ESource *	e_source_registry_server_ref_source
						(ESourceRegistryServer *server,
						 const gchar *uid);
GList *		e_source_registry_server_list_sources
						(ESourceRegistryServer *server,
						 const gchar *extension_name);
ESource *	e_source_registry_server_find_extension
						(ESourceRegistryServer *server,
						 ESource *source,
						 const gchar *extension_name);
ECollectionBackend *
		e_source_registry_server_ref_backend
						(ESourceRegistryServer *server,
						 ESource *source);
ECollectionBackendFactory *
		e_source_registry_server_ref_backend_factory
						(ESourceRegistryServer *server,
						 ESource *source);

#ifndef EDS_DISABLE_DEPRECATED
gboolean	e_source_registry_server_load_all
						(ESourceRegistryServer *server,
						 GError **error);
#endif /* EDS_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* E_SOURCE_REGISTRY_SERVER_H */
