/*
 * e-gdata-oauth2-authorizer.c
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

#include <time.h>

#include "e-gdata-oauth2-authorizer.h"

#ifdef HAVE_LIBGDATA

#include <gdata/gdata.h>

#define EXPIRY_INVALID ((time_t) -1)

struct _EGDataOAuth2AuthorizerPrivate {
	GWeakRef source;
	GType service_type;

	/* These members are protected by the global mutex. */
	gchar *access_token;
	time_t expiry;
	GHashTable *authorization_domains;
	ENamedParameters *credentials;
};

enum {
	PROP_0,
	PROP_SERVICE_TYPE,
	PROP_SOURCE
};

/* GDataAuthorizer methods must be thread-safe. */
static GMutex mutex;

/* Forward Declarations */
static void e_gdata_oauth2_authorizer_interface_init (GDataAuthorizerInterface *iface);

G_DEFINE_TYPE_WITH_CODE (EGDataOAuth2Authorizer, e_gdata_oauth2_authorizer, G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (GDATA_TYPE_AUTHORIZER, e_gdata_oauth2_authorizer_interface_init))

static gboolean
e_gdata_oauth2_authorizer_is_authorized (GDataAuthorizer *authorizer,
					 GDataAuthorizationDomain *domain)
{
	EGDataOAuth2Authorizer *oauth2_authorizer;

	/* This MUST be called with the mutex already locked. */

	if (!domain)
		return TRUE;

	oauth2_authorizer = E_GDATA_OAUTH2_AUTHORIZER (authorizer);

	return g_hash_table_contains (oauth2_authorizer->priv->authorization_domains, domain);
}

static void
e_gdata_oauth2_authorizer_set_service_type (EGDataOAuth2Authorizer *authorizer,
					    GType service_type)
{
	g_return_if_fail (service_type != 0);

	authorizer->priv->service_type = service_type;
}

static void
e_gdata_oauth2_authorizer_set_source (EGDataOAuth2Authorizer *authorizer,
				      ESource *source)
{
	g_return_if_fail (E_IS_SOURCE (source));

	g_weak_ref_set (&authorizer->priv->source, source);
}

