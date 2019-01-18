/*
 * e-backend-factory.c
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
 * SECTION: e-backend-factory
 * @include: libebackend/libebackend.h
 * @short_description: An abstract base class for backend factories
 *
 * An #EBackendFactory's job is to create an #EBackend instance for a
 * given #ESource.  #EBackendFactory and #EBackend should be subclassed
 * together, so that each type of #EBackendFactory creates a unique type
 * of #EBackend.
 *
 * Each #EBackendFactory subclass must define a hash key to uniquely
 * identify itself among other #EBackendFactory subclasses.  #EDataFactory
 * then services incoming connection requests by deriving a hash key from
 * the requested #ESource, using the dervied hash key to find an appropriate
 * #EBackendFactory, and creating an #EBackend instance from that factory
 * to pair with the requested #ESource.
 **/

#include "evolution-data-server-config.h"

#include <libedataserver/libedataserver.h>

#include <libebackend/e-data-factory.h>

#include "e-backend-factory.h"

G_DEFINE_ABSTRACT_TYPE (EBackendFactory, e_backend_factory, E_TYPE_EXTENSION)

static void
e_backend_factory_class_init (EBackendFactoryClass *class)
{
	EExtensionClass *extension_class;

	extension_class = E_EXTENSION_CLASS (class);
	extension_class->extensible_type = E_TYPE_DATA_FACTORY;
}

static void
e_backend_factory_init (EBackendFactory *factory)
{
}

/**
 * e_backend_factory_get_hash_key:
 * @factory: an #EBackendFactory
 *
 * Returns a hash key which uniquely identifies @factory.
 *
 * Since only one instance of each #EBackendFactory subclass is ever created,
 * the hash key need only be unique among subclasses, not among instances of
 * each subclass.
 *
 * Returns: a hash key which uniquely identifies @factory
 *
 * Since: 3.4
 **/
const gchar *
e_backend_factory_get_hash_key (EBackendFactory *factory)
{
	EBackendFactoryClass *class;

	g_return_val_if_fail (E_IS_BACKEND_FACTORY (factory), NULL);

	class = E_BACKEND_FACTORY_GET_CLASS (factory);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_hash_key != NULL, NULL);

	return class->get_hash_key (factory);
}

/**
 * e_backend_factory_new_backend:
 * @factory: an #EBackendFactory
 * @source: an #ESource
 *
 * Returns a new #EBackend instance for @source.
 *
 * Returns: a new #EBackend instance for @source
 *
 * Since: 3.4
 **/
EBackend *
e_backend_factory_new_backend (EBackendFactory *factory,
                               ESource *source)
{
	EBackendFactoryClass *class;

	g_return_val_if_fail (E_IS_BACKEND_FACTORY (factory), NULL);
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	class = E_BACKEND_FACTORY_GET_CLASS (factory);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->new_backend != NULL, NULL);

	return class->new_backend (factory, source);
}

/**
 * e_backend_factory_get_module_filename:
 * @factory: an #EBackendFactory
 *
 * Returns the filename of the shared library for the module used
 * to load the backends provided by @factory.
 *
 * Returns: the filename for the module associated to the @factory
 *
 * Since: 3.16
 **/
const gchar *
e_backend_factory_get_module_filename (EBackendFactory *factory)
{
	EBackendFactoryClass *class;

	g_return_val_if_fail (E_IS_BACKEND_FACTORY (factory), NULL);

	class = E_BACKEND_FACTORY_GET_CLASS (factory);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->e_module != NULL, NULL);

	return e_module_get_filename (class->e_module);
}

/**
 * e_backend_factory_share_subprocess:
 * @factory: an #EBackendFactory
 *
 * Returns TRUE if the @factory wants to share the subprocess
 * for all backends provided by itself. Otherwise, returns FALSE.
 *
 * Returns: TRUE if the @factory shares the subprocess for all its
 *          backends. Otherwise, FALSE.
 *
 * Since: 3.16
 **/
gboolean
e_backend_factory_share_subprocess (EBackendFactory *factory)
{
	EBackendFactoryClass *class;

	g_return_val_if_fail (E_IS_BACKEND_FACTORY (factory), FALSE);

	class = E_BACKEND_FACTORY_GET_CLASS (factory);
	g_return_val_if_fail (class != NULL, FALSE);

	return class->share_subprocess;
}
