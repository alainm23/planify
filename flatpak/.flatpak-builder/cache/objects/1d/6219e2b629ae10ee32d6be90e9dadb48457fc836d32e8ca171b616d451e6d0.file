/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcestylescheme.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2003 - Paolo Maggi <paolo.maggi@polito.it>
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

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef GTK_SOURCE_STYLE_SCHEME_H
#define GTK_SOURCE_STYLE_SCHEME_H

#if !defined (GTK_SOURCE_H_INSIDE) && !defined (GTK_SOURCE_COMPILATION)
#  if defined (__GNUC__)
#    warning "Only <gtksourceview/gtksource.h> can be included directly."
#  elif defined (G_OS_WIN32)
#    pragma message("Only <gtksourceview/gtksource.h> can be included directly.")
#  endif
#endif

#include <gtk/gtk.h>
#include <gtksourceview/gtksourcetypes.h>

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_STYLE_SCHEME             (gtk_source_style_scheme_get_type ())
#define GTK_SOURCE_STYLE_SCHEME(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_STYLE_SCHEME, GtkSourceStyleScheme))
#define GTK_SOURCE_STYLE_SCHEME_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_STYLE_SCHEME, GtkSourceStyleSchemeClass))
#define GTK_SOURCE_IS_STYLE_SCHEME(obj)          (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_STYLE_SCHEME))
#define GTK_SOURCE_IS_STYLE_SCHEME_CLASS(klass)  (G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_STYLE_SCHEME))
#define GTK_SOURCE_STYLE_SCHEME_GET_CLASS(obj)   (G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_STYLE_SCHEME, GtkSourceStyleSchemeClass))

typedef struct _GtkSourceStyleSchemePrivate      GtkSourceStyleSchemePrivate;
typedef struct _GtkSourceStyleSchemeClass        GtkSourceStyleSchemeClass;

struct _GtkSourceStyleScheme
{
	GObject base;
	GtkSourceStyleSchemePrivate *priv;
};

struct _GtkSourceStyleSchemeClass
{
	GObjectClass base_class;

	/* Padding for future expansion */
	void (*_gtk_source_reserved1) (void);
	void (*_gtk_source_reserved2) (void);
};

GTK_SOURCE_AVAILABLE_IN_ALL
GType			 gtk_source_style_scheme_get_type			(void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_ALL
const gchar             *gtk_source_style_scheme_get_id				(GtkSourceStyleScheme *scheme);

GTK_SOURCE_AVAILABLE_IN_ALL
const gchar             *gtk_source_style_scheme_get_name			(GtkSourceStyleScheme *scheme);

GTK_SOURCE_AVAILABLE_IN_ALL
const gchar             *gtk_source_style_scheme_get_description		(GtkSourceStyleScheme *scheme);

GTK_SOURCE_AVAILABLE_IN_ALL
const gchar * const *	 gtk_source_style_scheme_get_authors			(GtkSourceStyleScheme *scheme);

GTK_SOURCE_AVAILABLE_IN_ALL
const gchar             *gtk_source_style_scheme_get_filename			(GtkSourceStyleScheme *scheme);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkSourceStyle		*gtk_source_style_scheme_get_style			(GtkSourceStyleScheme *scheme,
										 const gchar          *style_id);

G_GNUC_INTERNAL
GtkSourceStyleScheme	*_gtk_source_style_scheme_new_from_file			(const gchar          *filename);

G_GNUC_INTERNAL
GtkSourceStyleScheme	*_gtk_source_style_scheme_get_default			(void);

G_GNUC_INTERNAL
const gchar		*_gtk_source_style_scheme_get_parent_id			(GtkSourceStyleScheme *scheme);

G_GNUC_INTERNAL
void			 _gtk_source_style_scheme_set_parent			(GtkSourceStyleScheme *scheme,
										 GtkSourceStyleScheme *parent_scheme);

G_GNUC_INTERNAL
void			 _gtk_source_style_scheme_apply				(GtkSourceStyleScheme *scheme,
										 GtkSourceView        *view);

G_GNUC_INTERNAL
void			 _gtk_source_style_scheme_unapply			(GtkSourceStyleScheme *scheme,
										 GtkSourceView        *view);

G_GNUC_INTERNAL
GtkSourceStyle		*_gtk_source_style_scheme_get_matching_brackets_style	(GtkSourceStyleScheme *scheme);

G_GNUC_INTERNAL
GtkSourceStyle		*_gtk_source_style_scheme_get_right_margin_style	(GtkSourceStyleScheme *scheme);

G_GNUC_INTERNAL
GtkSourceStyle          *_gtk_source_style_scheme_get_draw_spaces_style		(GtkSourceStyleScheme *scheme);

G_GNUC_INTERNAL
gboolean		 _gtk_source_style_scheme_get_current_line_color	(GtkSourceStyleScheme *scheme,
										 GdkRGBA              *color);

G_GNUC_INTERNAL
gboolean		 _gtk_source_style_scheme_get_background_pattern_color	(GtkSourceStyleScheme *scheme,
										 GdkRGBA              *color);

G_END_DECLS

#endif  /* GTK_SOURCE_STYLE_SCHEME_H */
