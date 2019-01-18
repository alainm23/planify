/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-session.c : Abstract class for an email session
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
 * Authors: Dan Winship <danw@ximian.com>
 *          Jeffrey Stedfast <fejj@ximian.com>
 *          Bertrand Guiheneuf <bertrand@helixcode.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include "camel-debug.h"
#include "camel-enumtypes.h"
#include "camel-file-utils.h"
#include "camel-folder.h"
#include "camel-mime-message.h"
#include "camel-sasl.h"
#include "camel-session.h"
#include "camel-store.h"
#include "camel-string-utils.h"
#include "camel-transport.h"
#include "camel-url.h"

#define CAMEL_SESSION_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SESSION, CamelSessionPrivate))

/* Prioritize ahead of GTK+ redraws. */
#define JOB_PRIORITY G_PRIORITY_HIGH_IDLE

#define d(x)

typedef struct _AsyncContext AsyncContext;
typedef struct _SignalClosure SignalClosure;
typedef struct _JobData JobData;

struct _CamelSessionPrivate {
	gchar *user_data_dir;
	gchar *user_cache_dir;

	GHashTable *services;
	GMutex services_lock;

	GHashTable *junk_headers;
	CamelJunkFilter *junk_filter;

	GMainContext *main_context;

	GMutex property_lock;
	GNetworkMonitor *network_monitor;

	guint online : 1;
};

struct _AsyncContext {
	CamelFolder *folder;
	CamelMimeMessage *message;
	CamelService *service;
	gchar *address;
	gchar *auth_mechanism;
};

struct _SignalClosure {
	GWeakRef session;
	CamelService *service;
	CamelSessionAlertType alert_type;
	gchar *alert_message;
};

struct _JobData {
	CamelSession *session;
	GCancellable *cancellable;
	CamelSessionCallback callback;
	gpointer user_data;
	GDestroyNotify notify;
	GMainContext *main_context;
	GError *error;
};

enum {
	PROP_0,
	PROP_JUNK_FILTER,
	PROP_MAIN_CONTEXT,
	PROP_NETWORK_MONITOR,
	PROP_ONLINE,
	PROP_USER_DATA_DIR,
	PROP_USER_CACHE_DIR
};

enum {
	JOB_STARTED,
	JOB_FINISHED,
	USER_ALERT,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE (CamelSession, camel_session, G_TYPE_OBJECT)

static void
async_context_free (AsyncContext *async_context)
{
	if (async_context->folder != NULL)
		g_object_unref (async_context->folder);

	if (async_context->message != NULL)
		g_object_unref (async_context->message);

	if (async_context->service != NULL)
		g_object_unref (async_context->service);

	g_free (async_context->address);
	g_free (async_context->auth_mechanism);

	g_slice_free (AsyncContext, async_context);
}

static void
signal_closure_free (SignalClosure *signal_closure)
{
	g_weak_ref_clear (&signal_closure->session);

	if (signal_closure->service != NULL)
		g_object_unref (signal_closure->service);

	g_free (signal_closure->alert_message);

	g_slice_free (SignalClosure, signal_closure);
}

static void
job_data_free (JobData *job_data)
{
	camel_operation_pop_message (job_data->cancellable);

	g_object_unref (job_data->session);
	g_object_unref (job_data->cancellable);
	g_clear_error (&job_data->error);

	if (job_data->main_context)
		g_main_context_unref (job_data->main_context);

	if (job_data->notify != NULL)
		job_data->notify (job_data->user_data);

	g_slice_free (JobData, job_data);
}

static gboolean
session_finish_job_cb (gpointer user_data)
{
	JobData *job_data = (JobData *) user_data;

	g_return_val_if_fail (job_data != NULL, FALSE);

	g_signal_emit (
		job_data->session,
		signals[JOB_FINISHED], 0,
		job_data->cancellable, job_data->error);

	return FALSE;
}

static void
session_job_thread (gpointer data,
		    gpointer user_data)
{
	JobData *job_data = (JobData *) data;
	GSource *source;

	g_return_if_fail (job_data != NULL);

	job_data->callback (
		job_data->session,
		job_data->cancellable,
		job_data->user_data,
		&job_data->error);

	source = g_idle_source_new ();
	g_source_set_priority (source, G_PRIORITY_DEFAULT);
	g_source_set_callback (source, session_finish_job_cb, job_data, (GDestroyNotify) job_data_free);
	g_source_attach (source, job_data->main_context);
	g_source_unref (source);
}

static gboolean
session_start_job_cb (gpointer user_data)
{
	static GThreadPool *job_pool = NULL;
	static GMutex job_pool_mutex;
	JobData *job_data = user_data;

	g_signal_emit (
		job_data->session,
		signals[JOB_STARTED], 0,
		job_data->cancellable);

	g_mutex_lock (&job_pool_mutex);

	if (!job_pool)
		job_pool = g_thread_pool_new (session_job_thread, NULL, 20, FALSE, NULL);

	job_data->main_context = g_main_context_ref_thread_default ();

	g_thread_pool_push (job_pool, job_data, NULL);

	g_mutex_unlock (&job_pool_mutex);

	return FALSE;
}

static gboolean
session_emit_user_alert_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	CamelSession *session;

	session = g_weak_ref_get (&signal_closure->session);

	if (session != NULL) {
		g_signal_emit (
			session,
			signals[USER_ALERT], 0,
			signal_closure->service,
			signal_closure->alert_type,
			signal_closure->alert_message);
		g_object_unref (session);
	}

	return G_SOURCE_REMOVE;
}

static void
session_set_user_data_dir (CamelSession *session,
                           const gchar *user_data_dir)
{
	g_return_if_fail (user_data_dir != NULL);
	g_return_if_fail (session->priv->user_data_dir == NULL);

	session->priv->user_data_dir = g_strdup (user_data_dir);
}

static void
session_set_user_cache_dir (CamelSession *session,
                            const gchar *user_cache_dir)
{
	g_return_if_fail (user_cache_dir != NULL);
	g_return_if_fail (session->priv->user_cache_dir == NULL);

	session->priv->user_cache_dir = g_strdup (user_cache_dir);
}

