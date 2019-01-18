/*
 * e-server-side-source.c
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
 * SECTION: e-server-side-source
 * @include: libebackend/libebackend.h
 * @short_description: A server-side data source
 *
 * An #EServerSideSource is an #ESource with some additional capabilities
 * exclusive to the registry D-Bus service.
 **/

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <glib/gi18n-lib.h>

/* Private D-Bus classes. */
#include "e-dbus-source.h"

#include "e-server-side-source.h"

#define E_SERVER_SIDE_SOURCE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SERVER_SIDE_SOURCE, EServerSideSourcePrivate))

#define DBUS_OBJECT_PATH	E_SOURCE_REGISTRY_SERVER_OBJECT_PATH "/Source"

#define PRIMARY_GROUP_NAME	"Data Source"

typedef struct _AsyncContext AsyncContext;

struct _EServerSideSourcePrivate {
	gpointer server;  /* weak pointer */
	GWeakRef oauth2_support;

	GNode node;
	GFile *file;

	/* For comparison. */
	gchar *file_contents;

	gchar *write_directory;

	GMutex last_values_lock;
	gchar *last_reason;
	gchar *last_certificate_pem;
	gchar *last_certificate_errors;
	gchar *last_dbus_error_name;
	gchar *last_dbus_error_message;
	ENamedParameters *last_credentials;

	GMutex pending_credentials_lookup_lock;
	GCancellable *pending_credentials_lookup;
};

struct _AsyncContext {
	EDBusSourceRemoteCreatable *remote_creatable;
	EDBusSourceRemoteDeletable *remote_deletable;
	EDBusSourceOAuth2Support *oauth2_support;
	GDBusMethodInvocation *invocation;
};

enum {
	PROP_0,
	PROP_EXPORTED,
	PROP_FILE,
	PROP_OAUTH2_SUPPORT,
	PROP_REMOTE_CREATABLE,
	PROP_REMOTE_DELETABLE,
	PROP_REMOVABLE,
	PROP_SERVER,
	PROP_WRITABLE,
	PROP_WRITE_DIRECTORY
};

static GInitableIface *initable_parent_interface;

/* Forward Declarations */
static void	e_server_side_source_initable_init
						(GInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	EServerSideSource,
	e_server_side_source,
	E_TYPE_SOURCE,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_server_side_source_initable_init))

static void
async_context_free (AsyncContext *async_context)
{
	if (async_context->remote_creatable != NULL)
		g_object_unref (async_context->remote_creatable);

	if (async_context->remote_deletable != NULL)
		g_object_unref (async_context->remote_deletable);

	if (async_context->oauth2_support != NULL)
		g_object_unref (async_context->oauth2_support);

	if (async_context->invocation != NULL)
		g_object_unref (async_context->invocation);

	g_slice_free (AsyncContext, async_context);
}

static gboolean
server_side_source_parse_data (GKeyFile *key_file,
                               const gchar *data,
                               gsize length,
                               GError **error)
{
	gboolean success;

	success = g_key_file_load_from_data (
		key_file, data, length, G_KEY_FILE_NONE, error);

	if (!success)
		return FALSE;

	/* Make sure the key file has a [Data Source] group. */
	if (!g_key_file_has_group (key_file, PRIMARY_GROUP_NAME)) {
		g_set_error (
			error, G_KEY_FILE_ERROR,
			G_KEY_FILE_ERROR_GROUP_NOT_FOUND,
			_("Data source is missing a [%s] group"),
			PRIMARY_GROUP_NAME);
		return FALSE;
	}

	return TRUE;
}

static void
server_side_source_print_diff (ESource *source,
                               const gchar *old_data,
                               const gchar *new_data)
{
	gchar **old_strv = NULL;
	gchar **new_strv = NULL;
	guint old_length = 0;
	guint new_length = 0;
	guint ii;

	if (!e_source_registry_debug_enabled ())
		return;

	e_source_registry_debug_print ("Saving %s\n", e_source_get_uid (source));

	if (old_data != NULL) {
		old_strv = g_strsplit (old_data, "\n", 0);
		old_length = g_strv_length (old_strv);
	}

	if (new_data != NULL) {
		new_strv = g_strsplit (new_data, "\n", 0);
		new_length = g_strv_length (new_strv);
	}

	for (ii = 0; ii < MIN (old_length, new_length); ii++) {
		if (g_strcmp0 (old_strv[ii], new_strv[ii]) != 0) {
			e_source_registry_debug_print (" - : %s\n", old_strv[ii]);
			e_source_registry_debug_print (" + : %s\n", new_strv[ii]);
		} else {
			e_source_registry_debug_print ("   : %s\n", old_strv[ii]);
		}
	}

	for (; ii < old_length; ii++)
		e_source_registry_debug_print (" - : %s\n", old_strv[ii]);

	for (; ii < new_length; ii++)
		e_source_registry_debug_print (" + : %s\n", new_strv[ii]);

	g_strfreev (old_strv);
	g_strfreev (new_strv);
}

static gboolean
server_side_source_traverse_cb (GNode *node,
                                GQueue *queue)
{
	g_queue_push_tail (queue, g_object_ref (node->data));

	return FALSE;
}

static ESourceCredentialsReason
server_side_source_credentials_reason_from_text (const gchar *arg_reason)
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

typedef struct _ReinvokeCredentialsRequiredData {
	EServerSideSource *source;
	gchar *arg_reason;
	gchar *arg_certificate_pem;
	gchar *arg_certificate_errors;
	gchar *arg_dbus_error_name;
	gchar *arg_dbus_error_message;
} ReinvokeCredentialsRequiredData;

static void
reinvoke_credentials_required_data_free (gpointer ptr)
{
	ReinvokeCredentialsRequiredData *data = ptr;

	if (data) {
		g_clear_object (&data->source);
		g_free (data->arg_reason);
		g_free (data->arg_certificate_pem);
		g_free (data->arg_certificate_errors);
		g_free (data->arg_dbus_error_name);
		g_free (data->arg_dbus_error_message);
		g_free (data);
	}
}

static void server_side_source_credentials_lookup_cb (GObject *source_object, GAsyncResult *result, gpointer user_data);

static gboolean
server_side_source_invoke_credentials_required_cb (EDBusSource *dbus_interface,
						   GDBusMethodInvocation *invocation,
						   const gchar *arg_reason,
						   const gchar *arg_certificate_pem,
						   const gchar *arg_certificate_errors,
						   const gchar *arg_dbus_error_name,
						   const gchar *arg_dbus_error_message,
						   EServerSideSource *source)
{
	gboolean skip_emit = FALSE;

	if (invocation)
		e_dbus_source_complete_invoke_credentials_required (dbus_interface, invocation);

	g_mutex_lock (&source->priv->pending_credentials_lookup_lock);
	if (source->priv->pending_credentials_lookup) {
		g_cancellable_cancel (source->priv->pending_credentials_lookup);
		g_clear_object (&source->priv->pending_credentials_lookup);
	}
	g_mutex_unlock (&source->priv->pending_credentials_lookup_lock);

	g_mutex_lock (&source->priv->last_values_lock);

	g_free (source->priv->last_reason);
	g_free (source->priv->last_certificate_pem);
	g_free (source->priv->last_certificate_errors);
	g_free (source->priv->last_dbus_error_name);
	g_free (source->priv->last_dbus_error_message);
	source->priv->last_reason = g_strdup (arg_reason);
	source->priv->last_certificate_pem = g_strdup (arg_certificate_pem);
	source->priv->last_certificate_errors = g_strdup (arg_certificate_errors);
	source->priv->last_dbus_error_name = g_strdup (arg_dbus_error_name);
	source->priv->last_dbus_error_message = g_strdup (arg_dbus_error_message);

	g_mutex_unlock (&source->priv->last_values_lock);

	/* Do not bother clients, when the password is stored. */
	if (server_side_source_credentials_reason_from_text (arg_reason) == E_SOURCE_CREDENTIALS_REASON_REQUIRED) {
		ESourceRegistryServer *server;
		ESourceCredentialsProvider *credentials_provider;

		server = e_server_side_source_get_server (source);
		credentials_provider = server ? e_source_registry_server_ref_credentials_provider (server) : NULL;

		if (credentials_provider) {
			ReinvokeCredentialsRequiredData *data;
			GCancellable *cancellable;

			g_mutex_lock (&source->priv->pending_credentials_lookup_lock);
			if (source->priv->pending_credentials_lookup) {
				g_cancellable_cancel (source->priv->pending_credentials_lookup);
				g_clear_object (&source->priv->pending_credentials_lookup);
			}
			cancellable = g_cancellable_new ();
			source->priv->pending_credentials_lookup = g_object_ref (cancellable);
			g_mutex_unlock (&source->priv->pending_credentials_lookup_lock);

			data = g_new0 (ReinvokeCredentialsRequiredData, 1);
			data->source = g_object_ref (source);
			data->arg_reason = g_strdup (arg_reason);
			data->arg_certificate_pem = g_strdup (arg_certificate_pem);
			data->arg_certificate_errors = g_strdup (arg_certificate_errors);
			data->arg_dbus_error_name = g_strdup (arg_dbus_error_name);
			data->arg_dbus_error_message = g_strdup (arg_dbus_error_message);

			skip_emit = TRUE;

			e_source_credentials_provider_lookup (credentials_provider, E_SOURCE (source),
				cancellable, server_side_source_credentials_lookup_cb, data);

			g_object_unref (cancellable);
		}

		g_clear_object (&credentials_provider);
	}

	if (!skip_emit) {
		e_dbus_source_emit_credentials_required (dbus_interface, arg_reason, arg_certificate_pem, arg_certificate_errors, arg_dbus_error_name, arg_dbus_error_message);
	}

	return TRUE;
}

