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

/**
 * SECTION:champlain-marker
 * @short_description: Base class of libchamplain markers
 *
 * Markers represent points of interest on a map. Markers need to be
 * placed on a layer (a #ChamplainMarkerLayer). Layers have to be added to a
 * #champlainview for the markers to show on the map.
 *
 * A marker is nothing more than a regular #clutteractor. You can draw on
 * it what ever you want.  Set the marker's position
 * on the map using #champlain_location_set_location. Don't forget to set the 
 * marker's pointer position using #clutter_actor_set_translation.
 *
 * This is a base class of all markers. libchamplain has a more evoluted
 * type of markers with text and image support. See #ChamplainLabel for more details.
 */

#include "config.h"

#include "champlain-marker.h"

#include "champlain.h"
#include "champlain-defines.h"
#include "champlain-marshal.h"
#include "champlain-private.h"
#include "champlain-tile.h"

#include <clutter/clutter.h>
#include <glib.h>
#include <glib-object.h>
#include <cairo.h>
#include <math.h>

static ClutterColor SELECTED_COLOR = { 0x00, 0x33, 0xcc, 0xff };
static ClutterColor SELECTED_TEXT_COLOR = { 0xff, 0xff, 0xff, 0xff };

enum
{
  /* normal signals */
  BUTTON_PRESS_SIGNAL,
  BUTTON_RELEASE_SIGNAL,
  DRAG_MOTION_SIGNAL,
  DRAG_FINISH_SIGNAL,
  LAST_SIGNAL,
};

static guint signals[LAST_SIGNAL] = { 0, };

enum
{
  PROP_0,
  PROP_LONGITUDE,
  PROP_LATITUDE,
  PROP_SELECTED,
  PROP_SELECTABLE,
  PROP_DRAGGABLE,
};

/* static guint champlain_marker_signals[LAST_SIGNAL] = { 0, }; */

static void set_location (ChamplainLocation *location,
    gdouble latitude,
    gdouble longitude);
static gdouble get_latitude (ChamplainLocation *location);
static gdouble get_longitude (ChamplainLocation *location);

static void location_interface_init (ChamplainLocationIface *iface);

G_DEFINE_TYPE_WITH_CODE (ChamplainMarker, champlain_marker, CLUTTER_TYPE_ACTOR,
    G_IMPLEMENT_INTERFACE (CHAMPLAIN_TYPE_LOCATION, location_interface_init));

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), CHAMPLAIN_TYPE_MARKER, ChamplainMarkerPrivate))

struct _ChamplainMarkerPrivate
{
  gdouble lon;
  gdouble lat;
  gboolean selected;
  gboolean selectable;
  gboolean draggable;

  gfloat click_x;
  gfloat click_y;
  gboolean moved;
};


/**
 * champlain_marker_set_selection_color:
 * @color: a #ClutterColor
 *
 * Changes the selection color, this is to ensure a better integration with
 * the desktop, this is automatically done by GtkChamplainEmbed.
 *
 * Since: 0.10
 */
void
champlain_marker_set_selection_color (ClutterColor *color)
{
  SELECTED_COLOR.red = color->red;
  SELECTED_COLOR.green = color->green;
  SELECTED_COLOR.blue = color->blue;
  SELECTED_COLOR.alpha = color->alpha;
}


/**
 * champlain_marker_get_selection_color:
 *
 * Gets the selection color.
 *
 * Returns: the selection color. Should not be freed.
 *
 * Since: 0.10
 */
const ClutterColor *
champlain_marker_get_selection_color ()
{
  return &SELECTED_COLOR;
}


/**
 * champlain_marker_set_selection_text_color:
 * @color: a #ClutterColor
 *
 * Changes the selection text color, this is to ensure a better integration with
 * the desktop, this is automatically done by GtkChamplainEmbed.
 *
 * Since: 0.10
 */
