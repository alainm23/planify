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

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <gtk/gtk.h>
#include <glib.h>
#include <atk/atk.h>

#include "client.h"
#include "menuitem.h"
#include "genericmenuitem.h"
#include "genericmenuitem-enum-types.h"

/* Private */
struct _DbusmenuGtkClientPrivate {
	GStrv old_themedirs;
	GtkAccelGroup * agroup;
};

GHashTable * theme_dir_db = NULL;

#define DBUSMENU_GTKCLIENT_GET_PRIVATE(o) (DBUSMENU_GTKCLIENT(o)->priv)
#define USE_FALLBACK_PROP  "use-fallback"

/* Prototypes */
static void dbusmenu_gtkclient_class_init (DbusmenuGtkClientClass *klass);
static void dbusmenu_gtkclient_init       (DbusmenuGtkClient *self);
static void dbusmenu_gtkclient_dispose    (GObject *object);
static void dbusmenu_gtkclient_finalize   (GObject *object);
static void new_menuitem (DbusmenuClient * client, DbusmenuMenuitem * mi, gpointer userdata);
static void new_child (DbusmenuMenuitem * mi, DbusmenuMenuitem * child, guint position, DbusmenuGtkClient * gtkclient);
static void delete_child (DbusmenuMenuitem * mi, DbusmenuMenuitem * child, DbusmenuGtkClient * gtkclient);
static void move_child (DbusmenuMenuitem * mi, DbusmenuMenuitem * child, guint new, guint old, DbusmenuGtkClient * gtkclient);
static void item_activate (DbusmenuClient * client, DbusmenuMenuitem * mi, guint timestamp, gpointer userdata);
static void theme_dir_changed (DbusmenuClient * client, GStrv theme_dirs, gpointer userdata);
static void remove_theme_dirs (GtkIconTheme * theme, GStrv dirs);
static void event_result (DbusmenuClient * client, DbusmenuMenuitem * mi, const gchar * event, GVariant * variant, guint timestamp, GError * error);

static gboolean new_item_normal     (DbusmenuMenuitem * newitem, DbusmenuMenuitem * parent, DbusmenuClient * client, gpointer user_data);
static gboolean new_item_seperator  (DbusmenuMenuitem * newitem, DbusmenuMenuitem * parent, DbusmenuClient * client, gpointer user_data);

static void process_visible (DbusmenuMenuitem * mi, GtkMenuItem * gmi, GVariant * value);
static void process_sensitive (DbusmenuMenuitem * mi, GtkMenuItem * gmi, GVariant * value);
static void image_property_handle (DbusmenuMenuitem * item, const gchar * property, GVariant * invalue, gpointer userdata);

/* GObject Stuff */
G_DEFINE_TYPE (DbusmenuGtkClient, dbusmenu_gtkclient, DBUSMENU_TYPE_CLIENT);

/* Basic build for the class.  Only a finalize and dispose handler. */
static void
dbusmenu_gtkclient_class_init (DbusmenuGtkClientClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	g_type_class_add_private (klass, sizeof (DbusmenuGtkClientPrivate));

	object_class->dispose = dbusmenu_gtkclient_dispose;
	object_class->finalize = dbusmenu_gtkclient_finalize;

	return;
}

/* Registers the three times of menuitems that we're going to handle
   for the gtk world.  And tracks when a new item gets added. */
static void
dbusmenu_gtkclient_init (DbusmenuGtkClient *self)
{
	self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), DBUSMENU_GTKCLIENT_TYPE, DbusmenuGtkClientPrivate);

	DbusmenuGtkClientPrivate * priv = DBUSMENU_GTKCLIENT_GET_PRIVATE(self);

	priv->agroup = NULL;
	priv->old_themedirs = NULL;

	/* We either build the theme db or we get a reference
	   to it.  This way when all clients die the hashtable
	   will be free'd as well. */
	if (theme_dir_db == NULL) {
		theme_dir_db = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, NULL);

		/* NOTE: We're adding an extra ref here because there
		   is no way to clear the pointer when the hash table
		   dies, so it's safer to keep the hash table around
		   forever than not know if it's free'd or not.  Patch
		   submitted to GLib. */
		g_hash_table_ref(theme_dir_db);
	} else {
		g_hash_table_ref(theme_dir_db);
	}

	dbusmenu_client_add_type_handler(DBUSMENU_CLIENT(self), DBUSMENU_CLIENT_TYPES_DEFAULT,   new_item_normal);
	dbusmenu_client_add_type_handler(DBUSMENU_CLIENT(self), DBUSMENU_CLIENT_TYPES_SEPARATOR, new_item_seperator);

	/* TODO: I think these can be handled in the class... */
	g_signal_connect(G_OBJECT(self), DBUSMENU_CLIENT_SIGNAL_NEW_MENUITEM, G_CALLBACK(new_menuitem), NULL);
	g_signal_connect(G_OBJECT(self), DBUSMENU_CLIENT_SIGNAL_ITEM_ACTIVATE, G_CALLBACK(item_activate), NULL);
	g_signal_connect(G_OBJECT(self), DBUSMENU_CLIENT_SIGNAL_ICON_THEME_DIRS_CHANGED, G_CALLBACK(theme_dir_changed), NULL);
	g_signal_connect(G_OBJECT(self), DBUSMENU_CLIENT_SIGNAL_EVENT_RESULT, G_CALLBACK(event_result), NULL);

	theme_dir_changed(DBUSMENU_CLIENT(self), dbusmenu_client_get_icon_paths(DBUSMENU_CLIENT(self)), NULL);

	return;
}

static void
clear_shortcut_foreach (DbusmenuMenuitem *mi, gpointer gclient)
{
	guint key = 0;
	GtkMenuItem * gmi;
	GdkModifierType mod = 0;
	DbusmenuGtkClient * client = DBUSMENU_GTKCLIENT (gclient);

	gmi = dbusmenu_gtkclient_menuitem_get (client, mi);
	dbusmenu_gtkclient_menuitem_get (client, mi);
	dbusmenu_menuitem_property_get_shortcut (mi, &key, &mod);
	if (key)
		gtk_widget_remove_accelerator (GTK_WIDGET (gmi), client->priv->agroup, key, mod);
}

