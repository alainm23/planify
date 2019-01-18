/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcelanguage.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2003 - Paolo Maggi <paolo.maggi@polito.it>
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

#ifndef GTK_SOURCE_LANGUAGE_H
#define GTK_SOURCE_LANGUAGE_H

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

#define GTK_SOURCE_TYPE_LANGUAGE		(gtk_source_language_get_type ())
#define GTK_SOURCE_LANGUAGE(obj)		(G_TYPE_CHECK_INSTANCE_CAST((obj), GTK_SOURCE_TYPE_LANGUAGE, GtkSourceLanguage))
#define GTK_SOURCE_LANGUAGE_CLASS(klass)	(G_TYPE_CHECK_CLASS_CAST((klass), GTK_SOURCE_TYPE_LANGUAGE, GtkSourceLanguageClass))
#define GTK_SOURCE_IS_LANGUAGE(obj)		(G_TYPE_CHECK_INSTANCE_TYPE((obj), GTK_SOURCE_TYPE_LANGUAGE))
#define GTK_SOURCE_IS_LANGUAGE_CLASS(klass)	(G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_LANGUAGE))
#define GTK_SOURCE_LANGUAGE_GET_CLASS(obj)      (G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_LANGUAGE, GtkSourceLanguageClass))


typedef struct _GtkSourceLanguageClass		GtkSourceLanguageClass;
typedef struct _GtkSourceLanguagePrivate	GtkSourceLanguagePrivate;

struct _GtkSourceLanguage
{
	GObject parent_instance;

	GtkSourceLanguagePrivate *priv;
};

struct _GtkSourceLanguageClass
{
	GObjectClass parent_class;

	/* Padding for future expansion */
	void (*_gtk_source_reserved1) (void);
	void (*_gtk_source_reserved2) (void);
};

GTK_SOURCE_AVAILABLE_IN_ALL
GType		  gtk_source_language_get_type 		(void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_ALL
const gchar	 *gtk_source_language_get_id		(GtkSourceLanguage *language);

GTK_SOURCE_AVAILABLE_IN_ALL
const gchar	 *gtk_source_language_get_name		(GtkSourceLanguage *language);

GTK_SOURCE_AVAILABLE_IN_ALL
const gchar	 *gtk_source_language_get_section	(GtkSourceLanguage *language);

GTK_SOURCE_AVAILABLE_IN_ALL
gboolean	  gtk_source_language_get_hidden 	(GtkSourceLanguage *language);

GTK_SOURCE_AVAILABLE_IN_ALL
const gchar	 *gtk_source_language_get_metadata	(GtkSourceLanguage *language,
							 const gchar       *name);

GTK_SOURCE_AVAILABLE_IN_ALL
gchar		**gtk_source_language_get_mime_types	(GtkSourceLanguage *language);

GTK_SOURCE_AVAILABLE_IN_ALL
gchar		**gtk_source_language_get_globs		(GtkSourceLanguage *language);

GTK_SOURCE_AVAILABLE_IN_ALL
gchar		**gtk_source_language_get_style_ids 	(GtkSourceLanguage *language);

GTK_SOURCE_AVAILABLE_IN_ALL
const gchar	*gtk_source_language_get_style_name	(GtkSourceLanguage *language,
							 const gchar       *style_id);

GTK_SOURCE_AVAILABLE_IN_3_4
const gchar	*gtk_source_language_get_style_fallback	(GtkSourceLanguage *language,
							 const gchar       *style_id);

G_END_DECLS

#endif /* GTK_SOURCE_LANGUAGE_H */

