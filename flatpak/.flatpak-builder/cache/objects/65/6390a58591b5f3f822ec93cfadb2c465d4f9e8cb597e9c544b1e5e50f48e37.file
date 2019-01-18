/*
 * camel-network-service.c
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

#include "camel-network-service.h"

#include <errno.h>
#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include "camel.h"
#include <camel/camel-enumtypes.h>
#include <camel/camel-network-settings.h>
#include <camel/camel-service.h>
#include <camel/camel-session.h>

#define PRIVATE_KEY "CamelNetworkService:private"

#define CAMEL_NETWORK_SERVICE_GET_PRIVATE(obj) \
	(g_object_get_data (G_OBJECT (obj), PRIVATE_KEY))

#define G_IS_IO_ERROR(error, code) \
	(g_error_matches ((error), G_IO_ERROR, (code)))

#define G_IS_RESOLVER_ERROR(error, code) \
	(g_error_matches ((error), G_RESOLVER_ERROR, (code)))

typedef struct _CamelNetworkServicePrivate CamelNetworkServicePrivate;

struct _CamelNetworkServicePrivate {
	GMutex property_lock;
	GSocketConnectable *connectable;
	gboolean host_reachable;
	gboolean host_reachable_set;

	GWeakRef session_weakref;
	gulong session_notify_network_monitor_handler_id;

	GNetworkMonitor *network_monitor;
	gulong network_changed_handler_id;

	GCancellable *network_monitor_cancellable;
	GMutex network_monitor_cancellable_lock;

	GSource *update_host_reachable;
	GMutex update_host_reachable_lock;
};

/* Forward Declarations */
void		camel_network_service_init	(CamelNetworkService *service);

G_DEFINE_INTERFACE (
	CamelNetworkService,
	camel_network_service,
	CAMEL_TYPE_SERVICE)

static gchar *
network_service_generate_fingerprint (GTlsCertificate *certificate)
{
	GChecksum *checksum;
	GString *fingerprint;
	GByteArray *der;
	guint8 *digest;
	gsize length, ii;
	const gchar tohex[16] = "0123456789abcdef";

	/* XXX No accessor function for this property. */
	g_object_get (certificate, "certificate", &der, NULL);
	g_return_val_if_fail (der != NULL, NULL);

	length = g_checksum_type_get_length (G_CHECKSUM_MD5);
	digest = g_alloca (length);

	checksum = g_checksum_new (G_CHECKSUM_MD5);
	g_checksum_update (checksum, der->data, der->len);
	g_checksum_get_digest (checksum, digest, &length);
	g_checksum_free (checksum);

	g_byte_array_unref (der);

	fingerprint = g_string_sized_new (50);

	for (ii = 0; ii < length; ii++) {
		guint8 byte = digest[ii];

		g_string_append_c (fingerprint, tohex[(byte >> 4) & 0xf]);
		g_string_append_c (fingerprint, tohex[byte & 0xf]);
#ifndef G_OS_WIN32
		g_string_append_c (fingerprint, ':');
#else
		/* The fingerprint is used as a filename, but can't have
		 * colons in filenames on Win32.  Use underscore instead. */
		g_string_append_c (fingerprint, '_');
#endif
	}

	return g_string_free (fingerprint, FALSE);
}

static CamelCert *
network_service_certdb_lookup (CamelCertDB *certdb,
                               GTlsCertificate *certificate,
                               const gchar *expected_host)
{
	CamelCert *cert = NULL;
	GBytes *bytes;
	GByteArray *der;
	gchar *fingerprint;

	fingerprint = network_service_generate_fingerprint (certificate);
	g_return_val_if_fail (fingerprint != NULL, NULL);

	cert = camel_certdb_get_host (certdb, expected_host, fingerprint);
	if (cert == NULL)
		goto exit;

	if (cert->rawcert == NULL) {
		GError *local_error = NULL;

		camel_cert_load_cert_file (cert, &local_error);

		/* Sanity check. */
		g_warn_if_fail (
			((cert->rawcert != NULL) && (local_error == NULL)) ||
			((cert->rawcert == NULL) && (local_error != NULL)));

		if (local_error != NULL) {
			g_warning ("%s: %s", G_STRFUNC, local_error->message);
			g_error_free (local_error);
		}

		if (cert->rawcert == NULL) {
			camel_certdb_remove_host (
				certdb, expected_host, fingerprint);
			camel_certdb_touch (certdb);
			goto exit;
		}
	}

	/* XXX No accessor function for this property. */
	g_object_get (certificate, "certificate", &der, NULL);
	g_return_val_if_fail (der != NULL, cert);

	bytes = g_bytes_new_static (der->data, der->len);

	if (g_bytes_compare (bytes, cert->rawcert) != 0) {
		cert->trust = CAMEL_CERT_TRUST_UNKNOWN;
		camel_certdb_touch (certdb);
	}

	g_byte_array_unref (der);
	g_bytes_unref (bytes);

exit:
	g_free (fingerprint);

	return cert;
}

