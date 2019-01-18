/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-pop3-store.c : class for a pop3 store
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
 * Authors: Dan Winship <danw@ximian.com>
 *          Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <ctype.h>

#include <glib/gi18n-lib.h>

#include "camel-pop3-folder.h"
#include "camel-pop3-settings.h"
#include "camel-pop3-store.h"

#ifdef G_OS_WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#endif

#define CAMEL_POP3_STORE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_POP3_STORE, CamelPOP3StorePrivate))

/* Specified in RFC 1939 */
#define POP3_PORT  110
#define POP3S_PORT 995

/* defines the length of the server error message we can display in the error dialog */
#define POP3_ERROR_SIZE_LIMIT 60

struct _CamelPOP3StorePrivate {
	GMutex property_lock;
	CamelDataCache *cache;
	CamelPOP3Engine *engine;
};

enum {
	PROP_0,
	PROP_CONNECTABLE,
	PROP_HOST_REACHABLE
};

extern CamelServiceAuthType camel_pop3_password_authtype;
extern CamelServiceAuthType camel_pop3_apop_authtype;

/* Forward Declarations */
static void camel_network_service_init (CamelNetworkServiceInterface *iface);

G_DEFINE_TYPE_WITH_CODE (
	CamelPOP3Store,
	camel_pop3_store,
	CAMEL_TYPE_STORE,
	G_IMPLEMENT_INTERFACE (
		CAMEL_TYPE_NETWORK_SERVICE,
		camel_network_service_init))

/* returns error message with ': ' as prefix */
static gchar *
get_valid_utf8_error (const gchar *text)
{
	gchar *tmp = camel_utf8_make_valid (text);
	gchar *ret = NULL;

	/*TODO If the error message > size limit log it somewhere */
	if (!tmp || g_utf8_strlen (tmp, -1) > POP3_ERROR_SIZE_LIMIT) {
		g_free (tmp);
		return NULL;
	}

	/* Translators: This is the separator between an error and an explanation */
	ret = g_strconcat (_(": "), tmp, NULL);

	g_free (tmp);
	return ret;
}

static gboolean
connect_to_server (CamelService *service,
                   GCancellable *cancellable,
                   GError **error)
{
	CamelPOP3Store *store = CAMEL_POP3_STORE (service);
	CamelNetworkSettings *network_settings;
	CamelNetworkSecurityMethod method;
	CamelSettings *settings;
	CamelStream *stream = NULL;
	CamelPOP3Engine *pop3_engine = NULL;
	CamelPOP3Command *pc;
	GIOStream *base_stream;
	GIOStream *tls_stream;
	gboolean disable_extensions;
	gboolean success = TRUE;
	gchar *host;
	guint32 flags = 0;
	gint ret;
	GError *local_error = NULL;

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	method = camel_network_settings_get_security_method (network_settings);

	disable_extensions = camel_pop3_settings_get_disable_extensions (
		CAMEL_POP3_SETTINGS (settings));

	g_object_unref (settings);

	base_stream = camel_network_service_connect_sync (
		CAMEL_NETWORK_SERVICE (service), cancellable, error);

	if (base_stream != NULL) {
		stream = camel_stream_new (base_stream);
		g_object_unref (base_stream);
	} else {
		success = FALSE;
		goto exit;
	}

	/* parent class connect initialization */
	if (CAMEL_SERVICE_CLASS (camel_pop3_store_parent_class)->
		connect_sync (service, cancellable, error) == FALSE) {
		g_object_unref (stream);
		success = FALSE;
		goto exit;
	}

	if (disable_extensions)
		flags |= CAMEL_POP3_ENGINE_DISABLE_EXTENSIONS;

	if (!(pop3_engine = camel_pop3_engine_new (stream, flags, cancellable, &local_error)) ||
	    local_error != NULL) {
		if (local_error)
			g_propagate_error (error, local_error);
		else
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Failed to read a valid greeting from POP server %s"),
				host);
		g_object_unref (stream);
		success = FALSE;
		goto exit;
	}

	if (method != CAMEL_NETWORK_SECURITY_METHOD_STARTTLS_ON_STANDARD_PORT) {
		g_object_unref (stream);
		goto exit;
	}

	if (!(pop3_engine->capa & CAMEL_POP3_CAP_STLS)) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Failed to connect to POP server %s in secure mode: %s"),
			host, _("STLS not supported by server"));
		goto stls_exception;
	}

	pc = camel_pop3_engine_command_new (
		pop3_engine, 0, NULL, NULL,
		cancellable, error, "STLS\r\n");
	while (camel_pop3_engine_iterate (pop3_engine, NULL, cancellable, NULL) > 0)
		;

	ret = pc->state == CAMEL_POP3_COMMAND_OK;
	camel_pop3_engine_command_free (pop3_engine, pc);

	if (ret == FALSE) {
		gchar *tmp;

		tmp = get_valid_utf8_error ((gchar *) pop3_engine->line);
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			/* Translators: Last %s is an optional
			 * explanation beginning with ": " separator. */
			_("Failed to connect to POP server %s in secure mode%s"),
			host, (tmp != NULL) ? tmp : "");
		g_free (tmp);
		goto stls_exception;
	}

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
			_("Failed to connect to POP server %s in secure mode: "),
			host);
		goto stls_exception;
	}

	g_clear_object (&stream);

	/* rfc2595, section 4 states that after a successful STLS
	 * command, the client MUST discard prior CAPA responses */
	if (!camel_pop3_engine_reget_capabilities (pop3_engine, cancellable, error))
		goto exception;

	goto exit;

