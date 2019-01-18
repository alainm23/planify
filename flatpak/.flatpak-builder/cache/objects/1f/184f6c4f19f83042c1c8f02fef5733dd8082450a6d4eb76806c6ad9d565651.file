/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- *
 * gtksourcegutterrenderer.h
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

#ifndef GTK_SOURCE_GUTTER_RENDERER_H
#define GTK_SOURCE_GUTTER_RENDERER_H

#if !defined (GTK_SOURCE_H_INSIDE) && !defined (GTK_SOURCE_COMPILATION)
#  if defined (__GNUC__)
#    warning "Only <gtksourceview/gtksource.h> can be included directly."
#  elif defined (G_OS_WIN32)
#    pragma message("Only <gtksourceview/gtksource.h> can be included directly.")
#  endif
#endif

#include <gtk/gtk.h>
#include <gtksourceview/gtksourcetypes.h>

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_GUTTER_RENDERER			(gtk_source_gutter_renderer_get_type ())
#define GTK_SOURCE_GUTTER_RENDERER(obj)			(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_GUTTER_RENDERER, GtkSourceGutterRenderer))
#define GTK_SOURCE_GUTTER_RENDERER_CONST(obj)		(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_GUTTER_RENDERER, GtkSourceGutterRenderer const))
#define GTK_SOURCE_GUTTER_RENDERER_CLASS(klass)		(G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_GUTTER_RENDERER, GtkSourceGutterRendererClass))
#define GTK_SOURCE_IS_GUTTER_RENDERER(obj)		(G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_GUTTER_RENDERER))
#define GTK_SOURCE_IS_GUTTER_RENDERER_CLASS(klass)	(G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_GUTTER_RENDERER))
#define GTK_SOURCE_GUTTER_RENDERER_GET_CLASS(obj)	(G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_GUTTER_RENDERER, GtkSourceGutterRendererClass))

typedef struct _GtkSourceGutterRendererClass	GtkSourceGutterRendererClass;
typedef struct _GtkSourceGutterRendererPrivate	GtkSourceGutterRendererPrivate;

/**
 * GtkSourceGutterRendererState:
 * @GTK_SOURCE_GUTTER_RENDERER_STATE_NORMAL: normal state
 * @GTK_SOURCE_GUTTER_RENDERER_STATE_CURSOR: area in the renderer represents the
 * line on which the insert cursor is currently positioned
 * @GTK_SOURCE_GUTTER_RENDERER_STATE_PRELIT: the mouse pointer is currently
 * over the activatable area of the renderer
 * @GTK_SOURCE_GUTTER_RENDERER_STATE_SELECTED: area in the renderer represents
 * a line in the buffer which contains part of the selection
 **/
typedef enum _GtkSourceGutterRendererState
{
	GTK_SOURCE_GUTTER_RENDERER_STATE_NORMAL = 0,
	GTK_SOURCE_GUTTER_RENDERER_STATE_CURSOR = 1 << 0,
	GTK_SOURCE_GUTTER_RENDERER_STATE_PRELIT = 1 << 1,
	GTK_SOURCE_GUTTER_RENDERER_STATE_SELECTED = 1 << 2
} GtkSourceGutterRendererState;

/**
 * GtkSourceGutterRendererAlignmentMode:
 * @GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_CELL: The full cell.
 * @GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_FIRST: The first line.
 * @GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_LAST: The last line.
 *
 * The alignment mode of the renderer, when a cell spans multiple lines (due to
 * text wrapping).
 **/
typedef enum _GtkSourceGutterRendererAlignmentMode
{
	GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_CELL,
	GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_FIRST,
	GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_LAST
} GtkSourceGutterRendererAlignmentMode;

struct _GtkSourceGutterRenderer
{
	GInitiallyUnowned parent;

	/*< private >*/
	GtkSourceGutterRendererPrivate *priv;
};

struct _GtkSourceGutterRendererClass
{
	GInitiallyUnownedClass parent_class;

	/*< public >*/
	void (*begin)               (GtkSourceGutterRenderer     *renderer,
	                             cairo_t                     *cr,
	                             GdkRectangle                *background_area,
	                             GdkRectangle                *cell_area,
	                             GtkTextIter                 *start,
	                             GtkTextIter                 *end);

	void (*draw)                (GtkSourceGutterRenderer      *renderer,
	                             cairo_t                      *cr,
	                             GdkRectangle                 *background_area,
	                             GdkRectangle                 *cell_area,
	                             GtkTextIter                  *start,
	                             GtkTextIter                  *end,
	                             GtkSourceGutterRendererState  state);

	void (*end)                 (GtkSourceGutterRenderer      *renderer);

	/**
	 * GtkSourceGutterRendererClass::change_view:
	 * @renderer: a #GtkSourceGutterRenderer.
	 * @old_view: (nullable): the old #GtkTextView.
	 *
	 * This is called when the text view changes for @renderer.
	 */
	void (*change_view)         (GtkSourceGutterRenderer      *renderer,
	                             GtkTextView                  *old_view);

	/**
	 * GtkSourceGutterRendererClass::change_buffer:
	 * @renderer: a #GtkSourceGutterRenderer.
	 * @old_buffer: (nullable): the old #GtkTextBuffer.
	 *
	 * This is called when the text buffer changes for @renderer.
	 */
	void (*change_buffer)       (GtkSourceGutterRenderer      *renderer,
	                             GtkTextBuffer                *old_buffer);

