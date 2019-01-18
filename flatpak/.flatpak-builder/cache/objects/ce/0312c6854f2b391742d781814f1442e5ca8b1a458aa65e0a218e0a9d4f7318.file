/*
 * base-room-config.c - Channel.Interface.RoomConfig1 implementation
 * Copyright ©2011 Collabora Ltd.
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include "config.h"

#include <telepathy-glib/base-room-config.h>

#include <telepathy-glib/dbus-properties-mixin.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/svc-channel.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_ROOM_CONFIG
#include "debug-internal.h"
#include "util-internal.h"

/**
 * SECTION:base-room-config
 * @title: TpBaseRoomConfig
 * @short_description: implements the RoomConfig interface for chat rooms.
 *
 * This class implements the #TpSvcChannelInterfaceRoomConfig interface on
 * multi-user chat room channels. CMs are expected to subclass this base class
 * to implement the protocol-specific details of changing room configuration.
 * Then, in the connection manager's subclass of #TpBaseChannel for multi-user
 * chats:
 *
 * <itemizedlist>
 *  <listitem>
 *   <para>in #G_DEFINE_TYPE_WITH_CODE, implement
 *   #TP_TYPE_SVC_CHANNEL_INTERFACE_ROOM_CONFIG using
 *   tp_base_room_config_iface_init():</para>
 * |[
 * G_DEFINE_TYPE_WITH_CODE (MyMucChannel, my_muc_channel,
 *     TP_TYPE_BASE_CHANNEL,
 *     // ...
 *     G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CHANNEL_INTERFACE_ROOM_CONFIG,
 *         tp_base_room_config_iface_init)
 *     // ...
 *     )
 * ]|
 *  </listitem>
 *  <listitem>
 *   <para>in the <function>class_init</function> method, call
 *    tp_base_room_config_register_class():</para>
 * |[
 * static void
 * my_muc_channel_class_init (MyMucChannelClass *klass)
 * {
 *   // ...
 *   tp_base_room_config_register_class (TP_BASE_CHANNEL_CLASS (klass));
 *   // ...
 * }
 * ]|
 *  </listitem>
 *  <listitem>
 *   <para>include %TP_IFACE_CHANNEL_INTERFACE_ROOM_CONFIG in the return of
 *    #TpBaseChannelClass.get_interfaces.</para>
 *  </listitem>
 * </itemizedlist>
 *
 * If this protocol supports modifying some aspects of the room's
 * configuration, the subclass should call
 * tp_base_room_config_set_property_mutable() to mark appropriate properties as
 * potentially-modifiable, call
 * tp_base_room_config_set_can_update_configuration() to indicate whether the
 * local user has permission to modify those properties at present, and
 * implement #TpBaseRoomConfigClass.update_async. When updates to properties
 * are received from the network, they should be updated on this object using
 * g_object_set():
 *
 * |[
 *   g_object_self (room_config,
 *      "description", "A place to bury strangers",
 *      "private", TRUE,
 *      NULL);
 *   tp_base_room_config_emit_properties_changed (room_config);
 * ]|
 *
 * On joining the room, once the entire room configuration has been retrieved
 * from the network, the CM should call tp_base_room_config_set_retrieved().
 *
 * Since: 0.15.8
 */

/**
 * TpBaseRoomConfigClass:
 * @update_async: begins a request to modify the room's configuration.
 * @update_finish: completes a call to @update_async; the default
 *  implementation may be used if @update_async uses #GSimpleAsyncResult
 *
 * Class structure for #TpBaseRoomConfig. By default, @update_async is %NULL,
 * indicating that updating room configuration is not implemented; subclasses
 * should override it if they wish to support updating room configuration.
 */

/**
 * TpBaseRoomConfig:
 *
 * An object representing the configuration of a multi-user chat room.
 *
 * There are no public fields.
 */

/**
 * TpBaseRoomConfigUpdateAsync:
 * @self: a #TpBaseRoomConfig
 * @validated_properties: a mapping from #TpBaseRoomConfigProperty to #GValue,
 *  whose types have already been validated. The function should not modify
 *  this hash table.
 * @callback: a callback to call on success, failure or disconnection
 * @user_data: user data for the callback
 *
 * Signature for a function to begin a network request to update the room
 * configuration. It is guaranteed that @validated_properties will only contain
 * properties which were marked as mutable when the D-Bus method invocation
 * arrived.
 *
 * Note that #TpBaseRoomConfig will take care of applying the property updates
 * to itself if the operation succeeds.
 */

/**
 * TpBaseRoomConfigUpdateFinish:
 * @self: a #TpBaseRoomConfig
 * @result: the result passed to the callback
 * @error: used to return an error if %FALSE is returned.
 *
 * Signature for a function to complete a call to a corresponding
 * implementation of #TpBaseRoomConfigUpdateAsync.
 *
 * Returns: %TRUE if the room configuration update was accepted by the server;
 *  %FALSE, with @error set, otherwise.
 */

