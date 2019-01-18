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

#if !defined (_DEE_H_INSIDE) && !defined (DEE_COMPILATION)
#error "Only <dee.h> can be included directly."
#endif

#ifndef _DEE_RESOURCE_MANAGER_H_
#define _DEE_RESOURCE_MANAGER_H_

#include <glib.h>
#include <glib-object.h>
#include <dee-serializable.h>

G_BEGIN_DECLS

#define DEE_TYPE_RESOURCE_MANAGER (dee_resource_manager_get_type ())

#define DEE_RESOURCE_MANAGER(obj) \
        (G_TYPE_CHECK_INSTANCE_CAST ((obj), DEE_TYPE_RESOURCE_MANAGER, DeeResourceManager))

#define DEE_IS_RESOURCE_MANAGER(obj) \
       (G_TYPE_CHECK_INSTANCE_TYPE ((obj), DEE_TYPE_RESOURCE_MANAGER))

#define DEE_RESOURCE_MANAGER_GET_IFACE(obj) \
       (G_TYPE_INSTANCE_GET_INTERFACE(obj, dee_resource_manager_get_type (), DeeResourceManagerIface))

typedef struct _DeeResourceManagerIface DeeResourceManagerIface;
typedef struct _DeeResourceManager DeeResourceManager;

struct _DeeResourceManagerIface
{
  GTypeInterface g_iface;

  /*< public >*/
  gboolean       (*store)         (DeeResourceManager  *self,
                                   DeeSerializable     *resource,
                                   const gchar         *resource_name,
                                   GError             **error);

  GObject*       (*load)          (DeeResourceManager  *self,
                                   const gchar         *resource_name,
                                   GError             **error);

  /*< private >*/
  void     (*_dee_resource_manager_1) (void);
  void     (*_dee_resource_manager_2) (void);
  void     (*_dee_resource_manager_3) (void);
  void     (*_dee_resource_manager_4) (void);
  void     (*_dee_resource_manager_5) (void);
  void     (*_dee_resource_manager_6) (void);
  void     (*_dee_resource_manager_7) (void);
  void     (*_dee_resource_manager_8) (void);
};

GType           dee_resource_manager_get_type          (void);

gboolean        dee_resource_manager_store             (DeeResourceManager  *self,
                                                        DeeSerializable     *resource,
                                                        const gchar         *resource_name,
                                                        GError             **error);

GObject*        dee_resource_manager_load              (DeeResourceManager  *self,
                                                        const gchar         *resource_name,
                                                        GError             **error);

DeeResourceManager* dee_resource_manager_get_default   (void);

G_END_DECLS

#endif /* _HAVE_DEE_RESOURCE_MANAGER_H */
