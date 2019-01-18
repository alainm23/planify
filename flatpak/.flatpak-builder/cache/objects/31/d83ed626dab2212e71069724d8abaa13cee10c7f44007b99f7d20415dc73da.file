/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcecompletionprovider.c
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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcecompletionprovider.h"
#include "gtksourcecompletionproposal.h"
#include "gtksourcecompletioninfo.h"

/**
 * SECTION:completionprovider
 * @title: GtkSourceCompletionProvider
 * @short_description: Completion provider interface
 *
 * You must implement this interface to provide proposals to #GtkSourceCompletion
 *
 * The provider may be displayed in the completion window as a header row, showing
 * its name and optionally an icon.
 * The icon may be specified as a #GdkPixbuf, as an icon name or as a #GIcon by
 * implementing the corresponding get function. At most one of those get functions
 * should return a value different from %NULL, if they all return %NULL no icon
 * will be used.
 */

typedef GtkSourceCompletionProviderIface GtkSourceCompletionProviderInterface;

G_DEFINE_INTERFACE(GtkSourceCompletionProvider, gtk_source_completion_provider, G_TYPE_OBJECT)

/* Default implementations */
static gchar *
gtk_source_completion_provider_get_name_default (GtkSourceCompletionProvider *provider)
{
	g_return_val_if_reached (NULL);
}

static GdkPixbuf *
gtk_source_completion_provider_get_icon_default (GtkSourceCompletionProvider *provider)
{
	return NULL;
}

static const gchar *
gtk_source_completion_provider_get_icon_name_default (GtkSourceCompletionProvider *provider)
{
	return NULL;
}

static GIcon *
gtk_source_completion_provider_get_gicon_default (GtkSourceCompletionProvider *provider)
{
	return NULL;
}

static void
gtk_source_completion_provider_populate_default (GtkSourceCompletionProvider *provider,
                                                 GtkSourceCompletionContext  *context)
{
	gtk_source_completion_context_add_proposals (context, provider, NULL, TRUE);
}

static GtkSourceCompletionActivation
gtk_source_completion_provider_get_activation_default (GtkSourceCompletionProvider *provider)
{
	return GTK_SOURCE_COMPLETION_ACTIVATION_INTERACTIVE |
	       GTK_SOURCE_COMPLETION_ACTIVATION_USER_REQUESTED;
}

static gboolean
gtk_source_completion_provider_match_default (GtkSourceCompletionProvider *provider,
                                              GtkSourceCompletionContext  *context)
{
	return TRUE;
}

static GtkWidget *
gtk_source_completion_provider_get_info_widget_default (GtkSourceCompletionProvider *provider,
                                                        GtkSourceCompletionProposal *proposal)
{
	return NULL;
}

static void
gtk_source_completion_provider_update_info_default (GtkSourceCompletionProvider *provider,
                                                    GtkSourceCompletionProposal *proposal,
                                                    GtkSourceCompletionInfo     *info)
{
}

static gboolean
gtk_source_completion_provider_get_start_iter_default (GtkSourceCompletionProvider *provider,
                                                       GtkSourceCompletionContext  *context,
                                                       GtkSourceCompletionProposal *proposal,
                                                       GtkTextIter                 *iter)
{
	return FALSE;
}

static gboolean
gtk_source_completion_provider_activate_proposal_default (GtkSourceCompletionProvider *provider,
                                                          GtkSourceCompletionProposal *proposal,
                                                          GtkTextIter                 *iter)
{
	return FALSE;
}

static gint
gtk_source_completion_provider_get_interactive_delay_default (GtkSourceCompletionProvider *provider)
{
	/* -1 means the default value in the completion object */
	return -1;
}

static gint
gtk_source_completion_provider_get_priority_default (GtkSourceCompletionProvider *provider)
{
	return 0;
}

static void
gtk_source_completion_provider_default_init (GtkSourceCompletionProviderIface *iface)
{
	iface->get_name = gtk_source_completion_provider_get_name_default;

	iface->get_icon = gtk_source_completion_provider_get_icon_default;
	iface->get_icon_name = gtk_source_completion_provider_get_icon_name_default;
	iface->get_gicon = gtk_source_completion_provider_get_gicon_default;

	iface->populate = gtk_source_completion_provider_populate_default;

	iface->match = gtk_source_completion_provider_match_default;
	iface->get_activation = gtk_source_completion_provider_get_activation_default;

	iface->get_info_widget = gtk_source_completion_provider_get_info_widget_default;
	iface->update_info = gtk_source_completion_provider_update_info_default;

	iface->get_start_iter = gtk_source_completion_provider_get_start_iter_default;
	iface->activate_proposal = gtk_source_completion_provider_activate_proposal_default;

	iface->get_interactive_delay = gtk_source_completion_provider_get_interactive_delay_default;
	iface->get_priority = gtk_source_completion_provider_get_priority_default;
}

