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
 * SECTION:champlain-point
 * @short_description: A simple point to mark a coordinate
 *
 * #ChamplainPoint is a simple variant of #ChamplainMarker. Contrary to
 * #ChamplainLabel, it is not capable of labelling the point with text and
 * only shows the location of the point as a circle on the map.
 */

#include "config.h"

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
#include <string.h>

#define DEFAULT_FONT_NAME "Sans 11"

static ClutterColor DEFAULT_COLOR = { 0x33, 0x33, 0x33, 0xff };

enum
{
  /* normal signals */
  LAST_SIGNAL
};

enum
{
  PROP_0,
  PROP_COLOR,
  PROP_SIZE,
  PROP_SURFACE,
};

/* static guint champlain_point_signals[LAST_SIGNAL] = { 0, }; */

struct _ChamplainPointPrivate
{
  ClutterColor *color;
  gdouble size;
  ClutterContent *canvas;
  cairo_surface_t *surface;

  guint redraw_id;
};

static void set_surface (ChamplainExportable *exportable,
    cairo_surface_t *surface);
static cairo_surface_t *get_surface (ChamplainExportable *exportable);

static void exportable_interface_init (ChamplainExportableIface *iface);

G_DEFINE_TYPE_WITH_CODE (ChamplainPoint, champlain_point, CHAMPLAIN_TYPE_MARKER,
    G_IMPLEMENT_INTERFACE (CHAMPLAIN_TYPE_EXPORTABLE, exportable_interface_init));

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), CHAMPLAIN_TYPE_POINT, ChamplainPointPrivate))


