/*
 * e-cal-client.c
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

/**
 * SECTION: e-cal-client
 * @include: libecal/libecal.h
 * @short_description: Accessing and modifying a calendar 
 *
 * This class is the main user facing API for accessing and modifying
 * the calendar.
 **/

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>
#include <gio/gio.h>

/* Private D-Bus classes. */
#include <e-dbus-calendar.h>
#include <e-dbus-calendar-factory.h>

#include <libedataserver/e-client-private.h>

#include "e-cal-client.h"
#include "e-cal-component.h"
#include "e-cal-check-timezones.h"
#include "e-cal-enumtypes.h"
#include "e-cal-time-util.h"
#include "e-cal-types.h"
#include "e-timezone-cache.h"

#define E_CAL_CLIENT_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_CAL_CLIENT, ECalClientPrivate))

/* Set this to a sufficiently large value
 * to cover most long-running operations. */
#define DBUS_PROXY_TIMEOUT_MS (3 * 60 * 1000)  /* 3 minutes */

typedef struct _AsyncContext AsyncContext;
typedef struct _SignalClosure SignalClosure;
typedef struct _ConnectClosure ConnectClosure;
typedef struct _RunInThreadClosure RunInThreadClosure;

struct _ECalClientPrivate {
	EDBusCalendar *dbus_proxy;
	guint name_watcher_id;

	ECalClientSourceType source_type;
	icaltimezone *default_zone;

	GMutex zone_cache_lock;
	GHashTable *zone_cache;

	gulong dbus_proxy_error_handler_id;
	gulong dbus_proxy_notify_handler_id;
	gulong dbus_proxy_free_busy_data_handler_id;
};

struct _AsyncContext {
	ECalClientView *client_view;
	icalcomponent *in_comp;
	icalcomponent *out_comp;
	icaltimezone *zone;
	GSList *comp_list;
	GSList *object_list;
	GSList *string_list;
	gchar *sexp;
	gchar *tzid;
	gchar *uid;
	gchar *rid;
	gchar *auid;
	ECalObjModType mod;
	time_t start;
	time_t end;
};

struct _SignalClosure {
	GWeakRef client;
	gchar *property_name;
	gchar *error_message;
	gchar **free_busy_data;
	icaltimezone *cached_zone;
};

struct _ConnectClosure {
	ESource *source;
	GCancellable *cancellable;
	guint32 wait_for_connected_seconds;
};

struct _RunInThreadClosure {
	GSimpleAsyncThreadFunc func;
	GSimpleAsyncResult *simple;
	GCancellable *cancellable;
};

enum {
	PROP_0,
	PROP_DEFAULT_TIMEZONE,
	PROP_SOURCE_TYPE
};

enum {
	FREE_BUSY_DATA,
	LAST_SIGNAL
};

/* Forward Declarations */
static void	e_cal_client_initable_init
					(GInitableIface *iface);
static void	e_cal_client_async_initable_init
					(GAsyncInitableIface *iface);
static void	e_cal_client_timezone_cache_init
					(ETimezoneCacheInterface *iface);

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE_WITH_CODE (
	ECalClient,
	e_cal_client,
	E_TYPE_CLIENT,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_cal_client_initable_init)
	G_IMPLEMENT_INTERFACE (
		G_TYPE_ASYNC_INITABLE,
		e_cal_client_async_initable_init)
	G_IMPLEMENT_INTERFACE (
		E_TYPE_TIMEZONE_CACHE,
		e_cal_client_timezone_cache_init))

static void
async_context_free (AsyncContext *async_context)
{
	if (async_context->client_view != NULL)
		g_object_unref (async_context->client_view);

	if (async_context->in_comp != NULL)
		icalcomponent_free (async_context->in_comp);

	if (async_context->out_comp != NULL)
		icalcomponent_free (async_context->out_comp);

	if (async_context->zone != NULL)
		icaltimezone_free (async_context->zone, 1);

	g_slist_free_full (
		async_context->comp_list,
		(GDestroyNotify) icalcomponent_free);

	g_slist_free_full (
		async_context->object_list,
		(GDestroyNotify) g_object_unref);

	g_slist_free_full (
		async_context->string_list,
		(GDestroyNotify) g_free);

	g_free (async_context->sexp);
	g_free (async_context->tzid);
	g_free (async_context->uid);
	g_free (async_context->rid);
	g_free (async_context->auid);

	g_slice_free (AsyncContext, async_context);
}

static void
signal_closure_free (SignalClosure *signal_closure)
{
	g_weak_ref_clear (&signal_closure->client);

	g_free (signal_closure->property_name);
	g_free (signal_closure->error_message);

	g_strfreev (signal_closure->free_busy_data);

	/* The icaltimezone is cached in ECalClient's internal
	 * "zone_cache" hash table and must not be freed here. */

	g_slice_free (SignalClosure, signal_closure);
}

static void
connect_closure_free (ConnectClosure *connect_closure)
{
	if (connect_closure->source != NULL)
		g_object_unref (connect_closure->source);

	if (connect_closure->cancellable != NULL)
		g_object_unref (connect_closure->cancellable);

	g_slice_free (ConnectClosure, connect_closure);
}

static void
run_in_thread_closure_free (RunInThreadClosure *run_in_thread_closure)
{
	if (run_in_thread_closure->simple != NULL)
		g_object_unref (run_in_thread_closure->simple);

	if (run_in_thread_closure->cancellable != NULL)
		g_object_unref (run_in_thread_closure->cancellable);

	g_slice_free (RunInThreadClosure, run_in_thread_closure);
}

static void
free_zone_cb (gpointer zone)
{
	icaltimezone_free (zone, 1);
}

/*
 * Well-known calendar backend properties:
 * @CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS: Contains default calendar's email
 *   address suggested by the backend.
 * @CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS: Contains default alarm email
 *   address suggested by the backend.
 * @CAL_BACKEND_PROPERTY_DEFAULT_OBJECT: Contains iCal component string
 *   of an #icalcomponent with the default values for properties needed.
 *   Preferred way of retrieving this property is by
 *   calling e_cal_client_get_default_object().
 *
 * See also: @CLIENT_BACKEND_PROPERTY_OPENED, @CLIENT_BACKEND_PROPERTY_OPENING,
 *   @CLIENT_BACKEND_PROPERTY_ONLINE, @CLIENT_BACKEND_PROPERTY_READONLY
 *   @CLIENT_BACKEND_PROPERTY_CACHE_DIR, @CLIENT_BACKEND_PROPERTY_CAPABILITIES
 */

G_DEFINE_QUARK (e-cal-client-error-quark, e_cal_client_error)

/**
 * e_cal_client_error_to_string:
 * @code: an #ECalClientError error code
 *
 * Get localized human readable description of the given error code.
 *
 * Returns: Localized human readable description of the given error code
 *
 * Since: 3.2
 **/
const gchar *
e_cal_client_error_to_string (ECalClientError code)
{
	switch (code) {
	case E_CAL_CLIENT_ERROR_NO_SUCH_CALENDAR:
		return _("No such calendar");
	case E_CAL_CLIENT_ERROR_OBJECT_NOT_FOUND:
		return _("Object not found");
	case E_CAL_CLIENT_ERROR_INVALID_OBJECT:
		return _("Invalid object");
	case E_CAL_CLIENT_ERROR_UNKNOWN_USER:
		return _("Unknown user");
	case E_CAL_CLIENT_ERROR_OBJECT_ID_ALREADY_EXISTS:
		return _("Object ID already exists");
	case E_CAL_CLIENT_ERROR_INVALID_RANGE:
		return _("Invalid range");
	}

	return _("Unknown error");
}

/**
 * e_cal_client_error_create:
 * @code: an #ECalClientError code to create
 * @custom_msg: custom message to use for the error; can be %NULL
 *
 * Returns: a new #GError containing an E_CAL_CLIENT_ERROR of the given
 * @code. If the @custom_msg is NULL, then the error message is
 * the one returned from e_cal_client_error_to_string() for the @code,
 * otherwise the given message is used.
 *
 * Returned pointer should be freed with g_error_free().
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Just use the #GError API directly.
 **/
GError *
e_cal_client_error_create (ECalClientError code,
                           const gchar *custom_msg)
{
	if (custom_msg == NULL)
		custom_msg = e_cal_client_error_to_string (code);

	return g_error_new_literal (E_CAL_CLIENT_ERROR, code, custom_msg);
}

static gpointer
cal_client_dbus_thread (gpointer user_data)
{
	GMainContext *main_context = user_data;
	GMainLoop *main_loop;

	g_main_context_push_thread_default (main_context);

	main_loop = g_main_loop_new (main_context, FALSE);
	g_main_loop_run (main_loop);
	g_main_loop_unref (main_loop);

	g_main_context_pop_thread_default (main_context);

	g_main_context_unref (main_context);

	return NULL;
}

static gpointer
cal_client_dbus_thread_init (gpointer unused)
{
	GMainContext *main_context;

	main_context = g_main_context_new ();

	/* This thread terminates when the process itself terminates, so
	 * no need to worry about unreferencing the returned GThread. */
	g_thread_new (
		"cal-client-dbus-thread",
		cal_client_dbus_thread,
		g_main_context_ref (main_context));

	return main_context;
}

static GMainContext *
cal_client_ref_dbus_main_context (void)
{
	static GOnce cal_client_dbus_thread_once = G_ONCE_INIT;

	g_once (
		&cal_client_dbus_thread_once,
		cal_client_dbus_thread_init, NULL);

	return g_main_context_ref (cal_client_dbus_thread_once.retval);
}

static gboolean
cal_client_run_in_dbus_thread_idle_cb (gpointer user_data)
{
	RunInThreadClosure *closure = user_data;
	GObject *source_object;
	GAsyncResult *result;

	result = G_ASYNC_RESULT (closure->simple);
	source_object = g_async_result_get_source_object (result);

	closure->func (
		closure->simple,
		source_object,
		closure->cancellable);

	if (source_object != NULL)
		g_object_unref (source_object);

	g_simple_async_result_complete_in_idle (closure->simple);

	return FALSE;
}

static void
cal_client_run_in_dbus_thread (GSimpleAsyncResult *simple,
                               GSimpleAsyncThreadFunc func,
                               gint io_priority,
                               GCancellable *cancellable)
{
	RunInThreadClosure *closure;
	GMainContext *main_context;
	GSource *idle_source;

	main_context = cal_client_ref_dbus_main_context ();

	closure = g_slice_new0 (RunInThreadClosure);
	closure->func = func;
	closure->simple = g_object_ref (simple);

	if (G_IS_CANCELLABLE (cancellable))
		closure->cancellable = g_object_ref (cancellable);

	idle_source = g_idle_source_new ();
	g_source_set_priority (idle_source, io_priority);
	g_source_set_callback (
		idle_source, cal_client_run_in_dbus_thread_idle_cb,
		closure, (GDestroyNotify) run_in_thread_closure_free);
	g_source_attach (idle_source, main_context);
	g_source_unref (idle_source);

	g_main_context_unref (main_context);
}

static gboolean
cal_client_emit_backend_died_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EClient *client;

	client = g_weak_ref_get (&signal_closure->client);

	if (client != NULL) {
		g_signal_emit_by_name (client, "backend-died");
		g_object_unref (client);
	}

	return FALSE;
}

static gboolean
cal_client_emit_backend_error_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EClient *client;

	client = g_weak_ref_get (&signal_closure->client);

	if (client != NULL) {
		g_signal_emit_by_name (
			client, "backend-error",
			signal_closure->error_message);
		g_object_unref (client);
	}

	return FALSE;
}

static gboolean
cal_client_emit_backend_property_changed_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EClient *client;

	client = g_weak_ref_get (&signal_closure->client);

	if (client != NULL) {
		gchar *prop_value = NULL;

		/* XXX Despite appearances, this function does not block. */
		e_client_get_backend_property_sync (
			client,
			signal_closure->property_name,
			&prop_value, NULL, NULL);

		if (prop_value != NULL) {
			g_signal_emit_by_name (
				client,
				"backend-property-changed",
				signal_closure->property_name,
				prop_value);
			g_free (prop_value);
		}

		g_object_unref (client);
	}

	return FALSE;
}

static gboolean
cal_client_emit_free_busy_data_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EClient *client;

	client = g_weak_ref_get (&signal_closure->client);

	if (client != NULL) {
		GSList *list = NULL;
		gchar **strv;
		gint ii;

		strv = signal_closure->free_busy_data;

		for (ii = 0; strv[ii] != NULL; ii++) {
			ECalComponent *comp;
			icalcomponent *icalcomp;
			icalcomponent_kind kind;

			icalcomp = icalcomponent_new_from_string (strv[ii]);
			if (icalcomp == NULL)
				continue;

			kind = icalcomponent_isa (icalcomp);
			if (kind != ICAL_VFREEBUSY_COMPONENT) {
				icalcomponent_free (icalcomp);
				continue;
			}

			comp = e_cal_component_new ();
			if (!e_cal_component_set_icalcomponent (comp, icalcomp)) {
				icalcomponent_free (icalcomp);
				g_object_unref (comp);
				continue;
			}

			list = g_slist_prepend (list, comp);
		}

		list = g_slist_reverse (list);

		g_signal_emit (client, signals[FREE_BUSY_DATA], 0, list);

		g_slist_free_full (list, (GDestroyNotify) g_object_unref);

		g_object_unref (client);
	}

	return FALSE;
}

static gboolean
cal_client_emit_timezone_added_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	EClient *client;

	client = g_weak_ref_get (&signal_closure->client);

	if (client != NULL) {
		g_signal_emit_by_name (
			client, "timezone-added",
			signal_closure->cached_zone);
		g_object_unref (client);
	}

	return FALSE;
}

static void
cal_client_dbus_proxy_error_cb (EDBusCalendar *dbus_proxy,
                                const gchar *error_message,
                                GWeakRef *client_weak_ref)
{
	EClient *client;

	client = g_weak_ref_get (client_weak_ref);

	if (client != NULL) {
		GSource *idle_source;
		GMainContext *main_context;
		SignalClosure *signal_closure;

		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->client, client);
		signal_closure->error_message = g_strdup (error_message);

		main_context = e_client_ref_main_context (client);

		idle_source = g_idle_source_new ();
		g_source_set_callback (
			idle_source,
			cal_client_emit_backend_error_idle_cb,
			signal_closure,
			(GDestroyNotify) signal_closure_free);
		g_source_attach (idle_source, main_context);
		g_source_unref (idle_source);

		g_main_context_unref (main_context);

		g_object_unref (client);
	}
}

static void
cal_client_dbus_proxy_property_changed (EClient *client,
					const gchar *property_name,
					const GValue *value,
					gboolean is_in_main_thread)
{
	const gchar *backend_prop_name = NULL;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (property_name != NULL);

	if (g_str_equal (property_name, "alarm-email-address")) {
		backend_prop_name = CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS;
	}

	if (g_str_equal (property_name, "cache-dir")) {
		backend_prop_name = CLIENT_BACKEND_PROPERTY_CACHE_DIR;
	}

	if (g_str_equal (property_name, "cal-email-address")) {
		backend_prop_name = CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS;
	}

	if (g_str_equal (property_name, "capabilities")) {
		gchar **strv;
		gchar *csv = NULL;

		backend_prop_name = CLIENT_BACKEND_PROPERTY_CAPABILITIES;

		strv = g_value_get_boxed (value);
		if (strv != NULL) {
			csv = g_strjoinv (",", strv);
		}
		e_client_set_capabilities (client, csv);
		g_free (csv);
	}

	if (g_str_equal (property_name, "default-object")) {
		backend_prop_name = CAL_BACKEND_PROPERTY_DEFAULT_OBJECT;
	}

	if (g_str_equal (property_name, "online")) {
		gboolean online;

		backend_prop_name = CLIENT_BACKEND_PROPERTY_ONLINE;

		online = g_value_get_boolean (value);
		e_client_set_online (client, online);
	}

	if (g_str_equal (property_name, "revision")) {
		backend_prop_name = CLIENT_BACKEND_PROPERTY_REVISION;
	}

	if (g_str_equal (property_name, "writable")) {
		gboolean writable;

		backend_prop_name = CLIENT_BACKEND_PROPERTY_READONLY;

		writable = g_value_get_boolean (value);
		e_client_set_readonly (client, !writable);
	}

	if (backend_prop_name != NULL) {
		SignalClosure *signal_closure;

		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->client, client);
		signal_closure->property_name = g_strdup (backend_prop_name);

		if (is_in_main_thread) {
			cal_client_emit_backend_property_changed_idle_cb (signal_closure);
			signal_closure_free (signal_closure);
		} else {
			GSource *idle_source;
			GMainContext *main_context;

			main_context = e_client_ref_main_context (client);

			idle_source = g_idle_source_new ();
			g_source_set_callback (
				idle_source,
				cal_client_emit_backend_property_changed_idle_cb,
				signal_closure,
				(GDestroyNotify) signal_closure_free);
			g_source_attach (idle_source, main_context);
			g_source_unref (idle_source);

			g_main_context_unref (main_context);
		}
	}

}

typedef struct {
	EClient *client;
	gchar *property_name;
	GValue property_value;
} IdleProxyNotifyData;

static void
idle_proxy_notify_data_free (gpointer ptr)
{
	IdleProxyNotifyData *ipn = ptr;

	if (ipn) {
		g_clear_object (&ipn->client);
		g_free (ipn->property_name);
		g_value_unset (&ipn->property_value);
		g_free (ipn);
	}
}

static gboolean
cal_client_proxy_notify_idle_cb (gpointer user_data)
{
	IdleProxyNotifyData *ipn = user_data;

	g_return_val_if_fail (ipn != NULL, FALSE);

	cal_client_dbus_proxy_property_changed (ipn->client, ipn->property_name, &ipn->property_value, TRUE);

	return FALSE;
}

static void
cal_client_dbus_proxy_notify_cb (EDBusCalendar *dbus_proxy,
                                 GParamSpec *pspec,
                                 GWeakRef *client_weak_ref)
{
	EClient *client;
	GSource *idle_source;
	GMainContext *main_context;
	IdleProxyNotifyData *ipn;

	client = g_weak_ref_get (client_weak_ref);
	if (client == NULL)
		return;

	ipn = g_new0 (IdleProxyNotifyData, 1);
	ipn->client = g_object_ref (client);
	ipn->property_name = g_strdup (pspec->name);
	g_value_init (&ipn->property_value, pspec->value_type);
	g_object_get_property (G_OBJECT (dbus_proxy), pspec->name, &ipn->property_value);

	main_context = e_client_ref_main_context (client);

	idle_source = g_idle_source_new ();
	g_source_set_callback (idle_source, cal_client_proxy_notify_idle_cb,
		ipn, idle_proxy_notify_data_free);
	g_source_attach (idle_source, main_context);
	g_source_unref (idle_source);

	g_main_context_unref (main_context);
	g_object_unref (client);
}

static void
cal_client_dbus_proxy_free_busy_data_cb (EDBusCalendar *dbus_proxy,
                                         gchar **free_busy_data,
                                         EClient *client)
{
	GSource *idle_source;
	GMainContext *main_context;
	SignalClosure *signal_closure;

	signal_closure = g_slice_new0 (SignalClosure);
	g_weak_ref_init (&signal_closure->client, client);
	signal_closure->free_busy_data = g_strdupv (free_busy_data);

	main_context = e_client_ref_main_context (client);

	idle_source = g_idle_source_new ();
	g_source_set_callback (
		idle_source,
		cal_client_emit_free_busy_data_idle_cb,
		signal_closure,
		(GDestroyNotify) signal_closure_free);
	g_source_attach (idle_source, main_context);
	g_source_unref (idle_source);

	g_main_context_unref (main_context);
}

static void
cal_client_name_vanished_cb (GDBusConnection *connection,
                             const gchar *name,
                             GWeakRef *client_weak_ref)
{
	EClient *client;

	client = g_weak_ref_get (client_weak_ref);

	if (client != NULL) {
		GSource *idle_source;
		GMainContext *main_context;
		SignalClosure *signal_closure;

		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->client, client);

		main_context = e_client_ref_main_context (client);

		idle_source = g_idle_source_new ();
		g_source_set_callback (
			idle_source,
			cal_client_emit_backend_died_idle_cb,
			signal_closure,
			(GDestroyNotify) signal_closure_free);
		g_source_attach (idle_source, main_context);
		g_source_unref (idle_source);

		g_main_context_unref (main_context);

		g_object_unref (client);
	}
}

