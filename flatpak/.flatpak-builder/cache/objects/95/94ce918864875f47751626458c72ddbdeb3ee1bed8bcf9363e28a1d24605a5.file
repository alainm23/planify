/*
 * e-cal-client.h
 *
 * Copyright (C) 2011 Red Hat, Inc. (www.redhat.com)
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

#if !defined (__LIBECAL_H_INSIDE__) && !defined (LIBECAL_COMPILATION)
#error "Only <libecal/libecal.h> should be included directly."
#endif

#ifndef E_CAL_CLIENT_H
#define E_CAL_CLIENT_H

#include <libedataserver/libedataserver.h>

#include <libecal/e-cal-client-view.h>
#include <libecal/e-cal-recur.h>
#include <libecal/e-cal-types.h>
#include <libecal/e-cal-util.h>

/* Standard GObject macros */
#define E_TYPE_CAL_CLIENT \
	(e_cal_client_get_type ())
#define E_CAL_CLIENT(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CAL_CLIENT, ECalClient))
#define E_CAL_CLIENT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CAL_CLIENT, ECalClientClass))
#define E_IS_CAL_CLIENT(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CAL_CLIENT))
#define E_IS_CAL_CLIENT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CAL_CLIENT))
#define E_CAL_CLIENT_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CAL_CLIENT, ECalClientClass))

/**
 * CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS:
 *
 * FIXME: Document me.
 *
 * Since: 3.2
 **/
#define CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS		"cal-email-address"

/**
 * CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS:
 *
 * FIXME: Document me.
 *
 * Since: 3.2
 **/
#define CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS	"alarm-email-address"

/**
 * CAL_BACKEND_PROPERTY_DEFAULT_OBJECT:
 *
 * FIXME: Document me.
 *
 * Since: 3.2
 **/
#define CAL_BACKEND_PROPERTY_DEFAULT_OBJECT		"default-object"

/**
 * E_CAL_CLIENT_ERROR:
 *
 * FIXME: Document me.
 *
 * Since: 3.2
 **/
#define E_CAL_CLIENT_ERROR e_cal_client_error_quark ()

G_BEGIN_DECLS

/**
 * ECalClientError:
 * @E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR: No such calendar
 * @E_CAL_CLIENT_ERROR_OBJECT_NOT_FOUND: Object not found
 * @E_CAL_CLIENT_ERROR_INVALID_OBJECT: Invalid object
 * @E_CAL_CLIENT_ERROR_UNKNOWN_USER: Unknown user
 * @E_CAL_CLIENT_ERROR_OBJECT_ID_ALREADY_EXISTS: Object ID already exists
 * @E_CAL_CLIENT_ERROR_INVALID_RANGE: Invalid range
 *
 * Since: 3.2
 **/
typedef enum {
	E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR,
	E_CAL_CLIENT_ERROR_OBJECT_NOT_FOUND,
	E_CAL_CLIENT_ERROR_INVALID_OBJECT,
	E_CAL_CLIENT_ERROR_UNKNOWN_USER,
	E_CAL_CLIENT_ERROR_OBJECT_ID_ALREADY_EXISTS,
	E_CAL_CLIENT_ERROR_INVALID_RANGE
} ECalClientError;

typedef struct _ECalClient ECalClient;
typedef struct _ECalClientClass ECalClientClass;
typedef struct _ECalClientPrivate ECalClientPrivate;

/**
 * ECalClient:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.2
 **/
struct _ECalClient {
	/*< private >*/
	EClient parent;

	ECalClientPrivate *priv;
};

/**
 * ECalClientClass:
 * @free_busy_data: signal used to notify about free/busy data
 *
 * Base class structure for the #ECalClient class
 **/
struct _ECalClientClass {
	/*< private >*/
	EClientClass parent;

	/*< public >*/
	/* Signals */
	void		(*free_busy_data)	(ECalClient *client,
						 const GSList *free_busy_ecalcomps);
};

GQuark		e_cal_client_error_quark	(void) G_GNUC_CONST;
const gchar *	e_cal_client_error_to_string	(ECalClientError code);