static void
session_set_property (GObject *object,
                      guint property_id,
                      const GValue *value,
                      GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_JUNK_FILTER:
			camel_session_set_junk_filter (
				CAMEL_SESSION (object),
				g_value_get_object (value));
			return;

		case PROP_NETWORK_MONITOR:
			camel_session_set_network_monitor (
				CAMEL_SESSION (object),
				g_value_get_object (value));
			return;

		case PROP_ONLINE:
			camel_session_set_online (
				CAMEL_SESSION (object),
				g_value_get_boolean (value));
			return;

		case PROP_USER_DATA_DIR:
			session_set_user_data_dir (
				CAMEL_SESSION (object),
				g_value_get_string (value));
			return;

		case PROP_USER_CACHE_DIR:
			session_set_user_cache_dir (
				CAMEL_SESSION (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
session_get_property (GObject *object,
                      guint property_id,
                      GValue *value,
                      GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_JUNK_FILTER:
			g_value_set_object (
				value, camel_session_get_junk_filter (
				CAMEL_SESSION (object)));
			return;

		case PROP_MAIN_CONTEXT:
			g_value_take_boxed (
				value, camel_session_ref_main_context (
				CAMEL_SESSION (object)));
			return;

		case PROP_NETWORK_MONITOR:
			g_value_take_object (
				value, camel_session_ref_network_monitor (
				CAMEL_SESSION (object)));
			return;

		case PROP_ONLINE:
			g_value_set_boolean (
				value, camel_session_get_online (
				CAMEL_SESSION (object)));
			return;

		case PROP_USER_DATA_DIR:
			g_value_set_string (
				value, camel_session_get_user_data_dir (
				CAMEL_SESSION (object)));
			return;

		case PROP_USER_CACHE_DIR:
			g_value_set_string (
				value, camel_session_get_user_cache_dir (
				CAMEL_SESSION (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
session_dispose (GObject *object)
{
	CamelSessionPrivate *priv;

	priv = CAMEL_SESSION_GET_PRIVATE (object);

	g_hash_table_remove_all (priv->services);

	g_clear_object (&priv->junk_filter);
	g_clear_object (&priv->network_monitor);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_session_parent_class)->dispose (object);
}

static void
session_finalize (GObject *object)
{
	CamelSessionPrivate *priv;

	priv = CAMEL_SESSION_GET_PRIVATE (object);

	g_free (priv->user_data_dir);
	g_free (priv->user_cache_dir);

	g_hash_table_destroy (priv->services);

	if (priv->main_context != NULL)
		g_main_context_unref (priv->main_context);

	g_mutex_clear (&priv->services_lock);
	g_mutex_clear (&priv->property_lock);

	if (priv->junk_headers) {
		g_hash_table_remove_all (priv->junk_headers);
		g_hash_table_destroy (priv->junk_headers);
	}

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_session_parent_class)->finalize (object);
}

static CamelService *
session_add_service (CamelSession *session,
                     const gchar *uid,
                     const gchar *protocol,
                     CamelProviderType type,
                     GError **error)
{
	CamelService *service;
	CamelProvider *provider;
	GType service_type = G_TYPE_INVALID;

	service = camel_session_ref_service (session, uid);
	if (CAMEL_IS_SERVICE (service))
		return service;

	/* Try to find a suitable CamelService subclass. */
	provider = camel_provider_get (protocol, error);
	if (provider != NULL)
		service_type = provider->object_types[type];

	if (error && *error)
		return NULL;

	if (service_type == G_TYPE_INVALID) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_URL_INVALID,
			_("No provider available for protocol “%s”"),
			protocol);
		return NULL;
	}

	if (!g_type_is_a (service_type, CAMEL_TYPE_SERVICE)) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_INVALID,
			_("Invalid GType registered for protocol “%s”"),
			protocol);
		return NULL;
	}

	service = g_initable_new (
		service_type, NULL, error,
		"provider", provider, "session",
		session, "uid", uid, NULL);

	if (service != NULL) {
		g_mutex_lock (&session->priv->services_lock);

		g_hash_table_insert (
			session->priv->services,
			g_strdup (uid),
			g_object_ref (service));

		g_mutex_unlock (&session->priv->services_lock);
	}

	return service;
}

static void
session_remove_service (CamelSession *session,
                        CamelService *service)
{
	const gchar *uid;

	g_mutex_lock (&session->priv->services_lock);

	uid = camel_service_get_uid (service);
	g_hash_table_remove (session->priv->services, uid);

	g_mutex_unlock (&session->priv->services_lock);
}

static gboolean
session_authenticate_sync (CamelSession *session,
                           CamelService *service,
                           const gchar *mechanism,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelServiceAuthType *authtype = NULL;
	CamelAuthenticationResult result;
	GError *local_error = NULL;

	/* XXX This authenticate_sync() implementation serves only as
	 *     a rough example and is not intended to be used as is.
	 *
	 *     Any CamelSession subclass should override this method
	 *     and implement a more complete authentication loop that
	 *     handles user prompts and password storage.
	 */

	g_warning (
		"The default CamelSession.authenticate_sync() "
		"method is not intended for production use.");

	/* If a SASL mechanism was given and we can't find
	 * a CamelServiceAuthType for it, fail immediately. */
	if (mechanism != NULL) {
		authtype = camel_sasl_authtype (mechanism);
		if (authtype == NULL) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("No support for %s authentication"),
				mechanism);
			return FALSE;
		}
	}

	/* If the SASL mechanism does not involve a user
	 * password, then it gets one shot to authenticate. */
	if (authtype != NULL && !authtype->need_password) {
		result = camel_service_authenticate_sync (
			service, mechanism, cancellable, error);
		if (result == CAMEL_AUTHENTICATION_REJECTED)
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("%s authentication failed"), mechanism);
		return (result == CAMEL_AUTHENTICATION_ACCEPTED);
	}

	/* Some SASL mechanisms can attempt to authenticate without a
	 * user password being provided (e.g. single-sign-on credentials),
	 * but can fall back to a user password.  Handle that case next. */
	if (mechanism != NULL) {
		CamelProvider *provider;
		CamelSasl *sasl;
		const gchar *service_name;
		gboolean success = FALSE;

		provider = camel_service_get_provider (service);
		service_name = provider->protocol;

		/* XXX Would be nice if camel_sasl_try_empty_password_sync()
		 *     returned CamelAuthenticationResult so it's easier to
		 *     detect errors. */
		sasl = camel_sasl_new (service_name, mechanism, service);
		if (sasl != NULL) {
			success = camel_sasl_try_empty_password_sync (
				sasl, cancellable, &local_error);
			g_object_unref (sasl);
		}

		if (success)
			return TRUE;
	}

	/* Abort authentication if we got cancelled.
	 * Otherwise clear any errors and press on. */
	if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
		return FALSE;

	g_clear_error (&local_error);

