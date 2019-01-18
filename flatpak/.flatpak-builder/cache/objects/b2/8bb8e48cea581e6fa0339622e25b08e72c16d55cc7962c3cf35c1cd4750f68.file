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

#include <libedataserver/libedataserver.h>

#include "e-server-side-source-credentials-provider.h"

struct _EServerSideSourceCredentialsProviderPrivate {
	gboolean dummy;
};

G_DEFINE_TYPE (EServerSideSourceCredentialsProvider, e_server_side_source_credentials_provider, E_TYPE_SOURCE_CREDENTIALS_PROVIDER)

static ESource *
server_side_source_credentials_provider_ref_source (ESourceCredentialsProvider *provider,
						    const gchar *uid)
{
	ESource *source = NULL;
	GObject *registry;

	g_return_val_if_fail (E_IS_SERVER_SIDE_SOURCE_CREDENTIALS_PROVIDER (provider), NULL);
	g_return_val_if_fail (uid, NULL);

	registry = e_source_credentials_provider_ref_registry (provider);
	if (registry) {
		g_return_val_if_fail (E_IS_SOURCE_REGISTRY_SERVER (registry), NULL);

		source = e_source_registry_server_ref_source (E_SOURCE_REGISTRY_SERVER (registry), uid);
	}

	g_clear_object (&registry);

	return source;
}

static void
e_server_side_source_credentials_provider_class_init (EServerSideSourceCredentialsProviderClass *class)
{
	ESourceCredentialsProviderClass *provider_class;

	g_type_class_add_private (class, sizeof (EServerSideSourceCredentialsProviderPrivate));

	provider_class = E_SOURCE_CREDENTIALS_PROVIDER_CLASS (class);
	provider_class->ref_source = server_side_source_credentials_provider_ref_source;
}

static void
e_server_side_source_credentials_provider_init (EServerSideSourceCredentialsProvider *provider)
{
	provider->priv = G_TYPE_INSTANCE_GET_PRIVATE (provider, E_TYPE_SERVER_SIDE_SOURCE_CREDENTIALS_PROVIDER, EServerSideSourceCredentialsProviderPrivate);
}

/**
 * e_server_side_source_credentials_provider_new:
 * @registry: an #ESourceRegistryServer
 *
 * Creates a new #EServerSideSourceCredentialsProvider, which is meant to abstract
 * credential management for #ESource<!-- -->-s.
 *
 * Returns: (transfer full): a new #EServerSideSourceCredentialsProvider
 *
 * Since: 3.16
 **/
ESourceCredentialsProvider *
e_server_side_source_credentials_provider_new (ESourceRegistryServer *registry)
{
	g_return_val_if_fail (E_IS_SOURCE_REGISTRY_SERVER (registry), NULL);

	return g_object_new (E_TYPE_SERVER_SIDE_SOURCE_CREDENTIALS_PROVIDER,
		"registry", registry,
		NULL);
}
