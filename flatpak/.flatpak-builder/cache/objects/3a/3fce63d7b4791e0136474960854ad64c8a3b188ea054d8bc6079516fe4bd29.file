/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcespacedrawer.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2016 - Sébastien Wilmet <swilmet@gnome.org>
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

#ifndef GTK_SOURCE_SPACE_DRAWER_H
#define GTK_SOURCE_SPACE_DRAWER_H

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

#define GTK_SOURCE_TYPE_SPACE_DRAWER             (gtk_source_space_drawer_get_type ())
#define GTK_SOURCE_SPACE_DRAWER(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_SPACE_DRAWER, GtkSourceSpaceDrawer))
#define GTK_SOURCE_SPACE_DRAWER_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_SPACE_DRAWER, GtkSourceSpaceDrawerClass))
#define GTK_SOURCE_IS_SPACE_DRAWER(obj)          (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_SPACE_DRAWER))
#define GTK_SOURCE_IS_SPACE_DRAWER_CLASS(klass)  (G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_SPACE_DRAWER))
#define GTK_SOURCE_SPACE_DRAWER_GET_CLASS(obj)   (G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_SPACE_DRAWER, GtkSourceSpaceDrawerClass))

typedef struct _GtkSourceSpaceDrawerClass    GtkSourceSpaceDrawerClass;
typedef struct _GtkSourceSpaceDrawerPrivate  GtkSourceSpaceDrawerPrivate;

struct _GtkSourceSpaceDrawer
{
	GObject parent;

	GtkSourceSpaceDrawerPrivate *priv;
};

struct _GtkSourceSpaceDrawerClass
{
	GObjectClass parent_class;

	gpointer padding[20];
};

/**
 * GtkSourceSpaceTypeFlags:
 * @GTK_SOURCE_SPACE_TYPE_NONE: No flags.
 * @GTK_SOURCE_SPACE_TYPE_SPACE: Space character.
 * @GTK_SOURCE_SPACE_TYPE_TAB: Tab character.
 * @GTK_SOURCE_SPACE_TYPE_NEWLINE: Line break character. If the
 *   #GtkSourceBuffer:implicit-trailing-newline property is %TRUE,
 *   #GtkSourceSpaceDrawer also draws a line break at the end of the buffer.
 * @GTK_SOURCE_SPACE_TYPE_NBSP: Non-breaking space character.
 * @GTK_SOURCE_SPACE_TYPE_ALL: All white spaces.
 *
 * #GtkSourceSpaceTypeFlags contains flags for white space types.
 *
 * Since: 3.24
 */
typedef enum _GtkSourceSpaceTypeFlags
{
	GTK_SOURCE_SPACE_TYPE_NONE	= 0,
	GTK_SOURCE_SPACE_TYPE_SPACE	= 1 << 0,
	GTK_SOURCE_SPACE_TYPE_TAB	= 1 << 1,
	GTK_SOURCE_SPACE_TYPE_NEWLINE	= 1 << 2,
	GTK_SOURCE_SPACE_TYPE_NBSP	= 1 << 3,
	GTK_SOURCE_SPACE_TYPE_ALL	= 0xf
} GtkSourceSpaceTypeFlags;

/**
 * GtkSourceSpaceLocationFlags:
 * @GTK_SOURCE_SPACE_LOCATION_NONE: No flags.
 * @GTK_SOURCE_SPACE_LOCATION_LEADING: Leading white spaces on a line, i.e. the
 *   indentation.
 * @GTK_SOURCE_SPACE_LOCATION_INSIDE_TEXT: White spaces inside a line of text.
 * @GTK_SOURCE_SPACE_LOCATION_TRAILING: Trailing white spaces on a line.
 * @GTK_SOURCE_SPACE_LOCATION_ALL: White spaces anywhere.
 *
 * #GtkSourceSpaceLocationFlags contains flags for white space locations.
 *
 * If a line contains only white spaces (no text), the white spaces match both
 * %GTK_SOURCE_SPACE_LOCATION_LEADING and %GTK_SOURCE_SPACE_LOCATION_TRAILING.
 *
 * Since: 3.24
 */
typedef enum _GtkSourceSpaceLocationFlags
{
	GTK_SOURCE_SPACE_LOCATION_NONE		= 0,
	GTK_SOURCE_SPACE_LOCATION_LEADING	= 1 << 0,
	GTK_SOURCE_SPACE_LOCATION_INSIDE_TEXT	= 1 << 1,
	GTK_SOURCE_SPACE_LOCATION_TRAILING	= 1 << 2,
	GTK_SOURCE_SPACE_LOCATION_ALL		= 0x7
} GtkSourceSpaceLocationFlags;

GTK_SOURCE_AVAILABLE_IN_3_24
GType			gtk_source_space_drawer_get_type		(void) G_GNUC_CONST;

GTK_SOURCE_AVAILABLE_IN_3_24
GtkSourceSpaceDrawer *	gtk_source_space_drawer_new			(void);

GTK_SOURCE_AVAILABLE_IN_3_24
GtkSourceSpaceTypeFlags	gtk_source_space_drawer_get_types_for_locations	(GtkSourceSpaceDrawer        *drawer,
									 GtkSourceSpaceLocationFlags  locations);

GTK_SOURCE_AVAILABLE_IN_3_24
void			gtk_source_space_drawer_set_types_for_locations	(GtkSourceSpaceDrawer        *drawer,
									 GtkSourceSpaceLocationFlags  locations,
									 GtkSourceSpaceTypeFlags      types);

GTK_SOURCE_AVAILABLE_IN_3_24
GVariant *		gtk_source_space_drawer_get_matrix		(GtkSourceSpaceDrawer *drawer);

GTK_SOURCE_AVAILABLE_IN_3_24
void			gtk_source_space_drawer_set_matrix		(GtkSourceSpaceDrawer *drawer,
									 GVariant             *matrix);

GTK_SOURCE_AVAILABLE_IN_3_24
gboolean		gtk_source_space_drawer_get_enable_matrix	(GtkSourceSpaceDrawer *drawer);

GTK_SOURCE_AVAILABLE_IN_3_24
void			gtk_source_space_drawer_set_enable_matrix	(GtkSourceSpaceDrawer *drawer,
									 gboolean              enable_matrix);

GTK_SOURCE_AVAILABLE_IN_3_24
void			gtk_source_space_drawer_bind_matrix_setting	(GtkSourceSpaceDrawer *drawer,
									 GSettings            *settings,
									 const gchar          *key,
									 GSettingsBindFlags    flags);

G_END_DECLS

#endif /* GTK_SOURCE_SPACE_DRAWER_H */
