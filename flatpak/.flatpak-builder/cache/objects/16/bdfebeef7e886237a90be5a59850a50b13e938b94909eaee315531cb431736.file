/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcegutterrenderer.c
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

#include "gtksourcegutterrenderer.h"
#include "gtksourcegutterrenderer-private.h"
#include "gtksourcestylescheme.h"
#include "gtksourceview-enumtypes.h"
#include "gtksourceview-i18n.h"

/**
 * SECTION:gutterrenderer
 * @Short_description: Gutter cell renderer
 * @Title: GtkSourceGutterRenderer
 * @See_also: #GtkSourceGutter
 *
 * A #GtkSourceGutterRenderer represents a column in a #GtkSourceGutter. The
 * column contains one cell for each visible line of the #GtkTextBuffer. Due to
 * text wrapping, a cell can thus span multiple lines of the #GtkTextView. In
 * this case, #GtkSourceGutterRendererAlignmentMode controls the alignment of
 * the cell.
 *
 * The gutter renderer must announce its #GtkSourceGutterRenderer:size. The
 * height is determined by the text view height. The width must be determined by
 * the gutter renderer. The width generally takes into account the entire text
 * buffer. For instance, to display the line numbers, if the buffer contains 100
 * lines, the gutter renderer will always set its width such as three digits can
 * be printed, even if only the first 20 lines are shown. Another strategy is to
 * take into account only the visible lines.  In this case, only two digits are
 * necessary to display the line numbers of the first 20 lines. To take another
 * example, the gutter renderer for #GtkSourceMark<!-- -->s doesn't need to take
 * into account the text buffer to announce its width. It only depends on the
 * icons size displayed in the gutter column.
 *
 * An horizontal and vertical padding can be added with
 * gtk_source_gutter_renderer_set_padding().  The total width of a gutter
 * renderer is its size (#GtkSourceGutterRenderer:size) plus two times the
 * horizontal padding (#GtkSourceGutterRenderer:xpad).
 *
 * When the available size to render a cell is greater than the required size to
 * render the cell contents, the cell contents can be aligned horizontally and
 * vertically with gtk_source_gutter_renderer_set_alignment().
 *
 * The cells rendering occurs in three phases:
 * - begin: the gtk_source_gutter_renderer_begin() function is called when some
 *   cells need to be redrawn. It provides the associated region of the
 *   #GtkTextBuffer. The cells need to be redrawn when the #GtkTextView is
 *   scrolled, or when the state of the cells change (see
 *   #GtkSourceGutterRendererState).
 * - draw: gtk_source_gutter_renderer_draw() is called for each cell that needs
 *   to be drawn.
 * - end: finally, gtk_source_gutter_renderer_end() is called.
 */

enum
{
	ACTIVATE,
	QUEUE_DRAW,
	QUERY_TOOLTIP,
	QUERY_DATA,
	QUERY_ACTIVATABLE,
	N_SIGNALS
};

struct _GtkSourceGutterRendererPrivate
{
	GtkTextView *view;
	GtkTextBuffer *buffer;
	GtkTextWindowType window_type;

	gint xpad;
	gint ypad;

	gfloat xalign;
	gfloat yalign;

	gint size;

	GtkSourceGutterRendererAlignmentMode alignment_mode;

	GdkRGBA background_color;

	guint background_set : 1;
	guint visible : 1;
};

static guint signals[N_SIGNALS];

G_DEFINE_ABSTRACT_TYPE_WITH_PRIVATE (GtkSourceGutterRenderer, gtk_source_gutter_renderer, G_TYPE_INITIALLY_UNOWNED)

enum
{
	PROP_0,
	PROP_VISIBLE,
	PROP_XPAD,
	PROP_YPAD,
	PROP_XALIGN,
	PROP_YALIGN,
	PROP_VIEW,
	PROP_ALIGNMENT_MODE,
	PROP_WINDOW_TYPE,
	PROP_SIZE,
	PROP_BACKGROUND_RGBA,
	PROP_BACKGROUND_SET
};

static void
set_buffer (GtkSourceGutterRenderer *renderer,
            GtkTextBuffer           *buffer)
{
	if (renderer->priv->buffer != NULL)
	{
		g_object_remove_weak_pointer (G_OBJECT (renderer->priv->buffer),
		                              (gpointer) &renderer->priv->buffer);
	}

	if (buffer != NULL)
	{
		g_object_add_weak_pointer (G_OBJECT (buffer),
		                           (gpointer) &renderer->priv->buffer);
	}

	renderer->priv->buffer = buffer;
}

static void
emit_buffer_changed (GtkTextView             *view,
                     GtkSourceGutterRenderer *renderer)
{
	GtkTextBuffer* buffer;

	buffer = gtk_text_view_get_buffer (view);

	if (buffer != renderer->priv->buffer)
	{
		if (GTK_SOURCE_GUTTER_RENDERER_GET_CLASS (renderer)->change_buffer)
		{
			GTK_SOURCE_GUTTER_RENDERER_GET_CLASS (renderer)->change_buffer (renderer,
			                                                                renderer->priv->buffer);
		}

		set_buffer (renderer, buffer);
	}
}

static void
on_buffer_changed (GtkTextView             *view,
                   GParamSpec              *spec,
                   GtkSourceGutterRenderer *renderer)
{
	emit_buffer_changed (view, renderer);
}

