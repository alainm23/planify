/*
An object to ferry over properties and signals between two different
dbusmenu instances.  Useful for services.

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

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "menuitem-proxy.h"

struct _DbusmenuMenuitemProxyPrivate {
	DbusmenuMenuitem * mi;
	gulong sig_property_changed;
	gulong sig_child_added;
	gulong sig_child_removed;
	gulong sig_child_moved;
};

/* Properties */
enum {
	PROP_0,
	PROP_MENU_ITEM
};

#define PROP_MENU_ITEM_S   "menu-item"

#define DBUSMENU_MENUITEM_PROXY_GET_PRIVATE(o) (DBUSMENU_MENUITEM_PROXY(o)->priv)

static void dbusmenu_menuitem_proxy_class_init (DbusmenuMenuitemProxyClass *klass);
static void dbusmenu_menuitem_proxy_init       (DbusmenuMenuitemProxy *self);
static void dbusmenu_menuitem_proxy_dispose    (GObject *object);
static void dbusmenu_menuitem_proxy_finalize   (GObject *object);
static void set_property (GObject * obj, guint id, const GValue * value, GParamSpec * pspec);
static void get_property (GObject * obj, guint id, GValue * value, GParamSpec * pspec);
static void handle_event (DbusmenuMenuitem * mi, const gchar * name, GVariant * variant, guint timestamp);
static void add_menuitem (DbusmenuMenuitemProxy * pmi, DbusmenuMenuitem * mi);
static void remove_menuitem (DbusmenuMenuitemProxy * pmi);

G_DEFINE_TYPE (DbusmenuMenuitemProxy, dbusmenu_menuitem_proxy, DBUSMENU_TYPE_MENUITEM);

static void
dbusmenu_menuitem_proxy_class_init (DbusmenuMenuitemProxyClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	g_type_class_add_private (klass, sizeof (DbusmenuMenuitemProxyPrivate));

	object_class->dispose = dbusmenu_menuitem_proxy_dispose;
	object_class->finalize = dbusmenu_menuitem_proxy_finalize;
	object_class->set_property = set_property;
	object_class->get_property = get_property;

	DbusmenuMenuitemClass * miclass = DBUSMENU_MENUITEM_CLASS(klass);

	miclass->handle_event = handle_event;

	g_object_class_install_property (object_class, PROP_MENU_ITEM,
	                                 g_param_spec_object(PROP_MENU_ITEM_S, "The Menuitem we're proxying",
	                                                     "An instance of the DbusmenuMenuitem class that this menuitem will mimic.",
	                                                     DBUSMENU_TYPE_MENUITEM,
	                                                     G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS));

	return;
}

static void
dbusmenu_menuitem_proxy_init (DbusmenuMenuitemProxy *self)
{
	self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), DBUSMENU_TYPE_MENUITEM_PROXY, DbusmenuMenuitemProxyPrivate);

	DbusmenuMenuitemProxyPrivate * priv = DBUSMENU_MENUITEM_PROXY_GET_PRIVATE(self);

	priv->mi = NULL;

	priv->sig_property_changed = 0;
	priv->sig_child_added = 0;
	priv->sig_child_removed = 0;
	priv->sig_child_moved = 0;

	return;
}

/* Remove references to objects */
static void
dbusmenu_menuitem_proxy_dispose (GObject *object)
{
	remove_menuitem(DBUSMENU_MENUITEM_PROXY(object));

	G_OBJECT_CLASS (dbusmenu_menuitem_proxy_parent_class)->dispose (object);
	return;
}

/* Free any memory that we've allocated */
static void
dbusmenu_menuitem_proxy_finalize (GObject *object)
{

	G_OBJECT_CLASS (dbusmenu_menuitem_proxy_parent_class)->finalize (object);
	return;
}

/* Set a property using the generic GObject interface */
static void
set_property (GObject * obj, guint id, const GValue * value, GParamSpec * pspec)
{
	switch (id) {
	case PROP_MENU_ITEM: {
		GObject * lobj = g_value_get_object(value);
		add_menuitem(DBUSMENU_MENUITEM_PROXY(obj), DBUSMENU_MENUITEM(lobj));
		break;
	}
	default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID(obj, id, pspec);
		break;
	}

	return;
}

/* Get a property using the generic GObject interface */
static void
get_property (GObject * obj, guint id, GValue * value, GParamSpec * pspec)
{
	DbusmenuMenuitemProxyPrivate * priv = DBUSMENU_MENUITEM_PROXY_GET_PRIVATE(obj);

	switch (id) {
	case PROP_MENU_ITEM:
		g_value_set_object(value, priv->mi);
		break;
	default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID(obj, id, pspec);
		break;
	}

	return;
}

/* Takes the event and passes it along to the item that we're
   playing proxy for. */
