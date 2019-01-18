/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcepixbufhelper.c
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

#include "gtksourcepixbufhelper.h"

typedef enum _IconType
{
	ICON_TYPE_PIXBUF,
	ICON_TYPE_STOCK,
	ICON_TYPE_GICON,
	ICON_TYPE_NAME
} IconType;

struct _GtkSourcePixbufHelper
{
	GdkPixbuf *cached_pixbuf;
	IconType type;

	GdkPixbuf *pixbuf;
	gchar *icon_name;
	gchar *stock_id;
	GIcon *gicon;
};

GtkSourcePixbufHelper *
gtk_source_pixbuf_helper_new (void)
{
	return g_slice_new0 (GtkSourcePixbufHelper);
}

void
gtk_source_pixbuf_helper_free (GtkSourcePixbufHelper *helper)
{
	if (helper->pixbuf)
	{
		g_object_unref (helper->pixbuf);
	}

	if (helper->cached_pixbuf)
	{
		g_object_unref (helper->cached_pixbuf);
	}

	if (helper->gicon)
	{
		g_object_unref (helper->gicon);
	}

	g_free (helper->stock_id);
	g_free (helper->icon_name);

	g_slice_free (GtkSourcePixbufHelper, helper);
}

static void
set_cache (GtkSourcePixbufHelper *helper,
           GdkPixbuf             *pixbuf)
{
	if (helper->cached_pixbuf)
	{
		g_object_unref (helper->cached_pixbuf);
		helper->cached_pixbuf = NULL;
	}

	if (pixbuf)
	{
		helper->cached_pixbuf = pixbuf;
	}
}

static void
clear_cache (GtkSourcePixbufHelper *helper)
{
	set_cache (helper, NULL);
}

void
gtk_source_pixbuf_helper_set_pixbuf (GtkSourcePixbufHelper *helper,
                                     const GdkPixbuf       *pixbuf)
{
	helper->type = ICON_TYPE_PIXBUF;

	if (helper->pixbuf)
	{
		g_object_unref (helper->pixbuf);
		helper->pixbuf = NULL;
	}

	if (pixbuf)
	{
		helper->pixbuf = gdk_pixbuf_copy (pixbuf);
	}

	clear_cache (helper);
}

GdkPixbuf *
gtk_source_pixbuf_helper_get_pixbuf (GtkSourcePixbufHelper *helper)
{
	return helper->pixbuf;
}

void
gtk_source_pixbuf_helper_set_stock_id (GtkSourcePixbufHelper *helper,
                                       const gchar           *stock_id)
{
	helper->type = ICON_TYPE_STOCK;

	if (helper->stock_id)
	{
		g_free (helper->stock_id);
	}

	helper->stock_id = g_strdup (stock_id);

	clear_cache (helper);
}

const gchar *
gtk_source_pixbuf_helper_get_stock_id (GtkSourcePixbufHelper *helper)
{
	return helper->stock_id;
}

void
gtk_source_pixbuf_helper_set_icon_name (GtkSourcePixbufHelper *helper,
                                        const gchar           *icon_name)
{
	helper->type = ICON_TYPE_NAME;

	if (helper->icon_name)
	{
		g_free (helper->icon_name);
	}

	helper->icon_name = g_strdup (icon_name);

	clear_cache (helper);
}

const gchar *
gtk_source_pixbuf_helper_get_icon_name (GtkSourcePixbufHelper *helper)
{
	return helper->icon_name;
}

void
gtk_source_pixbuf_helper_set_gicon (GtkSourcePixbufHelper *helper,
                                    GIcon                 *gicon)
{
	helper->type = ICON_TYPE_GICON;

	if (helper->gicon)
	{
		g_object_unref (helper->gicon);
		helper->gicon = NULL;
	}

	if (gicon)
	{
		helper->gicon = g_object_ref (gicon);
	}

	clear_cache (helper);
}

GIcon *
gtk_source_pixbuf_helper_get_gicon (GtkSourcePixbufHelper *helper)
{
	return helper->gicon;
}

