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

#include <gio/gio.h>
#include <geocode-glib/geocode-place.h>
#include <geocode-glib/geocode-bounding-box.h>
#include <geocode-glib/geocode-enum-types.h>
#include <geocode-glib/geocode-glib-private.h>

/**
 * SECTION:geocode-place
 * @short_description: Geocode place object
 * @include: geocode-glib/geocode-glib.h
 *
 * The #GeocodePlace instance represents a place on earth. While
 * #GeocodeLocation represents a point on the planet, #GeocodePlace represents
 * places, e.g street, town, village, county, country or points of interest
 * (POI) etc.
 **/

struct _GeocodePlacePrivate {
        char *name;
        GeocodePlaceType place_type;
        GeocodeLocation *location;
        GeocodeBoundingBox *bbox;

        char *street_address;
        char *street;
        char *building;
        char *postal_code;
        char *area;
        char *town;
        char *county;
        char *state;
        char *admin_area;
        char *country_code;
        char *country;
        char *continent;
        char *osm_id;
        GeocodePlaceOsmType osm_type;
};

enum {
        PROP_0,

        PROP_NAME,
        PROP_PLACE_TYPE,
        PROP_LOCATION,
        PROP_STREET_ADDRESS,
        PROP_STREET,
        PROP_BUILDING,
        PROP_POSTAL_CODE,
        PROP_AREA,
        PROP_TOWN,
        PROP_COUNTY,
        PROP_STATE,
        PROP_ADMINISTRATIVE_AREA,
        PROP_COUNTRY_CODE,
        PROP_COUNTRY,
        PROP_CONTINENT,
        PROP_ICON,
        PROP_BBOX,
        PROP_OSM_ID,
        PROP_OSM_TYPE
};

G_DEFINE_TYPE (GeocodePlace, geocode_place, G_TYPE_OBJECT)

static void
geocode_place_get_property (GObject    *object,
                            guint       property_id,
                            GValue     *value,
                            GParamSpec *pspec)
{
        GeocodePlace *place = GEOCODE_PLACE (object);

        switch (property_id) {
        case PROP_NAME:
                g_value_set_string (value,
                                    geocode_place_get_name (place));
                break;

        case PROP_PLACE_TYPE:
                g_value_set_enum (value,
                                  geocode_place_get_place_type (place));
                break;

        case PROP_LOCATION:
                g_value_set_object (value,
                                    geocode_place_get_location (place));
                break;

        case PROP_STREET_ADDRESS:
                g_value_set_string (value,
                                    geocode_place_get_street_address (place));
                break;

        case PROP_STREET:
                g_value_set_string (value,
                                    geocode_place_get_street (place));
                break;

        case PROP_BUILDING:
                g_value_set_string (value,
                                    geocode_place_get_building (place));
                break;

        case PROP_POSTAL_CODE:
                g_value_set_string (value,
                                    geocode_place_get_postal_code (place));
                break;

        case PROP_AREA:
                g_value_set_string (value,
                                    geocode_place_get_area (place));
                break;

        case PROP_TOWN:
                g_value_set_string (value,
                                    geocode_place_get_town (place));
                break;

        case PROP_COUNTY:
                g_value_set_string (value,
                                    geocode_place_get_county (place));
                break;

        case PROP_STATE:
                g_value_set_string (value,
                                    geocode_place_get_state (place));
                break;

        case PROP_ADMINISTRATIVE_AREA:
                g_value_set_string (value,
                                    geocode_place_get_administrative_area (place));
                break;

        case PROP_COUNTRY_CODE:
                g_value_set_string (value,
                                    geocode_place_get_country_code (place));
                break;

        case PROP_COUNTRY:
                g_value_set_string (value,
                                    geocode_place_get_country (place));
                break;

        case PROP_CONTINENT:
                g_value_set_string (value,
                                    geocode_place_get_continent (place));
                break;

        case PROP_ICON:
                g_value_set_object (value,
                                    geocode_place_get_icon (place));
                break;

        case PROP_BBOX:
                g_value_set_object (value,
                                    geocode_place_get_bounding_box (place));
                break;

        case PROP_OSM_ID:
                g_value_set_string (value,
                                    geocode_place_get_osm_id (place));
                break;

        case PROP_OSM_TYPE:
                g_value_set_enum (value,
                                  geocode_place_get_osm_type (place));
                break;

        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
                break;
        }
}

