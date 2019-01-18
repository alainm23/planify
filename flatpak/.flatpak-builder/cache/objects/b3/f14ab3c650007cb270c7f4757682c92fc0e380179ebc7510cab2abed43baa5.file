/*
 * channel.c - proxy for a Telepathy channel (Group interface)
 *
 * Copyright (C) 2007-2008 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2007-2008 Nokia Corporation
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

#include "telepathy-glib/channel-internal.h"

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/proxy-subclass.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_GROUPS
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/proxy-internal.h"

/* channel-group.c is ~all deprecated APIs, modern APIs are in
 * channel-contacts.c. So we allow this module to use deprecated functions. */
G_GNUC_BEGIN_IGNORE_DEPRECATIONS

/**
 * TP_ERRORS_REMOVED_FROM_GROUP:
 *
 * #GError domain representing the local user being removed from a channel
 * with the Group interface. The @code in a #GError with this domain must
 * be a member of #TpChannelGroupChangeReason.
 *
 * This error may be raised on non-Group channels with certain reason codes
 * if there's no better error code to use (mainly
 * %TP_CHANNEL_GROUP_CHANGE_REASON_NONE).
 *
 * This macro expands to a function call returning a #GQuark.
 *
 * Since: 0.7.1
 */
GQuark
tp_errors_removed_from_group_quark (void)
{
  static GQuark q = 0;

  if (q == 0)
    q = g_quark_from_static_string ("tp_errors_removed_from_group_quark");

  return q;
}


static void
local_pending_info_free (LocalPendingInfo *info)
{
  g_free (info->message);
  g_clear_object (&info->actor_contact);
  g_slice_free (LocalPendingInfo, info);
}


/**
 * tp_channel_group_get_self_handle:
 * @self: a channel
 *
 * Return the #TpChannel:group-self-handle property (see the description
 * of that property for notes on validity).
 *
 * Returns: the handle representing the user, or 0
 * Since: 0.7.12
 * Deprecated: New code should use tp_channel_group_get_self_contact() instead.
 */
TpHandle
tp_channel_group_get_self_handle (TpChannel *self)
{
  g_return_val_if_fail (TP_IS_CHANNEL (self), 0);

  return self->priv->group_self_handle;
}


/**
 * tp_channel_group_get_flags:
 * @self: a channel
 *
 * Return the #TpChannel:group-flags property (see the description
 * of that property for notes on validity).
 *
 * Returns: the group flags, or 0
 * Since: 0.7.12
 */
TpChannelGroupFlags
tp_channel_group_get_flags (TpChannel *self)
{
  g_return_val_if_fail (TP_IS_CHANNEL (self), 0);

  return self->priv->group_flags;
}


/**
 * tp_channel_group_get_members:
 * @self: a channel
 *
 * If @self is a group and the %TP_CHANNEL_FEATURE_GROUP feature has been
 * prepared, return a #TpIntset containing its members.
 *
 * If @self is a group but %TP_CHANNEL_FEATURE_GROUP has not been prepared,
 * the result may either be a set of members, or %NULL.
 *
 * If @self is not a group, return %NULL.
 *
 * Returns: (transfer none): the members, or %NULL
 * Since: 0.7.12
 * Deprecated: New code should use tp_channel_group_dup_members_contacts()
 *  instead.
 */
const TpIntset *
tp_channel_group_get_members (TpChannel *self)
{
  g_return_val_if_fail (TP_IS_CHANNEL (self), NULL);

  return self->priv->group_members;
}


/**
 * tp_channel_group_get_local_pending:
 * @self: a channel
 *
 * If @self is a group and the %TP_CHANNEL_FEATURE_GROUP feature has been
 * prepared, return a #TpIntset containing its local-pending members.
 *
 * If @self is a group but %TP_CHANNEL_FEATURE_GROUP has not been prepared,
 * the result may either be a set of local-pending members, or %NULL.
 *
 * If @self is not a group, return %NULL.
 *
 * Returns: (transfer none): the local-pending members, or %NULL
 * Since: 0.7.12
 * Deprecated: New code should use tp_channel_group_dup_local_pending_contacts()
 *  instead.
 */
const TpIntset *
tp_channel_group_get_local_pending (TpChannel *self)
{
  g_return_val_if_fail (TP_IS_CHANNEL (self), NULL);

  return self->priv->group_local_pending;
}


/**
 * tp_channel_group_get_remote_pending:
 * @self: a channel
 *
 * If @self is a group and the %TP_CHANNEL_FEATURE_GROUP feature has been
 * prepared, return a #TpIntset containing its remote-pending members.
 *
 * If @self is a group but %TP_CHANNEL_FEATURE_GROUP has not been prepared,
 * the result may either be a set of remote-pending members, or %NULL.
 *
 * If @self is not a group, return %NULL.
 *
 * Returns: (transfer none): the remote-pending members, or %NULL
 * Since: 0.7.12
 * Deprecated: New code should use
 *  tp_channel_group_dup_remote_pending_contacts() instead.
  */
const TpIntset *
tp_channel_group_get_remote_pending (TpChannel *self)
{
  g_return_val_if_fail (TP_IS_CHANNEL (self), NULL);

  return self->priv->group_remote_pending;
}


