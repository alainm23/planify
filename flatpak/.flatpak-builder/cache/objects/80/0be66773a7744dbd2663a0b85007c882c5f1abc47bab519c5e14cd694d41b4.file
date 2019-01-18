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

#include <glib/gi18n-lib.h>
#include <gio/gio.h>

#include "menuitem-private.h"
#include "server.h"
#include "server-marshal.h"
#include "enum-types.h"

#include "dbus-menu-clean.xml.h"

static void layout_update_signal (DbusmenuServer * server);

#define DBUSMENU_VERSION_NUMBER    3
#define DBUSMENU_INTERFACE         "com.canonical.dbusmenu"

/* Privates, I'll show you mine... */
struct _DbusmenuServerPrivate
{
	DbusmenuMenuitem * root;
	gchar * dbusobject;
	gint layout_revision;
	guint layout_idle;

	GDBusConnection * bus;
	guint find_server_signal;
	GCancellable * bus_lookup;
	guint dbus_registration;

	DbusmenuTextDirection text_direction;
	DbusmenuStatus status;
	GStrv icon_dirs;

	GArray * prop_array;
	guint property_idle;

	GHashTable * lookup_cache;
};

#define DBUSMENU_SERVER_GET_PRIVATE(o) (DBUSMENU_SERVER(o)->priv)

/* Signals */
enum {
	ID_PROP_UPDATE,
	ID_UPDATE,
	LAYOUT_UPDATED,
	ITEM_ACTIVATION,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL] = { 0 };

/* Properties */
enum {
	PROP_0,
	PROP_DBUS_OBJECT,
	PROP_ROOT_NODE,
	PROP_VERSION,
	PROP_TEXT_DIRECTION,
	PROP_STATUS,
	PROP_ICON_THEME_DIRS
};

/* Errors */
enum {
	INVALID_MENUITEM_ID,
	INVALID_PROPERTY_NAME,
	UNKNOWN_DBUS_ERROR,
	NOT_IMPLEMENTED,
	NO_VALID_LAYOUT,
	LAST_ERROR
};

/* Method Table */
typedef void (*MethodTableFunc) (DbusmenuServer * server, GVariant * params, GDBusMethodInvocation * invocation);

typedef struct _method_table_t method_table_t;
struct _method_table_t {
	const gchar * interned_name;
	MethodTableFunc func;
};

enum {
	METHOD_GET_LAYOUT = 0,
	METHOD_GET_GROUP_PROPERTIES,
	METHOD_GET_CHILDREN,
	METHOD_GET_PROPERTY,
	METHOD_GET_PROPERTIES,
	METHOD_EVENT,
	METHOD_EVENT_GROUP,
	METHOD_ABOUT_TO_SHOW,
	METHOD_ABOUT_TO_SHOW_GROUP,
	/* Counter, do not remove! */
	METHOD_COUNT
};

/* Prototype */
static void       dbusmenu_server_class_init  (DbusmenuServerClass *class);
static void       dbusmenu_server_init        (DbusmenuServer *self);
static void       dbusmenu_server_dispose     (GObject *object);
static void       dbusmenu_server_finalize    (GObject *object);
static void       set_property                (GObject * obj,
                                               guint id,
                                               const GValue * value,
                                               GParamSpec * pspec);
static void       get_property                (GObject * obj,
                                               guint id,
                                               GValue * value,
                                               GParamSpec * pspec);
static void       default_text_direction      (DbusmenuServer * server);
static void       register_object             (DbusmenuServer * server);
static void       bus_got_cb                  (GObject * obj,
                                               GAsyncResult * result,
                                               gpointer user_data);
static void       bus_method_call             (GDBusConnection * connection,
                                               const gchar * sender,
                                               const gchar * path,
                                               const gchar * interface,
                                               const gchar * method,
                                               GVariant * params,
                                               GDBusMethodInvocation * invocation,
                                               gpointer user_data);
static GVariant * bus_get_prop                (GDBusConnection * connection,
                                               const gchar * sender,
                                               const gchar * path,
                                               const gchar * interface,
                                               const gchar * property,
                                               GError ** error,
                                               gpointer user_data);
static void       menuitem_property_changed   (DbusmenuMenuitem * mi,
                                               gchar * property,
                                               GVariant * variant,
                                               DbusmenuServer * server);
static void       menuitem_child_added        (DbusmenuMenuitem * parent,
                                               DbusmenuMenuitem * child,
                                               guint pos,
                                               DbusmenuServer * server);
static void       menuitem_child_removed      (DbusmenuMenuitem * parent,
                                               DbusmenuMenuitem * child,
                                               DbusmenuServer * server);
static void       menuitem_signals_create     (DbusmenuMenuitem * mi,
                                               gpointer data);
static void       menuitem_signals_remove     (DbusmenuMenuitem * mi,
                                               gpointer data);
static GQuark     error_quark                 (void);
static void       prop_array_teardown         (GArray * prop_array);
static void       bus_get_layout              (DbusmenuServer * server,
                                               GVariant * params,
                                               GDBusMethodInvocation * invocation);
static void       bus_get_group_properties    (DbusmenuServer * server,
                                               GVariant * params,
                                               GDBusMethodInvocation * invocation);
static void       bus_get_children            (DbusmenuServer * server,
                                               GVariant * params,
                                               GDBusMethodInvocation * invocation);
static void       bus_get_property            (DbusmenuServer * server,
                                               GVariant * params,
                                               GDBusMethodInvocation * invocation);
static void       bus_get_properties          (DbusmenuServer * server,
                                               GVariant * params,
                                               GDBusMethodInvocation * invocation);
static void       bus_event                   (DbusmenuServer * server,
                                               GVariant * params,
                                               GDBusMethodInvocation * invocation);
static void       bus_event_group             (DbusmenuServer * server,
                                               GVariant * params,
                                               GDBusMethodInvocation * invocation);
static void       bus_about_to_show           (DbusmenuServer * server,
                                               GVariant * params,
                                               GDBusMethodInvocation * invocation);
static void       bus_about_to_show_group     (DbusmenuServer * server,
                                               GVariant * params,
                                               GDBusMethodInvocation * invocation);
static void       find_servers_cb             (GDBusConnection * connection,
                                               const gchar * sender,
                                               const gchar * path,
                                               const gchar * interface,
                                               const gchar * signal,
                                               GVariant * params,
                                               gpointer user_data);
static gboolean   layout_update_idle          (gpointer user_data);

/* Globals */
static GDBusNodeInfo *            dbusmenu_node_info = NULL;
static GDBusInterfaceInfo *       dbusmenu_interface_info = NULL;
static const GDBusInterfaceVTable dbusmenu_interface_table = {
	.method_call  = bus_method_call,
	.get_property = bus_get_prop,
	.set_property = NULL /* No properties that can be set */
};
static method_table_t             dbusmenu_method_table[METHOD_COUNT];

G_DEFINE_TYPE (DbusmenuServer, dbusmenu_server, G_TYPE_OBJECT);

