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
 * SECTION:champlain-map-source-chain
 * @short_description: A map source simplifying creation of source chains
 *
 * This map source simplifies creation of map chains by providing two
 * functions for their creation and modification in a stack-like manner:
 * champlain_map_source_chain_push() and champlain_map_source_chain_pop().
 * For instance, to create a chain consisting of #ChamplainMemoryCache,
 * #ChamplainFileCache and #ChamplainNetworkTileSource, the map
 * sources have to be pushed into the chain in the reverse order starting
 * from #ChamplainNetworkTileSource. After its creation, #ChamplainMapSourceChain
 * behaves as a chain of map sources it contains.
 */

#include "champlain-map-source-chain.h"
#include "champlain-tile-cache.h"
#include "champlain-tile-source.h"

G_DEFINE_TYPE (ChamplainMapSourceChain, champlain_map_source_chain, CHAMPLAIN_TYPE_MAP_SOURCE);

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_CHAIN, ChamplainMapSourceChainPrivate))

struct _ChamplainMapSourceChainPrivate
{
  ChamplainMapSource *stack_top;
  ChamplainMapSource *stack_bottom;
};

static const gchar *get_id (ChamplainMapSource *map_source);
static const gchar *get_name (ChamplainMapSource *map_source);
static const gchar *get_license (ChamplainMapSource *map_source);
static const gchar *get_license_uri (ChamplainMapSource *map_source);
static guint get_min_zoom_level (ChamplainMapSource *map_source);
static guint get_max_zoom_level (ChamplainMapSource *map_source);
static guint get_tile_size (ChamplainMapSource *map_source);

static void fill_tile (ChamplainMapSource *map_source,
    ChamplainTile *tile);
static void on_set_next_source_cb (ChamplainMapSourceChain *source_chain,
    G_GNUC_UNUSED gpointer user_data);


static void
champlain_map_source_chain_dispose (GObject *object)
{
  ChamplainMapSourceChain *source_chain = CHAMPLAIN_MAP_SOURCE_CHAIN (object);

  while (source_chain->priv->stack_top)
    champlain_map_source_chain_pop (source_chain);

  G_OBJECT_CLASS (champlain_map_source_chain_parent_class)->dispose (object);
}


static void
champlain_map_source_chain_finalize (GObject *object)
{
  G_OBJECT_CLASS (champlain_map_source_chain_parent_class)->finalize (object);
}


static void
champlain_map_source_chain_class_init (ChamplainMapSourceChainClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (ChamplainMapSourceChainPrivate));

  object_class->finalize = champlain_map_source_chain_finalize;
  object_class->dispose = champlain_map_source_chain_dispose;

  ChamplainMapSourceClass *map_source_class = CHAMPLAIN_MAP_SOURCE_CLASS (klass);

  map_source_class->get_id = get_id;
  map_source_class->get_name = get_name;
  map_source_class->get_license = get_license;
  map_source_class->get_license_uri = get_license_uri;
  map_source_class->get_min_zoom_level = get_min_zoom_level;
  map_source_class->get_max_zoom_level = get_max_zoom_level;
  map_source_class->get_tile_size = get_tile_size;

  map_source_class->fill_tile = fill_tile;
}


static void
champlain_map_source_chain_init (ChamplainMapSourceChain *source_chain)
{
  ChamplainMapSourceChainPrivate *priv = GET_PRIVATE (source_chain);

  source_chain->priv = priv;

  priv->stack_top = NULL;
  priv->stack_bottom = NULL;

  g_signal_connect (source_chain, "notify::next-source",
      G_CALLBACK (on_set_next_source_cb), NULL);
}


/**
 * champlain_map_source_chain_new:
 *
 * Constructor of #ChamplainMapSourceChain.
 *
 * Returns: a new empty #ChamplainMapSourceChain.
 *
 * Since: 0.6
 */
ChamplainMapSourceChain *
champlain_map_source_chain_new (void)
{
  return g_object_new (CHAMPLAIN_TYPE_MAP_SOURCE_CHAIN, NULL);
}


