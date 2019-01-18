/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2016 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * SECTION:as-pool
 * @short_description: Access the AppStream metadata pool.
 *
 * This class loads AppStream metadata from various sources and refines it with existing
 * knowledge about the system (e.g. by setting absolute pazhs for cached icons).
 * An #AsPool will use an on-disk cache to store metadata is has read and refined to
 * speed up the loading time when the same data is requested a second time.
 *
 * You can find AppStream metadata matching farious criteria, and also add new metadata to
 * the pool.
 * The caching behavior can be controlled by the application using #AsPool.
 *
 * An AppStream cache object can also be created and read using the appstreamcli(1) utility.
 *
 * See also: #AsComponent
 */

#include "config.h"
#include "as-pool.h"
#include "as-pool-private.h"

#include <glib.h>
#include <glib/gstdio.h>
#include <gio/gio.h>
#include <glib/gi18n-lib.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

#include "as-utils.h"
#include "as-utils-private.h"
#include "as-component-private.h"
#include "as-distro-details.h"
#include "as-settings-private.h"
#include "as-distro-extras.h"
#include "as-stemmer.h"
#include "as-variant-cache.h"

#include "as-metadata.h"

typedef struct
{
	GHashTable *cpt_table;
	GHashTable *known_cids;
	gchar *screenshot_service_url;
	gchar *locale;
	gchar *current_arch;

	GPtrArray *xml_dirs;
	GPtrArray *yaml_dirs;
	GPtrArray *icon_dirs;

	gchar **term_greylist;

	AsPoolFlags flags;
	AsCacheFlags cache_flags;
	gboolean prefer_local_metainfo;

	gchar *sys_cache_path;
	gchar *user_cache_path;
	time_t cache_ctime;
} AsPoolPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsPool, as_pool, G_TYPE_OBJECT)
#define GET_PRIVATE(o) (as_pool_get_instance_private (o))

/**
 * AS_APPSTREAM_METADATA_PATHS:
 *
 * Locations where system AppStream metadata can be stored.
 */
const gchar *AS_APPSTREAM_METADATA_PATHS[4] = { "/usr/share/app-info",
						"/var/lib/app-info",
						"/var/cache/app-info",
						NULL};

/* TRANSLATORS: List of "grey-listed" words sperated with ";"
 * Do not translate this list directly. Instead,
 * provide a list of words in your language that people are likely
 * to include in a search but that should normally be ignored in
 * the search.
 */
#define AS_SEARCH_GREYLIST_STR _("app;application;package;program;programme;suite;tool")

/* where .desktop files are installed to by packages to be registered with the system */
static gchar *APPLICATIONS_DIR = "/usr/share/applications";

/* where metainfo files can be found */
static gchar *METAINFO_DIR = "/usr/share/metainfo";

static void as_pool_add_metadata_location_internal (AsPool *pool, const gchar *directory, gboolean add_root);

/**
 * as_pool_check_cache_ctime:
 * @pool: An instance of #AsPool
 *
 * Update the cached cache-ctime. We need to cache it prior to potentially
 * creating a new database, so we will always rebuild the database in case
 * none existed previously.
 */
static void
as_pool_check_cache_ctime (AsPool *pool)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	struct stat cache_sbuf;
	g_autofree gchar *fname = NULL;

	fname = g_strdup_printf ("%s/%s.gvz", priv->sys_cache_path, priv->locale);
	if (stat (fname, &cache_sbuf) < 0)
		priv->cache_ctime = 0;
	else
		priv->cache_ctime = cache_sbuf.st_ctime;
}

/**
 * as_pool_init:
 **/
static void
as_pool_init (AsPool *pool)
{
	guint i;
	g_autoptr(AsDistroDetails) distro = NULL;
	AsPoolPrivate *priv = GET_PRIVATE (pool);

	/* set active locale */
	priv->locale = as_get_current_locale ();

	/* stores known components */
	priv->cpt_table = g_hash_table_new_full (g_str_hash,
						g_str_equal,
						g_free,
						(GDestroyNotify) g_object_unref);

	/* set which stores whether we have seen a component-ID already */
	priv->known_cids = g_hash_table_new_full (g_str_hash,
						  g_str_equal,
						  g_free,
						  NULL);

	priv->xml_dirs = g_ptr_array_new_with_free_func (g_free);
	priv->yaml_dirs = g_ptr_array_new_with_free_func (g_free);
	priv->icon_dirs = g_ptr_array_new_with_free_func (g_free);

	/* set the current architecture */
	priv->current_arch = as_get_current_arch ();

	/* set up our localized search-term greylist */
	priv->term_greylist = g_strsplit (AS_SEARCH_GREYLIST_STR, ";", -1);

	/* system-wide cache locations */
	priv->sys_cache_path = g_strdup (AS_APPSTREAM_CACHE_PATH);

	if (as_utils_is_root ()) {
		/* users umask shouldn't interfere with us creating new files when we are root */
		as_reset_umask ();

		/* ensure we never start gvfsd as root: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=852696 */
		g_setenv ("GIO_USE_VFS", "local", TRUE);
	}

	/* check the ctime of the cache directory, if it exists at all */
	as_pool_check_cache_ctime (pool);

	distro = as_distro_details_new ();
	priv->screenshot_service_url = as_distro_details_get_str (distro, "ScreenshotUrl");

	/* check whether we might want to prefer local metainfo files over remote data */
	priv->prefer_local_metainfo = as_distro_details_get_bool (distro, "PreferLocalMetainfoData", FALSE);

	/* set watched default directories for AppStream metadata */
	for (i = 0; AS_APPSTREAM_METADATA_PATHS[i] != NULL; i++)
		as_pool_add_metadata_location_internal (pool, AS_APPSTREAM_METADATA_PATHS[i], FALSE);

	/* set default pool flags */
	priv->flags = AS_POOL_FLAG_READ_COLLECTION | AS_POOL_FLAG_READ_METAINFO;

	/* set default cache flags */
	priv->cache_flags = AS_CACHE_FLAG_USE_SYSTEM | AS_CACHE_FLAG_USE_USER;
}

/**
 * as_pool_finalize:
 **/
static void
as_pool_finalize (GObject *object)
{
	AsPool *pool = AS_POOL (object);
	AsPoolPrivate *priv = GET_PRIVATE (pool);

	g_free (priv->screenshot_service_url);
	g_hash_table_unref (priv->cpt_table);
	g_hash_table_unref (priv->known_cids);

	g_ptr_array_unref (priv->xml_dirs);
	g_ptr_array_unref (priv->yaml_dirs);
	g_ptr_array_unref (priv->icon_dirs);

	g_free (priv->locale);
	g_free (priv->current_arch);

	g_strfreev (priv->term_greylist);

	g_free (priv->sys_cache_path);
	g_free (priv->user_cache_path);

	G_OBJECT_CLASS (as_pool_parent_class)->finalize (object);
}

/**
 * as_pool_class_init:
 **/
static void
as_pool_class_init (AsPoolClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_pool_finalize;
}

/**
 * as_pool_add_component_internal:
 * @pool: An instance of #AsPool
 * @cpt: The #AsComponent to add to the pool.
 * @pedantic_noadd: If %TRUE, always emit an error if component couldn't be added.
 * @error: A #GError or %NULL
 *
 * Internal.
 */