retry:
	/* XXX This is where things get bogus.  In a real implementation you
	 *     would want to fetch a stored password or prompt the user here.
	 *     Password should be stashed using camel_service_set_password()
	 *     before calling camel_service_authenticate_sync(). */

	result = camel_service_authenticate_sync (
		service, mechanism, cancellable, error);

	if (result == CAMEL_AUTHENTICATION_REJECTED) {
		/* XXX Request a different password here. */
		goto retry;
	}

	if (result == CAMEL_AUTHENTICATION_ACCEPTED) {
		/* XXX Possibly store the password here using
		 *     GNOME Keyring or something equivalent. */
	}

	return (result == CAMEL_AUTHENTICATION_ACCEPTED);
}

static gboolean
session_forward_to_sync (CamelSession *session,
                         CamelFolder *folder,
                         CamelMimeMessage *message,
                         const gchar *address,
                         GCancellable *cancellable,
                         GError **error)
{
	g_set_error_literal (
		error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
		_("Forwarding messages is not supported"));

	return FALSE;
}

static void
camel_session_class_init (CamelSessionClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelSessionPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = session_set_property;
	object_class->get_property = session_get_property;
	object_class->dispose = session_dispose;
	object_class->finalize = session_finalize;

	class->add_service = session_add_service;
	class->remove_service = session_remove_service;

	class->authenticate_sync = session_authenticate_sync;
	class->forward_to_sync = session_forward_to_sync;

	g_object_class_install_property (
		object_class,
		PROP_JUNK_FILTER,
		g_param_spec_object (
			"junk-filter",
			"Junk Filter",
			"Classifies messages as junk or not junk",
			CAMEL_TYPE_JUNK_FILTER,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_MAIN_CONTEXT,
		g_param_spec_boxed (
			"main-context",
			"Main Context",
			"The main loop context on "
			"which to attach event sources",
			G_TYPE_MAIN_CONTEXT,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_NETWORK_MONITOR,
		g_param_spec_object (
			"network-monitor",
			"Network Monitor",
			NULL,
			G_TYPE_NETWORK_MONITOR,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_ONLINE,
		g_param_spec_boolean (
			"online",
			"Online",
			"Whether the shell is online",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_USER_DATA_DIR,
		g_param_spec_string (
			"user-data-dir",
			"User Data Directory",
			"User-specific base directory for mail data",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_USER_CACHE_DIR,
		g_param_spec_string (
			"user-cache-dir",
			"User Cache Directory",
			"User-specific base directory for mail cache",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	signals[JOB_STARTED] = g_signal_new (
		"job-started",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (CamelSessionClass, job_started),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_CANCELLABLE);

	signals[JOB_FINISHED] = g_signal_new (
		"job-finished",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (CamelSessionClass, job_finished),
		NULL, NULL, NULL,
		G_TYPE_NONE, 2,
		G_TYPE_CANCELLABLE,
		G_TYPE_ERROR);

	/**
	 * CamelSession::user-alert:
	 * @session: the #CamelSession that received the signal
	 * @service: the #CamelService issuing the alert
	 * @type: the #CamelSessionAlertType
	 * @message: the alert message
	 *
	 * This purpose of this signal is to propagate a server-issued alert
	 * message from @service to a user interface.  The @type hints at the
	 * severity of the alert message.
	 **/
	signals[USER_ALERT] = g_signal_new (
		"user-alert",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (CamelSessionClass, user_alert),
		NULL, NULL, NULL,
		G_TYPE_NONE, 3,
		CAMEL_TYPE_SERVICE,
		CAMEL_TYPE_SESSION_ALERT_TYPE,
		G_TYPE_STRING);
}

static void
camel_session_init (CamelSession *session)
{
	GHashTable *services;

	services = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_object_unref);

	session->priv = CAMEL_SESSION_GET_PRIVATE (session);

	session->priv->services = services;
	g_mutex_init (&session->priv->services_lock);
	g_mutex_init (&session->priv->property_lock);
	session->priv->junk_headers = NULL;

	session->priv->main_context = g_main_context_ref_thread_default ();
}

/**
 * camel_session_ref_main_context:
 * @session: a #CamelSession
 *
 * Returns the #GMainContext on which event sources for @session are to
 * be attached.
 *
 * Returns: a #GMainContext
 *
 * Since: 3.8
 **/
GMainContext *
camel_session_ref_main_context (CamelSession *session)
{
	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);

	return g_main_context_ref (session->priv->main_context);
}

/**
 * camel_session_get_user_data_dir:
 * @session: a #CamelSession
 *
 * Returns the base directory under which to store user-specific mail data.
 *
 * Returns: the base directory for mail data
 *
 * Since: 3.2
 **/
const gchar *
camel_session_get_user_data_dir (CamelSession *session)
{
	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);

	return session->priv->user_data_dir;
}

/**
 * camel_session_get_user_cache_dir:
 * @session: a #CamelSession
 *
 * Returns the base directory under which to store user-specific mail cache.
 *
 * Returns: the base directory for mail cache
 *
 * Since: 3.4
 **/
const gchar *
camel_session_get_user_cache_dir (CamelSession *session)
{
	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);

	return session->priv->user_cache_dir;
}

/**
 * camel_session_set_network_monitor:
 * @session: a #CamelSession
 * @network_monitor: (nullable): a #GNetworkMonitor or %NULL
 *
 * Sets a network monitor instance for the @session. This can be used
 * to override which #GNetworkMonitor should be used to check network
 * availability and whether a server is reachable.
 *
 * Since: 3.22
 **/
void
camel_session_set_network_monitor (CamelSession *session,
				   GNetworkMonitor *network_monitor)
{
	gboolean changed = FALSE;

	g_return_if_fail (CAMEL_IS_SESSION (session));
	if (network_monitor)
		g_return_if_fail (G_IS_NETWORK_MONITOR (network_monitor));

	g_mutex_lock (&session->priv->property_lock);

	if (network_monitor != session->priv->network_monitor) {
		g_clear_object (&session->priv->network_monitor);
		session->priv->network_monitor = network_monitor ? g_object_ref (network_monitor) : NULL;

		changed = TRUE;
	}

	g_mutex_unlock (&session->priv->property_lock);

	if (changed)
		g_object_notify (G_OBJECT (session), "network-monitor");
}

/**
 * camel_session_ref_network_monitor:
 * @session: a #CamelSession
 *
 * References a #GNetworkMonitor instance, which had been previously set
 * by camel_session_set_network_monitor(). If none is set, then the default
 * #GNetworkMonitor is returned, as provided by g_network_monitor_get_default().
 * The returned pointer is referenced for thread safety, unref it with
 * g_object_unref() when no longer needed.
 *
 * Returns: (transfer full): A referenced #GNetworkMonitor instance to use
 *   for network availability tests.
 *
 * Since:3.22
 **/
GNetworkMonitor *
camel_session_ref_network_monitor (CamelSession *session)
{
	GNetworkMonitor *network_monitor;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);

	g_mutex_lock (&session->priv->property_lock);

	network_monitor = g_object_ref (session->priv->network_monitor ?
		session->priv->network_monitor : g_network_monitor_get_default ());

	g_mutex_unlock (&session->priv->property_lock);

	return network_monitor;
}

/**
 * camel_session_add_service:
 * @session: a #CamelSession
 * @uid: a unique identifier string
 * @protocol: the service protocol
 * @type: the service type
 * @error: return location for a #GError, or %NULL
 *
 * Instantiates a new #CamelService for @session.  The @uid identifies the
 * service for future lookup.  The @protocol indicates which #CamelProvider
 * holds the #GType of the #CamelService subclass to instantiate.  The @type
 * explicitly designates the service as a #CamelStore or #CamelTransport.
 *
 * If the given @uid has already been added, the existing #CamelService
 * with that @uid is returned regardless of whether it agrees with the
 * given @protocol and @type.
 *
 * If no #CamelProvider is available to handle the given @protocol, or
 * if the #CamelProvider does not specify a valid #GType for @type, the
 * function sets @error and returns %NULL.
 *
 * The returned #CamelService is referenced for thread-safety and must be
 * unreferenced with g_object_unref() when finished with it.
 *
 * Returns: (transfer full): a #CamelService instance, or %NULL
 *
 * Since: 3.2
 **/
CamelService *
camel_session_add_service (CamelSession *session,
                           const gchar *uid,
                           const gchar *protocol,
                           CamelProviderType type,
                           GError **error)
{
	CamelSessionClass *class;
	CamelService *service;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);
	g_return_val_if_fail (uid != NULL, NULL);
	g_return_val_if_fail (protocol != NULL, NULL);

	class = CAMEL_SESSION_GET_CLASS (session);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->add_service != NULL, NULL);

	service = class->add_service (session, uid, protocol, type, error);
	CAMEL_CHECK_GERROR (session, add_service, service != NULL, error);

	return service;
}

