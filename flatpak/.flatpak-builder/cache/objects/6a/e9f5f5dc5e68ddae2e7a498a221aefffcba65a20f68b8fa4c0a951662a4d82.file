/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- *
 * gtksourcecompletionmodel.c
 * This file is part of GtkSourceView
 *
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

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcecompletionmodel.h"
#include "gtksourcecompletionprovider.h"
#include "gtksourcecompletionproposal.h"
#include "gtksourceview-i18n.h"

typedef struct
{
	GtkSourceCompletionModel *model;
	GtkSourceCompletionProvider *completion_provider;

	/* List of ProposalInfo. If the header is visible, it is included. */
	GQueue *proposals;

	/* By default, all providers are visible. But with Ctrl+{left, right},
	 * the user can switch between providers. In this case, only one
	 * provider is visible, and the others are hidden. */
	guint visible : 1;
} ProviderInfo;

typedef struct
{
	/* Node from model->priv->providers */
	GList *provider_node;

	/* For the header, the completion proposal is NULL. */
	GtkSourceCompletionProposal *completion_proposal;

	/* For the "changed" signal emitted by the proposal.
	 * When the node is freed, the signal is disconnected. */
	gulong changed_id;
} ProposalInfo;

struct _GtkSourceCompletionModelPrivate
{
	GType column_types[GTK_SOURCE_COMPLETION_MODEL_N_COLUMNS];

	/* List of ProviderInfo sorted by priority in descending order. */
	GList *providers;

	/* List of GtkSourceCompletionProvider. If NULL, all providers are
	 * visible. */
	GList *visible_providers;

	guint show_headers : 1;
};

static void tree_model_iface_init (gpointer g_iface, gpointer iface_data);

G_DEFINE_TYPE_WITH_CODE (GtkSourceCompletionModel,
                         gtk_source_completion_model,
                         G_TYPE_OBJECT,
			 G_ADD_PRIVATE (GtkSourceCompletionModel)
                         G_IMPLEMENT_INTERFACE (GTK_TYPE_TREE_MODEL,
                                                tree_model_iface_init))

/* Utilities functions */

static gboolean
is_header (ProposalInfo *info)
{
	g_assert (info != NULL);

	return info->completion_proposal == NULL;
}

static gboolean
is_provider_visible (GtkSourceCompletionModel    *model,
		     GtkSourceCompletionProvider *provider)
{
	if (model->priv->visible_providers == NULL)
	{
		return TRUE;
	}

	return g_list_find (model->priv->visible_providers, provider) != NULL;
}

static gboolean
get_iter_from_index (GtkSourceCompletionModel *model,
                     GtkTreeIter              *iter,
                     gint                      idx)
{
	gint provider_index = 0;
	GList *l;
	ProviderInfo *info;

	if (idx < 0)
	{
		return FALSE;
	}

	/* Find the provider */
	for (l = model->priv->providers; l != NULL; l = l->next)
	{
		gint new_index;
		info = l->data;

		if (!info->visible)
		{
			continue;
		}

		new_index = provider_index + info->proposals->length;

		if (idx < new_index)
		{
			break;
		}

		provider_index = new_index;
	}

	if (l == NULL)
	{
		return FALSE;
	}

	/* Find the node inside the provider */
	iter->user_data = g_queue_peek_nth_link (info->proposals, idx - provider_index);

	return iter->user_data != NULL;
}

static gint
get_provider_start_index (GtkSourceCompletionModel *model,
			  ProviderInfo		   *info)
{
	gint start_index = 0;
	GList *l;

	g_assert (info != NULL);

	for (l = model->priv->providers; l != NULL; l = l->next)
	{
		ProviderInfo *cur_info = l->data;

		if (cur_info == info)
		{
			break;
		}

		if (cur_info->visible)
		{
			start_index += cur_info->proposals->length;
		}
	}

	/* The provider must be in the list. */
	g_assert (l != NULL);

	return start_index;
}

