/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 *
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2014 - Christian Hergert
 * Copyright (C) 2014 - Ignacio Casal Quinteiro
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
 * You should have received a copy of the GNU Lesser General Public License
 * along with GtkSourceView. If not, see <http://www.gnu.org/licenses/>.
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcestyleschemechooserwidget.h"
#include "gtksourcestyleschemechooser.h"
#include "gtksourcestylescheme.h"
#include "gtksourcestyleschememanager.h"
#include "gtksourcelanguage.h"
#include "gtksourcelanguagemanager.h"
#include "gtksourcebuffer.h"
#include "gtksourceview.h"

/**
 * SECTION:styleschemechooserwidget
 * @Short_description: A widget for choosing style schemes
 * @Title: GtkSourceStyleSchemeChooserWidget
 * @See_also: #GtkSourceStyleSchemeChooserButton
 *
 * The #GtkSourceStyleSchemeChooserWidget widget lets the user select a
 * style scheme. By default, the chooser presents a predefined list
 * of style schemes.
 *
 * To change the initially selected style scheme,
 * use gtk_source_style_scheme_chooser_set_style_scheme().
 * To get the selected style scheme
 * use gtk_source_style_scheme_chooser_get_style_scheme().
 *
 * Since: 3.16
 */

typedef struct
{
	GtkListBox *list_box;
	GtkSourceStyleScheme *scheme;
} GtkSourceStyleSchemeChooserWidgetPrivate;

static void gtk_source_style_scheme_chooser_widget_style_scheme_chooser_interface_init (GtkSourceStyleSchemeChooserInterface *iface);

G_DEFINE_TYPE_WITH_CODE (GtkSourceStyleSchemeChooserWidget,
                         gtk_source_style_scheme_chooser_widget,
                         GTK_TYPE_BIN,
                         G_ADD_PRIVATE (GtkSourceStyleSchemeChooserWidget)
                         G_IMPLEMENT_INTERFACE (GTK_SOURCE_TYPE_STYLE_SCHEME_CHOOSER,
                                                gtk_source_style_scheme_chooser_widget_style_scheme_chooser_interface_init))

#define GET_PRIV(o) gtk_source_style_scheme_chooser_widget_get_instance_private (o)

enum
{
	PROP_0,
	PROP_STYLE_SCHEME
};

static void
gtk_source_style_scheme_chooser_widget_dispose (GObject *object)
{
	GtkSourceStyleSchemeChooserWidget *widget = GTK_SOURCE_STYLE_SCHEME_CHOOSER_WIDGET (object);
	GtkSourceStyleSchemeChooserWidgetPrivate *priv = GET_PRIV (widget);

	g_clear_object (&priv->scheme);

	G_OBJECT_CLASS (gtk_source_style_scheme_chooser_widget_parent_class)->dispose (object);
}

static void
gtk_source_style_scheme_chooser_widget_get_property (GObject    *object,
                                                     guint       prop_id,
                                                     GValue     *value,
                                                     GParamSpec *pspec)
{
	switch (prop_id)
	{
		case PROP_STYLE_SCHEME:
			g_value_set_object (value,
			                    gtk_source_style_scheme_chooser_get_style_scheme (GTK_SOURCE_STYLE_SCHEME_CHOOSER (object)));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
	}
}

static void
gtk_source_style_scheme_chooser_widget_set_property (GObject      *object,
                                                     guint         prop_id,
                                                     const GValue *value,
                                                     GParamSpec   *pspec)
{
	switch (prop_id)
	{
		case PROP_STYLE_SCHEME:
			gtk_source_style_scheme_chooser_set_style_scheme (GTK_SOURCE_STYLE_SCHEME_CHOOSER (object),
			                                                  g_value_get_object (value));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
	}
}

static void
gtk_source_style_scheme_chooser_widget_class_init (GtkSourceStyleSchemeChooserWidgetClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->dispose = gtk_source_style_scheme_chooser_widget_dispose;
	object_class->get_property = gtk_source_style_scheme_chooser_widget_get_property;
	object_class->set_property = gtk_source_style_scheme_chooser_widget_set_property;

	g_object_class_override_property (object_class, PROP_STYLE_SCHEME, "style-scheme");
}

