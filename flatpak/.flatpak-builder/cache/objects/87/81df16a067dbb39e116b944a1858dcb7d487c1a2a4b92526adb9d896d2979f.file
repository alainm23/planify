/*-*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* Evolution calendar ecal
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 * Copyright (C) 2009 Intel Corporation
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
 *          Ross Burton <ross@linux.intel.com>
 */

/**
 * SECTION:e-cal
 *
 * The old signal "cal-opened" is deprecated since 3.0 and is replaced with
 * its equivalent "cal_opened_ex", which has a detailed #GError structure
 * as a parameter, instead of a status code only.
 *
 * Deprecated: 3.2: Use #ECalClient instead.
 */

#include "evolution-data-server-config.h"

#include <unistd.h>
#include <string.h>
#include <glib/gi18n-lib.h>

#include <libical/ical.h>

#include "e-cal-client.h"
#include "e-cal-check-timezones.h"
#include "e-cal-time-util.h"
#include "e-cal-view-private.h"
#include "e-cal.h"

#define E_CAL_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_CAL, ECalPrivate))

#define CLIENT_BACKEND_PROPERTY_CACHE_DIR		"cache-dir"
#define CLIENT_BACKEND_PROPERTY_CAPABILITIES		"capabilities"
#define CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS		"cal-email-address"
#define CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS	"alarm-email-address"
#define CAL_BACKEND_PROPERTY_DEFAULT_OBJECT		"default-object"

static gboolean open_calendar (ECal *ecal, gboolean only_if_exists, GError **error,
	ECalendarStatus *status,
	gboolean async);

struct _ECalPrivate {
	ECalClient *client;
	gulong backend_died_handler_id;
	gulong notify_online_handler_id;

	/* Load state to avoid multiple loads */
	ECalLoadState load_state;

	ESource *source;
	ECalSourceType type;

	GList **free_busy_data;
	GMutex free_busy_data_lock;
};

enum {
	PROP_0,
	PROP_SOURCE,
	PROP_SOURCE_TYPE
};

enum {
	CAL_OPENED,
	CAL_OPENED_EX,
	CAL_SET_MODE,
	BACKEND_ERROR,
	BACKEND_DIED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

static void	e_cal_initable_init		(GInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	ECal, e_cal, G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (G_TYPE_INITABLE, e_cal_initable_init))

G_DEFINE_QUARK (e-calendar-error-quark, e_calendar_error)

/*
 * If the GError is a remote error, extract the EBookStatus embedded inside.
 * Otherwise return CORBA_EXCEPTION (I know this is DBus...).
 */
static ECalendarStatus
get_status_from_error (const GError *error)
{
	#define err(a,b) "org.gnome.evolution.dataserver.Calendar." a, b
	static struct {
		const gchar *name;
		ECalendarStatus err_code;
	} errors[] = {
		{ err ("Success",				E_CALENDAR_STATUS_OK) },
		{ err ("Busy",					E_CALENDAR_STATUS_BUSY) },
		{ err ("RepositoryOffline",			E_CALENDAR_STATUS_REPOSITORY_OFFLINE) },
		{ err ("PermissionDenied",			E_CALENDAR_STATUS_PERMISSION_DENIED) },
		{ err ("InvalidRange",				E_CALENDAR_STATUS_OTHER_ERROR) },
		{ err ("ObjectNotFound",			E_CALENDAR_STATUS_OBJECT_NOT_FOUND) },
		{ err ("InvalidObject",				E_CALENDAR_STATUS_INVALID_OBJECT) },
		{ err ("ObjectIdAlreadyExists",			E_CALENDAR_STATUS_OBJECT_ID_ALREADY_EXISTS) },
		{ err ("AuthenticationFailed",			E_CALENDAR_STATUS_AUTHENTICATION_FAILED) },
		{ err ("AuthenticationRequired",		E_CALENDAR_STATUS_AUTHENTICATION_REQUIRED) },
		{ err ("UnsupportedField",			E_CALENDAR_STATUS_OTHER_ERROR) },
		{ err ("UnsupportedMethod",			E_CALENDAR_STATUS_OTHER_ERROR) },
		{ err ("UnsupportedAuthenticationMethod",	E_CALENDAR_STATUS_OTHER_ERROR) },
		{ err ("TLSNotAvailable",			E_CALENDAR_STATUS_OTHER_ERROR) },
		{ err ("NoSuchCal",				E_CALENDAR_STATUS_NO_SUCH_CALENDAR) },
		{ err ("UnknownUser",				E_CALENDAR_STATUS_UNKNOWN_USER) },
		{ err ("OfflineUnavailable",			E_CALENDAR_STATUS_OTHER_ERROR) },
		{ err ("SearchSizeLimitExceeded",		E_CALENDAR_STATUS_OTHER_ERROR) },
		{ err ("SearchTimeLimitExceeded",		E_CALENDAR_STATUS_OTHER_ERROR) },
		{ err ("InvalidQuery",				E_CALENDAR_STATUS_OTHER_ERROR) },
		{ err ("QueryRefused",				E_CALENDAR_STATUS_OTHER_ERROR) },
		{ err ("CouldNotCancel",			E_CALENDAR_STATUS_COULD_NOT_CANCEL) },
		{ err ("OtherError",				E_CALENDAR_STATUS_OTHER_ERROR) },
		{ err ("InvalidServerVersion",			E_CALENDAR_STATUS_INVALID_SERVER_VERSION) },
		{ err ("InvalidArg",				E_CALENDAR_STATUS_INVALID_ARG) },
		{ err ("NotSupported",				E_CALENDAR_STATUS_NOT_SUPPORTED) }
	};
	#undef err

	if G_LIKELY (error == NULL)
		return E_CALENDAR_STATUS_OK;

	if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_DBUS_ERROR)) {
		gchar *name;
		gint i;

		name = g_dbus_error_get_remote_error (error);

		for (i = 0; i < G_N_ELEMENTS (errors); i++) {
			if (g_ascii_strcasecmp (errors[i].name, name) == 0) {
				g_free (name);
				return errors[i].err_code;
			}
		}

		g_warning ("Unmatched error name %s", name);
		g_free (name);

		return E_CALENDAR_STATUS_OTHER_ERROR;
	} else if (error->domain == E_CALENDAR_ERROR) {
		return error->code;
	} else {
		/* In this case the error was caused by DBus */
		return E_CALENDAR_STATUS_DBUS_EXCEPTION;
	}
}

/**
 * e_cal_source_type_enum_get_type:
 *
 * Registers the #ECalSourceTypeEnum type with glib.
 *
 * Returns: the ID of the #ECalSourceTypeEnum type.
 *
 * Deprecated: 3.2: Use e_cal_client_source_type_enum_get_type() instead.
 */
GType
e_cal_source_type_enum_get_type (void)
{
	static volatile gsize enum_type__volatile = 0;

	if (g_once_init_enter (&enum_type__volatile)) {
		GType enum_type;
		static GEnumValue values[] = {
			{ E_CAL_SOURCE_TYPE_EVENT, "Event", "Event"},
			{ E_CAL_SOURCE_TYPE_TODO, "ToDo", "ToDo"},
			{ E_CAL_SOURCE_TYPE_JOURNAL, "Journal", "Journal"},
			{ E_CAL_SOURCE_TYPE_LAST, "Invalid", "Invalid"},
			{ -1, NULL, NULL}
		};

		enum_type = g_enum_register_static ("ECalSourceTypeEnum", values);
		g_once_init_leave (&enum_type__volatile, enum_type);
	}

	return enum_type__volatile;
}

/**
 * e_cal_set_mode_status_enum_get_type:
 *
 * Registers the #ECalSetModeStatusEnum type with glib.
 *
 * Returns: the ID of the #ECalSetModeStatusEnum type.
 *
 * Deprecated: 3.2: This type has been dropped completely.
 */
GType
e_cal_set_mode_status_enum_get_type (void)
{
	static volatile gsize enum_type__volatile = 0;

	if (g_once_init_enter (&enum_type__volatile)) {
		GType enum_type;
		static GEnumValue values[] = {
			{ E_CAL_SET_MODE_SUCCESS,          "ECalSetModeSuccess",         "success"     },
			{ E_CAL_SET_MODE_ERROR,            "ECalSetModeError",           "error"       },
			{ E_CAL_SET_MODE_NOT_SUPPORTED,    "ECalSetModeNotSupported",    "unsupported" },
			{ -1,                                   NULL,                              NULL}
		};

		enum_type = g_enum_register_static ("ECalSetModeStatusEnum", values);
		g_once_init_leave (&enum_type__volatile, enum_type);
	}

	return enum_type__volatile;
}

