/*
 * Copyright (C) 2011 Canonical, Ltd.
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
 * Authored by Michal Hruby <michal.hruby@canonical.com>
 */

#if !defined (_DEE_H_INSIDE) && !defined (DEE_COMPILATION)
#error "Only <dee.h> can be included directly."
#endif

#ifndef _HAVE_DEE_SERVER_H
#define _HAVE_DEE_SERVER_H

#include <glib.h>
#include <glib-object.h>
#include "dee-peer.h"

G_BEGIN_DECLS

#define DEE_TYPE_SERVER dee_server_get_type()

#define DEE_SERVER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), DEE_TYPE_SERVER, DeeServer))

#define DEE_SERVER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), DEE_TYPE_SERVER, DeeServerClass))

#define DEE_IS_SERVER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), DEE_TYPE_SERVER))

#define DEE_IS_SERVER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), DEE_TYPE_SERVER))

#define DEE_SERVER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), DEE_TYPE_SERVER, DeeServerClass))

typedef struct _DeeServerPrivate DeeServerPrivate;

typedef struct {
  /*< private >*/
  DeePeer parent;

  DeeServerPrivate *priv;
} DeeServer;

typedef struct {
  /*< private >*/
  DeePeerClass parent_class;
} DeeServerClass;

/**
 * dee_server_get_type:
 *
 * The GType of #DeeServer
 *
 * Return value: the #GType of #DeeServer
 **/
GType          dee_server_get_type             (void);

DeeServer*     dee_server_new                  (const gchar *swarm_name);

DeeServer*     dee_server_new_for_address      (const gchar *swarm_name,
                                                const gchar *bus_address);

const gchar*   dee_server_get_client_address   (DeeServer *server);

gchar*         dee_server_bus_address_for_name (const gchar *name,
                                                gboolean include_username);

G_END_DECLS

#endif /* _HAVE_DEE_SERVER_H */

