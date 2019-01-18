/*
 * gtypes.h - Specialized GTypes representing D-Bus structs etc.
 * Copyright (C) 2007 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2007 Nokia Corporation
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

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_GTYPES_H__
#define __TP_GTYPES_H__

#include <dbus/dbus-glib.h>

G_BEGIN_DECLS

#include <telepathy-glib/_gen/gtypes.h>

#define TP_ARRAY_TYPE_OBJECT_PATH_LIST (tp_type_dbus_array_of_o ())
#define TP_ARRAY_TYPE_UCHAR_ARRAY_LIST (tp_type_dbus_array_of_ay ())
#define TP_TYPE_UCHAR_ARRAY (tp_type_dbus_array_of_y ())

GType tp_type_dbus_array_of_o (void);
GType tp_type_dbus_array_of_y (void);
GType tp_type_dbus_array_of_ay (void);

GValue *tp_dbus_specialized_value_slice_new (GType type);

G_END_DECLS

#endif
