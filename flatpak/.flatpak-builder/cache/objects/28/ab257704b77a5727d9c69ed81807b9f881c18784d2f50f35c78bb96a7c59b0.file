/*
Parse to take a set of GTK Menus and turn them into something that can
be sent over the wire.

Copyright 2011 Canonical Ltd.

Authors:
	Numerous (check Bazaar)

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

#include <atk/atk.h>

#include "parser.h"
#include "menuitem.h"
#include "client.h"
#include "config.h"

#define CACHED_MENUITEM  "dbusmenu-gtk-parser-cached-item"
#define PARSER_DATA      "dbusmenu-gtk-parser-data"

typedef struct _ParserData
{
  GtkWidget *label;
  gulong label_notify_handler_id;

  GtkAction *action;
  gulong action_notify_handler_id;

  GtkWidget *shell;
  gulong item_inserted_handler_id;
  gulong item_removed_handler_id;

  GtkWidget *image;
  gulong image_notify_handler_id;

  AtkObject *accessible;
  gulong a11y_handler_id;

  GtkWidget *widget;
  gulong widget_notify_handler_id;
  gulong widget_add_handler_id;
  gulong widget_accel_handler_id;
  gulong widget_toggle_handler_id;
  gulong widget_visible_handler_id;
  gulong widget_screen_changed_handler_id;

  GtkSettings *settings;
  gulong settings_notify_handler_id;

} ParserData;

typedef struct _RecurseContext
{
  GtkWidget * toplevel;
  DbusmenuMenuitem * parent;
} RecurseContext;

static void parse_menu_structure_helper (GtkWidget * widget, RecurseContext * recurse);
static DbusmenuMenuitem * construct_dbusmenu_for_widget (GtkWidget * widget);
static void           accel_changed            (GtkWidget *         widget,
                                                gpointer            data);
static void           checkbox_toggled         (GtkWidget *         widget,
                                                DbusmenuMenuitem *  mi);
static void           update_icon              (DbusmenuMenuitem *  menuitem,
                                                ParserData *        pdata,
                                                GtkImage *          image);
static GtkWidget *    find_menu_child          (GtkWidget *         widget,
                                                GType               child_type);
static void           label_notify_cb          (GtkWidget *         widget,
                                                GParamSpec *        pspec,
                                                gpointer            data);
static void           image_notify_cb          (GtkWidget *         widget,
                                                GParamSpec *        pspec,
                                                gpointer            data);
static void           action_notify_cb         (GtkAction *         action,
                                                GParamSpec *        pspec,
                                                gpointer            data);
static void           a11y_name_notify_cb      (AtkObject *         accessible,
                                                GParamSpec *        pspec,
                                                gpointer            data);
static void           item_inserted_cb         (GtkContainer *      menu,
                                                GtkWidget *         widget,
                                                gint                position,
                                                gpointer            data);
static void           item_removed_cb          (GtkContainer *      menu,
                                                GtkWidget *         widget,
                                                gpointer            data);
static void           item_activated           (DbusmenuMenuitem *  item,
                                                guint               timestamp,
                                                gpointer            user_data);
static gboolean       item_about_to_show       (DbusmenuMenuitem *  item,
                                                gpointer            user_data);
static gboolean       item_handle_event        (DbusmenuMenuitem *  item,
                                                const gchar *       name,
                                                GVariant *          variant,
                                                guint               timestamp,
                                                GtkWidget *         widget);
static void           widget_notify_cb         (GtkWidget  *        widget,
                                                GParamSpec *        pspec,
                                                gpointer            data);
static void           widget_add_cb            (GtkWidget *         widget,
                                                GtkWidget *         child,
                                                gpointer            data);
static void           widget_screen_changed_cb (GtkWidget *         widget,
                                                GdkScreen *         old_screen,
                                                gpointer            data);
static void           settings_notify_cb       (GtkSettings *       settings,
                                                GParamSpec *        pspec,
                                                gpointer            data);
static gboolean       should_show_image        (GtkImage *          image);
static void           menuitem_notify_cb       (GtkWidget *         widget,
                                                GParamSpec *        pspec,
                                                gpointer            data);

/***
****
***/

static const char * interned_str_accessible_name   = NULL;
static const char * interned_str_active            = NULL;   
static const char * interned_str_always_show_image = NULL;
static const char * interned_str_file              = NULL;
static const char * interned_str_gicon             = NULL;
static const char * interned_str_gtk_menu_images   = NULL;
static const char * interned_str_icon_name         = NULL;      
static const char * interned_str_icon_set          = NULL;     
static const char * interned_str_image             = NULL;  
static const char * interned_str_label             = NULL;  
static const char * interned_str_mask              = NULL; 
static const char * interned_str_parent            = NULL;   
static const char * interned_str_pixbuf_animation  = NULL;             
static const char * interned_str_pixbuf            = NULL;   
static const char * interned_str_pixmap            = NULL;   
static const char * interned_str_sensitive         = NULL;      
static const char * interned_str_stock             = NULL;  
static const char * interned_str_storage_type      = NULL;         
static const char * interned_str_submenu           = NULL;
static const char * interned_str_visible           = NULL;    

static void
ensure_interned_strings_loaded (void)
{
  if (G_UNLIKELY(interned_str_file == NULL))
  {
    interned_str_accessible_name    = g_intern_static_string ("accessible-name");
    interned_str_active             = g_intern_static_string ("active");
    interned_str_always_show_image  = g_intern_static_string ("always-show-image");
    interned_str_file               = g_intern_static_string ("file");
    interned_str_gicon              = g_intern_static_string ("gicon");
    interned_str_gtk_menu_images    = g_intern_static_string ("gtk-menu-images");
    interned_str_icon_name          = g_intern_static_string ("icon-name");
    interned_str_icon_set           = g_intern_static_string ("icon-set");
    interned_str_image              = g_intern_static_string ("image");
    interned_str_label              = g_intern_static_string ("label");
    interned_str_mask               = g_intern_static_string ("mask");
    interned_str_parent             = g_intern_static_string ("parent");
    interned_str_pixbuf_animation   = g_intern_static_string ("pixbuf-animation");
    interned_str_pixbuf             = g_intern_static_string ("pixbuf");
    interned_str_pixmap             = g_intern_static_string ("pixmap");
    interned_str_sensitive          = g_intern_static_string ("sensitive");
    interned_str_stock              = g_intern_static_string ("stock");
    interned_str_storage_type       = g_intern_static_string ("storage-type");
    interned_str_submenu            = g_intern_static_string ("submenu");
    interned_str_visible            = g_intern_static_string ("visible");
  }
}

/***
****
***/

