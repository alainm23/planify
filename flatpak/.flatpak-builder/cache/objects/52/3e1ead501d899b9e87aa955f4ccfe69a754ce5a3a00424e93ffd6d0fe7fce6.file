/*
 * e-collection-backend.c
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

/**
 * SECTION: e-collection-backend
 * @include: libebackend/libebackend.h
 * @short_description: A base class for a data source collection backend
 *
 * #ECollectionBackend is a base class for backends which manage a
 * collection of data sources that collectively represent the resources
 * on a remote server.  The resources can include any number of private
 * and shared email stores, calendars and address books.
 *
 * The backend's job is to synchronize local representations of remote
 * resources by adding and removing #EServerSideSource instances in an
 * #ESourceRegistryServer.  If possible the backend should also listen
 * for notifications of newly-added or deleted resources on the remote
 * server or else poll the remote server at regular intervals and then
 * update the data source collection accordingly.
 *
 * The client is responsible to provide credentials to use to authenticate.
 **/

#include "evolution-data-server-config.h"

#include <errno.h>
#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include <libedataserver/libedataserver.h>

#include <libebackend/e-server-side-source.h>
#include <libebackend/e-source-registry-server.h>

#include "e-collection-backend.h"

#define E_COLLECTION_BACKEND_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_COLLECTION_BACKEND, ECollectionBackendPrivate))

struct _ECollectionBackendPrivate {
	GWeakRef server;

	/* Set of ESources */
	GHashTable *children;
	GMutex children_lock;

	GMutex property_lock;
	GProxyResolver *proxy_resolver;
	gchar *cache_dir;

	ESource *authentication_source;
	gulong auth_source_changed_handler_id;

	/* Resource ID -> ESource */
	GHashTable *unclaimed_resources;
	GMutex unclaimed_resources_lock;
	GHashTable *new_sources; /* ESource::uid ~> NULL, uses the unclaimed_resources_lock */

	gulong source_added_handler_id;
	gulong source_removed_handler_id;
	gulong notify_enabled_handler_id;
	gulong notify_collection_handler_id;
	gulong notify_online_handler_id;

	guint scheduled_populate_idle_id;
};

enum {
	PROP_0,
	PROP_PROXY_RESOLVER,
	PROP_SERVER
};

enum {
	CHILD_ADDED,
	CHILD_REMOVED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE (
	ECollectionBackend,
	e_collection_backend,
	E_TYPE_BACKEND)

static void
collection_backend_children_insert (ECollectionBackend *backend,
                                    ESource *source)
{
	g_mutex_lock (&backend->priv->children_lock);

	g_hash_table_add (backend->priv->children, g_object_ref (source));

	g_mutex_unlock (&backend->priv->children_lock);
}

static gboolean
collection_backend_children_remove (ECollectionBackend *backend,
                                    ESource *source)
{
	gboolean removed;

	g_mutex_lock (&backend->priv->children_lock);

	removed = g_hash_table_remove (backend->priv->children, source);

	g_mutex_unlock (&backend->priv->children_lock);

	return removed;
}

static GList *
collection_backend_children_list (ECollectionBackend *backend)
{
	GList *list, *link;

	g_mutex_lock (&backend->priv->children_lock);

	list = g_hash_table_get_keys (backend->priv->children);

	for (link = list; link != NULL; link = g_list_next (link))
		g_object_ref (link->data);

	g_mutex_unlock (&backend->priv->children_lock);

	return list;
}

static GFile *
collection_backend_new_user_file (ECollectionBackend *backend)
{
	GFile *file;
	gchar *safe_uid;
	gchar *basename;
	gchar *filename;
	const gchar *cache_dir;

	/* This is like e_server_side_source_new_user_file()
	 * except that it uses the backend's cache directory. */

	safe_uid = e_util_generate_uid ();
	e_filename_make_safe (safe_uid);

	cache_dir = e_collection_backend_get_cache_dir (backend);
	basename = g_strconcat (safe_uid, ".source", NULL);
	filename = g_build_filename (cache_dir, basename, NULL);

	file = g_file_new_for_path (filename);

	g_free (basename);
	g_free (filename);
	g_free (safe_uid);

	return file;
}

static ESource *
collection_backend_new_source (ECollectionBackend *backend,
                               GFile *file,
                               GError **error)
{
	ESourceRegistryServer *server;
	ESource *child_source;
	ESource *collection_source;
	EServerSideSource *server_side_source;
	const gchar *cache_dir;
	const gchar *collection_uid;

	server = e_collection_backend_ref_server (backend);
	child_source = e_server_side_source_new (server, file, error);
	g_object_unref (server);

	if (child_source == NULL)
		return NULL;

	server_side_source = E_SERVER_SIDE_SOURCE (child_source);

	/* Clients may change the source but may not remove it. */
	e_server_side_source_set_writable (server_side_source, TRUE);
	e_server_side_source_set_removable (server_side_source, FALSE);

	/* Changes should be written back to the cache directory. */
	cache_dir = e_collection_backend_get_cache_dir (backend);
	e_server_side_source_set_write_directory (
		server_side_source, cache_dir);

	/* Configure the child source as a collection member. */
	collection_source = e_backend_get_source (E_BACKEND (backend));
	collection_uid = e_source_get_uid (collection_source);
	e_source_set_parent (child_source, collection_uid);

	return child_source;
}

static void
collection_backend_remove_files (GSList *filenames, /* gchar * */
				 const gchar *cache_dir,
				 const gchar *reason)
{
	GSList *link;

	for (link = filenames; link; link = g_slist_next (link)) {
		const gchar *name = link->data;
		gchar *filename;

		filename = g_build_filename (cache_dir, name, NULL);
		if (filename) {
			if (g_unlink (filename) == -1) {
				gint errn = errno;
				e_source_registry_debug_print ("%s: Failed to remove %s source '%s': %s\n", G_STRFUNC, reason, filename, g_strerror (errn));
			} else {
				e_source_registry_debug_print ("%s: Removed %s source '%s'\n", G_STRFUNC, reason, filename);
			}
		}
		g_free (filename);
	}
}

static void
collection_backend_load_resources (ECollectionBackend *backend)
{
	ESourceRegistryServer *server;
	ECollectionBackendClass *class;
	GDir *dir;
	GFile *file;
	GSList *remove_redundant = NULL, *remove_broken = NULL;
	const gchar *name;
	const gchar *cache_dir;
	GError *error = NULL;

	/* This is based on e_source_registry_server_load_file()
	 * and e_source_registry_server_load_directory(). */

	class = E_COLLECTION_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->dup_resource_id != NULL);

	cache_dir = e_collection_backend_get_cache_dir (backend);

