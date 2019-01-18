/*
A menuitem subclass that has the ability to do lots of different
things depending on its settings.

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

#include <gdk/gdk.h>

#include "genericmenuitem.h"

/*
	GenericmenuitemPrivate:
	@check_type: What type of check we have, or none at all.
	@state: What the state of our check is.
*/
struct _GenericmenuitemPrivate {
	GenericmenuitemCheckType   check_type;
	GenericmenuitemState       state;
	GenericmenuitemDisposition disposition;
	gchar * label_text;
};

/* Private macro */
#define GENERICMENUITEM_GET_PRIVATE(o) \
(G_TYPE_INSTANCE_GET_PRIVATE ((o), GENERICMENUITEM_TYPE, GenericmenuitemPrivate))

/* Prototypes */
static void genericmenuitem_class_init (GenericmenuitemClass *klass);
static void genericmenuitem_init       (Genericmenuitem *self);
static void genericmenuitem_dispose    (GObject *object);
static void genericmenuitem_finalize   (GObject *object);
static void set_label (GtkMenuItem * menu_item, const gchar * label);
static const gchar * get_label (GtkMenuItem * menu_item);
static void activate (GtkMenuItem * menu_item);

/* GObject stuff */
G_DEFINE_TYPE (Genericmenuitem, genericmenuitem, GTK_TYPE_CHECK_MENU_ITEM);

#if GTK_CHECK_VERSION(3,0,0)
static void draw_indicator (GtkCheckMenuItem *check_menu_item, cairo_t *cr);
static void (*parent_draw_indicator) (GtkCheckMenuItem *check_menu_item, cairo_t *cr) = NULL;
#else
static void draw_indicator (GtkCheckMenuItem *check_menu_item, GdkRectangle *area);
static void (*parent_draw_indicator) (GtkCheckMenuItem *check_menu_item, GdkRectangle *area) = NULL;
#endif
static void (*parent_menuitem_activate) (GtkMenuItem * mi) = NULL;

/* Initializing all of the classes.  Most notably we're
   disabling the drawing of the check early. */
static void
genericmenuitem_class_init (GenericmenuitemClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	g_type_class_add_private (klass, sizeof (GenericmenuitemPrivate));

	object_class->dispose = genericmenuitem_dispose;
	object_class->finalize = genericmenuitem_finalize;

#if GTK_CHECK_VERSION(3,2,0)
	GtkWidgetClass * widget_class = GTK_WIDGET_CLASS(klass);

	gtk_widget_class_set_accessible_role(widget_class, ATK_ROLE_MENU_ITEM);
#endif

	GtkCheckMenuItemClass * check_class = GTK_CHECK_MENU_ITEM_CLASS (klass);

	parent_draw_indicator = check_class->draw_indicator;
	check_class->draw_indicator = draw_indicator;

	GtkMenuItemClass * menuitem_class = GTK_MENU_ITEM_CLASS (klass);
	menuitem_class->set_label = set_label;
	menuitem_class->get_label = get_label;
	parent_menuitem_activate = menuitem_class->activate;
	menuitem_class->activate = activate;

	return;
}

/* Sets default values for all the class variables.  Mostly,
   this puts us in a default state. */
static void
genericmenuitem_init (Genericmenuitem *self)
{
	self->priv = GENERICMENUITEM_GET_PRIVATE(self);

	self->priv->check_type = GENERICMENUITEM_CHECK_TYPE_NONE;
	self->priv->state = GENERICMENUITEM_STATE_UNCHECKED;
	self->priv->disposition = GENERICMENUITEM_DISPOSITION_NORMAL;
	self->priv->label_text = NULL;

#if !GTK_CHECK_VERSION(3,0,0)
	AtkObject * aobj = gtk_widget_get_accessible(GTK_WIDGET(self));
	if (aobj != NULL) {
		atk_object_set_role(aobj, ATK_ROLE_MENU_ITEM);
	}
#endif

	return;
}

/* Clean everything up.  Whew, that can be work. */
static void
genericmenuitem_dispose (GObject *object)
{

	G_OBJECT_CLASS (genericmenuitem_parent_class)->dispose (object);
	return;
}

/* Now free memory, we no longer need it. */
static void
genericmenuitem_finalize (GObject *object)
{
	Genericmenuitem * self = GENERICMENUITEM(object);
	g_free(self->priv->label_text);

	G_OBJECT_CLASS (genericmenuitem_parent_class)->finalize (object);
	return;
}

