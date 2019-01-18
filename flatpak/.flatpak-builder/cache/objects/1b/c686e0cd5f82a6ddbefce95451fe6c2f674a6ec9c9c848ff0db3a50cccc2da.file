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

#if !defined (__CHAMPLAIN_CHAMPLAIN_H_INSIDE__) && !defined (CHAMPLAIN_COMPILATION)
#error "Only <champlain/champlain.h> can be included directly."
#endif

#ifndef CHAMPLAIN_MAP_SOURCE_FACTORY_H
#define CHAMPLAIN_MAP_SOURCE_FACTORY_H

#include <champlain/champlain-features.h>
#include <champlain/champlain-defines.h>
#include <champlain/champlain-map-source.h>
#include <champlain/champlain-map-source-desc.h>

#include <glib-object.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_MAP_SOURCE_FACTORY champlain_map_source_factory_get_type ()

#define CHAMPLAIN_MAP_SOURCE_FACTORY(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_FACTORY, ChamplainMapSourceFactory))

#define CHAMPLAIN_MAP_SOURCE_FACTORY_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_MAP_SOURCE_FACTORY, ChamplainMapSourceFactoryClass))

#define CHAMPLAIN_IS_MAP_SOURCE_FACTORY(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_FACTORY))

#define CHAMPLAIN_IS_MAP_SOURCE_FACTORY_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_MAP_SOURCE_FACTORY))

#define CHAMPLAIN_MAP_SOURCE_FACTORY_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_FACTORY, ChamplainMapSourceFactoryClass))

typedef struct _ChamplainMapSourceFactoryPrivate ChamplainMapSourceFactoryPrivate;

typedef struct _ChamplainMapSourceFactory ChamplainMapSourceFactory;
typedef struct _ChamplainMapSourceFactoryClass ChamplainMapSourceFactoryClass;

/**
 * ChamplainMapSourceFactory:
 *
 * The #ChamplainMapSourceFactory structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.4
 */
struct _ChamplainMapSourceFactory
{
  GObject parent;
  ChamplainMapSourceFactoryPrivate *priv;
};

struct _ChamplainMapSourceFactoryClass
{
  GObjectClass parent_class;
};

GType champlain_map_source_factory_get_type (void);

ChamplainMapSourceFactory *champlain_map_source_factory_dup_default (void);

ChamplainMapSource *champlain_map_source_factory_create (ChamplainMapSourceFactory *factory,
    const gchar *id);
ChamplainMapSource *champlain_map_source_factory_create_cached_source (ChamplainMapSourceFactory *factory,
    const gchar *id);
ChamplainMapSource *champlain_map_source_factory_create_memcached_source (ChamplainMapSourceFactory *factory,
    const gchar *id);
ChamplainMapSource *champlain_map_source_factory_create_error_source (ChamplainMapSourceFactory *factory,
    guint tile_size);

gboolean champlain_map_source_factory_register (ChamplainMapSourceFactory *factory,
    ChamplainMapSourceDesc *desc);
GSList *champlain_map_source_factory_get_registered (ChamplainMapSourceFactory *factory);

#ifndef GTK_DISABLE_DEPRECATED
/**
 * CHAMPLAIN_MAP_SOURCE_OSM_OSMARENDER:
 *
 * OpenStreetMap Osmarender
 *
 * Deprecated: Osmarender isn't available any more and will be removed in the next release.
 * As it doens't exist, it isn't registered to the factory and the 'create' method won't
 * return any source.
 */
#define CHAMPLAIN_MAP_SOURCE_OSM_OSMARENDER "osm-osmarender"
/**
 * CHAMPLAIN_MAP_SOURCE_OAM:
 *
 * OpenAerialMap
 *
 * Deprecated: OpenAerialMap isn't available any more and will be removed in the next release.
 * As it doens't exist, it isn't registered to the factory and the 'create' method won't
 * return any source.
 */
