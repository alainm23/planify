/*
 * group-mixin.c - Source for TpGroupMixin
 *
 * Copyright (C) 2006-2007 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2006-2007 Nokia Corporation
 *   @author Ole Andre Vadla Ravnaas <ole.andre.ravnaas@collabora.co.uk>
 *   @author Robert McQueen <robert.mcqueen@collabora.co.uk>
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

/**
 * SECTION:group-mixin
 * @title: TpGroupMixin
 * @short_description: a mixin implementation of the groups interface
 * @see_also: #TpSvcChannelInterfaceGroup
 *
 * This mixin can be added to a channel GObject class to implement the
 * groups interface in a general way.
 *
 * To use the group mixin, include a #TpGroupMixinClass somewhere in your
 * class structure and a #TpGroupMixin somewhere in your instance structure,
 * and call tp_group_mixin_class_init() from your class_init function,
 * tp_group_mixin_init() from your init function or constructor, and
 * tp_group_mixin_finalize() from your dispose or finalize function.
 *
 * To use the group mixin as the implementation of
 * #TpSvcChannelInterfaceGroup, call
 * <literal>G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP,
 * tp_group_mixin_iface_init)</literal> in the fourth argument to
 * <literal>G_DEFINE_TYPE_WITH_CODE</literal>.
 *
 * Since 0.5.13 you can also implement the group interface by forwarding all
 * group operations to the group mixin of an associated object (mainly useful
 * for Tubes channels). To do this, call tp_external_group_mixin_init()
 * in the constructor after the associated object has been set,
 * tp_external_group_mixin_finalize() in the dispose or finalize function, and
 * <literal>G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP,
 * tp_external_group_mixin_iface_init)</literal> in the fourth argument to
 * <literal>G_DEFINE_TYPE_WITH_CODE</literal>.
 *
 * Since 0.7.10 you can also implement the properties of Group channels,
 * by calling tp_group_mixin_init_dbus_properties() or
 * tp_external_group_mixin_init_dbus_properties() (as appropriate).
 */

#include "config.h"

#include <telepathy-glib/group-mixin.h>

#include <dbus/dbus-glib.h>
#include <stdio.h>
#include <string.h>

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/debug-ansi.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>

#define DEBUG_FLAG TP_DEBUG_GROUPS

#include "debug-internal.h"

static const char *
group_change_reason_str (guint reason)
{
  switch (reason)
    {
    case TP_CHANNEL_GROUP_CHANGE_REASON_NONE:
      return "unspecified reason";
    case TP_CHANNEL_GROUP_CHANGE_REASON_OFFLINE:
      return "offline";
    case TP_CHANNEL_GROUP_CHANGE_REASON_KICKED:
      return "kicked";
    case TP_CHANNEL_GROUP_CHANGE_REASON_BUSY:
      return "busy";
    case TP_CHANNEL_GROUP_CHANGE_REASON_INVITED:
      return "invited";
    case TP_CHANNEL_GROUP_CHANGE_REASON_BANNED:
      return "banned";
    case TP_CHANNEL_GROUP_CHANGE_REASON_ERROR:
      return "error";
    case TP_CHANNEL_GROUP_CHANGE_REASON_INVALID_CONTACT:
      return "invalid contact";
    case TP_CHANNEL_GROUP_CHANGE_REASON_NO_ANSWER:
      return "no answer";
    case TP_CHANNEL_GROUP_CHANGE_REASON_RENAMED:
      return "renamed";
    case TP_CHANNEL_GROUP_CHANGE_REASON_PERMISSION_DENIED:
      return "permission denied";
    case TP_CHANNEL_GROUP_CHANGE_REASON_SEPARATED:
      return "separated";
    default:
      return "(unknown reason code)";
    }
}

typedef struct {
  TpHandle actor;
  guint reason;
  const gchar *message;
  TpHandleRepoIface *repo;
} LocalPendingInfo;

static LocalPendingInfo *
local_pending_info_new (TpHandleRepoIface *repo,
                        TpHandle actor,
                        guint reason,
                        const gchar *message)
{
  LocalPendingInfo *info = g_slice_new0 (LocalPendingInfo);
  info->reason = reason;
  info->message = g_strdup (message);
  info->repo = repo;

  if (actor != 0)
    info->actor = actor;

  return info;
}

static void
local_pending_info_free (LocalPendingInfo *info)
{
  g_free ((gchar *) info->message);
  g_slice_free (LocalPendingInfo, info);
}

struct _TpGroupMixinClassPrivate {
    TpGroupMixinRemMemberWithReasonFunc remove_with_reason;
    unsigned allow_self_removal : 1;
};

struct _TpGroupMixinPrivate {
    TpHandleSet *actors;
    GHashTable *handle_owners;
    GHashTable *local_pending_info;
    GPtrArray *externals;
};

/**
 * TP_HAS_GROUP_MIXIN:
 * @o: a #GObject instance
 *
 * <!-- -->
 *
 * Returns: %TRUE if @o (or one of its parent classes) has the group mixin.
 *
 * Since: 0.13.9
 */

/**
 * TP_HAS_GROUP_MIXIN_CLASS:
 * @cls: a #GObjectClass structure
 *
 * <!-- -->
 *
 * Returns: %TRUE if @cls (or one of its parent classes) has the group mixin.
 *
 * Since: 0.13.9
 */

/**
 * tp_group_mixin_class_get_offset_quark: (skip)
 *
 * <!--Returns: says it all-->
 *
 * Returns: the quark used for storing mixin offset on a GObjectClass
 */
GQuark
tp_group_mixin_class_get_offset_quark ()
{
  static GQuark offset_quark = 0;
  if (!offset_quark)
    offset_quark = g_quark_from_static_string ("TpGroupMixinClassOffsetQuark");
  return offset_quark;
}

/**
 * tp_group_mixin_get_offset_quark: (skip)
 *
 * <!--Returns: says it all-->
 *
 * Returns: the quark used for storing mixin offset on a GObject
 */
GQuark
tp_group_mixin_get_offset_quark ()
{
  static GQuark offset_quark = 0;
  if (!offset_quark)
    offset_quark = g_quark_from_static_string ("TpGroupMixinOffsetQuark");
  return offset_quark;
}

/**
 * tp_group_mixin_class_set_remove_with_reason_func: (skip)
 * @cls: The class of an object implementing the group interface using this
 *  mixin
 * @func: A callback to be used to remove contacts from this group with a
 *  specified reason.
 *
 * Set a callback to be used to implement RemoveMembers() and
 * RemoveMembersWithReason(). If this function is called during class
 * initialization, the given callback will be used instead of the remove
 * callback passed to tp_group_mixin_class_init() (which must be %NULL
 * in this case).
 *
 * Since: 0.5.13
 */
void
tp_group_mixin_class_set_remove_with_reason_func (GObjectClass *cls,
                                      TpGroupMixinRemMemberWithReasonFunc func)
{
  TpGroupMixinClass *mixin_cls = TP_GROUP_MIXIN_CLASS (cls);

  g_return_if_fail (mixin_cls->remove_member == NULL);
  g_return_if_fail (mixin_cls->priv->remove_with_reason == NULL);
  mixin_cls->priv->remove_with_reason = func;
}

/**
 * tp_group_mixin_class_init: (skip)
 * @obj_cls: The class of an object implementing the group interface using this
 *  mixin
 * @offset: The offset of the TpGroupMixinClass structure within the class
 *  structure
 * @add_func: A callback to be used to add contacts to this group
 * @rem_func: A callback to be used to remove contacts from this group.
 *  This must be %NULL if you will subsequently call
 *  tp_group_mixin_class_set_remove_with_reason_func().
 *
 * Configure the mixin for use with the given class.
 */
void
tp_group_mixin_class_init (GObjectClass *obj_cls,
                           glong offset,
                           TpGroupMixinAddMemberFunc add_func,
                           TpGroupMixinRemMemberFunc rem_func)
{
  TpGroupMixinClass *mixin_cls;

  g_assert (G_IS_OBJECT_CLASS (obj_cls));

  g_type_set_qdata (G_OBJECT_CLASS_TYPE (obj_cls),
                    TP_GROUP_MIXIN_CLASS_OFFSET_QUARK,
                    GINT_TO_POINTER (offset));

  mixin_cls = TP_GROUP_MIXIN_CLASS (obj_cls);

  mixin_cls->add_member = add_func;
  mixin_cls->remove_member = rem_func;

  mixin_cls->priv = g_slice_new0 (TpGroupMixinClassPrivate);
}

/**
 * tp_group_mixin_class_allow_self_removal: (skip)
 * @obj_cls: The class of an object implementing the group interface using this
 *  mixin
 *
 * Configure the mixin to allow attempts to remove the SelfHandle from this
 * Group, even if the group flags would otherwise disallow this. The
 * channel's #TpGroupMixinRemMemberFunc or
 * #TpGroupMixinRemMemberWithReasonFunc will be called as usual for such
 * attempts, and may make them fail with %TP_ERROR_PERMISSION_DENIED if
 * required.
 *
 * This function should be called from the GObject @class_init callback,
 * after calling tp_group_mixin_class_init().
 *
 * (Recent telepathy-spec changes make it valid to try to remove the
 * self-handle at all times, regardless of group flags. However, if this was
 * implemented automatically in TpGroupMixin, this would risk crashing
 * connection manager implementations that assume that TpGroupMixin will
 * enforce the group flags strictly. As a result, connection managers should
 * call this function to indicate to the TpGroupMixin that it may call their
 * removal callback with the self-handle regardless of flag settings.)
 *
 * Since: 0.7.27
 */
