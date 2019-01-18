/*
A library to communicate a menu object set accross DBus and
track updates and maintain consistency.

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

#ifndef __DBUSMENU_DEFAULTS_H__
#define __DBUSMENU_DEFAULTS_H__

#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS

#define DBUSMENU_TYPE_DEFAULTS            (dbusmenu_defaults_get_type ())
#define DBUSMENU_DEFAULTS(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), DBUSMENU_TYPE_DEFAULTS, DbusmenuDefaults))
#define DBUSMENU_DEFAULTS_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass), DBUSMENU_TYPE_DEFAULTS, DbusmenuDefaultsClass))
#define DBUSMENU_IS_DEFAULTS(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), DBUSMENU_TYPE_DEFAULTS))
#define DBUSMENU_IS_DEFAULTS_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), DBUSMENU_TYPE_DEFAULTS))
#define DBUSMENU_DEFAULTS_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), DBUSMENU_TYPE_DEFAULTS, DbusmenuDefaultsClass))

typedef struct _DbusmenuDefaults        DbusmenuDefaults;
typedef struct _DbusmenuDefaultsClass   DbusmenuDefaultsClass;
typedef struct _DbusmenuDefaultsPrivate DbusmenuDefaultsPrivate;

/*
 * DbusmenuDefaultsClass:
 *
 * All of the signals and functions for #DbusmenuDefaults
 */
struct _DbusmenuDefaultsClass {
	GObjectClass parent_class;
};

/*
 * DbusmenuDefaults:
 *
 * A singleton to hold all of the defaults for the menuitems
 * so they can use those easily.
 */
struct _DbusmenuDefaults {
	GObject parent;

	/*< Private >*/
	DbusmenuDefaultsPrivate * priv;
};

GType                 dbusmenu_defaults_get_type             (void);
DbusmenuDefaults *    dbusmenu_defaults_ref_default          (void);
void                  dbusmenu_defaults_default_set          (DbusmenuDefaults * defaults,
                                                              const gchar * type,
                                                              const gchar * property,
                                                              const GVariantType * prop_type,
                                                              GVariant * value);
GVariant *            dbusmenu_defaults_default_get          (DbusmenuDefaults * defaults,
                                                              const gchar * type,
                                                              const gchar * property);
GVariantType *        dbusmenu_defaults_default_get_type     (DbusmenuDefaults * defaults,
                                                              const gchar * type,
                                                              const gchar * property);

G_END_DECLS

#endif