/**
 * tp_channel_group_get_local_pending_info:
 * @self: a channel
 * @local_pending: the handle of a local-pending contact about whom more
 *  information is needed
 * @actor: (out) (allow-none): either %NULL or a location to return the contact
 * who requested the change
 * @reason: (out) (allow-none): either %NULL or a location to return the reason
 * for the change
 * @message: (out) (transfer none) (allow-none): either %NULL or a location to
 * return the user-supplied message
 *
 * If @local_pending is actually the handle of a local-pending contact,
 * write additional information into @actor, @reason and @message and return
 * %TRUE. The handle and message are not referenced or copied, and can only be
 * assumed to remain valid until the main loop is re-entered.
 *
 * If @local_pending is not the handle of a local-pending contact,
 * write 0 into @actor, %TP_CHANNEL_GROUP_CHANGE_REASON_NONE into @reason
 * and "" into @message, and return %FALSE.
 *
 * Returns: %TRUE if the contact is in fact local-pending
 * Since: 0.7.12
 * Deprecated: New code should use
 *  tp_channel_group_get_local_pending_contact_info() instead.
 */
gboolean
tp_channel_group_get_local_pending_info (TpChannel *self,
                                         TpHandle local_pending,
                                         TpHandle *actor,
                                         TpChannelGroupChangeReason *reason,
                                         const gchar **message)
{
  gboolean ret = FALSE;
  TpHandle a = 0;
  TpChannelGroupChangeReason r = TP_CHANNEL_GROUP_CHANGE_REASON_NONE;
  const gchar *m = "";

  g_return_val_if_fail (TP_IS_CHANNEL (self), FALSE);

  if (self->priv->group_local_pending != NULL)
    {
      /* it could conceivably be someone who is local-pending */

      ret = tp_intset_is_member (self->priv->group_local_pending,
          local_pending);

      if (ret && self->priv->group_local_pending_info != NULL)
        {
          /* we might even have information about them */
          LocalPendingInfo *info = g_hash_table_lookup (
              self->priv->group_local_pending_info,
              GUINT_TO_POINTER (local_pending));

          if (info != NULL)
            {
              a = info->actor;
              r = info->reason;

              if (info->message != NULL)
                m = info->message;
            }
          /* else we have no info, which means (0, NONE, NULL) */
        }
    }

  if (actor != NULL)
    *actor = a;

  if (message != NULL)
    *message = m;

  if (reason != NULL)
    *reason = r;

  return ret;
}


/**
 * tp_channel_group_get_handle_owner:
 * @self: a channel
 * @handle: a handle which is a member of this channel
 *
 * Synopsis (see below for further explanation):
 *
 * - if @self is not a group or @handle is not a member of this channel,
 *   result is undefined;
 * - if %TP_CHANNEL_FEATURE_GROUP has not yet been prepared, result is
 *   undefined;
 * - if @self does not have flags that include
 *   %TP_CHANNEL_GROUP_FLAG_PROPERTIES,
 *   result is undefined;
 * - if @handle is channel-specific and its globally valid "owner" is known,
 *   return that owner;
 * - if @handle is channel-specific and its globally valid "owner" is unknown,
 *   return zero;
 * - if @handle is globally valid, return @handle itself
 *
 * Some channels (those with flags that include
 * %TP_CHANNEL_GROUP_FLAG_CHANNEL_SPECIFIC_HANDLES) have a concept of
 * "channel-specific handles". These are handles that only have meaning within
 * the context of the channel - for instance, in XMPP Multi-User Chat,
 * participants in a chatroom are identified by an in-room JID consisting
 * of the JID of the chatroom plus a local nickname.
 *
 * Depending on the protocol and configuration, it might be possible to find
 * out what globally valid handle (i.e. an identifier that you could add to
 * your contact list) "owns" a channel-specific handle. For instance, in
 * most XMPP MUC chatrooms, normal users cannot see what global JID
 * corresponds to an in-room JID, but moderators can.
 *
 * This is further complicated by the fact that channels with channel-specific
 * handles can sometimes have members with globally valid handles (for
 * instance, if you invite someone to an XMPP MUC using their globally valid
 * JID, you would expect to see the handle representing that JID in the
 * Group's remote-pending set).
 *
 * This function's result is undefined unless the channel is ready
 * and its flags include %TP_CHANNEL_GROUP_FLAG_PROPERTIES (an implementation
 * without extra D-Bus round trips is not possible using the older API).
 *
 * Returns: the global handle that owns the given handle, or 0
 * Since: 0.7.12
 * Deprecated: New code should use tp_channel_group_get_contact_owner() instead.
 */
TpHandle
tp_channel_group_get_handle_owner (TpChannel *self,
                                   TpHandle handle)
{
  gpointer key, value;

  g_return_val_if_fail (TP_IS_CHANNEL (self), 0);

  if (self->priv->group_handle_owners == NULL)
    {
      /* undefined result - pretending it's global is probably as good as
       * any other behaviour, since we can't know either way */
      return handle;
    }

  if (g_hash_table_lookup_extended (self->priv->group_handle_owners,
        GUINT_TO_POINTER (handle), &key, &value))
    {
      /* channel-specific, value is either owner or 0 if unknown */
      return GPOINTER_TO_UINT (value);
    }
  else
    {
      /* either already globally valid, or not a member */
      return handle;
    }
}


/* This must be called before the local group members lists are created.  Until
 * this is called, the proxy is listening to both MembersChanged and
 * MembersChangedDetailed, but they are ignored until priv->group_members
 * exists.  If that list is created before one signal is disconnected, the
 * proxy will react to state changes twice and madness will ensue.
 */
