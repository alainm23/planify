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
 * SECTION:champlain-error-tile-renderer
 * @short_description: A renderer that renders error tiles independently of input data
 *
 * #ChamplainErrorTileRenderer always renders error tiles (tiles that indicate that the real tile could
 * not be loaded) no matter what input data is used.
 */

#include "champlain-error-tile-renderer.h"
#include <gdk/gdk.h>

G_DEFINE_TYPE (ChamplainErrorTileRenderer, champlain_error_tile_renderer, CHAMPLAIN_TYPE_RENDERER)

#define GET_PRIVATE(o) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((o), CHAMPLAIN_TYPE_ERROR_TILE_RENDERER, ChamplainErrorTileRendererPrivate))

struct _ChamplainErrorTileRendererPrivate
{
  ClutterContent *error_canvas;
  guint tile_size;
};

enum
{
  PROP_0,
  PROP_TILE_SIZE
};


static void set_data (ChamplainRenderer *renderer,
    const gchar *data,
    guint size);
static void render (ChamplainRenderer *renderer,
    ChamplainTile *tile);


static void
champlain_error_tile_renderer_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  ChamplainErrorTileRenderer *renderer = CHAMPLAIN_ERROR_TILE_RENDERER (object);

  switch (property_id)
    {
    case PROP_TILE_SIZE:
      g_value_set_uint (value, champlain_error_tile_renderer_get_tile_size (renderer));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}


static void
champlain_error_tile_renderer_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  ChamplainErrorTileRenderer *renderer = CHAMPLAIN_ERROR_TILE_RENDERER (object);

  switch (property_id)
    {
    case PROP_TILE_SIZE:
      champlain_error_tile_renderer_set_tile_size (renderer, g_value_get_uint (value));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}


static void
champlain_error_tile_renderer_dispose (GObject *object)
{
  ChamplainErrorTileRendererPrivate *priv = CHAMPLAIN_ERROR_TILE_RENDERER (object)->priv;

  if (priv->error_canvas)
    {
      g_object_unref (priv->error_canvas);
      priv->error_canvas = NULL;
    }

  G_OBJECT_CLASS (champlain_error_tile_renderer_parent_class)->dispose (object);
}


static void
champlain_error_tile_renderer_finalize (GObject *object)
{
  G_OBJECT_CLASS (champlain_error_tile_renderer_parent_class)->finalize (object);
}


static void
champlain_error_tile_renderer_class_init (ChamplainErrorTileRendererClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  ChamplainRendererClass *renderer_class = CHAMPLAIN_RENDERER_CLASS (klass);

  g_type_class_add_private (klass, sizeof (ChamplainErrorTileRendererPrivate));

  object_class->get_property = champlain_error_tile_renderer_get_property;
  object_class->set_property = champlain_error_tile_renderer_set_property;
  object_class->finalize = champlain_error_tile_renderer_finalize;
  object_class->dispose = champlain_error_tile_renderer_dispose;

  /**
   * ChamplainErrorTileRenderer:tile-size:
   *
   * The size of the rendered tile.
   *
   * Since: 0.8
   */
  g_object_class_install_property (object_class,
      PROP_TILE_SIZE,
      g_param_spec_uint ("tile-size",
          "Tile Size",
          "The size of the rendered tile",
          0,
          G_MAXINT,
          256,
          G_PARAM_READWRITE));

  renderer_class->set_data = set_data;
  renderer_class->render = render;
}


static void
champlain_error_tile_renderer_init (ChamplainErrorTileRenderer *self)
{
  ChamplainErrorTileRendererPrivate *priv = GET_PRIVATE (self);

  self->priv = priv;

  priv->error_canvas = NULL;
}


/**
 * champlain_error_tile_renderer_new:
 * @tile_size: the size of the rendered error tile
 *
 * Constructor of a #ChamplainErrorTileRenderer.
 *
 * Returns: a constructed #ChamplainErrorTileRenderer
 *
 * Since: 0.8
 */
ChamplainErrorTileRenderer *
champlain_error_tile_renderer_new (guint tile_size)
{
  return g_object_new (CHAMPLAIN_TYPE_ERROR_TILE_RENDERER, 
      "tile-size", tile_size, 
      NULL);
}


static void
set_data (ChamplainRenderer *renderer, const gchar *data, guint size)
{
  /* always render the error tile no matter what data is set */
}


