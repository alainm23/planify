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

#ifndef GEOCODE_BACKEND_H
#define GEOCODE_BACKEND_H

#include <glib.h>
#include <gio/gio.h>

#include "geocode-place.h"

G_BEGIN_DECLS

/**
 * GeocodeBackend:
 *
 * All the fields in the #GeocodeBackend structure are private and should
 * never be accessed directly.
 *
 * Since: 3.23.1
 */
#define GEOCODE_TYPE_BACKEND (geocode_backend_get_type ())
G_DECLARE_INTERFACE (GeocodeBackend, geocode_backend, GEOCODE, BACKEND, GObject)

/**
 * GEOCODE_TYPE_BACKEND:
 *
 * See #GeocodeBackend.
 *
 * Since: 3.23.1
 */

/**
 * GeocodeBackendInterface:
 * @forward_search: handles a synchronous forward geocoding request.
 * @forward_search_async: starts an asynchronous forward geocoding request.
 * @forward_search_finish: finishes an asynchronous forward geocoding request.
 * @reverse_resolve: handles a synchronous reverse geocoding request.
 * @reverse_resolve_async: starts an asynchronous reverse geocoding request.
 * @reverse_resolve_finish: finishes an asynchronous reverse geocoding request.
 *
 * Interface which defines the basic operations for geocoding.
 *
 * Since: 3.23.1
 */
struct _GeocodeBackendInterface
{
	/*< private >*/
	GTypeInterface g_iface;

	/*< public >*/

	/* Forward */
	GList        *(*forward_search)          (GeocodeBackend       *backend,
	                                          GHashTable           *params,
	                                          GCancellable         *cancellable,
	                                          GError              **error);
	void          (*forward_search_async)    (GeocodeBackend       *backend,
	                                          GHashTable           *params,
	                                          GCancellable         *cancellable,
	                                          GAsyncReadyCallback   callback,
	                                          gpointer              user_data);
	GList        *(*forward_search_finish)   (GeocodeBackend       *backend,
	                                          GAsyncResult         *result,
	                                          GError              **error);

	/* Reverse */
	GList        *(*reverse_resolve)         (GeocodeBackend       *backend,
	                                          GHashTable           *params,
	                                          GCancellable         *cancellable,
	                                          GError              **error);
	void          (*reverse_resolve_async)   (GeocodeBackend       *backend,
	                                          GHashTable           *params,
	                                          GCancellable         *cancellable,
	                                          GAsyncReadyCallback   callback,
	                                          gpointer              user_data);
	GList        *(*reverse_resolve_finish)  (GeocodeBackend       *backend,
	                                          GAsyncResult         *result,
	                                          GError              **error);

	/*< private >*/
	gpointer padding[4];
};

/* Forward geocoding operations */
void          geocode_backend_forward_search_async   (GeocodeBackend      *backend,
                                                      GHashTable          *params,
                                                      GCancellable        *cancellable,
                                                      GAsyncReadyCallback  callback,
                                                      gpointer             user_data);
GList        *geocode_backend_forward_search_finish  (GeocodeBackend      *backend,
                                                      GAsyncResult        *result,
                                                      GError             **error);
GList        *geocode_backend_forward_search         (GeocodeBackend      *backend,
                                                      GHashTable          *params,
                                                      GCancellable        *cancellable,
                                                      GError             **error);

/* Reverse geocoding operations */
void          geocode_backend_reverse_resolve_async  (GeocodeBackend       *backend,
                                                      GHashTable           *params,
                                                      GCancellable         *cancellable,
                                                      GAsyncReadyCallback   callback,
                                                      gpointer              user_data);
GList        *geocode_backend_reverse_resolve_finish (GeocodeBackend       *backend,
                                                      GAsyncResult         *result,
                                                      GError              **error);
GList        *geocode_backend_reverse_resolve        (GeocodeBackend       *backend,
                                                      GHashTable           *params,
                                                      GCancellable         *cancellable,
                                                      GError              **error);

G_END_DECLS

#endif /* GEOCODE_BACKEND_H */
