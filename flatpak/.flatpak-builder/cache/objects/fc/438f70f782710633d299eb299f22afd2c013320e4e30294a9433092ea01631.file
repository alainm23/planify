/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourceview-utils.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2007 - Gustavo Giráldez and Paolo Maggi
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourceview-utils.h"

#include <errno.h>
#include <math.h>

#define SOURCEVIEW_DIR "gtksourceview-3.0"

gchar **
_gtk_source_view_get_default_dirs (const char *basename,
				   gboolean    compat)
{
	const gchar * const *xdg_dirs;
	GPtrArray *dirs;

	dirs = g_ptr_array_new ();

	/* user dir */
	g_ptr_array_add (dirs, g_build_filename (g_get_user_data_dir (),
						 SOURCEVIEW_DIR,
						 basename,
						 NULL));

#ifdef G_OS_UNIX
	/* Legacy gtsourceview 1 user dir, for backward compatibility */
	if (compat)
	{
		const gchar *home;

		home = g_get_home_dir ();
		if (home != NULL)
		{
			g_ptr_array_add (dirs,
					 g_strdup_printf ("%s/%s",
							  home,
							  ".gnome2/gtksourceview-1.0/language-specs"));
		}
	}
#endif

	/* system dir */
	for (xdg_dirs = g_get_system_data_dirs (); xdg_dirs && *xdg_dirs; ++xdg_dirs)
	{
		g_ptr_array_add (dirs, g_build_filename (*xdg_dirs,
							 SOURCEVIEW_DIR,
							 basename,
							 NULL));
	}

	g_ptr_array_add (dirs, NULL);

	return (gchar**) g_ptr_array_free (dirs, FALSE);
}

static GSList *
build_file_listing (const gchar *item,
		    GSList      *filenames,
		    const gchar *suffix,
		    gboolean     only_dirs)
{
	GDir *dir;
	const gchar *name;

	if (!only_dirs && g_file_test (item, G_FILE_TEST_IS_REGULAR))
	{
		filenames = g_slist_prepend (filenames, g_strdup(item));
		return filenames;

	}
	dir = g_dir_open (item, 0, NULL);

	if (dir == NULL)
	{
		return filenames;
	}

	while ((name = g_dir_read_name (dir)) != NULL)
	{
		gchar *full_path = g_build_filename (item, name, NULL);

		if (!g_file_test (full_path, G_FILE_TEST_IS_DIR) &&
		    g_str_has_suffix (name, suffix))
		{
			filenames = g_slist_prepend (filenames, full_path);
		}
		else
		{
			g_free (full_path);
		}
	}

	g_dir_close (dir);

	return filenames;
}

GSList *
_gtk_source_view_get_file_list (gchar       **path,
				const gchar  *suffix,
				gboolean      only_dirs)
{
	GSList *files = NULL;

	for ( ; path && *path; ++path)
	{
		files = build_file_listing (*path, files, suffix, only_dirs);
	}

	return g_slist_reverse (files);
}

/* Wrapper around strtoull for easier use: tries
 * to convert @str to a number and return -1 if it is not.
 * Used to check if references in subpattern contexts
 * (e.g. \%{1@start} or \%{blah@start}) are named or numbers.
 */
gint
_gtk_source_string_to_int (const gchar *str)
{
	guint64 number;
	gchar *end_str;

	if (str == NULL || *str == '\0')
	{
		return -1;
	}

	errno = 0;
	number = g_ascii_strtoull (str, &end_str, 10);

	if (errno != 0 || number > G_MAXINT || *end_str != '\0')
	{
		return -1;
	}

	return number;
}

#define FONT_FAMILY  "font-family"
#define FONT_VARIANT "font-variant"
#define FONT_STRETCH "font-stretch"
#define FONT_WEIGHT  "font-weight"
#define FONT_SIZE    "font-size"

