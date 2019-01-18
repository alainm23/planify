/*
 * base-room-config.h - header for Channel.I.RoomConfig1 implementation
 * Copyright ©2011 Collabora Ltd.
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
 */

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef TP_BASE_ROOM_CONFIG_H
#define TP_BASE_ROOM_CONFIG_H

#include <glib-object.h>
#include <telepathy-glib/base-channel.h>
#include <telepathy-glib/defs.h>
#include <telepathy-glib/_gen/genums.h>

typedef struct _TpBaseRoomConfig TpBaseRoomConfig;
typedef struct _TpBaseRoomConfigClass TpBaseRoomConfigClass;
typedef struct _TpBaseRoomConfigPrivate TpBaseRoomConfigPrivate;

typedef void (*TpBaseRoomConfigUpdateAsync) (
    TpBaseRoomConfig *self,
    GHashTable *validated_properties,
    GAsyncReadyCallback callback,
    gpointer user_data);
typedef gboolean (*TpBaseRoomConfigUpdateFinish) (
    TpBaseRoomConfig *self,
    GAsyncResult *result,
    GError **error);

struct _TpBaseRoomConfigClass {
    /*< private >*/
    GObjectClass parent_class;

    /*< public >*/
    TpBaseRoomConfigUpdateAsync update_async;
    TpBaseRoomConfigUpdateFinish update_finish;
};

struct _TpBaseRoomConfig {
    /*< private >*/
    GObject parent;
    TpBaseRoomConfigPrivate *priv;
};

/* By an astonishing coincidence, the nicknames for this enum are the names of
 * corresponding D-Bus properties.
 */
typedef enum {
    TP_BASE_ROOM_CONFIG_ANONYMOUS = 0, /*< nick=Anonymous >*/
    TP_BASE_ROOM_CONFIG_INVITE_ONLY, /*< nick=InviteOnly >*/
    TP_BASE_ROOM_CONFIG_LIMIT, /*< nick=Limit >*/
    TP_BASE_ROOM_CONFIG_MODERATED, /*< nick=Moderated >*/
    TP_BASE_ROOM_CONFIG_TITLE, /*< nick=Title >*/
    TP_BASE_ROOM_CONFIG_DESCRIPTION, /*< nick=Description >*/
    TP_BASE_ROOM_CONFIG_PERSISTENT, /*< nick=Persistent >*/
    TP_BASE_ROOM_CONFIG_PRIVATE, /*< nick=Private >*/
    TP_BASE_ROOM_CONFIG_PASSWORD_PROTECTED, /*< nick=PasswordProtected >*/
    TP_BASE_ROOM_CONFIG_PASSWORD, /*< nick=Password >*/
    TP_BASE_ROOM_CONFIG_PASSWORD_HINT, /*< nick=PasswordHint >*/

    TP_NUM_BASE_ROOM_CONFIG_PROPERTIES /*< skip >*/
} TpBaseRoomConfigProperty;

_TP_AVAILABLE_IN_0_16
GType tp_base_room_config_get_type (void);

#define TP_TYPE_BASE_ROOM_CONFIG \
  (tp_base_room_config_get_type ())
#define TP_BASE_ROOM_CONFIG(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), TP_TYPE_BASE_ROOM_CONFIG, TpBaseRoomConfig))
#define TP_BASE_ROOM_CONFIG_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST((klass), TP_TYPE_BASE_ROOM_CONFIG,\
                           TpBaseRoomConfigClass))
#define TP_IS_BASE_ROOM_CONFIG(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE((obj), TP_TYPE_BASE_ROOM_CONFIG))
#define TP_IS_BASE_ROOM_CONFIG_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE((klass), TP_TYPE_BASE_ROOM_CONFIG))
#define TP_BASE_ROOM_CONFIG_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), TP_TYPE_BASE_ROOM_CONFIG, \
                              TpBaseRoomConfigClass))

_TP_AVAILABLE_IN_0_16
void tp_base_room_config_register_class (
    TpBaseChannelClass *base_channel_class);
_TP_AVAILABLE_IN_0_16
void tp_base_room_config_iface_init (
    gpointer g_iface,
    gpointer iface_data);

_TP_AVAILABLE_IN_0_16
TpBaseChannel *tp_base_room_config_dup_channel (
    TpBaseRoomConfig *self);

_TP_AVAILABLE_IN_0_16
void tp_base_room_config_set_can_update_configuration (
    TpBaseRoomConfig *self,
    gboolean can_update_configuration);

_TP_AVAILABLE_IN_0_16
void tp_base_room_config_set_property_mutable (
    TpBaseRoomConfig *self,
    TpBaseRoomConfigProperty property_id,
    gboolean is_mutable);

_TP_AVAILABLE_IN_0_16
void tp_base_room_config_emit_properties_changed (
    TpBaseRoomConfig *self);

_TP_AVAILABLE_IN_0_16
void tp_base_room_config_set_retrieved (
    TpBaseRoomConfig *self);

/* TYPE MACROS */

#endif /* TP_BASE_ROOM_CONFIG_H */