/**
 * camel_session_remove_service:
 * @session: a #CamelSession
 * @service: the #CamelService to remove
 *
 * Removes a #CamelService previously added by camel_session_add_service().
 *
 * Since: 3.2
 **/
void
camel_session_remove_service (CamelSession *session,
                              CamelService *service)
{
	CamelSessionClass *class;

	g_return_if_fail (CAMEL_IS_SESSION (session));
	g_return_if_fail (CAMEL_IS_SERVICE (service));

	class = CAMEL_SESSION_GET_CLASS (session);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->remove_service != NULL);

	class->remove_service (session, service);
}

/**
 * camel_session_ref_service:
 * @session: a #CamelSession
 * @uid: a unique identifier string
 *
 * Looks up a #CamelService by its unique identifier string.  The service
 * must have been previously added using camel_session_add_service().
 *
 * The returned #CamelService is referenced for thread-safety and must be
 * unreferenced with g_object_unref() when finished with it.
 *
 * Returns: (transfer full): a #CamelService instance, or %NULL
 *
 * Since: 3.6
 **/
CamelService *
camel_session_ref_service (CamelSession *session,
                           const gchar *uid)
{
	CamelService *service;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	g_mutex_lock (&session->priv->services_lock);

	service = g_hash_table_lookup (session->priv->services, uid);

	if (service != NULL)
		g_object_ref (service);

	g_mutex_unlock (&session->priv->services_lock);

	return service;
}

/**
 * camel_session_ref_service_by_url:
 * @session: a #CamelSession
 * @url: a #CamelURL
 * @type: a #CamelProviderType
 *
 * Looks up a #CamelService by trying to match its #CamelURL against the
 * given @url and then checking that the object is of the desired @type.
 * The service must have been previously added using
 * camel_session_add_service().
 *
 * The returned #CamelService is referenced for thread-safety and must be
 * unreferenced with g_object_unref() when finished with it.
 *
 * Note this function is significantly slower than camel_session_ref_service().
 *
 * Returns: (transfer full): a #CamelService instance, or %NULL
 *
 * Since: 3.6
 **/
CamelService *
camel_session_ref_service_by_url (CamelSession *session,
                                  CamelURL *url,
                                  CamelProviderType type)
{
	CamelService *match = NULL;
	GList *list, *iter;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);
	g_return_val_if_fail (url != NULL, NULL);

	list = camel_session_list_services (session);

	for (iter = list; iter != NULL; iter = g_list_next (iter)) {
		CamelProvider *provider;
		CamelService *service;
		CamelURL *service_url;
		gboolean url_equal;

		service = CAMEL_SERVICE (iter->data);
		provider = camel_service_get_provider (service);

		if (provider == NULL)
			continue;

		if (provider->url_equal == NULL)
			continue;

		service_url = camel_service_new_camel_url (service);
		url_equal = provider->url_equal (url, service_url);
		camel_url_free (service_url);

		if (!url_equal)
			continue;

		switch (type) {
			case CAMEL_PROVIDER_STORE:
				if (CAMEL_IS_STORE (service))
					match = g_object_ref (service);
				break;
			case CAMEL_PROVIDER_TRANSPORT:
				if (CAMEL_IS_TRANSPORT (service))
					match = g_object_ref (service);
				break;
			default:
				g_warn_if_reached ();
				break;
		}

		if (match != NULL)
			break;
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);

	return match;
}