/**
 * TpBaseRoomConfigProperty:
 * @TP_BASE_ROOM_CONFIG_ANONYMOUS: corresponds to #TpBaseRoomConfig:anonymous
 * @TP_BASE_ROOM_CONFIG_INVITE_ONLY: corresponds to #TpBaseRoomConfig:invite-only
 * @TP_BASE_ROOM_CONFIG_LIMIT: corresponds to #TpBaseRoomConfig:limit
 * @TP_BASE_ROOM_CONFIG_MODERATED: corresponds to #TpBaseRoomConfig:moderated
 * @TP_BASE_ROOM_CONFIG_TITLE: corresponds to #TpBaseRoomConfig:title
 * @TP_BASE_ROOM_CONFIG_DESCRIPTION: corresponds to #TpBaseRoomConfig:description
 * @TP_BASE_ROOM_CONFIG_PERSISTENT: corresponds to #TpBaseRoomConfig:persistent
 * @TP_BASE_ROOM_CONFIG_PRIVATE: corresponds to #TpBaseRoomConfig:private
 * @TP_BASE_ROOM_CONFIG_PASSWORD_PROTECTED: corresponds to #TpBaseRoomConfig:password-protected
 * @TP_BASE_ROOM_CONFIG_PASSWORD: corresponds to #TpBaseRoomConfig:password
 * @TP_BASE_ROOM_CONFIG_PASSWORD_HINT: corresponds to #TpBaseRoomConfig:password-hint
 * @TP_NUM_BASE_ROOM_CONFIG_PROPERTIES: the number of configuration properties
 *  currently defined.
 *
 * An enumeration of room configuration fields, corresponding to GObject
 * properties and, in turn, to D-Bus properties.
 */

/**
 * TP_TYPE_BASE_ROOM_CONFIG_PROPERTY:
 *
 * The #GEnumClass type of #TpBaseRoomConfigProperty. (The nicknames are chosen
 * to correspond to unqualified D-Bus property names.)
 */

struct _TpBaseRoomConfigPrivate {
    TpBaseChannel *channel;

    gboolean anonymous;
    gboolean invite_only;
    guint32 limit;
    gboolean moderated;
    gchar *title;
    gchar *description;
    gboolean persistent;
    gboolean private;
    gboolean password_protected;
    gchar *password;
    gchar *password_hint;

    gboolean can_update_configuration;
    TpIntset *mutable_properties;
    gboolean configuration_retrieved;

    /* Contains elements of TpBaseRoomConfigProperty which are known to have
     * changed since we last emitted PropertiesChanged.
     */
    TpIntset *changed_properties;
    /* These two properties are not elements of TpBaseRoomConfigProperty; we
     * track 'em separately.
     */
    gboolean can_update_configuration_changed;
    gboolean mutable_properties_changed;

    /* Details of a pending update, or both NULL if no call to
     * UpdateConfiguration is in progress.
     */
    DBusGMethodInvocation *update_configuration_ctx;
    GHashTable *validated_properties;
};

enum {
    PROP_CHANNEL = 42,

    /* D-Bus properties */
    PROP_ANONYMOUS,
    PROP_INVITE_ONLY,
    PROP_LIMIT,
    PROP_MODERATED,
    PROP_TITLE,
    PROP_DESCRIPTION,
    PROP_PERSISTENT,
    PROP_PRIVATE,
    PROP_PASSWORD_PROTECTED,
    PROP_PASSWORD,
    PROP_PASSWORD_HINT,

    PROP_CAN_UPDATE_CONFIGURATION,
    PROP_MUTABLE_PROPERTIES,
    PROP_CONFIGURATION_RETRIEVED,
};

G_DEFINE_TYPE (TpBaseRoomConfig, tp_base_room_config, G_TYPE_OBJECT)

static gboolean tp_base_room_config_update_finish (
    TpBaseRoomConfig *self,
    GAsyncResult *result,
    GError **error);

static void
tp_base_room_config_init (TpBaseRoomConfig *self)
{
  TpBaseRoomConfigPrivate *priv;

  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_BASE_ROOM_CONFIG,
      TpBaseRoomConfigPrivate);
  priv = self->priv;

  priv->mutable_properties = tp_intset_new ();
  priv->changed_properties = tp_intset_new ();
}

static void
add_properties_from_intset (
    GPtrArray *property_names,
    TpIntset *properties)
{
  TpIntsetFastIter iter;
  guint i;

  tp_intset_fast_iter_init (&iter, properties);
  while (tp_intset_fast_iter_next (&iter, &i))
    {
      const gchar *property_name = _tp_enum_to_nick (
          TP_TYPE_BASE_ROOM_CONFIG_PROPERTY, i);

      g_assert (property_name != NULL);
      g_ptr_array_add (property_names, (gchar *) property_name);
    }
}

