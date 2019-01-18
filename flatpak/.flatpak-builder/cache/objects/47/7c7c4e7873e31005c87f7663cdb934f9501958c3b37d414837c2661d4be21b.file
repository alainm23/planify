/*
 * defs.h - miscellaneous definitions
 *
 * Copyright (C) 2007-2009 Collabora Ltd.
 * Copyright (C) 2007-2009 Nokia Corporation
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

#ifndef __TP_DEFS_H__
#define __TP_DEFS_H__

#include <glib.h>
#include <telepathy-glib/version.h>

G_BEGIN_DECLS

/**
 * TP_CM_BUS_NAME_BASE:
 *
 * The prefix for a connection manager's bus name, to which the CM's name
 * (e.g. "gabble") should be appended.
 */
#define TP_CM_BUS_NAME_BASE    "org.freedesktop.Telepathy.ConnectionManager."

/**
 * TP_CM_OBJECT_PATH_BASE:
 *
 * The prefix for a connection manager's object path, to which the CM's name
 * (e.g. "gabble") should be appended.
 */
#define TP_CM_OBJECT_PATH_BASE "/org/freedesktop/Telepathy/ConnectionManager/"

/**
 * TP_CONN_BUS_NAME_BASE:
 *
 * The prefix for a connection's bus name, to which the CM's name
 * (e.g. "gabble"), the protocol (e.g. "jabber") and an element or sequence
 * of elements representing the account should be appended.
 */
#define TP_CONN_BUS_NAME_BASE "org.freedesktop.Telepathy.Connection."

/**
 * TP_CONN_OBJECT_PATH_BASE:
 *
 * The prefix for a connection's object path, to which the CM's name
 * (e.g. "gabble"), the protocol (e.g. "jabber") and an element or sequence
 * of elements representing the account should be appended.
 */
#define TP_CONN_OBJECT_PATH_BASE "/org/freedesktop/Telepathy/Connection/"

/**
 * TP_ACCOUNT_MANAGER_BUS_NAME:
 *
 * The account manager's well-known bus name
 */
#define TP_ACCOUNT_MANAGER_BUS_NAME "org.freedesktop.Telepathy.AccountManager"

/**
 * TP_ACCOUNT_MANAGER_OBJECT_PATH:
 *
 * The account manager's standard object path
 */
#define TP_ACCOUNT_MANAGER_OBJECT_PATH "/org/freedesktop/Telepathy/AccountManager"

/**
 * TP_ACCOUNT_OBJECT_PATH_BASE:
 *
 * The common prefix of the object path for all Account objects.
 */
#define TP_ACCOUNT_OBJECT_PATH_BASE "/org/freedesktop/Telepathy/Account/"

/**
 * TP_CHANNEL_DISPATCHER_BUS_NAME:
 *
 * The channel dispatcher's well-known bus name
 */
#define TP_CHANNEL_DISPATCHER_BUS_NAME "org.freedesktop.Telepathy.ChannelDispatcher"

/**
 * TP_CHANNEL_DISPATCHER_OBJECT_PATH:
 *
 * The channel dispatcher's standard object path
 */
#define TP_CHANNEL_DISPATCHER_OBJECT_PATH "/org/freedesktop/Telepathy/ChannelDispatcher"

/**
 * TP_CLIENT_BUS_NAME_BASE:
 *
 * The common prefix of the well-known bus name for any Telepathy Client.
 */
#define TP_CLIENT_BUS_NAME_BASE "org.freedesktop.Telepathy.Client."

/**
 * TP_CLIENT_OBJECT_PATH_BASE:
 *
 * The common prefix of the well-known object path for any Telepathy Client.
 */
#define TP_CLIENT_OBJECT_PATH_BASE "/org/freedesktop/Telepathy/Client/"

/**
 * TP_DEBUG_OBJECT_PATH:
 *
 * The standard path for objects implementing the Telepathy Debug interface
 * (#TpSvcDebug).
 */
#define TP_DEBUG_OBJECT_PATH "/org/freedesktop/Telepathy/debug"

/**
 * TP_USER_ACTION_TIME_NOT_USER_ACTION:
 *
 * The "user action time" used by methods like
 * tp_account_channel_request_new() to represent channel requests that are
 * not a result of user action.
 *
 * See also #TpAccountChannelRequest:user-action-time,
 * tp_user_action_time_from_x11(), tp_user_action_time_should_present() and
 * %TP_USER_ACTION_TIME_CURRENT_TIME.
 *
 * Since: 0.11.13
 */
#define TP_USER_ACTION_TIME_NOT_USER_ACTION (G_GINT64_CONSTANT (0))

