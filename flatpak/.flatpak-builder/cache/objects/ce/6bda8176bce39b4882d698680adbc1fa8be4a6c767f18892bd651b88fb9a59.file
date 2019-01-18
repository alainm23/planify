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

#include <geocode-glib/geocode-error.h>
#include <geocode-glib/geocode-enum-types.h>
#include <math.h>
#include <string.h>
#include "geocode-location.h"

#define EARTH_RADIUS_KM 6372.795

/**
 * SECTION:geocode-location
 * @short_description: Geocode location object
 * @include: geocode-glib/geocode-glib.h
 *
 * The #GeocodeLocation instance represents a location on earth, with an
 * optional description.
 **/

struct _GeocodeLocationPrivate {
        gdouble            longitude;
        gdouble            latitude;
        gdouble            altitude;
        gdouble            accuracy;
        guint64            timestamp;
        char              *description;
        GeocodeLocationCRS crs;
};

enum {
        PROP_0,

        PROP_LATITUDE,
        PROP_LONGITUDE,
        PROP_ACCURACY,
        PROP_DESCRIPTION,
        PROP_TIMESTAMP,
        PROP_ALTITUDE,
        PROP_CRS,
};

G_DEFINE_TYPE (GeocodeLocation, geocode_location, G_TYPE_OBJECT)

static void
geocode_location_get_property (GObject    *object,
                               guint       property_id,
                               GValue     *value,
                               GParamSpec *pspec)
{
        GeocodeLocation *location = GEOCODE_LOCATION (object);

        switch (property_id) {
        case PROP_DESCRIPTION:
                g_value_set_string (value,
                                    geocode_location_get_description (location));
                break;

        case PROP_LATITUDE:
                g_value_set_double (value,
                                    geocode_location_get_latitude (location));
                break;

        case PROP_LONGITUDE:
                g_value_set_double (value,
                                    geocode_location_get_longitude (location));
                break;

        case PROP_ALTITUDE:
                g_value_set_double (value,
                                    geocode_location_get_altitude (location));
                break;

        case PROP_ACCURACY:
                g_value_set_double (value,
                                    geocode_location_get_accuracy (location));
                break;

        case PROP_CRS:
                g_value_set_enum (value,
                                  geocode_location_get_crs (location));
                break;

        case PROP_TIMESTAMP:
                g_value_set_uint64 (value,
                                    geocode_location_get_timestamp (location));
                break;

        default:
                /* We don't have any other property... */
                G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
                break;
        }
}

/**
 * geocode_location_equal:
 * @a: a location
 * @b: another location
 *
 * Compare two #GeocodeLocation instances for equality. This compares all fields
 * and only returns %TRUE if the instances are exactly equal. For example, if
 * both locations have the same physical coordinates, but one location has its
 * #GeocodeLocation:description property set and the other does not, %FALSE
 * will be returned. Similarly, if both locations have the same
 * #GeocodeLocation:latitude, #GeocodeLocation:longitude and
 * #GeocodeLocation:altitude, but a different #GeocodeLocation:accuracy or
 * #GeocodeLocation:timestamp, %FALSE will be returned. Or if both locations
 * have the same#GeocodeLocation:latitude and #GeocodeLocation:longitude but a
 * different #GeocodeLocation:altitude, %FALSE will be returned.
 *
 * Both instances must be non-%NULL.
 *
 * Returns: %TRUE if the instances are equal, %FALSE otherwise
 * Since: 3.23.1
 */
gboolean
geocode_location_equal (GeocodeLocation *a,
                        GeocodeLocation *b)
{
        g_return_val_if_fail (GEOCODE_IS_LOCATION (a), FALSE);
        g_return_val_if_fail (GEOCODE_IS_LOCATION (b), FALSE);

        return (a->priv->longitude == b->priv->longitude &&
                a->priv->latitude == b->priv->latitude &&
                a->priv->altitude == b->priv->altitude &&
                a->priv->accuracy == b->priv->accuracy &&
                a->priv->timestamp == b->priv->timestamp &&
                g_strcmp0 (a->priv->description, b->priv->description) == 0 &&
                a->priv->crs == b->priv->crs);
}

