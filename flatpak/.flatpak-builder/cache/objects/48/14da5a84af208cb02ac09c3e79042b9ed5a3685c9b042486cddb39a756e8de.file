/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2014 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU General Public License Version 2
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the license, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "ascli-utils.h"

#include <config.h>
#include <glib/gi18n-lib.h>

/**
 * Set to true if we don't want colored output
 */
static gboolean _colored_output = FALSE;

/**
 * ascli_format_long_output:
 */
gchar*
ascli_format_long_output (const gchar *str, guint indent_level)
{
	GString *res = NULL;
	guint count = 0;
	gssize last_space = 0;
	const gchar *char_ptr = str;

	g_autofree gchar *spacing = NULL;
	g_autofree gchar *break_indent = NULL;

	spacing = g_strnfill (indent_level, ' ');
	break_indent = g_strdup_printf ("\n%s", spacing);

	res = g_string_sized_new (strlen (str));

	while (*char_ptr != '\0') {
		gunichar uchar = g_utf8_get_char_validated (char_ptr, -1);

		if (uchar == '\n') {
			g_string_append (res, break_indent);
			count = 0;
			last_space = 0;
			goto next;
		}

		g_string_append_unichar (res, uchar);
		count++;

		if (g_unichar_isspace (uchar)) {
			last_space = res->len;
			if (count > 80) {
				g_string_append (res, break_indent);
				count = 0;
				last_space = 0;
				goto next;
			}
		} else if (count > 80) {
			/* insert a linebreak at previous position */
			if (last_space > 0) {
				g_string_erase (res, last_space, 0);
				g_string_insert (res, last_space, break_indent);
				count = 0;
				last_space = 0;
			}
		}

	next:
		char_ptr = g_utf8_next_char (char_ptr);
	}

	return g_string_free (res, FALSE);
}

/**
 * ascli_print_key_value:
 */
void
ascli_print_key_value (const gchar* key, const gchar* val, gboolean highlight)
{
	gchar *str;
	gchar *fmtval;
	g_return_if_fail (key != NULL);

	if ((val == NULL) || (g_strcmp0 (val, "") == 0))
		return;

	if (strlen (val) > 120) {
		/* only produces slightly better output (indented).
		 * we need word-wrapping in future
		 */
		fmtval = ascli_format_long_output (val, 2);
	} else {
		fmtval = g_strdup (val);
	}

	str = g_strdup_printf ("%s: ", key);

	if (_colored_output) {
		g_print ("%c[%dm%s%c[%dm%s\n", 0x1B, 1, str, 0x1B, 0, fmtval);
	} else {
		g_print ("%s%s\n", str, fmtval);
	}

	g_free (str);
	g_free (fmtval);
}

/**
 * ascli_print_highlight:
 */
void
ascli_print_highlight (const gchar* msg)
{
	if (_colored_output) {
		g_print ("%c[%dm%s%c[%dm\n", 0x1B, 1, msg, 0x1B, 0);
	} else {
		g_print ("%s\n", msg);
	}
}

/**
 * ascli_print_separator:
 */
void
ascli_print_separator ()
{
	if (_colored_output) {
		g_print ("%c[%dm%s\n%c[%dm", 0x1B, 36, "---", 0x1B, 0);
	} else {
		g_print ("---\n");
	}
}

/**
 * ascli_print_stderr:
 */
void
ascli_print_stderr (const gchar *format, ...)
{
	va_list args;
	gchar *str;

	va_start (args, format);
	str = g_strdup_vprintf (format, args);
	va_end (args);

	g_printerr ("%s\n", str);

	g_free (str);
}

/**
 * ascli_print_stdout:
 */
void
ascli_print_stdout (const gchar *format, ...)
{
	va_list args;
	gchar *str;

	va_start (args, format);
	str = g_strdup_vprintf (format, args);
	va_end (args);

	g_print ("%s\n", str);

	g_free (str);
}

/**
 * ascli_set_output_colored:
 */
void
ascli_set_output_colored (gboolean colored)
{
	_colored_output = colored;
}

/**
 * ascli_get_output_colored:
 */
gboolean
ascli_get_output_colored ()
{
	return _colored_output;
}

/**
 * as_get_bundle_str:
 */