stls_exception:
	/* As soon as we send a STLS command, all hope
	 * is lost of a clean QUIT if problems arise. */
	/* if (clean_quit) {
		/ * try to disconnect cleanly * /
		pc = camel_pop3_engine_command_new (
			pop3_engine, 0, NULL, NULL,
			cancellable, NULL, "QUIT\r\n");
		while (camel_pop3_engine_iterate (pop3_engine, NULL, cancellable, NULL) > 0)
			;
		camel_pop3_engine_command_free (pop3_engine, pc);
	}*/

exception:
	g_clear_object (&stream);
	g_clear_object (&pop3_engine);

	success = FALSE;

exit:
	g_free (host);

	g_mutex_lock (&store->priv->property_lock);
	if (pop3_engine != NULL)
		store->priv->engine = g_object_ref (pop3_engine);
	g_mutex_unlock (&store->priv->property_lock);

	g_clear_object (&pop3_engine);

	return success;
}

static CamelAuthenticationResult
try_sasl (CamelPOP3Store *store,
          const gchar *mechanism,
          GCancellable *cancellable,
          GError **error)
{
	CamelPOP3Engine *pop3_engine;
	CamelPOP3Stream *pop3_stream;
	CamelNetworkSettings *network_settings;
	CamelAuthenticationResult result;
	CamelSettings *settings;
	CamelService *service;
	guchar *line, *resp;
	CamelSasl *sasl = NULL;
	gchar *string;
	gchar *host;
	guint len;
	gint ret;

	service = CAMEL_SERVICE (store);

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);

	g_object_unref (settings);

	pop3_engine = camel_pop3_store_ref_engine (store);
	if (!pop3_engine) {
		g_set_error_literal (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		result = CAMEL_AUTHENTICATION_ERROR;
		goto exit;
	}

	pop3_stream = pop3_engine->stream;

	sasl = camel_sasl_new ("pop", mechanism, service);
	if (sasl == NULL) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_URL_INVALID,
			_("No support for %s authentication"), mechanism);
		result = CAMEL_AUTHENTICATION_ERROR;
		goto exit;
	}

	string = g_strdup_printf ("AUTH %s\r\n", camel_sasl_is_xoauth2_alias (mechanism) ? "XOAUTH2" : mechanism);
	ret = camel_stream_write_string (
		CAMEL_STREAM (pop3_stream), string, cancellable, error);
	g_free (string);

	if (ret == -1)
		goto ioerror;

	while (1) {
		GError *local_error = NULL;

		if (camel_pop3_stream_line (pop3_stream, &line, &len, cancellable, error) == -1)
			goto ioerror;

		if (strncmp ((gchar *) line, "+OK", 3) == 0) {
			result = CAMEL_AUTHENTICATION_ACCEPTED;
			break;
		}

		if (strncmp ((gchar *) line, "-ERR", 4) == 0) {
			result = CAMEL_AUTHENTICATION_REJECTED;
			break;
		}

		/* If we dont get continuation, or the sasl object's run out
		 * of work, or we dont get a challenge, its a protocol error,
		 * so fail, and try reset the server. */
		if (strncmp ((gchar *) line, "+ ", 2) != 0
		    || camel_sasl_get_authenticated (sasl)
		    || (resp = (guchar *) camel_sasl_challenge_base64_sync (sasl, (const gchar *) line + 2, cancellable, &local_error)) == NULL) {
			if (camel_stream_write_string (CAMEL_STREAM (pop3_stream), "*\r\n", cancellable, NULL)) {
				/* coverity[unchecked_value] */
				if (!camel_pop3_stream_line (pop3_stream, &line, &len, cancellable, NULL)) {
					;
				}
			}

			if (local_error) {
				g_propagate_error (error, local_error);
				local_error = NULL;
				goto ioerror;
			}

			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Cannot login to POP server %s: "
				"SASL Protocol error"), host);
			result = CAMEL_AUTHENTICATION_ERROR;
			goto exit;
		}

		string = g_strdup_printf ("%s\r\n", resp);
		ret = camel_stream_write_string (
			CAMEL_STREAM (pop3_stream), string, cancellable, error);
		g_free (string);

		g_free (resp);

		if (ret == -1)
			goto ioerror;

	}

	goto exit;