static void
cal_client_set_source_type (ECalClient *cal_client,
                            ECalClientSourceType source_type)
{
	cal_client->priv->source_type = source_type;
}

static void
cal_client_set_property (GObject *object,
                         guint property_id,
                         const GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_DEFAULT_TIMEZONE:
			e_cal_client_set_default_timezone (
				E_CAL_CLIENT (object),
				g_value_get_pointer (value));
			return;

		case PROP_SOURCE_TYPE:
			cal_client_set_source_type (
				E_CAL_CLIENT (object),
				g_value_get_enum (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
cal_client_get_property (GObject *object,
                         guint property_id,
                         GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_DEFAULT_TIMEZONE:
			g_value_set_pointer (
				value,
				e_cal_client_get_default_timezone (
				E_CAL_CLIENT (object)));
			return;

		case PROP_SOURCE_TYPE:
			g_value_set_enum (
				value,
				e_cal_client_get_source_type (
				E_CAL_CLIENT (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
cal_client_dispose (GObject *object)
{
	ECalClientPrivate *priv;

	priv = E_CAL_CLIENT_GET_PRIVATE (object);

	if (priv->dbus_proxy_error_handler_id > 0) {
		g_signal_handler_disconnect (
			priv->dbus_proxy,
			priv->dbus_proxy_error_handler_id);
		priv->dbus_proxy_error_handler_id = 0;
	}

	if (priv->dbus_proxy_notify_handler_id > 0) {
		g_signal_handler_disconnect (
			priv->dbus_proxy,
			priv->dbus_proxy_notify_handler_id);
		priv->dbus_proxy_notify_handler_id = 0;
	}

	if (priv->dbus_proxy_free_busy_data_handler_id > 0) {
		g_signal_handler_disconnect (
			priv->dbus_proxy,
			priv->dbus_proxy_free_busy_data_handler_id);
		priv->dbus_proxy_free_busy_data_handler_id = 0;
	}

	if (priv->dbus_proxy != NULL) {
		/* Call close() asynchronously so we don't block dispose().
		 * Also omit a callback function, so the GDBusMessage uses
		 * G_DBUS_MESSAGE_FLAGS_NO_REPLY_EXPECTED. */
		e_dbus_calendar_call_close (
			priv->dbus_proxy, NULL, NULL, NULL);
		g_object_unref (priv->dbus_proxy);
		priv->dbus_proxy = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_cal_client_parent_class)->dispose (object);
}

static void
cal_client_finalize (GObject *object)
{
	ECalClientPrivate *priv;

	priv = E_CAL_CLIENT_GET_PRIVATE (object);

	if (priv->name_watcher_id > 0)
		g_bus_unwatch_name (priv->name_watcher_id);

	if (priv->default_zone && priv->default_zone != icaltimezone_get_utc_timezone ())
		icaltimezone_free (priv->default_zone, 1);

	g_mutex_lock (&priv->zone_cache_lock);
	g_hash_table_destroy (priv->zone_cache);
	g_mutex_unlock (&priv->zone_cache_lock);

	g_mutex_clear (&priv->zone_cache_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_cal_client_parent_class)->finalize (object);
}

static void
cal_client_process_properties (ECalClient *cal_client,
			       gchar * const *properties)
{
	GObject *dbus_proxy;
	GObjectClass *object_class;
	gint ii;

	g_return_if_fail (E_IS_CAL_CLIENT (cal_client));

	dbus_proxy = G_OBJECT (cal_client->priv->dbus_proxy);
	g_return_if_fail (G_IS_OBJECT (dbus_proxy));

	if (!properties)
		return;

	object_class = G_OBJECT_GET_CLASS (dbus_proxy);

	for (ii = 0; properties[ii]; ii++) {
		if (!(ii & 1) && properties[ii + 1]) {
			GParamSpec *param;
			GVariant *expected = NULL;

			param = g_object_class_find_property (object_class, properties[ii]);
			if (param) {
				#define WORKOUT(gvl, gvr) \
					if (g_type_is_a (param->value_type, G_TYPE_ ## gvl)) { \
						expected = g_variant_parse (G_VARIANT_TYPE_ ## gvr, properties[ii + 1], NULL, NULL, NULL); \
					}

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
			}

			/* Update the property always, even when the current value on the GDBusProxy
			   matches the expected value, because sometimes the proxy can have up-to-date
			   values, but still not propagated into EClient properties. */
			if (expected) {
				GValue value = G_VALUE_INIT;

				g_dbus_gvariant_to_gvalue (expected, &value);

				cal_client_dbus_proxy_property_changed (E_CLIENT (cal_client), param->name, &value, FALSE);

				g_value_unset (&value);
				g_variant_unref (expected);
			}
		}
	}
}

static GDBusProxy *
cal_client_get_dbus_proxy (EClient *client)
{
	ECalClientPrivate *priv;

	priv = E_CAL_CLIENT_GET_PRIVATE (client);

	return G_DBUS_PROXY (priv->dbus_proxy);
}

static gboolean
cal_client_get_backend_property_sync (EClient *client,
                                      const gchar *prop_name,
                                      gchar **prop_value,
                                      GCancellable *cancellable,
                                      GError **error)
{
	ECalClient *cal_client;
	EDBusCalendar *dbus_proxy;
	gchar **strv;

	cal_client = E_CAL_CLIENT (client);
	dbus_proxy = cal_client->priv->dbus_proxy;

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_OPENED)) {
		*prop_value = g_strdup ("TRUE");
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_OPENING)) {
		*prop_value = g_strdup ("FALSE");
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_ONLINE)) {
		if (e_dbus_calendar_get_online (dbus_proxy))
			*prop_value = g_strdup ("TRUE");
		else
			*prop_value = g_strdup ("FALSE");
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_READONLY)) {
		if (e_dbus_calendar_get_writable (dbus_proxy))
			*prop_value = g_strdup ("FALSE");
		else
			*prop_value = g_strdup ("TRUE");
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_CACHE_DIR)) {
		*prop_value = e_dbus_calendar_dup_cache_dir (dbus_proxy);
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_REVISION)) {
		*prop_value = e_dbus_calendar_dup_revision (dbus_proxy);
		return TRUE;
	}

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_CAPABILITIES)) {
		strv = e_dbus_calendar_dup_capabilities (dbus_proxy);
		if (strv != NULL)
			*prop_value = g_strjoinv (",", strv);
		else
			*prop_value = g_strdup ("");
		g_strfreev (strv);
		return TRUE;
	}

	if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS)) {
		*prop_value = e_dbus_calendar_dup_alarm_email_address (dbus_proxy);
		return TRUE;
	}

	if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS)) {
		*prop_value = e_dbus_calendar_dup_cal_email_address (dbus_proxy);
		return TRUE;
	}

	if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_DEFAULT_OBJECT)) {
		*prop_value = e_dbus_calendar_dup_default_object (dbus_proxy);
		return TRUE;
	}

	g_set_error (
		error, E_CLIENT_ERROR, E_CLIENT_ERROR_NOT_SUPPORTED,
		_("Unknown calendar property “%s”"), prop_name);

	return FALSE;
}

static gboolean
cal_client_set_backend_property_sync (EClient *client,
                                      const gchar *prop_name,
                                      const gchar *prop_value,
                                      GCancellable *cancellable,
                                      GError **error)
{
	g_set_error (
		error, E_CLIENT_ERROR,
		E_CLIENT_ERROR_NOT_SUPPORTED,
		_("Cannot change value of calendar property “%s”"),
		prop_name);

	return FALSE;
}

static gboolean
cal_client_open_sync (EClient *client,
                      gboolean only_if_exists,
                      GCancellable *cancellable,
                      GError **error)
{
	ECalClient *cal_client;
	gchar **properties = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);

	cal_client = E_CAL_CLIENT (client);

	e_dbus_calendar_call_open_sync (
		cal_client->priv->dbus_proxy, &properties, cancellable, &local_error);

	cal_client_process_properties (cal_client, properties);
	g_strfreev (properties);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

static gboolean
cal_client_refresh_sync (EClient *client,
                         GCancellable *cancellable,
                         GError **error)
{
	ECalClient *cal_client;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);

	cal_client = E_CAL_CLIENT (client);

	e_dbus_calendar_call_refresh_sync (
		cal_client->priv->dbus_proxy, cancellable, &local_error);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

static gboolean
cal_client_retrieve_properties_sync (EClient *client,
				     GCancellable *cancellable,
				     GError **error)
{
	ECalClient *cal_client;
	gchar **properties = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);

	cal_client = E_CAL_CLIENT (client);

	e_dbus_calendar_call_retrieve_properties_sync (cal_client->priv->dbus_proxy, &properties, cancellable, &local_error);

	cal_client_process_properties (cal_client, properties);
	g_strfreev (properties);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

static void
cal_client_init_in_dbus_thread (GSimpleAsyncResult *simple,
                                GObject *source_object,
                                GCancellable *cancellable)
{
	ECalClientPrivate *priv;
	EDBusCalendarFactory *factory_proxy;
	GDBusConnection *connection;
	GDBusProxy *proxy;
	EClient *client;
	ESource *source;
	const gchar *uid;
	gchar *object_path = NULL;
	gchar *bus_name = NULL;
	gulong handler_id;
	GError *local_error = NULL;

	priv = E_CAL_CLIENT_GET_PRIVATE (source_object);

	client = E_CLIENT (source_object);
	source = e_client_get_source (client);
	uid = e_source_get_uid (source);

	connection = g_bus_get_sync (
		G_BUS_TYPE_SESSION, cancellable, &local_error);

	/* Sanity check. */
	g_return_if_fail (
		((connection != NULL) && (local_error == NULL)) ||
		((connection == NULL) && (local_error != NULL)));

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
		return;
	}

	factory_proxy = e_dbus_calendar_factory_proxy_new_sync (
		connection,
		G_DBUS_PROXY_FLAGS_NONE,
		CALENDAR_DBUS_SERVICE_NAME,
		"/org/gnome/evolution/dataserver/CalendarFactory",
		cancellable, &local_error);

	/* Sanity check. */
	g_return_if_fail (
		((factory_proxy != NULL) && (local_error == NULL)) ||
		((factory_proxy == NULL) && (local_error != NULL)));

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
		g_object_unref (connection);
		return;
	}

	switch (e_cal_client_get_source_type (E_CAL_CLIENT (client))) {
		case E_CAL_CLIENT_SOURCE_TYPE_EVENTS:
			e_dbus_calendar_factory_call_open_calendar_sync (
				factory_proxy, uid, &object_path, &bus_name,
				cancellable, &local_error);
			break;
		case E_CAL_CLIENT_SOURCE_TYPE_TASKS:
			e_dbus_calendar_factory_call_open_task_list_sync (
				factory_proxy, uid, &object_path, &bus_name,
				cancellable, &local_error);
			break;
		case E_CAL_CLIENT_SOURCE_TYPE_MEMOS:
			e_dbus_calendar_factory_call_open_memo_list_sync (
				factory_proxy, uid, &object_path, &bus_name,
				cancellable, &local_error);
			break;
		default:
			g_return_if_reached ();
	}

	g_object_unref (factory_proxy);

	/* Sanity check. */
	g_return_if_fail (
		(((object_path != NULL) || (bus_name != NULL)) && (local_error == NULL)) ||
		(((object_path == NULL) || (bus_name == NULL)) && (local_error != NULL)));

	if (local_error) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
		g_object_unref (connection);
		return;
	}

	e_client_set_bus_name (client, bus_name);

	priv->dbus_proxy = e_dbus_calendar_proxy_new_sync (
		connection,
		G_DBUS_PROXY_FLAGS_DO_NOT_AUTO_START,
		bus_name, object_path, cancellable, &local_error);

	g_free (object_path);
	g_free (bus_name);

	/* Sanity check. */
	g_return_if_fail (
		((priv->dbus_proxy != NULL) && (local_error == NULL)) ||
		((priv->dbus_proxy == NULL) && (local_error != NULL)));

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
		g_object_unref (connection);
		return;
	}

	/* Configure our new GDBusProxy. */

	proxy = G_DBUS_PROXY (priv->dbus_proxy);

	g_dbus_proxy_set_default_timeout (proxy, DBUS_PROXY_TIMEOUT_MS);

	priv->name_watcher_id = g_bus_watch_name_on_connection (
		connection,
		g_dbus_proxy_get_name (proxy),
		G_BUS_NAME_WATCHER_FLAGS_NONE,
		(GBusNameAppearedCallback) NULL,
		(GBusNameVanishedCallback) cal_client_name_vanished_cb,
		e_weak_ref_new (client),
		(GDestroyNotify) e_weak_ref_free);

	handler_id = g_signal_connect_data (
		proxy, "error",
		G_CALLBACK (cal_client_dbus_proxy_error_cb),
		e_weak_ref_new (client),
		(GClosureNotify) e_weak_ref_free,
		0);
	priv->dbus_proxy_error_handler_id = handler_id;

	handler_id = g_signal_connect_data (
		proxy, "notify",
		G_CALLBACK (cal_client_dbus_proxy_notify_cb),
		e_weak_ref_new (client),
		(GClosureNotify) e_weak_ref_free,
		0);
	priv->dbus_proxy_notify_handler_id = handler_id;

	handler_id = g_signal_connect_object (
		proxy, "free-busy-data",
		G_CALLBACK (cal_client_dbus_proxy_free_busy_data_cb),
		client, 0);
	priv->dbus_proxy_free_busy_data_handler_id = handler_id;

	/* Initialize our public-facing GObject properties. */
	g_object_notify (G_OBJECT (proxy), "online");
	g_object_notify (G_OBJECT (proxy), "writable");
	g_object_notify (G_OBJECT (proxy), "capabilities");

	g_object_unref (connection);
}

static gboolean
cal_client_initable_init (GInitable *initable,
                          GCancellable *cancellable,
                          GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	closure = e_async_closure_new ();

	g_async_initable_init_async (
		G_ASYNC_INITABLE (initable),
		G_PRIORITY_DEFAULT, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = g_async_initable_init_finish (
		G_ASYNC_INITABLE (initable), result, error);

	e_async_closure_free (closure);

	return success;
}

static void
cal_client_initable_init_async (GAsyncInitable *initable,
                                gint io_priority,
                                GCancellable *cancellable,
                                GAsyncReadyCallback callback,
                                gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = g_simple_async_result_new (
		G_OBJECT (initable), callback, user_data,
		cal_client_initable_init_async);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	cal_client_run_in_dbus_thread (
		simple, cal_client_init_in_dbus_thread,
		io_priority, cancellable);

	g_object_unref (simple);
}

static gboolean
cal_client_initable_init_finish (GAsyncInitable *initable,
                                 GAsyncResult *result,
                                 GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (initable),
		cal_client_initable_init_async), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static void
cal_client_add_cached_timezone (ETimezoneCache *cache,
                                icaltimezone *zone)
{
	ECalClientPrivate *priv;
	const gchar *tzid;

	priv = E_CAL_CLIENT_GET_PRIVATE (cache);

	/* XXX Apparently this function can sometimes return NULL.
	 *     I'm not sure when or why that happens, but we can't
	 *     cache the icaltimezone if it has no tzid string. */
	tzid = icaltimezone_get_tzid (zone);
	if (tzid == NULL)
		return;

	g_mutex_lock (&priv->zone_cache_lock);

	/* Avoid replacing an existing cache entry.  We don't want to
	 * invalidate any icaltimezone pointers that may have already
	 * been returned through e_timezone_cache_get_timezone(). */
	if (!g_hash_table_contains (priv->zone_cache, tzid)) {
		GSource *idle_source;
		GMainContext *main_context;
		SignalClosure *signal_closure;

		icalcomponent *icalcomp;
		icaltimezone *cached_zone;

		cached_zone = icaltimezone_new ();
		icalcomp = icaltimezone_get_component (zone);
		icalcomp = icalcomponent_new_clone (icalcomp);
		icaltimezone_set_component (cached_zone, icalcomp);

		g_hash_table_insert (
			priv->zone_cache,
			g_strdup (tzid), cached_zone);

		/* The closure's client reference will keep the
		 * internally cached icaltimezone alive for the
		 * duration of the idle callback. */
		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->client, cache);
		signal_closure->cached_zone = cached_zone;

		main_context = e_client_ref_main_context (E_CLIENT (cache));

		idle_source = g_idle_source_new ();
		g_source_set_callback (
			idle_source,
			cal_client_emit_timezone_added_idle_cb,
			signal_closure,
			(GDestroyNotify) signal_closure_free);
		g_source_attach (idle_source, main_context);
		g_source_unref (idle_source);

		g_main_context_unref (main_context);
	}

	g_mutex_unlock (&priv->zone_cache_lock);
}

static icaltimezone *
cal_client_get_cached_timezone (ETimezoneCache *cache,
                                const gchar *tzid)
{
	ECalClientPrivate *priv;
	icaltimezone *zone = NULL;
	icaltimezone *builtin_zone = NULL;
	icalcomponent *icalcomp;
	icalproperty *prop;
	const gchar *builtin_tzid;

	priv = E_CAL_CLIENT_GET_PRIVATE (cache);

	if (g_str_equal (tzid, "UTC"))
		return icaltimezone_get_utc_timezone ();

	g_mutex_lock (&priv->zone_cache_lock);

	/* See if we already have it in the cache. */
	zone = g_hash_table_lookup (priv->zone_cache, tzid);

	if (zone != NULL)
		goto exit;

	/* Try to replace the original time zone with a more complete
	 * and/or potentially updated built-in time zone.  Note this also
	 * applies to TZIDs which match built-in time zones exactly: they
	 * are extracted via icaltimezone_get_builtin_timezone_from_tzid()
	 * below without a roundtrip to the backend. */

	builtin_tzid = e_cal_match_tzid (tzid);

	if (builtin_tzid != NULL)
		builtin_zone = icaltimezone_get_builtin_timezone_from_tzid (
			builtin_tzid);

	if (builtin_zone == NULL)
		goto exit;

	/* Use the built-in time zone *and* rename it.  Likely the caller
	 * is asking for a specific TZID because it has an event with such
	 * a TZID.  Returning an icaltimezone with a different TZID would
	 * lead to broken VCALENDARs in the caller. */

	icalcomp = icaltimezone_get_component (builtin_zone);
	icalcomp = icalcomponent_new_clone (icalcomp);

	prop = icalcomponent_get_first_property (
		icalcomp, ICAL_ANY_PROPERTY);

	while (prop != NULL) {
		if (icalproperty_isa (prop) == ICAL_TZID_PROPERTY) {
			icalproperty_set_value_from_string (prop, tzid, "NO");
			break;
		}

		prop = icalcomponent_get_next_property (
			icalcomp, ICAL_ANY_PROPERTY);
	}

	if (icalcomp != NULL) {
		zone = icaltimezone_new ();
		if (icaltimezone_set_component (zone, icalcomp)) {
			tzid = icaltimezone_get_tzid (zone);
			g_hash_table_insert (
				priv->zone_cache,
				g_strdup (tzid), zone);
		} else {
			icalcomponent_free (icalcomp);
			icaltimezone_free (zone, 1);
			zone = NULL;
		}
	}

exit:
	g_mutex_unlock (&priv->zone_cache_lock);

	return zone;
}

static GList *
cal_client_list_cached_timezones (ETimezoneCache *cache)
{
	ECalClientPrivate *priv;
	GList *list;

	priv = E_CAL_CLIENT_GET_PRIVATE (cache);

	g_mutex_lock (&priv->zone_cache_lock);

	list = g_hash_table_get_values (priv->zone_cache);

	g_mutex_unlock (&priv->zone_cache_lock);

	return list;
}