/**
 * cal_mode_enum_get_type:
 *
 * Registers the #CalModeEnum type with glib.
 *
 * Returns: the ID of the #CalModeEnum type.
 *
 * Deprecated: 3.2: This type has been dropped completely.
 */
GType
cal_mode_enum_get_type (void)
{
	static volatile gsize enum_type__volatile = 0;

	if (g_once_init_enter (&enum_type__volatile)) {
		GType enum_type;
		static GEnumValue values[] = {
			{ CAL_MODE_INVALID,                     "CalModeInvalid",                  "invalid" },
			{ CAL_MODE_LOCAL,                       "CalModeLocal",                    "local"   },
			{ CAL_MODE_REMOTE,                      "CalModeRemote",                   "remote"  },
			{ CAL_MODE_ANY,                         "CalModeAny",                      "any"     },
			{ -1,                                   NULL,                              NULL      }
		};

		enum_type = g_enum_register_static ("CalModeEnum", values);
		g_once_init_leave (&enum_type__volatile, enum_type);
	}

	return enum_type__volatile;
}

static void
cal_backend_died_cb (EClient *client,
                     ECal *cal)
{
	/* Echo the signal emission from the ECalClient. */
	g_signal_emit (cal, signals[BACKEND_DIED], 0);
}

static void
cal_notify_online_cb (EClient *client,
                      GParamSpec *pspec,
                      ECal *cal)
{
	gboolean online = e_client_is_online (client);

	g_signal_emit (
		cal, signals[CAL_SET_MODE], 0,
		E_CALENDAR_STATUS_OK, online ? Remote : Local);
}

static void
cal_set_source (ECal *cal,
                ESource *source)
{
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (cal->priv->source == NULL);

	cal->priv->source = g_object_ref (source);
}

static void
cal_set_source_type (ECal *cal,
                     ECalSourceType source_type)
{
	cal->priv->type = source_type;
}

