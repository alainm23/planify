/*
 * e-user-prompter-server.c
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
 * SECTION: e-user-prompter-server
 * @short_description: Server-side user prompter
 *
 * The #EUserPrompterServer is the heart of the user prompter D-Bus service.
 * Acting as a global singleton for user prompts from backends.
 **/

#include "evolution-data-server-config.h"

#include <string.h>
#include <glib/gi18n-lib.h>

#include <libedataserver/libedataserver.h>

/* Private D-Bus classes. */
#include "e-dbus-user-prompter.h"

#include "e-user-prompter-server-extension.h"
#include "e-user-prompter-server.h"

#define E_USER_PROMPTER_SERVER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_USER_PROMPTER_SERVER, EUserPrompterServerPrivate))

struct _EUserPrompterServerPrivate {
	EDBusUserPrompter *dbus_prompter;

	GHashTable *extensions;

	GRecMutex lock;
	guint schedule_id;
	GSList *prompts;
	gint last_prompt_id;
};

enum {
	PROMPT,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE_WITH_CODE (
	EUserPrompterServer,
	e_user_prompter_server,
	E_TYPE_DBUS_SERVER,
	G_IMPLEMENT_INTERFACE (
		E_TYPE_EXTENSIBLE, NULL))

typedef struct _PromptRequest {
	gint id;
	gboolean is_extension_prompt;

	/* 'Prompt' properties */
	gchar *type;
	gchar *title;
	gchar *primary_text;
	gchar *secondary_text;
	gboolean use_markup;
	GSList *button_captions;

	/* 'ExtensionPrompt' properties */
	gchar *dialog_name;
	ENamedParameters *parameters;
} PromptRequest;

static void
prompt_request_free (gpointer data)
{
	PromptRequest *pr = data;

	if (pr) {
		g_free (pr->type);
		g_free (pr->title);
		g_free (pr->primary_text);
		g_free (pr->secondary_text);
		g_slist_free_full (pr->button_captions, g_free);

		g_free (pr->dialog_name);
		e_named_parameters_free (pr->parameters);

		g_free (pr);
	}
}

static gint
add_prompt (EUserPrompterServer *server,
            gboolean is_extension_prompt,
            const gchar *type,
            const gchar *title,
            const gchar *primary_text,
            const gchar *secondary_text,
            gboolean use_markup,
            const gchar *const *button_captions,
            const gchar *dialog_name,
            const gchar *const *parameters)
{
	PromptRequest *pr;
	gint id;

	g_return_val_if_fail (E_IS_USER_PROMPTER_SERVER (server), -1);

	g_rec_mutex_lock (&server->priv->lock);

	server->priv->last_prompt_id++;

	pr = g_new0 (PromptRequest, 1);
	pr->is_extension_prompt = is_extension_prompt;
	pr->id = server->priv->last_prompt_id;
	pr->type = g_strdup (type);
	pr->title = g_strdup (title);
	pr->primary_text = g_strdup (primary_text);
	pr->secondary_text = g_strdup (secondary_text);
	pr->use_markup = use_markup;
	pr->button_captions = e_util_strv_to_slist (button_captions);
	pr->dialog_name = g_strdup (dialog_name);
	pr->parameters = parameters ? e_named_parameters_new_strv (parameters) : NULL;

	server->priv->prompts = g_slist_append (server->priv->prompts, pr);

	id = pr->id;

	e_dbus_server_hold (E_DBUS_SERVER (server));

	g_rec_mutex_unlock (&server->priv->lock);

	return id;
}

static gboolean
remove_prompt (EUserPrompterServer *server,
               gint prompt_id,
               gboolean *is_extension_prompt)
{
	GSList *iter;

	g_return_val_if_fail (E_IS_USER_PROMPTER_SERVER (server), FALSE);

	g_rec_mutex_lock (&server->priv->lock);

	for (iter = server->priv->prompts; iter; iter = g_slist_next (iter)) {
		PromptRequest *pr = iter->data;

		if (pr && pr->id == prompt_id) {
			server->priv->prompts = g_slist_remove (
				server->priv->prompts, pr);

			if (is_extension_prompt)
				*is_extension_prompt = pr->is_extension_prompt;

			prompt_request_free (pr);
			e_dbus_server_release (E_DBUS_SERVER (server));

			g_rec_mutex_unlock (&server->priv->lock);
			return TRUE;
		}
	}

	g_rec_mutex_unlock (&server->priv->lock);

	g_warn_if_reached ();

	return FALSE;
}

static void
do_show_prompt (EUserPrompterServer *server)
{
	PromptRequest *pr;

	g_return_if_fail (server->priv->prompts != NULL);

	pr = server->priv->prompts->data;
	g_return_if_fail (pr != NULL);

	if (pr->is_extension_prompt) {
		EUserPrompterServerExtension *extension;

		extension = g_hash_table_lookup (
			server->priv->extensions, pr->dialog_name);
		g_return_if_fail (extension != NULL);

		if (!e_user_prompter_server_extension_prompt (
				extension,
				pr->id,
				pr->dialog_name,
				pr->parameters)) {
			e_user_prompter_server_response (
				server, pr->id, -1, NULL);
		}
	} else {
		g_signal_emit (
			server,
			signals[PROMPT], 0,
			pr->id,
			pr->type,
			pr->title,
			pr->primary_text,
			pr->secondary_text,
			pr->use_markup,
			pr->button_captions);
	}
}

static gboolean
show_prompt_idle_cb (gpointer user_data)
{
	EUserPrompterServer *server = user_data;

	g_return_val_if_fail (E_IS_USER_PROMPTER_SERVER (server), FALSE);

	g_rec_mutex_lock (&server->priv->lock);
	if (server->priv->prompts) {
		do_show_prompt (server);
		/* keep the schedule_id set, until user responds */
	} else {
		server->priv->schedule_id = 0;
	}
	g_rec_mutex_unlock (&server->priv->lock);

	return FALSE;
}

static void
maybe_schedule_prompt (EUserPrompterServer *server)
{
	g_return_if_fail (E_IS_USER_PROMPTER_SERVER (server));

	g_rec_mutex_lock (&server->priv->lock);
	if (!server->priv->schedule_id && server->priv->prompts)
		server->priv->schedule_id = g_idle_add (
			show_prompt_idle_cb, server);
	g_rec_mutex_unlock (&server->priv->lock);
}

static gboolean
user_prompter_server_prompt_cb (EDBusUserPrompter *dbus_prompter,
                                GDBusMethodInvocation *invocation,
                                const gchar *type,
                                const gchar *title,
                                const gchar *primary_text,
                                const gchar *secondary_text,
                                gboolean use_markup,
                                const gchar *const *button_captions,
                                EUserPrompterServer *server)
{
	gint id;

	g_rec_mutex_lock (&server->priv->lock);

	id = add_prompt (
		server, FALSE, type, title,
		primary_text, secondary_text,
		use_markup, button_captions, NULL, NULL);

	e_dbus_user_prompter_complete_prompt (dbus_prompter, invocation, id);

	maybe_schedule_prompt (server);

	g_rec_mutex_unlock (&server->priv->lock);

	return TRUE;
}

static gboolean
user_prompter_server_extension_prompt_cb (EDBusUserPrompter *dbus_prompter,
                                          GDBusMethodInvocation *invocation,
                                          const gchar *dialog_name,
                                          const gchar *const *parameters,
                                          EUserPrompterServer *server)
{
	gboolean found_dialog;
	gint id;

	g_rec_mutex_lock (&server->priv->lock);

	found_dialog =
		(dialog_name != NULL) &&
		g_hash_table_contains (server->priv->extensions, dialog_name);

	if (!found_dialog) {
		g_rec_mutex_unlock (&server->priv->lock);

		g_dbus_method_invocation_return_error (
			invocation, G_IO_ERROR, G_IO_ERROR_NOT_FOUND,
			_("Extension dialog “%s” not found."),
			dialog_name ? dialog_name : "[null]");

		return TRUE;
	}

	id = add_prompt (
		server, TRUE, NULL, NULL, NULL, NULL, FALSE, NULL,
		dialog_name, parameters);

	e_dbus_user_prompter_complete_extension_prompt (
		dbus_prompter, invocation, id);

	maybe_schedule_prompt (server);

	g_rec_mutex_unlock (&server->priv->lock);

	return TRUE;
}

static void
user_prompter_server_constructed (GObject *object)
{
	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_user_prompter_server_parent_class)->constructed (object);

