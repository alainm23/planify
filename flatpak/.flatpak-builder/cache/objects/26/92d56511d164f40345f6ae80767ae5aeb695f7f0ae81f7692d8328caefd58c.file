/*
 * message-mixin.h - Header for TpMessageMixin
 * Copyright (C) 2006-2008 Collabora Ltd.
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

#ifndef TP_MESSAGE_MIXIN_H
#define TP_MESSAGE_MIXIN_H

#include <telepathy-glib/base-connection.h>
#include <telepathy-glib/cm-message.h>
#include <telepathy-glib/handle-repo.h>
#include <telepathy-glib/message.h>
#include <telepathy-glib/svc-channel.h>
#include <telepathy-glib/util.h>

G_BEGIN_DECLS

typedef struct _TpMessageMixin TpMessageMixin;
typedef struct _TpMessageMixinPrivate TpMessageMixinPrivate;

struct _TpMessageMixin {
  /*<private>*/
  TpMessageMixinPrivate *priv;
};

void tp_message_mixin_get_dbus_property (GObject *object, GQuark interface,
    GQuark name, GValue *value, gpointer unused);

/* Receiving */

guint tp_message_mixin_take_received (GObject *object, TpMessage *message);

gboolean tp_message_mixin_has_pending_messages (GObject *object,
    TpHandle *first_sender);

void tp_message_mixin_set_rescued (GObject *obj);

void tp_message_mixin_clear (GObject *obj);

/* Sending */

typedef void (*TpMessageMixinSendImpl) (GObject *object,
    TpMessage *message, TpMessageSendingFlags flags);

void tp_message_mixin_sent (GObject *object,
    TpMessage *message, TpMessageSendingFlags flags,
    const gchar *token, const GError *error);

void tp_message_mixin_implement_sending (GObject *object,
    TpMessageMixinSendImpl send, guint n_types,
    const TpChannelTextMessageType *types,
    TpMessagePartSupportFlags message_part_support_flags,
    TpDeliveryReportingSupportFlags delivery_reporting_support_flags,
    const gchar * const * supported_content_types);

/* ChatState */

typedef gboolean (*TpMessageMixinSendChatStateImpl) (GObject *object,
    TpChannelChatState state,
    GError **error);

_TP_AVAILABLE_IN_0_20
void tp_message_mixin_change_chat_state (GObject *object,
    TpHandle member,
    TpChannelChatState state);

_TP_AVAILABLE_IN_0_20
void tp_message_mixin_implement_send_chat_state (GObject *object,
    TpMessageMixinSendChatStateImpl send_chat_state);

_TP_AVAILABLE_IN_0_20
void tp_message_mixin_maybe_send_gone (GObject *object);

/* Initialization */
void tp_message_mixin_text_iface_init (gpointer g_iface, gpointer iface_data);
void tp_message_mixin_messages_iface_init (gpointer g_iface,
    gpointer iface_data);
void tp_message_mixin_chat_state_iface_init (gpointer g_iface,
    gpointer iface_data);

void tp_message_mixin_init (GObject *obj, gsize offset,
    TpBaseConnection *connection);
void tp_message_mixin_init_dbus_properties (GObjectClass *cls);
void tp_message_mixin_finalize (GObject *obj);

G_END_DECLS

#endif
