/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecompletion.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2007 - 2009 Jesús Barbero Rodríguez <chuchiperriman@gmail.com>
 * Copyright (C) 2009 - Jesse van den Kieboom <jessevdk@gnome.org>
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

#ifndef GTK_SOURCE_COMPLETION_H
#define GTK_SOURCE_COMPLETION_H

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

/*
 * Type checking and casting macros
 */
#define GTK_SOURCE_TYPE_COMPLETION              (gtk_source_completion_get_type())
#define GTK_SOURCE_COMPLETION(obj)              (G_TYPE_CHECK_INSTANCE_CAST((obj), GTK_SOURCE_TYPE_COMPLETION, GtkSourceCompletion))
#define GTK_SOURCE_COMPLETION_CLASS(klass)      (G_TYPE_CHECK_CLASS_CAST((klass), GTK_SOURCE_TYPE_COMPLETION, GtkSourceCompletionClass))
#define GTK_SOURCE_IS_COMPLETION(obj)           (G_TYPE_CHECK_INSTANCE_TYPE((obj), GTK_SOURCE_TYPE_COMPLETION))
#define GTK_SOURCE_IS_COMPLETION_CLASS(klass)   (G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_COMPLETION))
#define GTK_SOURCE_COMPLETION_GET_CLASS(obj)    (G_TYPE_INSTANCE_GET_CLASS((obj), GTK_SOURCE_TYPE_COMPLETION, GtkSourceCompletionClass))

/**
 * GTK_SOURCE_COMPLETION_ERROR:
 *
 * Error domain for the completion. Errors in this domain will be from the
 * #GtkSourceCompletionError enumeration. See #GError for more information on
 * error domains.
 */
#define GTK_SOURCE_COMPLETION_ERROR		(gtk_source_completion_error_quark ())

typedef struct _GtkSourceCompletionPrivate GtkSourceCompletionPrivate;
typedef struct _GtkSourceCompletionClass GtkSourceCompletionClass;

/**
 * GtkSourceCompletionError:
 * @GTK_SOURCE_COMPLETION_ERROR_ALREADY_BOUND: The #GtkSourceCompletionProvider
 * is already bound to the #GtkSourceCompletion object.
 * @GTK_SOURCE_COMPLETION_ERROR_NOT_BOUND: The #GtkSourceCompletionProvider is
 * not bound to the #GtkSourceCompletion object.
 *
 * An error code used with %GTK_SOURCE_COMPLETION_ERROR in a #GError returned
 * from a completion-related function.
 */
typedef enum _GtkSourceCompletionError
{
	GTK_SOURCE_COMPLETION_ERROR_ALREADY_BOUND = 0,
	GTK_SOURCE_COMPLETION_ERROR_NOT_BOUND
} GtkSourceCompletionError;

struct _GtkSourceCompletion
{
	GObject parent_instance;

	GtkSourceCompletionPrivate *priv;
};

struct _GtkSourceCompletionClass
{
	GObjectClass parent_class;

	gboolean 	(* proposal_activated)		(GtkSourceCompletion         *completion,
	                                                 GtkSourceCompletionProvider *provider,
							 GtkSourceCompletionProposal *proposal);
	void 		(* show)			(GtkSourceCompletion         *completion);
	void		(* hide)			(GtkSourceCompletion         *completion);
	void		(* populate_context)		(GtkSourceCompletion         *completion,
							 GtkSourceCompletionContext  *context);

	/* Actions */
	void		(* move_cursor)			(GtkSourceCompletion         *completion,
							 GtkScrollStep                step,
							 gint                         num);
	void		(* move_page)			(GtkSourceCompletion         *completion,
							 GtkScrollStep                step,
							 gint                         num);
	void		(* activate_proposal)		(GtkSourceCompletion         *completion);
};

GTK_SOURCE_AVAILABLE_IN_ALL
GType		 gtk_source_completion_get_type			(void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_ALL
GQuark		 gtk_source_completion_error_quark		(void);

GTK_SOURCE_AVAILABLE_IN_ALL
gboolean	 gtk_source_completion_add_provider		(GtkSourceCompletion           *completion,
								 GtkSourceCompletionProvider   *provider,
								 GError                       **error);

GTK_SOURCE_AVAILABLE_IN_ALL
gboolean	 gtk_source_completion_remove_provider		(GtkSourceCompletion           *completion,
								 GtkSourceCompletionProvider   *provider,
								 GError                       **error);

GTK_SOURCE_AVAILABLE_IN_ALL
GList		*gtk_source_completion_get_providers		(GtkSourceCompletion           *completion);

GTK_SOURCE_AVAILABLE_IN_ALL
gboolean	 gtk_source_completion_show			(GtkSourceCompletion           *completion,
								 GList                         *providers,
								 GtkSourceCompletionContext    *context);

GTK_SOURCE_AVAILABLE_IN_ALL
void		 gtk_source_completion_hide			(GtkSourceCompletion           *completion);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkSourceCompletionInfo *
		 gtk_source_completion_get_info_window		(GtkSourceCompletion           *completion);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkSourceView	*gtk_source_completion_get_view			(GtkSourceCompletion	       *completion);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkSourceCompletionContext *
		 gtk_source_completion_create_context		(GtkSourceCompletion           *completion,
		 						 GtkTextIter                   *position);

GTK_SOURCE_DEPRECATED_IN_3_8_FOR (gtk_source_completion_provider_get_start_iter)
void		 gtk_source_completion_move_window		(GtkSourceCompletion           *completion,
								 GtkTextIter                   *iter);

GTK_SOURCE_AVAILABLE_IN_ALL
void		 gtk_source_completion_block_interactive	(GtkSourceCompletion           *completion);

GTK_SOURCE_AVAILABLE_IN_ALL
void		 gtk_source_completion_unblock_interactive	(GtkSourceCompletion           *completion);

G_GNUC_INTERNAL
void		 _gtk_source_completion_add_proposals		(GtkSourceCompletion           *completion,
								 GtkSourceCompletionContext    *context,
								 GtkSourceCompletionProvider   *provider,
								 GList                         *proposals,
								 gboolean                       finished);
G_END_DECLS

#endif /* GTK_SOURCE_COMPLETION_H */
