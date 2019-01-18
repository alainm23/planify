/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016 Matthias Klumpp <matthias@tenstral.net>
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

#include "as-desktop-entry.h"

/**
 * SECTION:as-desktop-entry
 * @short_description: Parser for XDG Desktop Entry data.
 * @include: appstream.h
 *
 */

#include <string.h>

#include "as-utils.h"
#include "as-utils-private.h"
#include "as-metadata.h"
#include "as-component.h"
#include "as-component-private.h"

#define DESKTOP_GROUP G_KEY_FILE_DESKTOP_GROUP

/**
 * as_strequal_casefold:
 */
static gboolean
as_strequal_casefold (const gchar *a, const gchar *b)
{
	g_autofree gchar *str1 = NULL;
	g_autofree gchar *str2 = NULL;

	if (a != NULL)
		str1 = g_utf8_casefold (a, -1);
	if (b != NULL)
		str2 = g_utf8_casefold (b, -1);
	return g_strcmp0 (str1, str2) == 0;
}

/**
 * as_get_locale_from_key:
 */
static gchar*
as_get_locale_from_key (const gchar *key)
{
	gchar *tmp1;
	gchar *tmp2;
	gchar *locale = NULL;
	gchar *delim;

	tmp1 = g_strstr_len (key, -1, "[");
	if (tmp1 == NULL)
		return g_strdup ("C");
	tmp2 = g_strstr_len (tmp1, -1, "]");
	/* this is a bug in the file */
	if (tmp2 == NULL)
		return g_strdup ("C");
	locale = g_strdup (tmp1 + 1);
	locale[tmp2 - tmp1 - 1] = '\0';

	/* drop UTF-8 suffixes */
	if (g_str_has_suffix (locale, ".utf-8") ||
	    g_str_has_suffix (locale, ".UTF-8"))
		locale[strlen (locale)-6] = '\0';

	/* filter out cruft */
	if (as_is_cruft_locale (locale))
		return NULL;

	delim = g_strrstr (locale, ".");
	if (delim != NULL) {
		gchar *tmp;
		g_autofree gchar *enc = NULL;
		/* looks like we need to drop another encoding suffix
		 * (but we need to make sure it actually is one) */
		tmp = delim + 1;
		if (tmp != NULL)
			enc = g_utf8_strdown (tmp, -1);
		if ((enc != NULL) && (g_str_has_prefix (enc, "iso"))) {
			delim[0] = '\0';
		}
	}

	return locale;
}

/**
 * as_add_filtered_categories:
 *
 * Filter out some useless categories which we don't want to have in the
 * AppStream metadata.
 * Add the remaining ones to the new #AsComponent.
 */
static void
as_add_filtered_categories (gchar **cats, AsComponent *cpt)
{
	guint i;

	for (i = 0; cats[i] != NULL; i++) {
		const gchar *cat = cats[i];

		if (g_strcmp0 (cat, "GTK") == 0)
			continue;
		if (g_strcmp0 (cat, "Qt") == 0)
			continue;
		if (g_strcmp0 (cat, "GNOME") == 0)
			continue;
		if (g_strcmp0 (cat, "KDE") == 0)
			continue;
		if (g_strcmp0 (cat, "GUI") == 0)
			continue;
		if (g_strcmp0 (cat, "Application") == 0)
			continue;

		/* custom categories are ignored */
		if (g_str_has_prefix (cat, "X-"))
			continue;
		if (g_str_has_prefix (cat, "x-"))
			continue;

		/* check for invalid */
		if (g_strcmp0 (cat, "") == 0)
			continue;

		/* add the category if it is valid */
		if (as_utils_is_category_name (cat))
			as_component_add_category (cpt, cat);
	}
}


/**
 * as_desktop_entry_parse_data:
 */