static gboolean
as_pool_add_component_internal (AsPool *pool, AsComponent *cpt, gboolean pedantic_noadd, GError **error)
{
	const gchar *cdid = NULL;
	AsComponent *existing_cpt;
	gint pool_priority;
	AsOriginKind new_cpt_orig_kind;
	AsOriginKind existing_cpt_orig_kind;
	AsMergeKind new_cpt_merge_kind;
	AsPoolPrivate *priv = GET_PRIVATE (pool);

	cdid = as_component_get_data_id (cpt);
	if (as_component_is_ignored (cpt)) {
		if (pedantic_noadd)
			g_set_error (error,
					AS_POOL_ERROR,
					AS_POOL_ERROR_FAILED,
					"Skipping '%s' from inclusion into the pool: Component is ignored.", cdid);
		return FALSE;
	}

	existing_cpt = g_hash_table_lookup (priv->cpt_table, cdid);
	if (as_component_get_origin_kind (cpt) == AS_ORIGIN_KIND_DESKTOP_ENTRY) {
		g_autofree gchar *tmp_cdid = NULL;

		/* .desktop entries might map to existing metadata data with or without .desktop suffix, we need to check for that.
		 * (the .desktop suffix is optional for desktop-application metainfo files, and the desktop-entry parser will automatically
		 * omit it if the desktop-entry-id is following the reverse DNS scheme)
		 */
		if (existing_cpt == NULL) {
			tmp_cdid = g_strdup_printf ("%s.desktop", cdid);
			existing_cpt = g_hash_table_lookup (priv->cpt_table, tmp_cdid);
		}

		if (existing_cpt != NULL) {
			if (as_component_get_origin_kind (existing_cpt) != AS_ORIGIN_KIND_DESKTOP_ENTRY) {
				/* discard this component if we have better data already in the pool,
				 * which is basically anything *but* data from a .desktop file */
				g_debug ("Ignored .desktop metadata for '%s': We already have better data.", cdid);
				return FALSE;
			}
		}
	}

	/* perform metadata merges if necessary */
	new_cpt_merge_kind = as_component_get_merge_kind (cpt);
	if (new_cpt_merge_kind != AS_MERGE_KIND_NONE) {
		g_autoptr(GPtrArray) matches = NULL;
		guint i;

		/* we merge the data into all components with matching IDs at time */
		matches = as_pool_get_components_by_id (pool,
							as_component_get_id (cpt));
		for (i = 0; i < matches->len; i++) {
			AsComponent *match = AS_COMPONENT (g_ptr_array_index (matches, i));
			if (new_cpt_merge_kind == AS_MERGE_KIND_REMOVE_COMPONENT) {
				/* remove matching component from pool if its priority is lower */
				if (as_component_get_priority (match) < as_component_get_priority (cpt)) {
					const gchar *match_cdid = as_component_get_data_id (match);
					g_hash_table_remove (priv->cpt_table, match_cdid);
					g_debug ("Removed via merge component: %s", match_cdid);
				}
			} else {
				as_component_merge (match, cpt);
			}
		}

		return TRUE;
	}

	if (existing_cpt == NULL) {
		g_hash_table_insert (priv->cpt_table,
					g_strdup (cdid),
					g_object_ref (cpt));
		g_hash_table_add (priv->known_cids,
				  g_strdup (as_component_get_id (cpt)));
		return TRUE;
	}

	/* safety check so we don't ignore a good component because we added a bad one first */
	if (!as_component_is_valid (existing_cpt)) {
		g_debug ("Replacing invalid component '%s' with new one.", cdid);
		g_hash_table_replace (priv->cpt_table,
				      g_strdup (cdid),
				      g_object_ref (cpt));
		return TRUE;
	}

	new_cpt_orig_kind = as_component_get_origin_kind (cpt);
	existing_cpt_orig_kind = as_component_get_origin_kind (existing_cpt);

	/* always replace data from .desktop entries */
	if (existing_cpt_orig_kind == AS_ORIGIN_KIND_DESKTOP_ENTRY) {
		if (new_cpt_orig_kind == AS_ORIGIN_KIND_METAINFO) {
			/* do an append-merge to ensure the data from an existing metainfo file has an icon */
			as_component_merge_with_mode (cpt,
							existing_cpt,
							AS_MERGE_KIND_APPEND);

			g_hash_table_replace (priv->cpt_table,
				g_strdup (cdid),
				g_object_ref (cpt));
			g_debug ("Replaced '%s' with data from metainfo and desktop-entry file.", cdid);
			return TRUE;
		} else {
			as_component_set_priority (existing_cpt, -G_MAXINT);
		}
	}

	/* merge desktop-entry data in, if we already have existing data from a metainfo file */
	if (new_cpt_orig_kind == AS_ORIGIN_KIND_DESKTOP_ENTRY) {
		if (existing_cpt_orig_kind == AS_ORIGIN_KIND_METAINFO) {
			/* do an append-merge to ensure the metainfo file has an icon */
			as_component_merge_with_mode (existing_cpt,
						      cpt,
						      AS_MERGE_KIND_APPEND);
			g_debug ("Merged desktop-entry data into metainfo data for '%s'.", cdid);
			return TRUE;
		}
		if (existing_cpt_orig_kind == AS_ORIGIN_KIND_COLLECTION) {
			g_debug ("Ignored desktop-entry component '%s': We already have better data.", cdid);
			return FALSE;
		}
	}

	/* check whether we should prefer data from metainfo files over preexisting data */
	if ((priv->prefer_local_metainfo) &&
	    (new_cpt_orig_kind == AS_ORIGIN_KIND_METAINFO)) {
		/* update package info, metainfo files do never have this data.
		 * (we hope that collection data was loaded first here, so the existing_cpt already contains
		 *  the information we want - if that's not the case, no harm is done here) */
		as_component_set_pkgnames (cpt, as_component_get_pkgnames (existing_cpt));

		g_hash_table_replace (priv->cpt_table,
				g_strdup (cdid),
				g_object_ref (cpt));
		g_debug ("Replaced '%s' with data from metainfo file.", cdid);
		return TRUE;
	}

	/* if we are here, we might have duplicates and no merges, so check if we should replace a component
	 * with data of higher priority, or if we have an actual error in the metadata */
	pool_priority = as_component_get_priority (existing_cpt);
	if (pool_priority < as_component_get_priority (cpt)) {
		g_hash_table_replace (priv->cpt_table,
					g_strdup (cdid),
					g_object_ref (cpt));
		g_debug ("Replaced '%s' with data of higher priority.", cdid);
	} else {
		/* bundles are treated specially here */
		if ((!as_component_has_bundle (existing_cpt)) && (as_component_has_bundle (cpt))) {
			GPtrArray *bundles;
			/* propagate bundle information to existing component */
			bundles = as_component_get_bundles (cpt);
			as_component_set_bundles_array (existing_cpt, bundles);
			return TRUE;
		}

		/* experimental multiarch support */
		if (as_component_get_architecture (cpt) != NULL) {
			if (as_arch_compatible (as_component_get_architecture (cpt), priv->current_arch)) {
				const gchar *earch;
				/* this component is compatible with our current architecture */

				earch = as_component_get_architecture (existing_cpt);
				if (earch != NULL) {
					if (as_arch_compatible (earch, priv->current_arch)) {
						g_hash_table_replace (priv->cpt_table,
									g_strdup (cdid),
									g_object_ref (cpt));
						g_debug ("Preferred component for native architecture for %s (was %s)", cdid, earch);
						return TRUE;
					} else {
						g_debug ("Ignored additional entry for '%s' on architecture %s.", cdid, earch);
						return FALSE;
					}
				}
			}
		}

		if (pool_priority == as_component_get_priority (cpt)) {
			g_set_error (error,
					AS_POOL_ERROR,
					AS_POOL_ERROR_COLLISION,
					"Detected colliding IDs: %s was already added with the same priority.", cdid);
			return FALSE;
		} else {
			if (pedantic_noadd)
				g_set_error (error,
						AS_POOL_ERROR,
						AS_POOL_ERROR_COLLISION,
						"Detected colliding IDs: %s was already added with a higher priority.", cdid);
			return FALSE;
		}
	}

	return TRUE;
}

/**
 * as_pool_add_component:
 * @pool: An instance of #AsPool
 * @cpt: The #AsComponent to add to the pool.
 * @error: A #GError or %NULL
 *
 * Register a new component in the AppStream metadata pool.
 *
 * Returns: %TRUE if the new component was successfully added to the pool.
 */
gboolean
as_pool_add_component (AsPool *pool, AsComponent *cpt, GError **error)
{
	return as_pool_add_component_internal (pool, cpt, TRUE, error);
}

/**
 * as_pool_update_addon_info:
 *
 * Populate the "extensions" property of an #AsComponent, using the
 * "extends" information from other components.
 */
static void
as_pool_update_addon_info (AsPool *pool, AsComponent *cpt)
{
	guint i;
	GPtrArray *extends;
	AsPoolPrivate *priv = GET_PRIVATE (pool);

	extends = as_component_get_extends (cpt);
	if ((extends == NULL) || (extends->len == 0))
		return;

	for (i = 0; i < extends->len; i++) {
		AsComponent *extended_cpt;
		g_autofree gchar *extended_cdid = NULL;
		const gchar *extended_cid = (const gchar*) g_ptr_array_index (extends, i);

		extended_cdid = as_utils_build_data_id (AS_COMPONENT_SCOPE_SYSTEM, "os",
							as_utils_get_component_bundle_kind (cpt),
							extended_cid);

		extended_cpt = g_hash_table_lookup (priv->cpt_table, extended_cdid);
		if (extended_cpt == NULL) {
			g_debug ("%s extends %s, but %s was not found.", as_component_get_data_id (cpt), extended_cdid, extended_cdid);
			return;
		}

		/* don't add the same addon more than once */
		if (g_ptr_array_find (as_component_get_addons (extended_cpt), cpt, NULL))
			continue;

		as_component_add_addon (extended_cpt, cpt);
	}
}