static GtkTreePath *
get_proposal_path (GtkSourceCompletionModel *model,
		   GList                    *proposal_node)
{
	ProposalInfo *proposal_info;
	ProviderInfo *provider_info;
	gint idx;

	if (proposal_node == NULL)
	{
		return NULL;
	}

	proposal_info = proposal_node->data;
	provider_info = proposal_info->provider_node->data;

	idx = get_provider_start_index (model, provider_info);
	idx += g_queue_link_index (provider_info->proposals, proposal_node);

	return gtk_tree_path_new_from_indices (idx, -1);
}

/* Returns the first visible provider after @provider. It can be @provider
 * itself. Returns NULL if not found. */
static GList *
find_next_visible_provider (GList *provider)
{
	GList *l;

	for (l = provider; l != NULL; l = l->next)
	{
		ProviderInfo *info = l->data;

		if (info->visible)
		{
			return l;
		}
	}

	return NULL;
}

/* Returns the first visible provider before @provider. It can be @provider
 * itself. Returns NULL if not found. */
static GList *
find_previous_visible_provider (GList *provider)
{
	GList *l;

	for (l = provider; l != NULL; l = l->prev)
	{
		ProviderInfo *info = l->data;

		if (info->visible)
		{
			return l;
		}
	}

	return NULL;
}

static GList *
get_provider_node (GtkSourceCompletionModel    *model,
		   GtkSourceCompletionProvider *provider)
{
	GList *l;

	for (l = model->priv->providers; l != NULL; l = l->next)
	{
		ProviderInfo *provider_info = l->data;

		if (provider_info->completion_provider == provider)
		{
			return l;
		}
	}

	return NULL;
}

static gboolean
get_last_iter (GtkSourceCompletionModel *model,
	       GtkTreeIter              *iter)
{
	GList *last_provider;
	ProviderInfo *provider_info;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);

	last_provider = g_list_last (model->priv->providers);

	if (last_provider == NULL)
	{
		return FALSE;
	}

	provider_info = last_provider->data;

	iter->user_data = provider_info->proposals->tail;
	g_assert (iter->user_data != NULL);

	if (!provider_info->visible)
	{
		return gtk_source_completion_model_iter_previous (model, iter);
	}

	return TRUE;
}

static void
proposal_info_free (gpointer data)
{
	ProposalInfo *info = data;

	if (data == NULL)
	{
		return;
	}

	if (info->completion_proposal != NULL)
	{
		if (info->changed_id != 0)
		{
			g_signal_handler_disconnect (info->completion_proposal,
			                             info->changed_id);
		}

		g_object_unref (info->completion_proposal);
	}

	g_slice_free (ProposalInfo, data);
}

static void
provider_info_free (gpointer data)
{
	ProviderInfo *info = data;

	if (data == NULL)
	{
		return;
	}

	g_object_unref (info->completion_provider);
	g_queue_free_full (info->proposals, (GDestroyNotify)proposal_info_free);
	g_slice_free (ProviderInfo, data);
}

static void
add_header (GList *provider_node)
{
	ProviderInfo *provider_info = provider_node->data;
	ProposalInfo *header = g_slice_new0 (ProposalInfo);

	header->provider_node = provider_node;

	g_queue_push_head (provider_info->proposals, header);
}

/* Add the header, and emit the "row-inserted" signal. */
static void
show_header (GtkSourceCompletionModel *model,
	     GList                    *provider_node)
{
	ProviderInfo *provider_info = provider_node->data;

	add_header (provider_node);

	if (provider_info->visible)
	{
		GtkTreePath *path = get_proposal_path (model, provider_info->proposals->head);
		GtkTreeIter iter;

		iter.user_data = provider_info->proposals->head;
		gtk_tree_model_row_inserted (GTK_TREE_MODEL (model), path, &iter);

		gtk_tree_path_free (path);
	}
}

