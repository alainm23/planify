/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2015 Matthias Klumpp <matthias@tenstral.net>
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

#include <config.h>
#include <glib.h>
#include <glib-object.h>
#include <glib/gi18n-lib.h>
#include <locale.h>
#include <stdio.h>

#include "ascli-utils.h"
#include "ascli-actions-mdata.h"
#include "ascli-actions-validate.h"
#include "ascli-actions-pkgmgr.h"
#include "ascli-actions-misc.h"

#define ASCLI_BIN_NAME "appstreamcli"

/* global options which affect all commands */
static gboolean optn_show_version = FALSE;
static gboolean optn_verbose_mode = FALSE;
static gboolean optn_no_color = FALSE;

/*** COMMAND OPTIONS ***/

/* for data_collection_options */
static gchar *optn_cachepath = NULL;
static gchar *optn_datapath = NULL;
static gboolean optn_no_cache = FALSE;

/**
 * General options used for any operations on
 * metadata collections and the cache.
 */
const GOptionEntry data_collection_options[] = {
	{ "cachepath", 0, 0,
		G_OPTION_ARG_STRING,
		&optn_cachepath,
		/* TRANSLATORS: ascli flag description for: --cachepath */
		N_("Manually selected location of AppStream cache."), NULL },
	{ "datapath", 0, 0,
		G_OPTION_ARG_STRING,
		&optn_datapath,
		/* TRANSLATORS: ascli flag description for: --datapath */
		N_("Manually selected location of AppStream metadata to scan."), NULL },
	{ "no-cache", 0, 0,
		G_OPTION_ARG_NONE,
		&optn_no_cache,
		/* TRANSLATORS: ascli flag description for: --no-cache */
		N_("Make request without any caching."),
		NULL },
	{ NULL }
};

/* used by format_options */
static gchar *optn_format = NULL;

/**
 * The format option.
 */
const GOptionEntry format_options[] = {
	{ "format", 0, 0,
		G_OPTION_ARG_STRING,
		&optn_format,
		/* TRANSLATORS: ascli flag description for: --format */
		N_("Default metadata format (valid values are 'xml' and 'yaml')."), NULL },
	{ NULL }
};

/* used by find_options */
static gboolean optn_details = FALSE;

/**
 * General options for finding & displaying data.
 */
const GOptionEntry find_options[] = {
	{ "details", 0, 0,
		G_OPTION_ARG_NONE,
		&optn_details,
		/* TRANSLATORS: ascli flag description for: --details */
		N_("Print detailed output about found components."),
		NULL },
	{ NULL }
};

/* used by validate_options */
static gboolean optn_pedantic = FALSE;
static gboolean optn_nonet = FALSE;

/**
 * General options for validation.
 */
const GOptionEntry validate_options[] = {
	{ "pedantic", (gchar) 0, 0,
		G_OPTION_ARG_NONE,
		&optn_pedantic,
		/* TRANSLATORS: ascli flag description for: --pedantic (used by the "validate" command) */
		N_("Also show pedantic hints."), NULL },
	{ "no-net", (gchar) 0, 0,
		G_OPTION_ARG_NONE,
		&optn_nonet,
		/* TRANSLATORS: ascli flag description for: --no-net (used by the "validate" command) */
		N_("Do not use network access."), NULL },
	{ "nonet", (gchar) 0, G_OPTION_FLAG_HIDDEN,
		G_OPTION_ARG_NONE,
		&optn_nonet,
		NULL, NULL },
	{ NULL }
};

/* only used by the "refresh --force" command */
static gboolean optn_force = FALSE;

/*** HELPER METHODS ***/

/**
 * as_client_get_summary_for:
 **/
static gchar*
as_client_get_summary_for (const gchar *command)
{
	GString *string;
	string = g_string_new ("");

	/* TRANSLATORS: This is the header to the --help menu for subcommands */
	g_string_append_printf (string, "%s\n", _("AppStream command-line interface"));

	g_string_append (string, " ");
	g_string_append_printf (string, _("'%s' command"), command);

	return g_string_free (string, FALSE);
}

