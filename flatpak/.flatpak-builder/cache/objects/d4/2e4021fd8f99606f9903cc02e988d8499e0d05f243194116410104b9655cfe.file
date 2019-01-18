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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with the Gnome Library; see the file COPYING.LIB.  If not,
 * write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301  USA.
 *
 * Authors:
 *     Aleksander Morgado <aleksander.morgado@collabora.co.uk>
 *     Philip Withnall <philip.withnall@collabora.co.uk>
 */

#include "geocode-backend.h"

/**
 * SECTION:geocode-backend
 * @short_description: Geocode backend object
 * @include: geocode-glib/geocode-glib.h
 *
 * The #GeocodeBackend interface defines the operations that a resolver
 * service must implement.
 *
 * geocode-glib supports multiple backends which provide the underlying
 * geocoding database and functionality. By default, the #GeocodeNominatim
 * backend is used with
 * [GNOME’s Nominatim server](https://nominatim.gnome.org/). If you are using
 * geocode-glib in some GNOME software, this is the correct backend to use.
 * Otherwise, you should use a new #GeocodeNominatim instance with your own
 * Nominatim server, or a custom #GeocodeBackend implementation to use geocoding
 * data from a non-Nominatim service. In all cases, please respect the terms of
 * use of the service you are using.
 *
 * If you are writing a library which uses geocode-glib, consider exposing the
 * choice of #GeocodeBackend in your library API, so that applications can make
 * the best choice about which geocoding backend to use.
 *
 * Custom backends can be implemented by subclassing #GeocodeBackend and
 * implementing the synchronous `forward_search` and `reverse_resolve` methods.
 * The asynchronous versions may be implemented as well; the default
 * implementations run the synchronous version in a thread.
 *
 * In order to use a custom backend, either instantiate the backend directly
 * and do forward and reverse queries on it using the #GeocodeBackend interface;
 * or create #GeocodeForward and #GeocodeReverse objects as normal, and set
 * the backend they use with geocode_forward_set_backend() and
 * geocode_reverse_set_backend(). They default to using the GNOME Nominatim
 * backend.
 *
 * #GeocodeMockBackend is intended to be used in unit tests for applications
 * which use geocode-glib — it allows them to set the geocode results they
 * expect their application to query, and check afterwards that the queries
 * were performed. Additionally, it works offline, which allows application
 * unit tests to be run on integration and build machines which are not online.
 * It is not expected that #GeocodeMockBackend will be used in production code.
 *
 * Since: 3.23.1
 */

G_DEFINE_INTERFACE (GeocodeBackend, geocode_backend, G_TYPE_OBJECT)

/**
 * geocode_backend_forward_search_async:
 * @backend: a #GeocodeBackend.
 * @params: (transfer none) (element-type utf8 GValue): a #GHashTable with string keys, and #GValue values.
 * @cancellable: optional #GCancellable, %NULL to ignore.
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: the data to pass to the @callback function
 *
 * Asynchronously performs a forward geocoding query using the @backend. Use
 * geocode_backend_forward_search() to do the same thing synchronously.
 *
 * The @params hash table is in the format used by Telepathy, and documented
 * in the [Telepathy specification](http://telepathy.freedesktop.org/spec/Connection_Interface_Location.html#Mapping:Location).
 *
 * See also: [XEP-0080 specification](http://xmpp.org/extensions/xep-0080.html).
 *
 * When the operation is finished, @callback will be called. You can then call
 * geocode_backend_forward_search_finish() to get the result of the operation.
 *
 * Since: 3.23.1
 */
void
geocode_backend_forward_search_async (GeocodeBackend      *backend,
                                      GHashTable          *params,
                                      GCancellable        *cancellable,
                                      GAsyncReadyCallback  callback,
                                      gpointer             user_data)
{
	GeocodeBackendInterface *iface;

	g_return_if_fail (GEOCODE_IS_BACKEND (backend));
	g_return_if_fail (cancellable == NULL || G_IS_CANCELLABLE (cancellable));

	iface = GEOCODE_BACKEND_GET_IFACE (backend);

	return iface->forward_search_async (backend, params, cancellable,
	                                    callback, user_data);
}

/**
 * geocode_backend_forward_search_finish:
 * @backend: a #GeocodeBackend.
 * @result: a #GAsyncResult.
 * @error: a #GError.
 *
 * Finishes a forward geocoding operation. See
 * geocode_backend_forward_search_async().
 *
 * Returns: (element-type GeocodePlace) (transfer full): A list of
 * places or %NULL in case of errors. Free the returned instances with
 * g_object_unref() and the list with g_list_free() when done.
 *
 * Since: 3.23.1
 */
GList *
geocode_backend_forward_search_finish (GeocodeBackend  *backend,
                                       GAsyncResult    *result,
                                       GError         **error)
{
	GeocodeBackendInterface *iface;

	g_return_val_if_fail (GEOCODE_IS_BACKEND (backend), NULL);
	g_return_val_if_fail (G_IS_ASYNC_RESULT (result), NULL);
	g_return_val_if_fail (error == NULL || *error == NULL, NULL);

	iface = GEOCODE_BACKEND_GET_IFACE (backend);

	return iface->forward_search_finish (backend, result, error);
}

