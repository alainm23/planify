/*
 * Copyright (C) 2008-2009 Pierre-Luc Beaudoin <pierre-luc@pierlux.com>
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
 * SECTION:gtk-champlain-embed
 * @short_description: A Gtk+ Widget that embeds a #ChamplainView
 *
 * Since #ChamplainView is a #ClutterActor, you cannot embed it directly
 * into a Gtk+ application.  This widget solves this problem.  It creates
 * the #ChamplainView for you, you can get it with
 * #gtk_champlain_embed_get_view.
 */
#include "config.h"

#include <champlain/champlain.h>

#include <gtk/gtk.h>
#include <clutter/clutter.h>
#include <clutter-gtk/clutter-gtk.h>

#include "gtk-champlain-embed.h"

#if (GTK_MAJOR_VERSION == 2 && GTK_MINOR_VERSION <= 12)
#define gtk_widget_get_window(widget) ((widget)->window)
#endif

enum
{
  /* normal signals */
  LAST_SIGNAL
};

enum
{
  PROP_0,
  PROP_VIEW
};

/* static guint gtk_champlain_embed_embed_signals[LAST_SIGNAL] = { 0, }; */

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), GTK_CHAMPLAIN_TYPE_EMBED, GtkChamplainEmbedPrivate))

struct _GtkChamplainEmbedPrivate
{
  GtkWidget *clutter_embed;
  ChamplainView *view;

  GdkCursor *cursor_hand_open;
  GdkCursor *cursor_hand_closed;

  guint width;
  guint height;
};


static void gtk_champlain_embed_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec);
static void gtk_champlain_embed_set_property (GObject *object,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec);
static void gtk_champlain_embed_finalize (GObject *object);
static void gtk_champlain_embed_dispose (GObject *object);
static void gtk_champlain_embed_class_init (GtkChamplainEmbedClass *klass);
static void gtk_champlain_embed_init (GtkChamplainEmbed *view);
static void view_size_allocated_cb (GtkWidget *widget,
    GtkAllocation *allocation,
    GtkChamplainEmbed *view);
static gboolean mouse_button_cb (GtkWidget *widget,
    GdkEventButton *event,
    GtkChamplainEmbed *view);
static void view_size_allocated_cb (GtkWidget *widget,
    GtkAllocation *allocation,
    GtkChamplainEmbed *view);
static void view_realize_cb (GtkWidget *widget,
    GtkChamplainEmbed *view);
static gboolean embed_focus_cb (GtkChamplainEmbed *embed,
    GdkEvent *event);
static gboolean stage_key_press_cb (ClutterActor *actor,
    ClutterEvent *event,
    GtkChamplainEmbed *embed);

G_DEFINE_TYPE (GtkChamplainEmbed, gtk_champlain_embed, GTK_TYPE_ALIGNMENT);

