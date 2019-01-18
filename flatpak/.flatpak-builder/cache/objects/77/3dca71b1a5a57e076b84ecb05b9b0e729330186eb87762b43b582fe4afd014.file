/*
 *  Copyright 2011-2016 Bastien Nocera
 *  Copyright 2016 Collabora Ltd.
 *
 * The geocode-glib library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * The geocode-glib library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with the Gnome Library; see the file COPYING.LIB.  If not,
 * write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301  USA.
 *
 * Authors: Bastien Nocera <hadess@hadess.net>
 *          Aleksander Morgado <aleksander.morgado@collabora.co.uk>
 *          Philip Withnall <philip.withnall@collabora.co.uk>
 */

#include <gio/gio.h>
#include <json-glib/json-glib.h>
#include <libsoup/soup.h>
#include <stdlib.h>
#include <string.h>

#include "geocode-glib-private.h"
#include "geocode-glib.h"
#include "geocode-nominatim.h"

/**
 * SECTION:geocode-nominatim
 * @short_description: Geocoding resolver using a Nominatim web service
 * @include: geocode-glib/geocode-glib.h
 *
 * Contains functions for geocoding using the
 * [OSM Nominatim APIs](http://wiki.openstreetmap.org/wiki/Nominatim) exposed
 * by a Nominatim server at a given URI. By default, the GNOME Nominatim server
 * is used, but other server details may be given when constructing a
 * #GeocodeNominatim.
 *
 * Since: 3.23.1
 */

typedef enum {
	PROP_BASE_URL = 1,
	PROP_MAINTAINER_EMAIL_ADDRESS,
	PROP_USER_AGENT,
} GeocodeNominatimProperty;

static GParamSpec *properties[PROP_USER_AGENT + 1];

typedef struct {
	char *base_url;
	char *maintainer_email_address;
	char *user_agent;
} GeocodeNominatimPrivate;

static void geocode_backend_iface_init (GeocodeBackendInterface *iface);

G_DEFINE_TYPE_WITH_CODE (GeocodeNominatim, geocode_nominatim, G_TYPE_OBJECT,
                         G_ADD_PRIVATE (GeocodeNominatim)
                         G_IMPLEMENT_INTERFACE (GEOCODE_TYPE_BACKEND,
                                                geocode_backend_iface_init))

/******************************************************************************/

static void _geocode_read_nominatim_attributes (JsonReader *reader,
                                                GHashTable *ht);

static struct {
	const char *tp_attr;
	const char *gc_attr; /* NULL to ignore */
} attrs_map[] = {
	/* See http://xmpp.org/extensions/xep-0080.html: */
	{ "countrycode", NULL },
	{ "country", "country" },
	{ "region", "state" },
	{ "county", "county" },
	{ "locality", "city" },
	{ "area", NULL },
	{ "postalcode", "postalcode" },
	{ "street", "street" },
	{ "building", NULL },
	{ "floor", NULL },
	{ "room",  NULL },
	{ "text", NULL },
	{ "description", NULL },
	{ "uri", NULL },
	{ "language", "accept-language" },

	/* Custom keys which are passed through: */
	{ "location", "location" },
	{ "limit", "limit" },
};

static const char *
tp_attr_to_gc_attr (const char *attr,
		    gboolean   *found)
{
	guint i;

	*found = FALSE;

	for (i = 0; i < G_N_ELEMENTS (attrs_map); i++) {
		if (g_str_equal (attr, attrs_map[i].tp_attr)){
			*found = TRUE;
			return attrs_map[i].gc_attr;
		}
	}

	return NULL;
}

static GHashTable *
geocode_forward_fill_params (GHashTable *params)
{
	GHashTable *params_out = NULL;
	GHashTableIter iter;
	GValue *value;
	const char *key;

	params_out = g_hash_table_new_full (g_str_hash, g_str_equal,
	                                    g_free, g_free);

	g_hash_table_iter_init (&iter, params);
	while (g_hash_table_iter_next (&iter, (gpointer *) &key, (gpointer *) &value)) {
		gboolean found;
		const char *gc_attr;
		char *str = NULL;
		GValue string_value = G_VALUE_INIT;

		gc_attr = tp_attr_to_gc_attr (key, &found);
		if (found == FALSE) {
			g_warning ("XEP attribute '%s' unhandled", key);
			continue;
		}
		if (gc_attr == NULL)
			continue;

		g_value_init (&string_value, G_TYPE_STRING);
		g_assert (g_value_transform (value, &string_value));
		str = g_value_dup_string (&string_value);
		g_value_unset (&string_value);

		if (str == NULL)
			continue;

		g_return_val_if_fail (g_utf8_validate (str, -1, NULL), NULL);

		g_hash_table_insert (params_out,
		                     g_strdup (gc_attr),
		                     str);
	}

	return params_out;
}

