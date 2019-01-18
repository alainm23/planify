/*<private_header>*/
/*
 * TpConnection - proxy for a Telepathy connection (internals)
 *
 * Copyright (C) 2008 Collabora Ltd. <http://www.collabora.co.uk/>
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

#ifndef TP_CONNECTION_INTERNAL_H
#define TP_CONNECTION_INTERNAL_H

#include <telepathy-glib/capabilities.h>
#include <telepathy-glib/connection.h>
#include <telepathy-glib/contact.h>
#include <telepathy-glib/intset.h>

G_BEGIN_DECLS

typedef void (*TpConnectionProc) (TpConnection *self);

struct _TpConnectionPrivate {
    TpAccount *account;

    /* list of TpConnectionProc */
    GList *introspect_needed;

    gchar *cm_name;
    gchar *proto_name;

    TpHandle last_known_self_handle;
    TpContact *self_contact;
    TpConnectionStatus status;
    TpConnectionStatusReason status_reason;
    gchar *connection_error;
    /* a TP_HASH_TYPE_STRING_VARIANT_MAP */
    GHashTable *connection_error_details;

    /* GArray of GQuark */
    GArray *contact_attribute_interfaces;

    /* items are GQuarks that represent arguments to
     * Connection.AddClientInterests */
    TpIntset *interests;

    /* TpHandle => weak ref to TpContact */
    GHashTable *contacts;

    TpCapabilities *capabilities;
    /* Queue of owned GSimpleAsyncResult, each result being a pending call
     * started using _tp_connection_do_get_capabilities_async */
    GQueue capabilities_queue;

    TpAvatarRequirements *avatar_requirements;
    GArray *avatar_request_queue;
    guint avatar_request_idle_id;

    TpContactInfoFlags contact_info_flags;
    GList *contact_info_supported_fields;

    gint balance;
    guint balance_scale;
    gchar *balance_currency;
    gchar *balance_uri;

    /* ContactList properties */
    TpContactListState contact_list_state;
    gboolean contact_list_persists;
    gboolean can_change_contact_list;
    gboolean request_uses_message;
    /* TpHandle => ref to TpContact */
    GHashTable *roster;
    /* Queue of owned ContactsChangedItem */
    GQueue *contacts_changed_queue;
    gboolean roster_fetched;
    gboolean contact_list_properties_fetched;

    /* ContactGroups properties */
    gboolean disjoint_groups;
    TpContactMetadataStorageType group_storage;
    GPtrArray *contact_groups;
    gboolean groups_fetched;
    /* Queue of owned BlockedChangedItem */
    GQueue *blocked_changed_queue;

    /* ContactBlocking properies */
    TpContactBlockingCapabilities contact_blocking_capabilities;
    GPtrArray *blocked_contacts;
    gboolean blocked_contacts_fetched;

    /* Aliasing */
    TpConnectionAliasFlags alias_flags;

    TpProxyPendingCall *introspection_call;

    unsigned ready:1;
    unsigned ready_enough_for_contacts:1;
    unsigned has_immortal_handles:1;
    unsigned tracking_aliases_changed:1;
    unsigned tracking_avatar_updated:1;
    unsigned tracking_avatar_retrieved:1;
    unsigned tracking_presences_changed:1;
    unsigned tracking_presence_update:1;
    unsigned tracking_location_changed:1;
    unsigned tracking_contact_caps_changed:1;
    unsigned tracking_contact_info_changed:1;
    unsigned introspecting_after_connected:1;
    unsigned tracking_client_types_updated:1;
    unsigned introspecting_self_contact:1;
    unsigned tracking_contacts_changed:1;
    unsigned tracking_contact_groups_changed:1;
};

void _tp_connection_status_reason_to_gerror (TpConnectionStatusReason reason,
    TpConnectionStatus prev_status,
    const gchar **ret_str,
    GError **error);

/* Internal hook to break potential dependency loop between Connection and
 * Contacts */
void _tp_connection_get_capabilities_async (TpConnection *self,
    GAsyncReadyCallback callback,
    gpointer user_data);

gboolean _tp_connection_get_capabilities_finish (TpConnection *self,
    GAsyncResult *result, GError **error);

/* Those functions should be used only from contact.c, they are risky since they
 * could operate on incomplete contacts */
void _tp_connection_add_contact (TpConnection *self, TpHandle handle,
    TpContact *contact);
void _tp_connection_remove_contact (TpConnection *self, TpHandle handle,
    TpContact *contact);
TpContact *_tp_connection_lookup_contact (TpConnection *self, TpHandle handle);

void _tp_connection_set_account (TpConnection *self, TpAccount *account);

/* connection-contact-info.c */
void _tp_connection_prepare_contact_info_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);

TpContactInfoFieldSpec *_tp_contact_info_field_spec_new (const gchar *name,
    GStrv parameters, TpContactInfoFieldFlags flags, guint max);

/* connection-avatars.c */
void _tp_connection_prepare_avatar_requirements_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);

/* connection-contact-list.c */
void _tp_connection_prepare_contact_list_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);
void _tp_connection_prepare_contact_list_props_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);
void _tp_connection_prepare_contact_groups_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);
void _tp_connection_contacts_changed_queue_free (GQueue *queue);
void _tp_connection_blocked_changed_queue_free (GQueue *queue);

void _tp_connection_prepare_contact_blocking_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);

void _tp_connection_set_contact_blocked (TpConnection *self,
    TpContact *contact);

/* connection-aliasing.c */
void _tp_connection_prepare_aliasing_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data);

G_END_DECLS

#endif
