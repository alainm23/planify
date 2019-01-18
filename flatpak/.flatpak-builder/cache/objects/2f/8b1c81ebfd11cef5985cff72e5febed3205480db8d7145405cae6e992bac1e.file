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

/**
 * SECTION:champlain-map-source-desc
 * @short_description: A class that describes map sources.
 *
 * A class that describes map sources.
 */

#include "champlain-map-source-desc.h"

#include "champlain-enum-types.h"

enum
{
  PROP_0,
  PROP_ID,
  PROP_NAME,
  PROP_LICENSE,
  PROP_LICENSE_URI,
  PROP_URI_FORMAT,
  PROP_MIN_ZOOM_LEVEL,
  PROP_MAX_ZOOM_LEVEL,
  PROP_TILE_SIZE,
  PROP_PROJECTION,
  PROP_CONSTRUCTOR,
  PROP_DATA,
};

struct _ChamplainMapSourceDescPrivate
{
  gchar *id;
  gchar *name;
  gchar *license;
  gchar *license_uri;
  gchar *uri_format;
  guint min_zoom_level;
  guint max_zoom_level;
  guint tile_size;
  ChamplainMapProjection projection;
  ChamplainMapSourceConstructor constructor;
  gpointer data;
};

G_DEFINE_TYPE (ChamplainMapSourceDesc, champlain_map_source_desc, G_TYPE_OBJECT);

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), CHAMPLAIN_TYPE_MAP_SOURCE_DESC, ChamplainMapSourceDescPrivate))


static void set_id (ChamplainMapSourceDesc *desc,
    const gchar *id);
static void set_name (ChamplainMapSourceDesc *desc,
    const gchar *name);
static void set_license (ChamplainMapSourceDesc *desc,
    const gchar *license);
static void set_license_uri (ChamplainMapSourceDesc *desc,
    const gchar *license_uri);
static void set_uri_format (ChamplainMapSourceDesc *desc,
    const gchar *uri_format);
static void set_min_zoom_level (ChamplainMapSourceDesc *desc,
    guint zoom_level);
static void set_max_zoom_level (ChamplainMapSourceDesc *desc,
    guint zoom_level);
static void set_tile_size (ChamplainMapSourceDesc *desc,
    guint tile_size);
static void set_projection (ChamplainMapSourceDesc *desc,
    ChamplainMapProjection projection);
static void set_data (ChamplainMapSourceDesc *desc,
    gpointer data);
static void set_constructor (ChamplainMapSourceDesc *desc,
    ChamplainMapSourceConstructor constructor);