/* Remove the header, and emit the "row-deleted" signal. */
static void
hide_header (GtkSourceCompletionModel *model,
	     GList                    *provider_node)
{
	ProviderInfo *provider_info = provider_node->data;
	ProposalInfo *proposal_info = g_queue_pop_head (provider_info->proposals);

	g_assert (provider_info->proposals->length > 0);
	g_assert (is_header (proposal_info));

	proposal_info_free (proposal_info);

	if (provider_info->visible)
	{
		GtkTreePath *path = get_proposal_path (model, provider_info->proposals->head);
		gtk_tree_model_row_deleted (GTK_TREE_MODEL (model), path);
		gtk_tree_path_free (path);
	}
}

/* Interface implementation */

static GtkTreeModelFlags
tree_model_get_flags (GtkTreeModel *tree_model)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model), 0);

	return GTK_TREE_MODEL_LIST_ONLY | GTK_TREE_MODEL_ITERS_PERSIST;
}

static gint
tree_model_get_n_columns (GtkTreeModel *tree_model)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model), 0);

	return GTK_SOURCE_COMPLETION_MODEL_N_COLUMNS;
}

static GType
tree_model_get_column_type (GtkTreeModel *tree_model,
			    gint          idx)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model), G_TYPE_INVALID);
	g_return_val_if_fail (0 <= idx && idx < GTK_SOURCE_COMPLETION_MODEL_N_COLUMNS, G_TYPE_INVALID);

	return GTK_SOURCE_COMPLETION_MODEL (tree_model)->priv->column_types[idx];
}

static gboolean
tree_model_get_iter (GtkTreeModel *tree_model,
		     GtkTreeIter  *iter,
		     GtkTreePath  *path)
{
	GtkSourceCompletionModel *model;
	gint *indices;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (path != NULL, FALSE);

	model = GTK_SOURCE_COMPLETION_MODEL (tree_model);
	indices = gtk_tree_path_get_indices (path);

	return get_iter_from_index (model, iter, indices[0]);
}

static GtkTreePath *
tree_model_get_path (GtkTreeModel *tree_model,
		     GtkTreeIter  *iter)
{
	GtkSourceCompletionModel *model;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model), NULL);
	g_return_val_if_fail (iter != NULL, NULL);
	g_return_val_if_fail (iter->user_data != NULL, NULL);

	model = GTK_SOURCE_COMPLETION_MODEL (tree_model);

	return get_proposal_path (model, iter->user_data);
}

