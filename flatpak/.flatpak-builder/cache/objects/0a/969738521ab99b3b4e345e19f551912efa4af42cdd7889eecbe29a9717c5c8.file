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

#if !defined (__CHAMPLAIN_CHAMPLAIN_H_INSIDE__) && !defined (CHAMPLAIN_COMPILATION)
#error "Only <champlain/champlain.h> can be included directly."
#endif

#ifndef _CHAMPLAIN_NETWORK_TILE_SOURCE_H_
#define _CHAMPLAIN_NETWORK_TILE_SOURCE_H_

#include <champlain/champlain-defines.h>
#include <champlain/champlain-tile-source.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_NETWORK_TILE_SOURCE champlain_network_tile_source_get_type ()

#define CHAMPLAIN_NETWORK_TILE_SOURCE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_NETWORK_TILE_SOURCE, ChamplainNetworkTileSource))

#define CHAMPLAIN_NETWORK_TILE_SOURCE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_NETWORK_TILE_SOURCE, ChamplainNetworkTileSourceClass))

#define CHAMPLAIN_IS_NETWORK_TILE_SOURCE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_NETWORK_TILE_SOURCE))

#define CHAMPLAIN_IS_NETWORK_TILE_SOURCE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_NETWORK_TILE_SOURCE))

#define CHAMPLAIN_NETWORK_TILE_SOURCE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_NETWORK_TILE_SOURCE, ChamplainNetworkTileSourceClass))

typedef struct _ChamplainNetworkTileSourcePrivate ChamplainNetworkTileSourcePrivate;

typedef struct _ChamplainNetworkTileSource ChamplainNetworkTileSource;
typedef struct _ChamplainNetworkTileSourceClass ChamplainNetworkTileSourceClass;

/**
 * ChamplainNetworkTileSource:
 *
 * The #ChamplainNetworkTileSource structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.6
 */
struct _ChamplainNetworkTileSource
{
  ChamplainTileSource parent_instance;

  ChamplainNetworkTileSourcePrivate *priv;
};

struct _ChamplainNetworkTileSourceClass
{
  ChamplainTileSourceClass parent_class;
};

GType champlain_network_tile_source_get_type (void);

ChamplainNetworkTileSource *champlain_network_tile_source_new_full (const gchar *id,
    const gchar *name,
    const gchar *license,
    const gchar *license_uri,
    guint min_zoom,
    guint max_zoom,
    guint tile_size,
    ChamplainMapProjection projection,
    const gchar *uri_format,
    ChamplainRenderer *renderer);

const gchar *champlain_network_tile_source_get_uri_format (ChamplainNetworkTileSource *tile_source);
void champlain_network_tile_source_set_uri_format (ChamplainNetworkTileSource *tile_source,
    const gchar *uri_format);

gboolean champlain_network_tile_source_get_offline (ChamplainNetworkTileSource *tile_source);
void champlain_network_tile_source_set_offline (ChamplainNetworkTileSource *tile_source,
    gboolean offline);

const gchar *champlain_network_tile_source_get_proxy_uri (ChamplainNetworkTileSource *tile_source);
void champlain_network_tile_source_set_proxy_uri (ChamplainNetworkTileSource *tile_source,
    const gchar *proxy_uri);

gint champlain_network_tile_source_get_max_conns (ChamplainNetworkTileSource *tile_source);
void champlain_network_tile_source_set_max_conns (ChamplainNetworkTileSource *tile_source,
    gint max_conns);

void champlain_network_tile_source_set_user_agent (ChamplainNetworkTileSource *tile_source,
    const gchar *user_agent);

G_END_DECLS

#endif /* _CHAMPLAIN_NETWORK_TILE_SOURCE_H_ */
