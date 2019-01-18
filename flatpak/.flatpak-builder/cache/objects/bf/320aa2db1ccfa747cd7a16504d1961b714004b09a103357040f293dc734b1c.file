/*
 * dbus.c - Source for D-Bus utilities
 *
 * Copyright (C) 2005-2008 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2005-2008 Nokia Corporation
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
 * SECTION:dbus
 * @title: D-Bus utilities
 * @short_description: some D-Bus utility functions
 *
 * D-Bus utility functions used in telepathy-glib.
 */

/**
 * SECTION:asv
 * @title: Manipulating a{sv} mappings
 * @short_description: Functions to manipulate mappings from string to
 *  variant, as represented in dbus-glib by a #GHashTable from string
 *  to #GValue
 *
 * Mappings from string to variant (D-Bus signature a{sv}) are commonly used
 * to provide extensibility, but in dbus-glib they're somewhat awkward to deal
 * with.
 *
 * These functions provide convenient access to the values in such
 * a mapping.
 *
 * They also work around the fact that none of the #GHashTable public API
 * takes a const pointer to a #GHashTable, even the read-only methods that
 * logically ought to.
 *
 * Parts of telepathy-glib return const pointers to #GHashTable, to encourage
 * the use of this API.
 *
 * Since: 0.7.9
 */

#include "config.h"

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/dbus-internal.h>

#include <stdlib.h>
#include <string.h>

#include <dbus/dbus.h>

#include <gobject/gvaluecollector.h>

#include <telepathy-glib/errors.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_MISC
#include "debug-internal.h"

/**
 * tp_asv_size: (skip)
 * @asv: a GHashTable
 *
 * Return the size of @asv as if via g_hash_table_size().
 *
 * The only difference is that this version takes a const #GHashTable and
 * casts it.
 *
 * Since: 0.7.12
 */
/* (#define + static inline in dbus.h) */

/**
 * tp_dbus_g_method_return_not_implemented: (skip)
 * @context: The D-Bus method invocation context
 *
 * Return the Telepathy error NotImplemented from the method invocation
 * given by @context.
 */
void
tp_dbus_g_method_return_not_implemented (DBusGMethodInvocation *context)
{
  GError e = { TP_ERROR, TP_ERROR_NOT_IMPLEMENTED, "Not implemented" };

  dbus_g_method_return_error (context, &e);
}

DBusGConnection *
_tp_dbus_starter_bus_conn (GError **error)
{
  static DBusGConnection *starter_bus = NULL;

  if (starter_bus == NULL)
    {
      starter_bus = dbus_g_bus_get (DBUS_BUS_STARTER, error);
    }

  return starter_bus;
}

/**
 * tp_get_bus: (skip)
 *
 * Returns a connection to the D-Bus daemon on which this process was
 * activated if it was launched by D-Bus service activation, or the session
 * bus otherwise.
 *
 * If dbus_g_bus_get() fails, exit with error code 1.
 *
 * Note that this function is not suitable for use in applications which can
 * be useful even in the absence of D-Bus - it is designed for use in
 * connection managers, which are not at all useful without a D-Bus
 * connection. See &lt;https://bugs.freedesktop.org/show_bug.cgi?id=18832&gt;.
 * Most processes should use tp_dbus_daemon_dup() instead.
 *
 * Returns: a connection to the starter or session D-Bus daemon.
 */
DBusGConnection *
tp_get_bus (void)
{
  GError *error = NULL;
  DBusGConnection *bus = _tp_dbus_starter_bus_conn (&error);

  if (bus == NULL)
    {
      WARNING ("Failed to connect to starter bus: %s", error->message);
      exit (1);
    }

  return bus;
}

/**
 * tp_get_bus_proxy: (skip)
 *
 * Return a #DBusGProxy for the bus daemon object. The same caveats as for
 * tp_get_bus() apply.
 *
 * Returns: a proxy for the bus daemon object on the starter or session bus.
 *
 * Deprecated: 0.7.26: Use tp_dbus_daemon_dup() in new code.
 */
DBusGProxy *
tp_get_bus_proxy (void)
{
  static DBusGProxy *bus_proxy = NULL;

  if (bus_proxy == NULL)
    {
      GError *error = NULL;
      DBusGConnection *bus = _tp_dbus_starter_bus_conn (&error);

      if (bus == NULL)
        {
          WARNING ("Failed to connect to starter bus: %s", error->message);
          exit (1);
        }

      bus_proxy = dbus_g_proxy_new_for_name (bus,
                                            "org.freedesktop.DBus",
                                            "/org/freedesktop/DBus",
                                            "org.freedesktop.DBus");

      if (bus_proxy == NULL)
        ERROR ("Failed to get proxy object for bus.");
    }

  return bus_proxy;
}

/**
 * TpDBusNameType:
 * @TP_DBUS_NAME_TYPE_UNIQUE: accept unique names like :1.123
 *  (not including the name of the bus daemon itself)
 * @TP_DBUS_NAME_TYPE_WELL_KNOWN: accept well-known names like
 *  com.example.Service (not including the name of the bus daemon itself)
 * @TP_DBUS_NAME_TYPE_BUS_DAEMON: accept the name of the bus daemon
 *  itself, which has the syntax of a well-known name, but behaves like a
 *  unique name
 * @TP_DBUS_NAME_TYPE_NOT_BUS_DAEMON: accept either unique or well-known
 *  names, but not the bus daemon
 * @TP_DBUS_NAME_TYPE_ANY: accept any of the above
 *
 * A set of flags indicating which D-Bus bus names are acceptable.
 * They can be combined with the bitwise-or operator to accept multiple
 * types. %TP_DBUS_NAME_TYPE_NOT_BUS_DAEMON and %TP_DBUS_NAME_TYPE_ANY are
 * the bitwise-or of other appropriate types, for convenience.
 *
 * Since 0.11.5, there is a corresponding #GFlagsClass type,
 * %TP_TYPE_DBUS_NAME_TYPE.
 *
 * Since: 0.7.1
 */

/**
 * TP_TYPE_DBUS_NAME_TYPE:
 *
 * The #GFlagsClass type of a #TpDBusNameType or a set of name types.
 *
 * Since: 0.11.5
 */

