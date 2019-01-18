/*
 * camel-subscribable.c
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

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include "camel-async-closure.h"
#include "camel-debug.h"
#include "camel-session.h"
#include "camel-vtrash-folder.h"

#include "camel-subscribable.h"

typedef struct _AsyncContext AsyncContext;
typedef struct _SignalClosure SignalClosure;

struct _AsyncContext {
	gchar *folder_name;
};

struct _SignalClosure {
	GWeakRef subscribable;
	CamelFolderInfo *folder_info;
};

enum {
	FOLDER_SUBSCRIBED,
	FOLDER_UNSUBSCRIBED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_INTERFACE (CamelSubscribable, camel_subscribable, CAMEL_TYPE_STORE)

static void
async_context_free (AsyncContext *async_context)
{
	g_free (async_context->folder_name);

	g_slice_free (AsyncContext, async_context);
}

static void
signal_closure_free (SignalClosure *signal_closure)
{
	g_weak_ref_clear (&signal_closure->subscribable);

	if (signal_closure->folder_info != NULL)
		camel_folder_info_free (signal_closure->folder_info);

	g_slice_free (SignalClosure, signal_closure);
}

static gboolean
subscribable_emit_folder_subscribed_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	CamelSubscribable *subscribable;

	subscribable = g_weak_ref_get (&signal_closure->subscribable);

	if (subscribable != NULL) {
		g_signal_emit (
			subscribable,
			signals[FOLDER_SUBSCRIBED], 0,
			signal_closure->folder_info);
		g_object_unref (subscribable);
	}

	return FALSE;
}

static gboolean
subscribable_emit_folder_unsubscribed_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	CamelSubscribable *subscribable;

	subscribable = g_weak_ref_get (&signal_closure->subscribable);

	if (subscribable != NULL) {
		g_signal_emit (
			subscribable,
			signals[FOLDER_UNSUBSCRIBED], 0,
			signal_closure->folder_info);
		g_object_unref (subscribable);
	}

	return FALSE;
}

static void
camel_subscribable_default_init (CamelSubscribableInterface *iface)
{
	signals[FOLDER_SUBSCRIBED] = g_signal_new (
		"folder-subscribed",
		G_OBJECT_CLASS_TYPE (iface),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (
			CamelSubscribableInterface,
			folder_subscribed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		CAMEL_TYPE_FOLDER_INFO);

	signals[FOLDER_UNSUBSCRIBED] = g_signal_new (
		"folder-unsubscribed",
		G_OBJECT_CLASS_TYPE (iface),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (
			CamelSubscribableInterface,
			folder_unsubscribed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		CAMEL_TYPE_FOLDER_INFO);
}

/**
 * camel_subscribable_folder_is_subscribed:
 * @subscribable: a #CamelSubscribable
 * @folder_name: full path of the folder
 *
 * Find out if a folder has been subscribed to.
 *
 * Returns: %TRUE if the folder has been subscribed to or %FALSE otherwise
 *
 * Since: 3.2
 **/
gboolean
camel_subscribable_folder_is_subscribed (CamelSubscribable *subscribable,
                                         const gchar *folder_name)
{
	CamelSubscribableInterface *iface;

	g_return_val_if_fail (CAMEL_IS_SUBSCRIBABLE (subscribable), FALSE);
	g_return_val_if_fail (folder_name != NULL, FALSE);

	iface = CAMEL_SUBSCRIBABLE_GET_INTERFACE (subscribable);
	g_return_val_if_fail (iface->folder_is_subscribed != NULL, FALSE);

	return iface->folder_is_subscribed (subscribable, folder_name);
}

/**
 * camel_subscribable_subscribe_folder_sync:
 * @subscribable: a #CamelSubscribable
 * @folder_name: full path of the folder
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Subscribes to the folder described by @folder_name.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.2
 **/
gboolean
camel_subscribable_subscribe_folder_sync (CamelSubscribable *subscribable,
                                          const gchar *folder_name,
                                          GCancellable *cancellable,
                                          GError **error)
{
	CamelAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_SUBSCRIBABLE (subscribable), FALSE);
	g_return_val_if_fail (folder_name != NULL, FALSE);

	closure = camel_async_closure_new ();

	camel_subscribable_subscribe_folder (
		subscribable, folder_name,
		G_PRIORITY_DEFAULT, cancellable,
		camel_async_closure_callback, closure);

	result = camel_async_closure_wait (closure);

	success = camel_subscribable_subscribe_folder_finish (
		subscribable, result, error);

	camel_async_closure_free (closure);

	return success;
}

