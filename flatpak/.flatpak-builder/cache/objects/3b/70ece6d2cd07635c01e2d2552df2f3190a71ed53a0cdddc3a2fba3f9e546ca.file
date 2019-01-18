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

/**
 * SECTION:champlain-network-bbox-tile-source
 * @short_description: A map source that loads tile data from an OpenStreetMap API
 * server
 *
 * This map source source downloads the map data from an OpenStreetMap API
 * server. It supports protocol version 0.5 and 0.6.
 *
 * <ulink role="online-location" url="http://wiki.openstreetmap.org/wiki/API">
 * http://wiki.openstreetmap.org/wiki/API</ulink>
 */

#include "champlain-network-bbox-tile-source.h"

#define DEBUG_FLAG CHAMPLAIN_DEBUG_LOADING
#include "champlain-debug.h"
#include "champlain-bounding-box.h"
#include "champlain-enum-types.h"
#include "champlain-version.h"
#include "champlain-tile.h"

#include <libsoup/soup.h>

G_DEFINE_TYPE (ChamplainNetworkBboxTileSource, champlain_network_bbox_tile_source, CHAMPLAIN_TYPE_TILE_SOURCE)

#define GET_PRIVATE(o) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((o), CHAMPLAIN_TYPE_NETWORK_BBOX_TILE_SOURCE, ChamplainNetworkBboxTileSourcePrivate))

enum
{
  PROP_0,
  PROP_API_URI,
  PROP_PROXY_URI,
  PROP_STATE,
  PROP_USER_AGENT
};

struct _ChamplainNetworkBboxTileSourcePrivate
{
  gchar *api_uri;
  gchar *proxy_uri;
  SoupSession *soup_session;
  ChamplainState state;
};

static void fill_tile (ChamplainMapSource *map_source,
    ChamplainTile *tile);


static void
champlain_network_bbox_tile_source_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  ChamplainNetworkBboxTileSource *self =
    CHAMPLAIN_NETWORK_BBOX_TILE_SOURCE (object);
  ChamplainNetworkBboxTileSourcePrivate *priv = self->priv;

  switch (property_id)
    {
    case PROP_API_URI:
      g_value_set_string (value,
          champlain_network_bbox_tile_source_get_api_uri (self));
      break;

    case PROP_PROXY_URI:
      g_value_set_string (value, priv->proxy_uri);
      break;

    case PROP_STATE:
      g_value_set_enum (value, priv->state);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}


static void
champlain_network_bbox_tile_source_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  ChamplainNetworkBboxTileSource *self =
    CHAMPLAIN_NETWORK_BBOX_TILE_SOURCE (object);
  ChamplainNetworkBboxTileSourcePrivate *priv = self->priv;

  switch (property_id)
    {
    case PROP_API_URI:
      champlain_network_bbox_tile_source_set_api_uri (self,
          g_value_get_string (value));
      break;

    case PROP_PROXY_URI:
      g_free (priv->proxy_uri);

      priv->proxy_uri = g_value_dup_string (value);
      if (priv->soup_session)
        g_object_set (G_OBJECT (priv->soup_session), "proxy-uri",
            soup_uri_new (priv->proxy_uri), NULL);
      break;

    case PROP_STATE:
      priv->state = g_value_get_enum (value);
      g_object_notify (G_OBJECT (self), "state");
      break;

    case PROP_USER_AGENT:
      champlain_network_bbox_tile_source_set_user_agent (self,
          g_value_get_string (value));
     break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}


static void
champlain_network_bbox_tile_source_dispose (GObject *object)
{
  ChamplainNetworkBboxTileSource *self =
    CHAMPLAIN_NETWORK_BBOX_TILE_SOURCE (object);
  ChamplainNetworkBboxTileSourcePrivate *priv = self->priv;

  if (priv->soup_session != NULL)
    {
      soup_session_abort (priv->soup_session);
      priv->soup_session = NULL;
    }

  G_OBJECT_CLASS (champlain_network_bbox_tile_source_parent_class)->dispose (object);
}


static void
champlain_network_bbox_tile_source_finalize (GObject *object)
{
  ChamplainNetworkBboxTileSource *self =
    CHAMPLAIN_NETWORK_BBOX_TILE_SOURCE (object);
  ChamplainNetworkBboxTileSourcePrivate *priv = self->priv;

  g_free (priv->api_uri);
  g_free (priv->proxy_uri);

  G_OBJECT_CLASS (champlain_network_bbox_tile_source_parent_class)->finalize (object);
}


