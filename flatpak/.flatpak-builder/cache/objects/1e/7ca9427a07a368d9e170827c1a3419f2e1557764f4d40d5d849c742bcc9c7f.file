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

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <gio/gio.h>

#include "client.h"
#include "client-private.h"
#include "menuitem.h"
#include "menuitem-private.h"
#include "client-menuitem.h"
#include "server-marshal.h"
#include "client-marshal.h"
#include "dbus-menu-clean.xml.h"
#include "enum-types.h"

/* How many property requests should we queue before
   sending the message on dbus */
#define MAX_PROPERTIES_TO_QUEUE  100

/* Properties */
enum {
	PROP_0,
	PROP_DBUSOBJECT,
	PROP_DBUSNAME,
	PROP_STATUS,
	PROP_TEXT_DIRECTION,
	PROP_GROUP_EVENTS
};

/* Signals */
enum {
	LAYOUT_UPDATED,
	ROOT_CHANGED,
	NEW_MENUITEM,
	ITEM_ACTIVATE,
	EVENT_RESULT,
	ICON_THEME_DIRS,
	LAST_SIGNAL
};

/* Errors */
enum {
	ERROR_DISPOSAL,
	ERROR_ID_NOT_FOUND
};

typedef void (*properties_func) (GVariant * properties, GError * error, gpointer user_data);

static guint signals[LAST_SIGNAL] = { 0 };

struct _DbusmenuClientPrivate
{
	DbusmenuMenuitem * root;
	
	gchar * dbus_object;
	gchar * dbus_name;

	GDBusConnection * session_bus;
	GCancellable * session_bus_cancel;

	GDBusProxy * menuproxy;
	GCancellable * menuproxy_cancel;

	GCancellable * layoutcall;
	GVariant * layout_props;

	gint current_revision;
	gint my_revision;

	guint dbusproxy;

	GHashTable * type_handlers;

	GArray * delayed_property_list;
	GArray * delayed_property_listeners;
	gint delayed_idle;

	DbusmenuTextDirection text_direction;
	DbusmenuStatus status;
	GStrv icon_dirs;

	gboolean group_events;
	guint event_idle;
	GQueue * events_to_go; /* type: event_data_t * */

	guint about_to_show_idle;
	GQueue * about_to_show_to_go; /* type: about_to_show_t * */
};

typedef struct _newItemPropData newItemPropData;
struct _newItemPropData
{
	DbusmenuClient * client;
	DbusmenuMenuitem * item;
	DbusmenuMenuitem * parent;
};

typedef struct _properties_listener_t properties_listener_t;
struct _properties_listener_t {
	gint id;
	properties_func callback;
	gpointer user_data;
	gboolean replied;
};

typedef struct _event_data_t event_data_t;
struct _event_data_t {
	gint id;
	DbusmenuClient * client;
	DbusmenuMenuitem * menuitem;
	gchar * event;
	GVariant * variant;
	guint timestamp;
};

typedef struct _type_handler_t type_handler_t;
struct _type_handler_t {
	DbusmenuClient * client;
	DbusmenuClientTypeHandler cb;
	GDestroyNotify destroy_cb;
	gpointer user_data;
	gchar * type;
};

typedef struct _properties_callback_t properties_callback_t;
struct _properties_callback_t {
	DbusmenuClient * client;
	GArray * listeners;
};


#define DBUSMENU_CLIENT_GET_PRIVATE(o) (DBUSMENU_CLIENT(o)->priv)
#define DBUSMENU_INTERFACE  "com.canonical.dbusmenu"

/* GObject Stuff */
static void dbusmenu_client_class_init (DbusmenuClientClass *klass);
static void dbusmenu_client_init       (DbusmenuClient *self);
static void dbusmenu_client_dispose    (GObject *object);
static void dbusmenu_client_finalize   (GObject *object);
static void set_property (GObject * obj, guint id, const GValue * value, GParamSpec * pspec);
static void get_property (GObject * obj, guint id, GValue * value, GParamSpec * pspec);
/* Private Funcs */
static void layout_update (GDBusProxy * proxy, guint revision, gint parent, DbusmenuClient * client);
static void id_prop_update (GDBusProxy * proxy, gint id, gchar * property, GVariant * value, DbusmenuClient * client);
static void id_update (GDBusProxy * proxy, gint id, DbusmenuClient * client);
static void build_proxies (DbusmenuClient * client);
static DbusmenuMenuitem * parse_layout_xml(DbusmenuClient * client, GVariant * layout, DbusmenuMenuitem * item, DbusmenuMenuitem * parent, GDBusProxy * proxy);
static gint parse_layout (DbusmenuClient * client, GVariant * layout);
static void update_layout_cb (GObject * proxy, GAsyncResult * res, gpointer data);
static void update_layout (DbusmenuClient * client);
static void menuitem_get_properties_cb (GVariant * properties, GError * error, gpointer data);
static void get_properties_globber (DbusmenuClient * client, gint id, const gchar ** properties, properties_func callback, gpointer user_data);
static GQuark error_domain (void);
static void item_activated (GDBusProxy * proxy, gint id, guint timestamp, DbusmenuClient * client);
static void menuproxy_build_cb (GObject * object, GAsyncResult * res, gpointer user_data);
static void menuproxy_prop_changed_cb (GDBusProxy * proxy, GVariant * properties, GStrv invalidated, gpointer user_data);
static void menuproxy_name_changed_cb (GObject * object, GParamSpec * pspec, gpointer user_data);
static void menuproxy_signal_cb (GDBusProxy * proxy, gchar * sender, gchar * signal, GVariant * params, gpointer user_data);
static void type_handler_destroy (gpointer user_data);
static void event_data_end (event_data_t * eventd, GError * error);
static void about_to_show_finish_pntr (gpointer data, gpointer user_data);

/* Globals */
static GDBusNodeInfo *            dbusmenu_node_info = NULL;
static GDBusInterfaceInfo *       dbusmenu_interface_info = NULL;

/* Build a type */
G_DEFINE_TYPE (DbusmenuClient, dbusmenu_client, G_TYPE_OBJECT);

static void
dbusmenu_client_class_init (DbusmenuClientClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	g_type_class_add_private (klass, sizeof (DbusmenuClientPrivate));

	object_class->dispose = dbusmenu_client_dispose;
	object_class->finalize = dbusmenu_client_finalize;
	object_class->set_property = set_property;
	object_class->get_property = get_property;

	/**
		DbusmenuClient::layout-update:
		@arg0: The #DbusmenuClient object

		Tells that the layout has been updated and parsed by
		this object and is ready for grabbing by the calling
		application.
	*/
	signals[LAYOUT_UPDATED]  = g_signal_new(DBUSMENU_CLIENT_SIGNAL_LAYOUT_UPDATED,
	                                        G_TYPE_FROM_CLASS (klass),
	                                        G_SIGNAL_RUN_LAST,
	                                        G_STRUCT_OFFSET (DbusmenuClientClass, layout_updated),
	                                        NULL, NULL,
	                                        g_cclosure_marshal_VOID__VOID,
	                                        G_TYPE_NONE, 0, G_TYPE_NONE);
	/**
		DbusmenuClient::root-changed:
		@arg0: The #DbusmenuClient object
		@arg1: The new root #DbusmenuMenuitem

		The layout has changed in a way that can not be
		represented by the individual items changing as the
		root of this client has changed.
	*/
	signals[ROOT_CHANGED]    = g_signal_new(DBUSMENU_CLIENT_SIGNAL_ROOT_CHANGED,
	                                        G_TYPE_FROM_CLASS (klass),
	                                        G_SIGNAL_RUN_LAST,
	                                        G_STRUCT_OFFSET (DbusmenuClientClass, root_changed),
	                                        NULL, NULL,
	                                        g_cclosure_marshal_VOID__OBJECT,
	                                        G_TYPE_NONE, 1, G_TYPE_OBJECT);
	/**
		DbusmenuClient::new-menuitem:
		@arg0: The #DbusmenuClient object
		@arg1: The new #DbusmenuMenuitem created

		Signaled when the client creates a new menuitem.  This
		doesn't mean that it's placed anywhere.  The parent that
		it's applied to will signal #DbusmenuMenuitem::child-added
		when it gets parented.
	*/
	signals[NEW_MENUITEM]    = g_signal_new(DBUSMENU_CLIENT_SIGNAL_NEW_MENUITEM,
	                                        G_TYPE_FROM_CLASS (klass),
	                                        G_SIGNAL_RUN_LAST,
	                                        G_STRUCT_OFFSET (DbusmenuClientClass, new_menuitem),
	                                        NULL, NULL,
	                                        g_cclosure_marshal_VOID__OBJECT,
	                                        G_TYPE_NONE, 1, G_TYPE_OBJECT);
	/**
		DbusmenuClient::item-activate:
		@arg0: The #DbusmenuClient object
		@arg1: The #DbusmenuMenuitem activated
		@arg2: A timestamp that the event happened at

		Signaled when the server wants to activate an item in
		order to display the menu.
	*/
	signals[ITEM_ACTIVATE]   = g_signal_new(DBUSMENU_CLIENT_SIGNAL_ITEM_ACTIVATE,
	                                        G_TYPE_FROM_CLASS (klass),
	                                        G_SIGNAL_RUN_LAST,
	                                        G_STRUCT_OFFSET (DbusmenuClientClass, item_activate),
	                                        NULL, NULL,
	                                        _dbusmenu_client_marshal_VOID__OBJECT_UINT,
	                                        G_TYPE_NONE, 2, G_TYPE_OBJECT, G_TYPE_UINT);
	/**
		DbusmenuClient::event-error:
		@arg0: The #DbusmenuClient object
		@arg1: The #DbusmenuMenuitem sent an event
		@arg2: The ID of the event sent
		@arg3: The data sent along with the event
		@arg4: A timestamp that the event happened at
		@arg5: Possibly the error in sending the event (or NULL)

		Signal sent to show that there was an error in sending the event
		to the server.
	*/
	signals[EVENT_RESULT]    = g_signal_new(DBUSMENU_CLIENT_SIGNAL_EVENT_RESULT,
	                                        G_TYPE_FROM_CLASS (klass),
	                                        G_SIGNAL_RUN_LAST,
	                                        G_STRUCT_OFFSET (DbusmenuClientClass, event_result),
	                                        NULL, NULL,
	                                        _dbusmenu_client_marshal_VOID__OBJECT_STRING_VARIANT_UINT_POINTER,
	                                        G_TYPE_NONE, 5, G_TYPE_OBJECT, G_TYPE_STRING, G_TYPE_VARIANT, G_TYPE_UINT, G_TYPE_POINTER);
	/**
		DbusmenuClient::icon-theme-dirs-changed:
		@arg0: The #DbusmenuClient object
		@arg1: A #GStrv of theme directories

		Signaled when the theme directories are changed by the server.
	*/
	signals[ICON_THEME_DIRS] = g_signal_new(DBUSMENU_CLIENT_SIGNAL_ICON_THEME_DIRS_CHANGED,
	                                        G_TYPE_FROM_CLASS (klass),
	                                        G_SIGNAL_RUN_LAST,
	                                        G_STRUCT_OFFSET (DbusmenuClientClass, icon_theme_dirs),
	                                        NULL, NULL,
	                                        _dbusmenu_client_marshal_VOID__POINTER,
	                                        G_TYPE_NONE, 1, G_TYPE_POINTER);

	g_object_class_install_property (object_class, PROP_DBUSOBJECT,
	                                 g_param_spec_string(DBUSMENU_CLIENT_PROP_DBUS_OBJECT, "DBus Object we represent",
	                                              "The Object on the client that we're getting our data from.",
	                                              NULL,
	                                              G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS));
	g_object_class_install_property (object_class, PROP_DBUSNAME,
	                                 g_param_spec_string(DBUSMENU_CLIENT_PROP_DBUS_NAME, "DBus Client we connect to",
	                                              "Name of the DBus client we're connecting to.",
	                                              NULL,
	                                              G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS));
	g_object_class_install_property (object_class, PROP_STATUS,
	                                 g_param_spec_enum(DBUSMENU_CLIENT_PROP_STATUS, "Status of viewing the menus",
	                                              "Whether the menus should be given special visuals",
	                                              DBUSMENU_TYPE_STATUS, DBUSMENU_STATUS_NORMAL,
	                                              G_PARAM_READABLE | G_PARAM_STATIC_STRINGS));
	g_object_class_install_property (object_class, PROP_TEXT_DIRECTION,
	                                 g_param_spec_enum(DBUSMENU_CLIENT_PROP_TEXT_DIRECTION, "Direction text values have",
	                                              "Signals which direction the default text direction is for the menus",
	                                              DBUSMENU_TYPE_TEXT_DIRECTION, DBUSMENU_TEXT_DIRECTION_NONE,
	                                              G_PARAM_READABLE | G_PARAM_STATIC_STRINGS));
	g_object_class_install_property (object_class, PROP_GROUP_EVENTS,
	                                 g_param_spec_boolean(DBUSMENU_CLIENT_PROP_GROUP_EVENTS, "Whether or not multiple events should be grouped",
	                                              "Event grouping lowers the number of messages on DBus and will be set automatically based on the version to optimize traffic.  It can be disabled for testing or other purposes.",
	                                              FALSE, G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

	if (dbusmenu_node_info == NULL) {
		GError * error = NULL;

		dbusmenu_node_info = g_dbus_node_info_new_for_xml(dbus_menu_clean_xml, &error);
		if (error != NULL) {
			g_error("Unable to parse DBusmenu Interface description: %s", error->message);
			g_error_free(error);
		}
	}

	if (dbusmenu_interface_info == NULL) {
		dbusmenu_interface_info = g_dbus_node_info_lookup_interface(dbusmenu_node_info, DBUSMENU_INTERFACE);

		if (dbusmenu_interface_info == NULL) {
			g_error("Unable to find interface '" DBUSMENU_INTERFACE "'");
		}
	}

	return;
}

#define LAYOUT_PROPS_COUNT  6

static void
dbusmenu_client_init (DbusmenuClient *self)
{
	self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), DBUSMENU_TYPE_CLIENT, DbusmenuClientPrivate);

	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(self);

	priv->root = NULL;

	priv->dbus_object = NULL;
	priv->dbus_name = NULL;

	priv->session_bus = NULL;
	priv->session_bus_cancel = NULL;

	priv->menuproxy = NULL;
	priv->menuproxy_cancel = NULL;

	priv->layoutcall = NULL;

	gchar * layout_props[LAYOUT_PROPS_COUNT + 1];
	layout_props[0] = DBUSMENU_MENUITEM_PROP_TYPE;
	layout_props[1] = DBUSMENU_MENUITEM_PROP_LABEL;
	layout_props[2] = DBUSMENU_MENUITEM_PROP_VISIBLE;
	layout_props[3] = DBUSMENU_MENUITEM_PROP_ENABLED;
	layout_props[4] = DBUSMENU_MENUITEM_PROP_CHILD_DISPLAY;
	layout_props[5] = DBUSMENU_MENUITEM_PROP_ACCESSIBLE_DESC;
	layout_props[LAYOUT_PROPS_COUNT] = NULL;
	priv->layout_props = g_variant_new_strv((const gchar * const *)layout_props, LAYOUT_PROPS_COUNT);
	g_variant_ref_sink(priv->layout_props);

	priv->current_revision = 0;
	priv->my_revision = 0;

	priv->dbusproxy = 0;

	priv->type_handlers = g_hash_table_new_full(g_str_hash, g_str_equal,
	                                            g_free, type_handler_destroy);

	priv->delayed_idle = 0;
	priv->delayed_property_list = g_array_new(TRUE, FALSE, sizeof(gchar *));
	priv->delayed_property_listeners = g_array_new(FALSE, FALSE, sizeof(properties_listener_t));

	priv->text_direction = DBUSMENU_TEXT_DIRECTION_NONE;
	priv->status = DBUSMENU_STATUS_NORMAL;
	priv->icon_dirs = NULL;

	priv->group_events = FALSE;
	priv->event_idle = 0;
	priv->events_to_go = NULL;

	priv->about_to_show_idle = 0;
	priv->about_to_show_to_go = NULL;

	return;
}