	e_extensible_load_extensions (E_EXTENSIBLE (object));
}

static void
user_prompter_server_dispose (GObject *object)
{
	EUserPrompterServerPrivate *priv;

	priv = E_USER_PROMPTER_SERVER_GET_PRIVATE (object);

	if (priv->dbus_prompter != NULL) {
		g_object_unref (priv->dbus_prompter);
		priv->dbus_prompter = NULL;
	}

	g_slist_free_full (priv->prompts, prompt_request_free);
	g_hash_table_remove_all (priv->extensions);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_user_prompter_server_parent_class)->dispose (object);
}

static void
user_prompter_server_finalize (GObject *object)
{
	EUserPrompterServerPrivate *priv;

	priv = E_USER_PROMPTER_SERVER_GET_PRIVATE (object);

	g_rec_mutex_clear (&priv->lock);
	g_hash_table_destroy (priv->extensions);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_user_prompter_server_parent_class)->finalize (object);
}

static void
user_prompter_server_bus_acquired (EDBusServer *server,
                                     GDBusConnection *connection)
{
	EUserPrompterServerPrivate *priv;
	GError *error = NULL;

	priv = E_USER_PROMPTER_SERVER_GET_PRIVATE (server);

	g_dbus_interface_skeleton_export (
		G_DBUS_INTERFACE_SKELETON (priv->dbus_prompter),
		connection, E_USER_PROMPTER_SERVER_OBJECT_PATH, &error);

	/* Terminate the server if we can't export the interface. */
	if (error != NULL) {
		g_warning ("%s: %s", G_STRFUNC, error->message);
		e_dbus_server_quit (server, E_DBUS_SERVER_EXIT_NORMAL);
		g_error_free (error);
	}

	/* Chain up to parent's bus_acquired() method. */
	E_DBUS_SERVER_CLASS (e_user_prompter_server_parent_class)->
		bus_acquired (server, connection);
}

