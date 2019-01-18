/*
   Copyright 2011 Bastien Nocera
   Copyright 2016 Collabora Ltd.

   The Gnome Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   The Gnome Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with the Gnome Library; see the file COPYING.LIB.  If not,
   write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301  USA.

   Authors: Bastien Nocera <hadess@hadess.net>
            Philip Withnall <philip.withnall@collabora.co.uk>
 */

#include <string.h>
#include <stdlib.h>
#include <locale.h>
#include <gio/gio.h>
#include <geocode-glib/geocode-backend.h>
#include <geocode-glib/geocode-forward.h>
#include <geocode-glib/geocode-bounding-box.h>
#include <geocode-glib/geocode-error.h>
#include <geocode-glib/geocode-glib-private.h>
#include <geocode-glib/geocode-nominatim.h>

/**
 * SECTION:geocode-forward
 * @short_description: Geocode forward geocoding object
 * @include: geocode-glib/geocode-glib.h
 *
 * Contains functions for geocoding using the
 * <ulink url="http://wiki.openstreetmap.org/wiki/Nominatim">OSM Nominatim APIs</ulink>
 **/

struct _GeocodeForwardPrivate {
	GHashTable *ht;
	guint       answer_count;
	GeocodeBoundingBox *search_area;
	gboolean bounded;

	GeocodeBackend  *backend;
};

enum {
        PROP_0,

        PROP_ANSWER_COUNT,
        PROP_SEARCH_AREA,
        PROP_BOUNDED
};

G_DEFINE_TYPE (GeocodeForward, geocode_forward, G_TYPE_OBJECT)

static void
geocode_forward_get_property (GObject	 *object,
			      guint	  property_id,
			      GValue	 *value,
			      GParamSpec *pspec)
{
	GeocodeForward *forward = GEOCODE_FORWARD (object);

	switch (property_id) {
		case PROP_ANSWER_COUNT:
			g_value_set_uint (value,
					  geocode_forward_get_answer_count (forward));
			break;

		case PROP_SEARCH_AREA:
			g_value_set_object (value,
					    geocode_forward_get_search_area (forward));
			break;

		case PROP_BOUNDED:
			g_value_set_boolean (value,
					     geocode_forward_get_bounded (forward));
			break;

		default:
			/* We don't have any other property... */
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
			break;
	}
}

static void
geocode_forward_set_property(GObject	   *object,
			     guint	    property_id,
			     const GValue *value,
			     GParamSpec   *pspec)
{
	GeocodeForward *forward = GEOCODE_FORWARD (object);

	switch (property_id) {
		case PROP_ANSWER_COUNT:
			geocode_forward_set_answer_count (forward,
							  g_value_get_uint (value));
			break;

		case PROP_SEARCH_AREA:
			geocode_forward_set_search_area (forward,
							 g_value_get_object (value));
			break;

		case PROP_BOUNDED:
			geocode_forward_set_bounded (forward,
						     g_value_get_boolean (value));
			break;

		default:
			/* We don't have any other property... */
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
			break;
	}
}

static void
geocode_forward_finalize (GObject *gforward)
{
	GeocodeForward *forward = (GeocodeForward *) gforward;

	g_clear_pointer (&forward->priv->ht, g_hash_table_unref);
	g_clear_object (&forward->priv->backend);

	G_OBJECT_CLASS (geocode_forward_parent_class)->finalize (gforward);
}

static void
geocode_forward_class_init (GeocodeForwardClass *klass)
{
	GObjectClass *gforward_class = G_OBJECT_CLASS (klass);
	GParamSpec *pspec;

	gforward_class->finalize = geocode_forward_finalize;
	gforward_class->get_property = geocode_forward_get_property;
	gforward_class->set_property = geocode_forward_set_property;


	g_type_class_add_private (klass, sizeof (GeocodeForwardPrivate));

	/**
	* GeocodeForward:answer-count:
	*
	* The number of requested results to a search query.
	*/
	pspec = g_param_spec_uint ("answer-count",
				   "Answer count",
				   "The number of requested results",
				   0,
				   G_MAXINT,
				   DEFAULT_ANSWER_COUNT,
				   G_PARAM_READWRITE |
				   G_PARAM_STATIC_STRINGS);
	g_object_class_install_property (gforward_class, PROP_ANSWER_COUNT, pspec);

	/**
	* GeocodeForward:search-area:
	*
	* The bounding box that limits the search area.
	* If #GeocodeForward:bounded property is set to #TRUE only results from
	* this area is returned.
	*/
	pspec = g_param_spec_object ("search-area",
				     "Search area",
				     "The area to limit search within",
				     GEOCODE_TYPE_BOUNDING_BOX,
				     G_PARAM_READWRITE |
				     G_PARAM_STATIC_STRINGS);
	g_object_class_install_property (gforward_class, PROP_SEARCH_AREA, pspec);

	/**
	* GeocodeForward:bounded:
	*
	* If set to #TRUE then only results in the #GeocodeForward:search-area
	* bounding box are returned.
	* If set to #FALSE the #GeocodeForward:search-area is treated like a
	* preferred area for results.
	*/
	pspec = g_param_spec_boolean ("bounded",
				      "Bounded",
				      "Bind search results to search-area",
				      FALSE,
				      G_PARAM_READWRITE |
				      G_PARAM_STATIC_STRINGS);
	g_object_class_install_property (gforward_class, PROP_BOUNDED, pspec);
}