static void
dbusmenu_server_class_init (DbusmenuServerClass *class)
{
	GObjectClass *object_class = G_OBJECT_CLASS (class);

	g_type_class_add_private (class, sizeof (DbusmenuServerPrivate));

	object_class->dispose = dbusmenu_server_dispose;
	object_class->finalize = dbusmenu_server_finalize;
	object_class->set_property = set_property;
	object_class->get_property = get_property;

	/**
		DbusmenuServer::id-prop-update:
		@arg0: The #DbusmenuServer emitting the signal.
		@arg1: The ID of the #DbusmenuMenuitem changing a property.
		@arg2: The property being changed.
		@arg3: The value of the property being changed.

		This signal is emitted when a menuitem updates or
		adds a property.
	*/
	signals[ID_PROP_UPDATE] =   g_signal_new(DBUSMENU_SERVER_SIGNAL_ID_PROP_UPDATE,
	                                         G_TYPE_FROM_CLASS(class),
	                                         G_SIGNAL_RUN_LAST,
	                                         G_STRUCT_OFFSET(DbusmenuServerClass, id_prop_update),
	                                         NULL, NULL,
	                                         _dbusmenu_server_marshal_VOID__INT_STRING_VARIANT,
	                                         G_TYPE_NONE, 3, G_TYPE_INT, G_TYPE_STRING, G_TYPE_VARIANT);
	/**
		DbusmenuServer::id-update:
		@arg0: The #DbusmenuServer emitting the signal.
		@arg1: ID of the #DbusmenuMenuitem changing.

		The purpose of this signal is to show major change in
		a menuitem to the point that #DbusmenuServer::id-prop-update
		seems a little insubstantive.
	*/
	signals[ID_UPDATE] =        g_signal_new(DBUSMENU_SERVER_SIGNAL_ID_UPDATE,
	                                         G_TYPE_FROM_CLASS(class),
	                                         G_SIGNAL_RUN_LAST,
	                                         G_STRUCT_OFFSET(DbusmenuServerClass, id_update),
	                                         NULL, NULL,
	                                         g_cclosure_marshal_VOID__INT,
	                                         G_TYPE_NONE, 1, G_TYPE_INT);
	/**
		DbusmenuServer::layout-updated:
		@arg0: The #DbusmenuServer emitting the signal.
		@arg1: A revision number representing which revision the update
		       represents itself as.
		@arg2: The ID of the parent for this update.

		This signal is emitted any time the layout of the
		menuitems under this server is changed.
	*/
	signals[LAYOUT_UPDATED] =   g_signal_new(DBUSMENU_SERVER_SIGNAL_LAYOUT_UPDATED,
	                                         G_TYPE_FROM_CLASS(class),
	                                         G_SIGNAL_RUN_LAST,
	                                         G_STRUCT_OFFSET(DbusmenuServerClass, layout_updated),
	                                         NULL, NULL,
	                                         _dbusmenu_server_marshal_VOID__UINT_INT,
	                                         G_TYPE_NONE, 2, G_TYPE_UINT, G_TYPE_INT);
	/**
		DbusmenuServer::item-activation-requested:
		@arg0: The #DbusmenuServer emitting the signal.
		@arg1: The ID of the parent for this update.
		@arg2: The timestamp of when the event happened

		This is signaled when a menuitem under this server
		sends its activate signal.
	*/
	signals[ITEM_ACTIVATION] =  g_signal_new(DBUSMENU_SERVER_SIGNAL_ITEM_ACTIVATION,
	                                         G_TYPE_FROM_CLASS(class),
	                                         G_SIGNAL_RUN_LAST,
	                                         G_STRUCT_OFFSET(DbusmenuServerClass, item_activation),
	                                         NULL, NULL,
	                                         _dbusmenu_server_marshal_VOID__INT_UINT,
	                                         G_TYPE_NONE, 2, G_TYPE_INT, G_TYPE_UINT);


	g_object_class_install_property (object_class, PROP_DBUS_OBJECT,
	                                 g_param_spec_string(DBUSMENU_SERVER_PROP_DBUS_OBJECT, "DBus object path",
	                                              "The object that represents this set of menus on DBus",
	                                              "/com/canonical/dbusmenu",
	                                              G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY | G_PARAM_STATIC_STRINGS));
	g_object_class_install_property (object_class, PROP_ROOT_NODE,
	                                 g_param_spec_object(DBUSMENU_SERVER_PROP_ROOT_NODE, "Root menu node",
	                                              "The base object of the menus that are served",
	                                              DBUSMENU_TYPE_MENUITEM,
	                                              G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));
	g_object_class_install_property (object_class, PROP_VERSION,
	                                 g_param_spec_uint(DBUSMENU_SERVER_PROP_VERSION, "Dbusmenu API version",
	                                              "The version of the DBusmenu API that we're implementing.",
	                                              DBUSMENU_VERSION_NUMBER, DBUSMENU_VERSION_NUMBER, DBUSMENU_VERSION_NUMBER,
	                                              G_PARAM_READABLE | G_PARAM_STATIC_STRINGS));
	g_object_class_install_property (object_class, PROP_TEXT_DIRECTION,
	                                 g_param_spec_enum(DBUSMENU_SERVER_PROP_TEXT_DIRECTION, "The default direction of text",
	                                              "The object that represents this set of menus on DBus",
	                                              DBUSMENU_TYPE_TEXT_DIRECTION, DBUSMENU_TEXT_DIRECTION_NONE,
	                                              G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));
	g_object_class_install_property (object_class, PROP_STATUS,
	                                 g_param_spec_enum(DBUSMENU_SERVER_PROP_STATUS, "Status of viewing the menus",
	                                              "Exports over DBus whether the menus should be given special visuals",
	                                              DBUSMENU_TYPE_STATUS, DBUSMENU_STATUS_NORMAL,
	                                              G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

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

	/* Building our Method table :( */
	dbusmenu_method_table[METHOD_GET_LAYOUT].interned_name = g_intern_static_string("GetLayout");
	dbusmenu_method_table[METHOD_GET_LAYOUT].func          = bus_get_layout;

	dbusmenu_method_table[METHOD_GET_GROUP_PROPERTIES].interned_name = g_intern_static_string("GetGroupProperties");
	dbusmenu_method_table[METHOD_GET_GROUP_PROPERTIES].func          = bus_get_group_properties;

	dbusmenu_method_table[METHOD_GET_CHILDREN].interned_name = g_intern_static_string("GetChildren");
	dbusmenu_method_table[METHOD_GET_CHILDREN].func          = bus_get_children;

	dbusmenu_method_table[METHOD_GET_PROPERTY].interned_name = g_intern_static_string("GetProperty");
	dbusmenu_method_table[METHOD_GET_PROPERTY].func          = bus_get_property;

	dbusmenu_method_table[METHOD_GET_PROPERTIES].interned_name = g_intern_static_string("GetProperties");
	dbusmenu_method_table[METHOD_GET_PROPERTIES].func          = bus_get_properties;

	dbusmenu_method_table[METHOD_EVENT].interned_name = g_intern_static_string("Event");
	dbusmenu_method_table[METHOD_EVENT].func          = bus_event;

	dbusmenu_method_table[METHOD_EVENT_GROUP].interned_name = g_intern_static_string("EventGroup");
	dbusmenu_method_table[METHOD_EVENT_GROUP].func          = bus_event_group;

	dbusmenu_method_table[METHOD_ABOUT_TO_SHOW].interned_name = g_intern_static_string("AboutToShow");
	dbusmenu_method_table[METHOD_ABOUT_TO_SHOW].func          = bus_about_to_show;

	dbusmenu_method_table[METHOD_ABOUT_TO_SHOW_GROUP].interned_name = g_intern_static_string("AboutToShowGroup");
	dbusmenu_method_table[METHOD_ABOUT_TO_SHOW_GROUP].func          = bus_about_to_show_group;

	return;
}

static void
dbusmenu_server_init (DbusmenuServer *self)
{
	self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), DBUSMENU_TYPE_SERVER, DbusmenuServerPrivate);

	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(self);

	priv->root = NULL;
	priv->dbusobject = NULL;
	priv->layout_revision = 1;
	priv->layout_idle = 0;
	priv->bus = NULL;
	priv->bus_lookup = NULL;
	priv->find_server_signal = 0;
	priv->dbus_registration = 0;

	priv->lookup_cache = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, g_object_unref);

	default_text_direction(self);
	priv->status = DBUSMENU_STATUS_NORMAL;
	priv->icon_dirs = NULL;

	return;
}

static void
dbusmenu_server_dispose (GObject *object)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(object);

	if (priv->layout_idle != 0) {
		g_source_remove(priv->layout_idle);
		priv->layout_idle = 0;
	}
	
	if (priv->property_idle != 0) {
		g_source_remove(priv->property_idle);
		priv->property_idle = 0;
	}

	if (priv->prop_array != NULL) {
		prop_array_teardown(priv->prop_array);
		priv->prop_array = NULL;
	}

	if (priv->root != NULL) {
		dbusmenu_menuitem_foreach(priv->root, menuitem_signals_remove, object);
		g_object_unref(priv->root);
	}

	if (priv->dbus_registration != 0) {
		g_dbus_connection_unregister_object(priv->bus, priv->dbus_registration);
		priv->dbus_registration = 0;
	}

	if (priv->find_server_signal != 0) {
		g_dbus_connection_signal_unsubscribe(priv->bus, priv->find_server_signal);
		priv->find_server_signal = 0;
	}

	if (priv->bus != NULL) {
		g_object_unref(priv->bus);
		priv->bus = NULL;
	}

	if (priv->bus_lookup != NULL) {
		if (!g_cancellable_is_cancelled(priv->bus_lookup)) {
			/* Note, this may case the async function to run at
			   some point in the future.  That's okay, it'll get an
			   error, but just FYI */
			g_cancellable_cancel(priv->bus_lookup);
		}
		g_object_unref(priv->bus_lookup);
		priv->bus_lookup = NULL;
	}

	G_OBJECT_CLASS (dbusmenu_server_parent_class)->dispose (object);
	return;
}

static void
dbusmenu_server_finalize (GObject *object)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(object);

	if (priv->dbusobject != NULL) {
		g_free (priv->dbusobject);
		priv->dbusobject = NULL;
	}

	if (priv->icon_dirs != NULL) {
		g_strfreev(priv->icon_dirs);
		priv->icon_dirs = NULL;
	}

	if (priv->lookup_cache) {
		g_hash_table_destroy(priv->lookup_cache);
		priv->lookup_cache = NULL;
	}

	G_OBJECT_CLASS (dbusmenu_server_parent_class)->finalize (object);
	return;
}

static DbusmenuMenuitem *
lookup_menuitem_by_id (DbusmenuServer * server, gint id)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	DbusmenuMenuitem *res = (DbusmenuMenuitem *) g_hash_table_lookup(priv->lookup_cache, GINT_TO_POINTER(id));
	if (!res && id == 0) {
		return priv->root;
	}

	return res;
}

static void
cache_remove_entries_for_menuitem (GHashTable * cache, DbusmenuMenuitem * item)
{
	g_hash_table_remove(cache, GINT_TO_POINTER(dbusmenu_menuitem_get_id(item)));

	GList *child, *children = dbusmenu_menuitem_get_children(item);
	for (child = children; child != NULL; child = child->next) {
		cache_remove_entries_for_menuitem(cache, child->data);
	}
}