static gchar*
as_get_bundle_str (AsComponent *cpt)
{
	guint i;
	GString *gstr;

	if (!as_component_has_bundle (cpt))
		return NULL;

	gstr = g_string_new ("");
	for (i = 0; i < AS_BUNDLE_KIND_LAST; i++) {
		AsBundleKind kind = (AsBundleKind) i;
		AsBundle *bundle;

		bundle = as_component_get_bundle (cpt, kind);
		if (bundle == NULL)
			continue;
		g_string_append_printf (gstr, "%s:%s, ",
					as_bundle_kind_to_string (kind),
					as_bundle_get_id (bundle));

	}
	if (gstr->len > 0)
		g_string_truncate (gstr, gstr->len - 2);

	return g_string_free (gstr, FALSE);
}

/**
 * ascli_ptrarray_to_pretty:
 *
 * Pretty-print a GPtrArray.
 */
static gchar*
ascli_ptrarray_to_pretty (GPtrArray *array)
{
	GString *rstr = NULL;
	guint i;

	if (array->len == 1) {
		return g_strdup (g_ptr_array_index (array, 0));
	}

	rstr = g_string_new ("\n");
	for (i = 0; i < array->len; i++) {
		const gchar *astr = (const gchar*) g_ptr_array_index (array, i);
		g_string_append_printf (rstr, " - %s\n", astr);
	}
	if (rstr->len > 0)
		g_string_truncate (rstr, rstr->len - 1);

	return g_string_free (rstr, FALSE);
}

/**
 * ascli_print_component:
 *
 * Print well-formatted details about a component to stdout.
 */
