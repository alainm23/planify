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

#include "gtksourcestyleschemechooserbutton.h"
#include "gtksourcestyleschemechooser.h"
#include "gtksourcestyleschemechooserwidget.h"
#include "gtksourcestylescheme.h"
#include "gtksourceview-i18n.h"

/**
 * SECTION:styleschemechooserbutton
 * @Short_description: A button to launch a style scheme selection dialog
 * @Title: GtkSourceStyleSchemeChooserButton
 * @See_also: #GtkSourceStyleSchemeChooserWidget
 *
 * The #GtkSourceStyleSchemeChooserButton is a button which displays
 * the currently selected style scheme and allows to open a style scheme
 * selection dialog to change the style scheme.
 * It is suitable widget for selecting a style scheme in a preference dialog.
 *
 * In #GtkSourceStyleSchemeChooserButton, a #GtkSourceStyleSchemeChooserWidget
 * is used to provide a dialog for selecting style schemes.
 *
 * Since: 3.16
 */

typedef struct
{
	GtkSourceStyleScheme *scheme;

	GtkWidget *dialog;
	GtkSourceStyleSchemeChooserWidget *chooser;
} GtkSourceStyleSchemeChooserButtonPrivate;

static void gtk_source_style_scheme_chooser_button_style_scheme_chooser_interface_init (GtkSourceStyleSchemeChooserInterface *iface);

G_DEFINE_TYPE_WITH_CODE (GtkSourceStyleSchemeChooserButton,
                         gtk_source_style_scheme_chooser_button,
                         GTK_TYPE_BUTTON,
                         G_ADD_PRIVATE (GtkSourceStyleSchemeChooserButton)
                         G_IMPLEMENT_INTERFACE (GTK_SOURCE_TYPE_STYLE_SCHEME_CHOOSER,
                                                gtk_source_style_scheme_chooser_button_style_scheme_chooser_interface_init))

#define GET_PRIV(o) gtk_source_style_scheme_chooser_button_get_instance_private (o)

enum
{
	PROP_0,
	PROP_STYLE_SCHEME
};

static void
gtk_source_style_scheme_chooser_button_dispose (GObject *object)
{
	GtkSourceStyleSchemeChooserButton *button = GTK_SOURCE_STYLE_SCHEME_CHOOSER_BUTTON (object);
	GtkSourceStyleSchemeChooserButtonPrivate *priv = GET_PRIV (button);

	g_clear_object (&priv->scheme);

	G_OBJECT_CLASS (gtk_source_style_scheme_chooser_button_parent_class)->dispose (object);
}