/**
 * tp_dbus_check_valid_bus_name:
 * @name: a possible bus name
 * @allow_types: some combination of %TP_DBUS_NAME_TYPE_UNIQUE,
 *  %TP_DBUS_NAME_TYPE_WELL_KNOWN or %TP_DBUS_NAME_TYPE_BUS_DAEMON
 *  (often this will be %TP_DBUS_NAME_TYPE_NOT_BUS_DAEMON or
 *  %TP_DBUS_NAME_TYPE_ANY)
 * @error: used to raise %TP_DBUS_ERROR_INVALID_BUS_NAME if %FALSE is returned
 *
 * Check that the given string is a valid D-Bus bus name of an appropriate
 * type.
 *
 * Returns: %TRUE if @name is valid
 *
 * Since: 0.7.1
 */
gboolean
tp_dbus_check_valid_bus_name (const gchar *name,
                              TpDBusNameType allow_types,
                              GError **error)
{
  gboolean dot = FALSE;
  gboolean unique;
  gchar last;
  const gchar *ptr;

  g_return_val_if_fail (name != NULL, FALSE);

  if (name[0] == '\0')
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_BUS_NAME,
          "The empty string is not a valid bus name");
      return FALSE;
    }

  if (!tp_strdiff (name, DBUS_SERVICE_DBUS))
    {
      if (allow_types & TP_DBUS_NAME_TYPE_BUS_DAEMON)
        return TRUE;

      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_BUS_NAME,
          "The D-Bus daemon's bus name is not acceptable here");
      return FALSE;
    }

  unique = (name[0] == ':');
  if (unique && (allow_types & TP_DBUS_NAME_TYPE_UNIQUE) == 0)
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_BUS_NAME,
          "A well-known bus name not starting with ':'%s is required",
          allow_types & TP_DBUS_NAME_TYPE_BUS_DAEMON
            ? " (or the bus daemon itself)"
            : "");
      return FALSE;
    }

  if (!unique && (allow_types & TP_DBUS_NAME_TYPE_WELL_KNOWN) == 0)
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_BUS_NAME,
          "A unique bus name starting with ':'%s is required",
          allow_types & TP_DBUS_NAME_TYPE_BUS_DAEMON
            ? " (or the bus daemon itself)"
            : "");
      return FALSE;
    }

  if (strlen (name) > 255)
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_BUS_NAME,
          "Invalid bus name: too long (> 255 characters)");
      return FALSE;
    }

  last = '\0';

  for (ptr = name + (unique ? 1 : 0); *ptr != '\0'; ptr++)
    {
      if (*ptr == '.')
        {
          dot = TRUE;

          if (last == '.')
            {
              g_set_error (error, TP_DBUS_ERRORS,
                  TP_DBUS_ERROR_INVALID_BUS_NAME,
                  "Invalid bus name '%s': contains '..'", name);
              return FALSE;
            }
          else if (last == '\0')
            {
              g_set_error (error, TP_DBUS_ERRORS,
                  TP_DBUS_ERROR_INVALID_BUS_NAME,
                  "Invalid bus name '%s': must not start with '.'", name);
              return FALSE;
            }
        }
      else if (g_ascii_isdigit (*ptr))
        {
          if (!unique)
            {
              if (last == '.')
                {
                  g_set_error (error, TP_DBUS_ERRORS,
                      TP_DBUS_ERROR_INVALID_BUS_NAME,
                      "Invalid bus name '%s': a digit may not follow '.' "
                      "except in a unique name starting with ':'", name);
                  return FALSE;
                }
              else if (last == '\0')
                {
                  g_set_error (error, TP_DBUS_ERRORS,
                      TP_DBUS_ERROR_INVALID_BUS_NAME,
                      "Invalid bus name '%s': must not start with a digit",
                      name);
                  return FALSE;
                }
            }
        }
      else if (!g_ascii_isalpha (*ptr) && *ptr != '_' && *ptr != '-')
        {
          g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_BUS_NAME,
              "Invalid bus name '%s': contains invalid character '%c'",
              name, *ptr);
          return FALSE;
        }

      last = *ptr;
    }

  if (last == '.')
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_BUS_NAME,
          "Invalid bus name '%s': must not end with '.'", name);
      return FALSE;
    }

  if (!dot)
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_BUS_NAME,
          "Invalid bus name '%s': must contain '.'", name);
      return FALSE;
    }

  return TRUE;
}

/**
 * tp_dbus_check_valid_interface_name:
 * @name: a possible interface name
 * @error: used to raise %TP_DBUS_ERROR_INVALID_INTERFACE_NAME if %FALSE is
 *  returned
 *
 * Check that the given string is a valid D-Bus interface name. This is
 * also appropriate to use to check for valid error names.
 *
 * Since GIO 2.26, g_dbus_is_interface_name() should always return the same
 * thing, although the GLib function does not raise an error explaining why
 * the interface name is incorrect.
 *
 * Returns: %TRUE if @name is valid
 *
 * Since: 0.7.1
 */
gboolean
tp_dbus_check_valid_interface_name (const gchar *name,
                                    GError **error)
{
  gboolean dot = FALSE;
  gchar last;
  const gchar *ptr;

  g_return_val_if_fail (name != NULL, FALSE);

  if (name[0] == '\0')
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_INTERFACE_NAME,
          "The empty string is not a valid interface name");
      return FALSE;
    }

  if (strlen (name) > 255)
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_INTERFACE_NAME,
          "Invalid interface name: too long (> 255 characters)");
      return FALSE;
    }

  last = '\0';

  for (ptr = name; *ptr != '\0'; ptr++)
    {
      if (*ptr == '.')
        {
          dot = TRUE;

          if (last == '.')
            {
              g_set_error (error, TP_DBUS_ERRORS,
                  TP_DBUS_ERROR_INVALID_INTERFACE_NAME,
                  "Invalid interface name '%s': contains '..'", name);
              return FALSE;
            }
          else if (last == '\0')
            {
              g_set_error (error, TP_DBUS_ERRORS,
                  TP_DBUS_ERROR_INVALID_INTERFACE_NAME,
                  "Invalid interface name '%s': must not start with '.'",
                  name);
              return FALSE;
            }
        }
      else if (g_ascii_isdigit (*ptr))
        {
          if (last == '\0')
            {
              g_set_error (error, TP_DBUS_ERRORS,
                  TP_DBUS_ERROR_INVALID_INTERFACE_NAME,
                  "Invalid interface name '%s': must not start with a digit",
                  name);
              return FALSE;
            }
          else if (last == '.')
            {
              g_set_error (error, TP_DBUS_ERRORS,
                  TP_DBUS_ERROR_INVALID_INTERFACE_NAME,
                  "Invalid interface name '%s': a digit must not follow '.'",
                  name);
              return FALSE;
            }
        }
      else if (!g_ascii_isalpha (*ptr) && *ptr != '_')
        {
          g_set_error (error, TP_DBUS_ERRORS,
              TP_DBUS_ERROR_INVALID_INTERFACE_NAME,
              "Invalid interface name '%s': contains invalid character '%c'",
              name, *ptr);
          return FALSE;
        }

      last = *ptr;
    }

  if (last == '.')
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_INTERFACE_NAME,
          "Invalid interface name '%s': must not end with '.'", name);
      return FALSE;
    }

  if (!dot)
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_INTERFACE_NAME,
          "Invalid interface name '%s': must contain '.'", name);
      return FALSE;
    }

  return TRUE;
}

