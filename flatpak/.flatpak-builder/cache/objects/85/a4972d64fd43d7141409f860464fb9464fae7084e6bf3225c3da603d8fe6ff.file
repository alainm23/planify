/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-smtp-transport.c : class for a smtp transport
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/param.h>
#include <sys/types.h>

#include <glib/gi18n-lib.h>

#include "camel-smtp-settings.h"
#include "camel-smtp-transport.h"

#ifdef G_OS_WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#endif

#undef MIN
#undef MAX

#define d(x) (camel_debug ("smtp") ? (x) : 0)

/* Specified in RFC 821 */
#define SMTP_PORT  25
#define SMTPS_PORT 465

#define CAMEL_SMTP_TRANSPORT_IS_ESMTP               (1 << 0)
#define CAMEL_SMTP_TRANSPORT_8BITMIME               (1 << 1)
#define CAMEL_SMTP_TRANSPORT_ENHANCEDSTATUSCODES    (1 << 2)
#define CAMEL_SMTP_TRANSPORT_STARTTLS               (1 << 3)

/* set if we are using authtypes from a broken AUTH= */
#define CAMEL_SMTP_TRANSPORT_AUTH_EQUAL             (1 << 4)

enum {
	PROP_0,
	PROP_CONNECTABLE,
	PROP_HOST_REACHABLE
};

#define CAMEL_SMTP_TRANSPORT_ERROR camel_smtp_transport_error_quark ()

GQuark camel_smtp_transport_error_quark (void);

G_DEFINE_QUARK (camel-smtp-transport-error-quark, camel_smtp_transport_error)

enum {
	CAMEL_SMTP_TRANSPORT_ERROR_CONNECTION_LOST
};

/* support prototypes */
static GHashTable *	esmtp_get_authtypes	(const guchar *buffer);
static gboolean		smtp_helo		(CamelSmtpTransport *transport,
						 CamelStreamBuffer *istream,
						 CamelStream *ostream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean		smtp_mail		(CamelSmtpTransport *transport,
						 CamelStreamBuffer *istream,
						 CamelStream *ostream,
						 const gchar *sender,
						 gboolean has_8bit_parts,
						 GCancellable *cancellable,
						 GError **error);
static gboolean		smtp_rcpt		(CamelSmtpTransport *transport,
						 CamelStreamBuffer *istream,
						 CamelStream *ostream,
						 const gchar *recipient,
						 GCancellable *cancellable,
						 GError **error);
static gboolean		smtp_data		(CamelSmtpTransport *transport,
						 CamelStreamBuffer *istream,
						 CamelStream *ostream,
						 CamelMimeMessage *message,
						 GCancellable *cancellable,
						 GError **error);
static gboolean		smtp_rset		(CamelSmtpTransport *transport,
						 CamelStreamBuffer *istream,
						 CamelStream *ostream,
						 GCancellable *cancellable,
						 GError **error);
static gboolean		smtp_quit		(CamelSmtpTransport *transport,
						 CamelStreamBuffer *istream,
						 CamelStream *ostream,
						 GCancellable *cancellable,
						 GError **error);
static void		smtp_set_error		(CamelSmtpTransport *transport,
						 CamelStreamBuffer *istream,
						 const gchar *respbuf,
						 GCancellable *cancellable,
						 GError **error);

/* Forward Declarations */
static void camel_network_service_init (CamelNetworkServiceInterface *iface);

G_DEFINE_TYPE_WITH_CODE (
	CamelSmtpTransport,
	camel_smtp_transport,
	CAMEL_TYPE_TRANSPORT,
	G_IMPLEMENT_INTERFACE (
		CAMEL_TYPE_NETWORK_SERVICE,
		camel_network_service_init))

static CamelStreamBuffer *
smtp_ref_istream (CamelSmtpTransport *transport)
{
	CamelStreamBuffer *stream;

	g_return_val_if_fail (CAMEL_IS_SMTP_TRANSPORT (transport), NULL);

	g_mutex_lock (&transport->stream_lock);

	if (transport->istream)
		stream = g_object_ref (transport->istream);
	else
		stream = NULL;

	g_mutex_unlock (&transport->stream_lock);

	return stream;
}

static CamelStream *
smtp_ref_ostream (CamelSmtpTransport *transport)
{
	CamelStream *stream;

	g_return_val_if_fail (CAMEL_IS_SMTP_TRANSPORT (transport), NULL);

	g_mutex_lock (&transport->stream_lock);

	if (transport->ostream)
		stream = g_object_ref (transport->ostream);
	else
		stream = NULL;

	g_mutex_unlock (&transport->stream_lock);

	return stream;
}

static gboolean
connect_to_server (CamelService *service,
                   GCancellable *cancellable,
                   GError **error)
{
	CamelSmtpTransport *transport = CAMEL_SMTP_TRANSPORT (service);
	CamelNetworkSettings *network_settings;
	CamelNetworkSecurityMethod method;
	CamelSettings *settings;
	CamelStream *stream, *ostream = NULL;
	CamelStreamBuffer *istream = NULL;
	GIOStream *base_stream;
	GIOStream *tls_stream;
	gchar *respbuf = NULL;
	gboolean success = TRUE;
	gchar *host;

	if (!CAMEL_SERVICE_CLASS (camel_smtp_transport_parent_class)->
		connect_sync (service, cancellable, error))
		return FALSE;

	/* set some smtp transport defaults */
	transport->flags = 0;
	transport->authtypes = NULL;

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	method = camel_network_settings_get_security_method (network_settings);

	g_object_unref (settings);

	base_stream = camel_network_service_connect_sync (
		CAMEL_NETWORK_SERVICE (service), cancellable, error);

	if (base_stream != NULL) {
		/* get the localaddr - needed later by smtp_helo */
		transport->local_address =
			g_socket_connection_get_local_address (
			G_SOCKET_CONNECTION (base_stream), NULL);

		stream = camel_stream_new (base_stream);
		g_object_unref (base_stream);
	} else {
		success = FALSE;
		goto exit;
	}

	transport->connected = TRUE;

	g_mutex_lock (&transport->stream_lock);

	transport->ostream = stream;
	transport->istream = CAMEL_STREAM_BUFFER (camel_stream_buffer_new (
		stream, CAMEL_STREAM_BUFFER_READ));

	istream = g_object_ref (transport->istream);
	ostream = g_object_ref (transport->ostream);

	g_mutex_unlock (&transport->stream_lock);

	/* Read the greeting, note whether the server is ESMTP or not. */
	do {
		/* Check for "220" */
		g_free (respbuf);
		respbuf = camel_stream_buffer_read_line (istream, cancellable, error);
		d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));
		if (respbuf == NULL) {
			g_prefix_error (error, _("Welcome response error: "));
			transport->connected = FALSE;
			success = FALSE;
			goto exit;
		}
		if (strncmp (respbuf, "220", 3)) {
			smtp_set_error (transport, istream, respbuf, cancellable, error);
			g_prefix_error (error, _("Welcome response error: "));
			g_free (respbuf);
			success = FALSE;
			goto exit;
		}
	} while (*(respbuf+3) == '-'); /* if we got "220-" then loop again */
	g_free (respbuf);

	/* Try sending EHLO */
	transport->flags |= CAMEL_SMTP_TRANSPORT_IS_ESMTP;
	if (!smtp_helo (transport, istream, ostream, cancellable, error)) {
		if (!transport->connected) {
			success = FALSE;
			goto exit;
		}

		/* Fall back to HELO */
		g_clear_error (error);
		transport->flags &= ~CAMEL_SMTP_TRANSPORT_IS_ESMTP;

		if (!smtp_helo (transport, istream, ostream, cancellable, error)) {
			success = FALSE;
			goto exit;
		}
	}

	/* Clear any EHLO/HELO exception and assume that
	 * any SMTP errors encountered were non-fatal. */
	g_clear_error (error);

	if (method != CAMEL_NETWORK_SECURITY_METHOD_STARTTLS_ON_STANDARD_PORT)
		goto exit;  /* we're done */

	if (!(transport->flags & CAMEL_SMTP_TRANSPORT_STARTTLS)) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Failed to connect to SMTP server %s in secure mode: %s"),
			host, _("STARTTLS not supported"));

		success = FALSE;
		goto exit;
	}

	d (fprintf (stderr, "[SMTP] sending: STARTTLS\r\n"));
	if (camel_stream_write (ostream, "STARTTLS\r\n", 10, cancellable, error) == -1) {
		g_prefix_error (error, _("STARTTLS command failed: "));
		success = FALSE;
		goto exit;
	}

	respbuf = NULL;

	do {
		/* Check for "220 Ready for TLS" */
		g_free (respbuf);
		respbuf = camel_stream_buffer_read_line (istream, cancellable, error);
		d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));
		if (respbuf == NULL) {
			g_prefix_error (error, _("STARTTLS command failed: "));
			transport->connected = FALSE;
			success = FALSE;
			goto exit;
		}
		if (strncmp (respbuf, "220", 3) != 0) {
			smtp_set_error (transport, istream, respbuf, cancellable, error);
			g_prefix_error (error, _("STARTTLS command failed: "));
			g_free (respbuf);
			success = FALSE;
			goto exit;
		}
	} while (*(respbuf+3) == '-'); /* if we got "220-" then loop again */

	/* Okay, now toggle SSL/TLS mode */
	base_stream = camel_stream_ref_base_stream (stream);
	tls_stream = camel_network_service_starttls (
		CAMEL_NETWORK_SERVICE (service), base_stream, error);
	g_object_unref (base_stream);

	if (tls_stream != NULL) {
		camel_stream_set_base_stream (stream, tls_stream);
		g_object_unref (tls_stream);
	} else {
		g_prefix_error (
			error,
			_("Failed to connect to SMTP server %s in secure mode: "),
			host);
		success = FALSE;
		goto exit;
	}

	/* We are supposed to re-EHLO after a successful STARTTLS to
	 * re-fetch any supported extensions. */
	if (!smtp_helo (transport, istream, ostream, cancellable, error)) {
		success = FALSE;
	}

