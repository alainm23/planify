/*
 * Copyright (C) 2015 Red Hat, Inc. (www.redhat.com)
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

#include <glib.h>
#include <glib/gi18n-lib.h>

#include <camel/camel.h>
#include <libedataserver/libedataserver.h>

#include "e-credentials-prompter.h"

/* built-in credentials prompter implementations */
#include "e-credentials-prompter-impl-password.h"
#include "e-credentials-prompter-impl-oauth2.h"

typedef struct _ProcessPromptData {
	GWeakRef *prompter;
	ECredentialsPrompterImpl *prompter_impl;
	ESource *auth_source;
	ESource *cred_source;
	ESourceConnectionStatus connection_status; /* of the auth_source */
	gboolean remember_password; /* of the cred_source, to check for changes */
	gulong notify_handler_id;
	gchar *error_text;
	ENamedParameters *credentials;
	gboolean allow_source_save;
	GSimpleAsyncResult *async_result;
} ProcessPromptData;

struct _ECredentialsPrompterPrivate {
	ESourceRegistry *registry;
	ESourceCredentialsProvider *provider;
	gboolean auto_prompt;
	GCancellable *cancellable;

	GMutex disabled_auto_prompt_lock;
	GHashTable *disabled_auto_prompt; /* gchar *source_uid ~> 1; Source UIDs for which the auto-prompt is disabled */

	GMutex prompters_lock;
	GHashTable *prompters; 		/* gchar *method ~> ECredentialsPrompterImpl *impl */
	GHashTable *known_prompters;	/* gpointer [ECredentialsPrompterImpl] ~> UINT known instances; the prompter_impl is not referenced */

	GRecMutex queue_lock;		/* guards all queue and schedule related properties */
	GSList *queue;			/* ProcessPromptData * */
	ProcessPromptData *processing_prompt;
	gulong schedule_idle_id;
};

enum {
	PROP_0,
	PROP_AUTO_PROMPT,
	PROP_REGISTRY,
	PROP_PROVIDER
};

enum {
	GET_DIALOG_PARENT,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE_WITH_CODE (ECredentialsPrompter, e_credentials_prompter, G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (E_TYPE_EXTENSIBLE, NULL))

static void
process_prompt_data_free (gpointer ptr)
{
	ProcessPromptData *ppd = ptr;

	if (ppd) {
		if (ppd->notify_handler_id > 0)
			g_signal_handler_disconnect (ppd->auth_source, ppd->notify_handler_id);

		if (ppd->async_result) {
			ECredentialsPrompter *prompter;

			prompter = g_weak_ref_get (ppd->prompter);
			if (prompter) {
				e_credentials_prompter_complete_prompt_call (prompter, ppd->async_result, ppd->auth_source, NULL, NULL);
				g_clear_object (&prompter);
			}
		}

		e_weak_ref_free (ppd->prompter);
		g_clear_object (&ppd->prompter_impl);
		g_clear_object (&ppd->auth_source);
		g_clear_object (&ppd->cred_source);
		g_free (ppd->error_text);
		e_named_parameters_free (ppd->credentials);
		g_free (ppd);
	}
}

typedef struct _LookupSourceDetailsData {
	ESource *auth_source; /* an ESource which asked for credentials */
	ESource *cred_source; /* this might be auth_source or a parent collection source, if applicable, from where the credentials come */
	ENamedParameters *credentials; /* actual stored credentials */
} LookupSourceDetailsData;

static void
lookup_source_details_data_free (gpointer ptr)
{
	LookupSourceDetailsData *data = ptr;

	if (data) {
		g_clear_object (&data->auth_source);
		g_clear_object (&data->cred_source);
		e_named_parameters_free (data->credentials);
		g_free (data);
	}
}

static void
credentials_prompter_lookup_source_details_thread (GTask *task,
						   gpointer source_object,
						   gpointer task_data,
						   GCancellable *cancellable)
{
	ESource *source, *cred_source = NULL;
	ECredentialsPrompter *prompter;
	ESourceCredentialsProvider *provider;
	ENamedParameters *credentials = NULL;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_SOURCE (source_object));

	source = E_SOURCE (source_object);

	prompter = g_weak_ref_get (task_data);
	if (!prompter)
		return;

	provider = e_credentials_prompter_get_provider (prompter);
	cred_source = e_source_credentials_provider_ref_credentials_source (provider, source);

	e_source_credentials_provider_lookup_sync (provider, cred_source ? cred_source : source, cancellable, &credentials, &local_error);

	/* Interested only in the cancelled error, which means the prompter is freed. */
	if (local_error != NULL && g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
		g_task_return_error (task, local_error);
		local_error = NULL;
	} else {
		LookupSourceDetailsData *data;

		data = g_new0 (LookupSourceDetailsData, 1);
		data->auth_source = g_object_ref (source);
		data->cred_source = g_object_ref (cred_source ? cred_source : source); /* always set both, for simplicity */
		data->credentials = credentials; /* NULL for no credentials available */

		/* To not be freed below. */
		credentials = NULL;

		g_task_return_pointer (task, data, lookup_source_details_data_free);
	}

	e_named_parameters_free (credentials);
	g_clear_object (&cred_source);
	g_clear_object (&prompter);
	g_clear_error (&local_error);
}

static void
credentials_prompter_lookup_source_details (ESource *source,
					    ECredentialsPrompter *prompter,
					    GAsyncReadyCallback callback,
					    gpointer user_data)
{
	GTask *task;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));

	task = g_task_new (source, prompter->priv->cancellable, callback, user_data);
	g_task_set_source_tag (task, credentials_prompter_lookup_source_details_thread);
	g_task_set_task_data (task, e_weak_ref_new (prompter), (GDestroyNotify) e_weak_ref_free);

	g_task_run_in_thread (task, credentials_prompter_lookup_source_details_thread);

	g_object_unref (task);
}

static gboolean
credentials_prompter_lookup_source_details_finish (ESource *source,
						   GAsyncResult *result,
						   ECredentialsPrompter **out_prompter, /* will be referenced, if not NULL */
						   LookupSourceDetailsData **out_data,
						   GError **error)
{
	LookupSourceDetailsData *data;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (out_prompter != NULL, FALSE);
	g_return_val_if_fail (out_data != NULL, FALSE);
	g_return_val_if_fail (g_task_is_valid (result, source), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, credentials_prompter_lookup_source_details_thread), FALSE);

	data = g_task_propagate_pointer (G_TASK (result), error);
	if (!data)
		return FALSE;

	*out_data = data;
	*out_prompter = g_weak_ref_get (g_task_get_task_data (G_TASK (result)));

	return TRUE;
}

static void
credentials_prompter_invoke_authenticate_cb (GObject *source_object,
					     GAsyncResult *result,
					     gpointer user_data)
{
	GError *error = NULL;

	if (!e_source_invoke_authenticate_finish (E_SOURCE (source_object), result, &error) &&
	    !g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
		g_debug ("%s: Failed to invoke authenticate: %s", G_STRFUNC, error ? error->message : "Unknown error");
	}

	g_clear_error (&error);
}

typedef struct _CredentialsPromptData {
	ESource *source;
	gchar *error_text;
	ECredentialsPrompterPromptFlags flags;
	GTask *complete_task;
	GSimpleAsyncResult *async_result;
} CredentialsPromptData;

static void
credentials_prompt_data_free (gpointer ptr)
{
	CredentialsPromptData *data = ptr;

	if (data) {
		if (data->async_result) {
			g_simple_async_result_set_error (data->async_result,
				G_IO_ERROR, G_IO_ERROR_CANCELLED, "%s", _("Credentials prompt was cancelled"));
			g_simple_async_result_complete_in_idle (data->async_result);
			g_clear_object (&data->async_result);
		}

		g_clear_object (&data->source);
		g_free (data->error_text);
		g_free (data);
	}
}

typedef struct _CredentialsResultData {
	ESource *source;
	ENamedParameters *credentials;
} CredentialsResultData;

