/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcegutterrenderertext.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2010 - Jesse van den Kieboom
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

#ifndef GTK_SOURCE_GUTTER_RENDERER_TEXT_H
#define GTK_SOURCE_GUTTER_RENDERER_TEXT_H

#if !defined (GTK_SOURCE_H_INSIDE) && !defined (GTK_SOURCE_COMPILATION)
#  if defined (__GNUC__)
#    warning "Only <gtksourceview/gtksource.h> can be included directly."
#  elif defined (G_OS_WIN32)
#    pragma message("Only <gtksourceview/gtksource.h> can be included directly.")
#  endif
#endif

#include <gtksourceview/gtksourcetypes.h>
#include <gtksourceview/gtksourcegutterrenderer.h>

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_GUTTER_RENDERER_TEXT		(gtk_source_gutter_renderer_text_get_type ())
#define GTK_SOURCE_GUTTER_RENDERER_TEXT(obj)		(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_GUTTER_RENDERER_TEXT, GtkSourceGutterRendererText))
#define GTK_SOURCE_GUTTER_RENDERER_TEXT_CONST(obj)	(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_GUTTER_RENDERER_TEXT, GtkSourceGutterRendererText const))
#define GTK_SOURCE_GUTTER_RENDERER_TEXT_CLASS(klass)	(G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_GUTTER_RENDERER_TEXT, GtkSourceGutterRendererTextClass))
#define GTK_SOURCE_IS_GUTTER_RENDERER_TEXT(obj)		(G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_GUTTER_RENDERER_TEXT))
#define GTK_SOURCE_IS_GUTTER_RENDERER_TEXT_CLASS(klass)	(G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_GUTTER_RENDERER_TEXT))
#define GTK_SOURCE_GUTTER_RENDERER_TEXT_GET_CLASS(obj)	(G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_GUTTER_RENDERER_TEXT, GtkSourceGutterRendererTextClass))

typedef struct _GtkSourceGutterRendererTextClass	GtkSourceGutterRendererTextClass;
typedef struct _GtkSourceGutterRendererTextPrivate	GtkSourceGutterRendererTextPrivate;

struct _GtkSourceGutterRendererText
{
	/*< private >*/
	GtkSourceGutterRenderer parent;

	GtkSourceGutterRendererTextPrivate *priv;

	/*< public >*/
};

struct _GtkSourceGutterRendererTextClass
{
	/*< private >*/
	GtkSourceGutterRendererClass parent_class;

	/*< public >*/
};

GTK_SOURCE_AVAILABLE_IN_ALL
GType gtk_source_gutter_renderer_text_get_type (void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_ALL
GtkSourceGutterRenderer *gtk_source_gutter_renderer_text_new (void);

GTK_SOURCE_AVAILABLE_IN_ALL
void gtk_source_gutter_renderer_text_set_markup (GtkSourceGutterRendererText *renderer,
                                                 const gchar                 *markup,
                                                 gint                         length);

GTK_SOURCE_AVAILABLE_IN_ALL
void gtk_source_gutter_renderer_text_set_text (GtkSourceGutterRendererText *renderer,
                                               const gchar                 *text,
                                               gint                         length);

GTK_SOURCE_AVAILABLE_IN_ALL
void gtk_source_gutter_renderer_text_measure (GtkSourceGutterRendererText *renderer,
                                              const gchar                 *text,
                                              gint                        *width,
                                              gint                        *height);

GTK_SOURCE_AVAILABLE_IN_ALL
void gtk_source_gutter_renderer_text_measure_markup (GtkSourceGutterRendererText *renderer,
                                                     const gchar                 *markup,
                                                     gint                        *width,
                                                     gint                        *height);

G_END_DECLS

#endif /* GTK_SOURCE_GUTTER_RENDERER_TEXT_H */
