/*
 * e-client.c
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

/* TODO The next time we have a good excuse to break libedataserver's API,
 *      I'd like to purge all the deprecated cruft here and convert EClient
 *      from a GObjectClass to a GTypeInterface, implemented by EBookClient
 *      and ECalClient.  Then we could just bind the "online", "readonly"
 *      and "capabilities" properties to equivalent GDBusProxy properties
 *      and kill e-client-private.h.  Would simplify things.  --mbarnes
 */

/**
 * SECTION: e-client
 * @include: libedataserver/libedataserver.h
 * @short_description: Base class for client handles
 *
 * This class provides some base functionality for clients
 * such as #EBookClient and #ECalClient.
 **/

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>
#include <gio/gio.h>

#include <libedataserver/e-data-server-util.h>

#include "e-flag.h"

#include "e-client.h"
#include "e-client-private.h"

#define E_CLIENT_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_CLIENT, EClientPrivate))

typedef struct _AsyncContext AsyncContext;

struct _EClientPrivate {
	GRecMutex prop_mutex;

	ESource *source;
	gboolean online;
	gboolean readonly;
	GSList *capabilities;
	GMainContext *main_context;
	gchar *bus_name;
};

struct _AsyncContext {
	gchar *capabilities;
	gchar *prop_name;
	gchar *prop_value;
	gboolean only_if_exists;
};

enum {
	PROP_0,
	PROP_CAPABILITIES,
	PROP_MAIN_CONTEXT,
	PROP_ONLINE,
	PROP_OPENED,
	PROP_READONLY,
	PROP_SOURCE
};

enum {
	OPENED,
	BACKEND_ERROR,
	BACKEND_DIED,
	BACKEND_PROPERTY_CHANGED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_ABSTRACT_TYPE (EClient, e_client, G_TYPE_OBJECT)

static void
async_context_free (AsyncContext *async_context)
{
	g_free (async_context->capabilities);
	g_free (async_context->prop_name);
	g_free (async_context->prop_value);

	g_slice_free (AsyncContext, async_context);
}

/*
 * Well-known client backend properties, which are common for each #EClient:
 * @CLIENT_BACKEND_PROPERTY_OPENED: Is set to "TRUE" or "FALSE" depending
 *   whether the backend is fully opened.
 * @CLIENT_BACKEND_PROPERTY_OPENING: Is set to "TRUE" or "FALSE" depending
 *   whether the backend is processing its opening phase.
 * @CLIENT_BACKEND_PROPERTY_ONLINE: Is set to "TRUE" or "FALSE" depending
 *   on the backend's loaded state. See also e_client_is_online().
 * @CLIENT_BACKEND_PROPERTY_READONLY: Is set to "TRUE" or "FALSE" depending
 *   on the backend's readonly state. See also e_client_is_readonly().
 * @CLIENT_BACKEND_PROPERTY_CACHE_DIR: Local folder with cached data used
 *   by the backend.
 * @CLIENT_BACKEND_PROPERTY_CAPABILITIES: Retrieves comma-separated list
 *   of	capabilities supported by the backend. Preferred method of retreiving
 *   and working with capabilities is e_client_get_capabilities() and
 *   e_client_check_capability().
 */

G_DEFINE_QUARK (e-client-error-quark, e_client_error)

/**
 * e_client_error_to_string:
 * @code: an #EClientError error code
 *
 * Get localized human readable description of the given error code.
 *
 * Returns: Localized human readable description of the given error code
 *
 * Since: 3.2
 **/
const gchar *
e_client_error_to_string (EClientError code)
{
	switch (code) {
	case E_CLIENT_ERROR_INVALID_ARG:
		return _("Invalid argument");
	case E_CLIENT_ERROR_BUSY:
		return _("Backend is busy");
	case E_CLIENT_ERROR_SOURCE_NOT_LOADED:
		return _("Source not loaded");
	case E_CLIENT_ERROR_SOURCE_ALREADY_LOADED:
		return _("Source already loaded");
	case E_CLIENT_ERROR_AUTHENTICATION_FAILED:
		return _("Authentication failed");
	case E_CLIENT_ERROR_AUTHENTICATION_REQUIRED:
		return _("Authentication required");
	case E_CLIENT_ERROR_REPOSITORY_OFFLINE:
		return _("Repository offline");
	case E_CLIENT_ERROR_OFFLINE_UNAVAILABLE:
		/* Translators: This means that the EClient does not
		 * support offline mode, or it's not set to by a user,
		 * thus it is unavailable while user is not connected. */
		return _("Offline unavailable");
	case E_CLIENT_ERROR_PERMISSION_DENIED:
		return _("Permission denied");
	case E_CLIENT_ERROR_CANCELLED:
		return _("Cancelled");
	case E_CLIENT_ERROR_COULD_NOT_CANCEL:
		return _("Could not cancel");
	case E_CLIENT_ERROR_NOT_SUPPORTED:
		return _("Not supported");
	case E_CLIENT_ERROR_UNSUPPORTED_AUTHENTICATION_METHOD:
		return _("Unsupported authentication method");
	case E_CLIENT_ERROR_TLS_NOT_AVAILABLE:
		return _("TLS not available");
	case E_CLIENT_ERROR_SEARCH_SIZE_LIMIT_EXCEEDED:
		return _("Search size limit exceeded");
	case E_CLIENT_ERROR_SEARCH_TIME_LIMIT_EXCEEDED:
		return _("Search time limit exceeded");
	case E_CLIENT_ERROR_INVALID_QUERY:
		return _("Invalid query");
	case E_CLIENT_ERROR_QUERY_REFUSED:
		return _("Query refused");
	case E_CLIENT_ERROR_DBUS_ERROR:
		return _("D-Bus error");
	case E_CLIENT_ERROR_OTHER_ERROR:
		return _("Other error");
	case E_CLIENT_ERROR_NOT_OPENED:
		return _("Backend is not opened yet");
	case E_CLIENT_ERROR_OUT_OF_SYNC:
		return _("Object is out of sync");
	}

	return _("Unknown error");
}

/**
 * e_client_error_create:
 * @code: an #EClientError code to create
 * @custom_msg: custom message to use for the error; can be %NULL
 *
 * Returns: a new #GError containing an E_CLIENT_ERROR of the given
 * @code. If the @custom_msg is NULL, then the error message is
 * the one returned from e_client_error_to_string() for the @code,
 * otherwise the given message is used.
 *
 * Returned pointer should be freed with g_error_free().
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Just use the #GError API directly.
 **/
GError *
e_client_error_create (EClientError code,
                       const gchar *custom_msg)
{
	if (custom_msg == NULL)
		custom_msg = e_client_error_to_string (code);

	return g_error_new_literal (E_CLIENT_ERROR, code, custom_msg);
}

static void
client_set_source (EClient *client,
                   ESource *source)
{
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (client->priv->source == NULL);

	client->priv->source = g_object_ref (source);
}

static void
client_set_property (GObject *object,
                     guint property_id,
                     const GValue *value,
                     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ONLINE:
			e_client_set_online (
				E_CLIENT (object),
				g_value_get_boolean (value));
			return;

		case PROP_SOURCE:
			client_set_source (
				E_CLIENT (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
client_get_property (GObject *object,
                     guint property_id,
                     GValue *value,
                     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CAPABILITIES:
			g_value_set_pointer (
				value,
				(gpointer) e_client_get_capabilities (
				E_CLIENT (object)));
			return;

		case PROP_MAIN_CONTEXT:
			g_value_take_boxed (
				value,
				e_client_ref_main_context (
				E_CLIENT (object)));
			return;

		case PROP_ONLINE:
			g_value_set_boolean (
				value,
				e_client_is_online (
				E_CLIENT (object)));
			return;

		case PROP_OPENED:
			g_value_set_boolean (
				value,
				e_client_is_opened (
				E_CLIENT (object)));
			return;

		case PROP_READONLY:
			g_value_set_boolean (
				value,
				e_client_is_readonly (
				E_CLIENT (object)));
			return;

		case PROP_SOURCE:
			g_value_set_object (
				value,
				e_client_get_source (
				E_CLIENT (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
client_dispose (GObject *object)
{
	EClientPrivate *priv;

	priv = E_CLIENT_GET_PRIVATE (object);

	if (priv->main_context != NULL) {
		g_main_context_unref (priv->main_context);
		priv->main_context = NULL;
	}

	g_clear_object (&priv->source);

	g_free (priv->bus_name);
	priv->bus_name = NULL;

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_client_parent_class)->dispose (object);
}

static void
client_finalize (GObject *object)
{
	EClientPrivate *priv;

	priv = E_CLIENT_GET_PRIVATE (object);

	g_slist_free_full (priv->capabilities, (GDestroyNotify) g_free);

	g_rec_mutex_clear (&priv->prop_mutex);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_client_parent_class)->finalize (object);
}

static void
client_unwrap_dbus_error (EClient *client,
                          GError *dbus_error,
                          GError **out_error)
{
	/* This method is deprecated.  Make it a no-op. */

	if (out_error != NULL)
		*out_error = dbus_error;
}

/* Helper for client_retrieve_capabilities() */
static void
client_retrieve_capabilities_thread (GSimpleAsyncResult *simple,
                                     GObject *source_object,
                                     GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	e_client_retrieve_capabilities_sync (
		E_CLIENT (source_object),
		&async_context->capabilities,
		cancellable, &error);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);
}

static void
client_retrieve_capabilities (EClient *client,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	async_context = g_slice_new0 (AsyncContext);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback,
		user_data, client_retrieve_capabilities);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, client_retrieve_capabilities_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

static gboolean
client_retrieve_capabilities_finish (EClient *client,
                                     GAsyncResult *result,
                                     gchar **capabilities,
                                     GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		client_retrieve_capabilities), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->capabilities != NULL, FALSE);

	if (capabilities != NULL) {
		*capabilities = async_context->capabilities;
		async_context->capabilities = NULL;
	}

	return TRUE;
}

static gboolean
client_retrieve_capabilities_sync (EClient *client,
                                   gchar **capabilities,
                                   GCancellable *cancellable,
                                   GError **error)
{
	return e_client_get_backend_property_sync (
		client, CLIENT_BACKEND_PROPERTY_CAPABILITIES,
		capabilities, cancellable, error);
}

/* Helper for client_get_backend_property() */
static void
client_get_backend_property_thread (GSimpleAsyncResult *simple,
                                    GObject *source_object,
                                    GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	e_client_get_backend_property_sync (
		E_CLIENT (source_object),
		async_context->prop_name,
		&async_context->prop_value,
		cancellable, &error);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);
}

static void
client_get_backend_property (EClient *client,
                             const gchar *prop_name,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	async_context = g_slice_new0 (AsyncContext);
	async_context->prop_name = g_strdup (prop_name);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback,
		user_data, client_get_backend_property);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, client_get_backend_property_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

static gboolean
client_get_backend_property_finish (EClient *client,
                                    GAsyncResult *result,
                                    gchar **prop_value,
                                    GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		client_get_backend_property), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->prop_value != NULL, FALSE);

