/*
 * e-data-cal.h
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

#if !defined (__LIBEDATA_CAL_H_INSIDE__) && !defined (LIBEDATA_CAL_COMPILATION)
#error "Only <libedata-cal/libedata-cal.h> should be included directly."
#endif

#ifndef E_DATA_CAL_H
#define E_DATA_CAL_H

#include <gio/gio.h>
#include <libedata-cal/e-data-cal-view.h>

/* Standard GObject macros */
#define E_TYPE_DATA_CAL \
	(e_data_cal_get_type ())
#define E_DATA_CAL(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_DATA_CAL, EDataCal))
#define E_DATA_CAL_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_DATA_CAL, EDataCalClass))
#define E_IS_DATA_CAL(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_DATA_CAL))
#define E_IS_DATA_CAL_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_DATA_CAL))
#define E_DATA_CAL_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_DATA_CAL, EDataCalClass))

/**
 * E_DATA_CAL_ERROR:
 *
 * Since: 2.30
 **/
#define E_DATA_CAL_ERROR e_data_cal_error_quark ()

G_BEGIN_DECLS

struct _ECalBackend;

typedef struct _EDataCal EDataCal;
typedef struct _EDataCalClass EDataCalClass;
typedef struct _EDataCalPrivate EDataCalPrivate;

struct _EDataCal {
	GObject parent;
	EDataCalPrivate *priv;
};

struct _EDataCalClass {
	GObjectClass parent_class;
};

/**
 * EDataCalCallStatus:
 * @Success: call finished successfully
 * @Busy: the backend is busy
 * @RepositoryOffline: the backend is offline
 * @PermissionDenied: the call failed due to permission restrictions
 * @InvalidRange: the provided range for the call is invalid
 * @ObjectNotFound: the requested object could not be found
 * @InvalidObject: the provided object is invalid
 * @ObjectIdAlreadyExists: the provided object has an ID which already exists
 * @AuthenticationFailed: failed to authenticate with given credentials
 * @AuthenticationRequired: authentication credentials are required to connect to the calendar
 * @UnsupportedField: requested field is not supported
 * @UnsupportedMethod: requested method is not supported
 * @UnsupportedAuthenticationMethod: requested authentication method is not supported
 * @TLSNotAvailable: TLS for connection is not available for the calendar
 * @NoSuchCal: requested calendar does not exist
 * @UnknownUser: provided user is unknown
 * @OfflineUnavailable: requested data are not available in offline
 * @SearchSizeLimitExceeded: a successful search doesn't contain all responses due to size limit
 * @SearchTimeLimitExceeded: a successful search doesn't contain all responses due to time limit
 * @InvalidQuery: a requested search query is invalid
 * @QueryRefused: a requested search query had been refused, possibly by the server
 * @CouldNotCancel: an ongoing operation cannot be cancelled
 * @OtherError: a generic error happened
 * @InvalidServerVersion: server version is invalid
 * @InvalidArg: one of the arguments of the call was invalid
 * @NotSupported: the operation is not supported
 * @NotOpened: the calendar is not opened
 *
 * Response statuses of the calls.
 *
 * Since: 3.6
 **/
typedef enum {
	Success,
	Busy,
	RepositoryOffline,
	PermissionDenied,
	InvalidRange,
	ObjectNotFound,
	InvalidObject,
	ObjectIdAlreadyExists,
	AuthenticationFailed,
	AuthenticationRequired,
	UnsupportedField,
	UnsupportedMethod,
	UnsupportedAuthenticationMethod,
	TLSNotAvailable,
	NoSuchCal,
	UnknownUser,
	OfflineUnavailable,

	/* These can be returned for successful searches, but
		indicate the result set was truncated */
	SearchSizeLimitExceeded,
	SearchTimeLimitExceeded,

	InvalidQuery,
	QueryRefused,

	CouldNotCancel,

	OtherError,
	InvalidServerVersion,
	InvalidArg,
	NotSupported,
	NotOpened
} EDataCalCallStatus;

GQuark		e_data_cal_error_quark		(void);
GError *	e_data_cal_create_error		(EDataCalCallStatus status,
						 const gchar *custom_msg);
GError *	e_data_cal_create_error_fmt	(EDataCalCallStatus status,
						 const gchar *custom_msg_fmt,
						 ...) G_GNUC_PRINTF (2, 3);
const gchar *	e_data_cal_status_to_string	(EDataCalCallStatus status);

GType		e_data_cal_get_type		(void) G_GNUC_CONST;
EDataCal *	e_data_cal_new			(struct _ECalBackend *backend,
						 GDBusConnection *connection,
						 const gchar *object_path,
						 GError **error);
struct _ECalBackend *
		e_data_cal_ref_backend		(EDataCal *cal);
GDBusConnection *
		e_data_cal_get_connection	(EDataCal *cal);
const gchar *	e_data_cal_get_object_path	(EDataCal *cal);

void		e_data_cal_respond_open		(EDataCal *cal,
						 guint32 opid,
						 GError *error);
void		e_data_cal_respond_refresh	(EDataCal *cal,
						 guint32 opid,
						 GError *error);
void		e_data_cal_respond_get_object	(EDataCal *cal,
						 guint32 opid,
						 GError *error,
						 const gchar *object);
void		e_data_cal_respond_get_object_list
						(EDataCal *cal,
						 guint32 opid,
						 GError *error,
						 const GSList *objects);
void		e_data_cal_respond_get_free_busy
						(EDataCal *cal,
						 guint32 opid,
						 GError *error,
						 const GSList *freebusy);
void		e_data_cal_respond_create_objects
						(EDataCal *cal,
						 guint32 opid,
						 GError *error,
						 const GSList *uids,
						 GSList *new_components);
void		e_data_cal_respond_modify_objects
						(EDataCal *cal,
						 guint32 opid,
						 GError *error,
						 GSList *old_components,
						 GSList *new_components);
void		e_data_cal_respond_remove_objects
						(EDataCal *cal,
						 guint32 opid,
						 GError *error,
						 const GSList *ids,
						 GSList *old_components,
						 GSList *new_components);
void		e_data_cal_respond_receive_objects
						(EDataCal *cal,
						 guint32 opid,
						 GError *error);
void		e_data_cal_respond_send_objects	(EDataCal *cal,
						 guint32 opid,
						 GError *error,
						 const GSList *users,
						 const gchar *calobj);
void		e_data_cal_respond_get_attachment_uris
						(EDataCal *cal,
						 guint32 opid,
						 GError *error,
						 const GSList *attachment_uris);
void		e_data_cal_respond_discard_alarm
						(EDataCal *cal,
						 guint32 opid,
						 GError *error);
void		e_data_cal_respond_get_timezone	(EDataCal *cal,
						 guint32 opid,
						 GError *error,
						 const gchar *tzobject);
void		e_data_cal_respond_add_timezone	(EDataCal *cal,
						 guint32 opid,
						 GError *error);
void		e_data_cal_report_error		(EDataCal *cal,
						 const gchar *message);
void		e_data_cal_report_free_busy_data
						(EDataCal *cal,
						 const GSList *freebusy);
void		e_data_cal_report_backend_property_changed
						(EDataCal *cal,
						 const gchar *prop_name,
						 const gchar *prop_value);

G_END_DECLS

#endif /* E_DATA_CAL_H */
