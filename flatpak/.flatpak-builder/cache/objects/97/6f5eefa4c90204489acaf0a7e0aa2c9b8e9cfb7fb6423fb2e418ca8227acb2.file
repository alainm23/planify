/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcecompletion.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2007 -2009 Jesús Barbero Rodríguez <chuchiperriman@gmail.com>
 * Copyright (C) 2009 - Jesse van den Kieboom <jessevdk@gnome.org>
 * Copyright (C) 2013 - Sébastien Wilmet <swilmet@gnome.org>
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

/**
 * SECTION:completion
 * @title: GtkSourceCompletion
 * @short_description: Main Completion Object
 *
 * The completion system helps the user when he writes some text, such
 * as words, command names, functions, and suchlike. Proposals can be
 * shown, to complete the text the user is writing. Each proposal can
 * contain an additional piece of information, that is displayed when
 * the "Details" button is active.
 *
 * Proposals are created via a #GtkSourceCompletionProvider. There can
 * be for example a provider to complete words (see
 * #GtkSourceCompletionWords), another provider for the completion of
 * function's names, etc. To add a provider, call
 * gtk_source_completion_add_provider().
 *
 * When the completion is activated, a #GtkSourceCompletionContext object is
 * created. The providers are asked whether they match the context, with
 * gtk_source_completion_provider_match(). If a provider doesn't match the
 * context, it will not be visible in the completion window. On the
 * other hand, if the provider matches the context, its proposals will
 * be displayed.
 *
 * When several providers match, they are all shown in the completion
 * window, but one can switch between providers: see the
 * #GtkSourceCompletion::move-page signal. It is also possible to
 * activate the first proposals with key bindings, see the
 * #GtkSourceCompletion:accelerators property.
 *
 * The #GtkSourceCompletionProposal interface represents a proposal.
 * The #GtkSourceCompletionItem class is a simple implementation of this
 * interface.
 *
 * If a proposal contains extra information (see
 * gtk_source_completion_provider_get_info_widget()), it will be
 * displayed in a #GtkSourceCompletionInfo window, which appears when
 * the "Details" button is clicked.
 *
 * A #GtkSourceCompletionInfo window can also be used to display
 * calltips. When no proposals are available, it can be useful to
 * display extra information like a function's prototype (number of
 * parameters, types of parameters, etc).
 *
 * Each #GtkSourceView object is associated with a #GtkSourceCompletion
 * instance. This instance can be obtained with
 * gtk_source_view_get_completion(). The #GtkSourceView class contains also the
 * #GtkSourceView::show-completion signal.
 *
 * A same #GtkSourceCompletionProvider object can be used for several
 * #GtkSourceCompletion.
 *
 * # GtkSourceCompletion as GtkBuildable
 *
 * The GtkSourceCompletion implementation of the #GtkBuildable interface exposes
 * the info window object (see gtk_source_completion_get_info_window()) with the
 * internal-child "info_window".
 *
 * An example of a UI definition fragment with GtkSourceCompletion:
 * |[
 * <object class="GtkSourceCompletion">
 *   <property name="select_on_show">False</property>
 *   <child internal-child="info_window">
 *     <object class="GtkSourceCompletionInfo">
 *       <property name="border_width">6</property>
 *     </object>
 *   </child>
 * </object>
 * ]|
 */

/* Idea to improve the code: use a composite widget template. This class is not
 * a GtkWidget, so some refactoring needs to be done, to have a subclass of
 * GtkSourceCompletionInfo for the main completion window.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcecompletion.h"
#include "gtksourcecompletion-private.h"
#include "gtksourcecompletionmodel.h"
#include "gtksourcecompletioncontext.h"
#include "gtksourcecompletioninfo.h"
#include "gtksourcecompletionproposal.h"
#include "gtksourcecompletionprovider.h"
#include "gtksourcecompletioncontainer.h"
#include "gtksourcebuffer.h"
#include "gtksourceview.h"
#include "gtksourceview-i18n.h"

enum
{
	SHOW,
	HIDE,
	POPULATE_CONTEXT,

	/* Actions */
	ACTIVATE_PROPOSAL,
	MOVE_CURSOR,
	MOVE_PAGE,

	N_SIGNALS
};

enum
{
	PROP_0,
	PROP_VIEW,
	PROP_REMEMBER_INFO_VISIBILITY,
	PROP_SELECT_ON_SHOW,
	PROP_SHOW_HEADERS,
	PROP_SHOW_ICONS,
	PROP_ACCELERATORS,
	PROP_AUTO_COMPLETE_DELAY,
	PROP_PROVIDER_PAGE_SIZE,
	PROP_PROPOSAL_PAGE_SIZE
};

struct _GtkSourceCompletionPrivate
{
	GtkSourceCompletionInfo *main_window;
	GtkSourceCompletionInfo *info_window;

	/* Bottom bar, containing the "Details" button and the selection image
	 * and label. */
	GtkWidget *bottom_bar;

	/* Image and label in the bottom bar, on the right, for showing which
	 * provider(s) are selected. */
	GtkImage *selection_image;
	GtkLabel *selection_label;

	/* The default widget for the info window */
	GtkLabel *default_info;

	/* The "Details" button, for showing the info window */
	GtkToggleButton *info_button;

	/* List of proposals */
	GtkTreeView *tree_view_proposals;

	GtkCellRenderer *cell_renderer_proposal;

	/* Completion management */

	GtkSourceCompletionModel *model_proposals;

	GList *providers;

	GtkSourceCompletionContext *context;
	GList *active_providers;
	GList *running_providers;

	guint show_timed_out_id;

	GtkTextBuffer *buffer;

	GList *auto_completion_selection;
	GtkSourceCompletionContext *auto_completion_context;

	/* Number of times the interactive completion is blocked */
	guint block_interactive_num;

	/* Properties */

	/* Weak reference to the view. You must check if view != NULL before
	 * using it.
	 */
	GtkSourceView *view;
	guint num_accelerators;
	guint auto_complete_delay;
	guint proposal_page_size;
	guint provider_page_size;

	guint remember_info_visibility : 1;
	guint select_on_show : 1;
	guint show_headers : 1;
	guint show_icons : 1;
};

static guint signals[N_SIGNALS];

static void	gtk_source_completion_buildable_interface_init (GtkBuildableIface *iface);

G_DEFINE_TYPE_WITH_CODE (GtkSourceCompletion, gtk_source_completion, G_TYPE_OBJECT,
			 G_ADD_PRIVATE (GtkSourceCompletion)
			 G_IMPLEMENT_INTERFACE (GTK_TYPE_BUILDABLE,
						gtk_source_completion_buildable_interface_init))

static void
scroll_to_iter (GtkSourceCompletion *completion,
                GtkTreeIter         *iter)
{
	GtkTreePath *path;
	GtkTreeIter prev_iter = *iter;

	path = gtk_tree_model_get_path (GTK_TREE_MODEL (completion->priv->model_proposals),
					iter);

	gtk_tree_view_scroll_to_cell (completion->priv->tree_view_proposals,
				      path, NULL,
				      FALSE, 0, 0);
	gtk_tree_path_free (path);

	if (gtk_source_completion_model_iter_previous (completion->priv->model_proposals, &prev_iter) &&
	    gtk_source_completion_model_iter_is_header (completion->priv->model_proposals, &prev_iter))
	{
		/* If we want to scroll to the first proposal of a provider,
		 * it's better to show the header too, if there is a header.
		 * We first scroll to the proposal, and then to the
		 * header, so we are sure that the proposal is visible.
		 */

		path = gtk_tree_model_get_path (GTK_TREE_MODEL (completion->priv->model_proposals),
						&prev_iter);

		gtk_tree_view_scroll_to_cell (completion->priv->tree_view_proposals,
					      path, NULL,
					      FALSE, 0, 0);
		gtk_tree_path_free (path);
	}
}

/* Returns %TRUE if a proposal is selected.
 * Call g_object_unref() on @provider and @proposal when no longer needed.
 */
static gboolean
get_selected_proposal (GtkSourceCompletion          *completion,
		       GtkSourceCompletionProvider **provider,
		       GtkSourceCompletionProposal **proposal)
{
	GtkTreeIter iter;
	GtkTreeSelection *selection;

	selection = gtk_tree_view_get_selection (completion->priv->tree_view_proposals);

	if (!gtk_tree_selection_get_selected (selection, NULL, &iter))
	{
		return FALSE;
	}

	if (gtk_source_completion_model_iter_is_header (completion->priv->model_proposals, &iter))
	{
		return FALSE;
	}

	if (provider != NULL)
	{
		gtk_tree_model_get (GTK_TREE_MODEL (completion->priv->model_proposals), &iter,
				    GTK_SOURCE_COMPLETION_MODEL_COLUMN_PROVIDER, provider,
				    -1);
	}

	if (proposal != NULL)
	{
		gtk_tree_model_get (GTK_TREE_MODEL (completion->priv->model_proposals), &iter,
				    GTK_SOURCE_COMPLETION_MODEL_COLUMN_PROPOSAL, proposal,
				    -1);
	}

	return TRUE;
}

/* Returns %TRUE if the first proposal is selected. */
static gboolean
check_first_selected (GtkSourceCompletion *completion)
{
	GtkTreeSelection *selection;
	GtkTreeIter iter;

	if (get_selected_proposal (completion, NULL, NULL) ||
	    !completion->priv->select_on_show)
	{
		return FALSE;
	}

	if (!gtk_source_completion_model_first_proposal (completion->priv->model_proposals, &iter))
	{
		return FALSE;
	}

	selection = gtk_tree_view_get_selection (completion->priv->tree_view_proposals);
	gtk_tree_selection_select_iter (selection, &iter);
	scroll_to_iter (completion, &iter);

	return TRUE;
}

static void
get_iter_at_insert (GtkSourceCompletion *completion,
                    GtkTextIter         *iter)
{
	gtk_text_buffer_get_iter_at_mark (completion->priv->buffer,
	                                  iter,
	                                  gtk_text_buffer_get_insert (completion->priv->buffer));
}

static GList *
select_providers (GList                      *providers,
                  GtkSourceCompletionContext *context)
{
	GtkTextIter context_iter;
	GList *selection = NULL;
	GList *l;

	if (!gtk_source_completion_context_get_iter (context, &context_iter))
	{
		return NULL;
	}

	for (l = providers; l != NULL; l = l->next)
	{
		GtkSourceCompletionProvider *provider = l->data;

		gboolean good_activation = (gtk_source_completion_provider_get_activation (provider) &
					    gtk_source_completion_context_get_activation (context)) != 0;

		if (good_activation &&
		    gtk_source_completion_provider_match (provider, context))
		{
			selection = g_list_prepend (selection, provider);
		}
	}

	return g_list_reverse (selection);
}

static gint
minimum_auto_complete_delay (GtkSourceCompletion *completion,
                             GList               *providers)
{
	gint min_delay = completion->priv->auto_complete_delay;

	while (providers != NULL)
	{
		GtkSourceCompletionProvider *provider = providers->data;
		gint delay = gtk_source_completion_provider_get_interactive_delay (provider);

		if (0 <= delay && delay < min_delay)
		{
			min_delay = delay;
		}

		providers = g_list_next (providers);
	}

	return min_delay;
}

