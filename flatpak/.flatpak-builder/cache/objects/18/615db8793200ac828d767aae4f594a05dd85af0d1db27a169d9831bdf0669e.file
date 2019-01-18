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

#ifndef CHAMPLAIN_MARKER_LAYER_H
#define CHAMPLAIN_MARKER_LAYER_H

#include <champlain/champlain-defines.h>
#include <champlain/champlain-marker.h>
#include <champlain/champlain-layer.h>
#include <champlain/champlain-bounding-box.h>

#include <glib-object.h>
#include <clutter/clutter.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_MARKER_LAYER champlain_marker_layer_get_type ()

#define CHAMPLAIN_MARKER_LAYER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_MARKER_LAYER, ChamplainMarkerLayer))

#define CHAMPLAIN_MARKER_LAYER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_MARKER_LAYER, ChamplainMarkerLayerClass))

#define CHAMPLAIN_IS_MARKER_LAYER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_MARKER_LAYER))

#define CHAMPLAIN_IS_MARKER_LAYER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_MARKER_LAYER))

#define CHAMPLAIN_MARKER_LAYER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_MARKER_LAYER, ChamplainMarkerLayerClass))

typedef struct _ChamplainMarkerLayerPrivate ChamplainMarkerLayerPrivate;

typedef struct _ChamplainMarkerLayer ChamplainMarkerLayer;
typedef struct _ChamplainMarkerLayerClass ChamplainMarkerLayerClass;

/**
 * ChamplainSelectionMode:
 * @CHAMPLAIN_SELECTION_NONE: No marker can be selected.
 * @CHAMPLAIN_SELECTION_SINGLE: Only one marker can be selected.
 * @CHAMPLAIN_SELECTION_MULTIPLE: Multiple marker can be selected.
 *
 * Selection mode
 */
typedef enum
{
  CHAMPLAIN_SELECTION_NONE,
  CHAMPLAIN_SELECTION_SINGLE,
  CHAMPLAIN_SELECTION_MULTIPLE
} ChamplainSelectionMode;

/**
 * ChamplainMarkerLayer:
 *
 * The #ChamplainMarkerLayer structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.10
 */
struct _ChamplainMarkerLayer
{
  ChamplainLayer parent;

  ChamplainMarkerLayerPrivate *priv;
};

struct _ChamplainMarkerLayerClass
{
  ChamplainLayerClass parent_class;
};

GType champlain_marker_layer_get_type (void);

ChamplainMarkerLayer *champlain_marker_layer_new (void);
ChamplainMarkerLayer *champlain_marker_layer_new_full (ChamplainSelectionMode mode);

void champlain_marker_layer_add_marker (ChamplainMarkerLayer *layer,
    ChamplainMarker *marker);
void champlain_marker_layer_remove_marker (ChamplainMarkerLayer *layer,
    ChamplainMarker *marker);
void champlain_marker_layer_remove_all (ChamplainMarkerLayer *layer);
GList *champlain_marker_layer_get_markers (ChamplainMarkerLayer *layer);
GList *champlain_marker_layer_get_selected (ChamplainMarkerLayer *layer);

void champlain_marker_layer_animate_in_all_markers (ChamplainMarkerLayer *layer);
void champlain_marker_layer_animate_out_all_markers (ChamplainMarkerLayer *layer);

void champlain_marker_layer_show_all_markers (ChamplainMarkerLayer *layer);
void champlain_marker_layer_hide_all_markers (ChamplainMarkerLayer *layer);

void champlain_marker_layer_set_all_markers_draggable (ChamplainMarkerLayer *layer);
void champlain_marker_layer_set_all_markers_undraggable (ChamplainMarkerLayer *layer);

void champlain_marker_layer_select_all_markers (ChamplainMarkerLayer *layer);
void champlain_marker_layer_unselect_all_markers (ChamplainMarkerLayer *layer);

void champlain_marker_layer_set_selection_mode (ChamplainMarkerLayer *layer,
    ChamplainSelectionMode mode);
ChamplainSelectionMode champlain_marker_layer_get_selection_mode (ChamplainMarkerLayer *layer);

G_END_DECLS

#endif