	if (prop_value != NULL) {
		*prop_value = async_context->prop_value;
		async_context->prop_value = NULL;
	}

	return TRUE;
}

/* Helper for client_set_backend_property() */
static void
client_set_backend_property_thread (GSimpleAsyncResult *simple,
                                    GObject *source_object,
                                    GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	e_client_set_backend_property_sync (
		E_CLIENT (source_object),
		async_context->prop_name,
		async_context->prop_value,
		cancellable, &error);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);
}

static void
client_set_backend_property (EClient *client,
                             const gchar *prop_name,
                             const gchar *prop_value,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	async_context = g_slice_new0 (AsyncContext);
	async_context->prop_name = g_strdup (prop_name);
	async_context->prop_value = g_strdup (prop_value);

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback,
		user_data, client_set_backend_property);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, client_set_backend_property_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

static gboolean
client_set_backend_property_finish (EClient *client,
                                    GAsyncResult *result,
                                    GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client),
		client_set_backend_property), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/* Helper for client_open() */
static void
client_open_thread (GSimpleAsyncResult *simple,
                    GObject *source_object,
                    GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	e_client_open_sync (
		E_CLIENT (source_object),
		async_context->only_if_exists,
		cancellable, &error);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);
}

static void
client_open (EClient *client,
             gboolean only_if_exists,
             GCancellable *cancellable,
             GAsyncReadyCallback callback,
             gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	async_context = g_slice_new0 (AsyncContext);
	async_context->only_if_exists = only_if_exists;

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data, client_open);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, client_open_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

static gboolean
client_open_finish (EClient *client,
                    GAsyncResult *result,
                    GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client), client_open), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/* Helper for client_remove() */
static void
client_remove_thread (GSimpleAsyncResult *simple,
                      GObject *source_object,
                      GCancellable *cancellable)
{
	GError *error = NULL;

	e_client_remove_sync (
		E_CLIENT (source_object), cancellable, &error);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);
}

static void
client_remove (EClient *client,
               GCancellable *cancellable,
               GAsyncReadyCallback callback,
               gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data, client_remove);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_run_in_thread (
		simple, client_remove_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

static gboolean
client_remove_finish (EClient *client,
                      GAsyncResult *result,
                      GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client), client_remove), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static gboolean
client_remove_sync (EClient *client,
                    GCancellable *cancellable,
                    GError **error)
{
	ESource *source;

	source = e_client_get_source (client);

	return e_source_remove_sync (source, cancellable, error);
}

