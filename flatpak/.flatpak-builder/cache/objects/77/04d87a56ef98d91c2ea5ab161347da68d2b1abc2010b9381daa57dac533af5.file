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
 * SECTION:champlain-label
 * @short_description: A label to identify points of interest on a map
 *
 * Markers reprensent points of interest on a map. Markers need to be placed on
 * a layer (a #ChamplainMarkerLayer).  Layers have to be added to a #ChamplainView for
 * the markers to show on the map.
 *
 * A marker is nothing more than a regular #ClutterActor.  You can draw on it
 * what ever you want. Set the markers position on the map
 * using #champlain_location_set_location.
 *
 * Champlain has a default type of markers with text. To create one,
 * use #champlain_label_new_with_text.
 */

#include "config.h"

#include "champlain-label.h"

#include "champlain.h"
#include "champlain-defines.h"
#include "champlain-marshal.h"
#include "champlain-private.h"
#include "champlain-tile.h"

#include <clutter/clutter.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <glib.h>
#include <glib-object.h>
#include <cairo.h>
#include <math.h>
#include <string.h>

#define DEFAULT_FONT_NAME "Sans 11"
#define SLOPE -0.3
#define SCALING 0.65

static ClutterColor DEFAULT_COLOR = { 0x33, 0x33, 0x33, 0xff };
static ClutterColor DEFAULT_TEXT_COLOR = { 0xee, 0xee, 0xee, 0xff };

enum
{
  /* normal signals */
  LAST_SIGNAL
};

enum
{
  PROP_0,
  PROP_IMAGE,
  PROP_TEXT,
  PROP_USE_MARKUP,
  PROP_ALIGNMENT,
  PROP_ATTRIBUTES,
  PROP_ELLIPSIZE,
  PROP_COLOR,
  PROP_TEXT_COLOR,
  PROP_FONT_NAME,
  PROP_WRAP,
  PROP_WRAP_MODE,
  PROP_SINGLE_LINE_MODE,
  PROP_DRAW_BACKGROUND,
  PROP_DRAW_SHADOW
};

/* static guint champlain_label_signals[LAST_SIGNAL] = { 0, }; */

struct _ChamplainLabelPrivate
{
  gchar *text;
  ClutterActor *image;
  gboolean use_markup;
  PangoAlignment alignment;
  PangoAttrList *attributes;
  ClutterColor *color;
  ClutterColor *text_color;
  gchar *font_name;
  gboolean wrap;
  PangoWrapMode wrap_mode;
  gboolean single_line_mode;
  PangoEllipsizeMode ellipsize;
  gboolean draw_background;
  gboolean draw_shadow;

  guint redraw_id;
  gint total_width;
  gint total_height;
  gint point;
};

G_DEFINE_TYPE (ChamplainLabel, champlain_label, CHAMPLAIN_TYPE_MARKER);

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), CHAMPLAIN_TYPE_LABEL, ChamplainLabelPrivate))

static void draw_label (ChamplainLabel *label);


