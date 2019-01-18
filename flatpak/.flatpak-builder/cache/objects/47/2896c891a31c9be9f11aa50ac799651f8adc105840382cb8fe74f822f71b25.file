/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- *
 *
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2016 - Sébastien Wilmet <swilmet@gnome.org>
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

/* Constructor to init i18n.
 * Destructor to release remaining allocated memory (useful when using
 * memory-debugging tools).
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#ifdef ENABLE_NLS
#include <glib/gi18n-lib.h>
#endif

#include "gconstructor.h"
#include "gtksourcelanguagemanager.h"
#include "gtksourcestyleschememanager.h"

#ifdef G_OS_WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>

static HMODULE gtksourceview_dll;
#endif

#ifdef ENABLE_NLS

#  ifdef OS_OSX
#  include <Cocoa/Cocoa.h>

static gchar *
dirs_os_x_get_bundle_resource_dir (void)
{
	NSAutoreleasePool *pool;
	gchar *str = NULL;
	NSString *path;

	pool = [[NSAutoreleasePool alloc] init];

	if ([[NSBundle mainBundle] bundleIdentifier] == nil)
	{
		[pool release];
		return NULL;
	}

	path = [[NSBundle mainBundle] resourcePath];

	if (!path)
	{
		[pool release];
		return NULL;
	}

	str = g_strdup ([path UTF8String]);
	[pool release];
	return str;
}

static gchar *
dirs_os_x_get_locale_dir (void)
{
	gchar *res_dir;
	gchar *ret;

	res_dir = dirs_os_x_get_bundle_resource_dir ();

	if (res_dir == NULL)
	{
		ret = g_build_filename (DATADIR, "locale", NULL);
	}
	else
	{
		ret = g_build_filename (res_dir, "share", "locale", NULL);
		g_free (res_dir);
	}

	return ret;
}
#  endif /* OS_OSX */

static gchar *
get_locale_dir (void)
{
	gchar *locale_dir;

#  if defined (G_OS_WIN32)
	gchar *win32_dir;

	win32_dir = g_win32_get_package_installation_directory_of_module (gtksourceview_dll);

	locale_dir = g_build_filename (win32_dir, "share", "locale", NULL);

	g_free (win32_dir);
#  elif defined (OS_OSX)
	locale_dir = dirs_os_x_get_locale_dir ();
#  else
	locale_dir = g_build_filename (DATADIR, "locale", NULL);
#  endif

	return locale_dir;
}
#endif /* ENABLE_NLS */

static void
gtksourceview_init (void)
{
#ifdef ENABLE_NLS
	gchar *locale_dir;

	locale_dir = get_locale_dir ();
	bindtextdomain (GETTEXT_PACKAGE, locale_dir);
	g_free (locale_dir);

	bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
#endif /* ENABLE_NLS */
}

static void
gtksourceview_shutdown (void)
{
	GtkSourceLanguageManager *language_manager;
	GtkSourceStyleSchemeManager *style_scheme_manager;

	language_manager = _gtk_source_language_manager_peek_default ();
	g_clear_object (&language_manager);

	style_scheme_manager = _gtk_source_style_scheme_manager_peek_default ();
	g_clear_object (&style_scheme_manager);
}

#if defined (G_OS_WIN32)

BOOL WINAPI DllMain (HINSTANCE hinstDLL,
		     DWORD     fdwReason,
		     LPVOID    lpvReserved);

BOOL WINAPI
DllMain (HINSTANCE hinstDLL,
	 DWORD     fdwReason,
	 LPVOID    lpvReserved)
{
	switch (fdwReason)
	{
		case DLL_PROCESS_ATTACH:
			gtksourceview_dll = hinstDLL;
			gtksourceview_init ();
			break;

		case DLL_PROCESS_DETACH:
			gtksourceview_shutdown ();
			break;

		default:
			/* do nothing */
			break;
	}

	return TRUE;
}

#elif defined (G_HAS_CONSTRUCTORS)

#  ifdef G_DEFINE_CONSTRUCTOR_NEEDS_PRAGMA
#    pragma G_DEFINE_CONSTRUCTOR_PRAGMA_ARGS(gtksourceview_constructor)
#  endif
G_DEFINE_CONSTRUCTOR (gtksourceview_constructor)

static void
gtksourceview_constructor (void)
{
	gtksourceview_init ();
}

#  ifdef G_DEFINE_DESTRUCTOR_NEEDS_PRAGMA
#    pragma G_DEFINE_DESTRUCTOR_PRAGMA_ARGS(gtksourceview_destructor)
#  endif
G_DEFINE_DESTRUCTOR (gtksourceview_destructor)

static void
gtksourceview_destructor (void)
{
	gtksourceview_shutdown ();
}

#else
#  error Your platform/compiler is missing constructor support
#endif
