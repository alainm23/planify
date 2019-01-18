/*
 * call.c - misc low level API for Call
 *
 * Copyright (C) 2011 Collabora Ltd. <http://www.collabora.co.uk/>
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
 * SECTION:call-misc
 * @title: Misc Call APIs
 * @short_description: Misc generated APISs for Call
 *
 * This contains generated APIs to be used by #TpCallChannel, #TpCallStream,
 * #TpCallContent or telepathy-farstream. Should not be needed for normal
 * clients.
 */

#include "config.h"

#include "telepathy-glib/call-misc.h"
#include "telepathy-glib/errors.h"
#include "telepathy-glib/interfaces.h"
#include "telepathy-glib/proxy-subclass.h"

#include "_gen/tp-cli-call-content-media-description-body.h"
#include "_gen/tp-cli-call-stream-endpoint-body.h"

/**
 * tp_call_stream_endpoint_init_known_interfaces:
 *
 * Ensure that the known interfaces for #TpProxy have been set up.
 * This is done automatically when necessary, but for correct
 * overriding of library interfaces by local extensions, you should
 * call this function before calling
 * tp_proxy_or_subclass_hook_on_interface_add() with first argument
 * %TP_TYPE_PROXY.
 *
 * Since: 0.17.5
 */
void
tp_call_stream_endpoint_init_known_interfaces (void)
{
  static gsize once = 0;

  if (g_once_init_enter (&once))
    {
      GType tp_type = TP_TYPE_PROXY;

      tp_proxy_init_known_interfaces ();
      tp_proxy_or_subclass_hook_on_interface_add (tp_type,
          tp_cli_call_stream_endpoint_add_signals);

      g_once_init_leave (&once, 1);
    }
}

/**
 * tp_call_content_media_description_init_known_interfaces:
 *
 * Ensure that the known interfaces for #TpProxy have been set up.
 * This is done automatically when necessary, but for correct
 * overriding of library interfaces by local extensions, you should
 * call this function before calling
 * tp_proxy_or_subclass_hook_on_interface_add() with first argument
 * %TP_TYPE_PROXY.
 *
 * Since: 0.17.5
 */
void
tp_call_content_media_description_init_known_interfaces (void)
{
  static gsize once = 0;

  if (g_once_init_enter (&once))
    {
      GType tp_type = TP_TYPE_PROXY;

      tp_proxy_init_known_interfaces ();
      tp_proxy_or_subclass_hook_on_interface_add (tp_type,
          tp_cli_call_content_media_description_add_signals);

      g_once_init_leave (&once, 1);
    }
}
