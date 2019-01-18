/*
 * Copyright (C) 2008-2009 Pierre-Luc Beaudoin <pierre-luc@pierlux.com>
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

/**
 * SECTION:champlain-marker-layer
 * @short_description: A container for #ChamplainMarker
 *
 * A ChamplainMarkerLayer displays markers on the map. It is responsible for
 * positioning markers correctly, marker selections and group marker operations.
 */

#include "config.h"

#include "champlain-marker-layer.h"

#include "champlain-defines.h"
#include "champlain-enum-types.h"
#include "champlain-private.h"
#include "champlain-view.h"

#include <clutter/clutter.h>
#include <glib.h>

static void exportable_interface_init (ChamplainExportableIface *iface);

G_DEFINE_TYPE_WITH_CODE (ChamplainMarkerLayer, champlain_marker_layer, CHAMPLAIN_TYPE_LAYER,
    G_IMPLEMENT_INTERFACE (CHAMPLAIN_TYPE_EXPORTABLE, exportable_interface_init));

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), CHAMPLAIN_TYPE_MARKER_LAYER, ChamplainMarkerLayerPrivate))

enum
{
  /* normal signals */
  LAST_SIGNAL
};

enum
{
  PROP_0,
  PROP_SELECTION_MODE,
  PROP_SURFACE,
};


struct _ChamplainMarkerLayerPrivate
{
  ChamplainSelectionMode mode;
  ChamplainView *view;
};

static void set_surface (ChamplainExportable *exportable,
    cairo_surface_t *surface);
static cairo_surface_t *get_surface (ChamplainExportable *exportable);

static void marker_selected_cb (ChamplainMarker *marker,
    G_GNUC_UNUSED GParamSpec *arg1,
    ChamplainMarkerLayer *layer);

static void set_view (ChamplainLayer *layer,
    ChamplainView *view);

static ChamplainBoundingBox *get_bounding_box (ChamplainLayer *layer);


