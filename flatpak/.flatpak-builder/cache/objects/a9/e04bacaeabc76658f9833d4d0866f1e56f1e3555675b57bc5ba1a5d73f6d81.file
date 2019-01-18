/*
 * media-interfaces.h - proxies for Telepathy media session/stream handlers
 *
 * Copyright (C) 2007 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2007 Nokia Corporation
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

#ifndef __TP_MEDIA_INTERFACES_H__
#define __TP_MEDIA_INTERFACES_H__

#include <telepathy-glib/defs.h>
#include <telepathy-glib/proxy.h>

G_BEGIN_DECLS

typedef struct _TpMediaStreamHandler TpMediaStreamHandler;
typedef struct _TpMediaStreamHandlerPrivate TpMediaStreamHandlerPrivate;
typedef struct _TpMediaStreamHandlerClass TpMediaStreamHandlerClass;

GType tp_media_stream_handler_get_type (void);

typedef struct _TpMediaSessionHandler TpMediaSessionHandler;
typedef struct _TpMediaSessionHandlerPrivate TpMediaSessionHandlerPrivate;
typedef struct _TpMediaSessionHandlerClass TpMediaSessionHandlerClass;

GType tp_media_session_handler_get_type (void);

/* TYPE MACROS */
#define TP_TYPE_MEDIA_STREAM_HANDLER \
  (tp_media_stream_handler_get_type ())
#define TP_MEDIA_STREAM_HANDLER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_MEDIA_STREAM_HANDLER, \
                              TpMediaStreamHandler))
#define TP_MEDIA_STREAM_HANDLER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), TP_TYPE_MEDIA_STREAM_HANDLER, \
                           TpMediaStreamHandlerClass))
#define TP_IS_MEDIA_STREAM_HANDLER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_MEDIA_STREAM_HANDLER))
#define TP_IS_MEDIA_STREAM_HANDLER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_MEDIA_STREAM_HANDLER))
#define TP_MEDIA_STREAM_HANDLER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_MEDIA_STREAM_HANDLER, \
                              TpMediaStreamHandlerClass))

#define TP_TYPE_MEDIA_SESSION_HANDLER \
  (tp_media_session_handler_get_type ())
#define TP_MEDIA_SESSION_HANDLER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_MEDIA_SESSION_HANDLER, \
                              TpMediaSessionHandler))
#define TP_MEDIA_SESSION_HANDLER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), TP_TYPE_MEDIA_SESSION_HANDLER, \
                           TpMediaSessionHandlerClass))
#define TP_IS_MEDIA_SESSION_HANDLER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_MEDIA_SESSION_HANDLER))
#define TP_IS_MEDIA_SESSION_HANDLER_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_MEDIA_SESSION_HANDLER))
#define TP_MEDIA_SESSION_HANDLER_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_MEDIA_SESSION_HANDLER, \
                              TpMediaSessionHandlerClass))

TpMediaSessionHandler *tp_media_session_handler_new (TpDBusDaemon *dbus,
    const gchar *unique_name, const gchar *object_path, GError **error)
  G_GNUC_WARN_UNUSED_RESULT;

TpMediaStreamHandler *tp_media_stream_handler_new (TpDBusDaemon *dbus,
    const gchar *unique_name, const gchar *object_path, GError **error)
  G_GNUC_WARN_UNUSED_RESULT;

void tp_media_session_handler_init_known_interfaces (void);
void tp_media_stream_handler_init_known_interfaces (void);

G_END_DECLS

#include <telepathy-glib/_gen/tp-cli-media-session-handler.h>
#include <telepathy-glib/_gen/tp-cli-media-stream-handler.h>

#endif
