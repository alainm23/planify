/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- /
 * gtksourcegutter.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2009 - Jesse van den Kieboom
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

#include "gtksourcegutter.h"
#include "gtksourcegutter-private.h"
#include "gtksourceview.h"
#include "gtksourceview-i18n.h"
#include "gtksourcegutterrenderer.h"
#include "gtksourcegutterrenderer-private.h"

/**
 * SECTION:gutter
 * @Short_description: Gutter object for GtkSourceView
 * @Title: GtkSourceGutter
 * @See_also: #GtkSourceView, #GtkSourceMark
 *
 * The #GtkSourceGutter object represents the left or right gutter of the text
 * view. It is used by #GtkSourceView to draw the line numbers and
 * #GtkSourceMark<!-- -->s that might be present on a line. By packing
 * additional #GtkSourceGutterRenderer objects in the gutter, you can extend the
 * gutter with your own custom drawings.
 *
 * To get a #GtkSourceGutter, use the gtk_source_view_get_gutter() function.
 *
 * The gutter works very much the same way as cells rendered in a #GtkTreeView.
 * The concept is similar, with the exception that the gutter does not have an
 * underlying #GtkTreeModel. The builtin line number renderer is at position
 * #GTK_SOURCE_VIEW_GUTTER_POSITION_LINES (-30) and the marks renderer is at
 * #GTK_SOURCE_VIEW_GUTTER_POSITION_MARKS (-20). The gutter sorts the renderers
 * in ascending order, from left to right. So the marks are displayed on the
 * right of the line numbers.
 */

enum
{
	PROP_0,
	PROP_VIEW,
	PROP_WINDOW_TYPE,
	PROP_XPAD,
	PROP_YPAD
};

typedef struct
{
	GtkSourceGutterRenderer *renderer;

	gint prelit;
	gint position;

	gulong queue_draw_handler;
	gulong size_changed_handler;
	gulong notify_xpad_handler;
	gulong notify_ypad_handler;
	gulong notify_visible_handler;
} Renderer;

struct _GtkSourceGutterPrivate
{
	GtkSourceView *view;
	GtkTextWindowType window_type;
	GtkOrientation orientation;

	GList *renderers;

	gint xpad;
	gint ypad;

	guint is_drawing : 1;
};

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceGutter, gtk_source_gutter, G_TYPE_OBJECT)

static gboolean on_view_motion_notify_event (GtkSourceView   *view,
                                             GdkEventMotion  *event,
                                             GtkSourceGutter *gutter);


static gboolean on_view_enter_notify_event (GtkSourceView    *view,
                                            GdkEventCrossing *event,
                                            GtkSourceGutter  *gutter);

static gboolean on_view_leave_notify_event (GtkSourceView    *view,
                                            GdkEventCrossing *event,
                                            GtkSourceGutter  *gutter);

static gboolean on_view_button_press_event (GtkSourceView    *view,
                                            GdkEventButton   *event,
                                            GtkSourceGutter  *gutter);

static gboolean on_view_query_tooltip (GtkSourceView   *view,
                                       gint             x,
                                       gint             y,
                                       gboolean         keyboard_mode,
                                       GtkTooltip      *tooltip,
                                       GtkSourceGutter *gutter);

static void on_view_style_updated (GtkSourceView    *view,
                                   GtkSourceGutter  *gutter);

static void do_redraw (GtkSourceGutter *gutter);
static void update_gutter_size (GtkSourceGutter *gutter);

static GdkWindow *
get_window (GtkSourceGutter *gutter)
{
	return gtk_text_view_get_window (GTK_TEXT_VIEW (gutter->priv->view),
	                                 gutter->priv->window_type);
}

static void
on_renderer_size_changed (GtkSourceGutterRenderer *renderer,
                          GParamSpec              *spec,
                          GtkSourceGutter         *gutter)
{
	update_gutter_size (gutter);
}

static void
on_renderer_queue_draw (GtkSourceGutterRenderer *renderer,
                        GtkSourceGutter         *gutter)
{
	do_redraw (gutter);
}

static void
on_renderer_notify_padding (GtkSourceGutterRenderer *renderer,
                            GParamSpec              *spec,
                            GtkSourceGutter         *gutter)
{
	update_gutter_size (gutter);
}

static void
on_renderer_notify_visible (GtkSourceGutterRenderer *renderer,
                            GParamSpec              *spec,
                            GtkSourceGutter         *gutter)
{
	update_gutter_size (gutter);
}

static Renderer *
renderer_new (GtkSourceGutter         *gutter,
              GtkSourceGutterRenderer *renderer,
              gint                     position)
{
	Renderer *ret = g_slice_new0 (Renderer);

	ret->renderer = g_object_ref_sink (renderer);
	ret->position = position;
	ret->prelit = -1;

	_gtk_source_gutter_renderer_set_view (renderer,
	                                      GTK_TEXT_VIEW (gutter->priv->view),
	                                      gutter->priv->window_type);

	ret->size_changed_handler =
		g_signal_connect (ret->renderer,
		                  "notify::size",
		                  G_CALLBACK (on_renderer_size_changed),
		                  gutter);

	ret->queue_draw_handler =
		g_signal_connect (ret->renderer,
		                  "queue-draw",
		                  G_CALLBACK (on_renderer_queue_draw),
		                  gutter);

	ret->notify_xpad_handler =
		g_signal_connect (ret->renderer,
		                  "notify::xpad",
		                  G_CALLBACK (on_renderer_notify_padding),
		                  gutter);

	ret->notify_ypad_handler =
		g_signal_connect (ret->renderer,
		                  "notify::ypad",
		                  G_CALLBACK (on_renderer_notify_padding),
		                  gutter);

	ret->notify_visible_handler =
		g_signal_connect (ret->renderer,
		                  "notify::visible",
		                  G_CALLBACK (on_renderer_notify_visible),
		                  gutter);

	return ret;
}

