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

#include "e-data-server-util.h"
#include "e-source.h"
#include "e-source-authentication.h"
#include "e-source-collection.h"
#include "e-source-registry.h"
#include "e-source-credentials-provider-impl.h"
#include "e-module.h"

#include "libedataserver-private.h"

#include "e-source-credentials-provider.h"

/* built-in source credentials provider implementations */
#include "e-source-credentials-provider-impl-password.h"
#include "e-source-credentials-provider-impl-oauth2.h"

struct _ESourceCredentialsProviderPrivate {
	GWeakRef registry; /* The property can hold both client and server-side registry */
	GMutex providers_lock;
	GSList *providers; /* ESourceCredentialsProviderImpl *impl */
	ESourceCredentialsProviderImpl *impl_password;
};

enum {
	PROP_0,
	PROP_REGISTRY
};

G_DEFINE_TYPE_WITH_CODE (ESourceCredentialsProvider, e_source_credentials_provider, G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (E_TYPE_EXTENSIBLE, NULL))

static ESource *
source_credentials_provider_ref_source (ESourceCredentialsProvider *provider,
					const gchar *uid)
{
	GObject *registry;
	ESource *source = NULL;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), NULL);
	g_return_val_if_fail (uid, NULL);

	registry = e_source_credentials_provider_ref_registry (provider);
	if (registry) {
		g_return_val_if_fail (E_IS_SOURCE_REGISTRY (registry), NULL);

		source = e_source_registry_ref_source (E_SOURCE_REGISTRY (registry), uid);
	}

	g_clear_object (&registry);

	return source;
}

static void
source_credentials_provider_set_registry (ESourceCredentialsProvider *provider,
					  GObject *registry)
{
	g_return_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider));
	g_return_if_fail (G_IS_OBJECT (registry));
	g_return_if_fail (g_weak_ref_get (&provider->priv->registry) == NULL);

	g_weak_ref_set (&provider->priv->registry, registry);
}

