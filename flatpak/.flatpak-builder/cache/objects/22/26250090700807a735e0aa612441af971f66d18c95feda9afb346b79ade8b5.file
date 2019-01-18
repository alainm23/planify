/*<private_header>*/
/* ContactList channel manager - internals (for use by our channels)
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

#ifndef __TP_BASE_CONTACT_LIST_INTERNAL_H__
#define __TP_BASE_CONTACT_LIST_INTERNAL_H__

#include <telepathy-glib/base-contact-list.h>

#include <telepathy-glib/enums.h>
#include <telepathy-glib/handle.h>

G_BEGIN_DECLS

/* elements 1, 2... of this enum must be kept in sync with elements 0, 1...
 * of the array in the .c */
typedef enum {
    INVALID_TP_LIST_HANDLE = 0,
    TP_LIST_HANDLE_SUBSCRIBE,
    TP_LIST_HANDLE_PUBLISH,
    TP_LIST_HANDLE_STORED,
    TP_LIST_HANDLE_DENY,
    TP_NUM_LIST_HANDLES
} TpListHandle;

TpChannelGroupFlags _tp_base_contact_list_get_list_flags (
    TpBaseContactList *self,
    TpHandle list);

TpChannelGroupFlags _tp_base_contact_list_get_group_flags (
    TpBaseContactList *self);

void _tp_base_contact_list_add_to_list (TpBaseContactList *self,
    TpHandle list,
    const GArray *contacts_arr,
    const gchar *message,
    DBusGMethodInvocation *context);

void _tp_base_contact_list_remove_from_list (TpBaseContactList *self,
    TpHandle list,
    const GArray *contacts_arr,
    const gchar *message,
    guint reason,
    DBusGMethodInvocation *context);

void _tp_base_contact_list_add_to_group (TpBaseContactList *self,
    TpHandle group,
    const GArray *contacts_arr,
    const gchar *message,
    DBusGMethodInvocation *context);

void _tp_base_contact_list_remove_from_group (TpBaseContactList *self,
    TpHandle group,
    const GArray *contacts_arr,
    const gchar *message,
    guint reason,
    DBusGMethodInvocation *context);

gboolean _tp_base_contact_list_delete_group_by_handle (
    TpBaseContactList *self,
    TpHandle group,
    GError **error);

char _tp_base_contact_list_presence_state_to_letter (TpSubscriptionState ps);

G_END_DECLS

#endif