/* Helper for client_refresh() */
static void
client_refresh_thread (GSimpleAsyncResult *simple,
                       GObject *source_object,
                       GCancellable *cancellable)
{
	GError *error = NULL;

	e_client_refresh_sync (
		E_CLIENT (source_object), cancellable, &error);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);
}

static void
client_refresh (EClient *client,
                GCancellable *cancellable,
                GAsyncReadyCallback callback,
                gpointer user_data)
{
	GSimpleAsyncResult *simple;

	simple = g_simple_async_result_new (
		G_OBJECT (client), callback, user_data, client_refresh);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_run_in_thread (
		simple, client_refresh_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

static gboolean
client_refresh_finish (EClient *client,
                       GAsyncResult *result,
                       GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (client), client_refresh), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

static void
e_client_class_init (EClientClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EClientPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = client_set_property;
	object_class->get_property = client_get_property;
	object_class->dispose = client_dispose;
	object_class->finalize = client_finalize;

	class->unwrap_dbus_error = client_unwrap_dbus_error;
	class->retrieve_capabilities = client_retrieve_capabilities;
	class->retrieve_capabilities_finish = client_retrieve_capabilities_finish;
	class->retrieve_capabilities_sync = client_retrieve_capabilities_sync;
	class->get_backend_property = client_get_backend_property;
	class->get_backend_property_finish = client_get_backend_property_finish;
	class->set_backend_property = client_set_backend_property;
	class->set_backend_property_finish = client_set_backend_property_finish;
	class->open = client_open;
	class->open_finish = client_open_finish;
	class->remove = client_remove;
	class->remove_finish = client_remove_finish;
	class->remove_sync = client_remove_sync;
	class->refresh = client_refresh;
	class->refresh_finish = client_refresh_finish;

	/**
	 * EClient:capabilities:
	 *
	 * The capabilities of this client
	 */
	g_object_class_install_property (
		object_class,
		PROP_CAPABILITIES,
		g_param_spec_pointer (
			"capabilities",
			"Capabilities",
			"The capabilities of this client",
			G_PARAM_READABLE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * EClient:main-context:
	 *
	 * The main loop context in which notifications for
	 * this client will be delivered.
	 */
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

	/**
	 * EClient:online:
	 *
	 * Whether this client's backing data is online.
	 */
	g_object_class_install_property (
		object_class,
		PROP_ONLINE,
		g_param_spec_boolean (
			"online",
			"Online",
			"Whether this client is online",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * EClient:opened:
	 *
	 * Whether this client is open and ready to use.
	 *
	 * Deprecated: 3.8: This property is no longer relevant and
	 * will always be %TRUE after successfully creating any concrete
	 * type of #EClient.
	 */
	g_object_class_install_property (
		object_class,
		PROP_OPENED,
		g_param_spec_boolean (
			"opened",
			"Opened",
			"Whether this client is open and ready to use",
			FALSE,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	/**
	 * EClient:readonly:
	 *
	 * Whether this client's backing data is readonly.
	 */
	g_object_class_install_property (
		object_class,
		PROP_READONLY,
		g_param_spec_boolean (
			"readonly",
			"Read only",
			"Whether this client's backing data is readonly",
			FALSE,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	/**
	 * EClient:source:
	 *
	 * The #ESource for which this client was created.
	 */
	g_object_class_install_property (
		object_class,
		PROP_SOURCE,
		g_param_spec_object (
			"source",
			"Source",
			"The ESource for which this client was created",
			E_TYPE_SOURCE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * EClient:opened-signal: (skip)
	 *
	 * Deprecated: 3.8: This signal is no longer emitted.
	 **/
	signals[OPENED] = g_signal_new (
		"opened",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_LAST |
		G_SIGNAL_DEPRECATED,
		G_STRUCT_OFFSET (EClientClass, opened),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_ERROR);

	signals[BACKEND_ERROR] = g_signal_new (
		"backend-error",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (EClientClass, backend_error),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_STRING);

	signals[BACKEND_DIED] = g_signal_new (
		"backend-died",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EClientClass, backend_died),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);

	signals[BACKEND_PROPERTY_CHANGED] = g_signal_new (
		"backend-property-changed",
		G_OBJECT_CLASS_TYPE (class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EClientClass, backend_property_changed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 2,
		G_TYPE_STRING,
		G_TYPE_STRING);
}

static void
e_client_init (EClient *client)
{
	client->priv = E_CLIENT_GET_PRIVATE (client);

	client->priv->readonly = FALSE;
	client->priv->main_context = g_main_context_ref_thread_default ();

	g_rec_mutex_init (&client->priv->prop_mutex);
}

/**
 * e_client_get_source:
 * @client: an #EClient
 *
 * Get the #ESource that this client has assigned.
 *
 * Returns: (transfer none): The source.
 *
 * Since: 3.2
 **/
ESource *
e_client_get_source (EClient *client)
{
	g_return_val_if_fail (E_IS_CLIENT (client), NULL);

	return client->priv->source;
}

static void
client_ensure_capabilities (EClient *client)
{
	gchar *capabilities = NULL;

	g_return_if_fail (E_IS_CLIENT (client));

	if (client->priv->capabilities != NULL)
		return;

	/* Despite appearances this function does not actually block. */
	e_client_get_backend_property_sync (
		client, CLIENT_BACKEND_PROPERTY_CAPABILITIES,
		&capabilities, NULL, NULL);
	e_client_set_capabilities (client, capabilities);
	g_free (capabilities);
}

/**
 * e_client_get_capabilities:
 * @client: an #EClient
 *
 * Get list of strings with capabilities advertised by a backend.
 * This list, together with inner strings, is owned by the @client.
 * To check for individual capabilities use e_client_check_capability().
 *
 * Returns: (element-type utf8) (transfer none): #GSList of const strings
 *          of capabilities
 *
 * Since: 3.2
 **/
const GSList *
e_client_get_capabilities (EClient *client)
{
	g_return_val_if_fail (E_IS_CLIENT (client), NULL);

	client_ensure_capabilities (client);

	return client->priv->capabilities;
}

/**
 * e_client_ref_main_context:
 * @client: an #EClient
 *
 * Returns the #GMainContext on which event sources for @client are to
 * be attached.
 *
 * The returned #GMainContext is referenced for thread-safety and must be
 * unreferenced with g_main_context_unref() when finished with it.
 *
 * Returns: (transfer full): a #GMainContext
 *
 * Since: 3.8
 **/
GMainContext *
e_client_ref_main_context (EClient *client)
{
	g_return_val_if_fail (E_IS_CLIENT (client), NULL);

	return g_main_context_ref (client->priv->main_context);
}

/**
 * e_client_check_capability:
 * @client: an #EClient
 * @capability: a capability
 *
 * Check if backend supports particular capability.
 * To get all capabilities use e_client_get_capabilities().
 *
 * Returns: #GSList of const strings of capabilities
 *
 * Since: 3.2
 **/
gboolean
e_client_check_capability (EClient *client,
                           const gchar *capability)
{
	GSList *iter;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);
	g_return_val_if_fail (capability, FALSE);

	g_rec_mutex_lock (&client->priv->prop_mutex);

	client_ensure_capabilities (client);

	for (iter = client->priv->capabilities; iter; iter = g_slist_next (iter)) {
		const gchar *cap = iter->data;

		if (cap && g_ascii_strcasecmp (cap, capability) == 0) {
			g_rec_mutex_unlock (&client->priv->prop_mutex);
			return TRUE;
		}
	}

	g_rec_mutex_unlock (&client->priv->prop_mutex);

	return FALSE;
}

/**
 * e_client_check_refresh_supported:
 * @client: A client.
 *
 * Checks whether a client supports explicit refreshing
 * (see e_client_refresh()).
 *
 * Returns: TRUE if the client supports refreshing, FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_client_check_refresh_supported (EClient *client)
{
	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);

	return e_client_check_capability (client, "refresh-supported");
}

/* capabilities - comma-separated list of capabilities; can be NULL to unset */
void
e_client_set_capabilities (EClient *client,
                           const gchar *capabilities)
{
	g_return_if_fail (E_IS_CLIENT (client));

	g_rec_mutex_lock (&client->priv->prop_mutex);

	g_slist_foreach (client->priv->capabilities, (GFunc) g_free, NULL);
	g_slist_free (client->priv->capabilities);
	client->priv->capabilities = e_client_util_parse_comma_strings (capabilities);

	g_rec_mutex_unlock (&client->priv->prop_mutex);

	g_object_notify (G_OBJECT (client), "capabilities");
}

/**
 * e_client_is_readonly:
 * @client: an #EClient
 *
 * Check if this @client is read-only.
 *
 * Returns: %TRUE if this @client is read-only, otherwise %FALSE.
 *
 * Since: 3.2
 **/
gboolean
e_client_is_readonly (EClient *client)
{
	g_return_val_if_fail (E_IS_CLIENT (client), TRUE);

	return client->priv->readonly;
}

void
e_client_set_readonly (EClient *client,
                       gboolean readonly)
{
	g_return_if_fail (E_IS_CLIENT (client));

	g_rec_mutex_lock (&client->priv->prop_mutex);
	if (client->priv->readonly == readonly) {
		g_rec_mutex_unlock (&client->priv->prop_mutex);
		return;
	}

	client->priv->readonly = readonly;

	g_rec_mutex_unlock (&client->priv->prop_mutex);

	g_object_notify (G_OBJECT (client), "readonly");
}

/**
 * e_client_is_online:
 * @client: an #EClient
 *
 * Check if this @client is connected.
 *
 * Returns: %TRUE if this @client is connected, otherwise %FALSE.
 *
 * Since: 3.2
 **/
gboolean
e_client_is_online (EClient *client)
{
	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);

	return client->priv->online;
}

void
e_client_set_online (EClient *client,
                     gboolean is_online)
{
	g_return_if_fail (E_IS_CLIENT (client));

	/* newly connected/disconnected => make sure capabilities will be correct */
	e_client_set_capabilities (client, NULL);

	g_rec_mutex_lock (&client->priv->prop_mutex);
	if (client->priv->online == is_online) {
		g_rec_mutex_unlock (&client->priv->prop_mutex);
		return;
	}

	client->priv->online = is_online;

	g_rec_mutex_unlock (&client->priv->prop_mutex);

	g_object_notify (G_OBJECT (client), "online");
}

/**
 * e_client_is_opened:
 * @client: an #EClient
 *
 * Check if this @client is fully opened. This includes
 * everything from e_client_open() call up to the authentication,
 * if required by a backend. Client cannot do any other operation
 * during the opening phase except of authenticate or cancel it.
 * Every other operation results in an %E_CLIENT_ERROR_BUSY error.
 *
 * Returns: always %TRUE
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Clients don't need to care if they're fully opened
 *                  anymore.  This function always returns %TRUE.
 **/
gboolean
e_client_is_opened (EClient *client)
{
	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);

	return TRUE;
}

/**
 * e_client_cancel_all:
 * @client: an #EClient
 *
 * Cancels all pending operations started on @client.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: The function no longer does anything.
 **/
void
e_client_cancel_all (EClient *client)
{
	/* Do nothing. */
}

/**
 * e_client_retrieve_capabilities:
 * @client: an #EClient
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Initiates retrieval of capabilities on the @client. This is usually
 * required only once, after the @client is opened. The returned value
 * is cached and any subsequent call of e_client_get_capabilities() and
 * e_client_check_capability() is using the cached value.
 * The call is finished by e_client_retrieve_capabilities_finish()
 * from the @callback.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use e_client_get_capabilities() instead.
 **/
void
e_client_retrieve_capabilities (EClient *client,
                                GCancellable *cancellable,
                                GAsyncReadyCallback callback,
                                gpointer user_data)
{
	EClientClass *class;

	g_return_if_fail (E_IS_CLIENT (client));
	g_return_if_fail (callback != NULL);

	class = E_CLIENT_GET_CLASS (client);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->retrieve_capabilities != NULL);

	class->retrieve_capabilities (client, cancellable, callback, user_data);
}

/**
 * e_client_retrieve_capabilities_finish:
 * @client: an #EClient
 * @result: a #GAsyncResult
 * @capabilities: (out): Comma-separated list of capabilities of the @client
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_client_retrieve_capabilities().
 * Returned value of @capabilities should be freed with g_free(),
 * when no longer needed.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use e_client_get_capabilities() instead.
 **/
gboolean
e_client_retrieve_capabilities_finish (EClient *client,
                                       GAsyncResult *result,
                                       gchar **capabilities,
                                       GError **error)
{
	EClientClass *class;
	gboolean res;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);
	g_return_val_if_fail (capabilities != NULL, FALSE);

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->retrieve_capabilities_finish != NULL, FALSE);

	*capabilities = NULL;
	res = class->retrieve_capabilities_finish (
		client, result, capabilities, error);

	e_client_set_capabilities (client, res ? *capabilities : NULL);

	return res;
}

/**
 * e_client_retrieve_capabilities_sync:
 * @client: an #EClient
 * @capabilities: (out): Comma-separated list of capabilities of the @client
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Initiates retrieval of capabilities on the @client. This is usually
 * required only once, after the @client is opened. The returned value
 * is cached and any subsequent call of e_client_get_capabilities() and
 * e_client_check_capability() is using the cached value. Returned value
 * of @capabilities should be freed with g_free(), when no longer needed.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use e_client_get_capabilities() instead.
 **/
gboolean
e_client_retrieve_capabilities_sync (EClient *client,
                                     gchar **capabilities,
                                     GCancellable *cancellable,
                                     GError **error)
{
	EClientClass *class;
	gboolean res = FALSE;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);
	g_return_val_if_fail (capabilities != NULL, FALSE);

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->retrieve_capabilities_sync != NULL, FALSE);

	*capabilities = NULL;
	res = class->retrieve_capabilities_sync (
		client, capabilities, cancellable, error);

	e_client_set_capabilities (client, res ? *capabilities : NULL);

	return res;
}

/**
 * e_client_get_backend_property:
 * @client: an #EClient
 * @prop_name: property name, whose value to retrieve; cannot be %NULL
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Queries @client's backend for a property of name @prop_name.
 * The call is finished by e_client_get_backend_property_finish()
 * from the @callback.
 *
 * Since: 3.2
 **/
void
e_client_get_backend_property (EClient *client,
                               const gchar *prop_name,
                               GCancellable *cancellable,
                               GAsyncReadyCallback callback,
                               gpointer user_data)
{
	EClientClass *class;

	g_return_if_fail (callback != NULL);
	g_return_if_fail (E_IS_CLIENT (client));
	g_return_if_fail (prop_name != NULL);

	class = E_CLIENT_GET_CLASS (client);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->get_backend_property != NULL);

	class->get_backend_property (
		client, prop_name, cancellable, callback, user_data);
}

/**
 * e_client_get_backend_property_finish:
 * @client: an #EClient
 * @result: a #GAsyncResult
 * @prop_value: (out): Retrieved backend property value; cannot be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_client_get_backend_property().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_client_get_backend_property_finish (EClient *client,
                                      GAsyncResult *result,
                                      gchar **prop_value,
                                      GError **error)
{
	EClientClass *class;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);
	g_return_val_if_fail (prop_value != NULL, FALSE);

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->get_backend_property_finish != NULL, FALSE);

	return class->get_backend_property_finish (
		client, result, prop_value, error);
}

/**
 * e_client_get_backend_property_sync:
 * @client: an #EClient
 * @prop_name: property name, whose value to retrieve; cannot be %NULL
 * @prop_value: (out): Retrieved backend property value; cannot be %NULL
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Queries @client's backend for a property of name @prop_name.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_client_get_backend_property_sync (EClient *client,
                                    const gchar *prop_name,
                                    gchar **prop_value,
                                    GCancellable *cancellable,
                                    GError **error)
{
	EClientClass *class;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);
	g_return_val_if_fail (prop_name != NULL, FALSE);
	g_return_val_if_fail (prop_value != NULL, FALSE);

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->get_backend_property_sync != NULL, FALSE);

	return class->get_backend_property_sync (
		client, prop_name, prop_value, cancellable, error);
}

/**
 * e_client_set_backend_property:
 * @client: an #EClient
 * @prop_name: property name, whose value to change; cannot be %NULL
 * @prop_value: property value, to set; cannot be %NULL
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Sets @client's backend property of name @prop_name
 * to value @prop_value. The call is finished
 * by e_client_set_backend_property_finish() from the @callback.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Clients cannot set backend properties.  Any attempt
 *                  will fail with an %E_CLIENT_ERROR_NOT_SUPPORTED error.
 **/
void
e_client_set_backend_property (EClient *client,
                               const gchar *prop_name,
                               const gchar *prop_value,
                               GCancellable *cancellable,
                               GAsyncReadyCallback callback,
                               gpointer user_data)
{
	EClientClass *class;

	g_return_if_fail (callback != NULL);
	g_return_if_fail (E_IS_CLIENT (client));
	g_return_if_fail (prop_name != NULL);
	g_return_if_fail (prop_value != NULL);

	class = E_CLIENT_GET_CLASS (client);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->set_backend_property != NULL);

	class->set_backend_property (
		client, prop_name, prop_value,
		cancellable, callback, user_data);
}

/**
 * e_client_set_backend_property_finish:
 * @client: an #EClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_client_set_backend_property().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Clients cannot set backend properties.  Any attempt
 *                  will fail with an %E_CLIENT_ERROR_NOT_SUPPORTED error.
 **/
gboolean
e_client_set_backend_property_finish (EClient *client,
                                      GAsyncResult *result,
                                      GError **error)
{
	EClientClass *class;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->set_backend_property_finish != NULL, FALSE);

	return class->set_backend_property_finish (client, result, error);
}

/**
 * e_client_set_backend_property_sync:
 * @client: an #EClient
 * @prop_name: property name, whose value to change; cannot be %NULL
 * @prop_value: property value, to set; cannot be %NULL
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Sets @client's backend property of name @prop_name
 * to value @prop_value.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Clients cannot set backend properties.  Any attempt
 *                  will fail with an %E_CLIENT_ERROR_NOT_SUPPORTED error.
 **/
gboolean
e_client_set_backend_property_sync (EClient *client,
                                    const gchar *prop_name,
                                    const gchar *prop_value,
                                    GCancellable *cancellable,
                                    GError **error)
{
	EClientClass *class;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);
	g_return_val_if_fail (prop_name != NULL, FALSE);
	g_return_val_if_fail (prop_value != NULL, FALSE);

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->set_backend_property_sync != NULL, FALSE);

	return class->set_backend_property_sync (
		client, prop_name, prop_value, cancellable, error);
}

