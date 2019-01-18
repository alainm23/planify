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

#include <libedataserver/libedataserver.h>

#include "e-source-credentials-provider-impl-password.h"

struct _ESourceCredentialsProviderImplPasswordPrivate {
	gboolean dummy;
};

G_DEFINE_TYPE (ESourceCredentialsProviderImplPassword, e_source_credentials_provider_impl_password, E_TYPE_SOURCE_CREDENTIALS_PROVIDER_IMPL)

static gboolean
e_source_credentials_provider_impl_password_can_process (ESourceCredentialsProviderImpl *provider_impl,
							 ESource *source)
{
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL_PASSWORD (provider_impl), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	/* It can process any source by default */
	return TRUE;
}

static gboolean
e_source_credentials_provider_impl_password_can_store (ESourceCredentialsProviderImpl *provider_impl)
{
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL_PASSWORD (provider_impl), FALSE);

	return TRUE;
}

static gboolean
e_source_credentials_provider_impl_password_can_prompt (ESourceCredentialsProviderImpl *provider_impl)
{
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL_PASSWORD (provider_impl), FALSE);

	return TRUE;
}

static gboolean
e_source_credentials_provider_impl_password_lookup_sync (ESourceCredentialsProviderImpl *provider_impl,
							 ESource *source,
							 GCancellable *cancellable,
							 ENamedParameters **out_credentials,
							 GError **error)
{
	gchar *password = NULL;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL_PASSWORD (provider_impl), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (out_credentials != NULL, FALSE);

	*out_credentials = NULL;

	if (!e_source_lookup_password_sync (source, cancellable, &password, error))
		return FALSE;

	if (!password) {
		g_set_error_literal (error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND, _("Password not found"));
		return FALSE;
	}

	*out_credentials = e_named_parameters_new ();
	e_named_parameters_set (*out_credentials, E_SOURCE_CREDENTIAL_PASSWORD, password);

	e_util_safe_free_string (password);

	return TRUE;
}

static gboolean
e_source_credentials_provider_impl_password_store_sync (ESourceCredentialsProviderImpl *provider_impl,
							ESource *source,
							const ENamedParameters *credentials,
							gboolean permanently,
							GCancellable *cancellable,
							GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL_PASSWORD (provider_impl), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (credentials != NULL, FALSE);
	g_return_val_if_fail (e_named_parameters_get (credentials, E_SOURCE_CREDENTIAL_PASSWORD) != NULL, FALSE);

	return e_source_store_password_sync (source,
		e_named_parameters_get (credentials, E_SOURCE_CREDENTIAL_PASSWORD),
		permanently, cancellable, error);
}

static gboolean
e_source_credentials_provider_impl_password_delete_sync (ESourceCredentialsProviderImpl *provider_impl,
							 ESource *source,
							 GCancellable *cancellable,
							 GError **error)
{
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL_PASSWORD (provider_impl), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	return e_source_delete_password_sync (source, cancellable, error);
}

static void
e_source_credentials_provider_impl_password_class_init (ESourceCredentialsProviderImplPasswordClass *klass)
{
	ESourceCredentialsProviderImplClass *impl_class;

	g_type_class_add_private (klass, sizeof (ESourceCredentialsProviderImplPasswordPrivate));

	impl_class = E_SOURCE_CREDENTIALS_PROVIDER_IMPL_CLASS (klass);
	impl_class->can_process = e_source_credentials_provider_impl_password_can_process;
	impl_class->can_store = e_source_credentials_provider_impl_password_can_store;
	impl_class->can_prompt = e_source_credentials_provider_impl_password_can_prompt;
	impl_class->lookup_sync = e_source_credentials_provider_impl_password_lookup_sync;
	impl_class->store_sync = e_source_credentials_provider_impl_password_store_sync;
	impl_class->delete_sync = e_source_credentials_provider_impl_password_delete_sync;
}

static void
e_source_credentials_provider_impl_password_init (ESourceCredentialsProviderImplPassword *provider_impl)
{
	provider_impl->priv = G_TYPE_INSTANCE_GET_PRIVATE (provider_impl,
		E_TYPE_SOURCE_CREDENTIALS_PROVIDER_IMPL_PASSWORD, ESourceCredentialsProviderImplPasswordPrivate);
}
