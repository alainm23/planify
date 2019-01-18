/*
 * Copyright (C) 2009 Simon Wenner <simon@wenner.ch>
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

#if !defined (__CHAMPLAIN_CHAMPLAIN_H_INSIDE__) && !defined (CHAMPLAIN_COMPILATION)
#error "Only <champlain/champlain.h> can be included directly."
#endif

#ifndef CHAMPLAIN_BOUNDING_BOX_H
#define CHAMPLAIN_BOUNDING_BOX_H

#include <glib-object.h>

G_BEGIN_DECLS

typedef struct _ChamplainBoundingBox ChamplainBoundingBox;

#define CHAMPLAIN_BOUNDING_BOX(obj) ((ChamplainBoundingBox *) (obj))

/**
 * ChamplainBoundingBox:
 * @left: left coordinate
 * @top: top coordinate
 * @right: right coordinate
 * @bottom: bottom coordinate
 *
 * Defines the area of a ChamplainMapDataSource that contains data.
 *
 * Since: 0.6
 */
struct _ChamplainBoundingBox
{
  /*< public >*/
  gdouble left;
  gdouble top;
  gdouble right;
  gdouble bottom;
};

GType champlain_bounding_box_get_type (void) G_GNUC_CONST;
#define CHAMPLAIN_TYPE_BOUNDING_BOX (champlain_bounding_box_get_type ())

ChamplainBoundingBox *champlain_bounding_box_new (void);

ChamplainBoundingBox *champlain_bounding_box_copy (const ChamplainBoundingBox *bbox);

void champlain_bounding_box_free (ChamplainBoundingBox *bbox);

void champlain_bounding_box_get_center (ChamplainBoundingBox *bbox,
    gdouble *latitude,
    gdouble *longitude);

void champlain_bounding_box_compose (ChamplainBoundingBox *bbox,
    ChamplainBoundingBox *other);

void champlain_bounding_box_extend (ChamplainBoundingBox *bbox,
    gdouble latitude,
    gdouble longitude);

gboolean champlain_bounding_box_is_valid (ChamplainBoundingBox *bbox);

gboolean champlain_bounding_box_covers(ChamplainBoundingBox *bbox,
    gdouble latitude,
    gdouble longitude);

G_END_DECLS

#endif