static void
e_cal_client_class_init (ECalClientClass *class)
{
	GObjectClass *object_class;
	EClientClass *client_class;

	g_type_class_add_private (class, sizeof (ECalClientPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = cal_client_set_property;
	object_class->get_property = cal_client_get_property;
	object_class->dispose = cal_client_dispose;
	object_class->finalize = cal_client_finalize;

	client_class = E_CLIENT_CLASS (class);
	client_class->get_dbus_proxy = cal_client_get_dbus_proxy;
	client_class->get_backend_property_sync = cal_client_get_backend_property_sync;
	client_class->set_backend_property_sync = cal_client_set_backend_property_sync;
	client_class->open_sync = cal_client_open_sync;
	client_class->refresh_sync = cal_client_refresh_sync;
	client_class->retrieve_properties_sync = cal_client_retrieve_properties_sync;

	g_object_class_install_property (
		object_class,
		PROP_DEFAULT_TIMEZONE,
		g_param_spec_pointer (
			"default-timezone",
			"Default Timezone",
			"Timezone used to resolve DATE "
			"and floating DATE-TIME values",
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_SOURCE_TYPE,
		g_param_spec_enum (
			"source-type",
			"Source Type",
			"The iCalendar data type",
			E_TYPE_CAL_CLIENT_SOURCE_TYPE,
			E_CAL_CLIENT_SOURCE_TYPE_EVENTS,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	signals[FREE_BUSY_DATA] = g_signal_new (
		"free-busy-data",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ECalClientClass, free_busy_data),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_POINTER);
}

static void
e_cal_client_initable_init (GInitableIface *iface)
{
	iface->init = cal_client_initable_init;
}

static void
e_cal_client_async_initable_init (GAsyncInitableIface *iface)
{
	iface->init_async = cal_client_initable_init_async;
	iface->init_finish = cal_client_initable_init_finish;
}

static void
e_cal_client_timezone_cache_init (ETimezoneCacheInterface *iface)
{
	iface->add_timezone = cal_client_add_cached_timezone;
	iface->get_timezone = cal_client_get_cached_timezone;
	iface->list_timezones = cal_client_list_cached_timezones;
}

static void
e_cal_client_init (ECalClient *client)
{
	GHashTable *zone_cache;

	zone_cache = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) free_zone_cb);

	client->priv = E_CAL_CLIENT_GET_PRIVATE (client);
	client->priv->source_type = E_CAL_CLIENT_SOURCE_TYPE_LAST;
	client->priv->default_zone = icaltimezone_get_utc_timezone ();
	g_mutex_init (&client->priv->zone_cache_lock);
	client->priv->zone_cache = zone_cache;
}

/**
 * e_cal_client_connect_sync:
 * @source: an #ESource
 * @source_type: source type of the calendar
 * @wait_for_connected_seconds: timeout, in seconds, to wait for the backend to be fully connected
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #ECalClient for @source and @source_type.  If an error
 * occurs, the function will set @error and return %FALSE.
 *
 * The @wait_for_connected_seconds argument had been added since 3.16,
 * to let the caller decide how long to wait for the backend to fully
 * connect to its (possibly remote) data store. This is required due
 * to a change in the authentication process, which is fully asynchronous
 * and done on the client side, while not every client is supposed to
 * response to authentication requests. In case the backend will not connect
 * within the set interval, then it is opened in an offline mode. A special
 * value -1 can be used to not wait for the connected state at all.
 *
 * Unlike with e_cal_client_new(), there is no need to call
 * e_client_open_sync() after obtaining the #ECalClient.
 *
 * For error handling convenience, any error message returned by this
 * function will have a descriptive prefix that includes the display
 * name of @source.
 *
 * Returns: (transfer full): a new #ECalClient, or %NULL
 *
 * Since: 3.8
 **/
EClient *
e_cal_client_connect_sync (ESource *source,
                           ECalClientSourceType source_type,
			   guint32 wait_for_connected_seconds,
                           GCancellable *cancellable,
                           GError **error)
{
	ECalClient *client;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_SOURCE (source), NULL);
	g_return_val_if_fail (
		source_type == E_CAL_CLIENT_SOURCE_TYPE_EVENTS ||
		source_type == E_CAL_CLIENT_SOURCE_TYPE_TASKS ||
		source_type == E_CAL_CLIENT_SOURCE_TYPE_MEMOS, NULL);

	client = g_object_new (
		E_TYPE_CAL_CLIENT,
		"source", source,
		"source-type", source_type, NULL);

	g_initable_init (G_INITABLE (client), cancellable, &local_error);

	if (local_error == NULL) {
		gchar **properties = NULL;

		e_dbus_calendar_call_open_sync (
			client->priv->dbus_proxy, &properties, cancellable, &local_error);

		cal_client_process_properties (client, properties);
		g_strfreev (properties);
	}

	if (!local_error && wait_for_connected_seconds != (guint32) -1) {
		/* These errors are ignored, the book is left opened in an offline mode. */
		e_client_wait_for_connected_sync (E_CLIENT (client),
			wait_for_connected_seconds, cancellable, NULL);
	}

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		g_prefix_error (
			error,_("Unable to connect to “%s”: "),
			e_source_get_display_name (source));
		g_object_unref (client);
		return NULL;
	}

	return E_CLIENT (client);
}

static void
cal_client_connect_wait_for_connected_cb (GObject *source_object,
					   GAsyncResult *result,
					   gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = G_SIMPLE_ASYNC_RESULT (user_data);

	/* These errors are ignored, the book is left opened in an offline mode. */
	e_client_wait_for_connected_finish (E_CLIENT (source_object), result, NULL);

	g_simple_async_result_complete (simple);

	g_object_unref (simple);
}

/* Helper for e_cal_client_connect() */
static void
cal_client_connect_open_cb (GObject *source_object,
                            GAsyncResult *result,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	gchar **properties = NULL;
	GObject *client_object;
	GError *local_error = NULL;

	simple = G_SIMPLE_ASYNC_RESULT (user_data);

	e_dbus_calendar_call_open_finish (
		E_DBUS_CALENDAR (source_object), &properties, result, &local_error);

	client_object = g_async_result_get_source_object (G_ASYNC_RESULT (simple));
	if (client_object) {
		cal_client_process_properties (E_CAL_CLIENT (client_object), properties);

		if (!local_error) {
			ConnectClosure *closure;

			closure = g_simple_async_result_get_op_res_gpointer (simple);
			if (closure->wait_for_connected_seconds != (guint32) -1) {
				e_client_wait_for_connected (E_CLIENT (client_object),
					closure->wait_for_connected_seconds,
					closure->cancellable,
					cal_client_connect_wait_for_connected_cb, g_object_ref (simple));

				g_clear_object (&client_object);
				g_object_unref (simple);
				g_strfreev (properties);
				return;
			}
		}

		g_clear_object (&client_object);
	}

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
	}

	g_simple_async_result_complete (simple);

	g_object_unref (simple);
	g_strfreev (properties);
}

/* Helper for e_cal_client_connect() */
static void
cal_client_connect_init_cb (GObject *source_object,
                            GAsyncResult *result,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	ECalClientPrivate *priv;
	ConnectClosure *closure;
	GError *local_error = NULL;

	simple = G_SIMPLE_ASYNC_RESULT (user_data);

	g_async_initable_init_finish (
		G_ASYNC_INITABLE (source_object), result, &local_error);

	if (local_error != NULL) {
		g_simple_async_result_take_error (simple, local_error);
		g_simple_async_result_complete (simple);
		goto exit;
	}

	/* Note, we're repurposing some function parameters. */

	result = G_ASYNC_RESULT (simple);
	source_object = g_async_result_get_source_object (result);
	closure = g_simple_async_result_get_op_res_gpointer (simple);

	priv = E_CAL_CLIENT_GET_PRIVATE (source_object);

	e_dbus_calendar_call_open (
		priv->dbus_proxy,
		closure->cancellable,
		cal_client_connect_open_cb,
		g_object_ref (simple));

	g_object_unref (source_object);

exit:
	g_object_unref (simple);
}

/**
 * e_cal_client_connect:
 * @source: an #ESource
 * @source_type: source tpe of the calendar
 * @wait_for_connected_seconds: timeout, in seconds, to wait for the backend to be fully connected
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously creates a new #ECalClient for @source and @source_type.
 *
 * The @wait_for_connected_seconds argument had been added since 3.16,
 * to let the caller decide how long to wait for the backend to fully
 * connect to its (possibly remote) data store. This is required due
 * to a change in the authentication process, which is fully asynchronous
 * and done on the client side, while not every client is supposed to
 * response to authentication requests. In case the backend will not connect
 * within the set interval, then it is opened in an offline mode. A special
 * value -1 can be used to not wait for the connected state at all.
 *
 * Unlike with e_cal_client_new(), there is no need to call e_client_open()
 * after obtaining the #ECalClient.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_cal_client_connect_finish() to get the result of the operation.
 *
 * Since: 3.8
 **/
void
e_cal_client_connect (ESource *source,
                      ECalClientSourceType source_type,
		      guint32 wait_for_connected_seconds,
                      GCancellable *cancellable,
                      GAsyncReadyCallback callback,
                      gpointer user_data)
{
	GSimpleAsyncResult *simple;
	ConnectClosure *closure;
	ECalClient *client;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (
		source_type == E_CAL_CLIENT_SOURCE_TYPE_EVENTS ||
		source_type == E_CAL_CLIENT_SOURCE_TYPE_TASKS ||
		source_type == E_CAL_CLIENT_SOURCE_TYPE_MEMOS);

	/* Two things with this: 1) instantiate the client object
	 * immediately to make sure the thread-default GMainContext
	 * gets plucked, and 2) do not call the D-Bus open() method
	 * from our designated D-Bus thread -- it may take a long
	 * time and block other clients from receiving signals. */

	closure = g_slice_new0 (ConnectClosure);
	closure->source = g_object_ref (source);
	closure->wait_for_connected_seconds = wait_for_connected_seconds;

	if (G_IS_CANCELLABLE (cancellable))
		closure->cancellable = g_object_ref (cancellable);

	client = g_object_new (
		E_TYPE_CAL_CLIENT,
		"source", source,
		"source-type", source_type, NULL);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback,
		user_data, e_cal_client_connect);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, closure, (GDestroyNotify) connect_closure_free);

	g_async_initable_init_async (
		G_ASYNC_INITABLE (client),
		G_PRIORITY_DEFAULT, cancellable,
		cal_client_connect_init_cb,
		g_object_ref (simple));

	g_object_unref (simple);
	g_object_unref (client);
}

/**
 * e_cal_client_connect_finish:
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_client_connect().  If an
 * error occurs in connecting to the D-Bus service, the function sets
 * @error and returns %NULL.
 *
 * For error handling convenience, any error message returned by this
 * function will have a descriptive prefix that includes the display
 * name of the #ESource passed to e_cal_client_connect().
 *
 * Returns: (transfer full): a new #ECalClient, or %NULL
 *
 * Since: 3.8
 **/
EClient *
e_cal_client_connect_finish (GAsyncResult *result,
                             GError **error)
{
	GSimpleAsyncResult *simple;
	ConnectClosure *closure;
	gpointer source_tag;

	g_return_val_if_fail (G_IS_SIMPLE_ASYNC_RESULT (result), NULL);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	closure = g_simple_async_result_get_op_res_gpointer (simple);

	source_tag = g_simple_async_result_get_source_tag (simple);
	g_return_val_if_fail (source_tag == e_cal_client_connect, NULL);

	if (g_simple_async_result_propagate_error (simple, error)) {
		g_prefix_error (
			error, _("Unable to connect to “%s”: "),
			e_source_get_display_name (closure->source));
		return NULL;
	}

	return E_CLIENT (g_async_result_get_source_object (result));
}

/**
 * e_cal_client_new:
 * @source: An #ESource pointer
 * @source_type: source type of the calendar
 * @error: A #GError pointer
 *
 * Creates a new #ECalClient corresponding to the given source.  There are
 * only two operations that are valid on this calendar at this point:
 * e_client_open(), and e_client_remove().
 *
 * Returns: a new but unopened #ECalClient.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: It covertly makes synchronous D-Bus calls, with no
 *                  way to cancel.  Use e_cal_client_connect() instead,
 *                  which combines e_cal_client_new() and e_client_open()
 *                  into one step.
 **/
ECalClient *
e_cal_client_new (ESource *source,
                  ECalClientSourceType source_type,
                  GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);
	g_return_val_if_fail (
		source_type == E_CAL_CLIENT_SOURCE_TYPE_EVENTS ||
		source_type == E_CAL_CLIENT_SOURCE_TYPE_TASKS ||
		source_type == E_CAL_CLIENT_SOURCE_TYPE_MEMOS, NULL);

	return g_initable_new (
		E_TYPE_CAL_CLIENT, NULL, error,
		"source", source,
		"source-type", source_type, NULL);
}

/**
 * e_cal_client_get_source_type:
 * @client: A calendar client.
 *
 * Gets the source type of the calendar client.
 *
 * Returns: an #ECalClientSourceType value corresponding
 * to the source type of the calendar client.
 *
 * Since: 3.2
 **/
ECalClientSourceType
e_cal_client_get_source_type (ECalClient *client)
{
	g_return_val_if_fail (
		E_IS_CAL_CLIENT (client),
		E_CAL_CLIENT_SOURCE_TYPE_LAST);

	return client->priv->source_type;
}

/**
 * e_cal_client_get_local_attachment_store:
 * @client: A calendar client.
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
 * Since: 3.2
 **/
const gchar *
e_cal_client_get_local_attachment_store (ECalClient *client)
{
	g_return_val_if_fail (E_IS_CAL_CLIENT (client), NULL);

	return e_dbus_calendar_get_cache_dir (client->priv->dbus_proxy);
}

/* icaltimezone_copy does a shallow copy while icaltimezone_free tries to
 * free the entire the contents inside the structure with libical 0.43.
 * Use this, till eds allows older libical.
 */
static icaltimezone *
copy_timezone (icaltimezone *ozone)
{
	icaltimezone *zone = NULL;
	const gchar *tzid;

	tzid = icaltimezone_get_tzid (ozone);

	if (g_strcmp0 (tzid, "UTC") != 0) {
		icalcomponent *comp;

		comp = icaltimezone_get_component (ozone);
		if (comp != NULL) {
			zone = icaltimezone_new ();
			icaltimezone_set_component (
				zone, icalcomponent_new_clone (comp));
		}
	}

	if (zone == NULL)
		zone = icaltimezone_get_utc_timezone ();

	return zone;
}

/**
 * e_cal_client_set_default_timezone:
 * @client: A calendar client.
 * @zone: A timezone object.
 *
 * Sets the default timezone to use to resolve DATE and floating DATE-TIME
 * values. This will typically be from the user's timezone setting. Call this
 * before using any other object fetching functions.
 *
 * Since: 3.2
 **/
void
e_cal_client_set_default_timezone (ECalClient *client,
                                   icaltimezone *zone)
{
	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (zone != NULL);

	if (zone == client->priv->default_zone)
		return;

	if (client->priv->default_zone != icaltimezone_get_utc_timezone ())
		icaltimezone_free (client->priv->default_zone, 1);

	if (zone == icaltimezone_get_utc_timezone ())
		client->priv->default_zone = zone;
	else
		client->priv->default_zone = copy_timezone (zone);

	g_object_notify (G_OBJECT (client), "default-timezone");
}

/**
 * e_cal_client_get_default_timezone:
 * @client: A calendar client.
 *
 * Returns the default timezone previously set with
 * e_cal_client_set_default_timezone().  The returned pointer is owned by
 * the @client and should not be freed.
 *
 * Returns: an #icaltimezone
 *
 * Since: 3.2
 **/
icaltimezone *
e_cal_client_get_default_timezone (ECalClient *client)
{
	g_return_val_if_fail (E_IS_CAL_CLIENT (client), NULL);

	return client->priv->default_zone;
}

/**
 * e_cal_client_check_one_alarm_only:
 * @client: A calendar client.
 *
 * Checks if a calendar supports only one alarm per component.
 *
 * Returns: TRUE if the calendar allows only one alarm, FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_check_one_alarm_only (ECalClient *client)
{
	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);

	return e_client_check_capability (
		E_CLIENT (client),
		CAL_STATIC_CAPABILITY_ONE_ALARM_ONLY);
}

/**
 * e_cal_client_check_save_schedules:
 * @client: A calendar client.
 *
 * Checks whether the calendar saves schedules.
 *
 * Returns: TRUE if it saves schedules, FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_check_save_schedules (ECalClient *client)
{
	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);

	return e_client_check_capability (
		E_CLIENT (client),
		CAL_STATIC_CAPABILITY_SAVE_SCHEDULES);
}

/**
 * e_cal_client_check_organizer_must_attend:
 * @client: A calendar client.
 *
 * Checks if a calendar forces organizers of meetings to be also attendees.
 *
 * Returns: TRUE if the calendar forces organizers to attend meetings,
 * FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_check_organizer_must_attend (ECalClient *client)
{
	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);

	return e_client_check_capability (
		E_CLIENT (client),
		CAL_STATIC_CAPABILITY_ORGANIZER_MUST_ATTEND);
}

/**
 * e_cal_client_check_organizer_must_accept:
 * @client: A calendar client.
 *
 * Checks whether a calendar requires organizer to accept their attendance to
 * meetings.
 *
 * Returns: TRUE if the calendar requires organizers to accept, FALSE
 * otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_check_organizer_must_accept (ECalClient *client)
{
	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);

	return e_client_check_capability (
		E_CLIENT (client),
		CAL_STATIC_CAPABILITY_ORGANIZER_MUST_ACCEPT);
}

/**
 * e_cal_client_check_recurrences_no_master:
 * @client: A calendar client.
 *
 * Checks if the calendar has a master object for recurrences.
 *
 * Returns: TRUE if the calendar has a master object for recurrences,
 * FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_check_recurrences_no_master (ECalClient *client)
{
	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);

	return e_client_check_capability (
		E_CLIENT (client),
		CAL_STATIC_CAPABILITY_RECURRENCES_NO_MASTER);
}

/**
 * e_cal_client_free_icalcomp_slist:
 * @icalcomps: (element-type icalcomponent): list of icalcomponent objects
 *
 * Frees each element of the @icalcomps list and the list itself.
 * Each element is an object of type #icalcomponent.
 *
 * Since: 3.2
 **/
void
e_cal_client_free_icalcomp_slist (GSList *icalcomps)
{
	g_slist_foreach (icalcomps, (GFunc) icalcomponent_free, NULL);
	g_slist_free (icalcomps);
}

/**
 * e_cal_client_free_ecalcomp_slist:
 * @ecalcomps: (element-type ECalComponent): list of #ECalComponent objects
 *
 * Frees each element of the @ecalcomps list and the list itself.
 * Each element is an object of type #ECalComponent.
 *
 * Since: 3.2
 **/
void
e_cal_client_free_ecalcomp_slist (GSList *ecalcomps)
{
	g_slist_foreach (ecalcomps, (GFunc) g_object_unref, NULL);
	g_slist_free (ecalcomps);
}

/**
 * e_cal_client_resolve_tzid_cb:
 * @tzid: ID of the timezone to resolve.
 * @data: Closure data for the callback, in this case #ECalClient.
 *
 * Resolves TZIDs for the recurrence generator.
 *
 * Returns: The timezone identified by the @tzid argument, or %NULL if
 * it could not be found.
 *
 * Since: 3.2
 */
icaltimezone *
e_cal_client_resolve_tzid_cb (const gchar *tzid,
                              gpointer data)
{
	ECalClient *client = data;
	icaltimezone *zone = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), NULL);

	e_cal_client_get_timezone_sync (
		client, tzid, &zone, NULL, &local_error);

	if (local_error != NULL) {
		g_debug (
			"%s: Failed to find '%s' timezone: %s",
			G_STRFUNC, tzid, local_error->message);
		g_error_free (local_error);
	}

	return zone;
}

/**
 * e_cal_client_resolve_tzid_sync:
 * @tzid: ID of the timezone to resolve.
 * @cal_client: User data for the callback, in this case #ECalClient.
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Resolves TZIDs for the recurrence generator.
 *
 * Returns: The timezone identified by the @tzid argument, or %NULL if
 * it could not be found.
 *
 * Since: 3.20
 */