static void
geocode_place_set_property(GObject      *object,
                           guint         property_id,
                           const GValue *value,
                           GParamSpec   *pspec)
{
        GeocodePlace *place = GEOCODE_PLACE (object);

        switch (property_id) {
        case PROP_NAME:
                place->priv->name = g_value_dup_string (value);
                break;

        case PROP_PLACE_TYPE:
                place->priv->place_type = g_value_get_enum (value);
                break;

        case PROP_LOCATION:
                place->priv->location = g_value_dup_object (value);
                break;

        case PROP_STREET_ADDRESS:
                geocode_place_set_street_address (place,
                                                  g_value_get_string (value));
                break;

        case PROP_STREET:
                geocode_place_set_street (place, g_value_get_string (value));
                break;

        case PROP_BUILDING:
                geocode_place_set_building (place, g_value_get_string (value));
                break;

        case PROP_POSTAL_CODE:
                geocode_place_set_postal_code (place,
                                               g_value_get_string (value));
                break;

        case PROP_AREA:
                geocode_place_set_area (place, g_value_get_string (value));
                break;

        case PROP_TOWN:
                geocode_place_set_town (place, g_value_get_string (value));
                break;

        case PROP_COUNTY:
                geocode_place_set_county (place, g_value_get_string (value));
                break;

        case PROP_STATE:
                geocode_place_set_state (place, g_value_get_string (value));
                break;

        case PROP_ADMINISTRATIVE_AREA:
                geocode_place_set_administrative_area (place,
                                                       g_value_get_string (value));
                break;

        case PROP_COUNTRY_CODE:
                geocode_place_set_country_code (place,
                                                g_value_get_string (value));
                break;

        case PROP_COUNTRY:
                geocode_place_set_country (place,
                                           g_value_get_string (value));
                break;

        case PROP_CONTINENT:
                geocode_place_set_continent (place, g_value_get_string (value));
                break;

        case PROP_BBOX:
                place->priv->bbox = g_value_dup_object (value);
                break;

        case PROP_OSM_ID:
                place->priv->osm_id = g_value_dup_string (value);
                break;

        case PROP_OSM_TYPE:
                place->priv->osm_type = g_value_get_enum (value);
                break;

        default:
                G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
                break;
        }
}

static void
geocode_place_dispose (GObject *gplace)
{
        GeocodePlace *place = (GeocodePlace *) gplace;

        g_clear_object (&place->priv->location);
        g_clear_object (&place->priv->bbox);

        g_clear_pointer (&place->priv->name, g_free);
        g_clear_pointer (&place->priv->osm_id, g_free);
        g_clear_pointer (&place->priv->street_address, g_free);
        g_clear_pointer (&place->priv->street, g_free);
        g_clear_pointer (&place->priv->building, g_free);
        g_clear_pointer (&place->priv->postal_code, g_free);
        g_clear_pointer (&place->priv->area, g_free);
        g_clear_pointer (&place->priv->town, g_free);
        g_clear_pointer (&place->priv->county, g_free);
        g_clear_pointer (&place->priv->state, g_free);
        g_clear_pointer (&place->priv->admin_area, g_free);
        g_clear_pointer (&place->priv->country_code, g_free);
        g_clear_pointer (&place->priv->country, g_free);
        g_clear_pointer (&place->priv->continent, g_free);

        G_OBJECT_CLASS (geocode_place_parent_class)->dispose (gplace);
}

