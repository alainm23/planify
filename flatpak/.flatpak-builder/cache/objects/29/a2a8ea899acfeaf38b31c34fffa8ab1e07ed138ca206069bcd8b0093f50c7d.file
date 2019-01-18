/*
 * Copyright 2011–2015 Red Hat
 * Copyright 2014, 2015, 2016 Jonas Danielsson
 * Copyright 2016 Collabora Ltd.
 *
 * The Gnome Library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * The Gnome Library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with the Gnome Library; see the file COPYING.LIB.  If not,
 * write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301  USA.
 *
 * Authors: Bastien Nocera <hadess@hadess.net>
 *          Zeeshan Ali <zeeshanak@gnome.org>
 *          Jonas Danielsson <jonas.danielsson@threetimestwo.org>
 *          Philip Withnall <philip.withnall@collabora.co.uk>
 */

#include "config.h"
#include <locale.h>
#include <glib/gi18n.h>
#include <glib.h>
#include <stdlib.h>
#include <gio/gio.h>
#include <geocode-glib/geocode-glib.h>
#include <geocode-glib/geocode-glib-private.h>
#include <geocode-glib/tests/geocode-nominatim-test.h>

static GMainLoop *loop = NULL;
static gboolean enable_network = FALSE;
static char **command_line_params = NULL;

static void
print_loc (GeocodeLocation *loc)
{
	g_print ("\t%s @ %lf, %lf\n",
             geocode_location_get_description (loc),
             geocode_location_get_latitude (loc),
             geocode_location_get_longitude (loc));
}

static void
print_place (GeocodePlace *place)
{
	/* For now just print the underlying location */
	GeocodeLocation *loc = geocode_place_get_location (place);

	print_loc (loc);
}

static void
got_geocode_cb (GObject *source_object,
		GAsyncResult *res,
		gpointer user_data)
{
	GeocodeReverse *object = (GeocodeReverse *) source_object;
	GeocodePlace *place;
	GError *error = NULL;

	place = geocode_reverse_resolve_finish (object, res, &error);
	if (place == NULL) {
		g_message ("Failed to get geocode: %s", error->message);
		g_error_free (error);
		exit (1);
	}

	g_print ("Got geocode answer:\n");
	print_place (place);
	g_object_unref (place);
	g_object_unref (object);

	exit (0);
}

static void
got_geocode_search_cb (GObject *source_object,
		       GAsyncResult *res,
		       gpointer user_data)
{
	GeocodeForward *object = (GeocodeForward *) source_object;
	GList *results, *l;
	GError *error = NULL;

	results = geocode_forward_search_finish (object, res, &error);
	if (results == NULL) {
		g_message ("Failed to search geocode: %s", error->message);
		g_error_free (error);
		exit (1);
	}

	for (l = results; l != NULL; l = l->next) {
		GeocodePlace *place = l->data;

		g_print ("Got geocode search answer:\n");
		print_place (place);
		g_object_unref (place);
	}
	g_list_free (results);

	g_object_unref (object);

	exit (0);
}

static gboolean
bbox_includes_location (GeocodeBoundingBox *bbox,
                       GeocodeLocation *loc)
{
	if (geocode_bounding_box_get_left (bbox) > geocode_location_get_longitude (loc))
		return FALSE;

	if (geocode_bounding_box_get_right (bbox) < geocode_location_get_longitude (loc))
		return FALSE;

	if (geocode_bounding_box_get_bottom (bbox) > geocode_location_get_latitude (loc))
		return FALSE;

	if (geocode_bounding_box_get_top (bbox) < geocode_location_get_latitude (loc))
		return FALSE;

	return TRUE;
}

static void
add_attr (GHashTable *ht,
	  const char *key,
	  const char *s)
{
	GValue *value;
	value = g_new0 (GValue, 1);
	g_value_init (value, G_TYPE_STRING);
	g_value_set_static_string (value, s);
	g_hash_table_insert (ht, g_strdup (key), value);
}

static void
free_attr (GValue *attr)
{
	g_value_unset (attr);
	g_free (attr);
}