static void
renderer_change_view_impl (GtkSourceGutterRenderer *renderer,
                           GtkTextView             *old_view)
{
	if (old_view)
	{
		g_signal_handlers_disconnect_by_func (old_view,
		                                      G_CALLBACK (on_buffer_changed),
		                                      renderer);
	}

	if (renderer->priv->view)
	{
		emit_buffer_changed (renderer->priv->view, renderer);

		g_signal_connect (renderer->priv->view,
		                  "notify::buffer",
		                  G_CALLBACK (on_buffer_changed),
		                  renderer);
	}
}

static void
gtk_source_gutter_renderer_dispose (GObject *object)
{
	GtkSourceGutterRenderer *renderer;

	renderer = GTK_SOURCE_GUTTER_RENDERER (object);

	set_buffer (renderer, NULL);

	if (renderer->priv->view)
	{
		_gtk_source_gutter_renderer_set_view (renderer,
		                                      NULL,
		                                      GTK_TEXT_WINDOW_PRIVATE);
	}

	G_OBJECT_CLASS (gtk_source_gutter_renderer_parent_class)->dispose (object);
}

static void
set_visible (GtkSourceGutterRenderer *renderer,
             gboolean                 visible)
{
	visible = visible != FALSE;

	if (renderer->priv->visible != visible)
	{
		renderer->priv->visible = visible;
		g_object_notify (G_OBJECT (renderer), "visible");

		gtk_source_gutter_renderer_queue_draw (renderer);
	}
}

static gboolean
set_padding (GtkSourceGutterRenderer *renderer,
             gint                    *field,
             gint                     padding,
             const gchar             *name)
{
	if (*field == padding || padding < 0)
	{
		return FALSE;
	}

	*field = padding;
	g_object_notify (G_OBJECT (renderer), name);

	return TRUE;
}

static gboolean
set_xpad (GtkSourceGutterRenderer *renderer,
          gint                     xpad)
{
	return set_padding (renderer,
	                    &renderer->priv->xpad,
	                    xpad,
	                    "xpad");
}

static gboolean
set_ypad (GtkSourceGutterRenderer *renderer,
          gint                     ypad)
{
	return set_padding (renderer,
	                    &renderer->priv->ypad,
	                    ypad,
	                    "ypad");
}

static gboolean
set_alignment (GtkSourceGutterRenderer *renderer,
               gfloat                  *field,
               gfloat                   align,
               const gchar             *name,
               gboolean                 emit)
{
	if (*field == align || align < 0)
	{
		return FALSE;
	}

	*field = align;
	g_object_notify (G_OBJECT (renderer), name);

	if (emit)
	{
		gtk_source_gutter_renderer_queue_draw (renderer);
	}

	return TRUE;
}

static gboolean
set_xalign (GtkSourceGutterRenderer *renderer,
            gfloat                   xalign,
            gboolean                 emit)
{
	return set_alignment (renderer,
	                      &renderer->priv->xalign,
	                      xalign,
	                      "xalign",
	                      emit);
}

static gboolean
set_yalign (GtkSourceGutterRenderer *renderer,
            gfloat                   yalign,
            gboolean                 emit)
{
	return set_alignment (renderer,
	                      &renderer->priv->yalign,
	                      yalign,
	                      "yalign",
	                      emit);
}

static void
set_alignment_mode (GtkSourceGutterRenderer              *renderer,
                    GtkSourceGutterRendererAlignmentMode  mode)
{
	if (renderer->priv->alignment_mode == mode)
	{
		return;
	}

	renderer->priv->alignment_mode = mode;
	g_object_notify (G_OBJECT (renderer), "alignment-mode");

	gtk_source_gutter_renderer_queue_draw (renderer);
}

static void
set_size (GtkSourceGutterRenderer *renderer,
          gint                     value)
{
	if (renderer->priv->size == value)
	{
		return;
	}

	renderer->priv->size = value;
	g_object_notify (G_OBJECT (renderer), "size");
}

static void
set_background_color_set (GtkSourceGutterRenderer *renderer,
                          gboolean                 isset)
{
	isset = (isset != FALSE);

	if (isset != renderer->priv->background_set)
	{
		renderer->priv->background_set = isset;
		gtk_source_gutter_renderer_queue_draw (renderer);
	}
}

static void
set_background_color (GtkSourceGutterRenderer *renderer,
                      const GdkRGBA          *color)
{
	if (!color)
	{
		set_background_color_set (renderer, FALSE);
	}
	else
	{
		renderer->priv->background_color = *color;
		renderer->priv->background_set = TRUE;

		gtk_source_gutter_renderer_queue_draw (renderer);
	}
}

