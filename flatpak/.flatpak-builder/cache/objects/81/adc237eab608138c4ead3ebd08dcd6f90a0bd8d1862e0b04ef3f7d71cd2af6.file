/*
 * message.c - Source for TpMessage
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
 * SECTION:message
 * @title: TpMessage
 * @short_description: a message in the Telepathy message interface
 * @see_also: #TpCMMessage, #TpClientMessage, #TpSignalledMessage
 *
 * #TpMessage represent a message send or received using the Message
 * interface.
 *
 * Since: 0.7.21
 */

#include "config.h"

#include "message.h"
#include "message-internal.h"

#include <telepathy-glib/cm-message.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/util.h>
#include <telepathy-glib/variant-util-internal.h>

#define DEBUG_FLAG TP_DEBUG_MISC
#include "telepathy-glib/debug-internal.h"

G_DEFINE_TYPE (TpMessage, tp_message, G_TYPE_OBJECT)

/**
 * TpMessage:
 *
 * Opaque structure representing a message in the Telepathy messages interface
 * (an array of at least one mapping from string to variant, where the first
 * mapping contains message headers and subsequent mappings contain the
 * message body).
 *
 * This base class provides convenience API for most of the common keys that
 * can appear in the header. One notable exception is the sender of the
 * message. Inside a connection manager, messages are represented by the
 * #TpCMMessage subclass, and you should use tp_cm_message_get_sender().
 * When composing a message in a client using #TpClientMessage, messages do
 * not have an explicit sender (the sender is automatically the local user).
 * When a client sees a sent or received message signalled by the connection
 * manager (represented by #TpSignalledMessage), the message's sender (if any)
 * can be accessed with tp_signalled_message_get_sender().
 */

struct _TpMessagePrivate
{
  gboolean mutable;
};

static void
tp_message_dispose (GObject *object)
{
  TpMessage *self = TP_MESSAGE (object);
  void (*dispose) (GObject *) =
    G_OBJECT_CLASS (tp_message_parent_class)->dispose;
  guint i;

  if (self->parts != NULL)
    {
      for (i = 0; i < self->parts->len; i++)
        {
          g_hash_table_unref (g_ptr_array_index (self->parts, i));
        }

      g_ptr_array_unref (self->parts);
      self->parts = NULL;
    }

  if (dispose != NULL)
    dispose (object);
}

static void
tp_message_class_init (TpMessageClass *klass)
{
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  gobject_class->dispose = tp_message_dispose;

  g_type_class_add_private (gobject_class, sizeof (TpMessagePrivate));
}

static void
tp_message_init (TpMessage *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE ((self), TP_TYPE_MESSAGE,
      TpMessagePrivate);

  /* Message can be modified until _tp_message_set_immutable() is called */
  self->priv->mutable = TRUE;

  /* Create header part */
  self->parts = g_ptr_array_sized_new (1);

  tp_message_append_part (self);
}


/**
 * tp_message_new:
 * @connection: a connection on which to reference handles
 * @initial_parts: number of parts to create (at least 1)
 * @size_hint: preallocate space for this many parts (at least @initial_parts)
 *
 * <!-- nothing more to say -->
 *
 * Returns: a newly allocated message suitable to be passed to
 * tp_message_mixin_take_received()
 *
 * Since: 0.7.21
 * Deprecated: since 0.13.9. Use tp_cm_message_new()
 */
TpMessage *
tp_message_new (TpBaseConnection *connection,
                guint initial_parts,
                guint size_hint)
{
  g_return_val_if_fail (size_hint >= initial_parts, NULL);

  return tp_cm_message_new (connection, initial_parts);
}


/**
 * tp_message_destroy:
 * @self: a message
 *
 * Since 0.13.9 this function is a simple wrapper around
 * g_object_unref()
 *
 * Since: 0.7.21
 */
void
tp_message_destroy (TpMessage *self)
{
  g_object_unref (self);
}

/**
 * tp_message_count_parts:
 * @self: a message
 *
 * <!-- nothing more to say -->
 *
 * Returns: the number of parts in the message, including the headers in
 * part 0
 *
 * Since: 0.7.21
 */
guint
tp_message_count_parts (TpMessage *self)
{
  return self->parts->len;
}