static void
reset_completion (GtkSourceCompletion *completion)
{
	if (completion->priv->show_timed_out_id != 0)
	{
		g_source_remove (completion->priv->show_timed_out_id);
		completion->priv->show_timed_out_id = 0;
	}

	if (completion->priv->context != NULL)
	{
		/* Inform providers of cancellation through the context */
		_gtk_source_completion_context_cancel (completion->priv->context);

		g_clear_object (&completion->priv->context);
	}

	g_list_free (completion->priv->running_providers);
	g_list_free (completion->priv->active_providers);
	completion->priv->running_providers = NULL;
	completion->priv->active_providers = NULL;
}

/* A separator is a character like (, a space etc. An _ is not a separator. */
static gboolean
is_separator (const gunichar ch)
{
	if (g_unichar_isprint (ch) &&
	    (g_unichar_isalnum (ch) || ch == g_utf8_get_char ("_")))
	{
		return FALSE;
	}

	return TRUE;
}

/* Assigns @start_word to the start position of the word, and @end_word to the
 * end position.
 */
static void
get_word_iter (GtkTextBuffer *buffer,
	       GtkTextIter   *start_word,
	       GtkTextIter   *end_word)
{
	gtk_text_buffer_get_iter_at_mark (buffer,
	                                  end_word,
	                                  gtk_text_buffer_get_insert (buffer));

	*start_word = *end_word;

	while (gtk_text_iter_backward_char (start_word))
	{
		gunichar ch = gtk_text_iter_get_char (start_word);

		if (is_separator (ch))
		{
			gtk_text_iter_forward_char (start_word);
			return;
		}
	}
}

static void
replace_current_word (GtkTextBuffer *buffer,
		      const gchar   *new_text)
{
	GtkTextIter word_start;
	GtkTextIter word_end;

	get_word_iter (buffer, &word_start, &word_end);

	gtk_text_buffer_begin_user_action (buffer);

	gtk_text_buffer_delete (buffer, &word_start, &word_end);

	if (new_text != NULL)
	{
		gtk_text_buffer_insert (buffer, &word_start, new_text, -1);
	}

	gtk_text_buffer_end_user_action (buffer);
}

static void
update_window_position (GtkSourceCompletion *completion)
{
	GtkSourceCompletionProvider *provider;
	GtkSourceCompletionProposal *proposal;
	GtkTextIter iter;
	gboolean iter_set = FALSE;

	if (completion->priv->view == NULL)
	{
		return;
	}

	/* The model can be modified while there is no completion context, for
	 * example when the headers are shown or hidden. This triggers a signal
	 * to update the window position, but if there is no completion context,
	 * no need to update the window position (the window is normally hidden
	 * in this case). When a new population is done, this function will be
	 * called again, so no problem.
	 */
	if (completion->priv->context == NULL)
	{
		return;
	}

	if (get_selected_proposal (completion, &provider, &proposal))
	{
		GtkTextIter context_iter;
		gboolean valid_context;

		valid_context = gtk_source_completion_context_get_iter (completion->priv->context,
									&context_iter);

		if (valid_context &&
		    gtk_source_completion_provider_get_start_iter (provider,
		                                                   completion->priv->context,
		                                                   proposal,
		                                                   &iter))
		{
			iter_set = TRUE;
		}

		g_object_unref (provider);
		g_object_unref (proposal);
	}

	if (!iter_set)
	{
		GtkTextIter end_word;
		get_word_iter (completion->priv->buffer, &iter, &end_word);
	}

	gtk_source_completion_info_move_to_iter (completion->priv->main_window,
	                                         GTK_TEXT_VIEW (completion->priv->view),
	                                         &iter);
}

static void
set_info_widget (GtkSourceCompletion *completion,
		 GtkWidget           *new_widget)
{
	GtkWidget *cur_widget = gtk_bin_get_child (GTK_BIN (completion->priv->info_window));

	if (cur_widget == new_widget)
	{
		return;
	}

	if (cur_widget != NULL)
	{
		gtk_container_remove (GTK_CONTAINER (completion->priv->info_window), cur_widget);
	}

	gtk_container_add (GTK_CONTAINER (completion->priv->info_window), new_widget);
}

static void
update_proposal_info_state (GtkSourceCompletion *completion)
{
	GtkSourceCompletionProvider *provider = NULL;
	GtkSourceCompletionProposal *proposal = NULL;
	GtkWidget *info_widget;

	if (!get_selected_proposal (completion, &provider, &proposal))
	{
		gtk_widget_set_sensitive (GTK_WIDGET (completion->priv->info_button), FALSE);
		return;
	}

	info_widget = gtk_source_completion_provider_get_info_widget (provider, proposal);

	if (info_widget != NULL)
	{
		set_info_widget (completion, info_widget);
		gtk_widget_set_sensitive (GTK_WIDGET (completion->priv->info_button), TRUE);

		gtk_source_completion_provider_update_info (provider,
			                                    proposal,
			                                    completion->priv->info_window);
	}
	else
	{
		gchar *text = gtk_source_completion_proposal_get_info (proposal);

		if (text != NULL)
		{
			set_info_widget (completion, GTK_WIDGET (completion->priv->default_info));
			gtk_widget_set_sensitive (GTK_WIDGET (completion->priv->info_button), TRUE);

			gtk_label_set_markup (completion->priv->default_info, text);
			g_free (text);
		}
		else
		{
			gtk_widget_set_sensitive (GTK_WIDGET (completion->priv->info_button), FALSE);
		}
	}

	g_object_unref (provider);
	g_object_unref (proposal);
}

static void
update_info_window_visibility (GtkSourceCompletion *completion)
{
	if (gtk_widget_get_sensitive (GTK_WIDGET (completion->priv->info_button)) &&
	    gtk_toggle_button_get_active (completion->priv->info_button))
	{
		gtk_widget_show (GTK_WIDGET (completion->priv->info_window));
	}
	else
	{
		gtk_widget_hide (GTK_WIDGET (completion->priv->info_window));
	}
}

static void
update_proposal_info (GtkSourceCompletion *completion)
{
	update_proposal_info_state (completion);
	update_info_window_visibility (completion);
}

static void
gtk_source_completion_show_default (GtkSourceCompletion *completion)
{
	if (completion->priv->view == NULL)
	{
		return;
	}

	gtk_widget_show (GTK_WIDGET (completion->priv->main_window));

	/* Do the autosize when the widget is visible. It doesn't work if it is
	 * done before.
	 */
	gtk_tree_view_columns_autosize (completion->priv->tree_view_proposals);

	if (!completion->priv->remember_info_visibility)
	{
		gtk_toggle_button_set_active (completion->priv->info_button, FALSE);
	}

	update_proposal_info (completion);

	gtk_widget_grab_focus (GTK_WIDGET (completion->priv->view));
}

static void
gtk_source_completion_hide_default (GtkSourceCompletion *completion)
{
	gtk_widget_hide (GTK_WIDGET (completion->priv->info_window));
	gtk_widget_hide (GTK_WIDGET (completion->priv->main_window));
}

static void
gtk_source_completion_proposals_size_allocate (GtkSourceCompletion *completion,
					       GtkAllocation       *allocation,
					       GtkWidget           *widget)
{
	GtkTreeViewColumn *column;
	gint cell_offset = 0;
	gint column_offset;
	gint focus_padding;
	gint horizontal_separator;
	gint x_offset = 0;

	if (!gtk_widget_get_realized (GTK_WIDGET (completion->priv->tree_view_proposals)))
	{
		return;
	}

	gtk_widget_style_get (GTK_WIDGET (completion->priv->tree_view_proposals),
	                      "focus-padding", &focus_padding,
	                      "horizontal-separator", &horizontal_separator,
	                      NULL);

	column = gtk_tree_view_get_column (completion->priv->tree_view_proposals, 1);
	column_offset = gtk_tree_view_column_get_x_offset (column);
	gtk_tree_view_column_cell_get_position (column,
	                                        completion->priv->cell_renderer_proposal,
	                                        &cell_offset,
	                                        NULL);

	x_offset = column_offset + cell_offset + horizontal_separator + focus_padding;

	gtk_tree_view_convert_bin_window_to_widget_coords (completion->priv->tree_view_proposals,
	                                                   x_offset,
	                                                   0,
	                                                   &x_offset,
	                                                   NULL);
	gtk_widget_translate_coordinates (GTK_WIDGET (completion->priv->tree_view_proposals),
	                                  GTK_WIDGET (completion->priv->main_window),
	                                  x_offset,
	                                  0,
	                                  &x_offset,
	                                  NULL);

	_gtk_source_completion_info_set_xoffset (completion->priv->main_window, -x_offset);
}

static void
gtk_source_completion_activate_proposal (GtkSourceCompletion *completion)
{
	GtkSourceCompletionProvider *provider = NULL;
	GtkSourceCompletionProposal *proposal = NULL;
	GtkTextIter insert_iter;
	GtkTextIter context_iter;
	gboolean valid_context;
	gboolean activated;

	if (completion->priv->view == NULL)
	{
		return;
	}

	if (!get_selected_proposal (completion, &provider, &proposal))
	{
		return;
	}

	get_iter_at_insert (completion, &insert_iter);

	gtk_source_completion_block_interactive (completion);

	activated = gtk_source_completion_provider_activate_proposal (provider, proposal, &insert_iter);

	valid_context = (completion->priv->context != NULL &&
			 gtk_source_completion_context_get_iter (completion->priv->context,
								 &context_iter));

	if (!activated && valid_context)
	{
		GtkTextIter start_iter;
		gchar *text = gtk_source_completion_proposal_get_text (proposal);

		gboolean has_start = gtk_source_completion_provider_get_start_iter (provider,
										    completion->priv->context,
										    proposal,
										    &start_iter);

		if (has_start)
		{
			gtk_text_buffer_begin_user_action (completion->priv->buffer);
			gtk_text_buffer_delete (completion->priv->buffer, &start_iter, &insert_iter);
			gtk_text_buffer_insert (completion->priv->buffer, &start_iter, text, -1);
			gtk_text_buffer_end_user_action (completion->priv->buffer);
		}
		else
		{
			replace_current_word (completion->priv->buffer, text);
		}

		g_free (text);
	}

	gtk_source_completion_unblock_interactive (completion);

	gtk_source_completion_hide (completion);

	g_object_unref (provider);
	g_object_unref (proposal);
}

static void
update_info_position (GtkSourceCompletion *completion)
{
	GdkScreen *screen;
	gint x, y;
	gint width, height;
	gint screen_width;
	gint info_width;

	gtk_window_get_position (GTK_WINDOW (completion->priv->main_window), &x, &y);
	gtk_window_get_size (GTK_WINDOW (completion->priv->main_window), &width, &height);
	gtk_window_get_size (GTK_WINDOW (completion->priv->info_window), &info_width, NULL);

	screen = gtk_window_get_screen (GTK_WINDOW (completion->priv->main_window));
	screen_width = gdk_screen_get_width (screen);

	/* Determine on which side to place it */
	if (x + width + info_width >= screen_width)
	{
		x -= info_width;
	}
	else
	{
		x += width;
	}

	gtk_window_move (GTK_WINDOW (completion->priv->info_window), x, y);
}

