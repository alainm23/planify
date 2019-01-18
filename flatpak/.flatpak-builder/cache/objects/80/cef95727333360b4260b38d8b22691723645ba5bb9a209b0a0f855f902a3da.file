/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecompletionitem.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2009 - Jesse van den Kieboom <jessevdk@gnome.org>
 * Copyright (C) 2016 - Sébastien Wilmet <swilmet@gnome.org>
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
 * SECTION:completionitem
 * @title: GtkSourceCompletionItem
 * @short_description: Simple implementation of GtkSourceCompletionProposal
 *
 * The #GtkSourceCompletionItem class is a simple implementation of the
 * #GtkSourceCompletionProposal interface.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcecompletionitem.h"
#include "gtksourcecompletionproposal.h"
#include "gtksourceview-i18n.h"

struct _GtkSourceCompletionItemPrivate
{
	gchar *label;
	gchar *markup;
	gchar *text;
	GdkPixbuf *icon;
	gchar *icon_name;
	GIcon *gicon;
	gchar *info;
};

enum
{
	PROP_0,
	PROP_LABEL,
	PROP_MARKUP,
	PROP_TEXT,
	PROP_ICON,
	PROP_ICON_NAME,
	PROP_GICON,
	PROP_INFO
};

static void gtk_source_completion_proposal_iface_init (gpointer g_iface, gpointer iface_data);

G_DEFINE_TYPE_WITH_CODE (GtkSourceCompletionItem,
			 gtk_source_completion_item,
			 G_TYPE_OBJECT,
			 G_ADD_PRIVATE (GtkSourceCompletionItem)
			 G_IMPLEMENT_INTERFACE (GTK_SOURCE_TYPE_COMPLETION_PROPOSAL,
			 			gtk_source_completion_proposal_iface_init))

static gchar *
gtk_source_completion_proposal_get_label_impl (GtkSourceCompletionProposal *proposal)
{
	return g_strdup (GTK_SOURCE_COMPLETION_ITEM (proposal)->priv->label);
}

static gchar *
gtk_source_completion_proposal_get_markup_impl (GtkSourceCompletionProposal *proposal)
{
	return g_strdup (GTK_SOURCE_COMPLETION_ITEM (proposal)->priv->markup);
}

static gchar *
gtk_source_completion_proposal_get_text_impl (GtkSourceCompletionProposal *proposal)
{
	return g_strdup (GTK_SOURCE_COMPLETION_ITEM (proposal)->priv->text);
}

static GdkPixbuf *
gtk_source_completion_proposal_get_icon_impl (GtkSourceCompletionProposal *proposal)
{
	return GTK_SOURCE_COMPLETION_ITEM (proposal)->priv->icon;
}

static const gchar *
gtk_source_completion_proposal_get_icon_name_impl (GtkSourceCompletionProposal *proposal)
{
	return GTK_SOURCE_COMPLETION_ITEM (proposal)->priv->icon_name;
}

static GIcon *
gtk_source_completion_proposal_get_gicon_impl (GtkSourceCompletionProposal *proposal)
{
	return GTK_SOURCE_COMPLETION_ITEM (proposal)->priv->gicon;
}

static gchar *
gtk_source_completion_proposal_get_info_impl (GtkSourceCompletionProposal *proposal)
{
	return g_strdup (GTK_SOURCE_COMPLETION_ITEM (proposal)->priv->info);
}

static void
gtk_source_completion_proposal_iface_init (gpointer g_iface,
					   gpointer iface_data)
{
	GtkSourceCompletionProposalIface *iface = g_iface;

	/* Interface data getter implementations */
	iface->get_label = gtk_source_completion_proposal_get_label_impl;
	iface->get_markup = gtk_source_completion_proposal_get_markup_impl;
	iface->get_text = gtk_source_completion_proposal_get_text_impl;
	iface->get_icon = gtk_source_completion_proposal_get_icon_impl;
	iface->get_icon_name = gtk_source_completion_proposal_get_icon_name_impl;
	iface->get_gicon = gtk_source_completion_proposal_get_gicon_impl;
	iface->get_info = gtk_source_completion_proposal_get_info_impl;
}

static void
gtk_source_completion_item_dispose (GObject *object)
{
	GtkSourceCompletionItem *item = GTK_SOURCE_COMPLETION_ITEM (object);

	g_clear_object (&item->priv->icon);
	g_clear_object (&item->priv->gicon);

	G_OBJECT_CLASS (gtk_source_completion_item_parent_class)->dispose (object);
}