static gboolean
server_side_source_invoke_authenticate_cb (EDBusSource *dbus_interface,
					   GDBusMethodInvocation *invocation,
					   const gchar * const *arg_credentials,
					   EServerSideSource *source)
{
	gchar **last_credentials_strv = NULL;

	g_return_val_if_fail (E_IS_SERVER_SIDE_SOURCE (source), TRUE);

	g_mutex_lock (&source->priv->pending_credentials_lookup_lock);
	if (source->priv->pending_credentials_lookup) {
		g_cancellable_cancel (source->priv->pending_credentials_lookup);
		g_clear_object (&source->priv->pending_credentials_lookup);
	}
	g_mutex_unlock (&source->priv->pending_credentials_lookup_lock);

	g_mutex_lock (&source->priv->last_values_lock);

	/* Empty credentials are used to use the last credentials instead */
	if (source->priv->last_credentials && arg_credentials && !arg_credentials[0]) {
		last_credentials_strv = e_named_parameters_to_strv (source->priv->last_credentials);
		arg_credentials = (const gchar * const *) last_credentials_strv;
	} else if (arg_credentials && arg_credentials[0]) {
		ENamedParameters *credentials = e_named_parameters_new_strv (arg_credentials);

		/* If only one credential value is passed in, and it's the SSL Trust,
		   and there was any credentials already tried, then merge the previous
		   credentials with the SSL Trust, to inherit the password, if any. */
		if (source->priv->last_credentials &&
		    e_named_parameters_count (credentials) == 1 &&
		    e_named_parameters_exists (credentials, E_SOURCE_CREDENTIAL_SSL_TRUST)) {
			gint ii, count;

			count = e_named_parameters_count (source->priv->last_credentials);
			for (ii = 0; ii < count; ii++) {
				gchar *name;

				name = e_named_parameters_get_name (source->priv->last_credentials, ii);
				if (!name)
					continue;

				if (*name && !e_named_parameters_exists (credentials, name)) {
					e_named_parameters_set (credentials, name,
						e_named_parameters_get (source->priv->last_credentials, name));
				}

				g_free (name);
			}

			last_credentials_strv = e_named_parameters_to_strv (credentials);
			arg_credentials = (const gchar * const *) last_credentials_strv;
		}

		e_named_parameters_free (source->priv->last_credentials);
		source->priv->last_credentials = credentials;
	}

	g_free (source->priv->last_reason);
	g_free (source->priv->last_certificate_pem);
	g_free (source->priv->last_certificate_errors);
	g_free (source->priv->last_dbus_error_name);
	g_free (source->priv->last_dbus_error_message);
	source->priv->last_reason = NULL;
	source->priv->last_certificate_pem = NULL;
	source->priv->last_certificate_errors = NULL;
	source->priv->last_dbus_error_name = NULL;
	source->priv->last_dbus_error_message = NULL;

	g_mutex_unlock (&source->priv->last_values_lock);

	if (invocation)
		e_dbus_source_complete_invoke_authenticate (dbus_interface, invocation);

	e_dbus_source_emit_authenticate (dbus_interface, arg_credentials);

	g_strfreev (last_credentials_strv);

	return TRUE;
}

static void
server_side_source_credentials_lookup_cb (GObject *source_object,
					  GAsyncResult *result,
					  gpointer user_data)
{
	GDBusObject *dbus_object;
	EDBusSource *dbus_source;
	ReinvokeCredentialsRequiredData *data = user_data;
	ENamedParameters *credentials = NULL;
	gboolean success;
	GError *error = NULL;

	g_return_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (source_object));
	g_return_if_fail (data != NULL);

	success = e_source_credentials_provider_lookup_finish (E_SOURCE_CREDENTIALS_PROVIDER (source_object), result, &credentials, &error);

	dbus_object = e_source_ref_dbus_object (E_SOURCE (data->source));
	if (!dbus_object) {
		e_named_parameters_free (credentials);
		reinvoke_credentials_required_data_free (data);
		return;
	}

	dbus_source = e_dbus_object_get_source (E_DBUS_OBJECT (dbus_object));
	if (!dbus_source) {
		e_named_parameters_free (credentials);
		g_clear_object (&dbus_object);
		reinvoke_credentials_required_data_free (data);
		return;
	}

	if (success && credentials) {
		gchar **arg_credentials;

		arg_credentials = e_named_parameters_to_strv (credentials);

		server_side_source_invoke_authenticate_cb (dbus_source, NULL,
			(const gchar * const *) arg_credentials, data->source);

		g_strfreev (arg_credentials);
	} else if (!g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
		if (e_source_registry_debug_enabled ()) {
			printf ("%s: Failed to lookup password for source %s (%s): %s\n", G_STRFUNC,
				e_source_get_uid (E_SOURCE (data->source)),
				e_source_get_display_name (E_SOURCE (data->source)),
				error ? error->message : "Unknown error");
			fflush (stdout);
		}

		g_prefix_error (&error, "%s", _("Failed to lookup credentials: "));

		if (server_side_source_credentials_reason_from_text (data->arg_reason) == E_SOURCE_CREDENTIALS_REASON_REQUIRED &&
		    error && !e_source_credentials_provider_can_prompt (E_SOURCE_CREDENTIALS_PROVIDER (source_object), E_SOURCE (data->source))) {
			GEnumClass *enum_class;
			GEnumValue *enum_value;
			gchar *dbus_error_name;

			enum_class = g_type_class_ref (E_TYPE_SOURCE_CREDENTIALS_REASON);
			enum_value = g_enum_get_value (enum_class, E_SOURCE_CREDENTIALS_REASON_ERROR);

			g_return_if_fail (enum_value != NULL);

			dbus_error_name = g_dbus_error_encode_gerror (error);

			/* Use error reason when the source cannot be prompted for credentials */
			e_dbus_source_emit_credentials_required (dbus_source, enum_value->value_nick,
				data->arg_certificate_pem, data->arg_certificate_errors, dbus_error_name, error->message);

			g_type_class_unref (enum_class);
			g_free (dbus_error_name);
		} else {
			/* Reinvoke for clients only, if not cancelled */
			const gchar *arg_dbus_error_name, *arg_dbus_error_message;
			gchar *dbus_error_name = NULL;

			arg_dbus_error_name = data->arg_dbus_error_name;
			arg_dbus_error_message = data->arg_dbus_error_message;

			if (!arg_dbus_error_name || !*arg_dbus_error_name) {
				if (!error)
					error = g_error_new_literal (G_IO_ERROR, G_IO_ERROR_FAILED, _("Unknown error"));

				dbus_error_name = g_dbus_error_encode_gerror (error);
				arg_dbus_error_name = dbus_error_name;
				arg_dbus_error_message = error->message;
			}

			e_dbus_source_emit_credentials_required (dbus_source, data->arg_reason,
				data->arg_certificate_pem, data->arg_certificate_errors,
				arg_dbus_error_name, arg_dbus_error_message);

			g_free (dbus_error_name);
		}
	}

	e_named_parameters_free (credentials);
	reinvoke_credentials_required_data_free (data);
	g_object_unref (dbus_source);
	g_object_unref (dbus_object);
	g_clear_error (&error);
}

static gboolean
server_side_source_get_last_credentials_required_arguments_cb (EDBusSource *dbus_interface,
							       GDBusMethodInvocation *invocation,
							       EServerSideSource *source)
{
	g_mutex_lock (&source->priv->last_values_lock);

	e_dbus_source_complete_get_last_credentials_required_arguments (dbus_interface, invocation,
		source->priv->last_reason ? source->priv->last_reason : "",
		source->priv->last_certificate_pem ? source->priv->last_certificate_pem : "",
		source->priv->last_certificate_errors ? source->priv->last_certificate_errors : "",
		source->priv->last_dbus_error_name ? source->priv->last_dbus_error_name : "",
		source->priv->last_dbus_error_message ? source->priv->last_dbus_error_message : "");

	g_mutex_unlock (&source->priv->last_values_lock);

	return TRUE;
}

