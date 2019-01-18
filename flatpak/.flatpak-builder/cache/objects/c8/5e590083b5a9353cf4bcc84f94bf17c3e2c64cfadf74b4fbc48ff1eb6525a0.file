/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcepixbufhelper.h
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

#ifndef GTK_SOURCE_PIXBUF_HELPER_H
#define GTK_SOURCE_PIXBUF_HELPER_H

#include <gtk/gtk.h>
#include "gtksourcetypes-private.h"

G_GNUC_INTERNAL
GtkSourcePixbufHelper *gtk_source_pixbuf_helper_new (void);

G_GNUC_INTERNAL
void gtk_source_pixbuf_helper_free (GtkSourcePixbufHelper *helper);

G_GNUC_INTERNAL
void gtk_source_pixbuf_helper_set_pixbuf (GtkSourcePixbufHelper *helper,
                                          const GdkPixbuf       *pixbuf);

G_GNUC_INTERNAL
GdkPixbuf *gtk_source_pixbuf_helper_get_pixbuf (GtkSourcePixbufHelper *helper);

G_GNUC_INTERNAL
void gtk_source_pixbuf_helper_set_stock_id (GtkSourcePixbufHelper *helper,
                                            const gchar           *stock_id);

G_GNUC_INTERNAL
const gchar *gtk_source_pixbuf_helper_get_stock_id (GtkSourcePixbufHelper *helper);

G_GNUC_INTERNAL
void gtk_source_pixbuf_helper_set_icon_name (GtkSourcePixbufHelper *helper,
                                             const gchar           *icon_name);

G_GNUC_INTERNAL
const gchar *gtk_source_pixbuf_helper_get_icon_name (GtkSourcePixbufHelper *helper);

G_GNUC_INTERNAL
void gtk_source_pixbuf_helper_set_gicon (GtkSourcePixbufHelper *helper,
                                         GIcon                 *gicon);

G_GNUC_INTERNAL
GIcon *gtk_source_pixbuf_helper_get_gicon (GtkSourcePixbufHelper *helper);

G_GNUC_INTERNAL
GdkPixbuf *gtk_source_pixbuf_helper_render (GtkSourcePixbufHelper *helper,
                                            GtkWidget             *widget,
                                            gint                   size);

#endif /* GTK_SOURCE_PIXBUF_HELPER_H */