static void
gtk_source_gutter_renderer_set_property (GObject      *object,
                                         guint         prop_id,
                                         const GValue *value,
                                         GParamSpec   *pspec)
{
	GtkSourceGutterRenderer *self = GTK_SOURCE_GUTTER_RENDERER (object);

	switch (prop_id)
	{
		case PROP_VISIBLE:
			set_visible (self, g_value_get_boolean (value));
			break;
		case PROP_XPAD:
			set_xpad (self, g_value_get_int (value));
			break;
		case PROP_YPAD:
			set_ypad (self, g_value_get_int (value));
			break;
		case PROP_XALIGN:
			set_xalign (self, g_value_get_float (value), TRUE);
			break;
		case PROP_YALIGN:
			set_yalign (self, g_value_get_float (value), TRUE);
			break;
		case PROP_ALIGNMENT_MODE:
			set_alignment_mode (self, g_value_get_enum (value));
			break;
		case PROP_VIEW:
			self->priv->view = g_value_get_object (value);
			break;
		case PROP_WINDOW_TYPE:
			self->priv->window_type = g_value_get_enum (value);
			break;
		case PROP_SIZE:
			set_size (self, g_value_get_int (value));
			break;
		case PROP_BACKGROUND_RGBA:
			set_background_color (self,
			                      g_value_get_boxed (value));
			break;
		case PROP_BACKGROUND_SET:
			set_background_color_set (self,
			                          g_value_get_boolean (value));
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_gutter_renderer_get_property (GObject    *object,
                                         guint       prop_id,
                                         GValue     *value,
                                         GParamSpec *pspec)
{
	GtkSourceGutterRenderer *self = GTK_SOURCE_GUTTER_RENDERER (object);

	switch (prop_id)
	{
		case PROP_VISIBLE:
			g_value_set_boolean (value, self->priv->visible);
			break;
		case PROP_XPAD:
			g_value_set_int (value, self->priv->xpad);
			break;
		case PROP_YPAD:
			g_value_set_int (value, self->priv->ypad);
			break;
		case PROP_XALIGN:
			g_value_set_float (value, self->priv->xalign);
			break;
		case PROP_YALIGN:
			g_value_set_float (value, self->priv->yalign);
			break;
		case PROP_VIEW:
			g_value_set_object (value, self->priv->view);
			break;
		case PROP_ALIGNMENT_MODE:
			g_value_set_enum (value, self->priv->alignment_mode);
			break;
		case PROP_WINDOW_TYPE:
			g_value_set_enum (value, self->priv->window_type);
			break;
		case PROP_SIZE:
			g_value_set_int (value, self->priv->size);
			break;
		case PROP_BACKGROUND_RGBA:
			g_value_set_boxed (value, &self->priv->background_color);
			break;
		case PROP_BACKGROUND_SET:
			g_value_set_boolean (value, self->priv->background_set);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
renderer_draw_impl (GtkSourceGutterRenderer      *renderer,
                    cairo_t                      *cr,
                    GdkRectangle                 *background_area,
                    GdkRectangle                 *cell_area,
                    GtkTextIter                  *start,
                    GtkTextIter                  *end,
                    GtkSourceGutterRendererState  state)
{
	if (renderer->priv->background_set)
	{
		cairo_save (cr);
		gdk_cairo_rectangle (cr, background_area);
		gdk_cairo_set_source_rgba (cr, &renderer->priv->background_color);
		cairo_fill (cr);
		cairo_restore (cr);
	}
	else if ((state & GTK_SOURCE_GUTTER_RENDERER_STATE_CURSOR) != 0 &&
		 GTK_SOURCE_IS_VIEW (renderer->priv->view) &&
		 gtk_source_view_get_highlight_current_line (GTK_SOURCE_VIEW (renderer->priv->view)))
	{
		GtkStyleContext *context;

		context = gtk_widget_get_style_context (GTK_WIDGET (renderer->priv->view));

		gtk_style_context_save (context);
		gtk_style_context_add_class (context, "current-line-number");

		gtk_render_background (context,
				       cr,
				       background_area->x,
				       background_area->y,
				       background_area->width,
				       background_area->height);

		gtk_style_context_restore (context);
	}
}

static void
gtk_source_gutter_renderer_class_init (GtkSourceGutterRendererClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->dispose = gtk_source_gutter_renderer_dispose;

	object_class->get_property = gtk_source_gutter_renderer_get_property;
	object_class->set_property = gtk_source_gutter_renderer_set_property;

	klass->draw = renderer_draw_impl;
	klass->change_view = renderer_change_view_impl;

	/**
	 * GtkSourceGutterRenderer:visible:
	 *
	 * The visibility of the renderer.
	 *
	 **/
	g_object_class_install_property (object_class,
	                                 PROP_VISIBLE,
	                                 g_param_spec_boolean ("visible",
	                                                       "Visible",
	                                                       "Visible",
	                                                       TRUE,
	                                                       G_PARAM_READWRITE | G_PARAM_CONSTRUCT));

	/**
	 * GtkSourceGutterRenderer:xpad:
	 *
	 * The left and right padding of the renderer.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_XPAD,
	                                 g_param_spec_int ("xpad",
	                                                   "X Padding",
	                                                   "The x-padding",
	                                                   -1,
	                                                   G_MAXINT,
	                                                   0,
	                                                   G_PARAM_READWRITE | G_PARAM_CONSTRUCT));

	/**
	 * GtkSourceGutterRenderer:ypad:
	 *
	 * The top and bottom padding of the renderer.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_YPAD,
	                                 g_param_spec_int ("ypad",
	                                                   "Y Padding",
	                                                   "The y-padding",
	                                                   -1,
	                                                   G_MAXINT,
	                                                   0,
	                                                   G_PARAM_READWRITE | G_PARAM_CONSTRUCT));

	/**
	 * GtkSourceGutterRenderer:xalign:
	 *
	 * The horizontal alignment of the renderer. Set to 0 for a left
	 * alignment. 1 for a right alignment. And 0.5 for centering the cells.
	 * A value lower than 0 doesn't modify the alignment.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_XALIGN,
	                                 g_param_spec_float ("xalign",
	                                                     "X Alignment",
	                                                     "The x-alignment",
	                                                     -1,
	                                                     1,
	                                                     0,
	                                                     G_PARAM_READWRITE | G_PARAM_CONSTRUCT));

	/**
	 * GtkSourceGutterRenderer:yalign:
	 *
	 * The vertical alignment of the renderer. Set to 0 for a top
	 * alignment. 1 for a bottom alignment. And 0.5 for centering the cells.
	 * A value lower than 0 doesn't modify the alignment.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_YALIGN,
	                                 g_param_spec_float ("yalign",
	                                                     "Y Alignment",
	                                                     "The y-alignment",
	                                                     -1,
	                                                     1,
	                                                     0,
	                                                     G_PARAM_READWRITE | G_PARAM_CONSTRUCT));

	/**
	 * GtkSourceGutterRenderer::activate:
	 * @renderer: the #GtkSourceGutterRenderer who emits the signal
	 * @iter: a #GtkTextIter
	 * @area: a #GdkRectangle
	 * @event: the event that caused the activation
	 *
	 * The ::activate signal is emitted when the renderer is
	 * activated.
	 *
	 */
	signals[ACTIVATE] =
		g_signal_new ("activate",
		              G_TYPE_FROM_CLASS (object_class),
		              G_SIGNAL_RUN_LAST,
		              G_STRUCT_OFFSET (GtkSourceGutterRendererClass, activate),
		              NULL, NULL, NULL,
		              G_TYPE_NONE,
		              3,
		              GTK_TYPE_TEXT_ITER,
		              GDK_TYPE_RECTANGLE,
		              GDK_TYPE_EVENT);

	/**
	 * GtkSourceGutterRenderer::queue-draw:
	 * @renderer: the #GtkSourceGutterRenderer who emits the signal
	 *
	 * The ::queue-draw signal is emitted when the renderer needs
	 * to be redrawn. Use gtk_source_gutter_renderer_queue_draw()
	 * to emit this signal from an implementation of the
	 * #GtkSourceGutterRenderer interface.
	 */
	signals[QUEUE_DRAW] =
		g_signal_new ("queue-draw",
		              G_TYPE_FROM_CLASS (object_class),
		              G_SIGNAL_RUN_LAST,
		              G_STRUCT_OFFSET (GtkSourceGutterRendererClass, queue_draw),
		              NULL, NULL, NULL,
		              G_TYPE_NONE, 0);

	/**
	 * GtkSourceGutterRenderer::query-tooltip:
	 * @renderer: the #GtkSourceGutterRenderer who emits the signal
	 * @iter: a #GtkTextIter
	 * @area: a #GdkRectangle
	 * @x: the x position (in window coordinates)
	 * @y: the y position (in window coordinates)
	 * @tooltip: a #GtkTooltip
	 *
	 * The ::query-tooltip signal is emitted when the renderer can
	 * show a tooltip.
	 *
	 */
	signals[QUERY_TOOLTIP] =
		g_signal_new ("query-tooltip",
		              G_TYPE_FROM_CLASS (object_class),
		              G_SIGNAL_RUN_LAST,
		              G_STRUCT_OFFSET (GtkSourceGutterRendererClass, query_tooltip),
		              g_signal_accumulator_true_handled,
		              NULL,
		              NULL,
		              G_TYPE_BOOLEAN,
		              5,
		              GTK_TYPE_TEXT_ITER,
		              GDK_TYPE_RECTANGLE,
		              G_TYPE_INT,
		              G_TYPE_INT,
		              GTK_TYPE_TOOLTIP);

	/**
	 * GtkSourceGutterRenderer::query-data:
	 * @renderer: the #GtkSourceGutterRenderer who emits the signal
	 * @start: a #GtkTextIter
	 * @end: a #GtkTextIter
	 * @state: the renderer state
	 *
	 * The ::query-data signal is emitted when the renderer needs
	 * to be filled with data just before a cell is drawn. This can
	 * be used by general renderer implementations to allow render
	 * data to be filled in externally.
	 *
	 */
	signals[QUERY_DATA] =
		g_signal_new ("query-data",
		              G_TYPE_FROM_CLASS (object_class),
		              G_SIGNAL_RUN_LAST,
		              G_STRUCT_OFFSET (GtkSourceGutterRendererClass, query_data),
		              NULL, NULL, NULL,
		              G_TYPE_NONE,
		              3,
		              GTK_TYPE_TEXT_ITER,
		              GTK_TYPE_TEXT_ITER,
		              GTK_SOURCE_TYPE_GUTTER_RENDERER_STATE);

	/**
	 * GtkSourceGutterRenderer::query-activatable:
	 * @renderer: the #GtkSourceGutterRenderer who emits the signal
	 * @iter: a #GtkTextIter
	 * @area: a #GdkRectangle
	 * @event: the #GdkEvent that is causing the activatable query
	 *
	 * The ::query-activatable signal is emitted when the renderer
	 * can possibly be activated.
	 *
	 */
	signals[QUERY_ACTIVATABLE] =
		g_signal_new ("query-activatable",
		              G_TYPE_FROM_CLASS (object_class),
		              G_SIGNAL_RUN_LAST,
		              G_STRUCT_OFFSET (GtkSourceGutterRendererClass, query_activatable),
		              g_signal_accumulator_true_handled,
		              NULL,
		              NULL,
		              G_TYPE_BOOLEAN,
		              3,
		              GTK_TYPE_TEXT_ITER,
		              GDK_TYPE_RECTANGLE,
		              GDK_TYPE_EVENT);

	/**
	 * GtkSourceGutterRenderer:view:
	 *
	 * The view on which the renderer is placed.
	 *
	 **/
	g_object_class_install_property (object_class,
	                                 PROP_VIEW,
	                                 g_param_spec_object ("view",
	                                                      "The View",
	                                                      "The view",
	                                                      GTK_TYPE_TEXT_VIEW,
	                                                      G_PARAM_READABLE));

	/**
	 * GtkSourceGutterRenderer:alignment-mode:
	 *
	 * The alignment mode of the renderer. This can be used to indicate
	 * that in the case a cell spans multiple lines (due to text wrapping)
	 * the alignment should work on either the full cell, the first line
	 * or the last line.
	 *
	 **/
	g_object_class_install_property (object_class,
	                                 PROP_ALIGNMENT_MODE,
	                                 g_param_spec_enum ("alignment-mode",
	                                                    "Alignment Mode",
	                                                    "The alignment mode",
	                                                    GTK_SOURCE_TYPE_GUTTER_RENDERER_ALIGNMENT_MODE,
	                                                    GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_CELL,
	                                                    G_PARAM_READWRITE | G_PARAM_CONSTRUCT));

	/**
	 * GtkSourceGutterRenderer:window-type:
	 *
	 * The window type of the view on which the renderer is placed (left,
	 * or right).
	 *
	 **/
	g_object_class_install_property (object_class,
	                                 PROP_WINDOW_TYPE,
	                                 g_param_spec_enum ("window-type",
	                                                    "Window Type",
	                                                    "The window type",
	                                                    GTK_TYPE_TEXT_WINDOW_TYPE,
	                                                    GTK_TEXT_WINDOW_PRIVATE,
	                                                    G_PARAM_READABLE));

	g_object_class_install_property (object_class,
	                                 PROP_SIZE,
	                                 g_param_spec_int ("size",
	                                                   "Size",
	                                                   "The size",
	                                                   0,
	                                                   G_MAXINT,
	                                                   0,
	                                                   G_PARAM_READWRITE | G_PARAM_CONSTRUCT));

	g_object_class_install_property (object_class,
	                                 PROP_BACKGROUND_RGBA,
	                                 g_param_spec_boxed ("background-rgba",
	                                                     "Background Color",
	                                                     "The background color",
	                                                     GDK_TYPE_RGBA,
	                                                     G_PARAM_READWRITE));

	g_object_class_install_property (object_class,
	                                 PROP_BACKGROUND_SET,
	                                 g_param_spec_boolean ("background-set",
	                                                       "Background Set",
	                                                       "Whether the background color is set",
	                                                       FALSE,
	                                                       G_PARAM_READWRITE | G_PARAM_CONSTRUCT));
}

static void
gtk_source_gutter_renderer_init (GtkSourceGutterRenderer *self)
{
	self->priv = gtk_source_gutter_renderer_get_instance_private (self);
}

/**
 * gtk_source_gutter_renderer_begin:
 * @renderer: a #GtkSourceGutterRenderer
 * @cr: a #cairo_t
 * @background_area: a #GdkRectangle
 * @cell_area: a #GdkRectangle
 * @start: a #GtkTextIter
 * @end: a #GtkTextIter
 *
 * Called when drawing a region begins. The region to be drawn is indicated
 * by @start and @end. The purpose is to allow the implementation to precompute
 * some state before the draw method is called for each cell.
 */
void
gtk_source_gutter_renderer_begin (GtkSourceGutterRenderer *renderer,
                                  cairo_t                 *cr,
                                  GdkRectangle            *background_area,
                                  GdkRectangle            *cell_area,
                                  GtkTextIter             *start,
                                  GtkTextIter             *end)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));
	g_return_if_fail (cr != NULL);
	g_return_if_fail (background_area != NULL);
	g_return_if_fail (cell_area != NULL);
	g_return_if_fail (start != NULL);
	g_return_if_fail (end != NULL);

	if (GTK_SOURCE_GUTTER_RENDERER_CLASS (G_OBJECT_GET_CLASS (renderer))->begin)
	{
		GTK_SOURCE_GUTTER_RENDERER_CLASS (
			G_OBJECT_GET_CLASS (renderer))->begin (renderer,
			                                       cr,
			                                       background_area,
			                                       cell_area,
			                                       start,
			                                       end);
	}
}

/**
 * gtk_source_gutter_renderer_draw:
 * @renderer: a #GtkSourceGutterRenderer
 * @cr: the cairo render context
 * @background_area: a #GdkRectangle indicating the total area to be drawn
 * @cell_area: a #GdkRectangle indicating the area to draw content
 * @start: a #GtkTextIter
 * @end: a #GtkTextIter
 * @state: a #GtkSourceGutterRendererState
 *
 * Main renderering method. Implementations should implement this method to draw
 * onto the cairo context. The @background_area indicates the total area of the
 * cell to be drawn. The @cell_area indicates the area where content can be
 * drawn (text, images, etc).
 *
 * The @background_area is the @cell_area plus the padding on each side (two
 * times the #GtkSourceGutterRenderer:xpad horizontally and two times the
 * #GtkSourceGutterRenderer:ypad vertically, so that the @cell_area is centered
 * inside @background_area).
 *
 * The @state argument indicates the current state of the renderer and should
 * be taken into account to properly draw the different possible states
 * (cursor, prelit, selected) if appropriate.
 */
void
gtk_source_gutter_renderer_draw (GtkSourceGutterRenderer      *renderer,
                                 cairo_t                      *cr,
                                 GdkRectangle                 *background_area,
                                 GdkRectangle                 *cell_area,
                                 GtkTextIter                  *start,
                                 GtkTextIter                  *end,
                                 GtkSourceGutterRendererState  state)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));
	g_return_if_fail (cr != NULL);
	g_return_if_fail (background_area != NULL);
	g_return_if_fail (cell_area != NULL);
	g_return_if_fail (start != NULL);
	g_return_if_fail (end != NULL);

	if (GTK_SOURCE_GUTTER_RENDERER_CLASS (G_OBJECT_GET_CLASS (renderer))->draw)
	{
		GTK_SOURCE_GUTTER_RENDERER_CLASS (
			G_OBJECT_GET_CLASS (renderer))->draw (renderer,
			                                      cr,
			                                      background_area,
			                                      cell_area,
			                                      start,
			                                      end,
			                                      state);
	}
}