static void
server_side_source_unset_last_credentials_required_arguments (EServerSideSource *source)
{
	g_return_if_fail (E_IS_SERVER_SIDE_SOURCE (source));

	g_mutex_lock (&source->priv->last_values_lock);

	g_free (source->priv->last_reason);
	g_free (source->priv->last_certificate_pem);
	g_free (source->priv->last_certificate_errors);
	g_free (source->priv->last_dbus_error_name);
	g_free (source->priv->last_dbus_error_message);

	source->priv->last_reason = NULL;
	source->priv->last_certificate_pem = NULL;
	source->priv->last_certificate_errors = NULL;
	source->priv->last_dbus_error_name = NULL;
	source->priv->last_dbus_error_message = NULL;

	g_mutex_unlock (&source->priv->last_values_lock);
}

static gboolean
server_side_source_unset_last_credentials_required_arguments_cb (EDBusSource *dbus_interface,
								 GDBusMethodInvocation *invocation,
								 EServerSideSource *source)
{
	server_side_source_unset_last_credentials_required_arguments (source);

	e_dbus_source_complete_unset_last_credentials_required_arguments (dbus_interface, invocation);

	return TRUE;
}

static gboolean
server_side_source_remove_cb (EDBusSourceRemovable *dbus_interface,
                              GDBusMethodInvocation *invocation,
                              EServerSideSource *source)
{
	GError *error = NULL;

	/* Note we don't need to verify the source is removable here
	 * since if it isn't, the remove() method won't be available.
	 * Descendants of the source are removed whether they export
	 * a remove() method or not. */

	e_source_remove_sync (E_SOURCE (source), NULL, &error);

	if (error != NULL)
		g_dbus_method_invocation_take_error (invocation, error);
	else
		e_dbus_source_removable_complete_remove (
			dbus_interface, invocation);

	return TRUE;
}

static gboolean
server_side_source_write_cb (EDBusSourceWritable *dbus_interface,
                             GDBusMethodInvocation *invocation,
                             const gchar *data,
                             ESource *source)
{
	GKeyFile *key_file;
	GDBusObject *dbus_object;
	EDBusSource *dbus_source;
	GError *error = NULL;

	/* Note we don't need to verify the source is writable here
	 * since if it isn't, the write() method won't be available. */

	dbus_object = e_source_ref_dbus_object (source);
	dbus_source = e_dbus_object_get_source (E_DBUS_OBJECT (dbus_object));

	/* Validate the raw data before making the changes live. */
	key_file = g_key_file_new ();
	server_side_source_parse_data (key_file, data, strlen (data), &error);
	g_key_file_free (key_file);

	/* Q: How does this trigger data being written to disk?
	 *
	 * A: Here's the sequence of events:
	 *
	 *    1) We set the EDBusSource:data property.
	 *    2) ESource picks up the "notify::data" signal and parses
	 *       the raw data, which triggers an ESource:changed signal.
	 *    3) Our changed() method schedules an idle callback.
	 *    4) The idle callback calls e_source_write_sync().
	 *    5) e_source_write_sync() calls e_dbus_source_dup_data()
	 *       and synchronously writes the resulting string to disk.
	 *
	 * XXX: This should be done more straigtforward, because rely
	 *      on two different signals and having actual data file
	 *      save in 5 steps is ridiculous, not talking that
	 *      the returned GError from this D-Bus call doesn't handle
	 *      errors from actual file save, which can also break, thus
	 *      the caller doesn't know about any real problem during saving
	 *      and thinks that everything went fine.
	 */

	if (error == NULL) {
		e_dbus_source_set_data (dbus_source, data);

		/* Make sure the ESource::changed signal is called, otherwise
		 * the above Q&A doesn't work and changed data are not saved. */
		e_source_changed (source);
	}

	if (error != NULL)
		g_dbus_method_invocation_take_error (invocation, error);
	else
		e_dbus_source_writable_complete_write (
			dbus_interface, invocation);

	g_object_unref (dbus_source);
	g_object_unref (dbus_object);

	return TRUE;
}

/* Helper for server_side_source_remote_create_cb() */
static void
server_side_source_remote_create_done_cb (GObject *source_object,
                                          GAsyncResult *result,
                                          gpointer user_data)
{
	ESource *source;
	AsyncContext *async_context;
	GError *error = NULL;

	source = E_SOURCE (source_object);
	async_context = (AsyncContext *) user_data;

	e_source_remote_create_finish (source, result, &error);

	if (error != NULL)
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	else
		e_dbus_source_remote_creatable_complete_create (
			async_context->remote_creatable,
			async_context->invocation);

	async_context_free (async_context);
}

static gboolean
server_side_source_remote_create_cb (EDBusSourceRemoteCreatable *dbus_interface,
                                     GDBusMethodInvocation *invocation,
                                     const gchar *uid,
                                     const gchar *data,
                                     ESource *source)
{
	EServerSideSource *server_side_source;
	ESourceRegistryServer *server;
	AsyncContext *async_context;
	ESource *scratch_source;
	GDBusObject *dbus_object;
	EDBusSource *dbus_source;
	GKeyFile *key_file;
	GFile *file;
	GError *error = NULL;

	/* Create a new EServerSideSource from 'uid' and 'data' but
	 * DO NOT add it to the ESourceRegistryServer yet.  It's up
	 * to the ECollectionBackend whether to use source as given
	 * or create its own equivalent EServerSideSource, possibly
	 * in response to a notification from a remote server. */

	/* Validate the raw data. */
	key_file = g_key_file_new ();
	server_side_source_parse_data (key_file, data, strlen (data), &error);
	g_key_file_free (key_file);

	if (error != NULL) {
		g_dbus_method_invocation_take_error (invocation, error);
		return TRUE;
	}

	server_side_source = E_SERVER_SIDE_SOURCE (source);
	server = e_server_side_source_get_server (server_side_source);

	file = e_server_side_source_new_user_file (uid);
	scratch_source = e_server_side_source_new (server, file, &error);
	g_object_unref (file);

	/* Sanity check. */
	g_warn_if_fail (
		((scratch_source != NULL) && (error == NULL)) ||
		((scratch_source == NULL) && (error != NULL)));

	if (error != NULL) {
		g_dbus_method_invocation_take_error (invocation, error);
		return TRUE;
	}

	dbus_object = e_source_ref_dbus_object (scratch_source);
	dbus_source = e_dbus_object_get_source (E_DBUS_OBJECT (dbus_object));

	e_dbus_source_set_data (dbus_source, data);

	g_object_unref (dbus_object);
	g_object_unref (dbus_source);

	async_context = g_slice_new0 (AsyncContext);
	async_context->remote_creatable = g_object_ref (dbus_interface);
	async_context->invocation = g_object_ref (invocation);

	e_source_remote_create (
		source, scratch_source, NULL,
		server_side_source_remote_create_done_cb,
		async_context);

	g_object_unref (scratch_source);

	return TRUE;
}

/* Helper for server_side_source_remote_delete_cb() */
static void
server_side_source_remote_delete_done_cb (GObject *source_object,
                                          GAsyncResult *result,
                                          gpointer user_data)
{
	ESource *source;
	AsyncContext *async_context;
	GError *error = NULL;

	source = E_SOURCE (source_object);
	async_context = (AsyncContext *) user_data;

	e_source_remote_delete_finish (source, result, &error);

	if (error != NULL)
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	else
		e_dbus_source_remote_deletable_complete_delete (
			async_context->remote_deletable,
			async_context->invocation);

	async_context_free (async_context);
}

static gboolean
server_side_source_remote_delete_cb (EDBusSourceRemoteDeletable *dbus_interface,
                                     GDBusMethodInvocation *invocation,
                                     ESource *source)
{
	AsyncContext *async_context;

	async_context = g_slice_new0 (AsyncContext);
	async_context->remote_deletable = g_object_ref (dbus_interface);
	async_context->invocation = g_object_ref (invocation);

	e_source_remote_delete (
		source, NULL,
		server_side_source_remote_delete_done_cb,
		async_context);

	return TRUE;
}

/* Helper for server_side_source_get_access_token_cb() */
static void
server_side_source_get_access_token_done_cb (GObject *source_object,
                                             GAsyncResult *result,
                                             gpointer user_data)
{
	ESource *source;
	AsyncContext *async_context;
	gchar *access_token = NULL;
	gint expires_in = 0;
	GError *error = NULL;

	source = E_SOURCE (source_object);
	async_context = (AsyncContext *) user_data;

	e_source_get_oauth2_access_token_finish (
		source, result, &access_token, &expires_in, &error);

	/* Sanity check. */
	g_return_if_fail (
		((access_token != NULL) && (error == NULL)) ||
		((access_token == NULL) && (error != NULL)));

	if (error != NULL)
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	else
		e_dbus_source_oauth2_support_complete_get_access_token (
			async_context->oauth2_support,
			async_context->invocation,
			access_token, expires_in);

	g_free (access_token);

	async_context_free (async_context);
}

static gboolean
server_side_source_get_access_token_cb (EDBusSourceOAuth2Support *dbus_interface,
                                        GDBusMethodInvocation *invocation,
                                        ESource *source)
{
	AsyncContext *async_context;

	async_context = g_slice_new0 (AsyncContext);
	async_context->oauth2_support = g_object_ref (dbus_interface);
	async_context->invocation = g_object_ref (invocation);

	e_source_get_oauth2_access_token (
		source, NULL,
		server_side_source_get_access_token_done_cb,
		async_context);

	return TRUE;
}