static void
dbusmenu_client_dispose (GObject *object)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(object);

	if (priv->delayed_idle != 0) {
		g_source_remove(priv->delayed_idle);
		priv->delayed_idle = 0;
	}

	if (priv->event_idle != 0) {
		g_source_remove(priv->event_idle);
		priv->event_idle = 0;
	}

	if (priv->about_to_show_idle != 0) {
		g_source_remove(priv->about_to_show_idle);
		priv->about_to_show_idle = 0;
	}

	if (priv->events_to_go != NULL) {
		g_warning("Getting to client dispose with events pending.  This is odd.  Probably there's a ref count problem somewhere, but we're going to be cool about it now and clean up.  But there's probably a bug.");
		GError * error = g_error_new_literal(error_domain(), ERROR_DISPOSAL, "Client disposed before event signal returned");
		g_queue_foreach(priv->events_to_go, (GFunc)event_data_end, error);
		g_queue_free(priv->events_to_go);
		priv->events_to_go = NULL;
		g_error_free(error);
	}

	if (priv->about_to_show_to_go != NULL) {
		g_warning("Getting to client dispose with about_to_show's pending.  This is odd.  Probably there's a ref count problem somewhere, but we're going to be cool about it now and clean up.  But there's probably a bug.");
		g_queue_foreach(priv->about_to_show_to_go, about_to_show_finish_pntr, GINT_TO_POINTER(FALSE));
		g_queue_free(priv->about_to_show_to_go);
		priv->about_to_show_to_go = NULL;
	}

	/* Only used for queueing up a new command, so we can
	   just drop this array. */
	if (priv->delayed_property_list != NULL) {
		gchar ** dataregion = (gchar **)g_array_free(priv->delayed_property_list, FALSE);
		if (dataregion != NULL) {
			g_strfreev(dataregion);
		}
		priv->delayed_property_list = NULL;
	}

	if (priv->delayed_property_listeners != NULL) {
		gint i;
		GError * localerror = NULL;

		/* Making sure all the callbacks get called so that if they had
		   memory in their user_data that needs to be free'd that happens. */
		for (i = 0; i < priv->delayed_property_listeners->len; i++) {
			properties_listener_t * listener = &g_array_index(priv->delayed_property_listeners, properties_listener_t, i);
			if (!listener->replied) {
				if (localerror == NULL) {
					g_set_error_literal(&localerror, error_domain(), 0, "DbusmenuClient Shutdown");
				}
				listener->callback(NULL, localerror, listener->user_data);
			}
		}
		if (localerror != NULL) {
			g_error_free(localerror);
		}

		g_array_free(priv->delayed_property_listeners, TRUE);
		priv->delayed_property_listeners = NULL;
	}

	if (priv->layoutcall != NULL) {
		g_cancellable_cancel(priv->layoutcall);
		g_object_unref(priv->layoutcall);
		priv->layoutcall = NULL;
	}

	if (priv->layout_props != NULL) {
		g_variant_unref(priv->layout_props);
		priv->layout_props = NULL;
	}

	/* Bring down the menu proxy, ensure we're not
	   looking for one at the same time. */
	if (priv->menuproxy_cancel != NULL) {
		g_cancellable_cancel(priv->menuproxy_cancel);
		g_object_unref(priv->menuproxy_cancel);
		priv->menuproxy_cancel = NULL;
	}
	if (priv->menuproxy != NULL) {
		g_signal_handlers_disconnect_matched(priv->menuproxy,
		                                     G_SIGNAL_MATCH_DATA,
		                                     0, 0, NULL, NULL, object);
		g_object_unref(G_OBJECT(priv->menuproxy));
		priv->menuproxy = NULL;
	}

	if (priv->dbusproxy != 0) {
		g_bus_unwatch_name(priv->dbusproxy);
		priv->dbusproxy = 0;
	}

	/* Bring down the session bus, ensure we're not
	   looking for one at the same time. */
	if (priv->session_bus_cancel != NULL) {
		g_cancellable_cancel(priv->session_bus_cancel);
		g_object_unref(priv->session_bus_cancel);
		priv->session_bus_cancel = NULL;
	}
	if (priv->session_bus != NULL) {
		g_object_unref(priv->session_bus);
		priv->session_bus = NULL;
	}

	if (priv->root != NULL) {
		g_object_unref(G_OBJECT(priv->root));
		priv->root = NULL;
	}

	G_OBJECT_CLASS (dbusmenu_client_parent_class)->dispose (object);
	return;
}

static void
dbusmenu_client_finalize (GObject *object)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(object);

	g_free(priv->dbus_name);
	g_free(priv->dbus_object);

	if (priv->type_handlers != NULL) {
		g_hash_table_destroy(priv->type_handlers);
	}

	if (priv->icon_dirs != NULL) {
		g_strfreev(priv->icon_dirs);
		priv->icon_dirs = NULL;
	}

	G_OBJECT_CLASS (dbusmenu_client_parent_class)->finalize (object);
	return;
}

static void
set_property (GObject * obj, guint id, const GValue * value, GParamSpec * pspec)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(obj);

	switch (id) {
	case PROP_DBUSNAME:
		g_return_if_fail(g_dbus_is_name(g_value_get_string(value)));

		priv->dbus_name = g_value_dup_string(value);
		if (priv->dbus_name != NULL && priv->dbus_object != NULL) {
			build_proxies(DBUSMENU_CLIENT(obj));
		}
		break;
	case PROP_DBUSOBJECT:
		g_return_if_fail(g_variant_is_object_path(g_value_get_string(value)));

		priv->dbus_object = g_value_dup_string(value);
		if (priv->dbus_name != NULL && priv->dbus_object != NULL) {
			build_proxies(DBUSMENU_CLIENT(obj));
		}
		break;
	case PROP_GROUP_EVENTS:
		priv->group_events = g_value_get_boolean(value);
		break;
	default:
		g_warning("Unknown property %d.", id);
		return;
	}

	return;
}

static void
get_property (GObject * obj, guint id, GValue * value, GParamSpec * pspec)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(obj);

	switch (id) {
	case PROP_DBUSNAME:
		g_value_set_string(value, priv->dbus_name);
		break;
	case PROP_DBUSOBJECT:
		g_value_set_string(value, priv->dbus_object);
		break;
	case PROP_STATUS:
		g_value_set_enum(value, priv->status);
		break;
	case PROP_TEXT_DIRECTION:
		g_value_set_enum(value, priv->text_direction);
		break;
	case PROP_GROUP_EVENTS:
		g_value_set_boolean(value, priv->group_events);
		break;
	default:
		g_warning("Unknown property %d.", id);
		return;
	}

	return;
}

