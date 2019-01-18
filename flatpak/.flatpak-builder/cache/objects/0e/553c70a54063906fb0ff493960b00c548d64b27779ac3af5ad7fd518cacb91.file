/* champlain-kinetic-scroll-view.c: Finger scrolling container actor
 *
 * Copyright (C) 2008 OpenedHand
 * Copyright (C) 2011-2013 Jiri Techet <techet@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Written by: Chris Lord <chris@openedhand.com>
 */

#include "champlain-kinetic-scroll-view.h"
#include "champlain-enum-types.h"
#include "champlain-marshal.h"
#include "champlain-adjustment.h"
#include "champlain-viewport.h"
#include <clutter/clutter.h>
#include <math.h>

G_DEFINE_TYPE (ChamplainKineticScrollView, champlain_kinetic_scroll_view, CLUTTER_TYPE_ACTOR)

#define GET_PRIVATE(o) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((o), CHAMPLAIN_TYPE_KINETIC_SCROLL_VIEW, ChamplainKineticScrollViewPrivate))

typedef struct
{
  /* Units to store the origin of a click when scrolling */
  gfloat x;
  gfloat y;
  GTimeVal time;
} ChamplainKineticScrollViewMotion;

struct _ChamplainKineticScrollViewPrivate
{
  /* Scroll mode */
  gboolean kinetic;

  GArray *motion_buffer;
  guint last_motion;

  /* Variables for storing acceleration information for kinetic mode */
  ClutterTimeline *deceleration_timeline;
  gdouble dx;
  gdouble dy;
  gdouble decel_rate;

  ClutterActor *viewport;
  ClutterEventSequence *sequence;
};

enum
{
  PROP_MODE = 1,
  PROP_DECEL_RATE,
  PROP_BUFFER,
};

enum
{
  /* normal signals */
  PANNING_COMPLETED,
  LAST_SIGNAL
};

static guint signals[LAST_SIGNAL] = { 0, };

static gboolean
button_release_event_cb (ClutterActor *stage,
    ClutterButtonEvent *event,
    ChamplainKineticScrollView *scroll);

