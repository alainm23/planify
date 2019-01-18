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

/**
 * SECTION:champlain-scale
 * @short_description: An actor displaying a scale.
 *
 * An actor displaying a scale.
 */

#include "config.h"

#include "champlain-scale.h"
#include "champlain-defines.h"
#include "champlain-marshal.h"
#include "champlain-private.h"
#include "champlain-enum-types.h"
#include "champlain-view.h"

#include <clutter/clutter.h>
#include <glib.h>
#include <glib-object.h>
#include <cairo.h>
#include <math.h>
#include <string.h>


enum
{
  /* normal signals */
  LAST_SIGNAL
};

enum
{
  PROP_0,
  PROP_SCALE_UNIT,
  PROP_MAX_SCALE_WIDTH,
};

/* static guint champlain_scale_signals[LAST_SIGNAL] = { 0, }; */

struct _ChamplainScalePrivate
{
  ChamplainUnit scale_unit;
  guint max_scale_width;
  gfloat text_height;
  ClutterContent *canvas;

  ChamplainView *view;
  gboolean redraw_scheduled;
};

G_DEFINE_TYPE (ChamplainScale, champlain_scale, CLUTTER_TYPE_ACTOR);

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), CHAMPLAIN_TYPE_SCALE, ChamplainScalePrivate))


#define SCALE_HEIGHT  5
#define GAP_SIZE 2
#define SCALE_INSIDE_PADDING 10
#define SCALE_LINE_WIDTH 2