static void
geocode_location_set_latitude (GeocodeLocation *loc,
                               gdouble          latitude)
{
        g_return_if_fail (latitude >= -90.0 && latitude <= 90.0);

        loc->priv->latitude = latitude;
}

static void
geocode_location_set_longitude (GeocodeLocation *loc,
                                gdouble          longitude)
{
        g_return_if_fail (longitude >= -180.0 && longitude <= 180.0);

        loc->priv->longitude = longitude;
}

static void
geocode_location_set_altitude (GeocodeLocation *loc,
                               gdouble          altitude)
{
        loc->priv->altitude = altitude;
}

static void
geocode_location_set_accuracy (GeocodeLocation *loc,
                               gdouble          accuracy)
{
        g_return_if_fail (accuracy >= GEOCODE_LOCATION_ACCURACY_UNKNOWN);

        loc->priv->accuracy = accuracy;
}

static void
geocode_location_set_crs(GeocodeLocation   *loc,
                         GeocodeLocationCRS crs)
{
        g_return_if_fail (GEOCODE_IS_LOCATION (loc));

        loc->priv->crs = crs;
}

static void
geocode_location_set_timestamp (GeocodeLocation *loc,
                                guint64          timestamp)
{
        g_return_if_fail (GEOCODE_IS_LOCATION (loc));

        loc->priv->timestamp = timestamp;
}

static void
geocode_location_constructed (GObject *object)
{
        GeocodeLocation *location = GEOCODE_LOCATION (object);
        GTimeVal tv;

        if (location->priv->timestamp != 0)
                return;

        g_get_current_time (&tv);
        geocode_location_set_timestamp (location, tv.tv_sec);
}

static void
geocode_location_set_property(GObject      *object,
                              guint         property_id,
                              const GValue *value,
                              GParamSpec   *pspec)
{
        GeocodeLocation *location = GEOCODE_LOCATION (object);

        switch (property_id) {
        case PROP_DESCRIPTION:
                geocode_location_set_description (location,
                                                  g_value_get_string (value));
                break;

        case PROP_LATITUDE:
                geocode_location_set_latitude (location,
                                               g_value_get_double (value));
                break;

        case PROP_LONGITUDE:
                geocode_location_set_longitude (location,
                                                g_value_get_double (value));
                break;

        case PROP_ALTITUDE:
                geocode_location_set_altitude (location,
                                               g_value_get_double (value));
                break;

        case PROP_ACCURACY:
                geocode_location_set_accuracy (location,
                                                g_value_get_double (value));
                break;

        case PROP_CRS:
                geocode_location_set_crs (location,
                                          g_value_get_enum (value));
                break;

        case PROP_TIMESTAMP:
                geocode_location_set_timestamp (location,
                                                g_value_get_uint64 (value));
                break;

        default:
                /* We don't have any other property... */
                G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
                break;
        }
}

static gboolean
parse_geo_uri_special_parameters (GeocodeLocation *loc,
                                  const char      *params,
                                  GError         **error)
{
        char *end_ptr;
        char *next_token;
        char *description;
        char *token_end;
        int description_len;

        if (loc->priv->latitude != 0 || loc->priv->longitude != 0)
            goto err;

        if (strncmp (params, "q=", 2) != 0)
                goto err;

        next_token = ((char *)params) + 2;

        loc->priv->latitude = g_ascii_strtod (next_token, &end_ptr);
        if (*end_ptr != ',' || *end_ptr == *params)
                goto err;
        next_token = end_ptr + 1;

        loc->priv->longitude = g_ascii_strtod (next_token, &end_ptr);
        if (*end_ptr == *next_token)
                goto err;

        if (*end_ptr != '(' || *end_ptr == *next_token)
                goto err;
        next_token = end_ptr + 1;

        if ((token_end = strchr (next_token, ')')) == NULL)
                goto err;

        description_len = token_end - next_token;
        if (description_len <= 0)
            goto err;

        description = g_uri_unescape_segment (next_token,
                                              next_token + description_len,
                                              NULL);
        geocode_location_set_description (loc, description);
        g_free (description);
        return TRUE;

 err:
        g_set_error_literal (error,
                             GEOCODE_ERROR,
                             GEOCODE_ERROR_PARSE,
                             "Failed to parse geo URI parameters");
        return FALSE;
}

