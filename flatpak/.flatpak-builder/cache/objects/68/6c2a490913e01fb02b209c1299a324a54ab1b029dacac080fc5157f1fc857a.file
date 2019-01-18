/*
 * variant-util.c - Source for GVariant utilities
 *
 * Copyright (C) 2012 Collabora Ltd. <http://www.collabora.co.uk/>
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
 * SECTION:variant-util
 * @title: GVariant utilities
 * @short_description: some GVariant utility functions
 *
 * GVariant utility functions used in telepathy-glib.
 */

/**
 * SECTION:vardict
 * @title: Manipulating a{sv} mappings
 * @short_description: Functions to manipulate mappings from string to
 *  variant, as represented in GVariant by a %G_VARIANT_TYPE_VARDICT
 *
 * These functions provide convenient access to the values in such
 * a mapping.
 *
 * Since: 0.19.10
 */

#include "config.h"

#include <telepathy-glib/variant-util.h>
#include <telepathy-glib/variant-util-internal.h>

#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_MISC
#include "debug-internal.h"

/*
 * _tp_asv_to_vardict:
 *
 * Returns: (transfer full): a #GVariant of type %G_VARIANT_TYPE_VARDICT
 */
GVariant *
_tp_asv_to_vardict (const GHashTable *asv)
{
  return _tp_boxed_to_variant (TP_HASH_TYPE_STRING_VARIANT_MAP, "a{sv}", (gpointer) asv);
}

GVariant *
_tp_boxed_to_variant (GType gtype,
    const gchar *variant_type,
    gpointer boxed)
{
  GValue v = G_VALUE_INIT;
  GVariant *ret;

  g_return_val_if_fail (boxed != NULL, NULL);

  g_value_init (&v, gtype);
  g_value_set_boxed (&v, boxed);

  ret = dbus_g_value_build_g_variant (&v);
  g_return_val_if_fail (!tp_strdiff (g_variant_get_type_string (ret), variant_type), NULL);

  g_value_unset (&v);

  return g_variant_ref_sink (ret);
}

/*
 * _tp_asv_from_vardict:
 * @variant: a #GVariant of type %G_VARIANT_TYPE_VARDICT
 *
 * Returns: (transfer full): a newly created #GHashTable of
 * type #TP_HASH_TYPE_STRING_VARIANT_MAP
 */
GHashTable *
_tp_asv_from_vardict (GVariant *variant)
{
  GValue v = G_VALUE_INIT;
  GHashTable *result;

  g_return_val_if_fail (variant != NULL, NULL);
  g_return_val_if_fail (g_variant_is_of_type (variant, G_VARIANT_TYPE_VARDICT),
      NULL);

  dbus_g_value_parse_g_variant (variant, &v);
  g_assert (G_VALUE_HOLDS (&v, TP_HASH_TYPE_STRING_VARIANT_MAP));

  result = g_value_dup_boxed (&v);

  g_value_unset (&v);
  return result;
}

/**
 * tp_variant_type_classify:
 * @type: a #GVariantType
 *
 * Classifies @type according to its top-level type.
 *
 * Returns: the #GVariantClass of @type
 * Since: 0.19.10
 **/
GVariantClass
tp_variant_type_classify (const GVariantType *type)
{
  /* Same as g_variant_classify() but for a GVariantType. This returns the first
   * letter of the dbus type and cast it to an enum where elements have the
   * ascii value of the type letters. */
  return g_variant_type_peek_string (type)[0];
}

static gdouble
_tp_variant_convert_double (GVariant *variant,
    gboolean *valid)
{
  *valid = TRUE;

  switch (g_variant_classify (variant))
    {
      case G_VARIANT_CLASS_DOUBLE:
        return g_variant_get_double (variant);

      case G_VARIANT_CLASS_BYTE:
        return g_variant_get_byte (variant);

      case G_VARIANT_CLASS_UINT32:
        return g_variant_get_uint32 (variant);

      case G_VARIANT_CLASS_INT32:
        return g_variant_get_int32 (variant);

      case G_VARIANT_CLASS_INT64:
        return g_variant_get_int64 (variant);

      case G_VARIANT_CLASS_UINT64:
        return g_variant_get_uint64 (variant);

      default:
        break;
    }

  *valid = FALSE;
  return 0.0;
}

