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
 */

#if !defined (__LIBECAL_H_INSIDE__) && !defined (LIBECAL_COMPILATION)
#error "Only <libecal/libecal.h> should be included directly."
#endif

#ifndef E_CAL_UTIL_H
#define E_CAL_UTIL_H

#include <libical/ical.h>
#include <time.h>
#include <libecal/e-cal-component.h>
#include <libecal/e-cal-recur.h>
#include <libecal/e-cal-types.h>

G_BEGIN_DECLS

struct _ECalClient;

/**
 * CalObjInstance:
 * @uid: UID of the object
 * @start: Start time of instance
 * @end: End time of instance
 *
 * Instance of a calendar object.  This can be an actual occurrence, a
 * recurrence, or an alarm trigger of a `real' calendar object.
 **/
typedef struct {
	gchar *uid;			/* UID of the object */
	time_t start;			/* Start time of instance */
	time_t end;			/* End time of instance */
} CalObjInstance;

void cal_obj_instance_list_free (GList *list);

void cal_obj_uid_list_free (GList *list);

icalcomponent *	e_cal_util_new_top_level	(void);
icalcomponent *	e_cal_util_new_component	(icalcomponent_kind kind);

icalcomponent *	e_cal_util_parse_ics_string	(const gchar *string);
icalcomponent *	e_cal_util_parse_ics_file	(const gchar *filename);

ECalComponentAlarms *
		e_cal_util_generate_alarms_for_comp
						(ECalComponent *comp,
						 time_t start,
						 time_t end,
						 ECalComponentAlarmAction *omit,
						 ECalRecurResolveTimezoneFn resolve_tzid,
						 gpointer user_data,
						 icaltimezone *default_timezone);
gint		e_cal_util_generate_alarms_for_list
						(GList *comps,
						 time_t start,
						 time_t end,
						 ECalComponentAlarmAction *omit,
						 GSList **comp_alarms,
						 ECalRecurResolveTimezoneFn resolve_tzid,
						 gpointer user_data,
						 icaltimezone *default_timezone);

const gchar *	e_cal_util_priority_to_string	(gint priority);
gint		e_cal_util_priority_from_string	(const gchar *string);

gchar *		e_cal_util_seconds_to_string	(gint64 seconds);

void		e_cal_util_add_timezones_from_component
						(icalcomponent *vcal_comp,
						 icalcomponent *icalcomp);

gboolean	e_cal_util_component_is_instance
						(icalcomponent *icalcomp);
gboolean	e_cal_util_component_has_alarms	(icalcomponent *icalcomp);
gboolean	e_cal_util_component_has_organizer
						(icalcomponent *icalcomp);
gboolean	e_cal_util_component_has_recurrences
						(icalcomponent *icalcomp);
gboolean	e_cal_util_component_has_rdates	(icalcomponent *icalcomp);
gboolean	e_cal_util_component_has_rrules	(icalcomponent *icalcomp);
gboolean	e_cal_util_component_has_attendee
						(icalcomponent *icalcomp);
gboolean	e_cal_util_event_dates_match	(icalcomponent *icalcomp1,
						 icalcomponent *icalcomp2);

/* The static capabilities to be supported by backends */
#define CAL_STATIC_CAPABILITY_NO_ALARM_REPEAT		"no-alarm-repeat"
#define CAL_STATIC_CAPABILITY_NO_AUDIO_ALARMS		"no-audio-alarms"
#define CAL_STATIC_CAPABILITY_NO_DISPLAY_ALARMS		"no-display-alarms"
#define CAL_STATIC_CAPABILITY_NO_EMAIL_ALARMS		"no-email-alarms"
#define CAL_STATIC_CAPABILITY_NO_PROCEDURE_ALARMS	"no-procedure-alarms"
#define CAL_STATIC_CAPABILITY_NO_TASK_ASSIGNMENT	"no-task-assignment"
#define CAL_STATIC_CAPABILITY_NO_THISANDFUTURE		"no-thisandfuture"
#define CAL_STATIC_CAPABILITY_NO_THISANDPRIOR		"no-thisandprior"
#define CAL_STATIC_CAPABILITY_NO_TRANSPARENCY		"no-transparency"

/**
 * CAL_STATIC_CAPABILITY_MEMO_START_DATE:
 *
 * Flag indicating that the backend does not support memo's start date
 *
 * Since: 3.12
 */