void
tp_group_mixin_class_allow_self_removal (GObjectClass *obj_cls)
{
  TpGroupMixinClass *mixin_cls = TP_GROUP_MIXIN_CLASS (obj_cls);

  mixin_cls->priv->allow_self_removal = TRUE;
}

/**
 * tp_group_mixin_init: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @offset: The offset of the TpGroupMixin structure within the instance
 *  structure
 * @handle_repo: The connection's handle repository for contacts
 * @self_handle: The handle of the local user in this group, if any
 *
 * Initialize the mixin.
 */
void
tp_group_mixin_init (GObject *obj,
                     glong offset,
                     TpHandleRepoIface *handle_repo,
                     TpHandle self_handle)
{
  TpGroupMixin *mixin;

  g_assert (G_IS_OBJECT (obj));

  g_type_set_qdata (G_OBJECT_TYPE (obj),
                    TP_GROUP_MIXIN_OFFSET_QUARK,
                    GINT_TO_POINTER (offset));

  mixin = TP_GROUP_MIXIN (obj);

  mixin->handle_repo = handle_repo;

  if (self_handle != 0)
    mixin->self_handle = self_handle;

  mixin->group_flags = TP_CHANNEL_GROUP_FLAG_MEMBERS_CHANGED_DETAILED;

  mixin->members = tp_handle_set_new (handle_repo);
  mixin->local_pending = tp_handle_set_new (handle_repo);
  mixin->remote_pending = tp_handle_set_new (handle_repo);

  mixin->priv = g_slice_new0 (TpGroupMixinPrivate);
  mixin->priv->handle_owners = g_hash_table_new (NULL, NULL);
  mixin->priv->local_pending_info = g_hash_table_new_full (NULL, NULL, NULL,
      (GDestroyNotify)local_pending_info_free);
  mixin->priv->actors = tp_handle_set_new (handle_repo);
  mixin->priv->externals = NULL;
}

static void
tp_group_mixin_add_external (GObject *obj, GObject *external)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);

  if (mixin->priv->externals == NULL)
    mixin->priv->externals = g_ptr_array_new ();
  g_ptr_array_add (mixin->priv->externals, external);
}

static void
tp_group_mixin_remove_external (GObject *obj, GObject *external)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);

  /* we can't have added it if we have no array to add it to... */
  g_return_if_fail (mixin->priv->externals != NULL);
  g_ptr_array_remove_fast (mixin->priv->externals, external);
}

/**
 * tp_group_mixin_finalize: (skip)
 * @obj: An object implementing the group interface using this mixin
 *
 * Unreference handles and free resources used by this mixin.
 */
void
tp_group_mixin_finalize (GObject *obj)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);

  tp_handle_set_destroy (mixin->priv->actors);

  g_hash_table_unref (mixin->priv->handle_owners);
  g_hash_table_unref (mixin->priv->local_pending_info);

  if (mixin->priv->externals)
    g_ptr_array_unref (mixin->priv->externals);

  g_slice_free (TpGroupMixinPrivate, mixin->priv);

  tp_handle_set_destroy (mixin->members);
  tp_handle_set_destroy (mixin->local_pending);
  tp_handle_set_destroy (mixin->remote_pending);
}

/**
 * tp_group_mixin_get_self_handle: (skip)
 * @obj: An object implementing the group mixin using this interface
 * @ret: Used to return the local user's handle in this group
 * @error: Unused
 *
 * Set the guint pointed to by ret to the local user's handle in this
 * group, or to 0 if the local user is not present in this group.
 *
 * Returns: %TRUE.
 */
gboolean
tp_group_mixin_get_self_handle (GObject *obj,
                                guint *ret,
                                GError **error)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);

  if (tp_handle_set_is_member (mixin->members, mixin->self_handle) ||
      tp_handle_set_is_member (mixin->local_pending, mixin->self_handle) ||
      tp_handle_set_is_member (mixin->remote_pending, mixin->self_handle))
    {
      *ret = mixin->self_handle;
    }
  else
    {
      *ret = 0;
    }

  return TRUE;
}


/**
 * tp_group_mixin_change_self_handle: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @new_self_handle: The new self-handle for this group
 *
 * Change the self-handle for this group to the given value.
 */
void
tp_group_mixin_change_self_handle (GObject *obj,
                                   TpHandle new_self_handle)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);
  const gchar *new_self_id = tp_handle_inspect (mixin->handle_repo,
      new_self_handle);

  DEBUG ("%u '%s'", new_self_handle, new_self_id);

  mixin->self_handle = new_self_handle;

  tp_svc_channel_interface_group_emit_self_handle_changed (obj,
      new_self_handle);
  tp_svc_channel_interface_group_emit_self_contact_changed (obj,
      new_self_handle, new_self_id);
}


static void
tp_group_mixin_get_self_handle_async (TpSvcChannelInterfaceGroup *obj,
                                      DBusGMethodInvocation *context)
{
  guint ret;
  GError *error = NULL;

  if (tp_group_mixin_get_self_handle ((GObject *) obj, &ret, &error))
    {
      tp_svc_channel_interface_group_return_from_get_self_handle (
          context, ret);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

/**
 * tp_group_mixin_get_group_flags: (skip)
 * @obj: An object implementing the group mixin using this interface
 * @ret: Used to return the flags
 * @error: Unused
 *
 * Set the guint pointed to by ret to this group's flags, to be
 * interpreted according to TpChannelGroupFlags.
 *
 * Returns: %TRUE
 */
gboolean
tp_group_mixin_get_group_flags (GObject *obj,
                                guint *ret,
                                GError **error)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);

  *ret = mixin->group_flags;

  return TRUE;
}

