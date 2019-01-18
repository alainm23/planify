/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcegutterrenderertext.c
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

#include "gtksourcegutterrenderertext.h"
#include "gtksourceview-i18n.h"

/**
 * SECTION:gutterrenderertext
 * @Short_description: Renders text in the gutter
 * @Title: GtkSourceGutterRendererText
 * @See_also: #GtkSourceGutterRenderer, #GtkSourceGutter
 *
 * A #GtkSourceGutterRendererText can be used to render text in a cell of
 * #GtkSourceGutter.
 */

struct _GtkSourceGutterRendererTextPrivate
{
	gchar *text;

	PangoLayout *cached_layout;

	guint is_markup : 1;
};

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceGutterRendererText, gtk_source_gutter_renderer_text, GTK_SOURCE_TYPE_GUTTER_RENDERER)

enum
{
	PROP_0,
	PROP_MARKUP,
	PROP_TEXT
};

static void
gutter_renderer_text_begin (GtkSourceGutterRenderer *renderer,
			    cairo_t                 *cr,
			    GdkRectangle            *background_area,
			    GdkRectangle            *cell_area,
			    GtkTextIter             *start,
			    GtkTextIter             *end)
{
	GtkSourceGutterRendererText *text = GTK_SOURCE_GUTTER_RENDERER_TEXT (renderer);
	GtkTextView *view;

	view = gtk_source_gutter_renderer_get_view (renderer);

	g_clear_object (&text->priv->cached_layout);
	text->priv->cached_layout = gtk_widget_create_pango_layout (GTK_WIDGET (view), NULL);

	if (GTK_SOURCE_GUTTER_RENDERER_CLASS (gtk_source_gutter_renderer_text_parent_class)->begin != NULL)
	{
		GTK_SOURCE_GUTTER_RENDERER_CLASS (gtk_source_gutter_renderer_text_parent_class)->begin (renderer,
													cr,
													background_area,
													cell_area,
													start,
													end);
	}
}

static void
center_on (GtkTextView  *view,
           GdkRectangle *cell_area,
           GtkTextIter  *iter,
           gint          width,
           gint          height,
           gfloat        xalign,
           gfloat        yalign,
           gint         *x,
           gint         *y)
{
	GdkRectangle location;

	gtk_text_view_get_iter_location (view, iter, &location);

	*x = cell_area->x + (cell_area->width - width) * xalign;
	*y = cell_area->y + (location.height - height) * yalign;
}