/* Checks to see if we should be drawing a little box at
   all.  If we should be, let's do that, otherwise we're
   going suppress the box drawing. */
#if GTK_CHECK_VERSION(3,0,0)
static void
draw_indicator (GtkCheckMenuItem *check_menu_item, cairo_t *cr)
{
	Genericmenuitem * self = GENERICMENUITEM(check_menu_item);
	if (self->priv->check_type != GENERICMENUITEM_CHECK_TYPE_NONE) {
		parent_draw_indicator(check_menu_item, cr);
	}
	return;
}
#else
static void
draw_indicator (GtkCheckMenuItem *check_menu_item, GdkRectangle *area)
{
	Genericmenuitem * self = GENERICMENUITEM(check_menu_item);
	if (self->priv->check_type != GENERICMENUITEM_CHECK_TYPE_NONE) {
		parent_draw_indicator(check_menu_item, area);
	}
	return;
}
#endif

/* A small helper to look through the widgets in the
   box and find the one that is the label. */
static void
set_label_helper (GtkWidget * widget, gpointer data)
{
	GtkWidget ** labelval = (GtkWidget **)data;
	if (GTK_IS_LABEL(widget)) {
		*labelval = widget;
	}
	return;
}

/* A quick little function to grab the padding from the
   style.  It should be considered for caching when
   optimizing. */
static gint
get_toggle_space (GtkWidget * widget)
{
	gint padding = 0;
	gtk_widget_style_get(widget, "toggle-spacing", &padding, NULL);
	return padding;
}

/* Get the value to put in the span for the disposition */
static gchar *
get_text_color (GenericmenuitemDisposition disposition, GtkWidget * widget)
{
	struct {const gchar * color_name; const gchar * default_color;} values[] = {
		/* NORMAL */ { NULL, NULL},
		/* INFO   */ { "informational-color", "blue"},
		/* WARN   */ { "warning-color", "orange"},
		/* ALERT  */ { "error-color", "red"}
	};

#if GTK_CHECK_VERSION(3, 0, 0)
	GtkStyleContext * context = gtk_widget_get_style_context(widget);
	GdkRGBA color;

	if (gtk_style_context_lookup_color(context, values[disposition].color_name, &color)) {
		return g_strdup_printf("rgb(%d, %d, %d)", (gint)(color.red * 255), (gint)(color.green * 255), (gint)(color.blue * 255));
	}
#endif

	return g_strdup(values[disposition].default_color);
}

/* Check to see if we've got mnemonic stuff goin' on */
static gboolean
has_mnemonic (const gchar * string, gboolean previous_underscore)
{
	if (string == NULL || string[0] == '\0') {
		return FALSE;
	}

	if (g_utf8_get_char(string) == '_') {
		if (previous_underscore) {
			return has_mnemonic(g_utf8_next_char(string), FALSE);
		} else {
			return has_mnemonic(g_utf8_next_char(string), TRUE);
		}
	} else {
		if (previous_underscore) {
			return TRUE;
		} else {
			return has_mnemonic(g_utf8_next_char(string), FALSE);
		}
	}

	return FALSE;
}

/* Sanitize the label by removing "__" meaning "_" */
static gchar *
sanitize_label (const gchar * in_label)
{
	static GRegex * underscore_regex = NULL;

	g_return_val_if_fail(in_label != NULL, NULL);

	if (underscore_regex == NULL) {
		underscore_regex = g_regex_new("__", 0, 0, NULL);
	}

	return g_regex_replace_literal(underscore_regex,
	                               in_label,
	                               -1,    /* length */
	                               0,     /* start */
	                               "_",   /* replacement */
	                               0,     /* flags */
	                               NULL); /* error */
}