static void
credentials_result_data_free (gpointer ptr)
{
	CredentialsResultData *data = ptr;

	if (data) {
		g_clear_object (&data->source);
		e_named_parameters_free (data->credentials);
		g_free (data);
	}
}


static void
credentials_prompter_maybe_process_next_prompt (ECredentialsPrompter *prompter)
{
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));

	g_rec_mutex_lock (&prompter->priv->queue_lock);

	/* Already processing one */
	if (prompter->priv->processing_prompt) {
		g_rec_mutex_unlock (&prompter->priv->queue_lock);
		return;
	}

	if (prompter->priv->queue) {
		ProcessPromptData *ppd = prompter->priv->queue->data;

		g_warn_if_fail (ppd != NULL);

		prompter->priv->queue = g_slist_remove (prompter->priv->queue, ppd);
		prompter->priv->processing_prompt = ppd;

		e_credentials_prompter_impl_prompt (ppd->prompter_impl, ppd, ppd->auth_source,
			ppd->cred_source, ppd->error_text, ppd->credentials);
	}

	g_rec_mutex_unlock (&prompter->priv->queue_lock);
}

static gboolean
credentials_prompter_process_next_prompt_idle_cb (gpointer user_data)
{
	ECredentialsPrompter *prompter = user_data;

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), FALSE);

	g_rec_mutex_lock (&prompter->priv->queue_lock);

	if (g_source_get_id (g_main_current_source ()) == prompter->priv->schedule_idle_id) {
		prompter->priv->schedule_idle_id = 0;

		credentials_prompter_maybe_process_next_prompt (prompter);
	}

	g_rec_mutex_unlock (&prompter->priv->queue_lock);

	return FALSE;
}

static void
credentials_prompter_schedule_process_next_prompt (ECredentialsPrompter *prompter)
{
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));

	g_rec_mutex_lock (&prompter->priv->queue_lock);

	/* Already processing one */
	if (prompter->priv->processing_prompt ||
	    prompter->priv->schedule_idle_id) {
		g_rec_mutex_unlock (&prompter->priv->queue_lock);
		return;
	}

	prompter->priv->schedule_idle_id = g_idle_add_full (G_PRIORITY_HIGH_IDLE,
		credentials_prompter_process_next_prompt_idle_cb,
		prompter, NULL);

	g_rec_mutex_unlock (&prompter->priv->queue_lock);
}

static void
credentials_prompter_connection_status_changed_cb (ESource *source,
						   GParamSpec *param,
						   ECredentialsPrompter *prompter)
{
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));

	/* Do not cancel the prompt when the source is still waiting for the credentials. */
	if (e_source_get_connection_status (source) == E_SOURCE_CONNECTION_STATUS_AWAITING_CREDENTIALS)
		return;

	g_rec_mutex_lock (&prompter->priv->queue_lock);

	if (prompter->priv->processing_prompt &&
	    e_source_equal (prompter->priv->processing_prompt->auth_source, source)) {
		e_credentials_prompter_impl_cancel_prompt (prompter->priv->processing_prompt->prompter_impl, prompter->priv->processing_prompt);
	} else {
		GSList *link;

		for (link = prompter->priv->queue; link; link = g_slist_next (link)) {
			ProcessPromptData *ppd = link->data;

			g_warn_if_fail (ppd != NULL);

			if (ppd && e_source_equal (ppd->auth_source, source)) {
				if (ppd->connection_status != e_source_get_connection_status (source)) {
					prompter->priv->queue = g_slist_remove (prompter->priv->queue, ppd);
					process_prompt_data_free (ppd);
				}
				break;
			}
		}
	}

	g_rec_mutex_unlock (&prompter->priv->queue_lock);
}

static gboolean
e_credentials_prompter_eval_remember_password (ESource *source)
{
	gboolean remember_password = FALSE;

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION))
		remember_password = e_source_authentication_get_remember_password (
			e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION));

	return remember_password;
}

static void
e_credentials_prompter_manage_impl_prompt (ECredentialsPrompter *prompter,
					   ECredentialsPrompterImpl *prompter_impl,
					   ESource *auth_source,
					   ESource *cred_source,
					   const gchar *error_text,
					   const ENamedParameters *credentials,
					   gboolean allow_source_save,
					   GSimpleAsyncResult *async_result)
{
	GSList *link;
	gboolean success = TRUE;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL (prompter_impl));
	g_return_if_fail (E_IS_SOURCE (auth_source));
	g_return_if_fail (E_IS_SOURCE (cred_source));
	g_return_if_fail (credentials != NULL);

	g_rec_mutex_lock (&prompter->priv->queue_lock);

	for (link = prompter->priv->queue; link; link = g_slist_next (link)) {
		ProcessPromptData *ppd = link->data;

		g_warn_if_fail (ppd != NULL);

		if (ppd && e_source_equal (ppd->auth_source, auth_source)) {
			break;
		}
	}

	if (link != NULL || (prompter->priv->processing_prompt &&
	    e_source_equal (prompter->priv->processing_prompt->auth_source, auth_source))) {
		/* have queued or already asking for credentials for this source */
		success = FALSE;
	} else {
		ProcessPromptData *ppd;

		ppd = g_new0 (ProcessPromptData, 1);
		ppd->prompter = e_weak_ref_new (prompter);
		ppd->prompter_impl = g_object_ref (prompter_impl);
		ppd->auth_source = g_object_ref (auth_source);
		ppd->cred_source = g_object_ref (cred_source);
		ppd->connection_status = e_source_get_connection_status (ppd->auth_source);
		ppd->remember_password = e_credentials_prompter_eval_remember_password (ppd->cred_source);
		ppd->error_text = g_strdup (error_text);
		ppd->credentials = e_named_parameters_new_clone (credentials);
		ppd->allow_source_save = allow_source_save;
		ppd->async_result = async_result ? g_object_ref (async_result) : NULL;

		/* If the prompter doesn't auto-prompt, then it should not auto-close the prompt as well. */
		if (e_credentials_prompter_get_auto_prompt (prompter)) {
			ppd->notify_handler_id = g_signal_connect (ppd->auth_source, "notify::connection-status",
				G_CALLBACK (credentials_prompter_connection_status_changed_cb), prompter);
		} else {
			ppd->notify_handler_id = 0;
		}

		prompter->priv->queue = g_slist_append (prompter->priv->queue, ppd);

		credentials_prompter_schedule_process_next_prompt (prompter);
	}

	g_rec_mutex_unlock (&prompter->priv->queue_lock);

	if (!success && async_result) {
		e_credentials_prompter_complete_prompt_call (prompter, async_result, auth_source, NULL, NULL);
	}
}

static void
credentials_prompter_store_credentials_cb (GObject *source_object,
					   GAsyncResult *result,
					   gpointer user_data)
{
	GError *error = NULL;

	if (!e_source_credentials_provider_store_finish (E_SOURCE_CREDENTIALS_PROVIDER (source_object), result, &error) &&
	    !g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
		g_warning ("%s: Failed to store source credentials: %s", G_STRFUNC, error ? error->message : "Unknown error");
	}

	g_clear_error (&error);
}

static void
credentials_prompter_source_write_cb (GObject *source_object,
				      GAsyncResult *result,
				      gpointer user_data)
{
	ESource *source = E_SOURCE (source_object);
	GError *error = NULL;

	if (!e_source_write_finish (source, result, &error) &&
	    !g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
		g_warning ("%s: Failed to write source '%s' (%s) changes: %s", G_STRFUNC,
			e_source_get_uid (source),
			e_source_get_display_name (source),
			error ? error->message : "Unknown error");
	}

	g_clear_error (&error);
}

