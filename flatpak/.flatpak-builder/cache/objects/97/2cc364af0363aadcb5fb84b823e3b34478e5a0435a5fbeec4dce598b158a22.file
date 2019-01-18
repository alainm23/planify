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

#ifndef CHAMPLAIN_SCALE_H
#define CHAMPLAIN_SCALE_H

#include <champlain/champlain-defines.h>

#include <glib-object.h>
#include <clutter/clutter.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_SCALE champlain_scale_get_type ()

#define CHAMPLAIN_SCALE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_SCALE, ChamplainScale))

#define CHAMPLAIN_SCALE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_SCALE, ChamplainScaleClass))

#define CHAMPLAIN_IS_SCALE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_SCALE))

#define CHAMPLAIN_IS_SCALE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_SCALE))

#define CHAMPLAIN_SCALE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_SCALE, ChamplainScaleClass))

typedef struct _ChamplainScalePrivate ChamplainScalePrivate;

typedef struct _ChamplainScale ChamplainScale;
typedef struct _ChamplainScaleClass ChamplainScaleClass;

/**
 * ChamplainUnit:
 * @CHAMPLAIN_UNIT_KM: kilometers
 * @CHAMPLAIN_UNIT_MILES: miles
 *
 * Units used by the scale.
 */
typedef enum
{
  CHAMPLAIN_UNIT_KM,
  CHAMPLAIN_UNIT_MILES,
} ChamplainUnit;

/**
 * ChamplainScale:
 *
 * The #ChamplainScale structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.10
 */
struct _ChamplainScale
{
  ClutterActor parent;

  ChamplainScalePrivate *priv;
};

struct _ChamplainScaleClass
{
  ClutterActorClass parent_class;
};

GType champlain_scale_get_type (void);

ClutterActor *champlain_scale_new (void);


void champlain_scale_set_max_width (ChamplainScale *scale,
    guint value);
void champlain_scale_set_unit (ChamplainScale *scale,
    ChamplainUnit unit);

guint champlain_scale_get_max_width (ChamplainScale *scale);
ChamplainUnit champlain_scale_get_unit (ChamplainScale *scale);

void champlain_scale_connect_view (ChamplainScale *scale,
    ChamplainView *view);
void champlain_scale_disconnect_view (ChamplainScale *scale);

G_END_DECLS

#endif
