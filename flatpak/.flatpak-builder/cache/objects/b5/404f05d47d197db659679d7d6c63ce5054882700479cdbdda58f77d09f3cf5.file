/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcegutterrendererpixbuf.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2010 - Jesse van den Kieboom
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

#include "gtksourcegutterrendererpixbuf.h"
#include "gtksourceview-i18n.h"
#include "gtksourcepixbufhelper.h"

/**
 * SECTION:gutterrendererpixbuf
 * @Short_description: Renders a pixbuf in the gutter
 * @Title: GtkSourceGutterRendererPixbuf
 * @See_also: #GtkSourceGutterRenderer, #GtkSourceGutter
 *
 * A #GtkSourceGutterRendererPixbuf can be used to render an image in a cell of
 * #GtkSourceGutter.
 */

struct _GtkSourceGutterRendererPixbufPrivate
{
	GtkSourcePixbufHelper *helper;
};

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceGutterRendererPixbuf, gtk_source_gutter_renderer_pixbuf, GTK_SOURCE_TYPE_GUTTER_RENDERER)

enum
{
	PROP_0,
	PROP_PIXBUF,
	PROP_STOCK_ID,
	PROP_ICON_NAME,
	PROP_GICON,
};

static void
center_on (GtkSourceGutterRenderer *renderer,
           GdkRectangle            *cell_area,
           GtkTextIter             *iter,
           gint                     width,
           gint                     height,
           gfloat                   xalign,
           gfloat                   yalign,
           gint                    *x,
           gint                    *y)
{
	GtkTextView *view;
	GtkTextWindowType window_type;
	GdkRectangle buffer_location;
	gint window_y;

	view = gtk_source_gutter_renderer_get_view (renderer);
	window_type = gtk_source_gutter_renderer_get_window_type (renderer);

	gtk_text_view_get_iter_location (view, iter, &buffer_location);

	gtk_text_view_buffer_to_window_coords (view,
					       window_type,
					       0, buffer_location.y,
					       NULL, &window_y);

	*x = cell_area->x + (cell_area->width - width) * xalign;
	*y = window_y + (buffer_location.height - height) * yalign;
}

static void
gutter_renderer_pixbuf_draw (GtkSourceGutterRenderer      *renderer,
                             cairo_t                      *cr,
                             GdkRectangle                 *background_area,
                             GdkRectangle                 *cell_area,
                             GtkTextIter                  *start,
                             GtkTextIter                  *end,
                             GtkSourceGutterRendererState  state)
{
	GtkSourceGutterRendererPixbuf *pix = GTK_SOURCE_GUTTER_RENDERER_PIXBUF (renderer);
	gint width;
	gint height;
	gfloat xalign;
	gfloat yalign;
	GtkSourceGutterRendererAlignmentMode mode;
	GtkTextView *view;
	gint scale;
	gint x = 0;
	gint y = 0;
	GdkPixbuf *pixbuf;
	cairo_surface_t *surface;

	/* Chain up to draw background */
	if (GTK_SOURCE_GUTTER_RENDERER_CLASS (gtk_source_gutter_renderer_pixbuf_parent_class)->draw != NULL)
	{
		GTK_SOURCE_GUTTER_RENDERER_CLASS (gtk_source_gutter_renderer_pixbuf_parent_class)->draw (renderer,
													 cr,
													 background_area,
													 cell_area,
													 start,
													 end,
													 state);
	}

	view = gtk_source_gutter_renderer_get_view (renderer);

	pixbuf = gtk_source_pixbuf_helper_render (pix->priv->helper,
	                                          GTK_WIDGET (view),
	                                          cell_area->width);

	if (!pixbuf)
	{
		return;
	}

	width = gdk_pixbuf_get_width (pixbuf);
	height = gdk_pixbuf_get_height (pixbuf);

	/*
	 * We might have gotten a pixbuf back from the helper that will allow
	 * us to render for HiDPI. If we detect this, we pretend that we got a
	 * different size back and then gdk_cairo_surface_create_from_pixbuf()
	 * will take care of the rest.
	 */
	scale = gtk_widget_get_scale_factor (GTK_WIDGET (view));
	if ((scale > 1) &&
	    ((width > cell_area->width) || (height > cell_area->height)) &&
	    (width <= (cell_area->width * scale)) &&
	    (height <= (cell_area->height * scale)))
	{
		width = width / scale;
		height = height / scale;
	}

	gtk_source_gutter_renderer_get_alignment (renderer,
	                                          &xalign,
	                                          &yalign);

	mode = gtk_source_gutter_renderer_get_alignment_mode (renderer);

	switch (mode)
	{
		case GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_CELL:
			x = cell_area->x + (cell_area->width - width) * xalign;
			y = cell_area->y + (cell_area->height - height) * yalign;
			break;
		case GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_FIRST:
			center_on (renderer,
			           cell_area,
			           start,
			           width,
			           height,
			           xalign,
			           yalign,
			           &x,
			           &y);
			break;
		case GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_LAST:
			center_on (renderer,
			           cell_area,
			           end,
			           width,
			           height,
			           xalign,
			           yalign,
			           &x,
			           &y);
			break;
		default:
			g_assert_not_reached ();
	}

	surface = gdk_cairo_surface_create_from_pixbuf (pixbuf, scale, NULL);
	cairo_set_source_surface (cr, surface, x, y);

	cairo_paint (cr);

	cairo_surface_destroy (surface);
}

