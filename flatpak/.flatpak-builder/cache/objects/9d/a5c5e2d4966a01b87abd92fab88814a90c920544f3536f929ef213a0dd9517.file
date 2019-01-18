/*
 * Proxy for a Telepathy connection - ContactList support
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

#include "telepathy-glib/connection-contact-list.h"

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/simple-client-factory.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CONNECTION
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/connection-internal.h"
#include "telepathy-glib/contact-internal.h"
#include "telepathy-glib/util-internal.h"

typedef struct
{
  GHashTable *changes;
  GHashTable *identifiers;
  GHashTable *removals;
  GPtrArray *new_contacts;
} ContactsChangedItem;

static ContactsChangedItem *
contacts_changed_item_new (GHashTable *changes,
    GHashTable *identifiers,
    GHashTable *removals)
{
  ContactsChangedItem *item;

  item = g_slice_new0 (ContactsChangedItem);
  item->changes = g_hash_table_ref (changes);
  item->identifiers = g_hash_table_ref (identifiers);
  item->removals = g_hash_table_ref (removals);
  item->new_contacts = g_ptr_array_new_with_free_func (g_object_unref);

  return item;
}

static void
contacts_changed_item_free (ContactsChangedItem *item)
{
  tp_clear_pointer (&item->changes, g_hash_table_unref);
  tp_clear_pointer (&item->identifiers, g_hash_table_unref);
  tp_clear_pointer (&item->removals, g_hash_table_unref);
  tp_clear_pointer (&item->new_contacts, g_ptr_array_unref);
  g_slice_free (ContactsChangedItem, item);
}

void
_tp_connection_contacts_changed_queue_free (GQueue *queue)
{
  g_queue_foreach (queue, (GFunc) contacts_changed_item_free, NULL);
  g_queue_free (queue);
}

static void process_queued_contacts_changed (TpConnection *self);

static void
contacts_changed_head_ready (TpConnection *self)
{
  ContactsChangedItem *item;
  GHashTableIter iter;
  gpointer key;
  GPtrArray *added;
  GPtrArray *removed;
  guint i;

  item = g_queue_pop_head (self->priv->contacts_changed_queue);

  added = g_ptr_array_new_full (g_hash_table_size (item->removals),
      g_object_unref);
  removed = g_ptr_array_new_full (item->new_contacts->len,
      g_object_unref);

  /* Remove contacts from roster, and build a list of contacts really removed */
  g_hash_table_iter_init (&iter, item->removals);
  while (g_hash_table_iter_next (&iter, &key, NULL))
    {
      TpContact *contact;

      contact = g_hash_table_lookup (self->priv->roster, key);
      if (contact == NULL)
        {
          DEBUG ("handle %u removed but not in our table - broken CM",
              GPOINTER_TO_UINT (key));
          continue;
        }

      g_ptr_array_add (removed, g_object_ref (contact));
      g_hash_table_remove (self->priv->roster, key);
    }

  /* Add contacts to roster and build a list of contacts added */
  for (i = 0; i < item->new_contacts->len; i++)
    {
      TpContact *contact = g_ptr_array_index (item->new_contacts, i);

      g_ptr_array_add (added, g_object_ref (contact));
      g_hash_table_insert (self->priv->roster,
          GUINT_TO_POINTER (tp_contact_get_handle (contact)),
          g_object_ref (contact));
    }

  DEBUG ("roster changed: %d added, %d removed", added->len, removed->len);
  if (added->len > 0 || removed->len > 0)
    g_signal_emit_by_name (self, "contact-list-changed", added, removed);

  g_ptr_array_unref (added);
  g_ptr_array_unref (removed);
  contacts_changed_item_free (item);

  process_queued_contacts_changed (self);
}

static void
new_contacts_upgraded_cb (GObject *object,
    GAsyncResult *result,
    gpointer user_data)
{
  TpSimpleClientFactory *factory = (TpSimpleClientFactory *) object;
  TpConnection *self = user_data;
  GError *error = NULL;

  if (!tp_simple_client_factory_upgrade_contacts_finish (factory, result, NULL,
          &error))
    {
      DEBUG ("Error upgrading new roster contacts: %s", error->message);
      g_clear_error (&error);
    }

  contacts_changed_head_ready (self);
}

static void
process_queued_contacts_changed (TpConnection *self)
{
  ContactsChangedItem *item;
  GHashTableIter iter;
  gpointer key, value;

  item = g_queue_peek_head (self->priv->contacts_changed_queue);
  if (item == NULL)
    return;

  g_hash_table_iter_init (&iter, item->changes);
  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      TpContact *contact = g_hash_table_lookup (self->priv->roster, key);
      const gchar *identifier = g_hash_table_lookup (item->identifiers, key);
      TpHandle handle = GPOINTER_TO_UINT (key);

      /* If the contact is already in the roster, it is only a change of
       * subscription states. That's already handled by the TpContact itself so
       * we have nothing more to do for it here. */
      if (contact != NULL)
        continue;

      contact = tp_simple_client_factory_ensure_contact (
          tp_proxy_get_factory (self), self, handle, identifier);
      _tp_contact_set_subscription_states (contact, value);
      g_ptr_array_add (item->new_contacts, contact);
    }

  if (item->new_contacts->len == 0)
    {
      contacts_changed_head_ready (self);
      return;
    }

  tp_simple_client_factory_upgrade_contacts_async (tp_proxy_get_factory (self),
      self, item->new_contacts->len, (TpContact **) item->new_contacts->pdata,
      new_contacts_upgraded_cb, self);
}

