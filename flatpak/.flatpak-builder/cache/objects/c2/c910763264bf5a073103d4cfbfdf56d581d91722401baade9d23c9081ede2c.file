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

#include "menuitem.h"
#include <gdk/gdk.h>
#include <gtk/gtk.h>

/**
 * dbusmenu_menuitem_property_set_image:
 * @menuitem: The #DbusmenuMenuitem to set the property on.
 * @property: Name of the property to set.
 * @data: The image to place on the property.
 * 
 * This function takes the pixbuf that is stored in @data and
 * turns it into a base64 encoded PNG so that it can be placed
 * onto a standard #DbusmenuMenuitem property.
 * 
 * Return value: Whether the function was able to set the property
 * 	or not.
*/
gboolean
dbusmenu_menuitem_property_set_image (DbusmenuMenuitem * menuitem, const gchar * property, const GdkPixbuf * data)
{
	g_return_val_if_fail(GDK_IS_PIXBUF(data), FALSE);
	g_return_val_if_fail(DBUSMENU_IS_MENUITEM(menuitem), FALSE);
	g_return_val_if_fail(property != NULL && property[0] != '\0', FALSE);

	GError * error = NULL;
	gchar * png_data;
	gsize png_data_len;

	if (!gdk_pixbuf_save_to_buffer((GdkPixbuf *)data, &png_data, &png_data_len, "png", &error, NULL)) {
		if (error == NULL) {
			g_warning("Unable to create pixbuf data stream: %d", (gint)png_data_len);
		} else {
			g_warning("Unable to create pixbuf data stream: %s", error->message);
			g_error_free(error);
			error = NULL;
		}

		return FALSE;
	}

	gboolean propreturn = FALSE;
	propreturn = dbusmenu_menuitem_property_set_byte_array(menuitem, property, (guchar *)png_data, png_data_len);

	g_free(png_data);

	return propreturn;
}

/**
 * dbusmenu_menuitem_property_get_image:
 * @menuitem: The #DbusmenuMenuitem to look for the property on
 * @property: The name of the property to look for.
 * 
 * This function looks on the menu item for a property by the
 * name of @property.  If one exists it tries to turn it into
 * a #GdkPixbuf.  It assumes that the property is a base64 encoded
 * PNG file like the one created by #dbusmenu_menuite_property_set_image.
 * 
 * Return value: (transfer full): A pixbuf or #NULL to signal error.
 */
GdkPixbuf *
dbusmenu_menuitem_property_get_image (DbusmenuMenuitem * menuitem, const gchar * property)
{
	g_return_val_if_fail(DBUSMENU_IS_MENUITEM(menuitem), NULL);
	g_return_val_if_fail(property != NULL && property[0] != '\0', NULL);

	gsize length = 0;
	const guchar * icondata = dbusmenu_menuitem_property_get_byte_array(menuitem, property, &length);

	/* There is no icon */
	if (length == 0) {
		return NULL;
	}
	
	GInputStream * input = g_memory_input_stream_new_from_data(icondata, length, NULL);
	if (input == NULL) {
		g_warning("Cound not create input stream from icon property data");
		return NULL;
	}

	GError * error = NULL;
	GdkPixbuf * icon = gdk_pixbuf_new_from_stream(input, NULL, &error);

	if (error != NULL) {
		g_warning("Unable to build Pixbuf from icon data: %s", error->message);
		g_error_free(error);
	}

	g_object_unref(input);

	return icon;
}

/**
 * dbusmenu_menuitem_property_set_shortcut_string:
 * @menuitem: The #DbusmenuMenuitem to set the shortcut on
 * @shortcut: String describing the shortcut
 * 
 * This function takes a GTK shortcut string as defined in
 * #gtk_accelerator_parse and turns that into the information
 * required to send it over DBusmenu.
 * 
 * Return value: Whether it was successful at setting the property.
 */
gboolean
dbusmenu_menuitem_property_set_shortcut_string (DbusmenuMenuitem * menuitem, const gchar * shortcut)
{
	g_return_val_if_fail(DBUSMENU_IS_MENUITEM(menuitem), FALSE);
	g_return_val_if_fail(shortcut != NULL, FALSE);

	guint key = 0;
	GdkModifierType modifier = 0;

	gtk_accelerator_parse(shortcut, &key, &modifier);

	if (key == 0) {
		g_warning("Unable to parse shortcut string '%s'", shortcut);
		return FALSE;
	}

	return dbusmenu_menuitem_property_set_shortcut(menuitem, key, modifier);
}

/**
 * dbusmenu_menuitem_property_set_shortcut:
 * @menuitem: The #DbusmenuMenuitem to set the shortcut on
 * @key: The keycode of the key to send
 * @modifier: A bitmask of modifiers used to activate the item
 * 
 * Takes the modifer described by @key and @modifier and places that into
 * the format sending across Dbus for shortcuts.
 * 
 * Return value: Whether it was successful at setting the property.
 */
