/*
 * Factory creating higher level proxy objects
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
 * SECTION:automatic-proxy-factory
 * @title: TpAutomaticProxyFactory
 * @short_description: factory creating higher level proxy objects
 * @see_also: #TpBasicProxyFactory
 *
 * This factory implements the #TpClientChannelFactoryInterface interface to
 * create specialized #TpChannel subclasses.
 *
 * #TpAutomaticProxyFactory will currently create #TpChannel objects
 * as follows:
 *
 * <itemizedlist>
 *   <listitem>
 *     <para>a #TpStreamTubeChannel, if the channel is of type
 *     %TP_IFACE_CHANNEL_TYPE_STREAM_TUBE;</para>
 *   </listitem>
 *   <listitem>
 *     <para>a #TpTextChannel, if the channel is of type
 *     %TP_IFACE_CHANNEL_TYPE_TEXT and implements
 *     %TP_IFACE_CHANNEL_INTERFACE_MESSAGES;</para>
 *   </listitem>
 *   <listitem>
 *     <para>a #TpFileTransferChannel, if the channel is of type
 *     %TP_IFACE_CHANNEL_TYPE_FILE_TRANSFER;</para>
 *   </listitem>
 *   <listitem>
 *     <para>a plain #TpChannel, otherwise</para>
 *   </listitem>
 * </itemizedlist>
 *
 * It is guaranteed that the objects returned by future versions
 * will be either the class that is currently used, or a more specific
 * subclass of that class.
 *
 * This factory asks to prepare the following properties:
 *
 * <itemizedlist>
 *   <listitem>
 *     <para>%TP_CHANNEL_FEATURE_CORE, %TP_CHANNEL_FEATURE_GROUP
 *     and %TP_CHANNEL_FEATURE_PASSWORD for all
 *     type of channels.</para>
 *   </listitem>
 *   <listitem>
 *     <para>%TP_TEXT_CHANNEL_FEATURE_INCOMING_MESSAGES and
 *     TP_TEXT_CHANNEL_FEATURE_SMS for #TpTextChannel</para>
 *   </listitem>
 *   <listitem>
 *     <para>%TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE
 *     for #TpFileTransferChannel</para>
 *   </listitem>
 * </itemizedlist>
 *
 * TpProxy subclasses other than TpChannel are not currently supported.
 *
 * Since: 0.13.2
 */

/**
 * TpAutomaticProxyFactory:
 *
 * Data structure representing a #TpAutomaticProxyFactory
 *
 * Since: 0.13.2
 */

/**
 * TpAutomaticProxyFactoryClass:
 * @parent_class: the parent class
 *
 * The class of a #TpAutomaticProxyFactory.
 *
 * Since: 0.13.2
 */

#include "config.h"

#include "telepathy-glib/automatic-proxy-factory.h"

#include <telepathy-glib/client-channel-factory.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/stream-tube-channel.h>
#include <telepathy-glib/text-channel.h>
#include <telepathy-glib/file-transfer-channel.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CLIENT
#include "telepathy-glib/debug-internal.h"

static void client_proxy_factory_iface_init (gpointer, gpointer);

G_DEFINE_TYPE_WITH_CODE(TpAutomaticProxyFactory,
    tp_automatic_proxy_factory, G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE (TP_TYPE_CLIENT_CHANNEL_FACTORY,
      client_proxy_factory_iface_init))

/* Deprecated module can use deprecated APIs */
G_GNUC_BEGIN_IGNORE_DEPRECATIONS

static void
tp_automatic_proxy_factory_init (TpAutomaticProxyFactory *self)
{
}

static void
tp_automatic_proxy_factory_class_init (TpAutomaticProxyFactoryClass *cls)
{
}

static TpChannel *
tp_automatic_proxy_factory_create_channel_impl (
    TpConnection *conn,
    const gchar *path,
    GHashTable *properties,
    GError **error)
{
  const gchar *chan_type;

  chan_type = tp_asv_get_string (properties, TP_PROP_CHANNEL_CHANNEL_TYPE);

  if (!tp_strdiff (chan_type, TP_IFACE_CHANNEL_TYPE_STREAM_TUBE))
    {
      return TP_CHANNEL (tp_stream_tube_channel_new (conn, path, properties,
            error));
    }
  else if (!tp_strdiff (chan_type, TP_IFACE_CHANNEL_TYPE_TEXT))
    {
      /* Create a TpTextChannel only if the channel supports Messages */
      const gchar * const * interfaces;

      interfaces = tp_asv_get_strv (properties, TP_PROP_CHANNEL_INTERFACES);

      if (tp_strv_contains (interfaces, TP_IFACE_CHANNEL_INTERFACE_MESSAGES))
        return TP_CHANNEL (tp_text_channel_new (conn, path, properties,
              error));

      DEBUG ("channel %s doesn't implement Messages so we can't create "
          "a TpTextChannel", path);
    }
  else if (!tp_strdiff (chan_type, TP_IFACE_CHANNEL_TYPE_FILE_TRANSFER))
    {
      return TP_CHANNEL (tp_file_transfer_channel_new (conn, path, properties,
            error));
    }

  return tp_channel_new_from_properties (conn, path, properties, error);
}

