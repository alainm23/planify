/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-service.c : Abstract class for an email service
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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include "camel-async-closure.h"
#include "camel-debug.h"
#include "camel-enumtypes.h"
#include "camel-local-settings.h"
#include "camel-network-service.h"
#include "camel-network-settings.h"
#include "camel-operation.h"
#include "camel-session.h"
#include "camel-service.h"

#define d(x)
#define w(x)

#define CAMEL_SERVICE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SERVICE, CamelServicePrivate))

#define DISPATCH_DATA_KEY "camel-service-dispatch-data"

typedef struct _AsyncContext AsyncContext;
typedef struct _ConnectionOp ConnectionOp;
typedef struct _DispatchData DispatchData;

struct _CamelServicePrivate {
	GWeakRef session;

	GMutex property_lock;
	CamelSettings *settings;
	GProxyResolver *proxy_resolver;

	CamelProvider *provider;

	gchar *display_name;
	gchar *user_data_dir;
	gchar *user_cache_dir;
	gchar *uid;
	gchar *password;

	GMutex connection_lock;
	ConnectionOp *connection_op;
	CamelServiceConnectionStatus status;

	/* Queues of GTasks, by source object. */
	GHashTable *task_table;
	GMutex task_table_lock;

	gboolean network_service_inited;
};

struct _AsyncContext {
	gchar *auth_mechanism;
	gboolean clean;
};

/* The GQueue is only modified while CamelService's
 * connection_lock is held, so it does not need its
 * own mutex. */
struct _ConnectionOp {
	volatile gint ref_count;
	GQueue pending;
	GMutex task_lock;
	GTask *task;
	GCancellable *cancellable;
};

struct _DispatchData {
	GWeakRef service;
	gboolean return_on_cancel;
	GTaskThreadFunc task_func;
};

enum {
	PROP_0,
	PROP_CONNECTION_STATUS,
	PROP_DISPLAY_NAME,
	PROP_PASSWORD,
	PROP_PROVIDER,
	PROP_PROXY_RESOLVER,
	PROP_SESSION,
	PROP_SETTINGS,
	PROP_UID
};

/* Forward Declarations */
void		camel_network_service_init	(CamelNetworkService *service);
static void	camel_service_initable_init	(GInitableIface *iface);
static void	service_task_dispatch		(CamelService *service,
						 GTask *task);

G_DEFINE_ABSTRACT_TYPE_WITH_CODE (
	CamelService, camel_service, CAMEL_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (G_TYPE_INITABLE, camel_service_initable_init))
G_DEFINE_BOXED_TYPE (CamelServiceAuthType, camel_service_auth_type, camel_service_auth_type_copy, camel_service_auth_type_free);

static void
async_context_free (AsyncContext *async_context)
{
	g_free (async_context->auth_mechanism);

	g_slice_free (AsyncContext, async_context);
}

static ConnectionOp *
connection_op_new (GTask *task,
                   GCancellable *cancellable)
{
	ConnectionOp *op;

	op = g_slice_new0 (ConnectionOp);
	op->ref_count = 1;
	g_mutex_init (&op->task_lock);
	op->task = g_object_ref (task);

	if (G_IS_CANCELLABLE (cancellable))
		op->cancellable = g_object_ref (cancellable);

	return op;
}

static ConnectionOp *
connection_op_ref (ConnectionOp *op)
{
	g_return_val_if_fail (op != NULL, NULL);
	g_return_val_if_fail (op->ref_count > 0, NULL);

	g_atomic_int_inc (&op->ref_count);

	return op;
}

static void
connection_op_unref (ConnectionOp *op)
{
	g_return_if_fail (op != NULL);
	g_return_if_fail (op->ref_count > 0);

	if (g_atomic_int_dec_and_test (&op->ref_count)) {

		/* The pending queue should be empty. */
		g_warn_if_fail (g_queue_is_empty (&op->pending));

		g_mutex_clear (&op->task_lock);

		if (op->task != NULL)
			g_object_unref (op->task);

		if (op->cancellable != NULL)
			g_object_unref (op->cancellable);

		g_slice_free (ConnectionOp, op);
	}
}

static void
connection_op_complete (ConnectionOp *op,
                        const GError *error)
{
	g_mutex_lock (&op->task_lock);

	if (op->task != NULL) {
		if (error != NULL) {
			g_task_return_error (op->task, g_error_copy (error));
		} else {
			g_task_return_boolean (op->task, TRUE);
		}

		g_clear_object (&op->task);
	}

	g_mutex_unlock (&op->task_lock);
}

static void
connection_op_add_pending (ConnectionOp *op,
                           GTask *task,
                           GCancellable *cancellable)
{
	ConnectionOp *pending_op;

	g_return_if_fail (op != NULL);

	pending_op = connection_op_new (task, cancellable);

	g_queue_push_tail (&op->pending, pending_op);
}

static void
connection_op_complete_pending (ConnectionOp *op,
                                const GError *error)
{
	ConnectionOp *pending_op;

	g_return_if_fail (op != NULL);

	while (!g_queue_is_empty (&op->pending)) {
		pending_op = g_queue_pop_head (&op->pending);
		connection_op_complete (pending_op, error);
		connection_op_unref (pending_op);
	}
}

static void
dispatch_data_free (DispatchData *dispatch_data)
{
	g_weak_ref_clear (&dispatch_data->service);

	g_slice_free (DispatchData, dispatch_data);
}

static void
task_queue_free (GQueue *task_queue)
{
	g_queue_free_full (task_queue, g_object_unref);
}

static void
service_task_table_push (CamelService *service,
                         GTask *task)
{
	GQueue *task_queue;
	gpointer source_object;
	gboolean queue_was_empty;

	g_return_if_fail (CAMEL_IS_SERVICE (service));
	g_return_if_fail (G_IS_TASK (task));

	source_object = g_task_get_source_object (task);
	if (source_object == NULL)
		source_object = service;

	g_mutex_lock (&service->priv->task_table_lock);

	task_queue = g_hash_table_lookup (
		service->priv->task_table, source_object);

	/* Create on demand. */
	if (task_queue == NULL) {
		task_queue = g_queue_new ();
		g_hash_table_insert (
			service->priv->task_table,
			source_object, task_queue);
	}

	queue_was_empty = g_queue_is_empty (task_queue);
	g_queue_push_tail (task_queue, g_object_ref (task));

	g_mutex_unlock (&service->priv->task_table_lock);

	if (queue_was_empty)
		service_task_dispatch (service, task);
}

static void
service_task_table_done (CamelService *service,
                         GTask *task)
{
	GQueue *task_queue;
	gpointer source_object;
	GTask *next = NULL;

	g_return_if_fail (CAMEL_IS_SERVICE (service));
	g_return_if_fail (G_IS_TASK (task));

	source_object = g_task_get_source_object (task);
	if (source_object == NULL)
		source_object = service;

	g_mutex_lock (&service->priv->task_table_lock);

	task_queue = g_hash_table_lookup (
		service->priv->task_table, source_object);

	if (task_queue != NULL) {
		if (g_queue_remove (task_queue, task))
			g_object_unref (task);

		next = g_queue_peek_head (task_queue);
		if (next != NULL)
			g_object_ref (next);
	}

	g_mutex_unlock (&service->priv->task_table_lock);

	if (next != NULL) {
		service_task_dispatch (service, next);
		g_object_unref (next);
	}
}