/**
 * tp_dbus_check_valid_member_name:
 * @name: a possible member name
 * @error: used to raise %TP_DBUS_ERROR_INVALID_MEMBER_NAME if %FALSE is
 *  returned
 *
 * Check that the given string is a valid D-Bus member (method or signal) name.
 *
 * Since GIO 2.26, g_dbus_is_member_name() should always return the same
 * thing, although the GLib function does not raise an error explaining why
 * the interface name is incorrect.
 *
 * Returns: %TRUE if @name is valid
 *
 * Since: 0.7.1
 */
gboolean
tp_dbus_check_valid_member_name (const gchar *name,
                                 GError **error)
{
  const gchar *ptr;

  g_return_val_if_fail (name != NULL, FALSE);

  if (name[0] == '\0')
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_MEMBER_NAME,
          "The empty string is not a valid method or signal name");
      return FALSE;
    }

  if (strlen (name) > 255)
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_MEMBER_NAME,
          "Invalid method or signal name: too long (> 255 characters)");
      return FALSE;
    }

  for (ptr = name; *ptr != '\0'; ptr++)
    {
      if (g_ascii_isdigit (*ptr))
        {
          if (ptr == name)
            {
              g_set_error (error, TP_DBUS_ERRORS,
                  TP_DBUS_ERROR_INVALID_MEMBER_NAME,
                  "Invalid method or signal name '%s': must not start with "
                  "a digit", name);
              return FALSE;
            }
        }
      else if (!g_ascii_isalpha (*ptr) && *ptr != '_')
        {
          g_set_error (error, TP_DBUS_ERRORS,
              TP_DBUS_ERROR_INVALID_MEMBER_NAME,
              "Invalid method or signal name '%s': contains invalid "
              "character '%c'",
              name, *ptr);
          return FALSE;
        }
    }

  return TRUE;
}

/**
 * tp_dbus_check_valid_object_path:
 * @path: a possible object path
 * @error: used to raise %TP_DBUS_ERROR_INVALID_OBJECT_PATH if %FALSE is
 *  returned
 *
 * Check that the given string is a valid D-Bus object path. Since GLib 2.24,
 * g_variant_is_object_path() should always return the same thing as this
 * function, although it doesn't provide an error explaining why the object
 * path is invalid.
 *
 * Returns: %TRUE if @path is valid
 *
 * Since: 0.7.1
 */
gboolean
tp_dbus_check_valid_object_path (const gchar *path, GError **error)
{
  const gchar *ptr;

  g_return_val_if_fail (path != NULL, FALSE);

  if (path[0] != '/')
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_OBJECT_PATH,
          "Invalid object path '%s': must start with '/'",
          path);
      return FALSE;
    }

  if (path[1] == '\0')
    return TRUE;

  for (ptr = path + 1; *ptr != '\0'; ptr++)
    {
      if (*ptr == '/')
        {
          if (ptr[-1] == '/')
            {
              g_set_error (error, TP_DBUS_ERRORS,
                  TP_DBUS_ERROR_INVALID_OBJECT_PATH,
                  "Invalid object path '%s': contains '//'", path);
              return FALSE;
            }
        }
      else if (!g_ascii_isalnum (*ptr) && *ptr != '_')
        {
          g_set_error (error, TP_DBUS_ERRORS,
              TP_DBUS_ERROR_INVALID_OBJECT_PATH,
              "Invalid object path '%s': contains invalid character '%c'",
              path, *ptr);
          return FALSE;
        }
    }

  if (ptr[-1] == '/')
    {
        g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INVALID_OBJECT_PATH,
            "Invalid object path '%s': is not '/' but does end with '/'",
            path);
        return FALSE;
    }

  return TRUE;
}

/**
 * tp_g_value_slice_new_bytes: (skip)
 * @length: number of bytes to copy
 * @bytes: location of an array of bytes to be copied (this may be %NULL
 *  if and only if length is 0)
 *
 * Slice-allocate a #GValue containing a byte-array, using
 * tp_g_value_slice_new_boxed(). This function is convenient to use when
 * constructing hash tables from string to #GValue, for example.
 *
 * Returns: a #GValue of type %DBUS_TYPE_G_UCHAR_ARRAY whose value is a copy
 * of @length bytes from @bytes, to be freed with tp_g_value_slice_free() or
 * g_slice_free()
 *
 * Since: 0.7.27
 */
GValue *
tp_g_value_slice_new_bytes (guint length,
                            gconstpointer bytes)
{
  GArray *arr;

  g_return_val_if_fail (length == 0 || bytes != NULL, NULL);
  arr = g_array_sized_new (FALSE, FALSE, 1, length);

  if (length > 0)
    g_array_append_vals (arr, bytes, length);

  return tp_g_value_slice_new_take_boxed (DBUS_TYPE_G_UCHAR_ARRAY, arr);
}

/**
 * tp_g_value_slice_new_take_bytes: (skip)
 * @bytes: a non-NULL #GArray of guchar, ownership of which will be taken by
 *  the #GValue
 *
 * Slice-allocate a #GValue containing @bytes, using
 * tp_g_value_slice_new_boxed(). This function is convenient to use when
 * constructing hash tables from string to #GValue, for example.
 *
 * Returns: a #GValue of type %DBUS_TYPE_G_UCHAR_ARRAY whose value is
 * @bytes, to be freed with tp_g_value_slice_free() or
 * g_slice_free()
 *
 * Since: 0.7.27
 */