ioerror:
	g_prefix_error (
		error, _("Failed to authenticate on POP server %s: "), host);
	result = CAMEL_AUTHENTICATION_ERROR;

exit:
	if (sasl != NULL)
		g_object_unref (sasl);

	g_free (host);

	g_clear_object (&pop3_engine);

	return result;
}

static void
pop3_store_set_property (GObject *object,
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
pop3_store_get_property (GObject *object,
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
pop3_store_dispose (GObject *object)
{
	CamelPOP3StorePrivate *priv;

	priv = CAMEL_POP3_STORE_GET_PRIVATE (object);

	/* Force disconnect so we dont have it run
	 * later, after we've cleaned up some stuff. */
	camel_service_disconnect_sync (
		CAMEL_SERVICE (object), TRUE, NULL, NULL);

	g_clear_object (&priv->cache);
	g_clear_object (&priv->engine);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_pop3_store_parent_class)->dispose (object);
}

static void
pop3_store_finalize (GObject *object)
{
	CamelPOP3StorePrivate *priv;

	priv = CAMEL_POP3_STORE_GET_PRIVATE (object);

	g_mutex_clear (&priv->property_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_pop3_store_parent_class)->finalize (object);
}

static gchar *
pop3_store_get_name (CamelService *service,
                     gboolean brief)
{
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	gchar *host;
	gchar *user;
	gchar *name;

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	user = camel_network_settings_dup_user (network_settings);

	g_object_unref (settings);

	if (brief)
		name = g_strdup_printf (
			_("POP3 server %s"), host);
	else
		name = g_strdup_printf (
			_("POP3 server for %s on %s"), user, host);

	g_free (host);
	g_free (user);

	return name;
}

static gboolean
pop3_store_connect_sync (CamelService *service,
                         GCancellable *cancellable,
                         GError **error)
{
	CamelPOP3Store *store = (CamelPOP3Store *) service;
	CamelPOP3Engine *pop3_engine;
	CamelSettings *settings;
	CamelSession *session;
	const gchar *user_data_dir;
	gboolean success = TRUE;
	gchar *mechanism;

	/* Chain up to parent's method. */
	if (!CAMEL_SERVICE_CLASS (camel_pop3_store_parent_class)->connect_sync (service, cancellable, error))
		return FALSE;

	session = camel_service_ref_session (service);
	user_data_dir = camel_service_get_user_data_dir (service);

	settings = camel_service_ref_settings (service);

	mechanism = camel_network_settings_dup_auth_mechanism (
		CAMEL_NETWORK_SETTINGS (settings));

	g_object_unref (settings);

	if (!session || !camel_session_get_online (session)) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		success = FALSE;
		goto exit;
	}

	g_mutex_lock (&store->priv->property_lock);

	if (store->priv->cache == NULL) {
		CamelDataCache *cache;

		cache = camel_data_cache_new (user_data_dir, error);
		if (cache != NULL) {
			/* Ensure cache will never expire, otherwise
			 * it causes redownload of messages. */
			camel_data_cache_set_expire_age (cache, -1);
			camel_data_cache_set_expire_access (cache, -1);

			store->priv->cache = g_object_ref (cache);

			g_object_unref (cache);
		}
	}

	g_mutex_unlock (&store->priv->property_lock);

	success = connect_to_server (service, cancellable, error);

	if (!success)
		goto exit;

	success = camel_session_authenticate_sync (
		session, service, mechanism, cancellable, error);

	if (!success)
		goto exit;

	/* Now that we are in the TRANSACTION state,
	 * try regetting the capabilities */
	pop3_engine = camel_pop3_store_ref_engine (store);
	if (pop3_engine) {
		pop3_engine->state = CAMEL_POP3_ENGINE_TRANSACTION;
		if (!camel_pop3_engine_reget_capabilities (pop3_engine, cancellable, error))
			success = FALSE;
		g_clear_object (&pop3_engine);
	} else {
		g_set_error_literal (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		success = FALSE;
	}

exit:
	g_free (mechanism);

	g_object_unref (session);

	if (!success) {
		/* to not leak possible connection to the server */
		g_mutex_lock (&store->priv->property_lock);
		g_clear_object (&store->priv->engine);
		g_mutex_unlock (&store->priv->property_lock);
	}

	return success;
}

static gboolean
pop3_store_disconnect_sync (CamelService *service,
                            gboolean clean,
                            GCancellable *cancellable,
                            GError **error)
{
	CamelServiceClass *service_class;
	CamelPOP3Store *store = CAMEL_POP3_STORE (service);
	gboolean success;

	if (clean) {
		CamelPOP3Engine *pop3_engine;
		CamelPOP3Command *pc;

		pop3_engine = camel_pop3_store_ref_engine (store);

		if (pop3_engine) {
			if (camel_pop3_engine_busy_lock (pop3_engine, cancellable, NULL)) {
				pc = camel_pop3_engine_command_new (
					pop3_engine, 0, NULL, NULL,
					cancellable, error, "QUIT\r\n");
				while (camel_pop3_engine_iterate (pop3_engine, NULL, cancellable, NULL) > 0)
					;
				camel_pop3_engine_command_free (pop3_engine, pc);
				camel_pop3_engine_busy_unlock (pop3_engine);
			}

			g_clear_object (&pop3_engine);
		}
	}

	/* Chain up to parent's disconnect() method. */
	service_class = CAMEL_SERVICE_CLASS (camel_pop3_store_parent_class);

	success = service_class->disconnect_sync (service, clean, cancellable, error);

	g_mutex_lock (&store->priv->property_lock);
	g_clear_object (&store->priv->engine);
	g_mutex_unlock (&store->priv->property_lock);

	return success;
}

static CamelAuthenticationResult
pop3_store_authenticate_sync (CamelService *service,
                              const gchar *mechanism,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelPOP3Store *store = CAMEL_POP3_STORE (service);
	CamelNetworkSettings *network_settings;
	CamelAuthenticationResult result;
	CamelSettings *settings;
	CamelPOP3Command *pcu = NULL;
	CamelPOP3Command *pcp = NULL;
	CamelPOP3Engine *pop3_engine;
	const gchar *password;
	gchar *host;
	gchar *user;
	gint status;

	password = camel_service_get_password (service);

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	user = camel_network_settings_dup_user (network_settings);

	g_object_unref (settings);

	pop3_engine = camel_pop3_store_ref_engine (store);
	if (!pop3_engine) {
		g_set_error_literal (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		result = CAMEL_AUTHENTICATION_ERROR;
		goto exit;
	}

	if (!camel_pop3_engine_busy_lock (pop3_engine, cancellable, error)) {
		g_free (host);
		g_free (user);
		g_clear_object (&pop3_engine);

		return CAMEL_AUTHENTICATION_ERROR;
	}

	if (mechanism == NULL) {
		if (password == NULL) {
			g_set_error_literal (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Authentication password not available"));
			result = CAMEL_AUTHENTICATION_ERROR;
			goto exit;
		}

		/* pop engine will take care of pipelining ability */
		pcu = camel_pop3_engine_command_new (
			pop3_engine, 0, NULL, NULL, cancellable, error,
			"USER %s\r\n", user);
		if (error && *error) {
			g_prefix_error (
				error,
				_("Unable to connect to POP server %s.\n"
				"Error sending password: "), host);
			result = CAMEL_AUTHENTICATION_ERROR;
			goto exit;
		}

		pcp = camel_pop3_engine_command_new (
			pop3_engine, 0, NULL, NULL, cancellable, error,
			"PASS %s\r\n", password);

		if (error && *error) {
			g_prefix_error (
				error,
				_("Unable to connect to POP server %s.\n"
				"Error sending password: "), host);
			result = CAMEL_AUTHENTICATION_ERROR;
			goto exit;
		}
	} else if (strcmp (mechanism, "+APOP") == 0 && pop3_engine->apop) {
		gchar *secret, *md5asc, *d;
		gsize secret_len;

		if (password == NULL) {
			g_set_error_literal (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Authentication password not available"));
			result = CAMEL_AUTHENTICATION_ERROR;
			goto exit;
		}

		d = pop3_engine->apop;

		while (*d != '\0') {
			if (!isascii ((gint) * d)) {

				g_set_error (
					error, CAMEL_SERVICE_ERROR,
					CAMEL_SERVICE_ERROR_URL_INVALID,
					/* Translators: Do not translate APOP. */
					_("Unable to connect to POP server %s:	"
					"Invalid APOP ID received. Impersonation "
					"attack suspected. Please contact your admin."),
					host);

				result = CAMEL_AUTHENTICATION_ERROR;
				goto exit;
			}
			d++;
		}

		secret_len =
			strlen (pop3_engine->apop) +
			strlen (password) + 1;
		secret = g_alloca (secret_len);
		g_snprintf (
			secret, secret_len, "%s%s",
			pop3_engine->apop, password);
		md5asc = g_compute_checksum_for_string (
			G_CHECKSUM_MD5, secret, -1);
		pcp = camel_pop3_engine_command_new (
			pop3_engine, 0, NULL, NULL, cancellable, error,
			"APOP %s %s\r\n", user, md5asc);
		g_free (md5asc);

	} else {
		GList *link;
		const gchar *test_mechanism = mechanism;

		if (camel_sasl_is_xoauth2_alias (test_mechanism))
			test_mechanism = "XOAUTH2";

		link = pop3_engine->auth;
		while (link != NULL) {
			CamelServiceAuthType *auth = link->data;

			if (g_strcmp0 (auth->authproto, test_mechanism) == 0) {
				result = try_sasl (
					store, mechanism,
					cancellable, error);
				goto exit;
			}
			link = g_list_next (link);
		}

		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			_("No support for %s authentication"), mechanism);
		result = CAMEL_AUTHENTICATION_ERROR;
		goto exit;
	}

	while ((status = camel_pop3_engine_iterate (pop3_engine, pcp, cancellable, error)) > 0)
		;

	if (status == -1) {
		g_prefix_error (
			error,
			_("Unable to connect to POP server %s.\n"
			"Error sending password: "), host);
		result = CAMEL_AUTHENTICATION_ERROR;

	} else if (pcu && pcu->state != CAMEL_POP3_COMMAND_OK) {
		gchar *tmp;

		/* Abort authentication if the server rejects the user
		 * name.  Reprompting for a password won't do any good. */
		tmp = get_valid_utf8_error ((gchar *) pop3_engine->line);
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			/* Translators: Last %s is an optional explanation
			 * beginning with ": " separator. */
			_("Unable to connect to POP server %s.\n"
			"Error sending username%s"),
			host, (tmp != NULL) ? tmp : "");
		g_free (tmp);
		result = CAMEL_AUTHENTICATION_ERROR;

	} else if (pcp->state != CAMEL_POP3_COMMAND_OK) {
		result = CAMEL_AUTHENTICATION_REJECTED;
	} else {
		result = CAMEL_AUTHENTICATION_ACCEPTED;
	}

exit:
	if (pcp != NULL)
		camel_pop3_engine_command_free (pop3_engine, pcp);

	if (pcu != NULL)
		camel_pop3_engine_command_free (pop3_engine, pcu);

	g_free (host);
	g_free (user);

	camel_pop3_engine_busy_unlock (pop3_engine);
	g_clear_object (&pop3_engine);

	return result;
}

static GList *
pop3_store_query_auth_types_sync (CamelService *service,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelServiceClass *service_class;
	CamelPOP3Store *store = CAMEL_POP3_STORE (service);
	GList *types = NULL;
	GError *local_error = NULL;

	/* Chain up to parent's query_auth_types() method. */
	service_class = CAMEL_SERVICE_CLASS (camel_pop3_store_parent_class);
	types = service_class->query_auth_types_sync (
		service, cancellable, &local_error);

	if (local_error != NULL) {
		g_propagate_error (error, local_error);
		return NULL;
	}

	if (connect_to_server (service, cancellable, error)) {
		CamelPOP3Engine *pop3_engine;

		pop3_engine = camel_pop3_store_ref_engine (store);

		if (pop3_engine) {
			types = g_list_concat (types, g_list_copy (pop3_engine->auth));
			pop3_store_disconnect_sync (service, TRUE, cancellable, NULL);

			g_clear_object (&pop3_engine);
		}
	}

	return types;
}

static gboolean
pop3_store_can_refresh_folder (CamelStore *store,
                               CamelFolderInfo *info,
                               GError **error)
{
	/* any pop3 folder can be refreshed */
	return TRUE;
}

static CamelFolder *
pop3_store_get_folder_sync (CamelStore *store,
                            const gchar *folder_name,
                            CamelStoreGetFolderFlags flags,
                            GCancellable *cancellable,
                            GError **error)
{
	if (g_ascii_strcasecmp (folder_name, "inbox") != 0) {
		g_set_error (
			error, CAMEL_FOLDER_ERROR,
			CAMEL_FOLDER_ERROR_INVALID,
			_("No such folder “%s”."), folder_name);
		return NULL;
	}

	return camel_pop3_folder_new (store, cancellable, error);
}

static CamelFolderInfo *
pop3_store_get_folder_info_sync (CamelStore *store,
                                 const gchar *top,
                                 CamelStoreGetFolderInfoFlags flags,
                                 GCancellable *cancellable,
                                 GError **error)
{
	g_set_error (
		error, CAMEL_STORE_ERROR,
		CAMEL_STORE_ERROR_NO_FOLDER,
		_("POP3 stores have no folder hierarchy"));

	return NULL;
}

static CamelFolder *
pop3_store_get_trash_folder_sync (CamelStore *store,
                                  GCancellable *cancellable,
                                  GError **error)
{
	/* no-op */
	return NULL;
}

static const gchar *
pop3_store_get_service_name (CamelNetworkService *service,
                             CamelNetworkSecurityMethod method)
{
	const gchar *service_name;

	switch (method) {
		case CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT:
			service_name = "pop3s";
			break;

		default:
			service_name = "pop3";
			break;
	}

	return service_name;
}

static guint16
pop3_store_get_default_port (CamelNetworkService *service,
                             CamelNetworkSecurityMethod method)
{
	guint16 default_port;

	switch (method) {
		case CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT:
			default_port = POP3S_PORT;
			break;

		default:
			default_port = POP3_PORT;
			break;
	}

	return default_port;
}

static void
camel_pop3_store_class_init (CamelPOP3StoreClass *class)
{
	GObjectClass *object_class;
	CamelServiceClass *service_class;
	CamelStoreClass *store_class;

	g_type_class_add_private (class, sizeof (CamelPOP3StorePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = pop3_store_set_property;
	object_class->get_property = pop3_store_get_property;
	object_class->dispose = pop3_store_dispose;
	object_class->finalize = pop3_store_finalize;

	service_class = CAMEL_SERVICE_CLASS (class);
	service_class->settings_type = CAMEL_TYPE_POP3_SETTINGS;
	service_class->get_name = pop3_store_get_name;
	service_class->connect_sync = pop3_store_connect_sync;
	service_class->disconnect_sync = pop3_store_disconnect_sync;
	service_class->authenticate_sync = pop3_store_authenticate_sync;
	service_class->query_auth_types_sync = pop3_store_query_auth_types_sync;

	store_class = CAMEL_STORE_CLASS (class);
	store_class->can_refresh_folder = pop3_store_can_refresh_folder;
	store_class->get_folder_sync = pop3_store_get_folder_sync;
	store_class->get_folder_info_sync = pop3_store_get_folder_info_sync;
	store_class->get_trash_folder_sync = pop3_store_get_trash_folder_sync;

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
	iface->get_service_name = pop3_store_get_service_name;
	iface->get_default_port = pop3_store_get_default_port;
}

static void
camel_pop3_store_init (CamelPOP3Store *pop3_store)
{
	pop3_store->priv = CAMEL_POP3_STORE_GET_PRIVATE (pop3_store);

	g_mutex_init (&pop3_store->priv->property_lock);
}

/**
 * camel_pop3_store_ref_cache:
 * @store: a #CamelPOP3Store
 *
 * Returns the #CamelDataCache for @store.
 *
 * The returned #CamelDataCache is referenced for thread-safety and must be
 * unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelDataCache
 **/
CamelDataCache *
camel_pop3_store_ref_cache (CamelPOP3Store *store)
{
	CamelDataCache *cache = NULL;

	g_return_val_if_fail (CAMEL_IS_POP3_STORE (store), NULL);

	g_mutex_lock (&store->priv->property_lock);

	if (store->priv->cache != NULL)
		cache = g_object_ref (store->priv->cache);

	g_mutex_unlock (&store->priv->property_lock);

	return cache;
}

/**
 * camel_pop3_store_ref_engine:
 * @store: a #CamelPOP3Store
 *
 * Returns the #CamelPOP3Engine for @store.
 *
 * The returned #CamelPOP3Engine is referenced for thread-safety and must be
 * unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelPOP3Store
 **/
CamelPOP3Engine *
camel_pop3_store_ref_engine (CamelPOP3Store *store)
{
	CamelPOP3Engine *engine = NULL;

	g_return_val_if_fail (CAMEL_IS_POP3_STORE (store), NULL);

	g_mutex_lock (&store->priv->property_lock);

	if (store->priv->engine != NULL)
		engine = g_object_ref (store->priv->engine);

	g_mutex_unlock (&store->priv->property_lock);

	return engine;
}

/**
 * camel_pop3_store_expunge:
 * @store: a #CamelPOP3Store
 * @error: return location for a #GError, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 *
 * Expunge messages from the store. This will result in the connection
 * being closed, which may cause later commands to fail if they can't
 * reconnect.
 **/
gboolean
camel_pop3_store_expunge (CamelPOP3Store *store,
                          GCancellable *cancellable,
                          GError **error)
{
	CamelPOP3Command *pc;
	CamelPOP3Engine *pop3_engine;
	CamelServiceConnectionStatus status;

	status = camel_service_get_connection_status (CAMEL_SERVICE (store));

	if (status != CAMEL_SERVICE_CONNECTED) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		return FALSE;
	}

	pop3_engine = camel_pop3_store_ref_engine (store);

	if (!camel_pop3_engine_busy_lock (pop3_engine, cancellable, error)) {
		g_clear_object (&pop3_engine);
		return FALSE;
	}

	pc = camel_pop3_engine_command_new (
		pop3_engine, 0, NULL, NULL, cancellable, error, "QUIT\r\n");

	while (camel_pop3_engine_iterate (pop3_engine, NULL, cancellable, NULL) > 0)
		;

	camel_pop3_engine_command_free (pop3_engine, pc);

	camel_pop3_engine_busy_unlock (pop3_engine);
	g_clear_object (&pop3_engine);

	return TRUE;
}

/**
 * camel_pop3_store_cache_add:
 * @store: a #CamelPOP3Store
 * @uid: a message UID
 * @error: return location for a #GError, or %NULL
 *
 * Creates a cache file for @uid in @store and returns a #CamelStream for it.
 * If an error occurs in opening the cache file, the function sets @error and
 * returns %NULL.
 *
 * The returned #CamelStream is referenced for thread-safety and must be
 * unreferenced when finished with it.
 *
 * Returns: a #CamelStream, or %NULL
 **/
CamelStream *
camel_pop3_store_cache_add (CamelPOP3Store *store,
                            const gchar *uid,
                            GError **error)
{
	CamelDataCache *cache;
	GIOStream *base_stream;
	CamelStream *stream = NULL;

	g_return_val_if_fail (CAMEL_IS_POP3_STORE (store), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	cache = camel_pop3_store_ref_cache (store);
	g_return_val_if_fail (cache != NULL, NULL);

	base_stream = camel_data_cache_add (cache, "cache", uid, error);
	if (base_stream != NULL) {
		stream = camel_stream_new (base_stream);
		g_object_unref (base_stream);
	}

	g_object_unref (cache);

	return stream;
}

/**
 * camel_pop3_store_cache_get:
 * @store: a #CamelPOP3Store
 * @uid: a message UID
 * @error: return location for a #GError, or %NULL
 *
 * Opens the cache file for @uid in @store and returns a #CamelStream for it.
 * If no matching cache file exists, the function returns %NULL.  If an error
 * occurs in opening the cache file, the function sets @error and returns
 * %NULL.
 *
 * The returned #CamelStream is referenced for thread-safety and must be
 * unreferenced when finished with it.
 *
 * Returns: a #CamelStream, or %NULL
 **/
CamelStream *
camel_pop3_store_cache_get (CamelPOP3Store *store,
                            const gchar *uid,
                            GError **error)
{
	CamelDataCache *cache;
	GIOStream *base_stream;
	CamelStream *stream = NULL;

	g_return_val_if_fail (CAMEL_IS_POP3_STORE (store), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	cache = camel_pop3_store_ref_cache (store);
	g_return_val_if_fail (cache != NULL, NULL);

	base_stream = camel_data_cache_get (cache, "cache", uid, error);
	if (base_stream != NULL) {
		GInputStream *input_stream;
		gchar buffer[1];
		gssize n_bytes;

		input_stream = g_io_stream_get_input_stream (base_stream);

		n_bytes = g_input_stream_read (
			input_stream, buffer, 1, NULL, error);

		if (n_bytes == 1 && buffer[0] == '#')
			stream = camel_stream_new (base_stream);

		g_object_unref (base_stream);
	}

	g_object_unref (cache);

	return stream;
}

/**
 * camel_pop3_store_cache_has:
 * @store: a #CamelPOP3Store
 * @uid: a message UID
 *
 * Returns whether @store has a cached message for @uid.
 *
 * Returns: whether @uid is cached
 **/
gboolean
camel_pop3_store_cache_has (CamelPOP3Store *store,
                            const gchar *uid)
{
	CamelStream *stream;
	gboolean uid_is_cached;

	g_return_val_if_fail (CAMEL_IS_POP3_STORE (store), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	stream = camel_pop3_store_cache_get (store, uid, NULL);
	uid_is_cached = (stream != NULL);
	g_clear_object (&stream);

	return uid_is_cached;
}

