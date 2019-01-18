/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcemap.c
 *
 * Copyright (C) 2015 Christian Hergert <christian@hergert.me>
 * Copyright (C) 2015 Ignacio Casal Quinteiro <icq@gnome.org>
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

#include "gtksourcemap.h"
#include <string.h>
#include "gtksourcebuffer.h"
#include "gtksourcecompletion.h"
#include "gtksourcestyle-private.h"
#include "gtksourcestylescheme.h"
#include "gtksourceview-utils.h"

/**
 * SECTION:map
 * @Short_description: Widget that displays a map for a specific #GtkSourceView
 * @Title: GtkSourceMap
 * @See_also: #GtkSourceView
 *
 * #GtkSourceMap is a widget that maps the content of a #GtkSourceView into
 * a smaller view so the user can have a quick overview of the whole document.
 *
 * This works by connecting a #GtkSourceView to to the #GtkSourceMap using
 * the #GtkSourceMap:view property or gtk_source_map_set_view().
 *
 * #GtkSourceMap is a #GtkSourceView object. This means that you can add a
 * #GtkSourceGutterRenderer to a gutter in the same way you would for a
 * #GtkSourceView. One example might be a #GtkSourceGutterRenderer that shows
 * which lines have changed in the document.
 *
 * Additionally, it is desirable to match the font of the #GtkSourceMap and
 * the #GtkSourceView used for editing. Therefore, #GtkSourceMap:font-desc
 * should be used to set the target font. You will need to adjust this to the
 * desired font size for the map. A 1pt font generally seems to be an
 * appropriate font size. "Monospace 1" is the default. See
 * pango_font_description_set_size() for how to alter the size of an existing
 * #PangoFontDescription.
 */

/*
 * Implementation Notes:
 *
 * I tried implementing this a few different ways. They are worth noting so
 * that we do not repeat the same mistakes.
 *
 * Originally, I thought using a GtkSourceView to do the rendering was overkill
 * and would likely slow things down too much. But it turns out to have been
 * the best option so far.
 *
 *   - GtkPixelCache support results in very few GtkTextLayout relayout and
 *     sizing changes. Since the pixel cache renders +/- half a screen outside
 *     the visible range, scrolling is also quite smooth as we very rarely
 *     perform a new gtk_text_layout_draw().
 *
 *   - Performance for this type of widget is dominated by text layout
 *     rendering. When you scale out this car, you increase the number of
 *     layouts to be rendered greatly.
 *
 *   - We can pack GtkSourceGutterRenderer into the child view to provide
 *     additional information. This is quite handy to show information such
 *     as errors, line changes, and anything else that can help the user
 *     quickly jump to the target location.
 *
 * I also tried drawing the contents of the GtkSourceView onto a widget after
 * performing a cairo_scale(). This does not help us much because we ignore
 * pixel cache when cair_scale is not 1-to-1. This results in layout
 * invalidation and worst case render paths.
 *
 * I also tried rendering the scrubber (overlay box) during the
 * GtkTextView::draw_layer() vfunc. The problem with this approach is that
 * the scrubber contents are actually pixel cached. So every time the scrubber
 * moves we have to invalidate the GtkTextLayout and redraw cached contents.
 * Where as drawing in the GtkTextView::draw() vfunc, after the pixel cache
 * contents have been drawn results in only a composite blend, not
 * invalidating any of the pixel cached text layouts.
 *
 * In the future, we might consider bundling a custom font for the source map.
 * Other overview maps have used a "block" font. However, they typically do
 * that because of the glyph rendering cost. Since we have pixel cache, that
 * deficiency is largely a non-issue. But Pango recently got support for
 * embedding fonts in the application, so it is at least possible to bundle
 * our own font as a resource.
 *
 * By default we use a 1pt Monospace font. However, if the Gtksourcemap:font-desc
 * property is set, we will use that instead.
 *
 * We do not render the background grid as it requires a bunch of
 * cpu time for something that will essentially just create a solid
 * color background.
 *
 * The width of the view is determined by the
 * #GtkSourceView:right-margin-position. We cache the width of a
 * single "X" character and multiple that by the right-margin-position.
 * That becomes our size-request width.
 *
 * We do not allow horizontal scrolling so that the overflow text
 * is simply not visible in the minimap.
 *
 * -- Christian
 */

#define DEFAULT_WIDTH 100

