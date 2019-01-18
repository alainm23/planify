/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
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

/**
 * SECTION: e-soup-session
 * @include: libedataserver/libedataserver.h
 * @short_description: A SoupSession descendant
 *
 * The #ESoupSession is a #SoupSession descendant, which hides common
 * tasks related to the way evolution-data-server works.
 **/

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <glib/gi18n-lib.h>

#include "e-oauth2-services.h"
#include "e-soup-auth-bearer.h"
#include "e-soup-ssl-trust.h"
#include "e-source-authentication.h"
#include "e-source-webdav.h"

#include "e-soup-session.h"

#define BUFFER_SIZE 16384

struct _ESoupSessionPrivate {
	GMutex property_lock;
	ESource *source;
	ENamedParameters *credentials;

	gboolean ssl_info_set;
	gchar *ssl_certificate_pem;
	GTlsCertificateFlags ssl_certificate_errors;

	SoupLoggerLogLevel log_level;

	GError *bearer_auth_error;
	ESoupAuthBearer *using_bearer_auth;

	gboolean auth_prefilled; /* When TRUE, the first 'retrying' is ignored in the "authenticate" handler */
};

enum {
	PROP_0,
	PROP_SOURCE,
	PROP_CREDENTIALS
};

G_DEFINE_TYPE (ESoupSession, e_soup_session, SOUP_TYPE_SESSION)

static void
e_soup_session_ensure_auth_usage (ESoupSession *session,
				  SoupURI *in_soup_uri,
				  SoupMessage *message,
				  SoupAuth *soup_auth)
{
	SoupSessionFeature *feature;
	SoupURI *soup_uri;
	GType auth_type;

	g_return_if_fail (E_IS_SOUP_SESSION (session));
	g_return_if_fail (SOUP_IS_AUTH (soup_auth));

	feature = soup_session_get_feature (SOUP_SESSION (session), SOUP_TYPE_AUTH_MANAGER);

	auth_type = G_OBJECT_TYPE (soup_auth);

	if (!soup_session_feature_has_feature (feature, auth_type)) {
		/* Add the SoupAuth type to support it. */
		soup_session_feature_add_feature (feature, auth_type);
	}

	if (in_soup_uri) {
		soup_uri = in_soup_uri;
	} else {
		soup_uri = message ? soup_message_get_uri (message) : NULL;
		if (soup_uri && soup_uri->host && *soup_uri->host) {
			soup_uri = soup_uri_copy_host (soup_uri);
		} else {
			soup_uri = NULL;
		}

		if (!soup_uri) {
			ESourceWebdav *extension;
			ESource *source;

			source = e_soup_session_get_source (session);
			extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
			soup_uri = e_source_webdav_dup_soup_uri (extension);
		}
	}

	soup_auth_manager_use_auth (SOUP_AUTH_MANAGER (feature), soup_uri, soup_auth);

	if (!in_soup_uri)
		soup_uri_free (soup_uri);
}

static gboolean
e_soup_session_setup_bearer_auth (ESoupSession *session,
				  SoupMessage *message,
				  gboolean is_in_authenticate_handler,
				  ESoupAuthBearer *bearer,
				  GCancellable *cancellable,
				  GError **error)
{
	ESource *source;
	gchar *access_token = NULL;
	gint expires_in_seconds = -1;
	gboolean success = FALSE;

	g_return_val_if_fail (E_IS_SOUP_SESSION (session), FALSE);
	g_return_val_if_fail (E_IS_SOUP_AUTH_BEARER (bearer), FALSE);

	source = e_soup_session_get_source (session);

	success = e_source_get_oauth2_access_token_sync (source, cancellable,
		&access_token, &expires_in_seconds, error);

	if (success) {
		e_soup_auth_bearer_set_access_token (bearer, access_token, expires_in_seconds);

		/* Preload the SoupAuthManager with a valid "Bearer" token
		 * when using OAuth 2.0. This avoids an extra unauthorized
		 * HTTP round-trip, which apparently Google doesn't like. */
		if (!is_in_authenticate_handler)
			e_soup_session_ensure_auth_usage (session, NULL, message, SOUP_AUTH (bearer));
	}

	g_free (access_token);

	return success;
}

