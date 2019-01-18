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

#ifndef _CHAMPLAIN_TILE_CACHE_H_
#define _CHAMPLAIN_TILE_CACHE_H_

#include <champlain/champlain-defines.h>
#include <champlain/champlain-map-source.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_TILE_CACHE champlain_tile_cache_get_type ()

#define CHAMPLAIN_TILE_CACHE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_TILE_CACHE, ChamplainTileCache))

#define CHAMPLAIN_TILE_CACHE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_TILE_CACHE, ChamplainTileCacheClass))

#define CHAMPLAIN_IS_TILE_CACHE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_TILE_CACHE))

#define CHAMPLAIN_IS_TILE_CACHE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_TILE_CACHE))

#define CHAMPLAIN_TILE_CACHE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_TILE_CACHE, ChamplainTileCacheClass))

typedef struct _ChamplainTileCachePrivate ChamplainTileCachePrivate;

typedef struct _ChamplainTileCache ChamplainTileCache;
typedef struct _ChamplainTileCacheClass ChamplainTileCacheClass;

/**
 * ChamplainTileCache:
 *
 * The #ChamplainTileCache structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.6
 */
struct _ChamplainTileCache
{
  ChamplainMapSource parent_instance;

  ChamplainTileCachePrivate *priv;
};

struct _ChamplainTileCacheClass
{
  ChamplainMapSourceClass parent_class;

  void (*store_tile)(ChamplainTileCache *tile_cache,
      ChamplainTile *tile,
      const gchar *contents,
      gsize size);
  void (*refresh_tile_time)(ChamplainTileCache *tile_cache,
      ChamplainTile *tile);
  void (*on_tile_filled)(ChamplainTileCache *tile_cache,
      ChamplainTile *tile);
};

GType champlain_tile_cache_get_type (void);

void champlain_tile_cache_store_tile (ChamplainTileCache *tile_cache,
    ChamplainTile *tile,
    const gchar *contents,
    gsize size);
void champlain_tile_cache_refresh_tile_time (ChamplainTileCache *tile_cache,
    ChamplainTile *tile);
void champlain_tile_cache_on_tile_filled (ChamplainTileCache *tile_cache,
    ChamplainTile *tile);

G_END_DECLS

#endif /* _CHAMPLAIN_TILE_CACHE_H_ */