/**
 * as_client_new_subcommand_option_context:
 *
 * Create a new option context for an ascli subcommand.
 */
static GOptionContext*
as_client_new_subcommand_option_context (const gchar *command, const GOptionEntry *entries)
{
	GOptionContext *opt_context = NULL;
	g_autofree gchar *summary = NULL;

	opt_context = g_option_context_new ("- AppStream CLI.");
	g_option_context_set_help_enabled (opt_context, TRUE);
	g_option_context_add_main_entries (opt_context, entries, NULL);

	/* set the summary text */
	summary = as_client_get_summary_for (command);
	g_option_context_set_summary (opt_context, summary);

	return opt_context;
}

/**
 * as_client_print_help_hint:
 */
static void
as_client_print_help_hint (const gchar *subcommand, const gchar *unknown_option)
{
	if (unknown_option != NULL) {
		/* TRANSLATORS: An unknown option was passed to appstreamcli. */
		ascli_print_stderr (_("Option '%s' is unknown."), unknown_option);
	}

	if (subcommand == NULL)
		ascli_print_stderr (_("Run '%s --help' to see a full list of available command line options."), ASCLI_BIN_NAME);
	else
		ascli_print_stderr (_("Run '%s --help' to see a list of available commands and options, and '%s %s --help' to see a list of options specific for this subcommand."),
				    ASCLI_BIN_NAME, ASCLI_BIN_NAME, subcommand);
}

/**
 * as_client_option_context_parse:
 *
 * Parse the options, print errors.
 */
static int
as_client_option_context_parse (GOptionContext *opt_context, const gchar *subcommand, int *argc, char ***argv)
{
	g_autoptr(GError) error = NULL;

	g_option_context_parse (opt_context, argc, argv, &error);
	if (error != NULL) {
		gchar *msg;
		msg = g_strconcat (error->message, "\n", NULL);
		g_print ("%s", msg);
		g_free (msg);

		as_client_print_help_hint (subcommand, NULL);
		return 1;
	}

	return 0;
}

/*** SUBCOMMANDS ***/

/**
 * as_client_run_refresh_cache:
 *
 * Refresh the AppStream caches.
 */
static int
as_client_run_refresh_cache (char **argv, int argc)
{
	g_autoptr(GOptionContext) opt_context = NULL;
	gint ret;
	const gchar *command = "refresh";

	const GOptionEntry refresh_options[] = {
		{ "force", (gchar) 0, 0,
			G_OPTION_ARG_NONE,
			&optn_force,
			/* TRANSLATORS: ascli flag description for: --force */
			_("Enforce a cache refresh."),
			NULL },
		{ NULL }
	};

	opt_context = as_client_new_subcommand_option_context (command, refresh_options);
	g_option_context_add_main_entries (opt_context, data_collection_options, NULL);

	ret = as_client_option_context_parse (opt_context,
					      command, &argc, &argv);
	if (ret != 0)
		return ret;

	return ascli_refresh_cache (optn_cachepath,
					optn_datapath,
					optn_force);
}

/**
 * as_client_run_search:
 *
 * Search for AppStream metadata.
 */
static int
as_client_run_search (char **argv, int argc)
{
	g_autoptr(GOptionContext) opt_context = NULL;
	gint ret;
	const gchar *value = NULL;
	const gchar *command = "search";

	opt_context = as_client_new_subcommand_option_context (command, find_options);
	g_option_context_add_main_entries (opt_context, data_collection_options, NULL);

	ret = as_client_option_context_parse (opt_context, command, &argc, &argv);
	if (ret != 0)
		return ret;

	if (argc > 2)
		value = argv[2];

	return ascli_search_component (optn_cachepath,
					value,
					optn_details,
					optn_no_cache);
}