icaltimezone *
e_cal_client_resolve_tzid_sync (const gchar *tzid,
				gpointer cal_client,
				GCancellable *cancellable,
				GError **error)
{
	icaltimezone *zone = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (cal_client), NULL);

	if (!e_cal_client_get_timezone_sync (cal_client, tzid, &zone, cancellable, error))
		return NULL;

	return zone;
}

struct comp_instance {
	ECalComponent *comp;
	time_t start;
	time_t end;
};

struct instances_info {
	GSList **instances;
	icaltimezone *start_zone;
	icaltimezone *end_zone;
	icaltimezone *default_zone;
};

/* Called from cal_recur_generate_instances(); adds an instance to the list */
static gboolean
add_instance (ECalComponent *comp,
              time_t start,
              time_t end,
              gpointer data)
{
	GSList **list;
	struct comp_instance *ci;
	icalcomponent *icalcomp;
	struct instances_info *instances_hold;

	instances_hold = data;
	list = instances_hold->instances;

	ci = g_new (struct comp_instance, 1);

	icalcomp = icalcomponent_new_clone (
		e_cal_component_get_icalcomponent (comp));

	/* add the instance to the list */
	ci->comp = e_cal_component_new ();
	e_cal_component_set_icalcomponent (ci->comp, icalcomp);

	/* make sure we return an instance */
	if (e_cal_util_component_has_recurrences (icalcomp) &&
	    !(icalcomponent_get_first_property (icalcomp, ICAL_RECURRENCEID_PROPERTY))) {
		ECalComponentRange *range;
		struct icaltimetype itt;
		ECalComponentDateTime dtstart, dtend;

		/* update DTSTART */
		dtstart.value = NULL;
		dtstart.tzid = NULL;

		e_cal_component_get_dtstart (comp, &dtstart);

		if (instances_hold->start_zone) {
			itt = icaltime_from_timet_with_zone (
				start, dtstart.value && dtstart.value->is_date,
				instances_hold->start_zone);
			g_free ((gchar *) dtstart.tzid);
			dtstart.tzid = g_strdup (icaltimezone_get_tzid (
				instances_hold->start_zone));
		} else if (dtstart.value && dtstart.value->is_date && !dtstart.tzid && instances_hold->default_zone) {
			/* Floating date, set in the default zone */
			itt = icaltime_from_timet_with_zone (start, TRUE, instances_hold->default_zone);
		} else {
			itt = icaltime_from_timet_with_zone (start, dtstart.value && dtstart.value->is_date, NULL);
			if (dtstart.tzid) {
				g_free ((gchar *) dtstart.tzid);
				dtstart.tzid = NULL;
			}
		}

		g_free (dtstart.value);
		dtstart.value = &itt;
		e_cal_component_set_dtstart (ci->comp, &dtstart);

		/* set the RECUR-ID for the instance */
		range = g_new0 (ECalComponentRange, 1);
		range->type = E_CAL_COMPONENT_RANGE_SINGLE;
		range->datetime = dtstart;

		e_cal_component_set_recurid (ci->comp, range);

		g_free (range);
		g_free ((gchar *) dtstart.tzid);

		/* Update DTEND */
		dtend.value = NULL;
		dtend.tzid = NULL;

		e_cal_component_get_dtend (comp, &dtend);

		if (instances_hold->end_zone) {
			itt = icaltime_from_timet_with_zone (
				end, dtend.value && dtend.value->is_date,
				instances_hold->end_zone);
			g_free ((gchar *) dtend.tzid);
			dtend.tzid = g_strdup (icaltimezone_get_tzid (
				instances_hold->end_zone));
		} else if (dtend.value && dtend.value->is_date && !dtend.tzid && instances_hold->default_zone) {
			/* Floating date, set in the default zone */
			itt = icaltime_from_timet_with_zone (end, TRUE, instances_hold->default_zone);
		} else {
			itt = icaltime_from_timet_with_zone (end, dtend.value && dtend.value->is_date, NULL);
			if (dtend.tzid) {
				g_free ((gchar *) dtend.tzid);
				dtend.tzid = NULL;
			}
		}

		g_free (dtend.value);
		dtend.value = &itt;
		e_cal_component_set_dtend (ci->comp, &dtend);

		g_free ((gchar *) dtend.tzid);
	}

	ci->start = start;
	ci->end = end;

	*list = g_slist_prepend (*list, ci);

	return TRUE;
}

/* Used from g_slist_sort(); compares two struct comp_instance structures */
static gint
compare_comp_instance (gconstpointer a,
                       gconstpointer b)
{
	const struct comp_instance *cia, *cib;
	time_t diff;

	cia = a;
	cib = b;

	diff = cia->start - cib->start;
	return (diff < 0) ? -1 : (diff > 0) ? 1 : 0;
}

static time_t
convert_to_tt_with_zone (const ECalComponentDateTime *dt,
			 ECalRecurResolveTimezoneFn tz_cb,
			 gpointer tz_cb_data,
			 icaltimezone *default_timezone)
{
	icaltimezone *zone = default_timezone;

	if (!dt || !dt->value)
		return (time_t) 0;

	if (icaltime_is_utc (*dt->value)) {
		zone = icaltimezone_get_utc_timezone ();
	} else if (tz_cb && !dt->value->is_date && dt->tzid) {
		zone = (*tz_cb) (dt->tzid, tz_cb_data);

		if (!zone)
			zone = default_timezone;
	}

	return icaltime_as_timet_with_zone (*dt->value, zone);
}

static GSList *
process_detached_instances (GSList *instances,
			    GSList *detached_instances,
			    ECalRecurResolveTimezoneFn tz_cb,
			    gpointer tz_cb_data,
			    icaltimezone *default_timezone)
{
	struct comp_instance *ci, *cid;
	GSList *dl, *unprocessed_instances = NULL;

	for (dl = detached_instances; dl != NULL; dl = dl->next) {
		GSList *il;
		const gchar *uid;
		gboolean processed;
		ECalComponentRange recur_id;
		time_t d_rid, i_rid;

		processed = FALSE;
		recur_id.type = E_CAL_COMPONENT_RANGE_SINGLE;
		recur_id.datetime.value = NULL;

		cid = dl->data;
		e_cal_component_get_uid (cid->comp, &uid);
		e_cal_component_get_recurid (cid->comp, &recur_id);

		if (!recur_id.datetime.value)
			continue;

		d_rid = convert_to_tt_with_zone (&recur_id.datetime, tz_cb, tz_cb_data, default_timezone);

		/* search for coincident instances already expanded */
		for (il = instances; il != NULL; il = il->next) {
			const gchar *instance_uid;
			gint cmp;

			ci = il->data;
			e_cal_component_get_uid (ci->comp, &instance_uid);

			if (strcmp (uid, instance_uid) == 0) {
				ECalComponentRange instance_recur_id;

				instance_recur_id.type = E_CAL_COMPONENT_RANGE_SINGLE;
				instance_recur_id.datetime.value = NULL;

				e_cal_component_get_recurid (ci->comp, &instance_recur_id);

				if (!instance_recur_id.datetime.value) {
					/*
					 * Prevent obvious segfault by ignoring missing
					 * recurrency ids. Real problem might be elsewhere,
					 * but anything is better than crashing...
					 */
					g_warning ("UID %s: instance RECURRENCE-ID and detached instance RECURRENCE-ID cannot compare", uid);

					e_cal_component_free_range (&instance_recur_id);
					continue;
				}

				i_rid = convert_to_tt_with_zone (&instance_recur_id.datetime, tz_cb, tz_cb_data, default_timezone);

				if (recur_id.type == E_CAL_COMPONENT_RANGE_SINGLE && i_rid == d_rid) {
					g_object_unref (ci->comp);
					ci->comp = g_object_ref (cid->comp);
					ci->start = cid->start;
					ci->end = cid->end;

					processed = TRUE;
				} else {
					cmp = i_rid == d_rid ? 0 : i_rid < d_rid ? -1 : 1;
					if ((recur_id.type == E_CAL_COMPONENT_RANGE_THISPRIOR && cmp <= 0) ||
						(recur_id.type == E_CAL_COMPONENT_RANGE_THISFUTURE && cmp >= 0)) {
						ECalComponent *comp;

						comp = e_cal_component_new ();
						e_cal_component_set_icalcomponent (
							comp,
							icalcomponent_new_clone (e_cal_component_get_icalcomponent (cid->comp)));
						e_cal_component_set_recurid (comp, &instance_recur_id);

						/* replace the generated instances */
						g_object_unref (ci->comp);
						ci->comp = comp;
					}
				}

				e_cal_component_free_range (&instance_recur_id);
			}
		}

		e_cal_component_free_datetime (&recur_id.datetime);

		if (!processed)
			unprocessed_instances = g_slist_prepend (unprocessed_instances, cid);
	}

	/* add the unprocessed instances
	 * (ie, detached instances with no master object) */
	while (unprocessed_instances != NULL) {
		cid = unprocessed_instances->data;
		ci = g_new0 (struct comp_instance, 1);
		ci->comp = g_object_ref (cid->comp);
		ci->start = cid->start;
		ci->end = cid->end;
		instances = g_slist_append (instances, ci);

		unprocessed_instances = g_slist_remove (unprocessed_instances, cid);
	}

	return instances;
}

static void
generate_instances (ECalClient *client,
                    time_t start,
                    time_t end,
                    GSList *objects,
                    GCancellable *cancellable,
                    ECalRecurInstanceFn cb,
                    gpointer cb_data)
{
	GSList *instances, *detached_instances = NULL;
	GSList *l;
	ECalClientPrivate *priv;
	icaltimezone *default_zone;

	priv = client->priv;

	instances = NULL;

	if (priv->default_zone)
		default_zone = priv->default_zone;
	else
		default_zone = icaltimezone_get_utc_timezone ();

	for (l = objects; l && !g_cancellable_is_cancelled (cancellable); l = l->next) {
		ECalComponent *comp;

		comp = l->data;
		if (e_cal_component_is_instance (comp)) {
			struct comp_instance *ci;
			ECalComponentDateTime dtstart, dtend;
			icaltimezone *start_zone = NULL, *end_zone = NULL;

			/* keep the detached instances apart */
			ci = g_new0 (struct comp_instance, 1);
			ci->comp = g_object_ref (comp);

			e_cal_component_get_dtstart (comp, &dtstart);
			e_cal_component_get_dtend (comp, &dtend);

			/* For DATE-TIME values with a TZID, we use
			 * e_cal_resolve_tzid_cb to resolve the TZID.
			 * For DATE values and DATE-TIME values without a
			 * TZID (i.e. floating times) we use the default
			 * timezone. */
			if (dtstart.tzid && dtstart.value && !dtstart.value->is_date) {
				start_zone = e_cal_client_resolve_tzid_cb (
					dtstart.tzid, client);
				if (!start_zone)
					start_zone = default_zone;
			} else {
				start_zone = default_zone;
			}

			if (dtend.tzid && dtend.value && !dtend.value->is_date) {
				end_zone = e_cal_client_resolve_tzid_cb (
					dtend.tzid, client);
				if (!end_zone)
					end_zone = default_zone;
			} else {
				end_zone = default_zone;
			}

			if (!dtstart.value) {
				g_warn_if_reached ();

				e_cal_component_free_datetime (&dtstart);
				e_cal_component_free_datetime (&dtend);
				g_object_unref (G_OBJECT (ci->comp));
				g_free (ci);

				continue;
			}

			if (dtstart.value) {
				ci->start = icaltime_as_timet_with_zone (
					*dtstart.value, start_zone);
			}

			if (dtend.value)
				ci->end = icaltime_as_timet_with_zone (
					*dtend.value, end_zone);
			else if (dtstart.value && icaltime_is_date (*dtstart.value))
				ci->end = time_day_end (ci->start);
			else
				ci->end = ci->start;

			e_cal_component_free_datetime (&dtstart);
			e_cal_component_free_datetime (&dtend);

			if (ci->start <= end && ci->end >= start) {
				detached_instances = g_slist_prepend (
					detached_instances, ci);
			} else {
				/* it doesn't fit to our time range, thus skip it */
				g_object_unref (G_OBJECT (ci->comp));
				g_free (ci);
			}
		} else {
			ECalComponentDateTime datetime;
			icaltimezone *start_zone = NULL, *end_zone = NULL;
			struct instances_info *instances_hold;

			/* Get the start timezone */
			e_cal_component_get_dtstart (comp, &datetime);
			if (datetime.tzid)
				e_cal_client_get_timezone_sync (
					client, datetime.tzid,
					&start_zone, cancellable, NULL);
			else
				start_zone = NULL;
			e_cal_component_free_datetime (&datetime);

			/* Get the end timezone */
			e_cal_component_get_dtend (comp, &datetime);
			if (datetime.tzid)
				e_cal_client_get_timezone_sync (
					client, datetime.tzid,
					&end_zone, cancellable, NULL);
			else
				end_zone = NULL;
			e_cal_component_free_datetime (&datetime);

			instances_hold = g_new0 (struct instances_info, 1);
			instances_hold->instances = &instances;
			instances_hold->start_zone = start_zone;
			instances_hold->end_zone = end_zone;
			instances_hold->default_zone = default_zone;

			e_cal_recur_generate_instances (
				comp, start, end, add_instance, instances_hold,
				e_cal_client_resolve_tzid_cb, client,
				default_zone);

			g_free (instances_hold);
		}
	}

	g_slist_foreach (objects, (GFunc) g_object_unref, NULL);
	g_slist_free (objects);

	/* Generate instances and spew them out */

	if (!g_cancellable_is_cancelled (cancellable)) {
		instances = g_slist_sort (instances, compare_comp_instance);
		instances = process_detached_instances (instances, detached_instances,
			e_cal_client_resolve_tzid_cb, client, default_zone);
	}

	for (l = instances; l && !g_cancellable_is_cancelled (cancellable); l = l->next) {
		struct comp_instance *ci;
		gboolean result;

		ci = l->data;

		result = (* cb) (ci->comp, ci->start, ci->end, cb_data);

		if (!result)
			break;
	}

	/* Clean up */

	for (l = instances; l; l = l->next) {
		struct comp_instance *ci;

		ci = l->data;
		g_object_unref (G_OBJECT (ci->comp));
		g_free (ci);
	}

	g_slist_free (instances);

	for (l = detached_instances; l; l = l->next) {
		struct comp_instance *ci;

		ci = l->data;
		g_object_unref (G_OBJECT (ci->comp));
		g_free (ci);
	}

	g_slist_free (detached_instances);
}

static GSList *
get_objects_sync (ECalClient *client,
                  time_t start,
                  time_t end,
                  const gchar *uid)
{
	GSList *objects = NULL;

	/* Generate objects */
	if (uid && *uid) {
		GError *local_error = NULL;

		e_cal_client_get_objects_for_uid_sync (
			client, uid, &objects, NULL, &local_error);

		if (local_error != NULL) {
			g_warning (
				"Failed to get recurrence objects "
				"for uid: %s\n", local_error->message);
			g_error_free (local_error);
			return NULL;
		}
	} else {
		gchar *iso_start, *iso_end;
		gchar *query;

		iso_start = isodate_from_time_t (start);
		if (!iso_start)
			return NULL;

		iso_end = isodate_from_time_t (end);
		if (!iso_end) {
			g_free (iso_start);
			return NULL;
		}

		query = g_strdup_printf (
			"(occur-in-time-range? "
			"(make-time \"%s\") (make-time \"%s\"))",
			iso_start, iso_end);
		g_free (iso_start);
		g_free (iso_end);
		if (!e_cal_client_get_object_list_as_comps_sync (
			client, query, &objects, NULL, NULL)) {
			g_free (query);
			return NULL;
		}
		g_free (query);
	}

	return objects;
}

struct get_objects_async_data {
	GCancellable *cancellable;
	ECalClient *client;
	time_t start;
	time_t end;
	ECalRecurInstanceFn cb;
	gpointer cb_data;
	GDestroyNotify destroy_cb_data;
	gchar *uid;
	gchar *query;
	guint tries;
	void (* ready_cb) (struct get_objects_async_data *goad, GSList *objects);
	icaltimezone *start_zone;
	icaltimezone *end_zone;
	ECalComponent *comp;
};

static void
free_get_objects_async_data (struct get_objects_async_data *goad)
{
	if (!goad)
		return;

	if (goad->cancellable)
		g_object_unref (goad->cancellable);
	if (goad->destroy_cb_data)
		goad->destroy_cb_data (goad->cb_data);
	if (goad->client)
		g_object_unref (goad->client);
	if (goad->comp)
		g_object_unref (goad->comp);
	g_free (goad->query);
	g_free (goad->uid);
	g_free (goad);
}

static void
got_objects_for_uid_cb (GObject *source_object,
                        GAsyncResult *result,
                        gpointer user_data)
{
	struct get_objects_async_data *goad = user_data;
	GSList *objects = NULL;
	GError *local_error = NULL;

	g_return_if_fail (source_object != NULL);
	g_return_if_fail (result != NULL);
	g_return_if_fail (goad != NULL);
	g_return_if_fail (goad->client == E_CAL_CLIENT (source_object));

	e_cal_client_get_objects_for_uid_finish (
		goad->client, result, &objects, &local_error);

	if (local_error != NULL) {
		if (g_error_matches (local_error, E_CLIENT_ERROR, E_CLIENT_ERROR_CANCELLED) ||
		    g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
			free_get_objects_async_data (goad);
			g_error_free (local_error);
			return;
		}

		g_clear_error (&local_error);
		objects = NULL;
	}

	g_return_if_fail (goad->ready_cb != NULL);

	/* takes care of the objects and goad */
	goad->ready_cb (goad, objects);
}

static void
got_object_list_as_comps_cb (GObject *source_object,
                             GAsyncResult *result,
                             gpointer user_data)
{
	struct get_objects_async_data *goad = user_data;
	GSList *objects = NULL;
	GError *local_error = NULL;

	g_return_if_fail (source_object != NULL);
	g_return_if_fail (result != NULL);
	g_return_if_fail (goad != NULL);
	g_return_if_fail (goad->client == E_CAL_CLIENT (source_object));

	e_cal_client_get_object_list_as_comps_finish (
		goad->client, result, &objects, &local_error);

	if (local_error != NULL) {
		if (g_error_matches (local_error, E_CLIENT_ERROR, E_CLIENT_ERROR_CANCELLED) ||
		    g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
			free_get_objects_async_data (goad);
			g_error_free (local_error);
			return;
		}

		g_clear_error (&local_error);
		objects = NULL;
	}

	g_return_if_fail (goad->ready_cb != NULL);

	/* takes care of the objects and goad */
	goad->ready_cb (goad, objects);
}

/* ready_cb may take care of both arguments, goad and objects;
 * objects can be also NULL */
static void
get_objects_async (void (*ready_cb) (struct get_objects_async_data *goad,
                                     GSList *objects),
                   struct get_objects_async_data *goad)
{
	g_return_if_fail (ready_cb != NULL);
	g_return_if_fail (goad != NULL);

	goad->ready_cb = ready_cb;

	if (goad->uid && *goad->uid) {
		e_cal_client_get_objects_for_uid (
			goad->client, goad->uid, goad->cancellable,
			got_objects_for_uid_cb, goad);
	} else {
		gchar *iso_start, *iso_end;

		iso_start = isodate_from_time_t (goad->start);
		if (!iso_start) {
			free_get_objects_async_data (goad);
			return;
		}

		iso_end = isodate_from_time_t (goad->end);
		if (!iso_end) {
			g_free (iso_start);
			free_get_objects_async_data (goad);
			return;
		}

		goad->query = g_strdup_printf (
			"(occur-in-time-range? "
			"(make-time \"%s\") (make-time \"%s\"))",
			iso_start, iso_end);

		g_free (iso_start);
		g_free (iso_end);

		e_cal_client_get_object_list_as_comps (
			goad->client, goad->query, goad->cancellable,
			got_object_list_as_comps_cb, goad);
	}
}