/* Helper for camel_subscribable_subscribe_folder() */
static void
subscribable_subscribe_folder_thread (GTask *task,
                                      gpointer source_object,
                                      gpointer task_data,
                                      GCancellable *cancellable)
{
	CamelSubscribable *subscribable;
	CamelSubscribableInterface *iface;
	const gchar *folder_name;
	const gchar *message;
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	subscribable = CAMEL_SUBSCRIBABLE (source_object);
	async_context = (AsyncContext *) task_data;

	folder_name = async_context->folder_name;

	iface = CAMEL_SUBSCRIBABLE_GET_INTERFACE (subscribable);
	g_return_if_fail (iface->subscribe_folder_sync != NULL);

	/* Need to establish a connection before subscribing. */
	camel_service_connect_sync (
		CAMEL_SERVICE (subscribable), cancellable, &local_error);
	if (local_error != NULL) {
		g_task_return_error (task, local_error);
		return;
	}

	message = _("Subscribing to folder “%s”");
	camel_operation_push_message (cancellable, message, folder_name);

	success = iface->subscribe_folder_sync (
		subscribable, folder_name, cancellable, &local_error);
	CAMEL_CHECK_LOCAL_GERROR (
		subscribable, subscribe_folder_sync, success, local_error);

	camel_operation_pop_message (cancellable);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_subscribable_subscribe_folder:
 * @subscribable: a #CamelSubscribable
 * @folder_name: full path of the folder
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously subscribes to the folder described by @folder_name.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_subscribable_subscribe_folder_finish() to get the result of
 * the operation.
 *
 * Since: 3.2
 **/
void
camel_subscribable_subscribe_folder (CamelSubscribable *subscribable,
                                     const gchar *folder_name,
                                     gint io_priority,
                                     GCancellable *cancellable,
                                     GAsyncReadyCallback callback,
                                     gpointer user_data)
{
	GTask *task;
	CamelService *service;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_SUBSCRIBABLE (subscribable));
	g_return_if_fail (folder_name != NULL);

	service = CAMEL_SERVICE (subscribable);

	async_context = g_slice_new0 (AsyncContext);
	async_context->folder_name = g_strdup (folder_name);

	task = g_task_new (subscribable, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_subscribable_subscribe_folder);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	camel_service_queue_task (
		service, task, subscribable_subscribe_folder_thread);

	g_object_unref (task);
}

/**
 * camel_subscribable_subscribe_folder_finish:
 * @subscribable: a #CamelSubscribable
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_subscribable_subscribe_folder().
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.2
 **/
gboolean
camel_subscribable_subscribe_folder_finish (CamelSubscribable *subscribable,
                                            GAsyncResult *result,
                                            GError **error)
{
	g_return_val_if_fail (CAMEL_IS_SUBSCRIBABLE (subscribable), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, subscribable), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_subscribable_subscribe_folder), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_subscribable_unsubscribe_folder_sync:
 * @subscribable: a #CamelSubscribable
 * @folder_name: full path of the folder
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Unsubscribes from the folder described by @folder_name.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.2
 **/
gboolean
camel_subscribable_unsubscribe_folder_sync (CamelSubscribable *subscribable,
                                            const gchar *folder_name,
                                            GCancellable *cancellable,
                                            GError **error)
{
	CamelAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_SUBSCRIBABLE (subscribable), FALSE);
	g_return_val_if_fail (folder_name != NULL, FALSE);

	closure = camel_async_closure_new ();

	camel_subscribable_unsubscribe_folder (
		subscribable, folder_name,
		G_PRIORITY_DEFAULT, cancellable,
		camel_async_closure_callback, closure);

	result = camel_async_closure_wait (closure);

	success = camel_subscribable_unsubscribe_folder_finish (
		subscribable, result, error);

	camel_async_closure_free (closure);

	return success;
}

