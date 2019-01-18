/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcestyleschememanager.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2003-2007 - Paolo Maggi <paolo@gnome.org>
 *
 * GtkSourceView is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GtkSourceView is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcestyleschememanager.h"
#include "gtksourcestylescheme.h"
#include "gtksourceview-i18n.h"
#include "gtksourceview-utils.h"
#include <string.h>

/**
 * SECTION:styleschememanager
 * @Short_description: Provides access to GtkSourceStyleSchemes
 * @Title: GtkSourceStyleSchemeManager
 * @See_also: #GtkSourceStyleScheme
 *
 * Object which provides access to #GtkSourceStyleScheme<!-- -->s.
 */

#define SCHEME_FILE_SUFFIX	".xml"
#define STYLES_DIR		"styles"

struct _GtkSourceStyleSchemeManagerPrivate
{
	GHashTable	*schemes_hash;

	gchar          **search_path;
	gboolean	 need_reload;

	gchar          **ids; /* Cache the IDs of the available schemes */
};

enum {
	PROP_0,
	PROP_SEARCH_PATH,
	PROP_SCHEME_IDS
};

static GtkSourceStyleSchemeManager *default_instance;

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceStyleSchemeManager, gtk_source_style_scheme_manager, G_TYPE_OBJECT)

static void
gtk_source_style_scheme_manager_set_property (GObject 	   *object,
					      guint         prop_id,
					      const GValue *value,
					      GParamSpec   *pspec)
{
	GtkSourceStyleSchemeManager *sm;

	sm = GTK_SOURCE_STYLE_SCHEME_MANAGER (object);

	switch (prop_id)
	{
		case PROP_SEARCH_PATH:
			gtk_source_style_scheme_manager_set_search_path
					(sm, g_value_get_boxed (value));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object,
							   prop_id,
							   pspec);
			break;
	}
}

static void
gtk_source_style_scheme_manager_get_property (GObject    *object,
					      guint       prop_id,
					      GValue     *value,
					      GParamSpec *pspec)
{
	GtkSourceStyleSchemeManager *sm;

	sm = GTK_SOURCE_STYLE_SCHEME_MANAGER (object);

	switch (prop_id)
	{
		case PROP_SEARCH_PATH:
			g_value_set_boxed (value,
					   gtk_source_style_scheme_manager_get_search_path (sm));
			break;

		case PROP_SCHEME_IDS:
			g_value_set_boxed (value,
					   gtk_source_style_scheme_manager_get_scheme_ids (sm));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object,
							   prop_id,
							   pspec);
			break;
	}
}

static void
free_schemes (GtkSourceStyleSchemeManager *mgr)
{
	if (mgr->priv->schemes_hash != NULL)
	{
		g_hash_table_destroy (mgr->priv->schemes_hash);
		mgr->priv->schemes_hash = NULL;
	}

	g_strfreev (mgr->priv->ids);
	mgr->priv->ids = NULL;
}

static void
gtk_source_style_scheme_manager_finalize (GObject *object)
{
	GtkSourceStyleSchemeManager *mgr;

	mgr = GTK_SOURCE_STYLE_SCHEME_MANAGER (object);

	free_schemes (mgr);

	g_strfreev (mgr->priv->search_path);

	G_OBJECT_CLASS (gtk_source_style_scheme_manager_parent_class)->finalize (object);
}

static void
gtk_source_style_scheme_manager_class_init (GtkSourceStyleSchemeManagerClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->finalize	= gtk_source_style_scheme_manager_finalize;
	object_class->set_property = gtk_source_style_scheme_manager_set_property;
	object_class->get_property = gtk_source_style_scheme_manager_get_property;

	g_object_class_install_property (object_class,
					 PROP_SEARCH_PATH,
					 g_param_spec_boxed ("search-path",
						 	     "Style scheme search path",
							     "List of directories and files where the style schemes are located",
							     G_TYPE_STRV,
							     G_PARAM_READWRITE));

	g_object_class_install_property (object_class,
					 PROP_SCHEME_IDS,
					 g_param_spec_boxed ("scheme-ids",
						 	     "Scheme ids",
							     "List of the ids of the available style schemes",
							     G_TYPE_STRV,
							     G_PARAM_READABLE));
}