typedef struct
{
	/*
	 * By default, we use "Monospace 1pt". However, most text editing
	 * applications will have a custom font, so we allow them to set
	 * that here. Generally speaking, you will want to continue using
	 * a 1pt font, but if they set GtkSourceMap:font-desc, then they
	 * should also shrink the font to the desired size.
	 *
	 * For example:
	 *   pango_font_description_set_size(font_desc, 1 * PANGO_SCALE);
	 *
	 * Would set a 1pt font on whatever PangoFontDescription you have
	 * in your text editor.
	 */
	PangoFontDescription *font_desc;

	/*
	 * The easiest way to style the scrubber and the sourceview is
	 * by using CSS. This is necessary since we can't mess with the
	 * fonts used in the textbuffer (as one might using GtkTextTag).
	 */
	GtkCssProvider *css_provider;

	/* The GtkSourceView we are providing a map of */
	GtkSourceView *view;

	/* A weak pointer to the connected buffer */
	GtkTextBuffer *buffer;

	/* The location of the scrubber in widget coordinate space. */
	GdkRectangle scrubber_area;

	/* Weak pointer view to child view bindings */
	GBinding *buffer_binding;
	GBinding *indent_width_binding;
	GBinding *tab_width_binding;

	/* Our signal handler for buffer changes */
	gulong view_notify_buffer_handler;
	gulong view_vadj_value_changed_handler;
	gulong view_vadj_notify_upper_handler;

	/* Signals connected indirectly to the buffer */
	gulong buffer_notify_style_scheme_handler;

	/* Denotes if we are in a grab from button press */
	guint in_press : 1;
} GtkSourceMapPrivate;

enum
{
	PROP_0,
	PROP_VIEW,
	PROP_FONT_DESC,
	N_PROPERTIES
};

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceMap, gtk_source_map, GTK_SOURCE_TYPE_VIEW)

static GParamSpec *properties[N_PROPERTIES];

static void
update_scrubber_position (GtkSourceMap *map)
{
	GtkSourceMapPrivate *priv;
	GtkTextIter iter;
	GdkRectangle visible_area;
	GdkRectangle iter_area;
	GdkRectangle scrubber_area;
	GtkAllocation alloc;
	GtkAllocation view_alloc;
	gint child_height;
	gint view_height;
	gint y;

	priv = gtk_source_map_get_instance_private (map);

	if (priv->view == NULL)
	{
		return;
	}

	gtk_widget_get_allocation (GTK_WIDGET (priv->view), &view_alloc);
	gtk_widget_get_allocation (GTK_WIDGET (map), &alloc);

	gtk_widget_get_preferred_height (GTK_WIDGET (priv->view), NULL, &view_height);
	gtk_widget_get_preferred_height (GTK_WIDGET (map), NULL, &child_height);

	gtk_text_view_get_visible_rect (GTK_TEXT_VIEW (priv->view), &visible_area);
	gtk_text_view_get_iter_at_location (GTK_TEXT_VIEW (priv->view), &iter,
	                                    visible_area.x, visible_area.y);
	gtk_text_view_get_iter_location (GTK_TEXT_VIEW (map), &iter, &iter_area);
	gtk_text_view_buffer_to_window_coords (GTK_TEXT_VIEW (map),
	                                       GTK_TEXT_WINDOW_WIDGET,
	                                       iter_area.x, iter_area.y,
	                                       NULL, &y);

	scrubber_area.x = 0;
	scrubber_area.width = alloc.width;
	scrubber_area.y = y;
	scrubber_area.height = ((gdouble)view_alloc.height /
	                        (gdouble)view_height *
	                        (gdouble)child_height) +
	                       iter_area.height;

	if (memcmp (&scrubber_area, &priv->scrubber_area, sizeof scrubber_area) != 0)
	{
		GdkWindow *window;

		/*
		 * NOTE:
		 *
		 * Initially we had a gtk_widget_queue_draw() here thinking
		 * that we would hit the pixel cache and everything would be
		 * fine. However, it actually has a noticible improvement on
		 * interactivity to simply invalidate the old and new region
		 * in the widgets primary GdkWindow. Since the window is
		 * not the GTK_TEXT_WINDOW_TEXT, we don't seem to invalidate
		 * the pixel cache. This makes things as interactive as they
		 * were when drawing the scrubber from a parent widget.
		 */
		window = gtk_text_view_get_window (GTK_TEXT_VIEW (map), GTK_TEXT_WINDOW_WIDGET);
		if (window != NULL)
		{
			gdk_window_invalidate_rect (window, &priv->scrubber_area, FALSE);
			gdk_window_invalidate_rect (window, &scrubber_area, FALSE);
		}

		priv->scrubber_area = scrubber_area;
	}
}

