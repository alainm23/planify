/*
 * Proxy for a Telepathy connection - aliasing support
 *
 * Copyright © 2011 Collabora Ltd. <http://www.collabora.co.uk/>
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
 * TP_CONNECTION_FEATURE_ALIASING:
 *
 * Expands to a call to a function that returns a #GQuark representing the
 * "aliasing" feature.
 *
 * This feature needs to be prepared in order to use
 * tp_connection_can_set_contact_alias().
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.17.3
 */
GQuark
tp_connection_get_feature_quark_aliasing (void)
{
  return g_quark_from_static_string ("tp-connection-feature-aliasing");
}

/**
 * tp_connection_can_set_contact_alias:
 * @self: a #TpConnection
 *
 * Check if the user can set aliases on his contacts.
 * TP_CONNECTION_FEATURE_ALIASING needs to be prepared for this function to
 * return a meaningful value.
 *
 * Returns: %TRUE if the aliases of contacts on @self
 * may be changed by the user of the service, not just by the
 * contacts themselves; %FALSE otherwise.
 * Since: 0.17.3
 */
gboolean
tp_connection_can_set_contact_alias (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  return (self->priv->alias_flags & TP_CONNECTION_ALIAS_FLAG_USER_SET) != 0;
}

static void
get_alias_flag_cb (TpConnection *self,
    TpConnectionAliasFlags flags,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Failed to get AliasFlag : %s", error->message);
      g_simple_async_result_set_from_error (result, error);
      goto finally;
    }

  self->priv->alias_flags = flags;

finally:
  g_simple_async_result_complete_in_idle (result);
}

void
_tp_connection_prepare_aliasing_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result;

  g_assert (self->priv->alias_flags == 0);

  result = g_simple_async_result_new ((GObject *) proxy, callback, user_data,
      _tp_connection_prepare_aliasing_async);

  tp_cli_connection_interface_aliasing_call_get_alias_flags (self, -1,
      get_alias_flag_cb, result, g_object_unref, G_OBJECT (self));
}
