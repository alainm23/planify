/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-provider.c: provider framework
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
 *          Dan Winship <danw@ximian.com>
 *          Jeffrey Stedfast <fejj@ximian.com>
 */

/* FIXME: Shouldn't we add a version number to providers ? */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>

#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>
#include <gmodule.h>

#include "camel-provider.h"
#include "camel-string-utils.h"
#include "camel-vee-store.h"
#include "camel-win32.h"

/* table of CamelProviderModule's */
static GHashTable *module_table;
/* table of CamelProvider's */
static GHashTable *provider_table;
static GRecMutex provider_lock;

#define LOCK()		(g_rec_mutex_lock(&provider_lock))
#define UNLOCK()	(g_rec_mutex_unlock(&provider_lock))

CamelProvider *	camel_provider_copy		(CamelProvider *provider);
void		camel_provider_free		(CamelProvider *provider);

G_DEFINE_BOXED_TYPE (CamelProvider, camel_provider, camel_provider_copy, camel_provider_free)

/*
 * camel_provider_copy:
 * @provider: a #CamelProvider to copy
 *
 * The function returns @provider, because providers are not allocated
 * on heap. It's defined only for the introspection purposes.
 *
 * Returns: (transfer full): the @provider
 *
 * Since: 3.24
 */
CamelProvider *
camel_provider_copy (CamelProvider *provider)
{
	return provider;
}

/*
 * camel_provider_free:
 * @provider: a #CamelProvider to copy
 *
 * The function does nothing, because providers are not allocated
 * on heap. It's defined only for the introspection purposes.
 *
 * Since: 3.24
 */
void
camel_provider_free (CamelProvider *provider)
{
}

/* The vfolder provider is always available */
static CamelProvider vee_provider = {
	"vfolder",
	N_("Virtual folder email provider"),

	N_("For reading mail as a query of another set of folders"),

	"vfolder",

	CAMEL_PROVIDER_IS_STORAGE | CAMEL_PROVIDER_IS_LOCAL,
	CAMEL_URL_NEED_PATH | CAMEL_URL_PATH_IS_ABSOLUTE | CAMEL_URL_FRAGMENT_IS_PATH,

	NULL,	/* extra conf */

	NULL,   /* port providers */

	/* ... */
};

static GOnce setup_once = G_ONCE_INIT;

static void
provider_register_internal (CamelProvider *provider)
{
	CamelProviderConfEntry *conf;
	CamelProviderPortEntry *port;
	GList *link;
	gint ii;

	g_return_if_fail (provider != NULL);
	g_return_if_fail (provider->protocol != NULL);

	LOCK ();

	if (g_hash_table_lookup (provider_table, provider->protocol) != NULL) {
		g_warning (
			"Trying to re-register CamelProvider for protocol '%s'",
			provider->protocol);
		UNLOCK ();
		return;
	}

	/* Translate all strings here */
#define P_(string) dgettext (provider->translation_domain, string)

	provider->name = P_(provider->name);
	if (provider->description)
		provider->description = P_(provider->description);

	conf = provider->extra_conf;
	if (conf != NULL) {
		for (ii = 0; conf[ii].type != CAMEL_PROVIDER_CONF_END; ii++) {
			if (conf[ii].text && conf[ii].text[0])
				conf[ii].text = P_(conf[ii].text);
		}
	}

	for (link = provider->authtypes; link != NULL; link = link->next) {
		CamelServiceAuthType *auth = link->data;

		auth->name = P_(auth->name);
		auth->description = P_(auth->description);
	}

	if (provider->port_entries != NULL) {
		provider->url_flags |= CAMEL_URL_NEED_PORT;
		port = provider->port_entries;
		for (ii = 0; port[ii].port != 0; ii++)
			if (port[ii].desc != NULL)
				port[ii].desc = P_(port[ii].desc);
	} else {
		provider->url_flags &= ~CAMEL_URL_NEED_PORT;
	}

	g_hash_table_insert (
		provider_table,
		(gpointer) provider->protocol, provider);

	UNLOCK ();
}