/**
 * as_client_run_get:
 *
 * Get components by its ID.
 */
static int
as_client_run_get (char **argv, int argc)
{
	g_autoptr(GOptionContext) opt_context = NULL;
	gint ret;
	const gchar *value = NULL;
	const gchar *command = "get";

	opt_context = as_client_new_subcommand_option_context (command, find_options);
	g_option_context_add_main_entries (opt_context, data_collection_options, NULL);

	ret = as_client_option_context_parse (opt_context, command, &argc, &argv);
	if (ret != 0)
		return ret;

	if (argc > 2)
		value = argv[2];

	return ascli_get_component (optn_cachepath,
					value,
					optn_details,
					optn_no_cache);
}

/**
 * as_client_run_dump:
 *
 * Dump the raw component metadata to the console.
 */
static int
as_client_run_dump (char **argv, int argc)
{
	g_autoptr(GOptionContext) opt_context = NULL;
	gint ret;
	const gchar *value = NULL;
	AsFormatKind mformat;
	const gchar *command = "dump";

	opt_context = as_client_new_subcommand_option_context (command, data_collection_options);
	g_option_context_add_main_entries (opt_context, format_options, NULL);

	ret = as_client_option_context_parse (opt_context, command, &argc, &argv);
	if (ret != 0)
		return ret;

	if (argc > 2)
		value = argv[2];

	mformat = as_format_kind_from_string (optn_format);
	return ascli_dump_component (optn_cachepath,
					value,
					mformat,
					optn_no_cache);
}

/**
 * as_client_run_what_provides:
 *
 * Find components that provide a certain item.
 */
static int
as_client_run_what_provides (char **argv, int argc)
{
	g_autoptr(GOptionContext) opt_context = NULL;
	gint ret;
	const gchar *vtype = NULL;
	const gchar *vvalue = NULL;
	const gchar *command = "what-provides";

	opt_context = as_client_new_subcommand_option_context (command, find_options);
	g_option_context_add_main_entries (opt_context, data_collection_options, NULL);

	ret = as_client_option_context_parse (opt_context, command, &argc, &argv);
	if (ret != 0)
		return ret;

	if (argc > 2)
		vtype = argv[2];
	if (argc > 3)
		vvalue = argv[3];

	return ascli_what_provides (optn_cachepath,
				    vtype,
				    vvalue,
				    optn_details);
}

/**
 * as_client_run_validate:
 *
 * Validate single metadata files.
 */
static int
as_client_run_validate (char **argv, int argc)
{
	g_autoptr(GOptionContext) opt_context = NULL;
	gint ret;
	const gchar *command = "validate";

	opt_context = as_client_new_subcommand_option_context (command, validate_options);
	ret = as_client_option_context_parse (opt_context, command, &argc, &argv);
	if (ret != 0)
		return ret;

	return ascli_validate_files (&argv[2],
				     argc-2,
				     optn_pedantic,
				     !optn_nonet);
}

/**
 * as_client_run_validate_tree:
 *
 * Validate an installed filesystem tree for correct AppStream metadata
 * and .desktop files.
 */
static int
as_client_run_validate_tree (char **argv, int argc)
{
	g_autoptr(GOptionContext) opt_context = NULL;
	gint ret;
	const gchar *value = NULL;
	const gchar *command = "validate-tree";

	opt_context = as_client_new_subcommand_option_context (command, validate_options);
	ret = as_client_option_context_parse (opt_context, command, &argc, &argv);
	if (ret != 0)
		return ret;

	if (argc > 2)
		value = argv[2];

	return ascli_validate_tree (value,
				    optn_pedantic,
				    !optn_nonet);
}

/**
 * as_client_run_put:
 *
 * Place a metadata file in the right directory.
 */
static int
as_client_run_put (char **argv, int argc)
{
	const gchar *value = NULL;
	const gchar *command = "put";

	if (argc > 2)
		value = argv[2];
	if (argc > 3) {
		as_client_print_help_hint (command, argv[3]);
		return 1;
	}

	return ascli_put_metainfo (value);
}