/**
 * as_pool_refine_data:
 *
 * Automatically refine the data we have about software components in the pool.
 *
 * Returns: %TRUE if all metadata was used, %FALSE if we skipped some stuff.
 */
static guint
as_pool_refine_data (AsPool *pool)
{
	GHashTableIter iter;
	gpointer key, value;
	GHashTable *refined_cpts;
	guint invalid_cpts = 0;
	AsPoolPrivate *priv = GET_PRIVATE (pool);

	/* since we might remove stuff from the pool, we need a new table to store the result */
	refined_cpts = g_hash_table_new_full (g_str_hash,
						g_str_equal,
						g_free,
						(GDestroyNotify) g_object_unref);

	g_hash_table_iter_init (&iter, priv->cpt_table);
	while (g_hash_table_iter_next (&iter, &key, &value)) {
		AsComponent *cpt;
		const gchar *cdid;
		cpt = AS_COMPONENT (value);
		cdid = (const gchar*) key;

		/* validate the component */
		if (!as_component_is_valid (cpt)) {
			/* we still succeed if the components originates from a .desktop file -
			 * we care less about them and they generally have bad quality, so some issues
			 * pop up on pretty much every system */
			if (as_component_get_origin_kind (cpt) == AS_ORIGIN_KIND_DESKTOP_ENTRY) {
				g_debug ("Ignored '%s': The component (from a .desktop file) is invalid.", as_component_get_id (cpt));
			} else {
				g_debug ("WARNING: Ignored component '%s': The component is invalid.", as_component_get_id (cpt));
				invalid_cpts++;
			}
			continue;
		}

		/* add additional data to the component, e.g. external screenshots. Also refines
		* the component's icon paths */
		as_component_complete (cpt,
					priv->screenshot_service_url,
					priv->icon_dirs);

		/* set the "addons" information */
		as_pool_update_addon_info (pool, cpt);

		/* add to results table */
		g_hash_table_insert (refined_cpts,
					g_strdup (cdid),
					g_object_ref (cpt));
	}

	/* set refined components as new pool content */
	g_hash_table_unref (priv->cpt_table);
	priv->cpt_table = refined_cpts;

	return invalid_cpts;
}

/**
 * as_pool_clear:
 * @pool: An #AsPool.
 *
 * Remove all metadat from the pool.
 */
void
as_pool_clear (AsPool *pool)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	if (g_hash_table_size (priv->cpt_table) == 0)
		return;

	/* contents */
	g_hash_table_unref (priv->cpt_table);
	priv->cpt_table = g_hash_table_new_full (g_str_hash,
						 g_str_equal,
						 g_free,
						 (GDestroyNotify) g_object_unref);

	/* cid info set */
	g_hash_table_unref (priv->known_cids);
	priv->known_cids = g_hash_table_new_full (g_str_hash,
						  g_str_equal,
						  g_free,
						  NULL);
}

/**
 * as_pool_ctime_newer:
 *
 * Returns: %TRUE if ctime of file is newer than the cached time.
 */
static gboolean
as_pool_ctime_newer (AsPool *pool, const gchar *dir)
{
	struct stat sb;
	AsPoolPrivate *priv = GET_PRIVATE (pool);

	if (stat (dir, &sb) < 0)
		return FALSE;

	if (sb.st_ctime > priv->cache_ctime)
		return TRUE;

	return FALSE;
}

/**
 * as_pool_appstream_data_changed:
 */
static gboolean
as_pool_metadata_changed (AsPool *pool)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	guint i;

	for (i = 0; i < priv->xml_dirs->len; i++) {
		const gchar *dir = (const gchar*) g_ptr_array_index (priv->xml_dirs, i);
		if (as_pool_ctime_newer (pool, dir))
			return TRUE;
	}
	for (i = 0; i < priv->yaml_dirs->len; i++) {
		const gchar *dir = (const gchar*) g_ptr_array_index (priv->yaml_dirs, i);
		if (as_pool_ctime_newer (pool, dir))
			return TRUE;
	}

	return FALSE;
}

/**
 * as_pool_load_collection_data:
 *
 * Load fresh metadata from AppStream collection data directories.
 */
static gboolean
as_pool_load_collection_data (AsPool *pool, gboolean refresh, GError **error)
{
	GPtrArray *cpts;
	g_autoptr(GPtrArray) merge_cpts = NULL;
	guint i;
	gboolean ret;
	g_autoptr(AsMetadata) metad = NULL;
	g_autoptr(GPtrArray) mdata_files = NULL;
	GError *tmp_error = NULL;
	AsPoolPrivate *priv = GET_PRIVATE (pool);

	/* see if we can use the caches */
	if (!refresh) {
		if (!as_pool_metadata_changed (pool)) {
			g_autofree gchar *fname = NULL;
			g_debug ("Caches are up to date.");

			if (as_flags_contains (priv->cache_flags, AS_CACHE_FLAG_USE_SYSTEM)) {
				g_debug ("Using cached data.");

				fname = g_strdup_printf ("%s/%s.gvz", priv->sys_cache_path, priv->locale);
				if (g_file_test (fname, G_FILE_TEST_EXISTS)) {
					return as_pool_load_cache_file (pool, fname, error);
				} else {
					g_debug ("Missing cache for language '%s', attempting to load fresh data.", priv->locale);
				}
			} else {
				g_debug ("Not using system cache.");
			}
		}
	}

	/* prepare metadata parser */
	metad = as_metadata_new ();
	as_metadata_set_format_style (metad, AS_FORMAT_STYLE_COLLECTION);
	as_metadata_set_locale (metad, priv->locale);

	/* find AppStream metadata */
	ret = TRUE;
	mdata_files = g_ptr_array_new_with_free_func (g_free);

	/* find XML data */
	for (i = 0; i < priv->xml_dirs->len; i++) {
		const gchar *xml_path = (const gchar *) g_ptr_array_index (priv->xml_dirs, i);
		guint j;

		if (g_file_test (xml_path, G_FILE_TEST_IS_DIR)) {
			g_autoptr(GPtrArray) xmls = NULL;

			g_debug ("Searching for data in: %s", xml_path);
			xmls = as_utils_find_files_matching (xml_path, "*.xml*", FALSE, NULL);
			if (xmls != NULL) {
				for (j = 0; j < xmls->len; j++) {
					const gchar *val;
					val = (const gchar *) g_ptr_array_index (xmls, j);
					g_ptr_array_add (mdata_files,
								g_strdup (val));
				}
			}
		}
	}

	/* find YAML metadata */
	for (i = 0; i < priv->yaml_dirs->len; i++) {
		const gchar *yaml_path = (const gchar *) g_ptr_array_index (priv->yaml_dirs, i);
		guint j;

		if (g_file_test (yaml_path, G_FILE_TEST_IS_DIR)) {
			g_autoptr(GPtrArray) yamls = NULL;

			g_debug ("Searching for data in: %s", yaml_path);
			yamls = as_utils_find_files_matching (yaml_path, "*.yml*", FALSE, NULL);
			if (yamls != NULL) {
				for (j = 0; j < yamls->len; j++) {
					const gchar *val;
					val = (const gchar *) g_ptr_array_index (yamls, j);
					g_ptr_array_add (mdata_files,
								g_strdup (val));
				}
			}
		}
	}

	/* parse the found data */
	for (i = 0; i < mdata_files->len; i++) {
		g_autoptr(GFile) infile = NULL;
		const gchar *fname;

		fname = (const gchar*) g_ptr_array_index (mdata_files, i);
		g_debug ("Reading: %s", fname);

		infile = g_file_new_for_path (fname);
		if (!g_file_query_exists (infile, NULL)) {
			g_warning ("Metadata file '%s' does not exist.", fname);
			continue;
		}

		as_metadata_parse_file (metad,
					infile,
					AS_FORMAT_KIND_UNKNOWN,
					&tmp_error);
		if (tmp_error != NULL) {
			g_debug ("WARNING: %s", tmp_error->message);
			g_error_free (tmp_error);
			tmp_error = NULL;
			ret = FALSE;

			if (error != NULL) {
				if (*error == NULL)
					g_set_error_literal (error,
							     AS_POOL_ERROR,
							     AS_POOL_ERROR_FAILED,
							     fname);
				else
					g_prefix_error (error, "%s, ", fname);
			}
		}
	}

	/* finalize error message, if we had errors */
	if ((error != NULL) && (*error != NULL))
		g_prefix_error (error, "%s ", _("Metadata files have errors:"));

	/* add found components to the metadata pool */
	cpts = as_metadata_get_components (metad);
	merge_cpts = g_ptr_array_new ();
	for (i = 0; i < cpts->len; i++) {
		AsComponent *cpt = AS_COMPONENT (g_ptr_array_index (cpts, i));

		/* TODO: We support only system components at time */
		as_component_set_scope (cpt, AS_COMPONENT_SCOPE_SYSTEM);

		/* deal with merge-components later */
		if (as_component_get_merge_kind (cpt) != AS_MERGE_KIND_NONE) {
			g_ptr_array_add (merge_cpts, cpt);
			continue;
		}

		as_pool_add_component (pool, cpt, &tmp_error);
		if (tmp_error != NULL) {
			g_debug ("Metadata ignored: %s", tmp_error->message);
			g_error_free (tmp_error);
			tmp_error = NULL;
		}
	}

	/* we need to merge the merge-components into the pool last, so the merge process can fetch
	 * all components with matching IDs from the pool */
	for (i = 0; i < merge_cpts->len; i++) {
		AsComponent *mcpt = AS_COMPONENT (g_ptr_array_index (merge_cpts, i));

		as_pool_add_component (pool, mcpt, &tmp_error);
		if (tmp_error != NULL) {
			g_debug ("Merge component ignored: %s", tmp_error->message);
			g_error_free (tmp_error);
			tmp_error = NULL;
		}
	}

	return ret;
}

