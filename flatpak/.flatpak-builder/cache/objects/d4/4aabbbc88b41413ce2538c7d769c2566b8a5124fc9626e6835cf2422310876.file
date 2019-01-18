/*
 * exportable-channel.c - A channel usable with the Channel Manager
 *
 * Copyright (C) 2008 Collabora Ltd.
 * Copyright (C) 2008 Nokia Corporation
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
 * SECTION:exportable-channel
 * @title: TpExportableChannel
 * @short_description: interface representing channels with several standard
 *                     properties
 * @see_also: #TpChannelIface, #TpChannelManager, #TpSvcChannel
 *
 * This interface defines a set of channel properties on top of those of
 * #TpChannelIface. It's mainly used by #TpChannelManager to represent the
 * returned and managed channel objects.
 */

/**
 * TpExportableChannel:
 *
 * Opaque typedef representing a channel with several standard properties.
 */

/**
 * TpExportableChannelFunc:
 * @channel: An object implementing the exportable channel interface
 * @user_data: Arbitrary user-supplied data
 *
 * A callback for functions which act on exportable channels.
 */

/**
 * TpExportableChannelIface:
 * @parent: The parent interface
 *
 * The interface for #TpExportableChannel objects.
 */

#include "config.h"

#include "exportable-channel.h"

#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/svc-channel.h>
#include <telepathy-glib/util.h>


static void
exportable_channel_base_init (gpointer klass)
{
  static gboolean initialized = FALSE;

  if (!initialized)
    {
      GParamSpec *param_spec;

      initialized = TRUE;

      /**
       * TpExportableChannel:object-path:
       *
       * The D-Bus object path used for this object on the bus. Read-only
       * except during construction.
       */
      param_spec = g_param_spec_string ("object-path", "D-Bus object path",
          "The D-Bus object path used for this object on the bus.", NULL,
          G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
      g_object_interface_install_property (klass, param_spec);

      /**
       * TpExportableChannel:channel-properties:
       *
       * The D-Bus properties to be announced in the NewChannels signal
       * and in the Channels property, as a map from
       * interface.name.propertyname to GValue.
       *
       * A channel's immutable properties are constant for its lifetime on the
       * bus, so this property should only change when the closed signal is
       * emitted (so that respawned channels can reappear on the bus with
       * different properties).  All of the D-Bus properties mentioned here
       * should be exposed through the D-Bus properties interface; additional
       * (possibly mutable) properties not included here may also be exposed
       * via the D-Bus properties interface.
       *
       * If the channel implementation uses
       * <link linkend="telepathy-glib-dbus-properties-mixin">TpDBusPropertiesMixin</link>,
       * this property can implemented using
       * tp_dbus_properties_mixin_make_properties_hash() as follows:
       *
       * <informalexample><programlisting>
       *  case PROP_CHANNEL_PROPERTIES:
       *    g_value_take_boxed (value,
       *      tp_dbus_properties_mixin_make_properties_hash (object,
       *          // The spec says these properties MUST be included:
       *          TP_IFACE_CHANNEL, "TargetHandle",
       *          TP_IFACE_CHANNEL, "TargetHandleType",
       *          TP_IFACE_CHANNEL, "ChannelType",
       *          TP_IFACE_CHANNEL, "TargetID",
       *          TP_IFACE_CHANNEL, "Requested",
       *          // These aren't mandatory as of spec 0.17.17
       *          // (but they should be):
       *          TP_IFACE_CHANNEL, "InitiatorHandle",
       *          TP_IFACE_CHANNEL, "InitiatorID",
       *          TP_IFACE_CHANNEL, "Interfaces",
       *          // Perhaps your channel has some other immutable properties:
       *          TP_IFACE_CHANNEL_INTERFACE_MESSAGES, "SupportedContentTypes",
       *          // etc.
       *          NULL));
       *    break;
       * </programlisting></informalexample>
       */
      param_spec = g_param_spec_boxed ("channel-properties",
          "Channel properties",
          "The channel properties",
          TP_HASH_TYPE_QUALIFIED_PROPERTY_VALUE_MAP,
          G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
      g_object_interface_install_property (klass, param_spec);

      /**
       * TpExportableChannel:channel-destroyed:
       *
       * If true, the closed signal on the Channel interface indicates that
       * the channel can go away.
       *
       * If false, the closed signal indicates to the channel manager that the
       * channel should appear to go away and be re-created, by emitting Closed
       * followed by NewChannel. (This is to support the "respawning" of  Text
       * channels which are closed with unacknowledged messages.)
       */
      param_spec = g_param_spec_boolean ("channel-destroyed",
          "Destroyed?",
          "If true, the channel has *really* closed, rather than just "
          "appearing to do so",
          FALSE,
          G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
      g_object_interface_install_property (klass, param_spec);
    }
}

GType
tp_exportable_channel_get_type (void)
{
  static GType type = 0;

  if (G_UNLIKELY (type == 0))
    {
      static const GTypeInfo info = {
        sizeof (TpExportableChannelIface),
        exportable_channel_base_init,   /* base_init */
        NULL,   /* base_finalize */
        NULL,   /* class_init */
        NULL,   /* class_finalize */
        NULL,   /* class_data */
        0,
        0,      /* n_preallocs */
        NULL    /* instance_init */
      };

      type = g_type_register_static (G_TYPE_INTERFACE,
          "TpExportableChannel", &info, 0);

      g_type_interface_add_prerequisite (type, TP_TYPE_SVC_CHANNEL);
    }

  return type;
}