static void
dbusmenu_gtk_clear_signal_handler (gpointer instance, gulong *handler_id)
{
	if (handler_id && *handler_id) {
		/* complain if we thought we were connected but aren't */
		if (!g_signal_handler_is_connected (instance, *handler_id)) {
			g_debug ("%s tried to disconnect signal handler %lu from disconnected %p", G_STRLOC, *handler_id, instance);
		} else {
			g_signal_handler_disconnect (instance, *handler_id);
			*handler_id = 0;
		}
	}
}

/* get the ParserData associated with the specified DbusmenuMenuitem */
static ParserData*
parser_data_get_from_menuitem (DbusmenuMenuitem * item)
{
      return (ParserData *) g_object_get_data(G_OBJECT(item), PARSER_DATA);
}

/* get the ParserData associated with the specified widget */
static ParserData*
parser_data_get_from_widget (GtkWidget * widget)
{
	DbusmenuMenuitem * item = dbusmenu_gtk_parse_get_cached_item (widget);
	if (item != NULL)
		return parser_data_get_from_menuitem (item);
	return NULL;
}

/***
****
***/

/**
 * dbusmenu_gtk_parse_menu_structure:
 * @widget: A #GtkMenuItem or #GtkMenuShell to turn into a #DbusmenuMenuitem
 * 
 * Goes through the GTK structures and turns them into the appropraite
 * Dbusmenu structures along with setting up all the relationships
 * between the objects.  It also stores the dbusmenu items as a cache
 * on the GTK items so that they'll be reused if necissary.
 * 
 * Return value: (transfer full): A dbusmenu item representing the menu structure
 */
DbusmenuMenuitem *
dbusmenu_gtk_parse_menu_structure (GtkWidget * widget)
{
	g_return_val_if_fail(GTK_IS_MENU_ITEM(widget) || GTK_IS_MENU_SHELL(widget), NULL);

	DbusmenuMenuitem * returnval = NULL;
	gpointer data = g_object_get_data(G_OBJECT(widget), CACHED_MENUITEM);

	if (data == NULL) {
		RecurseContext recurse = {0};

		recurse.toplevel = gtk_widget_get_toplevel(widget);

		parse_menu_structure_helper(widget, &recurse);

		returnval = recurse.parent;
	} else {
		returnval = DBUSMENU_MENUITEM(data);
		g_object_ref(G_OBJECT(returnval));
	}

	return returnval;
}

/**
 * dbusmenu_gtk_parse_get_cached_item:
 * @widget: A #GtkMenuItem that may have a cached #DbusmenuMenuitem from the parser
 *
 * The Dbusmenu GTK parser adds cached items on the various
 * menu items throughout the tree.  Sometimes it can be useful
 * to get that cached item to use directly.  This function
 * will retrieve it for you.
 *
 * Return value: (transfer none): A pointer to the cached item
 * or NULL if it isn't there.
 */
DbusmenuMenuitem *
dbusmenu_gtk_parse_get_cached_item (GtkWidget * widget)
{
  GObject * o = NULL;
  DbusmenuMenuitem * ret = NULL;

  if (GTK_IS_MENU_ITEM (widget))
    o = g_object_get_data (G_OBJECT(widget), CACHED_MENUITEM);
 
  if (o && DBUSMENU_IS_MENUITEM(o))
    ret = DBUSMENU_MENUITEM (o);

  return ret;
}

/* remove our dbusmenuitem's hooks to a GtkWidget,
   such as when either of them are being destroyed */
static void
disconnect_from_widget (GtkWidget * widget)
{
  ParserData * pdata = parser_data_get_from_widget (widget);

  if (pdata && pdata->widget)
    {
      GObject * o;

      g_assert (pdata->widget == widget);

      /* stop listening to signals from the widget */
      o = G_OBJECT (pdata->widget);
      dbusmenu_gtk_clear_signal_handler (o, &pdata->widget_notify_handler_id);
      dbusmenu_gtk_clear_signal_handler (o, &pdata->widget_add_handler_id);
      dbusmenu_gtk_clear_signal_handler (o, &pdata->widget_accel_handler_id);
      dbusmenu_gtk_clear_signal_handler (o, &pdata->widget_toggle_handler_id);
      dbusmenu_gtk_clear_signal_handler (o, &pdata->widget_visible_handler_id);
      dbusmenu_gtk_clear_signal_handler (o, &pdata->widget_screen_changed_handler_id);

      /* clear the menuitem's widget pointer */
      g_object_remove_weak_pointer (o, (gpointer*)&pdata->widget);
      pdata->widget = NULL;

      /* clear the widget's menuitem pointer */
      g_object_set_data(o, CACHED_MENUITEM, NULL);
    }
}

static void
parser_data_free (ParserData * pdata)
{
	g_return_if_fail (pdata != NULL);

	if (pdata->label != NULL) {
		GObject * o = G_OBJECT(pdata->label);
		dbusmenu_gtk_clear_signal_handler (o, &pdata->label_notify_handler_id);
		g_object_remove_weak_pointer(o, (gpointer*)&pdata->label);
	}

	if (pdata->action != NULL) {
		GObject * o = G_OBJECT(pdata->action);
		dbusmenu_gtk_clear_signal_handler (o, &pdata->action_notify_handler_id);
		g_object_remove_weak_pointer(o, (gpointer*)&pdata->action);
	}

	if (pdata->widget != NULL) {
		disconnect_from_widget (pdata->widget);
	}

	if (pdata->settings != NULL) {
		dbusmenu_gtk_clear_signal_handler (pdata->settings,
						   &pdata->settings_notify_handler_id);
		g_object_unref (pdata->settings);
	}

	if (pdata->shell != NULL) {
		GObject * o = G_OBJECT(pdata->shell);
		dbusmenu_gtk_clear_signal_handler (o, &pdata->item_inserted_handler_id);
		dbusmenu_gtk_clear_signal_handler (o, &pdata->item_removed_handler_id);
		g_object_remove_weak_pointer(o, (gpointer*)&pdata->shell);
	}

	if (pdata->image != NULL) {
		GObject * o = G_OBJECT(pdata->image);
		dbusmenu_gtk_clear_signal_handler (o, &pdata->image_notify_handler_id);
		g_object_remove_weak_pointer(o, (gpointer*)&pdata->image);
	}

	if (pdata->accessible != NULL) {
		GObject * o = G_OBJECT(pdata->accessible);
		dbusmenu_gtk_clear_signal_handler (o, &pdata->a11y_handler_id);
		g_object_remove_weak_pointer(o, (gpointer*)&pdata->accessible);
	}

	g_free(pdata);

	return;
}

/* Gets the positon of the child with its parent if it has one.
   Returns -1 if the position is unable to be calculated. */