static void
cache_add_entries_for_menuitem (GHashTable * cache, DbusmenuMenuitem * item)
{
	g_hash_table_insert(cache, GINT_TO_POINTER(dbusmenu_menuitem_get_id(item)), g_object_ref(item));

	GList *child, *children = dbusmenu_menuitem_get_children(item);
	for (child = children; child != NULL; child = child->next) {
		cache_add_entries_for_menuitem(cache, child->data);
	}
}

static void
set_property (GObject * obj, guint id, const GValue * value, GParamSpec * pspec)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(obj);

	switch (id) {
	case PROP_DBUS_OBJECT:
		g_return_if_fail(priv->dbusobject == NULL);
		priv->dbusobject = g_value_dup_string(value);

		if (priv->bus == NULL) {
			if (priv->bus_lookup == NULL) {
				priv->bus_lookup = g_cancellable_new();
				g_return_if_fail(priv->bus_lookup != NULL);
			}

			g_object_ref(obj);
			g_bus_get(G_BUS_TYPE_SESSION, priv->bus_lookup, bus_got_cb, obj);
		} else {
			register_object(DBUSMENU_SERVER(obj));
		}
		break;
	case PROP_ROOT_NODE:
		if (priv->root != NULL) {
			dbusmenu_menuitem_foreach(priv->root, menuitem_signals_remove, obj);
			dbusmenu_menuitem_set_root(priv->root, FALSE);
			cache_remove_entries_for_menuitem(priv->lookup_cache, priv->root);

			GList * properties = dbusmenu_menuitem_properties_list(priv->root);
			GList * iter;
			for (iter = properties; iter != NULL; iter = g_list_next(iter)) {
				gchar * property = (gchar *)iter->data;
				menuitem_property_changed(priv->root, property, NULL, DBUSMENU_SERVER(obj));
			}
			g_list_free(properties);

			g_object_unref(G_OBJECT(priv->root));
			priv->root = NULL;
		}
		priv->root = DBUSMENU_MENUITEM(g_value_get_object(value));
		if (priv->root != NULL) {
			g_object_ref(G_OBJECT(priv->root));
			cache_add_entries_for_menuitem(priv->lookup_cache, priv->root);
			dbusmenu_menuitem_set_root(priv->root, TRUE);
			dbusmenu_menuitem_foreach(priv->root, menuitem_signals_create, obj);

			GList * properties = dbusmenu_menuitem_properties_list(priv->root);
			GList * iter;
			for (iter = properties; iter != NULL; iter = g_list_next(iter)) {
				gchar * property = (gchar *)iter->data;
				menuitem_property_changed(priv->root, property, dbusmenu_menuitem_property_get_variant(priv->root, property), DBUSMENU_SERVER(obj));
			}
			g_list_free(properties);
		} else {
			g_debug("Setting root node to NULL");
		}
		layout_update_signal(DBUSMENU_SERVER(obj));
		break;
	case PROP_TEXT_DIRECTION: {
		DbusmenuTextDirection indir = g_value_get_enum(value);
		DbusmenuTextDirection olddir = priv->text_direction;

		/* If being set to none we need to go back to default, otherwise
		   we'll set things the way that we've been told */
		if (indir == DBUSMENU_TEXT_DIRECTION_NONE) {
			default_text_direction(DBUSMENU_SERVER(obj));
		} else {
			priv->text_direction = indir;
		}

		/* If the value has changed we need to signal that on DBus */
		if (priv->text_direction != olddir && priv->bus != NULL && priv->dbusobject != NULL) {
			GVariantBuilder params;
			g_variant_builder_init(&params, G_VARIANT_TYPE_TUPLE);
			g_variant_builder_add_value(&params, g_variant_new_string(DBUSMENU_INTERFACE));
			GVariant * dict = g_variant_new_dict_entry(g_variant_new_string("TextDirection"), g_variant_new_variant(g_variant_new_string(dbusmenu_text_direction_get_nick(priv->text_direction))));
			g_variant_builder_add_value(&params, g_variant_new_array(NULL, &dict, 1));
			g_variant_builder_add_value(&params, g_variant_new_array(G_VARIANT_TYPE_STRING, NULL, 0));
			GVariant * vparams = g_variant_builder_end(&params);

			g_dbus_connection_emit_signal(priv->bus,
			                              NULL,
			                              priv->dbusobject,
			                              "org.freedesktop.DBus.Properties",
			                              "PropertiesChanged",
			                              vparams,
			                              NULL);
		}

		break;
	}
	case PROP_STATUS: {
		DbusmenuStatus instatus = g_value_get_enum(value);

		/* If the value has changed we need to signal that on DBus */
		if (priv->status != instatus && priv->bus != NULL && priv->dbusobject != NULL) {
			GVariantBuilder params;
			g_variant_builder_init(&params, G_VARIANT_TYPE_TUPLE);
			g_variant_builder_add_value(&params, g_variant_new_string(DBUSMENU_INTERFACE));
			GVariant * dict = g_variant_new_dict_entry(g_variant_new_string("Status"), g_variant_new_variant(g_variant_new_string(dbusmenu_status_get_nick(instatus))));
			g_variant_builder_add_value(&params, g_variant_new_array(NULL, &dict, 1));
			g_variant_builder_add_value(&params, g_variant_new_array(G_VARIANT_TYPE_STRING, NULL, 0));
			GVariant * vparams = g_variant_builder_end(&params);

			g_dbus_connection_emit_signal(priv->bus,
			                              NULL,
			                              priv->dbusobject,
			                              "org.freedesktop.DBus.Properties",
			                              "PropertiesChanged",
			                              vparams,
			                              NULL);
		}

		priv->status = instatus;
		break;
	}
	default:
		g_return_if_reached();
		break;
	}

	return;
}

static void
get_property (GObject * obj, guint id, GValue * value, GParamSpec * pspec)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(obj);

	switch (id) {
	case PROP_DBUS_OBJECT:
		g_value_set_string(value, priv->dbusobject);
		break;
	case PROP_ROOT_NODE:
		g_value_set_object(value, priv->root);
		break;
	case PROP_VERSION:
		g_value_set_uint(value, DBUSMENU_VERSION_NUMBER);
		break;
	case PROP_TEXT_DIRECTION:
		g_value_set_enum(value, priv->text_direction);
		break;
	case PROP_STATUS:
		g_value_set_enum(value, priv->status);
		break;
	default:
		g_return_if_reached();
		break;
	}

	return;
}

/* Determines the default text direction */
static void
default_text_direction (DbusmenuServer * server)
{
	DbusmenuTextDirection dir = DBUSMENU_TEXT_DIRECTION_NONE;
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	const gchar * env = g_getenv("DBUSMENU_TEXT_DIRECTION");
	if (env != NULL) {
		if (g_strcmp0(env, "ltr") == 0) {
			dir = DBUSMENU_TEXT_DIRECTION_LTR;
		} else if (g_strcmp0(env, "rtl") == 0) {
			dir = DBUSMENU_TEXT_DIRECTION_RTL;
		} else {
			g_warning("Value of 'DBUSMENU_TEXT_DIRECTION' is '%s' which is not one of 'rtl' or 'ltr'", env);
		}
	}

	if (dir == DBUSMENU_TEXT_DIRECTION_NONE) {
		/* TRANSLATORS: This is the direction of the text and can
		   either be the value 'ltr' for left-to-right text (English)
		   or 'rtl' for right-to-left (Arabic). */
		const gchar * default_dir = C_("default text direction", "ltr");

		if (g_strcmp0(default_dir, "ltr") == 0) {
			dir = DBUSMENU_TEXT_DIRECTION_LTR;
		} else if (g_strcmp0(default_dir, "rtl") == 0) {
			dir = DBUSMENU_TEXT_DIRECTION_RTL;
		} else {
			g_warning("Translation has an invalid value '%s' for default text direction.  Defaulting to left-to-right.", default_dir);
			dir = DBUSMENU_TEXT_DIRECTION_LTR;
		}
	}

	/* Shouldn't happen, but incase future patches make a mistake
	   this'll catch them */
	g_return_if_fail(dir != DBUSMENU_TEXT_DIRECTION_NONE);

	priv->text_direction = dir;

	return;
}