static void
gtk_source_completion_item_finalize (GObject *object)
{
	GtkSourceCompletionItem *item = GTK_SOURCE_COMPLETION_ITEM (object);

	g_free (item->priv->label);
	g_free (item->priv->markup);
	g_free (item->priv->text);
	g_free (item->priv->icon_name);
	g_free (item->priv->info);

	G_OBJECT_CLASS (gtk_source_completion_item_parent_class)->finalize (object);
}

static void
gtk_source_completion_item_get_property (GObject    *object,
					 guint       prop_id,
					 GValue     *value,
					 GParamSpec *pspec)
{
	GtkSourceCompletionItem *item;

	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_ITEM (object));

	item = GTK_SOURCE_COMPLETION_ITEM (object);

	switch (prop_id)
	{
		case PROP_LABEL:
			g_value_set_string (value, item->priv->label);
			break;

		case PROP_MARKUP:
			g_value_set_string (value, item->priv->markup);
			break;

		case PROP_TEXT:
			g_value_set_string (value, item->priv->text);
			break;

		case PROP_ICON:
			g_value_set_object (value, item->priv->icon);
			break;

		case PROP_ICON_NAME:
			g_value_set_string (value, item->priv->icon_name);
			break;

		case PROP_GICON:
			g_value_set_object (value, item->priv->gicon);
			break;

		case PROP_INFO:
			g_value_set_string (value, item->priv->info);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
emit_changed (GtkSourceCompletionItem *item)
{
	gtk_source_completion_proposal_changed (GTK_SOURCE_COMPLETION_PROPOSAL (item));
}

static void
gtk_source_completion_item_set_property (GObject      *object,
					 guint         prop_id,
					 const GValue *value,
					 GParamSpec   *pspec)
{
	GtkSourceCompletionItem *item;

	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_ITEM (object));

	item = GTK_SOURCE_COMPLETION_ITEM (object);

	switch (prop_id)
	{
		case PROP_LABEL:
			gtk_source_completion_item_set_label (item, g_value_get_string (value));
			break;

		case PROP_MARKUP:
			gtk_source_completion_item_set_markup (item, g_value_get_string (value));
			break;

		case PROP_TEXT:
			gtk_source_completion_item_set_text (item, g_value_get_string (value));
			break;

		case PROP_ICON:
			gtk_source_completion_item_set_icon (item, g_value_get_object (value));
			break;

		case PROP_ICON_NAME:
			gtk_source_completion_item_set_icon_name (item, g_value_get_string (value));
			break;

		case PROP_GICON:
			gtk_source_completion_item_set_gicon (item, g_value_get_object (value));
			break;

		case PROP_INFO:
			gtk_source_completion_item_set_info (item, g_value_get_string (value));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_completion_item_class_init (GtkSourceCompletionItemClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->dispose = gtk_source_completion_item_dispose;
	object_class->finalize = gtk_source_completion_item_finalize;
	object_class->get_property = gtk_source_completion_item_get_property;
	object_class->set_property = gtk_source_completion_item_set_property;

	/**
	 * GtkSourceCompletionItem:label:
	 *
	 * Label to be shown for this proposal.
	 */
	g_object_class_install_property (object_class,
					 PROP_LABEL,
					 g_param_spec_string ("label",
							      "Label",
							      "",
							      NULL,
							      G_PARAM_READWRITE |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletionItem:markup:
	 *
	 * Label with markup to be shown for this proposal.
	 */
	g_object_class_install_property (object_class,
					 PROP_MARKUP,
					 g_param_spec_string ("markup",
							      "Markup",
							      "",
							      NULL,
							      G_PARAM_READWRITE |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletionItem:text:
	 *
	 * Proposal text.
	 */
	g_object_class_install_property (object_class,
					 PROP_TEXT,
					 g_param_spec_string ("text",
							      "Text",
							      "",
							      NULL,
							      G_PARAM_READWRITE |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletionItem:icon:
	 *
	 * The #GdkPixbuf for the icon to be shown for this proposal.
	 */
	g_object_class_install_property (object_class,
					 PROP_ICON,
					 g_param_spec_object ("icon",
							      "Icon",
							      "",
							      GDK_TYPE_PIXBUF,
							      G_PARAM_READWRITE |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletionItem:icon-name:
	 *
	 * The icon name for the icon to be shown for this proposal.
	 *
	 * Since: 3.18
	 */
	g_object_class_install_property (object_class,
					 PROP_ICON_NAME,
					 g_param_spec_string ("icon-name",
							      "Icon Name",
							      "",
							      NULL,
							      G_PARAM_READWRITE |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletionItem:gicon:
	 *
	 * The #GIcon for the icon to be shown for this proposal.
	 *
	 * Since: 3.18
	 */
	g_object_class_install_property (object_class,
					 PROP_GICON,
					 g_param_spec_object ("gicon",
							      "GIcon",
							      "",
							      G_TYPE_ICON,
							      G_PARAM_READWRITE |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceCompletionItem:info:
	 *
	 * Optional extra information to be shown for this proposal.
	 */
	g_object_class_install_property (object_class,
					 PROP_INFO,
					 g_param_spec_string ("info",
							      "Info",
							      "",
							      NULL,
							      G_PARAM_READWRITE |
							      G_PARAM_STATIC_STRINGS));
}

static void
gtk_source_completion_item_init (GtkSourceCompletionItem *item)
{
	item->priv = gtk_source_completion_item_get_instance_private (item);
}

/**
 * gtk_source_completion_item_new:
 * @label: The item label.
 * @text: The item text.
 * @icon: (nullable): The item icon.
 * @info: (nullable): The item extra information.
 *
 * Create a new #GtkSourceCompletionItem with label @label, icon @icon and
 * extra information @info. Both @icon and @info can be %NULL in which case
 * there will be no icon shown and no extra information available.
 *
 * Returns: a new #GtkSourceCompletionItem.
 * Deprecated: 3.24: Use gtk_source_completion_item_new2() instead.
 */
GtkSourceCompletionItem *
gtk_source_completion_item_new (const gchar *label,
				const gchar *text,
				GdkPixbuf   *icon,
				const gchar *info)
{
	return g_object_new (GTK_SOURCE_TYPE_COMPLETION_ITEM,
			     "label", label,
			     "text", text,
			     "icon", icon,
			     "info", info,
			     NULL);
}

/**
 * gtk_source_completion_item_new_with_markup:
 * @markup: The item markup label.
 * @text: The item text.
 * @icon: (nullable): The item icon.
 * @info: (nullable): The item extra information.
 *
 * Create a new #GtkSourceCompletionItem with markup label @markup, icon
 * @icon and extra information @info. Both @icon and @info can be %NULL in
 * which case there will be no icon shown and no extra information available.
 *
 * Returns: a new #GtkSourceCompletionItem.
 * Deprecated: 3.24: Use gtk_source_completion_item_new2() instead.
 */
GtkSourceCompletionItem *
gtk_source_completion_item_new_with_markup (const gchar *markup,
                                            const gchar *text,
                                            GdkPixbuf   *icon,
                                            const gchar *info)
{
	return g_object_new (GTK_SOURCE_TYPE_COMPLETION_ITEM,
			     "markup", markup,
			     "text", text,
			     "icon", icon,
			     "info", info,
			     NULL);
}

G_GNUC_BEGIN_IGNORE_DEPRECATIONS;

/**
 * gtk_source_completion_item_new_from_stock:
 * @label: (nullable): The item label.
 * @text: The item text.
 * @stock: The stock icon.
 * @info: (nullable): The item extra information.
 *
 * Creates a new #GtkSourceCompletionItem from a stock item. If @label is %NULL,
 * the stock label will be used.
 *
 * Returns: a new #GtkSourceCompletionItem.
 * Deprecated: 3.10: Use gtk_source_completion_item_new2() instead.
 */
GtkSourceCompletionItem *
gtk_source_completion_item_new_from_stock (const gchar *label,
					   const gchar *text,
					   const gchar *stock,
					   const gchar *info)
{
	GtkSourceCompletionItem *item;
	GdkPixbuf *icon;
	GtkIconTheme *theme;
	gint width;
	gint height;
	GtkStockItem stock_item;

	if (stock != NULL)
	{
		theme = gtk_icon_theme_get_default ();

		gtk_icon_size_lookup (GTK_ICON_SIZE_MENU, &width, &height);

		icon = gtk_icon_theme_load_icon (theme,
						 stock,
						 width,
						 GTK_ICON_LOOKUP_USE_BUILTIN,
						 NULL);

		if (label == NULL && gtk_stock_lookup (stock, &stock_item))
		{
			label = stock_item.label;
		}
	}
	else
	{
		icon = NULL;
	}

	item = gtk_source_completion_item_new (label, text, icon, info);

	if (icon != NULL)
	{
		g_object_unref (icon);
	}

	return item;
}

G_GNUC_END_IGNORE_DEPRECATIONS;

/**
 * gtk_source_completion_item_new2:
 *
 * Creates a new #GtkSourceCompletionItem. The desired properties need to be set
 * afterwards.
 *
 * Returns: (transfer full): a new #GtkSourceCompletionItem.
 * Since: 3.24
 */
GtkSourceCompletionItem *
gtk_source_completion_item_new2 (void)
{
	return g_object_new (GTK_SOURCE_TYPE_COMPLETION_ITEM, NULL);
}

/**
 * gtk_source_completion_item_set_label:
 * @item: a #GtkSourceCompletionItem.
 * @label: (nullable): the label, or %NULL.
 *
 * Since: 3.24
 */
void
gtk_source_completion_item_set_label (GtkSourceCompletionItem *item,
				      const gchar             *label)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_ITEM (item));

	if (g_strcmp0 (item->priv->label, label) != 0)
	{
		g_free (item->priv->label);
		item->priv->label = g_strdup (label);

		emit_changed (item);
		g_object_notify (G_OBJECT (item), "label");
	}
}

/**
 * gtk_source_completion_item_set_markup:
 * @item: a #GtkSourceCompletionItem.
 * @markup: (nullable): the markup, or %NULL.
 *
 * Since: 3.24
 */
void
gtk_source_completion_item_set_markup (GtkSourceCompletionItem *item,
				       const gchar             *markup)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_ITEM (item));

	if (g_strcmp0 (item->priv->markup, markup) != 0)
	{
		g_free (item->priv->markup);
		item->priv->markup = g_strdup (markup);

		emit_changed (item);
		g_object_notify (G_OBJECT (item), "markup");
	}
}

/**
 * gtk_source_completion_item_set_text:
 * @item: a #GtkSourceCompletionItem.
 * @text: (nullable): the text, or %NULL.
 *
 * Since: 3.24
 */
void
gtk_source_completion_item_set_text (GtkSourceCompletionItem *item,
				     const gchar             *text)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_ITEM (item));

	if (g_strcmp0 (item->priv->text, text) != 0)
	{
		g_free (item->priv->text);
		item->priv->text = g_strdup (text);

		emit_changed (item);
		g_object_notify (G_OBJECT (item), "text");
	}
}

/**
 * gtk_source_completion_item_set_icon:
 * @item: a #GtkSourceCompletionItem.
 * @icon: (nullable): the #GdkPixbuf, or %NULL.
 *
 * Since: 3.24
 */
void
gtk_source_completion_item_set_icon (GtkSourceCompletionItem *item,
				     GdkPixbuf               *icon)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_ITEM (item));
	g_return_if_fail (icon == NULL || GDK_IS_PIXBUF (icon));

	if (g_set_object (&item->priv->icon, icon))
	{
		emit_changed (item);
		g_object_notify (G_OBJECT (item), "icon");
	}
}

/**
 * gtk_source_completion_item_set_icon_name:
 * @item: a #GtkSourceCompletionItem.
 * @icon_name: (nullable): the icon name, or %NULL.
 *
 * Since: 3.24
 */
void
gtk_source_completion_item_set_icon_name (GtkSourceCompletionItem *item,
					  const gchar             *icon_name)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_ITEM (item));

	if (g_strcmp0 (item->priv->icon_name, icon_name) != 0)
	{
		g_free (item->priv->icon_name);
		item->priv->icon_name = g_strdup (icon_name);

		emit_changed (item);
		g_object_notify (G_OBJECT (item), "icon-name");
	}
}

/**
 * gtk_source_completion_item_set_gicon:
 * @item: a #GtkSourceCompletionItem.
 * @gicon: (nullable): the #GIcon, or %NULL.
 *
 * Since: 3.24
 */
void
gtk_source_completion_item_set_gicon (GtkSourceCompletionItem *item,
				      GIcon                   *gicon)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_ITEM (item));
	g_return_if_fail (gicon == NULL || G_IS_ICON (gicon));

	if (g_set_object (&item->priv->gicon, gicon))
	{
		emit_changed (item);
		g_object_notify (G_OBJECT (item), "gicon");
	}
}

/**
 * gtk_source_completion_item_set_info:
 * @item: a #GtkSourceCompletionItem.
 * @info: (nullable): the info, or %NULL.
 *
 * Since: 3.24
 */
void
gtk_source_completion_item_set_info (GtkSourceCompletionItem *item,
				     const gchar             *info)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_ITEM (item));

	if (g_strcmp0 (item->priv->info, info) != 0)
	{
		g_free (item->priv->info);
		item->priv->info = g_strdup (info);

		emit_changed (item);
		g_object_notify (G_OBJECT (item), "info");
	}
}