static void
credentials_prompter_update_username_for_children (ESourceRegistry *registry,
						   ESource *collection_source,
						   gboolean allow_source_save,
						   const gchar *old_username,
						   const gchar *new_username,
						   GCancellable *cancellable)
{
	GList *sources, *link;
	const gchar *parent_uid;
	gchar *collection_host;
	gboolean username_changed;

	g_return_if_fail (E_IS_SOURCE_REGISTRY (registry));
	g_return_if_fail (E_IS_SOURCE (collection_source));

	parent_uid = e_source_get_uid (collection_source);
	if (!parent_uid || !*parent_uid)
		return;

	collection_host = e_source_authentication_dup_host (e_source_get_extension (collection_source, E_SOURCE_EXTENSION_AUTHENTICATION));
	username_changed = g_strcmp0 (old_username, new_username) != 0;
	sources = e_source_registry_list_sources (registry, NULL);

	for (link = sources; link; link = g_list_next (link)) {
		ESource *child = link->data;

		if (g_strcmp0 (e_source_get_parent (child), parent_uid) == 0 &&
		    e_source_get_writable (child) && e_source_has_extension (child, E_SOURCE_EXTENSION_AUTHENTICATION)) {
			ESourceAuthentication *auth_extension;
			gchar *child_username, *child_host;

			auth_extension = e_source_get_extension (child, E_SOURCE_EXTENSION_AUTHENTICATION);
			child_username = e_source_authentication_dup_user (auth_extension);
			child_host = e_source_authentication_dup_host (auth_extension);

			if ((!child_host || !*child_host || !collection_host || !*collection_host ||
			    g_ascii_strcasecmp (child_host, collection_host) == 0) &&
			    (!child_username || !*child_username || !old_username || !*old_username ||
			    (username_changed && g_strcmp0 (child_username, old_username) == 0))) {
				e_source_authentication_set_user (auth_extension, new_username);

				if (allow_source_save) {
					e_source_write (child, cancellable,
						credentials_prompter_source_write_cb, NULL);
				}
			}

			g_free (child_username);
			g_free (child_host);
		}
	}

	g_list_free_full (sources, g_object_unref);
	g_free (collection_host);
}

static void
e_credentials_prompter_prompt_finish_for_source (ECredentialsPrompter *prompter,
						 ProcessPromptData *ppd,
						 const ENamedParameters *credentials)
{
	ESource *cred_source;
	gboolean changed = FALSE;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));
	g_return_if_fail (ppd != NULL);

	if (!credentials)
		return;

	cred_source = ppd->cred_source;

	if (e_source_has_extension (cred_source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
		ESourceAuthentication *auth_extension = e_source_get_extension (cred_source, E_SOURCE_EXTENSION_AUTHENTICATION);
		gboolean could_use_collection;

		could_use_collection = e_source_has_extension (cred_source, E_SOURCE_EXTENSION_COLLECTION);

		if (e_source_get_writable (cred_source)) {
			const gchar *username;

			username = e_named_parameters_get (credentials, E_SOURCE_CREDENTIAL_USERNAME);
			if (username && *username) {
				gchar *old_username;

				old_username = e_source_authentication_dup_user (auth_extension);

				/* Sync the changed user name to the child sources of the collection as well */
				if (ppd->auth_source == cred_source && e_source_has_extension (cred_source, E_SOURCE_EXTENSION_COLLECTION)) {
					credentials_prompter_update_username_for_children (
						e_credentials_prompter_get_registry (prompter),
						cred_source,
						ppd->allow_source_save,
						old_username,
						username,
						prompter->priv->cancellable);

					/* Update the collection source as the last, due to tests for the old
					   username in the credentials_prompter_update_username_for_children(). */
					if (g_strcmp0 (username, old_username) != 0) {
						e_source_authentication_set_user (auth_extension, username);
						changed = TRUE;
					}
				} else if (g_strcmp0 (username, old_username) != 0) {
					if (ppd->auth_source != cred_source &&
					    e_source_has_extension (cred_source, E_SOURCE_EXTENSION_COLLECTION)) {
						auth_extension = e_source_get_extension (ppd->auth_source, E_SOURCE_EXTENSION_AUTHENTICATION);
						e_source_authentication_set_user (auth_extension, username);

						if (ppd->allow_source_save && e_source_get_writable (ppd->auth_source)) {
							e_source_write (ppd->auth_source, prompter->priv->cancellable,
								credentials_prompter_source_write_cb, NULL);
						}
					} else {
						e_source_authentication_set_user (auth_extension, username);
						changed = TRUE;
					}
				}

				g_free (old_username);
			}
		}

		if (could_use_collection && !e_util_can_use_collection_as_credential_source (cred_source, ppd->auth_source)) {
			/* Copy also the remember-password flag */
			e_source_authentication_set_remember_password (e_source_get_extension (ppd->auth_source, E_SOURCE_EXTENSION_AUTHENTICATION),
				e_credentials_prompter_eval_remember_password (cred_source));

			cred_source = ppd->auth_source;
		}
	}

	if (e_source_has_extension (cred_source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
		ESourceAuthentication *auth_extension = e_source_get_extension (cred_source, E_SOURCE_EXTENSION_AUTHENTICATION);

		if (e_source_credentials_provider_can_store (e_credentials_prompter_get_provider (prompter), cred_source)) {
			e_source_credentials_provider_store (e_credentials_prompter_get_provider (prompter), cred_source, credentials,
				e_source_authentication_get_remember_password (auth_extension),
				prompter->priv->cancellable,
				credentials_prompter_store_credentials_cb, NULL);
		}
	}

	if (ppd->allow_source_save && e_source_get_writable (cred_source) &&
	    (changed || (ppd->remember_password ? 1 : 0) != (e_credentials_prompter_eval_remember_password (cred_source) ? 1 : 0))) {
		e_source_write (cred_source, prompter->priv->cancellable,
			credentials_prompter_source_write_cb, NULL);
	}

	if (ppd->async_result) {
		ECredentialsPrompter *ppd_prompter;

		ppd_prompter = g_weak_ref_get (ppd->prompter);
		if (ppd_prompter) {
			e_credentials_prompter_complete_prompt_call (ppd_prompter, ppd->async_result, ppd->auth_source, credentials, NULL);
			g_clear_object (&ppd_prompter);

			/* To not be completed multiple times */
			g_clear_object (&ppd->async_result);
		}
	} else {
		e_source_invoke_authenticate (ppd->auth_source, credentials, prompter->priv->cancellable,
			credentials_prompter_invoke_authenticate_cb, NULL);
	}
}

static void
credentials_prompter_prompt_finished_cb (ECredentialsPrompterImpl *prompter_impl,
					 gpointer prompt_id,
					 const ENamedParameters *credentials,
					 ECredentialsPrompter *prompter)
{
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL (prompter_impl));
	g_return_if_fail (prompt_id != NULL);
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));

	g_rec_mutex_lock (&prompter->priv->queue_lock);

	if (prompt_id == prompter->priv->processing_prompt) {
		ProcessPromptData *ppd = prompter->priv->processing_prompt;
		GSList *link, *to_remove = NULL;

		prompter->priv->processing_prompt = NULL;

		e_credentials_prompter_prompt_finish_for_source (prompter, ppd, credentials);

		/* Finish also any other pending prompts for the same credentials source
		   as was finished this one. This can be relevant to collection sources. */
		for (link = prompter->priv->queue; link; link = g_slist_next (link)) {
			ProcessPromptData *sub_ppd = link->data;

			if (sub_ppd && sub_ppd->cred_source && e_source_equal (sub_ppd->cred_source, ppd->cred_source)) {
				to_remove = g_slist_prepend (to_remove, sub_ppd);
			}
		}

		for (link = to_remove; link; link = g_slist_next (link)) {
			ProcessPromptData *sub_ppd = link->data;

			if (sub_ppd) {
				prompter->priv->queue = g_slist_remove (prompter->priv->queue, sub_ppd);
				e_credentials_prompter_prompt_finish_for_source (prompter, sub_ppd, credentials);
			}
		}

		g_slist_free_full (to_remove, process_prompt_data_free);
		process_prompt_data_free (ppd);

		credentials_prompter_schedule_process_next_prompt (prompter);
	} else {
		g_warning ("%s: Unknown prompt_id %p", G_STRFUNC, prompt_id);
	}

	g_rec_mutex_unlock (&prompter->priv->queue_lock);
}