static gint32
_tp_variant_convert_int32 (GVariant *variant,
    gboolean *valid)
{
  gint64 i;
  guint64 u;

  *valid = TRUE;

  switch (g_variant_classify (variant))
    {
      case G_VARIANT_CLASS_BYTE:
        return g_variant_get_byte (variant);

      case G_VARIANT_CLASS_UINT32:
        u = g_variant_get_uint32 (variant);
        if (G_LIKELY (u <= G_MAXINT32))
          return u;
        break;

      case G_VARIANT_CLASS_INT32:
        return g_variant_get_int32 (variant);

      case G_VARIANT_CLASS_INT64:
        i = g_variant_get_int64 (variant);
        if (G_LIKELY (i >= G_MININT32 && i <= G_MAXINT32))
          return i;
        break;

      case G_VARIANT_CLASS_UINT64:
        u = g_variant_get_uint64 (variant);
        if (G_LIKELY (u <= G_MAXINT32))
          return u;
        break;

      default:
        break;
    }

  *valid = FALSE;
  return 0;
}

static gint64
_tp_variant_convert_int64 (GVariant *variant,
    gboolean *valid)
{
  guint64 u;

  *valid = TRUE;

  switch (g_variant_classify (variant))
    {
      case G_VARIANT_CLASS_BYTE:
        return g_variant_get_byte (variant);

      case G_VARIANT_CLASS_UINT32:
        return g_variant_get_uint32 (variant);

      case G_VARIANT_CLASS_INT32:
        return g_variant_get_int32 (variant);

      case G_VARIANT_CLASS_INT64:
        return g_variant_get_int64 (variant);

      case G_VARIANT_CLASS_UINT64:
        u = g_variant_get_uint64 (variant);
        if (G_LIKELY (u <= G_MAXINT64))
          return u;
        break;

      default:
        break;
    }

  *valid = FALSE;
  return 0;
}

static guint32
_tp_variant_convert_uint32 (GVariant *variant,
    gboolean *valid)
{
  gint64 i;
  guint64 u;

  *valid = TRUE;

  switch (g_variant_classify (variant))
    {
      case G_VARIANT_CLASS_BYTE:
        return g_variant_get_byte (variant);

      case G_VARIANT_CLASS_UINT32:
        return g_variant_get_uint32 (variant);

      case G_VARIANT_CLASS_INT32:
        i = g_variant_get_int32 (variant);
        if (G_LIKELY (i >= 0))
          return i;
        break;

      case G_VARIANT_CLASS_INT64:
        i = g_variant_get_int64 (variant);
        if (G_LIKELY (i >= 0 && i <= G_MAXUINT32))
          return i;
        break;

      case G_VARIANT_CLASS_UINT64:
        u = g_variant_get_uint64 (variant);
        if (G_LIKELY (u <= G_MAXUINT32))
          return u;
        break;

      default:
        break;
    }

  *valid = FALSE;
  return 0;
}

static guint64
_tp_variant_convert_uint64 (GVariant *variant,
    gboolean *valid)
{
  gint64 tmp;

  *valid = TRUE;

  switch (g_variant_classify (variant))
    {
      case G_VARIANT_CLASS_BYTE:
        return g_variant_get_byte (variant);

      case G_VARIANT_CLASS_UINT32:
        return g_variant_get_uint32 (variant);

      case G_VARIANT_CLASS_INT32:
        tmp = g_variant_get_int32 (variant);
        if (G_LIKELY (tmp >= 0))
          return tmp;
        break;

      case G_VARIANT_CLASS_INT64:
        tmp = g_variant_get_int64 (variant);
        if (G_LIKELY (tmp >= 0))
          return tmp;
        break;

      case G_VARIANT_CLASS_UINT64:
        return g_variant_get_uint64 (variant);

      default:
        break;
    }

  *valid = FALSE;
  return 0;
}

/**
 * tp_variant_convert:
 * @variant: (transfer full): a #GVariant to convert
 * @type: a #GVariantType @variant must be converted to
 *
 * Convert the type of @variant to @type if possible. This takes ownership of
 * @variant. If no conversion is needed, simply return @variant. If conversion
 * is not possible, %NULL is returned.
 *
 * Returns: (transfer full): a new #GVariant owned by the caller.
 * Since: 0.19.10
 **/