/**
 * gtk_source_completion_provider_get_name:
 * @provider: a #GtkSourceCompletionProvider.
 *
 * Get the name of the provider. This should be a translatable name for
 * display to the user. For example: _("Document word completion provider"). The
 * returned string must be freed with g_free().
 *
 * Returns: a new string containing the name of the provider.
 */
gchar *
gtk_source_completion_provider_get_name (GtkSourceCompletionProvider *provider)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), NULL);

	return GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->get_name (provider);
}

/**
 * gtk_source_completion_provider_get_icon:
 * @provider: The #GtkSourceCompletionProvider
 *
 * Get the #GdkPixbuf for the icon of the @provider.
 *
 * Returns: (nullable) (transfer none): The icon to be used for the provider,
 *          or %NULL if the provider does not have a special icon.
 */
GdkPixbuf *
gtk_source_completion_provider_get_icon (GtkSourceCompletionProvider *provider)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), NULL);

	return GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->get_icon (provider);
}

/**
 * gtk_source_completion_provider_get_icon_name:
 * @provider: The #GtkSourceCompletionProvider
 *
 * Gets the icon name of @provider.
 *
 * Returns: (nullable) (transfer none): The icon name to be used for the provider,
 *          or %NULL if the provider does not have a special icon.
 *
 * Since: 3.18
 */
const gchar *
gtk_source_completion_provider_get_icon_name (GtkSourceCompletionProvider *provider)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), NULL);

	return GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->get_icon_name (provider);
}

/**
 * gtk_source_completion_provider_get_gicon:
 * @provider: The #GtkSourceCompletionProvider
 *
 * Gets the #GIcon for the icon of @provider.
 *
 * Returns: (nullable) (transfer none): The icon to be used for the provider,
 *          or %NULL if the provider does not have a special icon.
 *
 * Since: 3.18
 */
GIcon *
gtk_source_completion_provider_get_gicon (GtkSourceCompletionProvider *provider)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), NULL);

	return GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->get_gicon (provider);
}

/**
 * gtk_source_completion_provider_populate:
 * @provider: a #GtkSourceCompletionProvider.
 * @context: a #GtkSourceCompletionContext.
 *
 * Populate @context with proposals from @provider added with the
 * gtk_source_completion_context_add_proposals() function.
 */
void
gtk_source_completion_provider_populate (GtkSourceCompletionProvider *provider,
                                         GtkSourceCompletionContext  *context)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider));

	GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->populate (provider, context);
}

/**
 * gtk_source_completion_provider_get_activation:
 * @provider: a #GtkSourceCompletionProvider.
 *
 * Get with what kind of activation the provider should be activated.
 *
 * Returns: a combination of #GtkSourceCompletionActivation.
 **/
GtkSourceCompletionActivation
gtk_source_completion_provider_get_activation (GtkSourceCompletionProvider *provider)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), GTK_SOURCE_COMPLETION_ACTIVATION_NONE);

	return GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->get_activation (provider);
}

/**
 * gtk_source_completion_provider_match:
 * @provider: a #GtkSourceCompletionProvider.
 * @context: a #GtkSourceCompletionContext.
 *
 * Get whether the provider match the context of completion detailed in
 * @context.
 *
 * Returns: %TRUE if @provider matches the completion context, %FALSE otherwise.
 */
gboolean
gtk_source_completion_provider_match (GtkSourceCompletionProvider *provider,
                                      GtkSourceCompletionContext  *context)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), TRUE);

	return GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->match (provider,
	                                                                       context);
}

/**
 * gtk_source_completion_provider_get_info_widget:
 * @provider: a #GtkSourceCompletionProvider.
 * @proposal: a currently selected #GtkSourceCompletionProposal.
 *
 * Get a customized info widget to show extra information of a proposal.
 * This allows for customized widgets on a proposal basis, although in general
 * providers will have the same custom widget for all their proposals and
 * @proposal can be ignored. The implementation of this function is optional.
 *
 * If this function is not implemented, the default widget is a #GtkLabel. The
 * return value of gtk_source_completion_proposal_get_info() is used as the
 * content of the #GtkLabel.
 *
 * <note>
 *   <para>
 *     If implemented, gtk_source_completion_provider_update_info()
 *     <emphasis>must</emphasis> also be implemented.
 *   </para>
 * </note>
 *
 * Returns: (nullable) (transfer none): a custom #GtkWidget to show extra
 * information about @proposal, or %NULL if the provider does not have a special
 * info widget.
 */
GtkWidget *
gtk_source_completion_provider_get_info_widget (GtkSourceCompletionProvider *provider,
                                                GtkSourceCompletionProposal *proposal)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), NULL);
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROPOSAL (proposal), NULL);

	return GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->get_info_widget (provider, proposal);
}

