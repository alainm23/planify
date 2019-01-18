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
 * SECTION:champlain-location
 * @short_description: An interface common to objects having latitude and longitude
 *
 * By implementing #ChamplainLocation the object declares that it has latitude
 * and longitude and can be used to specify location on the map.
 */

#include "champlain-location.h"
#include "champlain-private.h"

typedef ChamplainLocationIface ChamplainLocationInterface;

G_DEFINE_INTERFACE (ChamplainLocation, champlain_location, G_TYPE_OBJECT);


static void
champlain_location_default_init (ChamplainLocationInterface *iface)
{
  /**
   * ChamplainLocation:longitude:
   *
   * The longitude coordonate
   *
   * Since: 0.10
   */
  g_object_interface_install_property (iface,
      g_param_spec_double ("longitude", 
          "Longitude",
          "The longitude coordonate",
          -180.0f, 
          180.0f, 
          0.0f, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLocation:latitude:
   *
   * The latitude coordonate
   *
   * Since: 0.10
   */
  g_object_interface_install_property (iface,
      g_param_spec_double ("latitude", 
          "Latitude",
          "The latitude coordonate",
          -90.0f, 
          90.0f, 
          0.0f, 
          CHAMPLAIN_PARAM_READWRITE));
}


/**
 * champlain_location_set_location:
 * @location: a #ChamplainLocation
 * @latitude: the latitude
 * @longitude: the longitude
 *
 * Sets the coordinates of the location
 *
 * Since: 0.10
 */
void
champlain_location_set_location (ChamplainLocation *location,
    gdouble latitude,
    gdouble longitude)
{
  CHAMPLAIN_LOCATION_GET_IFACE (location)->set_location (location,
      latitude,
      longitude);
}


/**
 * champlain_location_get_latitude:
 * @location: a #ChamplainLocation
 *
 * Gets the latitude coordinate.
 *
 * Returns: the latitude coordinate.
 *
 * Since: 0.10
 */
gdouble
champlain_location_get_latitude (ChamplainLocation *location)
{
  return CHAMPLAIN_LOCATION_GET_IFACE (location)->get_latitude (location);
}


/**
 * champlain_location_get_longitude:
 * @location: a #ChamplainLocation
 *
 * Gets the longitude coordinate.
 *
 * Returns: the longitude coordinate.
 *
 * Since: 0.10
 */
gdouble
champlain_location_get_longitude (ChamplainLocation *location)
{
  return CHAMPLAIN_LOCATION_GET_IFACE (location)->get_longitude (location);
}
