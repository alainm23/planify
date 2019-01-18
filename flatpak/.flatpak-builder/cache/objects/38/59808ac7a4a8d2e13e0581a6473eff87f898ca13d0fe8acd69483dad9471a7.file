/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecompletionproposal.h
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

#ifndef GTK_SOURCE_COMPLETION_PROPOSAL_H
#define GTK_SOURCE_COMPLETION_PROPOSAL_H

#if !defined (GTK_SOURCE_H_INSIDE) && !defined (GTK_SOURCE_COMPILATION)
#  if defined (__GNUC__)
#    warning "Only <gtksourceview/gtksource.h> can be included directly."
#  elif defined (G_OS_WIN32)
#    pragma message("Only <gtksourceview/gtksource.h> can be included directly.")
#  endif
#endif

#include <glib-object.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <gtksourceview/gtksourcetypes.h>

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_COMPLETION_PROPOSAL			(gtk_source_completion_proposal_get_type ())
#define GTK_SOURCE_COMPLETION_PROPOSAL(obj)			(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_COMPLETION_PROPOSAL, GtkSourceCompletionProposal))
#define GTK_SOURCE_IS_COMPLETION_PROPOSAL(obj)			(G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_COMPLETION_PROPOSAL))
#define GTK_SOURCE_COMPLETION_PROPOSAL_GET_INTERFACE(obj)	(G_TYPE_INSTANCE_GET_INTERFACE ((obj), GTK_SOURCE_TYPE_COMPLETION_PROPOSAL, GtkSourceCompletionProposalIface))

typedef struct _GtkSourceCompletionProposalIface	GtkSourceCompletionProposalIface;

/**
 * GtkSourceCompletionProposalIface:
 * @parent: The parent interface.
 * @get_label: The virtual function pointer for gtk_source_completion_proposal_get_label().
 * By default, %NULL is returned.
 * @get_markup: The virtual function pointer for gtk_source_completion_proposal_get_markup().
 * By default, %NULL is returned.
 * @get_text: The virtual function pointer for gtk_source_completion_proposal_get_text().
 * By default, %NULL is returned.
 * @get_icon: The virtual function pointer for gtk_source_completion_proposal_get_icon().
 * By default, %NULL is returned.
 * @get_icon_name: The virtual function pointer for gtk_source_completion_proposal_get_icon_name().
 * By default, %NULL is returned.
 * @get_gicon: The virtual function pointer for gtk_source_completion_proposal_get_gicon().
 * By default, %NULL is returned.
 * @get_info: The virtual function pointer for gtk_source_completion_proposal_get_info().
 * By default, %NULL is returned.
 * @hash: The virtual function pointer for gtk_source_completion_proposal_hash().
 * By default, it uses a direct hash (g_direct_hash()).
 * @equal: The virtual function pointer for gtk_source_completion_proposal_equal().
 * By default, it uses direct equality (g_direct_equal()).
 * @changed: The function pointer for the #GtkSourceCompletionProposal::changed signal.
 *
 * The virtual function table for #GtkSourceCompletionProposal.
 */
struct _GtkSourceCompletionProposalIface
{
	GTypeInterface parent;

	/* Interface functions */
	gchar		*(*get_label)		(GtkSourceCompletionProposal *proposal);
	gchar		*(*get_markup)		(GtkSourceCompletionProposal *proposal);
	gchar		*(*get_text)		(GtkSourceCompletionProposal *proposal);

	GdkPixbuf	*(*get_icon)		(GtkSourceCompletionProposal *proposal);
	const gchar	*(*get_icon_name)	(GtkSourceCompletionProposal *proposal);
	GIcon		*(*get_gicon)		(GtkSourceCompletionProposal *proposal);

	gchar		*(*get_info)		(GtkSourceCompletionProposal *proposal);

	guint		 (*hash)		(GtkSourceCompletionProposal *proposal);
	gboolean	 (*equal)		(GtkSourceCompletionProposal *proposal,
						 GtkSourceCompletionProposal *other);

	/* Signals */
	void		 (*changed)		(GtkSourceCompletionProposal *proposal);
};

GTK_SOURCE_AVAILABLE_IN_ALL
GType 			 gtk_source_completion_proposal_get_type 	(void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_ALL
gchar			*gtk_source_completion_proposal_get_label	(GtkSourceCompletionProposal *proposal);

GTK_SOURCE_AVAILABLE_IN_ALL
gchar			*gtk_source_completion_proposal_get_markup	(GtkSourceCompletionProposal *proposal);

GTK_SOURCE_AVAILABLE_IN_ALL
gchar			*gtk_source_completion_proposal_get_text	(GtkSourceCompletionProposal *proposal);

GTK_SOURCE_AVAILABLE_IN_ALL
GdkPixbuf		*gtk_source_completion_proposal_get_icon	(GtkSourceCompletionProposal *proposal);

GTK_SOURCE_AVAILABLE_IN_3_18
const gchar		*gtk_source_completion_proposal_get_icon_name	(GtkSourceCompletionProposal *proposal);

GTK_SOURCE_AVAILABLE_IN_3_18
GIcon			*gtk_source_completion_proposal_get_gicon	(GtkSourceCompletionProposal *proposal);

GTK_SOURCE_AVAILABLE_IN_ALL
gchar			*gtk_source_completion_proposal_get_info	(GtkSourceCompletionProposal *proposal);

GTK_SOURCE_AVAILABLE_IN_ALL
void			 gtk_source_completion_proposal_changed		(GtkSourceCompletionProposal *proposal);

GTK_SOURCE_AVAILABLE_IN_ALL
guint			 gtk_source_completion_proposal_hash		(GtkSourceCompletionProposal *proposal);

GTK_SOURCE_AVAILABLE_IN_ALL
gboolean		 gtk_source_completion_proposal_equal		(GtkSourceCompletionProposal *proposal,
									 GtkSourceCompletionProposal *other);

G_END_DECLS

#endif /* GTK_SOURCE_COMPLETION_PROPOSAL_H */