static void
champlain_label_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  ChamplainLabelPrivate *priv = CHAMPLAIN_LABEL (object)->priv;

  switch (prop_id)
    {
    case PROP_TEXT:
      g_value_set_string (value, priv->text);
      break;

    case PROP_IMAGE:
      g_value_set_object (value, priv->image);
      break;

    case PROP_USE_MARKUP:
      g_value_set_boolean (value, priv->use_markup);
      break;

    case PROP_ALIGNMENT:
      g_value_set_enum (value, priv->alignment);
      break;

    case PROP_COLOR:
      clutter_value_set_color (value, priv->color);
      break;

    case PROP_TEXT_COLOR:
      clutter_value_set_color (value, priv->text_color);
      break;

    case PROP_FONT_NAME:
      g_value_set_string (value, priv->font_name);
      break;

    case PROP_WRAP:
      g_value_set_boolean (value, priv->wrap);
      break;

    case PROP_WRAP_MODE:
      g_value_set_enum (value, priv->wrap_mode);
      break;

    case PROP_DRAW_BACKGROUND:
      g_value_set_boolean (value, priv->draw_background);
      break;

    case PROP_DRAW_SHADOW:
      g_value_set_boolean (value, priv->draw_shadow);
      break;

    case PROP_ELLIPSIZE:
      g_value_set_enum (value, priv->ellipsize);
      break;

    case PROP_SINGLE_LINE_MODE:
      g_value_set_enum (value, priv->single_line_mode);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
champlain_label_set_property (GObject *object,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec)
{
  ChamplainLabel *label = CHAMPLAIN_LABEL (object);

  switch (prop_id)
    {
    case PROP_TEXT:
      champlain_label_set_text (label, g_value_get_string (value));
      break;

    case PROP_IMAGE:
      champlain_label_set_image (label, g_value_get_object (value));
      break;

    case PROP_USE_MARKUP:
      champlain_label_set_use_markup (label, g_value_get_boolean (value));
      break;

    case PROP_ALIGNMENT:
      champlain_label_set_alignment (label, g_value_get_enum (value));
      break;

    case PROP_COLOR:
      champlain_label_set_color (label, clutter_value_get_color (value));
      break;

    case PROP_TEXT_COLOR:
      champlain_label_set_text_color (label, clutter_value_get_color (value));
      break;

    case PROP_FONT_NAME:
      champlain_label_set_font_name (label, g_value_get_string (value));
      break;

    case PROP_WRAP:
      champlain_label_set_wrap (label, g_value_get_boolean (value));
      break;

    case PROP_WRAP_MODE:
      champlain_label_set_wrap_mode (label, g_value_get_enum (value));
      break;

    case PROP_ELLIPSIZE:
      champlain_label_set_ellipsize (label, g_value_get_enum (value));
      break;

    case PROP_DRAW_BACKGROUND:
      champlain_label_set_draw_background (label, g_value_get_boolean (value));
      break;

    case PROP_DRAW_SHADOW:
      champlain_label_set_draw_shadow (label, g_value_get_boolean (value));
      break;

    case PROP_SINGLE_LINE_MODE:
      champlain_label_set_single_line_mode (label, g_value_get_boolean (value));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


#define RADIUS 10
#define PADDING (RADIUS / 2)

static void
pick (ClutterActor *self,
    const ClutterColor *color)
{
  ChamplainLabelPrivate *priv = GET_PRIVATE (self);
  gfloat width, height;

  if (!clutter_actor_should_pick_paint (self))
    return;

  width = priv->total_width;
  height = priv->total_height;

  cogl_path_new ();

  cogl_set_source_color4ub (color->red,
      color->green,
      color->blue,
      color->alpha);

  cogl_path_move_to (RADIUS, 0);
  cogl_path_line_to (width - RADIUS, 0);
  cogl_path_arc (width - RADIUS, RADIUS, RADIUS, RADIUS, -90, 0);
  cogl_path_line_to (width, height - RADIUS);
  cogl_path_arc (width - RADIUS, height - RADIUS, RADIUS, RADIUS, 0, 90);
  cogl_path_line_to (RADIUS, height);
  cogl_path_arc (RADIUS, height - RADIUS, RADIUS, RADIUS, 90, 180);
  cogl_path_line_to (0, RADIUS);
  cogl_path_arc (RADIUS, RADIUS, RADIUS, RADIUS, 180, 270);
  cogl_path_close ();
  cogl_path_fill ();
}


static void
champlain_label_dispose (GObject *object)
{
  ChamplainLabelPrivate *priv = CHAMPLAIN_LABEL (object)->priv;

  if (priv->image)
    {
      clutter_actor_destroy (priv->image);
      priv->image = NULL;
    }

  if (priv->attributes)
    {
      pango_attr_list_unref (priv->attributes);
      priv->attributes = NULL;
    }

  G_OBJECT_CLASS (champlain_label_parent_class)->dispose (object);
}


static void
champlain_label_finalize (GObject *object)
{
  ChamplainLabelPrivate *priv = CHAMPLAIN_LABEL (object)->priv;

  if (priv->text)
    {
      g_free (priv->text);
      priv->text = NULL;
    }

  if (priv->font_name)
    {
      g_free (priv->font_name);
      priv->font_name = NULL;
    }

  if (priv->color)
    {
      clutter_color_free (priv->color);
      priv->color = NULL;
    }

  if (priv->text_color)
    {
      clutter_color_free (priv->text_color);
      priv->text_color = NULL;
    }

  if (priv->redraw_id)
    {
      g_source_remove (priv->redraw_id);
      priv->redraw_id = 0;
    }

  G_OBJECT_CLASS (champlain_label_parent_class)->finalize (object);
}


static void
champlain_label_class_init (ChamplainLabelClass *klass)
{
  ClutterActorClass *actor_class = CLUTTER_ACTOR_CLASS (klass);
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (klass, sizeof (ChamplainLabelPrivate));

  object_class->finalize = champlain_label_finalize;
  object_class->dispose = champlain_label_dispose;
  object_class->get_property = champlain_label_get_property;
  object_class->set_property = champlain_label_set_property;

  actor_class->pick = pick;

  /**
   * ChamplainLabel:text:
   *
   * The text of the label
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_TEXT,
      g_param_spec_string ("text", 
          "Text", 
          "The text of the label",
          "", 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLabel:image:
   *
   * The image of the label
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_IMAGE,
      g_param_spec_object ("image", 
          "Image", 
          "The image of the label",
          CLUTTER_TYPE_ACTOR, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLabel:use-markup:
   *
   * If the label's text uses markup
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_USE_MARKUP,
      g_param_spec_boolean ("use-markup", 
          "Use Markup", 
          "The text uses markup",
          FALSE, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLabel:alignment:
   *
   * The label's alignment
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_ALIGNMENT,
      g_param_spec_enum ("alignment", 
          "Alignment", 
          "The label's alignment",
          PANGO_TYPE_ALIGNMENT, 
          PANGO_ALIGN_LEFT, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLabel:color:
   *
   * The label's color
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_COLOR,
      clutter_param_spec_color ("color", 
          "Color", 
          "The label's color",
          &DEFAULT_COLOR, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLabel:text-color:
   *
   * The label's text color
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_TEXT_COLOR,
      clutter_param_spec_color ("text-color", 
          "Text Color", 
          "The label's text color",
          &DEFAULT_TEXT_COLOR, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLabel:font-name:
   *
   * The label's text font name
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_FONT_NAME,
      g_param_spec_string ("font-name", 
          "Font Name", 
          "The label's text font name",
          "Sans 11", 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLabel:wrap:
   *
   * If the label's text wrap is set
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_WRAP,
      g_param_spec_boolean ("wrap", 
          "Wrap", 
          "The label's text wrap",
          FALSE, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLabel:wrap-mode:
   *
   * The label's text wrap mode
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_WRAP_MODE,
      g_param_spec_enum ("wrap-mode", 
          "Wrap Mode", 
          "The label's text wrap mode",
          PANGO_TYPE_WRAP_MODE, 
          PANGO_WRAP_WORD, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLabel:ellipsize:
   *
   * The label's ellipsize mode
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_ELLIPSIZE,
      g_param_spec_enum ("ellipsize", 
          "Ellipsize Mode", 
          "The label's text ellipsize mode",
          PANGO_TYPE_ELLIPSIZE_MODE, 
          PANGO_ELLIPSIZE_NONE, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLabel:draw-background:
   *
   * If the label has a background
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_DRAW_BACKGROUND,
      g_param_spec_boolean ("draw-background", 
          "Draw Background", 
          "The label has a background",
          TRUE, 
          CHAMPLAIN_PARAM_READWRITE));

/**
   * ChamplainLabel:draw-shadow:
   *
   * If the label background has a shadow
   *
   * Since: 0.12.10
   */
  g_object_class_install_property (object_class, PROP_DRAW_SHADOW,
      g_param_spec_boolean ("draw-shadow", 
          "Draw Shadow", 
          "The label background has a shadow",
          TRUE, 
          CHAMPLAIN_PARAM_READWRITE));

  /**
   * ChamplainLabel:single-line-mode:
   *
   * If the label is in single line mode
   *
   * Since: 0.10
   */
  g_object_class_install_property (object_class, PROP_SINGLE_LINE_MODE,
      g_param_spec_boolean ("single-line-mode", 
          "Single Line Mode", 
          "The label's single line mode",
          TRUE, 
          CHAMPLAIN_PARAM_READWRITE));
}


static void
draw_box (cairo_t *cr,
    gint width,
    gint height,
    gint point,
    gboolean mirror)
{
  if (mirror)
    {
      cairo_move_to (cr, RADIUS, 0);
      cairo_line_to (cr, width - RADIUS, 0);
      cairo_arc (cr, width - RADIUS, RADIUS, RADIUS - 1, 3 * M_PI / 2.0, 0);
      cairo_line_to (cr, width, height - RADIUS);
      cairo_arc (cr, width - RADIUS, height - RADIUS, RADIUS - 1, 0, M_PI / 2.0);
      cairo_line_to (cr, point, height);
      cairo_line_to (cr, 0, height + point);
      cairo_arc (cr, RADIUS, RADIUS, RADIUS - 1, M_PI, 3 * M_PI / 2.0);
      cairo_close_path (cr);
    }
  else
    {
      cairo_move_to (cr, RADIUS, 0);
      cairo_line_to (cr, width - RADIUS, 0);
      cairo_arc (cr, width - RADIUS, RADIUS, RADIUS - 1, 3 * M_PI / 2.0, 0);
      cairo_line_to (cr, width, height + point);
      cairo_line_to (cr, width - point, height);
      cairo_line_to (cr, RADIUS, height);
      cairo_arc (cr, RADIUS, height - RADIUS, RADIUS - 1, M_PI / 2.0, M_PI);
      cairo_line_to (cr, 0, RADIUS);
      cairo_arc (cr, RADIUS, RADIUS, RADIUS - 1, M_PI, 3 * M_PI / 2.0);
      cairo_close_path (cr);
    }
}


static gint
get_shadow_slope_width (ChamplainLabel *label)
{
  ChamplainLabelPrivate *priv = label->priv;
  gint x;
  
  if (priv->alignment == PANGO_ALIGN_LEFT)
    x = -40 * SLOPE;
  else
    x = -58 * SLOPE;
    
  return x;
}


static gboolean
draw_shadow (ClutterCanvas *canvas,
    cairo_t *cr,
    int width,
    int height,
    ChamplainLabel *label)
{
  ChamplainLabelPrivate *priv = label->priv;
  gint x;
  cairo_matrix_t matrix;

  x = get_shadow_slope_width (label);

  cairo_set_operator (cr, CAIRO_OPERATOR_CLEAR);
  cairo_paint (cr);
  cairo_set_operator (cr, CAIRO_OPERATOR_OVER);

  cairo_matrix_init (&matrix,
      1, 0,
      SLOPE, SCALING,
      x, 0);
  cairo_set_matrix (cr, &matrix);

  draw_box (cr, width - x, height - priv->point, priv->point, priv->alignment == PANGO_ALIGN_LEFT);

  cairo_set_source_rgba (cr, 0, 0, 0, 0.15);
  cairo_fill (cr);

  return TRUE;
}


static gboolean
draw_background (ClutterCanvas *canvas,
    cairo_t *cr,
    int width,
    int height,
    ChamplainLabel *label)
{
  ChamplainLabelPrivate *priv = label->priv;
  ChamplainMarker *marker = CHAMPLAIN_MARKER (label);
  const ClutterColor *color;
  ClutterColor darker_color;

  cairo_set_operator (cr, CAIRO_OPERATOR_CLEAR);
  cairo_paint (cr);
  cairo_set_operator (cr, CAIRO_OPERATOR_OVER);

  /* If selected, add the selection color to the marker's color */
  if (champlain_marker_get_selected (marker))
    color = champlain_marker_get_selection_color ();
  else
    color = priv->color;

  draw_box (cr, width, height - priv->point, priv->point, priv->alignment == PANGO_ALIGN_LEFT);

  clutter_color_darken (color, &darker_color);

  cairo_set_source_rgba (cr,
      color->red / 255.0,
      color->green / 255.0,
      color->blue / 255.0,
      color->alpha / 255.0);
  cairo_fill_preserve (cr);

  cairo_set_line_width (cr, 1.0);
  cairo_set_source_rgba (cr,
      darker_color.red / 255.0,
      darker_color.green / 255.0,
      darker_color.blue / 255.0,
      darker_color.alpha / 255.0);
  cairo_stroke (cr);
  
  return TRUE;
}


static void
draw_label (ChamplainLabel *label)
{
  ChamplainLabelPrivate *priv = label->priv;
  ChamplainMarker *marker = CHAMPLAIN_MARKER (label);
  gint height = 0;
  gint total_width = 0, total_height = 0;
  ClutterActor *text_actor, *shadow, *background;
  
  text_actor = NULL;
  shadow = NULL;
  background = NULL;
  
  clutter_actor_remove_all_children (CLUTTER_ACTOR (label));
  
  if (priv->image != NULL)
    {
      clutter_actor_set_position (priv->image, PADDING, PADDING);
      total_width = clutter_actor_get_width (priv->image) + 2 * PADDING;
      total_height = clutter_actor_get_height (priv->image) + 2 * PADDING;
      clutter_actor_add_child (CLUTTER_ACTOR (label), priv->image);
    }

  if (priv->text != NULL && strlen (priv->text) > 0)
    {
      ClutterText *text;
      
      text_actor = clutter_text_new_with_text (priv->font_name, priv->text);

      text = CLUTTER_TEXT (text_actor);
      clutter_text_set_font_name (text, priv->font_name);
      clutter_text_set_text (text, priv->text);
      clutter_text_set_line_alignment (text, priv->alignment);
      clutter_text_set_line_wrap (text, priv->wrap);
      clutter_text_set_line_wrap_mode (text, priv->wrap_mode);
      clutter_text_set_ellipsize (text, priv->ellipsize);
      clutter_text_set_attributes (text, priv->attributes);
      clutter_text_set_use_markup (text, priv->use_markup);

      height = clutter_actor_get_height (text_actor);
      if (priv->image != NULL)
        {
          clutter_actor_set_position (text_actor, total_width, (total_height - height) / 2.0);
          total_width += clutter_actor_get_width (text_actor) + 2 * PADDING;
        }
      else
        {
          clutter_actor_set_position (text_actor, 2 * PADDING, PADDING);
          total_width += clutter_actor_get_width (text_actor) + 4 * PADDING;
        }

      height += 2 * PADDING;
      total_height = MAX (total_height, height);

      clutter_text_set_color (text,
          (champlain_marker_get_selected (marker) ? champlain_marker_get_selection_text_color () : priv->text_color));
      clutter_actor_add_child (CLUTTER_ACTOR (label), text_actor);
    }
    
  if (text_actor == NULL && priv->image == NULL)
    {
      total_width = 6 * PADDING;
      total_height = 6 * PADDING;
    }
    
  priv->point = (total_height + 2 * PADDING) / 4.0;
  priv->total_width = total_width;
  priv->total_height = total_height;

  if (priv->draw_background)
    {
      ClutterContent *canvas;
      
      canvas = clutter_canvas_new ();
      clutter_canvas_set_size (CLUTTER_CANVAS (canvas), total_width, total_height + priv->point);
      g_signal_connect (canvas, "draw", G_CALLBACK (draw_background), label);
      background = clutter_actor_new ();
      clutter_actor_set_size (background, total_width, total_height + priv->point);
      clutter_actor_set_content (background, canvas);
      clutter_actor_add_child (CLUTTER_ACTOR (label), background);
      clutter_content_invalidate (canvas);
      g_object_unref (canvas);
      
      if (priv->draw_shadow)
        {
          canvas = clutter_canvas_new ();
          clutter_canvas_set_size (CLUTTER_CANVAS (canvas), total_width + get_shadow_slope_width (label), total_height + priv->point);
          g_signal_connect (canvas, "draw", G_CALLBACK (draw_shadow), label);

          shadow = clutter_actor_new ();
          clutter_actor_set_size (shadow, total_width + get_shadow_slope_width (label), total_height + priv->point);
          clutter_actor_set_content (shadow, canvas);
          clutter_actor_add_child (CLUTTER_ACTOR (label), shadow);
          clutter_actor_set_position (shadow, 0, total_height / 2.0);
          clutter_content_invalidate (canvas);
          g_object_unref (canvas);
        }
    }
          
  if (text_actor != NULL && background != NULL)
    clutter_actor_set_child_above_sibling (CLUTTER_ACTOR (label), text_actor, background);
  if (priv->image != NULL && background != NULL)
    clutter_actor_set_child_above_sibling (CLUTTER_ACTOR (label), priv->image, background);
        
  if (priv->draw_background)
    {
      if (priv->alignment == PANGO_ALIGN_RIGHT)
        clutter_actor_set_translation (CLUTTER_ACTOR (label), -total_width, -total_height - priv->point, 0);
      else
        clutter_actor_set_translation (CLUTTER_ACTOR (label), 0, -total_height - priv->point, 0);
    }
  else if (priv->image != NULL)
    clutter_actor_set_translation (CLUTTER_ACTOR (label), -clutter_actor_get_width (priv->image) / 2.0 - PADDING,
        -clutter_actor_get_height (priv->image) / 2.0 - PADDING, 0);
  else if (text_actor != NULL)
    clutter_actor_set_translation (CLUTTER_ACTOR (label), 0, -clutter_actor_get_height (text_actor) / 2.0, 0);
}


static gboolean
redraw_on_idle (gpointer gobject)
{
  ChamplainLabel *label = CHAMPLAIN_LABEL (gobject);

  draw_label (label);
  label->priv->redraw_id = 0;
  return FALSE;
}


/*
 * champlain_label_queue_redraw:
 * @label: a #ChamplainLabel
 *
 * Queue a redraw of the label as soon as possible. This function should not
 * be used unless you are subclassing ChamplainLabel and adding new properties
 * that affect the aspect of the label.  When they change, call this function
 * to update the label.
 *
 * Since: 0.10
 */
static void
champlain_label_queue_redraw (ChamplainLabel *label)
{
  ChamplainLabelPrivate *priv = label->priv;

  if (!priv->redraw_id)
    {
      priv->redraw_id =
        g_idle_add_full (CLUTTER_PRIORITY_REDRAW,
            (GSourceFunc) redraw_on_idle,
            g_object_ref (label),
            (GDestroyNotify) g_object_unref);
    }
}


static void
notify_selected (GObject *gobject,
    G_GNUC_UNUSED GParamSpec *pspec,
    G_GNUC_UNUSED gpointer user_data)
{
  champlain_label_queue_redraw (CHAMPLAIN_LABEL (gobject));
}


static void
champlain_label_init (ChamplainLabel *label)
{
  ChamplainLabelPrivate *priv = GET_PRIVATE (label);

  label->priv = priv;

  priv->text = NULL;
  priv->image = NULL;
  priv->use_markup = FALSE;
  priv->alignment = PANGO_ALIGN_LEFT;
  priv->attributes = NULL;
  priv->color = clutter_color_copy (&DEFAULT_COLOR);
  priv->text_color = clutter_color_copy (&DEFAULT_TEXT_COLOR);
  priv->font_name = g_strdup (DEFAULT_FONT_NAME);
  priv->wrap = FALSE;
  priv->wrap_mode = PANGO_WRAP_WORD;
  priv->single_line_mode = TRUE;
  priv->ellipsize = PANGO_ELLIPSIZE_NONE;
  priv->draw_background = TRUE;
  priv->draw_shadow = TRUE;
  priv->redraw_id = 0;
  priv->total_width = 0;
  priv->total_height = 0;

  g_signal_connect (label, "notify::selected", G_CALLBACK (notify_selected), NULL);
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_new:
 *
 * Creates a new instance of #ChamplainLabel.
 *
 * Returns: a new #ChamplainLabel ready to be used as a #ClutterActor.
 *
 * Since: 0.10
 */
ClutterActor *
champlain_label_new (void)
{
  return CLUTTER_ACTOR (g_object_new (CHAMPLAIN_TYPE_LABEL, NULL));
}


/**
 * champlain_label_new_with_text:
 * @text: the text of the label
 * @font: (allow-none): the font to use to draw the text, for example "Courrier Bold 11", can be NULL
 * @text_color: (allow-none): a #ClutterColor, the color of the text, can be NULL
 * @label_color: (allow-none): a #ClutterColor, the color of the label, can be NULL
 *
 * Creates a new instance of #ChamplainLabel with text value.
 *
 * Returns: a new #ChamplainLabel with a drawn label containing the given text.
 *
 * Since: 0.10
 */
ClutterActor *
champlain_label_new_with_text (const gchar *text,
    const gchar *font,
    ClutterColor *text_color,
    ClutterColor *label_color)
{
  ChamplainLabel *label = CHAMPLAIN_LABEL (champlain_label_new ());

  champlain_label_set_text (label, text);

  if (font != NULL)
    champlain_label_set_font_name (label, font);

  if (text_color != NULL)
    champlain_label_set_text_color (label, text_color);

  if (label_color != NULL)
    champlain_label_set_color (label, label_color);

  return CLUTTER_ACTOR (label);
}


/**
 * champlain_label_new_with_image:
 * @actor: The image as a @ClutterActor.
 *
 * Creates a new instance of #ChamplainLabel with image.
 *
 * Returns: a new #ChamplainLabel with a drawn label containing the given
 * image.
 *
 * Since: 0.10
 */
ClutterActor *
champlain_label_new_with_image (ClutterActor *actor)
{
  ChamplainLabel *label = CHAMPLAIN_LABEL (champlain_label_new ());

  if (actor != NULL)
    champlain_label_set_image (label, actor);

  return CLUTTER_ACTOR (label);
}


/**
 * champlain_label_new_from_file:
 * @filename: The filename of the image.
 * @error: Return location for an error.
 *
 * Creates a new instance of #ChamplainLabel with image loaded from file.
 *
 * Returns: a new #ChamplainLabel with a drawn label containing the given
 * image.
 *
 * Since: 0.10
 */
ClutterActor *
champlain_label_new_from_file (const gchar *filename,
    GError **error)
{
  ChamplainLabel *label = CHAMPLAIN_LABEL (champlain_label_new ());
  
  ClutterActor *actor;
  GdkPixbuf *pixbuf;
  ClutterContent *content;
  gfloat width, height;
  
  if (filename == NULL)
    return CLUTTER_ACTOR (label);

  pixbuf = gdk_pixbuf_new_from_file (filename, error);
  if (pixbuf == NULL)
    return CLUTTER_ACTOR (label);
    
  content = clutter_image_new ();
  clutter_image_set_data (CLUTTER_IMAGE (content),
                          gdk_pixbuf_get_pixels (pixbuf),
                          gdk_pixbuf_get_has_alpha (pixbuf)
                            ? COGL_PIXEL_FORMAT_RGBA_8888
                            : COGL_PIXEL_FORMAT_RGB_888,
                          gdk_pixbuf_get_width (pixbuf),
                          gdk_pixbuf_get_height (pixbuf),
                          gdk_pixbuf_get_rowstride (pixbuf),
                          error);
  g_object_unref (pixbuf);

  actor = clutter_actor_new ();
  clutter_content_get_preferred_size (content, &width, &height);
  clutter_actor_set_size (actor, width, height);
  clutter_actor_set_content (actor, content);
  clutter_content_invalidate (content);
  g_object_unref (content);
  
  champlain_label_set_image (label, actor);

  return CLUTTER_ACTOR (label);
}


/**
 * champlain_label_new_full:
 * @text: The text of the label
 * @actor: The image as a @ClutterActor
 *
 * Creates a new instance of #ChamplainLabel consisting of a custom #ClutterActor.
 *
 * Returns: a new #ChamplainLabel with a drawn label containing the given
 * image.
 *
 * Since: 0.10
 */
ClutterActor *
champlain_label_new_full (const gchar *text,
    ClutterActor *actor)
{
  ChamplainLabel *label = CHAMPLAIN_LABEL (champlain_label_new ());

  if (actor != NULL)
    {
      champlain_label_set_image (label, actor);
    }
  champlain_label_set_text (label, text);

  return CLUTTER_ACTOR (label);
}


/**
 * champlain_label_set_text:
 * @label: a #ChamplainLabel
 * @text: The new text of the label
 *
 * Sets the label's text.
 *
 * Since: 0.10
 */
void
champlain_label_set_text (ChamplainLabel *label,
    const gchar *text)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  ChamplainLabelPrivate *priv = label->priv;

  if (priv->text != NULL)
    g_free (priv->text);

  priv->text = g_strdup (text);
  g_object_notify (G_OBJECT (label), "text");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_image:
 * @label: a #ChamplainLabel
 * @image: (allow-none): The image as a @ClutterActor or NULL to remove the current image.
 *
 * Sets the label's image.
 *
 * Since: 0.10
 */
void
champlain_label_set_image (ChamplainLabel *label,
    ClutterActor *image)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  ChamplainLabelPrivate *priv = label->priv;

  if (priv->image != NULL)
    clutter_actor_destroy (priv->image);

  if (image != NULL)
    {
      g_return_if_fail (CLUTTER_IS_ACTOR (image));
      priv->image = g_object_ref (image);
    }
  else
    priv->image = image;

  g_object_notify (G_OBJECT (label), "image");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_use_markup:
 * @label: a #ChamplainLabel
 * @use_markup: The value
 *
 * Sets if the label's text uses markup.
 *
 * Since: 0.10
 */
void
champlain_label_set_use_markup (ChamplainLabel *label,
    gboolean markup)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  label->priv->use_markup = markup;
  g_object_notify (G_OBJECT (label), "use-markup");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_alignment:
 * @label: a #ChamplainLabel
 * @alignment: The label's alignment
 *
 * Sets the label's text alignment.
 *
 * Since: 0.10
 */
void
champlain_label_set_alignment (ChamplainLabel *label,
    PangoAlignment alignment)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  label->priv->alignment = alignment;
  g_object_notify (G_OBJECT (label), "alignment");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_color:
 * @label: a #ChamplainLabel
 * @color: (allow-none): The label's background color or NULL to reset the background to the
 *         default color. The color parameter is copied.
 *
 * Sets the label's background color.
 *
 * Since: 0.10
 */
void
champlain_label_set_color (ChamplainLabel *label,
    const ClutterColor *color)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  ChamplainLabelPrivate *priv = label->priv;

  if (priv->color != NULL)
    clutter_color_free (priv->color);

  if (color == NULL)
    color = &DEFAULT_COLOR;

  priv->color = clutter_color_copy (color);
  g_object_notify (G_OBJECT (label), "color");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_text_color:
 * @label: a #ChamplainLabel
 * @color: (allow-none): The label's text color or NULL to reset the text to the default
 *         color. The color parameter is copied.
 *
 * Sets the label's text color.
 *
 * Since: 0.10
 */
void
champlain_label_set_text_color (ChamplainLabel *label,
    const ClutterColor *color)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  ChamplainLabelPrivate *priv = label->priv;

  if (priv->text_color != NULL)
    clutter_color_free (priv->text_color);

  if (color == NULL)
    color = &DEFAULT_TEXT_COLOR;

  priv->text_color = clutter_color_copy (color);
  g_object_notify (G_OBJECT (label), "text-color");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_font_name:
 * @label: a #ChamplainLabel
 * @font_name: (allow-none): The label's font name or NULL to reset the font to the default
 *             value.
 *
 * Sets the label's font name such as "Sans 12".
 *
 * Since: 0.10
 */
void
champlain_label_set_font_name (ChamplainLabel *label,
    const gchar *font_name)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  ChamplainLabelPrivate *priv = label->priv;

  if (priv->font_name != NULL)
    g_free (priv->font_name);

  if (font_name == NULL)
    font_name = DEFAULT_FONT_NAME;

  priv->font_name = g_strdup (font_name);
  g_object_notify (G_OBJECT (label), "font-name");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_wrap:
 * @label: a #ChamplainLabel
 * @wrap: The label's wrap.
 *
 * Sets if the label's text wrap.
 *
 * Since: 0.10
 */
void
champlain_label_set_wrap (ChamplainLabel *label,
    gboolean wrap)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  label->priv->wrap = wrap;
  g_object_notify (G_OBJECT (label), "wrap");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_wrap_mode:
 * @label: a #ChamplainLabel
 * @wrap_mode: The label's wrap mode.
 *
 * Sets the label's text wrap mode.
 *
 * Since: 0.10
 */
void
champlain_label_set_wrap_mode (ChamplainLabel *label,
    PangoWrapMode wrap_mode)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  label->priv->wrap_mode = wrap_mode;
  g_object_notify (G_OBJECT (label), "wrap-mode");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_attributes:
 * @label: a #ChamplainLabel
 * @list: The label's text attributes.
 *
 * Sets the label's text attributes.
 *
 * Since: 0.10
 */
void
champlain_label_set_attributes (ChamplainLabel *label,
    PangoAttrList *attributes)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  ChamplainLabelPrivate *priv = label->priv;

  if (attributes)
    pango_attr_list_ref (attributes);

  if (priv->attributes)
    pango_attr_list_unref (priv->attributes);

  priv->attributes = attributes;

  g_object_notify (G_OBJECT (label), "attributes");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_ellipsize:
 * @label: a #ChamplainLabel
 * @mode: The label's ellipsize mode.
 *
 * Sets the label's text ellipsize mode.
 *
 * Since: 0.10
 */
void
champlain_label_set_ellipsize (ChamplainLabel *label,
    PangoEllipsizeMode ellipsize)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  label->priv->ellipsize = ellipsize;
  g_object_notify (G_OBJECT (label), "ellipsize");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_single_line_mode:
 * @label: a #ChamplainLabel
 * @mode: The label's single line mode
 *
 * Sets if the label's text is on a single line.
 *
 * Since: 0.10
 */
void
champlain_label_set_single_line_mode (ChamplainLabel *label,
    gboolean mode)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  label->priv->single_line_mode = mode;

  g_object_notify (G_OBJECT (label), "single-line-mode");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_draw_background:
 * @label: a #ChamplainLabel
 * @background: value.
 *
 * Sets if the label has a background.
 *
 * Since: 0.10
 */
void
champlain_label_set_draw_background (ChamplainLabel *label,
    gboolean background)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  label->priv->draw_background = background;
  g_object_notify (G_OBJECT (label), "draw-background");
  champlain_label_queue_redraw (label);
}


/**
 * champlain_label_set_draw_shadow:
 * @label: a #ChamplainLabel
 * @shadow: value.
 *
 * Sets if the label's background has a shadow.
 *
 * Since: 0.12.10
 */
void
champlain_label_set_draw_shadow (ChamplainLabel *label,
    gboolean shadow)
{
  g_return_if_fail (CHAMPLAIN_IS_LABEL (label));

  label->priv->draw_shadow = shadow;
  g_object_notify (G_OBJECT (label), "draw-shadow");
  champlain_label_queue_redraw (label);
}

/**
 * champlain_label_get_image:
 * @label: a #ChamplainLabel
 *
 * Get the label's image.
 *
 * Returns: (transfer none): the label's image.
 *
 * Since: 0.10
 */
ClutterActor *
champlain_label_get_image (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), NULL);

  return label->priv->image;
}


/**
 * champlain_label_get_use_markup:
 * @label: a #ChamplainLabel
 *
 * Check whether the label uses markup.
 *
 * Returns: if the label's text contains markup.
 *
 * Since: 0.10
 */
gboolean
champlain_label_get_use_markup (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), FALSE);

  return label->priv->use_markup;
}