/**
 * tp_message_peek:
 * @self: a message
 * @part: a part number
 *
 * <!-- nothing more to say -->
 *
 * Returns: (transfer none) (element-type utf8 GObject.Value):
 *  the #GHashTable used to implement the given part, or %NULL if the
 *  part number is out of range. The hash table is only valid as long as the
 *  message is valid and the part is not deleted.
 *
 * Since: 0.7.21
 */
const GHashTable *
tp_message_peek (TpMessage *self,
                 guint part)
{
  if (part >= self->parts->len)
    return NULL;

  return g_ptr_array_index (self->parts, part);
}

/**
 * tp_message_dup_part:
 * @self: a message
 * @part: a part number
 *
 * <!-- nothing more to say -->
 *
 * Returns: (transfer full):
 *  the current contents of the given part, or %NULL if the part number is
 *  out of range
 *
 * Since: 0.19.10
 */
GVariant *
tp_message_dup_part (TpMessage *self,
    guint part)
{
  if (part >= self->parts->len)
    return NULL;

  return _tp_asv_to_vardict (g_ptr_array_index (self->parts, part));
}


/**
 * tp_message_append_part:
 * @self: a message
 *
 * Append a body part to the message.
 *
 * Returns: the part number
 *
 * Since: 0.7.21
 */
guint
tp_message_append_part (TpMessage *self)
{
  g_return_val_if_fail (self->priv->mutable, 0);

  g_ptr_array_add (self->parts, g_hash_table_new_full (g_str_hash,
        g_str_equal, g_free, (GDestroyNotify) tp_g_value_slice_free));
  return self->parts->len - 1;
}

/**
 * tp_message_delete_part:
 * @self: a message
 * @part: a part number, which must be strictly greater than 0, and strictly
 *  less than the number returned by tp_message_count_parts()
 *
 * Delete the given body part from the message.
 *
 * Since: 0.7.21
 */
void
tp_message_delete_part (TpMessage *self,
                        guint part)
{
  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (part > 0);
  g_return_if_fail (self->priv->mutable);

  g_hash_table_unref (g_ptr_array_remove_index (self->parts, part));
}

/**
 * tp_message_ref_handle:
 * @self: a message
 * @handle_type: a handle type, greater than %TP_HANDLE_TYPE_NONE and less than
 *  %TP_NUM_HANDLE_TYPES
 * @handle: a handle of the given type
 *
 * Reference the given handle until this message is destroyed.
 *
 * Since: 0.7.21
 * Deprecated: since 0.13.9. Handles are now immortal so there is
 * no point to ref them. Furthermore, the only handle that should be stored
 * in a TpMessage is message-sender which should be set using
 * tp_cm_message_set_sender().
 */
void
tp_message_ref_handle (TpMessage *self,
                       TpHandleType handle_type,
                       TpHandle handle)
{
  g_return_if_fail (TP_IS_CM_MESSAGE (self));
  g_return_if_fail (self->priv->mutable);

  /* Handles are now immortal so we don't have to anything */
}

/**
 * tp_message_delete_key:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 *
 * Remove the given key and its value from the given part.
 *
 * Returns: %TRUE if the key previously existed
 *
 * Since: 0.7.21
 */
gboolean
tp_message_delete_key (TpMessage *self,
                       guint part,
                       const gchar *key)
{
  g_return_val_if_fail (part < self->parts->len, FALSE);
  g_return_val_if_fail (self->priv->mutable, FALSE);

  return g_hash_table_remove (g_ptr_array_index (self->parts, part), key);
}


/**
 * tp_message_set_handle:
 * @self: a #TpCMMessage
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @handle_type: a handle type
 * @handle_or_0: a handle of that type, or 0
 *
 * If @handle_or_0 is not zero, reference it with tp_message_ref_handle().
 *
 * Set @key in part @part of @self to have @handle_or_0 as an unsigned integer
 * value.
 *
 * Since 0.13.9 this function has been deprecated in favor or
 * tp_cm_message_set_sender() as 'message-sender' is the only handle
 * you can put in a #TpCMMessage.
 *
 * Since: 0.7.21
 * Deprecated: since 0.13.9. Use tp_cm_message_set_sender()
 */