static void
add_attr_string (GHashTable  *ht,
                 const gchar *key,
                 const gchar *value)
{
	g_hash_table_insert (ht, (gpointer) key, (gpointer) value);
}

static gchar *
load_json (const gchar *expected_response_filename)
{
	g_autofree gchar *expected_response = NULL;
	g_autofree gchar *expected_response_path = NULL;
	g_autoptr (GError) error = NULL;

	expected_response_path = g_test_build_filename (G_TEST_DIST,
	                                                expected_response_filename,
	                                                NULL);
	g_file_get_contents (expected_response_path, &expected_response, NULL,
	                     &error);
	g_assert_no_error (error);

	return g_steal_pointer (&expected_response);
}

static void
set_up_cache (void)
{
	g_autofree gchar *cache_path = NULL;
	g_autoptr (GError) error = NULL;

	cache_path = g_dir_make_tmp ("test-gcglib-XXXXXX", &error);
	g_assert_no_error (error);

	g_setenv ("XDG_CACHE_HOME", cache_path, TRUE);
}

static GeocodeReverse *
create_reverse (GeocodeLocation *loc,
                const gchar     *expected_response_filename)
{
	g_autoptr (GHashTable) parameters = NULL;
	g_autoptr (GeocodeReverse) reverse = NULL;
	char lat[G_ASCII_DTOSTR_BUF_SIZE];
	char lon[G_ASCII_DTOSTR_BUF_SIZE];

	/* Set up the cache to avoid polluting the user’s main cache. */
	set_up_cache ();

	/* Build the query parameters. */
	g_ascii_dtostr (lat,
	                G_ASCII_DTOSTR_BUF_SIZE,
	                geocode_location_get_latitude (loc));
	g_ascii_dtostr (lon,
	                G_ASCII_DTOSTR_BUF_SIZE,
	                geocode_location_get_longitude (loc));

	parameters = g_hash_table_new_full (g_str_hash, g_str_equal, NULL,
	                                    g_free);
	add_attr_string (parameters, "lat", g_strdup (lat));
	add_attr_string (parameters, "lon", g_strdup (lon));

	reverse = geocode_reverse_new_for_location (loc);

	if (!enable_network) {
		g_autoptr (GeocodeNominatim) backend = NULL;
		g_autofree gchar *expected_response = NULL;

		/* Load the JSON we expect as a response. */
		expected_response = load_json (expected_response_filename);

		/* Build the backend and query object. */
		backend = geocode_nominatim_test_new ();
		geocode_nominatim_test_expect_query (GEOCODE_NOMINATIM_TEST (backend),
		                                     parameters, expected_response);

		geocode_reverse_set_backend (reverse, GEOCODE_BACKEND (backend));
	}

	return g_steal_pointer (&reverse);
}

/*
 * @tp: (element-type utf8 GValue) (transfer none):
 * @params: (element-type utf8 utf8) (transfer none):
 * @expected_response_filename:
 *
 * Returns: (transfer full):
 */
static GeocodeForward *
create_forward_for_params (GHashTable  *tp,
                           GHashTable  *params,
                           const gchar *expected_response_filename)
{
	g_autoptr (GeocodeForward) forward = NULL;

	/* Set up the cache to avoid polluting the user’s main cache. */
	set_up_cache ();

	forward = geocode_forward_new_for_params (tp);

	if (!enable_network) {
		g_autoptr (GeocodeNominatim) backend = NULL;
		g_autofree gchar *expected_response = NULL;

		expected_response = load_json (expected_response_filename);

		backend = geocode_nominatim_test_new ();
		geocode_nominatim_test_expect_query (GEOCODE_NOMINATIM_TEST (backend),
		                                     params, expected_response);

		geocode_forward_set_backend (forward, GEOCODE_BACKEND (backend));
	}

	return g_steal_pointer (&forward);
}

/*
 * @q:
 * @params: (element-type utf8 utf8) (transfer none):
 * @expected_response_filename:
 *
 * Returns: (transfer full):
 */