void
champlain_marker_set_selection_text_color (ClutterColor *color)
{
  SELECTED_TEXT_COLOR.red = color->red;
  SELECTED_TEXT_COLOR.green = color->green;
  SELECTED_TEXT_COLOR.blue = color->blue;
  SELECTED_TEXT_COLOR.alpha = color->alpha;
}


/**
 * champlain_marker_get_selection_text_color:
 *
 * Gets the selection text color.
 *
 * Returns: the selection text color. Should not be freed.
 *
 * Since: 0.10
 */
const ClutterColor *
champlain_marker_get_selection_text_color ()
{
  return &SELECTED_TEXT_COLOR;
}


static void
champlain_marker_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  ChamplainMarker *marker = CHAMPLAIN_MARKER (object);
  ChamplainMarkerPrivate *priv = marker->priv;

  switch (prop_id)
    {
    case PROP_LONGITUDE:
      g_value_set_double (value, priv->lon);
      break;

    case PROP_LATITUDE:
      g_value_set_double (value, priv->lat);
      break;

    case PROP_SELECTED:
      g_value_set_boolean (value, priv->selected);
      break;

    case PROP_SELECTABLE:
      g_value_set_boolean (value, priv->selectable);
      break;

    case PROP_DRAGGABLE:
      g_value_set_boolean (value, priv->draggable);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
champlain_marker_set_property (GObject *object,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec)
{
  ChamplainMarker *marker = CHAMPLAIN_MARKER (object);
  ChamplainMarkerPrivate *priv = marker->priv;

  switch (prop_id)
    {
    case PROP_LONGITUDE:
      {
        gdouble lon = g_value_get_double (value);
        set_location (CHAMPLAIN_LOCATION (marker), priv->lat, lon);
        break;
      }

    case PROP_LATITUDE:
      {
        gdouble lat = g_value_get_double (value);
        set_location (CHAMPLAIN_LOCATION (marker), lat, priv->lon);
        break;
      }

    case PROP_SELECTED:
      {
        gboolean bvalue = g_value_get_boolean (value);
        champlain_marker_set_selected (marker, bvalue);
        break;
      }

    case PROP_SELECTABLE:
      {
        gboolean bvalue = g_value_get_boolean (value);
        champlain_marker_set_selectable (marker, bvalue);
        break;
      }

    case PROP_DRAGGABLE:
      {
        gboolean bvalue = g_value_get_boolean (value);
        champlain_marker_set_draggable (marker, bvalue);
        break;
      }

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
set_location (ChamplainLocation *location,
    gdouble latitude,
    gdouble longitude)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER (location));

  ChamplainMarkerPrivate *priv = CHAMPLAIN_MARKER (location)->priv;
  
  priv->lon = CLAMP (longitude, CHAMPLAIN_MIN_LONGITUDE, CHAMPLAIN_MAX_LONGITUDE);
  priv->lat = CLAMP (latitude, CHAMPLAIN_MIN_LATITUDE, CHAMPLAIN_MAX_LATITUDE);

  g_object_notify (G_OBJECT (location), "latitude");
  g_object_notify (G_OBJECT (location), "longitude");
}


static gdouble
get_latitude (ChamplainLocation *location)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MARKER (location), 0.0);

  ChamplainMarkerPrivate *priv = CHAMPLAIN_MARKER (location)->priv;

  return priv->lat;
}


static gdouble
get_longitude (ChamplainLocation *location)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MARKER (location), 0.0);

  ChamplainMarkerPrivate *priv = CHAMPLAIN_MARKER (location)->priv;

  return priv->lon;
}


static void
location_interface_init (ChamplainLocationIface *iface)
{
  iface->get_latitude = get_latitude;
  iface->get_longitude = get_longitude;
  iface->set_location = set_location;
}


static void
champlain_marker_dispose (GObject *object)
{
  G_OBJECT_CLASS (champlain_marker_parent_class)->dispose (object);
}