static void
from_pixbuf (GtkSourcePixbufHelper *helper,
             GtkWidget             *widget,
             gint                   size)
{
	if (helper->pixbuf == NULL)
	{
		return;
	}

	if (gdk_pixbuf_get_width (helper->pixbuf) <= size)
	{
		if (!helper->cached_pixbuf)
		{
			set_cache (helper, gdk_pixbuf_copy (helper->pixbuf));
		}

		return;
	}

	/* Make smaller */
	set_cache (helper, gdk_pixbuf_scale_simple (helper->pixbuf,
	                                            size,
	                                            size,
	                                            GDK_INTERP_BILINEAR));
}

G_GNUC_BEGIN_IGNORE_DEPRECATIONS;

static void
from_stock (GtkSourcePixbufHelper *helper,
            GtkWidget             *widget,
            gint                   size)
{
	GtkIconSize icon_size;
	gchar *name;

	name = g_strdup_printf ("GtkSourcePixbufHelper%d", size);

	icon_size = gtk_icon_size_from_name (name);

	if (icon_size == GTK_ICON_SIZE_INVALID)
	{
		icon_size = gtk_icon_size_register (name, size, size);
	}

	g_free (name);

	set_cache (helper, gtk_widget_render_icon_pixbuf (widget,
	                                                  helper->stock_id,
	                                                  icon_size));
}

G_GNUC_END_IGNORE_DEPRECATIONS;

static void
from_gicon (GtkSourcePixbufHelper *helper,
            GtkWidget             *widget,
            gint                   size)
{
	GdkScreen *screen;
	GtkIconTheme *icon_theme;
	GtkIconInfo *info;
	GtkIconLookupFlags flags;

	screen = gtk_widget_get_screen (widget);
	icon_theme = gtk_icon_theme_get_for_screen (screen);

	flags = GTK_ICON_LOOKUP_USE_BUILTIN;

	info = gtk_icon_theme_lookup_by_gicon (icon_theme,
	                                       helper->gicon,
	                                       size,
	                                       flags);

	if (info)
	{
		set_cache (helper, gtk_icon_info_load_icon (info, NULL));
	}
}

static void
from_name (GtkSourcePixbufHelper *helper,
           GtkWidget             *widget,
           gint                   size)
{
	GdkScreen *screen;
	GtkIconTheme *icon_theme;
	GtkIconInfo *info;
	GtkIconLookupFlags flags;
	gint scale;

	screen = gtk_widget_get_screen (widget);
	icon_theme = gtk_icon_theme_get_for_screen (screen);

	flags = GTK_ICON_LOOKUP_USE_BUILTIN;
        scale = gtk_widget_get_scale_factor (widget);

	info = gtk_icon_theme_lookup_icon_for_scale (icon_theme,
	                                             helper->icon_name,
	                                             size,
	                                             scale,
	                                             flags);

	if (info)
	{
		GdkPixbuf *pixbuf;

		if (gtk_icon_info_is_symbolic (info))
		{
			GtkStyleContext *context;

			context = gtk_widget_get_style_context (widget);
			pixbuf = gtk_icon_info_load_symbolic_for_context (info, context, NULL, NULL);
		}
		else
		{
			pixbuf = gtk_icon_info_load_icon (info, NULL);
		}

		set_cache (helper, pixbuf);
	}
}

GdkPixbuf *
gtk_source_pixbuf_helper_render (GtkSourcePixbufHelper *helper,
                                 GtkWidget             *widget,
                                 gint                   size)
{
	if (helper->cached_pixbuf &&
	    gdk_pixbuf_get_width (helper->cached_pixbuf) == size)
	{
		return helper->cached_pixbuf;
	}

	switch (helper->type)
	{
		case ICON_TYPE_PIXBUF:
			from_pixbuf (helper, widget, size);
			break;
		case ICON_TYPE_STOCK:
			from_stock (helper, widget, size);
			break;
		case ICON_TYPE_GICON:
			from_gicon (helper, widget, size);
			break;
		case ICON_TYPE_NAME:
			from_name (helper, widget, size);
			break;
		default:
			g_assert_not_reached ();
	}

	return helper->cached_pixbuf;
}