static void
champlain_marker_layer_get_property (GObject *object,
    guint property_id,
    G_GNUC_UNUSED GValue *value,
    GParamSpec *pspec)
{
  ChamplainMarkerLayer *self = CHAMPLAIN_MARKER_LAYER (object);
  ChamplainMarkerLayerPrivate *priv = self->priv;

  switch (property_id)
    {
    case PROP_SELECTION_MODE:
      g_value_set_enum (value, priv->mode);
      break;

    case PROP_SURFACE:
      g_value_set_boxed (value, get_surface (CHAMPLAIN_EXPORTABLE (self)));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}


static void
champlain_marker_layer_set_property (GObject *object,
    guint property_id,
    G_GNUC_UNUSED const GValue *value,
    GParamSpec *pspec)
{
  ChamplainMarkerLayer *self = CHAMPLAIN_MARKER_LAYER (object);

  switch (property_id)
    {
    case PROP_SELECTION_MODE:
      champlain_marker_layer_set_selection_mode (self, g_value_get_enum (value));
      break;

    case PROP_SURFACE:
      set_surface (CHAMPLAIN_EXPORTABLE (object), g_value_get_boxed (value));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}


static void
champlain_marker_layer_dispose (GObject *object)
{
  ChamplainMarkerLayer *self = CHAMPLAIN_MARKER_LAYER (object);
  ChamplainMarkerLayerPrivate *priv = self->priv;

  if (priv->view != NULL)
    set_view (CHAMPLAIN_LAYER (self), NULL);

  G_OBJECT_CLASS (champlain_marker_layer_parent_class)->dispose (object);
}


static void
champlain_marker_layer_finalize (GObject *object)
{
  G_OBJECT_CLASS (champlain_marker_layer_parent_class)->finalize (object);
}


static void
champlain_marker_layer_class_init (ChamplainMarkerLayerClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  ChamplainLayerClass *layer_class = CHAMPLAIN_LAYER_CLASS (klass);

  g_type_class_add_private (klass, sizeof (ChamplainMarkerLayerPrivate));

  object_class->finalize = champlain_marker_layer_finalize;
  object_class->dispose = champlain_marker_layer_dispose;
  object_class->get_property = champlain_marker_layer_get_property;
  object_class->set_property = champlain_marker_layer_set_property;

  layer_class->set_view = set_view;
  layer_class->get_bounding_box = get_bounding_box;

  /**
   * ChamplainMarkerLayer:selection-mode:
   *
   * Determines the type of selection that will be performed.
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_SELECTION_MODE,
      g_param_spec_enum ("selection-mode",
          "Selection Mode",
          "Determines the type of selection that will be performed.",
          CHAMPLAIN_TYPE_SELECTION_MODE,
          CHAMPLAIN_SELECTION_NONE,
          CHAMPLAIN_PARAM_READWRITE));

    g_object_class_override_property (object_class,
      PROP_SURFACE,
      "surface");
}


static void
champlain_marker_layer_init (ChamplainMarkerLayer *self)
{
  ChamplainMarkerLayerPrivate *priv;

  self->priv = GET_PRIVATE (self);
  priv = self->priv;
  priv->mode = CHAMPLAIN_SELECTION_NONE;
  priv->view = NULL;
}


static void
set_surface (ChamplainExportable *exportable,
     cairo_surface_t *surface)
{
  /* no need */
}

static cairo_surface_t *
get_surface (ChamplainExportable *exportable)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MARKER_LAYER (exportable), NULL);

  ClutterActorIter iter;
  ClutterActor *child;
  ChamplainMarkerLayer *layer = CHAMPLAIN_MARKER_LAYER (exportable);
  ChamplainMarkerLayerPrivate *priv = layer->priv;
  cairo_surface_t *surface = NULL;
  cairo_t *cr;
  gboolean has_marker = FALSE;

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      ChamplainMarker *marker = CHAMPLAIN_MARKER (child);

      if (CHAMPLAIN_IS_EXPORTABLE (marker))
        {
          gfloat x, y, tx, ty;
          gint origin_x, origin_y;
          cairo_surface_t *marker_surface;
          ChamplainExportable *exportable;

          if (!has_marker)
            {
              gfloat width, height;

              width = 256;
              height = 256;
              if (priv->view != NULL)
                clutter_actor_get_size (CLUTTER_ACTOR (priv->view),&width, &height);
              surface = cairo_image_surface_create (CAIRO_FORMAT_ARGB32, width, height);
              has_marker = TRUE;
            }

          exportable = CHAMPLAIN_EXPORTABLE (marker);
          marker_surface = champlain_exportable_get_surface (exportable);

          champlain_view_get_viewport_origin (priv->view, &origin_x, &origin_y);
          clutter_actor_get_translation (CLUTTER_ACTOR (marker), &tx, &ty, NULL);
          clutter_actor_get_position (CLUTTER_ACTOR (marker), &x, &y);

          cr = cairo_create (surface);
          cairo_set_source_surface (cr, marker_surface,
                                    (x + tx) - origin_x,
                                    (y + ty) - origin_y);
          cairo_paint (cr);
          cairo_destroy (cr);
        }
    }

  return surface;
}

static void
exportable_interface_init (ChamplainExportableIface *iface)
{
  iface->get_surface = get_surface;
  iface->set_surface = set_surface;
}


/**
 * champlain_marker_layer_new:
 *
 * Creates a new instance of #ChamplainMarkerLayer.
 *
 * Returns: a new #ChamplainMarkerLayer ready to be used as a container for the markers.
 *
 * Since: 0.10
 */
ChamplainMarkerLayer *
champlain_marker_layer_new ()
{
  return g_object_new (CHAMPLAIN_TYPE_MARKER_LAYER, NULL);
}


