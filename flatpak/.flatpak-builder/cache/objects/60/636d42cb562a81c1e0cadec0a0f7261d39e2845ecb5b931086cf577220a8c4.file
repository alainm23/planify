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
 * SECTION:champlain-custom-marker
 * @short_description: A marker implementing the
 * #ClutterContainer interface. Deprecated.
 *
 * A marker implementing the #ClutterContainer interface. You can insert
 * your custom actors into the container. Don't forget to set the marker's
 * pointer position using #clutter_actor_set_translation.
 */

#include "config.h"

#include "champlain.h"
#include "champlain-defines.h"
#include "champlain-marshal.h"
#include "champlain-private.h"

#include <clutter/clutter.h>
#include <glib.h>
#include <glib-object.h>


enum
{
  /* normal signals */
  LAST_SIGNAL
};

enum
{
  PROP_0,
};

struct _ChamplainCustomMarkerPrivate
{
  ClutterContainer *dummy;
};

G_DEFINE_TYPE (ChamplainCustomMarker, champlain_custom_marker, CHAMPLAIN_TYPE_MARKER)

#define GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((obj), CHAMPLAIN_TYPE_CUSTOM_MARKER, ChamplainCustomMarkerPrivate))


static void
champlain_custom_marker_class_init (ChamplainCustomMarkerClass *klass)
{
  g_type_class_add_private (klass, sizeof (ChamplainCustomMarkerPrivate));
}


static void
champlain_custom_marker_init (ChamplainCustomMarker *custom_marker)
{
}


/**
 * champlain_custom_marker_new:
 *
 * Creates an instance of #ChamplainCustomMarker.
 *
 * Returns: a new #ChamplainCustomMarker.
 *
 * Since: 0.10
 * 
 * Deprecated: 0.12.4: #ChamplainMarker is a concrete class now and can be used
 * instead.
 */
ClutterActor *
champlain_custom_marker_new (void)
{
  return CLUTTER_ACTOR (g_object_new (CHAMPLAIN_TYPE_CUSTOM_MARKER, NULL));
}
