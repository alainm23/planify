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

#include <stdio.h>
#include <string.h>

#include <glib/gi18n-lib.h>

#include "camel-mime-utils.h"
#include "camel-network-settings.h"
#include "camel-sasl-cram-md5.h"
#include "camel-service.h"

#define CAMEL_SASL_CRAM_MD5_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SASL_CRAM_MD5, CamelSaslCramMd5Private))

struct _CamelSaslCramMd5Private {
	gint placeholder;  /* allow for future expansion */
};

static CamelServiceAuthType sasl_cram_md5_auth_type = {
	N_("CRAM-MD5"),

	N_("This option will connect to the server using a "
	   "secure CRAM-MD5 password, if the server supports it."),

	"CRAM-MD5",
	TRUE
};

G_DEFINE_TYPE (CamelSaslCramMd5, camel_sasl_cram_md5, CAMEL_TYPE_SASL)

/* CRAM-MD5 algorithm:
 * MD5 ((passwd XOR opad), MD5 ((passwd XOR ipad), timestamp))
 */

static GByteArray *
sasl_cram_md5_challenge_sync (CamelSasl *sasl,
                              GByteArray *token,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	CamelService *service;
	GChecksum *checksum;
	guint8 *digest;
	gsize length;
	const gchar *hex;
	const gchar *password;
	GByteArray *ret = NULL;
	guchar ipad[64];
	guchar opad[64];
	gchar *user;
	gint i, pw_len;

	/* Need to wait for the server */
	if (!token)
		return NULL;

	service = camel_sasl_get_service (sasl);

	settings = camel_service_ref_settings (service);
	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	user = camel_network_settings_dup_user (network_settings);

	g_object_unref (settings);

	g_return_val_if_fail (user != NULL, NULL);

	password = camel_service_get_password (service);
	g_return_val_if_fail (password != NULL, NULL);

	length = g_checksum_type_get_length (G_CHECKSUM_MD5);
	digest = g_alloca (length);

	memset (ipad, 0, sizeof (ipad));
	memset (opad, 0, sizeof (opad));

	pw_len = strlen (password);
	if (pw_len <= 64) {
		memcpy (ipad, password, pw_len);
		memcpy (opad, password, pw_len);
	} else {
		checksum = g_checksum_new (G_CHECKSUM_MD5);
		g_checksum_update (checksum, (guchar *) password, pw_len);
		g_checksum_get_digest (checksum, digest, &length);
		g_checksum_free (checksum);

		memcpy (ipad, digest, length);
		memcpy (opad, digest, length);
	}

	for (i = 0; i < 64; i++) {
		ipad[i] ^= 0x36;
		opad[i] ^= 0x5c;
	}

	checksum = g_checksum_new (G_CHECKSUM_MD5);
	g_checksum_update (checksum, (guchar *) ipad, sizeof (ipad));
	g_checksum_update (checksum, (guchar *) token->data, token->len);
	g_checksum_get_digest (checksum, digest, &length);
	g_checksum_free (checksum);

	checksum = g_checksum_new (G_CHECKSUM_MD5);
	g_checksum_update (checksum, (guchar *) opad, sizeof (opad));
	g_checksum_update (checksum, (guchar *) digest, length);

	/* String is owned by the checksum. */
	hex = g_checksum_get_string (checksum);

	ret = g_byte_array_new ();
	g_byte_array_append (ret, (guint8 *) user, strlen (user));
	g_byte_array_append (ret, (guint8 *) " ", 1);
	g_byte_array_append (ret, (guint8 *) hex, strlen (hex));

	g_checksum_free (checksum);

	camel_sasl_set_authenticated (sasl, TRUE);

	g_free (user);

	return ret;
}

static void
camel_sasl_cram_md5_class_init (CamelSaslCramMd5Class *class)
{
	CamelSaslClass *sasl_class;

	g_type_class_add_private (class, sizeof (CamelSaslCramMd5Private));

	sasl_class = CAMEL_SASL_CLASS (class);
	sasl_class->auth_type = &sasl_cram_md5_auth_type;
	sasl_class->challenge_sync = sasl_cram_md5_challenge_sync;
}

static void
camel_sasl_cram_md5_init (CamelSaslCramMd5 *sasl)
{
	sasl->priv = CAMEL_SASL_CRAM_MD5_GET_PRIVATE (sasl);
}
