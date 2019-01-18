/*
 * Copyright 2016 Collabora Ltd.
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
 * Authors: Philip Withnall <philip.withnall@collabora.co.uk>
 */

#include "config.h"

#include <geocode-glib/geocode-glib.h>
#include <gio/gio.h>
#include <glib.h>
#include <locale.h>
#include <stdlib.h>

static void
place_list_free (GList *l)
{
	g_list_free_full (l, g_object_unref);
}

typedef GList PlaceList;
G_DEFINE_AUTOPTR_CLEANUP_FUNC (PlaceList, place_list_free)

/* Checks the two #GeocodePlace lists are equal, and in the same order. */
static void
assert_place_list_equal (GList *a,
                         GList *b)
{
	for (; a != NULL && b != NULL; a = a->next, b = b->next) {
		GeocodePlace *place_a, *place_b;

		place_a = GEOCODE_PLACE (a->data);
		place_b = GEOCODE_PLACE (b->data);

		g_assert (place_a != NULL);
		g_assert (place_b != NULL);
		g_assert_true (geocode_place_equal (place_a, place_b));
	}

	g_assert (a == NULL);
	g_assert (b == NULL);
}

static void
value_free (GValue *value)
{
	g_value_unset (value);
	g_free (value);
}

static GHashTable *build_params (const gchar *first_key,
                                 ...) G_GNUC_NULL_TERMINATED;

/* Convenience method taking a varargs list of key–value pairs (all of which
 * must be static strings) and returning them as a #GHashTable mapping strings
 * to #GValues. */
static GHashTable *
build_params (const gchar *first_key,
              ...)
{
	g_autoptr (GHashTable) params = NULL;
	va_list ap;
	const gchar *key, *value_str;

	params = g_hash_table_new_full (g_str_hash, g_str_equal,
	                                NULL, (GDestroyNotify) value_free);

	va_start (ap, first_key);
	for (key = first_key, value_str = va_arg (ap, const gchar *);
	     key != NULL;
	     key = va_arg (ap, const gchar *),
	     value_str = va_arg (ap, const gchar *)) {
		GValue *value;

		value = g_new0 (GValue, 1);
		g_value_init (value, G_TYPE_STRING);
		g_value_set_static_string (value, value_str);
		g_hash_table_insert (params, (gpointer) key,
		                     g_steal_pointer (&value));
	}

	va_end (ap);

	return g_steal_pointer (&params);
}

/* Variant of build_params() which expects the values in the varargs list to be
 * #gdoubles rather than strings. */
static GHashTable *
build_double_params (const gchar *first_key,
                     ...)
{
	g_autoptr (GHashTable) params = NULL;
	va_list ap;
	const gchar *key;
	gdouble value_double;

	params = g_hash_table_new_full (g_str_hash, g_str_equal,
	                                NULL, (GDestroyNotify) value_free);

	va_start (ap, first_key);
	for (key = first_key, value_double = va_arg (ap, gdouble);
	     key != NULL;
	     key = va_arg (ap, const gchar *),
	     value_double = va_arg (ap, gdouble)) {
		GValue *value;

		value = g_new0 (GValue, 1);
		g_value_init (value, G_TYPE_DOUBLE);
		g_value_set_double (value, value_double);
		g_hash_table_insert (params, (gpointer) key,
		                     g_steal_pointer (&value));
	}

	va_end (ap);

	return g_steal_pointer (&params);
}

/* Test that a #GeocodeForward query with a single result from the mock backend
 * works. */
