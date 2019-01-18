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
 * Authored by Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

#ifndef _DEE_FILE_RESOURCE_MANAGER_H_
#define _DEE_FILE_RESOURCE_MANAGER_H_

#include <glib.h>
#include <glib-object.h>
#include <dee-resource-manager.h>

G_BEGIN_DECLS

#define DEE_TYPE_FILE_RESOURCE_MANAGER (dee_file_resource_manager_get_type ())

#define DEE_FILE_RESOURCE_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_FILE_RESOURCE_MANAGER, DeeFileResourceManager))
        
#define DEE_FILE_RESOURCE_MANAGER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_FILE_RESOURCE_MANAGER, DeeFileResourceManagerClass))
        
#define DEE_IS_FILE_RESOURCE_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_FILE_RESOURCE_MANAGER))
        
#define DEE_IS_FILE_RESOURCE_MANAGER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_FILE_RESOURCE_MANAGER))
        
#define DEE_FILE_RESOURCE_MANAGER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DEE_TYPE_FILE_RESOURCE_MANAGER, DeeFileResourceManagerClass))

typedef struct _DeeFileResourceManager DeeFileResourceManager;
typedef struct _DeeFileResourceManagerClass DeeFileResourceManagerClass;

struct _DeeFileResourceManager
{
  GObject  parent_instance;
};

struct _DeeFileResourceManagerClass
{
  GObjectClass  parent_class;
};

GType               dee_file_resource_manager_get_type              (void);

DeeResourceManager* dee_file_resource_manager_new              (const gchar *primary_path);

void                dee_file_resource_manager_add_search_path  (DeeResourceManager *self,
                                                                const gchar        *path);

const gchar*        dee_file_resource_manager_get_primary_path (DeeResourceManager *self);

G_END_DECLS

#endif /* _DEE_FILE_RESOURCE_MANAGER_H_ */