/* Register the object on the dbus bus */
static void
register_object (DbusmenuServer * server)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	/* Object info */
	g_return_if_fail(priv->bus != NULL);
	g_return_if_fail(priv->dbusobject != NULL);

	/* Class info */
	g_return_if_fail(dbusmenu_node_info != NULL);
	g_return_if_fail(dbusmenu_interface_info != NULL);

	/* We might block on this in the future, but it'd be nice if
	   we could change the object path.  Thinking about it... */
	if (priv->dbus_registration != 0) {
		g_dbus_connection_unregister_object(priv->bus, priv->dbus_registration);
		priv->dbus_registration = 0;
	}

	GError * error = NULL;
	priv->dbus_registration = g_dbus_connection_register_object(priv->bus,
	                                                            priv->dbusobject,
	                                                            dbusmenu_interface_info,
	                                                            &dbusmenu_interface_table,
	                                                            server,
	                                                            NULL,
	                                                            &error);

	if (error != NULL) {
		g_warning("Unable to register object on bus: %s", error->message);
		g_error_free(error);
		return;
	}

	/* If we've got it registered let's tell everyone about it */
	g_signal_emit(G_OBJECT(server), signals[LAYOUT_UPDATED], 0, priv->layout_revision, 0, TRUE);
	if (priv->dbusobject != NULL && priv->bus != NULL) {
		g_dbus_connection_emit_signal(priv->bus,
		                              NULL,
		                              priv->dbusobject,
		                              DBUSMENU_INTERFACE,
		                              "LayoutUpdated",
		                              g_variant_new("(ui)", priv->layout_revision, 0),
		                              NULL);
	}

	return;
}

/* Callback from asking GIO to get us the session bus */
static void
bus_got_cb (GObject * obj, GAsyncResult * result, gpointer user_data)
{
	GError * error = NULL;

	GDBusConnection * bus = g_bus_get_finish(result, &error);

	if (error != NULL) {
		g_warning("Unable to get session bus: %s", error->message);
		g_error_free(error);
		g_object_unref(G_OBJECT(user_data));
		return;
	}

	/* Note: We're not using the user_data before we check for
	   the error so that in the cancelled case at destruction of
	   the object we don't end up with an invalid object. */

	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(user_data);
	priv->bus = bus;

	priv->find_server_signal = g_dbus_connection_signal_subscribe(priv->bus,
	                                                              NULL, /* sender */
	                                                              "com.canonical.dbusmenu", /* interface */
	                                                              "FindServers", /* member */
	                                                              NULL, /* object path */
	                                                              NULL, /* arg0 */
	                                                              G_DBUS_SIGNAL_FLAGS_NONE, /* flags */
	                                                              find_servers_cb, /* cb */
	                                                              user_data, /* data */
	                                                              NULL); /* free func */

	register_object(DBUSMENU_SERVER(user_data));

	g_object_unref(G_OBJECT(user_data));
	return;
}

/* Respond to the find servers signal by sending an update
   to the bus */
static void
find_servers_cb (GDBusConnection * connection, const gchar * sender, const gchar * path, const gchar * interface, const gchar * signal, GVariant * params, gpointer user_data)
{
	layout_update_idle(user_data);
	return;
}

/* Function for the GDBus vtable to handle all method calls and dish
   them out the appropriate functions */
static void
bus_method_call (GDBusConnection * connection, const gchar * sender, const gchar * path, const gchar * interface, const gchar * method, GVariant * params, GDBusMethodInvocation * invocation, gpointer user_data)
{
	int i;
	const gchar * interned_method = g_intern_string(method);

	for (i = 0; i < METHOD_COUNT; i++) {
		if (dbusmenu_method_table[i].interned_name == interned_method) {
			if (dbusmenu_method_table[i].func != NULL) {
				return dbusmenu_method_table[i].func(DBUSMENU_SERVER(user_data), params, invocation);
			} else {
				/* If we have a null function we're responding but nothing else. */
				g_warning("Invalid function call for '%s' with parameters: %s", method, g_variant_print(params, TRUE));
				g_dbus_method_invocation_return_value(invocation, NULL);
				return;
			}
		}
	}

	/* We're here because there's an error */
	g_dbus_method_invocation_return_error(invocation,
	                                      error_quark(),
	                                      NOT_IMPLEMENTED,
	                                      "Unable to find method '%s'",
	                                      method);
	return;
}

/* For the GDBus vtable but we only have one property so it's pretty
   simple. */
static GVariant *
bus_get_prop (GDBusConnection * connection, const gchar * sender, const gchar * path, const gchar * interface, const gchar * property, GError ** error, gpointer user_data)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(user_data);

	/* None of these should happen */
	g_return_val_if_fail(g_strcmp0(interface, DBUSMENU_INTERFACE) == 0, NULL);
	g_return_val_if_fail(g_strcmp0(path, priv->dbusobject) == 0, NULL);

	if (g_strcmp0(property, "Version") == 0) {
		return g_variant_new_uint32(DBUSMENU_VERSION_NUMBER);
	} else if (g_strcmp0(property, "TextDirection") == 0) {
		return g_variant_new_string(dbusmenu_text_direction_get_nick(priv->text_direction));
	} else if (g_strcmp0(property, "IconThemePath") == 0) {
		GVariant * dirs = NULL;

		if (priv->icon_dirs != NULL) {
			dirs = g_variant_new_strv((const gchar * const *)priv->icon_dirs, -1);
		} else {
			dirs = g_variant_new_array(G_VARIANT_TYPE_STRING, NULL, 0);
		}

		return dirs;
	} else if (g_strcmp0(property, "Status") == 0) {
		return g_variant_new_string(dbusmenu_status_get_nick(priv->status));
	} else {
		g_warning("Unknown property '%s'", property);
	}

	return NULL;
}

/* Handle actually signalling in the idle loop.  This way we collect all
   the updates. */
static gboolean
layout_update_idle (gpointer user_data)
{
	DbusmenuServer * server = DBUSMENU_SERVER(user_data);
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	g_signal_emit(G_OBJECT(server), signals[LAYOUT_UPDATED], 0, priv->layout_revision, 0, TRUE);
	if (priv->dbusobject != NULL && priv->bus != NULL) {
		g_dbus_connection_emit_signal(priv->bus,
		                              NULL,
		                              priv->dbusobject,
		                              DBUSMENU_INTERFACE,
		                              "LayoutUpdated",
		                              g_variant_new("(ui)", priv->layout_revision, 0),
		                              NULL);
	}

	priv->layout_idle = 0;

	return FALSE;
}

/* Signals that the layout has been updated */
static void
layout_update_signal (DbusmenuServer * server)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);
	priv->layout_revision++;

	if (priv->layout_idle == 0) {
		priv->layout_idle = g_idle_add(layout_update_idle, server);
	}

	return;
}

typedef struct _prop_idle_item_t prop_idle_item_t;
struct _prop_idle_item_t {
	DbusmenuMenuitem * mi;
	GArray * array;
};

typedef struct _prop_idle_prop_t prop_idle_prop_t;
struct _prop_idle_prop_t {
	gchar * property;
	GVariant * variant;
};

/* Takes appart our data structure so we don't leak any
   memory or references. */
static void
prop_array_teardown (GArray * prop_array)
{
	int i, j;

	for (i = 0; i < prop_array->len; i++) {
		prop_idle_item_t * iitem = &g_array_index(prop_array, prop_idle_item_t, i);
		
		for (j = 0; j < iitem->array->len; j++) {
			prop_idle_prop_t * iprop = &g_array_index(iitem->array, prop_idle_prop_t, j);

			g_free(iprop->property);

			if (iprop->variant != NULL) {
				g_variant_unref(iprop->variant);
			}
		}

		g_object_unref(G_OBJECT(iitem->mi));
		g_array_free(iitem->array, TRUE);
	}

	g_array_free(prop_array, TRUE);

	return;
}

/* Works in the idle to send a set of property updates so that they'll
   all update in a single dbus message. */