static gboolean
e_soup_session_maybe_prepare_bearer_auth (ESoupSession *session,
					  SoupURI *soup_uri,
					  SoupMessage *message,
					  GCancellable *cancellable,
					  GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_SOUP_SESSION (session), FALSE);
	g_return_val_if_fail (soup_uri != NULL, FALSE);

	g_mutex_lock (&session->priv->property_lock);
	if (session->priv->using_bearer_auth) {
		ESoupAuthBearer *using_bearer_auth = g_object_ref (session->priv->using_bearer_auth);

		g_mutex_unlock (&session->priv->property_lock);

		success = e_soup_session_setup_bearer_auth (session, message, FALSE, using_bearer_auth, cancellable, error);

		g_clear_object (&using_bearer_auth);
	} else {
		SoupAuth *soup_auth;

		g_mutex_unlock (&session->priv->property_lock);

		soup_auth = g_object_new (
			E_TYPE_SOUP_AUTH_BEARER,
			SOUP_AUTH_HOST, soup_uri->host, NULL);

		success = e_soup_session_setup_bearer_auth (session, message, FALSE, E_SOUP_AUTH_BEARER (soup_auth), cancellable, error);
		if (success) {
			g_mutex_lock (&session->priv->property_lock);
			g_clear_object (&session->priv->using_bearer_auth);
			session->priv->using_bearer_auth = g_object_ref (soup_auth);
			g_mutex_unlock (&session->priv->property_lock);
		}

		g_object_unref (soup_auth);
	}

	return success;
}

static gboolean
e_soup_session_maybe_prepare_basic_auth (ESoupSession *session,
					 SoupURI *soup_uri,
					 SoupMessage *message,
					 const gchar *in_username,
					 const ENamedParameters *credentials,
					 GCancellable *cancellable,
					 GError **error)
{
	SoupAuth *soup_auth;
	const gchar *username;

	g_return_val_if_fail (E_IS_SOUP_SESSION (session), FALSE);
	g_return_val_if_fail (soup_uri != NULL, FALSE);

	if (!credentials || !e_named_parameters_exists (credentials, E_SOURCE_CREDENTIAL_PASSWORD)) {
		/* This error message won't get into the UI */
		g_set_error_literal (error, SOUP_HTTP_ERROR, SOUP_STATUS_UNAUTHORIZED, soup_status_get_phrase (SOUP_STATUS_UNAUTHORIZED));
		return FALSE;
	}

	username = e_named_parameters_get (credentials, E_SOURCE_CREDENTIAL_USERNAME);
	if (!username || !*username)
		username = in_username;

	soup_auth = soup_auth_new (SOUP_TYPE_AUTH_BASIC, message, "Basic");

	soup_auth_authenticate (soup_auth, username, e_named_parameters_get (credentials, E_SOURCE_CREDENTIAL_PASSWORD));

	g_mutex_lock (&session->priv->property_lock);
	session->priv->auth_prefilled = TRUE;
	g_mutex_unlock (&session->priv->property_lock);

	e_soup_session_ensure_auth_usage (session, soup_uri, message, soup_auth);

	g_clear_object (&soup_auth);

	return TRUE;
}

static gboolean
e_soup_session_maybe_prepare_auth (ESoupSession *session,
				   SoupRequestHTTP *request,
				   GCancellable *cancellable,
				   GError **error)
{
	ESource *source;
	ENamedParameters *credentials;
	SoupMessage *message;
	SoupURI *soup_uri;
	gchar *auth_method = NULL, *user = NULL;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_SOUP_SESSION (session), FALSE);

	source = e_soup_session_get_source (session);

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
		ESourceAuthentication *extension;

		extension = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);
		auth_method = e_source_authentication_dup_method (extension);
		user = e_source_authentication_dup_user (extension);
	} else {
		return TRUE;
	}

	credentials = e_soup_session_dup_credentials (session);
	message = soup_request_http_get_message (request);
	soup_uri = message ? soup_message_get_uri (message) : NULL;
	if (soup_uri && soup_uri->host && *soup_uri->host) {
		soup_uri = soup_uri_copy_host (soup_uri);
	} else {
		soup_uri = NULL;
	}

	if (!soup_uri) {
		ESourceWebdav *extension;

		extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
		soup_uri = e_source_webdav_dup_soup_uri (extension);
	}

	g_mutex_lock (&session->priv->property_lock);
	session->priv->auth_prefilled = FALSE;
	g_mutex_unlock (&session->priv->property_lock);

	if (g_strcmp0 (auth_method, "OAuth2") == 0 ||
	    e_oauth2_services_is_oauth2_alias_static (auth_method)) {
		success = e_soup_session_maybe_prepare_bearer_auth (session, soup_uri, message, cancellable, error);
	} else if (user && *user) {
		/* Default to Basic authentication when user is filled */
		success = e_soup_session_maybe_prepare_basic_auth (session, soup_uri, message, user, credentials, cancellable, error);
	}

	e_named_parameters_free (credentials);
	g_clear_object (&message);
	soup_uri_free (soup_uri);
	g_free (auth_method);
	g_free (user);

	return success;
}