exit:
	g_free (host);

	if (!success) {
		transport->connected = FALSE;

		g_mutex_lock (&transport->stream_lock);

		g_clear_object (&transport->istream);
		g_clear_object (&transport->ostream);

		g_mutex_unlock (&transport->stream_lock);
	}

	g_clear_object (&istream);
	g_clear_object (&ostream);

	return success;
}

static void
authtypes_free (gpointer key,
                gpointer value,
                gpointer data)
{
	g_free (value);
}

static void
smtp_transport_set_property (GObject *object,
                             guint property_id,
                             const GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONNECTABLE:
			camel_network_service_set_connectable (
				CAMEL_NETWORK_SERVICE (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
smtp_transport_get_property (GObject *object,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONNECTABLE:
			g_value_take_object (
				value,
				camel_network_service_ref_connectable (
				CAMEL_NETWORK_SERVICE (object)));
			return;

		case PROP_HOST_REACHABLE:
			g_value_set_boolean (
				value,
				camel_network_service_get_host_reachable (
				CAMEL_NETWORK_SERVICE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
smtp_transport_finalize (GObject *object)
{
	CamelSmtpTransport *transport = CAMEL_SMTP_TRANSPORT (object);

	g_mutex_clear (&transport->stream_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (camel_smtp_transport_parent_class)->finalize (object);
}

static gchar *
smtp_transport_get_name (CamelService *service,
                         gboolean brief)
{
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	gchar *host;
	gchar *name;

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);

	g_object_unref (settings);

	if (brief)
		name = g_strdup_printf (
			_("SMTP server %s"), host);
	else
		name = g_strdup_printf (
			_("SMTP mail delivery via %s"), host);

	g_free (host);

	return name;
}

static void
smtp_debug_print_server_name (CamelService *service,
			      const gchar *what)
{
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	gchar *host;
	gint port;

	if (d(1) + 0 == 0)
		return;

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	port = camel_network_settings_get_port (network_settings);

	g_object_unref (settings);

	fprintf (stderr, "[SMTP] %s server %s:%d from account %s\r\n", what, host, port, camel_service_get_uid (service));

	g_free (host);
}

static gboolean
smtp_transport_connect_sync (CamelService *service,
                             GCancellable *cancellable,
                             GError **error)
{
	CamelSmtpTransport *transport = CAMEL_SMTP_TRANSPORT (service);
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	gchar *host;
	gchar *mechanism;
	gboolean auth_required;
	gboolean success = TRUE;

	/* Chain up to parent's method. */
	if (!CAMEL_SERVICE_CLASS (camel_smtp_transport_parent_class)->connect_sync (service, cancellable, error))
		return FALSE;

	smtp_debug_print_server_name (service, "Connecting to");

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	mechanism = camel_network_settings_dup_auth_mechanism (network_settings);

	g_object_unref (settings);

	/* We (probably) need to check popb4smtp before we connect ... */
	if (g_strcmp0 (mechanism, "POPB4SMTP") == 0) {
		GByteArray *chal;
		CamelSasl *sasl;

		sasl = camel_sasl_new ("smtp", "POPB4SMTP", service);
		chal = camel_sasl_challenge_sync (sasl, NULL, cancellable, error);
		if (chal != NULL)
			g_byte_array_free (chal, TRUE);

		if (camel_sasl_get_authenticated (sasl))
			success = connect_to_server (
				service, cancellable, error);
		else
			success = FALSE;

		g_object_unref (sasl);

		goto exit;
	}

	success = connect_to_server (service, cancellable, error);

	if (!success)
		goto exit;

	/* check to see if AUTH is required, if so...then AUTH ourselves */
	auth_required =
		(mechanism != NULL) &&
		(transport->authtypes != NULL) &&
		(g_hash_table_size (transport->authtypes) > 0) &&
		(transport->flags & CAMEL_SMTP_TRANSPORT_IS_ESMTP);

	if (auth_required) {
		CamelSession *session;

		session = camel_service_ref_session (service);
		if (!session) {
			success = FALSE;
			g_set_error_literal (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_UNAVAILABLE,
				_("You must be working online to complete this operation"));
			goto exit;
		}

		if (g_hash_table_lookup (transport->authtypes, camel_sasl_is_xoauth2_alias (mechanism) ? "XOAUTH2" : mechanism)) {
			gint tries = 0;
			GError *local_error = NULL;

			success = camel_session_authenticate_sync (
				session, service, mechanism,
				cancellable, &local_error);

			while (g_error_matches (local_error, CAMEL_SMTP_TRANSPORT_ERROR, CAMEL_SMTP_TRANSPORT_ERROR_CONNECTION_LOST) &&
			       !g_cancellable_is_cancelled (cancellable) && tries < 3) {
				d (fprintf (stderr, "[SMTP] reconnecting after dropped connection, %d. try\r\n", tries + 1));

				tries++;

				g_clear_error (&local_error);

				transport->connected = FALSE;
				g_mutex_lock (&transport->stream_lock);
				g_clear_object (&transport->istream);
				g_clear_object (&transport->ostream);
				g_mutex_unlock (&transport->stream_lock);

				success = connect_to_server (service, cancellable, error);
				if (success)
					success = camel_session_authenticate_sync (
						session, service, mechanism,
						cancellable, &local_error);
			}

			if (local_error)
				g_propagate_error (error, local_error);
		} else {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("SMTP server %s does not support %s "
				"authentication"), host, mechanism);
			success = FALSE;
		}

		g_object_unref (session);

		if (!success)
			transport->connected = FALSE;
	}

exit:
	g_free (host);
	g_free (mechanism);

	return success;
}

static gboolean
smtp_transport_disconnect_sync (CamelService *service,
                                gboolean clean,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelServiceClass *service_class;
	CamelSmtpTransport *transport = CAMEL_SMTP_TRANSPORT (service);
	CamelStreamBuffer *istream;
	CamelStream *ostream;

	istream = smtp_ref_istream (transport);
	ostream = smtp_ref_ostream (transport);

	if (istream && ostream && clean) {
		/* send the QUIT command to the SMTP server */
		smtp_quit (transport, istream, ostream, cancellable, NULL);
	}

	g_clear_object (&istream);
	g_clear_object (&ostream);

	/* Chain up to parent's disconnect() method. */
	service_class = CAMEL_SERVICE_CLASS (camel_smtp_transport_parent_class);
	if (!service_class->disconnect_sync (service, clean, cancellable, error))
		return FALSE;

	if (transport->authtypes) {
		g_hash_table_foreach (transport->authtypes, authtypes_free, NULL);
		g_hash_table_destroy (transport->authtypes);
		transport->authtypes = NULL;
	}

	g_mutex_lock (&transport->stream_lock);
	g_clear_object (&transport->istream);
	g_clear_object (&transport->ostream);
	g_mutex_unlock (&transport->stream_lock);
	g_clear_object (&transport->local_address);

	transport->connected = FALSE;

	return TRUE;
}

static CamelAuthenticationResult
smtp_transport_authenticate_sync (CamelService *service,
                                  const gchar *mechanism,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelSmtpTransport *transport = CAMEL_SMTP_TRANSPORT (service);
	CamelAuthenticationResult result;
	CamelSasl *sasl;
	CamelStreamBuffer *istream;
	CamelStream *ostream;
	gchar *cmdbuf, *respbuf = NULL, *challenge;
	gboolean auth_challenge = FALSE;
	GError *local_error = NULL;

	if (mechanism == NULL) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			_("No SASL mechanism was specified"));
		return CAMEL_AUTHENTICATION_ERROR;
	}

	sasl = camel_sasl_new ("smtp", mechanism, service);
	if (sasl == NULL) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			_("No support for %s authentication"), mechanism);
		return CAMEL_AUTHENTICATION_ERROR;
	}

	challenge = camel_sasl_challenge_base64_sync (
		sasl, NULL, cancellable, &local_error);
	if (challenge) {
		auth_challenge = TRUE;
		cmdbuf = g_strdup_printf (
			"AUTH %s %s\r\n", camel_sasl_is_xoauth2_alias (mechanism) ? "XOAUTH2" : mechanism, challenge);
		g_free (challenge);
	} else if (local_error) {
		d (fprintf (stderr, "[SMTP] SASL challenge failed: %s", local_error->message));
		g_propagate_error (error, local_error);
		g_object_unref (sasl);
		return CAMEL_AUTHENTICATION_ERROR;
	} else {
		cmdbuf = g_strdup_printf (
			"AUTH %s\r\n", mechanism);
	}

	istream = smtp_ref_istream (transport);
	ostream = smtp_ref_ostream (transport);

	if (!istream || !ostream) {
		g_free (cmdbuf);
		g_set_error_literal (error, CAMEL_SERVICE_ERROR, CAMEL_SERVICE_ERROR_NOT_CONNECTED,
			_("AUTH command failed: Not connected."));
		goto lose;
	}

	d (fprintf (stderr, "[SMTP] sending: %s", cmdbuf));
	if (camel_stream_write_string (ostream, cmdbuf, cancellable, error) == -1) {
		g_free (cmdbuf);
		g_prefix_error (error, _("AUTH command failed: "));
		goto lose;
	}
	g_free (cmdbuf);

	respbuf = camel_stream_buffer_read_line (istream, cancellable, error);
	d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));

	while (!camel_sasl_get_authenticated (sasl)) {
		if (!respbuf) {
			/* It's an EOF state on the input stream. */
			if (error && !*error)
				g_set_error (error, CAMEL_SMTP_TRANSPORT_ERROR,
					CAMEL_SMTP_TRANSPORT_ERROR_CONNECTION_LOST, _("Connection cancelled"));
			g_prefix_error (error, _("AUTH command failed: "));
			transport->connected = FALSE;
			goto lose;
		}

		/* the server may have accepted our initial response */
		if (strncmp (respbuf, "235", 3) == 0)
			break;

		/* the server challenge/response should follow a 334 code */
		if (strncmp (respbuf, "334", 3) != 0) {
			if (strncmp (respbuf, "535", 3) == 0) {
				goto rejected;
			}

			smtp_set_error (transport, istream, respbuf, cancellable, error);
			g_prefix_error (error, _("AUTH command failed: "));
			goto lose;
		}

		if (FALSE) {
		broken_smtp_server:
			d (fprintf (
				stderr, "[SMTP] Your SMTP server's implementation "
				"of the %s SASL\nauthentication mechanism is "
				"broken. Please report this to the\n"
				"appropriate vendor and suggest that they "
				"re-read rfc2554 again\nfor the first time "
				"(specifically Section 4).\n",
				mechanism));
		}

		/* eat whtspc */
		for (challenge = respbuf + 4; isspace (*challenge); challenge++);

		challenge = camel_sasl_challenge_base64_sync (
			sasl, challenge, cancellable, error);
		if (challenge == NULL)
			goto break_and_lose;

		g_free (respbuf);
		respbuf = NULL;

		/* send our challenge */
		cmdbuf = g_strdup_printf ("%s\r\n", challenge);
		g_free (challenge);
		d (fprintf (stderr, "[SMTP] sending: %s", cmdbuf));
		if (camel_stream_write_string (ostream, cmdbuf, cancellable, error) == -1) {
			g_free (cmdbuf);
			goto lose;
		}
		g_free (cmdbuf);

		/* get the server's response */
		respbuf = camel_stream_buffer_read_line (istream, cancellable, error);
		d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));
	}

	if (respbuf == NULL)
		goto lose;

	/* Work around broken SASL implementations. */
	if (auth_challenge && strncmp (respbuf, "334", 3) == 0)
		goto broken_smtp_server;

	/* If our authentication data was rejected, destroy the
	 * password so that the user gets prompted to try again. */
	if (strncmp (respbuf, "535", 3) == 0) {
 rejected:
		result = CAMEL_AUTHENTICATION_REJECTED;

		/* Read the continuation, if the server returned it. */
		while (respbuf && respbuf[3] == '-') {
			g_free (respbuf);
			respbuf = camel_stream_buffer_read_line (istream, cancellable, error);
			d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));
		}
	} else if (strncmp (respbuf, "235", 3) == 0)
		result = CAMEL_AUTHENTICATION_ACCEPTED;
	/* Catch any other errors. */
	else {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			_("Bad authentication response from server."));
		goto lose;
	}

	goto exit;