static void
champlain_network_bbox_tile_source_class_init (ChamplainNetworkBboxTileSourceClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (ChamplainNetworkBboxTileSourcePrivate));

  object_class->get_property = champlain_network_bbox_tile_source_get_property;
  object_class->set_property = champlain_network_bbox_tile_source_set_property;
  object_class->dispose = champlain_network_bbox_tile_source_dispose;
  object_class->finalize = champlain_network_bbox_tile_source_finalize;

  ChamplainMapSourceClass *map_source_class = CHAMPLAIN_MAP_SOURCE_CLASS (klass);
  map_source_class->fill_tile = fill_tile;

  /**
   * ChamplainNetworkBboxTileSource:api-uri:
   *
   * The URI of an OpenStreetMap API server
   *
   * Since: 0.8
   */
  g_object_class_install_property (object_class,
      PROP_API_URI,
      g_param_spec_string ("api-uri",
          "API URI",
          "The API URI of an OpenStreetMap server",
          "http://www.informationfreeway.org/api/0.6",
          G_PARAM_READWRITE));

  /**
   * ChamplainNetworkBboxTileSource:proxy-uri:
   *
   * Used to override the default proxy for accessing the network.
   *
   * Since: 0.8
   */
  g_object_class_install_property (object_class,
      PROP_PROXY_URI,
      g_param_spec_string ("proxy-uri",
          "Proxy URI",
          "The proxy URI to use to access network",
          "",
          G_PARAM_READWRITE));

  /**
   * ChamplainNetworkBboxTileSource:state:
   *
   * The map source's state. Useful to know if the data source is loading
   * or not.
   *
   * Since: 0.8
   */
  g_object_class_install_property (object_class,
      PROP_STATE,
      g_param_spec_enum ("state",
          "map data source's state",
          "The state of the map data source",
          CHAMPLAIN_TYPE_STATE,
          CHAMPLAIN_STATE_NONE,
          G_PARAM_READWRITE));

  /**
   * ChamplainNetworkBboxTileSource:user-agent:
   *
   * The HTTP user agent used for requests
   *
   * Since: 0.12.16
   */
  g_object_class_install_property (object_class,
      PROP_USER_AGENT,
      g_param_spec_string ("user-agent",
        "HTTP User Agent",
        "The HTTP user agent used for network requests",
        "libchamplain/" CHAMPLAIN_VERSION_S,
        G_PARAM_WRITABLE));
}


static void
champlain_network_bbox_tile_source_init (ChamplainNetworkBboxTileSource *self)
{
  ChamplainNetworkBboxTileSourcePrivate *priv = GET_PRIVATE (self);

  self->priv = priv;

  priv->api_uri = g_strdup ("http://www.informationfreeway.org/api/0.6");
  /* informationfreeway.org is a load-balancer for different api servers */
  priv->proxy_uri = g_strdup ("");
  priv->soup_session = soup_session_new_with_options (
        "proxy-uri", soup_uri_new (priv->proxy_uri),
        "ssl-strict", FALSE,
        SOUP_SESSION_ADD_FEATURE_BY_TYPE, 
        SOUP_TYPE_PROXY_RESOLVER_DEFAULT,
        NULL);
  g_object_set (G_OBJECT (priv->soup_session),
      "user-agent", 
      "libchamplain/" CHAMPLAIN_VERSION_S,
      "max-conns-per-host", 2, 
      NULL);

  priv->state = CHAMPLAIN_STATE_NONE;
}


/**
 * champlain_network_bbox_tile_source_new_full:
 * @id: the map source's id
 * @name: the map source's name
 * @license: the map source's license
 * @license_uri: the map source's license URI
 * @min_zoom: the map source's minimum zoom level
 * @max_zoom: the map source's maximum zoom level
 * @tile_size: the map source's tile size (in pixels)
 * @projection: the map source's projection
 * @renderer: the #ChamplainRenderer used to render tiles
 *
 * Constructor of #ChamplainNetworkBboxTileSource.
 *
 * Returns: a constructed #ChamplainNetworkBboxTileSource object
 *
 * Since: 0.8
 */
ChamplainNetworkBboxTileSource *
champlain_network_bbox_tile_source_new_full (const gchar *id,
    const gchar *name,
    const gchar *license,
    const gchar *license_uri,
    guint min_zoom,
    guint max_zoom,
    guint tile_size,
    ChamplainMapProjection projection,
    ChamplainRenderer *renderer)
{
  ChamplainNetworkBboxTileSource *source;

  source = g_object_new (CHAMPLAIN_TYPE_NETWORK_BBOX_TILE_SOURCE, "id", id,
        "name", name,
        "license", license,
        "license-uri", license_uri,
        "min-zoom-level", min_zoom,
        "max-zoom-level", max_zoom,
        "tile-size", tile_size,
        "projection", projection,
        "renderer", renderer,
        NULL);
  return source;
}