static gint
get_child_position (GtkWidget * child)
{
	GtkWidget * parent = gtk_widget_get_parent (child);
	if (parent == NULL || !GTK_IS_CONTAINER (parent))
		return -1;

	GList * children = gtk_container_get_children (GTK_CONTAINER (parent));
	GList * iter;
	gint position = 0;

	for (iter = children; iter != NULL; iter = iter->next) {
		if (iter->data == child)
			break;
		++position;
	}

	g_list_free (children);

	if (iter == NULL)
		return -1;
	else
		return position;
}

/* Creates a new menu item that is attached to the widget and has
   the data linkages hooked up.  Also allocates the ParserData */
static DbusmenuMenuitem *
new_menuitem (GtkWidget * widget)
{
	DbusmenuMenuitem * item = dbusmenu_menuitem_new();

	ParserData *pdata = g_new0 (ParserData, 1);
	g_object_set_data_full(G_OBJECT(item), PARSER_DATA, pdata, (GDestroyNotify)parser_data_free);

	pdata->widget = widget;
	g_object_add_weak_pointer(G_OBJECT (widget), (gpointer*)&pdata->widget);
	g_object_set_data_full(G_OBJECT(widget), CACHED_MENUITEM, g_object_ref(item), g_object_unref);

	return item;
}

static gboolean
toggle_widget_visibility (GtkWidget * widget)
{
	gboolean vis = gtk_widget_get_visible (widget);
	gtk_widget_set_visible (widget, !vis);
	gtk_widget_set_visible (widget, vis);
	g_object_unref (G_OBJECT (widget));
	return FALSE;
}

static void
watch_submenu(DbusmenuMenuitem * mi, GtkWidget * menu)
{
	g_return_if_fail(DBUSMENU_IS_MENUITEM(mi));
	g_return_if_fail(GTK_IS_MENU_SHELL(menu));

	ParserData *pdata = parser_data_get_from_menuitem (mi);

	pdata->shell = menu;
	pdata->item_inserted_handler_id = g_signal_connect (G_OBJECT (menu),
                          "insert",
		          G_CALLBACK (item_inserted_cb),
		          mi);
	pdata->item_removed_handler_id = g_signal_connect (G_OBJECT (menu),
	                                                   "remove",
	                                                   G_CALLBACK (item_removed_cb),
	                                                   mi);
	g_object_add_weak_pointer(G_OBJECT (menu), (gpointer*)&pdata->shell);

	/* Some apps (notably Eclipse RCP apps) don't fill contents of submenus
	   until the menu is shown.  So we fake that by toggling the visibility of
	   any submenus we come across.  Further, these apps need it done with a
	   delay while they finish initializing, so we put the call in the idle
	   queue. */
	g_idle_add((GSourceFunc)toggle_widget_visibility,
	           g_object_ref (G_OBJECT (menu)));
}

static void
activate_toplevel_item (GtkWidget * item)
{
	/* Make sure that we have a menu item before we start calling
	   functions that depend on it.  This should almost always be
	   the case. */
	if (!GTK_IS_MENU_ITEM(item)) {
		return;
	}

	/* If the item is not opening a submenu we don't want to activate
	   it as that'd cause an action.  Like opening a preferences dialog
	   to the user.  That's not a good idea. */
	if (gtk_menu_item_get_submenu(GTK_MENU_ITEM(item)) == NULL) {
		return;
	}

	GtkWidget * shell = gtk_widget_get_parent (item);
	if (!GTK_IS_MENU_BAR (shell)) {
		return;
	}

	gtk_menu_shell_activate_item (GTK_MENU_SHELL (shell),
	                              item,
	                              TRUE);
}

static void
parse_menu_structure_helper (GtkWidget * widget, RecurseContext * recurse)
{
	/* If this is a shell, then let's handle the items in it. */
	if (GTK_IS_MENU_SHELL (widget)) {
		/* Okay, this is a little janky and all.. but some applications update some
		 * menuitem properties such as sensitivity on the activate callback.  This
		 * seems a little weird, but it's not our place to judge when all this code
		 * is so crazy.  So we're going to get ever crazier and activate all the
		 * menus that are directly below the menubar and force the applications to
		 * update their sensitivity.  The menus won't actually popup in the app
		 * window due to our gtk+ patches.
		 *
		 * Note that this will not force menuitems in submenus to be updated as well.
		 */
		if (recurse->parent == NULL && GTK_IS_MENU_BAR(widget)) {
			gtk_container_foreach (GTK_CONTAINER (widget),
			                       (GtkCallback)activate_toplevel_item,
			                       NULL);
		}

		if (recurse->parent == NULL) {
			recurse->parent = new_menuitem(widget);
			watch_submenu(recurse->parent, widget);
		}

		gtk_container_foreach (GTK_CONTAINER (widget),
		                       (GtkCallback)parse_menu_structure_helper,
		                       recurse);
		return;
	}

	if (GTK_IS_MENU_ITEM(widget)) {
		DbusmenuMenuitem * thisitem = NULL;

		/* Check to see if we're cached already */
		gpointer pmi = g_object_get_data(G_OBJECT(widget), CACHED_MENUITEM);
		if (pmi != NULL) {
			thisitem = DBUSMENU_MENUITEM(pmi);
			g_object_ref(G_OBJECT(thisitem));
		}

		/* We don't have one, so we'll need to build it */
		if (thisitem == NULL) {
			thisitem = construct_dbusmenu_for_widget (widget);

			if (!gtk_widget_get_visible (widget)) {
				ParserData *pdata = parser_data_get_from_menuitem (thisitem);
				pdata->widget_visible_handler_id = g_signal_connect (G_OBJECT (widget),
				                                                     "notify::visible",
				                                                     G_CALLBACK (menuitem_notify_cb),
				                                                     recurse->toplevel);
			}

			if (GTK_IS_TEAROFF_MENU_ITEM (widget)) {
				dbusmenu_menuitem_property_set_bool (thisitem,
				                                     DBUSMENU_MENUITEM_PROP_VISIBLE,
				                                     FALSE);
			}
		}

		/* Check to see if we're in our parents list of children, if we have
		   a parent. */
		if (recurse->parent != NULL) {
			GList * children = dbusmenu_menuitem_get_children (recurse->parent);
			GList * peek = NULL;

			if (children != NULL) {
				peek = g_list_find (children, thisitem);
			}

			/* Oops, let's tell our parents about us */
			if (peek == NULL) {
				g_object_ref(thisitem);

				DbusmenuMenuitem * parent = dbusmenu_menuitem_get_parent(thisitem);
				if (parent != NULL) {
					dbusmenu_menuitem_child_delete(parent, thisitem);
				}

				gint pos = get_child_position (widget);
				if (pos >= 0)
					dbusmenu_menuitem_child_add_position (recurse->parent,
					                                      thisitem,
					                                      pos);
				else
					dbusmenu_menuitem_child_append (recurse->parent,
					                                thisitem);

				g_object_unref(thisitem);
			}
		}

		GtkWidget *menu = gtk_menu_item_get_submenu (GTK_MENU_ITEM (widget));
		if (menu != NULL) {
			DbusmenuMenuitem * parent_save = recurse->parent;
			recurse->parent = thisitem;
			parse_menu_structure_helper (menu, recurse);
			recurse->parent = parent_save;
		}

		if (recurse->parent == NULL) {
			recurse->parent = thisitem;
		} else {
			g_object_unref(thisitem);
		}
	}

	return;
}