/* Just calling the super class.  Future use. */
static void
dbusmenu_gtkclient_dispose (GObject *object)
{
	DbusmenuMenuitem * root;
	DbusmenuGtkClientPrivate * priv = DBUSMENU_GTKCLIENT(object)->priv;

	if ((root = dbusmenu_client_get_root (DBUSMENU_CLIENT(object))))
		dbusmenu_menuitem_foreach (root, clear_shortcut_foreach, object);
	g_clear_object (&priv->agroup);

	if (priv->old_themedirs) {
		remove_theme_dirs(gtk_icon_theme_get_default(), priv->old_themedirs);
		g_strfreev(priv->old_themedirs);
		priv->old_themedirs = NULL;
	}

	if (theme_dir_db != NULL) {
		g_hash_table_unref(theme_dir_db);
	} else {
		g_assert_not_reached();
	}

	G_OBJECT_CLASS (dbusmenu_gtkclient_parent_class)->dispose (object);
	return;
}

/* Just calling the super class.  Future use. */
static void
dbusmenu_gtkclient_finalize (GObject *object)
{
	G_OBJECT_CLASS (dbusmenu_gtkclient_parent_class)->finalize (object);
	return;
}

/* Add a theme directory to the table and the theme's list of available
   themes to use. */
static void
theme_dir_ref (GtkIconTheme * theme, GHashTable * db, const gchar * dir)
{
	g_return_if_fail(db != NULL);
	g_return_if_fail(theme != NULL);
	g_return_if_fail(dir != NULL);

	int count = 0;
	if ((count = GPOINTER_TO_INT(g_hash_table_lookup(db, dir))) != 0) {
		/* It exists so what we need to do is increase the ref
		   count of this dir. */
		count++;
	} else {
		/* It doesn't exist, so we need to add it to the table
		   and to the search path. */
		gtk_icon_theme_append_search_path(gtk_icon_theme_get_default(), dir);
		g_debug("\tAppending search path: %s", dir);
		count = 1;
	}

	g_hash_table_insert(db, g_strdup(dir), GINT_TO_POINTER(count));

	return;
}

/* Unreference the theme directory, and if its count goes to zero then
   we need to remove it from the search path. */
static void
theme_dir_unref (GtkIconTheme * theme, GHashTable * db, const gchar * dir)
{
	g_return_if_fail(db != NULL);
	g_return_if_fail(theme != NULL);
	g_return_if_fail(dir != NULL);

	/* Grab the count for this dir */
	int count = GPOINTER_TO_INT(g_hash_table_lookup(db, dir));

	/* Is this a simple deprecation, if so, we can just lower the
	   number and move on. */
	if (count > 1) {
		count--;
		g_hash_table_insert(db, g_strdup(dir), GINT_TO_POINTER(count));
		return;
	}

	/* Try to remove it from the hash table, this makes sure
	   that it existed */
	if (!g_hash_table_remove(db, dir)) {
		g_warning("Unref'd a directory that wasn't in the theme dir hash table.");
		return;
	}

	gchar ** paths;
	gint path_count;

	gtk_icon_theme_get_search_path(theme, &paths, &path_count);

	gint i;
	gboolean found = FALSE;
	for (i = 0; i < path_count; i++) {
		if (found) {
			/* If we've already found the right entry */
			paths[i - 1] = paths[i];
		} else {
			/* We're still looking, is this the one? */
			if (!g_strcmp0(paths[i], dir)) {
				found = TRUE;
				/* We're freeing this here as it won't be captured by the
				   g_strfreev() below as it's out of the array. */
				g_free(paths[i]);
			}
		}
	}
	
	/* If we found one we need to reset the path to
	   accomidate the changes */
	if (found) {
		paths[path_count - 1] = NULL; /* Clear the last one */
		gtk_icon_theme_set_search_path(theme, (const gchar **)paths, path_count - 1);
	}

	g_strfreev(paths);

	return;
}

/* Unregister this list of theme directories */
static void
remove_theme_dirs (GtkIconTheme * theme, GStrv dirs)
{
	g_return_if_fail(GTK_ICON_THEME(theme));
	g_return_if_fail(dirs != NULL);

	int dir;

	for (dir = 0; dirs[dir] != NULL; dir++) {
		theme_dir_unref(theme, theme_dir_db, dirs[dir]);
	}

	return;
}

/* Called when the theme directories are changed by the
   server part of things. */
static void
theme_dir_changed (DbusmenuClient * client, GStrv theme_dirs, gpointer userdata)
{
	DbusmenuGtkClientPrivate * priv = DBUSMENU_GTKCLIENT_GET_PRIVATE(client);
	GtkIconTheme * theme = gtk_icon_theme_get_default();

	/* Ref the new directories */
	if (theme_dirs != NULL) {
		int dir;
		for (dir = 0; theme_dirs[dir] != NULL; dir++) {
			theme_dir_ref(theme, theme_dir_db, theme_dirs[dir]);
		}
	}

	/* Unref the old ones */
	if (priv->old_themedirs) {
		remove_theme_dirs(theme, priv->old_themedirs);
		g_strfreev(priv->old_themedirs);
		priv->old_themedirs = NULL;
	}

	/* Copy the new to the old */
	if (theme_dirs != NULL) {
		priv->old_themedirs = g_strdupv(theme_dirs);
	}

	return;
}

/* Structure for passing data to swap_agroup */
typedef struct _swap_agroup_t swap_agroup_t;
struct _swap_agroup_t {
	DbusmenuGtkClient * client;
	GtkAccelGroup * old_agroup;
	GtkAccelGroup * new_agroup;
};

/* Looks at the old version of the accelerator group and
   the new one and makes the state proper. */
static gboolean
do_swap_agroup (DbusmenuMenuitem * mi, gpointer userdata) {
        swap_agroup_t * data = (swap_agroup_t *)userdata;

	/* If we don't have a shortcut we don't care */
	if (!dbusmenu_menuitem_property_exist(mi, DBUSMENU_MENUITEM_PROP_SHORTCUT)) {
		return FALSE;
	}

	guint key = 0;
	GdkModifierType modifiers = 0;

	dbusmenu_menuitem_property_get_shortcut(mi, &key, &modifiers);

	if (key == 0) {
		return FALSE;
	}

	#ifdef MASSIVEDEBUGGING
	g_debug("Setting shortcut on '%s': %d %X", dbusmenu_menuitem_property_get(mi, DBUSMENU_MENUITEM_PROP_LABEL), key, modifiers);
	#endif

	GtkMenuItem * gmi = dbusmenu_gtkclient_menuitem_get(data->client, mi);
	if (gmi == NULL) {
		return FALSE;
	}

	const gchar * accel_path = gtk_menu_item_get_accel_path(gmi);

	if (accel_path != NULL) {
		gtk_accel_map_change_entry(accel_path, key, modifiers, TRUE /* replace */);
	} else {
		gchar * accel_path = g_strdup_printf("<Appmenus>/Generated/%X/%d", GPOINTER_TO_UINT(data->client), dbusmenu_menuitem_get_id(mi));

		gtk_accel_map_add_entry(accel_path, key, modifiers);
		gtk_widget_set_accel_path(GTK_WIDGET(gmi), accel_path, data->new_agroup);
		g_free(accel_path);
	}

	GtkMenu * submenu = dbusmenu_gtkclient_menuitem_get_submenu(data->client, mi);
	if (submenu != NULL) {
		gtk_menu_set_accel_group(submenu, data->new_agroup);
	}

	return TRUE;
}

