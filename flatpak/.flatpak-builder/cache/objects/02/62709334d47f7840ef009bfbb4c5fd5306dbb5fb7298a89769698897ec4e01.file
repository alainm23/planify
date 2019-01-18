/*
 * D-Bus error types used in telepathy
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

#include "config.h"

#include <telepathy-glib/errors.h>

#include <glib.h>
#include <dbus/dbus-glib.h>

#include <telepathy-glib/util.h>

/**
 * TP_ERROR_PREFIX:
 *
 * The common prefix of Telepathy errors, as a string constant, without
 * the trailing '.' character.
 *
 * Since: 0.7.1
 */

/**
 * TP_ERROR:
 *
 * The error domain for the D-Bus errors described in the Telepathy
 * specification. Error codes in this domain come from the #TpError
 * enumeration.
 *
 * This macro expands to a call to a function returning the Telepathy error
 * domain. Since 0.7.17, this function automatically registers the domain with
 * dbus-glib for server-side use (using dbus_g_error_domain_register()) when
 * called.
 *
 * This used to be called %TP_ERRORS.
 *
 * Since: 0.11.7
 */

/**
 * TP_TYPE_ERROR:
 *
 * The GType of the Telepathy error enumeration.
 */

/**
 * TpError:
 * @TP_ERROR_NETWORK_ERROR: org.freedesktop.Telepathy.Error.NetworkError:
 *     Raised when there is an error reading from or writing to the network.
 * @TP_ERROR_NOT_IMPLEMENTED: org.freedesktop.Telepathy.Error.NotImplemented:
 *     Raised when the requested method, channel, etc is not available on this
 *     connection.
 * @TP_ERROR_INVALID_ARGUMENT: org.freedesktop.Telepathy.Error.InvalidArgument:
 *     Raised when one of the provided arguments is invalid.
 * @TP_ERROR_NOT_AVAILABLE: org.freedesktop.Telepathy.Error.NotAvailable:
 *     Raised when the requested functionality is temporarily unavailable.
 * @TP_ERROR_PERMISSION_DENIED: org.freedesktop.Telepathy.Error.PermissionDenied:
 *     The user is not permitted to perform the requested operation.
 * @TP_ERROR_DISCONNECTED: org.freedesktop.Telepathy.Error.Disconnected:
 *     The connection is not currently connected and cannot be used.
 *     This error may also be raised when operations are performed on a
 *     Connection for which StatusChanged has signalled status Disconnected
 *     for reason None.
 * @TP_ERROR_INVALID_HANDLE: org.freedesktop.Telepathy.Error.InvalidHandle:
 *     An identifier being converted to a handle was syntactically invalid,
 *     or an invalid handle was used.
 * @TP_ERROR_CHANNEL_BANNED: org.freedesktop.Telepathy.Error.Channel.Banned:
 *     You are banned from the channel.
 * @TP_ERROR_CHANNEL_FULL: org.freedesktop.Telepathy.Error.Channel.Full:
 *     The channel is full.
 * @TP_ERROR_CHANNEL_INVITE_ONLY: org.freedesktop.Telepathy.Error.Channel.InviteOnly:
 *     The requested channel is invite-only.
 * @TP_ERROR_NOT_YOURS: org.freedesktop.Telepathy.Error.NotYours:
 *     The requested channel or other resource already exists, and another
 *     client is responsible for it
 * @TP_ERROR_CANCELLED: org.freedesktop.Telepathy.Error.Cancelled:
 *     Raised by an ongoing request if it is cancelled by user request before
 *     it has completed, or when operations are performed on an object which
 *     the user has asked to close (for instance, a Connection where the user
 *     has called Disconnect, or a Channel where the user has called Close).
 * @TP_ERROR_AUTHENTICATION_FAILED: org.freedesktop.Telepathy.Error.AuthenticationFailed:
 *     Raised when authentication with a service was unsuccessful.
 * @TP_ERROR_ENCRYPTION_NOT_AVAILABLE: org.freedesktop.Telepathy.Error.EncryptionNotAvailable:
 *     Raised if a user request insisted that encryption should be used,
 *     but encryption was not actually available.
 * @TP_ERROR_ENCRYPTION_ERROR: org.freedesktop.Telepathy.Error.EncryptionError:
 *     Raised if encryption appears to be available, but could not actually be
 *     used (for instance if SSL/TLS negotiation fails).
 * @TP_ERROR_CERT_NOT_PROVIDED: org.freedesktop.Telepathy.Error.Cert.NotProvided:
 *     Raised if the server did not provide a SSL/TLS certificate.
 * @TP_ERROR_CERT_UNTRUSTED: org.freedesktop.Telepathy.Error.Cert.Untrusted:
 *     Raised if the server provided a SSL/TLS certificate signed by an
 *     untrusted certifying authority.
 * @TP_ERROR_CERT_EXPIRED: org.freedesktop.Telepathy.Error.Cert.Expired:
 *     Raised if the server provided an expired SSL/TLS certificate.
 * @TP_ERROR_CERT_NOT_ACTIVATED: org.freedesktop.Telepathy.Error.Cert.NotActivated:
 *     Raised if the server provided an SSL/TLS certificate that will become
 *     valid at some point in the future.
 * @TP_ERROR_CERT_FINGERPRINT_MISMATCH: org.freedesktop.Telepathy.Error.Cert.FingerprintMismatch:
 *     Raised if the server provided an SSL/TLS certificate that did not have
 *     the expected fingerprint.
 * @TP_ERROR_CERT_HOSTNAME_MISMATCH: org.freedesktop.Telepathy.Error.Cert.HostnameMismatch:
 *     Raised if the server provided an SSL/TLS certificate that did not
 *     match its hostname.
 * @TP_ERROR_CERT_SELF_SIGNED: org.freedesktop.Telepathy.Error.Cert.SelfSigned:
 *     Raised if the server provided an SSL/TLS certificate that is
 *     self-signed and untrusted.
 * @TP_ERROR_CERT_INVALID: org.freedesktop.Telepathy.Error.Cert.Invalid:
 *     Raised if the server provided an SSL/TLS certificate that is
 *     unacceptable in some way that does not have a more specific error.
 * @TP_ERROR_NOT_CAPABLE: org.freedesktop.Telepathy.Error.NotCapable:
 *     Raised when requested functionality is unavailable due to a contact
 *     not having the required capabilities.
 * @TP_ERROR_OFFLINE: org.freedesktop.Telepathy.Error.Offline:
 *     Raised when requested functionality is unavailable because a contact is
 *     offline.
 * @TP_ERROR_CHANNEL_KICKED: org.freedesktop.Telepathy.Error.Channel.Kicked:
 *     Used to represent a user being ejected from a channel by another user,
 *     for instance being kicked from a chatroom.
 * @TP_ERROR_BUSY: org.freedesktop.Telepathy.Error.Busy:
 *     Used to represent a user being removed from a channel because of a
 *     "busy" indication.
 * @TP_ERROR_NO_ANSWER: org.freedesktop.Telepathy.Error.NoAnswer:
 *     Used to represent a user being removed from a channel because they did
 *     not respond, e.g. to a StreamedMedia call.
 * @TP_ERROR_DOES_NOT_EXIST: org.freedesktop.Telepathy.Error.DoesNotExist:
 *     Raised when the requested user does not, in fact, exist.
 * @TP_ERROR_TERMINATED: org.freedesktop.Telepathy.Error.Terminated:
 *     Raised when a channel is terminated for an unspecified reason. In
 *     particular, this error SHOULD be used whenever normal termination of a
 *     1-1 StreamedMedia call by the remote user is represented as a D-Bus
 *     error name.
 * @TP_ERROR_CONNECTION_REFUSED: org.freedesktop.Telepathy.Error.ConnectionRefused:
 *     Raised when a connection is refused.
 * @TP_ERROR_CONNECTION_FAILED: org.freedesktop.Telepathy.Error.ConnectionFailed:
 *     Raised when a connection can't be established.
 * @TP_ERROR_CONNECTION_LOST: org.freedesktop.Telepathy.Error.ConnectionLost:
 *     Raised when a connection is broken.
 * @TP_ERROR_ALREADY_CONNECTED: org.freedesktop.Telepathy.Error.AlreadyConnected:
 *     Raised on attempts to connect again to an account that is already
 *     connected, if the protocol or server does not allow this.
 *     Since 0.7.34
 * @TP_ERROR_CONNECTION_REPLACED: org.freedesktop.Telepathy.Error.ConnectionReplaced:
 *     Used as disconnection reason for an existing connection if it is
 *     disconnected because a second connection to the same account is made.
 *     Since 0.7.34
 * @TP_ERROR_REGISTRATION_EXISTS: org.freedesktop.Telepathy.Error.RegistrationExists:
 *     Raised on attempts to register an account on a server when the account
 *     already exists.
 *     Since 0.7.34
 * @TP_ERROR_SERVICE_BUSY: org.freedesktop.Telepathy.Error.ServiceBusy:
 *     Raised when a server or other infrastructure rejects a request because
 *     it is too busy.
 *     Since 0.7.34
 * @TP_ERROR_RESOURCE_UNAVAILABLE: org.freedesktop.Telepathy.Error.ResourceUnavailable:
 *     Raised when a local process rejects a request because it does not have
 *     enough of a resource, such as memory.
 *     Since 0.7.34
 * @TP_ERROR_WOULD_BREAK_ANONYMITY: org.freedesktop.Telepathy.Error.WouldBreakAnonymity:
 *     Raised when a request cannot be satisfied without violating an
 *     earlier request for anonymity, and the earlier request specified
 *     that raising an error is preferable to disclosing the user's
 *     identity
 *     Since 0.11.7
 * @TP_ERROR_CERT_REVOKED: org.freedesktop.Telepathy.Error.Cert.Revoked:
 *     Raised if the server provided an SSL/TLS certificate that has been
 *     revoked.
 *     Since 0.11.12
 * @TP_ERROR_CERT_INSECURE: org.freedesktop.Telepathy.Error.Cert.Insecure:
 *     Raised if the server provided an SSL/TLS certificate that uses an
 *     insecure cipher algorithm or is cryptographically weak.
 *     Since 0.11.12
 * @TP_ERROR_CERT_LIMIT_EXCEEDED: org.freedesktop.Telepathy.Error.Cert.LimitExceeded:
 *     Raised if the length in bytes of the server certificate, or the depth
 *     of the server certificate chain, exceed the limits imposed by the
 *     crypto library.
 *     Since 0.11.12
 * @TP_ERROR_NOT_YET: org.freedesktop.Telepathy.Error.NotYet:
 *     Raised when the requested functionality is not yet available, but is
 *     likely to become available after some time has passed.
 *     Since 0.11.15
 * @TP_ERROR_REJECTED: org.freedesktop.Telepathy.Error.Rejected:
 *     Raised when an incoming or outgoing call is rejected by the receiving
 *     contact.
 *     Since 0.13.2
 * @TP_ERROR_PICKED_UP_ELSEWHERE: org.freedesktop.Telepathy.Error.PickedUpElsewhere:
 *     Raised when a call was terminated as a result of the local user
 *     picking up the call on a different resource.
 *     Since 0.13.3
 * @TP_ERROR_CONFUSED: org.freedesktop.Telepathy.Error.Confused:
 *     Raised if a server rejects protocol messages from a connection manager
 *     claiming that they do not make sense, two local processes fail to
 *     understand each other, or an apparently impossible situation is
 *     reached. This has a similar meaning to %TP_DBUS_ERROR_INCONSISTENT but
 *     can be passed between processes via D-Bus.
 *     Since 0.13.7
 * @TP_ERROR_SERVICE_CONFUSED: org.freedesktop.Telepathy.Error.ServiceConfused:
 *     Raised when a server or other piece of infrastructure indicates an
 *     internal error, or when a message that makes no sense is received from
 *     a server or other piece of infrastructure.
 *     Since 0.13.7
 * @TP_ERROR_EMERGENCY_CALLS_NOT_SUPPORTED:
 *   org.freedesktop.Telepathy.Error.EmergencyCallsNotSupported:
 *     Raised when a client attempts to dial a number that is recognized as an
 *     emergency number (e.g. '911' in the USA), but the Connection
 *     Manager or provider does not support dialling emergency numbers.
 * @TP_ERROR_SOFTWARE_UPGRADE_REQUIRED:
 *   org.freedesktop.Telepathy.Error.SoftwareUpgradeRequired:
 *     Raised when a Connection cannot be established because either the
 *     Connection Manager or its support library (e.g. wocky, papyon, sofiasip)
 *     requires upgrading to support a newer protocol version.
 * @TP_ERROR_INSUFFICIENT_BALANCE:
 *   <code>org.freedesktop.Telepathy.Error.InsufficientBalance</code>:
 *     Raised if the user has insufficient balance to place a call.  The key
 *     'balance-required' MAY be included in CallStateDetails on a Call channel
 *     (with the same units and scale as AccountBalance) to indicate how much
 *     credit is required to make this call.
 * @TP_ERROR_MEDIA_CODECS_INCOMPATIBLE:
 *   <code>org.freedesktop.Telepathy.Error.Media.CodecsIncompatible</code>:
 *     Raised when the local streaming implementation has no codecs in common
 *     with the remote side.
 *     Since 0.15.6
 * @TP_ERROR_MEDIA_UNSUPPORTED_TYPE:
 *   <code>org.freedesktop.Telepathy.Error.Media.UnsupportedType</code>:
 *     The media stream type requested is not supported by either the local or
 *     remote side.
 *     Since 0.15.6
 * @TP_ERROR_MEDIA_STREAMING_ERROR:
 *   <code>org.freedesktop.Telepathy.Error.Media.StreamingError</code>:
 *     Raised when the call's streaming implementation has some kind of internal
 *     error.
 *     Since 0.15.6
 * @TP_ERROR_CAPTCHA_NOT_SUPPORTED:
 *   <code>org.freedesktop.Telepathy.Error.Media.CaptchaNotSupported</code>:
 *     Raised if no UI is available to present captchas, or if one is
 *     available but it is unable to answer any of the captchas given.
 *
 * Enumerated type representing the Telepathy D-Bus errors.
 */