static void
source_credentials_provider_set_property (GObject *object,
					  guint property_id,
					  const GValue *value,
					  GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_REGISTRY:
			source_credentials_provider_set_registry (
				E_SOURCE_CREDENTIALS_PROVIDER (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_credentials_provider_get_property (GObject *object,
					  guint property_id,
					  GValue *value,
					  GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_REGISTRY:
			g_value_take_object (value,
				e_source_credentials_provider_ref_registry (
				E_SOURCE_CREDENTIALS_PROVIDER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_credentials_provider_constructed (GObject *object)
{
	static gboolean modules_loaded = FALSE;
	ESourceCredentialsProvider *provider = E_SOURCE_CREDENTIALS_PROVIDER (object);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_source_credentials_provider_parent_class)->constructed (object);

	/* Load modules only once. */
	if (!modules_loaded) {
		GList *module_types;

		modules_loaded = TRUE;

		module_types = e_module_load_all_in_directory (E_DATA_SERVER_CREDENTIALMODULEDIR);
		g_list_free_full (module_types, (GDestroyNotify) g_type_module_unuse);
	}

	e_extensible_load_extensions (E_EXTENSIBLE (object));

	g_mutex_lock (&provider->priv->providers_lock);

	/* Safety check. */
	g_warn_if_fail (provider->priv->impl_password != NULL);

	g_mutex_unlock (&provider->priv->providers_lock);
}

static void
source_credentials_provider_finalize (GObject *object)
{
	ESourceCredentialsProvider *provider = E_SOURCE_CREDENTIALS_PROVIDER (object);

	g_mutex_lock (&provider->priv->providers_lock);
	g_slist_free_full (provider->priv->providers, g_object_unref);
	provider->priv->providers = NULL;
	g_clear_object (&provider->priv->impl_password);
	g_mutex_unlock (&provider->priv->providers_lock);

	g_mutex_clear (&provider->priv->providers_lock);
	g_weak_ref_clear (&provider->priv->registry);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_source_credentials_provider_parent_class)->finalize (object);
}

static void
e_source_credentials_provider_class_init (ESourceCredentialsProviderClass *class)
{
	GObjectClass *object_class;
	ESourceCredentialsProviderClass *provider_class;

	g_type_class_add_private (class, sizeof (ESourceCredentialsProviderPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_credentials_provider_set_property;
	object_class->get_property = source_credentials_provider_get_property;
	object_class->constructed = source_credentials_provider_constructed;
	object_class->finalize = source_credentials_provider_finalize;

	provider_class = E_SOURCE_CREDENTIALS_PROVIDER_CLASS (class);
	provider_class->ref_source = source_credentials_provider_ref_source;

	/**
	 * ESourceCredentialsProvider:registry:
	 *
	 * The Source Registry object, which can be either #ESourceregistry or #ESourceRegistryServer.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_REGISTRY,
		g_param_spec_object (
			"registry",
			"Registry",
			"An ESourceRegistry",
			G_TYPE_OBJECT,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/* Ensure built-in credential providers implementation types */
	g_type_ensure (E_TYPE_SOURCE_CREDENTIALS_PROVIDER_IMPL_PASSWORD);
	g_type_ensure (E_TYPE_SOURCE_CREDENTIALS_PROVIDER_IMPL_OAUTH2);
}

static void
e_source_credentials_provider_init (ESourceCredentialsProvider *provider)
{
	provider->priv = G_TYPE_INSTANCE_GET_PRIVATE (provider, E_TYPE_SOURCE_CREDENTIALS_PROVIDER, ESourceCredentialsProviderPrivate);

	g_weak_ref_init (&provider->priv->registry, NULL);
	provider->priv->providers = NULL;
	g_mutex_init (&provider->priv->providers_lock);
}

static ESourceCredentialsProviderImpl *
source_credential_provider_ref_impl_for_source (ESourceCredentialsProvider *provider,
						ESource *source,
						ESource **out_cred_source)
{
	ESourceCredentialsProviderImpl *impl = NULL;
	ESource *cred_source;
	GSList *link;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), NULL);
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	if (out_cred_source)
		*out_cred_source = NULL;

	cred_source = e_source_credentials_provider_ref_credentials_source (provider, source);
	if (!cred_source || cred_source == source) {
		g_clear_object (&cred_source);
	} else {
		source = cred_source;
		if (out_cred_source)
			*out_cred_source = g_object_ref (cred_source);
	}

	g_mutex_lock (&provider->priv->providers_lock);

	for (link = provider->priv->providers; link; link = link->next) {
		ESourceCredentialsProviderImpl *adept = link->data;

		if (adept && e_source_credentials_provider_impl_can_process (adept, source)) {
			impl = g_object_ref (adept);
			break;
		}
	}

	if (!impl && provider->priv->impl_password)
		impl = g_object_ref (provider->priv->impl_password);

	g_mutex_unlock (&provider->priv->providers_lock);

	g_clear_object (&cred_source);

	if (!impl && out_cred_source)
		g_clear_object (out_cred_source);

	return impl;
}

/**
 * e_source_credentials_provider_new:
 * @registry: an #ESourceRegistry
 *
 * Creates a new #ESourceCredentialsProvider, which is meant to abstract
 * credential management for #ESource<!-- -->-s.
 *
 * Returns: (transfer full): a new #ESourceCredentialsProvider
 *
 * Since: 3.16
 **/
ESourceCredentialsProvider *
e_source_credentials_provider_new (ESourceRegistry *registry)
{
	g_return_val_if_fail (E_IS_SOURCE_REGISTRY (registry), NULL);

	return g_object_new (E_TYPE_SOURCE_CREDENTIALS_PROVIDER,
		"registry", registry,
		NULL);
}

/**
 * e_source_credentials_provider_ref_registry:
 * @provider: an #ESourceCredentialsProvider
 *
 * Returns refenrenced registry associated with this @provider.
 *
 * Returns: (transfer full): Reference registry associated with this @provider. Unref it
 *    with g_object_unref() when no longer needed.
 *
 * Since: 3.16
 **/
GObject *
e_source_credentials_provider_ref_registry (ESourceCredentialsProvider *provider)
{
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), NULL);

	return g_weak_ref_get (&provider->priv->registry);
}

/**
 * e_source_credentials_provider_register_impl:
 * @provider: an #ESourceCredentialsProvider
 * @provider_impl: an #ESourceCredentialsProviderImpl
 *
 * Registers a credentials provider implementation and adds its own reference on
 * the @provider_impl.
 *
 * Returns: %TRUE on success, %FALSE on failure, like when there is
 *    the @provider_impl already registered.
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_register_impl (ESourceCredentialsProvider *provider,
					     ESourceCredentialsProviderImpl *provider_impl)
{
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), FALSE);
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL (provider_impl), FALSE);

	g_mutex_lock (&provider->priv->providers_lock);
	if (g_slist_find (provider->priv->providers, provider_impl)) {
		g_mutex_unlock (&provider->priv->providers_lock);
		return FALSE;
	}

	/* Deal with the built-in password provider differently, it's a fallback provider_impl */
	if (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL_PASSWORD (provider_impl)) {
		if (provider_impl == provider->priv->impl_password) {
			g_mutex_unlock (&provider->priv->providers_lock);
			return FALSE;
		}

		g_clear_object (&provider->priv->impl_password);
		provider->priv->impl_password = g_object_ref (provider_impl);
	} else {
		provider->priv->providers = g_slist_prepend (provider->priv->providers, g_object_ref (provider_impl));
	}

	g_mutex_unlock (&provider->priv->providers_lock);

	return TRUE;
}

/**
 * e_source_credentials_provider_unregister_impl:
 * @provider: an #ESourceCredentialsProvider
 * @provider_impl: an #ESourceCredentialsProviderImpl
 *
 * Unregisters previously registered @provider_impl with
 * e_source_credentials_provider_register_impl(). Function does nothing,
 * when the @provider_impl is not registered.
 *
 * Since: 3.16
 **/
void
e_source_credentials_provider_unregister_impl (ESourceCredentialsProvider *provider,
					       ESourceCredentialsProviderImpl *provider_impl)
{
	g_return_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider));

	g_mutex_lock (&provider->priv->providers_lock);

	provider->priv->providers = g_slist_remove (provider->priv->providers, provider_impl);

	g_mutex_unlock (&provider->priv->providers_lock);
}