/**
 * gtk_source_gutter_renderer_end:
 * @renderer: a #GtkSourceGutterRenderer
 *
 * Called when drawing a region of lines has ended.
 *
 **/
void
gtk_source_gutter_renderer_end (GtkSourceGutterRenderer *renderer)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	if (GTK_SOURCE_GUTTER_RENDERER_CLASS (G_OBJECT_GET_CLASS (renderer))->end)
	{
		GTK_SOURCE_GUTTER_RENDERER_CLASS (G_OBJECT_GET_CLASS (renderer))->end (renderer);
	}
}

/**
 * gtk_source_gutter_renderer_query_activatable:
 * @renderer: a #GtkSourceGutterRenderer
 * @iter: a #GtkTextIter at the start of the line to be activated
 * @area: a #GdkRectangle of the cell area to be activated
 * @event: the event that triggered the query
 *
 * Get whether the renderer is activatable at the location in @event. This is
 * called from #GtkSourceGutter to determine whether a renderer is activatable
 * using the mouse pointer.
 *
 * Returns: %TRUE if the renderer can be activated, %FALSE otherwise
 *
 **/
gboolean
gtk_source_gutter_renderer_query_activatable (GtkSourceGutterRenderer *renderer,
                                              GtkTextIter             *iter,
                                              GdkRectangle            *area,
                                              GdkEvent                *event)
{
	gboolean ret;

	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (area != NULL, FALSE);
	g_return_val_if_fail (event != NULL, FALSE);

	ret = FALSE;

	g_signal_emit (renderer,
	               signals[QUERY_ACTIVATABLE],
	               0,
	               iter,
	               area,
	               event,
	               &ret);

	return ret;
}

