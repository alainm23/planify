/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcetag.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2015 - Université Catholique de Louvain
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
 *
 * Author: Sébastien Wilmet
 */

#ifndef GTK_SOURCE_TAG_H
#define GTK_SOURCE_TAG_H

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

#define GTK_SOURCE_TYPE_TAG (gtk_source_tag_get_type ())

GTK_SOURCE_AVAILABLE_IN_3_20
G_DECLARE_DERIVABLE_TYPE (GtkSourceTag, gtk_source_tag,
			  GTK_SOURCE, TAG,
			  GtkTextTag)

struct _GtkSourceTagClass
{
	GtkTextTagClass parent_class;

	gpointer padding[10];
};

GTK_SOURCE_AVAILABLE_IN_3_20
GtkTextTag *	gtk_source_tag_new		(const gchar *name);

G_END_DECLS

#endif /* GTK_SOURCE_TAG_H */