/**
 * as_client_run_install:
 *
 * Install a component by its ID.
 */
static int
as_client_run_install (char **argv, int argc)
{
	const gchar *value = NULL;
	const gchar *command = "install";

	if (argc > 2)
		value = argv[2];
	if (argc > 3) {
		as_client_print_help_hint (command, argv[3]);
		return 1;
	}

	return ascli_install_component (value);
}

/**
 * as_client_run_remove:
 *
 * Uninstall a component by its ID.
 */
static int
as_client_run_remove (char **argv, int argc)
{
	const gchar *value = NULL;
	const gchar *command = "remove";

	if (argc > 2)
		value = argv[2];
	if (argc > 3) {
		as_client_print_help_hint (command, argv[3]);
		return 1;
	}

	return ascli_remove_component (value);
}

/**
 * as_client_run_status:
 *
 * Show diagnostic information.
 */
static int
as_client_run_status (char **argv, int argc)
{
	const gchar *command = "status";

	if (argc > 2) {
		as_client_print_help_hint (command, argv[3]);
		return 1;
	}

	return ascli_show_status ();
}

/**
 * as_client_run_convert:
 *
 * Convert metadata.
 */
static int
as_client_run_convert (char **argv, int argc)
{
	g_autoptr(GOptionContext) opt_context = NULL;
	gint ret;
	const gchar *fname1 = NULL;
	const gchar *fname2 = NULL;
	AsFormatKind mformat;
	const gchar *command = "convert";

	opt_context = as_client_new_subcommand_option_context (command, format_options);
	ret = as_client_option_context_parse (opt_context, command, &argc, &argv);
	if (ret != 0)
		return ret;

	if (argc > 2)
		fname1 = argv[2];
	if (argc > 3)
		fname2 = argv[3];

	mformat = as_format_kind_from_string (optn_format);
	return ascli_convert_data (fname1,
				   fname2,
				   mformat);
}

/**
 * as_client_run_compare_versions:
 *
 * Compare versions using AppStream's version comparison algorithm.
 */
static int
as_client_run_compare_versions (char **argv, int argc)
{
	g_autoptr(GOptionContext) opt_context = NULL;
	gint ret;
	const gchar *command = "compare-versions";

	opt_context = as_client_new_subcommand_option_context (command, format_options);
	ret = as_client_option_context_parse (opt_context, command, &argc, &argv);
	if (ret != 0)
		return ret;

	if (argc < 4) {
		ascli_print_stderr (_("You need to provide at least two version numbers to compare as parameters."));
		return 2;
	}

	if (argc == 4) {
		const gchar *ver1 = argv[2];
		const gchar *ver2 = argv[3];
		gint comp_res = as_utils_compare_versions (ver1, ver2);

		if (comp_res == 0)
			g_print ("%s == %s\n", ver1, ver2);
		else if (comp_res > 0)
			g_print ("%s >> %s\n", ver1, ver2);
		else if (comp_res < 0)
			g_print ("%s << %s\n", ver1, ver2);

		return 0;
	} else if (argc == 5) {
		AsRelationCompare compare;
		gint rc;
		gboolean res;
		const gchar *ver1 = argv[2];
		const gchar *comp_str = argv[3];
		const gchar *ver2 = argv[4];

		compare = as_relation_compare_from_string (comp_str);
		if (compare == AS_RELATION_COMPARE_UNKNOWN) {
			guint i;
			/** TRANSLATORS: The user tried to compare version numbers, but the comparison operator (greater-then, equal, etc.) was invalid. */
			ascli_print_stderr (_("Unknown compare relation '%s'. Valid values are:"), comp_str);
			for (i = 1; i < AS_RELATION_COMPARE_LAST; i++)
				g_printerr (" • %s\n", as_relation_compare_to_string (i));
			return 2;
		}

		rc = as_utils_compare_versions (ver1, ver2);
		switch (compare) {
		case AS_RELATION_COMPARE_EQ:
			res = rc == 0;
			break;
		case AS_RELATION_COMPARE_NE:
			res = rc != 0;
			break;
		case AS_RELATION_COMPARE_LT:
			res = rc < 0;
			break;
		case AS_RELATION_COMPARE_GT:
			res = rc > 0;
			break;
		case AS_RELATION_COMPARE_LE:
			res = rc <= 0;
			break;
		case AS_RELATION_COMPARE_GE:
			res = rc >= 0;
			break;
		default:
			res = FALSE;
		}

		g_print ("%s: ", res? "true" : "false");
		if (rc == 0)
			g_print ("%s == %s\n", ver1, ver2);
		else if (rc > 0)
			g_print ("%s >> %s\n", ver1, ver2);
		else if (rc < 0)
			g_print ("%s << %s\n", ver1, ver2);

		return res? 0 : 1;
	} else {
		ascli_print_stderr (_("Too many parameters: Need two version numbers or version numbers and a comparison operator."));
		return 2;
	}
}