static void
free_value (GValue *value)
{
	g_value_unset (value);
	g_free (value);
}

static void
geocode_forward_init (GeocodeForward *forward)
{
	forward->priv = G_TYPE_INSTANCE_GET_PRIVATE ((forward), GEOCODE_TYPE_FORWARD, GeocodeForwardPrivate);
	forward->priv->ht = g_hash_table_new_full (g_str_hash, g_str_equal,
	                                           g_free,
	                                           (GDestroyNotify) free_value);
	forward->priv->answer_count = DEFAULT_ANSWER_COUNT;
	forward->priv->search_area = NULL;
	forward->priv->bounded = FALSE;
}

static void
ensure_backend (GeocodeForward *object)
{
	/* If no backend is specified, default to the GNOME Nominatim backend */
	if (object->priv->backend == NULL)
		object->priv->backend = GEOCODE_BACKEND (geocode_nominatim_get_gnome ());
}

/**
 * geocode_forward_new_for_params:
 * @params: (transfer none) (element-type utf8 GValue): a #GHashTable with string keys, and #GValue values.
 *
 * Creates a new #GeocodeForward to perform geocoding with. The
 * #GHashTable is in the format used by Telepathy, and documented
 * on <ulink url="http://telepathy.freedesktop.org/spec/Connection_Interface_Location.html#Mapping:Location">Telepathy's specification site</ulink>.
 *
 * See also: <ulink url="http://xmpp.org/extensions/xep-0080.html">XEP-0080 specification</ulink>.
 *
 * Returns: a new #GeocodeForward. Use g_object_unref() when done.
 **/
GeocodeForward *
geocode_forward_new_for_params (GHashTable *params)
{
	GeocodeForward *forward;
	GHashTableIter iter;
	const gchar *key;
	const GValue *value;

	g_return_val_if_fail (params != NULL, NULL);

	if (g_hash_table_lookup (params, "lat") != NULL &&
	    g_hash_table_lookup (params, "long") != NULL) {
		g_warning ("You already have longitude and latitude in those parameters");
	}

	forward = g_object_new (GEOCODE_TYPE_FORWARD, NULL);

	g_hash_table_iter_init (&iter, params);

	while (g_hash_table_iter_next (&iter, (gpointer *) &key, (gpointer *) &value)) {
		GValue *value_copy = g_new0 (GValue, 1);
		g_value_init (value_copy, G_VALUE_TYPE (value));
		g_value_copy (value, value_copy);
		g_hash_table_insert (forward->priv->ht, g_strdup (key), value_copy);
	}

	return forward;
}

/**
 * geocode_forward_new_for_string:
 * @str: a string containing a free-form description of the location
 *
 * Creates a new #GeocodeForward to perform forward geocoding with. The
 * string is in free-form format.
 *
 * Returns: a new #GeocodeForward. Use g_object_unref() when done.
 **/
GeocodeForward *
geocode_forward_new_for_string (const char *location)
{
	GeocodeForward *forward;
	GValue *location_value;

	g_return_val_if_fail (location != NULL, NULL);

	forward = g_object_new (GEOCODE_TYPE_FORWARD, NULL);

	location_value = g_new0 (GValue, 1);
	g_value_init (location_value, G_TYPE_STRING);
	g_value_set_string (location_value, location);
	g_hash_table_insert (forward->priv->ht, g_strdup ("location"),
	                     location_value);

	return forward;
}

static void
backend_forward_search_ready (GeocodeBackend *backend,
                              GAsyncResult   *res,
                              GTask          *task)
{
	GList *places;  /* (element-type GeocodePlace) */
	GError *error = NULL;

	places = geocode_backend_forward_search_finish (backend, res, &error);
	if (places != NULL)
		g_task_return_pointer (task, places, (GDestroyNotify) g_list_free);
	else
		g_task_return_error (task, error);
	g_object_unref (task);
}