static void
service_task_thread (GTask *task,
                     gpointer source_object,
                     gpointer task_data,
                     GCancellable *cancellable)
{
	CamelService *service;
	DispatchData *data;

	data = g_object_get_data (G_OBJECT (task), DISPATCH_DATA_KEY);
	g_return_if_fail (data != NULL);

	service = g_weak_ref_get (&data->service);
	g_return_if_fail (service != NULL);

	data->task_func (task, source_object, task_data, cancellable);

	service_task_table_done (service, task);

	g_object_unref (service);
}

static void
service_task_dispatch (CamelService *service,
                       GTask *task)
{
	DispatchData *data;

	data = g_object_get_data (G_OBJECT (task), DISPATCH_DATA_KEY);
	g_return_if_fail (data != NULL);

	/* Restore the task's previous "return-on-cancel" flag.
	 * This returns FALSE if the task is already cancelled,
	 * in which case we skip calling g_task_run_in_thread()
	 * so the task doesn't complete twice. */
	if (g_task_set_return_on_cancel (task, data->return_on_cancel))
		g_task_run_in_thread (task, service_task_thread);
	else
		service_task_table_done (service, task);
}

static gchar *
service_find_old_data_dir (CamelService *service)
{
	CamelProvider *provider;
	CamelSession *session;
	CamelURL *url;
	GString *path;
	gboolean allows_host;
	gboolean allows_user;
	gboolean needs_host;
	gboolean needs_path;
	gboolean needs_user;
	const gchar *base_dir;
	gchar *old_data_dir;

	provider = camel_service_get_provider (service);
	url = camel_service_new_camel_url (service);

	allows_host = CAMEL_PROVIDER_ALLOWS (provider, CAMEL_URL_PART_HOST);
	allows_user = CAMEL_PROVIDER_ALLOWS (provider, CAMEL_URL_PART_USER);

	needs_host = CAMEL_PROVIDER_NEEDS (provider, CAMEL_URL_PART_HOST);
	needs_path = CAMEL_PROVIDER_NEEDS (provider, CAMEL_URL_PART_PATH);
	needs_user = CAMEL_PROVIDER_NEEDS (provider, CAMEL_URL_PART_USER);

	/* This function reproduces the way service data directories used
	 * to be determined before we moved to just using the UID.  If the
	 * old data directory exists, try renaming it to the new form.
	 *
	 * A virtual class method was used to determine the directory path,
	 * but no known CamelProviders ever overrode the default algorithm
	 * below.  So this should work for everyone. */

	path = g_string_new (provider->protocol);

	if (allows_user) {
		g_string_append_c (path, '/');
		if (url->user != NULL)
			g_string_append (path, url->user);
		if (allows_host) {
			g_string_append_c (path, '@');
			if (url->host != NULL)
				g_string_append (path, url->host);
			if (url->port) {
				g_string_append_c (path, ':');
				g_string_append_printf (path, "%d", url->port);
			}
		} else if (!needs_user) {
			g_string_append_c (path, '@');
		}

	} else if (allows_host) {
		g_string_append_c (path, '/');
		if (!needs_host)
			g_string_append_c (path, '@');
		if (url->host != NULL)
			g_string_append (path, url->host);
		if (url->port) {
			g_string_append_c (path, ':');
			g_string_append_printf (path, "%d", url->port);
		}
	}

	if (needs_path && url->path) {
		if (*url->path != '/')
			g_string_append_c (path, '/');
		g_string_append (path, url->path);
	}

	session = camel_service_ref_session (service);
	if (session) {
		base_dir = camel_session_get_user_data_dir (session);
		old_data_dir = g_build_filename (base_dir, path->str, NULL);

		g_object_unref (session);
	} else {
		old_data_dir = NULL;
	}

	g_string_free (path, TRUE);

	if (old_data_dir && !g_file_test (old_data_dir, G_FILE_TEST_IS_DIR)) {
		g_free (old_data_dir);
		old_data_dir = NULL;
	}

	camel_url_free (url);

	return old_data_dir;
}

static gboolean
service_notify_connection_status_cb (gpointer user_data)
{
	CamelService *service = CAMEL_SERVICE (user_data);

	g_object_notify (G_OBJECT (service), "connection-status");

	return FALSE;
}

static void
service_queue_notify_connection_status (CamelService *service)
{
	CamelSession *session;

	session = camel_service_ref_session (service);

	/* most-likely exitting the application */
	if (!session)
		return;

	/* Prioritize ahead of GTK+ redraws. */
	camel_session_idle_add (
		session, G_PRIORITY_HIGH_IDLE,
		service_notify_connection_status_cb,
		g_object_ref (service),
		(GDestroyNotify) g_object_unref);

	g_object_unref (session);
}

static void
service_shared_connect_cb (GObject *source_object,
                           GAsyncResult *result,
                           gpointer user_data)
{
	CamelService *service;
	ConnectionOp *op = user_data;
	gboolean success;
	GError *local_error = NULL;

	service = CAMEL_SERVICE (source_object);
	success = g_task_propagate_boolean (G_TASK (result), &local_error);

	g_mutex_lock (&service->priv->connection_lock);

	if (service->priv->connection_op == op) {
		connection_op_unref (service->priv->connection_op);
		service->priv->connection_op = NULL;
		if (success)
			service->priv->status = CAMEL_SERVICE_CONNECTED;
		else
			service->priv->status = CAMEL_SERVICE_DISCONNECTED;
		service_queue_notify_connection_status (service);
	}

	connection_op_complete (op, local_error);
	connection_op_complete_pending (op, local_error);

	g_mutex_unlock (&service->priv->connection_lock);

	connection_op_unref (op);
	g_clear_error (&local_error);
}

