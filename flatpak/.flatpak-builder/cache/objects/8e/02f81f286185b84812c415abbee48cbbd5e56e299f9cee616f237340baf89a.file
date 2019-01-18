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

#ifndef GEOCODE_LOCATION_H
#define GEOCODE_LOCATION_H

#include <glib-object.h>

G_BEGIN_DECLS

GType geocode_location_get_type (void) G_GNUC_CONST;

#define GEOCODE_TYPE_LOCATION                  (geocode_location_get_type ())
#define GEOCODE_LOCATION(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), GEOCODE_TYPE_LOCATION, GeocodeLocation))
#define GEOCODE_IS_LOCATION(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GEOCODE_TYPE_LOCATION))
#define GEOCODE_LOCATION_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), GEOCODE_TYPE_LOCATION, GeocodeLocationClass))
#define GEOCODE_IS_LOCATION_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), GEOCODE_TYPE_LOCATION))
#define GEOCODE_LOCATION_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), GEOCODE_TYPE_LOCATION, GeocodeLocationClass))

typedef struct _GeocodeLocation        GeocodeLocation;
typedef struct _GeocodeLocationClass   GeocodeLocationClass;
typedef struct _GeocodeLocationPrivate GeocodeLocationPrivate;

/**
 * GeocodeLocation:
 *
 * All the fields in the #GeocodeLocation structure are private and should never be accessed directly.
**/
struct _GeocodeLocation {
        /* <private> */
        GObject parent_instance;
        GeocodeLocationPrivate *priv;
};

/**
 * GeocodeLocationClass:
 *
 * All the fields in the #GeocodeLocationClass structure are private and should never be accessed directly.
**/
struct _GeocodeLocationClass {
        /* <private> */
        GObjectClass parent_class;
};

G_DEFINE_AUTOPTR_CLEANUP_FUNC (GeocodeLocation, g_object_unref)

/**
 * GeocodeLocationURIScheme:
 * @GEOCODE_LOCATION_URI_SCHEME_GEO: The 'geo' URI scheme, RFC 5870
 *
 * The URI scheme for this location.
 */
typedef enum {
	GEOCODE_LOCATION_URI_SCHEME_GEO = 0
} GeocodeLocationURIScheme;

/**
 * GeocodeLocationCRS:
 * @GEOCODE_LOCATION_CRS_WGS84: CRS is World Geodetic System, standard for Earth.
 *
 * Coordinate Reference System Identification for a location.
 */
typedef enum {
	GEOCODE_LOCATION_CRS_WGS84 = 0
} GeocodeLocationCRS;

/**
 * GEOCODE_LOCATION_ALTITUDE_UNKNOWN:
 *
 * Constant representing unknown altitude.
 */
#define GEOCODE_LOCATION_ALTITUDE_UNKNOWN -G_MAXDOUBLE

/**
 * GEOCODE_LOCATION_ACCURACY_UNKNOWN:
 *
 * Constant representing unknown accuracy.
 */
#define GEOCODE_LOCATION_ACCURACY_UNKNOWN -1

/**
 * GEOCODE_LOCATION_ACCURACY_STREET:
 *
 * Constant representing street-level accuracy.
 */
#define GEOCODE_LOCATION_ACCURACY_STREET 1000 /* 1 km */

/**
 * GEOCODE_LOCATION_ACCURACY_CITY:
 *
 * Constant representing city-level accuracy.
 */
#define GEOCODE_LOCATION_ACCURACY_CITY 15000 /* 15 km */

/**
 * GEOCODE_LOCATION_ACCURACY_REGION:
 *
 * Constant representing region-level accuracy.
 */
#define GEOCODE_LOCATION_ACCURACY_REGION 50000 /* 50 km */

/**
 * GEOCODE_LOCATION_ACCURACY_COUNTRY:
 *
 * Constant representing country-level accuracy.
 */
#define GEOCODE_LOCATION_ACCURACY_COUNTRY 300000 /* 300 km */

/**
 * GEOCODE_LOCATION_ACCURACY_CONTINENT:
 *
 * Constant representing continent-level accuracy.
 */
#define GEOCODE_LOCATION_ACCURACY_CONTINENT 3000000 /* 3000 km */

#define GEOCODE_TYPE_LOCATION (geocode_location_get_type ())

GeocodeLocation *geocode_location_new                  (gdouble latitude,
                                                        gdouble longitude,
                                                        gdouble accuracy);

GeocodeLocation *geocode_location_new_with_description (gdouble     latitude,
                                                        gdouble     longitude,
                                                        gdouble     accuracy,
                                                        const char *description);

gboolean geocode_location_equal                        (GeocodeLocation *a,
                                                        GeocodeLocation *b);

gboolean geocode_location_set_from_uri                 (GeocodeLocation *loc,
                                                        const char      *uri,
                                                        GError         **error);

char * geocode_location_to_uri                         (GeocodeLocation *loc,
                                                        GeocodeLocationURIScheme scheme);

double geocode_location_get_distance_from              (GeocodeLocation *loca,
                                                        GeocodeLocation *locb);

void geocode_location_set_description                  (GeocodeLocation *loc,
                                                        const char      *description);

const char *geocode_location_get_description           (GeocodeLocation *loc);

gdouble geocode_location_get_latitude                  (GeocodeLocation *loc);
gdouble geocode_location_get_longitude                 (GeocodeLocation *loc);
gdouble geocode_location_get_altitude                  (GeocodeLocation *loc);
GeocodeLocationCRS  geocode_location_get_crs           (GeocodeLocation *loc);
gdouble geocode_location_get_accuracy                  (GeocodeLocation *loc);
guint64 geocode_location_get_timestamp                 (GeocodeLocation *loc);

G_END_DECLS

#endif /* GEOCODE_LOCATION_H */