static void
user_prompter_server_quit_server (EDBusServer *server,
                                  EDBusServerExitCode code)
{
	EUserPrompterServerPrivate *priv;

	priv = E_USER_PROMPTER_SERVER_GET_PRIVATE (server);

	g_dbus_interface_skeleton_unexport (
		G_DBUS_INTERFACE_SKELETON (priv->dbus_prompter));

	/* Chain up to parent's quit_server() method. */
	E_DBUS_SERVER_CLASS (e_user_prompter_server_parent_class)->
		quit_server (server, code);
}

static void
e_user_prompter_server_class_init (EUserPrompterServerClass *class)
{
	GObjectClass *object_class;
	EDBusServerClass *dbus_server_class;

	g_type_class_add_private (class, sizeof (EUserPrompterServerPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->constructed = user_prompter_server_constructed;
	object_class->dispose = user_prompter_server_dispose;
	object_class->finalize = user_prompter_server_finalize;

	dbus_server_class = E_DBUS_SERVER_CLASS (class);
	dbus_server_class->bus_name = USER_PROMPTER_DBUS_SERVICE_NAME;
	dbus_server_class->module_directory = MODULE_DIRECTORY;
	dbus_server_class->bus_acquired = user_prompter_server_bus_acquired;
	dbus_server_class->quit_server = user_prompter_server_quit_server;

	signals[PROMPT] = g_signal_new (
		"prompt",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EUserPrompterServerClass, prompt),
		NULL, NULL, NULL,
		G_TYPE_NONE, 7,
		G_TYPE_INT,
		G_TYPE_STRING,
		G_TYPE_STRING,
		G_TYPE_STRING,
		G_TYPE_STRING,
		G_TYPE_BOOLEAN,
		G_TYPE_POINTER);
}

static void
e_user_prompter_server_init (EUserPrompterServer *server)
{
	server->priv = E_USER_PROMPTER_SERVER_GET_PRIVATE (server);
	server->priv->dbus_prompter = e_dbus_user_prompter_skeleton_new ();
	server->priv->prompts = NULL;
	server->priv->extensions = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) g_object_unref);

	g_rec_mutex_init (&server->priv->lock);

	g_signal_connect (
		server->priv->dbus_prompter, "handle-prompt",
		G_CALLBACK (user_prompter_server_prompt_cb), server);

	g_signal_connect (
		server->priv->dbus_prompter, "handle-extension-prompt",
		G_CALLBACK (user_prompter_server_extension_prompt_cb), server);
}