gchar *
_gtk_source_pango_font_description_to_css (const PangoFontDescription *font_desc)
{
	PangoFontMask mask;
	GString *str;

#define ADD_KEYVAL(key,fmt) \
	g_string_append(str,key":"fmt";")
#define ADD_KEYVAL_PRINTF(key,fmt,...) \
	g_string_append_printf(str,key":"fmt";", __VA_ARGS__)

	g_return_val_if_fail (font_desc, NULL);

	str = g_string_new (NULL);

	mask = pango_font_description_get_set_fields (font_desc);

	if ((mask & PANGO_FONT_MASK_FAMILY) != 0)
	{
		const gchar *family;

		family = pango_font_description_get_family (font_desc);
		ADD_KEYVAL_PRINTF (FONT_FAMILY, "\"%s\"", family);
	}

	if ((mask & PANGO_FONT_MASK_STYLE) != 0)
	{
		PangoVariant variant;

		variant = pango_font_description_get_variant (font_desc);

		switch (variant)
		{
			case PANGO_VARIANT_NORMAL:
				ADD_KEYVAL (FONT_VARIANT, "normal");
				break;

			case PANGO_VARIANT_SMALL_CAPS:
				ADD_KEYVAL (FONT_VARIANT, "small-caps");
				break;

			default:
				break;
		}
	}

	if ((mask & PANGO_FONT_MASK_WEIGHT))
	{
		gint weight;

		weight = pango_font_description_get_weight (font_desc);

		/*
		 * WORKAROUND:
		 *
		 * font-weight with numbers does not appear to be working as expected
		 * right now. So for the common (bold/normal), let's just use the string
		 * and let gtk warn for the other values, which shouldn't really be
		 * used for this.
		 */

		switch (weight)
		{
			case PANGO_WEIGHT_SEMILIGHT:
			/*
			 * 350 is not actually a valid css font-weight, so we will just round
			 * up to 400.
			 */
			case PANGO_WEIGHT_NORMAL:
				ADD_KEYVAL (FONT_WEIGHT, "normal");
				break;

			case PANGO_WEIGHT_BOLD:
				ADD_KEYVAL (FONT_WEIGHT, "bold");
				break;

			case PANGO_WEIGHT_THIN:
			case PANGO_WEIGHT_ULTRALIGHT:
			case PANGO_WEIGHT_LIGHT:
			case PANGO_WEIGHT_BOOK:
			case PANGO_WEIGHT_MEDIUM:
			case PANGO_WEIGHT_SEMIBOLD:
			case PANGO_WEIGHT_ULTRABOLD:
			case PANGO_WEIGHT_HEAVY:
			case PANGO_WEIGHT_ULTRAHEAVY:
			default:
				/* round to nearest hundred */
				weight = round (weight / 100.0) * 100;
				ADD_KEYVAL_PRINTF ("font-weight", "%d", weight);
				break;
		}
	}

	if ((mask & PANGO_FONT_MASK_STRETCH))
	{
		switch (pango_font_description_get_stretch (font_desc))
		{
			case PANGO_STRETCH_ULTRA_CONDENSED:
				ADD_KEYVAL (FONT_STRETCH, "untra-condensed");
				break;

			case PANGO_STRETCH_EXTRA_CONDENSED:
				ADD_KEYVAL (FONT_STRETCH, "extra-condensed");
				break;

			case PANGO_STRETCH_CONDENSED:
				ADD_KEYVAL (FONT_STRETCH, "condensed");
				break;

			case PANGO_STRETCH_SEMI_CONDENSED:
				ADD_KEYVAL (FONT_STRETCH, "semi-condensed");
				break;

			case PANGO_STRETCH_NORMAL:
				ADD_KEYVAL (FONT_STRETCH, "normal");
				break;

			case PANGO_STRETCH_SEMI_EXPANDED:
				ADD_KEYVAL (FONT_STRETCH, "semi-expanded");
				break;

			case PANGO_STRETCH_EXPANDED:
				ADD_KEYVAL (FONT_STRETCH, "expanded");
				break;

			case PANGO_STRETCH_EXTRA_EXPANDED:
				ADD_KEYVAL (FONT_STRETCH, "extra-expanded");
				break;

			case PANGO_STRETCH_ULTRA_EXPANDED:
				ADD_KEYVAL (FONT_STRETCH, "untra-expanded");
				break;

			default:
				break;
		}
	}

	if ((mask & PANGO_FONT_MASK_SIZE))
	{
		gint font_size;

		font_size = pango_font_description_get_size (font_desc) / PANGO_SCALE;
		ADD_KEYVAL_PRINTF ("font-size", "%dpt", font_size);
	}

	return g_string_free (str, FALSE);

#undef ADD_KEYVAL
#undef ADD_KEYVAL_PRINTF
}
