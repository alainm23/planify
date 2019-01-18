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

#include "e-credentials-prompter.h"
#include "e-credentials-prompter-impl.h"

struct _ECredentialsPrompterImplPrivate {
	GCancellable *cancellable;
};

enum {
	PROMPT_FINISHED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_ABSTRACT_TYPE (ECredentialsPrompterImpl, e_credentials_prompter_impl, E_TYPE_EXTENSION)

static void
e_credentials_prompter_impl_constructed (GObject *object)
{
	ECredentialsPrompterImpl *prompter_impl = E_CREDENTIALS_PROMPTER_IMPL (object);
	ECredentialsPrompterImplClass *klass;
	ECredentialsPrompter *prompter;
	gint ii;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_credentials_prompter_impl_parent_class)->constructed (object);

	prompter = E_CREDENTIALS_PROMPTER (e_extension_get_extensible (E_EXTENSION (prompter_impl)));

	klass = E_CREDENTIALS_PROMPTER_IMPL_GET_CLASS (object);
	g_return_if_fail (klass != NULL);
	g_return_if_fail (klass->authentication_methods != NULL);

	for (ii = 0; klass->authentication_methods[ii]; ii++) {
		e_credentials_prompter_register_impl (prompter, klass->authentication_methods[ii], prompter_impl);
	}
}

static void
e_credentials_prompter_impl_dispose (GObject *object)
{
	ECredentialsPrompterImpl *prompter_impl = E_CREDENTIALS_PROMPTER_IMPL (object);

	if (prompter_impl->priv->cancellable) {
		g_cancellable_cancel (prompter_impl->priv->cancellable);
		g_clear_object (&prompter_impl->priv->cancellable);
	}

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_credentials_prompter_impl_parent_class)->dispose (object);
}

static void
e_credentials_prompter_impl_class_init (ECredentialsPrompterImplClass *klass)
{
	GObjectClass *object_class;
	EExtensionClass *extension_class;

	g_type_class_add_private (klass, sizeof (ECredentialsPrompterImplPrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->dispose = e_credentials_prompter_impl_dispose;
	object_class->constructed = e_credentials_prompter_impl_constructed;

	extension_class = E_EXTENSION_CLASS (klass);
	extension_class->extensible_type = E_TYPE_CREDENTIALS_PROMPTER;

	/**
	 * ECredentialsPrompterImpl::prompt-finished:
	 * @prompter_impl: an #ECredentialsPrompterImpl which emitted the signal
	 * @prompt_id: an ID of the prompt which was finished
	 * @credentials: (allow-none): entered credentials, or %NULL for cancelled prompts
	 *
	 * Emitted when a prompt of ID @prompt_id is finished.
	 *
	 * Since: 3.16
	 **/
	signals[PROMPT_FINISHED] = g_signal_new (
		"prompt-finished",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ECredentialsPrompterImplClass, prompt_finished),
		NULL, NULL, NULL,
		G_TYPE_NONE, 2, G_TYPE_POINTER, E_TYPE_NAMED_PARAMETERS);
}

static void
e_credentials_prompter_impl_init (ECredentialsPrompterImpl *prompter_impl)
{
	prompter_impl->priv = G_TYPE_INSTANCE_GET_PRIVATE (prompter_impl,
		E_TYPE_CREDENTIALS_PROMPTER_IMPL, ECredentialsPrompterImplPrivate);

	prompter_impl->priv->cancellable = g_cancellable_new ();
}

/**
 * e_credentials_prompter_impl_get_credentials_prompter:
 * @prompter_impl: an #ECredentialsPrompterImpl
 *
 * Returns an #ECredentialsPrompter with which the @prompter_impl is associated.
 *
 * Returns: (transfer none): an #ECredentialsPrompter
 *
 * Since: 3.16
 **/
ECredentialsPrompter *
e_credentials_prompter_impl_get_credentials_prompter (ECredentialsPrompterImpl *prompter_impl)
{
	EExtensible *extensible;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL (prompter_impl), NULL);

	extensible = e_extension_get_extensible (E_EXTENSION (prompter_impl));
	if (!extensible)
		return NULL;

	return E_CREDENTIALS_PROMPTER (extensible);
}

