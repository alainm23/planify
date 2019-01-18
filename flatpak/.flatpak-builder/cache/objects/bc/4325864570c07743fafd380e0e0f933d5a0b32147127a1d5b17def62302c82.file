/*
 * e-data-factory.h
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

#ifndef E_DATA_FACTORY_H
#define E_DATA_FACTORY_H

#include <libebackend/e-dbus-server.h>
#include <libebackend/e-backend-factory.h>

/* Standard GObject macros */
#define E_TYPE_DATA_FACTORY \
	(e_data_factory_get_type ())
#define E_DATA_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_DATA_FACTORY, EDataFactory))
#define E_DATA_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_DATA_FACTORY, EDataFactoryClass))
#define E_IS_DATA_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_DATA_FACTORY))
#define E_IS_DATA_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_DATA_FACTORY))
#define E_DATA_FACTORY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_DATA_FACTORY, EDataFactoryClass))

G_BEGIN_DECLS

typedef struct _EDataFactory EDataFactory;
typedef struct _EDataFactoryClass EDataFactoryClass;
typedef struct _EDataFactoryPrivate EDataFactoryPrivate;

/**
 * EDataFactory:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.4
 **/
struct _EDataFactory {
	/*< private >*/
	EDBusServer parent;
	EDataFactoryPrivate *priv;
};

struct _EDataFactoryClass {
	EDBusServerClass parent_class;

	GType backend_factory_type;

	const gchar *factory_object_path;
	const gchar *data_object_path_prefix;
	const gchar *subprocess_object_path_prefix;
	const gchar *subprocess_bus_name_prefix;

	/* Virtual methods */
	GDBusInterfaceSkeleton *
			(*get_dbus_interface_skeleton)
						(EDBusServer *server);
	const gchar *	(*get_factory_name)	(EBackendFactory *backend_factory);
	void		(*complete_open)	(EDataFactory *data_factory,
						 GDBusMethodInvocation *invocation,
						 const gchar *object_path,
						 const gchar *bus_name,
						 const gchar *extension_name);

	EBackend *	(* create_backend)	(EDataFactory *data_factory,
						 EBackendFactory *backend_factory,
						 ESource *source);
	gchar *		(* open_backend)	(EDataFactory *data_factory,
						 EBackend *backend,
						 GDBusConnection *connection,
						 GCancellable *cancellable,
						 GError **error);

	gpointer reserved[13];
};

GType		e_data_factory_get_type		(void) G_GNUC_CONST;
EBackendFactory *
		e_data_factory_ref_backend_factory
						(EDataFactory *data_factory,
						 const gchar *backend_name,
						 const gchar *extension_name);
ESourceRegistry *
		e_data_factory_get_registry	(EDataFactory *data_factory);
gchar *		e_data_factory_construct_path	(EDataFactory *data_factory);
void		e_data_factory_spawn_subprocess_backend
						(EDataFactory *data_factory,
						 GDBusMethodInvocation *invocation,
						 const gchar *uid,
						 const gchar *extension_name,
						 const gchar *subprocess_path);
gboolean	e_data_factory_get_reload_supported
						(EDataFactory *data_factory);
gint		e_data_factory_get_backend_per_process
						(EDataFactory *data_factory);
gboolean	e_data_factory_use_backend_per_process
						(EDataFactory *data_factory);
EBackend *	e_data_factory_create_backend	(EDataFactory *data_factory,
						 EBackendFactory *backend_factory,
						 ESource *source);
gchar *		e_data_factory_open_backend	(EDataFactory *data_factory,
						 EBackend *backend,
						 GDBusConnection *connection,
						 GCancellable *cancellable,
						 GError **error);
void		e_data_factory_backend_closed	(EDataFactory *data_factory,
						 EBackend *backend);
GSList *	e_data_factory_list_opened_backends /* EBackend * */
						(EDataFactory *data_factory);

G_END_DECLS

#endif /* E_DATA_FACTORY_H */
