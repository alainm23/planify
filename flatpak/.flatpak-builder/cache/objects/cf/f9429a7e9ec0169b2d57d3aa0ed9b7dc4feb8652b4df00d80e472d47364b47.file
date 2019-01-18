/*
 * group-mixin.h - Header for TpGroupMixin
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

#if defined (TP_DISABLE_SINGLE_INCLUDE) && !defined (_TP_IN_META_HEADER) && !defined (_TP_COMPILATION)
#error "Only <telepathy-glib/telepathy-glib.h> and <telepathy-glib/telepathy-glib-dbus.h> can be included directly."
#endif

#ifndef __TP_GROUP_MIXIN_H__
#define __TP_GROUP_MIXIN_H__

#include <telepathy-glib/dbus-properties-mixin.h>
#include <telepathy-glib/handle-repo.h>
#include <telepathy-glib/svc-channel.h>
#include <telepathy-glib/util.h>

G_BEGIN_DECLS

typedef struct _TpGroupMixinClass TpGroupMixinClass;
typedef struct _TpGroupMixinClassPrivate TpGroupMixinClassPrivate;

typedef struct _TpGroupMixin TpGroupMixin;
typedef struct _TpGroupMixinPrivate TpGroupMixinPrivate;

/**
 * TpGroupMixinAddMemberFunc:
 * @obj: An object implementing the group interface with this mixin
 * @handle: The handle of the contact to be added
 * @message: A message to be sent if the protocol supports it
 * @error: Used to return a Telepathy D-Bus error if %FALSE is returned
 *
 * Signature of the callback used to add a member to the group.
 * This should perform the necessary operations in the underlying IM protocol
 * to cause the member to be added.
 *
 * Returns: %TRUE on success, %FALSE with @error set on error
 */
typedef gboolean (*TpGroupMixinAddMemberFunc) (GObject *obj,
    TpHandle handle, const gchar *message, GError **error);

/**
 * TpGroupMixinRemMemberFunc:
 * @obj: An object implementing the group interface with this mixin
 * @handle: The handle of the contact to be removed
 * @message: A message to be sent if the protocol supports it
 * @error: Used to return a Telepathy D-Bus error if %FALSE is returned
 *
 * Signature of the callback used to remove a member from the group.
 * This should perform the necessary operations in the underlying IM protocol
 * to cause the member to be removed.
 *
 * Returns: %TRUE on success, %FALSE with @error set on error
 */
typedef gboolean (*TpGroupMixinRemMemberFunc) (GObject *obj,
    TpHandle handle, const gchar *message, GError **error);

/**
 * TpGroupMixinRemMemberWithReasonFunc:
 * @obj: An object implementing the group interface with this mixin
 * @handle: The handle of the contact to be removed
 * @message: A message to be sent if the protocol supports it
 * @reason: A #TpChannelGroupChangeReason indicating the reason
 * @error: Used to return a Telepathy D-Bus error if %FALSE is returned
 *
 * Signature of the callback used to remove a member from the group.
 * This should perform the necessary operations in the underlying IM protocol
 * to cause the member to be removed.
 *
 * Set this with tp_group_mixin_class_set_remove_with_reason_func(), .
 *
 * Returns: %TRUE on success, %FALSE with @error set on error
 */
typedef gboolean (*TpGroupMixinRemMemberWithReasonFunc) (GObject *obj,
    TpHandle handle, const gchar *message, guint reason, GError **error);

void tp_group_mixin_class_set_remove_with_reason_func (GObjectClass *cls,
    TpGroupMixinRemMemberWithReasonFunc func);

/**
 * TpGroupMixin:
 * @handle_repo: The connection's contact handle repository
 * @self_handle: The local user's handle within this group, or 0 if none.
 *  Set using tp_group_mixin_init() and tp_group_mixin_change_self_handle().
 * @group_flags: This group's flags. Set using tp_group_mixin_change_flags();
 *  defaults to 0.
 * @members: The members of the group. Alter using
 *  tp_group_mixin_change_members().
 * @local_pending: Members awaiting the local user's approval to join the
 *  group. Alter using tp_group_mixin_change_members().
 * @remote_pending: Members awaiting remote (e.g. remote user or server)
 *  approval to join the group. Alter using tp_group_mixin_change_members().
 * @priv: Pointer to opaque private data
 *
 * Structure representing the group mixin as used in a particular class.
 * To be placed in the implementation's instance structure.
 *
 * All fields should be considered read-only.
 */
struct _TpGroupMixin {
  TpHandleRepoIface *handle_repo;
  TpHandle self_handle;

  TpChannelGroupFlags group_flags;

  TpHandleSet *members;
  TpHandleSet *local_pending;
  TpHandleSet *remote_pending;

  TpGroupMixinPrivate *priv;
};

/**
 * TpGroupMixinClass:
 * @add_member: The add-member function that was passed to
 *  tp_group_mixin_class_init()
 * @remove_member: The remove-member function that was passed to
 *  tp_group_mixin_class_init()
 * @priv: Pointer to opaque private data
 *
 * Structure representing the group mixin as used in a particular class.
 * To be placed in the implementation's class structure.
 *
 * Initialize this with tp_group_mixin_class_init().
 *
 * All fields should be considered read-only.
 */