break_and_lose:
	/* Get the server out of "waiting for continuation data" mode. */
	d (fprintf (stderr, "[SMTP] sending: *\n"));
	camel_stream_write (ostream, "*\r\n", 3, cancellable, NULL);
	respbuf = camel_stream_buffer_read_line (istream, cancellable, NULL);
	d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));

lose:
	result = CAMEL_AUTHENTICATION_ERROR;

exit:
	g_clear_object (&istream);
	g_clear_object (&ostream);
	g_object_unref (sasl);
	g_free (respbuf);

	return result;
}

static GList *
smtp_transport_query_auth_types_sync (CamelService *service,
                                      GCancellable *cancellable,
                                      GError **error)
{
	CamelSmtpTransport *transport = CAMEL_SMTP_TRANSPORT (service);
	GList *sasl_types = NULL;

	if (!connect_to_server (service, cancellable, error))
		return NULL;

	if (transport->authtypes) {
		GHashTableIter iter;
		gpointer key;

		g_hash_table_iter_init (&iter, transport->authtypes);
		while (g_hash_table_iter_next (&iter, &key, NULL)) {
			CamelServiceAuthType *auth_type;

			auth_type = camel_sasl_authtype (key);
			if (auth_type)
				sasl_types = g_list_prepend (sasl_types, auth_type);
		}
	}

	smtp_transport_disconnect_sync (service, TRUE, cancellable, NULL);

	return sasl_types;
}