static void
champlain_scale_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  ChamplainScalePrivate *priv = CHAMPLAIN_SCALE (object)->priv;

  switch (prop_id)
    {
    case PROP_MAX_SCALE_WIDTH:
      g_value_set_uint (value, priv->max_scale_width);
      break;

    case PROP_SCALE_UNIT:
      g_value_set_enum (value, priv->scale_unit);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
champlain_scale_set_property (GObject *object,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec)
{
  ChamplainScale *scale = CHAMPLAIN_SCALE (object);

  switch (prop_id)
    {
    case PROP_MAX_SCALE_WIDTH:
      champlain_scale_set_max_width (scale, g_value_get_uint (value));
      break;

    case PROP_SCALE_UNIT:
      champlain_scale_set_unit (scale, g_value_get_enum (value));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
champlain_scale_dispose (GObject *object)
{
  ChamplainScalePrivate *priv = CHAMPLAIN_SCALE (object)->priv;

  if (priv->view)
    {
      champlain_scale_disconnect_view (CHAMPLAIN_SCALE (object));
      priv->view = NULL;
    }
    
  if (priv->canvas)
    {
      g_object_unref (priv->canvas);
      priv->canvas = NULL;
    }

  G_OBJECT_CLASS (champlain_scale_parent_class)->dispose (object);
}


static void
champlain_scale_finalize (GObject *object)
{
/*  ChamplainScalePrivate *priv = CHAMPLAIN_SCALE (object)->priv; */

  G_OBJECT_CLASS (champlain_scale_parent_class)->finalize (object);
}


static void
champlain_scale_class_init (ChamplainScaleClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (ChamplainScalePrivate));

  object_class->finalize = champlain_scale_finalize;
  object_class->dispose = champlain_scale_dispose;
  object_class->get_property = champlain_scale_get_property;
  object_class->set_property = champlain_scale_set_property;

  /**
   * ChamplainScale:max-width:
   *
   * The size of the map scale on screen in pixels.
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_MAX_SCALE_WIDTH,
      g_param_spec_uint ("max-width",
          "The width of the scale",
          "The max width of the scale"
          "on screen",
          1,
          2000,
          100,
          G_PARAM_READWRITE));

  /**
   * ChamplainScale:unit:
   *
   * The scale's units.
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class,
      PROP_SCALE_UNIT,
      g_param_spec_enum ("unit",
          "The scale's unit",
          "The map scale's unit",
          CHAMPLAIN_TYPE_UNIT,
          CHAMPLAIN_UNIT_KM,
          G_PARAM_READWRITE));
}


static gboolean
redraw_scale (ClutterCanvas *canvas,
    cairo_t *cr,
    int w,
    int h,
    ChamplainScale *scale)
{
  gboolean is_small_unit = TRUE;  /* indicates if using meters */
  ClutterActor *text;
  gfloat width, height;
  ChamplainScalePrivate *priv = scale->priv;
  gfloat m_per_pixel;
  gfloat scale_width = priv->max_scale_width;
  gchar *label;
  gfloat base;
  gfloat factor;
  gboolean final_unit = FALSE;
  gint zoom_level;
  gdouble lat, lon;
  gfloat offset;
  ChamplainMapSource *map_source;

  if (!priv->view)
    return FALSE;

  zoom_level = champlain_view_get_zoom_level (priv->view);
  map_source = champlain_view_get_map_source (priv->view);
  lat = champlain_view_get_center_latitude (priv->view);
  lon = champlain_view_get_center_longitude (priv->view);
  m_per_pixel = champlain_map_source_get_meters_per_pixel (map_source,
        zoom_level, lat, lon);

  if (priv->scale_unit == CHAMPLAIN_UNIT_MILES)
    m_per_pixel *= 3.28;  /* m_per_pixel is now in ft */

  /* This loop will find the pretty value to display on the scale.
   * It will be run once for metric units, and twice for imperials
   * so that both feet and miles have pretty numbers.
   */
  do
    {
      /* Keep the previous power of 10 */
      base = floor (log (m_per_pixel * scale_width) / log (10));
      base = pow (10, base);

      /* How many times can it be fitted in our max scale width */
      g_assert (base > 0);
      g_assert (m_per_pixel * scale_width / base > 0);
      scale_width /= m_per_pixel * scale_width / base;
      g_assert (scale_width > 0);
      factor = floor (priv->max_scale_width / scale_width);
      base *= factor;
      scale_width *= factor;

      if (priv->scale_unit == CHAMPLAIN_UNIT_KM)
        {
          if (base / 1000.0 >= 1)
            {
              base /= 1000.0; /* base is now in km */
              is_small_unit = FALSE;
            }
          final_unit = TRUE; /* Don't need to recompute */
        }
      else if (priv->scale_unit == CHAMPLAIN_UNIT_MILES)
        {
          if (is_small_unit && base / 5280.0 >= 1)
            {
              m_per_pixel /= 5280.0; /* m_per_pixel is now in miles */
              is_small_unit = FALSE;
              /* we need to recompute the base because 1000 ft != 1 mile */
            }
          else
            final_unit = TRUE;
        }
    } while (!final_unit);

  text = clutter_container_find_child_by_name (CLUTTER_CONTAINER (scale), "scale-far-label");
  label = g_strdup_printf ("%g", base);
  /* Get only digits width for centering */
  clutter_text_set_text (CLUTTER_TEXT (text), label);
  g_free (label);
  clutter_actor_get_size (text, &width, NULL);
  /* actual label with unit */
  label = g_strdup_printf ("%g %s", base,
        priv->scale_unit == CHAMPLAIN_UNIT_KM ?
        (is_small_unit ? "m" : "km") :
        (is_small_unit ? "ft" : "miles"));
  clutter_text_set_text (CLUTTER_TEXT (text), label);
  g_free (label);
  clutter_actor_set_position (text, ceil (scale_width - width / 2) + SCALE_INSIDE_PADDING, SCALE_INSIDE_PADDING);

  text = clutter_container_find_child_by_name (CLUTTER_CONTAINER (scale), "scale-mid-label");
  label = g_strdup_printf ("%g", base / 2.0);
  clutter_text_set_text (CLUTTER_TEXT (text), label);
  clutter_actor_get_size (text, &width, &height);
  clutter_actor_set_position (text, ceil ((scale_width - width) / 2) + SCALE_INSIDE_PADDING, SCALE_INSIDE_PADDING);
  g_free (label);

  /* Draw the line */
  cairo_set_operator (cr, CAIRO_OPERATOR_CLEAR);
  cairo_paint (cr);
  cairo_set_operator (cr, CAIRO_OPERATOR_OVER);

  cairo_set_source_rgb (cr, 0, 0, 0);
  cairo_set_line_cap (cr, CAIRO_LINE_CAP_ROUND);
  cairo_set_line_width (cr, SCALE_LINE_WIDTH);

  offset = SCALE_INSIDE_PADDING + priv->text_height + GAP_SIZE;

  /* First tick */
  cairo_move_to (cr, SCALE_INSIDE_PADDING, offset);
  cairo_line_to (cr, SCALE_INSIDE_PADDING, offset + SCALE_HEIGHT);
  cairo_stroke (cr);

  /* Line */
  cairo_move_to (cr, SCALE_INSIDE_PADDING, offset + SCALE_HEIGHT);
  cairo_line_to (cr, scale_width + SCALE_INSIDE_PADDING, offset + SCALE_HEIGHT);
  cairo_stroke (cr);

  /* Middle tick */
  cairo_move_to (cr, scale_width / 2 + SCALE_INSIDE_PADDING, offset);
  cairo_line_to (cr, scale_width / 2 + SCALE_INSIDE_PADDING, offset + SCALE_HEIGHT);
  cairo_stroke (cr);

  /* Last tick */
  cairo_move_to (cr, scale_width + SCALE_INSIDE_PADDING, offset);
  cairo_line_to (cr, scale_width + SCALE_INSIDE_PADDING, offset + SCALE_HEIGHT);
  cairo_stroke (cr);

  return FALSE;
}


static gboolean
invalidate_canvas (ChamplainScale *layer)
{
  ChamplainScalePrivate *priv = layer->priv;

  clutter_content_invalidate (priv->canvas);
  priv->redraw_scheduled = FALSE;

  return FALSE;
}


static void
schedule_redraw (ChamplainScale *layer)
{
  if (!layer->priv->redraw_scheduled)
    {
      layer->priv->redraw_scheduled = TRUE;
      g_idle_add_full (CLUTTER_PRIORITY_REDRAW,
          (GSourceFunc) invalidate_canvas,
          g_object_ref (layer),
          (GDestroyNotify) g_object_unref);
    }
}


static void
create_scale (ChamplainScale *scale)
{
  ClutterActor *text, *scale_actor;
  gfloat width, height;
  ChamplainScalePrivate *priv = scale->priv;

  clutter_actor_destroy_all_children (CLUTTER_ACTOR (scale));
  
  text = clutter_text_new_with_text ("Sans 9", "X km");
  clutter_actor_set_name (text, "scale-far-label");
  clutter_actor_add_child (CLUTTER_ACTOR (scale), text);

  text = clutter_text_new_with_text ("Sans 9", "X");
  clutter_actor_set_name (text, "scale-mid-label");
  clutter_actor_add_child (CLUTTER_ACTOR (scale), text);

  text = clutter_text_new_with_text ("Sans 9", "0");
  clutter_actor_add_child (CLUTTER_ACTOR (scale), text);
  clutter_actor_get_size (text, &width, &priv->text_height);
  clutter_actor_set_position (text, SCALE_INSIDE_PADDING - ceil (width / 2), SCALE_INSIDE_PADDING);

  width = priv->max_scale_width + 2 * SCALE_INSIDE_PADDING;
  height = SCALE_HEIGHT + priv->text_height + GAP_SIZE + 2 * SCALE_INSIDE_PADDING;
  
  priv->canvas = clutter_canvas_new ();
  clutter_canvas_set_size (CLUTTER_CANVAS (priv->canvas), width, height);
  g_signal_connect (priv->canvas, "draw", G_CALLBACK (redraw_scale), scale);
  
  scale_actor = clutter_actor_new ();
  clutter_actor_set_size (scale_actor, width, height);
  clutter_actor_set_content (scale_actor, priv->canvas);
  clutter_actor_add_child (CLUTTER_ACTOR (scale), scale_actor);

  clutter_actor_set_opacity (CLUTTER_ACTOR (scale), 200);

  schedule_redraw (scale);
}


static void
champlain_scale_init (ChamplainScale *scale)
{
  ChamplainScalePrivate *priv = GET_PRIVATE (scale);

  scale->priv = priv;

  priv->scale_unit = CHAMPLAIN_UNIT_KM;
  priv->max_scale_width = 100;
  priv->view = NULL;
  priv->redraw_scheduled = FALSE;

  create_scale (scale);
}


/**
 * champlain_scale_new:
 *
 * Creates an instance of #ChamplainScale.
 *
 * Returns: a new #ChamplainScale.
 *
 * Since: 0.10
 */
ClutterActor *
champlain_scale_new (void)
{
  return CLUTTER_ACTOR (g_object_new (CHAMPLAIN_TYPE_SCALE, NULL));
}


/**
 * champlain_scale_set_max_width:
 * @scale: a #ChamplainScale
 * @value: the number of pixels
 *
 * Sets the maximum width of the scale on the screen in pixels
 *
 * Since: 0.10
 */
void
champlain_scale_set_max_width (ChamplainScale *scale,
    guint value)
{
  g_return_if_fail (CHAMPLAIN_IS_SCALE (scale));

  scale->priv->max_scale_width = value;
  create_scale (scale);
  g_object_notify (G_OBJECT (scale), "max-width");
}


/**
 * champlain_scale_set_unit:
 * @scale: a #ChamplainScale
 * @unit: a #ChamplainUnit
 *
 * Sets the scale unit.
 *
 * Since: 0.10
 */
void
champlain_scale_set_unit (ChamplainScale *scale,
    ChamplainUnit unit)
{
  g_return_if_fail (CHAMPLAIN_IS_SCALE (scale));

  scale->priv->scale_unit = unit;
  g_object_notify (G_OBJECT (scale), "unit");
  schedule_redraw (scale);
}


/**
 * champlain_scale_get_max_width:
 * @scale: a #ChamplainScale
 *
 * Gets the maximum scale width.
 *
 * Returns: The maximum scale width in pixels.
 *
 * Since: 0.10
 */
guint
champlain_scale_get_max_width (ChamplainScale *scale)
{
  g_return_val_if_fail (CHAMPLAIN_IS_SCALE (scale), FALSE);

  return scale->priv->max_scale_width;
}


/**
 * champlain_scale_get_unit:
 * @scale: a #ChamplainScale
 *
 * Gets the unit used by the scale.
 *
 * Returns: The unit used by the scale
 *
 * Since: 0.10
 */
ChamplainUnit
champlain_scale_get_unit (ChamplainScale *scale)
{
  g_return_val_if_fail (CHAMPLAIN_IS_SCALE (scale), FALSE);

  return scale->priv->scale_unit;
}


static void
redraw_scale_cb (G_GNUC_UNUSED GObject *gobject,
    G_GNUC_UNUSED GParamSpec *arg1,
    ChamplainScale *scale)
{
  schedule_redraw (scale);
}


/**
 * champlain_scale_connect_view:
 * @scale: a #ChamplainScale
 * @view: a #ChamplainView
 *
 * This method connects to the necessary signals of #ChamplainView to make the
 * scale adapt to the current latitude and longitude.
 *
 * Since: 0.10
 */
void
champlain_scale_connect_view (ChamplainScale *scale,
    ChamplainView *view)
{
  g_return_if_fail (CHAMPLAIN_IS_SCALE (scale));

  scale->priv->view = g_object_ref (view);
  g_signal_connect (view, "notify::latitude",
      G_CALLBACK (redraw_scale_cb), scale);
  schedule_redraw (scale);
}


/**
 * champlain_scale_disconnect_view:
 * @scale: a #ChamplainScale
 *
 * This method disconnects from the signals previously connected by champlain_scale_connect_view().
 *
 * Since: 0.10
 */
void
champlain_scale_disconnect_view (ChamplainScale *scale)
{
  g_return_if_fail (CHAMPLAIN_IS_SCALE (scale));

  g_signal_handlers_disconnect_by_func (scale->priv->view,
      redraw_scale_cb,
      scale);
  g_object_unref (scale->priv->view);
  scale->priv->view = NULL;
}
