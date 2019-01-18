/* Async operations for TpContact
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

#include "config.h"

#include <telepathy-glib/contact-operations.h>

#include <telepathy-glib/connection-contact-list.h>

#define DEBUG_FLAG TP_DEBUG_CONTACTS
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/util-internal.h"

static void
generic_callback (TpConnection *self,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Operation failed: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
    }

  /* tp_cli callbacks can potentially be called in a re-entrant way,
   * so we can't necessarily complete @result without using an idle. */
  g_simple_async_result_complete_in_idle (result);
}

/* Small macro trick because DBus method is remove_contacts and in this
 * TpContact helper API we removed the redundant _contacts. */
#define tp_contact_remove_contacts_async tp_contact_remove_async

#define contact_list_generic_async(method, ...) \
  G_STMT_START { \
    GSimpleAsyncResult *result; \
    TpHandle handle; \
    GArray *handles; \
    \
    g_return_if_fail (TP_IS_CONTACT (self)); \
    \
    handle = tp_contact_get_handle (self); \
    handles = g_array_new (FALSE, FALSE, sizeof (TpHandle)); \
    g_array_append_val (handles, handle); \
    \
    result = g_simple_async_result_new ((GObject *) self, callback, user_data, \
        tp_contact_##method##_async); \
    \
    tp_cli_connection_interface_contact_list_call_##method ( \
        tp_contact_get_connection (self), -1, handles, ##__VA_ARGS__, \
        generic_callback, result, g_object_unref, NULL); \
    g_array_unref (handles); \
  } G_STMT_END