static void
tree_model_get_value (GtkTreeModel *tree_model,
		      GtkTreeIter  *iter,
		      gint          column,
		      GValue       *value)
{
	GList *proposal_node;
	ProposalInfo *proposal_info;
	ProviderInfo *provider_info;
	GtkSourceCompletionProposal *completion_proposal;
	GtkSourceCompletionProvider *completion_provider;

	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model));
	g_return_if_fail (iter != NULL);
	g_return_if_fail (iter->user_data != NULL);
	g_return_if_fail (0 <= column && column < GTK_SOURCE_COMPLETION_MODEL_N_COLUMNS);

	proposal_node = iter->user_data;
	proposal_info = proposal_node->data;
	provider_info = proposal_info->provider_node->data;
	completion_proposal = proposal_info->completion_proposal;
	completion_provider = provider_info->completion_provider;

	g_value_init (value, GTK_SOURCE_COMPLETION_MODEL (tree_model)->priv->column_types[column]);

	switch (column)
	{
		case GTK_SOURCE_COMPLETION_MODEL_COLUMN_PROVIDER:
			g_value_set_object (value, completion_provider);
			break;

		case GTK_SOURCE_COMPLETION_MODEL_COLUMN_PROPOSAL:
			g_value_set_object (value, completion_proposal);
			break;

		case GTK_SOURCE_COMPLETION_MODEL_COLUMN_MARKUP:
			if (is_header (proposal_info))
			{
				gchar *name = gtk_source_completion_provider_get_name (completion_provider);

				if (name != NULL)
				{
					gchar *escaped = g_markup_escape_text (name, -1);
					gchar *markup = g_strdup_printf ("<b>%s</b>", escaped);
					g_value_take_string (value, markup);

					g_free (name);
					g_free (escaped);
				}
				else
				{
					gchar *markup = g_strdup_printf ("<b>%s</b>", _("Provider"));
					g_value_take_string (value, markup);
				}
			}
			else
			{
				gchar *markup = gtk_source_completion_proposal_get_markup (completion_proposal);

				if (markup == NULL)
				{
					gchar *label = gtk_source_completion_proposal_get_label (completion_proposal);
					markup = g_markup_escape_text (label != NULL ? label : "", -1);
					g_free (label);
				}

				g_value_take_string (value, markup);
			}
			break;

		case GTK_SOURCE_COMPLETION_MODEL_COLUMN_ICON:
			if (is_header (proposal_info))
			{
				GdkPixbuf *icon = gtk_source_completion_provider_get_icon (completion_provider);
				g_value_set_object (value, (gpointer)icon);
			}
			else
			{
				GdkPixbuf *icon = gtk_source_completion_proposal_get_icon (completion_proposal);
				g_value_set_object (value, (gpointer)icon);
			}
			break;

		case GTK_SOURCE_COMPLETION_MODEL_COLUMN_ICON_NAME:
			if (is_header (proposal_info))
			{
				const gchar *icon_name = gtk_source_completion_provider_get_icon_name (completion_provider);
				g_value_set_string (value, (gpointer)icon_name);
			}
			else
			{
				const gchar *icon_name = gtk_source_completion_proposal_get_icon_name (completion_proposal);
				g_value_set_string (value, (gpointer)icon_name);
			}
			break;

		case GTK_SOURCE_COMPLETION_MODEL_COLUMN_GICON:
			if (is_header (proposal_info))
			{
				GIcon *icon = gtk_source_completion_provider_get_gicon (completion_provider);
				g_value_set_object (value, (gpointer)icon);
			}
			else
			{
				GIcon *icon = gtk_source_completion_proposal_get_gicon (completion_proposal);
				g_value_set_object (value, (gpointer)icon);
			}
			break;

		case GTK_SOURCE_COMPLETION_MODEL_COLUMN_IS_HEADER:
			g_value_set_boolean (value, is_header (proposal_info));
			break;

		default:
			g_assert_not_reached ();
	}
}

static gboolean
tree_model_iter_next (GtkTreeModel *tree_model,
		      GtkTreeIter  *iter)
{
	ProposalInfo *proposal_info;
	GList *proposal_node;
	GList *cur_provider;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (iter->user_data != NULL, FALSE);

	proposal_node = iter->user_data;
	proposal_info = proposal_node->data;

	/* Find the right provider, which must be visible */

	cur_provider = proposal_info->provider_node;

	if (proposal_node->next == NULL)
	{
		cur_provider = g_list_next (cur_provider);
	}

	cur_provider = find_next_visible_provider (cur_provider);

	if (cur_provider == NULL)
	{
		return FALSE;
	}

	/* Find the proposal inside the provider */

	if (cur_provider == proposal_info->provider_node)
	{
		iter->user_data = g_list_next (proposal_node);
	}
	else
	{
		ProviderInfo *info = cur_provider->data;
		iter->user_data = info->proposals->head;
	}

	g_assert (iter->user_data != NULL);

	return TRUE;
}

static gboolean
tree_model_iter_children (GtkTreeModel *tree_model,
			  GtkTreeIter  *iter,
			  GtkTreeIter  *parent)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (parent == NULL || parent->user_data != NULL, FALSE);

	if (parent != NULL)
	{
		return FALSE;
	}
	else
	{
		return get_iter_from_index (GTK_SOURCE_COMPLETION_MODEL (tree_model), iter, 0);
	}
}

