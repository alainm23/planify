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

#include <gio/gio.h>
#include <json-glib/json-glib.h>
#include <libsoup/soup.h>
#include <stdlib.h>
#include <string.h>

#include "geocode-glib-private.h"
#include "geocode-glib.h"
#include "geocode-mock-backend.h"

/**
 * SECTION:geocode-mock-backend
 * @short_description: Geocode mock backend implementation
 * @include: geocode-glib/geocode-glib.h
 *
 * #GeocodeMockBackend is intended to be used in unit tests for applications
 * which use geocode-glib — it allows them to set the geocode results they
 * expect their application to query, and check afterwards that the queries
 * were performed. It works offline, which allows application unit tests to be
 * run on integration and build machines which are not online. It is not
 * expected that #GeocodeMockBackend will be used in production code.
 *
 * To use it, create the backend instance, add the query results to it which
 * you want to be returned to your application’s queries, then use it as the
 * #GeocodeBackend for geocode_forward_set_backend() or
 * geocode_reverse_set_backend(). After a test has been run, the set of queries
 * which the code under test actually made on the backend can be checked using
 * geocode_mock_backend_get_query_log(). The backend can be reset using
 * geocode_mock_backend_clear() and new queries added for the next test.
 *
 * |[<!-- language="C" -->
 * static void
 * place_list_free (GList *l)
 * {
 *   g_list_free_full (l, g_object_unref);
 * }
 *
 * typedef GList PlaceList;
 * G_DEFINE_AUTOPTR_CLEANUP_FUNC (PlaceList, place_list_free)
 *
 * g_autoptr (GeocodeForward) forward = NULL;
 * g_autoptr (GeocodeMockBackend) backend = NULL;
 * g_autoptr (GHashTable) params = NULL;
 * GValue location = G_VALUE_INIT;
 * g_autoptr (PlaceList) results = NULL;
 * g_autoptr (PlaceList) expected_results = NULL;
 * g_autoptr (GError) error = NULL;
 * g_autoptr (GeocodePlace) expected_place = NULL;
 * g_autoptr (GeocodeLocation) expected_location = NULL;
 * GPtrArray *query_log;  /<!-- -->* (element-type GeocodeMockBackendQuery) *<!-- -->/
 *
 * backend = geocode_mock_backend_new ();
 *
 * /<!-- -->* Build the set of parameters the mock backend expects to receive from
 *  * the #GeocodeForward instance. *<!-- -->/
 * params = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, NULL);
 *
 * g_value_init (&location, G_TYPE_STRING);
 * g_value_set_static_string (&location, "Bullpot Farm");
 * g_hash_table_insert (params, (gpointer) "location", &location);
 *
 * /<!-- -->* Build the set of results the mock backend should return. *<!-- -->/
 * expected_location = geocode_location_new_with_description (
 *     54.22759825, -2.51857179181113, 5.0,
 *     "Bullpot Farm, Fell Road, South Lakeland, Cumbria, "
 *     "North West England, England, United Kingdom");
 * expected_place = geocode_place_new_with_location (
 *     "Bullpot Farm", GEOCODE_PLACE_TYPE_BUILDING, expected_location);
 * expected_results = g_list_prepend (expected_results,
 *                                    g_steal_pointer (&expected_place));
 *
 * geocode_mock_backend_add_forward_result (backend, params,
 *                                          expected_results, NULL);
 *
 * /<!-- -->* Do the search. This would typically call the application code
 *  * under test, rather than geocode-glib directly. *<!-- -->/
 * forward = geocode_forward_new_for_string ("Bullpot Farm");
 * geocode_forward_set_backend (forward, GEOCODE_BACKEND (backend));
 * results = geocode_forward_search (forward, &error);
 *
 * g_assert_no_error (error);
 * assert_place_list_equal (results, expected_results);
 *
 * /<!-- -->* Check the application made the expected query. *<!-- -->/
 * query_log = geocode_mock_backend_get_query_log (backend);
 * g_assert_cmpuint (query_log->len, ==, 1);
 * ]|
 *
 * Since: 3.23.1
 */

