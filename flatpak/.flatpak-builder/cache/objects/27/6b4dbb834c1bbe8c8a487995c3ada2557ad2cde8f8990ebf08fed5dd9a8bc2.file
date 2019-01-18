/*
   Copyright 2012 Bastien Nocera

   The Gnome Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public License as
   published by the Free Software Foundation; either version 2 of the
   License, or (at your option) any later version.

   The Gnome Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with the Gnome Library; see the file COPYING.LIB.  If not,
   write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301  USA.

   Authors: Bastien Nocera <hadess@hadess.net>
            Zeeshan Ali (Khattak) <zeeshanak@gnome.org>

 */

#ifndef GEOCODE_PLACE_H
#define GEOCODE_PLACE_H

#include <glib-object.h>
#include <gio/gio.h>
#include <geocode-glib/geocode-location.h>
#include <geocode-glib/geocode-bounding-box.h>

G_BEGIN_DECLS

GType geocode_place_get_type (void) G_GNUC_CONST;

#define GEOCODE_TYPE_PLACE                  (geocode_place_get_type ())
#define GEOCODE_PLACE(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), GEOCODE_TYPE_PLACE, GeocodePlace))
#define GEOCODE_IS_PLACE(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GEOCODE_TYPE_PLACE))
#define GEOCODE_PLACE_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), GEOCODE_TYPE_PLACE, GeocodePlaceClass))
#define GEOCODE_IS_PLACE_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), GEOCODE_TYPE_PLACE))
#define GEOCODE_PLACE_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), GEOCODE_TYPE_PLACE, GeocodePlaceClass))

typedef struct _GeocodePlace        GeocodePlace;
typedef struct _GeocodePlaceClass   GeocodePlaceClass;
typedef struct _GeocodePlacePrivate GeocodePlacePrivate;

/**
 * GeocodePlace:
 *
 * All the fields in the #GeocodePlace structure are private and should never be accessed directly.
**/
struct _GeocodePlace {
        /* <private> */
        GObject parent_instance;
        GeocodePlacePrivate *priv;
};

/**
 * GeocodePlaceClass:
 *
 * All the fields in the #GeocodePlaceClass structure are private and should never be accessed directly.
**/
struct _GeocodePlaceClass {
        /* <private> */
        GObjectClass parent_class;
};

G_DEFINE_AUTOPTR_CLEANUP_FUNC (GeocodePlace, g_object_unref)

