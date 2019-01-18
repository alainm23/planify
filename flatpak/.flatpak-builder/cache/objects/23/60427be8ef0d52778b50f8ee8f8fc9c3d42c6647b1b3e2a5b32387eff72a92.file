/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcemarkattributes.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2010 - Jesse van den Kieboom
 * Copyright (C) 2010 - Krzesimir Nowak
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

#include "gtksourcemarkattributes.h"
#include "gtksourcemark.h"
#include "gtksourceview-i18n.h"
#include "gtksourcepixbufhelper.h"

/**
 * SECTION:markattributes
 * @short_description: The source mark attributes object
 * @title: GtkSourceMarkAttributes
 * @see_also: #GtkSourceMark
 *
 * #GtkSourceMarkAttributes is an object specifying attributes used by
 * a #GtkSourceView to visually show lines marked with #GtkSourceMark<!-- -->s
 * of a specific category. It allows you to define a background color of a line,
 * an icon shown in gutter and tooltips.
 *
 * The background color is used as a background of a line where a mark is placed
 * and it can be set with gtk_source_mark_attributes_set_background(). To check
 * if any custom background color was defined and what color it is, use
 * gtk_source_mark_attributes_get_background().
 *
 * An icon is a graphic element which is shown in the gutter of a view. An
 * example use is showing a red filled circle in a debugger to show that a
 * breakpoint was set in certain line. To get an icon that will be placed in
 * a gutter, first a base for it must be specified and then
 * gtk_source_mark_attributes_render_icon() must be called.
 * There are several ways to specify a base for an icon:
 * <itemizedlist>
 *  <listitem>
 *   <para>
 *    gtk_source_mark_attributes_set_icon_name()
 *   </para>
 *  </listitem>
 *  <listitem>
 *   <para>
 *    gtk_source_mark_attributes_set_stock_id()
 *   </para>
 *  </listitem>
 *  <listitem>
 *   <para>
 *    gtk_source_mark_attributes_set_gicon()
 *   </para>
 *  </listitem>
 *  <listitem>
 *   <para>
 *    gtk_source_mark_attributes_set_pixbuf()
 *   </para>
 *  </listitem>
 * </itemizedlist>
 * Using any of the above functions overrides the one used earlier. But note
 * that a getter counterpart of earlier used function can still return some
 * value, but it is just not used when rendering the proper icon.
 *
 * To provide meaningful tooltips for a given mark of a category, you should
 * connect to #GtkSourceMarkAttributes::query-tooltip-text or
 * #GtkSourceMarkAttributes::query-tooltip-markup where the latter
 * takes precedence.
 */

struct _GtkSourceMarkAttributesPrivate
{
	GdkRGBA background;

	GtkSourcePixbufHelper *helper;

	guint background_set : 1;
};

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceMarkAttributes, gtk_source_mark_attributes, G_TYPE_OBJECT)

enum
{
	PROP_0,
	PROP_BACKGROUND,
	PROP_STOCK_ID,
	PROP_PIXBUF,
	PROP_ICON_NAME,
	PROP_GICON
};

enum
{
	QUERY_TOOLTIP_TEXT,
	QUERY_TOOLTIP_MARKUP,
	N_SIGNALS
};

static guint signals[N_SIGNALS];

static void
gtk_source_mark_attributes_finalize (GObject *object)
{
	GtkSourceMarkAttributes *attributes = GTK_SOURCE_MARK_ATTRIBUTES (object);

	gtk_source_pixbuf_helper_free (attributes->priv->helper);

	G_OBJECT_CLASS (gtk_source_mark_attributes_parent_class)->finalize (object);
}

static void
set_background (GtkSourceMarkAttributes *attributes,
		const GdkRGBA           *color)
{
	if (color)
	{
		attributes->priv->background = *color;
	}

	attributes->priv->background_set = color != NULL;

	g_object_notify (G_OBJECT (attributes), "background");
}

