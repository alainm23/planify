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

#ifndef GEOCODE_MOCK_BACKEND_H
#define GEOCODE_MOCK_BACKEND_H

#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS

/**
 * GeocodeMockBackend:
 *
 * All the fields in the #GeocodeMockBackend structure are private and should
 * never be accessed directly.
 *
 * Since: 3.23.1
 */
#define GEOCODE_TYPE_MOCK_BACKEND (geocode_mock_backend_get_type ())
G_DECLARE_FINAL_TYPE (GeocodeMockBackend, geocode_mock_backend,
                      GEOCODE, MOCK_BACKEND, GObject)

/**
 * GEOCODE_TYPE_MOCK_BACKEND:
 *
 * See #GeocodeMockBackend.
 *
 * Since: 3.23.1
 */

GeocodeMockBackend *geocode_mock_backend_new (void);

void geocode_mock_backend_add_forward_result (GeocodeMockBackend *self,
                                              GHashTable         *params,
                                              GList              *results,
                                              const GError       *error);
void geocode_mock_backend_add_reverse_result (GeocodeMockBackend *self,
                                              GHashTable         *params,
                                              GList              *results,
                                              const GError       *error);

void geocode_mock_backend_clear              (GeocodeMockBackend *self);

/**
 * GeocodeMockBackendQuery:
 * @params: query parameters, in the format accepted by geocode_forward_search()
 *     (if @is_forward is %TRUE) or geocode_reverse_resolve() (otherwise)
 * @is_forward: %TRUE if this represents a call to geocode_forward_search();
 *     %FALSE if it represents a call to geocode_reverse_resolve()
 * @results: (nullable) (element-type GeocodePlace): results returned by the
 *     query, or %NULL if an error was returned
 * @error: (nullable): error returned by the query, or %NULL if a result set
 *     was returned
 *
 * The details of a forward or reverse query which was performed on a
 * #GeocodeMockBackend by application code. This includes the input (@params,
 * @is_forward), and the output which was returned (@results or @error).
 *
 * Empty result sets are represented by the %GEOCODE_ERROR_NO_MATCHES error
 * (for forward queries) or the %GEOCODE_ERROR_NOT_SUPPORTED error (for reverse
 * queries), rather than an empty @results list.
 *
 * Since: 3.23.1
 */
typedef struct {
	/* Request */
	GHashTable *params;
	gboolean is_forward;

	/* Response */
	GList *results;
	GError *error;
} GeocodeMockBackendQuery;

GPtrArray *geocode_mock_backend_get_query_log (GeocodeMockBackend *self);

G_END_DECLS

#endif /* GEOCODE_MOCK_BACKEND_H */