static gboolean
tree_model_iter_has_child (GtkTreeModel *tree_model,
			   GtkTreeIter  *iter)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (iter->user_data != NULL, FALSE);

	return FALSE;
}

static gint
tree_model_iter_n_children (GtkTreeModel *tree_model,
			    GtkTreeIter  *iter)
{
	GtkSourceCompletionModel *model;
	GList *l;
	gint num_nodes = 0;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model), 0);
	g_return_val_if_fail (iter == NULL || iter->user_data != NULL, 0);

	if (iter != NULL)
	{
		return 0;
	}

	model = GTK_SOURCE_COMPLETION_MODEL (tree_model);

	for (l = model->priv->providers; l != NULL; l = l->next)
	{
		ProviderInfo *info = l->data;

		if (info->visible)
		{
			num_nodes += info->proposals->length;
		}
	}

	return num_nodes;
}

static gboolean
tree_model_iter_nth_child (GtkTreeModel *tree_model,
			   GtkTreeIter  *iter,
			   GtkTreeIter  *parent,
			   gint          child_num)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (parent == NULL || parent->user_data != NULL, FALSE);

	if (parent != NULL)
	{
		return FALSE;
	}
	else
	{
		return get_iter_from_index (GTK_SOURCE_COMPLETION_MODEL (tree_model),
					    iter,
					    child_num);
	}
}

static gboolean
tree_model_iter_parent (GtkTreeModel *tree_model,
			GtkTreeIter  *iter,
			GtkTreeIter  *child)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (tree_model), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (child != NULL, FALSE);

	iter->user_data = NULL;
	return FALSE;
}

static void
tree_model_iface_init (gpointer g_iface,
                       gpointer iface_data)
{
	GtkTreeModelIface *iface = g_iface;

	iface->get_flags = tree_model_get_flags;
	iface->get_n_columns = tree_model_get_n_columns;
	iface->get_column_type = tree_model_get_column_type;
	iface->get_iter = tree_model_get_iter;
	iface->get_path = tree_model_get_path;
	iface->get_value = tree_model_get_value;
	iface->iter_next = tree_model_iter_next;
	iface->iter_children = tree_model_iter_children;
	iface->iter_has_child = tree_model_iter_has_child;
	iface->iter_n_children = tree_model_iter_n_children;
	iface->iter_nth_child = tree_model_iter_nth_child;
	iface->iter_parent = tree_model_iter_parent;
}

/* Construction and destruction */

static void
gtk_source_completion_model_dispose (GObject *object)
{
	GtkSourceCompletionModel *model = GTK_SOURCE_COMPLETION_MODEL (object);

	g_list_free_full (model->priv->providers, (GDestroyNotify)provider_info_free);
	model->priv->providers = NULL;

	g_list_free_full (model->priv->visible_providers, g_object_unref);
	model->priv->visible_providers = NULL;

	G_OBJECT_CLASS (gtk_source_completion_model_parent_class)->dispose (object);
}

static void
gtk_source_completion_model_class_init (GtkSourceCompletionModelClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->dispose = gtk_source_completion_model_dispose;
}

static void
gtk_source_completion_model_init (GtkSourceCompletionModel *self)
{
	self->priv = gtk_source_completion_model_get_instance_private (self);

	self->priv->column_types[GTK_SOURCE_COMPLETION_MODEL_COLUMN_MARKUP] = G_TYPE_STRING;
	self->priv->column_types[GTK_SOURCE_COMPLETION_MODEL_COLUMN_ICON] = GDK_TYPE_PIXBUF;
	self->priv->column_types[GTK_SOURCE_COMPLETION_MODEL_COLUMN_ICON_NAME] = G_TYPE_STRING;
	self->priv->column_types[GTK_SOURCE_COMPLETION_MODEL_COLUMN_GICON] = G_TYPE_ICON;
	self->priv->column_types[GTK_SOURCE_COMPLETION_MODEL_COLUMN_PROPOSAL] = G_TYPE_OBJECT;
	self->priv->column_types[GTK_SOURCE_COMPLETION_MODEL_COLUMN_PROVIDER] = G_TYPE_OBJECT;
	self->priv->column_types[GTK_SOURCE_COMPLETION_MODEL_COLUMN_IS_HEADER] = G_TYPE_BOOLEAN;

	self->priv->show_headers = 1;
	self->priv->providers = NULL;
	self->priv->visible_providers = NULL;
}