/**
 * e_source_credentials_provider_ref_source:
 * @provider: an #ESourceCredentialsProvider
 * @uid: an #ESource UID
 *
 * Returns referenced #ESource with the given @uid, or %NULL, when it could not be found.
 *
 * Returns: (transfer full): Referenced #ESource with the given @uid, or %NULL, when it
 *    could not be found. Unref the returned #ESource with g_object_unref(), when no longer needed.
 *
 * Since: 3.16
 **/
ESource *
e_source_credentials_provider_ref_source (ESourceCredentialsProvider *provider,
					  const gchar *uid)
{
	ESourceCredentialsProviderClass *klass;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	klass = E_SOURCE_CREDENTIALS_PROVIDER_GET_CLASS (provider);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->ref_source != NULL, NULL);

	return klass->ref_source (provider, uid);
}

/**
 * e_source_credentials_provider_ref_credentials_source:
 * @provider: an #ESourceCredentialsProvider
 * @source: an #ESource
 *
 * Returns a referenced parent #ESource, which holds the credentials for
 * the given @source. This is useful for collections, where the credentials
 * are usually stored on the collection source, thus shared between child
 * sources. When ther eis no such parent source, a %NULL is returned, which
 * means the @source holds credentials for itself.
 *
 * Returns: (transfer full): referenced parent #ESource, which holds credentials, or %NULL. Unref
 *    the returned non-NULL #ESource with g_object_unref(), when no longer needed.
 *
 * Since: 3.16
 **/
ESource *
e_source_credentials_provider_ref_credentials_source (ESourceCredentialsProvider *provider,
						      ESource *source)
{
	ESource *collection, *cred_source = NULL;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), NULL);
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	collection = g_object_ref (source);

	while (collection &&
	       !e_source_has_extension (collection, E_SOURCE_EXTENSION_COLLECTION)) {
		ESource *parent;

		if (!e_source_get_parent (collection)) {
			break;
		}

		parent = e_source_credentials_provider_ref_source (provider, e_source_get_parent (collection));

		g_clear_object (&collection);
		collection = parent;
	}

	if (e_util_can_use_collection_as_credential_source (collection, source))
		cred_source = g_object_ref (collection);

	g_clear_object (&collection);

	return cred_source;
}

