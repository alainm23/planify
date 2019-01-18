/*
 * Proxy for a Telepathy connection - avatar support
 *
 * Copyright © 2007-2010 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright © 2007-2010 Nokia Corporation
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

#include "config.h"

#include "telepathy-glib/connection.h"

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/interfaces.h>

#define DEBUG_FLAG TP_DEBUG_CONNECTION
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/connection-internal.h"
#include "telepathy-glib/proxy-internal.h"

/**
 * TP_CONNECTION_FEATURE_AVATAR_REQUIREMENTS:
 *
 * Expands to a call to a function that returns a #GQuark representing the
 * "avatar-requirements" feature.
 *
 * When this feature is prepared, the avatar requirements of the Connection has
 * been retrieved. Use tp_connection_get_avatar_requirements() to get them once
 * prepared.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.11.4
 */

GQuark
tp_connection_get_feature_quark_avatar_requirements (void)
{
  return g_quark_from_static_string ("tp-connection-feature-avatar-requirements");
}

static void
tp_connection_get_avatar_requirements_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Failed to get avatar requirements properties: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
      goto finally;
    }

  g_assert (self->priv->avatar_requirements == NULL);

  DEBUG ("AVATAR REQUIREMENTS ready");

  self->priv->avatar_requirements = tp_avatar_requirements_new (
      (GStrv) tp_asv_get_strv (properties, "SupportedAvatarMIMETypes"),
      tp_asv_get_uint32 (properties, "MinimumAvatarWidth", NULL),
      tp_asv_get_uint32 (properties, "MinimumAvatarHeight", NULL),
      tp_asv_get_uint32 (properties, "RecommendedAvatarWidth", NULL),
      tp_asv_get_uint32 (properties, "RecommendedAvatarHeight", NULL),
      tp_asv_get_uint32 (properties, "MaximumAvatarWidth", NULL),
      tp_asv_get_uint32 (properties, "MaximumAvatarHeight", NULL),
      tp_asv_get_uint32 (properties, "MaximumAvatarBytes", NULL));

finally:
  g_simple_async_result_complete_in_idle (result);
}

void
_tp_connection_prepare_avatar_requirements_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result;

  g_assert (self->priv->avatar_requirements == NULL);

  result = g_simple_async_result_new ((GObject *) proxy, callback, user_data,
      _tp_connection_prepare_avatar_requirements_async);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CONNECTION_INTERFACE_AVATARS,
      tp_connection_get_avatar_requirements_cb, result, g_object_unref, NULL);
}

/**
 * tp_connection_get_avatar_requirements:
 * @self: a connection
 *
 * To wait for valid avatar requirements, call tp_proxy_prepare_async()
 * with the feature %TP_CONNECTION_FEATURE_AVATAR_REQUIREMENTS.
 *
 * This property cannot change after @self goes to the Connected state.
 *
 * Returns: (transfer none): a #TpAvatarRequirements struct, or %NULL if the
 *  feature is not yet prepared or the connection doesn't have the necessary
 *  properties.
 * Since: 0.11.4
 */
TpAvatarRequirements *
tp_connection_get_avatar_requirements (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);

  return self->priv->avatar_requirements;
}

/**
 * TpAvatarRequirements:
 * @supported_mime_types: An array of supported MIME types (e.g. "image/jpeg")
 *  Clients MAY assume that the first type in this array is preferred
 * @minimum_width: The minimum width in pixels of an avatar, which MAY be 0
 * @minimum_height: The minimum height in pixels of an avatar, which MAY be 0
 * @recommended_width: The recommended width in pixels of an avatar, or 0 if
 *  there is no preferred width.
 * @recommended_height: The recommended height in pixels of an avatar, or 0 if
 *  there is no preferred height
 * @maximum_width: The maximum width in pixels of an avatar on this protocol,
 *  or 0 if there is no limit.
 * @maximum_height: The maximum height in pixels of an avatar, or 0 if there is
 *  no limit.
 * @maximum_bytes: he maximum size in bytes of an avatar, or 0 if there is no
 *  limit.
 *
 * The requirements for setting an avatar on a particular protocol.
 *
 * Since: 0.11.4
 */

/**
 * TP_TYPE_AVATAR_REQUIREMENTS:
 *
 * The boxed type of a #TpAvatarRequirements.
 *
 * Since: 0.11.4
 */

G_DEFINE_BOXED_TYPE (TpAvatarRequirements, tp_avatar_requirements,
    tp_avatar_requirements_copy, tp_avatar_requirements_destroy)

/**
 * tp_avatar_requirements_new:
 * @supported_mime_types: An array of supported MIME types (e.g. "image/jpeg")
 *  Clients MAY assume that the first type in this array is preferred
 * @minimum_width: The minimum width in pixels of an avatar, which MAY be 0
 * @minimum_height: The minimum height in pixels of an avatar, which MAY be 0
 * @recommended_width: The recommended width in pixels of an avatar, or 0 if
 *  there is no preferred width.
 * @recommended_height: The recommended height in pixels of an avatar, or 0 if
 *  there is no preferred height
 * @maximum_width: The maximum width in pixels of an avatar on this protocol,
 *  or 0 if there is no limit.
 * @maximum_height: The maximum height in pixels of an avatar, or 0 if there is
 *  no limit.
 * @maximum_bytes: he maximum size in bytes of an avatar, or 0 if there is no
 *  limit.
 *
 * <!--Returns: says it all-->
 *
 * Returns: a newly allocated #TpAvatarRequirements, free it with
 * tp_avatar_requirements_destroy()
 * Since: 0.11.4
 */
TpAvatarRequirements *
tp_avatar_requirements_new (GStrv supported_mime_types,
                            guint minimum_width,
                            guint minimum_height,
                            guint recommended_width,
                            guint recommended_height,
                            guint maximum_width,
                            guint maximum_height,
                            guint maximum_bytes)
{
  TpAvatarRequirements *self;
  gchar *empty[] = { NULL };

  self = g_slice_new (TpAvatarRequirements);
  self->supported_mime_types =
      g_strdupv (supported_mime_types ? supported_mime_types : empty);
  self->minimum_width = minimum_width;
  self->minimum_height = minimum_height;
  self->recommended_width = recommended_width;
  self->recommended_height = recommended_height;
  self->maximum_width = maximum_width;
  self->maximum_height = maximum_height;
  self->maximum_bytes = maximum_bytes;

  return self;
}

/**
 * tp_avatar_requirements_copy: (skip)
 * @self: a #TpAvatarRequirements
 *
 * <!--Returns: says it all-->
 *
 * Returns: a newly allocated #TpAvatarRequirements, free it with
 * tp_avatar_requirements_destroy()
 * Since: 0.11.4
 */
TpAvatarRequirements *
tp_avatar_requirements_copy (const TpAvatarRequirements *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return tp_avatar_requirements_new (self->supported_mime_types,
      self->minimum_width,
      self->minimum_height,
      self->recommended_width,
      self->recommended_height,
      self->maximum_width,
      self->maximum_height,
      self->maximum_bytes);
}

/**
 * tp_avatar_requirements_destroy: (skip)
 * @self: a #TpAvatarRequirements
 *
 * Free all memory used by the #TpAvatarRequirements.
 *
 * Since: 0.11.4
 */
void
tp_avatar_requirements_destroy (TpAvatarRequirements *self)
{
  g_return_if_fail (self != NULL);

  g_strfreev (self->supported_mime_types);
  g_slice_free (TpAvatarRequirements, self);
}
