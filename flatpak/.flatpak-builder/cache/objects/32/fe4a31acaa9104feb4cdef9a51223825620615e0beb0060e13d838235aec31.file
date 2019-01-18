/*
 * e-user-prompter.c
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
 * SECTION: e-user-prompter
 * @include: libebackend/libebackend.h
 * @short_description: Manages user prompts over DBus
 *
 * Use this to initiate a user prompt from an #EBackend descendant.
 **/

#include "evolution-data-server-config.h"

#include <libedataserver/libedataserver.h>

#include "e-dbus-user-prompter.h"
#include "e-user-prompter.h"

#define E_USER_PROMPTER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_USER_PROMPTER, EUserPrompterPrivate))

struct _EUserPrompterPrivate {
	gint dummy; /* not used */
};

G_DEFINE_TYPE (EUserPrompter, e_user_prompter, G_TYPE_OBJECT)

static void
e_user_prompter_class_init (EUserPrompterClass *class)
{
	g_type_class_add_private (class, sizeof (EUserPrompterPrivate));
}

static void
e_user_prompter_init (EUserPrompter *prompter)
{
	prompter->priv = E_USER_PROMPTER_GET_PRIVATE (prompter);
}

/**
 * e_user_prompter_new:
 *
 * Creates a new instance of #EUserPrompter.
 *
 * Returns: a new instance of #EUserPrompter
 *
 * Since: 3.8
 **/
EUserPrompter *
e_user_prompter_new (void)
{
	return g_object_new (E_TYPE_USER_PROMPTER, NULL);
}

typedef struct _PrompterAsyncData {
	/* Prompt data */
	gchar *type;
	gchar *title;
	gchar *primary_text;
	gchar *secondary_text;
	gboolean use_markup;
	GList *button_captions;

	/* ExtensionPrompt data */
	gchar *dialog_name;
	ENamedParameters *in_parameters;
	ENamedParameters *out_values;

	/* common data */
	gint response_button;

	/* callbacks */
	gchar *response_signal_name;
	GCallback response_callback;
	gboolean (* invoke) (EDBusUserPrompter *dbus_prompter,
			     struct _PrompterAsyncData *async_data,
			     GCancellable *cancellable,
			     GError **error);

	/* Internal data */
	gint prompt_id;
	GMainLoop *main_loop; /* not owned by the structure */
} PrompterAsyncData;

static void
prompter_async_data_free (PrompterAsyncData *async_data)
{
	if (!async_data)
		return;

	g_free (async_data->type);
	g_free (async_data->title);
	g_free (async_data->primary_text);
	g_free (async_data->secondary_text);
	g_list_free_full (async_data->button_captions, g_free);

	g_free (async_data->dialog_name);
	e_named_parameters_free (async_data->in_parameters);
	e_named_parameters_free (async_data->out_values);

	g_free (async_data->response_signal_name);

	g_free (async_data);
}

static void
user_prompter_response_cb (EDBusUserPrompter *dbus_prompter,
                           gint prompt_id,
                           gint response_button,
                           PrompterAsyncData *async_data)
{
	g_return_if_fail (async_data != NULL);

	if (async_data->prompt_id == prompt_id) {
		async_data->response_button = response_button;
		g_main_loop_quit (async_data->main_loop);
	}
}