static void
load_map_data_cb (G_GNUC_UNUSED SoupSession *session, SoupMessage *msg,
    gpointer user_data)
{
  ChamplainNetworkBboxTileSource *self =
    CHAMPLAIN_NETWORK_BBOX_TILE_SOURCE (user_data);
  ChamplainRenderer *renderer;

  if (!SOUP_STATUS_IS_SUCCESSFUL (msg->status_code))
    {
      DEBUG ("Unable to download file: %s",
          soup_status_get_phrase (msg->status_code));

      return;
    }

  g_object_set (G_OBJECT (self), "state", CHAMPLAIN_STATE_DONE, NULL);

  renderer = champlain_map_source_get_renderer (CHAMPLAIN_MAP_SOURCE (self));
  champlain_renderer_set_data (renderer, msg->response_body->data, msg->response_body->length);
}


/**
 * champlain_network_bbox_tile_source_load_map_data:
 * @map_data_source: a #ChamplainNetworkBboxTileSource
 * @bbox: bounding box of the requested area
 *
 * Asynchronously loads map data within a bounding box from the server.
 * The box must not exceed an edge size of 0.25 degree. There are also
 * limitations on the maximum number of nodes that can be requested.
 *
 * For details, see: <ulink role="online-location"
 * url="http://api.openstreetmap.org/api/capabilities">
 * http://api.openstreetmap.org/api/capabilities</ulink>
 *
 * Since: 0.10
 */
void
champlain_network_bbox_tile_source_load_map_data (
    ChamplainNetworkBboxTileSource *self,
    ChamplainBoundingBox *bbox)
{
  g_return_if_fail (CHAMPLAIN_IS_NETWORK_BBOX_TILE_SOURCE (self));

  g_return_if_fail (bbox->right - bbox->left < 0.25 &&
      bbox->top - bbox->bottom < 0.25);

  ChamplainNetworkBboxTileSourcePrivate *priv = self->priv;
  SoupMessage *msg;
  gchar *url;

  url = g_strdup_printf (
        "http://api.openstreetmap.org/api/0.6/map?bbox=%f,%f,%f,%f",
        bbox->left, bbox->bottom, bbox->right, bbox->top);
  msg = soup_message_new ("GET", url);

  DEBUG ("Request BBox data: '%s'", url);

  g_free (url);

  g_object_set (G_OBJECT (self), "state", CHAMPLAIN_STATE_LOADING, NULL);

  soup_session_queue_message (priv->soup_session, msg, load_map_data_cb, self);
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
  g_return_if_fail (CHAMPLAIN_IS_NETWORK_BBOX_TILE_SOURCE (map_source));
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


/**
 * champlain_network_bbox_tile_source_get_api_uri:
 * @map_data_source: a #ChamplainNetworkBboxTileSource
 *
 * Gets the URI of the API server.
 *
 * Returns: the URI of the API server.
 *
 * Since: 0.8
 */
const gchar *
champlain_network_bbox_tile_source_get_api_uri (
    ChamplainNetworkBboxTileSource *self)
{
  g_return_val_if_fail (CHAMPLAIN_IS_NETWORK_BBOX_TILE_SOURCE (self), NULL);

  return self->priv->api_uri;
}


/**
 * champlain_network_bbox_tile_source_set_api_uri:
 * @map_data_source: a #ChamplainNetworkBboxTileSource
 * @api_uri: an URI of an API server
 *
 * Sets the URI of the API server.
 *
 * Since: 0.8
 */
void
champlain_network_bbox_tile_source_set_api_uri (
    ChamplainNetworkBboxTileSource *self,
    const gchar *api_uri)
{
  g_return_if_fail (CHAMPLAIN_IS_NETWORK_BBOX_TILE_SOURCE (self)
      && api_uri != NULL);

  ChamplainNetworkBboxTileSourcePrivate *priv = self->priv;

  g_free (priv->api_uri);
  priv->api_uri = g_strdup (api_uri);
  g_object_notify (G_OBJECT (self), "api-uri");
}


/**
 * champlain_network_bbox_tile_source_set_user_agent:
 * @map_data_source: a #ChamplainNetworkBboxTileSource
 * @user_agent: A User-Agent string
 *
 * Sets the User-Agent header used communicating with the server.
 * Since: 0.12.16
 */
void
champlain_network_bbox_tile_source_set_user_agent (
    ChamplainNetworkBboxTileSource *self,
    const gchar *user_agent)
{
  g_return_if_fail (CHAMPLAIN_IS_NETWORK_BBOX_TILE_SOURCE (self)
      && user_agent != NULL);

  ChamplainNetworkBboxTileSourcePrivate *priv = self->priv;

  if (priv->soup_session)
    g_object_set (G_OBJECT (priv->soup_session), "user-agent",
        user_agent, NULL);
}