/**
 * camel_session_list_services:
 * @session: a #CamelSession
 *
 * Returns a list of all #CamelService objects previously added using
 * camel_session_add_service().
 *
 * The services returned in the list are referenced for thread-safety.
 * They must each be unreferenced with g_object_unref() when finished
 * with them.  Free the returned list itself with g_list_free().
 *
 * An easy way to free the list property in one step is as follows:
 *
 * |[
 *   g_list_free_full (list, g_object_unref);
 * ]|
 *
 * Returns: (element-type CamelService) (transfer full): an unsorted list of #CamelService objects
 *
 * Since: 3.2
 **/
GList *
camel_session_list_services (CamelSession *session)
{
	GList *list;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);

	g_mutex_lock (&session->priv->services_lock);

	list = g_hash_table_get_values (session->priv->services);

	g_list_foreach (list, (GFunc) g_object_ref, NULL);

	g_mutex_unlock (&session->priv->services_lock);

	return list;
}

/**
 * camel_session_remove_services:
 * @session: a #CamelSession
 *
 * Removes all #CamelService instances added by camel_session_add_service().
 *
 * This can be useful during application shutdown to ensure all #CamelService
 * instances are freed properly, especially since #CamelSession instances are
 * prone to reference cycles.
 *
 * Since: 3.2
 **/
void
camel_session_remove_services (CamelSession *session)
{
	g_return_if_fail (CAMEL_IS_SESSION (session));

	g_mutex_lock (&session->priv->services_lock);

	g_hash_table_remove_all (session->priv->services);

	g_mutex_unlock (&session->priv->services_lock);
}

/**
 * camel_session_get_password:
 * @session: a #CamelSession
 * @service: the #CamelService this query is being made by
 * @prompt: prompt to provide to user
 * @item: an identifier, unique within this service, for the information
 * @flags: %CAMEL_SESSION_PASSWORD_REPROMPT, the prompt should force a reprompt
 * %CAMEL_SESSION_PASSWORD_SECRET, whether the password is secret
 * %CAMEL_SESSION_PASSWORD_STATIC, the password is remembered externally
 * @error: return location for a #GError, or %NULL
 *
 * This function is used by a #CamelService to ask the application and
 * the user for a password or other authentication data.
 *
 * @service and @item together uniquely identify the piece of data the
 * caller is concerned with.
 *
 * @prompt is a question to ask the user (if the application doesn't
 * already have the answer cached). If %CAMEL_SESSION_PASSWORD_SECRET
 * is set, the user's input will not be echoed back.
 *
 * If %CAMEL_SESSION_PASSWORD_STATIC is set, it means the password returned
 * will be stored statically by the caller automatically, for the current
 * session.
 *
 * The authenticator should set @error to %G_IO_ERROR_CANCELLED if
 * the user did not provide the information. The caller must g_free()
 * the information returned when it is done with it.
 *
 * Returns: the authentication information or %NULL
 **/
gchar *
camel_session_get_password (CamelSession *session,
                            CamelService *service,
                            const gchar *prompt,
                            const gchar *item,
                            guint32 flags,
                            GError **error)
{
	CamelSessionClass *class;
	gchar *password;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);
	g_return_val_if_fail (prompt != NULL, NULL);
	g_return_val_if_fail (item != NULL, NULL);

	class = CAMEL_SESSION_GET_CLASS (session);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_password != NULL, NULL);

	password = class->get_password (
		session, service, prompt, item, flags, error);
	CAMEL_CHECK_GERROR (session, get_password, password != NULL, error);

	return password;
}

/**
 * camel_session_forget_password:
 * @session: a #CamelSession
 * @service: the #CamelService rejecting the password
 * @item: an identifier, unique within this service, for the information
 * @error: return location for a #GError, or %NULL
 *
 * This function is used by a #CamelService to tell the application
 * that the authentication information it provided via
 * camel_session_get_password() was rejected by the service. If the
 * application was caching this information, it should stop,
 * and if the service asks for it again, it should ask the user.
 *
 * @service and @item identify the rejected authentication information,
 * as with camel_session_get_password().
 *
 * Returns: %TRUE on success, %FALSE on failure
 **/
gboolean
camel_session_forget_password (CamelSession *session,
                               CamelService *service,
                               const gchar *item,
                               GError **error)
{
	CamelSessionClass *class;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), FALSE);
	g_return_val_if_fail (item != NULL, FALSE);

	class = CAMEL_SESSION_GET_CLASS (session);
	g_return_val_if_fail (class, FALSE);
	g_return_val_if_fail (class->forget_password, FALSE);

	success = class->forget_password (session, service, item, error);
	CAMEL_CHECK_GERROR (session, forget_password, success, error);

	return success;
}

/**
 * camel_session_trust_prompt:
 * @session: a #CamelSession
 * @service: a #CamelService
 * @certificate: the peer's #GTlsCertificate
 * @errors: the problems with @certificate
 *
 * Prompts the user whether to accept @certificate for @service.  The
 * set of flags given in @errors indicate why the @certificate failed
 * validation.
 *
 * If an error occurs during prompting or if the user declines to respond,
 * the function returns #CAMEL_CERT_TRUST_UNKNOWN and the certificate will
 * be rejected.
 *
 * Returns: the user's trust level for @certificate
 *
 * Since: 3.8
 **/
CamelCertTrust
camel_session_trust_prompt (CamelSession *session,
                            CamelService *service,
                            GTlsCertificate *certificate,
                            GTlsCertificateFlags errors)
{
	CamelSessionClass *class;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), CAMEL_CERT_TRUST_UNKNOWN);
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), CAMEL_CERT_TRUST_UNKNOWN);
	g_return_val_if_fail (G_IS_TLS_CERTIFICATE (certificate), CAMEL_CERT_TRUST_UNKNOWN);

	class = CAMEL_SESSION_GET_CLASS (session);
	g_return_val_if_fail (class != NULL, CAMEL_CERT_TRUST_UNKNOWN);
	g_return_val_if_fail (class->trust_prompt != NULL, CAMEL_CERT_TRUST_UNKNOWN);

	return class->trust_prompt (session, service, certificate, errors);
}