/**
 * as_client_run_new_template:
 *
 * Convert metadata.
 */
static int
as_client_run_new_template (char **argv, int argc)
{
	g_autoptr(GOptionContext) opt_context = NULL;
	g_autoptr(GString) desc_str = NULL;
	guint i;
	gint ret;
	const gchar *command = "new-template";
	const gchar *out_fname = NULL;
	const gchar *cpt_kind_str = NULL;
	const gchar *optn_desktop_file = NULL;

	const GOptionEntry newtemplate_options[] = {
		{ "from-desktop", 0, 0,
			G_OPTION_ARG_STRING,
			&optn_desktop_file,
			/* TRANSLATORS: ascli flag description for: --from-desktop (part of the new-template subcommand) */
			N_("Use the given .desktop file to fill in the basic values of the metainfo file."), NULL },
		{ NULL }
	};

	/* TRANSLATORS: Additional help text for the 'new-template' ascli subcommand */
	desc_str = g_string_new (_("This command takes optional TYPE and FILE positional arguments, FILE being a file to write to (or \"-\" for standard output)."));
	g_string_append (desc_str, "\n");
	/* TRANSLATORS: Additional help text for the 'new-template' ascli subcommand, a bullet-pointed list of types follows */
	g_string_append_printf (desc_str, _("The TYPE must be a valid component-type, such as: %s"), "\n");
	for (i = 1; i < AS_COMPONENT_KIND_LAST; i++)
		g_string_append_printf (desc_str, " • %s\n", as_component_kind_to_string (i));

	opt_context = as_client_new_subcommand_option_context (command, newtemplate_options);
	g_option_context_set_description (opt_context, desc_str->str);

	ret = as_client_option_context_parse (opt_context,
					      command, &argc, &argv);
	if (ret != 0)
		return ret;

	if (argc > 2)
		cpt_kind_str = argv[2];
	if (argc > 3)
		out_fname = argv[3];

	return ascli_create_metainfo_template (out_fname,
					       cpt_kind_str,
					       optn_desktop_file);
}

/**
 * as_client_get_summary:
 **/
