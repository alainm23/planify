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

#include "e-oauth2-service-outlook.h"

/* https://apps.dev.microsoft.com/
   https://msdn.microsoft.com/en-us/library/office/dn631845.aspx
   https://www.limilabs.com/blog/oauth2-outlook-com-imap-installed-applications
*/

#define OUTLOOK_SCOPE "wl.offline_access wl.emails wl.imap"

/* Forward Declarations */
static void e_oauth2_service_outlook_oauth2_service_init (EOAuth2ServiceInterface *iface);

G_DEFINE_TYPE_WITH_CODE (EOAuth2ServiceOutlook, e_oauth2_service_outlook, E_TYPE_OAUTH2_SERVICE_BASE,
	G_IMPLEMENT_INTERFACE (E_TYPE_OAUTH2_SERVICE, e_oauth2_service_outlook_oauth2_service_init))

static gboolean
eos_outlook_guess_can_process (EOAuth2Service *service,
			       const gchar *protocol,
			       const gchar *hostname)
{
	return hostname && e_util_utf8_strstrcase (hostname, ".outlook.com");
}

static const gchar *
eos_outlook_get_name (EOAuth2Service *service)
{
	return "Outlook";
}

static const gchar *
eos_outlook_get_display_name (EOAuth2Service *service)
{
	/* Translators: This is a user-visible string, display name of an OAuth2 service. */
	return C_("OAuth2Service", "Outlook");
}

static const gchar *
eos_outlook_get_client_id (EOAuth2Service *service,
			   ESource *source)
{
	return OUTLOOK_CLIENT_ID;
}

static const gchar *
eos_outlook_get_client_secret (EOAuth2Service *service,
			       ESource *source)
{
	const gchar *secret = OUTLOOK_CLIENT_SECRET;

	if (secret && !*secret)
		return NULL;

	return secret;
}

static const gchar *
eos_outlook_get_authentication_uri (EOAuth2Service *service,
				    ESource *source)
{
	return "https://login.live.com/oauth20_authorize.srf";
}

static const gchar *
eos_outlook_get_refresh_uri (EOAuth2Service *service,
			     ESource *source)
{
	return "https://login.live.com/oauth20_token.srf";
}

static const gchar *
eos_outlook_get_redirect_uri (EOAuth2Service *service,
			      ESource *source)
{
	return "https://login.live.com/oauth20_desktop.srf";
}

static void
eos_outlook_prepare_authentication_uri_query (EOAuth2Service *service,
					      ESource *source,
					      GHashTable *uri_query)
{
	g_return_if_fail (uri_query != NULL);

	e_oauth2_service_util_set_to_form (uri_query, "response_mode", "query");
	e_oauth2_service_util_set_to_form (uri_query, "scope", OUTLOOK_SCOPE);
}

static gboolean
eos_outlook_extract_authorization_code (EOAuth2Service *service,
					ESource *source,
					const gchar *page_title,
					const gchar *page_uri,
					const gchar *page_content,
					gchar **out_authorization_code)
{
	SoupURI *suri;
	gboolean known = FALSE;

	g_return_val_if_fail (out_authorization_code != NULL, FALSE);

	*out_authorization_code = NULL;

	if (!page_uri || !*page_uri)
		return FALSE;

	suri = soup_uri_new (page_uri);
	if (!suri)
		return FALSE;

	if (suri->query) {
		GHashTable *uri_query = soup_form_decode (suri->query);

		if (uri_query) {
			const gchar *code;

			code = g_hash_table_lookup (uri_query, "code");

			if (code && *code) {
				*out_authorization_code = g_strdup (code);
				known = TRUE;
			} else if (g_hash_table_lookup (uri_query, "error")) {
				known = TRUE;
			}

			g_hash_table_unref (uri_query);
		}
	}

	soup_uri_free (suri);

	return known;
}

static void
eos_outlook_prepare_refresh_token_form (EOAuth2Service *service,
					ESource *source,
					const gchar *refresh_token,
					GHashTable *form)
{
	g_return_if_fail (form != NULL);

	e_oauth2_service_util_set_to_form (form, "scope", OUTLOOK_SCOPE);
	e_oauth2_service_util_set_to_form (form, "redirect_uri", e_oauth2_service_get_redirect_uri (service, source));
}

static void
e_oauth2_service_outlook_oauth2_service_init (EOAuth2ServiceInterface *iface)
{
	iface->guess_can_process = eos_outlook_guess_can_process;
	iface->get_name = eos_outlook_get_name;
	iface->get_display_name = eos_outlook_get_display_name;
	iface->get_client_id = eos_outlook_get_client_id;
	iface->get_client_secret = eos_outlook_get_client_secret;
	iface->get_authentication_uri = eos_outlook_get_authentication_uri;
	iface->get_refresh_uri = eos_outlook_get_refresh_uri;
	iface->get_redirect_uri = eos_outlook_get_redirect_uri;
	iface->prepare_authentication_uri_query = eos_outlook_prepare_authentication_uri_query;
	iface->extract_authorization_code = eos_outlook_extract_authorization_code;
	iface->prepare_refresh_token_form = eos_outlook_prepare_refresh_token_form;
}

static void
e_oauth2_service_outlook_class_init (EOAuth2ServiceOutlookClass *klass)
{
}

static void
e_oauth2_service_outlook_init (EOAuth2ServiceOutlook *oauth2_outlook)
{
}