#define CAL_STATIC_CAPABILITY_NO_MEMO_START_DATE	"no-memo-start-date"

/**
 * CAL_STATIC_CAPABILITY_ALARM_DESCRIPTION:
 *
 * Flag indicating that the backend supports alarm description
 *
 * Since: 3.8
 */
#define CAL_STATIC_CAPABILITY_ALARM_DESCRIPTION		"alarm-description"

/**
 * CAL_STATIC_CAPABILITY_NO_ALARM_AFTER_START:
 *
 * Flag indicating that the backend does not support alarm after start the event
 *
 * Since: 3.8
 */
#define CAL_STATIC_CAPABILITY_NO_ALARM_AFTER_START	"no-alarm-after-start"

/**
 * CAL_STATIC_CAPABILITY_BULK_ADDS:
 *
 * Flag indicating that the backend supports bulk additions.
 *
 * Since: 3.6
 */
#define CAL_STATIC_CAPABILITY_BULK_ADDS			"bulk-adds"

/**
 * CAL_STATIC_CAPABILITY_BULK_MODIFIES:
 *
 * Flag indicating that the backend supports bulk modifications.
 *
 * Since: 3.6
 */
#define CAL_STATIC_CAPABILITY_BULK_MODIFIES		"bulk-modifies"

/**
 * CAL_STATIC_CAPABILITY_BULK_REMOVES:
 *
 * Flag indicating that the backend supports bulk removals.
 *
 * Since: 3.6
 */
#define CAL_STATIC_CAPABILITY_BULK_REMOVES		"bulk-removes"

/**
 * CAL_STATIC_CAPABILITY_REMOVE_ONLY_THIS:
 *
 * FIXME: Document me.
 *
 * Since: 3.2
 **/
#define CAL_STATIC_CAPABILITY_REMOVE_ONLY_THIS		"remove-only-this"

#define CAL_STATIC_CAPABILITY_ONE_ALARM_ONLY		"one-alarm-only"
#define CAL_STATIC_CAPABILITY_ORGANIZER_MUST_ATTEND	"organizer-must-attend"
#define CAL_STATIC_CAPABILITY_ORGANIZER_NOT_EMAIL_ADDRESS	"organizer-not-email-address"
#define CAL_STATIC_CAPABILITY_REMOVE_ALARMS		"remove-alarms"

/**
 * CAL_STATIC_CAPABILITY_CREATE_MESSAGES:
 *
 * Since: 2.26
 **/
#define CAL_STATIC_CAPABILITY_CREATE_MESSAGES		"create-messages"

#define CAL_STATIC_CAPABILITY_SAVE_SCHEDULES		"save-schedules"
#define CAL_STATIC_CAPABILITY_NO_CONV_TO_ASSIGN_TASK	"no-conv-to-assign-task"
#define CAL_STATIC_CAPABILITY_NO_CONV_TO_RECUR		"no-conv-to-recur"
#define CAL_STATIC_CAPABILITY_NO_GEN_OPTIONS		"no-general-options"
#define CAL_STATIC_CAPABILITY_REQ_SEND_OPTIONS		"require-send-options"
#define CAL_STATIC_CAPABILITY_RECURRENCES_NO_MASTER	"recurrences-no-master-object"
#define CAL_STATIC_CAPABILITY_ORGANIZER_MUST_ACCEPT	"organizer-must-accept"
#define CAL_STATIC_CAPABILITY_DELEGATE_SUPPORTED	"delegate-support"
#define CAL_STATIC_CAPABILITY_NO_ORGANIZER		"no-organizer"
#define CAL_STATIC_CAPABILITY_DELEGATE_TO_MANY		"delegate-to-many"
#define CAL_STATIC_CAPABILITY_HAS_UNACCEPTED_MEETING	"has-unaccepted-meeting"

/**
 * CAL_STATIC_CAPABILITY_REFRESH_SUPPORTED:
 *
 * Since: 2.30
 **/
#define CAL_STATIC_CAPABILITY_REFRESH_SUPPORTED		"refresh-supported"

/**
 * CAL_STATIC_CAPABILITY_ALL_DAY_EVENT_AS_TIME:
 *
 * Let the client know that it should store All Day event times as time
 * with a time zone, rather than as a date.
 *
 * Since: 3.18
 **/