/* Internal funcs */

static GQuark
error_domain (void)
{
	static GQuark error = 0;
	if (error == 0) {
		error = g_quark_from_static_string(G_LOG_DOMAIN "-CLIENT");
	}
	return error;
}

/* Quick little function to search through the listeners and find
   one that matches an ID */
static properties_listener_t *
find_listener (GArray * listeners, guint index, gint id)
{
	if (index >= listeners->len) {
		return NULL;
	}

	properties_listener_t * retval = &g_array_index(listeners, properties_listener_t, index);
	if (retval->id == id) {
		return retval;
	}

	return find_listener(listeners, index + 1, id);
}

/* Call back from getting the group properties, now we need
   to unwind and call the various functions. */
static void 
get_properties_callback (GObject *obj, GAsyncResult * res, gpointer user_data)
{
	properties_callback_t * cbdata = (properties_callback_t *)user_data;
	GArray * listeners = cbdata->listeners;
	int i;
	GError * error = NULL;
	GVariant * params = NULL;

	params = g_dbus_proxy_call_finish(G_DBUS_PROXY(obj), res, &error);

	if (error != NULL) {
		/* If we get an error, all our callbacks need to hear about it. */
		g_warning("Group Properties error: %s", error->message);
		for (i = 0; i < listeners->len; i++) {
			properties_listener_t * listener = &g_array_index(listeners, properties_listener_t, i);
			listener->callback(NULL, error, listener->user_data);
		}
		g_error_free(error);
	}

	/* Callback all the folks we can find */
	if (error == NULL) {
		GVariant * parent = g_variant_get_child_value(params, 0);
		GVariantIter iter;
		g_variant_iter_init(&iter, parent);
		GVariant * child;
		while ((child = g_variant_iter_next_value(&iter)) != NULL) {
			if (g_strcmp0(g_variant_get_type_string(child), "(ia{sv})") != 0) {
				g_warning("Properties return signature is not '(ia{sv})' it is '%s'", g_variant_get_type_string(child));
				g_variant_unref(child);
				continue;
			}

			GVariant * idv = g_variant_get_child_value(child, 0);
			gint id = g_variant_get_int32(idv);
			g_variant_unref(idv);

			GVariant * properties = g_variant_get_child_value(child, 1);

			properties_listener_t * listener = find_listener(listeners, 0, id);
			if (listener == NULL) {
				g_warning("Unable to find listener for ID %d", id);
				g_variant_unref(properties);
				g_variant_unref(child);
				continue;
			}

			if (!listener->replied) {
				listener->callback(properties, NULL, listener->user_data);
				listener->replied = TRUE;
			} else {
				g_warning("Odd, we've already replied to the listener on ID %d", id);
			}
			g_variant_unref(properties);
			g_variant_unref(child);
		}
		g_variant_unref(parent);
		g_variant_unref(params);
	}

	/* Provide errors for those who we can't */
	if (error == NULL && listeners->len > 0) {
		GError * localerror = NULL;
		for (i = 0; i < listeners->len; i++) {
			properties_listener_t * listener = &g_array_index(listeners, properties_listener_t, i);
			if (!listener->replied) {
				g_debug("Generating properties error for: %d", listener->id);
				if (localerror == NULL) {
					g_set_error_literal(&localerror, error_domain(), 0, "Error getting properties for ID");
				}
				listener->callback(NULL, localerror, listener->user_data);
			}
		}
		if (localerror != NULL) {
			g_error_free(localerror);
		}
	}

	/* Clean up */
	g_array_free(listeners, TRUE);
	g_object_unref(cbdata->client);
	g_free(user_data);

	return;
}

/* Idle handler to send out all of our property requests as one big
   lovely property request. */
static gboolean
get_properties_idle (gpointer user_data)
{
	properties_callback_t * cbdata = NULL;
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(user_data);
	g_return_val_if_fail(priv->menuproxy != NULL, TRUE);

	if (priv->delayed_property_listeners->len == 0) {
		g_warning("Odd, idle func got no listeners.");
		return FALSE;
	}

	/* Build up an ID list to pass */
	GVariantBuilder builder;
	g_variant_builder_init(&builder, G_VARIANT_TYPE_ARRAY);

	gint i;
	for (i = 0; i < priv->delayed_property_listeners->len; i++) {
		g_variant_builder_add(&builder, "i", g_array_index(priv->delayed_property_listeners, properties_listener_t, i).id);
	}

	GVariant * variant_ids = g_variant_builder_end(&builder);

	/* Build up a prop list to pass */
	GVariantType * type = g_variant_type_new("as");
	g_variant_builder_init(&builder, type);
	g_variant_type_free(type);
	/* TODO: need to use delayed property list here */
	GVariant * variant_props = g_variant_builder_end(&builder);

	/* Combine them into a value for the parameter */
	g_variant_builder_init(&builder, G_VARIANT_TYPE_TUPLE);
	g_variant_builder_add_value(&builder, variant_ids);
	g_variant_builder_add_value(&builder, variant_props);
	GVariant * variant_params = g_variant_builder_end(&builder);

	cbdata = g_new(properties_callback_t, 1);
	cbdata->listeners = priv->delayed_property_listeners;
	cbdata->client = DBUSMENU_CLIENT(user_data);
	g_object_ref(G_OBJECT(user_data));

	g_dbus_proxy_call(priv->menuproxy,
	                  "GetGroupProperties",
	                  variant_params,
	                  G_DBUS_CALL_FLAGS_NONE,
	                  -1,   /* timeout */
	                  NULL, /* cancellable */
	                  get_properties_callback,
	                  cbdata);

	/* Free properties */
	gchar ** dataregion = (gchar **)g_array_free(priv->delayed_property_list, FALSE);
	if (dataregion != NULL) {
		g_strfreev(dataregion);
	}
	priv->delayed_property_list = g_array_new(TRUE, FALSE, sizeof(gchar *));

	/* Rebuild the listeners */
	priv->delayed_property_listeners = g_array_new(FALSE, FALSE, sizeof(properties_listener_t));

	/* Make sure we set for a new idle */
	priv->delayed_idle = 0;

	return FALSE;
}

/* Forces a call out to start getting properties with the menu items
   that we have queued up already. */
static void
get_properties_flush (DbusmenuClient * client)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);

	if (priv->delayed_idle == 0) {
		return;
	}

	g_source_remove(priv->delayed_idle);
	priv->delayed_idle = 0;

	get_properties_idle(client);

	return;
}

/* A function to group all the get_properties commands to make them
   more efficient over dbus. */
static void
get_properties_globber (DbusmenuClient * client, gint id, const gchar ** properties, properties_func callback, gpointer user_data)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);
	if (find_listener(priv->delayed_property_listeners, 0, id) != NULL) {
		g_warning("Asking for properties from same ID twice: %d", id);
		GError * localerror = NULL;
		g_set_error_literal(&localerror, error_domain(), 0, "ID already queued");
		callback(NULL, localerror, user_data);
		g_error_free(localerror);
		return;
	}

	if (properties == NULL || properties[0] == NULL) {
		/* get all case */
		if (priv->delayed_property_list->len != 0) {
			/* If there are entries in the list, then we'll need to
			   remove them all, and start over */
			gchar ** dataregion = (gchar **)g_array_free(priv->delayed_property_list, FALSE);
			if (dataregion != NULL) {
				g_strfreev(dataregion);
			}
			priv->delayed_property_list = g_array_new(TRUE, FALSE, sizeof(gchar *));
		}
	} else {
		/* there could be a list we care about */
		/* TODO: No one uses this today */
		/* TODO: Copy them into the list */
	}

	properties_listener_t listener = {0};
	listener.id = id;
	listener.callback = callback;
	listener.user_data = user_data;
	listener.replied = FALSE;

	g_array_append_val(priv->delayed_property_listeners, listener);

	if (priv->delayed_idle == 0) {
		priv->delayed_idle = g_idle_add(get_properties_idle, client);
	}

	/* Look at how many proprites we have queued up and
	   make it so that we don't leave too many in one
	   request. */
	if (priv->delayed_property_listeners->len == MAX_PROPERTIES_TO_QUEUE) {
		get_properties_flush(client);
	}

	return;
}

/* Called when a server item wants to activate the menu */
static void
item_activated (GDBusProxy * proxy, gint id, guint timestamp, DbusmenuClient * client)
{
	g_return_if_fail(DBUSMENU_IS_CLIENT(client));

	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);

	if (priv->root == NULL) {
		g_warning("Asked to activate item %d when we don't have a menu structure.", id);
		return;
	}

	DbusmenuMenuitem * menuitem = dbusmenu_menuitem_find_id(priv->root, id);
	if (menuitem == NULL) {
		g_warning("Unable to find menu item %d to activate.", id);
		return;
	}

	g_signal_emit(G_OBJECT(client), signals[ITEM_ACTIVATE], 0, menuitem, timestamp, TRUE);

	return;
}

/* Annoying little wrapper to make the right function update */
static void
layout_update (GDBusProxy * proxy, guint revision, gint parent, DbusmenuClient * client)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);
	priv->current_revision = revision;
	if (priv->current_revision > priv->my_revision) {
		update_layout(client);
	}
	return;
}

/* Signal from the server that a property has changed
   on one of our menuitems */
static void
id_prop_update (GDBusProxy * proxy, gint id, gchar * property, GVariant * value, DbusmenuClient * client)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);

	g_return_if_fail(priv->root != NULL);

	DbusmenuMenuitem * menuitem = dbusmenu_menuitem_find_id(priv->root, id);
	if (menuitem == NULL) {
		#ifdef MASSIVEDEBUGGING
		g_debug("Property update '%s' on id %d which couldn't be found", property, id);
		#endif
		return;
	}

	dbusmenu_menuitem_property_set_variant(menuitem, property, value);

	return;
}

/* Oh, lots of updates now.  That silly server, they want
   to change all kinds of stuff! */
static void
id_update (GDBusProxy * proxy, gint id, DbusmenuClient * client)
{
	#ifdef MASSIVEDEBUGGING
	g_debug("Client side ID update: %d", id);
	#endif 

	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);
	g_return_if_fail(priv->root != NULL);

	DbusmenuMenuitem * menuitem = dbusmenu_menuitem_find_id(priv->root, id);
	g_return_if_fail(menuitem != NULL);

	g_debug("Getting properties");
	g_object_ref(menuitem);
	get_properties_globber(client, id, NULL, menuitem_get_properties_cb, menuitem);
	return;
}

/* Watches to see if our DBus savior comes onto the bus */
static void
dbus_owner_change (GDBusConnection * connection, const gchar * name, const gchar * owner, gpointer user_data)
{
	g_return_if_fail(DBUSMENU_IS_CLIENT(user_data));

	DbusmenuClient * client = DBUSMENU_CLIENT(user_data);

	/* Woot!  A service for us to love and to hold for ever
	   and ever and ever! */
	return build_proxies(client);
}

/* This function builds the DBus proxy which will look out for
   the service coming up. */