static GeocodeForward *
create_forward_for_string (const gchar *q,
                           GHashTable  *params,
                           const gchar *expected_response_filename)
{
	g_autoptr (GeocodeForward) forward = NULL;

	/* Set up the cache to avoid polluting the user’s main cache. */
	set_up_cache ();

	forward = geocode_forward_new_for_string (q);

	if (!enable_network) {
		g_autoptr (GeocodeNominatim) backend = NULL;
		g_autofree gchar *expected_response = NULL;

		expected_response = load_json (expected_response_filename);

		backend = geocode_nominatim_test_new ();
		geocode_nominatim_test_expect_query (GEOCODE_NOMINATIM_TEST (backend),
		                                     params, expected_response);

		geocode_forward_set_backend (forward, GEOCODE_BACKEND (backend));
	}

	return g_steal_pointer (&forward);
}

static void
test_rev (void)
{
	GeocodeLocation *loc;
	GeocodeReverse *rev;
	GError *error = NULL;
	GeocodePlace *place;

	loc = geocode_location_new (51.2370361, -0.5894834, GEOCODE_LOCATION_ACCURACY_UNKNOWN);
	rev = create_reverse (loc, "rev.json");
	g_object_unref (loc);

	place = geocode_reverse_resolve (rev, &error);
	if (place == NULL) {
		g_warning ("Failed at reverse geocoding: %s", error->message);
		g_error_free (error);
	}
	g_assert (place != NULL);
	g_object_unref (rev);

        g_assert_cmpstr (geocode_place_get_name (place), ==, "The Astolat");
        g_assert_cmpstr (geocode_place_get_postal_code (place), ==, "GU2 7NU");
        g_assert_cmpstr (geocode_place_get_area (place), ==, "Guildford Park");
        g_assert_cmpstr (geocode_place_get_country_code (place), ==, "GB");
        g_assert_cmpstr (geocode_place_get_street (place), ==, "Old Palace Road");
        g_assert_cmpstr (geocode_place_get_county (place), ==, "Surrey");
        g_assert_cmpstr (geocode_place_get_country (place), ==, "United Kingdom");
        g_assert_cmpstr (geocode_place_get_administrative_area (place), ==, "South East");
        g_assert_cmpstr (geocode_place_get_state (place), ==, "England");

	g_print ("Got geocode answer:\n");
	print_place (place);
	g_object_unref (place);
}

static void
test_rev_fail (void)
{
	GeocodeLocation *loc;
	GeocodeReverse *rev;
	GError *error = NULL;
	GeocodePlace *place;

	loc = geocode_location_new (-90, -180, GEOCODE_LOCATION_ACCURACY_UNKNOWN);
	rev = create_reverse (loc, "rev_fail.json");
	g_object_unref (loc);

	place = geocode_reverse_resolve (rev, &error);
	g_assert (place == NULL);
	g_assert_error (error, GEOCODE_ERROR, GEOCODE_ERROR_NOT_SUPPORTED);
	g_error_free (error);
	g_object_unref (rev);
}

static void
test_xep (void)
{
	g_autoptr (GHashTable) tp = NULL, params = NULL;
	GeocodeForward *object;
	GList *res;
	GeocodePlace *place;
	GeocodeLocation *loc;
	GError *error = NULL;

	/* The query parameters we are submitting. */
	tp = g_hash_table_new_full (g_str_hash, g_str_equal,
				    g_free, (GDestroyNotify) free_attr);
	add_attr (tp, "country", "United Kingdom");
	add_attr (tp, "region", "England");
	add_attr (tp, "county", "Surrey");
	add_attr (tp, "locality", "Guildford");
	add_attr (tp, "postalcode", "GU2 7NU");
	add_attr (tp, "street", "Old Palace Road");

	/* The query parameters the mock server expects to receive. */
	params = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, NULL);
	add_attr_string (params, "country", "United Kingdom");
	add_attr_string (params, "state", "England");
	add_attr_string (params, "county", "Surrey");
	add_attr_string (params, "city", "Guildford");
	add_attr_string (params, "postalcode", "GU2 7NU");
	add_attr_string (params, "street", "Old Palace Road");
	add_attr_string (params, "limit", "1");

	object = create_forward_for_params (tp, params, "xep.json");

	res = geocode_forward_search (object, &error);
	if (res == NULL) {
		g_warning ("Failed at geocoding: %s", error->message);
		g_error_free (error);
	}
	g_assert (res != NULL);

	g_object_unref (object);

	place = res->data;
	loc = geocode_place_get_location (place);
	g_assert (loc != NULL);
	g_assert_cmpfloat (geocode_location_get_latitude (loc), ==, 51.2371333);
	g_assert_cmpfloat (geocode_location_get_longitude (loc), ==, -0.5894036);

	g_object_unref (place);
	g_list_free (res);
}

