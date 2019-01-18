/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2015-2016 Matthias Klumpp <matthias@tenstral.net>
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

#include "ascli-actions-pkgmgr.h"

#include <config.h>
#include <glib/gi18n-lib.h>
#include <unistd.h>
#include <errno.h>

#include "ascli-utils.h"

/**
 * exec_pm_action:
 *
 * Run the native package manager to perform an action (install/remove) on
 * a set of packages.
 * The PM will replace the current process tree.
 */
static int
exec_pm_action (const gchar *action, gchar **pkgnames)
{
	int ret;
	const gchar *exe = NULL;
	guint i;
	g_auto(GStrv) cmd = NULL;

#ifdef APT_SUPPORT
	if (g_file_test ("/usr/bin/apt", G_FILE_TEST_EXISTS))
		exe = "/usr/bin/apt";
#endif
	if (exe == NULL) {
		if (g_file_test ("/usr/bin/pkcon", G_FILE_TEST_EXISTS)) {
			exe = "/usr/bin/pkcon";
		} else {
			g_printerr ("%s\n", _("No suitable package manager CLI found. Please make sure that e.g. \"pkcon\" (part of PackageKit) is available."));
			return 1;
		}
	}

	cmd = g_new0 (gchar*, 3 + g_strv_length (pkgnames) + 1);
	cmd[0] = g_strdup (exe);
	cmd[1] = g_strdup (action);
	for (i = 0; pkgnames[i] != NULL; i++) {
		cmd[2+i] = g_strdup (pkgnames[i]);
	}

	ret = execv (exe, cmd);
	if (ret != 0)
		ascli_print_stderr (_("Unable to spawn package manager: %s"), g_strerror (errno));
	return ret;
}

static int
ascli_get_component_pkgnames (const gchar *identifier, gchar ***pkgnames)
{
	g_autoptr(GError) error = NULL;
	g_autoptr(AsPool) dpool = NULL;
	g_autoptr(GPtrArray) result = NULL;
	AsComponent *cpt;

	if (identifier == NULL) {
		ascli_print_stderr (_("You need to specify a component-ID."));
		return 2;
	}

	dpool = as_pool_new ();
	as_pool_load (dpool, NULL, &error);
	if (error != NULL) {
		g_printerr ("%s\n", error->message);
		return 1;
	}

	result = as_pool_get_components_by_id (dpool, identifier);
	if (result->len == 0) {
		ascli_print_stderr (_("Unable to find component with ID '%s'!"), identifier);
		return 4;
	}

	/* FIXME: Ask user which component they want to install? */
	cpt = AS_COMPONENT (g_ptr_array_index (result, 0));

	/* we need a variable to take the pkgnames array */
	g_assert (pkgnames != NULL);

	*pkgnames = g_strdupv (as_component_get_pkgnames (cpt));
	if (*pkgnames == NULL) {
		/* TRANSLATORS: We found no distribution package or bundle to install to make this software available */
		ascli_print_stderr (_("Component '%s' has no installation candidate."), identifier);
		return 1;
	}

	return 0;
}

/**
 * ascli_install_component:
 *
 * Install a component matching the given ID.
 */
int
ascli_install_component (const gchar *identifier)
{
	g_auto(GStrv) pkgnames = NULL;
	gint exit_code = 0;

	exit_code = ascli_get_component_pkgnames (identifier, &pkgnames);
	if (exit_code != 0)
		return exit_code;

	exit_code = exec_pm_action ("install", pkgnames);
	return exit_code;

}

/**
 * ascli_remove_component:
 *
 * Remove a component matching the given ID.
 */
int
ascli_remove_component (const gchar *identifier)
{
	g_auto(GStrv) pkgnames = NULL;
	gint exit_code = 0;

	exit_code = ascli_get_component_pkgnames (identifier, &pkgnames);
	if (exit_code != 0)
		return exit_code;

	exit_code = exec_pm_action ("remove", pkgnames);
	return exit_code;

}
