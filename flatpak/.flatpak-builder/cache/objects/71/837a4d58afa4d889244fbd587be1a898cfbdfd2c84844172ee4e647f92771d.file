/* A ContactList channel with handle type LIST or GROUP.
 *
 * Copyright © 2009-2010 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright © 2009 Nokia Corporation
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

#include <config.h>
#include <telepathy-glib/contact-list-channel-internal.h>

#include <telepathy-glib/channel-iface.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/exportable-channel.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/svc-channel.h>
#include <telepathy-glib/svc-generic.h>

#include <telepathy-glib/base-contact-list-internal.h>

static void list_channel_iface_init (TpSvcChannelClass *iface);
static void group_channel_iface_init (TpSvcChannelClass *iface);
static void list_group_iface_init (TpSvcChannelInterfaceGroupClass *iface);
static void group_group_iface_init (TpSvcChannelInterfaceGroupClass *iface);

/* Abstract base class */
G_DEFINE_ABSTRACT_TYPE_WITH_CODE (TpBaseContactListChannel,
    _tp_base_contact_list_channel,
    TP_TYPE_BASE_CHANNEL,
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL_TYPE_CONTACT_LIST, NULL);
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP, NULL))

/* Subclass for handle type LIST */
G_DEFINE_TYPE_WITH_CODE (TpContactListChannel, _tp_contact_list_channel,
    TP_TYPE_BASE_CONTACT_LIST_CHANNEL,
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP,
      list_group_iface_init);
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL, list_channel_iface_init))

/* Subclass for handle type GROUP */
G_DEFINE_TYPE_WITH_CODE (TpContactGroupChannel, _tp_contact_group_channel,
    TP_TYPE_BASE_CONTACT_LIST_CHANNEL,
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL_INTERFACE_GROUP,
      group_group_iface_init);
    G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL, group_channel_iface_init))

static GPtrArray *
base_contact_list_get_interfaces (TpBaseChannel *self)
{
  GPtrArray *interfaces;

  interfaces = TP_BASE_CHANNEL_CLASS (
      _tp_base_contact_list_channel_parent_class)->get_interfaces (self);

  g_ptr_array_add (interfaces, TP_IFACE_CHANNEL_INTERFACE_GROUP);
  return interfaces;
};

enum
{
  PROP_MANAGER = 1,
  N_PROPS
};

static void
_tp_base_contact_list_channel_init (TpBaseContactListChannel *self)
{
}

static void
_tp_contact_list_channel_init (TpContactListChannel *self)
{
}

static void
_tp_contact_group_channel_init (TpContactGroupChannel *self)
{
}

static void
tp_base_contact_list_channel_constructed (GObject *object)
{
  TpBaseContactListChannel *self = TP_BASE_CONTACT_LIST_CHANNEL (object);
  TpBaseChannel *base = (TpBaseChannel *) self;
  TpBaseConnection *conn = tp_base_channel_get_connection (base);
  TpHandleRepoIface *contact_repo = tp_base_connection_get_handles (conn,
      TP_HANDLE_TYPE_CONTACT);
  void (*chain_up) (GObject *) =
    ((GObjectClass *) _tp_base_contact_list_channel_parent_class)->constructed;

  if (chain_up != NULL)
    chain_up (object);

  g_assert (TP_IS_BASE_CONTACT_LIST (self->manager));

  tp_base_channel_register (base);

  tp_group_mixin_init (object, G_STRUCT_OFFSET (TpBaseContactListChannel,
        group), contact_repo,
      tp_base_connection_get_self_handle (conn));
  /* Both the subclasses have full support for telepathy-spec 0.17.6. */
  tp_group_mixin_change_flags (object,
      TP_CHANNEL_GROUP_FLAG_PROPERTIES, 0);
}

static void
tp_contact_list_channel_constructed (GObject *object)
{
  TpBaseContactListChannel *self = TP_BASE_CONTACT_LIST_CHANNEL (object);
  void (*chain_up) (GObject *) =
    ((GObjectClass *) _tp_contact_list_channel_parent_class)->constructed;

  if (chain_up != NULL)
    chain_up (object);

  tp_group_mixin_change_flags (object,
      _tp_base_contact_list_get_list_flags (self->manager,
        tp_base_channel_get_target_handle ((TpBaseChannel *) self)),
      0);
}

static void
tp_contact_group_channel_constructed (GObject *object)
{
  TpBaseContactListChannel *self = TP_BASE_CONTACT_LIST_CHANNEL (object);
  void (*chain_up) (GObject *) =
    ((GObjectClass *) _tp_contact_group_channel_parent_class)->constructed;

  if (chain_up != NULL)
    chain_up (object);

  tp_group_mixin_change_flags (object,
      _tp_base_contact_list_get_group_flags (self->manager), 0);
}


static void
tp_base_contact_list_channel_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpBaseContactListChannel *self = TP_BASE_CONTACT_LIST_CHANNEL (object);

  switch (property_id)
    {
    case PROP_MANAGER:
      g_value_set_object (value, self->manager);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

static void
tp_base_contact_list_channel_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpBaseContactListChannel *self = TP_BASE_CONTACT_LIST_CHANNEL (object);

  switch (property_id)
    {
    case PROP_MANAGER:
      g_assert (self->manager == NULL);   /* construct-only */
      self->manager = g_value_dup_object (value);
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
    }
}