static void
tp_base_room_config_get_property (
    GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpBaseRoomConfig *self = TP_BASE_ROOM_CONFIG (object);
  TpBaseRoomConfigPrivate *priv = self->priv;

  switch (property_id)
    {
      case PROP_CHANNEL:
        g_value_set_object (value, priv->channel);
        break;
      case PROP_ANONYMOUS:
        g_value_set_boolean (value, priv->anonymous);
        break;
      case PROP_INVITE_ONLY:
        g_value_set_boolean (value, priv->invite_only);
        break;
      case PROP_LIMIT:
        g_value_set_uint (value, priv->limit);
        break;
      case PROP_MODERATED:
        g_value_set_boolean (value, priv->moderated);
        break;
      case PROP_TITLE:
        g_value_set_string (value, priv->title);
        break;
      case PROP_DESCRIPTION:
        g_value_set_string (value, priv->description);
        break;
      case PROP_PERSISTENT:
        g_value_set_boolean (value, priv->persistent);
        break;
      case PROP_PRIVATE:
        g_value_set_boolean (value, priv->private);
        break;
      case PROP_PASSWORD_PROTECTED:
        g_value_set_boolean (value, priv->password_protected);
        break;
      case PROP_PASSWORD:
        g_value_set_string (value, priv->password);
        break;
      case PROP_PASSWORD_HINT:
        g_value_set_string (value, priv->password_hint);
        break;
      case PROP_CAN_UPDATE_CONFIGURATION:
        g_value_set_boolean (value, priv->can_update_configuration);
        break;
      case PROP_MUTABLE_PROPERTIES:
      {
        GPtrArray *property_names = g_ptr_array_new ();

        add_properties_from_intset (property_names, priv->mutable_properties);
        g_ptr_array_add (property_names, NULL);
        g_value_take_boxed (value,
            g_strdupv ((gchar **) property_names->pdata));
        g_ptr_array_unref (property_names);
        break;
      }
      case PROP_CONFIGURATION_RETRIEVED:
        g_value_set_boolean (value, priv->configuration_retrieved);
        break;
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}

static void
channel_died_cb (
    gpointer data,
    GObject *deceased_channel)
{
  TpBaseRoomConfig *self = TP_BASE_ROOM_CONFIG (data);
  TpBaseRoomConfigPrivate *priv = self->priv;

  DEBUG ("(TpBaseChannel *)%p associated with (TpBaseRoomConfig *)%p died",
      deceased_channel, self);
  priv->channel = NULL;
}

static void
tp_base_room_config_set_property (
    GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpBaseRoomConfig *self = TP_BASE_ROOM_CONFIG (object);
  TpBaseRoomConfigPrivate *priv = self->priv;

  switch (property_id)
    {
      case PROP_CHANNEL:
        g_assert (priv->channel == NULL);
        priv->channel = g_value_get_object (value);
        g_assert (priv->channel != NULL);
        g_object_weak_ref (G_OBJECT (priv->channel), channel_died_cb, self);
        DEBUG ("associated (TpBaseChannel *)%p with (TpBaseRoomConfig *)%p",
            priv->channel, self);
        break;

/* We track changed-ness of all the configuration field-flavoured properties in
 * priv->changed_properties. The setters can be mechanically generated: we need
 * the property name in uppercase to build PROP_FOO and TP_BASE_ROOM_CONFIG_FOO,
 * and in lowercase to assign to priv->foo.
 */
#define CASE_BOOL(uppercase, lowercase) \
      case PROP_ ## uppercase: \
      { \
        gboolean lowercase = g_value_get_boolean (value); \
        if (!priv->lowercase != !lowercase) \
          tp_intset_add (priv->changed_properties, \
              TP_BASE_ROOM_CONFIG_ ## uppercase); \
        priv->lowercase = lowercase; \
        break; \
      }
#define CASE_STRING(uppercase, lowercase) \
      case PROP_ ## uppercase: \
      { \
        gchar *lowercase = g_value_dup_string (value); \
        if (tp_strdiff (priv->lowercase, lowercase)) \
          tp_intset_add (priv->changed_properties, \
              TP_BASE_ROOM_CONFIG_ ## uppercase); \
        g_free (priv->lowercase); \
        priv->lowercase = lowercase; \
        break; \
      }
CASE_BOOL (ANONYMOUS, anonymous)
CASE_BOOL (INVITE_ONLY, invite_only)
/* LIMIT is the only non-string or -boolean property, so there's no macro for
 * it. It's interspersed with the others because they're in the same order as
 * in the spec.
 */
      case PROP_LIMIT:
      {
        guint limit = g_value_get_uint (value);

        if (limit != priv->limit)
          tp_intset_add (priv->changed_properties,
              TP_BASE_ROOM_CONFIG_LIMIT);

        priv->limit = limit;
        break;
      }
CASE_BOOL (MODERATED, moderated)
CASE_STRING (TITLE, title);
CASE_STRING (DESCRIPTION, description)
CASE_BOOL (PERSISTENT, persistent)
CASE_BOOL (PRIVATE, private)
CASE_BOOL (PASSWORD_PROTECTED, password_protected)
CASE_STRING (PASSWORD, password)
CASE_STRING (PASSWORD_HINT, password_hint)
#undef CASE_BOOL
#undef CASE_STRING

/* This is not a member of TpBaseRoomConfigProperty, so we track its
 * changed-ness separately.
 */
      case PROP_CAN_UPDATE_CONFIGURATION:
      {
        gboolean can_update_configuration = g_value_get_boolean (value);

        if (!priv->can_update_configuration != !can_update_configuration)
          priv->can_update_configuration_changed = TRUE;

        priv->can_update_configuration = can_update_configuration;
        break;
      }
      default:
        G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}

/* This quark is used to attach a pointer to this object to its parent
 * TpBaseChannel, so we can recover ourself in D-Bus method invocations
 * and property lookups.
 */
static GQuark find_myself_q = 0;

static TpBaseRoomConfig *
find_myself (GObject *parent)
{
  TpBaseRoomConfig *self = g_object_get_qdata (parent, find_myself_q);

  DEBUG ("retrieved %p from channel %p", self, parent);

  g_return_val_if_fail (TP_IS_BASE_CHANNEL (parent), NULL);
  g_return_val_if_fail (self != NULL, NULL);
  g_return_val_if_fail (TP_IS_BASE_ROOM_CONFIG (self), NULL);

  return self;
}

static void
tp_base_room_config_constructed (GObject *object)
{
  TpBaseRoomConfig *self = TP_BASE_ROOM_CONFIG (object);
  TpBaseRoomConfigPrivate *priv = self->priv;
  GObjectClass *parent_class = tp_base_room_config_parent_class;

  if (parent_class->constructed != NULL)
    parent_class->constructed (object);

  g_assert (priv->channel != NULL);
  g_assert (find_myself_q != 0);
  g_object_set_qdata (G_OBJECT (priv->channel), find_myself_q, self);
}

static void
tp_base_room_config_dispose (GObject *object)
{
  TpBaseRoomConfig *self = TP_BASE_ROOM_CONFIG (object);
  GObjectClass *parent_class = tp_base_room_config_parent_class;
  TpBaseRoomConfigPrivate *priv = self->priv;

  if (priv->channel != NULL)
    {
      g_object_set_qdata (G_OBJECT (priv->channel), find_myself_q, NULL);
      g_object_weak_unref (G_OBJECT (priv->channel), channel_died_cb, self);
      priv->channel = NULL;
    }

  if (parent_class->dispose != NULL)
    parent_class->dispose (object);
}

static void
tp_base_room_config_finalize (GObject *object)
{
  TpBaseRoomConfig *self = TP_BASE_ROOM_CONFIG (object);
  GObjectClass *parent_class = tp_base_room_config_parent_class;
  TpBaseRoomConfigPrivate *priv = self->priv;

  g_free (priv->title);
  g_free (priv->description);
  g_free (priv->password);
  g_free (priv->password_hint);
  tp_intset_destroy (priv->mutable_properties);
  tp_intset_destroy (priv->changed_properties);

  if (priv->update_configuration_ctx != NULL)
    {
      CRITICAL ("finalizing (TpBaseRoomConfig *) %p with a pending "
          "UpdateConfiguration() call; this should not be possible",
          object);
    }
  g_warn_if_fail (priv->validated_properties == NULL);

  if (parent_class->finalize != NULL)
    parent_class->finalize (object);
}

static void
tp_base_room_config_class_init (TpBaseRoomConfigClass *klass)
{
  GObjectClass *object_class = G_OBJECT_CLASS (klass);
  GParamSpec *param_spec;

  object_class->get_property = tp_base_room_config_get_property;
  object_class->set_property = tp_base_room_config_set_property;
  object_class->constructed = tp_base_room_config_constructed;
  object_class->dispose = tp_base_room_config_dispose;
  object_class->finalize = tp_base_room_config_finalize;

  g_type_class_add_private (klass, sizeof (TpBaseRoomConfigPrivate));
  find_myself_q = g_quark_from_static_string ("TpBaseRoomConfig pointer");

  klass->update_finish = tp_base_room_config_update_finish;

  param_spec = g_param_spec_object ("channel", "Channel",
      "Parent TpBaseChannel",
      TP_TYPE_BASE_CHANNEL,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CHANNEL, param_spec);

  /* D-Bus properties. */
  param_spec = g_param_spec_boolean ("anonymous", "Anonymous",
      "True if people may join the channel without other members being made "
      "aware of their identity.",
      FALSE,
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ANONYMOUS, param_spec);

  param_spec = g_param_spec_boolean ("invite-only", "InviteOnly",
      "True if people may not join the channel until they have been invited.",
      FALSE,
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_INVITE_ONLY, param_spec);

  param_spec = g_param_spec_uint ("limit", "Limit",
      "The limit to the number of members; or 0 if there is no limit.",
      0, G_MAXUINT32, 0,
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_LIMIT, param_spec);

  param_spec = g_param_spec_boolean ("moderated", "Moderated",
      "True if channel membership is not sufficient to allow participation.",
      FALSE,
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_MODERATED, param_spec);

  param_spec = g_param_spec_string ("title", "Title",
      "A human-visible name for the channel, if it differs from "
      "Room.DRAFT.RoomName; the empty string, otherwise.",
      "",
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_TITLE, param_spec);

  param_spec = g_param_spec_string ("description", "Description",
      "A human-readable description of the channel's overall purpose; if any.",
      "",
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DESCRIPTION, param_spec);

  param_spec = g_param_spec_boolean ("persistent", "Persistent",
      "True if the channel will remain in existence on the server after all "
      "members have left it.",
      FALSE,
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PERSISTENT, param_spec);

  param_spec = g_param_spec_boolean ("private", "Private",
      "True if the channel is not visible to non-members.",
      FALSE,
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PRIVATE, param_spec);

  param_spec = g_param_spec_boolean ("password-protected", "PasswordProtected",
      "True if contacts joining this channel must provide a password to be "
      "granted entry.",
      FALSE,
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PASSWORD_PROTECTED,
      param_spec);

  param_spec = g_param_spec_string ("password", "Password",
      "If PasswordProtected is True, the password required to enter the "
      "channel, if known. If the password is unknown, or PasswordProtected "
      "is False, the empty string.",
      "",
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PASSWORD, param_spec);

  param_spec = g_param_spec_string ("password-hint", "PasswordHint",
      "If PasswordProtected is True, a hint for the password. If the password"
      "password is unknown, or PasswordProtected is False, the empty string.",
      "",
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PASSWORD_HINT, param_spec);

  param_spec = g_param_spec_boolean ("can-update-configuration",
      "CanUpdateConfiguration",
      "If True, the user may call UpdateConfiguration to change the values of "
      "the properties listed in MutableProperties.",
      FALSE,
      G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CAN_UPDATE_CONFIGURATION,
      param_spec);

  param_spec = g_param_spec_boxed ("mutable-properties", "MutableProperties",
      "A list of (unqualified) property names on this interface which may be "
      "modified using UpdateConfiguration (if CanUpdateConfiguration is "
      "True). Properties not listed here cannot be modified.",
      G_TYPE_STRV,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_MUTABLE_PROPERTIES,
      param_spec);

  param_spec = g_param_spec_boolean ("configuration-retrieved",
      "ConfigurationRetrieved",
      "Becomes True once the room config has been fetched from the network",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONFIGURATION_RETRIEVED,
      param_spec);
}

/* room_config_getter:
 *
 * This is basically an indirected version of
 * tp_dbus_properties_mixin_getter_gobject_properties to cope with this GObject
 * not actually being the exported D-Bus object.
 */
static void
room_config_getter (
    GObject *object,
    GQuark iface,
    GQuark name,
    GValue *value,
    gpointer getter_data)
{
  TpBaseRoomConfig *self = find_myself (object);

  g_return_if_fail (self != NULL);

  g_object_get_property ((GObject *) self, getter_data, value);
}

/* The TpBaseRoomConfigProperty enum is used to index into this array: be
 * careful! */
static TpDBusPropertiesMixinPropImpl room_config_properties[] = {
  /* Configuration */
  { "Anonymous", "anonymous", NULL, },
  { "InviteOnly", "invite-only", NULL },
  { "Limit", "limit", NULL },
  { "Moderated", "moderated", NULL },
  { "Title", "title", NULL },
  { "Description", "description", NULL },
  { "Persistent", "persistent", NULL },
  { "Private", "private", NULL },
  { "PasswordProtected", "password-protected", NULL },
  { "Password", "password", NULL },
  { "PasswordHint", "password-hint", NULL },

  /* Meta-data */
  { "CanUpdateConfiguration", "can-update-configuration", NULL },
  { "MutableProperties", "mutable-properties", NULL },
  { "ConfigurationRetrieved", "configuration-retrieved", NULL },

  { NULL }
};

/**
 * tp_base_room_config_register_class:
 * @base_channel_class: the class structure for a subclass of #TpBaseChannel
 *  which uses this object to implement #TP_SVC_CHANNEL_INTERFACE_ROOM_CONFIG
 *
 * Registers that D-Bus properties for the RoomConfig1 interface should be
 * handled by a #TpBaseRoomConfig object associated with instances of
 * @base_channel_class.
 *
 * @base_channel_class must implement #TP_SVC_CHANNEL_INTERFACE_ROOM_CONFIG
 * using tp_base_room_config_iface_init(), and instances of @base_channel_class
 * must construct an instance of #TpBaseRoomConfig, passing themself as
 * #TpBaseRoomConfig:channel.
 */
void
tp_base_room_config_register_class (
    TpBaseChannelClass *base_channel_class)
{
  GObjectClass *cls = G_OBJECT_CLASS (base_channel_class);

  tp_dbus_properties_mixin_implement_interface (cls,
      TP_IFACE_QUARK_CHANNEL_INTERFACE_ROOM_CONFIG,
      room_config_getter, NULL, room_config_properties);
}

/* This is almost copy-pasta from _tp_dbus_properties_mixin_find_prop_impl,
 * except this operates on the IfaceInfo structure…
 */
static TpDBusPropertiesMixinPropInfo *
find_prop_info (
    TpDBusPropertiesMixinIfaceInfo *iface_info,
    const gchar *property_name)
{
  GQuark prop_quark = g_quark_try_string (property_name);
  TpDBusPropertiesMixinPropInfo *prop_info;

  if (prop_quark == 0)
    return NULL;

  for (prop_info = iface_info->props;
       prop_info->name != 0;
       prop_info++)
    {
      if (prop_info->name == prop_quark)
        return prop_info;
    }

  return NULL;
}

static gboolean
validate_property_type (
    const gchar *property_name,
    const GValue *value,
    GError **error)
{
  static TpDBusPropertiesMixinIfaceInfo *iface_info = NULL;
  TpDBusPropertiesMixinPropInfo *prop_info;

  if (G_UNLIKELY (iface_info == NULL))
    iface_info = tp_svc_interface_get_dbus_properties_info (
          TP_TYPE_SVC_CHANNEL_INTERFACE_ROOM_CONFIG);

  g_return_val_if_fail (iface_info != NULL, FALSE);

  /* If we recognise the property name, but it's not registered with
   * TpDBusPropertiesMixin, then something is really screw-y.
   */
  prop_info = find_prop_info (iface_info, property_name);
  g_return_val_if_fail (prop_info != NULL, FALSE);

  /* TODO: transform types just like TpDBusPropertiesMixin does. We only
   * have one property that isn't a boolean or a string, so this is not a
   * pressing concern, and it would be nice to be able to reuse more of
   * TpDBusPropertiesMixin's validation code.
   */
  if (!G_VALUE_HOLDS (value, prop_info->type))
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "'%s' has type '%s', not '%s'", property_name,
          prop_info->dbus_signature, G_VALUE_TYPE_NAME (value));
      return FALSE;
    }

  return TRUE;
}

static gboolean
validate_property (
    TpBaseRoomConfig *self,
    GHashTable *validated_properties,
    const gchar *property_name,
    GValue *value,
    GError **error)
{
  TpBaseRoomConfigPrivate *priv = self->priv;
  gint property_id;

  if (!_tp_enum_from_nick (TP_TYPE_BASE_ROOM_CONFIG_PROPERTY,
          property_name, &property_id))
    {
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "'%s' is not a known RoomConfig property.", property_name);
      return FALSE;
    }

  if (!tp_intset_is_member (priv->mutable_properties, property_id))
    {
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
          "'%s' cannot be changed on this protocol", property_name);
      return FALSE;
    }

  if (!validate_property_type (property_name, value, error))
    return FALSE;

  g_hash_table_insert (validated_properties,
      GUINT_TO_POINTER (property_id), tp_g_value_slice_dup (value));
  return TRUE;
}