static void
set_stock_id (GtkSourceMarkAttributes *attributes,
	      const gchar             *stock_id)
{
	if (0 != g_strcmp0 (gtk_source_pixbuf_helper_get_stock_id (attributes->priv->helper),
	                                                           stock_id))
	{
		gtk_source_pixbuf_helper_set_stock_id (attributes->priv->helper,
				                       stock_id);

		g_object_notify (G_OBJECT (attributes), "stock-id");
	}
}

static void
set_icon_name (GtkSourceMarkAttributes *attributes,
	       const gchar             *icon_name)
{
	if (g_strcmp0 (gtk_source_pixbuf_helper_get_icon_name (attributes->priv->helper),
	                                                       icon_name) == 0)
	{
		return;
	}

	gtk_source_pixbuf_helper_set_icon_name (attributes->priv->helper,
	                                        icon_name);

	g_object_notify (G_OBJECT (attributes), "icon-name");
}

static void
set_pixbuf (GtkSourceMarkAttributes *attributes,
	    const GdkPixbuf         *pixbuf)
{
	if (gtk_source_pixbuf_helper_get_pixbuf (attributes->priv->helper) == pixbuf)
	{
		return;
	}

	gtk_source_pixbuf_helper_set_pixbuf (attributes->priv->helper,
	                                     pixbuf);

	g_object_notify (G_OBJECT (attributes), "pixbuf");
}

static void
set_gicon (GtkSourceMarkAttributes *attributes,
	   GIcon                   *gicon)
{
	if (gtk_source_pixbuf_helper_get_gicon (attributes->priv->helper) == gicon)
	{
		return;
	}

	gtk_source_pixbuf_helper_set_gicon (attributes->priv->helper,
	                                    gicon);

	g_object_notify (G_OBJECT (attributes), "gicon");
}