/**
 * champlain_label_get_text:
 * @label: a #ChamplainLabel
 *
 * Get the label's text.
 *
 * Returns: the label's text.
 *
 * Since: 0.10
 */
const gchar *
champlain_label_get_text (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), FALSE);

  return label->priv->text;
}


/**
 * champlain_label_get_alignment:
 * @label: a #ChamplainLabel
 *
 * Get the label's text alignment.
 *
 * Returns: the label's text alignment.
 *
 * Since: 0.10
 */
PangoAlignment
champlain_label_get_alignment (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), FALSE);

  return label->priv->alignment;
}


/**
 * champlain_label_get_color:
 * @label: a #ChamplainLabel
 *
 * Gets the label's background color.
 *
 * Returns: the label's background color.
 *
 * Since: 0.10
 */
ClutterColor *
champlain_label_get_color (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), NULL);

  return label->priv->color;
}


/**
 * champlain_label_get_text_color:
 * @label: a #ChamplainLabel
 *
 * Gets the label's text color.
 *
 * Returns: the label's text color.
 *
 * Since: 0.10
 */
ClutterColor *
champlain_label_get_text_color (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), NULL);

  return label->priv->text_color;
}


/**
 * champlain_label_get_font_name:
 * @label: a #ChamplainLabel
 *
 * Gets the label's font name.
 *
 * Returns: the label's font name.
 *
 * Since: 0.10
 */