static void
cal_set_property (GObject *object,
                  guint property_id,
                  const GValue *value,
                  GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SOURCE:
			cal_set_source (
				E_CAL (object),
				g_value_get_object (value));
			return;

		case PROP_SOURCE_TYPE:
			cal_set_source_type (
				E_CAL (object),
				g_value_get_enum (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
cal_get_property (GObject *object,
                  guint property_id,
                  GValue *value,
                  GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SOURCE:
			g_value_set_object (
				value, e_cal_get_source (
				E_CAL (object)));
			return;

		case PROP_SOURCE_TYPE:
			g_value_set_enum (
				value, e_cal_get_source_type (
				E_CAL (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
cal_dispose (GObject *object)
{
	ECalPrivate *priv;

	priv = E_CAL_GET_PRIVATE (object);

	if (priv->client != NULL) {
		g_signal_handler_disconnect (
			priv->client,
			priv->backend_died_handler_id);
		g_signal_handler_disconnect (
			priv->client,
			priv->notify_online_handler_id);
		g_object_unref (priv->client);
		priv->client = NULL;
	}

	if (priv->source != NULL) {
		g_object_unref (priv->source);
		priv->source = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_cal_parent_class)->dispose (object);
}

static void
cal_finalize (GObject *object)
{
	ECalPrivate *priv;

	priv = E_CAL_GET_PRIVATE (object);

	priv->load_state = E_CAL_LOAD_NOT_LOADED;

	if (priv->free_busy_data) {
		g_mutex_lock (&priv->free_busy_data_lock);
		g_list_foreach (*priv->free_busy_data, (GFunc) g_object_unref, NULL);
		g_list_free (*priv->free_busy_data);
		*priv->free_busy_data = NULL;
		priv->free_busy_data = NULL;
		g_mutex_unlock (&priv->free_busy_data_lock);
	}

	g_mutex_clear (&priv->free_busy_data_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_cal_parent_class)->finalize (object);
}

static gboolean
cal_initable_init (GInitable *initable,
                   GCancellable *cancellable,
                   GError **error)
{
	ECal *cal = E_CAL (initable);
	ECalClientSourceType source_type;
	ESource *source;

	source = e_cal_get_source (cal);

	switch (e_cal_get_source_type (cal)) {
		case E_CAL_SOURCE_TYPE_EVENT:
			source_type = E_CAL_CLIENT_SOURCE_TYPE_EVENTS;
			break;
		case E_CAL_SOURCE_TYPE_TODO:
			source_type = E_CAL_CLIENT_SOURCE_TYPE_TASKS;
			break;
		case E_CAL_SOURCE_TYPE_JOURNAL:
			source_type = E_CAL_CLIENT_SOURCE_TYPE_MEMOS;
			break;
		default:
			g_return_val_if_reached (FALSE);
	}

	cal->priv->client = e_cal_client_new (source, source_type, error);

	if (cal->priv->client == NULL)
		return FALSE;

	cal->priv->backend_died_handler_id = g_signal_connect (
		cal->priv->client, "backend-died",
		G_CALLBACK (cal_backend_died_cb), cal);

	cal->priv->notify_online_handler_id = g_signal_connect (
		cal->priv->client, "notify::online",
		G_CALLBACK (cal_notify_online_cb), cal);

	return TRUE;
}

static void
e_cal_class_init (ECalClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ECalPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = cal_set_property;
	object_class->get_property = cal_get_property;
	object_class->dispose = cal_dispose;
	object_class->finalize = cal_finalize;

	g_object_class_install_property (
		object_class,
		PROP_SOURCE,
		g_param_spec_object (
			"source",
			"Source",
			"The data source for the ECal",
			E_TYPE_SOURCE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_SOURCE_TYPE,
		g_param_spec_enum (
			"source-type",
			"Source Type",
			"The iCalendar data type for the ECal",
			E_TYPE_CAL_SOURCE_TYPE,
			E_CAL_SOURCE_TYPE_EVENT,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/* XXX The "cal-opened" signal is deprecated. */
	signals[CAL_OPENED] = g_signal_new (
		"cal_opened",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalClass, cal_opened),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_INT);

	/**
	 * ECal::cal-opened-ex:
	 * @ecal:: self
	 * @error: (type glong):
	 */
	signals[CAL_OPENED_EX] = g_signal_new (
		"cal_opened_ex",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalClass, cal_opened_ex),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_POINTER);

	signals[CAL_SET_MODE] = g_signal_new (
		"cal_set_mode",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalClass, cal_set_mode),
		NULL, NULL, NULL,
		G_TYPE_NONE, 2,
		E_CAL_SET_MODE_STATUS_ENUM_TYPE,
		CAL_MODE_ENUM_TYPE);

	signals[BACKEND_ERROR] = g_signal_new (
		"backend_error",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalClass, backend_error),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_STRING);

	signals[BACKEND_DIED] = g_signal_new (
		"backend_died",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalClass, backend_died),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);
}

static void
e_cal_initable_init (GInitableIface *iface)
{
	iface->init = cal_initable_init;
}

static void
e_cal_init (ECal *ecal)
{
	ecal->priv = E_CAL_GET_PRIVATE (ecal);

	ecal->priv->load_state = E_CAL_LOAD_NOT_LOADED;

	g_mutex_init (&ecal->priv->free_busy_data_lock);
}

static void async_open_report_result (ECal *ecal, const GError *error);

/**
 * e_cal_new:
 * @source: An #ESource to be used for the client.
 * @type: Type of the client.
 *
 * Creates a new calendar client. This does not open the calendar itself,
 * for that, e_cal_open() or e_cal_open_async() needs to be called.
 *
 * Returns: A newly-created calendar client, or NULL if the client could
 * not be constructed because it could not contact the calendar server.
 *
 * Deprecated: 3.2: Use e_cal_client_new() instead.
 **/
ECal *
e_cal_new (ESource *source,
           ECalSourceType type)
{
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);
	g_return_val_if_fail (type < E_CAL_SOURCE_TYPE_LAST, NULL);

	return g_initable_new (
		E_TYPE_CAL, NULL, NULL,
		"source", source, "source-type", type, NULL);
}

static void
async_open_report_result (ECal *ecal,
                          const GError *error)
{
	ECalendarStatus status;

	g_return_if_fail (E_IS_CAL (ecal));

	if (!error)
		ecal->priv->load_state = E_CAL_LOAD_LOADED;

	if (error) {
		status = get_status_from_error (error);
	} else {
		status = E_CALENDAR_STATUS_OK;
	}

	g_signal_emit (G_OBJECT (ecal), signals[CAL_OPENED], 0, status);
	g_signal_emit (G_OBJECT (ecal), signals[CAL_OPENED_EX], 0, error);
}

static void
async_open_ready_cb (GObject *source_object,
                     GAsyncResult *result,
                     gpointer user_data)
{
	ECal *cal = E_CAL (user_data);
	GError *error = NULL;

	e_client_open_finish (E_CLIENT (source_object), result, &error);

	async_open_report_result (cal, error);

	if (error != NULL)
		g_error_free (error);

	g_object_unref (cal);
}

static gboolean
open_calendar (ECal *ecal,
               gboolean only_if_exists,
               GError **error,
               ECalendarStatus *status,
               gboolean async)
{
	gboolean success = TRUE;

	if (ecal->priv->load_state == E_CAL_LOAD_LOADED)
		return TRUE;

	ecal->priv->load_state = E_CAL_LOAD_LOADING;

	*status = E_CALENDAR_STATUS_OK;
	if (!async) {
		success = e_client_open_sync (
			E_CLIENT (ecal->priv->client),
			only_if_exists, NULL, error);
		if (success) {
			*status = E_CALENDAR_STATUS_OK;
			ecal->priv->load_state = E_CAL_LOAD_LOADED;
		} else {
			*status = E_CALENDAR_STATUS_DBUS_EXCEPTION;
			ecal->priv->load_state = E_CAL_LOAD_NOT_LOADED;
		}
	} else {
		e_client_open (
			E_CLIENT (ecal->priv->client),
			only_if_exists, NULL,
			async_open_ready_cb,
			g_object_ref (ecal));
	}

	return success;
}

/**
 * e_cal_open:
 * @ecal: A calendar client.
 * @only_if_exists: FALSE if the calendar should be opened even if there
 * was no storage for it, i.e. to create a new calendar or load an existing
 * one if it already exists.  TRUE if it should only try to load calendars
 * that already exist.
 * @error: Placeholder for error information.
 *
 * Makes a calendar client initiate a request to open a calendar.  The calendar
 * client will emit the "cal_opened" signal when the response from the server is
 * received. Since 3.0 is emitted also "cal_opened_ex" signal, which contains
 * a GError pointer from the open operation (NULL when no error occurred).
 * New signal deprecates the old "cal_opened" signal.
 *
 * Returns: TRUE on success, FALSE on failure to issue the open request.
 *
 * Deprecated: 3.2: Use e_client_open_sync() on an #ECalClient object instead.
 **/
gboolean
e_cal_open (ECal *ecal,
            gboolean only_if_exists,
            GError **error)
{
	ECalendarStatus status = E_CALENDAR_STATUS_OK;
	GError *err = NULL;
	gboolean result;

	result = open_calendar (ecal, only_if_exists, &err, &status, FALSE);
	g_signal_emit (G_OBJECT (ecal), signals[CAL_OPENED], 0, status);
	g_signal_emit (G_OBJECT (ecal), signals[CAL_OPENED_EX], 0, err);

	if (err)
		g_propagate_error (error, err);

	return result;
}

struct idle_async_error_reply_data
{
	ECal *ecal; /* ref-ed */
	GError *error; /* can be NULL */
};

static gboolean
idle_async_error_reply_cb (gpointer user_data)
{
	struct idle_async_error_reply_data *data = user_data;

	g_return_val_if_fail (data != NULL, FALSE);
	g_return_val_if_fail (data->ecal != NULL, FALSE);

	async_open_report_result (data->ecal, data->error);

	g_object_unref (data->ecal);
	if (data->error)
		g_error_free (data->error);
	g_free (data);

	return FALSE;
}

/* takes ownership of error */
static void
async_report_idle (ECal *ecal,
                   GError *error)
{
	struct idle_async_error_reply_data *data;

	g_return_if_fail (ecal != NULL);

	data = g_new0 (struct idle_async_error_reply_data, 1);
	data->ecal = g_object_ref (ecal);
	data->error = error;

	/* Prioritize ahead of GTK+ redraws. */
	g_idle_add_full (
		G_PRIORITY_HIGH_IDLE,
		idle_async_error_reply_cb, data, NULL);
}

/**
 * e_cal_open_async:
 * @ecal: A calendar client.
 * @only_if_exists: If TRUE, then only open the calendar if it already
 * exists.  If FALSE, then create a new calendar if it doesn't already
 * exist.
 *
 * Open the calendar asynchronously.  The calendar will emit the
 * "cal_opened" signal when the operation has completed.
 * Since 3.0 is emitted also "cal_opened_ex" signal, which contains
 * a GError pointer from the open operation (NULL when no error occurred).
 * New signal deprecates the old "cal_opened" signal.
 *
 * Deprecated: 3.2: Use e_client_open()/e_client_open_finish()
 * on an #ECalClient object instead.
 **/
void
e_cal_open_async (ECal *ecal,
                  gboolean only_if_exists)
{
	ECalPrivate *priv;
	GError *error = NULL;
	ECalendarStatus status;

	g_return_if_fail (E_IS_CAL (ecal));

	priv = ecal->priv;

	switch (priv->load_state) {
	case E_CAL_LOAD_LOADING :
		async_report_idle (
			ecal,
			g_error_new_literal (
				E_CALENDAR_ERROR,
				E_CALENDAR_STATUS_BUSY,
				e_cal_get_error_message (
				E_CALENDAR_STATUS_BUSY)));
		return;
	case E_CAL_LOAD_LOADED :
		async_report_idle (ecal, NULL /* success */);
		return;
	default:
		/* ignore everything else */
		break;
	}

	open_calendar (ecal, only_if_exists, &error, &status, TRUE);

	if (error)
		async_report_idle (ecal, error);
}

/**
 * e_cal_refresh:
 * @ecal: A calendar client.
 * @error: Placeholder for error information.
 *
 * Invokes refresh on a calendar. See @e_cal_get_refresh_supported.
 *
 * Returns: TRUE if calendar supports refresh and it was invoked, FALSE otherwise.
 *
 * Since: 2.30
 *
 * Deprecated: 3.2: Use e_client_refresh_sync() instead.
 **/
gboolean
e_cal_refresh (ECal *ecal,
               GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);

	return e_client_refresh_sync (
		E_CLIENT (ecal->priv->client), NULL, error);
}

/**
 * e_cal_remove:
 * @ecal: A calendar client.
 * @error: Placeholder for error information.
 *
 * Removes a calendar.
 *
 * Returns: TRUE if the calendar was removed, FALSE if there was an error.
 *
 * Deprecated: 3.2: Use e_client_remove_sync() on an #ECalClient object instead.
 */
gboolean
e_cal_remove (ECal *ecal,
              GError **error)
{
	ESource *source;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);

	source = e_cal_get_source (ecal);

	return e_source_remove_sync (source, NULL, error);
}

#if 0
/* Builds an URI list out of a CORBA string sequence */
static GList *
build_uri_list (GNOME_Evolution_Calendar_StringSeq *seq)
{
	GList *uris = NULL;
	gint i;

	for (i = 0; i < seq->_length; i++)
		uris = g_list_prepend (uris, g_strdup (seq->_buffer[i]));

	return uris;
}
#endif

/**
 * e_cal_uri_list: (skip)
 * @ecal: A calendar client.
 * @mode: Mode of the URIs to get.
 *
 * Retrieves a list of all calendar clients for the given mode.
 *
 * Returns: list of uris.
 *
 * Deprecated: 3.2: This function has been dropped completely.
 */
GList *
e_cal_uri_list (ECal *ecal,
                CalMode mode)
{
	return NULL;
}

/**
 * e_cal_get_source_type:
 * @ecal: A calendar client.
 *
 * Gets the type of the calendar client.
 *
 * Returns: an #ECalSourceType value corresponding to the type
 * of the calendar client.
 *
 * Deprecated: 3.2: Use e_cal_client_get_source_type() instead.
 */
ECalSourceType
e_cal_get_source_type (ECal *ecal)
{
	ECalPrivate *priv;

	g_return_val_if_fail (E_IS_CAL (ecal), E_CAL_SOURCE_TYPE_LAST);

	priv = ecal->priv;

	return priv->type;
}

/**
 * e_cal_get_load_state:
 * @ecal: A calendar client.
 *
 * Queries the state of loading of a calendar client.
 *
 * Returns: A #ECalLoadState value indicating whether the client has
 * not been loaded with e_cal_open() yet, whether it is being
 * loaded, or whether it is already loaded.
 *
 * Deprecated: 3.2: Use e_client_is_opened() on an #ECalClient instead.
 **/
ECalLoadState
e_cal_get_load_state (ECal *ecal)
{
	g_return_val_if_fail (E_IS_CAL (ecal), E_CAL_LOAD_NOT_LOADED);

	return ecal->priv->load_state;
}

/**
 * e_cal_get_source: (skip)
 * @ecal: A calendar client.
 *
 * Queries the source that is open in a calendar client.
 *
 * Returns: The source of the calendar that is already loaded or is being
 * loaded, or NULL if the ecal has not started a load request yet.
 *
 * Deprecated: 3.2: Use e_client_get_source() on an #ECalClient object instead.
 **/
ESource *
e_cal_get_source (ECal *ecal)
{
	ECalPrivate *priv;

	g_return_val_if_fail (E_IS_CAL (ecal), NULL);

	priv = ecal->priv;
	return priv->source;
}

/**
 * e_cal_get_local_attachment_store:
 * @ecal: A calendar client.
 *
 * Queries the URL where the calendar attachments are
 * serialized in the local filesystem. This enable clients
 * to operate with the reference to attachments rather than the data itself
 * unless it specifically uses the attachments for open/sending
 * operations.
 *
 * Returns: The URL where the attachments are serialized in the
 * local filesystem.
 *
 * Deprecated: 3.2: Use e_cal_client_get_local_attachment_store() instead.
 **/
const gchar *
e_cal_get_local_attachment_store (ECal *ecal)
{
	g_return_val_if_fail (E_IS_CAL (ecal), NULL);

	return e_cal_client_get_local_attachment_store (ecal->priv->client);
}

/**
 * e_cal_is_read_only:
 * @ecal: A calendar client.
 * @read_only: Return value for read only status.
 * @error: Placeholder for error information.
 *
 * Queries whether the calendar client can perform modifications
 * on the calendar or not. Whether the backend is read only or not
 * is specified, on exit, in the @read_only argument.
 *
 * Returns: TRUE if the call was successful, FALSE if there was an error.
 *
 * Deprecated: 3.2: Use e_client_is_readonly() on an #ECalClient object instead.
 */
gboolean
e_cal_is_read_only (ECal *ecal,
                    gboolean *read_only,
                    GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (read_only != NULL, FALSE);

	*read_only = e_client_is_readonly (E_CLIENT (ecal->priv->client));

	return TRUE;
}

/**
 * e_cal_get_cal_address:
 * @ecal: A calendar client.
 * @cal_address: Return value for address information.
 * @error: Placeholder for error information.
 *
 * Queries the calendar address associated with a calendar client.
 *
 * Returns: TRUE if the operation was successful, FALSE if there
 * was an error.
 *
 * Deprecated: 3.2: Use e_client_get_backend_property_sync()
 * with #CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS instead.
 **/
gboolean
e_cal_get_cal_address (ECal *ecal,
                       gchar **cal_address,
                       GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (cal_address != NULL, FALSE);

	return e_client_get_backend_property_sync (
		E_CLIENT (ecal->priv->client),
		CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS,
		cal_address, NULL, error);
}

/**
 * e_cal_get_alarm_email_address:
 * @ecal: A calendar client.
 * @alarm_address: Return value for alarm address.
 * @error: Placeholder for error information.
 *
 * Queries the address to be used for alarms in a calendar client.
 *
 * Returns: TRUE if the operation was successful, FALSE if there was
 * an error while contacting the backend.
 *
 * Deprecated: 3.2: Use e_client_get_backend_property_sync()
 * with #CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS instead.
 */
gboolean
e_cal_get_alarm_email_address (ECal *ecal,
                               gchar **alarm_address,
                               GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (alarm_address != NULL, FALSE);

	return e_client_get_backend_property_sync (
		E_CLIENT (ecal->priv->client),
		CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS,
		alarm_address, NULL, error);
}

/**
 * e_cal_get_ldap_attribute:
 * @ecal: A calendar client.
 * @ldap_attribute: Return value for the LDAP attribute.
 * @error: Placeholder for error information.
 *
 * Queries the LDAP attribute for a calendar client.
 *
 * Returns: TRUE if the call was successful, FALSE if there was an
 * error contacting the backend.
 *
 * Deprecated: 3.2: This function has been dropped completely.
 */
gboolean
e_cal_get_ldap_attribute (ECal *ecal,
                          gchar **ldap_attribute,
                          GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (ldap_attribute != NULL, FALSE);

	*ldap_attribute = NULL;

	g_set_error (
		error, E_CALENDAR_ERROR,
		E_CALENDAR_STATUS_NOT_SUPPORTED,
		_("Not supported"));

	return FALSE;
}

/**
 * e_cal_get_one_alarm_only:
 * @ecal: A calendar client.
 *
 * Checks if a calendar supports only one alarm per component.
 *
 * Returns: TRUE if the calendar allows only one alarm, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_check_one_alarm_only() instead.
 */
gboolean
e_cal_get_one_alarm_only (ECal *ecal)
{
	const gchar *cap = CAL_STATIC_CAPABILITY_ONE_ALARM_ONLY;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);

	return e_cal_get_static_capability (ecal, cap);
}

/**
 * e_cal_get_organizer_must_attend:
 * @ecal: A calendar client.
 *
 * Checks if a calendar forces organizers of meetings to be also attendees.
 *
 * Returns: TRUE if the calendar forces organizers to attend meetings,
 * FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_check_organizer_must_attend() instead.
 */
gboolean
e_cal_get_organizer_must_attend (ECal *ecal)
{
	const gchar *cap = CAL_STATIC_CAPABILITY_ORGANIZER_MUST_ATTEND;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);

	return e_cal_get_static_capability (ecal, cap);
}

