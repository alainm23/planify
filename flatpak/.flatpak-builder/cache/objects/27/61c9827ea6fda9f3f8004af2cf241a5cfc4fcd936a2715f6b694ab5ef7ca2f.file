/*
 * Copyright (C) 2009 Pierre-Luc Beaudoin <pierre-luc@pierlux.com>
 * Copyright (C) 2010-2013 Jiri Techet <techet@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/**
 * SECTION:champlain-map-source-factory
 * @short_description: Manages #ChamplainMapSource instances
 *
 * This factory manages the create of #ChamplainMapSource. It contains names
 * and constructor functions for each available map sources in libchamplain.
 * You can add your own with #champlain_map_source_factory_register.
 *
 * To get the wanted map source, use #champlain_map_source_factory_create. It
 * will return a ready to use #ChamplainMapSource.
 *
 * To get the list of registered map sources, use
 * #champlain_map_source_factory_get_registered.
 *
 */
#include "config.h"

#include "champlain-map-source-factory.h"

#define DEBUG_FLAG CHAMPLAIN_DEBUG_NETWORK
#include "champlain-debug.h"

#include "champlain.h"
#ifdef CHAMPLAIN_HAS_MEMPHIS
#include "champlain-memphis-renderer.h"
#endif
#include "champlain-file-cache.h"
#include "champlain-defines.h"
#include "champlain-enum-types.h"
#include "champlain-map-source.h"
#include "champlain-marshal.h"
#include "champlain-private.h"
#include "champlain-network-tile-source.h"
#include "champlain-map-source-chain.h"
#include "champlain-error-tile-renderer.h"
#include "champlain-image-renderer.h"
#include "champlain-file-tile-source.h"

#include <glib.h>
#include <string.h>

enum
{
  /* normal signals */
  LAST_SIGNAL
};

enum
{
  PROP_0,
};

/* static guint champlain_map_source_factory_signals[LAST_SIGNAL] = { 0, }; */
static ChamplainMapSourceFactory *instance = NULL;

G_DEFINE_TYPE (ChamplainMapSourceFactory, champlain_map_source_factory, G_TYPE_OBJECT);

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_FACTORY, ChamplainMapSourceFactoryPrivate))

struct _ChamplainMapSourceFactoryPrivate
{
  GSList *registered_sources;
};

static ChamplainMapSource *champlain_map_source_new_generic (
    ChamplainMapSourceDesc *desc);

#ifdef CHAMPLAIN_HAS_MEMPHIS
static ChamplainMapSource *champlain_map_source_new_memphis (
    ChamplainMapSourceDesc *desc);
#endif


static void
champlain_map_source_factory_finalize (GObject *object)
{
  ChamplainMapSourceFactory *factory = CHAMPLAIN_MAP_SOURCE_FACTORY (object);

  g_slist_free (factory->priv->registered_sources);

  G_OBJECT_CLASS (champlain_map_source_factory_parent_class)->finalize (object);
}


static GObject *
champlain_map_source_factory_constructor (GType type,
    guint n_construct_params,
    GObjectConstructParam *construct_params)
{
  GObject *retval;

  if (instance == NULL)
    {
      retval = G_OBJECT_CLASS (champlain_map_source_factory_parent_class)->constructor
          (type, n_construct_params, construct_params);

      instance = CHAMPLAIN_MAP_SOURCE_FACTORY (retval);
      g_object_add_weak_pointer (retval, (gpointer *) &instance);
    }
  else
    {
      retval = g_object_ref (instance);
    }

  return retval;
}


static void
champlain_map_source_factory_class_init (ChamplainMapSourceFactoryClass *klass)
{
  g_type_class_add_private (klass, sizeof (ChamplainMapSourceFactoryPrivate));

  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->constructor = champlain_map_source_factory_constructor;
  object_class->finalize = champlain_map_source_factory_finalize;
}