static GtkSourceCompletionProvider *
get_visible_provider (GtkSourceCompletion *completion)
{
	GList *visible = gtk_source_completion_model_get_visible_providers (completion->priv->model_proposals);

	if (visible != NULL)
	{
		return GTK_SOURCE_COMPLETION_PROVIDER (visible->data);
	}
	else
	{
		return NULL;
	}
}

static void
get_num_visible_providers (GtkSourceCompletion *completion,
                           guint               *num,
                           guint               *current)
{
	GList *providers = gtk_source_completion_model_get_providers (completion->priv->model_proposals);
	GtkSourceCompletionProvider *visible = get_visible_provider (completion);

	*num = g_list_length (providers);
	*current = 0;

	if (visible != NULL)
	{
		gint idx = g_list_index (providers, visible);
		g_return_if_fail (idx != -1);

		*current = idx + 1;
	}

	g_list_free (providers);
}

static void
update_selection_label (GtkSourceCompletion *completion)
{
	guint pos;
	guint num;
	gchar *name;
	gchar *selection_text;
	GtkSourceCompletionProvider *visible;

	get_num_visible_providers (completion, &num, &pos);

	if (num <= 1)
	{
		/* At most one provider. All the proposals are shown. */
		gtk_image_clear (completion->priv->selection_image);
		gtk_widget_hide (GTK_WIDGET (completion->priv->selection_label));
		return;
	}

	visible = get_visible_provider (completion);

	if (visible == NULL)
	{
		/* Translators: "All" is used as a label in the status bar of the
		popup, telling that all completion pages are shown. */
		name = g_strdup_printf("<b>%s</b>", _("All"));

		gtk_image_clear (completion->priv->selection_image);
	}
	else
	{
		gchar *temp_name = gtk_source_completion_provider_get_name (visible);
		name = g_markup_escape_text (temp_name, -1);
		g_free (temp_name);

		gtk_image_set_from_pixbuf (completion->priv->selection_image,
					   gtk_source_completion_provider_get_icon (visible));
	}

	selection_text = g_strdup_printf ("<small>%s (%d/%d)</small>", name, pos + 1, num + 1);
	gtk_label_set_markup (completion->priv->selection_label, selection_text);
	gtk_widget_show (GTK_WIDGET (completion->priv->selection_label));

	g_free (selection_text);
	g_free (name);
}

static gboolean
get_next_iter (GtkSourceCompletion *completion,
	       gint                 num,
	       GtkTreeIter         *iter)
{
	GtkTreeSelection *selection;
	gboolean has_selection;

	selection = gtk_tree_view_get_selection (completion->priv->tree_view_proposals);
	has_selection = gtk_tree_selection_get_selected (selection, NULL, iter);

	if (!has_selection)
	{
		return gtk_source_completion_model_first_proposal (completion->priv->model_proposals,
								   iter);
	}

	while (num > 0)
	{
		if (!gtk_source_completion_model_next_proposal (completion->priv->model_proposals, iter))
		{
			return gtk_source_completion_model_last_proposal (completion->priv->model_proposals,
									  iter);
		}

		num--;
	}

	return TRUE;
}

static gboolean
get_previous_iter (GtkSourceCompletion *completion,
		   gint                 num,
		   GtkTreeIter         *iter)
{
	GtkTreeSelection *selection;
	gboolean has_selection;

	selection = gtk_tree_view_get_selection (completion->priv->tree_view_proposals);
	has_selection = gtk_tree_selection_get_selected (selection, NULL, iter);

	if (!has_selection)
	{
		return gtk_source_completion_model_last_proposal (completion->priv->model_proposals,
								  iter);
	}

	while (num > 0)
	{
		if (!gtk_source_completion_model_previous_proposal (completion->priv->model_proposals,
								    iter))
		{
			return gtk_source_completion_model_first_proposal (completion->priv->model_proposals,
									   iter);
		}

		num--;
	}

	return TRUE;
}

static void
gtk_source_completion_move_cursor (GtkSourceCompletion *completion,
                                   GtkScrollStep        step,
                                   gint                 num)
{
	GtkTreeIter iter;
	gboolean ok;

	if (step == GTK_SCROLL_ENDS)
	{
		if (num > 0)
		{
			ok = gtk_source_completion_model_last_proposal (completion->priv->model_proposals,
									&iter);
		}
		else
		{
			ok = gtk_source_completion_model_first_proposal (completion->priv->model_proposals,
									 &iter);
		}
	}
	else
	{
		if (step == GTK_SCROLL_PAGES)
		{
			num *= completion->priv->proposal_page_size;
		}

		if (num > 0)
		{
			ok = get_next_iter (completion, num, &iter);
		}
		else
		{
			ok = get_previous_iter (completion, -1 * num, &iter);
		}
	}

	if (ok)
	{
		GtkTreeSelection *selection;

		selection = gtk_tree_view_get_selection (completion->priv->tree_view_proposals);
		gtk_tree_selection_select_iter (selection, &iter);

		scroll_to_iter (completion, &iter);
	}
}

static GList *
get_last_provider (GtkSourceCompletion *completion)
{
	GList *providers = gtk_source_completion_model_get_providers (completion->priv->model_proposals);
	GList *ret;

	g_return_val_if_fail (providers != NULL, NULL);

	if (providers->next == NULL)
	{
		ret = NULL;
	}
	else
	{
		ret = g_list_copy (g_list_last (providers));
	}

	g_list_free (providers);
	return ret;
}

static GList *
providers_cycle_forward (GList *all_providers,
			 GList *position,
			 gint   num)
{
	GList *l = position;
	gint i;

	if (all_providers == NULL || all_providers->next == NULL)
	{
		return NULL;
	}

	for (i = 0; i < num; i++)
	{
		l = l == NULL ? all_providers : l->next;
	}

	return l;
}

static GList *
providers_cycle_backward (GList *all_providers,
			  GList *position,
			  gint   num)
{
	gint i;
	GList *l = position;
	GList *end = g_list_last (all_providers);

	if (all_providers == NULL || all_providers->next == NULL)
	{
		return NULL;
	}

	for (i = 0; i < num; i++)
	{
		l = l == NULL ? end : l->prev;
	}

	return l;
}

static GList *
get_next_provider (GtkSourceCompletion *completion,
		   gint                 num)
{
	GList *providers;
	GList *visible_providers;
	GList *position;
	GList *ret;

	providers = gtk_source_completion_model_get_providers (completion->priv->model_proposals);
	visible_providers = gtk_source_completion_model_get_visible_providers (completion->priv->model_proposals);

	if (visible_providers == NULL)
	{
		position = NULL;
	}
	else
	{
		position = g_list_find (providers, visible_providers->data);
	}

	position = providers_cycle_forward (providers, position, num);

	if (position == NULL)
	{
		ret = NULL;
	}
	else
	{
		ret = g_list_append (NULL, position->data);
	}

	g_list_free (providers);

	return ret;
}

static GList *
get_previous_provider (GtkSourceCompletion *completion,
		       gint                 num)
{
	GList *providers;
	GList *visible_providers;
	GList *position;
	GList *ret;

	providers = gtk_source_completion_model_get_providers (completion->priv->model_proposals);
	visible_providers = gtk_source_completion_model_get_visible_providers (completion->priv->model_proposals);

	if (visible_providers == NULL)
	{
		position = NULL;
	}
	else
	{
		position = g_list_find (providers, visible_providers->data);
	}

	position = providers_cycle_backward (providers, position, num);

	if (position == NULL)
	{
		ret = NULL;
	}
	else
	{
		ret = g_list_append (NULL, position->data);
	}

	g_list_free (providers);

	return ret;
}

static void
gtk_source_completion_move_page (GtkSourceCompletion *completion,
                                 GtkScrollStep        step,
                                 gint                 num)
{
	GList *visible_providers = NULL;

	if (step == GTK_SCROLL_ENDS)
	{
		if (num > 0)
		{
			visible_providers = get_last_provider (completion);
		}
		else
		{
			visible_providers = NULL;
		}
	}
	else
	{
		if (step == GTK_SCROLL_PAGES)
		{
			num *= completion->priv->provider_page_size;
		}

		if (num > 0)
		{
			visible_providers = get_next_provider (completion, num);
		}
		else
		{
			visible_providers = get_previous_provider (completion, -1 * num);
		}
	}

	gtk_tree_view_set_model (completion->priv->tree_view_proposals, NULL);
	gtk_tree_view_columns_autosize (completion->priv->tree_view_proposals);

	gtk_source_completion_model_set_visible_providers (completion->priv->model_proposals,
							   visible_providers);

	gtk_tree_view_set_model (completion->priv->tree_view_proposals,
				 GTK_TREE_MODEL (completion->priv->model_proposals));

	update_selection_label (completion);
	check_first_selected (completion);

	g_list_free (visible_providers);
}

/* Begins at 0. Returns -1 if no accelerators available for @iter. */
static gint
get_accel_at_iter (GtkSourceCompletion *completion,
                   GtkTreeIter         *iter)
{
	GtkTreeIter it;
	guint accel;

	if (gtk_source_completion_model_iter_is_header (completion->priv->model_proposals, iter))
	{
		return -1;
	}

	if (!gtk_source_completion_model_first_proposal (completion->priv->model_proposals, &it))
	{
		g_return_val_if_reached (-1);
	}

	for (accel = 0; accel < completion->priv->num_accelerators; accel++)
	{
		if (gtk_source_completion_model_iter_equal (completion->priv->model_proposals,
							    iter,
							    &it))
		{
			return accel;
		}

		if (!gtk_source_completion_model_next_proposal (completion->priv->model_proposals, &it))
		{
			return -1;
		}
	}

	return -1;
}

static void
render_proposal_accelerator_func (GtkTreeViewColumn   *column,
                                  GtkCellRenderer     *cell,
                                  GtkTreeModel        *model,
                                  GtkTreeIter         *iter,
                                  GtkSourceCompletion *completion)
{
	gint accel = get_accel_at_iter (completion, iter);
	gchar *text = NULL;

	if (accel != -1)
	{
		text = g_strdup_printf ("<small><b>%d</b></small>", (accel + 1) % 10);
	}

	g_object_set (cell, "markup", text, NULL);
	g_free (text);
}

static gboolean
activate_by_accelerator (GtkSourceCompletion *completion,
                         gint                 num)
{
	GtkTreeSelection *selection;
	GtkTreeIter iter;
	gint i;

	if (completion->priv->num_accelerators == 0)
	{
		return FALSE;
	}

	num = num == 0 ? 9 : num - 1;

	if (num < 0 || completion->priv->num_accelerators <= (guint)num)
	{
		return FALSE;
	}

	if (!gtk_source_completion_model_first_proposal (completion->priv->model_proposals, &iter))
	{
		return FALSE;
	}

	for (i = 0; i < num; i++)
	{
		if (!gtk_source_completion_model_next_proposal (completion->priv->model_proposals, &iter))
		{
			return FALSE;
		}
	}

	selection = gtk_tree_view_get_selection (completion->priv->tree_view_proposals);
	gtk_tree_selection_select_iter (selection, &iter);
	gtk_source_completion_activate_proposal (completion);

	return TRUE;
}

