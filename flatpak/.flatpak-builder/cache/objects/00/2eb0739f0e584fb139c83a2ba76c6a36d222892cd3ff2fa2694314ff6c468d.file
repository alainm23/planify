/*
 * Copyright (C) 2010 Canonical, Ltd.
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

#ifndef _HAVE_DEE_SHARED_MODEL_H
#define _HAVE_DEE_SHARED_MODEL_H

#include <glib.h>
#include <glib-object.h>

#include <dee-model.h>
#include <dee-proxy-model.h>
#include <dee-peer.h>

G_BEGIN_DECLS

#define DEE_TYPE_SHARED_MODEL (dee_shared_model_get_type ())

#define DEE_SHARED_MODEL(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_SHARED_MODEL, DeeSharedModel))

#define DEE_SHARED_MODEL_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_SHARED_MODEL, DeeSharedModelClass))

#define DEE_IS_SHARED_MODEL(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_SHARED_MODEL))

#define DEE_IS_SHARED_MODEL_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_SHARED_MODEL))

#define DEE_SHARED_MODEL_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DBUS_TYPE_SHARED_MODEL, DeeSharedModelClass))

typedef struct _DeeSharedModel DeeSharedModel;
typedef struct _DeeSharedModelClass DeeSharedModelClass;
typedef struct _DeeSharedModelPrivate DeeSharedModelPrivate;

/**
 * DeeSharedModel:
 *
 * All fields in the DeeSharedModel structure are private and should never be
 * accessed directly
 */
struct _DeeSharedModel
{
  /*< private >*/
  DeeProxyModel          parent;

  DeeSharedModelPrivate *priv;
};

/**
 * DEE_SHARED_MODEL_DBUS_IFACE:
 *
 * String constant defining the name of the DBus Model interface.
 */
#define DEE_SHARED_MODEL_DBUS_IFACE "com.canonical.Dee.Model"

struct _DeeSharedModelClass
{
  /*< private >*/
  DeeProxyModelClass parent_class;

  /*< private >*/
  void (*_dee_shared_model_1) (void);
  void (*_dee_shared_model_2) (void);
  void (*_dee_shared_model_3) (void);
  void (*_dee_shared_model_4) (void);
};

typedef enum
{
  DEE_SHARED_MODEL_ERROR_LEADER_INVALIDATED
} DeeSharedModelError;

#define DEE_TYPE_SHARED_MODEL_ACCESS_MODE \
  (dee_shared_model_access_mode_get_type ())

/**
 * DeeSharedModelAccessMode:
 *
 * Enumeration defining behavior of the model with regards to writes from
 * other peers in the swarm.
 */
typedef enum
{
  DEE_SHARED_MODEL_ACCESS_MODE_WORLD_WRITABLE,
  DEE_SHARED_MODEL_ACCESS_MODE_LEADER_WRITABLE
} DeeSharedModelAccessMode;

/**
 * dee_shared_model_access_mode_get_type:
 *
 * The GType of #DeeSharedModelAccessMode
 *
 * Return value: the #GType of #DeeSharedModelAccessMode
 **/
GType                 dee_shared_model_access_mode_get_type (void);

#define DEE_TYPE_SHARED_MODEL_FLUSH_MODE \
  (dee_shared_model_flush_mode_get_type ())

/**
 * DeeSharedModelFlushMode:
 *
 * Enumeration defining flushing behavior of a shared model.
 */
typedef enum
{
  DEE_SHARED_MODEL_FLUSH_MODE_AUTOMATIC,
  DEE_SHARED_MODEL_FLUSH_MODE_MANUAL
} DeeSharedModelFlushMode;

/**
 * dee_shared_model_flush_mode_get_type:
 *
 * The GType of #DeeSharedModelFlushMode
 *
 * Return value: the #GType of #DeeSharedModelFlushMode
 **/
GType                 dee_shared_model_flush_mode_get_type (void);

/**
 * dee_shared_model_get_type:
 *
 * The GType of #DeeSharedModel
 *
 * Return value: the #GType of #DeeSharedModel
 **/
GType                 dee_shared_model_get_type        (void);

DeeModel*             dee_shared_model_new             (const gchar *name);

DeeModel*             dee_shared_model_new_for_peer    (DeePeer *peer);

DeeModel*             dee_shared_model_new_with_back_end
                                                       (const gchar *name,
                                                        DeeModel *back_end);

const gchar*          dee_shared_model_get_swarm_name  (DeeSharedModel *self);

DeePeer*              dee_shared_model_get_peer        (DeeSharedModel *self);

gboolean              dee_shared_model_is_leader       (DeeSharedModel *self);

gboolean              dee_shared_model_is_synchronized (DeeSharedModel *self);

guint                 dee_shared_model_flush_revision_queue 
                                                       (DeeSharedModel *self);

guint                 dee_shared_model_flush_revision_queue_sync 
                                                       (DeeSharedModel *self);

void                  dee_shared_model_set_flush_mode  (DeeSharedModel *self,
                                                        DeeSharedModelFlushMode mode);

DeeSharedModelFlushMode dee_shared_model_get_flush_mode (DeeSharedModel *self);

G_END_DECLS

#endif /* _HAVE_DEE_SHARED_MODEL_H */