static void
champlain_map_source_desc_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  ChamplainMapSourceDescPrivate *priv = CHAMPLAIN_MAP_SOURCE_DESC (object)->priv;

  switch (prop_id)
    {
    case PROP_ID:
      g_value_set_string (value, priv->id);
      break;

    case PROP_NAME:
      g_value_set_string (value, priv->name);
      break;

    case PROP_LICENSE:
      g_value_set_string (value, priv->license);
      break;

    case PROP_LICENSE_URI:
      g_value_set_string (value, priv->license_uri);
      break;

    case PROP_URI_FORMAT:
      g_value_set_string (value, priv->uri_format);
      break;

    case PROP_MIN_ZOOM_LEVEL:
      g_value_set_uint (value, priv->min_zoom_level);
      break;

    case PROP_MAX_ZOOM_LEVEL:
      g_value_set_uint (value, priv->max_zoom_level);
      break;

    case PROP_TILE_SIZE:
      g_value_set_uint (value, priv->tile_size);
      break;

    case PROP_PROJECTION:
      g_value_set_enum (value, priv->projection);
      break;

    case PROP_CONSTRUCTOR:
      g_value_set_pointer (value, priv->constructor);
      break;

    case PROP_DATA:
      g_value_set_pointer (value, priv->data);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
champlain_map_source_desc_set_property (GObject *object,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec)
{
  ChamplainMapSourceDesc *desc = CHAMPLAIN_MAP_SOURCE_DESC (object);

  switch (prop_id)
    {
    case PROP_ID:
      set_id (desc, g_value_get_string (value));

    case PROP_NAME:
      set_name (desc, g_value_get_string (value));
      break;

    case PROP_LICENSE:
      set_license (desc, g_value_get_string (value));
      break;

    case PROP_LICENSE_URI:
      set_license_uri (desc, g_value_get_string (value));
      break;

    case PROP_URI_FORMAT:
      set_uri_format (desc, g_value_get_string (value));
      break;

    case PROP_MIN_ZOOM_LEVEL:
      set_min_zoom_level (desc, g_value_get_uint (value));
      break;

    case PROP_MAX_ZOOM_LEVEL:
      set_max_zoom_level (desc, g_value_get_uint (value));
      break;

    case PROP_TILE_SIZE:
      set_tile_size (desc, g_value_get_uint (value));
      break;

    case PROP_PROJECTION:
      set_projection (desc, g_value_get_enum (value));
      break;

    case PROP_CONSTRUCTOR:
      set_constructor (desc, g_value_get_pointer (value));
      break;

    case PROP_DATA:
      set_data (desc, g_value_get_pointer (value));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
champlain_map_source_desc_dispose (GObject *object)
{
/*  ChamplainMapSourceDesc *desc = CHAMPLAIN_MAP_SOURCE_DESC (object); */

  G_OBJECT_CLASS (champlain_map_source_desc_parent_class)->dispose (object);
}


static void
champlain_map_source_desc_finalize (GObject *object)
{
  ChamplainMapSourceDescPrivate *priv = CHAMPLAIN_MAP_SOURCE_DESC (object)->priv;

  g_free (priv->id);
  g_free (priv->name);
  g_free (priv->license);
  g_free (priv->license_uri);
  g_free (priv->uri_format);

  G_OBJECT_CLASS (champlain_map_source_desc_parent_class)->finalize (object);
}


static void
champlain_map_source_desc_class_init (ChamplainMapSourceDescClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (ChamplainMapSourceDescPrivate));

  object_class->finalize = champlain_map_source_desc_finalize;
  object_class->dispose = champlain_map_source_desc_dispose;
  object_class->get_property = champlain_map_source_desc_get_property;
  object_class->set_property = champlain_map_source_desc_set_property;

  /**
   * ChamplainMapSourceDesc:id:
   *
   * The id of the map source
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_ID,
      g_param_spec_string ("id",
          "Map source id",
          "Map source id",
          "",
          G_PARAM_READABLE | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * ChamplainMapSourceDesc:name:
   *
   * The name of the map source
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_NAME,
      g_param_spec_string ("name",
          "Map source name",
          "Map source name",
          "",
          G_PARAM_READABLE | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * ChamplainMapSourceDesc:license:
   *
   * The license of the map source
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_LICENSE,
      g_param_spec_string ("license",
          "Map source license",
          "Map source license",
          "",
          G_PARAM_READABLE | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * ChamplainMapSourceDesc:license-uri:
   *
   * The license's uri for more information
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_LICENSE_URI,
      g_param_spec_string ("license-uri",
          "Map source license URI",
          "Map source license URI",
          "",
          G_PARAM_READABLE | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * ChamplainMapSourceDesc:uri-format:
   *
   * The URI format of a network map source
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_URI_FORMAT,
      g_param_spec_string ("uri-format",
          "Network map source URI format",
          "Network map source URI format",
          "",
          G_PARAM_READABLE | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * ChamplainMapSourceDesc:min-zoom-level:
   *
   * The minimum zoom level
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_MIN_ZOOM_LEVEL,
      g_param_spec_uint ("min-zoom-level",
          "Min zoom level",
          "The lowest allowed level of zoom",
          0, 
          20, 
          0,
          G_PARAM_READABLE | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * ChamplainMapSourceDesc:max-zoom-level:
   *
   * The maximum zoom level
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_MAX_ZOOM_LEVEL,
      g_param_spec_uint ("max-zoom-level",
          "Max zoom level",
          "The highest allowed level of zoom",
          0, 
          20, 
          20,
          G_PARAM_READABLE | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * ChamplainMapSourceDesc:projection:
   *
   * The map projection of the map source
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_PROJECTION,
      g_param_spec_enum ("projection",
          "Map source projection",
          "Map source projection",
          CHAMPLAIN_TYPE_MAP_PROJECTION,
          CHAMPLAIN_MAP_PROJECTION_MERCATOR,
          G_PARAM_READABLE | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * ChamplainMapSourceDesc:tile-size:
   *
   * The tile size of the map source
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_TILE_SIZE,
      g_param_spec_uint ("tile-size",
          "Tile Size",
          "The size of the map source tile",
          0,
          G_MAXINT,
          256,
          G_PARAM_READABLE | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * ChamplainMapSourceDesc:constructor:
   *
   * The map source constructor
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_CONSTRUCTOR,
      g_param_spec_pointer ("constructor",
          "Map source constructor",
          "Map source constructor",
          G_PARAM_READABLE | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));

  /**
   * ChamplainMapSourceDesc:data:
   *
   * User data passed to the constructor
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_DATA,
      g_param_spec_pointer ("data",
          "User data",
          "User data",
          G_PARAM_READABLE | G_PARAM_WRITABLE | G_PARAM_CONSTRUCT_ONLY));
}


static void
champlain_map_source_desc_init (ChamplainMapSourceDesc *desc)
{
  ChamplainMapSourceDescPrivate *priv = GET_PRIVATE (desc);

  desc->priv = priv;

  priv->id = NULL;
  priv->name = NULL;
  priv->license = NULL;
  priv->license_uri = NULL;
  priv->uri_format = NULL;
  priv->min_zoom_level = 0;
  priv->max_zoom_level = 20;
  priv->tile_size = 256;
  priv->projection = CHAMPLAIN_MAP_PROJECTION_MERCATOR;
  priv->constructor = NULL;
  priv->data = NULL;
}


/**
 * champlain_map_source_desc_new_full: (skip)
 * @id: the map source's id
 * @name: the map source's name
 * @license: the map source's license
 * @license_uri: the map source's license URI
 * @min_zoom: the map source's minimum zoom level
 * @max_zoom: the map source's maximum zoom level
 * @tile_size: the map source's tile size (in pixels)
 * @projection: the map source's projection
 * @uri_format: the URI to fetch the tiles from, see #champlain_network_tile_source_set_uri_format
 * @constructor: the map source's constructor
 * @data: user data passed to the constructor
 *
 * Constructor of #ChamplainMapSourceDesc which describes a #ChamplainMapSource.
 * This is returned by #champlain_map_source_factory_get_registered
 *
 * Returns: a constructed #ChamplainMapSourceDesc object
 *
 * Since: 0.10
 */
ChamplainMapSourceDesc *
champlain_map_source_desc_new_full (
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
    gpointer data)
{
  return g_object_new (CHAMPLAIN_TYPE_MAP_SOURCE_DESC,
      "id", id,
      "name", name,
      "license", license,
      "license-uri", license_uri,
      "min-zoom-level", min_zoom,
      "max-zoom-level", max_zoom,
      "tile-size", tile_size,
      "projection", projection,
      "uri-format", uri_format,
      "constructor", constructor,
      "data", data,
      NULL);
}


/**
 * champlain_map_source_desc_get_id:
 * @desc: a #ChamplainMapSourceDesc
 *
 * Gets map source's id.
 *
 * Returns: the map source's id.
 *
 * Since: 0.10
 */
const gchar *
champlain_map_source_desc_get_id (ChamplainMapSourceDesc *desc)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc), NULL);

  return desc->priv->id;
}


