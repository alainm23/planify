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

#if !defined (__LIBECAL_H_INSIDE__) && !defined (LIBECAL_COMPILATION)
#error "Only <libecal/libecal.h> should be included directly."
#endif

#ifndef E_REMINDER_WATCHER_H
#define E_REMINDER_WATCHER_H

#include <libedataserver/libedataserver.h>
#include <libecal/e-cal-client.h>

/* Standard GObject macros */
#define E_TYPE_REMINDER_WATCHER \
	(e_reminder_watcher_get_type ())
#define E_REMINDER_WATCHER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_REMINDER_WATCHER, EReminderWatcher))
#define E_REMINDER_WATCHER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_REMINDER_WATCHER, EReminderWatcherClass))
#define E_IS_REMINDER_WATCHER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_REMINDER_WATCHER))
#define E_IS_REMINDER_WATCHER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_REMINDER_WATCHER))
#define E_REMINDER_WATCHER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_REMINDER_WATCHER, EReminderWatcherClass))

#define E_TYPE_REMINDER_DATA (e_reminder_data_get_type ())
#define E_TYPE_REMINDER_WATCHER_ZONE (e_reminder_watcher_zone_get_type ())

G_BEGIN_DECLS

/**
 * EReminderData:
 * @source_uid: the source UID
 * @component: the #ECalComponent that triggered the reminder
 * @instance: the #ECalComponentAlarmInstance describing the reminder alarm
 *
 * Contains data related to single reminder occurrence.
 *
 * Since: 3.30
 **/
typedef struct _EReminderData {
	gchar *source_uid;
	ECalComponent *component;
	ECalComponentAlarmInstance instance;
} EReminderData;

GType		e_reminder_data_get_type	(void) G_GNUC_CONST;
EReminderData *	e_reminder_data_new		(const gchar *source_uid,
						 const ECalComponent *component,
						 const ECalComponentAlarmInstance *instance);
EReminderData *	e_reminder_data_copy		(const EReminderData *rd);
void		e_reminder_data_free		(gpointer rd); /* EReminderData * */

/**
 * EReminderWatcherZone:
 *
 * A libical's icaltimezone encapsulated as a GBoxed type.
 * It can be retyped into icaltimezone directly.
 *
 * Since: 3.30
 **/
typedef icaltimezone EReminderWatcherZone;

GType		e_reminder_watcher_zone_get_type(void) G_GNUC_CONST;
EReminderWatcherZone *
		e_reminder_watcher_zone_copy	(const EReminderWatcherZone *watcher_zone);
void		e_reminder_watcher_zone_free	(EReminderWatcherZone *watcher_zone);

typedef struct _EReminderWatcher EReminderWatcher;
typedef struct _EReminderWatcherClass EReminderWatcherClass;
typedef struct _EReminderWatcherPrivate EReminderWatcherPrivate;

/**
 * EReminderWatcherDescribeFlags:
 * @E_REMINDER_WATCHER_DESCRIBE_FLAG_NONE: None flags
 * @E_REMINDER_WATCHER_DESCRIBE_FLAG_MARKUP: Returned description will contain
 *    also markup. Without it it'll be a plain text.
 *
 * Flags modifying behaviour of e_reminder_watcher_describe_data().
 *
 * Since: 3.30
 **/
typedef enum { /*< flags >*/
	E_REMINDER_WATCHER_DESCRIBE_FLAG_NONE	= 0,
	E_REMINDER_WATCHER_DESCRIBE_FLAG_MARKUP = (1 << 1)
} EReminderWatcherDescribeFlags;

/**
 * EReminderWatcher:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.30
 **/
struct _EReminderWatcher {
	/*< private >*/
	GObject parent;
	EReminderWatcherPrivate *priv;
};

struct _EReminderWatcherClass {
	GObjectClass parent_class;

	/* Virtual methods and signals */
	void		(* schedule_timer)	(EReminderWatcher *watcher,
						 gint64 at_time);
	void		(* format_time)		(EReminderWatcher *watcher,
						 const EReminderData *rd,
						 struct icaltimetype *itt,
						 gchar **inout_buffer,
						 gint buffer_size);
	void		(* triggered)		(EReminderWatcher *watcher,
						 const GSList *reminders, /* EReminderData * */
						 gboolean snoozed);
	void		(* changed)		(EReminderWatcher *watcher);
	EClient *	(* cal_client_connect_sync)
						(EReminderWatcher *watcher,
						 ESource *source,
						 ECalClientSourceType source_type,
						 guint32 wait_for_connected_seconds,
						 GCancellable *cancellable,
						 GError **error);
	void		(* cal_client_connect)	(EReminderWatcher *watcher,
						 ESource *source,
						 ECalClientSourceType source_type,
						 guint32 wait_for_connected_seconds,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
	EClient *	(* cal_client_connect_finish)
						(EReminderWatcher *watcher,
						 GAsyncResult *result,
						 GError **error);

	/* Padding for future expansion */
	gpointer reserved[7];
};

GType		e_reminder_watcher_get_type		(void) G_GNUC_CONST;
EReminderWatcher *
		e_reminder_watcher_new			(ESourceRegistry *registry);
ESourceRegistry *
		e_reminder_watcher_get_registry		(EReminderWatcher *watcher);
ECalClient *	e_reminder_watcher_ref_opened_client	(EReminderWatcher *watcher,
							 const gchar *source_uid);
void		e_reminder_watcher_set_default_zone	(EReminderWatcher *watcher,
							 const icaltimezone *zone);
icaltimezone *	e_reminder_watcher_dup_default_zone	(EReminderWatcher *watcher);
gboolean	e_reminder_watcher_get_timers_enabled	(EReminderWatcher *watcher);
void		e_reminder_watcher_set_timers_enabled	(EReminderWatcher *watcher,
							 gboolean enabled);
gchar *		e_reminder_watcher_describe_data	(EReminderWatcher *watcher,
							 const EReminderData *rd,
							 guint32 flags); /* bit-or of EReminderWatcherDescribeFlags */
void		e_reminder_watcher_timer_elapsed	(EReminderWatcher *watcher);
GSList *	e_reminder_watcher_dup_past		(EReminderWatcher *watcher); /* EReminderData * */
GSList *	e_reminder_watcher_dup_snoozed		(EReminderWatcher *watcher); /* EReminderData * */
void		e_reminder_watcher_snooze		(EReminderWatcher *watcher,
							 const EReminderData *rd,
							 gint64 until);
void		e_reminder_watcher_dismiss		(EReminderWatcher *watcher,
							 const EReminderData *rd,
							 GCancellable *cancellable,
							 GAsyncReadyCallback callback,
							 gpointer user_data);
gboolean	e_reminder_watcher_dismiss_finish	(EReminderWatcher *watcher,
							 GAsyncResult *result,
							 GError **error);
gboolean	e_reminder_watcher_dismiss_sync		(EReminderWatcher *watcher,
							 const EReminderData *rd,
							 GCancellable *cancellable,
							 GError **error);
void		e_reminder_watcher_dismiss_all		(EReminderWatcher *watcher,
							 GCancellable *cancellable,
							 GAsyncReadyCallback callback,
							 gpointer user_data);
gboolean	e_reminder_watcher_dismiss_all_finish	(EReminderWatcher *watcher,
							 GAsyncResult *result,
							 GError **error);
gboolean	e_reminder_watcher_dismiss_all_sync	(EReminderWatcher *watcher,
							 GCancellable *cancellable,
							 GError **error);

G_END_DECLS

#endif /* E_REMINDER_WATCHER_H */