/* Population: add proposals */

/* Returns the newly-created provider node */
static GList *
create_provider_info (GtkSourceCompletionModel    *model,
                      GtkSourceCompletionProvider *provider)
{
	ProviderInfo *info;
	gint priority;
	GList *l;
	GList *provider_node;

	/* Create the structure */

	info = g_slice_new0 (ProviderInfo);
	info->model = model;
	info->completion_provider = g_object_ref (provider);
	info->proposals = g_queue_new ();
	info->visible = is_provider_visible (model, provider);

	/* Insert the ProviderInfo in the list */

	priority = gtk_source_completion_provider_get_priority (provider);

	for (l = model->priv->providers; l != NULL; l = l->next)
	{
		ProviderInfo *cur_info = l->data;
		gint cur_priority = gtk_source_completion_provider_get_priority (cur_info->completion_provider);

		if (cur_priority < priority)
		{
			break;
		}
	}

	model->priv->providers = g_list_insert_before (model->priv->providers, l, info);

	provider_node = g_list_find (model->priv->providers, info);

	/* Insert the header if needed */

	if (model->priv->show_headers)
	{
		add_header (provider_node);
	}

	return provider_node;
}

static void
on_proposal_changed (GtkSourceCompletionProposal *proposal,
		     GList                       *proposal_node)
{
	ProposalInfo *proposal_info = proposal_node->data;
	ProviderInfo *provider_info = proposal_info->provider_node->data;

	if (provider_info->visible)
	{
		GtkTreeIter iter;
		GtkTreePath *path;

		iter.user_data = proposal_node;
		path = get_proposal_path (provider_info->model, proposal_node);

		gtk_tree_model_row_changed (GTK_TREE_MODEL (provider_info->model),
					    path,
					    &iter);

		gtk_tree_path_free (path);
	}
}

static void
add_proposal (GtkSourceCompletionProposal *proposal,
	      GList                       *provider_node)
{
	ProviderInfo *provider_info = provider_node->data;
	ProposalInfo *proposal_info = g_slice_new0 (ProposalInfo);

	proposal_info->provider_node = provider_node;
	proposal_info->completion_proposal = g_object_ref (proposal);

	g_queue_push_tail (provider_info->proposals, proposal_info);

	proposal_info->changed_id = g_signal_connect (proposal,
						      "changed",
						      G_CALLBACK (on_proposal_changed),
						      provider_info->proposals->tail);
}

void
gtk_source_completion_model_add_proposals (GtkSourceCompletionModel    *model,
					   GtkSourceCompletionProvider *provider,
					   GList                       *proposals)
{
	GList *provider_node = NULL;

	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model));
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (provider));

	if (proposals == NULL)
	{
		return;
	}

	provider_node = get_provider_node (model, provider);

	if (provider_node == NULL)
	{
		provider_node = create_provider_info (model, provider);
	}

	g_list_foreach (proposals, (GFunc)add_proposal, provider_node);
}

/* Other public functions */