static void
swap_agroup (DbusmenuMenuitem *mi, gpointer userdata) {
        do_swap_agroup (mi, userdata);
}

/* Refresh the shortcut for an entry */
static void
refresh_shortcut (DbusmenuGtkClient * client, DbusmenuMenuitem * mi)
{
	g_return_if_fail(DBUSMENU_IS_GTKCLIENT(client));
	g_return_if_fail(DBUSMENU_IS_MENUITEM(mi));

	DbusmenuGtkClientPrivate * priv = DBUSMENU_GTKCLIENT_GET_PRIVATE(client);

	swap_agroup_t data;
	data.client = client;
	data.old_agroup = priv->agroup;
	data.new_agroup = priv->agroup;

	if (do_swap_agroup(mi, &data)) {
		guint key = 0;
		GdkModifierType mod = 0;
		GtkMenuItem *gmi = dbusmenu_gtkclient_menuitem_get (client, mi);

		dbusmenu_menuitem_property_get_shortcut (mi, &key, &mod);

		if (key != 0) {
			gtk_widget_add_accelerator (GTK_WIDGET (gmi), "activate", priv->agroup, key, mod, GTK_ACCEL_VISIBLE);
		}
	}

	return;
}


/**
 * dbusmenu_gtkclient_set_accel_group:
 * @client: To set the group on
 * @agroup: The new acceleration group
 * 
 * Sets the acceleration group for the menu items with accelerators
 * on this client.
 */
void
dbusmenu_gtkclient_set_accel_group (DbusmenuGtkClient * client, GtkAccelGroup * agroup)
{
	g_return_if_fail(DBUSMENU_IS_GTKCLIENT(client));
	g_return_if_fail(GTK_IS_ACCEL_GROUP(agroup));

	DbusmenuGtkClientPrivate * priv = DBUSMENU_GTKCLIENT_GET_PRIVATE(client);

	DbusmenuMenuitem * root = dbusmenu_client_get_root(DBUSMENU_CLIENT(client));
	if (root != NULL) {
		swap_agroup_t data;
		data.client = client;
		data.old_agroup = priv->agroup;
		data.new_agroup = agroup;

		dbusmenu_menuitem_foreach(root, swap_agroup, &data);
	}

	if (priv->agroup != NULL) {
		g_object_unref(priv->agroup);
		priv->agroup = NULL;
	}

	priv->agroup = agroup;
	g_object_ref(priv->agroup);

	return;
}

/**
 * dbusmenu_gtkclient_get_accel_group:
 * @client: Client to query for an accelerator group
 * 
 * Gets the accel group for this client.
 * 
 * Return value: (transfer none): Either a valid group or #NULL on error or
 * 	none set.
 */
GtkAccelGroup *
dbusmenu_gtkclient_get_accel_group (DbusmenuGtkClient * client)
{
	g_return_val_if_fail(DBUSMENU_IS_GTKCLIENT(client), NULL);

	DbusmenuGtkClientPrivate * priv = DBUSMENU_GTKCLIENT_GET_PRIVATE(client);

	return priv->agroup;
}

/* Internal Functions */

static const gchar * data_menuitem =      "dbusmenugtk-data-gtkmenuitem";
static const gchar * data_menu =          "dbusmenugtk-data-gtkmenu";
static const gchar * data_activating =    "dbusmenugtk-data-activating";
static const gchar * data_idle_close_id = "dbusmenugtk-data-idle-close-id";
static const gchar * data_delayed_close = "dbusmenugtk-data-delayed-close";

static void
menu_item_start_activating(DbusmenuMenuitem * mi)
{
	/* Mark this item and all its parents as activating */
	DbusmenuMenuitem * parent = mi;
	do {
		g_object_set_data(G_OBJECT(parent), data_activating,
		                  GINT_TO_POINTER(TRUE));
	} while ((parent = dbusmenu_menuitem_get_parent (parent)) != NULL);

	GVariant * variant = g_variant_new("i", 0);
	dbusmenu_menuitem_handle_event(mi, DBUSMENU_MENUITEM_EVENT_ACTIVATED, variant, gtk_get_current_event_time());
}

static gboolean
menu_item_is_activating(DbusmenuMenuitem * mi)
{
	return GPOINTER_TO_INT(g_object_get_data(G_OBJECT(mi), data_activating));
}

static void
menu_item_stop_activating(DbusmenuMenuitem * mi)
{
	if (!menu_item_is_activating(mi))
		return;

	/* Mark this item and all its parents as not activating and finally
	   send their queued close event. */
	g_object_set_data(G_OBJECT(mi), data_activating, GINT_TO_POINTER(FALSE));

	/* There is one master root parent that we don't care about, so stop
	   right before it */
	DbusmenuMenuitem * parent = dbusmenu_menuitem_get_parent (mi);
	while (dbusmenu_menuitem_get_parent (parent) != NULL &&
	       menu_item_is_activating(parent)) {
		/* Now clean up the activating flag */
		g_object_set_data(G_OBJECT(parent), data_activating,
		                  GINT_TO_POINTER(FALSE));

		gboolean should_close = FALSE;

		/* Note that dbus might be fast enough to have already
		   processed the app's reply before close_in_idle() is called.
		   So to avoid that, we shut down any pending close_in_idle call */
		guint id = GPOINTER_TO_INT(g_object_get_data(G_OBJECT(parent),
		                           data_idle_close_id));
		if (id > 0) {
			g_object_set_data(G_OBJECT(parent), data_idle_close_id,
			                  GINT_TO_POINTER(0));
			should_close = TRUE;
		}

		gboolean delayed = GPOINTER_TO_INT(g_object_get_data(G_OBJECT(mi),
		                                                     data_delayed_close));
		if (delayed) {
			g_object_set_data(G_OBJECT(mi), data_delayed_close,
			                  GINT_TO_POINTER(FALSE));
			should_close = TRUE;
		}

		/* And finally send a delayed closed event if one would have
		   happened */
		if (should_close) {
			dbusmenu_menuitem_handle_event(parent,
			                               DBUSMENU_MENUITEM_EVENT_CLOSED,
			                               NULL,
			                               gtk_get_current_event_time());
		}

		parent = dbusmenu_menuitem_get_parent (parent);
	}
}