static gboolean
credentials_prompter_prompt_with_source_details (ECredentialsPrompter *prompter,
						 LookupSourceDetailsData *data,
						 const gchar *error_text,
						 ECredentialsPrompterPromptFlags flags,
						 GSimpleAsyncResult *async_result)
{
	ECredentialsPrompterImpl *prompter_impl = NULL;
	gchar *method = NULL;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), FALSE);
	g_return_val_if_fail (data != NULL, FALSE);

	if (e_source_has_extension (data->cred_source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
		ESourceAuthentication *authentication = e_source_get_extension (data->cred_source, E_SOURCE_EXTENSION_AUTHENTICATION);

		method = e_source_authentication_dup_method (authentication);
	}

	g_mutex_lock (&prompter->priv->prompters_lock);

	prompter_impl = g_hash_table_lookup (prompter->priv->prompters, method ? method : "");
	if (!prompter_impl && method && *method)
		prompter_impl = g_hash_table_lookup (prompter->priv->prompters, "");

	if (prompter_impl)
		g_object_ref (prompter_impl);

	g_mutex_unlock (&prompter->priv->prompters_lock);

	if (prompter_impl) {
		ENamedParameters *credentials;

		credentials = e_named_parameters_new ();
		if (data->credentials)
			e_named_parameters_assign (credentials, data->credentials);

		if (async_result && data->credentials && (flags & E_CREDENTIALS_PROMPTER_PROMPT_FLAG_ALLOW_STORED_CREDENTIALS) != 0) {
			e_credentials_prompter_complete_prompt_call (prompter, async_result, data->auth_source, credentials, NULL);
		} else if (!e_source_credentials_provider_can_prompt (prompter->priv->provider, data->auth_source)) {
			/* This source cannot be asked for credentials, thus end with a 'not supported' error. */
			GError *error;

			error = g_error_new (G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
				_("Source “%s” doesn’t support prompt for credentials"),
				e_source_get_display_name (data->cred_source));

			if (async_result)
				e_credentials_prompter_complete_prompt_call (prompter, async_result, data->auth_source, NULL, error);

			g_clear_error (&error);
		} else {
			e_credentials_prompter_manage_impl_prompt (prompter, prompter_impl,
				data->auth_source, data->cred_source, error_text, credentials,
				!async_result || (flags & E_CREDENTIALS_PROMPTER_PROMPT_FLAG_ALLOW_SOURCE_SAVE) != 0,
				async_result);
		}

		e_named_parameters_free (credentials);
	} else {
		/* Shoud not happen, because the password prompter is added as the default prompter. */
		g_warning ("%s: No prompter impl found for an authentication method '%s'", G_STRFUNC, method ? method : "");
		success = FALSE;
	}

	g_clear_object (&prompter_impl);
	g_free (method);

	return success;
}

static void
credentials_prompter_lookup_source_details_before_prompt_cb (GObject *source_object,
							     GAsyncResult *result,
							     gpointer user_data)
{
	CredentialsPromptData *prompt_data = user_data;
	ECredentialsPrompter *prompter = NULL;
	LookupSourceDetailsData *data = NULL;
	GError *error = NULL;

	g_return_if_fail (prompt_data != NULL);
	g_return_if_fail (E_IS_SOURCE (source_object));

	if (!credentials_prompter_lookup_source_details_finish (E_SOURCE (source_object), result, &prompter, &data, &error)) {
		g_clear_error (&error);
		credentials_prompt_data_free (prompt_data);
		return;
	}

	if (credentials_prompter_prompt_with_source_details (prompter, data, prompt_data->error_text,
		prompt_data->flags, prompt_data->async_result)) {
		/* To not finish the async_result multiple times */
		g_clear_object (&prompt_data->async_result);
	}

	g_clear_object (&prompter);

	credentials_prompt_data_free (prompt_data);
	lookup_source_details_data_free (data);
}

static void
credentials_prompter_lookup_source_details_cb (GObject *source_object,
					       GAsyncResult *result,
					       gpointer user_data)
{
	LookupSourceDetailsData *data = NULL;
	ECredentialsPrompter *prompter = NULL;
	ESource *source;
	GError *error = NULL;

	g_return_if_fail (E_IS_SOURCE (source_object));

	source = E_SOURCE (source_object);

	if (!credentials_prompter_lookup_source_details_finish (source, result, &prompter, &data, &error)) {
		g_clear_error (&error);
		return;
	}

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));
	g_return_if_fail (data != NULL);

	if (data->credentials) {
		e_source_invoke_authenticate (E_SOURCE (data->auth_source), data->credentials, prompter->priv->cancellable, credentials_prompter_invoke_authenticate_cb, NULL);
	} else {
		credentials_prompter_prompt_with_source_details (prompter, data, NULL, 0, NULL);
	}

	lookup_source_details_data_free (data);
	g_clear_object (&prompter);
}

static void
credentials_prompter_credentials_required_cb (ESourceRegistry *registry,
					      ESource *source,
					      ESourceCredentialsReason reason,
					      const gchar *certificate_pem,
					      GTlsCertificateFlags certificate_errors,
					      const GError *op_error,
					      ECredentialsPrompter *prompter)
{
	ESource *cred_source;

	g_return_if_fail (E_IS_SOURCE_REGISTRY (registry));
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));

	/* Only these two reasons are meant to be used to prompt the user for credentials. */
	if (reason != E_SOURCE_CREDENTIALS_REASON_REQUIRED &&
	    reason != E_SOURCE_CREDENTIALS_REASON_REJECTED) {
		return;
	}

	cred_source = e_source_credentials_provider_ref_credentials_source (e_credentials_prompter_get_provider (prompter), source);

	/* Global auto-prompt or the source's auto-prompt is disabled. */
	if (!e_credentials_prompter_get_auto_prompt (prompter) ||
	    (e_credentials_prompter_get_auto_prompt_disabled_for (prompter, source) &&
	    (!cred_source || e_credentials_prompter_get_auto_prompt_disabled_for (prompter, cred_source)))) {
		g_clear_object (&cred_source);
		return;
	}

	g_clear_object (&cred_source);

	/* This is a re-prompt, but the source cannot be prompted for credentials. */
	if (reason == E_SOURCE_CREDENTIALS_REASON_REJECTED &&
	    !e_source_credentials_provider_can_prompt (prompter->priv->provider, source)) {
		return;
	}

	if (reason == E_SOURCE_CREDENTIALS_REASON_REQUIRED) {
		credentials_prompter_lookup_source_details (source, prompter,
			credentials_prompter_lookup_source_details_cb, NULL);
		return;
	}

	e_credentials_prompter_prompt (prompter, source, op_error ? op_error->message : NULL, 0, NULL, NULL);
}

static gboolean
credentials_prompter_get_dialog_parent_accumulator (GSignalInvocationHint *ihint,
						    GValue *return_accu,
						    const GValue *handler_return,
						    gpointer data)
{
	if (handler_return && g_value_get_object (handler_return) != NULL) {
		g_value_set_object (return_accu, g_value_get_object (handler_return));
		return FALSE;
	}

	return TRUE;
}

static void
credentials_prompter_set_registry (ECredentialsPrompter *prompter,
				   ESourceRegistry *registry)
{
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));
	g_return_if_fail (E_IS_SOURCE_REGISTRY (registry));
	g_return_if_fail (prompter->priv->registry == NULL);

	prompter->priv->registry = g_object_ref (registry);
	prompter->priv->provider = e_source_credentials_provider_new (prompter->priv->registry);

	g_signal_connect (prompter->priv->registry, "credentials-required",
		G_CALLBACK (credentials_prompter_credentials_required_cb), prompter);
}