static gchar*
as_client_get_summary ()
{
	GString *string;
	string = g_string_new ("");

	/* TRANSLATORS: This is the header to the --help menu */
	g_string_append_printf (string, "%s\n\n%s\n", _("AppStream command-line interface"),
				/* these are commands we can use with appstreamcli */
				_("Subcommands:"));

	g_string_append_printf (string, "  %s - %s\n", "search TERM     ", _("Search the component database."));
	g_string_append_printf (string, "  %s - %s\n", "get COMPONENT-ID", _("Get information about a component by its ID."));
	g_string_append_printf (string, "  %s - %s\n", "what-provides TYPE VALUE", _("Get components which provide the given item."));
	g_string_append_printf (string, "    %s - %s\n", "TYPE ", _("An item type (e.g. lib, bin, python3, …)"));
	g_string_append_printf (string, "    %s - %s\n", "VALUE", _("Value of the item that should be found."));
	g_string_append (string, "\n");
	g_string_append_printf (string, "  %s - %s\n", "dump COMPONENT-ID", _("Dump raw XML metadata for a component matching the ID."));
	g_string_append_printf (string, "  %s - %s\n", "refresh-cache    ", _("Rebuild the component metadata cache."));
	g_string_append (string, "\n");
	g_string_append_printf (string, "  %s - %s\n", "validate FILE          ", _("Validate AppStream XML files for issues."));
	g_string_append_printf (string, "  %s - %s\n", "validate-tree DIRECTORY", _("Validate an installed file-tree of an application for valid metadata."));
	g_string_append (string, "\n");
	g_string_append_printf (string, "  %s - %s\n", "install COMPONENT-ID", _("Install software matching the component-ID."));
	g_string_append_printf (string, "  %s - %s\n", "remove  COMPONENT-ID", _("Remove software matching the component-ID."));
	g_string_append (string, "\n");
	g_string_append_printf (string, "  %s - %s\n", "status           ", _("Display status information about available AppStream metadata."));
	g_string_append_printf (string, "  %s - %s\n", "put FILE         ", _("Install a metadata file into the right location."));
	/* TRANSLATORS: "convert" command in ascli. "Collection XML" is a term describing a specific type of AppStream XML data. */
	g_string_append_printf (string, "  %s - %s\n", "convert FILE FILE", _("Convert collection XML to YAML or vice versa."));
	g_string_append_printf (string, "  %s - %s\n", "compare-versions VER1 [COMP] VER2", _("Compare two version numbers."));
	g_string_append_printf (string, "  %s - %s\n", "new-template TYPE FILE", _("Create a template for a metainfo file (to be filled out by the upstream project)."));

	g_string_append (string, "\n");
	g_string_append (string, _("You can find information about subcommand-specific options by passing \"--help\" to the subcommand."));

	return g_string_free (string, FALSE);
}

/**
 * as_client_run:
 */
