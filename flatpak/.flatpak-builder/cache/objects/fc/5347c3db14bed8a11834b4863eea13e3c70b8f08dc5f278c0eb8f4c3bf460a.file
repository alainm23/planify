/*
 * e-backend.c
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
 * SECTION: e-backend
 * @include: libebackend/libebackend.h
 * @short_description: An abstract base class for backends
 *
 * An #EBackend is paired with an #ESource to facilitate performing
 * actions on the local or remote resource described by the #ESource.
 *
 * In other words, whereas a certain backend type knows how to talk to a
 * certain type of server or data store, the #ESource fills in configuration
 * details such as host name, user name, resource path, etc.
 *
 * All #EBackend instances are created by an #EBackendFactory.
 **/

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include <gio/gio.h>

#include <libedataserver/libedataserver.h>

#include "e-backend.h"
#include "e-user-prompter.h"

#define E_BACKEND_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_BACKEND, EBackendPrivate))

#define G_IS_IO_ERROR(error, code) \
	(g_error_matches ((error), G_IO_ERROR, (code)))

#define G_IS_RESOLVER_ERROR(error, code) \
	(g_error_matches ((error), G_RESOLVER_ERROR, (code)))

struct _EBackendPrivate {
	GMutex property_lock;
	ESource *source;
	EUserPrompter *prompter;
	GMainContext *main_context;
	GSocketConnectable *connectable;
	gboolean online;
	gboolean tried_with_empty_credentials;

	GNetworkMonitor *network_monitor;
	gulong network_changed_handler_id;

	GSource *update_online_state;
	GMutex update_online_state_lock;

	GMutex network_monitor_cancellable_lock;
	GCancellable *network_monitor_cancellable;

	GMutex authenticate_cancellable_lock;
	GCancellable *authenticate_cancellable;
};

enum {
	PROP_0,
	PROP_CONNECTABLE,
	PROP_MAIN_CONTEXT,
	PROP_ONLINE,
	PROP_SOURCE,
	PROP_USER_PROMPTER
};

G_DEFINE_ABSTRACT_TYPE (EBackend, e_backend, G_TYPE_OBJECT)

typedef struct _CanReachData {
	EBackend *backend;
	GCancellable *cancellable;
} CanReachData;

static void
backend_network_monitor_can_reach_cb (GObject *source_object,
                                      GAsyncResult *result,
                                      gpointer user_data)
{
	CanReachData *crd = user_data;
	gboolean host_is_reachable;
	GError *error = NULL;

	g_return_if_fail (crd != NULL);

	host_is_reachable = g_network_monitor_can_reach_finish (
		G_NETWORK_MONITOR (source_object), result, &error);

	/* Sanity check. */
	g_return_if_fail (
		(host_is_reachable && (error == NULL)) ||
		(!host_is_reachable && (error != NULL)));

	g_mutex_lock (&crd->backend->priv->network_monitor_cancellable_lock);
	if (crd->backend->priv->network_monitor_cancellable == crd->cancellable)
		g_clear_object (&crd->backend->priv->network_monitor_cancellable);
	g_mutex_unlock (&crd->backend->priv->network_monitor_cancellable_lock);

	if (G_IS_IO_ERROR (error, G_IO_ERROR_CANCELLED) ||
	    host_is_reachable == e_backend_get_online (crd->backend)) {
		g_clear_error (&error);
		g_object_unref (crd->backend);
		g_free (crd);
		return;
	}

	g_clear_error (&error);

	e_backend_set_online (crd->backend, host_is_reachable);

	if (!host_is_reachable) {
		ESource *source;

		source = e_backend_get_source (crd->backend);
		e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);
	}

	g_object_unref (crd->backend);
	g_free (crd);
}

static GSocketConnectable *
backend_ref_connectable_internal (EBackend *backend)
{
	GSocketConnectable *connectable;

	g_return_val_if_fail (E_IS_BACKEND (backend), NULL);

	connectable = e_backend_ref_connectable (backend);

	if (!connectable) {
		gchar *host = NULL;
		guint16 port = 0;

		if (e_backend_get_destination_address (backend, &host, &port) && host)
			connectable = g_network_address_new (host, port);

		g_free (host);
	}

	return connectable;
}

static gboolean
backend_update_online_state_timeout_cb (gpointer user_data)
{
	EBackend *backend;
	GSocketConnectable *connectable;
	GCancellable *cancellable;
	GSource *current_source;

	current_source = g_main_current_source ();
	if (current_source && g_source_is_destroyed (current_source))
		return FALSE;

	backend = g_weak_ref_get (user_data);
	if (!backend)
		return FALSE;

	connectable = backend_ref_connectable_internal (backend);

	g_mutex_lock (&backend->priv->update_online_state_lock);
	g_source_unref (backend->priv->update_online_state);
	backend->priv->update_online_state = NULL;
	g_mutex_unlock (&backend->priv->update_online_state_lock);

	g_mutex_lock (&backend->priv->network_monitor_cancellable_lock);

	cancellable = backend->priv->network_monitor_cancellable;
	backend->priv->network_monitor_cancellable = NULL;

	if (cancellable != NULL) {
		g_cancellable_cancel (cancellable);
		g_object_unref (cancellable);
		cancellable = NULL;
	}

	if (connectable == NULL) {
		backend->priv->network_monitor_cancellable = cancellable;
		g_mutex_unlock (&backend->priv->network_monitor_cancellable_lock);

		e_backend_set_online (backend, TRUE);
	} else {
		CanReachData *crd;

		cancellable = g_cancellable_new ();

		crd = g_new0 (CanReachData, 1);
		crd->backend = g_object_ref (backend);
		crd->cancellable = cancellable;

		g_network_monitor_can_reach_async (
			backend->priv->network_monitor,
			connectable, cancellable,
			backend_network_monitor_can_reach_cb,
			crd);

		backend->priv->network_monitor_cancellable = cancellable;
		g_mutex_unlock (&backend->priv->network_monitor_cancellable_lock);
	}

	g_clear_object (&connectable);
	g_clear_object (&backend);

	return FALSE;
}