/*
 * validate_properties:
 * @self: it's me!
 * @properties: a mapping from unqualified property names (gchar *) to
 *              corresponding new values (GValue *).
 * @error: set to a TP_ERROR if validation fails.
 *
 * Validates the names and types and mutability of @properties.
 *
 * Returns: a mapping from TpBaseRoomConfigProperty elements to corresponding
 *          new values (GValue *).
 */
static GHashTable *
validate_properties (
    TpBaseRoomConfig *self,
    GHashTable *properties,
    GError **error)
{
  GHashTable *validated_properties = g_hash_table_new_full (
      NULL, NULL, NULL, (GDestroyNotify) tp_g_value_slice_free);
  GHashTableIter iter;
  gpointer k, v;

  g_hash_table_iter_init (&iter, properties);
  while (g_hash_table_iter_next (&iter, &k, &v))
    {
      if (!validate_property (self, validated_properties, k, v, error))
        {
          g_hash_table_unref (validated_properties);
          return NULL;
        }
    }

  return validated_properties;
}

static void
update_cb (
    GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpBaseRoomConfig *self = TP_BASE_ROOM_CONFIG (source);
  TpBaseRoomConfigPrivate *priv = self->priv;
  GError *error = NULL;

  g_return_if_fail (priv->update_configuration_ctx != NULL);
  g_return_if_fail (priv->validated_properties != NULL);
  /* We took a ref to the channel before calling out to application code; it
   * shouldn't have died in the meantime.
   */
  g_return_if_fail (priv->channel != NULL);

  if (TP_BASE_ROOM_CONFIG_GET_CLASS (self)->update_finish (
        self, result, &error))
    {
      GHashTableIter iter;
      gpointer k, v;

      g_hash_table_iter_init (&iter, priv->validated_properties);
      while (g_hash_table_iter_next (&iter, &k, &v))
        {
          TpBaseRoomConfigProperty property_id = GPOINTER_TO_UINT (k);
          GValue *value = v;
          const gchar *g_property_name;

          g_assert_cmpuint (property_id, <, TP_NUM_BASE_ROOM_CONFIG_PROPERTIES);
          g_property_name = room_config_properties[property_id].getter_data;
          g_assert_cmpstr (NULL, !=, g_property_name);

          g_object_set_property ((GObject *) self, g_property_name, value);
        }

      tp_base_room_config_emit_properties_changed (self);
      tp_svc_channel_interface_room_config_return_from_update_configuration (
          priv->update_configuration_ctx);
    }
  else
    {
      dbus_g_method_return_error (priv->update_configuration_ctx, error);
      g_clear_error (&error);
    }

  priv->update_configuration_ctx = NULL;
  tp_clear_pointer (&priv->validated_properties, g_hash_table_unref);
  g_object_unref (priv->channel);
}

