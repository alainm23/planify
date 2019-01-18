/*
 * Copyright (C) 2011-2013 Jiri Techet <techet@gmail.com>
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

#ifndef CHAMPLAIN_POINT_H
#define CHAMPLAIN_POINT_H

#include <champlain/champlain-marker.h>

#include <glib-object.h>
#include <clutter/clutter.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_POINT champlain_point_get_type ()

#define CHAMPLAIN_POINT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_POINT, ChamplainPoint))

#define CHAMPLAIN_POINT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_POINT, ChamplainPointClass))

#define CHAMPLAIN_IS_POINT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_POINT))

#define CHAMPLAIN_IS_POINT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_POINT))

#define CHAMPLAIN_POINT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_POINT, ChamplainPointClass))

typedef struct _ChamplainPointPrivate ChamplainPointPrivate;

typedef struct _ChamplainPoint ChamplainPoint;
typedef struct _ChamplainPointClass ChamplainPointClass;

/**
 * ChamplainPoint:
 *
 * The #ChamplainPoint structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.10
 */
struct _ChamplainPoint
{
  ChamplainMarker parent;

  ChamplainPointPrivate *priv;
};

struct _ChamplainPointClass
{
  ChamplainMarkerClass parent_class;
};

GType champlain_point_get_type (void);

ClutterActor *champlain_point_new (void);

ClutterActor *champlain_point_new_full (gdouble size,
    const ClutterColor *color);

void champlain_point_set_color (ChamplainPoint *point,
    const ClutterColor *color);
ClutterColor *champlain_point_get_color (ChamplainPoint *point);

void champlain_point_set_size (ChamplainPoint *point,
    gdouble size);
gdouble champlain_point_get_size (ChamplainPoint *point);


G_END_DECLS

#endif