static void
gtk_source_gutter_renderer_pixbuf_finalize (GObject *object)
{
	GtkSourceGutterRendererPixbuf *renderer = GTK_SOURCE_GUTTER_RENDERER_PIXBUF (object);

	gtk_source_pixbuf_helper_free (renderer->priv->helper);

	G_OBJECT_CLASS (gtk_source_gutter_renderer_pixbuf_parent_class)->finalize (object);
}

static void
set_pixbuf (GtkSourceGutterRendererPixbuf *renderer,
            GdkPixbuf                     *pixbuf)
{
	gtk_source_pixbuf_helper_set_pixbuf (renderer->priv->helper,
	                                     pixbuf);

	g_object_notify (G_OBJECT (renderer), "pixbuf");

	gtk_source_gutter_renderer_queue_draw (GTK_SOURCE_GUTTER_RENDERER (renderer));
}

static void
set_stock_id (GtkSourceGutterRendererPixbuf *renderer,
              const gchar                   *stock_id)
{
	gtk_source_pixbuf_helper_set_stock_id (renderer->priv->helper,
	                                       stock_id);

	g_object_notify (G_OBJECT (renderer), "stock-id");

	gtk_source_gutter_renderer_queue_draw (GTK_SOURCE_GUTTER_RENDERER (renderer));
}

static void
set_gicon (GtkSourceGutterRendererPixbuf *renderer,
           GIcon                         *icon)
{
	gtk_source_pixbuf_helper_set_gicon (renderer->priv->helper,
	                                    icon);

	g_object_notify (G_OBJECT (renderer), "gicon");

	gtk_source_gutter_renderer_queue_draw (GTK_SOURCE_GUTTER_RENDERER (renderer));
}

static void
set_icon_name (GtkSourceGutterRendererPixbuf *renderer,
               const gchar                   *icon_name)
{
	gtk_source_pixbuf_helper_set_icon_name (renderer->priv->helper,
	                                        icon_name);

	g_object_notify (G_OBJECT (renderer), "icon-name");

	gtk_source_gutter_renderer_queue_draw (GTK_SOURCE_GUTTER_RENDERER (renderer));
}