static void
contacts_changed_cb (TpConnection *self,
    GHashTable *changes,
    GHashTable *identifiers,
    GHashTable *removals,
    gpointer user_data,
    GObject *weak_object)
{
  ContactsChangedItem *item;

  /* Ignore ContactsChanged signal if we didn't receive initial roster yet */
  if (!self->priv->roster_fetched)
    return;

  /* We need a queue to make sure we don't reorder signals if we get a 2nd
   * ContactsChanged signal before the previous one finished preparing TpContact
   * objects. */
  item = contacts_changed_item_new (changes, identifiers, removals);
  g_queue_push_tail (self->priv->contacts_changed_queue, item);

  /* If this is the only item in the queue, we can process it right away */
  if (self->priv->contacts_changed_queue->length == 1)
    process_queued_contacts_changed (self);
}

static void
got_contact_list_attributes_cb (TpConnection *self,
    GHashTable *attributes,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = (GSimpleAsyncResult *) weak_object;
  GArray *features = user_data;
  GHashTableIter iter;
  gpointer key, value;

  if (error != NULL)
    {
      self->priv->contact_list_state = TP_CONTACT_LIST_STATE_FAILURE;
      g_object_notify ((GObject *) self, "contact-list-state");

      if (result != NULL)
        g_simple_async_result_set_from_error (result, error);

      goto OUT;
    }

  DEBUG ("roster fetched with %d contacts", g_hash_table_size (attributes));
  self->priv->roster_fetched = TRUE;

  g_hash_table_iter_init (&iter, attributes);
  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      TpHandle handle = GPOINTER_TO_UINT (key);
      const gchar *id = tp_asv_get_string (value,
          TP_TOKEN_CONNECTION_CONTACT_ID);
      TpContact *contact;
      GError *e = NULL;

      contact = tp_simple_client_factory_ensure_contact (
          tp_proxy_get_factory (self), self, handle, id);

      /* ensure_contact() can fail for obsolete CMs that don't have
       * ImmortalHandles */
      if (contact == NULL)
         continue;

      if (!_tp_contact_set_attributes (contact, value,
              features->len, (TpContactFeature *) features->data, &e))
        {
          DEBUG ("Error setting contact attributes: %s", e->message);
          g_clear_error (&e);
        }

      /* Give the contact ref to the table */
      g_hash_table_insert (self->priv->roster, key, contact);
    }

  /* emit initial set if roster is not empty */
  if (g_hash_table_size (self->priv->roster) != 0)
    {
      GPtrArray *added;
      GPtrArray *removed;

      added = tp_connection_dup_contact_list (self);
      removed = g_ptr_array_new ();
      g_signal_emit_by_name (self, "contact-list-changed", added, removed);
      g_ptr_array_unref (added);
      g_ptr_array_unref (removed);
    }

  self->priv->contact_list_state = TP_CONTACT_LIST_STATE_SUCCESS;
  g_object_notify ((GObject *) self, "contact-list-state");

OUT:
  if (result != NULL)
    {
      g_simple_async_result_complete_in_idle (result);
      g_object_unref (result);
    }
}

static void
prepare_roster (TpConnection *self,
    GSimpleAsyncResult *result)
{
  TpContactFeature feature_states = TP_CONTACT_FEATURE_SUBSCRIPTION_STATES;
  GArray *features;
  const gchar **supported_interfaces;

  DEBUG ("CM has the roster for connection %s, fetch it now.",
      tp_proxy_get_object_path (self));

  tp_cli_connection_interface_contact_list_connect_to_contacts_changed_with_id (
      self, contacts_changed_cb, NULL, NULL, NULL, NULL);

  features = tp_simple_client_factory_dup_contact_features (
      tp_proxy_get_factory (self), self);

  /* We'll get subscription states for free, but we still need to tell
   * TpContact to bind to change notification. */
  g_array_append_val (features, feature_states);

  supported_interfaces = _tp_contacts_bind_to_signals (self, features->len,
      (TpContactFeature *) features->data);

  tp_cli_connection_interface_contact_list_call_get_contact_list_attributes (
      self, -1, supported_interfaces, TRUE,
      got_contact_list_attributes_cb,
      features, (GDestroyNotify) g_array_unref,
      result ? g_object_ref (result) : NULL);

  g_free (supported_interfaces);
}

static void
contact_list_state_changed_cb (TpConnection *self,
    guint state,
    gpointer user_data,
    GObject *weak_object)
{
  /* Ignore StateChanged if we didn't had the initial state or if
   * duplicate signal */
  if (!self->priv->contact_list_properties_fetched ||
      state == self->priv->contact_list_state)
    return;

  DEBUG ("contact list state changed: %d", state);

  /* If state goes to success, delay notification until roster is ready */
  if (state == TP_CONTACT_LIST_STATE_SUCCESS &&
      tp_proxy_is_prepared (self, TP_CONNECTION_FEATURE_CONTACT_LIST))
    {
      prepare_roster (self, NULL);
      return;
    }

  self->priv->contact_list_state = state;
  g_object_notify ((GObject *) self, "contact-list-state");
}

static void
prepare_contact_list_props_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result = user_data;
  gboolean valid;

  self->priv->contact_list_properties_fetched = TRUE;

  if (error != NULL)
    {
      DEBUG ("Error preparing ContactList properties: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
      goto OUT;
    }

  self->priv->contact_list_state = tp_asv_get_uint32 (properties,
      "ContactListState", &valid);
  if (!valid)
    {
      DEBUG ("Connection %s doesn't have ContactListState property",
          tp_proxy_get_object_path (self));
    }

  self->priv->contact_list_persists = tp_asv_get_boolean (properties,
      "ContactListPersists", &valid);
  if (!valid)
    {
      DEBUG ("Connection %s doesn't have ContactListPersists property",
          tp_proxy_get_object_path (self));
    }

  self->priv->can_change_contact_list = tp_asv_get_boolean (properties,
      "CanChangeContactList", &valid);
  if (!valid)
    {
      DEBUG ("Connection %s doesn't have CanChangeContactList property",
          tp_proxy_get_object_path (self));
    }

  self->priv->request_uses_message = tp_asv_get_boolean (properties,
      "RequestUsesMessage", &valid);
  if (!valid)
    {
      DEBUG ("Connection %s doesn't have RequestUsesMessage property",
          tp_proxy_get_object_path (self));
    }

  DEBUG ("Got contact list properties; state=%d",
      self->priv->contact_list_state);

OUT:
  g_simple_async_result_complete_in_idle (result);
}

