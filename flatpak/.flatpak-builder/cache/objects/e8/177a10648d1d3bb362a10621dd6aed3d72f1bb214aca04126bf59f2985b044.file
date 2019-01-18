/*
 * Copyright (C) 2009 Simon Wenner <simon@wenner.ch>
 *
 * This file is inspired by clutter-color.c which is
 * Copyright (C) 2006 OpenedHand, and has the same license.
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
 * SECTION:champlain-bounding-box
 * @short_description: A basic struct to describe a bounding box
 *
 * A basic struct to describe a bounding box.
 *
 */

#include "champlain-bounding-box.h"
#include "champlain-defines.h"

GType
champlain_bounding_box_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      type = g_boxed_type_register_static (
            g_intern_static_string ("ChamplainBoundingBox"),
            (GBoxedCopyFunc) champlain_bounding_box_copy,
            (GBoxedFreeFunc) champlain_bounding_box_free);
    }

  return type;
}


/**
 * champlain_bounding_box_new:
 *
 * Creates a newly allocated #ChamplainBoundingBox to be freed
 * with champlain_bounding_box_free().
 *
 * Returns: a #ChamplainBoundingBox
 *
 * Since: 0.6
 */
ChamplainBoundingBox *
champlain_bounding_box_new (void)
{
  ChamplainBoundingBox *bbox;

  bbox = g_slice_new (ChamplainBoundingBox);

  bbox->left = CHAMPLAIN_MAX_LONGITUDE;
  bbox->right = CHAMPLAIN_MIN_LONGITUDE;
  bbox->bottom = CHAMPLAIN_MAX_LATITUDE;
  bbox->top = CHAMPLAIN_MIN_LATITUDE;

  return bbox;
}


/**
 * champlain_bounding_box_copy:
 * @bbox: a #ChamplainBoundingBox
 *
 * Makes a copy of the bounding box structure. The result must be
 * freed using champlain_bounding_box_free().
 *
 * Returns: an allocated copy of @bbox.
 *
 * Since: 0.6
 */
ChamplainBoundingBox *
champlain_bounding_box_copy (const ChamplainBoundingBox *bbox)
{
  if (G_LIKELY (bbox != NULL))
    return g_slice_dup (ChamplainBoundingBox, bbox);

  return NULL;
}


/**
 * champlain_bounding_box_free:
 * @bbox: a #ChamplainBoundingBox
 *
 * Frees a bounding box structure created with champlain_bounding_box_new() or
 * champlain_bounding_box_copy().
 *
 * Since: 0.6
 */
void
champlain_bounding_box_free (ChamplainBoundingBox *bbox)
{
  if (G_UNLIKELY (bbox == NULL))
    return;

  g_slice_free (ChamplainBoundingBox, bbox);
}


/**
 * champlain_bounding_box_get_center:
 * @bbox: a #ChamplainBoundingBox
 * @latitude: (out): the latitude of the box center
 * @longitude: (out): the longitude of the box center
 *
 * Gets the center's latitude and longitude of the box to @latitude and @longitude.
 *
 * Since: 0.6
 */
void
champlain_bounding_box_get_center (ChamplainBoundingBox *bbox,
    gdouble *latitude,
    gdouble *longitude)
{
  g_return_if_fail (CHAMPLAIN_BOUNDING_BOX (bbox));

  *longitude = (bbox->right + bbox->left) / 2.0;
  *latitude = (bbox->top + bbox->bottom) / 2.0;
}


/**
 * champlain_bounding_box_compose:
 * @bbox: a #ChamplainBoundingBox
 * @other: a #ChamplainBoundingBox
 *
 * Sets bbox equal to the bounding box containing both @bbox and @other.
 *
 * Since: 0.10
 */
void
champlain_bounding_box_compose (ChamplainBoundingBox *bbox,
    ChamplainBoundingBox *other)
{
  g_return_if_fail (CHAMPLAIN_BOUNDING_BOX (bbox));

  if (other->left < bbox->left)
    bbox->left = other->left;

  if (other->right > bbox->right)
    bbox->right = other->right;

  if (other->top > bbox->top)
    bbox->top = other->top;

  if (other->bottom < bbox->bottom)
    bbox->bottom = other->bottom;
}


/**
 * champlain_bounding_box_extend:
 * @bbox: a #ChamplainBoundingBox
 * @latitude: the latitude of the point
 * @longitude: the longitude of the point
 *
 * Extend the bounding box so it contains a point with @latitude and @longitude.
 * Do nothing if the point is already inside the bounding box.
 *
 * Since: 0.10
 */
void
champlain_bounding_box_extend (ChamplainBoundingBox *bbox,
    gdouble latitude, gdouble longitude)
{
  g_return_if_fail (CHAMPLAIN_BOUNDING_BOX (bbox));

  if (longitude < bbox->left)
    bbox->left = longitude;

  if (latitude < bbox->bottom)
    bbox->bottom = latitude;

  if (longitude > bbox->right)
    bbox->right = longitude;

  if (latitude > bbox->top)
    bbox->top = latitude;
}


/**
 * champlain_bounding_box_is_valid:
 * @bbox: a #ChamplainBoundingBox
 *
 * Checks whether @bbox represents a valid bounding box on the map.
 *
 * Returns: TRUE when the bounding box is valid, FALSE otherwise.
 *
 * Since: 0.10
 */
gboolean
champlain_bounding_box_is_valid (ChamplainBoundingBox *bbox)
{
  g_return_val_if_fail (CHAMPLAIN_BOUNDING_BOX (bbox), FALSE);

  return (bbox->left < bbox->right) && (bbox->bottom < bbox->top) &&
         (bbox->left >= CHAMPLAIN_MIN_LONGITUDE) && (bbox->left <= CHAMPLAIN_MAX_LONGITUDE) &&
         (bbox->right >= CHAMPLAIN_MIN_LONGITUDE) && (bbox->right <= CHAMPLAIN_MAX_LONGITUDE) &&
         (bbox->bottom >= CHAMPLAIN_MIN_LATITUDE) && (bbox->bottom <= CHAMPLAIN_MAX_LATITUDE) &&
         (bbox->top >= CHAMPLAIN_MIN_LATITUDE) && (bbox->top <= CHAMPLAIN_MAX_LATITUDE);
}

/**
 * champlain_bounding_box_covers:
 * @bbox: a #ChamplainBoundingBox
 * @latitude: the latitude of the point
 * @longitude: the longitude of the point
 *
 * Checks whether @bbox covers the given coordinates.
 *
 * Returns: TRUE when the bounding box covers given coordinates, FALSE otherwise.
 *
 * Since: 0.12.4
 */
gboolean
champlain_bounding_box_covers(ChamplainBoundingBox *bbox,
    gdouble latitude,
    gdouble longitude)
{
  g_return_val_if_fail (CHAMPLAIN_BOUNDING_BOX (bbox), FALSE);

  return ((latitude >= bbox->bottom && latitude <= bbox->top) &&
          (longitude >= bbox->left && longitude <= bbox->right));
}