static void
gtk_source_gutter_renderer_pixbuf_set_property (GObject      *object,
                                                guint         prop_id,
                                                const GValue *value,
                                                GParamSpec   *pspec)
{
	GtkSourceGutterRendererPixbuf *renderer;

	renderer = GTK_SOURCE_GUTTER_RENDERER_PIXBUF (object);

	switch (prop_id)
	{
		case PROP_PIXBUF:
			set_pixbuf (renderer, g_value_get_object (value));
			break;
		case PROP_STOCK_ID:
			set_stock_id (renderer, g_value_get_string (value));
			break;
		case PROP_ICON_NAME:
			set_icon_name (renderer, g_value_get_string (value));
			break;
		case PROP_GICON:
			set_gicon (renderer, g_value_get_object (value));
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_gutter_renderer_pixbuf_get_property (GObject    *object,
                                                guint       prop_id,
                                                GValue     *value,
                                                GParamSpec *pspec)
{
	GtkSourceGutterRendererPixbuf *renderer;

	renderer = GTK_SOURCE_GUTTER_RENDERER_PIXBUF (object);

	switch (prop_id)
	{
		case PROP_PIXBUF:
			g_value_set_object (value,
			                    gtk_source_pixbuf_helper_get_pixbuf (renderer->priv->helper));
			break;
		case PROP_STOCK_ID:
			g_value_set_string (value,
			                    gtk_source_pixbuf_helper_get_stock_id (renderer->priv->helper));
			break;
		case PROP_ICON_NAME:
			g_value_set_string (value,
			                    gtk_source_pixbuf_helper_get_icon_name (renderer->priv->helper));
			break;
		case PROP_GICON:
			g_value_set_object (value,
			                    gtk_source_pixbuf_helper_get_gicon (renderer->priv->helper));
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_gutter_renderer_pixbuf_class_init (GtkSourceGutterRendererPixbufClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	GtkSourceGutterRendererClass *renderer_class = GTK_SOURCE_GUTTER_RENDERER_CLASS (klass);

	object_class->finalize = gtk_source_gutter_renderer_pixbuf_finalize;

	object_class->get_property = gtk_source_gutter_renderer_pixbuf_get_property;
	object_class->set_property = gtk_source_gutter_renderer_pixbuf_set_property;

	renderer_class->draw = gutter_renderer_pixbuf_draw;

	g_object_class_install_property (object_class,
	                                 PROP_PIXBUF,
	                                 g_param_spec_object ("pixbuf",
	                                                      "Pixbuf",
	                                                      "The pixbuf",
	                                                      GDK_TYPE_PIXBUF,
	                                                      G_PARAM_READWRITE));

	/**
	 * GtkSourceGutterRendererPixbuf:stock-id:
	 *
	 * The stock id.
	 *
	 * Deprecated: 3.10: Don't use this property.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_STOCK_ID,
	                                 g_param_spec_string ("stock-id",
	                                                      "Stock Id",
	                                                      "The stock id",
	                                                      NULL,
	                                                      G_PARAM_READWRITE | G_PARAM_DEPRECATED));

	g_object_class_install_property (object_class,
	                                 PROP_ICON_NAME,
	                                 g_param_spec_string ("icon-name",
	                                                      "Icon Name",
	                                                      "The icon name",
	                                                      NULL,
	                                                      G_PARAM_READWRITE));

	g_object_class_install_property (object_class,
	                                 PROP_GICON,
	                                 g_param_spec_object ("gicon",
	                                                      "GIcon",
	                                                      "The gicon",
	                                                      G_TYPE_ICON,
	                                                      G_PARAM_READWRITE));
}

static void
gtk_source_gutter_renderer_pixbuf_init (GtkSourceGutterRendererPixbuf *self)
{
	self->priv = gtk_source_gutter_renderer_pixbuf_get_instance_private (self);

	self->priv->helper = gtk_source_pixbuf_helper_new ();
}

/**
 * gtk_source_gutter_renderer_pixbuf_new:
 *
 * Create a new #GtkSourceGutterRendererPixbuf.
 *
 * Returns: (transfer full): A #GtkSourceGutterRenderer
 *
 **/
GtkSourceGutterRenderer *
gtk_source_gutter_renderer_pixbuf_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_GUTTER_RENDERER_PIXBUF, NULL);
}

/**
 * gtk_source_gutter_renderer_pixbuf_set_pixbuf:
 * @renderer: a #GtkSourceGutterRendererPixbuf
 * @pixbuf: (nullable): the pixbuf, or %NULL.
 */
void
gtk_source_gutter_renderer_pixbuf_set_pixbuf (GtkSourceGutterRendererPixbuf *renderer,
                                              GdkPixbuf                     *pixbuf)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_PIXBUF (renderer));
	g_return_if_fail (renderer == NULL || GDK_IS_PIXBUF (pixbuf));

	set_pixbuf (renderer, pixbuf);
}


/**
 * gtk_source_gutter_renderer_pixbuf_get_pixbuf:
 * @renderer: a #GtkSourceGutterRendererPixbuf
 *
 * Get the pixbuf of the renderer.
 *
 * Returns: (transfer none): a #GdkPixbuf
 *
 **/
GdkPixbuf *
gtk_source_gutter_renderer_pixbuf_get_pixbuf (GtkSourceGutterRendererPixbuf *renderer)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_PIXBUF (renderer), NULL);

	return gtk_source_pixbuf_helper_get_pixbuf (renderer->priv->helper);
}

