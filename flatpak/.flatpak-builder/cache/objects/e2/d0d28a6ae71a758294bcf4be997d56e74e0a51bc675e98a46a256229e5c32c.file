/*<private_header>*/
/* Deprecated functions still used internally
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

#ifndef __TP_DEPRECATED_INTERNAL_H__
#define __TP_DEPRECATED_INTERNAL_H__

#include <telepathy-glib/account-channel-request.h>
#include <telepathy-glib/base-client.h>
#include <telepathy-glib/channel-request.h>
#include <telepathy-glib/client-channel-factory.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

void _tp_base_client_set_channel_factory (TpBaseClient *self,
    TpClientChannelFactory *factory);

void _tp_account_channel_request_set_channel_factory (
    TpAccountChannelRequest *self, TpClientChannelFactory *factory);

void _tp_channel_request_set_channel_factory (TpChannelRequest *self,
    TpClientChannelFactory *factory);

G_END_DECLS

#endif