void
_tp_connection_prepare_contact_list_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result;

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      _tp_connection_prepare_contact_list_async);

  /* If the CM has the contact list, prepare it right away */
  if (self->priv->contact_list_state == TP_CONTACT_LIST_STATE_SUCCESS)
    {
      prepare_roster (self, result);
      g_object_unref (result);
      return;
    }

  /* Contacts will be prepared once the CM has fetched the contact list from
   * the server.
   * Complete the preparation as it's not supposed to wait for the contact
   * list. */
  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

void
_tp_connection_prepare_contact_list_props_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result;

  tp_cli_connection_interface_contact_list_connect_to_contact_list_state_changed
      (self, contact_list_state_changed_cb, NULL, NULL, NULL, NULL);

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      _tp_connection_prepare_contact_list_props_async);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CONNECTION_INTERFACE_CONTACT_LIST,
      prepare_contact_list_props_cb, result, g_object_unref, NULL);
}

static void
contact_groups_created_cb (TpConnection *self,
    const gchar **names,
    gpointer user_data,
    GObject *weak_object)
{
  const gchar **iter;

  if (!self->priv->groups_fetched)
      return;

  DEBUG ("Groups created:");

  /* Remove the ending NULL */
  g_ptr_array_remove_index_fast (self->priv->contact_groups,
      self->priv->contact_groups->len - 1);

  for (iter = names; *iter != NULL; iter++)
    {
      DEBUG ("  %s", *iter);
      g_ptr_array_add (self->priv->contact_groups, g_strdup (*iter));
    }

  /* Add back the ending NULL */
  g_ptr_array_add (self->priv->contact_groups, NULL);

  g_object_notify ((GObject *) self, "contact-groups");
  g_signal_emit_by_name (self, "groups-created", names);
}

static void
contact_groups_removed_cb (TpConnection *self,
    const gchar **names,
    gpointer user_data,
    GObject *weak_object)
{
  const gchar **iter;

  if (!self->priv->groups_fetched)
      return;

  DEBUG ("Groups removed:");

  /* Remove the ending NULL */
  g_ptr_array_remove_index_fast (self->priv->contact_groups,
      self->priv->contact_groups->len - 1);

  for (iter = names; *iter != NULL; iter++)
    {
      guint i;

      for (i = 0; i < self->priv->contact_groups->len; i++)
        {
          const gchar *str = g_ptr_array_index (self->priv->contact_groups, i);

          if (!tp_strdiff (str, *iter))
            {
              DEBUG ("  %s", str);
              g_ptr_array_remove_index_fast (self->priv->contact_groups, i);
              break;
            }
        }
    }

  /* Add back the ending NULL */
  g_ptr_array_add (self->priv->contact_groups, NULL);

  g_object_notify ((GObject *) self, "contact-groups");
  g_signal_emit_by_name (self, "groups-removed", names);
}

static void
contact_group_renamed_cb (TpConnection *self,
    const gchar *old_name,
    const gchar *new_name,
    gpointer user_data,
    GObject *weak_object)
{
  guint i;

  if (!self->priv->groups_fetched)
      return;

  DEBUG ("Group renamed: %s -> %s", old_name, new_name);

  /* Remove the ending NULL */
  g_ptr_array_remove_index_fast (self->priv->contact_groups,
      self->priv->contact_groups->len - 1);

  for (i = 0; i < self->priv->contact_groups->len; i++)
    {
      const gchar *str = g_ptr_array_index (self->priv->contact_groups, i);

      if (!tp_strdiff (str, old_name))
        {
          g_ptr_array_remove_index_fast (self->priv->contact_groups, i);
          break;
        }
    }
  g_ptr_array_add (self->priv->contact_groups, g_strdup (new_name));

  /* Add back the ending NULL */
  g_ptr_array_add (self->priv->contact_groups, NULL);

  g_object_notify ((GObject *) self, "contact-groups");
  g_signal_emit_by_name (self, "group-renamed", old_name, new_name);
}

static void
prepare_contact_groups_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result = user_data;
  GStrv groups;
  gchar **iter;
  gboolean valid;

  if (error != NULL)
    {
      g_simple_async_result_set_from_error (result, error);
      goto OUT;
    }

  self->priv->groups_fetched = TRUE;

  self->priv->disjoint_groups = tp_asv_get_boolean (properties,
      "DisjointGroups", &valid);
  if (!valid)
    {
      DEBUG ("Connection %s doesn't have DisjointGroups property",
          tp_proxy_get_object_path (self));
    }

  self->priv->group_storage = tp_asv_get_uint32 (properties,
      "GroupStorage", &valid);
  if (!valid)
    {
      DEBUG ("Connection %s doesn't have GroupStorage property",
          tp_proxy_get_object_path (self));
    }

  DEBUG ("Got contact list groups:");

  /* Remove the ending NULL */
  g_ptr_array_remove_index_fast (self->priv->contact_groups,
      self->priv->contact_groups->len - 1);

  groups = tp_asv_get_boxed (properties, "Groups", G_TYPE_STRV);
  for (iter = groups; iter != NULL && *iter != NULL; iter++)
    {
      DEBUG ("  %s", *iter);
      g_ptr_array_add (self->priv->contact_groups, g_strdup (*iter));
    }

  /* Add back the ending NULL */
  g_ptr_array_add (self->priv->contact_groups, NULL);

OUT:
  g_simple_async_result_complete_in_idle (result);
}