static void
e_gdata_oauth2_authorizer_set_property (GObject *object,
					guint property_id,
					const GValue *value,
					GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SERVICE_TYPE:
			e_gdata_oauth2_authorizer_set_service_type (
				E_GDATA_OAUTH2_AUTHORIZER (object),
				g_value_get_gtype (value));
			return;

		case PROP_SOURCE:
			e_gdata_oauth2_authorizer_set_source (
				E_GDATA_OAUTH2_AUTHORIZER (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_gdata_oauth2_authorizer_get_property (GObject *object,
					guint property_id,
					GValue *value,
					GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SERVICE_TYPE:
			g_value_set_gtype (
				value,
				e_gdata_oauth2_authorizer_get_service_type (
				E_GDATA_OAUTH2_AUTHORIZER (object)));
			return;

		case PROP_SOURCE:
			g_value_take_object (
				value,
				e_gdata_oauth2_authorizer_ref_source (
				E_GDATA_OAUTH2_AUTHORIZER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_gdata_oauth2_authorizer_dispose (GObject *object)
{
	EGDataOAuth2Authorizer *oauth2_authorizer;

	oauth2_authorizer = E_GDATA_OAUTH2_AUTHORIZER (object);

	g_weak_ref_set (&oauth2_authorizer->priv->source, NULL);

	g_hash_table_remove_all (oauth2_authorizer->priv->authorization_domains);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_gdata_oauth2_authorizer_parent_class)->dispose (object);
}

static void
e_gdata_oauth2_authorizer_finalize (GObject *object)
{
	EGDataOAuth2Authorizer *oauth2_authorizer;

	oauth2_authorizer = E_GDATA_OAUTH2_AUTHORIZER (object);

	g_free (oauth2_authorizer->priv->access_token);

	g_hash_table_destroy (oauth2_authorizer->priv->authorization_domains);
	g_weak_ref_clear (&oauth2_authorizer->priv->source);

	e_named_parameters_free (oauth2_authorizer->priv->credentials);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_gdata_oauth2_authorizer_parent_class)->finalize (object);
}

static void
e_gdata_oauth2_authorizer_constructed (GObject *object)
{
	EGDataOAuth2Authorizer *oauth2_authorizer;
	GList *domains, *link;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_gdata_oauth2_authorizer_parent_class)->constructed (object);

	oauth2_authorizer = E_GDATA_OAUTH2_AUTHORIZER (object);

	domains = gdata_service_get_authorization_domains (oauth2_authorizer->priv->service_type);
	for (link = domains; link; link = g_list_next (link)) {
		g_hash_table_add (
			oauth2_authorizer->priv->authorization_domains,
			g_object_ref (domains->data));
	}

	g_list_free (domains);
}

static void
e_gdata_oauth2_authorizer_process_request (GDataAuthorizer *authorizer,
					   GDataAuthorizationDomain *domain,
					   SoupMessage *message)
{
	EGDataOAuth2Authorizer *oauth2_authorizer;
	gchar *authorization;

	oauth2_authorizer = E_GDATA_OAUTH2_AUTHORIZER (authorizer);

	g_mutex_lock (&mutex);

	if (!e_gdata_oauth2_authorizer_is_authorized (authorizer, domain) ||
	    e_gdata_oauth2_authorizer_is_expired (oauth2_authorizer))
		goto exit;

	/* We can't add an Authorization header without an access token.
	 * Let the request fail.  GData should refresh us if it gets back
	 * a "401 Authorization required" response from Google, and then
	 * automatically retry the request. */
	if (!oauth2_authorizer->priv->access_token)
		goto exit;

	authorization = g_strdup_printf ("OAuth %s", oauth2_authorizer->priv->access_token);

	/* Use replace here, not append, to make sure
	 * there's only one "Authorization" header. */
	soup_message_headers_replace (
		message->request_headers,
		"Authorization", authorization);

	g_free (authorization);

exit:
	g_mutex_unlock (&mutex);
}

static gboolean
e_gdata_oauth2_authorizer_is_authorized_for_domain (GDataAuthorizer *authorizer,
						    GDataAuthorizationDomain *domain)
{
	gboolean authorized;

	g_mutex_lock (&mutex);

	authorized = e_gdata_oauth2_authorizer_is_authorized (authorizer, domain);

	g_mutex_unlock (&mutex);

	return authorized;
}

static gboolean
e_gdata_oauth2_authorizer_refresh_authorization (GDataAuthorizer *authorizer,
						 GCancellable *cancellable,
						 GError **error)
{
	EGDataOAuth2Authorizer *oauth2_authorizer;
	ESource *source;
	gchar *access_token = NULL;
	gint expires_in_seconds = -1;
	gboolean success = FALSE;

	oauth2_authorizer = E_GDATA_OAUTH2_AUTHORIZER (authorizer);
	source = e_gdata_oauth2_authorizer_ref_source (oauth2_authorizer);
	g_return_val_if_fail (source != NULL, FALSE);

	g_mutex_lock (&mutex);

	success = e_source_get_oauth2_access_token_sync (source, cancellable,
		&access_token, &expires_in_seconds, error);

	/* Returned token is the same, thus no refresh happened, thus rather fail. */
	if (access_token && g_strcmp0 (access_token, oauth2_authorizer->priv->access_token) == 0) {
		g_free (access_token);
		access_token = NULL;
		success = FALSE;
	}

	g_free (oauth2_authorizer->priv->access_token);
	oauth2_authorizer->priv->access_token = access_token;

	if (success && expires_in_seconds > 0)
		oauth2_authorizer->priv->expiry = time (NULL) + expires_in_seconds - 1;
	else
		oauth2_authorizer->priv->expiry = EXPIRY_INVALID;

	g_mutex_unlock (&mutex);

	g_object_unref (source);

	return success && access_token;
}

static void
e_gdata_oauth2_authorizer_class_init (EGDataOAuth2AuthorizerClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EGDataOAuth2AuthorizerPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = e_gdata_oauth2_authorizer_set_property;
	object_class->get_property = e_gdata_oauth2_authorizer_get_property;
	object_class->dispose = e_gdata_oauth2_authorizer_dispose;
	object_class->finalize = e_gdata_oauth2_authorizer_finalize;
	object_class->constructed = e_gdata_oauth2_authorizer_constructed;

	g_object_class_install_property (
		object_class,
		PROP_SERVICE_TYPE,
		g_param_spec_gtype (
			"service-type",
			"Service Type",
			"The service type for which this authorization will be used",
			GDATA_TYPE_SERVICE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_SOURCE,
		g_param_spec_object (
			"source",
			"Source",
			"The data source to authenticate",
			E_TYPE_SOURCE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));
}

static void
e_gdata_oauth2_authorizer_interface_init (GDataAuthorizerInterface *iface)
{
	iface->process_request = e_gdata_oauth2_authorizer_process_request;
	iface->is_authorized_for_domain = e_gdata_oauth2_authorizer_is_authorized_for_domain;
	iface->refresh_authorization = e_gdata_oauth2_authorizer_refresh_authorization;
}

static void
e_gdata_oauth2_authorizer_init (EGDataOAuth2Authorizer *oauth2_authorizer)
{
	oauth2_authorizer->priv = G_TYPE_INSTANCE_GET_PRIVATE (oauth2_authorizer, E_TYPE_GDATA_OAUTH2_AUTHORIZER, EGDataOAuth2AuthorizerPrivate);
	oauth2_authorizer->priv->authorization_domains = g_hash_table_new_full (g_direct_hash, g_direct_equal, g_object_unref, NULL);
	oauth2_authorizer->priv->expiry = EXPIRY_INVALID;
	g_weak_ref_init (&oauth2_authorizer->priv->source, NULL);
}

#else /* HAVE_LIBGDATA */

/* Define a fake object, thus GObject introspection code is happy even when
   libgdata support was disabled. */
G_DEFINE_TYPE (EGDataOAuth2Authorizer, e_gdata_oauth2_authorizer, G_TYPE_OBJECT)

static void
e_gdata_oauth2_authorizer_class_init (EGDataOAuth2AuthorizerClass *class)
{
}

static void
e_gdata_oauth2_authorizer_init (EGDataOAuth2Authorizer *oauth2_authorizer)
{
}

#endif /* HAVE_LIBGDATA */

/**
 * e_gdata_oauth2_authorizer_supported:
 *
 * Returns: Whether the #EGDataOAuth2Authorizer is supported, which
 *    means whether evolution-data-server had been compiled with libgdata.
 *
 * Since: 3.28
 **/
gboolean
e_gdata_oauth2_authorizer_supported (void)
{
#ifdef HAVE_LIBGDATA
	return TRUE;
#else
	return FALSE;
#endif
}

/**
 * e_gdata_oauth2_authorizer_new:
 * @source: an #ESource
 * @service_type: a #GDataService type descendant
 *
 * Creates a new #EGDataOAuth2Authorizer for the given @source
 * and @service_type. The function always returns %NULL when
 * e_gdata_oauth2_authorizer_supported() returns %FALSE.
 *
 * Returns: (transfer full): a new #EGDataOAuth2Authorizer, or %NULL when
 *    the #EGDataOAuth2Authorizer is not supported.
 *
 * Since: 3.28
 **/
EGDataOAuth2Authorizer *
e_gdata_oauth2_authorizer_new (ESource *source,
			       GType service_type)
{
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

#ifdef HAVE_LIBGDATA
	return g_object_new (E_TYPE_GDATA_OAUTH2_AUTHORIZER,
		"service-type", service_type,
		"source", source,
		NULL);
#else
	return NULL;
#endif
}

/**
 * e_gdata_oauth2_authorizer_ref_source:
 * @oauth2_authorizer: an #EGDataOAuth2Authorizer
 *
 * Returns: (transfer full): an #ESource, for which the @oauth2_authorizer
 *    had been created, or %NULL. Free returned non-NULL object with g_object_unref(),
 *    when done with it.
 *
 * See: e_gdata_oauth2_authorizer_supported()
 *
 * Since: 3.28
 **/
ESource *
e_gdata_oauth2_authorizer_ref_source (EGDataOAuth2Authorizer *oauth2_authorizer)
{
#ifdef HAVE_LIBGDATA
	g_return_val_if_fail (E_IS_GDATA_OAUTH2_AUTHORIZER (oauth2_authorizer), NULL);

	return g_weak_ref_get (&oauth2_authorizer->priv->source);
#else
	return NULL;
#endif
}

/**
 * e_gdata_oauth2_authorizer_get_service_type:
 * @oauth2_authorizer: an #EGDataOAuth2Authorizer
 *
 * Returns: a service %GType, for which the @oauth2_authorizer had been created.
 *
 * See: e_gdata_oauth2_authorizer_supported()
 *
 * Since: 3.28
 **/
GType
e_gdata_oauth2_authorizer_get_service_type (EGDataOAuth2Authorizer *oauth2_authorizer)
{
#ifdef HAVE_LIBGDATA
	g_return_val_if_fail (E_IS_GDATA_OAUTH2_AUTHORIZER (oauth2_authorizer), (GType) 0);

	return oauth2_authorizer->priv->service_type;
#else
	return (GType) 0;
#endif
}

/**
 * e_gdata_oauth2_authorizer_set_credentials:
 * @oauth2_authorizer: an #EGDataOAuth2Authorizer
 * @credentials: (nullable): credentials to set, or %NULL
 *
 * Updates internally stored credentials, used to get access token.
 *
 * See: e_gdata_oauth2_authorizer_supported()
 *
 * Since: 3.28
 **/
void
e_gdata_oauth2_authorizer_set_credentials (EGDataOAuth2Authorizer *oauth2_authorizer,
					   const ENamedParameters *credentials)
{
#ifdef HAVE_LIBGDATA
	g_return_if_fail (E_IS_GDATA_OAUTH2_AUTHORIZER (oauth2_authorizer));

	g_mutex_lock (&mutex);

	e_named_parameters_free (oauth2_authorizer->priv->credentials);
	if (credentials)
		oauth2_authorizer->priv->credentials = e_named_parameters_new_clone (credentials);
	else
		oauth2_authorizer->priv->credentials = NULL;

	g_free (oauth2_authorizer->priv->access_token);
	oauth2_authorizer->priv->access_token = NULL;

	oauth2_authorizer->priv->expiry = EXPIRY_INVALID;

	g_mutex_unlock (&mutex);
#endif
}

/**
 * e_gdata_oauth2_authorizer_clone_credentials:
 * @oauth2_authorizer: an #EGDataOAuth2Authorizer
 *
 * Returns: (transfer full) (nullable): A copy of currently stored credentials,
 *    or %NULL, when none are set. Free the returned structure with
 *    e_named_parameters_free(), when no longer needed.
 *
 * See: e_gdata_oauth2_authorizer_supported()
 *
 * Since: 3.28
 **/
ENamedParameters *
e_gdata_oauth2_authorizer_clone_credentials (EGDataOAuth2Authorizer *oauth2_authorizer)
{
#ifdef HAVE_LIBGDATA
	ENamedParameters *credentials = NULL;

	g_return_val_if_fail (E_IS_GDATA_OAUTH2_AUTHORIZER (oauth2_authorizer), NULL);

	g_mutex_lock (&mutex);

	if (oauth2_authorizer->priv->credentials)
		credentials = e_named_parameters_new_clone (oauth2_authorizer->priv->credentials);

	g_mutex_unlock (&mutex);

	return credentials;
#else
	return NULL;
#endif
}

/**
 * e_gdata_oauth2_authorizer_is_expired:
 * @oauth2_authorizer: an #EGDataOAuth2Authorizer
 *
 * Returns: Whether the internally stored token is expired.
 *
 * See: e_gdata_oauth2_authorizer_supported()
 *
 * Since: 3.28
 **/
gboolean
e_gdata_oauth2_authorizer_is_expired (EGDataOAuth2Authorizer *oauth2_authorizer)
{
#ifdef HAVE_LIBGDATA
	g_return_val_if_fail (E_IS_GDATA_OAUTH2_AUTHORIZER (oauth2_authorizer), TRUE);

	return oauth2_authorizer->priv->expiry == EXPIRY_INVALID ||
	       oauth2_authorizer->priv->expiry <= time (NULL);
#else
	return TRUE;
#endif
}
