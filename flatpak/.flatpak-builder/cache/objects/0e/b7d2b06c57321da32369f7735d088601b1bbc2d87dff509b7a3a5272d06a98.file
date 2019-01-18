/*<private_header>*/
/*
 * TpChannel - proxy for a Telepathy channel (internals)
 *
 * Copyright (C) 2007-2008 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2007-2008 Nokia Corporation
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

#ifndef TP_CHANNEL_INTERNAL_H
#define TP_CHANNEL_INTERNAL_H

#include <telepathy-glib/channel.h>

G_BEGIN_DECLS

typedef void (*TpChannelProc) (TpChannel *self);

typedef struct {
    TpContact *actor_contact;
    TpHandle actor;
    TpChannelGroupChangeReason reason;
    gchar *message;
} LocalPendingInfo;

typedef struct _ContactsQueueItem ContactsQueueItem;

struct _TpChannelPrivate {
    gulong conn_invalidated_id;

    TpConnection *connection;

    /* GQueue of TpChannelProc */
    GQueue *introspect_needed;

    GQuark channel_type;
    TpHandleType handle_type;
    TpHandle handle;
    gchar *identifier;
    /* owned string (iface + "." + prop) => slice-allocated GValue */
    GHashTable *channel_properties;

    /* Set until introspection discovers which to use; both NULL after one has
     * been disconnected.
     */
    TpProxySignalConnection *members_changed_sig;
    TpProxySignalConnection *members_changed_detailed_sig;
    TpProxySignalConnection *self_handle_changed_sig;
    TpProxySignalConnection *self_contact_changed_sig;
    TpProxySignalConnection *handle_owners_changed_sig;
    TpProxySignalConnection *handle_owners_changed_detailed_sig;

    TpHandle group_self_handle;
    TpChannelGroupFlags group_flags;
    /* NULL if members not discovered yet */
    TpIntset *group_members;
    TpIntset *group_local_pending;
    TpIntset *group_remote_pending;
    /* (TpHandle => LocalPendingInfo), or NULL if members not discovered yet */
    GHashTable *group_local_pending_info;

    /* reason the self-handle left */
    GError *group_remove_error /* implicitly zero-initialized */ ;
    /* guint => guint, NULL if not discovered yet */
    GHashTable *group_handle_owners;

    /* reffed TpContact */
    TpContact *target_contact;
    TpContact *initiator_contact;
    TpContact *group_self_contact;
    /* TpHandle -> reffed TpContact */
    GHashTable *group_members_contacts;
    GHashTable *group_local_pending_contacts;
    GHashTable *group_remote_pending_contacts;
    /* the TpContact can be NULL if the owner is unknown */
    GHashTable *group_contact_owners;
    gboolean cm_too_old_for_contacts;

    /* Queue of GSimpleAsyncResult with ContactsQueueItem payload */
    GQueue *contacts_queue;
    /* Item currently being prepared, not part of contacts_queue anymore */
    GSimpleAsyncResult *current_contacts_queue_result;

    /* NULL, or TpHandle => TpChannelChatState;
     * if non-NULL, we're watching for ChatStateChanged */
    GHashTable *chat_states;

    /* These are really booleans, but gboolean is signed. Thanks, GLib */

    /* channel-ready */
    unsigned ready:1;
    /* Enough method calls have succeeded that we believe that the channel
     * exists (implied by ready) */
    unsigned exists:1;
    /* GetGroupFlags has returned */
    unsigned have_group_flags:1;

    TpChannelPasswordFlags password_flags;
};

/* channel.c internals */

void _tp_channel_continue_introspection (TpChannel *self);
void _tp_channel_abort_introspection (TpChannel *self,
    const gchar *debug,
    const GError *error);
GHashTable *_tp_channel_get_immutable_properties (TpChannel *self);

/* channel-group.c internals */

void _tp_channel_get_group_properties (TpChannel *self);

/* channel-contacts.c internals */

void _tp_channel_contacts_init (TpChannel *self);
void _tp_channel_contacts_group_init (TpChannel *self, GHashTable *identifiers);
void _tp_channel_contacts_members_changed (TpChannel *self,
    const GArray *added, const GArray *removed, const GArray *local_pending,
    const GArray *remote_pending, guint actor, GHashTable *details);
void _tp_channel_contacts_handle_owners_changed (TpChannel *self,
    GHashTable *added, const GArray *removed, GHashTable *identifiers);
void _tp_channel_contacts_self_contact_changed (TpChannel *self,
    guint self_handle, const gchar *identifier);
void _tp_channel_contacts_prepare_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);

void _tp_channel_contacts_queue_prepare_async (TpChannel *self,
    GPtrArray *contacts,
    GAsyncReadyCallback callback,
    gpointer user_data);
void _tp_channel_contacts_queue_prepare_by_id_async (TpChannel *self,
    GPtrArray *ids,
    GAsyncReadyCallback callback,
    gpointer user_data);
void _tp_channel_contacts_queue_prepare_by_handle_async (TpChannel *self,
    GArray *handles,
    GAsyncReadyCallback callback,
    gpointer user_data);
gboolean _tp_channel_contacts_queue_prepare_finish (TpChannel *self,
    GAsyncResult *result,
    GPtrArray **contacts,
    GError **error);

G_END_DECLS

#endif
