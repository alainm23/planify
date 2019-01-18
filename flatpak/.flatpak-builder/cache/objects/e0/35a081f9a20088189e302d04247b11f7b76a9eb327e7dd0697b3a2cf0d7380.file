/*
 * Copyright (C) 2014 Red Hat, Inc. (www.redhat.com)
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
 * Authors: Fabiano Fidêncio <fidencio@redhat.com>
 */

/**
 * SECTION: e-subprocess-factory
 * @include: libebackend/libebackend.h
 * @short_description: An abstract base class for a backend-subprocess server
 **/

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include <libedataserver/libedataserver.h>

#include <libebackend/e-backend-factory.h>

#include <e-dbus-subprocess-backend.h>

#include "e-subprocess-factory.h"

#define E_SUBPROCESS_FACTORY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SUBPROCESS_FACTORY, ESubprocessFactoryPrivate))

struct _ESubprocessFactoryPrivate {
	ESourceRegistry *registry;

	/*
	 * As backends and modules HashTables are used basically
	 * in the same places, we use the same mutex to guard
	 * both of them.
	 */
	GMutex mutex;

	/* ESource UID -> EBackend */
	GHashTable *backends;
	/* Module filename -> EModule */
	GHashTable *modules;
};

enum {
	PROP_0,
	PROP_REGISTRY,
};

/* Forward Declarations */
static void	e_subprocess_factory_initable_init		(GInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	ESubprocessFactory,
	e_subprocess_factory,
	G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_subprocess_factory_initable_init))

static void
subprocess_factory_toggle_notify_cb (gpointer data,
				     GObject *backend,
				     gboolean is_last_ref)
{
	if (is_last_ref) {
		g_object_ref (backend);

		g_object_remove_toggle_ref (
			backend, subprocess_factory_toggle_notify_cb, data);

		g_signal_emit_by_name (backend, "shutdown");

		g_object_unref (backend);
	}
}

static void
subprocess_factory_closed_cb (EBackend *backend,
			      const gchar *sender,
			      EDBusSubprocessBackend *proxy)
{
	e_dbus_subprocess_backend_emit_backend_closed (proxy, sender);
}

