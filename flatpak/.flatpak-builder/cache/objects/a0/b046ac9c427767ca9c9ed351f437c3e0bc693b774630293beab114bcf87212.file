/*
 * base-media-call-channel.h - Header for TpBaseMediaCallChannel
 * Copyright © 2011 Collabora Ltd.
 * @author Olivier Crete <olivier.crete@collabora.com>
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

#ifndef __TP_BASE_MEDIA_CALL_CHANNEL_H__
#define __TP_BASE_MEDIA_CALL_CHANNEL_H__

#include <telepathy-glib/base-call-channel.h>
#include <telepathy-glib/defs.h>

G_BEGIN_DECLS

typedef struct _TpBaseMediaCallChannel TpBaseMediaCallChannel;
typedef struct _TpBaseMediaCallChannelPrivate TpBaseMediaCallChannelPrivate;
typedef struct _TpBaseMediaCallChannelClass TpBaseMediaCallChannelClass;

typedef void (*TpBaseMediaCallChannelHoldStateChangedFunc) (
    TpBaseMediaCallChannel *self,
    TpLocalHoldState hold_state,
    TpLocalHoldStateReason hold_state_reason);
typedef void (*TpBaseMediaCallChannelVoidFunc) (TpBaseMediaCallChannel *self);

struct _TpBaseMediaCallChannelClass {
  /*<private>*/
  TpBaseCallChannelClass parent_class;

  /*< public >*/
  TpBaseMediaCallChannelHoldStateChangedFunc hold_state_changed;
  TpBaseMediaCallChannelVoidFunc accept;

  /*<private>*/
  gpointer future[4];
};

struct _TpBaseMediaCallChannel {
  /*<private>*/
  TpBaseCallChannel parent;

  TpBaseMediaCallChannelPrivate *priv;
};

_TP_AVAILABLE_IN_0_18
GType tp_base_media_call_channel_get_type (void);

/* TYPE MACROS */
#define TP_TYPE_BASE_MEDIA_CALL_CHANNEL \
  (tp_base_media_call_channel_get_type ())
#define TP_BASE_MEDIA_CALL_CHANNEL(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
   TP_TYPE_BASE_MEDIA_CALL_CHANNEL, TpBaseMediaCallChannel))
#define TP_BASE_MEDIA_CALL_CHANNEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), \
   TP_TYPE_BASE_MEDIA_CALL_CHANNEL, TpBaseMediaCallChannelClass))
#define TP_IS_BASE_MEDIA_CALL_CHANNEL(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_BASE_MEDIA_CALL_CHANNEL))
#define TP_IS_BASE_MEDIA_CALL_CHANNEL_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_BASE_MEDIA_CALL_CHANNEL))
#define TP_BASE_MEDIA_CALL_CHANNEL_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), \
   TP_TYPE_BASE_MEDIA_CALL_CHANNEL, TpBaseMediaCallChannelClass))

_TP_AVAILABLE_IN_0_18
TpLocalHoldState tp_base_media_call_channel_get_local_hold_state (
    TpBaseMediaCallChannel *channel, TpLocalHoldStateReason *reason);

G_END_DECLS

#endif /* #ifndef __TP_BASE_MEDIA_CALL_CHANNEL_H__*/