/**
 * TP_USER_ACTION_TIME_CURRENT_TIME:
 *
 * The "user action time" used by methods like
 * tp_account_channel_request_new() to represent channel requests that should
 * be treated as though they happened at the current time. This is the same
 * concept as %GDK_CURRENT_TIME in GDK (but note that the numerical value used
 * in Telepathy is not the same).
 *
 * See also #TpAccountChannelRequest:user-action-time,
 * tp_user_action_time_from_x11(), tp_user_action_time_should_present() and
 * %TP_USER_ACTION_TIME_NOT_USER_ACTION.
 *
 * Since: 0.11.13
 */
#define TP_USER_ACTION_TIME_CURRENT_TIME (G_MAXINT64)

#define _TP_ENCODE_VERSION(major, minor) (((major) << 16) | ((minor) << 8))

#define TP_VERSION_0_16 (_TP_ENCODE_VERSION (0, 16))
#define TP_VERSION_0_18 (_TP_ENCODE_VERSION (0, 18))
#define TP_VERSION_0_20 (_TP_ENCODE_VERSION (0, 20))
#define TP_VERSION_0_22 (_TP_ENCODE_VERSION (0, 22))
#define TP_VERSION_0_24 (_TP_ENCODE_VERSION (0, 24))
#define TP_VERSION_1_0 (_TP_ENCODE_VERSION (1, 0))

#if (TP_MINOR_VERSION == 99)
  /* special case for telepathy-glib 1.0 prereleases */
# define _TP_VERSION_CUR_STABLE (_TP_ENCODE_VERSION (TP_MAJOR_VERSION + 1, 0))
#elif (TP_MINOR_VERSION == 0)
  /* special case for telepathy-glib 1.0 itself */
# define _TP_VERSION_CUR_STABLE (_TP_ENCODE_VERSION (TP_MAJOR_VERSION, 0))
#elif (TP_MICRO_VERSION >= 99 && (TP_MINOR_VERSION % 2) == 0)
  /* development branch about to start (0.18.999.1) */
# define _TP_VERSION_CUR_STABLE \
  (_TP_ENCODE_VERSION (TP_MAJOR_VERSION, TP_MINOR_VERSION + 2))
#elif (TP_MINOR_VERSION % 2)
  /* development branch */
# define _TP_VERSION_CUR_STABLE \
  (_TP_ENCODE_VERSION (TP_MAJOR_VERSION, TP_MINOR_VERSION + 1))
#else
  /* stable branch */
# define _TP_VERSION_CUR_STABLE \
  (_TP_ENCODE_VERSION (TP_MAJOR_VERSION, TP_MINOR_VERSION))
#endif

#ifndef TP_VERSION_MIN_REQUIRED
# define TP_VERSION_MIN_REQUIRED (_TP_VERSION_CUR_STABLE)
#endif

#ifndef TP_VERSION_MAX_ALLOWED
# define TP_VERSION_MAX_ALLOWED (_TP_VERSION_CUR_STABLE)
#endif

#if TP_VERSION_MAX_ALLOWED < TP_VERSION_MIN_REQUIRED
# error "TP_VERSION_MAX_ALLOWED must be >= TP_VERSION_MIN_REQUIRED"
#endif
#if TP_VERSION_MIN_REQUIRED < TP_VERSION_0_16
# error "TP_VERSION_MIN_REQUIRED must be >= TP_VERSION_0_16"
#endif

#if TP_VERSION_MIN_REQUIRED >= TP_VERSION_0_16
# define _TP_DEPRECATED_IN_0_16 _TP_DEPRECATED
# define _TP_DEPRECATED_IN_0_16_FOR(f) _TP_DEPRECATED_FOR(f)
#else
# define _TP_DEPRECATED_IN_0_16 /* nothing */
# define _TP_DEPRECATED_IN_0_16_FOR(f) /* nothing */
#endif

#if TP_VERSION_MIN_REQUIRED >= TP_VERSION_0_18
# define _TP_DEPRECATED_IN_0_18 _TP_DEPRECATED
# define _TP_DEPRECATED_IN_0_18_FOR(f) _TP_DEPRECATED_FOR(f)
#else
# define _TP_DEPRECATED_IN_0_18 /* nothing */
# define _TP_DEPRECATED_IN_0_18_FOR(f) /* nothing */
#endif

#if TP_VERSION_MIN_REQUIRED >= TP_VERSION_0_20
# define _TP_DEPRECATED_IN_0_20 _TP_DEPRECATED
# define _TP_DEPRECATED_IN_0_20_FOR(f) _TP_DEPRECATED_FOR(f)
#else
# define _TP_DEPRECATED_IN_0_20 /* nothing */
# define _TP_DEPRECATED_IN_0_20_FOR(f) /* nothing */
#endif

#if TP_VERSION_MIN_REQUIRED >= TP_VERSION_0_22
# define _TP_DEPRECATED_IN_0_22 _TP_DEPRECATED
# define _TP_DEPRECATED_IN_0_22_FOR(f) _TP_DEPRECATED_FOR(f)
#else
# define _TP_DEPRECATED_IN_0_22 /* nothing */
# define _TP_DEPRECATED_IN_0_22_FOR(f) /* nothing */
#endif