static void
selection_changed_cb (GtkTreeSelection    *selection,
		      GtkSourceCompletion *completion)
{
	update_proposal_info (completion);

	if (get_selected_proposal (completion, NULL, NULL))
	{
		update_window_position (completion);
	}
}

static gboolean
gtk_source_completion_configure_event (GtkWidget           *widget,
                                       GdkEventConfigure   *event,
                                       GtkSourceCompletion *completion)
{
	update_info_position (completion);
	return FALSE;
}

static gboolean
hide_completion_cb (GtkSourceCompletion *completion)
{
	gtk_source_completion_hide (completion);
	return FALSE;
}

static gboolean
view_key_press_event_cb (GtkSourceView       *view,
			 GdkEventKey         *event,
			 GtkSourceCompletion *completion)
{
	static gboolean mnemonic_keyval_set = FALSE;
	static guint mnemonic_keyval = GDK_KEY_VoidSymbol;
	GdkModifierType mod;
	GtkBindingSet *binding_set;

	if (!gtk_widget_get_visible (GTK_WIDGET (completion->priv->main_window)))
	{
		return FALSE;
	}

	if (G_UNLIKELY (!mnemonic_keyval_set))
	{
		const gchar *label_text = gtk_button_get_label (GTK_BUTTON (completion->priv->info_button));
		GtkWidget *label = gtk_label_new_with_mnemonic (label_text);
		g_object_ref_sink (label);

		mnemonic_keyval = gtk_label_get_mnemonic_keyval (GTK_LABEL (label));
		mnemonic_keyval_set = TRUE;

		g_object_unref (label);
	}

	mod = gtk_accelerator_get_default_mod_mask () & event->state;

	/* Handle info button mnemonic */
	if ((mod & GDK_MOD1_MASK) != 0 &&
	    event->keyval == mnemonic_keyval &&
	    gtk_widget_get_sensitive (GTK_WIDGET (completion->priv->info_button)))
	{
		gtk_toggle_button_set_active (completion->priv->info_button,
		                              !gtk_toggle_button_get_active (completion->priv->info_button));
		return TRUE;
	}

	if ((mod & GDK_MOD1_MASK) != 0 &&
	    GDK_KEY_0 <= event->keyval && event->keyval <= GDK_KEY_9)
	{
		if (activate_by_accelerator (completion, event->keyval - GDK_KEY_0))
		{
			return TRUE;
		}
	}

	binding_set = gtk_binding_set_by_class (GTK_SOURCE_COMPLETION_GET_CLASS (completion));

	if (gtk_binding_set_activate (binding_set,
	                              event->keyval,
	                              event->state,
	                              G_OBJECT (completion)))
	{
		return TRUE;
	}

	return FALSE;
}

static void
buffer_mark_set_cb (GtkTextBuffer       *buffer,
                    GtkTextIter         *iter,
                    GtkTextMark         *mark,
                    GtkSourceCompletion *completion)
{
	if (mark == gtk_text_buffer_get_insert (buffer))
	{
		gtk_source_completion_hide (completion);
	}
}

static void
update_transient_for_info (GObject             *window,
                           GParamSpec          *spec,
                           GtkSourceCompletion *completion)
{
	gtk_window_set_transient_for (GTK_WINDOW (completion->priv->info_window),
				      gtk_window_get_transient_for (GTK_WINDOW (completion->priv->main_window)));
}

static void
replace_model (GtkSourceCompletion *completion)
{
	if (completion->priv->model_proposals != NULL)
	{
		g_object_unref (completion->priv->model_proposals);
	}

	completion->priv->model_proposals = gtk_source_completion_model_new ();

	gtk_source_completion_model_set_show_headers (completion->priv->model_proposals,
				                      completion->priv->show_headers);
}

/* Takes ownership of @providers and @context. */
static void
update_completion (GtkSourceCompletion        *completion,
                   GList                      *providers,
                   GtkSourceCompletionContext *context)
{
	GList *item;
	GtkTextIter context_iter;
	gboolean valid_context;

	/* Copy the parameters, because they can be freed by reset_completion(). */
	GList *providers_copy = g_list_copy (providers);
	GtkSourceCompletionContext *context_copy = g_object_ref_sink (context);

	/* Make sure to first cancel any running completion */
	reset_completion (completion);

	completion->priv->context = context_copy;
	completion->priv->running_providers = g_list_copy (providers_copy);
	completion->priv->active_providers = g_list_copy (providers_copy);

	/* Create a new CompletionModel */
	gtk_tree_view_set_model (completion->priv->tree_view_proposals, NULL);
	gtk_tree_view_columns_autosize (completion->priv->tree_view_proposals);

	replace_model (completion);

	valid_context = gtk_source_completion_context_get_iter (context_copy, &context_iter);

	if (valid_context)
	{
		for (item = providers_copy; item != NULL; item = g_list_next (item))
		{
			GtkSourceCompletionProvider *provider = item->data;
			gtk_source_completion_provider_populate (provider, context_copy);
		}
	}

	g_list_free (providers_copy);
}

static gboolean
auto_completion_final (GtkSourceCompletion *completion)
{
	/* Store and set to NULL because update_completion will cancel the last
	   completion, which will also remove the timeout source which in turn
	   would free these guys */
	GtkSourceCompletionContext *context = completion->priv->auto_completion_context;
	GList *selection = completion->priv->auto_completion_selection;

	completion->priv->auto_completion_context = NULL;
	completion->priv->auto_completion_selection = NULL;

	update_completion (completion, selection, context);

	g_list_free (selection);
	g_object_unref (context);
	return G_SOURCE_REMOVE;
}

static void
auto_completion_destroy (GtkSourceCompletion *completion)
{
	if (completion->priv->auto_completion_context != NULL)
	{
		g_object_unref (completion->priv->auto_completion_context);
		completion->priv->auto_completion_context = NULL;
	}

	g_list_free (completion->priv->auto_completion_selection);
	completion->priv->auto_completion_selection = NULL;
}

static void
start_interactive_completion (GtkSourceCompletion *completion,
			      GtkTextIter         *iter)
{
	GtkSourceCompletionContext *context;
	GList *providers;
	gint delay;

	reset_completion (completion);

	/* Create the context */
	context = gtk_source_completion_create_context (completion, iter);
	g_object_ref_sink (context);

	g_object_set (context,
	              "activation",
	              GTK_SOURCE_COMPLETION_ACTIVATION_INTERACTIVE,
	              NULL);

	g_signal_emit (completion, signals[POPULATE_CONTEXT], 0, context);

	/* Select providers */
	providers = select_providers (completion->priv->providers, context);

	if (providers == NULL)
	{
		g_object_unref (context);
		return;
	}

	/* Create the timeout */
	delay = minimum_auto_complete_delay (completion, providers);
	completion->priv->auto_completion_context = context;
	completion->priv->auto_completion_selection = providers;

	completion->priv->show_timed_out_id =
		g_timeout_add_full (G_PRIORITY_DEFAULT,
		                    delay,
		                    (GSourceFunc)auto_completion_final,
		                    completion,
		                    (GDestroyNotify)auto_completion_destroy);
}

static void
update_active_completion (GtkSourceCompletion *completion,
			  GtkTextIter         *new_iter)
{
	GList *selected_providers;

	g_assert (completion->priv->context != NULL);

	g_object_set (completion->priv->context,
		      "iter", new_iter,
		      NULL);

	selected_providers = select_providers (completion->priv->providers,
					       completion->priv->context);

	if (selected_providers != NULL)
	{
		update_completion (completion,
				   selected_providers,
				   completion->priv->context);

		g_list_free (selected_providers);
	}
	else
	{
		gtk_source_completion_hide (completion);
	}
}

static void
buffer_delete_range_cb (GtkTextBuffer       *buffer,
                        GtkTextIter         *start,
                        GtkTextIter         *end,
                        GtkSourceCompletion *completion)
{
	if (completion->priv->context != NULL)
	{
		update_active_completion (completion, start);
	}
}

static void
buffer_insert_text_cb (GtkTextBuffer       *buffer,
                       GtkTextIter         *location,
                       gchar               *text,
                       gint                 len,
                       GtkSourceCompletion *completion)
{
	if (completion->priv->context != NULL)
	{
		update_active_completion (completion, location);
	}
	else
	{
		start_interactive_completion (completion, location);
	}
}

static void
update_bottom_bar_visibility (GtkSourceCompletion *completion)
{
	GList *providers;
	guint nb_providers;

	providers = gtk_source_completion_model_get_providers (completion->priv->model_proposals);
	nb_providers = g_list_length (providers);
	g_list_free (providers);

	if (nb_providers > 1)
	{
		gtk_widget_show (completion->priv->bottom_bar);
		return;
	}

	if (gtk_source_completion_model_has_info (completion->priv->model_proposals))
	{
		gtk_widget_show (completion->priv->bottom_bar);
	}
	else
	{
		gtk_widget_hide (completion->priv->bottom_bar);
	}
}

static void
style_context_changed (GtkStyleContext     *style_context,
		       GtkSourceCompletion *completion)
{
	PangoFontDescription *font_desc = NULL;

	gtk_style_context_save (style_context);
	gtk_style_context_set_state (style_context, GTK_STATE_FLAG_NORMAL);

	gtk_style_context_get (style_context,
			       gtk_style_context_get_state (style_context),
			       GTK_STYLE_PROPERTY_FONT, &font_desc,
			       NULL);

	gtk_style_context_restore (style_context);

	/*
	 * Work around issue where when a proposal provides "<b>markup</b>" and
	 * the weight is set in the font description, the <b> markup will not
	 * have it's weight respected. This seems to be happening because the
	 * weight mask is getting set in pango_font_description_from_string()
	 * even if the the value is set to normal. That matter is complicated
	 * because PangoAttrFontDesc and PangoAttrWeight will both have the
	 * same starting offset in the PangoLayout.
	 * https://bugzilla.gnome.org/show_bug.cgi?id=755968
	 */
	if (PANGO_WEIGHT_NORMAL == pango_font_description_get_weight (font_desc))
	{
		pango_font_description_unset_fields (font_desc, PANGO_FONT_MASK_WEIGHT);
	}

	g_object_set (completion->priv->cell_renderer_proposal,
		      "font-desc", font_desc,
		      NULL);

	pango_font_description_free (font_desc);
}

static void
populating_done (GtkSourceCompletion        *completion,
                 GtkSourceCompletionContext *context)
{
	if (gtk_source_completion_model_is_empty (completion->priv->model_proposals, TRUE))
	{
		gtk_source_completion_hide (completion);
		return;
	}

	gtk_tree_view_set_model (completion->priv->tree_view_proposals,
				 GTK_TREE_MODEL (completion->priv->model_proposals));

	update_selection_label (completion);
	update_bottom_bar_visibility (completion);

	if (!check_first_selected (completion))
	{
		/* Update the window position only if the first proposal is not
		 * selected, because if it is selected, the window position will
		 * already be updated.
		 */
		update_window_position (completion);
	}

	if (!gtk_widget_get_visible (GTK_WIDGET (completion->priv->main_window)))
	{
		g_signal_emit (completion, signals[SHOW], 0);
	}
}