static gboolean
user_prompter_prompt_invoke (EDBusUserPrompter *dbus_prompter,
                             struct _PrompterAsyncData *async_data,
                             GCancellable *cancellable,
                             GError **error)
{
	GPtrArray *captions;
	GList *list, *link;
	GError *local_error = NULL;

	g_return_val_if_fail (dbus_prompter != NULL, FALSE);
	g_return_val_if_fail (async_data != NULL, FALSE);

	list = async_data->button_captions;

	captions = g_ptr_array_new ();

	for (link = list; link != NULL; link = g_list_next (link)) {
		gchar *caption = link->data;

		g_ptr_array_add (captions, caption ? caption : (gchar *) "");
	}

	/* NULL-terminated array */
	g_ptr_array_add (captions, NULL);

	e_dbus_user_prompter_call_prompt_sync (
		dbus_prompter,
		async_data->type ? async_data->type : "",
		async_data->title ? async_data->title : "",
		async_data->primary_text ? async_data->primary_text : "",
		async_data->secondary_text ? async_data->secondary_text : "",
		async_data->use_markup,
		(const gchar *const *) captions->pdata,
		&async_data->prompt_id,
		cancellable, &local_error);

	g_ptr_array_free (captions, TRUE);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

static void
user_prompter_extension_response_cb (EDBusUserPrompter *dbus_prompter,
                                     gint prompt_id,
                                     gint response_button,
                                     const gchar * const *arg_values,
                                     PrompterAsyncData *async_data)
{
	g_return_if_fail (async_data != NULL);

	if (async_data->prompt_id == prompt_id) {
		async_data->response_button = response_button;
		if (arg_values)
			async_data->out_values = e_named_parameters_new_strv (arg_values);
		g_main_loop_quit (async_data->main_loop);
	}
}

static gboolean
user_prompter_extension_prompt_invoke (EDBusUserPrompter *dbus_prompter,
                                       struct _PrompterAsyncData *async_data,
                                       GCancellable *cancellable,
                                       GError **error)
{
	gchar **params;
	GError *local_error = NULL;

	g_return_val_if_fail (dbus_prompter != NULL, FALSE);
	g_return_val_if_fail (async_data != NULL, FALSE);

	params = e_named_parameters_to_strv (async_data->in_parameters);

	e_dbus_user_prompter_call_extension_prompt_sync (
		dbus_prompter,
		async_data->dialog_name,
		(const gchar *const *) params,
		&async_data->prompt_id,
		cancellable, &local_error);

	g_strfreev (params);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

static void
user_prompter_prompt_thread (GSimpleAsyncResult *simple,
                             GObject *object,
                             GCancellable *cancellable)
{
	EDBusUserPrompter *dbus_prompter;
	PrompterAsyncData *async_data;
	GMainContext *main_context;
	GError *local_error = NULL;
	gulong handler_id;

	g_return_if_fail (E_IS_USER_PROMPTER (object));

	async_data = g_simple_async_result_get_op_res_gpointer (simple);
	g_return_if_fail (async_data != NULL);
	g_return_if_fail (async_data->response_signal_name != NULL);
	g_return_if_fail (async_data->response_callback != NULL);
	g_return_if_fail (async_data->invoke != NULL);

	main_context = g_main_context_new ();
	/* this way the Response signal is delivered here, not to the main thread's context,
	 * which can be blocked by the e_user_prompter_prompt_sync() call anyway */
	g_main_context_push_thread_default (main_context);

	dbus_prompter = e_dbus_user_prompter_proxy_new_for_bus_sync (
		G_BUS_TYPE_SESSION,
		G_DBUS_PROXY_FLAGS_NONE,
		USER_PROMPTER_DBUS_SERVICE_NAME,
		"/org/gnome/evolution/dataserver/UserPrompter",
		cancellable,
		&local_error);

	if (!dbus_prompter) {
		g_main_context_pop_thread_default (main_context);

		/* Make sure the main_context doesn't have pending operations;
		 * workarounds https://bugzilla.gnome.org/show_bug.cgi?id=690126 */
		while (g_main_context_pending (main_context))
			g_main_context_iteration (main_context, FALSE);

		g_main_context_unref (main_context);

		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
		return;
	}

	handler_id = g_signal_connect (
		dbus_prompter, async_data->response_signal_name,
		async_data->response_callback, async_data);

	if (!async_data->invoke (dbus_prompter, async_data, cancellable, &local_error)) {
		g_signal_handler_disconnect (dbus_prompter, handler_id);
		g_object_unref (dbus_prompter);

		g_main_context_pop_thread_default (main_context);

		/* Make sure the main_context doesn't have pending operations;
		 * workarounds https://bugzilla.gnome.org/show_bug.cgi?id=690126 */
		while (g_main_context_pending (main_context))
			g_main_context_iteration (main_context, FALSE);

		g_main_context_unref (main_context);

		g_dbus_error_strip_remote_error (local_error);
		g_simple_async_result_take_error (simple, local_error);
		return;
	}

	async_data->main_loop = g_main_loop_new (main_context, FALSE);

	g_main_loop_run (async_data->main_loop);

	g_main_loop_unref (async_data->main_loop);
	async_data->main_loop = NULL;

	g_signal_handler_disconnect (dbus_prompter, handler_id);
	g_object_unref (dbus_prompter);

	g_main_context_pop_thread_default (main_context);

	/* Make sure the main_context doesn't have pending operations;
	 * workarounds https://bugzilla.gnome.org/show_bug.cgi?id=690126 */
	while (g_main_context_pending (main_context))
		g_main_context_iteration (main_context, FALSE);

	g_main_context_unref (main_context);
}

/**
 * e_user_prompter_prompt:
 * @prompter: an #EUserPrompter
 * @type: (allow-none): type of the prompt; can be %NULL
 * @title: (allow-none): window title of the prompt; can be %NULL
 * @primary_text: (allow-none): primary text of the prompt; can be %NULL
 * @secondary_text: (allow-none): secondary text of the prompt; can be %NULL
 * @use_markup: whether both texts are with markup
 * @button_captions: (allow-none): captions of buttons to use in the message; can be %NULL
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously prompt a user for a decision.
 *
 * The @type can be one of "info", "warning", "question" or "error", to include
 * an icon in the message prompt; anything else results in no icon in the message.
 *
 * If @button_captions is %NULL or empty list, then only one button is shown in
 * the prompt, a "Dismiss" button.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_user_prompter_prompt_finish() to get the result of the operation.
 *
 * Since: 3.8
 **/
void
e_user_prompter_prompt (EUserPrompter *prompter,
                        const gchar *type,
                        const gchar *title,
                        const gchar *primary_text,
                        const gchar *secondary_text,
                        gboolean use_markup,
                        GList *button_captions,
                        GCancellable *cancellable,
                        GAsyncReadyCallback callback,
                        gpointer user_data)
{
	GSimpleAsyncResult *simple;
	PrompterAsyncData *async_data;

	g_return_if_fail (E_IS_USER_PROMPTER (prompter));
	g_return_if_fail (callback != NULL);

	simple = g_simple_async_result_new (
		G_OBJECT (prompter), callback, user_data,
		e_user_prompter_prompt);

	async_data = g_new0 (PrompterAsyncData, 1);
	async_data->type = g_strdup (type);
	async_data->title = g_strdup (title);
	async_data->primary_text = g_strdup (primary_text);
	async_data->secondary_text = g_strdup (secondary_text);
	async_data->use_markup = use_markup;
	async_data->button_captions = g_list_copy_deep (
		button_captions, (GCopyFunc) g_strdup, NULL);
	async_data->prompt_id = -1;
	async_data->response_button = -1;

	async_data->response_signal_name = g_strdup ("response");
	async_data->response_callback = G_CALLBACK (user_prompter_response_cb);
	async_data->invoke = user_prompter_prompt_invoke;

	g_simple_async_result_set_op_res_gpointer (simple, async_data, (GDestroyNotify) prompter_async_data_free);
	g_simple_async_result_run_in_thread (simple, user_prompter_prompt_thread, G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_user_prompter_prompt_finish:
 * @prompter: an #EUserPrompter
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_user_prompter_prompt().
 *
 * If an error occurred, the function sets @error and returns -1.
 *
 * Returns: 0-based index of a button being used by a user as a response,
 *   corresponding to 'button_captions' from e_user_prompter_prompt() call.
 *
 * Since: 3.8
 **/
gint
e_user_prompter_prompt_finish (EUserPrompter *prompter,
                               GAsyncResult *result,
                               GError **error)
{
	GSimpleAsyncResult *simple;
	PrompterAsyncData *async_data;

	g_return_val_if_fail (E_IS_USER_PROMPTER (prompter), -1);
	g_return_val_if_fail (g_simple_async_result_is_valid (result, G_OBJECT (prompter), e_user_prompter_prompt), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_data = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return -1;

	g_return_val_if_fail (async_data != NULL, -1);

	return async_data->response_button;
}

/**
 * e_user_prompter_prompt_sync:
 * @prompter: an #EUserPrompter
 * @type: (allow-none): type of the prompt; can be %NULL
 * @title: (allow-none): window title of the prompt; can be %NULL
 * @primary_text: (allow-none): primary text of the prompt; can be %NULL
 * @secondary_text: (allow-none): secondary text of the prompt; can be %NULL
 * @use_markup: whether both texts are with markup
 * @button_captions: (allow-none): captions of buttons to use in the message; can be %NULL
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Prompts a user for a decision.
 *
 * The @type can be one of "info", "warning", "question" or "error", to include
 * an icon in the message prompt; anything else results in no icon in the message.
 *
 * If @button_captions is %NULL or empty list, then only one button is shown in
 * the prompt, a "Dismiss" button.
 *
 * If an error occurred, the function sets @error and returns -1.
 *
 * Returns: 0-based index of a button being used by a user as a response,
 *   corresponding to @button_captions list.
 *
 * Since: 3.8
 **/
gint
e_user_prompter_prompt_sync (EUserPrompter *prompter,
                             const gchar *type,
                             const gchar *title,
                             const gchar *primary_text,
                             const gchar *secondary_text,
                             gboolean use_markup,
                             GList *button_captions,
                             GCancellable *cancellable,
                             GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gint response_button;

	g_return_val_if_fail (E_IS_USER_PROMPTER (prompter), -1);

	closure = e_async_closure_new ();

	e_user_prompter_prompt (
		prompter, type, title, primary_text, secondary_text,
		use_markup, button_captions, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	response_button = e_user_prompter_prompt_finish (
		prompter, result, error);

	e_async_closure_free (closure);

	return response_button;
}

/**
 * e_user_prompter_extension_prompt:
 * @prompter: an #EUserPrompter
 * @dialog_name: name of a dialog to invoke
 * @in_parameters: (allow-none): optional parameters to pass to extension; can be %NULL
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously prompt a user for a decision on an extension-provided dialog.
 * The caller usually provides an extension for #EUserPrompterServer, a descendant
 * of #EUserPrompterServerExtension, which registers itself as a dialog provider.
 * The extension defines @dialog_name, same as meaning of @in_parameters;
 * only the extension and the caller know about meaning of these.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_user_prompter_extension_prompt_finish() to get the result of the operation.
 * If there is no extension providing given dialog name, the operation finishes with
 * a G_IO_ERROR, G_IO_ERROR_NOT_FOUND #GError.
 *
 * Since: 3.8
 **/
void
e_user_prompter_extension_prompt (EUserPrompter *prompter,
                                  const gchar *dialog_name,
                                  const ENamedParameters *in_parameters,
                                  GCancellable *cancellable,
                                  GAsyncReadyCallback callback,
                                  gpointer user_data)
{
	GSimpleAsyncResult *simple;
	PrompterAsyncData *async_data;

	g_return_if_fail (E_IS_USER_PROMPTER (prompter));
	g_return_if_fail (dialog_name != NULL);
	g_return_if_fail (callback != NULL);

	simple = g_simple_async_result_new (
		G_OBJECT (prompter), callback, user_data,
		e_user_prompter_extension_prompt);

	async_data = g_new0 (PrompterAsyncData, 1);
	async_data->dialog_name = g_strdup (dialog_name);
	if (in_parameters) {
		async_data->in_parameters = e_named_parameters_new ();
		e_named_parameters_assign (async_data->in_parameters, in_parameters);
	} else {
		async_data->in_parameters = NULL;
	}

	async_data->prompt_id = -1;
	async_data->response_button = -1;
	async_data->out_values = NULL;

	async_data->response_signal_name = g_strdup ("extension-response");
	async_data->response_callback = G_CALLBACK (user_prompter_extension_response_cb);
	async_data->invoke = user_prompter_extension_prompt_invoke;

	g_simple_async_result_set_op_res_gpointer (simple, async_data, (GDestroyNotify) prompter_async_data_free);
	g_simple_async_result_run_in_thread (simple, user_prompter_prompt_thread, G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_user_prompter_extension_prompt_finish:
 * @prompter: an #EUserPrompter
 * @result: a #GAsyncResult
 * @out_values: (allow-none): Where to store values from the extension, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_user_prompter_extension_prompt().
 * Caller can provide @out_values to get additional values provided by the extension.
 * In case the caller is not interested in additional values, it can pass %NULL @out_values.
 * The @out_values will be cleared first, then any values will be added there.
 * Only the caller and the extension know about meaning of the result code and
 * additional values.
 *
 * If an error occurred, the function sets @error and returns -1. If there is
 * no extension providing given dialog name, the operation finishes with
 * a G_IO_ERROR, G_IO_ERROR_NOT_FOUND @error.
 *
 * Returns: Result code of the prompt, as defined by the extension, or -1 on error.
 *
 * Since: 3.8
 **/
gint
e_user_prompter_extension_prompt_finish (EUserPrompter *prompter,
                                         GAsyncResult *result,
                                         ENamedParameters *out_values,
                                         GError **error)
{
	GSimpleAsyncResult *simple;
	PrompterAsyncData *async_data;

	g_return_val_if_fail (E_IS_USER_PROMPTER (prompter), -1);
	g_return_val_if_fail (g_simple_async_result_is_valid (result, G_OBJECT (prompter), e_user_prompter_extension_prompt), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_data = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return -1;

	g_return_val_if_fail (async_data != NULL, -1);

	if (out_values)
		e_named_parameters_assign (out_values, async_data->out_values);

	return async_data->response_button;
}

/**
 * e_user_prompter_extension_prompt_sync:
 * @prompter: an #EUserPrompter
 * @dialog_name: name of a dialog to invoke
 * @in_parameters: (allow-none): optional parameters to pass to extension; can be %NULL
 * @out_values: (allow-none): Where to store values from the extension, or %NULL
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Synchronously prompt a user for a decision on an extension-provided dialog.
 * The caller usually provides an extension for #EUserPrompterServer, a descendant
 * of #EUserPrompterServerExtension, which registers itself as a dialog provider.
 * The extension defines @dialog_name, same as meaning of @in_parameters;
 * only the extension and the caller know about meaning of these.
 *
 * Caller can provide @out_values to get additional values provided by the extension.
 * In case the caller is not interested in additional values, it can pass %NULL @out_values.
 * The @out_values will be cleared first, then any values will be added there.
 * Only the caller and the extension know about meaning of the result code and
 * additional values.
 *
 * If an error occurred, the function sets @error and returns -1. If there is
 * no extension providing given dialog name, the operation finishes with
 * a G_IO_ERROR, G_IO_ERROR_NOT_FOUND @error.
 *
 * Returns: Result code of the prompt, as defined by the extension, or -1 on error.
 *
 * Since: 3.8
 **/
gint
e_user_prompter_extension_prompt_sync (EUserPrompter *prompter,
                                       const gchar *dialog_name,
                                       const ENamedParameters *in_parameters,
                                       ENamedParameters *out_values,
                                       GCancellable *cancellable,
                                       GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gint response_button;

	g_return_val_if_fail (E_IS_USER_PROMPTER (prompter), -1);
	g_return_val_if_fail (dialog_name != NULL, -1);

	closure = e_async_closure_new ();

	e_user_prompter_extension_prompt (
		prompter, dialog_name, in_parameters,
		cancellable, e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	response_button = e_user_prompter_extension_prompt_finish (prompter, result, out_values, error);

	e_async_closure_free (closure);

	return response_button;
}