/**
 * gtk_source_gutter_renderer_activate:
 * @renderer: a #GtkSourceGutterRenderer
 * @iter: a #GtkTextIter at the start of the line where the renderer is activated
 * @area: a #GdkRectangle of the cell area where the renderer is activated
 * @event: the event that triggered the activation
 *
 * Emits the #GtkSourceGutterRenderer::activate signal of the renderer. This is
 * called from #GtkSourceGutter and should never have to be called manually.
 */
void
gtk_source_gutter_renderer_activate (GtkSourceGutterRenderer *renderer,
                                     GtkTextIter             *iter,
                                     GdkRectangle            *area,
                                     GdkEvent                *event)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));
	g_return_if_fail (iter != NULL);
	g_return_if_fail (area != NULL);
	g_return_if_fail (event != NULL);

	g_signal_emit (renderer, signals[ACTIVATE], 0, iter, area, event);
}

/**
 * gtk_source_gutter_renderer_queue_draw:
 * @renderer: a #GtkSourceGutterRenderer
 *
 * Emits the #GtkSourceGutterRenderer::queue-draw signal of the renderer. Call
 * this from an implementation to inform that the renderer has changed such that
 * it needs to redraw.
 */
void
gtk_source_gutter_renderer_queue_draw (GtkSourceGutterRenderer *renderer)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	g_signal_emit (renderer, signals[QUEUE_DRAW], 0);
}