/**
 * e_source_credentials_provider_can_store:
 * @provider: an #ESourceCredentialsProvider
 * @source: an #ESource
 *
 * Returns whether the @source can store its credentials. When %FALSE is returned,
 * an attempt to call e_source_credentials_provider_store() or
 * e_source_credentials_provider_store_sync() will fail for this @source.
 *
 * Returns: %TRUE, when the credentials storing for @source is possible, %FALSE otherwise.
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_can_store (ESourceCredentialsProvider *provider,
					 ESource *source)
{
	ESourceCredentialsProviderImpl *provider_impl;
	gboolean res;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	provider_impl = source_credential_provider_ref_impl_for_source (provider, source, NULL);

	g_return_val_if_fail (provider_impl != NULL, FALSE);
	res = e_source_credentials_provider_impl_can_store (provider_impl);

	g_clear_object (&provider_impl);

	return res;
}

/**
 * e_source_credentials_provider_can_prompt:
 * @provider: an #ESourceCredentialsProvider
 * @source: an #ESource
 *
 * Returns whether a credentials prompt can be shown for the @source.
 *
 * Returns: %TRUE, when a credentials prompt can be shown for @source, %FALSE otherwise.
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_can_prompt (ESourceCredentialsProvider *provider,
					  ESource *source)
{
	ESourceCredentialsProviderImpl *provider_impl;
	gboolean res;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	provider_impl = source_credential_provider_ref_impl_for_source (provider, source, NULL);
	g_return_val_if_fail (provider_impl != NULL, FALSE);

	res = e_source_credentials_provider_impl_can_prompt (provider_impl);

	g_clear_object (&provider_impl);

	return res;
}

typedef struct _AsyncContext {
	ESource *source;
	ENamedParameters *credentials;
	gboolean permanently;
} AsyncContext;

static AsyncContext *
async_context_new (ESource *source,
		   const ENamedParameters *credentials,
		   gboolean permanently)
{
	AsyncContext *async_context;

	async_context = g_new0 (AsyncContext, 1);
	async_context->source = g_object_ref (source);
	async_context->permanently = permanently;
	if (credentials)
		async_context->credentials = e_named_parameters_new_clone (credentials);

	return async_context;
}

static void
async_context_free (gpointer ptr)
{
	AsyncContext *async_context = ptr;

	if (async_context) {
		g_clear_object (&async_context->source);
		e_named_parameters_free (async_context->credentials);
		g_free (async_context);
	}
}

/**
 * e_source_credentials_provider_lookup_sync:
 * @provider: an #ESourceCredentialsProvider
 * @source: an #ESource, to lookup credentials for
 * @cancellable: optional #GCancellable object, or %NULL
 * @out_credentials: (out): return location for the credentials
 * @error: return location for a #GError, or %NULL
 *
 * Looks up the credentials for @source.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_lookup_sync (ESourceCredentialsProvider *provider,
					   ESource *source,
					   GCancellable *cancellable,
					   ENamedParameters **out_credentials,
					   GError **error)
{
	ESourceCredentialsProviderImpl *provider_impl;
	ESource *cred_source = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (out_credentials != NULL, FALSE);

	provider_impl = source_credential_provider_ref_impl_for_source (provider, source, &cred_source);
	g_return_val_if_fail (provider_impl != NULL, FALSE);

	success = e_source_credentials_provider_impl_lookup_sync (provider_impl, cred_source ? cred_source : source, cancellable, out_credentials, error);

	g_clear_object (&provider_impl);
	g_clear_object (&cred_source);

	return success;
}

static void
source_credentials_provider_lookup_thread (GTask *task,
					   gpointer source_object,
					   gpointer task_data,
					   GCancellable *cancellable)
{
	ESourceCredentialsProvider *provider = source_object;
	AsyncContext *async_context = task_data;
	gboolean success;
	GError *local_error = NULL;

	success = e_source_credentials_provider_lookup_sync (provider,
		async_context->source,
		cancellable,
		&async_context->credentials,
		&local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * e_source_credentials_provider_lookup:
 * @provider: an #ESourceCredentialsProvider
 * @source: an #ESource, to lookup credentials for
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously looks up for credentials for @source.
 *
 * When the operation is finished, @callback will be called. You can then
 * call e_source_credentials_provider_lookup_finish() to get the result
 * of the operation.
 *
 * Since: 3.16
 **/