static void
test_pub (void)
{
	g_autoptr (GHashTable) params = NULL;
	GeocodeForward *object;
	GError *error = NULL;
	GList *res;
	GeocodePlace *place;
	GeocodeLocation *loc;

	/* The query parameters the mock server expects to receive. */
	params = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, NULL);
	add_attr_string (params, "q", "9, old palace road, guildford, surrey");
	add_attr_string (params, "limit", "1");
	add_attr_string (params, "bounded", "0");

	object = create_forward_for_string ("9, old palace road, guildford, surrey",
	                                    params, "pub.json");

	geocode_forward_set_answer_count (object, 1);
	res = geocode_forward_search (object, &error);
	if (res == NULL) {
		g_warning ("Failed at geocoding: %s", error->message);
		g_error_free (error);
	}
	g_assert (res != NULL);

	g_object_unref (object);

	g_assert_cmpint (g_list_length (res), ==, 1);
	place = res->data;
	loc = geocode_place_get_location (place);
	g_assert (loc != NULL);

	g_assert_cmpfloat (geocode_location_get_latitude (loc), ==, 51.2368747);
	g_assert_cmpfloat (geocode_location_get_longitude (loc), ==, -0.5912357);

	g_object_unref (place);
	g_list_free (res);
}

static void
test_search (void)
{
	GeocodeForward *forward;
	g_autoptr (GHashTable) params = NULL;
	GError *error = NULL;
	GList *results;
	char *old_locale;

	old_locale = g_strdup (setlocale(LC_MESSAGES, NULL));
	setlocale (LC_MESSAGES, "en_GB.UTF-8");

	/* The query parameters the mock server expects to receive. */
	params = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, NULL);
	add_attr_string (params, "q", "paris");
	add_attr_string (params, "limit", "10");
	add_attr_string (params, "bounded", "0");

	forward = create_forward_for_string ("paris", params, "search.json");

	results = geocode_forward_search (forward, &error);
	if (results == NULL) {
		g_warning ("Failed at geocoding: %s", error->message);
		g_error_free (error);
	}
	g_assert (results != NULL);

	g_object_unref (forward);

	g_assert_cmpint (g_list_length (results), ==, 10);

	/* We need to find Paris in France and in Texas */
        /* FIXME: Uncomment following and move variable declarations to top of
         *        this function when this bug is resolved:
         *        https://trac.openstreetmap.org/ticket/5111
         */
	/*GLis *l;
        gboolean got_france, got_texas;
	got_france = FALSE;
	got_texas = FALSE;
	for (l = results; l != NULL; l = l->next) {
		GeocodeLocation *loc;
		GeocodePlace *place = l->data;

		loc = geocode_place_get_location (place);
		g_assert (loc != NULL);

		if (g_strcmp0 (geocode_place_get_state (place), "Ile-de-France") == 0 &&
		    g_strcmp0 (geocode_place_get_name (place), "Paris") == 0 &&
                    g_strcmp0 (geocode_place_get_country (place), "France") == 0 &&
		    g_strcmp0 (geocode_location_get_description (loc), "Paris") == 0)
			got_france = TRUE;
		else if (g_strcmp0 (geocode_place_get_state (place), "Texas") == 0 &&
			 g_strcmp0 (geocode_place_get_country (place), "United States of America") == 0 &&
		         g_strcmp0 (geocode_place_get_name (place), "Paris, Texas, United States of America") == 0 &&
			 g_strcmp0 (geocode_location_get_description (loc),
                                    "Paris, Texas, United States of America") == 0)
			got_texas = TRUE;

		g_object_unref (place);

		if (got_france && got_texas)
			break;
	}
	g_list_free (results);

	g_assert (got_france);
	g_assert (got_texas);*/

	setlocale (LC_MESSAGES, old_locale);
	g_free (old_locale);

	g_list_free_full (results, (GDestroyNotify) g_object_unref);
}