	dir = g_dir_open (cache_dir, 0, &error);
	if (error != NULL) {
		g_warn_if_fail (dir == NULL);
		g_warning ("%s: %s", G_STRFUNC, error->message);
		g_error_free (error);
		return;
	}

	g_return_if_fail (dir != NULL);

	file = g_file_new_for_path (cache_dir);
	server = e_collection_backend_ref_server (backend);

	g_mutex_lock (&backend->priv->unclaimed_resources_lock);

	while ((name = g_dir_read_name (dir)) != NULL) {
		GFile *child;
		ESource *source;
		gchar *resource_id;

		/* Ignore files with no ".source" suffix. */
		if (!g_str_has_suffix (name, ".source"))
			continue;

		child = g_file_get_child (file, name);
		source = collection_backend_new_source (backend, child, &error);
		g_object_unref (child);

		if (error != NULL) {
			g_warn_if_fail (source == NULL);
			g_warning ("%s: %s", G_STRFUNC, error->message);
			g_clear_error (&error);

			/* Internal data, broken file for some reason, delete it */
			remove_broken = g_slist_prepend (remove_broken, g_strdup (name));
			continue;
		}

		g_return_if_fail (E_IS_SERVER_SIDE_SOURCE (source));

		resource_id = class->dup_resource_id (backend, source);

		/* Hash table takes ownership of the resource ID. */
		if (resource_id != NULL &&
		    !g_hash_table_contains (backend->priv->unclaimed_resources, resource_id)) {
			g_hash_table_insert (
				backend->priv->unclaimed_resources,
				resource_id, g_object_ref (source));
		} else {
			remove_redundant = g_slist_prepend (remove_redundant, g_strdup (name));
		}

		g_object_unref (source);
	}

	g_mutex_unlock (&backend->priv->unclaimed_resources_lock);

	g_object_unref (file);
	g_object_unref (server);
	g_dir_close (dir);

	collection_backend_remove_files (remove_redundant, cache_dir, "redundant");
	collection_backend_remove_files (remove_broken, cache_dir, "broken");

	g_slist_free_full (remove_redundant, g_free);
	g_slist_free_full (remove_broken, g_free);
}

static ESource *
collection_backend_claim_resource (ECollectionBackend *backend,
                                   const gchar *resource_id,
                                   GError **error)
{
	GHashTable *unclaimed_resources;
	ESource *source;

	g_mutex_lock (&backend->priv->unclaimed_resources_lock);

	unclaimed_resources = backend->priv->unclaimed_resources;
	source = g_hash_table_lookup (unclaimed_resources, resource_id);

	if (source != NULL) {
		g_object_ref (source);
		g_hash_table_remove (unclaimed_resources, resource_id);
	} else {
		GFile *file = collection_backend_new_user_file (backend);
		source = collection_backend_new_source (backend, file, error);
		g_object_unref (file);

		if (source) {
			if (!backend->priv->new_sources)
				backend->priv->new_sources = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);

			g_hash_table_insert (backend->priv->new_sources, e_source_dup_uid (source), NULL);
		}
	}

	g_mutex_unlock (&backend->priv->unclaimed_resources_lock);

	return source;
}

static gboolean
collection_backend_child_is_calendar (ESource *child_source)
{
	const gchar *extension_name;

	extension_name = E_SOURCE_EXTENSION_CALENDAR;
	if (e_source_has_extension (child_source, extension_name))
		return TRUE;

	extension_name = E_SOURCE_EXTENSION_MEMO_LIST;
	if (e_source_has_extension (child_source, extension_name))
		return TRUE;

	extension_name = E_SOURCE_EXTENSION_TASK_LIST;
	if (e_source_has_extension (child_source, extension_name))
		return TRUE;

	return FALSE;
}

static gboolean
collection_backend_child_is_contacts (ESource *child_source)
{
	const gchar *extension_name;

	extension_name = E_SOURCE_EXTENSION_ADDRESS_BOOK;
	if (e_source_has_extension (child_source, extension_name))
		return TRUE;

	return FALSE;
}

static gboolean
collection_backend_child_is_mail (ESource *child_source)
{
	const gchar *extension_name;

	extension_name = E_SOURCE_EXTENSION_MAIL_ACCOUNT;
	if (e_source_has_extension (child_source, extension_name))
		return TRUE;

	extension_name = E_SOURCE_EXTENSION_MAIL_IDENTITY;
	if (e_source_has_extension (child_source, extension_name))
		return TRUE;

	extension_name = E_SOURCE_EXTENSION_MAIL_TRANSPORT;
	if (e_source_has_extension (child_source, extension_name))
		return TRUE;

	return FALSE;
}

static gboolean
include_master_source_enabled_transform (GBinding *binding,
                                         const GValue *source_value,
                                         GValue *target_value,
                                         gpointer backend)
{
	g_value_set_boolean (
		target_value,
		g_value_get_boolean (source_value) &&
		e_source_get_enabled (e_backend_get_source (backend)));

	return TRUE;
}

static void
collection_backend_bind_child_enabled (ECollectionBackend *backend,
                                       ESource *child_source)
{
	ESource *collection_source;
	ESourceCollection *extension;
	const gchar *extension_name;

	/* See if the child source's "enabled" property can be
	 * bound to any ESourceCollection "enabled" properties. */

	extension_name = E_SOURCE_EXTENSION_COLLECTION;
	collection_source = e_backend_get_source (E_BACKEND (backend));
	extension = e_source_get_extension (collection_source, extension_name);

	if (collection_backend_child_is_calendar (child_source)) {
		e_binding_bind_property_full (
			extension, "calendar-enabled",
			child_source, "enabled",
			G_BINDING_SYNC_CREATE,
			include_master_source_enabled_transform,
			include_master_source_enabled_transform,
			backend,
			NULL);
		return;
	}

	if (collection_backend_child_is_contacts (child_source)) {
		e_binding_bind_property_full (
			extension, "contacts-enabled",
			child_source, "enabled",
			G_BINDING_SYNC_CREATE,
			include_master_source_enabled_transform,
			include_master_source_enabled_transform,
			backend,
			NULL);
		return;
	}

	if (collection_backend_child_is_mail (child_source)) {
		e_binding_bind_property_full (
			extension, "mail-enabled",
			child_source, "enabled",
			G_BINDING_SYNC_CREATE,
			include_master_source_enabled_transform,
			include_master_source_enabled_transform,
			backend,
			NULL);
		return;
	}

	e_binding_bind_property (
		collection_source, "enabled",
		child_source, "enabled",
		G_BINDING_SYNC_CREATE);
}