static void
tp_group_mixin_get_group_flags_async (TpSvcChannelInterfaceGroup *obj,
                                      DBusGMethodInvocation *context)
{
  guint ret;
  GError *error = NULL;

  if (tp_group_mixin_get_group_flags ((GObject *) obj, &ret, &error))
    {
      tp_svc_channel_interface_group_return_from_get_group_flags (
          context, ret);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

/**
 * tp_group_mixin_add_members: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @contacts: A GArray of guint representing contacts
 * @message: A message associated with the addition request, if supported
 * @error: Used to return an error if %FALSE is returned
 *
 * Request that the given contacts be added to the group as if in response
 * to user action. If the group's flags prohibit this, raise
 * PermissionDenied. If any of the handles is invalid, raise InvalidHandle.
 * Otherwise attempt to add the contacts by calling the callbacks provided
 * by the channel implementation.
 *
 * Returns: %TRUE on success
 */
gboolean
tp_group_mixin_add_members (GObject *obj,
                            const GArray *contacts,
                            const gchar *message,
                            GError **error)
{
  TpGroupMixinClass *mixin_cls = TP_GROUP_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);
  guint i;
  TpHandle handle;

  /* reject invalid handles */
  if (!tp_handles_are_valid (mixin->handle_repo, contacts, FALSE, error))
    return FALSE;

  /* check that adding is allowed by flags */
  for (i = 0; i < contacts->len; i++)
    {
      handle = g_array_index (contacts, TpHandle, i);

      if ((mixin->group_flags & TP_CHANNEL_GROUP_FLAG_CAN_ADD) == 0 &&
          !tp_handle_set_is_member (mixin->members, handle) &&
          !tp_handle_set_is_member (mixin->local_pending, handle))
        {
          DEBUG ("handle %u cannot be added to members without "
              "GROUP_FLAG_CAN_ADD", handle);

          g_set_error (error, TP_ERROR, TP_ERROR_PERMISSION_DENIED,
              "handle %u cannot be added to members without "
              "GROUP_FLAG_CAN_ADD", handle);

          return FALSE;
        }
    }

  /* add handle by handle */
  for (i = 0; i < contacts->len; i++)
    {
      handle = g_array_index (contacts, TpHandle, i);

      if (tp_handle_set_is_member (mixin->members, handle))
        {
          DEBUG ("handle %u is already a member, skipping", handle);

          continue;
        }

      if (mixin_cls->add_member == NULL)
        {
          g_set_error (error, TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
              "Adding members to this Group channel is not possible");
          return FALSE;
        }
      if (!mixin_cls->add_member (obj, handle, message, error))
        {
          return FALSE;
        }
    }

  return TRUE;
}

static void
tp_group_mixin_add_members_async (TpSvcChannelInterfaceGroup *obj,
                                  const GArray *contacts,
                                  const gchar *message,
                                  DBusGMethodInvocation *context)
{
  GError *error = NULL;

  if (tp_group_mixin_add_members ((GObject *) obj, contacts, message, &error))
    {
      tp_svc_channel_interface_group_return_from_add_members (context);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

/**
 * tp_group_mixin_remove_members: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @contacts: A GArray of guint representing contacts
 * @message: A message to be sent to those contacts, if supported
 * @error: Used to return an error if %FALSE is returned
 *
 * Request that the given contacts be removed from the group as if in response
 * to user action. If the group's flags prohibit this, raise
 * PermissionDenied. If any of the handles is invalid, raise InvalidHandle.
 * If any of the handles is absent from the group, raise NotAvailable.
 * Otherwise attempt to remove the contacts by calling the callbacks provided
 * by the channel implementation.
 *
 * Returns: %TRUE on success
 */
gboolean
tp_group_mixin_remove_members (GObject *obj,
                               const GArray *contacts,
                               const gchar *message,
                               GError **error)
{
  return tp_group_mixin_remove_members_with_reason (obj, contacts, message,
      TP_CHANNEL_GROUP_CHANGE_REASON_NONE, error);
}

/**
 * tp_group_mixin_remove_members_with_reason: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @contacts: A GArray of guint representing contacts
 * @message: A message to be sent to those contacts, if supported
 * @reason: A #TpChannelGroupChangeReason
 * @error: Used to return an error if %FALSE is returned
 *
 * Request that the given contacts be removed from the group as if in response
 * to user action. If the group's flags prohibit this, raise
 * PermissionDenied. If any of the handles is invalid, raise InvalidHandle.
 * If any of the handles is absent from the group, raise NotAvailable.
 * Otherwise attempt to remove the contacts by calling the callbacks provided
 * by the channel implementation.
 *
 * Returns: %TRUE on success
 */
gboolean
tp_group_mixin_remove_members_with_reason (GObject *obj,
                               const GArray *contacts,
                               const gchar *message,
                               guint reason,
                               GError **error)
{
  TpGroupMixinClass *mixin_cls = TP_GROUP_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);
  guint i;
  TpHandle handle;

  /* reject invalid handles */
  if (!tp_handles_are_valid (mixin->handle_repo, contacts, FALSE, error))
    return FALSE;

  /* check removing is allowed by flags */
  for (i = 0; i < contacts->len; i++)
    {
      handle = g_array_index (contacts, TpHandle, i);

      if (mixin_cls->priv->allow_self_removal &&
          handle == mixin->self_handle &&
          (tp_handle_set_is_member (mixin->members, handle) ||
           tp_handle_set_is_member (mixin->remote_pending, handle) ||
           tp_handle_set_is_member (mixin->local_pending, handle)))
        {
          /* don't check the flags - attempting to remove the self-handle
           * is explicitly always allowed by this channel */
        }
      else if (tp_handle_set_is_member (mixin->members, handle))
        {
          if ((mixin->group_flags & TP_CHANNEL_GROUP_FLAG_CAN_REMOVE) == 0)
            {
              DEBUG ("handle %u cannot be removed from members without "
                  "GROUP_FLAG_CAN_REMOVE", handle);

              g_set_error (error, TP_ERROR, TP_ERROR_PERMISSION_DENIED,
                  "handle %u cannot be removed from members without "
                  "GROUP_FLAG_CAN_REMOVE", handle);

              return FALSE;
            }
        }
      else if (tp_handle_set_is_member (mixin->remote_pending, handle))
        {
          if ((mixin->group_flags & TP_CHANNEL_GROUP_FLAG_CAN_RESCIND) == 0)
            {
              DEBUG ("handle %u cannot be removed from remote pending "
                  "without GROUP_FLAG_CAN_RESCIND", handle);

              g_set_error (error, TP_ERROR, TP_ERROR_PERMISSION_DENIED,
                  "handle %u cannot be removed from remote pending without "
                  "GROUP_FLAG_CAN_RESCIND", handle);

              return FALSE;
            }
        }
      else if (!tp_handle_set_is_member (mixin->local_pending, handle))
        {
          DEBUG ("handle %u is not a current or pending member",
                   handle);
          /* we'll skip this handle during the second pass */
        }
    }

  /* remove handle by handle */
  for (i = 0; i < contacts->len; i++)
    {
      handle = g_array_index (contacts, TpHandle, i);

      if (!tp_handle_set_is_member (mixin->members, handle) &&
          !tp_handle_set_is_member (mixin->remote_pending, handle) &&
          !tp_handle_set_is_member (mixin->local_pending, handle))
        continue;

      if (mixin_cls->priv->remove_with_reason != NULL)
        {
          if (!mixin_cls->priv->remove_with_reason (obj, handle, message,
                                                    reason, error))
            {
              return FALSE;
            }
        }
      else if (mixin_cls->remove_member != NULL)
        {
          if (!mixin_cls->remove_member (obj, handle, message, error))
            {
              return FALSE;
            }
        }
      else
        {
          g_set_error (error, TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
              "Removing contacts from this Group channel is not possible");
          return FALSE;
        }
    }

  return TRUE;
}

static void
tp_group_mixin_remove_members_with_reason_async
    (TpSvcChannelInterfaceGroup *obj,
     const GArray *contacts,
     const gchar *message,
     guint reason,
     DBusGMethodInvocation *context)
{
  GError *error = NULL;

  if (tp_group_mixin_remove_members_with_reason ((GObject *) obj, contacts,
        message, reason, &error))
    {
      tp_svc_channel_interface_group_return_from_remove_members_with_reason
        (context);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

static void
tp_group_mixin_remove_members_async (TpSvcChannelInterfaceGroup *obj,
                                     const GArray *contacts,
                                     const gchar *message,
                                     DBusGMethodInvocation *context)
{
  GError *error = NULL;

  if (tp_group_mixin_remove_members_with_reason ((GObject *) obj, contacts,
        message, TP_CHANNEL_GROUP_CHANGE_REASON_NONE, &error))
    {
      tp_svc_channel_interface_group_return_from_remove_members (context);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

/**
 * tp_group_mixin_get_members: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @ret: Used to return a newly-allocated GArray of guint contact handles
 * @error: Unused
 *
 * Get the group's current members
 *
 * Returns: %TRUE
 */
gboolean
tp_group_mixin_get_members (GObject *obj,
                            GArray **ret,
                            GError **error)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);

  *ret = tp_handle_set_to_array (mixin->members);

  return TRUE;
}

static void
tp_group_mixin_get_members_async (TpSvcChannelInterfaceGroup *obj,
                                  DBusGMethodInvocation *context)
{
  GArray *ret;
  GError *error = NULL;

  if (tp_group_mixin_get_members ((GObject *) obj, &ret, &error))
    {
      tp_svc_channel_interface_group_return_from_get_members (
          context, ret);
      g_array_unref (ret);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

/**
 * tp_group_mixin_get_local_pending_members: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @ret: Used to return a newly-allocated GArray of guint contact handles
 * @error: Unused
 *
 * Get the group's local-pending members.
 *
 * Returns: %TRUE
 */
gboolean
tp_group_mixin_get_local_pending_members (GObject *obj,
                                          GArray **ret,
                                          GError **error)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);

  *ret = tp_handle_set_to_array (mixin->local_pending);

  return TRUE;
}

static void
tp_group_mixin_get_local_pending_members_async (TpSvcChannelInterfaceGroup *obj,
                                                DBusGMethodInvocation *context)
{
  GArray *ret;
  GError *error = NULL;

  if (tp_group_mixin_get_local_pending_members ((GObject *) obj, &ret, &error))
    {
      tp_svc_channel_interface_group_return_from_get_local_pending_members (
          context, ret);
      g_array_unref (ret);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

typedef struct {
    TpGroupMixin *mixin;
    GPtrArray *array;
} _mixin_and_array_of_info;

static void
local_pending_members_with_info_foreach (TpHandleSet *set,
                                         TpHandle i,
                                         gpointer userdata)
{
  _mixin_and_array_of_info *data = userdata;
  TpGroupMixinPrivate *priv = data->mixin->priv;
  GType info_type = TP_STRUCT_TYPE_LOCAL_PENDING_INFO;
  GValue entry = { 0, };
  LocalPendingInfo *info = g_hash_table_lookup (priv->local_pending_info,
                                                GUINT_TO_POINTER(i));
  g_assert (info != NULL);

  g_value_init (&entry, info_type);
  g_value_take_boxed (&entry, dbus_g_type_specialized_construct (info_type));

  dbus_g_type_struct_set (&entry,
      0, i,
      1, info->actor,
      2, info->reason,
      3, info->message,
      G_MAXUINT);

  g_ptr_array_add (data->array, g_value_get_boxed (&entry));
}

/**
 * tp_group_mixin_get_local_pending_members_with_info: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @ret: Used to return a newly-allocated GPtrArray of D-Bus structures each
 * containing the handle of a local-pending contact, the handle of a contact
 *  responsible for adding them to the group (or 0), the reason code
 *  and a related message (e.g. their request to join the group)
 * @error: Unused
 *
 * Get the group's local-pending members and information about their
 * requests to join the channel.
 *
 * Returns: %TRUE
 */
gboolean
tp_group_mixin_get_local_pending_members_with_info (
                                               GObject *obj,
                                               GPtrArray **ret,
                                               GError **error)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);
  _mixin_and_array_of_info data = { mixin, NULL };

  *ret = g_ptr_array_new ();
  data.array = *ret;

  tp_handle_set_foreach (mixin->local_pending,
      local_pending_members_with_info_foreach, &data);

  return TRUE;
}

static void
tp_group_mixin_get_local_pending_members_with_info_async (
                                                TpSvcChannelInterfaceGroup *obj,
                                                DBusGMethodInvocation *context)
{
  GPtrArray *ret;
  GError *error = NULL;

  if (tp_group_mixin_get_local_pending_members_with_info ((GObject *) obj,
        &ret, &error))
    {
      guint i;
      tp_svc_channel_interface_group_return_from_get_local_pending_members_with_info (
          context, ret);
      for (i = 0 ; i < ret->len; i++) {
        tp_value_array_free (g_ptr_array_index (ret,i));
      }
      g_ptr_array_unref (ret);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

/**
 * tp_group_mixin_get_remote_pending_members: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @ret: Used to return a newly-allocated GArray of guint representing the
 * handles of the group's remote pending members
 * @error: Unused
 *
 * Get the group's remote-pending members.
 *
 * Returns: %TRUE
 */
gboolean
tp_group_mixin_get_remote_pending_members (GObject *obj,
                                           GArray **ret,
                                           GError **error)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);

  *ret = tp_handle_set_to_array (mixin->remote_pending);

  return TRUE;
}

static void
tp_group_mixin_get_remote_pending_members_async (TpSvcChannelInterfaceGroup *obj,
                                                 DBusGMethodInvocation *context)
{
  GArray *ret;
  GError *error = NULL;

  if (tp_group_mixin_get_remote_pending_members ((GObject *) obj,
        &ret, &error))
    {
      tp_svc_channel_interface_group_return_from_get_remote_pending_members (
          context, ret);
      g_array_unref (ret);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

/**
 * tp_group_mixin_get_all_members: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @members: Used to return a newly-allocated GArray of guint representing
 * the handles of the group's members
 * @local_pending: Used to return a newly-allocated GArray of guint
 * representing the handles of the group's local pending members
 * @remote_pending: Used to return a newly-allocated GArray of guint
 * representing the handles of the group's remote pending members
 * @error: Unused
 *
 * Get the group's current and pending members.
 *
 * Returns: %TRUE
 */
gboolean
tp_group_mixin_get_all_members (GObject *obj,
                                GArray **members,
                                GArray **local_pending,
                                GArray **remote_pending,
                                GError **error)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);

  *members = tp_handle_set_to_array (mixin->members);
  *local_pending = tp_handle_set_to_array (mixin->local_pending);
  *remote_pending = tp_handle_set_to_array (mixin->remote_pending);

  return TRUE;
}

static void
tp_group_mixin_get_all_members_async (TpSvcChannelInterfaceGroup *obj,
                                      DBusGMethodInvocation *context)
{
  GArray *mem, *local, *remote;
  GError *error = NULL;

  if (tp_group_mixin_get_all_members ((GObject *) obj, &mem, &local, &remote,
        &error))
    {
      tp_svc_channel_interface_group_return_from_get_all_members (
          context, mem, local, remote);
      g_array_unref (mem);
      g_array_unref (local);
      g_array_unref (remote);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

/**
 * tp_group_mixin_get_handle_owners: (skip)
 * @obj: An object implementing the group interface with this mixin
 * @handles: An array of guint representing locally valid handles
 * @ret: Used to return an array of guint representing globally valid
 *  handles, or 0 where unavailable, if %TRUE is returned
 * @error: Used to return an error if %FALSE is returned
 *
 * If the mixin has the flag %TP_CHANNEL_GROUP_FLAG_CHANNEL_SPECIFIC_HANDLES,
 * return the global owners of the given local handles, or 0 where
 * unavailable.
 *
 * Returns: %TRUE (setting @ret) on success, %FALSE (setting @error) on
 * failure
 */
gboolean
tp_group_mixin_get_handle_owners (GObject *obj,
                                  const GArray *handles,
                                  GArray **ret,
                                  GError **error)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);
  TpGroupMixinPrivate *priv = mixin->priv;
  guint i;

  if ((mixin->group_flags &
        TP_CHANNEL_GROUP_FLAG_CHANNEL_SPECIFIC_HANDLES) == 0)
    {
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "channel doesn't have channel specific handles");

      return FALSE;
    }

  if (!tp_handles_are_valid (mixin->handle_repo, handles, FALSE, error))
    {
      return FALSE;
    }

  *ret = g_array_sized_new (FALSE, FALSE, sizeof (TpHandle), handles->len);

  for (i = 0; i < handles->len; i++)
    {
      TpHandle local_handle = g_array_index (handles, TpHandle, i);
      TpHandle owner_handle;

      if (!tp_handle_set_is_member (mixin->members, local_handle))
        {
          g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
              "handle %u is not a member", local_handle);

          g_array_unref (*ret);
          *ret = NULL;

          return FALSE;
        }

      owner_handle = GPOINTER_TO_UINT (
          g_hash_table_lookup (priv->handle_owners,
                               GUINT_TO_POINTER (local_handle)));

      g_array_append_val (*ret, owner_handle);
    }

  return TRUE;
}

static void
tp_group_mixin_get_handle_owners_async (TpSvcChannelInterfaceGroup *obj,
                                        const GArray *handles,
                                        DBusGMethodInvocation *context)
{
  GArray *ret;
  GError *error = NULL;

  if (tp_group_mixin_get_handle_owners ((GObject *) obj, handles,
        &ret, &error))
    {
      tp_svc_channel_interface_group_return_from_get_handle_owners (
          context, ret);
      g_array_unref (ret);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}

#define GFTS_APPEND_FLAG_IF_SET(flag) \
  if (flags & flag) \
    { \
      if (i++ > 0) \
        g_string_append (str, "|"); \
      g_string_append (str, #flag + 22); \
      flags &= ~flag; \
    }

static gchar *
group_flags_to_string (TpChannelGroupFlags flags)
{
  gint i = 0;
  GString *str;

  str = g_string_new ("[");

  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_CAN_ADD);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_CAN_REMOVE);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_CAN_RESCIND);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_MESSAGE_ADD);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_MESSAGE_REMOVE);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_MESSAGE_ACCEPT);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_MESSAGE_REJECT);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_MESSAGE_RESCIND);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_CHANNEL_SPECIFIC_HANDLES);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_ONLY_ONE_GROUP);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_HANDLE_OWNERS_NOT_AVAILABLE);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_PROPERTIES);
  GFTS_APPEND_FLAG_IF_SET (TP_CHANNEL_GROUP_FLAG_MEMBERS_CHANGED_DETAILED);

  /* Print out any remaining flags that weren't removed in the above cases
   * numerically.
   */
  if (flags != 0)
    {
      if (i > 0)
        g_string_append (str, "|");

      g_string_append_printf (str, "%u", flags);
    }

  g_string_append (str, "]");

  return g_string_free (str, FALSE);
}