static void
gtk_source_mark_attributes_set_property (GObject      *object,
					 guint         prop_id,
					 const GValue *value,
					 GParamSpec   *pspec)
{
	GtkSourceMarkAttributes *self = GTK_SOURCE_MARK_ATTRIBUTES (object);

	switch (prop_id)
	{
		case PROP_BACKGROUND:
			set_background (self, g_value_get_boxed (value));
			break;
		case PROP_STOCK_ID:
			set_stock_id (self, g_value_get_string (value));
			break;
		case PROP_PIXBUF:
			set_pixbuf (self, g_value_get_object (value));
			break;
		case PROP_ICON_NAME:
			set_icon_name (self, g_value_get_string (value));
			break;
		case PROP_GICON:
			set_gicon (self, g_value_get_object (value));
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_mark_attributes_get_property (GObject    *object,
					 guint       prop_id,
					 GValue     *value,
					 GParamSpec *pspec)
{
	GtkSourceMarkAttributes *self = GTK_SOURCE_MARK_ATTRIBUTES (object);

	switch (prop_id)
	{
		case PROP_BACKGROUND:
			if (self->priv->background_set)
			{
				g_value_set_boxed (value, &self->priv->background);
			}
			else
			{
				g_value_set_boxed (value, NULL);
			}
			break;
		case PROP_STOCK_ID:
			g_value_set_string (value,
			                    gtk_source_pixbuf_helper_get_stock_id (self->priv->helper));
			break;
		case PROP_PIXBUF:
			g_value_set_object (value,
			                    gtk_source_pixbuf_helper_get_pixbuf (self->priv->helper));
			break;
		case PROP_ICON_NAME:
			g_value_set_string (value,
			                    gtk_source_pixbuf_helper_get_icon_name (self->priv->helper));
			break;
		case PROP_GICON:
			g_value_set_object (value,
			                    gtk_source_pixbuf_helper_get_gicon (self->priv->helper));
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_mark_attributes_class_init (GtkSourceMarkAttributesClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->finalize = gtk_source_mark_attributes_finalize;

	object_class->get_property = gtk_source_mark_attributes_get_property;
	object_class->set_property = gtk_source_mark_attributes_set_property;

	/**
	 * GtkSourceMarkAttributes:background:
	 *
	 * A color used for background of a line.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_BACKGROUND,
	                                 g_param_spec_boxed ("background",
	                                                     "Background",
	                                                     "The background",
	                                                     GDK_TYPE_RGBA,
	                                                     G_PARAM_READWRITE |
							     G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceMarkAttributes:stock-id:
	 *
	 * A stock id that may be a base of a rendered icon.
	 *
	 * Deprecated: 3.10: Don't use this property.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_STOCK_ID,
	                                 g_param_spec_string ("stock-id",
	                                                      "Stock Id",
	                                                      "The stock id",
	                                                      NULL,
	                                                      G_PARAM_READWRITE |
							      G_PARAM_DEPRECATED |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceMarkAttributes:pixbuf:
	 *
	 * A #GdkPixbuf that may be a base of a rendered icon.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_PIXBUF,
	                                 g_param_spec_object ("pixbuf",
	                                                      "Pixbuf",
	                                                      "The pixbuf",
	                                                      GDK_TYPE_PIXBUF,
	                                                      G_PARAM_READWRITE |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceMarkAttributes:icon-name:
	 *
	 * An icon name that may be a base of a rendered icon.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_ICON_NAME,
	                                 g_param_spec_string ("icon-name",
	                                                      "Icon Name",
	                                                      "The icon name",
	                                                      NULL,
	                                                      G_PARAM_READWRITE |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceMarkAttributes:gicon:
	 *
	 * A #GIcon that may be a base of a rendered icon.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_GICON,
	                                 g_param_spec_object ("gicon",
	                                                      "GIcon",
	                                                      "The GIcon",
	                                                      G_TYPE_ICON,
	                                                      G_PARAM_READWRITE |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceMarkAttributes::query-tooltip-text:
	 * @attributes: The #GtkSourceMarkAttributes which emits the signal.
	 * @mark: The #GtkSourceMark.
	 *
	 * The code should connect to this signal to provide a tooltip for given
	 * @mark. The tooltip should be just a plain text.
	 *
	 * Returns: (transfer full): A tooltip. The string should be freed with
	 * g_free() when done with it.
	 */
	signals[QUERY_TOOLTIP_TEXT] =
		g_signal_new ("query-tooltip-text",
		              G_TYPE_FROM_CLASS (klass),
		              G_SIGNAL_RUN_LAST,
		              0,
		              NULL, NULL, NULL,
		              G_TYPE_STRING,
		              1,
		              GTK_SOURCE_TYPE_MARK);

	/**
	 * GtkSourceMarkAttributes::query-tooltip-markup:
	 * @attributes: The #GtkSourceMarkAttributes which emits the signal.
	 * @mark: The #GtkSourceMark.
	 *
	 * The code should connect to this signal to provide a tooltip for given
	 * @mark. The tooltip can contain a markup.
	 *
	 * Returns: (transfer full): A tooltip. The string should be freed with
	 * g_free() when done with it.
	 */
	signals[QUERY_TOOLTIP_MARKUP] =
		g_signal_new ("query-tooltip-markup",
		              G_TYPE_FROM_CLASS (klass),
		              G_SIGNAL_RUN_LAST,
		              0,
		              NULL, NULL, NULL,
		              G_TYPE_STRING,
		              1,
		              GTK_SOURCE_TYPE_MARK);
}

static void
gtk_source_mark_attributes_init (GtkSourceMarkAttributes *self)
{
	self->priv = gtk_source_mark_attributes_get_instance_private (self);

	self->priv->helper = gtk_source_pixbuf_helper_new ();
}

/**
 * gtk_source_mark_attributes_new:
 *
 * Creates a new source mark attributes.
 *
 * Returns: (transfer full): a new source mark attributes.
 */
GtkSourceMarkAttributes *
gtk_source_mark_attributes_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_MARK_ATTRIBUTES, NULL);
}

/**
 * gtk_source_mark_attributes_set_background:
 * @attributes: a #GtkSourceMarkAttributes.
 * @background: a #GdkRGBA.
 *
 * Sets background color to the one given in @background.
 */
void
gtk_source_mark_attributes_set_background (GtkSourceMarkAttributes *attributes,
					   const GdkRGBA           *background)
{
	g_return_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes));

	set_background (attributes, background);
}

