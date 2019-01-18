/*
 * e-source.c
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
 * SECTION: e-source
 * @include: libedataserver/libedataserver.h
 * @short_description: Hierarchical data sources
 *
 * An #ESource (or "data source") is a description of a file or network
 * location where data can be obtained (such as a mail account), or a
 * description of a resource at that location (such as a mail folder).
 *
 * In more concrete terms, it's an interface for a key file.  All such
 * key files have a main group named [Data Source].  The keys in a
 * [Data Source] group map to #GObject properties in an #ESource.
 *
 * Additional groups in the key file are referred to as "extensions".
 * #ESourceExtension serves as the base class for writing interfaces
 * for these additional key file groups.  The keys in one of these
 * key file groups map to #GObject properties in some custom subclass
 * of #ESourceExtension which was written specifically for that key
 * file group.  For example, a key file might include a group named
 * [Calendar], whose keys map to #GObject properties in an extension
 * class named #ESourceCalendar.
 *
 * Each #ESource contains an internal dictionary of extension objects,
 * accessible by their key file group name.  e_source_get_extension()
 * can look up extension objects by name.
 *
 * An #ESource is identified by a unique identifier string, or "UID",
 * which is also the basename of the corresponding key file.  Additional
 * files related to the #ESource, such as cache files, are usually kept
 * in a directory named after the UID of the #ESource.  Similarly, the
 * password for an account described by an #ESource is kept in GNOME
 * Keyring under the UID of the #ESource.  This makes finding these
 * additional resources simple.
 *
 * Several extensions for common information such as authentication
 * details are built into libedataserver (#ESourceAuthentication, for
 * example).  Backend modules may also define their own extensions for
 * information and settings unique to the backend.  #ESourceExtension
 * subclasses written for specific backends are generally not available
 * to applications and shared libraries.  This is by design, to try and
 * keep backend-specific knowledge from creeping into places it doesn't
 * belong.
 *
 * As of 3.12, an #ESource with an #ESourceProxy extension can serve as a
 * #GProxyResolver.  Calling g_proxy_resolver_is_supported() on an #ESource
 * will reflect this constraint.  Attempting a proxy lookup operation on an
 * #ESource for which g_proxy_resolver_is_supported() returns %FALSE will
 * fail with %G_IO_ERROR_NOT_SUPPORTED.
 **/

#include "evolution-data-server-config.h"

#include <string.h>
#include <glib/gi18n-lib.h>

/* Private D-Bus classes. */
#include "e-dbus-source.h"

#include "e-data-server-util.h"
#include "e-secret-store.h"
#include "e-source-enumtypes.h"
#include "e-source-extension.h"
#include "e-uid.h"

/* built-in extension types */
#include "e-source-address-book.h"
#include "e-source-alarms.h"
#include "e-source-authentication.h"
#include "e-source-autocomplete.h"
#include "e-source-autoconfig.h"
#include "e-source-calendar.h"
#include "e-source-camel.h"
#include "e-source-collection.h"
#include "e-source-contacts.h"
#include "e-source-goa.h"
#include "e-source-ldap.h"
#include "e-source-local.h"
#include "e-source-mail-account.h"
#include "e-source-mail-composition.h"
#include "e-source-mail-identity.h"
#include "e-source-mail-signature.h"
#include "e-source-mail-submission.h"
#include "e-source-mail-transport.h"
#include "e-source-mdn.h"
#include "e-source-memo-list.h"
#include "e-source-offline.h"
#include "e-source-openpgp.h"
#include "e-source-proxy.h"
#include "e-source-refresh.h"
#include "e-source-resource.h"
#include "e-source-revision-guards.h"
#include "e-source-security.h"
#include "e-source-selectable.h"
#include "e-source-smime.h"
#include "e-source-task-list.h"
#include "e-source-uoa.h"
#include "e-source-weather.h"
#include "e-source-webdav.h"

#include "e-source.h"

#define E_SOURCE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE, ESourcePrivate))

#define PRIMARY_GROUP_NAME	"Data Source"

typedef struct _AsyncContext AsyncContext;
typedef struct _RemoveContext RemoveContext;

struct _ESourcePrivate {
	GDBusObject *dbus_object;
	GMainContext *main_context;

	GSource *changed;
	GMutex changed_lock;
	guint ignore_changed_signal;

	GSource *connection_status_change;
	GMutex connection_status_change_lock;
	ESourceConnectionStatus connection_status;

	GMutex property_lock;

	gchar *display_name;
	gchar *collate_key;
	gchar *parent;
	gchar *uid;

	/* The lock guards the key file and hash table. */

	GKeyFile *key_file;
	GRecMutex lock;
	GHashTable *extensions;

	gboolean enabled;
	gboolean initialized;
};

struct _AsyncContext {
	ESource *scratch_source;
	gchar *access_token;
	gint expires_in;
	gchar *password;
	gboolean permanently;
};

/* Used in e_source_remove_sync() */
struct _RemoveContext {
	GMainContext *main_context;
	GMainLoop *main_loop;
};

enum {
	PROP_0,
	PROP_DBUS_OBJECT,
	PROP_DISPLAY_NAME,
	PROP_ENABLED,
	PROP_MAIN_CONTEXT,
	PROP_PARENT,
	PROP_REMOTE_CREATABLE,
	PROP_REMOTE_DELETABLE,
	PROP_REMOVABLE,
	PROP_UID,
	PROP_WRITABLE,
	PROP_CONNECTION_STATUS
};

enum {
	CHANGED,
	CREDENTIALS_REQUIRED,
	AUTHENTICATE,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

/* Forward Declarations */
static void	e_source_initable_init	(GInitableIface *iface);
static void	e_source_proxy_resolver_init
					(GProxyResolverInterface *iface);

/* Private function shared only with ESourceRegistry. */
void		__e_source_private_replace_dbus_object
						(ESource *source,
						 GDBusObject *dbus_object);

G_DEFINE_TYPE_WITH_CODE (
	ESource,
	e_source,
	G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_source_initable_init)
	G_IMPLEMENT_INTERFACE (
		G_TYPE_PROXY_RESOLVER,
		e_source_proxy_resolver_init))

static void
async_context_free (AsyncContext *async_context)
{
	if (async_context->scratch_source != NULL)
		g_object_unref (async_context->scratch_source);

	g_free (async_context->access_token);
	g_free (async_context->password);

	g_slice_free (AsyncContext, async_context);
}

static RemoveContext *
remove_context_new (void)
{
	RemoveContext *remove_context;

	remove_context = g_slice_new0 (RemoveContext);

	remove_context->main_context = g_main_context_new ();

	remove_context->main_loop = g_main_loop_new (
		remove_context->main_context, FALSE);

	return remove_context;
}

static void
remove_context_free (RemoveContext *remove_context)
{
	g_main_loop_unref (remove_context->main_loop);
	g_main_context_unref (remove_context->main_context);

	g_slice_free (RemoveContext, remove_context);
}

static void
source_find_extension_classes_rec (GType parent_type,
                                   GHashTable *hash_table)
{
	GType *children;
	guint n_children, ii;

	children = g_type_children (parent_type, &n_children);

	for (ii = 0; ii < n_children; ii++) {
		GType type = children[ii];
		ESourceExtensionClass *class;
		gpointer key;

		/* Recurse over the child's children. */
		source_find_extension_classes_rec (type, hash_table);

		/* Skip abstract types. */
		if (G_TYPE_IS_ABSTRACT (type))
			continue;

		class = g_type_class_ref (type);
		key = (gpointer) class->name;

		if (key != NULL)
			g_hash_table_insert (hash_table, key, class);
		else
			g_type_class_unref (class);
	}

	g_free (children);
}

static GHashTable *
source_find_extension_classes (void)
{
	GHashTable *hash_table;

	hash_table = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) NULL,
		(GDestroyNotify) g_type_class_unref);

	source_find_extension_classes_rec (
		E_TYPE_SOURCE_EXTENSION, hash_table);

	return hash_table;
}

static void
source_localized_hack (GKeyFile *key_file,
                       const gchar *group_name,
                       const gchar *key,
                       const gchar *new_value)
{
	const gchar * const *language_names;
	gint ii;

	/* XXX If we're changing a string key that has translations,
	 *     set "key[$CURRENT_LOCALE]" (if available) to the new
	 *     value so g_key_file_get_locale_string() will pick it
	 *     up.  This is not a perfect solution however.  When a
	 *     different locale is used the value may revert to its
	 *     original localized string.  Good enough for now. */

	language_names = g_get_language_names ();

	for (ii = 0; language_names[ii] != NULL; ii++) {
		gboolean has_localized_key;
		gchar *localized_key;

		localized_key = g_strdup_printf (
			"%s[%s]", key, language_names[ii]);
		has_localized_key = g_key_file_has_key (
			key_file, group_name, localized_key, NULL);

		if (has_localized_key)
			g_key_file_set_string (
				key_file, group_name,
				localized_key, new_value);

		g_free (localized_key);

		if (has_localized_key)
			return;
	}

	g_key_file_set_string (key_file, group_name, key, new_value);
}

static gboolean
source_check_values_differ (GType g_type,
                            const GValue *value,
                            const GValue *value2)
{
	gboolean differ = TRUE;
	GValue *value1;

	g_return_val_if_fail (value != NULL, TRUE);
	g_return_val_if_fail (value2 != NULL, TRUE);

	value1 = g_slice_new0 (GValue);
	g_value_init (value1, g_type);
	g_value_copy (value2, value1);

	if (g_value_transform (value, value1)) {
		#define check_type(name,get) G_STMT_START { \
			if (G_VALUE_HOLDS_ ## name (value1)) { \
				differ = g_value_get_ ## get (value1) != g_value_get_ ## get (value2); \
				break; \
			} } G_STMT_END

		do {
			check_type (BOOLEAN, boolean);
			check_type (CHAR, schar);
			check_type (DOUBLE, double);
			check_type (ENUM, enum);
			check_type (FLAGS, flags);
			check_type (FLOAT, float);
			check_type (GTYPE, gtype);
			check_type (INT, int);
			check_type (INT64, int64);
			check_type (LONG, long);
			check_type (POINTER, pointer);
			check_type (UCHAR, uchar);
			check_type (UINT, uint);
			check_type (UINT64, uint64);
			check_type (ULONG, ulong);

			if (G_VALUE_HOLDS_STRING (value1)) {
				differ = g_strcmp0 (g_value_get_string (value1), g_value_get_string (value2)) != 0;
				break;
			}

			if (G_VALUE_HOLDS_VARIANT (value1)) {
				GVariant *variant1, *variant2;

				variant1 = g_value_get_variant (value1);
				variant2 = g_value_get_variant (value2);
				differ = g_variant_compare (variant1, variant2) != 0;
				break;
			}
		} while (FALSE);

		#undef check_type
	}

	g_value_unset (value1);
	g_slice_free (GValue, value1);

	return differ;
}

static void
source_set_key_file_from_property (GObject *object,
                                   GParamSpec *pspec,
                                   GKeyFile *key_file,
                                   const gchar *group_name)
{
	GValue *pvalue;
	GValue *svalue;
	gchar *key;

	pvalue = g_slice_new0 (GValue);
	g_value_init (pvalue, pspec->value_type);
	g_object_get_property (object, pspec->name, pvalue);

	svalue = g_slice_new0 (GValue);
	g_value_init (svalue, G_TYPE_STRING);

	key = e_source_parameter_to_key (pspec->name);

	/* For the most part we can just transform any supported
	 * property type to a string, with a couple exceptions. */

	/* Transforming a boolean GValue to a string results in
	 * "TRUE" or "FALSE" (all uppercase), but GKeyFile only
	 * recognizes "true" or "false" (all lowercase).  So we
	 * have to use g_key_file_set_boolean(). */
	if (G_VALUE_HOLDS_BOOLEAN (pvalue)) {
		gboolean v_boolean = g_value_get_boolean (pvalue);
		g_key_file_set_boolean (key_file, group_name, key, v_boolean);

	/* Store UIN64 in hexa */
	} else if (G_VALUE_HOLDS_UINT64 (pvalue)) {
		gchar *v_str;

		v_str = g_strdup_printf (
			"%016" G_GINT64_MODIFIER "X",
			g_value_get_uint64 (pvalue));
		g_key_file_set_string (key_file, group_name, key, v_str);
		g_free (v_str);

	/* String GValues may contain characters that need escaping. */
	} else if (G_VALUE_HOLDS_STRING (pvalue)) {
		const gchar *v_string = g_value_get_string (pvalue);

		if (v_string == NULL)
			v_string = "";

		/* Special case for localized "DisplayName" keys. */
		source_localized_hack (key_file, group_name, key, v_string);

	/* Transforming an enum GValue to a string results in
	 * the GEnumValue name.  We want the shorter nickname. */
	} else if (G_VALUE_HOLDS_ENUM (pvalue)) {
		GParamSpecEnum *enum_pspec;
		GEnumClass *enum_class;
		GEnumValue *enum_value;
		gint value;

		enum_pspec = G_PARAM_SPEC_ENUM (pspec);
		enum_class = enum_pspec->enum_class;

		value = g_value_get_enum (pvalue);
		enum_value = g_enum_get_value (enum_class, value);

		if (enum_value == NULL) {
			value = enum_pspec->default_value;
			enum_value = g_enum_get_value (enum_class, value);
		}

		if (enum_value != NULL)
			g_key_file_set_string (
				key_file, group_name, key,
				enum_value->value_nick);

	} else if (G_VALUE_HOLDS (pvalue, G_TYPE_STRV)) {
		const gchar **strv = g_value_get_boxed (pvalue);
		guint length = 0;

		if (strv != NULL)
			length = g_strv_length ((gchar **) strv);
		g_key_file_set_string_list (
			key_file, group_name, key, strv, length);

	/* For GValues holding a GFile object we save the URI. */
	} else if (G_VALUE_HOLDS (pvalue, G_TYPE_FILE)) {
		GFile *file = g_value_get_object (pvalue);
		gchar *uri = NULL;

		if (file != NULL)
			uri = g_file_get_uri (file);
		g_key_file_set_string (
			key_file, group_name, key,
			(uri != NULL) ? uri : "");
		g_free (uri);

	} else if (g_value_transform (pvalue, svalue)) {
		const gchar *value = g_value_get_string (svalue);
		g_key_file_set_value (key_file, group_name, key, value);
	}

	g_free (key);
	g_value_unset (pvalue);
	g_value_unset (svalue);
	g_slice_free (GValue, pvalue);
	g_slice_free (GValue, svalue);
}