static void
renderer_free (Renderer *renderer)
{
	g_signal_handler_disconnect (renderer->renderer,
	                             renderer->queue_draw_handler);

	g_signal_handler_disconnect (renderer->renderer,
	                             renderer->size_changed_handler);

	g_signal_handler_disconnect (renderer->renderer,
	                             renderer->notify_xpad_handler);

	g_signal_handler_disconnect (renderer->renderer,
	                             renderer->notify_ypad_handler);

	g_signal_handler_disconnect (renderer->renderer,
	                             renderer->notify_visible_handler);

	_gtk_source_gutter_renderer_set_view (renderer->renderer,
	                                      NULL,
	                                      GTK_TEXT_WINDOW_PRIVATE);

	g_object_unref (renderer->renderer);
	g_slice_free (Renderer, renderer);
}

static void
gtk_source_gutter_dispose (GObject *object)
{
	GtkSourceGutter *gutter = GTK_SOURCE_GUTTER (object);

	g_list_free_full (gutter->priv->renderers, (GDestroyNotify)renderer_free);
	gutter->priv->renderers = NULL;

	gutter->priv->view = NULL;

	G_OBJECT_CLASS (gtk_source_gutter_parent_class)->dispose (object);
}

static void
gtk_source_gutter_get_property (GObject    *object,
                                guint       prop_id,
                                GValue     *value,
                                GParamSpec *pspec)
{
	GtkSourceGutter *self = GTK_SOURCE_GUTTER (object);

	switch (prop_id)
	{
		case PROP_VIEW:
			g_value_set_object (value, self->priv->view);
			break;
		case PROP_WINDOW_TYPE:
			g_value_set_enum (value, self->priv->window_type);
			break;
		case PROP_XPAD:
			g_value_set_int (value, self->priv->xpad);
			break;
		case PROP_YPAD:
			g_value_set_int (value, self->priv->ypad);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
on_view_realize (GtkSourceView   *view,
                 GtkSourceGutter *gutter)
{
	update_gutter_size (gutter);
}

static void
set_view (GtkSourceGutter *gutter,
          GtkSourceView   *view)
{
	gutter->priv->view = view;

	g_signal_connect_object (view,
				 "motion-notify-event",
				 G_CALLBACK (on_view_motion_notify_event),
				 gutter,
				 0);

	g_signal_connect_object (view,
				 "enter-notify-event",
				 G_CALLBACK (on_view_enter_notify_event),
				 gutter,
				 0);

	g_signal_connect_object (view,
				 "leave-notify-event",
				 G_CALLBACK (on_view_leave_notify_event),
				 gutter,
				 0);

	g_signal_connect_object (view,
				 "button-press-event",
				 G_CALLBACK (on_view_button_press_event),
				 gutter,
				 0);

	g_signal_connect_object (view,
				 "query-tooltip",
				 G_CALLBACK (on_view_query_tooltip),
				 gutter,
				 0);

	g_signal_connect_object (view,
				 "realize",
				 G_CALLBACK (on_view_realize),
				 gutter,
				 0);

	g_signal_connect_object (view,
				 "style-updated",
				 G_CALLBACK (on_view_style_updated),
				 gutter,
				 0);
}

static void
do_redraw (GtkSourceGutter *gutter)
{
	GdkWindow *window;

	window = gtk_text_view_get_window (GTK_TEXT_VIEW (gutter->priv->view),
	                                   gutter->priv->window_type);

	if (window && !gutter->priv->is_drawing)
	{
		gdk_window_invalidate_rect (window, NULL, FALSE);
	}
}

static gint
calculate_gutter_size (GtkSourceGutter *gutter,
		       GArray          *sizes)
{
	GList *item;
	gint total_width = 0;

	/* Calculate size */
	for (item = gutter->priv->renderers; item; item = g_list_next (item))
	{
		Renderer *renderer = item->data;
		gint width;

		if (!gtk_source_gutter_renderer_get_visible (renderer->renderer))
		{
			width = 0;
		}
		else
		{
			gint xpad;
			gint size;

			size = gtk_source_gutter_renderer_get_size (renderer->renderer);

			gtk_source_gutter_renderer_get_padding (renderer->renderer,
			                                        &xpad,
			                                        NULL);

			width = size + 2 * xpad;
		}

		if (sizes)
		{
			g_array_append_val (sizes, width);
		}

		total_width += width;
	}

	return total_width;
}

static void
update_gutter_size (GtkSourceGutter *gutter)
{
	gint width = calculate_gutter_size (gutter, NULL);

	gtk_text_view_set_border_window_size (GTK_TEXT_VIEW (gutter->priv->view),
	                                      gutter->priv->window_type,
	                                      width);
}

static gboolean
set_padding (GtkSourceGutter *gutter,
             gint            *field,
             gint             padding,
             const gchar     *name,
             gboolean         resize)
{
	if (*field == padding || padding < 0)
	{
		return FALSE;
	}

	*field = padding;

	g_object_notify (G_OBJECT (gutter), name);

	if (resize)
	{
		update_gutter_size (gutter);
	}

	return TRUE;
}

static gboolean
set_xpad (GtkSourceGutter *gutter,
          gint             xpad,
          gboolean         resize)
{
	return set_padding (gutter, &gutter->priv->xpad, xpad, "xpad", resize);
}

static gboolean
set_ypad (GtkSourceGutter *gutter,
          gint             ypad,
          gboolean         resize)
{
	return set_padding (gutter, &gutter->priv->ypad, ypad, "ypad", resize);
}

static void
gtk_source_gutter_set_property (GObject       *object,
                                guint          prop_id,
                                const GValue  *value,
                                GParamSpec    *pspec)
{
	GtkSourceGutter *self = GTK_SOURCE_GUTTER (object);

	switch (prop_id)
	{
		case PROP_VIEW:
			set_view (self, GTK_SOURCE_VIEW (g_value_get_object (value)));
			break;
		case PROP_WINDOW_TYPE:
			self->priv->window_type = g_value_get_enum (value);
			break;
		case PROP_XPAD:
			set_xpad (self, g_value_get_int (value), TRUE);
			break;
		case PROP_YPAD:
			set_ypad (self, g_value_get_int (value), TRUE);
			break;
		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_gutter_constructed (GObject *object)
{
	GtkSourceGutter *gutter;

	gutter = GTK_SOURCE_GUTTER (object);

	if (gutter->priv->window_type == GTK_TEXT_WINDOW_LEFT ||
	    gutter->priv->window_type == GTK_TEXT_WINDOW_RIGHT)
	{
		gutter->priv->orientation = GTK_ORIENTATION_HORIZONTAL;
	}
	else
	{
		gutter->priv->orientation = GTK_ORIENTATION_VERTICAL;
	}

	G_OBJECT_CLASS (gtk_source_gutter_parent_class)->constructed (object);
}

static void
gtk_source_gutter_class_init (GtkSourceGutterClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->set_property = gtk_source_gutter_set_property;
	object_class->get_property = gtk_source_gutter_get_property;

	object_class->dispose = gtk_source_gutter_dispose;
	object_class->constructed = gtk_source_gutter_constructed;

	/**
	 * GtkSourceGutter:view:
	 *
	 * The #GtkSourceView of the gutter.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_VIEW,
	                                 g_param_spec_object ("view",
	                                                      "View",
	                                                      "",
	                                                      GTK_SOURCE_TYPE_VIEW,
	                                                      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	/**
	 * GtkSourceGutter:window-type:
	 *
	 * The text window type on which the window is placed.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_WINDOW_TYPE,
	                                 g_param_spec_enum ("window_type",
	                                                    "Window Type",
	                                                    "The gutters' text window type",
	                                                    GTK_TYPE_TEXT_WINDOW_TYPE,
	                                                    0,
	                                                    G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	/**
	 * GtkSourceGutter:xpad:
	 *
	 * The x-padding.
	 *
	 * Deprecated: 3.12: Use the #GtkSourceGutterRenderer's
	 * #GtkSourceGutterRenderer:xpad property instead.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_XPAD,
	                                 g_param_spec_int ("xpad",
	                                                   "X Padding",
	                                                   "The x-padding",
	                                                   -1,
	                                                   G_MAXINT,
	                                                   0,
	                                                   G_PARAM_READWRITE |
							   G_PARAM_CONSTRUCT |
							   G_PARAM_DEPRECATED));

	/**
	 * GtkSourceGutter:ypad:
	 *
	 * The y-padding.
	 *
	 * Deprecated: 3.12: Use the #GtkSourceGutterRenderer's
	 * #GtkSourceGutterRenderer:ypad property instead.
	 */
	g_object_class_install_property (object_class,
	                                 PROP_YPAD,
	                                 g_param_spec_int ("ypad",
	                                                   "Y Padding",
	                                                   "The y-padding",
	                                                   -1,
	                                                   G_MAXINT,
	                                                   0,
	                                                   G_PARAM_READWRITE |
							   G_PARAM_CONSTRUCT |
							   G_PARAM_DEPRECATED));
}

static void
gtk_source_gutter_init (GtkSourceGutter *self)
{
	self->priv = gtk_source_gutter_get_instance_private (self);
}

static gint
sort_by_position (Renderer *r1,
                  Renderer *r2,
                  gpointer  data)
{
	if (r1->position < r2->position)
	{
		return -1;
	}
	else if (r1->position > r2->position)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

static void
append_renderer (GtkSourceGutter *gutter,
                 Renderer        *renderer)
{
	gutter->priv->renderers =
		g_list_insert_sorted_with_data (gutter->priv->renderers,
		                                renderer,
		                                (GCompareDataFunc)sort_by_position,
		                                NULL);

	update_gutter_size (gutter);
}

GtkSourceGutter *
_gtk_source_gutter_new (GtkSourceView     *view,
			GtkTextWindowType  type)
{
	return g_object_new (GTK_SOURCE_TYPE_GUTTER,
	                     "view", view,
	                     "window_type", type,
	                     NULL);
}

/* Public API */

/**
 * gtk_source_gutter_get_view:
 * @gutter: a #GtkSourceGutter.
 *
 * Returns: (transfer none): the associated #GtkSourceView.
 * Since: 3.24
 */
GtkSourceView *
gtk_source_gutter_get_view (GtkSourceGutter *gutter)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER (gutter), NULL);

	return gutter->priv->view;
}

/**
 * gtk_source_gutter_get_window_type:
 * @gutter: a #GtkSourceGutter.
 *
 * Returns: the #GtkTextWindowType of @gutter.
 * Since: 3.24
 */
GtkTextWindowType
gtk_source_gutter_get_window_type (GtkSourceGutter *gutter)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER (gutter), GTK_TEXT_WINDOW_PRIVATE);

	return gutter->priv->window_type;
}

/**
 * gtk_source_gutter_get_window:
 * @gutter: a #GtkSourceGutter.
 *
 * Get the #GdkWindow of the gutter. The window will only be available when the
 * gutter has at least one, non-zero width, cell renderer packed.
 *
 * Returns: (transfer none): the #GdkWindow of the gutter, or %NULL
 * if the gutter has no window.
 *
 * Since: 2.8
 * Deprecated: 3.12: Use gtk_text_view_get_window() instead.
 */
GdkWindow *
gtk_source_gutter_get_window (GtkSourceGutter *gutter)
{
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER (gutter), NULL);
	g_return_val_if_fail (gutter->priv->view != NULL, NULL);

	return get_window (gutter);
}

