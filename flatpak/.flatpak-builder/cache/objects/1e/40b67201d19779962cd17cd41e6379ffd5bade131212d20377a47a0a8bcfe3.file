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
 * SECTION:dee-file-resource-manager
 * @short_description: A resource manager backed by memory mapped files
 *
 * This is an implementation of the #DeeResourceManager interface.
 * It uses atomic operations to write resources to files and memory maps
 * the resource files when you load them.
 *
 * Unless you have very specific circumstances you should normally not
 * create resource managers yourself, but get the default one for your
 * platform by calling dee_resource_manager_get_default().
 *
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <sys/stat.h> // for chmod codes for g_mkdir_with_parents()

#include "dee-file-resource-manager.h"
#include "trace-log.h"

static void dee_file_resource_manager_resource_manager_iface_init (DeeResourceManagerIface *iface);
G_DEFINE_TYPE_WITH_CODE (DeeFileResourceManager,
                         dee_file_resource_manager,
                         G_TYPE_OBJECT,
                         G_IMPLEMENT_INTERFACE (DEE_TYPE_RESOURCE_MANAGER,
                                                dee_file_resource_manager_resource_manager_iface_init))

#define DEE_FILE_RESOURCE_MANAGER_GET_PRIVATE(obj) \
  (G_TYPE_INSTANCE_GET_PRIVATE(obj, DEE_TYPE_FILE_RESOURCE_MANAGER, DeeFileResourceManagerPrivate))

enum
{
  PROP_0,
  PROP_PRIMARY_PATH,
};

typedef struct
{
  /* Directories to search for resources. The primary-path is stored
   * as element 0 in this list */
  GSList    *resource_dirs;

  /* Resource monitor ids -> GFileMonitors */
  GHashTable *monitors_by_id;
} DeeFileResourceManagerPrivate;

/* GObject Init */
static void
dee_file_resource_manager_finalize (GObject *object)
{
  DeeFileResourceManagerPrivate *priv;
  
  priv = DEE_FILE_RESOURCE_MANAGER_GET_PRIVATE (object);
  
  g_slist_free_full (priv->resource_dirs, g_free);
  priv->resource_dirs = NULL;

  if (priv->monitors_by_id)
    {
      g_hash_table_unref (priv->monitors_by_id);
      priv->monitors_by_id = NULL;
    }

  G_OBJECT_CLASS (dee_file_resource_manager_parent_class)->finalize (object);
}