const gchar *
champlain_label_get_font_name (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), FALSE);

  return label->priv->font_name;
}


/**
 * champlain_label_get_wrap:
 * @label: a #ChamplainLabel
 *
 * Checks whether the label text wraps.
 *
 * Returns: if the label's text wraps.
 *
 * Since: 0.10
 */
gboolean
champlain_label_get_wrap (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), FALSE);

  return label->priv->wrap;
}


/**
 * champlain_label_get_wrap_mode:
 * @label: a #ChamplainLabel
 *
 * Gets the label's text wrap mode.
 *
 * Returns: the label's text wrap mode.
 *
 * Since: 0.10
 */
PangoWrapMode
champlain_label_get_wrap_mode (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), FALSE);

  return label->priv->wrap_mode;
}


/**
 * champlain_label_get_ellipsize:
 * @label: a #ChamplainLabel
 *
 * Gets the label's text ellipsize mode.
 *
 * Returns: the label's text ellipsize mode.
 *
 * Since: 0.10
 */
PangoEllipsizeMode
champlain_label_get_ellipsize (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), FALSE);

  return label->priv->ellipsize;
}


/**
 * champlain_label_get_single_line_mode:
 * @label: a #ChamplainLabel
 *
 * Checks the label's single line mode.
 *
 * Returns: the label's text single line mode.
 *
 * Since: 0.10
 */
gboolean
champlain_label_get_single_line_mode (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), FALSE);

  return label->priv->single_line_mode;
}


/**
 * champlain_label_get_draw_background:
 * @label: a #ChamplainLabel
 *
 * Checks whether the label has a background.
 *
 * Returns: if the label has a background.
 *
 * Since: 0.10
 */
gboolean
champlain_label_get_draw_background (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), FALSE);

  return label->priv->draw_background;
}


/**
 * champlain_label_get_draw_shadow:
 * @label: a #ChamplainLabel
 *
 * Checks whether the label's background has a shadow.
 *
 * Returns: if the label's background has a shadow.
 *
 * Since: 0.12.10
 */
gboolean
champlain_label_get_draw_shadow (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), FALSE);

  return label->priv->draw_shadow;
}


/**
 * champlain_label_get_attributes:
 * @label: a #ChamplainLabel
 *
 * Gets the label's text attributes.
 *
 * Returns: the label's text attributes.
 *
 * Since: 0.10
 */
PangoAttrList *
champlain_label_get_attributes (ChamplainLabel *label)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LABEL (label), NULL);

  return label->priv->attributes;
}