void
e_source_credentials_provider_lookup (ESourceCredentialsProvider *provider,
				      ESource *source,
				      GCancellable *cancellable,
				      GAsyncReadyCallback callback,
				      gpointer user_data)
{
	ESourceCredentialsProviderImpl *provider_impl;
	ESource *cred_source = NULL;
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider));
	g_return_if_fail (E_IS_SOURCE (source));

	provider_impl = source_credential_provider_ref_impl_for_source (provider, source, &cred_source);
	g_return_if_fail (provider_impl != NULL);

	async_context = async_context_new (cred_source ? cred_source : source, NULL, FALSE);

	task = g_task_new (provider, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_source_credentials_provider_lookup);
	g_task_set_task_data (task, async_context, async_context_free);

	g_task_run_in_thread (task, source_credentials_provider_lookup_thread);

	g_object_unref (task);
	g_clear_object (&provider_impl);
	g_clear_object (&cred_source);
}

/**
 * e_source_credentials_provider_lookup_finish:
 * @provider: an #ESourceCredentialsProvider
 * @result: a #GAsyncResult
 * @out_credentials: (out): return location for the credentials
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_credentials_provider_lookup().
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_lookup_finish (ESourceCredentialsProvider *provider,
					     GAsyncResult *result,
					     ENamedParameters **out_credentials,
					     GError **error)
{
	AsyncContext *async_context;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), FALSE);
	g_return_val_if_fail (out_credentials != NULL, FALSE);
	g_return_val_if_fail (g_task_is_valid (result, provider), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_source_credentials_provider_lookup), FALSE);

	async_context = g_task_get_task_data (G_TASK (result));

	if (!g_task_had_error (G_TASK (result))) {
		*out_credentials = async_context->credentials;
		async_context->credentials = NULL;
	}

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * e_source_credentials_provider_store_sync:
 * @provider: an #ESourceCredentialsProvider
 * @source: an #ESource, to store credentials for
 * @credentials: an #ENamedParameters with credentials to store
 * @permanently: store permanently or just for the session
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Stores the @credentials for @source. Note the actual stored values
 * can differ for each storage. In other words, not all named parameters
 * are stored for each @source.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_store_sync (ESourceCredentialsProvider *provider,
					  ESource *source,
					  const ENamedParameters *credentials,
					  gboolean permanently,
					  GCancellable *cancellable,
					  GError **error)
{
	ESourceCredentialsProviderImpl *provider_impl;
	ESource *cred_source = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (credentials != NULL, FALSE);

	provider_impl = source_credential_provider_ref_impl_for_source (provider, source, &cred_source);
	g_return_val_if_fail (provider_impl != NULL, FALSE);

	success = e_source_credentials_provider_impl_store_sync (provider_impl, cred_source ? cred_source : source, credentials, permanently, cancellable, error);

	g_clear_object (&provider_impl);
	g_clear_object (&cred_source);

	return success;
}

static void
source_credentials_provider_store_thread (GTask *task,
					  gpointer source_object,
					  gpointer task_data,
					  GCancellable *cancellable)
{
	ESourceCredentialsProvider *provider = source_object;
	AsyncContext *async_context = task_data;
	gboolean success;
	GError *local_error = NULL;

	success = e_source_credentials_provider_store_sync (provider,
		async_context->source,
		async_context->credentials,
		async_context->permanently,
		cancellable,
		&local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * e_source_credentials_provider_store:
 * @provider: an #ESourceCredentialsProvider
 * @source: an #ESource, to lookup credentials for
 * @credentials: an #ENamedParameters with credentials to store
 * @permanently: store permanently or just for the session
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously stores the @credentials for @source. Note the actual stored
 * values can differ for each storage. In other words, not all named parameters
 * are stored for each @source.
 *
 * When the operation is finished, @callback will be called. You can then
 * call e_source_credentials_provider_store_finish() to get the result
 * of the operation.
 *
 * Since: 3.16
 **/