static void
credentials_prompter_set_property (GObject *object,
				   guint property_id,
				   const GValue *value,
				   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_REGISTRY:
			credentials_prompter_set_registry (
				E_CREDENTIALS_PROMPTER (object),
				g_value_get_object (value));
			return;

		case PROP_AUTO_PROMPT:
			e_credentials_prompter_set_auto_prompt (
				E_CREDENTIALS_PROMPTER (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
credentials_prompter_get_property (GObject *object,
				   guint property_id,
				   GValue *value,
				   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_REGISTRY:
			g_value_set_object (value,
				e_credentials_prompter_get_registry (
				E_CREDENTIALS_PROMPTER (object)));
			return;

		case PROP_PROVIDER:
			g_value_set_object (value,
				e_credentials_prompter_get_provider (
				E_CREDENTIALS_PROMPTER (object)));
			return;

		case PROP_AUTO_PROMPT:
			g_value_set_boolean (value,
				e_credentials_prompter_get_auto_prompt (
				E_CREDENTIALS_PROMPTER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
credentials_prompter_constructed (GObject *object)
{
	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_credentials_prompter_parent_class)->constructed (object);

	e_extensible_load_extensions (E_EXTENSIBLE (object));
}

static void
credentials_prompter_dispose (GObject *object)
{
	ECredentialsPrompter *prompter = E_CREDENTIALS_PROMPTER (object);
	GHashTableIter iter;
	gpointer key, value;

	if (prompter->priv->cancellable) {
		g_cancellable_cancel (prompter->priv->cancellable);
		g_clear_object (&prompter->priv->cancellable);
	}

	if (prompter->priv->registry) {
		g_signal_handlers_disconnect_by_data (prompter->priv->registry, prompter);
		g_clear_object (&prompter->priv->registry);
	}

	g_rec_mutex_lock (&prompter->priv->queue_lock);

	if (prompter->priv->schedule_idle_id) {
		g_source_remove (prompter->priv->schedule_idle_id);
		prompter->priv->schedule_idle_id = 0;
	}

	g_rec_mutex_unlock (&prompter->priv->queue_lock);

	g_clear_object (&prompter->priv->provider);

	g_mutex_lock (&prompter->priv->prompters_lock);

	g_hash_table_iter_init (&iter, prompter->priv->prompters);
	while (g_hash_table_iter_next (&iter, &key, &value)) {
		ECredentialsPrompterImpl *prompter_impl = value;

		g_signal_handlers_disconnect_by_func (prompter_impl, credentials_prompter_prompt_finished_cb, prompter);
	}

	g_hash_table_remove_all (prompter->priv->prompters);
	g_hash_table_remove_all (prompter->priv->known_prompters);
	g_mutex_unlock (&prompter->priv->prompters_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_credentials_prompter_parent_class)->dispose (object);
}

static void
credentials_prompter_finalize (GObject *object)
{
	ECredentialsPrompter *prompter = E_CREDENTIALS_PROMPTER (object);

	g_hash_table_destroy (prompter->priv->prompters);
	g_hash_table_destroy (prompter->priv->known_prompters);
	g_mutex_clear (&prompter->priv->prompters_lock);

	g_hash_table_destroy (prompter->priv->disabled_auto_prompt);
	g_mutex_clear (&prompter->priv->disabled_auto_prompt_lock);

	g_rec_mutex_clear (&prompter->priv->queue_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_credentials_prompter_parent_class)->finalize (object);
}

static void
e_credentials_prompter_class_init (ECredentialsPrompterClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ECredentialsPrompterPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = credentials_prompter_set_property;
	object_class->get_property = credentials_prompter_get_property;
	object_class->constructed = credentials_prompter_constructed;
	object_class->dispose = credentials_prompter_dispose;
	object_class->finalize = credentials_prompter_finalize;

	/**
	 * ECredentialsPrompter:auto-prompt:
	 *
	 * Whether the #ECredentialsPrompter can response to credential
	 * requests automatically.
	 *
	 * Since: 3.16
	 **/
	g_object_class_install_property (
		object_class,
		PROP_AUTO_PROMPT,
		g_param_spec_boolean (
			"auto-prompt",
			"Auto Prompt",
			"Whether can response to credential requests automatically",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ECredentialsPrompter:registry:
	 *
	 * The #ESourceRegistry object, to whose credential requests the prompter listens.
	 *
	 * Since: 3.16
	 **/
	g_object_class_install_property (
		object_class,
		PROP_REGISTRY,
		g_param_spec_object (
			"registry",
			"Registry",
			"An ESourceRegistry",
			E_TYPE_SOURCE_REGISTRY,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ECredentialsPrompter:provider:
	 *
	 * The #ESourceCredentialsProvider object, which the prompter uses.
	 *
	 * Since: 3.16
	 **/
	g_object_class_install_property (
		object_class,
		PROP_PROVIDER,
		g_param_spec_object (
			"provider",
			"Provider",
			"An ESourceCredentialsProvider",
			E_TYPE_SOURCE_CREDENTIALS_PROVIDER,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ECredentialsPrompter::get-dialog-parent:
	 * @prompter: the #ECredentialsPrompter which emitted the signal
	 *
	 * Emitted when a new dialog will be shown, to get the right parent
	 * window for it. If the result of the call is %NULL, then it tries
	 * to get the window from the default GtkApplication.
	 *
	 * Returns: (transfer none): a #GtkWindow, to be used as a dialog parent,
	 * or %NULL.
	 *
	 * Since: 3.16
	 **/
	signals[GET_DIALOG_PARENT] = g_signal_new (
		"get-dialog-parent",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ECredentialsPrompterClass, get_dialog_parent),
		credentials_prompter_get_dialog_parent_accumulator, NULL, NULL,
		GTK_TYPE_WINDOW, 0, G_TYPE_NONE);

	/* Ensure built-in credential providers implementation types */
	g_type_ensure (E_TYPE_CREDENTIALS_PROMPTER_IMPL_PASSWORD);
	g_type_ensure (E_TYPE_CREDENTIALS_PROMPTER_IMPL_OAUTH2);
}

static void
e_credentials_prompter_init (ECredentialsPrompter *prompter)
{
	prompter->priv = G_TYPE_INSTANCE_GET_PRIVATE (prompter, E_TYPE_CREDENTIALS_PROMPTER, ECredentialsPrompterPrivate);

	prompter->priv->auto_prompt = TRUE;
	prompter->priv->provider = NULL;
	prompter->priv->cancellable = g_cancellable_new ();

	g_mutex_init (&prompter->priv->prompters_lock);
	prompter->priv->prompters = g_hash_table_new_full (camel_strcase_hash, camel_strcase_equal, g_free, g_object_unref);
	prompter->priv->known_prompters = g_hash_table_new (g_direct_hash, g_direct_equal);

	g_mutex_init (&prompter->priv->disabled_auto_prompt_lock);
	prompter->priv->disabled_auto_prompt = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);

	g_rec_mutex_init (&prompter->priv->queue_lock);
}

/**
 * e_credentials_prompter_new:
 * @registry: an #ESourceRegistry to have the prompter listen to
 *
 * Creates a new #ECredentialsPrompter, which listens for credential requests
 * from @registry.
 *
 * Returns: (transfer full): a new #ECredentialsPrompter
 *
 * Since: 3.16
 **/
ECredentialsPrompter *
e_credentials_prompter_new (ESourceRegistry *registry)
{
	return g_object_new (E_TYPE_CREDENTIALS_PROMPTER,
		"registry", registry,
		NULL);
}

/**
 * e_credentials_prompter_get_registry:
 * @prompter: an #ECredentialsPrompter
 *
 * Returns an #ESourceRegistry, to which the @prompter listens.
 *
 * Returns: (transfer none): an #ESourceRegistry, to which the @prompter listens.
 *
 * Since: 3.16
 **/
ESourceRegistry *
e_credentials_prompter_get_registry (ECredentialsPrompter *prompter)
{
	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), NULL);

	return prompter->priv->registry;
}

/**
 * e_credentials_prompter_get_provider:
 * @prompter: an #ECredentialsPrompter
 *
 * Returns an #ESourceCredentialsProvider, which the @prompter uses.
 *
 * Returns: (transfer none): an #ESourceCredentialsProvider, which the @prompter uses.
 *
 * Since: 3.16
 **/
ESourceCredentialsProvider *
e_credentials_prompter_get_provider (ECredentialsPrompter *prompter)
{
	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), NULL);
	g_return_val_if_fail (prompter->priv->provider != NULL, NULL);

	return prompter->priv->provider;
}

/**
 * e_credentials_prompter_get_auto_prompt:
 * @prompter: an #ECredentialsPrompter
 *
 * Returns, whether can respond to credential prompts automatically.
 * Default value is %TRUE.
 *
 * This property does not influence direct calls of e_credentials_prompter_prompt().
 *
 * Returns: Whether can respond to credential prompts automatically.
 *
 * Since: 3.16
 **/
gboolean
e_credentials_prompter_get_auto_prompt (ECredentialsPrompter *prompter)
{
	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), FALSE);

	return prompter->priv->auto_prompt;
}

/**
 * e_credentials_prompter_set_auto_prompt:
 * @prompter: an #ECredentialsPrompter
 * @auto_prompt: new value of the auto-prompt property
 *
 * Sets whether can respond to credential prompts automatically. That means that
 * whenever any ESource will ask for credentials, it'll try to provide them.
 *
 * Use e_credentials_prompter_set_auto_prompt_disabled_for() to influence
 * auto-prompt per an #ESource.
 *
 * This property does not influence direct calls of e_credentials_prompter_prompt().
 *
 * Since: 3.16
 **/
void
e_credentials_prompter_set_auto_prompt (ECredentialsPrompter *prompter,
					gboolean auto_prompt)
{
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));

	if ((prompter->priv->auto_prompt ? 1 : 0) == (auto_prompt ? 1 : 0))
		return;

	prompter->priv->auto_prompt = auto_prompt;

	g_object_notify (G_OBJECT (prompter), "auto-prompt");
}

/**
 * e_credentials_prompter_set_auto_prompt_disabled_for:
 * @prompter: an #ECredentialsPrompter
 * @source: an #ESource
 * @is_disabled: whether the auto-prompt should be disabled for this @source
 *
 * Sets whether the auto-prompt should be disabled for the given @source.
 * All sources can be auto-prompted by default. This is a complementary
 * value for the ECredentialsPrompter::auto-prompt property.
 *
 * This value does not influence direct calls of e_credentials_prompter_prompt().
 *
 * Since: 3.16
 **/
void
e_credentials_prompter_set_auto_prompt_disabled_for (ECredentialsPrompter *prompter,
						     ESource *source,
						     gboolean is_disabled)
{
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (e_source_get_uid (source) != NULL);

	g_mutex_lock (&prompter->priv->disabled_auto_prompt_lock);

	if (is_disabled)
		g_hash_table_insert (prompter->priv->disabled_auto_prompt, g_strdup (e_source_get_uid (source)), GINT_TO_POINTER (1));
	else
		g_hash_table_remove (prompter->priv->disabled_auto_prompt, e_source_get_uid (source));

	g_mutex_unlock (&prompter->priv->disabled_auto_prompt_lock);
}

/**
 * e_credentials_prompter_get_auto_prompt_disabled_for:
 * @prompter: an #ECredentialsPrompter
 * @source: an #ESource
 *
 * Returns whether the auto-prompt is disabled for the given @source.
 * All sources can be auto-prompted by default. This is a complementary
 * value for the ECredentialsPrompter::auto-prompt property.
 *
 * This value does not influence direct calls of e_credentials_prompter_prompt().
 *
 * Returns: Whether the auto-prompt is disabled for the given @source
 *
 * Since: 3.16
 **/
gboolean
e_credentials_prompter_get_auto_prompt_disabled_for (ECredentialsPrompter *prompter,
						     ESource *source)
{
	gboolean is_disabled;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), TRUE);
	g_return_val_if_fail (E_IS_SOURCE (source), TRUE);
	g_return_val_if_fail (e_source_get_uid (source) != NULL, TRUE);

	g_mutex_lock (&prompter->priv->disabled_auto_prompt_lock);

	is_disabled = g_hash_table_contains (prompter->priv->disabled_auto_prompt, e_source_get_uid (source));

	g_mutex_unlock (&prompter->priv->disabled_auto_prompt_lock);

	return is_disabled;
}

