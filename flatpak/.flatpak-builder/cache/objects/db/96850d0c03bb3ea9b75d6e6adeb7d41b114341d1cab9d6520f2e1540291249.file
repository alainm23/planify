/*<private_header>*/
/* TpProtocol - internal header
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

#ifndef TP_PROTOCOL_INTERNAL_H
#define TP_PROTOCOL_INTERNAL_H

#include <telepathy-glib/connection-manager.h>
#include <telepathy-glib/protocol.h>

G_BEGIN_DECLS

void _tp_connection_manager_param_free_contents (
    TpConnectionManagerParam *param);
void _tp_connection_manager_protocol_free_contents (
    TpConnectionManagerProtocol *proto);

TpConnectionManagerProtocol *_tp_protocol_get_struct (TpProtocol *self);

GHashTable *_tp_protocol_parse_manager_file (GKeyFile *file,
    const gchar *cm_name,
    const gchar *group,
    gchar **protocol_name);

G_END_DECLS

#endif
