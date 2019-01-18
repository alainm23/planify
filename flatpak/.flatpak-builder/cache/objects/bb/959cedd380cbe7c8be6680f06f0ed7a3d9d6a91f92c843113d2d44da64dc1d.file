/*
 * util.h - Headers for telepathy-glib utility functions
 *
 * Copyright © 2006-2010 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright © 2006-2008 Nokia Corporation
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

#ifndef __TP_UTIL_H__
#define __TP_UTIL_H__
#define __TP_IN_UTIL_H__

#include <gio/gio.h>

#include <telepathy-glib/defs.h>
#include <telepathy-glib/verify.h>

#define tp_verify_statement(R) ((void) tp_verify_true (R))

G_BEGIN_DECLS

gboolean tp_g_ptr_array_contains (GPtrArray *haystack, gpointer needle);
void tp_g_ptr_array_extend (GPtrArray *target, GPtrArray *source);

#ifndef __GI_SCANNER__
/* Functions with _new in their names confuse the g-i scanner, but these
 * are all (skip)'d anyway. */

GValue *tp_g_value_slice_new (GType type) G_GNUC_WARN_UNUSED_RESULT;

GValue *tp_g_value_slice_new_boolean (gboolean b) G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_int (gint n) G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_int64 (gint64 n) G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_byte (guchar n) G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_uint (guint n) G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_uint64 (guint64 n) G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_double (double d) G_GNUC_WARN_UNUSED_RESULT;

GValue *tp_g_value_slice_new_string (const gchar *string)
  G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_static_string (const gchar *string)
  G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_take_string (gchar *string)
  G_GNUC_WARN_UNUSED_RESULT;

GValue *tp_g_value_slice_new_boxed (GType type, gconstpointer p)
  G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_static_boxed (GType type, gconstpointer p)
  G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_g_value_slice_new_take_boxed (GType type, gpointer p)
  G_GNUC_WARN_UNUSED_RESULT;

#endif

void tp_g_value_slice_free (GValue *value);

GValue *tp_g_value_slice_dup (const GValue *value) G_GNUC_WARN_UNUSED_RESULT;

void tp_g_hash_table_update (GHashTable *target, GHashTable *source,
    GBoxedCopyFunc key_dup, GBoxedCopyFunc value_dup);

/* See https://bugzilla.gnome.org/show_bug.cgi?id=399880 for glib inclusion */
static inline gboolean
tp_str_empty (const gchar *s)
{
  return (s == NULL || s[0] == '\0');
}

/* See https://bugzilla.gnome.org/show_bug.cgi?id=685878 for glib inclusion */
gboolean tp_strdiff (const gchar *left, const gchar *right);

gpointer tp_mixin_offset_cast (gpointer instance, guint offset);
guint tp_mixin_instance_get_offset (gpointer instance, GQuark quark);
guint tp_mixin_class_get_offset (gpointer klass, GQuark quark);

gchar *tp_escape_as_identifier (const gchar *name) G_GNUC_WARN_UNUSED_RESULT;

/* See https://bugzilla.gnome.org/show_bug.cgi?id=685880 for glib inclusion */
gboolean tp_strv_contains (const gchar * const *strv, const gchar *str);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_22_FOR(g_key_file_get_int64)
gint64 tp_g_key_file_get_int64 (GKeyFile *key_file, const gchar *group_name,
    const gchar *key, GError **error);
_TP_DEPRECATED_IN_0_22_FOR(g_key_file_get_uint64)
guint64 tp_g_key_file_get_uint64 (GKeyFile *key_file, const gchar *group_name,
    const gchar *key, GError **error);
#endif

/* g_signal_connect_object() has been fixed in GLib 2.36, we can deprecate this
 * once we depend on that version. */
gulong tp_g_signal_connect_object (gpointer instance,
    const gchar *detailed_signal, GCallback c_handler, gpointer gobject,
    GConnectFlags connect_flags);

GValueArray *tp_value_array_build (gsize length,
  GType type,
  ...) G_GNUC_WARN_UNUSED_RESULT;
void tp_value_array_unpack (GValueArray *array,
    gsize len,
    ...);

/* Work around GLib having deprecated something that is part of our API. */
_TP_AVAILABLE_IN_0_24
void tp_value_array_free (GValueArray *va);
#if TP_VERSION_MAX_ALLOWED >= TP_VERSION_0_24
#define tp_value_array_free(va) _tp_value_array_free_inline (va)
#ifndef __GTK_DOC_IGNORE__ /* gtk-doc can't parse this */
static inline void
_tp_value_array_free_inline (GValueArray *va)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  g_value_array_free (va);
  G_GNUC_END_IGNORE_DEPRECATIONS
}
#endif
#endif

/* See https://bugzilla.gnome.org/show_bug.cgi?id=680813 for glib inclusion */
typedef struct _TpWeakRef TpWeakRef;
TpWeakRef *tp_weak_ref_new (gpointer object,
    gpointer user_data,
    GDestroyNotify destroy) G_GNUC_WARN_UNUSED_RESULT;
gpointer tp_weak_ref_get_user_data (TpWeakRef *self) G_GNUC_WARN_UNUSED_RESULT;
gpointer tp_weak_ref_dup_object (TpWeakRef *self) G_GNUC_WARN_UNUSED_RESULT;
void tp_weak_ref_destroy (TpWeakRef *self);

#define tp_clear_pointer(pp, destroy) \
  G_STMT_START \
    { \
      gpointer _tp_clear_pointer_tmp; \
      \
      _tp_clear_pointer_tmp = *(pp); \
      *(pp) = NULL; \
      \
      if (_tp_clear_pointer_tmp != NULL) \
        (destroy) (_tp_clear_pointer_tmp); \
    } \
  G_STMT_END

#define tp_clear_object(op) tp_clear_pointer ((op), g_object_unref)

#define tp_clear_boxed(gtype, pp) \
  G_STMT_START \
    { \
      gpointer _tp_clear_boxed_tmp; \
      \
      _tp_clear_boxed_tmp = *(pp); \
      *(pp) = NULL; \
      \
      if (_tp_clear_boxed_tmp != NULL) \
        g_boxed_free (gtype, _tp_clear_boxed_tmp); \
    } \
  G_STMT_END

void tp_simple_async_report_success_in_idle (GObject *source,
    GAsyncReadyCallback callback, gpointer user_data, gpointer source_tag);

gint64 tp_user_action_time_from_x11 (guint32 x11_time);
gboolean tp_user_action_time_should_present (gint64 user_action_time,
    guint32 *x11_time);

/* See https://bugzilla.gnome.org/show_bug.cgi?id=610969 for glib inclusion */
gchar *tp_utf8_make_valid (const gchar *name);

G_END_DECLS

#undef  __TP_IN_UTIL_H__
#endif /* __TP_UTIL_H__ */
