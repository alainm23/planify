/*
 * Copyright (C) 2009 Canonical, Ltd.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License
 * version 3.0 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see
 * <http://www.gnu.org/licenses/>.
 *
 * Authored by:
 *               Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

/**
 * SECTION:dee-resource-manager
 * @short_description: Store and load #DeeSerializable<!-- -->s by name
 * @include: dee.h
 *
 * The #DeeResourceManager API provides a simple API for storing and loading
 * DeeSerializable<!-- -->s from some persistent storage. The resources
 * are stored in a flat structure identified by names that should be chosen
 * similarly to DBus names. That is reverse domain names ala
 * net.launchpad.Example.MyData.
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "dee-serializable.h"
#include "dee-resource-manager.h"
#include "dee-file-resource-manager.h"
#include "trace-log.h"

typedef DeeResourceManagerIface DeeResourceManagerInterface;
G_DEFINE_INTERFACE (DeeResourceManager, dee_resource_manager, G_TYPE_OBJECT)

static DeeResourceManager *_default_resource_manager = NULL;

static void
dee_resource_manager_default_init (DeeResourceManagerInterface *klass)
{
  
}

/**
 * dee_resource_manager_store:
 * @self: The resource manager to invoke
 * @resource: (transfer none):A #DeeSerializable to store under @resource_name
 * @resource_name: The name to store the resource under. Will overwrite any
 *                 existing resource with the same name
 * @error: A return location for a #GError pointer. %NULL to ignore errors
 *
 * Store a resource under a given name. The resource manager must guarantee
 * that the stored data survives system reboots and that you can recreate a
 * copy of @resource by calling dee_resource_manager_load() using the
 * same @resource_name.
 *
 * Important note: This call may do blocking IO. The resource manager must
 * guarantee that this call is reasonably fast, like writing the externalized
 * resource to a file, but not blocking IO over a network socket.
 *
 * Return value: %TRUE on success and %FALSE otherwise. In case of a runtime
 *               error the @error pointer will point to a #GError in the
 *               #DeeResourceError domain.
 */
gboolean
dee_resource_manager_store (DeeResourceManager  *self,
                            DeeSerializable     *resource,
                            const gchar         *resource_name,
                            GError             **error)
{
  DeeResourceManagerIface *iface;

  g_return_val_if_fail (DEE_IS_RESOURCE_MANAGER (self), FALSE);
  g_return_val_if_fail (DEE_IS_SERIALIZABLE(resource), FALSE);
  g_return_val_if_fail (resource_name != NULL, FALSE);
  g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

  iface = DEE_RESOURCE_MANAGER_GET_IFACE (self);

  return (* iface->store) (self, resource, resource_name, error);
}

/**
 * dee_resource_manager_load:
 * @self: The resource manager to invoke
 * @resource_name: The name of the resource to retrieve
 * @error: A return location for a #GError pointer. %NULL to ignore errors
 *
 * Load a resource from persistent storage. The loaded resource will be of the
 * same GType as when it was stored (provided that the same serialization and
 * parse functions are registered).
 *
 * In case of an error the error will be in the #GFileError domain. Specifically
 * if there is no resource with the name @resource_name the error code will
 * be #G_FILE_ERROR_NOENT.
 *
 * Important note: This call may do blocking IO. The resource manager must
 * guarantee that this call is reasonably fast, like writing the externalized
 * resource to a file, but not blocking IO over a network socket.
 *
 * Return value: (transfer full): A newly allocated #GObject in case of success
 *               and %NULL otherwise. In case of a runtime error the @error
 *               pointer will be set.
 */
GObject*
dee_resource_manager_load (DeeResourceManager *self,
                           const gchar        *resource_name,
                           GError            **error)
{
  DeeResourceManagerIface *iface;

  g_return_val_if_fail (DEE_IS_RESOURCE_MANAGER (self), NULL);
  g_return_val_if_fail (resource_name != NULL, NULL);
  g_return_val_if_fail (error == NULL || *error == NULL, NULL);

  iface = DEE_RESOURCE_MANAGER_GET_IFACE (self);

  return (* iface->load) (self, resource_name, error);
}

/**
 * dee_resource_manager_get_default:
 *
 * Get a pointer to the platform default #DeeResourceManager.
 *
 * Return value: (transfer none): The default resource manager for the platform.
 *               Do not unreference. If you need to keep the instance around
 *               you must manually reference it.
 */
DeeResourceManager*
dee_resource_manager_get_default (void)
{
  if (_default_resource_manager == NULL)
    {
      _default_resource_manager = dee_file_resource_manager_new (NULL);
    }

  return _default_resource_manager;
}
