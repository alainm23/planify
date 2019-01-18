/*
 * Copyright (C) 2008 Pierre-Luc Beaudoin <pierre-luc@pierlux.com>
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

#ifndef CHAMPLAIN_PATH_LAYER_H
#define CHAMPLAIN_PATH_LAYER_H

#include <champlain/champlain-defines.h>
#include <champlain/champlain-layer.h>
#include <champlain/champlain-location.h>
#include <champlain/champlain-bounding-box.h>

#include <glib-object.h>
#include <clutter/clutter.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_PATH_LAYER champlain_path_layer_get_type ()

#define CHAMPLAIN_PATH_LAYER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_PATH_LAYER, ChamplainPathLayer))

#define CHAMPLAIN_PATH_LAYER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_PATH_LAYER, ChamplainPathLayerClass))

#define CHAMPLAIN_IS_PATH_LAYER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_PATH_LAYER))

#define CHAMPLAIN_IS_PATH_LAYER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_PATH_LAYER))

#define CHAMPLAIN_PATH_LAYER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_PATH_LAYER, ChamplainPathLayerClass))

typedef struct _ChamplainPathLayerPrivate ChamplainPathLayerPrivate;

typedef struct _ChamplainPathLayer ChamplainPathLayer;
typedef struct _ChamplainPathLayerClass ChamplainPathLayerClass;


/**
 * ChamplainPathLayer:
 *
 * The #ChamplainPathLayer structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.10
 */
struct _ChamplainPathLayer
{
  ChamplainLayer parent;

  ChamplainPathLayerPrivate *priv;
};

struct _ChamplainPathLayerClass
{
  ChamplainLayerClass parent_class;
};

GType champlain_path_layer_get_type (void);

ChamplainPathLayer *champlain_path_layer_new (void);

void champlain_path_layer_add_node (ChamplainPathLayer *layer,
    ChamplainLocation *location);
void champlain_path_layer_remove_node (ChamplainPathLayer *layer,
    ChamplainLocation *location);
void champlain_path_layer_remove_all (ChamplainPathLayer *layer);
void champlain_path_layer_insert_node (ChamplainPathLayer *layer,
    ChamplainLocation *location,
    guint position);
GList *champlain_path_layer_get_nodes (ChamplainPathLayer *layer);

ClutterColor *champlain_path_layer_get_fill_color (ChamplainPathLayer *layer);
void champlain_path_layer_set_fill_color (ChamplainPathLayer *layer,
    const ClutterColor *color);

ClutterColor *champlain_path_layer_get_stroke_color (ChamplainPathLayer *layer);
void champlain_path_layer_set_stroke_color (ChamplainPathLayer *layer,
    const ClutterColor *color);

gboolean champlain_path_layer_get_fill (ChamplainPathLayer *layer);
void champlain_path_layer_set_fill (ChamplainPathLayer *layer,
    gboolean value);

gboolean champlain_path_layer_get_stroke (ChamplainPathLayer *layer);
void champlain_path_layer_set_stroke (ChamplainPathLayer *layer,
    gboolean value);

gdouble champlain_path_layer_get_stroke_width (ChamplainPathLayer *layer);
void champlain_path_layer_set_stroke_width (ChamplainPathLayer *layer,
    gdouble value);

gboolean champlain_path_layer_get_visible (ChamplainPathLayer *layer);
void champlain_path_layer_set_visible (ChamplainPathLayer *layer,
    gboolean value);

gboolean champlain_path_layer_get_closed (ChamplainPathLayer *layer);
void champlain_path_layer_set_closed (ChamplainPathLayer *layer,
    gboolean value);

GList *champlain_path_layer_get_dash (ChamplainPathLayer *layer);
void champlain_path_layer_set_dash (ChamplainPathLayer *layer,
    GList *dash_pattern);

G_END_DECLS

#endif
