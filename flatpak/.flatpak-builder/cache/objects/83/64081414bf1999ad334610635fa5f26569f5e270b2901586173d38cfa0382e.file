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

#if !defined (__CHAMPLAIN_CHAMPLAIN_H_INSIDE__) && !defined (CHAMPLAIN_COMPILATION)
#error "Only <champlain/champlain.h> can be included directly."
#endif

#ifndef CHAMPLAIN_CUSTOM_MARKER_H
#define CHAMPLAIN_CUSTOM_MARKER_H

#include <champlain/champlain-marker.h>

#include <glib-object.h>
#include <clutter/clutter.h>

G_BEGIN_DECLS

#ifndef GTK_DISABLE_DEPRECATED

#define CHAMPLAIN_TYPE_CUSTOM_MARKER champlain_custom_marker_get_type ()

#define CHAMPLAIN_CUSTOM_MARKER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_CUSTOM_MARKER, ChamplainCustomMarker))

#define CHAMPLAIN_CUSTOM_MARKER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_CUSTOM_MARKER, ChamplainCustomMarkerClass))

#define CHAMPLAIN_IS_CUSTOM_MARKER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_CUSTOM_MARKER))

#define CHAMPLAIN_IS_CUSTOM_MARKER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_CUSTOM_MARKER))

#define CHAMPLAIN_CUSTOM_MARKER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_CUSTOM_MARKER, ChamplainCustomMarkerClass))

typedef struct _ChamplainCustomMarkerPrivate ChamplainCustomMarkerPrivate;

typedef struct _ChamplainCustomMarker ChamplainCustomMarker;
typedef struct _ChamplainCustomMarkerClass ChamplainCustomMarkerClass;

/**
 * ChamplainCustomMarker:
 *
 * The #ChamplainCustomMarker structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.10
 * 
 * Deprecated: 0.12.4: #ChamplainMarker is a concrete class now and can be used
 * instead.
 */
struct _ChamplainCustomMarker
{
  ChamplainMarker parent;

  ChamplainCustomMarkerPrivate *priv;
};

struct _ChamplainCustomMarkerClass
{
  ChamplainMarkerClass parent_class;
};

GType champlain_custom_marker_get_type (void);

ClutterActor *champlain_custom_marker_new (void);

#endif

G_END_DECLS

#endif