static void
network_service_certdb_store (CamelCertDB *certdb,
                              CamelCert *cert,
                              GTlsCertificate *certificate)
{
	GByteArray *der = NULL;
	GError *local_error = NULL;

	g_object_get (certificate, "certificate", &der, NULL);
	g_return_if_fail (der != NULL);

	camel_cert_save_cert_file (cert, der, &local_error);

	g_byte_array_unref (der);

	/* Sanity check. */
	g_warn_if_fail (
		((cert->rawcert != NULL) && (local_error == NULL)) ||
		((cert->rawcert == NULL) && (local_error != NULL)));

	if (cert->rawcert != NULL)
		camel_certdb_put (certdb, cert);

	if (local_error != NULL) {
		g_warning ("%s: %s", G_STRFUNC, local_error->message);
		g_error_free (local_error);
	}
}

static gboolean
network_service_accept_certificate_cb (GTlsConnection *connection,
                                       GTlsCertificate *peer_certificate,
                                       GTlsCertificateFlags errors,
                                       CamelNetworkService *service)
{
	CamelCert *cert;
	CamelCertDB *certdb;
	CamelSession *session;
	CamelSettings *settings;
	CamelNetworkSettings *network_settings;
	gboolean new_cert = FALSE;
	gboolean accept;
	gchar *host;

	session = camel_service_ref_session (CAMEL_SERVICE (service));
	if (!session)
		return FALSE;

	settings = camel_service_ref_settings (CAMEL_SERVICE (service));

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);

	certdb = camel_certdb_get_default ();
	cert = network_service_certdb_lookup (certdb, peer_certificate, host);

	if (cert == NULL) {
		cert = camel_cert_new ();
		cert->fingerprint =
			network_service_generate_fingerprint (
			peer_certificate);
		cert->hostname = g_strdup (host);
		cert->trust = CAMEL_CERT_TRUST_UNKNOWN;

		/* Don't put() in the CamelCertDB yet.  Since we can only
		 * store one entry per hostname, we'd rather not ruin any
		 * existing entry for this hostname if the user rejects
		 * the new certificate. */
		new_cert = TRUE;
	}

	g_free (host);

	if ((errors & G_TLS_CERTIFICATE_REVOKED) != 0) {
		/* Always reject revoked certificates */
		accept = FALSE;
	} else {
		if (cert->trust == CAMEL_CERT_TRUST_UNKNOWN) {
			cert->trust = camel_session_trust_prompt (
				session, CAMEL_SERVICE (service),
				peer_certificate, errors);

			if (new_cert)
				network_service_certdb_store (
					certdb, cert, peer_certificate);

			camel_certdb_touch (certdb);
		}

		switch (cert->trust) {
			case CAMEL_CERT_TRUST_MARGINAL:
			case CAMEL_CERT_TRUST_FULLY:
			case CAMEL_CERT_TRUST_ULTIMATE:
			case CAMEL_CERT_TRUST_TEMPORARY:
				accept = TRUE;
				break;
			default:
				accept = FALSE;
				break;
		}
	}

	camel_cert_unref (cert);
	camel_certdb_save (certdb);

	g_clear_object (&certdb);
	g_clear_object (&session);
	g_clear_object (&settings);

	return accept;
}

