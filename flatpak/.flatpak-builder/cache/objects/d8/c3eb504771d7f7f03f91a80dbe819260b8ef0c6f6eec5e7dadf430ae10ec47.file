/*
 * Copyright (C) 2015 Jonas Danielsson
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
 * License along with this library; if not, see <http://www.gnu.org/licenses/>.
 */
 /**
 * SECTION:champlain-exportable
 * @short_description: An interface for objects exportable to a cairo surface
 *
 * By implementing #ChamplainExportable the object declares that it has a cairo
 * surface (#cairo_surface_t) representation of it self.
 */

#include "champlain-exportable.h"
#include "champlain-private.h"

#include <cairo-gobject.h>

typedef ChamplainExportableIface ChamplainExportableInterface;

G_DEFINE_INTERFACE (ChamplainExportable, champlain_exportable, G_TYPE_OBJECT);


static void
champlain_exportable_default_init (ChamplainExportableInterface *iface)
{
  /**
   * ChamplainExportable:surface:
   *
   * A #cairo_surface_t representation
   *
   * Since: 0.12.12
   */
  g_object_interface_install_property (iface,
      g_param_spec_boxed ("surface",
          "Surface",
          "Cairo surface representaion",
          CAIRO_GOBJECT_TYPE_SURFACE,
          G_PARAM_READWRITE));
}


/**
 * champlain_exportable_set_surface:
 * @exportable: the #ChamplainExportable
 * @surface: the #cairo_surface_t
 *
 * Set a #cairo_surface_t to be associated with this tile.
 *
 * Since: 0.12.12
 */
void
champlain_exportable_set_surface (ChamplainExportable *exportable,
    cairo_surface_t     *surface)
{
  g_return_if_fail (CHAMPLAIN_EXPORTABLE (exportable));
  g_return_if_fail (surface != NULL);

  CHAMPLAIN_EXPORTABLE_GET_IFACE (exportable)->set_surface (exportable, surface);
}


/**
 * champlain_exportable_get_surface:
 * @exportable: a #ChamplainExportable
 *
 * Gets the surface
 *
 * Returns: (transfer none): the #cairo_surface_t of the object
 *
 * Since: 0.12.12
 */
cairo_surface_t *
champlain_exportable_get_surface (ChamplainExportable *exportable)
{
  return CHAMPLAIN_EXPORTABLE_GET_IFACE (exportable)->get_surface (exportable);
}