/**
 * tp_group_mixin_change_flags: (skip)
 * @obj: An object implementing the groups interface using this mixin
 * @add: Flags to be added
 * @del: Flags to be removed
 *
 * Request a change to be made to the flags. If any flags were actually
 * set or cleared, emits the GroupFlagsChanged signal with the changes.
 *
 * It is an error to set any of the same bits in both @add and @del.
 *
 * Changed in 0.7.7: the signal is not emitted if adding @add and
 *  removing @del had no effect on the existing group flags.
 */
void
tp_group_mixin_change_flags (GObject *obj,
                             TpChannelGroupFlags add,
                             TpChannelGroupFlags del)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);
  TpChannelGroupFlags added, removed;

  /* It's meaningless to want to add and remove the same capability */
  g_return_if_fail ((add & del) == 0);

  added = add & ~mixin->group_flags;
  mixin->group_flags |= added;

  removed = del & mixin->group_flags;
  mixin->group_flags &= ~removed;

  if (added == 0 && removed == 0)
    {
      DEBUG ("No change: %u includes all the bits of %u and none of %u",
          mixin->group_flags, add, del);
    }
  else
    {
      gchar *str_added, *str_removed, *str_flags;

      if (DEBUGGING)
        {
          str_added = group_flags_to_string (added);
          str_removed = group_flags_to_string (removed);
          str_flags = group_flags_to_string (mixin->group_flags);

          DEBUG ("emitting group flags changed\n"
                  "  added    : %s\n"
                  "  removed  : %s\n"
                  "  flags now: %s\n",
                  str_added, str_removed, str_flags);

          g_free (str_added);
          g_free (str_removed);
          g_free (str_flags);
        }

      tp_svc_channel_interface_group_emit_group_flags_changed (obj, added,
          removed);
      if (mixin->priv->externals != NULL)
        {
          guint i;

          for (i = 0; i < mixin->priv->externals->len; i++)
            {
              tp_svc_channel_interface_group_emit_group_flags_changed
                ((GObject *) g_ptr_array_index (mixin->priv->externals, i),
                 added, removed);
            }
        }
    }
}

static gchar *
member_array_to_string (TpHandleRepoIface *repo,
                        const GArray *array)
{
  GString *str;
  guint i;

  str = g_string_new ("[");

  for (i = 0; i < array->len; i++)
    {
      TpHandle handle;
      const gchar *handle_str;

      handle = g_array_index (array, guint, i);
      handle_str = tp_handle_inspect (repo, handle);

      g_string_append_printf (str, "%s%u (%s)",
      /* indent to:   "  remote_pending: [" */
          (i > 0) ? "\n                   "
                  : "",
          handle, handle_str);
    }

  g_string_append (str, "]");

  return g_string_free (str, FALSE);
}

static GArray *remove_handle_owners_if_exist (GObject *obj,
    GArray *array) G_GNUC_WARN_UNUSED_RESULT;

typedef struct {
    TpGroupMixin *mixin;
    LocalPendingInfo *info;
} _mixin_and_info;

static void
local_pending_added_foreach (guint i,
                             gpointer userdata)
{
  _mixin_and_info *data = userdata;
  TpGroupMixinPrivate *priv = data->mixin->priv;

  g_hash_table_insert (priv->local_pending_info,
      GUINT_TO_POINTER (i),
      local_pending_info_new (data->mixin->handle_repo,
      data->info->actor, data->info->reason, data->info->message));
}

static void
local_pending_added (TpGroupMixin *mixin,
    const TpIntset *added,
    TpHandle actor,
    guint reason,
    const gchar *message)
{
  LocalPendingInfo info;
  _mixin_and_info data = { mixin, &info };
  info.actor = actor;
  info.reason = reason;
  info.message = message;

  tp_intset_foreach (added, local_pending_added_foreach, &data);
}

static void
local_pending_remove_foreach (guint i,
                             gpointer userdata)
{
  TpGroupMixin *mixin = (TpGroupMixin *) userdata;
  TpGroupMixinPrivate *priv = mixin->priv;

  g_hash_table_remove (priv->local_pending_info, GUINT_TO_POINTER(i));
}

static void
local_pending_remove (TpGroupMixin *mixin,
                     TpIntset *removed)
{
  tp_intset_foreach (removed, local_pending_remove_foreach, mixin);
}


static void
add_members_in_array (GHashTable *contact_ids,
                      TpHandleRepoIface *repo,
                      const GArray *handles)
{
  guint i;

  for (i = 0; i < handles->len; i++)
    {
      TpHandle handle = g_array_index (handles, TpHandle, i);
      const gchar *id = tp_handle_inspect (repo, handle);

      g_hash_table_insert (contact_ids, GUINT_TO_POINTER (handle), (gchar *) id);
    }
}