/**
 * e_cal_get_recurrences_no_master:
 * @ecal: A calendar client.
 *
 * Checks if the calendar has a master object for recurrences.
 *
 * Returns: TRUE if the calendar has a master object for recurrences,
 * FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_check_recurrences_no_master() instead.
 */
gboolean
e_cal_get_recurrences_no_master (ECal *ecal)
{
	const gchar *cap = CAL_STATIC_CAPABILITY_RECURRENCES_NO_MASTER;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);

	return e_cal_get_static_capability (ecal, cap);
}

/**
 * e_cal_get_static_capability:
 * @ecal: A calendar client.
 * @cap: Name of the static capability to check.
 *
 * Queries the calendar for static capabilities.
 *
 * Returns: TRUE if the capability is supported, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_client_check_capability() on an #ECalClient object instead.
 */
gboolean
e_cal_get_static_capability (ECal *ecal,
                             const gchar *cap)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (cap != NULL, FALSE);

	return e_client_check_capability (E_CLIENT (ecal->priv->client), cap);
}

/**
 * e_cal_get_save_schedules:
 * @ecal: A calendar client.
 *
 * Checks whether the calendar saves schedules.
 *
 * Returns: TRUE if it saves schedules, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_check_save_schedules() instead.
 */
gboolean
e_cal_get_save_schedules (ECal *ecal)
{
	const gchar *cap = CAL_STATIC_CAPABILITY_SAVE_SCHEDULES;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);

	return e_cal_get_static_capability (ecal, cap);
}

/**
 * e_cal_get_organizer_must_accept:
 * @ecal: A calendar client.
 *
 * Checks whether a calendar requires organizer to accept their attendance to
 * meetings.
 *
 * Returns: TRUE if the calendar requires organizers to accept, FALSE
 * otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_check_organizer_must_accept() instead.
 */
gboolean
e_cal_get_organizer_must_accept (ECal *ecal)
{
	const gchar *cap = CAL_STATIC_CAPABILITY_ORGANIZER_MUST_ACCEPT;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);

	return e_cal_get_static_capability (ecal, cap);
}