/**
 * geocode_forward_search_async:
 * @forward: a #GeocodeForward representing a query
 * @cancellable: optional #GCancellable forward, %NULL to ignore.
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: the data to pass to callback function
 *
 * Asynchronously performs a forward geocoding
 * query using a web service. Use geocode_forward_search() to do the same
 * thing synchronously.
 *
 * When the operation is finished, @callback will be called. You can then call
 * geocode_forward_search_finish() to get the result of the operation.
 **/
void
geocode_forward_search_async (GeocodeForward      *forward,
			      GCancellable        *cancellable,
			      GAsyncReadyCallback  callback,
			      gpointer             user_data)
{
	GTask *task;

	g_return_if_fail (GEOCODE_IS_FORWARD (forward));
	g_return_if_fail (cancellable == NULL || G_IS_CANCELLABLE (cancellable));

	ensure_backend (forward);
	g_assert (forward->priv->backend != NULL);

	task = g_task_new (forward, cancellable, callback, user_data);
	geocode_backend_forward_search_async (forward->priv->backend,
	                                      forward->priv->ht,
	                                      cancellable,
	                                      (GAsyncReadyCallback) backend_forward_search_ready,
	                                      g_object_ref (task));
	g_object_unref (task);
}

/**
 * geocode_forward_search_finish:
 * @forward: a #GeocodeForward representing a query
 * @res: a #GAsyncResult.
 * @error: a #GError.
 *
 * Finishes a forward geocoding operation. See geocode_forward_search_async().
 *
 * Returns: (element-type GeocodePlace) (transfer full): A list of
 * places or %NULL in case of errors. Free the returned instances with
 * g_object_unref() and the list with g_list_free() when done.
 **/
GList *
geocode_forward_search_finish (GeocodeForward       *forward,
			       GAsyncResult        *res,
			       GError             **error)
{
	g_return_val_if_fail (GEOCODE_IS_FORWARD (forward), NULL);
	g_return_val_if_fail (G_IS_ASYNC_RESULT (res), NULL);
	g_return_val_if_fail (error == NULL || *error == NULL, NULL);

	return g_task_propagate_pointer (G_TASK (res), error);
}

/**
 * geocode_forward_search:
 * @forward: a #GeocodeForward representing a query
 * @error: a #GError
 *
 * Gets the result of a forward geocoding
 * query using the current backend (see geocode_forward_set_backend()). By
 * default the GNOME Nominatim server is used. See #GeocodeBackend for more
 * information.
 *
 * If no results are found, a %GEOCODE_ERROR_NO_MATCHES error is returned.
 *
 * Returns: (element-type GeocodePlace) (transfer full): A list of
 * places or %NULL in case of errors. Free the returned instances with
 * g_object_unref() and the list with g_list_free() when done.
 **/
GList *
geocode_forward_search (GeocodeForward      *forward,
			GError             **error)
{
	g_return_val_if_fail (GEOCODE_IS_FORWARD (forward), NULL);
	g_return_val_if_fail (error == NULL || *error == NULL, NULL);

	ensure_backend (forward);
	g_assert (forward->priv->backend != NULL);

	return geocode_backend_forward_search (forward->priv->backend,
	                                       forward->priv->ht,
	                                       NULL,
	                                       error);
}

/**
 * geocode_forward_set_answer_count:
 * @forward: a #GeocodeForward representing a query
 * @count: the number of requested results, which must be greater than zero
 *
 * Sets the number of requested results to @count.
 **/
void
geocode_forward_set_answer_count (GeocodeForward *forward,
				  guint           count)
{
	GValue *count_value;

	g_return_if_fail (GEOCODE_IS_FORWARD (forward));
	g_return_if_fail (count > 0);

	forward->priv->answer_count = count;

	/* Note: This key name is not defined in the Telepathy specification or
	 * in XEP-0080; it is custom, but standard within Geocode. */
	count_value = g_new0 (GValue, 1);
	g_value_init (count_value, G_TYPE_UINT);
	g_value_set_uint (count_value, count);
	g_hash_table_insert (forward->priv->ht, g_strdup ("limit"),
	                     count_value);
}

/**
 * geocode_forward_set_search_area:
 * @forward: a #GeocodeForward representing a query
 * @box: a bounding box to limit the search area.
 *
 * Sets the area to limit searches within.
 **/
