/*
 * room-info.h
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

#ifndef __TP_ROOM_INFO_H__
#define __TP_ROOM_INFO_H__

#include <glib-object.h>

#include <telepathy-glib/defs.h>
#include <telepathy-glib/handle.h>

G_BEGIN_DECLS

typedef struct _TpRoomInfo TpRoomInfo;
typedef struct _TpRoomInfoClass TpRoomInfoClass;
typedef struct _TpRoomInfoPriv TpRoomInfoPriv;

struct _TpRoomInfoClass {
  /*<private>*/
  GObjectClass parent_class;
};

struct _TpRoomInfo {
  /*<private>*/
  GObject parent;
  TpRoomInfoPriv *priv;
};

_TP_AVAILABLE_IN_0_20
GType tp_room_info_get_type (void);

/* TYPE MACROS */
#define TP_TYPE_ROOM_INFO \
  (tp_room_info_get_type ())
#define TP_ROOM_INFO(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), \
    TP_TYPE_ROOM_INFO, \
    TpRoomInfo))
#define TP_ROOM_INFO_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), \
    TP_TYPE_ROOM_INFO, \
    TpRoomInfoClass))
#define TP_IS_ROOM_INFO(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), \
    TP_TYPE_ROOM_INFO))
#define TP_IS_ROOM_INFO_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), \
    TP_TYPE_ROOM_INFO))
#define TP_ROOM_INFO_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), \
    TP_TYPE_ROOM_INFO, \
    TpRoomInfoClass))

_TP_AVAILABLE_IN_0_20
TpHandle tp_room_info_get_handle (TpRoomInfo *self);
_TP_AVAILABLE_IN_0_20
const gchar * tp_room_info_get_channel_type (TpRoomInfo *self);
_TP_AVAILABLE_IN_0_20
const gchar *tp_room_info_get_handle_name (TpRoomInfo *self);
_TP_AVAILABLE_IN_0_20
const gchar *tp_room_info_get_name (TpRoomInfo *self);
_TP_AVAILABLE_IN_0_20
const gchar *tp_room_info_get_description (TpRoomInfo *self);
_TP_AVAILABLE_IN_0_20
const gchar *tp_room_info_get_subject (TpRoomInfo *self);
_TP_AVAILABLE_IN_0_20
guint tp_room_info_get_members_count (TpRoomInfo *self,
    gboolean *known);
_TP_AVAILABLE_IN_0_20
gboolean tp_room_info_get_requires_password (TpRoomInfo *self,
    gboolean *known);
_TP_AVAILABLE_IN_0_20
gboolean tp_room_info_get_invite_only (TpRoomInfo *self,
    gboolean *known);
_TP_AVAILABLE_IN_0_20
const gchar *tp_room_info_get_room_id (TpRoomInfo *self);
_TP_AVAILABLE_IN_0_20
const gchar *tp_room_info_get_server (TpRoomInfo *self);

G_END_DECLS

#endif /* #ifndef __TP_ROOM_INFO_H__*/