static void
champlain_kinetic_scroll_view_get_property (GObject *object, guint property_id,
    GValue *value, GParamSpec *pspec)
{
  ChamplainKineticScrollViewPrivate *priv = CHAMPLAIN_KINETIC_SCROLL_VIEW (object)->priv;

  switch (property_id)
    {
    case PROP_MODE:
      g_value_set_boolean (value, priv->kinetic);
      break;

    case PROP_DECEL_RATE:
      g_value_set_double (value, priv->decel_rate);
      break;

    case PROP_BUFFER:
      g_value_set_uint (value, priv->motion_buffer->len);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}


static void
champlain_kinetic_scroll_view_set_property (GObject *object, guint property_id,
    const GValue *value, GParamSpec *pspec)
{
  ChamplainKineticScrollViewPrivate *priv = CHAMPLAIN_KINETIC_SCROLL_VIEW (object)->priv;

  switch (property_id)
    {
    case PROP_MODE:
      priv->kinetic = g_value_get_boolean (value);
      g_object_notify (object, "mode");
      break;

    case PROP_DECEL_RATE:
      priv->decel_rate = g_value_get_double (value);
      g_object_notify (object, "decel-rate");
      break;

    case PROP_BUFFER:
      g_array_set_size (priv->motion_buffer, g_value_get_uint (value));
      g_object_notify (object, "motion-buffer");
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}


static void
champlain_kinetic_scroll_view_dispose (GObject *object)
{
  ChamplainKineticScrollViewPrivate *priv = CHAMPLAIN_KINETIC_SCROLL_VIEW (object)->priv;

  if (priv->viewport)
    {
      clutter_actor_remove_all_children (CLUTTER_ACTOR (object));
      priv->viewport = NULL;
    }

  if (priv->deceleration_timeline)
    {
      clutter_timeline_stop (priv->deceleration_timeline);
      g_object_unref (priv->deceleration_timeline);
      priv->deceleration_timeline = NULL;
    }

  G_OBJECT_CLASS (champlain_kinetic_scroll_view_parent_class)->dispose (object);
}


static void
champlain_kinetic_scroll_view_finalize (GObject *object)
{
  ChamplainKineticScrollViewPrivate *priv = CHAMPLAIN_KINETIC_SCROLL_VIEW (object)->priv;

  g_array_free (priv->motion_buffer, TRUE);

  G_OBJECT_CLASS (champlain_kinetic_scroll_view_parent_class)->finalize (object);
}


static void
champlain_kinetic_scroll_view_class_init (ChamplainKineticScrollViewClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (ChamplainKineticScrollViewPrivate));

  object_class->get_property = champlain_kinetic_scroll_view_get_property;
  object_class->set_property = champlain_kinetic_scroll_view_set_property;
  object_class->dispose = champlain_kinetic_scroll_view_dispose;
  object_class->finalize = champlain_kinetic_scroll_view_finalize;

  g_object_class_install_property (object_class,
      PROP_MODE,
      g_param_spec_boolean ("mode",
          "ChamplainKineticScrollViewMode",
          "Scrolling mode",
          FALSE,
          G_PARAM_READWRITE));

  g_object_class_install_property (object_class,
      PROP_DECEL_RATE,
      g_param_spec_double ("decel-rate",
          "Deceleration rate",
          "Rate at which the view "
          "will decelerate in "
          "kinetic mode.",
          G_MINDOUBLE + 1,
          G_MAXDOUBLE,
          1.1,
          G_PARAM_READWRITE));

  g_object_class_install_property (object_class,
      PROP_BUFFER,
      g_param_spec_uint ("motion-buffer",
          "Motion buffer",
          "Amount of motion "
          "events to buffer",
          1, G_MAXUINT, 3,
          G_PARAM_READWRITE));

  signals[PANNING_COMPLETED] =
    g_signal_new ("panning-completed", 
        G_OBJECT_CLASS_TYPE (object_class),
        G_SIGNAL_RUN_LAST, 
        0, NULL, NULL,
        g_cclosure_marshal_VOID__VOID, G_TYPE_NONE, 0);
}


static void
clamp_adjustments (ChamplainKineticScrollView *scroll)
{
  ChamplainKineticScrollViewPrivate *priv = scroll->priv;

  if (priv->viewport)
    {
      ChamplainAdjustment *hadj, *vadj;
      gdouble d, value, lower, step_increment;

      champlain_viewport_get_adjustments (CHAMPLAIN_VIEWPORT (priv->viewport),
          &hadj, &vadj);

      /* Snap to the nearest step increment on hadjustment */

      champlain_adjustment_get_values (hadj, &value, &lower, NULL,
          &step_increment);
      d = (rint ((value - lower) / step_increment) *
           step_increment) + lower;
      champlain_adjustment_set_value (hadj, d);

      /* Snap to the nearest step increment on vadjustment */
      champlain_adjustment_get_values (vadj, &value, &lower, NULL,
          &step_increment);
      d = (rint ((value - lower) / step_increment) *
           step_increment) + lower;
      champlain_adjustment_set_value (vadj, d);
    }
}


static gboolean
motion_event_cb (ClutterActor *stage,
    ClutterMotionEvent *event,
    ChamplainKineticScrollView *scroll)
{
  ChamplainKineticScrollViewPrivate *priv = scroll->priv;
  ClutterActor *actor = CLUTTER_ACTOR (scroll);
  gfloat x, y;

  if ((event->type != CLUTTER_MOTION || !(event->modifier_state & CLUTTER_BUTTON1_MASK)) &&
      (event->type != CLUTTER_TOUCH_UPDATE || priv->sequence != clutter_event_get_event_sequence ((ClutterEvent *) event)))
    return FALSE;

  if (clutter_actor_transform_stage_point (actor,
          event->x,
          event->y,
          &x, &y))
    {
      ChamplainKineticScrollViewMotion *motion;

      if (priv->viewport)
        {
          gdouble dx, dy;
          ChamplainAdjustment *hadjust, *vadjust;

          champlain_viewport_get_adjustments (CHAMPLAIN_VIEWPORT (priv->viewport),
              &hadjust,
              &vadjust);

          motion = &g_array_index (priv->motion_buffer,
                ChamplainKineticScrollViewMotion, priv->last_motion);
          if (hadjust)
            {
              dx = (motion->x - x) +
                champlain_adjustment_get_value (hadjust);
              champlain_adjustment_set_value (hadjust, dx);
            }

          if (vadjust)
            {
              dy = (motion->y - y) +
                champlain_adjustment_get_value (vadjust);
              champlain_adjustment_set_value (vadjust, dy);
            }
        }

      priv->last_motion++;
      if (priv->last_motion == priv->motion_buffer->len)
        {
          priv->motion_buffer = g_array_remove_index (priv->motion_buffer, 0);
          g_array_set_size (priv->motion_buffer, priv->last_motion);
          priv->last_motion--;
        }

      motion = &g_array_index (priv->motion_buffer,
            ChamplainKineticScrollViewMotion, priv->last_motion);
      motion->x = x;
      motion->y = y;
      g_get_current_time (&motion->time);
    }

  /* Due to the way gestures in progress connect to the stage in order to
   * receive events, we must let these events go through, as they could be
   * essential for the management of the ClutterZoomGesture in the
   * ChamplainView.
   */
  return FALSE;
}


static void
deceleration_completed_cb (ClutterTimeline *timeline,
    ChamplainKineticScrollView *scroll)
{
  clamp_adjustments (scroll);
  g_object_unref (timeline);
  scroll->priv->deceleration_timeline = NULL;

  g_signal_emit_by_name (scroll, "panning-completed", NULL);
}


static void
deceleration_new_frame_cb (ClutterTimeline *timeline,
    gint frame_num,
    ChamplainKineticScrollView *scroll)
{
  ChamplainKineticScrollViewPrivate *priv = scroll->priv;

  if (priv->viewport)
    {
      gdouble value, lower, upper;
      ChamplainAdjustment *hadjust, *vadjust;
      gint i;
      gboolean stop = TRUE;

      champlain_viewport_get_adjustments (CHAMPLAIN_VIEWPORT (priv->viewport),
          &hadjust,
          &vadjust);

      for (i = 0; i < clutter_timeline_get_delta (timeline) / 15; i++)
        {
          champlain_adjustment_set_value (hadjust,
              priv->dx +
              champlain_adjustment_get_value (hadjust));
          champlain_adjustment_set_value (vadjust,
              priv->dy +
              champlain_adjustment_get_value (vadjust));
          priv->dx = (priv->dx / priv->decel_rate);
          priv->dy = (priv->dy / priv->decel_rate);
        }

      /* Check if we've hit the upper or lower bounds and stop the timeline */
      champlain_adjustment_get_values (hadjust, &value, &lower, &upper,
          NULL);
      if (((priv->dx > 0) && (value < upper)) ||
          ((priv->dx < 0) && (value > lower)))
        stop = FALSE;

      if (stop)
        {
          champlain_adjustment_get_values (vadjust, &value, &lower, &upper,
              NULL);
          if (((priv->dy > 0) && (value < upper)) ||
              ((priv->dy < 0) && (value > lower)))
            stop = FALSE;
        }

      if (stop)
        {
          clutter_timeline_stop (timeline);
          deceleration_completed_cb (timeline, scroll);
        }
    }
}


static gboolean
button_release_event_cb (ClutterActor *stage,
    ClutterButtonEvent *event,
    ChamplainKineticScrollView *scroll)
{
  ChamplainKineticScrollViewPrivate *priv = scroll->priv;
  ClutterActor *actor = CLUTTER_ACTOR (scroll);
  gboolean decelerating = FALSE;

  if ((event->type != CLUTTER_MOTION || event->modifier_state & CLUTTER_BUTTON1_MASK) &&
      (event->type != CLUTTER_BUTTON_RELEASE || event->button != 1) && 
      (event->type != CLUTTER_TOUCH_END || priv->sequence != clutter_event_get_event_sequence ((ClutterEvent *) event)))
    return FALSE;

  g_signal_handlers_disconnect_by_func (stage,
      motion_event_cb,
      scroll);
  g_signal_handlers_disconnect_by_func (stage,
      button_release_event_cb,
      scroll);

  if (priv->kinetic && priv->viewport)
    {
      gfloat x, y;

      if (clutter_actor_transform_stage_point (actor,
              event->x,
              event->y,
              &x, &y))
        {
          double frac, x_origin, y_origin;
          GTimeVal release_time, motion_time;
          ChamplainAdjustment *hadjust, *vadjust;
          glong time_diff;
          gint i;

          /* Get time delta */
          g_get_current_time (&release_time);

          /* Get average position/time of last x mouse events */
          priv->last_motion++;
          x_origin = y_origin = 0;
          motion_time = (GTimeVal){ 0, 0 };
          for (i = 0; i < priv->last_motion; i++)
            {
              ChamplainKineticScrollViewMotion *motion =
                &g_array_index (priv->motion_buffer, ChamplainKineticScrollViewMotion, i);

              /* FIXME: This doesn't guard against overflows - Should
               *        either fix that, or calculate the correct maximum
               *        value for the buffer size
               */

              x_origin += motion->x;
              y_origin += motion->y;
              motion_time.tv_sec += motion->time.tv_sec;
              motion_time.tv_usec += motion->time.tv_usec;
            }
          x_origin /= priv->last_motion;
          y_origin /= priv->last_motion;
          motion_time.tv_sec /= priv->last_motion;
          motion_time.tv_usec /= priv->last_motion;

          if (motion_time.tv_sec == release_time.tv_sec)
            time_diff = release_time.tv_usec - motion_time.tv_usec;
          else
            time_diff = release_time.tv_usec +
              (G_USEC_PER_SEC - motion_time.tv_usec);

          /* On a macbook that's running Ubuntu 9.04 sometimes 'time_diff' is 0
             and this causes a division by 0 when computing 'frac'. This check
             avoids this error.
           */
          if (time_diff != 0)
            {
              /* Work out the fraction of 1/60th of a second that has elapsed */
              frac = (time_diff / 1000.0) / (1000.0 / 60.0);

              /* See how many units to move in 1/60th of a second */
              priv->dx = (x_origin - x) / frac;
              priv->dy = (y_origin - y) / frac;

              /* Get adjustments to do step-increment snapping */
              champlain_viewport_get_adjustments (CHAMPLAIN_VIEWPORT (priv->viewport),
                  &hadjust,
                  &vadjust);

              if (ABS (priv->dx) > 1 ||
                  ABS (priv->dy) > 1)
                {
                  gdouble value, lower, step_increment, d, a, x, y, n;

                  /* TODO: Convert this all to fixed point? */

                  /* We want n, where x / y    n < z,
                   * x = Distance to move per frame
                   * y = Deceleration rate
                   * z = maximum distance from target
                   *
                   * Rearrange to n = log (x / z) / log (y)
                   * To simplify, z = 1, so n = log (x) / log (y)
                   *
                   * As z = 1, this will cause stops to be slightly abrupt -
                   * add a constant 15 frames to compensate.
                   */
                  x = MAX (ABS (priv->dx), ABS (priv->dy));
                  y = priv->decel_rate;
                  n = logf (x) / logf (y) + 15.0;

                  /* Now we have n, adjust dx/dy so that we finish on a step
                   * boundary.
                   *
                   * Distance moved, using the above variable names:
                   *
                   * d = x + x/y + x/y    2 + ... + x/y    n
                   *
                   * Using geometric series,
                   *
                   * d = (1 - 1/y    (n+1))/(1 - 1/y)*x
                   *
                   * Let a = (1 - 1/y    (n+1))/(1 - 1/y),
                   *
                   * d = a * x
                   *
                   * Find d and find its nearest page boundary, then solve for x
                   *
                   * x = d / a
                   */

                  /* Get adjustments, work out y    n */
                  a = (1.0 - 1.0 / pow (y, n + 1)) / (1.0 - 1.0 / y);

                  /* Solving for dx */
                  d = a * priv->dx;
                  champlain_adjustment_get_values (hadjust, &value, &lower, NULL,
                      &step_increment);
                  d = ((rint (((value + d) - lower) / step_increment) *
                        step_increment) + lower) - value;
                  priv->dx = (d / a);

                  /* Solving for dy */
                  d = a * (priv->dy);
                  champlain_adjustment_get_values (vadjust, &value, &lower, NULL,
                      &step_increment);
                  d = ((rint (((value + d) - lower) / step_increment) *
                        step_increment) + lower) - value;
                  priv->dy = (d / a);

                  priv->deceleration_timeline = clutter_timeline_new ((n / 60) * 1000.0);
                }
              else
                {
                  gdouble value, lower, step_increment, d, a, y;

                  /* Start a short effects timeline to snap to the nearest step
                   * boundary (see equations above)
                   */
                  y = priv->decel_rate;
                  a = (1.0 - 1.0 / pow (y, 4 + 1)) / (1.0 - 1.0 / y);

                  champlain_adjustment_get_values (hadjust, &value, &lower, NULL,
                      &step_increment);
                  d = ((rint ((value - lower) / step_increment) *
                        step_increment) + lower) - value;
                  priv->dx = (d / a);

                  champlain_adjustment_get_values (vadjust, &value, &lower, NULL,
                      &step_increment);
                  d = ((rint ((value - lower) / step_increment) *
                        step_increment) + lower) - value;
                  priv->dy = (d / a);

                  priv->deceleration_timeline = clutter_timeline_new (250);
                }

              g_signal_connect (priv->deceleration_timeline, "new_frame",
                  G_CALLBACK (deceleration_new_frame_cb), scroll);
              g_signal_connect (priv->deceleration_timeline, "completed",
                  G_CALLBACK (deceleration_completed_cb), scroll);
              clutter_timeline_start (priv->deceleration_timeline);
              decelerating = TRUE;
            }
        }
    }

  priv->sequence = NULL;

  /* Reset motion event buffer */
  priv->last_motion = 0;

  if (!decelerating)
    {
      clamp_adjustments (scroll);
      g_signal_emit_by_name (scroll, "panning-completed", NULL);
    }

  /* Due to the way gestures in progress connect to the stage in order to
   * receive events, we must let these events go through, as they could be
   * essential for the management of the ClutterZoomGesture in the
   * ChamplainView.
   */
  return FALSE;
}


static gboolean
button_press_event_cb (ClutterActor *actor,
    ClutterEvent *event,
    ChamplainKineticScrollView *scroll)
{
  ChamplainKineticScrollViewPrivate *priv = scroll->priv;
  ClutterButtonEvent *bevent = (ClutterButtonEvent *) event;
  ClutterActor *stage = clutter_actor_get_stage (actor);

  if (event->type == CLUTTER_TOUCH_BEGIN && priv->sequence)
    {
      /* On multi touch input, shy away and cancel everything */
      priv->sequence = NULL;

      g_signal_handlers_disconnect_by_func (stage,
          motion_event_cb,
          scroll);
      g_signal_handlers_disconnect_by_func (stage,
          button_release_event_cb,
          scroll);

      champlain_kinetic_scroll_view_stop (scroll);
      clamp_adjustments (scroll);
      g_signal_emit_by_name (scroll, "panning-completed", NULL);

      return FALSE;
    }

  if ((((event->type == CLUTTER_BUTTON_PRESS) && (bevent->button == 1)) ||
      (event->type == CLUTTER_TOUCH_BEGIN && !priv->sequence)) &&
      stage)
    {
      ChamplainKineticScrollViewMotion *motion;

      /* Reset motion buffer */
      priv->last_motion = 0;
      motion = &g_array_index (priv->motion_buffer, ChamplainKineticScrollViewMotion, 0);

      if (clutter_actor_transform_stage_point (actor, bevent->x, bevent->y,
              &motion->x, &motion->y))
        {
          g_get_current_time (&motion->time);

          if (priv->deceleration_timeline)
            {
              clutter_timeline_stop (priv->deceleration_timeline);
              g_object_unref (priv->deceleration_timeline);
              priv->deceleration_timeline = NULL;
            }

          priv->sequence = clutter_event_get_event_sequence (event);

          g_signal_connect (stage,
              "captured-event",
              G_CALLBACK (motion_event_cb),
              scroll);
          g_signal_connect (stage,
              "captured-event",
              G_CALLBACK (button_release_event_cb),
              scroll);
        }
    }

  return FALSE;
}


static void
champlain_kinetic_scroll_view_init (ChamplainKineticScrollView *self)
{
  ChamplainKineticScrollViewPrivate *priv = self->priv = GET_PRIVATE (self);

  priv->motion_buffer = g_array_sized_new (FALSE, TRUE,
        sizeof (ChamplainKineticScrollViewMotion), 3);
  g_array_set_size (priv->motion_buffer, 3);
  priv->decel_rate = 1.1f;
  priv->viewport = NULL;
  priv->sequence = NULL;

  clutter_actor_set_reactive (CLUTTER_ACTOR (self), TRUE);
  g_signal_connect (self, "button-press-event",
      G_CALLBACK (button_press_event_cb), self);
  g_signal_connect (self, "touch-event",
      G_CALLBACK (button_press_event_cb), self);
}


ClutterActor *
champlain_kinetic_scroll_view_new (gboolean kinetic,
    ChamplainViewport *viewport)
{
  ClutterActor *scroll_view;
  
  scroll_view = CLUTTER_ACTOR (g_object_new (CHAMPLAIN_TYPE_KINETIC_SCROLL_VIEW,
          "mode", kinetic, NULL));
  CHAMPLAIN_KINETIC_SCROLL_VIEW (scroll_view)->priv->viewport = CLUTTER_ACTOR (viewport);
  clutter_actor_add_child (scroll_view, CLUTTER_ACTOR (viewport));

  return scroll_view;
}


void
champlain_kinetic_scroll_view_stop (ChamplainKineticScrollView *scroll)
{
  ChamplainKineticScrollViewPrivate *priv;

  g_return_if_fail (CHAMPLAIN_IS_KINETIC_SCROLL_VIEW (scroll));

  priv = scroll->priv;

  if (priv->deceleration_timeline)
    {
      clutter_timeline_stop (priv->deceleration_timeline);
      g_object_unref (priv->deceleration_timeline);
      priv->deceleration_timeline = NULL;
    }
}