/**
 * camel_session_user_alert:
 * @session: a #CamelSession
 * @service: a #CamelService
 * @type: a #CamelSessionAlertType
 * @message: the message for the user
 *
 * Emits a #CamelSession:user_alert signal from an idle source on the main
 * loop.  The idle source's priority is #G_PRIORITY_LOW.
 *
 * The purpose of the signal is to propagate a server-issued alert message
 * from @service to a user interface.  The @type hints at the nature of the
 * alert message.
 *
 * Since: 3.12
 */
void
camel_session_user_alert (CamelSession *session,
                          CamelService *service,
                          CamelSessionAlertType type,
                          const gchar *message)
{
	SignalClosure *signal_closure;

	g_return_if_fail (CAMEL_IS_SESSION (session));
	g_return_if_fail (CAMEL_IS_SERVICE (service));
	g_return_if_fail (message != NULL);

	signal_closure = g_slice_new0 (SignalClosure);
	g_weak_ref_init (&signal_closure->session, session);
	signal_closure->service = g_object_ref (service);
	signal_closure->alert_type = type;
	signal_closure->alert_message = g_strdup (message);

	camel_session_idle_add (
		session, G_PRIORITY_LOW,
		session_emit_user_alert_cb,
		signal_closure,
		(GDestroyNotify) signal_closure_free);
}

/**
 * camel_session_lookup_addressbook:
 * @session: a #CamelSession
 * @name: a name/address to lookup for
 *
 * Looks up for the @name in address books.
 *
 * Returns: whether found the @name in any address book.
 *
 * Since: 2.22
 **/
gboolean
camel_session_lookup_addressbook (CamelSession *session,
                                  const gchar *name)
{
	CamelSessionClass *class;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	class = CAMEL_SESSION_GET_CLASS (session);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->lookup_addressbook != NULL, FALSE);

	return class->lookup_addressbook (session, name);
}

/**
 * camel_session_get_online:
 * @session: a #CamelSession
 *
 * Returns: whether or not @session is online
 **/
gboolean
camel_session_get_online (CamelSession *session)
{
	g_return_val_if_fail (CAMEL_IS_SESSION (session), FALSE);

	return session->priv->online;
}

/**
 * camel_session_set_online:
 * @session: a #CamelSession
 * @online: whether or not the session should be online
 *
 * Sets the online status of @session to @online.
 **/
void
camel_session_set_online (CamelSession *session,
                          gboolean online)
{
	g_return_if_fail (CAMEL_IS_SESSION (session));

	if (online == session->priv->online)
		return;

	session->priv->online = online;

	g_object_notify (G_OBJECT (session), "online");
}

/**
 * camel_session_get_filter_driver:
 * @session: a #CamelSession
 * @type: the type of filter (eg, "incoming")
 * @for_folder: (nullable): an optional #CamelFolder, for which the filter driver will run, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * The optional @for_folder can be used to determine which filters
 * to add and which not.
 *
 * Returns: (transfer none): a filter driver, loaded with applicable rules
 **/
CamelFilterDriver *
camel_session_get_filter_driver (CamelSession *session,
				 const gchar *type,
				 CamelFolder *for_folder,
				 GError **error)
{
	CamelSessionClass *class;
	CamelFilterDriver *driver;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);
	g_return_val_if_fail (type != NULL, NULL);

	class = CAMEL_SESSION_GET_CLASS (session);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_filter_driver != NULL, NULL);

	driver = class->get_filter_driver (session, type, for_folder, error);
	CAMEL_CHECK_GERROR (session, get_filter_driver, driver != NULL, error);

	return driver;
}

/**
 * camel_session_get_junk_filter:
 * @session: a #CamelSession
 *
 * Returns the #CamelJunkFilter instance used to classify messages as
 * junk or not junk during filtering.
 *
 * Note that #CamelJunkFilter itself is just an interface.  The application
 * must implement the interface and install a #CamelJunkFilter instance for
 * junk filtering to take place.
 *
 * Returns: (transfer none): a #CamelJunkFilter, or %NULL
 *
 * Since: 3.2
 **/
CamelJunkFilter *
camel_session_get_junk_filter (CamelSession *session)
{
	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);

	return session->priv->junk_filter;
}

/**
 * camel_session_set_junk_filter:
 * @session: a #CamelSession
 * @junk_filter: a #CamelJunkFilter, or %NULL
 *
 * Installs the #CamelJunkFilter instance used to classify messages as
 * junk or not junk during filtering.
 *
 * Note that #CamelJunkFilter itself is just an interface.  The application
 * must implement the interface and install a #CamelJunkFilter instance for
 * junk filtering to take place.
 *
 * Since: 3.2
 **/
void
camel_session_set_junk_filter (CamelSession *session,
                               CamelJunkFilter *junk_filter)
{
	g_return_if_fail (CAMEL_IS_SESSION (session));

	if (junk_filter != NULL) {
		g_return_if_fail (CAMEL_IS_JUNK_FILTER (junk_filter));
		g_object_ref (junk_filter);
	}

	if (session->priv->junk_filter != NULL)
		g_object_unref (session->priv->junk_filter);

	session->priv->junk_filter = junk_filter;

	g_object_notify (G_OBJECT (session), "junk-filter");
}

/**
 * camel_session_idle_add:
 * @session: a #CamelSession
 * @priority: the priority of the idle source
 * @function: a function to call
 * @data: data to pass to @function
 * @notify: function to call when the idle is removed, or %NULL
 *
 * Adds a function to be called whenever there are no higher priority events
 * pending.  If @function returns %FALSE it is automatically removed from the
 * list of event sources and will not be called again.
 *
 * This internally creates a main loop source using g_idle_source_new()
 * and attaches it to @session's own #CamelSession:main-context using
 * g_source_attach().
 *
 * The @priority is typically in the range between %G_PRIORITY_DEFAULT_IDLE
 * and %G_PRIORITY_HIGH_IDLE.
 *
 * Returns: the ID (greater than 0) of the event source
 *
 * Since: 3.6
 **/