static void
server_side_source_set_file (EServerSideSource *source,
                             GFile *file)
{
	g_return_if_fail (file == NULL || G_IS_FILE (file));
	g_return_if_fail (source->priv->file == NULL);

	if (file != NULL)
		source->priv->file = g_object_ref (file);
}

static void
server_side_source_set_server (EServerSideSource *source,
                               ESourceRegistryServer *server)
{
	g_return_if_fail (E_IS_SOURCE_REGISTRY_SERVER (server));
	g_return_if_fail (source->priv->server == NULL);

	source->priv->server = server;

	g_object_add_weak_pointer (
		G_OBJECT (server), &source->priv->server);
}

static void
server_side_source_set_property (GObject *object,
                                 guint property_id,
                                 const GValue *value,
                                 GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_FILE:
			server_side_source_set_file (
				E_SERVER_SIDE_SOURCE (object),
				g_value_get_object (value));
			return;

		case PROP_OAUTH2_SUPPORT:
			e_server_side_source_set_oauth2_support (
				E_SERVER_SIDE_SOURCE (object),
				g_value_get_object (value));
			return;

		case PROP_REMOTE_CREATABLE:
			e_server_side_source_set_remote_creatable (
				E_SERVER_SIDE_SOURCE (object),
				g_value_get_boolean (value));
			return;

		case PROP_REMOTE_DELETABLE:
			e_server_side_source_set_remote_deletable (
				E_SERVER_SIDE_SOURCE (object),
				g_value_get_boolean (value));
			return;

		case PROP_REMOVABLE:
			e_server_side_source_set_removable (
				E_SERVER_SIDE_SOURCE (object),
				g_value_get_boolean (value));
			return;

		case PROP_SERVER:
			server_side_source_set_server (
				E_SERVER_SIDE_SOURCE (object),
				g_value_get_object (value));
			return;

		case PROP_WRITABLE:
			e_server_side_source_set_writable (
				E_SERVER_SIDE_SOURCE (object),
				g_value_get_boolean (value));
			return;

		case PROP_WRITE_DIRECTORY:
			e_server_side_source_set_write_directory (
				E_SERVER_SIDE_SOURCE (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
server_side_source_get_property (GObject *object,
                                 guint property_id,
                                 GValue *value,
                                 GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_EXPORTED:
			g_value_set_boolean (
				value,
				e_server_side_source_get_exported (
				E_SERVER_SIDE_SOURCE (object)));
			return;

		case PROP_FILE:
			g_value_set_object (
				value,
				e_server_side_source_get_file (
				E_SERVER_SIDE_SOURCE (object)));
			return;

		case PROP_OAUTH2_SUPPORT:
			g_value_take_object (
				value,
				e_server_side_source_ref_oauth2_support (
				E_SERVER_SIDE_SOURCE (object)));
			return;

		case PROP_REMOTE_CREATABLE:
			g_value_set_boolean (
				value,
				e_source_get_remote_creatable (
				E_SOURCE (object)));
			return;

		case PROP_REMOTE_DELETABLE:
			g_value_set_boolean (
				value,
				e_source_get_remote_deletable (
				E_SOURCE (object)));
			return;

		case PROP_REMOVABLE:
			g_value_set_boolean (
				value,
				e_source_get_removable (
				E_SOURCE (object)));
			return;

		case PROP_SERVER:
			g_value_set_object (
				value,
				e_server_side_source_get_server (
				E_SERVER_SIDE_SOURCE (object)));
			return;

		case PROP_WRITABLE:
			g_value_set_boolean (
				value,
				e_source_get_writable (
				E_SOURCE (object)));
			return;

		case PROP_WRITE_DIRECTORY:
			g_value_set_string (
				value,
				e_server_side_source_get_write_directory (
				E_SERVER_SIDE_SOURCE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
server_side_source_dispose (GObject *object)
{
	EServerSideSourcePrivate *priv;

	priv = E_SERVER_SIDE_SOURCE_GET_PRIVATE (object);

	g_mutex_lock (&priv->last_values_lock);

	g_free (priv->last_reason);
	g_free (priv->last_certificate_pem);
	g_free (priv->last_certificate_errors);
	g_free (priv->last_dbus_error_name);
	g_free (priv->last_dbus_error_message);
	priv->last_reason = NULL;
	priv->last_certificate_pem = NULL;
	priv->last_certificate_errors = NULL;
	priv->last_dbus_error_name = NULL;
	priv->last_dbus_error_message = NULL;

	e_named_parameters_free (priv->last_credentials);
	priv->last_credentials = NULL;

	g_mutex_unlock (&priv->last_values_lock);

	g_mutex_lock (&priv->pending_credentials_lookup_lock);
	if (priv->pending_credentials_lookup) {
		g_cancellable_cancel (priv->pending_credentials_lookup);
		g_clear_object (&priv->pending_credentials_lookup);
	}
	g_mutex_unlock (&priv->pending_credentials_lookup_lock);

	if (priv->server != NULL) {
		g_object_remove_weak_pointer (
			G_OBJECT (priv->server), &priv->server);
		priv->server = NULL;
	}

	g_weak_ref_set (&priv->oauth2_support, NULL);

	if (priv->file != NULL) {
		g_object_unref (priv->file);
		priv->file = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_server_side_source_parent_class)->dispose (object);
}

static void
server_side_source_finalize (GObject *object)
{
	EServerSideSourcePrivate *priv;

	priv = E_SERVER_SIDE_SOURCE_GET_PRIVATE (object);

	g_node_unlink (&priv->node);

	g_free (priv->file_contents);
	g_free (priv->write_directory);

	g_weak_ref_clear (&priv->oauth2_support);
	g_mutex_clear (&priv->last_values_lock);
	g_mutex_clear (&priv->pending_credentials_lookup_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_server_side_source_parent_class)->finalize (object);
}

static void
server_side_source_changed (ESource *source)
{
	GDBusObject *dbus_object;
	EDBusSource *dbus_source;
	gchar *old_data;
	gchar *new_data;
	GError *error = NULL;

	/* Do not write changes to disk until the source has been exported. */
	if (!e_server_side_source_get_exported (E_SERVER_SIDE_SOURCE (source)))
		return;

	dbus_object = e_source_ref_dbus_object (source);
	dbus_source = e_dbus_object_get_source (E_DBUS_OBJECT (dbus_object));

	old_data = e_dbus_source_dup_data (dbus_source);
	new_data = e_source_to_string (source, NULL);

	/* Setting the "data" property triggers the ESource::changed,
	 * signal, which invokes this callback, which sets the "data"
	 * property, etc.  This breaks an otherwise infinite loop. */
	if (g_strcmp0 (old_data, new_data) != 0)
		e_dbus_source_set_data (dbus_source, new_data);

	g_free (old_data);
	g_free (new_data);

	g_object_unref (dbus_source);
	g_object_unref (dbus_object);

	/* This writes the "data" property to disk. */
	e_source_write_sync (source, NULL, &error);

	if (error != NULL) {
		g_warning ("%s: %s", G_STRFUNC, error->message);
		g_error_free (error);
	}
}

static gboolean
server_side_source_remove_sync (ESource *source,
                                GCancellable *cancellable,
                                GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	closure = e_async_closure_new ();

	e_source_remove (
		source, cancellable, e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_source_remove_finish (source, result, error);

	e_async_closure_free (closure);

	return success;
}

static void
server_side_source_remove (ESource *source,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
	EServerSideSourcePrivate *priv;
	GSimpleAsyncResult *simple;
	ESourceRegistryServer *server;
	GQueue queue = G_QUEUE_INIT;
	GList *list, *link;
	GError *error = NULL;

	/* XXX Yes we block here.  We do this operation
	 *     synchronously to keep the server code simple. */

	priv = E_SERVER_SIDE_SOURCE_GET_PRIVATE (source);

	simple = g_simple_async_result_new (
		G_OBJECT (source), callback, user_data,
		server_side_source_remove);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	/* Collect the source and its descendants into a queue.
	 * Do this before unexporting so we hold references to
	 * all the removed sources. */
	g_node_traverse (
		&priv->node, G_POST_ORDER, G_TRAVERSE_ALL, -1,
		(GNodeTraverseFunc) server_side_source_traverse_cb, &queue);

	/* Unexport the object and its descendants. */
	server = E_SOURCE_REGISTRY_SERVER (priv->server);
	e_source_registry_server_remove_source (server, source);

	list = g_queue_peek_head_link (&queue);

	/* Delete the key file for each source in the queue. */
	for (link = list; link != NULL; link = g_list_next (link)) {
		EServerSideSource *child;
		GFile *file;

		child = E_SERVER_SIDE_SOURCE (link->data);
		file = e_server_side_source_get_file (child);

		if (file != NULL)
			g_file_delete (file, cancellable, &error);

		/* XXX Even though e_source_registry_server_remove_source()
		 *     is called first, the object path is unexported from
		 *     an idle callback some time after we have deleted the
		 *     key file.  That creates a small window of time where
		 *     the file is deleted but the object is still exported.
		 *
		 *     If a client calls e_source_remove() during that small
		 *     window of time, we still want to report a successful
		 *     removal, so disregard G_IO_ERROR_NOT_FOUND. */
		if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND))
			g_clear_error (&error);

		if (error != NULL)
			goto exit;
	}

exit:
	while (!g_queue_is_empty (&queue))
		g_object_unref (g_queue_pop_head (&queue));

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);

	g_simple_async_result_complete_in_idle (simple);
	g_object_unref (simple);
}

static gboolean
server_side_source_remove_finish (ESource *source,
                                  GAsyncResult *result,
                                  GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (source),
		server_side_source_remove), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static gboolean
server_side_source_write_sync (ESource *source,
                               GCancellable *cancellable,
                               GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	closure = e_async_closure_new ();

	e_source_write (
		source, cancellable, e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_source_write_finish (source, result, error);

	e_async_closure_free (closure);

	return success;
}

static void
server_side_source_write (ESource *source,
                          GCancellable *cancellable,
                          GAsyncReadyCallback callback,
                          gpointer user_data)
{
	EServerSideSourcePrivate *priv;
	GSimpleAsyncResult *simple;
	GDBusObject *dbus_object;
	EDBusSource *dbus_source;
	gboolean replace_file;
	const gchar *old_data;
	gchar *new_data;
	GError *error = NULL;

	/* XXX Yes we block here.  We do this operation
	 *     synchronously to keep the server code simple. */

	priv = E_SERVER_SIDE_SOURCE_GET_PRIVATE (source);

	simple = g_simple_async_result_new (
		G_OBJECT (source), callback, user_data,
		server_side_source_write);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	dbus_object = e_source_ref_dbus_object (source);
	dbus_source = e_dbus_object_get_source (E_DBUS_OBJECT (dbus_object));

	old_data = priv->file_contents;
	new_data = e_source_to_string (source, NULL);

	/* When writing source data to disk, we always write to the
	 * source's specified "write-directory" even if the key file
	 * was originally read from a different directory.  To avoid
	 * polluting the write directory with key files identical to
	 * the original, we check that the data has actually changed
	 * before writing a copy to disk. */

	replace_file =
		G_IS_FILE (priv->file) &&
		(g_strcmp0 (old_data, new_data) != 0);

	if (replace_file) {
		GFile *file;
		GFile *write_directory;
		gchar *basename;

		g_warn_if_fail (priv->write_directory != NULL);

		basename = g_file_get_basename (priv->file);
		write_directory = g_file_new_for_path (priv->write_directory);
		file = g_file_get_child (write_directory, basename);
		g_free (basename);

		if (!g_file_equal (file, priv->file)) {
			g_object_unref (priv->file);
			priv->file = g_object_ref (file);
		}

		server_side_source_print_diff (source, old_data, new_data);

		g_file_make_directory_with_parents (
			write_directory, cancellable, &error);

		if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_EXISTS))
			g_clear_error (&error);

		if (error == NULL)
			g_file_replace_contents (
				file, new_data, strlen (new_data),
				NULL, FALSE, G_FILE_CREATE_NONE,
				NULL, cancellable, &error);

		if (error == NULL) {
			g_free (priv->file_contents);
			priv->file_contents = new_data;
			new_data = NULL;
		}

		g_object_unref (write_directory);
		g_object_unref (file);
	}

	g_free (new_data);

	g_object_unref (dbus_source);
	g_object_unref (dbus_object);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);

	g_simple_async_result_complete_in_idle (simple);
	g_object_unref (simple);
}

static gboolean
server_side_source_write_finish (ESource *source,
                                 GAsyncResult *result,
                                 GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (source),
		server_side_source_write), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static gboolean
server_side_source_remote_create_sync (ESource *source,
                                       ESource *scratch_source,
                                       GCancellable *cancellable,
                                       GError **error)
{
	ECollectionBackend *backend;
	ESourceRegistryServer *server;
	EServerSideSource *server_side_source;
	gboolean success;

	if (!e_source_get_remote_creatable (source)) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_NOT_SUPPORTED,
			_("Data source “%s” does not "
			"support creating remote resources"),
			e_source_get_display_name (source));
		return FALSE;
	}

	server_side_source = E_SERVER_SIDE_SOURCE (source);
	server = e_server_side_source_get_server (server_side_source);
	backend = e_source_registry_server_ref_backend (server, source);

	if (backend == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_NOT_SUPPORTED,
			_("Data source “%s” has no collection "
			"backend to create the remote resource"),
			e_source_get_display_name (source));
		return FALSE;
	}

	success = e_collection_backend_create_resource_sync (
		backend, scratch_source, cancellable, error);

	g_object_unref (backend);

	return success;
}