static void
test_forward_single_result (void)
{
	g_autoptr (GeocodeForward) forward = NULL;
	g_autoptr (GeocodeMockBackend) backend = NULL;
	g_autoptr (GHashTable) params = NULL;
	g_autoptr (PlaceList) results = NULL;
	g_autoptr (PlaceList) expected_results = NULL;
	g_autoptr (GError) error = NULL;
	g_autoptr (GeocodePlace) expected_place = NULL;
	g_autoptr (GeocodeLocation) expected_location = NULL;
	GPtrArray *query_log;  /* (element-type GeocodeMockBackendQuery) */

	backend = geocode_mock_backend_new ();

	forward = geocode_forward_new_for_string ("Bullpot Farm");
	geocode_forward_set_backend (forward, GEOCODE_BACKEND (backend));

	/* Build the set of parameters the mock backend expects to receive from
	 * the #GeocodeForward instance. */
	params = build_params ("location", "Bullpot Farm", NULL);

	/* Build the set of results the mock backend should return. */
	expected_location = geocode_location_new_with_description (
	    54.22759825, -2.51857179181113, 5.0,
	    "Bullpot Farm, Fell Road, South Lakeland, Cumbria, "
	    "North West England, England, United Kingdom");
	expected_place = geocode_place_new_with_location (
	    "Bullpot Farm", GEOCODE_PLACE_TYPE_BUILDING, expected_location);
	expected_results = g_list_prepend (expected_results,
	                                   g_steal_pointer (&expected_place));

	geocode_mock_backend_add_forward_result (backend, params,
	                                         expected_results, NULL);

	/* Do the search. */
	results = geocode_forward_search (forward, &error);

	g_assert_no_error (error);
	assert_place_list_equal (results, expected_results);

	query_log = geocode_mock_backend_get_query_log (backend);
	g_assert_cmpuint (query_log->len, ==, 1);
}

/* Test that a #GeocodeForward query with multiple results from the mock backend
 * works. */
static void
test_forward_multiple_results (void)
{
	g_autoptr (GeocodeForward) forward = NULL;
	g_autoptr (GeocodeMockBackend) backend = NULL;
	g_autoptr (GHashTable) params = NULL;
	g_autoptr (PlaceList) results = NULL;
	g_autoptr (PlaceList) expected_results = NULL;
	g_autoptr (GError) error = NULL;
	g_autoptr (GeocodePlace) expected_place1 = NULL;
	g_autoptr (GeocodePlace) expected_place2 = NULL;
	g_autoptr (GeocodePlace) expected_place3 = NULL;
	g_autoptr (GeocodeLocation) expected_location1 = NULL;
	g_autoptr (GeocodeLocation) expected_location2 = NULL;
	g_autoptr (GeocodeLocation) expected_location3 = NULL;
	GPtrArray *query_log;  /* (element-type GeocodeMockBackendQuery) */

	backend = geocode_mock_backend_new ();

	/* ‘Y Foel’ is Welsh for ‘the bald hill’. Those who have visited Wales
	 * will know there are quite a few such hills. */
	forward = geocode_forward_new_for_string ("Y Foel");
	geocode_forward_set_backend (forward, GEOCODE_BACKEND (backend));

	/* Build the set of parameters the mock backend expects to receive from
	 * the #GeocodeForward instance. */
	params = build_params ("location", "Y Foel", NULL);

	/* Build the set of results the mock backend should return. */
	expected_location1 = geocode_location_new (53.0309637, -4.3126653, 50.0);
	expected_place1 = geocode_place_new_with_location (
	    "Foel", GEOCODE_PLACE_TYPE_LAND_FEATURE, expected_location1);
	expected_results = g_list_prepend (expected_results,
	                                   g_steal_pointer (&expected_place1));

	expected_location2 = geocode_location_new (52.9867051, -4.2023085, 50.0);
	expected_place2 = geocode_place_new_with_location (
	    "Y Foel", GEOCODE_PLACE_TYPE_LAND_FEATURE, expected_location2);
	expected_results = g_list_prepend (expected_results,
	                                   g_steal_pointer (&expected_place2));

	expected_location3 = geocode_location_new (52.4456769, -3.4452951, 50.0);
	expected_place3 = geocode_place_new_with_location (
	    "Y Foel", GEOCODE_PLACE_TYPE_LAND_FEATURE, expected_location3);
	expected_results = g_list_prepend (expected_results,
	                                   g_steal_pointer (&expected_place3));

	geocode_mock_backend_add_forward_result (backend, params,
	                                         expected_results, NULL);

	/* Do the search. */
	results = geocode_forward_search (forward, &error);

	g_assert_no_error (error);
	assert_place_list_equal (results, expected_results);

	query_log = geocode_mock_backend_get_query_log (backend);
	g_assert_cmpuint (query_log->len, ==, 1);
}

