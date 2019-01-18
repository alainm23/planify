/*
 * client.h - proxy for a Telepathy client
 *
 * Copyright (C) 2009 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2009 Nokia Corporation
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef TP_CLIENT_H
#define TP_CLIENT_H

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/proxy.h>

G_BEGIN_DECLS

typedef struct _TpClient TpClient;
typedef struct _TpClientClass TpClientClass;
typedef struct _TpClientPrivate TpClientPrivate;
typedef struct _TpClientClassPrivate TpClientClassPrivate;

struct _TpClient {
    /*<private>*/
    TpProxy parent;
    TpClientPrivate *priv;
};

struct _TpClientClass {
    /*<private>*/
    TpProxyClass parent_class;
    GCallback _padding[7];
    TpClientClassPrivate *priv;
};

GType tp_client_get_type (void);

#define TP_TYPE_CLIENT \
  (tp_client_get_type ())
#define TP_CLIENT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CLIENT, \
                               TpClient))
#define TP_CLIENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_CLIENT, \
                            TpClientClass))
#define TP_IS_CLIENT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CLIENT))
#define TP_IS_CLIENT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_CLIENT))
#define TP_CLIENT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CLIENT, \
                              TpClientClass))

void tp_client_init_known_interfaces (void);

G_END_DECLS

#include <telepathy-glib/_gen/tp-cli-client.h>

#endif
