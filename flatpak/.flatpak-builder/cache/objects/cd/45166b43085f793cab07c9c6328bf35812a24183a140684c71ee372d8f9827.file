/*<private_header>*/
/*
 * object for HandleChannels calls context (internal)
 *
 * Copyright (C) 2009 Collabora Ltd. <http://www.collabora.co.uk/>
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

#ifndef __TP_HANDLE_CHANNELS_CONTEXT_INTERNAL_H__
#define __TP_HANDLE_CHANNELS_CONTEXT_INTERNAL_H__

#include <dbus/dbus-glib.h>

#include <telepathy-glib/account.h>
#include <telepathy-glib/handle-channels-context.h>

G_BEGIN_DECLS

typedef enum
{
  TP_HANDLE_CHANNELS_CONTEXT_STATE_NONE,
  TP_HANDLE_CHANNELS_CONTEXT_STATE_DONE,
  TP_HANDLE_CHANNELS_CONTEXT_STATE_FAILED,
  TP_HANDLE_CHANNELS_CONTEXT_STATE_DELAYED,
} TpHandleChannelsContextState;

struct _TpHandleChannelsContext {
  /*<private>*/
  GObject parent;
  TpHandleChannelsContextPrivate *priv;

  TpAccount *account;
  TpConnection *connection;
  /* array of reffed TpChannel */
  GPtrArray *channels;
  /* array of reffed TpChannelRequest */
  GPtrArray *requests_satisfied;
  guint64 user_action_time;
  GHashTable *handler_info;
};

TpHandleChannelsContext * _tp_handle_channels_context_new (
    TpAccount *account,
    TpConnection *connection,
    GPtrArray *channels,
    GPtrArray *requests_satisfied,
    guint64 user_action_time,
    GHashTable *handler_info,
    DBusGMethodInvocation *dbus_context);

TpHandleChannelsContextState _tp_handle_channels_context_get_state
    (TpHandleChannelsContext *self);

void _tp_handle_channels_context_prepare_async (
    TpHandleChannelsContext *self,
    const GQuark *account_features,
    const GQuark *connection_features,
    const GQuark *channel_features,
    GAsyncReadyCallback callback,
    gpointer user_data);

gboolean _tp_handle_channels_context_prepare_finish (
    TpHandleChannelsContext *self,
    GAsyncResult *result,
    GError **error);

G_END_DECLS

#endif