static void
geocode_place_class_init (GeocodePlaceClass *klass)
{
        GObjectClass *gplace_class = G_OBJECT_CLASS (klass);
        GParamSpec *pspec;

        gplace_class->dispose = geocode_place_dispose;
        gplace_class->get_property = geocode_place_get_property;
        gplace_class->set_property = geocode_place_set_property;

        g_type_class_add_private (klass, sizeof (GeocodePlacePrivate));

        /**
         * GeocodePlace:name:
         *
         * The name of the place.
         */
        pspec = g_param_spec_string ("name",
                                     "Name",
                                     "Name",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_NAME, pspec);

        /**
         * GeocodePlace:place-type:
         *
         * The type of the place.
         */
        pspec = g_param_spec_enum ("place-type",
                                   "PlaceType",
                                   "Place Type",
                                   GEOCODE_TYPE_PLACE_TYPE,
                                   GEOCODE_PLACE_TYPE_UNKNOWN,
                                   G_PARAM_READWRITE |
                                   G_PARAM_CONSTRUCT_ONLY |
                                   G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_PLACE_TYPE, pspec);

        /**
         * GeocodePlace:location:
         *
         * The location info for the place.
         */
        pspec = g_param_spec_object ("location",
                                     "Location",
                                     "Location Info",
                                     GEOCODE_TYPE_LOCATION,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_LOCATION, pspec);

        /**
         * GeocodePlace:street-address:
         *
         * The street address.
         */
        pspec = g_param_spec_string ("street-address",
                                     "StreetAddress",
                                     "Street Address",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_STREET_ADDRESS, pspec);

        /**
         * GeocodePlace:street:
         *
         * The street name.
         */
        pspec = g_param_spec_string ("street",
                                     "Street",
                                     "Street name",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_STREET, pspec);

        /**
         * GeocodePlace:building:
         *
         * A specific building on a street or in an area.
         */
        pspec = g_param_spec_string ("building",
                                     "Building",
                                     "A specific building on a street or in an area",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_BUILDING, pspec);

        /**
         * GeocodePlace:postal-code:
         *
         * The postal code.
         */
        pspec = g_param_spec_string ("postal-code",
                                     "PostalCode",
                                     "Postal Code",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_POSTAL_CODE, pspec);

        /**
         * GeocodePlace:area:
         *
         * A named area such as a campus or neighborhood.
         */
        pspec = g_param_spec_string ("area",
                                     "Area",
                                     "A named area such as a campus or neighborhood",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_AREA, pspec);

        /**
         * GeocodePlace:town:
         *
         * The town.
         */
        pspec = g_param_spec_string ("town",
                                     "Town",
                                     "Town",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_TOWN, pspec);

        /**
         * GeocodePlace:state:
         *
         * The state.
         */
        pspec = g_param_spec_string ("state",
                                     "State",
                                     "State",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_STATE, pspec);

        /**
         * GeocodePlace:county:
         *
         * The county.
         */
        pspec = g_param_spec_string ("county",
                                     "County",
                                     "County",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_COUNTY, pspec);

        /**
         * GeocodePlace:administrative-area:
         *
         * The local administrative area.
         */
        pspec = g_param_spec_string ("administrative-area",
                                     "AdministrativeArea",
                                     "Local administrative area",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_ADMINISTRATIVE_AREA, pspec);

        /**
         * GeocodePlace:country-code:
         *
         * The country code.
         */
        pspec = g_param_spec_string ("country-code",
                                     "CountryCode",
                                     "ISO Country Code",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_COUNTRY_CODE, pspec);

        /**
         * GeocodePlace:country:
         *
         * The country.
         */
        pspec = g_param_spec_string ("country",
                                     "Country",
                                     "Country",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_COUNTRY, pspec);

        /**
         * GeocodePlace:continent:
         *
         * The continent.
         */
        pspec = g_param_spec_string ("continent",
                                     "Continent",
                                     "Continent",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_CONTINENT, pspec);

        /**
         * GeocodePlace:icon:
         *
         * #GIcon representing the @GeocodePlace.
         */
        pspec = g_param_spec_object ("icon",
                                     "Icon",
                                     "An icon representing the the place",
                                     G_TYPE_ICON,
                                     G_PARAM_READABLE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_ICON, pspec);

        /**
         * GeocodePlace:bounding-box:
         *
         * The bounding box for the place.
         */
        pspec = g_param_spec_object ("bounding-box",
                                     "Bounding Box",
                                     "The bounding box for the place",
                                     GEOCODE_TYPE_BOUNDING_BOX,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_BBOX, pspec);

        /**
         * GeocodePlace:osm-id:
         *
         * The OpenStreetMap id of the place.
         */
        pspec = g_param_spec_string ("osm-id",
                                     "OSM ID",
                                     "The OpenStreetMap ID of the place",
                                     NULL,
                                     G_PARAM_READWRITE |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_OSM_ID, pspec);

        /**
         * GeocodePlace:osm-type:
         *
         * The OpenStreetMap type of the place.
         */
        pspec = g_param_spec_enum ("osm-type",
                                   "OSM Type",
                                   "The OpenStreetMap type of the place",
                                   GEOCODE_TYPE_PLACE_OSM_TYPE,
                                   GEOCODE_PLACE_OSM_TYPE_UNKNOWN,
                                   G_PARAM_READWRITE |
                                   G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gplace_class, PROP_OSM_TYPE, pspec);
}

