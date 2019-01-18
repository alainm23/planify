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
 * Authored by Neil Jagdish Patel <neil.patel@canonical.com>
 */

#if !defined (_DEE_H_INSIDE) && !defined (DEE_COMPILATION)
#error "Only <dee.h> can be included directly."
#endif

#ifndef _HAVE_DEE_PEER_H
#define _HAVE_DEE_PEER_H

#include <glib.h>
#include <glib-object.h>
#include <gio/gio.h>

G_BEGIN_DECLS

#define DEE_TYPE_PEER (dee_peer_get_type ())

#define DEE_PEER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
        DEE_TYPE_PEER, DeePeer))

#define DEE_PEER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), \
        DEE_TYPE_PEER, DeePeerClass))

#define DEE_IS_PEER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
        DEE_TYPE_PEER))

#define DEE_IS_PEER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), \
        DEE_TYPE_PEER))

#define DEE_PEER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), \
        DEE_TYPE_PEER, DeePeerClass))

typedef struct _DeePeer DeePeer;
typedef struct _DeePeerClass DeePeerClass;
typedef struct _DeePeerPrivate DeePeerPrivate;

#define DEE_PEER_DBUS_IFACE "com.canonical.Dee.Peer"

/**
 * DeePeer:
 *
 * All fields in the DeePeer structure are private and should never be
 * accessed directly
 */
struct _DeePeer
{
  /*< private >*/
  GObject         parent;
 
  DeePeerPrivate   *priv;
};

struct _DeePeerClass
{
  /*< private >*/
  GObjectClass    parent_class;

  /*< public >*/

  /*< signals >*/
  void (*peer_found)          (DeePeer *self, const gchar *name);
  void (*peer_lost)           (DeePeer *self, const gchar *name);
  void (*connection_acquired) (DeePeer *self, GDBusConnection *connection);
  void (*connection_closed)   (DeePeer *self, GDBusConnection *connection);

  /*< vtable >*/
  const gchar* (*get_swarm_leader)  (DeePeer *self);
  gboolean     (*is_swarm_leader)   (DeePeer *self);
  GSList*      (*get_connections)   (DeePeer *self);
  gchar**      (*list_peers)        (DeePeer *self);

  /*< private >*/
  void (*_dee_peer_1) (void);
  void (*_dee_peer_2) (void);
  void (*_dee_peer_3) (void);
};

/**
 * dee_peer_get_type:
 *
 * The GType of #DeePeer
 *
 * Return value: the #GType of #DeePeer
 **/
GType             dee_peer_get_type         (void);

DeePeer*          dee_peer_new              (const gchar* swarm_name);

gboolean          dee_peer_is_swarm_leader  (DeePeer    *self);

const gchar*      dee_peer_get_swarm_leader (DeePeer    *self);

const gchar*      dee_peer_get_swarm_name   (DeePeer    *self);

GSList*           dee_peer_get_connections  (DeePeer    *self);

gchar**           dee_peer_list_peers       (DeePeer    *self);

gboolean          dee_peer_is_swarm_owner   (DeePeer    *self);

G_END_DECLS

#endif /* _HAVE_DEE_PEER_H */
