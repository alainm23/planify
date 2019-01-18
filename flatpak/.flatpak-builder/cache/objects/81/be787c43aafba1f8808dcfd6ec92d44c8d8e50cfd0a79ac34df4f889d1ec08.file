/*
 * dbus.h - Header for D-Bus utilities
 *
 * Copyright (C) 2005-2009 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2005-2009 Nokia Corporation
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

#ifndef __TELEPATHY_DBUS_H__
#define __TELEPATHY_DBUS_H__
#define __TP_IN_DBUS_H__

#include <telepathy-glib/defs.h>
#include <telepathy-glib/dbus-daemon.h>

#include <telepathy-glib/_gen/genums.h>

G_BEGIN_DECLS

void tp_dbus_g_method_return_not_implemented (DBusGMethodInvocation *context);

typedef enum /*< flags >*/
{
  TP_DBUS_NAME_TYPE_UNIQUE = 1,
  TP_DBUS_NAME_TYPE_WELL_KNOWN = 2,
  TP_DBUS_NAME_TYPE_BUS_DAEMON = 4,
  TP_DBUS_NAME_TYPE_NOT_BUS_DAEMON = TP_DBUS_NAME_TYPE_UNIQUE | TP_DBUS_NAME_TYPE_WELL_KNOWN,
  TP_DBUS_NAME_TYPE_ANY = TP_DBUS_NAME_TYPE_NOT_BUS_DAEMON | TP_DBUS_NAME_TYPE_BUS_DAEMON
} TpDBusNameType;

gboolean tp_dbus_check_valid_bus_name (const gchar *name,
    TpDBusNameType allow_types, GError **error);

gboolean tp_dbus_check_valid_interface_name (const gchar *name,
    GError **error);

gboolean tp_dbus_check_valid_member_name (const gchar *name,
    GError **error);

gboolean tp_dbus_check_valid_object_path (const gchar *path,
    GError **error);

/* The scanner warns about these, but they're skipped anyway.
 * See GNOME bug#656743 */
#ifndef __GI_SCANNER__
GValue *tp_g_value_slice_new_bytes (guint length, gconstpointer bytes)
  G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_take_bytes (GArray *bytes)
  G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_object_path (const gchar *path)
  G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_static_object_path (const gchar *path)
  G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_take_object_path (gchar *path)
  G_GNUC_WARN_UNUSED_RESULT;
#endif /* __GI_SCANNER__ */

#define tp_asv_size(asv) _tp_asv_size_inline (asv)

static inline guint
_tp_asv_size_inline (const GHashTable *asv)
{
  /* The empty comment here is to stop gtkdoc thinking g_hash_table_size is
   * a declaration. */
  return g_hash_table_size /* */ ((GHashTable *) asv);
}

GHashTable *tp_asv_new (const gchar *first_key, ...)
  G_GNUC_NULL_TERMINATED G_GNUC_WARN_UNUSED_RESULT;
gboolean tp_asv_get_boolean (const GHashTable *asv, const gchar *key,
    gboolean *valid);
void tp_asv_set_boolean (GHashTable *asv, const gchar *key, gboolean value);
gpointer tp_asv_get_boxed (const GHashTable *asv, const gchar *key,
    GType type);
void tp_asv_set_boxed (GHashTable *asv, const gchar *key, GType type,
    gconstpointer value);
void tp_asv_take_boxed (GHashTable *asv, const gchar *key, GType type,
    gpointer value);
void tp_asv_set_static_boxed (GHashTable *asv, const gchar *key, GType type,
    gconstpointer value);
const GArray *tp_asv_get_bytes (const GHashTable *asv, const gchar *key);
void tp_asv_set_bytes (GHashTable *asv, const gchar *key, guint length,
    gconstpointer bytes);
void tp_asv_take_bytes (GHashTable *asv, const gchar *key, GArray *value);
gdouble tp_asv_get_double (const GHashTable *asv, const gchar *key,
    gboolean *valid);
void tp_asv_set_double (GHashTable *asv, const gchar *key, gdouble value);
gint32 tp_asv_get_int32 (const GHashTable *asv, const gchar *key,
    gboolean *valid);
void tp_asv_set_int32 (GHashTable *asv, const gchar *key, gint32 value);
gint64 tp_asv_get_int64 (const GHashTable *asv, const gchar *key,
    gboolean *valid);
void tp_asv_set_int64 (GHashTable *asv, const gchar *key, gint64 value);
const gchar *tp_asv_get_object_path (const GHashTable *asv, const gchar *key);
void tp_asv_set_object_path (GHashTable *asv, const gchar *key,
    const gchar *value);
void tp_asv_take_object_path (GHashTable *asv, const gchar *key,
    gchar *value);
void tp_asv_set_static_object_path (GHashTable *asv, const gchar *key,
    const gchar *value);
const gchar *tp_asv_get_string (const GHashTable *asv, const gchar *key);
void tp_asv_set_string (GHashTable *asv, const gchar *key, const gchar *value);
void tp_asv_take_string (GHashTable *asv, const gchar *key, gchar *value);
void tp_asv_set_static_string (GHashTable *asv, const gchar *key,
    const gchar *value);
guint32 tp_asv_get_uint32 (const GHashTable *asv, const gchar *key,
    gboolean *valid);
void tp_asv_set_uint32 (GHashTable *asv, const gchar *key, guint32 value);
guint64 tp_asv_get_uint64 (const GHashTable *asv, const gchar *key,
    gboolean *valid);
void tp_asv_set_uint64 (GHashTable *asv, const gchar *key, guint64 value);
const GValue *tp_asv_lookup (const GHashTable *asv, const gchar *key);

const gchar * const *
/* this comment stops gtkdoc denying that this function exists */
tp_asv_get_strv (const GHashTable *asv, const gchar *key);
void tp_asv_set_strv (GHashTable *asv, const gchar *key, gchar **value);
void tp_asv_dump (GHashTable *asv);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED
DBusGConnection * tp_get_bus (void);

_TP_DEPRECATED
DBusGProxy * tp_get_bus_proxy (void);
#endif

G_END_DECLS

#undef __TP_IN_DBUS_H__
#endif /* __TELEPATHY_DBUS_H__ */