void
e_source_credentials_provider_store (ESourceCredentialsProvider *provider,
				     ESource *source,
				     const ENamedParameters *credentials,
				     gboolean permanently,
				     GCancellable *cancellable,
				     GAsyncReadyCallback callback,
				     gpointer user_data)
{
	ESourceCredentialsProviderImpl *provider_impl;
	ESource *cred_source = NULL;
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider));
	g_return_if_fail (E_IS_SOURCE (source));

	provider_impl = source_credential_provider_ref_impl_for_source (provider, source, &cred_source);
	g_return_if_fail (provider_impl != NULL);

	async_context = async_context_new (cred_source ? cred_source : source, credentials, permanently);

	task = g_task_new (provider, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_source_credentials_provider_store);
	g_task_set_task_data (task, async_context, async_context_free);

	g_task_run_in_thread (task, source_credentials_provider_store_thread);

	g_object_unref (task);
	g_clear_object (&provider_impl);
	g_clear_object (&cred_source);
}

/**
 * e_source_credentials_provider_store_finish:
 * @provider: an #ESourceCredentialsProvider
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_credentials_provider_store().
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_store_finish (ESourceCredentialsProvider *provider,
					    GAsyncResult *result,
					    GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, provider), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_source_credentials_provider_store), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * e_source_credentials_provider_delete_sync:
 * @provider: an #ESourceCredentialsProvider
 * @source: an #ESource, to store credentials for
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Deletes any previously stored credentials for @source.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_delete_sync (ESourceCredentialsProvider *provider,
					   ESource *source,
					   GCancellable *cancellable,
					   GError **error)
{
	ESourceCredentialsProviderImpl *provider_impl;
	ESource *cred_source = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	provider_impl = source_credential_provider_ref_impl_for_source (provider, source, &cred_source);
	g_return_val_if_fail (provider_impl != NULL, FALSE);

	success = e_source_credentials_provider_impl_delete_sync (provider_impl, cred_source ? cred_source : source, cancellable, error);

	g_clear_object (&provider_impl);
	g_clear_object (&cred_source);

	return success;
}

static void
source_credentials_provider_delete_thread (GTask *task,
					   gpointer source_object,
					   gpointer task_data,
					   GCancellable *cancellable)
{
	ESourceCredentialsProvider *provider = source_object;
	AsyncContext *async_context = task_data;
	gboolean success;
	GError *local_error = NULL;

	success = e_source_credentials_provider_delete_sync (provider,
		async_context->source, cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * e_source_credentials_provider_delete:
 * @provider: an #ESourceCredentialsProvider
 * @source: an #ESource, to lookup credentials for
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously deletes any previously stored credentials for @source.
 *
 * When the operation is finished, @callback will be called. You can then
 * call e_source_credentials_provider_delete_finish() to get the result
 * of the operation.
 *
 * Since: 3.16
 **/
void
e_source_credentials_provider_delete (ESourceCredentialsProvider *provider,
				      ESource *source,
				      GCancellable *cancellable,
				      GAsyncReadyCallback callback,
				      gpointer user_data)
{
	ESourceCredentialsProviderImpl *provider_impl;
	ESource *cred_source = NULL;
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider));
	g_return_if_fail (E_IS_SOURCE (source));

	provider_impl = source_credential_provider_ref_impl_for_source (provider, source, &cred_source);
	g_return_if_fail (provider_impl != NULL);

	async_context = async_context_new (cred_source ? cred_source : source, NULL, FALSE);

	task = g_task_new (provider, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_source_credentials_provider_delete);
	g_task_set_task_data (task, async_context, async_context_free);

	g_task_run_in_thread (task, source_credentials_provider_delete_thread);

	g_object_unref (task);
	g_clear_object (&provider_impl);
	g_clear_object (&cred_source);
}

/**
 * e_source_credentials_provider_delete_finish:
 * @provider: an #ESourceCredentialsProvider
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_credentials_provider_delete().
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_delete_finish (ESourceCredentialsProvider *provider,
					     GAsyncResult *result,
					     GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER (provider), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, provider), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_source_credentials_provider_delete), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}
