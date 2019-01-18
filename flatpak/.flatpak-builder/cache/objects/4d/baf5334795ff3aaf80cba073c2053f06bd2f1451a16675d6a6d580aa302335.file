/*
 * debug-sender.c - Telepathy debug interface implementation
 * Copyright (C) 2009 Collabora Ltd.
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

#include "config.h"

#include "debug-sender.h"

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/util.h>
#include <telepathy-glib/svc-generic.h>

/**
 * SECTION:debug-sender
 * @title: TpDebugSender
 * @short_description: object for exposing Telepathy debug interface
 *
 * A #TpDebugSender object is an object exposing the Telepathy debug interface.
 * There should be one object per process as it registers the object path
 * /org/freedesktop/Telepathy/debug. Once the object exists and has the object
 * path, messages can be passed to it using tp_debug_sender_add_message and
 * signals will automatically be fired.
 *
 * #TpDebugSender is primarily designed for use in Connection Managers, but can
 * be used by any other part of the Telepathy stack which wants to expose its
 * debugging information over the debug interface.
 *
 * In a Connection Manager, one would probably keep a ref to the #TpDebugSender
 * in the connection manager object, and when this said object is finalized, so
 * is the process's #TpDebugSender. A GLib log handler is also provided:
 * tp_debug_sender_log_handler().
 *
 * Since: 0.7.36
 */

/**
 * TpDebugSenderClass:
 *
 * The class of a #TpDebugSender.
 *
 * Since: 0.7.36
 */

/**
 * TpDebugSender:
 *
 * An object for exposing the Telepathy debug interface.
 *
 * Since: 0.7.36
 */

static gpointer debug_sender = NULL;

/* On the basis that messages are around 60 bytes on average, and that 50kb is
 * a reasonable maximum size for a frame buffer.
 */

#define DEBUG_MESSAGE_LIMIT 800

static void debug_iface_init (gpointer g_iface, gpointer iface_data);

struct _TpDebugSenderPrivate
{
  gboolean enabled;
  gboolean timestamps;
  GQueue *messages;
};

typedef struct {
  gdouble timestamp;
  gchar *domain;
  TpDebugLevel level;
  gchar *string;
} DebugMessage;

G_DEFINE_TYPE_WITH_CODE (TpDebugSender, tp_debug_sender, G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_DBUS_PROPERTIES,
        tp_dbus_properties_mixin_iface_init);
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_DEBUG, debug_iface_init))

/* properties */
enum
{
  PROP_ENABLED = 1,
  NUM_PROPERTIES
};

/* must be thread-safe */
static TpDebugLevel
log_level_flags_to_debug_level (GLogLevelFlags level)
{
  if (level & G_LOG_LEVEL_ERROR)
    return TP_DEBUG_LEVEL_ERROR;
  else if (level & G_LOG_LEVEL_CRITICAL)
    return TP_DEBUG_LEVEL_CRITICAL;
  else if (level & G_LOG_LEVEL_WARNING)
    return TP_DEBUG_LEVEL_WARNING;
  else if (level & G_LOG_LEVEL_MESSAGE)
    return TP_DEBUG_LEVEL_MESSAGE;
  else if (level & G_LOG_LEVEL_INFO)
    return TP_DEBUG_LEVEL_INFO;
  else if (level & G_LOG_LEVEL_DEBUG)
    return TP_DEBUG_LEVEL_DEBUG;
  else
    /* Fall back to DEBUG if all else fails */
    return TP_DEBUG_LEVEL_DEBUG;
}

/* must be thread-safe */
static DebugMessage *
debug_message_new (GTimeVal *timestamp,
    const gchar *domain,
    GLogLevelFlags level,
    const gchar *string)
{
  DebugMessage *msg;

  msg = g_slice_new0 (DebugMessage);
  msg->timestamp = timestamp->tv_sec + timestamp->tv_usec / 1e6;
  msg->domain = g_strdup (domain);
  msg->level = log_level_flags_to_debug_level (level);
  msg->string = g_strdup (string);
  return msg;
}

static void
debug_message_free (DebugMessage *msg)
{
  g_free (msg->domain);
  g_free (msg->string);
  g_slice_free (DebugMessage, msg);
}

static void
tp_debug_sender_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpDebugSender *self = TP_DEBUG_SENDER (object);

  switch (property_id)
    {
      case PROP_ENABLED:
        g_value_set_boolean (value, self->priv->enabled);
        break;

      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}

