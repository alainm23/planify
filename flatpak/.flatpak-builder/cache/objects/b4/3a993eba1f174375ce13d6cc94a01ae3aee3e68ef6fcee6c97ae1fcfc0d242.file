/*
 * Copyright (C) 2009 Pierre-Luc Beaudoin <pierre-luc@pierlux.com>
 * Copyright (C) 2011-2013 Jiri Techet <techet@gmail.com>
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

#ifndef CHAMPLAIN_MAP_SOURCE_DESC_H
#define CHAMPLAIN_MAP_SOURCE_DESC_H

#include <glib-object.h>
#include "champlain-tile-source.h"

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_MAP_SOURCE_DESC champlain_map_source_desc_get_type ()

#define CHAMPLAIN_MAP_SOURCE_DESC(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_DESC, ChamplainMapSourceDesc))

#define CHAMPLAIN_MAP_SOURCE_DESC_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_MAP_SOURCE_DESC, ChamplainMapSourceDescClass))

#define CHAMPLAIN_IS_MAP_SOURCE_DESC(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_DESC))

#define CHAMPLAIN_IS_MAP_SOURCE_DESC_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_MAP_SOURCE_DESC))

#define CHAMPLAIN_MAP_SOURCE_DESC_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_DESC, ChamplainMapSourceDescClass))

typedef struct _ChamplainMapSourceDescPrivate ChamplainMapSourceDescPrivate;

typedef struct _ChamplainMapSourceDesc ChamplainMapSourceDesc;
typedef struct _ChamplainMapSourceDescClass ChamplainMapSourceDescClass;

/**
 * ChamplainMapSourceDesc:
 *
 * The #ChamplainMapSourceDesc structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.10
 */
struct _ChamplainMapSourceDesc
{
  GObject parent_instance;

  ChamplainMapSourceDescPrivate *priv;
};

struct _ChamplainMapSourceDescClass
{
  GObjectClass parent_class;
};

/**
 * ChamplainMapSourceConstructor:
 * @desc: a #ChamplainMapSourceDesc
 *
 * A #ChamplainMapSource constructor.  It should return a ready to use
 * #ChamplainMapSource.
 *
 * Returns: A fully constructed #ChamplainMapSource ready to be used.
 *
 * Since: 0.10
 */
typedef ChamplainMapSource* (*ChamplainMapSourceConstructor) (ChamplainMapSourceDesc *desc);

/**
 * CHAMPLAIN_MAP_SOURCE_CONSTRUCTOR:
 *
 * Conversion macro to #ChamplainMapSourceConstructor.
 *
 * Since: 0.10
 */
#define CHAMPLAIN_MAP_SOURCE_CONSTRUCTOR (f) ((ChamplainMapSourceConstructor) (f))

GType champlain_map_source_desc_get_type (void);

ChamplainMapSourceDesc *champlain_map_source_desc_new_full (
    gchar *id,
    gchar *name,
    gchar *license,
    gchar *license_uri,
    guint min_zoom,
    guint max_zoom,
    guint tile_size,
    ChamplainMapProjection projection,
    gchar *uri_format,
    ChamplainMapSourceConstructor constructor,
    gpointer data);

const gchar *champlain_map_source_desc_get_id (ChamplainMapSourceDesc *desc);
const gchar *champlain_map_source_desc_get_name (ChamplainMapSourceDesc *desc);
const gchar *champlain_map_source_desc_get_license (ChamplainMapSourceDesc *desc);
const gchar *champlain_map_source_desc_get_license_uri (ChamplainMapSourceDesc *desc);
const gchar *champlain_map_source_desc_get_uri_format (ChamplainMapSourceDesc *desc);
guint champlain_map_source_desc_get_min_zoom_level (ChamplainMapSourceDesc *desc);
guint champlain_map_source_desc_get_max_zoom_level (ChamplainMapSourceDesc *desc);
guint champlain_map_source_desc_get_tile_size (ChamplainMapSourceDesc *desc);
ChamplainMapProjection champlain_map_source_desc_get_projection (ChamplainMapSourceDesc *desc);
gpointer champlain_map_source_desc_get_data (ChamplainMapSourceDesc *desc);
ChamplainMapSourceConstructor champlain_map_source_desc_get_constructor (ChamplainMapSourceDesc *desc);

G_END_DECLS

#endif