static void
gtk_source_map_rebuild_css (GtkSourceMap *map)
{
	GtkSourceMapPrivate *priv;
	GtkSourceStyleScheme *style_scheme;
	GtkSourceStyle *style = NULL;
	GtkTextBuffer *buffer;
	GString *gstr;
	gboolean alter_alpha = TRUE;
	gchar *background = NULL;

	priv = gtk_source_map_get_instance_private (map);

	if (priv->view == NULL)
	{
		return;
	}

	/*
	 * This is where we calculate the CSS that maps the font for the
	 * minimap as well as the styling for the scrubber.
	 *
	 * The font is calculated from #GtkSourceMap:font-desc. We convert this
	 * to CSS using _gtk_source_pango_font_description_to_css(). It gets
	 * applied to the minimap widget via the CSS style provider which we
	 * attach to the view in gtk_source_map_init().
	 *
	 * The rules for calculating the style for the scrubber are as follows.
	 *
	 * If the current style scheme provides a background color for the
	 * scrubber using the "map-overlay" style name, we use that without
	 * any transformations.
	 *
	 * If the style scheme contains a "selection" style scheme, used for
	 * selected text, we use that with a 0.75 alpha value.
	 *
	 * If none of these are met, we take the background from the
	 * #GtkStyleContext using the deprecated
	 * gtk_style_context_get_background_color(). This is non-ideal, but
	 * currently required since we cannot indicate that we want to
	 * alter the alpha for gtk_render_background().
	 */

	gstr = g_string_new (NULL);

	/* Calculate the font if one has been set */
	if (priv->font_desc != NULL)
	{
		gchar *css;

		css = _gtk_source_pango_font_description_to_css (priv->font_desc);
		g_string_append_printf (gstr, "textview { %s }\n", css != NULL ? css : "");
		g_free (css);
	}

	buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (priv->view));
	style_scheme = gtk_source_buffer_get_style_scheme (GTK_SOURCE_BUFFER (buffer));

	if (style_scheme != NULL)
	{

		style = gtk_source_style_scheme_get_style (style_scheme, "map-overlay");

		if (style != NULL)
		{
			/* styling is taking as is only if we found a "map-overlay". */
			alter_alpha = FALSE;
		}
		else
		{
			style = gtk_source_style_scheme_get_style (style_scheme, "selection");
		}
	}

	if (style != NULL)
	{
		g_object_get (style,
		              "background", &background,
		              NULL);
	}

	if (background == NULL)
	{
		GtkStyleContext *context;
		GdkRGBA color;

		/*
		 * We failed to locate a style for both "map-overlay" and for
		 * "selection". That means we need to fallback to using the
		 * selected color for the gtk+ theme. This uses deprecated
		 * API because we have no way to tell gtk_render_background()
		 * to render with an alpha.
		 */

		context = gtk_widget_get_style_context (GTK_WIDGET (priv->view));
		gtk_style_context_save (context);
		gtk_style_context_add_class (context, "view");
		gtk_style_context_set_state (context, GTK_STATE_FLAG_SELECTED);
		G_GNUC_BEGIN_IGNORE_DEPRECATIONS;
		gtk_style_context_get_background_color (context,
							gtk_style_context_get_state (context),
							&color);
		G_GNUC_END_IGNORE_DEPRECATIONS;
		gtk_style_context_restore (context);
		background = gdk_rgba_to_string (&color);

		/*
		 * Make sure we alter the alpha. It is possible this could be
		 * FALSE here if we found a style for map-overlay but it did
		 * not contain a background color.
		 */
		alter_alpha = TRUE;
	}

	if (alter_alpha)
	{
		GdkRGBA color;

		gdk_rgba_parse (&color, background);
		color.alpha = 0.75;
		g_free (background);
		background = gdk_rgba_to_string (&color);
	}


	if (background != NULL)
	{
		g_string_append_printf (gstr,
		                        "textview.scrubber {\n"
		                        "\tbackground-color: %s;\n"
		                        "\tborder-top: 1px solid shade(%s,0.9);\n"
		                        "\tborder-bottom: 1px solid shade(%s,0.9);\n"
		                        "}\n",
		                        background,
		                        background,
		                        background);
	}

	g_free (background);

	if (gstr->len > 0)
	{
		gtk_css_provider_load_from_data (priv->css_provider, gstr->str, gstr->len, NULL);
	}

	g_string_free (gstr, TRUE);
}

static void
update_child_vadjustment (GtkSourceMap *map)
{
	GtkSourceMapPrivate *priv;
	GtkAdjustment *vadj;
	GtkAdjustment *child_vadj;
	gdouble value;
	gdouble upper;
	gdouble page_size;
	gdouble child_upper;
	gdouble child_page_size;
	gdouble new_value = 0.0;

	priv = gtk_source_map_get_instance_private (map);

	vadj = gtk_scrollable_get_vadjustment (GTK_SCROLLABLE (priv->view));
	g_object_get (vadj,
	              "upper", &upper,
	              "value", &value,
	              "page-size", &page_size,
	              NULL);

	child_vadj = gtk_scrollable_get_vadjustment (GTK_SCROLLABLE (map));
	g_object_get (child_vadj,
	              "upper", &child_upper,
	              "page-size", &child_page_size,
	              NULL);

	/*
	 * FIXME:
	 * Technically we should take into account lower here, but in practice
	 *       it is always 0.0.
	 */
	if (child_page_size < child_upper)
	{
		new_value = (value / (upper - page_size)) * (child_upper - child_page_size);
	}

	gtk_adjustment_set_value (child_vadj, new_value);
}