static void
collection_backend_source_added_cb (ESourceRegistryServer *server,
                                    ESource *source,
                                    ECollectionBackend *backend)
{
	ESource *collection_source;
	ESource *parent_source;
	const gchar *uid;

	/* If the newly-added source is our own child, emit "child-added". */

	collection_source = e_backend_get_source (E_BACKEND (backend));

	uid = e_source_get_parent (source);
	if (uid == NULL)
		return;

	parent_source = e_source_registry_server_ref_source (server, uid);
	g_return_if_fail (parent_source != NULL);

	if (e_source_equal (collection_source, parent_source))
		g_signal_emit (backend, signals[CHILD_ADDED], 0, source);

	g_object_unref (parent_source);
}

static void
collection_backend_source_removed_cb (ESourceRegistryServer *server,
                                      ESource *source,
                                      ECollectionBackend *backend)
{
	ESource *collection_source;
	ESource *parent_source;
	const gchar *uid;

	/* If the removed source was our own child, emit "child-removed".
	 * Note that the source is already unlinked from the GNode tree. */

	collection_source = e_backend_get_source (E_BACKEND (backend));

	uid = e_source_get_parent (source);
	if (uid == NULL)
		return;

	parent_source = e_source_registry_server_ref_source (server, uid);
	g_return_if_fail (parent_source != NULL);

	if (e_source_equal (collection_source, parent_source))
		g_signal_emit (backend, signals[CHILD_REMOVED], 0, source);

	g_object_unref (parent_source);
}

static void
collection_backend_source_enabled_cb (ESource *source,
				      GParamSpec *spec,
				      EBackend *backend)
{
	ESource *collection_source;
	GObject *collection;

	g_return_if_fail (E_IS_COLLECTION_BACKEND (backend));

	collection_source = e_backend_get_source (E_BACKEND (backend));
	collection = e_source_get_extension (collection_source, E_SOURCE_EXTENSION_COLLECTION);

	/* Some child sources depend on both sub-part enabled and the main
	   ESource::enabled state, thus if the main's ESource::enabled
	   changes, then also notify the change of the sub-parts, thus
	   child's enabled property is properly recalculated. */
	g_object_notify (collection, "calendar-enabled");
	g_object_notify (collection, "contacts-enabled");
	g_object_notify (collection, "mail-enabled");
}

static void
collection_backend_forget_new_sources (ECollectionBackend *backend)
{
	g_return_if_fail (E_IS_COLLECTION_BACKEND (backend));

	g_mutex_lock (&backend->priv->unclaimed_resources_lock);

	if (backend->priv->new_sources) {
		g_hash_table_destroy (backend->priv->new_sources);
		backend->priv->new_sources = NULL;
	}

	g_mutex_unlock (&backend->priv->unclaimed_resources_lock);
}

static gboolean
collection_backend_populate_idle_cb (gpointer user_data)
{
	ECollectionBackend *backend;
	ECollectionBackendClass *class;

	backend = E_COLLECTION_BACKEND (user_data);

	backend->priv->scheduled_populate_idle_id = 0;

	class = E_COLLECTION_BACKEND_GET_CLASS (backend);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->populate != NULL, FALSE);

	/* Any new sources found during the last populate() are not
	   considered new anymore. */
	collection_backend_forget_new_sources (backend);

	class->populate (backend);

	return FALSE;
}

static void
collection_backend_schedule_populate_idle (ECollectionBackend *backend)
{
	g_return_if_fail (E_IS_COLLECTION_BACKEND (backend));

	if (!backend->priv->scheduled_populate_idle_id)
		backend->priv->scheduled_populate_idle_id = g_idle_add_full (
			G_PRIORITY_LOW,
			collection_backend_populate_idle_cb,
			g_object_ref (backend),
			(GDestroyNotify) g_object_unref);
}

static void
collection_backend_notify_collection_cb (ESourceCollection *collection_extension,
					 GParamSpec *param,
					 ECollectionBackend *collection_backend)
{
	ESource *source;

	g_return_if_fail (E_IS_SOURCE_COLLECTION (collection_extension));
	g_return_if_fail (param != NULL);
	g_return_if_fail (E_IS_COLLECTION_BACKEND (collection_backend));

	source = e_backend_get_source (E_BACKEND (collection_backend));
	if (!e_source_get_enabled (source) || (
	    g_strcmp0 (g_param_spec_get_name (param), "calendar-enabled") != 0 &&
	    g_strcmp0 (g_param_spec_get_name (param), "contacts-enabled") != 0 &&
	    g_strcmp0 (g_param_spec_get_name (param), "mail-enabled") != 0))
		return;

	collection_backend_schedule_populate_idle (collection_backend);
}

static void
collection_backend_update_proxy_resolver (ECollectionBackend *backend)
{
	GProxyResolver *proxy_resolver = NULL;
	ESourceAuthentication *extension;
	ESource *source = NULL;
	gboolean notify = FALSE;
	gchar *uid;

	extension = e_source_get_extension (
		backend->priv->authentication_source,
		E_SOURCE_EXTENSION_AUTHENTICATION);

	uid = e_source_authentication_dup_proxy_uid (extension);
	if (uid != NULL) {
		ESourceRegistryServer *server;

		server = e_collection_backend_ref_server (backend);
		source = e_source_registry_server_ref_source (server, uid);
		g_object_unref (server);
		g_free (uid);
	}

	if (source != NULL) {
		proxy_resolver = G_PROXY_RESOLVER (source);
		if (!g_proxy_resolver_is_supported (proxy_resolver))
			proxy_resolver = NULL;
	}

	g_mutex_lock (&backend->priv->property_lock);

	/* Emitting a "notify" signal unnecessarily might have
	 * unwanted side effects like cancelling a SoupMessage.
	 * Only emit if we now have a different GProxyResolver. */

	if (proxy_resolver != backend->priv->proxy_resolver) {
		g_clear_object (&backend->priv->proxy_resolver);
		backend->priv->proxy_resolver = proxy_resolver;

		if (proxy_resolver != NULL)
			g_object_ref (proxy_resolver);

		notify = TRUE;
	}

	g_mutex_unlock (&backend->priv->property_lock);

	if (notify)
		g_object_notify (G_OBJECT (backend), "proxy-resolver");

	g_clear_object (&source);
}

static void
collection_backend_auth_source_changed_cb (ESource *authentication_source,
                                           GWeakRef *backend_weak_ref)
{
	ECollectionBackend *backend;

	backend = g_weak_ref_get (backend_weak_ref);

	if (backend != NULL) {
		collection_backend_update_proxy_resolver (backend);
		g_object_unref (backend);
	}
}

static void
collection_backend_set_server (ECollectionBackend *backend,
                               ESourceRegistryServer *server)
{
	g_return_if_fail (E_IS_SOURCE_REGISTRY_SERVER (server));

	g_weak_ref_set (&backend->priv->server, server);
}