static gchar *
sanitize_label_text (const gchar * label)
{
	/* Label contains underscores, which we like, and pango markup,
           which we don't. */
	gchar * sanitized = NULL;
	GError * error = NULL;

	if (label == NULL) {
		return NULL;
	}

	if (pango_parse_markup (label, -1, 0, NULL, &sanitized, NULL, &error)) {
		return sanitized;
	}

	if (error != NULL) {
		g_warning ("Could not parse '%s': %s", label, error->message);
		g_error_free (error);
	}
	return g_strdup (label);
}

static gchar *
sanitize_label (GtkLabel * label)
{
	gchar * text;

	if (gtk_label_get_use_markup (label)) {
		text = sanitize_label_text (gtk_label_get_label (label));
	}
	else {
		text = g_strdup (gtk_label_get_label (label));
	}

	if (!gtk_label_get_use_underline (label)) {
		/* Insert extra underscores */
		GRegex * regex = g_regex_new ("_", 0, 0, NULL);
		gchar * escaped = g_regex_replace_literal (regex, text, -1, 0, "__", 0, NULL);

		g_regex_unref (regex);
		g_free (text);

		text = escaped;
	}

	return text;
}

/* Turn a widget into a dbusmenu item depending on the type of GTK
   object that it is. */
static DbusmenuMenuitem *
construct_dbusmenu_for_widget (GtkWidget * widget)
{
  /* If it's a standard GTK Menu Item we need to do some of our own work */
  if (GTK_IS_MENU_ITEM (widget))
    {
      DbusmenuMenuitem *mi = new_menuitem(widget);

      ParserData *pdata = (ParserData *)g_object_get_data(G_OBJECT(mi), PARSER_DATA);

      gboolean visible = FALSE;
      gboolean sensitive = FALSE;
      if (GTK_IS_SEPARATOR_MENU_ITEM (widget) || !find_menu_child (widget, GTK_TYPE_LABEL))
        {
          dbusmenu_menuitem_property_set (mi,
                                          DBUSMENU_MENUITEM_PROP_TYPE,
                                          DBUSMENU_CLIENT_TYPES_SEPARATOR);

          visible = gtk_widget_get_visible (widget);
          sensitive = gtk_widget_get_sensitive (widget);
        }
      else
        {
          GtkWidget *image = NULL;

          pdata->widget_accel_handler_id = g_signal_connect (widget, "accel-closures-changed",
                                                             G_CALLBACK (accel_changed), mi);

          if (GTK_IS_CHECK_MENU_ITEM (widget))
            {
              dbusmenu_menuitem_property_set (mi,
                                              DBUSMENU_MENUITEM_PROP_TOGGLE_TYPE,
                                              gtk_check_menu_item_get_draw_as_radio (GTK_CHECK_MENU_ITEM (widget)) ? DBUSMENU_MENUITEM_TOGGLE_RADIO : DBUSMENU_MENUITEM_TOGGLE_CHECK);

              dbusmenu_menuitem_property_set_int (mi,
                                                  DBUSMENU_MENUITEM_PROP_TOGGLE_STATE,
                                                  gtk_check_menu_item_get_active (GTK_CHECK_MENU_ITEM (widget)) ? DBUSMENU_MENUITEM_TOGGLE_STATE_CHECKED : DBUSMENU_MENUITEM_TOGGLE_STATE_UNCHECKED);

              pdata->widget_toggle_handler_id = g_signal_connect (widget, "activate", G_CALLBACK (checkbox_toggled), mi);
            }
          else if (GTK_IS_IMAGE_MENU_ITEM (widget))
            {

              image = gtk_image_menu_item_get_image (GTK_IMAGE_MENU_ITEM (widget));

            }
          else
            {
              // GtkImageMenuItem is deprecated, so check regular GtkMenuItems
              // for an image child too
              image = find_menu_child (widget, GTK_TYPE_IMAGE);
            }

          if (GTK_IS_IMAGE (image))
            {
              update_icon (mi, pdata, GTK_IMAGE (image));
            }


          GtkWidget *label = find_menu_child (widget, GTK_TYPE_LABEL);

          // Sometimes, an app will directly find and modify the label
          // (like empathy), so watch the label especially for that.
          gchar * text = sanitize_label (GTK_LABEL (label));
          dbusmenu_menuitem_property_set (mi, DBUSMENU_MENUITEM_PROP_LABEL, text);
          g_free (text);

          pdata->label = label;
          pdata->label_notify_handler_id = g_signal_connect (G_OBJECT (label), "notify", G_CALLBACK(label_notify_cb), mi);
          g_object_add_weak_pointer(G_OBJECT (label), (gpointer*)&pdata->label);

          AtkObject *accessible = gtk_widget_get_accessible (widget);
          if (accessible)
            {
              // Getting the accessible name of the Atk object retrieves the text
              // of the menu item label, unless the application has set an alternate
              // accessible name.
              const gchar * label_text = gtk_label_get_text (GTK_LABEL (label));
              const gchar * a11y_name = atk_object_get_name (accessible);
              if (g_strcmp0 (a11y_name, label_text))
                dbusmenu_menuitem_property_set (mi, DBUSMENU_MENUITEM_PROP_ACCESSIBLE_DESC, a11y_name);

              // An application may set an alternate accessible name in the future,
              // so we had better watch out for it.
              pdata->accessible = accessible;
              pdata->a11y_handler_id = g_signal_connect (G_OBJECT (accessible),
                                                         "notify::accessible-name",
                                                         G_CALLBACK (a11y_name_notify_cb),
                                                         mi);
              g_object_add_weak_pointer(G_OBJECT (accessible), (gpointer*)&pdata->accessible);
            }

          if (GTK_IS_ACTIVATABLE (widget))
            {
              GtkActivatable *activatable = GTK_ACTIVATABLE (widget);

              if (gtk_activatable_get_use_action_appearance (activatable))
                {
                  GtkAction *action = gtk_activatable_get_related_action (activatable);

                  if (action)
                    {
                      visible = gtk_action_is_visible (action);
                      sensitive = gtk_action_is_sensitive (action);

                      pdata->action = action;
                      pdata->action_notify_handler_id = g_signal_connect_object (action, "notify",
                                                                                 G_CALLBACK (action_notify_cb), mi,
                                                                                 G_CONNECT_AFTER);
                      g_object_add_weak_pointer(G_OBJECT (action), (gpointer*)&pdata->action);
                    }
                }
            }

          GtkWidget *submenu = gtk_menu_item_get_submenu(GTK_MENU_ITEM(widget));
          if (submenu)
            {
              watch_submenu(mi, submenu);
            }

          if (!g_object_get_data (G_OBJECT (widget), "gtk-empty-menu-item") && !GTK_IS_TEAROFF_MENU_ITEM (widget))
            {
              visible = gtk_widget_get_visible (widget);
              sensitive = gtk_widget_get_sensitive (widget);
            }

          dbusmenu_menuitem_property_set_shortcut_menuitem (mi, GTK_MENU_ITEM (widget));

          g_signal_connect (G_OBJECT (mi),
                            DBUSMENU_MENUITEM_SIGNAL_ITEM_ACTIVATED,
                            G_CALLBACK (item_activated),
                            widget);

          g_signal_connect (G_OBJECT (mi),
                            DBUSMENU_MENUITEM_SIGNAL_ABOUT_TO_SHOW,
                            G_CALLBACK (item_about_to_show),
                            widget);

          g_signal_connect (G_OBJECT (mi),
                            DBUSMENU_MENUITEM_SIGNAL_EVENT,
                            G_CALLBACK (item_handle_event),
                            widget);
        }

      dbusmenu_menuitem_property_set_bool (mi,
                                           DBUSMENU_MENUITEM_PROP_VISIBLE,
                                           visible);

      dbusmenu_menuitem_property_set_bool (mi,
                                           DBUSMENU_MENUITEM_PROP_ENABLED,
                                           sensitive);

      pdata->widget_notify_handler_id = g_signal_connect (widget, "notify",
                                                          G_CALLBACK (widget_notify_cb), mi);

      pdata->widget_add_handler_id = g_signal_connect (widget, "add",
                                                       G_CALLBACK (widget_add_cb), mi);

      pdata->widget_screen_changed_handler_id = g_signal_connect (widget, "screen-changed",
                                                                  G_CALLBACK (widget_screen_changed_cb), mi);
      widget_screen_changed_cb (widget, NULL, mi);

      return mi;
    }

	/* If it's none of those we're going to just create a
	   generic menuitem as a place holder for it. */
	return new_menuitem(widget);
}

