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

#ifndef __CHAMPLAIN_ERROR_TILE_RENDERER_H__
#define __CHAMPLAIN_ERROR_TILE_RENDERER_H__

#include <champlain/champlain-tile.h>
#include <champlain/champlain-renderer.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_ERROR_TILE_RENDERER champlain_error_tile_renderer_get_type ()

#define CHAMPLAIN_ERROR_TILE_RENDERER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_ERROR_TILE_RENDERER, ChamplainErrorTileRenderer))

#define CHAMPLAIN_ERROR_TILE_RENDERER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_ERROR_TILE_RENDERER, ChamplainErrorTileRendererClass))

#define CHAMPLAIN_IS_ERROR_TILE_RENDERER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_ERROR_TILE_RENDERER))

#define CHAMPLAIN_IS_ERROR_TILE_RENDERER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_ERROR_TILE_RENDERER))

#define CHAMPLAIN_ERROR_TILE_RENDERER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_ERROR_TILE_RENDERER, ChamplainErrorTileRendererClass))

typedef struct _ChamplainErrorTileRendererPrivate ChamplainErrorTileRendererPrivate;

typedef struct _ChamplainErrorTileRenderer ChamplainErrorTileRenderer;
typedef struct _ChamplainErrorTileRendererClass ChamplainErrorTileRendererClass;

/**
 * ChamplainErrorTileRenderer:
 *
 * The #ChamplainErrorTileRenderer structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.8
 */
struct _ChamplainErrorTileRenderer
{
  ChamplainRenderer parent;

  ChamplainErrorTileRendererPrivate *priv;
};

struct _ChamplainErrorTileRendererClass
{
  ChamplainRendererClass parent_class;
};


GType champlain_error_tile_renderer_get_type (void);

ChamplainErrorTileRenderer *champlain_error_tile_renderer_new (guint tile_size);

void champlain_error_tile_renderer_set_tile_size (ChamplainErrorTileRenderer *renderer,
    guint size);

guint champlain_error_tile_renderer_get_tile_size (ChamplainErrorTileRenderer *renderer);


G_END_DECLS

#endif /* __CHAMPLAIN_ERROR_TILE_RENDERER_H__ */