static void
handle_event (DbusmenuMenuitem * mi, const gchar * name, GVariant * variant, guint timestamp)
{
	g_return_if_fail(DBUSMENU_IS_MENUITEM_PROXY(mi));
	DbusmenuMenuitemProxyPrivate * priv = DBUSMENU_MENUITEM_PROXY_GET_PRIVATE(mi);
	g_return_if_fail(priv->mi != NULL);
	return dbusmenu_menuitem_handle_event(priv->mi, name, variant, timestamp);
}

/* Watches a property change and makes sure to put that value
   into our property list. */
static void
proxy_item_property_changed (DbusmenuMenuitem * mi, gchar * property, GVariant * variant, gpointer user_data)
{
	DbusmenuMenuitemProxy * pmi = DBUSMENU_MENUITEM_PROXY(user_data);
	dbusmenu_menuitem_property_set_variant(DBUSMENU_MENUITEM(pmi), property, variant);
	return;
}

/* Looks for a child getting added and wraps it and places it
   in our list of children. */
static void
proxy_item_child_added (DbusmenuMenuitem * parent, DbusmenuMenuitem * child, guint position, gpointer user_data)
{
	DbusmenuMenuitemProxy * pmi = DBUSMENU_MENUITEM_PROXY(user_data);
	DbusmenuMenuitemProxy * child_pmi = dbusmenu_menuitem_proxy_new(child);
	dbusmenu_menuitem_child_add_position(DBUSMENU_MENUITEM(pmi), DBUSMENU_MENUITEM(child_pmi), position);
	g_object_unref (child_pmi);
	return;
}

/* Find the wrapper for this child and remove it as well. */
static void 
proxy_item_child_removed (DbusmenuMenuitem * parent, DbusmenuMenuitem * child, gpointer user_data)
{
	DbusmenuMenuitemProxy * pmi = DBUSMENU_MENUITEM_PROXY(user_data);
	GList * children = dbusmenu_menuitem_get_children(DBUSMENU_MENUITEM(pmi));
	DbusmenuMenuitemProxy * finalpmi = NULL;
	GList * childitem;

	for (childitem = children; childitem != NULL; childitem = g_list_next(childitem)) {
		DbusmenuMenuitemProxy * childpmi = (DbusmenuMenuitemProxy *)childitem->data;
		DbusmenuMenuitem * childmi = dbusmenu_menuitem_proxy_get_wrapped(childpmi);
		if (childmi == child) {
			finalpmi = childpmi;
			break;
		}
	}

	if (finalpmi != NULL) {
		dbusmenu_menuitem_child_delete(DBUSMENU_MENUITEM(pmi), DBUSMENU_MENUITEM(finalpmi));
	}

	return;
}

/* Find the wrapper for the item and move it in our child list */
static void 
proxy_item_child_moved (DbusmenuMenuitem * parent, DbusmenuMenuitem * child, guint newpos, guint oldpos, gpointer user_data)
{
	DbusmenuMenuitemProxy * pmi = DBUSMENU_MENUITEM_PROXY(user_data);
	GList * children = dbusmenu_menuitem_get_children(DBUSMENU_MENUITEM(pmi));
	DbusmenuMenuitemProxy * finalpmi = NULL;
	GList * childitem;

	for (childitem = children; childitem != NULL; childitem = g_list_next(childitem)) {
		DbusmenuMenuitemProxy * childpmi = (DbusmenuMenuitemProxy *)childitem->data;
		DbusmenuMenuitem * childmi = dbusmenu_menuitem_proxy_get_wrapped(childpmi);
		if (childmi == child) {
			finalpmi = childpmi;
			break;
		}
	}

	if (finalpmi != NULL) {
		dbusmenu_menuitem_child_reorder(DBUSMENU_MENUITEM(pmi), DBUSMENU_MENUITEM(finalpmi), newpos);
	}

	return;
}

/* Making g_object_unref into a GFunc */
static void
func_g_object_unref (gpointer data, gpointer user_data)
{
	return g_object_unref(G_OBJECT(data));
}

/* References all of the things we need for talking to this menuitem
   including signals and other data.  If the menuitem already has
   properties we need to signal that they've changed for us.  */