static void
geocode_place_init (GeocodePlace *place)
{
        place->priv = G_TYPE_INSTANCE_GET_PRIVATE ((place),
                                                      GEOCODE_TYPE_PLACE,
                                                      GeocodePlacePrivate);
        place->priv->bbox = NULL;
        place->priv->osm_type = GEOCODE_PLACE_OSM_TYPE_UNKNOWN;
}

/**
 * geocode_place_new:
 * @name: the name of place
 * @place_type: the type of place
 *
 * Creates a new #GeocodePlace object.
 *
 * Returns: a new #GeocodePlace object. Use g_object_unref() when done.
 **/
GeocodePlace *
geocode_place_new (const char      *name,
                   GeocodePlaceType place_type)
{
        return g_object_new (GEOCODE_TYPE_PLACE,
                             "name", name,
                             "place-type", place_type,
                             NULL);
}

/**
 * geocode_place_new_with_location:
 * @name: the name of place
 * @place_type: the type of place
 * @location: the location info for the place
 *
 * Creates a new #GeocodePlace object.
 *
 * Returns: a new #GeocodePlace object. Use g_object_unref() when done.
 **/
GeocodePlace *
geocode_place_new_with_location (const char      *name,
                                 GeocodePlaceType place_type,
                                 GeocodeLocation *location)
{
        return g_object_new (GEOCODE_TYPE_PLACE,
                             "name", name,
                             "place-type", place_type,
                             "location", location,
                             NULL);
}

/* NULL-safe #GeocodeLocation equality check. */
static gboolean
location_equal0 (GeocodeLocation *a,
                 GeocodeLocation *b)
{
        return ((a == NULL && b == NULL) ||
                (a != NULL && b != NULL && geocode_location_equal (a, b)));
}

/* NULL-safe #GeocodeBoundingBox equality check. */
static gboolean
bbox_equal0 (GeocodeBoundingBox *a,
             GeocodeBoundingBox *b)
{
        return ((a == NULL && b == NULL) ||
                (a != NULL && b != NULL && geocode_bounding_box_equal (a, b)));
}

/**
 * geocode_place_equal:
 * @a: a place
 * @b: another place
 *
 * Compare two #GeocodePlace instances for equality. This compares all fields
 * and only returns %TRUE if the instances are exactly equal. For example, if
 * both places have the same #GeocodePlace:location, but place @b has its
 * #GeocodePlace:continent property set and place @a does not, %FALSE will be
 * returned.
 *
 * Both instances must be non-%NULL.
 *
 * Returns: %TRUE if the instances are equal, %FALSE otherwise
 * Since: 3.23.1
 */
gboolean
geocode_place_equal (GeocodePlace *a,
                     GeocodePlace *b)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (a), FALSE);
        g_return_val_if_fail (GEOCODE_IS_PLACE (b), FALSE);

        return (g_strcmp0 (a->priv->name, b->priv->name) == 0 &&
                a->priv->place_type == b->priv->place_type &&
                location_equal0 (a->priv->location, b->priv->location) &&
                bbox_equal0 (a->priv->bbox, b->priv->bbox) &&
                g_strcmp0 (a->priv->street_address, b->priv->street_address) == 0 &&
                g_strcmp0 (a->priv->street, b->priv->street) == 0 &&
                g_strcmp0 (a->priv->building, b->priv->building) == 0 &&
                g_strcmp0 (a->priv->postal_code, b->priv->postal_code) == 0 &&
                g_strcmp0 (a->priv->area, b->priv->area) == 0 &&
                g_strcmp0 (a->priv->town, b->priv->town) == 0 &&
                g_strcmp0 (a->priv->county, b->priv->county) == 0 &&
                g_strcmp0 (a->priv->state, b->priv->state) == 0 &&
                g_strcmp0 (a->priv->admin_area, b->priv->admin_area) == 0 &&
                g_strcmp0 (a->priv->country_code, b->priv->country_code) == 0 &&
                g_strcmp0 (a->priv->country, b->priv->country) == 0 &&
                g_strcmp0 (a->priv->continent, b->priv->continent) == 0 &&
                g_strcmp0 (a->priv->osm_id, b->priv->osm_id) == 0 &&
                a->priv->osm_type == b->priv->osm_type);
}