void
tp_message_set_handle (TpMessage *self,
                       guint part,
                       const gchar *key,
                       TpHandleType handle_type,
                       TpHandle handle_or_0)
{
  g_return_if_fail (TP_IS_CM_MESSAGE (self));
  g_return_if_fail (self->priv->mutable);

  tp_message_set_uint32 (self, part, key, handle_or_0);
}


/**
 * tp_message_set_boolean:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @b: a boolean value
 *
 * Set @key in part @part of @self to have @b as a boolean value.
 *
 * Since: 0.7.21
 */
void
tp_message_set_boolean (TpMessage *self,
                        guint part,
                        const gchar *key,
                        gboolean b)
{
  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (self->priv->mutable);

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key), tp_g_value_slice_new_boolean (b));
}

/**
 * tp_message_set_int16:
 * @s: a message
 * @p: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @k: a key in the mapping representing the part
 * @i: an integer value
 *
 * Set @key in part @part of @self to have @i as a signed integer value.
 *
 * Since: 0.7.21
 */

/**
 * tp_message_set_int32:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @i: an integer value
 *
 * Set @key in part @part of @self to have @i as a signed integer value.
 *
 * Since: 0.7.21
 */
void
tp_message_set_int32 (TpMessage *self,
                      guint part,
                      const gchar *key,
                      gint32 i)
{
  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (self->priv->mutable);

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key), tp_g_value_slice_new_int (i));
}


/**
 * tp_message_set_int64:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @i: an integer value
 *
 * Set @key in part @part of @self to have @i as a signed integer value.
 *
 * Since: 0.7.21
 */
void
tp_message_set_int64 (TpMessage *self,
                      guint part,
                      const gchar *key,
                      gint64 i)
{
  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (self->priv->mutable);

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key), tp_g_value_slice_new_int64 (i));
}


/**
 * tp_message_set_uint16:
 * @s: a message
 * @p: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @k: a key in the mapping representing the part
 * @u: an unsigned integer value
 *
 * Set @key in part @part of @self to have @u as an unsigned integer value.
 *
 * Since: 0.7.21
 */

/**
 * tp_message_set_uint32:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @u: an unsigned integer value
 *
 * Set @key in part @part of @self to have @u as an unsigned integer value.
 *
 * Since: 0.7.21
 */
void
tp_message_set_uint32 (TpMessage *self,
                       guint part,
                       const gchar *key,
                       guint32 u)
{
  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (self->priv->mutable);

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key), tp_g_value_slice_new_uint (u));
}


/**
 * tp_message_set_uint64:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @u: an unsigned integer value
 *
 * Set @key in part @part of @self to have @u as an unsigned integer value.
 *
 * Since: 0.7.21
 */
void
tp_message_set_uint64 (TpMessage *self,
                       guint part,
                       const gchar *key,
                       guint64 u)
{
  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (self->priv->mutable);

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key), tp_g_value_slice_new_uint64 (u));
}


/**
 * tp_message_set_string:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @s: a string value
 *
 * Set @key in part @part of @self to have @s as a string value.
 *
 * Since: 0.7.21
 */
void
tp_message_set_string (TpMessage *self,
                       guint part,
                       const gchar *key,
                       const gchar *s)
{
  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (s != NULL);
  g_return_if_fail (self->priv->mutable);

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key), tp_g_value_slice_new_string (s));
}


/**
 * tp_message_set_string_printf:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @fmt: a printf-style format string for the string value
 * @...: arguments for the format string
 *
 * Set @key in part @part of @self to have a string value constructed from a
 * printf-style format string.
 *
 * Since: 0.7.21
 */
void
tp_message_set_string_printf (TpMessage *self,
                              guint part,
                              const gchar *key,
                              const gchar *fmt,
                              ...)
{
  va_list va;
  gchar *s;

  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (fmt != NULL);
  g_return_if_fail (self->priv->mutable);

  va_start (va, fmt);
  s = g_strdup_vprintf (fmt, va);
  va_end (va);

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key), tp_g_value_slice_new_take_string (s));
}


/**
 * tp_message_set_bytes:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @len: a number of bytes
 * @bytes: an array of @len bytes
 *
 * Set @key in part @part of @self to have @bytes as a byte-array value.
 *
 * Since: 0.7.21
 */