struct _GeocodeMockBackend {
	GObject parent;

	GPtrArray *forward_results;  /* (owned) (element-type owned GeocodeMockBackendQuery) */
	GPtrArray *reverse_results;  /* (owned) (element-type owned GeocodeMockBackendQuery) */
	GPtrArray *query_log;  /* (owned) (element-type owned GeocodeMockBackendQuery) */
};

static void geocode_backend_iface_init (GeocodeBackendInterface *iface);

G_DEFINE_TYPE_WITH_CODE (GeocodeMockBackend, geocode_mock_backend, G_TYPE_OBJECT,
                         G_IMPLEMENT_INTERFACE (GEOCODE_TYPE_BACKEND,
                                                geocode_backend_iface_init))

/******************************************************************************/

static void
value_free (GValue *value)
{
	g_value_unset (value);
	g_free (value);
}

static GHashTable *
params_copy_deep (GHashTable *params)
{
	g_autoptr (GHashTable) output = NULL;
	GHashTableIter iter;
	const gchar *key;
	const GValue *value;

	output = g_hash_table_new_full (g_str_hash, g_str_equal,
	                                g_free, (GDestroyNotify) value_free);

	g_hash_table_iter_init (&iter, params);

	while (g_hash_table_iter_next (&iter, (gpointer *) &key,
	                               (gpointer *) &value)) {
		GValue *value_copy = NULL;

		value_copy = g_new0 (GValue, 1);
		g_value_init (value_copy, G_VALUE_TYPE (value));
		g_value_copy (value, value_copy);

		g_hash_table_insert (output, g_strdup (key),
		                     g_steal_pointer (&value_copy));
	}

	return g_steal_pointer (&output);
}

static GList *
results_copy_deep (GList *results)
{
	return g_list_copy_deep (results, (GCopyFunc) g_object_ref, NULL);
}

/******************************************************************************/

static void
geocode_mock_backend_query_free (GeocodeMockBackendQuery *query)
{
	if (query == NULL)
		return;

	g_hash_table_unref (query->params);
	g_list_free_full (query->results, g_object_unref);
	g_clear_error (&query->error);

	g_free (query);
}

G_DEFINE_AUTOPTR_CLEANUP_FUNC (GeocodeMockBackendQuery,
                               geocode_mock_backend_query_free)

static GeocodeMockBackendQuery *
geocode_mock_backend_query_new (GHashTable   *params,
                                gboolean      is_forward,
                                GList        *results,
                                const GError *error)
{
	g_autoptr (GeocodeMockBackendQuery) query = NULL;

	g_return_val_if_fail (params != NULL, NULL);
	g_return_val_if_fail ((results == NULL) != (error == NULL), NULL);

	query = g_new0 (GeocodeMockBackendQuery, 1);

	query->params = params_copy_deep (params);
	query->is_forward = is_forward;
	query->results = results_copy_deep (results);
	query->error = (error != NULL) ? g_error_copy (error) : NULL;

	return g_steal_pointer (&query);
}

/******************************************************************************/

static gboolean
value_equal (const GValue *a,
             const GValue *b)
{
	GValue a_string = G_VALUE_INIT, b_string = G_VALUE_INIT;
	gboolean equal;

	g_return_val_if_fail (a != NULL, FALSE);
	g_return_val_if_fail (b != NULL, FALSE);

	if (G_VALUE_TYPE (a) != G_VALUE_TYPE (b))
		return FALSE;

	/* Doubles can’t be converted to strings, so special-case comparison
	 * of them. */
	if (G_VALUE_TYPE (a) == G_TYPE_DOUBLE) {
		return g_value_get_double (a) == g_value_get_double (b);
	}

	g_value_init (&a_string, G_TYPE_STRING);
	g_value_init (&b_string, G_TYPE_STRING);

	/* We assume that all GValue types can be converted to strings for the
	 * purpose of comparison. */
	if (!g_value_transform (a, &a_string) ||
	    !g_value_transform (b, &b_string))
		return FALSE;

	equal = g_str_equal (g_value_get_string (&a_string),
	                     g_value_get_string (&b_string));

	g_value_unset (&b_string);
	g_value_unset (&a_string);

	return equal;
}