/**
 * geocode_place_set_name:
 * @place: A place
 * @name: the name of place
 *
 * Sets the name of the @place to @name.
 **/
void
geocode_place_set_name (GeocodePlace *place,
                        const char   *name)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (name != NULL);

        g_free (place->priv->name);
        place->priv->name = g_strdup (name);
}

/**
 * geocode_place_get_name:
 * @place: A place
 *
 * Gets the name of the @place.
 *
 * Returns: The name of the @place.
 **/
const char *
geocode_place_get_name (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->name;

}

/**
 * geocode_place_get_place_type:
 * @place: A place
 *
 * Gets the type of the @place.
 *
 * Returns: The type of the @place.
 **/
GeocodePlaceType
geocode_place_get_place_type (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place),
                              GEOCODE_PLACE_TYPE_UNKNOWN);

        return place->priv->place_type;
}

/**
 * geocode_place_set_location:
 * @place: A place
 * @location: A location
 *
 * Sets the location of @place to @location.
 **/
void
geocode_place_set_location (GeocodePlace *place,
                            GeocodeLocation *location)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (GEOCODE_IS_LOCATION (location));

        g_clear_object (&place->priv->location);
        place->priv->location = g_object_ref (location);
}

/**
 * geocode_place_get_location:
 * @place: A place
 *
 * Gets the associated location object.
 *
 * Returns: (transfer none): The associated location object.
 **/
GeocodeLocation *
geocode_place_get_location (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->location;
}

/**
 * geocode_place_set_street_address:
 * @place: A place
 * @street_address: a street address for the place
 *
 * Sets the street address of @place to @street_address.
 **/
void
geocode_place_set_street_address (GeocodePlace *place,
                                  const char   *street_address)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (street_address != NULL);

        g_free (place->priv->street_address);
        place->priv->street_address = g_strdup (street_address);
}

/**
 * geocode_place_get_street_address:
 * @place: A place
 *
 * Gets the street address of the @place.
 *
 * Returns: The street address of the @place.
 **/
const char *
geocode_place_get_street_address (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->street_address;
}

/**
 * geocode_place_set_street:
 * @place: A place
 * @street: a street
 *
 * Sets the street of @place to @street.
 **/
void
geocode_place_set_street (GeocodePlace *place,
                          const char   *street)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (street != NULL);

        g_free (place->priv->street);
        place->priv->street = g_strdup (street);
}

/**
 * geocode_place_get_street:
 * @place: A place
 *
 * Gets the street of the @place.
 *
 * Returns: The street of the @place.
 **/
const char *
geocode_place_get_street (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->street;
}

/**
 * geocode_place_set_building:
 * @place: A place
 * @building: a building
 *
 * Sets the building of @place to @building.
 **/
void
geocode_place_set_building (GeocodePlace *place,
                            const char   *building)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (building != NULL);

        g_free (place->priv->building);
        place->priv->building = g_strdup (building);
}

/**
 * geocode_place_get_building:
 * @place: A place
 *
 * Gets the building of the @place.
 *
 * Returns: The building of the @place.
 **/
const char *
geocode_place_get_building (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->building;
}

/**
 * geocode_place_set_postal_code:
 * @place: A place
 * @postal_code: a postal code for the place
 *
 * Sets the postal code of @place to @postal_code.
 **/
