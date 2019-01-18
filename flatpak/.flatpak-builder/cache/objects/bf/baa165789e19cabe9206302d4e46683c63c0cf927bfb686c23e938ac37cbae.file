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

#ifndef _HAVE_DEE_CLIENT_H
#define _HAVE_DEE_CLIENT_H

#include <glib.h>
#include <glib-object.h>
#include "dee-peer.h"

G_BEGIN_DECLS

#define DEE_TYPE_CLIENT dee_client_get_type()

#define DEE_CLIENT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), DEE_TYPE_CLIENT, DeeClient))

#define DEE_CLIENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), DEE_TYPE_CLIENT, DeeClientClass))

#define DEE_IS_CLIENT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), DEE_TYPE_CLIENT))

#define DEE_IS_CLIENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), DEE_TYPE_CLIENT))

#define DEE_CLIENT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), DEE_TYPE_CLIENT, DeeClientClass))

typedef struct _DeeClientPrivate DeeClientPrivate;

typedef struct {
  /*< private >*/
  DeePeer parent;

  DeeClientPrivate *priv;
} DeeClient;

typedef struct {
  /*< private >*/
  DeePeerClass parent_class;
} DeeClientClass;

/**
 * dee_client_get_type:
 *
 * The GType of #DeeClient.
 *
 * Return value: the #GType of #DeeClient.
 **/
GType          dee_client_get_type         (void);

DeeClient*     dee_client_new              (const gchar *swarm_name);

DeeClient*     dee_client_new_for_address  (const gchar* swarm_name,
                                            const gchar* bus_address);

G_END_DECLS

#endif /* _HAVE_DEE_CLIENT_H */

