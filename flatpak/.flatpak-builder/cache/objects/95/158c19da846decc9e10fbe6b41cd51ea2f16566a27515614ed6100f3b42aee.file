/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcegutterrenderermarks.c
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

#include "gtksourcegutterrenderermarks.h"
#include "gtksourceview.h"
#include "gtksourcebuffer.h"
#include "gtksourcemarkattributes.h"
#include "gtksourcemark.h"

#define COMPOSITE_ALPHA                 225

G_DEFINE_TYPE (GtkSourceGutterRendererMarks, gtk_source_gutter_renderer_marks, GTK_SOURCE_TYPE_GUTTER_RENDERER_PIXBUF)

static gint
sort_marks_by_priority (gconstpointer m1,
			gconstpointer m2,
			gpointer data)
{
	GtkSourceMark *mark1 = GTK_SOURCE_MARK (m1);
	GtkSourceMark *mark2 = GTK_SOURCE_MARK (m2);
	GtkSourceView *view = GTK_SOURCE_VIEW (data);
	GtkTextIter iter1, iter2;
	gint line1;
	gint line2;

	gtk_text_buffer_get_iter_at_mark (gtk_text_mark_get_buffer (GTK_TEXT_MARK (mark1)),
	                                  &iter1,
	                                  GTK_TEXT_MARK (mark1));

	gtk_text_buffer_get_iter_at_mark (gtk_text_mark_get_buffer (GTK_TEXT_MARK (mark2)),
	                                  &iter2,
	                                  GTK_TEXT_MARK (mark2));

	line1 = gtk_text_iter_get_line (&iter1);
	line2 = gtk_text_iter_get_line (&iter2);

	if (line1 == line2)
	{
		gint priority1 = -1;
		gint priority2 = -1;

		gtk_source_view_get_mark_attributes (view,
		                                     gtk_source_mark_get_category (mark1),
		                                     &priority1);

		gtk_source_view_get_mark_attributes (view,
		                                     gtk_source_mark_get_category (mark2),
		                                     &priority2);

		return priority1 - priority2;
	}
	else
	{
		return line2 - line1;
	}
}

static int
measure_line_height (GtkSourceView *view)
{
	PangoLayout *layout;
	gint height = 12;

	layout = gtk_widget_create_pango_layout (GTK_WIDGET (view), "QWERTY");

	if (layout)
	{
		pango_layout_get_pixel_size (layout, NULL, &height);
		g_object_unref (layout);
	}

	return height - 2;
}

static GdkPixbuf *
composite_marks (GtkSourceView *view,
                 GSList        *marks,
                 gint           size)
{
	GdkPixbuf *composite;
	gint mark_width;
	gint mark_height;

	/* Draw the mark with higher priority */
	marks = g_slist_sort_with_data (marks, sort_marks_by_priority, view);

	composite = NULL;
	mark_width = 0;
	mark_height = 0;

	/* composite all the pixbufs for the marks present at the line */
	do
	{
		GtkSourceMark *mark;
		GtkSourceMarkAttributes *attrs;
		const GdkPixbuf *pixbuf;

		mark = marks->data;
		attrs = gtk_source_view_get_mark_attributes (view,
		                                             gtk_source_mark_get_category (mark),
		                                             NULL);

		if (attrs == NULL)
		{
			continue;
		}

		pixbuf = gtk_source_mark_attributes_render_icon (attrs,
		                                                 GTK_WIDGET (view),
		                                                 size);

		if (pixbuf != NULL)
		{
			if (composite == NULL)
			{
				composite = gdk_pixbuf_copy (pixbuf);
				mark_width = gdk_pixbuf_get_width (composite);
				mark_height = gdk_pixbuf_get_height (composite);
			}
			else
			{
				gint pixbuf_w;
				gint pixbuf_h;

				pixbuf_w = gdk_pixbuf_get_width (pixbuf);
				pixbuf_h = gdk_pixbuf_get_height (pixbuf);

				gdk_pixbuf_composite (pixbuf,
				                      composite,
				                      0, 0,
				                      mark_width, mark_height,
				                      0, 0,
				                      (gdouble) pixbuf_w / mark_width,
				                      (gdouble) pixbuf_h / mark_height,
				                      GDK_INTERP_BILINEAR,
				                      COMPOSITE_ALPHA);
			}
		}

		marks = g_slist_next (marks);
	}
	while (marks);

	return composite;
}

static void
gutter_renderer_query_data (GtkSourceGutterRenderer      *renderer,
			    GtkTextIter                  *start,
			    GtkTextIter                  *end,
			    GtkSourceGutterRendererState  state)
{
	GSList *marks;
	GdkPixbuf *pixbuf = NULL;
	gint size = 0;
	GtkSourceView *view;
	GtkSourceBuffer *buffer;

	view = GTK_SOURCE_VIEW (gtk_source_gutter_renderer_get_view (renderer));
	buffer = GTK_SOURCE_BUFFER (gtk_text_view_get_buffer (GTK_TEXT_VIEW (view)));

	marks = gtk_source_buffer_get_source_marks_at_iter (buffer,
	                                                    start,
	                                                    NULL);

	if (marks != NULL)
	{
		size = measure_line_height (view);
		pixbuf = composite_marks (view, marks, size);

		g_slist_free (marks);
	}

	g_object_set (G_OBJECT (renderer),
	              "pixbuf", pixbuf,
	              "xpad", 2,
	              "yalign", 0.5,
	              "xalign", 0.5,
	              "alignment-mode", GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_FIRST,
	              NULL);
}