/* Test that a #GeocodeForward query with no results (but no error) from the
 * mock backend works. */
static void
test_forward_no_results (void)
{
	g_autoptr (GeocodeForward) forward = NULL;
	g_autoptr (GeocodeMockBackend) backend = NULL;
	g_autoptr (GHashTable) params = NULL;
	g_autoptr (PlaceList) results = NULL;
	g_autoptr (GError) error = NULL;
	const GError expected_error = {
	    GEOCODE_ERROR, GEOCODE_ERROR_NO_MATCHES,
	    (gchar *) "No matches found for request"
	};
	GPtrArray *query_log;  /* (element-type GeocodeMockBackendQuery) */

	backend = geocode_mock_backend_new ();

	forward = geocode_forward_new_for_string ("Reallydoesnotexist");
	geocode_forward_set_backend (forward, GEOCODE_BACKEND (backend));

	/* Build the set of parameters the mock backend expects to receive from
	 * the #GeocodeForward instance. */
	params = build_params ("location", "Reallydoesnotexist", NULL);

	geocode_mock_backend_add_forward_result (backend, params,
	                                         NULL  /* expected results */,
	                                         &expected_error);

	/* Do the search. */
	results = geocode_forward_search (forward, &error);

	g_assert_error (error, expected_error.domain, expected_error.code);
	g_assert_null (results);

	query_log = geocode_mock_backend_get_query_log (backend);
	g_assert_cmpuint (query_log->len, ==, 1);
}

/* Test that a #GeocodeForward query correctly handles errors from the mock
 * backend. */
static void
test_forward_error (void)
{
	g_autoptr (GeocodeForward) forward = NULL;
	g_autoptr (GeocodeMockBackend) backend = NULL;
	g_autoptr (GHashTable) params = NULL;
	g_autoptr (PlaceList) results = NULL;
	g_autoptr (GError) error = NULL;
	const GError expected_error = {
	    GEOCODE_ERROR, GEOCODE_ERROR_INTERNAL_SERVER,
	    (gchar *) "Internal server error"
	};
	GPtrArray *query_log;  /* (element-type GeocodeMockBackendQuery) */

	backend = geocode_mock_backend_new ();

	forward = geocode_forward_new_for_string ("Paradise");
	geocode_forward_set_backend (forward, GEOCODE_BACKEND (backend));

	/* Build the set of parameters the mock backend expects to receive from
	 * the #GeocodeForward instance. */
	params = build_params ("location", "Paradise", NULL);

	geocode_mock_backend_add_forward_result (backend, params,
	                                         NULL  /* expected results */,
	                                         &expected_error);

	/* Do the search. */
	results = geocode_forward_search (forward, &error);

	g_assert_error (error, expected_error.domain, expected_error.code);
	g_assert_null (results);

	query_log = geocode_mock_backend_get_query_log (backend);
	g_assert_cmpuint (query_log->len, ==, 1);
}

/* Test that a #GeocodeForward query with lots of additional parameters and no
 * results (but no error) from the mock backend works. */
static void
test_forward_with_params (void)
{
	g_autoptr (GeocodeForward) forward = NULL;
	g_autoptr (GeocodeMockBackend) backend = NULL;
	g_autoptr (GHashTable) params = NULL;
	g_autoptr (PlaceList) results = NULL;
	g_autoptr (GError) error = NULL;
	const GError expected_error = {
	    GEOCODE_ERROR, GEOCODE_ERROR_INTERNAL_SERVER,
	    (gchar *) "Some complex server error"
	};
	GPtrArray *query_log;  /* (element-type GeocodeMockBackendQuery) */

	/* Build the set of parameters the mock backend expects to receive from
	 * the #GeocodeForward instance. */
	params = build_params ("building", "Kett House",
	                       "street", "Station Road",
	                       "locality", "Cambridge",
	                       "postalcode", "CB12JH",
	                       "country", "Inglaterra",
	                       "uri", "https://collabora.com/",
	                       "language", "es",
	                       NULL);

	backend = geocode_mock_backend_new ();

	forward = geocode_forward_new_for_params (params);
	geocode_forward_set_backend (forward, GEOCODE_BACKEND (backend));

	geocode_mock_backend_add_forward_result (backend, params,
	                                         NULL  /* expected results */,
	                                         &expected_error);

	/* Do the search. */
	results = geocode_forward_search (forward, &error);

	g_assert_error (error, expected_error.domain, expected_error.code);
	g_assert_null (results);

	query_log = geocode_mock_backend_get_query_log (backend);
	g_assert_cmpuint (query_log->len, ==, 1);
}

