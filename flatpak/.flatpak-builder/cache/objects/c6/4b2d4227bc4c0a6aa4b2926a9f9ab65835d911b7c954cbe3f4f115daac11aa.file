/*
 * debug-message.h
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

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_DEBUG_MESSAGE_H__
#define __TP_DEBUG_MESSAGE_H__

#include <glib-object.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

typedef struct _TpDebugMessage TpDebugMessage;
typedef struct _TpDebugMessageClass TpDebugMessageClass;
typedef struct _TpDebugMessagePriv TpDebugMessagePriv;

struct _TpDebugMessageClass {
  /*<private>*/
  GObjectClass parent_class;
};

struct _TpDebugMessage {
  /*<private>*/
  GObject parent;
  TpDebugMessagePriv *priv;
};

_TP_AVAILABLE_IN_0_20
GType tp_debug_message_get_type (void);

/* TYPE MACROS */
#define TP_TYPE_DEBUG_MESSAGE \
  (tp_debug_message_get_type ())
#define TP_DEBUG_MESSAGE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), \
    TP_TYPE_DEBUG_MESSAGE, \
    TpDebugMessage))
#define TP_DEBUG_MESSAGE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), \
    TP_TYPE_DEBUG_MESSAGE, \
    TpDebugMessageClass))
#define TP_IS_DEBUG_MESSAGE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), \
    TP_TYPE_DEBUG_MESSAGE))
#define TP_IS_DEBUG_MESSAGE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), \
    TP_TYPE_DEBUG_MESSAGE))
#define TP_DEBUG_MESSAGE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), \
    TP_TYPE_DEBUG_MESSAGE, \
    TpDebugMessageClass))

_TP_AVAILABLE_IN_0_20
GDateTime * tp_debug_message_get_time (TpDebugMessage *self);
_TP_AVAILABLE_IN_0_20
const gchar * tp_debug_message_get_domain (TpDebugMessage *self);
_TP_AVAILABLE_IN_0_20
const gchar * tp_debug_message_get_category (TpDebugMessage *self);
_TP_AVAILABLE_IN_0_20
GLogLevelFlags tp_debug_message_get_level (TpDebugMessage *self);
_TP_AVAILABLE_IN_0_20
const gchar * tp_debug_message_get_message (TpDebugMessage *self);

G_END_DECLS

#endif /* #ifndef __TP_DEBUG_MESSAGE_H__*/