/**
 * tp_g_set_error_invalid_handle_type: (skip)
 * @type: An invalid handle type
 * @error: Either %NULL, or used to return an error (as for g_set_error)
 *
 * Set the error NotImplemented for an invalid handle type,
 * with an appropriate message.
 *
 * Changed in version 0.7.23: previously, the error was
 * InvalidArgument.
 */
void
tp_g_set_error_invalid_handle_type (guint type, GError **error)
{
  g_set_error (error, TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
      "unsupported handle type %u", type);
}

/**
 * tp_g_set_error_unsupported_handle_type: (skip)
 * @type: An unsupported handle type
 * @error: Either %NULL, or used to return an error (as for g_set_error)
 *
 * Set the error NotImplemented for a handle type which is valid but is not
 * supported by this connection manager, with an appropriate message.
 *
 * Changed in version 0.7.23: previously, the error was
 * InvalidArgument.
 */
void
tp_g_set_error_unsupported_handle_type (guint type, GError **error)
{
  g_set_error (error, TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
      "unsupported handle type %u", type);
}

/**
 * tp_error_get_dbus_name:
 * @error: a member of the #TpError enum.
 *
 * <!-- -->
 *
 * Returns: the D-Bus error name corresponding to @error.
 *
 * Since: 0.7.31
 */
/* tp_error_get_dbus_name is implemented in _gen/error-str.c by
 * tools/glib-errors-str-gen.py.
 */

/**
 * tp_errors_quark: (skip)
 *
 * <!-- -->
 *
 * Deprecated: Use tp_error_quark() instead.
 */
GQuark
tp_errors_quark (void)
{
  return tp_error_quark ();
}

/**
 * tp_error_quark:
 *
 * Return the error domain quark for #TpError.
 *
 * Since: 0.11.13
 */
GQuark
tp_error_quark (void)
{
  static gsize quark = 0;

  if (g_once_init_enter (&quark))
    {
      /* FIXME: When we next break API, this should be changed to
       * "tp-error-quark" */
      GQuark domain = g_quark_from_static_string ("tp_errors");

      dbus_g_error_domain_register (domain, TP_ERROR_PREFIX,
          TP_TYPE_ERROR);
      g_once_init_leave (&quark, domain);
    }

  return (GQuark) quark;
}

/* tp_errors_quark assumes this */
G_STATIC_ASSERT (sizeof (GQuark) <= sizeof (gsize));