static gboolean
maybe_add_contact_ids (TpGroupMixin *mixin,
                      const GArray *add,
                      const GArray *local_pending,
                      const GArray *remote_pending,
                      TpHandle actor,
                      GHashTable *details)
{
  GHashTable *contact_ids;

  /* If the library user had its own ideas about which members' IDs to include
   * in the change details, we'll leave that intact.
   */
  if (tp_asv_lookup (details, "contact-ids") != NULL)
    return FALSE;

  /* The library user didn't include the new members' IDs in details; let's add
   * the IDs of the handles being added to the group (but not removed, as per
   * the spec) and of the actor.
   */
  contact_ids = g_hash_table_new (NULL, NULL);

  add_members_in_array (contact_ids, mixin->handle_repo, add);
  add_members_in_array (contact_ids, mixin->handle_repo, local_pending);
  add_members_in_array (contact_ids, mixin->handle_repo, remote_pending);

  if (actor != 0)
    {
      const gchar *id = tp_handle_inspect (mixin->handle_repo, actor);

      g_hash_table_insert (contact_ids, GUINT_TO_POINTER (actor), (gchar *) id);
    }

  g_hash_table_insert (details, "contact-ids",
      tp_g_value_slice_new_take_boxed (TP_HASH_TYPE_HANDLE_IDENTIFIER_MAP,
          contact_ids));

  return TRUE;
}


static void
remove_contact_ids (GHashTable *details)
{
  GValue *contact_ids_v = g_hash_table_lookup (details, "contact-ids");

  g_assert (contact_ids_v != NULL);
  g_hash_table_steal (details, "contact-ids");

  tp_g_value_slice_free (contact_ids_v);
}


static void
emit_members_changed_signals (GObject *channel,
                              const gchar *message,
                              const GArray *add,
                              const GArray *del,
                              const GArray *local_pending,
                              const GArray *remote_pending,
                              TpHandle actor,
                              TpChannelGroupChangeReason reason,
                              const GHashTable *details)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (channel);
  GHashTable *details_ = (GHashTable *) details; /* Cast the pain away! */
  gboolean added_contact_ids;

  if (DEBUGGING)
    {
      gchar *add_str, *rem_str, *local_str, *remote_str;

      add_str = member_array_to_string (mixin->handle_repo, add);
      rem_str = member_array_to_string (mixin->handle_repo, del);
      local_str = member_array_to_string (mixin->handle_repo, local_pending);
      remote_str = member_array_to_string (mixin->handle_repo, remote_pending);

      DEBUG ("emitting members changed\n"
              "  message       : \"%s\"\n"
              "  added         : %s\n"
              "  removed       : %s\n"
              "  local_pending : %s\n"
              "  remote_pending: %s\n"
              "  actor         : %u\n"
              "  reason        : %u: %s\n",
              message, add_str, rem_str, local_str, remote_str,
              actor, reason, group_change_reason_str (reason));

      g_free (add_str);
      g_free (rem_str);
      g_free (local_str);
      g_free (remote_str);
    }

  added_contact_ids = maybe_add_contact_ids (mixin, add, local_pending,
      remote_pending, actor, details_);

  tp_svc_channel_interface_group_emit_members_changed (channel, message,
      add, del, local_pending, remote_pending, actor, reason);
  tp_svc_channel_interface_group_emit_members_changed_detailed (channel,
      add, del, local_pending, remote_pending, details_);

  if (mixin->priv->externals != NULL)
    {
      guint i;

      for (i = 0; i < mixin->priv->externals->len; i++)
        {
          GObject *external = g_ptr_array_index (mixin->priv->externals, i);

          tp_svc_channel_interface_group_emit_members_changed (external,
              message, add, del, local_pending, remote_pending, actor, reason);
          tp_svc_channel_interface_group_emit_members_changed_detailed (
              external, add, del, local_pending, remote_pending, details_);
        }
    }

  if (added_contact_ids)
    remove_contact_ids (details_);
}


static gboolean
change_members (GObject *obj,
                const gchar *message,
                const TpIntset *add,
                const TpIntset *del,
                const TpIntset *add_local_pending,
                const TpIntset *add_remote_pending,
                TpHandle actor,
                TpChannelGroupChangeReason reason,
                const GHashTable *details)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);
  TpIntset *new_add, *new_remove, *new_local_pending,
           *new_remote_pending, *tmp, *tmp2, *empty;
  gboolean ret;

  empty = tp_intset_new ();

  if (message == NULL)
    message = "";

  if (add == NULL)
    add = empty;

  if (del == NULL)
    del = empty;

  if (add_local_pending == NULL)
    add_local_pending = empty;

  if (add_remote_pending == NULL)
    add_remote_pending = empty;

  /* remember the actor handle before any handle unreffing happens */
  if (actor)
    {
      tp_handle_set_add (mixin->priv->actors, actor);
    }

  /* members + add */
  new_add = tp_handle_set_update (mixin->members, add);

  /* members - del */
  new_remove = tp_handle_set_difference_update (mixin->members, del);

  /* members - add_local_pending */
  tmp = tp_handle_set_difference_update (mixin->members, add_local_pending);
  tp_intset_destroy (tmp);

  /* members - add_remote_pending */
  tmp = tp_handle_set_difference_update (mixin->members, add_remote_pending);
  tp_intset_destroy (tmp);


  /* local pending + add_local_pending */
  new_local_pending = tp_handle_set_update (mixin->local_pending,
      add_local_pending);
  local_pending_added (mixin, add_local_pending, actor, reason, message);

  /* local pending - add */
  tmp = tp_handle_set_difference_update (mixin->local_pending, add);
  local_pending_remove (mixin, tmp);
  tp_intset_destroy (tmp);

  /* local pending - del */
  tmp = tp_handle_set_difference_update (mixin->local_pending, del);
  local_pending_remove (mixin, tmp);

  tmp2 = tp_intset_union (new_remove, tmp);
  tp_intset_destroy (new_remove);
  tp_intset_destroy (tmp);
  new_remove = tmp2;

  /* local pending - add_remote_pending */
  tmp = tp_handle_set_difference_update (mixin->local_pending,
      add_remote_pending);
  local_pending_remove (mixin, tmp);
  tp_intset_destroy (tmp);


  /* remote pending + add_remote_pending */
  new_remote_pending = tp_handle_set_update (mixin->remote_pending,
      add_remote_pending);

  /* remote pending - add */
  tmp = tp_handle_set_difference_update (mixin->remote_pending, add);
  tp_intset_destroy (tmp);

  /* remote pending - del */
  tmp = tp_handle_set_difference_update (mixin->remote_pending, del);
  tmp2 = tp_intset_union (new_remove, tmp);
  tp_intset_destroy (new_remove);
  tp_intset_destroy (tmp);
  new_remove = tmp2;

  /* remote pending - local_pending */
  tmp = tp_handle_set_difference_update (mixin->remote_pending,
      add_local_pending);
  tp_intset_destroy (tmp);

  if (tp_intset_size (new_add) > 0 ||
      tp_intset_size (new_remove) > 0 ||
      tp_intset_size (new_local_pending) > 0 ||
      tp_intset_size (new_remote_pending) > 0)
    {
      GArray *arr_add, *arr_remove, *arr_local, *arr_remote;
      GArray *arr_owners_removed;

      /* translate intsets to arrays */
      arr_add = tp_intset_to_array (new_add);
      arr_remove = tp_intset_to_array (new_remove);
      arr_local = tp_intset_to_array (new_local_pending);
      arr_remote = tp_intset_to_array (new_remote_pending);

      /* remove any handle owner mappings */
      arr_owners_removed = remove_handle_owners_if_exist (obj, arr_remove);

      /* emit signals */
      emit_members_changed_signals (obj, message, arr_add, arr_remove,
          arr_local, arr_remote, actor, reason, details);

      if (arr_owners_removed->len > 0)
        {
          GHashTable *empty_hash_table = g_hash_table_new (NULL, NULL);

          tp_svc_channel_interface_group_emit_handle_owners_changed (obj,
              empty_hash_table, arr_owners_removed);
          tp_svc_channel_interface_group_emit_handle_owners_changed_detailed (
              obj, empty_hash_table, arr_owners_removed, empty_hash_table);

          if (mixin->priv->externals != NULL)
            {
              guint i;

              for (i = 0; i < mixin->priv->externals->len; i++)
                {
                  tp_svc_channel_interface_group_emit_handle_owners_changed (
                      g_ptr_array_index (mixin->priv->externals, i),
                      empty_hash_table, arr_owners_removed);
                  tp_svc_channel_interface_group_emit_handle_owners_changed_detailed (
                      g_ptr_array_index (mixin->priv->externals, i),
                      empty_hash_table, arr_owners_removed, empty_hash_table);
                }
            }

          g_hash_table_unref (empty_hash_table);
        }

      /* free arrays */
      g_array_unref (arr_add);
      g_array_unref (arr_remove);
      g_array_unref (arr_local);
      g_array_unref (arr_remote);
      g_array_unref (arr_owners_removed);

      ret = TRUE;
    }
  else
    {
      DEBUG ("not emitting signal, nothing changed");

      ret = FALSE;
    }

  /* free intsets */
  tp_intset_destroy (new_add);
  tp_intset_destroy (new_remove);
  tp_intset_destroy (new_local_pending);
  tp_intset_destroy (new_remote_pending);
  tp_intset_destroy (empty);

  return ret;
}