static void
view_vadj_value_changed (GtkSourceMap  *map,
                         GtkAdjustment *vadj)
{
	update_child_vadjustment (map);
	update_scrubber_position (map);
}

static void
view_vadj_notify_upper (GtkSourceMap  *map,
                        GParamSpec    *pspec,
                        GtkAdjustment *vadj)
{
	update_scrubber_position (map);
}

static void
buffer_notify_style_scheme (GtkSourceMap  *map,
                            GParamSpec    *pspec,
                            GtkTextBuffer *buffer)
{
	gtk_source_map_rebuild_css (map);
}

static void
connect_buffer (GtkSourceMap  *map,
                GtkTextBuffer *buffer)
{
	GtkSourceMapPrivate *priv;

	priv = gtk_source_map_get_instance_private (map);

	priv->buffer = buffer;
	g_object_add_weak_pointer (G_OBJECT (buffer), (gpointer *)&priv->buffer);

	priv->buffer_notify_style_scheme_handler =
		g_signal_connect_object (buffer,
		                         "notify::style-scheme",
		                         G_CALLBACK (buffer_notify_style_scheme),
		                         map,
		                         G_CONNECT_SWAPPED);

	buffer_notify_style_scheme (map, NULL, buffer);
}

static void
disconnect_buffer (GtkSourceMap  *map)
{
	GtkSourceMapPrivate *priv;

	priv = gtk_source_map_get_instance_private (map);

	if (priv->buffer == NULL)
	{
		return;
	}

	if (priv->buffer_notify_style_scheme_handler != 0)
	{
		g_signal_handler_disconnect (priv->buffer,
		                             priv->buffer_notify_style_scheme_handler);
		priv->buffer_notify_style_scheme_handler = 0;
	}

	g_object_remove_weak_pointer (G_OBJECT (priv->buffer), (gpointer *)&priv->buffer);
	priv->buffer = NULL;
}

static void
view_notify_buffer (GtkSourceMap  *map,
                    GParamSpec    *pspec,
                    GtkSourceView *view)
{
	GtkSourceMapPrivate *priv;
	GtkTextBuffer *buffer;

	priv = gtk_source_map_get_instance_private (map);

	if (priv->buffer != NULL)
	{
		disconnect_buffer (map);
	}

	buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (view));

	if (buffer != NULL)
	{
		connect_buffer (map, buffer);
	}
}

static void
gtk_source_map_set_font_desc (GtkSourceMap               *map,
                              const PangoFontDescription *font_desc)
{
	GtkSourceMapPrivate *priv;

	priv = gtk_source_map_get_instance_private (map);

	if (font_desc != priv->font_desc)
	{
		g_clear_pointer (&priv->font_desc, pango_font_description_free);

		if (font_desc)
		{
			priv->font_desc = pango_font_description_copy (font_desc);
		}
	}

	gtk_source_map_rebuild_css (map);
}

static void
gtk_source_map_set_font_name (GtkSourceMap *map,
                              const gchar  *font_name)
{
	PangoFontDescription *font_desc;

	if (font_name == NULL)
	{
		font_name = "Monospace 1";
	}

	font_desc = pango_font_description_from_string (font_name);
	gtk_source_map_set_font_desc (map, font_desc);
	pango_font_description_free (font_desc);
}

static void
gtk_source_map_get_preferred_width (GtkWidget *widget,
                                    gint      *mininum_width,
                                    gint      *natural_width)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (widget);
	GtkSourceMapPrivate *priv;
	PangoLayout *layout;
	gint height;
	gint width;

	priv = gtk_source_map_get_instance_private (map);

	if (priv->font_desc == NULL)
	{
		*mininum_width = *natural_width = DEFAULT_WIDTH;
		return;
	}

	/*
	 * FIXME:
	 *
	 * This seems like the type of thing we should calculate when
	 * rebuilding our CSS since it gets used a bunch and changes
	 * very little.
	 */
	layout = gtk_widget_create_pango_layout (GTK_WIDGET (map), "X");
	pango_layout_get_pixel_size (layout, &width, &height);
	g_object_unref (layout);

	width *= gtk_source_view_get_right_margin_position (priv->view);

	*mininum_width = *natural_width = width;
}