/* Helper for camel_subscribable_unsubscribe_folder() */
static void
subscribable_unsubscribe_folder_thread (GTask *task,
                                        gpointer source_object,
                                        gpointer task_data,
                                        GCancellable *cancellable)
{
	CamelSubscribable *subscribable;
	CamelSubscribableInterface *iface;
	const gchar *folder_name;
	const gchar *message;
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	subscribable = CAMEL_SUBSCRIBABLE (source_object);
	async_context = (AsyncContext *) task_data;

	folder_name = async_context->folder_name;

	iface = CAMEL_SUBSCRIBABLE_GET_INTERFACE (subscribable);
	g_return_if_fail (iface->unsubscribe_folder_sync != NULL);

	/* Need to establish a connection before unsubscribing. */
	camel_service_connect_sync (
		CAMEL_SERVICE (subscribable), cancellable, &local_error);
	if (local_error != NULL) {
		g_task_return_error (task, local_error);
		return;
	}

	message = _("Unsubscribing from folder “%s”");
	camel_operation_push_message (cancellable, message, folder_name);

	success = iface->unsubscribe_folder_sync (
		subscribable, folder_name, cancellable, &local_error);
	CAMEL_CHECK_LOCAL_GERROR (
		subscribable, unsubscribe_folder_sync, success, local_error);

	if (success)
		camel_store_delete_cached_folder (CAMEL_STORE (subscribable), folder_name);

	camel_operation_pop_message (cancellable);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_subscribable_unsubscribe_folder:
 * @subscribable: a #CamelSubscribable
 * @folder_name: full path of the folder
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously unsubscribes from the folder described by @folder_name.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_subscribable_unsubscribe_folder_finish() to get the result of
 * the operation.
 *
 * Since: 3.2
 **/
void
camel_subscribable_unsubscribe_folder (CamelSubscribable *subscribable,
                                       const gchar *folder_name,
                                       gint io_priority,
                                       GCancellable *cancellable,
                                       GAsyncReadyCallback callback,
                                       gpointer user_data)
{
	GTask *task;
	CamelService *service;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_SUBSCRIBABLE (subscribable));
	g_return_if_fail (folder_name != NULL);

	service = CAMEL_SERVICE (subscribable);

	async_context = g_slice_new0 (AsyncContext);
	async_context->folder_name = g_strdup (folder_name);

	task = g_task_new (subscribable, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_subscribable_unsubscribe_folder);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	camel_service_queue_task (
		service, task, subscribable_unsubscribe_folder_thread);

	g_object_unref (task);
}

/**
 * camel_subscribable_unsubscribe_folder_finish:
 * @subscribable: a #CamelSubscribable
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_subscribable_unsubscribe_folder().
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.2
 **/
gboolean
camel_subscribable_unsubscribe_folder_finish (CamelSubscribable *subscribable,
                                              GAsyncResult *result,
                                              GError **error)
{
	g_return_val_if_fail (CAMEL_IS_SUBSCRIBABLE (subscribable), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, subscribable), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_subscribable_unsubscribe_folder), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_subscribable_folder_subscribed:
 * @subscribable: a #CamelSubscribable
 * @folder_info: information about the subscribed folder
 *
 * Emits the #CamelSubscribable::folder-subscribed signal from an idle source
 * on the main loop.  The idle source's priority is #G_PRIORITY_HIGH_IDLE.
 *
 * This function is only intended for Camel providers.
 *
 * Since: 3.2
 **/
void
camel_subscribable_folder_subscribed (CamelSubscribable *subscribable,
                                      CamelFolderInfo *folder_info)
{
	CamelService *service;
	CamelSession *session;
	SignalClosure *signal_closure;

	g_return_if_fail (CAMEL_IS_SUBSCRIBABLE (subscribable));
	g_return_if_fail (folder_info != NULL);

	service = CAMEL_SERVICE (subscribable);
	session = camel_service_ref_session (service);

	if (!session)
		return;

	signal_closure = g_slice_new0 (SignalClosure);
	g_weak_ref_init (&signal_closure->subscribable, subscribable);
	signal_closure->folder_info = camel_folder_info_clone (folder_info);

	/* Prioritize ahead of GTK+ redraws. */
	camel_session_idle_add (
		session, G_PRIORITY_HIGH_IDLE,
		subscribable_emit_folder_subscribed_cb,
		signal_closure,
		(GDestroyNotify) signal_closure_free);

	g_object_unref (session);
}

/**
 * camel_subscribable_folder_unsubscribed:
 * @subscribable: a #CamelSubscribable
 * @folder_info: information about the unsubscribed folder
 *
 * Emits the #CamelSubscribable::folder-unsubscribed signal from an idle source
 * on the main loop.  The idle source's priority is #G_PRIORITY_HIGH_IDLE.
 *
 * This function is only intended for Camel providers.
 *
 * Since: 3.2
 **/
void
camel_subscribable_folder_unsubscribed (CamelSubscribable *subscribable,
                                        CamelFolderInfo *folder_info)
{
	CamelService *service;
	CamelSession *session;
	SignalClosure *signal_closure;

	g_return_if_fail (CAMEL_IS_SUBSCRIBABLE (subscribable));
	g_return_if_fail (folder_info != NULL);

	service = CAMEL_SERVICE (subscribable);
	session = camel_service_ref_session (service);

	if (!session)
		return;

	signal_closure = g_slice_new0 (SignalClosure);
	g_weak_ref_init (&signal_closure->subscribable, subscribable);
	signal_closure->folder_info = camel_folder_info_clone (folder_info);

	/* Prioritize ahead of GTK+ redraws. */
	camel_session_idle_add (
		session, G_PRIORITY_HIGH_IDLE,
		subscribable_emit_folder_unsubscribed_cb,
		signal_closure,
		(GDestroyNotify) signal_closure_free);

	g_object_unref (session);
}

