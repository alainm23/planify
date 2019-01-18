/*
 * Copyright (C) 2010 Collabora Ltd.
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 */

#ifndef FOLKS_TP_LOWLEVEL_H
#define FOLKS_TP_LOWLEVEL_H

#include <glib.h>
#include <glib-object.h>
#include <gio/gio.h>
#include <telepathy-glib/telepathy-glib.h>

G_BEGIN_DECLS

void
folks_tp_lowlevel_connection_set_contact_alias_async (
    TpConnection *conn,
    guint handle,
    const gchar *alias,
    GAsyncReadyCallback callback,
    gpointer user_data);

void
folks_tp_lowlevel_connection_set_contact_alias_finish (
    GAsyncResult *result,
    GError **error);

G_END_DECLS

#endif /* FOLKS_TP_LOWLEVEL_H */