static void
tp_debug_sender_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpDebugSender *self = TP_DEBUG_SENDER (object);

  switch (property_id)
    {
      case PROP_ENABLED:
        self->priv->enabled = g_value_get_boolean (value);
        break;

     default:
       G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
  }
}

static void
tp_debug_sender_finalize (GObject *object)
{
  TpDebugSender *self = TP_DEBUG_SENDER (object);

  g_queue_foreach (self->priv->messages, (GFunc) debug_message_free, NULL);
  g_queue_free (self->priv->messages);
  self->priv->messages = NULL;

  G_OBJECT_CLASS (tp_debug_sender_parent_class)->finalize (object);
}

static GObject *
tp_debug_sender_constructor (GType type,
    guint n_construct_params,
    GObjectConstructParam *construct_params)
{
  GObject *retval;

  if (debug_sender == NULL)
    {
      retval = G_OBJECT_CLASS (tp_debug_sender_parent_class)->constructor (
          type, n_construct_params, construct_params);
      debug_sender = retval;
      g_object_add_weak_pointer (retval, &debug_sender);
    }
  else
    {
      retval = g_object_ref (G_OBJECT (debug_sender));
    }

  return retval;
}

static void
tp_debug_sender_constructed (GObject *object)
{
  TpDBusDaemon *dbus_daemon;

  dbus_daemon = tp_dbus_daemon_dup (NULL);

  if (dbus_daemon != NULL)
    {
      tp_dbus_daemon_register_object (dbus_daemon,
          TP_DEBUG_OBJECT_PATH, debug_sender);

      g_object_unref (dbus_daemon);
    }
}