static void
gtk_source_completion_dispose (GObject *object)
{
	GtkSourceCompletion *completion = GTK_SOURCE_COMPLETION (object);

	reset_completion (completion);

	if (completion->priv->view != NULL)
	{
		g_object_remove_weak_pointer (G_OBJECT (completion->priv->view),
					      (gpointer *)&completion->priv->view);

		completion->priv->view = NULL;
	}

	g_clear_object (&completion->priv->buffer);
	g_clear_object (&completion->priv->default_info);
	g_clear_object (&completion->priv->model_proposals);

	if (completion->priv->info_window != NULL)
	{
		gtk_widget_destroy (GTK_WIDGET (completion->priv->info_window));
		completion->priv->info_window = NULL;
	}

	if (completion->priv->main_window != NULL)
	{
		gtk_widget_destroy (GTK_WIDGET (completion->priv->main_window));
		completion->priv->main_window = NULL;
	}

	g_list_free_full (completion->priv->providers, g_object_unref);
	completion->priv->providers = NULL;

	G_OBJECT_CLASS (gtk_source_completion_parent_class)->dispose (object);
}

/* Unconditionnally block interactive completion, without taking into account
 * priv->block_interactive_num.
 * g_signal_handlers_block_by_func() has a counter too, so you may think that
 * block_interactive_num is useless. But it is useful when the buffer changes,
 * to keep the signal handler blocked on the new buffer.
 */
static void
block_interactive (GtkSourceCompletion *completion)
{
	g_signal_handlers_block_by_func (completion->priv->buffer,
					 buffer_insert_text_cb,
					 completion);

	g_signal_handlers_block_by_func (completion->priv->buffer,
					 buffer_delete_range_cb,
					 completion);
}

static void
connect_buffer (GtkSourceCompletion *completion)
{
	GtkTextBuffer *new_buffer = NULL;

	if (completion->priv->view != NULL)
	{
		new_buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (completion->priv->view));
	}

	if (completion->priv->buffer == new_buffer)
	{
		return;
	}

	if (completion->priv->buffer != NULL)
	{
		g_signal_handlers_disconnect_by_func (completion->priv->buffer,
						      buffer_mark_set_cb,
						      completion);

		g_signal_handlers_disconnect_by_func (completion->priv->buffer,
						      gtk_source_completion_block_interactive,
						      completion);

		g_signal_handlers_disconnect_by_func (completion->priv->buffer,
						      gtk_source_completion_unblock_interactive,
						      completion);

		g_signal_handlers_disconnect_by_func (completion->priv->buffer,
						      buffer_delete_range_cb,
						      completion);

		g_signal_handlers_disconnect_by_func (completion->priv->buffer,
						      buffer_insert_text_cb,
						      completion);

		reset_completion (completion);

		g_object_unref (completion->priv->buffer);
	}

	completion->priv->buffer = new_buffer;

	if (new_buffer == NULL)
	{
		return;
	}

	g_object_ref (completion->priv->buffer);

	g_signal_connect_object (new_buffer,
				 "mark-set",
				 G_CALLBACK (buffer_mark_set_cb),
				 completion,
				 G_CONNECT_AFTER);

	g_signal_connect_object (new_buffer,
		                 "undo",
		                 G_CALLBACK (gtk_source_completion_block_interactive),
		                 completion,
		                 G_CONNECT_SWAPPED);

	g_signal_connect_object (new_buffer,
		                 "undo",
		                 G_CALLBACK (gtk_source_completion_unblock_interactive),
		                 completion,
		                 G_CONNECT_SWAPPED | G_CONNECT_AFTER);

	g_signal_connect_object (new_buffer,
		                 "redo",
		                 G_CALLBACK (gtk_source_completion_block_interactive),
		                 completion,
		                 G_CONNECT_SWAPPED);

	g_signal_connect_object (new_buffer,
		                 "redo",
		                 G_CALLBACK (gtk_source_completion_unblock_interactive),
		                 completion,
		                 G_CONNECT_SWAPPED | G_CONNECT_AFTER);

	g_signal_connect_object (new_buffer,
				 "delete-range",
				 G_CALLBACK (buffer_delete_range_cb),
				 completion,
				 G_CONNECT_AFTER);

	g_signal_connect_object (new_buffer,
				 "insert-text",
				 G_CALLBACK (buffer_insert_text_cb),
				 completion,
				 G_CONNECT_AFTER);

	if (completion->priv->block_interactive_num > 0)
	{
		block_interactive (completion);
	}
}

static void
connect_view (GtkSourceCompletion *completion,
	      GtkSourceView       *view)
{
	g_assert (completion->priv->view == NULL);
	completion->priv->view = view;

	g_object_add_weak_pointer (G_OBJECT (view),
				   (gpointer *)&completion->priv->view);

	g_signal_connect_object (completion->priv->view,
				 "focus-out-event",
				 G_CALLBACK (hide_completion_cb),
				 completion,
				 G_CONNECT_SWAPPED);

	g_signal_connect_object (completion->priv->view,
				 "button-press-event",
				 G_CALLBACK (hide_completion_cb),
				 completion,
				 G_CONNECT_SWAPPED);

	g_signal_connect_object (completion->priv->view,
				 "key-press-event",
				 G_CALLBACK (view_key_press_event_cb),
				 completion,
				 0);

	g_signal_connect_object (completion->priv->view,
				 "paste-clipboard",
				 G_CALLBACK (gtk_source_completion_block_interactive),
				 completion,
				 G_CONNECT_SWAPPED);

	g_signal_connect_object (completion->priv->view,
				 "paste-clipboard",
				 G_CALLBACK (gtk_source_completion_unblock_interactive),
				 completion,
				 G_CONNECT_SWAPPED | G_CONNECT_AFTER);

	connect_buffer (completion);

	g_signal_connect_object (completion->priv->view,
				 "notify::buffer",
				 G_CALLBACK (connect_buffer),
				 completion,
				 G_CONNECT_SWAPPED);
}