static void
source_set_property_from_key_file (GObject *object,
                                   GParamSpec *pspec,
                                   GKeyFile *key_file,
                                   const gchar *group_name)
{
	gchar *key;
	GValue *value;
	GError *local_error = NULL;

	value = g_slice_new0 (GValue);
	key = e_source_parameter_to_key (pspec->name);

	if (G_IS_PARAM_SPEC_CHAR (pspec) ||
	    G_IS_PARAM_SPEC_UCHAR (pspec) ||
	    G_IS_PARAM_SPEC_INT (pspec) ||
	    G_IS_PARAM_SPEC_UINT (pspec) ||
	    G_IS_PARAM_SPEC_LONG (pspec) ||
	    G_IS_PARAM_SPEC_ULONG (pspec)) {
		gint v_int;

		v_int = g_key_file_get_integer (
			key_file, group_name, key, &local_error);
		if (local_error == NULL) {
			g_value_init (value, G_TYPE_INT);
			g_value_set_int (value, v_int);
		}

	} else if (G_IS_PARAM_SPEC_INT64 (pspec)) {
		gint64 v_int64;

		v_int64 = g_key_file_get_int64 (
			key_file, group_name, key, &local_error);
		if (local_error == NULL) {
			g_value_init (value, G_TYPE_INT64);
			g_value_set_int64 (value, v_int64);
		}

	} else if (G_IS_PARAM_SPEC_UINT64 (pspec)) {
		guint64 v_uint64;
		gchar *v_str;

		v_str = g_key_file_get_string (
			key_file, group_name, key, &local_error);
		if (local_error == NULL) {
			v_uint64 = g_ascii_strtoull (v_str, NULL, 16);

			g_value_init (value, G_TYPE_UINT64);
			g_value_set_uint64 (value, v_uint64);
		}

		g_free (v_str);

	} else if (G_IS_PARAM_SPEC_BOOLEAN (pspec)) {
		gboolean v_boolean;

		v_boolean = g_key_file_get_boolean (
			key_file, group_name, key, &local_error);
		if (local_error == NULL) {
			g_value_init (value, G_TYPE_BOOLEAN);
			g_value_set_boolean (value, v_boolean);
		}

	} else if (G_IS_PARAM_SPEC_ENUM (pspec)) {
		gchar *nick;

		nick = g_key_file_get_string (
			key_file, group_name, key, &local_error);
		if (local_error == NULL) {
			GParamSpecEnum *enum_pspec;
			GEnumValue *enum_value;

			enum_pspec = G_PARAM_SPEC_ENUM (pspec);
			enum_value = g_enum_get_value_by_nick (
				enum_pspec->enum_class, nick);
			if (enum_value != NULL) {
				g_value_init (value, pspec->value_type);
				g_value_set_enum (value, enum_value->value);
			}
			g_free (nick);
		}

	} else if (G_IS_PARAM_SPEC_FLOAT (pspec) ||
		   G_IS_PARAM_SPEC_DOUBLE (pspec)) {
		gdouble v_double;

		v_double = g_key_file_get_double (
			key_file, group_name, key, &local_error);
		if (local_error == NULL) {
			g_value_init (value, G_TYPE_DOUBLE);
			g_value_set_double (value, v_double);
		}

	} else if (G_IS_PARAM_SPEC_STRING (pspec)) {
		gchar *v_string;

		/* Get the localized string if present. */
		v_string = g_key_file_get_locale_string (
			key_file, group_name, key, NULL, &local_error);
		if (local_error == NULL) {
			g_value_init (value, G_TYPE_STRING);
			g_value_take_string (value, v_string);
		}

	} else if (g_type_is_a (pspec->value_type, G_TYPE_STRV)) {
		gchar **strv;

		strv = g_key_file_get_string_list (
			key_file, group_name, key, NULL, &local_error);
		if (local_error == NULL) {
			g_value_init (value, G_TYPE_STRV);
			g_value_take_boxed (value, strv);
		}

	} else if (g_type_is_a (pspec->value_type, G_TYPE_FILE)) {
		gchar *uri;

		/* Create the GFile from the URI string. */
		uri = g_key_file_get_locale_string (
			key_file, group_name, key, NULL, &local_error);
		if (local_error == NULL) {
			GFile *file = NULL;
			if (uri != NULL && *uri != '\0')
				file = g_file_new_for_uri (uri);
			g_value_init (value, pspec->value_type);
			g_value_take_object (value, file);
			g_free (uri);
		}

	} else {
		g_warning (
			"No GKeyFile-to-GValue converter defined "
			"for type '%s'", G_PARAM_SPEC_TYPE_NAME (pspec));
	}

	/* If a value could not be retrieved from the key
	 * file, restore the property to its default value. */
	if (local_error != NULL) {
		g_value_init (value, pspec->value_type);
		g_param_value_set_default (pspec, value);
		g_error_free (local_error);
	}

	if (G_IS_VALUE (value)) {
		GValue *cvalue;

		cvalue = g_slice_new0 (GValue);
		g_value_init (cvalue, pspec->value_type);
		g_object_get_property (object, pspec->name, cvalue);

		/* This is because the g_object_set_property() invokes "notify" signal
		 * on the set property, even if the value did not change, which creates
		 * false notifications, which can cause UI or background activities
		 * without any real reason (especially with the ''enabled' property load). */
		if (!G_IS_VALUE (cvalue) || source_check_values_differ (pspec->value_type, value, cvalue))
			g_object_set_property (object, pspec->name, value);

		if (G_IS_VALUE (cvalue))
			g_value_unset (cvalue);
		g_slice_free (GValue, cvalue);

		g_value_unset (value);
	}

	g_slice_free (GValue, value);
	g_free (key);
}

static void
source_load_from_key_file (GObject *object,
                           GKeyFile *key_file,
                           const gchar *group_name)
{
	GObjectClass *class;
	GParamSpec **properties;
	guint n_properties, ii;

	class = G_OBJECT_GET_CLASS (object);
	properties = g_object_class_list_properties (class, &n_properties);

	g_object_freeze_notify (object);

	for (ii = 0; ii < n_properties; ii++) {
		if (properties[ii]->flags & E_SOURCE_PARAM_SETTING) {
			source_set_property_from_key_file (
				object, properties[ii], key_file, group_name);
		}
	}

	g_object_thaw_notify (object);

	g_free (properties);
}

static void
source_save_to_key_file (GObject *object,
                         GKeyFile *key_file,
                         const gchar *group_name)
{
	GObjectClass *class;
	GParamSpec **properties;
	guint n_properties, ii;

	class = G_OBJECT_GET_CLASS (object);
	properties = g_object_class_list_properties (class, &n_properties);

	for (ii = 0; ii < n_properties; ii++) {
		if (properties[ii]->flags & E_SOURCE_PARAM_SETTING) {
			source_set_key_file_from_property (
				object, properties[ii], key_file, group_name);
		}
	}

	g_free (properties);
}

static gboolean
source_parse_dbus_data (ESource *source,
                        GError **error)
{
	GHashTableIter iter;
	EDBusObject *dbus_object;
	EDBusSource *dbus_source;
	GKeyFile *key_file;
	gpointer group_name;
	gpointer extension;
	gchar *data;
	gboolean success;

	if (!source->priv->dbus_object)
		return FALSE;

	dbus_object = E_DBUS_OBJECT (source->priv->dbus_object);

	dbus_source = e_dbus_object_get_source (dbus_object);
	data = e_dbus_source_dup_data (dbus_source);
	g_object_unref (dbus_source);

	g_return_val_if_fail (data != NULL, FALSE);

	key_file = source->priv->key_file;

	success = g_key_file_load_from_data (
		key_file, data, strlen (data),
		G_KEY_FILE_KEEP_COMMENTS |
		G_KEY_FILE_KEEP_TRANSLATIONS,
		error);

	g_free (data);
	data = NULL;

	if (!success)
		return FALSE;

	/* Make sure the key file has a [Data Source] group. */
	if (!g_key_file_has_group (key_file, PRIMARY_GROUP_NAME)) {
		g_set_error (
			error, G_KEY_FILE_ERROR,
			G_KEY_FILE_ERROR_GROUP_NOT_FOUND,
			_("Source file is missing a [%s] group"),
			PRIMARY_GROUP_NAME);
		return FALSE;
	}

	/* Load key file values from the [Data Source] group and from
	 * any other groups for which an extension object has already
	 * been created.  Note that not all the extension classes may
	 * be registered at this point, so avoid attempting to create
	 * new extension objects here.  Extension objects are created
	 * on-demand in e_source_get_extension(). */

	source_load_from_key_file (
		G_OBJECT (source), key_file, PRIMARY_GROUP_NAME);

	g_hash_table_iter_init (&iter, source->priv->extensions);
	while (g_hash_table_iter_next (&iter, &group_name, &extension))
		source_load_from_key_file (extension, key_file, group_name);

	return TRUE;
}

static void
source_notify_dbus_data_cb (EDBusSource *dbus_source,
                            GParamSpec *pspec,
                            ESource *source)
{
	GError *local_error = NULL;

	g_rec_mutex_lock (&source->priv->lock);

	/* Since the source data came from a GKeyFile structure on the
	 * server-side, this should never fail.  But we'll print error
	 * messages to the terminal just in case. */
	source_parse_dbus_data (source, &local_error);

	if (local_error != NULL) {
		g_warning ("%s", local_error->message);
		g_error_free (local_error);
	}

	g_rec_mutex_unlock (&source->priv->lock);
}

static gboolean
source_update_connection_status_internal (ESource *source,
					  EDBusSource *dbus_source)
{
	ESourceConnectionStatus connection_status_value;
	gchar *connection_status;
	gboolean changed = FALSE;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (dbus_source != NULL, FALSE);

	connection_status_value = E_SOURCE_CONNECTION_STATUS_DISCONNECTED;
	connection_status = e_dbus_source_dup_connection_status (dbus_source);

	if (connection_status) {
		GEnumClass *enum_class;
		GEnumValue *enum_value;

		enum_class = g_type_class_ref (E_TYPE_SOURCE_CONNECTION_STATUS);
		enum_value = g_enum_get_value_by_nick (enum_class, connection_status);

		if (enum_value) {
			connection_status_value = enum_value->value;
		} else if (!*connection_status) {
			connection_status_value = E_SOURCE_CONNECTION_STATUS_DISCONNECTED;
		} else {
			g_warning ("%s: Unknown connection status: '%s'", G_STRFUNC, connection_status);
		}

		g_type_class_unref (enum_class);
		g_free (connection_status);
	}

	if (source->priv->connection_status != connection_status_value) {
		source->priv->connection_status = connection_status_value;
		changed = TRUE;
	}

	return changed;
}

static gboolean
source_idle_connection_status_change_cb (gpointer user_data)
{
	ESource *source = E_SOURCE (user_data);
	EDBusObject *dbus_object;
	EDBusSource *dbus_source;
	gboolean changed = FALSE;

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_mutex_lock (&source->priv->connection_status_change_lock);
	if (source->priv->connection_status_change != NULL) {
		g_source_unref (source->priv->connection_status_change);
		source->priv->connection_status_change = NULL;
	}
	g_mutex_unlock (&source->priv->connection_status_change_lock);

	g_object_freeze_notify (G_OBJECT (source));
	g_mutex_lock (&source->priv->property_lock);

	if (source->priv->dbus_object) {
		dbus_object = E_DBUS_OBJECT (source->priv->dbus_object);

		dbus_source = e_dbus_object_get_source (dbus_object);
		changed = source_update_connection_status_internal (source, dbus_source);
		g_object_unref (dbus_source);
	}

	if (changed)
		g_object_notify (G_OBJECT (source), "connection-status");

	g_mutex_unlock (&source->priv->property_lock);
	g_object_thaw_notify (G_OBJECT (source));

	return FALSE;
}

static void
source_notify_dbus_connection_status_cb (EDBusSource *dbus_source,
					 GParamSpec *pspec,
					 ESource *source)
{
	g_mutex_lock (&source->priv->connection_status_change_lock);
	if (source->priv->connection_status_change == NULL &&
	    source->priv->initialized) {
		source->priv->connection_status_change = g_idle_source_new ();
		g_source_set_callback (
			source->priv->connection_status_change,
			source_idle_connection_status_change_cb,
			g_object_ref (source), g_object_unref);
		g_source_attach (
			source->priv->connection_status_change,
			source->priv->main_context);
	}
	g_mutex_unlock (&source->priv->connection_status_change_lock);
}

static ESourceCredentialsReason
source_credentials_reason_from_text (const gchar *arg_reason)
{
	ESourceCredentialsReason reason = E_SOURCE_CREDENTIALS_REASON_UNKNOWN;

	if (arg_reason && *arg_reason) {
		GEnumClass *enum_class;
		GEnumValue *enum_value;

		enum_class = g_type_class_ref (E_TYPE_SOURCE_CREDENTIALS_REASON);
		enum_value = g_enum_get_value_by_nick (enum_class, arg_reason);

		if (enum_value) {
			reason = enum_value->value;
		} else {
			g_warning ("%s: Unknown reason enum: '%s'", G_STRFUNC, arg_reason);
		}

		g_type_class_unref (enum_class);
	}

	return reason;
}

static GTlsCertificateFlags
source_certificate_errors_from_text (const gchar *arg_certificate_errors)
{
	GTlsCertificateFlags certificate_errors = 0;

	if (arg_certificate_errors && *arg_certificate_errors) {
		GFlagsClass *flags_class;
		gchar **flags_strv;
		gsize ii;

		flags_class = g_type_class_ref (G_TYPE_TLS_CERTIFICATE_FLAGS);
		flags_strv = g_strsplit (arg_certificate_errors, ":", -1);
		for (ii = 0; flags_strv[ii] != NULL; ii++) {
			GFlagsValue *flags_value;

			flags_value = g_flags_get_value_by_nick (flags_class, flags_strv[ii]);
			if (flags_value != NULL) {
				certificate_errors |= flags_value->value;
			} else {
				g_warning ("%s: Unknown flag: '%s'", G_STRFUNC, flags_strv[ii]);
			}
		}
		g_strfreev (flags_strv);
		g_type_class_unref (flags_class);
	}

	return certificate_errors;
}

static void
source_dbus_credentials_required_cb (EDBusSource *dbus_source,
				     const gchar *arg_reason,
				     const gchar *arg_certificate_pem,
				     const gchar *arg_certificate_errors,
				     const gchar *arg_dbus_error_name,
				     const gchar *arg_dbus_error_message,
				     ESource *source)
{
	ESourceCredentialsReason reason;
	GTlsCertificateFlags certificate_errors;
	GError *op_error = NULL;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (arg_reason != NULL);
	g_return_if_fail (arg_certificate_pem != NULL);
	g_return_if_fail (arg_certificate_errors != NULL);
	g_return_if_fail (arg_dbus_error_name != NULL);
	g_return_if_fail (arg_dbus_error_message != NULL);

	reason = source_credentials_reason_from_text (arg_reason);
	certificate_errors = source_certificate_errors_from_text (arg_certificate_errors);

	if (*arg_dbus_error_name) {
		op_error = g_dbus_error_new_for_dbus_error (arg_dbus_error_name, arg_dbus_error_message);
		g_dbus_error_strip_remote_error (op_error);
	}

	/* This is delivered in the GDBus thread */
	e_source_emit_credentials_required (source, reason, arg_certificate_pem, certificate_errors, op_error);

	g_clear_error (&op_error);
}

static gboolean
source_dbus_authenticate_cb (EDBusSource *dbus_interface,
			     const gchar *const *arg_credentials,
			     ESource *source)
{
	ENamedParameters *credentials;

	credentials = e_named_parameters_new_strv (arg_credentials);

	/* This is delivered in the GDBus thread */
	g_signal_emit (source, signals[AUTHENTICATE], 0, credentials);

	e_named_parameters_free (credentials);

	return TRUE;
}


static gboolean
source_idle_changed_cb (gpointer user_data)
{
	ESource *source = E_SOURCE (user_data);

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_mutex_lock (&source->priv->changed_lock);
	if (source->priv->changed != NULL) {
		g_source_unref (source->priv->changed);
		source->priv->changed = NULL;
	}
	g_mutex_unlock (&source->priv->changed_lock);

	g_signal_emit (source, signals[CHANGED], 0);

	return FALSE;
}

static void
source_set_dbus_object (ESource *source,
                        EDBusObject *dbus_object)
{
	/* D-Bus object will be NULL when configuring a new source. */
	if (dbus_object == NULL)
		return;

	g_return_if_fail (E_DBUS_IS_OBJECT (dbus_object));
	g_return_if_fail (source->priv->dbus_object == NULL);

	source->priv->dbus_object = g_object_ref (dbus_object);
}

static void
source_set_main_context (ESource *source,
                         GMainContext *main_context)
{
	g_return_if_fail (source->priv->main_context == NULL);

	source->priv->main_context =
		(main_context != NULL) ?
		g_main_context_ref (main_context) :
		g_main_context_ref_thread_default ();
}