/**
 * gtk_source_gutter_renderer_pixbuf_set_stock_id:
 * @renderer: a #GtkSourceGutterRendererPixbuf
 * @stock_id: (nullable): the stock id
 *
 * Deprecated: 3.10: Don't use this function.
 */
void
gtk_source_gutter_renderer_pixbuf_set_stock_id (GtkSourceGutterRendererPixbuf *renderer,
                                                const gchar                   *stock_id)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_PIXBUF_CLASS (renderer));

	set_stock_id (renderer, stock_id);
}

/**
 * gtk_source_gutter_renderer_pixbuf_get_stock_id:
 * @renderer: a #GtkSourceGutterRendererPixbuf
 *
 * Returns: the stock id.
 * Deprecated: 3.10: Don't use this function.
 */
const gchar *
gtk_source_gutter_renderer_pixbuf_get_stock_id (GtkSourceGutterRendererPixbuf *renderer)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_PIXBUF (renderer), NULL);

	return gtk_source_pixbuf_helper_get_stock_id (renderer->priv->helper);
}

/**
 * gtk_source_gutter_renderer_pixbuf_set_gicon:
 * @renderer: a #GtkSourceGutterRendererPixbuf
 * @icon: (nullable): the icon, or %NULL.
 */
void
gtk_source_gutter_renderer_pixbuf_set_gicon (GtkSourceGutterRendererPixbuf *renderer,
                                             GIcon                         *icon)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_PIXBUF (renderer));
	g_return_if_fail (icon == NULL || G_IS_ICON (icon));

	set_gicon (renderer, icon);
}

/**
 * gtk_source_gutter_renderer_pixbuf_get_gicon:
 * @renderer: a #GtkSourceGutterRendererPixbuf
 *
 * Get the gicon of the renderer
 *
 * Returns: (transfer none): a #GIcon
 *
 **/
GIcon *
gtk_source_gutter_renderer_pixbuf_get_gicon (GtkSourceGutterRendererPixbuf *renderer)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_PIXBUF (renderer), NULL);

	return gtk_source_pixbuf_helper_get_gicon (renderer->priv->helper);
}

/**
 * gtk_source_gutter_renderer_pixbuf_set_icon_name:
 * @renderer: a #GtkSourceGutterRendererPixbuf
 * @icon_name: (nullable): the icon name, or %NULL.
 */
void
gtk_source_gutter_renderer_pixbuf_set_icon_name (GtkSourceGutterRendererPixbuf *renderer,
                                                 const gchar                   *icon_name)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_PIXBUF (renderer));

	set_icon_name (renderer, icon_name);
}

const gchar *
gtk_source_gutter_renderer_pixbuf_get_icon_name (GtkSourceGutterRendererPixbuf *renderer)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_PIXBUF (renderer), NULL);

	return gtk_source_pixbuf_helper_get_icon_name (renderer->priv->helper);
}