/* Test that a #GeocodeReverse query with a single result from the mock backend
 * works. */
static void
test_reverse_single_result (void)
{
	g_autoptr (GeocodeReverse) reverse = NULL;
	g_autoptr (GeocodeMockBackend) backend = NULL;
	g_autoptr (GeocodeLocation) location = NULL;
	g_autoptr (GHashTable) params = NULL;
	g_autoptr (GeocodePlace) result = NULL;
	g_autoptr (PlaceList) expected_results = NULL;
	g_autoptr (GError) error = NULL;
	g_autoptr (GeocodePlace) expected_place = NULL;
	g_autoptr (GeocodeLocation) expected_location = NULL;
	GPtrArray *query_log;  /* (element-type GeocodeMockBackendQuery) */

	backend = geocode_mock_backend_new ();

	location = geocode_location_new (52.2127749, 0.0806149693681216, 10.0);
	reverse = geocode_reverse_new_for_location (location);
	geocode_reverse_set_backend (reverse, GEOCODE_BACKEND (backend));

	/* Build the set of parameters the mock backend expects to receive from
	 * the #GeocodeReverse instance. */
	params = build_double_params ("lat", 52.2127749,
	                              "lon", 0.0806149693681216,
	                              NULL);

	/* Build the set of results the mock backend should return. */
	expected_location = geocode_location_new_with_description (
	    52.2127749, 0.0806149693681216, 10.0, "British Antarctic Survey");
	expected_place = geocode_place_new_with_location (
	    "British Antarctic Survey", GEOCODE_PLACE_TYPE_BUILDING,
	    expected_location);
	expected_results = g_list_prepend (expected_results,
	                                   g_steal_pointer (&expected_place));

	geocode_mock_backend_add_reverse_result (backend, params,
	                                         expected_results, NULL);

	/* Do the search. */
	result = geocode_reverse_resolve (reverse, &error);

	g_assert_no_error (error);
	g_assert_true (geocode_place_equal (result, expected_results->data));

	query_log = geocode_mock_backend_get_query_log (backend);
	g_assert_cmpuint (query_log->len, ==, 1);
}

/* Test that a #GeocodeReverse query with multiple results from the mock backend
 * works. This has to be done by testing the backend directly, since
 * #GeocodeReverse does not support multiple results. */
static void
test_reverse_multiple_results (void)
{
	g_autoptr (GeocodeMockBackend) backend = NULL;
	g_autoptr (GeocodeLocation) location = NULL;
	g_autoptr (GHashTable) params = NULL;
	g_autoptr (PlaceList) results = NULL;
	g_autoptr (PlaceList) expected_results = NULL;
	g_autoptr (GError) error = NULL;
	g_autoptr (GeocodePlace) expected_place1 = NULL;
	g_autoptr (GeocodePlace) expected_place2 = NULL;
	g_autoptr (GeocodeLocation) expected_location1 = NULL;
	g_autoptr (GeocodeLocation) expected_location2 = NULL;
	GPtrArray *query_log;  /* (element-type GeocodeMockBackendQuery) */

	backend = geocode_mock_backend_new ();

	location = geocode_location_new (51.507891226831774, -0.12454301118850708, 1.0);

	/* Build the set of parameters the mock backend expects to receive from
	 * the #GeocodeBackend instance. */
	params = build_double_params ("lat", 51.507891226831774,
	                              "lon", -0.12454301118850708,
	                              NULL);

	/* Build the set of results the mock backend should return. */
	expected_location1 = geocode_location_new_with_description (
	    52.2127749, 0.0806149693681216, 1.0, "Heaven");
	expected_place1 = geocode_place_new_with_location (
	    "Heaven, The Arches, London, England", GEOCODE_PLACE_TYPE_UNKNOWN,
	    expected_location1);
	expected_results = g_list_prepend (expected_results,
	                                   g_steal_pointer (&expected_place1));

	expected_location2 = geocode_location_new_with_description (
	    51.5077409783118, -0.12424796819686891, 50.0, "Charing Cross Station");
	expected_place2 = geocode_place_new_with_location (
	    "Charing Cross Station, London, England",
	    GEOCODE_PLACE_TYPE_RAILWAY_STATION, expected_location2);
	expected_results = g_list_prepend (expected_results,
	                                   g_steal_pointer (&expected_place2));

	geocode_mock_backend_add_reverse_result (backend, params,
	                                         expected_results, NULL);

	/* Do the search. */
	results = geocode_backend_reverse_resolve (GEOCODE_BACKEND (backend),
	                                           params, NULL, &error);

	g_assert_no_error (error);
	assert_place_list_equal (results, expected_results);

	query_log = geocode_mock_backend_get_query_log (backend);
	g_assert_cmpuint (query_log->len, ==, 1);
}