static gboolean
set_tooltip_widget_from_marks (GtkSourceView *view,
                               GtkTooltip    *tooltip,
                               GSList        *marks)
{
	GtkGrid *grid = NULL;
	gint row_num = 0;
	gint icon_size;

	gtk_icon_size_lookup (GTK_ICON_SIZE_MENU, NULL, &icon_size);

	for (; marks; marks = g_slist_next (marks))
	{
		const gchar *category;
		GtkSourceMark *mark;
		GtkSourceMarkAttributes *attrs;
		gchar *text;
		gboolean ismarkup = FALSE;
		GtkWidget *label;
		const GdkPixbuf *pixbuf;

		mark = marks->data;
		category = gtk_source_mark_get_category (mark);

		attrs = gtk_source_view_get_mark_attributes (view, category, NULL);

		if (attrs == NULL)
		{
			continue;
		}

		text = gtk_source_mark_attributes_get_tooltip_markup (attrs, mark);

		if (text == NULL)
		{
			text = gtk_source_mark_attributes_get_tooltip_text (attrs, mark);
		}
		else
		{
			ismarkup = TRUE;
		}

		if (text == NULL)
		{
			continue;
		}

		if (grid == NULL)
		{
			grid = GTK_GRID (gtk_grid_new ());
			gtk_grid_set_column_spacing (grid, 4);
			gtk_widget_show (GTK_WIDGET (grid));
		}

		label = gtk_label_new (NULL);

		if (ismarkup)
		{
			gtk_label_set_markup (GTK_LABEL (label), text);
		}
		else
		{
			gtk_label_set_text (GTK_LABEL (label), text);
		}

		gtk_widget_set_halign (label, GTK_ALIGN_START);
		gtk_widget_set_valign (label, GTK_ALIGN_START);
		gtk_widget_show (label);

		pixbuf = gtk_source_mark_attributes_render_icon (attrs,
		                                                 GTK_WIDGET (view),
		                                                 icon_size);

		if (pixbuf == NULL)
		{
			gtk_grid_attach (grid, label, 0, row_num, 2, 1);
		}
		else
		{
			GtkWidget *image;
			GdkPixbuf *copy;

			/* FIXME why a copy is needed? */
			copy = gdk_pixbuf_copy (pixbuf);
			image = gtk_image_new_from_pixbuf (copy);
			g_object_unref (copy);

			gtk_widget_set_halign (image, GTK_ALIGN_START);
			gtk_widget_set_valign (image, GTK_ALIGN_START);
			gtk_widget_show (image);

			gtk_grid_attach (grid, image, 0, row_num, 1, 1);
			gtk_grid_attach (grid, label, 1, row_num, 1, 1);
		}

		row_num++;

		if (marks->next != NULL)
		{
			GtkWidget *separator;

			separator = gtk_separator_new (GTK_ORIENTATION_HORIZONTAL);

			gtk_widget_show (separator);

			gtk_grid_attach (grid, separator, 0, row_num, 2, 1);
			row_num++;
		}

		g_free (text);
	}

	if (grid == NULL)
	{
		return FALSE;
	}

	gtk_tooltip_set_custom (tooltip, GTK_WIDGET (grid));

	return TRUE;
}

static gboolean
gutter_renderer_query_tooltip (GtkSourceGutterRenderer *renderer,
                               GtkTextIter             *iter,
                               GdkRectangle            *area,
                               gint                     x,
                               gint                     y,
                               GtkTooltip              *tooltip)
{
	GSList *marks;
	GtkSourceView *view;
	GtkSourceBuffer *buffer;

	view = GTK_SOURCE_VIEW (gtk_source_gutter_renderer_get_view (renderer));
	buffer = GTK_SOURCE_BUFFER (gtk_text_view_get_buffer (GTK_TEXT_VIEW (view)));

	marks = gtk_source_buffer_get_source_marks_at_iter (buffer,
	                                                    iter,
	                                                    NULL);

	if (marks != NULL)
	{
		marks = g_slist_sort_with_data (marks,
		                                sort_marks_by_priority,
		                                view);

		marks = g_slist_reverse (marks);

		return set_tooltip_widget_from_marks (view, tooltip, marks);
	}

	return FALSE;
}

static gboolean
gutter_renderer_query_activatable (GtkSourceGutterRenderer *renderer,
                                   GtkTextIter             *iter,
                                   GdkRectangle            *area,
                                   GdkEvent                *event)
{
	return TRUE;
}

static void
gutter_renderer_change_view (GtkSourceGutterRenderer *renderer,
                             GtkTextView             *old_view)
{
	GtkSourceView *view;

	view = GTK_SOURCE_VIEW (gtk_source_gutter_renderer_get_view (renderer));

	if (view != NULL)
	{
		gtk_source_gutter_renderer_set_size (renderer,
		                                     measure_line_height (view));
	}

	if (GTK_SOURCE_GUTTER_RENDERER_CLASS (gtk_source_gutter_renderer_marks_parent_class)->change_view != NULL)
	{
		GTK_SOURCE_GUTTER_RENDERER_CLASS (gtk_source_gutter_renderer_marks_parent_class)->change_view (renderer,
													       old_view);
	}
}

static void
gtk_source_gutter_renderer_marks_class_init (GtkSourceGutterRendererMarksClass *klass)
{
	GtkSourceGutterRendererClass *renderer_class = GTK_SOURCE_GUTTER_RENDERER_CLASS (klass);

	renderer_class->query_data = gutter_renderer_query_data;
	renderer_class->query_tooltip = gutter_renderer_query_tooltip;
	renderer_class->query_activatable = gutter_renderer_query_activatable;
	renderer_class->change_view = gutter_renderer_change_view;
}

static void
gtk_source_gutter_renderer_marks_init (GtkSourceGutterRendererMarks *self)
{
}

GtkSourceGutterRenderer *
gtk_source_gutter_renderer_marks_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_GUTTER_RENDERER_MARKS, NULL);
}