static void
gtk_source_map_get_preferred_height (GtkWidget *widget,
                                     gint      *minimum_height,
                                     gint      *natural_height)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (widget);
	GtkSourceMapPrivate *priv;

	priv = gtk_source_map_get_instance_private (map);

	if (priv->view == NULL)
	{
		*minimum_height = *natural_height = 0;
		return;
	}

	GTK_WIDGET_CLASS (gtk_source_map_parent_class)->get_preferred_height (widget,
	                                                                      minimum_height,
	                                                                      natural_height);

	*minimum_height = 0;
}


/*
 * This scrolls using buffer coordinates.
 * Translate your event location to a buffer coordinate before
 * calling this function.
 */
static void
scroll_to_child_point (GtkSourceMap   *map,
                       const GdkPoint *point)
{
	GtkSourceMapPrivate *priv;

	priv = gtk_source_map_get_instance_private (map);

	if (priv->view != NULL)
	{
		GtkAllocation alloc;
		GtkTextIter iter;

		gtk_widget_get_allocation (GTK_WIDGET (map), &alloc);

		gtk_text_view_get_iter_at_location (GTK_TEXT_VIEW (map),
		                                    &iter, point->x, point->y);

		gtk_text_view_scroll_to_iter (GTK_TEXT_VIEW (priv->view), &iter,
		                              0.0, TRUE, 1.0, 0.5);
	}
}

static void
gtk_source_map_size_allocate (GtkWidget     *widget,
                              GtkAllocation *alloc)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (widget);

	GTK_WIDGET_CLASS (gtk_source_map_parent_class)->size_allocate (widget, alloc);

	update_scrubber_position (map);
}

static void
connect_view (GtkSourceMap  *map,
              GtkSourceView *view)
{
	GtkSourceMapPrivate *priv;
	GtkAdjustment *vadj;

	priv = gtk_source_map_get_instance_private (map);

	priv->view = view;
	g_object_add_weak_pointer (G_OBJECT (view), (gpointer *)&priv->view);

	vadj = gtk_scrollable_get_vadjustment (GTK_SCROLLABLE (view));

	priv->buffer_binding =
		g_object_bind_property (view, "buffer",
		                        map, "buffer",
		                        G_BINDING_SYNC_CREATE);
	g_object_add_weak_pointer (G_OBJECT (priv->buffer_binding),
	                           (gpointer *)&priv->buffer_binding);

	priv->indent_width_binding =
		g_object_bind_property (view, "indent-width",
		                        map, "indent-width",
		                        G_BINDING_SYNC_CREATE);
	g_object_add_weak_pointer (G_OBJECT (priv->indent_width_binding),
	                           (gpointer *)&priv->indent_width_binding);

	priv->tab_width_binding =
		g_object_bind_property (view, "tab-width",
		                        map, "tab-width",
		                        G_BINDING_SYNC_CREATE);
	g_object_add_weak_pointer (G_OBJECT (priv->tab_width_binding),
	                           (gpointer *)&priv->tab_width_binding);

	priv->view_notify_buffer_handler =
		g_signal_connect_object (view,
		                         "notify::buffer",
		                         G_CALLBACK (view_notify_buffer),
		                         map,
		                         G_CONNECT_SWAPPED);
	view_notify_buffer (map, NULL, view);

	priv->view_vadj_value_changed_handler =
		g_signal_connect_object (vadj,
		                         "value-changed",
		                         G_CALLBACK (view_vadj_value_changed),
		                         map,
		                         G_CONNECT_SWAPPED);

	priv->view_vadj_notify_upper_handler =
		g_signal_connect_object (vadj,
		                         "notify::upper",
		                         G_CALLBACK (view_vadj_notify_upper),
		                         map,
		                         G_CONNECT_SWAPPED);

	if ((gtk_widget_get_events (GTK_WIDGET (priv->view)) & GDK_ENTER_NOTIFY_MASK) == 0)
	{
		gtk_widget_add_events (GTK_WIDGET (priv->view), GDK_ENTER_NOTIFY_MASK);
	}

	if ((gtk_widget_get_events (GTK_WIDGET (priv->view)) & GDK_LEAVE_NOTIFY_MASK) == 0)
	{
		gtk_widget_add_events (GTK_WIDGET (priv->view), GDK_LEAVE_NOTIFY_MASK);
	}

	/* If we are not visible, we want to block certain signal handlers */
	if (!gtk_widget_get_visible (GTK_WIDGET (map)))
	{
		g_signal_handler_block (vadj, priv->view_vadj_value_changed_handler);
		g_signal_handler_block (vadj, priv->view_vadj_notify_upper_handler);
	}

	gtk_source_map_rebuild_css (map);
}

