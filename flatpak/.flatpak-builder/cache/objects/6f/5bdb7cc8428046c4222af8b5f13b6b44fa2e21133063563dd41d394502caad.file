/*
 * Simple client channel factory creating TpChannel
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
 * SECTION:basic-proxy-factory
 * @title: TpBasicProxyFactory
 * @short_description: channel factory creating TpChannel objects
 * @see_also: #TpAutomaticProxyFactory
 *
 * This factory implements the #TpClientChannelFactory interface to create
 * plain #TpChannel objects. Unlike #TpAutomaticProxyFactory, it will
 * not create higher-level subclasses like #TpStreamTubeChannel.
 * The only feature this factory asks to prepare is #TP_CHANNEL_FEATURE_CORE.
 *
 * TpProxy subclasses other than TpChannel are not currently supported.
 *
 * Since: 0.13.2
 */

/**
 * TpBasicProxyFactory:
 *
 * Data structure representing a #TpBasicProxyFactory
 *
 * Since: 0.13.2
 */

/**
 * TpBasicProxyFactoryClass:
 * @parent_class: the parent class
 *
 * The class of a #TpBasicProxyFactory.
 *
 * Since: 0.13.2
 */

#include "config.h"

#include "telepathy-glib/basic-proxy-factory.h"

#include <telepathy-glib/client-channel-factory.h>

#define DEBUG_FLAG TP_DEBUG_CLIENT
#include "telepathy-glib/debug-internal.h"

/* We rely on the default (lack of) implementation of everything */
G_DEFINE_TYPE_WITH_CODE(TpBasicProxyFactory, tp_basic_proxy_factory, G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE (TP_TYPE_CLIENT_CHANNEL_FACTORY, NULL))

static void
tp_basic_proxy_factory_init (TpBasicProxyFactory *self)
{
}

static void
tp_basic_proxy_factory_class_init (TpBasicProxyFactoryClass *cls)
{
}

/**
 * tp_basic_proxy_factory_new:
 *
 * Convenient function to create a new #TpBasicProxyFactory instance.
 *
 * Returns: a new #TpBasicProxyFactory
 *
 * Since: 0.13.2
 * Deprecated: New code should use #TpSimpleClientFactory instead
 */
static TpBasicProxyFactory *
_tp_basic_proxy_factory_new (void)
{
  return g_object_new (TP_TYPE_BASIC_PROXY_FACTORY,
      NULL);
}

TpBasicProxyFactory *
tp_basic_proxy_factory_new (void)
{
  return _tp_basic_proxy_factory_new ();
}

/**
 * tp_basic_proxy_factory_dup:
 *
 * Returns a cached #TpBasicProxyFactory; the same #TpBasicProxyFactory object
 * will be returned by this function repeatedly, as long as at least one
 * reference exists.
 *
 * Returns: (transfer full): a #TpBasicProxyFactory
 *
 * Since: 0.13.2
 * Deprecated: New code should use #TpSimpleClientFactory instead
 */
TpBasicProxyFactory *
tp_basic_proxy_factory_dup (void)
{
  static TpBasicProxyFactory *singleton = NULL;

  if (singleton != NULL)
    return g_object_ref (singleton);

  singleton = _tp_basic_proxy_factory_new ();

  g_object_add_weak_pointer (G_OBJECT (singleton), (gpointer) &singleton);

  return singleton;
}
