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
#include "camel-sasl-plain.h"
#include "camel-service.h"

#define CAMEL_SASL_PLAIN_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SASL_PLAIN, CamelSaslPlainPrivate))

struct _CamelSaslPlainPrivate {
	gint placeholder;  /* allow for future expansion */
};

static CamelServiceAuthType sasl_plain_auth_type = {
	N_("PLAIN"),

	N_("This option will connect to the server using a "
	   "simple password."),

	"PLAIN",
	TRUE
};

G_DEFINE_TYPE (CamelSaslPlain, camel_sasl_plain, CAMEL_TYPE_SASL)

static GByteArray *
sasl_plain_challenge_sync (CamelSasl *sasl,
                           GByteArray *token,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	CamelService *service;
	GByteArray *buf = NULL;
	const gchar *password;
	gchar *user;

	service = camel_sasl_get_service (sasl);

	settings = camel_service_ref_settings (service);
	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	user = camel_network_settings_dup_user (network_settings);

	g_object_unref (settings);

	g_return_val_if_fail (user != NULL, NULL);

	password = camel_service_get_password (service);
	g_return_val_if_fail (password != NULL, NULL);

	/* FIXME: make sure these are "UTF8-SAFE" */
	buf = g_byte_array_new ();
	g_byte_array_append (buf, (guint8 *) "", 1);
	g_byte_array_append (buf, (guint8 *) user, strlen (user));
	g_byte_array_append (buf, (guint8 *) "", 1);
	g_byte_array_append (buf, (guint8 *) password, strlen (password));

	camel_sasl_set_authenticated (sasl, TRUE);

	g_free (user);

	return buf;
}

static void
camel_sasl_plain_class_init (CamelSaslPlainClass *class)
{
	CamelSaslClass *sasl_class;

	g_type_class_add_private (class, sizeof (CamelSaslPlainPrivate));

	sasl_class = CAMEL_SASL_CLASS (class);
	sasl_class->auth_type = &sasl_plain_auth_type;
	sasl_class->challenge_sync = sasl_plain_challenge_sync;
}

static void
camel_sasl_plain_init (CamelSaslPlain *sasl)
{
	sasl->priv = CAMEL_SASL_PLAIN_GET_PRIVATE (sasl);
}