/**
 * champlain_marker_layer_new_full:
 * @mode: Selection mode
 *
 * Creates a new instance of #ChamplainMarkerLayer with the specified selection mode.
 *
 * Returns: a new #ChamplainMarkerLayer ready to be used as a container for the markers.
 *
 * Since: 0.10
 */
ChamplainMarkerLayer *
champlain_marker_layer_new_full (ChamplainSelectionMode mode)
{
  return g_object_new (CHAMPLAIN_TYPE_MARKER_LAYER, "selection-mode", mode, NULL);
}


static void
set_selected_all_but_one (ChamplainMarkerLayer *layer,
    ChamplainMarker *not_selected,
    gboolean select)
{
  ClutterActorIter iter;
  ClutterActor *child;

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      ChamplainMarker *marker = CHAMPLAIN_MARKER (child);

      if (marker != not_selected)
        {
          g_signal_handlers_block_by_func (marker,
              G_CALLBACK (marker_selected_cb),
              layer);

          champlain_marker_set_selected (marker, select);
          champlain_marker_set_selectable (marker, layer->priv->mode != CHAMPLAIN_SELECTION_NONE);

          g_signal_handlers_unblock_by_func (marker,
              G_CALLBACK (marker_selected_cb),
              layer);
        }
    }
}


static void
marker_selected_cb (ChamplainMarker *marker,
    G_GNUC_UNUSED GParamSpec *arg1,
    ChamplainMarkerLayer *layer)
{
  if (layer->priv->mode == CHAMPLAIN_SELECTION_SINGLE && champlain_marker_get_selected (marker))
    set_selected_all_but_one (layer, marker, FALSE);
}


static void
set_marker_position (ChamplainMarkerLayer *layer, ChamplainMarker *marker)
{
  ChamplainMarkerLayerPrivate *priv = layer->priv;
  gint x, y, origin_x, origin_y;

  /* layer not yet added to the view */
  if (priv->view == NULL)
    return;

  champlain_view_get_viewport_origin (priv->view, &origin_x, &origin_y);
  x = champlain_view_longitude_to_x (priv->view,
        champlain_location_get_longitude (CHAMPLAIN_LOCATION (marker))) + origin_x;
  y = champlain_view_latitude_to_y (priv->view,
        champlain_location_get_latitude (CHAMPLAIN_LOCATION (marker))) + origin_y;

  clutter_actor_set_position (CLUTTER_ACTOR (marker), x, y);
}


static void
marker_position_notify (ChamplainMarker *marker,
    G_GNUC_UNUSED GParamSpec *pspec,
    ChamplainMarkerLayer *layer)
{
  set_marker_position (layer, marker);
}


static void
marker_move_by_cb (ChamplainMarker *marker,
    gdouble dx,
    gdouble dy,
    ClutterEvent *event,
    ChamplainMarkerLayer *layer)
{
  ChamplainMarkerLayerPrivate *priv = layer->priv;
  ChamplainView *view = priv->view;
  gdouble x, y, lat, lon;

  x = champlain_view_longitude_to_x (view, champlain_location_get_longitude (CHAMPLAIN_LOCATION (marker)));
  y = champlain_view_latitude_to_y (view, champlain_location_get_latitude (CHAMPLAIN_LOCATION (marker)));

  x += dx;
  y += dy;

  lon = champlain_view_x_to_longitude (view, x);
  lat = champlain_view_y_to_latitude (view, y);

  champlain_location_set_location (CHAMPLAIN_LOCATION (marker), lat, lon);
}


/**
 * champlain_marker_layer_add_marker:
 * @layer: a #ChamplainMarkerLayer
 * @marker: a #ChamplainMarker
 *
 * Adds the marker to the layer.
 *
 * Since: 0.10
 */
