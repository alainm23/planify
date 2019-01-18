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
 * SECTION:champlain-renderer
 * @short_description: A base class of renderers
 *
 * A renderer is used to render tiles textures. A tile is rendered based on
 * the provided data - this can be arbitrary data the given renderer understands
 * (e.g. raw bitmap data, vector xml map representation and so on).
 */

#include "champlain-renderer.h"

G_DEFINE_TYPE (ChamplainRenderer, champlain_renderer, G_TYPE_INITIALLY_UNOWNED)

static void
champlain_renderer_dispose (GObject *object)
{
  G_OBJECT_CLASS (champlain_renderer_parent_class)->dispose (object);
}


static void
champlain_renderer_finalize (GObject *object)
{
  G_OBJECT_CLASS (champlain_renderer_parent_class)->finalize (object);
}


static void
champlain_renderer_class_init (ChamplainRendererClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = champlain_renderer_finalize;
  object_class->dispose = champlain_renderer_dispose;

  klass->set_data = NULL;
  klass->render = NULL;
}


/**
 * champlain_renderer_set_data:
 * @renderer: a #ChamplainRenderer
 * @data: data used for tile rendering
 * @size: size of the data in bytes
 *
 * Sets the data which is used to render tiles by the renderer.
 *
 * Since: 0.8
 */
void
champlain_renderer_set_data (ChamplainRenderer *renderer,
    const gchar *data,
    guint size)
{
  g_return_if_fail (CHAMPLAIN_IS_RENDERER (renderer));

  CHAMPLAIN_RENDERER_GET_CLASS (renderer)->set_data (renderer, data, size);
}


/**
 * champlain_renderer_render:
 * @renderer: a #ChamplainRenderer
 * @tile: the tile to render
 *
 * Renders the texture for the provided tile and calls champlain_tile_set_content()
 * to set the content of the tile. When the rendering is finished, the renderer
 * emits the #ChamplainTile::render-complete signal. The tile has to be displayed manually by
 * calling champlain_tile_display_content().
 *
 * Since: 0.8
 */
void
champlain_renderer_render (ChamplainRenderer *renderer,
    ChamplainTile *tile)
{
  g_return_if_fail (CHAMPLAIN_IS_RENDERER (renderer));

  CHAMPLAIN_RENDERER_GET_CLASS (renderer)->render (renderer, tile);
}


static void
champlain_renderer_init (ChamplainRenderer *self)
{
}