static const gchar *
get_id (ChamplainMapSource *map_source)
{
  ChamplainMapSourceChain *source_chain = CHAMPLAIN_MAP_SOURCE_CHAIN (map_source);

  g_return_val_if_fail (source_chain, NULL);

  ChamplainMapSourceChainPrivate *priv = source_chain->priv;
  g_return_val_if_fail (priv->stack_top, NULL);

  return champlain_map_source_get_id (priv->stack_top);
}


static const gchar *
get_name (ChamplainMapSource *map_source)
{
  ChamplainMapSourceChain *source_chain = CHAMPLAIN_MAP_SOURCE_CHAIN (map_source);

  g_return_val_if_fail (source_chain, NULL);

  ChamplainMapSourceChainPrivate *priv = source_chain->priv;
  g_return_val_if_fail (priv->stack_top, NULL);

  return champlain_map_source_get_name (priv->stack_top);
}


static const gchar *
get_license (ChamplainMapSource *map_source)
{
  ChamplainMapSourceChain *source_chain = CHAMPLAIN_MAP_SOURCE_CHAIN (map_source);

  g_return_val_if_fail (source_chain, NULL);

  ChamplainMapSourceChainPrivate *priv = source_chain->priv;
  g_return_val_if_fail (priv->stack_top, NULL);

  return champlain_map_source_get_license (priv->stack_top);
}


static const gchar *
get_license_uri (ChamplainMapSource *map_source)
{
  ChamplainMapSourceChain *source_chain = CHAMPLAIN_MAP_SOURCE_CHAIN (map_source);

  g_return_val_if_fail (source_chain, NULL);

  ChamplainMapSourceChainPrivate *priv = source_chain->priv;
  g_return_val_if_fail (priv->stack_top, NULL);

  return champlain_map_source_get_license_uri (priv->stack_top);
}


static guint
get_min_zoom_level (ChamplainMapSource *map_source)
{
  ChamplainMapSourceChain *source_chain = CHAMPLAIN_MAP_SOURCE_CHAIN (map_source);

  g_return_val_if_fail (source_chain, 0);

  ChamplainMapSourceChainPrivate *priv = source_chain->priv;
  g_return_val_if_fail (priv->stack_top, 0);

  return champlain_map_source_get_min_zoom_level (priv->stack_top);
}


static guint
get_max_zoom_level (ChamplainMapSource *map_source)
{
  ChamplainMapSourceChain *source_chain = CHAMPLAIN_MAP_SOURCE_CHAIN (map_source);

  g_return_val_if_fail (source_chain, 0);

  ChamplainMapSourceChainPrivate *priv = source_chain->priv;
  g_return_val_if_fail (priv->stack_top, 0);

  return champlain_map_source_get_max_zoom_level (priv->stack_top);
}


static guint
get_tile_size (ChamplainMapSource *map_source)
{
  ChamplainMapSourceChain *source_chain = CHAMPLAIN_MAP_SOURCE_CHAIN (map_source);

  g_return_val_if_fail (source_chain, 0);

  ChamplainMapSourceChainPrivate *priv = source_chain->priv;
  g_return_val_if_fail (priv->stack_top, 0);

  return champlain_map_source_get_tile_size (priv->stack_top);
}


static void
fill_tile (ChamplainMapSource *map_source,
    ChamplainTile *tile)
{
  ChamplainMapSourceChain *source_chain = CHAMPLAIN_MAP_SOURCE_CHAIN (map_source);

  g_return_if_fail (source_chain);

  ChamplainMapSourceChainPrivate *priv = source_chain->priv;
  g_return_if_fail (priv->stack_top);

  champlain_map_source_fill_tile (priv->stack_top, tile);
}


static void
on_set_next_source_cb (ChamplainMapSourceChain *source_chain,
    G_GNUC_UNUSED gpointer user_data)
{
  g_return_if_fail (source_chain);

  ChamplainMapSourceChainPrivate *priv = source_chain->priv;
  ChamplainMapSource *map_source = CHAMPLAIN_MAP_SOURCE (source_chain);
  ChamplainMapSource *next_source;

  next_source = champlain_map_source_get_next_source (map_source);

  if (priv->stack_bottom)
    champlain_map_source_set_next_source (priv->stack_bottom, next_source);
}


