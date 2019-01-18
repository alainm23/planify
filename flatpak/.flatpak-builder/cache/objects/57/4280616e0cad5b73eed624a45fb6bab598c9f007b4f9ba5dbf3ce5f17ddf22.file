/*
 * text-mixin.c - Source for TpTextMixin
 * Copyright (C) 2006, 2007 Collabora Ltd.
 * Copyright (C) 2006, 2007 Nokia Corporation
 *   @author Ole Andre Vadla Ravnaas <ole.andre.ravnaas@collabora.co.uk>
 *   @author Robert McQueen <robert.mcqueen@collabora.co.uk>
 *   @author Senko Rasic <senko@senko.net>
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
 * SECTION:text-mixin
 * @title: TpTextMixin
 * @short_description: a mixin implementation of the text channel type
 * @see_also: #TpSvcChannelTypeText
 *
 * This mixin can be added to a channel GObject class to implement the
 * text channel type in a general way. It implements the pending message
 * queue and GetMessageTypes, so the implementation should only need to
 * implement Send.
 *
 * To use the text mixin, include a #TpTextMixinClass somewhere in your
 * class structure and a #TpTextMixin somewhere in your instance structure,
 * and call tp_text_mixin_class_init() from your class_init function,
 * tp_text_mixin_init() from your init function or constructor, and
 * tp_text_mixin_finalize() from your dispose or finalize function.
 *
 * To use the text mixin as the implementation of
 * #TpSvcChannelTypeText, in the function you pass to G_IMPLEMENT_INTERFACE,
 * you should first call tp_text_mixin_iface_init(), then call
 * tp_svc_channel_type_text_implement_send() to register your implementation
 * of the Send method.
 *
 * Deprecated: Use #TpMessageMixin instead.
 */

#include "config.h"

#include <telepathy-glib/text-mixin.h>

#include <dbus/dbus-glib.h>
#include <string.h>

#include <telepathy-glib/enums.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/gtypes.h>

#define DEBUG_FLAG TP_DEBUG_IM

#include "debug-internal.h"

/* Deprecated module can use deprecated APIs */
G_GNUC_BEGIN_IGNORE_DEPRECATIONS

struct _TpTextMixinPrivate
{
    TpHandleRepoIface *contacts_repo;
    guint recv_id;
    gboolean message_lost;

    GQueue *pending;

    GArray *msg_types;
};

/* pending message */

/*
 * _PendingMessage:
 * @id: The message ID
 * @timestamp: The Unix time at which the message was received
 * @sender: The contact handle of the sender
 * @type: The message type
 * @text: The message itself
 * @flags: The message's flags
 *
 * Represents a message in the pending messages queue.
 */
typedef struct
{
    guint id;
    guint timestamp;
    TpHandle sender;
    TpChannelTextMessageType type;
    char *text;
    guint flags;
} _PendingMessage;

/**
 * tp_text_mixin_class_get_offset_quark:
 *
 * <!--no documentation beyond Returns: needed-->
 *
 * Returns: the quark used for storing mixin offset on a GObjectClass
 * Deprecated: Use #TpMessageMixin instead.
 */
GQuark
tp_text_mixin_class_get_offset_quark ()
{
  static GQuark offset_quark = 0;

  if (G_UNLIKELY (offset_quark == 0))
    offset_quark = g_quark_from_static_string ("TpTextMixinClassOffsetQuark");

  return offset_quark;
}

/**
 * tp_text_mixin_get_offset_quark:
 *
 * <!--no documentation beyond Returns: needed-->
 *
 * Returns: the quark used for storing mixin offset on a GObject
 * Deprecated: Use #TpMessageMixin instead.
 */
GQuark
tp_text_mixin_get_offset_quark ()
{
  static GQuark offset_quark = 0;

  if (G_UNLIKELY (offset_quark == 0))
    offset_quark = g_quark_from_static_string ("TpTextMixinOffsetQuark");

  return offset_quark;
}