static void
e_soup_session_authenticate_cb (SoupSession *soup_session,
				SoupMessage *message,
				SoupAuth *auth,
				gboolean retrying,
				gpointer user_data)
{
	ESoupSession *session;
	const gchar *username;
	ENamedParameters *credentials;
	gchar *auth_user = NULL;

	g_return_if_fail (E_IS_SOUP_SESSION (soup_session));

	session = E_SOUP_SESSION (soup_session);

	if (E_IS_SOUP_AUTH_BEARER (auth)) {
		g_object_ref (auth);
		g_warn_if_fail ((gpointer) session->priv->using_bearer_auth == (gpointer) auth);
		g_clear_object (&session->priv->using_bearer_auth);
		session->priv->using_bearer_auth = E_SOUP_AUTH_BEARER (auth);
	}

	g_mutex_lock (&session->priv->property_lock);
	if (retrying && !session->priv->auth_prefilled) {
		g_mutex_unlock (&session->priv->property_lock);
		return;
	}
	session->priv->auth_prefilled = FALSE;
	g_mutex_unlock (&session->priv->property_lock);

	if (session->priv->using_bearer_auth) {
		GError *local_error = NULL;

		e_soup_session_setup_bearer_auth (session, message, TRUE, E_SOUP_AUTH_BEARER (auth), NULL, &local_error);

		if (local_error) {
			g_mutex_lock (&session->priv->property_lock);

			/* Warn about an unclaimed error before we clear it.
			 * This is just to verify the errors we set here are
			 * actually making it back to the user. */
			g_warn_if_fail (session->priv->bearer_auth_error == NULL);
			g_clear_error (&session->priv->bearer_auth_error);

			g_propagate_error (&session->priv->bearer_auth_error, local_error);

			g_mutex_unlock (&session->priv->property_lock);
		}

		return;
	}

	credentials = e_soup_session_dup_credentials (session);

	username = credentials ? e_named_parameters_get (credentials, E_SOURCE_CREDENTIAL_USERNAME) : NULL;
	if ((!username || !*username) &&
	    e_source_has_extension (session->priv->source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
		ESourceAuthentication *auth_extension;

		auth_extension = e_source_get_extension (session->priv->source, E_SOURCE_EXTENSION_AUTHENTICATION);
		auth_user = e_source_authentication_dup_user (auth_extension);

		username = auth_user;
	}

	if (!username || !*username || !credentials ||
	    !e_named_parameters_exists (credentials, E_SOURCE_CREDENTIAL_PASSWORD))
		soup_message_set_status (message, SOUP_STATUS_UNAUTHORIZED);
	else
		soup_auth_authenticate (auth, username, e_named_parameters_get (credentials, E_SOURCE_CREDENTIAL_PASSWORD));

	e_named_parameters_free (credentials);
	g_free (auth_user);
}

static void
e_soup_session_set_source (ESoupSession *session,
			   ESource *source)
{
	g_return_if_fail (E_IS_SOUP_SESSION (session));
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (!session->priv->source);

	session->priv->source = g_object_ref (source);
}

static void
e_soup_session_set_property (GObject *object,
			     guint property_id,
			     const GValue *value,
			     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SOURCE:
			e_soup_session_set_source (
				E_SOUP_SESSION (object),
				g_value_get_object (value));
			return;

		case PROP_CREDENTIALS:
			e_soup_session_set_credentials (
				E_SOUP_SESSION (object),
				g_value_get_boxed (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_soup_session_get_property (GObject *object,
			     guint property_id,
			     GValue *value,
			     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SOURCE:
			g_value_set_object (
				value,
				e_soup_session_get_source (
				E_SOUP_SESSION (object)));
			return;

		case PROP_CREDENTIALS:
			g_value_take_boxed (
				value,
				e_soup_session_dup_credentials (
				E_SOUP_SESSION (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_soup_session_finalize (GObject *object)
{
	ESoupSession *session = E_SOUP_SESSION (object);

	g_clear_error (&session->priv->bearer_auth_error);
	g_clear_object (&session->priv->source);
	g_clear_object (&session->priv->using_bearer_auth);
	g_clear_pointer (&session->priv->credentials, e_named_parameters_free);
	g_clear_pointer (&session->priv->ssl_certificate_pem, g_free);

	g_mutex_clear (&session->priv->property_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_soup_session_parent_class)->finalize (object);
}

static void
e_soup_session_class_init (ESoupSessionClass *klass)
{
	GObjectClass *object_class;

	g_type_class_add_private (klass, sizeof (ESoupSessionPrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->set_property = e_soup_session_set_property;
	object_class->get_property = e_soup_session_get_property;
	object_class->finalize = e_soup_session_finalize;

	/**
	 * ESoupSession:source:
	 *
	 * The #ESource being used for this soup session.
	 *
	 * Since: 3.26
	 **/
	g_object_class_install_property (
		object_class,
		PROP_SOURCE,
		g_param_spec_object (
			"source",
			"Source",
			NULL,
			E_TYPE_SOURCE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ESoupSession:credentials:
	 *
	 * The #ENamedParameters containing login credentials.
	 *
	 * Since: 3.26
	 **/
	g_object_class_install_property (
		object_class,
		PROP_CREDENTIALS,
		g_param_spec_boxed (
			"credentials",
			"Credentials",
			NULL,
			E_TYPE_NAMED_PARAMETERS,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));
}

static void
e_soup_session_init (ESoupSession *session)
{
	session->priv = G_TYPE_INSTANCE_GET_PRIVATE (session, E_TYPE_SOUP_SESSION, ESoupSessionPrivate);
	session->priv->ssl_info_set = FALSE;
	session->priv->log_level = SOUP_LOGGER_LOG_NONE;
	session->priv->auth_prefilled = FALSE;

	g_mutex_init (&session->priv->property_lock);

	g_object_set (
		G_OBJECT (session),
		SOUP_SESSION_TIMEOUT, 90,
		SOUP_SESSION_SSL_STRICT, TRUE,
		SOUP_SESSION_SSL_USE_SYSTEM_CA_FILE, TRUE,
		SOUP_SESSION_ACCEPT_LANGUAGE_AUTO, TRUE,
		NULL);

	g_signal_connect (session, "authenticate",
		G_CALLBACK (e_soup_session_authenticate_cb), NULL);
}

/**
 * e_soup_session_new:
 * @source: an #ESource
 *
 * Creates a new #ESoupSession associated with given @source.
 * The @source can be used to store and read SSL trust settings, but only if
 * it already contains an #ESourceWebdav extension. Otherwise the SSL trust
 * settings are ignored.
 *
 * Returns: (transfer full): a new #ESoupSession; free it with g_object_unref(),
 *    when no longer needed.
 *
 * Since: 3.26
 **/
ESoupSession *
e_soup_session_new (ESource *source)
{
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	return g_object_new (E_TYPE_SOUP_SESSION,
		"source", source,
		NULL);
}

/**
 * e_soup_session_setup_logging:
 * @session: an #ESoupSession
 * @logging_level: (nullable): logging level to setup, or %NULL
 *
 * Setups logging for the @session. The @logging_level can be one of:
 * "all" - log whole raw communication;
 * "body" - the same as "all";
 * "headers" - log the headers only;
 * "min" - minimal logging;
 * "1" - the same as "all".
 * Any other value, including %NULL, disables logging.
 *
 * Use e_soup_session_get_log_level() to get current log level.
 *
 * Since: 3.26
 **/
void
e_soup_session_setup_logging (ESoupSession *session,
			      const gchar *logging_level)
{
	SoupLogger *logger;

	g_return_if_fail (E_IS_SOUP_SESSION (session));

	soup_session_remove_feature_by_type (SOUP_SESSION (session), SOUP_TYPE_LOGGER);
	session->priv->log_level = SOUP_LOGGER_LOG_NONE;

	if (!logging_level)
		return;

	if (g_ascii_strcasecmp (logging_level, "all") == 0 ||
	    g_ascii_strcasecmp (logging_level, "body") == 0 ||
	    g_ascii_strcasecmp (logging_level, "1") == 0)
		session->priv->log_level = SOUP_LOGGER_LOG_BODY;
	else if (g_ascii_strcasecmp (logging_level, "headers") == 0)
		session->priv->log_level = SOUP_LOGGER_LOG_HEADERS;
	else if (g_ascii_strcasecmp (logging_level, "min") == 0)
		session->priv->log_level = SOUP_LOGGER_LOG_MINIMAL;
	else
		return;

	logger = soup_logger_new (session->priv->log_level, -1);
	soup_session_add_feature (SOUP_SESSION (session), SOUP_SESSION_FEATURE (logger));
	g_object_unref (logger);
}

/**
 * e_soup_session_get_log_level:
 * @session: an #ESoupSession
 *
 * Returns: Current log level, as #SoupLoggerLogLevel
 *
 * Since: 3.26
 **/
SoupLoggerLogLevel
e_soup_session_get_log_level (ESoupSession *session)
{
	g_return_val_if_fail (E_IS_SOUP_SESSION (session), SOUP_LOGGER_LOG_NONE);

	return session->priv->log_level;
}

/**
 * e_soup_session_get_source:
 * @session: an #ESoupSession
 *
 * Returns: (transfer none): Associated #ESource with the @session.
 *
 * Since: 3.26
 **/
ESource *
e_soup_session_get_source (ESoupSession *session)
{
	g_return_val_if_fail (E_IS_SOUP_SESSION (session), NULL);

	return session->priv->source;
}

/**
 * e_soup_session_set_credentials:
 * @session: an #ESoupSession
 * @credentials: (nullable): an #ENamedParameters with credentials to use, or %NULL
 *
 * Sets credentials to use for connection. Using %NULL for @credentials
 * unsets previous value.
 *
 * Since: 3.26
 **/
void
e_soup_session_set_credentials (ESoupSession *session,
				const ENamedParameters *credentials)
{
	g_return_if_fail (E_IS_SOUP_SESSION (session));

	g_mutex_lock (&session->priv->property_lock);

	if (credentials == session->priv->credentials) {
		g_mutex_unlock (&session->priv->property_lock);
		return;
	}

	e_named_parameters_free (session->priv->credentials);
	if (credentials)
		session->priv->credentials = e_named_parameters_new_clone (credentials);
	else
		session->priv->credentials = NULL;

	g_mutex_unlock (&session->priv->property_lock);

	g_object_notify (G_OBJECT (session), "credentials");
}

/**
 * e_soup_session_dup_credentials:
 * @session: an #ESoupSession
 *
 * Returns: (nullable) (transfer full): A copy of the credentials being
 *    previously set with e_soup_session_set_credentials(), or %NULL when
 *    none are set. Free the returned pointer with e_named_parameters_free(),
 *    when no longer needed.
 *
 * Since: 3.26
 **/
ENamedParameters *
e_soup_session_dup_credentials (ESoupSession *session)
{
	ENamedParameters *credentials;

	g_return_val_if_fail (E_IS_SOUP_SESSION (session), NULL);

	g_mutex_lock (&session->priv->property_lock);

	if (session->priv->credentials)
		credentials = e_named_parameters_new_clone (session->priv->credentials);
	else
		credentials = NULL;

	g_mutex_unlock (&session->priv->property_lock);

	return credentials;
}

/**
 * e_soup_session_get_authentication_requires_credentials:
 * @session: an #ESoupSession
 *
 * Returns: Whether the last connection attempt required any credentials.
 *    Authentications like OAuth2 do not want extra credentials to work.
 *
 * Since: 3.28
 **/
gboolean
e_soup_session_get_authentication_requires_credentials (ESoupSession *session)
{
	g_return_val_if_fail (E_IS_SOUP_SESSION (session), FALSE);

	return !session->priv->using_bearer_auth;
}

/**
 * e_soup_session_get_ssl_error_details:
 * @session: an #ESoupSession
 * @out_certificate_pem: (out): return location for a server TLS/SSL certificate
 *   in PEM format, when the last operation failed with a TLS/SSL error
 * @out_certificate_errors: (out): return location for a #GTlsCertificateFlags,
 *   with certificate error flags when the the operation failed with a TLS/SSL error
 *
 * Populates @out_certificate_pem and @out_certificate_errors with the last values
 * returned on #SOUP_STATUS_SSL_FAILED error.
 *
 * Returns: Whether the information was available and set to the out parameters.
 *
 * Since: 3.26
 **/
gboolean
e_soup_session_get_ssl_error_details (ESoupSession *session,
				      gchar **out_certificate_pem,
				      GTlsCertificateFlags *out_certificate_errors)
{
	g_return_val_if_fail (E_IS_SOUP_SESSION (session), FALSE);
	g_return_val_if_fail (out_certificate_pem != NULL, FALSE);
	g_return_val_if_fail (out_certificate_errors != NULL, FALSE);

	g_mutex_lock (&session->priv->property_lock);
	if (!session->priv->ssl_info_set) {
		g_mutex_unlock (&session->priv->property_lock);
		return FALSE;
	}

	*out_certificate_pem = g_strdup (session->priv->ssl_certificate_pem);
	*out_certificate_errors = session->priv->ssl_certificate_errors;

	g_mutex_unlock (&session->priv->property_lock);

	return TRUE;
}

static void
e_soup_session_preset_request (SoupRequestHTTP *request)
{
	SoupMessage *message;

	if (!request)
		return;

	message = soup_request_http_get_message (request);
	if (message) {
		soup_message_headers_append (message->request_headers, "User-Agent", "Evolution/" VERSION);
		soup_message_headers_append (message->request_headers, "Connection", "close");

		/* Disable caching for proxies (RFC 4918, section 10.4.5) */
		soup_message_headers_append (message->request_headers, "Cache-Control", "no-cache");
		soup_message_headers_append (message->request_headers, "Pragma", "no-cache");

		g_clear_object (&message);
	}
}

/**
 * e_soup_session_new_request:
 * @session: an #ESoupSession
 * @method: an HTTP method
 * @uri_string: a URI string to use for the request
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #SoupRequestHTTP, similar to soup_session_request_http(),
 * but also presets request headers with "User-Agent" to be "Evolution/version"
 * and with "Connection" to be "close".
 *
 * See also e_soup_session_new_request_uri().
 *
 * Returns: (transfer full): a new #SoupRequestHTTP, or %NULL on error
 *
 * Since: 3.26
 **/
SoupRequestHTTP *
e_soup_session_new_request (ESoupSession *session,
			    const gchar *method,
			    const gchar *uri_string,
			    GError **error)
{
	SoupRequestHTTP *request;

	g_return_val_if_fail (E_IS_SOUP_SESSION (session), NULL);

	request = soup_session_request_http (SOUP_SESSION (session), method, uri_string, error);
	if (!request)
		return NULL;

	e_soup_session_preset_request (request);

	return request;
}

/**
 * e_soup_session_new_request_uri:
 * @session: an #ESoupSession
 * @method: an HTTP method
 * @uri: a #SoupURI to use for the request
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #SoupRequestHTTP, similar to soup_session_request_http_uri(),
 * but also presets request headers with "User-Agent" to be "Evolution/version"
 * and with "Connection" to be "close".
 *
 * See also e_soup_session_new_request().
 *
 * Returns: (transfer full): a new #SoupRequestHTTP, or %NULL on error
 *
 * Since: 3.26
 **/
SoupRequestHTTP *
e_soup_session_new_request_uri (ESoupSession *session,
				const gchar *method,
				SoupURI *uri,
				GError **error)
{
	SoupRequestHTTP *request;

	g_return_val_if_fail (E_IS_SOUP_SESSION (session), NULL);

	request = soup_session_request_http_uri (SOUP_SESSION (session), method, uri, error);
	if (!request)
		return NULL;

	e_soup_session_preset_request (request);

	return request;
}

static void
e_soup_session_extract_ssl_data (ESoupSession *session,
				 SoupMessage *message)
{
	GTlsCertificate *certificate = NULL;

	g_return_if_fail (E_IS_SOUP_SESSION (session));
	g_return_if_fail (SOUP_IS_MESSAGE (message));

	g_mutex_lock (&session->priv->property_lock);

	g_clear_pointer (&session->priv->ssl_certificate_pem, g_free);
	session->priv->ssl_info_set = FALSE;

	g_object_get (G_OBJECT (message),
		"tls-certificate", &certificate,
		"tls-errors", &session->priv->ssl_certificate_errors,
		NULL);

	if (certificate) {
		g_object_get (certificate, "certificate-pem", &session->priv->ssl_certificate_pem, NULL);
		session->priv->ssl_info_set = TRUE;

		g_object_unref (certificate);
	}

	g_mutex_unlock (&session->priv->property_lock);
}

static gboolean
e_soup_session_extract_google_daily_limit_error (SoupMessage *message,
						 GError **error)
{
	gchar *body;
	gboolean contains_daily_limit = FALSE;

	if (!message || !message->response_body ||
	    !message->response_body->data || !message->response_body->length)
		return FALSE;

	body = g_strndup (message->response_body->data, message->response_body->length);

	/* Do not localize this string, it is returned by the server. */
	if (body && (e_util_strstrcase (body, "Daily Limit") ||
	    e_util_strstrcase (body, "https://console.developers.google.com/"))) {
		/* Special-case this condition and provide this error up to the UI. */
		g_set_error_literal (error, SOUP_HTTP_ERROR, SOUP_STATUS_FORBIDDEN, body);
		contains_daily_limit = TRUE;
	}

	g_free (body);

	return contains_daily_limit;
}

/**
 * e_soup_session_check_result:
 * @session: an #ESoupSession
 * @request: a #SoupRequestHTTP
 * @read_bytes: (nullable): optional bytes which had been read from the stream, or %NULL
 * @bytes_length: how many bytes had been read; ignored when @read_bytes is %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Checks result of the @request and sets the @error if it failed.
 * When it failed and the @read_bytes is provided, then these are
 * set to @request's message response_body, thus it can be used
 * later.
 *
 * Returns: Whether succeeded, aka %TRUE, when no error recognized
 *    and %FALSE otherwise.
 *
 * Since: 3.26
 **/
gboolean
e_soup_session_check_result (ESoupSession *session,
			     SoupRequestHTTP *request,
			     gconstpointer read_bytes,
			     gsize bytes_length,
			     GError **error)
{
	SoupMessage *message;
	gboolean success;

	g_return_val_if_fail (E_IS_SOUP_SESSION (session), FALSE);
	g_return_val_if_fail (SOUP_IS_REQUEST_HTTP (request), FALSE);

	message = soup_request_http_get_message (request);
	g_return_val_if_fail (SOUP_IS_MESSAGE (message), FALSE);

	success = SOUP_STATUS_IS_SUCCESSFUL (message->status_code);
	if (!success) {
		if (read_bytes && bytes_length > 0) {
			SoupBuffer *buffer;

			soup_message_body_append (message->response_body, SOUP_MEMORY_COPY, read_bytes, bytes_length);

			/* This writes data to message->response_body->data */
			buffer = soup_message_body_flatten (message->response_body);
			if (buffer)
				soup_buffer_free (buffer);
		}

		if (message->status_code == SOUP_STATUS_CANCELLED) {
			g_set_error_literal (error, G_IO_ERROR, G_IO_ERROR_CANCELLED, _("Operation was cancelled"));
		} else if (message->status_code == SOUP_STATUS_FORBIDDEN &&
			   e_soup_session_extract_google_daily_limit_error (message, error)) {
			/* Nothing to do */
		} else {
			g_set_error (error, SOUP_HTTP_ERROR, message->status_code,
				_("Failed with HTTP error %d: %s"), message->status_code,
				e_soup_session_util_status_to_string (message->status_code, message->reason_phrase));
		}

		if (message->status_code == SOUP_STATUS_SSL_FAILED)
			e_soup_session_extract_ssl_data (session, message);
	}

	g_object_unref (message);

	return success;
}

/**
 * e_soup_session_send_request_sync:
 * @session: an #ESoupSession
 * @request: a #SoupRequestHTTP to send
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Synchronously sends prepared request and returns #GInputStream
 * that can be used to read its contents.
 *
 * This calls soup_request_send() internally, but it also setups
 * the request according to #ESoupSession:source authentication
 * settings. It also extracts information about used certificate,
 * in case of SOUP_STATUS_SSL_FAILED error and keeps it for later use
 * by e_soup_session_get_ssl_error_details().
 *
 * Use e_soup_session_send_request_simple_sync() to read whole
 * content into a #GByteArray.
 *
 * Note that SoupSession doesn't log content read from GInputStream,
 * thus the caller may print the read content on its own when needed.
 *
 * Note the @request is fully filled only after there is anything
 * read from the resulting #GInputStream, thus use
 * e_soup_session_check_result() to verify that the receive had
 * been finished properly.
 *
 * Returns: (transfer full): A newly allocated #GInputStream,
 *    that can be used to read from the URI pointed to by @request.
 *    Free it with g_object_unref(), when no longer needed.
 *
 * Since: 3.26
 **/
GInputStream *
e_soup_session_send_request_sync (ESoupSession *session,
				  SoupRequestHTTP *request,
				  GCancellable *cancellable,
				  GError **error)
{
	ESoupAuthBearer *using_bearer_auth = NULL;
	GInputStream *input_stream;
	SoupMessage *message;
	gboolean redirected;
	gint resend_count = 0;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_SOUP_SESSION (session), NULL);
	g_return_val_if_fail (SOUP_IS_REQUEST_HTTP (request), NULL);

	if (!e_soup_session_maybe_prepare_auth (session, request, cancellable, error))
		return NULL;

	g_mutex_lock (&session->priv->property_lock);
	g_clear_pointer (&session->priv->ssl_certificate_pem, g_free);
	session->priv->ssl_certificate_errors = 0;
	session->priv->ssl_info_set = FALSE;
	if (session->priv->using_bearer_auth)
		using_bearer_auth = g_object_ref (session->priv->using_bearer_auth);
	g_mutex_unlock (&session->priv->property_lock);

	if (session->priv->source &&
	    e_source_has_extension (session->priv->source, E_SOURCE_EXTENSION_WEBDAV_BACKEND)) {
		message = soup_request_http_get_message (request);

		e_soup_ssl_trust_connect (message, session->priv->source);

		g_clear_object (&message);
	}

	if (using_bearer_auth &&
	    e_soup_auth_bearer_is_expired (using_bearer_auth)) {
		message = soup_request_http_get_message (request);

		if (!e_soup_session_setup_bearer_auth (session, message, FALSE, using_bearer_auth, cancellable, &local_error)) {
			if (local_error) {
				soup_message_set_status_full (message, SOUP_STATUS_BAD_REQUEST, local_error->message);
				g_propagate_error (error, local_error);
			} else {
				soup_message_set_status (message, SOUP_STATUS_BAD_REQUEST);
			}

			g_object_unref (using_bearer_auth);
			g_clear_object (&message);

			return NULL;
		}

		g_clear_object (&message);
	}

	g_clear_object (&using_bearer_auth);

	redirected = TRUE;
	while (redirected) {
		redirected = FALSE;

		input_stream = soup_request_send (SOUP_REQUEST (request), cancellable, &local_error);
		if (input_stream) {
			message = soup_request_http_get_message (request);

			if (message && SOUP_STATUS_IS_REDIRECTION (message->status_code)) {
				/* libsoup uses 20, but the constant is not in any public header */
				if (resend_count >= 30) {
					soup_message_set_status (message, SOUP_STATUS_TOO_MANY_REDIRECTS);
				} else {
					const gchar *new_location;

					new_location = soup_message_headers_get_list (message->response_headers, "Location");
					if (new_location) {
						SoupURI *new_uri;

						new_uri = soup_uri_new_with_base (soup_message_get_uri (message), new_location);

						soup_message_set_uri (message, new_uri);

						g_clear_object (&input_stream);
						soup_uri_free (new_uri);

						g_signal_emit_by_name (message, "restarted");

						resend_count++;
						redirected = TRUE;
					}
				}
			}

			g_clear_object (&message);
		}
	}

	if (input_stream)
		return input_stream;

	if (g_error_matches (local_error, G_TLS_ERROR, G_TLS_ERROR_BAD_CERTIFICATE)) {
		local_error->domain = SOUP_HTTP_ERROR;
		local_error->code = SOUP_STATUS_SSL_FAILED;
	}

	if (g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_SSL_FAILED)) {
		message = soup_request_http_get_message (request);

		e_soup_session_extract_ssl_data (session, message);

		g_clear_object (&message);
	} else if (g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_FORBIDDEN)) {
		message = soup_request_http_get_message (request);

		if (e_soup_session_extract_google_daily_limit_error (message, error))
			g_clear_error (&local_error);

		g_clear_object (&message);
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return NULL;
}

/**
 * e_soup_session_send_request_simple_sync:
 * @session: an #ESoupSession
 * @request: a #SoupRequestHTTP to send
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Similar to e_soup_session_send_request_sync(), except it reads
 * whole response content into memory and returns it as a #GByteArray.
 * Use e_soup_session_send_request_sync() when you want to have
 * more control on the content read.
 *
 * The function prints read content to stdout when
 * e_soup_session_get_log_level() returns #SOUP_LOGGER_LOG_BODY.
 *
 * Returns: (transfer full): A newly allocated #GByteArray,
 *    which contains whole content from the URI pointed to by @request.
 *
 * Since: 3.26
 **/
GByteArray *
e_soup_session_send_request_simple_sync (ESoupSession *session,
					 SoupRequestHTTP *request,
					 GCancellable *cancellable,
					 GError **error)
{
	GInputStream *input_stream;
	GByteArray *bytes;
	gint expected_length;
	gpointer buffer;
	gsize nread = 0;
	gboolean success = FALSE;

	g_return_val_if_fail (E_IS_SOUP_SESSION (session), NULL);
	g_return_val_if_fail (SOUP_IS_REQUEST_HTTP (request), NULL);

	input_stream = e_soup_session_send_request_sync (session, request, cancellable, error);
	if (!input_stream)
		return NULL;

	expected_length = soup_request_get_content_length (SOUP_REQUEST (request));
	if (expected_length > 0)
		bytes = g_byte_array_sized_new (expected_length);
	else
		bytes = g_byte_array_new ();

	buffer = g_malloc (BUFFER_SIZE);

	while (success = g_input_stream_read_all (input_stream, buffer, BUFFER_SIZE, &nread, cancellable, error),
	       success && nread > 0) {
		g_byte_array_append (bytes, buffer, nread);
	}

	g_free (buffer);
	g_object_unref (input_stream);

	if (bytes->len > 0 && e_soup_session_get_log_level (session) == SOUP_LOGGER_LOG_BODY) {
		fwrite (bytes->data, 1, bytes->len, stdout);
		fprintf (stdout, "\n");
		fflush (stdout);
	}

	if (success)
		success = e_soup_session_check_result (session, request, bytes->data, bytes->len, error);

	if (!success) {
		g_byte_array_free (bytes, TRUE);
		bytes = NULL;
	}

	return bytes;
}

/**
 * e_soup_session_util_status_to_string:
 * @status_code: an HTTP status code
 * @reason_phrase: (nullable): preferred string to use for the message, or %NULL
 *
 * Returns the @reason_phrase, if it's non-%NULL and non-empty, a static string
 * corresponding to @status_code. In case neither that can be found a localized
 * "Unknown error" message is returned.
 *
 * Returns: (transfer none): Error text based on given arguments. The returned
 *    value is valid as long as @reason_phrase is not freed.
 *
 * Since: 3.26
 **/
const gchar *
e_soup_session_util_status_to_string (guint status_code,
				      const gchar *reason_phrase)
{
	if (!reason_phrase || !*reason_phrase)
		reason_phrase = soup_status_get_phrase (status_code);

	if (reason_phrase && *reason_phrase)
		return reason_phrase;

	return _("Unknown error");
}