void
_tp_connection_prepare_contact_groups_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result;

  tp_cli_connection_interface_contact_groups_connect_to_groups_created (
      self, contact_groups_created_cb, NULL, NULL, NULL, NULL);
  tp_cli_connection_interface_contact_groups_connect_to_groups_removed (
      self, contact_groups_removed_cb, NULL, NULL, NULL, NULL);
  tp_cli_connection_interface_contact_groups_connect_to_group_renamed (
      self, contact_group_renamed_cb, NULL, NULL, NULL, NULL);

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      _tp_connection_prepare_contact_groups_async);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CONNECTION_INTERFACE_CONTACT_GROUPS,
      prepare_contact_groups_cb, result, g_object_unref, NULL);
}

/**
 * TP_CONNECTION_FEATURE_CONTACT_LIST:
 *
 * Expands to a call to a function that returns a #GQuark representing the
 * "contact-list" feature.
 *
 * When this feature is prepared, the
 * %TP_CONNECTION_FEATURE_CONTACT_LIST_PROPERTIES has been prepared, so the
 * contact list properties of the Connection has been retrieved.
 * If #TpConnection:contact-list-state is
 * %TP_CONTACT_LIST_STATE_SUCCESS, all #TpContact objects will also be created
 * and prepared with the desired features. See tp_connection_dup_contact_list()
 * to get the list of contacts, and
 * tp_simple_client_factory_add_contact_features() to define which features
 * needs to be prepared on them.
 *
 * This feature will fail to prepare when using obsolete Telepathy connection
 * managers which do not implement the ContactList interface.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.15.5
 */

GQuark
tp_connection_get_feature_quark_contact_list (void)
{
  return g_quark_from_static_string ("tp-connection-feature-contact-list");
}

/**
 * tp_connection_get_contact_list_state:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: the value of #TpConnection:contact-list-state property
 *
 * Since: 0.15.5
 */
TpContactListState
tp_connection_get_contact_list_state (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), TP_CONTACT_LIST_STATE_NONE);

  return self->priv->contact_list_state;
}

/**
 * tp_connection_get_contact_list_persists:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: the value of #TpConnection:contact-list-persists property
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_get_contact_list_persists (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  return self->priv->contact_list_persists;
}

/**
 * tp_connection_get_can_change_contact_list:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: the value of #TpConnection:can-change-contact-list property
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_get_can_change_contact_list (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  return self->priv->can_change_contact_list;
}

/**
 * tp_connection_get_request_uses_message:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: the value of #TpConnection:request-uses-message property
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_get_request_uses_message (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  return self->priv->request_uses_message;
}

/**
 * tp_connection_dup_contact_list:
 * @self: a #TpConnection
 *
 * Retrieves the user's contact list. In general, blocked contacts are not
 * included in this list. The #TpContact objects returned are guaranteed to
 * have all of the features previously passed to
 * tp_simple_client_factory_add_contact_features() prepared.
 *
 * Before calling this method, you must first call tp_proxy_prepare_async() with
 * the %TP_CONNECTION_FEATURE_CONTACT_LIST feature, and verify that
 * #TpConnection:contact-list-state is set to %TP_CONTACT_LIST_STATE_SUCCESS.
 *
 * Returns: (transfer container) (type GLib.PtrArray) (element-type TelepathyGLib.Contact):
 *  a new #GPtrArray of #TpContact. Use g_ptr_array_unref() when done.
 *
 * Since: 0.15.5
 */
GPtrArray *
tp_connection_dup_contact_list (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);

  return _tp_contacts_from_values (self->priv->roster);
}

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