void
champlain_marker_layer_add_marker (ChamplainMarkerLayer *layer,
    ChamplainMarker *marker)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));
  g_return_if_fail (CHAMPLAIN_IS_MARKER (marker));

  champlain_marker_set_selectable (marker, layer->priv->mode != CHAMPLAIN_SELECTION_NONE);

  g_signal_connect (G_OBJECT (marker), "notify::selected",
      G_CALLBACK (marker_selected_cb), layer);

  g_signal_connect (G_OBJECT (marker), "notify::latitude",
      G_CALLBACK (marker_position_notify), layer);

  g_signal_connect (G_OBJECT (marker), "drag-motion",
      G_CALLBACK (marker_move_by_cb), layer);

  clutter_actor_add_child (CLUTTER_ACTOR (layer), CLUTTER_ACTOR (marker));
  set_marker_position (layer, marker);
}


/**
 * champlain_marker_layer_remove_all:
 * @layer: a #ChamplainMarkerLayer
 *
 * Removes all markers from the layer.
 *
 * Since: 0.10
 */
void
champlain_marker_layer_remove_all (ChamplainMarkerLayer *layer)
{
  ClutterActorIter iter;
  ClutterActor *child;

  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      GObject *marker = G_OBJECT (child);

      g_signal_handlers_disconnect_by_func (marker,
          G_CALLBACK (marker_selected_cb), layer);

      g_signal_handlers_disconnect_by_func (marker,
          G_CALLBACK (marker_position_notify), layer);

      g_signal_handlers_disconnect_by_func (marker,
          G_CALLBACK (marker_move_by_cb), layer);
          
      clutter_actor_iter_remove (&iter);
    }
}


/**
 * champlain_marker_layer_get_markers:
 * @layer: a #ChamplainMarkerLayer
 *
 * Gets a copy of the list of all markers inserted into the layer. You should
 * free the list but not its contents.
 *
 * Returns: (transfer container) (element-type ChamplainMarker): the list
 *
 * Since: 0.10
 */
GList *
champlain_marker_layer_get_markers (ChamplainMarkerLayer *layer)
{
  GList *lst;
  
  lst = clutter_actor_get_children (CLUTTER_ACTOR (layer));
  return g_list_reverse (lst);
}


/**
 * champlain_marker_layer_get_selected:
 * @layer: a #ChamplainMarkerLayer
 *
 * Gets a list of selected markers in the layer.
 *
 * Returns: (transfer container) (element-type ChamplainMarker): the list
 *
 * Since: 0.10
 */
GList *
champlain_marker_layer_get_selected (ChamplainMarkerLayer *layer)
{
  GList *selected = NULL;

  g_return_val_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer), NULL);

  ClutterActorIter iter;
  ClutterActor *child;

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      ChamplainMarker *marker = CHAMPLAIN_MARKER (child);

      if (champlain_marker_get_selected (marker))
        selected = g_list_prepend (selected, marker);
    }

  return selected;
}


/**
 * champlain_marker_layer_remove_marker:
 * @layer: a #ChamplainMarkerLayer
 * @marker: a #ChamplainMarker
 *
 * Removes the marker from the layer.
 *
 * Since: 0.10
 */
void
champlain_marker_layer_remove_marker (ChamplainMarkerLayer *layer,
    ChamplainMarker *marker)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));
  g_return_if_fail (CHAMPLAIN_IS_MARKER (marker));

  g_signal_handlers_disconnect_by_func (G_OBJECT (marker),
      G_CALLBACK (marker_selected_cb), layer);

  g_signal_handlers_disconnect_by_func (G_OBJECT (marker),
      G_CALLBACK (marker_position_notify), layer);

  g_signal_handlers_disconnect_by_func (marker,
      G_CALLBACK (marker_move_by_cb), layer);

  clutter_actor_remove_child (CLUTTER_ACTOR (layer), CLUTTER_ACTOR (marker));
}


/**
 * champlain_marker_layer_animate_in_all_markers:
 * @layer: a #ChamplainMarkerLayer
 *
 * Fade in all markers in the layer with an animation
 *
 * Since: 0.10
 */