static gchar *
get_search_uri_for_params (GeocodeNominatim  *self,
                           GHashTable        *params,
                           GError           **error)
{
	GeocodeNominatimPrivate *priv;
	GHashTable *ht;
	char *lang;
	char *encoded_params;
	char *uri;
        guint8 i;
        gboolean query_possible = FALSE;
        char *location;
        const char *allowed_attributes[] = { "country",
                                             "region",
                                             "county",
                                             "locality",
                                             "postalcode",
                                             "street",
                                             "location",
                                             NULL };

	priv = geocode_nominatim_get_instance_private (self);

        /* Make sure we have at least one parameter that Nominatim allows querying for */
	for (i = 0; allowed_attributes[i] != NULL; i++) {
	        if (g_hash_table_lookup (params, allowed_attributes[i]) != NULL) {
			query_possible = TRUE;
			break;
		}
	}

        if (!query_possible) {
                char *str;

                str = g_strjoinv (", ", (char **) allowed_attributes);
                g_set_error (error, GEOCODE_ERROR, GEOCODE_ERROR_INVALID_ARGUMENTS,
                             "Only following parameters supported: %s", str);
                g_free (str);

		return NULL;
	}

	/* Prepare the query parameters */
	ht = _geocode_glib_dup_hash_table (params);
	g_hash_table_insert (ht, (gpointer) "format", (gpointer) "jsonv2");
	g_hash_table_insert (ht, (gpointer) "email", (gpointer) priv->maintainer_email_address);
	g_hash_table_insert (ht, (gpointer) "addressdetails", (gpointer) "1");

	lang = NULL;
	if (g_hash_table_lookup (ht, "accept-language") == NULL) {
		lang = _geocode_object_get_lang ();
		if (lang)
			g_hash_table_insert (ht, (gpointer) "accept-language", lang);
	}

        location = g_strdup (g_hash_table_lookup (ht, "location"));
        g_hash_table_remove (ht, "location");

	if (location == NULL)
		g_hash_table_insert (ht, (gpointer) "limit", (gpointer) "1");
	else if (!g_hash_table_contains (ht, "limit"))
		g_hash_table_insert (ht, (gpointer) "limit",
		                     (gpointer) G_STRINGIFY (DEFAULT_ANSWER_COUNT));

	if (location == NULL)
		g_hash_table_remove (ht, "bounded");
	else if (!g_hash_table_contains (ht, "bounded"))
		g_hash_table_insert (ht, (gpointer) "bounded", (gpointer) "0");

	if (location != NULL)
		g_hash_table_insert (ht, (gpointer) "q", location);

	encoded_params = soup_form_encode_hash (ht);
	g_hash_table_unref (ht);
	g_free (lang);
	g_free (location);

	uri = g_strdup_printf ("%s/search?%s", priv->base_url, encoded_params);
	g_free (encoded_params);

	return uri;
}

static struct {
	const char *nominatim_attr;
        const char *place_prop; /* NULL to ignore */
} nominatim_to_place_map[] = {
        { "license", NULL },
        { "osm_id", "osm-id" },
        { "lat", NULL },
        { "lon", NULL },
        { "display_name", NULL },
        { "house_number", "building" },
        { "road", "street" },
        { "suburb", "area" },
        { "city",  "town" },
        { "village",  "town" },
        { "county", "county" },
        { "state_district", "administrative-area" },
        { "state", "state" },
        { "postcode", "postal-code" },
        { "country", "country" },
        { "country_code", "country-code" },
        { "continent", "continent" },
        { "address", NULL },
};

static void
fill_place_from_entry (const char   *key,
                       const char   *value,
                       GeocodePlace *place)
{
        guint i;

        for (i = 0; i < G_N_ELEMENTS (nominatim_to_place_map); i++) {
                if (g_str_equal (key, nominatim_to_place_map[i].nominatim_attr)){
                        g_object_set (G_OBJECT (place),
                                      nominatim_to_place_map[i].place_prop,
                                      value,
                                      NULL);
                        break;
                }
        }

        if (g_str_equal (key, "osm_type")) {
                gpointer ref = g_type_class_ref (geocode_place_osm_type_get_type ());
                GEnumClass *class = G_ENUM_CLASS (ref);
                GEnumValue *evalue = g_enum_get_value_by_nick (class, value);

                if (evalue)
                        g_object_set (G_OBJECT (place), "osm-type", evalue->value, NULL);
                else
                        g_warning ("Unsupported osm-type %s", value);

                g_type_class_unref (ref);
        }
}

static gboolean
node_free_func (GNode    *node,
		gpointer  user_data)
{
	/* Leaf nodes are GeocodeLocation objects
	 * which we reuse for the results */
	if (G_NODE_IS_LEAF (node) == FALSE)
		g_free (node->data);

	return FALSE;
}

static const char *place_attributes[] = {
	"country",
	"state",
	"county",
	"state_district",
	"postcode",
	"city",
	"suburb",
	"village",
};