#define CAL_STATIC_CAPABILITY_ALL_DAY_EVENT_AS_TIME	"all-day-event-as-time"

/**
 * CAL_STATIC_CAPABILITY_TASK_DATE_ONLY:
 *
 * Let the client know that the Task Start date, Due date and Completed date
 * can be entered only as dates. When the capability is not set, then these
 * can be date and time.
 *
 * Since: 3.24
 **/
#define CAL_STATIC_CAPABILITY_TASK_DATE_ONLY		"task-date-only"

/**
 * CAL_STATIC_CAPABILITY_TASK_CAN_RECUR:
 *
 * When the capability is set, the client can store and provide recurring
 * tasks, otherwise it cannot.
 *
 * Since: 3.30
 **/
#define CAL_STATIC_CAPABILITY_TASK_CAN_RECUR		"task-can-recur"

/**
 * CAL_STATIC_CAPABILITY_TASK_NO_ALARM:
 *
 * When the capability is set, the client cannot store reminders
 * on tasks, otherwise it can.
 *
 * Since: 3.30
 **/
#define CAL_STATIC_CAPABILITY_TASK_NO_ALARM		"task-no-alarm"

/**
 * CAL_STATIC_CAPABILITY_COMPONENT_COLOR:
 *
 * When the capability is set, the client supports storing color
 * for individual components.
 *
 * Since: 3.30
 **/
#define CAL_STATIC_CAPABILITY_COMPONENT_COLOR		"component-color"

/* Recurrent events. Management for instances */
icalcomponent *	e_cal_util_construct_instance	(icalcomponent *icalcomp,
						 struct icaltimetype rid);
void		e_cal_util_remove_instances	(icalcomponent *icalcomp,
						 struct icaltimetype rid,
						 ECalObjModType mod);
icalcomponent *	e_cal_util_split_at_instance	(icalcomponent *icalcomp,
						 struct icaltimetype rid,
						 struct icaltimetype master_dtstart);
gboolean	e_cal_util_is_first_instance	(ECalComponent *comp,
						 struct icaltimetype rid,
						 ECalRecurResolveTimezoneFn tz_cb,
						 gpointer tz_cb_data);

gchar *		e_cal_util_get_system_timezone_location (void);
icaltimezone *	e_cal_util_get_system_timezone (void);
void		e_cal_util_get_component_occur_times
						(ECalComponent *comp,
						 time_t * start,
						 time_t * end,
						 ECalRecurResolveTimezoneFn tz_cb,
						 gpointer tz_cb_data,
						 const icaltimezone *default_timezone,
						 icalcomponent_kind kind);

icalproperty *	e_cal_util_find_x_property	(icalcomponent *icalcomp,
						 const gchar *x_name);
gchar *		e_cal_util_dup_x_property	(icalcomponent *icalcomp,
						 const gchar *x_name);
const gchar *	e_cal_util_get_x_property	(icalcomponent *icalcomp,
						 const gchar *x_name);
void		e_cal_util_set_x_property	(icalcomponent *icalcomp,
						 const gchar *x_name,
						 const gchar *value);
gboolean	e_cal_util_remove_x_property	(icalcomponent *icalcomp,
						 const gchar *x_name);
guint		e_cal_util_remove_property_by_kind
						(icalcomponent *icalcomp,
						 icalproperty_kind kind,
						 gboolean all);

gboolean	e_cal_util_init_recur_task_sync	(icalcomponent *vtodo,
						 struct _ECalClient *cal_client,
						 GCancellable *cancellable,
						 GError **error);
gboolean	e_cal_util_mark_task_complete_sync
						(icalcomponent *vtodo,
						 time_t completed_time,
						 struct _ECalClient *cal_client,
						 GCancellable *cancellable,
						 GError **error);

#ifndef EDS_DISABLE_DEPRECATED
/* Used for mode stuff */
typedef enum {
	CAL_MODE_INVALID = -1,
	CAL_MODE_LOCAL = 1 << 0,
	CAL_MODE_REMOTE = 1 << 1,
	CAL_MODE_ANY = 0x07
} CalMode;

#define cal_mode_to_corba(mode) \
	(mode == CAL_MODE_LOCAL ? Local : \
	 mode == CAL_MODE_REMOTE ? Remote : \
	 AnyMode)
#endif /* EDS_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* E_CAL_UTIL_H */