/**
 * e_cal_get_refresh_supported:
 * @ecal: A calendar client.
 *
 * Checks whether a calendar supports explicit refreshing (see @e_cal_refresh).
 *
 * Returns: TRUE if the calendar supports refreshing, FALSE otherwise.
 *
 * Since: 2.30
 *
 * Deprecated: 3.2: Use e_client_check_refresh_supported() instead.
 */
gboolean
e_cal_get_refresh_supported (ECal *ecal)
{
	const gchar *cap = CAL_STATIC_CAPABILITY_REFRESH_SUPPORTED;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);

	return e_cal_get_static_capability (ecal, cap);
}

/**
 * e_cal_set_mode: (skip)
 * @ecal: A calendar client.
 * @mode: Mode to switch to.
 *
 * Switches online/offline mode on the calendar.
 *
 * Returns: TRUE if the switch was successful, FALSE if there was an error.
 *
 * Deprecated: 3.2: This function has been dropped completely.
 */
gboolean
e_cal_set_mode (ECal *ecal,
                CalMode mode)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (mode & CAL_MODE_ANY, FALSE);

	g_warning ("%s: This function is not supported since 3.2", G_STRFUNC);

	return FALSE;
}

/**
 * e_cal_get_default_object: (skip)
 * @ecal: A calendar client.
 * @icalcomp: Return value for the default object.
 * @error: Placeholder for error information.
 *
 * Retrives an #icalcomponent from the backend that contains the default
 * values for properties needed.
 *
 * Returns: TRUE if the call was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_get_default_object_sync() instead.
 */
gboolean
e_cal_get_default_object (ECal *ecal,
                          icalcomponent **icalcomp,
                          GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (icalcomp != NULL, FALSE);

	return e_cal_client_get_default_object_sync (
		ecal->priv->client, icalcomp, NULL, error);
}

/**
 * e_cal_get_attachments_for_comp: (skip)
 * @ecal: A calendar client.
 * @uid: Unique identifier for a calendar component.
 * @rid: Recurrence identifier.
 * @list: Return the list of attachment uris.
 * @error: Placeholder for error information.
 *
 * Queries a calendar for a calendar component object based on its unique
 * identifier and gets the attachments for the component.
 *
 * Returns: TRUE if the call was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_get_attachment_uris_sync() instead.
 **/
gboolean
e_cal_get_attachments_for_comp (ECal *ecal,
                                const gchar *uid,
                                const gchar *rid,
                                GSList **list,
                                GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (list != NULL, FALSE);

	return e_cal_client_get_attachment_uris_sync (
		ecal->priv->client, uid, rid, list, NULL, error);
}

/**
 * e_cal_get_object: (skip)
 * @ecal: A calendar client.
 * @uid: Unique identifier for a calendar component.
 * @rid: Recurrence identifier.
 * @icalcomp: Return value for the calendar component object.
 * @error: Placeholder for error information.
 *
 * Queries a calendar for a calendar component object based on its unique
 * identifier.
 *
 * Returns: TRUE if the call was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_get_object_sync() instead.
 **/
gboolean
e_cal_get_object (ECal *ecal,
                  const gchar *uid,
                  const gchar *rid,
                  icalcomponent **icalcomp,
                  GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (icalcomp != NULL, FALSE);

	return e_cal_client_get_object_sync (
		ecal->priv->client, uid, rid, icalcomp, NULL, error);
}

/**
 * e_cal_get_objects_for_uid: (skip)
 * @ecal: A calendar client.
 * @uid: Unique identifier for a calendar component.
 * @objects: Return value for the list of objects obtained from the backend.
 * @error: Placeholder for error information.
 *
 * Queries a calendar for all calendar components with the given unique
 * ID. This will return any recurring event and all its detached recurrences.
 * For non-recurring events, it will just return the object with that ID.
 *
 * Returns: TRUE if the call was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_get_objects_for_uid_sync() instead.
 **/
gboolean
e_cal_get_objects_for_uid (ECal *ecal,
                           const gchar *uid,
                           GList **objects,
                           GError **error)
{
	GSList *slist = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (objects != NULL, FALSE);

	*objects = NULL;

	success = e_cal_client_get_objects_for_uid_sync (
		ecal->priv->client, uid, &slist, NULL, error);

	if (slist != NULL) {
		GSList *link;

		/* XXX Never use GSList in a public API. */
		for (link = slist; link != NULL; link = g_slist_next (link))
			*objects = g_list_prepend (*objects, link->data);
		*objects = g_list_reverse (*objects);

		g_slist_free (slist);
	}

	return success;
}

/**
 * e_cal_resolve_tzid_cb: (skip)
 * @tzid: ID of the timezone to resolve.
 * @data: Closure data for the callback.
 *
 * Resolves TZIDs for the recurrence generator.
 *
 * Returns: The timezone identified by the @tzid argument, or %NULL if
 * it could not be found.
 *
 * Deprecated: 3.2: Use e_cal_client_resolve_tzid_cb() instead.
 */
icaltimezone *
e_cal_resolve_tzid_cb (const gchar *tzid,
                       gpointer data)
{
	ECal *ecal;
	icaltimezone *zone = NULL;

	g_return_val_if_fail (data != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL (data), NULL);

	ecal = E_CAL (data);

	/* FIXME: Handle errors. */
	e_cal_get_timezone (ecal, tzid, &zone, NULL);

	return zone;
}

/**
 * e_cal_get_changes: (skip)
 * @ecal: A calendar client.
 * @change_id: ID to use for comparing changes.
 * @changes: Return value for the list of changes.
 * @error: Placeholder for error information.
 *
 * Returns a list of changes made to the calendar since a specific time. That time
 * is identified by the @change_id argument, which is used by the backend to
 * compute the changes done.
 *
 * Returns: %TRUE if the call was successful, %FALSE otherwise.
 *
 * Deprecated: 3.2: This function has been dropped completely.
 */
gboolean
e_cal_get_changes (ECal *ecal,
                   const gchar *change_id,
                   GList **changes,
                   GError **error)
{

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (change_id != NULL, FALSE);
	g_return_val_if_fail (changes != NULL, FALSE);

	*changes = NULL;

	g_set_error (
		error, E_CALENDAR_ERROR,
		E_CALENDAR_STATUS_NOT_SUPPORTED,
		_("Not supported"));

	return FALSE;
}

/**
 * e_cal_free_change_list: (skip)
 * @list: List of changes to be freed.
 *
 * Free a list of changes as returned by e_cal_get_changes().
 *
 * Deprecated: 3.2: Use () instead.
 */
void
e_cal_free_change_list (GList *list)
{
	ECalChange *c;
	GList *l;

	for (l = list; l; l = l->next) {
		c = l->data;

		if (c != NULL && c->comp != NULL) {
			g_object_unref (G_OBJECT (c->comp));
			g_free (c);
		} else
			g_warn_if_reached ();
	}

	g_list_free (list);
}

/**
 * e_cal_get_object_list:
 * @ecal: A calendar client.
 * @query: Query string.
 * @objects: (out) (element-type long): Return value for list of objects.
 * @error: Placeholder for error information.
 *
 * Gets a list of objects from the calendar that match the query specified
 * by the @query argument. The objects will be returned in the @objects
 * argument, which is a list of #icalcomponent. When done, this list
 * should be freed by using the e_cal_free_object_list() function.
 *
 * Returns: TRUE if the operation was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_get_object_list_sync() instead.
 **/
gboolean
e_cal_get_object_list (ECal *ecal,
                       const gchar *query,
                       GList **objects,
                       GError **error)
{
	GSList *slist = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (query != NULL, FALSE);
	g_return_val_if_fail (objects != NULL, FALSE);

	*objects = NULL;

	success = e_cal_client_get_object_list_sync (
		ecal->priv->client, query, &slist, NULL, error);

	if (slist != NULL) {
		GSList *link;

		/* XXX Never use GSList in a public API. */
		for (link = slist; link != NULL; link = g_slist_next (link))
			*objects = g_list_prepend (*objects, link->data);
		*objects = g_list_reverse (*objects);

		g_slist_free (slist);
	}

	return success;
}

/**
 * e_cal_get_object_list_as_comp: (skip)
 * @ecal: A calendar client.
 * @query: Query string.
 * @objects: Return value for list of objects.
 * @error: Placeholder for error information.
 *
 * Gets a list of objects from the calendar that match the query specified
 * by the @query argument. The objects will be returned in the @objects
 * argument, which is a list of #ECalComponent.
 *
 * Returns: TRUE if the operation was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_get_object_list_as_comps_sync() instead.
 */
