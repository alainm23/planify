/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcesearchcontext.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2013, 2016 - Sébastien Wilmet <swilmet@gnome.org>
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

#ifndef GTK_SOURCE_SEARCH_CONTEXT_H
#define GTK_SOURCE_SEARCH_CONTEXT_H

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

#define GTK_SOURCE_TYPE_SEARCH_CONTEXT             (gtk_source_search_context_get_type ())
#define GTK_SOURCE_SEARCH_CONTEXT(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_SEARCH_CONTEXT, GtkSourceSearchContext))
#define GTK_SOURCE_SEARCH_CONTEXT_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_SEARCH_CONTEXT, GtkSourceSearchContextClass))
#define GTK_SOURCE_IS_SEARCH_CONTEXT(obj)          (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_SEARCH_CONTEXT))
#define GTK_SOURCE_IS_SEARCH_CONTEXT_CLASS(klass)  (G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_SEARCH_CONTEXT))
#define GTK_SOURCE_SEARCH_CONTEXT_GET_CLASS(obj)   (G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_SEARCH_CONTEXT, GtkSourceSearchContextClass))

typedef struct _GtkSourceSearchContextClass    GtkSourceSearchContextClass;
typedef struct _GtkSourceSearchContextPrivate  GtkSourceSearchContextPrivate;

struct _GtkSourceSearchContext
{
	GObject parent;

	GtkSourceSearchContextPrivate *priv;
};

struct _GtkSourceSearchContextClass
{
	GObjectClass parent_class;

	gpointer padding[10];
};

