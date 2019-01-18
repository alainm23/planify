/*
 * gtypes.c - Specialized GTypes representing D-Bus structs etc.
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

#include "config.h"

#include <telepathy-glib/gtypes.h>

#include <telepathy-glib/util.h>

/**
 * SECTION:gtypes
 * @title: GType factory functions
 * @short_description: Macros using caching factory functions to get
 *    dbus-glib specialized GTypes
 *
 * dbus-glib's built-in factory functions for specialized GTypes need to do
 * a fair amount of parsing on their arguments, so these macros are provided
 * to avoid that. Each macro expands to a call to a function which caches
 * the GType, so it only ever has to call into dbus-glib once.
 *
 * tp_dbus_specialized_value_slice_new() is also provided.
 *
 * Since: 0.7.0
 */

/**
 * TP_ARRAY_TYPE_OBJECT_PATH_LIST:
 *
 * Expands to a call to a function
 * that returns the #GType of a #GPtrArray
 * of DBUS_TYPE_G_OBJECT_PATH.
 *
 * Since: 0.7.34
 */

GType
tp_type_dbus_array_of_o (void)
{
  static GType t = 0;

  if (G_UNLIKELY (t == 0))
    t = dbus_g_type_get_collection ("GPtrArray", DBUS_TYPE_G_OBJECT_PATH);

  return t;
}

/**
 * tp_dbus_specialized_value_slice_new:
 * @type: A D-Bus specialized type (i.e. probably a specialized GValueArray
 * representing a D-Bus struct)
 *
 * <!-- -->
 *
 * Returns: a slice-allocated GValue containing an empty value of the
 * given type.
 */
GValue *
tp_dbus_specialized_value_slice_new (GType type)
{
  GValue *value = tp_g_value_slice_new (type);

  g_value_take_boxed (value, dbus_g_type_specialized_construct (type));
  return value;
}

/**
 * TP_TYPE_UCHAR_ARRAY:
 *
 * Expands to a call to a function
 * that returns the #GType of a #GArray
 * of %G_TYPE_UCHAR, i.e. the same thing as %DBUS_TYPE_G_UCHAR_ARRAY
 *
 * This is the type used in dbus-glib to represent a byte array, signature
 * 'ay'. (Note that the #GByteArray type is not used with dbus-glib.)
 *
 * Since: 0.11.1
 */

GType
tp_type_dbus_array_of_y (void)
{
  static GType t = 0;

  if (G_UNLIKELY (t == 0))
    t = DBUS_TYPE_G_UCHAR_ARRAY;

  return t;
}

/**
 * TP_ARRAY_TYPE_UCHAR_ARRAY_LIST:
 *
 * Expands to a call to a function
 * that returns the #GType of a #GPtrArray of %TP_TYPE_UCHAR_ARRAY, i.e.
 * a #GPtrArray of #GArray of #guchar.
 *
 * This is the type used in dbus-glib to represent an array of byte arrays,
 * signature 'aay'. (Note that the #GByteArray type is not used with
 * dbus-glib.)
 *
 * Since: 0.11.14
 */

GType
tp_type_dbus_array_of_ay (void)
{
  static GType t = 0;

  if (G_UNLIKELY (t == 0))
    t = dbus_g_type_get_collection ("GPtrArray", TP_TYPE_UCHAR_ARRAY);

  return t;
}

/* auto-generated implementation stubs */
#include "_gen/gtypes-body.h"