static void
build_dbus_proxy (DbusmenuClient * client)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);

	if (priv->dbusproxy != 0) {
		return;
	}

	priv->dbusproxy = g_bus_watch_name_on_connection(priv->session_bus,
	                                                 priv->dbus_name,
	                                                 G_BUS_NAME_WATCHER_FLAGS_NONE,
	                                                 dbus_owner_change,
	                                                 NULL,
	                                                 client,
	                                                 NULL);

	/* Now let's check to make sure we're not in some race
	   condition case. */
	/* TODO: Not sure how to check for names in GDBus */

	return;
}

/* A signal handler that gets called when a proxy is destoryed a
   so it needs to clean up a little.  Make sure we don't think we
   have a layout and setup the dbus watcher. */
static void
proxy_destroyed (GObject * gobj_proxy, gpointer userdata)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(userdata);

	if (priv->root != NULL) {
		g_object_unref(G_OBJECT(priv->root));
		priv->root = NULL;
		#ifdef MASSIVEDEBUGGING
		g_debug("Proxies destroyed, signaling a root change and a layout update.");
		#endif
		g_signal_emit(G_OBJECT(userdata), signals[ROOT_CHANGED], 0, NULL, TRUE);
		g_signal_emit(G_OBJECT(userdata), signals[LAYOUT_UPDATED], 0, TRUE);
	}

	if ((gpointer)priv->menuproxy == (gpointer)gobj_proxy) {
		if (priv->layoutcall != NULL) {
			g_cancellable_cancel(priv->layoutcall);
			g_object_unref(priv->layoutcall);
			priv->layoutcall = NULL;
		}
	}

	priv->current_revision = 0;
	priv->my_revision = 0;

	build_dbus_proxy(DBUSMENU_CLIENT(userdata));
	return;
}

/* Respond to us getting the session bus (hopefully) or handle
   the error if not */
static void
session_bus_cb (GObject * object, GAsyncResult * res, gpointer user_data)
{
	GError * error = NULL;

	/* NOTE: We're not using any other variables before checking
	   the result because they could be destroyed and thus invalid */
	GDBusConnection * bus = g_bus_get_finish(res, &error);
	if (error != NULL) {
		g_warning("Unable to get session bus: %s", error->message);
		g_error_free(error);
		return;
	}

	/* If this wasn't cancelled, we should be good */
	DbusmenuClient * client = DBUSMENU_CLIENT(user_data);
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);
	priv->session_bus = bus;

	if (priv->session_bus_cancel != NULL) {
		g_object_unref(priv->session_bus_cancel);
		priv->session_bus_cancel = NULL;
	}

	/* Retry to build the proxies now that we have a bus */
	build_proxies(DBUSMENU_CLIENT(user_data));

	return;
}

/* When we have a name and an object, build the two proxies and get the
   first version of the layout */
static void
build_proxies (DbusmenuClient * client)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);

	g_return_if_fail(priv->dbus_object != NULL);
	g_return_if_fail(priv->dbus_name != NULL);

	if (priv->session_bus == NULL) {
		/* We don't have the session bus yet, that's okay, but
		   we need to handle that. */

		/* If we're already running we don't need to look again. */
		if (priv->session_bus_cancel == NULL) {
			priv->session_bus_cancel = g_cancellable_new();

			/* Async get the session bus */
			g_bus_get(G_BUS_TYPE_SESSION, priv->session_bus_cancel, session_bus_cb, client);
		}

		/* This function exists, it'll be called again when we get
		   the session bus so this condition will be ignored */
		return;
	}

	/* Build us a menu proxy */
	if (priv->menuproxy == NULL) {

		/* Check to see if we're already building one */
		if (priv->menuproxy_cancel == NULL) {
			priv->menuproxy_cancel = g_cancellable_new();

			g_dbus_proxy_new(priv->session_bus,
			                 G_DBUS_PROXY_FLAGS_DO_NOT_AUTO_START,
			                 dbusmenu_interface_info,
			                 priv->dbus_name,
			                 priv->dbus_object,
			                 DBUSMENU_INTERFACE,
			                 priv->menuproxy_cancel,
			                 menuproxy_build_cb,
			                 client);
		}
	}

	return;
}

/* Callback when we know if the menu proxy can be created or
   not and do something with it! */
static void
menuproxy_build_cb (GObject * object, GAsyncResult * res, gpointer user_data)
{
	GError * error = NULL;

	/* NOTE: We're not using any other variables before checking
	   the result because they could be destroyed and thus invalid */
	GDBusProxy * proxy = g_dbus_proxy_new_finish(res, &error);
	if (error != NULL) {
		g_warning("Unable to get menu proxy: %s", error->message);
		g_error_free(error);
		return;
	}

	/* If this wasn't cancelled, we should be good */
	DbusmenuClient * client = DBUSMENU_CLIENT(user_data);
	/* But let's check */
	g_return_if_fail(client != NULL);
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);
	g_return_if_fail(priv != NULL);


	priv->menuproxy = proxy;

	if (priv->menuproxy_cancel != NULL) {
		g_object_unref(priv->menuproxy_cancel);
		priv->menuproxy_cancel = NULL;
	}

	/* Check the text direction if available */
	GVariant * textdir = g_dbus_proxy_get_cached_property(priv->menuproxy, "TextDirection");
	if (textdir != NULL) {
		if (g_variant_is_of_type(textdir, G_VARIANT_TYPE_VARIANT)) {
			GVariant * tmp =  g_variant_get_variant(textdir);
			g_variant_unref(textdir);
			textdir = tmp;
		}

		priv->text_direction = dbusmenu_text_direction_get_value_from_nick(g_variant_get_string(textdir, NULL));
		g_object_notify(G_OBJECT(user_data), DBUSMENU_CLIENT_PROP_TEXT_DIRECTION);

		g_variant_unref(textdir);
		textdir = NULL;
	}

	/* Check the status if available */
	GVariant * status = g_dbus_proxy_get_cached_property(priv->menuproxy, "Status");
	if (status != NULL) {
		if (g_variant_is_of_type(status, G_VARIANT_TYPE_VARIANT)) {
			GVariant * tmp = g_variant_get_variant(status);
			g_variant_unref(status);
			status = tmp;
		}

		priv->status = dbusmenu_status_get_value_from_nick(g_variant_get_string(status, NULL));
		g_object_notify(G_OBJECT(user_data), DBUSMENU_CLIENT_PROP_STATUS);

		g_variant_unref(status);
		status = NULL;
	}

	/* Get the icon theme directories if available */
	GVariant * icon_dirs = g_dbus_proxy_get_cached_property(priv->menuproxy, "IconThemePath");
	if (icon_dirs != NULL) {
		if (priv->icon_dirs != NULL) {
			g_strfreev(priv->icon_dirs);
			priv->icon_dirs = NULL;
		}

		priv->icon_dirs = g_variant_dup_strv(icon_dirs, NULL);
		g_signal_emit(G_OBJECT(client), signals[ICON_THEME_DIRS], 0, priv->icon_dirs, TRUE);

		g_variant_unref(icon_dirs);
		icon_dirs = NULL;
	}

	/* Get the dbusmenu protocol version if available */
	GVariant * version = g_dbus_proxy_get_cached_property(priv->menuproxy, "Version");
	if (version != NULL) {
		guint32 remote_version = 0;

		if (g_variant_is_of_type(version, G_VARIANT_TYPE_UINT32)) {
			remote_version = g_variant_get_uint32(version);
		}

		gboolean old_group = priv->group_events;
		/* Figure out if we can group the events or not */
		if (remote_version >= 3) {
			priv->group_events = TRUE;
		} else {
			priv->group_events = FALSE;
		}

		/* Notify listeners if we changed the value */
		if (old_group != priv->group_events) {
			g_object_notify(G_OBJECT(client), DBUSMENU_CLIENT_PROP_GROUP_EVENTS);
		}

		g_variant_unref(version);
		version = NULL;
	}

	/* If we get here, we don't need the DBus proxy */
	if (priv->dbusproxy != 0) {
		g_bus_unwatch_name(priv->dbusproxy);
		priv->dbusproxy = 0;
	}

	g_signal_connect(priv->menuproxy, "g-signal",             G_CALLBACK(menuproxy_signal_cb),       client);
	g_signal_connect(priv->menuproxy, "notify::g-name-owner", G_CALLBACK(menuproxy_name_changed_cb), client);
	g_signal_connect(priv->menuproxy, "g-properties-changed", G_CALLBACK(menuproxy_prop_changed_cb), client);

	gchar * name_owner = g_dbus_proxy_get_name_owner(priv->menuproxy);
	if (name_owner != NULL) {
		update_layout(client);
		g_free(name_owner);
	}

	return;
}

/* Handle the properites changing */
static void
menuproxy_prop_changed_cb (GDBusProxy * proxy, GVariant * properties, GStrv invalidated, gpointer user_data)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(user_data);
	DbusmenuTextDirection olddir = priv->text_direction;
	DbusmenuStatus oldstatus = priv->status;
	gboolean dirs_changed = FALSE;

	/* Invalidate first */
	gchar * invalid;
	gint i = 0;
	for (invalid = invalidated[i]; invalid != NULL; invalid = invalidated[++i]) {
		if (g_strcmp0(invalid, "TextDirection") == 0) {
			priv->text_direction = DBUSMENU_TEXT_DIRECTION_NONE;
		}
		if (g_strcmp0(invalid, "Status") == 0) {
			priv->status = DBUSMENU_STATUS_NORMAL;
		}
		if (g_strcmp0(invalid, "IconThemePath") == 0) {
			if (priv->icon_dirs != NULL) {
				dirs_changed = TRUE;
				g_strfreev(priv->icon_dirs);
				priv->icon_dirs = NULL;
			}
		}
	}

	/* Check updates */
	GVariantIter iters;
	gchar * key; GVariant * value;
	g_variant_iter_init(&iters, properties);
	while (g_variant_iter_loop(&iters, "{sv}", &key, &value)) {
		if (g_strcmp0(key, "TextDirection") == 0) {
			if (g_variant_is_of_type(value, G_VARIANT_TYPE_VARIANT)) {
				GVariant * tmp = g_variant_get_variant(value);
				g_variant_unref(value);
				value = tmp;
			}

			priv->text_direction = dbusmenu_text_direction_get_value_from_nick(g_variant_get_string(value, NULL));
		}
		if (g_strcmp0(key, "Status") == 0) {
			if (g_variant_is_of_type(value, G_VARIANT_TYPE_VARIANT)) {
				GVariant * tmp = g_variant_get_variant(value);
				g_variant_unref(value);
				value = tmp;
			}

			priv->status = dbusmenu_status_get_value_from_nick(g_variant_get_string(value, NULL));
		}
		if (g_strcmp0(key, "IconThemePath") == 0) {
			if (priv->icon_dirs != NULL) {
				g_strfreev(priv->icon_dirs);
				priv->icon_dirs = NULL;
			}

			priv->icon_dirs = g_variant_dup_strv(value, NULL);
			dirs_changed = TRUE;
		}
		if (g_strcmp0(key, "Version") == 0) {
			guint32 remote_version = 0;

			if (g_variant_is_of_type(value, G_VARIANT_TYPE_UINT32)) {
				remote_version = g_variant_get_uint32(value);
			}

			if (remote_version >= 3) {
				priv->group_events = TRUE;
			} else {
				priv->group_events = FALSE;
			}
		}
	}

	if (olddir != priv->text_direction) {
		g_object_notify(G_OBJECT(user_data), DBUSMENU_CLIENT_PROP_TEXT_DIRECTION);
	}

	if (oldstatus != priv->status) {
		g_object_notify(G_OBJECT(user_data), DBUSMENU_CLIENT_PROP_STATUS);
	}

	if (dirs_changed) {
		g_signal_emit(G_OBJECT(user_data), signals[ICON_THEME_DIRS], 0, priv->icon_dirs, TRUE);
	}

	return;
}

