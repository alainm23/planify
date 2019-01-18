/*
 * Copyright 2016 Collabora Ltd.
 *
 * The geocode-glib library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * The geocode-glib library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with the Gnome Library; see the file COPYING.LIB.  If not,
 * write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301  USA.
 *
 * Authors: Aleksander Morgado <aleksander.morgado@collabora.co.uk>
 *          Philip Withnall <philip.withnall@collabora.co.uk>
 */

#ifndef GEOCODE_NOMINATIM_TEST_H
#define GEOCODE_NOMINATIM_TEST_H

#include <glib.h>
#include <gio/gio.h>

#include "geocode-glib/geocode-nominatim.h"

G_BEGIN_DECLS

#define GEOCODE_TYPE_NOMINATIM_TEST (geocode_nominatim_test_get_type ())
G_DECLARE_FINAL_TYPE (GeocodeNominatimTest, geocode_nominatim_test, GEOCODE, NOMINATIM_TEST, GeocodeNominatim)

GeocodeNominatim *geocode_nominatim_test_new          (void);

void              geocode_nominatim_test_expect_query (GeocodeNominatimTest *self,
                                                       GHashTable           *ht,
                                                       const char           *response);

G_END_DECLS

#endif /* GEOCODE_NOMINATIM_TEST_H */