/* Set the label on the item */
static void
set_label (GtkMenuItem * menu_item, const gchar * in_label)
{
	if (in_label == NULL) return;

	Genericmenuitem * item = GENERICMENUITEM(menu_item);
	if (in_label != item->priv->label_text) {
		g_free(item->priv->label_text);
		item->priv->label_text = g_strdup(in_label);
	}

	/* Build a label that might include the colors of the disposition
	   so that it gets rendered in the menuitem. */
	gchar * local_label = NULL;
	switch (GENERICMENUITEM(menu_item)->priv->disposition) {
	case GENERICMENUITEM_DISPOSITION_NORMAL:
		local_label = g_markup_escape_text(in_label, -1);
		break;
	case GENERICMENUITEM_DISPOSITION_INFORMATIONAL:
	case GENERICMENUITEM_DISPOSITION_WARNING:
	case GENERICMENUITEM_DISPOSITION_ALERT: {
		gchar * color = get_text_color(GENERICMENUITEM(menu_item)->priv->disposition, GTK_WIDGET(menu_item));
		local_label = g_markup_printf_escaped("<span fgcolor=\"%s\">%s</span>", color, in_label);
		g_free(color);
		break;
	}
	default:
		g_warn_if_reached();
		break;
	}

	GtkWidget * child = gtk_bin_get_child(GTK_BIN(menu_item));
	GtkLabel * labelw = NULL;
	gboolean suppress_update = FALSE;

	/* Try to find if we have a label already */
	if (child != NULL) {
		if (GTK_IS_LABEL(child)) {
			/* We've got a label, let's update it. */
			labelw = GTK_LABEL(child);
		} else if (GTK_IS_BOX(child)) {
			/* Look for the label in the box */
			gtk_container_foreach(GTK_CONTAINER(child), set_label_helper, &labelw);
		} else {
			/* We need to put the child into a new box and
			   make the box the child of the menu item.  Basically
			   we're inserting a box in the middle. */
#if GTK_CHECK_VERSION(3,0,0)
			GtkWidget * hbox = gtk_box_new(GTK_ORIENTATION_HORIZONTAL,
			                               get_toggle_space(GTK_WIDGET(menu_item)));
#else
			GtkWidget * hbox = gtk_hbox_new(FALSE, get_toggle_space(GTK_WIDGET(menu_item)));
#endif
			g_object_ref(child);
			gtk_container_remove(GTK_CONTAINER(menu_item), child);
			gtk_box_pack_start(GTK_BOX(hbox), child, FALSE, FALSE, 0);
			gtk_container_add(GTK_CONTAINER(menu_item), hbox);
			gtk_widget_show(hbox);
			g_object_unref(child);
			child = hbox;
			/* It's important to notice that labelw is not set
			   by this condition.  There was no label to find. */
		}
	}

	/* No we can see if we need to ethier build a label or just
	   update the one that we already have. */
	if (labelw == NULL) {
		/* Build it */
		labelw = GTK_LABEL(gtk_accel_label_new(local_label));
		gtk_label_set_use_markup(GTK_LABEL(labelw), TRUE);
#if GTK_CHECK_VERSION(3,0,0)
		gtk_widget_set_halign(GTK_WIDGET(labelw), GTK_ALIGN_START);
		gtk_widget_set_valign(GTK_WIDGET(labelw), GTK_ALIGN_CENTER);
#else
		gtk_misc_set_alignment(GTK_MISC(labelw), 0.0, 0.5);
#endif
		gtk_accel_label_set_accel_widget(GTK_ACCEL_LABEL(labelw), GTK_WIDGET(menu_item));

		if (has_mnemonic(in_label, FALSE)) {
			gtk_label_set_use_underline(GTK_LABEL(labelw), TRUE);
			gtk_label_set_markup_with_mnemonic(labelw, local_label);
		} else {
			gchar * sanitized = sanitize_label(local_label);
			gtk_label_set_markup(labelw, sanitized);
			g_free(sanitized);
		}

		gtk_widget_show(GTK_WIDGET(labelw));

		/* Check to see if it needs to be in the bin for this
		   menu item or whether it gets packed in a box. */
		if (child == NULL) {
			gtk_container_add(GTK_CONTAINER(menu_item), GTK_WIDGET(labelw));
		} else {
			gtk_box_pack_end(GTK_BOX(child), GTK_WIDGET(labelw), TRUE, TRUE, 0);
		}
	} else {
		/* Oh, just an update.  No biggie. */
		if (!g_strcmp0(local_label, gtk_label_get_label(labelw))) {
			/* The only reason to suppress the update is if we had
			   a label and the value was the same as the one we're
			   getting in. */
			suppress_update = TRUE;
		} else {
			if (has_mnemonic(in_label, FALSE)) {
				gtk_label_set_use_underline(GTK_LABEL(labelw), TRUE);
				gtk_label_set_markup_with_mnemonic(labelw, local_label);
			} else {
				gchar * sanitized = sanitize_label(local_label);
				gtk_label_set_markup(labelw, sanitized);
				g_free(sanitized);
			}
		}
	}

	/* If we changed the value, tell folks. */
	if (!suppress_update) {
		g_object_notify(G_OBJECT(menu_item), "label");
	}

	/* Clean up this */
	if (local_label != NULL) {
		g_free(local_label);
		local_label = NULL;
	}

	return;
}