#define contact_list_generic_async(method, ...) \
  G_STMT_START { \
    GSimpleAsyncResult *result; \
    GArray *handles; \
    gboolean supplied_contacts_are_valid; \
    \
    g_return_if_fail (TP_IS_CONNECTION (self)); \
    g_return_if_fail (n_contacts > 0); \
    \
    supplied_contacts_are_valid = _tp_contacts_to_handles (self, n_contacts, \
        contacts, &handles); \
    g_return_if_fail (supplied_contacts_are_valid); \
    \
    result = g_simple_async_result_new ((GObject *) self, callback, user_data, \
        tp_connection_##method##_async); \
    \
    tp_cli_connection_interface_contact_list_call_##method (self, -1, handles, \
        ##__VA_ARGS__, generic_callback, result, g_object_unref, NULL); \
    g_array_unref (handles); \
  } G_STMT_END

#define generic_finish(method) \
    _tp_implement_finish_void (self, tp_connection_##method##_async);

/**
 * tp_connection_request_subscription_async:
 * @self: a #TpConnection
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects to whom
 *  requests are to be sent.
 * @message: an optional plain-text message from the user, to send to those
 *  @contacts with the subscription request.
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Request that the given @contacts allow the local user to subscribe to their
 * presence, i.e. that their #TpContact:subscribe-state property becomes
 * %TP_SUBSCRIPTION_STATE_YES.
 *
 * For this to work properly @self must have interface
 * %TP_IFACE_CONNECTION_INTERFACE_CONTACT_LIST.
 *
 * Since: 0.15.5
 */
void
tp_connection_request_subscription_async (TpConnection *self,
    guint n_contacts,
    TpContact * const *contacts,
    const gchar *message,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_list_generic_async (request_subscription, message);
}

/**
 * tp_connection_request_subscription_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_request_subscription_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_request_subscription_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (request_subscription);
}

/**
 * tp_connection_authorize_publication_async:
 * @self: a #TpConnection
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects to
 *  authorize
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * For each of the given @contacts, request that the local user's presence is
 * sent to that contact, i.e. that their #TpContact:publish-state property
 * becomes %TP_SUBSCRIPTION_STATE_YES.
 *
 * For this to work properly @self must have interface
 * %TP_IFACE_CONNECTION_INTERFACE_CONTACT_LIST.
 *
 * Since: 0.15.5
 */
void
tp_connection_authorize_publication_async (TpConnection *self,
    guint n_contacts,
    TpContact * const *contacts,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_list_generic_async (authorize_publication);
}

/**
 * tp_connection_authorize_publication_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_authorize_publication_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_authorize_publication_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (authorize_publication);
}

/**
 * tp_connection_remove_contacts_async:
 * @self: a #TpConnection
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects to
 *  remove
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Remove the given @contacts from the contact list entirely. It is
 * protocol-dependent whether this works, and under which circumstances.
 *
 * For this to work properly @self must have interface
 * %TP_IFACE_CONNECTION_INTERFACE_CONTACT_LIST.
 *
 * Since: 0.15.5
 */
void
tp_connection_remove_contacts_async (TpConnection *self,
    guint n_contacts,
    TpContact * const *contacts,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_list_generic_async (remove_contacts);
}

/**
 * tp_connection_remove_contacts_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_remove_contacts_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_remove_contacts_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (remove_contacts);
}

/**
 * tp_connection_unsubscribe_async:
 * @self: a #TpConnection
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects to
 *  remove
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Attempt to set the given @contacts' #TpContact:subscribe-state property to
 * %TP_SUBSCRIPTION_STATE_NO, i.e. stop receiving their presence.
 *
 * For this to work properly @self must have interface
 * %TP_IFACE_CONNECTION_INTERFACE_CONTACT_LIST.
 *
 * Since: 0.15.5
 */
void
tp_connection_unsubscribe_async (TpConnection *self,
    guint n_contacts,
    TpContact * const *contacts,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_list_generic_async (unsubscribe);
}

/**
 * tp_connection_unsubscribe_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_unsubscribe_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_unsubscribe_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (unsubscribe);
}

/**
 * tp_connection_unpublish_async:
 * @self: a #TpConnection
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects to
 *  remove
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Attempt to set the given @contacts' #TpContact:publish-state property to
 * %TP_SUBSCRIPTION_STATE_NO, i.e. stop sending presence to them.
 *
 * For this to work properly @self must have interface
 * %TP_IFACE_CONNECTION_INTERFACE_CONTACT_LIST.
 *
 * Since: 0.15.5
 */
void
tp_connection_unpublish_async (TpConnection *self,
    guint n_contacts,
    TpContact * const *contacts,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_list_generic_async (unpublish);
}

/**
 * tp_connection_unpublish_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_unpublish_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_unpublish_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (unpublish);
}

/**
 * TP_CONNECTION_FEATURE_CONTACT_GROUPS:
 *
 * Expands to a call to a function that returns a #GQuark representing the
 * "contact-groups" feature.
 *
 * When this feature is prepared, the contact groups properties of the
 * Connection has been retrieved.
 *
 * See #TpContact:contact-groups to get the list of groups a contact is member
 * of.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.15.5
 */

GQuark
tp_connection_get_feature_quark_contact_groups (void)
{
  return g_quark_from_static_string ("tp-connection-feature-contact-groups");
}

/**
 * tp_connection_get_disjoint_groups:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: the value of #TpConnection:disjoint-groups
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_get_disjoint_groups (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), FALSE);

  return self->priv->disjoint_groups;
}

/**
 * tp_connection_get_group_storage:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: the value of #TpConnection:group-storage
 *
 * Since: 0.15.5
 */
TpContactMetadataStorageType
tp_connection_get_group_storage (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self),
      TP_CONTACT_METADATA_STORAGE_TYPE_NONE);

  return self->priv->group_storage;
}

/**
 * tp_connection_get_contact_groups:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: (array zero-terminated=1) (transfer none): the value of
 *  #TpConnection:contact-groups
 *
 * Since: 0.15.5
 */
const gchar * const *
tp_connection_get_contact_groups (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);

  return (const gchar * const *) self->priv->contact_groups->pdata;
}

#define contact_groups_generic_async(method) \
  G_STMT_START { \
    GSimpleAsyncResult *result; \
    GArray *handles; \
    gboolean supplied_contacts_are_valid; \
    \
    g_return_if_fail (TP_IS_CONNECTION (self)); \
    g_return_if_fail (group != NULL); \
    g_return_if_fail (n_contacts > 0); \
    \
    supplied_contacts_are_valid = _tp_contacts_to_handles (self, n_contacts, \
        contacts, &handles); \
    g_return_if_fail (supplied_contacts_are_valid); \
    \
    result = g_simple_async_result_new ((GObject *) self, callback, user_data, \
        tp_connection_##method##_async); \
    \
    tp_cli_connection_interface_contact_groups_call_##method (self, -1, \
        group, handles, generic_callback, result, g_object_unref, NULL); \
    g_array_unref (handles); \
  } G_STMT_END

/**
 * tp_connection_set_group_members_async:
 * @self: a #TpConnection
 * @group: the group to alter.
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects members
 *  for the group. If this set is empty, this method MAY remove the group.
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Add the given @contacts to the given @group (creating it if necessary), and
 * remove all other members.
 *
 * For this to work properly @self must have interface
 * %TP_IFACE_CONNECTION_INTERFACE_CONTACT_GROUPS.
 *
 * Since: 0.15.5
 */
void
tp_connection_set_group_members_async (TpConnection *self,
    const gchar *group,
    guint n_contacts,
    TpContact * const *contacts,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_groups_generic_async (set_group_members);
}

/**
 * tp_connection_set_group_members_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_set_group_members_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_set_group_members_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (set_group_members);
}

/**
 * tp_connection_add_to_group_async:
 * @self: a #TpConnection
 * @group: the group to alter.
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects to
 *  include in the group.
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Add the given @contacts to the given @group, creating it if necessary.
 *
 * For this to work properly @self must have interface
 * %TP_IFACE_CONNECTION_INTERFACE_CONTACT_GROUPS.
 *
 * Since: 0.15.5
 */