void
champlain_marker_layer_animate_in_all_markers (ChamplainMarkerLayer *layer)
{
  ClutterActorIter iter;
  ClutterActor *child;
  guint delay = 0;

  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      ChamplainMarker *marker = CHAMPLAIN_MARKER (child);

      champlain_marker_animate_in_with_delay (marker, delay);
      delay += 50;
    }
}


/**
 * champlain_marker_layer_animate_out_all_markers:
 * @layer: a #ChamplainMarkerLayer
 *
 * Fade out all markers in the layer with an animation
 *
 * Since: 0.10
 */
void
champlain_marker_layer_animate_out_all_markers (ChamplainMarkerLayer *layer)
{
  ClutterActorIter iter;
  ClutterActor *child;
  guint delay = 0;

  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      ChamplainMarker *marker = CHAMPLAIN_MARKER (child);

      champlain_marker_animate_out_with_delay (marker, delay);
      delay += 50;
    }
}


/**
 * champlain_marker_layer_show_all_markers:
 * @layer: a #ChamplainMarkerLayer
 *
 * Shows all markers in the layer
 *
 * Since: 0.10
 */
void
champlain_marker_layer_show_all_markers (ChamplainMarkerLayer *layer)
{
  ClutterActorIter iter;
  ClutterActor *child;

  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      ClutterActor *actor = CLUTTER_ACTOR (child);

      clutter_actor_show (actor);
    }
}


/**
 * champlain_marker_layer_hide_all_markers:
 * @layer: a #ChamplainMarkerLayer
 *
 * Hides all the markers in the layer
 *
 * Since: 0.10
 */
void
champlain_marker_layer_hide_all_markers (ChamplainMarkerLayer *layer)
{
  ClutterActorIter iter;
  ClutterActor *child;

  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      ClutterActor *actor = CLUTTER_ACTOR (child);

      clutter_actor_hide (actor);
    }
}


/**
 * champlain_marker_layer_set_all_markers_draggable:
 * @layer: a #ChamplainMarkerLayer
 *
 * Sets all markers draggable in the layer
 *
 * Since: 0.10
 */
void
champlain_marker_layer_set_all_markers_draggable (ChamplainMarkerLayer *layer)
{
  ClutterActorIter iter;
  ClutterActor *child;

  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      ChamplainMarker *marker = CHAMPLAIN_MARKER (child);

      champlain_marker_set_draggable (marker, TRUE);
    }
}


/**
 * champlain_marker_layer_set_all_markers_undraggable:
 * @layer: a #ChamplainMarkerLayer
 *
 * Sets all markers undraggable in the layer
 *
 * Since: 0.10
 */
void
champlain_marker_layer_set_all_markers_undraggable (ChamplainMarkerLayer *layer)
{
  ClutterActorIter iter;
  ClutterActor *child;

  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      ChamplainMarker *marker = CHAMPLAIN_MARKER (child);

      champlain_marker_set_draggable (marker, FALSE);
    }
}


/**
 * champlain_marker_layer_unselect_all_markers:
 * @layer: a #ChamplainMarkerLayer
 *
 * Unselects all markers in the layer.
 *
 * Since: 0.10
 */
void
champlain_marker_layer_unselect_all_markers (ChamplainMarkerLayer *layer)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  set_selected_all_but_one (layer, NULL, FALSE);
}


/**
 * champlain_marker_layer_select_all_markers:
 * @layer: a #ChamplainMarkerLayer
 *
 * Selects all markers in the layer.
 *
 * Since: 0.10
 */
void
champlain_marker_layer_select_all_markers (ChamplainMarkerLayer *layer)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  set_selected_all_but_one (layer, NULL, TRUE);
}