/**
 * gtk_source_gutter_insert:
 * @gutter: a #GtkSourceGutter.
 * @renderer: a gutter renderer (must inherit from #GtkSourceGutterRenderer).
 * @position: the renderer position.
 *
 * Insert @renderer into the gutter. If @renderer is yet unowned then gutter
 * claims its ownership. Otherwise just increases renderer's reference count.
 * @renderer cannot be already inserted to another gutter.
 *
 * Returns: %TRUE if operation succeeded. Otherwise %FALSE.
 *
 * Since: 3.0
 *
 **/
gboolean
gtk_source_gutter_insert (GtkSourceGutter         *gutter,
                          GtkSourceGutterRenderer *renderer,
                          gint                     position)
{
	Renderer* internal_renderer;

	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER (gutter), FALSE);
	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer), FALSE);
	g_return_val_if_fail (gtk_source_gutter_renderer_get_view (renderer) == NULL, FALSE);
	g_return_val_if_fail (gtk_source_gutter_renderer_get_window_type (renderer) == GTK_TEXT_WINDOW_PRIVATE, FALSE);

	internal_renderer = renderer_new (gutter, renderer, position);
	append_renderer (gutter, internal_renderer);

	return TRUE;
}

static gboolean
renderer_find (GtkSourceGutter          *gutter,
               GtkSourceGutterRenderer  *renderer,
               Renderer                **ret,
               GList                   **retlist)
{
	GList *list;

	for (list = gutter->priv->renderers; list; list = g_list_next (list))
	{
		*ret = list->data;

		if ((*ret)->renderer == renderer)
		{
			if (retlist)
			{
				*retlist = list;
			}

			return TRUE;
		}
	}

	return FALSE;
}