void
gtk_source_completion_model_set_visible_providers (GtkSourceCompletionModel *model,
                                                   GList                    *providers)
{
	GList *l;

	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model));

	for (l = providers; l != NULL; l = l->next)
	{
		g_return_if_fail (GTK_SOURCE_IS_COMPLETION_PROVIDER (l->data));
	}

	g_list_free_full (model->priv->visible_providers, g_object_unref);

	model->priv->visible_providers = g_list_copy_deep (providers,
							   (GCopyFunc)g_object_ref,
							   NULL);

	for (l = model->priv->providers; l != NULL; l = l->next)
	{
		ProviderInfo *provider_info = l->data;
		provider_info->visible = is_provider_visible (model, provider_info->completion_provider);
	}
}

GList *
gtk_source_completion_model_get_visible_providers (GtkSourceCompletionModel *model)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model), NULL);

	return model->priv->visible_providers;
}

/* If @only_visible is %TRUE, only the visible providers are taken into account. */
gboolean
gtk_source_completion_model_is_empty (GtkSourceCompletionModel *model,
                                      gboolean                  only_visible)
{
	GList *l;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model), TRUE);

	for (l = model->priv->providers; l != NULL; l = l->next)
	{
		ProviderInfo *info = l->data;

		if (only_visible && !info->visible)
		{
			continue;
		}

		/* A provider can not be empty */
		return FALSE;
	}

	return TRUE;
}

void
gtk_source_completion_model_set_show_headers (GtkSourceCompletionModel *model,
                                              gboolean                  show_headers)
{
	GList *l;

	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model));

	if (model->priv->show_headers == show_headers)
	{
		return;
	}

	model->priv->show_headers = show_headers;

	for (l = model->priv->providers; l != NULL; l = l->next)
	{
		if (show_headers)
		{
			show_header (model, l);
		}
		else
		{
			hide_header (model, l);
		}
	}
}

gboolean
gtk_source_completion_model_iter_is_header (GtkSourceCompletionModel *model,
                                            GtkTreeIter              *iter)
{
	GList *proposal_node;
	ProposalInfo *proposal_info;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (iter->user_data != NULL, FALSE);

	proposal_node = iter->user_data;
	proposal_info = proposal_node->data;

	return is_header (proposal_info);
}

gboolean
gtk_source_completion_model_iter_previous (GtkSourceCompletionModel *model,
                                           GtkTreeIter              *iter)
{
	/* This function is the symmetry of tree_model_iter_next(). */

	ProposalInfo *proposal_info;
	GList *proposal_node;
	GList *cur_provider;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (iter->user_data != NULL, FALSE);

	proposal_node = iter->user_data;
	proposal_info = proposal_node->data;

	/* Find the right provider, which must be visible */

	cur_provider = proposal_info->provider_node;

	if (proposal_node->prev == NULL)
	{
		cur_provider = g_list_previous (cur_provider);
	}

	cur_provider = find_previous_visible_provider (cur_provider);

	if (cur_provider == NULL)
	{
		return FALSE;
	}

	/* Find the proposal inside the provider */

	if (cur_provider == proposal_info->provider_node)
	{
		iter->user_data = g_list_previous (proposal_node);
	}
	else
	{
		ProviderInfo *info = cur_provider->data;
		iter->user_data = info->proposals->tail;
	}

	g_assert (iter->user_data != NULL);

	return TRUE;
}

/* Get all the providers (visible and hidden), sorted by priority in descending
 * order (the highest priority first).
 * Free the return value with g_list_free().
 */
GList *
gtk_source_completion_model_get_providers (GtkSourceCompletionModel *model)
{
	GList *l;
	GList *ret = NULL;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model), NULL);

	for (l = model->priv->providers; l != NULL; l = l->next)
	{
		ProviderInfo *info = l->data;
		ret = g_list_prepend (ret, info->completion_provider);
	}

	return g_list_reverse (ret);
}

/* Get the first proposal. Headers are skipped.
 * Returns TRUE on success.
 */
