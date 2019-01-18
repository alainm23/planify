/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 *
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2014 - Christian Hergert
 * Copyright (C) 2014 - Ignacio Casal Quinteiro
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
 * You should have received a copy of the GNU Lesser General Public License
 * along with GtkSourceView. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef GTK_SOURCE_STYLE_SCHEME_CHOOSER_WIDGET_H
#define GTK_SOURCE_STYLE_SCHEME_CHOOSER_WIDGET_H

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

#define GTK_SOURCE_TYPE_STYLE_SCHEME_CHOOSER_WIDGET            (gtk_source_style_scheme_chooser_widget_get_type())
#define GTK_SOURCE_STYLE_SCHEME_CHOOSER_WIDGET(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_STYLE_SCHEME_CHOOSER_WIDGET, GtkSourceStyleSchemeChooserWidget))
#define GTK_SOURCE_STYLE_SCHEME_CHOOSER_WIDGET_CONST(obj)      (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_STYLE_SCHEME_CHOOSER_WIDGET, GtkSourceStyleSchemeChooserWidget const))
#define GTK_SOURCE_STYLE_SCHEME_CHOOSER_WIDGET_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass),  GTK_SOURCE_TYPE_STYLE_SCHEME_CHOOSER_WIDGET, GtkSourceStyleSchemeChooserWidgetClass))
#define GTK_SOURCE_IS_STYLE_SCHEME_CHOOSER_WIDGET(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_STYLE_SCHEME_CHOOSER_WIDGET))
#define GTK_SOURCE_IS_STYLE_SCHEME_CHOOSER_WIDGET_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass),  GTK_SOURCE_TYPE_STYLE_SCHEME_CHOOSER_WIDGET))
#define GTK_SOURCE_STYLE_SCHEME_CHOOSER_WIDGET_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj),  GTK_SOURCE_TYPE_STYLE_SCHEME_CHOOSER_WIDGET, GtkSourceStyleSchemeChooserWidgetClass))

typedef struct _GtkSourceStyleSchemeChooserWidgetClass GtkSourceStyleSchemeChooserWidgetClass;

struct _GtkSourceStyleSchemeChooserWidget
{
	GtkBin parent;
};

struct _GtkSourceStyleSchemeChooserWidgetClass
{
	GtkBinClass parent;
};

GTK_SOURCE_AVAILABLE_IN_3_16
GType        gtk_source_style_scheme_chooser_widget_get_type              (void);

GTK_SOURCE_AVAILABLE_IN_3_16
GtkWidget   *gtk_source_style_scheme_chooser_widget_new                   (void);

G_END_DECLS

#endif /* GTK_SOURCE_STYLE_SCHEME_CHOOSER_WIDGET_H */