/**
 * tp_text_mixin_class_init:
 * @obj_cls: The class of the implementation that uses this mixin
 * @offset: The byte offset of the TpTextMixinClass within the class structure
 *
 * Initialize the text mixin. Should be called from the implementation's
 * class_init function like so:
 *
 * <informalexample><programlisting>
 * tp_text_mixin_class_init ((GObjectClass *) klass,
 *                           G_STRUCT_OFFSET (SomeObjectClass, text_mixin));
 * </programlisting></informalexample>
 *
 * Deprecated: Use #TpMessageMixin instead.
 */

void
tp_text_mixin_class_init (GObjectClass *obj_cls, glong offset)
{
  TpTextMixinClass *mixin_cls;

  g_assert (G_IS_OBJECT_CLASS (obj_cls));

  g_type_set_qdata (G_OBJECT_CLASS_TYPE (obj_cls),
      TP_TEXT_MIXIN_CLASS_OFFSET_QUARK,
      GINT_TO_POINTER (offset));

  mixin_cls = TP_TEXT_MIXIN_CLASS (obj_cls);
  g_return_if_fail (mixin_cls != NULL);
}


/**
 * tp_text_mixin_init:
 * @obj: An instance of the implementation that uses this mixin
 * @offset: The byte offset of the TpTextMixin within the object structure
 * @contacts_repo: The connection's %TP_HANDLE_TYPE_CONTACT repository
 *
 * Initialize the text mixin. Should be called from the implementation's
 * instance init function like so:
 *
 * <informalexample><programlisting>
 * tp_text_mixin_init ((GObject *) self,
 *                     G_STRUCT_OFFSET (SomeObject, text_mixin),
 *                     self->contact_repo);
 * </programlisting></informalexample>
 *
 * Deprecated: Use tp_message_mixin_init() instead.
 */
void
tp_text_mixin_init (GObject *obj,
                    glong offset,
                    TpHandleRepoIface *contacts_repo)
{
  TpTextMixin *mixin;

  g_assert (G_IS_OBJECT (obj));

  g_type_set_qdata (G_OBJECT_TYPE (obj),
                    TP_TEXT_MIXIN_OFFSET_QUARK,
                    GINT_TO_POINTER (offset));

  mixin = TP_TEXT_MIXIN (obj);

  mixin->priv = g_slice_new0 (TpTextMixinPrivate);

  mixin->priv->pending = g_queue_new ();
  mixin->priv->contacts_repo = contacts_repo;
  mixin->priv->recv_id = 0;
  mixin->priv->msg_types = g_array_sized_new (FALSE, FALSE, sizeof (guint), 4);

  mixin->priv->message_lost = FALSE;
}

/**
 * tp_text_mixin_set_message_types:
 * @obj: An object with this mixin
 * @...: guints representing members of #TpChannelTextMessageType, terminated
 *  by G_MAXUINT
 *
 * Set the supported message types.
 *
 * Deprecated: Use #TpMessageMixin instead.
 */
void
tp_text_mixin_set_message_types (GObject *obj,
                                 ...)
{
  TpTextMixin *mixin = TP_TEXT_MIXIN (obj);
  va_list args;
  guint type;

  va_start (args, obj);

  while ((type = va_arg (args, guint)) != G_MAXUINT)
    g_array_append_val (mixin->priv->msg_types, type);

  va_end (args);
}

static inline _PendingMessage *
_pending_new0 (void)
{
  return g_slice_new0 (_PendingMessage);
}

/**
 * _pending_free
 *
 * Free up a _PendingMessage struct.
 */
static void
_pending_free (_PendingMessage *msg,
               TpHandleRepoIface *contacts_repo)
{
  g_free (msg->text);
  tp_handle_unref (contacts_repo, msg->sender);
  g_slice_free (_PendingMessage, msg);
}

/**
 * tp_text_mixin_finalize:
 * @obj: An object with this mixin.
 *
 * Free resources held by the text mixin.
 *
 * Deprecated: Use tp_message_mixin_finalize() instead.
 */
void
tp_text_mixin_finalize (GObject *obj)
{
  TpTextMixin *mixin = TP_TEXT_MIXIN (obj);

  DEBUG ("%p", obj);

  /* free any data held directly by the object here */

  tp_text_mixin_clear (obj);

  g_queue_free (mixin->priv->pending);

  g_array_unref (mixin->priv->msg_types);

  g_slice_free (TpTextMixinPrivate, mixin->priv);
}