static gpointer
provider_setup (gpointer param)
{
	module_table = g_hash_table_new (
		(GHashFunc) camel_strcase_hash,
		(GEqualFunc) camel_strcase_equal);
	provider_table = g_hash_table_new (
		(GHashFunc) camel_strcase_hash,
		(GEqualFunc) camel_strcase_equal);

	vee_provider.object_types[CAMEL_PROVIDER_STORE] = CAMEL_TYPE_VEE_STORE;
	vee_provider.url_hash = (GHashFunc) camel_url_hash;
	vee_provider.url_equal = (GEqualFunc) camel_url_equal;
	provider_register_internal (&vee_provider);

	return NULL;
}

/**
 * camel_provider_init:
 *
 * Initialize the Camel provider system by reading in the .urls
 * files in the provider directory and creating a hash table mapping
 * URLs to module names.
 *
 * A .urls file has the same initial prefix as the shared library it
 * correspond to, and consists of a series of lines containing the URL
 * protocols that that library handles.
 *
 * TODO: This should be pathed?
 * TODO: This should be plugin-d?
 **/
void
camel_provider_init (void)
{
	GDir *dir;
	const gchar *entry;
	gchar *p, *name, buf[80];
	static gint loaded = 0;
	const gchar *provider_dir;

	provider_dir = g_getenv (EDS_CAMEL_PROVIDER_DIR);
	if (!provider_dir)
		provider_dir = CAMEL_PROVIDERDIR;

	g_once (&setup_once, provider_setup, NULL);

	if (loaded)
		return;

	loaded = 1;

	dir = g_dir_open (provider_dir, 0, NULL);
	if (!dir) {
		g_warning (
			"Could not open camel provider directory (%s): %s",
			provider_dir, g_strerror (errno));
		return;
	}

	while ((entry = g_dir_read_name (dir))) {
		CamelProviderModule *m = NULL;
		FILE *fp;

		p = strrchr (entry, '.');
		if (!p || strcmp (p, ".urls") != 0)
			continue;

		name = g_strdup_printf ("%s/%s", provider_dir, entry);
		fp = g_fopen (name, "r");
		if (!fp) {
			g_warning (
				"Could not read provider info file %s: %s",
				name, g_strerror (errno));
			g_free (name);
			continue;
		}

		p = strrchr (name, '.');
		if (p)
			strcpy (p, "." G_MODULE_SUFFIX);

		while ((fgets (buf, sizeof (buf), fp))) {
			buf[sizeof (buf) - 1] = '\0';
			p = strchr (buf, '\n');
			if (p)
				*p = '\0';

			if (*buf) {
				gchar *protocol = g_strdup (buf);

				if (!m) {
					m = g_malloc0 (sizeof (*m));
					m->path = name;
				}

				m->types = g_slist_prepend (m->types, protocol);
				g_hash_table_insert (module_table, protocol, m);
			}
		}

		if (!m)
			g_free (name);
		fclose (fp);
	}

	g_dir_close (dir);
}

/**
 * camel_provider_load:
 * @path: the path to a shared library
 * @error: return location for a #GError, or %NULL
 *
 * Loads the provider at @path, and calls its initialization function,
 * passing @session as an argument. The provider should then register
 * itself with @session.
 *
 * Returns: %TRUE on success, %FALSE on failure
 **/
gboolean
camel_provider_load (const gchar *path,
                     GError **error)
{
	GModule *module;
	CamelProvider *(*provider_module_init) (void);

	g_once (&setup_once, provider_setup, NULL);

	if (!g_module_supported ()) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Could not load %s: Module loading "
			"not supported on this system."), path);
		return FALSE;
	}

	module = g_module_open (path, G_MODULE_BIND_LAZY);
	if (module == NULL) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Could not load %s: %s"),
			path, g_module_error ());
		return FALSE;
	}

	if (!g_module_symbol (module, "camel_provider_module_init",
			      (gpointer *) &provider_module_init)) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Could not load %s: No initialization "
			"code in module."), path);
		g_module_close (module);
		return FALSE;
	}

	provider_module_init ();

	return TRUE;
}

/**
 * camel_provider_register:
 * @provider: provider object
 *
 * Registers a provider.
 **/
void
camel_provider_register (CamelProvider *provider)
{
	g_once (&setup_once, provider_setup, NULL);

	provider_register_internal (provider);
}

static gint
provider_compare (gconstpointer a,
                  gconstpointer b)
{
	const CamelProvider *cpa = (const CamelProvider *) a;
	const CamelProvider *cpb = (const CamelProvider *) b;

	return strcmp (cpa->name, cpb->name);
}