GValue *
tp_g_value_slice_new_take_bytes (GArray *bytes)
{
  g_return_val_if_fail (bytes != NULL, NULL);
  return tp_g_value_slice_new_take_boxed (DBUS_TYPE_G_UCHAR_ARRAY, bytes);
}

/**
 * tp_g_value_slice_new_object_path: (skip)
 * @path: a valid D-Bus object path which will be copied
 *
 * Slice-allocate a #GValue containing an object path, using
 * tp_g_value_slice_new_boxed(). This function is convenient to use when
 * constructing hash tables from string to #GValue, for example.
 *
 * Returns: a #GValue of type %DBUS_TYPE_G_OBJECT_PATH whose value is a copy
 * of @path, to be freed with tp_g_value_slice_free() or g_slice_free()
 *
 * Since: 0.7.27
 */
GValue *
tp_g_value_slice_new_object_path (const gchar *path)
{
  g_return_val_if_fail (tp_dbus_check_valid_object_path (path, NULL), NULL);
  return tp_g_value_slice_new_boxed (DBUS_TYPE_G_OBJECT_PATH, path);
}

/**
 * tp_g_value_slice_new_static_object_path: (skip)
 * @path: a valid D-Bus object path which must remain valid forever
 *
 * Slice-allocate a #GValue containing an object path, using
 * tp_g_value_slice_new_static_boxed(). This function is convenient to use when
 * constructing hash tables from string to #GValue, for example.
 *
 * Returns: a #GValue of type %DBUS_TYPE_G_OBJECT_PATH whose value is @path,
 * to be freed with tp_g_value_slice_free() or g_slice_free()
 *
 * Since: 0.7.27
 */
GValue *
tp_g_value_slice_new_static_object_path (const gchar *path)
{
  g_return_val_if_fail (tp_dbus_check_valid_object_path (path, NULL), NULL);
  return tp_g_value_slice_new_static_boxed (DBUS_TYPE_G_OBJECT_PATH, path);
}

/**
 * tp_g_value_slice_new_take_object_path: (skip)
 * @path: a valid D-Bus object path which will be freed with g_free() by the
 *  returned #GValue (the caller must own it before calling this function, but
 *  no longer owns it after this function returns)
 *
 * Slice-allocate a #GValue containing an object path, using
 * tp_g_value_slice_new_take_boxed(). This function is convenient to use when
 * constructing hash tables from string to #GValue, for example.
 *
 * Returns: a #GValue of type %DBUS_TYPE_G_OBJECT_PATH whose value is @path,
 * to be freed with tp_g_value_slice_free() or g_slice_free()
 *
 * Since: 0.7.27
 */
GValue *
tp_g_value_slice_new_take_object_path (gchar *path)
{
  g_return_val_if_fail (tp_dbus_check_valid_object_path (path, NULL), NULL);
  return tp_g_value_slice_new_take_boxed (DBUS_TYPE_G_OBJECT_PATH, path);
}

/**
 * tp_asv_new: (skip)
 * @first_key: the name of the first key (or NULL)
 * @...: type and value for the first key, followed by a NULL-terminated list
 *  of (key, type, value) tuples
 *
 * Creates a new #GHashTable for use with a{sv} maps, containing the values
 * passed in as parameters.
 *
 * The #GHashTable is synonymous with:
 * <informalexample><programlisting>
 * GHashTable *asv = g_hash_table_new_full (g_str_hash, g_str_equal,
 *    NULL, (GDestroyNotify) tp_g_value_slice_free);
 * </programlisting></informalexample>
 * Followed by manual insertion of each of the parameters.
 *
 * Parameters are stored in slice-allocated GValues and should be set using
 * tp_asv_set_*() and retrieved using tp_asv_get_*().
 *
 * tp_g_value_slice_new() and tp_g_value_slice_dup() may also be used to insert
 * into the map if required.
 * <informalexample><programlisting>
 * g_hash_table_insert (parameters, "account",
 *    tp_g_value_slice_new_string ("bob@mcbadgers.com"));
 * </programlisting></informalexample>
 *
 * <example>
 *  <title>Using tp_asv_new()</title>
 *  <programlisting>
 * GHashTable *parameters = tp_asv_new (
 *    "answer", G_TYPE_INT, 42,
 *    "question", G_TYPE_STRING, "We just don't know",
 *    NULL);</programlisting>
 * </example>
 *
 * Allocated values will be automatically free'd when overwritten, removed or
 * the hash table destroyed with g_hash_table_unref().
 *
 * Returns: a newly created #GHashTable for storing a{sv} maps, free with
 * g_hash_table_unref().
 * Since: 0.7.29
 */
GHashTable *
tp_asv_new (const gchar *first_key, ...)
{
  va_list var_args;
  char *key;
  GType type;
  GValue *value;
  char *error = NULL; /* NB: not a GError! */

  /* create a GHashTable */
  GHashTable *asv = g_hash_table_new_full (g_str_hash, g_str_equal,
      NULL, (GDestroyNotify) tp_g_value_slice_free);

  va_start (var_args, first_key);

  for (key = (char *) first_key; key != NULL; key = va_arg (var_args, char *))
  {
    type = va_arg (var_args, GType);

    value = tp_g_value_slice_new (type);
    G_VALUE_COLLECT (value, var_args, 0, &error);

    if (error != NULL)
    {
      CRITICAL ("key %s: %s", key, error);
      g_free (error);
      error = NULL;
      tp_g_value_slice_free (value);
      continue;
    }

    g_hash_table_insert (asv, key, value);
  }

  va_end (var_args);

  return asv;
}

/**
 * tp_asv_get_boolean:
 * @asv: (element-type utf8 GObject.Value): A GHashTable where the keys are
 * strings and the values are GValues
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location to store %TRUE if the key actually
 *  exists and has a boolean value
 *
 * If a value for @key in @asv is present and boolean, return it,
 * and set *@valid to %TRUE if @valid is not %NULL.
 *
 * Otherwise return %FALSE, and set *@valid to %FALSE if @valid is not %NULL.
 *
 * Returns: a boolean value for @key
 * Since: 0.7.9
 */