static gboolean
redraw_tile (ClutterCanvas *canvas,
    cairo_t *cr,
    gint w,
    gint h,
    ChamplainTile *tile)
{
  cairo_pattern_t *pat;
  gint size = w;
  
  champlain_exportable_set_surface (CHAMPLAIN_EXPORTABLE (tile), cairo_get_target (cr));

  /* draw a linear gray to white pattern */
  pat = cairo_pattern_create_linear (size / 2.0, 0.0, size, size / 2.0);
  cairo_pattern_add_color_stop_rgb (pat, 0, 0.686, 0.686, 0.686);
  cairo_pattern_add_color_stop_rgb (pat, 1, 0.925, 0.925, 0.925);
  cairo_set_source (cr, pat);
  cairo_rectangle (cr, 0, 0, size, size);
  cairo_fill (cr);

  cairo_pattern_destroy (pat);

  /* draw the red cross */
  cairo_set_source_rgb (cr, 0.424, 0.078, 0.078);
  cairo_set_line_width (cr, 14.0);
  cairo_set_line_cap (cr, CAIRO_LINE_CAP_ROUND);
  cairo_move_to (cr, 24, 24);
  cairo_line_to (cr, 50, 50);
  cairo_move_to (cr, 50, 24);
  cairo_line_to (cr, 24, 50);
  cairo_stroke (cr);
  
  return TRUE;
}


static void
render (ChamplainRenderer *renderer, ChamplainTile *tile)
{
  g_return_if_fail (CHAMPLAIN_IS_ERROR_TILE_RENDERER (renderer));
  g_return_if_fail (CHAMPLAIN_IS_TILE (tile));

  ChamplainErrorTileRenderer *error_renderer = CHAMPLAIN_ERROR_TILE_RENDERER (renderer);
  ChamplainErrorTileRendererPrivate *priv = error_renderer->priv;
  ClutterActor *actor;
  gpointer data = NULL;
  guint size = 0;
  gboolean error = FALSE;

  if (champlain_tile_get_state (tile) == CHAMPLAIN_STATE_LOADED)
    {
      /* cache is just validating tile - don't generate error tile in this case - instead use what we have */
      g_signal_emit_by_name (tile, "render-complete", data, size, error);
      return;
    }

  size = champlain_error_tile_renderer_get_tile_size (error_renderer);

  if (!priv->error_canvas)
    {
      priv->error_canvas = clutter_canvas_new ();
      clutter_canvas_set_size (CLUTTER_CANVAS (priv->error_canvas), size, size);
      g_signal_connect (priv->error_canvas, "draw", G_CALLBACK (redraw_tile), tile);
      clutter_content_invalidate (priv->error_canvas);
    }

  actor = clutter_actor_new ();
  clutter_actor_set_size (actor, size, size);
  clutter_actor_set_content (actor, priv->error_canvas);
  /* has to be set for proper opacity */
  clutter_actor_set_offscreen_redirect (actor, CLUTTER_OFFSCREEN_REDIRECT_AUTOMATIC_FOR_OPACITY);

  champlain_tile_set_content (tile, actor);
  g_signal_emit_by_name (tile, "render-complete", data, size, error);
}


/**
 * champlain_error_tile_renderer_set_tile_size:
 * @renderer: a #ChamplainErrorTileRenderer
 * @size: the size of the rendered error tiles
 *
 * Sets the size of the rendered error tile.
 *
 * Since: 0.8
 */
void
champlain_error_tile_renderer_set_tile_size (ChamplainErrorTileRenderer *renderer,
    guint size)
{
  g_return_if_fail (CHAMPLAIN_IS_ERROR_TILE_RENDERER (renderer));

  renderer->priv->tile_size = size;

  g_object_notify (G_OBJECT (renderer), "tile-size");
}


/**
 * champlain_error_tile_renderer_get_tile_size:
 * @renderer: a #ChamplainErrorTileRenderer
 *
 * Gets the size of the rendered error tiles.
 *
 * Returns: the size of the rendered error tiles
 *
 * Since: 0.8
 */
guint
champlain_error_tile_renderer_get_tile_size (ChamplainErrorTileRenderer *renderer)
{
  g_return_val_if_fail (CHAMPLAIN_IS_ERROR_TILE_RENDERER (renderer), 0);

  return renderer->priv->tile_size;
}