#if TP_VERSION_MIN_REQUIRED >= TP_VERSION_0_24
# define _TP_DEPRECATED_IN_0_24 _TP_DEPRECATED
# define _TP_DEPRECATED_IN_0_24_FOR(f) _TP_DEPRECATED_FOR(f)
#else
# define _TP_DEPRECATED_IN_0_24 /* nothing */
# define _TP_DEPRECATED_IN_0_24_FOR(f) /* nothing */
#endif

#if TP_VERSION_MIN_REQUIRED >= TP_VERSION_1_0
# define _TP_DEPRECATED_IN_1_0 _TP_DEPRECATED
# define _TP_DEPRECATED_IN_1_0_FOR(f) _TP_DEPRECATED_FOR(f)
#else
# define _TP_DEPRECATED_IN_1_0 /* nothing */
# define _TP_DEPRECATED_IN_1_0_FOR(f) /* nothing */
#endif

#if TP_VERSION_MIN_REQUIRED >= _TP_VERSION_CUR_STABLE
# define _TP_DEPRECATED_IN_UNRELEASED _TP_DEPRECATED
# define _TP_DEPRECATED_IN_UNRELEASED_FOR(f) _TP_DEPRECATED_FOR(f)
#else
# define _TP_DEPRECATED_IN_UNRELEASED /* nothing */
# define _TP_DEPRECATED_IN_UNRELEASED_FOR(f) /* nothing */
#endif

#if TP_VERSION_MAX_ALLOWED < TP_VERSION_0_16
# define _TP_AVAILABLE_IN_0_16 _TP_UNAVAILABLE(0, 16)
#else
# define _TP_AVAILABLE_IN_0_16 /* nothing */
#endif

#if TP_VERSION_MAX_ALLOWED < TP_VERSION_0_18
# define _TP_AVAILABLE_IN_0_18 _TP_UNAVAILABLE(0, 18)
#else
# define _TP_AVAILABLE_IN_0_18 /* nothing */
#endif

#if TP_VERSION_MAX_ALLOWED < TP_VERSION_0_20
# define _TP_AVAILABLE_IN_0_20 _TP_UNAVAILABLE(0, 20)
#else
# define _TP_AVAILABLE_IN_0_20 /* nothing */
#endif

#if TP_VERSION_MAX_ALLOWED < TP_VERSION_0_22
# define _TP_AVAILABLE_IN_0_22 _TP_UNAVAILABLE(0, 22)
#else
# define _TP_AVAILABLE_IN_0_22 /* nothing */
#endif

#if TP_VERSION_MAX_ALLOWED < TP_VERSION_0_24
# define _TP_AVAILABLE_IN_0_24 _TP_UNAVAILABLE(0, 24)
#else
# define _TP_AVAILABLE_IN_0_24 /* nothing */
#endif

#if TP_VERSION_MAX_ALLOWED < TP_VERSION_1_0
# define _TP_AVAILABLE_IN_1_0 _TP_UNAVAILABLE(1, 0)
#else
# define _TP_AVAILABLE_IN_1_0 /* nothing */
#endif

#if TP_VERSION_MAX_ALLOWED < _TP_VERSION_CUR_STABLE
# define _TP_AVAILABLE_IN_UNRELEASED \
  _TP_UNAVAILABLE (TP_MAJOR_VERSION, TP_MINOR_VERSION)
#else
# define _TP_AVAILABLE_IN_UNRELEASED /* nothing */
#endif

/* telepathy-glib-specific macros so our regression
 * tests can continue to test deprecated functionality, while avoiding
 * deprecated bits of other libraries */
#ifdef _TP_IGNORE_DEPRECATIONS
#define _TP_DEPRECATED /* nothing */
#define _TP_DEPRECATED_FOR(f) /* nothing */
#define _TP_UNAVAILABLE(major, minor) /* nothing */
#define _TP_GNUC_DEPRECATED /* nothing */
#define _TP_GNUC_DEPRECATED_FOR(f) /* nothing */
#else
#define _TP_DEPRECATED G_DEPRECATED
#define _TP_DEPRECATED_FOR(f) G_DEPRECATED_FOR(f)
#define _TP_UNAVAILABLE(major, minor) G_UNAVAILABLE(major, minor)
  /* Available for typedefs etc., not just functions, but gcc-specific */
#define _TP_GNUC_DEPRECATED G_GNUC_DEPRECATED
#define _TP_GNUC_DEPRECATED_FOR(f) G_GNUC_DEPRECATED_FOR(f)
#endif

/* like G_SEAL */
#if (defined (TP_SEAL_ENABLE) || defined (TP_DISABLE_DEPRECATED)) \
  && !defined (_TP_COMPILATION)
# define _TP_SEAL(ident) _tp_sealed__ ## ident
#else
# define _TP_SEAL(ident) ident
#endif

G_END_DECLS
#endif
