/*
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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
 */

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include "e-oauth2-service.h"
#include "e-oauth2-service-base.h"

#include "e-oauth2-service-google.h"

/* https://developers.google.com/identity/protocols/OAuth2InstalledApp */

/* Forward Declarations */
static void e_oauth2_service_google_oauth2_service_init (EOAuth2ServiceInterface *iface);

G_DEFINE_TYPE_WITH_CODE (EOAuth2ServiceGoogle, e_oauth2_service_google, E_TYPE_OAUTH2_SERVICE_BASE,
	G_IMPLEMENT_INTERFACE (E_TYPE_OAUTH2_SERVICE, e_oauth2_service_google_oauth2_service_init))

static gboolean
eos_google_guess_can_process (EOAuth2Service *service,
			      const gchar *protocol,
			      const gchar *hostname)
{
	return hostname && (
		e_util_utf8_strstrcase (hostname, ".google.com") ||
		e_util_utf8_strstrcase (hostname, ".googlemail.com") ||
		e_util_utf8_strstrcase (hostname, ".googleusercontent.com") ||
		e_util_utf8_strstrcase (hostname, ".gmail.com"));
}

static const gchar *
eos_google_get_name (EOAuth2Service *service)
{
	return "Google";
}

static const gchar *
eos_google_get_display_name (EOAuth2Service *service)
{
	/* Translators: This is a user-visible string, display name of an OAuth2 service. */
	return C_("OAuth2Service", "Google");
}

static const gchar *
eos_google_get_client_id (EOAuth2Service *service,
			  ESource *source)
{
	return GOOGLE_CLIENT_ID;
}

static const gchar *
eos_google_get_client_secret (EOAuth2Service *service,
			      ESource *source)
{
	return GOOGLE_CLIENT_SECRET;
}

static const gchar *
eos_google_get_authentication_uri (EOAuth2Service *service,
				   ESource *source)
{
	return "https://accounts.google.com/o/oauth2/auth";
}

static const gchar *
eos_google_get_refresh_uri (EOAuth2Service *service,
			    ESource *source)
{
	return "https://www.googleapis.com/oauth2/v3/token";
}

static void
eos_google_prepare_authentication_uri_query (EOAuth2Service *service,
					     ESource *source,
					     GHashTable *uri_query)
{
	const gchar *GOOGLE_SCOPE =
		/* GMail IMAP and SMTP access */
		"https://mail.google.com/ "
		/* Google Calendar API (CalDAV and GData) */
		"https://www.googleapis.com/auth/calendar "
		/* Google Contacts API (GData) */
		"https://www.google.com/m8/feeds/ "
		/* Google Contacts API (CardDAV) - undocumented */
		"https://www.googleapis.com/auth/carddav "
		/* Google Tasks - undocumented */
		"https://www.googleapis.com/auth/tasks";

	g_return_if_fail (uri_query != NULL);

	e_oauth2_service_util_set_to_form (uri_query, "scope", GOOGLE_SCOPE);
	e_oauth2_service_util_set_to_form (uri_query, "include_granted_scopes", "false");
}

static gboolean
eos_google_extract_authorization_code (EOAuth2Service *service,
				       ESource *source,
				       const gchar *page_title,
				       const gchar *page_uri,
				       const gchar *page_content,
				       gchar **out_authorization_code)
{
	g_return_val_if_fail (out_authorization_code != NULL, FALSE);

	*out_authorization_code = NULL;

	if (page_title && *page_title) {
		/* Known response, but no authorization code */
		if (g_ascii_strncasecmp (page_title, "Denied ", 7) == 0)
			return TRUE;

		if (g_ascii_strncasecmp (page_title, "Success code=", 13) == 0) {
			*out_authorization_code = g_strdup (page_title + 13);
			return TRUE;
		}
	}

	if (page_uri && *page_uri) {
		SoupURI *suri;

		suri = soup_uri_new (page_uri);
		if (suri) {
			const gchar *query = soup_uri_get_query (suri);
			gboolean known = FALSE;

			if (query && *query) {
				GHashTable *params;

				params = soup_form_decode (query);
				if (params) {
					const gchar *response;

					response = g_hash_table_lookup (params, "response");
					if (response && g_ascii_strncasecmp (response, "code=", 5) == 0) {
						*out_authorization_code = g_strdup (response + 5);
						known = TRUE;
					} else if (response && g_ascii_strncasecmp (response, "error", 5) == 0) {
						known = TRUE;
					}

					g_hash_table_destroy (params);
				}
			}

			soup_uri_free (suri);

			if (known)
				return TRUE;
		}
	}

	return FALSE;
}

static void
e_oauth2_service_google_oauth2_service_init (EOAuth2ServiceInterface *iface)
{
	iface->guess_can_process = eos_google_guess_can_process;
	iface->get_name = eos_google_get_name;
	iface->get_display_name = eos_google_get_display_name;
	iface->get_client_id = eos_google_get_client_id;
	iface->get_client_secret = eos_google_get_client_secret;
	iface->get_authentication_uri = eos_google_get_authentication_uri;
	iface->get_refresh_uri = eos_google_get_refresh_uri;
	iface->prepare_authentication_uri_query = eos_google_prepare_authentication_uri_query;
	iface->extract_authorization_code = eos_google_extract_authorization_code;
}

static void
e_oauth2_service_google_class_init (EOAuth2ServiceGoogleClass *klass)
{
}

static void
e_oauth2_service_google_init (EOAuth2ServiceGoogle *oauth2_google)
{
}