static void
event_result (DbusmenuClient * client, DbusmenuMenuitem * mi,
              const gchar * event, GVariant * variant, guint timestamp,
              GError * error)
{
	if (g_strcmp0(event, DBUSMENU_MENUITEM_EVENT_ACTIVATED) == 0) {
		menu_item_stop_activating(mi);
	}

	return;
}

/* This is the call back for the GTK widget for when it gets
   clicked on by the user to send it back across the bus. */
static gboolean
menu_pressed_cb (GtkMenuItem * gmi, DbusmenuMenuitem * mi)
{
	if (gtk_menu_item_get_submenu(gmi) == NULL) {
		menu_item_start_activating(mi);
	} else {
		/* TODO: We need to stop the display of the submenu
		         until this callback returns. */
		dbusmenu_menuitem_send_about_to_show(mi, NULL, NULL);
	}
	return TRUE;
}

static gboolean
close_in_idle (DbusmenuMenuitem * mi)
{
	/* Don't send closed signal if we also sent activating signal.
	   We'd just be asking for race conditions.  We'll send closed
	   when done with activation. */
	if (!menu_item_is_activating(mi))
		dbusmenu_menuitem_handle_event(mi, DBUSMENU_MENUITEM_EVENT_CLOSED, NULL, gtk_get_current_event_time());
	else
		g_object_set_data(G_OBJECT(mi), data_delayed_close, GINT_TO_POINTER(TRUE));

	g_object_set_data(G_OBJECT(mi), data_idle_close_id, GINT_TO_POINTER(0));
	return FALSE;
}

static void
cancel_idle_close_id (gpointer data)
{
  guint id = GPOINTER_TO_INT(data);
  if (id > 0)
  	g_source_remove(id);
}

static void
submenu_notify_visible_cb (GtkWidget * menu, GParamSpec * pspec, DbusmenuMenuitem * mi)
{
	if (gtk_widget_get_visible (menu)) {
		menu_item_stop_activating(mi); /* just in case */
		dbusmenu_menuitem_handle_event(mi, DBUSMENU_MENUITEM_EVENT_OPENED, NULL, gtk_get_current_event_time());
	} else {
		/* Try to close in the idle loop because we actually get a menu
		   close notification before we get notified that a menu item
		   was clicked.  We want to give that clicked signal some
		   time, so we wait until all queued signals are handled before
		   continuing.  (our handling of the closed signal depends on
		   whether the user clicked an item or not) */
		guint id = GPOINTER_TO_INT(g_object_get_data(G_OBJECT(mi),
		                           data_idle_close_id));
		if (id == 0) {
			id = g_idle_add((GSourceFunc)close_in_idle, mi);
			g_object_set_data_full(G_OBJECT(mi), data_idle_close_id,
			                       GINT_TO_POINTER(id), cancel_idle_close_id);
		}
	}
}

/* Process the visible property */
static void
process_visible (DbusmenuMenuitem * mi, GtkMenuItem * gmi, GVariant * value)
{
	gboolean val = TRUE;
	if (value != NULL) {
		val = dbusmenu_menuitem_property_get_bool(mi, DBUSMENU_MENUITEM_PROP_VISIBLE);
	}

	if (val) {
		gtk_widget_show(GTK_WIDGET(gmi));
	} else {
		gtk_widget_hide(GTK_WIDGET(gmi));
	}
	return;
}

/* Process the sensitive property */
static void
process_sensitive (DbusmenuMenuitem * mi, GtkMenuItem * gmi, GVariant * value)
{
	gboolean val = TRUE;
	if (value != NULL) {
		val = dbusmenu_menuitem_property_get_bool(mi, DBUSMENU_MENUITEM_PROP_ENABLED);
	}
	gtk_widget_set_sensitive(GTK_WIDGET(gmi), val);
	return;
}

/* Process the sensitive property */
static void
process_toggle_type (DbusmenuMenuitem * mi, GtkMenuItem * gmi, GVariant * variant)
{
	if (!IS_GENERICMENUITEM(gmi)) return;
	if (variant == NULL) return;

	GenericmenuitemCheckType type = GENERICMENUITEM_CHECK_TYPE_NONE;

	if (variant != NULL) {
		const gchar * strval = g_variant_get_string(variant, NULL);

		if (!g_strcmp0(strval, DBUSMENU_MENUITEM_TOGGLE_CHECK)) {
			type = GENERICMENUITEM_CHECK_TYPE_CHECKBOX;
		} else if (!g_strcmp0(strval, DBUSMENU_MENUITEM_TOGGLE_RADIO)) {
			type = GENERICMENUITEM_CHECK_TYPE_RADIO;
		}
	}

	genericmenuitem_set_check_type(GENERICMENUITEM(gmi), type);
	
	return;
}

/* Process the sensitive property */
static void
process_toggle_state (DbusmenuMenuitem * mi, GtkMenuItem * gmi, GVariant * variant)
{
	if (!IS_GENERICMENUITEM(gmi)) return;

	GenericmenuitemState state = GENERICMENUITEM_STATE_UNCHECKED;

	if (variant != NULL) {
		int val = g_variant_get_int32(variant);

		if (val == DBUSMENU_MENUITEM_TOGGLE_STATE_CHECKED) {
			state = GENERICMENUITEM_STATE_CHECKED;
		} else if (val == DBUSMENU_MENUITEM_TOGGLE_STATE_UNKNOWN) {
			state = GENERICMENUITEM_STATE_INDETERMINATE;
		}
	}

	genericmenuitem_set_state(GENERICMENUITEM(gmi), state);
	return;
}