#define generic_finish(method) \
    _tp_implement_finish_void (self, tp_contact_##method##_async);

/**
 * tp_contact_request_subscription_async:
 * @self: a #TpContact
 * @message: an optional message
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Convenience wrapper for tp_connection_request_subscription_async()
 * on a single contact.
 *
 * Since: 0.15.5
 */
void
tp_contact_request_subscription_async (TpContact *self,
    const gchar *message,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_list_generic_async (request_subscription, message);
}

/**
 * tp_contact_request_subscription_finish:
 * @self: a #TpContact
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_contact_request_subscription_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_contact_request_subscription_finish (TpContact *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (request_subscription);
}

/**
 * tp_contact_authorize_publication_async:
 * @self: a #TpContact
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Convenience wrapper for tp_connection_authorize_publication_async()
 * on a single contact.
 *
 * Since: 0.15.5
 */
void
tp_contact_authorize_publication_async (TpContact *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_list_generic_async (authorize_publication);
}

/**
 * tp_contact_authorize_publication_finish:
 * @self: a #TpContact
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_contact_authorize_publication_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_contact_authorize_publication_finish (TpContact *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (authorize_publication);
}

/**
 * tp_contact_remove_async:
 * @self: a #TpContact
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Convenience wrapper for tp_connection_remove_contacts_async()
 * on a single contact.
 *
 * Since: 0.15.5
 */
void
tp_contact_remove_async (TpContact *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_list_generic_async (remove_contacts);
}

/**
 * tp_contact_remove_finish:
 * @self: a #TpContact
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_contact_remove_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_contact_remove_finish (TpContact *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (remove_contacts);
}

/**
 * tp_contact_unsubscribe_async:
 * @self: a #TpContact
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Convenience wrapper for tp_connection_unsubscribe_async()
 * on a single contact.
 *
 * Since: 0.15.5
 */
void
tp_contact_unsubscribe_async (TpContact *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_list_generic_async (unsubscribe);
}

/**
 * tp_contact_unsubscribe_finish:
 * @self: a #TpContact
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_contact_unsubscribe_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_contact_unsubscribe_finish (TpContact *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (unsubscribe);
}

/**
 * tp_contact_unpublish_async:
 * @self: a #TpContact
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Convenience wrapper for tp_connection_unpublish_async()
 * on a single contact.
 *
 * Since: 0.15.5
 */
void
tp_contact_unpublish_async (TpContact *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_list_generic_async (unpublish);
}

/**
 * tp_contact_unpublish_finish:
 * @self: a #TpContact
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_contact_unpublish_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_contact_unpublish_finish (TpContact *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (unpublish);
}

#define contact_groups_generic_async(method) \
  G_STMT_START { \
    GSimpleAsyncResult *result; \
    TpHandle handle; \
    GArray *handles; \
    \
    g_return_if_fail (TP_IS_CONTACT (self)); \
    \
    handle = tp_contact_get_handle (self); \
    handles = g_array_new (FALSE, FALSE, sizeof (TpHandle)); \
    g_array_append_val (handles, handle); \
    \
    result = g_simple_async_result_new ((GObject *) self, callback, user_data, \
        tp_contact_##method##_async); \
    \
    tp_cli_connection_interface_contact_groups_call_##method ( \
        tp_contact_get_connection (self), -1, group, handles, \
        generic_callback, result, g_object_unref, NULL); \
    g_array_unref (handles); \
  } G_STMT_END

/**
 * tp_contact_add_to_group_async:
 * @self: a #TpContact
 * @group: the group to alter.
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Convenience wrapper for tp_connection_add_to_group_async()
 * on a single contact.
 *
 * Since: 0.15.5
 */
void
tp_contact_add_to_group_async (TpContact *self,
    const gchar *group,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_groups_generic_async (add_to_group);
}

/**
 * tp_contact_add_to_group_finish:
 * @self: a #TpContact
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_contact_add_to_group_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_contact_add_to_group_finish (TpContact *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (add_to_group);
}

/**
 * tp_contact_remove_from_group_async:
 * @self: a #TpContact
 * @group: the group to alter.
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Convenience wrapper for tp_connection_remove_from_group_async()
 * on a single contact.
 *
 * Since: 0.15.5
 */
void
tp_contact_remove_from_group_async (TpContact *self,
    const gchar *group,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_groups_generic_async (remove_from_group);
}

/**
 * tp_contact_remove_from_group_finish:
 * @self: a #TpContact
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_contact_remove_from_group_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_contact_remove_from_group_finish (TpContact *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (remove_from_group);
}

/* ContactBlocking */

/**
 * tp_contact_block_async:
 * @self: a #TpContact
 * @report_abusive: If %TRUE, report this contact as abusive to the
 * server administrators as well as blocking him. See
 * #TpConnection:can-report-abusive to discover whether reporting abuse is
 * supported. If #TpConnection:can-report-abusive is %FALSE, this parameter will
 * be ignored.
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Block communications with a contact, optionally reporting the contact as
 * abusive to the server administrators. To block more than one contact at once,
 * see tp_connection_block_contacts_async().
 *
 * Since: 0.17.0
 */
void
tp_contact_block_async (TpContact *self,
    gboolean report_abusive,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  TpHandle handle;
  GArray *handles;

  g_return_if_fail (TP_IS_CONTACT (self));

  handle = tp_contact_get_handle (self);
  handles = g_array_new (FALSE, FALSE, sizeof (TpHandle));
  g_array_append_val (handles, handle);

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      tp_contact_block_async);

  tp_cli_connection_interface_contact_blocking_call_block_contacts (
      tp_contact_get_connection (self), -1,
      handles, report_abusive, generic_callback, result, g_object_unref, NULL);

  g_array_unref (handles);
}

/**
 * tp_contact_block_finish:
 * @self: a #TpContact
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_contact_block_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.17.0
 */
gboolean
tp_contact_block_finish (TpContact *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (block);
}

/**
 * tp_contact_unblock_async:
 * @self: a #TpContact
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Unblock communications with a contact. To unblock more than one contact
 * at once, see tp_connection_unblock_contacts_async().
 *
 * Since: 0.17.0
 */
void
tp_contact_unblock_async (TpContact *self,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  TpHandle handle;
  GArray *handles;

  g_return_if_fail (TP_IS_CONTACT (self));

  handle = tp_contact_get_handle (self);
  handles = g_array_new (FALSE, FALSE, sizeof (TpHandle));
  g_array_append_val (handles, handle);

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      tp_contact_unblock_async);

  tp_cli_connection_interface_contact_blocking_call_unblock_contacts (
      tp_contact_get_connection (self), -1,
      handles, generic_callback, result, g_object_unref, NULL);

  g_array_unref (handles);
}

/**
 * tp_contact_unblock_finish:
 * @self: a #TpContact
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_contact_unblock_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.17.0
 */
gboolean
tp_contact_unblock_finish (TpContact *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (unblock);
}
