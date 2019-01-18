/*
 * module-secret-monitor.c
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

/* XXX Yeah, yeah... */
#define SECRET_API_SUBJECT_TO_CHANGE

#include <libsecret/secret.h>

#include <libebackend/libebackend.h>

/* Standard GObject macros */
#define E_TYPE_SECRET_MONITOR \
	(e_secret_monitor_get_type ())
#define E_SECRET_MONITOR(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SECRET_MONITOR, ESecretMonitor))

/* XXX These intervals are borrowed from the 'cache-reaper' module, and
 *     are just as arbitrary here as they are there.  On startup we wait
 *     an hour to scan secrets, and thereafter repeat every 24 hours. */
#define INITIAL_INTERVAL_SECONDS  ( 1 * (60 * 60))
#define REGULAR_INTERVAL_SECONDS  (24 * (60 * 60))

typedef struct _ESecretMonitor ESecretMonitor;
typedef struct _ESecretMonitorClass ESecretMonitorClass;

struct _ESecretMonitor {
	EExtension parent;

	guint scan_timeout_id;
};

struct _ESecretMonitorClass {
	EExtensionClass parent_class;
};

/* XXX ESource's SecretSchema copied here for searching.
 *     Maybe add a searching function to e-source.[ch]? */

#define KEYRING_ITEM_ATTRIBUTE_UID	"e-source-uid"
#define KEYRING_ITEM_ATTRIBUTE_ORIGIN	"eds-origin"
#define KEYRING_ITEM_DISPLAY_FORMAT	"Evolution Data Source '%s'"

#ifdef DBUS_SERVICES_PREFIX
#define ORIGIN_KEY DBUS_SERVICES_PREFIX "." PACKAGE
#else
#define ORIGIN_KEY PACKAGE
#endif

static SecretSchema password_schema = {
	"org.gnome.Evolution.Data.Source",
	SECRET_SCHEMA_DONT_MATCH_NAME,
	{
		{ KEYRING_ITEM_ATTRIBUTE_UID, SECRET_SCHEMA_ATTRIBUTE_STRING },
		{ KEYRING_ITEM_ATTRIBUTE_ORIGIN, SECRET_SCHEMA_ATTRIBUTE_STRING },
		{ NULL, 0 }
	}
};

/* Module Entry Points */
void e_module_load (GTypeModule *type_module);
void e_module_unload (GTypeModule *type_module);

/* Forward Declarations */
GType e_secret_monitor_get_type (void);

G_DEFINE_DYNAMIC_TYPE (
	ESecretMonitor,
	e_secret_monitor,
	E_TYPE_EXTENSION)

static ESourceRegistryServer *
secret_monitor_get_server (ESecretMonitor *extension)
{
	EExtensible *extensible;

	extensible = e_extension_get_extensible (E_EXTENSION (extension));

	return E_SOURCE_REGISTRY_SERVER (extensible);
}

