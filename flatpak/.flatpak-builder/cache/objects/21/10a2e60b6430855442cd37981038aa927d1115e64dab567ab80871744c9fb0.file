/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-provider.h :  provider definition
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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 *          Jeffrey Stedfast <fejj@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_PROVIDER_H
#define CAMEL_PROVIDER_H

#include <glib-object.h>

#include <camel/camel-enums.h>
#include <camel/camel-object-bag.h>
#include <camel/camel-url.h>

#define CAMEL_PROVIDER(obj) ((CamelProvider *)(obj))
#define CAMEL_TYPE_PROVIDER \
	(camel_provider_get_type ())

/**
 * EDS_CAMEL_PROVIDER_DIR:
 *
 * This environment variable configures where the camel
 * provider modules are loaded from.
 */
#define EDS_CAMEL_PROVIDER_DIR    "EDS_CAMEL_PROVIDER_DIR"

G_BEGIN_DECLS

extern gchar *camel_provider_type_name[CAMEL_NUM_PROVIDER_TYPES];

/* Flags for url_flags. "ALLOW" means the config dialog will let the
 * user configure it. "NEED" implies "ALLOW" but means the user must
 * configure it. Service code can assume that any url part for which
 * it has set the NEED flag will be set when the service is
 * created. "HIDE" also implies "ALLOW", but the setting will be
 * hidden/no widgets created for it.
 */
#define CAMEL_URL_PART_USER	 (1 << 0)
#define CAMEL_URL_PART_AUTH	 (1 << 1)
#define CAMEL_URL_PART_PASSWORD	 (1 << 2)
#define CAMEL_URL_PART_HOST	 (1 << 3)
#define CAMEL_URL_PART_PORT	 (1 << 4)
#define CAMEL_URL_PART_PATH	 (1 << 5)
#define CAMEL_URL_PART_PATH_DIR  (1 << 6)

#define CAMEL_URL_PART_NEED	       8
#define CAMEL_URL_PART_HIDDEN	(CAMEL_URL_PART_NEED + 8)

/* Use these macros to test a provider's url_flags */
#define CAMEL_PROVIDER_ALLOWS(prov, flags) \
	(prov->url_flags & (flags | (flags << CAMEL_URL_PART_NEED) | (flags << CAMEL_URL_PART_HIDDEN)))
#define CAMEL_PROVIDER_NEEDS(prov, flags) \
	(prov->url_flags & (flags << CAMEL_URL_PART_NEED))
#define CAMEL_PROVIDER_HIDDEN(prov, flags) \
	(prov->url_flags & (flags << CAMEL_URL_PART_HIDDEN))

/* Providers use these macros to actually define their url_flags */
typedef enum {
	CAMEL_URL_ALLOW_USER = CAMEL_URL_PART_USER,
	CAMEL_URL_ALLOW_AUTH = CAMEL_URL_PART_AUTH,
	CAMEL_URL_ALLOW_PASSWORD = CAMEL_URL_PART_PASSWORD,
	CAMEL_URL_ALLOW_HOST = CAMEL_URL_PART_HOST,
	CAMEL_URL_ALLOW_PORT = CAMEL_URL_PART_PORT,
	CAMEL_URL_ALLOW_PATH = CAMEL_URL_PART_PATH,

	CAMEL_URL_NEED_USER = CAMEL_URL_PART_USER << CAMEL_URL_PART_NEED,
	CAMEL_URL_NEED_AUTH = CAMEL_URL_PART_AUTH << CAMEL_URL_PART_NEED,
	CAMEL_URL_NEED_PASSWORD = CAMEL_URL_PART_PASSWORD << CAMEL_URL_PART_NEED,
	CAMEL_URL_NEED_HOST = CAMEL_URL_PART_HOST << CAMEL_URL_PART_NEED,
	CAMEL_URL_NEED_PORT = CAMEL_URL_PART_PORT << CAMEL_URL_PART_NEED,
	CAMEL_URL_NEED_PATH = CAMEL_URL_PART_PATH << CAMEL_URL_PART_NEED,
	CAMEL_URL_NEED_PATH_DIR = CAMEL_URL_PART_PATH_DIR << CAMEL_URL_PART_NEED,

	CAMEL_URL_HIDDEN_USER = CAMEL_URL_PART_USER << CAMEL_URL_PART_HIDDEN,
	CAMEL_URL_HIDDEN_AUTH = CAMEL_URL_PART_AUTH << CAMEL_URL_PART_HIDDEN,
	CAMEL_URL_HIDDEN_PASSWORD = CAMEL_URL_PART_PASSWORD << CAMEL_URL_PART_HIDDEN,
	CAMEL_URL_HIDDEN_HOST = CAMEL_URL_PART_HOST << CAMEL_URL_PART_HIDDEN,
	CAMEL_URL_HIDDEN_PORT = CAMEL_URL_PART_PORT << CAMEL_URL_PART_HIDDEN,
	CAMEL_URL_HIDDEN_PATH = CAMEL_URL_PART_PATH << CAMEL_URL_PART_HIDDEN,

	CAMEL_URL_FRAGMENT_IS_PATH = 1 << 30, /* url uses fragment for folder name path, not path */
	CAMEL_URL_PATH_IS_ABSOLUTE = 1 << 31,
} CamelProviderURLFlags;