void
tp_message_set_bytes (TpMessage *self,
                      guint part,
                      const gchar *key,
                      guint len,
                      gconstpointer bytes)
{
  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (bytes != NULL);
  g_return_if_fail (self->priv->mutable);

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key),
      tp_g_value_slice_new_bytes (len, bytes));
}


/**
 * tp_message_set:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @source: a value, encoded as dbus-glib would
 *
 * Set @key in part @part of @self to have a copy of @source as its value.
 *
 * If @source represents a data structure containing handles, they should
 * all be referenced with tp_message_ref_handle() first.
 *
 * In high-level language bindings, use tp_message_set_variant() instead.
 *
 * Since: 0.7.21
 */
void
tp_message_set (TpMessage *self,
                guint part,
                const gchar *key,
                const GValue *source)
{
  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (source != NULL);
  g_return_if_fail (self->priv->mutable);

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key), tp_g_value_slice_dup (source));
}

/**
 * tp_message_set_variant:
 * @self: a message
 * @part: a part number, which must be strictly less than the number
 *  returned by tp_message_count_parts()
 * @key: a key in the mapping representing the part
 * @value: a value
 *
 * Set @key in part @part of @self to have @value as its value.
 *
 * If @value is a floating reference (see g_variant_ref_sink()), then this
 * function will take ownership of it.
 *
 * Since: 0.19.10
 */
void
tp_message_set_variant (TpMessage *self,
    guint part,
    const gchar *key,
    GVariant *value)
{
  GValue *gvalue;

  g_return_if_fail (part < self->parts->len);
  g_return_if_fail (key != NULL);
  g_return_if_fail (value != NULL);
  g_return_if_fail (self->priv->mutable);

  g_variant_ref_sink (value);
  gvalue = g_slice_new0 (GValue);
  dbus_g_value_parse_g_variant (value, gvalue);
  g_variant_unref (value);

  g_hash_table_insert (g_ptr_array_index (self->parts, part),
      g_strdup (key), gvalue);
}

/**
 * tp_message_take_message:
 * @self: a #TpCMMessage
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
 * Since: 0.7.21
 * Deprecated: since 0.13.9. Use tp_cm_message_take_message()
 */
void
tp_message_take_message (TpMessage *self,
                         guint part,
                         const gchar *key,
                         TpMessage *message)
{
  g_return_if_fail (TP_IS_CM_MESSAGE (self));

  tp_cm_message_take_message (self, part, key, message);
}

static void
subtract_from_hash (gpointer key,
                    gpointer value,
                    gpointer user_data)
{
  DEBUG ("... removing %s", (gchar *) key);
  g_hash_table_remove (user_data, key);
}

/**
 * tp_message_to_text:
 * @message: a #TpMessage
 * @out_flags: (out) : if not %NULL, the #TpChannelTextMessageFlags of @message
 *
 * Concatene all the text parts contained in @message.
 *
 * Returns: (transfer full): a newly allocated string containing the
 * text content of #message
 *
 * Since: 0.13.9
 */
