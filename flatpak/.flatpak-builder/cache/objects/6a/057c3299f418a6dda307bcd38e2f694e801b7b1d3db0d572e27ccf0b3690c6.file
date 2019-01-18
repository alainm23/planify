/*
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

#ifndef _CHAMPLAIN_MAP_SOURCE_H_
#define _CHAMPLAIN_MAP_SOURCE_H_

#include <champlain/champlain-defines.h>
#include <champlain/champlain-tile.h>
#include <champlain/champlain-renderer.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_MAP_SOURCE champlain_map_source_get_type ()

#define CHAMPLAIN_MAP_SOURCE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_MAP_SOURCE, ChamplainMapSource))

#define CHAMPLAIN_MAP_SOURCE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_MAP_SOURCE, ChamplainMapSourceClass))

#define CHAMPLAIN_IS_MAP_SOURCE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_MAP_SOURCE))

#define CHAMPLAIN_IS_MAP_SOURCE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_MAP_SOURCE))

#define CHAMPLAIN_MAP_SOURCE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_MAP_SOURCE, ChamplainMapSourceClass))

typedef struct _ChamplainMapSourcePrivate ChamplainMapSourcePrivate;

typedef struct _ChamplainMapSourceClass ChamplainMapSourceClass;

/**
 * ChamplainMapProjection:
 * @CHAMPLAIN_MAP_PROJECTION_MERCATOR: Currently the only supported projection
 *
 * Projections supported by the library.
 */
typedef enum
{
  CHAMPLAIN_MAP_PROJECTION_MERCATOR
} ChamplainMapProjection;

/**
 * ChamplainMapSource:
 *
 * The #ChamplainMapSource structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.4
 */
struct _ChamplainMapSource
{
  GInitiallyUnowned parent_instance;

  ChamplainMapSourcePrivate *priv;
};

struct _ChamplainMapSourceClass
{
  GInitiallyUnownedClass parent_class;

  const gchar * (*get_id)(ChamplainMapSource *map_source);
  const gchar * (*get_name)(ChamplainMapSource *map_source);
  const gchar * (*get_license)(ChamplainMapSource *map_source);
  const gchar * (*get_license_uri)(ChamplainMapSource *map_source);
  guint (*get_min_zoom_level)(ChamplainMapSource *map_source);
  guint (*get_max_zoom_level)(ChamplainMapSource *map_source);
  guint (*get_tile_size)(ChamplainMapSource *map_source);
  ChamplainMapProjection (*get_projection)(ChamplainMapSource *map_source);

  void (*fill_tile)(ChamplainMapSource *map_source,
      ChamplainTile *tile);
};

GType champlain_map_source_get_type (void);

ChamplainMapSource *champlain_map_source_get_next_source (ChamplainMapSource *map_source);
void champlain_map_source_set_next_source (ChamplainMapSource *map_source,
    ChamplainMapSource *next_source);

ChamplainRenderer *champlain_map_source_get_renderer (ChamplainMapSource *map_source);
void champlain_map_source_set_renderer (ChamplainMapSource *map_source,
    ChamplainRenderer *renderer);

const gchar *champlain_map_source_get_id (ChamplainMapSource *map_source);
const gchar *champlain_map_source_get_name (ChamplainMapSource *map_source);
const gchar *champlain_map_source_get_license (ChamplainMapSource *map_source);
const gchar *champlain_map_source_get_license_uri (ChamplainMapSource *map_source);
guint champlain_map_source_get_min_zoom_level (ChamplainMapSource *map_source);
guint champlain_map_source_get_max_zoom_level (ChamplainMapSource *map_source);
guint champlain_map_source_get_tile_size (ChamplainMapSource *map_source);
ChamplainMapProjection champlain_map_source_get_projection (ChamplainMapSource *map_source);

gdouble champlain_map_source_get_x (ChamplainMapSource *map_source,
    guint zoom_level,
    gdouble longitude);
gdouble champlain_map_source_get_y (ChamplainMapSource *map_source,
    guint zoom_level,
    gdouble latitude);
gdouble champlain_map_source_get_longitude (ChamplainMapSource *map_source,
    guint zoom_level,
    gdouble x);
gdouble champlain_map_source_get_latitude (ChamplainMapSource *map_source,
    guint zoom_level,
    gdouble y);
guint champlain_map_source_get_row_count (ChamplainMapSource *map_source,
    guint zoom_level);
guint champlain_map_source_get_column_count (ChamplainMapSource *map_source,
    guint zoom_level);
gdouble champlain_map_source_get_meters_per_pixel (ChamplainMapSource *map_source,
    guint zoom_level,
    gdouble latitude,
    gdouble longitude);

void champlain_map_source_fill_tile (ChamplainMapSource *map_source,
    ChamplainTile *tile);

G_END_DECLS

#endif /* _CHAMPLAIN_MAP_SOURCE_H_ */