#define CAMEL_PROVIDER_IS_STORE_AND_TRANSPORT(provider) \
	((provider != NULL) && \
	(provider->object_types[CAMEL_PROVIDER_STORE] != G_TYPE_INVALID) && \
	(provider->object_types[CAMEL_PROVIDER_TRANSPORT] != G_TYPE_INVALID))

/* Generic extra config stuff */

typedef struct {
	CamelProviderConfType type;
	const gchar *name, *depname;
	const gchar *text, *value;
} CamelProviderConfEntry;

/**
 * CamelProviderPortEntry:
 * @port: port number
 * @desc: human description of the port
 * @is_ssl: a boolean whether the port is used together with TLS/SSL
 *
 * Since: 3.2
 **/
typedef struct {
	gint port;
	const gchar *desc;
	gboolean is_ssl;
} CamelProviderPortEntry;

typedef gint (*CamelProviderAutoDetectFunc) (CamelURL *url, GHashTable **auto_detected, GError **error);

typedef struct {
	/* Provider protocol name (e.g. "imap", "smtp"). */
	const gchar *protocol;

	/* Provider name as used by people. (May be the same as protocol) */
	const gchar *name;

	/* Description of the provider. A novice user should be able
	 * to read this description, and the information provided by
	 * an ISP, IS department, etc, and determine whether or not
	 * this provider is relevant to him, and if so, which
	 * information goes with it.
	 */
	const gchar *description;

	/* The category of message that this provider works with.
	 * (evolution-mail will only list a provider in the store/transport
	 * config dialogs if its domain is "mail".)
	 */
	const gchar *domain;

	/* Flags describing the provider, flags describing its URLs */
	CamelProviderFlags flags;
	CamelProviderURLFlags url_flags;

	/* The ConfEntry and AutoDetect functions will probably be
	 * DEPRECATED in a future release */

	/* Extra configuration information */
	CamelProviderConfEntry *extra_conf;

	/* The list of CamelProviderPortEntry structs. Each struct contains 
	 * port number and a short string description ("Default IMAP port"
	 * or "POP3 over SSL" etc.
	 */
	CamelProviderPortEntry *port_entries;

	/* auto-detection function */
	CamelProviderAutoDetectFunc auto_detect;

	/* GType(s) of its store and/or transport. If both are
	 * set, then they are assumed to be linked together and the
	 * transport type can only be used in an account that also
	 * uses the store type (eg, Exchange or NNTP).
	 */
	GType object_types[CAMEL_NUM_PROVIDER_TYPES];

	/* GList of CamelServiceAuthTypes the provider supports */
	GList *authtypes;

	GHashFunc url_hash;
	GEqualFunc url_equal;

	/* gettext translation domain (NULL for providers in the
	 * evolution source tree).
	 */
	const gchar *translation_domain;

	/* Private to the provider */
	gpointer priv;
} CamelProvider;

typedef struct _CamelProviderModule CamelProviderModule;

struct _CamelProviderModule {
	gchar *path;
	GSList *types;
	guint loaded : 1;
};

/* Introspection function */
GType		camel_provider_get_type		(void) G_GNUC_CONST;

void		camel_provider_init		(void);
gboolean	camel_provider_load		(const gchar *path,
						 GError **error);
void		camel_provider_register		(CamelProvider *provider);
GList *		camel_provider_list		(gboolean load);
CamelProvider *	camel_provider_get		(const gchar *protocol,
						 GError **error);

/* This is defined by each module, not by camel-provider.c. */
void		camel_provider_module_init	(void);

gint		camel_provider_auto_detect	(CamelProvider *provider,
						 CamelURL *url,
						 GHashTable **auto_detected,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_PROVIDER_H */