static void
assign_cache_of_next_source_sequence (ChamplainMapSourceChain *source_chain,
    ChamplainMapSource *start_map_source,
    ChamplainTileCache *tile_cache)
{
  ChamplainMapSource *map_source = start_map_source;
  ChamplainMapSource *chain_next_source = champlain_map_source_get_next_source (CHAMPLAIN_MAP_SOURCE (source_chain));

  do
    {
      map_source = champlain_map_source_get_next_source (map_source);
    } 
  while (CHAMPLAIN_IS_TILE_CACHE (map_source));

  while (CHAMPLAIN_IS_TILE_SOURCE (map_source) && map_source != chain_next_source)
    {
      champlain_tile_source_set_cache (CHAMPLAIN_TILE_SOURCE (map_source), tile_cache);
      map_source = champlain_map_source_get_next_source (map_source);
    }
}


/**
 * champlain_map_source_chain_push:
 * @source_chain: a #ChamplainMapSourceChain
 * @map_source: the #ChamplainMapSource to be pushed into the chain
 *
 * Pushes a map source into the chain.
 *
 * Since: 0.6
 */
void
champlain_map_source_chain_push (ChamplainMapSourceChain *source_chain,
    ChamplainMapSource *map_source)
{
  ChamplainMapSourceChainPrivate *priv = source_chain->priv;
  gboolean is_cache = FALSE;

  if (CHAMPLAIN_IS_TILE_CACHE (map_source))
    is_cache = TRUE;
  else
    g_return_if_fail (CHAMPLAIN_IS_TILE_SOURCE (map_source));

  g_object_ref_sink (map_source);

  if (!priv->stack_top)
    {
      ChamplainMapSource *chain_next_source = champlain_map_source_get_next_source (CHAMPLAIN_MAP_SOURCE (source_chain));

      /* tile source has to be last */
      g_return_if_fail (!is_cache);

      priv->stack_top = map_source;
      priv->stack_bottom = map_source;
      if (chain_next_source)
        champlain_map_source_set_next_source (priv->stack_bottom, chain_next_source);
    }
  else
    {
      champlain_map_source_set_next_source (map_source, priv->stack_top);
      priv->stack_top = map_source;

      if (is_cache)
        {
          ChamplainTileCache *tile_cache = CHAMPLAIN_TILE_CACHE (map_source);
          assign_cache_of_next_source_sequence (source_chain, priv->stack_top, tile_cache);
        }
    }
}


/**
 * champlain_map_source_chain_pop:
 * @source_chain: a #ChamplainMapSourceChain
 *
 * Pops a map source from the top of the stack from the chain.
 *
 * Since: 0.6
 */
void
champlain_map_source_chain_pop (ChamplainMapSourceChain *source_chain)
{
  ChamplainMapSourceChainPrivate *priv = source_chain->priv;
  ChamplainMapSource *old_stack_top = priv->stack_top;
  ChamplainMapSource *next_source = champlain_map_source_get_next_source (priv->stack_top);

  g_return_if_fail (priv->stack_top);

  if (CHAMPLAIN_IS_TILE_CACHE (priv->stack_top))
    {
      ChamplainTileCache *tile_cache = NULL;

      if (CHAMPLAIN_IS_TILE_CACHE (next_source))
        tile_cache = CHAMPLAIN_TILE_CACHE (next_source);

      /* _push() guarantees that the last source is tile_source so we can be
         sure that the next map source is still within the chain */
      assign_cache_of_next_source_sequence (source_chain, priv->stack_top, tile_cache);
    }

  if (next_source == champlain_map_source_get_next_source (CHAMPLAIN_MAP_SOURCE (source_chain)))
    {
      priv->stack_top = NULL;
      priv->stack_bottom = NULL;
    }
  else
    priv->stack_top = next_source;

  g_object_unref (old_stack_top);
}