static void
gtk_champlain_embed_get_property (GObject *object,
    guint prop_id,
    GValue *value,
    GParamSpec *pspec)
{
  GtkChamplainEmbed *embed = GTK_CHAMPLAIN_EMBED (object);
  GtkChamplainEmbedPrivate *priv = embed->priv;

  switch (prop_id)
    {
    case PROP_VIEW:
      g_value_set_object (value, priv->view);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
gtk_champlain_embed_set_property (GObject *object,
    guint prop_id,
    const GValue *value,
    GParamSpec *pspec)
{
  switch (prop_id)
    {
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
    }
}


static void
gtk_champlain_embed_dispose (GObject *object)
{
  GtkChamplainEmbed *embed = GTK_CHAMPLAIN_EMBED (object);
  GtkChamplainEmbedPrivate *priv = embed->priv;

  if (priv->cursor_hand_open != NULL)
    {
#if (GTK_MAJOR_VERSION == 2)
      gdk_cursor_unref (priv->cursor_hand_open);
#else
      g_object_unref (priv->cursor_hand_open);
#endif
      priv->cursor_hand_open = NULL;
    }

  if (priv->cursor_hand_closed != NULL)
    {
#if (GTK_MAJOR_VERSION == 2)
      gdk_cursor_unref (priv->cursor_hand_closed);
#else
      g_object_unref (priv->cursor_hand_closed);
#endif
      priv->cursor_hand_closed = NULL;
    }

  G_OBJECT_CLASS (gtk_champlain_embed_parent_class)->dispose (object);
}


static void
gtk_champlain_embed_finalize (GObject *object)
{
  G_OBJECT_CLASS (gtk_champlain_embed_parent_class)->finalize (object);
}


static void
gtk_champlain_embed_class_init (GtkChamplainEmbedClass *klass)
{
  g_type_class_add_private (klass, sizeof (GtkChamplainEmbedPrivate));

  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  object_class->finalize = gtk_champlain_embed_finalize;
  object_class->dispose = gtk_champlain_embed_dispose;
  object_class->get_property = gtk_champlain_embed_get_property;
  object_class->set_property = gtk_champlain_embed_set_property;

  /**
   * GtkChamplainEmbed:champlain-view:
   *
   * The #ChamplainView to embed in the Gtk+ widget.
   *
   * Since: 0.4
   */
  g_object_class_install_property (object_class,
      PROP_VIEW,
      g_param_spec_object ("champlain-view",
          "Champlain view",
          "The ChamplainView to embed into the Gtk+ widget",
          CHAMPLAIN_TYPE_VIEW,
          G_PARAM_READABLE));
}


static void
set_view (GtkChamplainEmbed *embed,
    ChamplainView *view)
{
  GtkChamplainEmbedPrivate *priv = embed->priv;
  ClutterActor *stage;

  stage = gtk_clutter_embed_get_stage (GTK_CLUTTER_EMBED (priv->clutter_embed));

  if (priv->view != NULL)
    clutter_actor_remove_child (stage, CLUTTER_ACTOR (priv->view));

  priv->view = view;
  clutter_actor_set_size (CLUTTER_ACTOR (priv->view), priv->width, priv->height);

  clutter_actor_add_child (stage, CLUTTER_ACTOR (priv->view));
}


static void
gtk_champlain_embed_init (GtkChamplainEmbed *embed)
{
  GtkChamplainEmbedPrivate *priv = GET_PRIVATE (embed);
  ClutterActor *stage;
  GdkDisplay *display;

  embed->priv = priv;

  priv->clutter_embed = gtk_clutter_embed_new ();

  g_signal_connect (priv->clutter_embed,
      "size-allocate",
      G_CALLBACK (view_size_allocated_cb),
      embed);
  g_signal_connect (priv->clutter_embed,
      "realize",
      G_CALLBACK (view_realize_cb),
      embed);
  g_signal_connect (priv->clutter_embed,
      "button-press-event",
      G_CALLBACK (mouse_button_cb),
      embed);
  g_signal_connect (priv->clutter_embed,
      "button-release-event",
      G_CALLBACK (mouse_button_cb),
      embed);
  /* Setup cursors */
  display = gdk_display_get_default ();
  priv->cursor_hand_open = gdk_cursor_new_for_display (display, GDK_HAND1);
  priv->cursor_hand_closed = gdk_cursor_new_for_display (display, GDK_FLEUR);

  priv->view = NULL;
  set_view (embed, CHAMPLAIN_VIEW (champlain_view_new ()));

  /* Setup focus/key-press events */
  g_signal_connect (embed, "focus-in-event",
                    G_CALLBACK (embed_focus_cb),
                    NULL);
  stage = gtk_clutter_embed_get_stage (GTK_CLUTTER_EMBED (priv->clutter_embed));
  g_signal_connect (stage, "key-press-event",
                    G_CALLBACK (stage_key_press_cb),
                    embed);
  gtk_widget_set_can_focus (GTK_WIDGET (embed), TRUE);

  gtk_container_add (GTK_CONTAINER (embed), priv->clutter_embed);
}


#if (GTK_MAJOR_VERSION == 2)
static void
gdk_to_clutter_color (GdkColor *gdk_color,
    ClutterColor *color)
{
  color->red = CLAMP ((gdk_color->red / 65535.0) * 255, 0, 255);
  color->green = CLAMP ((gdk_color->green / 65535.0) * 255, 0, 255);
  color->blue = CLAMP ((gdk_color->blue / 65535.0) * 255, 0, 255);
  color->alpha = 255;
}
#else
static void
gdk_rgba_to_clutter_color (GdkRGBA *gdk_rgba_color,
    ClutterColor *color)
{
  color->red = CLAMP (gdk_rgba_color->red * 255, 0, 255);
  color->green = CLAMP (gdk_rgba_color->green * 255, 0, 255);
  color->blue = CLAMP (gdk_rgba_color->blue * 255, 0, 255);
  color->alpha = CLAMP (gdk_rgba_color->alpha * 255, 0, 255);
}
#endif


static void
view_realize_cb (GtkWidget *widget,
    GtkChamplainEmbed *view)
{
  ClutterColor color = { 0, 0, 0, };
  GtkChamplainEmbedPrivate *priv = view->priv;

#if (GTK_MAJOR_VERSION == 2)
  GtkStyle *style;

  /* Set selection color */
  style = gtk_widget_get_style (widget);

  gdk_to_clutter_color (&style->text[GTK_STATE_SELECTED], &color);
  if (color.alpha == 0 && color.red == 0 && color.green == 0 && color.blue == 0)
    {
      color.red = 255;
      color.green = 255;
      color.blue = 255;
    }
  champlain_marker_set_selection_text_color (&color);

  gdk_to_clutter_color (&style->bg[GTK_STATE_SELECTED], &color);
  if (color.alpha == 0)
    color.alpha = 255;
  if (color.red == 0 && color.green == 0 && color.blue == 0)
    {
      color.red = 75;
      color.green = 105;
      color.blue = 131;
    }
  champlain_marker_set_selection_color (&color);
#else
  GtkStyleContext *style;
  GdkRGBA gdk_rgba_color;

  /* Set selection color */
  style = gtk_widget_get_style_context (widget);
  gtk_style_context_save (style);
  gtk_style_context_set_state (style, GTK_STATE_FLAG_SELECTED);

  gtk_style_context_get_color (style, gtk_style_context_get_state (style),
                               &gdk_rgba_color);
  gdk_rgba_to_clutter_color (&gdk_rgba_color, &color);
  if (color.alpha == 0 && color.red == 0 && color.green == 0 && color.blue == 0)
    {
      color.red = 255;
      color.green = 255;
      color.blue = 255;
    }
  champlain_marker_set_selection_text_color (&color);

  gtk_style_context_get_background_color (style, gtk_style_context_get_state (style),
                                          &gdk_rgba_color);
  gdk_rgba_to_clutter_color (&gdk_rgba_color, &color);
  if (color.alpha == 0)
    color.alpha = 255;
  if (color.red == 0 && color.green == 0 && color.blue == 0)
    {
      color.red = 75;
      color.green = 105;
      color.blue = 131;
    }
  champlain_marker_set_selection_color (&color);

  gtk_style_context_restore (style);
#endif

  /* Setup mouse cursor to a hand */
  gdk_window_set_cursor (gtk_widget_get_window (priv->clutter_embed), priv->cursor_hand_open);
}


static void
view_size_allocated_cb (GtkWidget *widget,
    GtkAllocation *allocation,
    GtkChamplainEmbed *view)
{
  GtkChamplainEmbedPrivate *priv = view->priv;

  if (priv->view != NULL)
    clutter_actor_set_size (CLUTTER_ACTOR (priv->view), allocation->width, allocation->height);

  priv->width = allocation->width;
  priv->height = allocation->height;
}


static gboolean
mouse_button_cb (GtkWidget *widget,
    GdkEventButton *event,
    GtkChamplainEmbed *view)
{
  GtkChamplainEmbedPrivate *priv = view->priv;

  if (event->type == GDK_BUTTON_PRESS)
    gdk_window_set_cursor (gtk_widget_get_window (priv->clutter_embed),
        priv->cursor_hand_closed);
  else
    gdk_window_set_cursor (gtk_widget_get_window (priv->clutter_embed),
        priv->cursor_hand_open);

  return FALSE;
}

static gboolean
embed_focus_cb (GtkChamplainEmbed *embed,
    GdkEvent *event)
{
  GtkChamplainEmbedPrivate *priv = embed->priv;

  gtk_widget_grab_focus (priv->clutter_embed);
  return TRUE;
}

static gboolean
stage_key_press_cb (ClutterActor *actor,
    ClutterEvent *event,
    GtkChamplainEmbed *embed)
{
  ChamplainView *view = gtk_champlain_embed_get_view (embed);

  clutter_actor_event (CLUTTER_ACTOR (view), event, FALSE);
  return TRUE;
}

/**
 * gtk_champlain_embed_new:
 *
 * Creates an instance of #GtkChamplainEmbed.
 *
 * Return value: a new #GtkChamplainEmbed ready to be used as a #GtkWidget.
 *
 * Since: 0.4
 */
GtkWidget *
gtk_champlain_embed_new ()
{
  return g_object_new (GTK_CHAMPLAIN_TYPE_EMBED, NULL);
}


/**
 * gtk_champlain_embed_get_view:
 * @embed: a #ChamplainView, the map view to embed
 *
 * Gets a #ChamplainView from the #GtkChamplainEmbed object.
 *
 * Return value: (transfer none): a #ChamplainView ready to be used
 *
 * Since: 0.4
 */
ChamplainView *
gtk_champlain_embed_get_view (GtkChamplainEmbed *embed)
{
  g_return_val_if_fail (GTK_CHAMPLAIN_IS_EMBED (embed), NULL);

  GtkChamplainEmbedPrivate *priv = embed->priv;
  return priv->view;
}