static gboolean
smtp_transport_send_to_sync (CamelTransport *transport,
                             CamelMimeMessage *message,
                             CamelAddress *from,
                             CamelAddress *recipients,
			     gboolean *out_sent_message_saved,
                             GCancellable *cancellable,
                             GError **error)
{
	CamelSmtpTransport *smtp_transport = CAMEL_SMTP_TRANSPORT (transport);
	CamelInternetAddress *cia;
	CamelStreamBuffer *istream;
	CamelStream *ostream;
	gboolean has_8bit_parts;
	const gchar *addr;
	gint i, len;

	smtp_debug_print_server_name (CAMEL_SERVICE (transport), "Sending with");

	istream = smtp_ref_istream (smtp_transport);
	ostream = smtp_ref_ostream (smtp_transport);

	if (!smtp_transport->connected || !istream || !ostream) {
		g_clear_object (&istream);
		g_clear_object (&ostream);
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_NOT_CONNECTED,
			_("Cannot send message: service not connected."));
		return FALSE;
	}

	if (!camel_internet_address_get (CAMEL_INTERNET_ADDRESS (from), 0, NULL, &addr)) {
		g_clear_object (&istream);
		g_clear_object (&ostream);
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot send message: sender address not valid."));
		return FALSE;
	}

	camel_operation_push_message (cancellable, _("Sending message"));

	/* find out if the message has 8bit mime parts */
	has_8bit_parts = camel_mime_message_has_8bit_parts (message);

	/* If the connection needs a ReSET, then do so */
	if (smtp_transport->need_rset &&
	    !smtp_rset (smtp_transport, istream, ostream, cancellable, error)) {
		camel_operation_pop_message (cancellable);
		g_clear_object (&istream);
		g_clear_object (&ostream);
		return FALSE;
	}
	smtp_transport->need_rset = FALSE;

	/* rfc1652 (8BITMIME) requires that you notify the ESMTP daemon that
	 * you'll be sending an 8bit mime message at "MAIL FROM:" time. */
	if (!smtp_mail (
		smtp_transport, istream, ostream, addr, has_8bit_parts, cancellable, error)) {
		camel_operation_pop_message (cancellable);
		g_clear_object (&istream);
		g_clear_object (&ostream);
		return FALSE;
	}

	len = camel_address_length (recipients);
	if (len == 0) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot send message: no recipients defined."));
		camel_operation_pop_message (cancellable);
		smtp_transport->need_rset = TRUE;
		g_clear_object (&istream);
		g_clear_object (&ostream);
		return FALSE;
	}

	cia = CAMEL_INTERNET_ADDRESS (recipients);
	for (i = 0; i < len; i++) {
		gchar *enc;

		if (!camel_internet_address_get (cia, i, NULL, &addr)) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Cannot send message: "
				"one or more invalid recipients"));
			camel_operation_pop_message (cancellable);
			smtp_transport->need_rset = TRUE;
			g_clear_object (&istream);
			g_clear_object (&ostream);
			return FALSE;
		}

		enc = camel_internet_address_encode_address (NULL, NULL, addr);
		if (!smtp_rcpt (smtp_transport, istream, ostream, enc, cancellable, error)) {
			g_free (enc);
			camel_operation_pop_message (cancellable);
			smtp_transport->need_rset = TRUE;
			g_clear_object (&istream);
			g_clear_object (&ostream);
			return FALSE;
		}
		g_free (enc);
	}

	if (!smtp_data (smtp_transport, istream, ostream, message, cancellable, error)) {
		camel_operation_pop_message (cancellable);
		smtp_transport->need_rset = TRUE;
		g_clear_object (&istream);
		g_clear_object (&ostream);
		return FALSE;
	}

	camel_operation_pop_message (cancellable);
	g_clear_object (&istream);
	g_clear_object (&ostream);

	return TRUE;
}

static const gchar *
smtp_transport_get_service_name (CamelNetworkService *service,
                                 CamelNetworkSecurityMethod method)
{
	const gchar *service_name;

	switch (method) {
		case CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT:
			service_name = "smtps";
			break;

		default:
			service_name = "smtp";
			break;
	}

	return service_name;
}

static guint16
smtp_transport_get_default_port (CamelNetworkService *service,
                                 CamelNetworkSecurityMethod method)
{
	guint16 default_port;

	switch (method) {
		case CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT:
			default_port = SMTPS_PORT;
			break;

		default:
			default_port = SMTP_PORT;
			break;
	}

	return default_port;
}

