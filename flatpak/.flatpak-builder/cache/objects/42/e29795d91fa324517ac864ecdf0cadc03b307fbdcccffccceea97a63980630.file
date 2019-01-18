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

#ifndef __CHAMPLAIN_LOCATION_H__
#define __CHAMPLAIN_LOCATION_H__

#include <glib-object.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_LOCATION (champlain_location_get_type ())

#define CHAMPLAIN_LOCATION(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_LOCATION, ChamplainLocation))

#define CHAMPLAIN_IS_LOCATION(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_LOCATION))

#define CHAMPLAIN_LOCATION_GET_IFACE(inst) \
  (G_TYPE_INSTANCE_GET_INTERFACE ((inst), CHAMPLAIN_TYPE_LOCATION, ChamplainLocationIface))

typedef struct _ChamplainLocation ChamplainLocation; /* Dummy object */
typedef struct _ChamplainLocationIface ChamplainLocationIface;

/**
 * ChamplainLocation:
 *
 * An interface common to objects having latitude and longitude.
 */

/**
 * ChamplainLocationIface:
 * @get_latitude: virtual function for obtaining latitude.
 * @get_longitude: virtual function for obtaining longitude.
 * @set_location: virtual function for setting position.
 *
 * An interface common to objects having latitude and longitude.
 */
struct _ChamplainLocationIface
{
  /*< private >*/
  GTypeInterface g_iface;

  /*< public >*/
  gdouble (*get_latitude)(ChamplainLocation *location);
  gdouble (*get_longitude)(ChamplainLocation *location);
  void (*set_location)(ChamplainLocation *location,
      gdouble latitude,
      gdouble longitude);
};

GType champlain_location_get_type (void) G_GNUC_CONST;

void champlain_location_set_location (ChamplainLocation *location,
    gdouble latitude,
    gdouble longitude);
gdouble champlain_location_get_latitude (ChamplainLocation *location);
gdouble champlain_location_get_longitude (ChamplainLocation *location);

G_END_DECLS

#endif /* __CHAMPLAIN_LOCATION_H__ */
