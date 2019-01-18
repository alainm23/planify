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

#ifndef __CHAMPLAIN_LAYER_H__
#define __CHAMPLAIN_LAYER_H__

#include <clutter/clutter.h>
#include <champlain/champlain-defines.h>
#include <champlain/champlain-bounding-box.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_LAYER champlain_layer_get_type ()

#define CHAMPLAIN_LAYER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_LAYER, ChamplainLayer))

#define CHAMPLAIN_LAYER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_LAYER, ChamplainLayerClass))

#define CHAMPLAIN_IS_LAYER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_LAYER))

#define CHAMPLAIN_IS_LAYER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_LAYER))

#define CHAMPLAIN_LAYER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_LAYER, ChamplainLayerClass))

typedef struct _ChamplainLayer ChamplainLayer;
typedef struct _ChamplainLayerClass ChamplainLayerClass;

/**
 * ChamplainLayer:
 *
 * The #ChamplainLayer structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.10
 */
struct _ChamplainLayer
{
  ClutterActor parent;
};

struct _ChamplainLayerClass
{
  ClutterActorClass parent_class;

  void (*set_view)(ChamplainLayer *layer,
      ChamplainView *view);
  ChamplainBoundingBox * (*get_bounding_box)(ChamplainLayer * layer);
};

GType champlain_layer_get_type (void);


void champlain_layer_set_view (ChamplainLayer *layer,
    ChamplainView *view);

ChamplainBoundingBox *champlain_layer_get_bounding_box (ChamplainLayer *layer);

G_END_DECLS

#endif /* __CHAMPLAIN_LAYER_H__ */