static void
network_service_client_event_cb (GSocketClient *client,
                                 GSocketClientEvent event,
                                 GSocketConnectable *connectable,
                                 GIOStream *connection,
                                 CamelNetworkService *service)
{
	if (event == G_SOCKET_CLIENT_TLS_HANDSHAKING) {
		g_signal_connect (
			connection, "accept-certificate",
			G_CALLBACK (network_service_accept_certificate_cb),
			service);
	}
}

static gboolean
network_service_notify_host_reachable_cb (gpointer user_data)
{
	g_object_notify (G_OBJECT (user_data), "host-reachable");

	return G_SOURCE_REMOVE;
}

static void
network_service_notify_host_reachable (CamelNetworkService *service)
{
	CamelSession *session;

	session = camel_service_ref_session (CAMEL_SERVICE (service));

	if (session) {
		camel_session_idle_add (
			session, G_PRIORITY_DEFAULT_IDLE,
			network_service_notify_host_reachable_cb,
			g_object_ref (service),
			(GDestroyNotify) g_object_unref);

		g_object_unref (session);
	}
}

static void
network_service_set_host_reachable (CamelNetworkService *service,
                                    gboolean host_reachable)
{
	CamelNetworkServicePrivate *priv;

	priv = CAMEL_NETWORK_SERVICE_GET_PRIVATE (service);
	g_return_if_fail (priv != NULL);

	g_mutex_lock (&priv->property_lock);

	/* Host reachability is in an indeterminate state until the first
	 * time this function is called.  Don't let our arbitrary default
	 * value block the first notification signal. */
	if (!priv->host_reachable_set) {
		priv->host_reachable_set = TRUE;
	} else if (host_reachable == priv->host_reachable) {
		g_mutex_unlock (&priv->property_lock);
		return;
	}

	priv->host_reachable = host_reachable;

	g_mutex_unlock (&priv->property_lock);

	network_service_notify_host_reachable (service);

	/* Disconnect immediately if the host is not reachable.
	 * Then connect lazily when the host becomes reachable. */
	if (!host_reachable) {
		GError *local_error = NULL;

		/* XXX Does this actually block in any providers?
		 *     If so then we need to do it asynchronously. */
		camel_service_disconnect_sync (
			CAMEL_SERVICE (service), FALSE, NULL, &local_error);
		if (local_error != NULL) {
			if (!G_IS_IO_ERROR (local_error, G_IO_ERROR_CANCELLED))
				g_warning ("%s: %s", G_STRFUNC, local_error->message);
			g_error_free (local_error);
		}
	}
}

static gboolean
network_service_update_host_reachable_timeout_cb (gpointer user_data)
{
	CamelNetworkService *service;
	CamelNetworkServicePrivate *priv;
	GCancellable *old_cancellable;
	GCancellable *new_cancellable;
	GSource *current_source;

	current_source = g_main_current_source ();
	if (current_source && g_source_is_destroyed (current_source))
		return FALSE;

	service = CAMEL_NETWORK_SERVICE (user_data);
	priv = CAMEL_NETWORK_SERVICE_GET_PRIVATE (service);
	g_return_val_if_fail (priv != NULL, FALSE);

	g_mutex_lock (&priv->update_host_reachable_lock);
	g_source_unref (priv->update_host_reachable);
	priv->update_host_reachable = NULL;
	g_mutex_unlock (&priv->update_host_reachable_lock);

	new_cancellable = g_cancellable_new ();

	g_mutex_lock (&priv->network_monitor_cancellable_lock);
	old_cancellable = priv->network_monitor_cancellable;
	priv->network_monitor_cancellable = g_object_ref (new_cancellable);
	g_mutex_unlock (&priv->network_monitor_cancellable_lock);

	g_cancellable_cancel (old_cancellable);

	/* XXX This updates the "host-reachable" property on its own.
	 *     There's nothing else to do with the result so omit the
	 *     GAsyncReadyCallback; just needs to run asynchronously. */
	camel_network_service_can_reach (service, new_cancellable, NULL, NULL);

	g_clear_object (&old_cancellable);
	g_clear_object (&new_cancellable);

	return FALSE;
}

