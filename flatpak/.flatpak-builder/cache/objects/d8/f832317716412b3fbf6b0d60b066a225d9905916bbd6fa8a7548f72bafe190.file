/*
A library to take the object model made consistent by libdbusmenu-glib
and visualize it in GTK.

Copyright 2009 Canonical Ltd.

Authors:
    Ted Gould <ted@canonical.com>

This program is free software: you can redistribute it and/or modify it 
under the terms of either or both of the following licenses:

1) the GNU Lesser General Public License version 3, as published by the 
Free Software Foundation; and/or
2) the GNU Lesser General Public License version 2.1, as published by 
the Free Software Foundation.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranties of 
MERCHANTABILITY, SATISFACTORY QUALITY or FITNESS FOR A PARTICULAR 
PURPOSE.  See the applicable version of the GNU Lesser General Public 
License for more details.

You should have received a copy of both the GNU Lesser General Public 
License version 3 and version 2.1 along with this program.  If not, see 
<http://www.gnu.org/licenses/>
*/

#ifndef DBUSMENU_GTK_MENUITEM_H__
#define DBUSMENU_GTK_MENUITEM_H__ 1

#include <glib.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <libdbusmenu-glib/menuitem.h>
#include <gdk/gdk.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

gboolean dbusmenu_menuitem_property_set_image (DbusmenuMenuitem * menuitem, const gchar * property, const GdkPixbuf * data);
GdkPixbuf * dbusmenu_menuitem_property_get_image (DbusmenuMenuitem * menuitem, const gchar * property);

gboolean dbusmenu_menuitem_property_set_shortcut (DbusmenuMenuitem * menuitem, guint key, GdkModifierType modifier);
gboolean dbusmenu_menuitem_property_set_shortcut_string (DbusmenuMenuitem * menuitem, const gchar * shortcut);
gboolean dbusmenu_menuitem_property_set_shortcut_menuitem (DbusmenuMenuitem * menuitem, const GtkMenuItem * gmi);
void dbusmenu_menuitem_property_get_shortcut (DbusmenuMenuitem * menuitem, guint * key, GdkModifierType * modifier);

/**
	SECTION:menuitem
	@short_description: Helpers for #DbusmenuMenuitem properties that require a GTK dependency
	@stability: Unstable
	@include: libdbusmenu-gtk/menuitem.h

	Some property helpers can't be done without picking up a GTK+
	dependency.  So those sit in libdbusmenu-gtk but have very similar
	prototypes to the code in libdbusmenu-glib so your code will
	look consistent, just with the extra depedency.
*/
G_END_DECLS

#endif
