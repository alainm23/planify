/*
 * cm-message.c - Source for TpCMMessage
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
 * SECTION:cm-message
 * @title: TpCMMessage
 * @short_description: a message in the Telepathy message interface, CM side
 *
 *  #TpCMMessage is used within connection managers to represent a
 *  message sent or received using the Messages interface.
 *
 * Since: 0.13.9
 */

#include "config.h"

#include "cm-message.h"
#include "cm-message-internal.h"
#include "message-internal.h"

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/util.h>

G_DEFINE_TYPE (TpCMMessage, tp_cm_message, TP_TYPE_MESSAGE)

/**
 * TpCMMessage:
 *
 * Opaque structure representing a message in the Telepathy messages interface
 * (an array of at least one mapping from string to variant, where the first
 * mapping contains message headers and subsequent mappings contain the
 * message body).
 *
 * Since: 0.13.9
 */

struct _TpCMMessagePrivate
{
  TpBaseConnection *connection;
};

static void
tp_cm_message_dispose (GObject *object)
{
  TpCMMessage *self = TP_CM_MESSAGE (object);
  void (*dispose) (GObject *) =
    G_OBJECT_CLASS (tp_cm_message_parent_class)->dispose;

  tp_clear_object (&self->priv->connection);

  if (dispose != NULL)
    dispose (object);
}

static void
tp_cm_message_class_init (TpCMMessageClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  gobject_class->dispose = tp_cm_message_dispose;

  g_type_class_add_private (gobject_class, sizeof (TpCMMessagePrivate));
}

static void
tp_cm_message_init (TpCMMessage *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), TP_TYPE_CM_MESSAGE,
      TpCMMessagePrivate);
}

/**
 * tp_cm_message_new:
 * @connection: a connection on which to reference handles
 * @initial_parts: number of parts to create (at least 1)
 *
 * <!-- nothing more to say -->
 *
 * Returns: a newly allocated message suitable to be passed to
 * tp_cm_message_mixin_take_received()
 *
 * Since: 0.13.9
 */
TpMessage *
tp_cm_message_new (TpBaseConnection *connection,
    guint initial_parts)
{
  TpCMMessage *self;
  TpMessage *msg;
  guint i;

  g_return_val_if_fail (connection != NULL, NULL);

  self = g_object_new (TP_TYPE_CM_MESSAGE,
      NULL);

  msg = (TpMessage *) self;

  /* The first part has already be created */
  for (i = 1; i < initial_parts; i++)
    tp_message_append_part (msg);

  self->priv->connection = g_object_ref (connection);
  self->incoming_id = G_MAXUINT32;
  self->outgoing_context = NULL;

  return msg;
}

/**
 * tp_cm_message_set_message:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @message: another (distinct) message created for the same #TpBaseConnection
 *
 * Set @key in part @part of @self to have @message as an aa{sv} value (that
 * is, an array of Message_Part).
 *
 * Since: 0.15.5
 */
void
tp_cm_message_set_message (TpMessage *self,
    guint part,
    const gchar *key,
    TpMessage *message)
{
  GPtrArray *parts;
  guint i;

  g_return_if_fail (self != NULL);
  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (message != NULL);
  g_return_if_fail (self != message);
  g_return_if_fail (TP_IS_CM_MESSAGE (self));
  g_return_if_fail (TP_IS_CM_MESSAGE (message));

  g_return_if_fail (TP_CM_MESSAGE (self)->priv->connection ==
      TP_CM_MESSAGE (message)->priv->connection);

  parts = g_ptr_array_sized_new (message->parts->len);

  for (i = 0; i < message->parts->len; i++)
    {
      GHashTable *src, *dest;

      src = g_ptr_array_index (message->parts, i);
      dest = g_hash_table_new_full (g_str_hash, g_str_equal,
          g_free, (GDestroyNotify) tp_g_value_slice_free);

      tp_g_hash_table_update (dest, src,
          (GBoxedCopyFunc) g_strdup,
          (GBoxedCopyFunc) tp_g_value_slice_dup);
      g_ptr_array_add (parts, dest);
    }

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key),
      tp_g_value_slice_new_take_boxed (TP_ARRAY_TYPE_MESSAGE_PART_LIST, parts));
}

/**
 * tp_cm_message_take_message:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @message: another (distinct) message created for the same #TpBaseConnection
 *
 * Set @key in part @part of @self to have @message as an aa{sv} value (that
 * is, an array of Message_Part), and take ownership of @message.  The caller
 * should not use @message after passing it to this function.  All handle
 * references owned by @message will subsequently belong to and be released
 * with @self.
 *
 * Since: 0.13.9
 */