/**
 * as_pool_get_desktop_entries_table:
 *
 * Load fresh metadata from .desktop files.
 *
 * Returns: (transfer full): a hash map of #AsComponent instances.
 */
static GHashTable*
as_pool_get_desktop_entries_table (AsPool *pool)
{
	guint i;
	g_autoptr(AsMetadata) metad = NULL;
	g_autoptr(GPtrArray) de_files = NULL;
	GHashTable *de_cpt_table = NULL;
	GError *error = NULL;
	AsPoolPrivate *priv = GET_PRIVATE (pool);

	/* prepare metadata parser */
	metad = as_metadata_new ();
	as_metadata_set_locale (metad, priv->locale);

	de_cpt_table = g_hash_table_new_full (g_str_hash,
					      g_str_equal,
					      g_free,
					      (GDestroyNotify) g_object_unref);

	/* find .desktop files */
	g_debug ("Searching for data in: %s", APPLICATIONS_DIR);
	de_files = as_utils_find_files_matching (APPLICATIONS_DIR, "*.desktop", FALSE, NULL);
	if (de_files == NULL) {
		g_debug ("Unable find .desktop files.");
		return de_cpt_table;
	}

	/* parse the found data */
	for (i = 0; i < de_files->len; i++) {
		g_autoptr(GFile) infile = NULL;
		AsComponent *cpt;
		const gchar *fname = (const gchar*) g_ptr_array_index (de_files, i);

		g_debug ("Reading: %s", fname);
		infile = g_file_new_for_path (fname);
		if (!g_file_query_exists (infile, NULL)) {
			g_warning ("Metadata file '%s' does not exist.", fname);
			continue;
		}

		as_metadata_clear_components (metad);
		as_metadata_parse_file (metad,
					infile,
					AS_FORMAT_KIND_DESKTOP_ENTRY,
					&error);
		if (error != NULL) {
			g_debug ("Error reading .desktop file '%s': %s", fname, error->message);
			g_error_free (error);
			error = NULL;
			continue;
		}

		cpt = as_metadata_get_component (metad);
		if (cpt != NULL) {
			/* we only read metainfo files from system directories */
			as_component_set_scope (cpt, AS_COMPONENT_SCOPE_SYSTEM);

			g_hash_table_insert (de_cpt_table,
					     g_path_get_basename (fname),
					     g_object_ref (cpt));
		}
	}

	return de_cpt_table;
}

/**
 * as_pool_load_metainfo_data:
 *
 * Load fresh metadata from metainfo files.
 */
static void
as_pool_load_metainfo_data (AsPool *pool, GHashTable *desktop_entry_cpts)
{
	guint i;
	g_autoptr(AsMetadata) metad = NULL;
	g_autoptr(GPtrArray) mi_files = NULL;
	GError *error = NULL;
	AsPoolPrivate *priv = GET_PRIVATE (pool);

	/* prepare metadata parser */
	metad = as_metadata_new ();
	as_metadata_set_locale (metad, priv->locale);

	/* find metainfo files */
	g_debug ("Searching for data in: %s", METAINFO_DIR);
	mi_files = as_utils_find_files_matching (METAINFO_DIR, "*.xml", FALSE, NULL);
	if (mi_files == NULL) {
		g_debug ("Unable find metainfo files.");
		return;
	}

	/* parse the found data */
	for (i = 0; i < mi_files->len; i++) {
		AsComponent *cpt;
		AsLaunchable *launchable;
		g_autoptr(GFile) infile = NULL;
		g_autofree gchar *desktop_id = NULL;
		const gchar *fname = (const gchar*) g_ptr_array_index (mi_files, i);

		if (!priv->prefer_local_metainfo) {
			g_autofree gchar *mi_cid = NULL;

			mi_cid = g_path_get_basename (fname);
			if (g_str_has_suffix (mi_cid, ".metainfo.xml"))
				mi_cid[strlen (mi_cid) - 13] = '\0';
			if (g_str_has_suffix (mi_cid, ".appdata.xml")) {
				g_autofree gchar *mi_cid_desktop = NULL;
				mi_cid[strlen (mi_cid) - 12] = '\0';

				mi_cid_desktop = g_strdup_printf ("%s.desktop", mi_cid);
				/* check with .desktop suffix too */
				if (g_hash_table_contains (priv->known_cids, mi_cid_desktop)) {
					g_debug ("Skipped: %s (already known)", fname);
					continue;
				}
			}

			/* quickly check if we know the component already */
			if (g_hash_table_contains (priv->known_cids, mi_cid)) {
				g_debug ("Skipped: %s (already known)", fname);
				continue;
			}
		}

		g_debug ("Reading: %s", fname);
		infile = g_file_new_for_path (fname);
		if (!g_file_query_exists (infile, NULL)) {
			g_warning ("Metadata file '%s' does not exist.", fname);
			continue;
		}

		as_metadata_clear_components (metad);
		as_metadata_parse_file (metad,
					infile,
					AS_FORMAT_KIND_UNKNOWN,
					&error);
		if (error != NULL) {
			g_debug ("Errors in '%s': %s", fname, error->message);
			g_error_free (error);
			error = NULL;
		}

		cpt = as_metadata_get_component (metad);
		if (cpt == NULL)
			continue;

		/* we only read metainfo files from system directories */
		as_component_set_scope (cpt, AS_COMPONENT_SCOPE_SYSTEM);

		launchable = as_component_get_launchable (cpt, AS_LAUNCHABLE_KIND_DESKTOP_ID);
		if ((launchable != NULL) && (as_launchable_get_entries (launchable)->len > 0)) {
			/* find matching .desktop component to merge with via launchable */
			desktop_id = g_strdup (g_ptr_array_index (as_launchable_get_entries (launchable), 0));
		} else {
			/* try to guess the matching .desktop ID from the component-id */
			if (g_str_has_suffix (as_component_get_id (cpt), ".desktop"))
				desktop_id = g_strdup (as_component_get_id (cpt));
			else
				desktop_id = g_strdup_printf ("%s.desktop", as_component_get_id (cpt));
		}

		/* merge .desktop data into component if possible */
		if (desktop_id != NULL) {
			AsComponent *de_cpt;
			de_cpt = g_hash_table_lookup (desktop_entry_cpts, desktop_id);
			if (de_cpt != NULL) {
				as_component_merge_with_mode (cpt,
								de_cpt,
								AS_MERGE_KIND_APPEND);
				g_hash_table_remove (desktop_entry_cpts, desktop_id);
			}
		}

		as_pool_add_component_internal (pool, cpt, FALSE, &error);
		if (error != NULL) {
			g_debug ("Component '%s' ignored: %s", as_component_get_data_id (cpt), error->message);
			g_error_free (error);
			error = NULL;
		}
	}
}

/**
 * as_pool_load_metainfo_desktop_data:
 *
 * Load metadata from metainfo files and .desktop files that
 * where made available by locally installed applications.
 */
