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

#if !defined (__CHAMPLAIN_CHAMPLAIN_H_INSIDE__) && !defined (CHAMPLAIN_COMPILATION)
#error "Only <champlain/champlain.h> can be included directly."
#endif

#ifndef __CHAMPLAIN_EXPORTABLE_H__
#define __CHAMPLAIN_EXPORTABLE_H__

#include <glib-object.h>
#include <cairo.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_EXPORTABLE (champlain_exportable_get_type ())

#define CHAMPLAIN_EXPORTABLE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_EXPORTABLE, ChamplainExportable))

#define CHAMPLAIN_IS_EXPORTABLE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_EXPORTABLE))

#define CHAMPLAIN_EXPORTABLE_GET_IFACE(inst) \
  (G_TYPE_INSTANCE_GET_INTERFACE ((inst), CHAMPLAIN_TYPE_EXPORTABLE, ChamplainExportableIface))

typedef struct _ChamplainExportable ChamplainExportable; /* Dummy object */
typedef struct _ChamplainExportableIface ChamplainExportableIface;

/**
 * ChamplainExportable:
 *
 * An interface common to objects having a #cairo_surface_t representation.
 */

/**
 * ChamplainExportableIface:
 * @get_surface: virtual function for obtaining the cairo surface.
 * @set_surface: virtual function for setting a cairo surface.
 *
 * An interface common to objects having a #cairo_surface_t representation.
 */
struct _ChamplainExportableIface
{
  /*< private >*/
  GTypeInterface g_iface;

  /*< public >*/
  cairo_surface_t *(*get_surface)(ChamplainExportable *exportable);
  void (*set_surface)(ChamplainExportable *exportable,
      cairo_surface_t *surface);
};

GType champlain_exportable_get_type (void) G_GNUC_CONST;

void champlain_exportable_set_surface (ChamplainExportable *exportable,
    cairo_surface_t *surface);
cairo_surface_t * champlain_exportable_get_surface (ChamplainExportable *exportable);

G_END_DECLS

#endif /* __CHAMPLAIN_EXPORTABLE_H__ */
