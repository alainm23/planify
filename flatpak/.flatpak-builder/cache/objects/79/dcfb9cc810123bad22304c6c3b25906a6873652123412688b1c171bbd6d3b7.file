/*
 * debug-message.c
 *
 * Copyright (C) 2012 Collabora Ltd. <http://www.collabora.co.uk/>
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

#include "debug-message.h"
#include "debug-message-internal.h"

#include <telepathy-glib/telepathy-glib.h>

/**
 * SECTION: debug-message
 * @title: TpDebugMessage
 * @short_description: a debug message
 *
 * #TpDebugMessage is a small object used to represent a debug message receive
 * from a Telepathy component using #TpDebugClient.
 *
 * See also: #TpDebugClient
 */

/**
 * TpDebugMessage:
 *
 * Data structure representing a #TpDebugMessage.
 *
 * Since: 0.19.0
 */

/**
 * TpDebugMessageClass:
 *
 * The class of a #TpDebugMessage.
 *
 * Since: 0.19.0
 */

G_DEFINE_TYPE (TpDebugMessage, tp_debug_message, G_TYPE_OBJECT)

enum {
  PROP_TIME = 1,
  PROP_DOMAIN,
  PROP_CATEGORY,
  PROP_LEVEL,
  PROP_MESSAGE,
  LAST_PROPERTY,
};

struct _TpDebugMessagePriv {
  GDateTime *time;
  gchar *domain;
  gchar *category;
  GLogLevelFlags level;
  gchar *message;
};

static void
tp_debug_message_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpDebugMessage *self = TP_DEBUG_MESSAGE (object);

  switch (property_id)
    {
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
        break;
      case PROP_TIME:
        g_value_set_boxed (value, self->priv->time);
        break;
      case PROP_DOMAIN:
        g_value_set_string (value, self->priv->domain);
        break;
      case PROP_CATEGORY:
        g_value_set_string (value, self->priv->category);
        break;
      case PROP_LEVEL:
        g_value_set_uint (value, self->priv->level);
        break;
      case PROP_MESSAGE:
        g_value_set_string (value, self->priv->message);
        break;
    }
}

static void
tp_debug_message_finalize (GObject *object)
{
  TpDebugMessage *self = TP_DEBUG_MESSAGE (object);
  void (*chain_up) (GObject *) =
      ((GObjectClass *) tp_debug_message_parent_class)->finalize;

  g_free (self->priv->domain);
  g_free (self->priv->category);
  g_free (self->priv->message);

  if (chain_up != NULL)
    chain_up (object);
}