gboolean
e_cal_get_object_list_as_comp (ECal *ecal,
                               const gchar *query,
                               GList **objects,
                               GError **error)
{
	GSList *slist = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (query != NULL, FALSE);
	g_return_val_if_fail (objects != NULL, FALSE);

	*objects = NULL;

	success = e_cal_client_get_object_list_as_comps_sync (
		ecal->priv->client, query, &slist, NULL, error);

	if (slist != NULL) {
		GSList *link;

		/* XXX Never use GSList in a public API. */
		for (link = slist; link != NULL; link = g_slist_next (link))
			*objects = g_list_prepend (*objects, link->data);
		*objects = g_list_reverse (*objects);

		g_slist_free (slist);
	}

	return success;
}

/**
 * e_cal_free_object_list: (skip)
 * @objects: List of objects to be freed.
 *
 * Frees a list of objects as returned by e_cal_get_object_list().
 *
 * Deprecated: 3.2: Use e_cal_client_free_icalcomp_slist() instead.
 */
void
e_cal_free_object_list (GList *objects)
{
	g_list_free_full (objects, (GDestroyNotify) icalcomponent_free);
}

/**
 * e_cal_get_free_busy: (skip)
 * @ecal: A calendar client.
 * @users: List of users to retrieve free/busy information for.
 * @start: Start time for query.
 * @end: End time for query.
 * @freebusy: Return value for VFREEBUSY objects.
 * @error: Placeholder for error information.
 *
 * Gets free/busy information from the calendar server.
 *
 * Returns: TRUE if the operation was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_get_free_busy_sync() instead.
 */
gboolean
e_cal_get_free_busy (ECal *ecal,
                     GList *users,
                     time_t start,
                     time_t end,
                     GList **freebusy,
                     GError **error)
{
	GSList *slist = NULL, *out_freebusy = NULL, *link;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (users != NULL, FALSE);
	g_return_val_if_fail (freebusy != NULL, FALSE);

	*freebusy = NULL;

	/* XXX Never use GSList in a public API. */
	for (; users != NULL; users = g_list_next (users))
		slist = g_slist_prepend (slist, users->data);

	success = e_cal_client_get_free_busy_sync (
		ecal->priv->client, start, end, slist, &out_freebusy, NULL, error);

	g_slist_free (slist);

	if (success) {
		for (link = out_freebusy; link; link = g_slist_next (link)) {
			*freebusy = g_list_prepend (*freebusy, g_object_ref (link->data));
		}
	}

	g_slist_free_full (out_freebusy, g_object_unref);

	return success;
}

/**
 * e_cal_generate_instances: (skip)
 * @ecal: A calendar client.
 * @start: Start time for query.
 * @end: End time for query.
 * @cb: Callback for each generated instance.
 * @cb_data: Closure data for the callback.
 *
 * Does a combination of e_cal_get_object_list() and
 * e_cal_recur_generate_instances().
 *
 * The callback function should do a g_object_ref() of the calendar component
 * it gets passed if it intends to keep it around, since it will be unref'ed
 * as soon as the callback returns.
 *
 * Deprecated: 3.2: Use e_cal_client_generate_instances() instead.
 **/
void
e_cal_generate_instances (ECal *ecal,
                          time_t start,
                          time_t end,
                          ECalRecurInstanceFn cb,
                          gpointer cb_data)
{
	g_return_if_fail (E_IS_CAL (ecal));

	e_cal_client_generate_instances_sync (
		ecal->priv->client, start, end, cb, cb_data);
}

/**
 * e_cal_generate_instances_for_object: (skip)
 * @ecal: A calendar client.
 * @icalcomp: Object to generate instances from.
 * @start: Start time for query.
 * @end: End time for query.
 * @cb: Callback for each generated instance.
 * @cb_data: Closure data for the callback.
 *
 * Does a combination of e_cal_get_object_list() and
 * e_cal_recur_generate_instances(), like e_cal_generate_instances(), but
 * for a single object.
 *
 * The callback function should do a g_object_ref() of the calendar component
 * it gets passed if it intends to keep it around, since it will be unref'ed
 * as soon as the callback returns.
 *
 * Deprecated: 3.2: Use e_cal_client_generate_instances_for_object() instead.
 **/
void
e_cal_generate_instances_for_object (ECal *ecal,
                                     icalcomponent *icalcomp,
                                     time_t start,
                                     time_t end,
                                     ECalRecurInstanceFn cb,
                                     gpointer cb_data)
{
	g_return_if_fail (E_IS_CAL (ecal));

	e_cal_client_generate_instances_for_object (
		ecal->priv->client, icalcomp,
		start, end, NULL, cb, cb_data, NULL);
}

/* Builds a list of ECalComponentAlarms structures */
static GSList *
build_component_alarms_list (ECal *ecal,
                             GList *object_list,
                             time_t start,
                             time_t end)
{
	icaltimezone *default_zone;
	GSList *comp_alarms;
	GList *l;

	comp_alarms = NULL;

	default_zone = e_cal_client_get_default_timezone (ecal->priv->client);

	for (l = object_list; l != NULL; l = l->next) {
		ECalComponent *comp;
		ECalComponentAlarms *alarms;
		ECalComponentAlarmAction omit[] = {-1};

		comp = e_cal_component_new ();
		if (!e_cal_component_set_icalcomponent (comp, icalcomponent_new_clone (l->data))) {
			g_object_unref (G_OBJECT (comp));
			continue;
		}

		alarms = e_cal_util_generate_alarms_for_comp (
			comp, start, end, omit, e_cal_resolve_tzid_cb,
			ecal, default_zone);
		if (alarms)
			comp_alarms = g_slist_prepend (comp_alarms, alarms);
	}

	return comp_alarms;
}

/**
 * e_cal_get_alarms_in_range: (skip)
 * @ecal: A calendar client.
 * @start: Start time for query.
 * @end: End time for query.
 *
 * Queries a calendar for the alarms that trigger in the specified range of
 * time.
 *
 * Returns: A list of #ECalComponentAlarms structures.  This should be freed
 * using the e_cal_free_alarms() function, or by freeing each element
 * separately with e_cal_component_alarms_free() and then freeing the list with
 * g_slist_free().
 *
 * Deprecated: 3.2: This function has been dropped completely.
 **/
GSList *
e_cal_get_alarms_in_range (ECal *ecal,
                           time_t start,
                           time_t end)
{
	ECalPrivate *priv;
	GSList *alarms;
	gchar *sexp, *iso_start, *iso_end;
	GList *object_list = NULL;

	g_return_val_if_fail (E_IS_CAL (ecal), NULL);

	priv = ecal->priv;
	g_return_val_if_fail (priv->load_state == E_CAL_LOAD_LOADED, NULL);

	g_return_val_if_fail (start >= 0 && end >= 0, NULL);
	g_return_val_if_fail (start <= end, NULL);

	iso_start = isodate_from_time_t (start);
	if (!iso_start)
		return NULL;

	iso_end = isodate_from_time_t (end);
	if (!iso_end) {
		g_free (iso_start);
		return NULL;
	}

	/* build the query string */
	sexp = g_strdup_printf (
		"(has-alarms-in-range? "
		"(make-time \"%s\") "
		"(make-time \"%s\"))",
		iso_start, iso_end);
	g_free (iso_start);
	g_free (iso_end);

	/* execute the query on the server */
	if (!e_cal_get_object_list (ecal, sexp, &object_list, NULL)) {
		g_free (sexp);
		return NULL;
	}

	alarms = build_component_alarms_list (ecal, object_list, start, end);

	g_list_foreach (object_list, (GFunc) icalcomponent_free, NULL);
	g_list_free (object_list);
	g_free (sexp);

	return alarms;
}

/**
 * e_cal_free_alarms: (skip)
 * @comp_alarms: A list of #ECalComponentAlarms structures.
 *
 * Frees a list of #ECalComponentAlarms structures as returned by
 * e_cal_get_alarms_in_range().
 *
 * Deprecated: 3.2: This function has been dropped completely.
 **/
void
e_cal_free_alarms (GSList *comp_alarms)
{
	GSList *l;

	for (l = comp_alarms; l; l = l->next) {
		ECalComponentAlarms *alarms;

		alarms = l->data;
		if (alarms != NULL)
			e_cal_component_alarms_free (alarms);
		else
			g_warn_if_reached ();
	}

	g_slist_free (comp_alarms);
}