static void
menuitem_notify_cb (GtkWidget  *widget,
                    GParamSpec *pspec,
                    gpointer    data)
{
  ensure_interned_strings_loaded ();

  if (pspec->name == interned_str_visible)
    {
      GtkWidget * new_toplevel = gtk_widget_get_toplevel (widget);
      GtkWidget * old_toplevel = GTK_WIDGET(data);

      if (new_toplevel == old_toplevel) {
          /* TODO: Figure this out -> rebuild (context->bridge, window); */
      }

      /* We only care about this once, so let's disconnect now. */
      ParserData * pdata = parser_data_get_from_widget (widget);
      dbusmenu_gtk_clear_signal_handler (widget, &pdata->widget_visible_handler_id);
    }
}

static void
accel_changed (GtkWidget *widget,
               gpointer   data)
{
  DbusmenuMenuitem *mi = (DbusmenuMenuitem *)data;
  dbusmenu_menuitem_property_set_shortcut_menuitem (mi, GTK_MENU_ITEM (widget));
}

static void
checkbox_toggled (GtkWidget *widget, DbusmenuMenuitem *mi)
{
  dbusmenu_menuitem_property_set_int (mi,
                                      DBUSMENU_MENUITEM_PROP_TOGGLE_STATE,
                                      gtk_check_menu_item_get_active (GTK_CHECK_MENU_ITEM (widget)) ? DBUSMENU_MENUITEM_TOGGLE_STATE_CHECKED : DBUSMENU_MENUITEM_TOGGLE_STATE_UNCHECKED);
}

static void
update_icon (DbusmenuMenuitem *menuitem, ParserData * pdata, GtkImage *image)
{
  GdkPixbuf * pixbuf = NULL;
  const gchar * icon_name = NULL;
  GtkStockItem stock;
  GIcon * gicon;
  GtkIconInfo * info;
  gint width;

  /* Check to see if we're changing the image.  If so, we need to track that little bugger */
  if (image != GTK_IMAGE(pdata->image)) {

    if (pdata->image != NULL) {
      GObject * o = G_OBJECT(pdata->image);
      dbusmenu_gtk_clear_signal_handler (o, &pdata->image_notify_handler_id);
      g_object_remove_weak_pointer(o, (gpointer*)&pdata->image);
    }

    pdata->image = GTK_WIDGET(image);

    if (pdata->image != NULL) {
      pdata->image_notify_handler_id = g_signal_connect (G_OBJECT (pdata->image),
                                                         "notify",
                                                         G_CALLBACK (image_notify_cb),
                                                         menuitem);
      g_object_add_weak_pointer(G_OBJECT (pdata->image), (gpointer*)&pdata->image);
    }
  }

  if (image != NULL && should_show_image (image)) {
    switch (gtk_image_get_storage_type (image)) {
    case GTK_IMAGE_EMPTY:
      break;

    case GTK_IMAGE_PIXBUF:
      pixbuf = g_object_ref (gtk_image_get_pixbuf (image));
      break;

    case GTK_IMAGE_ICON_NAME:
      gtk_image_get_icon_name (image, &icon_name, NULL);
      break;

    case GTK_IMAGE_STOCK:
      gtk_image_get_stock (image, (gchar **) &icon_name, NULL);
      if (gtk_stock_lookup (icon_name, &stock)) {
        /* Now set label too */
        const gchar * label = NULL;
        label = dbusmenu_menuitem_property_get (menuitem,
                                                DBUSMENU_MENUITEM_PROP_LABEL);
        if (stock.label != NULL && label != NULL && label[0] == '\0') {
          dbusmenu_menuitem_property_set (menuitem,
                                          DBUSMENU_MENUITEM_PROP_LABEL,
                                          stock.label);
        }
      }
      break;

    case GTK_IMAGE_GICON:
      /* Load up a pixbuf and send that over.  We don't bother differentiating
         between icon-name gicons and pixbuf gicons because even when given a
         icon-name gicon, there's no easy way to lookup which icon-name among
         its set is present and should be used among the icon themes available.
         So instead, we render to a pixbuf and watch icon theme changes. */
      gtk_image_get_gicon (image, &gicon, NULL);
		  gtk_icon_size_lookup(GTK_ICON_SIZE_MENU, &width, NULL);
      info = gtk_icon_theme_lookup_by_gicon (gtk_icon_theme_get_default (),
                                             gicon, width, 
                                             GTK_ICON_LOOKUP_FORCE_SIZE);
      if (info != NULL) {
        pixbuf = gtk_icon_info_load_icon (info, NULL);
#if GTK_CHECK_VERSION(3,8,0)
        g_object_unref (info);
#else
        gtk_icon_info_free (info);
#endif
      }
      break;

    default:
      g_debug ("Could not handle image type %i\n", gtk_image_get_storage_type (image));
      break;
    }
  }

  if (icon_name != NULL) {
    dbusmenu_menuitem_property_set (menuitem,
                                    DBUSMENU_MENUITEM_PROP_ICON_NAME,
                                    icon_name);
    dbusmenu_menuitem_property_remove (menuitem,
                                       DBUSMENU_MENUITEM_PROP_ICON_DATA);
  }
  else if (pixbuf != NULL) {
    dbusmenu_menuitem_property_remove (menuitem,
                                       DBUSMENU_MENUITEM_PROP_ICON_NAME);
    dbusmenu_menuitem_property_set_image (menuitem,
                                          DBUSMENU_MENUITEM_PROP_ICON_DATA,
                                          pixbuf);
  }
  else {
    dbusmenu_menuitem_property_remove (menuitem,
                                       DBUSMENU_MENUITEM_PROP_ICON_NAME);
    dbusmenu_menuitem_property_remove (menuitem,
                                       DBUSMENU_MENUITEM_PROP_ICON_DATA);
  }

  if (pixbuf != NULL) {
    g_object_unref (pixbuf);
  }
}