/**
 * gtk_source_gutter_reorder:
 * @gutter: a #GtkSourceGutterRenderer.
 * @renderer: a #GtkCellRenderer.
 * @position: the new renderer position.
 *
 * Reorders @renderer in @gutter to new @position.
 *
 * Since: 2.8
 */
void
gtk_source_gutter_reorder (GtkSourceGutter         *gutter,
                           GtkSourceGutterRenderer *renderer,
                           gint                     position)
{
	Renderer *ret;
	GList *retlist;

	g_return_if_fail (GTK_SOURCE_IS_GUTTER (gutter));
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	if (renderer_find (gutter, renderer, &ret, &retlist))
	{
		gutter->priv->renderers =
			g_list_delete_link (gutter->priv->renderers,
			                    retlist);

		ret->position = position;
		append_renderer (gutter, ret);
	}
}

/**
 * gtk_source_gutter_remove:
 * @gutter: a #GtkSourceGutter.
 * @renderer: a #GtkSourceGutterRenderer.
 *
 * Removes @renderer from @gutter.
 *
 * Since: 2.8
 */
void
gtk_source_gutter_remove (GtkSourceGutter         *gutter,
                          GtkSourceGutterRenderer *renderer)
{
	Renderer *ret;
	GList *retlist;

	g_return_if_fail (GTK_SOURCE_IS_GUTTER (gutter));
	g_return_if_fail (GTK_SOURCE_IS_GUTTER_RENDERER (renderer));

	if (renderer_find (gutter, renderer, &ret, &retlist))
	{
		gutter->priv->renderers =
			g_list_delete_link (gutter->priv->renderers,
			                    retlist);

		update_gutter_size (gutter);
		renderer_free (ret);
	}
}

/**
 * gtk_source_gutter_queue_draw:
 * @gutter: a #GtkSourceGutter.
 *
 * Invalidates the drawable area of the gutter. You can use this to force a
 * redraw of the gutter if something has changed and needs to be redrawn.
 *
 * Since: 2.8
 */
void
gtk_source_gutter_queue_draw (GtkSourceGutter *gutter)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER (gutter));

	do_redraw (gutter);
}

typedef struct _LinesInfo LinesInfo;

struct _LinesInfo
{
	gint total_height;
	gint lines_count;
	GArray *buffer_coords;
	GArray *line_heights;
	GArray *line_numbers;
	GtkTextIter start;
	GtkTextIter end;
};

static LinesInfo *
lines_info_new (void)
{
	LinesInfo *info;

	info = g_slice_new0 (LinesInfo);

	info->buffer_coords = g_array_new (FALSE, FALSE, sizeof (gint));
	info->line_heights = g_array_new (FALSE, FALSE, sizeof (gint));
	info->line_numbers = g_array_new (FALSE, FALSE, sizeof (gint));

	return info;
}

static void
lines_info_free (LinesInfo *info)
{
	if (info != NULL)
	{
		g_array_free (info->buffer_coords, TRUE);
		g_array_free (info->line_heights, TRUE);
		g_array_free (info->line_numbers, TRUE);

		g_slice_free (LinesInfo, info);
	}
}