#define CHAMPLAIN_MAP_SOURCE_OAM "OpenAerialMap"
/**
 * CHAMPLAIN_MAP_SOURCE_OSM_MAPQUEST:
 *
 * Deprecated: Mapquest isn't available any more and will be removed in the next release.
 * As it doens't exist, it isn't registered to the factory and the 'create' method won't
 * return any source.
 */
#define CHAMPLAIN_MAP_SOURCE_OSM_MAPQUEST "osm-mapquest"
/**
 * CHAMPLAIN_MAP_SOURCE_OSM_AERIAL_MAP:
 *
 * Mapquest Open Aerial
 *
 * Deprecated: Mapquest isn't available any more and will be removed in the next release.
 * As it doens't exist, it isn't registered to the factory and the 'create' method won't
 * return any source.
 */
#define CHAMPLAIN_MAP_SOURCE_OSM_AERIAL_MAP "osm-aerialmap"
#endif

/**
 * CHAMPLAIN_MAP_SOURCE_OSM_MAPNIK:
 *
 * OpenStreetMap Mapnik
 */
#define CHAMPLAIN_MAP_SOURCE_OSM_MAPNIK "osm-mapnik"
/**
 * CHAMPLAIN_MAP_SOURCE_OSM_CYCLE_MAP:
 *
 * OpenStreetMap Cycle Map
 */
#define CHAMPLAIN_MAP_SOURCE_OSM_CYCLE_MAP "osm-cyclemap"
/**
 * CHAMPLAIN_MAP_SOURCE_OSM_TRANSPORT_MAP:
 *
 * OpenStreetMap Transport Map
 */
#define CHAMPLAIN_MAP_SOURCE_OSM_TRANSPORT_MAP "osm-transportmap"
/**
 * CHAMPLAIN_MAP_SOURCE_MFF_RELIEF:
 *
 * Maps for Free Relief
 */
#define CHAMPLAIN_MAP_SOURCE_MFF_RELIEF "mff-relief"
/**
 * CHAMPLAIN_MAP_SOURCE_OWM_CLOUDS:
 *
 * OpenWeatherMap clouds layer
 */
#define CHAMPLAIN_MAP_SOURCE_OWM_CLOUDS "owm-clouds"
/**
 * CHAMPLAIN_MAP_SOURCE_OWM_PRECIPITATION:
 *
 * OpenWeatherMap precipitation
 */
#define CHAMPLAIN_MAP_SOURCE_OWM_PRECIPITATION "owm-precipitation"
/**
 * CHAMPLAIN_MAP_SOURCE_OWM_PRESSURE:
 *
 * OpenWeatherMap sea level pressure
 */
#define CHAMPLAIN_MAP_SOURCE_OWM_PRESSURE "owm-pressure"
/**
 * CHAMPLAIN_MAP_SOURCE_OWM_WIND:
 *
 * OpenWeatherMap wind
 */
#define CHAMPLAIN_MAP_SOURCE_OWM_WIND "owm-wind"
/**
 * CHAMPLAIN_MAP_SOURCE_OWM_TEMPERATURE:
 *
 * OpenWeatherMap temperature
 */
#define CHAMPLAIN_MAP_SOURCE_OWM_TEMPERATURE "owm-temperature"


#ifdef CHAMPLAIN_HAS_MEMPHIS
/**
 * CHAMPLAIN_MAP_SOURCE_MEMPHIS_LOCAL:
 *
 * OpenStreetMap Memphis Local Map
 */
#define CHAMPLAIN_MAP_SOURCE_MEMPHIS_LOCAL "memphis-local"
/**
 * CHAMPLAIN_MAP_SOURCE_MEMPHIS_NETWORK:
 *
 * OpenStreetMap Memphis Network Map
 */
#define CHAMPLAIN_MAP_SOURCE_MEMPHIS_NETWORK "memphis-network"
#endif

G_END_DECLS

#endif