AsComponent*
as_desktop_entry_parse_data (const gchar *data, const gchar *cid, AsFormatVersion fversion, GError **error)
{
	g_autoptr(AsComponent) cpt = NULL;
	g_autoptr(GKeyFile) df = NULL;
	gchar *tmp;
	gboolean ignore_cpt = FALSE;
	g_auto(GStrv) keys = NULL;
	guint i;

	g_assert (cid != NULL);

	df = g_key_file_new ();
	g_key_file_load_from_data (df,
				   data,
				   -1,
				   G_KEY_FILE_KEEP_TRANSLATIONS,
				   error);
	if (*error != NULL)
		return NULL;

	/* Type */
	tmp = g_key_file_get_string (df,
				     DESKTOP_GROUP,
				     "Type",
				     NULL);
	if (!as_strequal_casefold (tmp, "application")) {
		g_free (tmp);
		/* not an application, so we can't proceed, but also no error */
		return NULL;
	}
	g_free (tmp);

	/* NoDisplay */
	tmp = g_key_file_get_string (df,
				     DESKTOP_GROUP,
				     "NoDisplay",
				     NULL);
	if (as_strequal_casefold (tmp, "true")) {
		/* we will read the application data, but it will be ignored in its current form */
		ignore_cpt = TRUE;
	}
	g_free (tmp);

	/* X-AppStream-Ignore */
	tmp = g_key_file_get_string (df,
				     DESKTOP_GROUP,
				     "X-AppStream-Ignore",
				     NULL);
	if (as_strequal_casefold (tmp, "true")) {
		g_free (tmp);
		/* this file should be ignored, we can't return a component (but this is also no error) */
		return NULL;
	}
	g_free (tmp);

	/* check this is a valid desktop file */
	if (!g_key_file_has_group (df, DESKTOP_GROUP)) {
		g_set_error (error,
				AS_METADATA_ERROR,
				AS_METADATA_ERROR_PARSE,
				"Data in '%s' does not contain a valid Desktop Entry.", cid);
		return NULL;
	}

	/* create the new component we synthesize for this desktop entry */
	cpt = as_component_new ();
	as_component_set_kind (cpt, AS_COMPONENT_KIND_DESKTOP_APP);
	as_component_set_id (cpt, cid);
	as_component_set_ignored (cpt, ignore_cpt);
	as_component_set_origin_kind (cpt, AS_ORIGIN_KIND_DESKTOP_ENTRY);

	/* strip .desktop suffix if the reverse-domain-name scheme is followed and we build for
         * a recent AppStream version */
        if (fversion >= AS_FORMAT_VERSION_V0_10) {
		g_auto(GStrv) parts = g_strsplit (cid, ".", 3);
		if (g_strv_length (parts) == 3) {
			if (as_utils_is_tld (parts[0]) && g_str_has_suffix (cid, ".desktop")) {
				g_autofree gchar *id_raw = NULL;
				/* remove .desktop suffix */
				id_raw = g_strdup (cid);
				id_raw[strlen (id_raw)-8] = '\0';

				as_component_set_id (cpt, id_raw);
			}
		}
	}

	keys = g_key_file_get_keys (df, DESKTOP_GROUP, NULL, NULL);
	for (i = 0; keys[i] != NULL; i++) {
		g_autofree gchar *locale = NULL;
		g_autofree gchar *val = NULL;
		gchar *key = keys[i];

		g_strstrip (key);
		locale = as_get_locale_from_key (key);

		/* skip invalid stuff */
		if (locale == NULL)
			continue;

		val = g_key_file_get_string (df, DESKTOP_GROUP, key, NULL);
		if (g_str_has_prefix (key, "Name")) {
			as_component_set_name (cpt, val, locale);
		} else if (g_str_has_prefix (key, "Comment")) {
			as_component_set_summary (cpt, val, locale);
		} else if (g_strcmp0 (key, "Categories") == 0) {
			g_auto(GStrv) cats = NULL;

			cats = g_strsplit (val, ";", -1);
			as_add_filtered_categories (cats, cpt);
		} else if (g_str_has_prefix (key, "Keywords")) {
			g_auto(GStrv) kws = NULL;

			/* drop last ";" to not get an empty entry later */
			if (g_str_has_suffix (val, ";"))
				val[strlen (val) -1] = '\0';

			kws = g_strsplit (val, ";", -1);
			as_component_set_keywords (cpt, kws, locale);
		} else if (g_strcmp0 (key, "MimeType") == 0) {
			g_auto(GStrv) mts = NULL;
			g_autoptr(AsProvided) prov = NULL;
			guint j;

			mts = g_strsplit (val, ";", -1);
			if (mts == NULL)
				continue;

			prov = as_component_get_provided_for_kind (cpt, AS_PROVIDED_KIND_MIMETYPE);
			if (prov == NULL) {
				prov = as_provided_new ();
				as_provided_set_kind (prov, AS_PROVIDED_KIND_MIMETYPE);
			} else {
				g_object_ref (prov);
			}

			for (j = 0; mts[j] != NULL; j++) {
				if (g_strcmp0 (mts[j], "") == 0)
					continue;
				as_provided_add_item (prov, mts[j]);
			}

			as_component_add_provided (cpt, prov);
		} else if (g_strcmp0 (key, "Icon") == 0) {
			g_autoptr(AsIcon) icon = NULL;

			icon = as_icon_new ();
			if (g_str_has_prefix (val, "/")) {
				as_icon_set_kind (icon, AS_ICON_KIND_LOCAL);
				as_icon_set_filename (icon, val);
			} else {
				gchar *dot;
				as_icon_set_kind (icon, AS_ICON_KIND_STOCK);

				/* work around stock icons being suffixed */
				dot = g_strstr_len (val, -1, ".");
				if (dot != NULL &&
				    (g_strcmp0 (dot, ".png") == 0 ||
				     g_strcmp0 (dot, ".xpm") == 0 ||
				     g_strcmp0 (dot, ".svg") == 0 ||
				     g_strcmp0 (dot, ".svgz") == 0)) {
					*dot = '\0';
				}

				as_icon_set_name (icon, val);
			}

			as_component_add_icon (cpt, icon);
		}
	}

	/* we have the lowest priority */
	as_component_set_priority (cpt, -G_MAXINT);
	return g_object_ref (cpt);
}

/**
 * as_desktop_entry_parse_file:
 *
 * Parse a .desktop file.
 */
AsComponent*
as_desktop_entry_parse_file (GFile *file, AsFormatVersion fversion, GError **error)
{
	g_autofree gchar *file_basename = NULL;
	g_autoptr(GInputStream) file_stream = NULL;
	g_autoptr(GString) dedata = NULL;
	gssize len;
	const gsize buffer_size = 1024 * 32;
	g_autofree gchar *buffer = NULL;

	file_stream = G_INPUT_STREAM (g_file_read (file, NULL, error));
	if (file_stream == NULL)
		return NULL;

	file_basename = g_file_get_basename (file);
	dedata = g_string_new ("");
	buffer = g_malloc (buffer_size);
	while ((len = g_input_stream_read (file_stream, buffer, buffer_size, NULL, error)) > 0) {
		g_string_append_len (dedata, buffer, len);
	}
	/* check if there was an error */
	if (len < 0)
		return NULL;

	/* parse desktop entry */
	return as_desktop_entry_parse_data (dedata->str,
					    file_basename,
					    fversion,
					    error);
}