/* Submenu processing */
static void
process_submenu (DbusmenuMenuitem * mi, GtkMenuItem * gmi, GVariant * variant, DbusmenuGtkClient * gtkclient)
{
	const gchar * submenu = NULL;
	if (variant != NULL) {
		submenu = g_variant_get_string(variant, NULL);
	}

	if (g_strcmp0(submenu, DBUSMENU_MENUITEM_CHILD_DISPLAY_SUBMENU) != 0) {
		/* This is the only case we're really supporting right now,
		   so if it's not this, we want to clean up. */
		/* We're just going to warn for now. */
		gpointer pmenu = g_object_get_data(G_OBJECT(mi), data_menu);
		if (pmenu != NULL) {
			g_warning("The child-display variable is set to '%s' but there's a menu, odd?", submenu);
		}
	} else {
		/* We need to build a menu for these guys to live in. */
		GtkMenu * menu = GTK_MENU(gtk_menu_new());
		g_object_ref_sink(menu);
		g_object_set_data_full(G_OBJECT(mi), data_menu, menu, g_object_unref);

		gtk_menu_item_set_submenu(gmi, GTK_WIDGET(menu));

		g_signal_connect(menu, "notify::visible", G_CALLBACK(submenu_notify_visible_cb), mi);
	}

	return;
}

/* Process the disposition changing */
static void
process_disposition (DbusmenuMenuitem * mi, GtkMenuItem * gmi, GVariant * variant, DbusmenuGtkClient * gtkclient)
{
	/* We can only handle generic menu items here. Perhaps someone else
	   will find the value useful.  Not us. */
	if (!IS_GENERICMENUITEM(gmi)) {
		return;
	}

	genericmenuitem_set_disposition(GENERICMENUITEM(gmi), genericmenuitem_disposition_get_value_from_nick(g_variant_get_string(variant, NULL)));
	return;
}

/* Process the accessible description */
static void
process_a11y_desc (DbusmenuMenuitem * mi, GtkMenuItem * gmi, GVariant * variant, DbusmenuGtkClient * gtkclient)
{
	AtkObject * aobj = gtk_widget_get_accessible(GTK_WIDGET(gmi));

	if (aobj == NULL) {
		return;
	}


	if (variant != NULL) {
		const gchar * setname = NULL;
		setname = g_variant_get_string(variant, NULL);
		atk_object_set_name(aobj, setname);
	} else {
	/* The atk docs advise to set the name of the atk object to an empty
	 * string, but GTK doesn't yet do the same, and setting the name to NULL
	 * causes tests to fail.
	 */
		const gchar * label = NULL;
		label = dbusmenu_menuitem_property_get(mi, DBUSMENU_MENUITEM_PROP_LABEL);

		if (label != NULL) {
			gchar * setname = NULL;

			/* We don't want the underscore for mnewmonics */
			GRegex * regex = g_regex_new ("_", 0, 0, NULL);
			setname = g_regex_replace_literal (regex, label, -1, 0, "", 0, NULL);
			g_regex_unref(regex);

			atk_object_set_name(aobj, setname);
			g_free(setname);
		}
	}

	return;
}

/* Whenever we have a property change on a DbusmenuMenuitem
   we need to be responsive to that. */
static void
menu_prop_change_cb (DbusmenuMenuitem * mi, gchar * prop, GVariant * variant, DbusmenuGtkClient * gtkclient)
{
	GtkMenuItem * gmi = dbusmenu_gtkclient_menuitem_get(gtkclient, mi);

	if (!g_strcmp0(prop, DBUSMENU_MENUITEM_PROP_LABEL)) {
		gtk_menu_item_set_label(gmi, variant == NULL ? NULL : g_variant_get_string(variant, NULL));
	} else if (!g_strcmp0(prop, DBUSMENU_MENUITEM_PROP_VISIBLE)) {
		process_visible(mi, gmi, variant);
	} else if (!g_strcmp0(prop, DBUSMENU_MENUITEM_PROP_ENABLED)) {
		process_sensitive(mi, gmi, variant);
	} else if (!g_strcmp0(prop, DBUSMENU_MENUITEM_PROP_TOGGLE_TYPE)) {
		process_toggle_type(mi, gmi, variant);
	} else if (!g_strcmp0(prop, DBUSMENU_MENUITEM_PROP_TOGGLE_STATE)) {
		process_toggle_state(mi, gmi, variant);
	} else if (!g_strcmp0(prop, DBUSMENU_MENUITEM_PROP_CHILD_DISPLAY)) {
		process_submenu(mi, gmi, variant, gtkclient);
	} else if (!g_strcmp0(prop, DBUSMENU_MENUITEM_PROP_DISPOSITION)) {
		process_disposition(mi, gmi, variant, gtkclient);
	} else if (!g_strcmp0(prop, DBUSMENU_MENUITEM_PROP_ACCESSIBLE_DESC)) {
		process_a11y_desc(mi, gmi, variant, gtkclient);
	} else if (!g_strcmp0(prop, DBUSMENU_MENUITEM_PROP_SHORTCUT)) {
		refresh_shortcut(gtkclient, mi);
	}

	return;
}

/* The new menuitem signal only happens if we don't have a type handler
   for the type of the item.  This should be an error condition and we're
   printing out a message. */
static void
new_menuitem (DbusmenuClient * client, DbusmenuMenuitem * mi, gpointer userdata)
{
	g_warning("Got new menuitem signal, which means they want something");
	g_warning("  that I simply don't have.");

	return;
}

/* Goes through the tree of items and ensure's that all the items
   above us are also displayed. */
static void
activate_helper (GtkMenuShell * shell)
{
	if (shell == NULL) {
		return;
	}

	if (GTK_IS_MENU(shell)) {
		GtkWidget * attach = gtk_menu_get_attach_widget(GTK_MENU(shell));

		if (attach != NULL) {
			GtkWidget * parent = gtk_widget_get_parent(GTK_WIDGET(attach));

			if (parent != NULL) {
				if (GTK_IS_MENU(parent)) {
					activate_helper(GTK_MENU_SHELL(parent));
				}

				/* This code is being commented out for GTK 3 because it
				   doesn't expose the right variables.  We need to figure
				   this out as menus won't get grabs properly.
				   TODO FIXME HELP ARGHHHHHHHH */
#if !GTK_CHECK_VERSION(3,0,0)
				if (!GTK_MENU_SHELL (parent)->active) {
					gtk_grab_add (parent);
					GTK_MENU_SHELL (parent)->have_grab = TRUE;
					GTK_MENU_SHELL (parent)->active = TRUE;
				}
#endif

				gtk_menu_shell_select_item(GTK_MENU_SHELL(parent), attach);
			}
		}
	}

	return;
}

/* Signaled when we should show a menuitem at request of the application
   that it is in. */