static void
camel_smtp_transport_class_init (CamelSmtpTransportClass *class)
{
	GObjectClass *object_class;
	CamelServiceClass *service_class;
	CamelTransportClass *transport_class;

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = smtp_transport_set_property;
	object_class->get_property = smtp_transport_get_property;
	object_class->finalize = smtp_transport_finalize;

	service_class = CAMEL_SERVICE_CLASS (class);
	service_class->settings_type = CAMEL_TYPE_SMTP_SETTINGS;
	service_class->get_name = smtp_transport_get_name;
	service_class->connect_sync = smtp_transport_connect_sync;
	service_class->disconnect_sync = smtp_transport_disconnect_sync;
	service_class->authenticate_sync = smtp_transport_authenticate_sync;
	service_class->query_auth_types_sync = smtp_transport_query_auth_types_sync;

	transport_class = CAMEL_TRANSPORT_CLASS (class);
	transport_class->send_to_sync = smtp_transport_send_to_sync;

	/* Inherited from CamelNetworkService. */
	g_object_class_override_property (
		object_class,
		PROP_CONNECTABLE,
		"connectable");

	/* Inherited from CamelNetworkService. */
	g_object_class_override_property (
		object_class,
		PROP_HOST_REACHABLE,
		"host-reachable");
}

static void
camel_network_service_init (CamelNetworkServiceInterface *iface)
{
	iface->get_service_name = smtp_transport_get_service_name;
	iface->get_default_port = smtp_transport_get_default_port;
}

static void
camel_smtp_transport_init (CamelSmtpTransport *smtp)
{
	smtp->flags = 0;
	smtp->connected = FALSE;

	g_mutex_init (&smtp->stream_lock);
}

static const gchar *
smtp_error_string (gint error)
{
	/* SMTP error codes grabbed from rfc821 */
	switch (error) {
	case 500:
		return _("Syntax error, command unrecognized");
	case 501:
		return _("Syntax error in parameters or arguments");
	case 502:
		return _("Command not implemented");
	case 504:
		return _("Command parameter not implemented");
	case 211:
		return _("System status, or system help reply");
	case 214:
		return _("Help message");
	case 220:
		return _("Service ready");
	case 221:
		return _("Service closing transmission channel");
	case 421:
		return _("Service not available, closing transmission channel");
	case 250:
		return _("Requested mail action okay, completed");
	case 251:
		return _("User not local; will forward to <forward-path>");
	case 450:
		return _("Requested mail action not taken: mailbox unavailable");
	case 550:
		return _("Requested action not taken: mailbox unavailable");
	case 451:
		return _("Requested action aborted: error in processing");
	case 551:
		return _("User not local; please try <forward-path>");
	case 452:
		return _("Requested action not taken: insufficient system storage");
	case 552:
		return _("Requested mail action aborted: exceeded storage allocation");
	case 553:
		return _("Requested action not taken: mailbox name not allowed");
	case 354:
		return _("Start mail input; end with <CRLF>.<CRLF>");
	case 554:
		return _("Transaction failed");

	/* AUTH error codes: */
	case 432:
		return _("A password transition is needed");
	case 534:
		return _("Authentication mechanism is too weak");
	case 538:
		return _("Encryption required for requested authentication mechanism");
	case 454:
		return _("Temporary authentication failure");
	case 530:
		return _("Authentication required");

	default:
		return _("Unknown");
	}
}

static GHashTable *
esmtp_get_authtypes (const guchar *buffer)
{
	const guchar *start, *end;
	GHashTable *table = NULL;

	start = buffer;

	/* make sure there is at least one delimiter
	 * character in the AUTH response */
	if (!isspace ((gint) *start) && *start != '=')
		return NULL;

	/* advance to the first token */
	while (isspace ((gint) *start) || *start == '=')
		start++;

	if (!*start)
		return NULL;

	table = g_hash_table_new (g_str_hash, g_str_equal);

	for (; *start; ) {
		gchar *type;

		/* advance to the end of the token */
		end = start;
		while (*end && !isspace ((gint) *end))
			end++;

		type = g_strndup ((gchar *) start, end - start);
		g_hash_table_insert (table, type, type);

		/* advance to the next token */
		start = end;
		while (isspace ((gint) *start))
			start++;
	}

	return table;
}

static const gchar *
smtp_next_token (const gchar *buf)
{
	const guchar *token;

	token = (const guchar *) buf;
	while (*token && !isspace ((gint) *token))
		token++;

	while (*token && isspace ((gint) *token))
		token++;

	return (const gchar *) token;
}

#define HEXVAL(c) (isdigit (c) ? (c) - '0' : (c) - 'A' + 10)

/*
 * example (rfc2034):
 * 5.1.1 Mailbox "nosuchuser" does not exist
 *
 * The human-readable status code is what we want. Since this text
 * could possibly be encoded, we must decode it.
 *
 * "xtext" is formally defined as follows:
 *
 *   xtext = *( xchar / hexchar / linear-white-space / comment )
 *
 *   xchar = any ASCII CHAR between "!" (33) and "~" (126) inclusive,
 *        except for "+", "\" and "(".
 *
 * "hexchar"s are intended to encode octets that cannot be represented
 * as plain text, either because they are reserved, or because they are
 * non-printable.  However, any octet value may be represented by a
 * "hexchar".
 *
 *   hexchar = ASCII "+" immediately followed by two upper case
 *        hexadecimal digits
 */
static gchar *
smtp_decode_status_code (const gchar *in,
                         gsize len)
{
	guchar *inptr, *outptr;
	const guchar *inend;
	gchar *outbuf;

	outbuf = (gchar *) g_malloc (len + 1);
	outptr = (guchar *) outbuf;

	inptr = (guchar *) in;
	inend = inptr + len;
	while (inptr < inend) {
		if (*inptr == '+') {
			if (isxdigit (inptr[1]) && isxdigit (inptr[2])) {
				*outptr++ = HEXVAL (inptr[1]) * 16 + HEXVAL (inptr[2]);
				inptr += 3;
			} else
				*outptr++ = *inptr++;
		} else
			*outptr++ = *inptr++;
	}

	*outptr = '\0';

	return outbuf;
}

/* converts string str to local encoding, thinking it's in utf8.
 * If fails, then converts all character greater than 127 to hex values.
 * Also those under 32, other than \n, \r, \t.
 * Note that the c is signed character, so all characters above 127 have
 * negative value.
*/
static void
convert_to_local (GString *str)
{
	gchar *buf;

	buf = g_locale_from_utf8 (str->str, str->len, NULL, NULL, NULL);

	if (!buf) {
		gint i;
		gchar c;
		GString *s = g_string_new_len (str->str, str->len);

		g_string_truncate (str, 0);

		for (i = 0; i < s->len; i++) {
			c = s->str[i];

			if (c < 32 && c != '\n' && c != '\r' && c != '\t')
				g_string_append_printf (str, "<%X%X>", (c >> 4) & 0xF, c & 0xF);
			else
				g_string_append_c (str, c);
		}

		g_string_free (s, TRUE);
	} else {
		g_string_truncate (str, 0);
		g_string_append (str, buf);

		g_free (buf);
	}
}

