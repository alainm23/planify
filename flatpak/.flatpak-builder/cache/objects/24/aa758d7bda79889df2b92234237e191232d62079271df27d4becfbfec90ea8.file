/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
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
 */

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include "camel-network-settings.h"
#include "camel-session.h"

#include "camel-sasl-xoauth2.h"

static CamelServiceAuthType sasl_xoauth2_auth_type = {
	N_("OAuth2"),
	N_("This option will use an OAuth 2.0 "
	   "access token to connect to the server"),
	"XOAUTH2",
	FALSE
};

G_DEFINE_TYPE (CamelSaslXOAuth2, camel_sasl_xoauth2, CAMEL_TYPE_SASL)

static void
sasl_xoauth2_append_request (GByteArray *byte_array,
                             const gchar *user,
                             const gchar *access_token)
{
	GString *request;

	g_return_if_fail (user != NULL);
	g_return_if_fail (access_token != NULL);

	/* Compared to OAuth 1.0, this step is trivial. */

	/* The request is easier to assemble with a GString. */
	request = g_string_sized_new (512);

	g_string_append (request, "user=");
	g_string_append (request, user);
	g_string_append_c (request, 1);
	g_string_append (request, "auth=Bearer ");
	g_string_append (request, access_token);
	g_string_append_c (request, 1);
	g_string_append_c (request, 1);

	/* Copy the GString content to the GByteArray. */
	g_byte_array_append (
		byte_array, (guint8 *) request->str, request->len);

	g_string_free (request, TRUE);
}

static GByteArray *
sasl_xoauth2_challenge_sync (CamelSasl *sasl,
                             GByteArray *token,
                             GCancellable *cancellable,
                             GError **error)
{
	GByteArray *byte_array = NULL;
	CamelService *service;
	CamelSession *session;
	CamelSettings *settings;
	gchar *access_token = NULL;
	gint expires_in = -1;
	gboolean success;

	service = camel_sasl_get_service (sasl);
	session = camel_service_ref_session (service);
	settings = camel_service_ref_settings (service);

	success = camel_session_get_oauth2_access_token_sync (session, service,
		&access_token, &expires_in, cancellable, error);

	if (success && expires_in > 0) {
		CamelNetworkSettings *network_settings;
		gchar *user;

		network_settings = CAMEL_NETWORK_SETTINGS (settings);
		user = camel_network_settings_dup_user (network_settings);

		byte_array = g_byte_array_new ();
		sasl_xoauth2_append_request (byte_array, user, access_token);

		g_free (user);
	}

	g_free (access_token);
	g_object_unref (settings);
	g_object_unref (session);

	/* IMAP and SMTP services will Base64-encode the request. */

	return byte_array;
}

static void
camel_sasl_xoauth2_class_init (CamelSaslXOAuth2Class *class)
{
	CamelSaslClass *sasl_class;

	sasl_class = CAMEL_SASL_CLASS (class);
	sasl_class->auth_type = &sasl_xoauth2_auth_type;
	sasl_class->challenge_sync = sasl_xoauth2_challenge_sync;
}

static void
camel_sasl_xoauth2_init (CamelSaslXOAuth2 *sasl)
{
}