gboolean
dbusmenu_menuitem_property_set_shortcut (DbusmenuMenuitem * menuitem, guint key, GdkModifierType modifier)
{
	g_return_val_if_fail(DBUSMENU_IS_MENUITEM(menuitem), FALSE);
	g_return_val_if_fail(gtk_accelerator_valid(key, modifier), FALSE);

	const gchar * keyname = gdk_keyval_name(key);
	g_return_val_if_fail(keyname != NULL, FALSE);

	GVariantBuilder builder;
	g_variant_builder_init(&builder, G_VARIANT_TYPE_ARRAY);

	if (modifier & GDK_CONTROL_MASK) {
		g_variant_builder_add(&builder, "s", DBUSMENU_MENUITEM_SHORTCUT_CONTROL);
	}
	if (modifier & GDK_MOD1_MASK) {
		g_variant_builder_add(&builder, "s", DBUSMENU_MENUITEM_SHORTCUT_ALT);
	}
	if (modifier & GDK_SHIFT_MASK) {
		g_variant_builder_add(&builder, "s", DBUSMENU_MENUITEM_SHORTCUT_SHIFT);
	}
	if (modifier & GDK_SUPER_MASK) {
		g_variant_builder_add(&builder, "s", DBUSMENU_MENUITEM_SHORTCUT_SUPER);
	}

	g_variant_builder_add(&builder, "s", keyname);

	GVariant * inside = g_variant_builder_end(&builder);
	g_variant_builder_init(&builder, G_VARIANT_TYPE_ARRAY);
	g_variant_builder_add_value(&builder, inside);
	GVariant * outsidevariant = g_variant_builder_end(&builder);

	return dbusmenu_menuitem_property_set_variant(menuitem, DBUSMENU_MENUITEM_PROP_SHORTCUT, outsidevariant);
}

/* Look at the closures in an accel group and find
   the one that matches the one we've been passed */
static gboolean
find_closure (GtkAccelKey * key, GClosure * closure, gpointer user_data)
{
	return closure == user_data;
}

/**
 * dbusmenu_menuitem_property_set_shortcut_menuitem:
 * @menuitem: The #DbusmenuMenuitem to set the shortcut on
 * @gmi: A menu item to steal the shortcut off of
 * 
 * Takes the shortcut that is installed on a menu item and calls
 * #dbusmenu_menuitem_property_set_shortcut with it.  It also sets
 * up listeners to watch it change.
 * 
 * Return value: Whether it was successful at setting the property.
 */
gboolean
dbusmenu_menuitem_property_set_shortcut_menuitem (DbusmenuMenuitem * menuitem, const GtkMenuItem * gmi)
{
	g_return_val_if_fail(DBUSMENU_IS_MENUITEM(menuitem), FALSE);
	g_return_val_if_fail(GTK_IS_MENU_ITEM(gmi), FALSE);

	GClosure * closure = NULL;
        GtkWidget *label = gtk_bin_get_child(GTK_BIN (gmi));

        if (GTK_IS_ACCEL_LABEL (label))
          {
            g_object_get (label,
                          "accel-closure", &closure,
                          NULL);
          }

        if (closure == NULL) {
          /* As a fallback, check for a closure in the related menu item.  This
             actually happens with SWT menu items. */
          GList * closures = gtk_widget_list_accel_closures (GTK_WIDGET (gmi));
          if (closures == NULL)
            return FALSE;
          closure = closures->data;
          g_list_free (closures);
	}

	GtkAccelGroup * group = gtk_accel_group_from_accel_closure(closure);

	/* Apparently this is more common than I thought. */
	if (group == NULL) {
		return FALSE;
	}

	GtkAccelKey * key = gtk_accel_group_find(group, find_closure, closure);
	/* Again, not much we can do except complain loudly. */
	g_return_val_if_fail(key != NULL, FALSE);

        if (!gtk_accelerator_valid (key->accel_key, key->accel_mods))
            return FALSE;

	return dbusmenu_menuitem_property_set_shortcut(menuitem, key->accel_key, key->accel_mods);
}

/**
 * dbusmenu_menuitem_property_get_shortcut:
 * @menuitem: The #DbusmenuMenuitem to get the shortcut off
 * @key: (out): Location to put the key value
 * @modifier: (out): Location to put the modifier mask
 * 
 * This function gets a GTK shortcut as a key and a mask
 * for use to set the accelerators.
 */
void
dbusmenu_menuitem_property_get_shortcut (DbusmenuMenuitem * menuitem, guint * key, GdkModifierType * modifier)
{
	guint dummykey;
	GdkModifierType dummymodifier;

	if (key == NULL) {
		key = &dummykey;
	}

	if (modifier == NULL) {
		modifier = &dummymodifier;
	}

	*key = 0;
	*modifier = 0;

	g_return_if_fail(DBUSMENU_IS_MENUITEM(menuitem));

	GVariant * wrapper = dbusmenu_menuitem_property_get_variant(menuitem, DBUSMENU_MENUITEM_PROP_SHORTCUT);
	if (wrapper == NULL) {
		return;
	}

	if (g_variant_n_children(wrapper) != 1) {
		g_warning("Unable to parse shortcut, too many keys");
		return;
	}

	GVariantIter iter;
	GVariant * child = g_variant_get_child_value(wrapper, 0);
	g_variant_iter_init(&iter, child);
	gchar * string;

	while(g_variant_iter_loop(&iter, "s", &string)) {
		if (g_strcmp0(string, DBUSMENU_MENUITEM_SHORTCUT_CONTROL) == 0) {
			*modifier |= GDK_CONTROL_MASK;
		} else if (g_strcmp0(string, DBUSMENU_MENUITEM_SHORTCUT_ALT) == 0) {
			*modifier |= GDK_MOD1_MASK;
		} else if (g_strcmp0(string, DBUSMENU_MENUITEM_SHORTCUT_SHIFT) == 0) {
			*modifier |= GDK_SHIFT_MASK;
		} else if (g_strcmp0(string, DBUSMENU_MENUITEM_SHORTCUT_SUPER) == 0) {
			*modifier |= GDK_SUPER_MASK;
		} else {
			GdkModifierType tempmod;
			gtk_accelerator_parse(string, key, &tempmod);
		}
	}

	g_variant_unref(child);

	return;
}