static GtkWidget *
make_row (GtkSourceStyleScheme *scheme,
          GtkSourceLanguage    *language)
{
	GtkWidget *row;
	AtkObject *accessible;
	GtkWidget *event;
	GtkSourceBuffer *buffer;
	GtkWidget *view;
	gchar *text;

	row = gtk_list_box_row_new ();
	accessible = gtk_widget_get_accessible (row);
	atk_object_set_name (accessible,
	                     gtk_source_style_scheme_get_name (scheme));
	gtk_widget_show (row);

	g_object_set_data (G_OBJECT (row), "scheme", scheme);

	event = gtk_event_box_new ();
	gtk_event_box_set_above_child (GTK_EVENT_BOX (event), TRUE);
	gtk_widget_show (event);
	gtk_container_add (GTK_CONTAINER (row), event);

	buffer = gtk_source_buffer_new_with_language (language);
	gtk_source_buffer_set_highlight_matching_brackets (buffer, FALSE);
	gtk_source_buffer_set_style_scheme (buffer, scheme);

	text = g_strdup_printf ("/* %s */\n#include <gtksourceview/gtksource.h>",
	                        gtk_source_style_scheme_get_name (scheme));
	gtk_text_buffer_set_text (GTK_TEXT_BUFFER (buffer), text, -1);
	g_free (text);

	view = g_object_new (GTK_SOURCE_TYPE_VIEW,
	                     "buffer", buffer,
	                     "can-focus", FALSE,
	                     "cursor-visible", FALSE,
	                     "editable", FALSE,
	                     "visible", TRUE,
	                     "show-line-numbers", TRUE,
	                     "right-margin-position", 30,
	                     "show-right-margin", TRUE,
	                     "margin", 2,
	                     NULL);
	gtk_container_add (GTK_CONTAINER (event), view);

	return row;
}

static void
on_row_selected (GtkListBox                        *list_box,
                 GtkListBoxRow                     *row,
                 GtkSourceStyleSchemeChooserWidget *widget)
{
	GtkSourceStyleSchemeChooserWidgetPrivate *priv = GET_PRIV (widget);

	if (row != NULL)
	{
		GtkSourceStyleScheme *scheme;

		scheme = g_object_get_data (G_OBJECT (row), "scheme");

		if (g_set_object (&priv->scheme, scheme))
		{
			g_object_notify (G_OBJECT (widget), "style-scheme");
		}
	}
}

static void
gtk_source_style_scheme_chooser_widget_populate (GtkSourceStyleSchemeChooserWidget *widget)
{
	GtkSourceStyleSchemeChooserWidgetPrivate *priv = GET_PRIV (widget);
	GtkSourceLanguageManager *lm;
	GtkSourceLanguage *lang;
	GtkSourceStyleSchemeManager *manager;
	const gchar * const *scheme_ids;
	guint i;
	gboolean row_selected = FALSE;

	g_signal_handlers_block_by_func (priv->list_box, on_row_selected, widget);

	gtk_container_foreach (GTK_CONTAINER (priv->list_box),
	                       (GtkCallback)gtk_widget_destroy,
	                       NULL);

	manager = gtk_source_style_scheme_manager_get_default ();
	scheme_ids = gtk_source_style_scheme_manager_get_scheme_ids (manager);

	lm = gtk_source_language_manager_get_default ();
	lang = gtk_source_language_manager_get_language (lm, "c");

	for (i = 0; scheme_ids [i]; i++)
	{
		GtkWidget *row;
		GtkSourceStyleScheme *scheme;

		scheme = gtk_source_style_scheme_manager_get_scheme (manager, scheme_ids [i]);
		row = make_row (scheme, lang);
		gtk_container_add (GTK_CONTAINER (priv->list_box), GTK_WIDGET (row));

		if (scheme == priv->scheme)
		{
			gtk_list_box_select_row (priv->list_box, GTK_LIST_BOX_ROW (row));

			row_selected = TRUE;
		}
	}

	g_signal_handlers_unblock_by_func (priv->list_box, on_row_selected, widget);

	/* The current scheme may have been removed so select the default one */
	if (!row_selected)
	{
		gtk_source_style_scheme_chooser_set_style_scheme (GTK_SOURCE_STYLE_SCHEME_CHOOSER (widget),
		                                                  _gtk_source_style_scheme_get_default ());
	}
}