/**
 * champlain_map_source_desc_get_name:
 * @desc: a #ChamplainMapSourceDesc
 *
 * Gets map source's name.
 *
 * Returns: the map source's name.
 *
 * Since: 0.10
 */
const gchar *
champlain_map_source_desc_get_name (ChamplainMapSourceDesc *desc)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc), NULL);

  return desc->priv->name;
}


/**
 * champlain_map_source_desc_get_license:
 * @desc: a #ChamplainMapSourceDesc
 *
 * Gets map source's license.
 *
 * Returns: the map source's license.
 *
 * Since: 0.10
 */
const gchar *
champlain_map_source_desc_get_license (ChamplainMapSourceDesc *desc)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc), NULL);

  return desc->priv->license;
}


/**
 * champlain_map_source_desc_get_license_uri:
 * @desc: a #ChamplainMapSourceDesc
 *
 * Gets map source's license URI.
 *
 * Returns: the map source's license URI.
 *
 * Since: 0.10
 */
const gchar *
champlain_map_source_desc_get_license_uri (ChamplainMapSourceDesc *desc)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc), NULL);

  return desc->priv->license_uri;
}


/**
 * champlain_map_source_desc_get_uri_format:
 * @desc: a #ChamplainMapSourceDesc
 *
 * Gets network map source's URI format.
 *
 * Returns: the URI format.
 *
 * Since: 0.10
 */
const gchar *
champlain_map_source_desc_get_uri_format (ChamplainMapSourceDesc *desc)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc), NULL);

  return desc->priv->uri_format;
}


/**
 * champlain_map_source_desc_get_min_zoom_level:
 * @desc: a #ChamplainMapSourceDesc
 *
 * Gets map source's minimum zoom level.
 *
 * Returns: the miminum zoom level this map source supports
 *
 * Since: 0.10
 */
guint
champlain_map_source_desc_get_min_zoom_level (ChamplainMapSourceDesc *desc)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc), 0);

  return desc->priv->min_zoom_level;
}


/**
 * champlain_map_source_desc_get_max_zoom_level:
 * @desc: a #ChamplainMapSourceDesc
 *
 * Gets map source's maximum zoom level.
 *
 * Returns: the maximum zoom level this map source supports
 *
 * Since: 0.10
 */
guint
champlain_map_source_desc_get_max_zoom_level (ChamplainMapSourceDesc *desc)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc), 0);

  return desc->priv->max_zoom_level;
}


