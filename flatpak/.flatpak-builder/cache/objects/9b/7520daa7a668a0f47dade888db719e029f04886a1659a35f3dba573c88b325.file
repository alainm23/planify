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

#include <geocode-glib/geocode-bounding-box.h>

/**
 * SECTION:geocode-bounding-box
 * @short_description: Geocode BoundingBox object
 * @include: geocode-glib/geocode-bounding-box.h
 *
 * The #GeocodeBoundingBox represents a geographical area on earth, bounded
 * by top, bottom, left and right coordinates.
 **/

struct _GeocodeBoundingBoxPrivate {
        gdouble top;
        gdouble bottom;
        gdouble left;
        gdouble right;
};

enum {
        PROP_0,

        PROP_TOP,
        PROP_BOTTOM,
        PROP_LEFT,
        PROP_RIGHT
};

G_DEFINE_TYPE (GeocodeBoundingBox, geocode_bounding_box, G_TYPE_OBJECT)

static void
geocode_bounding_box_get_property (GObject    *object,
                                   guint       property_id,
                                   GValue     *value,
                                   GParamSpec *pspec)
{
        GeocodeBoundingBox *bbox = GEOCODE_BOUNDING_BOX (object);

        switch (property_id) {
        case PROP_TOP:
                g_value_set_double (value,
                                    geocode_bounding_box_get_top (bbox));
                break;

        case PROP_BOTTOM:
                g_value_set_double (value,
                                    geocode_bounding_box_get_bottom (bbox));
                break;

        case PROP_LEFT:
                g_value_set_double (value,
                                    geocode_bounding_box_get_left (bbox));
                break;

        case PROP_RIGHT:
                g_value_set_double (value,
                                    geocode_bounding_box_get_right (bbox));
                break;

        default:
                /* We don't have any other property... */
                G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
                break;
        }
}

static void
geocode_bounding_box_set_top (GeocodeBoundingBox *bbox,
                              gdouble             top)
{
        g_return_if_fail (top >= -90.0 && top <= 90.0);

        bbox->priv->top = top;
}

static void
geocode_bounding_box_set_bottom (GeocodeBoundingBox *bbox,
                                 gdouble             bottom)
{
        g_return_if_fail (bottom >= -90.0 && bottom <= 90.0);

        bbox->priv->bottom = bottom;
}

static void
geocode_bounding_box_set_left (GeocodeBoundingBox *bbox,
                               gdouble             left)
{
        g_return_if_fail (left >= -180.0 && left <= 180.0);

        bbox->priv->left = left;
}

static void
geocode_bounding_box_set_right (GeocodeBoundingBox *bbox,
                                gdouble             right)
{
        g_return_if_fail (right >= -180.0 && right <= 180.0);

        bbox->priv->right = right;
}

static void
geocode_bounding_box_set_property (GObject      *object,
                                   guint         property_id,
                                   const GValue *value,
                                   GParamSpec   *pspec)
{
        GeocodeBoundingBox *bbox = GEOCODE_BOUNDING_BOX (object);

        switch (property_id) {
        case PROP_TOP:
                geocode_bounding_box_set_top (bbox,
                                              g_value_get_double (value));
                break;

        case PROP_BOTTOM:
                geocode_bounding_box_set_bottom (bbox,
                                                 g_value_get_double (value));
                break;

        case PROP_LEFT:
                geocode_bounding_box_set_left (bbox,
                                               g_value_get_double (value));
                break;

        case PROP_RIGHT:
                geocode_bounding_box_set_right (bbox,
                                                g_value_get_double (value));
                break;

        default:
                /* We don't have any other property... */
                G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
                break;
        }
}

static void
geocode_bounding_box_finalize (GObject *gbbox)
{
        G_OBJECT_CLASS (geocode_bounding_box_parent_class)->finalize (gbbox);
}