static void
_got_initial_group_flags (TpChannel *self,
                          TpChannelGroupFlags flags)
{
  TpChannelPrivate *priv = self->priv;

  g_assert (priv->group_flags == 0);
  g_assert (self->priv->group_members == NULL);

  priv->group_flags = flags;
  DEBUG ("Initial GroupFlags: %u", flags);
  priv->have_group_flags = TRUE;

  if (flags != 0)
    g_object_notify ((GObject *) self, "group-flags");

  if (tp_proxy_get_invalidated (self) != NULL)
    {
      /* Because the proxy has been invalidated, it is not safe to call
       * tp_proxy_signal_connection_disconnect (below), so just return early */
      return;
    }

  /* If the channel claims to support MembersChangedDetailed, disconnect from
   * MembersChanged. Otherwise, disconnect from MembersChangedDetailed in case
   * it secretly emits it anyway, so we're only listening to one change
   * notification.
   */
  if (flags & TP_CHANNEL_GROUP_FLAG_MEMBERS_CHANGED_DETAILED)
    tp_proxy_signal_connection_disconnect (priv->members_changed_sig);
  else
    tp_proxy_signal_connection_disconnect (priv->members_changed_detailed_sig);

  priv->members_changed_sig = NULL;
  priv->members_changed_detailed_sig = NULL;
}


static void
tp_channel_got_group_flags_0_16_cb (TpChannel *self,
                                    guint flags,
                                    const GError *error,
                                    gpointer user_data G_GNUC_UNUSED,
                                    GObject *weak_object G_GNUC_UNUSED)
{
  g_assert (self->priv->group_flags == 0);

  if (error != NULL)
    {
      /* GetGroupFlags() has existed with its current signature since November
       * 2005. I think it's reasonable to say that if it doesn't work, the
       * channel is broken.
       */
      _tp_channel_abort_introspection (self, "GetGroupFlags() failed", error);
      return;
    }

  /* If we reach this point, GetAll has already failed... */
  if (flags & TP_CHANNEL_GROUP_FLAG_PROPERTIES)
    {
      DEBUG ("Treason uncloaked! The channel claims to support Group "
          "properties, but GetAll didn't work");
      flags &= ~TP_CHANNEL_GROUP_FLAG_PROPERTIES;
    }

  _got_initial_group_flags (self, flags);
  _tp_channel_continue_introspection (self);
}


static void
tp_channel_group_self_handle_changed_cb (TpChannel *self,
                                         guint self_handle,
                                         gpointer unused G_GNUC_UNUSED,
                                         GObject *unused_object G_GNUC_UNUSED)
{
  if (self_handle == self->priv->group_self_handle)
    return;

  DEBUG ("%p SelfHandle changed to %u", self, self_handle);

  self->priv->group_self_handle = self_handle;
  g_object_notify ((GObject *) self, "group-self-handle");
}


static void
tp_channel_group_self_contact_changed_cb (TpChannel *self,
    guint self_handle,
    const gchar *identifier,
    gpointer user_data,
    GObject *weak_object)
{
  tp_channel_group_self_handle_changed_cb (self, self_handle, user_data,
      weak_object);

  _tp_channel_contacts_self_contact_changed (self, self_handle,
      identifier);
}


static void
tp_channel_got_self_handle_0_16_cb (TpChannel *self,
                                    guint self_handle,
                                    const GError *error,
                                    gpointer user_data G_GNUC_UNUSED,
                                    GObject *weak_object G_GNUC_UNUSED)
{
  if (error != NULL)
    {
      DEBUG ("%p Group.GetSelfHandle() failed, assuming 0: %s", self,
          error->message);
      tp_channel_group_self_handle_changed_cb (self, 0, NULL, NULL);
    }
  else
    {
      DEBUG ("Initial Group.SelfHandle: %u", self_handle);
      tp_channel_group_self_handle_changed_cb (self, self_handle, NULL, NULL);
    }

  _tp_channel_continue_introspection (self);
}


static void
_tp_channel_get_self_handle_0_16 (TpChannel *self)
{
  tp_cli_channel_interface_group_call_get_self_handle (self, -1,
      tp_channel_got_self_handle_0_16_cb, NULL, NULL, NULL);
}


static void
_tp_channel_get_group_flags_0_16 (TpChannel *self)
{
  tp_cli_channel_interface_group_call_get_group_flags (self, -1,
      tp_channel_got_group_flags_0_16_cb, NULL, NULL, NULL);
}


static void
_tp_channel_group_set_one_lp (TpChannel *self,
                              TpHandle handle,
                              TpHandle actor,
                              TpChannelGroupChangeReason reason,
                              const gchar *message)
{
  LocalPendingInfo *info = NULL;

  g_assert (self->priv->group_local_pending != NULL);

  tp_intset_add (self->priv->group_local_pending, handle);
  tp_intset_remove (self->priv->group_members, handle);
  tp_intset_remove (self->priv->group_remote_pending, handle);

  if (actor == 0 && reason == TP_CHANNEL_GROUP_CHANGE_REASON_NONE &&
      tp_str_empty (message))
    {
      /* we just don't bother storing informationless local-pending */
      if (self->priv->group_local_pending_info != NULL)
        {
          g_hash_table_remove (self->priv->group_local_pending_info,
              GUINT_TO_POINTER (handle));
        }

      return;
    }

  if (self->priv->group_local_pending_info == NULL)
    {
      self->priv->group_local_pending_info = g_hash_table_new_full (
          g_direct_hash, g_direct_equal, NULL,
          (GDestroyNotify) local_pending_info_free);
    }
  else
    {
      info = g_hash_table_lookup (self->priv->group_local_pending_info,
          GUINT_TO_POINTER (handle));
    }

  if (info == NULL)
    {
      info = g_slice_new0 (LocalPendingInfo);
    }
  else
    {
      g_hash_table_steal (self->priv->group_local_pending_info,
          GUINT_TO_POINTER (handle));
    }

  info->actor = actor;
  info->reason = reason;
  g_free (info->message);

  if (tp_str_empty (message))
    info->message = NULL;
  else
    info->message = g_strdup (message);

  g_hash_table_insert (self->priv->group_local_pending_info,
      GUINT_TO_POINTER (handle), info);
}