static GtkWidget *
find_menu_child (GtkWidget *widget, GType child_type)
{
  GtkWidget *child = NULL;

  if (G_TYPE_CHECK_INSTANCE_TYPE (widget, child_type))
    return widget;

  if (GTK_IS_CONTAINER (widget))
    {
      GList *children;
      GList *l;

      children = gtk_container_get_children (GTK_CONTAINER (widget));

      for (l = children; l; l = l->next)
        {
          child = find_menu_child (l->data, child_type);

          if (child)
            break;
        }

      g_list_free (children);
    }

  return child;
}

static void
recreate_menu_item (DbusmenuMenuitem * parent, DbusmenuMenuitem * child)
{
  if (parent == NULL)
    {
      /* We need a parent */
      return;
    }
  ParserData * pdata = g_object_get_data (G_OBJECT (child), PARSER_DATA);
  /* Keep a pointer to the GtkMenuItem, as pdata->widget might be
   * invalidated when we delete the DbusmenuMenuitem
   */
  GtkWidget * menuitem = pdata->widget;

  dbusmenu_menuitem_child_delete (parent, child);
  disconnect_from_widget (menuitem);

  RecurseContext recurse = {0};
  recurse.toplevel = gtk_widget_get_toplevel(menuitem);
  recurse.parent = parent;

  parse_menu_structure_helper(menuitem, &recurse);
}

static gboolean
recreate_menu_item_in_idle_cb (gpointer data)
{
  DbusmenuMenuitem * child = (DbusmenuMenuitem *)data;
  DbusmenuMenuitem * parent = dbusmenu_menuitem_get_parent (child);
  g_object_unref (child);
  recreate_menu_item (parent, child);
  return FALSE;
}

static void
label_notify_cb (GtkWidget  *widget,
                 GParamSpec *pspec,
                 gpointer    data)
{
  DbusmenuMenuitem *child = (DbusmenuMenuitem *)data;
  GValue prop_value = {0};

  ensure_interned_strings_loaded ();

  g_value_init (&prop_value, pspec->value_type); 
  g_object_get_property (G_OBJECT (widget), pspec->name, &prop_value);

  if (pspec->name == interned_str_label)
    {
      gchar * text = sanitize_label (GTK_LABEL (widget));
      dbusmenu_menuitem_property_set (child,
                                      DBUSMENU_MENUITEM_PROP_LABEL,
                                      text);
      g_free (text);
    }
  else if (pspec->name == interned_str_parent)
    {
      if (GTK_WIDGET (g_value_get_object (&prop_value)) == NULL)
        {
          /* This label is being removed from its GtkMenuItem. The
           * menuitem becomes a separator now. As the client doesn't handle
           * changing types so well, we remove the current DbusmenuMenuitem
           * and add a new one.
           *
           * Note, we have to defer this to idle, as we are called before
           * bin->child member of our old parent is invalidated. If we go ahead
           * and call parse_menu_structure_helper now, the GtkMenuItem will
           * still appear to have a label and we never convert it to a separator
           */
          g_object_ref (child);
          g_idle_add ((GSourceFunc)recreate_menu_item_in_idle_cb, child);
        } 
    }

  g_value_unset(&prop_value);
  return;
}

static void
image_notify_cb (GtkWidget * image, GParamSpec * pspec, gpointer data)
{
  ensure_interned_strings_loaded();

  if (pspec->name == interned_str_file ||
      pspec->name == interned_str_gicon ||
      pspec->name == interned_str_icon_name ||
      pspec->name == interned_str_icon_set ||
      pspec->name == interned_str_image ||
      pspec->name == interned_str_mask ||
      pspec->name == interned_str_pixbuf ||
      pspec->name == interned_str_pixbuf_animation ||
      pspec->name == interned_str_pixmap ||
      pspec->name == interned_str_stock ||
      pspec->name == interned_str_storage_type)
    {
      DbusmenuMenuitem * mi = DBUSMENU_MENUITEM(data);
      ParserData *pdata = (ParserData *)g_object_get_data(G_OBJECT(mi), PARSER_DATA);
      update_icon (mi, pdata, GTK_IMAGE (image));
    }
}

