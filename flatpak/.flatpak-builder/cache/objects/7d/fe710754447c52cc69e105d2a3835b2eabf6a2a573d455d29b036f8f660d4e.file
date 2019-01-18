/* Evolution calendar utilities and types
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Federico Mena-Quintero <federico@ximian.com>
 *          JP Rosevear <jpr@ximian.com>
 */

#if !defined (__LIBECAL_H_INSIDE__) && !defined (LIBECAL_COMPILATION)
#error "Only <libecal/libecal.h> should be included directly."
#endif

#ifndef E_CAL_TYPES_H
#define E_CAL_TYPES_H

#include <libecal/e-cal-component.h>

G_BEGIN_DECLS

/**
 * ECalClientSourceType:
 * @E_CAL_CLIENT_SOURCE_TYPE_EVENTS: Events calander
 * @E_CAL_CLIENT_SOURCE_TYPE_TASKS: Task list calendar
 * @E_CAL_CLIENT_SOURCE_TYPE_MEMOS: Memo list calendar
 * @E_CAL_CLIENT_SOURCE_TYPE_LAST: Artificial 'last' value of the enum
 *
 * Indicates the type of calendar
 *
 * Since: 3.2
 **/
typedef enum {
	E_CAL_CLIENT_SOURCE_TYPE_EVENTS,
	E_CAL_CLIENT_SOURCE_TYPE_TASKS,
	E_CAL_CLIENT_SOURCE_TYPE_MEMOS,
	E_CAL_CLIENT_SOURCE_TYPE_LAST  /*< skip >*/
} ECalClientSourceType;

/**
 * ECalObjModType:
 * @E_CAL_OBJ_MOD_THIS: Modify this component
 * @E_CAL_OBJ_MOD_THIS_AND_PRIOR: Modify this component and all prior occurrances
 * @E_CAL_OBJ_MOD_THIS_AND_FUTURE: Modify this component and all future occurrances
 * @E_CAL_OBJ_MOD_ALL: Modify all occurrances of this component
 * @E_CAL_OBJ_MOD_ONLY_THIS: Modify only this component
 *
 * Indicates the type of modification made to a calendar
 *
 * Since: 3.8
 **/
typedef enum {
	E_CAL_OBJ_MOD_THIS = 1 << 0,
	E_CAL_OBJ_MOD_THIS_AND_PRIOR = 1 << 1,
	E_CAL_OBJ_MOD_THIS_AND_FUTURE = 1 << 2,
	E_CAL_OBJ_MOD_ALL = 0x07,
	E_CAL_OBJ_MOD_ONLY_THIS = 1 << 3
} ECalObjModType;

/* Everything below this point is deprecated. */

#ifndef EDS_DISABLE_DEPRECATED

/**
 * E_CALENDAR_ERROR:
 *
 * The error domain for the deprecated #ECal
 *
 * Deprecated: 3.2: Use #ECalClient and it's errors instead
 */
#define E_CALENDAR_ERROR e_calendar_error_quark()

GQuark e_calendar_error_quark (void) G_GNUC_CONST;

/**
 * ECalChangeType:
 * @E_CAL_CHANGE_ADDED: A component was added
 * @E_CAL_CHANGE_MODIFIED: A component was modified
 * @E_CAL_CHANGE_DELETED: A component was deleted
 *
 * Indicates the type of change in an #ECalChange
 *
 * Deprecated: 3.2: Use #ECalClient instead
 */
typedef enum {
	E_CAL_CHANGE_ADDED = 1 << 0,
	E_CAL_CHANGE_MODIFIED = 1 << 1,
	E_CAL_CHANGE_DELETED = 1 << 2
} ECalChangeType;

/**
 * ECalChange:
 * @comp: The #ECalComponent which changed
 * @type: The #ECalChangeType which occurred
 *
 * A structure indicating a calendar change
 *
 * Deprecated: 3.2: Use #ECalClient instead
 **/
typedef struct {
	ECalComponent *comp;
	ECalChangeType type;
} ECalChange;

/**
 * ECalendarStatus:
 *
 * Error codes for the #E_CALENDAR_ERROR error domain
 *
 * Deprecated: 3.2: Use #ECalClient and it's errors instead
 */
/*
 * Marked all these deprecated errors as private to avoid
 * warnings from gtk-doc
 */
typedef enum { /*< private >*/
	E_CALENDAR_STATUS_OK,
	E_CALENDAR_STATUS_INVALID_ARG,
	E_CALENDAR_STATUS_BUSY,
	E_CALENDAR_STATUS_REPOSITORY_OFFLINE,
	E_CALENDAR_STATUS_NO_SUCH_CALENDAR,
	E_CALENDAR_STATUS_OBJECT_NOT_FOUND,
	E_CALENDAR_STATUS_INVALID_OBJECT,
	E_CALENDAR_STATUS_URI_NOT_LOADED,
	E_CALENDAR_STATUS_URI_ALREADY_LOADED,
	E_CALENDAR_STATUS_PERMISSION_DENIED,
	E_CALENDAR_STATUS_UNKNOWN_USER,
	E_CALENDAR_STATUS_OBJECT_ID_ALREADY_EXISTS,
	E_CALENDAR_STATUS_PROTOCOL_NOT_SUPPORTED,
	E_CALENDAR_STATUS_CANCELLED,
	E_CALENDAR_STATUS_COULD_NOT_CANCEL,
	E_CALENDAR_STATUS_AUTHENTICATION_FAILED,
	E_CALENDAR_STATUS_AUTHENTICATION_REQUIRED,
	E_CALENDAR_STATUS_DBUS_EXCEPTION,
	E_CALENDAR_STATUS_OTHER_ERROR,
	E_CALENDAR_STATUS_INVALID_SERVER_VERSION,
	E_CALENDAR_STATUS_NOT_SUPPORTED
} ECalendarStatus;

/**
 * E_CALENDAR_STATUS_CORBA_EXCEPTION:
 *
 * A deprecated #ECalendarStatus error code
 *
 * Deprecated: Use #ECalClient and it's errors instead
 */
#define E_CALENDAR_STATUS_CORBA_EXCEPTION E_CALENDAR_STATUS_DBUS_EXCEPTION

/**
 * EDataCalObjType:
 *
 * A deprecated object type indicator
 *
 * Deprecated
 **/
typedef enum { /*< private >*/
	Event = 1 << 0,
	Todo = 1 << 1,
	Journal = 1 << 2,
	AnyType = 0x07
} EDataCalObjType;

/**
 * EDataCalObjModType:
 *
 * A deprecated object modification type indicator
 *
 * Deprecated
 **/
typedef enum { /*< private >*/
	This = 1 << 0,
	ThisAndPrior = 1 << 1,
	ThisAndFuture = 1 << 2,
	All = 0x07
} EDataCalObjModType;

typedef ECalObjModType CalObjModType;
#define CALOBJ_MOD_THIS          E_CAL_OBJ_MOD_THIS
#define CALOBJ_MOD_THISANDPRIOR  E_CAL_OBJ_MOD_THIS_AND_PRIOR
#define CALOBJ_MOD_THISANDFUTURE E_CAL_OBJ_MOD_THIS_AND_FUTURE
#define CALOBJ_MOD_ALL           E_CAL_OBJ_MOD_ALL
#define CALOBJ_MOD_ONLY_THIS     E_CAL_OBJ_MOD_ONLY_THIS

#endif /* EDS_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* E_CAL_TYPES_H */