static void
_tp_channel_group_set_lp (TpChannel *self,
                          const GPtrArray *info)
{
  guint i;

  /* should only be called during initialization */
  g_assert (self->priv->group_local_pending != NULL);
  g_assert (self->priv->group_local_pending_info == NULL);

  tp_intset_clear (self->priv->group_local_pending);

  /* NULL-safe for ease of use with tp_asv_get_boxed */
  if (info == NULL)
    {
      return;
    }

  for (i = 0; i < info->len; i++)
    {
      GValueArray *item = g_ptr_array_index (info, i);
      TpHandle handle = g_value_get_uint (item->values + 0);
      TpHandle actor = g_value_get_uint (item->values + 1);
      TpChannelGroupChangeReason reason = g_value_get_uint (
          item->values + 2);
      const gchar *message = g_value_get_string (item->values + 3);

      if (handle == 0)
        {
          DEBUG ("Ignoring handle 0, claimed to be in local-pending");
          continue;
        }

      DEBUG ("+L %u, actor=%u, reason=%u, message=%s", handle,
          actor, reason, message);
      _tp_channel_group_set_one_lp (self, handle, actor,
          reason, message);
    }
}


static void
tp_channel_got_all_members_0_16_cb (TpChannel *self,
                                    const GArray *members,
                                    const GArray *local_pending,
                                    const GArray *remote_pending,
                                    const GError *error,
                                    gpointer user_data G_GNUC_UNUSED,
                                    GObject *weak_object G_GNUC_UNUSED)
{
  g_assert (self->priv->group_local_pending == NULL);
  g_assert (self->priv->group_local_pending_info == NULL);
  g_assert (self->priv->group_members == NULL);
  g_assert (self->priv->group_remote_pending == NULL);

  if (error == NULL)
    {
      DEBUG ("%p GetAllMembers returned %u members + %u LP + %u RP",
          self, members->len, local_pending->len, remote_pending->len);

      self->priv->group_local_pending = tp_intset_from_array (local_pending);
      self->priv->group_members = tp_intset_from_array (members);
      self->priv->group_remote_pending = tp_intset_from_array (remote_pending);

      if (tp_intset_remove (self->priv->group_members, 0))
        {
          DEBUG ("Ignoring handle 0, claimed to be in group");
        }

      if (tp_intset_remove (self->priv->group_local_pending, 0))
        {
          DEBUG ("Ignoring handle 0, claimed to be in local-pending");
        }

      if (tp_intset_remove (self->priv->group_remote_pending, 0))
        {
          DEBUG ("Ignoring handle 0, claimed to be in remote-pending");
        }

      /* the local-pending info will be filled in with the result of
       * GetLocalPendingMembersWithInfo, if it succeeds */
    }
  else
    {
      DEBUG ("%p GetAllMembers failed, assuming empty: %s", self,
          error->message);

      self->priv->group_local_pending = tp_intset_new ();
      self->priv->group_members = tp_intset_new ();
      self->priv->group_remote_pending = tp_intset_new ();
    }

  g_assert (self->priv->group_local_pending != NULL);
  g_assert (self->priv->group_members != NULL);
  g_assert (self->priv->group_remote_pending != NULL);

  _tp_channel_continue_introspection (self);
}


static void
_tp_channel_get_all_members_0_16 (TpChannel *self)
{
  tp_cli_channel_interface_group_call_get_all_members (self, -1,
      tp_channel_got_all_members_0_16_cb, NULL, NULL, NULL);
}


static void
tp_channel_glpmwi_0_16_cb (TpChannel *self,
                           const GPtrArray *info,
                           const GError *error,
                           gpointer user_data G_GNUC_UNUSED,
                           GObject *object G_GNUC_UNUSED)
{
  /* this should always run after tp_channel_got_all_members_0_16 */
  g_assert (self->priv->group_local_pending != NULL);
  g_assert (self->priv->group_local_pending_info == NULL);

  if (error == NULL)
    {
      DEBUG ("%p GetLocalPendingMembersWithInfo returned %u records",
          self, info->len);
      _tp_channel_group_set_lp (self, info);
    }
  else
    {
      DEBUG ("%p GetLocalPendingMembersWithInfo failed, keeping result of "
          "GetAllMembers instead: %s", self, error->message);
    }

  _tp_channel_continue_introspection (self);
}


static void
_tp_channel_glpmwi_0_16 (TpChannel *self)
{
  tp_cli_channel_interface_group_call_get_local_pending_members_with_info (
      self, -1, tp_channel_glpmwi_0_16_cb, NULL, NULL, NULL);
}

static void
_tp_channel_emit_initial_sets (TpChannel *self)
{
  GArray *added, *remote_pending;
  GArray empty_array = { NULL, 0 };
  TpIntsetFastIter iter;
  TpHandle handle;

  tp_intset_fast_iter_init (&iter, self->priv->group_local_pending);

  added = tp_intset_to_array (self->priv->group_members);
  remote_pending = tp_intset_to_array (self->priv->group_remote_pending);

  g_signal_emit_by_name (self, "group-members-changed", "",
      added, &empty_array, &empty_array, remote_pending, 0, 0);

  while (tp_intset_fast_iter_next (&iter, &handle))
    {
      GArray local_pending = { (gchar *) &handle, 1 };
      TpHandle actor;
      TpChannelGroupChangeReason reason;
      const gchar *message;

      tp_channel_group_get_local_pending_info (self, handle, &actor, &reason,
          &message);

      g_signal_emit_by_name (self, "group-members-changed", message,
          &empty_array, &empty_array, &local_pending, &empty_array, actor,
          reason);
    }

  g_array_unref (added);
  g_array_unref (remote_pending);

  _tp_channel_continue_introspection (self);
}