static void
network_service_update_host_reachable (CamelNetworkService *service)
{
	CamelNetworkServicePrivate *priv;
	CamelSession *session;
	GMainContext *main_context;
	GSource *timeout_source;

	priv = CAMEL_NETWORK_SERVICE_GET_PRIVATE (service);

	session = camel_service_ref_session (CAMEL_SERVICE (service));
	if (!session)
		return;

	if (!camel_session_get_online (session)) {
		g_object_unref (session);
		return;
	}

	g_mutex_lock (&priv->update_host_reachable_lock);

	/* Reference the service before destroying any already scheduled GSource,
	   in case the service's last reference is held by that GSource. */
	g_object_ref (service);

	if (priv->update_host_reachable) {
		g_source_destroy (priv->update_host_reachable);
		g_source_unref (priv->update_host_reachable);
		priv->update_host_reachable = NULL;
	}

	main_context = camel_session_ref_main_context (session);

	timeout_source = g_timeout_source_new_seconds (5);
	g_source_set_priority (timeout_source, G_PRIORITY_LOW);
	g_source_set_callback (
		timeout_source,
		network_service_update_host_reachable_timeout_cb,
		service, (GDestroyNotify) g_object_unref);
	g_source_attach (timeout_source, main_context);
	priv->update_host_reachable = g_source_ref (timeout_source);
	g_source_unref (timeout_source);

	g_main_context_unref (main_context);

	g_mutex_unlock (&priv->update_host_reachable_lock);

	g_object_unref (session);
}

static void
network_service_network_changed_cb (GNetworkMonitor *network_monitor,
                                    gboolean network_available,
                                    CamelNetworkService *service)
{
	network_service_update_host_reachable (service);
}

static void
network_service_session_notify_network_monitor_cb (GObject *object,
						   GParamSpec *param,
						   gpointer user_data)
{
	CamelSession *session;
	CamelNetworkService *service = user_data;
	CamelNetworkServicePrivate *priv;
	GNetworkMonitor *network_monitor;
	gboolean update_host_reachable = FALSE;

	g_return_if_fail (CAMEL_IS_SESSION (object));
	g_return_if_fail (CAMEL_IS_NETWORK_SERVICE (service));

	priv = CAMEL_NETWORK_SERVICE_GET_PRIVATE (service);
	g_return_if_fail (priv != NULL);

	g_object_ref (service);

	session = CAMEL_SESSION (object);

	network_monitor = camel_session_ref_network_monitor (session);

	g_mutex_lock (&priv->property_lock);

	if (network_monitor != priv->network_monitor) {
		if (priv->network_monitor) {
			g_signal_handler_disconnect (
				priv->network_monitor,
				priv->network_changed_handler_id);
			g_object_unref (priv->network_monitor);
		}

		priv->network_monitor = g_object_ref (network_monitor);

		priv->network_changed_handler_id = g_signal_connect (
			priv->network_monitor, "network-changed",
			G_CALLBACK (network_service_network_changed_cb), service);

		update_host_reachable = TRUE;
	}

	g_mutex_unlock (&priv->property_lock);

	g_clear_object (&network_monitor);

	if (update_host_reachable)
		network_service_update_host_reachable (service);

	g_object_unref (service);
}

static CamelNetworkServicePrivate *
network_service_private_new (CamelNetworkService *service)
{
	CamelNetworkServicePrivate *priv;
	CamelSession *session;
	gulong handler_id;

	priv = g_slice_new0 (CamelNetworkServicePrivate);

	g_mutex_init (&priv->property_lock);
	g_mutex_init (&priv->network_monitor_cancellable_lock);
	g_mutex_init (&priv->update_host_reachable_lock);

	/* Configure network monitoring. */

	session = camel_service_ref_session (CAMEL_SERVICE (service));
	if (session) {
		priv->network_monitor = camel_session_ref_network_monitor (session);

		priv->session_notify_network_monitor_handler_id =
			g_signal_connect (session, "notify::network-monitor",
				G_CALLBACK (network_service_session_notify_network_monitor_cb), service);

		g_weak_ref_init (&priv->session_weakref, session);

		g_object_unref (session);
	} else
		g_weak_ref_init (&priv->session_weakref, NULL);

	if (priv->network_monitor) {
		handler_id = g_signal_connect (
			priv->network_monitor, "network-changed",
			G_CALLBACK (network_service_network_changed_cb), service);
		priv->network_changed_handler_id = handler_id;
	}

	return priv;
}