/* This function is taken and adapted from gtk+/tests/testtext.c */
static LinesInfo *
get_lines_info (GtkTextView *text_view,
		gint         first_y_buffer_coord,
		gint         last_y_buffer_coord)
{
	LinesInfo *info;
	GtkTextIter iter;
	gint last_line_num = -1;

	info = lines_info_new ();

	/* Get iter at first y */
	gtk_text_view_get_line_at_y (text_view, &iter, first_y_buffer_coord, NULL);

	info->start = iter;

	/* For each iter, get its location and add it to the arrays.
	 * Stop when we pass last_y_buffer_coord.
	 */
	while (!gtk_text_iter_is_end (&iter))
	{
		gint y;
		gint height;
		gint line_num;

		gtk_text_view_get_line_yrange (text_view, &iter, &y, &height);

		g_array_append_val (info->buffer_coords, y);
		g_array_append_val (info->line_heights, height);

		info->total_height += height;

		line_num = gtk_text_iter_get_line (&iter);
		g_array_append_val (info->line_numbers, line_num);

		last_line_num = line_num;

		info->lines_count++;

		if (last_y_buffer_coord <= (y + height))
		{
			break;
		}

		gtk_text_iter_forward_line (&iter);
	}

	if (gtk_text_iter_is_end (&iter))
	{
		gint y;
		gint height;
		gint line_num;

		gtk_text_view_get_line_yrange (text_view, &iter, &y, &height);

		line_num = gtk_text_iter_get_line (&iter);

		if (line_num != last_line_num)
		{
			g_array_append_val (info->buffer_coords, y);
			g_array_append_val (info->line_heights, height);

			info->total_height += height;

			g_array_append_val (info->line_numbers, line_num);
			info->lines_count++;
		}
	}

	if (info->lines_count == 0)
	{
		gint y = 0;
		gint n = 0;
		gint height;

		info->lines_count = 1;

		g_array_append_val (info->buffer_coords, y);
		g_array_append_val (info->line_numbers, n);

		gtk_text_view_get_line_yrange (text_view, &iter, &y, &height);
		g_array_append_val (info->line_heights, height);

		info->total_height += height;
	}

	info->end = iter;

	return info;
}

/* Returns %TRUE if @clip is set. @clip contains the area that should be drawn. */
static gboolean
get_clip_rectangle (GtkSourceGutter *gutter,
		    GtkSourceView   *view,
		    cairo_t         *cr,
		    GdkRectangle    *clip)
{
	GdkWindow *window = get_window (gutter);

	if (window == NULL || !gtk_cairo_should_draw_window (cr, window))
	{
		return FALSE;
	}

	gtk_cairo_transform_to_window (cr, GTK_WIDGET (view), window);

	return gdk_cairo_get_clip_rectangle (cr, clip);
}

static void
apply_style (GtkSourceGutter *gutter,
	     GtkSourceView   *view,
	     GtkStyleContext *style_context,
	     cairo_t         *cr)
{
	const gchar *class;
	GdkRGBA fg_color;

	switch (gutter->priv->window_type)
	{
		case GTK_TEXT_WINDOW_TOP:
			class = GTK_STYLE_CLASS_TOP;
			break;

		case GTK_TEXT_WINDOW_RIGHT:
			class = GTK_STYLE_CLASS_RIGHT;
			break;

		case GTK_TEXT_WINDOW_BOTTOM:
			class = GTK_STYLE_CLASS_BOTTOM;
			break;

		case GTK_TEXT_WINDOW_LEFT:
			class = GTK_STYLE_CLASS_LEFT;
			break;

		case GTK_TEXT_WINDOW_PRIVATE:
		case GTK_TEXT_WINDOW_WIDGET:
		case GTK_TEXT_WINDOW_TEXT:
		default:
			g_return_if_reached ();
	}

	/* Apply classes ourselves, since we are in connect_after and so they
	 * are not set by gtk.
	 */
	gtk_style_context_add_class (style_context, class);
	gtk_style_context_get_color (style_context,
	                             gtk_style_context_get_state (style_context),
	                             &fg_color);

	gdk_cairo_set_source_rgba (cr, &fg_color);
}

/* Call gtk_source_gutter_renderer_begin() on each renderer. */
static void
begin_draw (GtkSourceGutter *gutter,
	    GtkTextView     *view,
	    GArray          *renderer_widths,
	    LinesInfo       *info,
	    cairo_t         *cr)
{
	GdkRectangle background_area = { 0 };
	GdkRectangle cell_area;
	GList *l;
	gint renderer_num;

	background_area.x = 0;
	background_area.height = info->total_height;

	gtk_text_view_buffer_to_window_coords (view,
	                                       gutter->priv->window_type,
	                                       0,
	                                       g_array_index (info->buffer_coords, gint, 0),
	                                       NULL,
	                                       &background_area.y);

	cell_area = background_area;

	for (l = gutter->priv->renderers, renderer_num = 0;
	     l != NULL;
	     l = l->next, renderer_num++)
	{
		Renderer *renderer = l->data;
		gint width;
		gint xpad;

		width = g_array_index (renderer_widths, gint, renderer_num);

		if (!gtk_source_gutter_renderer_get_visible (renderer->renderer))
		{
			g_assert_cmpint (width, ==, 0);
			continue;
		}

		gtk_source_gutter_renderer_get_padding (renderer->renderer,
							&xpad,
							NULL);

		background_area.width = width;

		cell_area.width = background_area.width - 2 * xpad;
		cell_area.x = background_area.x + xpad;

		cairo_save (cr);

		gdk_cairo_rectangle (cr, &background_area);
		cairo_clip (cr);

		gtk_source_gutter_renderer_begin (renderer->renderer,
						  cr,
						  &background_area,
						  &cell_area,
						  &info->start,
						  &info->end);

		cairo_restore (cr);

		background_area.x += background_area.width;
	}
}