static void
test_search_lat_long (void)
{
	GeocodeForward *object;
	GError *error = NULL;
	GList *res;
	GeocodePlace *place;
	GeocodeLocation *loc;
	GeocodeBoundingBox *bbox;
	g_autoptr (GHashTable) params = NULL;

	/* The query parameters the mock server expects to receive. */
	params = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, NULL);
	add_attr_string (params, "q", "Santa María del Río, San Luis Potosi");
	add_attr_string (params, "limit", "10");
	add_attr_string (params, "bounded", "0");

	object = create_forward_for_string ("Santa María del Río, San Luis Potosi",
	                                    params, "search_lat_long.json");

	res = geocode_forward_search (object, &error);
	if (res == NULL) {
		g_warning ("Failed at geocoding: %s", error->message);
		g_error_free (error);
	}
	g_assert (res != NULL);
	g_object_unref (object);

        /* Nominatim puts the Spanish city on the top & we want the Mexican one */
	place = res->next->data;
	loc = geocode_place_get_location (place);
	g_assert (loc != NULL);

	bbox = geocode_place_get_bounding_box (place);
	g_assert (bbox != NULL);

	g_assert_cmpfloat (geocode_location_get_latitude (loc) - 21.803641, <, 0.000001);
	g_assert_cmpfloat (geocode_location_get_longitude (loc) - -100.736292, <, 0.000001);
	g_assert (bbox_includes_location (bbox, geocode_place_get_location (place)));
	g_assert_cmpstr (geocode_place_get_name (place), ==, "Santa Maria Del Rio, Santa Mar\303\255a del R\303\255o");
	g_assert_cmpstr (geocode_location_get_description (loc), ==, "Santa Maria Del Rio, Santa Mar\303\255a del R\303\255o");

	g_list_free_full (res, (GDestroyNotify) g_object_unref);
}

static void
test_osm_type (void)
{
	GeocodeForward *object;
	GError *error = NULL;
	GList *res;
	GeocodePlace *place;
	guint i;
	struct {
		const gchar *search_string;
		GeocodePlaceOsmType osm_type;
	} types[] = {
		{ "Drottning Christinas väg", GEOCODE_PLACE_OSM_TYPE_WAY },
		{ "North dakota", GEOCODE_PLACE_OSM_TYPE_RELATION },
		{ "Grand canyon, USA", GEOCODE_PLACE_OSM_TYPE_NODE }
	};
	for (i = 0; i < G_N_ELEMENTS (types); i++) {
		g_autoptr (GHashTable) params = NULL;
		g_autofree gchar *expected_response_filename = NULL;

		/* The query parameters the mock server expects to receive. */
		params = g_hash_table_new_full (g_str_hash, g_str_equal, NULL,
		                                NULL);
		add_attr_string (params, "q", types[i].search_string);
		add_attr_string (params, "limit", "10");
		add_attr_string (params, "bounded", "0");

		expected_response_filename = g_strdup_printf ("osm_type%u.json",
		                                              i);

		object = create_forward_for_string (types[i].search_string, params,
		                                    expected_response_filename);
		res = geocode_forward_search (object, &error);
		if (res == NULL) {
			g_warning ("Failed at geocoding: %s", error->message);
			g_error_free (error);
		}
		g_assert (res != NULL);
		g_object_unref (object);

		place = res->data;
		g_test_message ("Location: %s", types[i].search_string);
		g_assert_cmpint (geocode_place_get_osm_type (place), ==, types[i].osm_type);
		g_list_free_full (res, (GDestroyNotify) g_object_unref);
	}
}

/* Test case from:
 * http://andrew.hedges.name/experiments/haversine/ */