/* Get the text of the label for the item */
static const gchar *
get_label (GtkMenuItem * menu_item)
{
	Genericmenuitem * item = GENERICMENUITEM(menu_item);

	return item->priv->label_text;
}

/* Make sure we don't toggle when there is an
   activate like a normal check menu item. */
static void
activate (GtkMenuItem * menu_item)
{
	return;
}

/**
 * genericmenuitem_set_check_type:
 * @item: #Genericmenuitem to set the type on
 * @check_type: Which type of check should be displayed
 * 
 * This function changes the type of the checkmark that
 * appears in the left hand gutter for the menuitem.
*/
void
genericmenuitem_set_check_type (Genericmenuitem * item, GenericmenuitemCheckType check_type)
{
	if (item->priv->check_type == check_type) {
		return;
	}

	item->priv->check_type = check_type;
	AtkObject * aobj = gtk_widget_get_accessible(GTK_WIDGET(item));

	switch (item->priv->check_type) {
	case GENERICMENUITEM_CHECK_TYPE_NONE:
		/* We don't need to do anything here as we're queuing the
		   draw and then when it draws it'll avoid drawing the
		   check on the item. */

		if (aobj != NULL) {
			atk_object_set_role(aobj, ATK_ROLE_MENU_ITEM);
		}
		break;
	case GENERICMENUITEM_CHECK_TYPE_CHECKBOX:
		gtk_check_menu_item_set_draw_as_radio(GTK_CHECK_MENU_ITEM(item), FALSE);
		if (aobj != NULL) {
			atk_object_set_role(aobj, ATK_ROLE_CHECK_MENU_ITEM);
		}
		break;
	case GENERICMENUITEM_CHECK_TYPE_RADIO:
		gtk_check_menu_item_set_draw_as_radio(GTK_CHECK_MENU_ITEM(item), TRUE);
		if (aobj != NULL) {
			atk_object_set_role(aobj, ATK_ROLE_RADIO_MENU_ITEM);
		}
		break;
	default:
		g_warning("Generic Menuitem invalid check type: %d", check_type);
		return;
	}

	gtk_widget_queue_draw(GTK_WIDGET(item));

	return;
}

/**
 * genericmenuitem_set_state:
 * @item: #Genericmenuitem to set the type on
 * @check_type: What is the state of the check 
 * 
 * Sets the state of the check in the menu item.  It does
 * not require, but isn't really useful if the type of
 * check that the menuitem is set to #GENERICMENUITEM_CHECK_TYPE_NONE.
 */
void
genericmenuitem_set_state (Genericmenuitem * item, GenericmenuitemState state)
{
	if (item->priv->state == state) {
		return;
	}

	item->priv->state = state;

	GtkCheckMenuItem * check = GTK_CHECK_MENU_ITEM(item);
	gboolean goal_active = FALSE;

	switch (item->priv->state) {
	case GENERICMENUITEM_STATE_UNCHECKED:
		goal_active = FALSE;
		gtk_check_menu_item_set_inconsistent (check, FALSE);
		break;
	case GENERICMENUITEM_STATE_CHECKED:
		goal_active = TRUE;
		gtk_check_menu_item_set_inconsistent (check, FALSE);
		break;
	case GENERICMENUITEM_STATE_INDETERMINATE:
		goal_active = TRUE;
		gtk_check_menu_item_set_inconsistent (check, TRUE);
		break;
	default:
		g_warning("Generic Menuitem invalid check state: %d", state);
		return;
	}

	if (goal_active != gtk_check_menu_item_get_active(check)) {
		if (parent_menuitem_activate != NULL) {
			parent_menuitem_activate(GTK_MENU_ITEM(check));
		}
	}

	return;
}

/* A small helper to look through the widgets in the
   box and find the one that is the image. */
static void
set_image_helper (GtkWidget * widget, gpointer data)
{
	GtkWidget ** labelval = (GtkWidget **)data;
	if (GTK_IS_IMAGE(widget)) {
		*labelval = widget;
	}
	return;
}

