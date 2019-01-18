/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016 Matthias Klumpp <matthias@tenstral.net>
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

#include "ascli-actions-misc.h"

#include <config.h>
#include <glib/gi18n-lib.h>

#include "as-utils-private.h"
#include "as-settings-private.h"
#include "ascli-utils.h"

/**
 * ascli_show_status:
 *
 * Print various interesting status information.
 */
int
ascli_show_status (void)
{
	guint i;
	g_autoptr(AsPool) dpool = NULL;
	g_autoptr(GError) error = NULL;
	const gchar *metainfo_path = "/usr/share/metainfo";
	const gchar *appdata_path = "/usr/share/appdata";

	/* TRANSLATORS: In the status report of ascli: Header */
	ascli_print_highlight (_("AppStream Status:"));
	ascli_print_stdout (_("Version: %s"), PACKAGE_VERSION);
	g_print ("\n");

	/* TRANSLATORS: In the status report of ascli: Refers to the metadata shipped by distributions */
	ascli_print_highlight (_("Distribution metadata:"));
	for (i = 0; AS_APPSTREAM_METADATA_PATHS[i] != NULL; i++) {
		g_autofree gchar *xml_path = NULL;
		g_autofree gchar *yaml_path = NULL;
		g_autofree gchar *icons_path = NULL;
		gboolean found = FALSE;

		xml_path = g_build_filename (AS_APPSTREAM_METADATA_PATHS[i], "xmls", NULL);
		yaml_path = g_build_filename (AS_APPSTREAM_METADATA_PATHS[i], "yaml", NULL);
		icons_path = g_build_filename (AS_APPSTREAM_METADATA_PATHS[i], "icons", NULL);

		g_print (" %s\n", AS_APPSTREAM_METADATA_PATHS[i]);

		/* display XML data count */
		if (g_file_test (xml_path, G_FILE_TEST_IS_DIR)) {
			g_autoptr(GPtrArray) xmls = NULL;

			xmls = as_utils_find_files_matching (xml_path, "*.xml*", FALSE, NULL);
			if (xmls != NULL) {
				ascli_print_stdout ("  - XML:  %i", xmls->len);
				found = TRUE;
			}
		}

		/* display YAML data count */
		if (g_file_test (yaml_path, G_FILE_TEST_IS_DIR)) {
			g_autoptr(GPtrArray) yaml = NULL;

			yaml = as_utils_find_files_matching (yaml_path, "*.yml*", FALSE, NULL);
			if (yaml != NULL) {
				ascli_print_stdout ("  - YAML: %i", yaml->len);
				found = TRUE;
			}
		}

		/* display icon information data count */
		if (g_file_test (icons_path, G_FILE_TEST_IS_DIR)) {
			guint j;
			g_autoptr(GPtrArray) icon_dirs = NULL;
			icon_dirs = as_utils_find_files_matching (icons_path, "*", FALSE, NULL);
			if (icon_dirs != NULL) {
				found = TRUE;
				ascli_print_stdout ("  - %s:", _("Iconsets"));
				for (j = 0; j < icon_dirs->len; j++) {
					const gchar *ipath;
					g_autofree gchar *dname = NULL;
					ipath = (const gchar *) g_ptr_array_index (icon_dirs, j);

					dname = g_path_get_basename (ipath);
					g_print ("     %s\n", dname);
				}
			}
		} else if (found) {
			ascli_print_stdout ("  - %s", _("No icons."));
		}

		if (!found) {
			ascli_print_stdout ("  - %s", _("Empty."));
		}

		g_print ("\n");
	}

	/* TRANSLATORS: Info about upstream metadata / metainfo files in the ascli status report */
	ascli_print_highlight (_("Metainfo files:"));
	if (g_file_test (metainfo_path, G_FILE_TEST_IS_DIR)) {
		g_autoptr(GPtrArray) xmls = NULL;
		g_autofree gchar *msg = NULL;

		xmls = as_utils_find_files_matching (metainfo_path, "*.xml", FALSE, NULL);
		if (xmls != NULL) {
			msg = g_strdup_printf (_("Found %i components."), xmls->len);
			ascli_print_stdout ("  - %s", msg);
		}
	} else {
		if (!g_file_test (appdata_path, G_FILE_TEST_IS_DIR))
			/* TRANSLATORS: No metainfo files have been found */
			ascli_print_stdout ("  - %s", _("Empty."));
	}
	if (g_file_test (appdata_path, G_FILE_TEST_IS_DIR)) {
		g_autoptr(GPtrArray) xmls = NULL;
		g_autofree gchar *msg = NULL;

		xmls = as_utils_find_files_matching (appdata_path, "*.xml", FALSE, NULL);
		if (xmls != NULL) {
			/* TRANSLATORS: Found metainfo files in legacy directories */
			msg = g_strdup_printf (_("Found %i components in legacy paths."), xmls->len);
			ascli_print_stdout ("  - %s", msg);
		}
	}
	g_print ("\n");

	/* TRANSLATORS: Status summary in ascli */
	ascli_print_highlight (_("Summary:"));

	dpool = as_pool_new ();
	as_pool_load (dpool, NULL, &error);
	if (error == NULL) {
		g_autoptr(GPtrArray) cpts = NULL;
		cpts = as_pool_get_components (dpool);

		ascli_print_stdout (_("We have information on %i software components."), cpts->len);
		/* TODO: Request the on-disk cache status from #AsPool and display it here.
		 * ascli_print_stdout (_("The system metadata cache exists."));
		 * ascli_print_stdout (_("The system metadata cache does not exist."));
		 */
	} else {
		ascli_print_stderr (_("Error while loading the metadata pool: %s"), error->message);
	}

	return 0;
}