/**
 * GeocodePlaceType:
 * @GEOCODE_PLACE_TYPE_UNKNOWN: Type is unknown for this place.
 * @GEOCODE_PLACE_TYPE_BUILDING: A building or house.
 * @GEOCODE_PLACE_TYPE_STREET: A street.
 * @GEOCODE_PLACE_TYPE_TOWN: A populated settlement such as a city, town, village.
 * @GEOCODE_PLACE_TYPE_STATE: One of the primary administrative areas within a country.
 * @GEOCODE_PLACE_TYPE_COUNTY: One of the secondary administrative areas within a country.
 * @GEOCODE_PLACE_TYPE_LOCAL_ADMINISTRATIVE_AREA: One of the tertiary administrative areas within a country.
 * @GEOCODE_PLACE_TYPE_POSTAL_CODE: A partial or full postal code.
 * @GEOCODE_PLACE_TYPE_COUNTRY: One of the countries or dependent territories defined by the ISO 3166-1 standard.
 * @GEOCODE_PLACE_TYPE_ISLAND: An island.
 * @GEOCODE_PLACE_TYPE_AIRPORT: An airport.
 * @GEOCODE_PLACE_TYPE_RAILWAY_STATION: A railway station.
 * @GEOCODE_PLACE_TYPE_BUS_STOP: A bus stop.
 * @GEOCODE_PLACE_TYPE_MOTORWAY: A high capacity highways designed to safely carry fast motor traffic.
 * @GEOCODE_PLACE_TYPE_DRAINAGE: A water feature such as a river, canal, lake, bay or ocean.
 * @GEOCODE_PLACE_TYPE_LAND_FEATURE: A land feature such as a park, mountain or beach.
 * @GEOCODE_PLACE_TYPE_MISCELLANEOUS: A uncategorized place.
 * @GEOCODE_PLACE_TYPE_SUPERNAME: An area covering multiple countries.
 * @GEOCODE_PLACE_TYPE_POINT_OF_INTEREST: A point of interest such as a school, hospital or tourist attraction.
 * @GEOCODE_PLACE_TYPE_SUBURB: A subdivision of a town such as a suburb or neighborhood.
 * @GEOCODE_PLACE_TYPE_COLLOQUIAL: A place known by a colloquial name.
 * @GEOCODE_PLACE_TYPE_ZONE: An area known within a specific context such as MSA or area code.
 * @GEOCODE_PLACE_TYPE_HISTORICAL_STATE: A historical primary administrative area within a country.
 * @GEOCODE_PLACE_TYPE_HISTORICAL_COUNTY: A historical secondary administrative area within a country.
 * @GEOCODE_PLACE_TYPE_CONTINENT: One of the major land masses on the Earth.
 * @GEOCODE_PLACE_TYPE_TIME_ZONE: An area defined by the Olson standard (tz database).
 * @GEOCODE_PLACE_TYPE_ESTATE: A housing development or subdivision known by name.
 * @GEOCODE_PLACE_TYPE_HISTORICAL_TOWN: A historical populated settlement that is no longer known by its original name.
 * @GEOCODE_PLACE_TYPE_OCEAN: One of the five major bodies of water on the Earth.
 * @GEOCODE_PLACE_TYPE_SEA: An area of open water smaller than an ocean.
 * @GEOCODE_PLACE_TYPE_SCHOOL: Institution designed for learning under the supervision of teachers.
 * @GEOCODE_PLACE_TYPE_PLACE_OF_WORSHIP: All places of worship independently of the religion or denomination.
 * @GEOCODE_PLACE_TYPE_RESTAURANT: Generally formal place with sit-down facilities selling full meals served by waiters.
 * @GEOCODE_PLACE_TYPE_BAR: A bar or pub.
 * @GEOCODE_PLACE_TYPE_LIGHT_RAIL_STATION: A light rail station or tram stop.
 *
 * Type of the place.
 */
typedef enum {
        GEOCODE_PLACE_TYPE_UNKNOWN = 0,
        GEOCODE_PLACE_TYPE_BUILDING,
        GEOCODE_PLACE_TYPE_STREET,
        GEOCODE_PLACE_TYPE_TOWN,
        GEOCODE_PLACE_TYPE_STATE,
        GEOCODE_PLACE_TYPE_COUNTY,
        GEOCODE_PLACE_TYPE_LOCAL_ADMINISTRATIVE_AREA,
        GEOCODE_PLACE_TYPE_POSTAL_CODE,
        GEOCODE_PLACE_TYPE_COUNTRY,
        GEOCODE_PLACE_TYPE_ISLAND,
        GEOCODE_PLACE_TYPE_AIRPORT,
        GEOCODE_PLACE_TYPE_RAILWAY_STATION,
        GEOCODE_PLACE_TYPE_BUS_STOP,
        GEOCODE_PLACE_TYPE_MOTORWAY,
        GEOCODE_PLACE_TYPE_DRAINAGE,
        GEOCODE_PLACE_TYPE_LAND_FEATURE,
        GEOCODE_PLACE_TYPE_MISCELLANEOUS,
        GEOCODE_PLACE_TYPE_SUPERNAME,
        GEOCODE_PLACE_TYPE_POINT_OF_INTEREST,
        GEOCODE_PLACE_TYPE_SUBURB,
        GEOCODE_PLACE_TYPE_COLLOQUIAL,
        GEOCODE_PLACE_TYPE_ZONE,
        GEOCODE_PLACE_TYPE_HISTORICAL_STATE,
        GEOCODE_PLACE_TYPE_HISTORICAL_COUNTY,
        GEOCODE_PLACE_TYPE_CONTINENT,
        GEOCODE_PLACE_TYPE_TIME_ZONE,
        GEOCODE_PLACE_TYPE_ESTATE,
        GEOCODE_PLACE_TYPE_HISTORICAL_TOWN,
        GEOCODE_PLACE_TYPE_OCEAN,
        GEOCODE_PLACE_TYPE_SEA,
        GEOCODE_PLACE_TYPE_SCHOOL,
        GEOCODE_PLACE_TYPE_PLACE_OF_WORSHIP,
        GEOCODE_PLACE_TYPE_RESTAURANT,
        GEOCODE_PLACE_TYPE_BAR,
        GEOCODE_PLACE_TYPE_LIGHT_RAIL_STATION
} GeocodePlaceType;