static gboolean
tp_base_room_config_update_finish (
    TpBaseRoomConfig *self,
    GAsyncResult *result,
    GError **error)
{
  gpointer source_tag = TP_BASE_ROOM_CONFIG_GET_CLASS (self)->update_async;

  _tp_implement_finish_void (self, source_tag);
}

static void
tp_base_room_config_update_configuration (
    TpSvcChannelInterfaceRoomConfig *iface,
    GHashTable *properties,
    DBusGMethodInvocation *context)
{
  TpBaseRoomConfig *self = find_myself ((GObject *) iface);
  TpBaseChannel *channel = TP_BASE_CHANNEL (iface);
  TpBaseRoomConfigPrivate *priv;
  TpBaseRoomConfigUpdateAsync update_async;
  GError *error = NULL;

  if (self == NULL)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_CONFUSED,
          "Internal error: couldn't find TpBaseRoomConfig object "
          "attached to (TpBaseChannel *) %p at %s",
          iface,
          tp_base_channel_get_object_path (channel));

      CRITICAL ("%s", error->message);
      goto err;
    }

  priv = self->priv;
  update_async = TP_BASE_ROOM_CONFIG_GET_CLASS (self)->update_async;

  if (update_async == NULL)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
          "This protocol does not implement updating the room configuration");
      goto err;
    }

  if (priv->update_configuration_ctx != NULL)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "Another UpdateConfiguration() call is still in progress");
      goto err;
    }

  /* If update_configuration_ctx == NULL, then validated_properties should be,
   * too.
   */
  g_warn_if_fail (priv->validated_properties == NULL);

  if (!priv->can_update_configuration)
    {
      g_set_error (&error, TP_ERROR, TP_ERROR_PERMISSION_DENIED,
          "The user doesn't have permission to modify this room's "
          "configuration (maybe they're not an op/admin/owner?)");
      goto err;
    }

  if (g_hash_table_size (properties) == 0)
    {
      tp_svc_channel_interface_room_config_return_from_update_configuration (
          context);
      return;
    }

  priv->validated_properties = validate_properties (self, properties, &error);

  if (priv->validated_properties == NULL)
    goto err;

  priv->update_configuration_ctx = context;
  /* We ensure our channel stays alive for the duration of the call. This is
   * mainly as a convenience to the subclass, which would probably like
   * tp_base_room_config_get_channel() to work reliably.
   *
   * If the DBusGMethodInvocation kept the object alive, we wouldn't need this.
   */
  g_object_ref (priv->channel);
  /* This means the CM could modify validated_properties if it wanted. This is
   * good in some ways: it means it can further sanitize the values if it
   * wants, for instance. But I guess it's also possible for the CM to mess up.
   */
  update_async (self, priv->validated_properties, update_cb, NULL);
  return;

