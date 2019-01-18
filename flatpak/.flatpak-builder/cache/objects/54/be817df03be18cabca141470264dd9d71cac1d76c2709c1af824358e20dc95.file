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

#include "e-source-credentials-provider.h"
#include "e-source-credentials-provider-impl.h"

struct _ESourceCredentialsProviderImplPrivate {
	gboolean dummy;
};

G_DEFINE_ABSTRACT_TYPE (ESourceCredentialsProviderImpl, e_source_credentials_provider_impl, E_TYPE_EXTENSION)

static gboolean
source_credentials_provider_impl_lookup_sync (ESourceCredentialsProviderImpl *provider_impl,
					      ESource *source,
					      GCancellable *cancellable,
					      ENamedParameters **out_credentials,
					      GError **error)
{
	g_set_error_literal (error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED, _("Credentials lookup is not supported"));

	return FALSE;
}

static gboolean
source_credentials_provider_impl_store_sync (ESourceCredentialsProviderImpl *provider_impl,
					     ESource *source,
					     const ENamedParameters *credentials,
					     gboolean permanently,
					     GCancellable *cancellable,
					     GError **error)
{
	g_set_error_literal (error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED, _("Credentials store is not supported"));

	return FALSE;
}

static gboolean
source_credentials_provider_impl_delete_sync (ESourceCredentialsProviderImpl *provider_impl,
					      ESource *source,
					      GCancellable *cancellable,
					      GError **error)
{
	g_set_error_literal (error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED, _("Credentials delete is not supported"));

	return FALSE;
}

static void
e_source_credentials_provider_impl_constructed (GObject *object)
{
	ESourceCredentialsProviderImpl *provider_impl = E_SOURCE_CREDENTIALS_PROVIDER_IMPL (object);
	ESourceCredentialsProvider *provider;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_source_credentials_provider_impl_parent_class)->constructed (object);

	provider = E_SOURCE_CREDENTIALS_PROVIDER (e_extension_get_extensible (E_EXTENSION (provider_impl)));

	e_source_credentials_provider_register_impl (provider, provider_impl);
}

