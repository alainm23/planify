/*
 * Copyright (C) 2015 Red Hat, Inc. (www.redhat.com)
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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

#include "e-oauth2-services.h"
#include "e-oauth2-service.h"

#include "e-source-credentials-provider-impl-oauth2.h"

struct _ESourceCredentialsProviderImplOAuth2Private {
	EOAuth2Services *services;
};

G_DEFINE_TYPE (ESourceCredentialsProviderImplOAuth2, e_source_credentials_provider_impl_oauth2, E_TYPE_SOURCE_CREDENTIALS_PROVIDER_IMPL)

static gboolean
e_source_credentials_provider_impl_oauth2_can_process (ESourceCredentialsProviderImpl *provider_impl,
						       ESource *source)
{
	ESourceCredentialsProviderImplOAuth2 *oauth2_provider;
	EOAuth2Service *service;
	gboolean can_process;

	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL_OAUTH2 (provider_impl), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	oauth2_provider = E_SOURCE_CREDENTIALS_PROVIDER_IMPL_OAUTH2 (provider_impl);

	if (!e_oauth2_services_is_supported () || !oauth2_provider->priv->services)
		return FALSE;

	service = e_oauth2_services_find (oauth2_provider->priv->services, source);
	can_process = service != NULL;
	g_clear_object (&service);

	return can_process;
}

static gboolean
e_source_credentials_provider_impl_oauth2_can_store (ESourceCredentialsProviderImpl *provider_impl)
{
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL_OAUTH2 (provider_impl), FALSE);

	return FALSE;
}

static gboolean
e_source_credentials_provider_impl_oauth2_can_prompt (ESourceCredentialsProviderImpl *provider_impl)
{
	g_return_val_if_fail (E_IS_SOURCE_CREDENTIALS_PROVIDER_IMPL_OAUTH2 (provider_impl), FALSE);

	return e_oauth2_services_is_supported ();
}

static void
e_source_credentials_provider_impl_oauth2_dispose (GObject *object)
{
	ESourceCredentialsProviderImplOAuth2 *provider_impl = E_SOURCE_CREDENTIALS_PROVIDER_IMPL_OAUTH2 (object);

	g_clear_object (&provider_impl->priv->services);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_source_credentials_provider_impl_oauth2_parent_class)->dispose (object);
}

static void
e_source_credentials_provider_impl_oauth2_class_init (ESourceCredentialsProviderImplOAuth2Class *klass)
{
	ESourceCredentialsProviderImplClass *impl_class;
	GObjectClass *object_class;

	g_type_class_add_private (klass, sizeof (ESourceCredentialsProviderImplOAuth2Private));

	impl_class = E_SOURCE_CREDENTIALS_PROVIDER_IMPL_CLASS (klass);
	impl_class->can_process = e_source_credentials_provider_impl_oauth2_can_process;
	impl_class->can_store = e_source_credentials_provider_impl_oauth2_can_store;
	impl_class->can_prompt = e_source_credentials_provider_impl_oauth2_can_prompt;

	object_class = G_OBJECT_CLASS (klass);
	object_class->dispose = e_source_credentials_provider_impl_oauth2_dispose;
}

static void
e_source_credentials_provider_impl_oauth2_init (ESourceCredentialsProviderImplOAuth2 *provider_impl)
{
	provider_impl->priv = G_TYPE_INSTANCE_GET_PRIVATE (provider_impl,
		E_TYPE_SOURCE_CREDENTIALS_PROVIDER_IMPL_OAUTH2, ESourceCredentialsProviderImplOAuth2Private);

	if (e_oauth2_services_is_supported ())
		provider_impl->priv->services = e_oauth2_services_new ();
}