static void
collection_backend_set_property (GObject *object,
                                 guint property_id,
                                 const GValue *value,
                                 GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SERVER:
			collection_backend_set_server (
				E_COLLECTION_BACKEND (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
collection_backend_get_property (GObject *object,
                                 guint property_id,
                                 GValue *value,
                                 GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_PROXY_RESOLVER:
			g_value_take_object (
				value,
				e_collection_backend_ref_proxy_resolver (
				E_COLLECTION_BACKEND (object)));
			return;

		case PROP_SERVER:
			g_value_take_object (
				value,
				e_collection_backend_ref_server (
				E_COLLECTION_BACKEND (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
collection_backend_dispose (GObject *object)
{
	ECollectionBackendPrivate *priv;
	ESourceRegistryServer *server;

	priv = E_COLLECTION_BACKEND_GET_PRIVATE (object);

	server = g_weak_ref_get (&priv->server);
	if (server != NULL) {
		g_signal_handler_disconnect (
			server, priv->source_added_handler_id);
		g_signal_handler_disconnect (
			server, priv->source_removed_handler_id);
		g_weak_ref_set (&priv->server, NULL);
		g_object_unref (server);
	}

	if (priv->notify_enabled_handler_id) {
		ESource *source = e_backend_get_source (E_BACKEND (object));

		if (source)
			g_signal_handler_disconnect (source, priv->notify_enabled_handler_id);

		priv->notify_enabled_handler_id = 0;
	}

	if (priv->notify_collection_handler_id) {
		ESource *source = e_backend_get_source (E_BACKEND (object));

		if (source) {
			ESourceCollection *collection_extension;

			collection_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_COLLECTION);

			g_signal_handler_disconnect (collection_extension, priv->notify_collection_handler_id);
		}

		priv->notify_collection_handler_id = 0;
	}

	if (priv->notify_online_handler_id) {
		g_signal_handler_disconnect (object, priv->notify_online_handler_id);
		priv->notify_online_handler_id = 0;
	}

	g_mutex_lock (&priv->children_lock);
	g_hash_table_remove_all (priv->children);
	g_mutex_unlock (&priv->children_lock);

	g_clear_object (&priv->proxy_resolver);
	g_clear_object (&priv->authentication_source);

	g_mutex_lock (&priv->unclaimed_resources_lock);
	g_hash_table_remove_all (priv->unclaimed_resources);
	if (priv->new_sources)
		g_hash_table_remove_all (priv->new_sources);
	g_mutex_unlock (&priv->unclaimed_resources_lock);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_collection_backend_parent_class)->dispose (object);
}

static void
collection_backend_finalize (GObject *object)
{
	ECollectionBackendPrivate *priv;

	priv = E_COLLECTION_BACKEND_GET_PRIVATE (object);

	g_hash_table_destroy (priv->children);
	g_mutex_clear (&priv->children_lock);

	g_mutex_clear (&priv->property_lock);

	g_hash_table_destroy (priv->unclaimed_resources);
	if (priv->new_sources)
		g_hash_table_destroy (priv->new_sources);
	g_mutex_clear (&priv->unclaimed_resources_lock);

	g_weak_ref_clear (&priv->server);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_collection_backend_parent_class)->finalize (object);
}

static void
collection_backend_constructed (GObject *object)
{
	ECollectionBackend *backend;
	ESourceRegistryServer *server;
	ESource *source;
	GNode *node;
	const gchar *collection_uid;
	const gchar *user_cache_dir;
	gulong handler_id;

	backend = E_COLLECTION_BACKEND (object);

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_collection_backend_parent_class)->constructed (object);

	server = e_collection_backend_ref_server (backend);
	source = e_backend_get_source (E_BACKEND (backend));

	/* Determine the backend's cache directory. */

	user_cache_dir = e_get_user_cache_dir ();
	collection_uid = e_source_get_uid (source);
	backend->priv->cache_dir = g_build_filename (
		user_cache_dir, "sources", collection_uid, NULL);
	g_mkdir_with_parents (backend->priv->cache_dir, 0700);

	/* Track the proxy resolver for this backend. */
	backend->priv->authentication_source =
		e_source_registry_server_find_extension (
		server, source, E_SOURCE_EXTENSION_AUTHENTICATION);
	if (backend->priv->authentication_source != NULL) {
		gulong handler_id;

		handler_id = g_signal_connect_data (
			backend->priv->authentication_source, "changed",
			G_CALLBACK (collection_backend_auth_source_changed_cb),
			e_weak_ref_new (backend),
			(GClosureNotify) e_weak_ref_free, 0);
		backend->priv->auth_source_changed_handler_id = handler_id;

		collection_backend_update_proxy_resolver (backend);
	}

	/* This requires the cache directory to be set. */
	collection_backend_load_resources (backend);

	/* Emit "child-added" signals for the children we already have. */

	node = e_server_side_source_get_node (E_SERVER_SIDE_SOURCE (source));
	node = g_node_first_child (node);

	while (node != NULL) {
		ESource *child = E_SOURCE (node->data);
		g_signal_emit (backend, signals[CHILD_ADDED], 0, child);
		node = g_node_next_sibling (node);
	}

	/* Listen for "source-added" and "source-removed" signals
	 * from the server, which may trigger our own "child-added"
	 * and "child-removed" signals. */

	handler_id = g_signal_connect (
		server, "source-added",
		G_CALLBACK (collection_backend_source_added_cb), backend);

	backend->priv->source_added_handler_id = handler_id;

	handler_id = g_signal_connect (
		server, "source-removed",
		G_CALLBACK (collection_backend_source_removed_cb), backend);

	backend->priv->source_removed_handler_id = handler_id;

	g_object_unref (server);

	backend->priv->notify_enabled_handler_id = g_signal_connect (source, "notify::enabled",
		G_CALLBACK (collection_backend_source_enabled_cb), backend);

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_COLLECTION)) {
		ESourceCollection *collection_extension;

		collection_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_COLLECTION);
		backend->priv->notify_collection_handler_id = g_signal_connect (collection_extension, "notify",
			G_CALLBACK (collection_backend_notify_collection_cb), backend);
	}

	/* Populate the newly-added collection from an idle callback
	 * so persistent child sources have a chance to be added first. */
	collection_backend_schedule_populate_idle (backend);

	backend->priv->notify_online_handler_id = g_signal_connect (backend, "notify::online",
		G_CALLBACK (e_collection_backend_schedule_populate), NULL);
}

static void
collection_backend_populate (ECollectionBackend *backend)
{
	/* Placeholder so subclasses can safely chain up. */
}

static gchar *
collection_backend_dup_resource_id (ECollectionBackend *backend,
                                    ESource *source)
{
	const gchar *extension_name;
	gchar *resource_id = NULL;

	extension_name = E_SOURCE_EXTENSION_RESOURCE;

	if (e_source_has_extension (source, extension_name)) {
		ESourceResource *extension;

		extension = e_source_get_extension (source, extension_name);
		resource_id = e_source_resource_dup_identity (extension);
	}

	return resource_id;
}

