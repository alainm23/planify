/* Evolution calendar - iCalendar file backend for tasks
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
 *          Rodrigo Moya <rodrigo@ximian.com>
 */

#include "evolution-data-server-config.h"

#include "e-cal-backend-file-todos.h"

G_DEFINE_TYPE (
	ECalBackendFileTodos,
	e_cal_backend_file_todos,
	E_TYPE_CAL_BACKEND_FILE)

static void
e_cal_backend_file_todos_class_init (ECalBackendFileTodosClass *class)
{
}

static void
e_cal_backend_file_todos_init (ECalBackendFileTodos *cbfile)
{
	e_cal_backend_file_set_file_name (
		E_CAL_BACKEND_FILE (cbfile), "tasks.ics");
}