/**
 * e_client_open:
 * @client: an #EClient
 * @only_if_exists: if %TRUE, fail if this book doesn't already exist,
 *                  otherwise create it first
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Opens the @client, making it ready for queries and other operations.
 * The call is finished by e_client_open_finish() from the @callback.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use e_book_client_connect() and
 *                  e_book_client_connect_finish() or
 *                  e_cal_client_connect() and
 *                  e_cal_client_connect_finish() instead.
 **/
void
e_client_open (EClient *client,
               gboolean only_if_exists,
               GCancellable *cancellable,
               GAsyncReadyCallback callback,
               gpointer user_data)
{
	EClientClass *class;

	g_return_if_fail (callback != NULL);
	g_return_if_fail (E_IS_CLIENT (client));

	class = E_CLIENT_GET_CLASS (client);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->open != NULL);

	class->open (client, only_if_exists, cancellable, callback, user_data);
}

/**
 * e_client_open_finish:
 * @client: an #EClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_client_open().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use e_book_client_connect() and
 *                  e_book_client_connect_finish() or
 *                  e_cal_client_connect() and
 *                  e_cal_client_connect_finish() instead.
 **/
gboolean
e_client_open_finish (EClient *client,
                      GAsyncResult *result,
                      GError **error)
{
	EClientClass *class;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->open_finish != NULL, FALSE);

	return class->open_finish (client, result, error);
}