static gboolean
menuitem_property_idle (gpointer user_data)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(user_data);

	/* Source will get removed as we return */
	priv->property_idle = 0;

	/* If there are no items, let's just not signal */
	if (priv->prop_array == NULL) {
		return FALSE;
	}

	int i, j;
	GVariantBuilder itembuilder;
	gboolean item_init = FALSE;

	GVariantBuilder removeitembuilder;
	gboolean removeitem_init = FALSE;

	for (i = 0; i < priv->prop_array->len; i++) {
		prop_idle_item_t * iitem = &g_array_index(priv->prop_array, prop_idle_item_t, i);

		/* if it's not exposed we're going to block it's properties
		   from getting into the dbus message */
		if (dbusmenu_menuitem_exposed(iitem->mi) == FALSE) {
			continue;
		}

		GVariantBuilder dictbuilder;
		gboolean dictinit = FALSE;

		GVariantBuilder removedictbuilder;
		gboolean removedictinit = FALSE;
		
		/* Go throught each item and see if it should go in the removal list
		   or the additive list. */
		for (j = 0; j < iitem->array->len; j++) {
			prop_idle_prop_t * iprop = &g_array_index(iitem->array, prop_idle_prop_t, j);

			if (iprop->variant != NULL) {
				if (!dictinit) {
					g_variant_builder_init(&dictbuilder, G_VARIANT_TYPE_DICTIONARY);
					dictinit = TRUE;
				}

				GVariant * entry = g_variant_new_dict_entry(g_variant_new_string(iprop->property),
				                                            g_variant_new_variant(iprop->variant));

				g_variant_builder_add_value(&dictbuilder, entry);
			} else {
				if (!removedictinit) {
					g_variant_builder_init(&removedictbuilder, G_VARIANT_TYPE_ARRAY);
					removedictinit = TRUE;
				}

				g_variant_builder_add_value(&removedictbuilder, g_variant_new_string(iprop->property));
			}
		}

		/* If we've got new values that are real values we need to add that
		   to the list of items to send the value of */
		if (dictinit) {
			GVariantBuilder tuplebuilder;
			g_variant_builder_init(&tuplebuilder, G_VARIANT_TYPE_TUPLE);

			g_variant_builder_add_value(&tuplebuilder, g_variant_new_int32(dbusmenu_menuitem_get_id(iitem->mi)));
			g_variant_builder_add_value(&tuplebuilder, g_variant_builder_end(&dictbuilder));

			if (!item_init) {
				g_variant_builder_init(&itembuilder, G_VARIANT_TYPE_ARRAY);
				item_init = TRUE;
			}

			g_variant_builder_add_value(&itembuilder, g_variant_builder_end(&tuplebuilder));
		}

		/* If we've got properties that have been removed then we need to add
		   them to the list of removed items */
		if (removedictinit) {
			GVariantBuilder tuplebuilder;
			g_variant_builder_init(&tuplebuilder, G_VARIANT_TYPE_TUPLE);

			g_variant_builder_add_value(&tuplebuilder, g_variant_new_int32(dbusmenu_menuitem_get_id(iitem->mi)));
			g_variant_builder_add_value(&tuplebuilder, g_variant_builder_end(&removedictbuilder));

			if (!removeitem_init) {
				g_variant_builder_init(&removeitembuilder, G_VARIANT_TYPE_ARRAY);
				removeitem_init = TRUE;
			}

			g_variant_builder_add_value(&removeitembuilder, g_variant_builder_end(&tuplebuilder));
		}
	}

	/* these are going to be standard references in all code paths and must be unrefed */
	GVariant * megadata[2];
	gboolean gotsomething = FALSE;
	gboolean error_nosend = FALSE;

	if (item_init) {
		megadata[0] = g_variant_builder_end(&itembuilder);
		g_variant_ref_sink(megadata[0]);
		gotsomething = TRUE;
	} else {
		GError * error = NULL;
		megadata[0] = g_variant_parse(G_VARIANT_TYPE("a(ia{sv})"), "[ ]", NULL, NULL, &error);

		if (error != NULL) {
			g_warning("Unable to parse '[ ]' as a 'a(ia{sv})': %s", error->message);
			g_error_free(error);
			megadata[0] = NULL;
			error_nosend = TRUE;
		}
	}

	if (removeitem_init) {
		megadata[1] = g_variant_builder_end(&removeitembuilder);
		g_variant_ref_sink(megadata[1]);
		gotsomething = TRUE;
	} else {
		GError * error = NULL;
		megadata[1] = g_variant_parse(G_VARIANT_TYPE("a(ias)"), "[ ]", NULL, NULL, &error);

		if (error != NULL) {
			g_warning("Unable to parse '[ ]' as a 'a(ias)': %s", error->message);
			g_error_free(error);
			megadata[1] = NULL;
			error_nosend = TRUE;
		}
	}

	if (gotsomething && !error_nosend && priv->dbusobject != NULL && priv->bus != NULL) {
		g_dbus_connection_emit_signal(priv->bus,
		                              NULL,
		                              priv->dbusobject,
		                              DBUSMENU_INTERFACE,
		                              "ItemsPropertiesUpdated",
		                              g_variant_new_tuple(megadata, 2),
		                              NULL);
	}

	if (megadata[0] != NULL) {
		g_variant_unref(megadata[0]);
	}

	if (megadata[1] != NULL) {
		g_variant_unref(megadata[1]);
	}

	/* Clean everything up */
	prop_array_teardown(priv->prop_array);
	priv->prop_array = NULL;

	return FALSE;
}

static void 
menuitem_property_changed (DbusmenuMenuitem * mi, gchar * property, GVariant * variant, DbusmenuServer * server)
{
	int i;
	gint item_id;

	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	item_id = dbusmenu_menuitem_get_id(mi);

	g_signal_emit(G_OBJECT(server), signals[ID_PROP_UPDATE], 0, item_id, property, variant, TRUE);

	/* See if we have a property array, if not, we need to
	   build one of these suckers */
	if (priv->prop_array == NULL) {
		priv->prop_array = g_array_new(FALSE, FALSE, sizeof(prop_idle_item_t));
	}

	/* Look to see if we already have this item in the list
	   and use it if so */
	prop_idle_item_t * item = NULL;
	for (i = 0; i < priv->prop_array->len; i++) {
		prop_idle_item_t * iitem = &g_array_index(priv->prop_array, prop_idle_item_t, i);
		if (iitem->mi == mi) {
			item = iitem;
			break;
		}
	}

	GArray * properties = NULL;
	/* If not, we'll need to build ourselves one */
	if (item == NULL) {
		prop_idle_item_t myitem;
		myitem.mi = mi;
		g_object_ref(G_OBJECT(mi));
		myitem.array = g_array_new(FALSE, FALSE, sizeof(prop_idle_prop_t));

		g_array_append_val(priv->prop_array, myitem);
		properties = myitem.array;
	} else {
		properties = item->array;
	}

	/* Check to see if this property is in the list */
	prop_idle_prop_t * prop = NULL;
	for (i = 0; i < properties->len; i++) {
		prop_idle_prop_t * iprop = &g_array_index(properties, prop_idle_prop_t, i);
		if (g_strcmp0(iprop->property, property) == 0) {
			prop = iprop;
			break;
		}
	}

	/* If it's the default value we want to treat it like a clearing
	   of the value so that it doesn't get sent over dbus and waste
	   bandwidth */
	if (dbusmenu_menuitem_property_is_default(mi, property)) {
		variant = NULL;
	}

	/* If so, we need to swap the value */
	if (prop != NULL) {
		if (prop->variant != NULL) {
			g_variant_unref(prop->variant);
		}
		prop->variant = variant;
	} else {
	/* else we need to add it */
		prop_idle_prop_t myprop;
		myprop.property = g_strdup(property);
		myprop.variant = variant;

		g_array_append_val(properties, myprop);
	}
	if (variant != NULL) {
		g_variant_ref_sink(variant);
	}

	/* Check to see if the idle is already queued, and queue it
	   if not. */
	if (priv->property_idle == 0) {
		priv->property_idle = g_idle_add(menuitem_property_idle, server);
	}

	return;
}

/* Adds the signals for this entry to the list and looks at
   the children of this entry to add the signals we need
   as well.  We like signals. */
static void
added_check_children (gpointer data, gpointer user_data)
{
	DbusmenuMenuitem * mi = (DbusmenuMenuitem *)data;
	DbusmenuServer * server = (DbusmenuServer *)user_data;

	menuitem_signals_create(mi, server);
	g_list_foreach(dbusmenu_menuitem_get_children(mi), added_check_children, server);

	return;
}

/* Callback for when a child is added.  We need to connect everything
   up and signal that the layout has changed. */
static void
menuitem_child_added (DbusmenuMenuitem * parent, DbusmenuMenuitem * child, guint pos, DbusmenuServer * server)
{
	menuitem_signals_create(child, server);
	cache_add_entries_for_menuitem(server->priv->lookup_cache, child);
	g_list_foreach(dbusmenu_menuitem_get_children(child), added_check_children, server);

	layout_update_signal(server);
	return;
}

static void 
menuitem_child_removed (DbusmenuMenuitem * parent, DbusmenuMenuitem * child, DbusmenuServer * server)
{
	menuitem_signals_remove(child, server);
	cache_remove_entries_for_menuitem(server->priv->lookup_cache, child);
	layout_update_signal(server);
	return;
}

static void 
menuitem_child_moved (DbusmenuMenuitem * parent, DbusmenuMenuitem * child, guint newpos, guint oldpos, DbusmenuServer * server)
{
	layout_update_signal(server);
	return;
}

/* Called when a menu item emits its activated signal so it
   gets passed across the bus. */
static void 
menuitem_shown (DbusmenuMenuitem * mi, guint timestamp, DbusmenuServer * server)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	g_signal_emit(G_OBJECT(server), signals[ITEM_ACTIVATION], 0, dbusmenu_menuitem_get_id(mi), timestamp, TRUE);

	if (priv->dbusobject != NULL && priv->bus != NULL) {
		g_dbus_connection_emit_signal(priv->bus,
		                              NULL,
		                              priv->dbusobject,
		                              DBUSMENU_INTERFACE,
		                              "ItemActivationRequested",
		                              g_variant_new("(iu)", dbusmenu_menuitem_get_id(mi), timestamp),
		                              NULL);
	}

	return;
}

/* Connects all the signals that we're interested in
   coming from a menuitem */