static void
gtk_source_style_scheme_manager_init (GtkSourceStyleSchemeManager *mgr)
{
	mgr->priv = gtk_source_style_scheme_manager_get_instance_private (mgr);
	mgr->priv->schemes_hash = NULL;
	mgr->priv->ids = NULL;
	mgr->priv->search_path = NULL;
	mgr->priv->need_reload = TRUE;
}

/**
 * gtk_source_style_scheme_manager_new:
 *
 * Creates a new style manager. If you do not need more than one style
 * manager then use gtk_source_style_scheme_manager_get_default() instead.
 *
 * Returns: a new #GtkSourceStyleSchemeManager.
 */
GtkSourceStyleSchemeManager *
gtk_source_style_scheme_manager_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_STYLE_SCHEME_MANAGER, NULL);
}

/**
 * gtk_source_style_scheme_manager_get_default:
 *
 * Returns the default #GtkSourceStyleSchemeManager instance.
 *
 * Returns: (transfer none): a #GtkSourceStyleSchemeManager. Return value
 * is owned by GtkSourceView library and must not be unref'ed.
 */
GtkSourceStyleSchemeManager *
gtk_source_style_scheme_manager_get_default (void)
{
	if (default_instance == NULL)
	{
		default_instance = gtk_source_style_scheme_manager_new ();
		g_object_add_weak_pointer (G_OBJECT (default_instance),
					   (gpointer) &default_instance);
	}

	return default_instance;
}

GtkSourceStyleSchemeManager *
_gtk_source_style_scheme_manager_peek_default (void)
{
	return default_instance;
}

static gboolean
build_reference_chain (GtkSourceStyleScheme *scheme,
		       GHashTable           *hash,
		       GSList              **ret)
{
	GSList *chain;
	gboolean retval = TRUE;

	chain = g_slist_prepend (NULL, scheme);

	while (TRUE)
	{
		GtkSourceStyleScheme *parent_scheme;
		const gchar *parent_id;

		parent_id = _gtk_source_style_scheme_get_parent_id (scheme);

		if (parent_id == NULL)
			break;

		parent_scheme = g_hash_table_lookup (hash, parent_id);

		if (parent_scheme == NULL)
		{
			g_warning ("Unknown parent scheme '%s' in scheme '%s'",
				   parent_id, gtk_source_style_scheme_get_id (scheme));
			retval = FALSE;
			break;
		}
		else if (g_slist_find (chain, parent_scheme) != NULL)
		{
			g_warning ("Reference cycle in scheme '%s'", parent_id);
			retval = FALSE;
			break;
		}
		else
		{
			_gtk_source_style_scheme_set_parent (scheme, parent_scheme);
		}

		chain = g_slist_prepend (chain, parent_scheme);
		scheme = parent_scheme;
	}

	*ret = chain;
	return retval;
}

static GSList *
check_parents (GSList *schemes, GHashTable *hash)
{
	GSList *to_check;

	to_check = g_slist_copy (schemes);

	while (to_check != NULL)
	{
		GtkSourceStyleScheme *scheme_to_check;
		GSList *chain;
		gboolean valid;

		scheme_to_check = to_check->data;

		valid = build_reference_chain (scheme_to_check, hash, &chain);

		while (chain != NULL)
		{
			GtkSourceStyleScheme *scheme = chain->data;

			to_check = g_slist_remove (to_check, scheme);

			if (!valid)
			{
				const gchar *id = gtk_source_style_scheme_get_id (scheme);
				schemes = g_slist_remove (schemes, scheme);
				g_hash_table_remove (hash, id);
			}

			chain = g_slist_delete_link (chain, chain);
		}
	}

	return schemes;
}

static gint
schemes_compare (GtkSourceStyleScheme *scheme1, GtkSourceStyleScheme *scheme2)
{
	const gchar *name1;
	const gchar *name2;

	name1 = gtk_source_style_scheme_get_name (scheme1);
	name2 = gtk_source_style_scheme_get_name (scheme2);

	return g_utf8_collate (name1, name2);
}

static gchar **
schemes_list_to_ids (GSList *list)
{
	gchar **res;
	guint i = 0;

	res = g_new (gchar *, g_slist_length (list) + 1);

	for ( ; list != NULL; list = list->next)
	{
		const gchar *id = gtk_source_style_scheme_get_id (list->data);
		res[i] = g_strdup (id);
		++i;
	}

	res[i] = NULL;

	return res;
}