/**
 * e_client_open_sync:
 * @client: an #EClient
 * @only_if_exists: if %TRUE, fail if this book doesn't already exist,
 *                  otherwise create it first
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Opens the @client, making it ready for queries and other operations.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use e_book_client_connect_sync() or
 *                  e_cal_client_connect_sync() instead.
 **/
gboolean
e_client_open_sync (EClient *client,
                    gboolean only_if_exists,
                    GCancellable *cancellable,
                    GError **error)
{
	EClientClass *class;

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->open_sync != NULL, FALSE);

	return class->open_sync (client, only_if_exists, cancellable, error);
}

/**
 * e_client_remove:
 * @client: an #EClient
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Removes the backing data for this #EClient. For example, with the file
 * backend this deletes the database file. You cannot get it back!
 * The call is finished by e_client_remove_finish() from the @callback.
 *
 * Since: 3.2
 *
 * Deprecated: 3.6: Use e_source_remove() instead.
 **/
void
e_client_remove (EClient *client,
                 GCancellable *cancellable,
                 GAsyncReadyCallback callback,
                 gpointer user_data)
{
	EClientClass *class;

	g_return_if_fail (E_IS_CLIENT (client));
	g_return_if_fail (callback != NULL);

	class = E_CLIENT_GET_CLASS (client);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->remove != NULL);

	class->remove (client, cancellable, callback, user_data);
}