gchar *
tp_message_to_text (TpMessage *message,
    TpChannelTextMessageFlags *out_flags)
{
  guint i;
  GHashTable *header = g_ptr_array_index (message->parts, 0);
  /* Lazily created hash tables, used as a sets: keys are borrowed
   * "alternative" string values from @parts, value == key. */
  /* Alternative IDs for which we have already extracted an alternative */
  GHashTable *alternatives_used = NULL;
  /* Alternative IDs for which we expect to extract text, but have not yet;
   * cleared if the flag Channel_Text_Message_Flag_Non_Text_Content is set.
   * At the end, if this contains any item not in alternatives_used,
   * Channel_Text_Message_Flag_Non_Text_Content must be set. */
  GHashTable *alternatives_needed = NULL;
  GString *buffer = g_string_new ("");
  TpChannelTextMessageFlags flags = 0;

  if (tp_asv_get_boolean (header, "scrollback", NULL))
    flags |= TP_CHANNEL_TEXT_MESSAGE_FLAG_SCROLLBACK;

  if (tp_asv_get_boolean (header, "rescued", NULL))
    flags |= TP_CHANNEL_TEXT_MESSAGE_FLAG_RESCUED;

  /* If the message is on an extended interface, is a delivery report, or only
   * contains headers, definitely set the "your client is too old" flag. */
  if (message->parts->len <= 1 ||
      tp_asv_get_uint32 (header, "message-type", NULL)
          == TP_CHANNEL_TEXT_MESSAGE_TYPE_DELIVERY_REPORT ||
      g_hash_table_lookup (header, "interface") != NULL)
    {
      flags |= TP_CHANNEL_TEXT_MESSAGE_FLAG_NON_TEXT_CONTENT;
    }

  for (i = 1; i < message->parts->len; i++)
    {
      GHashTable *part = g_ptr_array_index (message->parts, i);
      const gchar *type = tp_asv_get_string (part, "content-type");
      const gchar *alternative = tp_asv_get_string (part, "alternative");

      /* Renamed to "content-type" in spec 0.17.14 */
      if (type == NULL)
        type = tp_asv_get_string (part, "type");

      DEBUG ("Parsing part %u, type %s, alternative %s", i, type, alternative);

      if (!tp_strdiff (type, "text/plain"))
        {
          GValue *value;

          DEBUG ("... is text/plain");

          if (alternative != NULL && alternative[0] != '\0')
            {
              if (alternatives_used == NULL)
                {
                  /* We can't have seen an alternative for this part yet.
                   * However, we need to create the hash table now */
                  alternatives_used = g_hash_table_new (g_str_hash,
                      g_str_equal);
                }
              else if (g_hash_table_lookup (alternatives_used,
                    alternative) != NULL)
                {
                  /* we've seen a "better" alternative for this part already.
                   * Skip it */
                  DEBUG ("... already saw a better alternative, skipping it");
                  continue;
                }

              g_hash_table_insert (alternatives_used, (gpointer) alternative,
                  (gpointer) alternative);
            }

          value = g_hash_table_lookup (part, "content");

          if (value != NULL && G_VALUE_HOLDS_STRING (value))
            {
              DEBUG ("... using its text");
              g_string_append (buffer, g_value_get_string (value));

              value = g_hash_table_lookup (part, "truncated");

              if (value != NULL && (!G_VALUE_HOLDS_BOOLEAN (value) ||
                  g_value_get_boolean (value)))
                {
                  DEBUG ("... appears to have been truncated");
                  flags |= TP_CHANNEL_TEXT_MESSAGE_FLAG_TRUNCATED;
                }
            }
          else
            {
              /* There was a text/plain part we couldn't parse:
               * that counts as "non-text content" I think */
              DEBUG ("... didn't understand it, setting NON_TEXT_CONTENT");
              flags |= TP_CHANNEL_TEXT_MESSAGE_FLAG_NON_TEXT_CONTENT;
              tp_clear_pointer (&alternatives_needed, g_hash_table_unref);
            }
        }
      else if ((flags & TP_CHANNEL_TEXT_MESSAGE_FLAG_NON_TEXT_CONTENT) == 0)
        {
          DEBUG ("... wondering whether this is NON_TEXT_CONTENT?");

          if (tp_str_empty (alternative))
            {
              /* This part can't possibly have a text alternative, since it
               * isn't part of a multipart/alternative group
               * (attached image or something, perhaps) */
              DEBUG ("... ... yes, no possibility of a text alternative");
              flags |= TP_CHANNEL_TEXT_MESSAGE_FLAG_NON_TEXT_CONTENT;
              tp_clear_pointer (&alternatives_needed, g_hash_table_unref);
            }
          else if (alternatives_used != NULL &&
              g_hash_table_lookup (alternatives_used, (gpointer) alternative)
              != NULL)
            {
              DEBUG ("... ... no, we already saw a text alternative");
            }
          else
            {
              /* This part might have a text alternative later, if we're
               * lucky */
              if (alternatives_needed == NULL)
                alternatives_needed = g_hash_table_new (g_str_hash,
                    g_str_equal);

              DEBUG ("... ... perhaps, but might have text alternative later");
              g_hash_table_insert (alternatives_needed, (gpointer) alternative,
                  (gpointer) alternative);
            }
        }
    }

  if ((flags & TP_CHANNEL_TEXT_MESSAGE_FLAG_NON_TEXT_CONTENT) == 0 &&
      alternatives_needed != NULL)
    {
      if (alternatives_used != NULL)
        g_hash_table_foreach (alternatives_used, subtract_from_hash,
            alternatives_needed);

      if (g_hash_table_size (alternatives_needed) > 0)
        flags |= TP_CHANNEL_TEXT_MESSAGE_FLAG_NON_TEXT_CONTENT;
    }

  if (alternatives_needed != NULL)
    g_hash_table_unref (alternatives_needed);

  if (alternatives_used != NULL)
    g_hash_table_unref (alternatives_used);

  if (out_flags != NULL)
    {
      *out_flags = flags;
    }

  return g_string_free (buffer, FALSE);
}