/**
 * champlain_map_source_desc_get_tile_size:
 * @desc: a #ChamplainMapSourceDesc
 *
 * Gets map source's tile size.
 *
 * Returns: the tile's size (width and height) in pixels for this map source
 *
 * Since: 0.10
 */
guint
champlain_map_source_desc_get_tile_size (ChamplainMapSourceDesc *desc)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc), 0);

  return desc->priv->tile_size;
}


/**
 * champlain_map_source_desc_get_projection:
 * @desc: a #ChamplainMapSourceDesc
 *
 * Gets map source's projection.
 *
 * Returns: the map source's projection.
 *
 * Since: 0.10
 */
ChamplainMapProjection
champlain_map_source_desc_get_projection (ChamplainMapSourceDesc *desc)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc), CHAMPLAIN_MAP_PROJECTION_MERCATOR);

  return desc->priv->projection;
}


/**
 * champlain_map_source_desc_get_data:
 * @desc: a #ChamplainMapSourceDesc
 *
 * Gets user data.
 *
 * Returns: (transfer none): the user data.
 *
 * Since: 0.10
 */
gpointer
champlain_map_source_desc_get_data (ChamplainMapSourceDesc *desc)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc), NULL);

  return desc->priv->data;
}


/**
 * champlain_map_source_desc_get_constructor: (skip)
 * @desc: a #ChamplainMapSourceDesc
 *
 * Gets the map source constructor.
 *
 * Returns: the constructor.
 *
 * Since: 0.10
 */
ChamplainMapSourceConstructor
champlain_map_source_desc_get_constructor (ChamplainMapSourceDesc *desc)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc), NULL);

  return desc->priv->constructor;
}


static void
set_id (ChamplainMapSourceDesc *desc,
    const gchar *id)
{
  g_return_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc));

  ChamplainMapSourceDescPrivate *priv = desc->priv;

  g_free (priv->id);
  priv->id = g_strdup (id);

  g_object_notify (G_OBJECT (desc), "id");
}


static void
set_name (ChamplainMapSourceDesc *desc,
    const gchar *name)
{
  g_return_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc));

  ChamplainMapSourceDescPrivate *priv = desc->priv;

  g_free (priv->name);
  priv->name = g_strdup (name);

  g_object_notify (G_OBJECT (desc), "name");
}


static void
set_license (ChamplainMapSourceDesc *desc,
    const gchar *license)
{
  g_return_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc));

  ChamplainMapSourceDescPrivate *priv = desc->priv;

  g_free (priv->license);
  priv->license = g_strdup (license);

  g_object_notify (G_OBJECT (desc), "license");
}


static void
set_license_uri (ChamplainMapSourceDesc *desc,
    const gchar *license_uri)
{
  g_return_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc));

  ChamplainMapSourceDescPrivate *priv = desc->priv;

  g_free (priv->license_uri);
  priv->license_uri = g_strdup (license_uri);

  g_object_notify (G_OBJECT (desc), "license-uri");
}


static void
set_uri_format (ChamplainMapSourceDesc *desc,
    const gchar *uri_format)
{
  g_return_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc));

  ChamplainMapSourceDescPrivate *priv = desc->priv;

  g_free (priv->uri_format);
  priv->uri_format = g_strdup (uri_format);

  g_object_notify (G_OBJECT (desc), "uri-format");
}


static void
set_min_zoom_level (ChamplainMapSourceDesc *desc,
    guint zoom_level)
{
  g_return_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc));

  desc->priv->min_zoom_level = zoom_level;

  g_object_notify (G_OBJECT (desc), "min-zoom-level");
}


static void
set_max_zoom_level (ChamplainMapSourceDesc *desc,
    guint zoom_level)
{
  g_return_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc));

  desc->priv->max_zoom_level = zoom_level;

  g_object_notify (G_OBJECT (desc), "max-zoom-level");
}


static void
set_tile_size (ChamplainMapSourceDesc *desc,
    guint tile_size)
{
  g_return_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc));

  desc->priv->tile_size = tile_size;

  g_object_notify (G_OBJECT (desc), "tile-size");
}


static void
set_projection (ChamplainMapSourceDesc *desc,
    ChamplainMapProjection projection)
{
  g_return_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc));

  desc->priv->projection = projection;

  g_object_notify (G_OBJECT (desc), "projection");
}


static void
set_data (ChamplainMapSourceDesc *desc,
    gpointer data)
{
  g_return_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc));

  desc->priv->data = data;

  g_object_notify (G_OBJECT (desc), "data");
}


static void
set_constructor (ChamplainMapSourceDesc *desc,
    ChamplainMapSourceConstructor constructor)
{
  g_return_if_fail (CHAMPLAIN_IS_MAP_SOURCE_DESC (desc));

  desc->priv->constructor = constructor;

  g_object_notify (G_OBJECT (desc), "constructor");
}
