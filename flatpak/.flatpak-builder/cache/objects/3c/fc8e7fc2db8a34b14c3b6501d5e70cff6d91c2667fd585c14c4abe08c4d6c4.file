/*
A library to communicate a menu object set accross DBus and
track updates and maintain consistency.

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

#ifndef __DBUSMENU_MENUITEM_PRIVATE_H__
#define __DBUSMENU_MENUITEM_PRIVATE_H__

#include "menuitem.h"

G_BEGIN_DECLS

GVariant * dbusmenu_menuitem_build_variant (DbusmenuMenuitem * mi, const gchar ** properties, gint recurse);
gboolean dbusmenu_menuitem_realized (DbusmenuMenuitem * mi);
void dbusmenu_menuitem_set_realized (DbusmenuMenuitem * mi);
GVariant * dbusmenu_menuitem_properties_variant (DbusmenuMenuitem * mi, const gchar ** properties);
gboolean dbusmenu_menuitem_property_is_default (DbusmenuMenuitem * mi, const gchar * property);
gboolean dbusmenu_menuitem_exposed (DbusmenuMenuitem * mi);

G_END_DECLS

#endif