static void
smtp_set_error (CamelSmtpTransport *transport,
		CamelStreamBuffer *istream,
                const gchar *respbuf,
                GCancellable *cancellable,
                GError **error)
{
	const gchar *token, *rbuf = respbuf;
	gchar *buffer = NULL;
	GString *string;

	g_return_if_fail (respbuf != NULL);

	string = g_string_new ("");
	do {
		if (transport->flags & CAMEL_SMTP_TRANSPORT_ENHANCEDSTATUSCODES)
			token = smtp_next_token (rbuf + 4);
		else
			token = rbuf + 4;

		if (*token == '\0') {
			g_free (buffer);
			g_string_free (string, TRUE);
			goto fake_status_code;
		}

		g_string_append (string, token);
		if (*(rbuf + 3) == '-') {
			g_free (buffer);
			buffer = camel_stream_buffer_read_line (istream, cancellable, NULL);
			d (fprintf (stderr, "[SMTP] received: %s\n", buffer ? buffer : "(null)"));
			g_string_append_c (string, '\n');
		} else {
			g_free (buffer);
			buffer = NULL;
		}

		rbuf = buffer;
	} while (rbuf);

	convert_to_local (string);
	if (!(transport->flags & CAMEL_SMTP_TRANSPORT_ENHANCEDSTATUSCODES) && string->len) {
		string->str = g_strstrip (string->str);
		string->len = strlen (string->str);

		if (!string->len) {
			g_string_free (string, TRUE);
			goto fake_status_code;
		}

		g_set_error (
			error, CAMEL_ERROR,
			CAMEL_ERROR_GENERIC,
			"%s", string->str);

		g_string_free (string, TRUE);
	} else {
		buffer = smtp_decode_status_code (string->str, string->len);
		g_string_free (string, TRUE);
		if (!buffer)
			goto fake_status_code;

		g_set_error (
			error, CAMEL_ERROR,
			CAMEL_ERROR_GENERIC,
			"%s", buffer);

		g_free (buffer);
	}

	return;

fake_status_code:
	g_set_error (
		error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
		"%s", smtp_error_string (atoi (respbuf)));
}

static gboolean
smtp_helo (CamelSmtpTransport *transport,
	   CamelStreamBuffer *istream,
	   CamelStream *ostream,
           GCancellable *cancellable,
           GError **error)
{
	gchar *name = NULL, *cmdbuf = NULL, *respbuf = NULL;
	const gchar *token;
	GResolver *resolver;
	GInetAddress *address;
	GError *local_error = NULL;

	/* these are flags that we set, so unset them in case we
	 * are being called a second time (ie, after a STARTTLS) */
	transport->flags &= ~(CAMEL_SMTP_TRANSPORT_8BITMIME |
			      CAMEL_SMTP_TRANSPORT_ENHANCEDSTATUSCODES |
			      CAMEL_SMTP_TRANSPORT_STARTTLS);

	if (transport->authtypes) {
		g_hash_table_foreach (transport->authtypes, authtypes_free, NULL);
		g_hash_table_destroy (transport->authtypes);
		transport->authtypes = NULL;
	}

	resolver = g_resolver_get_default ();
	address = g_inet_socket_address_get_address (
		G_INET_SOCKET_ADDRESS (transport->local_address));

	name = g_resolver_lookup_by_address (
		resolver, address, cancellable, &local_error);

	/* Sanity check. */
	g_return_val_if_fail (
		((name != NULL) && (local_error == NULL)) ||
		((name == NULL) && (local_error != NULL)), FALSE);

	if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
		return FALSE;

	g_clear_error (&local_error);

	if (name == NULL) {
		GSocketFamily family;
		gchar *string;

		string = g_inet_address_to_string (address);
		family = g_inet_address_get_family (address);
		if (family == G_SOCKET_FAMILY_IPV6)
			name = g_strdup_printf ("[IPv6:%s]", string);
		else
			name = g_strdup_printf ("[%s]", string);
		g_free (string);
	}

	camel_operation_push_message (cancellable, _("SMTP Greeting"));

	token = (transport->flags & CAMEL_SMTP_TRANSPORT_IS_ESMTP) ? "EHLO" : "HELO";
	cmdbuf = g_strdup_printf ("%s %s\r\n", token, name);
	g_free (name);

	d (fprintf (stderr, "[SMTP] sending: %s", cmdbuf));
	if (camel_stream_write_string (ostream, cmdbuf, cancellable, error) == -1) {
		g_free (cmdbuf);
		g_prefix_error (error, _("HELO command failed: "));
		camel_operation_pop_message (cancellable);

		return FALSE;
	}
	g_free (cmdbuf);

	do {
		/* Check for "250" */
		g_free (respbuf);
		respbuf = camel_stream_buffer_read_line (istream, cancellable, error);
		d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));
		if (respbuf == NULL) {
			g_prefix_error (error, _("HELO command failed: "));
			transport->connected = FALSE;
			camel_operation_pop_message (cancellable);
			return FALSE;
		}
		if (strncmp (respbuf, "250", 3)) {
			smtp_set_error (transport, istream, respbuf, cancellable, error);
			g_prefix_error (error, _("HELO command failed: "));
			camel_operation_pop_message (cancellable);
			g_free (respbuf);
			return FALSE;
		}

		token = respbuf + 4;

		if (transport->flags & CAMEL_SMTP_TRANSPORT_IS_ESMTP) {
			if (!g_ascii_strncasecmp (token, "8BITMIME", 8)) {
				transport->flags |= CAMEL_SMTP_TRANSPORT_8BITMIME;
			} else if (!g_ascii_strncasecmp (token, "ENHANCEDSTATUSCODES", 19)) {
				transport->flags |= CAMEL_SMTP_TRANSPORT_ENHANCEDSTATUSCODES;
			} else if (!g_ascii_strncasecmp (token, "STARTTLS", 8)) {
				transport->flags |= CAMEL_SMTP_TRANSPORT_STARTTLS;
			} else if (!g_ascii_strncasecmp (token, "AUTH", 4)) {
				if (!transport->authtypes || transport->flags & CAMEL_SMTP_TRANSPORT_AUTH_EQUAL) {
					/* Don't bother parsing any authtypes if we already have a list.
					 * Some servers will list AUTH twice, once the standard way and
					 * once the way Microsoft Outlook requires them to be:
					 *
					 * 250-AUTH LOGIN PLAIN DIGEST-MD5 CRAM-MD5
					 * 250-AUTH=LOGIN PLAIN DIGEST-MD5 CRAM-MD5
					 *
					 * Since they can come in any order, parse each list that we get
					 * until we parse an authtype list that does not use the AUTH=
					 * format. We want to let the standard way have priority over the
					 * broken way.
					 **/

					if (token[4] == '=')
						transport->flags |= CAMEL_SMTP_TRANSPORT_AUTH_EQUAL;
					else
						transport->flags &= ~CAMEL_SMTP_TRANSPORT_AUTH_EQUAL;

					/* parse for supported AUTH types */
					token += 4;

					if (transport->authtypes) {
						g_hash_table_foreach (transport->authtypes, authtypes_free, NULL);
						g_hash_table_destroy (transport->authtypes);
					}

					transport->authtypes = esmtp_get_authtypes ((const guchar *) token);
				}
			}
		}
	} while (*(respbuf+3) == '-'); /* if we got "250-" then loop again */
	g_free (respbuf);

	camel_operation_pop_message (cancellable);

	return TRUE;
}