gboolean
tp_asv_get_boolean (const GHashTable *asv,
                    const gchar *key,
                    gboolean *valid)
{
  GValue *value;

  g_return_val_if_fail (asv != NULL, FALSE);
  g_return_val_if_fail (key != NULL, FALSE);

  value = g_hash_table_lookup ((GHashTable *) asv, key);

  if (value == NULL || !G_VALUE_HOLDS_BOOLEAN (value))
    {
      if (valid != NULL)
        *valid = FALSE;

      return FALSE;
    }

  if (valid != NULL)
    *valid = TRUE;

  return g_value_get_boolean (value);
}

/**
 * tp_asv_set_boolean: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_boolean(), tp_g_value_slice_new_boolean()
 * Since: 0.7.29
 */
void
tp_asv_set_boolean (GHashTable *asv,
                    const gchar *key,
                    gboolean value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key, tp_g_value_slice_new_boolean (value));
}

/**
 * tp_asv_get_bytes:
 * @asv: (element-type utf8 GObject.Value): A GHashTable where the keys are
 * strings and the values are GValues
 * @key: The key to look up
 *
 * If a value for @key in @asv is present and is an array of bytes
 * (its GType is %DBUS_TYPE_G_UCHAR_ARRAY), return it.
 *
 * Otherwise return %NULL.
 *
 * The returned value is not copied, and is only valid as long as the value
 * for @key in @asv is not removed or altered. Copy it with
 * g_boxed_copy (DBUS_TYPE_G_UCHAR_ARRAY, ...) if you need to keep
 * it for longer.
 *
 * Returns: (transfer none) (allow-none) (element-type guint8): the string value
 * of @key, or %NULL
 * Since: 0.7.9
 */
const GArray *
tp_asv_get_bytes (const GHashTable *asv,
                   const gchar *key)
{
  GValue *value;

  g_return_val_if_fail (asv != NULL, NULL);
  g_return_val_if_fail (key != NULL, NULL);

  value = g_hash_table_lookup ((GHashTable *) asv, key);

  if (value == NULL || !G_VALUE_HOLDS (value, DBUS_TYPE_G_UCHAR_ARRAY))
    return NULL;

  return g_value_get_boxed (value);
}

/**
 * tp_asv_set_bytes: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @length: the number of bytes to copy
 * @bytes: location of an array of bytes to be copied (this may be %NULL
 * if and only if length is 0)
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_bytes(), tp_g_value_slice_new_bytes()
 * Since: 0.7.29
 */
void
tp_asv_set_bytes (GHashTable *asv,
                  const gchar *key,
                  guint length,
                  gconstpointer bytes)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);
  g_return_if_fail (!(length > 0 && bytes == NULL));

  g_hash_table_insert (asv, (char *) key,
      tp_g_value_slice_new_bytes (length, bytes));
}

/**
 * tp_asv_take_bytes: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: a non-NULL #GArray of %guchar, ownership of which will be taken by
 * the #GValue
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_bytes(), tp_g_value_slice_new_take_bytes()
 * Since: 0.7.29
 */
void
tp_asv_take_bytes (GHashTable *asv,
                   const gchar *key,
                   GArray *value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);
  g_return_if_fail (value != NULL);

  g_hash_table_insert (asv, (char *) key,
      tp_g_value_slice_new_take_bytes (value));
}

/**
 * tp_asv_get_string:
 * @asv: (element-type utf8 GObject.Value): A GHashTable where the keys are
 * strings and the values are GValues
 * @key: The key to look up
 *
 * If a value for @key in @asv is present and is a string, return it.
 *
 * Otherwise return %NULL.
 *
 * The returned value is not copied, and is only valid as long as the value
 * for @key in @asv is not removed or altered. Copy it with g_strdup() if you
 * need to keep it for longer.
 *
 * Returns: (transfer none) (allow-none): the string value of @key, or %NULL
 * Since: 0.7.9
 */
const gchar *
tp_asv_get_string (const GHashTable *asv,
                   const gchar *key)
{
  GValue *value;

  g_return_val_if_fail (asv != NULL, NULL);
  g_return_val_if_fail (key != NULL, NULL);

  value = g_hash_table_lookup ((GHashTable *) asv, key);

  if (value == NULL || !G_VALUE_HOLDS_STRING (value))
    return NULL;

  return g_value_get_string (value);
}

/**
 * tp_asv_set_string: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_string(), tp_g_value_slice_new_string()
 * Since: 0.7.29
 */
void
tp_asv_set_string (GHashTable *asv,
                   const gchar *key,
                   const gchar *value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key, tp_g_value_slice_new_string (value));
}

/**
 * tp_asv_take_string: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_string(),
 * tp_g_value_slice_new_take_string()
 * Since: 0.7.29
 */
void
tp_asv_take_string (GHashTable *asv,
                    const gchar *key,
                    gchar *value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key,
      tp_g_value_slice_new_take_string (value));
}

/**
 * tp_asv_set_static_string: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_string(),
 * tp_g_value_slice_new_static_string()
 * Since: 0.7.29
 */
void
tp_asv_set_static_string (GHashTable *asv,
                          const gchar *key,
                          const gchar *value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key,
      tp_g_value_slice_new_static_string (value));
}

/**
 * tp_asv_get_int32:
 * @asv: (element-type utf8 GObject.Value): A GHashTable where the keys are
 * strings and the values are GValues
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location in which to store %TRUE on success
 * or %FALSE on failure
 *
 * If a value for @key in @asv is present, has an integer type used by
 * dbus-glib (guchar, gint, guint, gint64 or guint64) and fits in the
 * range of a gint32, return it, and if @valid is not %NULL, set *@valid to
 * %TRUE.
 *
 * Otherwise, return 0, and if @valid is not %NULL, set *@valid to %FALSE.
 *
 * Returns: the 32-bit signed integer value of @key, or 0
 * Since: 0.7.9
 */