/**
 * genericmenuitem_set_image:
 * @item: A #Genericmenuitem
 * @image: The image to set as the image of @item
 * 
 * Sets the image of the menu item.
*/
void
genericmenuitem_set_image (Genericmenuitem * menu_item, GtkWidget * image)
{
	GtkWidget * child = gtk_bin_get_child(GTK_BIN(menu_item));
	GtkImage * imagew = NULL;

	/* Try to find if we have a label already */
	if (child != NULL) {
		if (GTK_IS_IMAGE(child)) {
			/* We've got a label, let's update it. */
			imagew = GTK_IMAGE(child);
			child = NULL;
		} else if (GTK_IS_BOX(child)) {
			/* Look for the label in the box */
			gtk_container_foreach(GTK_CONTAINER(child), set_image_helper, &imagew);
		} else if (image != NULL) {
			/* We need to put the child into a new box and
			   make the box the child of the menu item.  Basically
			   we're inserting a box in the middle. */
#if GTK_CHECK_VERSION(3,0,0)
			GtkWidget * hbox = gtk_box_new(GTK_ORIENTATION_HORIZONTAL,
			                               get_toggle_space(GTK_WIDGET(menu_item)));
#else
			GtkWidget * hbox = gtk_hbox_new(FALSE, get_toggle_space(GTK_WIDGET(menu_item)));
#endif
			g_object_ref(child);
			gtk_container_remove(GTK_CONTAINER(menu_item), child);
			gtk_box_pack_end(GTK_BOX(hbox), child, TRUE, TRUE, 0);
			gtk_container_add(GTK_CONTAINER(menu_item), hbox);
			gtk_widget_show(hbox);
			g_object_unref(child);
			child = hbox;
			/* It's important to notice that imagew is not set
			   by this condition.  There was no label to find. */
		}
	}

        if (image == (GtkWidget *)imagew)
          return;

	/* No we can see if we need to ethier replace and image or
	   just put ourselves into the structures */
	if (imagew != NULL) {
		gtk_widget_destroy(GTK_WIDGET(imagew));
	}

	/* Check to see if it needs to be in the bin for this
	   menu item or whether it gets packed in a box. */
	if (image != NULL) {
		if (child == NULL) {
			gtk_container_add(GTK_CONTAINER(menu_item), GTK_WIDGET(image));
		} else {
			gtk_box_pack_start(GTK_BOX(child), GTK_WIDGET(image), FALSE, FALSE, 0);
		}

		gtk_widget_show(image);
	}

	return;
}

/**
 * genericmenuitem_get_image:
 * @item: A #Genericmenuitem
 * 
 * Returns the image if there is one.
 * 
 * Return value: (transfer none): A pointer to the image of the item or #NULL
 * 	if there isn't one.
*/
GtkWidget *
genericmenuitem_get_image (Genericmenuitem * menu_item)
{
	GtkWidget * child = gtk_bin_get_child(GTK_BIN(menu_item));
	GtkWidget * imagew = NULL;

	/* Try to find if we have a label already */
	if (child != NULL) {
		if (GTK_IS_IMAGE(child)) {
			/* We've got a label, let's update it. */
			imagew = child;
		} else if (GTK_IS_BOX(child)) {
			/* Look for the label in the box */
			gtk_container_foreach(GTK_CONTAINER(child), set_image_helper, &imagew);
		}
	}

	return imagew;
}

/**
 * genericmenuitem_set_disposition:
 * @item: A #Genericmenuitem
 * @disposition: The disposition of the item
 * 
 * Sets the disposition of the menuitem.
 */
void
genericmenuitem_set_disposition (Genericmenuitem * item, GenericmenuitemDisposition disposition)
{
	g_return_if_fail(IS_GENERICMENUITEM(item));

	if (item->priv->disposition == disposition)
		return;

	item->priv->disposition = disposition;
	
	set_label(GTK_MENU_ITEM(item), get_label(GTK_MENU_ITEM(item)));

	return;
}

/**
 * genericmenuitem_get_disposition:
 * @item: A #Genericmenuitem
 * 
 * Gets the disposition of the menuitem.
 *
 * Return value: The disposition of the menuitem.
 */
GenericmenuitemDisposition
genericmenuitem_get_disposition (Genericmenuitem * item)
{
	g_return_val_if_fail(IS_GENERICMENUITEM(item), GENERICMENUITEM_DISPOSITION_NORMAL);

	return item->priv->disposition;
}
