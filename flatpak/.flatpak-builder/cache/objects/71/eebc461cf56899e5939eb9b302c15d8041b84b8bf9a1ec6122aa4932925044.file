/* Evolution calendar ecal
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
 *          Rodrigo Moya <rodrigo@novell.com>
 */

#if !defined (__LIBECAL_H_INSIDE__) && !defined (LIBECAL_COMPILATION)
#error "Only <libecal/libecal.h> should be included directly."
#endif

#ifndef EDS_DISABLE_DEPRECATED

#ifndef E_CAL_H
#define E_CAL_H

#include <libedataserver/libedataserver.h>

#include <libecal/e-cal-recur.h>
#include <libecal/e-cal-util.h>
#include <libecal/e-cal-view.h>
#include <libecal/e-cal-types.h>

G_BEGIN_DECLS



#define E_TYPE_CAL            (e_cal_get_type ())
#define E_CAL(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), E_TYPE_CAL, ECal))
#define E_CAL_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass), E_TYPE_CAL, ECalClass))
#define E_IS_CAL(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), E_TYPE_CAL))
#define E_IS_CAL_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), E_TYPE_CAL))

#define E_TYPE_CAL_SOURCE_TYPE (e_cal_source_type_enum_get_type ())
#define E_CAL_SET_MODE_STATUS_ENUM_TYPE (e_cal_set_mode_status_enum_get_type ())
#define CAL_MODE_ENUM_TYPE                   (cal_mode_enum_get_type ())

typedef struct _ECal ECal;
typedef struct _ECalClass ECalClass;
typedef struct _ECalPrivate ECalPrivate;

/**
 * ECalSourceType:
 * @E_CAL_SOURCE_TYPE_EVENT: Event calander
 * @E_CAL_SOURCE_TYPE_TODO: Todo list calendar
 * @E_CAL_SOURCE_TYPE_JOURNAL: Journal calendar
 *
 * Indicates the type of calendar
 *
 * Deprecated: 3.2: Use #ECalClient instead
 */
typedef enum {
	E_CAL_SOURCE_TYPE_EVENT,
	E_CAL_SOURCE_TYPE_TODO,
	E_CAL_SOURCE_TYPE_JOURNAL,
	/*< private >*/
	E_CAL_SOURCE_TYPE_LAST
} ECalSourceType;

/**
 * ECalSetModeStatus:
 * @E_CAL_SET_MODE_SUCCESS: Success
 * @E_CAL_SET_MODE_ERROR: Error
 * @E_CAL_SET_MODE_NOT_SUPPORTED: Not supported
 *
 * Status of e_cal_set_mode() function
 *
 * Deprecated: 3.2: Use #ECalClient instead
 */
typedef enum {
	E_CAL_SET_MODE_SUCCESS,
	E_CAL_SET_MODE_ERROR,
	E_CAL_SET_MODE_NOT_SUPPORTED
} ECalSetModeStatus;

/**
 * ECalLoadState:
 * @E_CAL_LOAD_NOT_LOADED: Not loaded
 * @E_CAL_LOAD_LOADING: Loading
 * @E_CAL_LOAD_LOADED: Loaded
 *
 * The current loading state reported by e_cal_get_load_state()
 *
 * Deprecated: 3.2: Use #ECalClient instead
 */
typedef enum {
	E_CAL_LOAD_NOT_LOADED,
	E_CAL_LOAD_LOADING,
	E_CAL_LOAD_LOADED
} ECalLoadState;

/**
 * EDataCalMode:
 *
 * A deprecated detail of the old #ECal API.
 *
 * Deprecated: 3.2: Use #ECalClient instead
 **/
typedef enum {
	/*< private >*/
	Local = 1 << 0,
	Remote = 1 << 1,
	AnyMode = 0x07
} EDataCalMode;

/**
 * ECal:
 *
 * The deprecated API for accessing the calendar
 *
 * Deprecated: 3.2: Use #ECalClient instead 
 */
struct _ECal {
	/*< private >*/
	GObject object;
	ECalPrivate *priv;
};

/**
 * ECalClass:
 *
 * Class structure for the deprecated API for accessing the calendar
 *
 * Deprecated: 3.2: Use #ECalClient instead 
 */
struct _ECalClass {
	/*< private >*/
	GObjectClass parent_class;

	/*
	 * Leaving the whole thing < private >, avoid documenting
	 * the deprecated vfuncs here
	 */

	/* Notification signals */
	#ifndef EDS_DISABLE_DEPRECATED
	void (* cal_opened) (ECal *ecal, ECalendarStatus status);
	#endif
	void (* cal_opened_ex) (ECal *ecal, const GError *error);
	void (* cal_set_mode) (ECal *ecal, ECalSetModeStatus status, CalMode mode);

	void (* backend_error) (ECal *ecal, const gchar *message);
	void (* backend_died) (ECal *ecal);
};

GType e_cal_get_type (void);

GType e_cal_source_type_enum_get_type (void);
GType e_cal_set_mode_status_enum_get_type (void);
GType cal_mode_enum_get_type (void);

ECal *e_cal_new (ESource *source, ECalSourceType type);

gboolean e_cal_open (ECal *ecal, gboolean only_if_exists, GError **error);
void e_cal_open_async (ECal *ecal, gboolean only_if_exists);
gboolean e_cal_refresh (ECal *ecal, GError **error);
gboolean e_cal_remove (ECal *ecal, GError **error);