gint32
tp_asv_get_int32 (const GHashTable *asv,
                  const gchar *key,
                  gboolean *valid)
{
  gint64 i;
  guint64 u;
  gint32 ret;
  GValue *value;

  g_return_val_if_fail (asv != NULL, 0);
  g_return_val_if_fail (key != NULL, 0);

  value = g_hash_table_lookup ((GHashTable *) asv, key);

  if (value == NULL)
    goto return_invalid;

  switch (G_VALUE_TYPE (value))
    {
    case G_TYPE_UCHAR:
      ret = g_value_get_uchar (value);
      break;

    case G_TYPE_UINT:
      u = g_value_get_uint (value);

      if (G_UNLIKELY (u > G_MAXINT32))
        goto return_invalid;

      ret = u;
      break;

    case G_TYPE_INT:
      ret = g_value_get_int (value);
      break;

    case G_TYPE_INT64:
      i = g_value_get_int64 (value);

      if (G_UNLIKELY (i < G_MININT32 || i > G_MAXINT32))
        goto return_invalid;

      ret = i;
      break;

    case G_TYPE_UINT64:
      u = g_value_get_uint64 (value);

      if (G_UNLIKELY (u > G_MAXINT32))
        goto return_invalid;

      ret = u;
      break;

    default:
      goto return_invalid;
    }

  if (valid != NULL)
    *valid = TRUE;

  return ret;

return_invalid:
  if (valid != NULL)
    *valid = FALSE;

  return 0;
}

/**
 * tp_asv_set_int32: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_int32(), tp_g_value_slice_new_int()
 * Since: 0.7.29
 */
void
tp_asv_set_int32 (GHashTable *asv,
                  const gchar *key,
                  gint32 value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key, tp_g_value_slice_new_int (value));
}

/**
 * tp_asv_get_uint32:
 * @asv: (element-type utf8 GObject.Value): A GHashTable where the keys are
 * strings and the values are GValues
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location in which to store %TRUE on success
 * or %FALSE on failure
 *
 * If a value for @key in @asv is present, has an integer type used by
 * dbus-glib (guchar, gint, guint, gint64 or guint64) and fits in the
 * range of a guint32, return it, and if @valid is not %NULL, set *@valid to
 * %TRUE.
 *
 * Otherwise, return 0, and if @valid is not %NULL, set *@valid to %FALSE.
 *
 * Returns: the 32-bit unsigned integer value of @key, or 0
 * Since: 0.7.9
 */
guint32
tp_asv_get_uint32 (const GHashTable *asv,
                   const gchar *key,
                   gboolean *valid)
{
  gint64 i;
  guint64 u;
  guint32 ret;
  GValue *value;

  g_return_val_if_fail (asv != NULL, 0);
  g_return_val_if_fail (key != NULL, 0);

  value = g_hash_table_lookup ((GHashTable *) asv, key);

  if (value == NULL)
    goto return_invalid;

  switch (G_VALUE_TYPE (value))
    {
    case G_TYPE_UCHAR:
      ret = g_value_get_uchar (value);
      break;

    case G_TYPE_UINT:
      ret = g_value_get_uint (value);
      break;

    case G_TYPE_INT:
      i = g_value_get_int (value);

      if (G_UNLIKELY (i < 0))
        goto return_invalid;

      ret = i;
      break;

    case G_TYPE_INT64:
      i = g_value_get_int64 (value);

      if (G_UNLIKELY (i < 0 || i > G_MAXUINT32))
        goto return_invalid;

      ret = i;
      break;

    case G_TYPE_UINT64:
      u = g_value_get_uint64 (value);

      if (G_UNLIKELY (u > G_MAXUINT32))
        goto return_invalid;

      ret = u;
      break;

    default:
      goto return_invalid;
    }

  if (valid != NULL)
    *valid = TRUE;

  return ret;

return_invalid:
  if (valid != NULL)
    *valid = FALSE;

  return 0;
}

/**
 * tp_asv_set_uint32: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_uint32(), tp_g_value_slice_new_uint()
 * Since: 0.7.29
 */
void
tp_asv_set_uint32 (GHashTable *asv,
                   const gchar *key,
                   guint32 value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key, tp_g_value_slice_new_uint (value));
}

/**
 * tp_asv_get_int64:
 * @asv: (element-type utf8 GObject.Value): A GHashTable where the keys are
 * strings and the values are GValues
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location in which to store %TRUE on success
 * or %FALSE on failure
 *
 * If a value for @key in @asv is present, has an integer type used by
 * dbus-glib (guchar, gint, guint, gint64 or guint64) and fits in the
 * range of a gint64, return it, and if @valid is not %NULL, set *@valid to
 * %TRUE.
 *
 * Otherwise, return 0, and if @valid is not %NULL, set *@valid to %FALSE.
 *
 * Returns: the 64-bit signed integer value of @key, or 0
 * Since: 0.7.9
 */
gint64
tp_asv_get_int64 (const GHashTable *asv,
                  const gchar *key,
                  gboolean *valid)
{
  gint64 ret;
  guint64 u;
  GValue *value;

  g_return_val_if_fail (asv != NULL, 0);
  g_return_val_if_fail (key != NULL, 0);

  value = g_hash_table_lookup ((GHashTable *) asv, key);

  if (value == NULL)
    goto return_invalid;

  switch (G_VALUE_TYPE (value))
    {
    case G_TYPE_UCHAR:
      ret = g_value_get_uchar (value);
      break;

    case G_TYPE_UINT:
      ret = g_value_get_uint (value);
      break;

    case G_TYPE_INT:
      ret = g_value_get_int (value);
      break;

    case G_TYPE_INT64:
      ret = g_value_get_int64 (value);
      break;

    case G_TYPE_UINT64:
      u = g_value_get_uint64 (value);

      if (G_UNLIKELY (u > G_MAXINT64))
        goto return_invalid;

      ret = u;
      break;

    default:
      goto return_invalid;
    }

  if (valid != NULL)
    *valid = TRUE;

  return ret;

return_invalid:
  if (valid != NULL)
    *valid = FALSE;

  return 0;
}

/**
 * tp_asv_set_int64: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_int64(), tp_g_value_slice_new_int64()
 * Since: 0.7.29
 */
void
tp_asv_set_int64 (GHashTable *asv,
                  const gchar *key,
                  gint64 value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key, tp_g_value_slice_new_int64 (value));
}