/**
 * e_client_remove_finish:
 * @client: an #EClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_client_remove().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 *
 * Deprecated: 3.6: Use e_source_remove_finish() instead.
 **/
gboolean
e_client_remove_finish (EClient *client,
                        GAsyncResult *result,
                        GError **error)
{
	EClientClass *class;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->remove_finish != NULL, FALSE);

	return class->remove_finish (client, result, error);
}

/**
 * e_client_remove_sync:
 * @client: an #EClient
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Removes the backing data for this #EClient. For example, with the file
 * backend this deletes the database file. You cannot get it back!
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 *
 * Deprecated: 3.6: Use e_source_remove_sync() instead.
 **/
gboolean
e_client_remove_sync (EClient *client,
                      GCancellable *cancellable,
                      GError **error)
{
	EClientClass *class;

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->remove_sync != NULL, FALSE);

	return class->remove_sync (client, cancellable, error);
}

/**
 * e_client_refresh:
 * @client: an #EClient
 * @cancellable: a #GCancellable; can be %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Initiates refresh on the @client. Finishing the method doesn't mean
 * that the refresh is done, backend only notifies whether it started
 * refreshing or not. Use e_client_check_refresh_supported() to check
 * whether the backend supports this method.
 * The call is finished by e_client_refresh_finish() from the @callback.
 *
 * Since: 3.2
 **/
void
e_client_refresh (EClient *client,
                  GCancellable *cancellable,
                  GAsyncReadyCallback callback,
                  gpointer user_data)
{
	EClientClass *class;

	g_return_if_fail (E_IS_CLIENT (client));
	g_return_if_fail (callback != NULL);

	class = E_CLIENT_GET_CLASS (client);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->refresh != NULL);

	class->refresh (client, cancellable, callback, user_data);
}

/**
 * e_client_refresh_finish:
 * @client: an #EClient
 * @result: a #GAsyncResult
 * @error: (out): a #GError to set an error, if any
 *
 * Finishes previous call of e_client_refresh().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_client_refresh_finish (EClient *client,
                         GAsyncResult *result,
                         GError **error)
{
	EClientClass *class;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->refresh_finish != NULL, FALSE);

	return class->refresh_finish (client, result, error);
}

/**
 * e_client_refresh_sync:
 * @client: an #EClient
 * @cancellable: a #GCancellable; can be %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Initiates refresh on the @client. Finishing the method doesn't mean
 * that the refresh is done, backend only notifies whether it started
 * refreshing or not. Use e_client_check_refresh_supported() to check
 * whether the backend supports this method.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_client_refresh_sync (EClient *client,
                       GCancellable *cancellable,
                       GError **error)
{
	EClientClass *class;

	class = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->refresh_sync != NULL, FALSE);

	return class->refresh_sync (client, cancellable, error);
}

static void
client_wait_for_connected_thread (GTask *task,
				  gpointer source_object,
				  gpointer task_data,
				  GCancellable *cancellable)
{
	guint32 timeout_seconds;
	gboolean success;
	GError *local_error = NULL;

	timeout_seconds = GPOINTER_TO_UINT (task_data);
	success = e_client_wait_for_connected_sync (E_CLIENT (source_object), timeout_seconds, cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * e_client_wait_for_connected:
 * @client: an #EClient
 * @timeout_seconds: a timeout for the wait, in seconds
 * @cancellable: (allow-none): a #GCancellable; or %NULL
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Asynchronously waits until the @client is connected (according
 * to @ESource::connection-status property), but not longer than @timeout_seconds.
 *
 * The call is finished by e_client_wait_for_connected_finish() from
 * the @callback.
 *
 * Since: 3.16
 **/
void
e_client_wait_for_connected (EClient *client,
			     guint32 timeout_seconds,
			     GCancellable *cancellable,
			     GAsyncReadyCallback callback,
			     gpointer user_data)
{
	GTask *task;

	g_return_if_fail (E_IS_CLIENT (client));

	task = g_task_new (client, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_client_wait_for_connected);
	g_task_set_task_data (task, GUINT_TO_POINTER (timeout_seconds), NULL);

	g_task_run_in_thread (task, client_wait_for_connected_thread);

	g_object_unref (task);
}

/**
 * e_client_wait_for_connected_finish:
 * @client: an #EClient
 * @result: a #GAsyncResult
 * @error: (out): (allow-none): a #GError to set an error, or %NULL
 *
 * Finishes previous call of e_client_wait_for_connected().
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.16
 **/
gboolean
e_client_wait_for_connected_finish (EClient *client,
				    GAsyncResult *result,
				    GError **error)
{
	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, client), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_client_wait_for_connected), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

static void
client_wait_for_connected_cancelled_cb (GCancellable *cancellable,
					EFlag *flag)
{
	g_return_if_fail (flag != NULL);

	e_flag_set (flag);
}

static void
client_wait_for_connected_notify_cb (ESource *source,
				     GParamSpec *param,
				     EFlag *flag)
{
	g_return_if_fail (flag != NULL);

	if (e_source_get_connection_status (source) == E_SOURCE_CONNECTION_STATUS_CONNECTED)
		e_flag_set (flag);
}

/**
 * e_client_wait_for_connected_sync:
 * @client: an #EClient
 * @timeout_seconds: a timeout for the wait, in seconds
 * @cancellable: (allow-none): a #GCancellable; or %NULL
 * @error: (out): (allow-none): a #GError to set an error, or %NULL
 *
 * Synchronously waits until the @client is connected (according
 * to @ESource::connection-status property), but not longer than @timeout_seconds.
 *
 * Note: This also calls e_client_retrieve_properties_sync() on success, to have
 *   up-to-date property values on the client side, without a delay due
 *   to property change notifcations delivery through D-Bus.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.16
 **/