static void
service_shared_connect_thread (GTask *task,
                               gpointer source_object,
                               gpointer task_data,
                               GCancellable *cancellable)
{
	CamelServiceClass *class;
	gboolean success;
	GError *local_error = NULL;

	/* Note we call the class method directly here. */

	class = CAMEL_SERVICE_GET_CLASS (source_object);
	g_return_if_fail (class->connect_sync != NULL);

	success = class->connect_sync (
		CAMEL_SERVICE (source_object),
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

static void
service_shared_connect (CamelService *service,
                        gint io_priority,
                        ConnectionOp *op)
{
	GTask *task;

	task = g_task_new (
		service, op->cancellable,
		service_shared_connect_cb,
		connection_op_ref (op));

	g_task_set_source_tag (task, service_shared_connect);
	g_task_set_priority (task, io_priority);

	g_task_run_in_thread (task, service_shared_connect_thread);

	g_object_unref (task);
}

static void
service_shared_disconnect_cb (GObject *source_object,
                              GAsyncResult *result,
                              gpointer user_data)
{
	CamelService *service;
	ConnectionOp *op = user_data;
	gboolean success;
	GError *local_error = NULL;

	service = CAMEL_SERVICE (source_object);
	success = g_task_propagate_boolean (G_TASK (result), &local_error);

	g_mutex_lock (&service->priv->connection_lock);

	if (service->priv->connection_op == op) {
		connection_op_unref (service->priv->connection_op);
		service->priv->connection_op = NULL;
		if (success || service->priv->status == CAMEL_SERVICE_CONNECTING)
			service->priv->status = CAMEL_SERVICE_DISCONNECTED;
		else
			service->priv->status = CAMEL_SERVICE_CONNECTED;
		service_queue_notify_connection_status (service);
	}

	connection_op_complete (op, local_error);
	connection_op_complete_pending (op, local_error);

	g_mutex_unlock (&service->priv->connection_lock);

	connection_op_unref (op);
	g_clear_error (&local_error);
}

static void
service_shared_disconnect_thread (GTask *task,
                                  gpointer source_object,
                                  gpointer task_data,
                                  GCancellable *cancellable)
{
	CamelServiceClass *class;
	AsyncContext *async_context;
	gboolean success;
	GError *local_error = NULL;

	/* Note we call the class method directly here. */

	async_context = (AsyncContext *) task_data;

	class = CAMEL_SERVICE_GET_CLASS (source_object);
	g_return_if_fail (class->disconnect_sync != NULL);

	success = class->disconnect_sync (
		CAMEL_SERVICE (source_object),
		async_context->clean,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

static void
service_shared_disconnect (CamelService *service,
                           gboolean clean,
                           gint io_priority,
                           ConnectionOp *op)
{
	GTask *task;
	AsyncContext *async_context;

	async_context = g_slice_new0 (AsyncContext);
	async_context->clean = clean;

	task = g_task_new (
		service, op->cancellable,
		service_shared_disconnect_cb,
		connection_op_ref (op));

	g_task_set_source_tag (task, service_shared_disconnect);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, service_shared_disconnect_thread);

	g_object_unref (task);
}

static void
service_set_provider (CamelService *service,
                      CamelProvider *provider)
{
	g_return_if_fail (provider != NULL);
	g_return_if_fail (service->priv->provider == NULL);

	service->priv->provider = provider;
}

static void
service_set_session (CamelService *service,
                     CamelSession *session)
{
	g_return_if_fail (CAMEL_IS_SESSION (session));

	g_weak_ref_set (&service->priv->session, session);
}

static void
service_set_uid (CamelService *service,
                 const gchar *uid)
{
	g_return_if_fail (uid != NULL);
	g_return_if_fail (service->priv->uid == NULL);

	service->priv->uid = g_strdup (uid);
}

static void
service_set_property (GObject *object,
                      guint property_id,
                      const GValue *value,
                      GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_DISPLAY_NAME:
			camel_service_set_display_name (
				CAMEL_SERVICE (object),
				g_value_get_string (value));
			return;

		case PROP_PASSWORD:
			camel_service_set_password (
				CAMEL_SERVICE (object),
				g_value_get_string (value));
			return;

		case PROP_PROVIDER:
			service_set_provider (
				CAMEL_SERVICE (object),
				g_value_get_boxed (value));
			return;

		case PROP_PROXY_RESOLVER:
			camel_service_set_proxy_resolver (
				CAMEL_SERVICE (object),
				g_value_get_object (value));
			return;

		case PROP_SESSION:
			service_set_session (
				CAMEL_SERVICE (object),
				g_value_get_object (value));
			return;

		case PROP_SETTINGS:
			camel_service_set_settings (
				CAMEL_SERVICE (object),
				g_value_get_object (value));
			return;

		case PROP_UID:
			service_set_uid (
				CAMEL_SERVICE (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
service_get_property (GObject *object,
                      guint property_id,
                      GValue *value,
                      GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONNECTION_STATUS:
			g_value_set_enum (
				value,
				camel_service_get_connection_status (
				CAMEL_SERVICE (object)));
			return;

		case PROP_DISPLAY_NAME:
			g_value_take_string (
				value,
				camel_service_dup_display_name (
				CAMEL_SERVICE (object)));
			return;

		case PROP_PASSWORD:
			g_value_take_string (
				value,
				camel_service_dup_password (
				CAMEL_SERVICE (object)));
			return;

		case PROP_PROVIDER:
			g_value_set_boxed (
				value,
				camel_service_get_provider (
				CAMEL_SERVICE (object)));
			return;

		case PROP_PROXY_RESOLVER:
			g_value_take_object (
				value,
				camel_service_ref_proxy_resolver (
				CAMEL_SERVICE (object)));
			return;

		case PROP_SESSION:
			g_value_take_object (
				value,
				camel_service_ref_session (
				CAMEL_SERVICE (object)));
			return;

		case PROP_SETTINGS:
			g_value_take_object (
				value,
				camel_service_ref_settings (
				CAMEL_SERVICE (object)));
			return;

		case PROP_UID:
			g_value_set_string (
				value,
				camel_service_get_uid (
				CAMEL_SERVICE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
service_dispose (GObject *object)
{
	CamelServicePrivate *priv;

	priv = CAMEL_SERVICE_GET_PRIVATE (object);

	if (priv->status == CAMEL_SERVICE_CONNECTED)
		CAMEL_SERVICE_GET_CLASS (object)->disconnect_sync (
			CAMEL_SERVICE (object), TRUE, NULL, NULL);

	g_weak_ref_set (&priv->session, NULL);

	g_clear_object (&priv->settings);
	g_clear_object (&priv->proxy_resolver);

	g_hash_table_remove_all (priv->task_table);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_service_parent_class)->dispose (object);
}

static void
service_finalize (GObject *object)
{
	CamelServicePrivate *priv;

	priv = CAMEL_SERVICE_GET_PRIVATE (object);

	g_mutex_clear (&priv->property_lock);

	g_free (priv->display_name);
	g_free (priv->user_data_dir);
	g_free (priv->user_cache_dir);
	g_free (priv->uid);
	g_free (priv->password);

	/* There should be no outstanding connection operations. */
	g_warn_if_fail (priv->connection_op == NULL);
	g_mutex_clear (&priv->connection_lock);

	g_hash_table_destroy (priv->task_table);
	g_mutex_clear (&priv->task_table_lock);

	g_weak_ref_clear (&priv->session);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_service_parent_class)->finalize (object);
}

static void
service_constructed (GObject *object)
{
	CamelService *service;
	CamelSession *session;
	const gchar *base_dir;
	const gchar *uid;

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (camel_service_parent_class)->constructed (object);

	service = CAMEL_SERVICE (object);
	session = camel_service_ref_session (service);

	uid = camel_service_get_uid (service);

	base_dir = camel_session_get_user_data_dir (session);
	service->priv->user_data_dir = g_build_filename (base_dir, uid, NULL);

	base_dir = camel_session_get_user_cache_dir (session);
	service->priv->user_cache_dir = g_build_filename (base_dir, uid, NULL);

	g_object_unref (session);

	/* The CamelNetworkService interface needs initialization. */
	if (CAMEL_IS_NETWORK_SERVICE (service)) {
		camel_network_service_init (CAMEL_NETWORK_SERVICE (service));
		service->priv->network_service_inited = TRUE;
	}
}

static gchar *
service_get_name (CamelService *service,
                  gboolean brief)
{
	g_warning (
		"%s does not implement CamelServiceClass::get_name()",
		G_OBJECT_TYPE_NAME (service));

	return g_strdup (G_OBJECT_TYPE_NAME (service));
}

static gboolean
service_connect_sync (CamelService *service,
                      GCancellable *cancellable,
                      GError **error)
{
	return TRUE;
}

static gboolean
service_disconnect_sync (CamelService *service,
                         gboolean clean,
                         GCancellable *cancellable,
                         GError **error)
{
	if (CAMEL_IS_NETWORK_SERVICE (service))
		camel_network_service_set_connectable (
			CAMEL_NETWORK_SERVICE (service), NULL);

	return TRUE;
}

static GList *
service_query_auth_types_sync (CamelService *service,
                               GCancellable *cancellable,
                               GError **error)
{
	return NULL;
}

static gboolean
service_initable_init (GInitable *initable,
                       GCancellable *cancellable,
                       GError **error)
{
	/* Nothing to do here, but we may need add something in the future.
	 * For now this is a placeholder so subclasses can safely chain up. */

	return TRUE;
}

static void
camel_service_class_init (CamelServiceClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelServicePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = service_set_property;
	object_class->get_property = service_get_property;
	object_class->dispose = service_dispose;
	object_class->finalize = service_finalize;
	object_class->constructed = service_constructed;

	class->settings_type = CAMEL_TYPE_SETTINGS;
	class->get_name = service_get_name;
	class->connect_sync = service_connect_sync;
	class->disconnect_sync = service_disconnect_sync;
	class->query_auth_types_sync = service_query_auth_types_sync;

	g_object_class_install_property (
		object_class,
		PROP_CONNECTION_STATUS,
		g_param_spec_enum (
			"connection-status",
			"Connection Status",
			"The connection status for the service",
			CAMEL_TYPE_SERVICE_CONNECTION_STATUS,
			CAMEL_SERVICE_DISCONNECTED,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_DISPLAY_NAME,
		g_param_spec_string (
			"display-name",
			"Display Name",
			"The display name for the service",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_PASSWORD,
		g_param_spec_string (
			"password",
			"Password",
			"The password for the service",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_PROVIDER,
		g_param_spec_boxed (
			"provider",
			"Provider",
			"The CamelProvider for the service",
			CAMEL_TYPE_PROVIDER,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_PROXY_RESOLVER,
		g_param_spec_object (
			"proxy-resolver",
			"Proxy Resolver",
			"The proxy resolver for the service",
			G_TYPE_PROXY_RESOLVER,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_SESSION,
		g_param_spec_object (
			"session",
			"Session",
			"A CamelSession instance",
			CAMEL_TYPE_SESSION,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_SETTINGS,
		g_param_spec_object (
			"settings",
			"Settings",
			"A CamelSettings instance",
			CAMEL_TYPE_SETTINGS,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_UID,
		g_param_spec_string (
			"uid",
			"UID",
			"The unique identity of the service",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));
}

static void
camel_service_initable_init (GInitableIface *iface)
{
	iface->init = service_initable_init;
}

static void
camel_service_init (CamelService *service)
{
	GHashTable *task_table;

	task_table = g_hash_table_new_full (
		(GHashFunc) g_direct_hash,
		(GEqualFunc) g_direct_equal,
		(GDestroyNotify) NULL,
		(GDestroyNotify) task_queue_free);

	service->priv = CAMEL_SERVICE_GET_PRIVATE (service);

	g_mutex_init (&service->priv->property_lock);
	g_mutex_init (&service->priv->connection_lock);
	g_weak_ref_init (&service->priv->session, NULL);
	service->priv->status = CAMEL_SERVICE_DISCONNECTED;

	service->priv->proxy_resolver = g_proxy_resolver_get_default ();
	if (service->priv->proxy_resolver != NULL)
		g_object_ref (service->priv->proxy_resolver);

	service->priv->task_table = task_table;
	g_mutex_init (&service->priv->task_table_lock);
}

G_DEFINE_QUARK (camel-service-error-quark, camel_service_error)

/**
 * camel_service_migrate_files:
 * @service: a #CamelService
 *
 * Performs any necessary file migrations for @service.  This should be
 * called after installing or configuring the @service's #CamelSettings,
 * since it requires building a URL string for @service.
 *
 * Since: 3.4
 **/
void
camel_service_migrate_files (CamelService *service)
{
	const gchar *new_data_dir;
	gchar *old_data_dir;

	g_return_if_fail (CAMEL_IS_SERVICE (service));

	new_data_dir = camel_service_get_user_data_dir (service);
	old_data_dir = service_find_old_data_dir (service);

	/* If the old data directory name exists, try renaming
	 * it to the new data directory.  Failure is non-fatal. */
	if (old_data_dir != NULL) {
		if (g_rename (old_data_dir, new_data_dir) == -1) {
			g_warning (
				"%s: Failed to rename '%s' to '%s': %s",
				G_STRFUNC, old_data_dir, new_data_dir, g_strerror (errno));
		}
		g_free (old_data_dir);
	}
}

/**
 * camel_service_new_camel_url:
 * @service: a #CamelService
 *
 * Returns a new #CamelURL representing @service.
 * Free the returned #CamelURL with camel_url_free().
 *
 * Returns: a new #CamelURL
 *
 * Since: 3.2
 **/
CamelURL *
camel_service_new_camel_url (CamelService *service)
{
	CamelURL *url;
	CamelProvider *provider;
	CamelSettings *settings;
	gchar *host = NULL;
	gchar *user = NULL;
	gchar *path = NULL;
	guint16 port = 0;

	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	provider = camel_service_get_provider (service);
	g_return_val_if_fail (provider != NULL, NULL);

	settings = camel_service_ref_settings (service);

	/* Allocate as camel_url_new_with_base() does. */
	url = g_new0 (CamelURL, 1);

	if (CAMEL_IS_NETWORK_SETTINGS (settings)) {
		CamelNetworkSettings *network_settings;

		network_settings = CAMEL_NETWORK_SETTINGS (settings);
		host = camel_network_settings_dup_host (network_settings);
		port = camel_network_settings_get_port (network_settings);
		user = camel_network_settings_dup_user (network_settings);
	}

	if (CAMEL_IS_LOCAL_SETTINGS (settings)) {
		CamelLocalSettings *local_settings;

		local_settings = CAMEL_LOCAL_SETTINGS (settings);
		path = camel_local_settings_dup_path (local_settings);
	}

	camel_url_set_protocol (url, provider->protocol);
	camel_url_set_host (url, host);
	camel_url_set_port (url, port);
	camel_url_set_user (url, user);
	camel_url_set_path (url, path);

	g_free (host);
	g_free (user);
	g_free (path);

	g_object_unref (settings);

	return url;
}

/**
 * camel_service_get_connection_status:
 * @service: a #CamelService
 *
 * Returns the connection status for @service.
 *
 * Returns: the connection status
 *
 * Since: 3.2
 **/
CamelServiceConnectionStatus
camel_service_get_connection_status (CamelService *service)
{
	g_return_val_if_fail (
		CAMEL_IS_SERVICE (service),
		CAMEL_SERVICE_DISCONNECTED);

	return service->priv->status;
}

/**
 * camel_service_get_display_name:
 * @service: a #CamelService
 *
 * Returns the display name for @service, or %NULL if @service has not
 * been given a display name.  The display name is intended for use in
 * a user interface and should generally be given a user-defined name.
 *
 * Compare this with camel_service_get_name(), which returns a built-in
 * description of the type of service (IMAP, SMTP, etc.).
 *
 * Returns: the display name for @service, or %NULL
 *
 * Since: 3.2
 **/
const gchar *
camel_service_get_display_name (CamelService *service)
{
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	return service->priv->display_name;
}

/**
 * camel_service_dup_display_name:
 * @service: a #CamelService
 *
 * Thread-safe variation of camel_service_get_display_name().
 * Use this function when accessing @service from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #CamelService:display-name
 *
 * Since: 3.12
 **/
gchar *
camel_service_dup_display_name (CamelService *service)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	g_mutex_lock (&service->priv->property_lock);

	protected = camel_service_get_display_name (service);
	duplicate = g_strdup (protected);

	g_mutex_unlock (&service->priv->property_lock);

	return duplicate;
}

/**
 * camel_service_set_display_name:
 * @service: a #CamelService
 * @display_name: a valid UTF-8 string, or %NULL
 *
 * Assigns a UTF-8 display name to @service.  The display name is intended
 * for use in a user interface and should generally be given a user-defined
 * name.
 *
 * Compare this with camel_service_get_name(), which returns a built-in
 * description of the type of service (IMAP, SMTP, etc.).
 *
 * Since: 3.2
 **/
void
camel_service_set_display_name (CamelService *service,
                                const gchar *display_name)
{
	g_return_if_fail (CAMEL_IS_SERVICE (service));

	if (display_name != NULL)
		g_return_if_fail (g_utf8_validate (display_name, -1, NULL));

	g_mutex_lock (&service->priv->property_lock);

	if (g_strcmp0 (service->priv->display_name, display_name) == 0) {
		g_mutex_unlock (&service->priv->property_lock);
		return;
	}

	g_free (service->priv->display_name);
	service->priv->display_name = g_strdup (display_name);

	g_mutex_unlock (&service->priv->property_lock);

	g_object_notify (G_OBJECT (service), "display-name");
}

/**
 * camel_service_get_password:
 * @service: a #CamelService
 *
 * Returns the password for @service.  Some SASL mechanisms use this
 * when attempting to authenticate.
 *
 * Returns: the password for @service
 *
 * Since: 3.4
 **/
const gchar *
camel_service_get_password (CamelService *service)
{
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	return service->priv->password;
}

/**
 * camel_service_dup_password:
 * @service: a #CamelService
 *
 * Thread-safe variation of camel_service_get_password().
 * Use this function when accessing @service from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #CamelService:password
 *
 * Since: 3.12
 **/
gchar *
camel_service_dup_password (CamelService *service)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	g_mutex_lock (&service->priv->property_lock);

	protected = camel_service_get_password (service);
	duplicate = g_strdup (protected);

	g_mutex_unlock (&service->priv->property_lock);

	return duplicate;
}

/**
 * camel_service_set_password:
 * @service: a #CamelService
 * @password: the password for @service
 *
 * Sets the password for @service.  Use this function to cache the password
 * in memory after obtaining it through camel_session_get_password().  Some
 * SASL mechanisms use this when attempting to authenticate.
 *
 * Since: 3.4
 **/
void
camel_service_set_password (CamelService *service,
                            const gchar *password)
{
	g_return_if_fail (CAMEL_IS_SERVICE (service));

	g_mutex_lock (&service->priv->property_lock);

	if (g_strcmp0 (service->priv->password, password) == 0) {
		g_mutex_unlock (&service->priv->property_lock);
		return;
	}

	g_free (service->priv->password);
	service->priv->password = g_strdup (password);

	g_mutex_unlock (&service->priv->property_lock);

	g_object_notify (G_OBJECT (service), "password");
}

/**
 * camel_service_get_user_data_dir:
 * @service: a #CamelService
 *
 * Returns the base directory under which to store user-specific data
 * for @service.  The directory is formed by appending the directory
 * returned by camel_session_get_user_data_dir() with the service's
 * #CamelService:uid value.
 *
 * Returns: the base directory for @service
 *
 * Since: 3.2
 **/
const gchar *
camel_service_get_user_data_dir (CamelService *service)
{
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	return service->priv->user_data_dir;
}

/**
 * camel_service_get_user_cache_dir:
 * @service: a #CamelService
 *
 * Returns the base directory under which to store cache data
 * for @service.  The directory is formed by appending the directory
 * returned by camel_session_get_user_cache_dir() with the service's
 * #CamelService:uid value.
 *
 * Returns: the base cache directory for @service
 *
 * Since: 3.4
 **/
const gchar *
camel_service_get_user_cache_dir (CamelService *service)
{
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	return service->priv->user_cache_dir;
}

/**
 * camel_service_get_name:
 * @service: a #CamelService
 * @brief: whether or not to use a briefer form
 *
 * This gets the name of the service in a "friendly" (suitable for
 * humans) form. If @brief is %TRUE, this should be a brief description
 * such as for use in the folder tree. If @brief is %FALSE, it should
 * be a more complete and mostly unambiguous description.
 *
 * Returns: a description of the service which the caller must free
 **/
gchar *
camel_service_get_name (CamelService *service,
                        gboolean brief)
{
	CamelServiceClass *class;

	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	class = CAMEL_SERVICE_GET_CLASS (service);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_name != NULL, NULL);

	return class->get_name (service, brief);
}

/**
 * camel_service_get_provider:
 * @service: a #CamelService
 *
 * Gets the #CamelProvider associated with the service.
 *
 * Returns: the #CamelProvider
 **/
CamelProvider *
camel_service_get_provider (CamelService *service)
{
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	return service->priv->provider;
}

/**
 * camel_service_ref_proxy_resolver:
 * @service: a #CamelService
 *
 * Returns the #GProxyResolver for @service.  If an application needs to
 * override this, it should do so prior to calling functions on @service
 * that may require a network connection.
 *
 * The returned #GProxyResolver is referenced for thread-safety and must
 * be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: (transfer full): a #GProxyResolver, or %NULL
 *
 * Since: 3.12
 **/
GProxyResolver *
camel_service_ref_proxy_resolver (CamelService *service)
{
	GProxyResolver *proxy_resolver = NULL;

	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	g_mutex_lock (&service->priv->property_lock);

	if (service->priv->proxy_resolver != NULL)
		proxy_resolver = g_object_ref (service->priv->proxy_resolver);

	g_mutex_unlock (&service->priv->property_lock);

	return proxy_resolver;
}

/**
 * camel_service_set_proxy_resolver:
 * @service: a #CamelService
 * @proxy_resolver: a #GProxyResolver, or %NULL for the default
 *
 * Sets the #GProxyResolver for @service.  If an application needs to
 * override this, it should do so prior to calling functions on @service
 * that may require a network connection.
 *
 * Since: 3.12
 **/
void
camel_service_set_proxy_resolver (CamelService *service,
                                  GProxyResolver *proxy_resolver)
{
	gboolean notify = FALSE;

	if (proxy_resolver == NULL)
		proxy_resolver = g_proxy_resolver_get_default ();

	g_return_if_fail (CAMEL_IS_SERVICE (service));
	g_return_if_fail (G_IS_PROXY_RESOLVER (proxy_resolver));

	g_mutex_lock (&service->priv->property_lock);

	/* Emitting a "notify" signal unnecessarily might have
	 * unwanted side effects like cancelling a SoupMessage.
	 * Only emit if we now have a different GProxyResolver. */

	if (proxy_resolver != service->priv->proxy_resolver) {
		g_clear_object (&service->priv->proxy_resolver);
		service->priv->proxy_resolver = proxy_resolver;

		if (proxy_resolver != NULL)
			g_object_ref (proxy_resolver);

		notify = TRUE;
	}

	g_mutex_unlock (&service->priv->property_lock);

	if (notify)
		g_object_notify (G_OBJECT (service), "proxy-resolver");
}

/**
 * camel_service_ref_session:
 * @service: a #CamelService
 *
 * Returns the #CamelSession associated with the service.
 *
 * The returned #CamelSession is referenced for thread-safety.  Unreference
 * the #CamelSession with g_object_unref() when finished with it.
 *
 * Returns: (transfer full) (type CamelSession): the #CamelSession
 *
 * Since: 3.8
 **/
CamelSession *
camel_service_ref_session (CamelService *service)
{
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	return g_weak_ref_get (&service->priv->session);
}

/**
 * camel_service_ref_settings:
 * @service: a #CamelService
 *
 * Returns the #CamelSettings instance associated with the service.
 *
 * The returned #CamelSettings is referenced for thread-safety and must
 * be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: (transfer full): the #CamelSettings
 *
 * Since: 3.6
 **/
CamelSettings *
camel_service_ref_settings (CamelService *service)
{
	CamelSettings *settings;

	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	/* Every service should have a settings object. */
	g_return_val_if_fail (service->priv->settings != NULL, NULL);

	g_mutex_lock (&service->priv->property_lock);

	settings = g_object_ref (service->priv->settings);

	g_mutex_unlock (&service->priv->property_lock);

	return settings;
}

/**
 * camel_service_set_settings:
 * @service: a #CamelService
 * @settings: an instance derviced from #CamelSettings, or %NULL
 *
 * Associates a new #CamelSettings instance with the service.
 * The @settings instance must match the settings type defined in
 * #CamelServiceClass.  If @settings is %NULL, a new #CamelSettings
 * instance of the appropriate type is created with all properties
 * set to defaults.
 *
 * Since: 3.2
 **/
void
camel_service_set_settings (CamelService *service,
                            CamelSettings *settings)
{
	CamelServiceClass *class;

	g_return_if_fail (CAMEL_IS_SERVICE (service));

	class = CAMEL_SERVICE_GET_CLASS (service);
	g_return_if_fail (class != NULL);

	if (settings != NULL) {
		g_return_if_fail (
			g_type_is_a (
				G_OBJECT_TYPE (settings),
				class->settings_type));
		g_object_ref (settings);

	} else {
		g_return_if_fail (
			g_type_is_a (
				class->settings_type,
				CAMEL_TYPE_SETTINGS));
		settings = g_object_new (class->settings_type, NULL);
	}

	g_mutex_lock (&service->priv->property_lock);

	if (service->priv->settings != NULL)
		g_object_unref (service->priv->settings);

	service->priv->settings = settings;  /* takes ownership */

	g_mutex_unlock (&service->priv->property_lock);

	/* If the service is a CamelNetworkService, it needs to
	 * replace its GSocketConnectable for the new settings. */
	if (service->priv->network_service_inited)
		camel_network_service_set_connectable (
			CAMEL_NETWORK_SERVICE (service), NULL);

	g_object_notify (G_OBJECT (service), "settings");
}

/**
 * camel_service_get_uid:
 * @service: a #CamelService
 *
 * Gets the unique identifier string associated with the service.
 *
 * Returns: the UID string
 *
 * Since: 3.2
 **/
const gchar *
camel_service_get_uid (CamelService *service)
{
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	return service->priv->uid;
}

/**
 * camel_service_queue_task:
 * @service: a #CamelService
 * @task: a #GTask
 * @task_func: (scope async): function to call when @task is dispatched
 *
 * Adds @task to a queue of waiting tasks with the same source object.
 * Queued tasks execute one at a time in the order they were added.  When
 * @task reaches the front of the queue, it will be dispatched by invoking
 * @task_func in a separate thread.  If @task is cancelled while queued,
 * it will complete immediately with an appropriate error.
 *
 * This is primarily intended for use by #CamelStore, #CamelTransport and
 * #CamelFolder to achieve ordered invocation of synchronous class methods.
 *
 * Since: 3.12
 **/
void
camel_service_queue_task (CamelService *service,
                          GTask *task,
                          GTaskThreadFunc task_func)
{
	DispatchData *dispatch_data;
	gboolean return_on_cancel;

	g_return_if_fail (CAMEL_IS_SERVICE (service));
	g_return_if_fail (G_IS_TASK (task));
	g_return_if_fail (task_func != NULL);

	return_on_cancel = g_task_get_return_on_cancel (task);

	dispatch_data = g_slice_new0 (DispatchData);
	g_weak_ref_init (&dispatch_data->service, service);
	dispatch_data->return_on_cancel = return_on_cancel;
	dispatch_data->task_func = task_func;

	/* Complete immediately if cancelled while queued. */
	g_task_set_return_on_cancel (task, TRUE);

	/* Stash this until it's time to dispatch the GTask. */
	g_object_set_data_full (
		G_OBJECT (task), DISPATCH_DATA_KEY,
		dispatch_data, (GDestroyNotify) dispatch_data_free);

	service_task_table_push (service, task);
}

/**
 * camel_service_connect_sync:
 * @service: a #CamelService
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Connects @service to a remote server using the information in its
 * #CamelService:settings instance.
 *
 * If a connect operation is already in progress when this function is
 * called, its results will be reflected in this connect operation.
 *
 * Returns: %TRUE if the connection is made or %FALSE otherwise
 *
 * Since: 3.6
 **/
gboolean
camel_service_connect_sync (CamelService *service,
                            GCancellable *cancellable,
                            GError **error)
{
	CamelAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_SERVICE (service), FALSE);

	closure = camel_async_closure_new ();

	camel_service_connect (
		service, G_PRIORITY_DEFAULT, cancellable,
		camel_async_closure_callback, closure);

	result = camel_async_closure_wait (closure);

	success = camel_service_connect_finish (service, result, error);

	camel_async_closure_free (closure);

	return success;
}

/**
 * camel_service_connect:
 * @service: a #CamelService
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously connects @service to a remote server using the information
 * in its #CamelService:settings instance.
 *
 * If a connect operation is already in progress when this function is
 * called, its results will be reflected in this connect operation.
 *
 * If any disconnect operations are in progress when this function is
 * called, they will be cancelled.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_service_connect_finish() to get the result of the
 * operation.
 *
 * Since: 3.6
 **/
void
camel_service_connect (CamelService *service,
                       gint io_priority,
                       GCancellable *cancellable,
                       GAsyncReadyCallback callback,
                       gpointer user_data)
{
	GTask *task;
	ConnectionOp *op;

	g_return_if_fail (CAMEL_IS_SERVICE (service));

	cancellable = camel_operation_new_proxy (cancellable);

	task = g_task_new (service, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_service_connect);
	g_task_set_priority (task, io_priority);

	g_mutex_lock (&service->priv->connection_lock);

	switch (service->priv->status) {

		/* If a connect operation is already in progress,
		 * queue this operation so it completes at the same
		 * time the first connect operation completes. */
		case CAMEL_SERVICE_CONNECTING:
			connection_op_add_pending (
				service->priv->connection_op,
				task, cancellable);
			break;

		/* If we're already connected, just report success. */
		case CAMEL_SERVICE_CONNECTED:
			g_task_return_boolean (task, TRUE);
			break;

		/* If a disconnect operation is currently in progress,
		 * cancel it and make room for the connect operation. */
		case CAMEL_SERVICE_DISCONNECTING:
			g_return_if_fail (
				service->priv->connection_op != NULL);
			g_cancellable_cancel (
				service->priv->connection_op->cancellable);
			connection_op_unref (service->priv->connection_op);
			service->priv->connection_op = NULL;
			/* fall through */

		/* Start a new connect operation.  Subsequent connect
		 * operations are queued until this operation completes
		 * and will share this operation's result. */
		case CAMEL_SERVICE_DISCONNECTED:
			g_return_if_fail (
				service->priv->connection_op == NULL);

			op = connection_op_new (task, cancellable);
			service->priv->connection_op = op;

			service->priv->status = CAMEL_SERVICE_CONNECTING;
			service_queue_notify_connection_status (service);

			service_shared_connect (service, io_priority, op);
			break;

		default:
			g_warn_if_reached ();
	}

	g_mutex_unlock (&service->priv->connection_lock);

	g_object_unref (cancellable);
	g_object_unref (task);
}

/**
 * camel_service_connect_finish:
 * @service: a #CamelService
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_service_connect().
 *
 * Returns: %TRUE if the connection was made or %FALSE otherwise
 *
 * Since: 3.6
 **/
gboolean
camel_service_connect_finish (CamelService *service,
                              GAsyncResult *result,
                              GError **error)
{
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, service), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_service_connect), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_service_disconnect_sync:
 * @service: a #CamelService
 * @clean: whether or not to try to disconnect cleanly
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Disconnect from the service. If @clean is %FALSE, it should not
 * try to do any synchronizing or other cleanup of the connection.
 *
 * If a disconnect operation is already in progress when this function is
 * called, its results will be reflected in this disconnect operation.
 *
 * If any connect operations are in progress when this function is called,
 * they will be cancelled.
 *
 * Returns: %TRUE if the connection was severed or %FALSE otherwise
 *
 * Since: 3.6
 **/
gboolean
camel_service_disconnect_sync (CamelService *service,
                               gboolean clean,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_SERVICE (service), FALSE);

	closure = camel_async_closure_new ();

	camel_service_disconnect (
		service, clean, G_PRIORITY_DEFAULT, cancellable,
		camel_async_closure_callback, closure);

	result = camel_async_closure_wait (closure);

	success = camel_service_disconnect_finish (service, result, error);

	camel_async_closure_free (closure);

	return success;
}

/**
 * camel_service_disconnect:
 * @service: a #CamelService
 * @clean: whether or not to try to disconnect cleanly
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * If a disconnect operation is already in progress when this function is
 * called, its results will be reflected in this disconnect operation.
 *
 * If any connect operations are in progress when this function is called,
 * they will be cancelled.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_service_disconnect_finish() to get the result of the
 * operation.
 *
 * Since: 3.6
 **/
void
camel_service_disconnect (CamelService *service,
                          gboolean clean,
                          gint io_priority,
                          GCancellable *cancellable,
                          GAsyncReadyCallback callback,
                          gpointer user_data)
{
	GTask *task;
	ConnectionOp *op;

	g_return_if_fail (CAMEL_IS_SERVICE (service));

	cancellable = camel_operation_new_proxy (cancellable);

	task = g_task_new (service, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_service_disconnect);
	g_task_set_priority (task, io_priority);

	g_mutex_lock (&service->priv->connection_lock);

	switch (service->priv->status) {

		/* If a connect operation is currently in progress,
		 * cancel it and make room for the disconnect operation. */
		case CAMEL_SERVICE_CONNECTING:
			g_return_if_fail (
				service->priv->connection_op != NULL);
			g_cancellable_cancel (
				service->priv->connection_op->cancellable);
			connection_op_unref (service->priv->connection_op);
			service->priv->connection_op = NULL;
			/* fall through */

		/* Start a new disconnect operation.  Subsequent disconnect
		 * operations are queued until this operation completes and
		 * will share this operation's result. */
		case CAMEL_SERVICE_CONNECTED:
			g_return_if_fail (
				service->priv->connection_op == NULL);

			op = connection_op_new (task, cancellable);
			service->priv->connection_op = op;

			/* Do not change the status if CONNECTING, in case a
			 * provider calls disconnect() during the connection
			 * phase, which confuses the other logic here and
			 * effectively makes the service's connection state
			 * CONNECTED instead of DISCONNECTED at the end. */
			if (service->priv->status != CAMEL_SERVICE_CONNECTING) {
				service->priv->status = CAMEL_SERVICE_DISCONNECTING;
				service_queue_notify_connection_status (service);
			}

			service_shared_disconnect (
				service, clean, io_priority, op);
			break;

		/* If a disconnect operation is already in progress,
		 * queue this operation so it completes at the same
		 * time the first disconnect operation completes. */
		case CAMEL_SERVICE_DISCONNECTING:
			connection_op_add_pending (
				service->priv->connection_op,
				task, cancellable);
			break;

		/* If we're already disconnected, just report success. */
		case CAMEL_SERVICE_DISCONNECTED:
			g_task_return_boolean (task, TRUE);
			break;

		default:
			g_warn_if_reached ();
	}

	g_mutex_unlock (&service->priv->connection_lock);

	g_object_unref (cancellable);
	g_object_unref (task);
}

/**
 * camel_service_disconnect_finish:
 * @service: a #CamelService
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_service_disconnect().
 *
 * Returns: %TRUE if the connection was severed or %FALSE otherwise
 *
 * Since: 3.6
 **/
gboolean
camel_service_disconnect_finish (CamelService *service,
                                 GAsyncResult *result,
                                 GError **error)
{
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, service), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_service_disconnect), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_service_authenticate_sync:
 * @service: a #CamelService
 * @mechanism: (nullable): a SASL mechanism name, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Attempts to authenticate @service using @mechanism and, if necessary,
 * @service's #CamelService:password property.  The function makes only
 * ONE attempt at authentication and does not loop.
 *
 * If the authentication attempt completed and the server accepted the
 * credentials, the function returns #CAMEL_AUTHENTICATION_ACCEPTED.
 *
 * If the authentication attempt completed but the server rejected the
 * credentials, the function returns #CAMEL_AUTHENTICATION_REJECTED.
 *
 * If the authentication attempt failed to complete due to a network
 * communication issue or some other mishap, the function sets @error
 * and returns #CAMEL_AUTHENTICATION_ERROR.
 *
 * Generally this function should only be called from a #CamelSession
 * subclass in order to implement its own authentication loop.
 *
 * Returns: the authentication result
 *
 * Since: 3.4
 **/
CamelAuthenticationResult
camel_service_authenticate_sync (CamelService *service,
                                 const gchar *mechanism,
                                 GCancellable *cancellable,
                                 GError **error)
{
	CamelServiceClass *class;
	CamelAuthenticationResult result;

	g_return_val_if_fail (
		CAMEL_IS_SERVICE (service),
		CAMEL_AUTHENTICATION_ERROR);

	class = CAMEL_SERVICE_GET_CLASS (service);
	g_return_val_if_fail (class != NULL, CAMEL_AUTHENTICATION_ERROR);
	g_return_val_if_fail (class->authenticate_sync != NULL, CAMEL_AUTHENTICATION_ERROR);

	result = class->authenticate_sync (
		service, mechanism, cancellable, error);
	CAMEL_CHECK_GERROR (
		service, authenticate_sync,
		result != CAMEL_AUTHENTICATION_ERROR, error);

	return result;
}

/* Helper for camel_service_authenticate() */
static void
service_authenticate_thread (GTask *task,
                             gpointer source_object,
                             gpointer task_data,
                             GCancellable *cancellable)
{
	CamelAuthenticationResult auth_result;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	auth_result = camel_service_authenticate_sync (
		CAMEL_SERVICE (source_object),
		async_context->auth_mechanism,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_int (task, auth_result);
	}
}

/**
 * camel_service_authenticate:
 * @service: a #CamelService
 * @mechanism: (nullable): a SASL mechanism name, or %NULL
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously attempts to authenticate @service using @mechanism and,
 * if necessary, @service's #CamelService:password property.  The function
 * makes only ONE attempt at authentication and does not loop.
 *
 * Generally this function should only be called from a #CamelSession
 * subclass in order to implement its own authentication loop.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_service_authenticate_finish() to get the result of
 * the operation.
 *
 * Since: 3.4
 **/
void
camel_service_authenticate (CamelService *service,
                            const gchar *mechanism,
                            gint io_priority,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_SERVICE (service));

	async_context = g_slice_new0 (AsyncContext);
	async_context->auth_mechanism = g_strdup (mechanism);

	task = g_task_new (service, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_service_authenticate);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, service_authenticate_thread);

	g_object_unref (task);
}

/**
 * camel_service_authenticate_finish:
 * @service: a #CamelService
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_service_authenticate().
 *
 * If the authentication attempt completed and the server accepted the
 * credentials, the function returns #CAMEL_AUTHENTICATION_ACCEPTED.
 *
 * If the authentication attempt completed but the server rejected the
 * credentials, the function returns #CAMEL_AUTHENTICATION_REJECTED.
 *
 * If the authentication attempt failed to complete due to a network
 * communication issue or some other mishap, the function sets @error
 * and returns #CAMEL_AUTHENTICATION_ERROR.
 *
 * Returns: the authentication result
 *
 * Since: 3.4
 **/
CamelAuthenticationResult
camel_service_authenticate_finish (CamelService *service,
                                   GAsyncResult *result,
                                   GError **error)
{
	CamelAuthenticationResult auth_result;

	g_return_val_if_fail (
		CAMEL_IS_SERVICE (service),
		CAMEL_AUTHENTICATION_ERROR);
	g_return_val_if_fail (
		g_task_is_valid (result, service),
		CAMEL_AUTHENTICATION_ERROR);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_service_authenticate),
		CAMEL_AUTHENTICATION_ERROR);

	/* XXX A little hackish, but best way to return enum values
	 *     from GTask in GLib 2.36.  Recommended by Dan Winship. */

	auth_result = g_task_propagate_int (G_TASK (result), error);

	if (auth_result == (CamelAuthenticationResult) -1)
		return CAMEL_AUTHENTICATION_ERROR;

	return auth_result;
}

/**
 * camel_service_query_auth_types_sync:
 * @service: a #CamelService
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Obtains a list of authentication types supported by @service.
 * Free the returned list with g_list_free().
 *
 * Returns: (element-type CamelServiceAuthType) (transfer container): a list of #CamelServiceAuthType structs
 **/
GList *
camel_service_query_auth_types_sync (CamelService *service,
                                     GCancellable *cancellable,
                                     GError **error)
{
	CamelServiceClass *class;

	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	class = CAMEL_SERVICE_GET_CLASS (service);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->query_auth_types_sync != NULL, NULL);

	return class->query_auth_types_sync (service, cancellable, error);
}

/* Helper for camel_service_query_auth_types() */
static void
service_query_auth_types_thread (GTask *task,
                                 gpointer source_object,
                                 gpointer task_data,
                                 GCancellable *cancellable)
{
	GList *auth_types;
	GError *local_error = NULL;

	auth_types = camel_service_query_auth_types_sync (
		CAMEL_SERVICE (source_object),
		cancellable, &local_error);

	if (local_error != NULL) {
		g_warn_if_fail (auth_types == NULL);
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (
			task, auth_types,
			(GDestroyNotify) g_list_free);
	}
}

/**
 * camel_service_query_auth_types:
 * @service: a #CamelService
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously obtains a list of authentication types supported by
 * @service.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_service_query_auth_types_finish() to get the result
 * of the operation.
 *
 * Since: 3.2
 **/
void
camel_service_query_auth_types (CamelService *service,
                                gint io_priority,
                                GCancellable *cancellable,
                                GAsyncReadyCallback callback,
                                gpointer user_data)
{
	GTask *task;

	g_return_if_fail (CAMEL_IS_SERVICE (service));

	task = g_task_new (service, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_service_query_auth_types);
	g_task_set_priority (task, io_priority);

	g_task_run_in_thread (task, service_query_auth_types_thread);

	g_object_unref (task);
}

/**
 * camel_service_query_auth_types_finish:
 * @service: a #CamelService
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_service_query_auth_types().
 * Free the returned list with g_list_free().
 *
 * Returns: (element-type CamelServiceAuthType) (transfer container): a list of #CamelServiceAuthType structs
 *
 * Since: 3.2
 **/
GList *
camel_service_query_auth_types_finish (CamelService *service,
                                       GAsyncResult *result,
                                       GError **error)
{
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);
	g_return_val_if_fail (g_task_is_valid (result, service), NULL);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_service_query_auth_types), NULL);

	return g_task_propagate_pointer (G_TASK (result), error);
}

/**
 * camel_service_auth_type_copy:
 * @service_auth_type: an #CamelServiceAuthType
 *
 * Copies the @service_auth_type struct.
 * Does nothing and returns the given object in reality, needed for the introspection.
 *
 * Returns: (transfer full): the copy of @service_auth_type
 *
 * Since: 3.24
 **/
CamelServiceAuthType *
camel_service_auth_type_copy (const CamelServiceAuthType *service_auth_type)
{
	/* This is needed for the introspection.
	 * In the reality, each CamelSasl subclass has a static reference of it.
	 */
	return (CamelServiceAuthType *) service_auth_type;
}

/**
 * camel_service_auth_type_free:
 * @service_auth_type: an #CamelServiceAuthType
 *
 * Frees the @service_auth_type struct.
 * Does nothing in reality, needed for the introspection.
 *
 * Since: 3.24
 **/
void
camel_service_auth_type_free (CamelServiceAuthType *service_auth_type)
{
	/* This is needed for the introspection.
	 * In the reality, each CamelSasl subclass has a static reference of it.
	 */
}