static gboolean
smtp_mail (CamelSmtpTransport *transport,
	   CamelStreamBuffer *istream,
	   CamelStream *ostream,
           const gchar *sender,
           gboolean has_8bit_parts,
           GCancellable *cancellable,
           GError **error)
{
	/* we gotta tell the smtp server who we are. (our email addy) */
	gchar *cmdbuf, *respbuf = NULL;

	if (transport->flags & CAMEL_SMTP_TRANSPORT_8BITMIME && has_8bit_parts)
		cmdbuf = g_strdup_printf ("MAIL FROM:<%s> BODY=8BITMIME\r\n", sender);
	else
		cmdbuf = g_strdup_printf ("MAIL FROM:<%s>\r\n", sender);

	d (fprintf (stderr, "[SMTP] sending: %s", cmdbuf));

	if (camel_stream_write_string (ostream, cmdbuf, cancellable, error) == -1) {
		g_free (cmdbuf);
		g_prefix_error (error, _("MAIL FROM command failed: "));
		camel_service_disconnect_sync (
			CAMEL_SERVICE (transport),
			FALSE, cancellable, NULL);
		return FALSE;
	}
	g_free (cmdbuf);

	do {
		/* Check for "250 Sender OK..." */
		g_free (respbuf);
		respbuf = camel_stream_buffer_read_line (istream, cancellable, error);
		d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));
		if (respbuf == NULL) {
			g_prefix_error (error, _("MAIL FROM command failed: "));
			camel_service_disconnect_sync (
				CAMEL_SERVICE (transport),
				FALSE, cancellable, NULL);
			return FALSE;
		}
		if (strncmp (respbuf, "250", 3)) {
			smtp_set_error (transport, istream, respbuf, cancellable, error);
			g_prefix_error (
				error, _("MAIL FROM command failed: "));
			g_free (respbuf);
			return FALSE;
		}
	} while (*(respbuf+3) == '-'); /* if we got "250-" then loop again */
	g_free (respbuf);

	return TRUE;
}

static gboolean
smtp_rcpt (CamelSmtpTransport *transport,
	   CamelStreamBuffer *istream,
	   CamelStream *ostream,
           const gchar *recipient,
           GCancellable *cancellable,
           GError **error)
{
	/* we gotta tell the smtp server who we are going to be sending
	 * our email to */
	gchar *cmdbuf, *respbuf = NULL;

	cmdbuf = g_strdup_printf ("RCPT TO:<%s>\r\n", recipient);

	d (fprintf (stderr, "[SMTP] sending: %s", cmdbuf));

	if (camel_stream_write_string (ostream, cmdbuf, cancellable, error) == -1) {
		g_free (cmdbuf);
		g_prefix_error (error, _("RCPT TO command failed: "));
		camel_service_disconnect_sync (
			CAMEL_SERVICE (transport),
			FALSE, cancellable, NULL);

		return FALSE;
	}
	g_free (cmdbuf);

	do {
		/* Check for "250 Recipient OK..." */
		g_free (respbuf);
		respbuf = camel_stream_buffer_read_line (istream, cancellable, error);
		d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));
		if (respbuf == NULL) {
			g_prefix_error (
				error, _("RCPT TO <%s> failed: "), recipient);
			camel_service_disconnect_sync (
				CAMEL_SERVICE (transport),
				FALSE, cancellable, NULL);
			return FALSE;
		}
		if (strncmp (respbuf, "250", 3)) {
			smtp_set_error (transport, istream, respbuf, cancellable, error);
			g_prefix_error (
				error, _("RCPT TO <%s> failed: "), recipient);
			g_free (respbuf);

			return FALSE;
		}
	} while (*(respbuf+3) == '-'); /* if we got "250-" then loop again */
	g_free (respbuf);

	return TRUE;
}

static void
smtp_maybe_update_socket_timeout (CamelStream *strm,
				  gint timeout_seconds)
{
	GIOStream *base_strm = camel_stream_ref_base_stream (strm);

	if (G_IS_TLS_CONNECTION (base_strm)) {
		GIOStream *base_io_stream = NULL;

		g_object_get (G_OBJECT (base_strm), "base-io-stream", &base_io_stream, NULL);

		g_object_unref (base_strm);
		base_strm = base_io_stream;
	}

	if (G_IS_SOCKET_CONNECTION (base_strm)) {
		GSocket *socket;

		socket = g_socket_connection_get_socket (G_SOCKET_CONNECTION (base_strm));
		if (socket) {
			if (timeout_seconds > g_socket_get_timeout (socket))
				g_socket_set_timeout (socket, timeout_seconds);
		}
	}

	g_clear_object (&base_strm);
}

