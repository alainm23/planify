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

/**
 * SECTION:champlain-null-tile-source
 * @short_description: A tile source that doesn't load map data from anywhere
 *
 * This map source does not provide any input data to the associated renderer.
 * This can be useful in situations when the tile can be rendered independently
 * of any input such as in the case of the #ChamplainErrorTileRenderer.
 */

#include "champlain-null-tile-source.h"

#include "champlain-debug.h"
#include "champlain-bounding-box.h"
#include "champlain-enum-types.h"
#include "champlain-tile.h"

G_DEFINE_TYPE (ChamplainNullTileSource, champlain_null_tile_source, CHAMPLAIN_TYPE_TILE_SOURCE)

static void fill_tile (ChamplainMapSource *map_source,
    ChamplainTile *tile);


static void
champlain_null_tile_source_dispose (GObject *object)
{
  G_OBJECT_CLASS (champlain_null_tile_source_parent_class)->dispose (object);
}


static void
champlain_null_tile_source_finalize (GObject *object)
{
  G_OBJECT_CLASS (champlain_null_tile_source_parent_class)->finalize (object);
}


static void
champlain_null_tile_source_class_init (ChamplainNullTileSourceClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  ChamplainMapSourceClass *map_source_class = CHAMPLAIN_MAP_SOURCE_CLASS (klass);

  object_class->dispose = champlain_null_tile_source_dispose;
  object_class->finalize = champlain_null_tile_source_finalize;

  map_source_class->fill_tile = fill_tile;
}


static void
champlain_null_tile_source_init (ChamplainNullTileSource *self)
{
  g_return_if_fail (CHAMPLAIN_IS_NULL_TILE_SOURCE (self));
}


/**
 * champlain_null_tile_source_new_full:
 * @renderer: the #ChamplainRenderer used to render tiles
 *
 * Constructor of #ChamplainNullTileSource.
 *
 * Returns: a constructed #ChamplainNullTileSource object
 *
 * Since: 0.8
 */
ChamplainNullTileSource *
champlain_null_tile_source_new_full (ChamplainRenderer *renderer)
{
  ChamplainNullTileSource *source;

  source = g_object_new (CHAMPLAIN_TYPE_NULL_TILE_SOURCE,
        "renderer", renderer,
        NULL);
  return source;
}


static void
tile_rendered_cb (ChamplainTile *tile,
    gpointer data,
    guint size,
    gboolean error,
    ChamplainMapSource *map_source)
{
  ChamplainMapSource *next_source;

  g_signal_handlers_disconnect_by_func (tile, tile_rendered_cb, map_source);

  next_source = champlain_map_source_get_next_source (map_source);

  if (!error)
    {
      ChamplainTileSource *tile_source = CHAMPLAIN_TILE_SOURCE (map_source);
      ChamplainTileCache *tile_cache = champlain_tile_source_get_cache (tile_source);

      if (tile_cache && data)
        champlain_tile_cache_store_tile (tile_cache, tile, data, size);

      champlain_tile_set_fade_in (tile, TRUE);
      champlain_tile_set_state (tile, CHAMPLAIN_STATE_DONE);
      champlain_tile_display_content (tile);
    }
  else if (next_source)
    champlain_map_source_fill_tile (next_source, tile);

  g_object_unref (map_source);
  g_object_unref (tile);
}


static void
fill_tile (ChamplainMapSource *map_source,
    ChamplainTile *tile)
{
  g_return_if_fail (CHAMPLAIN_IS_NULL_TILE_SOURCE (map_source));
  g_return_if_fail (CHAMPLAIN_IS_TILE (tile));

  ChamplainMapSource *next_source = champlain_map_source_get_next_source (map_source);

  if (champlain_tile_get_state (tile) == CHAMPLAIN_STATE_DONE)
    return;

  if (champlain_tile_get_state (tile) != CHAMPLAIN_STATE_LOADED)
    {
      ChamplainRenderer *renderer;

      renderer = champlain_map_source_get_renderer (map_source);

      g_return_if_fail (CHAMPLAIN_IS_RENDERER (renderer));

      g_object_ref (map_source);
      g_object_ref (tile);

      g_signal_connect (tile, "render-complete", G_CALLBACK (tile_rendered_cb), map_source);

      champlain_renderer_render (renderer, tile);
    }
  else if (CHAMPLAIN_IS_MAP_SOURCE (next_source))
    champlain_map_source_fill_tile (next_source, tile);
  else if (champlain_tile_get_state (tile) == CHAMPLAIN_STATE_LOADED)
    {
      /* if we have some content, use the tile even if it wasn't validated */
      champlain_tile_set_state (tile, CHAMPLAIN_STATE_DONE);
      champlain_tile_display_content (tile);
    }
}
