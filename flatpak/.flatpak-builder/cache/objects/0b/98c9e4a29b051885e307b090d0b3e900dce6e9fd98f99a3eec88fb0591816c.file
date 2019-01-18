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

#ifndef _CHAMPLAIN_NULL_TILE_SOURCE
#define _CHAMPLAIN_NULL_TILE_SOURCE

#include <glib-object.h>

#include <champlain/champlain-tile-source.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_NULL_TILE_SOURCE champlain_null_tile_source_get_type ()

#define CHAMPLAIN_NULL_TILE_SOURCE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_NULL_TILE_SOURCE, ChamplainNullTileSource))

#define CHAMPLAIN_NULL_TILE_SOURCE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_NULL_TILE_SOURCE, ChamplainNullTileSourceClass))

#define CHAMPLAIN_IS_NULL_TILE_SOURCE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_NULL_TILE_SOURCE))

#define CHAMPLAIN_IS_NULL_TILE_SOURCE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_NULL_TILE_SOURCE))

#define CHAMPLAIN_NULL_TILE_SOURCE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_NULL_TILE_SOURCE, ChamplainNullTileSourceClass))

typedef struct _ChamplainNullTileSourcePrivate ChamplainNullTileSourcePrivate;

/**
 * ChamplainNullTileSource:
 *
 * The #ChamplainNullTileSource structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.8
 */
typedef struct _ChamplainNullTileSource ChamplainNullTileSource;
typedef struct _ChamplainNullTileSourceClass ChamplainNullTileSourceClass;

struct _ChamplainNullTileSource
{
  ChamplainTileSource parent;
};

struct _ChamplainNullTileSourceClass
{
  ChamplainTileSourceClass parent_class;
};

GType champlain_null_tile_source_get_type (void);

ChamplainNullTileSource *champlain_null_tile_source_new_full (ChamplainRenderer *renderer);


G_END_DECLS

#endif /* _CHAMPLAIN_NULL_TILE_SOURCE */