gboolean
gtk_source_completion_model_first_proposal (GtkSourceCompletionModel *model,
					    GtkTreeIter              *iter)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);

	if (!gtk_tree_model_get_iter_first (GTK_TREE_MODEL (model), iter))
	{
		return FALSE;
	}

	while (gtk_source_completion_model_iter_is_header (model, iter))
	{
		if (!gtk_tree_model_iter_next (GTK_TREE_MODEL (model), iter))
		{
			return FALSE;
		}
	}

	return TRUE;
}

/* Get the last proposal. Headers are skipped.
 * Returns TRUE on success.
 */
gboolean
gtk_source_completion_model_last_proposal (GtkSourceCompletionModel *model,
					   GtkTreeIter              *iter)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);

	if (!get_last_iter (model, iter))
	{
		return FALSE;
	}

	while (gtk_source_completion_model_iter_is_header (model, iter))
	{
		if (!gtk_source_completion_model_iter_previous (model, iter))
		{
			return FALSE;
		}
	}

	return TRUE;
}

/* Get the next proposal. Headers are skipped.
 * Returns TRUE on success.
 */
gboolean
gtk_source_completion_model_next_proposal (GtkSourceCompletionModel *model,
					   GtkTreeIter              *iter)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model), FALSE);
	g_return_val_if_fail (iter != NULL && iter->user_data != NULL, FALSE);

	do
	{
		if (!gtk_tree_model_iter_next (GTK_TREE_MODEL (model), iter))
		{
			return FALSE;
		}
	} while (gtk_source_completion_model_iter_is_header (model, iter));

	return TRUE;
}

/* Get the previous proposal. Headers are skipped.
 * Returns TRUE on success.
 */
gboolean
gtk_source_completion_model_previous_proposal (GtkSourceCompletionModel *model,
					       GtkTreeIter              *iter)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model), FALSE);
	g_return_val_if_fail (iter != NULL && iter->user_data != NULL, FALSE);

	do
	{
		if (!gtk_source_completion_model_iter_previous (model, iter))
		{
			return FALSE;
		}
	} while (gtk_source_completion_model_iter_is_header (model, iter));

	return TRUE;
}

static gboolean
proposal_has_info (GtkSourceCompletionProvider *provider,
		   GtkSourceCompletionProposal *proposal)
{
	gchar *info;

	if (gtk_source_completion_provider_get_info_widget (provider, proposal) != NULL)
	{
		return TRUE;
	}

	info = gtk_source_completion_proposal_get_info (proposal);

	if (info != NULL)
	{
		g_free (info);
		return TRUE;
	}

	return FALSE;
}

static gboolean
provider_has_info (ProviderInfo *provider_info)
{
	GList *l;

	for (l = provider_info->proposals->head; l != NULL; l = l->next)
	{
		ProposalInfo *proposal_info = l->data;

		if (proposal_info->completion_proposal == NULL)
		{
			continue;
		}

		if (proposal_has_info (provider_info->completion_provider,
				       proposal_info->completion_proposal))
		{
			return TRUE;
		}
	}

	return FALSE;
}

/* Returns whether the model contains one or more proposal with extra
 * information. If the function returns %FALSE, the "Details" button is useless.
 */
gboolean
gtk_source_completion_model_has_info (GtkSourceCompletionModel *model)
{
	GList *l;

	for (l = model->priv->providers; l != NULL; l = l->next)
	{
		ProviderInfo *provider_info = l->data;

		if (provider_has_info (provider_info))
		{
			return TRUE;
		}
	}

	return FALSE;
}

gboolean
gtk_source_completion_model_iter_equal (GtkSourceCompletionModel *model,
                                        GtkTreeIter              *iter1,
                                        GtkTreeIter              *iter2)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_MODEL (model), FALSE);
	g_return_val_if_fail (iter1 != NULL, FALSE);
	g_return_val_if_fail (iter2 != NULL, FALSE);

	return iter1->user_data == iter2->user_data;
}

GtkSourceCompletionModel*
gtk_source_completion_model_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_COMPLETION_MODEL, NULL);
}
