/*
 * variant-util.h - Header for GVariant utilities
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

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_VARIANT_UTIL_H__
#define __TP_VARIANT_UTIL_H__

#include <glib.h>
#include <gio/gio.h>

G_BEGIN_DECLS

GVariantClass tp_variant_type_classify (const GVariantType *type);

GVariant *tp_variant_convert (GVariant *variant,
    const GVariantType *type);

const gchar *tp_vardict_get_string (GVariant *variant,
    const gchar *key);
const gchar *tp_vardict_get_object_path (GVariant *variant,
    const gchar *key);
gboolean tp_vardict_get_boolean (GVariant *variant,
    const gchar *key,
    gboolean *valid);
gdouble tp_vardict_get_double (GVariant *variant,
    const gchar *key,
    gboolean *valid);
gint32 tp_vardict_get_int32 (GVariant *variant,
    const gchar *key,
    gboolean *valid);
gint64 tp_vardict_get_int64 (GVariant *variant,
    const gchar *key,
    gboolean *valid);
guint32 tp_vardict_get_uint32 (GVariant *variant,
    const gchar *key,
    gboolean *valid);
guint64 tp_vardict_get_uint64 (GVariant *variant,
    const gchar *key,
    gboolean *valid);

G_END_DECLS

#endif /* __TP_VARIANT_UTIL_H__ */