static void
tp_channel_got_group_properties_cb (TpProxy *proxy,
                                    GHashTable *asv,
                                    const GError *error,
                                    gpointer unused G_GNUC_UNUSED,
                                    GObject *unused_object G_GNUC_UNUSED)
{
  TpChannel *self = TP_CHANNEL (proxy);
  static GType au_type = 0;

  if (G_UNLIKELY (au_type == 0))
    {
      au_type = dbus_g_type_get_collection ("GArray", G_TYPE_UINT);
    }

  if (error != NULL)
    {
      DEBUG ("Error getting group properties, falling back to 0.16 API: %s",
          error->message);
    }
  else if ((tp_asv_get_uint32 (asv, "GroupFlags", NULL)
      & TP_CHANNEL_GROUP_FLAG_PROPERTIES) == 0)
    {
      DEBUG ("Got group properties, but no Properties flag: assuming a "
          "broken implementation and falling back to 0.16 API");
    }
  else
    {
      GHashTable *table;
      GArray *arr;

      DEBUG ("Received %u group properties", g_hash_table_size (asv));

      _got_initial_group_flags (self,
          tp_asv_get_uint32 (asv, "GroupFlags", NULL));

      tp_channel_group_self_handle_changed_cb (self,
          tp_asv_get_uint32 (asv, "SelfHandle", NULL), NULL, NULL);

      g_assert (self->priv->group_members == NULL);
      g_assert (self->priv->group_remote_pending == NULL);

      arr = tp_asv_get_boxed (asv, "Members", au_type);

      if (arr == NULL)
        self->priv->group_members = tp_intset_new ();
      else
        self->priv->group_members = tp_intset_from_array (arr);

      if (tp_intset_remove (self->priv->group_members, 0))
        {
          DEBUG ("Ignoring handle 0, claimed to be in group");
        }

      arr = tp_asv_get_boxed (asv, "RemotePendingMembers", au_type);

      if (arr == NULL)
        self->priv->group_remote_pending = tp_intset_new ();
      else
        self->priv->group_remote_pending = tp_intset_from_array (arr);

      if (tp_intset_remove (self->priv->group_remote_pending, 0))
        {
          DEBUG ("Ignoring handle 0, claimed to be in remote-pending");
        }

      g_assert (self->priv->group_local_pending == NULL);
      g_assert (self->priv->group_local_pending_info == NULL);

      self->priv->group_local_pending = tp_intset_new ();

      /* this is NULL-safe with respect to the array */
      _tp_channel_group_set_lp (self,
          tp_asv_get_boxed (asv, "LocalPendingMembers",
              TP_ARRAY_TYPE_LOCAL_PENDING_INFO_LIST));

      table = tp_asv_get_boxed (asv, "HandleOwners",
          TP_HASH_TYPE_HANDLE_OWNER_MAP);

      self->priv->group_handle_owners = g_hash_table_new (g_direct_hash,
          g_direct_equal);

      if (table != NULL)
        tp_g_hash_table_update (self->priv->group_handle_owners,
            table, NULL, NULL);

      table = tp_asv_get_boxed (asv, "MemberIdentifiers",
          TP_HASH_TYPE_HANDLE_IDENTIFIER_MAP);

      /* If CM implements MemberIdentifiers property, assume it also emits
       * SelfContactChanged and HandleOwnersChangedDetailed */
      if (table != NULL)
        {
          tp_proxy_signal_connection_disconnect (
              self->priv->self_handle_changed_sig);
          tp_proxy_signal_connection_disconnect (
              self->priv->handle_owners_changed_sig);
        }
      else
        {
          tp_proxy_signal_connection_disconnect (
              self->priv->self_contact_changed_sig);
          tp_proxy_signal_connection_disconnect (
              self->priv->handle_owners_changed_detailed_sig);
        }

      self->priv->self_handle_changed_sig = NULL;
      self->priv->self_contact_changed_sig = NULL;
      self->priv->handle_owners_changed_sig = NULL;
      self->priv->handle_owners_changed_detailed_sig = NULL;

      _tp_channel_contacts_group_init (self, table);

      goto OUT;
    }

  /* Failure case: fall back. This is quite annoying, as we need to combine:
   *
   * - GetGroupFlags
   * - GetAllMembers
   * - GetLocalPendingMembersWithInfo
   *
   * Channel-specific handles can't really have a sane client API (without
   * lots of silly round-trips) unless the CM implements the HandleOwners
   * property, so I intend to ignore this in the fallback case.
   */

  g_queue_push_tail (self->priv->introspect_needed,
      _tp_channel_get_group_flags_0_16);

  g_queue_push_tail (self->priv->introspect_needed,
      _tp_channel_get_self_handle_0_16);

  g_queue_push_tail (self->priv->introspect_needed,
      _tp_channel_get_all_members_0_16);

  g_queue_push_tail (self->priv->introspect_needed,
      _tp_channel_glpmwi_0_16);

  self->priv->cm_too_old_for_contacts = TRUE;

OUT:

  g_queue_push_tail (self->priv->introspect_needed,
      _tp_channel_emit_initial_sets);

  _tp_channel_continue_introspection (self);
}

/*
 * If the @group_remove_error is derived from a TpChannelGroupChangeReason,
 * attempt to rewrite it into a TpError.
 */