static void
source_set_uid (ESource *source,
                const gchar *uid)
{
	/* The "uid" argument will usually be NULL unless called
	 * from e_source_new_with_uid().  If NULL, we'll pick up
	 * a UID in source_initable_init(). */

	g_return_if_fail (source->priv->uid == NULL);

	source->priv->uid = g_strdup (uid);
}

static void
source_set_property (GObject *object,
                     guint property_id,
                     const GValue *value,
                     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_DBUS_OBJECT:
			source_set_dbus_object (
				E_SOURCE (object),
				g_value_get_object (value));
			return;

		case PROP_DISPLAY_NAME:
			e_source_set_display_name (
				E_SOURCE (object),
				g_value_get_string (value));
			return;

		case PROP_ENABLED:
			e_source_set_enabled (
				E_SOURCE (object),
				g_value_get_boolean (value));
			return;

		case PROP_MAIN_CONTEXT:
			source_set_main_context (
				E_SOURCE (object),
				g_value_get_boxed (value));
			return;

		case PROP_PARENT:
			e_source_set_parent (
				E_SOURCE (object),
				g_value_get_string (value));
			return;

		case PROP_UID:
			source_set_uid (
				E_SOURCE (object),
				g_value_get_string (value));
			return;

		case PROP_CONNECTION_STATUS:
			e_source_set_connection_status (E_SOURCE (object),
				g_value_get_enum (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_get_property (GObject *object,
                     guint property_id,
                     GValue *value,
                     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_DBUS_OBJECT:
			g_value_take_object (
				value, e_source_ref_dbus_object (
				E_SOURCE (object)));
			return;

		case PROP_DISPLAY_NAME:
			g_value_take_string (
				value, e_source_dup_display_name (
				E_SOURCE (object)));
			return;

		case PROP_ENABLED:
			g_value_set_boolean (
				value, e_source_get_enabled (
				E_SOURCE (object)));
			return;

		case PROP_MAIN_CONTEXT:
			g_value_take_boxed (
				value, e_source_ref_main_context (
				E_SOURCE (object)));
			return;

		case PROP_PARENT:
			g_value_take_string (
				value, e_source_dup_parent (
				E_SOURCE (object)));
			return;

		case PROP_REMOTE_CREATABLE:
			g_value_set_boolean (
				value, e_source_get_remote_creatable (
				E_SOURCE (object)));
			return;

		case PROP_REMOTE_DELETABLE:
			g_value_set_boolean (
				value, e_source_get_remote_deletable (
				E_SOURCE (object)));
			return;

		case PROP_REMOVABLE:
			g_value_set_boolean (
				value, e_source_get_removable (
				E_SOURCE (object)));
			return;

		case PROP_UID:
			g_value_take_string (
				value, e_source_dup_uid (
				E_SOURCE (object)));
			return;

		case PROP_WRITABLE:
			g_value_set_boolean (
				value, e_source_get_writable (
				E_SOURCE (object)));
			return;

		case PROP_CONNECTION_STATUS:
			g_value_set_enum (value,
				e_source_get_connection_status (E_SOURCE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_dispose (GObject *object)
{
	ESourcePrivate *priv;

	priv = E_SOURCE_GET_PRIVATE (object);

	/* Lock & unlock to make sure any pending operations in other threads
	   which use this lock are already done */
	g_rec_mutex_lock (&priv->lock);
	g_rec_mutex_unlock (&priv->lock);

	g_mutex_lock (&priv->property_lock);

	if (priv->dbus_object != NULL) {
		EDBusObject *dbus_object;
		EDBusSource *dbus_source;

		dbus_object = E_DBUS_OBJECT (priv->dbus_object);

		dbus_source = e_dbus_object_get_source (dbus_object);
		if (dbus_source != NULL) {
			g_signal_handlers_disconnect_matched (
				dbus_source, G_SIGNAL_MATCH_DATA,
				0, 0, NULL, NULL, object);
			g_object_unref (dbus_source);
		}

		g_object_unref (priv->dbus_object);
		priv->dbus_object = NULL;
	}

	g_mutex_unlock (&priv->property_lock);

	if (priv->main_context != NULL) {
		g_main_context_unref (priv->main_context);
		priv->main_context = NULL;
	}

	/* XXX Maybe not necessary to acquire the lock? */
	g_mutex_lock (&priv->changed_lock);
	if (priv->changed != NULL) {
		g_source_destroy (priv->changed);
		g_source_unref (priv->changed);
		priv->changed = NULL;
	}
	g_mutex_unlock (&priv->changed_lock);

	g_mutex_lock (&priv->connection_status_change_lock);
	if (priv->connection_status_change != NULL) {
		g_source_destroy (priv->connection_status_change);
		g_source_unref (priv->connection_status_change);
		priv->connection_status_change = NULL;
	}
	g_mutex_unlock (&priv->connection_status_change_lock);

	g_hash_table_remove_all (priv->extensions);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_source_parent_class)->dispose (object);
}

static void
source_finalize (GObject *object)
{
	ESourcePrivate *priv;

	priv = E_SOURCE_GET_PRIVATE (object);

	g_mutex_clear (&priv->changed_lock);
	g_mutex_clear (&priv->connection_status_change_lock);
	g_mutex_clear (&priv->property_lock);

	g_free (priv->display_name);
	g_free (priv->collate_key);
	g_free (priv->parent);
	g_free (priv->uid);

	g_key_file_free (priv->key_file);
	g_rec_mutex_clear (&priv->lock);
	g_hash_table_destroy (priv->extensions);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_parent_class)->finalize (object);
}

static void
source_notify (GObject *object,
               GParamSpec *pspec)
{
	if ((pspec->flags & E_SOURCE_PARAM_SETTING) != 0)
		e_source_changed (E_SOURCE (object));
}

/* Helper for source_remove_sync() */
static gboolean
source_remove_main_loop_quit_cb (gpointer user_data)
{
	GMainLoop *main_loop = user_data;

	g_main_loop_quit (main_loop);

	return FALSE;
}

/* Helper for e_source_remove_sync() */
static void
source_remove_notify_dbus_object_cb (ESource *source,
                                     GParamSpec *pspec,
                                     RemoveContext *remove_context)
{
	GDBusObject *dbus_object;

	dbus_object = e_source_ref_dbus_object (source);

	/* The GDBusObject will be NULL once the ESourceRegistry
	 * receives an "object-removed" signal for this ESource. */
	if (dbus_object == NULL) {
		GSource *idle_source;

		idle_source = g_idle_source_new ();
		g_source_set_callback (
			idle_source,
			source_remove_main_loop_quit_cb,
			g_main_loop_ref (remove_context->main_loop),
			(GDestroyNotify) g_main_loop_unref);
		g_source_attach (idle_source, remove_context->main_context);
		g_source_unref (idle_source);
	}

	g_clear_object (&dbus_object);
}

static gboolean
source_remove_sync (ESource *source,
                    GCancellable *cancellable,
                    GError **error)
{
	EDBusSourceRemovable *dbus_interface = NULL;
	GDBusObject *dbus_object;
	RemoveContext *remove_context;
	gulong notify_dbus_object_id;
	GError *local_error = NULL;

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		dbus_interface =
			e_dbus_object_get_source_removable (
			E_DBUS_OBJECT (dbus_object));
		g_object_unref (dbus_object);
	}

	if (dbus_interface == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_PERMISSION_DENIED,
			_("Data source “%s” is not removable"),
			e_source_get_display_name (source));
		return FALSE;
	}

	remove_context = remove_context_new ();
	g_main_context_push_thread_default (remove_context->main_context);

	notify_dbus_object_id = g_signal_connect (
		source, "notify::dbus-object",
		G_CALLBACK (source_remove_notify_dbus_object_cb),
		remove_context);

	e_dbus_source_removable_call_remove_sync (
		dbus_interface, cancellable, &local_error);

	/* Wait for the ESourceRegistry to remove our GDBusObject while
	 * handling an "object-removed" signal from the registry service.
	 * But also set a short timeout to avoid getting deadlocked here. */
	if (local_error == NULL) {
		GSource *timeout_source;

		timeout_source = g_timeout_source_new_seconds (2);
		g_source_set_callback (
			timeout_source,
			source_remove_main_loop_quit_cb,
			g_main_loop_ref (remove_context->main_loop),
			(GDestroyNotify) g_main_loop_unref);
		g_source_attach (timeout_source, remove_context->main_context);
		g_source_unref (timeout_source);

		g_main_loop_run (remove_context->main_loop);
	}

	g_signal_handler_disconnect (source, notify_dbus_object_id);

	g_main_context_pop_thread_default (remove_context->main_context);
	remove_context_free (remove_context);

	g_object_unref (dbus_interface);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for source_remove() */
static void
source_remove_thread (GSimpleAsyncResult *simple,
                      GObject *object,
                      GCancellable *cancellable)
{
	GError *local_error = NULL;

	e_source_remove_sync (E_SOURCE (object), cancellable, &local_error);

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

static void
source_remove (ESource *source,
               GCancellable *cancellable,
               GAsyncReadyCallback callback,
               gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = g_simple_async_result_new (
		G_OBJECT (source), callback, user_data, source_remove);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_run_in_thread (
		simple, source_remove_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

static gboolean
source_remove_finish (ESource *source,
                      GAsyncResult *result,
                      GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (source), source_remove), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static gboolean
source_write_sync (ESource *source,
                   GCancellable *cancellable,
                   GError **error)
{
	EDBusSourceWritable *dbus_interface = NULL;
	GDBusObject *dbus_object;
	gchar *data;
	GError *local_error = NULL;

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		dbus_interface =
			e_dbus_object_get_source_writable (
			E_DBUS_OBJECT (dbus_object));
		g_object_unref (dbus_object);
	}

	if (dbus_interface == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_PERMISSION_DENIED,
			_("Data source “%s” is not writable"),
			e_source_get_display_name (source));
		return FALSE;
	}

	data = e_source_to_string (source, NULL);

	e_dbus_source_writable_call_write_sync (
		dbus_interface, data, cancellable, &local_error);

	g_free (data);

	g_object_unref (dbus_interface);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for source_write() */
static void
source_write_thread (GSimpleAsyncResult *simple,
                     GObject *object,
                     GCancellable *cancellable)
{
	GError *local_error = NULL;

	e_source_write_sync (E_SOURCE (object), cancellable, &local_error);

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

static void
source_write (ESource *source,
              GCancellable *cancellable,
              GAsyncReadyCallback callback,
              gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = g_simple_async_result_new (
		G_OBJECT (source), callback, user_data, source_write);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_run_in_thread (
		simple, source_write_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

static gboolean
source_write_finish (ESource *source,
                     GAsyncResult *result,
                     GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (source), source_write), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static gboolean
source_remote_create_sync (ESource *source,
                           ESource *scratch_source,
                           GCancellable *cancellable,
                           GError **error)
{
	EDBusSourceRemoteCreatable *dbus_interface = NULL;
	GDBusObject *dbus_object;
	gchar *uid, *data;
	GError *local_error = NULL;

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		dbus_interface =
			e_dbus_object_get_source_remote_creatable (
			E_DBUS_OBJECT (dbus_object));
		g_object_unref (dbus_object);
	}

	if (dbus_interface == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_NOT_SUPPORTED,
			_("Data source “%s” does not "
			"support creating remote resources"),
			e_source_get_display_name (source));
		return FALSE;
	}

	uid = e_source_dup_uid (scratch_source);
	data = e_source_to_string (scratch_source, NULL);

	e_dbus_source_remote_creatable_call_create_sync (
		dbus_interface, uid, data, cancellable, &local_error);

	g_free (data);
	g_free (uid);

	g_object_unref (dbus_interface);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for source_remote_create() */
static void
source_remote_create_thread (GSimpleAsyncResult *simple,
                             GObject *object,
                             GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	e_source_remote_create_sync (
		E_SOURCE (object),
		async_context->scratch_source,
		cancellable, &local_error);

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

static void
source_remote_create (ESource *source,
                      ESource *scratch_source,
                      GCancellable *cancellable,
                      GAsyncReadyCallback callback,
                      gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	async_context = g_slice_new0 (AsyncContext);
	async_context->scratch_source = g_object_ref (scratch_source);

	simple = g_simple_async_result_new (
		G_OBJECT (source), callback,
		user_data, source_remote_create);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, source_remote_create_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

static gboolean
source_remote_create_finish (ESource *source,
                             GAsyncResult *result,
                             GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (source), source_remote_create), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static gboolean
source_remote_delete_sync (ESource *source,
                           GCancellable *cancellable,
                           GError **error)
{
	EDBusSourceRemoteDeletable *dbus_interface = NULL;
	GDBusObject *dbus_object;
	GError *local_error = NULL;

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		dbus_interface =
			e_dbus_object_get_source_remote_deletable (
			E_DBUS_OBJECT (dbus_object));
		g_object_unref (dbus_object);
	}

	if (dbus_interface == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_NOT_SUPPORTED,
			_("Data source “%s” does not "
			"support deleting remote resources"),
			e_source_get_display_name (source));
		return FALSE;
	}

	e_dbus_source_remote_deletable_call_delete_sync (
		dbus_interface, cancellable, &local_error);

	g_object_unref (dbus_interface);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for source_remote_delete() */
static void
source_remote_delete_thread (GSimpleAsyncResult *simple,
                             GObject *object,
                             GCancellable *cancellable)
{
	GError *local_error = NULL;

	e_source_remote_delete_sync (
		E_SOURCE (object), cancellable, &local_error);

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

static void
source_remote_delete (ESource *source,
                      GCancellable *cancellable,
                      GAsyncReadyCallback callback,
                      gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = g_simple_async_result_new (
		G_OBJECT (source), callback,
		user_data, source_remote_delete);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_run_in_thread (
		simple, source_remote_delete_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

static gboolean
source_remote_delete_finish (ESource *source,
                             GAsyncResult *result,
                             GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (source), source_remote_delete), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static gboolean
source_get_oauth2_access_token_sync (ESource *source,
                                     GCancellable *cancellable,
                                     gchar **out_access_token,
                                     gint *out_expires_in,
                                     GError **error)
{
	EDBusSourceOAuth2Support *dbus_interface = NULL;
	GDBusObject *dbus_object;
	GError *local_error = NULL;

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		dbus_interface =
			e_dbus_object_get_source_oauth2_support (
			E_DBUS_OBJECT (dbus_object));
		g_object_unref (dbus_object);
	}

	if (dbus_interface == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_NOT_SUPPORTED,
			_("Data source “%s” does not "
			"support OAuth 2.0 authentication"),
			e_source_get_display_name (source));
		return FALSE;
	}

	e_dbus_source_oauth2_support_call_get_access_token_sync (
		dbus_interface, out_access_token,
		out_expires_in, cancellable, &local_error);

	g_object_unref (dbus_interface);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for source_get_oauth2_access_token() */
static void
source_get_oauth2_access_token_thread (GSimpleAsyncResult *simple,
                                       GObject *object,
                                       GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	e_source_get_oauth2_access_token_sync (
		E_SOURCE (object), cancellable,
		&async_context->access_token,
		&async_context->expires_in,
		&local_error);

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

static void
source_get_oauth2_access_token (ESource *source,
                                GCancellable *cancellable,
                                GAsyncReadyCallback callback,
                                gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	async_context = g_slice_new0 (AsyncContext);

	simple = g_simple_async_result_new (
		G_OBJECT (source), callback, user_data,
		source_get_oauth2_access_token);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, source_get_oauth2_access_token_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

static gboolean
source_get_oauth2_access_token_finish (ESource *source,
                                       GAsyncResult *result,
                                       gchar **out_access_token,
                                       gint *out_expires_in,
                                       GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (source),
		source_get_oauth2_access_token), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->access_token != NULL, FALSE);

	if (out_access_token != NULL) {
		*out_access_token = async_context->access_token;
		async_context->access_token = NULL;
	}

	if (out_expires_in != NULL)
		*out_expires_in = async_context->expires_in;

	return TRUE;
}


static gboolean
source_invoke_credentials_required_impl (ESource *source,
					 gpointer dbus_source, /* EDBusSource * */
					 const gchar *arg_reason,
					 const gchar *arg_certificate_pem,
					 const gchar *arg_certificate_errors,
					 const gchar *arg_dbus_error_name,
					 const gchar *arg_dbus_error_message,
					 GCancellable *cancellable,
					 GError **error)
{
	g_return_val_if_fail (E_DBUS_IS_SOURCE (dbus_source), FALSE);

	return e_dbus_source_call_invoke_credentials_required_sync (dbus_source,
		arg_reason ? arg_reason : "",
		arg_certificate_pem ? arg_certificate_pem : "",
		arg_certificate_errors ? arg_certificate_errors : "",
		arg_dbus_error_name ? arg_dbus_error_name : "",
		arg_dbus_error_message ? arg_dbus_error_message : "",
		cancellable, error);
}

static gboolean
source_invoke_authenticate_impl (ESource *source,
				 gpointer dbus_source, /* EDBusSource * */
				 const gchar * const *arg_credentials,
				 GCancellable *cancellable,
				 GError **error)
{
	g_return_val_if_fail (E_DBUS_IS_SOURCE (dbus_source), FALSE);

	return e_dbus_source_call_invoke_authenticate_sync (dbus_source, arg_credentials, cancellable, error);
}

static gboolean
source_unset_last_credentials_required_arguments_impl (ESource *source,
						       GCancellable *cancellable,
						       GError **error)
{
	GDBusObject *dbus_object;
	EDBusSource *dbus_source = NULL;
	gboolean success;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		dbus_source = e_dbus_object_get_source (E_DBUS_OBJECT (dbus_object));
		g_object_unref (dbus_object);
	}

	if (!dbus_source)
		return FALSE;

	success = e_dbus_source_call_unset_last_credentials_required_arguments_sync (dbus_source, cancellable, &local_error);

	g_object_unref (dbus_source);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return success;
}

static gboolean
source_initable_init (GInitable *initable,
                      GCancellable *cancellable,
                      GError **error)
{
	ESource *source;
	gboolean success = TRUE;

	source = E_SOURCE (initable);

	/* The D-Bus object has the unique identifier (UID). */
	if (source->priv->dbus_object != NULL) {
		EDBusObject *dbus_object;
		EDBusSource *dbus_source;

		dbus_object = E_DBUS_OBJECT (source->priv->dbus_object);

		/* An EDBusObject lacking an EDBusSource
		 * interface indicates a programmer error. */
		dbus_source = e_dbus_object_get_source (dbus_object);
		g_return_val_if_fail (E_DBUS_IS_SOURCE (dbus_source), FALSE);

		/* The UID never changes, so we can cache a copy.
		 *
		 * XXX Note, EServerSideSource may have already set this
		 *     by way of the "uid" construct-only property, hence
		 *     the g_free() call.  Not a problem, we'll just free
		 *     our UID string and set it to the same value again. */
		g_free (source->priv->uid);
		source->priv->uid = e_dbus_source_dup_uid (dbus_source);

		source_update_connection_status_internal (source, dbus_source);

		g_signal_connect (
			dbus_source, "notify::data",
			G_CALLBACK (source_notify_dbus_data_cb), source);
		g_signal_connect (
			dbus_source, "notify::connection-status",
			G_CALLBACK (source_notify_dbus_connection_status_cb), source);
		g_signal_connect (
			dbus_source, "credentials-required",
			G_CALLBACK (source_dbus_credentials_required_cb), source);
		g_signal_connect (
			dbus_source, "authenticate",
			G_CALLBACK (source_dbus_authenticate_cb), source);

		success = source_parse_dbus_data (source, error);

		g_object_unref (dbus_source);

	/* No D-Bus object implies we're configuring a new source,
	 * so generate a new unique identifier (UID) unless one was
	 * explicitly provided through e_source_new_with_uid(). */
	} else if (source->priv->uid == NULL) {
		source->priv->uid = e_util_generate_uid ();
	}

	source->priv->initialized = TRUE;

	return success;
}

static gboolean
source_proxy_resolver_is_supported (GProxyResolver *resolver)
{
	return e_source_has_extension (
		E_SOURCE (resolver), E_SOURCE_EXTENSION_PROXY);
}

static gchar **
source_proxy_resolver_lookup (GProxyResolver *resolver,
                              const gchar *uri,
                              GCancellable *cancellable,
                              GError **error)
{
	return e_source_proxy_lookup_sync (
		E_SOURCE (resolver), uri, cancellable, error);
}

/* Helper for source_proxy_resolver_lookup_async() */
static void
source_proxy_resolver_lookup_ready_cb (GObject *object,
                                       GAsyncResult *result,
                                       gpointer user_data)
{
	GSimpleAsyncResult *simple;
	gchar **proxies;
	GError *local_error = NULL;

	simple = G_SIMPLE_ASYNC_RESULT (user_data);

	proxies = e_source_proxy_lookup_finish (
		E_SOURCE (object), result, &local_error);

	/* Sanity check. */
	g_return_if_fail (
		((proxies != NULL) && (local_error == NULL)) ||
		((proxies == NULL) && (local_error != NULL)));

	if (proxies != NULL) {
		g_simple_async_result_set_op_res_gpointer (
			simple, proxies, (GDestroyNotify) g_strfreev);
	} else {
		g_simple_async_result_take_error (simple, local_error);
	}

	g_simple_async_result_complete (simple);

	g_object_unref (simple);
}

static void
source_proxy_resolver_lookup_async (GProxyResolver *resolver,
                                    const gchar *uri,
                                    GCancellable *cancellable,
                                    GAsyncReadyCallback callback,
                                    gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = g_simple_async_result_new (
		G_OBJECT (resolver), callback, user_data,
		source_proxy_resolver_lookup_async);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	e_source_proxy_lookup (
		E_SOURCE (resolver), uri, cancellable,
		source_proxy_resolver_lookup_ready_cb,
		g_object_ref (simple));

	g_object_unref (simple);
}

static gchar **
source_proxy_resolver_lookup_finish (GProxyResolver *resolver,
                                     GAsyncResult *result,
                                     GError **error)
{
	GSimpleAsyncResult *simple;
	gchar **proxies;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (resolver),
		source_proxy_resolver_lookup_async), NULL);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	if (g_simple_async_result_propagate_error (simple, error))
		return NULL;

	proxies = g_simple_async_result_get_op_res_gpointer (simple);

	return g_strdupv (proxies);
}

static void
e_source_class_init (ESourceClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ESourcePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_set_property;
	object_class->get_property = source_get_property;
	object_class->dispose = source_dispose;
	object_class->finalize = source_finalize;
	object_class->notify = source_notify;

	class->remove_sync = source_remove_sync;
	class->remove = source_remove;
	class->remove_finish = source_remove_finish;
	class->write_sync = source_write_sync;
	class->write = source_write;
	class->write_finish = source_write_finish;
	class->remote_create_sync = source_remote_create_sync;
	class->remote_create = source_remote_create;
	class->remote_create_finish = source_remote_create_finish;
	class->remote_delete_sync = source_remote_delete_sync;
	class->remote_delete = source_remote_delete;
	class->remote_delete_finish = source_remote_delete_finish;
	class->get_oauth2_access_token_sync = source_get_oauth2_access_token_sync;
	class->get_oauth2_access_token = source_get_oauth2_access_token;
	class->get_oauth2_access_token_finish = source_get_oauth2_access_token_finish;
	class->invoke_credentials_required_impl = source_invoke_credentials_required_impl;
	class->invoke_authenticate_impl = source_invoke_authenticate_impl;
	class->unset_last_credentials_required_arguments_impl = source_unset_last_credentials_required_arguments_impl;

	g_object_class_install_property (
		object_class,
		PROP_DBUS_OBJECT,
		g_param_spec_object (
			"dbus-object",
			"D-Bus Object",
			"The D-Bus object for the data source",
			E_DBUS_TYPE_OBJECT,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_DISPLAY_NAME,
		g_param_spec_string (
			"display-name",
			"Display Name",
			"The human-readable name of the data source",
			_("Unnamed"),
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_ENABLED,
		g_param_spec_boolean (
			"enabled",
			"Enabled",
			"Whether the data source is enabled",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_MAIN_CONTEXT,
		g_param_spec_boxed (
			"main-context",
			"Main Context",
			"The main loop context on "
			"which to attach event sources",
			G_TYPE_MAIN_CONTEXT,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_PARENT,
		g_param_spec_string (
			"parent",
			"Parent",
			"The unique identity of the parent data source",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_REMOTE_CREATABLE,
		g_param_spec_boolean (
			"remote-creatable",
			"Remote Creatable",
			"Whether the data source "
			"can create remote resources",
			FALSE,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_REMOTE_DELETABLE,
		g_param_spec_boolean (
			"remote-deletable",
			"Remote Deletable",
			"Whether the data source "
			"can delete remote resources",
			FALSE,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_REMOVABLE,
		g_param_spec_boolean (
			"removable",
			"Removable",
			"Whether the data source is removable",
			FALSE,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_UID,
		g_param_spec_string (
			"uid",
			"UID",
			"The unique identity of the data source",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_WRITABLE,
		g_param_spec_boolean (
			"writable",
			"Writable",
			"Whether the data source is writable",
			FALSE,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_CONNECTION_STATUS,
		g_param_spec_enum (
			"connection-status",
			"Connection Status",
			"Connection status of the source",
			E_TYPE_SOURCE_CONNECTION_STATUS,
			E_SOURCE_CONNECTION_STATUS_DISCONNECTED,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ESource::changed:
	 * @source: the #ESource that received the signal
	 *
	 * The ::changed signal is emitted when a property in @source or
	 * one of its extension objects changes.  A common use for this
	 * signal is to notify a #GtkTreeModel containing data collected
	 * from #ESource<!-- -->s that it needs to update a row.
	 **/
	signals[CHANGED] = g_signal_new (
		"changed",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_LAST | G_SIGNAL_NO_RECURSE,
		G_STRUCT_OFFSET (ESourceClass, changed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);

	/**
	 * ESource::credentials-required:
	 * @source: the #ESource that received the signal
	 * @reason: an #ESourceCredentialsReason indicating why the credentials are requested
	 * @certificate_pem: PEM-encoded secure connection certificate for failed SSL/TLS checks
	 * @certificate_errors: what failed with the SSL/TLS certificate
	 * @error: a text description of the error, if any
	 *
	 * The ::credentials-required signal is emitted when the @source
	 * requires credentials to connect to (possibly remote)
	 * data store. The credentials can be passed to the backend using
	 * e_source_invoke_authenticate() function.
	 **/
	signals[CREDENTIALS_REQUIRED] = g_signal_new (
		"credentials-required",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_LAST | G_SIGNAL_NO_RECURSE,
		G_STRUCT_OFFSET (ESourceClass, credentials_required),
		NULL, NULL, NULL,
		G_TYPE_NONE, 4,
		E_TYPE_SOURCE_CREDENTIALS_REASON,
		G_TYPE_STRING,
		G_TYPE_TLS_CERTIFICATE_FLAGS,
		G_TYPE_ERROR);

	/**
	 * ESource::authenticate
	 * @source: the #ESource that received the signal
	 * @credentials: an #ENamedParameters with provided credentials
	 *
	 * Let's the backend know provided credentials to use to login
	 * to (possibly remote) data store.
	 **/
	signals[AUTHENTICATE] = g_signal_new (
		"authenticate",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_LAST | G_SIGNAL_NO_RECURSE,
		G_STRUCT_OFFSET (ESourceClass, authenticate),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1, E_TYPE_NAMED_PARAMETERS);

	/* Register built-in ESourceExtension types. */
	g_type_ensure (E_TYPE_SOURCE_ADDRESS_BOOK);
	g_type_ensure (E_TYPE_SOURCE_ALARMS);
	g_type_ensure (E_TYPE_SOURCE_AUTHENTICATION);
	g_type_ensure (E_TYPE_SOURCE_AUTOCOMPLETE);
	g_type_ensure (E_TYPE_SOURCE_AUTOCONFIG);
	g_type_ensure (E_TYPE_SOURCE_CALENDAR);
	g_type_ensure (E_TYPE_SOURCE_COLLECTION);
	g_type_ensure (E_TYPE_SOURCE_CONTACTS);
	g_type_ensure (E_TYPE_SOURCE_GOA);
	g_type_ensure (E_TYPE_SOURCE_LDAP);
	g_type_ensure (E_TYPE_SOURCE_LOCAL);
	g_type_ensure (E_TYPE_SOURCE_MAIL_ACCOUNT);
	g_type_ensure (E_TYPE_SOURCE_MAIL_COMPOSITION);
	g_type_ensure (E_TYPE_SOURCE_MAIL_IDENTITY);
	g_type_ensure (E_TYPE_SOURCE_MAIL_SIGNATURE);
	g_type_ensure (E_TYPE_SOURCE_MAIL_SUBMISSION);
	g_type_ensure (E_TYPE_SOURCE_MAIL_TRANSPORT);
	g_type_ensure (E_TYPE_SOURCE_MDN);
	g_type_ensure (E_TYPE_SOURCE_MEMO_LIST);
	g_type_ensure (E_TYPE_SOURCE_OFFLINE);
	g_type_ensure (E_TYPE_SOURCE_OPENPGP);
	g_type_ensure (E_TYPE_SOURCE_PROXY);
	g_type_ensure (E_TYPE_SOURCE_REFRESH);
	g_type_ensure (E_TYPE_SOURCE_RESOURCE);
	g_type_ensure (E_TYPE_SOURCE_REVISION_GUARDS);
	g_type_ensure (E_TYPE_SOURCE_SECURITY);
	g_type_ensure (E_TYPE_SOURCE_SELECTABLE);
	g_type_ensure (E_TYPE_SOURCE_SMIME);
	g_type_ensure (E_TYPE_SOURCE_TASK_LIST);
	g_type_ensure (E_TYPE_SOURCE_UOA);
	g_type_ensure (E_TYPE_SOURCE_WEATHER);
	g_type_ensure (E_TYPE_SOURCE_WEBDAV);
}

static void
e_source_initable_init (GInitableIface *iface)
{
	iface->init = source_initable_init;
}

static void
e_source_proxy_resolver_init (GProxyResolverInterface *iface)
{
	iface->is_supported = source_proxy_resolver_is_supported;
	iface->lookup = source_proxy_resolver_lookup;
	iface->lookup_async = source_proxy_resolver_lookup_async;
	iface->lookup_finish = source_proxy_resolver_lookup_finish;
}

static void
e_source_init (ESource *source)
{
	GHashTable *extensions;

	/* Don't do this as part of class initialization because it
	 * loads Camel modules and can screw up introspection, which
	 * occurs at compile-time before Camel modules are installed. */
	e_source_camel_register_types ();

	extensions = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_object_unref);

	source->priv = E_SOURCE_GET_PRIVATE (source);
	g_mutex_init (&source->priv->changed_lock);
	g_mutex_init (&source->priv->connection_status_change_lock);
	g_mutex_init (&source->priv->property_lock);
	source->priv->key_file = g_key_file_new ();
	source->priv->extensions = extensions;
	source->priv->connection_status = E_SOURCE_CONNECTION_STATUS_DISCONNECTED;

	g_rec_mutex_init (&source->priv->lock);
}

void
__e_source_private_replace_dbus_object (ESource *source,
                                        GDBusObject *dbus_object)
{
	/* XXX This function is only ever called by ESourceRegistry
	 *     either when the registry service reported an ESource
	 *     removal, or while recovering from a registry service
	 *     restart.  In the first case the GDBusObject is NULL,
	 *     in the second case the GDBusObject is an equivalent
	 *     proxy for the newly-started registry service. */

	g_return_if_fail (E_IS_SOURCE (source));

	if (dbus_object != NULL) {
		g_return_if_fail (E_DBUS_IS_OBJECT (dbus_object));
		dbus_object = g_object_ref (dbus_object);
	}

	g_mutex_lock (&source->priv->property_lock);

	g_clear_object (&source->priv->dbus_object);
	source->priv->dbus_object = dbus_object;

	g_mutex_unlock (&source->priv->property_lock);

	g_object_notify (G_OBJECT (source), "dbus-object");
}

/**
 * e_source_new:
 * @dbus_object: (allow-none): a #GDBusObject or %NULL
 * @main_context: (allow-none): a #GMainContext or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #ESource instance.
 *
 * The #ESource::changed signal will be emitted from @main_context if given,
 * or else from the thread-default #GMainContext at the time this function is
 * called.
 *
 * The only time the function should be called outside of #ESourceRegistry
 * is to create a so-called "scratch" #ESource for editing in a Properties
 * window or an account setup assistant.
 *
 * FIXME: Elaborate on scratch sources.
 *
 * Returns: a new #ESource, or %NULL on error
 *
 * Since: 3.6
 **/
ESource *
e_source_new (GDBusObject *dbus_object,
              GMainContext *main_context,
              GError **error)
{
	if (dbus_object != NULL)
		g_return_val_if_fail (E_DBUS_IS_OBJECT (dbus_object), NULL);

	return g_initable_new (
		E_TYPE_SOURCE, NULL, error,
		"dbus-object", dbus_object,
		"main-context", main_context,
		NULL);
}

/**
 * e_source_new_with_uid:
 * @uid: a new unique identifier string
 * @main_context: (allow-none): a #GMainContext or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new "scratch" #ESource with a predetermined unique identifier.
 *
 * The #ESource::changed signal will be emitted from @main_context if given,
 * or else from the thread-default #GMainContext at the time this function is
 * called.
 *
 * Returns: a new scratch #ESource, or %NULL on error
 *
 * Since: 3.6
 **/
ESource *
e_source_new_with_uid (const gchar *uid,
                       GMainContext *main_context,
                       GError **error)
{
	g_return_val_if_fail (uid != NULL, NULL);

	return g_initable_new (
		E_TYPE_SOURCE, NULL, error,
		"main-context", main_context,
		"uid", uid, NULL);
}

/**
 * e_source_hash:
 * @source: an #ESource
 *
 * Generates a hash value for @source.  This function is intended for
 * easily hashing an #ESource to add to a #GHashTable or similar data
 * structure.
 *
 * Returns: a hash value for @source.
 *
 * Since: 3.6
 **/
guint
e_source_hash (ESource *source)
{
	const gchar *uid;

	g_return_val_if_fail (E_IS_SOURCE (source), 0);

	uid = e_source_get_uid (source);

	return g_str_hash (uid);
}

/**
 * e_source_equal:
 * @source1: the first #ESource
 * @source2: the second #ESource
 *
 * Checks two #ESource instances for equality.  #ESource instances are
 * equal if their unique identifier strings are equal.
 *
 * Returns: %TRUE if @source1 and @source2 are equal
 *
 * Since: 3.6
 **/
gboolean
e_source_equal (ESource *source1,
                ESource *source2)
{
	const gchar *uid1, *uid2;

	g_return_val_if_fail (E_IS_SOURCE (source1), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source2), FALSE);

	if (source1 == source2)
		return TRUE;

	uid1 = e_source_get_uid (source1);
	uid2 = e_source_get_uid (source2);

	return g_str_equal (uid1, uid2);
}

/**
 * e_source_changed:
 * @source: an #ESource
 *
 * Emits the #ESource::changed signal from an idle callback in
 * @source's #ESource:main-context.
 *
 * This function is primarily intended for use by #ESourceExtension
 * when emitting a #GObject::notify signal on one of its properties.
 *
 * Since: 3.6
 **/
void
e_source_changed (ESource *source)
{
	g_return_if_fail (E_IS_SOURCE (source));

	g_mutex_lock (&source->priv->changed_lock);
	if (!source->priv->ignore_changed_signal &&
	    source->priv->initialized &&
	    source->priv->changed == NULL) {
		source->priv->changed = g_idle_source_new ();
		g_source_set_callback (
			source->priv->changed,
			source_idle_changed_cb,
			g_object_ref (source), g_object_unref);
		g_source_attach (
			source->priv->changed,
			source->priv->main_context);
	}
	g_mutex_unlock (&source->priv->changed_lock);
}

/**
 * e_source_get_uid:
 * @source: an #ESource
 *
 * Returns the unique identifier string for @source.
 *
 * Returns: the UID for @source
 *
 * Since: 3.6
 **/
const gchar *
e_source_get_uid (ESource *source)
{
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	return source->priv->uid;
}

/**
 * e_source_dup_uid:
 * @source: an #ESource
 *
 * Thread-safe variation of e_source_get_uid().
 * Use this function when accessing @source from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESource:uid
 *
 * Since: 3.6
 **/
gchar *
e_source_dup_uid (ESource *source)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	/* Perhaps we don't need to lock the mutex since
	 * this is a read-only property but it can't hurt. */

	g_mutex_lock (&source->priv->property_lock);

	protected = e_source_get_uid (source);
	duplicate = g_strdup (protected);

	g_mutex_unlock (&source->priv->property_lock);

	return duplicate;
}

/**
 * e_source_get_parent:
 * @source: an #ESource
 *
 * Returns the unique identifier string of the parent #ESource.
 *
 * Returns: the UID of the parent #ESource
 *
 * Since: 3.6
 **/
const gchar *
e_source_get_parent (ESource *source)
{
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	return source->priv->parent;
}

/**
 * e_source_dup_parent:
 * @source: an #ESource
 *
 * Thread-safe variation of e_source_get_parent().
 * Use this function when accessing @source from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESource:parent
 *
 * Since: 3.6
 **/
gchar *
e_source_dup_parent (ESource *source)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	g_mutex_lock (&source->priv->property_lock);

	protected = e_source_get_parent (source);
	duplicate = g_strdup (protected);

	g_mutex_unlock (&source->priv->property_lock);

	return duplicate;
}

/**
 * e_source_set_parent:
 * @source: an #ESource
 * @parent: (allow-none): the UID of the parent #ESource, or %NULL
 *
 * Identifies the parent of @source by its unique identifier string.
 * This can only be set prior to adding @source to an #ESourceRegistry.
 *
 * The internal copy of #ESource:parent is automatically stripped of leading
 * and trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.6
 **/
void
e_source_set_parent (ESource *source,
                     const gchar *parent)
{
	g_return_if_fail (E_IS_SOURCE (source));

	g_mutex_lock (&source->priv->property_lock);

	if (e_util_strcmp0 (source->priv->parent, parent) == 0) {
		g_mutex_unlock (&source->priv->property_lock);
		return;
	}

	g_free (source->priv->parent);
	source->priv->parent = e_util_strdup_strip (parent);

	g_mutex_unlock (&source->priv->property_lock);

	g_object_notify (G_OBJECT (source), "parent");
}

/**
 * e_source_get_enabled:
 * @source: an #ESource
 *
 * Returns %TRUE if @source is enabled.
 *
 * An application should try to honor this setting if at all possible,
 * even if it does not provide a way to change the setting through its
 * user interface.  Disabled data sources should generally be hidden.
 *
 * <note><para>
 *   This function does not take into account @source's ancestors in the
 *   #ESource hierarchy, each of which have their own enabled state.  If
 *   any of @source's ancestors are disabled, then @source itself should
 *   be treated as disabled.  Use e_source_registry_check_enabled() to
 *   easily check for this.
 * </para></note>
 *
 * Returns: whether @source is enabled
 *
 * Since: 3.6
 **/
gboolean
e_source_get_enabled (ESource *source)
{
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	return source->priv->enabled;
}

/**
 * e_source_set_enabled:
 * @source: an #ESource
 * @enabled: whether to enable @source
 *
 * Enables or disables @source.
 *
 * An application should try to honor this setting if at all possible,
 * even if it does not provide a way to change the setting through its
 * user interface.  Disabled data sources should generally be hidden.
 *
 * Since: 3.6
 **/
void
e_source_set_enabled (ESource *source,
                      gboolean enabled)
{
	g_return_if_fail (E_IS_SOURCE (source));

	if (source->priv->enabled == enabled)
		return;

	source->priv->enabled = enabled;

	g_object_notify (G_OBJECT (source), "enabled");
}

/**
 * e_source_get_writable:
 * @source: an #ESource
 *
 * Returns whether the D-Bus service will accept changes to @source.
 * If @source is not writable, calls to e_source_write() will fail.
 *
 * Returns: whether @source is writable
 *
 * Since: 3.6
 **/
gboolean
e_source_get_writable (ESource *source)
{
	GDBusObject *dbus_object;
	gboolean writable = FALSE;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		EDBusSourceWritable *dbus_interface;

		dbus_interface =
			e_dbus_object_peek_source_writable (
			E_DBUS_OBJECT (dbus_object));
		writable = (dbus_interface != NULL);
		g_object_unref (dbus_object);
	}

	return writable;
}

/**
 * e_source_get_removable:
 * @source: an #ESource
 *
 * Returns whether the D-Bus service will allow @source to be removed.
 * If @source is not writable, calls to e_source_remove() will fail.
 *
 * Returns: whether @source is removable
 *
 * Since: 3.6
 **/
gboolean
e_source_get_removable (ESource *source)
{
	GDBusObject *dbus_object;
	gboolean removable = FALSE;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		EDBusSourceRemovable *dbus_interface;

		dbus_interface =
			e_dbus_object_peek_source_removable (
			E_DBUS_OBJECT (dbus_object));
		removable = (dbus_interface != NULL);
		g_object_unref (dbus_object);
	}

	return removable;
}

/**
 * e_source_get_remote_creatable:
 * @source: an #ESource
 *
 * Returns whether new resources can be created on a remote server by
 * calling e_source_remote_create() on @source.
 *
 * Generally this is only %TRUE if @source has an #ESourceCollection
 * extension, which means there is an #ECollectionBackend in the D-Bus
 * service that can handle create requests.  If @source does not have
 * this capability, calls to e_source_remote_create() will fail.
 *
 * Returns: whether @source can create remote resources
 *
 * Since: 3.6
 **/
gboolean
e_source_get_remote_creatable (ESource *source)
{
	GDBusObject *dbus_object;
	gboolean remote_creatable = FALSE;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		EDBusSourceRemoteCreatable *dbus_interface;

		dbus_interface =
			e_dbus_object_peek_source_remote_creatable (
			E_DBUS_OBJECT (dbus_object));
		remote_creatable = (dbus_interface != NULL);
		g_object_unref (dbus_object);
	}

	return remote_creatable;
}

/**
 * e_source_get_remote_deletable:
 * @source: an #ESource
 *
 * Returns whether the resource represented by @source can be deleted
 * from a remote server by calling e_source_remote_delete().
 *
 * Generally this is only %TRUE if @source is a child of an #ESource
 * which has an #ESourceCollection extension, which means there is an
 * #ECollectionBackend in the D-Bus service that can handle delete
 * requests.  If @source does not have this capability, calls to
 * e_source_remote_delete() will fail.
 *
 * Returns: whether @source can delete remote resources
 *
 * Since: 3.6
 **/
gboolean
e_source_get_remote_deletable (ESource *source)
{
	GDBusObject *dbus_object;
	gboolean remote_deletable = FALSE;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		EDBusSourceRemoteDeletable *dbus_interface;

		dbus_interface =
			e_dbus_object_peek_source_remote_deletable (
			E_DBUS_OBJECT (dbus_object));
		remote_deletable = (dbus_interface != NULL);
		g_object_unref (dbus_object);
	}

	return remote_deletable;
}

/**
 * e_source_get_extension:
 * @source: an #ESource
 * @extension_name: an extension name
 *
 * Returns an instance of some #ESourceExtension subclass which registered
 * itself under @extension_name.  If no such instance exists within @source,
 * one will be created.  It is the caller's responsibility to know which
 * subclass is being returned.
 *
 * If you just want to test for the existence of an extension within @source
 * without creating it, use e_source_has_extension().
 *
 * Extension instances are owned by their #ESource and should not be
 * referenced directly.  Instead, reference the #ESource instance and
 * use this function to fetch the extension instance as needed.
 *
 * Returns: (type ESourceExtension) (transfer none): an instance of some
 * #ESourceExtension subclass
 *
 * Since: 3.6
 **/
gpointer
e_source_get_extension (ESource *source,
                        const gchar *extension_name)
{
	ESourceExtension *extension;
	GHashTable *hash_table;
	GTypeClass *class;

	g_return_val_if_fail (E_IS_SOURCE (source), NULL);
	g_return_val_if_fail (extension_name != NULL, NULL);

	g_rec_mutex_lock (&source->priv->lock);

	/* Check if we already have the extension. */
	extension = g_hash_table_lookup (
		source->priv->extensions, extension_name);
	if (extension != NULL)
		goto exit;

	/* Find all subclasses of ESourceExtensionClass. */
	hash_table = source_find_extension_classes ();
	class = g_hash_table_lookup (hash_table, extension_name);

	/* Create a new instance of the appropriate GType. */
	if (class != NULL) {
		g_mutex_lock (&source->priv->changed_lock);
		source->priv->ignore_changed_signal++;
		g_mutex_unlock (&source->priv->changed_lock);

		extension = g_object_new (
			G_TYPE_FROM_CLASS (class),
			"source", source, NULL);
		source_load_from_key_file (
			G_OBJECT (extension),
			source->priv->key_file,
			extension_name);
		g_hash_table_insert (
			source->priv->extensions,
			g_strdup (extension_name), extension);

		g_mutex_lock (&source->priv->changed_lock);
		source->priv->ignore_changed_signal--;
		g_mutex_unlock (&source->priv->changed_lock);
	} else {
		/* XXX Tie this into a debug setting for ESources. */
#ifdef DEBUG
		g_critical (
			"No registered GType for ESource "
			"extension '%s'", extension_name);
#endif
	}

	g_hash_table_destroy (hash_table);

exit:
	g_rec_mutex_unlock (&source->priv->lock);

	return extension;
}

/**
 * e_source_has_extension:
 * @source: an #ESource
 * @extension_name: an extension name
 *
 * Checks whether @source has an #ESourceExtension with the given name.
 *
 * Returns: %TRUE if @source has such an extension, %FALSE if not
 *
 * Since: 3.6
 **/
gboolean
e_source_has_extension (ESource *source,
                        const gchar *extension_name)
{
	ESourceExtension *extension;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (extension_name != NULL, FALSE);

	g_rec_mutex_lock (&source->priv->lock);

	/* Two cases to check for, either one is good enough:
	 * 1) Our internal GKeyFile has a group named 'extension_name'.
	 * 2) Our 'extensions' table has an entry for 'extension_name'.
	 *
	 * We have to check both data structures in case a new extension
	 * not present in the GKeyFile was instantiated, but we have not
	 * yet updated our internal GKeyFile.  A common occurrence when
	 * editing a brand new data source.
	 *
	 * When checking the GKeyFile we want to actually fetch the
	 * extension with e_source_get_extension() to make sure it's
	 * a registered extension name and not just an arbitrary key
	 * file group name. */

	if (g_key_file_has_group (source->priv->key_file, extension_name)) {
		extension = e_source_get_extension (source, extension_name);
	} else {
		GHashTable *hash_table = source->priv->extensions;
		extension = g_hash_table_lookup (hash_table, extension_name);
	}

	g_rec_mutex_unlock (&source->priv->lock);

	return (extension != NULL);
}

/**
 * e_source_ref_dbus_object:
 * @source: an #ESource
 *
 * Returns the #GDBusObject that was passed to e_source_new().
 *
 * The returned #GDBusObject is referenced for thread-safety and must be
 * unreferenced with g_object_unref() when finished with it.
 *
 * Returns: (transfer full): the #GDBusObject for @source, or %NULL
 *
 * Since: 3.6
 **/
GDBusObject *
e_source_ref_dbus_object (ESource *source)
{
	GDBusObject *dbus_object = NULL;

	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	g_mutex_lock (&source->priv->property_lock);

	if (source->priv->dbus_object != NULL)
		dbus_object = g_object_ref (source->priv->dbus_object);

	g_mutex_unlock (&source->priv->property_lock);

	return dbus_object;
}

/**
 * e_source_ref_main_context:
 * @source: an #ESource
 *
 * Returns the #GMainContext on which event sources for @source are to
 * be attached.
 *
 * The returned #GMainContext is referenced for thread-safety and must be
 * unreferenced with g_main_context_unref() when finished with it.
 *
 * Returns: (transfer full): a #GMainContext
 *
 * Since: 3.6
 **/
GMainContext *
e_source_ref_main_context (ESource *source)
{
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	return g_main_context_ref (source->priv->main_context);
}

/**
 * e_source_get_display_name:
 * @source: an #ESource
 *
 * Returns the display name for @source.  Use the display name to
 * represent the #ESource in a user interface.
 *
 * Returns: the display name for @source
 *
 * Since: 3.6
 **/
const gchar *
e_source_get_display_name (ESource *source)
{
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	return source->priv->display_name;
}

/**
 * e_source_dup_display_name:
 * @source: an #ESource
 *
 * Thread-safe variation of e_source_get_display_name().
 * Use this function when accessing @source from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESource:display-name
 *
 * Since: 3.6
 **/
gchar *
e_source_dup_display_name (ESource *source)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	g_mutex_lock (&source->priv->property_lock);

	protected = e_source_get_display_name (source);
	duplicate = g_strdup (protected);

	g_mutex_unlock (&source->priv->property_lock);

	return duplicate;
}

/**
 * e_source_set_display_name:
 * @source: an #ESource
 * @display_name: a display name
 *
 * Sets the display name for @source.  The @display_name argument must be a
 * valid UTF-8 string.  Use the display name to represent the #ESource in a
 * user interface.
 *
 * The internal copy of @display_name is automatically stripped of leading
 * and trailing whitespace.
 *
 * Since: 3.6
 **/
void
e_source_set_display_name (ESource *source,
                           const gchar *display_name)
{
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (display_name != NULL);
	g_return_if_fail (g_utf8_validate (display_name, -1, NULL));

	g_mutex_lock (&source->priv->property_lock);

	if (g_strcmp0 (source->priv->display_name, display_name) == 0) {
		g_mutex_unlock (&source->priv->property_lock);
		return;
	}

	g_free (source->priv->display_name);
	source->priv->display_name = g_strdup (display_name);

	/* Strip leading and trailing whitespace. */
	g_strstrip (source->priv->display_name);

	/* This is used in e_source_compare_by_display_name(). */
	g_free (source->priv->collate_key);
	source->priv->collate_key = g_utf8_collate_key (display_name, -1);

	g_mutex_unlock (&source->priv->property_lock);

	g_object_notify (G_OBJECT (source), "display-name");
}

/**
 * e_source_dup_secret_label:
 * @source: an #ESource
 *
 * Creates a label string based on @source's #ESource:display-name for use
 * with #SecretItem.
 *
 * Returns: a newly-allocated secret label
 *
 * Since: 3.12
 **/
gchar *
e_source_dup_secret_label (ESource *source)
{
	gchar *display_name;
	gchar *backend_name = NULL;
	const gchar *type = NULL;
	const gchar *parent;
	GString *secret_label;

	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	display_name = e_source_dup_display_name (source);

	if (display_name == NULL || *display_name == '\0') {
		g_free (display_name);
		display_name = e_source_dup_uid (source);
	}

	#define update_backend_name(ext) G_STMT_START { \
			ESourceBackend *backend_extension; \
			backend_extension = e_source_get_extension (source, ext); \
			g_free (backend_name); \
			backend_name = e_source_backend_dup_backend_name (backend_extension); \
		} G_STMT_END

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_ADDRESS_BOOK)) {
		type = "Addressbook";
		update_backend_name (E_SOURCE_EXTENSION_ADDRESS_BOOK);
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_CALENDAR)) {
		if (!type) {
			type = "Calendar";
			update_backend_name (E_SOURCE_EXTENSION_CALENDAR);
		} else
			type = "";
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_MAIL_ACCOUNT)) {
		if (!type) {
			type = "Mail Account";
			update_backend_name (E_SOURCE_EXTENSION_MAIL_ACCOUNT);
		} else
			type = "";
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_MAIL_TRANSPORT)) {
		if (!type) {
			type = "Mail Transport";
			update_backend_name (E_SOURCE_EXTENSION_MAIL_TRANSPORT);
		} else
			type = "";
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_MEMO_LIST)) {
		if (!type) {
			type = "Memo List";
			update_backend_name (E_SOURCE_EXTENSION_MEMO_LIST);
		} else
			type = "";
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_TASK_LIST)) {
		if (!type) {
			type = "Task List";
			update_backend_name (E_SOURCE_EXTENSION_TASK_LIST);
		} else
			type = "";
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_COLLECTION)) {
		if (!type) {
			type = "Collection";
			update_backend_name (E_SOURCE_EXTENSION_COLLECTION);
		} else
			type = "";
	}

	if (!type || !*type) {
		g_free (backend_name);
		backend_name = NULL;
		type = NULL;
	}

	if (backend_name && !*backend_name) {
		g_free (backend_name);
		backend_name = NULL;
	}

	secret_label = g_string_new (NULL);

	if (type && backend_name)
		g_string_append_printf (secret_label, "Evolution Data Source \"%s\" (%s - %s) ", display_name, type, backend_name);
	else if (type)
		g_string_append_printf (secret_label, "Evolution Data Source \"%s\" (%s)", display_name, type);
	else
		g_string_append_printf (secret_label, "Evolution Data Source \"%s\"", display_name);

	g_free (backend_name);
	g_free (display_name);

	parent = e_source_get_parent (source);
	if (parent && *parent)
		g_string_append_printf (secret_label, " of %s", parent);

	return g_string_free (secret_label, FALSE);
}

/**
 * e_source_compare_by_display_name:
 * @source1: the first #ESource
 * @source2: the second #ESource
 *
 * Compares two #ESource instances by their display names.  Useful for
 * ordering sources in a user interface.
 *
 * Returns: a negative value if @source1 compares before @source2, zero if
 *          they compare equal, or a positive value if @source1 compares
 *          after @source2
 *
 * Since: 3.6
 **/
gint
e_source_compare_by_display_name (ESource *source1,
                                  ESource *source2)
{
	gint res;

	res = g_strcmp0 (
		source1->priv->collate_key,
		source2->priv->collate_key);

	if (res == 0)
		res = g_strcmp0 (source1->priv->uid, source2->priv->uid);

	return res;
}

/**
 * e_source_to_string:
 * @source: an #ESource
 * @length: (allow-none): return location for the length of the returned
 *          string, or %NULL
 *
 * Outputs the current contents of @source as a key file string.
 * Free the returned string with g_free().
 *
 * Returns: a newly-allocated string
 *
 * Since: 3.6
 **/
gchar *
e_source_to_string (ESource *source,
                    gsize *length)
{
	GHashTableIter iter;
	GKeyFile *key_file;
	gpointer group_name;
	gpointer extension;
	gchar *data;

	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	g_rec_mutex_lock (&source->priv->lock);

	key_file = source->priv->key_file;

	source_save_to_key_file (
		G_OBJECT (source), key_file, PRIMARY_GROUP_NAME);

	g_hash_table_iter_init (&iter, source->priv->extensions);
	while (g_hash_table_iter_next (&iter, &group_name, &extension))
		source_save_to_key_file (extension, key_file, group_name);

	data = g_key_file_to_data (key_file, length, NULL);

	g_rec_mutex_unlock (&source->priv->lock);

	return data;
}

/**
 * e_source_parameter_to_key:
 * @param_name: a #GParamSpec name
 *
 * Converts a #GParamSpec name (e.g. "foo-bar" or "foo_bar")
 * to "CamelCase" for use as a #GKeyFile key (e.g. "FooBar").
 *
 * This function is made public only to aid in account migration.
 * Applications should not need to use this.
 *
 * Since: 3.6
 **/
gchar *
e_source_parameter_to_key (const gchar *param_name)
{
	gboolean uppercase = TRUE;
	gchar *key, *cp;
	gint ii;

	g_return_val_if_fail (param_name != NULL, NULL);

	key = cp = g_malloc0 (strlen (param_name) + 1);

	for (ii = 0; param_name[ii] != '\0'; ii++) {
		if (g_ascii_isalnum (param_name[ii]) && uppercase) {
			*cp++ = g_ascii_toupper (param_name[ii]);
			uppercase = FALSE;
		} else if (param_name[ii] == '-' || param_name[ii] == '_')
			uppercase = TRUE;
		else
			*cp++ = param_name[ii];
	}

	return key;
}

/**
 * e_source_get_connection_status:
 * @source: an #ESource
 *
 * Obtain current connection status of the @source.
 *
 * Returns: Current connection status of the @source.
 *
 * Since: 3.16
 **/
ESourceConnectionStatus
e_source_get_connection_status (ESource *source)
{
	g_return_val_if_fail (E_IS_SOURCE (source), E_SOURCE_CONNECTION_STATUS_DISCONNECTED);

	return source->priv->connection_status;
}

/**
 * e_source_set_connection_status:
 * @source: an #ESource
 * @connection_status: one of the #ESourceConnectionStatus
 *
 * Set's current connection status of the @source.
 *
 * Since: 3.16
 **/
void
e_source_set_connection_status (ESource *source,
				ESourceConnectionStatus connection_status)
{
	GEnumClass *enum_class;
	GEnumValue *enum_value;

	g_return_if_fail (E_IS_SOURCE (source));

	if (source->priv->connection_status == connection_status)
		return;

	source->priv->connection_status = connection_status;

	enum_class = g_type_class_ref (E_TYPE_SOURCE_CONNECTION_STATUS);
	enum_value = g_enum_get_value (enum_class, connection_status);

	if (enum_value) {
		GDBusObject *dbus_object;
		EDBusSource *dbus_source;

		dbus_object = e_source_ref_dbus_object (E_SOURCE (source));
		if (dbus_object) {
			dbus_source = e_dbus_object_get_source (E_DBUS_OBJECT (dbus_object));
			if (dbus_source) {
				e_dbus_source_set_connection_status (dbus_source, enum_value->value_nick);
				g_object_unref (dbus_source);
			}

			g_object_unref (dbus_object);
		}
	} else {
		g_warning ("%s: Unknown connection status: %x", G_STRFUNC, connection_status);
	}

	g_type_class_unref (enum_class);

	g_object_notify (G_OBJECT (source), "connection-status");
}

/**
 * e_source_remove_sync:
 * @source: the #ESource to be removed
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Requests the D-Bus service to delete the key files for @source and all of
 * its descendants and broadcast their removal to all clients.  The @source
 * must be #ESource:removable.
 *
 * If an error occurs, the functon will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.6
 **/
gboolean
e_source_remove_sync (ESource *source,
                      GCancellable *cancellable,
                      GError **error)
{
	ESourceClass *class;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	class = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->remove_sync != NULL, FALSE);

	return class->remove_sync (source, cancellable, error);
}

/**
 * e_source_remove:
 * @source: the #ESource to be removed
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously requests the D-Bus service to delete the key files for
 * @source and all of its descendants and broadcast their removal to all
 * clients.  The @source must be #ESource:removable.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_source_remove_finish() to get the result of the operation.
 *
 * Since: 3.6
 **/
void
e_source_remove (ESource *source,
                 GCancellable *cancellable,
                 GAsyncReadyCallback callback,
                 gpointer user_data)
{
	ESourceClass *class;

	g_return_if_fail (E_IS_SOURCE (source));

	class = E_SOURCE_GET_CLASS (source);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->remove != NULL);

	class->remove (source, cancellable, callback, user_data);
}