static GtkWindow *
credentials_prompter_guess_dialog_parent (ECredentialsPrompter *prompter)
{
	GApplication *app;

	app = g_application_get_default ();
	if (!app)
		return NULL;

	if (GTK_IS_APPLICATION (app))
		return gtk_application_get_active_window (GTK_APPLICATION (app));

	return NULL;
}

/**
 * e_credentials_prompter_get_dialog_parent:
 * @prompter: an #ECredentialsPrompter
 *
 * Returns a #GtkWindow, which should be used as a dialog parent. This is determined
 * by an ECredentialsPrompter::get-dialog-parent signal emission. If there is no callback
 * registered or the current callbacks don't have any suitable window, then there's
 * chosen the last active window from the default GApplication, if any available.
 *
 * Returns: (transfer none): a #GtkWindow, to be used as a dialog parent, or %NULL.
 *
 * Since: 3.16
 **/
GtkWindow *
e_credentials_prompter_get_dialog_parent (ECredentialsPrompter *prompter)
{
	GtkWindow *parent = NULL;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), NULL);

	g_signal_emit (prompter, signals[GET_DIALOG_PARENT], 0, &parent);

	if (!parent)
		parent = credentials_prompter_guess_dialog_parent (prompter);

	return parent;
}

/**
 * e_credentials_prompter_register_impl:
 * @prompter: an #ECredentialsPrompter
 * @authentication_method: (allow-none): an authentication method to registr @prompter_impl for; or %NULL
 * @prompter_impl: an #ECredentialsPrompterImpl
 *
 * Registers a prompter implementation for a given authentication method. If there is
 * registered a prompter for the same @authentication_method, then the function does
 * nothing, otherwise it adds its own reference on the @prompter_impl, and uses it
 * for that authentication method. One @prompter_impl can be registered for multiple
 * authentication methods.
 *
 * A special value %NULL can be used for the @authentication_method, which means
 * a default credentials prompter, that is to be used when there is no prompter
 * registered for the exact authentication method.
 *
 * Returns: %TRUE on success, %FALSE on failure or when there was another prompter
 * implementation registered for the given authentication method.
 *
 * Since: 3.16
 **/
gboolean
e_credentials_prompter_register_impl (ECredentialsPrompter *prompter,
				      const gchar *authentication_method,
				      ECredentialsPrompterImpl *prompter_impl)
{
	guint known_prompters;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), FALSE);
	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL (prompter_impl), FALSE);

	if (!authentication_method)
		authentication_method = "";

	g_mutex_lock (&prompter->priv->prompters_lock);

	if (g_hash_table_lookup (prompter->priv->prompters, authentication_method) != NULL) {
		g_mutex_unlock (&prompter->priv->prompters_lock);
		return FALSE;
	}

	g_hash_table_insert (prompter->priv->prompters, g_strdup (authentication_method), g_object_ref (prompter_impl));

	known_prompters = GPOINTER_TO_UINT (g_hash_table_lookup (prompter->priv->known_prompters, prompter_impl));
	if (!known_prompters) {
		g_signal_connect (prompter_impl, "prompt-finished", G_CALLBACK (credentials_prompter_prompt_finished_cb), prompter);
	}
	g_hash_table_insert (prompter->priv->known_prompters, prompter_impl, GUINT_TO_POINTER (known_prompters + 1));

	g_mutex_unlock (&prompter->priv->prompters_lock);

	return TRUE;
}