void
_tp_message_set_immutable (TpMessage *self)
{
  self->priv->mutable = FALSE;
}

/**
 * tp_message_is_mutable:
 * @self: a #TpMessage
 *
 * Check if @self is mutable. Only mutable messages can be modified using
 * functions such as tp_message_set_string().
 *
 * Returns: %TRUE if the message is mutable.
 *
 * Since: 0.13.9
 */
gboolean
tp_message_is_mutable (TpMessage *self)
{
  g_return_val_if_fail (TP_IS_MESSAGE (self), FALSE);

  return self->priv->mutable;
}

/**
 * tp_message_get_token:
 * @self: a message
 *
 * Return this message's identifier in the underlying protocol. This is
 * <emphasis>not</emphasis> guaranteed to be unique, even within the scope
 * of a single channel or contact: the only guarantee made is that two
 * messages with different non-empty tokens are different messages.
 *
 * If there is no suitable token, return %NULL.
 *
 * Returns: (transfer none): a non-empty opaque identifier, or %NULL if none
 *
 * Since: 0.13.9
 */
const gchar *
tp_message_get_token (TpMessage *self)
{
  const gchar *token;

  g_return_val_if_fail (TP_IS_MESSAGE (self), NULL);

  token = tp_asv_get_string (tp_message_peek (self, 0), "message-token");

  if (tp_str_empty (token))
    return NULL;
  else
    return token;
}

/**
 * tp_message_get_message_type:
 * @self: a message
 *
 * <!-- -->
 *
 * Returns: the type of this message
 *
 * Since: 0.13.10
 */
TpChannelTextMessageType
tp_message_get_message_type (TpMessage *self)
{
  g_return_val_if_fail (TP_IS_MESSAGE (self),
      TP_CHANNEL_TEXT_MESSAGE_TYPE_NORMAL);
  /* if message-type is absent or invalid we just return 0, which is NORMAL */
  return tp_asv_get_uint32 (tp_message_peek (self, 0), "message-type", NULL);
}

/**
 * tp_message_get_sent_timestamp:
 * @self: a message
 *
 * Return when this message was sent, as a number of seconds since the
 * beginning of 1970 in the UTC timezone (the same representation used by
 * g_date_time_new_from_unix_utc(), for instance), or 0 if not known.
 *
 * If this protocol does not track the time at which the message was
 * initially sent, this timestamp might be approximated by using the
 * time at which it arrived at a central server.
 *
 * Returns: a Unix timestamp, or 0
 *
 * Since: 0.13.9
 */
gint64
tp_message_get_sent_timestamp (TpMessage *self)
{
  g_return_val_if_fail (TP_IS_MESSAGE (self), 0);
  return tp_asv_get_int64 (tp_message_peek (self, 0), "message-sent", NULL);
}

/**
 * tp_message_get_received_timestamp:
 * @self: a message
 *
 * Return when this message was received locally, as a number of seconds since
 * the beginning of 1970 in the UTC timezone (the same representation used by
 * g_date_time_new_from_unix_utc(), for instance), or 0 if not known.
 *
 * Returns: a Unix timestamp, or 0
 *
 * Since: 0.13.9
 */
gint64
tp_message_get_received_timestamp (TpMessage *self)
{
  g_return_val_if_fail (TP_IS_MESSAGE (self), 0);
  return tp_asv_get_int64 (tp_message_peek (self, 0), "message-received",
      NULL);
}