static void
add_menuitem (DbusmenuMenuitemProxy * pmi, DbusmenuMenuitem * mi)
{
	/* Put it in private */
	DbusmenuMenuitemProxyPrivate * priv = DBUSMENU_MENUITEM_PROXY_GET_PRIVATE(pmi);
	if (priv->mi != NULL) {
		remove_menuitem(pmi);
	}
	priv->mi = mi;
	g_object_ref(G_OBJECT(priv->mi));

	/* Attach signals */
	priv->sig_property_changed = g_signal_connect(G_OBJECT(priv->mi), DBUSMENU_MENUITEM_SIGNAL_PROPERTY_CHANGED, G_CALLBACK(proxy_item_property_changed), pmi);
	priv->sig_child_added =      g_signal_connect(G_OBJECT(priv->mi), DBUSMENU_MENUITEM_SIGNAL_CHILD_ADDED,      G_CALLBACK(proxy_item_child_added),      pmi);
	priv->sig_child_removed =    g_signal_connect(G_OBJECT(priv->mi), DBUSMENU_MENUITEM_SIGNAL_CHILD_REMOVED,    G_CALLBACK(proxy_item_child_removed),    pmi);
	priv->sig_child_moved =      g_signal_connect(G_OBJECT(priv->mi), DBUSMENU_MENUITEM_SIGNAL_CHILD_MOVED,      G_CALLBACK(proxy_item_child_moved),      pmi);

	/* Grab (cache) Properties */
	GList * props = dbusmenu_menuitem_properties_list(priv->mi);
	GList * prop;
	for (prop = props; prop != NULL; prop = g_list_next(prop)) {
		gchar * prop_name = (gchar *)prop->data;
		dbusmenu_menuitem_property_set_variant(DBUSMENU_MENUITEM(pmi), prop_name, dbusmenu_menuitem_property_get_variant(priv->mi, prop_name));
	}
	g_list_free(props);

	/* Go through children and wrap them */
	GList * children = dbusmenu_menuitem_get_children(priv->mi);
	GList * child;
	for (child = children; child != NULL; child = g_list_next(child)) {
		DbusmenuMenuitemProxy * child_pmi = dbusmenu_menuitem_proxy_new(DBUSMENU_MENUITEM(child->data));
		dbusmenu_menuitem_child_append(DBUSMENU_MENUITEM(pmi), DBUSMENU_MENUITEM(child_pmi));
		g_object_unref (child_pmi);
	}

	return;
}

/* Removes the menuitem from being our proxy.  Typically this isn't
   done until this object is destroyed, but who knows?!? */
static void
remove_menuitem (DbusmenuMenuitemProxy * pmi)
{
	DbusmenuMenuitemProxyPrivate * priv = DBUSMENU_MENUITEM_PROXY_GET_PRIVATE(pmi);
	if (priv->mi == NULL) {
		return;
	}

	/* Remove signals */
	if (priv->sig_property_changed != 0) {
		g_signal_handler_disconnect(G_OBJECT(priv->mi), priv->sig_property_changed);
	}
	if (priv->sig_child_added != 0) {
		g_signal_handler_disconnect(G_OBJECT(priv->mi), priv->sig_child_added);
	}
	if (priv->sig_child_removed != 0) {
		g_signal_handler_disconnect(G_OBJECT(priv->mi), priv->sig_child_removed);
	}
	if (priv->sig_child_moved != 0) {
		g_signal_handler_disconnect(G_OBJECT(priv->mi), priv->sig_child_moved);
	}

	/* Unref */
	g_object_unref(G_OBJECT(priv->mi));
	priv->mi = NULL;

	/* Remove our own children */
	GList * children = dbusmenu_menuitem_take_children(DBUSMENU_MENUITEM(pmi));
	g_list_foreach(children, func_g_object_unref, NULL);
	g_list_free(children);

	return;
}

/**
 * dbusmenu_menuitem_proxy_new:
 * @mi: The #DbusmenuMenuitem to proxy
 * 
 * Builds a new #DbusmenuMenuitemProxy object that proxies
 * all of the values for @mi.
 * 
 * Return value: A new #DbusmenuMenuitemProxy object.
 */
DbusmenuMenuitemProxy *
dbusmenu_menuitem_proxy_new (DbusmenuMenuitem * mi)
{
	DbusmenuMenuitemProxy * pmi = g_object_new(DBUSMENU_TYPE_MENUITEM_PROXY,
	                                           PROP_MENU_ITEM_S, mi,
	                                           NULL);

	return pmi;
}

/**
 * dbusmenu_menuitem_proxy_get_wrapped:
 * @pmi: #DbusmenuMenuitemProxy to look into
 * 
 * Accesses the private variable of which #DbusmenuMenuitem
 * we are doing the proxying for.
 * 
 * Return value: (transfer none): A #DbusmenuMenuitem object or a #NULL if we
 * 	don't have one or there is an error.
 */
DbusmenuMenuitem *
dbusmenu_menuitem_proxy_get_wrapped (DbusmenuMenuitemProxy * pmi)
{
	g_return_val_if_fail(DBUSMENU_MENUITEM_PROXY(pmi), NULL);
	DbusmenuMenuitemProxyPrivate * priv = DBUSMENU_MENUITEM_PROXY_GET_PRIVATE(pmi);
	return priv->mi;
}