static void
tp_debug_sender_class_init (TpDebugSenderClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  static TpDBusPropertiesMixinPropImpl debug_props[] = {
      { "Enabled", "enabled", "enabled" },
      { NULL }
  };
  static TpDBusPropertiesMixinIfaceImpl prop_interfaces[] = {
      { TP_IFACE_DEBUG,
        tp_dbus_properties_mixin_getter_gobject_properties,
        tp_dbus_properties_mixin_setter_gobject_properties,
        debug_props,
      },
      { NULL }
  };

  g_type_class_add_private (klass, sizeof (TpDebugSenderPrivate));

  object_class->get_property = tp_debug_sender_get_property;
  object_class->set_property = tp_debug_sender_set_property;
  object_class->finalize = tp_debug_sender_finalize;
  object_class->constructor = tp_debug_sender_constructor;
  object_class->constructed = tp_debug_sender_constructed;

  /**
   * TpDebugSender:enabled:
   *
   * %TRUE if the NewDebugMessage signal should be emitted when a new debug
   * message is generated.
   */
  g_object_class_install_property (object_class, PROP_ENABLED,
      g_param_spec_boolean ("enabled", "Enabled?",
          "True if the new-debug-message signal is enabled.",
          FALSE,
          G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  klass->dbus_props_class.interfaces = prop_interfaces;
  tp_dbus_properties_mixin_class_init (object_class,
      G_STRUCT_OFFSET (TpDebugSenderClass, dbus_props_class));
}

static void
get_messages (TpSvcDebug *self,
    DBusGMethodInvocation *context)
{
  TpDebugSender *dbg = TP_DEBUG_SENDER (self);
  GPtrArray *messages;
  GList *i;
  guint j;

  messages = g_ptr_array_sized_new (g_queue_get_length (dbg->priv->messages));

  for (i = dbg->priv->messages->head; i; i = i->next)
    {
      GValue gvalue = { 0 };
      DebugMessage *message = (DebugMessage *) i->data;

      g_value_init (&gvalue, TP_STRUCT_TYPE_DEBUG_MESSAGE);
      g_value_take_boxed (&gvalue,
          dbus_g_type_specialized_construct (TP_STRUCT_TYPE_DEBUG_MESSAGE));
      dbus_g_type_struct_set (&gvalue,
          0, message->timestamp,
          1, message->domain,
          2, message->level,
          3, message->string,
          G_MAXUINT);
      g_ptr_array_add (messages, g_value_get_boxed (&gvalue));
    }

  tp_svc_debug_return_from_get_messages (context, messages);

  for (j = 0; j < messages->len; j++)
    g_boxed_free (TP_STRUCT_TYPE_DEBUG_MESSAGE, messages->pdata[j]);

  g_ptr_array_unref (messages);
}

static void
debug_iface_init (gpointer g_iface,
    gpointer iface_data)
{
  TpSvcDebugClass *klass = (TpSvcDebugClass *) g_iface;

  tp_svc_debug_implement_get_messages (klass, get_messages);
}

static void
tp_debug_sender_init (TpDebugSender *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_DEBUG_SENDER,
      TpDebugSenderPrivate);

  self->priv->messages = g_queue_new ();
}

/**
 * tp_debug_sender_dup:
 *
 * Returns a #TpDebugSender instance on the bus this process was activated by
 * (if it was launched by D-Bus service activation), or the session bus
 * (otherwise).
 *
 * The returned #TpDebugSender is cached; the same #TpDebugSender object will
 * be returned by this function repeatedly, as long as at least one reference
 * exists.
 *
 * Returns: a reference to the #TpDebugSender instance for the current starter
 *          bus daemon
 *
 * Since: 0.7.36
 */
TpDebugSender *
tp_debug_sender_dup (void)
{
  return g_object_new (TP_TYPE_DEBUG_SENDER, NULL);
}

static void
_tp_debug_sender_take (TpDebugSender *self,
    DebugMessage *new_msg)
{
#ifdef ENABLE_DEBUG_CACHE
  if (g_queue_get_length (self->priv->messages) >= DEBUG_MESSAGE_LIMIT)
    {
      DebugMessage *old_head =
        (DebugMessage *) g_queue_pop_head (self->priv->messages);

      debug_message_free (old_head);
    }

  g_queue_push_tail (self->priv->messages, new_msg);
#endif

  if (self->priv->enabled)
    {
      tp_svc_debug_emit_new_debug_message (self, new_msg->timestamp,
          new_msg->domain, new_msg->level, new_msg->string);
    }

#ifndef ENABLE_DEBUG_CACHE
  /* if there's cache, these are freed when they fall of its end instead */
  debug_message_free (new_msg);
#endif
}

/**
 * tp_debug_sender_add_message:
 * @self: A #TpDebugSender instance
 * @timestamp: Time of the message or %NULL for right now
 * @domain: Message domain
 * @level: The message level
 * @string: The message string itself
 *
 * Adds a new message to the debug sender message queue. If the
 * #TpDebugSender:enabled property is set to %TRUE, then a NewDebugMessage
 * signal will be fired too.
 *
 * Since: 0.7.36
 */
void
tp_debug_sender_add_message (TpDebugSender *self,
    GTimeVal *timestamp,
    const gchar *domain,
    GLogLevelFlags level,
    const gchar *string)
{
  GTimeVal now = { 0 };

  if (timestamp == NULL)
    {
      g_get_current_time (&now);
      timestamp = &now;
    }

  _tp_debug_sender_take (self,
      debug_message_new (timestamp, domain, level, string));
}

/**
 * tp_debug_sender_add_message_vprintf:
 * @self: A #TpDebugSender instance
 * @timestamp: Time of the message, or %NULL for right now
 * @formatted: Place to store the formatted message, or %NULL if not needed
 * @domain: Message domain
 * @level: The message level
 * @format: The printf() format string
 * @args: the #va_list of parameters to insert into @format
 *
 * Formats and adds a new message to the debug sender message queue. If the
 * #TpDebugSender:enabled property is set to %TRUE, then a NewDebugMessage
 * signal will be fired too.
 *
 * Since: 0.13.13
 */
void
tp_debug_sender_add_message_vprintf (TpDebugSender *self,
    GTimeVal *timestamp,
    gchar **formatted,
    const gchar *domain,
    GLogLevelFlags level,
    const gchar *format,
    va_list args)
{
  gchar *message = NULL;

  /* disabled cache? we might have no need to format the message at all */
#ifndef ENABLE_DEBUG_CACHE
  if (!self->priv->enabled && formatted == NULL)
    return;
#endif

  message = g_strdup_vprintf (format, args);

  tp_debug_sender_add_message (self, timestamp, domain, level, message);

  /* if the caller didn't want a copy, we're done with the message: */
  if (formatted != NULL)
    *formatted = message;
  else
    g_free (message);
}

/**
 * tp_debug_sender_add_message_printf:
 * @self: A #TpDebugSender instance
 * @timestamp: Time of the message, or %NULL for right now
 * @formatted: Place to store the formatted message, or %NULL if not required
 * @domain: Message domain
 * @level: The message level
 * @format: The printf() format string
 * @...: The parameters to insert into @format
 *
 * Formats and adds a new message to the debug sender message queue. If the
 * #TpDebugSender:enabled property is set to %TRUE, then a NewDebugMessage
 * signal will be fired too.
 *
 * Since: 0.13.13
 */
void
tp_debug_sender_add_message_printf (TpDebugSender *self,
    GTimeVal *timestamp,
    gchar **formatted,
    const gchar *domain,
    GLogLevelFlags level,
    const gchar *format,
    ...)
{
  va_list args;

  va_start (args, format);
  tp_debug_sender_add_message_vprintf (self, timestamp, formatted, domain, level,
      format, args);
  va_end (args);
}

static gboolean
tp_debug_sender_idle (gpointer data)
{
  if (debug_sender == NULL)
    debug_message_free (data);
  else
    _tp_debug_sender_take (debug_sender, data);

  return FALSE;
}

/**
 * tp_debug_sender_log_handler:
 * @log_domain: domain of the message
 * @log_level: log leve of the message
 * @message: the message itself
 * @exclude: a log domain string to exclude from the #TpDebugSender, or %NULL
 *
 * A generic log handler designed to be used by CMs. It initially calls
 * g_log_default_handler(), and then sends the message on the bus
 * #TpDebugSender.
 *
 * The @exclude parameter is designed to allow filtering one domain, instead of
 * sending every message to the #TpDebugSender: typical usage is for a
 * process to filter out messages from its own %G_LOG_DOMAIN, so that it can
 * append a category to its own messages and pass them directly to
 * tp_debug_sender_add_message. Note that every message, regardless of
 * domain, is given to g_log_default_handler().
 *
 * Note that a ref to a #TpDebugSender must be kept at all times otherwise
 * no messages given to the handler will be sent to the Telepathy debug
 * interface.
 *
 * An example of its usage, taking in mind the notes above, follows:
 * |[
 * /<!-- -->* Create a main loop and debug sender *<!-- -->/
 * GMainLoop *loop = g_main_loop_new (NULL, FALSE);
 * TpDebugSender *sender = tp_debug_sender_dup ();
 *
 * /<!-- -->* Set the default handler *<!-- -->/
 * g_log_set_default_handler (tp_debug_sender_log_handler, G_LOG_DOMAIN);
 *
 * /<!-- -->* Run the main loop, but keeping a ref on the TpDebugSender from
 *  * the beginning of this code sample. *<!-- -->/
 * g_main_loop_run (loop);
 *
 * /<!-- -->* g_main_loop_quit was called, so only now can we clean up the
 *  * TpDebugSender. *<!-- -->/
 * g_object_unref (sender);
 * ]|
 *
 * (In a connection manager, replace g_main_loop_run() in the above example
 * with tp_run_connection_manager().)
 *
 * This function is merely for convenience if it meets the requirements.
 * It can easily be re-implemented in services, and does not need to be
 * used.
 *
 * If timestamps should be prepended to messages (like in
 * tp_debug_timestamped_log_handler()), tp_debug_sender_set_timestamps()
 * should also be called.
 *
 * Since version 0.11.15, this function can be called from any thread.
 *
 * Since: 0.7.36
 */
void
tp_debug_sender_log_handler (const gchar *log_domain,
    GLogLevelFlags log_level,
    const gchar *message,
    gpointer exclude)
{
  GTimeVal now = { 0, 0 };

  if (debug_sender != NULL &&
      ((TpDebugSender *) debug_sender)->priv->timestamps)
    {
      gchar *now_str, *tmp;

      g_get_current_time (&now);
      now_str = g_time_val_to_iso8601 (&now);

      tmp = g_strdup_printf ("%s: %s", now_str, message);

      g_log_default_handler (log_domain, log_level, tmp, NULL);

      g_free (now_str);
      g_free (tmp);
    }
  else
    {
      g_log_default_handler (log_domain, log_level, message, NULL);
    }

  if (exclude == NULL || tp_strdiff (log_domain, exclude))
    {
      if (now.tv_sec == 0)
        g_get_current_time (&now);

      g_idle_add_full (G_PRIORITY_HIGH, tp_debug_sender_idle,
          debug_message_new (&now, log_domain, log_level, message),
          NULL);
    }
}

/**
 * tp_debug_sender_set_timestamps:
 * @self: a #TpDebugSender
 * @maybe: whether to display message timestamps
 *
 * If the log handler is tp_debug_sender_log_handler() then calling
 * this function with %TRUE on the debug sender will prepend the
 * message to be printed to stdout with the UTC time (currently in ISO
 * 8601 format, with microsecond resolution). This is equivalent to
 * using tp_debug_timestamped_log_handler() as the log handler, but
 * also logging to the debug sender.
 *
 * Since: 0.15.5
 */
void
tp_debug_sender_set_timestamps (TpDebugSender *self,
    gboolean maybe)
{
  g_return_if_fail (TP_IS_DEBUG_SENDER (self));

  self->priv->timestamps = maybe;
}