static void
e_source_credentials_provider_impl_class_init (ESourceCredentialsProviderImplClass *klass)
{
	GObjectClass *object_class;
	EExtensionClass *extension_class;
	ESourceCredentialsProviderImplClass *provider_impl_class;

	g_type_class_add_private (klass, sizeof (ESourceCredentialsProviderImplPrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->constructed = e_source_credentials_provider_impl_constructed;

	extension_class = E_EXTENSION_CLASS (klass);
	extension_class->extensible_type = E_TYPE_SOURCE_CREDENTIALS_PROVIDER;

	provider_impl_class = E_SOURCE_CREDENTIALS_PROVIDER_IMPL_CLASS (klass);
	provider_impl_class->lookup_sync = source_credentials_provider_impl_lookup_sync;
	provider_impl_class->store_sync = source_credentials_provider_impl_store_sync;
	provider_impl_class->delete_sync = source_credentials_provider_impl_delete_sync;
}

static void
e_source_credentials_provider_impl_init (ESourceCredentialsProviderImpl *provider_impl)
{
	provider_impl->priv = G_TYPE_INSTANCE_GET_PRIVATE (provider_impl,
		E_TYPE_SOURCE_CREDENTIALS_PROVIDER_IMPL, ESourceCredentialsProviderImplPrivate);
}

/**
 * e_source_credentials_provider_impl_get_provider:
 * @provider_impl: an #ESourceCredentialsProviderImpl
 *
 * Returns an #ESourceCredentialsProvider with which the @provider_impl is associated.
 *
 * Returns: (transfer none) : an #ESourceCredentialsProvider
 *
 * Since: 3.16
 **/
ESourceCredentialsProvider *
e_source_credentials_provider_impl_get_provider (ESourceCredentialsProviderImpl *provider_impl)
{
	EExtensible *extensible;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL (provider_impl), NULL);

	extensible = e_extension_get_extensible (E_EXTENSION (provider_impl));
	if (!extensible)
		return NULL;

	return E_SOURCE_CREDENTIALS_PROVIDER (extensible);
}

/**
 * e_source_credentials_provider_impl_can_process:
 * @provider_impl: an #ESourceCredentialsProviderImpl
 * @source: an #ESource
 *
 * Returns whether the @provider_impl can process credentials for the @source.
 *
 * Returns: Whether the @provider_impl can process credentials for the @source.
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_impl_can_process (ESourceCredentialsProviderImpl *provider_impl,
						ESource *source)
{
	ESourceCredentialsProviderImplClass *klass;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL (provider_impl), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	klass = E_SOURCE_CREDENTIALS_PROVIDER_IMPL_GET_CLASS (provider_impl);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->can_process != NULL, FALSE);

	return klass->can_process (provider_impl, source);
}

/**
 * e_source_credentials_provider_impl_can_store:
 * @provider_impl: an #ESourceCredentialsProviderImpl
 *
 * Returns whether the @provider_impl can store credentials.
 *
 * Returns: Whether the @provider_impl can store credentials.
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_impl_can_store (ESourceCredentialsProviderImpl *provider_impl)
{
	ESourceCredentialsProviderImplClass *klass;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL (provider_impl), FALSE);

	klass = E_SOURCE_CREDENTIALS_PROVIDER_IMPL_GET_CLASS (provider_impl);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->can_store != NULL, FALSE);

	return klass->can_store (provider_impl);
}

/**
 * e_source_credentials_provider_impl_can_prompt:
 * @provider_impl: an #ESourceCredentialsProviderImpl
 *
 * Returns whether credential prompt can be done for the @provider_impl.
 *
 * Returns: Whether credential prompt can be done for the @provider_impl.
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_impl_can_prompt (ESourceCredentialsProviderImpl *provider_impl)
{
	ESourceCredentialsProviderImplClass *klass;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL (provider_impl), FALSE);

	klass = E_SOURCE_CREDENTIALS_PROVIDER_IMPL_GET_CLASS (provider_impl);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->can_prompt != NULL, FALSE);

	return klass->can_prompt (provider_impl);
}

/**
 * e_source_credentials_provider_impl_lookup_sync:
 * @provider_impl: an #ESourceCredentialsProviderImpl
 * @source: an #ESource
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @out_credentials: (out): an #ENamedParameters to be set with stored credentials
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Asks @provider_impl to lookup for stored credentials for @source.
 * The @out_credentials is populated with them. If the result is not
 * %NULL, then it should be freed with e_named_parameters_free() when
 * no longer needed.
 *
 * Default implementation returns %FALSE and sets #G_IO_ERROR_NOT_SUPPORTED error.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_impl_lookup_sync (ESourceCredentialsProviderImpl *provider_impl,
						ESource *source,
						GCancellable *cancellable,
						ENamedParameters **out_credentials,
						GError **error)
{
	ESourceCredentialsProviderImplClass *klass;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL (provider_impl), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (out_credentials != NULL, FALSE);

	klass = E_SOURCE_CREDENTIALS_PROVIDER_IMPL_GET_CLASS (provider_impl);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->lookup_sync != NULL, FALSE);

	return klass->lookup_sync (provider_impl, source, cancellable, out_credentials, error);
}

/**
 * e_source_credentials_provider_impl_store_sync:
 * @provider_impl: an #ESourceCredentialsProviderImpl
 * @source: an #ESource
 * @credentials: an #ENamedParameters containing credentials to store
 * @permanently: whether to store credentials permanently, or for the current session only
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Asks @provider_impl to store @credentials for @source.
 *
 * Default implementation returns %FALSE and sets #G_IO_ERROR_NOT_SUPPORTED error.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_impl_store_sync (ESourceCredentialsProviderImpl *provider_impl,
					       ESource *source,
					       const ENamedParameters *credentials,
					       gboolean permanently,
					       GCancellable *cancellable,
					       GError **error)
{
	ESourceCredentialsProviderImplClass *klass;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL (provider_impl), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (credentials != NULL, FALSE);

	klass = E_SOURCE_CREDENTIALS_PROVIDER_IMPL_GET_CLASS (provider_impl);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->store_sync != NULL, FALSE);

	return klass->store_sync (provider_impl, source, credentials, permanently, cancellable, error);
}

/**
 * e_source_credentials_provider_impl_delete_sync:
 * @provider_impl: an #ESourceCredentialsProviderImpl
 * @source: an #ESource
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Asks @provider_impl to delete any stored credentials for @source.
 *
 * Default implementation returns %FALSE and sets #G_IO_ERROR_NOT_SUPPORTED error.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_source_credentials_provider_impl_delete_sync (ESourceCredentialsProviderImpl *provider_impl,
						ESource *source,
						GCancellable *cancellable,
						GError **error)
{
	ESourceCredentialsProviderImplClass *klass;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL (provider_impl), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	klass = E_SOURCE_CREDENTIALS_PROVIDER_IMPL_GET_CLASS (provider_impl);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->delete_sync != NULL, FALSE);

	return klass->delete_sync (provider_impl, source, cancellable, error);
}