static void
gtk_source_completion_get_property (GObject    *object,
				    guint       prop_id,
				    GValue     *value,
				    GParamSpec *pspec)
{
	GtkSourceCompletion *completion;

	g_return_if_fail (GTK_SOURCE_IS_COMPLETION (object));

	completion = GTK_SOURCE_COMPLETION (object);

	switch (prop_id)
	{
		case PROP_VIEW:
			g_value_set_object (value, completion->priv->view);
			break;
		case PROP_REMEMBER_INFO_VISIBILITY:
			g_value_set_boolean (value, completion->priv->remember_info_visibility);
			break;
		case PROP_SELECT_ON_SHOW:
			g_value_set_boolean (value, completion->priv->select_on_show);
			break;
		case PROP_SHOW_HEADERS:
			g_value_set_boolean (value, completion->priv->show_headers);
			break;
		case PROP_SHOW_ICONS:
			g_value_set_boolean (value, completion->priv->show_icons);
			break;
		case PROP_ACCELERATORS:
			g_value_set_uint (value, completion->priv->num_accelerators);
			break;
		case PROP_AUTO_COMPLETE_DELAY:
			g_value_set_uint (value, completion->priv->auto_complete_delay);
			break;
		case PROP_PROPOSAL_PAGE_SIZE:
			g_value_set_uint (value, completion->priv->proposal_page_size);
			break;
		case PROP_PROVIDER_PAGE_SIZE:
			g_value_set_uint (value, completion->priv->provider_page_size);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_completion_set_property (GObject      *object,
				    guint         prop_id,
				    const GValue *value,
				    GParamSpec   *pspec)
{
	GtkSourceCompletion *completion;

	g_return_if_fail (GTK_SOURCE_IS_COMPLETION (object));

	completion = GTK_SOURCE_COMPLETION (object);

	switch (prop_id)
	{
		case PROP_VIEW:
			connect_view (completion, g_value_get_object (value));
			break;
		case PROP_REMEMBER_INFO_VISIBILITY:
			completion->priv->remember_info_visibility = g_value_get_boolean (value);
			break;
		case PROP_SELECT_ON_SHOW:
			completion->priv->select_on_show = g_value_get_boolean (value);
			break;
		case PROP_SHOW_HEADERS:
			completion->priv->show_headers = g_value_get_boolean (value);

			if (completion->priv->model_proposals != NULL)
			{
				gtk_source_completion_model_set_show_headers (completion->priv->model_proposals,
				                                              completion->priv->show_headers);
			}
			break;
		case PROP_SHOW_ICONS:
			completion->priv->show_icons = g_value_get_boolean (value);
			break;
		case PROP_ACCELERATORS:
			completion->priv->num_accelerators = g_value_get_uint (value);
			break;
		case PROP_AUTO_COMPLETE_DELAY:
			completion->priv->auto_complete_delay = g_value_get_uint (value);
			break;
		case PROP_PROPOSAL_PAGE_SIZE:
			completion->priv->proposal_page_size = g_value_get_uint (value);
			break;
		case PROP_PROVIDER_PAGE_SIZE:
			completion->priv->provider_page_size = g_value_get_uint (value);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static gboolean
selection_func (GtkTreeSelection    *selection,
                GtkTreeModel        *model,
                GtkTreePath         *path,
                gboolean             path_currently_selected,
                GtkSourceCompletion *completion)
{
	GtkTreeIter iter;

	gtk_tree_model_get_iter (model, &iter, path);

	if (gtk_source_completion_model_iter_is_header (completion->priv->model_proposals,
	                                                &iter))
	{
		/* A header must never be selected */
		g_return_val_if_fail (!path_currently_selected, TRUE);
		return FALSE;
	}
	else
	{
		return TRUE;
	}
}

static void
accelerators_notify_cb (GtkSourceCompletion *completion,
			GParamSpec          *pspec,
			GtkTreeViewColumn   *column)
{
	gtk_tree_view_column_set_visible (column, completion->priv->num_accelerators > 0);
}

static void
cell_icon_func (GtkTreeViewColumn *column,
                GtkCellRenderer   *cell,
                GtkTreeModel      *model,
                GtkTreeIter       *iter,
                gpointer           data)
{
	GdkPixbuf *pixbuf;
	gchar *icon_name;
	GIcon *gicon;
	gboolean set = FALSE;

	gtk_tree_model_get (model, iter,
	                    GTK_SOURCE_COMPLETION_MODEL_COLUMN_ICON, &pixbuf,
	                    GTK_SOURCE_COMPLETION_MODEL_COLUMN_ICON_NAME, &icon_name,
	                    GTK_SOURCE_COMPLETION_MODEL_COLUMN_GICON, &gicon,
	                    -1);

	if (pixbuf != NULL)
	{
		g_object_set (cell, "pixbuf", pixbuf, NULL);
		g_object_unref (pixbuf);
		set = TRUE;
	}

	if (icon_name != NULL)
	{
		g_object_set (cell, "icon-name", icon_name, NULL);
		g_free (icon_name);
		set = TRUE;
	}

	if (gicon != NULL)
	{
		g_object_set (cell, "gicon", gicon, NULL);
		g_object_unref (gicon);
		set = TRUE;
	}

	if (!set)
	{
		g_object_set (cell, "icon-name", NULL, NULL);
	}
}

static void
init_tree_view (GtkSourceCompletion *completion,
		GtkBuilder          *builder)
{
	GtkTreeSelection *selection;
	GtkTreeViewColumn *column;
	GtkCellRenderer *cell_renderer;
	GtkStyleContext *style_context;
	GdkRGBA* background_color = NULL;
	GdkRGBA foreground_color;

	completion->priv->tree_view_proposals = GTK_TREE_VIEW (gtk_builder_get_object (builder, "tree_view_proposals"));

	g_signal_connect_swapped (completion->priv->tree_view_proposals,
				  "row-activated",
				  G_CALLBACK (gtk_source_completion_activate_proposal),
				  completion);

	g_signal_connect_swapped (completion->priv->tree_view_proposals,
				  "size-allocate",
				  G_CALLBACK (gtk_source_completion_proposals_size_allocate),
				  completion);

	/* Selection */

	selection = gtk_tree_view_get_selection (completion->priv->tree_view_proposals);

	gtk_tree_selection_set_select_function (selection,
	                                        (GtkTreeSelectionFunc)selection_func,
	                                        completion,
	                                        NULL);

	g_signal_connect (selection,
			  "changed",
			  G_CALLBACK (selection_changed_cb),
			  completion);

	/* Icon cell renderer */

	cell_renderer = GTK_CELL_RENDERER (gtk_builder_get_object (builder, "cell_renderer_icon"));

	column = GTK_TREE_VIEW_COLUMN (gtk_builder_get_object (builder, "tree_view_column_icon"));

	/* We use a cell function instead of plain attributes for the icon since
	 * the pixbuf renderer will not renderer any icon if pixbuf is set to NULL.
	 * See https://bugzilla.gnome.org/show_bug.cgi?id=753510
	 */
	gtk_tree_view_column_set_cell_data_func (column,
	                                         cell_renderer,
	                                         cell_icon_func,
	                                         NULL,
	                                         NULL);

	gtk_tree_view_column_set_attributes (column, cell_renderer,
					     "cell-background-set", GTK_SOURCE_COMPLETION_MODEL_COLUMN_IS_HEADER,
					     NULL);

	style_context = gtk_widget_get_style_context (GTK_WIDGET (completion->priv->tree_view_proposals));

	gtk_style_context_save (style_context);
	gtk_style_context_set_state (style_context, GTK_STATE_FLAG_INSENSITIVE);

	gtk_style_context_get (style_context,
			       gtk_style_context_get_state (style_context),
			       "background-color", &background_color,
			       NULL);

	gtk_style_context_get_color (style_context,
				     gtk_style_context_get_state (style_context),
				     &foreground_color);

	gtk_style_context_restore (style_context);

	g_object_set (cell_renderer,
	              "cell-background-rgba", background_color,
	              NULL);

	g_object_bind_property (completion, "show-icons",
				cell_renderer, "visible",
				G_BINDING_SYNC_CREATE);

	/* Proposal text cell renderer */

	cell_renderer = GTK_CELL_RENDERER (gtk_builder_get_object (builder, "cell_renderer_proposal"));
	completion->priv->cell_renderer_proposal = cell_renderer;

	column = GTK_TREE_VIEW_COLUMN (gtk_builder_get_object (builder, "tree_view_column_proposal"));

	gtk_tree_view_column_set_attributes (column, cell_renderer,
					     "markup", GTK_SOURCE_COMPLETION_MODEL_COLUMN_MARKUP,
					     "cell-background-set", GTK_SOURCE_COMPLETION_MODEL_COLUMN_IS_HEADER,
					     "foreground-set", GTK_SOURCE_COMPLETION_MODEL_COLUMN_IS_HEADER,
					     NULL);

	g_object_set (cell_renderer,
	              "foreground-rgba", &foreground_color,
	              "cell-background-rgba", background_color,
	              NULL);

	/* Accelerators cell renderer */

	column = GTK_TREE_VIEW_COLUMN (gtk_builder_get_object (builder, "tree_view_column_accelerator"));

	cell_renderer = GTK_CELL_RENDERER (gtk_builder_get_object (builder, "cell_renderer_accelerator"));

	gtk_tree_view_column_set_attributes (column,
					     cell_renderer,
					     "cell-background-set", GTK_SOURCE_COMPLETION_MODEL_COLUMN_IS_HEADER,
					     NULL);

	g_object_set (cell_renderer,
	              "foreground-rgba", &foreground_color,
	              "cell-background-rgba", background_color,
		      NULL);

	gtk_tree_view_column_set_cell_data_func (column,
	                                         cell_renderer,
	                                         (GtkTreeCellDataFunc)render_proposal_accelerator_func,
	                                         completion,
	                                         NULL);

	g_signal_connect_object (completion,
				 "notify::accelerators",
				 G_CALLBACK (accelerators_notify_cb),
				 column,
				 0);

	gdk_rgba_free (background_color);
}

static void
init_main_window (GtkSourceCompletion *completion,
		  GtkBuilder          *builder)
{
	if (completion->priv->view == NULL)
	{
		return;
	}

	completion->priv->main_window = GTK_SOURCE_COMPLETION_INFO (gtk_builder_get_object (builder, "main_window"));
	completion->priv->info_button = GTK_TOGGLE_BUTTON (gtk_builder_get_object (builder, "info_button"));
	completion->priv->selection_image = GTK_IMAGE (gtk_builder_get_object (builder, "selection_image"));
	completion->priv->selection_label = GTK_LABEL (gtk_builder_get_object (builder, "selection_label"));
	completion->priv->bottom_bar = GTK_WIDGET (gtk_builder_get_object (builder, "bottom_bar"));

	gtk_container_set_border_width (GTK_CONTAINER (completion->priv->main_window), 0);

	gtk_window_set_attached_to (GTK_WINDOW (completion->priv->main_window),
				    GTK_WIDGET (completion->priv->view));

	g_signal_connect (completion->priv->main_window,
			  "configure-event",
			  G_CALLBACK (gtk_source_completion_configure_event),
			  completion);

	g_signal_connect_swapped (completion->priv->main_window,
				  "size-allocate",
				  G_CALLBACK (update_window_position),
				  completion);

	g_signal_connect (completion->priv->main_window,
			  "delete-event",
			  G_CALLBACK (gtk_widget_hide_on_delete),
			  NULL);

	g_signal_connect (completion->priv->main_window,
	                  "notify::transient-for",
	                  G_CALLBACK (update_transient_for_info),
	                  completion);

	g_signal_connect_swapped (completion->priv->info_button,
				  "toggled",
				  G_CALLBACK (update_info_window_visibility),
				  completion);
}

static void
init_info_window (GtkSourceCompletion *completion)
{
	completion->priv->info_window = gtk_source_completion_info_new ();
	g_object_ref_sink (completion->priv->info_window);

	gtk_window_set_attached_to (GTK_WINDOW (completion->priv->info_window),
				    GTK_WIDGET (completion->priv->main_window));

	g_signal_connect_swapped (completion->priv->info_window,
				  "size-allocate",
				  G_CALLBACK (update_info_position),
				  completion);

	/* Default info widget */

	completion->priv->default_info = GTK_LABEL (gtk_label_new (NULL));
	g_object_ref_sink (completion->priv->default_info);

	gtk_widget_show (GTK_WIDGET (completion->priv->default_info));
}

static void
connect_style_context (GtkSourceCompletion *completion)
{
	GtkStyleContext *style_context;

	if (completion->priv->view == NULL)
	{
		return;
	}

	style_context = gtk_widget_get_style_context (GTK_WIDGET (completion->priv->view));

	g_signal_connect_object (style_context,
				 "changed",
				 G_CALLBACK (style_context_changed),
				 completion,
				 G_CONNECT_AFTER);

	style_context_changed (style_context, completion);
}

static void
gtk_source_completion_constructed (GObject *object)
{
	GtkSourceCompletion *completion = GTK_SOURCE_COMPLETION (object);
	GError *error = NULL;
	GtkBuilder *builder = gtk_builder_new ();
	GtkSourceCompletionContainer *container = _gtk_source_completion_container_new ();
	g_object_ref_sink (container);

	gtk_builder_set_translation_domain (builder, GETTEXT_PACKAGE);

	/* GtkSourceCompletionContainer is a private type. */
	gtk_builder_expose_object (builder, "completion_container", G_OBJECT (container));

	gtk_builder_add_from_resource (builder,
				       "/org/gnome/gtksourceview/ui/gtksourcecompletion.ui",
				       &error);

	if (error != NULL)
	{
		g_error ("Error while loading the completion UI: %s", error->message);
	}

	init_tree_view (completion, builder);
	init_main_window (completion, builder);
	init_info_window (completion);
	connect_style_context (completion);

	g_object_unref (builder);
	g_object_unref (container);

	G_OBJECT_CLASS (gtk_source_completion_parent_class)->constructed (object);
}

static void
gtk_source_completion_class_init (GtkSourceCompletionClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	GtkBindingSet *binding_set;

	object_class->get_property = gtk_source_completion_get_property;
	object_class->set_property = gtk_source_completion_set_property;
	object_class->dispose = gtk_source_completion_dispose;
	object_class->constructed = gtk_source_completion_constructed;

	klass->show = gtk_source_completion_show_default;
	klass->hide = gtk_source_completion_hide_default;

	klass->move_cursor = gtk_source_completion_move_cursor;
	klass->move_page = gtk_source_completion_move_page;
	klass->activate_proposal = gtk_source_completion_activate_proposal;

	/**
	 * GtkSourceCompletion:view:
	 *
	 * The #GtkSourceView bound to the completion object.
	 */
	g_object_class_install_property (object_class,
					 PROP_VIEW,
					 g_param_spec_object ("view",
							      "View",
							      "The GtkSourceView bound to the completion",
							      GTK_SOURCE_TYPE_VIEW,
							      G_PARAM_READWRITE |
							      G_PARAM_CONSTRUCT_ONLY |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletion:remember-info-visibility:
	 *
	 * Determines whether the visibility of the info window should be
	 * saved when the completion is hidden, and restored when the completion
	 * is shown again.
	 */
	g_object_class_install_property (object_class,
					 PROP_REMEMBER_INFO_VISIBILITY,
					 g_param_spec_boolean ("remember-info-visibility",
							       "Remember Info Visibility",
							       "Remember the last info window visibility state",
							       FALSE,
							       G_PARAM_READWRITE |
							       G_PARAM_CONSTRUCT |
							       G_PARAM_STATIC_STRINGS));
	/**
	 * GtkSourceCompletion:select-on-show:
	 *
	 * Determines whether the first proposal should be selected when the
	 * completion is first shown.
	 */
	g_object_class_install_property (object_class,
					 PROP_SELECT_ON_SHOW,
					 g_param_spec_boolean ("select-on-show",
							       "Select on Show",
							       "Select first proposal when completion is shown",
							       TRUE,
							       G_PARAM_READWRITE |
							       G_PARAM_CONSTRUCT |
							       G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletion:show-headers:
	 *
	 * Determines whether provider headers should be shown in the proposal
	 * list. It can be useful to disable when there is only one provider.
	 */
	g_object_class_install_property (object_class,
					 PROP_SHOW_HEADERS,
					 g_param_spec_boolean ("show-headers",
							       "Show Headers",
							       "Show provider headers when proposals from multiple providers are available",
							       TRUE,
							       G_PARAM_READWRITE |
							       G_PARAM_CONSTRUCT |
							       G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletion:show-icons:
	 *
	 * Determines whether provider and proposal icons should be shown in
	 * the completion popup.
	 */
	g_object_class_install_property (object_class,
					 PROP_SHOW_ICONS,
					 g_param_spec_boolean ("show-icons",
							       "Show Icons",
							       "Show provider and proposal icons in the completion popup",
							       TRUE,
							       G_PARAM_READWRITE |
							       G_PARAM_CONSTRUCT |
							       G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletion:accelerators:
	 *
	 * Number of keyboard accelerators to show for the first proposals. For
	 * example, to activate the first proposal, the user can press
	 * <keycombo><keycap>Alt</keycap><keycap>1</keycap></keycombo>.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_ACCELERATORS,
	                                 g_param_spec_uint ("accelerators",
	                                                    "Accelerators",
	                                                    "Number of proposal accelerators to show",
	                                                    0,
	                                                    10,
	                                                    5,
	                                                    G_PARAM_READWRITE |
							    G_PARAM_CONSTRUCT |
							    G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletion:auto-complete-delay:
	 *
	 * Determines the popup delay (in milliseconds) at which the completion
	 * will be shown for interactive completion.
	 */
	g_object_class_install_property (object_class,
					 PROP_AUTO_COMPLETE_DELAY,
					 g_param_spec_uint ("auto-complete-delay",
							    "Auto Complete Delay",
							    "Completion popup delay for interactive completion",
							    0,
							    G_MAXUINT,
							    250,
							    G_PARAM_READWRITE |
							    G_PARAM_CONSTRUCT |
							    G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletion:provider-page-size:
	 *
	 * The scroll page size of the provider pages in the completion window.
	 *
	 * See the #GtkSourceCompletion::move-page signal.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_PROVIDER_PAGE_SIZE,
	                                 g_param_spec_uint ("provider-page-size",
	                                                    "Provider Page Size",
	                                                    "Provider scrolling page size",
	                                                    1,
	                                                    G_MAXUINT,
	                                                    5,
	                                                    G_PARAM_READWRITE |
							    G_PARAM_CONSTRUCT |
							    G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletion:proposal-page-size:
	 *
	 * The scroll page size of the proposals in the completion window. In
	 * other words, when <keycap>PageDown</keycap> or
	 * <keycap>PageUp</keycap> is pressed, the selected
	 * proposal becomes the one which is located one page size backward or
	 * forward.
	 *
	 * See also the #GtkSourceCompletion::move-cursor signal.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_PROPOSAL_PAGE_SIZE,
	                                 g_param_spec_uint ("proposal-page-size",
	                                                    "Proposal Page Size",
	                                                    "Proposal scrolling page size",
	                                                    1,
	                                                    G_MAXUINT,
	                                                    5,
	                                                    G_PARAM_READWRITE |
							    G_PARAM_CONSTRUCT |
							    G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletion::show:
	 * @completion: The #GtkSourceCompletion who emits the signal
	 *
	 * Emitted when the completion window is shown. The default handler
	 * will actually show the window.
	 */
	signals[SHOW] =
		g_signal_new ("show",
			      G_TYPE_FROM_CLASS (klass),
			      G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
			      G_STRUCT_OFFSET (GtkSourceCompletionClass, show),
			      NULL, NULL, NULL,
			      G_TYPE_NONE, 0);


	/**
	 * GtkSourceCompletion::hide:
	 * @completion: The #GtkSourceCompletion who emits the signal
	 *
	 * Emitted when the completion window is hidden. The default handler
	 * will actually hide the window.
	 */
	signals[HIDE] =
		g_signal_new ("hide",
			      G_TYPE_FROM_CLASS (klass),
			      G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
			      G_STRUCT_OFFSET (GtkSourceCompletionClass, hide),
			      NULL, NULL, NULL,
			      G_TYPE_NONE, 0);

	/**
	 * GtkSourceCompletion::populate-context:
	 * @completion: The #GtkSourceCompletion who emits the signal
	 * @context: The #GtkSourceCompletionContext for the current completion
	 *
	 * Emitted just before starting to populate the completion with providers.
	 * You can use this signal to add additional attributes in the context.
	 */
	signals[POPULATE_CONTEXT] =
		g_signal_new ("populate-context",
		              G_TYPE_FROM_CLASS (klass),
		              G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		              G_STRUCT_OFFSET (GtkSourceCompletionClass, populate_context),
		              NULL, NULL, NULL,
		              G_TYPE_NONE,
		              1,
		              GTK_SOURCE_TYPE_COMPLETION_CONTEXT);

	/* Actions */

	/**
	 * GtkSourceCompletion::move-cursor:
	 * @completion: The #GtkSourceCompletion who emits the signal
	 * @step: The #GtkScrollStep by which to move the cursor
	 * @num: The amount of steps to move the cursor
	 *
	 * The #GtkSourceCompletion::move-cursor signal is a keybinding
	 * signal which gets emitted when the user initiates a cursor
	 * movement.
	 *
	 * The <keycap>Up</keycap>, <keycap>Down</keycap>,
	 * <keycap>PageUp</keycap>, <keycap>PageDown</keycap>,
	 * <keycap>Home</keycap> and <keycap>End</keycap> keys are bound to the
	 * normal behavior expected by those keys.
	 *
	 * When @step is equal to %GTK_SCROLL_PAGES, the page size is defined by
	 * the #GtkSourceCompletion:proposal-page-size property. It is used for
	 * the <keycap>PageDown</keycap> and <keycap>PageUp</keycap> keys.
	 *
	 * Applications should not connect to it, but may emit it with
	 * g_signal_emit_by_name() if they need to control the cursor
	 * programmatically.
	 */
	signals [MOVE_CURSOR] =
		g_signal_new ("move-cursor",
			      G_TYPE_FROM_CLASS (klass),
			      G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
			      G_STRUCT_OFFSET (GtkSourceCompletionClass, move_cursor),
			      NULL, NULL, NULL,
			      G_TYPE_NONE,
			      2,
			      GTK_TYPE_SCROLL_STEP,
			      G_TYPE_INT);

	/**
	 * GtkSourceCompletion::move-page:
	 * @completion: The #GtkSourceCompletion who emits the signal
	 * @step: The #GtkScrollStep by which to move the page
	 * @num: The amount of steps to move the page
	 *
	 * The #GtkSourceCompletion::move-page signal is a keybinding
	 * signal which gets emitted when the user initiates a page
	 * movement (i.e. switches between provider pages).
	 *
	 * <keycombo><keycap>Control</keycap><keycap>Left</keycap></keycombo>
	 * is for going to the previous provider.
	 * <keycombo><keycap>Control</keycap><keycap>Right</keycap></keycombo>
	 * is for going to the next provider.
	 * <keycombo><keycap>Control</keycap><keycap>Home</keycap></keycombo>
	 * is for displaying all the providers.
	 * <keycombo><keycap>Control</keycap><keycap>End</keycap></keycombo>
	 * is for going to the last provider.
	 *
	 * When @step is equal to #GTK_SCROLL_PAGES, the page size is defined by
	 * the #GtkSourceCompletion:provider-page-size property.
	 *
	 * Applications should not connect to it, but may emit it with
	 * g_signal_emit_by_name() if they need to control the page selection
	 * programmatically.
	 */
	signals [MOVE_PAGE] =
		g_signal_new ("move-page",
			      G_TYPE_FROM_CLASS (klass),
			      G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
			      G_STRUCT_OFFSET (GtkSourceCompletionClass, move_page),
			      NULL, NULL, NULL,
			      G_TYPE_NONE,
			      2,
			      GTK_TYPE_SCROLL_STEP,
			      G_TYPE_INT);

	/**
	 * GtkSourceCompletion::activate-proposal:
	 * @completion: The #GtkSourceCompletion who emits the signal
	 *
	 * The #GtkSourceCompletion::activate-proposal signal is a
	 * keybinding signal which gets emitted when the user initiates
	 * a proposal activation.
	 *
	 * Applications should not connect to it, but may emit it with
	 * g_signal_emit_by_name() if they need to control the proposal
	 * activation programmatically.
	 */
	signals [ACTIVATE_PROPOSAL] =
		g_signal_new ("activate-proposal",
			      G_TYPE_FROM_CLASS (klass),
			      G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
			      G_STRUCT_OFFSET (GtkSourceCompletionClass, activate_proposal),
			      NULL, NULL, NULL,
			      G_TYPE_NONE, 0);

	/* Key bindings */
	binding_set = gtk_binding_set_by_class (klass);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Down,
				      0,
				      "move-cursor",
				      2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_STEPS,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Page_Down,
				      0,
				      "move-cursor",
				      2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_PAGES,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Up,
				      0,
				      "move-cursor",
				      2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_STEPS,
				      G_TYPE_INT, -1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Page_Up,
				      0,
				      "move-cursor",
				      2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_PAGES,
				      G_TYPE_INT, -1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Home,
				      0,
				      "move-cursor",
				      2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_ENDS,
				      G_TYPE_INT, -1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_End,
				      0,
				      "move-cursor",
				      2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_ENDS,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Escape,
				      0,
				      "hide",
				      0);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Return,
				      0,
				      "activate-proposal",
				      0);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Tab,
				      0,
				      "activate-proposal",
				      0);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Left,
				      GDK_CONTROL_MASK,
				      "move-page",
				      2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_STEPS,
				      G_TYPE_INT, -1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Right,
				      GDK_CONTROL_MASK,
				      "move-page",
				      2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_STEPS,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Home,
				      GDK_CONTROL_MASK,
				      "move-page",
				      2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_ENDS,
				      G_TYPE_INT, -1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_End,
				      GDK_CONTROL_MASK,
				      "move-page",
				      2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_ENDS,
				      G_TYPE_INT, 1);
}

static void
gtk_source_completion_init (GtkSourceCompletion *completion)
{
	completion->priv = gtk_source_completion_get_instance_private (completion);
}

static GObject *
gtk_source_completion_buildable_get_internal_child (GtkBuildable *buildable,
						    GtkBuilder   *builder,
						    const gchar  *childname)
{
	GtkSourceCompletion *completion = GTK_SOURCE_COMPLETION (buildable);

	if (g_strcmp0 (childname, "info_window") == 0)
	{
		return G_OBJECT (gtk_source_completion_get_info_window (completion));
	}

	return NULL;
}

static void
gtk_source_completion_buildable_interface_init (GtkBuildableIface *iface)
{
	iface->get_internal_child = gtk_source_completion_buildable_get_internal_child;
}

void
_gtk_source_completion_add_proposals (GtkSourceCompletion         *completion,
                                      GtkSourceCompletionContext  *context,
                                      GtkSourceCompletionProvider *provider,
                                      GList                       *proposals,
                                      gboolean                     finished)
{
	GList *item;

	g_return_if_fail (GTK_SOURCE_IS_COMPLETION (completion));
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_CONTEXT (context));
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider));
	g_return_if_fail (completion->priv->context == context);

	item = g_list_find (completion->priv->running_providers, provider);
	g_return_if_fail (item != NULL);

	gtk_source_completion_model_add_proposals (completion->priv->model_proposals,
						   provider,
						   proposals);

	if (finished)
	{
		/* Remove provider from list of running providers */
		completion->priv->running_providers =
			g_list_delete_link (completion->priv->running_providers,
			                    item);

		if (completion->priv->running_providers == NULL)
		{
			populating_done (completion, context);
		}
	}
}

/**
 * gtk_source_completion_show:
 * @completion: a #GtkSourceCompletion.
 * @providers: (element-type GtkSource.CompletionProvider) (nullable):
 * a list of #GtkSourceCompletionProvider, or %NULL.
 * @context: (transfer floating): The #GtkSourceCompletionContext
 * with which to start the completion.
 *
 * Starts a new completion with the specified #GtkSourceCompletionContext and
 * a list of potential candidate providers for completion.
 *
 * It can be convenient for showing a completion on-the-fly, without the need to
 * add or remove providers to the #GtkSourceCompletion.
 *
 * Another solution is to add providers with
 * gtk_source_completion_add_provider(), and implement
 * gtk_source_completion_provider_match() for each provider.
 *
 * Returns: %TRUE if it was possible to the show completion window.
 */
gboolean
gtk_source_completion_show (GtkSourceCompletion        *completion,
                            GList                      *providers,
                            GtkSourceCompletionContext *context)
{
	GList *selected_providers;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION (completion), FALSE);
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_CONTEXT (context), FALSE);

	if (completion->priv->view == NULL)
	{
		return FALSE;
	}

	/* Make sure to clear any active completion */
	reset_completion (completion);

	/* We need to take owenership of the context right before doing
	   anything so we don't leak it or get a crash emitting the signal */
	g_object_ref_sink (context);

	if (providers == NULL)
	{
		g_object_unref (context);

		return FALSE;
	}

	/* Populate the context */
	g_signal_emit (completion, signals[POPULATE_CONTEXT], 0, context);

	/* From the providers, select the ones that match the context */
	selected_providers = select_providers (providers, context);

	if (selected_providers == NULL)
	{
		g_object_unref (context);
		gtk_source_completion_hide (completion);
		return FALSE;
	}

	update_completion (completion, selected_providers, context);
	g_list_free (selected_providers);
	g_object_unref (context);

	return TRUE;
}

/**
 * gtk_source_completion_get_providers:
 * @completion: a #GtkSourceCompletion.
 *
 * Get list of providers registered on @completion. The returned list is owned
 * by the completion and should not be freed.
 *
 * Returns: (element-type GtkSource.CompletionProvider) (transfer none):
 * list of #GtkSourceCompletionProvider.
 */
GList *
gtk_source_completion_get_providers (GtkSourceCompletion *completion)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION (completion), NULL);
	return completion->priv->providers;
}

GQuark
gtk_source_completion_error_quark (void)
{
	static GQuark quark = 0;

	if (G_UNLIKELY (quark == 0))
	{
		quark = g_quark_from_static_string ("gtk-source-completion-error-quark");
	}

	return quark;
}

/**
 * gtk_source_completion_new:
 * @view: a #GtkSourceView.
 *
 * Creates a new #GtkSourceCompletion associated with @view.
 *
 * Returns: a new #GtkSourceCompletion.
 */
GtkSourceCompletion *
gtk_source_completion_new (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), NULL);

	return g_object_new (GTK_SOURCE_TYPE_COMPLETION,
	                     "view", view,
	                     NULL);
}

/**
 * gtk_source_completion_add_provider:
 * @completion: a #GtkSourceCompletion.
 * @provider: a #GtkSourceCompletionProvider.
 * @error: a #GError.
 *
 * Add a new #GtkSourceCompletionProvider to the completion object. This will
 * add a reference @provider, so make sure to unref your own copy when you
 * no longer need it.
 *
 * Returns: %TRUE if @provider was successfully added, otherwise if @error
 *          is provided, it will be set with the error and %FALSE is returned.
 */
gboolean
gtk_source_completion_add_provider (GtkSourceCompletion          *completion,
				    GtkSourceCompletionProvider  *provider,
				    GError                      **error)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION (completion), FALSE);
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), FALSE);

	if (g_list_find (completion->priv->providers, provider) != NULL)
	{
		if (error != NULL)
		{
			g_set_error (error,
			             GTK_SOURCE_COMPLETION_ERROR,
			             GTK_SOURCE_COMPLETION_ERROR_ALREADY_BOUND,
			             "Provider is already bound to this completion object");
		}

		return FALSE;
	}

	completion->priv->providers = g_list_append (completion->priv->providers,
	                                             g_object_ref (provider));

	if (error != NULL)
	{
		*error = NULL;
	}

	return TRUE;
}