/**
 * e_source_remove_finish:
 * @source: the #ESource to be removed
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_remove().  If an
 * error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE of failure
 *
 * Since: 3.6
 **/
gboolean
e_source_remove_finish (ESource *source,
                        GAsyncResult *result,
                        GError **error)
{
	ESourceClass *class;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (G_IS_ASYNC_RESULT (result), FALSE);

	class = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->remove_finish != NULL, FALSE);

	return class->remove_finish (source, result, error);
}

/**
 * e_source_write_sync:
 * @source: a writable #ESource
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Submits the current contents of @source to the D-Bus service to be
 * written to disk and broadcast to other clients.  The @source must
 * be #ESource:writable.
 *
 * If an error occurs, the functon will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.6
 **/
gboolean
e_source_write_sync (ESource *source,
                     GCancellable *cancellable,
                     GError **error)
{
	ESourceClass *class;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	class = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->write_sync != NULL, FALSE);

	return class->write_sync (source, cancellable, error);
}

/**
 * e_source_write:
 * @source: a writable #ESource
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously submits the current contents of @source to the D-Bus
 * service to be written to disk and broadcast to other clients.  The
 * @source must be #ESource:writable.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_source_write_finish() to get the result of the operation.
 *
 * Since: 3.6
 **/
void
e_source_write (ESource *source,
                GCancellable *cancellable,
                GAsyncReadyCallback callback,
                gpointer user_data)
{
	ESourceClass *class;

	g_return_if_fail (E_IS_SOURCE (source));

	class = E_SOURCE_GET_CLASS (source);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->write != NULL);

	class->write (source, cancellable, callback, user_data);
}