/* Test that a #GeocodeReverse query with no results (but no error) from the
 * mock backend works. */
static void
test_reverse_no_results (void)
{
	g_autoptr (GeocodeReverse) reverse = NULL;
	g_autoptr (GeocodeMockBackend) backend = NULL;
	g_autoptr (GeocodeLocation) location = NULL;
	g_autoptr (GHashTable) params = NULL;
	g_autoptr (GeocodePlace) result = NULL;
	g_autoptr (GError) error = NULL;
	const GError expected_error = {
	    GEOCODE_ERROR, GEOCODE_ERROR_NOT_SUPPORTED,
	    (gchar *) "Unable to geocode"
	};
	GPtrArray *query_log;  /* (element-type GeocodeMockBackendQuery) */

	backend = geocode_mock_backend_new ();

	location = geocode_location_new (45.4015357985572, -35.9033203125, 10.0);
	reverse = geocode_reverse_new_for_location (location);
	geocode_reverse_set_backend (reverse, GEOCODE_BACKEND (backend));

	/* Build the set of parameters the mock backend expects to receive from
	 * the #GeocodeReverse instance. */
	params = build_double_params ("lat", 45.4015357985572,
	                              "lon", -35.9033203125,
	                              NULL);

	geocode_mock_backend_add_reverse_result (backend, params,
	                                         NULL  /* expected results */,
	                                         &expected_error);

	/* Do the search. */
	result = geocode_reverse_resolve (reverse, &error);

	g_assert_error (error, expected_error.domain, expected_error.code);
	g_assert_null (result);

	query_log = geocode_mock_backend_get_query_log (backend);
	g_assert_cmpuint (query_log->len, ==, 1);
}

/* Test that a #GeocodeReverse query correctly handles errors from the mock
 * backend. */
static void
test_reverse_error (void)
{
	g_autoptr (GeocodeReverse) reverse = NULL;
	g_autoptr (GeocodeMockBackend) backend = NULL;
	g_autoptr (GeocodeLocation) location = NULL;
	g_autoptr (GHashTable) params = NULL;
	g_autoptr (GeocodePlace) result = NULL;
	g_autoptr (GError) error = NULL;
	const GError expected_error = {
	    GEOCODE_ERROR, GEOCODE_ERROR_INTERNAL_SERVER,
	    (gchar *) "Internal server error"
	};
	GPtrArray *query_log;  /* (element-type GeocodeMockBackendQuery) */

	backend = geocode_mock_backend_new ();

	location = geocode_location_new (45.4015357985572, -35.9033203125, 10.0);
	reverse = geocode_reverse_new_for_location (location);
	geocode_reverse_set_backend (reverse, GEOCODE_BACKEND (backend));

	/* Build the set of parameters the mock backend expects to receive from
	 * the #GeocodeReverse instance. */
	params = build_double_params ("lat", 45.4015357985572,
	                              "lon", -35.9033203125,
	                              NULL);

	geocode_mock_backend_add_reverse_result (backend, params,
	                                         NULL  /* expected results */,
	                                         &expected_error);

	/* Do the search. */
	result = geocode_reverse_resolve (reverse, &error);

	g_assert_error (error, expected_error.domain, expected_error.code);
	g_assert_null (result);

	query_log = geocode_mock_backend_get_query_log (backend);
	g_assert_cmpuint (query_log->len, ==, 1);
}

