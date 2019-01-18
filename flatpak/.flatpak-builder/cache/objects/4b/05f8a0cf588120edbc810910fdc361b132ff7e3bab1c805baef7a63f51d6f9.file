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
 * SECTION:champlain-layer
 * @short_description: Base class of libchamplain layers
 *
 * Every layer (overlay that moves together with the map) has to inherit this
 * class and implement its virtual methods.
 */

#include "champlain-layer.h"

G_DEFINE_ABSTRACT_TYPE (ChamplainLayer, champlain_layer, CLUTTER_TYPE_ACTOR)

static void
champlain_layer_dispose (GObject *object)
{
  G_OBJECT_CLASS (champlain_layer_parent_class)->dispose (object);
}


static void
champlain_layer_finalize (GObject *object)
{
  G_OBJECT_CLASS (champlain_layer_parent_class)->finalize (object);
}


static void
champlain_layer_class_init (ChamplainLayerClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);

  object_class->finalize = champlain_layer_finalize;
  object_class->dispose = champlain_layer_dispose;

  klass->set_view = NULL;
  klass->get_bounding_box = NULL;
}


/**
 * champlain_layer_set_view:
 * @layer: a #ChamplainLayer
 * @view: a #ChamplainView
 *
 * #ChamplainView calls this method to pass a reference to itself to the layer
 * when the layer is added to the view. When the layer is removed from the
 * view, it passes NULL to the layer. Custom layers can implement this method
 * and perform the necessary initialization. This method should not be called
 * by user code.
 *
 * Since: 0.10
 */
void
champlain_layer_set_view (ChamplainLayer *layer,
    ChamplainView *view)
{
  g_return_if_fail (CHAMPLAIN_IS_LAYER (layer));

  CHAMPLAIN_LAYER_GET_CLASS (layer)->set_view (layer, view);
}


/**
 * champlain_layer_get_bounding_box:
 * @layer: a #ChamplainLayer
 *
 * Gets the bounding box occupied by the elements inside the layer.
 *
 * Returns: The bounding box.
 *
 * Since: 0.10
 */
ChamplainBoundingBox *
champlain_layer_get_bounding_box (ChamplainLayer *layer)
{
  g_return_val_if_fail (CHAMPLAIN_IS_LAYER (layer), NULL);

  return CHAMPLAIN_LAYER_GET_CLASS (layer)->get_bounding_box (layer);
}


static void
champlain_layer_init (ChamplainLayer *self)
{
}
