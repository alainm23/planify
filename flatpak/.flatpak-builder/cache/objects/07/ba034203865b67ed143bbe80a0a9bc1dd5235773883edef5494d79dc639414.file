/*
Parse to take a set of GTK Menus and turn them into something that can
be sent over the wire.

Copyright 2011 Canonical Ltd.

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

#ifndef DBUSMENU_GTK_PARSER_H__
#define DBUSMENU_GTK_PARSER_H__

#include <libdbusmenu-glib/menuitem.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

DbusmenuMenuitem * dbusmenu_gtk_parse_menu_structure (GtkWidget * widget);
DbusmenuMenuitem * dbusmenu_gtk_parse_get_cached_item (GtkWidget * widget);

/**
	SECTION:parser
	@short_description: A parser of in-memory GTK menu trees
	@stability: Unstable
	@include: libdbusmenu-gtk/parser.h

	The parser will take a GTK menu tree and attach it to a Dbusmenu menu
	tree.  Along with setting up all the signals for updates and destruction.
	The returned item would be the root item of the given tree.
*/
G_END_DECLS

#endif /* DBUSMENU_GTK_PARSER_H__ */