struct _TpGroupMixinClass {
  TpGroupMixinAddMemberFunc add_member;
  TpGroupMixinRemMemberFunc remove_member;
  TpGroupMixinClassPrivate *priv;
};

/* TYPE MACROS */
#define TP_GROUP_MIXIN_CLASS_OFFSET_QUARK \
  (tp_group_mixin_class_get_offset_quark ())
#define TP_GROUP_MIXIN_CLASS_OFFSET(o) \
  tp_mixin_class_get_offset (o, TP_GROUP_MIXIN_CLASS_OFFSET_QUARK)
#define TP_GROUP_MIXIN_CLASS(o) \
  ((TpGroupMixinClass *) tp_mixin_offset_cast (o, \
    TP_GROUP_MIXIN_CLASS_OFFSET (o)))
#define TP_HAS_GROUP_MIXIN_CLASS(cls) (TP_GROUP_MIXIN_CLASS_OFFSET (cls) != 0)

#define TP_GROUP_MIXIN_OFFSET_QUARK (tp_group_mixin_get_offset_quark ())
#define TP_GROUP_MIXIN_OFFSET(o) \
  tp_mixin_instance_get_offset (o, TP_GROUP_MIXIN_OFFSET_QUARK)
#define TP_GROUP_MIXIN(o) ((TpGroupMixin *) tp_mixin_offset_cast (o, \
      TP_GROUP_MIXIN_OFFSET(o)))
#define TP_HAS_GROUP_MIXIN(o) (TP_GROUP_MIXIN_OFFSET (o) != 0)

GQuark tp_group_mixin_class_get_offset_quark (void);
GQuark tp_group_mixin_get_offset_quark (void);

void tp_group_mixin_class_init (GObjectClass *obj_cls,
    glong offset, TpGroupMixinAddMemberFunc add_func,
    TpGroupMixinRemMemberFunc rem_func);
void tp_group_mixin_class_allow_self_removal (GObjectClass *obj_cls);

void tp_group_mixin_init (GObject *obj, glong offset,
    TpHandleRepoIface *handle_repo, TpHandle self_handle);
void tp_group_mixin_finalize (GObject *obj);

gboolean tp_group_mixin_get_self_handle (GObject *obj,
    guint *ret, GError **error);
gboolean tp_group_mixin_get_group_flags (GObject *obj,
    guint *ret, GError **error);

gboolean tp_group_mixin_add_members (GObject *obj,
    const GArray *contacts, const gchar *message, GError **error);
gboolean tp_group_mixin_remove_members (GObject *obj,
    const GArray *contacts, const gchar *message, GError **error);
gboolean tp_group_mixin_remove_members_with_reason (GObject *obj,
    const GArray *contacts, const gchar *message, guint reason,
    GError **error);

gboolean tp_group_mixin_get_members (GObject *obj,
    GArray **ret, GError **error);
gboolean tp_group_mixin_get_local_pending_members (GObject *obj,
    GArray **ret, GError **error);
gboolean tp_group_mixin_get_local_pending_members_with_info (GObject *obj,
    GPtrArray **ret, GError **error);
gboolean tp_group_mixin_get_remote_pending_members (GObject *obj,
    GArray **ret, GError **error);
gboolean tp_group_mixin_get_all_members (GObject *obj,
    GArray **members, GArray **local_pending, GArray **remote_pending,
    GError **error);

gboolean tp_group_mixin_get_handle_owners (GObject *obj,
    const GArray *handles, GArray **ret, GError **error);

void tp_group_mixin_change_flags (GObject *obj,
    TpChannelGroupFlags add, TpChannelGroupFlags del);
gboolean tp_group_mixin_change_members (GObject *obj,
    const gchar *message, const TpIntset *add, const TpIntset *del,
    const TpIntset *add_local_pending, const TpIntset *add_remote_pending,
    TpHandle actor, TpChannelGroupChangeReason reason);
gboolean tp_group_mixin_change_members_detailed (GObject *obj,
    const TpIntset *add, const TpIntset *del,
    const TpIntset *add_local_pending, const TpIntset *add_remote_pending,
    const GHashTable *details);
void tp_group_mixin_change_self_handle (GObject *obj,
    TpHandle new_self_handle);

void tp_group_mixin_add_handle_owner (GObject *obj,
    TpHandle local_handle, TpHandle owner_handle);
void tp_group_mixin_add_handle_owners (GObject *obj,
    GHashTable *local_to_owner_handle);

void tp_group_mixin_get_dbus_property (GObject *object,
    GQuark interface, GQuark name, GValue *value, gpointer unused);
void tp_group_mixin_init_dbus_properties (GObjectClass *cls);

void tp_group_mixin_iface_init (gpointer g_iface, gpointer iface_data);

void tp_external_group_mixin_init (GObject *obj, GObject *obj_with_mixin);
void tp_external_group_mixin_finalize (GObject *obj);
void tp_external_group_mixin_iface_init (gpointer g_iface,
    gpointer iface_data);

void tp_external_group_mixin_get_dbus_property (GObject *object,
    GQuark interface, GQuark name, GValue *value, gpointer unused);
void tp_external_group_mixin_init_dbus_properties (GObjectClass *cls);

G_END_DECLS

#endif /* #ifndef __TP_GROUP_MIXIN_H__ */
