/*
   Copyright 2013 Jonas Danielsson

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

   Authors: Jonas Danielsson <jonas@threetimestwo.org>

 */

#ifndef GEOCODE_BOUNDING_BOX_H
#define GEOCODE_BOUNDING_BOX_H

#include <glib-object.h>

G_BEGIN_DECLS

GType geocode_bounding_box_get_type (void) G_GNUC_CONST;

#define GEOCODE_TYPE_BOUNDING_BOX (geocode_bounding_box_get_type ())
#define GEOCODE_BOUNDING_BOX(obj)                  (G_TYPE_CHECK_INSTANCE_CAST ((obj), GEOCODE_TYPE_BOUNDING_BOX, GeocodeBoundingBox))
#define GEOCODE_IS_BOUNDING_BOX(obj)               (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GEOCODE_TYPE_BOUNDING_BOX))
#define GEOCODE_BOUNDING_BOX_CLASS(klass)          (G_TYPE_CHECK_CLASS_CAST ((klass), GEOCODE_TYPE_BOUNDING_BOX, GeocodeBoundingBoxClass))
#define GEOCODE_IS_BOUNDING_BOX_CLASS(klass)       (G_TYPE_CHECK_CLASS_TYPE ((klass), GEOCODE_TYPE_BOUNDING_BOX))
#define GEOCODE_BOUNDING_BOX_GET_CLASS(obj)        (G_TYPE_INSTANCE_GET_CLASS ((obj), GEOCODE_TYPE_BOUNDING_BOX, GeocodeBoundingBoxClass))


typedef struct _GeocodeBoundingBox        GeocodeBoundingBox;
typedef struct _GeocodeBoundingBoxClass   GeocodeBoundingBoxClass;
typedef struct _GeocodeBoundingBoxPrivate GeocodeBoundingBoxPrivate;

/**
 * GeocodeBoundingBox:
 *
 * All the fields in the #GeocodeLocation structure are private and should
 * never be accessed directly.
**/
struct _GeocodeBoundingBox {
    /* <private> */
    GObject parent_instance;
    GeocodeBoundingBoxPrivate *priv;
};

/**
 * GeocodeBoundingBoxClass:
 *
 * All the fields in the #GeocodeBoundingBoxClass structure are private and
 * should never be accessed directly.
**/
struct _GeocodeBoundingBoxClass {
        /* <private> */
        GObjectClass parent_class;
};

G_DEFINE_AUTOPTR_CLEANUP_FUNC (GeocodeBoundingBox, g_object_unref)

GeocodeBoundingBox *geocode_bounding_box_new  (gdouble top,
                                               gdouble bottom,
                                               gdouble left,
                                               gdouble right);

gboolean geocode_bounding_box_equal     (GeocodeBoundingBox *a,
                                         GeocodeBoundingBox *b);

gdouble geocode_bounding_box_get_top    (GeocodeBoundingBox *bbox);
gdouble geocode_bounding_box_get_bottom (GeocodeBoundingBox *bbox);
gdouble geocode_bounding_box_get_left   (GeocodeBoundingBox *bbox);
gdouble geocode_bounding_box_get_right  (GeocodeBoundingBox *bbox);

G_END_DECLS

#endif /* GEOCODE_BOUNDING_BOX_H */
