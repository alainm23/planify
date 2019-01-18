/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-pop3-provider.c: pop3 provider registration code
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
 *   Dan Winship <danw@ximian.com>
 *   Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <string.h>
#include <camel/camel.h>
#include <glib/gi18n-lib.h>

#include "camel-imapx-store.h"

static guint imapx_url_hash (gconstpointer key);
static gint  imapx_url_equal (gconstpointer a, gconstpointer b);

CamelProviderConfEntry imapx_conf_entries[] = {
	{ CAMEL_PROVIDER_CONF_SECTION_START, "mailcheck", NULL,
	  N_("Checking for New Mail") },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "check-all", NULL,
	  N_("C_heck for new messages in all folders"), "1" },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "check-subscribed", NULL,
	  N_("Ch_eck for new messages in subscribed folders"), "0" },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "use-qresync", NULL,
	  N_("Use _Quick Resync if the server supports it"), "0" },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "use-idle", NULL,
	  N_("_Listen for server change notifications"), "1" },
	{ CAMEL_PROVIDER_CONF_SECTION_END },
	{ CAMEL_PROVIDER_CONF_SECTION_START, "cmdsection", NULL,
	  N_("Connection to Server") },
	{ CAMEL_PROVIDER_CONF_CHECKSPIN, "concurrent-connections", NULL,
	  N_("Numbe_r of concurrent connections to use"), "y:1:3:7" },
	{ CAMEL_PROVIDER_CONF_SECTION_END },
	{ CAMEL_PROVIDER_CONF_SECTION_START, "folders", NULL,
	  N_("Folders") },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "use-subscriptions", NULL,
	  N_("_Show only subscribed folders"), "0" },
#if 0
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "use-namespace", NULL,
	  N_("O_verride server-supplied folder namespace"), "0" },
	{ CAMEL_PROVIDER_CONF_ENTRY, "namespace", "use-namespace",
	  N_("Namespace:") },
#endif
	{ CAMEL_PROVIDER_CONF_SECTION_END },
	{ CAMEL_PROVIDER_CONF_SECTION_START, "general", NULL, N_("Options") },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "filter-all", NULL,
	  N_("Apply _filters to new messages in all folders"), "0" },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "filter-inbox", "!filter-all",
	  N_("_Apply filters to new messages in Inbox on this server"), "1" },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "filter-junk", NULL,
	  N_("Check new messages for _Junk contents"), "0" },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "filter-junk-inbox", "filter-junk",
	  N_("Only check for Junk messages in the In_box folder"), "0" },
	{ CAMEL_PROVIDER_CONF_CHECKBOX, "stay-synchronized", NULL,
	  N_("Synchroni_ze remote mail locally in all folders"), "0" },
	{ CAMEL_PROVIDER_CONF_PLACEHOLDER, "imapx-limit-by-age-placeholder", NULL },
	{ CAMEL_PROVIDER_CONF_SECTION_END },
	{ CAMEL_PROVIDER_CONF_END }
};

CamelProviderPortEntry imapx_port_entries[] = {
	{ 143, N_("Default IMAP port"), FALSE },
	{ 993, N_("IMAP over TLS"), TRUE },
	{ 0, NULL, 0 }
};

static CamelProvider imapx_provider = {
	"imapx",

	N_("IMAP"),

	N_("For reading and storing mail on IMAP servers."),

	"mail",

	CAMEL_PROVIDER_IS_REMOTE | CAMEL_PROVIDER_IS_SOURCE |
	CAMEL_PROVIDER_IS_STORAGE | CAMEL_PROVIDER_SUPPORTS_SSL|
	CAMEL_PROVIDER_SUPPORTS_MOBILE_DEVICES |
	CAMEL_PROVIDER_SUPPORTS_BATCH_FETCH |
	CAMEL_PROVIDER_SUPPORTS_PURGE_MESSAGE_CACHE,

	CAMEL_URL_NEED_USER | CAMEL_URL_NEED_HOST | CAMEL_URL_ALLOW_AUTH,

	imapx_conf_entries,

	imapx_port_entries,

	/* ... */
};

extern CamelServiceAuthType camel_imapx_password_authtype;

void camel_imapx_module_init (void);

void
camel_imapx_module_init (void)
{
	imapx_provider.object_types[CAMEL_PROVIDER_STORE] =
		CAMEL_TYPE_IMAPX_STORE;
	imapx_provider.url_hash = imapx_url_hash;
	imapx_provider.url_equal = imapx_url_equal;
	imapx_provider.authtypes = camel_sasl_authtype_list (FALSE);
	imapx_provider.authtypes = g_list_prepend (
		imapx_provider.authtypes, &camel_imapx_password_authtype);
	imapx_provider.translation_domain = GETTEXT_PACKAGE;

	camel_provider_register (&imapx_provider);
}

void
camel_provider_module_init (void)
{
	camel_imapx_module_init ();
}

static void
imapx_add_hash (guint *hash,
                gchar *s)
{
	if (s)
		*hash ^= g_str_hash(s);
}

static guint
imapx_url_hash (gconstpointer key)
{
	const CamelURL *u = (CamelURL *) key;
	guint hash = 0;

	imapx_add_hash (&hash, u->user);
	imapx_add_hash (&hash, u->host);
	hash ^= u->port;

	return hash;
}

static gint
imapx_check_equal (gchar *s1,
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
imapx_url_equal (gconstpointer a,
                 gconstpointer b)
{
	const CamelURL *u1 = a, *u2 = b;

	return imapx_check_equal (u1->protocol, u2->protocol)
		&& imapx_check_equal (u1->user, u2->user)
		&& imapx_check_equal (u1->host, u2->host)
		&& u1->port == u2->port;
}
