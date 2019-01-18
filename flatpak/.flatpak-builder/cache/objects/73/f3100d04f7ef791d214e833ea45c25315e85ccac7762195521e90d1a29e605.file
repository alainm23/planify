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
 * Authors: Aleksander Morgado <aleksander.morgado@collabora.co.uk>
 *          Philip Withnall <philip.withnall@collabora.co.uk>
 */

#include <glib.h>
#include <libsoup/soup.h>

#include "geocode-glib/geocode-glib.h"
#include "geocode-nominatim-test.h"

struct _GeocodeNominatimTest {
	GeocodeNominatim parent;
	GList *cache;
};

G_DEFINE_TYPE (GeocodeNominatimTest, geocode_nominatim_test, GEOCODE_TYPE_NOMINATIM)

/******************************************************************************/

typedef struct {
	GHashTable *ht;
	gchar      *response;
} CacheItem;

static void
cache_item_free (CacheItem *item)
{
	g_hash_table_unref (item->ht);
	g_free (item->response);
	g_slice_free (CacheItem, item);
}

/* Finds the first item which satisfies the input arguments */
static CacheItem *
lookup_cache_item (GeocodeNominatimTest *self,
                   GHashTable           *ht)
{
	GList *l;

	for (l = self->cache; l; l = g_list_next (l)) {
		CacheItem *item = l->data;
		gboolean found = TRUE;
		GHashTableIter iter;
		gpointer key, value, value2;

		if (g_hash_table_size (item->ht) != g_hash_table_size (ht))
			continue;

		g_hash_table_iter_init (&iter, ht);
		while (found && g_hash_table_iter_next (&iter, &key, &value)) {
			found = g_hash_table_lookup_extended (item->ht, key,
			                                      NULL, (gpointer *) &value2);

			if (!found)
				continue;

			g_debug ("%s: comparing %s, %s", G_STRFUNC,
			         (const gchar *) value,
			         (const gchar *) value2);

			found = g_str_equal ((const gchar *) value,
			                     (const gchar *) value2);
		}

		if (!found)
			g_debug ("%s: failed to find %s = %s", G_STRFUNC,
			         (const gchar *) key, (const gchar *) value);

		if (found)
			return item;
	}

	return NULL;
}

/*
 * @self:
 * @ht: (element-type utf8 utf8) (transfer none):
 * @response:
 */
void
geocode_nominatim_test_expect_query (GeocodeNominatimTest *self,
                                     GHashTable           *ht,
                                     const char           *response)
{
	CacheItem *item;

	{
		GHashTableIter iter;
		gpointer key, value;

		g_hash_table_iter_init (&iter, ht);
		while (g_hash_table_iter_next (&iter, &key, &value)) {
			g_debug ("%s: %s = %s", G_STRFUNC, (const gchar *) key,
			         (const gchar *) value);
		}
	}

	item = g_slice_new (CacheItem);
	item->ht = g_hash_table_ref (ht);
	item->response = g_strdup (response);

	self->cache = g_list_prepend (self->cache, item);
}

/******************************************************************************/

static gchar *
common_get_response (GeocodeNominatim  *self,
                     const gchar       *uri,
                     GError           **error)
{
	CacheItem *item;
	SoupURI *parsed_uri = NULL;
	GHashTable *parameters = NULL;

	/* Parse the URI to get its query parameters. */
	parsed_uri = soup_uri_new (uri);
	g_assert_nonnull (parsed_uri);

	parameters = soup_form_decode (soup_uri_get_query (parsed_uri));
	soup_uri_free (parsed_uri);

	{
		GHashTableIter iter;
		gpointer key, value;

		g_hash_table_iter_init (&iter, parameters);
		while (g_hash_table_iter_next (&iter, &key, &value))
			g_debug ("%s: %s = %s", G_STRFUNC, (const gchar *) key, (const gchar *) value);
	}

	/* Drop keys which we don’t care about. */
	g_assert_true (g_hash_table_remove (parameters, "addressdetails"));
	g_assert_true (g_hash_table_remove (parameters, "email"));
	g_assert_true (g_hash_table_remove (parameters, "format"));
	g_assert_true (g_hash_table_remove (parameters, "accept-language"));

	/* Find the item in the cache. */
	item = lookup_cache_item (GEOCODE_NOMINATIM_TEST (self), parameters);
	g_hash_table_unref (parameters);

	if (!item) {
		g_set_error (error,
		             G_IO_ERROR,
		             G_IO_ERROR_NOT_FOUND,
		             "Location not found");
		return NULL;
	}

	return g_strdup (item->response);
}

static gchar *
real_query_finish (GeocodeNominatim  *self,
                   GAsyncResult      *res,
                   GError           **error)
{
	return g_task_propagate_pointer (G_TASK (res), error);
}

static void
real_query_async (GeocodeNominatim    *self,
                  const gchar         *uri,
                  GCancellable        *cancellable,
                  GAsyncReadyCallback  callback,
                  gpointer             user_data)
{
	GTask *task;
	gchar *response;
	GError *error = NULL;

	task = g_task_new (self, cancellable, callback, user_data);

	response = common_get_response (self, uri, &error);
	if (response == NULL)
		g_task_return_error (task, error);
	else
		g_task_return_pointer (task, response, g_free);
	g_object_unref (task);
}

static gchar *
real_query (GeocodeNominatim  *self,
            const gchar       *uri,
            GCancellable      *cancellable,
            GError           **error)
{
	return common_get_response (self, uri, error);
}

/******************************************************************************/

GeocodeNominatim *
geocode_nominatim_test_new (void)
{
	/* This shouldn’t be used with the user’s normal cache directory, or we
	 * will pollute it. */
	g_assert (g_str_has_prefix (g_get_user_cache_dir (), g_get_tmp_dir ()));

	return GEOCODE_NOMINATIM (g_object_new (GEOCODE_TYPE_NOMINATIM_TEST,
	                                        "base-url", "http://example.invalid",
	                                        "maintainer-email-address", "maintainer@invalid",
	                                        NULL));
}

static void
geocode_nominatim_test_init (GeocodeNominatimTest *object)
{
}

static void
geocode_nominatim_test_finalize (GObject *object)
{
	GeocodeNominatimTest *self;

	self = GEOCODE_NOMINATIM_TEST (object);

	g_list_free_full (self->cache, (GDestroyNotify) cache_item_free);

	G_OBJECT_CLASS (geocode_nominatim_test_parent_class)->finalize (object);
}

static void
geocode_nominatim_test_class_init (GeocodeNominatimTestClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	GeocodeNominatimClass *nominatim_class = GEOCODE_NOMINATIM_CLASS (klass);

	object_class->finalize = geocode_nominatim_test_finalize;

	nominatim_class->query        = real_query;
	nominatim_class->query_async  = real_query_async;
	nominatim_class->query_finish = real_query_finish;
}
