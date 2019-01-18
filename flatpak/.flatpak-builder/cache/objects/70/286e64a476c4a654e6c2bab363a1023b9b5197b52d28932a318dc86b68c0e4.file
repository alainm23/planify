/*
 * debug-sender.h - header for Telepathy debug interface implementation
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

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_DEBUG_SENDER_H__
#define __TP_DEBUG_SENDER_H__

#include <glib-object.h>

#include <telepathy-glib/dbus-properties-mixin.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/svc-debug.h>

G_BEGIN_DECLS

typedef struct _TpDebugSender TpDebugSender;
typedef struct _TpDebugSenderClass TpDebugSenderClass;
typedef struct _TpDebugSenderPrivate TpDebugSenderPrivate;

#define TP_TYPE_DEBUG_SENDER tp_debug_sender_get_type()
#define TP_DEBUG_SENDER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_DEBUG_SENDER, TpDebugSender))
#define TP_DEBUG_SENDER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_DEBUG_SENDER, TpDebugSenderClass))
#define TP_IS_DEBUG_SENDER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_DEBUG_SENDER))
#define TP_IS_DEBUG_SENDER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_DEBUG_SENDER))
#define TP_DEBUG_SENDER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_DEBUG_SENDER, TpDebugSenderClass))

struct _TpDebugSender {
  /*<private>*/
  GObject parent;

  TpDebugSenderPrivate *priv;
};

struct _TpDebugSenderClass {
  /*<private>*/
  GObjectClass parent_class;
  TpDBusPropertiesMixinClass dbus_props_class;
  GCallback _padding[7];
  gpointer priv;
};

GType tp_debug_sender_get_type (void);

TpDebugSender *tp_debug_sender_dup (void) G_GNUC_WARN_UNUSED_RESULT;

void tp_debug_sender_add_message (TpDebugSender *self,
    GTimeVal *timestamp,
    const gchar *domain,
    GLogLevelFlags level,
    const gchar *string);

void tp_debug_sender_add_message_vprintf (TpDebugSender *self,
    GTimeVal *timestamp,
    gchar **formatted,
    const gchar *domain,
    GLogLevelFlags level,
    const gchar *format,
    va_list args);

void tp_debug_sender_add_message_printf (TpDebugSender *self,
    GTimeVal *timestamp,
    gchar **formatted,
    const gchar *domain,
    GLogLevelFlags level,
    const gchar *format,
    ...);

void tp_debug_sender_log_handler (const gchar *log_domain,
    GLogLevelFlags log_level, const gchar *message, gpointer exclude);

_TP_AVAILABLE_IN_0_16
void tp_debug_sender_set_timestamps (TpDebugSender *self, gboolean maybe);

G_END_DECLS

#endif /* __TP_DEBUG_SENDER_H__ */
