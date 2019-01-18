/*
 * room-info.c
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

#include "room-info.h"
#include "room-info-internal.h"

#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/util.h>

/**
 * SECTION: room-info
 * @title: TpRoomInfo
 * @short_description: a room found by #TpRoomList
 *
 * #TpRoomInfo represents a room found during a room listing using
 * #TpRoomList.
 *
 * See also: #TpRoomList
 */

/**
 * TpRoomInfo:
 *
 * Data structure representing a #TpRoomInfo.
 *
 * Since: 0.19.0
 */

/**
 * TpRoomInfoClass:
 *
 * The class of a #TpRoomInfo.
 *
 * Since: 0.19.0
 */

G_DEFINE_TYPE (TpRoomInfo, tp_room_info, G_TYPE_OBJECT)

struct _TpRoomInfoPriv {
  TpHandle handle;
  gchar *channel_type;
  GHashTable *info;
};

static void
tp_room_info_finalize (GObject *object)
{
  TpRoomInfo *self = TP_ROOM_INFO (object);
  void (*chain_up) (GObject *) =
      ((GObjectClass *) tp_room_info_parent_class)->finalize;

  g_free (self->priv->channel_type);
  g_hash_table_unref (self->priv->info);

  if (chain_up != NULL)
    chain_up (object);
}

static void
tp_room_info_class_init (
    TpRoomInfoClass *klass)
{
  GObjectClass *oclass = G_OBJECT_CLASS (klass);

  oclass->finalize = tp_room_info_finalize;

  g_type_class_add_private (klass, sizeof (TpRoomInfoPriv));
}

static void
tp_room_info_init (TpRoomInfo *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self,
      TP_TYPE_ROOM_INFO, TpRoomInfoPriv);
}

TpRoomInfo *
_tp_room_info_new (GValueArray *dbus_struct)
{
  TpRoomInfo *room;
  const gchar *channel_type;
  GHashTable *info;

  g_return_val_if_fail (dbus_struct != NULL, NULL);
  g_return_val_if_fail (dbus_struct->n_values == 3, NULL);

  /* We don't want to expose the GValueArray in the API so it's not
   * a GObject property. */
  room = g_object_new (TP_TYPE_ROOM_INFO,
      NULL);

  tp_value_array_unpack (dbus_struct, 3,
      &room->priv->handle,
      &channel_type,
      &info);
  room->priv->channel_type = g_strdup (channel_type);
  room->priv->info = g_hash_table_new_full (g_str_hash, g_str_equal,
      g_free, (GDestroyNotify) tp_g_value_slice_free);
  tp_g_hash_table_update (room->priv->info, info,
      (GBoxedCopyFunc) g_strdup,
      (GBoxedCopyFunc) tp_g_value_slice_dup);

  return room;
}

/**
 * tp_room_info_get_handle:
 * @self: a #TpRoomInfo
 *
 * <!-- -->
 *
 * Returns: the #TpHandle of the room
 *
 * Since: 0.19.0
 */
TpHandle
tp_room_info_get_handle (TpRoomInfo *self)
{
  return self->priv->handle;
}

/**
 * tp_room_info_get_channel_type:
 * @self: a #TpRoomInfo
 *
 * <!-- -->
 *
 * Returns: a string representing the D-Bus interface name of
 * the channel type of the room
 *
 * Since: 0.19.0
 */
const gchar *
tp_room_info_get_channel_type (TpRoomInfo *self)
{
  return self->priv->channel_type;
}

/**
 * tp_room_info_get_handle_name:
 * @self: a #TpRoomInfo
 *
 * <!-- -->
 *
 * Returns: the identifier of the room (as would be returned
 * by inspecting the #TpHandle returned by tp_room_info_get_handle())
 *
 * Since: 0.19.0
 */
const gchar *
tp_room_info_get_handle_name (TpRoomInfo *self)
{
  return tp_asv_get_string (self->priv->info, "handle-name");
}

/**
 * tp_room_info_get_name:
 * @self: a #TpRoomInfo
 *
 * <!-- -->
 *
 * Returns: the human-readable name of the room if different
 * from the handle
 *
 * Since: 0.19.0
 */
const gchar *
tp_room_info_get_name (TpRoomInfo *self)
{
  return tp_asv_get_string (self->priv->info, "name");
}

/**
 * tp_room_info_get_description:
 * @self: a #TpRoomInfo
 *
 * <!-- -->
 *
 * Returns: a description of the room's overall purpose
 *
 * Since: 0.19.0
 */
const gchar *
tp_room_info_get_description (TpRoomInfo *self)
{
  return tp_asv_get_string (self->priv->info, "description");
}

/**
 * tp_room_info_get_subject:
 * @self: a #TpRoomInfo
 *
 * <!-- -->
 *
 * Returns: the current subject of conversation in the room
 *
 * Since: 0.19.0
 */
const gchar *
tp_room_info_get_subject (TpRoomInfo *self)
{
  return tp_asv_get_string (self->priv->info, "subject");
}

/**
 * tp_room_info_get_members_count:
 * @self: a #TpRoomInfo
 * @known: either %NULL, or a location in which to store %TRUE if the
 * returned value is meaningful
 *
 * <!-- -->
 *
 * Returns: the number of members in the room
 *
 * Since: 0.19.0
 */
guint
tp_room_info_get_members_count (TpRoomInfo *self,
    gboolean *known)
{
  return tp_asv_get_uint32 (self->priv->info, "members", known);
}

/**
 * tp_room_info_get_requires_password:
 * @self: a #TpRoomInfo
 * @known: either %NULL, or a location in which to store %TRUE if the
 * returned value is meaningful
 *
 * <!-- -->
 *
 * Returns: %TRUE if the room requires a password to enter
 *
 * Since: 0.19.0
 */
gboolean
tp_room_info_get_requires_password (TpRoomInfo *self,
    gboolean *known)
{
  return tp_asv_get_boolean (self->priv->info, "password", known);
}

/**
 * tp_room_info_get_invite_only:
 * @self: a #TpRoomInfo
 * @known: either %NULL, or a location in which to store %TRUE if the
 * returned value is meaningful
 *
 * <!-- -->
 *
 * Returns: %TRUE if you cannot join the room, but must be invited
 *
 * Since: 0.19.0
 */
gboolean
tp_room_info_get_invite_only (TpRoomInfo *self,
    gboolean *known)
{
  return tp_asv_get_boolean (self->priv->info, "invite-only", known);
}

/**
 * tp_room_info_get_room_id:
 * @self: a #TpRoomInfo
 *
 * <!-- -->
 *
 * Returns: the human-readable identifier of the room
 *
 * Since: 0.19.0
 */
const gchar *
tp_room_info_get_room_id (TpRoomInfo *self)
{
  return tp_asv_get_string (self->priv->info, "room-id");
}

/**
 * tp_room_info_get_server:
 * @self: a #TpRoomInfo
 *
 * <!-- -->
 *
 * Returns: the DNS name of the server hosting the room
 *
 * Since: 0.19.0
 */
const gchar *
tp_room_info_get_server (TpRoomInfo *self)
{
  return tp_asv_get_string (self->priv->info, "server");
}