static void
champlain_point_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  ChamplainPointPrivate *priv = CHAMPLAIN_POINT (object)->priv;

  switch (prop_id)
    {
    case PROP_COLOR:
      clutter_value_set_color (value, priv->color);
      break;

    case PROP_SIZE:
      g_value_set_double (value, priv->size);
      break;

    case PROP_SURFACE:
      g_value_set_boxed (value, get_surface (CHAMPLAIN_EXPORTABLE (object)));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
champlain_point_set_property (GObject *object,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec)
{
  ChamplainPoint *point = CHAMPLAIN_POINT (object);

  switch (prop_id)
    {
    case PROP_COLOR:
      champlain_point_set_color (point, clutter_value_get_color (value));
      break;

    case PROP_SIZE:
      champlain_point_set_size (point, g_value_get_double (value));
      break;

    case PROP_SURFACE:
      set_surface (CHAMPLAIN_EXPORTABLE (object), g_value_get_boxed (value));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
pick (ClutterActor *self,
    const ClutterColor *color)
{
  ChamplainPointPrivate *priv = GET_PRIVATE (self);
  gdouble radius = priv->size / 2.0;

  cogl_path_new ();

  cogl_set_source_color4ub (color->red,
      color->green,
      color->blue,
      color->alpha);

  cogl_path_move_to (radius, radius);
  cogl_path_arc (radius, radius, radius, radius, 0, 360.0);
  cogl_path_close ();
  cogl_path_fill ();
}


static void
champlain_point_dispose (GObject *object)
{
  ChamplainPointPrivate *priv = CHAMPLAIN_POINT (object)->priv;

  g_clear_pointer (&priv->surface, cairo_surface_destroy);

  G_OBJECT_CLASS (champlain_point_parent_class)->dispose (object);
}


static void
champlain_point_finalize (GObject *object)
{
  ChamplainPointPrivate *priv = CHAMPLAIN_POINT (object)->priv;

  if (priv->color)
    {
      clutter_color_free (priv->color);
      priv->color = NULL;
    }

  if (priv->canvas)
    {
      g_object_unref (priv->canvas);
      priv->canvas = NULL;
    }

  G_OBJECT_CLASS (champlain_point_parent_class)->finalize (object);
}


static void
champlain_point_class_init (ChamplainPointClass *klass)
{
  ClutterActorClass *actor_class = CLUTTER_ACTOR_CLASS (klass);
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (ChamplainPointPrivate));

  object_class->finalize = champlain_point_finalize;
  object_class->dispose = champlain_point_dispose;
  object_class->get_property = champlain_point_get_property;
  object_class->set_property = champlain_point_set_property;

  actor_class->pick = pick;

  g_object_class_install_property (object_class, PROP_COLOR,
      clutter_param_spec_color ("color", 
          "Color", 
          "The point's color",
          &DEFAULT_COLOR, 
          CHAMPLAIN_PARAM_READWRITE));

  g_object_class_install_property (object_class, PROP_SIZE,
      g_param_spec_double ("size", 
          "Size", 
          "The point size", 
          0, 
          G_MAXDOUBLE,
          12, 
          CHAMPLAIN_PARAM_READWRITE));

  g_object_class_override_property (object_class,
      PROP_SURFACE,
      "surface");

}


static void
draw (ClutterCanvas *canvas,
      cairo_t       *cr,
      gint           width,
      gint           height,
      ChamplainPoint *point)
{
  ChamplainPointPrivate *priv = point->priv;
  gdouble size = priv->size;
  gdouble radius = size / 2.0;
  const ClutterColor *color;

  set_surface (CHAMPLAIN_EXPORTABLE (point), cairo_get_target (cr));

  cairo_set_operator (cr, CAIRO_OPERATOR_CLEAR);
  cairo_paint (cr);
  cairo_set_operator (cr, CAIRO_OPERATOR_OVER);

  if (champlain_marker_get_selected (CHAMPLAIN_MARKER (point)))
    color = champlain_marker_get_selection_color ();
  else
    color = priv->color;

  cairo_set_source_rgba (cr,
      color->red / 255.0,
      color->green / 255.0,
      color->blue / 255.0,
      color->alpha / 255.0);

  cairo_arc (cr, radius, radius, radius, 0, 2 * M_PI);
  cairo_fill (cr);

  cairo_fill_preserve (cr);
  cairo_set_line_width (cr, 1.0);
  cairo_stroke (cr);
}


static void
notify_selected (GObject *gobject,
    G_GNUC_UNUSED GParamSpec *pspec,
    G_GNUC_UNUSED gpointer user_data)
{
  clutter_content_invalidate (CHAMPLAIN_POINT (gobject)->priv->canvas);
}


static void
champlain_point_init (ChamplainPoint *point)
{
  ChamplainPointPrivate *priv = GET_PRIVATE (point);

  point->priv = priv;

  priv->color = clutter_color_copy (&DEFAULT_COLOR);
  priv->size = 12;
  priv->canvas = clutter_canvas_new ();
  g_signal_connect (priv->canvas, "draw", G_CALLBACK (draw), point);
  clutter_canvas_set_size (CLUTTER_CANVAS (priv->canvas), priv->size, priv->size);
  clutter_actor_set_size (CLUTTER_ACTOR (point), priv->size, priv->size);
  clutter_actor_set_content (CLUTTER_ACTOR (point), priv->canvas);
  clutter_actor_set_translation (CLUTTER_ACTOR (point), -priv->size/2, -priv->size/2, 0.0);
  clutter_content_invalidate (priv->canvas);

  g_signal_connect (point, "notify::selected", G_CALLBACK (notify_selected), NULL);
}


static void
set_surface (ChamplainExportable *exportable,
     cairo_surface_t *surface)
{
  g_return_if_fail (CHAMPLAIN_POINT (exportable));
  g_return_if_fail (surface != NULL);

  ChamplainPoint *self = CHAMPLAIN_POINT (exportable);

  if (self->priv->surface == surface)
    return;

  cairo_surface_destroy (self->priv->surface);
  self->priv->surface = cairo_surface_reference (surface);
  g_object_notify (G_OBJECT (self), "surface");
}

static cairo_surface_t *
get_surface (ChamplainExportable *exportable)
{
  g_return_val_if_fail (CHAMPLAIN_POINT (exportable), NULL);

  return CHAMPLAIN_POINT (exportable)->priv->surface;
}


static void
exportable_interface_init (ChamplainExportableIface *iface)
{
  iface->get_surface = get_surface;
  iface->set_surface = set_surface;
}


/**
 * champlain_point_new:
 *
 * Creates an instance of #ChamplainPoint with default size and color.
 *
 * Returns: a new #ChamplainPoint.
 *
 * Since: 0.10
 */
ClutterActor *
champlain_point_new (void)
{
  return CLUTTER_ACTOR (g_object_new (CHAMPLAIN_TYPE_POINT, NULL));
}


/**
 * champlain_point_new_full:
 * @size: Marker size
 * @color: Marker color
 *
 * Creates an instance of #ChamplainPoint with the specified size and color.
 *
 * Returns: a new #ChamplainPoint.
 *
 * Since: 0.10
 */
ClutterActor *
champlain_point_new_full (gdouble size,
    const ClutterColor *color)
{
  ChamplainPoint *point = CHAMPLAIN_POINT (champlain_point_new ());

  champlain_point_set_size (point, size);
  champlain_point_set_color (point, color);

  return CLUTTER_ACTOR (point);
}


/**
 * champlain_point_set_size:
 * @point: a #ChamplainPoint
 * @size: The size of the point.
 *
 * Set the size of the point.
 *
 * Since: 0.10
 */
void
champlain_point_set_size (ChamplainPoint *point,
    gdouble size)
{
  g_return_if_fail (CHAMPLAIN_IS_POINT (point));

  ChamplainPointPrivate *priv = point->priv;

  point->priv->size = size;
  clutter_canvas_set_size (CLUTTER_CANVAS (priv->canvas), size, size);
  clutter_actor_set_size (CLUTTER_ACTOR (point), priv->size, priv->size);
  clutter_actor_set_translation (CLUTTER_ACTOR (point), -priv->size/2, -priv->size/2, 0.0);
  g_object_notify (G_OBJECT (point), "size");
  clutter_content_invalidate (priv->canvas);
}


/**
 * champlain_point_get_size:
 * @point: a #ChamplainPoint
 *
 * Gets the size of the point.
 *
 * Returns: the size.
 *
 * Since: 0.10
 */
gdouble
champlain_point_get_size (ChamplainPoint *point)
{
  g_return_val_if_fail (CHAMPLAIN_IS_POINT (point), 0);

  return point->priv->size;
}


/**
 * champlain_point_set_color:
 * @point: a #ChamplainPoint
 * @color: (allow-none): The color of the point or NULL to reset the background to the
 *         default color. The color parameter is copied.
 *
 * Set the color of the point.
 *
 * Since: 0.10
 */
void
champlain_point_set_color (ChamplainPoint *point,
    const ClutterColor *color)
{
  g_return_if_fail (CHAMPLAIN_IS_POINT (point));

  ChamplainPointPrivate *priv = point->priv;

  if (priv->color != NULL)
    clutter_color_free (priv->color);

  if (color == NULL)
    color = &DEFAULT_COLOR;

  priv->color = clutter_color_copy (color);
  g_object_notify (G_OBJECT (point), "color");
  clutter_content_invalidate (priv->canvas);
}


/**
 * champlain_point_get_color:
 * @point: a #ChamplainPoint
 *
 * Gets the color of the point.
 *
 * Returns: the color.
 *
 * Since: 0.10
 */
ClutterColor *
champlain_point_get_color (ChamplainPoint *point)
{
  g_return_val_if_fail (CHAMPLAIN_IS_POINT (point), NULL);

  return point->priv->color;
}