static void
as_pool_load_metainfo_desktop_data (AsPool *pool)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	g_autoptr(GHashTable) de_cpts = NULL;

	/* check if we actually need to load anything */
	if (!as_flags_contains (priv->flags, AS_POOL_FLAG_READ_DESKTOP_FILES) && !as_flags_contains (priv->flags, AS_POOL_FLAG_READ_METAINFO))
		return;

	/* get a hashmap of desktop-entry components */
	de_cpts = as_pool_get_desktop_entries_table (pool);

	if (as_flags_contains (priv->flags, AS_POOL_FLAG_READ_METAINFO)) {
		/* load metainfo components, absorb desktop-entry components into them */
		as_pool_load_metainfo_data (pool, de_cpts);
	}

	/* read all remaining .desktop file components, if needed */
	if (as_flags_contains (priv->flags, AS_POOL_FLAG_READ_DESKTOP_FILES)) {
		GHashTableIter iter;
		gpointer value;
		GError *error = NULL;

		g_debug ("Including components from .desktop files in the pool.");
		g_hash_table_iter_init (&iter, de_cpts);
		while (g_hash_table_iter_next (&iter, NULL, &value)) {
			AsComponent *cpt = AS_COMPONENT (value);

			as_pool_add_component_internal (pool, cpt, FALSE, &error);
			if (error != NULL) {
				g_debug ("Component '%s' ignored: %s", as_component_get_data_id (cpt), error->message);
				g_error_free (error);
				error = NULL;
			}
		}
	}
}

/**
 * as_pool_load:
 * @pool: An instance of #AsPool.
 * @error: A #GError or %NULL.
 *
 * Builds an index of all found components in the watched locations.
 * The function will try to get as much data into the pool as possible, so even if
 * the update completes with %FALSE, it might still have added components to the pool.
 *
 * The function will load from all possible data sources, preferring caches if they
 * are up to date.
 *
 * Returns: %TRUE if update completed without error.
 **/
gboolean
as_pool_load (AsPool *pool, GCancellable *cancellable, GError **error)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	gboolean ret = TRUE;
	guint invalid_cpts_n;
	guint all_cpts_n;
	gdouble valid_percentage;

	/* load means to reload, so we get rid of all the old data */
	as_pool_clear (pool);

	/* read all AppStream metadata that we can find */
	if (as_flags_contains (priv->flags, AS_POOL_FLAG_READ_COLLECTION))
		ret = as_pool_load_collection_data (pool, FALSE, error);

	/* read all metainfo and desktop files and add them to the pool */
	as_pool_load_metainfo_desktop_data (pool);

	/* automatically refine the metadata we have in the pool */
	all_cpts_n = g_hash_table_size (priv->cpt_table);
	invalid_cpts_n = as_pool_refine_data (pool);

	valid_percentage = (100 / (gdouble) all_cpts_n) * (gdouble) (all_cpts_n - invalid_cpts_n);
	g_debug ("Percentage of valid components: %0.3f", valid_percentage);

	/* we only return a non-TRUE value if a significant amount (10%) of components has been declared invalid. */
	if ((invalid_cpts_n != 0) && (valid_percentage <= 90))
		ret = FALSE;
	
	/* report errors if refining has failed */
	if (!ret && (error != NULL)) {
		if (*error == NULL) {
			g_set_error_literal (error,
					     AS_POOL_ERROR,
					     AS_POOL_ERROR_INCOMPLETE,
					     _("Many components have been recognized as invalid. See debug output for details."));
		} else {
			g_prefix_error (error, "Some components have been ignored: ");
		}
	}

	return ret;
}

/**
 * as_pool_load_cache_file:
 * @pool: An instance of #AsPool.
 * @fname: Filename of the cache file to load into the pool.
 * @error: A #GError or %NULL.
 *
 * Load AppStream metadata from a cache file.
 */
gboolean
as_pool_load_cache_file (AsPool *pool, const gchar *fname, GError **error)
{
	g_autoptr(GPtrArray) cpts = NULL;
	guint i;
	GError *tmp_error = NULL;

	/* load list of components in cache */
	cpts = as_cache_file_read (fname, &tmp_error);
	if (tmp_error != NULL) {
		g_propagate_error (error, tmp_error);
		return FALSE;
	}

	/* add cache objects to the pool */
	for (i = 0; i < cpts->len; i++) {
		AsComponent *cpt = AS_COMPONENT (g_ptr_array_index (cpts, i));

		/* TODO: Caches are system wide only at time, so we only have system-scope components in there */
		as_component_set_scope (cpt, AS_COMPONENT_SCOPE_SYSTEM);

		as_pool_add_component (pool, cpt, &tmp_error);
		if (tmp_error != NULL) {
			g_warning ("Cached data ignored: %s", tmp_error->message);
			g_error_free (tmp_error);
			tmp_error = NULL;
			continue;
		}
	}

	/* NOTE: Caches don't have merge components, so we don't need to special-case them here */
	/* NOTE: To have addons connected properly, as_pool_update_addon_info() has to be called, which busually happens anyway in the final _refine() run */

	return TRUE;
}

/**
 * as_pool_save_cache_file:
 * @pool: An instance of #AsPool.
 * @fname: Filename of the cache file the pool contents should be dumped to.
 * @error: A #GError or %NULL.
 *
 * Serialize AppStream metadata to a cache file.
 */
gboolean
as_pool_save_cache_file (AsPool *pool, const gchar *fname, GError **error)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	g_autoptr(GPtrArray) cpts = NULL;

	cpts = as_pool_get_components (pool);
	as_cache_file_save (fname, priv->locale, cpts, error);

	return TRUE;
}

/**
 * as_pool_get_components:
 * @pool: An instance of #AsPool.
 *
 * Get a list of found components.
 *
 * Returns: (transfer full) (element-type AsComponent): an array of #AsComponent instances.
 */
GPtrArray*
as_pool_get_components (AsPool *pool)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	GHashTableIter iter;
	gpointer value;
	GPtrArray *cpts;

	cpts = g_ptr_array_new_with_free_func (g_object_unref);
	g_hash_table_iter_init (&iter, priv->cpt_table);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		AsComponent *cpt = AS_COMPONENT (value);
		g_ptr_array_add (cpts, g_object_ref (cpt));
	}

	return cpts;
}

/**
 * as_pool_get_components_by_id:
 * @pool: An instance of #AsPool.
 * @cid: The AppStream-ID to look for.
 *
 * Get a specific component by its ID.
 * This function may contain multiple results if we have
 * data describing this component from multiple scopes/origin types.
 *
 * Returns: (transfer container) (element-type AsComponent): An #AsComponent
 */
GPtrArray*
as_pool_get_components_by_id (AsPool *pool, const gchar *cid)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	GPtrArray *result;
	GHashTableIter iter;
	gpointer value;

	result = g_ptr_array_new_with_free_func (g_object_unref);
	if (cid == NULL)
		return result;

	g_hash_table_iter_init (&iter, priv->cpt_table);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		AsComponent *cpt = AS_COMPONENT (value);
		if (g_strcmp0 (as_component_get_id (cpt), cid) == 0)
			g_ptr_array_add (result,
					 g_object_ref (cpt));
	}

	return result;
}

/**
 * as_pool_get_components_by_provided_item:
 * @pool: An instance of #AsPool.
 * @kind: An #AsProvidesKind
 * @item: The value of the provided item.
 *
 * Find components in the AppStream data pool which provide a certain item.
 *
 * Returns: (transfer container) (element-type AsComponent): an array of #AsComponent objects which have been found.
 */
GPtrArray*
as_pool_get_components_by_provided_item (AsPool *pool,
					      AsProvidedKind kind,
					      const gchar *item)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	GHashTableIter iter;
	gpointer value;
	GPtrArray *results;

	/* sanity check */
	g_return_val_if_fail (item != NULL, NULL);

	results = g_ptr_array_new_with_free_func (g_object_unref);
	g_hash_table_iter_init (&iter, priv->cpt_table);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		GPtrArray *provided = NULL;
		guint i;
		AsComponent *cpt = AS_COMPONENT (value);

		provided = as_component_get_provided (cpt);
		for (i = 0; i < provided->len; i++) {
			AsProvided *prov = AS_PROVIDED (g_ptr_array_index (provided, i));
			if (kind != AS_PROVIDED_KIND_UNKNOWN) {
				/* check if the kind matches. an unknown kind matches all provides types */
				if (as_provided_get_kind (prov) != kind)
					continue;
			}

			if (as_provided_has_item (prov, item))
				g_ptr_array_add (results, g_object_ref (cpt));
		}
	}

	return results;
}