/**
 * geocode_backend_forward_search:
 * @backend: a #GeocodeBackend.
 * @params: (transfer none) (element-type utf8 GValue): a #GHashTable with string keys, and #GValue values.
 * @cancellable: optional #GCancellable, %NULL to ignore.
 * @error: a #GError
 *
 * Gets the result of a forward geocoding query using the @backend.
 *
 * If no results are found, a %GEOCODE_ERROR_NO_MATCHES error is returned.
 *
 * This is a synchronous function, which means it may block on network requests.
 * In most situations, the asynchronous version
 * (geocode_backend_forward_search_async()) is more appropriate. See its
 * documentation for more information on usage.
 *
 * Returns: (element-type GeocodePlace) (transfer full): A list of
 * places or %NULL in case of errors. Free the returned instances with
 * g_object_unref() and the list with g_list_free() when done.
 *
 * Since: 3.23.1
 */
GList *
geocode_backend_forward_search (GeocodeBackend  *backend,
                                GHashTable      *params,
                                GCancellable    *cancellable,
                                GError         **error)
{
	GeocodeBackendInterface *iface;

	g_return_val_if_fail (GEOCODE_IS_BACKEND (backend), NULL);
	g_return_val_if_fail (error == NULL || *error == NULL, NULL);

	iface = GEOCODE_BACKEND_GET_IFACE (backend);

	return iface->forward_search (backend, params, cancellable, error);
}

/**
 * geocode_backend_reverse_resolve_async:
 * @backend: a #GeocodeBackend.
 * @params: (transfer none) (element-type utf8 GValue): a #GHashTable with string keys, and #GValue values.
 * @cancellable: optional #GCancellable object, %NULL to ignore.
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied.
 * @user_data: the data to pass to callback function.
 *
 * Asynchronously gets the result of a reverse geocoding query using the
 * backend.
 *
 * Typically, a single result will be returned representing the place at a
 * given latitude and longitude (the `lat` and `lon` keys to @params); but in
 * some cases the results will be ambiguous and *multiple* results will be
 * returned. They will be returned in order of relevance, with the most
 * relevant result first in the list.
 *
 * The @params hash table is in the format used by Telepathy, and documented
 * in the [Telepathy specification](http://telepathy.freedesktop.org/spec/Connection_Interface_Location.html#Mapping:Location).
 *
 * See also: [XEP-0080 specification](http://xmpp.org/extensions/xep-0080.html).
 *
 * Use geocode_backend_reverse_resolve() to do the same thing synchronously.
 *
 * When the operation is finished, @callback will be called. You can then call
 * geocode_backend_reverse_resolve_finish() to get the result of the operation.
 *
 * Since: 3.23.1
 */
void
geocode_backend_reverse_resolve_async (GeocodeBackend      *backend,
                                       GHashTable          *params,
                                       GCancellable        *cancellable,
                                       GAsyncReadyCallback  callback,
                                       gpointer             user_data)
{
	GeocodeBackendInterface *iface;

	g_return_if_fail (GEOCODE_IS_BACKEND (backend));
	g_return_if_fail (params != NULL);
	g_return_if_fail (cancellable == NULL || G_IS_CANCELLABLE (cancellable));

	iface = GEOCODE_BACKEND_GET_IFACE (backend);

	return (* iface->reverse_resolve_async) (backend, params,
	                                         cancellable, callback, user_data);
}

/**
 * geocode_backend_reverse_resolve_finish:
 * @backend: a #GeocodeBackend.
 * @result: a #GAsyncResult.
 * @error: a #GError.
 *
 * Finishes a reverse geocoding operation. See geocode_backend_reverse_resolve_async().
 *
 * Returns: (transfer full) (element-type GeocodePlace): A list of
 *    #GeocodePlace instances, or %NULL in case of errors. The list is ordered
 *    by relevance, with most relevant results first. Free the returned
 *    instances with g_object_unref() and the list with g_list_free() when done.
 *
 * Since: 3.23.1
 **/
GList *
geocode_backend_reverse_resolve_finish (GeocodeBackend  *backend,
                                        GAsyncResult    *result,
                                        GError         **error)
{
	GeocodeBackendInterface *iface;

	g_return_val_if_fail (GEOCODE_IS_BACKEND (backend), NULL);
	g_return_val_if_fail (G_IS_ASYNC_RESULT (result), NULL);
	g_return_val_if_fail (error == NULL || *error == NULL, NULL);

	iface = GEOCODE_BACKEND_GET_IFACE (backend);

	return (* iface->reverse_resolve_finish) (backend, result, error);
}