/**
 * tp_text_mixin_receive_with_flags:
 * @obj: An object with the text mixin
 * @type: The type of message received from the underlying protocol
 * @sender: The handle of the message sender
 * @timestamp: The time the message was received
 * @text: The text of the message
 * @flags: the message's flags
 *
 * Add a message to the pending queue and emit Received.
 *
 * Returns: %TRUE on success; %FALSE if the message was lost due to the memory
 * limit.
 *
 * Deprecated: Use tp_message_mixin_take_received() instead.
 */
gboolean
tp_text_mixin_receive_with_flags (GObject *obj,
                                  TpChannelTextMessageType type,
                                  TpHandle sender,
                                  time_t timestamp,
                                  const char *text,
                                  TpChannelTextMessageFlags flags)
{
  TpTextMixin *mixin = TP_TEXT_MIXIN (obj);
  _PendingMessage *msg;
  size_t len;

  msg = _pending_new0 ();
  msg->sender = tp_handle_ref (mixin->priv->contacts_repo, sender);
  /* FIXME: we don't check for overflow, so in highly pathological cases we
   * might end up with multiple messages with the same ID */
  msg->id = mixin->priv->recv_id++;
  msg->timestamp = timestamp;
  msg->type = type;
  msg->flags = flags;

  len = strlen (text);
  msg->text = g_try_malloc (len + 1);

  if (msg->text == NULL)
    {
      DEBUG ("unable to copy message, giving up");

      if (!mixin->priv->message_lost)
        {
          tp_svc_channel_type_text_emit_lost_message (obj);
          mixin->priv->message_lost = TRUE;
        }

      _pending_free (msg, mixin->priv->contacts_repo);

      return FALSE;
    }

  g_strlcpy (msg->text, text, len + 1);

  g_queue_push_tail (mixin->priv->pending, msg);

  tp_svc_channel_type_text_emit_received (obj,
                 msg->id,
                 msg->timestamp,
                 msg->sender,
                 msg->type,
                 msg->flags,
                 msg->text);

  DEBUG ("queued message %u", msg->id);

  mixin->priv->message_lost = FALSE;

  return TRUE;
}


/**
 * tp_text_mixin_receive:
 * @obj: An object with the text mixin
 * @type: The type of message received from the underlying protocol
 * @sender: The handle of the message sender
 * @timestamp: The time the message was received
 * @text: The text of the message
 *
 * Add a message to the pending queue and emit Received. Exactly equivalent
 * to tp_text_mixin_receive_with_flags() with @flags == 0.
 *
 * Returns: %TRUE on success; %FALSE if the message was lost due to the memory
 * limit.
 *
 * Deprecated: Use tp_message_mixin_take_received() instead.
 */
gboolean
tp_text_mixin_receive (GObject *obj,
                       TpChannelTextMessageType type,
                       TpHandle sender,
                       time_t timestamp,
                       const char *text)
{
  return tp_text_mixin_receive_with_flags (obj, type, sender, timestamp, text,
      0);
}

static gint
compare_pending_message (gconstpointer haystack,
                         gconstpointer needle)
{
  _PendingMessage *msg = (_PendingMessage *) haystack;
  guint id = GPOINTER_TO_INT (needle);

  return (msg->id != id);
}

/**
 * tp_text_mixin_acknowledge_pending_messages:
 * @obj: An object with this mixin
 * @ids: An array of guint representing message IDs
 * @error: Used to return a pointer to a GError detailing any error
 *         that occurred, D-Bus will throw the error only if this
 *         function returns false.
 *
 * Implements D-Bus method AcknowledgePendingMessages
 * on interface org.freedesktop.Telepathy.Channel.Type.Text
 *
 * Returns: TRUE if successful, FALSE if an error was thrown.
 *
 * Deprecated: Use #TpMessageMixin instead.
 */
