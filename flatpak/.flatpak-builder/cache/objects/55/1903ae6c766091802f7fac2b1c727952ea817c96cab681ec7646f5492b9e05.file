/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcebuffer.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2007 - Johannes Schmid <jhs@gnome.org>
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

#ifndef GTKSOURCEMARK_H
#define GTKSOURCEMARK_H

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

#define GTK_SOURCE_TYPE_MARK             (gtk_source_mark_get_type ())
#define GTK_SOURCE_MARK(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_MARK, GtkSourceMark))
#define GTK_SOURCE_MARK_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_MARK, GtkSourceMarkClass))
#define GTK_SOURCE_IS_MARK(obj)          (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_MARK))
#define GTK_SOURCE_IS_MARK_CLASS(klass)  (G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_MARK))
#define GTK_SOURCE_MARK_GET_CLASS(obj)   (G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_MARK, GtkSourceMarkClass))

typedef struct _GtkSourceMarkClass GtkSourceMarkClass;

typedef struct _GtkSourceMarkPrivate GtkSourceMarkPrivate;

struct _GtkSourceMark
{
	GtkTextMark parent_instance;

	GtkSourceMarkPrivate *priv;
};

struct _GtkSourceMarkClass
{
	GtkTextMarkClass parent_class;

	/* Padding for future expansion */
	void (*_gtk_source_reserved1) (void);
	void (*_gtk_source_reserved2) (void);
};

GTK_SOURCE_AVAILABLE_IN_ALL
GType		 gtk_source_mark_get_type (void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_ALL
GtkSourceMark   *gtk_source_mark_new		(const gchar	*name,
						 const gchar	*category);

GTK_SOURCE_AVAILABLE_IN_ALL
const gchar	*gtk_source_mark_get_category	(GtkSourceMark	*mark);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkSourceMark	*gtk_source_mark_next		(GtkSourceMark	*mark,
						 const gchar	*category);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkSourceMark	*gtk_source_mark_prev		(GtkSourceMark	*mark,
						 const gchar	*category);

G_END_DECLS

#endif /* GTKSOURCEMARK_H */