static void
on_scheme_ids_changed (GtkSourceStyleSchemeManager       *manager,
                       GParamSpec                        *pspec,
                       GtkSourceStyleSchemeChooserWidget *widget)
{
	gtk_source_style_scheme_chooser_widget_populate (widget);
}

static void
gtk_source_style_scheme_chooser_widget_init (GtkSourceStyleSchemeChooserWidget *widget)
{
	GtkSourceStyleSchemeChooserWidgetPrivate *priv = GET_PRIV (widget);
	GtkSourceStyleSchemeManager *manager;

	priv->list_box = GTK_LIST_BOX (gtk_list_box_new ());
	gtk_list_box_set_selection_mode (priv->list_box, GTK_SELECTION_BROWSE);
	gtk_widget_show (GTK_WIDGET (priv->list_box));
	gtk_container_add (GTK_CONTAINER (widget), GTK_WIDGET (priv->list_box));

	manager = gtk_source_style_scheme_manager_get_default ();
	g_signal_connect (manager,
	                  "notify::scheme-ids",
	                  G_CALLBACK (on_scheme_ids_changed),
	                  widget);

	gtk_source_style_scheme_chooser_widget_populate (widget);

	gtk_source_style_scheme_chooser_set_style_scheme (GTK_SOURCE_STYLE_SCHEME_CHOOSER (widget),
	                                                  _gtk_source_style_scheme_get_default ());

	g_signal_connect (priv->list_box,
	                  "row-selected",
	                  G_CALLBACK (on_row_selected),
	                  widget);
}

static GtkSourceStyleScheme *
gtk_source_style_scheme_chooser_widget_get_style_scheme (GtkSourceStyleSchemeChooser *chooser)
{
	GtkSourceStyleSchemeChooserWidget *widget = GTK_SOURCE_STYLE_SCHEME_CHOOSER_WIDGET (chooser);
	GtkSourceStyleSchemeChooserWidgetPrivate *priv = GET_PRIV (widget);

	return priv->scheme;
}

static void
gtk_source_style_scheme_chooser_widget_set_style_scheme (GtkSourceStyleSchemeChooser *chooser,
                                                         GtkSourceStyleScheme        *scheme)
{
	GtkSourceStyleSchemeChooserWidget *widget = GTK_SOURCE_STYLE_SCHEME_CHOOSER_WIDGET (chooser);
	GtkSourceStyleSchemeChooserWidgetPrivate *priv = GET_PRIV (widget);

	if (g_set_object (&priv->scheme, scheme))
	{
		GList *children;
		GList *l;

		children = gtk_container_get_children (GTK_CONTAINER (priv->list_box));

		for (l = children; l != NULL; l = g_list_next (l))
		{
			GtkListBoxRow *row = l->data;
			GtkSourceStyleScheme *cur;

			cur = g_object_get_data (G_OBJECT (row), "scheme");

			if (cur == scheme)
			{
				g_signal_handlers_block_by_func (priv->list_box, on_row_selected, widget);
				gtk_list_box_select_row (priv->list_box, row);
				g_signal_handlers_unblock_by_func (priv->list_box, on_row_selected, widget);
				break;
			}
		}

		g_list_free (children);

		g_object_notify (G_OBJECT (chooser), "style-scheme");
	}
}

static void
gtk_source_style_scheme_chooser_widget_style_scheme_chooser_interface_init (GtkSourceStyleSchemeChooserInterface *iface)
{
	iface->get_style_scheme = gtk_source_style_scheme_chooser_widget_get_style_scheme;
	iface->set_style_scheme = gtk_source_style_scheme_chooser_widget_set_style_scheme;
}

/**
 * gtk_source_style_scheme_chooser_widget_new:
 *
 * Creates a new #GtkSourceStyleSchemeChooserWidget.
 *
 * Returns: a new  #GtkSourceStyleSchemeChooserWidget.
 *
 * Since: 3.16
 */
GtkWidget *
gtk_source_style_scheme_chooser_widget_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_STYLE_SCHEME_CHOOSER_WIDGET, NULL);
}