/* Handle the case where we change owners */
static void
menuproxy_name_changed_cb (GObject * object, GParamSpec * pspec, gpointer user_data)
{
	GDBusProxy * proxy = G_DBUS_PROXY(object);

	gchar * owner = g_dbus_proxy_get_name_owner(proxy);

	if (owner == NULL) {
		/* Oh, no!  We lost our owner! */
		proxy_destroyed(G_OBJECT(proxy), user_data);
	} else {
		g_free(owner);
		update_layout(DBUSMENU_CLIENT(user_data));
	}

	return;
}

/* Handle the signals out of the proxy */
static void
menuproxy_signal_cb (GDBusProxy * proxy, gchar * sender, gchar * signal, GVariant * params, gpointer user_data)
{
	g_return_if_fail(DBUSMENU_IS_CLIENT(user_data));
	DbusmenuClient * client = DBUSMENU_CLIENT(user_data);
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);

	if (g_strcmp0(signal, "LayoutUpdated") == 0) {
		guint revision; gint parent;
		g_variant_get(params, "(ui)", &revision, &parent);
		layout_update(proxy, revision, parent, client);
	} else if (priv->root == NULL) {
		/* Drop out here, all the rest of these really need to have a root
		   node so we can just ignore them if there isn't one. */
	} else if (g_strcmp0(signal, "ItemsPropertiesUpdated") == 0) {
		/* Remove before adding just incase there is a duplicate, against the
		   rules, but we can handle it so let's do it. */
		GVariantIter ritems;
		GVariant * ritemsv = g_variant_get_child_value(params, 1);
		g_variant_iter_init(&ritems, ritemsv);

		GVariant * ritem;
		while ((ritem = g_variant_iter_next_value(&ritems)) != NULL) {
			GVariant * idv = g_variant_get_child_value(ritem, 0);
			gint id = g_variant_get_int32(idv);
			g_variant_unref(idv);
			DbusmenuMenuitem * menuitem = dbusmenu_menuitem_find_id(priv->root, id);

			if (menuitem == NULL) {
				continue;
			}

			GVariantIter properties;
			GVariant * propv = g_variant_get_child_value(ritem, 1);
			g_variant_iter_init(&properties, propv);
			gchar * property;

			while (g_variant_iter_loop(&properties, "s", &property)) {
				/* g_debug("Removing property '%s' on %d", property, id); */
				dbusmenu_menuitem_property_remove(menuitem, property);
			}
			g_variant_unref(ritem);
			g_variant_unref(propv);
		}
		g_variant_unref(ritemsv);

		GVariantIter items;
		GVariant * itemsv = g_variant_get_child_value(params, 0);
		g_variant_iter_init(&items, itemsv);

		GVariant * item;
		while ((item = g_variant_iter_next_value(&items)) != NULL) {
			GVariant * idv = g_variant_get_child_value(item, 0);
			gint id = g_variant_get_int32(idv);
			g_variant_unref(idv);

			GVariantIter properties;
			GVariant * propv = g_variant_get_child_value(item, 1);
			g_variant_iter_init(&properties, propv);
			gchar * property;
			GVariant * value;

			while (g_variant_iter_loop(&properties, "{sv}", &property, &value)) {
				GVariant * internalvalue = value;
				if (G_LIKELY(g_variant_is_of_type(value, G_VARIANT_TYPE_VARIANT))) {
					/* Unboxing if needed */
					internalvalue = g_variant_get_variant(value);
				}

				id_prop_update(proxy, id, property, internalvalue, client);

				if (internalvalue != value) {
					/* If we unboxed, we need to drop it, otherwise the
					   iter_loop function will unref for us */
					g_variant_unref(internalvalue);
				}
			}
			g_variant_unref(propv);
			g_variant_unref(item);
		}
		g_variant_unref(itemsv);
	} else if (g_strcmp0(signal, "ItemPropertyUpdated") == 0) {
		gint id; gchar * property; GVariant * value;
		g_variant_get(params, "(isv)", &id, &property, &value);
		id_prop_update(proxy, id, property, value, client);
		g_free(property);
		g_variant_unref(value);
	} else if (g_strcmp0(signal, "ItemUpdated") == 0) {
		gint id;
		g_variant_get(params, "(i)", &id);
		id_update(proxy, id, client);
	} else if (g_strcmp0(signal, "ItemActivationRequested") == 0) {
		gint id; guint timestamp;
		g_variant_get(params, "(iu)", &id, &timestamp);
		item_activated(proxy, id, timestamp, client);
	} else {
		g_warning("Received signal '%s' from menu proxy that is unknown", signal);
	}

	return;
}

/* This is the callback for the properties on a menu item.  There
   should be all of them in the Hash, and they we use foreach to
   copy them into the menuitem.
   This isn't the most efficient way.  We can optimize this by
   somehow removing the foreach.  But that is for later.  */
static void
menuitem_get_properties_cb (GVariant * properties, GError * error, gpointer data)
{
	g_return_if_fail(DBUSMENU_IS_MENUITEM(data));
	DbusmenuMenuitem * item = DBUSMENU_MENUITEM(data);

	if (error != NULL) {
		g_warning("Error getting properties on a menuitem: %s", error->message);
		goto out;
	}

	if (properties == NULL) {
		goto out;
	}

	if (!g_variant_is_of_type(properties, G_VARIANT_TYPE("a{sv}"))) {
		g_warning("Properties are of type '%s' instead of type '%s'", g_variant_get_type_string(properties), "a{sv}");
		goto out;
	}

	GVariantIter iter;
	gchar * key;
	GVariant * value;

	g_variant_iter_init(&iter, properties);

	while (g_variant_iter_loop(&iter, "{sv}", &key, &value)) {
		dbusmenu_menuitem_property_set_variant(item, key, value);
	}

out:
	g_object_unref(data);

	return;
}

/* This function is called to refresh the properites on an item that
   is getting recycled with the update, but we think might have prop
   changes. */
static void
menuitem_get_properties_replace_cb (GVariant * properties, GError * error, gpointer data)
{
	g_return_if_fail(DBUSMENU_IS_MENUITEM(data));
	gboolean have_error = FALSE;

	if (error != NULL) {
		g_warning("Unable to replace properties on %d: %s", dbusmenu_menuitem_get_id(DBUSMENU_MENUITEM(data)), error->message);
		have_error = TRUE;
	}
	
	if (properties == NULL) {
		have_error = TRUE;
	}

	/* Get the list of the current properties */
	GList * current_props = dbusmenu_menuitem_properties_list(DBUSMENU_MENUITEM(data));
	GList * tmp = NULL;

	if (!have_error && g_variant_is_of_type(properties, G_VARIANT_TYPE("a{sv}"))) {
		GVariantIter iter;
		g_variant_iter_init(&iter, properties);
		gchar * name; GVariant * value;

		/* Remove the entries from the current list that we have new
		   values for.  This way we don't create signals of them being
		   removed with the duplication of the value being changed. */
		while (g_variant_iter_loop(&iter, "{sv}", &name, &value)) {
			for (tmp = current_props; tmp != NULL; tmp = g_list_next(tmp)) {
				if (g_strcmp0((gchar *)tmp->data, name) == 0) {
					current_props = g_list_delete_link(current_props, tmp);
					break;
				}
			}
		}
	}

	/* Remove all entries that we're not getting values for, we can
	   assume that they no longer exist */
	for (tmp = current_props; tmp != NULL && have_error == FALSE; tmp = g_list_next(tmp)) {
		dbusmenu_menuitem_property_remove(DBUSMENU_MENUITEM(data), (const gchar *)tmp->data);
	}
	g_list_free(current_props);

	if (!have_error) {
		menuitem_get_properties_cb(properties, error, data);
	} else {
		g_object_unref(data);
	}

	return;
}

/* This is a different get properites call back that also sends
   new signals.  It basically is a small wrapper around the original. */
static void
menuitem_get_properties_new_cb (GVariant * properties, GError * error, gpointer data)
{
	g_return_if_fail(data != NULL);
	newItemPropData * propdata = (newItemPropData *)data;

	if (error != NULL) {
		g_debug("Error getting properties on a new menuitem: %s", error->message);
		goto out;
	}

	if (properties == NULL) {
		g_warning("Not realizing new item as properties for it were unavailable");
		goto out;
	}

	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(propdata->client);

	/* Extra ref as get_properties will unref once itself */
	g_object_ref(propdata->item);
	menuitem_get_properties_cb (properties, error, propdata->item);

	gboolean handled = FALSE;

	const gchar * type;
	type_handler_t * th = NULL;
	
	type = dbusmenu_menuitem_property_get(propdata->item, DBUSMENU_MENUITEM_PROP_TYPE);
	if (type != NULL) {
		th = (type_handler_t *)g_hash_table_lookup(priv->type_handlers, type);
	} else {
		th = (type_handler_t *)g_hash_table_lookup(priv->type_handlers, DBUSMENU_CLIENT_TYPES_DEFAULT);
	}

	if (th != NULL && th->cb != NULL) {
		handled = th->cb(propdata->item, propdata->parent, propdata->client, th->user_data);
	}

	#ifdef MASSIVEDEBUGGING
	g_debug("Client has realized a menuitem: %d", dbusmenu_menuitem_get_id(propdata->item));
	#endif
	dbusmenu_menuitem_set_realized(propdata->item);

	if (!handled) {
		g_signal_emit(G_OBJECT(propdata->client), signals[NEW_MENUITEM], 0, propdata->item, TRUE);
	}

out:
	g_object_unref(propdata->item);
	g_free(propdata);

	return;
}

/* A function to work with an event_data_t and make sure it gets
   free'd and in a terminal state. */
static void
event_data_end (event_data_t * edata, GError * error)
{
	g_signal_emit(edata->client, signals[EVENT_RESULT], 0, edata->menuitem, edata->event, edata->variant, edata->timestamp, error, TRUE);

	g_variant_unref(edata->variant);
	g_free(edata->event);
	g_object_unref(edata->menuitem);
	g_object_unref(edata->client);
	g_free(edata);

	return;
}

/* Respond to the call function to make sure that the other side
   got it, or print a warning. */
static void
menuitem_call_cb (GObject * proxy, GAsyncResult * res, gpointer userdata)
{
	GError * error = NULL;
	event_data_t * edata = (event_data_t *)userdata;
	GVariant * params;

	params = g_dbus_proxy_call_finish(G_DBUS_PROXY(proxy), res, &error);

	if (error != NULL) {
		g_warning("Unable to call event '%s' on menu item %d: %s", edata->event, dbusmenu_menuitem_get_id(edata->menuitem), error->message);
	}

	event_data_end(edata, error);

	if (G_UNLIKELY(error != NULL)) {
		g_error_free(error);
	}
	if (G_LIKELY(params != NULL)) {
		g_variant_unref(params);
	}

	return;
}