static void
action_notify_cb (GtkAction *action, GParamSpec * pspec, gpointer data)
{
  DbusmenuMenuitem * mi = DBUSMENU_MENUITEM(data);
  ensure_interned_strings_loaded ();

  if (pspec->name == interned_str_sensitive)
    {
      dbusmenu_menuitem_property_set_bool (mi,
                                           DBUSMENU_MENUITEM_PROP_ENABLED,
                                           gtk_action_is_sensitive (action));
    }
  else if (pspec->name == interned_str_visible)
    {
      dbusmenu_menuitem_property_set_bool (mi,
                                           DBUSMENU_MENUITEM_PROP_VISIBLE,
                                           gtk_action_is_visible (action));
    }
  else if (pspec->name == interned_str_active)
    {
      dbusmenu_menuitem_property_set_int (mi,
                                          DBUSMENU_MENUITEM_PROP_TOGGLE_STATE,
                                          gtk_toggle_action_get_active (GTK_TOGGLE_ACTION (action)) ? DBUSMENU_MENUITEM_TOGGLE_STATE_CHECKED : DBUSMENU_MENUITEM_TOGGLE_STATE_UNCHECKED);
    }
  else if (pspec->name == interned_str_label)
    {
      gchar * text = sanitize_label_text (gtk_action_get_label (action));
      dbusmenu_menuitem_property_set (mi,
                                      DBUSMENU_MENUITEM_PROP_LABEL,
                                      text);
      g_free (text);
    }
}

static void
a11y_name_notify_cb (AtkObject * accessible, GParamSpec * pspec, gpointer data)
{
  ensure_interned_strings_loaded ();

  /* If an application sets the accessible name to NULL, then a subsequent
   * call to get the accessible name from the Atk object should return the same
   * string as the text of the menu item label, in which case, we want to clear
   * the accessible description property of the dbusmenu item.
   */
  if (pspec->name == interned_str_accessible_name)
    {
      DbusmenuMenuitem * item = DBUSMENU_MENUITEM(data);
      GtkWidget *widget = gtk_accessible_get_widget (GTK_ACCESSIBLE (accessible));
      GtkWidget *label = find_menu_child (widget, GTK_TYPE_LABEL);
      const gchar *label_text = gtk_label_get_text (GTK_LABEL (label));
      const gchar *name = atk_object_get_name (accessible);

      if (!g_strcmp0 (name, label_text))
        dbusmenu_menuitem_property_set (item, DBUSMENU_MENUITEM_PROP_ACCESSIBLE_DESC, NULL);
      else
        dbusmenu_menuitem_property_set (item, DBUSMENU_MENUITEM_PROP_ACCESSIBLE_DESC, name);
    }
}

static void
item_activated (DbusmenuMenuitem *item, guint timestamp, gpointer user_data)
{
  GtkWidget *child;

  if (user_data != NULL)
    {
      child = (GtkWidget *)user_data;

      if (GTK_IS_MENU_ITEM (child))
        {
          GtkWidget *parent = gtk_widget_get_parent(child);
          if (GTK_IS_MENU (parent))
            {
              gint pos = get_child_position (child);
              if (pos >= 0)
                gtk_menu_set_active (GTK_MENU(parent), pos);
            }

          gdk_threads_enter ();
          gtk_menu_item_activate (GTK_MENU_ITEM (child));
          gdk_threads_leave ();
        }
    }
}

static gboolean
item_about_to_show (DbusmenuMenuitem *item, gpointer user_data)
{
  GtkWidget *child;

  if (user_data != NULL)
    {
      child = (GtkWidget *)user_data;

      if (GTK_IS_MENU_ITEM (child))
        {
          // Only called for items with submens.  So we activate it here in
          // case the program dynamically creates menus (like empathy does)
          gtk_menu_item_activate (GTK_MENU_ITEM (child));
        }
    }

  return TRUE;
}

static gboolean
item_handle_event (DbusmenuMenuitem *item, const gchar *name,
                   GVariant *variant, guint timestamp, GtkWidget *widget)
{
  if (g_strcmp0 (name, DBUSMENU_MENUITEM_EVENT_OPENED) == 0)
    {
      GtkWidget *submenu = gtk_menu_item_get_submenu (GTK_MENU_ITEM (widget));
      if (submenu != NULL)
        {
          // Show the submenu so the app can notice and futz with the menus as
          // desired (empathy and geany do this)
          gtk_widget_show (submenu);
        }
    }
  else if (g_strcmp0 (name, DBUSMENU_MENUITEM_EVENT_CLOSED) == 0)
    {
      GtkWidget *submenu = gtk_menu_item_get_submenu (GTK_MENU_ITEM (widget));
      if (submenu != NULL)
        {
          // Hide the submenu so the app can notice and futz with the menus as
          // desired (empathy and geany do this)
          gtk_widget_hide (submenu);
        }
    }

  return FALSE; // just pass through on everything
}

static gboolean
handle_first_label (DbusmenuMenuitem *mi)
{
  ParserData *pdata = g_object_get_data (G_OBJECT (mi), PARSER_DATA);
  if (!pdata->label)
    {
      /* GtkMenuItem's can start life as a separator if they have no child
       * GtkLabel. In this case, we need to convert the DbusmenuMenuitem from
       * a separator to a normal menuitem if the application adds a label.
       * As changing types isn't handled too well by the client, we delete
       * this menuitem for now and then recreate it
       */
      DbusmenuMenuitem * parent = dbusmenu_menuitem_get_parent (mi);
      recreate_menu_item (parent, mi);
      return TRUE;
    }

  return FALSE;
}