static void
generate_instances_got_objects_cb (struct get_objects_async_data *goad,
                                   GSList *objects)
{
	g_return_if_fail (goad != NULL);

	/* generate_instaces () frees 'objects' slist */
	if (objects)
		generate_instances (
			goad->client, goad->start, goad->end, objects,
			goad->cancellable, goad->cb, goad->cb_data);

	free_get_objects_async_data (goad);
}

/**
 * e_cal_client_generate_instances:
 * @client: A calendar client.
 * @start: Start time for query.
 * @end: End time for query.
 * @cancellable: a #GCancellable; can be %NULL
 * @cb: Callback for each generated instance.
 * @cb_data: Closure data for the callback.
 * @destroy_cb_data: Function to call when the processing is done, to free
 *                   @cb_data; can be %NULL.
 *
 * Does a combination of e_cal_client_get_object_list() and
 * e_cal_recur_generate_instances(). Unlike
 * e_cal_client_generate_instances_sync(), this returns immediately and the
 * @cb callback is called asynchronously.
 *
 * The callback function should do a g_object_ref() of the calendar component
 * it gets passed if it intends to keep it around, since it will be unref'ed
 * as soon as the callback returns.
 *
 * Since: 3.2
 **/
void
e_cal_client_generate_instances (ECalClient *client,
                                 time_t start,
                                 time_t end,
                                 GCancellable *cancellable,
                                 ECalRecurInstanceFn cb,
                                 gpointer cb_data,
                                 GDestroyNotify destroy_cb_data)
{
	struct get_objects_async_data *goad;
	GCancellable *use_cancellable;

	g_return_if_fail (E_IS_CAL_CLIENT (client));

	g_return_if_fail (start >= 0);
	g_return_if_fail (end >= 0);
	g_return_if_fail (cb != NULL);

	use_cancellable = cancellable;
	if (!use_cancellable)
		use_cancellable = g_cancellable_new ();

	goad = g_new0 (struct get_objects_async_data, 1);
	goad->cancellable = g_object_ref (use_cancellable);
	goad->client = g_object_ref (client);
	goad->start = start;
	goad->end = end;
	goad->cb = cb;
	goad->cb_data = cb_data;
	goad->destroy_cb_data = destroy_cb_data;

	get_objects_async (generate_instances_got_objects_cb, goad);

	if (use_cancellable != cancellable)
		g_object_unref (use_cancellable);
}

/**
 * e_cal_client_generate_instances_sync:
 * @client: A calendar client
 * @start: Start time for query
 * @end: End time for query
 * @cb: (closure cb_data) (scope call): Callback for each generated instance
 * @cb_data: (closure): Closure data for the callback
 *
 * Does a combination of e_cal_client_get_object_list() and
 * e_cal_recur_generate_instances().
 *
 * The callback function should do a g_object_ref() of the calendar component
 * it gets passed if it intends to keep it around, since it will be unreffed
 * as soon as the callback returns.
 *
 * Since: 3.2
 **/
void
e_cal_client_generate_instances_sync (ECalClient *client,
                                      time_t start,
                                      time_t end,
                                      ECalRecurInstanceFn cb,
                                      gpointer cb_data)
{
	GSList *objects = NULL;

	g_return_if_fail (E_IS_CAL_CLIENT (client));

	g_return_if_fail (start >= 0);
	g_return_if_fail (end >= 0);
	g_return_if_fail (cb != NULL);

	objects = get_objects_sync (client, start, end, NULL);
	if (!objects)
		return;

	/* generate_instaces frees 'objects' slist */
	generate_instances (client, start, end, objects, NULL, cb, cb_data);
}

/* also frees 'instances' GSList */
static void
process_instances (ECalComponent *comp,
                   GSList *instances,
                   ECalRecurInstanceFn cb,
                   gpointer cb_data)
{
	gchar *rid;
	gboolean result;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (cb != NULL);

	rid = e_cal_component_get_recurid_as_string (comp);

	/* Reverse the instances list because the add_instance() function
	 * is prepending. */
	instances = g_slist_reverse (instances);

	/* now only return back the instances for the given object */
	result = TRUE;
	while (instances != NULL) {
		struct comp_instance *ci;
		gchar *instance_rid = NULL;

		ci = instances->data;

		if (result) {
			instance_rid = e_cal_component_get_recurid_as_string (ci->comp);

			if (rid && *rid) {
				if (instance_rid && *instance_rid && strcmp (rid, instance_rid) == 0)
					result = (* cb) (ci->comp, ci->start, ci->end, cb_data);
			} else
				result = (* cb) (ci->comp, ci->start, ci->end, cb_data);
		}

		/* remove instance from list */
		instances = g_slist_remove (instances, ci);
		g_object_unref (ci->comp);
		g_free (ci);
		g_free (instance_rid);
	}

	/* clean up */
	g_free (rid);
}

static void
generate_instances_for_object_got_objects_cb (struct get_objects_async_data *goad,
                                              GSList *objects)
{
	struct instances_info *instances_hold;
	GSList *instances = NULL;

	g_return_if_fail (goad != NULL);

	instances_hold = g_new0 (struct instances_info, 1);
	instances_hold->instances = &instances;
	instances_hold->start_zone = goad->start_zone;
	instances_hold->end_zone = goad->end_zone;
	instances_hold->default_zone = e_cal_client_get_default_timezone (goad->client);

	/* generate all instances in the given time range */
	generate_instances (
		goad->client, goad->start, goad->end, objects,
		goad->cancellable, add_instance, instances_hold);

	/* it also frees 'instances' GSList */
	process_instances (
		goad->comp, *(instances_hold->instances),
		goad->cb, goad->cb_data);

	/* clean up */
	free_get_objects_async_data (goad);
	g_free (instances_hold);
}

/**
 * e_cal_client_generate_instances_for_object:
 * @client: A calendar client.
 * @icalcomp: Object to generate instances from.
 * @start: Start time for query.
 * @end: End time for query.
 * @cancellable: a #GCancellable; can be %NULL
 * @cb: Callback for each generated instance.
 * @cb_data: Closure data for the callback.
 * @destroy_cb_data: Function to call when the processing is done, to
 *                   free @cb_data; can be %NULL.
 *
 * Does a combination of e_cal_client_get_object_list() and
 * e_cal_recur_generate_instances(), like
 * e_cal_client_generate_instances(), but for a single object. Unlike
 * e_cal_client_generate_instances_for_object_sync(), this returns immediately
 * and the @cb callback is called asynchronously.
 *
 * The callback function should do a g_object_ref() of the calendar component
 * it gets passed if it intends to keep it around, since it will be unref'ed
 * as soon as the callback returns.
 *
 * Since: 3.2
 **/
void
e_cal_client_generate_instances_for_object (ECalClient *client,
                                            icalcomponent *icalcomp,
                                            time_t start,
                                            time_t end,
                                            GCancellable *cancellable,
                                            ECalRecurInstanceFn cb,
                                            gpointer cb_data,
                                            GDestroyNotify destroy_cb_data)
{
	ECalComponent *comp;
	const gchar *uid;
	ECalComponentDateTime datetime;
	icaltimezone *start_zone = NULL, *end_zone = NULL;
	gboolean is_single_instance = FALSE;
	struct get_objects_async_data *goad;
	GCancellable *use_cancellable;

	g_return_if_fail (E_IS_CAL_CLIENT (client));

	g_return_if_fail (start >= 0);
	g_return_if_fail (end >= 0);
	g_return_if_fail (cb != NULL);

	comp = e_cal_component_new ();
	e_cal_component_set_icalcomponent (comp, icalcomponent_new_clone (icalcomp));

	if (!e_cal_component_has_recurrences (comp))
		is_single_instance = TRUE;

	/* If the backend stores it as individual instances and does not
	 * have a master object - do not expand */
	if (is_single_instance || e_client_check_capability (E_CLIENT (client), CAL_STATIC_CAPABILITY_RECURRENCES_NO_MASTER)) {
		/* return the same instance */
		(* cb)  (comp,
			icaltime_as_timet_with_zone (
				icalcomponent_get_dtstart (icalcomp),
				client->priv->default_zone),
			icaltime_as_timet_with_zone (
				icalcomponent_get_dtend (icalcomp),
				client->priv->default_zone),
			cb_data);
		g_object_unref (comp);

		if (destroy_cb_data)
			destroy_cb_data (cb_data);
		return;
	}

	e_cal_component_get_uid (comp, &uid);

	/* Get the start timezone */
	e_cal_component_get_dtstart (comp, &datetime);
	if (datetime.tzid)
		e_cal_client_get_timezone_sync (
			client, datetime.tzid, &start_zone, NULL, NULL);
	else
		start_zone = NULL;
	e_cal_component_free_datetime (&datetime);

	/* Get the end timezone */
	e_cal_component_get_dtend (comp, &datetime);
	if (datetime.tzid)
		e_cal_client_get_timezone_sync (
			client, datetime.tzid, &end_zone, NULL, NULL);
	else
		end_zone = NULL;
	e_cal_component_free_datetime (&datetime);

	use_cancellable = cancellable;
	if (!use_cancellable)
		use_cancellable = g_cancellable_new ();

	goad = g_new0 (struct get_objects_async_data, 1);
	goad->cancellable = g_object_ref (use_cancellable);
	goad->client = g_object_ref (client);
	goad->start = start;
	goad->end = end;
	goad->cb = cb;
	goad->cb_data = cb_data;
	goad->destroy_cb_data = destroy_cb_data;
	goad->start_zone = start_zone;
	goad->end_zone = end_zone;
	goad->comp = comp;
	goad->uid = g_strdup (uid);

	get_objects_async (generate_instances_for_object_got_objects_cb, goad);

	if (use_cancellable != cancellable)
		g_object_unref (use_cancellable);
}

/**
 * e_cal_client_generate_instances_for_object_sync:
 * @client: A calendar client
 * @icalcomp: Object to generate instances from
 * @start: Start time for query
 * @end: End time for query
 * @cb: (closure cb_data) (scope call): Callback for each generated instance
 * @cb_data: (closure): Closure data for the callback
 *
 * Does a combination of e_cal_client_get_object_list() and
 * e_cal_recur_generate_instances(), like
 * e_cal_client_generate_instances_sync(), but for a single object.
 *
 * The callback function should do a g_object_ref() of the calendar component
 * it gets passed if it intends to keep it around, since it will be unref'ed
 * as soon as the callback returns.
 *
 * Since: 3.2
 **/
void
e_cal_client_generate_instances_for_object_sync (ECalClient *client,
                                                 icalcomponent *icalcomp,
                                                 time_t start,
                                                 time_t end,
                                                 ECalRecurInstanceFn cb,
                                                 gpointer cb_data)
{
	ECalComponent *comp;
	const gchar *uid;
	GSList *instances = NULL;
	ECalComponentDateTime datetime;
	icaltimezone *start_zone = NULL, *end_zone = NULL;
	struct instances_info *instances_hold;
	gboolean is_single_instance = FALSE;

	g_return_if_fail (E_IS_CAL_CLIENT (client));

	g_return_if_fail (start >= 0);
	g_return_if_fail (end >= 0);
	g_return_if_fail (cb != NULL);

	comp = e_cal_component_new ();
	e_cal_component_set_icalcomponent (comp, icalcomponent_new_clone (icalcomp));

	if (!e_cal_component_has_recurrences (comp))
		is_single_instance = TRUE;

	/* If the backend stores it as individual instances and does not
	 * have a master object - do not expand */
	if (is_single_instance || e_client_check_capability (E_CLIENT (client), CAL_STATIC_CAPABILITY_RECURRENCES_NO_MASTER)) {
		/* return the same instance */
		(* cb)  (comp,
			icaltime_as_timet_with_zone (
				icalcomponent_get_dtstart (icalcomp),
				client->priv->default_zone),
			icaltime_as_timet_with_zone (
				icalcomponent_get_dtend (icalcomp),
				client->priv->default_zone),
			cb_data);
		g_object_unref (comp);
		return;
	}

	e_cal_component_get_uid (comp, &uid);

	/* Get the start timezone */
	e_cal_component_get_dtstart (comp, &datetime);
	if (datetime.tzid)
		e_cal_client_get_timezone_sync (
			client, datetime.tzid, &start_zone, NULL, NULL);
	else
		start_zone = NULL;
	e_cal_component_free_datetime (&datetime);

	/* Get the end timezone */
	e_cal_component_get_dtend (comp, &datetime);
	if (datetime.tzid)
		e_cal_client_get_timezone_sync (
			client, datetime.tzid, &end_zone, NULL, NULL);
	else
		end_zone = NULL;
	e_cal_component_free_datetime (&datetime);

	instances_hold = g_new0 (struct instances_info, 1);
	instances_hold->instances = &instances;
	instances_hold->start_zone = start_zone;
	instances_hold->end_zone = end_zone;
	instances_hold->default_zone = e_cal_client_get_default_timezone (client);

	/* generate all instances in the given time range */
	generate_instances (
		client, start, end,
		get_objects_sync (client, start, end, uid),
		NULL, add_instance, instances_hold);

	/* it also frees 'instances' GSList */
	process_instances (comp, *(instances_hold->instances), cb, cb_data);

	/* clean up */
	g_object_unref (comp);
	g_free (instances_hold);
}

typedef struct _ForeachTZIDCallbackData ForeachTZIDCallbackData;
struct _ForeachTZIDCallbackData {
	ECalClient *client;
	GHashTable *timezone_hash;
	gboolean success;
};

/* This adds the VTIMEZONE given by the TZID parameter to the GHashTable in
 * data. */
static void
foreach_tzid_callback (icalparameter *param,
                       gpointer cbdata)
{
	ForeachTZIDCallbackData *data = cbdata;
	const gchar *tzid;
	icaltimezone *zone = NULL;
	icalcomponent *vtimezone_comp;
	gchar *vtimezone_as_string;

	/* Get the TZID string from the parameter. */
	tzid = icalparameter_get_tzid (param);
	if (!tzid)
		return;

	/* Check if we've already added it to the GHashTable. */
	if (g_hash_table_lookup (data->timezone_hash, tzid))
		return;

	if (!e_cal_client_get_timezone_sync (data->client, tzid, &zone, NULL, NULL) || !zone) {
		data->success = FALSE;
		return;
	}

	/* Convert it to a string and add it to the hash. */
	vtimezone_comp = icaltimezone_get_component (zone);
	if (!vtimezone_comp)
		return;

	vtimezone_as_string = icalcomponent_as_ical_string_r (vtimezone_comp);

	g_hash_table_insert (data->timezone_hash, (gchar *) tzid, vtimezone_as_string);
}

/* This appends the value string to the GString given in data. */
static void
append_timezone_string (gpointer key,
                        gpointer value,
                        gpointer data)
{
	GString *vcal_string = data;

	g_string_append (vcal_string, value);
	g_free (value);
}

/* This simply frees the hash values. */
static void
free_timezone_string (gpointer key,
                      gpointer value,
                      gpointer data)
{
	g_free (value);
}

/**
 * e_cal_client_get_component_as_string:
 * @client: A calendar client.
 * @icalcomp: A calendar component object.
 *
 * Gets a calendar component as an iCalendar string, with a toplevel
 * VCALENDAR component and all VTIMEZONEs needed for the component.
 *
 * Returns: the component as a complete iCalendar string, or NULL on
 * failure. The string should be freed with g_free().
 *
 * Since: 3.2
 **/
gchar *
e_cal_client_get_component_as_string (ECalClient *client,
                                      icalcomponent *icalcomp)
{
	GHashTable *timezone_hash;
	GString *vcal_string;
	ForeachTZIDCallbackData cbdata;
	gchar *obj_string;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), NULL);
	g_return_val_if_fail (icalcomp != NULL, NULL);

	timezone_hash = g_hash_table_new (g_str_hash, g_str_equal);

	/* Add any timezones needed to the hash. We use a hash since we only
	 * want to add each timezone once at most. */
	cbdata.client = client;
	cbdata.timezone_hash = timezone_hash;
	cbdata.success = TRUE;
	icalcomponent_foreach_tzid (icalcomp, foreach_tzid_callback, &cbdata);
	if (!cbdata.success) {
		g_hash_table_foreach (timezone_hash, free_timezone_string, NULL);
		return NULL;
	}

	/* Create the start of a VCALENDAR, to add the VTIMEZONES to,
	 * and remember its length so we know if any VTIMEZONEs get added. */
	vcal_string = g_string_new (NULL);
	g_string_append (
		vcal_string,
		"BEGIN:VCALENDAR\r\n"
		"PRODID:-//Ximian//NONSGML Evolution Calendar//EN\r\n"
		"VERSION:2.0\r\n"
		"METHOD:PUBLISH\r\n");

	/* Now concatenate all the timezone strings. This also frees the
	 * timezone strings as it goes. */
	g_hash_table_foreach (timezone_hash, append_timezone_string, vcal_string);

	/* Get the string for the VEVENT/VTODO. */
	obj_string = icalcomponent_as_ical_string_r (icalcomp);

	/* If there were any timezones to send, create a complete VCALENDAR,
	 * else just send the VEVENT/VTODO string. */
	g_string_append (vcal_string, obj_string);
	g_string_append (vcal_string, "END:VCALENDAR\r\n");
	g_free (obj_string);

	obj_string = g_string_free (vcal_string, FALSE);

	g_hash_table_destroy (timezone_hash);

	return obj_string;
}

/* Helper for e_cal_client_get_default_object() */
static void
cal_client_get_default_object_thread (GSimpleAsyncResult *simple,
                                      GObject *source_object,
                                      GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_get_default_object_sync (
		E_CAL_CLIENT (source_object),
		&async_context->out_comp,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_get_default_object:
 * @client: an #ECalClient
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Retrives an #icalcomponent from the backend that contains the default
 * values for properties needed. The call is finished
 * by e_cal_client_get_default_object_finish() from the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_get_default_object (ECalClient *client,
                                 GCancellable *cancellable,
                                 GAsyncReadyCallback callback,
                                 gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));

	async_context = g_slice_new0 (AsyncContext);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_get_default_object);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_get_default_object_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_get_default_object_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_icalcomp: (out): Return value for the default calendar object.
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_get_default_object() and
 * sets @out_icalcomp to an #icalcomponent from the backend that contains
 * the default values for properties needed. This @out_icalcomp should be
 * freed with icalcomponent_free().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_default_object_finish (ECalClient *client,
                                        GAsyncResult *result,
                                        icalcomponent **out_icalcomp,
                                        GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_get_default_object), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->out_comp != NULL, FALSE);

	if (out_icalcomp != NULL) {
		*out_icalcomp = async_context->out_comp;
		async_context->out_comp = NULL;
	}

	return TRUE;
}

/**
 * e_cal_client_get_default_object_sync:
 * @client: an #ECalClient
 * @out_icalcomp: (out): Return value for the default calendar object.
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Retrives an #icalcomponent from the backend that contains the default
 * values for properties needed. This @out_icalcomp should be freed with
 * icalcomponent_free().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_default_object_sync (ECalClient *client,
                                      icalcomponent **out_icalcomp,
                                      GCancellable *cancellable,
                                      GError **error)
{
	icalcomponent *icalcomp = NULL;
	gchar *string;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (out_icalcomp != NULL, FALSE);

	string = e_dbus_calendar_dup_default_object (client->priv->dbus_proxy);
	if (string != NULL) {
		icalcomp = icalparser_parse_string (string);
		g_free (string);
	}

	if (icalcomp == NULL) {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_INVALID_OBJECT,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_INVALID_OBJECT));
		return FALSE;
	}

	if (icalcomponent_get_uid (icalcomp) != NULL) {
		gchar *new_uid;

		/* Make sure the UID is always unique. */
		new_uid = e_util_generate_uid ();
		icalcomponent_set_uid (icalcomp, new_uid);
		g_free (new_uid);
	}

	*out_icalcomp = icalcomp;

	return TRUE;
}

