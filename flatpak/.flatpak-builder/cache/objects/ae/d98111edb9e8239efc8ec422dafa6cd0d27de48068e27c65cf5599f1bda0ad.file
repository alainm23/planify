/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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
 */

#ifndef E_ALARM_NOTIFY_H
#define E_ALARM_NOTIFY_H

#include <gtk/gtk.h>
#include <libecal/libecal.h>

/* Standard GObject macros */
#define E_TYPE_ALARM_NOTIFY \
	(e_alarm_notify_get_type ())
#define E_ALARM_NOTIFY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_ALARM_NOTIFY, EAlarmNotify))
#define E_ALARM_NOTIFY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_ALARM_NOTIFY, EAlarmNotifyClass))
#define E_IS_ALARM_NOTIFY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_ALARM_NOTIFY))
#define E_IS_ALARM_NOTIFY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_ALARM_NOTIFY))
#define E_ALARM_NOTIFY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_ALARM_NOTIFY, EAlarmNotifyClass))

G_BEGIN_DECLS

typedef struct _EAlarmNotify EAlarmNotify;
typedef struct _EAlarmNotifyClass EAlarmNotifyClass;
typedef struct _EAlarmNotifyPrivate EAlarmNotifyPrivate;

struct _EAlarmNotify {
	/*< private >*/
	GtkApplication parent;
	EAlarmNotifyPrivate *priv;
};

struct _EAlarmNotifyClass {
	/*< private >*/
	GtkApplicationClass parent_class;
};

GType		e_alarm_notify_get_type		(void);
EAlarmNotify *	e_alarm_notify_new		(GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* E_ALARM_NOTIFY_H */