void
geocode_place_set_postal_code (GeocodePlace *place,
                               const char   *postal_code)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (postal_code != NULL);

        g_free (place->priv->postal_code);
        place->priv->postal_code = g_strdup (postal_code);
}

/**
 * geocode_place_get_postal_code:
 * @place: A place
 *
 * Gets the postal code of the @place.
 *
 * Returns: The postal code of the @place.
 **/
const char *
geocode_place_get_postal_code (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->postal_code;
}

/**
 * geocode_place_set_area:
 * @place: A place
 * @area: a area
 *
 * Sets the area of @place to @area.
 **/
void
geocode_place_set_area (GeocodePlace *place,
                        const char   *area)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (area != NULL);

        g_free (place->priv->area);
        place->priv->area = g_strdup (area);
}

/**
 * geocode_place_get_area:
 * @place: A place
 *
 * Gets the area of the @place.
 *
 * Returns: The area of the @place.
 **/
const char *
geocode_place_get_area (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->area;
}

/**
 * geocode_place_set_town:
 * @place: A place
 * @town: a town for the place
 *
 * Sets the town of @place to @town.
 **/
void
geocode_place_set_town (GeocodePlace *place,
                        const char   *town)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (town != NULL);

        g_free (place->priv->town);
        place->priv->town = g_strdup (town);
}

/**
 * geocode_place_get_town:
 * @place: A place
 *
 * Gets the town of the @place.
 *
 * Returns: The town of the @place.
 **/
const char *
geocode_place_get_town (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->town;
}

/**
 * geocode_place_set_county:
 * @place: A place
 * @county: a county for the place
 *
 * Sets the county of @place to @county.
 **/
void
geocode_place_set_county (GeocodePlace *place,
                          const char   *county)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (county != NULL);

        g_free (place->priv->county);
        place->priv->county = g_strdup (county);
}

/**
 * geocode_place_get_county:
 * @place: A place
 *
 * Gets the county of the @place.
 *
 * Returns: The country of the @place.
 **/
const char *
geocode_place_get_county (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->county;
}

/**
 * geocode_place_set_state:
 * @place: A place
 * @state: a state for the place
 *
 * Sets the state of @place to @state.
 **/
void
geocode_place_set_state (GeocodePlace *place,
                         const char   *state)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (state != NULL);

        g_free (place->priv->state);
        place->priv->state = g_strdup (state);
}

/**
 * geocode_place_get_state:
 * @place: A place
 *
 * Gets the state of the @place.
 *
 * Returns: The state of the @place.
 **/
const char *
geocode_place_get_state (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->state;
}

/**
 * geocode_place_set_administrative_area:
 * @place: A place
 * @admin_area: an administrative area for the place
 *
 * Sets the local administrative area of @place to @admin_area.
 **/
void
geocode_place_set_administrative_area (GeocodePlace *place,
                                       const char   *admin_area)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (admin_area != NULL);

        g_free (place->priv->admin_area);
        place->priv->admin_area = g_strdup (admin_area);
}

/**
 * geocode_place_get_administrative_area:
 * @place: A place
 *
 * Gets the local administrative area of the @place.
 *
 * Returns: The local administrative area of the @place.
 **/
const char *
geocode_place_get_administrative_area (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->admin_area;
}

/**
 * geocode_place_set_country_code:
 * @place: A place
 * @country_code: an ISO country code for the place
 *
 * Sets the ISO country code of @place to @country_code.
 **/
void
geocode_place_set_country_code (GeocodePlace *place,
                                const char   *country_code)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (country_code != NULL);

        g_free (place->priv->country_code);
        place->priv->country_code = g_utf8_strup (country_code, -1);
}

/**
 * geocode_place_get_country_code:
 * @place: A place
 *
 * Gets the ISO-3166 country code of the @place.
 *
 * Returns: The ISO-3166 country code of the @place, in upper case.
 **/
const char *
geocode_place_get_country_code (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->country_code;
}

/**
 * geocode_place_set_country:
 * @place: A place
 * @country: a country for the place
 *
 * Sets the country of @place to @country.
 **/
void
geocode_place_set_country (GeocodePlace *place,
                           const char   *country)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (country != NULL);

        g_free (place->priv->country);
        place->priv->country = g_strdup (country);
}