/**
 * tp_message_is_scrollback:
 * @self: a message
 *
 * <!-- no more to say -->
 *
 * Returns: %TRUE if this message is part of a replay of message history, for
 *  instance in an XMPP chatroom.
 *
 * Since: 0.13.9
 */
gboolean
tp_message_is_scrollback (TpMessage *self)
{
  g_return_val_if_fail (TP_IS_MESSAGE (self), FALSE);
  return tp_asv_get_boolean (tp_message_peek (self, 0), "scrollback", NULL);
}

/**
 * tp_message_is_rescued:
 * @self: a message
 *
 * Returns %TRUE if this incoming message has been seen in a previous channel
 * during the lifetime of the Connection, but had not been acknowledged when
 * that channel closed, causing an identical channel (in which the message now
 * appears) to open.
 *
 * Loggers should check this flag to avoid duplicating messages, for instance.
 *
 * Returns: %TRUE if this message was seen in a previous Channel on this
 *  Connection
 *
 * Since: 0.13.9
 */
gboolean
tp_message_is_rescued (TpMessage *self)
{
  g_return_val_if_fail (TP_IS_MESSAGE (self), FALSE);
  return tp_asv_get_boolean (tp_message_peek (self, 0), "rescued", NULL);
}

/**
 * tp_message_get_supersedes:
 * @self: a message
 *
 * If this message replaces a previous message, return the value of
 * tp_message_get_token() for that previous message. Otherwise, return %NULL.
 *
 * For instance, a user interface could replace the superseded
 * message with this message, or grey out the superseded message.
 *
 * Returns: (transfer none): a non-empty opaque identifier, or %NULL if none
 *
 * Since: 0.13.9
 */
const gchar *
tp_message_get_supersedes (TpMessage *self)
{
  const gchar *token;

  g_return_val_if_fail (TP_IS_MESSAGE (self), NULL);

  token = tp_asv_get_string (tp_message_peek (self, 0), "supersedes");

  if (tp_str_empty (token))
    return NULL;
  else
    return token;
}

/**
 * tp_message_get_specific_to_interface:
 * @self: a message
 *
 * If this message is specific to a particular D-Bus interface and should
 * be ignored by clients without knowledge of that interface, return the
 * name of the interface.
 *
 * If this message is an ordinary message or delivery report, return %NULL.
 *
 * Returns: (transfer none): a D-Bus interface name, or %NULL for ordinary
 *  messages and delivery reports
 *
 * Since: 0.13.9
 */
const gchar *
tp_message_get_specific_to_interface (TpMessage *self)
{
  g_return_val_if_fail (TP_IS_MESSAGE (self), NULL);
  return tp_asv_get_string (tp_message_peek (self, 0), "interface");
}

/**
 * tp_message_is_delivery_report:
 * @self: a message
 *
 * If this message is a delivery report indicating success or failure of
 * delivering a message, return %TRUE.
 *
 * Returns: %TRUE if this is a delivery report
 *
 * Since: 0.13.9
 */
gboolean
tp_message_is_delivery_report (TpMessage *self)
{
  gboolean valid;

  g_return_val_if_fail (TP_IS_MESSAGE (self), FALSE);

  tp_asv_get_uint32 (tp_message_peek (self, 0), "delivery-status", &valid);
  return valid;
}

/**
 * tp_message_get_pending_message_id:
 * @self: a message
 * @valid: (out): either %NULL, or a location in which to store %TRUE if @self
 * contains a pending message ID.
 *
 * Return the incoming message ID of @self. Only incoming messages have such
 * ID, for outgoing ones this function returns 0 and set @valid to %FALSE.
 *
 * Returns: the incoming message ID.
 *
 * Since: 0.15.3
 */
guint32
tp_message_get_pending_message_id (TpMessage *self,
    gboolean *valid)
{
  g_return_val_if_fail (TP_IS_MESSAGE (self), FALSE);

  return tp_asv_get_uint32 (tp_message_peek (self, 0),
      "pending-message-id", valid);
}

/*
 * Omitted for now:
 *
 * sender-nickname - perhaps better done in TpSignalledMessage, so we can use
 *  the TpContact's nickname if the message doesn't specify?
 *
 * delivery reporting stuff other than "is this a report?" - later
 */