/* Helper for e_cal_client_get_object() */
static void
cal_client_get_object_thread (GSimpleAsyncResult *simple,
                              GObject *source_object,
                              GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_get_object_sync (
		E_CAL_CLIENT (source_object),
		async_context->uid,
		async_context->rid,
		&async_context->out_comp,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_get_object:
 * @client: an #ECalClient
 * @uid: Unique identifier for a calendar component.
 * @rid: Recurrence identifier.
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Queries a calendar for a calendar component object based on its unique
 * identifier. The call is finished by e_cal_client_get_object_finish()
 * from the @callback.
 *
 * Use e_cal_client_get_objects_for_uid() to get list of all
 * objects for the given uid, which includes master object and
 * all detached instances.
 *
 * Since: 3.2
 **/
void
e_cal_client_get_object (ECalClient *client,
                         const gchar *uid,
                         const gchar *rid,
                         GCancellable *cancellable,
                         GAsyncReadyCallback callback,
                         gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (uid != NULL);
	/* rid is optional */

	async_context = g_slice_new0 (AsyncContext);
	async_context->uid = g_strdup (uid);
	async_context->rid = g_strdup (rid);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_get_object);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_get_object_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_get_object_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_icalcomp: (out): Return value for the calendar component object.
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_get_object() and
 * sets @out_icalcomp to queried component. This function always returns
 * master object for a case of @rid being NULL or an empty string.
 * This component should be freed with icalcomponent_free().
 *
 * Use e_cal_client_get_objects_for_uid() to get list of all
 * objects for the given uid, which includes master object and
 * all detached instances.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_object_finish (ECalClient *client,
                                GAsyncResult *result,
                                icalcomponent **out_icalcomp,
                                GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_get_object), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->out_comp != NULL, FALSE);

	if (out_icalcomp != NULL) {
		*out_icalcomp = async_context->out_comp;
		async_context->out_comp = NULL;
	}

	return TRUE;
}

/**
 * e_cal_client_get_object_sync:
 * @client: an #ECalClient
 * @uid: Unique identifier for a calendar component.
 * @rid: Recurrence identifier.
 * @out_icalcomp: (out): Return value for the calendar component object.
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Queries a calendar for a calendar component object based
 * on its unique identifier. This function always returns
 * master object for a case of @rid being NULL or an empty string.
 * This component should be freed with icalcomponent_free().
 *
 * Use e_cal_client_get_objects_for_uid_sync() to get list of all
 * objects for the given uid, which includes master object and
 * all detached instances.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_object_sync (ECalClient *client,
                              const gchar *uid,
                              const gchar *rid,
                              icalcomponent **out_icalcomp,
                              GCancellable *cancellable,
                              GError **error)
{
	icalcomponent *icalcomp = NULL;
	icalcomponent_kind kind;
	gchar *utf8_uid;
	gchar *utf8_rid;
	gchar *string = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_icalcomp != NULL, FALSE);

	if (rid == NULL)
		rid = "";

	utf8_uid = e_util_utf8_make_valid (uid);
	utf8_rid = e_util_utf8_make_valid (rid);

	e_dbus_calendar_call_get_object_sync (
		client->priv->dbus_proxy, utf8_uid, utf8_rid,
		&string, cancellable, &local_error);

	g_free (utf8_uid);
	g_free (utf8_rid);

	/* Sanity check. */
	g_return_val_if_fail (
		((string != NULL) && (local_error == NULL)) ||
		((string == NULL) && (local_error != NULL)), FALSE);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	icalcomp = icalparser_parse_string (string);

	g_free (string);

	if (icalcomp == NULL) {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_INVALID_OBJECT,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_INVALID_OBJECT));
		return FALSE;
	}

	switch (e_cal_client_get_source_type (client)) {
		case E_CAL_CLIENT_SOURCE_TYPE_EVENTS:
			kind = ICAL_VEVENT_COMPONENT;
			break;
		case E_CAL_CLIENT_SOURCE_TYPE_TASKS:
			kind = ICAL_VTODO_COMPONENT;
			break;
		case E_CAL_CLIENT_SOURCE_TYPE_MEMOS:
			kind = ICAL_VJOURNAL_COMPONENT;
			break;
		default:
			g_warn_if_reached ();
			kind = ICAL_VEVENT_COMPONENT;
			break;
	}

	if (icalcomponent_isa (icalcomp) == kind) {
		*out_icalcomp = icalcomp;

	} else if (icalcomponent_isa (icalcomp) == ICAL_VCALENDAR_COMPONENT) {
		icalcomponent *subcomponent;

		for (subcomponent = icalcomponent_get_first_component (icalcomp, kind);
			subcomponent != NULL;
			subcomponent = icalcomponent_get_next_component (icalcomp, kind)) {
			struct icaltimetype recurrenceid;

			if (icalcomponent_get_uid (subcomponent) == NULL)
				continue;

			recurrenceid =
				icalcomponent_get_recurrenceid (subcomponent);

			if (icaltime_is_null_time (recurrenceid))
				break;

			if (!icaltime_is_valid_time (recurrenceid))
				break;
		}

		if (subcomponent == NULL)
			subcomponent = icalcomponent_get_first_component (icalcomp, kind);
		if (subcomponent != NULL)
			subcomponent = icalcomponent_new_clone (subcomponent);

		/* XXX Shouldn't we set an error is this is still NULL? */
		*out_icalcomp = subcomponent;

		icalcomponent_free (icalcomp);
	}

	return TRUE;
}

/* Helper for e_cal_client_get_objects_for_uid() */
static void
cal_client_get_objects_for_uid_thread (GSimpleAsyncResult *simple,
                                       GObject *source_object,
                                       GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_get_objects_for_uid_sync (
		E_CAL_CLIENT (source_object),
		async_context->uid,
		&async_context->object_list,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_get_objects_for_uid:
 * @client: an #ECalClient
 * @uid: Unique identifier for a calendar component
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Queries a calendar for all calendar components with the given unique
 * ID. This will return any recurring event and all its detached recurrences.
 * For non-recurring events, it will just return the object with that ID.
 * The call is finished by e_cal_client_get_objects_for_uid_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_get_objects_for_uid (ECalClient *client,
                                  const gchar *uid,
                                  GCancellable *cancellable,
                                  GAsyncReadyCallback callback,
                                  gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (uid != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->uid = g_strdup (uid);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_get_objects_for_uid);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_get_objects_for_uid_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_get_objects_for_uid_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_ecalcomps: (out) (transfer full) (element-type ECalComponent):
 *                 Return location for the list of objects obtained from the
 *                 backend
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_get_objects_for_uid() and
 * sets @out_ecalcomps to a list of #ECalComponent<!-- -->s corresponding to
 * found components for a given uid of the same type as this client.
 * This list should be freed with e_cal_client_free_ecalcomp_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_objects_for_uid_finish (ECalClient *client,
                                         GAsyncResult *result,
                                         GSList **out_ecalcomps,
                                         GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_get_objects_for_uid), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	if (out_ecalcomps != NULL) {
		*out_ecalcomps = async_context->object_list;
		async_context->object_list = NULL;
	}

	return TRUE;
}

/**
 * e_cal_client_get_objects_for_uid_sync:
 * @client: an #ECalClient
 * @uid: Unique identifier for a calendar component
 * @out_ecalcomps: (out) (transfer full) (element-type ECalComponent):
 *                 Return location for the list of objects obtained from the
 *                 backend
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Queries a calendar for all calendar components with the given unique
 * ID. This will return any recurring event and all its detached recurrences.
 * For non-recurring events, it will just return the object with that ID.
 * This list should be freed with e_cal_client_free_ecalcomp_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_objects_for_uid_sync (ECalClient *client,
                                       const gchar *uid,
                                       GSList **out_ecalcomps,
                                       GCancellable *cancellable,
                                       GError **error)
{
	icalcomponent *icalcomp;
	icalcomponent_kind kind;
	gchar *utf8_uid;
	gchar *string = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_ecalcomps != NULL, FALSE);

	utf8_uid = e_util_utf8_make_valid (uid);

	e_dbus_calendar_call_get_object_sync (
		client->priv->dbus_proxy, utf8_uid, "",
		&string, cancellable, &local_error);

	g_free (utf8_uid);

	/* Sanity check. */
	g_return_val_if_fail (
		((string != NULL) && (local_error == NULL)) ||
		((string == NULL) && (local_error != NULL)), FALSE);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	icalcomp = icalparser_parse_string (string);

	g_free (string);

	if (icalcomp == NULL) {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_INVALID_OBJECT,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_INVALID_OBJECT));
		return FALSE;
	}

	switch (e_cal_client_get_source_type (client)) {
		case E_CAL_CLIENT_SOURCE_TYPE_EVENTS:
			kind = ICAL_VEVENT_COMPONENT;
			break;
		case E_CAL_CLIENT_SOURCE_TYPE_TASKS:
			kind = ICAL_VTODO_COMPONENT;
			break;
		case E_CAL_CLIENT_SOURCE_TYPE_MEMOS:
			kind = ICAL_VJOURNAL_COMPONENT;
			break;
		default:
			g_warn_if_reached ();
			kind = ICAL_VEVENT_COMPONENT;
			break;
	}

	if (icalcomponent_isa (icalcomp) == kind) {
		ECalComponent *comp;

		comp = e_cal_component_new ();
		e_cal_component_set_icalcomponent (comp, icalcomp);
		*out_ecalcomps = g_slist_append (NULL, comp);

	} else if (icalcomponent_isa (icalcomp) == ICAL_VCALENDAR_COMPONENT) {
		GSList *tmp = NULL;
		icalcomponent *subcomponent;

		subcomponent = icalcomponent_get_first_component (
			icalcomp, kind);

		while (subcomponent != NULL) {
			ECalComponent *comp;
			icalcomponent *clone;

			comp = e_cal_component_new ();
			clone = icalcomponent_new_clone (subcomponent);
			e_cal_component_set_icalcomponent (comp, clone);
			tmp = g_slist_prepend (tmp, comp);

			subcomponent = icalcomponent_get_next_component (
				icalcomp, kind);
		}

		*out_ecalcomps = g_slist_reverse (tmp);

		icalcomponent_free (icalcomp);
	}

	return TRUE;
}