/**
 * e_credentials_prompter_impl_prompt:
 * @prompter_impl: an #ECredentialsPrompterImpl
 * @prompt_id: a prompt ID to be passed to e_credentials_prompter_impl_prompt_finish()
 * @auth_source: an #ESource, to prompt the credentials for (the source which asked for credentials)
 * @cred_source: a parent #ESource, from which credentials were taken, or should be stored to
 * @error_text: (allow-none): an optional error text from the previous credentials prompt; can be %NULL
 * @credentials: credentials, as saved in keyring; can be empty, but not %NULL
 *
 * Runs a credentials prompt for the @prompter_impl. The actual prompter implementation
 * receives the prompt through ECredentialsPrompterImplClass::process_prompt(), where the given
 * @prompt_id is used for an identification. The prompt is left 'active' as long as it is
 * not finished with a call of e_credentials_prompter_impl_prompt_finish(). This should be
 * called even for cancelled prompts. The prompt can be cancelled before it's processed,
 * using the e_credentials_prompter_impl_cancel_prompt().
 *
 * The @auth_source can be the same as @cred_source, in case the credentials
 * are stored only for that particular source. If the sources share credentials,
 * which can be a case when the @auth_source is part of a collection, then
 * the @cred_stource can be that collection source.
 *
 * Since: 3.16
 **/
void
e_credentials_prompter_impl_prompt (ECredentialsPrompterImpl *prompter_impl,
				    gpointer prompt_id,
				    ESource *auth_source,
				    ESource *cred_source,
				    const gchar *error_text,
				    const ENamedParameters *credentials)
{
	ECredentialsPrompterImplClass *klass;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL (prompter_impl));
	g_return_if_fail (E_IS_SOURCE (auth_source));
	g_return_if_fail (E_IS_SOURCE (cred_source));
	g_return_if_fail (credentials != NULL);

	klass = E_CREDENTIALS_PROMPTER_IMPL_GET_CLASS (prompter_impl);
	g_return_if_fail (klass != NULL);
	g_return_if_fail (klass->process_prompt != NULL);

	klass->process_prompt (prompter_impl, prompt_id, auth_source, cred_source, error_text, credentials);
}

/**
 * e_credentials_prompter_impl_prompt_finish:
 * @prompter_impl: an #ECredentialsPrompterImpl
 * @prompt_id: a prompt ID
 * @credentials: (allow-none): credentials to use; can be %NULL for cancelled prompts
 *
 * The actual credentials prompt implementation finishes a previously started
 * credentials prompt @prompt_id with ECredentialsPrompterImplClass::process_prompt()
 * by a call to this function. This function should be called regardless the prompt
 * was or was not cancelled with e_credentials_prompter_impl_cancel_prompt().
 * Once the prompt is finished another queued is started, if any pending exists.
 * Use %NULL @credentials for cancelled prompts, otherwise the credentials are used
 * for authentication of the associated #ESource.
 *
 * Since: 3.16
 **/
void
e_credentials_prompter_impl_prompt_finish (ECredentialsPrompterImpl *prompter_impl,
					   gpointer prompt_id,
					   const ENamedParameters *credentials)
{
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL (prompter_impl));
	g_return_if_fail (prompt_id != NULL);

	g_signal_emit (prompter_impl, signals[PROMPT_FINISHED], 0, prompt_id, credentials);
}

/**
 * e_credentials_prompter_impl_cancel_prompt:
 * @prompter_impl: an #ECredentialsPrompterImpl
 * @prompt_id: a prompt ID to cancel
 *
 * Asks the @prompt_impl to cancel current prompt, which should have ID @prompt_id.
 *
 * Since: 3.16
 **/
void
e_credentials_prompter_impl_cancel_prompt (ECredentialsPrompterImpl *prompter_impl,
					   gpointer prompt_id)
{
	ECredentialsPrompterImplClass *klass;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL (prompter_impl));

	klass = E_CREDENTIALS_PROMPTER_IMPL_GET_CLASS (prompter_impl);
	g_return_if_fail (klass != NULL);
	g_return_if_fail (klass->cancel_prompt != NULL);

	klass->cancel_prompt (prompter_impl, prompt_id);
}
