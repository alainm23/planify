/*
A library to communicate a menu object set accross DBus and
track updates and maintain consistency.

Copyright 2010 Canonical Ltd.

Authors:
    Aurélien Gâteau <aurelien.gateau@canonical.com>

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
#include <glib.h>
#include <gio/gio.h>

#include <json-glib/json-glib.h>

#include <libdbusmenu-glib/server.h>
#include <libdbusmenu-glib/menuitem.h>

#define USAGE "dbusmenubench-glibapp <path/to/menu.json>"

static void
set_props (DbusmenuMenuitem * mi, JsonObject * node)
{
	if (node == NULL) return;

	GList * members = NULL;
	for (members = json_object_get_members(node); members != NULL; members = g_list_next(members)) {
		const gchar * member = members->data;

		if (!g_strcmp0(member, "id")) { continue; }
		if (!g_strcmp0(member, "submenu")) { continue; }

		JsonNode * lnode = json_object_get_member(node, member);
		if (JSON_NODE_TYPE(lnode) != JSON_NODE_VALUE) { continue; }

		dbusmenu_menuitem_property_set(mi, member, json_node_get_string(lnode));
	}

	return;
}

static DbusmenuMenuitem *
layout2menuitem (JsonNode * inlayout)
{
	if (inlayout == NULL) return NULL;
	if (JSON_NODE_TYPE(inlayout) != JSON_NODE_OBJECT) return NULL;

	JsonObject * layout = json_node_get_object(inlayout);

	DbusmenuMenuitem * local = NULL;
	if (json_object_has_member(layout, "id")) {
		JsonNode * node = json_object_get_member(layout, "id");
		g_return_val_if_fail(JSON_NODE_TYPE(node) == JSON_NODE_VALUE, NULL);
		local = dbusmenu_menuitem_new_with_id(json_node_get_int(node));
	} else {
		local = dbusmenu_menuitem_new();
	}

	set_props(local, layout);

	if (json_object_has_member(layout, "submenu")) {
		JsonNode * node = json_object_get_member(layout, "submenu");
		g_return_val_if_fail(JSON_NODE_TYPE(node) == JSON_NODE_ARRAY, local);
		JsonArray * array = json_node_get_array(node);
		guint count;
		for (count = 0; count < json_array_get_length(array); count++) {
			DbusmenuMenuitem * child = layout2menuitem(json_array_get_element(array, count));
			if (child != NULL) {
				dbusmenu_menuitem_child_append(local, child);
			}
		}
	}

	/* g_debug("Layout to menu return: 0x%X", (unsigned int)local); */
	return local;
}

void init_menu(DbusmenuMenuitem *root, const char *filename)
{
	JsonParser * parser = json_parser_new();
	GError * error = NULL;
	if (!json_parser_load_from_file(parser, filename, &error)) {
		g_debug("Failed parsing file %s because: %s", filename, error->message);
		return;
	}
	JsonNode * root_node = json_parser_get_root(parser);
	if (JSON_NODE_TYPE(root_node) != JSON_NODE_ARRAY) {
		g_debug("Root node is not an array, fail.  It's an: %s", json_node_type_name(root_node));
		return;
	}

	JsonArray * root_array = json_node_get_array(root_node);
	int pos;
	int count = json_array_get_length(root_array);
	for (pos=0; pos < count; ++pos) {
		DbusmenuMenuitem *child = layout2menuitem(json_array_get_element(root_array, pos));
		dbusmenu_menuitem_child_append(root, child);
	}
}

static void
on_bus (GDBusConnection * connection, const gchar * name, gpointer user_data)
{
	DbusmenuServer *server = dbusmenu_server_new("/MenuBar");
	DbusmenuMenuitem *root = dbusmenu_menuitem_new_with_id(0);
	init_menu(root, (gchar *)user_data);
	dbusmenu_server_set_root(server, root);

	return;
}

static void
name_lost (GDBusConnection * connection, const gchar * name, gpointer user_data)
{
	g_error("Unable to get name '%s' on DBus", name);
	return;
}

int main (int argc, char ** argv)
{
	if (argc != 2) {
		g_warning(USAGE);
		return 1;
	}
	const char *filename = argv[1];

	g_bus_own_name(G_BUS_TYPE_SESSION,
	               "org.dbusmenu.test",
	               G_BUS_NAME_OWNER_FLAGS_NONE,
	               on_bus,
	               NULL,
	               name_lost,
	               (gpointer)filename,
	               NULL);

	g_main_loop_run(g_main_loop_new(NULL, FALSE));

	return 0;
}