static void
gutter_renderer_text_draw (GtkSourceGutterRenderer      *renderer,
			   cairo_t                      *cr,
			   GdkRectangle                 *background_area,
			   GdkRectangle                 *cell_area,
			   GtkTextIter                  *start,
			   GtkTextIter                  *end,
			   GtkSourceGutterRendererState  state)
{
	GtkSourceGutterRendererText *text = GTK_SOURCE_GUTTER_RENDERER_TEXT (renderer);
	GtkTextView *view;
	gint width;
	gint height;
	gfloat xalign;
	gfloat yalign;
	GtkSourceGutterRendererAlignmentMode mode;
	gint x = 0;
	gint y = 0;
	GtkStyleContext *context;

	/* Chain up to draw background */
	if (GTK_SOURCE_GUTTER_RENDERER_CLASS (gtk_source_gutter_renderer_text_parent_class)->draw != NULL)
	{
		GTK_SOURCE_GUTTER_RENDERER_CLASS (gtk_source_gutter_renderer_text_parent_class)->draw (renderer,
												       cr,
												       background_area,
												       cell_area,
												       start,
												       end,
												       state);
	}

	view = gtk_source_gutter_renderer_get_view (renderer);

	if (text->priv->is_markup)
	{
		pango_layout_set_markup (text->priv->cached_layout,
		                         text->priv->text,
		                         -1);
	}
	else
	{
		pango_layout_set_text (text->priv->cached_layout,
		                       text->priv->text,
		                       -1);
	}

	pango_layout_get_pixel_size (text->priv->cached_layout, &width, &height);

	gtk_source_gutter_renderer_get_alignment (renderer,
	                                          &xalign,
	                                          &yalign);

	/* Avoid calculations if we don't wrap text */
	if (gtk_text_view_get_wrap_mode (view) == GTK_WRAP_NONE)
	{
		mode = GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_CELL;
	}
	else
	{
		mode = gtk_source_gutter_renderer_get_alignment_mode (renderer);
	}

	switch (mode)
	{
		case GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_CELL:
			x = cell_area->x + (cell_area->width - width) * xalign;
			y = cell_area->y + (cell_area->height - height) * yalign;
			break;

		case GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_FIRST:
			center_on (view,
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
			center_on (view,
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

	context = gtk_widget_get_style_context (GTK_WIDGET (view));
	gtk_render_layout (context, cr, x, y, text->priv->cached_layout);
}

static void
gutter_renderer_text_end (GtkSourceGutterRenderer *renderer)
{
	GtkSourceGutterRendererText *text = GTK_SOURCE_GUTTER_RENDERER_TEXT (renderer);

	g_clear_object (&text->priv->cached_layout);

	if (GTK_SOURCE_GUTTER_RENDERER_CLASS (gtk_source_gutter_renderer_text_parent_class)->end != NULL)
	{
		GTK_SOURCE_GUTTER_RENDERER_CLASS (gtk_source_gutter_renderer_text_parent_class)->end (renderer);
	}
}

static void
measure_text (GtkSourceGutterRendererText *renderer,
              const gchar                 *markup,
              const gchar                 *text,
              gint                        *width,
              gint                        *height)
{
	GtkTextView *view;
	PangoLayout *layout;

	view = gtk_source_gutter_renderer_get_view (GTK_SOURCE_GUTTER_RENDERER (renderer));

	layout = gtk_widget_create_pango_layout (GTK_WIDGET (view), NULL);

	if (markup != NULL)
	{
		pango_layout_set_markup (layout, markup, -1);
	}
	else
	{
		pango_layout_set_text (layout, text, -1);
	}

	pango_layout_get_pixel_size (layout, width, height);

	g_object_unref (layout);
}

/**
 * gtk_source_gutter_renderer_text_measure:
 * @renderer: a #GtkSourceGutterRendererText.
 * @text: the text to measure.
 * @width: (out) (optional): location to store the width of the text in pixels,
 *   or %NULL.
 * @height: (out) (optional): location to store the height of the text in
 *   pixels, or %NULL.
 *
 * Measures the text provided using the pango layout used by the
 * #GtkSourceGutterRendererText.
 */
void
gtk_source_gutter_renderer_text_measure (GtkSourceGutterRendererText *renderer,
                                         const gchar                 *text,
                                         gint                        *width,
                                         gint                        *height)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_TEXT (renderer));
	g_return_if_fail (text != NULL);

	measure_text (renderer, NULL, text, width, height);
}

/**
 * gtk_source_gutter_renderer_text_measure_markup:
 * @renderer: a #GtkSourceGutterRendererText.
 * @markup: the pango markup to measure.
 * @width: (out) (optional): location to store the width of the text in pixels,
 *   or %NULL.
 * @height: (out) (optional): location to store the height of the text in
 *   pixels, or %NULL.
 *
 * Measures the pango markup provided using the pango layout used by the
 * #GtkSourceGutterRendererText.
 */
void
gtk_source_gutter_renderer_text_measure_markup (GtkSourceGutterRendererText *renderer,
                                                const gchar                 *markup,
                                                gint                        *width,
                                                gint                        *height)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_TEXT (renderer));
	g_return_if_fail (markup != NULL);

	measure_text (renderer, markup, NULL, width, height);
}

static void
gtk_source_gutter_renderer_text_finalize (GObject *object)
{
	GtkSourceGutterRendererText *renderer = GTK_SOURCE_GUTTER_RENDERER_TEXT (object);

	g_free (renderer->priv->text);
	g_clear_object (&renderer->priv->cached_layout);

	G_OBJECT_CLASS (gtk_source_gutter_renderer_text_parent_class)->finalize (object);
}