GVariant *
tp_variant_convert (GVariant *variant,
    const GVariantType *type)
{
  GVariant *ret = NULL;
  gboolean valid;

  if (variant == NULL)
    return NULL;

  g_variant_ref_sink (variant);

  if (g_variant_is_of_type (variant, type))
    return variant;

  switch (tp_variant_type_classify (type))
    {
      #define CASE(type) \
        { \
          g##type tmp = _tp_variant_convert_##type (variant, &valid); \
          if (valid) \
            ret = g_variant_new_##type (tmp); \
        }
      case G_VARIANT_CLASS_DOUBLE:
        CASE (double);
        break;

      case G_VARIANT_CLASS_INT32:
        CASE (int32);
        break;

      case G_VARIANT_CLASS_INT64:
        CASE (int64);
        break;

      case G_VARIANT_CLASS_UINT32:
        CASE (uint32);
        break;

      case G_VARIANT_CLASS_UINT64:
        CASE (uint64);
        break;

      default:
        break;
      #undef CASE
    }

  g_variant_unref (variant);

  return (ret != NULL) ? g_variant_ref_sink (ret) : NULL;
}

/**
 * tp_vardict_get_string:
 * @variant: a #GVariant of type %G_VARIANT_TYPE_VARDICT
 * @key: The key to look up
 *
 * If a value for @key in @variant is present and is a string, return it.
 *
 * Otherwise return %NULL.
 *
 * The returned value is not copied, and is only valid as long as @variant is
 * kept. Copy it with g_strdup() if you need to keep it for longer.
 *
 * Returns: (transfer none) (allow-none): the string value of @key, or %NULL
 * Since: 0.19.10
 */
const gchar *
tp_vardict_get_string (GVariant *variant,
    const gchar *key)
{
  const gchar *ret;

  g_return_val_if_fail (variant != NULL, NULL);
  g_return_val_if_fail (key != NULL, NULL);
  g_return_val_if_fail (g_variant_is_of_type (variant, G_VARIANT_TYPE_VARDICT), NULL);

  if (!g_variant_lookup (variant, key, "&s", &ret))
    return NULL;

  return ret;
}

/**
 * tp_vardict_get_object_path:
 * @variant: a #GVariant of type %G_VARIANT_TYPE_VARDICT
 * @key: The key to look up
 *
 * If a value for @key in @variant is present and is an object path, return it.
 *
 * Otherwise return %NULL.
 *
 * The returned value is not copied, and is only valid as long as @variant is
 * kept. Copy it with g_strdup() if you need to keep it for longer.
 *
 * Returns: (transfer none) (allow-none): the object path value of @key, or
 *  %NULL
 * Since: 0.19.10
 */
const gchar *
tp_vardict_get_object_path (GVariant *variant,
    const gchar *key)
{
  const gchar *ret;

  g_return_val_if_fail (variant != NULL, NULL);
  g_return_val_if_fail (key != NULL, NULL);
  g_return_val_if_fail (g_variant_is_of_type (variant, G_VARIANT_TYPE_VARDICT), NULL);

  if (!g_variant_lookup (variant, key, "&o", &ret))
    return NULL;

  return ret;
}

/**
 * tp_vardict_get_boolean:
 * @variant: a #GVariant of type %G_VARIANT_TYPE_VARDICT
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location to store %TRUE if the key actually
 *  exists and has a boolean value
 *
 * If a value for @key in @variant is present and boolean, return it,
 * and set *@valid to %TRUE if @valid is not %NULL.
 *
 * Otherwise return %FALSE, and set *@valid to %FALSE if @valid is not %NULL.
 *
 * Returns: a boolean value for @key
 * Since: 0.19.10
 */
gboolean
tp_vardict_get_boolean (GVariant *variant,
    const gchar *key,
    gboolean *valid)
{
  gboolean ret;

  g_return_val_if_fail (variant != NULL, FALSE);
  g_return_val_if_fail (key != NULL, FALSE);
  g_return_val_if_fail (g_variant_is_of_type (variant, G_VARIANT_TYPE_VARDICT), FALSE);

  if (!g_variant_lookup (variant, key, "b", &ret))
    {
      if (valid != NULL)
        *valid = FALSE;

      return FALSE;
    }

  if (valid != NULL)
    *valid = TRUE;

  return ret;
}