static void
champlain_map_source_factory_init (ChamplainMapSourceFactory *factory)
{
  ChamplainMapSourceFactoryPrivate *priv = GET_PRIVATE (factory);
  ChamplainMapSourceDesc *desc;

  factory->priv = priv;
  priv->registered_sources = NULL;

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OSM_MAPNIK,
        "OpenStreetMap Mapnik",
        "Map Data ODBL OpenStreetMap Contributors, Map Imagery CC-BY-SA 2.0 OpenStreetMap",
        "http://creativecommons.org/licenses/by-sa/2.0/",
        0,
        18,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "https://tile.openstreetmap.org/#Z#/#X#/#Y#.png",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OSM_CYCLE_MAP,
        "OpenStreetMap Cycle Map",
        "Map data is CC-BY-SA 2.0 OpenStreetMap contributors",
        "http://creativecommons.org/licenses/by-sa/2.0/",
        0,
        18,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "http://tile.opencyclemap.org/cycle/#Z#/#X#/#Y#.png",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OSM_TRANSPORT_MAP,
        "OpenStreetMap Transport Map",
        "Map data is CC-BY-SA 2.0 OpenStreetMap contributors",
        "http://creativecommons.org/licenses/by-sa/2.0/",
        0,
        18,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "http://tile.xn--pnvkarte-m4a.de/tilegen/#Z#/#X#/#Y#.png",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_MFF_RELIEF,
        "Maps for Free Relief",
        "Map data available under GNU Free Documentation license, Version 1.2 or later",
        "http://www.gnu.org/copyleft/fdl.html",
        0,
        11,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "http://maps-for-free.com/layer/relief/z#Z#/row#Y#/#Z#_#X#-#Y#.jpg",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OWM_CLOUDS,
        "OpenWeatherMap cloud layer",
        "Map data is CC-BY-SA 2.0 OpenWeatherMap contributors",
        "http://creativecommons.org/licenses/by-sa/2.0/",
        0,
        18,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "http://tile.openweathermap.org/map/clouds/#Z#/#X#/#Y#.png",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OWM_WIND,
        "OpenWeatherMap wind layer",
        "Map data is CC-BY-SA 2.0 OpenWeatherMap contributors",
        "http://creativecommons.org/licenses/by-sa/2.0/",
        0,
        18,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "http://tile.openweathermap.org/map/wind/#Z#/#X#/#Y#.png",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OWM_TEMPERATURE,
        "OpenWeatherMap temperature layer",
        "Map data is CC-BY-SA 2.0 OpenWeatherMap contributors",
        "http://creativecommons.org/licenses/by-sa/2.0/",
        0,
        18,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "http://tile.openweathermap.org/map/temp/#Z#/#X#/#Y#.png",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OWM_PRECIPITATION,
        "OpenWeatherMap precipitation layer",
        "Map data is CC-BY-SA 2.0 OpenWeatherMap contributors",
        "http://creativecommons.org/licenses/by-sa/2.0/",
        0,
        18,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "http://tile.openweathermap.org/map/precipitation/#Z#/#X#/#Y#.png",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OWM_PRESSURE,
        "OpenWeatherMap sea level pressure layer",
        "Map data is CC-BY-SA 2.0 OpenWeatherMap contributors",
        "http://creativecommons.org/licenses/by-sa/2.0/",
        0,
        18,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "http://tile.openweathermap.org/map/pressure/#Z#/#X#/#Y#.png",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

#ifdef CHAMPLAIN_HAS_MEMPHIS
  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_MEMPHIS_LOCAL,
        "OpenStreetMap Memphis Local Map",
        "(CC) BY 2.0 OpenStreetMap contributors",
        "http://creativecommons.org/licenses/by/2.0/",
        12,
        18,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "",
        champlain_map_source_new_memphis,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_MEMPHIS_NETWORK,
        "OpenStreetMap Memphis Network Map",
        "(CC) BY 2.0 OpenStreetMap contributors",
        "http://creativecommons.org/licenses/by/2.0/",
        12,
        18,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "",
        champlain_map_source_new_memphis,
        NULL);
  champlain_map_source_factory_register (factory, desc);
#endif