static gboolean
hash_table_equal (GHashTable *a,
                  GHashTable *b)
{
	GHashTableIter iter_a;
	const gchar *key;
	const GValue *value_a, *value_b;

	if (g_hash_table_size (a) != g_hash_table_size (b))
		return FALSE;

	g_hash_table_iter_init (&iter_a, a);

	while (g_hash_table_iter_next (&iter_a, (gpointer *) &key,
	                               (gpointer *) &value_a)) {
		if (!g_hash_table_lookup_extended (b, key, NULL,
		                                   (gpointer *) &value_b) ||
		    !value_equal (value_a, value_b))
			return FALSE;
	}

	return TRUE;
}

static const GeocodeMockBackendQuery *
find_query (GPtrArray  *queries,
            GHashTable *params,
            gsize      *index)
{
	gsize i;

	for (i = 0; i < queries->len; i++) {
		const GeocodeMockBackendQuery *query = queries->pdata[i];

		if (hash_table_equal (query->params, params)) {
			if (index != NULL)
				*index = i;

			return query;
		}
	}

	return NULL;
}

static void
debug_print_params (GHashTable *params)
{
	GHashTableIter iter;
	const gchar *key;
	const GValue *value;
	g_autoptr (GString) output = NULL;
	g_autofree gchar *output_str = NULL;
	gboolean non_empty = FALSE;

	g_hash_table_iter_init (&iter, params);
	output = g_string_new ("");

	while (g_hash_table_iter_next (&iter, (gpointer *) &key,
	                               (gpointer *) &value)) {
		g_autofree gchar *value_str = NULL;

		value_str = g_strdup_value_contents (value);
		g_string_append_printf (output, " • %s = %s\n", key, value_str);

		non_empty = TRUE;
	}

	if (non_empty)
		g_string_prepend (output, "Parameters:\n");
	else
		g_string_append (output, "Parameters: (none)\n");

	/* Strip off the trailing newline. */
	g_string_truncate (output, output->len - 1);

	output_str = g_string_free (g_steal_pointer (&output), FALSE);
	g_debug ("%s", output_str);
}

static GList *
forward_or_reverse (GeocodeMockBackend  *self,
                    GPtrArray           *results,
                    GeocodeError         no_results_error,
                    GHashTable          *params,
                    GCancellable        *cancellable,
                    GError             **error)
{
	const GeocodeMockBackendQuery *query;
	g_autoptr (GeocodeMockBackendQuery) logged_query = NULL;
	GList *output_results = NULL;  /* (element-type GeocodePlace) */
	g_autoptr (GError) output_error = NULL;

	/* Log the query; helpful during development. */
	debug_print_params (params);

	/* Do we have a mock result for this query? */
	query = find_query (results, params, NULL);

	if (query == NULL) {
		output_error = g_error_new (GEOCODE_ERROR, no_results_error,
		                            "No matches found for request");
	} else if (query->error != NULL) {
		output_error = g_error_copy (query->error);
	} else {
		output_results = results_copy_deep (query->results);
	}

	/* Log the query. */
	logged_query = geocode_mock_backend_query_new (params, TRUE,
	                                               output_results,
	                                               output_error);
	g_ptr_array_add (self->query_log, g_steal_pointer (&logged_query));

	/* Output either the results or the error. */
	g_assert ((output_results == NULL) != (output_error == NULL));

	if (output_error != NULL)
		g_propagate_error (error, g_steal_pointer (&output_error));

	return g_steal_pointer (&output_results);
}

static GList *
geocode_mock_backend_forward_search (GeocodeBackend  *backend,
                                     GHashTable      *params,
                                     GCancellable    *cancellable,
                                     GError         **error)
{
	GeocodeMockBackend *self = GEOCODE_MOCK_BACKEND (backend);

	return forward_or_reverse (self, self->forward_results,
	                           GEOCODE_ERROR_NO_MATCHES, params,
	                           cancellable, error);
}

