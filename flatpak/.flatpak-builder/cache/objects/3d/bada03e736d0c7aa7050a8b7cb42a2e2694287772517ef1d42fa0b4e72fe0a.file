/*
 * gnio-util.h - Headers for telepathy-glib GNIO utility functions
 *
 * Copyright (C) 2009 Collabora Ltd. <http://www.collabora.co.uk/>
 *   @author Danielle Madeley <danielle.madeley@collabora.co.uk>
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

#include <glib-object.h>
#include <gio/gio.h>

#include <telepathy-glib/defs.h>
#include <telepathy-glib/enums.h>

#ifndef __TP_GNIO_UTIL_H__
#define __TP_GNIO_UTIL_H__

G_BEGIN_DECLS

GSocketAddress *tp_g_socket_address_from_variant (TpSocketAddressType type,
    const GValue *variant,
    GError **error) G_GNUC_WARN_UNUSED_RESULT;
GValue *tp_address_variant_from_g_socket_address (GSocketAddress *address,
    TpSocketAddressType *type,
    GError **error) G_GNUC_WARN_UNUSED_RESULT;

_TP_AVAILABLE_IN_0_20
GSocketAddress *tp_g_socket_address_from_g_variant (TpSocketAddressType type,
    GVariant *variant,
    GError **error) G_GNUC_WARN_UNUSED_RESULT;
_TP_AVAILABLE_IN_0_20
GVariant *tp_address_g_variant_from_g_socket_address (GSocketAddress *address,
    TpSocketAddressType *type,
    GError **error) G_GNUC_WARN_UNUSED_RESULT;

gboolean tp_unix_connection_send_credentials_with_byte (
    GSocketConnection *connection,
    guchar byte,
    GCancellable *cancellable,
    GError **error);
_TP_AVAILABLE_IN_0_18
void tp_unix_connection_send_credentials_with_byte_async (
    GSocketConnection *connection,
    guchar byte,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data);
_TP_AVAILABLE_IN_0_18
gboolean tp_unix_connection_send_credentials_with_byte_finish (
    GSocketConnection *connection,
    GAsyncResult *result,
    GError **error);

_TP_AVAILABLE_IN_0_18
GCredentials * tp_unix_connection_receive_credentials_with_byte (
    GSocketConnection *connection,
    guchar *byte,
    GCancellable *cancellable,
    GError **error);
_TP_AVAILABLE_IN_0_18
void tp_unix_connection_receive_credentials_with_byte_async (
    GSocketConnection *connection,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data);
GCredentials *tp_unix_connection_receive_credentials_with_byte_finish (
    GSocketConnection *connection,
    GAsyncResult *result,
    guchar *byte,
    GError **error);

G_END_DECLS

#endif /* __TP_GNIO_UTIL_H__ */