static void
menuitem_signals_create (DbusmenuMenuitem * mi, gpointer data)
{
	g_signal_connect(G_OBJECT(mi), DBUSMENU_MENUITEM_SIGNAL_CHILD_ADDED, G_CALLBACK(menuitem_child_added), data);
	g_signal_connect(G_OBJECT(mi), DBUSMENU_MENUITEM_SIGNAL_CHILD_REMOVED, G_CALLBACK(menuitem_child_removed), data);
	g_signal_connect(G_OBJECT(mi), DBUSMENU_MENUITEM_SIGNAL_CHILD_MOVED, G_CALLBACK(menuitem_child_moved), data);
	g_signal_connect(G_OBJECT(mi), DBUSMENU_MENUITEM_SIGNAL_PROPERTY_CHANGED, G_CALLBACK(menuitem_property_changed), data);
	g_signal_connect(G_OBJECT(mi), DBUSMENU_MENUITEM_SIGNAL_SHOW_TO_USER, G_CALLBACK(menuitem_shown), data);
	return;
}

/* Removes all the signals that we're interested in
   coming from a menuitem */
static void
menuitem_signals_remove (DbusmenuMenuitem * mi, gpointer data)
{
	g_signal_handlers_disconnect_by_func(G_OBJECT(mi), G_CALLBACK(menuitem_child_added), data);
	g_signal_handlers_disconnect_by_func(G_OBJECT(mi), G_CALLBACK(menuitem_child_removed), data);
	g_signal_handlers_disconnect_by_func(G_OBJECT(mi), G_CALLBACK(menuitem_child_moved), data);
	g_signal_handlers_disconnect_by_func(G_OBJECT(mi), G_CALLBACK(menuitem_property_changed), data);
	g_signal_handlers_disconnect_by_func(G_OBJECT(mi), G_CALLBACK(menuitem_shown), data);
	return;
}

static GQuark
error_quark (void)
{
	static GQuark quark = 0;
	if (quark == 0) {
		quark = g_quark_from_static_string (G_LOG_DOMAIN);
	}
	return quark;
}

/* DBus interface */
static void
bus_get_layout (DbusmenuServer * server, GVariant * params, GDBusMethodInvocation * invocation)
{
	g_return_if_fail(DBUSMENU_IS_SERVER(server));
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);
	g_return_if_fail(priv != NULL);

	/* Input */
	gint32 parent;
	gint32 recurse;
	const gchar ** props;

	g_variant_get(params, "(ii^a&s)", &parent, &recurse, &props);

	/* Output */
	guint revision = priv->layout_revision;
	GVariant * items = NULL;

	if (priv->root != NULL) {
		DbusmenuMenuitem * mi = lookup_menuitem_by_id(server, parent);

		if (mi != NULL) {
			items = dbusmenu_menuitem_build_variant(mi, props, recurse);
			if (items) {
				g_variant_ref_sink(items);
			}
		}
	}
	g_free(props);

	/* What happens if we don't have anything? */
	if (items == NULL) {
		if (parent == 0) {
			/* We should always have a root, so we'll make up one for
			   right now. */
			items = g_variant_parse(G_VARIANT_TYPE("(ia{sv}av)"), "(0, [], [])", NULL, NULL, NULL);
		} else {
			/* If we were looking for a specific ID that's an error that
			   we should send back, so let's do that. */
			g_dbus_method_invocation_return_error(invocation,
				                                  error_quark(),
				                                  INVALID_MENUITEM_ID,
				                                  "The ID supplied %d does not refer to a menu item we have",
				                                  parent);
			return;
		}
	}

	/* Build the final variant tuple */
	GVariantBuilder tuplebuilder;
	g_variant_builder_init(&tuplebuilder, G_VARIANT_TYPE_TUPLE);

	g_variant_builder_add_value(&tuplebuilder, g_variant_new_uint32(revision));
	g_variant_builder_add_value(&tuplebuilder, items);

	g_variant_unref(items);

	GVariant * retval = g_variant_builder_end(&tuplebuilder);
	// g_debug("Sending layout type: %s", g_variant_get_type_string(retval));
	g_dbus_method_invocation_return_value(invocation,
	                                      retval);
	return;
}

/* Get a single property off of a single menuitem */
static void
bus_get_property (DbusmenuServer * server, GVariant * params, GDBusMethodInvocation * invocation)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	if (priv->root == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			            error_quark(),
			            NO_VALID_LAYOUT,
			            "There currently isn't a layout in this server");
		return;
	}

	gint32 id;
	const gchar * property;

	g_variant_get(params, "(i&s)", &id, &property);

	DbusmenuMenuitem * mi = lookup_menuitem_by_id(server, id);

	if (mi == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			            error_quark(),
			            INVALID_MENUITEM_ID,
			            "The ID supplied %d does not refer to a menu item we have",
			            id);
		return;
	}

	GVariant * variant = dbusmenu_menuitem_property_get_variant(mi, property);
	if (variant == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			            error_quark(),
			            INVALID_PROPERTY_NAME,
			            "The property '%s' does not exist on menuitem with ID of %d",
			            property,
			            id);
		return;
	}

	g_dbus_method_invocation_return_value(invocation, g_variant_new("(v)", variant));
	return;
}

/* Get some properties off of a single menuitem */
static void
bus_get_properties (DbusmenuServer * server, GVariant * params, GDBusMethodInvocation * invocation)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);
	
	if (priv->root == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			            error_quark(),
			            NO_VALID_LAYOUT,
			            "There currently isn't a layout in this server");
		return;
	}

	gint32 id;
	g_variant_get(params, "(i)", &id);

	DbusmenuMenuitem * mi = lookup_menuitem_by_id(server, id);

	if (mi == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			            error_quark(),
			            INVALID_MENUITEM_ID,
			            "The ID supplied %d does not refer to a menu item we have",
			            id);
		return;
	}

	GVariant * dict = dbusmenu_menuitem_properties_variant(mi, NULL);

	g_dbus_method_invocation_return_value(invocation, g_variant_new("(a{sv})", dict));

	return;
}

/* Handles getting a bunch of properties from a variety of menu items
   to make one mega dbus message */
static void
bus_get_group_properties (DbusmenuServer * server, GVariant * params, GDBusMethodInvocation * invocation)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	if (priv->root == NULL) {
		/* Allow a request for just id 0 when root is null. Return no properties.
		   So that a request always returns a valid structure no matter the
		   state of the structure in the server.
		*/
		GVariant * idlist = g_variant_get_child_value(params, 0);
		if (g_variant_n_children(idlist) == 1) {

			GVariant *id_v = g_variant_get_child_value(idlist, 0);
			gint32 id = g_variant_get_int32(id_v);
			g_variant_unref(id_v);

			if (id == 0) {

				GVariant * final = g_variant_parse(G_VARIANT_TYPE("(a(ia{sv}))"), "([(0, {})],)", NULL, NULL, NULL);
				g_dbus_method_invocation_return_value(invocation, final);
				g_variant_unref(final);
			}
		} else {

			g_dbus_method_invocation_return_error(invocation,
					          error_quark(),
					          NO_VALID_LAYOUT,
					          "There currently isn't a layout in this server");
		}
		g_variant_unref(idlist);
		return;
	}

	GVariantIter *ids;
	g_variant_get(params, "(aias)", &ids, NULL);
	/* TODO: implementation ignores propertyNames declared in XML */

	GVariantBuilder builder;
	gboolean builder_init = FALSE;

	gint32 id;
	while (g_variant_iter_loop(ids, "i", &id)) {
		DbusmenuMenuitem * mi = lookup_menuitem_by_id(server, id);
		if (mi == NULL) continue;

		if (!builder_init) {
			g_variant_builder_init(&builder, G_VARIANT_TYPE_ARRAY);
			builder_init = TRUE;
		}

		GVariantBuilder wbuilder;
		g_variant_builder_init(&wbuilder, G_VARIANT_TYPE_TUPLE);
		g_variant_builder_add(&wbuilder, "i", id);
		GVariant * props = dbusmenu_menuitem_properties_variant(mi, NULL);
		if (props != NULL) {
			g_variant_ref(props);
		}

		if (props == NULL) {
			GError * error = NULL;
			props = g_variant_parse(G_VARIANT_TYPE("a{sv}"), "{}", NULL, NULL, &error);
			if (error != NULL) {
				g_warning("Unable to parse '{}' as a 'a{sv}': %s", error->message);
				g_error_free(error);
				props = NULL;
			}
		}

		g_variant_builder_add_value(&wbuilder, props);
		g_variant_unref(props);
		GVariant * mi_data = g_variant_builder_end(&wbuilder);

		g_variant_builder_add_value(&builder, mi_data);
	}
	g_variant_iter_free(ids);

	/* a standard reference that must be unrefed */
	GVariant * ret = NULL;
	
	if (builder_init) {
		ret = g_variant_builder_end(&builder);
		g_variant_ref_sink(ret);
	} else {
		GError * error = NULL;
		ret = g_variant_parse(G_VARIANT_TYPE("a(ia{sv})"), "[]", NULL, NULL, &error);
		if (error != NULL) {
			g_warning("Unable to parse '[]' as a 'a(ia{sv})': %s", error->message);
			g_error_free(error);
		}
	}

	GVariant * final = NULL;
	if (ret != NULL) {
		g_variant_builder_init(&builder, G_VARIANT_TYPE_TUPLE);
		g_variant_builder_add_value(&builder, ret);
		g_variant_unref(ret);
		final = g_variant_builder_end(&builder);
	} else {
		g_warning("Error building property list, final variant is NULL");
	}

	g_dbus_method_invocation_return_value(invocation, final);

	return;
}

