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

/**
 * SECTION:champlain-network-tile-source
 * @short_description: A map source that downloads tile data from a web server
 *
 * This class is specialized for map tiles that can be downloaded
 * from a web server.  This includes all web based map services such as
 * OpenStreetMap, Google Maps, Yahoo Maps and more.  This class contains
 * all mechanisms necessary to download tiles.
 *
 * Some preconfigured network map sources are built-in this library,
 * see #ChamplainMapSourceFactory.
 *
 */

#include "config.h"

#include "champlain-network-tile-source.h"

#define DEBUG_FLAG CHAMPLAIN_DEBUG_LOADING
#include "champlain-debug.h"

#include "champlain.h"
#include "champlain-defines.h"
#include "champlain-enum-types.h"
#include "champlain-map-source.h"
#include "champlain-marshal.h"
#include "champlain-private.h"

#include <errno.h>
#include <gdk/gdk.h>
#include <gio/gio.h>
#include <glib.h>
#include <glib/gstdio.h>
#include <glib-object.h>
#include <libsoup/soup.h>
#include <math.h>
#include <sys/stat.h>
#include <string.h>

enum
{
  PROP_0,
  PROP_URI_FORMAT,
  PROP_OFFLINE,
  PROP_PROXY_URI,
  PROP_MAX_CONNS,
  PROP_USER_AGENT
};

G_DEFINE_TYPE (ChamplainNetworkTileSource, champlain_network_tile_source, CHAMPLAIN_TYPE_TILE_SOURCE);

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), CHAMPLAIN_TYPE_NETWORK_TILE_SOURCE, ChamplainNetworkTileSourcePrivate))

/* The osm.org tile set require us to use no more than 2 simultaneous
 * connections so let that be the default.
 */
#define MAX_CONNS_DEFAULT 2

struct _ChamplainNetworkTileSourcePrivate
{
  gboolean offline;
  gchar *uri_format;
  gchar *proxy_uri;
  SoupSession *soup_session;
  gint max_conns;
};

typedef struct
{
  ChamplainMapSource *map_source;
  SoupMessage *msg;
} TileCancelledData;

typedef struct
{
  ChamplainMapSource *map_source;
  ChamplainTile *tile;
  TileCancelledData *cancelled_data;
} TileLoadedData;

typedef struct
{
  ChamplainMapSource *map_source;
  gchar *etag;
} TileRenderedData;


static void fill_tile (ChamplainMapSource *map_source,
    ChamplainTile *tile);
static void tile_state_notify (ChamplainTile *tile,
    G_GNUC_UNUSED GParamSpec *pspec,
    TileCancelledData *data);

static gchar *get_tile_uri (ChamplainNetworkTileSource *source,
    gint x,
    gint y,
    gint z);