/* Looks at event_data_t structs to match an ID */
static gint
event_data_find (gconstpointer data, gconstpointer user_data)
{
	event_data_t * edata = (event_data_t *)data;
	gint id = GPOINTER_TO_INT(user_data);

	if (edata->id == id) {
		return 0;
	} else {
		return -1;
	}
}

/* The callback from the dbus message to pass events to the
   to the server en masse */
static void
event_group_cb (GObject * proxy, GAsyncResult * res, gpointer user_data)
{
	GQueue * events = (GQueue *)user_data;

	GError * error = NULL;
	GVariant * params;
	params = g_dbus_proxy_call_finish(G_DBUS_PROXY(proxy), res, &error);

	if (error != NULL) {
		/* If we got an actual DBus error, we should just pass that
		   along and finish up */
		g_queue_foreach(events, (GFunc)event_data_end, error);
		g_queue_free(events);
		events = NULL;
		return;
	}

	gint id = 0;
	GVariant * array = g_variant_get_child_value(params, 0);
	GVariantIter iter;
	g_variant_iter_init(&iter, array);

	while (g_variant_iter_loop(&iter, "i", &id)) {
		GList * item = g_queue_find_custom(events, GINT_TO_POINTER(id), event_data_find);

		if (item != NULL) {
			GError * iderror = g_error_new(error_domain(), ERROR_ID_NOT_FOUND, "Unable to find ID: %d", id);
			event_data_end((event_data_t *)item->data, iderror);
			g_queue_delete_link(events, item);
			g_error_free(iderror);
		}
	}

	g_variant_unref(array);
	g_variant_unref(params);

	/* If we have any left send non-error responses */
	g_queue_foreach(events, (GFunc)event_data_end, NULL);
	g_queue_free(events);
	return;
}

/* Turn an event structure into the variant builder form */
static void
events_to_builder (gpointer data, gpointer user_data)
{
	event_data_t * edata = (event_data_t *)data;
	GVariantBuilder * builder = (GVariantBuilder *)user_data;

	GVariantBuilder tuple;
	g_variant_builder_init(&tuple, G_VARIANT_TYPE_TUPLE);

	g_variant_builder_add_value(&tuple, g_variant_new_int32(edata->id));
	g_variant_builder_add_value(&tuple, g_variant_new_string(edata->event));
	g_variant_builder_add_value(&tuple, g_variant_new_variant(edata->variant));
	g_variant_builder_add_value(&tuple, g_variant_new_uint32(edata->timestamp));

	GVariant * vtuple = g_variant_builder_end(&tuple);
	g_variant_builder_add_value(builder, vtuple);
	return;
}

/* Group all the events into a single Dbus message and send
   that out */
static gboolean
event_idle_cb (gpointer user_data)
{
	g_return_val_if_fail(DBUSMENU_IS_CLIENT(user_data), FALSE);
	DbusmenuClient * client = DBUSMENU_CLIENT(user_data);
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(user_data);

	/* We use prepend for speed, but now we want to have them
	   in the order they were called incase that matters. */
	GQueue * levents = priv->events_to_go;
	priv->events_to_go = NULL;
	priv->event_idle = 0;

	GVariantBuilder array;
	g_variant_builder_init(&array, G_VARIANT_TYPE("a(isvu)"));
	g_queue_foreach(levents, events_to_builder, &array);
	GVariant * vevents = g_variant_builder_end(&array);

	if (g_signal_has_handler_pending (client, signals[EVENT_RESULT], 0, TRUE)) {
		g_dbus_proxy_call(priv->menuproxy,
		                  "EventGroup",
		                  g_variant_new_tuple(&vevents, 1),
		                  G_DBUS_CALL_FLAGS_NONE,
		                  1000,   /* timeout */
		                  NULL, /* cancellable */
		                  event_group_cb, levents);
	} else {
		g_dbus_proxy_call(priv->menuproxy,
		                  "EventGroup",
		                  g_variant_new_tuple(&vevents, 1),
		                  G_DBUS_CALL_FLAGS_NONE,
		                  1000,   /* timeout */
		                  NULL, /* cancellable */
		                  NULL, NULL);
		g_queue_foreach(levents, (GFunc)event_data_end, NULL);
		g_queue_free(levents);
	}

	return FALSE;
}

/* Sends the event over DBus to the server on the other side
   of the bus. */
void
dbusmenu_client_send_event (DbusmenuClient * client, gint id, const gchar * name, GVariant * variant, guint timestamp, DbusmenuMenuitem * mi)
{
	g_return_if_fail(DBUSMENU_IS_CLIENT(client));
	g_return_if_fail(id >= 0);
	g_return_if_fail(name != NULL);

	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);
	if (mi == NULL) {
		g_warning("Asked to activate a menuitem %d that we don't know about", id);
		return;
	}

	if (variant == NULL) {
		variant = g_variant_new_int32(0);
	}

	/* Don't bother with the reply handling if nobody is watching... */
	if (!priv->group_events && !g_signal_has_handler_pending (client, signals[EVENT_RESULT], 0, TRUE)) {
		g_dbus_proxy_call(priv->menuproxy,
		                  "Event",
		                  g_variant_new("(isvu)", id, name, variant, timestamp),
		                  G_DBUS_CALL_FLAGS_NONE,
		                  1000,   /* timeout */
		                  NULL, /* cancellable */
		                  NULL, NULL);
		return;
	}

	event_data_t * edata = g_new0(event_data_t, 1);
	edata->id = id;
	edata->client = client;
	g_object_ref(client);
	edata->menuitem = mi;
	g_object_ref(edata->menuitem);
	edata->event = g_strdup(name);
	edata->timestamp = timestamp;
	edata->variant = variant;
	g_variant_ref_sink(variant);

	if (!priv->group_events) {
		g_dbus_proxy_call(priv->menuproxy,
		                  "Event",
		                  g_variant_new("(isvu)", id, name, variant, timestamp),
		                  G_DBUS_CALL_FLAGS_NONE,
		                  1000,   /* timeout */
		                  NULL, /* cancellable */
		                  menuitem_call_cb,
		                  edata);
	} else {
		if (priv->events_to_go == NULL) {
			priv->events_to_go = g_queue_new();
		}

		g_queue_push_tail(priv->events_to_go, edata);

		if (priv->event_idle == 0) {
			priv->event_idle = g_idle_add(event_idle_cb, client);
		}
	}

	return;
}

typedef struct _about_to_show_t about_to_show_t;
struct _about_to_show_t {
	gint id;
	DbusmenuClient * client;
	void (*cb) (gpointer data);
	gpointer cb_data;
};

/* Takes an about_to_show_t structure and calls the callback correctly
   and updates the layout if needed. */
static void
about_to_show_finish (about_to_show_t * data, gboolean need_update)
{
	g_return_if_fail(data != NULL);

	/* If we need to update, do that first. */
	if (need_update) {
		update_layout(data->client);
	}

	if (data->cb != NULL) {
		data->cb(data->cb_data);
	}

	g_object_unref(data->client);
	g_free(data);

	return;
}

/* A little function to match prototypes and make sure to convert from
   a pointer to an int correctly */
static void
about_to_show_finish_pntr (gpointer data, gpointer user_data)
{
	return about_to_show_finish((about_to_show_t *)data, GPOINTER_TO_INT(user_data));
}

/* Respond to the DBus message from sending a bunch of about-to-show events
   to the server */
static void
about_to_show_group_cb (GObject * proxy, GAsyncResult * res, gpointer userdata)
{
	GError * error = NULL;
	GQueue * showers = (GQueue *)userdata;
	GVariant * params = NULL;

	params = g_dbus_proxy_call_finish(G_DBUS_PROXY(proxy), res, &error);

	if (error != NULL) {
		g_warning("Unable to send about_to_show_group: %s", error->message);
		/* Note: we're just ensuring only the callback gets called */
		g_error_free(error);
		error = NULL;
	} else {
		GVariant * updates = g_variant_get_child_value(params, 0);
		GVariantIter iter;

		/* Okay, so this is kinda interesting.  We actually don't care which
		   entries asked us to update the structure, as it's quite simply a
		   single structure.  So if we have any ask, we get the update once to
		   avoid itterating through all the structures. */
		if (g_variant_iter_init(&iter, updates) > 0) {
			about_to_show_t * first = (about_to_show_t *)g_queue_peek_head(showers);
			update_layout(first->client);
		}

		g_variant_unref(updates);
		g_variant_unref(params);
		params = NULL;
	}

	g_queue_foreach(showers, about_to_show_finish_pntr, GINT_TO_POINTER(FALSE));
	g_queue_free(showers);

	return;
}

/* Check to see if this about to show entry has a callback associated
   with it */
static void
about_to_show_idle_callbacks (gpointer data, gpointer user_data)
{
	about_to_show_t * abts = (about_to_show_t *)data;
	gboolean * got_callbacks = (gboolean *)user_data;

	if (abts->cb != NULL) {
		*got_callbacks = TRUE;
	}

	return;
}

/* Take the ID out of the about to show structure and put it into the 
   variant builder */
static void
about_to_show_idle_ids (gpointer data, gpointer user_data)
{
	about_to_show_t * abts = (about_to_show_t *)data;
	GVariantBuilder * builder = (GVariantBuilder *)user_data;

	g_variant_builder_add_value(builder, g_variant_new_int32(abts->id));

	return;
}

/* Function that gets called with all the queued about_to_show messages, let's
   get these guys on the bus! */
static gboolean
about_to_show_idle (gpointer user_data)
{
	DbusmenuClient * client = DBUSMENU_CLIENT(user_data);
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);

	/* Reset our object global props and take ownership of these entries */
	priv->about_to_show_idle = 0;
	GQueue * showers = priv->about_to_show_to_go;
	priv->about_to_show_to_go = NULL;

	g_return_val_if_fail(showers != NULL, FALSE);

	/* Figure out if we've got any callbacks */
	gboolean got_callbacks = FALSE;
	g_queue_foreach(showers, about_to_show_idle_callbacks, &got_callbacks);

	/* Build a list of the IDs */
	GVariantBuilder idarray;
	g_variant_builder_init(&idarray, G_VARIANT_TYPE("ai"));
	g_queue_foreach(showers, about_to_show_idle_ids, &idarray);
	GVariant * ids = g_variant_builder_end(&idarray);

	/* Setup our callbacks */
	GAsyncReadyCallback cb = NULL;
	gpointer cb_data = NULL;
	if (got_callbacks) {
		cb = about_to_show_group_cb;
		cb_data = showers;
	} else {
		g_queue_foreach(showers, about_to_show_finish_pntr, GINT_TO_POINTER(FALSE));
		g_queue_free(showers);
	}

	/* Let's call it! */
	g_dbus_proxy_call(priv->menuproxy,
	                  "AboutToShowGroup",
	                  g_variant_new_tuple(&ids, 1),
	                  G_DBUS_CALL_FLAGS_NONE,
	                  -1,   /* timeout */
	                  NULL, /* cancellable */
	                  cb,
	                  cb_data);

	return FALSE;
}

/* Reports errors and responds to update request that were a result
   of sending the about to show signal. */