static void
draw_cells (GtkSourceGutter *gutter,
	    GtkTextView     *view,
	    GArray          *renderer_widths,
	    LinesInfo       *info,
	    cairo_t         *cr)
{
	GtkTextBuffer *buffer;
	GtkTextIter insert_iter;
	gint cur_line;
	GtkTextIter selection_start;
	GtkTextIter selection_end;
	gint selection_start_line = 0;
	gint selection_end_line = 0;
	gboolean has_selection;
	GtkTextIter start;
	gint i;

	buffer = gtk_text_view_get_buffer (view);

	gtk_text_buffer_get_iter_at_mark (buffer,
	                                  &insert_iter,
	                                  gtk_text_buffer_get_insert (buffer));

	cur_line = gtk_text_iter_get_line (&insert_iter);

	has_selection = gtk_text_buffer_get_selection_bounds (buffer,
	                                                      &selection_start,
	                                                      &selection_end);

	if (has_selection)
	{
		selection_start_line = gtk_text_iter_get_line (&selection_start);
		selection_end_line = gtk_text_iter_get_line (&selection_end);
	}

	start = info->start;
	i = 0;

	while (i < info->lines_count)
	{
		GtkTextIter end;
		GdkRectangle background_area;
		GtkSourceGutterRendererState state;
		gint pos;
		gint line_to_paint;
		gint renderer_num;
		GList *l;

		end = start;

		if (!gtk_text_iter_ends_line (&end))
		{
			/*
			 * It turns out that gtk_text_iter_forward_to_line_end
			 * is slower than jumping to the next line in the
			 * btree index and then moving backwards a character.
			 * We don't really care that we might be after the
			 * newline breaking characters, since those are part
			 * of the same line (rather than the next line).
			 */
			if (gtk_text_iter_forward_line (&end))
			{
				gtk_text_iter_backward_char (&end);
			}
		}

		/* Possible improvement: if buffer and window coords have the
		 * same unit, there are probably some possible performance
		 * improvements by avoiding some buffer <-> window coords
		 * conversions.
		 */
		gtk_text_view_buffer_to_window_coords (view,
		                                       gutter->priv->window_type,
		                                       0,
		                                       g_array_index (info->buffer_coords, gint, i),
		                                       NULL,
		                                       &pos);

		line_to_paint = g_array_index (info->line_numbers, gint, i);

		background_area.y = pos;
		background_area.height = g_array_index (info->line_heights, gint, i);
		background_area.x = 0;

		state = GTK_SOURCE_GUTTER_RENDERER_STATE_NORMAL;

		if (line_to_paint == cur_line)
		{
			state |= GTK_SOURCE_GUTTER_RENDERER_STATE_CURSOR;
		}

		if (has_selection &&
		    selection_start_line <= line_to_paint && line_to_paint <= selection_end_line)
		{
			state |= GTK_SOURCE_GUTTER_RENDERER_STATE_SELECTED;
		}

		for (l = gutter->priv->renderers, renderer_num = 0;
		     l != NULL;
		     l = l->next, renderer_num++)
		{
			Renderer *renderer;
			GdkRectangle cell_area;
			gint width;
			gint xpad;
			gint ypad;

			renderer = l->data;
			width = g_array_index (renderer_widths, gint, renderer_num);

			if (!gtk_source_gutter_renderer_get_visible (renderer->renderer))
			{
				g_assert_cmpint (width, ==, 0);
				continue;
			}

			gtk_source_gutter_renderer_get_padding (renderer->renderer,
			                                        &xpad,
			                                        &ypad);

			background_area.width = width;

			cell_area.y = background_area.y + ypad;
			cell_area.height = background_area.height - 2 * ypad;

			cell_area.x = background_area.x + xpad;
			cell_area.width = background_area.width - 2 * xpad;

			if (renderer->prelit >= 0 &&
			    cell_area.y <= renderer->prelit && renderer->prelit <= cell_area.y + cell_area.height)
			{
				state |= GTK_SOURCE_GUTTER_RENDERER_STATE_PRELIT;
			}

			gtk_source_gutter_renderer_query_data (renderer->renderer,
			                                       &start,
			                                       &end,
			                                       state);

			cairo_save (cr);

			gdk_cairo_rectangle (cr, &background_area);

			cairo_clip (cr);

			/* Call render with correct area */
			gtk_source_gutter_renderer_draw (renderer->renderer,
			                                 cr,
			                                 &background_area,
			                                 &cell_area,
			                                 &start,
			                                 &end,
			                                 state);

			cairo_restore (cr);

			background_area.x += background_area.width;
			state &= ~GTK_SOURCE_GUTTER_RENDERER_STATE_PRELIT;
		}

		i++;
		gtk_text_iter_forward_line (&start);
	}
}

static void
end_draw (GtkSourceGutter *gutter)
{
	GList *l;

	for (l = gutter->priv->renderers; l != NULL; l = l->next)
	{
		Renderer *renderer = l->data;

		if (gtk_source_gutter_renderer_get_visible (renderer->renderer))
		{
			gtk_source_gutter_renderer_end (renderer->renderer);
		}
	}
}

void
_gtk_source_gutter_draw (GtkSourceGutter *gutter,
			 GtkSourceView   *view,
			 cairo_t         *cr)
{
	GdkRectangle clip;
	GtkTextView *text_view;
	gint first_y_window_coord;
	gint last_y_window_coord;
	gint first_y_buffer_coord;
	gint last_y_buffer_coord;
	GArray *renderer_widths;
	LinesInfo *info;
	GtkStyleContext *style_context;

	if (!get_clip_rectangle (gutter, view, cr, &clip))
	{
		return;
	}

	gutter->priv->is_drawing = TRUE;

	renderer_widths = g_array_new (FALSE, FALSE, sizeof (gint));
	calculate_gutter_size (gutter, renderer_widths);

	text_view = GTK_TEXT_VIEW (view);

	first_y_window_coord = clip.y;
	last_y_window_coord = first_y_window_coord + clip.height;

	/* get the extents of the line printing */
	gtk_text_view_window_to_buffer_coords (text_view,
	                                       gutter->priv->window_type,
	                                       0,
	                                       first_y_window_coord,
	                                       NULL,
	                                       &first_y_buffer_coord);

	gtk_text_view_window_to_buffer_coords (text_view,
	                                       gutter->priv->window_type,
	                                       0,
	                                       last_y_window_coord,
	                                       NULL,
	                                       &last_y_buffer_coord);

	info = get_lines_info (text_view,
			       first_y_buffer_coord,
			       last_y_buffer_coord);

	style_context = gtk_widget_get_style_context (GTK_WIDGET (view));
	gtk_style_context_save (style_context);
	apply_style (gutter, view, style_context, cr);

	begin_draw (gutter,
		    text_view,
		    renderer_widths,
		    info,
		    cr);

	draw_cells (gutter,
		    text_view,
		    renderer_widths,
		    info,
		    cr);

	/* Allow to call queue_redraw() in ::end. */
	gutter->priv->is_drawing = FALSE;

	end_draw (gutter);

	gtk_style_context_restore (style_context);

	g_array_free (renderer_widths, TRUE);
	lines_info_free (info);
}