static int
as_client_run (char **argv, int argc)
{
	g_autoptr(GOptionContext) opt_context = NULL;
	gint ret;
	const gchar *command = NULL;

	gchar *summary;
	g_autofree gchar *options_help = NULL;

	const GOptionEntry client_options[] = {
		{ "version", 0, 0,
			G_OPTION_ARG_NONE,
			&optn_show_version,
			/* TRANSLATORS: ascli flag description for: --version */
			_("Show the program version."),
			NULL },
		{ "verbose", (gchar) 0, 0,
			G_OPTION_ARG_NONE,
			&optn_verbose_mode,
			/* TRANSLATORS: ascli flag description for: --verbose */
			_("Show extra debugging information."),
			NULL },
		{ "no-color", (gchar) 0, 0,
			G_OPTION_ARG_NONE, &optn_no_color,
			/* TRANSLATORS: ascli flag description for: --no-color */
			_("Don\'t show colored output."), NULL },
		{ NULL }
	};

	opt_context = g_option_context_new ("- AppStream CLI.");
	g_option_context_add_main_entries (opt_context, client_options, NULL);

	/* set the summary text */
	summary = as_client_get_summary ();
	g_option_context_set_summary (opt_context, summary) ;
	g_free (summary);

	/* we handle the unknown options later in the individual subcommands */
	g_option_context_set_ignore_unknown_options (opt_context, TRUE);

	if (argc < 2) {
		/* TRANSLATORS: ascli has been run without command. */
		g_printerr ("%s\n", _("You need to specify a command."));
		ascli_print_stderr (_("Run '%s --help' to see a full list of available command line options."), argv[0]);
		return 1;
	}
	command = argv[1];

	/* only attempt to show global help if we don't have a subcommand as first parameter (subcommands are never prefixed with "-") */
	if (g_str_has_prefix (command, "-"))
		g_option_context_set_help_enabled (opt_context, TRUE);
	else
		g_option_context_set_help_enabled (opt_context, FALSE);

	ret = as_client_option_context_parse (opt_context, NULL, &argc, &argv);
	if (ret != 0)
		return ret;

	if (optn_show_version) {
		if (g_strcmp0 (as_get_appstream_version (), PACKAGE_VERSION) == 0) {
			/* TRANSLATORS: Output if appstreamcli --version is executed. */
			ascli_print_stdout (_("AppStream version: %s"), PACKAGE_VERSION);
		} else {
			/* TRANSLATORS: Output if appstreamcli --version is run and the CLI and libappstream versions differ. */
			ascli_print_stdout (_("AppStream CLI tool version: %s\nAppStream library version: %s"), PACKAGE_VERSION, as_get_appstream_version ());
		}
		return 0;
	}

	/* just a hack, we might need proper message handling later */
	if (optn_verbose_mode) {
		g_setenv ("G_MESSAGES_DEBUG", "all", TRUE);
	}

	/* allow disabling network access via an environment variable */
	if (g_getenv ("AS_VALIDATE_NONET") != NULL) {
		g_debug ("Disabling network usage: Environment variable AS_VALIDATE_NONET is set.");
		optn_nonet = TRUE;
	}

	ascli_set_output_colored (!optn_no_color);

	/* if out terminal is no tty, disable colors automatically */
	if (!isatty (fileno (stdout)))
		ascli_set_output_colored (FALSE);

	/* don't let gvfsd start it's own session bus: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=852696 */
	g_setenv ("GIO_USE_VFS", "local", TRUE);

	/* process subcommands */
	if ((g_strcmp0 (command, "search") == 0) || (g_strcmp0 (command, "s") == 0)) {
		return as_client_run_search (argv, argc);
	} else if ((g_strcmp0 (command, "refresh-cache") == 0) || (g_strcmp0 (command, "refresh") == 0)) {
		return as_client_run_refresh_cache (argv, argc);
	} else if (g_strcmp0 (command, "get") == 0) {
		return as_client_run_get (argv, argc);
	} else if (g_strcmp0 (command, "dump") == 0) {
		return as_client_run_dump (argv, argc);
	} else if (g_strcmp0 (command, "what-provides") == 0) {
		return as_client_run_what_provides (argv, argc);
	} else if (g_strcmp0 (command, "validate") == 0) {
		return as_client_run_validate (argv, argc);
	} else if (g_strcmp0 (command, "validate-tree") == 0) {
		return as_client_run_validate_tree (argv, argc);
	} else if (g_strcmp0 (command, "put") == 0) {
		return as_client_run_put (argv, argc);
	} else if (g_strcmp0 (command, "install") == 0) {
		return as_client_run_install (argv, argc);
	} else if (g_strcmp0 (command, "remove") == 0) {
		return as_client_run_remove (argv, argc);
	} else if (g_strcmp0 (command, "status") == 0) {
		return as_client_run_status (argv, argc);
	} else if (g_strcmp0 (command, "convert") == 0) {
		return as_client_run_convert (argv, argc);
	} else if (g_strcmp0 (command, "compare-versions") == 0) {
		return as_client_run_compare_versions (argv, argc);
	} else if (g_strcmp0 (command, "new-template") == 0) {
		return as_client_run_new_template (argv, argc);
	} else {
		/* TRANSLATORS: ascli has been run with unknown command. */
		ascli_print_stderr (_("Unknown command '%s'."), command);
		return 1;
	}
}

int
main (int argc, char ** argv)
{
	gint code = 0;

	/* bind locale */
	setlocale (LC_ALL, "");
	bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
	bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
	textdomain (GETTEXT_PACKAGE);

	/* run the application */
	code = as_client_run (argv, argc);

	return code;
}