/**
 * gtk_source_gutter_renderer_query_tooltip:
 * @renderer: a #GtkSourceGutterRenderer.
 * @iter: a #GtkTextIter.
 * @area: a #GdkRectangle.
 * @x: The x position of the tooltip.
 * @y: The y position of the tooltip.
 * @tooltip: a #GtkTooltip.
 *
 * Emits the #GtkSourceGutterRenderer::query-tooltip signal. This function is
 * called from #GtkSourceGutter. Implementations can override the default signal
 * handler or can connect to the signal externally.
 *
 * Returns: %TRUE if the tooltip has been set, %FALSE otherwise
 */
gboolean
gtk_source_gutter_renderer_query_tooltip (GtkSourceGutterRenderer *renderer,
                                          GtkTextIter             *iter,
                                          GdkRectangle            *area,
                                          gint                     x,
                                          gint                     y,
                                          GtkTooltip              *tooltip)
{
	gboolean ret;

	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (area != NULL, FALSE);
	g_return_val_if_fail (GTK_IS_TOOLTIP (tooltip), FALSE);

	ret = FALSE;

	g_signal_emit (renderer,
	               signals[QUERY_TOOLTIP],
	               0,
	               iter,
	               area,
	               x,
	               y,
	               tooltip,
	               &ret);

	return ret;
}