#define IMPLEMENT(type) \
  g##type \
  tp_vardict_get_##type (GVariant *variant, \
      const gchar *key, \
      gboolean *valid) \
  { \
    g##type ret = 0; \
    gboolean ret_valid = FALSE; \
    GVariant *value; \
    \
    g_return_val_if_fail (variant != NULL, 0); \
    g_return_val_if_fail (key != NULL, 0); \
    g_return_val_if_fail (g_variant_is_of_type (variant, G_VARIANT_TYPE_VARDICT), 0); \
    \
    value = g_variant_lookup_value (variant, key, NULL); \
    if (value != NULL) \
      { \
        ret = _tp_variant_convert_##type (value, &ret_valid); \
        g_variant_unref (value); \
      } \
    \
    if (valid != NULL) \
      *valid = ret_valid; \
    \
    return ret; \
  }

/**
 * tp_vardict_get_double:
 * @variant: a #GVariant of type %G_VARIANT_TYPE_VARDICT
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location in which to store %TRUE on success
 * or %FALSE on failure
 *
 * If a value for @key in @variant is present and has any numeric type used by
 * GVariant (gint32, guint32, gint64, guint64 or gdouble),
 * return it as a double, and if @valid is not %NULL, set *@valid to %TRUE.
 *
 * Otherwise, return 0.0, and if @valid is not %NULL, set *@valid to %FALSE.
 *
 * Returns: the double precision floating-point value of @key, or 0.0
 * Since: 0.19.10
 */
IMPLEMENT (double)

/**
 * tp_vardict_get_int32:
 * @variant: a #GVariant of type %G_VARIANT_TYPE_VARDICT
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location in which to store %TRUE on success
 * or %FALSE on failure
 *
 * If a value for @key in @variant is present, has an integer type used by
 * GVariant (gint32, guint32, gint64 or guint64) and fits in the
 * range of a gint32, return it, and if @valid is not %NULL, set *@valid to
 * %TRUE.
 *
 * Otherwise, return 0, and if @valid is not %NULL, set *@valid to %FALSE.
 *
 * Returns: the 32-bit signed integer value of @key, or 0
 * Since: 0.19.10
 */
IMPLEMENT (int32)

/**
 * tp_vardict_get_int64:
 * @variant: a #GVariant of type %G_VARIANT_TYPE_VARDICT
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location in which to store %TRUE on success
 * or %FALSE on failure
 *
 * If a value for @key in @variant is present, has an integer type used by
 * GVariant (gint32, guint32, gint64 or guint64) and fits in the
 * range of a gint64, return it, and if @valid is not %NULL, set *@valid to
 * %TRUE.
 *
 * Otherwise, return 0, and if @valid is not %NULL, set *@valid to %FALSE.
 *
 * Returns: the 64-bit signed integer value of @key, or 0
 * Since: 0.19.10
 */
IMPLEMENT (int64)

/**
 * tp_vardict_get_uint32:
 * @variant: a #GVariant of type %G_VARIANT_TYPE_VARDICT
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location in which to store %TRUE on success
 * or %FALSE on failure
 *
 * If a value for @key in @variant is present, has an integer type used by
 * GVariant (gint32, guint32, gint64 or guint64) and fits in the
 * range of a guint32, return it, and if @valid is not %NULL, set *@valid to
 * %TRUE.
 *
 * Otherwise, return 0, and if @valid is not %NULL, set *@valid to %FALSE.
 *
 * Returns: the 32-bit unsigned integer value of @key, or 0
 * Since: 0.19.10
 */
IMPLEMENT (uint32)

/**
 * tp_vardict_get_uint64:
 * @variant: a #GVariant of type %G_VARIANT_TYPE_VARDICT
 * @key: The key to look up
 * @valid: (out): Either %NULL, or a location in which to store %TRUE on success
 * or %FALSE on failure
 *
 * If a value for @key in @variant is present, has an integer type used by
 * GVariant (gint32, guint32, gint64 or guint64) and is non-negative,
 * return it, and if @valid is not %NULL, set *@valid to %TRUE.
 *
 * Otherwise, return 0, and if @valid is not %NULL, set *@valid to %FALSE.
 *
 * Returns: the 64-bit unsigned integer value of @key, or 0
 * Since: 0.19.10
 */
IMPLEMENT (uint64)

#undef IMPLEMENT
