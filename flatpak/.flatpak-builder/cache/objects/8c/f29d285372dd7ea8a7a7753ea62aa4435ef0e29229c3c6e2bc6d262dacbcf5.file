/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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
 */

#include "evolution-data-server-config.h"

#include <glib.h>

#include "libedataserver/libedataserver.h"
#include "libedataserver/libedataserver-private.h"

#include "libedataserverui-private.h"

/*
 * _libedataserverui_load_modules:
 *
 * Usually called in a GObject::constructed() method to ensure
 * the modules from the UI module directories are loaded.
 *
 * Since: 3.30
 **/
void
_libedataserverui_load_modules (void)
{
	static gboolean modules_loaded = FALSE;

	/* Load modules only once. */
	if (!modules_loaded) {
		GList *module_types;

		modules_loaded = TRUE;

		module_types = e_module_load_all_in_directory (E_DATA_SERVER_UIMODULEDIR);
		g_list_free_full (module_types, (GDestroyNotify) g_type_module_unuse);
	}
}