static void
widget_notify_cb (GtkWidget * widget, GParamSpec * pspec, gpointer data)
{
  GValue prop_value = {0};
  DbusmenuMenuitem * child = DBUSMENU_MENUITEM(data);
  g_return_if_fail (child != NULL);

  ensure_interned_strings_loaded ();

  g_value_init (&prop_value, pspec->value_type); 
  g_object_get_property (G_OBJECT (widget), pspec->name, &prop_value);

  if (pspec->name == interned_str_sensitive)
    {
      dbusmenu_menuitem_property_set_bool (child,
                                           DBUSMENU_MENUITEM_PROP_ENABLED,
                                           g_value_get_boolean (&prop_value));
    }
  else if (pspec->name == interned_str_label)
    {
      if (!handle_first_label (child))
        {
          dbusmenu_menuitem_property_set (child,
                                          DBUSMENU_MENUITEM_PROP_LABEL,
                                          g_value_get_string (&prop_value));
        }
    }
  else if (pspec->name == interned_str_visible)
    {
      dbusmenu_menuitem_property_set_bool (child,
                                           DBUSMENU_MENUITEM_PROP_VISIBLE,
                                           g_value_get_boolean (&prop_value));
    }
  else if (pspec->name == interned_str_always_show_image)
    {
      GtkWidget *image = NULL;
      g_object_get(widget, "image", &image, NULL);
      ParserData *pdata = (ParserData *)g_object_get_data(G_OBJECT(child), PARSER_DATA);
      update_icon (child, pdata, GTK_IMAGE(image));
    }
  else if (pspec->name == interned_str_image)
    {
      GtkWidget * image = GTK_WIDGET (g_value_get_object (&prop_value));
      ParserData *pdata = (ParserData *)g_object_get_data(G_OBJECT(child), PARSER_DATA);
      update_icon (child, pdata, GTK_IMAGE (image));
    }
  else if (pspec->name == interned_str_parent)
    {
      /*
        * We probably should have added a 'remove' method to the
        * UbuntuMenuProxy early on, but it's late in the cycle now.
        */
      if (GTK_WIDGET (g_value_get_object (&prop_value)) == NULL) 
        {
          ParserData *pdata = parser_data_get_from_menuitem (child);
          dbusmenu_gtk_clear_signal_handler (widget, &pdata->widget_notify_handler_id);

          DbusmenuMenuitem *parent = dbusmenu_menuitem_get_parent (child);

          if (DBUSMENU_IS_MENUITEM (parent) && DBUSMENU_IS_MENUITEM (child))
            {
              dbusmenu_menuitem_child_delete (parent, child);
            }
        }
    }
  else if (pspec->name == interned_str_submenu)
    {
      /* The underlying submenu got swapped out.  Let's see what it is now. */
      /* First, delete any children that may exist currently. */
      DbusmenuMenuitem * item = DBUSMENU_MENUITEM(g_object_get_data(G_OBJECT(widget), CACHED_MENUITEM));
      if (item != NULL)
        {
          GList * children = dbusmenu_menuitem_take_children (item);
          GList * child = children;
          while (child != NULL) {
            g_object_unref (G_OBJECT(child->data));
            child = child->next;
          }
          g_list_free(children);
        }

      /* Now parse new submenu. */
      RecurseContext recurse = {0};
      recurse.toplevel = gtk_widget_get_toplevel(widget);
      recurse.parent = item;

	  if (item != NULL) {
        GtkWidget * menu = GTK_WIDGET (g_value_get_object (&prop_value));
        /* Ensure the submenu isn't being set to NULL to remove it
         * (ex. Geany does this) */
        if (menu != NULL) {
            parse_menu_structure_helper(menu, &recurse);
            watch_submenu(item, menu);
        }
      } else {
        /* Note: it would be really odd that we wouldn't have a cached
           item, but we should handle that appropriately. */
        parse_menu_structure_helper(widget, &recurse);
        g_object_unref(G_OBJECT(recurse.parent));
      }
    }
  g_value_unset (&prop_value);
}

static void
widget_add_cb (GtkWidget *widget,
               GtkWidget *child,
               gpointer   data)
{
  if (find_menu_child (widget, GTK_TYPE_LABEL) != NULL)
    handle_first_label (data);
}

/* Pass NULL for pspec to update all settings at once */
static void
widget_screen_changed_cb (GtkWidget * widget, GdkScreen * old_screen, gpointer data)
{
  DbusmenuMenuitem * mi = DBUSMENU_MENUITEM(data);
  g_return_if_fail (mi != NULL);

  ParserData *pdata = (ParserData *)g_object_get_data(G_OBJECT(mi), PARSER_DATA);

  if (pdata->settings != NULL)
    {
      dbusmenu_gtk_clear_signal_handler (pdata->settings,
                                         &pdata->settings_notify_handler_id);
      g_object_unref (pdata->settings);
    }

  pdata->settings = g_object_ref (gtk_widget_get_settings (widget));
  pdata->settings_notify_handler_id = g_signal_connect (pdata->settings, "notify",
                                                        G_CALLBACK (settings_notify_cb), mi);

  /* And update widget now that we have a new GtkSettings */
  settings_notify_cb (gtk_widget_get_settings (widget), NULL, mi);
}

/* Pass NULL for pspec to update all settings at once */
static void
settings_notify_cb (GtkSettings * settings, GParamSpec * pspec, gpointer data)
{
  GValue prop_value = {0};
  DbusmenuMenuitem * mi = DBUSMENU_MENUITEM(data);
  g_return_if_fail (mi != NULL);

  ensure_interned_strings_loaded ();

  if (pspec != NULL)
    {
      g_value_init (&prop_value, pspec->value_type); 
      g_object_get_property (G_OBJECT (settings), pspec->name, &prop_value);
    }

  if (pspec == NULL || pspec->name == interned_str_gtk_menu_images)
    {
      ParserData *pdata = (ParserData *)g_object_get_data(G_OBJECT(mi), PARSER_DATA);
      update_icon (mi, pdata, GTK_IMAGE(pdata->image));
    }

  if (pspec != NULL)
    g_value_unset (&prop_value);
}

/* A child item was added to a menu we're watching.  Let's try to integrate it. */
static void
item_inserted_cb (GtkContainer *menu,
                  GtkWidget    *widget,
                  gint          position,
                  gpointer      data)
{
	DbusmenuMenuitem *menuitem = (DbusmenuMenuitem *)data;

	RecurseContext recurse = {0};
	recurse.toplevel = gtk_widget_get_toplevel(GTK_WIDGET(menu));
	recurse.parent = menuitem;

	if (GTK_IS_MENU_BAR(menu)) {
		activate_toplevel_item (widget);
	}

	parse_menu_structure_helper(widget, &recurse);
}

/* A child item was removed from a menu we're watching. */
static void
item_removed_cb (GtkContainer *parent_w, GtkWidget *child_w, gpointer data)
{
  DbusmenuMenuitem * child_mi;

  if ((child_mi = dbusmenu_gtk_parse_get_cached_item (child_w)))
    {
      DbusmenuMenuitem * parent_mi;

      if ((parent_mi = dbusmenu_gtk_parse_get_cached_item (GTK_WIDGET(parent_w))))
        dbusmenu_menuitem_child_delete (parent_mi, child_mi); 

      disconnect_from_widget (child_w);
    }
}

static gboolean
should_show_image (GtkImage *image)
{
  GtkWidget *item;

  item = gtk_widget_get_ancestor (GTK_WIDGET (image),
                                  GTK_TYPE_IMAGE_MENU_ITEM);
  if (!item)
    item = gtk_widget_get_ancestor (GTK_WIDGET (image),
                                    GTK_TYPE_MENU_ITEM);

  if (item)
    {
      GtkSettings *settings;
      gboolean gtk_menu_images;

      settings = gtk_widget_get_settings (item);

      g_object_get (settings, "gtk-menu-images", &gtk_menu_images, NULL);

      if (gtk_menu_images)
        return TRUE;

      if (GTK_IS_IMAGE_MENU_ITEM (item))
        return gtk_image_menu_item_get_always_show_image (GTK_IMAGE_MENU_ITEM (item));
    }

  return FALSE;
}