/**
 * tp_group_mixin_change_members: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @message: A message to be sent to the affected contacts if possible;
 *  %NULL is allowed, and is mapped to an empty string
 * @add: A set of contact handles to be added to the members (if not
 *  already present) and removed from local pending and remote pending
 *  (if present)
 * @del: A set of contact handles to be removed from members,
 *  local pending or remote pending, wherever they are present
 * @add_local_pending: A set of contact handles to be added to local pending,
 *  and removed from members and remote pending
 * @add_remote_pending: A set of contact handles to be added to remote pending,
 *  and removed from members and local pending
 * @actor: The handle of the contact responsible for this change
 * @reason: The reason for this change
 *
 * Change the sets of members as given by the arguments, and emit the
 * MembersChanged and MembersChangedDetailed signals if the changes were not a
 * no-op.
 *
 * This function must be called in response to events on the underlying
 * IM protocol, and must not be called in direct response to user input;
 * it does not respect the permissions flags, but changes the group directly.
 *
 * If any two of add, del, add_local_pending and add_remote_pending have
 * a non-empty intersection, the result is undefined. Don't do that.
 *
 * Each of the TpIntset arguments may be %NULL, which is treated as
 * equivalent to an empty set.
 *
 * Returns: %TRUE if the group was changed and the MembersChanged(Detailed)
 *  signals were emitted; %FALSE if nothing actually changed and the signals
 *  were suppressed.
 */
gboolean
tp_group_mixin_change_members (GObject *obj,
                               const gchar *message,
                               const TpIntset *add,
                               const TpIntset *del,
                               const TpIntset *add_local_pending,
                               const TpIntset *add_remote_pending,
                               TpHandle actor,
                               TpChannelGroupChangeReason reason)
{
  GHashTable *details = g_hash_table_new_full (g_str_hash, g_str_equal,
      NULL, (GDestroyNotify) tp_g_value_slice_free);
  gboolean ret;

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

  if (message != NULL && message[0] != '\0')
    {
      g_hash_table_insert (details, "message",
          tp_g_value_slice_new_string (message));
    }

  ret = change_members (obj, message, add, del, add_local_pending,
      add_remote_pending, actor, reason, details);

  g_hash_table_unref (details);
  return ret;
}

/**
 * tp_group_mixin_change_members_detailed: (skip)
 * @obj: An object implementing the group interface using this mixin
 * @add: A set of contact handles to be added to the members (if not
 *  already present) and removed from local pending and remote pending
 *  (if present)
 * @del: A set of contact handles to be removed from members,
 *  local pending or remote pending, wherever they are present
 * @add_local_pending: A set of contact handles to be added to local pending,
 *  and removed from members and remote pending
 * @add_remote_pending: A set of contact handles to be added to remote pending,
 *  and removed from members and local pending
 * @details: a map from strings to GValues detailing the change
 *
 * Change the sets of members as given by the arguments, and emit the
 * MembersChanged and MembersChangedDetailed signals if the changes were not a
 * no-op.
 *
 * This function must be called in response to events on the underlying
 * IM protocol, and must not be called in direct response to user input;
 * it does not respect the permissions flags, but changes the group directly.
 *
 * If any two of add, del, add_local_pending and add_remote_pending have
 * a non-empty intersection, the result is undefined. Don't do that.
 *
 * Each of the TpIntset arguments may be %NULL, which is treated as
 * equivalent to an empty set.
 *
 * details may contain, among other entries, the well-known
 * keys (and corresponding type, wrapped in a GValue) defined by the
 * Group.MembersChangedDetailed signal's specification; these include "actor"
 * (a handle as G_TYPE_UINT), "change-reason" (an element of
 * #TpChannelGroupChangeReason as G_TYPE_UINT), "message" (G_TYPE_STRING),
 * "error" (G_TYPE_STRING), "debug-message" (G_TYPE_STRING).
 *
 * If all of the information in details could be passed to
 * tp_group_mixin_change_members() then calling this function instead provides
 * no benefit. Calling this function without setting
 * #TP_CHANNEL_GROUP_FLAG_MEMBERS_CHANGED_DETAILED with
 * tp_group_mixin_change_members() first is not very useful, as clients will
 * not know to listen for MembersChangedDetailed and thus will miss the
 * details.
 *
 * Returns: %TRUE if the group was changed and the MembersChanged(Detailed)
 *  signals were emitted; %FALSE if nothing actually changed and the signals
 *  were suppressed.
 *
 * Since: 0.7.21
 */
gboolean
tp_group_mixin_change_members_detailed (GObject *obj,
                                        const TpIntset *add,
                                        const TpIntset *del,
                                        const TpIntset *add_local_pending,
                                        const TpIntset *add_remote_pending,
                                        const GHashTable *details)
{
  const gchar *message;
  TpHandle actor;
  TpChannelGroupChangeReason reason;
  gboolean valid;

  g_return_val_if_fail (details != NULL, FALSE);

  /* For each detail we're extracting for the benefit of old-school
   * MembersChanged, warn if it's present but badly typed.
   */

  message = tp_asv_get_string (details, "message");
  g_warn_if_fail (message != NULL || tp_asv_lookup (details, "message") == NULL);

  /* change_members will cry (via tp_handle_set_add) if actor is non-zero and
   * invalid.
   */
  actor = tp_asv_get_uint32 (details, "actor", &valid);
  g_warn_if_fail (valid || tp_asv_lookup (details, "actor") == NULL);

  reason = tp_asv_get_uint32 (details, "change-reason", &valid);
  g_warn_if_fail (valid || tp_asv_lookup (details, "change-reason") == NULL);

  return change_members (obj, message, add, del, add_local_pending,
      add_remote_pending, actor, reason, details);
}

/**
 * tp_group_mixin_add_handle_owner: (skip)
 * @obj: A GObject implementing the group interface with this mixin
 * @local_handle: A contact handle valid within this group (may not be 0)
 * @owner_handle: A contact handle valid globally, or 0 if the owner of the
 *  @local_handle is unknown
 *
 * Note that the given local handle is an alias within this group
 * for the given globally-valid handle. It will be returned from subsequent
 * GetHandleOwner queries where appropriate.
 *
 * Changed in 0.7.10: The @owner_handle may be 0. To comply with telepathy-spec
 *  0.17.6, before adding any channel-specific handle to the members,
 *  local-pending members or remote-pending members, you must call either
 *  this function or tp_group_mixin_add_handle_owners().
 */
void
tp_group_mixin_add_handle_owner (GObject *obj,
                                 TpHandle local_handle,
                                 TpHandle owner_handle)
{
  GHashTable *tmp;

  g_return_if_fail (local_handle != 0);

  tmp = g_hash_table_new (g_direct_hash, g_direct_equal);
  g_hash_table_insert (tmp, GUINT_TO_POINTER (local_handle),
      GUINT_TO_POINTER (owner_handle));

  tp_group_mixin_add_handle_owners (obj, tmp);

  g_hash_table_unref (tmp);
}


static void
add_us_mapping_for_handleset (GHashTable *map,
    TpHandleRepoIface *repo,
    TpHandleSet *handles)
{
  TpIntset *set;
  TpIntsetFastIter iter;
  TpHandle handle;

  set = tp_handle_set_peek (handles);
  tp_intset_fast_iter_init (&iter, set);
  while (tp_intset_fast_iter_next (&iter, &handle))
    g_hash_table_insert (map, GUINT_TO_POINTER (handle),
        (gchar *) tp_handle_inspect (repo, handle));
}

static void
add_us_mapping_for_owners_map (GHashTable *map,
    TpHandleRepoIface *repo,
    GHashTable *owners)
{
  GHashTableIter iter;
  gpointer key, value;

  g_hash_table_iter_init (&iter, owners);
  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      TpHandle local_handle = GPOINTER_TO_UINT (key);
      TpHandle owner_handle = GPOINTER_TO_UINT (value);

      g_hash_table_insert (map, key,
          (gchar *) tp_handle_inspect (repo, local_handle));

      if (owner_handle != 0)
        g_hash_table_insert (map, value,
            (gchar *) tp_handle_inspect (repo, owner_handle));
    }
}

static void
add_handle_owners_helper (gpointer key,
                          gpointer value,
                          gpointer user_data)
{
  TpHandle local_handle = GPOINTER_TO_UINT (key);
  TpGroupMixin *mixin = user_data;

  g_return_if_fail (local_handle != 0);

  g_hash_table_insert (mixin->priv->handle_owners, key, value);
}

/**
 * tp_group_mixin_add_handle_owners: (skip)
 * @obj: A GObject implementing the group interface with this mixin
 * @local_to_owner_handle: A map from contact handles valid within this group
 *  (which may not be 0) to either contact handles valid globally, or 0 if the
 *  owner of the corresponding key is unknown; all handles are stored using
 *  GUINT_TO_POINTER
 *
 * Note that the given local handles are aliases within this group
 * for the given globally-valid handles.
 *
 * To comply with telepathy-spec 0.17.6, before adding any channel-specific
 * handle to the members, local-pending members or remote-pending members, you
 * must call either this function or tp_group_mixin_add_handle_owner().
 *
 * Since: 0.7.10
 */
void
tp_group_mixin_add_handle_owners (GObject *obj,
                                  GHashTable *local_to_owner_handle)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);
  GArray *empty_array;
  GHashTable *ids = g_hash_table_new (NULL, NULL);

  if (g_hash_table_size (local_to_owner_handle) == 0)
    return;

  empty_array = g_array_sized_new (FALSE, FALSE, sizeof (guint), 0);

  g_hash_table_foreach (local_to_owner_handle, add_handle_owners_helper,
      mixin);

  tp_svc_channel_interface_group_emit_handle_owners_changed (obj,
      local_to_owner_handle, empty_array);

  add_us_mapping_for_owners_map (ids, mixin->handle_repo, local_to_owner_handle);
  tp_svc_channel_interface_group_emit_handle_owners_changed_detailed (obj,
      local_to_owner_handle, empty_array, ids);

  g_array_unref (empty_array);
  g_hash_table_unref (ids);
}