static Renderer *
renderer_at_x (GtkSourceGutter *gutter,
               gint             x,
               gint            *start,
               gint            *width)
{
	GList *item;
	gint s;
	gint w;

	update_gutter_size (gutter);

	s = 0;

	for (item = gutter->priv->renderers; item; item = g_list_next (item))
	{
		Renderer *renderer = item->data;
		gint xpad;

		if (!gtk_source_gutter_renderer_get_visible (renderer->renderer))
		{
			continue;
		}

		w = gtk_source_gutter_renderer_get_size (renderer->renderer);

		gtk_source_gutter_renderer_get_padding (renderer->renderer,
		                                        &xpad,
		                                        NULL);

		s += xpad;

		if (w > 0 && x >= s && x < s + w)
		{
			if (width)
			{
				*width = w;
			}

			if (start)
			{
				*start = s;
			}

			return renderer;
		}

		s += w + xpad;
	}

	return NULL;
}

static void
get_renderer_rect (GtkSourceGutter *gutter,
                   Renderer        *renderer,
                   GtkTextIter     *iter,
                   gint             line,
                   GdkRectangle    *rectangle,
                   gint             start)
{
	gint y;
	gint ypad;

	rectangle->x = start;

	gtk_text_view_get_line_yrange (GTK_TEXT_VIEW (gutter->priv->view),
	                               iter,
	                               &y,
	                               &rectangle->height);

	rectangle->width = gtk_source_gutter_renderer_get_size (renderer->renderer);

	gtk_text_view_buffer_to_window_coords (GTK_TEXT_VIEW (gutter->priv->view),
	                                       gutter->priv->window_type,
	                                       0,
	                                       y,
	                                       NULL,
	                                       &rectangle->y);

	gtk_source_gutter_renderer_get_padding (renderer->renderer,
	                                        NULL,
	                                        &ypad);

	rectangle->y += ypad;
	rectangle->height -= 2 * ypad;
}

static gboolean
renderer_query_activatable (GtkSourceGutter *gutter,
                            Renderer        *renderer,
                            GdkEvent        *event,
                            gint             x,
                            gint             y,
                            GtkTextIter     *line_iter,
                            GdkRectangle    *rect,
                            gint             start)
{
	gint y_buf;
	gint yline;
	GtkTextIter iter;
	GdkRectangle r;

	if (!renderer)
	{
		return FALSE;
	}

	gtk_text_view_window_to_buffer_coords (GTK_TEXT_VIEW (gutter->priv->view),
	                                       gutter->priv->window_type,
	                                       x,
	                                       y,
	                                       NULL,
	                                       &y_buf);

	gtk_text_view_get_line_at_y (GTK_TEXT_VIEW (gutter->priv->view),
	                             &iter,
	                             y_buf,
	                             &yline);

	if (yline > y_buf)
	{
		return FALSE;
	}

	get_renderer_rect (gutter, renderer, &iter, yline, &r, start);

	if (line_iter)
	{
		*line_iter = iter;
	}

	if (rect)
	{
		*rect = r;
	}

	if (y < r.y || y > r.y + r.height)
	{
		return FALSE;
	}

	return gtk_source_gutter_renderer_query_activatable (renderer->renderer,
	                                                     &iter,
	                                                     &r,
	                                                     event);
}

static gboolean
redraw_for_window (GtkSourceGutter *gutter,
		   GdkEvent        *event,
		   gboolean         act_on_window,
		   gint             x,
		   gint             y)
{
	Renderer *at_x = NULL;
	gint start = 0;
	GList *item;
	gboolean redraw;

	if (event->any.window != get_window (gutter) && act_on_window)
	{
		return FALSE;
	}

	if (act_on_window)
	{
		at_x = renderer_at_x (gutter, x, &start, NULL);
	}

	redraw = FALSE;

	for (item = gutter->priv->renderers; item; item = g_list_next (item))
	{
		Renderer *renderer = item->data;
		gint prelit = renderer->prelit;

		if (!gtk_source_gutter_renderer_get_visible (renderer->renderer))
		{
			renderer->prelit = -1;
		}
		else
		{
			if (renderer != at_x || !act_on_window)
			{
				renderer->prelit = -1;
			}
			else if (renderer_query_activatable (gutter,
			                                     renderer,
			                                     event,
			                                     x,
			                                     y,
			                                     NULL,
			                                     NULL,
			                                     start))
			{
				renderer->prelit = y;
			}
			else
			{
				renderer->prelit = -1;
			}
		}

		redraw |= (renderer->prelit != prelit);
	}

	if (redraw)
	{
		do_redraw (gutter);
	}

	return FALSE;
}

static gboolean
on_view_motion_notify_event (GtkSourceView    *view,
                             GdkEventMotion   *event,
                             GtkSourceGutter  *gutter)
{
	return redraw_for_window (gutter,
	                          (GdkEvent *)event,
	                          TRUE,
	                          (gint)event->x,
	                          (gint)event->y);
}