guint
camel_session_idle_add (CamelSession *session,
                        gint priority,
                        GSourceFunc function,
                        gpointer data,
                        GDestroyNotify notify)
{
	GMainContext *main_context;
	GSource *source;
	guint source_id;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), 0);
	g_return_val_if_fail (function != NULL, 0);

	main_context = camel_session_ref_main_context (session);

	source = g_idle_source_new ();

	if (priority != G_PRIORITY_DEFAULT_IDLE)
		g_source_set_priority (source, priority);

	g_source_set_callback (source, function, data, notify);

	source_id = g_source_attach (source, main_context);

	g_source_unref (source);

	g_main_context_unref (main_context);

	return source_id;
}

/**
 * camel_session_submit_job:
 * @session: a #CamelSession
 * @description: human readable description of the job, shown to a user
 * @callback: a #CamelSessionCallback
 * @user_data: user data passed to the callback
 * @notify: a #GDestroyNotify function
 *
 * This function provides a simple mechanism for providers to initiate
 * low-priority background jobs.  Jobs can be submitted from any thread,
 * but execution of the jobs is always as follows:
 *
 * 1) The #CamelSession:job-started signal is emitted from the thread
 *    in which @session was created.  This is typically the same thread
 *    that hosts the global default #GMainContext, or "main" thread.
 *
 * 2) The @callback function is invoked from a different thread where
 *    it's safe to call synchronous functions.
 *
 * 3) Once @callback has returned, the #CamelSesson:job-finished signal
 *    is emitted from the same thread as #CamelSession:job-started was
 *    emitted.
 *
 * 4) Finally if a @notify function was provided, it is invoked and
 *    passed @user_data so that @user_data can be freed.
 *
 * Since: 3.2
 **/
void
camel_session_submit_job (CamelSession *session,
			  const gchar *description,
                          CamelSessionCallback callback,
                          gpointer user_data,
                          GDestroyNotify notify)
{
	JobData *job_data;

	g_return_if_fail (CAMEL_IS_SESSION (session));
	g_return_if_fail (description != NULL);
	g_return_if_fail (callback != NULL);

	job_data = g_slice_new0 (JobData);
	job_data->session = g_object_ref (session);
	job_data->cancellable = camel_operation_new ();
	job_data->callback = callback;
	job_data->user_data = user_data;
	job_data->notify = notify;
	job_data->main_context = NULL;
	job_data->error = NULL;

	camel_operation_push_message (job_data->cancellable, "%s", description);

	camel_session_idle_add (
		session, JOB_PRIORITY,
		session_start_job_cb,
		job_data, (GDestroyNotify) NULL);
}

/**
 * camel_session_set_junk_headers:
 * @session: a #CamelSession
 * @headers: (array length=len):
 * @values: (array):
 * @len: the length of the headers and values arrays
 *
 * Since: 2.22
 **/
void
camel_session_set_junk_headers (CamelSession *session,
                                const gchar **headers,
                                const gchar **values,
                                gint len)
{
	gint i;

	g_return_if_fail (CAMEL_IS_SESSION (session));

	if (session->priv->junk_headers) {
		g_hash_table_remove_all (session->priv->junk_headers);
		g_hash_table_destroy (session->priv->junk_headers);
	}

	session->priv->junk_headers = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);

	for (i = 0; i < len; i++) {
		g_hash_table_insert (session->priv->junk_headers, g_strdup (headers[i]), g_strdup (values[i]));
	}
}

/**
 * camel_session_get_junk_headers:
 * @session: a #CamelSession
 *
 * Returns: (element-type utf8 utf8) (transfer none): Currently used junk
 *    headers as a hash table, previously set by camel_session_set_junk_headers().
 *
 * Since: 2.22
 **/
const GHashTable *
camel_session_get_junk_headers (CamelSession *session)
{
	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);

	return session->priv->junk_headers;
}

/**
 * camel_session_authenticate_sync:
 * @session: a #CamelSession
 * @service: a #CamelService
 * @mechanism: (nullable): a SASL mechanism name, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Authenticates @service, which may involve repeated calls to
 * camel_service_authenticate() or camel_service_authenticate_sync().
 * A #CamelSession subclass is largely responsible for implementing this,
 * and should handle things like user prompts and secure password storage.
 * These issues are out-of-scope for Camel.
 *
 * If an error occurs, or if authentication is aborted, the function sets
 * @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.4
 **/
gboolean
camel_session_authenticate_sync (CamelSession *session,
                                 CamelService *service,
                                 const gchar *mechanism,
                                 GCancellable *cancellable,
                                 GError **error)
{
	CamelSessionClass *class;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), FALSE);
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), FALSE);

	class = CAMEL_SESSION_GET_CLASS (session);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->authenticate_sync != NULL, FALSE);

	success = class->authenticate_sync (
		session, service, mechanism, cancellable, error);
	CAMEL_CHECK_GERROR (session, authenticate_sync, success, error);

	return success;
}

/* Helper for camel_session_authenticate() */
static void
session_authenticate_thread (GTask *task,
                             gpointer source_object,
                             gpointer task_data,
                             GCancellable *cancellable)
{
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	success = camel_session_authenticate_sync (
		CAMEL_SESSION (source_object),
		async_context->service,
		async_context->auth_mechanism,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_session_authenticate:
 * @session: a #CamelSession
 * @service: a #CamelService
 * @mechanism: (nullable): a SASL mechanism name, or %NULL
 * @io_priority: the I/O priority for the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously authenticates @service, which may involve repeated calls
 * to camel_service_authenticate() or camel_service_authenticate_sync().
 * A #CamelSession subclass is largely responsible for implementing this,
 * and should handle things like user prompts and secure password storage.
 * These issues are out-of-scope for Camel.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_session_authenticate_finish() to get the result of
 * the operation.
 *
 * Since: 3.4
 **/
void
camel_session_authenticate (CamelSession *session,
                            CamelService *service,
                            const gchar *mechanism,
                            gint io_priority,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_SESSION (session));
	g_return_if_fail (CAMEL_IS_SERVICE (service));

	async_context = g_slice_new0 (AsyncContext);
	async_context->service = g_object_ref (service);
	async_context->auth_mechanism = g_strdup (mechanism);

	task = g_task_new (session, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_session_authenticate);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, session_authenticate_thread);

	g_object_unref (task);
}

/**
 * camel_session_authenticate_finish:
 * @session: a #CamelSession
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_session_authenticate().
 *
 * If an error occurred, or if authentication was aborted, the function
 * sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.4
 **/