static void
disconnect_view (GtkSourceMap *map)
{
	GtkSourceMapPrivate *priv;
	GtkAdjustment *vadj;

	priv = gtk_source_map_get_instance_private (map);

	if (priv->view == NULL)
	{
		return;
	}

	disconnect_buffer (map);

	if (priv->buffer_binding != NULL)
	{
		g_object_remove_weak_pointer (G_OBJECT (priv->buffer_binding),
		                              (gpointer *)&priv->buffer_binding);
		g_binding_unbind (priv->buffer_binding);
		priv->buffer_binding = NULL;
	}

	if (priv->indent_width_binding != NULL)
	{
		g_object_remove_weak_pointer (G_OBJECT (priv->indent_width_binding),
		                              (gpointer *)&priv->indent_width_binding);
		g_binding_unbind (priv->indent_width_binding);
		priv->indent_width_binding = NULL;
	}

	if (priv->tab_width_binding != NULL)
	{
		g_object_remove_weak_pointer (G_OBJECT (priv->tab_width_binding),
		                              (gpointer *)&priv->tab_width_binding);
		g_binding_unbind (priv->tab_width_binding);
		priv->tab_width_binding = NULL;
	}

	if (priv->view_notify_buffer_handler != 0)
	{
		g_signal_handler_disconnect (priv->view, priv->view_notify_buffer_handler);
		priv->view_notify_buffer_handler = 0;
	}

	vadj = gtk_scrollable_get_vadjustment (GTK_SCROLLABLE (priv->view));
	if (vadj != NULL)
	{
		g_signal_handler_disconnect (vadj, priv->view_vadj_value_changed_handler);
		priv->view_vadj_value_changed_handler = 0;

		g_signal_handler_disconnect (vadj, priv->view_vadj_notify_upper_handler);
		priv->view_vadj_notify_upper_handler = 0;
	}

	g_object_remove_weak_pointer (G_OBJECT (priv->view), (gpointer *)&priv->view);
	priv->view = NULL;
}

static void
gtk_source_map_destroy (GtkWidget *widget)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (widget);
	GtkSourceMapPrivate *priv;

	priv = gtk_source_map_get_instance_private (map);

	disconnect_buffer (map);
	disconnect_view (map);

	g_clear_object (&priv->css_provider);
	g_clear_pointer (&priv->font_desc, pango_font_description_free);

	GTK_WIDGET_CLASS (gtk_source_map_parent_class)->destroy (widget);
}

static gboolean
gtk_source_map_draw (GtkWidget *widget,
                     cairo_t   *cr)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (widget);
	GtkSourceMapPrivate *priv;
	GtkStyleContext *style_context;

	priv = gtk_source_map_get_instance_private (map);

	style_context = gtk_widget_get_style_context (widget);

	GTK_WIDGET_CLASS (gtk_source_map_parent_class)->draw (widget, cr);

	gtk_style_context_save (style_context);
	gtk_style_context_add_class (style_context, "scrubber");
	gtk_render_background (style_context, cr,
	                       priv->scrubber_area.x, priv->scrubber_area.y,
	                       priv->scrubber_area.width, priv->scrubber_area.height);
	gtk_style_context_restore (style_context);

	return FALSE;
}

static void
gtk_source_map_get_property (GObject    *object,
                             guint       prop_id,
                             GValue     *value,
                             GParamSpec *pspec)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (object);
	GtkSourceMapPrivate *priv;

	priv = gtk_source_map_get_instance_private (map);

	switch (prop_id)
	{
		case PROP_FONT_DESC:
			g_value_set_boxed (value, priv->font_desc);
			break;

		case PROP_VIEW:
			g_value_set_object (value, gtk_source_map_get_view (map));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
	}
}

static void
gtk_source_map_set_property (GObject      *object,
                             guint         prop_id,
                             const GValue *value,
                             GParamSpec   *pspec)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (object);

	switch (prop_id)
	{
		case PROP_VIEW:
			gtk_source_map_set_view (map, g_value_get_object (value));
			break;

		case PROP_FONT_DESC:
			gtk_source_map_set_font_desc (map, g_value_get_boxed (value));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
	}
}

static gboolean
gtk_source_map_button_press_event (GtkWidget      *widget,
                                   GdkEventButton *event)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (widget);
	GtkSourceMapPrivate *priv;
	GdkPoint point;

	priv = gtk_source_map_get_instance_private (map);

	point.x = event->x;
	point.y = event->y;

	gtk_text_view_window_to_buffer_coords (GTK_TEXT_VIEW (map),
	                                       GTK_TEXT_WINDOW_WIDGET,
	                                       event->x, event->y,
	                                       &point.x, &point.y);

	scroll_to_child_point (map, &point);

	gtk_grab_add (widget);

	priv->in_press = TRUE;

	return GDK_EVENT_STOP;
}

static gboolean
gtk_source_map_button_release_event (GtkWidget      *widget,
                                     GdkEventButton *event)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (widget);
	GtkSourceMapPrivate *priv;

	priv = gtk_source_map_get_instance_private (map);

	gtk_grab_remove (widget);

	priv->in_press = FALSE;

	return GDK_EVENT_STOP;
}