/**
 * e_source_write_finish:
 * @source: a writable #ESource
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_write().  If an
 * error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.6
 **/
gboolean
e_source_write_finish (ESource *source,
                       GAsyncResult *result,
                       GError **error)
{
	ESourceClass *class;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (G_IS_ASYNC_RESULT (result), FALSE);

	class = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->write_finish != NULL, FALSE);

	return class->write_finish (source, result, error);
}

/**
 * e_source_remote_create_sync:
 * @source: an #ESource
 * @scratch_source: an #ESource describing the resource to create
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new remote resource by picking out relevant details from
 * @scratch_source.  The @scratch_source must be an #ESource with no
 * #GDBusObject.  The @source must be #ESource:remote-creatable.
 *
 * The details required to create the resource vary by #ECollectionBackend,
 * but in most cases the @scratch_source need only define the resource type
 * (address book, calendar, etc.), a display name for the resource, and
 * possibly a server-side path or ID for the resource.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.6
 **/
gboolean
e_source_remote_create_sync (ESource *source,
                             ESource *scratch_source,
                             GCancellable *cancellable,
                             GError **error)
{
	ESourceClass *class;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (scratch_source), FALSE);

	class = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->remote_create_sync != NULL, FALSE);

	return class->remote_create_sync (
		source, scratch_source, cancellable, error);
}

