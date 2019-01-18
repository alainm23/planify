/*
 * evolution-scan-gconf-tree-xml.c
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
 */

#include "evolution-data-server-config.h"

#include <locale.h>
#include <stdlib.h>
#include <glib/gi18n.h>

#include <glib.h>

#include <libedataserver/libedataserver.h>

#define PROGRAM_SUMMARY \
	"Extracts Evolution accounts from a merged GConf tree file."

/* Forward Declarations */
gboolean	evolution_source_registry_migrate_gconf_tree_xml
						(const gchar *filename,
						 GError **error);

gint
main (gint argc,
      gchar **argv)
{
	GOptionContext *context;
	GError *error = NULL;

	setlocale (LC_ALL, "");
	bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
	bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");

	context = g_option_context_new ("/path/to/%gconf-tree.xml");
	g_option_context_set_summary (context, PROGRAM_SUMMARY);
	g_option_context_parse (context, &argc, &argv, &error);

	if (error != NULL) {
		g_printerr ("%s\n", error->message);
		exit (1);
	}

	if (argc != 2) {
		e_source_registry_debug_print (
			"Usage: %s /path/to/%%gconf-tree.xml\n\n",
			g_get_prgname ());
		exit (0);
	}

	evolution_source_registry_migrate_gconf_tree_xml (argv[1], &error);

	if (error != NULL) {
		g_printerr ("%s\n", error->message);
		exit (1);
	}

	return 0;
}

