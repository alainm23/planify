/*
A loader to turn JSON into dbusmenu menuitems

Copyright 2010 Canonical Ltd.

Authors:
    Ted Gould <ted@canonical.com>

This program is free software: you can redistribute it and/or modify it 
under the terms of the GNU General Public License version 3, as published 
by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranties of 
MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR 
PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along 
with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "json-loader.h"

static GVariant * node2variant (JsonNode * node, const gchar * name);

static void
array_byte_foreach (JsonArray * array, guint index, JsonNode * node, gpointer user_data)
{
	g_return_if_fail(JSON_NODE_TYPE(node) == JSON_NODE_VALUE);
	g_return_if_fail(json_node_get_value_type(node) == G_TYPE_INT || json_node_get_value_type(node) == G_TYPE_INT64);

	GVariantBuilder * builder = (GVariantBuilder *)user_data;

	g_variant_builder_add_value(builder, g_variant_new_byte(json_node_get_int(node)));
	return;
}

static void
array_foreach (JsonArray * array, guint index, JsonNode * node, gpointer user_data)
{
	GVariantBuilder * builder = (GVariantBuilder *)user_data;
	GVariant * variant = node2variant(node, NULL);
	if (variant != NULL) {
		g_variant_builder_add_value(builder, variant);
	}
	return;
}

static void
object_foreach (JsonObject * array, const gchar * member, JsonNode * node, gpointer user_data)
{
	GVariantBuilder * builder = (GVariantBuilder *)user_data;
	GVariant * variant = node2variant(node, member);
	if (variant != NULL) {
		g_variant_builder_add(builder, "{sv}", member, variant);
	}
	return;
}

static GVariant *
node2variant (JsonNode * node, const gchar * name)
{
	if (node == NULL) {
		return NULL;
	}

	if (JSON_NODE_TYPE(node) == JSON_NODE_VALUE) {
		switch (json_node_get_value_type(node)) {
		case G_TYPE_INT:
		case G_TYPE_INT64:
			return g_variant_new_int32(json_node_get_int(node));
		case G_TYPE_DOUBLE:
		case G_TYPE_FLOAT:
			return g_variant_new_double(json_node_get_double(node));
		case G_TYPE_BOOLEAN:
			return g_variant_new_boolean(json_node_get_boolean(node));
		case G_TYPE_STRING: {
			if (g_strcmp0(name, DBUSMENU_MENUITEM_PROP_ICON_DATA) != 0) {
				return g_variant_new_string(json_node_get_string(node));
			} else {
				gsize length;
				guchar * b64 = g_base64_decode(json_node_get_string(node), &length);
				GVariant * retval = g_variant_new_fixed_array(G_VARIANT_TYPE_BYTE, b64, length, sizeof(guchar));
				g_free(b64);
				return retval;
			}
		}
		default:
			g_assert_not_reached();
		}
	}

	if (JSON_NODE_TYPE(node) == JSON_NODE_ARRAY) {
		JsonArray * array = json_node_get_array(node);
		GVariantBuilder builder;

		if (g_strcmp0(name, "icon-data") == 0) {
			g_variant_builder_init(&builder, G_VARIANT_TYPE("ay"));
			json_array_foreach_element(array, array_byte_foreach, &builder);
		} else {
			g_variant_builder_init(&builder, G_VARIANT_TYPE_ARRAY);
			json_array_foreach_element(array, array_foreach, &builder);
		}


		return g_variant_builder_end(&builder);
	}

	if (JSON_NODE_TYPE(node) == JSON_NODE_OBJECT) {
		GVariantBuilder builder;
		g_variant_builder_init(&builder, G_VARIANT_TYPE_DICTIONARY);

		JsonObject * array = json_node_get_object(node);
		json_object_foreach_member(array, object_foreach, &builder);

		return g_variant_builder_end(&builder);
	}

	return NULL;
}

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
		GVariant * variant = node2variant(lnode, member);

		if (variant != NULL) {
			dbusmenu_menuitem_property_set_variant(mi, member, variant);
		}
	}

	return;
}

DbusmenuMenuitem *
dbusmenu_json_build_from_node (const JsonNode * cnode)
{
	JsonNode * node = (JsonNode *)cnode; /* To match the jsonglib API :( */

	if (node == NULL) return NULL;
	if (JSON_NODE_TYPE(node) != JSON_NODE_OBJECT) return NULL;

	JsonObject * layout = json_node_get_object(node);

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
			DbusmenuMenuitem * child = dbusmenu_json_build_from_node(json_array_get_element(array, count));
			if (child != NULL) {
				dbusmenu_menuitem_child_append(local, child);
			}
		}
	}

	/* g_debug("Layout to menu return: 0x%X", (unsigned int)local); */
	return local;
}

DbusmenuMenuitem *
dbusmenu_json_build_from_file (const gchar * filename)
{
	JsonParser * parser = json_parser_new();

	GError * error = NULL;
	if (!json_parser_load_from_file(parser, filename, &error)) {
		g_warning("Failed parsing file %s because: %s", filename, error->message);
		g_error_free(error);
		return NULL;
	}

	JsonNode * root_node = json_parser_get_root(parser);
	if (JSON_NODE_TYPE(root_node) != JSON_NODE_OBJECT) {
		g_warning("Root node is not an object, fail.  It's an: %s", json_node_type_name(root_node));
		return NULL;
	}

	DbusmenuMenuitem * mi = dbusmenu_json_build_from_node(root_node);

	g_object_unref(parser);

	return mi;
}
