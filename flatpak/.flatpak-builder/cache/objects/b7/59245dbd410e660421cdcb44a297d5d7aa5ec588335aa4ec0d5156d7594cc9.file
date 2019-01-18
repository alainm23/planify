/*
 * Interface for channel factories
 *
 * Copyright © 2010 Collabora Ltd.
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

#ifndef __TP_CLIENT_CHANNEL_FACTORY_H__
#define __TP_CLIENT_CHANNEL_FACTORY_H__

#include <glib-object.h>

#include <telepathy-glib/channel.h>

G_BEGIN_DECLS

typedef struct _TpClientChannelFactory TpClientChannelFactory;
typedef struct _TpClientChannelFactoryInterface TpClientChannelFactoryInterface;

struct _TpClientChannelFactoryInterface {
    GTypeInterface parent;

    TpChannel * (* create_channel) (TpClientChannelFactoryInterface *self,
        TpConnection *conn,
        const gchar *path,
        GHashTable *properties,
        GError **error);

    GArray * (* dup_channel_features) (TpClientChannelFactoryInterface *self,
        TpChannel *channel);

    TpChannel *(*obj_create_channel) (TpClientChannelFactory *self,
        TpConnection *conn,
        const gchar *path,
        GHashTable *properties,
        GError **error);

    GArray *(*obj_dup_channel_features) (TpClientChannelFactory *self,
        TpChannel *channel);
};

GType tp_client_channel_factory_get_type (void);

#define TP_TYPE_CLIENT_CHANNEL_FACTORY \
  (tp_client_channel_factory_get_type ())
#define TP_CLIENT_CHANNEL_FACTORY(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CLIENT_CHANNEL_FACTORY, \
                               TpClientChannelFactory))
#define TP_IS_CLIENT_CHANNEL_FACTORY(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CLIENT_CHANNEL_FACTORY))
#define TP_CLIENT_CHANNEL_FACTORY_GET_IFACE(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE ((obj), TP_TYPE_CLIENT_CHANNEL_FACTORY, \
                              TpClientChannelFactoryInterface))

TpChannel *tp_client_channel_factory_create_channel (
    TpClientChannelFactory *self,
    TpConnection *conn,
    const gchar *path,
    GHashTable *properties,
    GError **error);

GArray *tp_client_channel_factory_dup_channel_features (
    TpClientChannelFactory *self,
    TpChannel *channel);

G_END_DECLS

#endif
