/*
 * proxy.h - Base class for Telepathy client proxies
 *
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

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_PROXY_H__
#define __TP_PROXY_H__

#include <dbus/dbus-glib.h>
#include <gio/gio.h>

#include <telepathy-glib/defs.h>
#include <telepathy-glib/_gen/genums.h>

G_BEGIN_DECLS

/* Forward declaration of a subclass - from dbus.h */
typedef struct _TpDBusDaemon TpDBusDaemon;
/* Forward declaration - from simple-client-factory.h */
typedef struct _TpSimpleClientFactory TpSimpleClientFactory;

typedef struct _TpProxyPrivate TpProxyPrivate;

typedef struct _TpProxy TpProxy;

#define TP_DBUS_ERRORS (tp_dbus_errors_quark ())
GQuark tp_dbus_errors_quark (void);

typedef enum {
    TP_DBUS_ERROR_UNKNOWN_REMOTE_ERROR = 0,
    TP_DBUS_ERROR_PROXY_UNREFERENCED = 1,
    TP_DBUS_ERROR_NO_INTERFACE = 2,
    TP_DBUS_ERROR_NAME_OWNER_LOST = 3,
    TP_DBUS_ERROR_INVALID_BUS_NAME = 4,
    TP_DBUS_ERROR_INVALID_INTERFACE_NAME = 5,
    TP_DBUS_ERROR_INVALID_OBJECT_PATH = 6,
    TP_DBUS_ERROR_INVALID_MEMBER_NAME = 7,
    TP_DBUS_ERROR_OBJECT_REMOVED = 8,
    TP_DBUS_ERROR_CANCELLED = 9,
    TP_DBUS_ERROR_INCONSISTENT = 10,
} TpDBusError;
#define TP_NUM_DBUS_ERRORS (TP_DBUS_ERROR_INCONSISTENT + 1)
#define NUM_TP_DBUS_ERRORS TP_NUM_DBUS_ERRORS

struct _TpProxy {
    /*<private>*/
    GObject parent;

    TpDBusDaemon *_TP_SEAL (dbus_daemon);
    DBusGConnection *_TP_SEAL (dbus_connection);
    gchar *_TP_SEAL (bus_name);
    gchar *_TP_SEAL (object_path);

    GError *_TP_SEAL (invalidated);

    TpProxyPrivate *priv;
};

typedef struct _TpProxyClass TpProxyClass;

typedef struct _TpProxyFeature TpProxyFeature;
typedef struct _TpProxyFeaturePrivate TpProxyFeaturePrivate;

typedef void (* TpProxyPrepareAsync) (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);

struct _TpProxyFeature {
    /*<public>*/
    GQuark name;
    gboolean core;

    TpProxyPrepareAsync prepare_async;
    TpProxyPrepareAsync prepare_before_signalling_connected_async;

    const GQuark *interfaces_needed;
    /* Features we depend on */
    const GQuark *depends_on;

    gboolean can_retry;

    /*<private>*/
    GCallback _reserved[4];
    TpProxyFeaturePrivate *priv;
};

/* XXX: hide this from the g-i scanner, since vapigen can't cope */
#ifndef __GI_SCANNER__
typedef const TpProxyFeature *(*TpProxyClassFeatureListFunc) (
    TpProxyClass *cls);
#endif /* __GI_SCANNER__ */

struct _TpProxyClass {
    /*<public>*/
    GObjectClass parent_class;

    GQuark interface;

    unsigned int must_have_unique_name:1;
    /*<private>*/
    guint _reserved_flags:31;

/* XXX: hide this from the g-i scanner, since vapigen can't cope */
#ifdef __GI_SCANNER__
    GCallback _internal_list_features;
#else
    TpProxyClassFeatureListFunc list_features;
#endif /* __GI_SCANNER__ */
    GCallback _reserved[3];
    gpointer priv;
};

typedef struct _TpProxyPendingCall TpProxyPendingCall;

void tp_proxy_pending_call_cancel (TpProxyPendingCall *pc);

typedef struct _TpProxySignalConnection TpProxySignalConnection;

void tp_proxy_signal_connection_disconnect (TpProxySignalConnection *sc);

GType tp_proxy_get_type (void);

/* TYPE MACROS */
#define TP_TYPE_PROXY \
  (tp_proxy_get_type ())
#define TP_PROXY(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_PROXY, \
                              TpProxy))
#define TP_PROXY_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), TP_TYPE_PROXY, \
                           TpProxyClass))
#define TP_IS_PROXY(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_PROXY))
#define TP_IS_PROXY_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_PROXY))
#define TP_PROXY_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_PROXY, \
                              TpProxyClass))

gboolean tp_proxy_has_interface_by_id (gpointer self, GQuark iface);
gboolean tp_proxy_has_interface (gpointer self, const gchar *iface);

_TP_AVAILABLE_IN_0_16
TpSimpleClientFactory *tp_proxy_get_factory (gpointer self);

TpDBusDaemon *tp_proxy_get_dbus_daemon (gpointer self);

DBusGConnection *tp_proxy_get_dbus_connection (gpointer self);

const gchar *tp_proxy_get_bus_name (gpointer self);

const gchar *tp_proxy_get_object_path (gpointer self);

const GError *tp_proxy_get_invalidated (gpointer self);

void tp_proxy_dbus_error_to_gerror (gpointer self,
    const char *dbus_error, const char *debug_message, GError **error);

gboolean tp_proxy_is_prepared (gpointer self, GQuark feature);
void tp_proxy_prepare_async (gpointer self,
    const GQuark *features,
    GAsyncReadyCallback callback,
    gpointer user_data);
gboolean tp_proxy_prepare_finish (gpointer self,
    GAsyncResult *result,
    GError **error);

G_END_DECLS

#include <telepathy-glib/_gen/tp-cli-generic.h>

#endif /* #ifndef __TP_PROXY_H__*/