static void
e_subprocess_factory_get_property (GObject *object,
				   guint property_id,
				   GValue *value,
				   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_REGISTRY:
			g_value_set_object (
				value,
				e_subprocess_factory_get_registry (
				E_SUBPROCESS_FACTORY (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
subprocess_factory_dispose (GObject *object)
{
	ESubprocessFactory *subprocess_factory;
	ESubprocessFactoryPrivate *priv;

	subprocess_factory = E_SUBPROCESS_FACTORY (object);
	priv = subprocess_factory->priv;

	g_hash_table_remove_all (priv->backends);
	g_hash_table_remove_all (priv->modules);
	g_clear_object (&priv->registry);

	/* Chain up to parent's dispose() method */
	G_OBJECT_CLASS (e_subprocess_factory_parent_class)->dispose (object);
}

static void
subprocess_factory_finalize (GObject *object)
{
	ESubprocessFactory *subprocess_factory;
	ESubprocessFactoryPrivate *priv;

	subprocess_factory = E_SUBPROCESS_FACTORY (object);
	priv = subprocess_factory->priv;

	g_mutex_clear (&priv->mutex);

	g_hash_table_destroy (priv->backends);
	g_hash_table_destroy (priv->modules);

	/* Chain up to parent's finalize() method */
	G_OBJECT_CLASS (e_subprocess_factory_parent_class)->finalize (object);
}

static gboolean
subprocess_factory_initable_init (GInitable *initable,
				  GCancellable *cancellable,
				  GError **error)
{
	ESubprocessFactory *subprocess_factory;

	subprocess_factory = E_SUBPROCESS_FACTORY (initable);

	subprocess_factory->priv->registry = e_source_registry_new_sync (
		cancellable, error);

	return (subprocess_factory->priv->registry != NULL);
}

static void
e_subprocess_factory_initable_init (GInitableIface *iface)
{
	iface->init = subprocess_factory_initable_init;
}

static void
e_subprocess_factory_class_init (ESubprocessFactoryClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ESubprocessFactoryPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->get_property = e_subprocess_factory_get_property;
	object_class->dispose = subprocess_factory_dispose;
	object_class->finalize = subprocess_factory_finalize;

	g_object_class_install_property (
		object_class,
		PROP_REGISTRY,
		g_param_spec_object (
			"registry",
			"Registry",
			"Data source registry",
			E_TYPE_SOURCE_REGISTRY,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));
}

static void
e_subprocess_factory_init (ESubprocessFactory *subprocess_factory)
{
	subprocess_factory->priv = E_SUBPROCESS_FACTORY_GET_PRIVATE (subprocess_factory);

	g_mutex_init (&subprocess_factory->priv->mutex);

	subprocess_factory->priv->backends = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_object_unref);

	subprocess_factory->priv->modules = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_type_module_unuse);
}

/**
 * e_subprocess_factory_ref_initable_backend:
 * @subprocess_factory: an #ESubprocessFactory
 * @uid: UID of an #ESource to open
 * @backend_factory_type_name: the name of the backend factory type
 * @module_filename: the name (full-path) of the backend module to be loaded
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Returns either a newly-created or existing #EBackend for #ESource.
 * The returned #EBackend is referenced for thread-safety and must be
 * unreferenced with g_object_unref() when finished with it.
 *
 * If the newly-created backend implements the #GInitable interface, then
 * g_initable_init() is also called on it using @cancellable and @error.
 *
 * The @subprocess_factory retains a strong reference to @backend.
 *
 * If no suitable #EBackendFactory exists, or if the #EBackend fails to
 * initialize, the function sets @error and returns %NULL.
 *
 * Returns: an #EBackend for @source, or %NULL
 *
 * Since: 3.16
 **/
EBackend *
e_subprocess_factory_ref_initable_backend (ESubprocessFactory *subprocess_factory,
					   const gchar *uid,
					   const gchar *backend_factory_type_name,
					   const gchar *module_filename,
					   GCancellable *cancellable,
					   GError **error)
{
	EBackend *backend;
	EModule *module;
	ESource *source;
	ESourceRegistry *registry;
	ESubprocessFactoryPrivate *priv;
	ESubprocessFactoryClass *class;

	g_return_val_if_fail (E_IS_SUBPROCESS_FACTORY (subprocess_factory), NULL);
	g_return_val_if_fail (uid != NULL && *uid != '\0', NULL);
	g_return_val_if_fail (backend_factory_type_name != NULL && *backend_factory_type_name != '\0', NULL);
	g_return_val_if_fail (module_filename != NULL && *module_filename != '\0', NULL);

	class = E_SUBPROCESS_FACTORY_GET_CLASS (subprocess_factory);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->ref_backend != NULL, NULL);

	priv = subprocess_factory->priv;

	g_mutex_lock (&priv->mutex);

	backend = g_hash_table_lookup (priv->backends, uid);
	if (backend != NULL) {
		g_object_ref (backend);
		goto exit;
	}

	module = g_hash_table_lookup (priv->modules, module_filename);
	if (module == NULL) {
		module = e_module_load_file (module_filename);
		if (!module) {
			g_set_error (
				error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND,
				_("Module “%s” for source UID “%s” cannot be loaded"), module_filename, uid);
			goto exit;
		}

		g_hash_table_insert (priv->modules, g_strdup (module_filename), module);
	}

	registry = e_subprocess_factory_get_registry (subprocess_factory);
	source = e_source_registry_ref_source (registry, uid);
	if (source == NULL) {
		g_set_error (
			error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND,
			_("No such source for UID “%s”"), uid);
		goto exit;
	}

	backend = class->ref_backend (registry, source, backend_factory_type_name);

	if (backend == NULL) {
		g_set_error (
			error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND,
			_("Failed to create backend of type “%s” for source UID “%s”"), backend_factory_type_name, uid);
		goto exit;
	}

	if (G_IS_INITABLE (backend)) {
		GInitable *initable = G_INITABLE (backend);

		if (!g_initable_init (initable, cancellable, error))
			g_clear_object (&backend);
	}

	if (backend != NULL)
		g_hash_table_insert (priv->backends, g_strdup (uid), g_object_ref (backend));

exit:
	g_mutex_unlock (&priv->mutex);
	return backend;
}

/**
 * e_subprocess_factory_get_registry:
 * @subprocess_factory: an #ESubprocessFactory
 *
 * Returns the #ESourceRegistry owned by @subprocess_factory.
 *
 * Returns: the #ESourceRegistry
 *
 * Since: 3.16
 **/
ESourceRegistry *
e_subprocess_factory_get_registry (ESubprocessFactory *subprocess_factory)
{
	g_return_val_if_fail (E_IS_SUBPROCESS_FACTORY (subprocess_factory), NULL);

	return subprocess_factory->priv->registry;
}

/**
 * e_subprocess_factory_construct_path:
 *
 * Returns a new and unique object path for a D-Bus interface based
 * in the data object path prefix of the @subprocess_factory
 *
 * Returns: a newly allocated string, representing the object path for
 *          the D-Bus interface.
 *
 * This function is here for a lack of a better place
 *
 * Since: 3.16
 **/
gchar *
e_subprocess_factory_construct_path (void)
{
	static volatile gint counter = 1;

	g_atomic_int_inc (&counter);

	return g_strdup_printf (
		"/org/gnome/evolution/dataserver/Subprocess/%d/%u", getpid (), counter);
}

/**
 * e_subprocess_factory_open_backend:
 * @subprocess_factory: an #ESubprocessFactory
 * @connection: a #GDBusConnection
 * @uid: UID of an #ESource to open
 * @backend_factory_type_name: the name of the backend factory type
 * @module_filename: the name (full-path) of the backend module to be loaded
 * @proxy: a #GDBusInterfaceSkeleton, used to communicate to the subprocess backend
 * @cancellable: a #GCancellable
 * @error: return location for a #GError, or %NULL
 *
 * Returns the #EBackend data D-Bus object path
 *
 * Returns: a newly allocated string that represents the #EBackend
 *          data D-Bus object path.
 *
 * Since: 3.16
 **/
gchar *
e_subprocess_factory_open_backend (ESubprocessFactory *subprocess_factory,
				   GDBusConnection *connection,
				   const gchar *uid,
				   const gchar *backend_factory_type_name,
				   const gchar *module_filename,
				   GDBusInterfaceSkeleton *proxy,
				   GCancellable *cancellable,
				   GError **error)
{
	ESubprocessFactoryClass *class;
	EBackend *backend;
	gchar *object_path = NULL;

	g_return_val_if_fail (E_IS_SUBPROCESS_FACTORY (subprocess_factory), NULL);
	g_return_val_if_fail (connection != NULL, NULL);
	g_return_val_if_fail (uid != NULL && *uid != '\0', NULL);
	g_return_val_if_fail (backend_factory_type_name != NULL && *backend_factory_type_name != '\0', NULL);
	g_return_val_if_fail (module_filename != NULL && *module_filename != '\0', NULL);
	g_return_val_if_fail (E_DBUS_SUBPROCESS_IS_BACKEND (proxy), NULL);

	class = E_SUBPROCESS_FACTORY_GET_CLASS (subprocess_factory);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->open_data != NULL, NULL);

	backend = e_subprocess_factory_ref_initable_backend (
		subprocess_factory, uid, backend_factory_type_name, module_filename, cancellable, error);

	if (backend == NULL)
		return NULL;

	object_path = class->open_data (subprocess_factory, backend, connection, proxy, cancellable, error);

	g_clear_object (&backend);

	return object_path;
}

