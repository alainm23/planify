/* Evolution calendar - iCalendar file backend
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
 */

#ifndef E_CAL_BACKEND_FILE_H
#define E_CAL_BACKEND_FILE_H

#include <libedata-cal/libedata-cal.h>

/* Standard GObject macros */
#define E_TYPE_CAL_BACKEND_FILE \
	(e_cal_backend_file_get_type ())
#define E_CAL_BACKEND_FILE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CAL_BACKEND_FILE, ECalBackendFile))
#define E_CAL_BACKEND_FILE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CAL_BACKEND_FILE, ECalBackendFileClass))
#define E_IS_CAL_BACKEND_FILE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CAL_BACKEND_FILE))
#define E_IS_CAL_BACKEND_FILE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CAL_BACKEND_FILE))
#define E_CAL_BACKEND_FILE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CAL_BACKEND_FILE, ECalBackendFileClass))

G_BEGIN_DECLS

typedef struct _ECalBackendFile ECalBackendFile;
typedef struct _ECalBackendFileClass ECalBackendFileClass;
typedef struct _ECalBackendFilePrivate ECalBackendFilePrivate;

struct _ECalBackendFile {
	ECalBackendSync parent;
	ECalBackendFilePrivate *priv;
};

struct _ECalBackendFileClass {
	ECalBackendSyncClass parent_class;
};

GType		e_cal_backend_file_get_type	(void);
const gchar *	e_cal_backend_file_get_file_name
						(ECalBackendFile *cbfile);
void		e_cal_backend_file_set_file_name
						(ECalBackendFile *cbfile,
						 const gchar *file_name);
void		e_cal_backend_file_reload	(ECalBackendFile *cbfile,
						 GError **error);

G_END_DECLS

#endif /* E_CAL_BACKEND_FILE_H */
