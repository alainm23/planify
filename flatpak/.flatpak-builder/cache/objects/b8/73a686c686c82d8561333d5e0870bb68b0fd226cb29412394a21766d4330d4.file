/*
 * proxy-subclass.h - Base class for Telepathy client proxies
 *  (API for subclasses only)
 *
 * Copyright (C) 2007-2008 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2007-2008 Nokia Corporation
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

#ifndef __TP_PROXY_SUBCLASS_H__
#define __TP_PROXY_SUBCLASS_H__

#define _TP_IN_META_HEADER

#include <telepathy-glib/proxy.h>

G_BEGIN_DECLS

typedef void (*TpProxyInvokeFunc) (TpProxy *self,
    GError *error, GValueArray *args, GCallback callback, gpointer user_data,
    GObject *weak_object);

TpProxyPendingCall *tp_proxy_pending_call_v0_new (TpProxy *self,
    GQuark iface, const gchar *member, DBusGProxy *iface_proxy,
    TpProxyInvokeFunc invoke_callback,
    GCallback callback, gpointer user_data, GDestroyNotify destroy,
    GObject *weak_object, gboolean cancel_must_raise);

void tp_proxy_pending_call_v0_take_pending_call (TpProxyPendingCall *pc,
    DBusGProxyCall *pending_call);

void tp_proxy_pending_call_v0_take_results (TpProxyPendingCall *pc,
    GError *error, GValueArray *args);

void tp_proxy_pending_call_v0_completed (gpointer p);

TpProxySignalConnection *tp_proxy_signal_connection_v0_new (TpProxy *self,
    GQuark iface, const gchar *member,
    const GType *expected_types,
    GCallback collect_args, TpProxyInvokeFunc invoke_callback,
    GCallback callback, gpointer user_data, GDestroyNotify destroy,
    GObject *weak_object, GError **error);

void tp_proxy_signal_connection_v0_take_results
    (TpProxySignalConnection *sc, GValueArray *args);

typedef void (*TpProxyInterfaceAddedCb) (TpProxy *self,
    guint quark, DBusGProxy *proxy, gpointer unused);

void tp_proxy_or_subclass_hook_on_interface_add (GType proxy_or_subclass,
    TpProxyInterfaceAddedCb callback);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_IN_0_20_FOR(tp_proxy_get_interface_by_id)
DBusGProxy *tp_proxy_borrow_interface_by_id (TpProxy *self, GQuark iface,
    GError **error);
#endif

_TP_AVAILABLE_IN_0_20
DBusGProxy *tp_proxy_get_interface_by_id (TpProxy *self, GQuark iface,
    GError **error);

DBusGProxy *tp_proxy_add_interface_by_id (TpProxy *self, GQuark iface);
void tp_proxy_add_interfaces (TpProxy *self, const gchar * const *interfaces);

void tp_proxy_invalidate (TpProxy *self, const GError *error);

void tp_proxy_subclass_add_error_mapping (GType proxy_subclass,
    const gchar *static_prefix, GQuark domain, GType code_enum_type);

gboolean tp_proxy_dbus_g_proxy_claim_for_signal_adding (DBusGProxy *proxy);

void tp_proxy_init_known_interfaces (void);

G_END_DECLS

#undef _TP_IN_META_HEADER

#endif /* #ifndef __TP_PROXY_SUBCLASS_H__*/
