/*
 * presence-mixin.h - Header for TpPresenceMixin
 * Copyright (C) 2007 Collabora Ltd.
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

#ifndef __TP_PRESENCE_MIXIN_H__
#define __TP_PRESENCE_MIXIN_H__

#include <telepathy-glib/enums.h>
#include <telepathy-glib/handle.h>
#include <telepathy-glib/svc-connection.h>
#include "util.h"

G_BEGIN_DECLS

typedef struct _TpPresenceStatusOptionalArgumentSpec
    TpPresenceStatusOptionalArgumentSpec;
typedef struct _TpPresenceStatusSpec TpPresenceStatusSpec;
typedef struct _TpPresenceStatusSpecPrivate TpPresenceStatusSpecPrivate;

struct _TpPresenceStatusOptionalArgumentSpec {
    const gchar *name;
    const gchar *dtype;

    /*<private>*/
    gpointer _future1;
    gpointer _future2;
};

struct _TpPresenceStatusSpec {
    const gchar *name;
    TpConnectionPresenceType presence_type;
    gboolean self;
    const TpPresenceStatusOptionalArgumentSpec *optional_arguments;

    /*<private>*/
    gpointer _future1;
    TpPresenceStatusSpecPrivate *priv;
};

_TP_AVAILABLE_IN_0_24
TpConnectionPresenceType tp_presence_status_spec_get_presence_type (
    const TpPresenceStatusSpec *self);

_TP_AVAILABLE_IN_0_24
const gchar *tp_presence_status_spec_get_name (
    const TpPresenceStatusSpec *self);

_TP_AVAILABLE_IN_0_24
gboolean tp_presence_status_spec_can_set_on_self (
    const TpPresenceStatusSpec *self);

_TP_AVAILABLE_IN_0_24
gboolean tp_presence_status_spec_has_message (
    const TpPresenceStatusSpec *self);

_TP_AVAILABLE_IN_0_24
GType tp_presence_status_spec_get_type (void);

_TP_AVAILABLE_IN_0_24
TpPresenceStatusSpec *tp_presence_status_spec_new (const gchar *name,
    TpConnectionPresenceType type,
    gboolean can_set_on_self,
    gboolean has_message);

_TP_AVAILABLE_IN_0_24
TpPresenceStatusSpec *tp_presence_status_spec_copy (
    const TpPresenceStatusSpec *self);

_TP_AVAILABLE_IN_0_24
void tp_presence_status_spec_free (TpPresenceStatusSpec *self);

typedef struct _TpPresenceStatus TpPresenceStatus;

struct _TpPresenceStatus {
    guint index;
    GHashTable *optional_arguments;

    /*<private>*/
    gpointer _future1;
    gpointer _future2;
};

TpPresenceStatus *tp_presence_status_new (guint which,
    GHashTable *optional_arguments) G_GNUC_WARN_UNUSED_RESULT;
void tp_presence_status_free (TpPresenceStatus *status);

typedef gboolean (*TpPresenceMixinStatusAvailableFunc) (GObject *obj,
    guint which);

typedef GHashTable *(*TpPresenceMixinGetContactStatusesFunc) (GObject *obj,
    const GArray *contacts, GError **error);

typedef gboolean (*TpPresenceMixinSetOwnStatusFunc) (GObject *obj,
    const TpPresenceStatus *status, GError **error);

typedef guint (*TpPresenceMixinGetMaximumStatusMessageLengthFunc) (
    GObject *obj);

typedef struct _TpPresenceMixinClass TpPresenceMixinClass;
typedef struct _TpPresenceMixinClassPrivate TpPresenceMixinClassPrivate;
typedef struct _TpPresenceMixin TpPresenceMixin;
typedef struct _TpPresenceMixinPrivate TpPresenceMixinPrivate;

struct _TpPresenceMixinClass {
    TpPresenceMixinStatusAvailableFunc status_available;
    TpPresenceMixinGetContactStatusesFunc get_contact_statuses;
    TpPresenceMixinSetOwnStatusFunc set_own_status;

    const TpPresenceStatusSpec *statuses;

    /*<private>*/
    TpPresenceMixinClassPrivate *priv;

    /*<public>*/
    TpPresenceMixinGetMaximumStatusMessageLengthFunc get_maximum_status_message_length;

    /*<private>*/
    gpointer _future1;
    gpointer _future2;
    gpointer _future3;
};

struct _TpPresenceMixin {
  /*<private>*/
  TpPresenceMixinPrivate *priv;
};

/* TYPE MACROS */
#define TP_PRESENCE_MIXIN_CLASS_OFFSET_QUARK \
  (tp_presence_mixin_class_get_offset_quark ())
#define TP_PRESENCE_MIXIN_CLASS_OFFSET(o) \
  tp_mixin_class_get_offset (o, TP_PRESENCE_MIXIN_CLASS_OFFSET_QUARK)
#define TP_PRESENCE_MIXIN_CLASS(o) \
  ((TpPresenceMixinClass *) tp_mixin_offset_cast (o, \
    TP_PRESENCE_MIXIN_CLASS_OFFSET (o)))

#define TP_PRESENCE_MIXIN_OFFSET_QUARK (tp_presence_mixin_get_offset_quark ())
#define TP_PRESENCE_MIXIN_OFFSET(o) \
  tp_mixin_instance_get_offset (o, TP_PRESENCE_MIXIN_OFFSET_QUARK)
#define TP_PRESENCE_MIXIN(o) \
  ((TpPresenceMixin *) tp_mixin_offset_cast (o, TP_PRESENCE_MIXIN_OFFSET (o)))

GQuark tp_presence_mixin_class_get_offset_quark (void);
GQuark tp_presence_mixin_get_offset_quark (void);

void tp_presence_mixin_class_init (GObjectClass *obj_cls, glong offset,
    TpPresenceMixinStatusAvailableFunc status_available,
    TpPresenceMixinGetContactStatusesFunc get_contact_statuses,
    TpPresenceMixinSetOwnStatusFunc set_own_status,
    const TpPresenceStatusSpec *statuses);

void tp_presence_mixin_init (GObject *obj, glong offset);
void tp_presence_mixin_finalize (GObject *obj);

void tp_presence_mixin_emit_presence_update (GObject *obj,
    GHashTable *contact_presences);
void tp_presence_mixin_emit_one_presence_update (GObject *obj,
    TpHandle handle, const TpPresenceStatus *status);

void tp_presence_mixin_iface_init (gpointer g_iface, gpointer iface_data);
void tp_presence_mixin_simple_presence_iface_init (gpointer g_iface, gpointer iface_data);
void tp_presence_mixin_simple_presence_init_dbus_properties (GObjectClass *cls);

void tp_presence_mixin_simple_presence_register_with_contacts_mixin (
    GObject *obj);

G_END_DECLS

#endif /* #ifndef __TP_PRESENCE_MIXIN_H__ */
