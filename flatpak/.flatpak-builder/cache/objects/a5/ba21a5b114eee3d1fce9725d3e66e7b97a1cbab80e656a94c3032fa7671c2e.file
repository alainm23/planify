/* Evolution calendar - iCalendar file backend
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 * Copyright (C) 2003 Gergő Érdi
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
 * Authors: Federico Mena-Quintero <federico@ximian.com>,
 *          Gergő Érdi <cactus@cactus.rulez.org>
 */

#ifndef E_CAL_BACKEND_CONTACTS_H
#define E_CAL_BACKEND_CONTACTS_H

#include <libedata-cal/libedata-cal.h>

/* Standard GObject macros */
#define E_TYPE_CAL_BACKEND_CONTACTS \
	(e_cal_backend_contacts_get_type ())
#define E_CAL_BACKEND_CONTACTS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CAL_BACKEND_CONTACTS, ECalBackendContacts))
#define E_CAL_BACKEND_CONTACTS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CAL_BACKEND_CONTACTS, ECalBackendContactsClass))
#define E_IS_CAL_BACKEND_CONTACTS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CAL_BACKEND_CONTACTS))
#define E_IS_CAL_BACKEND_CONTACTS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CAL_BACKEND_CONTACTS))
#define E_CAL_BACKEND_CONTACTS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CAL_BACKEND_CONTACTS, ECalBackendContactsClass))

G_BEGIN_DECLS

typedef struct _ECalBackendContacts ECalBackendContacts;
typedef struct _ECalBackendContactsClass ECalBackendContactsClass;
typedef struct _ECalBackendContactsPrivate ECalBackendContactsPrivate;

struct _ECalBackendContacts {
	ECalBackendSync backend;
	ECalBackendContactsPrivate *priv;
};

struct _ECalBackendContactsClass {
	ECalBackendSyncClass parent_class;
};

GType		e_cal_backend_contacts_get_type		(void);

G_END_DECLS

#endif /* E_CAL_BACKEND_CONTACTS_H */