gboolean
e_client_wait_for_connected_sync (EClient *client,
				  guint32 timeout_seconds,
				  GCancellable *cancellable,
				  GError **error)
{
	ESource *source;
	EFlag *flag;
	gulong cancellable_handler_id = 0, notify_handler_id;
	gint64 end_time;
	gboolean success;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);

	end_time = g_get_monotonic_time () + timeout_seconds * G_TIME_SPAN_SECOND;
	flag = e_flag_new ();

	if (cancellable)
		cancellable_handler_id = g_cancellable_connect (cancellable,
			G_CALLBACK (client_wait_for_connected_cancelled_cb), flag, NULL);

	source = e_client_get_source (client);

	notify_handler_id = g_signal_connect (source, "notify::connection-status",
		G_CALLBACK (client_wait_for_connected_notify_cb), flag);

	while (success = e_source_get_connection_status (source) == E_SOURCE_CONNECTION_STATUS_CONNECTED,
	       !success && !g_cancellable_is_cancelled (cancellable)) {
		e_flag_clear (flag);

		if (timeout_seconds > 0) {
			if (g_get_monotonic_time () > end_time)
				break;

			e_flag_wait_until (flag, end_time);
		} else {
			e_flag_wait (flag);
		}
	}

	g_signal_handler_disconnect (source, notify_handler_id);

	if (cancellable_handler_id > 0 && cancellable)
		g_cancellable_disconnect (cancellable, cancellable_handler_id);

	e_flag_free (flag);

	success = e_source_get_connection_status (source) == E_SOURCE_CONNECTION_STATUS_CONNECTED;

	if (!success && !g_cancellable_set_error_if_cancelled (cancellable, error))
		g_set_error_literal (error, G_IO_ERROR, G_IO_ERROR_TIMED_OUT, _("Timeout was reached"));
	else if (success)
		success = e_client_retrieve_properties_sync (client, cancellable, error);

	return success;
}

/**
 * e_client_retrieve_properties_sync:
 * @client: an #EClient
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Retrieves @client properties to match server-side values, without waiting
 * for the D-Bus property change notifications delivery.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_client_retrieve_properties_sync (EClient *client,
				   GCancellable *cancellable,
				   GError **error)
{
	EClientClass *klass;

	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);

	klass = E_CLIENT_GET_CLASS (client);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->retrieve_properties_sync != NULL, FALSE);

	return klass->retrieve_properties_sync (client, cancellable, error);
}

static void
client_retrieve_properties_thread (GTask *task,
				   gpointer source_object,
				   gpointer task_data,
				   GCancellable *cancellable)
{
	gboolean success;
	GError *local_error = NULL;

	success = e_client_retrieve_properties_sync (E_CLIENT (source_object), cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * e_client_retrieve_properties:
 * @client: an #EClient
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously retrieves @client properties to match server-side values,
 * without waiting for the D-Bus property change notifications delivery.
 *
 * When the operation is finished, @callback will be called. You can then
 * call e_client_retrieve_properties_finish() to get the result of the operation.
 *
 * Since: 3.16
 **/
void
e_client_retrieve_properties (EClient *client,
			      GCancellable *cancellable,
			      GAsyncReadyCallback callback,
			      gpointer user_data)
{
	GTask *task;

	g_return_if_fail (E_IS_CLIENT (client));

	task = g_task_new (client, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_client_retrieve_properties);

	g_task_run_in_thread (task, client_retrieve_properties_thread);

	g_object_unref (task);
}

/**
 * e_client_retrieve_properties_finish:
 * @client: an #EClient
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_client_retrieve_properties().
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_client_retrieve_properties_finish (EClient *client,
				     GAsyncResult *result,
				     GError **error)
{
	g_return_val_if_fail (E_IS_CLIENT (client), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, client), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_client_retrieve_properties), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * e_client_util_slist_to_strv:
 * @strings: (element-type utf8): a #GSList of strings (const gchar *)
 *
 * Convert a list of strings into a %NULL-terminated array of strings.
 *
 * Returns: (transfer full): Newly allocated %NULL-terminated array of strings.
 * The returned pointer should be freed with g_strfreev().
 *
 * Note: Paired function for this is e_client_util_strv_to_slist().
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use e_util_slist_to_strv() instead.
 **/
gchar **
e_client_util_slist_to_strv (const GSList *strings)
{
	return e_util_slist_to_strv (strings);
}

/**
 * e_client_util_strv_to_slist:
 * @strv: a %NULL-terminated array of strings (const gchar *)
 *
 * Convert a %NULL-terminated array of strings to a list of strings.
 *
 * Returns: (transfer full) (element-type utf8): Newly allocated #GSList of
 * newly allocated strings. The returned pointer should be freed with
 * e_client_util_free_string_slist().
 *
 * Note: Paired function for this is e_client_util_slist_to_strv().
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use e_util_strv_to_slist() instead.
 **/
GSList *
e_client_util_strv_to_slist (const gchar * const *strv)
{
	return e_util_strv_to_slist (strv);
}

/**
 * e_client_util_copy_string_slist:
 * @copy_to: (element-type utf8) (allow-none): Where to copy; may be %NULL
 * @strings: (element-type utf8): #GSList of strings to be copied
 *
 * Copies the #GSList of strings to the end of @copy_to.
 *
 * Returns: (transfer full) (element-type utf8): New head of @copy_to.
 * The returned pointer can be freed with e_client_util_free_string_slist().
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use e_util_copy_string_slist() instead.
 **/
GSList *
e_client_util_copy_string_slist (GSList *copy_to,
                                 const GSList *strings)
{
	return e_util_copy_string_slist (copy_to, strings);
}

/**
 * e_client_util_copy_object_slist:
 * @copy_to: (element-type GObject) (allow-none): Where to copy; may be %NULL
 * @objects: (element-type GObject): #GSList of #GObject<!-- -->s to be copied
 *
 * Copies a #GSList of #GObject<!-- -->s to the end of @copy_to.
 *
 * Returns: (transfer full) (element-type GObject): New head of @copy_to.
 * The returned pointer can be freed with e_client_util_free_object_slist().
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use e_util_copy_object_slist() instead.
 **/
GSList *
e_client_util_copy_object_slist (GSList *copy_to,
                                 const GSList *objects)
{
	return e_util_copy_object_slist (copy_to, objects);
}

/**
 * e_client_util_free_string_slist:
 * @strings: (element-type utf8): a #GSList of strings (gchar *)
 *
 * Frees memory previously allocated by e_client_util_strv_to_slist().
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use g_slist_free_full() instead.
 **/
void
e_client_util_free_string_slist (GSList *strings)
{
	e_util_free_string_slist (strings);
}