static void
network_service_private_free (CamelNetworkServicePrivate *priv)
{
	if (priv->network_changed_handler_id) {
		g_signal_handler_disconnect (
			priv->network_monitor,
			priv->network_changed_handler_id);
	}

	if (priv->session_notify_network_monitor_handler_id) {
		CamelSession *session;

		session = g_weak_ref_get (&priv->session_weakref);
		if (session) {
			g_signal_handler_disconnect (
				session,
				priv->session_notify_network_monitor_handler_id);
			g_object_unref (session);
		}
	}

	g_clear_object (&priv->connectable);
	g_clear_object (&priv->network_monitor);
	g_clear_object (&priv->network_monitor_cancellable);
	g_weak_ref_clear (&priv->session_weakref);

	if (priv->update_host_reachable != NULL) {
		g_source_destroy (priv->update_host_reachable);
		g_source_unref (priv->update_host_reachable);
	}

	g_mutex_clear (&priv->property_lock);
	g_mutex_clear (&priv->network_monitor_cancellable_lock);
	g_mutex_clear (&priv->update_host_reachable_lock);

	g_slice_free (CamelNetworkServicePrivate, priv);
}

static GIOStream *
network_service_connect_sync (CamelNetworkService *service,
                              GCancellable *cancellable,
                              GError **error)
{
	GSocketClient *client;
	GSocketConnection *connection;
	GSocketConnectable *connectable;
	CamelNetworkSecurityMethod method;
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;

	settings = camel_service_ref_settings (CAMEL_SERVICE (service));

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	method = camel_network_settings_get_security_method (network_settings);

	connectable = camel_network_service_ref_connectable (service);
	g_return_val_if_fail (connectable != NULL, NULL);

	client = g_socket_client_new ();
	g_socket_client_set_timeout (client, 90);

	g_signal_connect (
		client, "event",
		G_CALLBACK (network_service_client_event_cb), service);

	if (method == CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT)
		g_socket_client_set_tls (client, TRUE);

	camel_binding_bind_property (
		service, "proxy-resolver",
		client, "proxy-resolver",
		G_BINDING_SYNC_CREATE);

	connection = g_socket_client_connect (
		client, connectable, cancellable, error);

	g_object_unref (connectable);
	g_object_unref (client);

	g_object_unref (settings);

	if (connection) {
		GSocket *socket;

		socket = g_socket_connection_get_socket (connection);
		if (socket) {
			g_socket_set_timeout (socket, 90);
			g_socket_set_keepalive (socket, TRUE);
		}
	}

	return (connection != NULL) ? G_IO_STREAM (connection) : NULL;
}

static GSocketConnectable *
network_service_new_connectable (CamelNetworkService *service)
{
	GSocketConnectable *connectable = NULL;
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	guint16 port;
	gchar *host;

	/* Some services might want to override this method to
	 * create a GNetworkService instead of a GNetworkAddress. */

	settings = camel_service_ref_settings (CAMEL_SERVICE (service));
	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host_ensure_ascii (network_settings);
	port = camel_network_settings_get_port (network_settings);

	if (host && *host) {
		CamelProvider *provider;

		provider = camel_service_get_provider (CAMEL_SERVICE (service));

		connectable = g_object_new (G_TYPE_NETWORK_ADDRESS,
			"scheme", provider ? provider->protocol : "socks",
			"hostname", host,
			"port", port,
			NULL);
	}

	g_free (host);

	g_object_unref (settings);

	return connectable;
}

static void
camel_network_service_default_init (CamelNetworkServiceInterface *iface)
{
	iface->connect_sync = network_service_connect_sync;
	iface->new_connectable = network_service_new_connectable;

	g_object_interface_install_property (
		iface,
		g_param_spec_object (
			"connectable",
			"Connectable",
			"Socket endpoint of a network service",
			G_TYPE_SOCKET_CONNECTABLE,
			G_PARAM_READWRITE |
			G_PARAM_STATIC_STRINGS));

	g_object_interface_install_property (
		iface,
		g_param_spec_boolean (
			"host-reachable",
			"Host Reachable",
			"Whether the host is reachable",
			FALSE,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));
}

