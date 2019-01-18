/*
 * message.h - Header for TpMessage
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

#ifndef __TP_MESSAGE_H__
#define __TP_MESSAGE_H__

#include <telepathy-glib/defs.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/handle.h>

G_BEGIN_DECLS

#define TP_TYPE_MESSAGE (tp_message_get_type ())
#define TP_MESSAGE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_MESSAGE, TpMessage))
#define TP_MESSAGE_CLASS(obj) (G_TYPE_CHECK_CLASS_CAST ((obj), TP_TYPE_MESSAGE, TpMessageClass))
#define TP_IS_MESSAGE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_MESSAGE))
#define TP_IS_MESSAGE_CLASS(obj) (G_TYPE_CHECK_CLASS_TYPE ((obj), TP_TYPE_MESSAGE))
#define TP_MESSAGE_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_MESSAGE, TpMessageClass))

typedef struct _TpMessage TpMessage;
typedef struct _TpMessageClass TpMessageClass;

GType tp_message_get_type (void);

void tp_message_destroy (TpMessage *self);
guint tp_message_count_parts (TpMessage *self);
const GHashTable *tp_message_peek (TpMessage *self, guint part);
_TP_AVAILABLE_IN_0_20
GVariant *tp_message_dup_part (TpMessage *self, guint part);
guint tp_message_append_part (TpMessage *self);
void tp_message_delete_part (TpMessage *self, guint part);

gboolean tp_message_delete_key (TpMessage *self, guint part, const gchar *key);
void tp_message_set_boolean (TpMessage *self, guint part, const gchar *key,
    gboolean b);
void tp_message_set_int32 (TpMessage *self, guint part, const gchar *key,
    gint32 i);
#define tp_message_set_int16(s, p, k, i) \
    tp_message_set_int32 (s, p, k, (gint16) i)
void tp_message_set_int64 (TpMessage *self, guint part, const gchar *key,
    gint64 i);
void tp_message_set_uint32 (TpMessage *self, guint part, const gchar *key,
    guint32 u);
#define tp_message_set_uint16(s, p, k, u) \
    tp_message_set_uint32 (s, p, k, (guint16) u)
void tp_message_set_uint64 (TpMessage *self, guint part, const gchar *key,
    guint64 u);
void tp_message_set_string (TpMessage *self, guint part, const gchar *key,
    const gchar *s);
void tp_message_set_string_printf (TpMessage *self, guint part,
    const gchar *key, const gchar *fmt, ...) G_GNUC_PRINTF (4, 5);
void tp_message_set_bytes (TpMessage *self, guint part, const gchar *key,
    guint len, gconstpointer bytes);
void tp_message_set (TpMessage *self, guint part, const gchar *key,
    const GValue *source);
_TP_AVAILABLE_IN_0_20
void tp_message_set_variant (TpMessage *self, guint part, const gchar *key,
    GVariant *value);

gchar * tp_message_to_text (TpMessage *message,
    TpChannelTextMessageFlags *out_flags) G_GNUC_WARN_UNUSED_RESULT;

#ifndef TP_DISABLE_DEPRECATED
/* Takes a TpCMMessage */
_TP_DEPRECATED_FOR (tp_cm_message_set_sender)
void tp_message_set_handle (TpMessage *self, guint part, const gchar *key,
    TpHandleType handle_type, TpHandle handle_or_0);

_TP_DEPRECATED_FOR (tp_cm_message_take_message)
void tp_message_take_message (TpMessage *self, guint part, const gchar *key,
    TpMessage *message);

_TP_DEPRECATED_FOR (tp_cm_message_set_sender)
void tp_message_ref_handle (TpMessage *self, TpHandleType handle_type,
    TpHandle handle);
#endif

gboolean tp_message_is_mutable (TpMessage *self);

TpChannelTextMessageType tp_message_get_message_type (TpMessage *self);
const gchar *tp_message_get_token (TpMessage *self);
gint64 tp_message_get_sent_timestamp (TpMessage *self);
gint64 tp_message_get_received_timestamp (TpMessage *self);
gboolean tp_message_is_scrollback (TpMessage *self);
gboolean tp_message_is_rescued (TpMessage *self);
const gchar *tp_message_get_supersedes (TpMessage *self);
const gchar *tp_message_get_specific_to_interface (TpMessage *self);
gboolean tp_message_is_delivery_report (TpMessage *self);
_TP_AVAILABLE_IN_0_16
guint32 tp_message_get_pending_message_id (TpMessage *self,
    gboolean *valid);

G_END_DECLS

#endif /* __TP_MESSAGE_H__ */