static GArray *
remove_handle_owners_if_exist (GObject *obj,
                               GArray *array)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);
  TpGroupMixinPrivate *priv = mixin->priv;
  guint i;
  GArray *ret;

  ret = g_array_sized_new (FALSE, FALSE, sizeof (guint), array->len);

  for (i = 0; i < array->len; i++)
    {
      TpHandle handle = g_array_index (array, guint, i);
      gpointer local_handle, owner_handle;

      g_assert (handle != 0);

      if (g_hash_table_lookup_extended (priv->handle_owners,
                                        GUINT_TO_POINTER (handle),
                                        &local_handle,
                                        &owner_handle))
        {
          g_assert (GPOINTER_TO_UINT (local_handle) == handle);
          g_array_append_val (ret, handle);
          g_hash_table_remove (priv->handle_owners, GUINT_TO_POINTER (handle));
        }
    }

  return ret;
}

static GHashTable *
dup_member_identifiers (GObject *obj)
{
  TpGroupMixin *mixin = TP_GROUP_MIXIN (obj);
  GHashTable *ret = g_hash_table_new (NULL, NULL);

  g_hash_table_insert (ret, GUINT_TO_POINTER (mixin->self_handle),
      (gchar *) tp_handle_inspect (mixin->handle_repo, mixin->self_handle));

  add_us_mapping_for_handleset (ret, mixin->handle_repo, mixin->priv->actors);
  add_us_mapping_for_handleset (ret, mixin->handle_repo, mixin->members);
  add_us_mapping_for_handleset (ret, mixin->handle_repo, mixin->local_pending);
  add_us_mapping_for_handleset (ret, mixin->handle_repo, mixin->remote_pending);

  add_us_mapping_for_owners_map (ret, mixin->handle_repo,
      mixin->priv->handle_owners);

  return ret;
}

/**
 * tp_group_mixin_iface_init: (skip)
 * @g_iface: A #TpSvcChannelInterfaceGroupClass
 * @iface_data: Unused
 *
 * Fill in the vtable entries needed to implement the group interface using
 * this mixin. This function should usually be called via
 * G_IMPLEMENT_INTERFACE.
 */
void
tp_group_mixin_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcChannelInterfaceGroupClass *klass = g_iface;

#define IMPLEMENT(x) tp_svc_channel_interface_group_implement_##x (klass,\
    tp_group_mixin_##x##_async)
  IMPLEMENT(add_members);
  IMPLEMENT(get_all_members);
  IMPLEMENT(get_group_flags);
  IMPLEMENT(get_handle_owners);
  IMPLEMENT(get_local_pending_members);
  IMPLEMENT(get_local_pending_members_with_info);
  IMPLEMENT(get_members);
  IMPLEMENT(get_remote_pending_members);
  IMPLEMENT(get_self_handle);
  IMPLEMENT(remove_members);
  IMPLEMENT(remove_members_with_reason);
#undef IMPLEMENT
}


enum {
    MIXIN_DP_GROUP_FLAGS,
    MIXIN_DP_HANDLE_OWNERS,
    MIXIN_DP_LOCAL_PENDING_MEMBERS,
    MIXIN_DP_MEMBERS,
    MIXIN_DP_REMOTE_PENDING_MEMBERS,
    MIXIN_DP_SELF_HANDLE,
    MIXIN_DP_MEMBER_IDENTIFIERS,
    NUM_MIXIN_DBUS_PROPERTIES
};


/**
 * tp_group_mixin_get_dbus_property: (skip)
 * @object: An object with this mixin
 * @interface: Must be %TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP
 * @name: A quark representing the D-Bus property name, either
 *  "GroupFlags", "HandleOwners", "LocalPendingMembers", "Members",
 *  "RemotePendingMembers" or "SelfHandle"
 * @value: A GValue pre-initialized to the right type, into which to put the
 *  value
 * @unused: Ignored
 *
 * An implementation of #TpDBusPropertiesMixinGetter which assumes that the
 * @object has the group mixin. It can only be used for the Group interface.
 *
 * Since: 0.7.10
 */
void
tp_group_mixin_get_dbus_property (GObject *object,
                                  GQuark interface,
                                  GQuark name,
                                  GValue *value,
                                  gpointer unused G_GNUC_UNUSED)
{
  TpGroupMixin *mixin;
  static GQuark q[NUM_MIXIN_DBUS_PROPERTIES] = { 0 };

  if (G_UNLIKELY (q[0] == 0))
    {
      q[MIXIN_DP_GROUP_FLAGS] = g_quark_from_static_string ("GroupFlags");
      q[MIXIN_DP_HANDLE_OWNERS] = g_quark_from_static_string ("HandleOwners");
      q[MIXIN_DP_LOCAL_PENDING_MEMBERS] = g_quark_from_static_string (
          "LocalPendingMembers");
      q[MIXIN_DP_MEMBERS] = g_quark_from_static_string ("Members");
      q[MIXIN_DP_REMOTE_PENDING_MEMBERS] = g_quark_from_static_string (
          "RemotePendingMembers");
      q[MIXIN_DP_SELF_HANDLE] = g_quark_from_static_string ("SelfHandle");
      q[MIXIN_DP_MEMBER_IDENTIFIERS] = g_quark_from_static_string ("MemberIdentifiers");
    }

  g_return_if_fail (object != NULL);
  mixin = TP_GROUP_MIXIN (object);
  g_return_if_fail (mixin != NULL);
  g_return_if_fail (interface == TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP);
  g_return_if_fail (name != 0);
  g_return_if_fail (value != NULL);

  if (name == q[MIXIN_DP_GROUP_FLAGS])
    {
      g_return_if_fail (G_VALUE_HOLDS_UINT (value));
      g_value_set_uint (value, mixin->group_flags);
    }
  else if (name == q[MIXIN_DP_HANDLE_OWNERS])
    {
      g_return_if_fail (G_VALUE_HOLDS (value, TP_HASH_TYPE_HANDLE_OWNER_MAP));
      g_value_set_boxed (value, mixin->priv->handle_owners);
    }
  else if (name == q[MIXIN_DP_LOCAL_PENDING_MEMBERS])
    {
      GPtrArray *ret = NULL;
      gboolean success;

      g_return_if_fail (G_VALUE_HOLDS_BOXED (value));
      success = tp_group_mixin_get_local_pending_members_with_info (object,
          &ret, NULL);
      g_assert (success);     /* as of 0.7.8, cannot fail */
      g_value_take_boxed (value, ret);
    }
  else if (name == q[MIXIN_DP_MEMBERS])
    {
      GArray *ret = NULL;
      gboolean success;

      g_return_if_fail (G_VALUE_HOLDS_BOXED (value));
      success = tp_group_mixin_get_members (object, &ret, NULL);
      g_assert (success);     /* as of 0.7.8, cannot fail */
      g_value_take_boxed (value, ret);
    }
  else if (name == q[MIXIN_DP_REMOTE_PENDING_MEMBERS])
    {
      GArray *ret = NULL;
      gboolean success;

      g_return_if_fail (G_VALUE_HOLDS_BOXED (value));
      success = tp_group_mixin_get_remote_pending_members (object,
          &ret, NULL);
      g_assert (success);     /* as of 0.7.8, cannot fail */
      g_value_take_boxed (value, ret);
    }
  else if (name == q[MIXIN_DP_SELF_HANDLE])
    {
      g_return_if_fail (G_VALUE_HOLDS_UINT (value));
      g_value_set_uint (value, mixin->self_handle);
    }
  else if (name == q[MIXIN_DP_MEMBER_IDENTIFIERS])
    {
      g_return_if_fail (G_VALUE_HOLDS (value, TP_HASH_TYPE_HANDLE_IDENTIFIER_MAP));
      g_value_take_boxed (value, dup_member_identifiers (object));
    }
  else
    {
      g_return_if_reached ();
    }
}

static TpDBusPropertiesMixinPropImpl known_group_props[] = {
    { "GroupFlags", NULL, NULL },
    { "HandleOwners", NULL, NULL },
    { "LocalPendingMembers", NULL, NULL },
    { "Members", NULL, NULL },
    { "RemotePendingMembers", NULL, NULL },
    { "SelfHandle", NULL, NULL },
    { "MemberIdentifiers", NULL, NULL },
    { NULL }
};

/**
 * tp_group_mixin_init_dbus_properties: (skip)
 * @cls: The class of an object with this mixin
 *
 * Set up #TpDBusPropertiesMixinClass to use this mixin's implementation of
 * the Group interface's properties.
 *
 * This uses tp_group_mixin_get_dbus_property() as the property getter and
 * sets up a list of the supported properties for it.  Having called this, you
 * should add #TP_CHANNEL_GROUP_FLAG_PROPERTIES to any channels of this class
 * with tp_group_mixin_change_flags() to indicate that the DBus properties are
 * available.
 *
 * Since: 0.7.10
 */
void
tp_group_mixin_init_dbus_properties (GObjectClass *cls)
{

  tp_dbus_properties_mixin_implement_interface (cls,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP, tp_group_mixin_get_dbus_property,
      NULL, known_group_props);
}


#define TP_EXTERNAL_GROUP_MIXIN_OBJ(o) \
    ((GObject *) g_object_get_qdata (o, \
      _external_group_mixin_get_obj_quark ()))

static GQuark
_external_group_mixin_get_obj_quark (void)
{
  static GQuark quark = 0;
  if (!quark)
    quark = g_quark_from_static_string
        ("TpExternalGroupMixinQuark");
  return quark;
}