static void
reload_if_needed (GtkSourceStyleSchemeManager *mgr)
{
	GSList *schemes = NULL;
	GSList *files;
	GSList *l;
	GHashTable *schemes_hash;

	if (!mgr->priv->need_reload)
		return;

	schemes_hash = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_object_unref);

	files = _gtk_source_view_get_file_list ((gchar **)gtk_source_style_scheme_manager_get_search_path (mgr),
						SCHEME_FILE_SUFFIX,
						FALSE);

	for (l = files; l != NULL; l = l->next)
	{
		GtkSourceStyleScheme *scheme;
		gchar *filename;

		filename = l->data;

		scheme = _gtk_source_style_scheme_new_from_file (filename);

		if (scheme != NULL)
		{
			const gchar *id = gtk_source_style_scheme_get_id (scheme);

			/* scheme with the same id already loaded from a path with higher prio: skip it */
			if (g_hash_table_contains (schemes_hash, id))
			{
				g_object_unref (scheme);
				continue;
			}

			schemes = g_slist_prepend (schemes, scheme);
			g_hash_table_insert (schemes_hash, g_strdup (id), scheme);
		}
	}

	g_slist_free_full (files, g_free);

	schemes = check_parents (schemes, schemes_hash);

	/* Sort by name */
	schemes = g_slist_sort (schemes, (GCompareFunc)schemes_compare);

	free_schemes (mgr);

	mgr->priv->need_reload = FALSE;
	mgr->priv->schemes_hash = schemes_hash;

	mgr->priv->ids = schemes_list_to_ids (schemes);
	g_slist_free (schemes);
}

static void
notify_search_path (GtkSourceStyleSchemeManager *mgr)
{
	mgr->priv->need_reload = TRUE;

	g_object_notify (G_OBJECT (mgr), "search-path");
	g_object_notify (G_OBJECT (mgr), "scheme-ids");
}

/**
 * gtk_source_style_scheme_manager_set_search_path:
 * @manager: a #GtkSourceStyleSchemeManager.
 * @path: (array zero-terminated=1) (nullable):
 * a %NULL-terminated array of strings or %NULL.
 *
 * Sets the list of directories where the @manager looks for
 * style scheme files.
 * If @path is %NULL, the search path is reset to default.
 */
void
gtk_source_style_scheme_manager_set_search_path (GtkSourceStyleSchemeManager  *manager,
						 gchar	                     **path)
{
	gchar **tmp;

	g_return_if_fail (GTK_SOURCE_IS_STYLE_SCHEME_MANAGER (manager));

	tmp = manager->priv->search_path;

	if (path == NULL)
		manager->priv->search_path = _gtk_source_view_get_default_dirs (STYLES_DIR, FALSE);
	else
		manager->priv->search_path = g_strdupv (path);

	g_strfreev (tmp);

	notify_search_path (manager);
}

/**
 * gtk_source_style_scheme_manager_append_search_path:
 * @manager: a #GtkSourceStyleSchemeManager.
 * @path: a directory or a filename.
 *
 * Appends @path to the list of directories where the @manager looks for
 * style scheme files.
 * See gtk_source_style_scheme_manager_set_search_path() for details.
 */
void
gtk_source_style_scheme_manager_append_search_path (GtkSourceStyleSchemeManager *manager,
						    const gchar                 *path)
{
	guint len = 0;

	g_return_if_fail (GTK_SOURCE_IS_STYLE_SCHEME_MANAGER (manager));
	g_return_if_fail (path != NULL);

	if (manager->priv->search_path == NULL)
		manager->priv->search_path = _gtk_source_view_get_default_dirs (STYLES_DIR, FALSE);

	g_return_if_fail (manager->priv->search_path != NULL);

	len = g_strv_length (manager->priv->search_path);

	manager->priv->search_path = g_renew (gchar *,
					      manager->priv->search_path,
					      len + 2); /* old path + new entry + NULL */

	manager->priv->search_path[len] = g_strdup (path);
	manager->priv->search_path[len + 1] = NULL;

	notify_search_path (manager);
}

/**
 * gtk_source_style_scheme_manager_prepend_search_path:
 * @manager: a #GtkSourceStyleSchemeManager.
 * @path: a directory or a filename.
 *
 * Prepends @path to the list of directories where the @manager looks
 * for style scheme files.
 * See gtk_source_style_scheme_manager_set_search_path() for details.
 */
