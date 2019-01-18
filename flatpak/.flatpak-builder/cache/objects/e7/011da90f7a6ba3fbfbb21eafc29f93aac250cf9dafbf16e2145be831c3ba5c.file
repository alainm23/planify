/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
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

#include <string.h>

#include <glib/gi18n-lib.h>

#include "camel-network-settings.h"
#include "camel-sasl-login.h"
#include "camel-service.h"

#define CAMEL_SASL_LOGIN_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SASL_LOGIN, CamelSaslLoginPrivate))

static CamelServiceAuthType sasl_login_auth_type = {
	N_("Login"),

	N_("This option will connect to the server using a "
	   "simple password."),

	"LOGIN",
	TRUE
};

enum {
	LOGIN_USER,
	LOGIN_PASSWD
};

struct _CamelSaslLoginPrivate {
	gint state;
};

G_DEFINE_TYPE (CamelSaslLogin, camel_sasl_login, CAMEL_TYPE_SASL)

static GByteArray *
sasl_login_challenge_sync (CamelSasl *sasl,
                           GByteArray *token,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelSaslLoginPrivate *priv;
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	CamelService *service;
	GByteArray *buf = NULL;
	const gchar *password;
	gchar *user;

	/* Need to wait for the server */
	if (token == NULL)
		return NULL;

	priv = CAMEL_SASL_LOGIN_GET_PRIVATE (sasl);

	service = camel_sasl_get_service (sasl);

	settings = camel_service_ref_settings (service);
	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	user = camel_network_settings_dup_user (network_settings);

	g_object_unref (settings);

	g_return_val_if_fail (user != NULL, NULL);

	password = camel_service_get_password (service);
	g_return_val_if_fail (password != NULL, NULL);

	switch (priv->state) {
	case LOGIN_USER:
		buf = g_byte_array_new ();
		g_byte_array_append (buf, (guint8 *) user, strlen (user));
		break;
	case LOGIN_PASSWD:
		buf = g_byte_array_new ();
		g_byte_array_append (buf, (guint8 *) password, strlen (password));

		camel_sasl_set_authenticated (sasl, TRUE);
		break;
	default:
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			_("Unknown authentication state."));
	}

	priv->state++;

	g_free (user);

	return buf;
}

static void
camel_sasl_login_class_init (CamelSaslLoginClass *class)
{
	CamelSaslClass *sasl_class;

	g_type_class_add_private (class, sizeof (CamelSaslLoginPrivate));

	sasl_class = CAMEL_SASL_CLASS (class);
	sasl_class->auth_type = &sasl_login_auth_type;
	sasl_class->challenge_sync = sasl_login_challenge_sync;
}

static void
camel_sasl_login_init (CamelSaslLogin *sasl)
{
	sasl->priv = CAMEL_SASL_LOGIN_GET_PRIVATE (sasl);
}