static gboolean
gtk_source_map_motion_notify_event (GtkWidget      *widget,
                                    GdkEventMotion *event)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (widget);
	GtkSourceMapPrivate *priv;

	priv = gtk_source_map_get_instance_private (map);

	if (priv->in_press && (priv->view != NULL))
	{
		GtkTextBuffer *buffer;
		GtkAllocation alloc;
		GdkRectangle area;
		GtkTextIter iter;
		GdkPoint point;
		gdouble yratio;
		gint height;

		gtk_widget_get_allocation (widget, &alloc);
		gtk_widget_get_preferred_height (widget, NULL, &height);
		if (height > 0)
		{
			height = MIN (height, alloc.height);
		}

		buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (map));
		gtk_text_buffer_get_end_iter (buffer, &iter);
		gtk_text_view_get_iter_location (GTK_TEXT_VIEW (map), &iter, &area);

		yratio = CLAMP (event->y - alloc.y, 0, height) / (gdouble)height;

		point.x = 0;
		point.y = (area.y + area.height) * yratio;

		scroll_to_child_point (map, &point);
	}

	return GDK_EVENT_STOP;
}

static gboolean
gtk_source_map_scroll_event (GtkWidget      *widget,
                             GdkEventScroll *event)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (widget);
	GtkSourceMapPrivate *priv;
	static const gint scroll_acceleration = 4;

	priv = gtk_source_map_get_instance_private (map);

	/*
	 * FIXME:
	 *
	 * This doesn't propagate kinetic scrolling or anything.
	 * We should probably make something that does that.
	 */
	if (priv->view != NULL)
	{
		gdouble x;
		gdouble y;
		gint count = 0;

		if (event->direction == GDK_SCROLL_UP)
		{
			count = -scroll_acceleration;
		}
		else if (event->direction == GDK_SCROLL_DOWN)
		{
			count = scroll_acceleration;
		}
		else
		{
			gdk_event_get_scroll_deltas ((GdkEvent *)event, &x, &y);

			if (y > 0)
			{
				count = scroll_acceleration;
			}
			else if (y < 0)
			{
				count = -scroll_acceleration;
			}
		}

		if (count != 0)
		{
			g_signal_emit_by_name (priv->view, "move-viewport",
			                       GTK_SCROLL_STEPS, count);
			return GDK_EVENT_STOP;
		}
	}

	return GDK_EVENT_PROPAGATE;
}

static void
set_view_cursor (GtkSourceMap *map)
{
	GdkWindow *window;

	window = gtk_text_view_get_window (GTK_TEXT_VIEW (map),
	                                   GTK_TEXT_WINDOW_TEXT);
	if (window != NULL)
	{
		gdk_window_set_cursor (window, NULL);
	}
}

static void
gtk_source_map_state_flags_changed (GtkWidget     *widget,
                                    GtkStateFlags  flags)
{
	GTK_WIDGET_CLASS (gtk_source_map_parent_class)->state_flags_changed (widget, flags);

	set_view_cursor (GTK_SOURCE_MAP (widget));
}

static void
gtk_source_map_realize (GtkWidget *widget)
{
	GTK_WIDGET_CLASS (gtk_source_map_parent_class)->realize (widget);

	set_view_cursor (GTK_SOURCE_MAP (widget));
}

static void
gtk_source_map_show (GtkWidget *widget)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (widget);
	GtkSourceMapPrivate *priv;
	GtkAdjustment *vadj;

	GTK_WIDGET_CLASS (gtk_source_map_parent_class)->show (widget);

	priv = gtk_source_map_get_instance_private (map);

	if (priv->view != NULL)
	{
		vadj = gtk_scrollable_get_vadjustment (GTK_SCROLLABLE (priv->view));

		g_signal_handler_unblock (vadj, priv->view_vadj_value_changed_handler);
		g_signal_handler_unblock (vadj, priv->view_vadj_notify_upper_handler);

		g_object_notify (G_OBJECT (vadj), "upper");
		g_signal_emit_by_name (vadj, "value-changed");
	}
}

static void
gtk_source_map_hide (GtkWidget *widget)
{
	GtkSourceMap *map = GTK_SOURCE_MAP (widget);
	GtkSourceMapPrivate *priv;
	GtkAdjustment *vadj;

	GTK_WIDGET_CLASS (gtk_source_map_parent_class)->hide (widget);

	priv = gtk_source_map_get_instance_private (map);

	if (priv->view != NULL)
	{
		vadj = gtk_scrollable_get_vadjustment (GTK_SCROLLABLE (priv->view));
		g_signal_handler_block (vadj, priv->view_vadj_value_changed_handler);
		g_signal_handler_block (vadj, priv->view_vadj_notify_upper_handler);
	}
}