err:
  dbus_g_method_return_error (context, error);
  g_clear_error (&error);
}

/**
 * tp_base_room_config_iface_init:
 * @g_iface: a pointer to a #TpSvcChannelInterfaceRoomConfigClass structure
 * @iface_data: ignored
 *
 * Pass this as the second argument to G_IMPLEMENT_INTERFACE() when defining a
 * #TpBaseChannel subclass to declare that TP_SVC_CHANNEL_INTERFACE_ROOM_CONFIG
 * is implemented using this class. The #TpBaseChannel subclass must also call
 * tp_base_room_config_register_class() in its class_init function, and
 * construct a #TpBaseRoomConfig object for each instance.
 */
void
tp_base_room_config_iface_init (
    gpointer g_iface,
    gpointer iface_data)
{
#define IMPLEMENT(x) tp_svc_channel_interface_room_config_implement_##x (\
    g_iface, tp_base_room_config_##x)
  IMPLEMENT (update_configuration);
#undef IMPLEMENT
}

/**
 * tp_base_room_config_dup_channel:
 * @self: a #TpBaseChannel
 *
 * Returns the channel to which @self is attached.
 *
 * Returns: (transfer full): the #TpBaseRoomConfig:channel property.
 */
TpBaseChannel *
tp_base_room_config_dup_channel (
    TpBaseRoomConfig *self)
{
  g_return_val_if_fail (TP_IS_BASE_ROOM_CONFIG (self), NULL);
  g_return_val_if_fail (self->priv->channel != NULL, NULL);

  return g_object_ref (self->priv->channel);
}