/**
 * tp_external_group_mixin_init: (skip)
 * @obj: An object implementing the groups interface using an external group
 *    mixin
 * @obj_with_mixin: A GObject with the group mixin
 *
 * Fill in the qdata needed to implement the group interface using
 * the group mixin of another object. This function should usually be called
 * in the instance constructor.
 *
 * Since: 0.5.13
 */
void
tp_external_group_mixin_init (GObject *obj, GObject *obj_with_mixin)
{
  g_object_ref (obj_with_mixin);
  g_object_set_qdata (obj, _external_group_mixin_get_obj_quark (),
      obj_with_mixin);
  tp_group_mixin_add_external (obj_with_mixin, obj);
}

/**
 * tp_external_group_mixin_finalize: (skip)
 * @obj: An object implementing the groups interface using an external group
 *    mixin
 *
 * Remove the external group mixin. This function should usually be called
 * in the dispose or finalize function.
 *
 * Since: 0.5.13
 */
void
tp_external_group_mixin_finalize (GObject *obj)
{
  GObject *obj_with_mixin = g_object_steal_qdata (obj,
      _external_group_mixin_get_obj_quark ());

  tp_group_mixin_remove_external (obj_with_mixin, obj);
  g_object_unref (obj_with_mixin);
}

/**
 * tp_external_group_mixin_init_dbus_properties: (skip)
 * @cls: The class of an object with this mixin
 *
 * Set up #TpDBusPropertiesMixinClass to use this mixin's implementation of
 * the Group interface's properties.
 *
 * This uses tp_group_mixin_get_dbus_property() as the property getter and
 * sets up a list of the supported properties for it.  Having called this, you
 * should add #TP_CHANNEL_GROUP_FLAG_PROPERTIES to channels containing the
 * mixin used by this class with tp_group_mixin_change_flags() to indicate that
 * the DBus properties are available.
 *
 * Since: 0.7.10
 */
void
tp_external_group_mixin_init_dbus_properties (GObjectClass *cls)
{

  tp_dbus_properties_mixin_implement_interface (cls,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP,
      tp_external_group_mixin_get_dbus_property,
      NULL, known_group_props);
}

/**
 * tp_external_group_mixin_get_dbus_property: (skip)
 * @object: An object with this mixin
 * @interface: Must be %TP_IFACE_QUARK_CHANNEL_INTERFACE_GROUP
 * @name: A quark representing the D-Bus property name, either
 *  "GroupFlags", "HandleOwners", "LocalPendingMembers", "Members",
 *  "RemotePendingMembers" or "SelfHandle"
 * @value: A GValue pre-initialized to the right type, into which to put the
 *  value
 * @unused: Ignored
 *
 * An implementation of #TpDBusPropertiesMixinGetter which assumes that the
 * @object has the external group mixin. It can only be used for the Group
 * interface.
 *
 * Since: 0.7.10
 */
void
tp_external_group_mixin_get_dbus_property (GObject *object,
                                           GQuark interface,
                                           GQuark name,
                                           GValue *value,
                                           gpointer unused G_GNUC_UNUSED)
{
  GObject *group = TP_EXTERNAL_GROUP_MIXIN_OBJ (object);

  if (group != NULL)
    {
      tp_group_mixin_get_dbus_property (group, interface, name, value, NULL);
    }
  else if (G_VALUE_HOLDS_BOXED (value))
    {
      /* for certain boxed types we need to supply an empty value */

      if (G_VALUE_HOLDS (value, TP_HASH_TYPE_HANDLE_OWNER_MAP))
        g_value_take_boxed (value, g_hash_table_new (NULL, NULL));
      else if (G_VALUE_HOLDS (value, TP_HASH_TYPE_HANDLE_IDENTIFIER_MAP))
        g_value_take_boxed (value, g_hash_table_new (NULL, NULL));
      else if (G_VALUE_HOLDS (value, DBUS_TYPE_G_UINT_ARRAY))
        g_value_take_boxed (value, g_array_sized_new (FALSE, FALSE,
              sizeof (guint), 0));
      else if (G_VALUE_HOLDS (value, TP_ARRAY_TYPE_LOCAL_PENDING_INFO_LIST))
        g_value_take_boxed (value, g_ptr_array_sized_new (0));
    }
}

#define EXTERNAL_OR_DIE(var) \
    GObject *var = TP_EXTERNAL_GROUP_MIXIN_OBJ ((GObject *) obj); \
    \
    if (var == NULL) \
      { \
        GError na = { TP_ERROR, TP_ERROR_NOT_AVAILABLE, "I'm sure I " \
                      "had a group object around here somewhere?" };\
        \
        dbus_g_method_return_error (context, &na); \
        return; \
      } \

static void
tp_external_group_mixin_add_members_async (TpSvcChannelInterfaceGroup *obj,
                                           const GArray *contacts,
                                           const gchar *message,
                                           DBusGMethodInvocation *context)
{
  EXTERNAL_OR_DIE (group)
  tp_group_mixin_add_members_async ((TpSvcChannelInterfaceGroup *) group,
      contacts, message, context);
}

static void
tp_external_group_mixin_get_self_handle_async (TpSvcChannelInterfaceGroup *obj,
                                               DBusGMethodInvocation *context)
{
  EXTERNAL_OR_DIE (group)
  tp_group_mixin_get_self_handle_async ((TpSvcChannelInterfaceGroup *) group,
      context);
}

static void
tp_external_group_mixin_get_group_flags_async (TpSvcChannelInterfaceGroup *obj,
                                               DBusGMethodInvocation *context)
{
  EXTERNAL_OR_DIE (group)
  tp_group_mixin_get_group_flags_async ((TpSvcChannelInterfaceGroup *) group,
      context);
}

static void
tp_external_group_mixin_get_members_async (TpSvcChannelInterfaceGroup *obj,
                                               DBusGMethodInvocation *context)
{
  EXTERNAL_OR_DIE (group)
  tp_group_mixin_get_members_async ((TpSvcChannelInterfaceGroup *) group,
      context);
}

static void
tp_external_group_mixin_get_local_pending_members_async
    (TpSvcChannelInterfaceGroup *obj, DBusGMethodInvocation *context)
{
  EXTERNAL_OR_DIE (group)
  tp_group_mixin_get_local_pending_members_async
      ((TpSvcChannelInterfaceGroup *) group, context);
}

static void
tp_external_group_mixin_get_local_pending_members_with_info_async
    (TpSvcChannelInterfaceGroup *obj, DBusGMethodInvocation *context)
{
  EXTERNAL_OR_DIE (group)
  tp_group_mixin_get_local_pending_members_with_info_async
      ((TpSvcChannelInterfaceGroup *) group, context);
}

static void
tp_external_group_mixin_get_remote_pending_members_async
    (TpSvcChannelInterfaceGroup *obj, DBusGMethodInvocation *context)
{
  EXTERNAL_OR_DIE (group)
  tp_group_mixin_get_remote_pending_members_async
      ((TpSvcChannelInterfaceGroup *) group, context);
}

static void
tp_external_group_mixin_get_all_members_async (TpSvcChannelInterfaceGroup *obj,
                                               DBusGMethodInvocation *context)
{
  EXTERNAL_OR_DIE (group)
  tp_group_mixin_get_all_members_async ((TpSvcChannelInterfaceGroup *) group,
      context);
}

static void
tp_external_group_mixin_get_handle_owners_async
    (TpSvcChannelInterfaceGroup *obj,
     const GArray *handles,
     DBusGMethodInvocation *context)
{
  EXTERNAL_OR_DIE (group)
  tp_group_mixin_get_handle_owners_async ((TpSvcChannelInterfaceGroup *) group,
      handles, context);
}

static void
tp_external_group_mixin_remove_members_async (TpSvcChannelInterfaceGroup *obj,
                                              const GArray *contacts,
                                              const gchar *message,
                                              DBusGMethodInvocation *context)
{
  EXTERNAL_OR_DIE (group)
  tp_group_mixin_remove_members_with_reason_async
      ((TpSvcChannelInterfaceGroup *) group, contacts, message,
       TP_CHANNEL_GROUP_CHANGE_REASON_NONE, context);
}


static void
tp_external_group_mixin_remove_members_with_reason_async
    (TpSvcChannelInterfaceGroup *obj,
     const GArray *contacts,
     const gchar *message,
     guint reason,
     DBusGMethodInvocation *context)
{
  EXTERNAL_OR_DIE (group)
  tp_group_mixin_remove_members_with_reason_async
      ((TpSvcChannelInterfaceGroup *) group, contacts, message, reason,
       context);
}
/**
 * tp_external_group_mixin_iface_init: (skip)
 * @g_iface: A #TpSvcChannelInterfaceGroupClass
 * @iface_data: Unused
 *
 * Fill in the vtable entries needed to implement the group interface using
 * the group mixin of another object. This function should usually be called
 * via G_IMPLEMENT_INTERFACE.
 *
 * Since: 0.5.13
 */
void
tp_external_group_mixin_iface_init (gpointer g_iface,
                                    gpointer iface_data)
{
  TpSvcChannelInterfaceGroupClass *klass = g_iface;

#define IMPLEMENT(x) tp_svc_channel_interface_group_implement_##x (klass,\
    tp_external_group_mixin_##x##_async)
  IMPLEMENT(add_members);
  IMPLEMENT(get_all_members);
  IMPLEMENT(get_group_flags);
  IMPLEMENT(get_handle_owners);
  IMPLEMENT(get_local_pending_members);
  IMPLEMENT(get_local_pending_members_with_info);
  IMPLEMENT(get_members);
  IMPLEMENT(get_remote_pending_members);
  IMPLEMENT(get_self_handle);
  IMPLEMENT(remove_members);
  IMPLEMENT(remove_members_with_reason);
#undef IMPLEMENT
}