static void
gtk_source_map_class_init (GtkSourceMapClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	GtkWidgetClass *widget_class = GTK_WIDGET_CLASS (klass);

	object_class->get_property = gtk_source_map_get_property;
	object_class->set_property = gtk_source_map_set_property;

	widget_class->destroy = gtk_source_map_destroy;
	widget_class->draw = gtk_source_map_draw;
	widget_class->get_preferred_height = gtk_source_map_get_preferred_height;
	widget_class->get_preferred_width = gtk_source_map_get_preferred_width;
	widget_class->hide = gtk_source_map_hide;
	widget_class->size_allocate = gtk_source_map_size_allocate;
	widget_class->button_press_event = gtk_source_map_button_press_event;
	widget_class->button_release_event = gtk_source_map_button_release_event;
	widget_class->motion_notify_event = gtk_source_map_motion_notify_event;
	widget_class->scroll_event = gtk_source_map_scroll_event;
	widget_class->show = gtk_source_map_show;
	widget_class->state_flags_changed = gtk_source_map_state_flags_changed;
	widget_class->realize = gtk_source_map_realize;

	properties[PROP_VIEW] =
		g_param_spec_object ("view",
		                     "View",
		                     "The view this widget is mapping.",
		                     GTK_SOURCE_TYPE_VIEW,
		                     (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

	properties[PROP_FONT_DESC] =
		g_param_spec_boxed ("font-desc",
		                    "Font Description",
		                    "The Pango font description to use.",
		                    PANGO_TYPE_FONT_DESCRIPTION,
		                    (G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

	g_object_class_install_properties (object_class, N_PROPERTIES, properties);
}

static void
gtk_source_map_init (GtkSourceMap *map)
{
	GtkSourceMapPrivate *priv;
	GtkSourceCompletion *completion;
	GtkStyleContext *context;

	priv = gtk_source_map_get_instance_private (map);

	priv->css_provider = gtk_css_provider_new ();

	context = gtk_widget_get_style_context (GTK_WIDGET (map));
	gtk_style_context_add_provider (context,
	                                GTK_STYLE_PROVIDER (priv->css_provider),
	                                GTK_SOURCE_STYLE_PROVIDER_PRIORITY + 1);

	g_object_set (map,
	              "auto-indent", FALSE,
	              "can-focus", FALSE,
	              "editable", FALSE,
	              "expand", FALSE,
	              "monospace", TRUE,
	              "show-line-numbers", FALSE,
	              "show-line-marks", FALSE,
	              "show-right-margin", FALSE,
	              "visible", TRUE,
	              NULL);

	gtk_widget_add_events (GTK_WIDGET (map), GDK_SCROLL_MASK);

	completion = gtk_source_view_get_completion (GTK_SOURCE_VIEW (map));
	gtk_source_completion_block_interactive (completion);

	gtk_source_map_set_font_name (map, "Monospace 1");
}

/**
 * gtk_source_map_new:
 *
 * Creates a new #GtkSourceMap.
 *
 * Returns: a new #GtkSourceMap.
 *
 * Since: 3.18
 */
GtkWidget *
gtk_source_map_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_MAP, NULL);
}

/**
 * gtk_source_map_set_view:
 * @map: a #GtkSourceMap
 * @view: a #GtkSourceView
 *
 * Sets the view that @map will be doing the mapping to.
 *
 * Since: 3.18
 */
void
gtk_source_map_set_view (GtkSourceMap  *map,
                         GtkSourceView *view)
{
	GtkSourceMapPrivate *priv;

	g_return_if_fail (GTK_SOURCE_IS_MAP (map));
	g_return_if_fail (view == NULL || GTK_SOURCE_IS_VIEW (view));

	priv = gtk_source_map_get_instance_private (map);

	if (priv->view == view)
	{
		return;
	}

	if (priv->view != NULL)
	{
		disconnect_view (map);
	}

	if (view != NULL)
	{
		connect_view (map, view);
	}

	g_object_notify_by_pspec (G_OBJECT (map), properties[PROP_VIEW]);
}

/**
 * gtk_source_map_get_view:
 * @map: a #GtkSourceMap.
 *
 * Gets the #GtkSourceMap:view property, which is the view this widget is mapping.
 *
 * Returns: (transfer none) (nullable): a #GtkSourceView or %NULL.
 *
 * Since: 3.18
 */
GtkSourceView *
gtk_source_map_get_view (GtkSourceMap *map)
{
	GtkSourceMapPrivate *priv;

	g_return_val_if_fail (GTK_SOURCE_IS_MAP (map), NULL);

	priv = gtk_source_map_get_instance_private (map);

	return priv->view;
}