/* Not available any more - remove completely in the next release */
#if 0
  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OSM_AERIAL_MAP,
        "MapQuest Open Aerial",
        "Map data is CC-BY-SA 2.0 OpenStreetMap contributors",
        "http://creativecommons.org/licenses/by-sa/2.0/",
        0,
        18,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "https://otile1.mqcdn.com/tiles/1.0.0/sat/#Z#/#X#/#Y#.jpg",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OSM_MAPQUEST,
        "MapQuest OSM",
        "Data, imagery and map information provided by MapQuest, Open Street Map and contributors",
        "http://creativecommons.org/licenses/by-sa/2.0/",
        0,
        17,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "https://otile1.mqcdn.com/tiles/1.0.0/osm/#Z#/#X#/#Y#.png",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OAM,
        "OpenAerialMap",
        "(CC) BY 3.0 OpenAerialMap contributors",
        "http://creativecommons.org/licenses/by/3.0/",
        0,
        17,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "http://tile.openaerialmap.org/tiles/1.0.0/openaerialmap-900913/#Z#/#X#/#Y#.jpg",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);

  desc = champlain_map_source_desc_new_full (
        CHAMPLAIN_MAP_SOURCE_OSM_OSMARENDER,
        "OpenStreetMap Osmarender",
        "Map data is CC-BY-SA 2.0 OpenStreetMap contributors",
        "http://creativecommons.org/licenses/by-sa/2.0/",
        0,
        17,
        256,
        CHAMPLAIN_MAP_PROJECTION_MERCATOR,
        "http://a.tah.openstreetmap.org/Tiles/tile/#Z#/#X#/#Y#.png",
        champlain_map_source_new_generic,
        NULL);
  champlain_map_source_factory_register (factory, desc);
#endif

}


/**
 * champlain_map_source_factory_dup_default:
 *
 * A method to obtain the singleton object.
 *
 * Returns: (transfer full): the singleton #ChamplainMapSourceFactory, it should be freed
 * using #g_object_unref() when not needed.
 *
 * Since: 0.4
 */
ChamplainMapSourceFactory *
champlain_map_source_factory_dup_default (void)
{
  return g_object_new (CHAMPLAIN_TYPE_MAP_SOURCE_FACTORY, NULL);
}


/**
 * champlain_map_source_factory_get_registered:
 * @factory: the Factory
 *
 * Get the list of registered map sources.
 *
 * Returns: (transfer container) (element-type ChamplainMapSourceDesc): the list of registered map sources, the items should not be freed,
 * the list should be freed with #g_slist_free.
 *
 * Since: 0.4
 */
GSList *
champlain_map_source_factory_get_registered (ChamplainMapSourceFactory *factory)
{
  return g_slist_copy (factory->priv->registered_sources);
}


/**
 * champlain_map_source_factory_create:
 * @factory: the Factory
 * @id: the wanted map source id
 *
 * Note: The id should not contain any character that can't be in a filename as it
 * will be used as the cache directory name for that map source.
 *
 * Returns: (transfer none): a ready to use #ChamplainMapSource matching the given name;
 * returns NULL if the source with the given name doesn't exist.
 *
 * Since: 0.4
 */
ChamplainMapSource *
champlain_map_source_factory_create (ChamplainMapSourceFactory *factory,
    const gchar *id)
{
  GSList *item;

  item = factory->priv->registered_sources;

  while (item != NULL)
    {
      ChamplainMapSourceDesc *desc = CHAMPLAIN_MAP_SOURCE_DESC (item->data);
      if (strcmp (champlain_map_source_desc_get_id (desc), id) == 0)
        {
          ChamplainMapSourceConstructor constructor;

          constructor = champlain_map_source_desc_get_constructor (desc);
          return constructor (desc);
        }
      item = g_slist_next (item);
    }

  return NULL;
}


/**
 * champlain_map_source_factory_create_cached_source:
 * @factory: the Factory
 * @id: the wanted map source id
 *
 * Creates a cached map source.
 *
 * Returns: (transfer none): a ready to use #ChamplainMapSourceChain consisting of
 * #ChamplainMemoryCache, #ChamplainFileCache, #ChamplainMapSource matching the given name, and
 * an error tile source created with champlain_map_source_factory_create_error_source ().
 * Returns NULL if the source with the given name doesn't exist.
 *
 * Since: 0.6
 */
