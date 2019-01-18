/*
 * room-list-channel.h - High level API for RoomList channels
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

#ifndef __TP_ROOM_LIST_H__
#define __TP_ROOM_LIST_H__

#include <telepathy-glib/channel.h>
#include <telepathy-glib/room-info.h>

G_BEGIN_DECLS

#define TP_TYPE_ROOM_LIST (tp_room_list_get_type ())
#define TP_ROOM_LIST(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TP_TYPE_ROOM_LIST, TpRoomList))
#define TP_ROOM_LIST_CLASS(obj) (G_TYPE_CHECK_CLASS_CAST ((obj), TP_TYPE_ROOM_LIST, TpRoomListClass))
#define TP_IS_ROOM_LIST(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TP_TYPE_ROOM_LIST))
#define TP_IS_ROOM_LIST_CLASS(obj) (G_TYPE_CHECK_CLASS_TYPE ((obj), TP_TYPE_ROOM_LIST))
#define TP_ROOM_LIST_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_ROOM_LIST, TpRoomListClass))

typedef struct _TpRoomList TpRoomList;
typedef struct _TpRoomListClass TpRoomListClass;
typedef struct _TpRoomListPrivate TpRoomListPrivate;

struct _TpRoomList
{
  /*<private>*/
  GObject parent;
  TpRoomListPrivate *priv;
};

struct _TpRoomListClass
{
  /*<private>*/
  GObjectClass parent_class;
  GCallback _padding[7];
};

GType tp_room_list_get_type (void);

void tp_room_list_new_async (TpAccount *account,
    const gchar *server,
    GAsyncReadyCallback callback,
    gpointer user_data);

TpRoomList * tp_room_list_new_finish (GAsyncResult *result,
    GError **error);

TpAccount * tp_room_list_get_account (TpRoomList *self);

const gchar * tp_room_list_get_server (TpRoomList *self);

gboolean tp_room_list_is_listing (TpRoomList *self);

void tp_room_list_start (TpRoomList *self);

G_END_DECLS

#endif