gboolean
camel_session_authenticate_finish (CamelSession *session,
                                   GAsyncResult *result,
                                   GError **error)
{
	g_return_val_if_fail (CAMEL_IS_SESSION (session), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, session), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_session_authenticate), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_session_forward_to_sync:
 * @session: a #CamelSession
 * @folder: the #CamelFolder where @message is located
 * @message: the #CamelMimeMessage to forward
 * @address: the recipient's email address
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Forwards @message in @folder to the email address(es) given by @address.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
camel_session_forward_to_sync (CamelSession *session,
                               CamelFolder *folder,
                               CamelMimeMessage *message,
                               const gchar *address,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelSessionClass *class;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), FALSE);
	g_return_val_if_fail (CAMEL_IS_FOLDER (folder), FALSE);
	g_return_val_if_fail (CAMEL_IS_MIME_MESSAGE (message), FALSE);
	g_return_val_if_fail (address != NULL, FALSE);

	class = CAMEL_SESSION_GET_CLASS (session);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->forward_to_sync != NULL, FALSE);

	success = class->forward_to_sync (
		session, folder, message, address, cancellable, error);
	CAMEL_CHECK_GERROR (session, forward_to_sync, success, error);

	return success;
}

/* Helper for camel_session_forward_to() */
static void
session_forward_to_thread (GTask *task,
                           gpointer source_object,
                           gpointer task_data,
                           GCancellable *cancellable)
{
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	success = camel_session_forward_to_sync (
		CAMEL_SESSION (source_object),
		async_context->folder,
		async_context->message,
		async_context->address,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_session_forward_to:
 * @session: a #CamelSession
 * @folder: the #CamelFolder where @message is located
 * @message: the #CamelMimeMessage to forward
 * @address: the recipient's email address
 * @io_priority: the I/O priority for the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously forwards @message in @folder to the email address(s)
 * given by @address.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_session_forward_to_finish() to get the result of the
 * operation.
 *
 * Since: 3.6
 **/
void
camel_session_forward_to (CamelSession *session,
                          CamelFolder *folder,
                          CamelMimeMessage *message,
                          const gchar *address,
                          gint io_priority,
                          GCancellable *cancellable,
                          GAsyncReadyCallback callback,
                          gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_SESSION (session));
	g_return_if_fail (CAMEL_IS_FOLDER (folder));
	g_return_if_fail (CAMEL_IS_MIME_MESSAGE (message));
	g_return_if_fail (address != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->folder = g_object_ref (folder);
	async_context->message = g_object_ref (message);
	async_context->address = g_strdup (address);

	task = g_task_new (session, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_session_forward_to);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, session_forward_to_thread);

	g_object_unref (task);
}

/**
 * camel_session_forward_to_finish:
 * @session: a #CamelSession
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_session_forward_to().
 *
 * If an error occurred, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
camel_session_forward_to_finish (CamelSession *session,
                                 GAsyncResult *result,
                                 GError **error)
{
	g_return_val_if_fail (CAMEL_IS_SESSION (session), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, session), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_session_forward_to), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_session_get_oauth2_access_token_sync:
 * @session: a #CamelSession
 * @service: a #CamelService
 * @out_access_token: (out) (nullable): return location for the access token, or %NULL
 * @out_expires_in: (out) (nullable): return location for the token expiry, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Obtains the OAuth 2.0 access token for @service along with its expiry
 * in seconds from the current time (or 0 if unknown).
 *
 * Free the returned access token with g_free() when no longer needed.
 *
 * Returns: whether succeeded
 *
 * Since: 3.28
 **/
gboolean
camel_session_get_oauth2_access_token_sync (CamelSession *session,
					    CamelService *service,
					    gchar **out_access_token,
					    gint *out_expires_in,
					    GCancellable *cancellable,
					    GError **error)
{
	CamelSessionClass *klass;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), FALSE);

	klass = CAMEL_SESSION_GET_CLASS (session);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->get_oauth2_access_token_sync != NULL, FALSE);

	return klass->get_oauth2_access_token_sync (session, service, out_access_token, out_expires_in, cancellable, error);
}

/**
 * camel_session_get_recipient_certificates_sync:
 * @session: a #CamelSession
 * @flags: bit-or of #CamelRecipientCertificateFlags
 * @recipients: (element-type utf8): a #GPtrArray of recipients
 * @out_certificates: (element-type utf8) (out): a #GSList of gathered certificates
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Searches for S/MIME certificates or PGP keys for the given @recipients,
 * which are returned as base64 encoded strings in @out_certificates.
 * This is used when encrypting messages. The @flags influence what
 * the @out_certificates will contain. The order of items in @out_certificates
 * should match the order of items in @recipients, with %NULL data for those
 * which could not be found.
 *
 * The function should return failure only if some fatal error happened.
 * It's not an error when certificates for some, or all, recipients
 * could not be found.
 *
 * This method is optional and the default implementation returns %TRUE
 * and sets the @out_certificates to %NULL. It's the only exception
 * when the length of @recipients and @out_certificates can differ.
 * In all other cases the length of the two should match.
 *
 * The @out_certificates will be freed with g_slist_free_full (certificates, g_free);
 * when done with it.
 *
 * Returns: Whether succeeded, or better whether no fatal error happened.
 *
 * Since: 3.30
 **/
gboolean
camel_session_get_recipient_certificates_sync (CamelSession *session,
					       guint32 flags, /* bit-or of CamelRecipientCertificateFlags */
					       const GPtrArray *recipients, /* gchar * */
					       GSList **out_certificates, /* gchar * */
					       GCancellable *cancellable,
					       GError **error)
{
	CamelSessionClass *klass;

	g_return_val_if_fail (CAMEL_IS_SESSION (session), FALSE);
	g_return_val_if_fail (recipients != NULL, FALSE);
	g_return_val_if_fail (out_certificates != NULL, FALSE);

	*out_certificates = NULL;

	klass = CAMEL_SESSION_GET_CLASS (session);
	g_return_val_if_fail (klass != NULL, FALSE);

	if (!klass->get_recipient_certificates_sync)
		return TRUE;

	return klass->get_recipient_certificates_sync (session, flags, recipients, out_certificates, cancellable, error);
}
