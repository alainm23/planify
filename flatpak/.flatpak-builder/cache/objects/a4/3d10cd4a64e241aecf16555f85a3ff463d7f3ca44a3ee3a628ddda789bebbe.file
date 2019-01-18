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

#ifndef __DBUSMENU_GTKMENU_H__
#define __DBUSMENU_GTKMENU_H__

#include <glib.h>
#include <glib-object.h>
#include "client.h"

G_BEGIN_DECLS

#define DBUSMENU_GTKMENU_TYPE            (dbusmenu_gtkmenu_get_type ())
#define DBUSMENU_GTKMENU(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), DBUSMENU_GTKMENU_TYPE, DbusmenuGtkMenu))
#define DBUSMENU_GTKMENU_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass), DBUSMENU_GTKMENU_TYPE, DbusmenuGtkMenuClass))
#define DBUSMENU_IS_GTKMENU(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), DBUSMENU_GTKMENU_TYPE))
#define DBUSMENU_IS_GTKMENU_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), DBUSMENU_GTKMENU_TYPE))
#define DBUSMENU_GTKMENU_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), DBUSMENU_GTKMENU_TYPE, DbusmenuGtkMenuClass))

typedef struct _DbusmenuGtkMenuPrivate DbusmenuGtkMenuPrivate;

/**
 * DbusmenuGtkMenuClass:
 * @parent_class: #GtkMenuClass
 * @reserved1: Reserved for future use.
 * @reserved2: Reserved for future use.
 * @reserved3: Reserved for future use.
 * @reserved4: Reserved for future use.
 * @reserved5: Reserved for future use.
 * @reserved6: Reserved for future use.
 *
 * All of the subclassable functions and signal slots for a
 * #DbusmenuGtkMenu.
 */
typedef struct _DbusmenuGtkMenuClass DbusmenuGtkMenuClass;
struct _DbusmenuGtkMenuClass {
	GtkMenuClass parent_class;

	/*< Private >*/
	void (*reserved1) (void);
	void (*reserved2) (void);
	void (*reserved3) (void);
	void (*reserved4) (void);
	void (*reserved5) (void);
	void (*reserved6) (void);
};

/**
 * DbusmenuGtkMenu:
 *
 * A #GtkMenu that is built using an abstract tree built from
 * a #DbusmenuGtkClient.
 */
typedef struct _DbusmenuGtkMenu      DbusmenuGtkMenu;
struct _DbusmenuGtkMenu {
	GtkMenu parent;

	/*< Private >*/
	DbusmenuGtkMenuPrivate * priv;
};

GType dbusmenu_gtkmenu_get_type (void);
DbusmenuGtkMenu * dbusmenu_gtkmenu_new (gchar * dbus_name, gchar * dbus_object);
DbusmenuGtkClient * dbusmenu_gtkmenu_get_client (DbusmenuGtkMenu * menu);

/**
	SECTION:menu
	@short_description: A GTK Menu Object that syncronizes over DBus
	@stability: Unstable
	@include: libdbusmenu-gtk/menu.h

	In general, this is just a #GtkMenu, why else would you care?  Oh,
	because this menu is created by someone else on a server that exists
	on the other side of DBus.  You need a #DbusmenuServer to be able
	push the data into this menu.

	The first thing you need to know is how to find that #DbusmenuServer
	on DBus.  This involves both the DBus name and the DBus object that
	the menu interface can be found on.  Those two value should be set
	when creating the object using dbusmenu_gtkmenu_new().  They are then
	stored on two properties #DbusmenuGtkMenu:dbus-name and #DbusmenuGtkMenu:dbus-object.

	After creation the #DbusmenuGtkMenu it will continue to keep in
	synchronization with the #DbusmenuServer object across Dbus.  If the
	number of entries change, the menus change, if they change thier
	properties change, they update in the items.  All of this should
	be handled transparently to the user of this object.
*/
G_END_DECLS

#endif