/*
  From RFC 5870:
      Both 'crs' and 'u' parameters MUST NOT appear more than once each.
      The 'crs' and 'u' parameters MUST be given before any other
      parameters that may be defined in future extensions.  The 'crs'
      parameter MUST be given first if both 'crs' and 'u' are used.
 */
static gboolean
parse_geo_uri_parameters (GeocodeLocation *loc,
                          const char      *params,
                          GError         **error)
{
        char **parameters;
        char *endptr;
        char *val;
        char *u = NULL;
        char *crs = NULL;
        int ret = TRUE;

        parameters = g_strsplit (params, ";", 2);
        if (parameters[0] == NULL)
                goto err;

        if (g_str_has_prefix (parameters[0], "u=")) {
                /*
                 * if u parameter is first, then there should not be any more
                 * parameters.
                 */
                if (parameters[1] != NULL)
                        goto err;

                u = parameters[0];
        } else if (g_str_has_prefix (parameters[0], "crs=")) {
                /*
                 * if crs parameter is first, then the next should be the u
                 * parameter or none.
                 */
                crs = parameters[0];
                if (parameters[1] != NULL){

                        if (!g_str_has_prefix (parameters[1], "u="))
                                goto err;

                        u = parameters[1];
                }
        } else {
                goto err;
        }

        if (u != NULL) {
                val = u + 2; /* len of 'u=' */
                loc->priv->accuracy = g_ascii_strtod (val, &endptr);
                if (*endptr != '\0')
                        goto err;
        }

        if (crs != NULL) {
                val = crs + 4; /* len of 'crs=' */
                if (g_strcmp0 (val, "wgs84"))
                        goto err;
        }
        goto out;

 err:
        ret = FALSE;
        g_set_error_literal (error,
                             GEOCODE_ERROR,
                             GEOCODE_ERROR_PARSE,
                             "Failed to parse geo URI parameters");
 out:
       g_strfreev (parameters);
       return ret;
}

/*
   From RFC 5870:
      geo-URI       = geo-scheme ":" geo-path
      geo-scheme    = "geo"
      geo-path      = coordinates p
      coordinates   = coord-a "," coord-b [ "," coord-c ]

      [...]

      The value of "-0" for <num> is allowed and is identical to "0".

      In case the URI identifies a location in the default CRS of WGS-84,
      the <coordinates> sub-components are further restricted as follows:

      coord-a        = latitude
      coord-b        = longitude
      coord-c        = altitude

      latitude       = [ "-" ] 1*2DIGIT [ "." 1*DIGIT ]
      longitude      = [ "-" ] 1*3DIGIT [ "." 1*DIGIT ]
      altitude       = [ "-" ] 1*DIGIT [ "." 1*DIGIT ]

       p             = [ crsp ] [ uncp ] *parameter
       crsp          = ";crs=" crslabel
       crslabel      = "wgs84" / labeltext
       uncp          = ";u=" uval
       uval          = pnum

       parameter     = ";" pname [ "=" pvalue ]
       pname         = labeltext
       pvalue        = 1*paramchar
       paramchar     = p-unreserved / unreserved / pct-encoded

       labeltext     = 1*( alphanum / "-" )
       pnum          = 1*DIGIT [ "." 1*DIGIT ]
       num           = [ "-" ] pnum
       unreserved    = alphanum / mark
       mark          = "-" / "_" / "." / "!" / "~" / "*" /
                        "'" / "(" / ")"
       pct-encoded   = "%" HEXDIG HEXDIG
*/
static gboolean
parse_geo_uri (GeocodeLocation *loc,
               const char      *uri,
               GError         **error)
{
        const char *uri_part;
        char *end_ptr;
        char *next_token;
        const char *s;

        /* bail out if we encounter whitespace in uri */
        s = uri;
        while (*s) {
                if (g_ascii_isspace (*s++))
                        goto err;
        }

        uri_part = (const char *) uri + strlen("geo") + 1;

        /* g_ascii_strtod is locale safe */
        loc->priv->latitude = g_ascii_strtod (uri_part, &end_ptr);
        if (*end_ptr != ',' || *end_ptr == *uri_part) {
                goto err;
        }
        next_token = end_ptr + 1;

        loc->priv->longitude = g_ascii_strtod (next_token, &end_ptr);
        if (*end_ptr == *next_token) {
                goto err;
        }
        if (*end_ptr == ',') {
                next_token = end_ptr + 1;
                loc->priv->altitude = g_ascii_strtod (next_token, &end_ptr);
                if (*end_ptr == *next_token) {
                        goto err;
                }
        }
        if (*end_ptr == ';') {
                next_token = end_ptr + 1;
                return parse_geo_uri_parameters (loc, next_token, error);
        } else if (*end_ptr == '?') {
                next_token = end_ptr + 1;
                return parse_geo_uri_special_parameters (loc,
                                                         next_token,
                                                         error);
        } else if (*end_ptr == '\0') {
                return TRUE;
        }
 err:
        g_set_error_literal (error,
                             GEOCODE_ERROR,
                             GEOCODE_ERROR_PARSE,
                             "Failed to parse geo URI");
        return FALSE;
}