/* Turn a menuitem into an variant and attach it to the
   VariantBuilder we passed in */
static void
serialize_menuitem(gpointer data, gpointer user_data)
{
	DbusmenuMenuitem * mi = DBUSMENU_MENUITEM(data);
	GVariantBuilder * builder = (GVariantBuilder *)(user_data);
	GVariantBuilder tuple;
	
	g_variant_builder_init(&tuple, G_VARIANT_TYPE_TUPLE);

	gint id = dbusmenu_menuitem_get_id(mi);
	g_variant_builder_add_value(&tuple, g_variant_new_int32(id));

	GVariant * props = dbusmenu_menuitem_properties_variant(mi, NULL);
	g_variant_builder_add_value(&tuple, props);

	g_variant_builder_add_value(builder, g_variant_builder_end(&tuple));

	return;
}

/* Gets the children and their properties of the ID that is
   passed into the function */
static void
bus_get_children (DbusmenuServer * server, GVariant * params, GDBusMethodInvocation * invocation)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);
	gint32 id;
	g_variant_get(params, "(i)", &id);

	if (priv->root == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			            error_quark(),
			            NO_VALID_LAYOUT,
			            "There currently isn't a layout in this server");
		return;
	}

	DbusmenuMenuitem * mi = lookup_menuitem_by_id(server, id);

	if (mi == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			                                  error_quark(),
			                                  INVALID_MENUITEM_ID,
			                                  "The ID supplied %d does not refer to a menu item we have",
			                                  id);
		return;
	}

	GList * children = dbusmenu_menuitem_get_children(mi);
	GVariant * ret = NULL;

	if (children != NULL) {
		GVariantBuilder builder;
		g_variant_builder_init(&builder, G_VARIANT_TYPE_ARRAY); 

		g_list_foreach(children, serialize_menuitem, &builder);

		GVariant * end = g_variant_builder_end(&builder);
		ret = g_variant_new_tuple(&end, 1);
		g_variant_ref_sink(ret);
	} else {
		GError * error = NULL;
		ret = g_variant_parse(G_VARIANT_TYPE("(a(ia{sv}))"), "([(0, {})],)", NULL, NULL, &error);
		if (error != NULL) {
			g_warning("Unable to parse '([(0, {})],)' as a '(a(ia{sv}))': %s", error->message);
			g_error_free(error);
			ret = NULL;
		}
	}

	g_dbus_method_invocation_return_value(invocation, ret);
	g_variant_unref(ret);
	return;
}

/* Structure for holding the event data for the idle function
   to pick it up. */
typedef struct _idle_event_t idle_event_t;
struct _idle_event_t {
	DbusmenuMenuitem * mi;
	gchar * eventid;
	GVariant * variant;
	guint timestamp;
};

/* A handler for else where in the main loop so that the dbusmenu
   event response doesn't get blocked */
static gboolean
event_local_handler (gpointer user_data)
{
	idle_event_t * data = (idle_event_t *)user_data;

	dbusmenu_menuitem_handle_event(data->mi, data->eventid, data->variant, data->timestamp);

	g_object_unref(data->mi);
	g_free(data->eventid);
	g_variant_unref(data->variant);
	g_free(data);
	return FALSE;
}

/* The core menu finding and doing the work part of the two
   event functions */
static gboolean
bus_event_core (DbusmenuServer * server, gint32 id, gchar * event_type, GVariant * data, guint32 timestamp)
{
	DbusmenuMenuitem * mi = lookup_menuitem_by_id(server, id);

	if (mi == NULL) {
		return FALSE;
	}

	idle_event_t * event_data = g_new0(idle_event_t, 1);
	event_data->mi = g_object_ref(mi);
	event_data->eventid = g_strdup(event_type);
	event_data->timestamp = timestamp;
	event_data->variant = g_variant_ref(data);

	g_timeout_add(0, event_local_handler, event_data);

	return TRUE;
}

/* Handles the events coming off of DBus */
static void
bus_event (DbusmenuServer * server, GVariant * params, GDBusMethodInvocation * invocation)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	if (priv->root == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			            error_quark(),
			            NO_VALID_LAYOUT,
			            "There currently isn't a layout in this server");
		return;
	}

	gint32 id;
	gchar *etype;
	GVariant *data;
	guint32 ts;

	g_variant_get(params, "(isvu)", &id, &etype, &data, &ts);

	if (!bus_event_core(server, id, etype, data, ts)) {
		g_dbus_method_invocation_return_error(invocation,
			                                  error_quark(),
			                                  INVALID_MENUITEM_ID,
			                                  "The ID supplied %d does not refer to a menu item we have",
			                                  id);
	} else {
		if (~g_dbus_message_get_flags (g_dbus_method_invocation_get_message (invocation)) & G_DBUS_MESSAGE_FLAGS_NO_REPLY_EXPECTED) {
			g_dbus_method_invocation_return_value(invocation, NULL);
		} else {
			g_object_unref(invocation);
		}
	}

	g_free(etype);
	g_variant_unref(data);

	return;
}

/* Respond to the event group method that will send events to a
   variety of menuitems */
static void
bus_event_group (DbusmenuServer * server, GVariant * params, GDBusMethodInvocation * invocation)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	if (priv->root == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			            error_quark(),
			            NO_VALID_LAYOUT,
			            "There currently isn't a layout in this server");
		return;
	}

	GVariant * events = g_variant_get_child_value(params, 0);
	gint32 id;
	gchar *etype;
	GVariant *data;
	guint32 ts;
	GVariantIter iter;
	GVariantBuilder builder;

	g_variant_iter_init(&iter, events);
	g_variant_builder_init(&builder, G_VARIANT_TYPE("ai"));
	gboolean gotone = FALSE;

	while (g_variant_iter_loop(&iter, "(isvu)", &id, &etype, &data, &ts)) {
		if (bus_event_core(server, id, etype, data, ts)) {
			gotone = TRUE;
		} else {
			g_variant_builder_add_value(&builder, g_variant_new_int32(id));
		}
	}

	GVariant * errors = g_variant_builder_end(&builder);
	g_variant_ref_sink(errors);

	if (gotone) {
		if (~g_dbus_message_get_flags (g_dbus_method_invocation_get_message (invocation)) & G_DBUS_MESSAGE_FLAGS_NO_REPLY_EXPECTED) {
			g_dbus_method_invocation_return_value(invocation, g_variant_new_tuple(&errors, 1));
		} else {
			g_object_unref(invocation);
		}
	} else {
		gchar * ids = g_variant_print(errors, FALSE);
		g_dbus_method_invocation_return_error(invocation,
			                                  error_quark(),
			                                  INVALID_MENUITEM_ID,
			                                  "The IDs supplied '%s' do not refer to any menu items we have",
			                                  ids);
		g_free(ids);
	}

	g_variant_unref(errors);
	g_variant_unref(events);

	return;
}

/* Does the about-to-show in an idle loop so we don't block things */
/* NOTE: this only works so easily as we don't return the value, if we
   were to do that it would get more complex. */
static gboolean
bus_about_to_show_idle (gpointer user_data)
{
	DbusmenuMenuitem * mi = DBUSMENU_MENUITEM(user_data);
	dbusmenu_menuitem_send_about_to_show(mi, NULL, NULL);
	g_object_unref(mi);
	return FALSE;
}

/* Recieve the About To Show function.  Pass it to our menu item. */
static void
bus_about_to_show (DbusmenuServer * server, GVariant * params, GDBusMethodInvocation * invocation)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	if (priv->root == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			            error_quark(),
			            NO_VALID_LAYOUT,
			            "There currently isn't a layout in this server");
		return;
	}

	gint32 id;
	g_variant_get(params, "(i)", &id);
	DbusmenuMenuitem * mi = lookup_menuitem_by_id(server, id);

	if (mi == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			                                  error_quark(),
			                                  INVALID_MENUITEM_ID,
			                                  "The ID supplied %d does not refer to a menu item we have",
			                                  id);
		return;
	}

	g_timeout_add(0, bus_about_to_show_idle, g_object_ref(mi));

	/* GTK+ does not support about-to-show concept for now */
	g_dbus_method_invocation_return_value(invocation,
	                                      g_variant_new("(b)", FALSE));
	return;
}

/* Handle the about to show on a set of menus and tell all of them that
   we love them */