static void
add_to_list (gpointer key,
             gpointer value,
             gpointer user_data)
{
	GList **list = user_data;

	*list = g_list_prepend(*list, value);
}

/**
 * camel_provider_list:
 * @load: whether or not to load in providers that are not already loaded
 *
 * This returns a list of available providers. If @load is %TRUE, it will
 * first load in all available providers that haven't yet been loaded.
 *
 * Free the returned list with g_list_free().  The #CamelProvider structs
 * in the list are owned by Camel and should not be modified or freed.
 *
 * Returns: (element-type CamelProvider) (transfer container): a #GList of #CamelProvider structs
 **/
GList *
camel_provider_list (gboolean load)
{
	GList *list = NULL;

	/* provider_table can be NULL, so initialize it */
	if (G_UNLIKELY (provider_table == NULL))
		camel_provider_init ();

	g_return_val_if_fail (provider_table != NULL, NULL);

	LOCK ();

	if (load) {
		GList *w;

		g_hash_table_foreach (module_table, add_to_list, &list);
		for (w = list; w; w = w->next) {
			CamelProviderModule *m = w->data;
			GError *error = NULL;

			if (!m->loaded) {
				camel_provider_load (m->path, &error);
				m->loaded = 1;
			}

			if (error != NULL) {
				g_critical (
					"%s: %s", G_STRFUNC,
					error->message);
				g_error_free (error);
			}
		}
		g_list_free (list);
		list = NULL;
	}

	g_hash_table_foreach (provider_table, add_to_list, &list);

	UNLOCK ();

	list = g_list_sort (list, provider_compare);

	return list;
}

/**
 * camel_provider_get:
 * @protocol: a #CamelProvider protocol name
 * @error: return location for a #GError, or %NULL
 *
 * Returns the registered #CamelProvider for @protocol, loading it
 * from disk if necessary.  If no #CamelProvider can be found for
 * @protocol, or the provider module fails to load, the function
 * sets @error and returns %NULL.
 *
 * The returned #CamelProvider is owned by Camel and should not be
 * modified or freed.
 *
 * Returns: a #CamelProvider for @protocol, or %NULL
 **/
CamelProvider *
camel_provider_get (const gchar *protocol,
                    GError **error)
{
	CamelProvider *provider = NULL;

	g_return_val_if_fail (protocol != NULL, NULL);
	g_return_val_if_fail (provider_table != NULL, NULL);

	LOCK ();

	provider = g_hash_table_lookup (provider_table, protocol);
	if (provider == NULL) {
		CamelProviderModule *module;

		module = g_hash_table_lookup (module_table, protocol);
		if (module != NULL && !module->loaded) {
			module->loaded = 1;
			if (!camel_provider_load (module->path, error))
				goto fail;
		}
		provider = g_hash_table_lookup (provider_table, protocol);
	}

	if (provider == NULL)
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_URL_INVALID,
			_("No provider available for protocol “%s”"),
			protocol);
fail:
	UNLOCK ();

	return provider;
}

/**
 * camel_provider_auto_detect:
 * @provider: camel provider
 * @url: a #CamelURL
 * @auto_detected: (inout): output hash table of auto-detected values
 * @error: return location for a #GError, or %NULL
 *
 * After filling in the standard Username/Hostname/Port/Path settings
 * (which must be set in @url), if the provider supports it, you
 * may wish to have the provider auto-detect further settings based on
 * the aformentioned settings.
 *
 * If the provider does not support auto-detection, @auto_detected
 * will be set to %NULL. Otherwise the provider will attempt to
 * auto-detect whatever it can and file them into @auto_detected. If
 * for some reason it cannot auto-detect anything (not enough
 * information provided in @url?) then @auto_detected will be
 * set to %NULL and an exception may be set to explain why it failed.
 *
 * Returns: 0 on success or -1 on fail.
 **/
gint
camel_provider_auto_detect (CamelProvider *provider,
                            CamelURL *url,
                            GHashTable **auto_detected,
                            GError **error)
{
	g_return_val_if_fail (provider != NULL, -1);

	if (provider->auto_detect) {
		return provider->auto_detect (url, auto_detected, error);
	} else {
		*auto_detected = NULL;
		return 0;
	}
}