static void
collection_backend_child_added (ECollectionBackend *backend,
                                ESource *child_source)
{
	ESource *collection_source;
	const gchar *extension_name;
	gboolean is_mail = FALSE;

	collection_backend_children_insert (backend, child_source);
	collection_backend_bind_child_enabled (backend, child_source);

	collection_source = e_backend_get_source (E_BACKEND (backend));

	extension_name = E_SOURCE_EXTENSION_MAIL_ACCOUNT;
	is_mail |= e_source_has_extension (child_source, extension_name);

	extension_name = E_SOURCE_EXTENSION_MAIL_IDENTITY;
	is_mail |= e_source_has_extension (child_source, extension_name);

	extension_name = E_SOURCE_EXTENSION_MAIL_TRANSPORT;
	is_mail |= e_source_has_extension (child_source, extension_name);

	/* Synchronize mail-related display names with the collection. */
	if (is_mail)
		e_binding_bind_property (
			collection_source, "display-name",
			child_source, "display-name",
			G_BINDING_SYNC_CREATE);

	/* Collection children are not removable. */
	e_server_side_source_set_removable (
		E_SERVER_SIDE_SOURCE (child_source), FALSE);

	/* Collection children inherit OAuth 2.0 support if available. */
	e_binding_bind_property (
		collection_source, "oauth2-support",
		child_source, "oauth2-support",
		G_BINDING_SYNC_CREATE);
}

static void
collection_backend_child_removed (ECollectionBackend *backend,
                                  ESource *child_source)
{
	collection_backend_children_remove (backend, child_source);
}

static gboolean
collection_backend_create_resource_sync (ECollectionBackend *backend,
                                         ESource *source,
                                         GCancellable *cancellable,
                                         GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	closure = e_async_closure_new ();

	e_collection_backend_create_resource (
		backend, source, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_collection_backend_create_resource_finish (
		backend, result, error);

	e_async_closure_free (closure);

	return success;
}

static void
collection_backend_create_resource (ECollectionBackend *backend,
                                    ESource *source,
                                    GCancellable *cancellable,
                                    GAsyncReadyCallback callback,
                                    gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = g_simple_async_result_new_error (
		G_OBJECT (backend), callback, user_data,
		G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
		_("%s does not support creating remote resources"),
		G_OBJECT_TYPE_NAME (backend));

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
}

static gboolean
collection_backend_create_resource_finish (ECollectionBackend *backend,
                                           GAsyncResult *result,
                                           GError **error)
{
	GSimpleAsyncResult *simple;

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static gboolean
collection_backend_delete_resource_sync (ECollectionBackend *backend,
                                         ESource *source,
                                         GCancellable *cancellable,
                                         GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	closure = e_async_closure_new ();

	e_collection_backend_delete_resource (
		backend, source, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_collection_backend_delete_resource_finish (
		backend, result, error);

	e_async_closure_free (closure);

	return success;
}

static void
collection_backend_delete_resource (ECollectionBackend *backend,
                                    ESource *source,
                                    GCancellable *cancellable,
                                    GAsyncReadyCallback callback,
                                    gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = g_simple_async_result_new_error (
		G_OBJECT (backend), callback, user_data,
		G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
		_("%s does not support deleting remote resources"),
		G_OBJECT_TYPE_NAME (backend));

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
}

static gboolean
collection_backend_delete_resource_finish (ECollectionBackend *backend,
                                           GAsyncResult *result,
                                           GError **error)
{
	GSimpleAsyncResult *simple;

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static void
e_collection_backend_class_init (ECollectionBackendClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ECollectionBackendPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = collection_backend_set_property;
	object_class->get_property = collection_backend_get_property;
	object_class->dispose = collection_backend_dispose;
	object_class->finalize = collection_backend_finalize;
	object_class->constructed = collection_backend_constructed;

	class->populate = collection_backend_populate;
	class->dup_resource_id = collection_backend_dup_resource_id;
	class->child_added = collection_backend_child_added;
	class->child_removed = collection_backend_child_removed;
	class->create_resource_sync = collection_backend_create_resource_sync;
	class->create_resource = collection_backend_create_resource;
	class->create_resource_finish = collection_backend_create_resource_finish;
	class->delete_resource_sync = collection_backend_delete_resource_sync;
	class->delete_resource = collection_backend_delete_resource;
	class->delete_resource_finish = collection_backend_delete_resource_finish;

	g_object_class_install_property (
		object_class,
		PROP_PROXY_RESOLVER,
		g_param_spec_object (
			"proxy-resolver",
			"Proxy Resolver",
			"The proxy resolver for this backend",
			G_TYPE_PROXY_RESOLVER,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_SERVER,
		g_param_spec_object (
			"server",
			"Server",
			"The server to which the backend belongs",
			E_TYPE_SOURCE_REGISTRY_SERVER,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ECollectionBackend::child-added:
	 * @backend: the #ECollectionBackend which emitted the signal
	 * @child_source: the newly-added child #EServerSideSource
	 *
	 * Emitted when an #EServerSideSource is added to @backend's
	 * #ECollectionBackend:server as a child of @backend's collection
	 * #EBackend:source.
	 *
	 * You can think of this as a filtered version of
	 * #ESourceRegistryServer's #ESourceRegistryServer::source-added
	 * signal which only lets through sources relevant to @backend.
	 **/
	signals[CHILD_ADDED] = g_signal_new (
		"child-added",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ECollectionBackendClass, child_added),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		E_TYPE_SERVER_SIDE_SOURCE);

	/**
	 * ECollectionBackend::child-removed:
	 * @backend: the #ECollectionBackend which emitted the signal
	 * @child_source: the child #EServerSideSource that got removed
	 *
	 * Emitted when an #EServerSideSource that is a child of
	 * @backend's collection #EBackend:source is removed from
	 * @backend's #ECollectionBackend:server.
	 *
	 * You can think of this as a filtered version of
	 * #ESourceRegistryServer's #ESourceRegistryServer::source-removed
	 * signal which only lets through sources relevant to @backend.
	 **/
	signals[CHILD_REMOVED] = g_signal_new (
		"child-removed",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ECollectionBackendClass, child_removed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		E_TYPE_SERVER_SIDE_SOURCE);
}

static void
e_collection_backend_init (ECollectionBackend *backend)
{
	GHashTable *children;
	GHashTable *unclaimed_resources;

	children = g_hash_table_new_full (
		(GHashFunc) e_source_hash,
		(GEqualFunc) e_source_equal,
		(GDestroyNotify) g_object_unref,
		(GDestroyNotify) NULL);

	unclaimed_resources = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_object_unref);

	backend->priv = E_COLLECTION_BACKEND_GET_PRIVATE (backend);
	backend->priv->children = children;
	g_mutex_init (&backend->priv->children_lock);
	g_mutex_init (&backend->priv->property_lock);
	backend->priv->unclaimed_resources = unclaimed_resources;
	backend->priv->new_sources = NULL;
	g_mutex_init (&backend->priv->unclaimed_resources_lock);
	g_weak_ref_init (&backend->priv->server, NULL);
}

/**
 * e_collection_backend_new_child:
 * @backend: an #ECollectionBackend
 * @resource_id: a stable and unique resource ID
 *
 * Creates a new #EServerSideSource as a child of the collection
 * #EBackend:source owned by @backend.  If possible, the #EServerSideSource
 * is drawn from a cache of previously used sources indexed by @resource_id
 * so that locally cached data from previous sessions can be reused.
 *
 * The returned data source should be passed to
 * e_source_registry_server_add_source() to export it over D-Bus.
 *
 * Return: a newly-created data source
 *
 * Since: 3.6
 **/
ESource *
e_collection_backend_new_child (ECollectionBackend *backend,
                                const gchar *resource_id)
{
	ESource *collection_source;
	ESource *child_source;
	GError *error = NULL;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), NULL);
	g_return_val_if_fail (resource_id != NULL, NULL);

	/* This being a newly-created or existing data source, claiming
	 * it should never fail but we'll check for errors just the same.
	 * It's unlikely enough that we don't need a GError parameter. */
	child_source = collection_backend_claim_resource (
		backend, resource_id, &error);

	if (error != NULL) {
		g_warn_if_fail (child_source == NULL);
		g_warning ("%s: %s", G_STRFUNC, error->message);
		g_error_free (error);
		return NULL;
	}

	collection_source = e_backend_get_source (E_BACKEND (backend));

	e_source_registry_debug_print (
		"%s: Pairing %s with resource %s\n",
		e_source_get_display_name (collection_source),
		e_source_get_uid (child_source), resource_id);

	return child_source;
}

/**
 * e_collection_backend_is_new_source:
 * @backend: an #ECollectionBackend
 * @source: a child #ESource
 *
 * Returns whether the @source is a newly created child or not. New sources
 * are remembered between two populate calls only.
 *
 * Returns: %TRUE, when the @source is a new child; %FALSE when
 *    it had been known before.
 *
 * Since: 3.32
 **/
gboolean
e_collection_backend_is_new_source (ECollectionBackend *backend,
				    ESource *source)
{
	gboolean is_new;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (e_source_get_uid (source) != NULL, FALSE);

	g_mutex_lock (&backend->priv->unclaimed_resources_lock);

	is_new = backend->priv->new_sources &&
		g_hash_table_contains (backend->priv->new_sources, e_source_get_uid (source));

	g_mutex_unlock (&backend->priv->unclaimed_resources_lock);

	return is_new;
}

/**
 * e_collection_backend_ref_proxy_resolver:
 * @backend: an #ECollectionBackend
 *
 * Returns the #GProxyResolver for @backend (if applicable), as indicated
 * by the #ESourceAuthentication:proxy-uid of @backend's #EBackend:source
 * or one of its ancestors.
 *
 * The returned #GProxyResolver is referenced for thread-safety and must
 * be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #GProxyResolver, or %NULL
 *
 * Since: 3.12
 **/
GProxyResolver *
e_collection_backend_ref_proxy_resolver (ECollectionBackend *backend)
{
	GProxyResolver *proxy_resolver = NULL;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), NULL);

	g_mutex_lock (&backend->priv->property_lock);

	if (backend->priv->proxy_resolver != NULL)
		proxy_resolver = g_object_ref (backend->priv->proxy_resolver);

	g_mutex_unlock (&backend->priv->property_lock);

	return proxy_resolver;
}

/**
 * e_collection_backend_ref_server:
 * @backend: an #ECollectionBackend
 *
 * Returns the #ESourceRegistryServer to which @backend belongs.
 *
 * The returned #ESourceRegistryServer is referenced for thread-safety.
 * Unreference the #ESourceRegistryServer with g_object_unref() when
 * finished with it.
 *
 * Returns: the #ESourceRegistryServer for @backend
 *
 * Since: 3.6
 **/
ESourceRegistryServer *
e_collection_backend_ref_server (ECollectionBackend *backend)
{
	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), NULL);

	return g_weak_ref_get (&backend->priv->server);
}