/**
 * champlain_marker_layer_set_selection_mode:
 * @layer: a #ChamplainMarkerLayer
 * @mode: a #ChamplainSelectionMode value
 *
 * Sets the selection mode of the layer.
 *
 * NOTE: changing selection mode to CHAMPLAIN_SELECTION_NONE or
 * CHAMPLAIN_SELECTION_SINGLE will clear all previously selected markers.
 *
 * Since: 0.10
 */
void
champlain_marker_layer_set_selection_mode (ChamplainMarkerLayer *layer,
    ChamplainSelectionMode mode)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  if (layer->priv->mode == mode)
    return;
  layer->priv->mode = mode;

  if (mode != CHAMPLAIN_SELECTION_MULTIPLE)
    set_selected_all_but_one (layer, NULL, FALSE);

  g_object_notify (G_OBJECT (layer), "selection-mode");
}


/**
 * champlain_marker_layer_get_selection_mode:
 * @layer: a #ChamplainMarkerLayer
 *
 * Gets the selection mode of the layer.
 *
 * Returns: the selection mode of the layer.
 *
 * Since: 0.10
 */
ChamplainSelectionMode
champlain_marker_layer_get_selection_mode (ChamplainMarkerLayer *layer)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer), CHAMPLAIN_SELECTION_SINGLE);
  return layer->priv->mode;
}


static void
reposition (ChamplainMarkerLayer *layer)
{
  ClutterActorIter iter;
  ClutterActor *child;

  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      ChamplainMarker *marker = CHAMPLAIN_MARKER (child);

      set_marker_position (layer, marker);
    }
}


static void
relocate_cb (G_GNUC_UNUSED GObject *gobject,
    ChamplainMarkerLayer *layer)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  reposition (layer);
}


static void
zoom_reposition_cb (G_GNUC_UNUSED GObject *gobject,
    G_GNUC_UNUSED GParamSpec *arg1,
    ChamplainMarkerLayer *layer)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer));

  reposition (layer);
}


static void
set_view (ChamplainLayer *layer,
    ChamplainView *view)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer) && (CHAMPLAIN_IS_VIEW (view) || view == NULL));

  ChamplainMarkerLayer *marker_layer = CHAMPLAIN_MARKER_LAYER (layer);

  if (marker_layer->priv->view != NULL)
    {
      g_signal_handlers_disconnect_by_func (marker_layer->priv->view,
          G_CALLBACK (relocate_cb), marker_layer);
      g_object_unref (marker_layer->priv->view);
    }

  marker_layer->priv->view = view;

  if (view != NULL)
    {
      g_object_ref (view);

      g_signal_connect (view, "layer-relocated",
          G_CALLBACK (relocate_cb), layer);

      g_signal_connect (view, "notify::zoom-level",
          G_CALLBACK (zoom_reposition_cb), layer);

      reposition (marker_layer);
    }
}


static ChamplainBoundingBox *
get_bounding_box (ChamplainLayer *layer)
{
  ClutterActorIter iter;
  ClutterActor *child;
  ChamplainBoundingBox *bbox;

  g_return_val_if_fail (CHAMPLAIN_IS_MARKER_LAYER (layer), NULL);

  bbox = champlain_bounding_box_new ();

  clutter_actor_iter_init (&iter, CLUTTER_ACTOR (layer));
  while (clutter_actor_iter_next (&iter, &child))
    {
      ChamplainMarker *marker = CHAMPLAIN_MARKER (child);
      gdouble lat, lon;

      lat = champlain_location_get_latitude (CHAMPLAIN_LOCATION (marker));
      lon = champlain_location_get_longitude (CHAMPLAIN_LOCATION (marker));

      champlain_bounding_box_extend (bbox, lat, lon);
    }

  if (bbox->left == bbox->right)
    {
      bbox->left -= 0.0001;
      bbox->right += 0.0001;
    }

  if (bbox->bottom == bbox->top)
    {
      bbox->bottom -= 0.0001;
      bbox->top += 0.0001;
    }

  return bbox;
}
