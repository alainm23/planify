/*
 * e-data-cal.c
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

/**
 * SECTION: e-data-cal
 * @include: libedata-cal/libedata-cal.h
 * @short_description: Server side D-Bus layer to communicate with calendars
 *
 * This class communicates with #ECalClients over the bus and accesses
 * an #ECalBackend to satisfy client requests.
 **/

#include "evolution-data-server-config.h"

#include <libical/ical.h>
#include <glib/gi18n-lib.h>
#include <unistd.h>

/* Private D-Bus classes. */
#include <e-dbus-calendar.h>

#include <libedataserver/libedataserver.h>

#include "e-data-cal.h"
#include "e-cal-backend.h"
#include "e-cal-backend-sexp.h"

#define E_DATA_CAL_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_DATA_CAL, EDataCalPrivate))

#define EDC_ERROR(_code) e_data_cal_create_error (_code, NULL)
#define EDC_ERROR_EX(_code, _msg) e_data_cal_create_error (_code, _msg)

typedef struct _AsyncContext AsyncContext;

struct _EDataCalPrivate {
	GDBusConnection *connection;
	EDBusCalendar *dbus_interface;
	GWeakRef backend;
	gchar *object_path;

	GMutex sender_lock;
	GHashTable *sender_table;
};

struct _AsyncContext {
	EDataCal *data_cal;
	EDBusCalendar *dbus_interface;
	GDBusMethodInvocation *invocation;
	GCancellable *cancellable;
	guint watcher_id;
};

enum {
	PROP_0,
	PROP_BACKEND,
	PROP_CONNECTION,
	PROP_OBJECT_PATH
};

/* Forward Declarations */
static void	e_data_cal_initable_init	(GInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	EDataCal,
	e_data_cal,
	G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_data_cal_initable_init))

static void
sender_vanished_cb (GDBusConnection *connection,
                    const gchar *sender,
                    GCancellable *cancellable)
{
	g_cancellable_cancel (cancellable);
}

static void
sender_table_insert (EDataCal *data_cal,
                     const gchar *sender,
                     GCancellable *cancellable)
{
	GHashTable *sender_table;
	GPtrArray *array;

	g_return_if_fail (sender != NULL);

	g_mutex_lock (&data_cal->priv->sender_lock);

	sender_table = data_cal->priv->sender_table;
	array = g_hash_table_lookup (sender_table, sender);

	if (array == NULL) {
		array = g_ptr_array_new_with_free_func (
			(GDestroyNotify) g_object_unref);
		g_hash_table_insert (
			sender_table, g_strdup (sender), array);
	}

	g_ptr_array_add (array, g_object_ref (cancellable));

	g_mutex_unlock (&data_cal->priv->sender_lock);
}

static gboolean
sender_table_remove (EDataCal *data_cal,
                     const gchar *sender,
                     GCancellable *cancellable)
{
	GHashTable *sender_table;
	GPtrArray *array;
	gboolean removed = FALSE;

	g_return_val_if_fail (sender != NULL, FALSE);

	g_mutex_lock (&data_cal->priv->sender_lock);

	sender_table = data_cal->priv->sender_table;
	array = g_hash_table_lookup (sender_table, sender);

	if (array != NULL) {
		removed = g_ptr_array_remove_fast (array, cancellable);

		if (array->len == 0)
			g_hash_table_remove (sender_table, sender);
	}

	g_mutex_unlock (&data_cal->priv->sender_lock);

	return removed;
}

static AsyncContext *
async_context_new (EDataCal *data_cal,
                   GDBusMethodInvocation *invocation)
{
	AsyncContext *async_context;
	EDBusCalendar *dbus_interface;

	dbus_interface = data_cal->priv->dbus_interface;

	async_context = g_slice_new0 (AsyncContext);
	async_context->data_cal = g_object_ref (data_cal);
	async_context->dbus_interface = g_object_ref (dbus_interface);
	async_context->invocation = g_object_ref (invocation);
	async_context->cancellable = g_cancellable_new ();

	async_context->watcher_id = g_bus_watch_name_on_connection (
		g_dbus_method_invocation_get_connection (invocation),
		g_dbus_method_invocation_get_sender (invocation),
		G_BUS_NAME_WATCHER_FLAGS_NONE,
		(GBusNameAppearedCallback) NULL,
		(GBusNameVanishedCallback) sender_vanished_cb,
		g_object_ref (async_context->cancellable),
		(GDestroyNotify) g_object_unref);

	sender_table_insert (
		async_context->data_cal,
		g_dbus_method_invocation_get_sender (invocation),
		async_context->cancellable);

	return async_context;
}

static void
async_context_free (AsyncContext *async_context)
{
	sender_table_remove (
		async_context->data_cal,
		g_dbus_method_invocation_get_sender (
			async_context->invocation),
		async_context->cancellable);

	g_clear_object (&async_context->data_cal);
	g_clear_object (&async_context->dbus_interface);
	g_clear_object (&async_context->invocation);
	g_clear_object (&async_context->cancellable);

	if (async_context->watcher_id > 0)
		g_bus_unwatch_name (async_context->watcher_id);

	g_slice_free (AsyncContext, async_context);
}

static gchar *
construct_calview_path (void)
{
	static volatile gint counter = 1;

	g_atomic_int_inc (&counter);

	return g_strdup_printf (
		"/org/gnome/evolution/dataserver/CalendarView/%d/%d",
		getpid (), counter);
}

static void
data_cal_convert_to_client_error (GError *error)
{
	g_return_if_fail (error != NULL);

	/* Data-Factory returns common error for unknown/broken ESource-s */
	if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND)) {
		error->domain = E_CAL_CLIENT_ERROR;
		error->code = E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR;

		return;
	}

	if (error->domain != E_DATA_CAL_ERROR)
		return;

	switch (error->code) {
		case RepositoryOffline:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_REPOSITORY_OFFLINE;
			break;

		case PermissionDenied:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_PERMISSION_DENIED;
			break;

		case InvalidRange:
			error->domain = E_CAL_CLIENT_ERROR;
			error->code = E_CAL_CLIENT_ERROR_INVALID_RANGE;
			break;

		case ObjectNotFound:
			error->domain = E_CAL_CLIENT_ERROR;
			error->code = E_CAL_CLIENT_ERROR_OBJECT_NOT_FOUND;
			break;

		case InvalidObject:
			error->domain = E_CAL_CLIENT_ERROR;
			error->code = E_CAL_CLIENT_ERROR_INVALID_OBJECT;
			break;

		case ObjectIdAlreadyExists:
			error->domain = E_CAL_CLIENT_ERROR;
			error->code = E_CAL_CLIENT_ERROR_OBJECT_ID_ALREADY_EXISTS;
			break;

		case AuthenticationFailed:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_AUTHENTICATION_FAILED;
			break;

		case AuthenticationRequired:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_AUTHENTICATION_REQUIRED;
			break;

		case UnsupportedAuthenticationMethod:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_UNSUPPORTED_AUTHENTICATION_METHOD;
			break;

		case TLSNotAvailable:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_TLS_NOT_AVAILABLE;
			break;

		case NoSuchCal:
			error->domain = E_CAL_CLIENT_ERROR;
			error->code = E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR;
			break;

		case UnknownUser:
			error->domain = E_CAL_CLIENT_ERROR;
			error->code = E_CAL_CLIENT_ERROR_UNKNOWN_USER;
			break;

		case OfflineUnavailable:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_OFFLINE_UNAVAILABLE;
			break;

		case SearchSizeLimitExceeded:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_SEARCH_SIZE_LIMIT_EXCEEDED;
			break;

		case SearchTimeLimitExceeded:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_SEARCH_TIME_LIMIT_EXCEEDED;
			break;

		case InvalidQuery:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_INVALID_QUERY;
			break;

		case QueryRefused:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_QUERY_REFUSED;
			break;

		case CouldNotCancel:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_COULD_NOT_CANCEL;
			break;

		case InvalidArg:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_INVALID_ARG;
			break;

		case NotSupported:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_NOT_SUPPORTED;
			break;

		case NotOpened:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_NOT_OPENED;
			break;

		case UnsupportedField:
		case UnsupportedMethod:
		case OtherError:
		case InvalidServerVersion:
			error->domain = E_CLIENT_ERROR;
			error->code = E_CLIENT_ERROR_OTHER_ERROR;
			break;

		default:
			g_warn_if_reached ();
	}
}