static void
item_activate (DbusmenuClient * client, DbusmenuMenuitem * mi, guint timestamp, gpointer userdata)
{
	gpointer pmenu = g_object_get_data(G_OBJECT(mi), data_menu);
	if (pmenu == NULL) {
		g_warning("Activated menu item doesn't have a menu?  ID: %d", dbusmenu_menuitem_get_id(mi));
		return;
	}

	activate_helper(GTK_MENU_SHELL(pmenu));
	gtk_menu_shell_select_first(GTK_MENU_SHELL(pmenu), FALSE);

	return;
}

static void
destroy_gmi (GtkMenuItem * gmi)
{
#ifdef MASSIVEDEBUGGING
	g_debug("Destroying GTK Menuitem %d", gmi);
#endif

	/* Call gtk_widget_destroy to remove from any containers and cleanup */
	gtk_widget_destroy(GTK_WIDGET(gmi));

	/* Now remove last ref that we are holding (due to g_object_ref_sink in
	   dbusmenu_gtkclient_newitem_base).  This should finalize the object */
	g_object_unref(G_OBJECT(gmi));

	return;
}

/**
 * dbusmenu_gtkclient_newitem_base:
 * @client: The client handling everything on this connection
 * @item: The #DbusmenuMenuitem to attach the GTK-isms to
 * @gmi: A #GtkMenuItem representing the GTK world's view of this menuitem
 * @parent: The parent #DbusmenuMenuitem
 * 
 * This function provides some of the basic connectivity for being in
 * the GTK world.  Things like visibility and sensitivity of the item are
 * handled here so that the subclasses don't have to.  If you're building
 * your on GTK menu item you can use this function to apply those basic
 * attributes so that you don't have to deal with them either.
 * 
 * This also handles passing the "activate" signal back to the
 * #DbusmenuMenuitem side of thing.
 */
void
dbusmenu_gtkclient_newitem_base (DbusmenuGtkClient * client, DbusmenuMenuitem * item, GtkMenuItem * gmi, DbusmenuMenuitem * parent)
{
	#ifdef MASSIVEDEBUGGING
	g_debug("GTK Client new item base for %d", dbusmenu_menuitem_get_id(item));
	#endif

	/* Attach these two */
	g_object_ref_sink(G_OBJECT(gmi));
	g_object_set_data_full(G_OBJECT(item), data_menuitem, gmi, (GDestroyNotify)destroy_gmi);

	/* DbusmenuMenuitem signals */
	g_signal_connect(G_OBJECT(item), DBUSMENU_MENUITEM_SIGNAL_PROPERTY_CHANGED, G_CALLBACK(menu_prop_change_cb), client);
	g_signal_connect(G_OBJECT(item), DBUSMENU_MENUITEM_SIGNAL_CHILD_REMOVED, G_CALLBACK(delete_child), client);
	g_signal_connect(G_OBJECT(item), DBUSMENU_MENUITEM_SIGNAL_CHILD_MOVED,   G_CALLBACK(move_child),   client);

	/* GtkMenuitem signals */
	g_signal_connect(G_OBJECT(gmi), "activate", G_CALLBACK(menu_pressed_cb), item);

	/* Check our set of props to see if any are set already */
	process_visible(item, gmi, dbusmenu_menuitem_property_get_variant(item, DBUSMENU_MENUITEM_PROP_VISIBLE));
	process_sensitive(item, gmi, dbusmenu_menuitem_property_get_variant(item, DBUSMENU_MENUITEM_PROP_ENABLED));
	process_toggle_type(item, gmi, dbusmenu_menuitem_property_get_variant(item, DBUSMENU_MENUITEM_PROP_TOGGLE_TYPE));
	process_toggle_state(item, gmi, dbusmenu_menuitem_property_get_variant(item, DBUSMENU_MENUITEM_PROP_TOGGLE_STATE));
	process_submenu(item, gmi, dbusmenu_menuitem_property_get_variant(item, DBUSMENU_MENUITEM_PROP_CHILD_DISPLAY), client);
	process_disposition(item, gmi, dbusmenu_menuitem_property_get_variant(item, DBUSMENU_MENUITEM_PROP_DISPOSITION), client);
	process_a11y_desc(item, gmi, dbusmenu_menuitem_property_get_variant(item, DBUSMENU_MENUITEM_PROP_ACCESSIBLE_DESC), client);
	refresh_shortcut(client, item);

	const gchar * a11y_desc = dbusmenu_menuitem_property_get(item, DBUSMENU_MENUITEM_PROP_ACCESSIBLE_DESC);
	if (a11y_desc != NULL) {
		atk_object_set_name(gtk_widget_get_accessible(GTK_WIDGET(gmi)), a11y_desc);
	}

	/* Oh, we're a child, let's deal with that */
	if (parent != NULL) {
		new_child(parent, item, dbusmenu_menuitem_get_position(item, parent), DBUSMENU_GTKCLIENT(client));
	}

	return;
}

static void
new_child (DbusmenuMenuitem * mi, DbusmenuMenuitem * child, guint position, DbusmenuGtkClient * gtkclient)
{
	#ifdef MASSIVEDEBUGGING
	g_debug("GTK Client new child for %d on %d at %d", dbusmenu_menuitem_get_id(mi), dbusmenu_menuitem_get_id(child), position);
	#endif

	if (dbusmenu_menuitem_get_root(mi)) { return; }
	if (g_strcmp0(dbusmenu_menuitem_property_get(mi, DBUSMENU_MENUITEM_PROP_TYPE), DBUSMENU_CLIENT_TYPES_SEPARATOR) == 0) { return; }

	gpointer ann_menu = g_object_get_data(G_OBJECT(mi), data_menu);
	if (ann_menu == NULL) {
		g_warning("Children but no menu, someone's been naughty with their '" DBUSMENU_MENUITEM_PROP_CHILD_DISPLAY "' property: '%s'", dbusmenu_menuitem_property_get(mi, DBUSMENU_MENUITEM_PROP_CHILD_DISPLAY));
		return;
	}

	GtkMenu * menu = GTK_MENU(ann_menu);

	GtkMenuItem * childmi  = dbusmenu_gtkclient_menuitem_get(gtkclient, child);
	gtk_menu_shell_insert(GTK_MENU_SHELL(menu), GTK_WIDGET(childmi), position);
	
	return;
}

static void
delete_child (DbusmenuMenuitem * mi, DbusmenuMenuitem * child, DbusmenuGtkClient * gtkclient)
{
	/* If it's a root item, we shouldn't be dealing with it here. */
	if (dbusmenu_menuitem_get_root(mi)) { return; }

	if (g_list_length(dbusmenu_menuitem_get_children(mi)) == 0) {
		gpointer ann_menu = g_object_get_data(G_OBJECT(mi), data_menu);
		GtkMenu * menu = GTK_MENU(ann_menu);

		if (menu != NULL) {
			gtk_widget_destroy(GTK_WIDGET(menu));
			g_object_steal_data(G_OBJECT(mi), data_menu);
		}
	}

	return;
}

