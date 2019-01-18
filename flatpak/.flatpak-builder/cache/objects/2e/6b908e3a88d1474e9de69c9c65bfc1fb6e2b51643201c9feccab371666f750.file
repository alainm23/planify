/*
 * e-backend-enums.h
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#if !defined (__LIBEBACKEND_H_INSIDE__) && !defined (LIBEBACKEND_COMPILATION)
#error "Only <libebackend/libebackend.h> should be included directly."
#endif

#ifndef E_BACKEND_ENUMS_H
#define E_BACKEND_ENUMS_H

/**
 * EAuthenticationSessionResult:
 * @E_AUTHENTICATION_SESSION_ERROR:
 *   An error occurred while authenticating.
 * @E_AUTHENTICATION_SESSION_SUCCESS:
 *   Client reported successful authentication.
 * @E_AUTHENTICATION_SESSION_DISMISSED:
 *   User dismissed the authentication prompt.
 *
 * Completion codes used by #EAuthenticationSession.
 *
 * Since: 3.6
 **/
typedef enum {
	E_AUTHENTICATION_SESSION_ERROR,
	E_AUTHENTICATION_SESSION_SUCCESS,
	E_AUTHENTICATION_SESSION_DISMISSED
} EAuthenticationSessionResult;

/**
 * EDBusServerExitCode:
 * @E_DBUS_SERVER_EXIT_NONE:
 *   The server's run state is unchanged.
 * @E_DBUS_SERVER_EXIT_NORMAL:
 *   Normal termination.  The process itself may now terminate.
 * @E_DBUS_SERVER_EXIT_RELOAD:
 *   The server should reload its configuration and start again.
 *   Servers that do not support reloading may wish to intercept
 *   this exit code and stop the #EDBusServer::quit-server emission.
 *
 * Exit codes submitted to e_dbus_server_quit() and returned by
 * e_dbus_server_run().
 *
 * Since: 3.6
 **/
typedef enum {
	E_DBUS_SERVER_EXIT_NONE,
	E_DBUS_SERVER_EXIT_NORMAL,
	E_DBUS_SERVER_EXIT_RELOAD
} EDBusServerExitCode;

/**
 * ESourcePermissionFlags:
 * @E_SOURCE_PERMISSION_NONE:
 *   The data source gets no initial permissions.
 * @E_SOURCE_PERMISSION_WRITABLE:
 *   The data source is initially writable.
 * @E_SOURCE_PERMISSION_REMOVABLE:
 *   The data source is initially removable.
 *
 * Initial permissions for a newly-loaded data source key file.
 *
 * Since: 3.6
 **/
typedef enum { /*< flags >*/
	E_SOURCE_PERMISSION_NONE = 0,
	E_SOURCE_PERMISSION_WRITABLE = 1 << 0,
	E_SOURCE_PERMISSION_REMOVABLE = 1 << 1
} ESourcePermissionFlags;

/**
 * EOfflineState:
 * @E_OFFLINE_STATE_UNKNOWN: Unknown offline state.
 * @E_OFFLINE_STATE_SYNCED: The object if synchnized with no local changes.
 * @E_OFFLINE_STATE_LOCALLY_CREATED: The object is locally created.
 * @E_OFFLINE_STATE_LOCALLY_MODIFIED: The object is locally modified.
 * @E_OFFLINE_STATE_LOCALLY_DELETED: The object is locally deleted.
 *
 * Defines offline state of an object. Locally changed objects require
 * synchronization with their remote storage.
 *
 * Since: 3.26
 **/
typedef enum {
	E_OFFLINE_STATE_UNKNOWN = -1,
	E_OFFLINE_STATE_SYNCED,
	E_OFFLINE_STATE_LOCALLY_CREATED,
	E_OFFLINE_STATE_LOCALLY_MODIFIED,
	E_OFFLINE_STATE_LOCALLY_DELETED
} EOfflineState;

/**
 * EConflictResolution:
 * @E_CONFLICT_RESOLUTION_FAIL: Fail when a write-conflict occurs.
 * @E_CONFLICT_RESOLUTION_USE_NEWER: Use newer version of the object,
 *    which can be either the server version or the local version of it.
 * @E_CONFLICT_RESOLUTION_KEEP_SERVER: Keep server object on conflict.
 * @E_CONFLICT_RESOLUTION_KEEP_LOCAL: Write local version of the object on conflict.
 * @E_CONFLICT_RESOLUTION_WRITE_COPY: Create a new copy of the object on conflict.
 *
 * Defines what to do when a conflict between the locally stored and
 * remotely stored object versions happen during object modify or remove.
 *
 * Since: 3.26
 **/
typedef enum {
	E_CONFLICT_RESOLUTION_FAIL = 0,
	E_CONFLICT_RESOLUTION_USE_NEWER,
	E_CONFLICT_RESOLUTION_KEEP_SERVER,
	E_CONFLICT_RESOLUTION_KEEP_LOCAL,
	E_CONFLICT_RESOLUTION_WRITE_COPY
} EConflictResolution;

#endif /* E_BACKEND_ENUMS_H */