static void
backend_update_online_state (EBackend *backend)
{
	GMainContext *main_context;
	GSource *timeout_source;

	g_mutex_lock (&backend->priv->update_online_state_lock);

	/* Reference the backend before destroying any already scheduled GSource,
	   in case the backend's last reference is held by that GSource. */
	g_object_ref (backend);

	if (backend->priv->update_online_state) {
		g_source_destroy (backend->priv->update_online_state);
		g_source_unref (backend->priv->update_online_state);
		backend->priv->update_online_state = NULL;
	}

	main_context = e_backend_ref_main_context (backend);

	timeout_source = g_timeout_source_new_seconds (5);
	g_source_set_priority (timeout_source, G_PRIORITY_LOW);
	g_source_set_callback (
		timeout_source,
		backend_update_online_state_timeout_cb,
		e_weak_ref_new (backend), (GDestroyNotify) e_weak_ref_free);
	g_source_attach (timeout_source, main_context);
	backend->priv->update_online_state =
		g_source_ref (timeout_source);
	g_source_unref (timeout_source);

	g_main_context_unref (main_context);

	g_mutex_unlock (&backend->priv->update_online_state_lock);

	g_object_unref (backend);
}

static void
backend_network_changed_cb (GNetworkMonitor *network_monitor,
                            gboolean network_available,
                            EBackend *backend)
{
	if (network_available) {
		backend_update_online_state (backend);
	} else {
		GSocketConnectable *connectable;

		connectable = backend_ref_connectable_internal (backend);
		e_backend_set_online (backend, !connectable);
		g_clear_object (&connectable);
	}
}

static ESourceAuthenticationResult
e_backend_authenticate_sync (EBackend *backend,
			     const ENamedParameters *credentials,
			     gchar **out_certificate_pem,
			     GTlsCertificateFlags *out_certificate_errors,
			     GCancellable *cancellable,
			     GError **error)
{
	EBackendClass *class;

	g_return_val_if_fail (E_IS_BACKEND (backend), E_SOURCE_AUTHENTICATION_ERROR);
	g_return_val_if_fail (credentials != NULL, E_SOURCE_AUTHENTICATION_ERROR);

	class = E_BACKEND_GET_CLASS (backend);
	g_return_val_if_fail (class != NULL, E_SOURCE_AUTHENTICATION_ERROR);
	g_return_val_if_fail (class->authenticate_sync != NULL, E_SOURCE_AUTHENTICATION_ERROR);

	return class->authenticate_sync (backend, credentials, out_certificate_pem, out_certificate_errors, cancellable, error);
}

typedef struct _AuthenticateThreadData {
	EBackend *backend;
	GCancellable *cancellable;
	ENamedParameters *credentials;
} AuthenticateThreadData;

static AuthenticateThreadData *
authenticate_thread_data_new (EBackend *backend,
			      GCancellable *cancellable,
			      const ENamedParameters *credentials)
{
	AuthenticateThreadData *data;

	data = g_new0 (AuthenticateThreadData, 1);
	data->backend = g_object_ref (backend);
	data->cancellable = g_object_ref (cancellable);
	data->credentials = credentials ? e_named_parameters_new_clone (credentials) : e_named_parameters_new ();

	return data;
}

static void
authenticate_thread_data_free (AuthenticateThreadData *data)
{
	if (data) {
		if (data->backend) {
			g_mutex_lock (&data->backend->priv->authenticate_cancellable_lock);
			if (data->backend->priv->authenticate_cancellable &&
			    data->backend->priv->authenticate_cancellable == data->cancellable) {
				g_clear_object (&data->backend->priv->authenticate_cancellable);
			}
			g_mutex_unlock (&data->backend->priv->authenticate_cancellable_lock);
		}

		g_clear_object (&data->backend);
		g_clear_object (&data->cancellable);
		e_named_parameters_free (data->credentials);
		g_free (data);
	}
}

