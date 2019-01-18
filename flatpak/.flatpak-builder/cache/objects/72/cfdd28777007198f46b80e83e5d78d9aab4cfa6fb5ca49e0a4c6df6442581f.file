/*
 * Copyright (C) 2008 Pierre-Luc Beaudoin <pierre-luc@pierlux.com>
 * Copyright (C) 2010-2013 Jiri Techet <techet@gmail.com>
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

#ifndef CHAMPLAIN_VIEW_H
#define CHAMPLAIN_VIEW_H

#include <champlain/champlain-defines.h>
#include <champlain/champlain-layer.h>
#include <champlain/champlain-map-source.h>
#include <champlain/champlain-license.h>
#include <champlain/champlain-bounding-box.h>

#include <glib.h>
#include <glib-object.h>
#include <clutter/clutter.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_VIEW champlain_view_get_type ()

#define CHAMPLAIN_VIEW(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_VIEW, ChamplainView))

#define CHAMPLAIN_VIEW_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_VIEW, ChamplainViewClass))

#define CHAMPLAIN_IS_VIEW(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_VIEW))

#define CHAMPLAIN_IS_VIEW_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_VIEW))

#define CHAMPLAIN_VIEW_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_VIEW, ChamplainViewClass))

typedef struct _ChamplainViewPrivate ChamplainViewPrivate;


/**
 * ChamplainView:
 *
 * The #ChamplainView structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.1
 */
struct _ChamplainView
{
  ClutterActor parent;

  ChamplainViewPrivate *priv;
};

struct _ChamplainViewClass
{
  ClutterActorClass parent_class;
};

GType champlain_view_get_type (void);

ClutterActor *champlain_view_new (void);

void champlain_view_center_on (ChamplainView *view,
    gdouble latitude,
    gdouble longitude);
void champlain_view_go_to (ChamplainView *view,
    gdouble latitude,
    gdouble longitude);
void champlain_view_stop_go_to (ChamplainView *view);
gdouble champlain_view_get_center_latitude (ChamplainView *view);
gdouble champlain_view_get_center_longitude (ChamplainView *view);

void champlain_view_zoom_in (ChamplainView *view);
void champlain_view_zoom_out (ChamplainView *view);
void champlain_view_set_zoom_level (ChamplainView *view,
    guint zoom_level);
void champlain_view_set_min_zoom_level (ChamplainView *view,
    guint zoom_level);
void champlain_view_set_max_zoom_level (ChamplainView *view,
    guint zoom_level);

void champlain_view_ensure_visible (ChamplainView *view,
    ChamplainBoundingBox *bbox,
    gboolean animate);
void champlain_view_ensure_layers_visible (ChamplainView *view,
    gboolean animate);

void champlain_view_set_map_source (ChamplainView *view,
    ChamplainMapSource *map_source);
void champlain_view_add_overlay_source (ChamplainView *view,
    ChamplainMapSource *map_source,
    guint8 opacity);
void champlain_view_remove_overlay_source (ChamplainView *view,
    ChamplainMapSource *map_source);
GList *champlain_view_get_overlay_sources (ChamplainView *view);

void champlain_view_set_deceleration (ChamplainView *view,
    gdouble rate);
void champlain_view_set_kinetic_mode (ChamplainView *view,
    gboolean kinetic);
void champlain_view_set_keep_center_on_resize (ChamplainView *view,
    gboolean value);
void champlain_view_set_zoom_on_double_click (ChamplainView *view,
    gboolean value);
void champlain_view_set_animate_zoom (ChamplainView *view,
    gboolean value);
void champlain_view_set_background_pattern (ChamplainView *view,
    ClutterContent *background);
void champlain_view_set_world (ChamplainView *view,
    ChamplainBoundingBox *bbox);
void champlain_view_set_horizontal_wrap (ChamplainView *view,
    gboolean wrap);
void champlain_view_add_layer (ChamplainView *view,
    ChamplainLayer *layer);
void champlain_view_remove_layer (ChamplainView *view,
    ChamplainLayer *layer);
cairo_surface_t * champlain_view_to_surface (ChamplainView *view,
    gboolean include_layers);

guint champlain_view_get_zoom_level (ChamplainView *view);
guint champlain_view_get_min_zoom_level (ChamplainView *view);
guint champlain_view_get_max_zoom_level (ChamplainView *view);
ChamplainMapSource *champlain_view_get_map_source (ChamplainView *view);
gdouble champlain_view_get_deceleration (ChamplainView *view);
gboolean champlain_view_get_kinetic_mode (ChamplainView *view);
gboolean champlain_view_get_keep_center_on_resize (ChamplainView *view);
gboolean champlain_view_get_zoom_on_double_click (ChamplainView *view);
gboolean champlain_view_get_animate_zoom (ChamplainView *view);
ChamplainState champlain_view_get_state (ChamplainView *view);
ClutterContent *champlain_view_get_background_pattern (ChamplainView *view);
ChamplainBoundingBox *champlain_view_get_world (ChamplainView *view);
gboolean champlain_view_get_horizontal_wrap (ChamplainView *view);

void champlain_view_reload_tiles (ChamplainView *view);

gdouble champlain_view_x_to_longitude (ChamplainView *view,
    gdouble x);
gdouble champlain_view_y_to_latitude (ChamplainView *view,
    gdouble y);
gdouble champlain_view_longitude_to_x (ChamplainView *view,
    gdouble longitude);
gdouble champlain_view_latitude_to_y (ChamplainView *view,
    gdouble latitude);

void champlain_view_get_viewport_anchor (ChamplainView *view,
    gint *anchor_x,
    gint *anchor_y);
void champlain_view_get_viewport_origin (ChamplainView *view,
    gint *x,
    gint *y);

#ifndef GTK_DISABLE_DEPRECATED
void champlain_view_bin_layout_add (ChamplainView *view,
    ClutterActor *child,
    ClutterBinAlignment x_align,
    ClutterBinAlignment y_align);
#endif
ChamplainLicense *champlain_view_get_license_actor (ChamplainView *view);

ChamplainBoundingBox *champlain_view_get_bounding_box (ChamplainView *view);
ChamplainBoundingBox *champlain_view_get_bounding_box_for_zoom_level (ChamplainView *view,
    guint zoom_level);

G_END_DECLS

#endif