static void
bus_about_to_show_group (DbusmenuServer * server, GVariant * params, GDBusMethodInvocation * invocation)
{
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	if (priv->root == NULL) {
		g_dbus_method_invocation_return_error(invocation,
			            error_quark(),
			            NO_VALID_LAYOUT,
			            "There currently isn't a layout in this server");
		return;
	}

	gint32 id;
	GVariantIter iter;
	GVariantBuilder builder;

	GVariant * items = g_variant_get_child_value(params, 0);
	g_variant_iter_init(&iter, items);
	g_variant_builder_init(&builder, G_VARIANT_TYPE("ai"));
	gboolean gotone = FALSE;

	while (g_variant_iter_loop(&iter, "i", &id)) {
		DbusmenuMenuitem * mi = lookup_menuitem_by_id(server, id);
		if (mi != NULL) {
			g_timeout_add(0, bus_about_to_show_idle, g_object_ref(mi));
			gotone = TRUE;
		} else {
			g_variant_builder_add_value(&builder, g_variant_new_int32(id));
		}
	}

	GVariant * errors = g_variant_builder_end(&builder);
	g_variant_ref_sink(errors);

	if (gotone) {
		if (~g_dbus_message_get_flags (g_dbus_method_invocation_get_message (invocation)) & G_DBUS_MESSAGE_FLAGS_NO_REPLY_EXPECTED) {
			GVariantBuilder tuple;
			g_variant_builder_init(&tuple, G_VARIANT_TYPE_TUPLE);

			/* Updates needed */
			g_variant_builder_add_value(&tuple, g_variant_new_array(G_VARIANT_TYPE_INT32, NULL, 0));
			/* Errors */
			g_variant_builder_add_value(&tuple, errors);

			g_dbus_method_invocation_return_value(invocation, g_variant_builder_end(&tuple));
		} else {
			g_object_unref(invocation);
		}
	} else {
		gchar * ids = g_variant_print(errors, FALSE);
		g_dbus_method_invocation_return_error(invocation,
			                                  error_quark(),
			                                  INVALID_MENUITEM_ID,
			                                  "The IDs supplied '%s' do not refer to any menu items we have",
			                                  ids);
		g_free(ids);
	}

	g_variant_unref(errors);
	g_variant_unref(items);

	return;
}

/* Public Interface */
/**
	dbusmenu_server_new:
	@object: The object name to show for this menu structure
		on DBus.  May be NULL.

	Creates a new #DbusmenuServer object with a specific object
	path on DBus.  If @object is set to NULL the default object
	name of "/com/canonical/dbusmenu" will be used.

	Return value: A brand new #DbusmenuServer
*/
DbusmenuServer *
dbusmenu_server_new (const gchar * object)
{
	if (object == NULL) {
		object = "/com/canonical/dbusmenu";
	}

	DbusmenuServer * self = g_object_new(DBUSMENU_TYPE_SERVER,
	                                     DBUSMENU_SERVER_PROP_DBUS_OBJECT, object,
	                                     NULL);

	return self;
}

/**
	dbusmenu_server_set_root:
	@self: The #DbusmenuServer object to set the root on
	@root: The new root #DbusmenuMenuitem tree

	This function contains all of the #GValue wrapping
	required to set the property #DbusmenuServer:root-node
	on the server @self.
*/
void
dbusmenu_server_set_root (DbusmenuServer * self, DbusmenuMenuitem * root)
{
	g_return_if_fail(DBUSMENU_IS_SERVER(self));
	g_return_if_fail(DBUSMENU_IS_MENUITEM(root));

	/* g_debug("Setting root object: 0x%X", (unsigned int)root); */
	GValue rootvalue = {0};
	g_value_init(&rootvalue, G_TYPE_OBJECT);
	g_value_set_object(&rootvalue, root);
	g_object_set_property(G_OBJECT(self), DBUSMENU_SERVER_PROP_ROOT_NODE, &rootvalue);
	g_object_unref(G_OBJECT(root));
	return;
}

/**
	dbusmenu_server_get_text_direction:
	@server: The #DbusmenuServer object to get the text direction from

	Returns the value of the text direction that is being exported
	over DBus for this server.  It should relate to the direction
	of the labels and other text fields that are being exported by
	this server.

	Return value: Text direction exported for this server.
*/
DbusmenuTextDirection
dbusmenu_server_get_text_direction (DbusmenuServer * server)
{
	g_return_val_if_fail(DBUSMENU_IS_SERVER(server), DBUSMENU_TEXT_DIRECTION_NONE);

	GValue val = {0};
	g_value_init(&val, DBUSMENU_TYPE_TEXT_DIRECTION);
	g_object_get_property(G_OBJECT(server), DBUSMENU_SERVER_PROP_TEXT_DIRECTION, &val);

	DbusmenuTextDirection retval = g_value_get_enum(&val);
	g_value_unset(&val);

	return retval;
}

/**
	dbusmenu_server_set_text_direction:
	@server: The #DbusmenuServer object to set the text direction on
	@dir: Direction of the text

	Sets the text direction that should be exported over DBus for
	this server.  If the value is set to #DBUSMENU_TEXT_DIRECTION_NONE
	the default detection will be used for setting the value and
	exported over DBus.
*/
void
dbusmenu_server_set_text_direction (DbusmenuServer * server, DbusmenuTextDirection dir)
{
	g_return_if_fail(DBUSMENU_IS_SERVER(server));
	g_return_if_fail(dir == DBUSMENU_TEXT_DIRECTION_NONE || dir == DBUSMENU_TEXT_DIRECTION_LTR || dir == DBUSMENU_TEXT_DIRECTION_RTL);

	GValue newval = {0};
	g_value_init(&newval, DBUSMENU_TYPE_TEXT_DIRECTION);
	g_value_set_enum(&newval, dir);
	g_object_set_property(G_OBJECT(server), DBUSMENU_SERVER_PROP_TEXT_DIRECTION, &newval);
	g_value_unset(&newval);
	return;
}

/**
	dbusmenu_server_get_status:
	@server: The #DbusmenuServer to get the status from

	Gets the current statust hat the server is sending out over
	DBus.

	Return value: The current status the server is sending
*/
DbusmenuStatus
dbusmenu_server_get_status (DbusmenuServer * server)
{
	g_return_val_if_fail(DBUSMENU_IS_SERVER(server), DBUSMENU_STATUS_NORMAL);

	GValue val = {0};
	g_value_init(&val, DBUSMENU_TYPE_STATUS);
	g_object_get_property(G_OBJECT(server), DBUSMENU_SERVER_PROP_STATUS, &val);

	DbusmenuStatus retval = g_value_get_enum(&val);
	g_value_unset(&val);

	return retval;
}

/**
	dbusmenu_server_set_status:
	@server: The #DbusmenuServer to set the status on
	@status: Status value to set on the server

	Changes the status of the server.
*/
void
dbusmenu_server_set_status (DbusmenuServer * server, DbusmenuStatus status)
{
	g_return_if_fail(DBUSMENU_IS_SERVER(server));

	GValue val = {0};
	g_value_init(&val, DBUSMENU_TYPE_STATUS);
	g_value_set_enum(&val, status);
	g_object_set_property(G_OBJECT(server), DBUSMENU_SERVER_PROP_STATUS, &val);
	g_value_unset(&val);

	return;
}

/**
 * dbusmenu_server_get_icon_paths:
 * @server: The #DbusmenuServer to get the icon paths from
 * 
 * Gets the stored and exported icon paths from the server.
 * 
 * Return value: (transfer none): A NULL-terminated list of icon paths with
 *   memory managed by the server.  Duplicate if you want
 *   to keep them.
 */
GStrv
dbusmenu_server_get_icon_paths (DbusmenuServer * server)
{
	g_return_val_if_fail(DBUSMENU_IS_SERVER(server), NULL);
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);
	return priv->icon_dirs;
}

/**
	dbusmenu_server_set_icon_paths:
	@server: The #DbusmenuServer to set the icon paths on

	Sets the icon paths for the server.  This will replace previously
	set icon theme paths.
*/
void
dbusmenu_server_set_icon_paths (DbusmenuServer * server, GStrv icon_paths)
{
	g_return_if_fail(DBUSMENU_IS_SERVER(server));
	DbusmenuServerPrivate * priv = DBUSMENU_SERVER_GET_PRIVATE(server);

	if (priv->icon_dirs != NULL) {
		g_strfreev(priv->icon_dirs);
		priv->icon_dirs = NULL;
	}

	if (icon_paths != NULL) {
		priv->icon_dirs = g_strdupv(icon_paths);
	}

	if (priv->bus != NULL && priv->dbusobject != NULL) {
		GVariantBuilder params;
		g_variant_builder_init(&params, G_VARIANT_TYPE_TUPLE);
		g_variant_builder_add_value(&params, g_variant_new_string(DBUSMENU_INTERFACE));
		GVariant * items = NULL;
		if (priv->icon_dirs != NULL) {
			GVariant * dict = g_variant_new_dict_entry(g_variant_new_string("IconThemePath"), g_variant_new_variant(g_variant_new_strv((const gchar * const *)priv->icon_dirs, -1)));
			items = g_variant_new_array(NULL, &dict, 1);
		} else {
			items = g_variant_new_array(G_VARIANT_TYPE("{sv}"), NULL, 0);
		}
		g_variant_builder_add_value(&params, items);
		g_variant_builder_add_value(&params, g_variant_new_array(G_VARIANT_TYPE_STRING, NULL, 0));
		GVariant * vparams = g_variant_builder_end(&params);

		g_dbus_connection_emit_signal(priv->bus,
		                              NULL,
		                              priv->dbusobject,
		                              "org.freedesktop.DBus.Properties",
		                              "PropertiesChanged",
		                              vparams,
		                              NULL);
	}

	return;
}