/**
 * as_pool_get_components_by_kind:
 * @pool: An instance of #AsDatabase.
 * @kind: An #AsComponentKind.
 *
 * Return a list of all components in the pool which are of a certain kind.
 *
 * Returns: (transfer container) (element-type AsComponent): an array of #AsComponent objects which have been found.
 */
GPtrArray*
as_pool_get_components_by_kind (AsPool *pool, AsComponentKind kind)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	GHashTableIter iter;
	gpointer value;
	GPtrArray *results;

	/* sanity check */
	g_return_val_if_fail ((kind < AS_COMPONENT_KIND_LAST) && (kind > AS_COMPONENT_KIND_UNKNOWN), NULL);

	results = g_ptr_array_new_with_free_func (g_object_unref);
	g_hash_table_iter_init (&iter, priv->cpt_table);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		AsComponent *cpt = AS_COMPONENT (value);

		if (as_component_get_kind (cpt) == kind)
				g_ptr_array_add (results, g_object_ref (cpt));
	}

	return results;
}

/**
 * as_pool_get_components_by_categories:
 * @pool: An instance of #AsDatabase.
 * @categories: An array of XDG categories to include.
 *
 * Return a list of components which are in one of the categories.
 *
 * Returns: (transfer container) (element-type AsComponent): an array of #AsComponent objects which have been found.
 */
GPtrArray*
as_pool_get_components_by_categories (AsPool *pool, gchar **categories)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	GHashTableIter iter;
	gpointer value;
	guint i;
	GPtrArray *results;

	results = g_ptr_array_new_with_free_func (g_object_unref);

	/* sanity check */
	for (i = 0; categories[i] != NULL; i++) {
		if (!as_utils_is_category_name (categories[i])) {
			g_warning ("'%s' is not a valid XDG category name, search results might be invalid or empty.", categories[i]);
		}
	}

	g_hash_table_iter_init (&iter, priv->cpt_table);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		AsComponent *cpt = AS_COMPONENT (value);

		for (i = 0; categories[i] != NULL; i++) {
			if (as_component_has_category (cpt, categories[i]))
				g_ptr_array_add (results, g_object_ref (cpt));
		}
	}

	return results;
}

/**
 * as_pool_get_components_by_launchable:
 * @pool: An instance of #AsPool.
 * @kind: An #AsLaunchableKind
 * @id: The ID of the launchable.
 *
 * Find components in the AppStream data pool which provide a specific launchable.
 * See #AsLaunchable for details on launchables, or refer to the AppStream specification.
 *
 * Returns: (transfer container) (element-type AsComponent): an array of #AsComponent objects which have been found.
 *
 * Since: 0.11.4
 */
GPtrArray*
as_pool_get_components_by_launchable (AsPool *pool,
					      AsLaunchableKind kind,
					      const gchar *id)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	GHashTableIter iter;
	gpointer value;
	GPtrArray *results;

	/* sanity check */
	g_return_val_if_fail (id != NULL, NULL);

	results = g_ptr_array_new_with_free_func (g_object_unref);
	g_hash_table_iter_init (&iter, priv->cpt_table);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		GPtrArray *launchables = NULL;
		guint i;
		AsComponent *cpt = AS_COMPONENT (value);

		launchables = as_component_get_launchables (cpt);
		for (i = 0; i < launchables->len; i++) {
			guint j;
			GPtrArray *entries;
			AsLaunchable *launch = AS_LAUNCHABLE (g_ptr_array_index (launchables, i));

			if (kind != AS_LAUNCHABLE_KIND_UNKNOWN) {
				/* check if the kind matches. an unknown kind matches all provides types */
				if (as_launchable_get_kind (launch) != kind)
					continue;
			}

			entries = as_launchable_get_entries (launch);
			for (j = 0; j < entries->len; j++) {
				if (g_strcmp0 ((const gchar*) g_ptr_array_index (entries, j), id) == 0)
					g_ptr_array_add (results, g_object_ref (cpt));
			}
		}
	}

	return results;
}

/**
 * as_pool_build_search_terms:
 *
 * Build an array of search terms from a search string and improve the search terms
 * slightly, by stripping whitespaces, casefolding the terms and removing greylist words.
 */
static gchar**
as_pool_build_search_terms (AsPool *pool, const gchar *search)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	g_autoptr(AsStemmer) stemmer = NULL;
	g_autofree gchar *tmp_str = NULL;
	g_auto(GStrv) strv = NULL;
	gchar **terms;
	guint i;
	guint idx;

	if (search == NULL)
		return NULL;
	tmp_str = g_utf8_casefold (search, -1);

	/* filter query by greylist (to avoid overly generic search terms) */
	for (i = 0; priv->term_greylist[i] != NULL; i++) {
		gchar *str;
		str = as_str_replace (tmp_str, priv->term_greylist[i], "");
		g_free (tmp_str);
		tmp_str = str;
	}

	/* restore query if it was just greylist words */
	if (g_strcmp0 (tmp_str, "") == 0) {
		g_debug ("grey-list replaced all terms, restoring");
		g_free (tmp_str);
		tmp_str = g_utf8_casefold (search, -1);
	}

	/* we have to strip the leading and trailing whitespaces to avoid having
	 * different results for e.g. 'font ' and 'font' (LP: #506419)
	 */
	g_strstrip (tmp_str);

	strv = g_strsplit (tmp_str, " ", -1);
	terms = g_new0 (gchar *, g_strv_length (strv) + 1);
	idx = 0;
	stemmer = g_object_ref (as_stemmer_get ());
	for (i = 0; strv[i] != NULL; i++) {
		if (!as_utils_search_token_valid (strv[i]))
			continue;
		/* stem the string and add it to terms */
		terms[idx++] = as_stemmer_stem (stemmer, strv[i]);
	}
	/* if we have no valid terms, return NULL */
	if (idx == 0) {
		g_free (terms);
		return NULL;
	}

	return terms;
}

/**
 * as_sort_components_by_score_cb:
 *
 * Helper method to sort result arrays by the #AsComponent match score
 * with higher scores appearing higher in the list.
 */
static gint
as_sort_components_by_score_cb (gconstpointer a, gconstpointer b)
{
	guint s1, s2;
	AsComponent *cpt1 = *((AsComponent **) a);
	AsComponent *cpt2 = *((AsComponent **) b);
	s1 = as_component_get_sort_score (cpt1);
	s2 = as_component_get_sort_score (cpt2);

	if (s1 > s2)
		return -1;
	if (s1 < s2)
		return 1;
	return 0;
}

/**
 * as_pool_search:
 * @pool: An instance of #AsPool
 * @search: A search string
 *
 * Search for a list of components matching the search terms.
 * The list will be ordered by match score.
 *
 * Returns: (transfer container) (element-type AsComponent): an array of the found #AsComponent objects.
 *
 * Since: 0.9.7
 */
GPtrArray*
as_pool_search (AsPool *pool, const gchar *search)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	g_auto(GStrv) terms = NULL;
	GPtrArray *results;
	GHashTableIter iter;
	gpointer value;

	/* sanitize user's search term */
	terms = as_pool_build_search_terms (pool, search);
	results = g_ptr_array_new_with_free_func (g_object_unref);

	if (terms == NULL) {
		g_debug ("Search term invalid. Matching everything.");
	} else {
		g_autofree gchar *tmp_str = NULL;
		tmp_str = g_strjoinv (" ", terms);
		g_debug ("Searching for: %s", tmp_str);
	}

	g_hash_table_iter_init (&iter, priv->cpt_table);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		guint score;
		AsComponent *cpt = AS_COMPONENT (value);

		score = as_component_search_matches_all (cpt, terms);
		if (score == 0)
			continue;

		g_ptr_array_add (results, g_object_ref (cpt));
	}

	/* sort the results by their priority */
	g_ptr_array_sort (results, as_sort_components_by_score_cb);

	return results;
}

/**
 * as_pool_refresh_cache:
 * @pool: An instance of #AsPool.
 * @force: Enforce refresh, even if source data has not changed.
 *
 * Update the AppStream cache. There is normally no need to call this function manually, because cache updates are handled
 * transparently in the background.
 *
 * Returns: %TRUE if the cache was updated, %FALSE on error or if the cache update was not necessary and has been skipped.
 */