static void
geocode_bounding_box_class_init (GeocodeBoundingBoxClass *klass)
{
        GObjectClass *gbbox_class = G_OBJECT_CLASS (klass);
        GParamSpec *pspec;

        gbbox_class->finalize = geocode_bounding_box_finalize;
        gbbox_class->get_property = geocode_bounding_box_get_property;
        gbbox_class->set_property = geocode_bounding_box_set_property;

        g_type_class_add_private (klass, sizeof (GeocodeBoundingBoxPrivate));

        /**
         * GeocodeBoundingBox:top:
         *
         * Top coordinate.
         */
        pspec = g_param_spec_double ("top",
                                     "Top",
                                     "Top coordinate",
                                     -90,
                                     90,
                                     0.0,
                                     G_PARAM_READWRITE |
                                     G_PARAM_CONSTRUCT_ONLY |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gbbox_class, PROP_TOP, pspec);

        /**
         * GeocodeBoundingBox:bottom:
         *
         * Bottom coordinate.
         */
        pspec = g_param_spec_double ("bottom",
                                     "Bottom",
                                     "Bottom coordinate",
                                     -90,
                                     90,
                                     0.0,
                                     G_PARAM_READWRITE |
                                     G_PARAM_CONSTRUCT_ONLY |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gbbox_class, PROP_BOTTOM, pspec);

        /**
         * GeocodeBoundingBox:left:
         *
         * Left coordinate.
         */
        pspec = g_param_spec_double ("left",
                                     "Left",
                                     "Left coordinate",
                                     -180,
                                     180,
                                     0.0,
                                     G_PARAM_READWRITE |
                                     G_PARAM_CONSTRUCT_ONLY |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gbbox_class, PROP_LEFT, pspec);

        /**
         * GeocodeBoundingBox:right:
         *
         * Right coordinate.
         */
        pspec = g_param_spec_double ("right",
                                     "Right",
                                     "Right coordinate",
                                     -180,
                                     180,
                                     0.0,
                                     G_PARAM_READWRITE |
                                     G_PARAM_CONSTRUCT_ONLY |
                                     G_PARAM_STATIC_STRINGS);
        g_object_class_install_property (gbbox_class, PROP_RIGHT, pspec);

}

static void
geocode_bounding_box_init (GeocodeBoundingBox *bbox)
{
        bbox->priv = G_TYPE_INSTANCE_GET_PRIVATE ((bbox),
                                                  GEOCODE_TYPE_BOUNDING_BOX,
                                                  GeocodeBoundingBoxPrivate);
}

/**
 * geocode_bounding_box_new:
 * @top: The left coordinate
 * @bottom: The bottom coordinate
 * @left: The left coordinate
 * @right: The right coordinate
 *
 * Creates a new #GeocodeBoundingBox object.
 *
 * Returns: a new #GeocodeBoundingBox object. Use g_object_unref() when done.
 **/
GeocodeBoundingBox *
geocode_bounding_box_new (gdouble top,
                          gdouble bottom,
                          gdouble left,
                          gdouble right)
{
        return g_object_new (GEOCODE_TYPE_BOUNDING_BOX,
                             "top", top,
                             "bottom", bottom,
                             "left", left,
                             "right", right,
                             NULL);
}

/**
 * geocode_bounding_box_equal:
 * @a: a bounding box
 * @b: another bounding box
 *
 * Compare two #GeocodeBoundingBox instances for equality. This compares all
 * fields and only returns %TRUE if the instances are exactly equal.
 *
 * Both instances must be non-%NULL.
 *
 * Returns: %TRUE if the instances are equal, %FALSE otherwise
 * Since: 3.23.1
 */
gboolean
geocode_bounding_box_equal (GeocodeBoundingBox *a,
                            GeocodeBoundingBox *b)
{
        g_return_val_if_fail (GEOCODE_IS_BOUNDING_BOX (a), FALSE);
        g_return_val_if_fail (GEOCODE_IS_BOUNDING_BOX (b), FALSE);

        return (a->priv->top == b->priv->top &&
                a->priv->bottom == b->priv->bottom &&
                a->priv->left == b->priv->left &&
                a->priv->right == b->priv->right);
}

/**
 * geocode_bounding_box_get_top:
 * @bbox: a #GeocodeBoundingBox
 *
 * Gets the top coordinate of @bbox.
 *
 * Returns: the top coordinate of @bbox.
 **/
gdouble
geocode_bounding_box_get_top (GeocodeBoundingBox *bbox)
{
        g_return_val_if_fail (GEOCODE_IS_BOUNDING_BOX (bbox), 0.0);

        return bbox->priv->top;
}

/**
 * geocode_bounding_box_get_bottom:
 * @bbox: a #GeocodeBoundingBox
 *
 * Gets the bottom coordinate of @bbox.
 *
 * Returns: the bottom coordinate of @bbox.
 **/
gdouble
geocode_bounding_box_get_bottom (GeocodeBoundingBox *bbox)
{
        g_return_val_if_fail (GEOCODE_IS_BOUNDING_BOX (bbox), 0.0);

        return bbox->priv->bottom;
}

/**
 * geocode_bounding_box_get_left:
 * @bbox: a #GeocodeBoundingBox
 *
 * Gets the left coordinate of @bbox.
 *
 * Returns: the left coordinate of @bbox.
 **/
gdouble
geocode_bounding_box_get_left (GeocodeBoundingBox *bbox)
{
        g_return_val_if_fail (GEOCODE_IS_BOUNDING_BOX (bbox), 0.0);

        return bbox->priv->left;
}

/**
 * geocode_bounding_box_get_right:
 * @bbox: a #GeocodeBoundingBox
 *
 * Gets the right coordinate of @bbox.
 *
 * Returns: the right coordinate of @bbox.
 **/
gdouble
geocode_bounding_box_get_right (GeocodeBoundingBox *bbox)
{
        g_return_val_if_fail (GEOCODE_IS_BOUNDING_BOX (bbox), 0.0);

        return bbox->priv->right;
}
