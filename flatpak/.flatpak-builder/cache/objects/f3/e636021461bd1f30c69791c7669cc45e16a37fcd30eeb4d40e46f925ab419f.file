/*
 * debug-client.h - proxy for Telepathy debug objects
 *
 * Copyright © 2010 Collabora Ltd. <http://www.collabora.co.uk/>
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

#ifndef TP_DEBUG_CLIENT_H
#define TP_DEBUG_CLIENT_H

#include <telepathy-glib/defs.h>
#include <telepathy-glib/proxy.h>
#include <telepathy-glib/debug-message.h>

G_BEGIN_DECLS

typedef struct _TpDebugClient TpDebugClient;
typedef struct _TpDebugClientPrivate TpDebugClientPrivate;
typedef struct _TpDebugClientClass TpDebugClientClass;

_TP_AVAILABLE_IN_0_20
TpDebugClient *tp_debug_client_new (
    TpDBusDaemon *dbus,
    const gchar *unique_name,
    GError **error);

#define TP_DEBUG_CLIENT_FEATURE_CORE \
    (tp_debug_client_get_feature_quark_core ())
_TP_AVAILABLE_IN_0_20
GQuark tp_debug_client_get_feature_quark_core (void) G_GNUC_CONST;

_TP_AVAILABLE_IN_0_20
void tp_debug_client_set_enabled_async (
    TpDebugClient *self,
    gboolean enabled,
    GAsyncReadyCallback callback,
    gpointer user_data);

_TP_AVAILABLE_IN_0_20
gboolean tp_debug_client_set_enabled_finish (
    TpDebugClient *self,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_20
gboolean tp_debug_client_is_enabled (TpDebugClient *self);

/* Tedious GObject boilerplate */

_TP_AVAILABLE_IN_0_20
GType tp_debug_client_get_type (void);

#define TP_TYPE_DEBUG_CLIENT \
  (tp_debug_client_get_type ())
#define TP_DEBUG_CLIENT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_DEBUG_CLIENT, \
                              TpDebugClient))
#define TP_DEBUG_CLIENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), TP_TYPE_DEBUG_CLIENT, \
                           TpDebugClientClass))
#define TP_IS_DEBUG_CLIENT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_DEBUG_CLIENT))
#define TP_IS_DEBUG_CLIENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_DEBUG_CLIENT))
#define TP_DEBUG_CLIENT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_DEBUG_CLIENT, \
                              TpDebugClientClass))

_TP_AVAILABLE_IN_0_20
void tp_debug_client_init_known_interfaces (void);

_TP_AVAILABLE_IN_0_20
void tp_debug_client_get_messages_async (
    TpDebugClient *self,
    GAsyncReadyCallback callback,
    gpointer user_data);

_TP_AVAILABLE_IN_0_20
GPtrArray * tp_debug_client_get_messages_finish (TpDebugClient *self,
    GAsyncResult *result,
    GError **error) G_GNUC_WARN_UNUSED_RESULT;

G_END_DECLS

#include <telepathy-glib/_gen/tp-cli-debug.h>

#endif