static gboolean
parse_uri (GeocodeLocation *location,
           const char      *uri,
           GError         **error)
{
        char *scheme;
        int ret = TRUE;

        scheme = g_uri_parse_scheme (uri);
        if (scheme == NULL) {
                ret = FALSE;
                goto err;
        }

        if (g_strcmp0 (scheme, "geo") == 0) {
                if (!parse_geo_uri (location, uri, error))
                        ret = FALSE;
                goto out;
        } else {
                ret = FALSE;
                goto err;
        }

 err:
        if (error) {
                g_set_error_literal (error,
                                     GEOCODE_ERROR,
                                     GEOCODE_ERROR_NOT_SUPPORTED,
                                     "Unsupported or invalid URI scheme");
        }
 out:
        g_free (scheme);
        return ret;
}

static void
geocode_location_finalize (GObject *glocation)
{
        GeocodeLocation *location = (GeocodeLocation *) glocation;

        g_clear_pointer (&location->priv->description, g_free);

        G_OBJECT_CLASS (geocode_location_parent_class)->finalize (glocation);
}

static void
geocode_location_class_init (GeocodeLocationClass *klass)
{
        GObjectClass *glocation_class = G_OBJECT_CLASS (klass);
        GParamSpec *pspec;

        glocation_class->finalize = geocode_location_finalize;
        glocation_class->get_property = geocode_location_get_property;
        glocation_class->set_property = geocode_location_set_property;
        glocation_class->constructed = geocode_location_constructed;

        g_type_class_add_private (klass, sizeof (GeocodeLocationPrivate));

        /**
         * GeocodeLocation:description:
         *
         * The description of this location.
         */
        pspec = g_param_spec_string ("description",
                                     "Description",
                                     "Description of this location",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (glocation_class, PROP_DESCRIPTION, pspec);

        /**
         * GeocodeLocation:latitude:
         *
         * The latitude of this location in degrees.
         */
        pspec = g_param_spec_double ("latitude",
                                     "Latitude",
                                     "The latitude of this location in degrees",
                                     -90.0,
                                     90.0,
                                     0.0,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (glocation_class, PROP_LATITUDE, pspec);

        /**
         * GeocodeLocation:longitude:
         *
         * The longitude of this location in degrees.
         */
        pspec = g_param_spec_double ("longitude",
                                     "Longitude",
                                     "The longitude of this location in degrees",
                                     -180.0,
                                     180.0,
                                     0.0,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (glocation_class, PROP_LONGITUDE, pspec);

        /**
         * GeocodeLocation:altitude:
         *
         * The altitude of this location in meters.
         */
        pspec = g_param_spec_double ("altitude",
                                     "Altitude",
                                     "The altitude of this location in meters",
                                     GEOCODE_LOCATION_ALTITUDE_UNKNOWN,
                                     G_MAXDOUBLE,
                                     GEOCODE_LOCATION_ALTITUDE_UNKNOWN,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (glocation_class, PROP_ALTITUDE, pspec);

        /**
         * GeocodeLocation:accuracy:
         *
         * The accuracy of this location in meters.
         */
        pspec = g_param_spec_double ("accuracy",
                                     "Accuracy",
                                     "The accuracy of this location in meters",
                                     GEOCODE_LOCATION_ACCURACY_UNKNOWN,
                                     G_MAXDOUBLE,
                                     GEOCODE_LOCATION_ACCURACY_UNKNOWN,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (glocation_class, PROP_ACCURACY, pspec);


        /**
         * GeocodeLocation:crs:
         *
         * The Coordinate Reference System Identification of this location.
         * Only the value 'wgs84' is currently valid.
         */
        pspec = g_param_spec_enum ("crs",
                                   "Coordinate Reference System Identification",
                                   "Coordinate Reference System Identification",
                                   GEOCODE_TYPE_LOCATION_CRS,
                                   GEOCODE_LOCATION_CRS_WGS84,
                                   G_PARAM_READWRITE |
                                   G_PARAM_CONSTRUCT_ONLY |
                                   G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (glocation_class, PROP_CRS, pspec);

        /**
         * GeocodeLocation:timestamp:
         *
         * A timestamp in seconds since
         * <ulink url="http://en.wikipedia.org/wiki/Unix_epoch">Epoch</ulink>,
         * giving when the location was resolved from an address.
         *
         * A value of 0 (zero) will be interpreted as the current time.
         */
        pspec = g_param_spec_uint64 ("timestamp",
                                     "Timestamp",
                                     "The timestamp of this location "
                                     "in seconds since Epoch",
                                     0,
                                     G_MAXINT64,
                                     0,
                                     G_PARAM_READWRITE |
                                     G_PARAM_CONSTRUCT_ONLY |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (glocation_class, PROP_TIMESTAMP, pspec);
}

static void
geocode_location_init (GeocodeLocation *location)
{
        location->priv = G_TYPE_INSTANCE_GET_PRIVATE ((location),
                                                      GEOCODE_TYPE_LOCATION,
                                                      GeocodeLocationPrivate);

        location->priv->altitude = GEOCODE_LOCATION_ALTITUDE_UNKNOWN;
        location->priv->accuracy = GEOCODE_LOCATION_ACCURACY_UNKNOWN;
        location->priv->crs = GEOCODE_LOCATION_CRS_WGS84;
}

/**
 * geocode_location_new:
 * @latitude: a valid latitude
 * @longitude: a valid longitude
 * @accuracy: accuracy of location in meters
 *
 * Creates a new #GeocodeLocation object.
 *
 * Returns: a new #GeocodeLocation object. Use g_object_unref() when done.
 **/
GeocodeLocation *
geocode_location_new (gdouble latitude,
                      gdouble longitude,
                      gdouble accuracy)
{
        return g_object_new (GEOCODE_TYPE_LOCATION,
                             "latitude", latitude,
                             "longitude", longitude,
                             "accuracy", accuracy,
                             NULL);
}

/**
 * geocode_location_new_with_description:
 * @latitude: a valid latitude
 * @longitude: a valid longitude
 * @accuracy: accuracy of location in meters
 * @description: a description for the location
 *
 * Creates a new #GeocodeLocation object.
 *
 * Returns: a new #GeocodeLocation object. Use g_object_unref() when done.
 **/
GeocodeLocation *
geocode_location_new_with_description (gdouble     latitude,
                                       gdouble     longitude,
                                       gdouble     accuracy,
                                       const char *description)
{
        return g_object_new (GEOCODE_TYPE_LOCATION,
                             "latitude", latitude,
                             "longitude", longitude,
                             "accuracy", accuracy,
                             "description", description,
                             NULL);
}

/**
 * geocode_location_set_from_uri:
 * @loc: a #GeocodeLocation
 * @uri: a URI mapping out a location
 * @error: #GError for error reporting, or %NULL to ignore
 *
 * Initialize a #GeocodeLocation object with the given @uri.
 *
 * The URI should be in the geo scheme (RFC 5870) which in its simplest form
 * looks like:
 *
 * - geo:latitude,longitude
 *
 * An <ulink
 * url="http://developer.android.com/guide/components/intents-common.html#Maps">
 * Android extension</ulink> to set a description is also supported in the form of:
 *
 * - geo:0,0?q=latitude,longitude(description)
 *
 * Returns: %TRUE on success and %FALSE on error.
 **/
gboolean
geocode_location_set_from_uri (GeocodeLocation *loc,
                               const char      *uri,
                               GError         **error)
{
        return parse_uri (loc, uri, error);
}

/**
 * geocode_location_set_description:
 * @loc: a #GeocodeLocation
 * @description: a description for the location
 *
 * Sets the description of @loc to @description.
 **/
void
geocode_location_set_description (GeocodeLocation *loc,
                                  const char      *description)
{
        g_return_if_fail (GEOCODE_IS_LOCATION (loc));

        g_free (loc->priv->description);
        loc->priv->description = g_strdup (description);
}

/**
 * geocode_location_get_description:
 * @loc: a #GeocodeLocation
 *
 * Gets the description of location @loc.
 *
 * Returns: The description of location @loc.
 **/
const char *
geocode_location_get_description (GeocodeLocation *loc)
{
        g_return_val_if_fail (GEOCODE_IS_LOCATION (loc), NULL);

        return loc->priv->description;
}

/**
 * geocode_location_get_latitude:
 * @loc: a #GeocodeLocation
 *
 * Gets the latitude of location @loc.
 *
 * Returns: The latitude of location @loc.
 **/
gdouble
geocode_location_get_latitude (GeocodeLocation *loc)
{
        g_return_val_if_fail (GEOCODE_IS_LOCATION (loc), 0.0);

        return loc->priv->latitude;
}

/**
 * geocode_location_get_longitude:
 * @loc: a #GeocodeLocation
 *
 * Gets the longitude of location @loc.
 *
 * Returns: The longitude of location @loc.
 **/
gdouble
geocode_location_get_longitude (GeocodeLocation *loc)
{
        g_return_val_if_fail (GEOCODE_IS_LOCATION (loc), 0.0);

        return loc->priv->longitude;
}

/**
 * geocode_location_get_altitude:
 * @loc: a #GeocodeLocation
 *
 * Gets the altitude of location @loc.
 *
 * Returns: The altitude of location @loc.
 **/
gdouble
geocode_location_get_altitude (GeocodeLocation *loc)
{
        g_return_val_if_fail (GEOCODE_IS_LOCATION (loc),
                              GEOCODE_LOCATION_ALTITUDE_UNKNOWN);

        return loc->priv->altitude;
}

/**
 * geocode_location_get_accuracy:
 * @loc: a #GeocodeLocation
 *
 * Gets the accuracy (in meters) of location @loc.
 *
 * Returns: The accuracy of location @loc.
 **/
gdouble
geocode_location_get_accuracy (GeocodeLocation *loc)
{
        g_return_val_if_fail (GEOCODE_IS_LOCATION (loc),
                              GEOCODE_LOCATION_ACCURACY_UNKNOWN);

        return loc->priv->accuracy;
}

/**
 * geocode_location_get_crs:
 * @loc: a #GeocodeLocation
 *
 * Gets the Coordinate Reference System Identification of location @loc.
 *
 * Returns: The CRS of location @loc.
 **/
GeocodeLocationCRS
geocode_location_get_crs (GeocodeLocation *loc)
{
        g_return_val_if_fail (GEOCODE_IS_LOCATION (loc),
                              GEOCODE_LOCATION_CRS_WGS84);

        return loc->priv->crs;
}

/**
 * geocode_location_get_timestamp:
 * @loc: a #GeocodeLocation
 *
 * Gets the timestamp (in seconds since the Epoch) of location @loc. See
 * #GeocodeLocation:timestamp.
 *
 * Returns: The timestamp of location @loc.
 **/
guint64
geocode_location_get_timestamp (GeocodeLocation *loc)
{
        g_return_val_if_fail (GEOCODE_IS_LOCATION (loc), 0);

        return loc->priv->timestamp;
}

static gdouble
round_coord_n (gdouble coord, guint n)
{
  gdouble fac = pow (10, n);

  return round (coord * fac) / fac;
}

static char *
geo_uri_from_location (GeocodeLocation *loc)
{
        guint precision = 6; /* 0.1 meter precision */
        char *uri;
        char *coords;
        char *params;
        const char *crs = "wgs84";
        char lat[G_ASCII_DTOSTR_BUF_SIZE];
        char lon[G_ASCII_DTOSTR_BUF_SIZE];
        char alt[G_ASCII_DTOSTR_BUF_SIZE];
        char acc[G_ASCII_DTOSTR_BUF_SIZE];

        g_return_val_if_fail (GEOCODE_IS_LOCATION (loc), NULL);

        g_ascii_formatd (lat,
                         G_ASCII_DTOSTR_BUF_SIZE,
                         "%.6f",
                         round_coord_n (loc->priv->latitude, precision));
        g_ascii_formatd (lon,
                         G_ASCII_DTOSTR_BUF_SIZE,
                         "%.6f",
                         round_coord_n (loc->priv->longitude, precision));

        if (loc->priv->altitude != GEOCODE_LOCATION_ALTITUDE_UNKNOWN) {
                g_ascii_dtostr (alt, G_ASCII_DTOSTR_BUF_SIZE,
                                loc->priv->altitude);
                coords = g_strdup_printf ("%s,%s,%s", lat, lon, alt);
        } else {
                coords = g_strdup_printf ("%s,%s", lat, lon);
        }

        if (loc->priv->accuracy != GEOCODE_LOCATION_ACCURACY_UNKNOWN) {
                g_ascii_dtostr (acc, G_ASCII_DTOSTR_BUF_SIZE,
                                loc->priv->accuracy);
                params = g_strdup_printf (";crs=%s;u=%s", crs, acc);
        } else {
                params = g_strdup_printf (";crs=%s", crs);
        }

        uri = g_strconcat ("geo:", coords, params, NULL);
        g_free (coords);
        g_free (params);

        return uri;
}

/**
 * geocode_location_to_uri:
 * @loc: a #GeocodeLocation
 * @scheme: the scheme of the requested URI
 *
 * Creates a URI representing @loc in the scheme specified in @scheme.
 *
 * Returns: a URI representing the location. The returned string should be freed
 * with g_free() when no longer needed.
 **/
char *
geocode_location_to_uri (GeocodeLocation *loc,
                         GeocodeLocationURIScheme scheme)
{
        g_return_val_if_fail (GEOCODE_IS_LOCATION (loc), NULL);
        g_return_val_if_fail (scheme == GEOCODE_LOCATION_URI_SCHEME_GEO, NULL);

        return geo_uri_from_location (loc);
}

/**
 * geocode_location_get_distance_from:
 * @loca: a #GeocodeLocation
 * @locb: a #GeocodeLocation
 *
 * Calculates the distance in km, along the curvature of the Earth,
 * between 2 locations. Note that altitude changes are not
 * taken into account.
 *
 * Returns: a distance in km.
 **/
double
geocode_location_get_distance_from (GeocodeLocation *loca,
                                    GeocodeLocation *locb)
{
        gdouble dlat, dlon, lat1, lat2;
        gdouble a, c;

        g_return_val_if_fail (GEOCODE_IS_LOCATION (loca), 0.0);
        g_return_val_if_fail (GEOCODE_IS_LOCATION (locb), 0.0);

        /* Algorithm from:
         * http://www.movable-type.co.uk/scripts/latlong.html */

        dlat = (locb->priv->latitude - loca->priv->latitude) * M_PI / 180.0;
        dlon = (locb->priv->longitude - loca->priv->longitude) * M_PI / 180.0;
        lat1 = loca->priv->latitude * M_PI / 180.0;
        lat2 = locb->priv->latitude * M_PI / 180.0;

        a = sin (dlat / 2) * sin (dlat / 2) +
            sin (dlon / 2) * sin (dlon / 2) * cos (lat1) * cos (lat2);
        c = 2 * atan2 (sqrt (a), sqrt (1-a));
        return EARTH_RADIUS_KM * c;
}