/**
 * e_cal_get_alarms_for_object:
 * @ecal: A calendar client.
 * @id: Unique identifier for a calendar component.
 * @start: Start time for query.
 * @end: End time for query.
 * @alarms: Return value for the component's alarm instances.  Will return NULL
 * if no instances occur within the specified time range.  This should be freed
 * using the e_cal_component_alarms_free() function.
 *
 * Queries a calendar for the alarms of a particular object that trigger in the
 * specified range of time.
 *
 * Returns: TRUE on success, FALSE if the object was not found.
 *
 * Deprecated: 3.2: This function has been dropped completely.
 **/
gboolean
e_cal_get_alarms_for_object (ECal *ecal,
                             const ECalComponentId *id,
                             time_t start,
                             time_t end,
                             ECalComponentAlarms **alarms)
{
	ECalPrivate *priv;
	icalcomponent *icalcomp;
	icaltimezone *default_zone;
	ECalComponent *comp;
	ECalComponentAlarmAction omit[] = {-1};

	g_return_val_if_fail (alarms != NULL, FALSE);
	*alarms = NULL;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);

	priv = ecal->priv;
	g_return_val_if_fail (priv->load_state == E_CAL_LOAD_LOADED, FALSE);

	g_return_val_if_fail (id != NULL, FALSE);
	g_return_val_if_fail (start >= 0 && end >= 0, FALSE);
	g_return_val_if_fail (start <= end, FALSE);

	if (!e_cal_get_object (ecal, id->uid, id->rid, &icalcomp, NULL))
		return FALSE;
	if (!icalcomp)
		return FALSE;

	comp = e_cal_component_new ();
	if (!e_cal_component_set_icalcomponent (comp, icalcomp)) {
		icalcomponent_free (icalcomp);
		g_object_unref (G_OBJECT (comp));
		return FALSE;
	}

	default_zone = e_cal_client_get_default_timezone (ecal->priv->client);

	*alarms = e_cal_util_generate_alarms_for_comp (
		comp, start, end, omit, e_cal_resolve_tzid_cb,
		ecal, default_zone);

	return TRUE;
}

/**
 * e_cal_discard_alarm:
 * @ecal: A calendar ecal.
 * @comp: The component to discard the alarm from.
 * @auid: Unique identifier of the alarm to be discarded.
 * @error: Placeholder for error information.
 *
 * Tells the calendar backend to get rid of the alarm identified by the
 * @auid argument in @comp. Some backends might remove the alarm or
 * update internal information about the alarm be discarded, or, like
 * the file backend does, ignore the operation.
 *
 * CALOBJ_MOD_ONLY_THIS is not supported in this call.
 *
 * Returns: TRUE if the operation was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_discard_alarm_sync() instead.
 */
gboolean
e_cal_discard_alarm (ECal *ecal,
                     ECalComponent *comp,
                     const gchar *auid,
                     GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);
	g_return_val_if_fail (auid != NULL, FALSE);

	g_set_error (
		error, E_CALENDAR_ERROR,
		E_CALENDAR_STATUS_NOT_SUPPORTED,
		_("Not supported"));

	return FALSE;
}

/**
 * e_cal_get_component_as_string: (skip)
 * @ecal: A calendar client.
 * @icalcomp: A calendar component object.
 *
 * Gets a calendar component as an iCalendar string, with a toplevel
 * VCALENDAR component and all VTIMEZONEs needed for the component.
 *
 * Returns: the component as a complete iCalendar string, or NULL on
 * failure. The string should be freed after use.
 *
 * Deprecated: 3.2: Use e_cal_client_get_component_as_string() instead.
 **/
gchar *
e_cal_get_component_as_string (ECal *ecal,
                               icalcomponent *icalcomp)
{
	g_return_val_if_fail (E_IS_CAL (ecal), NULL);
	g_return_val_if_fail (icalcomp != NULL, NULL);

	return e_cal_client_get_component_as_string (
		ecal->priv->client, icalcomp);
}

/**
 * e_cal_create_object: (skip)
 * @ecal: A calendar client.
 * @icalcomp: The component to create.
 * @uid: Return value for the UID assigned to the new component by the
 *       calendar backend.
 * @error: Placeholder for error information.
 *
 * Requests the calendar backend to create the object specified by the @icalcomp
 * argument. Some backends would assign a specific UID to the newly created object,
 * in those cases that UID would be returned in the @uid argument.
 *
 * Returns: TRUE if the operation was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_create_object_sync() instead.
 */