static void
tp_debug_message_class_init (
    TpDebugMessageClass *klass)
{
  GObjectClass *oclass = G_OBJECT_CLASS (klass);
  GParamSpec *spec;

  oclass->get_property = tp_debug_message_get_property;
  oclass->finalize = tp_debug_message_finalize;

  /**
   * TpDebugMessage:time:
   *
   * Timestamp of the debug message.
   *
   * Since: 0.19.0
   */
  spec = g_param_spec_boxed ("time", "time",
      "Time",
      G_TYPE_DATE_TIME,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (oclass, PROP_TIME, spec);

  /**
   * TpDebugMessage:domain:
   *
   * Domain of the debug message.
   *
   * Since: 0.19.0
   */
  spec = g_param_spec_string ("domain", "domain",
      "Domain",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (oclass, PROP_DOMAIN, spec);

  /**
   * TpDebugMessage:category:
   *
   * Category of the debug message, or %NULL if none was specified.
   *
   * Since: 0.19.0
   */
  spec = g_param_spec_string ("category", "category",
      "Category",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (oclass, PROP_CATEGORY, spec);

  /**
   * TpDebugMessage:level:
   *
   * A #GLogLevelFlags representing the level of the debug message.
   *
   * Since: 0.19.0
   */
  spec = g_param_spec_uint ("level", "level",
      "Level",
      0, G_LOG_LEVEL_MASK, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (oclass, PROP_LEVEL, spec);

  /**
   * TpDebugMessage:message:
   *
   * Text of the debug message, stripped from its trailing whitespaces.
   *
   * Since: 0.19.0
   */
  spec = g_param_spec_string ("message", "message",
      "Message",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (oclass, PROP_MESSAGE, spec);

  g_type_class_add_private (klass, sizeof (TpDebugMessagePriv));
}

static void
tp_debug_message_init (TpDebugMessage *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_DEBUG_MESSAGE, TpDebugMessagePriv);
}

static GLogLevelFlags
debug_level_to_log_level_flags (TpDebugLevel level)
{
  if (level == TP_DEBUG_LEVEL_ERROR)
    return G_LOG_LEVEL_ERROR;
  else if (level == TP_DEBUG_LEVEL_CRITICAL)
    return G_LOG_LEVEL_CRITICAL;
  else if (level == TP_DEBUG_LEVEL_WARNING)
    return G_LOG_LEVEL_WARNING;
  else if (level == TP_DEBUG_LEVEL_MESSAGE)
    return G_LOG_LEVEL_MESSAGE;
  else if (level == TP_DEBUG_LEVEL_INFO)
    return G_LOG_LEVEL_INFO;
  else if (level == TP_DEBUG_LEVEL_DEBUG)
    return G_LOG_LEVEL_DEBUG;

  /* Fall back to DEBUG if all else fails */
  return TP_DEBUG_LEVEL_DEBUG;
}

TpDebugMessage *
_tp_debug_message_new (gdouble timestamp,
    const gchar *domain,
    TpDebugLevel level,
    const gchar *message)
{
  TpDebugMessage *self;
  GTimeVal tv;

  g_return_val_if_fail (domain != NULL, NULL);
  g_return_val_if_fail (message != NULL, NULL);

  self = g_object_new (TP_TYPE_DEBUG_MESSAGE,
      NULL);

  tv.tv_sec = (glong) timestamp;
  tv.tv_usec = ((timestamp - (int) timestamp) * 1e6);

  if (g_strrstr (domain, "/"))
    {
      gchar **parts = g_strsplit (domain, "/", 2);
      self->priv->domain = g_strdup (parts[0]);
      self->priv->category = g_strdup (parts[1]);
      g_strfreev (parts);
    }
  else
    {
      self->priv->domain = g_strdup (domain);
      self->priv->category = NULL;
    }

  self->priv->time = g_date_time_new_from_timeval_utc (&tv);

  self->priv->level = debug_level_to_log_level_flags (level);
  self->priv->message = g_strdup (message);
  g_strchomp (self->priv->message);

  return self;
}

/**
 * tp_debug_message_get_time:
 * @self: a #TpDebugMessage
 *
 * Return the #TpDebugMessage:time property
 *
 * Returns: (transfer none): the value of #TpDebugMessage:time property
 *
 * Since: 0.19.0
 */
GDateTime *
tp_debug_message_get_time (TpDebugMessage *self)
{
  return self->priv->time;
}

/**
 * tp_debug_message_get_domain:
 * @self: a #TpDebugMessage
 *
 * Return the #TpDebugMessage:domain property
 *
 * Returns: the value of #TpDebugMessage:domain property
 *
 * Since: 0.19.0
 */
const gchar *
tp_debug_message_get_domain (TpDebugMessage *self)
{
  return self->priv->domain;
}

/**
 * tp_debug_message_get_category:
 * @self: a #TpDebugMessage
 *
 * Return the #TpDebugMessage:category property
 *
 * Returns: the value of #TpDebugMessage:category property
 *
 * Since: 0.19.0
 */
const char *
tp_debug_message_get_category (TpDebugMessage *self)
{
  return self->priv->category;
}

/**
 * tp_debug_message_get_level:
 * @self: a #TpDebugMessage
 *
 * Return the #TpDebugMessage:level property
 *
 * Returns: the value of #TpDebugMessage:level property
 *
 * Since: 0.19.0
 */
GLogLevelFlags
tp_debug_message_get_level (TpDebugMessage *self)
{
  return self->priv->level;
}

/**
 * tp_debug_message_get_message:
 * @self: a #TpDebugMessage
 *
 * Return the #TpDebugMessage:message property
 *
 * Returns: the value of #TpDebugMessage:message property
 *
 * Since: 0.19.0
 */
const gchar *
tp_debug_message_get_message (TpDebugMessage *self)
{
  return self->priv->message;
}