/**
 * GeocodePlaceOsmType:
 * @GEOCODE_PLACE_OSM_TYPE_UNKNOWN: Unknown type
 * @GEOCODE_PLACE_OSM_TYPE_NODE: Defines a point in space.
 * @GEOCODE_PLACE_OSM_TYPE_RELATION: Used to explain how other elements work together.
 * @GEOCODE_PLACE_OSM_TYPE_WAY: Defines a linear feature and area boundaries.
 *
 * Osm type of the place.
 */
typedef enum {
  GEOCODE_PLACE_OSM_TYPE_UNKNOWN,
  GEOCODE_PLACE_OSM_TYPE_NODE,
  GEOCODE_PLACE_OSM_TYPE_RELATION,
  GEOCODE_PLACE_OSM_TYPE_WAY
} GeocodePlaceOsmType;

#define GEOCODE_TYPE_PLACE (geocode_place_get_type ())

GeocodePlace *geocode_place_new                    (const char      *name,
                                                    GeocodePlaceType place_type);
GeocodePlace *geocode_place_new_with_location      (const char      *name,
                                                    GeocodePlaceType place_type,
                                                    GeocodeLocation *location);

gboolean geocode_place_equal                       (GeocodePlace *a,
                                                    GeocodePlace *b);

void geocode_place_set_name                        (GeocodePlace *place,
                                                    const char   *name);
const char *geocode_place_get_name                 (GeocodePlace *place);

GeocodePlaceType geocode_place_get_place_type      (GeocodePlace *place);

GeocodeBoundingBox *geocode_place_get_bounding_box (GeocodePlace *place);

void geocode_place_set_bounding_box                (GeocodePlace *place,
                                                    GeocodeBoundingBox *bbox);

void geocode_place_set_location                    (GeocodePlace    *place,
                                                    GeocodeLocation *location);
GeocodeLocation *geocode_place_get_location        (GeocodePlace *place);

void geocode_place_set_street_address              (GeocodePlace *place,
                                                    const char   *street_address);
const char *geocode_place_get_street_address       (GeocodePlace *place);

void geocode_place_set_street                      (GeocodePlace *place,
                                                    const char   *street);
const char *geocode_place_get_street               (GeocodePlace *place);

void geocode_place_set_building                    (GeocodePlace *place,
                                                    const char   *building);
const char *geocode_place_get_building             (GeocodePlace *place);

void geocode_place_set_postal_code                 (GeocodePlace *place,
                                                    const char   *postal_code);
const char *geocode_place_get_postal_code          (GeocodePlace *place);

void geocode_place_set_area                        (GeocodePlace *place,
                                                    const char   *area);
const char *geocode_place_get_area                 (GeocodePlace *place);

void geocode_place_set_town                        (GeocodePlace *place,
                                                    const char   *town);
const char *geocode_place_get_town                 (GeocodePlace *place);

void geocode_place_set_county                      (GeocodePlace *place,
                                                    const char   *county);
const char *geocode_place_get_county               (GeocodePlace *place);

void geocode_place_set_state                       (GeocodePlace *place,
                                                    const char   *state);
const char *geocode_place_get_state                (GeocodePlace *place);

void geocode_place_set_administrative_area         (GeocodePlace *place,
                                                    const char   *admin_area);
const char *geocode_place_get_administrative_area  (GeocodePlace *place);

void geocode_place_set_country_code                (GeocodePlace *place,
                                                    const char   *country_code);
const char *geocode_place_get_country_code         (GeocodePlace *place);

void geocode_place_set_country                     (GeocodePlace *place,
                                                    const char   *country);
const char *geocode_place_get_country              (GeocodePlace *place);

void geocode_place_set_continent                   (GeocodePlace *place,
                                                    const char   *continent);
const char *geocode_place_get_continent            (GeocodePlace *place);

GIcon *geocode_place_get_icon                      (GeocodePlace *place);

const char *geocode_place_get_osm_id               (GeocodePlace *place);
GeocodePlaceOsmType geocode_place_get_osm_type     (GeocodePlace *place);

G_END_DECLS

#endif /* GEOCODE_PLACE_H */