/**
 * e_credentials_prompter_unregister_impl:
 * @prompter: an #ECredentialsPrompter
 * @authentication_method: (allow-none): an authentication method to registr @prompter_impl for; or %NULL
 * @prompter_impl: an #ECredentialsPrompterImpl
 *
 * Unregisters previously registered @prompter_impl for the given @autnetication_method with
 * e_credentials_prompter_register_impl(). Function does nothing, if no such authentication
 * method is registered or if it has set a different prompter implementation.
 *
 * Since: 3.16
 **/
void
e_credentials_prompter_unregister_impl (ECredentialsPrompter *prompter,
					const gchar *authentication_method,
					ECredentialsPrompterImpl *prompter_impl)
{
	ECredentialsPrompterImpl *current_prompter_impl;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));

	if (!authentication_method)
		authentication_method = "";

	g_mutex_lock (&prompter->priv->prompters_lock);

	current_prompter_impl = g_hash_table_lookup (prompter->priv->prompters, authentication_method);
	if (current_prompter_impl == prompter_impl) {
		guint known_prompters;

		known_prompters = GPOINTER_TO_UINT (g_hash_table_lookup (prompter->priv->known_prompters, prompter_impl));
		if (known_prompters == 1) {
			g_signal_handlers_disconnect_by_func (prompter_impl, credentials_prompter_prompt_finished_cb, prompter);
			g_hash_table_remove (prompter->priv->known_prompters, prompter_impl);
		} else {
			known_prompters--;
			g_hash_table_insert (prompter->priv->known_prompters, prompter_impl, GUINT_TO_POINTER (known_prompters + 1));
		}

		g_hash_table_remove (prompter->priv->prompters, authentication_method);
	}

	g_mutex_unlock (&prompter->priv->prompters_lock);
}

static void
credentials_prompter_get_last_credentials_required_arguments_cb (GObject *source_object,
								 GAsyncResult *result,
								 gpointer user_data)
{
	ECredentialsPrompter *prompter = user_data;
	ESource *source;
	ESourceCredentialsReason reason = E_SOURCE_CREDENTIALS_REASON_UNKNOWN;
	gchar *certificate_pem = NULL;
	GTlsCertificateFlags certificate_errors = 0;
	GError *op_error = NULL;
	GError *error = NULL;

	g_return_if_fail (E_IS_SOURCE (source_object));

	source = E_SOURCE (source_object);

	if (!e_source_get_last_credentials_required_arguments_finish (source, result,
		&reason, &certificate_pem, &certificate_errors, &op_error, &error)) {
		if (!g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
			g_warning ("%s: Failed to get last credential values: %s", G_STRFUNC, error ? error->message : "Unknown error");
		}

		g_clear_error (&error);
		return;
	}

	/* Can check only now, when know the operation was not cancelled and the prompter freed. */
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));

	/* Check once again, as this was called asynchronously and anything could change meanwhile. */
	if (e_source_get_connection_status (source) == E_SOURCE_CONNECTION_STATUS_AWAITING_CREDENTIALS) {
		credentials_prompter_credentials_required_cb (prompter->priv->registry,
			source, reason, certificate_pem, certificate_errors, op_error, prompter);
	}

	g_free (certificate_pem);
	g_clear_error (&op_error);
}

/**
 * e_credentials_prompter_process_awaiting_credentials:
 * @prompter: an #ECredentialsPrompter
 *
 * Process all enabled sources with connection state #E_SOURCE_CONNECTION_STATUS_AWAITING_CREDENTIALS,
 * like if they just asked for its credentials for the first time.
 *
 * Since: 3.16
 **/
void
e_credentials_prompter_process_awaiting_credentials (ECredentialsPrompter *prompter)
{
	GList *sources, *link;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));

	sources = e_source_registry_list_enabled (prompter->priv->registry, NULL);
	for (link = sources; link; link = g_list_next (link)) {
		ESource *source = link->data;

		if (!source)
			continue;

		if (e_source_get_connection_status (source) == E_SOURCE_CONNECTION_STATUS_AWAITING_CREDENTIALS) {
			/* Check what failed the last time */
			e_credentials_prompter_process_source (prompter, source);
		}
	}

	g_list_free_full (sources, g_object_unref);
}

/**
 * e_credentials_prompter_process_source:
 * @prompter: an #ECredentialsPrompter
 * @source: an #ESource
 *
 * Continues a credential prompt for @source. Returns, whether anything wil be done.
 * The %FALSE either means that the @source<!-- -->'s connection status is not
 * the %E_SOURCE_CONNECTION_STATUS_AWAITING_CREDENTIALS.
 *
 * Returns: Whether continues with the credentials prompt.
 *
 * Since: 3.16
 **/
gboolean
e_credentials_prompter_process_source (ECredentialsPrompter *prompter,
				       ESource *source)
{
	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	if (e_source_get_connection_status (source) != E_SOURCE_CONNECTION_STATUS_AWAITING_CREDENTIALS)
		return FALSE;

	e_source_get_last_credentials_required_arguments (source, prompter->priv->cancellable,
		credentials_prompter_get_last_credentials_required_arguments_cb, prompter);

	return TRUE;
}

/**
 * e_credentials_prompter_prompt:
 * @prompter: an #ECredentialsPrompter
 * @source: an #ESource, which prompt the credentials for
 * @error_text: (allow-none): Additional error text to show to a user, or %NULL
 * @flags: a bit-or of #ECredentialsPrompterPromptFlags
 * @callback: (allow-none): a callback to call when the credentials are ready, or %NULL
 * @user_data: user data passed into @callback
 *
 * Asks the @prompter to prompt for credentials, which are returned
 * to the caller through @callback, when available.The @flags are ignored,
 * when the @callback is %NULL; the credentials are passed to the @source
 * with e_source_invoke_authenticate() directly, in this case.
 * Call e_credentials_prompter_prompt_finish() in @callback to get to
 * the provided credentials.
 *
 * Since: 3.16
 **/
void
e_credentials_prompter_prompt (ECredentialsPrompter *prompter,
			       ESource *source,
			       const gchar *error_text,
			       ECredentialsPrompterPromptFlags flags,
			       GAsyncReadyCallback callback,
			       gpointer user_data)
{
	CredentialsPromptData *prompt_data;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));
	g_return_if_fail (E_IS_SOURCE (source));

	prompt_data = g_new0 (CredentialsPromptData, 1);
	prompt_data->source = g_object_ref (source);
	prompt_data->error_text = g_strdup (error_text);
	prompt_data->flags = flags;
	prompt_data->async_result = callback ? g_simple_async_result_new (G_OBJECT (prompter),
		callback, user_data, e_credentials_prompter_prompt) : NULL;

	/* Just it can be shown in the UI as a prefilled value and the right source (collection) is used. */
	credentials_prompter_lookup_source_details (source, prompter,
		credentials_prompter_lookup_source_details_before_prompt_cb, prompt_data);
}

/**
 * e_credentials_prompter_prompt_finish:
 * @prompter: an #ECredentialsPrompter
 * @result: a #GAsyncResult
 * @out_source: (transfer full): (allow-none): optionally set to an #ESource, on which the prompt was started; can be %NULL
 * @out_credentials: (transfer full): set to an #ENamedParameters with provied credentials
 * @error: return location for a #GError, or %NULL
 *
 * Finishes a credentials prompt previously started with e_credentials_prompter_prompt().
 * The @out_source will have set a referenced #ESource, for which the prompt
 * was started. Unref it, when  no longer needed. Similarly the @out_credentials
 * will have set a newly allocated #ENamedParameters structure with provided credentials,
 * which should be freed with e_named_credentials_free() when no longer needed.
 * Both output arguments will be set to %NULL on error and %FALSE will be returned.
 *
 * Returns: %TRUE on success, %FALSE otherwise.
 *
 * Since: 3.16
 **/