/**
 * e_collection_backend_get_cache_dir:
 * @backend: an #ECollectionBackend
 *
 * Returns the private cache directory path for @backend, which is named
 * after the #ESource:uid of @backend's collection #EBackend:source.
 *
 * The cache directory is meant to store key files for backend-created
 * data sources.  See also: e_server_side_source_set_write_directory()
 *
 * Returns: the cache directory for @backend
 *
 * Since: 3.6
 **/
const gchar *
e_collection_backend_get_cache_dir (ECollectionBackend *backend)
{
	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), NULL);

	return backend->priv->cache_dir;
}

/**
 * e_collection_backend_dup_resource_id:
 * @backend: an #ECollectionBackend
 * @child_source: an #ESource managed by @backend
 *
 * Extracts the resource ID for @child_source, which is supposed to be a
 * stable and unique server-assigned identifier for the remote resource
 * described by @child_source.  If @child_source is not actually a child
 * of the collection #EBackend:source owned by @backend, the function
 * returns %NULL.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated resource ID for @child_source, or %NULL
 *
 * Since: 3.6
 **/
gchar *
e_collection_backend_dup_resource_id (ECollectionBackend *backend,
                                      ESource *child_source)
{
	ECollectionBackend *backend_for_child_source;
	ECollectionBackendClass *class;
	ESourceRegistryServer *server;
	gboolean child_is_ours = FALSE;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), NULL);
	g_return_val_if_fail (E_IS_SOURCE (child_source), NULL);

	class = E_COLLECTION_BACKEND_GET_CLASS (backend);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->dup_resource_id != NULL, NULL);

	/* Make sure the ESource belongs to the ECollectionBackend to
	 * avoid accidentally creating a new extension while trying to
	 * extract a resource ID that isn't there.  Better to test this
	 * up front than rely on ECollectionBackend subclasses to do it. */
	server = e_collection_backend_ref_server (backend);
	backend_for_child_source =
		e_source_registry_server_ref_backend (server, child_source);
	g_object_unref (server);

	if (backend_for_child_source != NULL) {
		child_is_ours = (backend_for_child_source == backend);
		g_object_unref (backend_for_child_source);
	}

	if (!child_is_ours)
		return NULL;

	return class->dup_resource_id (backend, child_source);
}