static void
test_distance (void)
{
	g_autoptr (GeocodeLocation) loca = NULL, locb = NULL;

	/* 1600 Pennsylvania Ave NW, Washington, DC */
	loca = geocode_location_new (38.898556, -77.037852, GEOCODE_LOCATION_ACCURACY_UNKNOWN);
	/* 1600 Pennsylvania Ave NW, Washington, DC */
	locb = geocode_location_new (38.897147, -77.043934, GEOCODE_LOCATION_ACCURACY_UNKNOWN);

	g_assert_cmpfloat (geocode_location_get_distance_from (loca, locb) - 0.549311, <, 0.000001);
}

static void
test_locale_format (void)
{
#if defined(__GLIBC__) && !defined(__UCLIBC__)
	GeocodeForward *object;
	GError *error = NULL;
	GList *res;
	GeocodePlace *place;
	char *old_locale;
	g_autoptr (GHashTable) params = NULL;

	old_locale = g_strdup (setlocale(LC_ADDRESS, NULL));

	/* Set to a locale that has number after street */
	setlocale (LC_ADDRESS, "sv_SE.utf8");

	/* The query parameters the mock server expects to receive. */
	params = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, NULL);
	add_attr_string (params, "q", "Université libre de Bruxelles");
	add_attr_string (params, "limit", "10");
	add_attr_string (params, "bounded", "0");

	object = create_forward_for_string ("Université libre de Bruxelles",
	                                    params, "locale_format.json");

	res = geocode_forward_search (object, &error);
	if (res == NULL) {
		g_warning ("Failed at geocoding: %s", error->message);
		g_error_free (error);
	}
	g_assert (res != NULL);
	place = res->data;
	g_assert_cmpstr (geocode_place_get_street_address (place),
			 ==,
			 "Avenue Franklin Roosevelt - Franklin Rooseveltlaan 50");
	g_object_unref (object);
	g_list_free_full (res, (GDestroyNotify) g_object_unref);

	setlocale (LC_ADDRESS, old_locale);
	g_free (old_locale);
#endif
}

static void
test_locale_name (void)
{
	GeocodeForward *object;
	GError *error = NULL;
	GList *res;
	GeocodePlace *place;
	GeocodeLocation *loc;
	char *old_locale;
	g_autoptr (GHashTable) params = NULL;

	old_locale = g_strdup (setlocale(LC_MESSAGES, NULL));

	/* The query parameters the mock server expects to receive. */
	params = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, NULL);
	add_attr_string (params, "q", "moscow");
	add_attr_string (params, "limit", "10");
	add_attr_string (params, "bounded", "0");

	/* Check Moscow's name in Czech */
	setlocale (LC_MESSAGES, "cs_CZ.UTF-8");

	object = create_forward_for_string ("moscow", params,
	                                    "locale_name.json");

	res = geocode_forward_search (object, &error);
	if (res == NULL) {
		g_warning ("Failed at geocoding: %s", error->message);
		g_error_free (error);
	}
	g_assert (res != NULL);
	g_object_unref (object);

	place = res->data;
	g_assert_cmpstr (geocode_place_get_name (place), ==, "Moskva, Ruská federace");
	g_assert_cmpstr (geocode_place_get_state (place), ==, "Moskva");
	g_assert_cmpstr (geocode_place_get_country (place), ==, "Ruská federace");

	loc = geocode_place_get_location (place);
	g_assert (loc != NULL);
	g_assert_cmpstr (geocode_location_get_description (loc), ==, "Moskva, Ruská federace");
	g_assert_cmpfloat (geocode_location_get_latitude (loc) - 55.756950, <, 0.005);
	g_assert_cmpfloat (geocode_location_get_longitude (loc) - 37.614971, <, 0.005);
	print_place (place);

	g_list_free_full (res, (GDestroyNotify) g_object_unref);

	/* Check Bonneville's region in French */
        /* FIXME: Uncomment following and move variable declarations to top of
         *        this function when this bug is resolved:
         *        https://trac.openstreetmap.org/ticket/5111
         */
	/*GList *l;
        gboolean found = FALSE;
	setlocale (LC_MESSAGES, "fr_FR.UTF-8");
	object = geocode_forward_new_for_string ("bonneville");
	res = geocode_forward_search (object, &error);
	if (res == NULL) {
		g_warning ("Failed at geocoding: %s", error->message);
		g_error_free (error);
	}
	g_assert (res != NULL);
	g_object_unref (object);

	for (l = res; l != NULL; l = l->next) {
		place = l->data;

		loc = geocode_place_get_location (place);
		g_assert (loc != NULL);

		if (g_strcmp0 (geocode_place_get_name (place), "Bonneville, Rhône-Alpes, France") == 0 &&
		    g_strcmp0 (geocode_place_get_state (place), "Rhône-Alpes") == 0 &&
		    g_strcmp0 (geocode_place_get_country (place), "France") == 0 &&
		    g_strcmp0 (geocode_location_get_description (loc),
                               "Bonneville, Rhône-Alpes, France") == 0) {
		        found = TRUE;
                        break;
                }
	}

	g_list_free_full (res, (GDestroyNotify) g_object_unref);
	g_assert (found);*/

	/* And reset the locale */
	setlocale (LC_MESSAGES, old_locale);
	g_free (old_locale);
}