	/* Signal handlers */
	gboolean (*query_activatable) (GtkSourceGutterRenderer      *renderer,
	                               GtkTextIter                  *iter,
	                               GdkRectangle                 *area,
	                               GdkEvent                     *event);

	void (*activate)            (GtkSourceGutterRenderer      *renderer,
	                             GtkTextIter                  *iter,
	                             GdkRectangle                 *area,
	                             GdkEvent                     *event);

	void (*queue_draw)          (GtkSourceGutterRenderer      *renderer);

	gboolean (*query_tooltip)   (GtkSourceGutterRenderer      *renderer,
	                             GtkTextIter                  *iter,
	                             GdkRectangle                 *area,
	                             gint                          x,
	                             gint                          y,
	                             GtkTooltip                   *tooltip);

	void (*query_data)          (GtkSourceGutterRenderer      *renderer,
	                             GtkTextIter                  *start,
	                             GtkTextIter                  *end,
	                             GtkSourceGutterRendererState  state);
};

GTK_SOURCE_AVAILABLE_IN_ALL
GType    gtk_source_gutter_renderer_get_type (void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_begin           (GtkSourceGutterRenderer      *renderer,
                                                     cairo_t                      *cr,
                                                     GdkRectangle                 *background_area,
                                                     GdkRectangle                 *cell_area,
                                                     GtkTextIter                  *start,
                                                     GtkTextIter                  *end);

GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_draw            (GtkSourceGutterRenderer      *renderer,
                                                     cairo_t                      *cr,
                                                     GdkRectangle                 *background_area,
                                                     GdkRectangle                 *cell_area,
                                                     GtkTextIter                  *start,
                                                     GtkTextIter                  *end,
                                                     GtkSourceGutterRendererState  state);

GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_end             (GtkSourceGutterRenderer      *renderer);

GTK_SOURCE_AVAILABLE_IN_ALL
gint     gtk_source_gutter_renderer_get_size        (GtkSourceGutterRenderer      *renderer);

GTK_SOURCE_AVAILABLE_IN_ALL
void    gtk_source_gutter_renderer_set_size         (GtkSourceGutterRenderer      *renderer,
                                                     gint                          size);

GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_set_visible     (GtkSourceGutterRenderer      *renderer,
                                                     gboolean                      visible);

GTK_SOURCE_AVAILABLE_IN_ALL
gboolean gtk_source_gutter_renderer_get_visible     (GtkSourceGutterRenderer      *renderer);

GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_get_padding     (GtkSourceGutterRenderer      *renderer,
                                                     gint                         *xpad,
                                                     gint                         *ypad);

GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_set_padding     (GtkSourceGutterRenderer      *renderer,
                                                     gint                          xpad,
                                                     gint                          ypad);

GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_get_alignment   (GtkSourceGutterRenderer      *renderer,
                                                     gfloat                       *xalign,
                                                     gfloat                       *yalign);

GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_set_alignment   (GtkSourceGutterRenderer      *renderer,
                                                     gfloat                        xalign,
                                                     gfloat                        yalign);

GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_set_alignment_mode (GtkSourceGutterRenderer              *renderer,
                                                        GtkSourceGutterRendererAlignmentMode  mode);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkTextWindowType
	gtk_source_gutter_renderer_get_window_type  (GtkSourceGutterRenderer      *renderer);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkTextView *gtk_source_gutter_renderer_get_view    (GtkSourceGutterRenderer      *renderer);

GTK_SOURCE_AVAILABLE_IN_ALL
GtkSourceGutterRendererAlignmentMode
	gtk_source_gutter_renderer_get_alignment_mode (GtkSourceGutterRenderer    *renderer);

GTK_SOURCE_AVAILABLE_IN_ALL
gboolean gtk_source_gutter_renderer_get_background  (GtkSourceGutterRenderer      *renderer,
                                                     GdkRGBA                      *color);

GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_set_background  (GtkSourceGutterRenderer      *renderer,
                                                     const GdkRGBA                *color);

/* Emits the 'activate' signal */
GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_activate        (GtkSourceGutterRenderer      *renderer,
                                                     GtkTextIter                  *iter,
                                                     GdkRectangle                 *area,
                                                     GdkEvent                     *event);

/* Emits the 'query-activatable' signal */
GTK_SOURCE_AVAILABLE_IN_ALL
gboolean gtk_source_gutter_renderer_query_activatable (GtkSourceGutterRenderer      *renderer,
                                                       GtkTextIter                  *iter,
                                                       GdkRectangle                 *area,
                                                       GdkEvent                     *event);

/* Emits the 'queue-draw' signal */
GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_queue_draw      (GtkSourceGutterRenderer      *renderer);

/* Emits the 'query-tooltip' signal */
GTK_SOURCE_AVAILABLE_IN_ALL
gboolean gtk_source_gutter_renderer_query_tooltip   (GtkSourceGutterRenderer      *renderer,
                                                     GtkTextIter                  *iter,
                                                     GdkRectangle                 *area,
                                                     gint                          x,
                                                     gint                          y,
                                                     GtkTooltip                   *tooltip);

/* Emits the 'query-data' signal */
GTK_SOURCE_AVAILABLE_IN_ALL
void     gtk_source_gutter_renderer_query_data      (GtkSourceGutterRenderer      *renderer,
                                                     GtkTextIter                  *start,
                                                     GtkTextIter                  *end,
                                                     GtkSourceGutterRendererState  state);

G_END_DECLS

#endif /* GTK_SOURCE_GUTTER_RENDERER_H */