/**
 * gtk_source_mark_attributes_get_background:
 * @attributes: a #GtkSourceMarkAttributes.
 * @background: (out caller-allocates): a #GdkRGBA.
 *
 * Stores background color in @background.
 *
 * Returns: whether background color for @attributes was set.
 */
gboolean
gtk_source_mark_attributes_get_background (GtkSourceMarkAttributes *attributes,
					   GdkRGBA                 *background)
{
	g_return_val_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes), FALSE);

	if (background)
	{
		*background = attributes->priv->background;
	}
	return attributes->priv->background_set;
}

/**
 * gtk_source_mark_attributes_set_stock_id:
 * @attributes: a #GtkSourceMarkAttributes.
 * @stock_id: a stock id.
 *
 * Sets stock id to be used as a base for rendered icon.
 *
 * Deprecated: 3.10: Don't use this function.
 */
void
gtk_source_mark_attributes_set_stock_id (GtkSourceMarkAttributes *attributes,
					 const gchar             *stock_id)
{
	g_return_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes));

	set_stock_id (attributes, stock_id);
}

/**
 * gtk_source_mark_attributes_get_stock_id:
 * @attributes: a #GtkSourceMarkAttributes.
 *
 * Gets a stock id of an icon used by this attributes. Note that the stock id can
 * be %NULL if it wasn't set earlier.
 *
 * Returns: (transfer none): Stock id. Returned string is owned by @attributes and
 * shouldn't be freed.
 *
 * Deprecated: 3.10: Don't use this function.
 */
const gchar *
gtk_source_mark_attributes_get_stock_id (GtkSourceMarkAttributes *attributes)
{
	g_return_val_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes), NULL);

	return gtk_source_pixbuf_helper_get_stock_id (attributes->priv->helper);
}

/**
 * gtk_source_mark_attributes_set_icon_name:
 * @attributes: a #GtkSourceMarkAttributes.
 * @icon_name: name of an icon to be used.
 *
 * Sets a name of an icon to be used as a base for rendered icon.
 */
void
gtk_source_mark_attributes_set_icon_name (GtkSourceMarkAttributes *attributes,
					  const gchar             *icon_name)
{
	g_return_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes));

	set_icon_name (attributes, icon_name);
}

/**
 * gtk_source_mark_attributes_get_icon_name:
 * @attributes: a #GtkSourceMarkAttributes.
 *
 * Gets a name of an icon to be used as a base for rendered icon. Note that the
 * icon name can be %NULL if it wasn't set earlier.
 *
 * Returns: (transfer none): An icon name. The string belongs to @attributes and
 * should not be freed.
 */
const gchar *
gtk_source_mark_attributes_get_icon_name (GtkSourceMarkAttributes *attributes)
{
	g_return_val_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes), NULL);

	return gtk_source_pixbuf_helper_get_icon_name (attributes->priv->helper);
}

/**
 * gtk_source_mark_attributes_set_gicon:
 * @attributes: a #GtkSourceMarkAttributes.
 * @gicon: a #GIcon to be used.
 *
 * Sets an icon to be used as a base for rendered icon.
 */
void
gtk_source_mark_attributes_set_gicon (GtkSourceMarkAttributes *attributes,
				      GIcon                   *gicon)
{
	g_return_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes));

	set_gicon (attributes, gicon);
}

/**
 * gtk_source_mark_attributes_get_gicon:
 * @attributes: a #GtkSourceMarkAttributes.
 *
 * Gets a #GIcon to be used as a base for rendered icon. Note that the icon can
 * be %NULL if it wasn't set earlier.
 *
 * Returns: (transfer none): An icon. The icon belongs to @attributes and should
 * not be unreffed.
 */
GIcon *
gtk_source_mark_attributes_get_gicon (GtkSourceMarkAttributes *attributes)
{
	g_return_val_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes), NULL);

	return gtk_source_pixbuf_helper_get_gicon (attributes->priv->helper);
}

/**
 * gtk_source_mark_attributes_set_pixbuf:
 * @attributes: a #GtkSourceMarkAttributes.
 * @pixbuf: a #GdkPixbuf to be used.
 *
 * Sets a pixbuf to be used as a base for rendered icon.
 */
