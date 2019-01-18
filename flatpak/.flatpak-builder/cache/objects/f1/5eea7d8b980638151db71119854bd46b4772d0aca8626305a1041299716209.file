/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecompletionprovider.h
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

#ifndef GTK_SOURCE_COMPLETION_PROVIDER_H
#define GTK_SOURCE_COMPLETION_PROVIDER_H

#if !defined (GTK_SOURCE_H_INSIDE) && !defined (GTK_SOURCE_COMPILATION)
#  if defined (__GNUC__)
#    warning "Only <gtksourceview/gtksource.h> can be included directly."
#  elif defined (G_OS_WIN32)
#    pragma message("Only <gtksourceview/gtksource.h> can be included directly.")
#  endif
#endif

#include <gtk/gtk.h>
#include <gtksourceview/gtksourcecompletioncontext.h>
#include <gtksourceview/gtksourcetypes.h>

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_COMPLETION_PROVIDER 			(gtk_source_completion_provider_get_type ())
#define GTK_SOURCE_COMPLETION_PROVIDER(obj) 			(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_COMPLETION_PROVIDER, GtkSourceCompletionProvider))
#define GTK_SOURCE_IS_COMPLETION_PROVIDER(obj) 			(G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_COMPLETION_PROVIDER))
#define GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE(obj) 	(G_TYPE_INSTANCE_GET_INTERFACE ((obj), GTK_SOURCE_TYPE_COMPLETION_PROVIDER, GtkSourceCompletionProviderIface))

typedef struct _GtkSourceCompletionProviderIface GtkSourceCompletionProviderIface;

/**
 * GtkSourceCompletionProviderIface:
 * @g_iface: The parent interface.
 * @get_name: The virtual function pointer for gtk_source_completion_provider_get_name().
 * Must be implemented.
 * @get_icon: The virtual function pointer for gtk_source_completion_provider_get_icon().
 * By default, %NULL is returned.
 * @get_icon_name: The virtual function pointer for gtk_source_completion_provider_get_icon_name().
 * By default, %NULL is returned.
 * @get_gicon: The virtual function pointer for gtk_source_completion_provider_get_gicon().
 * By default, %NULL is returned.
 * @populate: The virtual function pointer for gtk_source_completion_provider_populate().
 * Add no proposals by default.
 * @match: The virtual function pointer for gtk_source_completion_provider_match().
 * By default, %TRUE is returned.
 * @get_activation: The virtual function pointer for gtk_source_completion_provider_get_activation().
 * The combination of all #GtkSourceCompletionActivation is returned by default.
 * @get_info_widget: The virtual function pointer for gtk_source_completion_provider_get_info_widget().
 * By default, %NULL is returned.
 * @update_info: The virtual function pointer for gtk_source_completion_provider_update_info().
 * Does nothing by default.
 * @get_start_iter: The virtual function pointer for gtk_source_completion_provider_get_start_iter().
 * By default, %FALSE is returned.
 * @activate_proposal: The virtual function pointer for gtk_source_completion_provider_activate_proposal().
 * By default, %FALSE is returned.
 * @get_interactive_delay: The virtual function pointer for gtk_source_completion_provider_get_interactive_delay().
 * By default, -1 is returned.
 * @get_priority: The virtual function pointer for gtk_source_completion_provider_get_priority().
 * By default, 0 is returned.
 *
 * The virtual function table for #GtkSourceCompletionProvider.
 */
struct _GtkSourceCompletionProviderIface
{
	GTypeInterface g_iface;

	gchar		*(*get_name)       	(GtkSourceCompletionProvider *provider);

	GdkPixbuf	*(*get_icon)       	(GtkSourceCompletionProvider *provider);
	const gchar	*(*get_icon_name)   (GtkSourceCompletionProvider *provider);
	GIcon		*(*get_gicon)       (GtkSourceCompletionProvider *provider);

	void 		 (*populate) 		(GtkSourceCompletionProvider *provider,
						 GtkSourceCompletionContext  *context);