gboolean
e_credentials_prompter_prompt_finish (ECredentialsPrompter *prompter,
				      GAsyncResult *result,
				      ESource **out_source,
				      ENamedParameters **out_credentials,
				      GError **error)
{
	CredentialsResultData *data;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), FALSE);
	g_return_val_if_fail (g_simple_async_result_get_source_tag (G_SIMPLE_ASYNC_RESULT (result))
		== e_credentials_prompter_prompt, FALSE);
	g_return_val_if_fail (out_credentials, FALSE);

	if (out_source)
		*out_source = NULL;
	*out_credentials = NULL;

	if (g_simple_async_result_propagate_error (G_SIMPLE_ASYNC_RESULT (result), error))
		return FALSE;

	data = g_simple_async_result_get_op_res_gpointer (G_SIMPLE_ASYNC_RESULT (result));
	g_return_val_if_fail (data != NULL, FALSE);

	if (data->credentials) {
		if (out_source)
			*out_source = g_object_ref (data->source);
		*out_credentials = e_named_parameters_new_clone (data->credentials);
	} else {
		g_set_error_literal (error, G_IO_ERROR, G_IO_ERROR_CANCELLED, _("Credentials prompt was cancelled"));

		return FALSE;
	}

	return TRUE;
}

/**
 * e_credentials_prompter_complete_prompt_call:
 * @prompter: an #ECredentialsPrompter
 * @async_result: a #GSimpleAsyncResult
 * @source: an #ESource, on which the prompt was started
 * @credentials: (allow-none): credentials, as provided by a user, on %NULL, when the prompt was cancelled
 * @error: (allow-none): a resulting #GError, or %NULL
 *
 * Completes an ongoing credentials prompt on idle, by finishing the @async_result.
 * This function is meant to be used by an #ECredentialsPrompterImpl implementation.
 * To actually finish the credentials prompt previously started with
 * e_credentials_prompter_prompt(), the e_credentials_prompter_prompt_finish() should
 * be called from the provided callback.
 *
 * Using %NULL @credentials will result in a G_IO_ERROR_CANCELLED error, if
 * no other @error is provided.
 *
 * Since: 3.16
 **/
void
e_credentials_prompter_complete_prompt_call (ECredentialsPrompter *prompter,
					     GSimpleAsyncResult *async_result,
					     ESource *source,
					     const ENamedParameters *credentials,
					     const GError *error)
{
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter));
	g_return_if_fail (G_IS_SIMPLE_ASYNC_RESULT (async_result));
	g_return_if_fail (g_simple_async_result_get_source_tag (async_result) == e_credentials_prompter_prompt);
	g_return_if_fail (source == NULL || E_IS_SOURCE (source));
	if (credentials)
		g_return_if_fail (E_IS_SOURCE (source));

	if (error) {
		g_simple_async_result_set_from_error (async_result, error);
	} else if (!credentials) {
		g_simple_async_result_set_error (async_result, G_IO_ERROR, G_IO_ERROR_CANCELLED, _("Credentials prompt was cancelled"));
	} else {
		CredentialsResultData *result;

		result = g_new0 (CredentialsResultData, 1);
		result->source = g_object_ref (source);
		result->credentials = e_named_parameters_new_clone (credentials);

		g_simple_async_result_set_op_res_gpointer (async_result, result, credentials_result_data_free);
	}

	g_simple_async_result_complete_in_idle (async_result);
}

static gboolean
credentials_prompter_prompt_sync (ECredentialsPrompter *prompter,
				  ESource *source,
				  gboolean is_retry,
				  ECredentialsPrompterPromptFlags *flags,
				  const gchar *error_text,
				  ENamedParameters **out_credentials,
				  GCancellable *cancellable,
				  GError **error)
{
	gboolean res = FALSE;
	ESourceCredentialsProvider *credentials_provider;
	ENamedParameters *credentials = NULL;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (flags != NULL, FALSE);
	g_return_val_if_fail (out_credentials != NULL, FALSE);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return FALSE;

	credentials_provider = e_credentials_prompter_get_provider (prompter);

	if (!is_retry) {
		ESource *cred_source;
		GError *local_error = NULL;

		cred_source = e_source_credentials_provider_ref_credentials_source (credentials_provider, source);

		if (e_source_credentials_provider_lookup_sync (credentials_provider, cred_source ? cred_source : source,
			cancellable, &credentials, &local_error)) {
			res = TRUE;
		} else if (!g_cancellable_is_cancelled (cancellable)) {
			/* To prompt for the password directly */
			is_retry = TRUE;
			g_clear_error (&local_error);
		} else {
			g_propagate_error (error, local_error);
		}

		g_clear_object (&cred_source);
	}

	if (is_retry) {
		EAsyncClosure *closure;
		GAsyncResult *result;

		*flags = (*flags) & (~E_CREDENTIALS_PROMPTER_PROMPT_FLAG_ALLOW_STORED_CREDENTIALS);

		closure = e_async_closure_new ();

		e_credentials_prompter_prompt (prompter, source, error_text, *flags,
			e_async_closure_callback, closure);

		result = e_async_closure_wait (closure);

		if (e_credentials_prompter_prompt_finish (prompter, result, NULL, &credentials, error)) {
			res = TRUE;
		}

		e_async_closure_free (closure);
	}

	if (res && credentials)
		*out_credentials = e_named_parameters_new_clone (credentials);

	e_named_parameters_free (credentials);

	return res;
}

/**
 * e_credentials_prompter_loop_prompt_sync:
 * @prompter: an #ECredentialsPrompter
 * @source: an #ESource to be prompted credentials for
 * @flags: a bit-or of #ECredentialsPrompterPromptFlags initial flags
 * @func: (scope call): an #ECredentialsPrompterLoopPromptFunc user function to call to check provided credentials
 * @user_data: user data to pass to @func
 * @cancellable: (allow-none): an optional #GCancellable, or %NULL
 * @error: (allow-none): a #GError, to store any errors to, or %NULL
 *
 * Runs a credentials prompt loop for @source, as long as the @func doesn't
 * indicate that the provided credentials can be used to successfully
 * authenticate against @source<!-- -->'s server, or that the @func
 * returns %FALSE. The loop is also teminated when a used cancels
 * the credentials prompt or the @cancellable is cancelled, though
 * not sooner than the credentials prompt dialog is closed.
 *
 * Note: The function doesn't return until the loop is terminated, either
 *    successfully or unsuccessfully. The function can be called from any
 *    thread, though a dedicated thread is preferred.
 *
 * Returns: %TRUE, when the credentials were provided sucessfully and they
 *   can be used to authenticate the @source; %FALSE otherwise.
 *
 * Since: 3.16
 **/
gboolean
e_credentials_prompter_loop_prompt_sync (ECredentialsPrompter *prompter,
					 ESource *source,
					 ECredentialsPrompterPromptFlags flags,
					 ECredentialsPrompterLoopPromptFunc func,
					 gpointer user_data,
					 GCancellable *cancellable,
					 GError **error)
{
	gboolean is_retry, authenticated;
	ENamedParameters *credentials = NULL;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (prompter), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (func != NULL, FALSE);

	is_retry = FALSE;
	authenticated = FALSE;

	while (!authenticated && !g_cancellable_is_cancelled (cancellable)) {
		GError *local_error = NULL;

		e_named_parameters_free (credentials);
		credentials = NULL;

		if (!credentials_prompter_prompt_sync (prompter, source, is_retry, &flags, NULL,
			&credentials, cancellable, error))
			break;

		if (g_cancellable_set_error_if_cancelled (cancellable, error))
			break;

		g_clear_error (&local_error);

		if (!func (prompter, source, credentials, &authenticated, user_data, cancellable, &local_error)) {
			if (local_error)
				g_propagate_error (error, local_error);
			break;
		}

		is_retry = TRUE;
	}

	e_named_parameters_free (credentials);

	return authenticated;
}
