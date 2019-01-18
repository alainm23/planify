/*<private_header>*/
/*
 * message-internal.h - Header for TpCMMessage (internal
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

#ifndef __TP_CM_MESSAGE_INTERNAL_H__
#define __TP_CM_MESSAGE_INTERNAL_H__

#include "cm-message.h"

#include <glib.h>

#include "message.h"
#include "message-internal.h"

G_BEGIN_DECLS

typedef struct _TpCMMessagePrivate TpCMMessagePrivate;

struct _TpCMMessageClass
{
    /*<private>*/
    TpMessageClass parent_class;
};

struct _TpCMMessage {
    /*<private>*/
    TpMessage parent;
    TpCMMessagePrivate *priv;

    /* from here down is implementation-specific for TpMessageMixin */

    /* for receiving */
    guint32 incoming_id;

    /* for sending */
    DBusGMethodInvocation *outgoing_context;
    TpMessageSendingFlags outgoing_flags;
    gboolean outgoing_text_api;
};

TpMessage * _tp_cm_message_new_from_parts (TpBaseConnection *conn,
    const GPtrArray *parts);

G_END_DECLS

#endif /* __TP_CM_MESSAGE_INTERNAL_H__ */