static void
champlain_marker_finalize (GObject *object)
{
  G_OBJECT_CLASS (champlain_marker_parent_class)->finalize (object);
}


static void
champlain_marker_class_init (ChamplainMarkerClass *marker_class)
{
  g_type_class_add_private (marker_class, sizeof (ChamplainMarkerPrivate));

  GObjectClass *object_class = G_OBJECT_CLASS (marker_class);
  object_class->finalize = champlain_marker_finalize;
  object_class->dispose = champlain_marker_dispose;
  object_class->get_property = champlain_marker_get_property;
  object_class->set_property = champlain_marker_set_property;

  /**
   * ChamplainMarker:selected:
   *
   * The selected state of the marker
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_SELECTED,
      g_param_spec_boolean ("selected", 
          "Selected",
          "The sighlighted state of the marker",
          FALSE, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainMarker:selectable:
   *
   * The selectable state of the marker
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_SELECTABLE,
      g_param_spec_boolean ("selectable", 
          "Selectable",
          "The draggable state of the marker",
          FALSE, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainMarker:draggable:
   *
   * The draggable state of the marker
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_DRAGGABLE,
      g_param_spec_boolean ("draggable", 
          "Draggable",
          "The draggable state of the marker",
          FALSE, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainMarker::button-press:
   * @self: a #ChamplainMarker
   * @event: the underlying ClutterEvent
   *
   * Emitted when button is pressed.
   *
   * Since: 0.10
   */
  signals[BUTTON_PRESS_SIGNAL] =
    g_signal_new ("button-press", 
        G_OBJECT_CLASS_TYPE (object_class),
        G_SIGNAL_RUN_LAST, 
        0, NULL, NULL,
        g_cclosure_marshal_VOID__BOXED, 
        G_TYPE_NONE, 
        1, 
        CLUTTER_TYPE_EVENT | G_SIGNAL_TYPE_STATIC_SCOPE);

  /**
   * ChamplainMarker::button-release:
   * @self: a #ChamplainMarker
   * @event: the underlying ClutterEvent
   *
   * Emitted when button is released. This signal is not emmitted at the end of dragging.
   *
   * Since: 0.10
   */
  signals[BUTTON_RELEASE_SIGNAL] =
    g_signal_new ("button-release", 
        G_OBJECT_CLASS_TYPE (object_class),
        G_SIGNAL_RUN_LAST, 
        0, NULL, NULL,
        g_cclosure_marshal_VOID__BOXED, 
        G_TYPE_NONE, 
        1, 
        CLUTTER_TYPE_EVENT | G_SIGNAL_TYPE_STATIC_SCOPE);

  /**
   * ChamplainMarker::drag-motion:
   * @self: a #ChamplainMarker
   * @dx: by how much the marker has been moved in the x direction
   * @dy: by how much the marker has been moved in the y direction
   * @event: the underlying ClutterEvent
   *
   * Emmitted when the marker is dragged by mouse. dx and dy specify by how much
   * the marker has been dragged since last time.
   *
   * Since: 0.10
   */
  signals[DRAG_MOTION_SIGNAL] =
    g_signal_new ("drag-motion", 
        G_OBJECT_CLASS_TYPE (object_class),
        G_SIGNAL_RUN_LAST, 
        0, NULL, NULL,
        _champlain_marshal_VOID__DOUBLE_DOUBLE_BOXED, 
        G_TYPE_NONE, 
        3, 
        G_TYPE_DOUBLE, G_TYPE_DOUBLE, CLUTTER_TYPE_EVENT | G_SIGNAL_TYPE_STATIC_SCOPE);

  /**
   * ChamplainMarker::drag-finish:
   * @self: a #ChamplainMarker
   * @event: the underlying ClutterEvent
   *
   * Emitted when marker dragging ends (i.e. the button is released at the end
   * of dragging).
   *
   * Since: 0.10
   */
  signals[DRAG_FINISH_SIGNAL] =
    g_signal_new ("drag-finish", 
        G_OBJECT_CLASS_TYPE (object_class),
        G_SIGNAL_RUN_LAST, 
        0, NULL, NULL,
        g_cclosure_marshal_VOID__BOXED, 
        G_TYPE_NONE, 
        1, 
        CLUTTER_TYPE_EVENT | G_SIGNAL_TYPE_STATIC_SCOPE);


  g_object_class_override_property (object_class,
      PROP_LONGITUDE,
      "longitude");

  g_object_class_override_property (object_class,
      PROP_LATITUDE,
      "latitude");
}