static void
_tp_channel_group_improve_remove_error (TpChannel *self,
    TpHandle actor)
{
  GError *error = self->priv->group_remove_error;

  if (error == NULL || error->domain != TP_ERRORS_REMOVED_FROM_GROUP)
    return;

  switch (error->code)
    {
    case TP_CHANNEL_GROUP_CHANGE_REASON_NONE:
      if (actor == self->priv->group_self_handle ||
          actor == tp_connection_get_self_handle (self->priv->connection))
        {
          error->code = TP_ERROR_CANCELLED;
        }
      else
        {
          error->code = TP_ERROR_TERMINATED;
        }
      break;

    case TP_CHANNEL_GROUP_CHANGE_REASON_OFFLINE:
      error->code = TP_ERROR_OFFLINE;
      break;

    case TP_CHANNEL_GROUP_CHANGE_REASON_KICKED:
      error->code = TP_ERROR_CHANNEL_KICKED;
      break;

    case TP_CHANNEL_GROUP_CHANGE_REASON_BUSY:
      error->code = TP_ERROR_BUSY;
      break;

    case TP_CHANNEL_GROUP_CHANGE_REASON_INVITED:
      DEBUG ("%s: Channel_Group_Change_Reason_Invited makes no sense as a "
          "removal reason!", tp_proxy_get_object_path (self));
      error->domain = TP_DBUS_ERRORS;
      error->code = TP_DBUS_ERROR_INCONSISTENT;
      return;

    case TP_CHANNEL_GROUP_CHANGE_REASON_BANNED:
      error->code = TP_ERROR_CHANNEL_BANNED;
      break;

    case TP_CHANNEL_GROUP_CHANGE_REASON_ERROR:
      /* hopefully all CMs that use this will also give us an error detail,
       * but if they didn't, or gave us one we didn't understand... */
      error->code = TP_ERROR_NOT_AVAILABLE;
      break;

    case TP_CHANNEL_GROUP_CHANGE_REASON_INVALID_CONTACT:
      error->code = TP_ERROR_DOES_NOT_EXIST;
      break;

    case TP_CHANNEL_GROUP_CHANGE_REASON_NO_ANSWER:
      error->code = TP_ERROR_NO_ANSWER;
      break;

    /* TP_CHANNEL_GROUP_CHANGE_REASON_RENAMED shouldn't be the last error
     * seen in the channel - we'll get removed again with a real reason,
     * later, so there's no point in doing anything special with this one */

    case TP_CHANNEL_GROUP_CHANGE_REASON_PERMISSION_DENIED:
      error->code = TP_ERROR_PERMISSION_DENIED;
      break;

    case TP_CHANNEL_GROUP_CHANGE_REASON_SEPARATED:
      DEBUG ("%s: Channel_Group_Change_Reason_Separated makes no sense as a "
          "removal reason!", tp_proxy_get_object_path (self));
      error->domain = TP_DBUS_ERRORS;
      error->code = TP_DBUS_ERROR_INCONSISTENT;
      return;

    /* all values up to and including Separated have been checked */

    default:
      /* We don't understand this reason code, so keeping the domain and code
       * the same (i.e. using TP_ERRORS_REMOVED_FROM_GROUP) is no worse than
       * anything else we could do. */
      return;
    }

  /* If we changed the code we also need to change the domain; if not, we did
   * an early return, so we'll never reach this */
  error->domain = TP_ERROR;
}

