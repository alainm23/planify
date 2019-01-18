/*
 * Copyright (C) 2007-2010 Collabora Ltd.
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
 *       Xavier Claessens <xavier.claessens@collabora.co.uk>
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <glib.h>
#include <glib/gi18n.h>
#include <gio/gio.h>
#include <telepathy-glib/telepathy-glib.h>

#include "tp-lowlevel.h"

static void
set_contact_alias_cb (TpConnection *conn,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *simple = G_SIMPLE_ASYNC_RESULT (user_data);

  if (error != NULL)
    {
      g_simple_async_result_set_from_error (simple, error);
    }

  g_simple_async_result_complete (simple);
}

/**
 * folks_tp_lowlevel_connection_set_contact_alias_async:
 * @conn: the connection to use
 * @handle: handle of the contact whose alias is to be changed
 * @alias: new human-readable alias for the contact
 * @callback: function to call on completion
 * @user_data: user data to pass to @callback
 *
 * Change the alias of the contact identified by @handle to @alias.
 */
void
folks_tp_lowlevel_connection_set_contact_alias_async (
    TpConnection *conn,
    guint handle,
    const gchar *alias,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  GHashTable *ht;

  ht = g_hash_table_new_full (g_direct_hash, g_direct_equal, NULL, g_free);
  g_hash_table_insert (ht, GUINT_TO_POINTER (handle), g_strdup (alias));

  result = g_simple_async_result_new (G_OBJECT (conn), callback, user_data,
      folks_tp_lowlevel_connection_set_contact_alias_finish);

  tp_cli_connection_interface_aliasing_call_set_aliases (conn, -1,
      ht, set_contact_alias_cb, g_object_ref (result), g_object_unref,
      G_OBJECT (conn));

  g_object_unref (result);
  g_hash_table_destroy (ht);
}

/**
 * folks_tp_lowlevel_connection_set_contact_alias_finish:
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finish an asynchronous call to
 * folks_tp_lowlevel_connection-set_contact_alias_async().
 */
void
folks_tp_lowlevel_connection_set_contact_alias_finish (
    GAsyncResult *result,
    GError **error)
{
  GSimpleAsyncResult *simple = G_SIMPLE_ASYNC_RESULT (result);
  TpConnection *conn;

  g_return_if_fail (G_IS_SIMPLE_ASYNC_RESULT (simple));

  conn = TP_CONNECTION (g_async_result_get_source_object (result));
  g_return_if_fail (TP_IS_CONNECTION (conn));

  g_return_if_fail (g_simple_async_result_is_valid (result,
      G_OBJECT (conn),
      folks_tp_lowlevel_connection_set_contact_alias_finish));

  g_simple_async_result_propagate_error (simple, error);
}