/**
 * e_client_util_free_object_slist:
 * @objects: (element-type GObject): a #GSList of #GObject<!-- -->s
 *
 * Calls g_object_unref() on each member of @objects and then frees @objects
 * itself.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use g_slist_free_full() instead.
 **/
void
e_client_util_free_object_slist (GSList *objects)
{
	e_util_free_object_slist (objects);
}

/**
 * e_client_util_parse_comma_strings:
 * @strings: string of comma-separated values
 *
 * Parses comma-separated list of values into #GSList.
 *
 * Returns: (transfer full) (element-type utf8): Newly allocated #GSList of
 * newly allocated strings corresponding to values parsed from @strings.
 * Free the returned pointer with e_client_util_free_string_slist().
 *
 * Since: 3.2
 **/
GSList *
e_client_util_parse_comma_strings (const gchar *strings)
{
	GSList *strs_slist = NULL;
	gchar **strs_strv = NULL;
	gint ii;

	if (!strings || !*strings)
		return NULL;

	strs_strv = g_strsplit (strings, ",", -1);
	g_return_val_if_fail (strs_strv != NULL, NULL);

	for (ii = 0; strs_strv && strs_strv[ii]; ii++) {
		gchar *str = g_strstrip (strs_strv[ii]);

		if (str && *str)
			strs_slist = g_slist_prepend (strs_slist, g_strdup (str));
	}

	g_strfreev (strs_strv);

	return g_slist_reverse (strs_slist);
}

/**
 * e_client_unwrap_dbus_error:
 * @client: an #EClient
 * @dbus_error: a #GError returned bu D-Bus
 * @out_error: a #GError variable where to store the result
 *
 * Unwraps D-Bus error to local error. @dbus_error is automatically freed.
 * @dbus_erorr and @out_error can point to the same variable.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: Use g_dbus_error_strip_remote_error() instead.
 **/
void
e_client_unwrap_dbus_error (EClient *client,
                            GError *dbus_error,
                            GError **out_error)
{
	EClientClass *class;

	g_return_if_fail (E_IS_CLIENT (client));

	class = E_CLIENT_GET_CLASS (client);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->unwrap_dbus_error != NULL);

	if (!dbus_error || !out_error) {
		if (dbus_error)
			g_error_free (dbus_error);
	} else {
		class->unwrap_dbus_error (client, dbus_error, out_error);
	}
}

/**
 * e_client_util_unwrap_dbus_error:
 * @dbus_error: DBus #GError to unwrap
 * @client_error: (out): Resulting #GError; can be %NULL
 * @known_errors: List of known errors against which try to match
 * @known_errors_count: How many items are stored in @known_errors
 * @known_errors_domain: Error domain for @known_errors
 * @fail_when_none_matched: Whether to fail when none of @known_errors matches
 *
 * The function takes a @dbus_error and tries to find a match in @known_errors
 * for it, if it is a G_IO_ERROR, G_IO_ERROR_DBUS_ERROR. If it is anything else
 * then the @dbus_error is moved to @client_error.
 *
 * The @fail_when_none_matched influences behaviour. If it's %TRUE, and none of
 * @known_errors matches, or this is not a G_IO_ERROR_DBUS_ERROR, then %FALSE
 * is returned and the @client_error is left without change. Otherwise, the
 * @fail_when_none_matched is %FALSE, the error is always processed and will
 * result in E_CLIENT_ERROR, E_CLIENT_ERROR_OTHER_ERROR if none of @known_error
 * matches.
 *
 * Returns: Whether was @dbus_error processed into @client_error.
 *
 * Note: The @dbus_error is automatically freed if returned %TRUE.
 *
 * Since: 3.2
 *
 * Deprecated: 3.8: This function is no longer used.
 **/
gboolean
e_client_util_unwrap_dbus_error (GError *dbus_error,
                                 GError **client_error,
                                 const EClientErrorsList *known_errors,
                                 guint known_errors_count,
                                 GQuark known_errors_domain,
                                 gboolean fail_when_none_matched)
{
	if (!client_error) {
		if (dbus_error)
			g_error_free (dbus_error);
		return TRUE;
	}

	if (!dbus_error) {
		*client_error = NULL;
		return TRUE;
	}

	if (dbus_error->domain == known_errors_domain) {
		*client_error = dbus_error;
		return TRUE;
	}

	if (known_errors) {
		if (g_error_matches (dbus_error, G_IO_ERROR, G_IO_ERROR_DBUS_ERROR)) {
			gchar *name;
			gint ii;

			name = g_dbus_error_get_remote_error (dbus_error);

			for (ii = 0; ii < known_errors_count; ii++) {
				if (g_ascii_strcasecmp (known_errors[ii].name, name) == 0) {
					g_free (name);

					g_dbus_error_strip_remote_error (dbus_error);
					*client_error = g_error_new_literal (
						known_errors_domain,
						known_errors[ii].err_code,
						dbus_error->message);
					g_error_free (dbus_error);
					return TRUE;
				}
			}

			g_free (name);
		}
	}

	if (fail_when_none_matched)
		return FALSE;

	if (g_error_matches (dbus_error, G_IO_ERROR, G_IO_ERROR_DBUS_ERROR)) {
		g_dbus_error_strip_remote_error (dbus_error);
		*client_error = g_error_new_literal (
			E_CLIENT_ERROR,
			E_CLIENT_ERROR_OTHER_ERROR,
			dbus_error->message);
		g_error_free (dbus_error);
	} else {
		g_dbus_error_strip_remote_error (dbus_error);
		*client_error = dbus_error;
	}

	return TRUE;
}

/**
 * e_client_dup_bus_name:
 * @client: an #EClient
 *
 * Returns a D-Bus bus name that will be used to connect the
 * client to the backend subprocess.
 *
 * Returns: a newly-allocated string representing a D-Bus bus
 *          name that will be used to connect the client to
 *          the backend subprocess. The string should be
 *          freed by the caller using g_free().
 *
 * Since: 3.16
 **/
gchar *
e_client_dup_bus_name (EClient *client)
{
	g_return_val_if_fail (E_IS_CLIENT (client), NULL);

	return g_strdup (client->priv->bus_name);
}

/**
 * e_client_set_bus_name:
 * @client: an #EClient
 * @bus_name: a string representing a D-Bus bus name
 *
 * Sets a D-Bus bus name that will be used to connect the client
 * to the backend subprocess.
 *
 * Since: 3.16
 **/
void
e_client_set_bus_name (EClient *client,
		       const gchar *bus_name)
{
	g_return_if_fail (E_IS_CLIENT (client));
	g_return_if_fail (client->priv->bus_name == NULL);
	g_return_if_fail (bus_name != NULL && *bus_name != '\0');

	client->priv->bus_name = g_strdup (bus_name);
}