/* Create the EDataCal error quark */
GQuark
e_data_cal_error_quark (void)
{
	#define ERR_PREFIX "org.gnome.evolution.dataserver.Calendar."

	static const GDBusErrorEntry entries[] = {
		{ Success,				ERR_PREFIX "Success" },
		{ Busy,					ERR_PREFIX "Busy" },
		{ RepositoryOffline,			ERR_PREFIX "RepositoryOffline" },
		{ PermissionDenied,			ERR_PREFIX "PermissionDenied" },
		{ InvalidRange,				ERR_PREFIX "InvalidRange" },
		{ ObjectNotFound,			ERR_PREFIX "ObjectNotFound" },
		{ InvalidObject,			ERR_PREFIX "InvalidObject" },
		{ ObjectIdAlreadyExists,		ERR_PREFIX "ObjectIdAlreadyExists" },
		{ AuthenticationFailed,			ERR_PREFIX "AuthenticationFailed" },
		{ AuthenticationRequired,		ERR_PREFIX "AuthenticationRequired" },
		{ UnsupportedField,			ERR_PREFIX "UnsupportedField" },
		{ UnsupportedMethod,			ERR_PREFIX "UnsupportedMethod" },
		{ UnsupportedAuthenticationMethod,	ERR_PREFIX "UnsupportedAuthenticationMethod" },
		{ TLSNotAvailable,			ERR_PREFIX "TLSNotAvailable" },
		{ NoSuchCal,				ERR_PREFIX "NoSuchCal" },
		{ UnknownUser,				ERR_PREFIX "UnknownUser" },
		{ OfflineUnavailable,			ERR_PREFIX "OfflineUnavailable" },
		{ SearchSizeLimitExceeded,		ERR_PREFIX "SearchSizeLimitExceeded" },
		{ SearchTimeLimitExceeded,		ERR_PREFIX "SearchTimeLimitExceeded" },
		{ InvalidQuery,				ERR_PREFIX "InvalidQuery" },
		{ QueryRefused,				ERR_PREFIX "QueryRefused" },
		{ CouldNotCancel,			ERR_PREFIX "CouldNotCancel" },
		{ OtherError,				ERR_PREFIX "OtherError" },
		{ InvalidServerVersion,			ERR_PREFIX "InvalidServerVersion" },
		{ InvalidArg,				ERR_PREFIX "InvalidArg" },
		{ NotSupported,				ERR_PREFIX "NotSupported" },
		{ NotOpened,				ERR_PREFIX "NotOpened" }
	};

	#undef ERR_PREFIX

	static volatile gsize quark_volatile = 0;

	g_dbus_error_register_error_domain ("e-data-cal-error", &quark_volatile, entries, G_N_ELEMENTS (entries));

	return (GQuark) quark_volatile;
}

/**
 * e_data_cal_status_to_string:
 * @status: an #EDataCalCallStatus
 *
 * Returns: A localized text representation of the @status.
 *
 * Since: 2.32
 **/
const gchar *
e_data_cal_status_to_string (EDataCalCallStatus status)
{
	gint i;
	static struct _statuses {
		EDataCalCallStatus status;
		const gchar *msg;
	} statuses[] = {
		{ Success,				N_("Success") },
		{ Busy,					N_("Backend is busy") },
		{ RepositoryOffline,			N_("Repository offline") },
		{ PermissionDenied,			N_("Permission denied") },
		{ InvalidRange,				N_("Invalid range") },
		{ ObjectNotFound,			N_("Object not found") },
		{ InvalidObject,			N_("Invalid object") },
		{ ObjectIdAlreadyExists,		N_("Object ID already exists") },
		{ AuthenticationFailed,			N_("Authentication Failed") },
		{ AuthenticationRequired,		N_("Authentication Required") },
		{ UnsupportedField,			N_("Unsupported field") },
		{ UnsupportedMethod,			N_("Unsupported method") },
		{ UnsupportedAuthenticationMethod,	N_("Unsupported authentication method") },
		{ TLSNotAvailable,			N_("TLS not available") },
		{ NoSuchCal,				N_("Calendar does not exist") },
		{ UnknownUser,				N_("Unknown user") },
		{ OfflineUnavailable,			N_("Not available in offline mode") },
		{ SearchSizeLimitExceeded,		N_("Search size limit exceeded") },
		{ SearchTimeLimitExceeded,		N_("Search time limit exceeded") },
		{ InvalidQuery,				N_("Invalid query") },
		{ QueryRefused,				N_("Query refused") },
		{ CouldNotCancel,			N_("Could not cancel") },
		/* { OtherError,			N_("Other error") }, */
		{ InvalidServerVersion,			N_("Invalid server version") },
		{ InvalidArg,				N_("Invalid argument") },
		/* Translators: The string for NOT_SUPPORTED error */
		{ NotSupported,				N_("Not supported") },
		{ NotOpened,				N_("Backend is not opened yet") }
	};

	for (i = 0; i < G_N_ELEMENTS (statuses); i++) {
		if (statuses[i].status == status)
			return _(statuses[i].msg);
	}

	return _("Other error");
}

/**
 * e_data_cal_create_error:
 * @status: #EDataCalCallStatus code
 * @custom_msg: Custom message to use for the error. When NULL,
 *              then uses a default message based on the @status code.
 *
 * Returns: (nullable) (transfer full): %NULL, when the @status is Success,
 *          or a newly allocated GError, which should be freed
 *          with g_error_free() call.
 *
 * Since: 2.32
 **/
GError *
e_data_cal_create_error (EDataCalCallStatus status,
                         const gchar *custom_msg)
{
	if (status == Success)
		return NULL;

	return g_error_new_literal (E_DATA_CAL_ERROR, status, custom_msg ? custom_msg : e_data_cal_status_to_string (status));
}

/**
 * e_data_cal_create_error_fmt:
 * @status: an #EDataCalCallStatus
 * @custom_msg_fmt: (nullable): message format, or %NULL to use the default message for the @status
 * @...: arguments for the format
 *
 * Similar as e_data_cal_create_error(), only here, instead of custom_msg,
 * is used a printf() format to create a custom message for the error.
 *
 * Returns: (nullable) (transfer full): %NULL, when the @status is Success,
 *   or a newly allocated #GError, which should be freed with g_error_free() call.
 *   The #GError has set the custom message, or the default message for
 *   @status, when @custom_msg_fmt is %NULL.
 *
 * Since: 2.32
 **/
GError *
e_data_cal_create_error_fmt (EDataCalCallStatus status,
                             const gchar *custom_msg_fmt,
                             ...)
{
	GError *error;
	gchar *custom_msg;
	va_list ap;

	if (!custom_msg_fmt)
		return e_data_cal_create_error (status, NULL);

	va_start (ap, custom_msg_fmt);
	custom_msg = g_strdup_vprintf (custom_msg_fmt, ap);
	va_end (ap);

	error = e_data_cal_create_error (status, custom_msg);

	g_free (custom_msg);

	return error;
}