/**
 * gtk_source_gutter_renderer_query_data:
 * @renderer: a #GtkSourceGutterRenderer.
 * @start: a #GtkTextIter.
 * @end: a #GtkTextIter.
 * @state: a #GtkSourceGutterRendererState.
 *
 * Emit the #GtkSourceGutterRenderer::query-data signal. This function is called
 * to query for data just before rendering a cell. This is called from the
 * #GtkSourceGutter.  Implementations can override the default signal handler or
 * can connect a signal handler externally to the
 * #GtkSourceGutterRenderer::query-data signal.
 */
void
gtk_source_gutter_renderer_query_data (GtkSourceGutterRenderer      *renderer,
                                       GtkTextIter                  *start,
                                       GtkTextIter                  *end,
                                       GtkSourceGutterRendererState  state)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));
	g_return_if_fail (start != NULL);
	g_return_if_fail (end != NULL);


	/* Signal emission is relatively expensive and this code path is
	 * frequent enough to optimize the common case where we only have the
	 * override and no connected handlers.
	 *
	 * This is the same trick used by gtk_widget_draw().
	 */
	if (G_UNLIKELY (g_signal_has_handler_pending (renderer, signals[QUERY_DATA], 0, FALSE)))
	{
		g_signal_emit (renderer, signals[QUERY_DATA], 0, start, end, state);
	}
	else if (GTK_SOURCE_GUTTER_RENDERER_GET_CLASS (renderer)->query_data)
	{
		GTK_SOURCE_GUTTER_RENDERER_GET_CLASS (renderer)->query_data (renderer, start, end, state);
	}
}

/**
 * gtk_source_gutter_renderer_set_visible:
 * @renderer: a #GtkSourceGutterRenderer
 * @visible: the visibility
 *
 * Set whether the gutter renderer is visible.
 *
 **/
void
gtk_source_gutter_renderer_set_visible (GtkSourceGutterRenderer *renderer,
                                        gboolean                 visible)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	set_visible (renderer, visible);
}

/**
 * gtk_source_gutter_renderer_get_visible:
 * @renderer: a #GtkSourceGutterRenderer
 *
 * Get whether the gutter renderer is visible.
 *
 * Returns: %TRUE if the renderer is visible, %FALSE otherwise
 *
 **/
gboolean
gtk_source_gutter_renderer_get_visible (GtkSourceGutterRenderer *renderer)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer), FALSE);

	return renderer->priv->visible;
}

/**
 * gtk_source_gutter_renderer_set_padding:
 * @renderer: a #GtkSourceGutterRenderer
 * @xpad: the x-padding
 * @ypad: the y-padding
 *
 * Set the padding of the gutter renderer. Both @xpad and @ypad can be
 * -1, which means the values will not be changed (this allows changing only
 * one of the values).
 *
 * @xpad is the left and right padding. @ypad is the top and bottom padding.
 */
void
gtk_source_gutter_renderer_set_padding (GtkSourceGutterRenderer *renderer,
                                        gint                     xpad,
                                        gint                     ypad)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	set_xpad (renderer, xpad);
	set_ypad (renderer, ypad);
}

/**
 * gtk_source_gutter_renderer_get_padding:
 * @renderer: a #GtkSourceGutterRenderer
 * @xpad: (out caller-allocates) (optional): return location for the x-padding,
 *   or %NULL to ignore.
 * @ypad: (out caller-allocates) (optional): return location for the y-padding,
 *   or %NULL to ignore.
 *
 * Get the x-padding and y-padding of the gutter renderer.
 */
void
gtk_source_gutter_renderer_get_padding (GtkSourceGutterRenderer *renderer,
                                        gint                    *xpad,
                                        gint                    *ypad)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	if (xpad)
	{
		*xpad = renderer->priv->xpad;
	}

	if (ypad)
	{
		*ypad = renderer->priv->ypad;
	}
}

/**
 * gtk_source_gutter_renderer_set_alignment:
 * @renderer: a #GtkSourceGutterRenderer
 * @xalign: the x-alignment
 * @yalign: the y-alignment
 *
 * Set the alignment of the gutter renderer. Both @xalign and @yalign can be
 * -1, which means the values will not be changed (this allows changing only
 * one of the values).
 *
 * @xalign is the horizontal alignment. Set to 0 for a left alignment. 1 for a
 * right alignment. And 0.5 for centering the cells. @yalign is the vertical
 * alignment. Set to 0 for a top alignment. 1 for a bottom alignment.
 */
void
gtk_source_gutter_renderer_set_alignment (GtkSourceGutterRenderer *renderer,
                                          gfloat                   xalign,
                                          gfloat                   yalign)
{
	gboolean changed_x;
	gboolean changed_y;

	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	changed_x = set_xalign (renderer, xalign, FALSE);
	changed_y = set_yalign (renderer, yalign, FALSE);

	if (changed_x || changed_y)
	{
		gtk_source_gutter_renderer_queue_draw (renderer);
	}
}

/**
 * gtk_source_gutter_renderer_get_alignment:
 * @renderer: a #GtkSourceGutterRenderer
 * @xalign: (out caller-allocates) (optional): return location for the x-alignment,
 *   or %NULL to ignore.
 * @yalign: (out caller-allocates) (optional): return location for the y-alignment,
 *   or %NULL to ignore.
 *
 * Get the x-alignment and y-alignment of the gutter renderer.
 */