static void
move_child (DbusmenuMenuitem * mi, DbusmenuMenuitem * child, guint new, guint old, DbusmenuGtkClient * gtkclient)
{
	/* If it's a root item, we shouldn't be dealing with it here. */
	if (dbusmenu_menuitem_get_root(mi)) { return; }

	gpointer ann_menu = g_object_get_data(G_OBJECT(mi), data_menu);
	if (ann_menu == NULL) {
		g_warning("Moving a child when we don't have a submenu!");
		return;
	}

	GtkMenuItem * childmi  = dbusmenu_gtkclient_menuitem_get(gtkclient, child);
	gtk_menu_reorder_child(GTK_MENU(ann_menu), GTK_WIDGET(childmi), dbusmenu_menuitem_get_position_realized(child, mi));

	return;
}

/* Public API */

/**
 * dbusmenu_gtkclient_new:
 * @dbus_name: Name of the #DbusmenuServer on DBus
 * @dbus_object: Name of the object on the #DbusmenuServer
 * 
 * Creates a new #DbusmenuGtkClient object and creates a #DbusmenuClient
 * that connects across DBus to a #DbusmenuServer.
 * 
 * Return value: A new #DbusmenuGtkClient sync'd with a server
 */
DbusmenuGtkClient *
dbusmenu_gtkclient_new (gchar * dbus_name, gchar * dbus_object)
{
	return g_object_new(DBUSMENU_GTKCLIENT_TYPE,
	                    DBUSMENU_CLIENT_PROP_DBUS_OBJECT, dbus_object,
	                    DBUSMENU_CLIENT_PROP_DBUS_NAME, dbus_name,
	                    NULL);
}

/**
 * dbusmenu_gtkclient_menuitem_get:
 * @client: A #DbusmenuGtkClient with the item in it.
 * @item: #DbusmenuMenuitem to get associated #GtkMenuItem on.
 * 
 * This grabs the #GtkMenuItem that is associated with the
 * #DbusmenuMenuitem.
 * 
 * Return value: (transfer none): The #GtkMenuItem that can be played with.
 */
GtkMenuItem *
dbusmenu_gtkclient_menuitem_get (DbusmenuGtkClient * client, DbusmenuMenuitem * item)
{
	g_return_val_if_fail(DBUSMENU_IS_GTKCLIENT(client), NULL);
	g_return_val_if_fail(DBUSMENU_IS_MENUITEM(item), NULL);

	gpointer data = g_object_get_data(G_OBJECT(item), data_menuitem);
	if (data == NULL) {
		return NULL;
	}

	return GTK_MENU_ITEM(data);
}

/**
 * dbusmenu_gtkclient_menuitem_get_submenu:
 * @client: A #DbusmenuGtkClient with the item in it.
 * @item: #DbusmenuMenuitem to get associated #GtkMenu on.
 * 
 * This grabs the submenu associated with the menuitem.
 * 
 * Return value: (transfer none): The #GtkMenu if there is one.
*/
GtkMenu *
dbusmenu_gtkclient_menuitem_get_submenu (DbusmenuGtkClient * client, DbusmenuMenuitem * item)
{
	g_return_val_if_fail(DBUSMENU_IS_GTKCLIENT(client), NULL);
	g_return_val_if_fail(DBUSMENU_IS_MENUITEM(item), NULL);

	gpointer data = g_object_get_data(G_OBJECT(item), data_menu);
	if (data == NULL) {
		return NULL;
	}

	return GTK_MENU(data);
}

/* The base type handler that builds a plain ol'
   GtkMenuItem to represent, well, the GtkMenuItem */
static gboolean
new_item_normal (DbusmenuMenuitem * newitem, DbusmenuMenuitem * parent, DbusmenuClient * client, gpointer user_data)
{
	g_return_val_if_fail(DBUSMENU_IS_MENUITEM(newitem), FALSE);
	g_return_val_if_fail(DBUSMENU_IS_GTKCLIENT(client), FALSE);
	/* Note: not checking parent, it's reasonable for it to be NULL */

	GtkMenuItem * gmi;
	gmi = GTK_MENU_ITEM(g_object_new(GENERICMENUITEM_TYPE, NULL));

	if (gmi != NULL) {
		gtk_menu_item_set_label(gmi, dbusmenu_menuitem_property_get(newitem, DBUSMENU_MENUITEM_PROP_LABEL));
		dbusmenu_gtkclient_newitem_base(DBUSMENU_GTKCLIENT(client), newitem, gmi, parent);
	} else {
		return FALSE;
	}

	image_property_handle(newitem,
	                      DBUSMENU_MENUITEM_PROP_ICON_NAME,
	                      dbusmenu_menuitem_property_get_variant(newitem, DBUSMENU_MENUITEM_PROP_ICON_NAME),
	                      client);
	image_property_handle(newitem,
	                      DBUSMENU_MENUITEM_PROP_ICON_DATA,
	                      dbusmenu_menuitem_property_get_variant(newitem, DBUSMENU_MENUITEM_PROP_ICON_DATA),
	                      client);
	g_signal_connect(G_OBJECT(newitem),
	                 DBUSMENU_MENUITEM_SIGNAL_PROPERTY_CHANGED,
	                 G_CALLBACK(image_property_handle),
	                 client);

	return TRUE;
}

/* Type handler for the seperators where it builds
   a GtkSeparator to act as the GtkMenuItem */
static gboolean
new_item_seperator (DbusmenuMenuitem * newitem, DbusmenuMenuitem * parent, DbusmenuClient * client, gpointer user_data)
{
	g_return_val_if_fail(DBUSMENU_IS_MENUITEM(newitem), FALSE);
	g_return_val_if_fail(DBUSMENU_IS_GTKCLIENT(client), FALSE);
	/* Note: not checking parent, it's reasonable for it to be NULL */

	GtkMenuItem * gmi;
	gmi = GTK_MENU_ITEM(gtk_separator_menu_item_new());

	if (gmi != NULL) {
		dbusmenu_gtkclient_newitem_base(DBUSMENU_GTKCLIENT(client), newitem, gmi, parent);
	} else {
		return FALSE;
	}

	return TRUE;
}

