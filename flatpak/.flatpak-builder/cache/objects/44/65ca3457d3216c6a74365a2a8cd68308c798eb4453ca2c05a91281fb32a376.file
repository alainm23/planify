/*
 * Copyright (C) 2009 Simon Wenner <simon@wenner.ch>
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

#ifndef _CHAMPLAIN_FILE_TILE_SOURCE
#define _CHAMPLAIN_FILE_TILE_SOURCE

#include <glib-object.h>

#include <champlain/champlain-tile-source.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_FILE_TILE_SOURCE champlain_file_tile_source_get_type ()

#define CHAMPLAIN_FILE_TILE_SOURCE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_FILE_TILE_SOURCE, ChamplainFileTileSource))

#define CHAMPLAIN_FILE_TILE_SOURCE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_FILE_TILE_SOURCE, ChamplainFileTileSourceClass))

#define CHAMPLAIN_IS_FILE_TILE_SOURCE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_FILE_TILE_SOURCE))

#define CHAMPLAIN_IS_FILE_TILE_SOURCE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_FILE_TILE_SOURCE))

#define CHAMPLAIN_FILE_TILE_SOURCE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_FILE_TILE_SOURCE, ChamplainFileTileSourceClass))

typedef struct _ChamplainFileTileSourcePrivate ChamplainFileTileSourcePrivate;

typedef struct _ChamplainFileTileSource ChamplainFileTileSource;
typedef struct _ChamplainFileTileSourceClass ChamplainFileTileSourceClass;

/**
 * ChamplainFileTileSource:
 *
 * The #ChamplainFileTileSource structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.8
 */
struct _ChamplainFileTileSource
{
  ChamplainTileSource parent;
};

struct _ChamplainFileTileSourceClass
{
  ChamplainTileSourceClass parent_class;
};

GType champlain_file_tile_source_get_type (void);

ChamplainFileTileSource *champlain_file_tile_source_new_full (const gchar *id,
    const gchar *name,
    const gchar *license,
    const gchar *license_uri,
    guint min_zoom,
    guint max_zoom,
    guint tile_size,
    ChamplainMapProjection projection,
    ChamplainRenderer *renderer);

void champlain_file_tile_source_load_map_data (
    ChamplainFileTileSource *self,
    const gchar *map_path);

G_END_DECLS

#endif /* _CHAMPLAIN_FILE_TILE_SOURCE */