void
gtk_source_gutter_renderer_get_alignment (GtkSourceGutterRenderer *renderer,
                                          gfloat                  *xalign,
                                          gfloat                  *yalign)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	if (xalign)
	{
		*xalign = renderer->priv->xalign;
	}

	if (yalign)
	{
		*yalign = renderer->priv->yalign;
	}
}

/**
 * gtk_source_gutter_renderer_set_alignment_mode:
 * @renderer: a #GtkSourceGutterRenderer
 * @mode: a #GtkSourceGutterRendererAlignmentMode
 *
 * Set the alignment mode. The alignment mode describes the manner in which the
 * renderer is aligned (see :xalign and :yalign).
 *
 **/
void
gtk_source_gutter_renderer_set_alignment_mode (GtkSourceGutterRenderer              *renderer,
                                               GtkSourceGutterRendererAlignmentMode  mode)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	set_alignment_mode (renderer, mode);
}

/**
 * gtk_source_gutter_renderer_get_alignment_mode:
 * @renderer: a #GtkSourceGutterRenderer
 *
 * Get the alignment mode. The alignment mode describes the manner in which the
 * renderer is aligned (see :xalign and :yalign).
 *
 * Returns: a #GtkSourceGutterRendererAlignmentMode
 *
 **/
GtkSourceGutterRendererAlignmentMode
gtk_source_gutter_renderer_get_alignment_mode (GtkSourceGutterRenderer *renderer)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer), 0);

	return renderer->priv->alignment_mode;
}

/**
 * gtk_source_gutter_renderer_get_window_type:
 * @renderer: a #GtkSourceGutterRenderer
 *
 * Get the #GtkTextWindowType associated with the gutter renderer.
 *
 * Returns: a #GtkTextWindowType
 *
 **/
GtkTextWindowType
gtk_source_gutter_renderer_get_window_type (GtkSourceGutterRenderer *renderer)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer), GTK_TEXT_WINDOW_PRIVATE);

	return renderer->priv->window_type;
}

/**
 * gtk_source_gutter_renderer_get_view:
 * @renderer: a #GtkSourceGutterRenderer
 *
 * Get the view associated to the gutter renderer
 *
 * Returns: (transfer none): a #GtkTextView
 *
 **/
GtkTextView *
gtk_source_gutter_renderer_get_view (GtkSourceGutterRenderer *renderer)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer), NULL);

	return renderer->priv->view;
}

/**
 * gtk_source_gutter_renderer_get_size:
 * @renderer: a #GtkSourceGutterRenderer
 *
 * Get the size of the renderer.
 *
 * Returns: the size of the renderer.
 *
 **/
gint
gtk_source_gutter_renderer_get_size (GtkSourceGutterRenderer *renderer)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer), 0);

	return renderer->priv->size;
}

/**
 * gtk_source_gutter_renderer_set_size:
 * @renderer: a #GtkSourceGutterRenderer
 * @size: the size
 *
 * Sets the size of the renderer. A value of -1 specifies that the size
 * is to be determined dynamically.
 *
 **/
void
gtk_source_gutter_renderer_set_size (GtkSourceGutterRenderer *renderer,
                                     gint                     size)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	set_size (renderer, size);
}

/**
 * gtk_source_gutter_renderer_get_background:
 * @renderer: a #GtkSourceGutterRenderer
 * @color: (out caller-allocates) (optional): return value for a #GdkRGBA
 *
 * Get the background color of the renderer.
 *
 * Returns: %TRUE if the background color is set, %FALSE otherwise
 *
 **/
gboolean
gtk_source_gutter_renderer_get_background (GtkSourceGutterRenderer *renderer,
                                           GdkRGBA                 *color)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer), FALSE);

	if (color)
	{
		*color = renderer->priv->background_color;
	}

	return renderer->priv->background_set;
}

/**
 * gtk_source_gutter_renderer_set_background:
 * @renderer: a #GtkSourceGutterRenderer
 * @color: (nullable): a #GdkRGBA or %NULL
 *
 * Set the background color of the renderer. If @color is set to %NULL, the
 * renderer will not have a background color.
 *
 */
void
gtk_source_gutter_renderer_set_background (GtkSourceGutterRenderer *renderer,
                                           const GdkRGBA           *color)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	set_background_color (renderer, color);
}

void
_gtk_source_gutter_renderer_set_view (GtkSourceGutterRenderer *renderer,
                                      GtkTextView             *view,
                                      GtkTextWindowType        window_type)
{
	GtkTextView *old_view;

	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));
	g_return_if_fail (view == NULL || GTK_IS_TEXT_VIEW (view));

	old_view = renderer->priv->view;

	renderer->priv->window_type = window_type;
	renderer->priv->view = view != NULL ? g_object_ref (view) : NULL;

	if (GTK_SOURCE_GUTTER_RENDERER_GET_CLASS (renderer)->change_view)
	{
		GTK_SOURCE_GUTTER_RENDERER_GET_CLASS (renderer)->change_view (renderer,
		                                                              old_view);
	}

	if (old_view)
	{
		g_object_unref (old_view);
	}

	g_object_notify (G_OBJECT (renderer), "view");
	g_object_notify (G_OBJECT (renderer), "window_type");
}