/* Test that the query log and clear functionality on the backend works. */
static void
test_clear (void)
{
	g_autoptr (GeocodeForward) forward = NULL;
	g_autoptr (GeocodeMockBackend) backend = NULL;
	g_autoptr (GHashTable) params = NULL;
	g_autoptr (PlaceList) results = NULL;
	g_autoptr (PlaceList) expected_results = NULL;
	g_autoptr (GError) error = NULL;
	g_autoptr (GeocodePlace) expected_place = NULL;
	g_autoptr (GeocodeLocation) expected_location = NULL;
	GPtrArray *query_log;  /* (element-type GeocodeMockBackendQuery) */
	const GeocodeMockBackendQuery *query;

	backend = geocode_mock_backend_new ();

	forward = geocode_forward_new_for_string ("Bullpot Farm");
	geocode_forward_set_backend (forward, GEOCODE_BACKEND (backend));

	/* Build the set of parameters the mock backend expects to receive from
	 * the #GeocodeForward instance. */
	params = build_params ("location", "Bullpot Farm", NULL);

	/* Build the set of results the mock backend should return. */
	expected_location = geocode_location_new_with_description (
	    54.22759825, -2.51857179181113, 5.0,
	    "Bullpot Farm, Fell Road, South Lakeland, Cumbria, "
	    "North West England, England, United Kingdom");
	expected_place = geocode_place_new_with_location (
	    "Bullpot Farm", GEOCODE_PLACE_TYPE_BUILDING, expected_location);
	expected_results = g_list_prepend (expected_results,
	                                   g_steal_pointer (&expected_place));

	geocode_mock_backend_add_forward_result (backend, params,
	                                         expected_results, NULL);

	/* Do the search. */
	results = geocode_forward_search (forward, &error);

	g_assert_no_error (error);
	assert_place_list_equal (results, expected_results);

	query_log = geocode_mock_backend_get_query_log (backend);
	g_assert_cmpuint (query_log->len, ==, 1);

	query = (const GeocodeMockBackendQuery *) query_log->pdata[0];
	g_assert_cmpuint (g_hash_table_size (query->params), ==, 1);
	g_assert_true (query->is_forward);
	assert_place_list_equal (query->results, expected_results);
	g_assert_null (query->error);

	/* Try clearing the backend then try another search. */
	geocode_mock_backend_clear (backend);

	query_log = geocode_mock_backend_get_query_log (backend);
	g_assert_cmpuint (query_log->len, ==, 0);

	results = geocode_forward_search (forward, &error);
	g_assert_null (results);
	g_assert_error (error, GEOCODE_ERROR, GEOCODE_ERROR_NO_MATCHES);
}

int
main (int argc, char **argv)
{
	setlocale (LC_ALL, "");
	g_test_init (&argc, &argv, NULL);
	g_test_bug_base ("http://bugzilla.gnome.org/show_bug.cgi?id=");

	g_test_add_func ("/mock-backend/forward/single-result",
	                 test_forward_single_result);
	g_test_add_func ("/mock-backend/forward/multiple-results",
	                 test_forward_multiple_results);
	g_test_add_func ("/mock-backend/forward/no-results",
	                 test_forward_no_results);
	g_test_add_func ("/mock-backend/forward/error", test_forward_error);
	g_test_add_func ("/mock-backend/forward/with-params",
	                 test_forward_with_params);

	g_test_add_func ("/mock-backend/reverse-single-result",
	                 test_reverse_single_result);
	g_test_add_func ("/mock-backend/reverse-multiple-results",
	                 test_reverse_multiple_results);
	g_test_add_func ("/mock-backend/reverse-no-results",
	                 test_reverse_no_results);
	g_test_add_func ("/mock-backend/reverse-error", test_reverse_error);

	g_test_add_func ("/mock-backend/clear", test_clear);

	return g_test_run ();
}

