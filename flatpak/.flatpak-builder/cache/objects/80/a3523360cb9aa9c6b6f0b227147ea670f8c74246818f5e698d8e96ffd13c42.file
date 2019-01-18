/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 8; tab-width: 8 -*- */
/* e-cell-renderer-color.h
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 */

#if !defined (__LIBEDATASERVERUI_H_INSIDE__) && !defined (LIBEDATASERVERUI_COMPILATION)
#error "Only <libedataserverui/libedataserverui.h> should be included directly."
#endif

#ifndef E_CELL_RENDERER_COLOR_H
#define E_CELL_RENDERER_COLOR_H

#include <gtk/gtk.h>

/* Standard GObject macros */
#define E_TYPE_CELL_RENDERER_COLOR \
	(e_cell_renderer_color_get_type ())
#define E_CELL_RENDERER_COLOR(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CELL_RENDERER_COLOR, ECellRendererColor))
#define E_CELL_RENDERER_COLOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CELL_RENDERER_COLOR, ECellRendererColorClass))
#define E_IS_CELL_RENDERER_COLOR(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CELL_RENDERER_COLOR))
#define E_IS_CELL_RENDERER_COLOR_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE ((cls), E_TYPE_CELL_RENDERER_COLOR))
#define E_CELL_RENDERER_COLOR_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CELL_RENDERER_COLOR, ECellRendererColorClass))

G_BEGIN_DECLS

typedef struct _ECellRendererColor ECellRendererColor;
typedef struct _ECellRendererColorClass ECellRendererColorClass;
typedef struct _ECellRendererColorPrivate ECellRendererColorPrivate;

/**
 * ECellRendererColor:
 *
 * Since: 2.22
 **/
struct _ECellRendererColor {
	GtkCellRenderer parent;
	ECellRendererColorPrivate *priv;
};

struct _ECellRendererColorClass {
	GtkCellRendererClass parent_class;

	/* Padding for future expansion */
	void (*_gtk_reserved1) (void);
	void (*_gtk_reserved2) (void);
	void (*_gtk_reserved3) (void);
	void (*_gtk_reserved4) (void);
};

GType            e_cell_renderer_color_get_type	(void) G_GNUC_CONST;
GtkCellRenderer *e_cell_renderer_color_new	(void);

G_END_DECLS

#endif /* E_CELL_RENDERER_COLOR_H */