	gboolean 	 (*match)		(GtkSourceCompletionProvider *provider,
	                                         GtkSourceCompletionContext  *context);

	GtkSourceCompletionActivation
		         (*get_activation)	(GtkSourceCompletionProvider *provider);

	GtkWidget 	*(*get_info_widget)	(GtkSourceCompletionProvider *provider,
						 GtkSourceCompletionProposal *proposal);
	void		 (*update_info)		(GtkSourceCompletionProvider *provider,
						 GtkSourceCompletionProposal *proposal,
						 GtkSourceCompletionInfo     *info);

	gboolean	 (*get_start_iter)	(GtkSourceCompletionProvider *provider,
						 GtkSourceCompletionContext  *context,
						 GtkSourceCompletionProposal *proposal,
						 GtkTextIter                 *iter);
	gboolean	 (*activate_proposal)	(GtkSourceCompletionProvider *provider,
						 GtkSourceCompletionProposal *proposal,
						 GtkTextIter                 *iter);

	gint		 (*get_interactive_delay) (GtkSourceCompletionProvider *provider);
	gint		 (*get_priority)	(GtkSourceCompletionProvider *provider);
};

GTK_SOURCE_AVAILABLE_IN_ALL
GType		 gtk_source_completion_provider_get_type	(void);

GTK_SOURCE_AVAILABLE_IN_ALL
gchar		*gtk_source_completion_provider_get_name	(GtkSourceCompletionProvider *provider);

GTK_SOURCE_AVAILABLE_IN_ALL
GdkPixbuf	*gtk_source_completion_provider_get_icon	(GtkSourceCompletionProvider *provider);

GTK_SOURCE_AVAILABLE_IN_3_18
const gchar	*gtk_source_completion_provider_get_icon_name	(GtkSourceCompletionProvider *provider);

GTK_SOURCE_AVAILABLE_IN_3_18
GIcon		*gtk_source_completion_provider_get_gicon	(GtkSourceCompletionProvider *provider);

GTK_SOURCE_AVAILABLE_IN_ALL
void		 gtk_source_completion_provider_populate	(GtkSourceCompletionProvider *provider,
								 GtkSourceCompletionContext  *context);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkSourceCompletionActivation
		 gtk_source_completion_provider_get_activation (GtkSourceCompletionProvider *provider);

GTK_SOURCE_AVAILABLE_IN_ALL
gboolean	 gtk_source_completion_provider_match 		(GtkSourceCompletionProvider *provider,
		                                                 GtkSourceCompletionContext  *context);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkWidget	*gtk_source_completion_provider_get_info_widget	(GtkSourceCompletionProvider *provider,
								 GtkSourceCompletionProposal *proposal);

GTK_SOURCE_AVAILABLE_IN_ALL
void 		 gtk_source_completion_provider_update_info	(GtkSourceCompletionProvider *provider,
								 GtkSourceCompletionProposal *proposal,
								 GtkSourceCompletionInfo     *info);

GTK_SOURCE_AVAILABLE_IN_ALL
gboolean	 gtk_source_completion_provider_get_start_iter	(GtkSourceCompletionProvider *provider,
								 GtkSourceCompletionContext  *context,
								 GtkSourceCompletionProposal *proposal,
								 GtkTextIter                 *iter);

GTK_SOURCE_AVAILABLE_IN_ALL
gboolean	 gtk_source_completion_provider_activate_proposal (GtkSourceCompletionProvider *provider,
								   GtkSourceCompletionProposal *proposal,
								   GtkTextIter                 *iter);

GTK_SOURCE_AVAILABLE_IN_ALL
gint		 gtk_source_completion_provider_get_interactive_delay (GtkSourceCompletionProvider *provider);

GTK_SOURCE_AVAILABLE_IN_ALL
gint		 gtk_source_completion_provider_get_priority	(GtkSourceCompletionProvider *provider);

G_END_DECLS

#endif /* GTK_SOURCE_COMPLETION_PROVIDER_H */