/**
 * e_collection_backend_claim_all_resources:
 * @backend: an #ECollectionBackend
 *
 * Claims all previously used sources that have not yet been claimed by
 * e_collection_backend_new_child() and returns them in a #GList.  Note
 * that previously used sources can only be claimed once, so subsequent
 * calls to this function for @backend will return %NULL.
 *
 * The @backend is then expected to compare the returned list with a
 * current list of resources from a remote server, create new #ESource
 * instances as needed with e_collection_backend_new_child(), discard
 * unneeded #ESource instances with e_source_remove(), and export the
 * remaining instances with e_source_registry_server_add_source().
 *
 * The sources returned in the list are referenced for thread-safety.
 * They must each be unreferenced with g_object_unref() when finished
 * with them.  Free the returned #GList itself with g_list_free().
 *
 * An easy way to free the list properly in one step is as follows:
 *
 * |[
 *   g_list_free_full (list, g_object_unref);
 * ]|
 *
 * Returns: a list of previously used sources
 *
 * Since: 3.6
 **/
GList *
e_collection_backend_claim_all_resources (ECollectionBackend *backend)
{
	GHashTable *unclaimed_resources;
	GList *resources;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), NULL);

	g_mutex_lock (&backend->priv->unclaimed_resources_lock);

	unclaimed_resources = backend->priv->unclaimed_resources;
	resources = g_hash_table_get_values (unclaimed_resources);
	g_list_foreach (resources, (GFunc) g_object_ref, NULL);
	g_hash_table_remove_all (unclaimed_resources);

	g_mutex_unlock (&backend->priv->unclaimed_resources_lock);

	return resources;
}

/**
 * e_collection_backend_list_calendar_sources:
 * @backend: an #ECollectionBackend
 *
 * Returns a list of calendar sources belonging to the data source
 * collection managed by @backend.
 *
 * The sources returned in the list are referenced for thread-safety.
 * They must each be unreferenced with g_object_unref() when finished
 * with them.  Free the returned #GList itself with g_list_free().
 *
 * An easy way to free the list properly in one step is as follows:
 *
 * |[
 *   g_list_free_full (list, g_object_unref);
 * ]|
 *
 * Returns: a list of calendar sources
 *
 * Since: 3.6
 **/
GList *
e_collection_backend_list_calendar_sources (ECollectionBackend *backend)
{
	GList *result_list = NULL;
	GList *list, *link;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), NULL);

	list = collection_backend_children_list (backend);

	for (link = list; link != NULL; link = g_list_next (link)) {
		ESource *child_source = E_SOURCE (link->data);
		if (collection_backend_child_is_calendar (child_source))
			result_list = g_list_prepend (
				result_list, g_object_ref (child_source));
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);

	return g_list_reverse (result_list);
}

/**
 * e_collection_backend_list_contacts_sources:
 * @backend: an #ECollectionBackend
 *
 * Returns a list of address book sources belonging to the data source
 * collection managed by @backend.
 *
 * The sources returned in the list are referenced for thread-safety.
 * They must each be unreferenced with g_object_unref() when finished
 * with them.  Free the returned #GList itself with g_list_free().
 *
 * An easy way to free the list properly in one step is as follows:
 *
 * |[
 *   g_list_free_full (list, g_object_unref);
 * ]|
 *
 * Returns: a list of address book sources
 *
 * Since: 3.6
 **/
GList *
e_collection_backend_list_contacts_sources (ECollectionBackend *backend)
{
	GList *result_list = NULL;
	GList *list, *link;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), NULL);

	list = collection_backend_children_list (backend);

	for (link = list; link != NULL; link = g_list_next (link)) {
		ESource *child_source = E_SOURCE (link->data);
		if (collection_backend_child_is_contacts (child_source))
			result_list = g_list_prepend (
				result_list, g_object_ref (child_source));
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);

	return g_list_reverse (result_list);
}

/**
 * e_collection_backend_list_mail_sources:
 * @backend: an #ECollectionBackend
 *
 * Returns a list of mail sources belonging to the data source collection
 * managed by @backend.
 *
 * The sources returned in the list are referenced for thread-safety.
 * They must each be unreferenced with g_object_unref() when finished
 * with them.  Free the returned #GList itself with g_list_free().
 *
 * An easy way to free the list properly in one step is as follows:
 *
 * |[
 *   g_list_free_full (list, g_object_unref);
 * ]|
 *
 * Returns: a list of mail sources
 *
 * Since: 3.6
 **/
GList *
e_collection_backend_list_mail_sources (ECollectionBackend *backend)
{
	GList *result_list = NULL;
	GList *list, *link;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), NULL);

	list = collection_backend_children_list (backend);

	for (link = list; link != NULL; link = g_list_next (link)) {
		ESource *child_source = E_SOURCE (link->data);
		if (collection_backend_child_is_mail (child_source))
			result_list = g_list_prepend (
				result_list, g_object_ref (child_source));
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);

	return g_list_reverse (result_list);
}

/**
 * e_collection_backend_create_resource_sync
 * @backend: an #ECollectionBackend
 * @source: an #ESource
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a server-side resource described by @source.  For example, if
 * @source describes a new calendar, an equivalent calendar is created on
 * the server.
 *
 * It is the implementor's responsibility to examine @source and determine
 * what the equivalent server-side resource would be.  If this cannot be
 * determined without ambiguity, the function must return an error.
 *
 * After the server-side resource is successfully created, the implementor
 * must also add an #ESource to @backend's #ECollectionBackend:server.  This
 * can either be done immediately or in response to some "resource created"
 * notification from the server.  The added #ESource can be @source itself
 * or a different #ESource instance that describes the new resource.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
e_collection_backend_create_resource_sync (ECollectionBackend *backend,
                                           ESource *source,
                                           GCancellable *cancellable,
                                           GError **error)
{
	ECollectionBackendClass *class;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	class = E_COLLECTION_BACKEND_GET_CLASS (backend);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->create_resource_sync != NULL, FALSE);

	return class->create_resource_sync (
		backend, source, cancellable, error);
}

/**
 * e_collection_backend_create_resource:
 * @backend: an #ECollectionBackend
 * @source: an #ESource
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously creates a server-side resource described by @source.
 * For example, if @source describes a new calendar, an equivalent calendar
 * is created on the server.
 *
 * It is the implementor's responsibility to examine @source and determine
 * what the equivalent server-side resource would be.  If this cannot be
 * determined without ambiguity, the function must return an error.
 *
 * After the server-side resource is successfully created, the implementor
 * must also add an #ESource to @backend's #ECollectionBackend:server.  This
 * can either be done immediately or in response to some "resource created"
 * notification from the server.  The added #ESource can be @source itself
 * or a different #ESource instance that describes the new resource.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_collection_backend_create_resource_finish() to get the result of
 * the operation.
 *
 * Since: 3.6
 **/