static GList *
geocode_mock_backend_reverse_resolve (GeocodeBackend  *backend,
                                      GHashTable      *params,
                                      GCancellable    *cancellable,
                                      GError         **error)
{
	GeocodeMockBackend *self = GEOCODE_MOCK_BACKEND (backend);

	return forward_or_reverse (self, self->reverse_results,
	                           GEOCODE_ERROR_NOT_SUPPORTED,
	                           params, cancellable, error);
}

/******************************************************************************/

/**
 * geocode_mock_backend_new:
 *
 * Creates a new mock backend implementation with no initial forward or reverse
 * query results (so it will return an empty result set for all queries).
 *
 * Returns: (transfer full): a new #GeocodeMockBackend
 *
 * Since: 3.23.1
 */
GeocodeMockBackend *
geocode_mock_backend_new (void)
{
	return GEOCODE_MOCK_BACKEND (g_object_new (GEOCODE_TYPE_MOCK_BACKEND,
	                                           NULL));
}

/**
 * geocode_mock_backend_add_forward_result:
 * @self: a #GeocodeMockBackend
 * @params: (transfer none) (element-type utf8 GValue): query parameters to
 *     respond to, in the same format as accepted by geocode_forward_search()
 * @results: (transfer none) (nullable) (element-type GeocodePlace): result set
 *     to return for the query, or %NULL if @error is non-%NULL; result sets
 *     must be in the same format as returned by geocode_forward_search()
 * @error: (nullable): error to return for the query, or %NULL if @results
 *     should be returned instead; errors must match those returned by
 *     geocode_forward_search()
 *
 * Add a query and corresponding result (or error) to the mock backend, meaning
 * that if it receives a forward search for @params through
 * geocode_backend_forward_search() (or its asynchronous variants), the mock
 * backend will return the given @results or @error to the caller.
 *
 * If a set of @params is added to the backend multiple times, the most
 * recently provided @results and @error will be used.
 *
 * Exactly one of @results and @error must be set. Empty result sets are
 * represented as a %GEOCODE_ERROR_NO_MATCHES error.
 *
 * Since: 3.23.1
 */
void
geocode_mock_backend_add_forward_result (GeocodeMockBackend *self,
                                         GHashTable         *params,
                                         GList              *results,
                                         const GError       *error)
{
	g_autoptr (GeocodeMockBackendQuery) query = NULL;
	gsize idx;

	g_return_if_fail (GEOCODE_IS_MOCK_BACKEND (self));
	g_return_if_fail (params != NULL);
	g_return_if_fail (results == NULL || error == NULL);

	if (find_query (self->forward_results, params, &idx))
		g_ptr_array_remove_index_fast (self->forward_results, idx);

	query = geocode_mock_backend_query_new (params, TRUE, results, error);
	g_ptr_array_add (self->forward_results, g_steal_pointer (&query));
}

/**
 * geocode_mock_backend_add_reverse_result:
 * @self: a #GeocodeMockBackend
 * @params: (transfer none) (element-type utf8 GValue): query parameters to
 *     respond to, in the same format as accepted by geocode_reverse_resolve()
 * @results: (transfer none) (nullable) (element-type GeocodePlace): result set
 *     to return for the query, or %NULL if @error is non-%NULL; result sets
 *     must be in the same format as returned by geocode_reverse_resolve()
 * @error: (nullable): error to return for the query, or %NULL if @results
 *     should be returned instead; errors must match those returned by
 *     geocode_reverse_resolve()
 *
 * Add a query and corresponding result (or error) to the mock backend, meaning
 * that if it receives a reverse search for @params through
 * geocode_backend_reverse_resolve() (or its asynchronous variants), the mock
 * backend will return the given @results or @error to the caller.
 *
 * If a set of @params is added to the backend multiple times, the most
 * recently provided @results and @error will be used.
 *
 * Exactly one of @results and @error must be set. Empty result sets are
 * represented as a %GEOCODE_ERROR_NOT_SUPPORTED error.
 *
 * Since: 3.23.1
 */
