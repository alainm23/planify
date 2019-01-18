/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-smtp-provider.c: smtp provider registration code
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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <camel/camel.h>
#include <glib/gi18n-lib.h>

#include "camel-smtp-transport.h"

#ifdef G_OS_WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#endif

static guint smtp_url_hash (gconstpointer key);
static gint smtp_url_equal (gconstpointer a, gconstpointer b);

CamelProviderPortEntry smtp_port_entries[] = {
	{ 25, N_("Default SMTP port"), FALSE },
	{ 465, N_("SMTP over TLS"), TRUE },
	{ 587, N_("Message submission port"), FALSE },
	{ 0, NULL, 0 }
};

static CamelProvider smtp_provider = {
	"smtp",
	N_("SMTP"),

	N_("For delivering mail by connecting to a remote mailhub "
	   "using SMTP."),

	"mail",

	CAMEL_PROVIDER_IS_REMOTE | CAMEL_PROVIDER_SUPPORTS_SSL,

	CAMEL_URL_NEED_HOST | CAMEL_URL_ALLOW_AUTH | CAMEL_URL_ALLOW_USER,

	NULL,

	smtp_port_entries,

	/* ... */
};

void
camel_provider_module_init (void)
{
	smtp_provider.object_types[CAMEL_PROVIDER_TRANSPORT] = camel_smtp_transport_get_type ();
	smtp_provider.authtypes = g_list_append (camel_sasl_authtype_list (TRUE), camel_sasl_authtype ("LOGIN"));
	smtp_provider.authtypes = g_list_append (smtp_provider.authtypes, camel_sasl_authtype ("POPB4SMTP"));
	smtp_provider.url_hash = smtp_url_hash;
	smtp_provider.url_equal = smtp_url_equal;
	smtp_provider.translation_domain = GETTEXT_PACKAGE;

	camel_provider_register (&smtp_provider);
}

static void
add_hash (guint *hash,
          gchar *s)
{
	if (s)
		*hash ^= g_str_hash(s);
}

static guint
smtp_url_hash (gconstpointer key)
{
	const CamelURL *u = (CamelURL *) key;
	guint hash = 0;

	add_hash (&hash, u->user);
	add_hash (&hash, u->host);
	hash ^= u->port;

	return hash;
}

static gint
check_equal (gchar *s1,
             gchar *s2)
{
	if (s1 == NULL) {
		if (s2 == NULL)
			return TRUE;
		else
			return FALSE;
	}

	if (s2 == NULL)
		return FALSE;

	return strcmp (s1, s2) == 0;
}

static gint
smtp_url_equal (gconstpointer a,
                gconstpointer b)
{
	const CamelURL *u1 = a, *u2 = b;

	return check_equal (u1->protocol, u2->protocol)
		&& check_equal (u1->user, u2->user)
		&& check_equal (u1->host, u2->host)
		&& u1->port == u2->port;
}