void
gtk_source_mark_attributes_set_pixbuf (GtkSourceMarkAttributes *attributes,
				       const GdkPixbuf         *pixbuf)
{
	g_return_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes));

	set_pixbuf (attributes, pixbuf);
}

/**
 * gtk_source_mark_attributes_get_pixbuf:
 * @attributes: a #GtkSourceMarkAttributes.
 *
 * Gets a #GdkPixbuf to be used as a base for rendered icon. Note that the
 * pixbuf can be %NULL if it wasn't set earlier.
 *
 * Returns: (transfer none): A pixbuf. The pixbuf belongs to @attributes and
 * should not be unreffed.
 */
const GdkPixbuf *
gtk_source_mark_attributes_get_pixbuf (GtkSourceMarkAttributes *attributes)
{
	g_return_val_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes), NULL);

	return gtk_source_pixbuf_helper_get_pixbuf (attributes->priv->helper);
}

/**
 * gtk_source_mark_attributes_render_icon:
 * @attributes: a #GtkSourceMarkAttributes.
 * @widget: widget of which style settings may be used.
 * @size: size of the rendered icon.
 *
 * Renders an icon of given size. The base of the icon is set by the last call
 * to one of: gtk_source_mark_attributes_set_pixbuf(),
 * gtk_source_mark_attributes_set_gicon(),
 * gtk_source_mark_attributes_set_icon_name() or
 * gtk_source_mark_attributes_set_stock_id(). @size cannot be lower than 1.
 *
 * Returns: (transfer none): A rendered pixbuf. The pixbuf belongs to @attributes
 * and should not be unreffed.
 */
const GdkPixbuf *
gtk_source_mark_attributes_render_icon (GtkSourceMarkAttributes *attributes,
					GtkWidget               *widget,
					gint                     size)
{
	g_return_val_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes), NULL);
	g_return_val_if_fail (GTK_IS_WIDGET (widget), NULL);
	g_return_val_if_fail (size > 0, NULL);

	return gtk_source_pixbuf_helper_render (attributes->priv->helper,
	                                        widget,
	                                        size);
}

/**
 * gtk_source_mark_attributes_get_tooltip_text:
 * @attributes: a #GtkSourceMarkAttributes.
 * @mark: a #GtkSourceMark.
 *
 * Queries for a tooltip by emitting
 * a #GtkSourceMarkAttributes::query-tooltip-text signal. The tooltip is a plain
 * text.
 *
 * Returns: (transfer full): A tooltip. The returned string should be freed by
 * using g_free() when done with it.
 */
gchar *
gtk_source_mark_attributes_get_tooltip_text (GtkSourceMarkAttributes *attributes,
					     GtkSourceMark           *mark)
{
	gchar *ret;

	g_return_val_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes), NULL);
	g_return_val_if_fail (GTK_SOURCE_IS_MARK (mark), NULL);

	ret = NULL;
	g_signal_emit (attributes, signals[QUERY_TOOLTIP_TEXT], 0, mark, &ret);

	return ret;
}

/**
 * gtk_source_mark_attributes_get_tooltip_markup:
 * @attributes: a #GtkSourceMarkAttributes.
 * @mark: a #GtkSourceMark.
 *
 * Queries for a tooltip by emitting
 * a #GtkSourceMarkAttributes::query-tooltip-markup signal. The tooltip may contain
 * a markup.
 *
 * Returns: (transfer full): A tooltip. The returned string should be freed by
 * using g_free() when done with it.
 */
gchar *
gtk_source_mark_attributes_get_tooltip_markup (GtkSourceMarkAttributes *attributes,
					       GtkSourceMark           *mark)
{
	gchar *ret;

	g_return_val_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes), NULL);
	g_return_val_if_fail (GTK_SOURCE_IS_MARK (mark), NULL);

	ret = NULL;
	g_signal_emit (attributes, signals[QUERY_TOOLTIP_MARKUP], 0, mark, &ret);

	return ret;
}