GTK_SOURCE_AVAILABLE_IN_3_10
GType			 gtk_source_search_context_get_type			(void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_3_10
GtkSourceSearchContext	*gtk_source_search_context_new				(GtkSourceBuffer	 *buffer,
										 GtkSourceSearchSettings *settings);

GTK_SOURCE_AVAILABLE_IN_3_10
GtkSourceBuffer		*gtk_source_search_context_get_buffer			(GtkSourceSearchContext  *search);

GTK_SOURCE_AVAILABLE_IN_3_10
GtkSourceSearchSettings	*gtk_source_search_context_get_settings			(GtkSourceSearchContext	 *search);

GTK_SOURCE_DEPRECATED_IN_3_24_FOR (gtk_source_search_context_new)
void			 gtk_source_search_context_set_settings			(GtkSourceSearchContext  *search,
										 GtkSourceSearchSettings *settings);

GTK_SOURCE_AVAILABLE_IN_3_10
gboolean		 gtk_source_search_context_get_highlight		(GtkSourceSearchContext  *search);

GTK_SOURCE_AVAILABLE_IN_3_10
void			 gtk_source_search_context_set_highlight		(GtkSourceSearchContext  *search,
										 gboolean                 highlight);

GTK_SOURCE_AVAILABLE_IN_3_16
GtkSourceStyle		*gtk_source_search_context_get_match_style		(GtkSourceSearchContext  *search);

GTK_SOURCE_AVAILABLE_IN_3_16
void			 gtk_source_search_context_set_match_style		(GtkSourceSearchContext  *search,
										 GtkSourceStyle          *match_style);

GTK_SOURCE_AVAILABLE_IN_3_10
GError			*gtk_source_search_context_get_regex_error		(GtkSourceSearchContext	 *search);

GTK_SOURCE_AVAILABLE_IN_3_10
gint			 gtk_source_search_context_get_occurrences_count	(GtkSourceSearchContext	 *search);

GTK_SOURCE_AVAILABLE_IN_3_10
gint			 gtk_source_search_context_get_occurrence_position	(GtkSourceSearchContext	 *search,
										 const GtkTextIter	 *match_start,
										 const GtkTextIter	 *match_end);

GTK_SOURCE_DEPRECATED_IN_3_22_FOR (gtk_source_search_context_forward2)
gboolean		 gtk_source_search_context_forward			(GtkSourceSearchContext	 *search,
										 const GtkTextIter	 *iter,
										 GtkTextIter		 *match_start,
										 GtkTextIter		 *match_end);

GTK_SOURCE_AVAILABLE_IN_3_22
gboolean		 gtk_source_search_context_forward2			(GtkSourceSearchContext *search,
										 const GtkTextIter      *iter,
										 GtkTextIter            *match_start,
										 GtkTextIter            *match_end,
										 gboolean               *has_wrapped_around);

GTK_SOURCE_AVAILABLE_IN_3_10
void			 gtk_source_search_context_forward_async		(GtkSourceSearchContext	 *search,
										 const GtkTextIter	 *iter,
										 GCancellable		 *cancellable,
										 GAsyncReadyCallback	  callback,
										 gpointer		  user_data);

GTK_SOURCE_DEPRECATED_IN_3_22_FOR (gtk_source_search_context_forward_finish2)
gboolean		 gtk_source_search_context_forward_finish		(GtkSourceSearchContext	 *search,
										 GAsyncResult		 *result,
										 GtkTextIter		 *match_start,
										 GtkTextIter		 *match_end,
										 GError		        **error);

GTK_SOURCE_AVAILABLE_IN_3_22
gboolean		 gtk_source_search_context_forward_finish2		(GtkSourceSearchContext  *search,
										 GAsyncResult            *result,
										 GtkTextIter             *match_start,
										 GtkTextIter             *match_end,
										 gboolean                *has_wrapped_around,
										 GError                 **error);

GTK_SOURCE_DEPRECATED_IN_3_22_FOR (gtk_source_search_context_backward2)
gboolean		 gtk_source_search_context_backward			(GtkSourceSearchContext	 *search,
										 const GtkTextIter	 *iter,
										 GtkTextIter		 *match_start,
										 GtkTextIter		 *match_end);

GTK_SOURCE_AVAILABLE_IN_3_22
gboolean		 gtk_source_search_context_backward2			(GtkSourceSearchContext *search,
										 const GtkTextIter      *iter,
										 GtkTextIter            *match_start,
										 GtkTextIter            *match_end,
										 gboolean               *has_wrapped_around);

GTK_SOURCE_AVAILABLE_IN_3_10
void			 gtk_source_search_context_backward_async		(GtkSourceSearchContext	 *search,
										 const GtkTextIter	 *iter,
										 GCancellable		 *cancellable,
										 GAsyncReadyCallback	  callback,
										 gpointer		  user_data);

GTK_SOURCE_DEPRECATED_IN_3_22_FOR (gtk_source_search_context_backward_finish2)
gboolean		 gtk_source_search_context_backward_finish		(GtkSourceSearchContext	 *search,
										 GAsyncResult		 *result,
										 GtkTextIter		 *match_start,
										 GtkTextIter		 *match_end,
										 GError		        **error);

GTK_SOURCE_AVAILABLE_IN_3_22
gboolean		 gtk_source_search_context_backward_finish2		(GtkSourceSearchContext  *search,
										 GAsyncResult            *result,
										 GtkTextIter             *match_start,
										 GtkTextIter             *match_end,
										 gboolean                *has_wrapped_around,
										 GError                 **error);

GTK_SOURCE_DEPRECATED_IN_3_22_FOR (gtk_source_search_context_replace2)
gboolean		 gtk_source_search_context_replace			(GtkSourceSearchContext	 *search,
										 const GtkTextIter	 *match_start,
										 const GtkTextIter	 *match_end,
										 const gchar		 *replace,
										 gint			  replace_length,
										 GError			**error);

GTK_SOURCE_AVAILABLE_IN_3_22
gboolean		 gtk_source_search_context_replace2			(GtkSourceSearchContext  *search,
										 GtkTextIter             *match_start,
										 GtkTextIter             *match_end,
										 const gchar             *replace,
										 gint                     replace_length,
										 GError                 **error);

GTK_SOURCE_AVAILABLE_IN_3_10
guint			 gtk_source_search_context_replace_all			(GtkSourceSearchContext	 *search,
										 const gchar		 *replace,
										 gint			  replace_length,
										 GError			**error);

G_GNUC_INTERNAL
void			 _gtk_source_search_context_update_highlight		(GtkSourceSearchContext	 *search,
										 const GtkTextIter	 *start,
										 const GtkTextIter	 *end,
										 gboolean		  synchronous);

G_END_DECLS

#endif /* GTK_SOURCE_SEARCH_CONTEXT_H */