static gpointer
secret_monitor_scan_secrets_thread (gpointer user_data)
{
	ESourceRegistryServer *server;
	GHashTable *attributes;
	GList *list, *link;
	GError *local_error = NULL;

	/* We bail on the first error because 1) this processing is
	 * periodic and not critical, and 2) if a D-Bus call fails,
	 * subsequent D-Bus calls are also likely to fail. */

	server = E_SOURCE_REGISTRY_SERVER (user_data);

	attributes = g_hash_table_new (g_str_hash, g_str_equal);
	g_hash_table_insert (attributes, (gpointer) KEYRING_ITEM_ATTRIBUTE_ORIGIN, (gpointer) ORIGIN_KEY);

	/* List all items under our custom SecretSchema. */
	list = secret_service_search_sync (
		NULL, &password_schema, attributes,
		SECRET_SEARCH_ALL, NULL, &local_error);

	g_hash_table_destroy (attributes);

	for (link = list; link != NULL; link = g_list_next (link)) {
		SecretItem *item;
		ESource *source;
		const gchar *uid;

		item = SECRET_ITEM (link->data);

		/* Skip locked items. */
		if (secret_item_get_locked (item))
			continue;

		attributes = secret_item_get_attributes (item);

		uid = g_hash_table_lookup (attributes, KEYRING_ITEM_ATTRIBUTE_UID);

		/* No UID attribute?  Best leave it alone. */
		if (uid == NULL)
			continue;

		/* These are special keys, not referencing any real ESource */
		if (g_str_has_prefix (uid, "OAuth2::"))
			continue;

		source = e_source_registry_server_ref_source (server, uid);

		/* If we find a matching ESource, update the SecretItem's
		 * label based on the ESource's display name.  Otherwise,
		 * delete the orphaned SecretItem. */
		if (source != NULL) {
			gchar *new_label;
			gchar *old_label;

			new_label = e_source_dup_secret_label (source);
			old_label = secret_item_get_label (item);

			if (g_strcmp0 (old_label, new_label) != 0) {
				secret_item_set_label_sync (
					item, new_label, NULL, &local_error);
			}

			g_free (new_label);
			g_free (old_label);

		} else {
			secret_item_delete_sync (item, NULL, &local_error);
		}

		if (local_error != NULL)
			break;
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);

	if (local_error != NULL) {
		g_warning ("%s: %s", G_STRFUNC, local_error->message);
		g_error_free (local_error);
	}

	g_clear_object (&server);

	return NULL;
}

static gboolean
secret_monitor_scan_secrets_timeout_cb (gpointer user_data)
{
	GThread *thread;
	ESecretMonitor *extension;
	ESourceRegistryServer *server;
	GError *local_error = NULL;

	extension = E_SECRET_MONITOR (user_data);
	server = secret_monitor_get_server (extension);

	e_source_registry_debug_print ("Scanning and pruning saved passwords\n");

	/* Do the real work in a thread, so we can use synchronous
	 * libsecret calls and keep the logic flow easy to follow. */

	thread = g_thread_try_new (
		G_LOG_DOMAIN,
		secret_monitor_scan_secrets_thread,
		g_object_ref (server), &local_error);

	/* Sanity check. */
	g_warn_if_fail (
		((thread != NULL) && (local_error == NULL)) ||
		((thread == NULL) && (local_error != NULL)));

	if (thread != NULL)
		g_thread_unref (thread);

	if (local_error != NULL) {
		g_warning ("%s: %s", G_STRFUNC, local_error->message);
		g_error_free (local_error);
		g_object_unref (server);
	}

	/* Always explicitly reschedule since the initial
	 * interval is different than the regular interval. */
	extension->scan_timeout_id = e_named_timeout_add_seconds (
		REGULAR_INTERVAL_SECONDS,
		secret_monitor_scan_secrets_timeout_cb,
		extension);

	return G_SOURCE_REMOVE;
}

static void
secret_monitor_finalize (GObject *object)
{
	ESecretMonitor *extension;

	extension = E_SECRET_MONITOR (object);

	if (extension->scan_timeout_id > 0)
		g_source_remove (extension->scan_timeout_id);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_secret_monitor_parent_class)->finalize (object);
}

static void
e_secret_monitor_class_init (ESecretMonitorClass *class)
{
	GObjectClass *object_class;
	EExtensionClass *extension_class;

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = secret_monitor_finalize;

	extension_class = E_EXTENSION_CLASS (class);
	extension_class->extensible_type = E_TYPE_SOURCE_REGISTRY_SERVER;
}

static void
e_secret_monitor_class_finalize (ESecretMonitorClass *class)
{
}

static void
e_secret_monitor_init (ESecretMonitor *extension)
{
	/* Schedule the initial scan. */
	extension->scan_timeout_id = e_named_timeout_add_seconds (
		INITIAL_INTERVAL_SECONDS,
		secret_monitor_scan_secrets_timeout_cb,
		extension);
}

G_MODULE_EXPORT void
e_module_load (GTypeModule *type_module)
{
	e_secret_monitor_register_type (type_module);
}

G_MODULE_EXPORT void
e_module_unload (GTypeModule *type_module)
{
}

