/*
 * <telepathy-glib/errors.h> - Header for Telepathy error types
 * Copyright (C) 2005-2009 Collabora Ltd.
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

#ifndef __TP_ERRORS_H__
#define __TP_ERRORS_H__

#include <glib-object.h>

#include <telepathy-glib/defs.h>

#include <telepathy-glib/_gen/error-str.h>
#include <telepathy-glib/_gen/genums.h>

G_BEGIN_DECLS

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED_FOR (TP_ERROR)
GQuark tp_errors_quark (void);

/* this is deliberately the old one, so that it expands to a call to a
 * deprecated function, so that gcc will warn */
#define TP_ERRORS (tp_errors_quark ())
#endif

GQuark tp_error_quark (void);

#define TP_ERROR_PREFIX "org.freedesktop.Telepathy.Error"

#define TP_ERROR (tp_error_quark ())

void tp_g_set_error_invalid_handle_type (guint type, GError **error);
void tp_g_set_error_unsupported_handle_type (guint type, GError **error);

typedef enum {
    TP_ERROR_NETWORK_ERROR, /*< nick=NetworkError >*/
    TP_ERROR_NOT_IMPLEMENTED, /*< nick=NotImplemented >*/
    TP_ERROR_INVALID_ARGUMENT, /*< nick=InvalidArgument >*/
    TP_ERROR_NOT_AVAILABLE, /*< nick=NotAvailable >*/
    TP_ERROR_PERMISSION_DENIED, /*< nick=PermissionDenied >*/
    TP_ERROR_DISCONNECTED, /*< nick=Disconnected >*/
    TP_ERROR_INVALID_HANDLE, /*< nick=InvalidHandle >*/
    TP_ERROR_CHANNEL_BANNED, /*< nick=Channel.Banned >*/
    TP_ERROR_CHANNEL_FULL, /*< nick=Channel.Full >*/
    TP_ERROR_CHANNEL_INVITE_ONLY, /*< nick=Channel.InviteOnly >*/
    TP_ERROR_NOT_YOURS, /*< nick=NotYours >*/
    TP_ERROR_CANCELLED, /*< nick=Cancelled >*/
    TP_ERROR_AUTHENTICATION_FAILED, /*< nick=AuthenticationFailed >*/
    TP_ERROR_ENCRYPTION_NOT_AVAILABLE, /*< nick=EncryptionNotAvailable >*/
    TP_ERROR_ENCRYPTION_ERROR, /*< nick=EncryptionError >*/
    TP_ERROR_CERT_NOT_PROVIDED, /*< nick=Cert.NotProvided >*/
    TP_ERROR_CERT_UNTRUSTED, /*< nick=Cert.Untrusted >*/
    TP_ERROR_CERT_EXPIRED, /*< nick=Cert.Expired >*/
    TP_ERROR_CERT_NOT_ACTIVATED, /*< nick=Cert.NotActivated >*/
    TP_ERROR_CERT_FINGERPRINT_MISMATCH, /*< nick=Cert.FingerprintMismatch >*/
    TP_ERROR_CERT_HOSTNAME_MISMATCH, /*< nick=Cert.HostnameMismatch >*/
    TP_ERROR_CERT_SELF_SIGNED, /*< nick=Cert.SelfSigned >*/
    TP_ERROR_CERT_INVALID, /*< nick=Cert.Invalid >*/
    TP_ERROR_NOT_CAPABLE, /*< nick=NotCapable >*/
    TP_ERROR_OFFLINE, /*< nick=Offline >*/
    TP_ERROR_CHANNEL_KICKED, /*< nick=Channel.Kicked >*/
    TP_ERROR_BUSY, /*< nick=Busy >*/
    TP_ERROR_NO_ANSWER, /*< nick=NoAnswer >*/
    TP_ERROR_DOES_NOT_EXIST, /*< nick=DoesNotExist >*/
    TP_ERROR_TERMINATED, /*< nick=Terminated >*/
    TP_ERROR_CONNECTION_REFUSED, /*< nick=ConnectionRefused >*/
    TP_ERROR_CONNECTION_FAILED, /*< nick=ConnectionFailed >*/
    TP_ERROR_CONNECTION_LOST, /*< nick=ConnectionLost >*/
    TP_ERROR_ALREADY_CONNECTED, /*< nick=AlreadyConnected >*/
    TP_ERROR_CONNECTION_REPLACED, /*< nick=ConnectionReplaced >*/
    TP_ERROR_REGISTRATION_EXISTS, /*< nick=RegistrationExists >*/
    TP_ERROR_SERVICE_BUSY, /*< nick=ServiceBusy >*/
    TP_ERROR_RESOURCE_UNAVAILABLE, /*< nick=ResourceUnavailable >*/
    TP_ERROR_WOULD_BREAK_ANONYMITY, /*< nick=WouldBreakAnonymity >*/
    TP_ERROR_CERT_REVOKED, /*< nick=Cert.Revoked >*/
    TP_ERROR_CERT_INSECURE, /*< nick=Cert.Insecure >*/
    TP_ERROR_CERT_LIMIT_EXCEEDED, /*< nick=Cert.LimitExceeded >*/
    TP_ERROR_NOT_YET, /*< nick=NotYet >*/
    TP_ERROR_REJECTED, /*< nick=Rejected >*/
    TP_ERROR_PICKED_UP_ELSEWHERE, /*< nick=PickedUpElsewhere >*/
    TP_ERROR_CONFUSED, /*< nick=Confused >*/
    TP_ERROR_SERVICE_CONFUSED, /*< nick=ServiceConfused >*/
    TP_ERROR_EMERGENCY_CALLS_NOT_SUPPORTED, /*< nick=EmergencyCallsNotSupported >*/
    TP_ERROR_SOFTWARE_UPGRADE_REQUIRED, /*< nick=SoftwareUpgradeRequired >*/
    TP_ERROR_INSUFFICIENT_BALANCE, /*< nick=InsufficientBalance >*/
    TP_ERROR_MEDIA_CODECS_INCOMPATIBLE, /*< nick=Media.CodecsIncompatible >*/
    TP_ERROR_MEDIA_UNSUPPORTED_TYPE, /*< nick=Media.UnsupportedType >*/
    TP_ERROR_MEDIA_STREAMING_ERROR, /*< nick=Media.StreamingError >*/
    TP_ERROR_CAPTCHA_NOT_SUPPORTED, /*< nick=CaptchaNotSupported >*/
} TpError;

const gchar *tp_error_get_dbus_name (TpError error);

G_END_DECLS

#endif
