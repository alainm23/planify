/*
 * base-connection-manager.h - Header for TpBaseConnectionManager
 *
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

#ifndef __TP_BASE_CONNECTION_MANAGER_H__
#define __TP_BASE_CONNECTION_MANAGER_H__

#include <dbus/dbus-glib.h>
#include <glib-object.h>

#include <telepathy-glib/base-connection.h>
#include <telepathy-glib/base-protocol.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/proxy.h>
#include <telepathy-glib/svc-connection-manager.h>

G_BEGIN_DECLS

void tp_cm_param_setter_offset (const TpCMParamSpec *paramspec,
    const GValue *value, gpointer params);

typedef struct {
    const gchar *name;
    const TpCMParamSpec *parameters;
    gpointer (*params_new) (void);
    void (*params_free) (gpointer);
    TpCMParamSetter set_param;

    /*<private>*/
    gpointer _future1;
    gpointer _future2;
    gpointer _future3;
} TpCMProtocolSpec;

typedef struct _TpBaseConnectionManager TpBaseConnectionManager;
typedef struct _TpBaseConnectionManagerPrivate TpBaseConnectionManagerPrivate;
typedef struct _TpBaseConnectionManagerClass TpBaseConnectionManagerClass;
typedef struct _TpBaseConnectionManagerClassPrivate
    TpBaseConnectionManagerClassPrivate;

typedef TpBaseConnection *(*TpBaseConnectionManagerNewConnFunc)(
    TpBaseConnectionManager *self, const gchar *proto,
    TpIntset *params_present, void *parsed_params, GError **error);

typedef GPtrArray * (*TpBaseConnectionManagerGetInterfacesFunc) (
    TpBaseConnectionManager *self);

struct _TpBaseConnectionManagerClass {
    GObjectClass parent_class;

    const char *cm_dbus_name;
    /*<private>*/
    const TpCMProtocolSpec *_TP_SEAL (protocol_params);
    TpBaseConnectionManagerNewConnFunc _TP_SEAL (new_connection);
    /*< public >*/

    /*<private>*/
    const gchar * const *_TP_SEAL (interfaces);
    /*<public>*/
    TpBaseConnectionManagerGetInterfacesFunc get_interfaces;

    /*<private>*/
    gpointer _future3;
    gpointer _future4;

    TpBaseConnectionManagerClassPrivate *priv;
};

struct _TpBaseConnectionManager {
    /*<private>*/
    GObject parent;

    TpBaseConnectionManagerPrivate *priv;
};

GType tp_base_connection_manager_get_type (void);

gboolean tp_base_connection_manager_register (TpBaseConnectionManager *self);


TpDBusDaemon *tp_base_connection_manager_get_dbus_daemon (
    TpBaseConnectionManager *self);

void tp_base_connection_manager_add_protocol (TpBaseConnectionManager *self,
    TpBaseProtocol *protocol);

/* TYPE MACROS */
#define TP_TYPE_BASE_CONNECTION_MANAGER \
  (tp_base_connection_manager_get_type ())
#define TP_BASE_CONNECTION_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_BASE_CONNECTION_MANAGER, \
                              TpBaseConnectionManager))
#define TP_BASE_CONNECTION_MANAGER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), TP_TYPE_BASE_CONNECTION_MANAGER, \
                           TpBaseConnectionManagerClass))
#define TP_IS_BASE_CONNECTION_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_BASE_CONNECTION_MANAGER))
#define TP_IS_BASE_CONNECTION_MANAGER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_BASE_CONNECTION_MANAGER))
#define TP_BASE_CONNECTION_MANAGER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_BASE_CONNECTION_MANAGER, \
                              TpBaseConnectionManagerClass))

G_END_DECLS

#endif /* #ifndef __TP_BASE_CONNECTION_MANAGER_H__*/