gboolean
as_pool_refresh_cache (AsPool *pool, gboolean force, GError **error)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	gboolean ret = FALSE;
	gboolean ret_poolupdate;
	g_autofree gchar *cache_fname = NULL;
	g_autoptr(GError) data_load_error = NULL;
	g_autoptr(GError) tmp_error = NULL;

	/* try to create cache directory, in case it doesn't exist */
	g_mkdir_with_parents (priv->sys_cache_path, 0755);
	if (!as_utils_is_writable (priv->sys_cache_path)) {
		g_set_error (error,
				AS_POOL_ERROR,
				AS_POOL_ERROR_TARGET_NOT_WRITABLE,
				_("Cache location '%s' is not writable."), priv->sys_cache_path);
		return FALSE;
	}

	/* collect metadata */
#ifdef HAVE_APT_SUPPORT
	/* currently, we only do something here if we are running with explicit APT support compiled in */
	as_pool_scan_apt (pool, force, &tmp_error);
	if (tmp_error != NULL) {
		/* the exact error is not forwarded here, since we might be able to partially update the cache */
		g_warning ("Error while collecting metadata: %s", tmp_error->message);
		g_error_free (tmp_error);
		tmp_error = NULL;
	}
#endif

	/* create the filename of our cache */
	cache_fname = g_strdup_printf ("%s/%s.gvz", priv->sys_cache_path, priv->locale);

	/* check if we need to refresh the cache
	 * (which is only necessary if the AppStream data has changed) */
	if (!as_pool_metadata_changed (pool)) {
		g_debug ("Data did not change, no cache refresh needed.");
		if (force) {
			g_debug ("Forcing refresh anyway.");
		} else {
			return FALSE;
		}
	}
	g_debug ("Refreshing AppStream cache");

	/* ensure we start with an empty pool */
	as_pool_clear (pool);

	/* NOTE: we will only cache AppStream metadata, no .desktop file metadata etc. */

	/* load AppStream collection metadata only and refine it */
	ret = as_pool_load_collection_data (pool, TRUE, &data_load_error);
	ret_poolupdate = as_pool_refine_data (pool) && ret;
	if (data_load_error != NULL)
		g_debug ("Error while updating the in-memory data pool: %s", data_load_error->message);

	/* save the cache object */
	as_pool_save_cache_file (pool, cache_fname, &tmp_error);
	if (tmp_error != NULL) {
		/* the exact error is not forwarded here, since we might be able to partially update the cache */
		g_warning ("Error while updating the cache: %s", tmp_error->message);
		g_error_free (tmp_error);
		tmp_error = NULL;
		ret = FALSE;
	} else {
		ret = TRUE;
	}

	if (ret) {
		if (!ret_poolupdate) {
			g_autofree gchar *error_message = NULL;
			if (data_load_error == NULL)
				error_message = g_strdup (_("The AppStream system cache was updated, but some errors were detected, which might lead to missing metadata. Refer to the verbose log for more information."));
			else
				error_message = g_strdup_printf (_("AppStream system cache was updated, but problems were found: %s"), data_load_error->message);

			g_set_error_literal (error,
				AS_POOL_ERROR,
				AS_POOL_ERROR_INCOMPLETE,
				error_message);
		}
		/* update the cache mtime, to not needlessly rebuild it again */
		as_touch_location (cache_fname);
		as_pool_check_cache_ctime (pool);
	} else {
		g_set_error (error,
				AS_POOL_ERROR,
				AS_POOL_ERROR_FAILED,
				_("AppStream cache update failed. Turn on verbose mode to get more detailed issue information."));
	}

	return TRUE;
}

/**
 * as_cache_file_save:
 * @fname: The file to save the data to.
 * @locale: The locale this cache file is for.
 * @cpts: (element-type AsComponent): The components to serialize.
 * @error: A #GError
 *
 * Serialize components to a cache file and store it on disk.
 */
void
as_cache_file_save (const gchar *fname, const gchar *locale, GPtrArray *cpts, GError **error)
{
	g_autoptr(GVariant) main_gv = NULL;
	g_autoptr(GVariantBuilder) main_builder = NULL;
	g_autoptr(GVariantBuilder) builder = NULL;

	g_autoptr(GFile) ofile = NULL;
	g_autoptr(GFileOutputStream) file_out = NULL;
	g_autoptr(GOutputStream) zout = NULL;
	g_autoptr(GZlibCompressor) compressor = NULL;
	gboolean serializable_components_found = FALSE;
	GError *tmp_error = NULL;
	guint cindex;

	if (cpts->len == 0) {
		g_debug ("Skipped writing cache file: No components to serialize.");
		return;
	}

	main_builder = g_variant_builder_new (G_VARIANT_TYPE_VARDICT);
	builder = g_variant_builder_new (G_VARIANT_TYPE_ARRAY);

	for (cindex = 0; cindex < cpts->len; cindex++) {
		AsComponent *cpt = AS_COMPONENT (g_ptr_array_index (cpts, cindex));

		/* sanity checks */
		if (!as_component_is_valid (cpt)) {
			/* we should *never* get here, all invalid stuff should be filtered out at this point */
			g_critical ("Skipped component '%s' from inclusion into the cache: The component is invalid.",
					   as_component_get_id (cpt));
			continue;
		}

		if (as_component_get_merge_kind (cpt) != AS_MERGE_KIND_NONE) {
			g_debug ("Skipping '%s' from cache inclusion, it is a merge component.",
				 as_component_get_id (cpt));
			continue;
		}
		serializable_components_found = TRUE;

		as_component_to_variant (cpt, builder);
	}

	/* check if we actually have some valid components serialized to a GVariant */
	if (!serializable_components_found) {
		g_debug ("Skipped writing cache file: No valid components found for serialization.");
		return;
	}

	/* write basic information and add components */
	g_variant_builder_add (main_builder, "{sv}",
				"format_version",
				g_variant_new_uint32 (CACHE_FORMAT_VERSION));
	g_variant_builder_add (main_builder, "{sv}",
				"locale",
				as_variant_mstring_new (locale));

	g_variant_builder_add (main_builder, "{sv}",
				"components",
				g_variant_builder_end (builder));
	main_gv = g_variant_builder_end (main_builder);

	ofile = g_file_new_for_path (fname);
	compressor = g_zlib_compressor_new (G_ZLIB_COMPRESSOR_FORMAT_GZIP, -1);
	file_out = g_file_replace (ofile,
				   NULL, /* entity-tag */
				   FALSE, /* make backup */
				   G_FILE_CREATE_REPLACE_DESTINATION,
				   NULL, /* cancellable */
				   error);
	if ((error != NULL) && (*error != NULL))
		return;

	zout = g_converter_output_stream_new (G_OUTPUT_STREAM (file_out), G_CONVERTER (compressor));
	if (!g_output_stream_write_all (zout,
					g_variant_get_data (main_gv),
					g_variant_get_size (main_gv),
					NULL, NULL, &tmp_error)) {
		g_set_error (error,
			     AS_POOL_ERROR,
			     AS_POOL_ERROR_FAILED,
			     "Failed to write stream: %s",
			     tmp_error->message);
		g_error_free (tmp_error);
		return;
	}
	if (!g_output_stream_close (zout, NULL, &tmp_error)) {
		g_set_error (error,
			     AS_POOL_ERROR,
			     AS_POOL_ERROR_FAILED,
			     "Failed to close stream: %s",
			     tmp_error->message);
		g_error_free (tmp_error);
		return;
	}
}

/**
 * as_cache_read:
 * @fname: The file to save the data to.
 * @locale: The locale this cache file is for.
 * @cpts: (element-type AsComponent): The components to serialize.
 * @error: A #GError
 *
 * Serialize components to a cache file and store it on disk.
 */