static gpointer
backend_source_authenticate_thread (gpointer user_data)
{
	ESourceAuthenticationResult auth_result;
	AuthenticateThreadData *thread_data = user_data;
	gchar *certificate_pem = NULL;
	GTlsCertificateFlags certificate_errors = 0;
	gboolean empty_crendetials;
	GError *local_error = NULL;
	ESource *source;

	g_return_val_if_fail (thread_data != NULL, NULL);

	source = e_backend_get_source (thread_data->backend);

	e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_CONNECTING);

	/* Update the SSL trust transparently. */
	if (e_named_parameters_get (thread_data->credentials, E_SOURCE_CREDENTIAL_SSL_TRUST) &&
	    e_source_has_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND)) {
		ESourceWebdav *webdav_extension;

		webdav_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
		e_source_webdav_set_ssl_trust (webdav_extension,
			e_named_parameters_get (thread_data->credentials, E_SOURCE_CREDENTIAL_SSL_TRUST));
	}

	auth_result = e_backend_authenticate_sync (thread_data->backend, thread_data->credentials,
		&certificate_pem, &certificate_errors, thread_data->cancellable, &local_error);

	empty_crendetials = auth_result == E_SOURCE_AUTHENTICATION_REQUIRED &&
		(!thread_data->credentials || !e_named_parameters_count (thread_data->credentials)) &&
		!g_cancellable_is_cancelled (thread_data->cancellable);

	if (empty_crendetials && thread_data->backend->priv->tried_with_empty_credentials) {
		/* When tried repeatedly with empty credentials and both resulted in 'REQUIRED',
		   then change it to 'REJECTED' to avoid loop. */
		auth_result = E_SOURCE_AUTHENTICATION_REJECTED;
	}

	thread_data->backend->priv->tried_with_empty_credentials = empty_crendetials;

	if (!g_cancellable_is_cancelled (thread_data->cancellable)) {
		ESourceCredentialsReason reason = E_SOURCE_CREDENTIALS_REASON_ERROR;

		switch (auth_result) {
		case E_SOURCE_AUTHENTICATION_UNKNOWN:
		case E_SOURCE_AUTHENTICATION_ERROR:
			reason = E_SOURCE_CREDENTIALS_REASON_ERROR;
			break;
		case E_SOURCE_AUTHENTICATION_ERROR_SSL_FAILED:
			reason = E_SOURCE_CREDENTIALS_REASON_SSL_FAILED;
			break;
		case E_SOURCE_AUTHENTICATION_ACCEPTED:
			e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_CONNECTED);
			break;
		case E_SOURCE_AUTHENTICATION_REQUIRED:
			reason = E_SOURCE_CREDENTIALS_REASON_REQUIRED;
			break;
		case E_SOURCE_AUTHENTICATION_REJECTED:
			reason = E_SOURCE_CREDENTIALS_REASON_REJECTED;
			break;
		}

		if (auth_result == E_SOURCE_AUTHENTICATION_ACCEPTED) {
			const gchar *username = e_named_parameters_get (thread_data->credentials, E_SOURCE_CREDENTIAL_USERNAME);
			gboolean call_write = FALSE;

			if (username && *username && e_source_has_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
				ESourceAuthentication *extension_authentication = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);

				if (g_strcmp0 (username, e_source_authentication_get_user (extension_authentication)) != 0) {
					e_source_authentication_set_user (extension_authentication, username);
					call_write = TRUE;
				}
			}

			if (username && *username && e_source_has_extension (source, E_SOURCE_EXTENSION_COLLECTION)) {
				ESourceCollection *extension_collection = e_source_get_extension (source, E_SOURCE_EXTENSION_COLLECTION);

				if (g_strcmp0 (username, e_source_collection_get_identity (extension_collection)) != 0) {
					e_source_collection_set_identity (extension_collection, username);
					call_write = TRUE;
				}
			}

			if (call_write) {
				GError *local_error2 = NULL;

				if (!e_source_write_sync (source, thread_data->cancellable, &local_error2)) {
					g_warning ("%s: Failed to store changed user name: %s", G_STRFUNC, local_error2 ? local_error2->message : "Unknown error");
				}

				g_clear_error (&local_error2);
			}
		} else {
			GError *local_error2 = NULL;

			e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);

			if (!e_source_invoke_credentials_required_sync (source, reason, certificate_pem, certificate_errors,
				local_error, thread_data->cancellable, &local_error2)) {
				g_warning ("%s: Failed to invoke credentials required: %s", G_STRFUNC, local_error2 ? local_error2->message : "Unknown error");
			}

			g_clear_error (&local_error2);
		}
	} else {
		e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);
	}

	g_free (certificate_pem);
	g_clear_error (&local_error);

	authenticate_thread_data_free (thread_data);

	return NULL;
}

static void
backend_source_authenticate_cb (ESource *source,
				const ENamedParameters *credentials,
				EBackend *backend)
{
	g_return_if_fail (E_IS_BACKEND (backend));
	g_return_if_fail (credentials != NULL);

	e_backend_schedule_authenticate	(backend, credentials);
}

static void
backend_source_unset_last_credentials_required_arguments_cb (GObject *source_object,
							     GAsyncResult *result,
							     gpointer user_data)
{
	GError *local_error = NULL;

	g_return_if_fail (E_IS_SOURCE (source_object));

	e_source_unset_last_credentials_required_arguments_finish (E_SOURCE (source_object), result, &local_error);

	if (local_error)
		g_debug ("%s: Call failed: %s", G_STRFUNC, local_error->message);

	g_clear_error (&local_error);
}

static void
backend_set_source (EBackend *backend,
                    ESource *source)
{
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (backend->priv->source == NULL);

	backend->priv->source = g_object_ref (source);

	g_signal_connect (backend->priv->source, "authenticate", G_CALLBACK (backend_source_authenticate_cb), backend);
}