/**
 * gtk_source_completion_remove_provider:
 * @completion: a #GtkSourceCompletion.
 * @provider: a #GtkSourceCompletionProvider.
 * @error: a #GError.
 *
 * Remove @provider from the completion.
 *
 * Returns: %TRUE if @provider was successfully removed, otherwise if @error
 *          is provided, it will be set with the error and %FALSE is returned.
 */
gboolean
gtk_source_completion_remove_provider (GtkSourceCompletion          *completion,
				       GtkSourceCompletionProvider  *provider,
				       GError                      **error)
{
	GList *item;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION (completion), FALSE);
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider), FALSE);

	item = g_list_find (completion->priv->providers, provider);

	if (item == NULL)
	{
		if (error != NULL)
		{
			g_set_error (error,
			             GTK_SOURCE_COMPLETION_ERROR,
			             GTK_SOURCE_COMPLETION_ERROR_NOT_BOUND,
			             "Provider is not bound to this completion object");
		}

		return FALSE;
	}

	completion->priv->providers = g_list_remove_link (completion->priv->providers, item);

	g_object_unref (provider);

	if (error != NULL)
	{
		*error = NULL;
	}

	return TRUE;
}

/**
 * gtk_source_completion_hide:
 * @completion: a #GtkSourceCompletion.
 *
 * Hides the completion if it is active (visible).
 */
