/*<private_header>*/
/* Object representing a Telepathy contact (internal)
 *
 * Copyright © 2011 Collabora Ltd. <http://www.collabora.co.uk/>
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

#ifndef __TP_CONTACT_INTERNAL_H__
#define __TP_CONTACT_INTERNAL_H__

#include <telepathy-glib/contact.h>

G_BEGIN_DECLS

TpContact *_tp_contact_new (TpConnection *connection,
    TpHandle handle,
    const gchar *identifier);

gboolean _tp_contact_set_attributes (TpContact *contact,
    GHashTable *asv,
    guint n_features,
    const TpContactFeature *features,
    GError **error);

const gchar **_tp_contacts_bind_to_signals (TpConnection *connection,
    guint n_features,
    const TpContactFeature *features);

void _tp_contact_set_subscription_states (TpContact *self,
    GValueArray *value_array);

void _tp_contact_set_is_blocked (TpContact *self,
    gboolean is_blocked);

void _tp_contact_connection_disposed (TpContact *contact);

G_END_DECLS

#endif