static void
gtk_source_style_scheme_chooser_button_get_property (GObject    *object,
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
gtk_source_style_scheme_chooser_button_set_property (GObject      *object,
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
gtk_source_style_scheme_chooser_button_constructed (GObject *object)
{
	GtkSourceStyleSchemeChooserButton *button = GTK_SOURCE_STYLE_SCHEME_CHOOSER_BUTTON (object);

	G_OBJECT_CLASS (gtk_source_style_scheme_chooser_button_parent_class)->constructed (object);

	gtk_source_style_scheme_chooser_set_style_scheme (GTK_SOURCE_STYLE_SCHEME_CHOOSER (button),
	                                                  _gtk_source_style_scheme_get_default ());
}

static gboolean
dialog_destroy (GtkWidget *widget,
                gpointer   data)
{
	GtkSourceStyleSchemeChooserButton *button = GTK_SOURCE_STYLE_SCHEME_CHOOSER_BUTTON (data);
	GtkSourceStyleSchemeChooserButtonPrivate *priv = GET_PRIV (button);

	priv->dialog = NULL;
	priv->chooser = NULL;

	return FALSE;
}

static void
dialog_response (GtkDialog *dialog,
                 gint       response,
                 gpointer   data)
{
	if (response == GTK_RESPONSE_CANCEL)
	{
		gtk_widget_hide (GTK_WIDGET (dialog));
	}
	else if (response == GTK_RESPONSE_OK)
	{
		GtkSourceStyleSchemeChooserButton *button = GTK_SOURCE_STYLE_SCHEME_CHOOSER_BUTTON (data);
		GtkSourceStyleSchemeChooserButtonPrivate *priv = GET_PRIV (button);
		GtkSourceStyleScheme *scheme;

		scheme = gtk_source_style_scheme_chooser_get_style_scheme (GTK_SOURCE_STYLE_SCHEME_CHOOSER (priv->chooser));

		gtk_widget_hide (GTK_WIDGET (dialog));

		gtk_source_style_scheme_chooser_set_style_scheme (GTK_SOURCE_STYLE_SCHEME_CHOOSER (button),
		                                                  scheme);
	}
}

/* Create the dialog and connects its buttons */
static void
ensure_dialog (GtkSourceStyleSchemeChooserButton *button)
{
	GtkSourceStyleSchemeChooserButtonPrivate *priv = GET_PRIV (button);
	GtkWidget *parent, *dialog, *scrolled_window;
	GtkWidget *content_area;

	if (priv->dialog != NULL)
	{
		return;
	}

	parent = gtk_widget_get_toplevel (GTK_WIDGET (button));

	/* TODO: have a ChooserDialog? */
	priv->dialog = dialog = gtk_dialog_new_with_buttons (_("Select a Style"),
	                                                     GTK_WINDOW (parent),
	                                                     GTK_DIALOG_DESTROY_WITH_PARENT |
	                                                     GTK_DIALOG_USE_HEADER_BAR,
	                                                     _("_Cancel"), GTK_RESPONSE_CANCEL,
	                                                     _("_Select"), GTK_RESPONSE_OK,
	                                                     NULL);
	gtk_dialog_set_default_response (GTK_DIALOG (dialog), GTK_RESPONSE_OK);

	scrolled_window = gtk_scrolled_window_new (NULL, NULL);
	gtk_widget_set_size_request (scrolled_window, 325, 350);
	gtk_widget_show (scrolled_window);
	gtk_widget_set_hexpand (scrolled_window, TRUE);
	gtk_widget_set_vexpand (scrolled_window, TRUE);
	content_area = gtk_dialog_get_content_area (GTK_DIALOG (dialog));
	gtk_container_add (GTK_CONTAINER (content_area), scrolled_window);

	priv->chooser = GTK_SOURCE_STYLE_SCHEME_CHOOSER_WIDGET (gtk_source_style_scheme_chooser_widget_new ());
	gtk_widget_show (GTK_WIDGET (priv->chooser));
	gtk_source_style_scheme_chooser_set_style_scheme (GTK_SOURCE_STYLE_SCHEME_CHOOSER (priv->chooser),
	                                                  priv->scheme);

	gtk_container_add (GTK_CONTAINER (scrolled_window), GTK_WIDGET (priv->chooser));

	if (gtk_widget_is_toplevel (parent) && GTK_IS_WINDOW (parent))
	{
		if (GTK_WINDOW (parent) != gtk_window_get_transient_for (GTK_WINDOW (dialog)))
		{
			gtk_window_set_transient_for (GTK_WINDOW (dialog), GTK_WINDOW (parent));
		}

		gtk_window_set_modal (GTK_WINDOW (dialog),
		                      gtk_window_get_modal (GTK_WINDOW (parent)));
	}

	g_signal_connect (dialog, "response",
	                  G_CALLBACK (dialog_response), button);
	g_signal_connect (dialog, "destroy",
	                  G_CALLBACK (dialog_destroy), button);
}

static void
gtk_source_style_scheme_chooser_button_clicked (GtkButton *button)
{
	GtkSourceStyleSchemeChooserButton *cbutton = GTK_SOURCE_STYLE_SCHEME_CHOOSER_BUTTON (button);
	GtkSourceStyleSchemeChooserButtonPrivate *priv = GET_PRIV (cbutton);

	ensure_dialog (cbutton);

	gtk_source_style_scheme_chooser_set_style_scheme (GTK_SOURCE_STYLE_SCHEME_CHOOSER (priv->chooser),
	                                                  priv->scheme);

	gtk_window_present (GTK_WINDOW (priv->dialog));
}

static void
gtk_source_style_scheme_chooser_button_class_init (GtkSourceStyleSchemeChooserButtonClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	GtkButtonClass *button_class = GTK_BUTTON_CLASS (klass);

	object_class->dispose = gtk_source_style_scheme_chooser_button_dispose;
	object_class->get_property = gtk_source_style_scheme_chooser_button_get_property;
	object_class->set_property = gtk_source_style_scheme_chooser_button_set_property;
	object_class->constructed = gtk_source_style_scheme_chooser_button_constructed;

	button_class->clicked = gtk_source_style_scheme_chooser_button_clicked;

	g_object_class_override_property (object_class, PROP_STYLE_SCHEME, "style-scheme");
}

static void
gtk_source_style_scheme_chooser_button_init (GtkSourceStyleSchemeChooserButton *button)
{
}

static GtkSourceStyleScheme *
gtk_source_style_scheme_chooser_button_get_style_scheme (GtkSourceStyleSchemeChooser *chooser)
{
	GtkSourceStyleSchemeChooserButton *button = GTK_SOURCE_STYLE_SCHEME_CHOOSER_BUTTON (chooser);
	GtkSourceStyleSchemeChooserButtonPrivate *priv = GET_PRIV (button);

	return priv->scheme;
}

static void
gtk_source_style_scheme_chooser_button_update_label (GtkSourceStyleSchemeChooserButton *button)
{
	GtkSourceStyleSchemeChooserButtonPrivate *priv = GET_PRIV (button);
	const gchar *label;

	label = priv->scheme != NULL ? gtk_source_style_scheme_get_name (priv->scheme) : NULL;
	gtk_button_set_label (GTK_BUTTON (button), label);
}

static void
gtk_source_style_scheme_chooser_button_set_style_scheme (GtkSourceStyleSchemeChooser *chooser,
                                                         GtkSourceStyleScheme        *scheme)
{
	GtkSourceStyleSchemeChooserButton *button = GTK_SOURCE_STYLE_SCHEME_CHOOSER_BUTTON (chooser);
	GtkSourceStyleSchemeChooserButtonPrivate *priv = GET_PRIV (button);

	if (g_set_object (&priv->scheme, scheme))
	{
		gtk_source_style_scheme_chooser_button_update_label (button);

		g_object_notify (G_OBJECT (button), "style-scheme");
	}
}

static void
gtk_source_style_scheme_chooser_button_style_scheme_chooser_interface_init (GtkSourceStyleSchemeChooserInterface *iface)
{
	iface->get_style_scheme = gtk_source_style_scheme_chooser_button_get_style_scheme;
	iface->set_style_scheme = gtk_source_style_scheme_chooser_button_set_style_scheme;
}

/**
 * gtk_source_style_scheme_chooser_button_new:
 *
 * Creates a new #GtkSourceStyleSchemeChooserButton.
 *
 * Returns: a new #GtkSourceStyleSchemeChooserButton.
 *
 * Since: 3.16
 */
GtkWidget *
gtk_source_style_scheme_chooser_button_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_STYLE_SCHEME_CHOOSER_BUTTON, NULL);
}