GPtrArray*
as_cache_file_read (const gchar *fname, GError **error)
{
	GPtrArray *cpts = NULL;
	g_autoptr(GFile) ifile = NULL;
	g_autoptr(GInputStream) file_stream = NULL;
	g_autoptr(GInputStream) stream_data = NULL;
	g_autoptr(GConverter) conv = NULL;

	GByteArray *byte_array;
	g_autoptr(GBytes) bytes = NULL;
	gssize len;
	const gsize buffer_size = 1024 * 32;
	g_autofree guint8 *buffer = NULL;

	g_autoptr(GVariant) main_gv = NULL;
	g_autoptr(GVariant) cptsv_array = NULL;
	g_autoptr(GVariant) cptv = NULL;
	g_autoptr(GVariant) gmvar = NULL;
	const gchar *locale = NULL;
	GVariantIter main_iter;

	ifile = g_file_new_for_path (fname);

	file_stream = G_INPUT_STREAM (g_file_read (ifile, NULL, error));
	if (file_stream == NULL)
		return NULL;

	/* decompress the GZip stream */
	conv = G_CONVERTER (g_zlib_decompressor_new (G_ZLIB_COMPRESSOR_FORMAT_GZIP));
	stream_data = g_converter_input_stream_new (file_stream, conv);

	buffer = g_malloc (buffer_size);
	byte_array = g_byte_array_new ();
	while ((len = g_input_stream_read (stream_data, buffer, buffer_size, NULL, error)) > 0) {
		g_byte_array_append (byte_array, buffer, len);
	}
	bytes = g_byte_array_free_to_bytes (byte_array);

	/* check if there was an error */
	if (len < 0)
		return NULL;
	if ((error != NULL) && (*error != NULL))
		return NULL;

	main_gv = g_variant_new_from_bytes (G_VARIANT_TYPE_VARDICT, bytes, TRUE);
	cpts = g_ptr_array_new_with_free_func (g_object_unref);

	gmvar = g_variant_lookup_value (main_gv,
					"format_version",
					G_VARIANT_TYPE_UINT32);
	if ((gmvar == NULL) || (g_variant_get_uint32 (gmvar) != CACHE_FORMAT_VERSION)) {
		/* don't try to load incompatible cache versions */
		if (gmvar == NULL)
			g_warning ("Skipped loading of broken cache file '%s'.", fname);
		else
			g_warning ("Skipped loading of incompatible or broken cache file '%s': Format is %i (expected %i)",
					fname, g_variant_get_uint32 (gmvar), CACHE_FORMAT_VERSION);

		/* TODO: Maybe emit a proper GError? */
		return NULL;
	}

	g_variant_unref (gmvar);
	gmvar = g_variant_lookup_value (main_gv,
					"locale",
					G_VARIANT_TYPE_MAYBE);
	locale = as_variant_get_mstring (&gmvar);

	cptsv_array = g_variant_lookup_value (main_gv,
					      "components",
					      G_VARIANT_TYPE_ARRAY);

	g_variant_iter_init (&main_iter, cptsv_array);
	while ((cptv = g_variant_iter_next_value (&main_iter))) {
		g_autoptr(AsComponent) cpt = as_component_new ();
		if (as_component_set_from_variant (cpt, cptv, locale)) {
			/* add to result list */
			if (as_component_is_valid (cpt)) {
				g_ptr_array_add (cpts, g_object_ref (cpt));
			} else {
				g_autofree gchar *str = as_component_to_string (cpt);
				g_warning ("Ignored serialized component: %s", str);
			}
		}
		g_variant_unref (cptv);
	}

	return cpts;
}

/**
 * as_pool_set_locale:
 * @pool: An instance of #AsPool.
 * @locale: the locale.
 *
 * Sets the current locale which should be used when parsing metadata.
 **/
void
as_pool_set_locale (AsPool *pool, const gchar *locale)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	g_free (priv->locale);
	priv->locale = g_strdup (locale);
}

/**
 * as_pool_get_locale:
 * @pool: An instance of #AsPool.
 *
 * Gets the currently used locale.
 *
 * Returns: Locale used for metadata parsing.
 **/
const gchar *
as_pool_get_locale (AsPool *pool)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	return priv->locale;
}

/**
 * as_pool_add_metadata_location_internal:
 * @pool: An instance of #AsPool.
 * @directory: An existing filesystem location.
 * @add_root: Whether to add the root directory if necessary.
 *
 * See %as_pool_add_metadata_location()
 */
static void
as_pool_add_metadata_location_internal (AsPool *pool, const gchar *directory, gboolean add_root)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	gboolean dir_added = FALSE;
	gchar *path;

	if (!g_file_test (directory, G_FILE_TEST_IS_DIR)) {
		g_debug ("Not adding metadata location '%s': Is no directory", directory);
		return;
	}

	/* metadata locations */
	path = g_build_filename (directory, "xml", NULL);
	if (g_file_test (path, G_FILE_TEST_IS_DIR)) {
		g_ptr_array_add (priv->xml_dirs, path);
		dir_added = TRUE;
		g_debug ("Added %s to XML metadata search path.", path);
	} else {
		g_free (path);
	}

	path = g_build_filename (directory, "xmls", NULL);
	if (g_file_test (path, G_FILE_TEST_IS_DIR)) {
		g_ptr_array_add (priv->xml_dirs, path);
		dir_added = TRUE;
		g_debug ("Added %s to XML metadata search path.", path);
	} else {
		g_free (path);
	}

	path = g_build_filename (directory, "yaml", NULL);
	if (g_file_test (path, G_FILE_TEST_IS_DIR)) {
		g_ptr_array_add (priv->yaml_dirs, path);
		dir_added = TRUE;
		g_debug ("Added %s to YAML metadata search path.", path);
	} else {
		g_free (path);
	}

	if ((add_root) && (!dir_added)) {
		/* we didn't find metadata-specific directories, so let's watch to root path for both YAML and XML */
		g_ptr_array_add (priv->xml_dirs, g_strdup (directory));
		g_ptr_array_add (priv->yaml_dirs, g_strdup (directory));
		g_debug ("Added %s to all metadata search paths.", directory);
	}

	/* icons */
	path = g_build_filename (directory, "icons", NULL);
	if (g_file_test (path, G_FILE_TEST_IS_DIR))
		g_ptr_array_add (priv->icon_dirs, path);
	else
		g_free (path);

}

/**
 * as_pool_add_metadata_location:
 * @pool: An instance of #AsPool.
 * @directory: An existing filesystem location.
 *
 * Add a location for the data pool to read data from.
 * If @directory contains a "xml", "xmls", "yaml" or "icons" subdirectory (or all of them),
 * those paths will be added to the search paths instead.
 */
void
as_pool_add_metadata_location (AsPool *pool, const gchar *directory)
{
	as_pool_add_metadata_location_internal (pool, directory, TRUE);
}

/**
 * as_pool_clear_metadata_locations:
 * @pool: An instance of #AsPool.
 *
 * Remove all metadata locations from the list of watched locations.
 */
void
as_pool_clear_metadata_locations (AsPool *pool)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);

	/* clear arrays */
	g_ptr_array_set_size (priv->xml_dirs, 0);
	g_ptr_array_set_size (priv->yaml_dirs, 0);
	g_ptr_array_set_size (priv->icon_dirs, 0);

	g_debug ("Cleared all metadata search paths.");
}

/**
 * as_pool_get_cache_flags:
 * @pool: An instance of #AsPool.
 *
 * Get the #AsCacheFlags for this data pool.
 */
AsCacheFlags
as_pool_get_cache_flags (AsPool *pool)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	return priv->cache_flags;
}

/**
 * as_pool_set_cache_flags:
 * @pool: An instance of #AsPool.
 * @flags: The new #AsCacheFlags.
 *
 * Set the #AsCacheFlags for this data pool.
 */
void
as_pool_set_cache_flags (AsPool *pool, AsCacheFlags flags)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	priv->cache_flags = flags;
}

/**
 * as_pool_get_flags:
 * @pool: An instance of #AsPool.
 *
 * Get the #AsPoolFlags for this data pool.
 */
AsPoolFlags
as_pool_get_flags (AsPool *pool)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	return priv->flags;
}

/**
 * as_pool_set_flags:
 * @pool: An instance of #AsPool.
 * @flags: The new #AsPoolFlags.
 *
 * Set the #AsPoolFlags for this data pool.
 */
void
as_pool_set_flags (AsPool *pool, AsPoolFlags flags)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	priv->flags = flags;
}

/**
 * as_pool_get_cache_age:
 * @pool: An instance of #AsPool.
 *
 * Get the age of our internal cache.
 */
time_t
as_pool_get_cache_age (AsPool *pool)
{
	AsPoolPrivate *priv = GET_PRIVATE (pool);
	return priv->cache_ctime;
}

/**
 * as_pool_error_quark:
 *
 * Return value: An error quark.
 **/
GQuark
as_pool_error_quark (void)
{
	static GQuark quark = 0;
	if (!quark)
		quark = g_quark_from_static_string ("AsPool");
	return quark;
}

/**
 * as_pool_new:
 *
 * Creates a new #AsPool.
 *
 * Returns: (transfer full): a #AsPool
 *
 **/
AsPool*
as_pool_new (void)
{
	AsPool *pool;
	pool = g_object_new (AS_TYPE_POOL, NULL);
	return AS_POOL (pool);
}