void
camel_network_service_init (CamelNetworkService *service)
{
	/* This is called from CamelService during instance
	 * construction.  It is not part of the public API. */

	g_return_if_fail (CAMEL_IS_NETWORK_SERVICE (service));

	g_object_set_data_full (
		G_OBJECT (service), PRIVATE_KEY,
		network_service_private_new (service),
		(GDestroyNotify) network_service_private_free);
}

/**
 * camel_network_service_get_service_name:
 * @service: a #CamelNetworkService
 * @method: a #CamelNetworkSecurityMethod
 *
 * Returns the standard network service name for @service and the security
 * method @method, as defined in /etc/services.  For example, the service
 * name for unencrypted IMAP or encrypted IMAP using STARTTLS is "imap",
 * but the service name for IMAP over SSL is "imaps".
 *
 * Returns: the network service name for @service and @method, or %NULL
 *
 * Since: 3.2
 **/
const gchar *
camel_network_service_get_service_name (CamelNetworkService *service,
                                        CamelNetworkSecurityMethod method)
{
	CamelNetworkServiceInterface *iface;
	const gchar *service_name = NULL;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SERVICE (service), NULL);

	iface = CAMEL_NETWORK_SERVICE_GET_INTERFACE (service);

	if (iface->get_service_name != NULL)
		service_name = iface->get_service_name (service, method);

	return service_name;
}

/**
 * camel_network_service_get_default_port:
 * @service: a #CamelNetworkService
 * @method: a #CamelNetworkSecurityMethod
 *
 * Returns the default network port number for @service and the security
 * method @method, as defined in /etc/services.  For example, the default
 * port for unencrypted IMAP or encrypted IMAP using STARTTLS is 143, but
 * the default port for IMAP over SSL is 993.
 *
 * Returns: the default port number for @service and @method
 *
 * Since: 3.2
 **/
guint16
camel_network_service_get_default_port (CamelNetworkService *service,
                                        CamelNetworkSecurityMethod method)
{
	CamelNetworkServiceInterface *iface;
	guint16 default_port = 0;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SERVICE (service), 0);

	iface = CAMEL_NETWORK_SERVICE_GET_INTERFACE (service);

	if (iface->get_default_port != NULL)
		default_port = iface->get_default_port (service, method);

	return default_port;
}

/**
 * camel_network_service_ref_connectable:
 * @service: a #CamelNetworkService
 *
 * Returns the socket endpoint for the network service to which @service
 * is a client.
 *
 * The returned #GSocketConnectable is referenced for thread-safety and
 * must be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: (transfer full): a #GSocketConnectable
 *
 * Since: 3.8
 **/
GSocketConnectable *
camel_network_service_ref_connectable (CamelNetworkService *service)
{
	CamelNetworkServicePrivate *priv;
	GSocketConnectable *connectable = NULL;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SERVICE (service), NULL);

	priv = CAMEL_NETWORK_SERVICE_GET_PRIVATE (service);
	g_return_val_if_fail (priv != NULL, NULL);

	g_mutex_lock (&priv->property_lock);

	if (priv->connectable != NULL) {
		connectable = g_object_ref (priv->connectable);
		g_mutex_unlock (&priv->property_lock);
	} else {
		CamelNetworkServiceInterface *iface;

		g_mutex_unlock (&priv->property_lock);

		iface = CAMEL_NETWORK_SERVICE_GET_INTERFACE (service);
		g_return_val_if_fail (iface->new_connectable != NULL, NULL);

		/* This may return NULL if we don't have valid network
		 * settings from which to create a GSocketConnectable. */
		connectable = iface->new_connectable (service);
	}

	return connectable;
}

/**
 * camel_network_service_set_connectable:
 * @service: a #CamelNetworkService
 * @connectable: a #GSocketConnectable, or %NULL
 *
 * Sets the socket endpoint for the network service to which @service is
 * a client.  If @connectable is %NULL, a #GSocketConnectable is derived
 * from the @service's #CamelNetworkSettings.
 *
 * Since: 3.8
 **/