GList *e_cal_uri_list (ECal *ecal, CalMode mode);

ECalSourceType e_cal_get_source_type (ECal *ecal);
ECalLoadState e_cal_get_load_state (ECal *ecal);

ESource *e_cal_get_source (ECal *ecal);

gboolean e_cal_is_read_only (ECal *ecal, gboolean *read_only, GError **error);
gboolean e_cal_get_cal_address (ECal *ecal, gchar **cal_address, GError **error);
gboolean e_cal_get_alarm_email_address (ECal *ecal, gchar **alarm_address, GError **error);
gboolean e_cal_get_ldap_attribute (ECal *ecal, gchar **ldap_attribute, GError **error);

gboolean e_cal_get_one_alarm_only (ECal *ecal);
gboolean e_cal_get_organizer_must_attend (ECal *ecal);
gboolean e_cal_get_save_schedules (ECal *ecal);
gboolean e_cal_get_static_capability (ECal *ecal, const gchar *cap);
gboolean e_cal_get_organizer_must_accept (ECal *ecal);
gboolean e_cal_get_refresh_supported (ECal *ecal);

gboolean e_cal_set_mode (ECal *ecal, CalMode mode);

gboolean e_cal_get_default_object (ECal *ecal,
				   icalcomponent **icalcomp, GError **error);

gboolean e_cal_get_object (ECal *ecal,
			   const gchar *uid,
			   const gchar *rid,
			   icalcomponent **icalcomp,
			   GError **error);
gboolean e_cal_get_objects_for_uid (ECal *ecal,
				    const gchar *uid,
				    GList **objects,
				    GError **error);

gboolean e_cal_get_changes (ECal *ecal, const gchar *change_id, GList **changes, GError **error);
void e_cal_free_change_list (GList *list);

gboolean e_cal_get_object_list (ECal *ecal, const gchar *query, GList **objects, GError **error);
gboolean e_cal_get_object_list_as_comp (ECal *ecal, const gchar *query, GList **objects, GError **error);
void e_cal_free_object_list (GList *objects);

gboolean e_cal_get_free_busy (ECal *ecal, GList *users, time_t start, time_t end,
			      GList **freebusy, GError **error);

void e_cal_generate_instances (ECal *ecal, time_t start, time_t end,
			       ECalRecurInstanceFn cb, gpointer cb_data);
void e_cal_generate_instances_for_object (ECal *ecal, icalcomponent *icalcomp,
					  time_t start, time_t end,
					  ECalRecurInstanceFn cb, gpointer cb_data);

GSList *e_cal_get_alarms_in_range (ECal *ecal, time_t start, time_t end);

void e_cal_free_alarms (GSList *comp_alarms);

gboolean e_cal_get_alarms_for_object (ECal *ecal, const ECalComponentId *id,
				      time_t start, time_t end,
				      ECalComponentAlarms **alarms);

gboolean e_cal_create_object (ECal *ecal, icalcomponent *icalcomp, gchar **uid, GError **error);
gboolean e_cal_modify_object (ECal *ecal, icalcomponent *icalcomp, ECalObjModType mod, GError **error);
gboolean e_cal_remove_object (ECal *ecal, const gchar *uid, GError **error);
gboolean e_cal_remove_object_with_mod (ECal *ecal, const gchar *uid, const gchar *rid, ECalObjModType mod, GError **error);

gboolean e_cal_discard_alarm (ECal *ecal, ECalComponent *comp, const gchar *auid, GError **error);

gboolean e_cal_receive_objects (ECal *ecal, icalcomponent *icalcomp, GError **error);
gboolean e_cal_send_objects (ECal *ecal, icalcomponent *icalcomp, GList **users, icalcomponent **modified_icalcomp, GError **error);

gboolean e_cal_get_timezone (ECal *ecal, const gchar *tzid, icaltimezone **zone, GError **error);
gboolean e_cal_add_timezone (ECal *ecal, icaltimezone *izone, GError **error);
/* Sets the default timezone to use to resolve DATE and floating DATE-TIME
 * values. This will typically be from the user's timezone setting. Call this
 * before using any other functions. It will pass the default timezone on to
 * the server. Returns TRUE on success. */
gboolean e_cal_set_default_timezone (ECal *ecal, icaltimezone *zone, GError **error);

gboolean e_cal_get_query (ECal *ecal, const gchar *sexp, ECalView **query, GError **error);

/* Resolves TZIDs for the recurrence generator. */
icaltimezone *e_cal_resolve_tzid_cb (const gchar *tzid, gpointer data);

/* Returns a complete VCALENDAR for a VEVENT/VTODO including all VTIMEZONEs
 * used by the component. It also includes a 'METHOD:PUBLISH' property. */
gchar * e_cal_get_component_as_string (ECal *ecal, icalcomponent *icalcomp);

const gchar * e_cal_get_error_message (ECalendarStatus status);

/* Calendar/Tasks Discovery */
const gchar * e_cal_get_local_attachment_store (ECal *ecal);
gboolean e_cal_get_recurrences_no_master (ECal *ecal);
gboolean e_cal_get_attachments_for_comp (ECal *ecal, const gchar *uid, const gchar *rid, GSList **list, GError **error);

G_END_DECLS

#endif /* E_CAL_H */

#endif /* EDS_DISABLE_DEPRECATED */