/**
 * tp_base_room_config_set_can_update_configuration:
 * @self: a #TpBaseRoomConfig object.
 * @can_update_configuration: %TRUE if the local user has permission to modify
 *  properties marked as mutable.
 *
 * Specify whether or not the local user currently has permission to modify the
 * room configuration.
 *
 * Changes made by calling this function are not signalled over D-Bus until
 * tp_base_room_config_emit_properties_changed() is next called.
 */
void
tp_base_room_config_set_can_update_configuration (
    TpBaseRoomConfig *self,
    gboolean can_update_configuration)
{
  g_return_if_fail (TP_IS_BASE_ROOM_CONFIG (self));

  g_object_set (self,
      "can-update-configuration", can_update_configuration,
      NULL);
}

/**
 * tp_base_room_config_set_property_mutable:
 * @self: a #TpBaseRoomConfig object.
 * @property_id: a property identifier (not including
 *  %TP_NUM_BASE_ROOM_CONFIG_PROPERTIES)
 * @is_mutable: %TRUE if it is possible for Telepathy clients to modify
 *  @property_id when #TpBaseRoomConfig:can-update-configuration is %TRUE.
 *
 * Specify whether it is possible for room members to modify the value of
 * @property_id (possibly dependent on them having channel-operator powers), or
 * whether @property_id's value is an intrinsic fact about the protocol.
 *
 * For example, on IRC it is impossible to configure a channel to hide the
 * identities of participants from others, so %TP_BASE_ROOM_CONFIG_ANONYMOUS
 * should be marked as immutable on IRC; whereas channel operators can mark
 * rooms as invite-only, so %TP_BASE_ROOM_CONFIG_INVITE_ONLY should be marked as
 * mutable on IRC.
 *
 * By default, all properties are considered immutable.
 *
 * Call tp_base_room_config_set_can_update_configuration() to specify whether or
 * not it is currently possible for the local user to alter properties marked
 * as mutable.
 *
 * Changes made by calling this function are not signalled over D-Bus until
 * tp_base_room_config_emit_properties_changed() is next called.
 */