/**
 * tp_asv_get_uint64:
 * @asv: (element-type utf8 GObject.Value): A GHashTable where the keys are
 * strings and the values are GValues
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location in which to store %TRUE on success
 * or %FALSE on failure
 *
 * If a value for @key in @asv is present, has an integer type used by
 * dbus-glib (guchar, gint, guint, gint64 or guint64) and is non-negative,
 * return it, and if @valid is not %NULL, set *@valid to %TRUE.
 *
 * Otherwise, return 0, and if @valid is not %NULL, set *@valid to %FALSE.
 *
 * Returns: the 64-bit unsigned integer value of @key, or 0
 * Since: 0.7.9
 */
guint64
tp_asv_get_uint64 (const GHashTable *asv,
                   const gchar *key,
                   gboolean *valid)
{
  gint64 tmp;
  guint64 ret;
  GValue *value;

  g_return_val_if_fail (asv != NULL, 0);
  g_return_val_if_fail (key != NULL, 0);

  value = g_hash_table_lookup ((GHashTable *) asv, key);

  if (value == NULL)
    goto return_invalid;

  switch (G_VALUE_TYPE (value))
    {
    case G_TYPE_UCHAR:
      ret = g_value_get_uchar (value);
      break;

    case G_TYPE_UINT:
      ret = g_value_get_uint (value);
      break;

    case G_TYPE_INT:
      tmp = g_value_get_int (value);

      if (G_UNLIKELY (tmp < 0))
        goto return_invalid;

      ret = tmp;
      break;

    case G_TYPE_INT64:
      tmp = g_value_get_int64 (value);

      if (G_UNLIKELY (tmp < 0))
        goto return_invalid;

      ret = tmp;
      break;

    case G_TYPE_UINT64:
      ret = g_value_get_uint64 (value);
      break;

    default:
      goto return_invalid;
    }

  if (valid != NULL)
    *valid = TRUE;

  return ret;

return_invalid:
  if (valid != NULL)
    *valid = FALSE;

  return 0;
}

/**
 * tp_asv_set_uint64: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_uint64(), tp_g_value_slice_new_uint64()
 * Since: 0.7.29
 */
void
tp_asv_set_uint64 (GHashTable *asv,
                   const gchar *key,
                   guint64 value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key, tp_g_value_slice_new_uint64 (value));
}

/**
 * tp_asv_get_double:
 * @asv: (element-type utf8 GObject.Value): A GHashTable where the keys are
 * strings and the values are GValues
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location in which to store %TRUE on success
 * or %FALSE on failure
 *
 * If a value for @key in @asv is present and has any numeric type used by
 * dbus-glib (guchar, gint, guint, gint64, guint64 or gdouble),
 * return it as a double, and if @valid is not %NULL, set *@valid to %TRUE.
 *
 * Otherwise, return 0.0, and if @valid is not %NULL, set *@valid to %FALSE.
 *
 * Returns: the double precision floating-point value of @key, or 0.0
 * Since: 0.7.9
 */
gdouble
tp_asv_get_double (const GHashTable *asv,
                   const gchar *key,
                   gboolean *valid)
{
  gdouble ret;
  GValue *value;

  g_return_val_if_fail (asv != NULL, 0.0);
  g_return_val_if_fail (key != NULL, 0.0);

  value = g_hash_table_lookup ((GHashTable *) asv, key);

  if (value == NULL)
    goto return_invalid;

  switch (G_VALUE_TYPE (value))
    {
    case G_TYPE_DOUBLE:
      ret = g_value_get_double (value);
      break;

    case G_TYPE_UCHAR:
      ret = g_value_get_uchar (value);
      break;

    case G_TYPE_UINT:
      ret = g_value_get_uint (value);
      break;

    case G_TYPE_INT:
      ret = g_value_get_int (value);
      break;

    case G_TYPE_INT64:
      ret = g_value_get_int64 (value);
      break;

    case G_TYPE_UINT64:
      ret = g_value_get_uint64 (value);
      break;

    default:
      goto return_invalid;
    }

  if (valid != NULL)
    *valid = TRUE;

  return ret;

return_invalid:
  if (valid != NULL)
    *valid = FALSE;

  return 0;
}

/**
 * tp_asv_set_double: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_double(), tp_g_value_slice_new_double()
 * Since: 0.7.29
 */
void
tp_asv_set_double (GHashTable *asv,
                   const gchar *key,
                   gdouble value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key, tp_g_value_slice_new_double (value));
}

/**
 * tp_asv_get_object_path:
 * @asv: (element-type utf8 GObject.Value): A GHashTable where the keys are
 * strings and the values are GValues
 * @key: The key to look up
 *
 * If a value for @key in @asv is present and is an object path, return it.
 *
 * Otherwise return %NULL.
 *
 * The returned value is not copied, and is only valid as long as the value
 * for @key in @asv is not removed or altered. Copy it with g_strdup() if you
 * need to keep it for longer.
 *
 * Returns: (transfer none) (allow-none): the object-path value of @key, or
 * %NULL
 * Since: 0.7.9
 */
const gchar *
tp_asv_get_object_path (const GHashTable *asv,
                        const gchar *key)
{
  GValue *value;

  g_return_val_if_fail (asv != NULL, 0);
  g_return_val_if_fail (key != NULL, 0);

  value = g_hash_table_lookup ((GHashTable *) asv, key);

  if (value == NULL || !G_VALUE_HOLDS (value, DBUS_TYPE_G_OBJECT_PATH))
    return NULL;

  return g_value_get_boxed (value);
}

/**
 * tp_asv_set_object_path: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_object_path(),
 * tp_g_value_slice_new_object_path()
 * Since: 0.7.29
 */
void
tp_asv_set_object_path (GHashTable *asv,
                        const gchar *key,
                        const gchar *value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key,
      tp_g_value_slice_new_object_path (value));
}

/**
 * tp_asv_take_object_path: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_object_path(),
 * tp_g_value_slice_new_take_object_path()
 * Since: 0.7.29
 */
void
tp_asv_take_object_path (GHashTable *asv,
                         const gchar *key,
                         gchar *value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key,
      tp_g_value_slice_new_take_object_path (value));
}

/**
 * tp_asv_set_static_object_path: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_object_path(),
 * tp_g_value_slice_new_static_object_path()
 * Since: 0.7.29
 */
void
tp_asv_set_static_object_path (GHashTable *asv,
                               const gchar *key,
                               const gchar *value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key,
      tp_g_value_slice_new_static_object_path (value));
}

