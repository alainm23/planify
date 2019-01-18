/*
 * contacts-mixin.h - Header for TpContactsMixin
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

#ifndef __TP_CONTACTS_MIXIN_H__
#define __TP_CONTACTS_MIXIN_H__

#include <telepathy-glib/svc-connection.h>
#include <telepathy-glib/handle-repo.h>

#include "util.h"

G_BEGIN_DECLS

typedef struct _TpContactsMixinClass TpContactsMixinClass;
typedef struct _TpContactsMixinClassPrivate TpContactsMixinClassPrivate;
typedef struct _TpContactsMixin TpContactsMixin;
typedef struct _TpContactsMixinPrivate TpContactsMixinPrivate;

/**
 * TpContactsMixinFillContactAttributesFunc:
 * @obj: An object implementing the Contacts interface with this mixin
 * @contacts: The contact handles for which attributes are requested
 * @attributes_hash: hash of handle => hash of attributes, containing all the
 * contacts in the contacts array
 *
 * This function is called to supply contact attributes pertaining to
 * a particular interface, for a list of contacts.
 * All the handles in @contacts are guaranteed to be valid and
 * referenced.
 */
typedef void (*TpContactsMixinFillContactAttributesFunc) (GObject *obj,
  const GArray *contacts, GHashTable *attributes_hash);

/**
 * TpContactsMixinClass:
 *
 * Structure to be included in the class structure of objects that
 * use this mixin. Initialize it with tp_contacts_mixin_class_init().
 *
 * There are no public fields.
 */
struct _TpContactsMixinClass {
    /*<private>*/
    TpContactsMixinClassPrivate *priv;
};

/**
 * TpContactsMixin:
 *
 * Structure to be included in the instance structure of objects that
 * use this mixin. Initialize it with tp_contacts_mixin_init().
 *
 * There are no public fields.
 */
struct _TpContactsMixin {
  /*<private>*/
  TpContactsMixinPrivate *priv;
};

/* TYPE MACROS */
#define TP_CONTACTS_MIXIN_CLASS_OFFSET_QUARK \
  (tp_contacts_mixin_class_get_offset_quark ())
#define TP_CONTACTS_MIXIN_CLASS_OFFSET(o) \
  tp_mixin_class_get_offset (o, TP_CONTACTS_MIXIN_CLASS_OFFSET_QUARK)
#define TP_CONTACTS_MIXIN_CLASS(o) \
  ((TpContactsMixinClass *) tp_mixin_offset_cast (o, \
    TP_CONTACTS_MIXIN_CLASS_OFFSET (o)))

#define TP_CONTACTS_MIXIN_OFFSET_QUARK (tp_contacts_mixin_get_offset_quark ())
#define TP_CONTACTS_MIXIN_OFFSET(o) \
  tp_mixin_instance_get_offset (o, TP_CONTACTS_MIXIN_OFFSET_QUARK)
#define TP_CONTACTS_MIXIN(o) \
  ((TpContactsMixin *) tp_mixin_offset_cast (o, TP_CONTACTS_MIXIN_OFFSET (o)))

GQuark tp_contacts_mixin_class_get_offset_quark (void);
GQuark tp_contacts_mixin_get_offset_quark (void);

void tp_contacts_mixin_class_init (GObjectClass *obj_cls, glong offset);

void tp_contacts_mixin_init (GObject *obj, gsize offset);
void tp_contacts_mixin_finalize (GObject *obj);

void tp_contacts_mixin_iface_init (gpointer g_iface, gpointer iface_data);

void tp_contacts_mixin_add_contact_attributes_iface (GObject *obj,
    const gchar *interface,
    TpContactsMixinFillContactAttributesFunc fill_contact_attributes);

void tp_contacts_mixin_set_contact_attribute (GHashTable *contact_attributes,
    TpHandle handle, const gchar *attribute, GValue *value);

GHashTable *tp_contacts_mixin_get_contact_attributes (GObject *obj,
    const GArray *handles, const gchar **interfaces, const gchar **assumed_interfaces,
    const gchar *sender);

G_END_DECLS

#endif /* #ifndef __TP_CONTACTS_MIXIN_H__ */
