/*
 * dbus-properties-mixin.h - D-Bus core Properties
 * Copyright (C) 2008 Collabora Ltd.
 * Copyright (C) 2008 Nokia Corporation
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

#ifndef __TP_DBUS_PROPERTIES_MIXIN_H__
#define __TP_DBUS_PROPERTIES_MIXIN_H__

#include <glib-object.h>

#include <telepathy-glib/defs.h>
#include <telepathy-glib/_gen/genums.h>

G_BEGIN_DECLS

/* ---- Semi-abstract property definition (used in TpSvc*) ---------- */

typedef enum { /*< flags >*/
    TP_DBUS_PROPERTIES_MIXIN_FLAG_READ = 1,
    TP_DBUS_PROPERTIES_MIXIN_FLAG_WRITE = 2,
    TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_CHANGED = 4,
    TP_DBUS_PROPERTIES_MIXIN_FLAG_EMITS_INVALIDATED = 8
} TpDBusPropertiesMixinFlags;

typedef struct {
    GQuark name;
    TpDBusPropertiesMixinFlags flags;
    gchar *dbus_signature;
    GType type;
    /*<private>*/
    GCallback _1;
    GCallback _2;
} TpDBusPropertiesMixinPropInfo;

typedef struct {
    GQuark dbus_interface;
    TpDBusPropertiesMixinPropInfo *props;
    /*<private>*/
    GCallback _1;
    GCallback _2;
} TpDBusPropertiesMixinIfaceInfo;

void tp_svc_interface_set_dbus_properties_info (GType g_interface,
    TpDBusPropertiesMixinIfaceInfo *info);
_TP_AVAILABLE_IN_0_16
TpDBusPropertiesMixinIfaceInfo *tp_svc_interface_get_dbus_properties_info (
    GType g_interface);

/* ---- Concrete implementation (in GObject subclasses) ------------- */

typedef void (*TpDBusPropertiesMixinGetter) (GObject *object,
    GQuark iface, GQuark name, GValue *value, gpointer getter_data);

void tp_dbus_properties_mixin_getter_gobject_properties (GObject *object,
    GQuark iface, GQuark name, GValue *value, gpointer getter_data);

typedef gboolean (*TpDBusPropertiesMixinSetter) (GObject *object,
    GQuark iface, GQuark name, const GValue *value, gpointer setter_data,
    GError **error);

gboolean tp_dbus_properties_mixin_setter_gobject_properties (GObject *object,
    GQuark iface, GQuark name, const GValue *value, gpointer setter_data,
    GError **error);

typedef struct {
    const gchar *name;
    gpointer getter_data;
    gpointer setter_data;
    /*<private>*/
    GCallback _1;
    GCallback _2;
    gpointer mixin_priv;
} TpDBusPropertiesMixinPropImpl;

typedef struct {
    const gchar *name;
    TpDBusPropertiesMixinGetter getter;
    TpDBusPropertiesMixinSetter setter;
    TpDBusPropertiesMixinPropImpl *props;
    /*<private>*/
    GCallback _1;
    GCallback _2;
    gpointer mixin_next;
    gpointer mixin_priv;
} TpDBusPropertiesMixinIfaceImpl;

struct _TpDBusPropertiesMixinClass {
    TpDBusPropertiesMixinIfaceImpl *interfaces;
    /*<private>*/
    gpointer _1;
    gpointer _2;
    gpointer _3;
    gpointer _4;
    gpointer _5;
    gpointer _6;
    gpointer _7;
};

typedef struct _TpDBusPropertiesMixinClass TpDBusPropertiesMixinClass;

void tp_dbus_properties_mixin_class_init (GObjectClass *cls,
    gsize offset);

void tp_dbus_properties_mixin_implement_interface (GObjectClass *cls,
    GQuark iface, TpDBusPropertiesMixinGetter getter,
    TpDBusPropertiesMixinSetter setter, TpDBusPropertiesMixinPropImpl *props);

void tp_dbus_properties_mixin_iface_init (gpointer g_iface,
    gpointer iface_data);

gboolean tp_dbus_properties_mixin_get (GObject *self,
    const gchar *interface_name, const gchar *property_name,
    GValue *value, GError **error);
_TP_AVAILABLE_IN_0_16
gboolean tp_dbus_properties_mixin_set (
    GObject *self,
    const gchar *interface_name,
    const gchar *property_name,
    const GValue *value,
    GError **error);

_TP_AVAILABLE_IN_0_22
GHashTable *tp_dbus_properties_mixin_dup_all (GObject *self,
    const gchar *interface_name);

GHashTable *tp_dbus_properties_mixin_make_properties_hash (
    GObject *object, const gchar *first_interface,
    const gchar *first_property, ...)
  G_GNUC_NULL_TERMINATED G_GNUC_WARN_UNUSED_RESULT;

void tp_dbus_properties_mixin_fill_properties_hash (GObject *object,
    GHashTable *table,
    const gchar *first_interface,
    const gchar *first_property,
    ...)
  G_GNUC_NULL_TERMINATED;

_TP_AVAILABLE_IN_0_16
void tp_dbus_properties_mixin_emit_properties_changed (
    GObject *object,
    const gchar *interface_name,
    const gchar * const *properties);

_TP_AVAILABLE_IN_0_16
void tp_dbus_properties_mixin_emit_properties_changed_varargs (
    GObject *object,
    const gchar *interface_name,
    ...)
  G_GNUC_NULL_TERMINATED;

G_END_DECLS

#endif /* #ifndef __TP_DBUS_PROPERTIES_MIXIN_H__ */