void
_tp_base_contact_list_channel_close (TpBaseContactListChannel *self)
{
  if (self->manager == NULL)
    return;

  tp_clear_object (&self->manager);
  tp_group_mixin_finalize ((GObject *) self);
  tp_base_channel_destroyed ((TpBaseChannel *) self);
}

static void
tp_base_contact_list_channel_dispose (GObject *object)
{
  TpBaseContactListChannel *self = TP_BASE_CONTACT_LIST_CHANNEL (object);
  void (*dispose) (GObject *) =
    G_OBJECT_CLASS (_tp_base_contact_list_channel_parent_class)->dispose;

  _tp_base_contact_list_channel_close (self);

  if (dispose != NULL)
    dispose (object);
}

static gboolean
tp_base_contact_list_channel_check_still_usable (
    TpBaseContactListChannel *self,
    DBusGMethodInvocation *context)
{
  if (self->manager == NULL)
    {
      GError e = { TP_ERROR, TP_ERROR_TERMINATED, "Channel already closed" };
      dbus_g_method_return_error (context, &e);
      return FALSE;
    }

  return TRUE;
}

static gboolean
group_add_member (GObject *object,
    TpHandle handle,
    const gchar *message,
    GError **error)
{
  /* We don't use this: it's synchronous */
  g_return_val_if_reached (FALSE);
}

static gboolean
group_remove_member (GObject *object,
    TpHandle handle,
    const gchar *message,
    GError **error)
{
  /* We don't use this: it's synchronous */
  g_return_val_if_reached (FALSE);
}

static gboolean
list_add_member (GObject *object,
    TpHandle handle,
    const gchar *message,
    GError **error)
{
  /* We don't use this: it's synchronous */
  g_return_val_if_reached (FALSE);
}

static gboolean
list_remove_member (GObject *object,
    TpHandle handle,
    const gchar *message,
    GError **error)
{
  /* We don't use this: it's synchronous */
  g_return_val_if_reached (FALSE);
}

/* We don't use this: #TpBaseChannelClass.close doesn't allow us to fail to
 * close, which is a quirk of the old ContactList design, so subclasses must
 * IMPLEMENT (close) manually. */
static void
stub_close (TpBaseChannel *channel G_GNUC_UNUSED)
{
  g_return_if_reached ();
}

static void
_tp_base_contact_list_channel_class_init (TpBaseContactListChannelClass *cls)
{
  GObjectClass *object_class = (GObjectClass *) cls;
  TpBaseChannelClass *base_class = (TpBaseChannelClass *) cls;

  object_class->constructed = tp_base_contact_list_channel_constructed;
  object_class->set_property = tp_base_contact_list_channel_set_property;
  object_class->get_property = tp_base_contact_list_channel_get_property;
  object_class->dispose = tp_base_contact_list_channel_dispose;

  base_class->channel_type = TP_IFACE_CHANNEL_TYPE_CONTACT_LIST;
  base_class->target_handle_type = 0;       /* placeholder, set in subclass */
  base_class->get_interfaces = base_contact_list_get_interfaces;
  base_class->close = stub_close;           /* placeholder, not called */

  g_object_class_install_property (object_class, PROP_MANAGER,
      g_param_spec_object ("manager", "TpBaseContactList",
        "TpBaseContactList object that owns this channel",
        TP_TYPE_BASE_CONTACT_LIST,
        G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS));

  /* Group mixin is initialized separately for each subclass - they have
   *  different callbacks */
}

static void
_tp_contact_list_channel_class_init (TpContactListChannelClass *cls)
{
  GObjectClass *object_class = (GObjectClass *) cls;
  TpBaseChannelClass *base_class = (TpBaseChannelClass *) cls;

  object_class->constructed = tp_contact_list_channel_constructed;

  base_class->target_handle_type = TP_HANDLE_TYPE_LIST;

  tp_group_mixin_class_init (object_class,
      G_STRUCT_OFFSET (TpBaseContactListChannelClass, group_class),
      list_add_member,
      list_remove_member);
  tp_group_mixin_init_dbus_properties (object_class);
}

static void
_tp_contact_group_channel_class_init (TpContactGroupChannelClass *cls)
{
  GObjectClass *object_class = (GObjectClass *) cls;
  TpBaseChannelClass *base_class = (TpBaseChannelClass *) cls;

  object_class->constructed = tp_contact_group_channel_constructed;

  base_class->target_handle_type = TP_HANDLE_TYPE_GROUP;

  tp_group_mixin_class_init (object_class,
      G_STRUCT_OFFSET (TpBaseContactListChannelClass, group_class),
      group_add_member,
      group_remove_member);
  tp_group_mixin_init_dbus_properties (object_class);
}

static void
list_channel_close (TpSvcChannel *iface G_GNUC_UNUSED,
    DBusGMethodInvocation *context)
{
  GError e = { TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
      "ContactList channels with handle type LIST may not be closed" };

  dbus_g_method_return_error (context, &e);
}