void
camel_network_service_set_connectable (CamelNetworkService *service,
                                       GSocketConnectable *connectable)
{
	CamelNetworkServicePrivate *priv;

	g_return_if_fail (CAMEL_IS_NETWORK_SERVICE (service));

	priv = CAMEL_NETWORK_SERVICE_GET_PRIVATE (service);
	g_return_if_fail (priv != NULL);

	/* The GNetworkAddress is not thread safe, thus rather than precache it,
	   create a new instance whenever it's asked for it. Keep precached only
	   the connectable which had been explicitly set, because there cannot be
	   done exact copy of it.
	*/
	if (connectable != NULL) {
		g_return_if_fail (G_IS_SOCKET_CONNECTABLE (connectable));
		g_object_ref (connectable);
	}

	g_mutex_lock (&priv->property_lock);

	if (priv->connectable != NULL)
		g_object_unref (priv->connectable);

	priv->connectable = connectable;

	g_mutex_unlock (&priv->property_lock);

	network_service_update_host_reachable (service);

	g_object_notify (G_OBJECT (service), "connectable");
}

/**
 * camel_network_service_get_host_reachable:
 * @service: a #CamelNetworkService
 *
 * Returns %TRUE if @service believes that the host pointed to by
 * #CamelNetworkService:connectable can be reached.  This property
 * is updated automatically as network conditions change.
 *
 * Returns: whether the host is reachable
 *
 * Since: 3.8
 **/
gboolean
camel_network_service_get_host_reachable (CamelNetworkService *service)
{
	CamelNetworkServicePrivate *priv;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SERVICE (service), FALSE);

	priv = CAMEL_NETWORK_SERVICE_GET_PRIVATE (service);
	g_return_val_if_fail (priv != NULL, FALSE);

	return priv->host_reachable;
}

/**
 * camel_network_service_connect_sync:
 * @service: a #CamelNetworkService
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Attempts to establish a network connection to the server described by
 * @service, using the preferred #CamelNetworkSettings:security-method to
 * secure the connection.  If a connection cannot be established, or the
 * connection attempt is cancelled, the function sets @error and returns
 * %NULL.
 *
 * Returns: (transfer full): a #GIOStream, or %NULL
 *
 * Since: 3.2
 **/
GIOStream *
camel_network_service_connect_sync (CamelNetworkService *service,
                                    GCancellable *cancellable,
                                    GError **error)
{
	CamelNetworkServiceInterface *iface;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SERVICE (service), NULL);

	iface = CAMEL_NETWORK_SERVICE_GET_INTERFACE (service);
	g_return_val_if_fail (iface->connect_sync != NULL, NULL);

	return iface->connect_sync (service, cancellable, error);
}

/**
 * camel_network_service_starttls:
 * @service: a #CamelNetworkService
 * @base_stream: a #GIOStream
 * @error: return location for a #GError, or %NULL
 *
 * Creates a #GTlsClientConnection wrapping @base_stream, which is
 * assumed to communicate with the server identified by @service's
 * #CamelNetworkService:connectable.
 *
 * This should typically be called after issuing a STARTTLS command
 * to a server to initiate a Transport Layer Security handshake.
 *
 * Returns: (transfer full): the new #GTlsClientConnection, or %NULL on error
 *
 * Since: 3.12
 **/
GIOStream *
camel_network_service_starttls (CamelNetworkService *service,
                                GIOStream *base_stream,
                                GError **error)
{
	GSocketConnectable *connectable;
	GIOStream *tls_client_connection;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SERVICE (service), NULL);
	g_return_val_if_fail (G_IS_IO_STREAM (base_stream), NULL);

	connectable = camel_network_service_ref_connectable (service);
	g_return_val_if_fail (connectable != NULL, FALSE);

	tls_client_connection = g_tls_client_connection_new (
		base_stream, connectable, error);

	if (tls_client_connection != NULL) {
		g_signal_connect (
			tls_client_connection, "accept-certificate",
			G_CALLBACK (network_service_accept_certificate_cb),
			service);
	}

	g_object_unref (connectable);

	return tls_client_connection;
}