void
geocode_mock_backend_add_reverse_result (GeocodeMockBackend *self,
                                         GHashTable         *params,
                                         GList              *results,
                                         const GError       *error)
{
	g_autoptr (GeocodeMockBackendQuery) query = NULL;
	gsize idx;

	g_return_if_fail (GEOCODE_IS_MOCK_BACKEND (self));
	g_return_if_fail (params != NULL);
	g_return_if_fail (results == NULL || error == NULL);

	if (find_query (self->reverse_results, params, &idx))
		g_ptr_array_remove_index_fast (self->reverse_results, idx);

	query = geocode_mock_backend_query_new (params, FALSE, results, error);
	g_ptr_array_add (self->reverse_results, g_steal_pointer (&query));
}

/**
 * geocode_mock_backend_clear:
 * @self: a #GeocodeMockBackend
 *
 * Clear the set of stored results in the mock backend which have been added
 * using geocode_mock_backend_add_forward_result() and
 * geocode_mock_backend_add_reverse_result(). Additionally, clear the query log
 * so far (see geocode_mock_backend_get_query_log()).
 *
 * This effectively resets the mock backend to its initial state.
 *
 * Since: 3.23.1
 */
void
geocode_mock_backend_clear (GeocodeMockBackend *self)
{
	g_return_if_fail (GEOCODE_MOCK_BACKEND (self));

	g_ptr_array_set_size (self->query_log, 0);
	g_ptr_array_set_size (self->forward_results, 0);
	g_ptr_array_set_size (self->reverse_results, 0);
}

/**
 * geocode_mock_backend_get_query_log:
 * @self: a #GeocodeMockBackend
 *
 * Get the details of the forward and reverse queries which have been requested
 * of the mock backend since the most recent call to
 * geocode_mock_backend_clear(). The query details are provided as
 * #GeocodeMockBackendQuery structures, which map the query parameters to
 * either the result set or the error which geocode_backend_forward_search()
 * or geocode_backend_reverse_resolve() (or their asynchronous variants)
 * returned to the caller.
 *
 * The results are provided in the order in which calls were made to
 * geocode_backend_forward_search() and geocode_backend_reverse_resolve().
 * Results for forward and reverse queries may be interleaved.
 *
 * Returns: (transfer none) (element-type GeocodeMockBackendQuery): potentially
 *     empty sequence of forward and reverse query details
 * Since: 3.23.1
 */
GPtrArray *
geocode_mock_backend_get_query_log (GeocodeMockBackend *self)
{
	g_return_val_if_fail (GEOCODE_IS_MOCK_BACKEND (self), NULL);

	return self->query_log;
}

static void
geocode_mock_backend_init (GeocodeMockBackend *self)
{
	self->query_log =
	    g_ptr_array_new_with_free_func ((GDestroyNotify) geocode_mock_backend_query_free);
	self->forward_results =
	    g_ptr_array_new_with_free_func ((GDestroyNotify) geocode_mock_backend_query_free);
	self->reverse_results =
	    g_ptr_array_new_with_free_func ((GDestroyNotify) geocode_mock_backend_query_free);
}

static void
geocode_mock_backend_finalize (GObject *object)
{
	GeocodeMockBackend *self = GEOCODE_MOCK_BACKEND (object);

	g_clear_pointer (&self->forward_results, g_ptr_array_unref);
	g_clear_pointer (&self->reverse_results, g_ptr_array_unref);

	G_OBJECT_CLASS (geocode_mock_backend_parent_class)->finalize (object);
}

static void
geocode_backend_iface_init (GeocodeBackendInterface *iface)
{
	/* We use the default implementation of the asynchronous methods, which
	 * runs the synchronous version in a thread. */
	iface->forward_search = geocode_mock_backend_forward_search;
	iface->reverse_resolve = geocode_mock_backend_reverse_resolve;
}

static void
geocode_mock_backend_class_init (GeocodeMockBackendClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->finalize = geocode_mock_backend_finalize;
}
