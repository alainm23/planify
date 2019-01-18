/*
 * channel-manager.h - factory and manager for channels relating to a
 *  particular protocol feature
 *
 * Copyright (C) 2008 Collabora Ltd.
 * Copyright (C) 2008 Nokia Corporation
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

#ifndef TP_CHANNEL_MANAGER_H
#define TP_CHANNEL_MANAGER_H

#include <glib-object.h>

#include <telepathy-glib/defs.h>
#include <telepathy-glib/exportable-channel.h>

G_BEGIN_DECLS

#define TP_TYPE_CHANNEL_MANAGER (tp_channel_manager_get_type ())

#define TP_CHANNEL_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), \
  TP_TYPE_CHANNEL_MANAGER, TpChannelManager))

#define TP_IS_CHANNEL_MANAGER(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), \
  TP_TYPE_CHANNEL_MANAGER))

#define TP_CHANNEL_MANAGER_GET_INTERFACE(obj) \
  (G_TYPE_INSTANCE_GET_INTERFACE ((obj), \
  TP_TYPE_CHANNEL_MANAGER, TpChannelManagerIface))

typedef struct _TpChannelManager TpChannelManager;
typedef struct _TpChannelManagerIface TpChannelManagerIface;


/* virtual methods */

typedef void (*TpChannelManagerForeachChannelFunc) (
    TpChannelManager *manager, TpExportableChannelFunc func,
    gpointer user_data);

void tp_channel_manager_foreach_channel (TpChannelManager *manager,
    TpExportableChannelFunc func, gpointer user_data);


typedef void (*TpChannelManagerChannelClassFunc) (
    TpChannelManager *manager,
    GHashTable *fixed_properties,
    const gchar * const *allowed_properties,
    gpointer user_data);

typedef void (*TpChannelManagerForeachChannelClassFunc) (
    TpChannelManager *manager, TpChannelManagerChannelClassFunc func,
    gpointer user_data);

void tp_channel_manager_foreach_channel_class (
    TpChannelManager *manager,
    TpChannelManagerChannelClassFunc func, gpointer user_data);

typedef void (*TpChannelManagerTypeChannelClassFunc) (GType type,
    GHashTable *fixed_properties,
    const gchar * const *allowed_properties,
    gpointer user_data);

typedef void (*TpChannelManagerTypeForeachChannelClassFunc) (
    GType type, TpChannelManagerTypeChannelClassFunc func,
    gpointer user_data);

void tp_channel_manager_type_foreach_channel_class (GType type,
    TpChannelManagerTypeChannelClassFunc func, gpointer user_data);


typedef gboolean (*TpChannelManagerRequestFunc) (
    TpChannelManager *manager, gpointer request_token,
    GHashTable *request_properties);

gboolean tp_channel_manager_create_channel (TpChannelManager *manager,
    gpointer request_token, GHashTable *request_properties);

gboolean tp_channel_manager_request_channel (TpChannelManager *manager,
    gpointer request_token, GHashTable *request_properties);

gboolean tp_channel_manager_ensure_channel (TpChannelManager *manager,
    gpointer request_token, GHashTable *request_properties);


struct _TpChannelManagerIface {
    GTypeInterface parent;

    TpChannelManagerForeachChannelFunc foreach_channel;

    TpChannelManagerForeachChannelClassFunc foreach_channel_class;

    TpChannelManagerRequestFunc create_channel;
    TpChannelManagerRequestFunc request_channel;
    TpChannelManagerRequestFunc ensure_channel;

    TpChannelManagerTypeForeachChannelClassFunc type_foreach_channel_class;

    /*<private>*/
    /* We know that these two methods will be added in the near future, so
     * reserve extra space for them.
     */
    GCallback _reserved_for_foreach_contact_channel_class;
    GCallback _reserved_for_add_cap;

    GCallback _future[7];
};


GType tp_channel_manager_get_type (void);


/* signal emission */

void tp_channel_manager_emit_new_channel (gpointer instance,
    TpExportableChannel *channel, GSList *request_tokens);

_TP_DEPRECATED_IN_0_20
void tp_channel_manager_emit_new_channels (gpointer instance,
    GHashTable *channels);

void tp_channel_manager_emit_channel_closed (gpointer instance,
    const gchar *path);
void tp_channel_manager_emit_channel_closed_for_object (gpointer instance,
    TpExportableChannel *channel);

void tp_channel_manager_emit_request_already_satisfied (
    gpointer instance, gpointer request_token,
    TpExportableChannel *channel);

void tp_channel_manager_emit_request_failed (gpointer instance,
    gpointer request_token, GQuark domain, gint code, const gchar *message);
void tp_channel_manager_emit_request_failed_printf (gpointer instance,
    gpointer request_token, GQuark domain, gint code, const gchar *format,
    ...) G_GNUC_PRINTF (5, 6);


/* helper functions */

gboolean tp_channel_manager_asv_has_unknown_properties (GHashTable *properties,
    const gchar * const *fixed, const gchar * const *allowed, GError **error);

G_END_DECLS

#endif
