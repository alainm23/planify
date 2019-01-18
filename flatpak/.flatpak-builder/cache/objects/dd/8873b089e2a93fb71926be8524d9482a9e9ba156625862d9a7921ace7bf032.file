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

/**
 * SECTION:client-channel-factory
 * @title: TpClientChannelFactoryInterface
 * @short_description: an interface for client channel factories
 *
 * Client channel factories are used to create channel proxies. An application
 * wanting to use its own #TpChannel subclass has to implement an object
 * implementing the #TpClientChannelFactoryInterface interface.
 *
 * Once a channel has been created by a factory using
 * tp_client_channel_factory_create_channel(), the caller should then prepare
 * on it the channel features returned by
 * tp_client_channel_factory_dup_channel_features() using
 * tp_proxy_prepare_async().
 *
 * Since: 0.13.2
 */

/**
 * TpClientChannelFactory:
 *
 * Opaque typedef representing a #GObject that implements
 * the %TP_TYPE_CLIENT_CHANNEL_FACTORY interface.
 *
 * Since: 0.13.6
 */

/**
 * TpClientChannelFactoryInterface:
 * @parent: the parent
 * @create_channel: obsolete version of @obj_create_channel which does not
 *  receive the object instance as an argument
 * @dup_channel_features: obsolete version of @obj_dup_channel_features which
 *  does not receive the object instance as an argument
 * @obj_create_channel: virtual method used to create channels;
 *  see tp_client_channel_factory_create_channel()
 * @obj_dup_channel_features: virtual method returning channel features that
 *  have to be prepared on newly created channels;
 *  see tp_client_channel_factory_dup_channel_features()
 *
 * Interface for a channel factory
 *
 * Since: 0.13.2
 */

#include "config.h"

#include "telepathy-glib/client-channel-factory.h"

#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CLIENT
#include "telepathy-glib/debug-internal.h"

G_DEFINE_INTERFACE(TpClientChannelFactory, tp_client_channel_factory,
    G_TYPE_OBJECT)

/* Deprecated module can use deprecated APIs */
G_GNUC_BEGIN_IGNORE_DEPRECATIONS

static void
tp_client_channel_factory_default_init (TpClientChannelFactoryInterface *iface)
{
}

/**
 * tp_client_channel_factory_create_channel:
 * @self: a client channel factory
 * @conn: a #TpConnection
 * @path: the object path of the channel
 * @properties: (transfer none) (element-type utf8 GObject.Value):
 * the immutable properties of the channel
 * @error: used to indicate the error if %NULL is returned
 *
 * Function called when a channel need to be created.
 * Implementation can return a subclass of #TpChannel if they need to.
 *
 * Changed in 0.13.6: the function's signature was previously wrong;
 * it expected an object instance as its first parameter, but the type of the
 * parameter was the type of the interface vtable.
 *
 * Returns: (transfer full): a new channel proxy, or %NULL on invalid arguments
 *
 * Since: 0.13.2
 */
TpChannel *
tp_client_channel_factory_create_channel (TpClientChannelFactory *self,
    TpConnection *conn,
    const gchar *path,
    GHashTable *properties,
    GError **error)
{
  TpClientChannelFactoryInterface *iface = TP_CLIENT_CHANNEL_FACTORY_GET_IFACE (
      self);

  g_return_val_if_fail (TP_IS_CLIENT_CHANNEL_FACTORY (self), NULL);
  g_return_val_if_fail (TP_IS_CONNECTION (conn), NULL);
  g_return_val_if_fail (path != NULL, NULL);
  g_return_val_if_fail (properties != NULL, NULL);

  if (iface->obj_create_channel != NULL)
    return iface->obj_create_channel (self, conn, path, properties, error);

  if (iface->create_channel != NULL)
    return iface->create_channel (iface, conn, path, properties, error);

  return tp_channel_new_from_properties (conn, path, properties, error);
}

/**
 * tp_client_channel_factory_dup_channel_features:
 * @self: a client channel factory
 * @channel: a #TpChannel
 *
 * Return a zero terminated #GArray containing the #TpChannel features that
 * should be prepared on @channel.
 *
 * Changed in 0.13.6: the function's signature was previously wrong;
 * it expected an object instance as its first parameter, but the type of the
 * parameter was the type of the interface vtable.
 *
 * Returns: (transfer full) (element-type GQuark): a newly allocated #GArray
 *
 * Since: 0.13.3
 */
GArray *
tp_client_channel_factory_dup_channel_features (
    TpClientChannelFactory *self,
    TpChannel *channel)
{
  TpClientChannelFactoryInterface *iface = TP_CLIENT_CHANNEL_FACTORY_GET_IFACE (
      self);
  GArray *arr;
  GQuark feature = TP_CHANNEL_FEATURE_CORE;

  g_return_val_if_fail (TP_IS_CLIENT_CHANNEL_FACTORY (self), NULL);
  g_return_val_if_fail (TP_IS_CHANNEL (channel), NULL);

  if (iface->obj_dup_channel_features != NULL)
    return iface->obj_dup_channel_features (self, channel);

  if (iface->dup_channel_features != NULL)
    return iface->dup_channel_features (iface, channel);

  arr = g_array_sized_new (TRUE, FALSE, sizeof (GQuark), 1);

  g_array_append_val (arr, feature);

  return arr;
}

G_GNUC_END_IGNORE_DEPRECATIONS
