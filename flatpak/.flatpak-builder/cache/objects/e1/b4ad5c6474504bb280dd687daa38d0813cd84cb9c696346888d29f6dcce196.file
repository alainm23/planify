/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- *
 *
 * This file is part of GtkSourceView
 *
 * Copyright (C) 1997, 1998, 1999, 2000 Free Software Foundation
 * Copyright (C) 2016 - Sébastien Wilmet <swilmet@gnome.org>
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

/* Handles all of the internationalization configuration options.
 * Author: Tom Tromey <tromey@creche.cygnus.com>
 */

#ifndef GTKSOURCEVIEW_18N_H
#define GTKSOURCEVIEW_18N_H 1

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <glib.h>

G_BEGIN_DECLS

#ifdef ENABLE_NLS
#    include <glib/gi18n-lib.h>
#    undef GD_
#    define GD_(Domain,String) _gtksourceview_dgettext (Domain, String)
#else
/* Stubs that do something close enough. */
#    undef textdomain
#    define textdomain(String) (String)
#    undef gettext
#    define gettext(String) (String)
#    undef dgettext
#    define dgettext(Domain,Message) (Message)
#    undef dcgettext
#    define dcgettext(Domain,Message,Type) (Message)
#    undef bindtextdomain
#    define bindtextdomain(Domain,Directory) (Domain)
#    undef bind_textdomain_codeset
#    define bind_textdomain_codeset(Domain,CodeSet) (Domain)
#    undef _
#    define _(String) (String)
#    undef N_
#    define N_(String) (String)
#    undef GD_
#    define GD_(Domain,String) (g_strdup (String))
#    undef C_
#    define C_(Context,String) (String)
#endif

/* NOTE: it returns duplicated string */
G_GNUC_INTERNAL
gchar *		_gtksourceview_dgettext		(const gchar *domain,
						 const gchar *msgid) G_GNUC_FORMAT(2);

G_END_DECLS

#endif /* GTKSOURCEVIEW_I18N_H */