ChamplainMapSource *
champlain_map_source_factory_create_cached_source (ChamplainMapSourceFactory *factory,
    const gchar *id)
{
  ChamplainMapSourceChain *source_chain;
  ChamplainMapSource *tile_source;
  ChamplainMapSource *error_source;
  ChamplainMapSource *memory_cache;
  ChamplainMapSource *file_cache;
  guint tile_size;
  ChamplainRenderer *renderer;

  tile_source = champlain_map_source_factory_create (factory, id);
  if (!tile_source)
    return NULL;

  tile_size = champlain_map_source_get_tile_size (tile_source);
  error_source = champlain_map_source_factory_create_error_source (factory, tile_size);

  renderer = CHAMPLAIN_RENDERER (champlain_image_renderer_new ());
  file_cache = CHAMPLAIN_MAP_SOURCE (champlain_file_cache_new_full (100000000, NULL, renderer));

  renderer = CHAMPLAIN_RENDERER (champlain_image_renderer_new ());
  memory_cache = CHAMPLAIN_MAP_SOURCE (champlain_memory_cache_new_full (100, renderer));

  source_chain = champlain_map_source_chain_new ();
  champlain_map_source_chain_push (source_chain, error_source);
  champlain_map_source_chain_push (source_chain, tile_source);
  champlain_map_source_chain_push (source_chain, file_cache);
  champlain_map_source_chain_push (source_chain, memory_cache);

  return CHAMPLAIN_MAP_SOURCE (source_chain);
}


/**
 * champlain_map_source_factory_create_memcached_source:
 * @factory: the Factory
 * @id: the wanted map source id
 *
 * Creates a memory cached map source.
 *
 * Returns: (transfer none): a ready to use #ChamplainMapSourceChain consisting of
 * #ChamplainMemoryCache and #ChamplainMapSource matching the given name.
 * Returns NULL if the source with the given name doesn't exist.
 *
 * Since: 0.12.5
 */
ChamplainMapSource *
champlain_map_source_factory_create_memcached_source (ChamplainMapSourceFactory *factory,
    const gchar *id)
{
  ChamplainMapSourceChain *source_chain;
  ChamplainMapSource *tile_source;
  ChamplainMapSource *memory_cache;
  ChamplainRenderer *renderer;

  tile_source = champlain_map_source_factory_create (factory, id);
  if (!tile_source)
    return NULL;

  renderer = CHAMPLAIN_RENDERER (champlain_image_renderer_new ());
  memory_cache = CHAMPLAIN_MAP_SOURCE (champlain_memory_cache_new_full (100, renderer));

  source_chain = champlain_map_source_chain_new ();
  champlain_map_source_chain_push (source_chain, tile_source);
  champlain_map_source_chain_push (source_chain, memory_cache);

  return CHAMPLAIN_MAP_SOURCE (source_chain);
}


/**
 * champlain_map_source_factory_create_error_source:
 * @factory: the Factory
 * @tile_size: the size of the error tile
 *
 * Creates a map source generating error tiles.
 *
 * Returns: (transfer none): a ready to use map source generating error tiles.
 *
 * Since: 0.8
 */
ChamplainMapSource *
champlain_map_source_factory_create_error_source (ChamplainMapSourceFactory *factory,
    guint tile_size)
{
  ChamplainMapSource *null_source;
  ChamplainRenderer *renderer;

  renderer = CHAMPLAIN_RENDERER (champlain_error_tile_renderer_new (tile_size));
  null_source = CHAMPLAIN_MAP_SOURCE (champlain_null_tile_source_new_full (renderer));

  return null_source;
}


static gint
compare_id (ChamplainMapSourceDesc *a, ChamplainMapSourceDesc *b)
{
  const gchar *id_a, *id_b;

  id_a = champlain_map_source_desc_get_id (a);
  id_b = champlain_map_source_desc_get_id (b);

  return g_strcmp0 (id_a, id_b);
}


