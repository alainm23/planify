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

#ifndef CHAMPLAIN_LABEL_H
#define CHAMPLAIN_LABEL_H

#include <champlain/champlain-marker.h>

#include <glib-object.h>
#include <clutter/clutter.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_LABEL champlain_label_get_type ()

#define CHAMPLAIN_LABEL(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_LABEL, ChamplainLabel))

#define CHAMPLAIN_LABEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_LABEL, ChamplainLabelClass))

#define CHAMPLAIN_IS_LABEL(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_LABEL))

#define CHAMPLAIN_IS_LABEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_LABEL))

#define CHAMPLAIN_LABEL_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_LABEL, ChamplainLabelClass))

typedef struct _ChamplainLabelPrivate ChamplainLabelPrivate;

typedef struct _ChamplainLabel ChamplainLabel;
typedef struct _ChamplainLabelClass ChamplainLabelClass;

/**
 * ChamplainLabel:
 *
 * The #ChamplainLabel structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.10
 */
struct _ChamplainLabel
{
  ChamplainMarker parent;

  ChamplainLabelPrivate *priv;
};

struct _ChamplainLabelClass
{
  ChamplainMarkerClass parent_class;
};

GType champlain_label_get_type (void);

ClutterActor *champlain_label_new (void);

ClutterActor *champlain_label_new_with_text (const gchar *text,
    const gchar *font,
    ClutterColor *text_color,
    ClutterColor *label_color);

ClutterActor *champlain_label_new_with_image (ClutterActor *actor);

ClutterActor *champlain_label_new_from_file (const gchar *filename,
    GError **error);

ClutterActor *champlain_label_new_full (const gchar *text,
    ClutterActor *actor);

void champlain_label_set_text (ChamplainLabel *label,
    const gchar *text);
void champlain_label_set_image (ChamplainLabel *label,
    ClutterActor *image);
void champlain_label_set_use_markup (ChamplainLabel *label,
    gboolean use_markup);
void champlain_label_set_alignment (ChamplainLabel *label,
    PangoAlignment alignment);
void champlain_label_set_color (ChamplainLabel *label,
    const ClutterColor *color);
void champlain_label_set_text_color (ChamplainLabel *label,
    const ClutterColor *color);
void champlain_label_set_font_name (ChamplainLabel *label,
    const gchar *font_name);
void champlain_label_set_wrap (ChamplainLabel *label,
    gboolean wrap);
void champlain_label_set_wrap_mode (ChamplainLabel *label,
    PangoWrapMode wrap_mode);
void champlain_label_set_attributes (ChamplainLabel *label,
    PangoAttrList *list);
void champlain_label_set_single_line_mode (ChamplainLabel *label,
    gboolean mode);
void champlain_label_set_ellipsize (ChamplainLabel *label,
    PangoEllipsizeMode mode);
void champlain_label_set_draw_background (ChamplainLabel *label,
    gboolean background);
void champlain_label_set_draw_shadow (ChamplainLabel *label,
    gboolean shadow);

gboolean champlain_label_get_use_markup (ChamplainLabel *label);
const gchar *champlain_label_get_text (ChamplainLabel *label);
ClutterActor *champlain_label_get_image (ChamplainLabel *label);
PangoAlignment champlain_label_get_alignment (ChamplainLabel *label);
ClutterColor *champlain_label_get_color (ChamplainLabel *label);
ClutterColor *champlain_label_get_text_color (ChamplainLabel *label);
const gchar *champlain_label_get_font_name (ChamplainLabel *label);
gboolean champlain_label_get_wrap (ChamplainLabel *label);
PangoWrapMode champlain_label_get_wrap_mode (ChamplainLabel *label);
PangoEllipsizeMode champlain_label_get_ellipsize (ChamplainLabel *label);
gboolean champlain_label_get_single_line_mode (ChamplainLabel *label);
gboolean champlain_label_get_draw_background (ChamplainLabel *label);
gboolean champlain_label_get_draw_shadow (ChamplainLabel *label);
PangoAttrList *champlain_label_get_attributes (ChamplainLabel *label);


G_END_DECLS

#endif