/**
 * e_subprocess_factory_get_backends_list:
 * @subprocess_factory: an #ESubprocessFactory
 *
 * Returns a list of used backends.
 *
 * Returns: A #GList that contains a list of used backends. The list should be freed
 * by the caller using: g_list_free_full (backends, g_object_unref).
 *
 * Since: 3.16
 **/
GList *
e_subprocess_factory_get_backends_list (ESubprocessFactory *subprocess_factory)
{
	GList *backends;
	ESubprocessFactoryPrivate *priv;

	g_return_val_if_fail (E_IS_SUBPROCESS_FACTORY (subprocess_factory), NULL);

	priv = subprocess_factory->priv;

	g_mutex_lock (&priv->mutex);
	backends = g_hash_table_get_values (subprocess_factory->priv->backends);
	g_list_foreach (backends, (GFunc) g_object_ref, NULL);
	g_mutex_unlock (&priv->mutex);

	return backends;
}

/**
 * e_subprocess_factory_call_backends_prepare_shutdown:
 * @subprocess_factory: an #ESubprocessFactory
 *
 * Calls e_backend_prepare_shutdown() for the list of used backends.
 *
 * Since: 3.16
 */
void
e_subprocess_factory_call_backends_prepare_shutdown (ESubprocessFactory *subprocess_factory)
{
	GList *backends, *l;

	g_return_if_fail (E_IS_SUBPROCESS_FACTORY (subprocess_factory));

	backends = e_subprocess_factory_get_backends_list (subprocess_factory);

	for (l = backends; l != NULL; l = g_list_next (l)) {
		EBackend *backend = l->data;

		e_backend_prepare_shutdown (backend);
	}

	g_list_free_full (backends, g_object_unref);
}

/**
 * e_subprocess_factory_set_backend_callbacks:
 * @subprocess_factory: an #ESubprocessFactory
 * @backend: an #EBackend
 * @proxy: a #GDBusInterfaceSkeleton, used to communicate to the subprocess backend
 *
 * Installs a toggle reference on the backend, that can receive a signal to
 * shutdown once all client connections are closed.
 *
 * Since: 3.16
 **/
void
e_subprocess_factory_set_backend_callbacks (ESubprocessFactory *subprocess_factory,
					    EBackend *backend,
					    GDBusInterfaceSkeleton *proxy)
{
	g_return_if_fail (E_IS_SUBPROCESS_FACTORY (subprocess_factory));
	g_return_if_fail (backend != NULL);
	g_return_if_fail (E_DBUS_SUBPROCESS_IS_BACKEND (proxy));

	/*
	 * Install a toggle reference on the backend
	 * so we can signal it to shutdown once all
	 * client connections are closed
	 */
	g_object_add_toggle_ref (
		G_OBJECT (backend),
		subprocess_factory_toggle_notify_cb,
		NULL);

	g_signal_connect_object (
		backend, "closed",
		G_CALLBACK (subprocess_factory_closed_cb),
		proxy, 0);
}
