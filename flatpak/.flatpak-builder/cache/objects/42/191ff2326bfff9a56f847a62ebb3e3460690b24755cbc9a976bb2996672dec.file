/*
 * e-soup-auth-bearer.c
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
 * SECTION: e-soup-auth-bearer
 * @include: libedataserver/libedataserver.h
 * @short_description: OAuth 2.0 support for libsoup
 *
 * #ESoupAuthBearer adds libsoup support for the use of bearer tokens in
 * HTTP requests to access OAuth 2.0 protected resources, as defined in
 * <ulink url="http://tools.ietf.org/html/rfc6750">RFC 6750</ulink>.
 *
 * An #EBackend should integrate #ESoupAuthBearer first by adding it as a
 * feature to a #SoupSession's #SoupAuthManager, then from a #SoupSession
 * #SoupSession::authenticate handler call e_source_get_oauth2_access_token()
 * and pass the results to e_soup_auth_bearer_set_access_token().
 **/

#include "evolution-data-server-config.h"

#include "e-soup-auth-bearer.h"

#include <time.h>

#define E_SOUP_AUTH_BEARER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOUP_AUTH_BEARER, ESoupAuthBearerPrivate))

#define AUTH_STRENGTH 1

#define EXPIRY_INVALID ((time_t) -1)

struct _ESoupAuthBearerPrivate {
	gchar *access_token;
	time_t expiry;
};

G_DEFINE_TYPE (
	ESoupAuthBearer,
	e_soup_auth_bearer,
	SOUP_TYPE_AUTH)

static void
e_soup_auth_bearer_finalize (GObject *object)
{
	ESoupAuthBearerPrivate *priv;

	priv = E_SOUP_AUTH_BEARER_GET_PRIVATE (object);

	g_free (priv->access_token);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_soup_auth_bearer_parent_class)->finalize (object);
}

static gboolean
e_soup_auth_bearer_update (SoupAuth *auth,
                           SoupMessage *message,
                           GHashTable *auth_header)
{
	if (message && message->status_code == SOUP_STATUS_UNAUTHORIZED) {
		ESoupAuthBearer *bearer;

		g_return_val_if_fail (E_IS_SOUP_AUTH_BEARER (auth), FALSE);

		bearer = E_SOUP_AUTH_BEARER (auth);

		/* Expire the token, it's likely to be invalid. */
		bearer->priv->expiry = EXPIRY_INVALID;

		return FALSE;
	}

	return TRUE;
}

static GSList *
e_soup_auth_bearer_get_protection_space (SoupAuth *auth,
                                         SoupURI *source_uri)
{
	/* XXX Not sure what to do here.  Need to return something. */

	return g_slist_prepend (NULL, g_strdup (""));
}

static gboolean
e_soup_auth_bearer_is_authenticated (SoupAuth *auth)
{
	ESoupAuthBearer *bearer;
	gboolean authenticated = FALSE;

	bearer = E_SOUP_AUTH_BEARER (auth);

	if (!e_soup_auth_bearer_is_expired (bearer))
		authenticated = (bearer->priv->access_token != NULL);

	return authenticated;
}

static gchar *
e_soup_auth_bearer_get_authorization (SoupAuth *auth,
                                      SoupMessage *message)
{
	ESoupAuthBearer *bearer;

	bearer = E_SOUP_AUTH_BEARER (auth);

	return g_strdup_printf ("Bearer %s", bearer->priv->access_token);
}

static void
e_soup_auth_bearer_class_init (ESoupAuthBearerClass *class)
{
	GObjectClass *object_class;
	SoupAuthClass *auth_class;

	g_type_class_add_private (class, sizeof (ESoupAuthBearerPrivate));

	/* Keep the "e" prefix on private methods
	 * so we don't step on libsoup's namespace. */

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = e_soup_auth_bearer_finalize;

	auth_class = SOUP_AUTH_CLASS (class);
	auth_class->scheme_name = "Bearer";
	auth_class->strength = AUTH_STRENGTH;
	auth_class->update = e_soup_auth_bearer_update;
	auth_class->get_protection_space = e_soup_auth_bearer_get_protection_space;
	auth_class->is_authenticated = e_soup_auth_bearer_is_authenticated;
	auth_class->get_authorization = e_soup_auth_bearer_get_authorization;
}

static void
e_soup_auth_bearer_init (ESoupAuthBearer *bearer)
{
	bearer->priv = E_SOUP_AUTH_BEARER_GET_PRIVATE (bearer);
	bearer->priv->expiry = EXPIRY_INVALID;
}

/**
 * e_soup_auth_bearer_set_access_token:
 * @bearer: an #ESoupAuthBearer
 * @access_token: an OAuth 2.0 access token
 * @expires_in_seconds: expiry for @access_token, or 0 if unknown
 *
 * This function is analogous to soup_auth_authenticate() for "Basic" HTTP
 * authentication, except it takes an OAuth 2.0 access token instead of a
 * username and password.
 *
 * If @expires_in_seconds is greater than zero, soup_auth_is_authenticated()
 * will return %FALSE after the given number of seconds have elapsed.
 *
 * Since: 3.10
 **/
void
e_soup_auth_bearer_set_access_token (ESoupAuthBearer *bearer,
                                     const gchar *access_token,
                                     gint expires_in_seconds)
{
	gboolean was_authenticated;
	gboolean now_authenticated;

	g_return_if_fail (E_IS_SOUP_AUTH_BEARER (bearer));

	was_authenticated = soup_auth_is_authenticated (SOUP_AUTH (bearer));

	g_free (bearer->priv->access_token);
	bearer->priv->access_token = g_strdup (access_token);

	if (expires_in_seconds > 0)
		bearer->priv->expiry = time (NULL) + expires_in_seconds - 1;
	else
		bearer->priv->expiry = EXPIRY_INVALID;

	now_authenticated = soup_auth_is_authenticated (SOUP_AUTH (bearer));

	if (was_authenticated != now_authenticated)
		g_object_notify (
			G_OBJECT (bearer),
			SOUP_AUTH_IS_AUTHENTICATED);
}

/**
 * e_soup_auth_bearer_is_expired:
 * @bearer: an #ESoupAuthBearer
 *
 * Returns: Whether the set token is expired. It is considered expired even
 *   if the e_soup_auth_bearer_set_access_token() was called set yet.
 *
 * Since: 3.24
 **/
gboolean
e_soup_auth_bearer_is_expired (ESoupAuthBearer *bearer)
{
	gboolean expired = TRUE;

	g_return_val_if_fail (E_IS_SOUP_AUTH_BEARER (bearer), TRUE);

	if (bearer->priv->expiry != EXPIRY_INVALID)
		expired = (bearer->priv->expiry <= time (NULL));

	return expired;
}