static gboolean
server_side_source_remote_delete_sync (ESource *source,
                                       GCancellable *cancellable,
                                       GError **error)
{
	ECollectionBackend *backend;
	ESourceRegistryServer *server;
	EServerSideSource *server_side_source;
	gboolean success;

	if (!e_source_get_remote_deletable (source)) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_NOT_SUPPORTED,
			_("Data source “%s” does not "
			"support deleting remote resources"),
			e_source_get_display_name (source));
		return FALSE;
	}

	server_side_source = E_SERVER_SIDE_SOURCE (source);
	server = e_server_side_source_get_server (server_side_source);
	backend = e_source_registry_server_ref_backend (server, source);

	if (backend == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_NOT_SUPPORTED,
			_("Data source “%s” has no collection "
			"backend to delete the remote resource"),
			e_source_get_display_name (source));
		return FALSE;
	}

	success = e_collection_backend_delete_resource_sync (
		backend, source, cancellable, error);

	g_object_unref (backend);

	return success;
}

static gboolean
server_side_source_get_oauth2_access_token_sync (ESource *source,
                                                 GCancellable *cancellable,
                                                 gchar **out_access_token,
                                                 gint *out_expires_in,
                                                 GError **error)
{
	EOAuth2Support *oauth2_support;
	gboolean success;

	oauth2_support = e_server_side_source_ref_oauth2_support (
		E_SERVER_SIDE_SOURCE (source));

	if (oauth2_support == NULL) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_NOT_SUPPORTED,
			_("Data source “%s” does not "
			"support OAuth 2.0 authentication"),
			e_source_get_display_name (source));
		return FALSE;
	}

	success = e_oauth2_support_get_access_token_sync (
		oauth2_support, source, cancellable,
		out_access_token, out_expires_in, error);

	g_object_unref (oauth2_support);

	return success;
}

static gboolean
server_side_source_invoke_credentials_required_impl (ESource *source,
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

	return server_side_source_invoke_credentials_required_cb (dbus_source, NULL,
		arg_reason ? arg_reason : "",
		arg_certificate_pem ? arg_certificate_pem : "",
		arg_certificate_errors ? arg_certificate_errors : "",
		arg_dbus_error_name ? arg_dbus_error_name : "",
		arg_dbus_error_message ? arg_dbus_error_message : "",
		E_SERVER_SIDE_SOURCE (source));
}

static gboolean
server_side_source_invoke_authenticate_impl (ESource *source,
					     gpointer dbus_source, /* EDBusSource * */
					     const gchar * const *arg_credentials,
					     GCancellable *cancellable,
					     GError **error)
{
	g_return_val_if_fail (E_DBUS_IS_SOURCE (dbus_source), FALSE);

	return server_side_source_invoke_authenticate_cb (dbus_source, NULL,
		arg_credentials, E_SERVER_SIDE_SOURCE (source));
}

static gboolean
server_side_source_unset_last_credentials_required_arguments_impl (ESource *source,
								   GCancellable *cancellable,
								   GError **error)
{
	g_return_val_if_fail (E_IS_SERVER_SIDE_SOURCE (source), FALSE);

	server_side_source_unset_last_credentials_required_arguments (E_SERVER_SIDE_SOURCE (source));

	return TRUE;
}

static gboolean
server_side_source_initable_init (GInitable *initable,
                                  GCancellable *cancellable,
                                  GError **error)
{
	EServerSideSource *source;
	GDBusObject *dbus_object;
	EDBusSource *dbus_source;
	gchar *uid;

	source = E_SERVER_SIDE_SOURCE (initable);

	dbus_source = e_dbus_source_skeleton_new ();

	uid = e_source_dup_uid (E_SOURCE (source));
	if (uid == NULL)
		uid = e_util_generate_uid ();
	e_dbus_source_set_uid (dbus_source, uid);
	g_free (uid);

	dbus_object = e_source_ref_dbus_object (E_SOURCE (source));
	e_dbus_object_skeleton_set_source (
		E_DBUS_OBJECT_SKELETON (dbus_object), dbus_source);
	g_object_unref (dbus_object);

	g_signal_connect (
		dbus_source, "handle-invoke-credentials-required",
		G_CALLBACK (server_side_source_invoke_credentials_required_cb), source);
	g_signal_connect (
		dbus_source, "handle-invoke-authenticate",
		G_CALLBACK (server_side_source_invoke_authenticate_cb), source);
	g_signal_connect (
		dbus_source, "handle-get-last-credentials-required-arguments",
		G_CALLBACK (server_side_source_get_last_credentials_required_arguments_cb), source);
	g_signal_connect (
		dbus_source, "handle-unset-last-credentials-required-arguments",
		G_CALLBACK (server_side_source_unset_last_credentials_required_arguments_cb), source);

	g_object_unref (dbus_source);

	if (!e_server_side_source_load (source, cancellable, error))
		return FALSE;

	/* Chain up to parent interface's init() method. */
	return initable_parent_interface->init (initable, cancellable, error);
}