static TpChannel *
tp_automatic_proxy_factory_create_channel (
    TpClientChannelFactoryInterface *iface G_GNUC_UNUSED,
    TpConnection *conn,
    const gchar *path,
    GHashTable *properties,
    GError **error)
{
  return tp_automatic_proxy_factory_create_channel_impl (conn, path,
      properties, error);
}

static TpChannel *
tp_automatic_proxy_factory_obj_create_channel (
    TpClientChannelFactory *self G_GNUC_UNUSED,
    TpConnection *conn,
    const gchar *path,
    GHashTable *properties,
    GError **error)
{
  return tp_automatic_proxy_factory_create_channel_impl (conn, path,
      properties, error);
}

static GArray *
tp_automatic_proxy_factory_dup_channel_features_impl (TpChannel *channel)
{
  GArray *features;
  GQuark feature;

  features = g_array_sized_new (TRUE, FALSE, sizeof (GQuark), 2);

  feature = TP_CHANNEL_FEATURE_CORE;
  g_array_append_val (features, feature);

  feature = TP_CHANNEL_FEATURE_GROUP;
  g_array_append_val (features, feature);

  feature = TP_CHANNEL_FEATURE_PASSWORD;
  g_array_append_val (features, feature);

  if (TP_IS_TEXT_CHANNEL (channel))
    {
      feature = TP_TEXT_CHANNEL_FEATURE_INCOMING_MESSAGES;
      g_array_append_val (features, feature);

      feature = TP_TEXT_CHANNEL_FEATURE_SMS;
      g_array_append_val (features, feature);
    }
  else if (TP_IS_FILE_TRANSFER_CHANNEL (channel))
    {
      feature = TP_FILE_TRANSFER_CHANNEL_FEATURE_CORE;
      g_array_append_val (features, feature);
    }

  return features;
}

static GArray *
tp_automatic_proxy_factory_obj_dup_channel_features (
    TpClientChannelFactory *self G_GNUC_UNUSED,
    TpChannel *channel)
{
  return tp_automatic_proxy_factory_dup_channel_features_impl (channel);
}

static GArray *
tp_automatic_proxy_factory_dup_channel_features (
    TpClientChannelFactoryInterface *iface G_GNUC_UNUSED,
    TpChannel *channel)
{
  return tp_automatic_proxy_factory_dup_channel_features_impl (channel);
}

static void
client_proxy_factory_iface_init (gpointer g_iface,
    gpointer unused G_GNUC_UNUSED)
{
  TpClientChannelFactoryInterface *iface = g_iface;

  iface->create_channel = tp_automatic_proxy_factory_create_channel;
  iface->dup_channel_features = tp_automatic_proxy_factory_dup_channel_features;
  iface->obj_create_channel = tp_automatic_proxy_factory_obj_create_channel;
  iface->obj_dup_channel_features = tp_automatic_proxy_factory_obj_dup_channel_features;
}

/**
 * tp_automatic_proxy_factory_new:
 *
 * Convenient function to create a new #TpAutomaticProxyFactory instance.
 *
 * Returns: a new #TpAutomaticProxyFactory
 *
 * Since: 0.13.2
 * Deprecated: New code should use #TpAutomaticClientFactory instead
 */
static TpAutomaticProxyFactory *
_tp_automatic_proxy_factory_new (void)
{
  return g_object_new (TP_TYPE_AUTOMATIC_PROXY_FACTORY,
      NULL);
}

TpAutomaticProxyFactory *
tp_automatic_proxy_factory_new (void)
{
  return _tp_automatic_proxy_factory_new ();
}

/**
 * tp_automatic_proxy_factory_dup:
 *
 * Returns a cached #TpAutomaticProxyFactory; the same
 * #TpAutomaticProxyFactory object will be returned by this function repeatedly,
 * as long as at least one reference exists.
 *
 * Returns: (transfer full): a #TpAutomaticProxyFactory
 *
 * Since: 0.13.2
 * Deprecated: New code should use #TpAutomaticClientFactory instead
 */
TpAutomaticProxyFactory *
tp_automatic_proxy_factory_dup (void)
{
  static TpAutomaticProxyFactory *singleton = NULL;

  if (singleton != NULL)
    return g_object_ref (singleton);

  singleton = _tp_automatic_proxy_factory_new ();

  g_object_add_weak_pointer (G_OBJECT (singleton), (gpointer) &singleton);

  return singleton;
}

G_GNUC_END_IGNORE_DEPRECATIONS
