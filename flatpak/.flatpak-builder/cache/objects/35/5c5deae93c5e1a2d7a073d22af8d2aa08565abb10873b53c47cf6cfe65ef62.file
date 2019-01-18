/*
 * cm-message.h - Header for TpCMMessage
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

#ifndef __TP_CM_MESSAGE_H__
#define __TP_CM_MESSAGE_H__


#include <glib.h>

#include <telepathy-glib/base-connection.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/message.h>

G_BEGIN_DECLS

#define TP_TYPE_CM_MESSAGE (tp_cm_message_get_type ())
#define TP_CM_MESSAGE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_CM_MESSAGE, TpCMMessage))
#define TP_CM_MESSAGE_CLASS(obj) (G_TYPE_CHECK_CLASS_CAST ((obj), TP_TYPE_CM_MESSAGE, TpCMMessageClass))
#define TP_IS_CM_MESSAGE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_CM_MESSAGE))
#define TP_IS_CM_MESSAGE_CLASS(obj) (G_TYPE_CHECK_CLASS_TYPE ((obj), TP_TYPE_CM_MESSAGE))
#define TP_CM_MESSAGE_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_CM_MESSAGE, TpCMMessageClass))

typedef struct _TpCMMessage TpCMMessage;
typedef struct _TpCMMessageClass TpCMMessageClass;

GType tp_cm_message_get_type (void);

TpMessage * tp_cm_message_new (TpBaseConnection *connection,
    guint initial_parts);

TpMessage *tp_cm_message_new_text (TpBaseConnection *conn,
    TpHandle sender,
    TpChannelTextMessageType type,
    const gchar *text);

_TP_AVAILABLE_IN_0_16
void tp_cm_message_set_message (TpMessage *self,
    guint part,
    const gchar *key,
    TpMessage *message);
void tp_cm_message_take_message (TpMessage *self,
    guint part,
    const gchar *key,
    TpMessage *message);

TpHandle tp_cm_message_get_sender (TpMessage *self);
void tp_cm_message_set_sender (TpMessage *self,
    TpHandle handle);

#ifndef TP_DISABLE_DEPRECATED
_TP_DEPRECATED
TpMessage *tp_message_new (TpBaseConnection *connection,
    guint initial_parts,
    guint size_hint) G_GNUC_WARN_UNUSED_RESULT;
#endif

G_END_DECLS

#endif /* __TP_CM_MESSAGE_H__ */