static void
e_server_side_source_class_init (EServerSideSourceClass *class)
{
	GObjectClass *object_class;
	ESourceClass *source_class;

	g_type_class_add_private (class, sizeof (EServerSideSourcePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = server_side_source_set_property;
	object_class->get_property = server_side_source_get_property;
	object_class->dispose = server_side_source_dispose;
	object_class->finalize = server_side_source_finalize;

	source_class = E_SOURCE_CLASS (class);
	source_class->changed = server_side_source_changed;
	source_class->remove_sync = server_side_source_remove_sync;
	source_class->remove = server_side_source_remove;
	source_class->remove_finish = server_side_source_remove_finish;
	source_class->write_sync = server_side_source_write_sync;
	source_class->write = server_side_source_write;
	source_class->write_finish = server_side_source_write_finish;
	source_class->remote_create_sync = server_side_source_remote_create_sync;
	source_class->remote_delete_sync = server_side_source_remote_delete_sync;
	source_class->get_oauth2_access_token_sync = server_side_source_get_oauth2_access_token_sync;
	source_class->invoke_credentials_required_impl = server_side_source_invoke_credentials_required_impl;
	source_class->invoke_authenticate_impl = server_side_source_invoke_authenticate_impl;
	source_class->unset_last_credentials_required_arguments_impl = server_side_source_unset_last_credentials_required_arguments_impl;

	g_object_class_install_property (
		object_class,
		PROP_EXPORTED,
		g_param_spec_boolean (
			"exported",
			"Exported",
			"Whether the source has been exported over D-Bus",
			FALSE,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_FILE,
		g_param_spec_object (
			"file",
			"File",
			"The key file for the data source",
			G_TYPE_FILE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_OAUTH2_SUPPORT,
		g_param_spec_object (
			"oauth2-support",
			"OAuth2 Support",
			"The object providing OAuth 2.0 support",
			E_TYPE_OAUTH2_SUPPORT,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/* This overrides the "remote-creatable" property
	 * in ESourceClass with a writable version. */
	g_object_class_install_property (
		object_class,
		PROP_REMOTE_CREATABLE,
		g_param_spec_boolean (
			"remote-creatable",
			"Remote Creatable",
			"Whether the data source "
			"can create remote resources",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/* This overrides the "remote-deletable" property
	 * in ESourceClass with a writable version. */
	g_object_class_install_property (
		object_class,
		PROP_REMOTE_DELETABLE,
		g_param_spec_boolean (
			"remote-deletable",
			"Remote Deletable",
			"Whether the data source "
			"can delete remote resources",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/* This overrides the "removable" property
	 * in ESourceClass with a writable version. */
	g_object_class_install_property (
		object_class,
		PROP_REMOVABLE,
		g_param_spec_boolean (
			"removable",
			"Removable",
			"Whether the data source is removable",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_SERVER,
		g_param_spec_object (
			"server",
			"Server",
			"The server to which the data source belongs",
			E_TYPE_SOURCE_REGISTRY_SERVER,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/* This overrides the "writable" property
	 * in ESourceClass with a writable version. */
	g_object_class_install_property (
		object_class,
		PROP_WRITABLE,
		g_param_spec_boolean (
			"writable",
			"Writable",
			"Whether the data source is writable",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/* Do not use G_PARAM_CONSTRUCT.  We initialize the
	 * property ourselves in e_server_side_source_init(). */
	g_object_class_install_property (
		object_class,
		PROP_WRITE_DIRECTORY,
		g_param_spec_string (
			"write-directory",
			"Write Directory",
			"Directory in which to write changes to disk",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));
}

static void
e_server_side_source_initable_init (GInitableIface *iface)
{
	initable_parent_interface = g_type_interface_peek_parent (iface);

	iface->init = server_side_source_initable_init;
}

static void
e_server_side_source_init (EServerSideSource *source)
{
	const gchar *user_dir;

	source->priv = E_SERVER_SIDE_SOURCE_GET_PRIVATE (source);

	source->priv->node.data = source;

	user_dir = e_server_side_source_get_user_dir ();
	source->priv->write_directory = g_strdup (user_dir);

	g_weak_ref_init (&source->priv->oauth2_support, NULL);
	g_mutex_init (&source->priv->last_values_lock);
	g_mutex_init (&source->priv->pending_credentials_lookup_lock);
}

/**
 * e_server_side_source_get_user_dir:
 *
 * Returns the directory where user-specific data source files are stored.
 *
 * Returns: the user-specific data source directory
 *
 * Since: 3.6
 **/
const gchar *
e_server_side_source_get_user_dir (void)
{
	static gchar *dirname = NULL;

	if (G_UNLIKELY (dirname == NULL)) {
		const gchar *config_dir = e_get_user_config_dir ();
		dirname = g_build_filename (config_dir, "sources", NULL);
		g_mkdir_with_parents (dirname, 0700);
	}

	return dirname;
}

/**
 * e_server_side_source_new_user_file:
 * @uid: unique identifier for a data source, or %NULL
 *
 * Generates a unique file name for a new user-specific data source.
 * If @uid is non-%NULL it will be used in the basename of the file,
 * otherwise a unique basename will be generated using e_util_generate_uid().
 *
 * The returned #GFile can then be passed to e_server_side_source_new().
 * Unreference the #GFile with g_object_unref() when finished with it.
 *
 * Note the data source file itself is not created here, only its name.
 *
 * Returns: the #GFile for a new data source
 *
 * Since: 3.6
 **/
GFile *
e_server_side_source_new_user_file (const gchar *uid)
{
	GFile *file;
	gchar *safe_uid;
	gchar *basename;
	gchar *filename;
	const gchar *user_dir;

	if (uid == NULL)
		safe_uid = e_util_generate_uid ();
	else
		safe_uid = g_strdup (uid);
	e_filename_make_safe (safe_uid);

	user_dir = e_server_side_source_get_user_dir ();
	basename = g_strconcat (safe_uid, ".source", NULL);
	filename = g_build_filename (user_dir, basename, NULL);

	file = g_file_new_for_path (filename);

	g_free (basename);
	g_free (filename);
	g_free (safe_uid);

	return file;
}

/**
 * e_server_side_source_uid_from_file:
 * @file: a #GFile for a data source
 * @error: return location for a #GError, or %NULL
 *
 * Extracts a unique identity string from the base name of @file.
 * If the base name of @file is missing a '.source' extension, the
 * function sets @error and returns %NULL.
 *
 * Returns: the unique identity string for @file, or %NULL
 *
 * Since: 3.6
 **/
gchar *
e_server_side_source_uid_from_file (GFile *file,
                                    GError **error)
{
	gchar *basename;
	gchar *uid = NULL;

	g_return_val_if_fail (G_IS_FILE (file), FALSE);

	basename = g_file_get_basename (file);

	if (*basename == '.') {
		/* ignore hidden files */
	} else if (g_str_has_suffix (basename, ".source")) {
		/* strlen(".source") --> 7 */
		uid = g_strndup (basename, strlen (basename) - 7);
	} else {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_INVALID_FILENAME,
			_("File must have a “.source” extension"));
	}

	g_free (basename);

	return uid;
}

/**
 * e_server_side_source_new:
 * @server: an #ESourceRegistryServer
 * @file: a #GFile, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #EServerSideSource which belongs to @server.  If @file
 * is non-%NULL and points to an existing file, the #EServerSideSource is
 * initialized from the file content.  If a read error occurs or the file
 * contains syntax errors, the function sets @error and returns %NULL.
 *
 * Returns: a new #EServerSideSource, or %NULL
 *
 * Since: 3.6
 **/
ESource *
e_server_side_source_new (ESourceRegistryServer *server,
                          GFile *file,
                          GError **error)
{
	EDBusObjectSkeleton *dbus_object;
	ESource *source;
	gchar *uid = NULL;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY_SERVER (server), NULL);
	g_return_val_if_fail (file == NULL || G_IS_FILE (file), NULL);

	/* Extract a UID from the GFile, if we were given one. */
	if (file != NULL) {
		uid = e_server_side_source_uid_from_file (file, error);
		if (uid == NULL)
			return NULL;
	}

	/* XXX This is an awkward way of initializing the "dbus-object"
	 *     property, but e_source_ref_dbus_object() needs to work. */
	dbus_object = e_dbus_object_skeleton_new (DBUS_OBJECT_PATH);

	source = g_initable_new (
		E_TYPE_SERVER_SIDE_SOURCE, NULL, error,
		"dbus-object", dbus_object,
		"file", file, "server", server,
		"uid", uid, NULL);

	g_object_unref (dbus_object);
	g_free (uid);

	return source;
}

/**
 * e_server_side_source_new_memory_only:
 * @server: an #ESourceRegistryServer
 * @uid: a unique identifier, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a memory-only #EServerSideSource which belongs to @server.
 * No on-disk key file is created for this data source, so it will not
 * be remembered across sessions.
 *
 * Data source collections are often populated with memory-only data
 * sources to serve as proxies for resources discovered on a remote server.
 * These data sources are usually neither #EServerSideSource:writable nor
 * #EServerSideSource:removable by clients, at least not directly.
 *
 * If an error occurs while instantiating the #EServerSideSource, the
 * function sets @error and returns %NULL.  Although at this time there
 * are no known error conditions for memory-only data sources.
 *
 * Returns: a new memory-only #EServerSideSource, or %NULL
 *
 * Since: 3.6
 **/
ESource *
e_server_side_source_new_memory_only (ESourceRegistryServer *server,
                                      const gchar *uid,
                                      GError **error)
{
	EDBusObjectSkeleton *dbus_object;
	ESource *source;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY_SERVER (server), NULL);

	/* XXX This is an awkward way of initializing the "dbus-object"
	 *     property, but e_source_ref_dbus_object() needs to work. */
	dbus_object = e_dbus_object_skeleton_new (DBUS_OBJECT_PATH);

	source = g_initable_new (
		E_TYPE_SERVER_SIDE_SOURCE, NULL, error,
		"dbus-object", dbus_object,
		"server", server, "uid", uid, NULL);

	g_object_unref (dbus_object);

	return source;
}

/**
 * e_server_side_source_load:
 * @source: an #EServerSideSource
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Reloads data source content from the file pointed to by the
 * #EServerSideSource:file property.
 *
 * If the #EServerSideSource:file property is %NULL or the file it points
 * to does not exist, the function does nothing and returns %TRUE.
 *
 * If a read error occurs or the file contains syntax errors, the function
 * sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
e_server_side_source_load (EServerSideSource *source,
                           GCancellable *cancellable,
                           GError **error)
{
	GDBusObject *dbus_object;
	EDBusSource *dbus_source;
	GKeyFile *key_file;
	GFile *file;
	gboolean success = TRUE;
	gchar *data = NULL;
	gsize length;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_SERVER_SIDE_SOURCE (source), FALSE);

	file = e_server_side_source_get_file (source);

	if (file != NULL && !g_file_load_contents (file, cancellable, &data, &length, NULL, &local_error)) {
		data = NULL;
		length = 0;
	}

	/* Disregard G_IO_ERROR_NOT_FOUND and treat it as a successful load. */
	if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND)) {
		g_error_free (local_error);

	} else if (local_error != NULL) {
		g_propagate_error (error, local_error);
		return FALSE;

	} else {
		source->priv->file_contents = g_strdup (data);
	}

	if (data == NULL) {
		/* Create the bare minimum to pass parse_data(). */
		data = g_strdup_printf ("[%s]", PRIMARY_GROUP_NAME);
		length = strlen (data);
	}

	key_file = g_key_file_new ();

	success = server_side_source_parse_data (
		key_file, data, length, error);

	g_key_file_free (key_file);

	if (!success) {
		g_free (data);
		return FALSE;
	}

	/* Update the D-Bus interface properties. */

	dbus_object = e_source_ref_dbus_object (E_SOURCE (source));
	dbus_source = e_dbus_object_get_source (E_DBUS_OBJECT (dbus_object));

	e_dbus_source_set_data (dbus_source, data);

	g_object_unref (dbus_source);
	g_object_unref (dbus_object);

	g_free (data);

	return TRUE;
}

/**
 * e_server_side_source_get_file:
 * @source: an #EServerSideSource
 *
 * Returns the #GFile from which data source content is loaded and to
 * which changes are saved.  Note the @source may not have a #GFile.
 *
 * Returns: the #GFile for @source, or %NULL
 *
 * Since: 3.6
 **/
GFile *
e_server_side_source_get_file (EServerSideSource *source)
{
	g_return_val_if_fail (E_IS_SERVER_SIDE_SOURCE (source), NULL);

	return source->priv->file;
}

/**
 * e_server_side_source_get_node:
 * @source: an #EServerSideSource
 *
 * Returns the #GNode representing the @source's hierarchical placement,
 * or %NULL if @source has not been placed in the data source hierarchy.
 * The data member of the #GNode points back to @source.  This is an easy
 * way to traverse ancestor and descendant data sources.
 *
 * Note that accessing other data sources this way is not thread-safe,
 * and this therefore function may be replaced at some later date.
 *
 * Returns: a #GNode, or %NULL
 *
 * Since: 3.6
 **/
GNode *
e_server_side_source_get_node (EServerSideSource *source)
{
	g_return_val_if_fail (E_IS_SERVER_SIDE_SOURCE (source), NULL);

	return &source->priv->node;
}

/**
 * e_server_side_source_get_server:
 * @source: an #EServerSideSource
 *
 * Returns the #ESourceRegistryServer to which @source belongs.
 *
 * Returns: the #ESourceRegistryServer for @source
 *
 * Since: 3.6
 **/
ESourceRegistryServer *
e_server_side_source_get_server (EServerSideSource *source)
{
	g_return_val_if_fail (E_IS_SERVER_SIDE_SOURCE (source), NULL);

	return source->priv->server;
}

/**
 * e_server_side_source_get_exported:
 * @source: an #EServerSideSource
 *
 * Returns whether @source has been exported over D-Bus.
 *
 * The function returns %FALSE after @source is initially created, %TRUE
 * after passing @source uid to e_source_registry_server_ref_source() (provided
 * that @source's #ESource:parent is also exported).
 *
 * Returns: whether @source has been exported
 *
 * Since: 3.6
 **/
gboolean
e_server_side_source_get_exported (EServerSideSource *source)
{
	ESourceRegistryServer *server;
	ESource *exported_source;
	gboolean exported = FALSE;
	const gchar *uid;

	g_return_val_if_fail (E_IS_SERVER_SIDE_SOURCE (source), FALSE);

	uid = e_source_get_uid (E_SOURCE (source));
	server = e_server_side_source_get_server (source);

	/* We're exported if we can look ourselves up in the registry. */

	exported_source = e_source_registry_server_ref_source (server, uid);
	if (exported_source != NULL) {
		exported = TRUE;
		g_object_unref (exported_source);
	}

	return exported;
}

/**
 * e_server_side_source_get_write_directory:
 * @source: an #EServerSideSource
 *
 * Returns the local directory path where changes to @source are written.
 *
 * By default, changes are written to the local directory path returned by
 * e_server_side_source_get_user_dir(), but an #ECollectionBackend may wish
 * to override this to use its own private cache directory for data sources
 * it creates automatically.
 *
 * Returns: the directory where changes are written
 *
 * Since: 3.6
 **/
const gchar *
e_server_side_source_get_write_directory (EServerSideSource *source)
{
	g_return_val_if_fail (E_IS_SERVER_SIDE_SOURCE (source), NULL);

	return source->priv->write_directory;
}

/**
 * e_server_side_source_set_write_directory:
 * @source: an #EServerSideSource
 * @write_directory: the directory where changes are to be written
 *
 * Sets the local directory path where changes to @source are to be written.
 *
 * By default, changes are written to the local directory path returned by
 * e_server_side_source_get_user_dir(), but an #ECollectionBackend may wish
 * to override this to use its own private cache directory for data sources
 * it creates automatically.
 *
 * Since: 3.6
 **/
void
e_server_side_source_set_write_directory (EServerSideSource *source,
                                          const gchar *write_directory)
{
	g_return_if_fail (E_IS_SERVER_SIDE_SOURCE (source));
	g_return_if_fail (write_directory != NULL);

	if (g_strcmp0 (source->priv->write_directory, write_directory) == 0)
		return;

	g_free (source->priv->write_directory);
	source->priv->write_directory = g_strdup (write_directory);

	g_object_notify (G_OBJECT (source), "write-directory");
}

/**
 * e_server_side_source_set_removable:
 * @source: an #EServerSideSource
 * @removable: whether to export the Removable interface
 *
 * Sets whether to allow registry clients to remove @source and its
 * descendants.  If %TRUE, the Removable D-Bus interface is exported at
 * the object path for @source.  If %FALSE, the Removable D-Bus interface
 * is unexported at the object path for @source, and any attempt by clients
 * to call e_source_remove() will fail.
 *
 * Note this is only enforced for clients of the registry D-Bus service.
 * The service itself may remove any data source at any time.
 *
 * Since: 3.6
 **/
void
e_server_side_source_set_removable (EServerSideSource *source,
                                    gboolean removable)
{
	EDBusSourceRemovable *dbus_interface = NULL;
	GDBusObject *dbus_object;
	gboolean currently_removable;

	g_return_if_fail (E_IS_SERVER_SIDE_SOURCE (source));

	currently_removable = e_source_get_removable (E_SOURCE (source));

	if (removable == currently_removable)
		return;

	if (removable) {
		dbus_interface =
			e_dbus_source_removable_skeleton_new ();

		g_signal_connect (
			dbus_interface, "handle-remove",
			G_CALLBACK (server_side_source_remove_cb), source);
	}

	dbus_object = e_source_ref_dbus_object (E_SOURCE (source));
	e_dbus_object_skeleton_set_source_removable (
		E_DBUS_OBJECT_SKELETON (dbus_object), dbus_interface);
	g_object_unref (dbus_object);

	if (dbus_interface != NULL)
		g_object_unref (dbus_interface);

	g_object_notify (G_OBJECT (source), "removable");
}

/**
 * e_server_side_source_set_writable:
 * @source: an #EServerSideSource
 * @writable: whether to export the Writable interface
 *
 * Sets whether to allow registry clients to alter the content of @source.
 * If %TRUE, the Writable D-Bus interface is exported at the object path
 * for @source.  If %FALSE, the Writable D-Bus interface is unexported at
 * the object path for @source, and any attempt by clients to call
 * e_source_write() will fail.
 *
 * Note this is only enforced for clients of the registry D-Bus service.
 * The service itself can write to any data source at any time.
 *
 * Since: 3.6
 **/
void
e_server_side_source_set_writable (EServerSideSource *source,
                                   gboolean writable)
{
	EDBusSourceWritable *dbus_interface = NULL;
	GDBusObject *dbus_object;
	gboolean currently_writable;

	g_return_if_fail (E_IS_SERVER_SIDE_SOURCE (source));

	currently_writable = e_source_get_writable (E_SOURCE (source));

	if (writable == currently_writable)
		return;

	if (writable) {
		dbus_interface =
			e_dbus_source_writable_skeleton_new ();

		g_signal_connect (
			dbus_interface, "handle-write",
			G_CALLBACK (server_side_source_write_cb), source);
	}

	dbus_object = e_source_ref_dbus_object (E_SOURCE (source));
	e_dbus_object_skeleton_set_source_writable (
		E_DBUS_OBJECT_SKELETON (dbus_object), dbus_interface);
	g_object_unref (dbus_object);

	if (dbus_interface != NULL)
		g_object_unref (dbus_interface);

	g_object_notify (G_OBJECT (source), "writable");
}

/**
 * e_server_side_source_set_remote_creatable:
 * @source: an #EServerSideSource
 * @remote_creatable: whether to export the RemoteCreatable interface
 *
 * Indicates whether @source can be used to create resources on a remote
 * server.  Typically this is only set to %TRUE for collection sources.
 *
 * If %TRUE, the RemoteCreatable D-Bus interface is exported at the object
 * path for @source.  If %FALSE, the RemoteCreatable D-Bus interface is
 * unexported at the object path for @source, and any attempt by clients
 * to call e_source_remote_create() will fail.
 *
 * Unlike the #ESource:removable and #ESource:writable properties, this
 * is enforced for both clients of the registry D-Bus service and within
 * the registry D-Bus service itself.
 *
 * Since: 3.6
 **/
void
e_server_side_source_set_remote_creatable (EServerSideSource *source,
                                           gboolean remote_creatable)
{
	EDBusSourceRemoteCreatable *dbus_interface = NULL;
	GDBusObject *dbus_object;
	gboolean currently_remote_creatable;

	g_return_if_fail (E_IS_SERVER_SIDE_SOURCE (source));

	currently_remote_creatable =
		e_source_get_remote_creatable (E_SOURCE (source));

	if (remote_creatable == currently_remote_creatable)
		return;

	if (remote_creatable) {
		dbus_interface =
			e_dbus_source_remote_creatable_skeleton_new ();

		g_signal_connect (
			dbus_interface, "handle-create",
			G_CALLBACK (server_side_source_remote_create_cb),
			source);
	}

	dbus_object = e_source_ref_dbus_object (E_SOURCE (source));
	e_dbus_object_skeleton_set_source_remote_creatable (
		E_DBUS_OBJECT_SKELETON (dbus_object), dbus_interface);
	g_object_unref (dbus_object);

	if (dbus_interface != NULL)
		g_object_unref (dbus_interface);

	g_object_notify (G_OBJECT (source), "remote-creatable");
}

/**
 * e_server_side_source_set_remote_deletable:
 * @source: an #EServerSideSource
 * @remote_deletable: whether to export the RemoteDeletable interface
 *
 * Indicates whether @source can be used to delete resources on a remote
 * server.  Typically this is only set to %TRUE for sources created by an
 * #ECollectionBackend to represent a remote resource.
 *
 * If %TRUE, the RemoteDeletable D-Bus interface is exported at the object
 * path for @source.  If %FALSE, the RemoteDeletable D-Bus interface is
 * unexported at the object path for @source, and any attempt by clients
 * to call e_source_remote_delete() will fail.
 *
 * Unlike the #ESource:removable and #ESource:writable properties, this
 * is enforced for both clients of the registry D-Bus server and within
 * the registry D-Bus service itself.
 *
 * Since: 3.6
 **/
void
e_server_side_source_set_remote_deletable (EServerSideSource *source,
                                           gboolean remote_deletable)
{
	EDBusSourceRemoteDeletable *dbus_interface = NULL;
	GDBusObject *dbus_object;
	gboolean currently_remote_deletable;

	g_return_if_fail (E_IS_SERVER_SIDE_SOURCE (source));

	currently_remote_deletable =
		e_source_get_remote_deletable (E_SOURCE (source));

	if (remote_deletable == currently_remote_deletable)
		return;

	if (remote_deletable) {
		dbus_interface =
			e_dbus_source_remote_deletable_skeleton_new ();

		g_signal_connect (
			dbus_interface, "handle-delete",
			G_CALLBACK (server_side_source_remote_delete_cb),
			source);
	}

	dbus_object = e_source_ref_dbus_object (E_SOURCE (source));
	e_dbus_object_skeleton_set_source_remote_deletable (
		E_DBUS_OBJECT_SKELETON (dbus_object), dbus_interface);
	g_object_unref (dbus_object);

	if (dbus_interface != NULL)
		g_object_unref (dbus_interface);

	g_object_notify (G_OBJECT (source), "remote-deletable");
}

/**
 * e_server_side_source_ref_oauth2_support:
 * @source: an #EServerSideSource
 *
 * Returns the object implementing the #EOAuth2SupportInterface,
 * or %NULL if @source does not support OAuth 2.0 authentication.
 *
 * The returned #EOAuth2Support object is referenced for thread-safety.
 * Unreference the object with g_object_unref() when finished with it.
 *
 * Returns: an #EOAuth2Support object, or %NULL
 *
 * Since: 3.8
 **/
EOAuth2Support *
e_server_side_source_ref_oauth2_support (EServerSideSource *source)
{
	g_return_val_if_fail (E_IS_SERVER_SIDE_SOURCE (source), NULL);

	return g_weak_ref_get (&source->priv->oauth2_support);
}

/**
 * e_server_side_source_set_oauth2_support:
 * @source: an #EServerSideSource
 * @oauth2_support: an #EOAuth2Support object, or %NULL
 *
 * Indicates whether @source supports OAuth 2.0 authentication.
 *
 * If @oauth2_support is non-%NULL, the OAuth2Support D-Bus interface is
 * exported at the object path for @source.  If @oauth2_support is %NULL,
 * the OAuth2Support D-Bus interface is unexported at the object path for
 * @source, and any attempt by clients to call
 * e_source_get_oauth2_access_token() will fail.
 *
 * Requests for OAuth 2.0 access tokens are forwarded to @oauth2_support,
 * which implements the #EOAuth2SupportInterface.
 *
 * Since: 3.8
 **/
void
e_server_side_source_set_oauth2_support (EServerSideSource *source,
                                         EOAuth2Support *oauth2_support)
{
	EDBusSourceOAuth2Support *dbus_interface = NULL;
	GDBusObject *dbus_object;

	g_return_if_fail (E_IS_SERVER_SIDE_SOURCE (source));

	if (oauth2_support != NULL) {
		g_return_if_fail (E_IS_OAUTH2_SUPPORT (oauth2_support));

		dbus_interface =
			e_dbus_source_oauth2_support_skeleton_new ();

		g_signal_connect (
			dbus_interface, "handle-get-access-token",
			G_CALLBACK (server_side_source_get_access_token_cb),
			source);
	}

	g_weak_ref_set (&source->priv->oauth2_support, oauth2_support);

	dbus_object = e_source_ref_dbus_object (E_SOURCE (source));
	e_dbus_object_skeleton_set_source_oauth2_support (
		E_DBUS_OBJECT_SKELETON (dbus_object), dbus_interface);
	g_object_unref (dbus_object);

	if (dbus_interface != NULL)
		g_object_unref (dbus_interface);

	g_object_notify (G_OBJECT (source), "oauth2-support");
}
