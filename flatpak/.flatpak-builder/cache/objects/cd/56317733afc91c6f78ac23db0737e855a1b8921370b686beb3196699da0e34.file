/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecompletioncontext.h
 * This file is part of GtkSourceView
 *
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

#ifndef GTK_SOURCE_COMPLETION_CONTEXT_H
#define GTK_SOURCE_COMPLETION_CONTEXT_H

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

#define GTK_SOURCE_TYPE_COMPLETION_CONTEXT		(gtk_source_completion_context_get_type ())
#define GTK_SOURCE_COMPLETION_CONTEXT(obj)		(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_COMPLETION_CONTEXT, GtkSourceCompletionContext))
#define GTK_SOURCE_COMPLETION_CONTEXT_CLASS(klass)	(G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_COMPLETION_CONTEXT, GtkSourceCompletionContextClass))
#define GTK_SOURCE_IS_COMPLETION_CONTEXT(obj)		(G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_COMPLETION_CONTEXT))
#define GTK_SOURCE_IS_COMPLETION_CONTEXT_CLASS(klass)	(G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_COMPLETION_CONTEXT))
#define GTK_SOURCE_COMPLETION_CONTEXT_GET_CLASS(obj)	(G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_COMPLETION_CONTEXT, GtkSourceCompletionContextClass))

typedef struct _GtkSourceCompletionContextClass		GtkSourceCompletionContextClass;
typedef struct _GtkSourceCompletionContextPrivate	GtkSourceCompletionContextPrivate;

/**
 * GtkSourceCompletionActivation:
 * @GTK_SOURCE_COMPLETION_ACTIVATION_NONE: None.
 * @GTK_SOURCE_COMPLETION_ACTIVATION_INTERACTIVE: Interactive activation. By
 * default, it occurs on each insertion in the #GtkTextBuffer. This can be
 * blocked temporarily with gtk_source_completion_block_interactive().
 * @GTK_SOURCE_COMPLETION_ACTIVATION_USER_REQUESTED: User requested activation.
 * By default, it occurs when the user presses
 * <keycombo><keycap>Control</keycap><keycap>space</keycap></keycombo>.
 */
typedef enum _GtkSourceCompletionActivation
{
	GTK_SOURCE_COMPLETION_ACTIVATION_NONE = 0,
	GTK_SOURCE_COMPLETION_ACTIVATION_INTERACTIVE = 1 << 0,
	GTK_SOURCE_COMPLETION_ACTIVATION_USER_REQUESTED = 1 << 1
} GtkSourceCompletionActivation;

struct _GtkSourceCompletionContext {
	GInitiallyUnowned parent;

	GtkSourceCompletionContextPrivate *priv;
};

struct _GtkSourceCompletionContextClass {
	GInitiallyUnownedClass parent_class;

	void (*cancelled) 	(GtkSourceCompletionContext          *context);

	/* Padding for future expansion */
	void (*_gtk_source_reserved1) (void);
	void (*_gtk_source_reserved2) (void);
	void (*_gtk_source_reserved3) (void);
};

GTK_SOURCE_AVAILABLE_IN_ALL
GType		 gtk_source_completion_context_get_type (void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_ALL
void		 gtk_source_completion_context_add_proposals 	(GtkSourceCompletionContext   *context,
								 GtkSourceCompletionProvider  *provider,
								 GList                        *proposals,
								 gboolean                      finished);

GTK_SOURCE_AVAILABLE_IN_ALL
gboolean	 gtk_source_completion_context_get_iter		(GtkSourceCompletionContext   *context,
								 GtkTextIter                  *iter);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkSourceCompletionActivation
		 gtk_source_completion_context_get_activation	(GtkSourceCompletionContext   *context);

G_GNUC_INTERNAL
GtkSourceCompletionContext *
		_gtk_source_completion_context_new		(GtkSourceCompletion          *completion,
								 GtkTextIter                  *position);

G_GNUC_INTERNAL
void		_gtk_source_completion_context_cancel		(GtkSourceCompletionContext   *context);

G_END_DECLS

#endif /* GTK_SOURCE_COMPLETION_CONTEXT_H */