/**
 * champlain_marker_new:
 *
 * Creates an instance of #ChamplainMarker.
 *
 * Returns: a new #ChamplainMarker.
 *
 * Since: 0.12.4
 */
ClutterActor *
champlain_marker_new (void)
{
  return CLUTTER_ACTOR (g_object_new (CHAMPLAIN_TYPE_MARKER, NULL));
}


static gboolean
motion_event_cb (ClutterActor *stage,
    ClutterMotionEvent *event,
    ChamplainMarker *marker)
{
  ChamplainMarkerPrivate *priv = marker->priv;
  gfloat x, y;

  if (event->type != CLUTTER_MOTION)
    return FALSE;

  if (clutter_actor_transform_stage_point (CLUTTER_ACTOR (marker),
          event->x,
          event->y,
          &x, &y))
    {
      g_signal_emit_by_name (marker, "drag-motion", 
          x - priv->click_x, y - priv->click_y, event);
      priv->moved = TRUE;
    }

  return TRUE;
}


static gboolean
capture_release_event_cb (ClutterActor *stage,
    ClutterButtonEvent *event,
    ChamplainMarker *marker)
{
  ChamplainMarkerPrivate *priv = marker->priv;

  if ((event->type != CLUTTER_BUTTON_RELEASE) ||
      (event->button != 1))
    return FALSE;

  g_signal_handlers_disconnect_by_func (stage,
      motion_event_cb,
      marker);
  g_signal_handlers_disconnect_by_func (stage,
      capture_release_event_cb,
      marker);

  if (priv->moved)
    g_signal_emit_by_name (marker, "drag-finish", event);
  else
    g_signal_emit_by_name (marker, "button-release", event);

  return TRUE;
}


static gboolean
button_release_event_cb (ClutterActor *actor,
    ClutterButtonEvent *event,
    ChamplainMarker *marker)
{
  if ((event->type != CLUTTER_BUTTON_RELEASE) ||
      (event->button != 1))
    return FALSE;

  g_signal_handlers_disconnect_by_func (marker,
      button_release_event_cb,
      marker);

  g_signal_emit_by_name (marker, "button-release", event);

  return TRUE;
}


static gboolean
button_press_event_cb (ClutterActor *actor,
    ClutterEvent *event,
    ChamplainMarker *marker)
{
  ChamplainMarkerPrivate *priv = marker->priv;
  ClutterButtonEvent *bevent = (ClutterButtonEvent *) event;
  ClutterActor *stage = clutter_actor_get_stage (actor);

  if (event->type != CLUTTER_BUTTON_PRESS ||
      bevent->button != 1 ||
      !stage)
    {
      return FALSE;
    }

  if (priv->draggable)
    {
      if (clutter_actor_transform_stage_point (actor, bevent->x, bevent->y,
              &priv->click_x, &priv->click_y))
        {
          priv->moved = FALSE;
          g_signal_connect (stage,
              "captured-event",
              G_CALLBACK (motion_event_cb),
              marker);

          g_signal_connect (stage,
              "captured-event",
              G_CALLBACK (capture_release_event_cb),
              marker);
        }
    }
  else
    {
      g_signal_connect (marker,
          "button-release-event",
          G_CALLBACK (button_release_event_cb),
          marker);
    }

  if (priv->selectable)
    champlain_marker_set_selected (marker, TRUE);

  if (priv->selectable || priv->draggable)
    {
      ClutterActor *parent;
      
      parent = clutter_actor_get_parent (CLUTTER_ACTOR (marker));
      clutter_actor_set_child_above_sibling (parent, CLUTTER_ACTOR (marker), NULL);
    }

  g_signal_emit_by_name (marker, "button-press", event);

  return TRUE;
}