static void
group_channel_close (TpSvcChannel *iface,
    DBusGMethodInvocation *context)
{
  TpBaseContactListChannel *self = TP_BASE_CONTACT_LIST_CHANNEL (iface);
  GError *error = NULL;

  if (!tp_base_contact_list_channel_check_still_usable (self, context))
    return;

  if (tp_handle_set_size (self->group.members) > 0)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "Non-empty groups may not be deleted (closed)");
      goto error;
    }

  if (!_tp_base_contact_list_delete_group_by_handle (self->manager,
      tp_base_channel_get_target_handle ((TpBaseChannel *) self), &error))
    goto error;

  tp_svc_channel_return_from_close (context);
  return;

error:
  dbus_g_method_return_error (context, error);
  g_clear_error (&error);
}

static void
list_channel_iface_init (TpSvcChannelClass *iface)
{
#define IMPLEMENT(x) tp_svc_channel_implement_##x (iface, list_channel_##x)
  IMPLEMENT (close);
#undef IMPLEMENT
}

static void
group_channel_iface_init (TpSvcChannelClass *iface)
{
#define IMPLEMENT(x) tp_svc_channel_implement_##x (iface, group_channel_##x)
  IMPLEMENT (close);
#undef IMPLEMENT
}

static void
list_group_add_members (TpSvcChannelInterfaceGroup *iface,
    const GArray *contacts,
    const gchar *message,
    DBusGMethodInvocation *context)
{
  TpBaseContactListChannel *self = TP_BASE_CONTACT_LIST_CHANNEL (iface);

  if (tp_base_contact_list_channel_check_still_usable (self, context))
    _tp_base_contact_list_add_to_list (self->manager,
        tp_base_channel_get_target_handle ((TpBaseChannel *) self),
        contacts, message, context);
}

static void
list_group_remove_members_with_reason (TpSvcChannelInterfaceGroup *iface,
    const GArray *contacts,
    const gchar *message,
    guint reason,
    DBusGMethodInvocation *context)
{
  TpBaseContactListChannel *self = TP_BASE_CONTACT_LIST_CHANNEL (iface);

  if (tp_base_contact_list_channel_check_still_usable (self, context))
    _tp_base_contact_list_remove_from_list (self->manager,
        tp_base_channel_get_target_handle ((TpBaseChannel *) self),
        contacts, message, reason, context);
}

static void
list_group_remove_members (TpSvcChannelInterfaceGroup *iface,
    const GArray *contacts,
    const gchar *message,
    DBusGMethodInvocation *context)
{
  /* also returns void, so this is OK */
  list_group_remove_members_with_reason (iface, contacts, message,
      TP_CHANNEL_GROUP_CHANGE_REASON_NONE, context);
}

static void
list_group_iface_init (TpSvcChannelInterfaceGroupClass *iface)
{
  tp_group_mixin_iface_init (iface, NULL);

#define IMPLEMENT(x) tp_svc_channel_interface_group_implement_##x (iface, \
    list_group_##x)
  IMPLEMENT (add_members);
  IMPLEMENT (remove_members);
  IMPLEMENT (remove_members_with_reason);
#undef IMPLEMENT
}

static void
group_group_add_members (TpSvcChannelInterfaceGroup *iface,
    const GArray *contacts,
    const gchar *message,
    DBusGMethodInvocation *context)
{
  TpBaseContactListChannel *self = TP_BASE_CONTACT_LIST_CHANNEL (iface);

  if (tp_base_contact_list_channel_check_still_usable (self, context))
    _tp_base_contact_list_add_to_group (self->manager,
        tp_base_channel_get_target_handle ((TpBaseChannel *) self),
        contacts, message, context);
}

static void
group_group_remove_members_with_reason (TpSvcChannelInterfaceGroup *iface,
    const GArray *contacts,
    const gchar *message,
    guint reason,
    DBusGMethodInvocation *context)
{
  TpBaseContactListChannel *self = TP_BASE_CONTACT_LIST_CHANNEL (iface);

  if (tp_base_contact_list_channel_check_still_usable (self, context))
    _tp_base_contact_list_remove_from_group (self->manager,
        tp_base_channel_get_target_handle ((TpBaseChannel *) self),
        contacts, message, reason, context);
}

static void
group_group_remove_members (TpSvcChannelInterfaceGroup *iface,
    const GArray *contacts,
    const gchar *message,
    DBusGMethodInvocation *context)
{
  /* also returns void, so this is OK */
  group_group_remove_members_with_reason (iface, contacts, message,
      TP_CHANNEL_GROUP_CHANGE_REASON_NONE, context);
}

static void
group_group_iface_init (TpSvcChannelInterfaceGroupClass *iface)
{
  tp_group_mixin_iface_init (iface, NULL);

#define IMPLEMENT(x) tp_svc_channel_interface_group_implement_##x (iface, \
    group_group_##x)
  IMPLEMENT (add_members);
  IMPLEMENT (remove_members);
  IMPLEMENT (remove_members_with_reason);
#undef IMPLEMENT
}
