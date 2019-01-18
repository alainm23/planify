/*
 * Copyright 2013, 2014 Jonas Danielsson
 *
 * The Gnome Library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * The Gnome Library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with the Gnome Library; see the file COPYING.LIB.  If not,
 * write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301  USA.
 *
 * Authors: Jonas Danielsson <jonas.danielsson@threetimestwo.org>
 */

#include <glib/gi18n.h>
#include <glib.h>
#include <stdlib.h>
#include <gio/gio.h>
#include <geocode-glib/geocode-glib.h>
#include <geocode-glib/geocode-glib-private.h>

struct uri {
    const char *uri;
    gboolean valid;
};

static struct uri uris[] = {
    { "geo:13.37,42.42", TRUE },
    { "geo:13.37373737,42.42424242", TRUE },
    { "geo:13.37,42.42,12.12", TRUE },
    { "geo:1,2,3", TRUE },
    { "geo:-13.37,42.42", TRUE },
    { "geo:13.37,-42.42", TRUE },
    { "geo:13.37,42.42;u=-45.5", TRUE },
    { "geo:13.37,42.42;u=45.5", TRUE },
    { "geo:13.37,42.42,12.12;u=45.5", TRUE },
    { "geo:13.37,42.42,12.12;crs=wgs84;u=45.5", TRUE },
    { "geo:0.0,0,0", TRUE },
    { "geo :0.0,0,0", FALSE },
    { "geo:0.0 ,0,0", FALSE },
    { "geo:0.0,0 ,0", FALSE },
    { "geo: 0.0,0,0", FALSE },
    { "geo:13.37,42.42,12.12;crs=newcrs;u=45.5", FALSE },
    { "geo:13.37,42.42,12.12;u=45.5;crs=hej", FALSE },
    { "geo:13.37,42.42,12.12;u=45.5;u=22", FALSE },
    { "geo:13.37,42.42,12.12;u=alpha", FALSE },
    { "gel:13.37,42.42,12.12", FALSE },
    { "geo:13.37alpha,42.42", FALSE },
    { "geo:13.37,alpha42.42", FALSE },
    { "geo:13.37,42.42,12.alpha", FALSE },
    { "geo:,13.37,42.42", FALSE },
    { "geo:0,0?q=13.36,4242(description)", TRUE },
    { "geo:0,0?q=-13.36,4242(description)", TRUE },
    { "geo:0,0?q=13.36,-4242(description)", TRUE },
    { "geo:1,2?q=13.36,4242(description)", FALSE },
    { "geo:0,0?q=13.36,4242(description", FALSE },
    { "geo:0,0?q=13.36,4242()", FALSE }
};

static void
test_parse_uri (void)
{
        GeocodeLocation *loc;
        GError *error = NULL;
        const char *uri = "geo:1.2,2.3,4.5;crs=wgs84;u=67";

        loc = geocode_location_new (0, 0, 0);

        g_assert (geocode_location_set_from_uri (loc, uri, &error));
        g_assert (error == NULL);

        g_assert_cmpfloat (geocode_location_get_latitude (loc),
                           ==,
                           1.2);

        g_assert_cmpfloat (geocode_location_get_longitude (loc),
                           ==,
                           2.3);

        g_assert_cmpfloat (geocode_location_get_altitude (loc),
                           ==,
                           4.5);

        g_assert_cmpfloat (geocode_location_get_accuracy (loc),
                           ==,
                           67);

        g_object_unref (loc);
}

static void
test_valid_uri (void)
{
        guint i;

        for (i = 0; i < G_N_ELEMENTS (uris); i++) {
                GeocodeLocation *loc;
                GError *error = NULL;
                gboolean success;

                loc = geocode_location_new (0, 0, 0);
                success = geocode_location_set_from_uri (loc, uris[i].uri, &error);
                if (uris[i].valid) {
                        g_assert (success);
                        g_assert (error == NULL);
                } else {
                        g_assert (!success);
                        g_assert (error != NULL);
                        g_error_free (error);
                }
                g_object_unref (loc);
        }
}

static void
test_unescape_uri (void)
{
        GeocodeLocation *loc;
        const char *uri = "geo:0,0?q=57.038,12.3982(Parkvägen%202,%20Tvååker)";

        loc = geocode_location_new (0, 0, 0);
        g_assert (geocode_location_set_from_uri (loc, uri, NULL));
        g_assert_cmpstr (geocode_location_get_description(loc),
                         ==,
                         "Parkvägen 2, Tvååker");
        g_object_unref (loc);
}

static void
test_convert_from_to_location (void)
{
        GeocodeLocation *loc;
        GError *error = NULL;
        gdouble latitude = 48.198634;
        gdouble longitude = 16.371648;
        gdouble altitude = 5;
        gdouble accuracy = 40;
        /* Karlskirche (from RFC) */
        const char *uri = "geo:48.198634,16.371648,5;crs=wgs84;u=40";
        g_autofree gchar *returned_uri = NULL;

        loc = geocode_location_new (0, 0, 0);
        g_assert (geocode_location_set_from_uri (loc, uri, &error));
        g_assert (error == NULL);

        g_assert_cmpfloat (geocode_location_get_latitude (loc),
                           ==,
                           latitude);
        g_assert_cmpfloat (geocode_location_get_longitude (loc),
                           ==,
                           longitude);
        g_assert_cmpfloat (geocode_location_get_altitude (loc),
                           ==,
                           altitude);
        g_assert_cmpfloat (geocode_location_get_accuracy (loc),
                           ==,
                           accuracy);

        returned_uri = geocode_location_to_uri (loc, GEOCODE_LOCATION_URI_SCHEME_GEO);
        g_object_unref (loc);
        loc = geocode_location_new (0, 0, 0);
        g_assert (geocode_location_set_from_uri (loc, returned_uri, &error));
        g_assert (error == NULL);

        g_assert_cmpfloat (geocode_location_get_latitude (loc),
                           ==,
                           latitude);
        g_assert_cmpfloat (geocode_location_get_longitude (loc),
                           ==,
                           longitude);
        g_assert_cmpfloat (geocode_location_get_altitude (loc),
                           ==,
                           altitude);
        g_assert_cmpfloat (geocode_location_get_accuracy (loc),
                           ==,
                           accuracy);
        g_object_unref (loc);
}

int main (int argc, char **argv)
{
        g_test_init (&argc, &argv, NULL);
        g_test_bug_base ("http://bugzilla.gnome.org/show_bug.cgi?id=");

        g_test_add_func ("/geouri/parse_uri", test_parse_uri);
        g_test_add_func ("/geouri/valid_uri", test_valid_uri);
        g_test_add_func ("/geouri/unescape_uri", test_unescape_uri);
        g_test_add_func ("/geouri/convert_uri", test_convert_from_to_location);

        return g_test_run ();
}