/**
 * camel_network_service_can_reach_sync:
 * @service: a #CamelNetworkService
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Attempts to determine whether or not the host described by @service's
 * #CamelNetworkService:connectable property can be reached, without actually
 * trying to connect to it.
 *
 * If @service believes an attempt to connect will succeed, the function
 * returns %TRUE.  Otherwise the function returns %FALSE and sets @error
 * to an appropriate error (such as %G_IO_ERROR_HOST_UNREACHABLE).
 *
 * The function will also update the @service's
 * #CamelNetworkService:host-reachable property based on the result.
 *
 * Returns: whether the host for @service can be reached
 *
 * Since: 3.12
 **/
gboolean
camel_network_service_can_reach_sync (CamelNetworkService *service,
                                      GCancellable *cancellable,
                                      GError **error)
{
	CamelNetworkServicePrivate *priv;
	GSocketConnectable *connectable;
	gboolean can_reach = FALSE;
	gboolean update_property;
	GError *local_error = NULL;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SERVICE (service), FALSE);

	priv = CAMEL_NETWORK_SERVICE_GET_PRIVATE (service);
	g_return_val_if_fail (priv != NULL, FALSE);

	connectable = camel_network_service_ref_connectable (service);

	if (connectable != NULL) {
		can_reach = g_network_monitor_can_reach (
			priv->network_monitor, connectable,
			cancellable, &local_error);
	} else {
		/* No host information available, assume reachable */
		can_reach = TRUE;
	}

	update_property =
		can_reach ||
		G_IS_IO_ERROR (local_error, G_IO_ERROR_HOST_UNREACHABLE) ||
		G_IS_RESOLVER_ERROR (local_error, G_RESOLVER_ERROR_NOT_FOUND);

	if (update_property) {
		g_mutex_lock (&priv->update_host_reachable_lock);

		if (priv->update_host_reachable) {
			g_source_destroy (priv->update_host_reachable);
			g_source_unref (priv->update_host_reachable);
			priv->update_host_reachable = NULL;
		}

		g_mutex_unlock (&priv->update_host_reachable_lock);

		network_service_set_host_reachable (service, can_reach);
	}

	g_clear_object (&connectable);

	if (local_error)
		g_propagate_error (error, local_error);

	return can_reach;
}

/* Helper for camel_network_service_can_reach() */
static void
network_service_can_reach_thread (CamelSession *session,
                                  GCancellable *cancellable,
				  gpointer user_data,
				  GError **error)
{
	GTask *task = user_data;
	gboolean success;
	GError *local_error = NULL;

	g_return_if_fail (G_IS_TASK (task));

	success = camel_network_service_can_reach_sync (
		CAMEL_NETWORK_SERVICE (g_task_get_source_object (task)),
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_network_service_can_reach:
 * @service: a #CamelNetworkService
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously attempts to determine whether or not the host described by
 * @service's #CamelNetworkService:connectable property can be reached, without
 * actually trying to connect to it.
 *
 * For more details, see camel_network_service_can_reach_sync().
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_network_service_can_reach_finish() to get the result of the
 * operation.
 *
 * Since: 3.12
 **/
void
camel_network_service_can_reach (CamelNetworkService *service,
                                 GCancellable *cancellable,
                                 GAsyncReadyCallback callback,
                                 gpointer user_data)
{
	CamelSession *session;
	gchar *description;
	GTask *task;

	g_return_if_fail (CAMEL_IS_NETWORK_SERVICE (service));

	session = camel_service_ref_session (CAMEL_SERVICE (service));
	g_return_if_fail (session != NULL);

	task = g_task_new (service, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_network_service_can_reach);

	description = g_strdup_printf (_("Checking reach-ability of account “%s”"), camel_service_get_display_name (CAMEL_SERVICE (service)));

	camel_session_submit_job (session, description, network_service_can_reach_thread, task, g_object_unref);

	g_object_unref (session);
	g_free (description);
}

/**
 * camel_network_service_can_reach_finish:
 * @service: a #CamelNetworkService
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_network_service_can_reach().
 *
 * Returns: whether the host for @service can be reached
 *
 * Since: 3.12
 **/
gboolean
camel_network_service_can_reach_finish (CamelNetworkService *service,
                                        GAsyncResult *result,
                                        GError **error)
{
	g_return_val_if_fail (CAMEL_IS_NETWORK_SERVICE (service), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, service), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_network_service_can_reach), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