void
tp_connection_add_to_group_async (TpConnection *self,
    const gchar *group,
    guint n_contacts,
    TpContact * const *contacts,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_groups_generic_async (add_to_group);
}

/**
 * tp_connection_add_to_group_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_add_to_group_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_add_to_group_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (add_to_group);
}

/**
 * tp_connection_remove_from_group_async:
 * @self: a #TpConnection
 * @group: the group to alter.
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects to
 *  remove from the group.
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Remove the given @contacts from the given @group. If there are no members
 * left in the group afterwards, the group MAY itself be removed.
 *
 * For this to work properly @self must have interface
 * %TP_IFACE_CONNECTION_INTERFACE_CONTACT_GROUPS.
 *
 * Since: 0.15.5
 */
void
tp_connection_remove_from_group_async (TpConnection *self,
    const gchar *group,
    guint n_contacts,
    TpContact * const *contacts,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  contact_groups_generic_async (remove_from_group);
}

/**
 * tp_connection_remove_from_group_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_remove_from_group_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_remove_from_group_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (remove_from_group);
}

/**
 * tp_connection_remove_group_async:
 * @self: a #TpConnection
 * @group: the group to remove.
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Remove all members from the given group, then remove the group itself.
 *
 * For this to work properly @self must have interface
 * %TP_IFACE_CONNECTION_INTERFACE_CONTACT_GROUPS.
 *
 * Since: 0.15.5
 */
void
tp_connection_remove_group_async (TpConnection *self,
    const gchar *group,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
    GSimpleAsyncResult *result;

    g_return_if_fail (TP_IS_CONNECTION (self));
    g_return_if_fail (group != NULL);

    result = g_simple_async_result_new ((GObject *) self, callback, user_data,
        tp_connection_remove_group_async);

    tp_cli_connection_interface_contact_groups_call_remove_group (self, -1,
        group, generic_callback, result, g_object_unref, NULL);
}

/**
 * tp_connection_remove_group_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_remove_group_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_remove_group_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (remove_group);
}

/**
 * tp_connection_rename_group_async:
 * @self: a #TpConnection
 * @old_name: the group to rename
 * @new_name: the new name for the group
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Rename the given @old_name.
 *
 * On protocols where groups behave like tags, this is an API short-cut for
 * adding all of the group's members to a group with the new name, then removing
 * the old group.
 *
 * For this to work properly @self must have interface
 * %TP_IFACE_CONNECTION_INTERFACE_CONTACT_GROUPS.
 *
 * Since: 0.15.5
 */
void
tp_connection_rename_group_async (TpConnection *self,
    const gchar *old_name,
    const gchar *new_name,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
    GSimpleAsyncResult *result;

    g_return_if_fail (TP_IS_CONNECTION (self));
    g_return_if_fail (old_name != NULL);
    g_return_if_fail (new_name != NULL);

    result = g_simple_async_result_new ((GObject *) self, callback, user_data,
        tp_connection_rename_group_async);

    tp_cli_connection_interface_contact_groups_call_rename_group (self, -1,
        old_name, new_name, generic_callback, result, g_object_unref, NULL);
}

/**
 * tp_connection_rename_group_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_rename_group_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.15.5
 */
gboolean
tp_connection_rename_group_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (rename_group);
}

/* ContactBlocking */

/**
 * tp_connection_block_contacts_async:
 * @self: a #TpConnection
 * @n_contacts: the number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects to
 *  block
 * @report_abusive: If %TRUE, report these contacts as abusive to the
 * server administrators as well as blocking them. See
 * #TpConnection:can-report-abusive to discover whether reporting abuse is
 * supported. If #TpConnection:can-report-abusive is %FALSE, this parameter will
 * be ignored.
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Direct the server to block @contacts.
 *
 * Since: 0.17.0
 */
void
tp_connection_block_contacts_async (TpConnection *self,
    guint n_contacts,
    TpContact * const *contacts,
    gboolean report_abusive,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  GArray *handles;
  gboolean supplied_contacts_are_valid;

  g_return_if_fail (TP_IS_CONNECTION (self));
  g_return_if_fail (n_contacts > 0);

  supplied_contacts_are_valid = _tp_contacts_to_handles (self, n_contacts,
      contacts, &handles);
  g_return_if_fail (supplied_contacts_are_valid);

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      tp_connection_block_contacts_async);

  tp_cli_connection_interface_contact_blocking_call_block_contacts (self, -1,
      handles, report_abusive, generic_callback, result, g_object_unref, NULL);
  g_array_unref (handles);
}

/**
 * tp_connection_block_contacts_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_block_contacts_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.17.0
 */
gboolean
tp_connection_block_contacts_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (block_contacts);
}

/**
 * tp_connection_unblock_contacts_async:
 * @self: a #TpConnection
 * @n_contacts: the number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects to
 *  block
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Direct the server to unblock @contacts.
 *
 * Since: 0.17.0
 */
void
tp_connection_unblock_contacts_async (TpConnection *self,
    guint n_contacts,
    TpContact * const *contacts,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  GArray *handles;
  gboolean supplied_contacts_are_valid;

  g_return_if_fail (TP_IS_CONNECTION (self));
  g_return_if_fail (n_contacts > 0);

  supplied_contacts_are_valid = _tp_contacts_to_handles (self, n_contacts,
      contacts, &handles);
  g_return_if_fail (supplied_contacts_are_valid);

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      tp_connection_unblock_contacts_async);

  tp_cli_connection_interface_contact_blocking_call_unblock_contacts (self, -1,
      handles, generic_callback, result, g_object_unref, NULL);
  g_array_unref (handles);
}

/**
 * tp_connection_unblock_contacts_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_unblock_contacts_async()
 *
 * Returns: %TRUE if the operation was successful, otherwise %FALSE.
 *
 * Since: 0.17.0
 */
