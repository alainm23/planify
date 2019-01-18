/*
 * e-collection-backend-factory.c
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
 * SECTION: e-collection-backend-factory
 * @include: libebackend/libebackend.h
 * @short_description: A base class for a data source collection
 *                     backend factory
 *
 * #ECollectionBackendFactory is a type of #EBackendFactory for creating
 * #ECollectionBackend instances.
 **/

#include <string.h>

#include "e-collection-backend-factory.h"

#include <libedataserver/libedataserver.h>

#include <libebackend/e-collection-backend.h>
#include <libebackend/e-source-registry-server.h>

G_DEFINE_TYPE (
	ECollectionBackendFactory,
	e_collection_backend_factory,
	E_TYPE_BACKEND_FACTORY)

static ESourceRegistryServer *
collection_backend_factory_get_server (EBackendFactory *factory)
{
	EExtensible *extensible;

	extensible = e_extension_get_extensible (E_EXTENSION (factory));

	return E_SOURCE_REGISTRY_SERVER (extensible);
}

static const gchar *
collection_backend_factory_get_hash_key (EBackendFactory *factory)
{
	ECollectionBackendFactoryClass *class;
	const gchar *component_name;
	gchar *hash_key;
	gsize length;

	class = E_COLLECTION_BACKEND_FACTORY_GET_CLASS (factory);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->factory_name != NULL, NULL);

	component_name = E_SOURCE_EXTENSION_COLLECTION;

	/* Hash key: FACTORY ´:' COMPONENT_NAME */
	length = strlen (class->factory_name) + strlen (component_name) + 2;
	hash_key = g_alloca (length);
	g_snprintf (
		hash_key, length, "%s:%s",
		class->factory_name, component_name);

	return g_intern_string (hash_key);
}

static EBackend *
collection_backend_factory_new_backend (EBackendFactory *factory,
                                        ESource *source)
{
	ECollectionBackendFactoryClass *class;
	ESourceRegistryServer *server;

	class = E_COLLECTION_BACKEND_FACTORY_GET_CLASS (factory);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (g_type_is_a (class->backend_type, E_TYPE_COLLECTION_BACKEND), NULL);

	server = collection_backend_factory_get_server (factory);

	return g_object_new (
		class->backend_type,
		"server", server,
		"source", source, NULL);
}

static void
collection_backend_factory_prepare_mail (ECollectionBackendFactory *factory,
                                         ESource *mail_account_source,
                                         ESource *mail_identity_source,
                                         ESource *mail_transport_source)
{
	ESource *source;
	ESourceExtension *extension;
	const gchar *extension_name;

	/* This does only very basic configuration.
	 * The rest is for subclasses to implement. */

	source = mail_account_source;

	extension_name = E_SOURCE_EXTENSION_MAIL_ACCOUNT;
	extension = e_source_get_extension (source, extension_name);

	e_source_mail_account_set_identity_uid (
		E_SOURCE_MAIL_ACCOUNT (extension),
		e_source_get_uid (mail_identity_source));

	source = mail_identity_source;

	/* This just makes sure the extension is present
	 * so the source is recognized as a mail identity. */
	extension_name = E_SOURCE_EXTENSION_MAIL_IDENTITY;
	e_source_get_extension (source, extension_name);

	extension_name = E_SOURCE_EXTENSION_MAIL_SUBMISSION;
	extension = e_source_get_extension (source, extension_name);

	e_source_mail_submission_set_transport_uid (
		E_SOURCE_MAIL_SUBMISSION (extension),
		e_source_get_uid (mail_transport_source));

	source = mail_transport_source;

	/* This just makes sure the extension is present
	 * so the source is recognized as a mail transport. */
	extension_name = E_SOURCE_EXTENSION_MAIL_TRANSPORT;
	e_source_get_extension (source, extension_name);
}

static void
e_collection_backend_factory_class_init (ECollectionBackendFactoryClass *class)
{
	EExtensionClass *extension_class;
	EBackendFactoryClass *factory_class;

	extension_class = E_EXTENSION_CLASS (class);
	extension_class->extensible_type = E_TYPE_SOURCE_REGISTRY_SERVER;

	factory_class = E_BACKEND_FACTORY_CLASS (class);
	factory_class->get_hash_key = collection_backend_factory_get_hash_key;
	factory_class->new_backend = collection_backend_factory_new_backend;

	class->factory_name = "none";
	class->backend_type = E_TYPE_COLLECTION_BACKEND;
	class->prepare_mail = collection_backend_factory_prepare_mail;
}

static void
e_collection_backend_factory_init (ECollectionBackendFactory *factory)
{
}

/**
 * e_collection_backend_factory_prepare_mail:
 * @factory: an #ECollectionBackendFactory
 * @mail_account_source: an #ESource to hold mail account information
 * @mail_identity_source: an #ESource to hold mail identity information
 * @mail_transport_source: an #ESource to hold mail transport information
 *
 * Convenience function to populate a set of #ESource instances with mail
 * account information to be added to an #ECollectionBackend.  This is mainly
 * used for vendor-specific collection backends like Google or Yahoo! where
 * the host, port, and security details are known ahead of time and only
 * user-specific information needs to be filled in.
 *
 * Since: 3.6
 **/
void
e_collection_backend_factory_prepare_mail (ECollectionBackendFactory *factory,
                                           ESource *mail_account_source,
                                           ESource *mail_identity_source,
                                           ESource *mail_transport_source)
{
	ECollectionBackendFactoryClass *class;

	g_return_if_fail (E_IS_COLLECTION_BACKEND_FACTORY (factory));
	g_return_if_fail (E_IS_SOURCE (mail_account_source));
	g_return_if_fail (E_IS_SOURCE (mail_identity_source));
	g_return_if_fail (E_IS_SOURCE (mail_transport_source));

	class = E_COLLECTION_BACKEND_FACTORY_GET_CLASS (factory);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->prepare_mail != NULL);

	class->prepare_mail (
		factory,
		mail_account_source,
		mail_identity_source,
		mail_transport_source);
}