static void
champlain_marker_init (ChamplainMarker *marker)
{
  ChamplainMarkerPrivate *priv = GET_PRIVATE (marker);

  marker->priv = priv;

  priv->lat = 0;
  priv->lon = 0;
  priv->selected = FALSE;
  priv->selectable = TRUE;
  priv->draggable = FALSE;

  clutter_actor_set_reactive (CLUTTER_ACTOR (marker), TRUE);

  g_signal_connect (marker,
      "button-press-event",
      G_CALLBACK (button_press_event_cb),
      marker);
}


/**
 * champlain_marker_set_selected:
 * @marker: a #ChamplainMarker
 * @value: the selected state
 *
 * Sets the marker as selected or not. This will affect the "Selected" look
 * of the marker.
 *
 * Since: 0.10
 */
void
champlain_marker_set_selected (ChamplainMarker *marker,
    gboolean value)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER (marker));

  marker->priv->selected = value;

  g_object_notify (G_OBJECT (marker), "selected");
}


/**
 * champlain_marker_get_selected:
 * @marker: a #ChamplainMarker
 *
 * Checks whether the marker is selected.
 *
 * Returns: the selected or not state of the marker.
 *
 * Since: 0.10
 */
gboolean
champlain_marker_get_selected (ChamplainMarker *marker)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MARKER (marker), FALSE);

  return marker->priv->selected;
}


/**
 * champlain_marker_set_selectable:
 * @marker: a #ChamplainMarker
 * @value: the selectable state
 *
 * Sets the marker as selectable or not.
 *
 * Since: 0.10
 */
void
champlain_marker_set_selectable (ChamplainMarker *marker,
    gboolean value)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER (marker));

  marker->priv->selectable = value;

  g_object_notify (G_OBJECT (marker), "selectable");
}


/**
 * champlain_marker_get_selectable:
 * @marker: a #ChamplainMarker
 *
 * Checks whether the marker is selectable.
 *
 * Returns: the selectable or not state of the marker.
 *
 * Since: 0.10
 */
gboolean
champlain_marker_get_selectable (ChamplainMarker *marker)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MARKER (marker), FALSE);

  return marker->priv->selectable;
}


/**
 * champlain_marker_set_draggable:
 * @marker: a #ChamplainMarker
 * @value: the draggable state
 *
 * Sets the marker as draggable or not.
 *
 * Since: 0.10
 */
void
champlain_marker_set_draggable (ChamplainMarker *marker,
    gboolean value)
{
  g_return_if_fail (CHAMPLAIN_IS_MARKER (marker));

  marker->priv->draggable = value;

  g_object_notify (G_OBJECT (marker), "draggable");
}


/**
 * champlain_marker_get_draggable:
 * @marker: a #ChamplainMarker
 *
 * Checks whether the marker is draggable.
 *
 * Returns: the draggable or not state of the marker.
 *
 * Since: 0.10
 */
gboolean
champlain_marker_get_draggable (ChamplainMarker *marker)
{
  g_return_val_if_fail (CHAMPLAIN_IS_MARKER (marker), FALSE);

  return marker->priv->draggable;
}


/**
 * champlain_marker_animate_in:
 * @marker: a #ChamplainMarker
 *
 * Animates the marker as if it were falling from the sky onto the map.
 *
 * Since: 0.10
 */
void
champlain_marker_animate_in (ChamplainMarker *marker)
{
  champlain_marker_animate_in_with_delay (marker, 0);
}


