/*<private_header>*/
/* Base class for Connection implementations
 *
 * Copyright © 2007-2010 Collabora Ltd.
 * Copyright © 2007-2009 Nokia Corporation
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

#ifndef __TP_BASE_CONNECTION_INTERNAL_H__
#define __TP_BASE_CONNECTION_INTERNAL_H__

#include <telepathy-glib/base-connection.h>

G_BEGIN_DECLS

void _tp_base_connection_set_handle_repo (TpBaseConnection *self,
    TpHandleType handle_type,
    TpHandleRepoIface *handle_repo);

gpointer _tp_base_connection_find_channel_manager (TpBaseConnection *self,
    GType type);

G_END_DECLS

#endif