void
tp_base_room_config_set_property_mutable (
    TpBaseRoomConfig *self,
    TpBaseRoomConfigProperty property_id,
    gboolean is_mutable)
{
  TpBaseRoomConfigPrivate *priv = self->priv;
  gboolean changed = FALSE;

  g_return_if_fail (TP_IS_BASE_ROOM_CONFIG (self));
  g_return_if_fail (property_id < TP_NUM_BASE_ROOM_CONFIG_PROPERTIES);

  /* Grr. Damn _add and _remove functions for being asymmetrical. */
  if (!is_mutable)
    {
      changed = tp_intset_remove (priv->mutable_properties, property_id);
    }
  else if (!tp_intset_is_member (priv->mutable_properties, property_id))
    {
      tp_intset_add (priv->mutable_properties, property_id);
      changed = TRUE;
    }

  if (changed)
    {
      g_object_notify ((GObject *) self, "mutable-properties");
      priv->mutable_properties_changed = TRUE;
   }
}

/**
 * tp_base_room_config_emit_properties_changed:
 * @self: a #TpBaseRoomConfig object.
 *
 * Signal the new values of properties which have been modified since the last
 * call to this method, if any. This includes changes made by calling
 * tp_base_room_config_set_can_update_configuration() and
 * tp_base_room_config_set_property_mutable(), as well as changes to any of the
 * (writeable) GObject properties on this object.
 */
void
tp_base_room_config_emit_properties_changed (
    TpBaseRoomConfig *self)
{
  TpBaseRoomConfigPrivate *priv;

  g_return_if_fail (TP_IS_BASE_ROOM_CONFIG (self));
  priv = self->priv;

  if (priv->channel == NULL)
    {
      CRITICAL ("the channel associated with (TpBaseRoomConfig *)%p has died",
          self);
      g_return_if_reached ();
    }
  else
    {
      GPtrArray *changed = g_ptr_array_new ();

      add_properties_from_intset (changed, priv->changed_properties);
      tp_intset_clear (priv->changed_properties);

      if (priv->mutable_properties_changed)
        {
          g_ptr_array_add (changed, "MutableProperties");
          priv->mutable_properties_changed = FALSE;
        }

      if (priv->can_update_configuration_changed)
        {
          g_ptr_array_add (changed, "CanUpdateConfiguration");
          priv->can_update_configuration_changed = FALSE;
        }

      if (changed->len > 0)
        {
          g_ptr_array_add (changed, NULL);
          DEBUG ("emitting PropertiesChanged for %s",
              g_strjoinv (", ", (gchar **) changed->pdata));
          tp_dbus_properties_mixin_emit_properties_changed (
              G_OBJECT (priv->channel),
              TP_IFACE_CHANNEL_INTERFACE_ROOM_CONFIG,
              (const gchar * const *) changed->pdata);
        }

      g_ptr_array_unref (changed);
    }
}

/**
 * tp_base_room_config_set_retrieved:
 * @self: a #TpBaseRoomConfig object
 *
 * Signal that the room's configuration has been retrieved, as well as
 * signalling any queued property changes. This function should be called once
 * all properties have been set to meaningful values.
 *
 * It is safe to call this function more than once; second and subsequent calls
 * are equivalent to calling tp_base_room_config_emit_properties_changed().
 */
void
tp_base_room_config_set_retrieved (
    TpBaseRoomConfig *self)
{
  TpBaseRoomConfigPrivate *priv;

  g_return_if_fail (TP_IS_BASE_ROOM_CONFIG (self));
  priv = self->priv;

  if (priv->channel == NULL)
    {
      CRITICAL ("the channel associated with (TpBaseRoomConfig *)%p has died",
          self);
      g_return_if_reached ();
    }

  /* Flush any pending property changes */
  tp_base_room_config_emit_properties_changed (self);

  if (!priv->configuration_retrieved)
    {
      priv->configuration_retrieved = TRUE;
      tp_dbus_properties_mixin_emit_properties_changed_varargs (
          G_OBJECT (priv->channel),
          TP_IFACE_CHANNEL_INTERFACE_ROOM_CONFIG,
          "ConfigurationRetrieved", NULL);
    }
}