GType		e_cal_client_get_type		(void) G_GNUC_CONST;
EClient *	e_cal_client_connect_sync	(ESource *source,
						 ECalClientSourceType source_type,
						 guint32 wait_for_connected_seconds,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_connect		(ESource *source,
						 ECalClientSourceType source_type,
						 guint32 wait_for_connected_seconds,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
EClient *	e_cal_client_connect_finish	(GAsyncResult *result,
						 GError **error);
ECalClientSourceType
		e_cal_client_get_source_type	(ECalClient *client);
const gchar *	e_cal_client_get_local_attachment_store
						(ECalClient *client);
void		e_cal_client_set_default_timezone
						(ECalClient *client,
						 icaltimezone *zone);
icaltimezone *	e_cal_client_get_default_timezone
						(ECalClient *client);
gboolean	e_cal_client_check_one_alarm_only
						(ECalClient *client);
gboolean	e_cal_client_check_save_schedules
						(ECalClient *client);
gboolean	e_cal_client_check_organizer_must_attend
						(ECalClient *client);
gboolean	e_cal_client_check_organizer_must_accept
						(ECalClient *client);
gboolean	e_cal_client_check_recurrences_no_master
						(ECalClient *client);
void		e_cal_client_free_icalcomp_slist
						(GSList *icalcomps);
void		e_cal_client_free_ecalcomp_slist
						(GSList *ecalcomps);

icaltimezone *	e_cal_client_resolve_tzid_cb	(const gchar *tzid,
						 gpointer data);
icaltimezone *	e_cal_client_resolve_tzid_sync	(const gchar *tzid,
						 gpointer cal_client,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_generate_instances	(ECalClient *client,
						 time_t start,
						 time_t end,
						 GCancellable *cancellable,
						 ECalRecurInstanceFn cb,
						 gpointer cb_data,
						 GDestroyNotify destroy_cb_data);
void		e_cal_client_generate_instances_sync
						(ECalClient *client,
						 time_t start,
						 time_t end,
						 ECalRecurInstanceFn cb,
						 gpointer cb_data);
void		e_cal_client_generate_instances_for_object
						(ECalClient *client,
						 icalcomponent *icalcomp,
						 time_t start,
						 time_t end,
						 GCancellable *cancellable,
						 ECalRecurInstanceFn cb,
						 gpointer cb_data,
						 GDestroyNotify destroy_cb_data);
void		e_cal_client_generate_instances_for_object_sync
						(ECalClient *client,
						 icalcomponent *icalcomp,
						 time_t start,
						 time_t end,
						 ECalRecurInstanceFn cb,
						 gpointer cb_data);
gchar *		e_cal_client_get_component_as_string
						(ECalClient *client,
						 icalcomponent *icalcomp);
void		e_cal_client_get_default_object	(ECalClient *client,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_get_default_object_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 icalcomponent **out_icalcomp,
						 GError **error);
gboolean	e_cal_client_get_default_object_sync
						(ECalClient *client,
						 icalcomponent **out_icalcomp,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_get_object		(ECalClient *client,
						 const gchar *uid,
						 const gchar *rid,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_get_object_finish	(ECalClient *client,
						 GAsyncResult *result,
						 icalcomponent **out_icalcomp,
						 GError **error);
gboolean	e_cal_client_get_object_sync	(ECalClient *client,
						 const gchar *uid,
						 const gchar *rid,
						 icalcomponent **out_icalcomp,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_get_objects_for_uid
						(ECalClient *client,
						 const gchar *uid,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_get_objects_for_uid_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GSList **out_ecalcomps,
						 GError **error);
gboolean	e_cal_client_get_objects_for_uid_sync
						(ECalClient *client,
						 const gchar *uid,
						 GSList **out_ecalcomps,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_get_object_list	(ECalClient *client,
						 const gchar *sexp,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_get_object_list_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GSList **out_icalcomps,
						 GError **error);
gboolean	e_cal_client_get_object_list_sync
						(ECalClient *client,
						 const gchar *sexp,
						 GSList **out_icalcomps,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_get_object_list_as_comps
						(ECalClient *client,
						 const gchar *sexp,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_get_object_list_as_comps_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GSList **out_ecalcomps,
						 GError **error);
gboolean	e_cal_client_get_object_list_as_comps_sync
						(ECalClient *client,
						 const gchar *sexp,
						 GSList **out_ecalcomps,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_get_free_busy	(ECalClient *client,
						 time_t start,
						 time_t end,
						 const GSList *users,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_get_free_busy_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GSList **out_freebusy,
						 GError **error);
gboolean	e_cal_client_get_free_busy_sync	(ECalClient *client,
						 time_t start,
						 time_t end,
						 const GSList *users,
						 GSList **out_freebusy,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_create_object	(ECalClient *client,
						 icalcomponent *icalcomp,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_create_object_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 gchar **out_uid,
						 GError **error);
gboolean	e_cal_client_create_object_sync	(ECalClient *client,
						 icalcomponent *icalcomp,
						 gchar **out_uid,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_create_objects	(ECalClient *client,
						 GSList *icalcomps,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_create_objects_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GSList **out_uids,
						 GError **error);
gboolean	e_cal_client_create_objects_sync
						(ECalClient *client,
						 GSList *icalcomps,
						 GSList **out_uids,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_modify_object	(ECalClient *client,
						 icalcomponent *icalcomp,
						 ECalObjModType mod,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_modify_object_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_cal_client_modify_object_sync	(ECalClient *client,
						 icalcomponent *icalcomp,
						 ECalObjModType mod,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_modify_objects	(ECalClient *client,
						 GSList *comps,
						 ECalObjModType mod,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_modify_objects_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_cal_client_modify_objects_sync
						(ECalClient *client,
						 GSList *comps,
						 ECalObjModType mod,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_remove_object	(ECalClient *client,
						 const gchar *uid,
						 const gchar *rid,
						 ECalObjModType mod,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_remove_object_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_cal_client_remove_object_sync	(ECalClient *client,
						 const gchar *uid,
						 const gchar *rid,
						 ECalObjModType mod,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_remove_objects	(ECalClient *client,
						 const GSList *ids,
						 ECalObjModType mod,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_remove_objects_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_cal_client_remove_objects_sync
						(ECalClient *client,
						 const GSList *ids,
						 ECalObjModType mod,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_receive_objects	(ECalClient *client,
						 icalcomponent *icalcomp,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_receive_objects_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_cal_client_receive_objects_sync
						(ECalClient *client,
						 icalcomponent *icalcomp,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_send_objects	(ECalClient *client,
						 icalcomponent *icalcomp,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_send_objects_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GSList **out_users,
						 icalcomponent **out_modified_icalcomp,
						 GError **error);
gboolean	e_cal_client_send_objects_sync	(ECalClient *client,
						 icalcomponent *icalcomp,
						 GSList **out_users,
						 icalcomponent **out_modified_icalcomp,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_get_attachment_uris
						(ECalClient *client,
						 const gchar *uid,
						 const gchar *rid,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_get_attachment_uris_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GSList **out_attachment_uris,
						 GError **error);
gboolean	e_cal_client_get_attachment_uris_sync
						(ECalClient *client,
						 const gchar *uid,
						 const gchar *rid,
						 GSList **out_attachment_uris,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_discard_alarm	(ECalClient *client,
						 const gchar *uid,
						 const gchar *rid,
						 const gchar *auid,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_discard_alarm_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_cal_client_discard_alarm_sync	(ECalClient *client,
						 const gchar *uid,
						 const gchar *rid,
						 const gchar *auid,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_get_view		(ECalClient *client,
						 const gchar *sexp,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_get_view_finish	(ECalClient *client,
						 GAsyncResult *result,
						 ECalClientView **out_view,
						 GError **error);
gboolean	e_cal_client_get_view_sync	(ECalClient *client,
						 const gchar *sexp,
						 ECalClientView **out_view,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_get_timezone	(ECalClient *client,
						 const gchar *tzid,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_get_timezone_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 icaltimezone **out_zone,
						 GError **error);
gboolean	e_cal_client_get_timezone_sync	(ECalClient *client,
						 const gchar *tzid,
						 icaltimezone **out_zone,
						 GCancellable *cancellable,
						 GError **error);
void		e_cal_client_add_timezone	(ECalClient *client,
						 icaltimezone *zone,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_cal_client_add_timezone_finish
						(ECalClient *client,
						 GAsyncResult *result,
						 GError **error);
gboolean	e_cal_client_add_timezone_sync	(ECalClient *client,
						 icaltimezone *zone,
						 GCancellable *cancellable,
						 GError **error);

#ifndef EDS_DISABLE_DEPRECATED
ECalClient *	e_cal_client_new		(ESource *source,
						 ECalClientSourceType source_type,
						 GError **error);
GError *	e_cal_client_error_create	(ECalClientError code,
						 const gchar *custom_msg);
#endif /* EDS_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* E_CAL_CLIENT_H */
