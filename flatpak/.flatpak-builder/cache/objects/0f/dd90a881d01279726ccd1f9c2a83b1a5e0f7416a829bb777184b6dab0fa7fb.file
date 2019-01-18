/*
 * client-message.c - Source for TpClientMessage
 * Copyright (C) 2006-2010 Collabora Ltd.
 * Copyright (C) 2006-2008 Nokia Corporation
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
 * SECTION:client-message
 * @title: TpClientMessage
 * @short_description: a message in the Telepathy message interface, client side
 *
 * #TpClientMessage is used within Telepathy clients to represent a
 * message composed by a client, which it will send using the
 * Messages interface.
 * Its subclass #TpSignalledMessage represents messages as signalled by a
 * connection manager.
 *
 * Since: 0.13.9
 */

#include "config.h"

#include "client-message.h"
#include "client-message-internal.h"
#include "message-internal.h"

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/util.h>

/**
 * TpClientMessage:
 *
 * Opaque structure representing a message in the Telepathy messages interface
 * (client side).
 *
 * Since: 0.13.9
 */

G_DEFINE_TYPE (TpClientMessage, tp_client_message, TP_TYPE_MESSAGE)

struct _TpClientMessagePrivate
{
  gpointer unused;
};

static void
tp_client_message_class_init (TpClientMessageClass *klass)
{
}

static void
tp_client_message_init (TpClientMessage *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), TP_TYPE_MESSAGE,
      TpClientMessagePrivate);
}

/**
 * tp_client_message_new:
 *
 * A convenient function to create a new #TpClientMessage
 *
 * Returns: (transfer full): a newly allocated #TpClientMessage having only
 * the header part.
 *
 * Since: 0.13.9
 */
TpMessage *
tp_client_message_new (void)
{
  return g_object_new (TP_TYPE_CLIENT_MESSAGE,
      NULL);
}

/**
 * tp_client_message_new_text:
 * @type: the type of message
 * @text: content of the messsage
 *
 * A convenient function to create a new #TpClientMessage having
 * 'text/plain' as 'content-type', @type as 'message-type' and
 * @text as 'content'.
 *
 * Returns: (transfer full): a newly allocated #TpClientMessage
 *
 * Since: 0.13.9
 */
TpMessage *
tp_client_message_new_text (TpChannelTextMessageType type,
    const gchar *text)
{
  TpMessage *msg;

  msg = g_object_new (TP_TYPE_CLIENT_MESSAGE,
      NULL);

  if (type != TP_CHANNEL_TEXT_MESSAGE_TYPE_NORMAL)
    tp_message_set_uint32 (msg, 0, "message-type", type);

  tp_message_append_part (msg);
  tp_message_set_string (msg, 1, "content-type", "text/plain");
  tp_message_set_string (msg, 1, "content", text);

  return msg;
}
