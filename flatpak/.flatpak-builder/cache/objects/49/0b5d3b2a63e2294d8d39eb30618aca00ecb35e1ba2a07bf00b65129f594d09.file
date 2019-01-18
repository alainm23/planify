/*
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
 * SECTION:champlain-coordinate
 * @short_description: The simplest implementation of #ChamplainLocation
 *
 * #ChamplainCoordinate is a simple object implementing #ChamplainLocation.
 */

#include "champlain-coordinate.h"

#include "config.h"
#include "champlain-marshal.h"
#include "champlain-private.h"
#include "champlain-location.h"

enum
{
  PROP_0,
  PROP_LONGITUDE,
  PROP_LATITUDE,
};


static void set_location (ChamplainLocation *location,
    gdouble latitude,
    gdouble longitude);
static gdouble get_latitude (ChamplainLocation *location);
static gdouble get_longitude (ChamplainLocation *location);

static void location_interface_init (ChamplainLocationIface *iface);

G_DEFINE_TYPE_WITH_CODE (ChamplainCoordinate, champlain_coordinate, G_TYPE_INITIALLY_UNOWNED,
    G_IMPLEMENT_INTERFACE (CHAMPLAIN_TYPE_LOCATION, location_interface_init));

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), CHAMPLAIN_TYPE_COORDINATE, ChamplainCoordinatePrivate))

struct _ChamplainCoordinatePrivate
{
  gdouble longitude;
  gdouble latitude;
};

static void
champlain_coordinate_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  ChamplainCoordinate *coordinate = CHAMPLAIN_COORDINATE (object);
  ChamplainCoordinatePrivate *priv = coordinate->priv;

  switch (prop_id)
    {
    case PROP_LONGITUDE:
      g_value_set_double (value, priv->longitude);
      break;

    case PROP_LATITUDE:
      g_value_set_double (value, priv->latitude);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
champlain_coordinate_set_property (GObject *object,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec)
{
  ChamplainCoordinate *coordinate = CHAMPLAIN_COORDINATE (object);
  ChamplainCoordinatePrivate *priv = coordinate->priv;

  switch (prop_id)
    {
    case PROP_LONGITUDE:
      {
        gdouble longitude = g_value_get_double (value);
        set_location (CHAMPLAIN_LOCATION (coordinate), priv->latitude, longitude);
        break;
      }

    case PROP_LATITUDE:
      {
        gdouble latitude = g_value_get_double (value);
        set_location (CHAMPLAIN_LOCATION (coordinate), latitude, priv->longitude);
        break;
      }

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
set_location (ChamplainLocation *location,
    gdouble latitude,
    gdouble longitude)
{
  g_return_if_fail (CHAMPLAIN_IS_COORDINATE (location));

  ChamplainCoordinatePrivate *priv = CHAMPLAIN_COORDINATE (location)->priv;

  priv->longitude = CLAMP (longitude, CHAMPLAIN_MIN_LONGITUDE, CHAMPLAIN_MAX_LONGITUDE);
  priv->latitude = CLAMP (latitude, CHAMPLAIN_MIN_LATITUDE, CHAMPLAIN_MAX_LATITUDE);

  g_object_notify (G_OBJECT (location), "latitude");
  g_object_notify (G_OBJECT (location), "longitude");
}


static gdouble
get_latitude (ChamplainLocation *location)
{
  g_return_val_if_fail (CHAMPLAIN_IS_COORDINATE (location), 0.0);

  ChamplainCoordinatePrivate *priv = CHAMPLAIN_COORDINATE (location)->priv;

  return priv->latitude;
}


static gdouble
get_longitude (ChamplainLocation *location)
{
  g_return_val_if_fail (CHAMPLAIN_IS_COORDINATE (location), 0.0);

  ChamplainCoordinatePrivate *priv = CHAMPLAIN_COORDINATE (location)->priv;

  return priv->longitude;
}


static void
location_interface_init (ChamplainLocationIface *iface)
{
  iface->get_latitude = get_latitude;
  iface->get_longitude = get_longitude;
  iface->set_location = set_location;
}


static void
champlain_coordinate_dispose (GObject *object)
{
  G_OBJECT_CLASS (champlain_coordinate_parent_class)->dispose (object);
}


static void
champlain_coordinate_finalize (GObject *object)
{
  G_OBJECT_CLASS (champlain_coordinate_parent_class)->finalize (object);
}


static void
champlain_coordinate_class_init (ChamplainCoordinateClass *coordinate_class)
{
  g_type_class_add_private (coordinate_class, sizeof (ChamplainCoordinatePrivate));

  GObjectClass *object_class = G_OBJECT_CLASS (coordinate_class);
  object_class->finalize = champlain_coordinate_finalize;
  object_class->dispose = champlain_coordinate_dispose;
  object_class->get_property = champlain_coordinate_get_property;
  object_class->set_property = champlain_coordinate_set_property;

  g_object_class_override_property (object_class,
      PROP_LONGITUDE,
      "longitude");

  g_object_class_override_property (object_class,
      PROP_LATITUDE,
      "latitude");
}


static void
champlain_coordinate_init (ChamplainCoordinate *coordinate)
{
  ChamplainCoordinatePrivate *priv = GET_PRIVATE (coordinate);

  coordinate->priv = priv;

  priv->latitude = 0.0;
  priv->longitude = 0.0;
}


/**
 * champlain_coordinate_new:
 *
 * Creates a new instance of #ChamplainCoordinate.
 *
 * Returns: the created instance.
 *
 * Since: 0.10
 */
ChamplainCoordinate *
champlain_coordinate_new ()
{
  return CHAMPLAIN_COORDINATE (g_object_new (CHAMPLAIN_TYPE_COORDINATE, NULL));
}


/**
 * champlain_coordinate_new_full:
 * @latitude: the latitude coordinate
 * @longitude: the longitude coordinate
 *
 * Creates a new instance of #ChamplainCoordinate initialized with the given
 * coordinates.
 *
 * Returns: the created instance.
 *
 * Since: 0.10
 */
ChamplainCoordinate *
champlain_coordinate_new_full (gdouble latitude,
    gdouble longitude)
{
  return CHAMPLAIN_COORDINATE (g_object_new (CHAMPLAIN_TYPE_COORDINATE,
          "latitude", latitude,
          "longitude", longitude,
          NULL));
}