/**
 * e_source_remote_create:
 * @source: an #ESource
 * @scratch_source: an #ESource describing the resource to create
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously creates a new remote resource by picking out relevant
 * details from @scratch_source.  The @scratch_source must be an #ESource
 * with no #GDBusObject.  The @source must be #ESource:remote-creatable.
 *
 * The details required to create the resource vary by #ECollectionBackend,
 * but in most cases the @scratch_source need only define the resource type
 * (address book, calendar, etc.), a display name for the resource, and
 * possibly a server-side path or ID for the resource.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_source_remote_create_finish() to get the result of the operation.
 *
 * Since: 3.6
 **/
void
e_source_remote_create (ESource *source,
                        ESource *scratch_source,
                        GCancellable *cancellable,
                        GAsyncReadyCallback callback,
                        gpointer user_data)
{
	ESourceClass *class;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (E_IS_SOURCE (scratch_source));

	class = E_SOURCE_GET_CLASS (source);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->remote_create != NULL);

	class->remote_create (
		source, scratch_source,
		cancellable, callback, user_data);
}

/**
 * e_source_remote_create_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_remote_create().  If
 * an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.6
 **/
gboolean
e_source_remote_create_finish (ESource *source,
                               GAsyncResult *result,
                               GError **error)
{
	ESourceClass *class;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	class = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->remote_create_finish != NULL, FALSE);

	return class->remote_create_finish (source, result, error);
}