gboolean
tp_text_mixin_acknowledge_pending_messages (GObject *obj,
                                            const GArray *ids,
                                            GError **error)
{
  TpTextMixin *mixin = TP_TEXT_MIXIN (obj);
  GList **nodes;
  _PendingMessage *msg;
  guint i;

  nodes = g_new (GList *, ids->len);

  for (i = 0; i < ids->len; i++)
    {
      guint id = g_array_index (ids, guint, i);

      nodes[i] = g_queue_find_custom (mixin->priv->pending,
                                      GINT_TO_POINTER (id),
                                      compare_pending_message);

      if (nodes[i] == NULL)
        {
          DEBUG ("invalid message id %u", id);

          g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
              "invalid message id %u", id);

          g_free (nodes);
          return FALSE;
        }
    }

  for (i = 0; i < ids->len; i++)
    {
      msg = (_PendingMessage *) nodes[i]->data;

      DEBUG ("acknowleding message id %u", msg->id);

      g_queue_remove (mixin->priv->pending, msg);

      _pending_free (msg, mixin->priv->contacts_repo);
    }

  g_free (nodes);
  return TRUE;
}

static void
tp_text_mixin_acknowledge_pending_messages_async (TpSvcChannelTypeText *iface,
                                                  const GArray *ids,
                                                  DBusGMethodInvocation *context)
{
  GError *error = NULL;

  if (tp_text_mixin_acknowledge_pending_messages (G_OBJECT (iface), ids,
      &error))
    {
      tp_svc_channel_type_text_return_from_acknowledge_pending_messages (
          context);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

/**
 * tp_text_mixin_list_pending_messages:
 * @obj: An object with this mixin
 * @clear: If %TRUE, delete the pending messages from the queue
 * @ret: Used to return a pointer to a new GPtrArray of D-Bus structures
 * @error: Used to return a pointer to a GError detailing any error
 *         that occurred, D-Bus will throw the error only if this
 *         function returns false.
 *
 * Implements D-Bus method ListPendingMessages
 * on interface org.freedesktop.Telepathy.Channel.Type.Text
 *
 * Returns: TRUE if successful, FALSE if an error was thrown.
 *
 * Deprecated: Use #TpMessageMixin instead.
 */
gboolean
tp_text_mixin_list_pending_messages (GObject *obj,
                                     gboolean clear,
                                     GPtrArray **ret,
                                     GError **error)
{
  TpTextMixin *mixin = TP_TEXT_MIXIN (obj);
  GType pending_type = TP_STRUCT_TYPE_PENDING_TEXT_MESSAGE;
  guint count;
  GPtrArray *messages;
  GList *cur;

  count = g_queue_get_length (mixin->priv->pending);
  messages = g_ptr_array_sized_new (count);

  for (cur = g_queue_peek_head_link (mixin->priv->pending);
       cur != NULL;
       cur = cur->next)
    {
      _PendingMessage *msg = cur->data;
      GValue val = { 0, };

      g_value_init (&val, pending_type);
      g_value_take_boxed (&val,
          dbus_g_type_specialized_construct (pending_type));
      dbus_g_type_struct_set (&val,
          0, msg->id,
          1, msg->timestamp,
          2, msg->sender,
          3, msg->type,
          4, msg->flags,
          5, msg->text,
          G_MAXUINT);

      g_ptr_array_add (messages, g_value_get_boxed (&val));
    }

  if (clear)
    {
      DEBUG ("WARNING: ListPendingMessages(clear=TRUE) is deprecated");
      tp_text_mixin_clear (obj);
    }

  *ret = messages;

  return TRUE;
}

static void
tp_text_mixin_list_pending_messages_async (TpSvcChannelTypeText *iface,
                                           gboolean clear,
                                           DBusGMethodInvocation *context)
{
  GPtrArray *ret;
  GError *error = NULL;

  if (tp_text_mixin_list_pending_messages (G_OBJECT (iface), clear, &ret,
      &error))
    {
      guint i;

      tp_svc_channel_type_text_return_from_list_pending_messages (
          context, ret);

      for (i = 0; i < ret->len; i++)
        tp_value_array_free (g_ptr_array_index (ret, i));

      g_ptr_array_unref (ret);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

/**
 * tp_text_mixin_get_message_types:
 * @obj: An object with this mixin
 * @ret: A pointer to where a GArray of guint will be placed on success
 * @error: A pointer to where an error will be placed on failure
 *
 * Return a newly allocated GArray of guint, representing message types
 * taken from #TpChannelTextMessageType, through @ret.
 *
 * Returns: %TRUE on success
 *
 * Deprecated: Use #TpMessageMixin instead.
 */
gboolean
tp_text_mixin_get_message_types (GObject *obj,
                                 GArray **ret,
                                 GError **error)
{
  TpTextMixin *mixin = TP_TEXT_MIXIN (obj);
  guint i;

  *ret = g_array_sized_new (FALSE, FALSE, sizeof (guint),
                            mixin->priv->msg_types->len);

  for (i = 0; i < mixin->priv->msg_types->len; i++)
    {
      g_array_append_val (*ret, g_array_index (mixin->priv->msg_types, guint,
            i));
    }

  return TRUE;
}


static void
tp_text_mixin_get_message_types_async (TpSvcChannelTypeText *iface,
                                       DBusGMethodInvocation *context)
{
  TpTextMixin *mixin = TP_TEXT_MIXIN (iface);

  tp_svc_channel_type_text_return_from_get_message_types (context,
      mixin->priv->msg_types);
}

/**
 * tp_text_mixin_clear:
 * @obj: An object with this mixin
 *
 * Clear the pending message queue, deleting all messages.
 *
 * Deprecated: Use tp_message_mixin_clear() instead.
 */
void
tp_text_mixin_clear (GObject *obj)
{
  TpTextMixin *mixin = TP_TEXT_MIXIN (obj);
  _PendingMessage *msg;

  while ((msg = g_queue_pop_head (mixin->priv->pending)) != NULL)
    {
      _pending_free (msg, mixin->priv->contacts_repo);
    }
}

/**
 * tp_text_mixin_has_pending_messages:
 * @obj: An object with this mixin
 * @first_sender: If not %NULL, used to store the sender of the oldest pending
 *  message
 *
 * Return whether the channel @obj has unacknowledged messages. If so, and
 * @first_sender is not %NULL, the handle of the sender of the first message
 * is placed in it, without incrementing the handle's reference count.
 *
 * Returns: %TRUE if there are pending messages
 *
 * Deprecated: Use tp_message_mixin_has_pending_messages() instead.
 */
gboolean
tp_text_mixin_has_pending_messages (GObject *obj,
                                    TpHandle *first_sender)
{
  TpTextMixin *mixin = TP_TEXT_MIXIN (obj);
  _PendingMessage *msg = g_queue_peek_head (mixin->priv->pending);

  if (msg != NULL && first_sender != NULL)
    {
      *first_sender = msg->sender;
    }

  return (msg != NULL);
}

/**
 * tp_text_mixin_set_rescued:
 * @obj: An object with this mixin
 *
 * Mark all pending messages as having been "rescued" from a channel that
 * previously closed.
 *
 * Deprecated: Use tp_message_mixin_set_rescued() instead.
 */
void
tp_text_mixin_set_rescued (GObject *obj)
{
  TpTextMixin *mixin = TP_TEXT_MIXIN (obj);
  GList *cur;

  for (cur = g_queue_peek_head_link (mixin->priv->pending);
       cur != NULL;
       cur = cur->next)
    {
      _PendingMessage *msg = cur->data;

      msg->flags |= TP_CHANNEL_TEXT_MESSAGE_FLAG_RESCUED;
    }
}

/**
 * tp_text_mixin_iface_init:
 * @g_iface: A pointer to the #TpSvcChannelTypeTextClass in an object class
 * @iface_data: Ignored
 *
 * Fill in this mixin's AcknowledgePendingMessages, GetMessageTypes and
 * ListPendingMessages implementations in the given interface vtable.
 * In addition to calling this function during interface initialization, the
 * implementor is expected to call tp_svc_channel_type_text_implement_send(),
 * providing a Send implementation.
 *
 * Deprecated: Use tp_message_mixin_text_iface_init() instead.
 */
void
tp_text_mixin_iface_init (gpointer g_iface,
                          gpointer iface_data)
{
  TpSvcChannelTypeTextClass *klass = g_iface;

#define IMPLEMENT(x) tp_svc_channel_type_text_implement_##x (klass,\
    tp_text_mixin_##x##_async)
  IMPLEMENT(acknowledge_pending_messages);
  IMPLEMENT(get_message_types);
  IMPLEMENT(list_pending_messages);
  /* send not implemented here */
#undef IMPLEMENT
}

G_GNUC_END_IGNORE_DEPRECATIONS