void
ascli_print_component (AsComponent *cpt, gboolean show_detailed)
{
	gchar *short_idline;
	gchar *pkgs_str = NULL;
	gchar *bundles_str = NULL;
	AsIcon *icon = NULL;
	guint j;

	short_idline = g_strdup_printf ("%s [%s]",
					as_component_get_id (cpt),
					as_component_kind_to_string (as_component_get_kind (cpt)));
	if (as_component_get_pkgnames (cpt) != NULL)
		pkgs_str = g_strjoinv (", ", as_component_get_pkgnames (cpt));
	bundles_str = as_get_bundle_str (cpt);

	icon = as_component_get_icon_by_size (cpt, 64, 64);
	if (icon == NULL) {
		GPtrArray *icons = as_component_get_icons (cpt);
		for (j = 0; j < icons->len; j++) {
			AsIcon *tmp_icon = AS_ICON (g_ptr_array_index (icons, j));
			if (as_icon_get_kind (tmp_icon) == AS_ICON_KIND_STOCK) {
				icon = tmp_icon;
				break;
			}
		}
	}

	ascli_print_key_value (_("Identifier"), short_idline, FALSE);
	ascli_print_key_value (_("Name"), as_component_get_name (cpt), FALSE);
	ascli_print_key_value (_("Summary"), as_component_get_summary (cpt), FALSE);
	ascli_print_key_value (_("Package"), pkgs_str, FALSE);
	ascli_print_key_value (_("Bundle"), bundles_str, FALSE);
	ascli_print_key_value (_("Homepage"), as_component_get_url (cpt, AS_URL_KIND_HOMEPAGE), FALSE);
	ascli_print_key_value (_("Icon"), icon == NULL ? NULL : as_icon_get_name (icon), FALSE);
	g_free (short_idline);
	g_free (pkgs_str);
	g_free (bundles_str);
	short_idline = NULL;

	if (show_detailed) {
		GPtrArray *sshot_array;
		GPtrArray *imgs = NULL;
		GPtrArray *extends;
		GPtrArray *addons;
		GPtrArray *categories;
		GPtrArray *compulsory_desktops;
		GPtrArray *provided;
		guint i;
		AsScreenshot *sshot;
		AsImage *img;
		gchar *str;

		/* developer name */
		ascli_print_key_value (_("Developer"), as_component_get_developer_name (cpt), FALSE);

		/* extends data (e.g. for addons) */
		extends = as_component_get_extends (cpt);
		if (extends->len > 0) {
			str = ascli_ptrarray_to_pretty (extends);
			ascli_print_key_value (_("Extends"), str, FALSE);
			g_free (str);
		}

		/* long description */
		str = as_markup_convert_simple (as_component_get_description (cpt), NULL);
		ascli_print_key_value (_("Description"), str, FALSE);
		g_free (str);

		/* some simple screenshot information */
		sshot_array = as_component_get_screenshots (cpt);

		/* find default screenshot, if possible */
		sshot = NULL;
		for (j = 0; j < sshot_array->len; j++) {
			sshot = AS_SCREENSHOT (g_ptr_array_index (sshot_array, j));
			if (as_screenshot_get_kind (sshot) == AS_SCREENSHOT_KIND_DEFAULT)
				break;
		}

		if (sshot != NULL) {
			/* get the first source image and display it's url */
			imgs = as_screenshot_get_images (sshot);
			for (j = 0; j < imgs->len; j++) {
				img = AS_IMAGE (g_ptr_array_index (imgs, j));
				if (as_image_get_kind (img) == AS_IMAGE_KIND_SOURCE) {
					ascli_print_key_value (_("Default Screenshot URL"), as_image_get_url (img), FALSE);
					break;
				}
			}
		}

		/* project group */
		ascli_print_key_value (_("Project Group"), as_component_get_project_group (cpt), FALSE);

		/* license */
		ascli_print_key_value (_("License"), as_component_get_project_license (cpt), FALSE);

		/* Categories */
		categories = as_component_get_categories (cpt);
		if (categories->len > 0) {
			str = ascli_ptrarray_to_pretty (categories);
			ascli_print_key_value (_("Categories"), str, FALSE);
			g_free (str);
		}

		/* Desktop-compulsority */
		compulsory_desktops = as_component_get_compulsory_for_desktops (cpt);
		if (compulsory_desktops->len > 0) {
			str = ascli_ptrarray_to_pretty (compulsory_desktops);
			ascli_print_key_value (_("Compulsory for"), str, FALSE);
			g_free (str);
		}

		/* list of addons extending this component */
		addons = as_component_get_addons (cpt);
		if (addons->len > 0) {
			g_autoptr(GPtrArray) addons_str = g_ptr_array_new_with_free_func (g_free);
			for (i = 0; i < addons->len; i++) {
				AsComponent *addon = AS_COMPONENT (g_ptr_array_index (addons, i));
				if (as_component_get_kind (addon) == AS_COMPONENT_KIND_LOCALIZATION) {
					g_ptr_array_add (addons_str, g_strdup_printf ("l10n: %s",
											as_component_get_id (addon)));
				} else {
					g_ptr_array_add (addons_str, g_strdup_printf ("%s (%s)",
											as_component_get_id (addon),
											as_component_get_name (cpt)));
				}
			}
			str = ascli_ptrarray_to_pretty (addons_str);
			/* TRANSLATORS: Addons are extensions for existing software components, e.g. support for more visual effects for a video editor */
			ascli_print_key_value (_("Add-ons"), str, FALSE);
			g_free (str);
		}

		/* Provided Items */
		provided = as_component_get_provided (cpt);
		if (provided->len > 0)
			ascli_print_key_value (_("Provided Items"), "↓", FALSE);
		for (i = 0; i < provided->len; i++) {
			GPtrArray *items = NULL;
			AsProvided *prov = AS_PROVIDED (g_ptr_array_index (provided, i));

			items = as_provided_get_items (prov);
			if (items->len > 0) {
				g_autofree gchar *keyname = NULL;

				str = ascli_ptrarray_to_pretty (items);
				keyname = g_strdup_printf (" %s", as_provided_kind_to_l10n_string (as_provided_get_kind (prov)));
				ascli_print_key_value (keyname, str, FALSE);
				g_free (str);
			}
		}
	}
}

/**
 * ascli_print_components:
 *
 * Print well-formatted details about multiple components to stdout.
 */
void
ascli_print_components (GPtrArray *cpts, gboolean show_detailed)
{
	guint i;

	for (i = 0; i < cpts->len; i++) {
		AsComponent *cpt = AS_COMPONENT(g_ptr_array_index (cpts, i));
		ascli_print_component (cpt, show_detailed);

		if (i < cpts->len-1)
			ascli_print_separator ();
	}
}