/**
 * champlain_map_source_factory_register:
 * @factory: A #ChamplainMapSourceFactory
 * @desc: the description of the map source
 *
 * Registers the new map source with the given constructor.  When this map
 * source is requested, the given constructor will be used to build the
 * map source.  #ChamplainMapSourceFactory will take ownership of the passed
 * #ChamplainMapSourceDesc, so don't free it.
 *
 * Returns: TRUE if the registration suceeded.
 *
 * Since: 0.10
 */
gboolean
champlain_map_source_factory_register (ChamplainMapSourceFactory *factory,
    ChamplainMapSourceDesc *desc)
{
  if(!g_slist_find_custom (factory->priv->registered_sources, desc, (GCompareFunc) compare_id))
    {
      factory->priv->registered_sources = g_slist_append (factory->priv->registered_sources, desc);
      return TRUE;
    }
  return FALSE;
}


static ChamplainMapSource *
champlain_map_source_new_generic (ChamplainMapSourceDesc *desc)
{
  ChamplainMapSource *map_source;
  ChamplainRenderer *renderer;
  const gchar *id, *name, *license, *license_uri, *uri_format;
  guint min_zoom, max_zoom, tile_size;
  ChamplainMapProjection projection;

  id = champlain_map_source_desc_get_id (desc);
  name = champlain_map_source_desc_get_name (desc);
  license = champlain_map_source_desc_get_license (desc);
  license_uri = champlain_map_source_desc_get_license_uri (desc);
  min_zoom = champlain_map_source_desc_get_min_zoom_level (desc);
  max_zoom = champlain_map_source_desc_get_max_zoom_level (desc);
  tile_size = champlain_map_source_desc_get_tile_size (desc);
  projection = champlain_map_source_desc_get_projection (desc);
  uri_format = champlain_map_source_desc_get_uri_format (desc);

  renderer = CHAMPLAIN_RENDERER (champlain_image_renderer_new ());

  map_source = CHAMPLAIN_MAP_SOURCE (champlain_network_tile_source_new_full (
            id,
            name,
            license,
            license_uri,
            min_zoom,
            max_zoom,
            tile_size,
            projection,
            uri_format,
            renderer));

  return map_source;
}


#ifdef CHAMPLAIN_HAS_MEMPHIS
static ChamplainMapSource *
champlain_map_source_new_memphis (ChamplainMapSourceDesc *desc)
{
  ChamplainMapSource *map_source;
  ChamplainRenderer *renderer;
  const gchar *id, *name, *license, *license_uri;
  guint min_zoom, max_zoom, tile_size;
  ChamplainMapProjection projection;

  id = champlain_map_source_desc_get_id (desc);
  name = champlain_map_source_desc_get_name (desc);
  license = champlain_map_source_desc_get_license (desc);
  license_uri = champlain_map_source_desc_get_license_uri (desc);
  min_zoom = champlain_map_source_desc_get_min_zoom_level (desc);
  max_zoom = champlain_map_source_desc_get_max_zoom_level (desc);
  tile_size = champlain_map_source_desc_get_tile_size (desc);
  projection = champlain_map_source_desc_get_projection (desc);

  renderer = CHAMPLAIN_RENDERER (champlain_memphis_renderer_new_full (tile_size));

  if (g_strcmp0 (id, CHAMPLAIN_MAP_SOURCE_MEMPHIS_LOCAL) == 0)
    {
      map_source = CHAMPLAIN_MAP_SOURCE (champlain_file_tile_source_new_full (
                id,
                name,
                license,
                license_uri,
                min_zoom,
                max_zoom,
                tile_size,
                projection,
                renderer));
    }
  else
    {
      map_source = CHAMPLAIN_MAP_SOURCE (champlain_network_bbox_tile_source_new_full (
                id,
                name,
                license,
                license_uri,
                min_zoom,
                max_zoom,
                tile_size,
                projection,
                renderer));
    }

  return map_source;
}


#endif