static GPtrArray *
data_cal_encode_properties (EDBusCalendar *dbus_interface)
{
	GPtrArray *properties_array;

	g_warn_if_fail (E_DBUS_IS_CALENDAR (dbus_interface));

	properties_array = g_ptr_array_new_with_free_func (g_free);

	if (dbus_interface) {
		GParamSpec **properties;
		guint ii, n_properties = 0;

		properties = g_object_class_list_properties (G_OBJECT_GET_CLASS (dbus_interface), &n_properties);

		for (ii = 0; ii < n_properties; ii++) {
			gboolean can_process =
				g_type_is_a (properties[ii]->value_type, G_TYPE_BOOLEAN) ||
				g_type_is_a (properties[ii]->value_type, G_TYPE_STRING) ||
				g_type_is_a (properties[ii]->value_type, G_TYPE_STRV) ||
				g_type_is_a (properties[ii]->value_type, G_TYPE_UCHAR) ||
				g_type_is_a (properties[ii]->value_type, G_TYPE_INT) ||
				g_type_is_a (properties[ii]->value_type, G_TYPE_UINT) ||
				g_type_is_a (properties[ii]->value_type, G_TYPE_INT64) ||
				g_type_is_a (properties[ii]->value_type, G_TYPE_UINT64) ||
				g_type_is_a (properties[ii]->value_type, G_TYPE_DOUBLE);

			if (can_process) {
				GValue value = G_VALUE_INIT;
				GVariant *stored = NULL;

				g_value_init (&value, properties[ii]->value_type);
				g_object_get_property ((GObject *) dbus_interface, properties[ii]->name, &value);

				#define WORKOUT(gvl, gvr) \
					if (g_type_is_a (properties[ii]->value_type, G_TYPE_ ## gvl)) \
						stored = g_dbus_gvalue_to_gvariant (&value, G_VARIANT_TYPE_ ## gvr);

				WORKOUT (BOOLEAN, BOOLEAN);
				WORKOUT (STRING, STRING);
				WORKOUT (STRV, STRING_ARRAY);
				WORKOUT (UCHAR, BYTE);
				WORKOUT (INT, INT32);
				WORKOUT (UINT, UINT32);
				WORKOUT (INT64, INT64);
				WORKOUT (UINT64, UINT64);
				WORKOUT (DOUBLE, DOUBLE);

				#undef WORKOUT

				g_value_unset (&value);

				if (stored) {
					g_ptr_array_add (properties_array, g_strdup (properties[ii]->name));
					g_ptr_array_add (properties_array, g_variant_print (stored, TRUE));

					g_variant_unref (stored);
				}
			}
		}

		g_free (properties);
	}

	g_ptr_array_add (properties_array, NULL);

	return properties_array;
}

static gboolean
data_cal_handle_retrieve_properties_cb (EDBusCalendar *dbus_interface,
					GDBusMethodInvocation *invocation,
					EDataCal *data_cal)
{
	GPtrArray *properties_array;

	properties_array = data_cal_encode_properties (dbus_interface);

	e_dbus_calendar_complete_retrieve_properties (
		dbus_interface,
		invocation,
		(const gchar * const *) properties_array->pdata);

	g_ptr_array_free (properties_array, TRUE);

	return TRUE;
}

static void
data_cal_complete_open_cb (GObject *source_object,
                           GAsyncResult *result,
                           gpointer user_data)
{
	AsyncContext *async_context = user_data;
	GError *error = NULL;

	e_cal_backend_open_finish (
		E_CAL_BACKEND (source_object), result, &error);

	if (error == NULL) {
		GPtrArray *properties_array;

		properties_array = data_cal_encode_properties (async_context->dbus_interface);

		e_dbus_calendar_complete_open (
			async_context->dbus_interface,
			async_context->invocation,
			(const gchar * const *) properties_array->pdata);

		g_ptr_array_free (properties_array, TRUE);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_open_cb (EDBusCalendar *dbus_interface,
                         GDBusMethodInvocation *invocation,
                         EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_open (
		backend,
		async_context->cancellable,
		data_cal_complete_open_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_refresh_cb (GObject *source_object,
                              GAsyncResult *result,
                              gpointer user_data)
{
	AsyncContext *async_context = user_data;
	GError *error = NULL;

	e_cal_backend_refresh_finish (
		E_CAL_BACKEND (source_object), result, &error);

	if (error == NULL) {
		e_dbus_calendar_complete_refresh (
			async_context->dbus_interface,
			async_context->invocation);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_refresh_cb (EDBusCalendar *dbus_interface,
                            GDBusMethodInvocation *invocation,
                            EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_refresh (
		backend,
		async_context->cancellable,
		data_cal_complete_refresh_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_get_object_cb (GObject *source_object,
                                 GAsyncResult *result,
                                 gpointer user_data)
{
	AsyncContext *async_context = user_data;
	gchar *calobj;
	GError *error = NULL;

	calobj = e_cal_backend_get_object_finish (
		E_CAL_BACKEND (source_object), result, &error);

	/* Sanity check. */
	g_return_if_fail (
		((calobj != NULL) && (error == NULL)) ||
		((calobj == NULL) && (error != NULL)));

	if (error == NULL) {
		gchar *utf8_calobj;

		utf8_calobj = e_util_utf8_make_valid (calobj);

		e_dbus_calendar_complete_get_object (
			async_context->dbus_interface,
			async_context->invocation,
			utf8_calobj);

		g_free (utf8_calobj);
		g_free (calobj);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_get_object_cb (EDBusCalendar *dbus_interface,
                               GDBusMethodInvocation *invocation,
                               const gchar *in_uid,
                               const gchar *in_rid,
                               EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	/* Recurrence ID is optional.  Its omission is denoted
	 * via D-Bus by an emptry string.  Convert it to NULL. */
	if (in_rid != NULL && *in_rid == '\0')
		in_rid = NULL;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_get_object (
		backend,
		in_uid, in_rid,
		async_context->cancellable,
		data_cal_complete_get_object_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_get_object_list_cb (GObject *source_object,
                                      GAsyncResult *result,
                                      gpointer user_data)
{
	AsyncContext *async_context = user_data;
	GQueue queue = G_QUEUE_INIT;
	GError *error = NULL;

	e_cal_backend_get_object_list_finish (
		E_CAL_BACKEND (source_object), result, &queue, &error);

	if (error == NULL) {
		gchar **strv;
		gint ii = 0;

		strv = g_new0 (gchar *, queue.length + 1);

		while (!g_queue_is_empty (&queue)) {
			gchar *calobj;

			calobj = g_queue_pop_head (&queue);

			strv[ii++] = e_util_utf8_make_valid (calobj);

			g_free (calobj);
		}

		e_dbus_calendar_complete_get_object_list (
			async_context->dbus_interface,
			async_context->invocation,
			(const gchar * const *) strv);

		g_strfreev (strv);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_get_object_list_cb (EDBusCalendar *dbus_interface,
                                    GDBusMethodInvocation *invocation,
                                    const gchar *in_query,
                                    EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_get_object_list (
		backend,
		in_query,
		async_context->cancellable,
		data_cal_complete_get_object_list_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_get_free_busy_cb (GObject *source_object,
                                    GAsyncResult *result,
                                    gpointer user_data)
{
	AsyncContext *async_context = user_data;
	GSList *out_freebusy = NULL;
	GError *error = NULL;

	e_cal_backend_get_free_busy_finish (
		E_CAL_BACKEND (source_object), result, &out_freebusy, &error);

	if (error == NULL) {
		gchar **strv;
		gint ii = 0;
		GSList *link;

		strv = g_new0 (gchar *, g_slist_length (out_freebusy) + 1);

		for (link = out_freebusy; link; link = g_slist_next (link)) {
			gchar *ical_freebusy = link->data;

			strv[ii++] = e_util_utf8_make_valid (ical_freebusy);
		}

		e_dbus_calendar_complete_get_free_busy (
			async_context->dbus_interface,
			async_context->invocation,
			(const gchar * const *) strv);

		g_strfreev (strv);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	g_slist_free_full (out_freebusy, g_free);
	async_context_free (async_context);
}

static gboolean
data_cal_handle_get_free_busy_cb (EDBusCalendar *dbus_interface,
                                  GDBusMethodInvocation *invocation,
                                  gint64 in_start,
                                  gint64 in_end,
                                  const gchar * const *in_users,
                                  EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_get_free_busy (
		backend,
		(time_t) in_start,
		(time_t) in_end,
		in_users,
		async_context->cancellable,
		data_cal_complete_get_free_busy_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_create_objects_cb (GObject *source_object,
                                     GAsyncResult *result,
                                     gpointer user_data)
{
	AsyncContext *async_context = user_data;
	GQueue queue = G_QUEUE_INIT;
	GError *error = NULL;

	e_cal_backend_create_objects_finish (
		E_CAL_BACKEND (source_object), result, &queue, &error);

	if (error == NULL) {
		gchar **strv;
		gint ii = 0;

		strv = g_new0 (gchar *, queue.length + 1);

		while (!g_queue_is_empty (&queue)) {
			gchar *uid;

			uid = g_queue_pop_head (&queue);
			strv[ii++] = e_util_utf8_make_valid (uid);
			g_free (uid);
		}

		e_dbus_calendar_complete_create_objects (
			async_context->dbus_interface,
			async_context->invocation,
			(const gchar * const *) strv);

		g_strfreev (strv);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_create_objects_cb (EDBusCalendar *dbus_interface,
                                   GDBusMethodInvocation *invocation,
                                   const gchar * const *in_calobjs,
                                   EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_create_objects (
		backend,
		in_calobjs,
		async_context->cancellable,
		data_cal_complete_create_objects_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_modify_objects_cb (GObject *source_object,
                                     GAsyncResult *result,
                                     gpointer user_data)
{
	AsyncContext *async_context = user_data;
	GError *error = NULL;

	e_cal_backend_modify_objects_finish (
		E_CAL_BACKEND (source_object), result, &error);

	if (error == NULL) {
		e_dbus_calendar_complete_modify_objects (
			async_context->dbus_interface,
			async_context->invocation);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_modify_objects_cb (EDBusCalendar *dbus_interface,
                                   GDBusMethodInvocation *invocation,
                                   const gchar * const *in_ics_objects,
                                   const gchar *in_mod_type,
                                   EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;
	GFlagsClass *flags_class;
	ECalObjModType mod = 0;
	gchar **flags_strv;
	gint ii;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	flags_class = g_type_class_ref (E_TYPE_CAL_OBJ_MOD_TYPE);
	flags_strv = g_strsplit (in_mod_type, ":", -1);
	for (ii = 0; flags_strv[ii] != NULL; ii++) {
		GFlagsValue *flags_value;

		flags_value = g_flags_get_value_by_nick (
			flags_class, flags_strv[ii]);
		if (flags_value != NULL) {
			mod |= flags_value->value;
		} else {
			g_warning (
				"%s: Unknown flag: %s",
				G_STRFUNC, flags_strv[ii]);
		}
	}
	g_strfreev (flags_strv);
	g_type_class_unref (flags_class);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_modify_objects (
		backend,
		in_ics_objects, mod,
		async_context->cancellable,
		data_cal_complete_modify_objects_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_remove_objects_cb (GObject *source_object,
                                     GAsyncResult *result,
                                     gpointer user_data)
{
	AsyncContext *async_context = user_data;
	GError *error = NULL;

	e_cal_backend_remove_objects_finish (
		E_CAL_BACKEND (source_object), result, &error);

	if (error == NULL) {
		e_dbus_calendar_complete_remove_objects (
			async_context->dbus_interface,
			async_context->invocation);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_remove_objects_cb (EDBusCalendar *dbus_interface,
                                   GDBusMethodInvocation *invocation,
                                   GVariant *in_uid_rid_array,
                                   const gchar *in_mod_type,
                                   EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;
	GFlagsClass *flags_class;
	ECalObjModType mod = 0;
	GQueue component_ids = G_QUEUE_INIT;
	gchar **flags_strv;
	gsize n_children, ii;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	flags_class = g_type_class_ref (E_TYPE_CAL_OBJ_MOD_TYPE);
	flags_strv = g_strsplit (in_mod_type, ":", -1);
	for (ii = 0; flags_strv[ii] != NULL; ii++) {
		GFlagsValue *flags_value;

		flags_value = g_flags_get_value_by_nick (
			flags_class, flags_strv[ii]);
		if (flags_value != NULL) {
			mod |= flags_value->value;
		} else {
			g_warning (
				"%s: Unknown flag: %s",
				G_STRFUNC, flags_strv[ii]);
		}
	}
	g_strfreev (flags_strv);
	g_type_class_unref (flags_class);

	n_children = g_variant_n_children (in_uid_rid_array);
	for (ii = 0; ii < n_children; ii++) {
		ECalComponentId *id;

		/* e_cal_component_free_id() uses g_free(),
		 * not g_slice_free().  Therefore allocate
		 * with g_malloc(), not g_slice_new(). */
		id = g_malloc0 (sizeof (ECalComponentId));

		g_variant_get_child (
			in_uid_rid_array, ii, "(ss)", &id->uid, &id->rid);

		if (id->uid != NULL && *id->uid == '\0') {
			e_cal_component_free_id (id);
			continue;
		}

		/* Recurrence ID is optional.  Its omission is denoted
		 * via D-Bus by an empty string.  Convert it to NULL. */
		if (id->rid != NULL && *id->rid == '\0') {
			g_free (id->rid);
			id->rid = NULL;
		}

		g_queue_push_tail (&component_ids, id);
	}

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_remove_objects (
		backend,
		component_ids.head, mod,
		async_context->cancellable,
		data_cal_complete_remove_objects_cb,
		async_context);

	while (!g_queue_is_empty (&component_ids))
		e_cal_component_free_id (g_queue_pop_head (&component_ids));

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_receive_objects_cb (GObject *source_object,
                                      GAsyncResult *result,
                                      gpointer user_data)
{
	AsyncContext *async_context = user_data;
	GError *error = NULL;

	e_cal_backend_receive_objects_finish (
		E_CAL_BACKEND (source_object), result, &error);

	if (error == NULL) {
		e_dbus_calendar_complete_receive_objects (
			async_context->dbus_interface,
			async_context->invocation);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_receive_objects_cb (EDBusCalendar *dbus_interface,
                                    GDBusMethodInvocation *invocation,
                                    const gchar *in_calobj,
                                    EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_receive_objects (
		backend,
		in_calobj,
		async_context->cancellable,
		data_cal_complete_receive_objects_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_send_objects_cb (GObject *source_object,
                                   GAsyncResult *result,
                                   gpointer user_data)
{
	AsyncContext *async_context = user_data;
	gchar *calobj;
	GQueue queue = G_QUEUE_INIT;
	GError *error = NULL;

	calobj = e_cal_backend_send_objects_finish (
		E_CAL_BACKEND (source_object), result, &queue, &error);

	/* Sanity check. */
	g_return_if_fail (
		((calobj != NULL) && (error == NULL)) ||
		((calobj == NULL) && (error != NULL)));

	if (calobj != NULL) {
		gchar **strv;
		gchar *utf8_calobj;
		gint ii = 0;

		strv = g_new0 (gchar *, queue.length + 1);

		while (!g_queue_is_empty (&queue)) {
			gchar *user;

			user = g_queue_pop_head (&queue);
			strv[ii++] = e_util_utf8_make_valid (user);
			g_free (user);
		}

		utf8_calobj = e_util_utf8_make_valid (calobj);

		e_dbus_calendar_complete_send_objects (
			async_context->dbus_interface,
			async_context->invocation,
			(const gchar * const *) strv,
			utf8_calobj);

		g_free (utf8_calobj);
		g_free (calobj);

		g_strfreev (strv);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_send_objects_cb (EDBusCalendar *dbus_interface,
                                 GDBusMethodInvocation *invocation,
                                 const gchar *in_calobj,
                                 EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_send_objects (
		backend,
		in_calobj,
		async_context->cancellable,
		data_cal_complete_send_objects_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_get_attachment_uris_cb (GObject *source_object,
                                          GAsyncResult *result,
                                          gpointer user_data)
{
	AsyncContext *async_context = user_data;
	GQueue queue = G_QUEUE_INIT;
	GError *error = NULL;

	e_cal_backend_get_attachment_uris_finish (
		E_CAL_BACKEND (source_object), result, &queue, &error);

	if (error == NULL) {
		gchar **strv;
		gint ii = 0;

		strv = g_new0 (gchar *, queue.length + 1);

		while (!g_queue_is_empty (&queue)) {
			gchar *uri;

			uri = g_queue_pop_head (&queue);
			strv[ii++] = e_util_utf8_make_valid (uri);
			g_free (uri);
		}

		e_dbus_calendar_complete_get_attachment_uris (
			async_context->dbus_interface,
			async_context->invocation,
			(const gchar * const *) strv);

		g_strfreev (strv);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_get_attachment_uris_cb (EDBusCalendar *dbus_interface,
                                        GDBusMethodInvocation *invocation,
                                        const gchar *in_uid,
                                        const gchar *in_rid,
                                        EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	/* Recurrence ID is optional.  Its omission is denoted
	 * via D-Bus by an empty string.  Convert it to NULL. */
	if (in_rid != NULL && *in_rid == '\0')
		in_rid = NULL;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_get_attachment_uris (
		backend,
		in_uid, in_rid,
		async_context->cancellable,
		data_cal_complete_get_attachment_uris_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_discard_alarm_cb (GObject *source_object,
                                    GAsyncResult *result,
                                    gpointer user_data)
{
	AsyncContext *async_context = user_data;
	GError *error = NULL;

	e_cal_backend_discard_alarm_finish (
		E_CAL_BACKEND (source_object), result, &error);

	if (error == NULL) {
		e_dbus_calendar_complete_discard_alarm (
			async_context->dbus_interface,
			async_context->invocation);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_discard_alarm_cb (EDBusCalendar *dbus_interface,
                                  GDBusMethodInvocation *invocation,
                                  const gchar *in_uid,
                                  const gchar *in_rid,
                                  const gchar *in_alarm_uid,
                                  EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	/* Recurrence ID is optional.  Its omission is denoted
	 * via D-Bus by an empty string.  Convert it to NULL. */
	if (in_rid != NULL && *in_rid == '\0')
		in_rid = NULL;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_discard_alarm (
		backend,
		in_uid, in_rid, in_alarm_uid,
		async_context->cancellable,
		data_cal_complete_discard_alarm_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static gboolean
data_cal_handle_get_view_cb (EDBusCalendar *dbus_interface,
                             GDBusMethodInvocation *invocation,
                             const gchar *in_query,
                             EDataCal *data_cal)
{
	ECalBackend *backend;
	EDataCalView *view;
	ECalBackendSExp *sexp;
	GDBusConnection *connection;
	gchar *object_path;
	GError *error = NULL;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	sexp = e_cal_backend_sexp_new (in_query);
	if (sexp == NULL) {
		g_dbus_method_invocation_return_error_literal (
			invocation,
			E_CLIENT_ERROR,
			E_CLIENT_ERROR_INVALID_QUERY,
			_("Invalid query"));
		g_object_unref (backend);
		return TRUE;
	}

	object_path = construct_calview_path ();
	connection = g_dbus_method_invocation_get_connection (invocation);

	view = e_data_cal_view_new (
		backend, sexp, connection, object_path, &error);

	g_object_unref (sexp);

	/* Sanity check. */
	g_return_val_if_fail (
		((view != NULL) && (error == NULL)) ||
		((view == NULL) && (error != NULL)), FALSE);

	if (view != NULL) {
		e_dbus_calendar_complete_get_view (
			dbus_interface, invocation, object_path);
		e_cal_backend_add_view (backend, view);
		g_object_unref (view);
	} else {
		data_cal_convert_to_client_error (error);
		g_prefix_error (&error, "%s", _("Invalid query: "));
		g_dbus_method_invocation_take_error (invocation, error);
	}

	g_free (object_path);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_get_timezone_cb (GObject *source_object,
                                   GAsyncResult *result,
                                   gpointer user_data)
{
	AsyncContext *async_context = user_data;
	gchar *tzobject;
	GError *error = NULL;

	/* XXX Should this return an ECalComponent instead? */
	tzobject = e_cal_backend_get_timezone_finish (
		E_CAL_BACKEND (source_object), result, &error);

	/* Sanity check. */
	g_return_if_fail (
		((tzobject != NULL) && (error == NULL)) ||
		((tzobject == NULL) && (error != NULL)));

	if (tzobject != NULL) {
		e_dbus_calendar_complete_get_timezone (
			async_context->dbus_interface,
			async_context->invocation,
			tzobject);

		g_free (tzobject);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_get_timezone_cb (EDBusCalendar *dbus_interface,
                                 GDBusMethodInvocation *invocation,
                                 const gchar *in_tzid,
                                 EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_get_timezone (
		backend,
		in_tzid,
		async_context->cancellable,
		data_cal_complete_get_timezone_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_complete_add_timezone_cb (GObject *source_object,
                                   GAsyncResult *result,
                                   gpointer user_data)
{
	AsyncContext *async_context = user_data;
	GError *error = NULL;

	e_cal_backend_add_timezone_finish (
		E_CAL_BACKEND (source_object), result, &error);

	if (error == NULL) {
		e_dbus_calendar_complete_add_timezone (
			async_context->dbus_interface,
			async_context->invocation);
	} else {
		data_cal_convert_to_client_error (error);
		g_dbus_method_invocation_take_error (
			async_context->invocation, error);
	}

	async_context_free (async_context);
}

static gboolean
data_cal_handle_add_timezone_cb (EDBusCalendar *dbus_interface,
                                 GDBusMethodInvocation *invocation,
                                 const gchar *in_tzobject,
                                 EDataCal *data_cal)
{
	ECalBackend *backend;
	AsyncContext *async_context;

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	async_context = async_context_new (data_cal, invocation);

	e_cal_backend_add_timezone (
		backend,
		in_tzobject,
		async_context->cancellable,
		data_cal_complete_add_timezone_cb,
		async_context);

	g_object_unref (backend);

	return TRUE;
}

static void
data_cal_source_unset_last_credentials_required_arguments_cb (GObject *source_object,
							      GAsyncResult *result,
							      gpointer user_data)
{
	GError *local_error = NULL;

	g_return_if_fail (E_IS_SOURCE (source_object));

	e_source_unset_last_credentials_required_arguments_finish (E_SOURCE (source_object), result, &local_error);

	if (local_error)
		g_debug ("%s: Call failed: %s", G_STRFUNC, local_error->message);

	g_clear_error (&local_error);
}

static gboolean
data_cal_handle_close_cb (EDBusCalendar *dbus_interface,
                          GDBusMethodInvocation *invocation,
                          EDataCal *data_cal)
{
	ECalBackend *backend;
	ESource *source;
	const gchar *sender;

	/* G_DBUS_MESSAGE_FLAGS_NO_REPLY_EXPECTED should be set on
	 * the GDBusMessage, but we complete the invocation anyway
	 * and let the D-Bus machinery suppress the reply. */
	e_dbus_calendar_complete_close (dbus_interface, invocation);

	backend = e_data_cal_ref_backend (data_cal);
	g_return_val_if_fail (backend != NULL, FALSE);

	source = e_backend_get_source (E_BACKEND (backend));
	e_source_unset_last_credentials_required_arguments (source, NULL,
		data_cal_source_unset_last_credentials_required_arguments_cb, NULL);

	sender = g_dbus_method_invocation_get_sender (invocation);
	g_signal_emit_by_name (backend, "closed", sender);

	g_object_unref (backend);

	return TRUE;
}

/**
 * e_data_cal_respond_open:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 *
 * Notifies listeners of the completion of the open method call.
 *
 * Since: 3.2
 */
void
e_data_cal_respond_open (EDataCal *cal,
                         guint32 opid,
                         GError *error)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, NULL);
	g_return_if_fail (simple != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Cannot open calendar: "));

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_refresh:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 *
 * Notifies listeners of the completion of the refresh method call.
 *
 * Since: 3.2
 */
void
e_data_cal_respond_refresh (EDataCal *cal,
                            guint32 opid,
                            GError *error)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, NULL);
	g_return_if_fail (simple != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Cannot refresh calendar: "));

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_get_object:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 * @object: The object retrieved as an iCalendar string.
 *
 * Notifies listeners of the completion of the get_object method call.
 *
 * Since: 3.2
 */
void
e_data_cal_respond_get_object (EDataCal *cal,
                               guint32 opid,
                               GError *error,
                               const gchar *object)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;
	GQueue *queue = NULL;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, &queue);
	g_return_if_fail (simple != NULL);
	g_return_if_fail (queue != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Cannot retrieve calendar object path: "));

	if (error == NULL) {
		if (object != NULL) {
			g_queue_push_tail (queue, g_strdup (object));
		} else {
			g_simple_async_result_set_error (
				simple, E_CAL_CLIENT_ERROR,
				E_CAL_CLIENT_ERROR_INVALID_OBJECT,
				"%s", e_cal_client_error_to_string (
				E_CAL_CLIENT_ERROR_INVALID_OBJECT));
		}
	} else {
		g_simple_async_result_take_error (simple, error);
	}

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_get_object_list:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 * @objects: List of retrieved objects.
 *
 * Notifies listeners of the completion of the get_object_list method call.
 *
 * Since: 3.2
 */
void
e_data_cal_respond_get_object_list (EDataCal *cal,
                                    guint32 opid,
                                    GError *error,
                                    const GSList *objects)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;
	GQueue *queue = NULL;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, &queue);
	g_return_if_fail (simple != NULL);
	g_return_if_fail (queue != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Cannot retrieve calendar object list: "));

	if (error == NULL) {
		GSList *list, *link;

		list = (GSList *) objects;

		for (link = list; link != NULL; link = g_slist_next (link)) {
			const gchar *calobj = link->data;

			if (calobj != NULL)
				g_queue_push_tail (queue, g_strdup (calobj));
		}

	} else {
		g_simple_async_result_take_error (simple, error);
	}

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_get_free_busy:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 * @freebusy: a #GSList of iCalendar strings with all gathered free/busy components.
 *
 * Notifies listeners of the completion of the get_free_busy method call.
 * To pass actual free/busy objects to the client asynchronously
 * use e_data_cal_report_free_busy_data(), but the @freebusy should contain
 * all the objects being used in e_data_cal_report_free_busy_data().
 *
 * Since: 3.2
 */
void
e_data_cal_respond_get_free_busy (EDataCal *cal,
                                  guint32 opid,
                                  GError *error,
				  const GSList *freebusy)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;
	GQueue *queue = NULL;
	const GSList *link;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, &queue);
	g_return_if_fail (simple != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Cannot retrieve calendar free/busy list: "));

	if (error != NULL) {
		g_simple_async_result_take_error (simple, error);
	} else {
		for (link = freebusy; link; link = g_slist_next (link)) {
			const gchar *ical_freebusy = link->data;

			g_queue_push_tail (queue, g_strdup (ical_freebusy));
		}
	}

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_create_objects:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 * @uids: UIDs of the objects created.
 * @new_components: The newly created #ECalComponent objects.
 *
 * Notifies listeners of the completion of the create_objects method call.
 *
 * Since: 3.6
 */
void
e_data_cal_respond_create_objects (EDataCal *cal,
                                   guint32 opid,
                                   GError *error,
                                   const GSList *uids,
                                   GSList *new_components)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;
	GQueue *queue = NULL;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, &queue);
	g_return_if_fail (simple != NULL);
	g_return_if_fail (queue != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Cannot create calendar object: "));

	if (error == NULL) {
		GQueue *inner_queue;
		GSList *list, *link;

		inner_queue = g_queue_new ();

		list = (GSList *) uids;

		for (link = list; link != NULL; link = g_slist_next (link))
			g_queue_push_tail (inner_queue, g_strdup (link->data));

		g_queue_push_tail (queue, inner_queue);

		inner_queue = g_queue_new ();

		list = (GSList *) new_components;

		for (link = list; link != NULL; link = g_slist_next (link))
			g_queue_push_tail (
				inner_queue,
				g_object_ref (link->data));

		g_queue_push_tail (queue, inner_queue);

	} else {
		g_simple_async_result_take_error (simple, error);
	}

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_modify_objects:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 * @old_components: The old #ECalComponent(s).
 * @new_components: The new #ECalComponent(s).
 *
 * Notifies listeners of the completion of the modify_objects method call.
 *
 * Since: 3.6
 */
void
e_data_cal_respond_modify_objects (EDataCal *cal,
                                   guint32 opid,
                                   GError *error,
                                   GSList *old_components,
                                   GSList *new_components)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;
	GQueue *queue = NULL;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, &queue);
	g_return_if_fail (simple != NULL);
	g_return_if_fail (queue != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Cannot modify calendar object: "));

	if (error == NULL) {
		GQueue *inner_queue;
		GSList *list, *link;

		/* FIXME Ugh, this is awkward... */

		inner_queue = g_queue_new ();

		list = (GSList *) old_components;

		for (link = list; link != NULL; link = g_slist_next (link)) {
			if (link->data)
				g_object_ref (link->data);
			g_queue_push_tail (
				inner_queue,
				link->data);
		}

		g_queue_push_tail (queue, inner_queue);

		inner_queue = g_queue_new ();

		list = (GSList *) new_components;

		for (link = list; link != NULL; link = g_slist_next (link))
			g_queue_push_tail (
				inner_queue,
				g_object_ref (link->data));

		g_queue_push_tail (queue, inner_queue);

	} else {
		g_simple_async_result_take_error (simple, error);
	}

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_remove_objects:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 * @ids: (element-type: utf8) IDs of the removed objects.
 * @old_components: (element-type ECalComponent): The old #ECalComponent(s).
 * @new_components: (element-type ECalComponent): The new #ECalComponent(s).
 *    They will not be NULL only when removing instances of recurring appointments.
 *
 * Notifies listeners of the completion of the remove_objects method call.
 *
 * Since: 3.6
 */
void
e_data_cal_respond_remove_objects (EDataCal *cal,
                                  guint32 opid,
                                  GError *error,
                                  const GSList *ids,
                                  GSList *old_components,
                                  GSList *new_components)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;
	GQueue *queue = NULL;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, &queue);
	g_return_if_fail (simple != NULL);
	g_return_if_fail (queue != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Cannot remove calendar object: "));

	if (error == NULL) {
		GQueue *inner_queue;
		GSList *list, *link;

		/* FIXME Ugh, this is awkward... */

		inner_queue = g_queue_new ();

		list = (GSList *) ids;

		for (link = list; link != NULL; link = g_slist_next (link))
			g_queue_push_tail (
				inner_queue,
				e_cal_component_id_copy (link->data));

		g_queue_push_tail (queue, inner_queue);

		inner_queue = g_queue_new ();

		list = (GSList *) old_components;

		for (link = list; link != NULL; link = g_slist_next (link)) {
			if (link->data)
				g_object_ref (link->data);
			g_queue_push_tail (
				inner_queue,
				link->data);
		}

		g_queue_push_tail (queue, inner_queue);

		if (new_components != NULL) {
			inner_queue = g_queue_new ();

			list = (GSList *) new_components;

			/* XXX Careful here.  Apparently list elements
			 *     can be NULL.  What a horrible API design. */
			for (link = list; link != NULL; link = g_slist_next (link)) {
				if (link->data != NULL)
					g_object_ref (link->data);
				g_queue_push_tail (
					inner_queue, link->data);
			}

			g_queue_push_tail (queue, inner_queue);
		}

	} else {
		g_simple_async_result_take_error (simple, error);
	}

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_receive_objects:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 *
 * Notifies listeners of the completion of the receive_objects method call.
 *
 * Since: 3.2
 */
void
e_data_cal_respond_receive_objects (EDataCal *cal,
                                    guint32 opid,
                                    GError *error)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, NULL);
	g_return_if_fail (simple != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Cannot receive calendar objects: "));

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_send_objects:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 * @users: List of users.
 * @calobj: An iCalendar string representing the object sent.
 *
 * Notifies listeners of the completion of the send_objects method call.
 *
 * Since: 3.2
 */
void
e_data_cal_respond_send_objects (EDataCal *cal,
                                 guint32 opid,
                                 GError *error,
                                 const GSList *users,
                                 const gchar *calobj)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;
	GQueue *queue = NULL;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, &queue);
	g_return_if_fail (simple != NULL);
	g_return_if_fail (queue != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Cannot send calendar objects: "));

	if (error == NULL) {
		GSList *list, *link;

		g_queue_push_tail (queue, g_strdup (calobj));

		list = (GSList *) users;

		for (link = list; link != NULL; link = g_slist_next (link))
			g_queue_push_tail (queue, g_strdup (link->data));

	} else {
		g_simple_async_result_take_error (simple, error);
	}

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_get_attachment_uris:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 * @attachment_uris: List of retrieved attachment uri's.
 *
 * Notifies listeners of the completion of the get_attachment_uris method call.
 *
 * Since: 3.2
 **/
void
e_data_cal_respond_get_attachment_uris (EDataCal *cal,
                                        guint32 opid,
                                        GError *error,
                                        const GSList *attachment_uris)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;
	GQueue *queue = NULL;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, &queue);
	g_return_if_fail (simple != NULL);
	g_return_if_fail (queue != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Could not retrieve attachment uris: "));

	if (error == NULL) {
		GSList *list, *link;

		list = (GSList *) attachment_uris;

		for (link = list; link != NULL; link = g_slist_next (link))
			g_queue_push_tail (queue, g_strdup (link->data));
	} else {
		g_simple_async_result_take_error (simple, error);
	}

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_discard_alarm:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 *
 * Notifies listeners of the completion of the discard_alarm method call.
 *
 * Since: 3.2
 **/
void
e_data_cal_respond_discard_alarm (EDataCal *cal,
                                  guint32 opid,
                                  GError *error)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, NULL);
	g_return_if_fail (simple != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Could not discard reminder: "));

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_get_timezone:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 * @tzobject: The requested timezone as an iCalendar string.
 *
 * Notifies listeners of the completion of the get_timezone method call.
 *
 * Since: 3.2
 */
void
e_data_cal_respond_get_timezone (EDataCal *cal,
                                 guint32 opid,
                                 GError *error,
                                 const gchar *tzobject)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;
	GQueue *queue = NULL;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, &queue);
	g_return_if_fail (simple != NULL);
	g_return_if_fail (queue != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Could not retrieve calendar time zone: "));

	if (error == NULL) {
		g_queue_push_tail (queue, g_strdup (tzobject));
	} else {
		g_simple_async_result_take_error (simple, error);
	}

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_respond_add_timezone:
 * @cal: A calendar client interface.
 * @opid: associated operation id
 * @error: Operation error, if any, automatically freed if passed it.
 *
 * Notifies listeners of the completion of the add_timezone method call.
 *
 * Since: 3.2
 */
void
e_data_cal_respond_add_timezone (EDataCal *cal,
                                 guint32 opid,
                                 GError *error)
{
	ECalBackend *backend;
	GSimpleAsyncResult *simple;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	backend = e_data_cal_ref_backend (cal);
	g_return_if_fail (backend != NULL);

	simple = e_cal_backend_prepare_for_completion (backend, opid, NULL);
	g_return_if_fail (simple != NULL);

	/* Translators: This is prefix to a detailed error message */
	g_prefix_error (&error, "%s", _("Could not add calendar time zone: "));

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);

	g_simple_async_result_complete_in_idle (simple);

	g_object_unref (simple);
	g_object_unref (backend);
}

/**
 * e_data_cal_report_error:
 * @cal: an #EDataCal
 * @message: an error message to report
 *
 * Emits an error message, thus the clients can be notified about it.
 *
 * Since: 3.2
 **/
void
e_data_cal_report_error (EDataCal *cal,
                         const gchar *message)
{
	gchar *valid_utf8;

	g_return_if_fail (E_IS_DATA_CAL (cal));
	g_return_if_fail (message != NULL);

	valid_utf8 = e_util_utf8_make_valid (message);

	e_dbus_calendar_emit_error (cal->priv->dbus_interface, valid_utf8 ? valid_utf8 : message);

	g_free (valid_utf8);
}

/**
 * e_data_cal_report_free_busy_data:
 * @cal: an #EDataCal
 * @freebusy: (element-type utf8): a #GSList of free/busy components encoded as string
 *
 * Reports result of a free/busy query on the @cal.
 *
 * Since: 3.2
 **/
void
e_data_cal_report_free_busy_data (EDataCal *cal,
                                  const GSList *freebusy)
{
	gchar **strv;
	guint length;
	gint ii = 0;

	g_return_if_fail (E_IS_DATA_CAL (cal));

	length = g_slist_length ((GSList *) freebusy);
	strv = g_new0 (gchar *, length + 1);

	while (freebusy != NULL) {
		strv[ii++] = e_util_utf8_make_valid (freebusy->data);
		freebusy = g_slist_next ((GSList *) freebusy);
	}

	e_dbus_calendar_emit_free_busy_data (
		cal->priv->dbus_interface,
		(const gchar * const *) strv);

	g_strfreev (strv);
}

/**
 * e_data_cal_report_backend_property_changed:
 * @cal: an #EDataCal
 * @prop_name: property name
 * @prop_value: new property value
 *
 * Notifies client about certain property value change 
 *
 * Since: 3.2
 **/
void
e_data_cal_report_backend_property_changed (EDataCal *cal,
                                            const gchar *prop_name,
                                            const gchar *prop_value)
{
	EDBusCalendar *dbus_interface;
	gchar **strv;

	g_return_if_fail (E_IS_DATA_CAL (cal));
	g_return_if_fail (prop_name != NULL);

	if (prop_value == NULL)
		prop_value = "";

	dbus_interface = cal->priv->dbus_interface;

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_CAPABILITIES)) {
		strv = g_strsplit (prop_value, ",", -1);
		e_dbus_calendar_set_capabilities (
			dbus_interface, (const gchar * const *) strv);
		g_strfreev (strv);
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_REVISION))
		e_dbus_calendar_set_revision (dbus_interface, prop_value);

	if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS))
		e_dbus_calendar_set_cal_email_address (dbus_interface, prop_value);

	if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS))
		e_dbus_calendar_set_alarm_email_address (dbus_interface, prop_value);

	if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_DEFAULT_OBJECT))
		e_dbus_calendar_set_default_object (dbus_interface, prop_value);

	/* Disregard anything else. */
}

static void
data_cal_set_backend (EDataCal *cal,
                      ECalBackend *backend)
{
	g_return_if_fail (E_IS_CAL_BACKEND (backend));

	g_weak_ref_set (&cal->priv->backend, backend);
}

static void
data_cal_set_connection (EDataCal *cal,
                         GDBusConnection *connection)
{
	g_return_if_fail (G_IS_DBUS_CONNECTION (connection));
	g_return_if_fail (cal->priv->connection == NULL);

	cal->priv->connection = g_object_ref (connection);
}

static void
data_cal_set_object_path (EDataCal *cal,
                          const gchar *object_path)
{
	g_return_if_fail (object_path != NULL);
	g_return_if_fail (cal->priv->object_path == NULL);

	cal->priv->object_path = g_strdup (object_path);
}

static void
data_cal_set_property (GObject *object,
                       guint property_id,
                       const GValue *value,
                       GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_BACKEND:
			data_cal_set_backend (
				E_DATA_CAL (object),
				g_value_get_object (value));
			return;

		case PROP_CONNECTION:
			data_cal_set_connection (
				E_DATA_CAL (object),
				g_value_get_object (value));
			return;

		case PROP_OBJECT_PATH:
			data_cal_set_object_path (
				E_DATA_CAL (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
data_cal_get_property (GObject *object,
                       guint property_id,
                       GValue *value,
                       GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_BACKEND:
			g_value_take_object (
				value,
				e_data_cal_ref_backend (
				E_DATA_CAL (object)));
			return;

		case PROP_CONNECTION:
			g_value_set_object (
				value,
				e_data_cal_get_connection (
				E_DATA_CAL (object)));
			return;

		case PROP_OBJECT_PATH:
			g_value_set_string (
				value,
				e_data_cal_get_object_path (
				E_DATA_CAL (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
data_cal_dispose (GObject *object)
{
	EDataCalPrivate *priv;

	priv = E_DATA_CAL_GET_PRIVATE (object);

	g_weak_ref_set (&priv->backend, NULL);

	if (priv->connection != NULL) {
		g_object_unref (priv->connection);
		priv->connection = NULL;
	}

	g_hash_table_remove_all (priv->sender_table);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_data_cal_parent_class)->dispose (object);
}

static void
data_cal_finalize (GObject *object)
{
	EDataCalPrivate *priv;

	priv = E_DATA_CAL_GET_PRIVATE (object);

	g_free (priv->object_path);

	g_mutex_clear (&priv->sender_lock);
	g_weak_ref_clear (&priv->backend);
	g_hash_table_destroy (priv->sender_table);

	if (priv->dbus_interface) {
		g_object_unref (priv->dbus_interface);
		priv->dbus_interface = NULL;
	}

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_data_cal_parent_class)->finalize (object);
}

static void
data_cal_constructed (GObject *object)
{
	EDataCal *cal = E_DATA_CAL (object);
	ECalBackend *backend;
	const gchar *prop_name;
	gchar *prop_value;

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_data_cal_parent_class)->constructed (object);

	backend = e_data_cal_ref_backend (cal);
	g_warn_if_fail (backend != NULL);

	/* Attach ourselves to the ECalBackend. */
	e_cal_backend_set_data_cal (backend, cal);

	e_binding_bind_property (
		backend, "cache-dir",
		cal->priv->dbus_interface, "cache-dir",
		G_BINDING_SYNC_CREATE);

	e_binding_bind_property (
		backend, "online",
		cal->priv->dbus_interface, "online",
		G_BINDING_SYNC_CREATE);

	e_binding_bind_property (
		backend, "writable",
		cal->priv->dbus_interface, "writable",
		G_BINDING_SYNC_CREATE);

	/* XXX Initialize the rest of the properties. */

	prop_name = CLIENT_BACKEND_PROPERTY_CAPABILITIES;
	prop_value = e_cal_backend_get_backend_property (backend, prop_name);
	e_data_cal_report_backend_property_changed (
		cal, prop_name, prop_value);
	g_free (prop_value);

	prop_name = CLIENT_BACKEND_PROPERTY_REVISION;
	prop_value = e_cal_backend_get_backend_property (backend, prop_name);
	e_data_cal_report_backend_property_changed (
		cal, prop_name, prop_value);
	g_free (prop_value);

	prop_name = CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS;
	prop_value = e_cal_backend_get_backend_property (backend, prop_name);
	e_data_cal_report_backend_property_changed (
		cal, prop_name, prop_value);
	g_free (prop_value);

	prop_name = CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS;
	prop_value = e_cal_backend_get_backend_property (backend, prop_name);
	e_data_cal_report_backend_property_changed (
		cal, prop_name, prop_value);
	g_free (prop_value);

	prop_name = CAL_BACKEND_PROPERTY_DEFAULT_OBJECT;
	prop_value = e_cal_backend_get_backend_property (backend, prop_name);
	e_data_cal_report_backend_property_changed (
		cal, prop_name, prop_value);
	g_free (prop_value);

	g_object_unref (backend);
}

static gboolean
data_cal_initable_init (GInitable *initable,
                        GCancellable *cancellable,
                        GError **error)
{
	EDataCal *cal;

	cal = E_DATA_CAL (initable);

	return g_dbus_interface_skeleton_export (
		G_DBUS_INTERFACE_SKELETON (cal->priv->dbus_interface),
		cal->priv->connection,
		cal->priv->object_path,
		error);
}

static void
e_data_cal_class_init (EDataCalClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EDataCalPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = data_cal_set_property;
	object_class->get_property = data_cal_get_property;
	object_class->dispose = data_cal_dispose;
	object_class->finalize = data_cal_finalize;
	object_class->constructed = data_cal_constructed;

	g_object_class_install_property (
		object_class,
		PROP_BACKEND,
		g_param_spec_object (
			"backend",
			"Backend",
			"The backend driving this connection",
			E_TYPE_CAL_BACKEND,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_CONNECTION,
		g_param_spec_object (
			"connection",
			"Connection",
			"The GDBusConnection on which to "
			"export the calendar interface",
			G_TYPE_DBUS_CONNECTION,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_OBJECT_PATH,
		g_param_spec_string (
			"object-path",
			"Object Path",
			"The object path at which to "
			"export the calendar interface",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));
}

static void
e_data_cal_initable_init (GInitableIface *iface)
{
	iface->init = data_cal_initable_init;
}

static void
e_data_cal_init (EDataCal *data_cal)
{
	EDBusCalendar *dbus_interface;

	data_cal->priv = E_DATA_CAL_GET_PRIVATE (data_cal);

	dbus_interface = e_dbus_calendar_skeleton_new ();
	data_cal->priv->dbus_interface = dbus_interface;

	g_mutex_init (&data_cal->priv->sender_lock);
	g_weak_ref_init (&data_cal->priv->backend, NULL);

	data_cal->priv->sender_table = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_ptr_array_unref);

	g_signal_connect (
		dbus_interface, "handle-retrieve-properties",
		G_CALLBACK (data_cal_handle_retrieve_properties_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-open",
		G_CALLBACK (data_cal_handle_open_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-refresh",
		G_CALLBACK (data_cal_handle_refresh_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-get-object",
		G_CALLBACK (data_cal_handle_get_object_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-get-object-list",
		G_CALLBACK (data_cal_handle_get_object_list_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-get-free-busy",
		G_CALLBACK (data_cal_handle_get_free_busy_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-create-objects",
		G_CALLBACK (data_cal_handle_create_objects_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-modify-objects",
		G_CALLBACK (data_cal_handle_modify_objects_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-remove-objects",
		G_CALLBACK (data_cal_handle_remove_objects_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-receive-objects",
		G_CALLBACK (data_cal_handle_receive_objects_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-send-objects",
		G_CALLBACK (data_cal_handle_send_objects_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-get-attachment-uris",
		G_CALLBACK (data_cal_handle_get_attachment_uris_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-discard-alarm",
		G_CALLBACK (data_cal_handle_discard_alarm_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-get-view",
		G_CALLBACK (data_cal_handle_get_view_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-get-timezone",
		G_CALLBACK (data_cal_handle_get_timezone_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-add-timezone",
		G_CALLBACK (data_cal_handle_add_timezone_cb), data_cal);
	g_signal_connect (
		dbus_interface, "handle-close",
		G_CALLBACK (data_cal_handle_close_cb), data_cal);
}

/**
 * e_data_cal_new:
 * @backend: an #ECalBackend
 * @connection: a #GDBusConnection
 * @object_path: object path for the D-Bus interface
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #EDataCal and exports the Calendar D-Bus interface
 * on @connection at @object_path.  The #EDataCal handles incoming remote
 * method invocations and forwards them to the @backend.  If the Calendar
 * interface fails to export, the function sets @error and returns %NULL.
 *
 * Returns: an #EDataCal, or %NULL on error
 **/
EDataCal *
e_data_cal_new (ECalBackend *backend,
                GDBusConnection *connection,
                const gchar *object_path,
                GError **error)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);
	g_return_val_if_fail (G_IS_DBUS_CONNECTION (connection), NULL);
	g_return_val_if_fail (object_path != NULL, NULL);

	return g_initable_new (
		E_TYPE_DATA_CAL, NULL, error,
		"backend", backend,
		"connection", connection,
		"object-path", object_path,
		NULL);
}

/**
 * e_data_cal_ref_backend:
 * @cal: an #EDataCal
 *
 * Returns the #ECalBackend to which incoming remote method invocations
 * are being forwarded.
 *
 * The returned #ECalBackend is referenced for thread-safety and should
 * be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: an #ECalBackend
 *
 * Since: 3.10
 **/
ECalBackend *
e_data_cal_ref_backend (EDataCal *cal)
{
	g_return_val_if_fail (E_IS_DATA_CAL (cal), NULL);

	return g_weak_ref_get (&cal->priv->backend);
}

/**
 * e_data_cal_get_connection:
 * @cal: an #EDataCal
 *
 * Returns the #GDBusConnection on which the Calendar D-Bus interface
 * is exported.
 *
 * Returns: the #GDBusConnection
 *
 * Since: 3.8
 **/
GDBusConnection *
e_data_cal_get_connection (EDataCal *cal)
{
	g_return_val_if_fail (E_IS_DATA_CAL (cal), NULL);

	return cal->priv->connection;
}

/**
 * e_data_cal_get_object_path:
 * @cal: an #EDataCal
 *
 * Returns the object path at which the Calendar D-Bus interface is
 * exported.
 *
 * Returns: the object path
 *
 * Since: 3.8
 **/
const gchar *
e_data_cal_get_object_path (EDataCal *cal)
{
	g_return_val_if_fail (E_IS_DATA_CAL (cal), NULL);

	return cal->priv->object_path;
}