static void
test_resolve_json (void)
{
	GList *list;
	GeocodePlace *place;
	GError *error = NULL;
	guint i;
	struct {
		const char *fname;
		const char *error;
		const char *prop;
		const char *value;
	} tests[] = {
		{ "nominatim-area.json", NULL, "area", "Guildford Park" },
		{ "nominatim-no-results.json", "No matches found for request", NULL, NULL },
	};

	for (i = 0; i < G_N_ELEMENTS (tests); i++) {
		char *contents;
		char *filename;
                char *value;

		filename = g_test_build_filename (G_TEST_DIST,
		                                  tests[i].fname,
		                                  NULL);
		if (g_file_get_contents (filename, &contents, NULL, &error) == FALSE) {
			g_critical ("Couldn't load contents of '%s': %s",
				    filename, error->message);
		}
		g_free (filename);

                list = _geocode_parse_search_json (contents, &error);
		g_free (contents);

		if (tests[i].error) {
                        g_assert (list == NULL);
			g_assert_cmpstr (error->message, ==, tests[i].error);
		} else {
                        g_assert (list != NULL);
                        g_assert_cmpint (g_list_length (list), ==, 1);
		}

		if (list == NULL) {
			g_error_free (error);
			error = NULL;
			continue;
		}

                place = GEOCODE_PLACE (list->data);
                g_object_get (place, tests[i].prop, &value, NULL);
		g_assert_cmpstr (value, ==, tests[i].value);
                g_free (value);
                g_list_free_full (list, (GDestroyNotify) g_object_unref);
	}
}

static void
test_search_json (void)
{
	GError *error = NULL;
	GList *list, *l;
	char *contents;
        gboolean found = FALSE;
	g_autofree gchar *filename = NULL;

	filename = g_test_build_filename (G_TEST_DIST, "nominatim-rio.json",
	                                  NULL);

	if (g_file_get_contents (filename, &contents, NULL, &error) == FALSE) {
		g_critical ("Couldn't load contents of '%s': %s",
		            filename, error->message);
	}
	list = _geocode_parse_search_json (contents, &error);
	g_assert_no_error (error);

	g_assert (list != NULL);
	g_assert_cmpint (g_list_length (list), ==, 10);

	for (l = list; l != NULL; l = l->next) {
		GeocodeLocation *loc;
		GeocodePlace *place = l->data;

		loc = geocode_place_get_location (place);
		g_assert (loc != NULL);

		if (g_strcmp0 (geocode_place_get_name (place), "Rio de Janeiro, Rio de Janeiro, Brazil") == 0 &&
	            g_strcmp0 (geocode_place_get_town (place), "Rio de Janeiro") == 0 &&
		    g_strcmp0 (geocode_place_get_state (place), "Rio de Janeiro") == 0 &&
	            g_strcmp0 (geocode_place_get_county (place), "Rio de Janeiro") == 0 &&
		    g_strcmp0 (geocode_place_get_country (place), "Brazil") == 0 &&
		    g_strcmp0 (geocode_location_get_description (loc), "Rio de Janeiro, Rio de Janeiro, Brazil") == 0) {
                        found = TRUE;
                        break;
                }
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);
	g_assert (found);
	g_free (contents);
}