/**
 * geocode_backend_reverse_resolve:
 * @backend: a #GeocodeBackend.
 * @params: (transfer none) (element-type utf8 GValue): a #GHashTable with string keys, and #GValue values.
 * @cancellable: optional #GCancellable object, %NULL to ignore.
 * @error: a #GError.
 *
 * Gets the result of a reverse geocoding query using the @backend.
 *
 * If no result could be found, a %GEOCODE_ERROR_NOT_SUPPORTED error will be
 * returned. This typically happens if the coordinates to geocode are in the
 * middle of the ocean.
 *
 * This is a synchronous function, which means it may block on network requests.
 * In most situations, the asynchronous version,
 * geocode_backend_forward_search_async(), is more appropriate. See its
 * documentation for more information on usage.
 *
 * Returns: (transfer full) (element-type GeocodePlace): A list of
 *    #GeocodePlace instances, or %NULL in case of errors. The list is ordered
 *    by relevance, with most relevant results first. Free the returned
 *    instances with g_object_unref() and the list with g_list_free() when done.
 *
 * Since: 3.23.1
 */
GList *
geocode_backend_reverse_resolve (GeocodeBackend   *backend,
                                 GHashTable       *params,
                                 GCancellable     *cancellable,
                                 GError          **error)
{
	GeocodeBackendInterface *iface;

	g_return_val_if_fail (GEOCODE_IS_BACKEND (backend), NULL);
	g_return_val_if_fail (params != NULL, NULL);
	g_return_val_if_fail (cancellable == NULL || G_IS_CANCELLABLE (cancellable), NULL);
	g_return_val_if_fail (error == NULL || *error == NULL, NULL);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return NULL;

	iface = GEOCODE_BACKEND_GET_IFACE (backend);

	if (iface->reverse_resolve == NULL) {
		g_set_error_literal (error, G_IO_ERROR,
		                     G_IO_ERROR_NOT_SUPPORTED,
		                     "Operation not supported");
		return NULL;
	}

	return (* iface->reverse_resolve) (backend, params,
	                                   cancellable, error);
}

/* Free a GList of GeocodePlace objects. */
static void
places_list_free (GList *places)
{
	g_list_free_full (places, g_object_unref);
}

static void
forward_search_async_thread (GTask           *task,
                             GeocodeBackend  *backend,
                             GHashTable      *params,
                             GCancellable    *cancellable)
{
	GError *error = NULL;
	GList *places;

	places = geocode_backend_forward_search (backend, params,
	                                         cancellable, &error);
	if (error)
		g_task_return_error (task, error);
	else
		g_task_return_pointer (task, places, (GDestroyNotify) places_list_free);
}

static void
real_forward_search_async (GeocodeBackend       *backend,
                           GHashTable           *params,
                           GCancellable         *cancellable,
                           GAsyncReadyCallback   callback,
                           gpointer              user_data)
{
	GTask *task;

	task = g_task_new (backend, cancellable, callback, user_data);
	g_task_set_task_data (task, g_hash_table_ref (params),
	                      (GDestroyNotify) g_hash_table_unref);
	g_task_run_in_thread (task, (GTaskThreadFunc) forward_search_async_thread);
	g_object_unref (task);
}

static GList *
real_forward_search_finish (GeocodeBackend  *backend,
                            GAsyncResult    *result,
                            GError         **error)
{
	return g_task_propagate_pointer (G_TASK (result), error);
}

static void
reverse_resolve_async_thread (GTask           *task,
                              GeocodeBackend  *backend,
                              GHashTable      *params,
                              GCancellable    *cancellable)
{
	GError *error = NULL;
	GList *places;  /* (element-type GeocodePlace) */

	places = geocode_backend_reverse_resolve (backend, params,
	                                          cancellable, &error);
	if (error)
		g_task_return_error (task, error);
	else
		g_task_return_pointer (task, places,
		                       (GDestroyNotify) places_list_free);
}

static void
real_reverse_resolve_async (GeocodeBackend      *backend,
                            GHashTable          *params,
                            GCancellable        *cancellable,
                            GAsyncReadyCallback  callback,
                            gpointer             user_data)
{
	GTask *task;

	task = g_task_new (backend, cancellable, callback, user_data);
	g_task_set_task_data (task, g_hash_table_ref (params),
	                      (GDestroyNotify) g_hash_table_unref);
	g_task_run_in_thread (task, (GTaskThreadFunc) reverse_resolve_async_thread);
	g_object_unref (task);
}

static GList *
real_reverse_resolve_finish (GeocodeBackend  *backend,
                             GAsyncResult    *result,
                             GError         **error)
{
	return g_task_propagate_pointer (G_TASK (result), error);
}

static void
geocode_backend_default_init (GeocodeBackendInterface *iface)
{
	iface->forward_search_async  = real_forward_search_async;
	iface->forward_search_finish = real_forward_search_finish;
	iface->reverse_resolve_async  = real_reverse_resolve_async;
	iface->reverse_resolve_finish = real_reverse_resolve_finish;
}