static void
set_text (GtkSourceGutterRendererText *renderer,
          const gchar                 *text,
          gint                         length,
          gboolean                     is_markup)
{
	g_free (renderer->priv->text);

	renderer->priv->text = length >= 0 ? g_strndup (text, length) : g_strdup (text);
	renderer->priv->is_markup = is_markup;
}

static void
gtk_source_gutter_renderer_text_set_property (GObject      *object,
                                              guint         prop_id,
                                              const GValue *value,
                                              GParamSpec   *pspec)
{
	GtkSourceGutterRendererText *renderer;

	renderer = GTK_SOURCE_GUTTER_RENDERER_TEXT (object);

	switch (prop_id)
	{
		case PROP_MARKUP:
			set_text (renderer, g_value_get_string (value), -1, TRUE);
			break;
		case PROP_TEXT:
			set_text (renderer, g_value_get_string (value), -1, FALSE);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_gutter_renderer_text_get_property (GObject    *object,
                                              guint       prop_id,
                                              GValue     *value,
                                              GParamSpec *pspec)
{
	GtkSourceGutterRendererText *renderer;

	renderer = GTK_SOURCE_GUTTER_RENDERER_TEXT (object);

	switch (prop_id)
	{
		case PROP_MARKUP:
			g_value_set_string (value, renderer->priv->is_markup ? renderer->priv->text : NULL);
			break;
		case PROP_TEXT:
			g_value_set_string (value, !renderer->priv->is_markup ? renderer->priv->text : NULL);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_gutter_renderer_text_class_init (GtkSourceGutterRendererTextClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	GtkSourceGutterRendererClass *renderer_class = GTK_SOURCE_GUTTER_RENDERER_CLASS (klass);

	object_class->finalize = gtk_source_gutter_renderer_text_finalize;

	object_class->get_property = gtk_source_gutter_renderer_text_get_property;
	object_class->set_property = gtk_source_gutter_renderer_text_set_property;

	renderer_class->begin = gutter_renderer_text_begin;
	renderer_class->draw = gutter_renderer_text_draw;
	renderer_class->end = gutter_renderer_text_end;

	g_object_class_install_property (object_class,
	                                 PROP_MARKUP,
	                                 g_param_spec_string ("markup",
	                                                      "Markup",
	                                                      "The markup",
	                                                      NULL,
	                                                      G_PARAM_READWRITE | G_PARAM_CONSTRUCT));

	g_object_class_install_property (object_class,
	                                 PROP_TEXT,
	                                 g_param_spec_string ("text",
	                                                      "Text",
	                                                      "The text",
	                                                      NULL,
	                                                      G_PARAM_READWRITE | G_PARAM_CONSTRUCT));
}

static void
gtk_source_gutter_renderer_text_init (GtkSourceGutterRendererText *self)
{
	self->priv = gtk_source_gutter_renderer_text_get_instance_private (self);

	self->priv->is_markup = TRUE;
}

/**
 * gtk_source_gutter_renderer_text_new:
 *
 * Create a new #GtkSourceGutterRendererText.
 *
 * Returns: (transfer full): A #GtkSourceGutterRenderer
 *
 **/
GtkSourceGutterRenderer *
gtk_source_gutter_renderer_text_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_GUTTER_RENDERER_TEXT, NULL);
}

void
gtk_source_gutter_renderer_text_set_markup (GtkSourceGutterRendererText *renderer,
                                            const gchar                 *markup,
                                            gint                         length)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_TEXT (renderer));

	set_text (renderer, markup, length, TRUE);
}

void
gtk_source_gutter_renderer_text_set_text (GtkSourceGutterRendererText *renderer,
                                          const gchar                 *text,
                                          gint                         length)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER_TEXT (renderer));

	set_text (renderer, text, length, FALSE);
}