/* A little helper so we don't generate a bunch of warnings
   about being able to set use-fallback */
static void
set_use_fallback (GtkWidget * widget)
{
	static gboolean checked = FALSE;
	static gboolean available = FALSE;

	if (!checked) {
		available = (g_object_class_find_property(G_OBJECT_CLASS(GTK_IMAGE_GET_CLASS(widget)), USE_FALLBACK_PROP) != NULL);
		if (!available) {
			g_warning("The '" USE_FALLBACK_PROP "' is not available on GtkImage so icons may not show correctly.");
		}
		checked = TRUE;
	}

	if (available) {
		g_object_set(G_OBJECT(widget), USE_FALLBACK_PROP, TRUE, NULL);
	}

	return;
}

/* This handler looks at property changes for items that are
   image menu items. */
static void
image_property_handle (DbusmenuMenuitem * item, const gchar * property, GVariant * variant, gpointer userdata)
{
	/* We're only looking at these two properties here */
	if (g_strcmp0(property, DBUSMENU_MENUITEM_PROP_ICON_NAME) != 0 &&
			g_strcmp0(property, DBUSMENU_MENUITEM_PROP_ICON_DATA) != 0) {
		return;
	}

	if (variant == NULL) {
		/* This means that we're unsetting a value. */
		/* Try to use the other one */
		if (g_strcmp0(property, DBUSMENU_MENUITEM_PROP_ICON_NAME)) {
			property = DBUSMENU_MENUITEM_PROP_ICON_DATA;
		} else {
			property = DBUSMENU_MENUITEM_PROP_ICON_NAME;
		}
	}

	/* Grab the data of the items that we've got, so that
	   we can know how things need to change. */
	GtkMenuItem * gimi = dbusmenu_gtkclient_menuitem_get (DBUSMENU_GTKCLIENT(userdata), item);
	if (gimi == NULL) {
		g_warning("Oddly we're handling image properties on a menuitem that doesn't have any GTK structures associated with it.");
		return;
	}
	GtkWidget * gtkimage = genericmenuitem_get_image(GENERICMENUITEM(gimi));

	if (!g_strcmp0(property, DBUSMENU_MENUITEM_PROP_ICON_DATA)) {
		/* If we have an image already built from a name that is
		   way better than a pixbuf.  Keep it. */
		if (gtkimage != NULL && (gtk_image_get_storage_type(GTK_IMAGE(gtkimage)) == GTK_IMAGE_ICON_NAME || gtk_image_get_storage_type(GTK_IMAGE(gtkimage)) == GTK_IMAGE_EMPTY)) {
			const gchar *icon_name = NULL;
			gtk_image_get_icon_name (GTK_IMAGE(gtkimage), &icon_name, NULL);
			if ((icon_name != NULL) && gtk_icon_theme_has_icon(gtk_icon_theme_get_default(), icon_name)) {
				return;
			}
		}
	}

	/* Now figure out what to change */
	if (!g_strcmp0(property, DBUSMENU_MENUITEM_PROP_ICON_NAME)) {
		const gchar * iconname = dbusmenu_menuitem_property_get(item, property);
		if (iconname == NULL) {
			/* If there is no name, by golly we want no
			   icon either. */
			gtkimage = NULL;
		} else if (g_strcmp0(iconname, DBUSMENU_MENUITEM_ICON_NAME_BLANK) == 0) {
			gtkimage = gtk_image_new();
			set_use_fallback(gtkimage);
		} else {
			/* Look to see if we want to have an icon with the 'ltr' or
			   'rtl' depending on what we're doing. */
			gchar * finaliconname = g_strdup_printf("%s-%s", iconname,
						gtk_widget_get_direction(GTK_WIDGET(gimi)) == GTK_TEXT_DIR_RTL ? "rtl" : "ltr");
			if (!gtk_icon_theme_has_icon(gtk_icon_theme_get_default(), finaliconname)) {
				/* If we don't have that icon, fall back to having one
				   without the extra bits. */
				g_free(finaliconname);
				finaliconname = (gchar *)iconname; /* Dropping const not
				                                      becaue we don't love it. */
			}

			/* If we don't have an image, we need to build
			   one so that we can set the name.  Otherwise we
			   can just convert it to this name. */
			if (gtkimage == NULL) {
				gtkimage = gtk_image_new_from_icon_name(finaliconname, GTK_ICON_SIZE_MENU);
				set_use_fallback(gtkimage);
			} else {
				gtk_image_set_from_icon_name(GTK_IMAGE(gtkimage), finaliconname, GTK_ICON_SIZE_MENU);
			}

			/* If we're using the name with extra bits, then we need
			   to free that string. */
			if (finaliconname != iconname) {
				g_free(finaliconname);
			}
		}
	} else {
		GdkPixbuf * image = dbusmenu_menuitem_property_get_image(item, property);
		if (image == NULL) {
			/* If there is no pixbuf, by golly we want no
			   icon either. */
			gtkimage = NULL;
		} else {
			/* Resize the pixbuf */
			gint width, height;
			gtk_icon_size_lookup(GTK_ICON_SIZE_MENU, &width, &height);
			if (gdk_pixbuf_get_width(image) > width ||
					gdk_pixbuf_get_height(image) > height) {
				GdkPixbuf * newimage = gdk_pixbuf_scale_simple(image,
				                                               width,
				                                               height,
				                                               GDK_INTERP_BILINEAR);
				g_object_unref(image);
				image = newimage;
			}
			
			/* If we don't have an image, we need to build
			   one so that we can set the pixbuf. */
			if (gtkimage == NULL) {
				gtkimage = gtk_image_new_from_pixbuf(image);
			} else {
				gtk_image_set_from_pixbuf(GTK_IMAGE(gtkimage), image);
			}
			if (image) {
				g_object_unref(image);
			}
		}

	}

	if (gtkimage != NULL) {
		gint width, height;
		gtk_icon_size_lookup(GTK_ICON_SIZE_MENU, &width, &height);

		gtk_widget_set_size_request(GTK_WIDGET(gtkimage), width, height);
#if GTK_CHECK_VERSION(3,0,0)
		gtk_widget_set_halign(GTK_WIDGET(gtkimage), GTK_ALIGN_START);
		gtk_widget_set_valign(GTK_WIDGET(gtkimage), GTK_ALIGN_CENTER);
#else
		gtk_misc_set_alignment(GTK_MISC(gtkimage), 0.0, 0.5);
#endif
	}

	genericmenuitem_set_image(GENERICMENUITEM(gimi), gtkimage);

	return;
}