/**
 * gtk_source_completion_provider_update_info:
 * @provider: a #GtkSourceCompletionProvider.
 * @proposal: a #GtkSourceCompletionProposal.
 * @info: a #GtkSourceCompletionInfo.
 *
 * Update extra information shown in @info for @proposal.
 *
 * <note>
 *   <para>
 *     This function <emphasis>must</emphasis> be implemented when
 *     gtk_source_completion_provider_get_info_widget() is implemented.
 *   </para>
 * </note>
 */
void
gtk_source_completion_provider_update_info (GtkSourceCompletionProvider *provider,
                                            GtkSourceCompletionProposal *proposal,
                                            GtkSourceCompletionInfo     *info)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider));
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_PROPOSAL (proposal));
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_INFO (info));

	GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->update_info (provider, proposal, info);
}

/**
 * gtk_source_completion_provider_get_start_iter:
 * @provider: a #GtkSourceCompletionProvider.
 * @proposal: a #GtkSourceCompletionProposal.
 * @context: a #GtkSourceCompletionContext.
 * @iter: (out): a #GtkTextIter.
 *
 * Get the #GtkTextIter at which the completion for @proposal starts. When
 * implemented, this information is used to position the completion window
 * accordingly when a proposal is selected in the completion window. The
 * @proposal text inside the completion window is aligned on @iter.
 *
 * If this function is not implemented, the word boundary is taken to position
 * the completion window. See gtk_source_completion_provider_activate_proposal()
 * for an explanation on the word boundaries.
 *
 * When the @proposal is activated, the default handler uses @iter as the start
 * of the word to replace. See
 * gtk_source_completion_provider_activate_proposal() for more information.
 *
 * Returns: %TRUE if @iter was set for @proposal, %FALSE otherwise.
 */
gboolean
gtk_source_completion_provider_get_start_iter (GtkSourceCompletionProvider *provider,
                                               GtkSourceCompletionContext  *context,
                                               GtkSourceCompletionProposal *proposal,
                                               GtkTextIter                 *iter)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), FALSE);
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_CONTEXT (context), FALSE);
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROPOSAL (proposal), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);

	return GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->get_start_iter (provider,
	                                                                                context,
	                                                                                proposal,
	                                                                                iter);
}

/**
 * gtk_source_completion_provider_activate_proposal:
 * @provider: a #GtkSourceCompletionProvider.
 * @proposal: a #GtkSourceCompletionProposal.
 * @iter: a #GtkTextIter.
 *
 * Activate @proposal at @iter. When this functions returns %FALSE, the default
 * activation of @proposal will take place which replaces the word at @iter
 * with the text of @proposal (see gtk_source_completion_proposal_get_text()).
 *
 * Here is how the default activation selects the boundaries of the word to
 * replace. The end of the word is @iter. For the start of the word, it depends
 * on whether a start iter is defined for @proposal (see
 * gtk_source_completion_provider_get_start_iter()). If a start iter is defined,
 * the start of the word is the start iter. Else, the word (as long as possible)
 * will contain only alphanumerical and the "_" characters.
 *
 * Returns: %TRUE to indicate that the proposal activation has been handled,
 *          %FALSE otherwise.
 */
gboolean
gtk_source_completion_provider_activate_proposal (GtkSourceCompletionProvider *provider,
                                                  GtkSourceCompletionProposal *proposal,
                                                  GtkTextIter                 *iter)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), FALSE);
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROPOSAL (proposal), FALSE);

	return GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->activate_proposal (provider,
	                                                                                   proposal,
	                                                                                   iter);
}

/**
 * gtk_source_completion_provider_get_interactive_delay:
 * @provider: a #GtkSourceCompletionProvider.
 *
 * Get the delay in milliseconds before starting interactive completion for
 * this provider. A value of -1 indicates to use the default value as set
 * by the #GtkSourceCompletion:auto-complete-delay property.
 *
 * Returns: the interactive delay in milliseconds.
 **/
gint
gtk_source_completion_provider_get_interactive_delay (GtkSourceCompletionProvider *provider)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), -1);

	return GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->get_interactive_delay (provider);
}

/**
 * gtk_source_completion_provider_get_priority:
 * @provider: a #GtkSourceCompletionProvider.
 *
 * Get the provider priority. The priority determines the order in which
 * proposals appear in the completion popup. Higher priorities are sorted
 * before lower priorities. The default priority is 0.
 *
 * Returns: the provider priority.
 **/
gint
gtk_source_completion_provider_get_priority (GtkSourceCompletionProvider *provider)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), 0);

	return GTK_SOURCE_COMPLETION_PROVIDER_GET_INTERFACE (provider)->get_priority (provider);
}
