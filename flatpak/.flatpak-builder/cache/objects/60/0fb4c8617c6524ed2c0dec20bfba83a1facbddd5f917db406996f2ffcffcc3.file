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

#ifndef CHAMPLAIN_COORDINATE_H
#define CHAMPLAIN_COORDINATE_H

#include <champlain/champlain-defines.h>
#include <champlain/champlain-location.h>

#include <glib-object.h>

G_BEGIN_DECLS

#define CHAMPLAIN_TYPE_COORDINATE champlain_coordinate_get_type ()

#define CHAMPLAIN_COORDINATE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), CHAMPLAIN_TYPE_COORDINATE, ChamplainCoordinate))

#define CHAMPLAIN_COORDINATE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), CHAMPLAIN_TYPE_COORDINATE, ChamplainCoordinateClass))

#define CHAMPLAIN_IS_COORDINATE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), CHAMPLAIN_TYPE_COORDINATE))

#define CHAMPLAIN_IS_COORDINATE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), CHAMPLAIN_TYPE_COORDINATE))

#define CHAMPLAIN_COORDINATE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), CHAMPLAIN_TYPE_COORDINATE, ChamplainCoordinateClass))

typedef struct _ChamplainCoordinatePrivate ChamplainCoordinatePrivate;

typedef struct _ChamplainCoordinate ChamplainCoordinate;
typedef struct _ChamplainCoordinateClass ChamplainCoordinateClass;


/**
 * ChamplainCoordinate:
 *
 * The #ChamplainCoordinate structure contains only private data
 * and should be accessed using the provided API
 *
 * Since: 0.10
 */
struct _ChamplainCoordinate
{
  GInitiallyUnowned parent;

  ChamplainCoordinatePrivate *priv;
};

struct _ChamplainCoordinateClass
{
  GInitiallyUnownedClass parent_class;
};

GType champlain_coordinate_get_type (void);

ChamplainCoordinate *champlain_coordinate_new (void);

ChamplainCoordinate *champlain_coordinate_new_full (gdouble latitude,
    gdouble longitude);

G_END_DECLS

#endif