/**
 * e_source_remote_delete_sync:
 * @source: an #ESource
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Deletes the resource represented by @source from a remote server.
 * The @source must be #ESource:remote-deletable.  This will also delete
 * the key file for @source and broadcast its removal to all clients,
 * similar to e_source_remove_sync().
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.6
 **/
gboolean
e_source_remote_delete_sync (ESource *source,
                             GCancellable *cancellable,
                             GError **error)
{
	ESourceClass *class;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	class = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->remote_delete_sync != NULL, FALSE);

	return class->remote_delete_sync (source, cancellable, error);
}

/**
 * e_source_remote_delete:
 * @source: an #ESource
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously deletes the resource represented by @source from a remote
 * server.  The @source must be #ESource:remote-deletable.  This will also
 * delete the key file for @source and broadcast its removal to all clients,
 * similar to e_source_remove().
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_source_remote_delete_finish() to get the result of the operation.
 *
 * Since: 3.6
 **/
void
e_source_remote_delete (ESource *source,
                        GCancellable *cancellable,
                        GAsyncReadyCallback callback,
                        gpointer user_data)
{
	ESourceClass *class;

	g_return_if_fail (E_IS_SOURCE (source));

	class = E_SOURCE_GET_CLASS (source);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->remote_delete != NULL);

	class->remote_delete (source, cancellable, callback, user_data);
}

/**
 * e_source_remote_delete_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_remote_delete().  If
 * an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.6
 **/
gboolean
e_source_remote_delete_finish (ESource *source,
                               GAsyncResult *result,
                               GError **error)
{
	ESourceClass *class;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	class = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->remote_delete_finish != NULL, FALSE);

	return class->remote_delete_finish (source, result, error);
}

/**
 * e_source_get_oauth2_access_token_sync:
 * @source: an #ESource
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @out_access_token: (allow-none) (out): return location for the access token,
 *                    or %NULL
 * @out_expires_in: (allow-none) (out): return location for the token expiry,
 *                  or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Obtains the OAuth 2.0 access token for @source along with its expiry
 * in seconds from the current time (or 0 if unknown).
 *
 * Free the returned access token with g_free() when finished with it.
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.8
 **/
gboolean
e_source_get_oauth2_access_token_sync (ESource *source,
                                       GCancellable *cancellable,
                                       gchar **out_access_token,
                                       gint *out_expires_in,
                                       GError **error)
{
	ESourceClass *class;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	class = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->get_oauth2_access_token_sync != NULL, FALSE);

	return class->get_oauth2_access_token_sync (
		source, cancellable, out_access_token, out_expires_in, error);
}

/**
 * e_source_get_oauth2_access_token:
 * @source: an #ESource
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously obtains the OAuth 2.0 access token for @source along
 * with its expiry in seconds from the current time (or 0 if unknown).
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_source_get_oauth2_access_token_finish() to get the result of the
 * operation.
 *
 * Since: 3.8
 **/
void
e_source_get_oauth2_access_token (ESource *source,
                                  GCancellable *cancellable,
                                  GAsyncReadyCallback callback,
                                  gpointer user_data)
{
	ESourceClass *class;

	g_return_if_fail (E_IS_SOURCE (source));

	class = E_SOURCE_GET_CLASS (source);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->get_oauth2_access_token != NULL);

	return class->get_oauth2_access_token (
		source, cancellable, callback, user_data);
}

/**
 * e_source_get_oauth2_access_token_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @out_access_token: (allow-none) (out): return location for the access token,
 *                    or %NULL
 * @out_expires_in: (allow-none) (out): return location for the token expiry,
 *                  or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_get_oauth2_access_token().
 *
 * Free the returned access token with g_free() when finished with it.
 * If an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.8
 **/
gboolean
e_source_get_oauth2_access_token_finish (ESource *source,
                                         GAsyncResult *result,
                                         gchar **out_access_token,
                                         gint *out_expires_in,
                                         GError **error)
{
	ESourceClass *class;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (G_IS_ASYNC_RESULT (result), FALSE);

	class = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->get_oauth2_access_token_finish != NULL, FALSE);

	return class->get_oauth2_access_token_finish (
		source, result, out_access_token, out_expires_in, error);
}

/**
 * e_source_store_password_sync:
 * @source: an #ESource
 * @password: the password to store
 * @permanently: store permanently or just for the session
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Stores a password for @source.  This operation does not rely on the
 * registry service and therefore works for any #ESource -- registered
 * or "scratch".
 *
 * If @permanently is %TRUE, the password is stored in the default keyring.
 * Otherwise the password is stored in the memory-only session keyring.  If
 * an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.12
 **/
gboolean
e_source_store_password_sync (ESource *source,
                              const gchar *password,
                              gboolean permanently,
                              GCancellable *cancellable,
                              GError **error)
{
	gboolean success;
	const gchar *uid;
	gchar *label;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (password != NULL, FALSE);

	uid = e_source_get_uid (source);
	label = e_source_dup_secret_label (source);

	success = e_secret_store_store_sync (uid, password, label, permanently, cancellable, error);

	g_free (label);

	return success;
}

/* Helper for e_source_store_password() */
static void
source_store_password_thread (GTask *task,
                              gpointer source_object,
                              gpointer task_data,
                              GCancellable *cancellable)
{
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	success = e_source_store_password_sync (
		E_SOURCE (source_object),
		async_context->password,
		async_context->permanently,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * e_source_store_password:
 * @source: an #ESource
 * @password: the password to store
 * @permanently: store permanently or just for the session
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously stores a password for @source.  This operation does
 * not rely on the registry service and therefore works for any #ESource
 * -- registered or "scratch".
 *
 * If @permanently is %TRUE, the password is stored in the default keyring.
 * Otherwise the password is stored in the memory-only session keyring.  If
 * an error occurs, the function sets @error and returns %FALSE.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_source_store_password_finish() to get the result of the operation.
 *
 * Since: 3.12
 **/
void
e_source_store_password (ESource *source,
                         const gchar *password,
                         gboolean permanently,
                         GCancellable *cancellable,
                         GAsyncReadyCallback callback,
                         gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (password != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->password = g_strdup (password);
	async_context->permanently = permanently;

	task = g_task_new (source, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_source_store_password);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, source_store_password_thread);

	g_object_unref (task);
}

/**
 * e_source_store_password_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_store_password().
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.12
 **/
gboolean
e_source_store_password_finish (ESource *source,
                                GAsyncResult *result,
                                GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, source), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_source_store_password), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * e_source_lookup_password_sync:
 * @source: an #ESource
 * @cancellable: optional #GCancellable object, or %NULL
 * @out_password: (out): return location for the password, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Looks up a password for @source.  Both the default and session keyrings
 * are queried.  This operation does not rely on the registry service and
 * therefore works for any #ESource -- registered or "scratch".
 *
 * Note the boolean return value indicates whether the lookup operation
 * itself completed successfully, not whether a password was found.  If
 * no password was found, the function will set @out_password to %NULL
 * but still return %TRUE.  If an error occurs, the function sets @error
 * and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.12
 **/
gboolean
e_source_lookup_password_sync (ESource *source,
                               GCancellable *cancellable,
                               gchar **out_password,
                               GError **error)
{
	const gchar *uid;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	uid = e_source_get_uid (source);

	return e_secret_store_lookup_sync (uid, out_password, cancellable, error);
}

/* Helper for e_source_lookup_password() */
static void
source_lookup_password_thread (GTask *task,
                               gpointer source_object,
                               gpointer task_data,
                               GCancellable *cancellable)
{
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	success = e_source_lookup_password_sync (
		E_SOURCE (source_object),
		cancellable,
		&async_context->password,
		&local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * e_source_lookup_password:
 * @source: an #ESource
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously looks up a password for @source.  Both the default and
 * session keyrings are queried.  This operation does not rely on the
 * registry service and therefore works for any #ESource -- registered
 * or "scratch".
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_source_lookup_password_finish() to get the result of the operation.
 *
 * Since: 3.12
 **/
void
e_source_lookup_password (ESource *source,
                          GCancellable *cancellable,
                          GAsyncReadyCallback callback,
                          gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_SOURCE (source));

	async_context = g_slice_new0 (AsyncContext);

	task = g_task_new (source, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_source_lookup_password);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, source_lookup_password_thread);

	g_object_unref (task);
}

/**
 * e_source_lookup_password_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @out_password: (out): return location for the password, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_lookup_password().
 *
 * Note the boolean return value indicates whether the lookup operation
 * itself completed successfully, not whether a password was found.  If
 * no password was found, the function will set @out_password to %NULL
 * but still return %TRUE.  If an error occurs, the function sets @error
 * and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.12
 **/
gboolean
e_source_lookup_password_finish (ESource *source,
                                 GAsyncResult *result,
                                 gchar **out_password,
                                 GError **error)
{
	AsyncContext *async_context;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, source), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_source_lookup_password), FALSE);

	async_context = g_task_get_task_data (G_TASK (result));

	if (!g_task_had_error (G_TASK (result))) {
		if (out_password != NULL) {
			*out_password = async_context->password;
			async_context->password = NULL;
		}
	}

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * e_source_delete_password_sync:
 * @source: an #ESource
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Deletes the password for @source from either the default keyring or
 * session keyring.  This operation does not rely on the registry service
 * and therefore works for any #ESource -- registered or "scratch".
 *
 * Note the boolean return value indicates whether the delete operation
 * itself completed successfully, not whether a password was found and
 * deleted.  If no password was found, the function will still return
 * %TRUE.  If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.12
 **/
gboolean
e_source_delete_password_sync (ESource *source,
                               GCancellable *cancellable,
                               GError **error)
{
	const gchar *uid;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	uid = e_source_get_uid (source);

	return e_secret_store_delete_sync (uid, cancellable, error);
}

/* Helper for e_source_delete_password() */
static void
source_delete_password_thread (GTask *task,
                               gpointer source_object,
                               gpointer task_data,
                               GCancellable *cancellable)
{
	gboolean success;
	GError *local_error = NULL;

	success = e_source_delete_password_sync (
		E_SOURCE (source_object),
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * e_source_delete_password:
 * @source: an #ESource
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously deletes the password for @source from either the default
 * keyring or session keyring.  This operation does not rely on the registry
 * service and therefore works for any #ESource -- registered or "scratch".
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_source_delete_password_finish() to get the result of the operation.
 *
 * Since: 3.12
 **/
void
e_source_delete_password (ESource *source,
                          GCancellable *cancellable,
                          GAsyncReadyCallback callback,
                          gpointer user_data)
{
	GTask *task;

	g_return_if_fail (E_IS_SOURCE (source));

	task = g_task_new (source, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_source_delete_password);

	g_task_run_in_thread (task, source_delete_password_thread);

	g_object_unref (task);
}

/**
 * e_source_delete_password_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_delete_password().
 *
 * Note the boolean return value indicates whether the delete operation
 * itself completed successfully, not whether a password was found and
 * deleted.  If no password was found, the function will still return
 * %TRUE.  If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.12
 **/
gboolean
e_source_delete_password_finish (ESource *source,
                                 GAsyncResult *result,
                                 GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, source), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_source_delete_password), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * e_source_invoke_credentials_required_sync:
 * @source: an #ESource
 * @reason: an #ESourceCredentialsReason, why the credentials are required
 * @certificate_pem: PEM-encoded secure connection certificate, or an empty string
 * @certificate_errors: a bit-or of #GTlsCertificateFlags for secure connection certificate
 * @op_error: (allow-none): a #GError with a description of the previous credentials error, or %NULL
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Let's the client-side know that credentials are required. The @reason defines which
 * parameters are used. The client passed the credentials with an e_source_invoke_authenticate()
 * call.
 *
 * The %E_SOURCE_CREDENTIALS_REASON_REQUIRED is used for the first credentials prompt,
 * when the client can return credentials as stored from the previous success login.
 *
 * The %E_SOURCE_CREDENTIALS_REASON_REJECTED is used when the previously used credentials
 * had been rejected by the server. That usually means that the user should be asked
 * to provide/correct the credentials.
 *
 * The %E_SOURCE_CREDENTIALS_REASON_SSL_FAILED is used when a secured connection failed
 * due to some server-side certificate issues.
 *
 * The %E_SOURCE_CREDENTIALS_REASON_ERROR is used when the server returned an error.
 * It is not possible to connect to it at the moment usually.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_invoke_credentials_required_sync (ESource *source,
					   ESourceCredentialsReason reason,
					   const gchar *certificate_pem,
					   GTlsCertificateFlags certificate_errors,
					   const GError *op_error,
					   GCancellable *cancellable,
					   GError **error)
{
	GDBusObject *dbus_object;
	EDBusSource *dbus_source = NULL;
	ESourceClass *klass;
	gchar *arg_reason, *arg_certificate_errors;
	GEnumClass *enum_class;
	GEnumValue *enum_value;
	GFlagsClass *flags_class;
	GFlagsValue *flags_value;
	GString *certificate_errors_str;
	gchar *dbus_error_name = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	klass = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->invoke_credentials_required_impl != NULL, FALSE);

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		dbus_source = e_dbus_object_get_source (E_DBUS_OBJECT (dbus_object));
		g_object_unref (dbus_object);
	}

	if (!dbus_source) {
		g_warn_if_fail (dbus_source != NULL);
		return FALSE;
	}

	enum_class = g_type_class_ref (E_TYPE_SOURCE_CREDENTIALS_REASON);
	enum_value = g_enum_get_value (enum_class, reason);

	g_return_val_if_fail (enum_value != NULL, FALSE);

	arg_reason = g_strdup (enum_value->value_nick);
	g_type_class_unref (enum_class);

	certificate_errors_str = g_string_new ("");

	flags_class = g_type_class_ref (G_TYPE_TLS_CERTIFICATE_FLAGS);
	for (flags_value = g_flags_get_first_value (flags_class, certificate_errors);
	     flags_value;
	     flags_value = g_flags_get_first_value (flags_class, certificate_errors)) {
		if (certificate_errors_str->len)
			g_string_append_c (certificate_errors_str, ':');
		g_string_append (certificate_errors_str, flags_value->value_nick);
		certificate_errors &= ~flags_value->value;
	}
	g_type_class_unref (flags_class);

	arg_certificate_errors = g_string_free (certificate_errors_str, FALSE);

	if (reason == E_SOURCE_CREDENTIALS_REASON_SSL_FAILED)
		e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_SSL_FAILED);
	else if (reason != E_SOURCE_CREDENTIALS_REASON_ERROR)
		e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_AWAITING_CREDENTIALS);

	if (op_error)
		dbus_error_name = g_dbus_error_encode_gerror (op_error);

	klass->invoke_credentials_required_impl (source, dbus_source,
			arg_reason ? arg_reason : "",
			certificate_pem ? certificate_pem : "",
			arg_certificate_errors ? arg_certificate_errors : "",
			dbus_error_name ? dbus_error_name : "",
			op_error ? op_error->message : "",
			cancellable, &local_error);

	g_free (arg_reason);
	g_free (arg_certificate_errors);
	g_free (dbus_error_name);
	g_object_unref (dbus_source);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

typedef struct _InvokeCredentialsRequiredData {
	ESourceCredentialsReason reason;
	gchar *certificate_pem;
	GTlsCertificateFlags certificate_errors;
	GError *op_error;
} InvokeCredentialsRequiredData;