static void
champlain_network_tile_source_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  ChamplainNetworkTileSourcePrivate *priv = CHAMPLAIN_NETWORK_TILE_SOURCE (object)->priv;

  switch (prop_id)
    {
    case PROP_URI_FORMAT:
      g_value_set_string (value, priv->uri_format);
      break;

    case PROP_OFFLINE:
      g_value_set_boolean (value, priv->offline);
      break;

    case PROP_PROXY_URI:
      g_value_set_string (value, priv->proxy_uri);
      break;

    case PROP_MAX_CONNS:
      g_value_set_int (value, priv->max_conns);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
champlain_network_tile_source_set_property (GObject *object,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec)
{
  ChamplainNetworkTileSource *tile_source = CHAMPLAIN_NETWORK_TILE_SOURCE (object);

  switch (prop_id)
    {
    case PROP_URI_FORMAT:
      champlain_network_tile_source_set_uri_format (tile_source, g_value_get_string (value));
      break;

    case PROP_OFFLINE:
      champlain_network_tile_source_set_offline (tile_source, g_value_get_boolean (value));
      break;

    case PROP_PROXY_URI:
      champlain_network_tile_source_set_proxy_uri (tile_source, g_value_get_string (value));
      break;

    case PROP_MAX_CONNS:
      champlain_network_tile_source_set_max_conns (tile_source, g_value_get_int (value));
      break;

    case PROP_USER_AGENT:
      champlain_network_tile_source_set_user_agent (tile_source, g_value_get_string (value));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
champlain_network_tile_source_dispose (GObject *object)
{
  ChamplainNetworkTileSourcePrivate *priv = CHAMPLAIN_NETWORK_TILE_SOURCE (object)->priv;

  if (priv->soup_session)
    {
      soup_session_abort (priv->soup_session);
      g_object_unref (priv->soup_session);
      priv->soup_session = NULL;
    }

  G_OBJECT_CLASS (champlain_network_tile_source_parent_class)->dispose (object);
}


static void
champlain_network_tile_source_finalize (GObject *object)
{
  ChamplainNetworkTileSourcePrivate *priv = CHAMPLAIN_NETWORK_TILE_SOURCE (object)->priv;

  g_free (priv->uri_format);
  g_free (priv->proxy_uri);

  G_OBJECT_CLASS (champlain_network_tile_source_parent_class)->finalize (object);
}


static void
champlain_network_tile_source_constructed (GObject *object)
{
  G_OBJECT_CLASS (champlain_network_tile_source_parent_class)->constructed (object);
}


static void
champlain_network_tile_source_class_init (ChamplainNetworkTileSourceClass *klass)
{
  ChamplainMapSourceClass *map_source_class = CHAMPLAIN_MAP_SOURCE_CLASS (klass);
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GParamSpec *pspec;

  g_type_class_add_private (klass, sizeof (ChamplainNetworkTileSourcePrivate));

  object_class->finalize = champlain_network_tile_source_finalize;
  object_class->dispose = champlain_network_tile_source_dispose;
  object_class->get_property = champlain_network_tile_source_get_property;
  object_class->set_property = champlain_network_tile_source_set_property;
  object_class->constructed = champlain_network_tile_source_constructed;

  map_source_class->fill_tile = fill_tile;

  /**
   * ChamplainNetworkTileSource:uri-format:
   *
   * The uri format of the tile source, see #champlain_network_tile_source_set_uri_format
   *
   * Since: 0.4
   */
  pspec = g_param_spec_string ("uri-format",
        "URI Format",
        "The URI format",
        "",
        G_PARAM_READWRITE | G_PARAM_CONSTRUCT);
  g_object_class_install_property (object_class, PROP_URI_FORMAT, pspec);

  /**
   * ChamplainNetworkTileSource:offline:
   *
   * Specifies whether the network tile source can access network
   *
   * Since: 0.4
   */
  pspec = g_param_spec_boolean ("offline",
        "Offline",
        "Offline",
        FALSE,
        G_PARAM_READWRITE);
  g_object_class_install_property (object_class, PROP_OFFLINE, pspec);

  /**
   * ChamplainNetworkTileSource:proxy-uri:
   *
   * Used to override the default proxy for accessing the network.
   *
   * Since: 0.4
   */
  pspec = g_param_spec_string ("proxy-uri",
        "Proxy URI",
        "The proxy URI to use to access network",
        "",
        G_PARAM_READWRITE);
  g_object_class_install_property (object_class, PROP_PROXY_URI, pspec);

  /**
   * ChamplainNetworkTileSource:max-conns:
   *
   * Specifies the max number of allowed simultaneous connections for this tile
   * source.
   *
   * Before changing this remember to verify how many simultaneous connections
   * your tile provider allows you to make.
   *
   * Since: 0.12.14
   */
  pspec = g_param_spec_int ("max-conns",
        "Max Connection Count",
        "The maximum number of allowed simultaneous connections "
        "for this tile source.",
        1,
        G_MAXINT,
        MAX_CONNS_DEFAULT,
        G_PARAM_READWRITE);

  g_object_class_install_property (object_class, PROP_MAX_CONNS, pspec);

  /**
   * ChamplainNetworkTileSource:user-agent:
   *
   * The HTTP user agent used for requests
   *
   * Since: 0.12.16
   */
  pspec = g_param_spec_string ("user-agent",
        "HTTP User Agent",
        "The HTTP user agent used for network requests",
        "libchamplain/" CHAMPLAIN_VERSION_S,
        G_PARAM_WRITABLE);

  g_object_class_install_property (object_class, PROP_USER_AGENT, pspec);
}


static void
champlain_network_tile_source_init (ChamplainNetworkTileSource *tile_source)
{
  ChamplainNetworkTileSourcePrivate *priv = GET_PRIVATE (tile_source);

  tile_source->priv = priv;

  priv->proxy_uri = NULL;
  priv->uri_format = NULL;
  priv->offline = FALSE;
  priv->max_conns = MAX_CONNS_DEFAULT;

  priv->soup_session = soup_session_new_with_options (
        "proxy-uri", NULL,
        "ssl-strict", FALSE,
        SOUP_SESSION_ADD_FEATURE_BY_TYPE, 
        SOUP_TYPE_PROXY_RESOLVER_DEFAULT,
        SOUP_SESSION_ADD_FEATURE_BY_TYPE,
        SOUP_TYPE_CONTENT_DECODER,
        NULL);
  g_object_set (G_OBJECT (priv->soup_session),
      "user-agent", 
      "libchamplain/" CHAMPLAIN_VERSION_S,
      "max-conns-per-host", MAX_CONNS_DEFAULT,
      "max-conns", MAX_CONNS_DEFAULT,
      NULL);
}


/**
 * champlain_network_tile_source_new_full:
 * @id: the map source's id
 * @name: the map source's name
 * @license: the map source's license
 * @license_uri: the map source's license URI
 * @min_zoom: the map source's minimum zoom level
 * @max_zoom: the map source's maximum zoom level
 * @tile_size: the map source's tile size (in pixels)
 * @projection: the map source's projection
 * @uri_format: the URI to fetch the tiles from, see #champlain_network_tile_source_set_uri_format
 * @renderer: the #ChamplainRenderer used to render tiles
 *
 * Constructor of #ChamplainNetworkTileSource.
 *
 * Returns: a constructed #ChamplainNetworkTileSource object
 *
 * Since: 0.4
 */
ChamplainNetworkTileSource *
champlain_network_tile_source_new_full (const gchar *id,
    const gchar *name,
    const gchar *license,
    const gchar *license_uri,
    guint min_zoom,
    guint max_zoom,
    guint tile_size,
    ChamplainMapProjection projection,
    const gchar *uri_format,
    ChamplainRenderer *renderer)
{
  ChamplainNetworkTileSource *source;

  source = g_object_new (CHAMPLAIN_TYPE_NETWORK_TILE_SOURCE,
        "id", id,
        "name", name,
        "license", license,
        "license-uri", license_uri,
        "min-zoom-level", min_zoom,
        "max-zoom-level", max_zoom,
        "tile-size", tile_size,
        "projection", projection,
        "uri-format", uri_format,
        "renderer", renderer,
        NULL);
  return source;
}


/**
 * champlain_network_tile_source_get_uri_format:
 * @tile_source: the #ChamplainNetworkTileSource
 *
 * Default constructor of #ChamplainNetworkTileSource.
 *
 * Returns: A URI format used for URI creation when downloading tiles. See
 * champlain_network_tile_source_set_uri_format() for more information.
 *
 * Since: 0.6
 */
const gchar *
champlain_network_tile_source_get_uri_format (ChamplainNetworkTileSource *tile_source)
{
  g_return_val_if_fail (CHAMPLAIN_IS_NETWORK_TILE_SOURCE (tile_source), NULL);

  return tile_source->priv->uri_format;
}


/**
 * champlain_network_tile_source_set_uri_format:
 * @tile_source: the #ChamplainNetworkTileSource
 * @uri_format: the URI format
 *
 * A URI format is a URI where x, y and zoom level information have been
 * marked for parsing and insertion.  There can be an unlimited number of
 * marked items in a URI format.  They are delimited by "#" before and after
 * the variable name. There are 4 defined variable names: X, Y, Z, and TMSY for
 * Y in TMS coordinates.
 *
 * For example, this is the OpenStreetMap URI format:
 * "http://tile.openstreetmap.org/\#Z\#/\#X\#/\#Y\#.png"
 *
 * Since: 0.4
 */
void
champlain_network_tile_source_set_uri_format (ChamplainNetworkTileSource *tile_source,
    const gchar *uri_format)
{
  g_return_if_fail (CHAMPLAIN_IS_NETWORK_TILE_SOURCE (tile_source));

  ChamplainNetworkTileSourcePrivate *priv = tile_source->priv;

  g_free (priv->uri_format);
  priv->uri_format = g_strdup (uri_format);

  g_object_notify (G_OBJECT (tile_source), "uri-format");
}


/**
 * champlain_network_tile_source_get_proxy_uri:
 * @tile_source: the #ChamplainNetworkTileSource
 *
 * Gets the proxy uri used to access network.
 *
 * Returns: the proxy uri
 *
 * Since: 0.6
 */
const gchar *
champlain_network_tile_source_get_proxy_uri (ChamplainNetworkTileSource *tile_source)
{
  g_return_val_if_fail (CHAMPLAIN_IS_NETWORK_TILE_SOURCE (tile_source), NULL);

  return tile_source->priv->proxy_uri;
}


/**
 * champlain_network_tile_source_set_proxy_uri:
 * @tile_source: the #ChamplainNetworkTileSource
 * @proxy_uri: the proxy uri used to access network
 *
 * Override the default proxy for accessing the network.
 *
 * Since: 0.6
 */
void
champlain_network_tile_source_set_proxy_uri (ChamplainNetworkTileSource *tile_source,
    const gchar *proxy_uri)
{
  g_return_if_fail (CHAMPLAIN_IS_NETWORK_TILE_SOURCE (tile_source));

  ChamplainNetworkTileSourcePrivate *priv = tile_source->priv;
  SoupURI *uri = NULL;

  g_free (priv->proxy_uri);
  priv->proxy_uri = g_strdup (proxy_uri);

  if (priv->proxy_uri)
    uri = soup_uri_new (priv->proxy_uri);

  if (priv->soup_session)
    g_object_set (G_OBJECT (priv->soup_session),
        "proxy-uri", uri,
        NULL);

  if (uri)
    soup_uri_free (uri);

  g_object_notify (G_OBJECT (tile_source), "proxy-uri");
}


/**
 * champlain_network_tile_source_get_offline:
 * @tile_source: the #ChamplainNetworkTileSource
 *
 * Gets offline status.
 *
 * Returns: TRUE when the tile source is set to be offline; FALSE otherwise.
 *
 * Since: 0.6
 */
gboolean
champlain_network_tile_source_get_offline (ChamplainNetworkTileSource *tile_source)
{
  g_return_val_if_fail (CHAMPLAIN_IS_NETWORK_TILE_SOURCE (tile_source), FALSE);

  return tile_source->priv->offline;
}


/**
 * champlain_network_tile_source_set_offline:
 * @tile_source: the #ChamplainNetworkTileSource
 * @offline: TRUE when the tile source should be offline; FALSE otherwise
 *
 * Sets offline status.
 *
 * Since: 0.6
 */
void
champlain_network_tile_source_set_offline (ChamplainNetworkTileSource *tile_source,
    gboolean offline)
{
  g_return_if_fail (CHAMPLAIN_IS_NETWORK_TILE_SOURCE (tile_source));

  tile_source->priv->offline = offline;

  g_object_notify (G_OBJECT (tile_source), "offline");
}


/**
 * champlain_network_tile_source_get_max_conns:
 * @tile_source: the #ChamplainNetworkTileSource
 *
 * Gets the max number of allowed simultaneous connections for this tile
 * source.
 *
 * Returns: the max number of allowed simultaneous connections for this tile
 * source.
 *
 * Since: 0.12.14
 */
gint
champlain_network_tile_source_get_max_conns (ChamplainNetworkTileSource *tile_source)
{
  g_return_val_if_fail (CHAMPLAIN_IS_NETWORK_TILE_SOURCE (tile_source), 0);

  return tile_source->priv->max_conns;
}


/**
 * champlain_network_tile_source_set_max_conns:
 * @tile_source: the #ChamplainNetworkTileSource
 * @max_conns: the number of allowed simultaneous connections
 *
 * Sets the max number of allowed simultaneous connections for this tile source.
 *
 * Before changing this remember to verify how many simultaneous connections
 * your tile provider allows you to make.
 *
 * Since: 0.12.14
 */
void
champlain_network_tile_source_set_max_conns (ChamplainNetworkTileSource *tile_source,
    gint max_conns)
{
  g_return_if_fail (CHAMPLAIN_IS_NETWORK_TILE_SOURCE (tile_source));
  g_return_if_fail (SOUP_IS_SESSION (tile_source->priv->soup_session));

  tile_source->priv->max_conns = max_conns;

  g_object_set (G_OBJECT (tile_source->priv->soup_session),
      "max-conns-per-host", max_conns,
      "max-conns", max_conns,
      NULL);

  g_object_notify (G_OBJECT (tile_source), "max_conns");
}

/**
 * champlain_network_tile_source_set_user_agent:
 * @tile_source: a #ChamplainNetworkTileSource
 * @user_agent: A User-Agent string
 *
 * Sets the User-Agent header used communicating with the server.
 * Since: 0.12.16
 */
void
champlain_network_tile_source_set_user_agent (
    ChamplainNetworkTileSource *tile_source,
    const gchar *user_agent)
{
  g_return_if_fail (CHAMPLAIN_IS_NETWORK_TILE_SOURCE (tile_source)
      && user_agent != NULL);

  ChamplainNetworkTileSourcePrivate *priv = tile_source->priv;

  if (priv->soup_session)
    g_object_set (G_OBJECT (priv->soup_session), "user-agent",
        user_agent, NULL);
}


#define SIZE 8
static gchar *
get_tile_uri (ChamplainNetworkTileSource *tile_source,
    gint x,
    gint y,
    gint z)
{
  ChamplainNetworkTileSourcePrivate *priv = tile_source->priv;

  gchar **tokens;
  gchar *token;
  GString *ret;
  gint i = 0;

  tokens = g_strsplit (priv->uri_format, "#", 20);
  token = tokens[i];
  ret = g_string_sized_new (strlen (priv->uri_format));

  while (token != NULL)
    {
      gint number = G_MAXINT;
      gchar value[SIZE];

      if (strcmp (token, "X") == 0)
        number = x;
      if (strcmp (token, "Y") == 0)
        number = y;
      if (strcmp (token, "TMSY") == 0){
        int ymax = 1 << z;
        number = ymax - y - 1;
      }
      if (strcmp (token, "Z") == 0)
        number = z;

      if (number != G_MAXINT)
        {
          g_snprintf (value, SIZE, "%d", number);
          g_string_append (ret, value);
        }
      else
        g_string_append (ret, token);

      token = tokens[++i];
    }

  token = ret->str;
  g_string_free (ret, FALSE);
  g_strfreev (tokens);

  return token;
}


static void
tile_rendered_cb (ChamplainTile *tile,
    gpointer data,
    guint size,
    gboolean error,
    TileRenderedData *user_data)
{
  ChamplainMapSource *map_source = user_data->map_source;
  ChamplainMapSource *next_source;
  gchar *etag = user_data->etag;

  g_signal_handlers_disconnect_by_func (tile, tile_rendered_cb, user_data);
  g_slice_free (TileRenderedData, user_data);

  next_source = champlain_map_source_get_next_source (map_source);

  if (!error)
    {
      ChamplainTileSource *tile_source = CHAMPLAIN_TILE_SOURCE (map_source);
      ChamplainTileCache *tile_cache = champlain_tile_source_get_cache (tile_source);

      if (etag != NULL)
        champlain_tile_set_etag (tile, etag);

      if (tile_cache && data)
        champlain_tile_cache_store_tile (tile_cache, tile, data, size);

      champlain_tile_set_fade_in (tile, TRUE);
      champlain_tile_set_state (tile, CHAMPLAIN_STATE_DONE);
      champlain_tile_display_content (tile);
    }
  else if (next_source)
    champlain_map_source_fill_tile (next_source, tile);

  g_free (etag);
  g_object_unref (map_source);
  g_object_unref (tile);
}


static void
tile_loaded_cb (G_GNUC_UNUSED SoupSession *session,
    SoupMessage *msg,
    gpointer user_data)
{
  TileLoadedData *callback_data = (TileLoadedData *) user_data;
  ChamplainMapSource *map_source = callback_data->map_source;
  ChamplainTileSource *tile_source = CHAMPLAIN_TILE_SOURCE (map_source);
  ChamplainTileCache *tile_cache = champlain_tile_source_get_cache (tile_source);
  ChamplainMapSource *next_source = champlain_map_source_get_next_source (map_source);
  ChamplainTile *tile = callback_data->tile;
  const gchar *etag;
  TileRenderedData *data;
  ChamplainRenderer *renderer;

  g_signal_handlers_disconnect_by_func (tile, tile_state_notify, callback_data->cancelled_data);
  g_slice_free (TileLoadedData, callback_data);

  DEBUG ("Got reply %d", msg->status_code);

  if (msg->status_code == SOUP_STATUS_CANCELLED)
    {
      DEBUG ("Download of tile %d, %d got cancelled",
          champlain_tile_get_x (tile), champlain_tile_get_y (tile));
      goto cleanup;
    }

  if (msg->status_code == SOUP_STATUS_NOT_MODIFIED)
    {
      if (tile_cache)
        champlain_tile_cache_refresh_tile_time (tile_cache, tile);
      goto finish;
    }

  if (!SOUP_STATUS_IS_SUCCESSFUL (msg->status_code))
    {
      DEBUG ("Unable to download tile %d, %d: %s",
          champlain_tile_get_x (tile),
          champlain_tile_get_y (tile),
          soup_status_get_phrase (msg->status_code));

      goto load_next;
    }

  /* Verify if the server sent an etag and save it */
  etag = soup_message_headers_get_one (msg->response_headers, "ETag");
  DEBUG ("Received ETag %s", etag);

  renderer = champlain_map_source_get_renderer (map_source);
  g_return_if_fail (CHAMPLAIN_IS_RENDERER (renderer));

  data = g_slice_new (TileRenderedData);
  data->map_source = map_source;
  data->etag = g_strdup (etag);

  g_signal_connect (tile, "render-complete", G_CALLBACK (tile_rendered_cb), data);

  champlain_renderer_set_data (renderer, msg->response_body->data, msg->response_body->length);
  champlain_renderer_render (renderer, tile);

  return;

load_next:
  if (next_source)
    champlain_map_source_fill_tile (next_source, tile);

  goto cleanup;

finish:
  champlain_tile_set_fade_in (tile, TRUE);
  champlain_tile_set_state (tile, CHAMPLAIN_STATE_DONE);
  champlain_tile_display_content (tile);

cleanup:
  g_object_unref (tile);
  g_object_unref (map_source);
}


static void
destroy_cancelled_data (TileCancelledData *data,
    G_GNUC_UNUSED GClosure *closure)
{
  if (data->map_source)
    g_object_remove_weak_pointer (G_OBJECT (data->map_source), (gpointer *) &data->map_source);

  if (data->msg)
    g_object_remove_weak_pointer (G_OBJECT (data->msg), (gpointer *) &data->msg);

  g_slice_free (TileCancelledData, data);
}


static void
tile_state_notify (ChamplainTile *tile,
    G_GNUC_UNUSED GParamSpec *pspec,
    TileCancelledData *data)
{
  if (champlain_tile_get_state (tile) == CHAMPLAIN_STATE_DONE && data->map_source && data->msg)
    {
      DEBUG ("Canceling tile download");
      ChamplainNetworkTileSourcePrivate *priv = CHAMPLAIN_NETWORK_TILE_SOURCE (data->map_source)->priv;
      soup_session_cancel_message (priv->soup_session, data->msg, SOUP_STATUS_CANCELLED);
    }
}


static gchar *
get_modified_time_string (ChamplainTile *tile)
{
  const GTimeVal *time;

  g_return_val_if_fail (CHAMPLAIN_TILE (tile), NULL);

  time = champlain_tile_get_modified_time (tile);

  if (time == NULL)
    return NULL;

  struct tm *other_time = gmtime (&time->tv_sec);
  char value[100];

#ifdef G_OS_WIN32
  strftime (value, 100, "%a, %d %b %Y %H:%M:%S %Z", other_time);
#else
  strftime (value, 100, "%a, %d %b %Y %T %Z", other_time);
#endif

  return g_strdup (value);
}


static void
fill_tile (ChamplainMapSource *map_source,
    ChamplainTile *tile)
{
  g_return_if_fail (CHAMPLAIN_IS_NETWORK_TILE_SOURCE (map_source));
  g_return_if_fail (CHAMPLAIN_IS_TILE (tile));

  ChamplainNetworkTileSource *tile_source = CHAMPLAIN_NETWORK_TILE_SOURCE (map_source);
  ChamplainNetworkTileSourcePrivate *priv = tile_source->priv;

  if (champlain_tile_get_state (tile) == CHAMPLAIN_STATE_DONE)
    return;

  if (!priv->offline)
    {
      TileLoadedData *callback_data;
      SoupMessage *msg;
      gchar *uri;

      uri = get_tile_uri (tile_source,
            champlain_tile_get_x (tile),
            champlain_tile_get_y (tile),
            champlain_tile_get_zoom_level (tile));
      msg = soup_message_new (SOUP_METHOD_GET, uri);
      g_free (uri);

      if (champlain_tile_get_state (tile) == CHAMPLAIN_STATE_LOADED)
        {
          /* validate tile */

          const gchar *etag = champlain_tile_get_etag (tile);
          gchar *date = get_modified_time_string (tile);

          /* If an etag is available, only use it.
           * OSM servers seems to send now as the modified time for all tiles
           * Omarender servers set the modified time correctly
           */
          if (etag)
            {
              DEBUG ("If-None-Match: %s", etag);
              soup_message_headers_append (msg->request_headers,
                  "If-None-Match", etag);
            }
          else if (date)
            {
              DEBUG ("If-Modified-Since %s", date);
              soup_message_headers_append (msg->request_headers,
                  "If-Modified-Since", date);
            }

          g_free (date);
        }

      TileCancelledData *tile_cancelled_data = g_slice_new (TileCancelledData);
      tile_cancelled_data->map_source = map_source;
      tile_cancelled_data->msg = msg;

      g_object_add_weak_pointer (G_OBJECT (msg), (gpointer *) &tile_cancelled_data->msg);
      g_object_add_weak_pointer (G_OBJECT (map_source), (gpointer *) &tile_cancelled_data->map_source);

      g_signal_connect_data (tile, "notify::state", G_CALLBACK (tile_state_notify),
          tile_cancelled_data, (GClosureNotify) destroy_cancelled_data, 0);

      callback_data = g_slice_new (TileLoadedData);
      callback_data->tile = tile;
      callback_data->map_source = map_source;
      callback_data->cancelled_data = tile_cancelled_data;

      g_object_ref (map_source);
      g_object_ref (tile);

      soup_session_queue_message (priv->soup_session, msg,
          tile_loaded_cb,
          callback_data);
    }
  else
    {
      ChamplainMapSource *next_source = champlain_map_source_get_next_source (map_source);

      if (CHAMPLAIN_IS_MAP_SOURCE (next_source))
        champlain_map_source_fill_tile (next_source, tile);
    }
}