void
e_collection_backend_create_resource (ECollectionBackend *backend,
                                      ESource *source,
                                      GCancellable *cancellable,
                                      GAsyncReadyCallback callback,
                                      gpointer user_data)
{
	ECollectionBackendClass *class;

	g_return_if_fail (E_IS_COLLECTION_BACKEND (backend));
	g_return_if_fail (E_IS_SOURCE (source));

	class = E_COLLECTION_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->create_resource != NULL);

	class->create_resource (
		backend, source, cancellable, callback, user_data);
}

/**
 * e_collection_backend_create_resource_finish:
 * @backend: an #ECollectionBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_collection_backend_create_resource().
 *
 * If an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
e_collection_backend_create_resource_finish (ECollectionBackend *backend,
                                             GAsyncResult *result,
                                             GError **error)
{
	ECollectionBackendClass *class;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), FALSE);
	g_return_val_if_fail (G_IS_ASYNC_RESULT (result), FALSE);

	class = E_COLLECTION_BACKEND_GET_CLASS (backend);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->create_resource_finish != NULL, FALSE);

	return class->create_resource_finish (backend, result, error);
}

/**
 * e_collection_backend_delete_resource_sync:
 * @backend: an #ECollectionBackend
 * @source: an #ESource
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Deletes a server-side resource described by @source.  The @source must
 * be a child of @backend's collection #EBackend:source.
 *
 * After the server-side resource is successfully deleted, the implementor
 * must also remove @source from the @backend's #ECollectionBackend:server.
 * This can either be done immediately or in response to some "resource
 * deleted" notification from the server.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
e_collection_backend_delete_resource_sync (ECollectionBackend *backend,
                                           ESource *source,
                                           GCancellable *cancellable,
                                           GError **error)
{
	ECollectionBackendClass *class;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	class = E_COLLECTION_BACKEND_GET_CLASS (backend);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->delete_resource_sync != NULL, FALSE);

	return class->delete_resource_sync (
		backend, source, cancellable, error);
}

/**
 * e_collection_backend_delete_resource:
 * @backend: an #ECollectionBackend
 * @source: an #ESource
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously deletes a server-side resource described by @source.
 * The @source must be a child of @backend's collection #EBackend:source.
 *
 * After the server-side resource is successfully deleted, the implementor
 * must also remove @source from the @backend's #ECollectionBackend:server.
 * This can either be done immediately or in response to some "resource
 * deleted" notification from the server.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_collection_backend_delete_resource_finish() to get the result of
 * the operation.
 *
 * Since: 3.6
 **/
void
e_collection_backend_delete_resource (ECollectionBackend *backend,
                                      ESource *source,
                                      GCancellable *cancellable,
                                      GAsyncReadyCallback callback,
                                      gpointer user_data)
{
	ECollectionBackendClass *class;

	g_return_if_fail (E_IS_COLLECTION_BACKEND (backend));
	g_return_if_fail (E_IS_SOURCE (source));

	class = E_COLLECTION_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->delete_resource != NULL);

	return class->delete_resource (
		backend, source, cancellable, callback, user_data);
}

/**
 * e_collection_backend_delete_resource_finish:
 * @backend: an #ECollectionBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_collection_backend_delete_resource().
 *
 * If an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
e_collection_backend_delete_resource_finish (ECollectionBackend *backend,
                                             GAsyncResult *result,
                                             GError **error)
{
	ECollectionBackendClass *class;

	g_return_val_if_fail (E_IS_COLLECTION_BACKEND (backend), FALSE);
	g_return_val_if_fail (G_IS_ASYNC_RESULT (result), FALSE);

	class = E_COLLECTION_BACKEND_GET_CLASS (backend);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->delete_resource_finish != NULL, FALSE);

	return class->delete_resource_finish (backend, result, error);
}

static void
collection_backend_child_authenticate_done_cb (GObject *source_object,
					       GAsyncResult *result,
					       gpointer user_data)
{
	ESource *source;
	GError *error = NULL;

	g_return_if_fail (E_IS_SOURCE (source_object));

	source = E_SOURCE (source_object);

	if (!e_source_invoke_authenticate_finish (source, result, &error) &&
	    !g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
		g_warning ("%s: Failed to invoke authenticate for '%s': %s", G_STRFUNC,
			e_source_get_uid (source), error ? error->message : "Unknown error");
	}

	g_clear_error (&error);
}

/**
 * e_collection_backend_authenticate_children:
 * @backend: an #ECollectionBackend
 * @credentials: credentials to authenticate with
 *
 * Authenticates all enabled children sources with the given @crendetials.
 * This is usually called when the collection source successfully used
 * the @credentials to connect to the (possibly) remote data store, to
 * open the childern too. Already connected child sources are skipped.
 *
 * Since: 3.16
 **/
void
e_collection_backend_authenticate_children (ECollectionBackend *backend,
					    const ENamedParameters *credentials)
{
	ESource *master_source, *child, *cred_source;
	ESourceRegistryServer *registry_server;
	ESourceCredentialsProvider *credentials_provider;
	GList *sources, *link;

	g_return_if_fail (E_IS_COLLECTION_BACKEND (backend));

	master_source = e_backend_get_source (E_BACKEND (backend));
	g_return_if_fail (master_source != NULL);

	registry_server = e_collection_backend_ref_server (backend);
	g_return_if_fail (registry_server != NULL);

	credentials_provider = e_source_registry_server_ref_credentials_provider (registry_server);
	sources = e_source_registry_server_list_sources (registry_server, NULL);
	for (link = sources; link; link = g_list_next (link)) {
		child = link->data;

		if (child && !e_source_equal (child, master_source) && e_source_get_enabled (child) && (
		    e_source_get_connection_status (child) == E_SOURCE_CONNECTION_STATUS_AWAITING_CREDENTIALS ||
		    e_source_get_connection_status (child) == E_SOURCE_CONNECTION_STATUS_DISCONNECTED)) {
			cred_source = e_source_credentials_provider_ref_credentials_source (credentials_provider, child);

			if (cred_source && e_source_equal (cred_source, master_source)) {
				e_source_invoke_authenticate (child, credentials, NULL, collection_backend_child_authenticate_done_cb, NULL);
			}

			g_clear_object (&cred_source);
		}
	}

	g_list_free_full (sources, g_object_unref);
	g_clear_object (&credentials_provider);
	g_clear_object (&registry_server);
}

/**
 * e_collection_backend_schedule_populate:
 * @backend: an #ECollectionBackend
 *
 * Schedules a call to populate() of the @backend on idle.
 * The function does nothing in case the @backend is offline.
 *
 * Since: 3.30
 **/
void
e_collection_backend_schedule_populate (ECollectionBackend *backend)
{
	g_return_if_fail (E_IS_COLLECTION_BACKEND (backend));

	if (e_backend_get_online (E_BACKEND (backend)))
		collection_backend_schedule_populate_idle (backend);
}
