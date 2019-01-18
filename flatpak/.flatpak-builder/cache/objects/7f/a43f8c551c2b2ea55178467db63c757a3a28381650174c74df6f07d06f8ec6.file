/*
 * e-soup-ssl-trust.c
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
 * SECTION: e-soup-ssl-trust
 * @include: libedataserver/libedataserver.h
 * @short_description: SSL certificate trust handling for WebDAV sources
 *
 * 
 **/

#include "evolution-data-server-config.h"

#include "e-source-authentication.h"
#include "e-source-webdav.h"

#include "e-soup-ssl-trust.h"

typedef struct _ESoupSslTrustData {
	SoupMessage *soup_message; /* weak */
	ESource *source;

	GClosure *accept_certificate_closure;
} ESoupSslTrustData;

static gboolean
e_soup_ssl_trust_accept_certificate_cb (GTlsConnection *conn,
					GTlsCertificate *peer_cert,
					GTlsCertificateFlags errors,
					gpointer user_data)
{
	ESoupSslTrustData *handler = user_data;
	ETrustPromptResponse response;
	SoupURI *soup_uri;
	const gchar *host;
	gchar *auth_host = NULL;

	soup_uri = soup_message_get_uri (handler->soup_message);
	if (!soup_uri || !soup_uri_get_host (soup_uri))
		return FALSE;

	host = soup_uri_get_host (soup_uri);

	if (e_source_has_extension (handler->source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
		ESourceAuthentication *extension_authentication;

		extension_authentication = e_source_get_extension (handler->source, E_SOURCE_EXTENSION_AUTHENTICATION);
		auth_host = e_source_authentication_dup_host (extension_authentication);

		if (auth_host && *auth_host) {
			/* Use the 'host' from the Authentication extension, because
			   it's the one used when storing the trust prompt result.
			   The SoupMessage can be redirected, thus it would not ever match. */
			host = auth_host;
		} else {
			g_free (auth_host);
			auth_host = NULL;
		}
	}

	response = e_source_webdav_verify_ssl_trust (
		e_source_get_extension (handler->source, E_SOURCE_EXTENSION_WEBDAV_BACKEND),
		host, peer_cert, errors);

	g_free (auth_host);

	return (response == E_TRUST_PROMPT_RESPONSE_ACCEPT ||
	        response == E_TRUST_PROMPT_RESPONSE_ACCEPT_TEMPORARILY);
}

static void
e_soup_ssl_trust_network_event_cb (SoupMessage *msg,
				   GSocketClientEvent event,
				   GIOStream *connection,
				   gpointer user_data)
{
	ESoupSslTrustData *handler = user_data;

	/* It's either a GTlsConnection or a GTcpConnection */
	if (event == G_SOCKET_CLIENT_TLS_HANDSHAKING &&
	    G_IS_TLS_CONNECTION (connection)) {
		g_signal_connect_closure (
			G_TLS_CONNECTION (connection), "accept-certificate",
			handler->accept_certificate_closure, FALSE);
	}
}

static void
e_soup_ssl_trust_message_finalized_cb (gpointer data,
				       GObject *unused_message)
{
	ESoupSslTrustData *handler;

	/* The network event handler will be disconnected from the message just
	 * before this is called. */
	handler = data;

	g_clear_object (&handler->source);

	/* Synchronously disconnects the accept certificate handler from all
	 * GTlsConnections. */
	g_closure_invalidate (handler->accept_certificate_closure);
	g_closure_unref (handler->accept_certificate_closure);

	g_free (handler);
}

/**
 * e_soup_ssl_trust_connect:
 * @soup_message: a #SoupMessage about to be sent to the source
 * @source: an #ESource that uses WebDAV
 *
 * Sets up automatic SSL certificate trust handling for @soup_message using the trust
 * data stored in @source's WebDAV extension. If @soup_message is about to be sent on
 * an SSL connection with an invalid certificate, the code checks if the WebDAV
 * extension already has a trust response for that certificate and verifies it
 * with e_source_webdav_verify_ssl_trust(). If the verification fails, then
 * the @soup_message send also fails.
 *
 * This works by connecting to the "network-event" signal on @soup_message and
 * connecting to the "accept-certificate" signal on each #GTlsConnection for
 * which @soup_message reports a #G_SOCKET_CLIENT_TLS_HANDSHAKING event. These
 * handlers are torn down automatically when @soup_message is disposed. This process
 * is not thread-safe; it is sufficient for safety if all use of @soup_message's
 * session and the disposal of @soup_message occur in the same thread.
 *
 * Since: 3.16
 **/
void
e_soup_ssl_trust_connect (SoupMessage *soup_message,
                          ESource *source)
{
	ESoupSslTrustData *handler;

	g_return_if_fail (SOUP_IS_MESSAGE (soup_message));
	g_return_if_fail (E_IS_SOURCE (source));

	handler = g_malloc (sizeof (ESoupSslTrustData));
	handler->soup_message = soup_message;
	g_object_weak_ref (G_OBJECT (soup_message), e_soup_ssl_trust_message_finalized_cb, handler);
	handler->source = g_object_ref (source);
	handler->accept_certificate_closure = g_cclosure_new (G_CALLBACK (e_soup_ssl_trust_accept_certificate_cb), handler, NULL);

	g_closure_ref (handler->accept_certificate_closure);
	g_closure_sink (handler->accept_certificate_closure);

	g_signal_connect (
		soup_message, "network-event",
		G_CALLBACK (e_soup_ssl_trust_network_event_cb), handler);
}