/**
 * tp_asv_get_boxed:
 * @asv: (element-type utf8 GObject.Value): A GHashTable where the keys are
 * strings and the values are GValues
 * @key: The key to look up
 * @type: The type that the key's value should have, which must be derived
 *  from %G_TYPE_BOXED
 *
 * If a value for @key in @asv is present and is of the desired type,
 * return it.
 *
 * Otherwise return %NULL.
 *
 * The returned value is not copied, and is only valid as long as the value
 * for @key in @asv is not removed or altered. Copy it, for instance with
 * g_boxed_copy(), if you need to keep it for longer.
 *
 * Returns: (transfer none) (allow-none): the value of @key, or %NULL
 * Since: 0.7.9
 */
gpointer
tp_asv_get_boxed (const GHashTable *asv,
                  const gchar *key,
                  GType type)
{
  GValue *value;

  g_return_val_if_fail (asv != NULL, NULL);
  g_return_val_if_fail (key != NULL, NULL);
  g_return_val_if_fail (G_TYPE_FUNDAMENTAL (type) == G_TYPE_BOXED, NULL);

  value = g_hash_table_lookup ((GHashTable *) asv, key);

  if (value == NULL || !G_VALUE_HOLDS (value, type))
    return NULL;

  return g_value_get_boxed (value);
}

/**
 * tp_asv_set_boxed: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @type: the type of the key's value, which must be derived from %G_TYPE_BOXED
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_boxed(), tp_g_value_slice_new_boxed()
 * Since: 0.7.29
 */
void
tp_asv_set_boxed (GHashTable *asv,
                  const gchar *key,
                  GType type,
                  gconstpointer value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);
  g_return_if_fail (G_TYPE_FUNDAMENTAL (type) == G_TYPE_BOXED);

  g_hash_table_insert (asv, (char *) key,
      tp_g_value_slice_new_boxed (type, value));
}

/**
 * tp_asv_take_boxed: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @type: the type of the key's value, which must be derived from %G_TYPE_BOXED
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_boxed(), tp_g_value_slice_new_take_boxed()
 * Since: 0.7.29
 */
void
tp_asv_take_boxed (GHashTable *asv,
                   const gchar *key,
                   GType type,
                   gpointer value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);
  g_return_if_fail (G_TYPE_FUNDAMENTAL (type) == G_TYPE_BOXED);

  g_hash_table_insert (asv, (char *) key,
      tp_g_value_slice_new_take_boxed (type, value));
}

/**
 * tp_asv_set_static_boxed: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @type: the type of the key's value, which must be derived from %G_TYPE_BOXED
 * @value: value
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_boxed(),
 * tp_g_value_slice_new_static_boxed()
 * Since: 0.7.29
 */
void
tp_asv_set_static_boxed (GHashTable *asv,
                         const gchar *key,
                         GType type,
                         gconstpointer value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);
  g_return_if_fail (G_TYPE_FUNDAMENTAL (type) == G_TYPE_BOXED);

  g_hash_table_insert (asv, (char *) key,
      tp_g_value_slice_new_static_boxed (type, value));
}

/**
 * tp_asv_get_strv:
 * @asv: (element-type utf8 GObject.Value): A GHashTable where the keys are
 * strings and the values are GValues
 * @key: The key to look up
 *
 * If a value for @key in @asv is present and is an array of strings (strv),
 * return it.
 *
 * Otherwise return %NULL.
 *
 * The returned value is not copied, and is only valid as long as the value
 * for @key in @asv is not removed or altered. Copy it with g_strdupv() if you
 * need to keep it for longer.
 *
 * Returns: (transfer none) (allow-none): the %NULL-terminated string-array
 * value of @key, or %NULL
 * Since: 0.7.9
 */
const gchar * const *
tp_asv_get_strv (const GHashTable *asv,
                 const gchar *key)
{
  GValue *value;

  g_return_val_if_fail (asv != NULL, NULL);
  g_return_val_if_fail (key != NULL, NULL);

  value = g_hash_table_lookup ((GHashTable *) asv, key);

  if (value == NULL || !G_VALUE_HOLDS (value, G_TYPE_STRV))
    return NULL;

  return g_value_get_boxed (value);
}

/**
 * tp_asv_set_strv: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 * @key: string key
 * @value: a %NULL-terminated string array
 *
 * Stores the value in the map.
 *
 * The value is stored as a slice-allocated GValue.
 *
 * See Also: tp_asv_new(), tp_asv_get_strv()
 * Since: 0.7.29
 */
void
tp_asv_set_strv (GHashTable *asv,
                 const gchar *key,
                 gchar **value)
{
  g_return_if_fail (asv != NULL);
  g_return_if_fail (key != NULL);

  g_hash_table_insert (asv, (char *) key,
      tp_g_value_slice_new_boxed (G_TYPE_STRV, value));
}

/**
 * tp_asv_lookup: (skip)
 * @asv: A GHashTable where the keys are strings and the values are GValues
 * @key: The key to look up
 *
 * If a value for @key in @asv is present, return it. Otherwise return %NULL.
 *
 * The returned value is not copied, and is only valid as long as the value
 * for @key in @asv is not removed or altered. Copy it with (for instance)
 * g_value_copy() if you need to keep it for longer.
 *
 * Returns: the value of @key, or %NULL
 * Since: 0.7.9
 */
const GValue *
tp_asv_lookup (const GHashTable *asv,
               const gchar *key)
{
  g_return_val_if_fail (asv != NULL, NULL);
  g_return_val_if_fail (key != NULL, NULL);

  return g_hash_table_lookup ((GHashTable *) asv, key);
}

/**
 * tp_asv_dump: (skip)
 * @asv: a #GHashTable created with tp_asv_new()
 *
 * Dumps the a{sv} map to the debugging console.
 *
 * The purpose of this function is give the programmer the ability to easily
 * inspect the contents of an a{sv} map for debugging purposes.
 */
void
tp_asv_dump (GHashTable *asv)
{
  GHashTableIter iter;
  char *key;
  GValue *value;

  g_return_if_fail (asv != NULL);

  g_debug ("{");

  g_hash_table_iter_init (&iter, asv);
  while (g_hash_table_iter_next (&iter, (gpointer) &key, (gpointer) &value))
  {
    char *str = g_strdup_value_contents (value);
    g_debug ("  '%s' : %s", key, str);
    g_free (str);
  }

  g_debug ("}");
}