void
gtk_source_style_scheme_manager_prepend_search_path (GtkSourceStyleSchemeManager *manager,
						     const gchar                 *path)
{
	guint len = 0;
	gchar **new_search_path;

	g_return_if_fail (GTK_SOURCE_IS_STYLE_SCHEME_MANAGER (manager));
	g_return_if_fail (path != NULL);

	if (manager->priv->search_path == NULL)
		manager->priv->search_path = _gtk_source_view_get_default_dirs (STYLES_DIR, FALSE);

	g_return_if_fail (manager->priv->search_path != NULL);

	len = g_strv_length (manager->priv->search_path);

	new_search_path = g_new (gchar *, len + 2);
	new_search_path[0] = g_strdup (path);
	memcpy (new_search_path + 1, manager->priv->search_path, (len + 1) * sizeof (gchar*));

	g_free (manager->priv->search_path);
	manager->priv->search_path = new_search_path;

	notify_search_path (manager);
}

/**
 * gtk_source_style_scheme_manager_get_search_path:
 * @manager: a #GtkSourceStyleSchemeManager.
 *
 * Returns the current search path for the @manager.
 * See gtk_source_style_scheme_manager_set_search_path() for details.
 *
 * Returns: (array zero-terminated=1) (transfer none): a %NULL-terminated array
 * of string containing the search path.
 * The array is owned by the @manager and must not be modified.
 */
const gchar * const *
gtk_source_style_scheme_manager_get_search_path (GtkSourceStyleSchemeManager *manager)
{
	g_return_val_if_fail (GTK_SOURCE_IS_STYLE_SCHEME_MANAGER (manager), NULL);

	if (manager->priv->search_path == NULL)
		manager->priv->search_path = _gtk_source_view_get_default_dirs (STYLES_DIR, FALSE);

	return (const gchar * const *)manager->priv->search_path;
}

/**
 * gtk_source_style_scheme_manager_force_rescan:
 * @manager: a #GtkSourceStyleSchemeManager.
 *
 * Mark any currently cached information about the available style scehems
 * as invalid. All the available style schemes will be reloaded next time
 * the @manager is accessed.
 */
void
gtk_source_style_scheme_manager_force_rescan (GtkSourceStyleSchemeManager *manager)
{
	g_return_if_fail (GTK_SOURCE_IS_STYLE_SCHEME_MANAGER (manager));

	manager->priv->need_reload = TRUE;

	g_object_notify (G_OBJECT (manager), "scheme-ids");
}

/**
 * gtk_source_style_scheme_manager_get_scheme_ids:
 * @manager: a #GtkSourceStyleSchemeManager.
 *
 * Returns the ids of the available style schemes.
 *
 * Returns: (nullable) (array zero-terminated=1) (transfer none):
 * a %NULL-terminated array of strings containing the ids of the available
 * style schemes or %NULL if no style scheme is available.
 * The array is sorted alphabetically according to the scheme name.
 * The array is owned by the @manager and must not be modified.
 */
const gchar * const *
gtk_source_style_scheme_manager_get_scheme_ids (GtkSourceStyleSchemeManager *manager)
{
	g_return_val_if_fail (GTK_SOURCE_IS_STYLE_SCHEME_MANAGER (manager), NULL);

	reload_if_needed (manager);

	return (const gchar * const *)manager->priv->ids;
}

/**
 * gtk_source_style_scheme_manager_get_scheme:
 * @manager: a #GtkSourceStyleSchemeManager.
 * @scheme_id: style scheme id to find.
 *
 * Looks up style scheme by id.
 *
 * Returns: (transfer none): a #GtkSourceStyleScheme object. Returned value is owned by
 * @manager and must not be unref'ed.
 */
GtkSourceStyleScheme *
gtk_source_style_scheme_manager_get_scheme (GtkSourceStyleSchemeManager *manager,
					    const gchar                 *scheme_id)
{
	g_return_val_if_fail (GTK_SOURCE_IS_STYLE_SCHEME_MANAGER (manager), NULL);
	g_return_val_if_fail (scheme_id != NULL, NULL);

	reload_if_needed (manager);

	return g_hash_table_lookup (manager->priv->schemes_hash, scheme_id);
}
