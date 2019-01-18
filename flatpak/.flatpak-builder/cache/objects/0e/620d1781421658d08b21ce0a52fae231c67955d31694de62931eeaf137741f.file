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

#ifndef CHAMPLAIN_MARKER_H
#define CHAMPLAIN_MARKER_H

#include <champlain/champlain-defines.h>
#include <champlain/champlain-location.h>

#include <glib-object.h>
#include <clutter/clutter.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_MARKER champlain_marker_get_type ()

#define CHAMPLAIN_MARKER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_MARKER, ChamplainMarker))

#define CHAMPLAIN_MARKER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_MARKER, ChamplainMarkerClass))

#define CHAMPLAIN_IS_MARKER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_MARKER))

#define CHAMPLAIN_IS_MARKER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_MARKER))

#define CHAMPLAIN_MARKER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_MARKER, ChamplainMarkerClass))

typedef struct _ChamplainMarkerPrivate ChamplainMarkerPrivate;

typedef struct _ChamplainMarker ChamplainMarker;
typedef struct _ChamplainMarkerClass ChamplainMarkerClass;


/**
 * ChamplainMarker:
 *
 * The #ChamplainMarker structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.10
 */
struct _ChamplainMarker
{
  ClutterActor parent;

  ChamplainMarkerPrivate *priv;
};

struct _ChamplainMarkerClass
{
  ClutterActorClass parent_class;
};

GType champlain_marker_get_type (void);


ClutterActor *champlain_marker_new (void);

void champlain_marker_set_selectable (ChamplainMarker *marker,
    gboolean value);
gboolean champlain_marker_get_selectable (ChamplainMarker *marker);

void champlain_marker_set_draggable (ChamplainMarker *marker,
    gboolean value);
gboolean champlain_marker_get_draggable (ChamplainMarker *marker);

void champlain_marker_set_selected (ChamplainMarker *marker,
    gboolean value);
gboolean champlain_marker_get_selected (ChamplainMarker *marker);

void champlain_marker_animate_in (ChamplainMarker *marker);
void champlain_marker_animate_in_with_delay (ChamplainMarker *marker,
    guint delay);
void champlain_marker_animate_out (ChamplainMarker *marker);
void champlain_marker_animate_out_with_delay (ChamplainMarker *marker,
    guint delay);

void champlain_marker_set_selection_color (ClutterColor *color);
const ClutterColor *champlain_marker_get_selection_color (void);

void champlain_marker_set_selection_text_color (ClutterColor *color);
const ClutterColor *champlain_marker_get_selection_text_color (void);

G_END_DECLS

#endif