static void
about_to_show_cb (GObject * proxy, GAsyncResult * res, gpointer userdata)
{
	gboolean need_update = FALSE;
	GError * error = NULL;
	about_to_show_t * data = (about_to_show_t *)userdata;
	GVariant * params = NULL;

	params = g_dbus_proxy_call_finish(G_DBUS_PROXY(proxy), res, &error);

	if (error != NULL) {
		g_warning("Unable to send about_to_show: %s", error->message);
		/* Note: we're just ensuring only the callback gets called */
		need_update = FALSE;
		g_error_free(error);
		error = NULL;
	} else {
		g_variant_get(params, "(b)", &need_update);
		g_variant_unref(params);
	}

	if (data != NULL) {
		about_to_show_finish(data, need_update);
	}

	return;
}

/* Sends the about to show signal for a given id to the
   server on the other side of DBus */
void
dbusmenu_client_send_about_to_show(DbusmenuClient * client, gint id, void (*cb)(gpointer data), gpointer cb_data)
{
	g_return_if_fail(DBUSMENU_CLIENT(client));
	g_return_if_fail(id >= 0);

	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);
	g_return_if_fail(priv != NULL);

	about_to_show_t * data = g_new0(about_to_show_t, 1);
	data->id = id;
	data->client = client;
	data->cb = cb;
	data->cb_data = cb_data;
	g_object_ref(client);

	if (priv->group_events) {
		if (priv->about_to_show_to_go == NULL) {
			priv->about_to_show_to_go = g_queue_new();
		}

		g_queue_push_tail(priv->about_to_show_to_go, data);

		if (priv->about_to_show_idle == 0) {
			priv->about_to_show_idle = g_idle_add(about_to_show_idle, client);
		}
	} else {
		GAsyncReadyCallback dbuscb = NULL;

		/* If there's no callback we don't need this data, let's
		   clean it up in a consistent way */
		if (cb == NULL) {
			about_to_show_finish(data, FALSE);
			data = NULL;
		} else {
			dbuscb = about_to_show_cb;
		}

		g_dbus_proxy_call(priv->menuproxy,
		                  "AboutToShow",
		                  g_variant_new("(i)", id),
		                  G_DBUS_CALL_FLAGS_NONE,
		                  -1,   /* timeout */
		                  NULL, /* cancellable */
		                  dbuscb,
		                  data);
	}

	return;
}

/* Builds a new child with property requests and everything
   else to clean up the code a bit */
static DbusmenuMenuitem *
parse_layout_new_child (gint id, DbusmenuClient * client, DbusmenuMenuitem * parent)
{
	DbusmenuMenuitem * item = NULL;

	/* Build a new item */
	item = DBUSMENU_MENUITEM(dbusmenu_client_menuitem_new(id, client));
	if (parent == NULL) {
		dbusmenu_menuitem_set_root(item, TRUE);
	}

	/* Get the properties queued up for this item */
	/* Not happy allocating about this, but I need these :( */
	newItemPropData * propdata = g_new0(newItemPropData, 1);
	if (propdata != NULL) {
		propdata->client  = client;
		propdata->item    = item;
		propdata->parent  = parent;

		g_object_ref(item);
		get_properties_globber(client, id, NULL, menuitem_get_properties_new_cb, propdata);
	} else {
		g_warning("Unable to allocate memory to get properties for menuitem.  This menuitem will never be realized.");
	}

	return item;
}

/* Refresh the properties on this item */
static void
parse_layout_update (DbusmenuMenuitem * item, DbusmenuClient * client)
{
	g_object_ref(item);
	get_properties_globber(client, dbusmenu_menuitem_get_id(item), NULL, menuitem_get_properties_replace_cb, item);
	return;
}

/* Parse recursively through the XML and make it into
   objects as need be */
static DbusmenuMenuitem *
parse_layout_xml(DbusmenuClient * client, GVariant * layout, DbusmenuMenuitem * item, DbusmenuMenuitem * parent, GDBusProxy * proxy)
{
	if (layout == NULL) {
		return NULL;
	}

	/* First verify and figure out what we've got */
	GVariant * idv = g_variant_get_child_value(layout, 0);
	gint id = g_variant_get_int32(idv);
	g_variant_unref(idv);
	if (id < 0) {
		return NULL;
	}
	#ifdef MASSIVEDEBUGGING
	g_debug("Client looking at node with id: %d", id);
	#endif

	g_return_val_if_fail(item != NULL, NULL);
	g_return_val_if_fail(id == dbusmenu_menuitem_get_id(item), NULL);

	/* Some variables */
	GVariantIter children;
	GVariant * childrenv;

	childrenv = g_variant_get_child_value(layout, 2);
	g_variant_iter_init(&children, childrenv);

	guint position = 0;
	GList * oldchildren = g_list_copy(dbusmenu_menuitem_get_children(item));
	/* g_debug("Starting old children: %d", g_list_length(oldchildren)); */

	/* Go through all the XML Nodes and make sure that we have menuitems
	   to cover those XML nodes. */
	GVariant * child;
	while ((child = g_variant_iter_next_value(&children)) != NULL) {
		/* g_debug("Looking at child: %d", position); */
		if (g_variant_is_of_type(child, G_VARIANT_TYPE_VARIANT)) {
			GVariant * tmp = g_variant_get_variant(child);
			g_variant_unref(child);
			child = tmp;
		}

		GVariant * childidv = g_variant_get_child_value(child, 0);
		gint childid = g_variant_get_int32(childidv);
		g_variant_unref(childidv);
		if (childid < 0) {
			/* Don't increment the position when there isn't a valid
			   node in the XML tree.  It's probably a comment. */
			g_variant_unref(child);
			continue;
		}
		DbusmenuMenuitem * childmi = NULL;

		/* First see if we can recycle a node that we've already built
		   on this menu item */
		GList * childsearch = NULL;
		for (childsearch = oldchildren; childsearch != NULL; childsearch = g_list_next(childsearch)) {
			DbusmenuMenuitem * cs_mi = DBUSMENU_MENUITEM(childsearch->data);
			if (childid == dbusmenu_menuitem_get_id(cs_mi)) {
				GVariantIter iter;
				gchar * prop;
				GVariant * value;
				GVariant * child_props;
				GVariant * new_type = NULL;
				GVariant * old_type = NULL;

				child_props = g_variant_get_child_value(child, 1);
				g_variant_iter_init(&iter, child_props);
				while (g_variant_iter_loop(&iter, "{sv}", &prop, &value)) {
					if (g_strcmp0(prop, DBUSMENU_MENUITEM_PROP_TYPE) == 0) {
						new_type = value;
						break;
					}
				}
				g_variant_unref(child_props);
				
				old_type = dbusmenu_menuitem_property_get_variant(cs_mi, DBUSMENU_MENUITEM_PROP_TYPE);
				if ((old_type == NULL && new_type == NULL) || (old_type != NULL && new_type != NULL && g_variant_compare(old_type, new_type) == 0)) {
					// Only recycle the menu item if it's of the same type
					oldchildren = g_list_remove(oldchildren, cs_mi);
					childmi = cs_mi;
				}
				break;
			}
		}

		if (childmi == NULL) {
			#ifdef MASSIVEDEBUGGING
			g_debug("Building new menu item %d at position %d", childid, position);
			#endif
			/* If we can't recycle, then we build a new one */
			childmi = parse_layout_new_child(childid, client, item);
			dbusmenu_menuitem_child_add_position(item, childmi, position);
			g_object_unref(childmi);
		} else {
			#ifdef MASSIVEDEBUGGING
			g_debug("Recycling menu item %d at position %d", childid, position);
			#endif
			/* If we can recycle, make sure it's in the right place */
			dbusmenu_menuitem_child_reorder(item, childmi, position);
			parse_layout_update(childmi, client);
		}

		/* Apply known properties sent in the structure to the
		   menu item.  Sometimes they may just be copies */
		if (childmi != NULL) {
			GVariantIter iter;
			gchar * prop;
			GVariant * value;
			GVariant * child_props;

			/* Set the type first as it can manage the behavior of
			   all other properties. */
			child_props = g_variant_get_child_value(child, 1);
			g_variant_iter_init(&iter, child_props);
			while (g_variant_iter_loop(&iter, "{sv}", &prop, &value)) {
				if (g_strcmp0(prop, DBUSMENU_MENUITEM_PROP_TYPE) == 0) {
					dbusmenu_menuitem_property_set_variant(childmi, prop, value);
				}
			}

			/* Now go through and do all the properties. */
			g_variant_iter_init(&iter, child_props);
			while (g_variant_iter_loop(&iter, "{sv}", &prop, &value)) {
				dbusmenu_menuitem_property_set_variant(childmi, prop, value);
			}
			g_variant_unref(child_props);
		}

		position++;
		g_variant_unref(child);
	}

	/* Remove any children that are no longer used by this version of
	   the layout. */
	GList * oldchildleft = NULL;
	for (oldchildleft = oldchildren; oldchildleft != NULL; oldchildleft = g_list_next(oldchildleft)) {
		DbusmenuMenuitem * oldmi = DBUSMENU_MENUITEM(oldchildleft->data);
		#ifdef MASSIVEDEBUGGING
		g_debug("Unref'ing menu item with layout update. ID: %d", dbusmenu_menuitem_get_id(oldmi));
		#endif
		dbusmenu_menuitem_child_delete(item, oldmi);
	}
	g_list_free(oldchildren);

	/* We've got everything built up at this node and reconcilled */

	/* Flush the properties requests if this is the first level */
	if (parent != NULL && dbusmenu_menuitem_get_id(parent) == 0) {
		get_properties_flush(client);
	}

	/* now it's time to recurse down the tree. */
	g_variant_iter_init(&children, childrenv);

	child = g_variant_iter_next_value(&children);
	GList * childmis = dbusmenu_menuitem_get_children(item);
	while (child != NULL && childmis != NULL) {
		if (g_variant_is_of_type(child, G_VARIANT_TYPE_VARIANT)) {
			GVariant * tmp = g_variant_get_variant(child);
			g_variant_unref(child);
			child = tmp;
		}

		GVariant * xmlidv = g_variant_get_child_value(child, 0);
		gint xmlid = g_variant_get_int32(xmlidv);
		g_variant_unref(xmlidv);
		/* If this isn't a valid menu item we need to move on
		   until we have one.  This avoids things like comments. */
		if (xmlid < 0) {
			g_variant_unref(child);
			child = g_variant_iter_next_value(&children);
			continue;
		}

		#ifdef MASSIVEDEBUGGING
		gint miid = dbusmenu_menuitem_get_id(DBUSMENU_MENUITEM(childmis->data));
		g_debug("Recursing parse_layout_xml.  XML ID: %d  MI ID: %d", xmlid, miid);
		#endif
		
		parse_layout_xml(client, child, DBUSMENU_MENUITEM(childmis->data), item, proxy);

		g_variant_unref(child);
		child = g_variant_iter_next_value(&children);
		childmis = g_list_next(childmis);
	}

	g_variant_unref(childrenv);

	if (child != NULL) {
		g_warning("Sync failed, now we've got extra layout nodes.");
	}
	if (childmis != NULL) {
		g_warning("Sync failed, now we've got extra menu items.");
	}

	return item;
}

/* Take the layout passed to us over DBus and turn it into
   a set of beautiful objects */