/**
 * champlain_marker_animate_in_with_delay :
 * @marker: a #ChamplainMarker
 * @delay: The delay in milliseconds
 *
 * Animates the marker as if it were falling from the sky onto the map after
 * delay.
 *
 * Since: 0.10
 */
void
champlain_marker_animate_in_with_delay (ChamplainMarker *marker,
    guint delay)
{
  gfloat y;

  g_return_if_fail (CHAMPLAIN_IS_MARKER (marker));

  clutter_actor_show (CLUTTER_ACTOR (marker));
  clutter_actor_set_opacity (CLUTTER_ACTOR (marker), 0);
  clutter_actor_set_scale (CLUTTER_ACTOR (marker), 1.5, 1.5);
  clutter_actor_get_position (CLUTTER_ACTOR (marker), NULL, &y);
  clutter_actor_move_by (CLUTTER_ACTOR (marker), 0, -100);
      
  clutter_actor_save_easing_state (CLUTTER_ACTOR (marker));
  clutter_actor_set_easing_delay (CLUTTER_ACTOR (marker), delay);
  clutter_actor_set_easing_mode (CLUTTER_ACTOR (marker), CLUTTER_EASE_OUT_BOUNCE);
  clutter_actor_set_easing_duration (CLUTTER_ACTOR (marker), 1000);
  clutter_actor_set_opacity (CLUTTER_ACTOR (marker), 255);
  clutter_actor_set_scale (CLUTTER_ACTOR (marker), 1.0, 1.0);
  clutter_actor_set_y (CLUTTER_ACTOR (marker), y);
  clutter_actor_restore_easing_state (CLUTTER_ACTOR (marker));
}


/**
 * champlain_marker_animate_out:
 * @marker: a #ChamplainMarker
 *
 * Animates the marker as if it were drawn through the sky.
 *
 * Since: 0.10
 */
void
champlain_marker_animate_out (ChamplainMarker *marker)
{
  champlain_marker_animate_out_with_delay (marker, 0);
}


static void
on_transition_stopped (ClutterActor *marker,
    const gchar *transition_name,
    gboolean is_finished)
{
  clutter_actor_hide (marker);

  clutter_actor_move_by (marker, 0, 100);
  g_signal_handlers_disconnect_by_func (marker, on_transition_stopped, NULL);
}


/**
 * champlain_marker_animate_out_with_delay :
 * @marker: a #ChamplainMarker
 * @delay: The delay in milliseconds
 *
 * Animates the marker as if it were drawn through the sky after
 * delay.
 *
 * Since: 0.10
 */
void
champlain_marker_animate_out_with_delay (ChamplainMarker *marker,
    guint delay)
{
  gfloat y;

  g_return_if_fail (CHAMPLAIN_IS_MARKER (marker));

  clutter_actor_get_position (CLUTTER_ACTOR (marker), NULL, &y);
  clutter_actor_set_opacity (CLUTTER_ACTOR (marker), 200);

  clutter_actor_save_easing_state (CLUTTER_ACTOR (marker));
  clutter_actor_set_easing_delay (CLUTTER_ACTOR (marker), delay);
  clutter_actor_set_easing_mode (CLUTTER_ACTOR (marker), CLUTTER_EASE_IN_BACK);
  clutter_actor_set_easing_duration (CLUTTER_ACTOR (marker), 750);
  clutter_actor_set_opacity (CLUTTER_ACTOR (marker), 0);
  clutter_actor_set_scale (CLUTTER_ACTOR (marker), 2.0, 2.0);
  clutter_actor_set_y (CLUTTER_ACTOR (marker), y - 100);
  clutter_actor_restore_easing_state (CLUTTER_ACTOR (marker));
      
  g_signal_connect (CLUTTER_ACTOR (marker),
      "transition-stopped::opacity",
      G_CALLBACK (on_transition_stopped),
      NULL);      
}
