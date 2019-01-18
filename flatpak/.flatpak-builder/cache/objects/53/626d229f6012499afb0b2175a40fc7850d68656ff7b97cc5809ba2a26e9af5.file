/*
 * Copyright (C) 2008-2009 Pierre-Luc Beaudoin <pierre-luc@pierlux.com>
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

#ifndef _CHAMPLAIN_TILE_SOURCE_H_
#define _CHAMPLAIN_TILE_SOURCE_H_

#include <champlain/champlain-defines.h>
#include <champlain/champlain-map-source.h>
#include <champlain/champlain-tile-cache.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_TILE_SOURCE champlain_tile_source_get_type ()

#define CHAMPLAIN_TILE_SOURCE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_TILE_SOURCE, ChamplainTileSource))

#define CHAMPLAIN_TILE_SOURCE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_TILE_SOURCE, ChamplainTileSourceClass))

#define CHAMPLAIN_IS_TILE_SOURCE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_TILE_SOURCE))

#define CHAMPLAIN_IS_TILE_SOURCE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_TILE_SOURCE))

#define CHAMPLAIN_TILE_SOURCE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_TILE_SOURCE, ChamplainTileSourceClass))

typedef struct _ChamplainTileSourcePrivate ChamplainTileSourcePrivate;

typedef struct _ChamplainTileSource ChamplainTileSource;
typedef struct _ChamplainTileSourceClass ChamplainTileSourceClass;

/**
 * ChamplainTileSource:
 *
 * The #ChamplainTileSource structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.6
 */
struct _ChamplainTileSource
{
  ChamplainMapSource parent_instance;

  ChamplainTileSourcePrivate *priv;
};

struct _ChamplainTileSourceClass
{
  ChamplainMapSourceClass parent_class;
};

GType champlain_tile_source_get_type (void);

ChamplainTileCache *champlain_tile_source_get_cache (ChamplainTileSource *tile_source);
void champlain_tile_source_set_cache (ChamplainTileSource *tile_source,
    ChamplainTileCache *cache);

void champlain_tile_source_set_id (ChamplainTileSource *tile_source,
    const gchar *id);
void champlain_tile_source_set_name (ChamplainTileSource *tile_source,
    const gchar *name);
void champlain_tile_source_set_license (ChamplainTileSource *tile_source,
    const gchar *license);
void champlain_tile_source_set_license_uri (ChamplainTileSource *tile_source,
    const gchar *license_uri);

void champlain_tile_source_set_min_zoom_level (ChamplainTileSource *tile_source,
    guint zoom_level);
void champlain_tile_source_set_max_zoom_level (ChamplainTileSource *tile_source,
    guint zoom_level);
void champlain_tile_source_set_tile_size (ChamplainTileSource *tile_source,
    guint tile_size);
void champlain_tile_source_set_projection (ChamplainTileSource *tile_source,
    ChamplainMapProjection projection);

G_END_DECLS

#endif /* _CHAMPLAIN_TILE_SOURCE_H_ */
