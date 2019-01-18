/*
A small subclass of the menuitem for using clients.

Copyright 2010 Canonical Ltd.

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

#ifndef __DBUSMENU_CLIENT_MENUITEM_H__
#define __DBUSMENU_CLIENT_MENUITEM_H__

#include <glib.h>
#include <glib-object.h>
#include "menuitem.h"
#include "client.h"

G_BEGIN_DECLS

#define DBUSMENU_TYPE_CLIENT_MENUITEM            (dbusmenu_client_menuitem_get_type ())
#define DBUSMENU_CLIENT_MENUITEM(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), DBUSMENU_TYPE_CLIENT_MENUITEM, DbusmenuClientMenuitem))
#define DBUSMENU_CLIENT_MENUITEM_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass), DBUSMENU_TYPE_CLIENT_MENUITEM, DbusmenuClientMenuitemClass))
#define DBUSMENU_IS_CLIENT_MENUITEM(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), DBUSMENU_TYPE_CLIENT_MENUITEM))
#define DBUSMENU_IS_CLIENT_MENUITEM_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), DBUSMENU_TYPE_CLIENT_MENUITEM))
#define DBUSMENU_CLIENT_MENUITEM_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), DBUSMENU_TYPE_CLIENT_MENUITEM, DbusmenuClientMenuitemClass))

typedef struct _DbusmenuClientMenuitem      DbusmenuClientMenuitem;
typedef struct _DbusmenuClientMenuitemClass DbusmenuClientMenuitemClass;

struct _DbusmenuClientMenuitemClass {
	DbusmenuMenuitemClass parent_class;
};

struct _DbusmenuClientMenuitem {
	DbusmenuMenuitem parent;
};

GType dbusmenu_client_menuitem_get_type (void);
DbusmenuClientMenuitem * dbusmenu_client_menuitem_new (gint id, DbusmenuClient * client);

G_END_DECLS

#endif