static gboolean
on_view_enter_notify_event (GtkSourceView     *view,
                            GdkEventCrossing  *event,
                            GtkSourceGutter   *gutter)
{
	return redraw_for_window (gutter,
	                          (GdkEvent *)event,
	                          TRUE,
	                          (gint)event->x,
	                          (gint)event->y);
}

static gboolean
on_view_leave_notify_event (GtkSourceView     *view,
                            GdkEventCrossing  *event,
                            GtkSourceGutter   *gutter)
{
	return redraw_for_window (gutter,
	                          (GdkEvent *)event,
	                          FALSE,
	                          (gint)event->x,
	                          (gint)event->y);
}

static gboolean
on_view_button_press_event (GtkSourceView    *view,
                            GdkEventButton   *event,
                            GtkSourceGutter  *gutter)
{
	Renderer *renderer;
	GtkTextIter line_iter;
	gint start = -1;
	GdkRectangle rect;

	if (event->window != get_window (gutter))
	{
		return FALSE;
	}

	if (event->type != GDK_BUTTON_PRESS)
	{
		return FALSE;
	}

	/* Check cell renderer */
	renderer = renderer_at_x (gutter, event->x, &start, NULL);

	if (renderer_query_activatable (gutter,
	                                renderer,
	                                (GdkEvent *)event,
	                                (gint)event->x,
	                                (gint)event->y,
	                                &line_iter,
	                                &rect,
	                                start))
	{
		gtk_source_gutter_renderer_activate (renderer->renderer,
		                                     &line_iter,
		                                     &rect,
		                                     (GdkEvent *)event);

		do_redraw (gutter);

		return TRUE;
	}

	return FALSE;
}

static gboolean
on_view_query_tooltip (GtkSourceView   *view,
                       gint             x,
                       gint             y,
                       gboolean         keyboard_mode,
                       GtkTooltip      *tooltip,
                       GtkSourceGutter *gutter)
{
	GtkTextView *text_view = GTK_TEXT_VIEW (view);
	Renderer *renderer;
	gint start = 0;
	gint width = 0;
	gint y_buf;
	gint yline;
	GtkTextIter line_iter;
	GdkRectangle rect;

	if (keyboard_mode)
	{
		return FALSE;
	}

	/* Check cell renderer */
	renderer = renderer_at_x (gutter, x, &start, &width);

	if (!renderer)
	{
		return FALSE;
	}

	gtk_text_view_window_to_buffer_coords (text_view,
	                                       gutter->priv->window_type,
	                                       x, y,
	                                       NULL, &y_buf);

	gtk_text_view_get_line_at_y (GTK_TEXT_VIEW (view),
	                             &line_iter,
	                             y_buf,
	                             &yline);

	if (yline > y_buf)
	{
		return FALSE;
	}

	get_renderer_rect (gutter,
	                   renderer,
	                   &line_iter,
	                   yline,
	                   &rect,
	                   start);

	return gtk_source_gutter_renderer_query_tooltip (renderer->renderer,
	                                                 &line_iter,
	                                                 &rect,
	                                                 x,
	                                                 y,
	                                                 tooltip);
}

static void
on_view_style_updated (GtkSourceView   *view,
                       GtkSourceGutter *gutter)
{
	gtk_source_gutter_queue_draw (gutter);
}

/**
 * gtk_source_gutter_set_padding:
 * @gutter:
 * @xpad:
 * @ypad:
 *
 * Deprecated: 3.12: Use gtk_source_gutter_renderer_set_padding() instead.
 */
void
gtk_source_gutter_set_padding (GtkSourceGutter *gutter,
                               gint             xpad,
                               gint             ypad)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER (gutter));

	if (set_xpad (gutter, xpad, FALSE) || set_ypad (gutter, ypad, FALSE))
	{
		update_gutter_size (gutter);
	}
}

/**
 * gtk_source_gutter_get_padding:
 * @gutter:
 * @xpad:
 * @ypad:
 *
 * Deprecated: 3.12: Use gtk_source_gutter_renderer_get_padding() instead.
 */
void
gtk_source_gutter_get_padding (GtkSourceGutter *gutter,
                               gint            *xpad,
                               gint            *ypad)
{
	g_return_if_fail (GTK_SOURCE_IS_GUTTER (gutter));

	if (xpad)
	{
		*xpad = gutter->priv->xpad;
	}

	if (ypad)
	{
		*ypad = gutter->priv->ypad;
	}
}

/**
 * gtk_source_gutter_get_renderer_at_pos:
 * @gutter: A #GtkSourceGutter.
 * @x: The x position to get identified.
 * @y: The y position to get identified.
 *
 * Finds the #GtkSourceGutterRenderer at (x, y).
 *
 * Returns: (nullable) (transfer none): the renderer at (x, y) or %NULL.
 */
/* TODO: better document this function. The (x,y) position is different from
 * the position passed to gtk_source_gutter_insert() and
 * gtk_source_gutter_reorder(). The (x,y) coordinate can come from a click
 * event, for example? Is the (x,y) a coordinate of the Gutter's GdkWindow?
 * Where is the (0,0)? And so on.
 * Also, this function doesn't seem to be used.
 */
GtkSourceGutterRenderer *
gtk_source_gutter_get_renderer_at_pos (GtkSourceGutter *gutter,
                                       gint             x,
                                       gint             y)
{
	Renderer *renderer;

	g_return_val_if_fail (GTK_SOURCE_IS_GUTTER (gutter), NULL);

	renderer = renderer_at_x (gutter, x, NULL, NULL);

	if (renderer == NULL)
	{
		return NULL;
	}

	return renderer->renderer;
}