static void
dee_file_resource_manager_set_property (GObject       *object,
                                        guint          id,
                                        const GValue  *value,
                                        GParamSpec    *pspec)
{
  DeeResourceManager        *self = DEE_RESOURCE_MANAGER (object);
  gchar                     *path;

  switch (id)
    {
    case PROP_PRIMARY_PATH:
      /* Assume ownership of filter */
      path = g_value_dup_string(value);
      if (path == NULL)
        {
          path = g_build_filename (g_get_user_data_dir (), "resources", NULL);
        }
      dee_file_resource_manager_add_search_path (self, path);
      g_free (path);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_file_resource_manager_get_property (GObject     *object,
                                        guint        id,
                                        GValue      *value,
                                        GParamSpec  *pspec)
{
  DeeFileResourceManagerPrivate *priv;

  priv = DEE_FILE_RESOURCE_MANAGER_GET_PRIVATE (object);

  switch (id)
    {
    case PROP_PRIMARY_PATH:
      g_value_set_string (value, priv->resource_dirs != NULL ?
                                          priv->resource_dirs->data : NULL);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, id, pspec);
      break;
    }
}

static void
dee_file_resource_manager_class_init (DeeFileResourceManagerClass *klass)
{
  GParamSpec    *pspec;
  GObjectClass  *obj_class = G_OBJECT_CLASS (klass);

  obj_class->finalize     = dee_file_resource_manager_finalize;
  obj_class->get_property = dee_file_resource_manager_get_property;
  obj_class->set_property = dee_file_resource_manager_set_property;

  /**
   * DeeFileResourceManager:primary-path:
   *
   * Property holding the primary path used to store and load resources
   */
  pspec = g_param_spec_string("primary-path", "Primary path",
                              "The primary path to to store and load resources from",
                              NULL,
                              G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY
                              | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (obj_class, PROP_PRIMARY_PATH, pspec);

  /* Add private data */
  g_type_class_add_private (obj_class, sizeof (DeeFileResourceManagerPrivate));
}

static void
dee_file_resource_manager_init (DeeFileResourceManager *self)
{
  DeeFileResourceManagerPrivate *priv;

  priv = DEE_FILE_RESOURCE_MANAGER_GET_PRIVATE (self);
  priv->resource_dirs = NULL;
  priv->monitors_by_id = g_hash_table_new_full(g_direct_hash,
                                               g_direct_equal,
                                               NULL,
                                               (GDestroyNotify) g_object_unref);
}

/**
 * dee_file_resource_manager_new:
 * @primary_path: The primary path used to store and load resources.
 *                If you pass %NULL the manager will use a default path.
 *
 * Create a new #DeeFileResourceManager with its primary store- and load
 * path set to @primary_path.
 *
 * You can manually add fallback search paths by calling
 * dee_file_resource_manager_add_search_path().
 *
 * You normally don't need to create you own resource managers. Instead
 * you should call dee_resource_manager_get_default().
 *
 * Return value: (transfer full) (type DeeFileResourceManager): A newly allocated #DeeFileResourceManager.
 *               Free with g_object_unref().
 */
DeeResourceManager*
dee_file_resource_manager_new (const gchar *primary_path)
{
  DeeResourceManager *self;

  self = DEE_RESOURCE_MANAGER (g_object_new (DEE_TYPE_FILE_RESOURCE_MANAGER,
                                             "primary-path", primary_path,
                                             NULL));

  return self;
}

/**
 * dee_file_resource_manager_add_search_path:
 * @self: (type DeeFileResourceManager): The resource manager to add a search
 * path to
 * @path: The path to add to the set of searched paths
 *
 * Add a path to the set of paths searched for resources. The manager will
 * first search the primary path as specified in the constructor and then
 * search paths in the order they where added.
 */
void
dee_file_resource_manager_add_search_path (DeeResourceManager *self,
                                           const gchar        *path)
{
  DeeFileResourceManagerPrivate *priv;

  g_return_if_fail (DEE_IS_FILE_RESOURCE_MANAGER (self));
  g_return_if_fail (path != NULL);

  priv = DEE_FILE_RESOURCE_MANAGER_GET_PRIVATE (self);
  priv->resource_dirs = g_slist_append (priv->resource_dirs,
                                        g_strdup (path));
}

/**
 * dee_file_resource_manager_get_primary_path:
 * @self: (type DeeFileResourceManager): The resource manager to inspect
 *
 * Helper method to access the :primary-path property.
 *
 * Return value: The value of the :primary-path property
 */
const gchar*
dee_file_resource_manager_get_primary_path (DeeResourceManager *self)
{
  DeeFileResourceManagerPrivate *priv;

  g_return_val_if_fail (DEE_IS_FILE_RESOURCE_MANAGER (self), NULL);

  priv = DEE_FILE_RESOURCE_MANAGER_GET_PRIVATE (self);
  return (const gchar *) priv->resource_dirs->data;
}

static gboolean
dee_file_resource_manager_store (DeeResourceManager  *self,
                                 DeeSerializable     *resource,
                                 const gchar         *resource_name,
                                 GError             **error)
{
  GVariant    *external;
  gsize        size;
  gchar       *buf, *path;
  const gchar *primary_path;
  gboolean     stack_allocated_buffer, result, did_retry = FALSE;
  GError      *local_error;

  g_return_val_if_fail (DEE_IS_RESOURCE_MANAGER (self), FALSE);
  g_return_val_if_fail (DEE_IS_SERIALIZABLE (resource), FALSE);
  g_return_val_if_fail (resource_name != NULL, FALSE);
  g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

  external = dee_serializable_externalize (resource);

  if (external == NULL)
    {
      /* This is a programming error, not a runtime error, we don't
       * set the error value */
      g_critical ("When writing DeeSerializable %s@%p to the file %s "
                  "externalize() returned NULL",
                  G_OBJECT_TYPE_NAME (resource), resource, resource_name);
      return FALSE;
    }

  size = g_variant_get_size (external);

  /* For less than ½MB structures we use a stack-allocated buffer,
   * for bigger sizes we use a heap allocated buffer to avoid
   * stack overflows */
  if (size < 524288)
    {
      buf = g_alloca (size);
      stack_allocated_buffer = TRUE;
    }
  else
    {
      buf = g_malloc (size);
      stack_allocated_buffer = FALSE;
    }

  /* Note: Since we're using mmap() in read_from_file() we need atomic
   *       IO operations. Hence g_file_set_contents(). */
  g_variant_store (external, buf);
  primary_path = dee_file_resource_manager_get_primary_path (self);
  path = g_build_filename (primary_path, resource_name, NULL);

  store:
    local_error = NULL;
    result = g_file_set_contents(path, buf, size, &local_error);

    if (local_error)
      {
        /* The resource directory might not exist - try to create it,
         * and then try over  */
        if (local_error->domain == G_FILE_ERROR &&
            local_error->code == G_FILE_ERROR_NOENT &&
            !did_retry)
          {
            trace_object (self, "Failed to write resource %s, "
                          "parent directory %s does not exist. "
                          "Trying to create it",
                          resource_name, primary_path);
            g_error_free (local_error);
            g_mkdir_with_parents (primary_path, S_IRUSR | S_IWUSR | S_IXUSR); // read+write+exec user only permissions
            did_retry = TRUE;
            goto store;
          }
        else
          {
            g_propagate_error (error, local_error);
            goto out;
          }
      }

  out:
    if (result)
      trace_object (self, "Successfully stored %s", path);
    else
      trace_object (self, "Failed to store %s", path);

    g_free (path);

    if (!stack_allocated_buffer)
      g_free (buf);

    g_variant_unref (external);

    return result;
}

static GObject*
_load_resource_from_file (const gchar         *filename,
                          GError             **error)
{
  GMappedFile *map;
  gsize        map_size;
  gchar       *contents;
  GVariant    *external;
  GObject     *object;
  GError      *local_error = NULL;

  g_return_val_if_fail (filename != NULL, FALSE);
  g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

  map = g_mapped_file_new (filename, FALSE, &local_error);

  if (local_error)
    {
      g_propagate_error (error, local_error);
      return NULL;
    }

  contents = g_mapped_file_get_contents (map);
  map_size = g_mapped_file_get_length (map);
  external = g_variant_new_from_data (G_VARIANT_TYPE ("(ua{sv}v)"),
                                      contents,
                                      map_size,
                                      FALSE,
                                      (GDestroyNotify) g_mapped_file_unref,
                                      map);

  object = dee_serializable_parse_external (external);

  return object;
}

static GObject*
dee_file_resource_manager_load (DeeResourceManager *self,
                                const gchar        *resource_name,
                                GError             **error)
{
  DeeFileResourceManagerPrivate *priv;
  gchar                         *resource_path;
  GSList                        *iter;
  GError                        *local_error;
  GObject                       *object = NULL;

  g_return_val_if_fail (DEE_IS_FILE_RESOURCE_MANAGER (self), NULL);
  g_return_val_if_fail (resource_name != NULL, NULL);
  g_return_val_if_fail (error == NULL || *error == NULL, NULL);

  priv = DEE_FILE_RESOURCE_MANAGER_GET_PRIVATE (self);

  for (iter = priv->resource_dirs; iter != NULL; iter = iter->next)
    {
      resource_path = g_build_filename (iter->data, resource_name, NULL);

      trace_object (self, "Looking up resource %s in %s",
                    resource_name, iter->data);

      local_error = NULL;
      object = _load_resource_from_file (resource_path, &local_error);
      g_free (resource_path);

      /* If we get any error except no-such-file-or-directory we bail out */
      if (local_error != NULL)
        {
          if (local_error->domain == G_FILE_ERROR &&
              local_error->code == G_FILE_ERROR_NOENT)
            {
              continue;
            }
          else
            {
              g_propagate_error (error, local_error);
              break;
            }
        }

      if (object != NULL)
        break;
    }

  return object;
}

static void
dee_file_resource_manager_resource_manager_iface_init (DeeResourceManagerIface *iface)
{
  iface->store             = dee_file_resource_manager_store;
  iface->load              = dee_file_resource_manager_load;
}