/**
 * geocode_place_get_country:
 * @place: A place
 *
 * Gets the country of the @place.
 *
 * Returns: The country of the @place.
 **/
const char *
geocode_place_get_country (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->country;
}

/**
 * geocode_place_set_continent:
 * @place: A place
 * @continent: a continent for the place
 *
 * Sets the continent of @place to @continent.
 **/
void
geocode_place_set_continent (GeocodePlace *place,
                             const char   *continent)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (continent != NULL);

        g_free (place->priv->continent);
        place->priv->continent = g_strdup (continent);
}

/**
 * geocode_place_get_continent:
 * @place: A place
 *
 * Gets the continent of the @place.
 *
 * Returns: The continent of the @place.
 **/
const char *
geocode_place_get_continent (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->continent;
}

static const char *
get_icon_name (GeocodePlace *place)
{
        switch ((int) place->priv->place_type) {
        case GEOCODE_PLACE_TYPE_BUILDING:
                return "poi-building";

        case GEOCODE_PLACE_TYPE_TOWN:
                return "poi-town";

        case GEOCODE_PLACE_TYPE_AIRPORT:
                return "poi-airport";

        case GEOCODE_PLACE_TYPE_RAILWAY_STATION:
                return "poi-railway-station";

        case GEOCODE_PLACE_TYPE_BUS_STOP:
                return "poi-bus-stop";

        case GEOCODE_PLACE_TYPE_STREET:
                return "poi-car";

        case GEOCODE_PLACE_TYPE_SCHOOL:
                return "poi-school";

        case GEOCODE_PLACE_TYPE_PLACE_OF_WORSHIP:
                return "poi-place-of-worship";

        case GEOCODE_PLACE_TYPE_RESTAURANT:
                return "poi-restaurant";

        case GEOCODE_PLACE_TYPE_BAR:
                return "poi-bar";

        case GEOCODE_PLACE_TYPE_LIGHT_RAIL_STATION:
                return "poi-light-rail-station";

        default:
                return "poi-marker"; /* generic marker */
        }
}

/**
 * geocode_place_get_icon:
 * @place: A place
 *
 * Gets the #GIcon representing the @place.
 *
 * Returns: (transfer none): The #GIcon representing the @place.
 **/
GIcon *
geocode_place_get_icon (GeocodePlace *place)
{
        const char *icon_name;

        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        icon_name = get_icon_name (place);

        return g_icon_new_for_string (icon_name, NULL);
}

/**
 * geocode_place_get_bounding_box:
 * @place: A place
 *
 * Gets the bounding box for the place @place.
 *
 * Returns: (transfer none): A #GeocodeBoundingBox, or NULL if boundaries are
 * unknown.
 **/
GeocodeBoundingBox *
geocode_place_get_bounding_box (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->bbox;
}

/**
 * geocode_place_set_bounding_box:
 * @place: A place
 * @bbox: A #GeocodeBoundingBox for the place
 *
 * Sets the #GeocodeBoundingBox for the place @place.
 *
 **/
void
geocode_place_set_bounding_box (GeocodePlace       *place,
                                GeocodeBoundingBox *bbox)
{
        g_return_if_fail (GEOCODE_IS_PLACE (place));
        g_return_if_fail (GEOCODE_IS_BOUNDING_BOX (bbox));

        g_clear_object (&place->priv->bbox);
        place->priv->bbox = g_object_ref (bbox);
}

/**
 * geocode_place_get_osm_id:
 * @place: A place
 *
 * Gets the OpenStreetMap ID of the @place.
 *
 * Returns: The osm ID of the @place.
 **/
const char *
geocode_place_get_osm_id (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), NULL);

        return place->priv->osm_id;
}

/**
 * geocode_place_get_osm_type:
 * @place: A place
 *
 * Gets the OpenStreetMap type of the @place.
 *
 * Returns: The osm type of the @place.
 **/
GeocodePlaceOsmType
geocode_place_get_osm_type (GeocodePlace *place)
{
        g_return_val_if_fail (GEOCODE_IS_PLACE (place), GEOCODE_PLACE_OSM_TYPE_UNKNOWN);

        return place->priv->osm_type;
}