void
tp_cm_message_take_message (TpMessage *self,
    guint part,
    const gchar *key,
    TpMessage *message)
{
  g_return_if_fail (self != NULL);
  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (message != NULL);
  g_return_if_fail (self != message);
  g_return_if_fail (TP_IS_CM_MESSAGE (self));
  g_return_if_fail (TP_IS_CM_MESSAGE (message));

  g_return_if_fail (TP_CM_MESSAGE (self)->priv->connection ==
      TP_CM_MESSAGE (message)->priv->connection);

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key),
      tp_g_value_slice_new_take_boxed (TP_ARRAY_TYPE_MESSAGE_PART_LIST,
          message->parts));

  /* Now that @self has stolen @message's parts, replace them with a stub to
   * keep tp_message_destroy happy.
   */
  message->parts = g_ptr_array_sized_new (1);
  tp_message_append_part (message);

  tp_message_destroy (message);
}

/**
 * tp_cm_message_set_sender:
 * @self: a #TpCMMessage
 * @handle: the #TpHandle of the sender of the message
 *
 * Set the sender of @self, i.e. the "message-sender" and
 * "message-sender-id" keys in the header.
 *
 * Since: 0.13.9
 */
void
tp_cm_message_set_sender (TpMessage *self,
    TpHandle handle)
{
  TpCMMessage *cm_msg;
  TpHandleRepoIface *contact_repo;
  const gchar *id;

  g_return_if_fail (TP_IS_CM_MESSAGE (self));
  g_return_if_fail (handle != 0);

  tp_message_set_uint32 (self, 0, "message-sender", handle);

  cm_msg = (TpCMMessage *) self;

  contact_repo = tp_base_connection_get_handles (cm_msg->priv->connection,
      TP_HANDLE_TYPE_CONTACT);

  id = tp_handle_inspect (contact_repo, handle);
  if (id != NULL)
    tp_message_set_string (self, 0, "message-sender-id", id);
}

TpMessage *
_tp_cm_message_new_from_parts (TpBaseConnection *conn,
    const GPtrArray *parts)
{
  TpMessage *self;
  guint i;
  const GHashTable *header;
  TpHandle sender;

  g_return_val_if_fail (parts != NULL, NULL);
  g_return_val_if_fail (parts->len > 0, NULL);

  self = tp_cm_message_new (conn, parts->len);

  for (i = 0; i < parts->len; i++)
    {
      tp_g_hash_table_update (g_ptr_array_index (self->parts, i),
          g_ptr_array_index (parts, i),
          (GBoxedCopyFunc) g_strdup,
          (GBoxedCopyFunc) tp_g_value_slice_dup);
    }

  header = tp_message_peek (self, 0);
  sender = tp_asv_get_uint32 (header, "message-sender", NULL);
  if (sender != 0)
    tp_cm_message_set_sender (self, sender);

  return self;
}

/**
 * tp_cm_message_get_sender:
 * @self: a #TpCMMessage
 *
 * Return the sender of @self, i.e. the "message-sender" key of the header,
 * or 0 if there is no sender.
 *
 * Returns: a %TP_HANDLE_TYPE_CONTACT handle, or 0
 *
 * Since: 0.13.9
 */
TpHandle
tp_cm_message_get_sender (TpMessage *self)
{
  g_return_val_if_fail (TP_IS_CM_MESSAGE (self), 0);
  return tp_asv_get_uint32 (tp_message_peek (self, 0), "message-sender", NULL);
}

/**
 * tp_cm_message_new_text:
 * @conn: a connection
 * @sender: the #TpHandle of the sender of the message
 * @type: the type of message
 * @text: content of the messsage
 *
 * A convenient function to create a new #TpCMMessage having
 * 'text/plain' as 'content-type', @type as 'message-type',
 * @text as 'content' and @sender as its sender.
 *
 * Returns: (transfer full): a newly allocated #TpCMMessage
 *
 * Since: 0.13.10
 */
TpMessage *
tp_cm_message_new_text (TpBaseConnection *conn,
    TpHandle sender,
    TpChannelTextMessageType type,
    const gchar *text)
{
  TpMessage *msg;

  msg = tp_cm_message_new (conn, 2);

  if (sender != 0)
    tp_cm_message_set_sender (msg, sender);

  if (type != TP_CHANNEL_TEXT_MESSAGE_TYPE_NORMAL)
    tp_message_set_uint32 (msg, 0, "message-type", type);

  tp_message_set_string (msg, 1, "content-type", "text/plain");
  tp_message_set_string (msg, 1, "content", text);

  return msg;
}