/**
 * e_user_prompter_server_new:
 *
 * Creates a new instance of #EUserPrompterServer.
 *
 * Returns: a new instance of #EUserPrompterServer
 *
 * Since: 3.8
 **/
EDBusServer *
e_user_prompter_server_new (void)
{
	return g_object_new (E_TYPE_USER_PROMPTER_SERVER, NULL);
}

/**
 * e_user_prompter_server_response:
 * @server: an #EUserPrompterServer
 * @prompt_id: Id of a prompt, which was responded
 * @response: Response of the prompt
 * @extension_values: (allow-none): For extension prompts can pass extra return values
 *
 * Finishes prompt initiated by a "prompt" signal or an extension prompt.
 * The @response for non-extension prompts is a 0-based index of a button
 * used to close the prompt.
 *
 * The @extension_values is ignored for non-extension prompts.
 *
 * Since: 3.8
 **/
void
e_user_prompter_server_response (EUserPrompterServer *server,
                                 gint prompt_id,
                                 gint response,
                                 const ENamedParameters *extension_values)
{
	gboolean is_extension_prompt = FALSE;

	g_return_if_fail (E_IS_USER_PROMPTER_SERVER (server));
	g_return_if_fail (server->priv->schedule_id != 0);

	g_rec_mutex_lock (&server->priv->lock);

	if (!server->priv->prompts || server->priv->schedule_id == 0) {
		g_rec_mutex_unlock (&server->priv->lock);
		g_return_if_reached ();
		return;
	}

	if (remove_prompt (server, prompt_id, &is_extension_prompt)) {
		if (is_extension_prompt) {
			gchar **values;

			values = e_named_parameters_to_strv (extension_values);

			e_dbus_user_prompter_emit_extension_response (
				server->priv->dbus_prompter,
				prompt_id, response,
				(const gchar * const *) values);

			if (values)
				g_strfreev (values);
		} else {
			e_dbus_user_prompter_emit_response (
				server->priv->dbus_prompter,
				prompt_id, response);
		}
	}

	if (server->priv->prompts) {
		do_show_prompt (server);
	} else {
		server->priv->schedule_id = 0;
	}

	g_rec_mutex_unlock (&server->priv->lock);
}

/**
 * e_user_prompter_server_register:
 * @server: an #EUserPrompterServer
 * @extension: an #EUserPrompterServerExtension descendant
 * @dialog_name: name of a dialog, which the @extensions implement
 *
 * Registers @extension as a provider of @dialog_name dialog. The names
 * are compared case sensitively and two extensions cannot provide
 * the same dialog. If the function succeeds, then it adds its own
 * reference on the @extension.
 *
 * Extensions providing multiple dialogs call this function multiple
 * times, for each dialog name separately.
 *
 * Returns: Whether properly registered @extension
 *
 * Since: 3.8
 **/
gboolean
e_user_prompter_server_register (EUserPrompterServer *server,
                                 EExtension *extension,
                                 const gchar *dialog_name)
{
	g_return_val_if_fail (E_IS_USER_PROMPTER_SERVER (server), FALSE);
	g_return_val_if_fail (E_IS_USER_PROMPTER_SERVER_EXTENSION (extension), FALSE);
	g_return_val_if_fail (dialog_name != NULL, FALSE);
	g_return_val_if_fail (*dialog_name != '\0', FALSE);

	g_rec_mutex_lock (&server->priv->lock);

	if (g_hash_table_lookup (server->priv->extensions, dialog_name)) {
		g_rec_mutex_unlock (&server->priv->lock);
		return FALSE;
	}

	e_source_registry_debug_print (
		"Registering %s for dialog '%s'\n",
		G_OBJECT_TYPE_NAME (extension), dialog_name);
	g_hash_table_insert (
		server->priv->extensions,
		g_strdup (dialog_name),
		g_object_ref (extension));

	g_rec_mutex_unlock (&server->priv->lock);

	return TRUE;
}