static GeocodeLocation *
new_loc (void)
{
	gdouble latitude, longitude;

	if (command_line_params[0] == NULL ||
	    *command_line_params[0] == '\0' ||
	    command_line_params[1] == NULL ||
	    *command_line_params[1] == '\0')
		return NULL;
	latitude = g_ascii_strtod (command_line_params[0], NULL);
	longitude = g_ascii_strtod (command_line_params[1], NULL);
	return geocode_location_new (latitude, longitude, GEOCODE_LOCATION_ACCURACY_UNKNOWN);
}

int main (int argc, char **argv)
{
	GError *error = NULL;
	g_autoptr (GOptionContext) context = NULL;
	gboolean do_rev_geocoding = FALSE;
	int answer_count = DEFAULT_ANSWER_COUNT;
	const GOptionEntry entries[] = {
		{ "count", 0, 0, G_OPTION_ARG_INT, &answer_count, "Number of answers to get for forward searches", NULL },
		{ "reverse", 0, 0, G_OPTION_ARG_NONE, &do_rev_geocoding, "Whether to do reverse geocoding for the given parameters", NULL },
		{ "enable-network", 0, 0, G_OPTION_ARG_NONE, &enable_network, "Whether to do network queries during unit tests, or use recorded results", NULL },
		{ G_OPTION_REMAINING, 0, 0, G_OPTION_ARG_STRING_ARRAY, &command_line_params, NULL, "[KEY=VALUE...]" },
		{ NULL }
	};

	setlocale (LC_ALL, "");
	g_test_init (&argc, &argv, NULL);
	g_test_bug_base ("http://bugzilla.gnome.org/show_bug.cgi?id=");

	/* Parse our own command-line options */
	context = g_option_context_new ("- test parser functions");
	g_option_context_add_main_entries (context, entries, GETTEXT_PACKAGE);

	if (g_option_context_parse (context, &argc, &argv, &error) == FALSE) {
		g_print ("Option parsing failed: %s\n", error->message);
		return 1;
	}

	if (command_line_params == NULL) {
		g_test_add_func ("/geocode/resolve_json", test_resolve_json);
		g_test_add_func ("/geocode/search_json", test_search_json);
		g_test_add_func ("/geocode/reverse", test_rev);
		g_test_add_func ("/geocode/reverse_fail", test_rev_fail);
		g_test_add_func ("/geocode/pub", test_pub);
		g_test_add_func ("/geocode/xep-0080", test_xep);
		g_test_add_func ("/geocode/locale_name", test_locale_name);
		g_test_add_func ("/geocode/locale_format", test_locale_format);
		g_test_add_func ("/geocode/search", test_search);
		g_test_add_func ("/geocode/search_lat_long", test_search_lat_long);
		g_test_add_func ("/geocode/distance", test_distance);
		g_test_add_func ("/geocode/osm_type", test_osm_type);
		return g_test_run ();
	}

	if (do_rev_geocoding == FALSE) {
		GeocodeForward *forward;

		forward = geocode_forward_new_for_string (command_line_params[0]);
		if (answer_count != DEFAULT_ANSWER_COUNT)
			geocode_forward_set_answer_count (forward, answer_count);
		geocode_forward_search_async (forward, NULL, got_geocode_search_cb, NULL);
	} else {
		GeocodeReverse *reverse;
		GeocodeLocation *loc;

		loc = new_loc ();
		if (loc == NULL) {
			g_print ("Options parsing failed: Use for example\n"
				 "%s --reverse -- 51.237070 -0.589669\n", argv[0]);
			return 1;
		}
		print_loc (loc);
		reverse = geocode_reverse_new_for_location (loc);
		g_object_unref (loc);
		geocode_reverse_resolve_async (reverse, NULL, got_geocode_cb, NULL);
	}

	loop = g_main_loop_new (NULL, FALSE);
	g_main_loop_run (loop);

	return 0;
}