gboolean
tp_connection_unblock_contacts_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  generic_finish (unblock_contacts);
}

/**
 * TP_CONNECTION_FEATURE_CONTACT_BLOCKING:
 *
 * Expands to a call to a function that returns a #GQuark representing the
 * "contact-blocking" feature.
 *
 * When this feature is prepared, #TpConnection:blocked-contacts will contain an
 * up-to-date list of #TpContact<!-- -->s the user has blocked, and
 * #TpConnection:can-report-abusive will indicate whether abusive contacts can
 * be reported to the server administrator.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.17.0
 */

GQuark
tp_connection_get_feature_quark_contact_blocking (void)
{
  return g_quark_from_static_string ("tp-connection-feature-contact-blocking");
}

typedef struct
{
  /* TpHandle -> (const gchar *) identifier */
  GHashTable *added;
  /* TpHandle -> (const gchar *) identifier */
  GHashTable *removed;

  /* array of reffed TpContact */
  GPtrArray *added_contacts;
  /* array of reffed TpContact */
  GPtrArray *removed_contacts;

  GSimpleAsyncResult *result;
} BlockedChangedItem;

static BlockedChangedItem *
blocked_changed_item_new (TpConnection *conn,
    GHashTable *added,
    GHashTable *removed,
    GSimpleAsyncResult *result)
{
  BlockedChangedItem *item = g_slice_new0 (BlockedChangedItem);

  item->added = g_hash_table_ref (added);

  if (removed != NULL)
    item->removed = g_hash_table_ref (removed);
  else
    item->removed = g_hash_table_new (NULL, NULL);

  item->added_contacts = g_ptr_array_new_with_free_func (g_object_unref);
  item->removed_contacts = g_ptr_array_new_with_free_func (g_object_unref);

  if (result != NULL)
    item->result = g_object_ref (result);

  return item;
}

static void
blocked_changed_item_free (BlockedChangedItem *item)
{
  g_hash_table_unref (item->added);
  g_hash_table_unref (item->removed);
  g_ptr_array_unref (item->added_contacts);
  g_ptr_array_unref (item->removed_contacts);
  g_clear_object (&item->result);

  g_slice_free (BlockedChangedItem, item);
}

static void process_queued_blocked_changed (TpConnection *self);

void
_tp_connection_set_contact_blocked (TpConnection *self,
    TpContact *contact)
{
  gboolean blocked;

  blocked = tp_g_ptr_array_contains (self->priv->blocked_contacts,
      contact);

  _tp_contact_set_is_blocked (contact, blocked);
}

static void
blocked_changed_head_ready (TpConnection *self)
{
  BlockedChangedItem *item;

  item = g_queue_pop_head (self->priv->blocked_changed_queue);

  if (item->result != NULL)
    {
      /* Finish preparing TP_CONNECTION_FEATURE_CONTACT_BLOCKING; we can
       * prepare TP_CONTACT_FEATURE_CONTACT_BLOCKING on all contacts as we
       * have now the list of blocked contacts. */
      GHashTableIter iter;
      gpointer contact;

      g_hash_table_iter_init (&iter, self->priv->contacts);
      while (g_hash_table_iter_next (&iter, NULL, &contact))
        {
          _tp_connection_set_contact_blocked (self, contact);
        }

      g_simple_async_result_complete_in_idle (item->result);
    }

  blocked_changed_item_free (item);
  process_queued_blocked_changed (self);
}

static void
blocked_contacts_upgraded_cb (GObject *object,
    GAsyncResult *result,
    gpointer user_data)
{
  TpSimpleClientFactory *factory = (TpSimpleClientFactory *) object;
  TpConnection *self = user_data;
  BlockedChangedItem *item;
  guint i;
  GPtrArray *added, *removed;
  GPtrArray *contacts;
  GError *error = NULL;

  item = g_queue_peek_head (self->priv->blocked_changed_queue);

  if (!tp_simple_client_factory_upgrade_contacts_finish (factory, result,
          &contacts, &error))
    {
      DEBUG ("Error upgrading blocked contacts: %s", error->message);
      g_clear_error (&error);
      goto out;
    }

  added = g_ptr_array_new ();
  removed = g_ptr_array_new_with_free_func (g_object_unref);

  for (i = 0; i < contacts->len; i++)
    {
      TpContact *contact = g_ptr_array_index (contacts, i);
      TpHandle handle;

      handle = tp_contact_get_handle (contact);

      if (g_hash_table_lookup (item->added, GUINT_TO_POINTER (handle)) != NULL)
        {
          DEBUG ("Contact %s is blocked",
              tp_contact_get_identifier (contact));

          g_ptr_array_add (self->priv->blocked_contacts,
              g_object_ref (contact));

          g_ptr_array_add (added, contact);
        }
      else if (g_hash_table_lookup (item->removed,
            GUINT_TO_POINTER (handle)) != NULL)
        {
          DEBUG ("Contact %s is no longer blocked",
              tp_contact_get_identifier (contact));

          /* Ref the contact as removing it from blocked_contacts may drop its
           * last ref. */
          g_ptr_array_add (removed, g_object_ref (contact));

          g_ptr_array_remove (self->priv->blocked_contacts, contact);
        }
      else
        {
          g_assert_not_reached ();
        }
    }

  g_object_notify (G_OBJECT (self), "blocked-contacts");

  g_signal_emit_by_name (self, "blocked-contacts-changed", added, removed);

  g_ptr_array_unref (added);
  g_ptr_array_unref (removed);
  g_ptr_array_unref (contacts);

out:
  blocked_changed_head_ready (self);
}