static gboolean
smtp_data (CamelSmtpTransport *transport,
	   CamelStreamBuffer *istream,
	   CamelStream *ostream,
           CamelMimeMessage *message,
           GCancellable *cancellable,
           GError **error)
{
	CamelNameValueArray *previous_headers;
	const gchar *header_name = NULL, *header_value = NULL;
	CamelBestencEncoding enctype = CAMEL_BESTENC_8BIT;
	CamelStream *filtered_stream;
	gchar *cmdbuf, *respbuf = NULL;
	CamelMimeFilter *filter;
	gsize bytes_written;
	gint ret;
	guint ii;

	/* If the server doesn't support 8BITMIME, set our required encoding to be 7bit */
	if (!(transport->flags & CAMEL_SMTP_TRANSPORT_8BITMIME))
		enctype = CAMEL_BESTENC_7BIT;

	/* FIXME: should we get the best charset too?? */
	/* Changes the encoding of all mime parts to fit within our required
	 * encoding type and also force any text parts with long lines (longer
	 * than 998 octets) to wrap by QP or base64 encoding them. */
	camel_mime_message_set_best_encoding (
		message, CAMEL_BESTENC_GET_ENCODING, enctype);

	cmdbuf = g_strdup ("DATA\r\n");

	d (fprintf (stderr, "[SMTP] sending: %s", cmdbuf));

	if (camel_stream_write_string (ostream, cmdbuf, cancellable, error) == -1) {
		g_free (cmdbuf);
		g_prefix_error (error, _("DATA command failed: "));
		camel_service_disconnect_sync (
			CAMEL_SERVICE (transport),
			FALSE, cancellable, NULL);
		return FALSE;
	}
	g_free (cmdbuf);

	respbuf = camel_stream_buffer_read_line (istream, cancellable, error);
	d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));
	if (respbuf == NULL) {
		g_prefix_error (error, _("DATA command failed: "));
		camel_service_disconnect_sync (
			CAMEL_SERVICE (transport),
			FALSE, cancellable, NULL);
		return FALSE;
	}
	if (strncmp (respbuf, "354", 3) != 0) {
		/* We should have gotten instructions on how to use the DATA
		 * command: 354 Enter mail, end with "." on a line by itself
		 */
		smtp_set_error (transport, istream, respbuf, cancellable, error);
		g_prefix_error (error, _("DATA command failed: "));
		g_free (respbuf);
		return FALSE;
	}

	g_free (respbuf);
	respbuf = NULL;

	/* unlink the bcc headers and keep a copy of them */
	previous_headers = camel_medium_dup_headers (CAMEL_MEDIUM (message));
	camel_medium_remove_header (CAMEL_MEDIUM (message), "Bcc");

	/* find out how large the message is... */
	bytes_written = camel_data_wrapper_calculate_size_sync (CAMEL_DATA_WRAPPER (message), NULL, NULL);

	/* Set the upload timeout to an equal of 512 bytes per second */
	smtp_maybe_update_socket_timeout (ostream, bytes_written / 512);

	filtered_stream = camel_stream_filter_new (ostream);

	/* setup progress reporting for message sending... */
	filter = camel_mime_filter_progress_new (cancellable, bytes_written);
	camel_stream_filter_add (
		CAMEL_STREAM_FILTER (filtered_stream), filter);
	g_object_unref (filter);

	/* setup LF->CRLF conversion */
	filter = camel_mime_filter_crlf_new (
		CAMEL_MIME_FILTER_CRLF_ENCODE,
		CAMEL_MIME_FILTER_CRLF_MODE_CRLF_DOTS);
	camel_stream_filter_add (
		CAMEL_STREAM_FILTER (filtered_stream), filter);
	g_object_unref (filter);

	/* write the message */
	ret = camel_data_wrapper_write_to_stream_sync (
		CAMEL_DATA_WRAPPER (message),
		filtered_stream, cancellable, error);

	/* restore the bcc headers */
	for (ii = 0; camel_name_value_array_get (previous_headers, ii, &header_name, &header_value); ii++) {
		if (!g_ascii_strcasecmp (header_name, "Bcc")) {
			camel_medium_add_header (CAMEL_MEDIUM (message), header_name, header_value);
		}
	}

	camel_name_value_array_free (previous_headers);

	if (ret == -1) {
		g_prefix_error (error, _("DATA command failed: "));

		g_object_unref (filtered_stream);

		camel_service_disconnect_sync (
			CAMEL_SERVICE (transport),
			FALSE, cancellable, NULL);
		return FALSE;
	}

	camel_stream_flush (filtered_stream, cancellable, NULL);
	g_object_unref (filtered_stream);

	/* terminate the message body */

	d (fprintf (stderr, "[SMTP] sending: \\r\\n.\\r\\n\n"));

	if (camel_stream_write (ostream, "\r\n.\r\n", 5, cancellable, error) == -1) {
		g_prefix_error (error, _("DATA command failed: "));
		camel_service_disconnect_sync (
			CAMEL_SERVICE (transport),
			FALSE, cancellable, NULL);
		return FALSE;
	}

	do {
		/* Check for "250 Sender OK..." */
		g_free (respbuf);
		respbuf = camel_stream_buffer_read_line (istream, cancellable, error);
		d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));
		if (respbuf == NULL) {
			g_prefix_error (error, _("DATA command failed: "));
			camel_service_disconnect_sync (
				CAMEL_SERVICE (transport),
				FALSE, cancellable, NULL);
			return FALSE;
		}
		if (strncmp (respbuf, "250", 3) != 0) {
			smtp_set_error (transport, istream, respbuf, cancellable, error);
			g_prefix_error (error, _("DATA command failed: "));
			g_free (respbuf);
			return FALSE;
		}
	} while (*(respbuf+3) == '-'); /* if we got "250-" then loop again */
	g_free (respbuf);

	return TRUE;
}

static gboolean
smtp_rset (CamelSmtpTransport *transport,
	   CamelStreamBuffer *istream,
	   CamelStream *ostream,
           GCancellable *cancellable,
           GError **error)
{
	/* we are going to reset the smtp server (just to be nice) */
	gchar *cmdbuf, *respbuf = NULL;

	cmdbuf = g_strdup ("RSET\r\n");

	d (fprintf (stderr, "[SMTP] sending: %s", cmdbuf));

	if (camel_stream_write_string (ostream, cmdbuf, cancellable, error) == -1) {
		g_free (cmdbuf);
		g_prefix_error (error, _("RSET command failed: "));
		camel_service_disconnect_sync (
			CAMEL_SERVICE (transport),
			FALSE, cancellable, NULL);
		return FALSE;
	}
	g_free (cmdbuf);

	do {
		/* Check for "250" */
		g_free (respbuf);
		respbuf = camel_stream_buffer_read_line (istream, cancellable, error);
		d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));
		if (respbuf == NULL) {
			g_prefix_error (error, _("RSET command failed: "));
			camel_service_disconnect_sync (
				CAMEL_SERVICE (transport),
				FALSE, cancellable, NULL);
			return FALSE;
		}
		if (strncmp (respbuf, "250", 3) != 0) {
			smtp_set_error (transport, istream, respbuf, cancellable, error);
			g_prefix_error (error, _("RSET command failed: "));
			g_free (respbuf);
			return FALSE;
		}
	} while (*(respbuf+3) == '-'); /* if we got "250-" then loop again */
	g_free (respbuf);

	return TRUE;
}

static gboolean
smtp_quit (CamelSmtpTransport *transport,
	   CamelStreamBuffer *istream,
	   CamelStream *ostream,
           GCancellable *cancellable,
           GError **error)
{
	/* we are going to reset the smtp server (just to be nice) */
	gchar *cmdbuf, *respbuf = NULL;

	cmdbuf = g_strdup ("QUIT\r\n");

	d (fprintf (stderr, "[SMTP] sending: %s", cmdbuf));

	if (camel_stream_write_string (ostream, cmdbuf, cancellable, error) == -1) {
		g_free (cmdbuf);
		g_prefix_error (error, _("QUIT command failed: "));
		return FALSE;
	}
	g_free (cmdbuf);

	do {
		/* Check for "221" */
		g_free (respbuf);
		respbuf = camel_stream_buffer_read_line (istream, cancellable, error);

		d (fprintf (stderr, "[SMTP] received: %s\n", respbuf ? respbuf : "(null)"));
		if (respbuf == NULL) {
			g_prefix_error (error, _("QUIT command failed: "));
			transport->connected = FALSE;
			return FALSE;
		}
		if (strncmp (respbuf, "221", 3) != 0) {
			smtp_set_error (transport, istream, respbuf, cancellable, error);
			g_prefix_error (error, _("QUIT command failed: "));
			g_free (respbuf);
			return FALSE;
		}
	} while (*(respbuf+3) == '-'); /* if we got "221-" then loop again */

	g_free (respbuf);

	return TRUE;
}
