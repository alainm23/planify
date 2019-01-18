/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-nntp-provider.c: nntp provider registration code
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
 * Authors :
 *   Chris Toshok <toshok@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <string.h>

#include <glib/gi18n-lib.h>

#include "camel-nntp-store.h"

static void add_hash (guint *hash, gchar *s);
static guint nntp_url_hash (gconstpointer key);
static gint check_equal (gchar *s1, gchar *s2);
static gint nntp_url_equal (gconstpointer a, gconstpointer b);

static CamelProviderConfEntry nntp_conf_entries[] = {
	{ CAMEL_PROVIDER_CONF_SECTION_START, "general", NULL, N_("Options") },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "filter-all", NULL,
	  N_("Apply _filters to new messages in all folders"), "0" },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "filter-junk", NULL,
	  N_("Check new messages for _Junk contents"), "0" },
	{ CAMEL_PROVIDER_CONF_SECTION_END },
	{ CAMEL_PROVIDER_CONF_SECTION_START, "folders", NULL,
	  N_("Folders") },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "short-folder-names", NULL,
	  N_("_Show folders in short notation (e.g. c.o.linux rather "
	  "than comp.os.linux)"), "1" },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "folder-hierarchy-relative", NULL,
	  N_("In the subscription _dialog, show relative folder names"), "1" },
	{ CAMEL_PROVIDER_CONF_CHECKSPIN, "limit-latest", NULL,
	  /* Translators: The '%s' is replaced with a spin button with the actual value to use */
	  N_("Download only up to %s latest messages"), "y:100:1000:99999999" },
	{ CAMEL_PROVIDER_CONF_SECTION_END },
	{ CAMEL_PROVIDER_CONF_END }
};

CamelProviderPortEntry nntp_port_entries[] = {
	{ 119, N_("Default NNTP port"), FALSE },
	{ 563, N_("NNTP over TLS"), TRUE },
	{ 0, NULL, 0 }
};

static CamelProvider news_provider = {
	"nntp",
	N_("USENET news"),

	N_("This is a provider for reading from and posting to "
	   "USENET newsgroups."),

	"news",

	CAMEL_PROVIDER_IS_REMOTE | CAMEL_PROVIDER_IS_SOURCE |
	CAMEL_PROVIDER_IS_STORAGE | CAMEL_PROVIDER_SUPPORTS_SSL,

	CAMEL_URL_NEED_HOST | CAMEL_URL_ALLOW_USER |
	CAMEL_URL_ALLOW_PASSWORD | CAMEL_URL_ALLOW_AUTH,

	nntp_conf_entries,

	nntp_port_entries,

	/* ... */
};

CamelServiceAuthType camel_nntp_anonymous_authtype = {
	N_("Anonymous"),

	N_("This option will connect to the NNTP server anonymously, without "
	   "authentication."),

	"ANONYMOUS",
	FALSE
};

CamelServiceAuthType camel_nntp_password_authtype = {
	N_("Password"),

	N_("This option will authenticate with the NNTP server using a "
	   "plaintext password."),

	"PLAIN",
	TRUE
};

void
camel_provider_module_init (void)
{
	GList *auth_types;

	auth_types = g_list_append (NULL, &camel_nntp_anonymous_authtype);
	auth_types = g_list_append (auth_types, &camel_nntp_password_authtype);

	news_provider.object_types[CAMEL_PROVIDER_STORE] = camel_nntp_store_get_type ();

	news_provider.url_hash = nntp_url_hash;
	news_provider.url_equal = nntp_url_equal;
	news_provider.authtypes = auth_types;
	news_provider.translation_domain = GETTEXT_PACKAGE;

	camel_provider_register (&news_provider);
}

static void
add_hash (guint *hash,
          gchar *s)
{
	if (s)
		*hash ^= g_str_hash(s);
}

static guint
nntp_url_hash (gconstpointer key)
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
nntp_url_equal (gconstpointer a,
                gconstpointer b)
{
	const CamelURL *u1 = a, *u2 = b;

	return check_equal (u1->protocol, u2->protocol)
		&& check_equal (u1->user, u2->user)
		&& check_equal (u1->host, u2->host)
		&& u1->port == u2->port;
}
