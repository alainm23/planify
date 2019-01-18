/*
 * client-message.h - Header for TpClientMessage
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

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_CLIENT_MESSAGE_H__
#define __TP_CLIENT_MESSAGE_H__

#include <glib-object.h>

G_BEGIN_DECLS

#include <telepathy-glib/message.h>

#define TP_TYPE_CLIENT_MESSAGE (tp_client_message_get_type ())
#define TP_CLIENT_MESSAGE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CLIENT_MESSAGE, TpClientMessage))
#define TP_CLIENT_MESSAGE_CLASS(obj) (G_TYPE_CHECK_CLASS_CAST ((obj), TP_TYPE_CLIENT_MESSAGE, TpClientMessageClass))
#define TP_IS_CLIENT_MESSAGE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CLIENT_MESSAGE))
#define TP_IS_CLIENT_MESSAGE_CLASS(obj) (G_TYPE_CHECK_CLASS_TYPE ((obj), TP_TYPE_CLIENT_MESSAGE))
#define TP_CLIENT_MESSAGE_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CLIENT_MESSAGE, TpClientMessageClass))

typedef struct _TpClientMessage TpClientMessage;
typedef struct _TpClientMessageClass TpClientMessageClass;

GType tp_client_message_get_type (void);

TpMessage * tp_client_message_new (void);

TpMessage * tp_client_message_new_text (TpChannelTextMessageType type,
    const gchar *text);

G_END_DECLS

#endif /* __TP_CLIENT_MESSAGE_H__ */