gboolean
e_cal_create_object (ECal *ecal,
                     icalcomponent *icalcomp,
                     gchar **uid,
                     GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (icalcomp != NULL, FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	return e_cal_client_create_object_sync (
		ecal->priv->client, icalcomp, uid, NULL, error);
}

/**
 * e_cal_modify_object: (skip)
 * @ecal: A calendar client.
 * @icalcomp: Component to modify.
 * @mod: Type of modification.
 * @error: Placeholder for error information.
 *
 * Requests the calendar backend to modify an existing object. If the object
 * does not exist on the calendar, an error will be returned.
 *
 * For recurrent appointments, the @mod argument specifies what to modify,
 * if all instances (CALOBJ_MOD_ALL), a single instance (CALOBJ_MOD_THIS),
 * or a specific set of instances (CALOBJ_MOD_THISNADPRIOR and
 * CALOBJ_MOD_THISANDFUTURE).
 *
 * Returns: TRUE if the operation was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_modify_object_sync() instead.
 */
gboolean
e_cal_modify_object (ECal *ecal,
                     icalcomponent *icalcomp,
                     ECalObjModType mod,
                     GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (icalcomp != NULL, FALSE);

	return e_cal_client_modify_object_sync (
		ecal->priv->client, icalcomp, mod, NULL, error);
}

/**
 * e_cal_remove_object_with_mod: (skip)
 * @ecal: A calendar client.
 * @uid: UID of the object to remove.
 * @rid: Recurrence ID of the specific recurrence to remove.
 * @mod: Type of removal.
 * @error: Placeholder for error information.
 *
 * This function allows the removal of instances of a recurrent
 * appointment. If what you want is to remove all instances, use
 * e_cal_remove_object instead.
 *
 * By using a combination of the @uid, @rid and @mod arguments, you
 * can remove specific instances. @uid is mandatory.  Empty or NULL
 * @rid selects the parent appointment (the one with the recurrence
 * rule). A non-empty @rid selects the recurrence at the time specified
 * in @rid, using the same time zone as the parent appointment's start
 * time.
 *
 * The exact semantic then depends on @mod. CALOBJ_MOD_THIS,
 * CALOBJ_MOD_THISANDPRIOR, CALOBJ_MOD_THISANDFUTURE and
 * CALOBJ_MOD_ALL ensure that the event does not recur at the selected
 * instance(s). This is done by removing any detached recurrence
 * matching the selection criteria and modifying the parent
 * appointment (adding EXDATE, adjusting recurrence rules, etc.).  It
 * is not an error if @uid+@rid do not match an existing instance.
 *
 * If not all instances are removed, the client will get a
 * "obj_modified" signal for the parent appointment, while it will get
 * an "obj_removed" signal when all instances are removed.
 *
 * CALOBJ_MOD_ONLY_THIS changes the semantic of CALOBJ_MOD_THIS: @uid
 * and @rid must select an existing instance. That instance is
 * removed without modifying the parent appointment. In other words,
 * e_cal_remove_object_with_mod(CALOBJ_MOD_ONLY_THIS) is the inverse
 * operation for adding a detached recurrence. The client is
 * always sent an "obj_removed" signal.
 *
 * Note that not all backends support CALOBJ_MOD_ONLY_THIS. Check for
 * the CAL_STATIC_CAPABILITY_REMOVE_ONLY_THIS capability before using
 * it. Previous releases did not check consistently for unknown
 * @mod values, using it with them may have had unexpected results.
 *
 * Returns: TRUE if the operation was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_remove_object_sync() instead.
 */
gboolean
e_cal_remove_object_with_mod (ECal *ecal,
                              const gchar *uid,
                              const gchar *rid,
                              ECalObjModType mod,
                              GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	return e_cal_client_remove_object_sync (
		ecal->priv->client, uid, rid, mod, NULL, error);
}

/**
 * e_cal_remove_object:
 * @ecal:  A calendar client.
 * @uid: Unique identifier of the calendar component to remove.
 * @error: Placeholder for error information.
 *
 * Asks a calendar to remove all components with the given UID.
 * If more control of the removal is desired, then use
 * e_cal_remove_object_with_mod().
 * If the server is able to remove the component(s), all clients will
 * be notified and they will emit the "obj_removed" signal.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_remove_object_sync() instead, with rid
 *                  set to NULL and mod set to CALOBJ_MOD_ALL.
 **/
gboolean
e_cal_remove_object (ECal *ecal,
                     const gchar *uid,
                     GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	return e_cal_remove_object_with_mod (
		ecal, uid, NULL, CALOBJ_MOD_ALL, error);
}

/**
 * e_cal_receive_objects: (skip)
 * @ecal:  A calendar client.
 * @icalcomp: An icalcomponent.
 * @error: Placeholder for error information.
 *
 * Makes the backend receive the set of iCalendar objects specified in the
 * @icalcomp argument. This is used for iTIP confirmation/cancellation
 * messages for scheduled meetings.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_receive_objects_sync() instead.
 */
gboolean
e_cal_receive_objects (ECal *ecal,
                       icalcomponent *icalcomp,
                       GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (icalcomp != NULL, FALSE);

	return e_cal_client_receive_objects_sync (
		ecal->priv->client, icalcomp, NULL, error);
}

/**
 * e_cal_send_objects: (skip)
 * @ecal: A calendar client.
 * @icalcomp: An icalcomponent.
 * @users: List of users to send the objects to.
 * @modified_icalcomp: Return value for the icalcomponent after all the operations
 * performed.
 * @error: Placeholder for error information.
 *
 * Requests a calendar backend to send meeting information to the specified list
 * of users.
 *
 * Returns: TRUE if the operation was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_send_objects_sync() instead.
 */
gboolean
e_cal_send_objects (ECal *ecal,
                    icalcomponent *icalcomp,
                    GList **users,
                    icalcomponent **modified_icalcomp,
                    GError **error)
{
	GSList *slist = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (icalcomp != NULL, FALSE);
	g_return_val_if_fail (users != NULL, FALSE);
	g_return_val_if_fail (modified_icalcomp != NULL, FALSE);

	success = e_cal_client_send_objects_sync (
		ecal->priv->client, icalcomp, &slist,
		modified_icalcomp, NULL, error);

	if (slist != NULL) {
		GSList *link;

		/* XXX Never use GSList in a public API. */
		for (link = slist; link != NULL; link = g_slist_next (link))
			*users = g_list_prepend (*users, link->data);
		*users = g_list_reverse (*users);

		g_slist_free (slist);
	}

	return success;
}

/**
 * e_cal_get_timezone: (skip)
 * @ecal: A calendar client.
 * @tzid: ID of the timezone to retrieve.
 * @zone: Return value for the timezone.
 * @error: Placeholder for error information.
 *
 * Retrieves a timezone object from the calendar backend.
 *
 * Returns: TRUE if the operation was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_get_timezone_sync() instead.
 */
gboolean
e_cal_get_timezone (ECal *ecal,
                    const gchar *tzid,
                    icaltimezone **zone,
                    GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (tzid != NULL, FALSE);
	g_return_val_if_fail (zone != NULL, FALSE);

	return e_cal_client_get_timezone_sync (
		ecal->priv->client, tzid, zone, NULL, error);
}

/**
 * e_cal_add_timezone: (skip)
 * @ecal: A calendar client.
 * @izone: The timezone to add.
 * @error: Placeholder for error information.
 *
 * Add a VTIMEZONE object to the given calendar.
 *
 * Returns: TRUE if successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_add_timezone_sync() instead.
 */
gboolean
e_cal_add_timezone (ECal *ecal,
                    icaltimezone *izone,
                    GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (izone != NULL, FALSE);

	return e_cal_client_add_timezone_sync (
		ecal->priv->client, izone, NULL, error);
}

/**
 * e_cal_get_query:
 * @ecal: A calendar client.
 * @sexp: S-expression representing the query.
 * @query: (out): Return value for the new query.
 * @error: Placeholder for error information.
 *
 * Creates a live query object from a loaded calendar.
 *
 * Returns: A query object that will emit notification signals as calendar
 * components are added and removed from the query in the server.
 *
 * Deprecated: 3.2: Use e_cal_client_get_view_sync() instead.
 **/
gboolean
e_cal_get_query (ECal *ecal,
                 const gchar *sexp,
                 ECalView **query,
                 GError **error)
{
	ECalClientView *client_view = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (sexp != NULL, FALSE);
	g_return_val_if_fail (query != NULL, FALSE);

	*query = NULL;

	success = e_cal_client_get_view_sync (
		ecal->priv->client, sexp, &client_view, NULL, error);

	/* Sanity check. */
	g_return_val_if_fail (
		(success && (client_view != NULL)) ||
		(!success && (client_view == NULL)), FALSE);

	if (client_view != NULL) {
		*query = _e_cal_view_new (ecal, client_view);
		g_object_unref (client_view);
	}

	return success;
}

/**
 * e_cal_set_default_timezone: (skip)
 * @ecal: A calendar client.
 * @zone: A timezone object.
 * @error: Placeholder for error information.
 *
 * Sets the default timezone on the calendar. This should be called before opening
 * the calendar.
 *
 * Returns: TRUE if the operation was successful, FALSE otherwise.
 *
 * Deprecated: 3.2: Use e_cal_client_set_default_timezone() instead.
 */
gboolean
e_cal_set_default_timezone (ECal *ecal,
                            icaltimezone *zone,
                            GError **error)
{
	g_return_val_if_fail (E_IS_CAL (ecal), FALSE);
	g_return_val_if_fail (zone != NULL, FALSE);

	e_cal_client_set_default_timezone (ecal->priv->client, zone);

	return TRUE;
}

/**
 * e_cal_get_error_message:
 * @status: A status code.
 *
 * Gets an error message for the given status code.
 *
 * Returns: the error message.
 *
 * Deprecated: 3.2: Use e_cal_client_error_to_string() instead.
 */
const gchar *
e_cal_get_error_message (ECalendarStatus status)
{
	switch (status) {
	case E_CALENDAR_STATUS_INVALID_ARG :
		return _("Invalid argument");
	case E_CALENDAR_STATUS_BUSY :
		return _("Backend is busy");
	case E_CALENDAR_STATUS_REPOSITORY_OFFLINE :
		return _("Repository is offline");
	case E_CALENDAR_STATUS_NO_SUCH_CALENDAR :
		return _("No such calendar");
	case E_CALENDAR_STATUS_OBJECT_NOT_FOUND :
		return _("Object not found");
	case E_CALENDAR_STATUS_INVALID_OBJECT :
		return _("Invalid object");
	case E_CALENDAR_STATUS_URI_NOT_LOADED :
		return _("URI not loaded");
	case E_CALENDAR_STATUS_URI_ALREADY_LOADED :
		return _("URI already loaded");
	case E_CALENDAR_STATUS_PERMISSION_DENIED :
		return _("Permission denied");
	case E_CALENDAR_STATUS_UNKNOWN_USER :
		return _("Unknown User");
	case E_CALENDAR_STATUS_OBJECT_ID_ALREADY_EXISTS :
		return _("Object ID already exists");
	case E_CALENDAR_STATUS_PROTOCOL_NOT_SUPPORTED :
		return _("Protocol not supported");
	case E_CALENDAR_STATUS_CANCELLED :
		return _("Operation has been cancelled");
	case E_CALENDAR_STATUS_COULD_NOT_CANCEL :
		return _("Could not cancel operation");
	case E_CALENDAR_STATUS_AUTHENTICATION_FAILED :
		return _("Authentication failed");
	case E_CALENDAR_STATUS_AUTHENTICATION_REQUIRED :
		return _("Authentication required");
	case E_CALENDAR_STATUS_DBUS_EXCEPTION :
		return _("A D-Bus exception has occurred");
	case E_CALENDAR_STATUS_OTHER_ERROR :
		return _("Unknown error");
	case E_CALENDAR_STATUS_OK :
		return _("No error");
	case E_CALENDAR_STATUS_NOT_SUPPORTED :
		/* Translators: The string for NOT_SUPPORTED error */
		return _("Not supported");
	default:
		/* ignore everything else */
		break;
	}

	return NULL;
}
