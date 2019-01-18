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

#ifndef CHAMPLAIN_MAP_TILE_H
#define CHAMPLAIN_MAP_TILE_H

#include <champlain/champlain-defines.h>
#include <champlain/champlain-exportable.h>

#include <glib.h>
#include <clutter/clutter.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_TILE champlain_tile_get_type ()

#define CHAMPLAIN_TILE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_TILE, ChamplainTile))

#define CHAMPLAIN_TILE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_TILE, ChamplainTileClass))

#define CHAMPLAIN_IS_TILE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_TILE))

#define CHAMPLAIN_IS_TILE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_TILE))

#define CHAMPLAIN_TILE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_TILE, ChamplainTileClass))

typedef struct _ChamplainTilePrivate ChamplainTilePrivate;

typedef struct _ChamplainTile ChamplainTile;
typedef struct _ChamplainTileClass ChamplainTileClass;

/**
 * ChamplainState:
 * @CHAMPLAIN_STATE_NONE: Initial or undefined state
 * @CHAMPLAIN_STATE_LOADING: Tile is loading
 * @CHAMPLAIN_STATE_LOADED: Tile is loaded but not yet displayed
 * @CHAMPLAIN_STATE_DONE: Tile loading finished. Also used to inform map sources
 *     that tile loading has been cancelled.
 *
 * Tile loading state.
 */
typedef enum
{
  CHAMPLAIN_STATE_NONE,
  CHAMPLAIN_STATE_LOADING,
  CHAMPLAIN_STATE_LOADED,
  CHAMPLAIN_STATE_DONE
} ChamplainState;


/**
 * ChamplainTile:
 *
 * The #ChamplainTile structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.4
 */
struct _ChamplainTile
{
  ClutterActor parent;

  ChamplainTilePrivate *priv;
};

struct _ChamplainTileClass
{
  ClutterActorClass parent_class;
};


GType champlain_tile_get_type (void);

ChamplainTile *champlain_tile_new (void);
ChamplainTile *champlain_tile_new_full (guint x,
    guint y,
    guint size,
    guint zoom_level);

guint champlain_tile_get_x (ChamplainTile *self);
guint champlain_tile_get_y (ChamplainTile *self);
guint champlain_tile_get_zoom_level (ChamplainTile *self);
guint champlain_tile_get_size (ChamplainTile *self);
ChamplainState champlain_tile_get_state (ChamplainTile *self);
ClutterActor *champlain_tile_get_content (ChamplainTile *self);
const GTimeVal *champlain_tile_get_modified_time (ChamplainTile *self);
const gchar *champlain_tile_get_etag (ChamplainTile *self);
gboolean champlain_tile_get_fade_in (ChamplainTile *self);

void champlain_tile_set_x (ChamplainTile *self,
    guint x);
void champlain_tile_set_y (ChamplainTile *self,
    guint y);
void champlain_tile_set_zoom_level (ChamplainTile *self,
    guint zoom_level);
void champlain_tile_set_size (ChamplainTile *self,
    guint size);
void champlain_tile_set_state (ChamplainTile *self,
    ChamplainState state);
void champlain_tile_set_content (ChamplainTile *self,
    ClutterActor *actor);
void champlain_tile_set_etag (ChamplainTile *self,
    const gchar *etag);
void champlain_tile_set_modified_time (ChamplainTile *self,
    const GTimeVal *time);
void champlain_tile_set_fade_in (ChamplainTile *self,
    gboolean fade_in);

void champlain_tile_display_content (ChamplainTile *self);

G_END_DECLS

#endif /* CHAMPLAIN_MAP_TILE_H */