static void
backend_set_property (GObject *object,
                      guint property_id,
                      const GValue *value,
                      GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONNECTABLE:
			e_backend_set_connectable (
				E_BACKEND (object),
				g_value_get_object (value));
			return;

		case PROP_ONLINE:
			e_backend_set_online (
				E_BACKEND (object),
				g_value_get_boolean (value));
			return;

		case PROP_SOURCE:
			backend_set_source (
				E_BACKEND (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
backend_get_property (GObject *object,
                      guint property_id,
                      GValue *value,
                      GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONNECTABLE:
			g_value_take_object (
				value, e_backend_ref_connectable (
				E_BACKEND (object)));
			return;

		case PROP_MAIN_CONTEXT:
			g_value_take_boxed (
				value, e_backend_ref_main_context (
				E_BACKEND (object)));
			return;

		case PROP_ONLINE:
			g_value_set_boolean (
				value, e_backend_get_online (
				E_BACKEND (object)));
			return;

		case PROP_SOURCE:
			g_value_set_object (
				value, e_backend_get_source (
				E_BACKEND (object)));
			return;

		case PROP_USER_PROMPTER:
			g_value_set_object (
				value, e_backend_get_user_prompter (
				E_BACKEND (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
backend_dispose (GObject *object)
{
	EBackendPrivate *priv;

	priv = E_BACKEND_GET_PRIVATE (object);

	if (priv->network_changed_handler_id > 0) {
		g_signal_handler_disconnect (
			priv->network_monitor,
			priv->network_changed_handler_id);
		priv->network_changed_handler_id = 0;
	}

	if (priv->main_context != NULL) {
		g_main_context_unref (priv->main_context);
		priv->main_context = NULL;
	}

	if (priv->update_online_state != NULL) {
		g_source_destroy (priv->update_online_state);
		g_source_unref (priv->update_online_state);
		priv->update_online_state = NULL;
	}

	if (priv->source) {
		g_signal_handlers_disconnect_by_func (priv->source, backend_source_authenticate_cb, object);
		e_source_set_connection_status (priv->source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);
		e_source_unset_last_credentials_required_arguments (priv->source, NULL,
			backend_source_unset_last_credentials_required_arguments_cb, NULL);
	}

	g_mutex_lock (&priv->authenticate_cancellable_lock);
	if (priv->authenticate_cancellable) {
		g_cancellable_cancel (priv->authenticate_cancellable);
		g_clear_object (&priv->authenticate_cancellable);
	}
	g_mutex_unlock (&priv->authenticate_cancellable_lock);

	g_clear_object (&priv->source);
	g_clear_object (&priv->prompter);
	g_clear_object (&priv->connectable);
	g_clear_object (&priv->network_monitor);
	g_clear_object (&priv->network_monitor_cancellable);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_backend_parent_class)->dispose (object);
}

static void
backend_finalize (GObject *object)
{
	EBackendPrivate *priv;

	priv = E_BACKEND_GET_PRIVATE (object);

	g_mutex_clear (&priv->property_lock);
	g_mutex_clear (&priv->update_online_state_lock);
	g_mutex_clear (&priv->network_monitor_cancellable_lock);
	g_mutex_clear (&priv->authenticate_cancellable_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_backend_parent_class)->finalize (object);
}

static void
backend_constructed (GObject *object)
{
	EBackend *backend;
	ESource *source;
	const gchar *extension_name;

	backend = E_BACKEND (object);

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_backend_parent_class)->constructed (object);

	/* Get an initial GSocketConnectable from the data
	 * source's [Authentication] extension, if present. */
	source = e_backend_get_source (backend);
	extension_name = E_SOURCE_EXTENSION_AUTHENTICATION;
	if (e_source_has_extension (source, extension_name)) {
		ESourceAuthentication *extension;

		extension = e_source_get_extension (source, extension_name);

		backend->priv->connectable =
			e_source_authentication_ref_connectable (extension);

		backend_update_online_state (backend);
	}
}

static ESourceAuthenticationResult
backend_authenticate_sync (EBackend *backend,
			   const ENamedParameters *credentials,
			   gchar **out_certificate_pem,
			   GTlsCertificateFlags *out_certificate_errors,
			   GCancellable *cancellable,
			   GError **error)
{
	/* The default implementation just reports success, it's for backends
	   which do not use (nor define) authentication routines, because
	   they use different methods to get to the credentials. */

	return E_SOURCE_AUTHENTICATION_ACCEPTED;
}

static gboolean
backend_get_destination_address (EBackend *backend,
                                 gchar **host,
                                 guint16 *port)
{
	GSocketConnectable *connectable;
	GNetworkAddress *address;

	g_return_val_if_fail (E_IS_BACKEND (backend), FALSE);
	g_return_val_if_fail (host != NULL, FALSE);
	g_return_val_if_fail (port != NULL, FALSE);

	connectable = e_backend_ref_connectable (backend);
	if (!connectable)
		return FALSE;

	if (!G_IS_NETWORK_ADDRESS (connectable)) {
		g_object_unref (connectable);
		return FALSE;
	}

	address = G_NETWORK_ADDRESS (connectable);

	*host = g_strdup (g_network_address_get_hostname (address));
	*port = g_network_address_get_port (address);

	g_object_unref (connectable);

	return *host != NULL;
}

static void
backend_prepare_shutdown (EBackend *backend)
{
}

static void
e_backend_class_init (EBackendClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EBackendPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = backend_set_property;
	object_class->get_property = backend_get_property;
	object_class->dispose = backend_dispose;
	object_class->finalize = backend_finalize;
	object_class->constructed = backend_constructed;

	class->authenticate_sync = backend_authenticate_sync;
	class->get_destination_address = backend_get_destination_address;
	class->prepare_shutdown = backend_prepare_shutdown;

	g_object_class_install_property (
		object_class,
		PROP_CONNECTABLE,
		g_param_spec_object (
			"connectable",
			"Connectable",
			"Socket endpoint of a network service",
			G_TYPE_SOCKET_CONNECTABLE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_MAIN_CONTEXT,
		g_param_spec_boxed (
			"main-context",
			"Main Context",
			"The main loop context on "
			"which to attach event sources",
			G_TYPE_MAIN_CONTEXT,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_ONLINE,
		g_param_spec_boolean (
			"online",
			"Online",
			"Whether the backend is online",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_SOURCE,
		g_param_spec_object (
			"source",
			"Source",
			"The data source being acted upon",
			E_TYPE_SOURCE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_USER_PROMPTER,
		g_param_spec_object (
			"user-prompter",
			"User Prompter",
			"User prompter instance",
			E_TYPE_USER_PROMPTER,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));
}

static void
e_backend_init (EBackend *backend)
{
	GNetworkMonitor *network_monitor;
	gulong handler_id;

	backend->priv = E_BACKEND_GET_PRIVATE (backend);
	backend->priv->prompter = e_user_prompter_new ();
	backend->priv->main_context = g_main_context_ref_thread_default ();
	backend->priv->tried_with_empty_credentials = FALSE;

	g_mutex_init (&backend->priv->property_lock);
	g_mutex_init (&backend->priv->update_online_state_lock);
	g_mutex_init (&backend->priv->network_monitor_cancellable_lock);
	g_mutex_init (&backend->priv->authenticate_cancellable_lock);

	backend->priv->authenticate_cancellable = NULL;

	/* Configure network monitoring. */

	network_monitor = e_network_monitor_get_default ();
	backend->priv->network_monitor = g_object_ref (network_monitor);
	backend->priv->online = g_network_monitor_get_network_available (network_monitor);

	handler_id = g_signal_connect (
		backend->priv->network_monitor, "network-changed",
		G_CALLBACK (backend_network_changed_cb), backend);
	backend->priv->network_changed_handler_id = handler_id;
}

/**
 * e_backend_get_online:
 * @backend: an #EBackend
 *
 * Returns the online state of @backend: %TRUE if @backend is online,
 * %FALSE if offline.
 *
 * If the #EBackend:connectable property is non-%NULL, the @backend will
 * automatically determine whether the network service should be reachable,
 * and hence whether the @backend is #EBackend:online.  But subclasses may
 * override the online state if, for example, a connection attempt fails.
 *
 * Returns: the online state
 *
 * Since: 3.4
 **/
gboolean
e_backend_get_online (EBackend *backend)
{
	g_return_val_if_fail (E_IS_BACKEND (backend), FALSE);

	return backend->priv->online;
}

/**
 * e_backend_set_online:
 * @backend: an #EBackend
 * @online: the online state
 *
 * Sets the online state of @backend: %TRUE if @backend is online,
 * @FALSE if offline.
 *
 * If the #EBackend:connectable property is non-%NULL, the @backend will
 * automatically determine whether the network service should be reachable,
 * and hence whether the @backend is #EBackend:online.  But subclasses may
 * override the online state if, for example, a connection attempt fails.
 *
 * Since: 3.4
 **/
void
e_backend_set_online (EBackend *backend,
                      gboolean online)
{
	g_return_if_fail (E_IS_BACKEND (backend));

	/* Avoid unnecessary "notify" signals. */
	if (backend->priv->online == online)
		return;

	backend->priv->online = online;

	/* Cancel any automatic "online" state update in progress. */
	g_mutex_lock (&backend->priv->network_monitor_cancellable_lock);
	g_cancellable_cancel (backend->priv->network_monitor_cancellable);
	g_mutex_unlock (&backend->priv->network_monitor_cancellable_lock);

	g_object_notify (G_OBJECT (backend), "online");

	if (!backend->priv->online && backend->priv->source)
		e_source_set_connection_status (backend->priv->source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);
}

/**
 * e_backend_ensure_online_state_updated:
 * @backend: an #EBackend
 * @cancellable: optional #GCancellable object, or %NULL
 *
 * Makes sure that the "online" property is updated, that is, if there
 * is any destination reachability test pending, it'll be done immediately
 * and the only state will be updated as well.
 *
 * Since: 3.18
 **/
void
e_backend_ensure_online_state_updated (EBackend *backend,
				       GCancellable *cancellable)
{
	gboolean needs_update = FALSE;

	g_return_if_fail (E_IS_BACKEND (backend));

	g_object_ref (backend);

	g_mutex_lock (&backend->priv->update_online_state_lock);

	if (backend->priv->update_online_state) {
		g_source_destroy (backend->priv->update_online_state);
		g_source_unref (backend->priv->update_online_state);
		backend->priv->update_online_state = NULL;

		needs_update = TRUE;
	}

	g_mutex_unlock (&backend->priv->update_online_state_lock);

	if (!needs_update) {
		g_mutex_lock (&backend->priv->network_monitor_cancellable_lock);
		needs_update = backend->priv->network_monitor_cancellable != NULL;
		g_mutex_unlock (&backend->priv->network_monitor_cancellable_lock);
	}

	if (needs_update)
		e_backend_set_online (backend, e_backend_is_destination_reachable (backend, cancellable, NULL));

	g_object_unref (backend);
}

/**
 * e_backend_get_source:
 * @backend: an #EBackend
 *
 * Returns the #ESource to which @backend is paired.
 *
 * Returns: the #ESource to which @backend is paired
 *
 * Since: 3.4
 **/
ESource *
e_backend_get_source (EBackend *backend)
{
	g_return_val_if_fail (E_IS_BACKEND (backend), NULL);

	return backend->priv->source;
}

/**
 * e_backend_ref_connectable:
 * @backend: an #EBackend
 *
 * Returns the socket endpoint for the network service to which @backend
 * is a client, or %NULL if @backend does not use network sockets.
 *
 * The initial value of the #EBackend:connectable property is derived from
 * the #ESourceAuthentication extension of the @backend's #EBackend:source
 * property, if the extension is present.
 *
 * The returned #GSocketConnectable is referenced for thread-safety and
 * must be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #GSocketConnectable, or %NULL
 *
 * Since: 3.8
 **/
GSocketConnectable *
e_backend_ref_connectable (EBackend *backend)
{
	GSocketConnectable *connectable = NULL;

	g_return_val_if_fail (E_IS_BACKEND (backend), NULL);

	g_mutex_lock (&backend->priv->property_lock);

	if (backend->priv->connectable != NULL)
		connectable = g_object_ref (backend->priv->connectable);

	g_mutex_unlock (&backend->priv->property_lock);

	return connectable;
}

/**
 * e_backend_set_connectable:
 * @backend: an #EBackend
 * @connectable: a #GSocketConnectable, or %NULL
 *
 * Sets the socket endpoint for the network service to which @backend is
 * a client.  This can be %NULL if @backend does not use network sockets.
 *
 * The initial value of the #EBackend:connectable property is derived from
 * the #ESourceAuthentication extension of the @backend's #EBackend:source
 * property, if the extension is present.
 *
 * Since: 3.8
 **/
void
e_backend_set_connectable (EBackend *backend,
                           GSocketConnectable *connectable)
{
	g_return_if_fail (E_IS_BACKEND (backend));

	if (connectable != NULL) {
		g_return_if_fail (G_IS_SOCKET_CONNECTABLE (connectable));
		g_object_ref (connectable);
	}

	g_mutex_lock (&backend->priv->property_lock);

	if (backend->priv->connectable != NULL)
		g_object_unref (backend->priv->connectable);

	backend->priv->connectable = connectable;

	g_mutex_unlock (&backend->priv->property_lock);

	backend_update_online_state (backend);

	g_object_notify (G_OBJECT (backend), "connectable");
}

/**
 * e_backend_ref_main_context:
 * @backend: an #EBackend
 *
 * Returns the #GMainContext on which event sources for @backend are to
 * be attached.
 *
 * The returned #GMainContext is referenced for thread-safety and must be
 * unreferenced with g_main_context_unref() when finished with it.
 *
 * Returns: (transfer full): a #GMainContext
 *
 * Since: 3.8
 **/
GMainContext *
e_backend_ref_main_context (EBackend *backend)
{
	g_return_val_if_fail (E_IS_BACKEND (backend), NULL);

	return g_main_context_ref (backend->priv->main_context);
}

/**
 * e_backend_credentials_required_sync:
 * @backend: an #EBackend
 * @reason: an #ESourceCredentialsReason, why the credentials are required
 * @certificate_pem: PEM-encoded secure connection certificate, or an empty string
 * @certificate_errors: a bit-or of #GTlsCertificateFlags for secure connection certificate
 * @op_error: (allow-none): a #GError with a description of the previous credentials error, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Synchronously lets the clients know that the backned requires credentials to be
 * properly opened. It's a proxy function for e_source_invoke_credentials_required_sync(),
 * where can be found more information about actual parameters meaning.
 *
 * The provided credentials are received through #EBackendClass.authenticate_sync()
 * method asynchronously.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_backend_credentials_required_sync (EBackend *backend,
				     ESourceCredentialsReason reason,
				     const gchar *certificate_pem,
				     GTlsCertificateFlags certificate_errors,
				     const GError *op_error,
				     GCancellable *cancellable,
				     GError **error)
{
	ESource *source;

	g_return_val_if_fail (E_IS_BACKEND (backend), FALSE);

	source = e_backend_get_source (backend);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	return e_source_invoke_credentials_required_sync (source,
		reason, certificate_pem, certificate_errors, op_error, cancellable, error);
}

typedef struct _CredentialsRequiredData {
	ESourceCredentialsReason reason;
	gchar *certificate_pem;
	GTlsCertificateFlags certificate_errors;
	GError *op_error;
} CredentialsRequiredData;

static void
credentials_required_data_free (gpointer ptr)
{
	CredentialsRequiredData *data = ptr;

	if (data) {
		g_free (data->certificate_pem);
		g_clear_error (&data->op_error);
		g_free (data);
	}
}

static void
backend_credentials_required_thread (GTask *task,
				     gpointer source_object,
				     gpointer task_data,
				     GCancellable *cancellable)
{
	CredentialsRequiredData *data = task_data;
	gboolean success;
	GError *local_error = NULL;

	success = e_backend_credentials_required_sync (
		E_BACKEND (source_object), data->reason, data->certificate_pem,
		data->certificate_errors, data->op_error,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * e_backend_credentials_required:
 * @backend: an #EBackend
 * @reason: an #ESourceCredentialsReason, why the credentials are required
 * @certificate_pem: PEM-encoded secure connection certificate, or an empty string
 * @certificate_errors: a bit-or of #GTlsCertificateFlags for secure connection certificate
 * @op_error: (allow-none): a #GError with a description of the previous credentials error, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: (closure user_data) (scope async): a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously calls the e_backend_credentials_required_sync() on the @backend,
 * to inform clients that credentials are required.
 *
 * When the operation is finished, @callback will be called. You can then
 * call e_backend_credentials_required_finish() to get the result of the operation.
 *
 * Since: 3.16
 **/
void
e_backend_credentials_required (EBackend *backend,
				ESourceCredentialsReason reason,
				const gchar *certificate_pem,
				GTlsCertificateFlags certificate_errors,
				const GError *op_error,
				GCancellable *cancellable,
				GAsyncReadyCallback callback,
				gpointer user_data)
{
	CredentialsRequiredData *data;
	GTask *task;

	g_return_if_fail (E_IS_BACKEND (backend));

	data = g_new0 (CredentialsRequiredData, 1);
	data->reason = reason;
	data->certificate_pem = g_strdup (certificate_pem);
	data->certificate_errors = certificate_errors;
	data->op_error = op_error ? g_error_copy (op_error) : NULL;

	task = g_task_new (backend, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_backend_credentials_required);
	g_task_set_task_data (task, data, credentials_required_data_free);

	g_task_run_in_thread (task, backend_credentials_required_thread);

	g_object_unref (task);
}

/**
 * e_backend_credentials_required_finish:
 * @backend: an #EBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_backend_credentials_required().
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_backend_credentials_required_finish (EBackend *backend,
				       GAsyncResult *result,
				       GError **error)
{
	g_return_val_if_fail (E_IS_BACKEND (backend), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, backend), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_backend_credentials_required), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

static void
backend_scheduled_credentials_required_done_cb (GObject *source_object,
						GAsyncResult *result,
						gpointer user_data)
{
	GError *error = NULL;
	gchar *who_calls = user_data;

	g_return_if_fail (E_IS_BACKEND (source_object));

	if (!e_backend_credentials_required_finish (E_BACKEND (source_object), result, &error) &&
	    !g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
		g_warning ("%s: Failed to invoke credentials required: %s", who_calls ? who_calls : G_STRFUNC,
			error ? error->message : "Unknown error");
	}

	g_clear_error (&error);
	g_free (who_calls);
}

/**
 * e_backend_schedule_credentials_required:
 * @backend: an #EBackend
 * @reason: an #ESourceCredentialsReason, why the credentials are required
 * @certificate_pem: PEM-encoded secure connection certificate, or an empty string
 * @certificate_errors: a bit-or of #GTlsCertificateFlags for secure connection certificate
 * @op_error: (allow-none): a #GError with a description of the previous credentials error, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @who_calls: (allow-none): an identification who calls this
 *
 * Asynchronously invokes e_backend_credentials_required(), but installs its
 * own callback which only prints a runtime warning on the console when
 * the call fails. The @who_calls is a prefix of the console message.
 * This is useful when the caller just wants to start the operation
 * without having actual place where to show the operation result.
 *
 * Since: 3.16
 **/
void
e_backend_schedule_credentials_required (EBackend *backend,
					 ESourceCredentialsReason reason,
					 const gchar *certificate_pem,
					 GTlsCertificateFlags certificate_errors,
					 const GError *op_error,
					 GCancellable *cancellable,
					 const gchar *who_calls)
{
	g_return_if_fail (E_IS_BACKEND (backend));

	e_backend_credentials_required (backend, reason, certificate_pem, certificate_errors,
		op_error, cancellable, backend_scheduled_credentials_required_done_cb, g_strdup (who_calls));
}

/**
 * e_backend_schedule_authenticate:
 * @backend: an #EBackend
 * @credentials: (allow-none): a credentials to use to authenticate, or %NULL
 *
 * Schedules a new authenticate session, cancelling any previously run.
 * This is usually done automatically, when an 'authenticate' signal is
 * received for the associated #ESource. With %NULL @credentials an attempt
 * without it is run.
 *
 * Since: 3.16
 **/
void
e_backend_schedule_authenticate	(EBackend *backend,
				 const ENamedParameters *credentials)
{
	GCancellable *cancellable;
	AuthenticateThreadData *thread_data;

	g_return_if_fail (E_IS_BACKEND (backend));

	g_mutex_lock (&backend->priv->authenticate_cancellable_lock);
	if (backend->priv->authenticate_cancellable) {
		g_cancellable_cancel (backend->priv->authenticate_cancellable);
		g_clear_object (&backend->priv->authenticate_cancellable);
	}

	backend->priv->authenticate_cancellable = g_cancellable_new ();
	cancellable = g_object_ref (backend->priv->authenticate_cancellable);

	g_mutex_unlock (&backend->priv->authenticate_cancellable_lock);

	thread_data = authenticate_thread_data_new (backend, cancellable, credentials);

	g_thread_unref (g_thread_new (NULL, backend_source_authenticate_thread, thread_data));

	g_clear_object (&cancellable);
}

/**
 * e_backend_ensure_source_status_connected:
 * @backend: an #EBackend
 *
 * Makes sure that the associated ESource::connection-status is connected. This is
 * useful in cases when the backend can connect to the destination without invoking
 * #EBackendClass.authenticate_sync(), possibly through e_backend_schedule_authenticate().
 *
 * Since: 3.18
 **/
void
e_backend_ensure_source_status_connected (EBackend *backend)
{
	ESource *source;

	g_return_if_fail (E_IS_BACKEND (backend));

	source = e_backend_get_source (backend);

	g_return_if_fail (E_IS_SOURCE (source));

	if (e_source_get_connection_status (source) != E_SOURCE_CONNECTION_STATUS_CONNECTED)
		e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_CONNECTED);
}

/**
 * e_backend_get_user_prompter:
 * @backend: an #EBackend
 *
 * Gets an instance of #EUserPrompter, associated with this @backend.
 *
 * The returned instance is owned by the @backend.
 *
 * Returns: (transfer none): an #EUserPrompter instance
 *
 * Since: 3.8
 **/
EUserPrompter *
e_backend_get_user_prompter (EBackend *backend)
{
	g_return_val_if_fail (E_IS_BACKEND (backend), NULL);

	return backend->priv->prompter;
}

/**
 * e_backend_trust_prompt_sync:
 * @backend: an #EBackend
 * @parameters: an #ENamedParameters with values for the trust prompt
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Asks a user a trust prompt with given @parameters, and returns what
 * user responded. This blocks until the response is delivered.
 *
 * Returns: an #ETrustPromptResponse what user responded
 *
 * Note: The function can return also %E_TRUST_PROMPT_RESPONSE_UNKNOWN,
 *    it's on error or if user closes the trust prompt dialog with other
 *    than the offered buttons. Usual behaviour in such case is to treat
 *    it as a temporary reject.
 *
 * Since: 3.8
 **/
ETrustPromptResponse
e_backend_trust_prompt_sync (EBackend *backend,
                             const ENamedParameters *parameters,
                             GCancellable *cancellable,
                             GError **error)
{
	EUserPrompter *prompter;
	gint response;

	g_return_val_if_fail (
		E_IS_BACKEND (backend), E_TRUST_PROMPT_RESPONSE_UNKNOWN);
	g_return_val_if_fail (
		parameters != NULL, E_TRUST_PROMPT_RESPONSE_UNKNOWN);

	prompter = e_backend_get_user_prompter (backend);
	g_return_val_if_fail (
		prompter != NULL, E_TRUST_PROMPT_RESPONSE_UNKNOWN);

	response = e_user_prompter_extension_prompt_sync (
		prompter, "ETrustPrompt::trust-prompt",
		parameters, NULL, cancellable, error);

	if (response == 0)
		return E_TRUST_PROMPT_RESPONSE_REJECT;
	if (response == 1)
		return E_TRUST_PROMPT_RESPONSE_ACCEPT;
	if (response == 2)
		return E_TRUST_PROMPT_RESPONSE_ACCEPT_TEMPORARILY;
	if (response == -1)
		return E_TRUST_PROMPT_RESPONSE_REJECT_TEMPORARILY;

	return E_TRUST_PROMPT_RESPONSE_UNKNOWN;
}

/**
 * e_backend_trust_prompt:
 * @backend: an #EBackend
 * @parameters: an #ENamedParameters with values for the trust prompt
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (closure user_data) (scope async): a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Initiates a user trust prompt with given @parameters.
 *
 * When the operation is finished, @callback will be called. You can then
 * call e_backend_trust_prompt_finish() to get the result of the operation.
 *
 * Since: 3.8
 **/
void
e_backend_trust_prompt (EBackend *backend,
                        const ENamedParameters *parameters,
                        GCancellable *cancellable,
                        GAsyncReadyCallback callback,
                        gpointer user_data)
{
	EUserPrompter *prompter;

	g_return_if_fail (E_IS_BACKEND (backend));
	g_return_if_fail (parameters != NULL);

	prompter = e_backend_get_user_prompter (backend);
	g_return_if_fail (prompter != NULL);

	e_user_prompter_extension_prompt (
		prompter, "ETrustPrompt::trust-prompt",
		parameters, cancellable, callback, user_data);
}

/**
 * e_backend_trust_prompt_finish:
 * @backend: an #EBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_backend_trust_prompt().
 * If an error occurred, the function will set @error and return
 * %E_TRUST_PROMPT_RESPONSE_UNKNOWN.
 *
 * Returns: an #ETrustPromptResponse what user responded
 *
 * Note: The function can return also %E_TRUST_PROMPT_RESPONSE_UNKNOWN,
 *    it's on error or if user closes the trust prompt dialog with other
 *    than the offered buttons. Usual behaviour in such case is to treat
 *    it as a temporary reject.
 *
 * Since: 3.8
 **/
ETrustPromptResponse
e_backend_trust_prompt_finish (EBackend *backend,
                               GAsyncResult *result,
                               GError **error)
{
	EUserPrompter *prompter;
	gint response;

	g_return_val_if_fail (
		E_IS_BACKEND (backend), E_TRUST_PROMPT_RESPONSE_UNKNOWN);

	prompter = e_backend_get_user_prompter (backend);
	g_return_val_if_fail (
		prompter != NULL, E_TRUST_PROMPT_RESPONSE_UNKNOWN);

	response = e_user_prompter_extension_prompt_finish (
		prompter, result, NULL, error);

	if (response == 0)
		return E_TRUST_PROMPT_RESPONSE_REJECT;
	if (response == 1)
		return E_TRUST_PROMPT_RESPONSE_ACCEPT;
	if (response == 2)
		return E_TRUST_PROMPT_RESPONSE_ACCEPT_TEMPORARILY;
	if (response == -1)
		return E_TRUST_PROMPT_RESPONSE_REJECT_TEMPORARILY;

	return E_TRUST_PROMPT_RESPONSE_UNKNOWN;
}

/**
 * e_backend_get_destination_address:
 * @backend: an #EBackend instance
 * @host: (out): destination server host name
 * @port: (out): destination server port
 *
 * Provides destination server host name and port to which
 * the backend connects. This is used to determine required
 * connection point for e_backend_is_destination_reachable().
 * The @host is a newly allocated string, which will be freed
 * with g_free(). When @backend sets both @host and @port, then
 * it should return %TRUE, indicating it's a remote backend.
 * Default implementation returns %FALSE, which is treated
 * like the backend is local, no checking for server reachability
 * is possible.
 *
 * Returns: %TRUE, when it's a remote backend and provides both
 *   @host and @port; %FALSE otherwise.
 *
 * Since: 3.8
 **/
gboolean
e_backend_get_destination_address (EBackend *backend,
                                   gchar **host,
                                   guint16 *port)
{
	EBackendClass *klass;

	g_return_val_if_fail (E_IS_BACKEND (backend), FALSE);
	g_return_val_if_fail (host != NULL, FALSE);
	g_return_val_if_fail (port != NULL, FALSE);

	klass = E_BACKEND_GET_CLASS (backend);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->get_destination_address != NULL, FALSE);

	return klass->get_destination_address (backend, host, port);
}

/**
 * e_backend_is_destination_reachable:
 * @backend: an #EBackend instance
 * @cancellable: a #GCancellable instance, or %NULL
 * @error: a #GError for errors, or %NULL
 *
 * Checks whether the @backend<!-- -->'s destination server, as returned
 * by e_backend_get_destination_address(), is reachable.
 * If the e_backend_get_destination_address() returns %FALSE, this function
 * returns %TRUE, meaning the destination is always reachable.
 * This uses #GNetworkMonitor<!-- -->'s g_network_monitor_can_reach()
 * for reachability tests.
 *
 * Returns: %TRUE, when destination server address is reachable or
 *    the backend doesn't provide destination address; %FALSE if
 *    the backend destination server cannot be reached currently.
 *
 * Since: 3.8
 **/
gboolean
e_backend_is_destination_reachable (EBackend *backend,
                                    GCancellable *cancellable,
                                    GError **error)
{
	gboolean reachable = TRUE;
	gchar *host = NULL;
	guint16 port = 0;

	g_return_val_if_fail (E_IS_BACKEND (backend), FALSE);

	if (e_backend_get_destination_address (backend, &host, &port)) {
		g_warn_if_fail (host != NULL);

		if (host) {
			GNetworkMonitor *network_monitor;
			GSocketConnectable *connectable;

			network_monitor = backend->priv->network_monitor;

			connectable = g_network_address_new (host, port);
			if (connectable) {
				reachable = g_network_monitor_can_reach (
					network_monitor, connectable,
					cancellable, error);
				g_object_unref (connectable);
			} else {
				reachable = FALSE;
			}
		}
	}

	g_free (host);

	return reachable;
}

/**
 * e_backend_prepare_shutdown:
 * @backend: an #EBackend instance
 *
 * Let's the @backend know that it'll be shut down shortly, no client connects
 * to it anymore. The @backend can free any resources which reference it, for
 * example the opened views.
 *
 * Since: 3.16
 */
void
e_backend_prepare_shutdown (EBackend *backend)
{
	EBackendClass *class;

	g_return_if_fail (E_IS_BACKEND (backend));

	class = E_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->prepare_shutdown != NULL);

	g_object_ref (backend);

	class->prepare_shutdown (backend);

	g_object_unref (backend);
}