static gint
parse_layout (DbusmenuClient * client, GVariant * layout)
{
	#ifdef MASSIVEDEBUGGING
	g_debug("Client Parsing a new layout");
	#endif 

	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);

	DbusmenuMenuitem * oldroot = priv->root;

	if (priv->root == NULL) {
		priv->root = parse_layout_new_child(0, client, NULL);
	} else {
		parse_layout_update(priv->root, client);
	}

	priv->root = parse_layout_xml(client, layout, priv->root, NULL, priv->menuproxy);

	if (priv->root == NULL) {
		g_warning("Unable to parse layout on client %s object %s: %s", priv->dbus_name, priv->dbus_object, g_variant_print(layout, TRUE));
	}

	if (priv->root != oldroot) {
		#ifdef MASSIVEDEBUGGING
		g_debug("Client signaling root changed.");
		#endif 

		/* If they are different, and there was an old root we must
		   clean up that old root */
		if (oldroot != NULL) {
			dbusmenu_menuitem_set_root(oldroot, FALSE);
			g_object_unref(oldroot);
			oldroot = NULL;
		}

		/* If the root changed we can signal that */
		g_signal_emit(G_OBJECT(client), signals[ROOT_CHANGED], 0, priv->root, TRUE);
	}

	return 1;
}

/* When the layout property returns, here's where we take care of that. */
static void
update_layout_cb (GObject * proxy, GAsyncResult * res, gpointer data)
{
	DbusmenuClient * client = DBUSMENU_CLIENT(data);
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);

	GError * error = NULL;
	GVariant * params = NULL;
	GVariant * layout = NULL;

	params = g_dbus_proxy_call_finish(G_DBUS_PROXY(proxy), res, &error);

	if (error != NULL) {
		g_warning("Getting layout failed: %s", error->message);
		g_error_free(error);
		goto out;
	}

	GVariant * revv = g_variant_get_child_value(params, 0);
	guint rev = g_variant_get_uint32(revv);
	g_variant_unref(revv);

	layout = g_variant_get_child_value(params, 1);

	guint parseable = parse_layout(client, layout);

	if (parseable == 0) {
		g_warning("Unable to parse layout!");
		goto out;
	}

	priv->my_revision = rev;
	/* g_debug("Root is now: 0x%X", (unsigned int)priv->root); */
	#ifdef MASSIVEDEBUGGING
	g_debug("Client signaling layout has changed.");
	#endif 
	g_signal_emit(G_OBJECT(client), signals[LAYOUT_UPDATED], 0, TRUE);

	/* Check to see if we got another update in the time this
	   one was issued. */
	if (priv->my_revision < priv->current_revision) {
		update_layout(client);
	}

out:
	if (priv->layoutcall != NULL) {
		g_object_unref(priv->layoutcall);
		priv->layoutcall = NULL;
	}

	if (layout != NULL) {
		g_variant_unref(layout);
	}

	if (params != NULL) {
		g_variant_unref(params);
	}

	g_object_unref(G_OBJECT(client));
	return;
}

/* Call the property on the server we're connected to and set it up to
   be async back to _update_layout_cb */
static void
update_layout (DbusmenuClient * client)
{
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);
	g_return_if_fail(priv->layout_props != NULL);

	if (priv->menuproxy == NULL) {
		return;
	}

	gchar * name_owner = g_dbus_proxy_get_name_owner(priv->menuproxy);
	if (name_owner == NULL) {
		return;
	}
	g_free(name_owner);

	if (priv->layoutcall != NULL) {
		return;
	}

	priv->layoutcall = g_cancellable_new();

	GVariantBuilder tupleb;
	g_variant_builder_init(&tupleb, G_VARIANT_TYPE_TUPLE);
	
	g_variant_builder_add_value(&tupleb, g_variant_new_int32(0)); // root
	g_variant_builder_add_value(&tupleb, g_variant_new_int32(-1)); // recurse
	g_variant_builder_add_value(&tupleb, priv->layout_props); // props

	GVariant * args = g_variant_builder_end(&tupleb);
	// g_debug("Args (type: %s): %s", g_variant_get_type_string(args), g_variant_print(args, TRUE));

	g_object_ref(G_OBJECT(client));
	g_dbus_proxy_call(priv->menuproxy,
	                  "GetLayout",
	                  args,
	                  G_DBUS_CALL_FLAGS_NONE,
	                  -1,   /* timeout */
	                  priv->layoutcall, /* cancellable */
	                  update_layout_cb,
	                  client);

	return;
}

/* Public API */
/**
 * dbusmenu_client_new:
 * @name: The DBus name for the server to connect to
 * @object: The object on the server to monitor
 * 
 * This function creates a new client that connects to a specific
 * server on DBus.  That server is at a specific location sharing
 * a known object.  The interface is assumed by the code to be 
 * the DBus menu interface.  The newly created client will start
 * sending out events as it syncs up with the server.
 * 
 * Return value: A brand new #DbusmenuClient
*/
DbusmenuClient *
dbusmenu_client_new (const gchar * name, const gchar * object)
{
	g_return_val_if_fail(g_dbus_is_name(name), NULL);
	g_return_val_if_fail(g_variant_is_object_path(object), NULL);

	DbusmenuClient * self = g_object_new(DBUSMENU_TYPE_CLIENT,
	                                     DBUSMENU_CLIENT_PROP_DBUS_NAME, name,
	                                     DBUSMENU_CLIENT_PROP_DBUS_OBJECT, object,
	                                     NULL);

	return self;
}

/**
 * dbusmenu_client_get_root:
 * @client: The #DbusmenuClient to get the root node from
 * 
 * Grabs the root node for the specified client @client.  This
 * function may block.  It will block if there is currently a
 * call to update the layout, it will block on that layout 
 * updated and then return the newly updated layout.  Chances
 * are that this update is in the queue for the mainloop as
 * it would have been requested some time ago, but in theory
 * it could block longer.
 * 
 * Return value: (transfer none): A #DbusmenuMenuitem representing the root of
 * 	menu on the server.  If there is no server or there is
 * 	an error receiving its layout it'll return #NULL.
 */
DbusmenuMenuitem *
dbusmenu_client_get_root (DbusmenuClient * client)
{
	g_return_val_if_fail(DBUSMENU_IS_CLIENT(client), NULL);

	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);

	#ifdef MASSIVEDEBUGGING
	g_debug("Client get root: %X", (guint)priv->root);
	#endif

	return priv->root;
}

/* Remove the type handler when we're all done with it */
static void
type_handler_destroy (gpointer user_data)
{
	type_handler_t * th = (type_handler_t *)user_data;
	if (th->destroy_cb != NULL) {
		th->destroy_cb(th->user_data);
	}
	g_free(th->type);
	g_free(th);
	return;
}

/**
 * dbusmenu_client_add_type_handler:
 * @client: Client where we're getting types coming in
 * @type: A text string that will be matched with the 'type'
 *     property on incoming menu items
 * @newfunc: (scope notified): The function that will be executed with those new
 *     items when they come in.
 * 
 * This function connects into the type handling of the #DbusmenuClient.
 * Every new menuitem that comes in immediately gets asked for its
 * properties.  When we get those properties we check the 'type'
 * property and look to see if it matches a handler that is known
 * by the client.  If so, the @newfunc function is executed on that
 * #DbusmenuMenuitem.  If not, then the DbusmenuClient::new-menuitem
 * signal is sent.
 * 
 * In the future the known types will be sent to the server so that it
 * can make choices about the menu item types availble.
 * 
 * Return value: If registering the new type was successful.
*/
gboolean
dbusmenu_client_add_type_handler (DbusmenuClient * client, const gchar * type, DbusmenuClientTypeHandler newfunc)
{
	return dbusmenu_client_add_type_handler_full(client, type, newfunc, NULL, NULL);
}

/**
 * dbusmenu_client_add_type_handler_full:
 * @client: Client where we're getting types coming in
 * @type: A text string that will be matched with the 'type'
 *     property on incoming menu items
 * @newfunc: (scope notified): The function that will be executed with those new
 *     items when they come in.
 * @user_data: Data passed to @newfunc when it is called
 * @destroy_func: A function that is called when the type handler is
 * 	removed (usually on client destruction) which will free
 * 	the resources in @user_data.
 * 
 * This function connects into the type handling of the #DbusmenuClient.
 * Every new menuitem that comes in immediately gets asked for its
 * properties.  When we get those properties we check the 'type'
 * property and look to see if it matches a handler that is known
 * by the client.  If so, the @newfunc function is executed on that
 * #DbusmenuMenuitem.  If not, then the DbusmenuClient::new-menuitem
 * signal is sent.
 * 
 * In the future the known types will be sent to the server so that it
 * can make choices about the menu item types availble.
 * 
 * Return value: If registering the new type was successful.
*/
gboolean
dbusmenu_client_add_type_handler_full (DbusmenuClient * client, const gchar * type, DbusmenuClientTypeHandler newfunc, gpointer user_data, GDestroyNotify destroy_func)
{
	g_return_val_if_fail(DBUSMENU_IS_CLIENT(client), FALSE);
	g_return_val_if_fail(type != NULL, FALSE);

	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);

	#ifdef MASSIVEDEBUGGING
	g_debug("Adding a type handler for '%s'", type);
	#endif

	if (priv->type_handlers == NULL) {
		g_warning("Type handlers hashtable not built");
		return FALSE;
	}

	gpointer value = g_hash_table_lookup(priv->type_handlers, type);
	if (value != NULL) {
		g_warning("Type '%s' already had a registered handler.", type);
		return FALSE;
	}

	type_handler_t * th = g_new0(type_handler_t, 1);
	th->client = client;
	th->cb = newfunc;
	th->destroy_cb = destroy_func;
	th->user_data = user_data;
	th->type = g_strdup(type);

	g_hash_table_insert(priv->type_handlers, g_strdup(type), th);
	return TRUE;
}

/**
	dbusmenu_client_get_text_direction:
	@client: #DbusmenuClient to check the text direction on

	Gets the text direction that the server is exporting.  If
	the server is not exporting a direction then the value
	#DBUSMENU_TEXT_DIRECTION_NONE will be returned.

	Return value: Text direction being exported.
*/
DbusmenuTextDirection
dbusmenu_client_get_text_direction (DbusmenuClient * client)
{
	g_return_val_if_fail(DBUSMENU_IS_CLIENT(client), DBUSMENU_TEXT_DIRECTION_NONE);
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);
	return priv->text_direction;
}

/**
	dbusmenu_client_get_status:
	@client: #DbusmenuClient to check the status on

	Gets the recommended current status that the server
	is exporting for the menus.  In situtations where the
	value is #DBUSMENU_STATUS_NOTICE it is recommended that
	the client show the menus to the user an a more noticible
	way.

	Return value: Status being exported.
*/
DbusmenuStatus
dbusmenu_client_get_status (DbusmenuClient * client)
{
	g_return_val_if_fail(DBUSMENU_IS_CLIENT(client), DBUSMENU_STATUS_NORMAL);
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);
	return priv->status;
}

/**
 * dbusmenu_client_get_icon_paths:
 * @client: The #DbusmenuClient to get the icon paths from
 * 
 * Gets the stored and exported icon paths from the client.
 * 
 * Return value: (transfer none): A NULL-terminated list of icon paths with
 *   memory managed by the client.  Duplicate if you want
 *   to keep them.
 */
GStrv
dbusmenu_client_get_icon_paths (DbusmenuClient * client)
{
	g_return_val_if_fail(DBUSMENU_IS_CLIENT(client), NULL);
	DbusmenuClientPrivate * priv = DBUSMENU_CLIENT_GET_PRIVATE(client);
	return priv->icon_dirs;
}