static void
process_queued_blocked_changed (TpConnection *self)
{
  BlockedChangedItem *item;
  GHashTableIter iter;
  gpointer key, value;
  GPtrArray *contacts;

  item = g_queue_peek_head (self->priv->blocked_changed_queue);
  if (item == NULL)
    return;

  /* contacts will contain the union of item->added_contacts and
   * item->removed_contacts */
  contacts = g_ptr_array_new ();

  g_hash_table_iter_init (&iter, item->added);
  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      TpHandle handle = GPOINTER_TO_UINT (key);
      const gchar *identifier = value;
      TpContact *contact;

      contact = tp_simple_client_factory_ensure_contact (
          tp_proxy_get_factory (self), self, handle, identifier);

      g_ptr_array_add (item->added_contacts, contact);
      g_ptr_array_add (contacts, contact);

      _tp_contact_set_is_blocked (contact, TRUE);
    }

  g_hash_table_iter_init (&iter, item->removed);
  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      TpHandle handle = GPOINTER_TO_UINT (key);
      const gchar *identifier = value;
      TpContact *contact;

      contact = tp_simple_client_factory_ensure_contact (
          tp_proxy_get_factory (self), self, handle, identifier);

      g_ptr_array_add (item->removed_contacts, contact);
      g_ptr_array_add (contacts, contact);

      _tp_contact_set_is_blocked (contact, FALSE);
    }

  if (contacts->len == 0)
    {
      blocked_changed_head_ready (self);
      g_ptr_array_unref (contacts);
      return;
    }

  tp_simple_client_factory_upgrade_contacts_async (tp_proxy_get_factory (self),
      self, contacts->len, (TpContact **) contacts->pdata,
      blocked_contacts_upgraded_cb, self);

  g_ptr_array_unref (contacts);
}

static void
add_to_blocked_changed_queue (TpConnection *self,
    GHashTable *added,
    GHashTable *removed,
    GSimpleAsyncResult *result)
{
  BlockedChangedItem *item;

  item = blocked_changed_item_new (self, added, removed, result);
  g_queue_push_tail (self->priv->blocked_changed_queue, item);

  if (self->priv->blocked_changed_queue->length == 1)
    process_queued_blocked_changed (self);
}

static void
request_blocked_contacts_cb (TpConnection *self,
    GHashTable *contacts,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;

  self->priv->blocked_contacts_fetched = TRUE;

  if (error != NULL)
    {
      DEBUG ("Error calling RequestBlockedContacts: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
      g_simple_async_result_complete_in_idle (result);
      return;
    }

  /* We are not supposed to add items to this queue until the blocked contacts
   * have been fetched. */
  g_assert_cmpuint (self->priv->blocked_changed_queue->length, ==, 0);

  add_to_blocked_changed_queue (self, contacts, NULL, result);
}

static void
prepare_contact_blocking_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result = user_data;
  gboolean valid;

  if (error != NULL)
    {
      DEBUG ("Error preparing ContactBlocking properties: %s", error->message);
    }
  else
    {
      self->priv->contact_blocking_capabilities = tp_asv_get_uint32 (properties,
          "ContactBlockingCapabilities", &valid);
      if (!valid)
        {
          DEBUG ("Connection %s doesn't have ContactBlockingCapabilities "
              "property", tp_proxy_get_object_path (self));
        }
    }

  tp_cli_connection_interface_contact_blocking_call_request_blocked_contacts (
      self, -1, request_blocked_contacts_cb, g_object_ref (result),
      g_object_unref, G_OBJECT (self));
}

static void
blocked_contacts_changed_cb (TpConnection *self,
    GHashTable *blocked,
    GHashTable *unblocked,
    gpointer user_data,
    GObject *weak_object)
{
  if (!self->priv->blocked_contacts_fetched)
    return;

  add_to_blocked_changed_queue (self, blocked, unblocked, NULL);
}

void
_tp_connection_prepare_contact_blocking_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result;
  GError *error = NULL;

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      _tp_connection_prepare_contact_blocking_async);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CONNECTION_INTERFACE_CONTACT_BLOCKING,
      prepare_contact_blocking_cb, result, g_object_unref, NULL);

  if (tp_cli_connection_interface_contact_blocking_connect_to_blocked_contacts_changed (self,
        blocked_contacts_changed_cb, NULL, NULL, NULL, &error) == NULL)
    {
      DEBUG ("Failed to connect to BlockedContactsChanged: %s", error->message);
      g_error_free (error);
    }
}

/**
 * tp_connection_can_report_abusive:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: the value of #TpConnection:can-report-abusive
 *
 * Since: 0.17.0
 */
gboolean
tp_connection_can_report_abusive (TpConnection *self)
{
  return (self->priv->contact_blocking_capabilities &
    TP_CONTACT_BLOCKING_CAPABILITY_CAN_REPORT_ABUSIVE) != 0;
}

/**
 * tp_connection_get_blocked_contacts:
 * @self: a #TpConnection
 *
 * <!-- -->
 *
 * Returns: (transfer none) (element-type TelepathyGLib.Contact): the value of
 * #TpConnection:blocked-contacts
 *
 * Since: 0.17.0
 */
GPtrArray *
tp_connection_get_blocked_contacts (TpConnection *self)
{
  return self->priv->blocked_contacts;
}

void
_tp_connection_blocked_changed_queue_free (GQueue *queue)
{
  g_queue_foreach (queue, (GFunc) blocked_changed_item_free, NULL);
  g_queue_free (queue);
}

/**
 * TP_CONNECTION_FEATURE_CONTACT_LIST_PROPERTIES:
 *
 * Expands to a call to a function that returns a #GQuark representing the
 * "contact-list-properties" feature.
 *
 * When this feature is prepared, the contact list properties of the Connection
 * has been retrieved.
 * This feature will fail to prepare when using obsolete Telepathy connection
 * managers which do not implement the ContactList interface.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.17.0
 */
GQuark
tp_connection_get_feature_quark_contact_list_properties (void)
{
  return g_quark_from_static_string (
      "tp-connection-feature-contact-list-properties");
}