static void
invoke_credentials_required_data_free (gpointer ptr)
{
	InvokeCredentialsRequiredData *data = ptr;

	if (data) {
		g_free (data->certificate_pem);
		g_clear_error (&data->op_error);
		g_free (data);
	}
}

static void
source_invoke_credentials_required_thread (GTask *task,
					   gpointer source_object,
					   gpointer task_data,
					   GCancellable *cancellable)
{
	InvokeCredentialsRequiredData *data = task_data;
	gboolean success;
	GError *local_error = NULL;

	success = e_source_invoke_credentials_required_sync (
		E_SOURCE (source_object), data->reason, data->certificate_pem,
		data->certificate_errors, data->op_error,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * e_source_invoke_credentials_required:
 * @source: an #ESource
 * @reason: an #ESourceCredentialsReason, why the credentials are required
 * @certificate_pem: PEM-encoded secure connection certificate, or an empty string
 * @certificate_errors: a bit-or of #GTlsCertificateFlags for secure connection certificate
 * @op_error: (allow-none): a #GError with a description of the previous credentials error, or %NULL
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously calls the InvokeCredentialsRequired method on the server side,
 * to inform clients that credentials are required.
 *
 * When the operation is finished, @callback will be called. You can then
 * call e_source_invoke_credentials_required_finish() to get the result of the operation.
 *
 * Since: 3.16
 **/
void
e_source_invoke_credentials_required (ESource *source,
				      ESourceCredentialsReason reason,
				      const gchar *certificate_pem,
				      GTlsCertificateFlags certificate_errors,
				      const GError *op_error,
				      GCancellable *cancellable,
				      GAsyncReadyCallback callback,
				      gpointer user_data)
{
	InvokeCredentialsRequiredData *data;
	GTask *task;

	g_return_if_fail (E_IS_SOURCE (source));

	data = g_new0 (InvokeCredentialsRequiredData, 1);
	data->reason = reason;
	data->certificate_pem = g_strdup (certificate_pem);
	data->certificate_errors = certificate_errors;
	data->op_error = op_error ? g_error_copy (op_error) : NULL;

	task = g_task_new (source, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_source_invoke_credentials_required);
	g_task_set_task_data (task, data, invoke_credentials_required_data_free);

	g_task_run_in_thread (task, source_invoke_credentials_required_thread);

	g_object_unref (task);
}

/**
 * e_source_invoke_credentials_required_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_invoke_credentials_required().
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_invoke_credentials_required_finish (ESource *source,
					     GAsyncResult *result,
					     GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, source), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_source_invoke_credentials_required), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * e_source_invoke_authenticate_sync:
 * @source: an #ESource
 * @credentials: (allow-none): an #ENamedParameters structure with credentials to use; can be %NULL
 *    to use those from the last call
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Calls the InvokeAuthenticate method on the server side, thus the backend
 * knows what credentials to use to connect to its (possibly remote) data store.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_invoke_authenticate_sync (ESource *source,
				   const ENamedParameters *credentials,
				   GCancellable *cancellable,
				   GError **error)
{
	GDBusObject *dbus_object;
	EDBusSource *dbus_source = NULL;
	ESourceClass *klass;
	gchar **credentials_strv;
	gboolean success;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	klass = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->invoke_authenticate_impl != NULL, FALSE);

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		dbus_source = e_dbus_object_get_source (E_DBUS_OBJECT (dbus_object));
		g_object_unref (dbus_object);
	}

	if (!dbus_source) {
		g_warn_if_fail (dbus_source != NULL);
		return FALSE;
	}

	if (credentials) {
		if (e_source_has_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND) &&
		    !e_named_parameters_get (credentials, E_SOURCE_CREDENTIAL_SSL_TRUST)) {
			ENamedParameters *clone;
			ESourceWebdav *webdav_extension;

			clone = e_named_parameters_new_clone (credentials);

			webdav_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
			e_named_parameters_set (clone, E_SOURCE_CREDENTIAL_SSL_TRUST,
				e_source_webdav_get_ssl_trust (webdav_extension));

			credentials_strv = e_named_parameters_to_strv (clone);

			e_named_parameters_free (clone);
		} else {
			credentials_strv = e_named_parameters_to_strv (credentials);
		}
	} else {
		ENamedParameters *empty_credentials;

		empty_credentials = e_named_parameters_new ();
		credentials_strv = e_named_parameters_to_strv (empty_credentials);
		e_named_parameters_free (empty_credentials);
	}

	success = klass->invoke_authenticate_impl (source, dbus_source, (const gchar * const *) credentials_strv, cancellable, &local_error);

	g_strfreev (credentials_strv);
	g_object_unref (dbus_source);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return success;
}

static void
source_invoke_authenticate_thread (GTask *task,
				   gpointer source_object,
				   gpointer task_data,
				   GCancellable *cancellable)
{
	gboolean success;
	GError *local_error = NULL;

	success = e_source_invoke_authenticate_sync (
		E_SOURCE (source_object), task_data,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * e_source_invoke_authenticate:
 * @source: an #ESource
 * @credentials: (allow-none): an #ENamedParameters structure with credentials to use; can be %NULL
 *    to use those from the last call
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously calls the InvokeAuthenticate method on the server side,
 * thus the backend knows what credentials to use to connect to its (possibly
 * remote) data store.
 *
 * When the operation is finished, @callback will be called. You can then
 * call e_source_invoke_authenticate_finish() to get the result of the operation.
 *
 * Since: 3.16
 **/
void
e_source_invoke_authenticate (ESource *source,
			      const ENamedParameters *credentials,
			      GCancellable *cancellable,
			      GAsyncReadyCallback callback,
			      gpointer user_data)
{
	ENamedParameters *credentials_copy;
	GTask *task;

	g_return_if_fail (E_IS_SOURCE (source));

	credentials_copy = e_named_parameters_new_clone (credentials);

	task = g_task_new (source, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_source_invoke_authenticate);
	g_task_set_task_data (task, credentials_copy, (GDestroyNotify) e_named_parameters_free);

	g_task_run_in_thread (task, source_invoke_authenticate_thread);

	g_object_unref (task);
}

/**
 * e_source_invoke_authenticate_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_invoke_authenticate().
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_invoke_authenticate_finish (ESource *source,
				     GAsyncResult *result,
				     GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, source), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_source_invoke_authenticate), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * e_source_emit_credentials_required:
 * @source: an #ESource
 * @reason: an #ESourceCredentialsReason, why the credentials are required
 * @certificate_pem: PEM-encoded secure connection certificate, or an empty string
 * @certificate_errors: a bit-or of #GTlsCertificateFlags for secure connection certificate
 * @op_error: (allow-none): a #GError with a description of the previous credentials error, or %NULL
 *
 * Emits localy (in this process only) the ESource::credentials-required
 * signal with given parameters. That's the difference with e_source_invoke_credentials_required(),
 * which calls the signal globally, within each client.
 *
 * Since: 3.16
 **/
void
e_source_emit_credentials_required (ESource *source,
				    ESourceCredentialsReason reason,
				    const gchar *certificate_pem,
				    GTlsCertificateFlags certificate_errors,
				    const GError *op_error)
{
	g_return_if_fail (E_IS_SOURCE (source));

	g_signal_emit (source, signals[CREDENTIALS_REQUIRED], 0, reason, certificate_pem, certificate_errors, op_error);
}

/**
 * e_source_get_last_credentials_required_arguments_sync:
 * @source: an #ESource
 * @out_reason: (out): an #ESourceCredentialsReason, why the credentials are required
 * @out_certificate_pem: (out): PEM-encoded secure connection certificate, or an empty string
 * @out_certificate_errors: (out): a bit-or of #GTlsCertificateFlags for secure connection certificate
 * @out_op_error: (out): a #GError with a description of the previous credentials error
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Retrieves the last used arguments of the 'credentials-required' signal emission.
 * If there was none emitted yet, or a corresponding 'authenitcate' had been emitted
 * already, then the @out_reason is set to #E_SOURCE_CREDENTIALS_REASON_UNKNOWN
 * and the value of other 'out' arguments is set to no values.
 *
 * If an error occurs, the function sets @error and returns %FALSE. The result gchar
 * values should be freed with g_free() when no longer needed.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_get_last_credentials_required_arguments_sync (ESource *source,
						       ESourceCredentialsReason *out_reason,
						       gchar **out_certificate_pem,
						       GTlsCertificateFlags *out_certificate_errors,
						       GError **out_op_error,
						       GCancellable *cancellable,
						       GError **error)
{
	GDBusObject *dbus_object;
	EDBusSource *dbus_source = NULL;
	gboolean success;
	gchar *arg_reason = NULL, *arg_certificate_errors = NULL;
	gchar *arg_dbus_error_name = NULL, *arg_dbus_error_message = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (out_reason != NULL, FALSE);
	g_return_val_if_fail (out_certificate_pem != NULL, FALSE);
	g_return_val_if_fail (out_certificate_errors != NULL, FALSE);
	g_return_val_if_fail (out_op_error != NULL, FALSE);

	*out_reason = E_SOURCE_CREDENTIALS_REASON_UNKNOWN;
	*out_certificate_pem =  NULL;
	*out_certificate_errors = 0;
	*out_op_error = NULL;

	dbus_object = e_source_ref_dbus_object (source);
	if (dbus_object != NULL) {
		dbus_source = e_dbus_object_get_source (E_DBUS_OBJECT (dbus_object));
		g_object_unref (dbus_object);
	}

	if (!dbus_source)
		return FALSE;

	success = e_dbus_source_call_get_last_credentials_required_arguments_sync (dbus_source,
		&arg_reason, out_certificate_pem, &arg_certificate_errors,
		&arg_dbus_error_name, &arg_dbus_error_message, cancellable, &local_error);

	g_object_unref (dbus_source);

	*out_reason = source_credentials_reason_from_text (arg_reason);
	*out_certificate_errors = source_certificate_errors_from_text (arg_certificate_errors);

	if (arg_dbus_error_name && *arg_dbus_error_name && arg_dbus_error_message) {
		*out_op_error = g_dbus_error_new_for_dbus_error (arg_dbus_error_name, arg_dbus_error_message);
		g_dbus_error_strip_remote_error (*out_op_error);
	}

	if (*out_certificate_pem && !**out_certificate_pem) {
		g_free (*out_certificate_pem);
		*out_certificate_pem = NULL;
	}

	g_free (arg_reason);
	g_free (arg_certificate_errors);
	g_free (arg_dbus_error_name);
	g_free (arg_dbus_error_message);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return success;
}

static void
source_get_last_credentials_required_arguments_thread (GTask *task,
						       gpointer source_object,
						       gpointer task_data,
						       GCancellable *cancellable)
{
	InvokeCredentialsRequiredData *data;
	GError *local_error = NULL;

	data = g_new0 (InvokeCredentialsRequiredData, 1);
	data->reason = E_SOURCE_CREDENTIALS_REASON_UNKNOWN;
	data->certificate_pem = NULL;
	data->certificate_errors = 0;
	data->op_error = NULL;

	e_source_get_last_credentials_required_arguments_sync (
		E_SOURCE (source_object), &data->reason, &data->certificate_pem,
		&data->certificate_errors, &data->op_error,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (task, data, invoke_credentials_required_data_free);
	}
}

/**
 * e_source_get_last_credentials_required_arguments:
 * @source: an #ESource
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously calls the GetLastCredentialsRequiredArguments method
 * on the server side, to get the last values used for the 'credentials-required'
 * signal. See e_source_get_last_credentials_required_arguments_sync() for
 * more information.
 *
 * When the operation is finished, @callback will be called. You can then
 * call e_source_get_last_credentials_required_arguments_finish() to get
 * the result of the operation.
 *
 * Since: 3.16
 **/
void
e_source_get_last_credentials_required_arguments (ESource *source,
						  GCancellable *cancellable,
						  GAsyncReadyCallback callback,
						  gpointer user_data)
{
	GTask *task;

	g_return_if_fail (E_IS_SOURCE (source));

	task = g_task_new (source, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_source_get_last_credentials_required_arguments);

	g_task_run_in_thread (task, source_get_last_credentials_required_arguments_thread);

	g_object_unref (task);
}

/**
 * e_source_get_last_credentials_required_arguments_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @out_reason: (out): an #ESourceCredentialsReason, why the credentials are required
 * @out_certificate_pem: (out): PEM-encoded secure connection certificate, or an empty string
 * @out_certificate_errors: (out): a bit-or of #GTlsCertificateFlags for secure connection certificate
 * @out_op_error: (out): a #GError with a description of the previous credentials error
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_get_last_credentials_required_arguments().
 * See e_source_get_last_credentials_required_arguments_sync() for more information
 * about the output arguments.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_get_last_credentials_required_arguments_finish (ESource *source,
							 GAsyncResult *result,
							 ESourceCredentialsReason *out_reason,
							 gchar **out_certificate_pem,
							 GTlsCertificateFlags *out_certificate_errors,
							 GError **out_op_error,
							 GError **error)
{
	InvokeCredentialsRequiredData *data;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, source), FALSE);
	g_return_val_if_fail (out_reason != NULL, FALSE);
	g_return_val_if_fail (out_certificate_pem != NULL, FALSE);
	g_return_val_if_fail (out_certificate_errors != NULL, FALSE);
	g_return_val_if_fail (out_op_error != NULL, FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_source_get_last_credentials_required_arguments), FALSE);

	data = g_task_propagate_pointer (G_TASK (result), error);
	if (!data)
		return FALSE;

	*out_reason = data->reason;
	*out_certificate_pem =  g_strdup (data->certificate_pem);
	*out_certificate_errors = data->certificate_errors;
	*out_op_error = data->op_error ? g_error_copy (data->op_error) : NULL;

	invoke_credentials_required_data_free (data);

	return TRUE;
}

/**
 * e_source_unset_last_credentials_required_arguments_sync:
 * @source: an #ESource
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Unsets the last used arguments of the 'credentials-required' signal emission.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.18
 **/
gboolean
e_source_unset_last_credentials_required_arguments_sync (ESource *source,
							 GCancellable *cancellable,
							 GError **error)
{
	ESourceClass *klass;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	klass = E_SOURCE_GET_CLASS (source);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->unset_last_credentials_required_arguments_impl != NULL, FALSE);

	return klass->unset_last_credentials_required_arguments_impl (source, cancellable, error);
}

static void
source_unset_last_credentials_required_arguments_thread (GTask *task,
							 gpointer source_object,
							 gpointer task_data,
							 GCancellable *cancellable)
{
	GError *local_error = NULL;

	e_source_unset_last_credentials_required_arguments_sync (
		E_SOURCE (source_object), cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, TRUE);
	}
}

/**
 * e_source_unset_last_credentials_required_arguments:
 * @source: an #ESource
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously calls the UnsetLastCredentialsRequiredArguments method
 * on the server side, to unset the last values used for the 'credentials-required'
 * signal.
 *
 * When the operation is finished, @callback will be called. You can then
 * call e_source_unset_last_credentials_required_arguments_finish() to get
 * the result of the operation.
 *
 * Since: 3.18
 **/
void
e_source_unset_last_credentials_required_arguments (ESource *source,
						    GCancellable *cancellable,
						    GAsyncReadyCallback callback,
						    gpointer user_data)
{
	GTask *task;

	g_return_if_fail (E_IS_SOURCE (source));

	task = g_task_new (source, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_source_unset_last_credentials_required_arguments);

	g_task_run_in_thread (task, source_unset_last_credentials_required_arguments_thread);

	g_object_unref (task);
}

/**
 * e_source_unset_last_credentials_required_arguments_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_unset_last_credentials_required_arguments().
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.18
 **/
gboolean
e_source_unset_last_credentials_required_arguments_finish (ESource *source,
							   GAsyncResult *result,
							   GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, source), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_source_unset_last_credentials_required_arguments), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}