void
geocode_forward_set_search_area (GeocodeForward     *forward,
				 GeocodeBoundingBox *bbox)
{
	GValue *area_value;
	char *area;
	char top[G_ASCII_DTOSTR_BUF_SIZE];
	char left[G_ASCII_DTOSTR_BUF_SIZE];
	char bottom[G_ASCII_DTOSTR_BUF_SIZE];
	char right[G_ASCII_DTOSTR_BUF_SIZE];

	g_return_if_fail (GEOCODE_IS_FORWARD (forward));

	forward->priv->search_area = bbox;

	/* need to convert with g_ascii_dtostr to be locale safe */
	g_ascii_dtostr (top, G_ASCII_DTOSTR_BUF_SIZE,
	                geocode_bounding_box_get_top (bbox));

	g_ascii_dtostr (bottom, G_ASCII_DTOSTR_BUF_SIZE,
	                geocode_bounding_box_get_bottom (bbox));

	g_ascii_dtostr (left, G_ASCII_DTOSTR_BUF_SIZE,
	                geocode_bounding_box_get_left (bbox));

	g_ascii_dtostr (right, G_ASCII_DTOSTR_BUF_SIZE,
	                geocode_bounding_box_get_right (bbox));

	/* Note: This key name is not defined in the Telepathy specification or
	 * in XEP-0080; it is custom, but standard within Geocode. */
	area = g_strdup_printf ("%s,%s,%s,%s", left, top, right, bottom);
	area_value = g_new0 (GValue, 1);
	g_value_init (area_value, G_TYPE_STRING);
	g_value_take_string (area_value, area);
	g_hash_table_insert (forward->priv->ht, g_strdup ("viewbox"),
	                     area_value);
}

/**
 * geocode_forward_set_bounded:
 * @forward: a #GeocodeForward representing a query
 * @bounded: #TRUE to restrict results to only items contained within the
 * #GeocodeForward:search-area bounding box.
 *
 * Set the #GeocodeForward:bounded property that regulates whether the
 * #GeocodeForward:search-area property acts restricting or not.
 **/
void
geocode_forward_set_bounded (GeocodeForward *forward,
			     gboolean        bounded)
{
	GValue *bounded_value;

	g_return_if_fail (GEOCODE_IS_FORWARD (forward));

	forward->priv->bounded = bounded;

	/* Note: This key name is not defined in the Telepathy specification or
	 * in XEP-0080; it is custom, but standard within Geocode. */
	bounded_value = g_new0 (GValue, 1);
	g_value_init (bounded_value, G_TYPE_STRING);
	g_value_set_boolean (bounded_value, bounded);
	g_hash_table_insert (forward->priv->ht, g_strdup ("bounded"),
	                     bounded_value);
}

/**
 * geocode_forward_get_answer_count:
 * @forward: a #GeocodeForward representing a query
 *
 * Gets the number of requested results for searches.
 **/
guint
geocode_forward_get_answer_count (GeocodeForward *forward)
{
	g_return_val_if_fail (GEOCODE_IS_FORWARD (forward), 0);

	return forward->priv->answer_count;
}

/**
 * geocode_forward_get_search_area:
 * @forward: a #GeocodeForward representing a query
 *
 * Gets the area to limit searches within.
 *
 * Returns: (transfer none) (nullable): the search area, or %NULL if none is set
 **/
GeocodeBoundingBox *
geocode_forward_get_search_area (GeocodeForward *forward)
{
	g_return_val_if_fail (GEOCODE_IS_FORWARD (forward), NULL);

	return forward->priv->search_area;
}

/**
 * geocode_forward_get_bounded:
 * @forward: a #GeocodeForward representing a query
 *
 * Gets the #GeocodeForward:bounded property that regulates whether the
 * #GeocodeForward:search-area property acts restricting or not.
 **/
gboolean
geocode_forward_get_bounded (GeocodeForward *forward)
{
	g_return_val_if_fail (GEOCODE_IS_FORWARD (forward), FALSE);

	return forward->priv->bounded;
}

/**
 * geocode_forward_set_backend:
 * @forward: a #GeocodeForward representing a query
 * @backend: (nullable) (transfer none): a #GeocodeBackend, or %NULL to use the
 *    default one.
 *
 * Specifies the backend to use in the forward geocoding operation.
 *
 * If none is given, the default GNOME Nominatim server is used.
 *
 * Since: 3.23.1
 */
void
geocode_forward_set_backend (GeocodeForward *forward,
                             GeocodeBackend *backend)
{
	g_return_if_fail (GEOCODE_IS_FORWARD (forward));
	g_return_if_fail (backend == NULL || GEOCODE_IS_BACKEND (backend));

	g_set_object (&forward->priv->backend, backend);
}