/* Helper for e_cal_client_get_object_list() */
static void
cal_client_get_object_list_thread (GSimpleAsyncResult *simple,
                                   GObject *source_object,
                                   GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_get_object_list_sync (
		E_CAL_CLIENT (source_object),
		async_context->sexp,
		&async_context->comp_list,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_get_object_list:
 * @client: an #ECalClient
 * @sexp: an S-expression representing the query
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Gets a list of objects from the calendar that match the query specified
 * by the @sexp argument, returning matching objects as a list of #icalcomponent-s.
 * The call is finished by e_cal_client_get_object_list_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_get_object_list (ECalClient *client,
                              const gchar *sexp,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (sexp != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->sexp = g_strdup (sexp);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_get_object_list);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_get_object_list_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_get_object_list_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_icalcomps: (out) (element-type icalcomponent): list of matching
 *                 #icalcomponent<!-- -->s
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_get_object_list() and
 * sets @out_icalcomps to a matching list of #icalcomponent-s.
 * This list should be freed with e_cal_client_free_icalcomp_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_object_list_finish (ECalClient *client,
                                     GAsyncResult *result,
                                     GSList **out_icalcomps,
                                     GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_get_object_list), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	if (out_icalcomps != NULL) {
		*out_icalcomps = async_context->comp_list;
		async_context->comp_list = NULL;
	}

	return TRUE;
}

/**
 * e_cal_client_get_object_list_sync:
 * @client: an #ECalClient
 * @sexp: an S-expression representing the query
 * @out_icalcomps: (out) (element-type icalcomponent): list of matching
 *                 #icalcomponent<!-- -->s
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Gets a list of objects from the calendar that match the query specified
 * by the @sexp argument. The objects will be returned in the @out_icalcomps
 * argument, which is a list of #icalcomponent.
 * This list should be freed with e_cal_client_free_icalcomp_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_object_list_sync (ECalClient *client,
                                   const gchar *sexp,
                                   GSList **out_icalcomps,
                                   GCancellable *cancellable,
                                   GError **error)
{
	GSList *tmp = NULL;
	gchar *utf8_sexp;
	gchar **strv = NULL;
	gint ii;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (sexp != NULL, FALSE);
	g_return_val_if_fail (out_icalcomps != NULL, FALSE);

	utf8_sexp = e_util_utf8_make_valid (sexp);

	e_dbus_calendar_call_get_object_list_sync (
		client->priv->dbus_proxy, utf8_sexp,
		&strv, cancellable, &local_error);

	g_free (utf8_sexp);

	/* Sanity check. */
	g_return_val_if_fail (
		((strv != NULL) && (local_error == NULL)) ||
		((strv == NULL) && (local_error != NULL)), FALSE);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	for (ii = 0; strv[ii] != NULL; ii++) {
		icalcomponent *icalcomp;

		icalcomp = icalcomponent_new_from_string (strv[ii]);
		if (icalcomp == NULL)
			continue;

		tmp = g_slist_prepend (tmp, icalcomp);
	}

	*out_icalcomps = g_slist_reverse (tmp);

	g_strfreev (strv);

	return TRUE;
}

/* Helper for e_cal_client_get_object_list_as_comps() */
static void
cal_client_get_object_list_as_comps_thread (GSimpleAsyncResult *simple,
                                            GObject *source_object,
                                            GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_get_object_list_as_comps_sync (
		E_CAL_CLIENT (source_object),
		async_context->sexp,
		&async_context->object_list,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_get_object_list_as_comps:
 * @client: an #ECalClient
 * @sexp: an S-expression representing the query
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Gets a list of objects from the calendar that match the query specified
 * by the @sexp argument, returning matching objects as a list of #ECalComponent-s.
 * The call is finished by e_cal_client_get_object_list_as_comps_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_get_object_list_as_comps (ECalClient *client,
                                       const gchar *sexp,
                                       GCancellable *cancellable,
                                       GAsyncReadyCallback callback,
                                       gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (sexp != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->sexp = g_strdup (sexp);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_get_object_list_as_comps);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_get_object_list_as_comps_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_get_object_list_as_comps_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_ecalcomps: (out) (element-type ECalComponent): list of matching
 *                 #ECalComponent<!-- -->s
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_get_object_list_as_comps() and
 * sets @out_ecalcomps to a matching list of #ECalComponent-s.
 * This list should be freed with e_cal_client_free_ecalcomp_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_object_list_as_comps_finish (ECalClient *client,
                                              GAsyncResult *result,
                                              GSList **out_ecalcomps,
                                              GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_get_object_list_as_comps), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	if (out_ecalcomps != NULL) {
		*out_ecalcomps = async_context->object_list;
		async_context->object_list = NULL;
	}

	return TRUE;
}

/**
 * e_cal_client_get_object_list_as_comps_sync:
 * @client: an #ECalClient
 * @sexp: an S-expression representing the query
 * @out_ecalcomps: (out) (element-type ECalComponent): list of matching
 *                 #ECalComponent<!-- -->s
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Gets a list of objects from the calendar that match the query specified
 * by the @sexp argument. The objects will be returned in the @out_ecalcomps
 * argument, which is a list of #ECalComponent.
 * This list should be freed with e_cal_client_free_ecalcomp_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_object_list_as_comps_sync (ECalClient *client,
                                            const gchar *sexp,
                                            GSList **out_ecalcomps,
                                            GCancellable *cancellable,
                                            GError **error)
{
	GSList *list = NULL;
	GSList *link;
	GQueue trash = G_QUEUE_INIT;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (sexp != NULL, FALSE);
	g_return_val_if_fail (out_ecalcomps != NULL, FALSE);

	success = e_cal_client_get_object_list_sync (
		client, sexp, &list, cancellable, error);

	if (!success) {
		g_warn_if_fail (list == NULL);
		return FALSE;
	}

	/* Convert the icalcomponent list to an ECalComponent list. */
	for (link = list; link != NULL; link = g_slist_next (link)) {
		ECalComponent *comp;
		icalcomponent *icalcomp = link->data;

		comp = e_cal_component_new ();

		/* This takes ownership of the icalcomponent, if it works. */
		if (e_cal_component_set_icalcomponent (comp, icalcomp)) {
			link->data = g_object_ref (comp);
		} else {
			/* On failure, free resources and add
			 * the GSList link to the trash queue. */
			icalcomponent_free (icalcomp);
			g_queue_push_tail (&trash, link);
			link->data = NULL;
		}

		g_object_unref (comp);
	}

	/* Delete GSList links we failed to convert. */
	while ((link = g_queue_pop_head (&trash)) != NULL)
		list = g_slist_delete_link (list, link);

	*out_ecalcomps = list;

	return TRUE;
}

/* Helper for e_cal_client_get_free_busy() */
static void
cal_client_get_free_busy_thread (GSimpleAsyncResult *simple,
                                 GObject *source_object,
                                 GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_get_free_busy_sync (
		E_CAL_CLIENT (source_object),
		async_context->start,
		async_context->end,
		async_context->string_list,
		&async_context->object_list,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_get_free_busy:
 * @client: an #ECalClient
 * @start: Start time for query
 * @end: End time for query
 * @users: (element-type utf8): List of users to retrieve free/busy information for
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Begins retrieval of free/busy information from the calendar server
 * as a list of #ECalComponent-s. Connect to "free-busy-data" signal
 * to receive chunks of free/busy components.
 * The call is finished by e_cal_client_get_free_busy_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_get_free_busy (ECalClient *client,
                            time_t start,
                            time_t end,
                            const GSList *users,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (start > 0);
	g_return_if_fail (end > 0);

	async_context = g_slice_new0 (AsyncContext);
	async_context->start = start;
	async_context->end = end;
	async_context->string_list = g_slist_copy_deep (
		(GSList *) users, (GCopyFunc) g_strdup, NULL);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_get_free_busy);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_get_free_busy_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_get_free_busy_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_freebusy: (element-type ECalComponent): a #GSList of #ECalComponent-s with overall returned Free/Busy data
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_get_free_busy().
 * The @out_freebusy contains all VFREEBUSY #ECalComponent-s, which could be also
 * received by "free-busy-data" signal. The client is responsible to do a merge of
 * the components between this complete list and those received through the signal.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_free_busy_finish (ECalClient *client,
                                   GAsyncResult *result,
				   GSList **out_freebusy,
                                   GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_get_free_busy), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	if (out_freebusy != NULL) {
		AsyncContext *async_context;

		async_context = g_simple_async_result_get_op_res_gpointer (simple);

		*out_freebusy = async_context->object_list;
		async_context->object_list = NULL;
	}

	return TRUE;
}

/**
 * e_cal_client_get_free_busy_sync:
 * @client: an #ECalClient
 * @start: Start time for query
 * @end: End time for query
 * @users: (element-type utf8): List of users to retrieve free/busy information for
 * @out_freebusy: (element-type ECalComponent): a #GSList of #ECalComponent-s with overall returned Free/Busy data
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Gets free/busy information from the calendar server.
 * The @out_freebusy contains all VFREEBUSY #ECalComponent-s, which could be also
 * received by "free-busy-data" signal. The client is responsible to do a merge of
 * the components between this complete list and those received through the signal.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_free_busy_sync (ECalClient *client,
                                 time_t start,
                                 time_t end,
                                 const GSList *users,
				 GSList **out_freebusy,
                                 GCancellable *cancellable,
                                 GError **error)
{
	gchar **strv, **freebusy_strv = NULL;
	gint ii = 0;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (start > 0, FALSE);
	g_return_val_if_fail (end > 0, FALSE);

	strv = g_new0 (gchar *, g_slist_length ((GSList *) users) + 1);
	while (users != NULL) {
		strv[ii++] = e_util_utf8_make_valid (users->data);
		users = g_slist_next (users);
	}

	e_dbus_calendar_call_get_free_busy_sync (
		client->priv->dbus_proxy,
		(gint64) start, (gint64) end,
		(const gchar * const *) strv,
		&freebusy_strv,
		cancellable, &local_error);

	g_strfreev (strv);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	if (out_freebusy) {
		*out_freebusy = NULL;

		for (ii = 0; freebusy_strv && freebusy_strv[ii] != NULL; ii++) {
			ECalComponent *comp;

			comp = e_cal_component_new_from_string (freebusy_strv[ii]);
			if (!comp)
				continue;

			*out_freebusy = g_slist_prepend (*out_freebusy, comp);
		}

		*out_freebusy = g_slist_reverse (*out_freebusy);
	}

	g_strfreev (freebusy_strv);

	return TRUE;
}

/* Helper for e_cal_client_create_object() */
static void
cal_client_create_object_thread (GSimpleAsyncResult *simple,
                                 GObject *source_object,
                                 GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_create_object_sync (
		E_CAL_CLIENT (source_object),
		async_context->in_comp,
		&async_context->uid,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_create_object:
 * @client: an #ECalClient
 * @icalcomp: The component to create
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Requests the calendar backend to create the object specified by the @icalcomp
 * argument. Some backends would assign a specific UID to the newly created object,
 * but this function does not modify the original @icalcomp if its UID changes.
 * The call is finished by e_cal_client_create_object_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_create_object (ECalClient *client,
                            icalcomponent *icalcomp,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (icalcomp != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->in_comp = icalcomponent_new_clone (icalcomp);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_create_object);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_create_object_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_create_object_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_uid: (out): Return value for the UID assigned to the new component
 *           by the calendar backend
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_create_object() and
 * sets @out_uid to newly assigned UID for the created object.
 * This @out_uid should be freed with g_free().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_create_object_finish (ECalClient *client,
                                   GAsyncResult *result,
                                   gchar **out_uid,
                                   GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_create_object), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->uid != NULL, FALSE);

	if (out_uid != NULL) {
		*out_uid = async_context->uid;
		async_context->uid = NULL;
	}

	return TRUE;
}

/**
 * e_cal_client_create_object_sync:
 * @client: an #ECalClient
 * @icalcomp: The component to create
 * @out_uid: (out): Return value for the UID assigned to the new component
 *           by the calendar backend
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Requests the calendar backend to create the object specified by the
 * @icalcomp argument. Some backends would assign a specific UID to the newly
 * created object, in those cases that UID would be returned in the @out_uid
 * argument. This function does not modify the original @icalcomp if its UID
 * changes.  Returned @out_uid should be freed with g_free().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_create_object_sync (ECalClient *client,
                                 icalcomponent *icalcomp,
                                 gchar **out_uid,
                                 GCancellable *cancellable,
                                 GError **error)
{
	GSList link = { icalcomp, NULL };
	GSList *string_list = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (icalcomp != NULL, FALSE);

	success = e_cal_client_create_objects_sync (
		client, &link, &string_list, cancellable, error);

	/* Sanity check. */
	g_return_val_if_fail (
		(success && (string_list != NULL)) ||
		(!success && (string_list == NULL)), FALSE);

	if (out_uid != NULL && string_list != NULL)
		*out_uid = g_strdup (string_list->data);

	g_slist_free_full (string_list, (GDestroyNotify) g_free);

	return success;
}

/* Helper for e_cal_client_create_objects() */
static void
cal_client_create_objects_thread (GSimpleAsyncResult *simple,
                                  GObject *source_object,
                                  GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_create_objects_sync (
		E_CAL_CLIENT (source_object),
		async_context->comp_list,
		&async_context->string_list,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_create_objects:
 * @client: an #ECalClient
 * @icalcomps: (element-type icalcomponent): The components to create
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Requests the calendar backend to create the objects specified by the @icalcomps
 * argument. Some backends would assign a specific UID to the newly created object,
 * but this function does not modify the original @icalcomps if their UID changes.
 * The call is finished by e_cal_client_create_objects_finish() from
 * the @callback.
 *
 * Since: 3.6
 **/
void
e_cal_client_create_objects (ECalClient *client,
                             GSList *icalcomps,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (icalcomps != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->comp_list = g_slist_copy_deep (
		icalcomps, (GCopyFunc) icalcomponent_new_clone, NULL);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_create_objects);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_create_objects_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_create_objects_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_uids: (out) (element-type utf8): Return value for the UIDs assigned
 *            to the new components by the calendar backend
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_create_objects() and
 * sets @out_uids to newly assigned UIDs for the created objects.
 * This @out_uids should be freed with e_client_util_free_string_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.6
 **/
gboolean
e_cal_client_create_objects_finish (ECalClient *client,
                                    GAsyncResult *result,
                                    GSList **out_uids,
                                    GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_create_objects), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	if (out_uids != NULL) {
		*out_uids = async_context->string_list;
		async_context->string_list = NULL;
	}

	return TRUE;
}

/**
 * e_cal_client_create_objects_sync:
 * @client: an #ECalClient
 * @icalcomps: (element-type icalcomponent): The components to create
 * @out_uids: (out) (element-type utf8): Return value for the UIDs assigned
 *            to the new components by the calendar backend
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Requests the calendar backend to create the objects specified by the
 * @icalcomps argument. Some backends would assign a specific UID to the
 * newly created objects, in those cases these UIDs would be returned in
 * the @out_uids argument. This function does not modify the original
 * @icalcomps if their UID changes.  Returned @out_uids should be freed
 * with e_client_util_free_string_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.6
 **/
gboolean
e_cal_client_create_objects_sync (ECalClient *client,
                                  GSList *icalcomps,
                                  GSList **out_uids,
                                  GCancellable *cancellable,
                                  GError **error)
{
	gchar **strv;
	gchar **uids = NULL;
	gint ii = 0;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (icalcomps != NULL, FALSE);
	g_return_val_if_fail (out_uids != NULL, FALSE);

	strv = g_new0 (gchar *, g_slist_length (icalcomps) + 1);
	while (icalcomps != NULL) {
		gchar *ical_string;

		ical_string = icalcomponent_as_ical_string_r (icalcomps->data);
		strv[ii++] = e_util_utf8_make_valid (ical_string);
		g_free (ical_string);

		icalcomps = g_slist_next (icalcomps);
	}

	e_dbus_calendar_call_create_objects_sync (
		client->priv->dbus_proxy,
		(const gchar * const *) strv,
		&uids, cancellable, &local_error);

	g_strfreev (strv);

	/* Sanity check. */
	g_return_val_if_fail (
		((uids != NULL) && (local_error == NULL)) ||
		((uids == NULL) && (local_error != NULL)), FALSE);

	if (uids != NULL) {
		GSList *tmp = NULL;

		/* Steal the string array elements. */
		for (ii = 0; uids[ii] != NULL; ii++) {
			tmp = g_slist_prepend (tmp, uids[ii]);
			uids[ii] = NULL;
		}

		*out_uids = g_slist_reverse (tmp);
	}

	g_strfreev (uids);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for e_cal_client_modify_object() */
static void
cal_client_modify_object_thread (GSimpleAsyncResult *simple,
                                 GObject *source_object,
                                 GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_modify_object_sync (
		E_CAL_CLIENT (source_object),
		async_context->in_comp,
		async_context->mod,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_modify_object:
 * @client: an #ECalClient
 * @icalcomp: Component to modify
 * @mod: Type of modification
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Requests the calendar backend to modify an existing object. If the object
 * does not exist on the calendar, an error will be returned.
 *
 * For recurrent appointments, the @mod argument specifies what to modify,
 * if all instances (E_CAL_OBJ_MOD_ALL), a single instance (E_CAL_OBJ_MOD_THIS),
 * or a specific set of instances (E_CAL_OBJ_MOD_THIS_AND_PRIOR and
 * E_CAL_OBJ_MOD_THIS_AND_FUTURE).
 *
 * The call is finished by e_cal_client_modify_object_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_modify_object (ECalClient *client,
                            icalcomponent *icalcomp,
                            ECalObjModType mod,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (icalcomp != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->in_comp = icalcomponent_new_clone (icalcomp);
	async_context->mod = mod;

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_modify_object);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_modify_object_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_modify_object_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_modify_object().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_modify_object_finish (ECalClient *client,
                                   GAsyncResult *result,
                                   GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_modify_object), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_cal_client_modify_object_sync:
 * @client: an #ECalClient
 * @icalcomp: Component to modify
 * @mod: Type of modification
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Requests the calendar backend to modify an existing object. If the object
 * does not exist on the calendar, an error will be returned.
 *
 * For recurrent appointments, the @mod argument specifies what to modify,
 * if all instances (E_CAL_OBJ_MOD_ALL), a single instance (E_CAL_OBJ_MOD_THIS),
 * or a specific set of instances (E_CAL_OBJ_MOD_THISNADPRIOR and
 * E_CAL_OBJ_MOD_THIS_AND_FUTURE).
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_modify_object_sync (ECalClient *client,
                                 icalcomponent *icalcomp,
                                 ECalObjModType mod,
                                 GCancellable *cancellable,
                                 GError **error)
{
	GSList link = { icalcomp, NULL };

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (icalcomp != NULL, FALSE);

	return e_cal_client_modify_objects_sync (
		client, &link, mod, cancellable, error);
}

/* Helper for e_cal_client_modify_objects() */
static void
cal_client_modify_objects_thread (GSimpleAsyncResult *simple,
                                  GObject *source_object,
                                  GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_modify_objects_sync (
		E_CAL_CLIENT (source_object),
		async_context->comp_list,
		async_context->mod,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_modify_objects:
 * @client: an #ECalClient
 * @comps: (element-type icalcomponent): Components to modify
 * @mod: Type of modification
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Requests the calendar backend to modify existing objects. If an object
 * does not exist on the calendar, an error will be returned.
 *
 * For recurrent appointments, the @mod argument specifies what to modify,
 * if all instances (E_CAL_OBJ_MOD_ALL), a single instance (E_CAL_OBJ_MOD_THIS),
 * or a specific set of instances (E_CAL_OBJ_MOD_THISNADPRIOR and
 * E_CAL_OBJ_MOD_THIS_AND_FUTURE).
 *
 * The call is finished by e_cal_client_modify_objects_finish() from
 * the @callback.
 *
 * Since: 3.6
 **/
void
e_cal_client_modify_objects (ECalClient *client,
                             GSList *comps,
                             ECalObjModType mod,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (comps != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->comp_list = g_slist_copy_deep (
		comps, (GCopyFunc) icalcomponent_new_clone, NULL);
	async_context->mod = mod;

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_modify_objects);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_modify_objects_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_modify_objects_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_modify_objects().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.6
 **/
gboolean
e_cal_client_modify_objects_finish (ECalClient *client,
                                    GAsyncResult *result,
                                    GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_modify_objects), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_cal_client_modify_objects_sync:
 * @client: an #ECalClient
 * @comps: (element-type icalcomponent): Components to modify
 * @mod: Type of modification
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Requests the calendar backend to modify existing objects. If an object
 * does not exist on the calendar, an error will be returned.
 *
 * For recurrent appointments, the @mod argument specifies what to modify,
 * if all instances (E_CAL_OBJ_MOD_ALL), a single instance (E_CAL_OBJ_MOD_THIS),
 * or a specific set of instances (E_CAL_OBJ_MOD_THISNADPRIOR and
 * E_CAL_OBJ_MOD_THIS_AND_FUTURE).
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.6
 **/
gboolean
e_cal_client_modify_objects_sync (ECalClient *client,
                                  GSList *comps,
                                  ECalObjModType mod,
                                  GCancellable *cancellable,
                                  GError **error)
{
	GFlagsClass *flags_class;
	GFlagsValue *flags_value;
	GString *flags;
	gchar **strv;
	gint ii = 0;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (comps != NULL, FALSE);

	flags = g_string_new (NULL);
	flags_class = g_type_class_ref (E_TYPE_CAL_OBJ_MOD_TYPE);
	flags_value = g_flags_get_first_value (flags_class, mod);
	while (flags_value != NULL) {
		if (flags->len > 0)
			g_string_append_c (flags, ':');
		g_string_append (flags, flags_value->value_nick);
		mod &= ~flags_value->value;
		flags_value = g_flags_get_first_value (flags_class, mod);
	}

	strv = g_new0 (gchar *, g_slist_length (comps) + 1);
	while (comps != NULL) {
		gchar *ical_string;

		ical_string = icalcomponent_as_ical_string_r (comps->data);
		strv[ii++] = e_util_utf8_make_valid (ical_string);
		g_free (ical_string);

		comps = g_slist_next (comps);
	}

	e_dbus_calendar_call_modify_objects_sync (
		client->priv->dbus_proxy,
		(const gchar * const *) strv,
		flags->str, cancellable, &local_error);

	g_strfreev (strv);

	g_type_class_unref (flags_class);
	g_string_free (flags, TRUE);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for e_cal_client_remove_object() */
static void
cal_client_remove_object_thread (GSimpleAsyncResult *simple,
                                 GObject *source_object,
                                 GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_remove_object_sync (
		E_CAL_CLIENT (source_object),
		async_context->uid,
		async_context->rid,
		async_context->mod,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_remove_object:
 * @client: an #ECalClient
 * @uid: UID of the object to remove
 * @rid: Recurrence ID of the specific recurrence to remove
 * @mod: Type of the removal
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * This function allows the removal of instances of a recurrent
 * appointment. By using a combination of the @uid, @rid and @mod
 * arguments, you can remove specific instances. If what you want
 * is to remove all instances, use %NULL @rid and E_CAL_OBJ_MOD_ALL
 * for the @mod.
 *
 * The call is finished by e_cal_client_remove_object_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_remove_object (ECalClient *client,
                            const gchar *uid,
                            const gchar *rid,
                            ECalObjModType mod,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (uid != NULL);
	/* rid is optional */

	async_context = g_slice_new0 (AsyncContext);
	async_context->uid = g_strdup (uid);
	async_context->rid = g_strdup (rid);
	async_context->mod = mod;

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_remove_object);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_remove_object_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_remove_object_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_remove_object().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_remove_object_finish (ECalClient *client,
                                   GAsyncResult *result,
                                   GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_remove_object), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_cal_client_remove_object_sync:
 * @client: an #ECalClient
 * @uid: UID of the object to remove
 * @rid: Recurrence ID of the specific recurrence to remove
 * @mod: Type of the removal
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * This function allows the removal of instances of a recurrent
 * appointment. By using a combination of the @uid, @rid and @mod
 * arguments, you can remove specific instances. If what you want
 * is to remove all instances, use %NULL @rid and E_CAL_OBJ_MODE_ALL
 * for the @mod.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_remove_object_sync (ECalClient *client,
                                 const gchar *uid,
                                 const gchar *rid,
                                 ECalObjModType mod,
                                 GCancellable *cancellable,
                                 GError **error)
{
	ECalComponentId id = { (gchar *) uid, (gchar *) rid };
	GSList link = { &id, NULL };

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	return e_cal_client_remove_objects_sync (
		client, &link, mod, cancellable, error);
}

/* Helper for e_cal_client_remove_objects() */
static void
cal_client_remove_objects_thread (GSimpleAsyncResult *simple,
                                  GObject *source_object,
                                  GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_remove_objects_sync (
		E_CAL_CLIENT (source_object),
		async_context->string_list,
		async_context->mod,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_remove_objects:
 * @client: an #ECalClient
 * @ids: (element-type ECalComponentId): A list of #ECalComponentId objects
 * identifying the objects to remove
 * @mod: Type of the removal
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * This function allows the removal of instances of recurrent appointments.
 * #ECalComponentId objects can identify specific instances (if rid is not
 * %NULL).  If what you want is to remove all instances, use a %NULL rid in
 * the #ECalComponentId and E_CAL_OBJ_MOD_ALL for the @mod.
 *
 * The call is finished by e_cal_client_remove_objects_finish() from
 * the @callback.
 *
 * Since: 3.6
 **/
void
e_cal_client_remove_objects (ECalClient *client,
                             const GSList *ids,
                             ECalObjModType mod,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (ids != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->string_list = g_slist_copy_deep (
		(GSList *) ids, (GCopyFunc) g_strdup, NULL);
	async_context->mod = mod;

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_remove_objects);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_remove_objects_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_remove_objects_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_remove_objects().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.6
 **/
gboolean
e_cal_client_remove_objects_finish (ECalClient *client,
                                    GAsyncResult *result,
                                    GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_remove_objects), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_cal_client_remove_objects_sync:
 * @client: an #ECalClient
 * @ids: (element-type ECalComponentId): a list of #ECalComponentId objects
 *       identifying the objects to remove
 * @mod: Type of the removal
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * This function allows the removal of instances of recurrent
 * appointments. #ECalComponentId objects can identify specific instances
 * (if rid is not %NULL).  If what you want is to remove all instances, use
 * a %NULL rid in the #ECalComponentId and E_CAL_OBJ_MOD_ALL for the @mod.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.6
 **/
gboolean
e_cal_client_remove_objects_sync (ECalClient *client,
                                  const GSList *ids,
                                  ECalObjModType mod,
                                  GCancellable *cancellable,
                                  GError **error)
{
	GVariantBuilder builder;
	GFlagsClass *flags_class;
	GFlagsValue *flags_value;
	GString *flags;
	guint n_valid_uids = 0;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (ids != NULL, FALSE);

	flags = g_string_new (NULL);
	flags_class = g_type_class_ref (E_TYPE_CAL_OBJ_MOD_TYPE);
	flags_value = g_flags_get_first_value (flags_class, mod);
	while (flags_value != NULL) {
		if (flags->len > 0)
			g_string_append_c (flags, ':');
		g_string_append (flags, flags_value->value_nick);
		mod &= ~flags_value->value;
		flags_value = g_flags_get_first_value (flags_class, mod);
	}

	g_variant_builder_init (&builder, G_VARIANT_TYPE ("a(ss)"));
	while (ids != NULL) {
		ECalComponentId *id = ids->data;
		gchar *utf8_uid;
		gchar *utf8_rid;

		ids = g_slist_next (ids);

		if (id->uid == NULL)
			continue;

		/* Reject empty UIDs with an OBJECT_NOT_FOUND error for
		 * backward-compatibility, even though INVALID_ARG might
		 * be more appropriate. */
		if (*id->uid == '\0') {
			local_error = g_error_new_literal (
				E_CAL_CLIENT_ERROR,
				E_CAL_CLIENT_ERROR_OBJECT_NOT_FOUND,
				e_cal_client_error_to_string (
				E_CAL_CLIENT_ERROR_OBJECT_NOT_FOUND));
			n_valid_uids = 0;
			break;
		}

		utf8_uid = e_util_utf8_make_valid (id->uid);
		if (id->rid != NULL)
			utf8_rid = e_util_utf8_make_valid (id->rid);
		else
			utf8_rid = g_strdup ("");

		g_variant_builder_add (&builder, "(ss)", utf8_uid, utf8_rid);

		g_free (utf8_uid);
		g_free (utf8_rid);

		n_valid_uids++;
	}

	if (n_valid_uids > 0) {
		e_dbus_calendar_call_remove_objects_sync (
			client->priv->dbus_proxy,
			g_variant_builder_end (&builder),
			flags->str, cancellable, &local_error);
	} else {
		g_variant_builder_clear (&builder);
	}

	g_type_class_unref (flags_class);
	g_string_free (flags, TRUE);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for e_cal_client_receive_objects() */
static void
cal_client_receive_objects_thread (GSimpleAsyncResult *simple,
                                   GObject *source_object,
                                   GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_receive_objects_sync (
		E_CAL_CLIENT (source_object),
		async_context->in_comp,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_receive_objects:
 * @client: an #ECalClient
 * @icalcomp: An #icalcomponent
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Makes the backend receive the set of iCalendar objects specified in the
 * @icalcomp argument. This is used for iTIP confirmation/cancellation
 * messages for scheduled meetings.
 *
 * The call is finished by e_cal_client_receive_objects_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_receive_objects (ECalClient *client,
                              icalcomponent *icalcomp,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (icalcomp != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->in_comp = icalcomponent_new_clone (icalcomp);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_receive_objects);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_receive_objects_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_receive_objects_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_receive_objects().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_receive_objects_finish (ECalClient *client,
                                     GAsyncResult *result,
                                     GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_receive_objects), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_cal_client_receive_objects_sync:
 * @client: an #ECalClient
 * @icalcomp: An #icalcomponent
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Makes the backend receive the set of iCalendar objects specified in the
 * @icalcomp argument. This is used for iTIP confirmation/cancellation
 * messages for scheduled meetings.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_receive_objects_sync (ECalClient *client,
                                   icalcomponent *icalcomp,
                                   GCancellable *cancellable,
                                   GError **error)
{
	gchar *ical_string;
	gchar *utf8_ical_string;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);

	ical_string = icalcomponent_as_ical_string_r (icalcomp);
	utf8_ical_string = e_util_utf8_make_valid (ical_string);

	e_dbus_calendar_call_receive_objects_sync (
		client->priv->dbus_proxy, utf8_ical_string,
		cancellable, &local_error);

	g_free (utf8_ical_string);
	g_free (ical_string);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for e_cal_client_send_objects() */
static void
cal_client_send_objects_thread (GSimpleAsyncResult *simple,
                                GObject *source_object,
                                GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_send_objects_sync (
		E_CAL_CLIENT (source_object),
		async_context->in_comp,
		&async_context->string_list,
		&async_context->out_comp,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_send_objects:
 * @client: an #ECalClient
 * @icalcomp: An icalcomponent to be sent
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Requests a calendar backend to send meeting information stored in @icalcomp.
 * The backend can modify this component and request a send to particular users.
 * The call is finished by e_cal_client_send_objects_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_send_objects (ECalClient *client,
                           icalcomponent *icalcomp,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (icalcomp != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->in_comp = icalcomponent_new_clone (icalcomp);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_send_objects);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_send_objects_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_send_objects_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_users: (out) (element-type utf8): List of users to send
 *             the @out_modified_icalcomp to
 * @out_modified_icalcomp: (out): Return value for the icalcomponent to be sent
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_send_objects() and
 * populates @out_users with a list of users to send @out_modified_icalcomp to.
 *
 * The @out_users list should be freed with e_client_util_free_string_slist()
 * and the @out_modified_icalcomp should be freed with icalcomponent_free().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_send_objects_finish (ECalClient *client,
                                  GAsyncResult *result,
                                  GSList **out_users,
                                  icalcomponent **out_modified_icalcomp,
                                  GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_send_objects), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->out_comp != NULL, FALSE);

	if (out_users != NULL) {
		*out_users = async_context->string_list;
		async_context->string_list = NULL;
	}

	if (out_modified_icalcomp != NULL) {
		*out_modified_icalcomp = async_context->out_comp;
		async_context->out_comp = NULL;
	}

	return TRUE;
}

/**
 * e_cal_client_send_objects_sync:
 * @client: an #ECalClient
 * @icalcomp: An icalcomponent to be sent
 * @out_users: (out) (element-type utf8): List of users to send the
 *             @out_modified_icalcomp to
 * @out_modified_icalcomp: (out): Return value for the icalcomponent to be sent
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Requests a calendar backend to send meeting information stored in @icalcomp.
 * The backend can modify this component and request a send to users in the
 * @out_users list.
 *
 * The @out_users list should be freed with e_client_util_free_string_slist()
 * and the @out_modified_icalcomp should be freed with icalcomponent_free().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_send_objects_sync (ECalClient *client,
                                icalcomponent *icalcomp,
                                GSList **out_users,
                                icalcomponent **out_modified_icalcomp,
                                GCancellable *cancellable,
                                GError **error)
{
	gchar *ical_string;
	gchar *utf8_ical_string;
	gchar **users = NULL;
	gchar *out_ical_string = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (icalcomp != NULL, FALSE);
	g_return_val_if_fail (out_users != NULL, FALSE);
	g_return_val_if_fail (out_modified_icalcomp != NULL, FALSE);

	ical_string = icalcomponent_as_ical_string_r (icalcomp);
	utf8_ical_string = e_util_utf8_make_valid (ical_string);

	e_dbus_calendar_call_send_objects_sync (
		client->priv->dbus_proxy, utf8_ical_string, &users,
		&out_ical_string, cancellable, &local_error);

	g_free (utf8_ical_string);
	g_free (ical_string);

	/* Sanity check. */
	g_return_val_if_fail (
		((out_ical_string != NULL) && (local_error == NULL)) ||
		((out_ical_string == NULL) && (local_error != NULL)), FALSE);

	if (local_error != NULL) {
		g_warn_if_fail (users == NULL);
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	icalcomp = icalparser_parse_string (out_ical_string);

	g_free (out_ical_string);

	if (icalcomp != NULL) {
		*out_modified_icalcomp = icalcomp;
	} else {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_INVALID_OBJECT,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_INVALID_OBJECT));
		g_strfreev (users);
		return FALSE;
	}

	if (users != NULL) {
		GSList *tmp = NULL;
		gint ii;

		for (ii = 0; users[ii] != NULL; ii++) {
			tmp = g_slist_prepend (tmp, users[ii]);
			users[ii] = NULL;
		}

		*out_users = g_slist_reverse (tmp);
	}

	g_strfreev (users);

	return TRUE;
}

/* Helper for e_cal_client_get_attachment_uris() */
static void
cal_client_get_attachment_uris_thread (GSimpleAsyncResult *simple,
                                       GObject *source_object,
                                       GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_get_attachment_uris_sync (
		E_CAL_CLIENT (source_object),
		async_context->uid,
		async_context->rid,
		&async_context->string_list,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_get_attachment_uris:
 * @client: an #ECalClient
 * @uid: Unique identifier for a calendar component
 * @rid: Recurrence identifier
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Queries a calendar for a specified component's object attachment uris.
 * The call is finished by e_cal_client_get_attachment_uris_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_get_attachment_uris (ECalClient *client,
                                  const gchar *uid,
                                  const gchar *rid,
                                  GCancellable *cancellable,
                                  GAsyncReadyCallback callback,
                                  gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_CAL_CLIENT (client));
	g_return_if_fail (uid != NULL);
	/* rid is optional */

	async_context = g_slice_new0 (AsyncContext);
	async_context->uid = g_strdup (uid);
	async_context->rid = g_strdup (rid);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_get_attachment_uris);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_get_attachment_uris_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_get_attachment_uris_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_attachment_uris: (out) (element-type utf8): Return location for the
 *                       list of attachment URIs
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_get_attachment_uris() and
 * sets @out_attachment_uris to uris for component's attachments.
 * The list should be freed with e_client_util_free_string_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_attachment_uris_finish (ECalClient *client,
                                         GAsyncResult *result,
                                         GSList **out_attachment_uris,
                                         GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_get_attachment_uris), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	if (out_attachment_uris != NULL) {
		*out_attachment_uris = async_context->string_list;
		async_context->string_list = NULL;
	}

	return TRUE;
}

/**
 * e_cal_client_get_attachment_uris_sync:
 * @client: an #ECalClient
 * @uid: Unique identifier for a calendar component
 * @rid: Recurrence identifier
 * @out_attachment_uris: (out) (element-type utf8): Return location for the
 *                       list of attachment URIs
 * @cancellable: (allow-none): a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Queries a calendar for a specified component's object attachment URIs.
 * The list should be freed with e_client_util_free_string_slist().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_attachment_uris_sync (ECalClient *client,
                                       const gchar *uid,
                                       const gchar *rid,
                                       GSList **out_attachment_uris,
                                       GCancellable *cancellable,
                                       GError **error)
{
	gchar *utf8_uid;
	gchar *utf8_rid;
	gchar **uris = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_attachment_uris != NULL, FALSE);

	if (rid == NULL)
		rid = "";

	utf8_uid = e_util_utf8_make_valid (uid);
	utf8_rid = e_util_utf8_make_valid (rid);

	e_dbus_calendar_call_get_attachment_uris_sync (
		client->priv->dbus_proxy, utf8_uid, utf8_rid,
		&uris, cancellable, &local_error);

	g_free (utf8_uid);
	g_free (utf8_rid);

	/* Sanity check. */
	g_return_val_if_fail (
		((uris != NULL) && (local_error == NULL)) ||
		((uris == NULL) && (local_error != NULL)), FALSE);

	if (uris != NULL) {
		GSList *tmp = NULL;
		gint ii;

		for (ii = 0; uris[ii] != NULL; ii++) {
			tmp = g_slist_prepend (tmp, uris[ii]);
			uris[ii] = NULL;
		}

		*out_attachment_uris = g_slist_reverse (tmp);
	}

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for e_cal_client_discard_alarm() */
static void
cal_client_discard_alarm_thread (GSimpleAsyncResult *simple,
                                 GObject *source_object,
                                 GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_discard_alarm_sync (
		E_CAL_CLIENT (source_object),
		async_context->uid,
		async_context->rid,
		async_context->auid,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_discard_alarm:
 * @client: an #ECalClient
 * @uid: Unique identifier for a calendar component
 * @rid: Recurrence identifier
 * @auid: Alarm identifier to remove
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Removes alarm @auid from a given component identified by @uid and @rid.
 * The call is finished by e_cal_client_discard_alarm_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_discard_alarm (ECalClient *client,
                            const gchar *uid,
                            const gchar *rid,
                            const gchar *auid,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (uid != NULL);
	/* rid is optional */
	g_return_if_fail (auid != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->uid = g_strdup (uid);
	async_context->rid = NULL;
	async_context->auid = g_strdup (auid);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_discard_alarm);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_discard_alarm_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_discard_alarm_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_discard_alarm().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_discard_alarm_finish (ECalClient *client,
                                   GAsyncResult *result,
                                   GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_discard_alarm), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_cal_client_discard_alarm_sync:
 * @client: an #ECalClient
 * @uid: Unique identifier for a calendar component
 * @rid: Recurrence identifier
 * @auid: Alarm identifier to remove
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Removes alarm @auid from a given component identified by @uid and @rid.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_discard_alarm_sync (ECalClient *client,
                                 const gchar *uid,
                                 const gchar *rid,
                                 const gchar *auid,
                                 GCancellable *cancellable,
                                 GError **error)
{
	gchar *utf8_uid;
	gchar *utf8_rid;
	gchar *utf8_auid;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (auid != NULL, FALSE);

	if (rid == NULL)
		rid = "";

	utf8_uid = e_util_utf8_make_valid (uid);
	utf8_rid = e_util_utf8_make_valid (rid);
	utf8_auid = e_util_utf8_make_valid (auid);

	e_dbus_calendar_call_discard_alarm_sync (
		client->priv->dbus_proxy,
		utf8_uid, utf8_rid, utf8_auid,
		cancellable, &local_error);

	g_free (utf8_uid);
	g_free (utf8_rid);
	g_free (utf8_auid);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

/* Helper for e_cal_client_get_view() */
static void
cal_client_get_view_in_dbus_thread (GSimpleAsyncResult *simple,
                                    GObject *source_object,
                                    GCancellable *cancellable)
{
	ECalClient *client = E_CAL_CLIENT (source_object);
	AsyncContext *async_context;
	gchar *utf8_sexp;
	gchar *object_path = NULL;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	utf8_sexp = e_util_utf8_make_valid (async_context->sexp);

	e_dbus_calendar_call_get_view_sync (
		client->priv->dbus_proxy, utf8_sexp,
		&object_path, cancellable, &local_error);

	g_free (utf8_sexp);

	/* Sanity check. */
	g_return_if_fail (
		((object_path != NULL) && (local_error == NULL)) ||
		((object_path == NULL) && (local_error != NULL)));

	if (object_path != NULL) {
		GDBusConnection *connection;
		ECalClientView *client_view;

		connection = g_dbus_proxy_get_connection (
			G_DBUS_PROXY (client->priv->dbus_proxy));

		client_view = g_initable_new (
			E_TYPE_CAL_CLIENT_VIEW,
			cancellable, &local_error,
			"client", client,
			"connection", connection,
			"object-path", object_path,
			NULL);

		/* Sanity check. */
		g_return_if_fail (
			((client_view != NULL) && (local_error == NULL)) ||
			((client_view == NULL) && (local_error != NULL)));

		async_context->client_view = client_view;

		g_free (object_path);
	}

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
	}
}

/**
 * e_cal_client_get_view:
 * @client: an #ECalClient
 * @sexp: an S-expression representing the query.
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Query @client with @sexp, creating an #ECalClientView.
 * The call is finished by e_cal_client_get_view_finish()
 * from the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_get_view (ECalClient *client,
                       const gchar *sexp,
                       GCancellable *cancellable,
                       GAsyncReadyCallback callback,
                       gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (sexp != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->sexp = g_strdup (sexp);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_get_view);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_client_run_in_dbus_thread (
		simple, cal_client_get_view_in_dbus_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_get_view_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_view: (out): an #ECalClientView
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_get_view().
 * If successful, then the @out_view is set to newly allocated #ECalClientView,
 * which should be freed with g_object_unref().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_view_finish (ECalClient *client,
                              GAsyncResult *result,
                              ECalClientView **out_view,
                              GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_get_view), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->client_view != NULL, FALSE);

	if (out_view != NULL)
		*out_view = g_object_ref (async_context->client_view);

	return TRUE;
}

/**
 * e_cal_client_get_view_sync:
 * @client: an #ECalClient
 * @sexp: an S-expression representing the query.
 * @out_view: (out): an #ECalClientView
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Query @client with @sexp, creating an #ECalClientView.
 * If successful, then the @out_view is set to newly allocated #ECalClientView,
 * which should be freed with g_object_unref().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_view_sync (ECalClient *client,
                            const gchar *sexp,
                            ECalClientView **out_view,
                            GCancellable *cancellable,
                            GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (sexp != NULL, FALSE);
	g_return_val_if_fail (out_view != NULL, FALSE);

	closure = e_async_closure_new ();

	e_cal_client_get_view (
		client, sexp, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_client_get_view_finish (
		client, result, out_view, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_cal_client_get_timezone() */
static void
cal_client_get_timezone_thread (GSimpleAsyncResult *simple,
                                GObject *source_object,
                                GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_get_timezone_sync (
		E_CAL_CLIENT (source_object),
		async_context->tzid,
		&async_context->zone,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_get_timezone:
 * @client: an #ECalClient
 * @tzid: ID of the timezone to retrieve
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Retrieves a timezone object from the calendar backend.
 * The call is finished by e_cal_client_get_timezone_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_get_timezone (ECalClient *client,
                           const gchar *tzid,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (tzid != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->tzid = g_strdup (tzid);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_get_timezone);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, cal_client_get_timezone_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_get_timezone_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @out_zone: (out): Return value for the timezone
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_get_timezone() and
 * sets @out_zone to a retrieved timezone object from the calendar backend.
 * This object is owned by the @client, thus do not free it.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_timezone_finish (ECalClient *client,
                                  GAsyncResult *result,
                                  icaltimezone **out_zone,
                                  GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_get_timezone), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->zone != NULL, FALSE);

	if (out_zone != NULL) {
		*out_zone = async_context->zone;
		async_context->zone = NULL;
	}

	return TRUE;
}

/**
 * e_cal_client_get_timezone_sync:
 * @client: an #ECalClient
 * @tzid: ID of the timezone to retrieve
 * @out_zone: (out): Return value for the timezone
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Retrieves a timezone object from the calendar backend.
 * This object is owned by the @client, thus do not free it.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_get_timezone_sync (ECalClient *client,
                                const gchar *tzid,
                                icaltimezone **out_zone,
                                GCancellable *cancellable,
                                GError **error)
{
	icalcomponent *icalcomp;
	icaltimezone *zone;
	gchar *utf8_tzid;
	gchar *string = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (tzid != NULL, FALSE);
	g_return_val_if_fail (out_zone != NULL, FALSE);

	zone = e_timezone_cache_get_timezone (
		E_TIMEZONE_CACHE (client), tzid);
	if (zone != NULL) {
		*out_zone = zone;
		return TRUE;
	}

	utf8_tzid = e_util_utf8_make_valid (tzid);

	e_dbus_calendar_call_get_timezone_sync (
		client->priv->dbus_proxy, utf8_tzid,
		&string, cancellable, &local_error);

	g_free (utf8_tzid);

	/* Sanity check. */
	g_return_val_if_fail (
		((string != NULL) && (local_error == NULL)) ||
		((string == NULL) && (local_error != NULL)), FALSE);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	icalcomp = icalparser_parse_string (string);

	g_free (string);

	if (icalcomp == NULL) {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_INVALID_OBJECT,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_INVALID_OBJECT));
		return FALSE;
	}

	zone = icaltimezone_new ();
	if (!icaltimezone_set_component (zone, icalcomp)) {
		g_set_error_literal (
			error, E_CAL_CLIENT_ERROR,
			E_CAL_CLIENT_ERROR_INVALID_OBJECT,
			e_cal_client_error_to_string (
			E_CAL_CLIENT_ERROR_INVALID_OBJECT));
		icalcomponent_free (icalcomp);
		icaltimezone_free (zone, 1);
		return FALSE;
	}

	/* Add the timezone to the cache directly,
	 * otherwise we'd have to free this struct
	 * and fetch the cached copy. */
	g_mutex_lock (&client->priv->zone_cache_lock);
	if (g_hash_table_lookup (client->priv->zone_cache, tzid)) {
		/* It can be that another thread already filled the zone into the cache,
		   thus deal with it properly, because that other zone can be used by that
		   other thread. */
		icaltimezone_free (zone, 1);
		zone = g_hash_table_lookup (client->priv->zone_cache, tzid);
	} else {
		g_hash_table_insert (
			client->priv->zone_cache, g_strdup (tzid), zone);
	}
	g_mutex_unlock (&client->priv->zone_cache_lock);

	*out_zone = zone;

	return TRUE;
}

/* Helper for e_cal_client_add_timezone() */
static void
cal_client_add_timezone_thread (GSimpleAsyncResult *simple,
                                GObject *source_object,
                                GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_client_add_timezone_sync (
		E_CAL_CLIENT (source_object),
		async_context->zone,
		cancellable, &local_error)) {

		if (!local_error)
			local_error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_cal_client_add_timezone:
 * @client: an #ECalClient
 * @zone: The timezone to add
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Add a VTIMEZONE object to the given calendar client.
 * The call is finished by e_cal_client_add_timezone_finish() from
 * the @callback.
 *
 * Since: 3.2
 **/
void
e_cal_client_add_timezone (ECalClient *client,
                           icaltimezone *zone,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	icalcomponent *icalcomp;

	g_return_if_fail (E_IS_CAL_CLIENT (client));
	g_return_if_fail (zone != NULL);

	icalcomp = icaltimezone_get_component (zone);
	g_return_if_fail (icalcomp != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->zone = icaltimezone_new ();

	icalcomp = icalcomponent_new_clone (icalcomp);
	icaltimezone_set_component (async_context->zone, icalcomp);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data,
		e_cal_client_add_timezone);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	if (zone == icaltimezone_get_utc_timezone ())
		g_simple_async_result_complete_in_idle (simple);
	else
		g_simple_async_result_run_in_thread (
			simple, cal_client_add_timezone_thread,
			G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_cal_client_add_timezone_finish:
 * @client: an #ECalClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_cal_client_add_timezone().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_add_timezone_finish (ECalClient *client,
                                  GAsyncResult *result,
                                  GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		e_cal_client_add_timezone), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_cal_client_add_timezone_sync:
 * @client: an #ECalClient
 * @zone: The timezone to add
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Add a VTIMEZONE object to the given calendar client.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_add_timezone_sync (ECalClient *client,
                                icaltimezone *zone,
                                GCancellable *cancellable,
                                GError **error)
{
	icalcomponent *icalcomp;
	gchar *zone_str;
	gchar *utf8_zone_str;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_CLIENT (client), FALSE);
	g_return_val_if_fail (zone != NULL, FALSE);

	if (zone == icaltimezone_get_utc_timezone ())
		return TRUE;

	icalcomp = icaltimezone_get_component (zone);
	if (icalcomp == NULL) {
		g_propagate_error (
			error, e_client_error_create (
			E_CLIENT_ERROR_INVALID_ARG, NULL));
		return FALSE;
	}

	zone_str = icalcomponent_as_ical_string_r (icalcomp);
	utf8_zone_str = e_util_utf8_make_valid (zone_str);

	e_dbus_calendar_call_add_timezone_sync (
		client->priv->dbus_proxy, utf8_zone_str,
		cancellable, &local_error);

	g_free (zone_str);
	g_free (utf8_zone_str);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