void
gtk_source_completion_hide (GtkSourceCompletion *completion)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION (completion));

	reset_completion (completion);

	if (gtk_widget_get_visible (GTK_WIDGET (completion->priv->main_window)))
	{
		g_signal_emit (completion, signals[HIDE], 0);
	}
}

/**
 * gtk_source_completion_get_info_window:
 * @completion: a #GtkSourceCompletion.
 *
 * The info widget is the window where the completion displays optional extra
 * information of the proposal.
 *
 * Returns: (transfer none): The #GtkSourceCompletionInfo window
 *                           associated with @completion.
 */
GtkSourceCompletionInfo *
gtk_source_completion_get_info_window (GtkSourceCompletion *completion)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION (completion), NULL);

	return completion->priv->info_window;
}

/**
 * gtk_source_completion_get_view:
 * @completion: a #GtkSourceCompletion.
 *
 * The #GtkSourceView associated with @completion, or %NULL if the view has been
 * destroyed.
 *
 * Returns: (nullable) (transfer none): The #GtkSourceView associated with
 * @completion, or %NULL.
 */
GtkSourceView *
gtk_source_completion_get_view (GtkSourceCompletion *completion)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION (completion), NULL);

	return completion->priv->view;
}

/**
 * gtk_source_completion_create_context:
 * @completion: a #GtkSourceCompletion.
 * @position: (nullable): a #GtkTextIter, or %NULL.
 *
 * Create a new #GtkSourceCompletionContext for @completion. The position where
 * the completion occurs can be specified by @position. If @position is %NULL,
 * the current cursor position will be used.
 *
 * Returns: (transfer floating): a new #GtkSourceCompletionContext.
 * The reference being returned is a 'floating' reference,
 * so if you invoke gtk_source_completion_show() with this context
 * you don't need to unref it.
 */
GtkSourceCompletionContext *
gtk_source_completion_create_context (GtkSourceCompletion *completion,
                                      GtkTextIter         *position)
{
	GtkTextIter iter;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION (completion), NULL);

	if (completion->priv->view == NULL)
	{
		return NULL;
	}

	if (position == NULL)
	{
		get_iter_at_insert (completion, &iter);
	}
	else
	{
		iter = *position;
	}

	return _gtk_source_completion_context_new (completion, &iter);
}

/**
 * gtk_source_completion_move_window:
 * @completion: a #GtkSourceCompletion.
 * @iter: a #GtkTextIter.
 *
 * Move the completion window to a specific iter.
 *
 * Deprecated: 3.8: Use gtk_source_completion_provider_get_start_iter() instead.
 */
void
gtk_source_completion_move_window (GtkSourceCompletion *completion,
                                   GtkTextIter         *iter)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION (completion));
	g_return_if_fail (iter != NULL);

	if (completion->priv->view == NULL)
	{
		return;
	}

	if (!gtk_widget_get_visible (GTK_WIDGET (completion->priv->main_window)))
	{
		return;
	}

	gtk_source_completion_info_move_to_iter (completion->priv->main_window,
	                                         GTK_TEXT_VIEW (completion->priv->view),
	                                         iter);
}

/**
 * gtk_source_completion_block_interactive:
 * @completion: a #GtkSourceCompletion.
 *
 * Block interactive completion. This can be used to disable interactive
 * completion when inserting or deleting text from the buffer associated with
 * the completion. Use gtk_source_completion_unblock_interactive() to enable
 * interactive completion again.
 *
 * This function may be called multiple times. It will continue to block
 * interactive completion until gtk_source_completion_unblock_interactive()
 * has been called the same number of times.
 */
void
gtk_source_completion_block_interactive (GtkSourceCompletion *completion)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION (completion));

	if (completion->priv->view == NULL)
	{
		return;
	}

	if (completion->priv->block_interactive_num == 0)
	{
		block_interactive (completion);
	}

	completion->priv->block_interactive_num++;
}

/**
 * gtk_source_completion_unblock_interactive:
 * @completion: a #GtkSourceCompletion.
 *
 * Unblock interactive completion. This can be used after using
 * gtk_source_completion_block_interactive() to enable interactive completion
 * again.
 */
void
gtk_source_completion_unblock_interactive (GtkSourceCompletion *completion)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION (completion));

	if (completion->priv->view == NULL)
	{
		return;
	}

	if (completion->priv->block_interactive_num == 1)
	{
		g_signal_handlers_unblock_by_func (completion->priv->buffer,
						   buffer_insert_text_cb,
						   completion);

		g_signal_handlers_unblock_by_func (completion->priv->buffer,
						   buffer_delete_range_cb,
						   completion);
	}

	if (completion->priv->block_interactive_num > 0)
	{
		completion->priv->block_interactive_num--;
	}
}
