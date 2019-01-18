/*<private_header>*/
/*
 * Internals for TpCallChannel, TpCallContent and TpCallStream
 *
 * Copyright (C) 2011 Collabora Ltd. <http://www.collabora.co.uk/>
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

#ifndef TP_CALL_INTERNAL_H
#define TP_CALL_INTERNAL_H

#include <telepathy-glib/call-channel.h>

G_BEGIN_DECLS

/* implemented in call-channel.c */
TpCallStateReason *_tp_call_state_reason_new (const GValueArray *value_array);
TpCallStateReason *_tp_call_state_reason_ref (TpCallStateReason *r);
void _tp_call_state_reason_unref (TpCallStateReason *r);
GHashTable *_tp_call_members_convert_table (TpConnection *connection,
    GHashTable *table,
    GHashTable *identifiers);
GPtrArray *_tp_call_members_convert_array (TpConnection *connection,
    const GArray *array);

G_END_DECLS

#endif