static void
handle_members_changed (TpChannel *self,
                        const gchar *message,
                        const GArray *added,
                        const GArray *removed,
                        const GArray *local_pending,
                        const GArray *remote_pending,
                        guint actor,
                        guint reason,
                        GHashTable *details)
{
  guint i;

  if (self->priv->group_members == NULL)
    return;

  g_assert (self->priv->group_local_pending != NULL);
  g_assert (self->priv->group_remote_pending != NULL);

  for (i = 0; i < added->len; i++)
    {
      TpHandle handle = g_array_index (added, guint, i);

      DEBUG ("+++ contact#%u", handle);

      if (handle == 0)
        {
          DEBUG ("handle 0 shouldn't be in MembersChanged, ignoring");
          continue;
        }

      tp_intset_add (self->priv->group_members, handle);
      tp_intset_remove (self->priv->group_local_pending, handle);
      tp_intset_remove (self->priv->group_remote_pending, handle);
    }

  for (i = 0; i < local_pending->len; i++)
    {
      TpHandle handle = g_array_index (local_pending, guint, i);

      DEBUG ("+LP contact#%u", handle);

      if (handle == 0)
        {
          DEBUG ("handle 0 shouldn't be in MembersChanged, ignoring");
          continue;
        }

      /* Special-case renaming a local-pending contact, if the
       * signal is spec-compliant. Keep the old actor/reason/message in
       * this case */
      if (reason == TP_CHANNEL_GROUP_CHANGE_REASON_RENAMED &&
          added->len == 0 &&
          local_pending->len == 1 &&
          remote_pending->len == 0 &&
          removed->len == 1 &&
          self->priv->group_local_pending_info != NULL)
        {
          TpHandle old = g_array_index (removed, guint, 0);
          LocalPendingInfo *info = g_hash_table_lookup (
              self->priv->group_local_pending_info,
              GUINT_TO_POINTER (old));

          if (info != NULL)
            {
              _tp_channel_group_set_one_lp (self, handle,
                  info->actor, info->reason, info->message);
              continue;
            }
        }

      /* not reached if the Renamed special case occurred */
      _tp_channel_group_set_one_lp (self, handle, actor,
          reason, message);
    }

  for (i = 0; i < remote_pending->len; i++)
    {
      TpHandle handle = g_array_index (remote_pending, guint, i);

      DEBUG ("+RP contact#%u", handle);

      if (handle == 0)
        {
          DEBUG ("handle 0 shouldn't be in MembersChanged, ignoring");
          continue;
        }

      tp_intset_add (self->priv->group_remote_pending, handle);
      tp_intset_remove (self->priv->group_members, handle);
      tp_intset_remove (self->priv->group_local_pending, handle);
    }

  for (i = 0; i < removed->len; i++)
    {
      TpHandle handle = g_array_index (removed, guint, i);

      DEBUG ("--- contact#%u", handle);

      if (handle == 0)
        {
          DEBUG ("handle 0 shouldn't be in MembersChanged, ignoring");
          continue;
        }

      if (self->priv->group_local_pending_info != NULL)
        g_hash_table_remove (self->priv->group_local_pending_info,
            GUINT_TO_POINTER (handle));

      tp_intset_remove (self->priv->group_members, handle);
      tp_intset_remove (self->priv->group_local_pending, handle);
      tp_intset_remove (self->priv->group_remote_pending, handle);

      if (handle == self->priv->group_self_handle ||
          handle == tp_connection_get_self_handle (self->priv->connection))
        {
          const gchar *error_detail = tp_asv_get_string (details, "error");
          const gchar *debug_message = tp_asv_get_string (details,
              "debug-message");

          if (debug_message == NULL && !tp_str_empty (message))
            debug_message = message;

          if (debug_message == NULL && error_detail != NULL)
            debug_message = error_detail;

          if (debug_message == NULL)
            debug_message = "(no message provided)";

          if (self->priv->group_remove_error != NULL)
            g_clear_error (&self->priv->group_remove_error);

          if (error_detail != NULL)
            {
              /* CM specified a D-Bus error name */
              tp_proxy_dbus_error_to_gerror (self, error_detail,
                  debug_message == NULL || debug_message[0] == '\0'
                      ? error_detail
                      : debug_message,
                  &self->priv->group_remove_error);

              /* ... but if we don't know anything about that D-Bus error
               * name, we can still do better by using RemovedFromGroup */
              if (g_error_matches (self->priv->group_remove_error,
                    TP_DBUS_ERRORS, TP_DBUS_ERROR_UNKNOWN_REMOTE_ERROR))
                {
                  self->priv->group_remove_error->domain =
                    TP_ERRORS_REMOVED_FROM_GROUP;
                  self->priv->group_remove_error->code = reason;

                  _tp_channel_group_improve_remove_error (self, actor);
                }
            }
          else
            {
              /* Use our separate error domain */
              g_set_error_literal (&self->priv->group_remove_error,
                  TP_ERRORS_REMOVED_FROM_GROUP, reason, debug_message);

              _tp_channel_group_improve_remove_error (self, actor);
            }
        }
    }

  g_signal_emit_by_name (self, "group-members-changed", message,
      added, removed, local_pending, remote_pending, actor, reason);
  g_signal_emit_by_name (self, "group-members-changed-detailed", added,
      removed, local_pending, remote_pending, details);

  _tp_channel_contacts_members_changed (self, added, removed,
      local_pending, remote_pending, actor, details);
}


static void
tp_channel_group_members_changed_cb (TpChannel *self,
                                     const gchar *message,
                                     const GArray *added,
                                     const GArray *removed,
                                     const GArray *local_pending,
                                     const GArray *remote_pending,
                                     guint actor,
                                     guint reason,
                                     gpointer unused G_GNUC_UNUSED,
                                     GObject *unused_object G_GNUC_UNUSED)
{
  GHashTable *details = g_hash_table_new_full (g_str_hash, g_str_equal, NULL,
      (GDestroyNotify) tp_g_value_slice_free);

  DEBUG ("%p MembersChanged: added %u, removed %u, "
      "moved %u to LP and %u to RP, actor %u, reason %u, message %s",
      self, added->len, removed->len, local_pending->len, remote_pending->len,
      actor, reason, message);

  if (actor != 0)
    {
      g_hash_table_insert (details, "actor",
          tp_g_value_slice_new_uint (actor));
    }

  if (reason != TP_CHANNEL_GROUP_CHANGE_REASON_NONE)
    {
      g_hash_table_insert (details, "change-reason",
          tp_g_value_slice_new_uint (reason));
    }

  if (*message != '\0')
    {
      g_hash_table_insert (details, "message",
          tp_g_value_slice_new_string (message));
    }

  handle_members_changed (self, message, added, removed, local_pending,
      remote_pending, actor, reason, details);

  g_hash_table_unref (details);
}


static void
tp_channel_group_members_changed_detailed_cb (TpChannel *self,
                                              const GArray *added,
                                              const GArray *removed,
                                              const GArray *local_pending,
                                              const GArray *remote_pending,
                                              GHashTable *details,
                                              gpointer unused G_GNUC_UNUSED,
                                              GObject *weak_obj G_GNUC_UNUSED)
{
  const gchar *message;
  guint actor;
  guint reason;

  DEBUG ("%p MembersChangedDetailed: added %u, removed %u, "
      "moved %u to LP and %u to RP",
      self, added->len, removed->len, local_pending->len, remote_pending->len);

  actor = tp_asv_get_uint32 (details, "actor", NULL);
  reason = tp_asv_get_uint32 (details, "change-reason", NULL);
  message = tp_asv_get_string (details, "message");

  if (message == NULL)
    message = "";

  handle_members_changed (self, message, added, removed, local_pending,
      remote_pending, actor, reason, details);
}


static void
tp_channel_handle_owners_changed_cb (TpChannel *self,
                                     GHashTable *added,
                                     const GArray *removed,
                                     gpointer unused G_GNUC_UNUSED,
                                     GObject *unused_object G_GNUC_UNUSED)
{
  guint i;

  /* ignore the signal if we don't have the initial set yet */
  if (self->priv->group_handle_owners == NULL)
    return;

  tp_g_hash_table_update (self->priv->group_handle_owners, added, NULL, NULL);

  for (i = 0; i < removed->len; i++)
    {
      g_hash_table_remove (self->priv->group_handle_owners,
          GUINT_TO_POINTER (g_array_index (removed, guint, i)));
    }
}