static GeocodePlaceType
get_place_type_from_attributes (GHashTable *ht)
{
        char *category, *type;
        GeocodePlaceType place_type = GEOCODE_PLACE_TYPE_UNKNOWN;

        category = g_hash_table_lookup (ht, "category");
        type = g_hash_table_lookup (ht, "type");

        if (g_strcmp0 (category, "place") == 0) {
                if (g_strcmp0 (type, "house") == 0 ||
                    g_strcmp0 (type, "building") == 0 ||
                    g_strcmp0 (type, "residential") == 0 ||
                    g_strcmp0 (type, "plaza") == 0 ||
                    g_strcmp0 (type, "office") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_BUILDING;
                else if (g_strcmp0 (type, "estate") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_ESTATE;
                else if (g_strcmp0 (type, "town") == 0 ||
                         g_strcmp0 (type, "city") == 0 ||
                         g_strcmp0 (type, "hamlet") == 0 ||
                         g_strcmp0 (type, "isolated_dwelling") == 0 ||
                         g_strcmp0 (type, "village") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_TOWN;
                else if (g_strcmp0 (type, "suburb") == 0 ||
                         g_strcmp0 (type, "neighbourhood") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_SUBURB;
                else if (g_strcmp0 (type, "state") == 0 ||
                         g_strcmp0 (type, "region") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_STATE;
                else if (g_strcmp0 (type, "farm") == 0 ||
                         g_strcmp0 (type, "forest") == 0 ||
                         g_strcmp0 (type, "valey") == 0 ||
                         g_strcmp0 (type, "park") == 0 ||
                         g_strcmp0 (type, "hill") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_LAND_FEATURE;
                else if (g_strcmp0 (type, "island") == 0 ||
                         g_strcmp0 (type, "islet") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_ISLAND;
                else if (g_strcmp0 (type, "country") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_COUNTRY;
                else if (g_strcmp0 (type, "continent") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_CONTINENT;
                else if (g_strcmp0 (type, "lake") == 0 ||
                         g_strcmp0 (type, "bay") == 0 ||
                         g_strcmp0 (type, "river") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_DRAINAGE;
                else if (g_strcmp0 (type, "sea") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_SEA;
                else if (g_strcmp0 (type, "ocean") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_OCEAN;
        } else if (g_strcmp0 (category, "highway") == 0) {
                if (g_strcmp0 (type, "motorway") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_MOTORWAY;
                else if (g_strcmp0 (type, "bus_stop") == 0)
                        place_type =  GEOCODE_PLACE_TYPE_BUS_STOP;
                else
                        place_type =  GEOCODE_PLACE_TYPE_STREET;
        } else if (g_strcmp0 (category, "railway") == 0) {
                if (g_strcmp0 (type, "station") == 0 ||
                    g_strcmp0 (type, "halt") == 0)
                        place_type = GEOCODE_PLACE_TYPE_RAILWAY_STATION;
                else if (g_strcmp0 (type, "tram_stop") == 0)
                        place_type = GEOCODE_PLACE_TYPE_LIGHT_RAIL_STATION;
        } else if (g_strcmp0 (category, "waterway") == 0) {
                place_type =  GEOCODE_PLACE_TYPE_DRAINAGE;
        } else if (g_strcmp0 (category, "boundary") == 0) {
                if (g_strcmp0 (type, "administrative") == 0) {
                        int rank;

                        rank = atoi (g_hash_table_lookup (ht, "place_rank"));
                        if (rank < 2)
                                place_type =  GEOCODE_PLACE_TYPE_UNKNOWN;

                        if (rank == 28)
                                place_type =  GEOCODE_PLACE_TYPE_BUILDING;
                        else if (rank == 16)
                                place_type =  GEOCODE_PLACE_TYPE_TOWN;
                        else if (rank == 12)
                                place_type =  GEOCODE_PLACE_TYPE_COUNTY;
                        else if (rank == 10 || rank == 8)
                                place_type =  GEOCODE_PLACE_TYPE_STATE;
                        else if (rank == 4)
                                place_type =  GEOCODE_PLACE_TYPE_COUNTRY;
                }
        } else if (g_strcmp0 (category, "amenity") == 0) {
                if (g_strcmp0 (type, "school") == 0)
                        place_type = GEOCODE_PLACE_TYPE_SCHOOL;
                else if (g_strcmp0 (type, "place_of_worship") == 0)
                        place_type = GEOCODE_PLACE_TYPE_PLACE_OF_WORSHIP;
                else if (g_strcmp0 (type, "restaurant") == 0)
                        place_type = GEOCODE_PLACE_TYPE_RESTAURANT;
                else if (g_strcmp0 (type, "bar") == 0 ||
                         g_strcmp0 (type, "pub") == 0)
                        place_type = GEOCODE_PLACE_TYPE_BAR;
        } else if (g_strcmp0 (category, "aeroway") == 0) {
                if (g_strcmp0 (type, "aerodrome") == 0)
                        place_type = GEOCODE_PLACE_TYPE_AIRPORT;
        }

        return place_type;
}

static GeocodePlace *
_geocode_create_place_from_attributes (GHashTable *ht)
{
        GeocodePlace *place;
        GeocodeLocation *loc = NULL;
        const char *name, *street, *building, *bbox_corner;
        GeocodePlaceType place_type;
        gdouble longitude, latitude;

        place_type = get_place_type_from_attributes (ht);

        name = g_hash_table_lookup (ht, "name");
        if (name == NULL)
                name = g_hash_table_lookup (ht, "display_name");

        place = geocode_place_new (name, place_type);

        /* If one corner exists, then all exists */
        bbox_corner = g_hash_table_lookup (ht, "boundingbox-top");
        if (bbox_corner != NULL) {
            GeocodeBoundingBox *bbox;
            gdouble top, bottom, left, right;

            top = g_ascii_strtod (bbox_corner, NULL);

            bbox_corner = g_hash_table_lookup (ht, "boundingbox-bottom");
            bottom = g_ascii_strtod (bbox_corner, NULL);

            bbox_corner = g_hash_table_lookup (ht, "boundingbox-left");
            left = g_ascii_strtod (bbox_corner, NULL);

            bbox_corner = g_hash_table_lookup (ht, "boundingbox-right");
            right = g_ascii_strtod (bbox_corner, NULL);

            bbox = geocode_bounding_box_new (top, bottom, left, right);
            geocode_place_set_bounding_box (place, bbox);
            g_object_unref (bbox);
        }

        /* Nominatim doesn't give us street addresses as such */
        street = g_hash_table_lookup (ht, "road");
        building = g_hash_table_lookup (ht, "house_number");
        if (street != NULL && building != NULL) {
            char *address;
            gboolean number_after;

            number_after = _geocode_object_is_number_after_street ();
            address = g_strdup_printf ("%s %s",
                                       number_after ? street : building,
                                       number_after ? building : street);
            geocode_place_set_street_address (place, address);
            g_free (address);
        }

        g_hash_table_foreach (ht, (GHFunc) fill_place_from_entry, place);

        /* Get latitude and longitude and create GeocodeLocation object. */
        longitude = g_ascii_strtod (g_hash_table_lookup (ht, "lon"), NULL);
        latitude = g_ascii_strtod (g_hash_table_lookup (ht, "lat"), NULL);
        name = geocode_place_get_name (place);

        loc = geocode_location_new_with_description (latitude,
                                                     longitude,
                                                     GEOCODE_LOCATION_ACCURACY_UNKNOWN,
                                                     name);
        geocode_place_set_location (place, loc);
        g_object_unref (loc);

        return place;
}

static void
insert_place_into_tree (GNode *place_tree, GHashTable *ht)
{
	GNode *start = place_tree;
        GeocodePlace *place = NULL;
	char *attr_val = NULL;
	guint i;

	for (i = 0; i < G_N_ELEMENTS (place_attributes); i++) {
		GNode *child = NULL;

		attr_val = g_hash_table_lookup (ht, place_attributes[i]);
		if (!attr_val) {
			/* Add a dummy node if the attribute value is not
			 * available for the place */
			child = g_node_insert_data (start, -1, NULL);
		} else {
			/* If the attr value (eg for country United States)
			 * already exists, then keep on adding other attributes under that node. */
			child = g_node_first_child (start);
			while (child &&
			       child->data &&
			       g_ascii_strcasecmp (child->data, attr_val) != 0) {
				child = g_node_next_sibling (child);
			}
			if (!child) {
				/* create a new node */
				child = g_node_insert_data (start, -1, g_strdup (attr_val));
			}
		}
		start = child;
	}

        place = _geocode_create_place_from_attributes (ht);

        /* The leaf node of the tree is the GeocodePlace object, containing
         * associated GeocodePlace object */
	g_node_insert_data (start, -1, place);
}

static void
make_place_list_from_tree (GNode  *node,
                           char  **s_array,
                           GList **place_list,
                           int     i)
{
	GNode *child;

	if (node == NULL)
		return;

	if (G_NODE_IS_LEAF (node)) {
		GPtrArray *rev_s_array;
		GeocodePlace *place;
		GeocodeLocation *loc;
		char *name;
		int counter = 0;

		rev_s_array = g_ptr_array_new ();

		/* If leaf node, then add all the attributes in the s_array
		 * and set it to the description of the loc object */
		place = (GeocodePlace *) node->data;
		name = (char *) geocode_place_get_name (place);
		loc = geocode_place_get_location (place);

		/* To print the attributes in a meaningful manner
		 * reverse the s_array */
		g_ptr_array_add (rev_s_array, (gpointer) name);
		for (counter = 1; counter <= i; counter++)
			g_ptr_array_add (rev_s_array, s_array[i - counter]);
		g_ptr_array_add (rev_s_array, NULL);
		name = g_strjoinv (", ", (char **) rev_s_array->pdata);
		g_ptr_array_unref (rev_s_array);

		geocode_place_set_name (place, name);
		geocode_location_set_description (loc, name);
		g_free (name);

		*place_list = g_list_prepend (*place_list, place);
	} else {
                GNode *prev, *next;

                prev = g_node_prev_sibling (node);
                next = g_node_next_sibling (node);

		/* If there are other attributes with a different value,
		 * add those attributes to the string to differentiate them */
		if (node->data && ((prev && prev->data) || (next && next->data))) {
                        s_array[i] = node->data;
                        i++;
		}
	}

	for (child = node->children; child != NULL; child = child->next)
		make_place_list_from_tree (child, s_array, place_list, i);
}

GList *
_geocode_parse_search_json (const char *contents,
			     GError    **error)
{
	GList *ret;
	JsonParser *parser;
	JsonNode *root;
	JsonReader *reader;
	const GError *err = NULL;
	int num_places, i;
	GNode *place_tree;
	char *s_array[G_N_ELEMENTS (place_attributes)];

	g_debug ("%s: contents = %s", G_STRFUNC, contents);

	ret = NULL;

	parser = json_parser_new ();
	if (json_parser_load_from_data (parser, contents, -1, error) == FALSE) {
		g_object_unref (parser);
		return ret;
	}

	root = json_parser_get_root (parser);
	reader = json_reader_new (root);

	num_places = json_reader_count_elements (reader);
	if (num_places < 0)
		goto parse;
        if (num_places == 0) {
	        g_set_error_literal (error,
                                     GEOCODE_ERROR,
                                     GEOCODE_ERROR_NO_MATCHES,
                                     "No matches found for request");
		goto no_results;
        }

	place_tree = g_node_new (NULL);

	for (i = 0; i < num_places; i++) {
		GHashTable *ht;

		json_reader_read_element (reader, i);

                ht = g_hash_table_new_full (g_str_hash, g_str_equal,
				            g_free, g_free);
                _geocode_read_nominatim_attributes (reader, ht);

		/* Populate the tree with place details */
		insert_place_into_tree (place_tree, ht);

		g_hash_table_unref (ht);

		json_reader_end_element (reader);
	}

	make_place_list_from_tree (place_tree, s_array, &ret, 0);

	g_node_traverse (place_tree,
			 G_IN_ORDER,
			 G_TRAVERSE_ALL,
			 -1,
			 (GNodeTraverseFunc) node_free_func,
			 NULL);

	g_node_destroy (place_tree);

	g_object_unref (parser);
	g_object_unref (reader);
	ret = g_list_reverse (ret);

	return ret;
parse:
	err = json_reader_get_error (reader);
	g_set_error_literal (error, GEOCODE_ERROR, GEOCODE_ERROR_PARSE, err->message);
no_results:
	g_object_unref (parser);
	g_object_unref (reader);
	return NULL;
}

static GList *
geocode_nominatim_forward_search (GeocodeBackend  *backend,
                                  GHashTable      *params,
                                  GCancellable    *cancellable,
                                  GError         **error)
{
	GeocodeNominatim *self = GEOCODE_NOMINATIM (backend);
	char *contents;
	GHashTable *transformed_params = NULL;  /* (utf8, utf8) */
	GList *result = NULL;  /* (element-type GeocodePlace) */
	gchar *uri = NULL;

	transformed_params = geocode_forward_fill_params (params);
	uri = get_search_uri_for_params (self, transformed_params, error);
	g_hash_table_unref (transformed_params);

	if (uri == NULL)
		return NULL;

	contents = GEOCODE_NOMINATIM_GET_CLASS (self)->query (self,
	                                                      uri,
	                                                      cancellable,
	                                                      error);
	if (contents != NULL) {
		result = _geocode_parse_search_json (contents, error);
		g_free (contents);
	}

	g_free (uri);

	return result;
}

static void
on_forward_query_ready (GeocodeNominatim *self,
                        GAsyncResult     *res,
                        GTask            *task)
{
	GError *error = NULL;
	char *contents;
	GList *places;  /* (element-type GeocodePlace) */

	contents = GEOCODE_NOMINATIM_GET_CLASS (self)->query_finish (GEOCODE_NOMINATIM (self), res, &error);
	if (contents == NULL) {
		g_task_return_error (task, error);
		g_object_unref (task);
		return;
	}

	places = _geocode_parse_search_json (contents, &error);
	g_free (contents);

	if (places == NULL) {
		g_task_return_error (task, error);
		g_object_unref (task);
		return;
	}

	g_task_return_pointer (task, places, (GDestroyNotify) g_list_free);
	g_object_unref (task);
}

static void
geocode_nominatim_forward_search_async (GeocodeBackend      *backend,
                                        GHashTable          *params,
                                        GCancellable        *cancellable,
                                        GAsyncReadyCallback  callback,
                                        gpointer             user_data)
{
	GeocodeNominatim *self = GEOCODE_NOMINATIM (backend);
	GTask *task;
	GHashTable *transformed_params = NULL;  /* (utf8, utf8) */
	gchar *uri = NULL;
	GError *error = NULL;

	transformed_params = geocode_forward_fill_params (params);
	uri = get_search_uri_for_params (self, transformed_params, &error);
	g_hash_table_unref (transformed_params);

	if (error != NULL) {
		g_task_report_error (self, callback, user_data, NULL, error);
		return;
	}

	task = g_task_new (self, cancellable, callback, user_data);
	GEOCODE_NOMINATIM_GET_CLASS (self)->query_async (self,
	                                                 uri,
	                                                 cancellable,
	                                                 (GAsyncReadyCallback) on_forward_query_ready,
	                                                 g_object_ref (task));
	g_object_unref (task);
	g_free (uri);
}

static GList *
geocode_nominatim_forward_search_finish (GeocodeBackend  *backend,
                                         GAsyncResult    *res,
                                         GError         **error)
{
	return g_task_propagate_pointer (G_TASK (res), error);
}

/******************************************************************************/

static void
copy_item (char       *key,
           char       *value,
           GHashTable *ret)
{
	g_hash_table_insert (ret, key, value);
}

GHashTable *
_geocode_glib_dup_hash_table (GHashTable *ht)
{
	GHashTable *ret;

	ret = g_hash_table_new (g_str_hash, g_str_equal);
	g_hash_table_foreach (ht, (GHFunc) copy_item, ret);

	return ret;
}

static gchar *
get_resolve_uri_for_params (GeocodeNominatim  *self,
                            GHashTable        *orig_ht,
                            GError           **error)
{
	GHashTable *ht;
	char *locale;
	char *params, *uri;
	GeocodeNominatimPrivate *priv;
	const GValue *lat, *lon;
	char lat_str[G_ASCII_DTOSTR_BUF_SIZE];
	char lon_str[G_ASCII_DTOSTR_BUF_SIZE];

	priv = geocode_nominatim_get_instance_private (self);

	/* Make sure we have both lat and lon. */
	lat = g_hash_table_lookup (orig_ht, "lat");
	lon = g_hash_table_lookup (orig_ht, "lon");

	if (lat == NULL || lon == NULL) {
		g_set_error_literal (error, GEOCODE_ERROR, GEOCODE_ERROR_INVALID_ARGUMENTS,
		                     "Only following parameters supported: lat, lon");

		return NULL;
	}

	ht = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, NULL);

	g_ascii_dtostr (lat_str, G_ASCII_DTOSTR_BUF_SIZE,
	                g_value_get_double (lat));
	g_ascii_dtostr (lon_str, G_ASCII_DTOSTR_BUF_SIZE,
	                g_value_get_double (lon));

	g_hash_table_insert (ht, (gpointer) "lat", lat_str);
	g_hash_table_insert (ht, (gpointer) "lon", lon_str);

	g_hash_table_insert (ht, (gpointer) "format", (gpointer) "json");
	g_hash_table_insert (ht, (gpointer) "email",
	                     (gpointer) priv->maintainer_email_address);
	g_hash_table_insert (ht, (gpointer) "addressdetails", (gpointer) "1");

	locale = NULL;
	if (g_hash_table_lookup (ht, "accept-language") == NULL) {
		locale = _geocode_object_get_lang ();
		if (locale)
			g_hash_table_insert (ht, (gpointer) "accept-language", locale);
	}

	{
		GHashTableIter iter;
		gpointer key, value;

		g_hash_table_iter_init (&iter, ht);
		while (g_hash_table_iter_next (&iter, &key, &value))
			g_debug ("%s: %s = %s", G_STRFUNC, (const gchar *) key, (const gchar *) value);
	}

	params = soup_form_encode_hash (ht);
	g_hash_table_unref (ht);
	g_free (locale);

	uri = g_strdup_printf ("%s/reverse?%s", priv->base_url, params);
	g_free (params);

	return uri;
}

static gchar *
geocode_nominatim_query_finish (GeocodeNominatim  *self,
                                GAsyncResult      *res,
                                GError           **error)
{
	return g_task_propagate_pointer (G_TASK (res), error);
}

static void
on_query_data_loaded (SoupSession *session,
                      SoupMessage *query,
                      GTask       *task)
{
	char *contents;

	if (query->status_code != SOUP_STATUS_OK)
		g_task_return_new_error (task,
		                         G_IO_ERROR,
		                         G_IO_ERROR_FAILED,
		                         "%s",
		                         query->reason_phrase ? query->reason_phrase : "Query failed");
	else {
		contents = g_strndup (query->response_body->data, query->response_body->length);
		_geocode_glib_cache_save (query, contents);
		g_task_return_pointer (task, contents, g_free);
	}

	g_object_unref (task);
}

static void
on_cache_data_loaded (GFile        *cache,
                      GAsyncResult *res,
                      GTask        *task)
{
	GeocodeNominatim *self;
	GeocodeNominatimPrivate *priv;
	char *contents;
	SoupSession *soup_session;

	self = g_task_get_source_object (task);
	priv = geocode_nominatim_get_instance_private (self);

	if (g_file_load_contents_finish (cache,
	                                 res,
	                                 &contents,
	                                 NULL,
	                                 NULL,
	                                 NULL)) {
		g_task_return_pointer (task, contents, g_free);
		g_object_unref (task);
		return;
	}

	soup_session = _geocode_glib_build_soup_session (priv->user_agent);
	soup_session_queue_message (soup_session,
	                            g_object_ref (g_task_get_task_data (task)),
	                            (SoupSessionCallback) on_query_data_loaded,
	                            task);
	g_object_unref (soup_session);
}

static void
geocode_nominatim_query_async (GeocodeNominatim    *self,
                               const gchar         *uri,
                               GCancellable        *cancellable,
                               GAsyncReadyCallback  callback,
                               gpointer             user_data)
{
	GTask *task;
	SoupSession *soup_session;
	SoupMessage *soup_query;
	char *cache_path;
	GeocodeNominatimPrivate *priv;

	priv = geocode_nominatim_get_instance_private (self);

	g_debug ("%s: uri = %s", G_STRFUNC, uri);

	task = g_task_new (self, cancellable, callback, user_data);

	soup_query = soup_message_new (SOUP_METHOD_GET, uri);
	g_task_set_task_data (task, soup_query, g_object_unref);

	cache_path = _geocode_glib_cache_path_for_query (soup_query);
	if (cache_path != NULL) {
		GFile *cache;

		cache = g_file_new_for_path (cache_path);
		g_file_load_contents_async (cache,
		                            cancellable,
		                            (GAsyncReadyCallback) on_cache_data_loaded,
		                            task);
		g_object_unref (cache);
		g_free (cache_path);
		return;
	}

	soup_session = _geocode_glib_build_soup_session (priv->user_agent);
	soup_session_queue_message (soup_session,
	                            g_object_ref (soup_query),
	                            (SoupSessionCallback) on_query_data_loaded,
	                            task);
	g_object_unref (soup_session);
}

static gchar *
geocode_nominatim_query (GeocodeNominatim  *self,
                         const gchar       *uri,
                         GCancellable      *cancellable,
                         GError           **error)
{
	SoupSession *soup_session;
	SoupMessage *soup_query;
	char *contents;
	GeocodeNominatimPrivate *priv;

	priv = geocode_nominatim_get_instance_private (self);

	g_debug ("%s: uri = %s", G_STRFUNC, uri);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return NULL;

	soup_session = _geocode_glib_build_soup_session (priv->user_agent);
	soup_query = soup_message_new (SOUP_METHOD_GET, uri);

	if (_geocode_glib_cache_load (soup_query, &contents) == FALSE) {
		if (soup_session_send_message (soup_session, soup_query) != SOUP_STATUS_OK) {
			g_set_error_literal (error, G_IO_ERROR, G_IO_ERROR_FAILED,
			                     soup_query->reason_phrase ? soup_query->reason_phrase : "Query failed");
			contents = NULL;
		} else {
			contents = g_strndup (soup_query->response_body->data, soup_query->response_body->length);
			_geocode_glib_cache_save (soup_query, contents);
		}
	}

	g_object_unref (soup_query);
	g_object_unref (soup_session);

	return contents;
}

/******************************************************************************/

static GList *
geocode_nominatim_reverse_resolve_finish (GeocodeBackend  *backend,
                                          GAsyncResult    *res,
                                          GError         **error)
{
	return g_task_propagate_pointer (G_TASK (res), error);
}

static void
insert_bounding_box_element (GHashTable *ht,
                             GType       value_type,
                             const char *name,
                             JsonReader *reader)
{
	if (value_type == G_TYPE_STRING) {
		const char *bbox_val;

		bbox_val = json_reader_get_string_value (reader);
		g_hash_table_insert (ht, g_strdup (name), g_strdup (bbox_val));
	} else if (value_type == G_TYPE_DOUBLE) {
		gdouble bbox_val;

		bbox_val = json_reader_get_double_value (reader);
		g_hash_table_insert(ht, g_strdup (name), g_strdup_printf ("%lf", bbox_val));
	} else if (value_type == G_TYPE_INT64) {
		gint64 bbox_val;

		bbox_val = json_reader_get_double_value (reader);
		g_hash_table_insert(ht, g_strdup (name), g_strdup_printf ("%"G_GINT64_FORMAT, bbox_val));
	} else {
		g_debug ("Unhandled node type %s for %s", g_type_name (value_type), name);
	}
}

static void
_geocode_read_nominatim_attributes (JsonReader *reader,
                                    GHashTable *ht)
{
	char **members;
	guint i;
	gboolean is_address;
	const char *house_number = NULL;

	is_address = (g_strcmp0 (json_reader_get_member_name (reader), "address") == 0);

	members = json_reader_list_members (reader);
	if (members == NULL) {
		json_reader_end_member (reader);
		return;
	}

	for (i = 0; members[i] != NULL; i++) {
		const char *value = NULL;

		json_reader_read_member (reader, members[i]);

		if (json_reader_is_value (reader)) {
			JsonNode *node = json_reader_get_value (reader);
			if (json_node_get_value_type (node) == G_TYPE_STRING) {
				value = json_node_get_string (node);
				if (value && *value == '\0')
					value = NULL;
			}
		}

		if (value != NULL) {
			g_hash_table_insert (ht, g_strdup (members[i]), g_strdup (value));

			if (i == 0 && is_address) {
				if (g_strcmp0 (members[i], "house_number") != 0)
					/* Since Nominatim doesn't give us a short name,
					 * we use the first component of address as name.
					 */
					g_hash_table_insert (ht, g_strdup ("name"), g_strdup (value));
				else
					house_number = value;
			} else if (house_number != NULL && g_strcmp0 (members[i], "road") == 0) {
				gboolean number_after;
				char *name;

				number_after = _geocode_object_is_number_after_street ();
				name = g_strdup_printf ("%s %s",
				                        number_after ? value : house_number,
				                        number_after ? house_number : value);
				g_hash_table_insert (ht, g_strdup ("name"), name);
			}
		} else if (g_strcmp0 (members[i], "boundingbox") == 0) {
			JsonNode *node;
			GType value_type;

			json_reader_read_element (reader, 0);
			node = json_reader_get_value (reader);
			value_type = json_node_get_value_type (node);

			insert_bounding_box_element (ht, value_type, "boundingbox-bottom", reader);
			json_reader_end_element (reader);

			json_reader_read_element (reader, 1);
			insert_bounding_box_element (ht, value_type, "boundingbox-top", reader);
			json_reader_end_element (reader);

			json_reader_read_element (reader, 2);
			insert_bounding_box_element (ht, value_type, "boundingbox-left", reader);
			json_reader_end_element (reader);

			json_reader_read_element (reader, 3);
			insert_bounding_box_element (ht, value_type, "boundingbox-right", reader);
			json_reader_end_element (reader);
		}
		json_reader_end_member (reader);
	}

	g_strfreev (members);

	if (json_reader_read_member (reader, "address"))
		_geocode_read_nominatim_attributes (reader, ht);
	json_reader_end_member (reader);
}

static GHashTable *
resolve_json (const char  *contents,
              GError     **error)
{
	GHashTable *ret = NULL;
	JsonParser *parser;
	JsonNode *root;
	JsonReader *reader;

	g_debug ("%s: contents = %s", G_STRFUNC, contents);

	parser = json_parser_new ();
	if (json_parser_load_from_data (parser, contents, -1, error) == FALSE) {
		g_object_unref (parser);
		return ret;
	}

	root = json_parser_get_root (parser);
	reader = json_reader_new (root);

	if (json_reader_read_member (reader, "error")) {
		const char *msg;

		msg = json_reader_get_string_value (reader);
		json_reader_end_member (reader);
		if (msg && *msg == '\0')
			msg = NULL;

		g_set_error_literal (error,
		                     GEOCODE_ERROR,
		                     GEOCODE_ERROR_NOT_SUPPORTED,
		                     msg ? msg : "Query not supported");
		g_object_unref (parser);
		g_object_unref (reader);
		return NULL;
	}

	ret = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);
	_geocode_read_nominatim_attributes (reader, ret);

	g_object_unref (parser);
	g_object_unref (reader);

	return ret;
}

static void
places_list_free (GList *places)
{
	g_list_free_full (places, g_object_unref);
}

static void
on_reverse_query_ready (GeocodeNominatim *self,
                        GAsyncResult     *res,
                        GTask            *task)
{
	GError *error = NULL;
	char *contents;
	g_autoptr (GeocodePlace) place = NULL;
	GHashTable *attributes;

	contents = GEOCODE_NOMINATIM_GET_CLASS (self)->query_finish (GEOCODE_NOMINATIM (self), res, &error);
	if (contents == NULL) {
		g_task_return_error (task, error);
		g_object_unref (task);
		return;
	}

	attributes = resolve_json (contents, &error);
	g_free (contents);

	if (attributes == NULL) {
		g_task_return_error (task, error);
		g_object_unref (task);
		return;
	}

	place = _geocode_create_place_from_attributes (attributes);
	g_hash_table_unref (attributes);

	g_task_return_pointer (task,
	                       g_list_prepend (NULL, g_object_ref (place)),
	                       (GDestroyNotify) places_list_free);
	g_object_unref (task);
}

static void
geocode_nominatim_reverse_resolve_async (GeocodeBackend      *self,
                                         GHashTable          *params,
                                         GCancellable        *cancellable,
                                         GAsyncReadyCallback  callback,
                                         gpointer             user_data)
{
	GTask *task;
	gchar *uri = NULL;
	GError *error = NULL;

	g_return_if_fail (GEOCODE_IS_BACKEND (self));
	g_return_if_fail (params != NULL);

	uri = get_resolve_uri_for_params (GEOCODE_NOMINATIM (self), params,
	                                  &error);

	if (error != NULL) {
		g_task_report_error (self, callback, user_data, NULL, error);
		return;
	}

	task = g_task_new (self, cancellable, callback, user_data);
	GEOCODE_NOMINATIM_GET_CLASS (self)->query_async (GEOCODE_NOMINATIM (self),
	                                                 uri,
	                                                 cancellable,
	                                                 (GAsyncReadyCallback) on_reverse_query_ready,
	                                                 g_object_ref (task));
	g_object_unref (task);
	g_free (uri);
}

static GList *
geocode_nominatim_reverse_resolve (GeocodeBackend  *self,
                                   GHashTable      *params,
                                   GCancellable    *cancellable,
                                   GError         **error)
{
	char *contents;
	GHashTable *result = NULL;
	g_autoptr (GeocodePlace) place = NULL;
	gchar *uri = NULL;

	g_return_val_if_fail (GEOCODE_IS_BACKEND (self), NULL);
	g_return_val_if_fail (params != NULL, NULL);

	uri = get_resolve_uri_for_params (GEOCODE_NOMINATIM (self), params,
	                                  error);

	if (uri == NULL)
		return NULL;

	contents = GEOCODE_NOMINATIM_GET_CLASS (self)->query (GEOCODE_NOMINATIM (self),
	                                                      uri,
	                                                      cancellable,
	                                                      error);
	if (contents != NULL) {
		result = resolve_json (contents, error);
		g_free (contents);
	}

	g_free (uri);

	if (result == NULL)
		return NULL;

	place = _geocode_create_place_from_attributes (result);
	g_hash_table_unref (result);

	return g_list_prepend (NULL, g_object_ref (place));
}

/******************************************************************************/

G_LOCK_DEFINE_STATIC (backend_nominatim_gnome_lock);
static GWeakRef backend_nominatim_gnome;

/**
 * geocode_nominatim_get_gnome:
 *
 * Gets a reference to the default Nominatim server on nominatim.gnome.org.
 *
 * This function is thread-safe.
 *
 * Returns: (transfer full): a new #GeocodeNominatim. Use g_object_unref() when done.
 *
 * Since: 3.23.1
 */
GeocodeNominatim *
geocode_nominatim_get_gnome (void)
{
	GeocodeNominatim *backend;

	G_LOCK (backend_nominatim_gnome_lock);
	backend = g_weak_ref_get (&backend_nominatim_gnome);
	if (backend == NULL) {
		backend = geocode_nominatim_new ("https://nominatim.gnome.org",
		                                 "zeeshanak@gnome.org");
		g_weak_ref_set (&backend_nominatim_gnome, backend);
	}
	G_UNLOCK (backend_nominatim_gnome_lock);

	return backend;
}

/******************************************************************************/

/**
 * geocode_nominatim_new:
 * @base_url: a the base URL of the Nominatim server.
 * @maintainer_email_address: the email address of the software maintainer.
 *
 * Creates a new backend implementation for an online Nominatim server. See
 * the documentation for #GeocodeNominatim:base-url and
 * #GeocodeNominatim:maintainer-email-address.
 *
 * Returns: (transfer full): a new #GeocodeNominatim. Use g_object_unref() when done.
 *
 * Since: 3.23.1
 */
GeocodeNominatim *
geocode_nominatim_new (const char *base_url,
                       const char *maintainer_email_address)
{
	g_return_val_if_fail (base_url != NULL, NULL);
	g_return_val_if_fail (maintainer_email_address != NULL, NULL);

	return GEOCODE_NOMINATIM (g_object_new (GEOCODE_TYPE_NOMINATIM,
	                                        "base-url", base_url,
	                                        "maintainer-email-address", maintainer_email_address,
	                                        NULL));
}

static void
geocode_nominatim_init (GeocodeNominatim *object)
{
}

static void
geocode_nominatim_constructed (GObject *object)
{
	GeocodeNominatimPrivate *priv;

	/* Chain up. */
	G_OBJECT_CLASS (geocode_nominatim_parent_class)->constructed (object);

	priv = geocode_nominatim_get_instance_private (GEOCODE_NOMINATIM (object));

	/* Ensure our mandatory construction properties have been passed. */
	g_assert (priv->base_url != NULL);
	g_assert (priv->maintainer_email_address != NULL);
}

static void
geocode_nominatim_get_property (GObject    *object,
                                guint       property_id,
                                GValue     *value,
                                GParamSpec *pspec)
{
	GeocodeNominatimPrivate *priv;

	priv = geocode_nominatim_get_instance_private (GEOCODE_NOMINATIM (object));

	switch ((GeocodeNominatimProperty) property_id) {
	case PROP_BASE_URL:
		g_value_set_string (value, priv->base_url);
		break;
	case PROP_MAINTAINER_EMAIL_ADDRESS:
		g_value_set_string (value, priv->maintainer_email_address);
		break;
	case PROP_USER_AGENT:
		g_value_set_string (value, priv->user_agent);
		break;
	default:
		/* We don't have any other property... */
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
		break;
	}
}

static void
geocode_nominatim_set_property (GObject      *object,
                                guint         property_id,
                                const GValue *value,
                                GParamSpec   *pspec)
{
	GeocodeNominatimPrivate *priv;

	priv = geocode_nominatim_get_instance_private (GEOCODE_NOMINATIM (object));

	switch ((GeocodeNominatimProperty) property_id) {
	case PROP_BASE_URL:
		/* Construct only. */
		g_assert (priv->base_url == NULL);
		priv->base_url = g_value_dup_string (value);
		break;
	case PROP_MAINTAINER_EMAIL_ADDRESS:
		/* Construct only. */
		g_assert (priv->maintainer_email_address == NULL);
		priv->maintainer_email_address = g_value_dup_string (value);
		break;
	case PROP_USER_AGENT:
		if (g_strcmp0 (priv->user_agent, g_value_get_string (value)) != 0) {
			g_free (priv->user_agent);
			priv->user_agent = g_value_dup_string (value);
			g_object_notify_by_pspec (object,
			                          properties[PROP_USER_AGENT]);
		}
		break;
	default:
		/* We don't have any other property... */
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
		break;
	}
}

static void
geocode_nominatim_finalize (GObject *object)
{
	GeocodeNominatimPrivate *priv;

	priv = geocode_nominatim_get_instance_private (GEOCODE_NOMINATIM (object));

	g_free (priv->base_url);
	g_free (priv->maintainer_email_address);
	g_free (priv->user_agent);

	G_OBJECT_CLASS (geocode_nominatim_parent_class)->finalize (object);
}

static void
geocode_backend_iface_init (GeocodeBackendInterface *iface)
{
	iface->forward_search         = geocode_nominatim_forward_search;
	iface->forward_search_async   = geocode_nominatim_forward_search_async;
	iface->forward_search_finish  = geocode_nominatim_forward_search_finish;

	iface->reverse_resolve        = geocode_nominatim_reverse_resolve;
	iface->reverse_resolve_async  = geocode_nominatim_reverse_resolve_async;
	iface->reverse_resolve_finish = geocode_nominatim_reverse_resolve_finish;
}

static void
geocode_nominatim_class_init (GeocodeNominatimClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->constructed  = geocode_nominatim_constructed;
	object_class->finalize     = geocode_nominatim_finalize;
	object_class->get_property = geocode_nominatim_get_property;
	object_class->set_property = geocode_nominatim_set_property;

	klass->query        = geocode_nominatim_query;
	klass->query_async  = geocode_nominatim_query_async;
	klass->query_finish = geocode_nominatim_query_finish;

	/**
	 * GeocodeNominatim:base-url:
	 *
	 * The base URL of the Nominatim service, for example
	 * `https://nominatim.example.org`.
	 *
	 * Since: 3.23.1
	 */
	properties[PROP_BASE_URL] = g_param_spec_string ("base-url",
	                                                 "Base URL",
	                                                 "Base URL of the Nominatim service",
	                                                 NULL,
	                                                 (G_PARAM_READWRITE |
	                                                  G_PARAM_CONSTRUCT_ONLY |
	                                                  G_PARAM_STATIC_STRINGS));

	/**
	 * GeocodeNominatim:maintainer-email-address:
	 *
	 * E-mail address of the maintainer of the software making the
	 * geocoding requests to the  Nominatim server. This is used to contact
	 * them in the event of a problem with their usage. See
	 * [the Nominatim API](http://wiki.openstreetmap.org/wiki/Nominatim).
	 *
	 * Since: 3.23.1
	 */
	properties[PROP_MAINTAINER_EMAIL_ADDRESS] =
	    g_param_spec_string ("maintainer-email-address",
	                         "Maintainer e-mail address",
	                         "E-mail address of the maintainer",
	                         NULL,
	                         (G_PARAM_READWRITE |
	                          G_PARAM_CONSTRUCT_ONLY |
	                          G_PARAM_STATIC_STRINGS));

	/**
	 * GeocodeNominatim:user-agent:
	 *
	 * User-Agent string to send with HTTP(S) requests, or %NULL to use the
	 * default user agent, which is derived from the geocode-glib version
	 * and #GApplication:id, for example: `geocode-glib/3.20 (MyAppId)`.
	 *
	 * As per the
	 * [Nominatim usage policy](http://wiki.openstreetmap.org/wiki/Nominatim_usage_policy),
	 * it should be set to a string which identifies the application which
	 * is using geocode-glib, and must be a valid
	 * [user agent](https://tools.ietf.org/html/rfc7231#section-5.5.3)
	 * string.
	 *
	 * Since: 3.23.1
	 */
	properties[PROP_USER_AGENT] = g_param_spec_string ("user-agent",
	                                                   "User agent",
	                                                   "User-Agent string to send with HTTP(S) requests",
	                                                   NULL,
	                                                   (G_PARAM_READWRITE |
	                                                    G_PARAM_STATIC_STRINGS));

	g_object_class_install_properties (object_class,
	                                   G_N_ELEMENTS (properties), properties);
}
