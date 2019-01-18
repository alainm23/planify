/*
 * object for HandleChannels calls context
 *
 * Copyright © 2010 Collabora Ltd.
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

#ifndef __TP_HANDLE_CHANNELS_CONTEXT_H__
#define __TP_HANDLE_CHANNELS_CONTEXT_H__

#include <gio/gio.h>
#include <glib-object.h>

G_BEGIN_DECLS

typedef struct _TpHandleChannelsContext TpHandleChannelsContext;
typedef struct _TpHandleChannelsContextClass \
          TpHandleChannelsContextClass;
typedef struct _TpHandleChannelsContextPrivate \
          TpHandleChannelsContextPrivate;

GType tp_handle_channels_context_get_type (void);

#define TP_TYPE_HANDLE_CHANNELS_CONTEXT \
  (tp_handle_channels_context_get_type ())
#define TP_HANDLE_CHANNELS_CONTEXT(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_HANDLE_CHANNELS_CONTEXT, \
                               TpHandleChannelsContext))
#define TP_HANDLE_CHANNELS_CONTEXT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), TP_TYPE_HANDLE_CHANNELS_CONTEXT, \
                            TpHandleChannelsContextClass))
#define TP_IS_HANDLE_CHANNELS_CONTEXT(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_HANDLE_CHANNELS_CONTEXT))
#define TP_IS_HANDLE_CHANNELS_CONTEXT_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), TP_TYPE_HANDLE_CHANNELS_CONTEXT))
#define TP_HANDLE_CHANNELS_CONTEXT_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_HANDLE_CHANNELS_CONTEXT, \
                              TpHandleChannelsContextClass))

void tp_handle_channels_context_accept (
    TpHandleChannelsContext *self);

void tp_handle_channels_context_fail (
    TpHandleChannelsContext *self,
    const GError *error);

void tp_handle_channels_context_delay (
    TpHandleChannelsContext *self);

const GHashTable *tp_handle_channels_context_get_handler_info (
    TpHandleChannelsContext *self);

GList * tp_handle_channels_context_get_requests (
    TpHandleChannelsContext *self);

G_END_DECLS

#endif