static void
tp_channel_handle_owners_changed_detailed_cb (TpChannel *self,
    GHashTable *added,
    const GArray *removed,
    GHashTable *identifiers,
    gpointer user_data,
    GObject *weak_object)
{
  tp_channel_handle_owners_changed_cb (self, added, removed, user_data,
      weak_object);

  _tp_channel_contacts_handle_owners_changed (self, added, removed,
      identifiers);
}


#define IMMUTABLE_FLAGS \
  (TP_CHANNEL_GROUP_FLAG_PROPERTIES | \
  TP_CHANNEL_GROUP_FLAG_MEMBERS_CHANGED_DETAILED)

static void
tp_channel_group_flags_changed_cb (TpChannel *self,
                                   guint added,
                                   guint removed,
                                   gpointer unused G_GNUC_UNUSED,
                                   GObject *unused_object G_GNUC_UNUSED)
{
  if (self->priv->have_group_flags)
    {
      DEBUG ("%p GroupFlagsChanged: +%u -%u", self, added, removed);

      added &= ~(self->priv->group_flags);
      removed &= self->priv->group_flags;

      DEBUG ("%p GroupFlagsChanged (after filtering): +%u -%u",
          self, added, removed);

      if ((added & IMMUTABLE_FLAGS) || (removed & IMMUTABLE_FLAGS))
        {
          GError *e = g_error_new (TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
              "CM is broken: it changed the Properties/"
              "Members_Changed_Detailed flags on an existing group channel "
              "(offending changes: added=%u, removed=%u)",
              added & IMMUTABLE_FLAGS, removed & IMMUTABLE_FLAGS);

          tp_proxy_invalidate ((TpProxy *) self, e);
          g_error_free (e);
          return;
        }

      self->priv->group_flags |= added;
      self->priv->group_flags &= ~removed;

      if (added != 0 || removed != 0)
        {
          g_object_notify ((GObject *) self, "group-flags");
          g_signal_emit_by_name (self, "group-flags-changed", added, removed);
        }
    }
}

#undef IMMUTABLE_FLAGS


void
_tp_channel_get_group_properties (TpChannel *self)
{
  TpChannelPrivate *priv = self->priv;
  TpProxySignalConnection *sc;
  GError *error = NULL;

  if (!tp_proxy_has_interface_by_id (self,
        TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP))
    {
      _tp_proxy_set_feature_prepared ((TpProxy *) self,
          TP_CHANNEL_FEATURE_GROUP, FALSE);

      DEBUG ("%p: not a Group, continuing", self);
      _tp_channel_continue_introspection (self);
      return;
    }

  DEBUG ("%p", self);

  /* If this callback has been called, 'self' has not been invalidated. And we
   * just checked above that the proxy has the Group interface. So, connecting
   * to these signals must succeed. */
#define DIE(sig) \
  { \
    CRITICAL ("couldn't connect to " sig ": %s", error->message); \
    g_assert_not_reached (); \
    g_error_free (error); \
    return; \
  }

  priv->members_changed_sig =
      tp_cli_channel_interface_group_connect_to_members_changed (self,
          tp_channel_group_members_changed_cb, NULL, NULL, NULL, &error);

  if (priv->members_changed_sig == NULL)
    DIE ("MembersChanged");

  priv->members_changed_detailed_sig =
      tp_cli_channel_interface_group_connect_to_members_changed_detailed (self,
          tp_channel_group_members_changed_detailed_cb, NULL, NULL, NULL,
          &error);

  if (priv->members_changed_detailed_sig == NULL)
    DIE ("MembersChangedDetailed");

  sc = tp_cli_channel_interface_group_connect_to_group_flags_changed (self,
      tp_channel_group_flags_changed_cb, NULL, NULL, NULL, &error);

  if (sc == NULL)
    DIE ("GroupFlagsChanged");

  priv->self_handle_changed_sig =
      tp_cli_channel_interface_group_connect_to_self_handle_changed (self,
          tp_channel_group_self_handle_changed_cb, NULL, NULL, NULL, &error);

  if (priv->self_handle_changed_sig == NULL)
    DIE ("SelfHandleChanged");

  priv->self_contact_changed_sig =
      tp_cli_channel_interface_group_connect_to_self_contact_changed (self,
          tp_channel_group_self_contact_changed_cb, NULL, NULL, NULL, &error);

  if (priv->self_contact_changed_sig == NULL)
    DIE ("SelfContactChanged");

  priv->handle_owners_changed_sig =
      tp_cli_channel_interface_group_connect_to_handle_owners_changed (self,
          tp_channel_handle_owners_changed_cb, NULL, NULL, NULL, &error);

  if (priv->handle_owners_changed_sig == NULL)
    DIE ("HandleOwnersChanged");

  priv->handle_owners_changed_detailed_sig =
      tp_cli_channel_interface_group_connect_to_handle_owners_changed_detailed (
          self, tp_channel_handle_owners_changed_detailed_cb, NULL, NULL, NULL,
          &error);

  if (priv->handle_owners_changed_detailed_sig == NULL)
    DIE ("HandleOwnersChangedDetailed");

  /* First try the 0.17 API (properties). If this fails we'll fall back */
  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CHANNEL_INTERFACE_GROUP, tp_channel_got_group_properties_cb,
      NULL, NULL, NULL);
}

G_GNUC_END_IGNORE_DEPRECATIONS
