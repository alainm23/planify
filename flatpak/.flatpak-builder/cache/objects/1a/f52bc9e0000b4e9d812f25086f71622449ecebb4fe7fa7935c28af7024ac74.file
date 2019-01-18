/*
 * A factory for TpContacts and plain subclasses of TpProxy
 *
 * Copyright © 2011 Collabora Ltd.
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
 * SECTION:simple-client-factory
 * @title: TpSimpleClientFactory
 * @short_description: a factory for #TpContact<!-- -->s and plain subclasses
 *  of #TpProxy
 * @see_also: #TpAutomaticClientFactory
 *
 * This factory constructs various #TpProxy subclasses as well as #TpContact,
 * which guarantees that at most one instance of those objects will exist for a
 * given remote object or contact. It also stores the desired features for
 * contacts and each type of proxy.
 *
 * Note that the factory will not prepare the desired features: it is the
 * caller's responsibility to do so. By default, only core features are
 * requested.
 *
 * Currently supported classes are #TpAccount, #TpConnection,
 * #TpChannel and #TpContact. Those objects should always be acquired through a
 * factory or a "larger" object (e.g. getting the #TpConnection from
 * a #TpAccount), rather than being constructed directly.
 *
 * One can subclass #TpSimpleClientFactory and override some of its virtual
 * methods to construct more specialized objects. See #TpAutomaticClientFactory
 * for a subclass which automatically constructs subclasses of #TpChannel for
 * common channel types.
 *
 * An application using its own factory subclass would look like this:
 * |[
 * int main(int argc, char *argv[])
 * {
 *   TpSimpleClientFactory *factory;
 *   TpAccountManager *manager;
 *
 *   factory = my_factory_new ();
 *   manager = tp_account_manager_new_with_factory (factory);
 *   tp_account_manager_set_default (manager);
 *
 *   ...
 *   tp_proxy_prepare_async (manager, am_features, callback, user_data);
 *   ...
 * }
 * ]|
 *
 * The call to tp_account_manager_set_default() near the beginning of main()
 * will ensure that any libraries or plugins which also use Telepathy (and call
 * tp_account_manager_dup()) will share your #TpAccountManager.
 *
 * Since: 0.15.5
 */

/**
 * TpSimpleClientFactory:
 *
 * Data structure representing a #TpSimpleClientFactory
 *
 * Since: 0.15.5
 */

/**
 * TpSimpleClientFactoryClass:
 * @parent_class: the parent
 * @create_account: create a #TpAccount;
 *  see tp_simple_client_factory_ensure_account()
 * @dup_account_features: implementation of tp_simple_client_factory_dup_account_features()
 * @create_connection: create a #TpConnection;
 *  see tp_simple_client_factory_ensure_connection()
 * @dup_connection_features: implementation of
 *  tp_simple_client_factory_dup_connection_features()
 * @create_channel: create a #TpChannel;
 *  see tp_simple_client_factory_ensure_channel()
 * @dup_channel_features: implementation of tp_simple_client_factory_dup_channel_features()
 * @create_contact: create a #TpContact;
 *  see tp_simple_client_factory_ensure_contact()
 * @dup_contact_features: implementation of tp_simple_client_factory_dup_contact_features()
 *
 * The class structure for #TpSimpleClientFactory.
 *
 * #TpSimpleClientFactory maintains a cache of previously-constructed proxy
 * objects, so the implementations of @create_account,
 * @create_connection, @create_channel, and @create_contact may assume that a
 * new object should be created when they are called. The default
 * implementations create unadorned instances of the relevant classes;
 * subclasses of the factory may choose to create more interesting proxy
 * subclasses.
 *
 * The default implementation of @dup_channel_features returns
 * #TP_CHANNEL_FEATURE_CORE, plus all features passed to
 * tp_simple_client_factory_add_channel_features() by the application.
 * Subclasses may override this method to prepare more interesting features
 * from subclasses of #TpChannel, for instance. The default implementations of
 * the other <function>dup_x_features</function> methods behave similarly.
 *
 * Since: 0.15.5
 */

#include "config.h"

#include "telepathy-glib/simple-client-factory.h"

#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CLIENT
#include "telepathy-glib/connection-internal.h"
#include "telepathy-glib/contact-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/simple-client-factory-internal.h"
#include "telepathy-glib/util-internal.h"

struct _TpSimpleClientFactoryPrivate
{
  TpDBusDaemon *dbus;
  /* Owned object-path -> weakref to TpProxy */
  GHashTable *proxy_cache;
  GArray *desired_account_features;
  GArray *desired_connection_features;
  GArray *desired_channel_features;
  GArray *desired_contact_features;
};

enum
{
  PROP_DBUS_DAEMON = 1,
  N_PROPS
};

G_DEFINE_TYPE (TpSimpleClientFactory, tp_simple_client_factory, G_TYPE_OBJECT)

static void
proxy_invalidated_cb (TpProxy *proxy,
    guint domain,
    gint code,
    gchar *message,
    TpSimpleClientFactory *self)
{
  g_hash_table_remove (self->priv->proxy_cache,
      tp_proxy_get_object_path (proxy));
}

static void
insert_proxy (TpSimpleClientFactory *self,
    gpointer proxy)
{
  if (proxy == NULL)
    return;

  g_hash_table_insert (self->priv->proxy_cache,
      (gpointer) tp_proxy_get_object_path (proxy), proxy);

  /* This assume that invalidated signal is emitted from TpProxy dispose. May
   * change in a future API break? */
  tp_g_signal_connect_object (proxy, "invalidated",
      G_CALLBACK (proxy_invalidated_cb), self, 0);
}

static gpointer
lookup_proxy (TpSimpleClientFactory *self,
    const gchar *object_path)
{
  return g_hash_table_lookup (self->priv->proxy_cache, object_path);
}

void
_tp_simple_client_factory_insert_proxy (TpSimpleClientFactory *self,
    gpointer proxy)
{
  g_return_if_fail (lookup_proxy (self,
      tp_proxy_get_object_path (proxy)) == NULL);

  insert_proxy (self, proxy);
}

static TpAccount *
create_account_impl (TpSimpleClientFactory *self,
    const gchar *object_path,
    const GHashTable *immutable_properties G_GNUC_UNUSED,
    GError **error)
{
  return _tp_account_new_with_factory (self, self->priv->dbus, object_path,
      error);
}

static GArray *
dup_account_features_impl (TpSimpleClientFactory *self,
    TpAccount *account)
{
  return _tp_quark_array_copy (
      (GQuark *) self->priv->desired_account_features->data);
}

static TpConnection *
create_connection_impl (TpSimpleClientFactory *self,
    const gchar *object_path,
    const GHashTable *immutable_properties G_GNUC_UNUSED,
    GError **error)
{
  return _tp_connection_new_with_factory (self, self->priv->dbus, NULL,
      object_path, error);
}

static GArray *
dup_connection_features_impl (TpSimpleClientFactory *self,
    TpConnection *connection)
{
  return _tp_quark_array_copy (
      (GQuark *) self->priv->desired_connection_features->data);
}

static TpChannel *
create_channel_impl (TpSimpleClientFactory *self,
    TpConnection *conn,
    const gchar *object_path,
    const GHashTable *immutable_properties,
    GError **error)
{
  return _tp_channel_new_with_factory (self, conn, object_path,
      immutable_properties, error);
}

static GArray *
dup_channel_features_impl (TpSimpleClientFactory *self,
    TpChannel *channel)
{
  return _tp_quark_array_copy (
      (GQuark *) self->priv->desired_channel_features->data);
}

static TpContact *
create_contact_impl (TpSimpleClientFactory *self,
    TpConnection *connection,
    TpHandle handle,
    const gchar *identifier)
{
  return _tp_contact_new (connection, handle, identifier);
}

static GArray *
dup_contact_features_impl (TpSimpleClientFactory *self,
    TpConnection *connection)
{
  GArray *array;

  array = g_array_sized_new (FALSE, FALSE, sizeof (TpContactFeature),
      self->priv->desired_contact_features->len);
  g_array_append_vals (array, self->priv->desired_contact_features->data,
      self->priv->desired_contact_features->len);

  return array;
}

static void
tp_simple_client_factory_get_property (GObject *object,
    guint property_id,
    GValue *value,
    GParamSpec *pspec)
{
  TpSimpleClientFactory *self = (TpSimpleClientFactory *) object;

  switch (property_id)
    {
    case PROP_DBUS_DAEMON:
      g_value_set_object (value, self->priv->dbus);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}

static void
tp_simple_client_factory_set_property (GObject *object,
    guint property_id,
    const GValue *value,
    GParamSpec *pspec)
{
  TpSimpleClientFactory *self = (TpSimpleClientFactory *) object;

  switch (property_id)
    {
    case PROP_DBUS_DAEMON:
      g_assert (self->priv->dbus == NULL); /* construct only */
      self->priv->dbus = g_value_dup_object (value);
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}

static void
tp_simple_client_factory_constructed (GObject *object)
{
  TpSimpleClientFactory *self = (TpSimpleClientFactory *) object;

  if (self->priv->dbus == NULL)
    self->priv->dbus = tp_dbus_daemon_dup (NULL);

  G_OBJECT_CLASS (tp_simple_client_factory_parent_class)->constructed (object);
}

static void
tp_simple_client_factory_finalize (GObject *object)
{
  TpSimpleClientFactory *self = (TpSimpleClientFactory *) object;

  g_clear_object (&self->priv->dbus);
  tp_clear_pointer (&self->priv->proxy_cache, g_hash_table_unref);
  tp_clear_pointer (&self->priv->desired_account_features, g_array_unref);
  tp_clear_pointer (&self->priv->desired_connection_features, g_array_unref);
  tp_clear_pointer (&self->priv->desired_channel_features, g_array_unref);
  tp_clear_pointer (&self->priv->desired_contact_features, g_array_unref);

  G_OBJECT_CLASS (tp_simple_client_factory_parent_class)->finalize (object);
}

static void
tp_simple_client_factory_init (TpSimpleClientFactory *self)
{
  GQuark feature;

  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_SIMPLE_CLIENT_FACTORY,
      TpSimpleClientFactoryPrivate);

  self->priv->proxy_cache = g_hash_table_new (g_str_hash, g_str_equal);

  self->priv->desired_account_features = g_array_new (TRUE, FALSE,
      sizeof (GQuark));
  feature = TP_ACCOUNT_FEATURE_CORE;
  g_array_append_val (self->priv->desired_account_features, feature);

  self->priv->desired_connection_features = g_array_new (TRUE, FALSE,
      sizeof (GQuark));
  feature = TP_CONNECTION_FEATURE_CORE;
  g_array_append_val (self->priv->desired_connection_features, feature);

  self->priv->desired_channel_features = g_array_new (TRUE, FALSE,
      sizeof (GQuark));
  feature = TP_CHANNEL_FEATURE_CORE;
  g_array_append_val (self->priv->desired_channel_features, feature);

  self->priv->desired_contact_features = g_array_new (FALSE, FALSE,
      sizeof (TpContactFeature));
}

static void
tp_simple_client_factory_class_init (TpSimpleClientFactoryClass *klass)
{
  GObjectClass *object_class = (GObjectClass *) klass;
  GParamSpec *param_spec;

  g_type_class_add_private (klass, sizeof (TpSimpleClientFactoryPrivate));

  object_class->get_property = tp_simple_client_factory_get_property;
  object_class->set_property = tp_simple_client_factory_set_property;
  object_class->constructed = tp_simple_client_factory_constructed;
  object_class->finalize = tp_simple_client_factory_finalize;

  klass->create_account = create_account_impl;
  klass->dup_account_features = dup_account_features_impl;
  klass->create_connection = create_connection_impl;
  klass->dup_connection_features = dup_connection_features_impl;
  klass->create_channel = create_channel_impl;
  klass->dup_channel_features = dup_channel_features_impl;
  klass->create_contact = create_contact_impl;
  klass->dup_contact_features = dup_contact_features_impl;

  /**
   * TpSimpleClientFactory:dbus-daemon:
   *
   * The D-Bus daemon for this object.
   */
  param_spec = g_param_spec_object ("dbus-daemon", "D-Bus daemon",
      "The D-Bus daemon used by this object",
      TP_TYPE_DBUS_DAEMON,
      G_PARAM_CONSTRUCT_ONLY | G_PARAM_READWRITE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_DBUS_DAEMON,
      param_spec);
}

/**
 * tp_simple_client_factory_new:
 * @dbus: (allow-none): a #TpDBusDaemon, or %NULL
 *
 * Creates a new #TpSimpleClientFactory instance. If @dbus is %NULL,
 * tp_dbus_daemon_dup() will be used.
 *
 * Returns: a new #TpSimpleClientFactory
 *
 * Since: 0.15.5
 */
TpSimpleClientFactory *
tp_simple_client_factory_new (TpDBusDaemon *dbus)
{
  return g_object_new (TP_TYPE_SIMPLE_CLIENT_FACTORY,
      "dbus-daemon", dbus,
      NULL);
}

/**
 * tp_simple_client_factory_get_dbus_daemon:
 * @self: a #TpSimpleClientFactory object
 *
 * <!-- -->
 *
 * Returns: (transfer none): the value of the #TpSimpleClientFactory:dbus-daemon
 *  property
 *
 * Since: 0.15.5
 */
TpDBusDaemon *
tp_simple_client_factory_get_dbus_daemon (TpSimpleClientFactory *self)
{
  g_return_val_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self), NULL);

  return self->priv->dbus;
}

/**
 * tp_simple_client_factory_ensure_account:
 * @self: a #TpSimpleClientFactory object
 * @object_path: the object path of an account
 * @immutable_properties: (transfer none) (element-type utf8 GObject.Value):
 *  the immutable properties of the account, or %NULL.
 * @error: Used to raise an error if @object_path is not valid
 *
 * Returns a #TpAccount proxy for the account at @object_path. The returned
 * #TpAccount is cached; the same #TpAccount object will be returned by this
 * function repeatedly, as long as at least one reference exists.
 *
 * Note that the returned #TpAccount is not guaranteed to be ready; the caller
 * is responsible for calling tp_proxy_prepare_async() with the desired
 * features (as given by tp_simple_client_factory_dup_account_features()).
 *
 * This function is rather low-level. tp_account_manager_dup_valid_accounts()
 * and #TpAccountManager::validity-changed are more appropriate for most
 * applications.
 *
 * Returns: (transfer full): a reference to a #TpAccount;
 *  see tp_account_new().
 *
 * Since: 0.15.5
 */
TpAccount *
tp_simple_client_factory_ensure_account (TpSimpleClientFactory *self,
    const gchar *object_path,
    const GHashTable *immutable_properties,
    GError **error)
{
  TpAccount *account;

  g_return_val_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self), NULL);
  g_return_val_if_fail (g_variant_is_object_path (object_path), NULL);

  account = lookup_proxy (self, object_path);
  if (account != NULL)
    return g_object_ref (account);

  account = TP_SIMPLE_CLIENT_FACTORY_GET_CLASS (self)->create_account (self,
      object_path, immutable_properties, error);
  insert_proxy (self, account);

  return account;
}

/**
 * tp_simple_client_factory_dup_account_features:
 * @self: a #TpSimpleClientFactory object
 * @account: a #TpAccount
 *
 * Return a zero-terminated #GArray containing the #TpAccount features that
 * should be prepared on @account.
 *
 * Returns: (transfer full) (element-type GLib.Quark): a newly allocated
 *  #GArray
 *
 * Since: 0.15.5
 */
GArray *
tp_simple_client_factory_dup_account_features (TpSimpleClientFactory *self,
    TpAccount *account)
{
  g_return_val_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self), NULL);
  g_return_val_if_fail (TP_IS_ACCOUNT (account), NULL);
  g_return_val_if_fail (tp_proxy_get_factory (account) == self, NULL);

  return TP_SIMPLE_CLIENT_FACTORY_GET_CLASS (self)->dup_account_features (self,
      account);
}

/**
 * tp_simple_client_factory_add_account_features:
 * @self: a #TpSimpleClientFactory object
 * @features: (transfer none) (array zero-terminated=1) (allow-none): an array
 *  of desired features, ending with 0; %NULL is equivalent to an array
 *  containing only 0
 *
 * Add @features to the desired features to be prepared on #TpAccount
 * objects. Those features will be added to the features already returned be
 * tp_simple_client_factory_dup_account_features().
 *
 * It is not necessary to add %TP_ACCOUNT_FEATURE_CORE as it is already
 * included by default.
 *
 * Note that these features will not be added to existing #TpAccount
 * objects; the user must call tp_proxy_prepare_async() themself.
 *
 * Since: 0.15.5
 */
void
tp_simple_client_factory_add_account_features (
    TpSimpleClientFactory *self,
    const GQuark *features)
{
  g_return_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self));

  _tp_quark_array_merge (self->priv->desired_account_features, features, -1);
}

/**
 * tp_simple_client_factory_add_account_features_varargs: (skip)
 * @self: a #TpSimpleClientFactory
 * @feature: the first feature
 * @...: the second and subsequent features, if any, ending with 0
 *
 * The same as tp_simple_client_factory_add_account_features(), but with a more
 * convenient calling convention from C.
 *
 * Since: 0.15.5
 */
void
tp_simple_client_factory_add_account_features_varargs (
    TpSimpleClientFactory *self,
    GQuark feature,
    ...)
{
  va_list var_args;

  g_return_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self));

  va_start (var_args, feature);
  _tp_quark_array_merge_valist (self->priv->desired_account_features, feature,
      var_args);
  va_end (var_args);
}

/**
 * tp_simple_client_factory_ensure_connection:
 * @self: a #TpSimpleClientFactory object
 * @object_path: the object path of a connection
 * @immutable_properties: (transfer none) (element-type utf8 GObject.Value):
 *  the immutable properties of the connection.
 * @error: Used to raise an error if @object_path is not valid
 *
 * Returns a #TpConnection proxy for the connection at @object_path.
 * The returned #TpConnection is cached; the same #TpConnection object
 * will be returned by this function repeatedly, as long as at least one
 * reference exists.
 *
 * Note that the returned #TpConnection is not guaranteed to be ready; the
 * caller is responsible for calling tp_proxy_prepare_async() with the desired
 * features (as given by tp_simple_client_factory_dup_connection_features()).
 *
 * This function is rather low-level. #TpAccount:connection is more
 * appropriate for most applications.
 *
 * Returns: (transfer full): a reference to a #TpConnection;
 *  see tp_connection_new().
 *
 * Since: 0.15.5
 */
TpConnection *
tp_simple_client_factory_ensure_connection (TpSimpleClientFactory *self,
    const gchar *object_path,
    const GHashTable *immutable_properties,
    GError **error)
{
  TpConnection *connection;

  g_return_val_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self), NULL);
  g_return_val_if_fail (g_variant_is_object_path (object_path), NULL);

  connection = lookup_proxy (self, object_path);
  if (connection != NULL)
    return g_object_ref (connection);

  connection = TP_SIMPLE_CLIENT_FACTORY_GET_CLASS (self)->create_connection (
      self, object_path, immutable_properties, error);
  insert_proxy (self, connection);

  return connection;
}

/**
 * tp_simple_client_factory_dup_connection_features:
 * @self: a #TpSimpleClientFactory object
 * @connection: a #TpConnection
 *
 * Return a zero-terminated #GArray containing the #TpConnection features that
 * should be prepared on @connection.
 *
 * Returns: (transfer full) (element-type GLib.Quark): a newly allocated
 *  #GArray
 *
 * Since: 0.15.5
 */
GArray *
tp_simple_client_factory_dup_connection_features (TpSimpleClientFactory *self,
    TpConnection *connection)
{
  g_return_val_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self), NULL);
  g_return_val_if_fail (TP_IS_CONNECTION (connection), NULL);
  g_return_val_if_fail (tp_proxy_get_factory (connection) == self, NULL);

  return TP_SIMPLE_CLIENT_FACTORY_GET_CLASS (self)->dup_connection_features (
      self, connection);
}

/**
 * tp_simple_client_factory_add_connection_features:
 * @self: a #TpSimpleClientFactory object
 * @features: (transfer none) (array zero-terminated=1) (allow-none): an array
 *  of desired features, ending with 0; %NULL is equivalent to an array
 *  containing only 0
 *
 * Add @features to the desired features to be prepared on #TpConnection
 * objects. Those features will be added to the features already returned be
 * tp_simple_client_factory_dup_connection_features().
 *
 * It is not necessary to add %TP_CONNECTION_FEATURE_CORE as it is already
 * included by default.
 *
 * Note that these features will not be added to existing #TpConnection
 * objects; the user must call tp_proxy_prepare_async() themself.
 *
 * Since: 0.15.5
 */
void
tp_simple_client_factory_add_connection_features (
    TpSimpleClientFactory *self,
    const GQuark *features)
{
  g_return_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self));

  _tp_quark_array_merge (self->priv->desired_connection_features, features, -1);
}

/**
 * tp_simple_client_factory_add_connection_features_varargs: (skip)
 * @self: a #TpSimpleClientFactory
 * @feature: the first feature
 * @...: the second and subsequent features, if any, ending with 0
 *
 * The same as tp_simple_client_factory_add_connection_features(), but with a
 * more convenient calling convention from C.
 *
 * Since: 0.15.5
 */
void
tp_simple_client_factory_add_connection_features_varargs (
    TpSimpleClientFactory *self,
    GQuark feature,
    ...)
{
  va_list var_args;

  g_return_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self));

  va_start (var_args, feature);
  _tp_quark_array_merge_valist (self->priv->desired_connection_features,
      feature, var_args);
  va_end (var_args);
}

/**
 * tp_simple_client_factory_ensure_channel:
 * @self: a #TpSimpleClientFactory object
 * @connection: a #TpConnection whose #TpProxy:factory is this object
 * @object_path: the object path of a channel on @connection
 * @immutable_properties: (transfer none) (element-type utf8 GObject.Value):
 *  the immutable properties of the channel
 * @error: Used to raise an error if @object_path is not valid
 *
 * Returns a #TpChannel proxy for the channel at @object_path on @connection.
 * The returned #TpChannel is cached; the same #TpChannel object
 * will be returned by this function repeatedly, as long as at least one
 * reference exists.
 *
 * Note that the returned #TpChannel is not guaranteed to be ready; the
 * caller is responsible for calling tp_proxy_prepare_async() with the desired
 * features (as given by tp_simple_client_factory_dup_channel_features()).
 *
 * This function is rather low-level.
 * #TpAccountChannelRequest and #TpBaseClient are more appropriate ways
 * to obtain channels for most applications.
 *
 * Returns: (transfer full): a reference to a #TpChannel;
 *  see tp_channel_new_from_properties().
 *
 * Since: 0.15.5
 */
TpChannel *
tp_simple_client_factory_ensure_channel (TpSimpleClientFactory *self,
    TpConnection *connection,
    const gchar *object_path,
    const GHashTable *immutable_properties,
    GError **error)
{
  TpChannel *channel;

  g_return_val_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self), NULL);
  g_return_val_if_fail (TP_IS_CONNECTION (connection), NULL);
  g_return_val_if_fail (tp_proxy_get_factory (connection) == self, NULL);
  g_return_val_if_fail (g_variant_is_object_path (object_path), NULL);

  channel = lookup_proxy (self, object_path);
  if (channel != NULL)
    return g_object_ref (channel);

  channel = TP_SIMPLE_CLIENT_FACTORY_GET_CLASS (self)->create_channel (self,
      connection, object_path, immutable_properties, error);
  insert_proxy (self, channel);

  return channel;
}

/**
 * tp_simple_client_factory_dup_channel_features:
 * @self: a #TpSimpleClientFactory object
 * @channel: a #TpChannel
 *
 * Return a zero-terminated #GArray containing the #TpChannel features that
 * should be prepared on @channel.
 *
 * Returns: (transfer full) (element-type GLib.Quark): a newly allocated
 *  #GArray
 *
 * Since: 0.15.5
 */
GArray *
tp_simple_client_factory_dup_channel_features (TpSimpleClientFactory *self,
    TpChannel *channel)
{
  g_return_val_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self), NULL);
  g_return_val_if_fail (TP_IS_CHANNEL (channel), NULL);
  g_return_val_if_fail (tp_proxy_get_factory (channel) == self, NULL);

  return TP_SIMPLE_CLIENT_FACTORY_GET_CLASS (self)->dup_channel_features (
      self, channel);
}

/**
 * tp_simple_client_factory_add_channel_features:
 * @self: a #TpSimpleClientFactory object
 * @features: (transfer none) (array zero-terminated=1) (allow-none): an array
 *  of desired features, ending with 0; %NULL is equivalent to an array
 *  containing only 0
 *
 * Add @features to the desired features to be prepared on #TpChannel
 * objects. Those features will be added to the features already returned be
 * tp_simple_client_factory_dup_channel_features().
 *
 * It is not necessary to add %TP_CHANNEL_FEATURE_CORE as it is already
 * included by default.
 *
 * Note that these features will not be added to existing #TpChannel
 * objects; the user must call tp_proxy_prepare_async() themself.
 *
 * Since: 0.15.5
 */
void
tp_simple_client_factory_add_channel_features (
    TpSimpleClientFactory *self,
    const GQuark *features)
{
  g_return_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self));

  _tp_quark_array_merge (self->priv->desired_channel_features, features, -1);
}

/**
 * tp_simple_client_factory_add_channel_features_varargs: (skip)
 * @self: a #TpSimpleClientFactory
 * @feature: the first feature
 * @...: the second and subsequent features, if any, ending with 0
 *
 * The same as tp_simple_client_factory_add_channel_features(), but with a
 * more convenient calling convention from C.
 *
 * Since: 0.15.5
 */
void
tp_simple_client_factory_add_channel_features_varargs (
    TpSimpleClientFactory *self,
    GQuark feature,
    ...)
{
  va_list var_args;

  g_return_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self));

  va_start (var_args, feature);
  _tp_quark_array_merge_valist (self->priv->desired_channel_features,
      feature, var_args);
  va_end (var_args);
}

/**
 * tp_simple_client_factory_ensure_contact:
 * @self: a #TpSimpleClientFactory object
 * @connection: a #TpConnection whose #TpProxy:factory is this object
 * @handle: a #TpHandle
 * @identifier: a string representing the contact's identifier
 *
 * Returns a #TpContact representing @identifier (and @handle) on @connection.
 * The returned #TpContact is cached; the same #TpContact object
 * will be returned by this function repeatedly, as long as at least one
 * reference exists.
 *
 * Note that the returned #TpContact is not guaranteed to be ready; the caller
 * is responsible for calling tp_connection_upgrade_contacts() with the desired
 * features (as given by tp_simple_client_factory_dup_contact_features()).
 *
 * For this function to work properly, tp_connection_has_immortal_handles()
 * must return %TRUE for @connection.
 *
 * Returns: (transfer full): a reference to a #TpContact.
 *
 * Since: 0.15.5
 */
TpContact *
tp_simple_client_factory_ensure_contact (TpSimpleClientFactory *self,
    TpConnection *connection,
    TpHandle handle,
    const gchar *identifier)
{
  TpContact *contact;

  g_return_val_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self), NULL);
  g_return_val_if_fail (TP_IS_CONNECTION (connection), NULL);
  g_return_val_if_fail (tp_proxy_get_factory (connection) == self, NULL);
  g_return_val_if_fail (tp_connection_has_immortal_handles (connection), NULL);
  g_return_val_if_fail (handle != 0, NULL);
  g_return_val_if_fail (identifier != NULL, NULL);

  contact = tp_connection_dup_contact_if_possible (connection,
      handle, identifier);
  if (contact != NULL)
    return contact;

  contact = TP_SIMPLE_CLIENT_FACTORY_GET_CLASS (self)->create_contact (self,
      connection, handle, identifier);
  _tp_connection_add_contact (connection, handle, contact);

  return contact;
}

static void
upgrade_contacts_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpConnection *connection = (TpConnection *) source;
  GSimpleAsyncResult *my_result = user_data;
  GPtrArray *contacts;
  GError *error = NULL;

  if (!tp_connection_upgrade_contacts_finish (connection, result,
          &contacts, &error))
    {
      g_simple_async_result_take_error (my_result, error);
    }
  else
    {
      g_simple_async_result_set_op_res_gpointer (my_result, contacts,
          (GDestroyNotify) g_ptr_array_unref);
    }

  g_simple_async_result_complete (my_result);
  g_object_unref (my_result);
}


/**
 * tp_simple_client_factory_upgrade_contacts_async:
 * @self: a #TpSimpleClientFactory object
 * @connection: a #TpConnection whose #TpProxy:factory is this object
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects
 *  associated with @self
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Same as tp_connection_upgrade_contacts_async(), but prepare contacts with all
 * features previously passed to
 * tp_simple_client_factory_add_contact_features().
 *
 * Since: 0.19.1
 */
void
tp_simple_client_factory_upgrade_contacts_async (
    TpSimpleClientFactory *self,
    TpConnection *connection,
    guint n_contacts,
    TpContact * const *contacts,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  GArray *features;

  /* no real reason this shouldn't work, but it's really confusing
   * and probably indicates an error */
  g_warn_if_fail (tp_proxy_get_factory (connection) == self);

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      tp_simple_client_factory_upgrade_contacts_async);

  features = tp_simple_client_factory_dup_contact_features (self, connection);
  tp_connection_upgrade_contacts_async (connection, n_contacts, contacts,
      features->len, (TpContactFeature *) features->data,
      upgrade_contacts_cb, result);
  g_array_unref (features);
}

/**
 * tp_simple_client_factory_upgrade_contacts_finish:
 * @self: a #TpSimpleClientFactory
 * @result: a #GAsyncResult
 * @contacts: (element-type TelepathyGLib.Contact) (transfer container) (out) (allow-none):
 *  a location to set a #GPtrArray of upgraded #TpContact, or %NULL.
 * @error: a #GError to fill
 *
 * Finishes tp_simple_client_factory_upgrade_contacts_async()
 *
 * Returns: %TRUE on success, %FALSE otherwise.
 * Since: 0.19.1
 */
gboolean
tp_simple_client_factory_upgrade_contacts_finish (
    TpSimpleClientFactory *self,
    GAsyncResult *result,
    GPtrArray **contacts,
    GError **error)
{
  _tp_implement_finish_copy_pointer (self,
      tp_simple_client_factory_upgrade_contacts_async,
      g_ptr_array_ref, contacts);
}

static void
dup_contact_by_id_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpConnection *connection = (TpConnection *) source;
  GSimpleAsyncResult *my_result = user_data;
  TpContact *contact;
  GError *error = NULL;

  contact = tp_connection_dup_contact_by_id_finish (connection, result, &error);
  if (contact == NULL)
    {
      g_simple_async_result_take_error (my_result, error);
    }
  else
    {
      g_simple_async_result_set_op_res_gpointer (my_result, contact,
          g_object_unref);
    }

  g_simple_async_result_complete (my_result);
  g_object_unref (my_result);
}


/**
 * tp_simple_client_factory_ensure_contact_by_id_async:
 * @self: a #TpSimpleClientFactory object
 * @connection: a #TpConnection
 * @identifier: a string representing the contact's identifier
 * @callback: a callback to call when the operation finishes
 * @user_data: data to pass to @callback
 *
 * Same as tp_connection_dup_contact_by_id_async(), but prepare the
 * contact with all features previously passed to
 * tp_simple_client_factory_add_contact_features().
 *
 * Since: 0.19.1
 */
void
tp_simple_client_factory_ensure_contact_by_id_async (
    TpSimpleClientFactory *self,
    TpConnection *connection,
    const gchar *identifier,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  GArray *features;

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      tp_simple_client_factory_ensure_contact_by_id_async);

  features = tp_simple_client_factory_dup_contact_features (self, connection);
  tp_connection_dup_contact_by_id_async (connection, identifier,
      features->len, (TpContactFeature *) features->data,
      dup_contact_by_id_cb, result);
  g_array_unref (features);
}

/**
 * tp_simple_client_factory_ensure_contact_by_id_finish:
 * @self: a #TpSimpleClientFactory
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_simple_client_factory_ensure_contact_by_id_async()
 *
 * Returns: (transfer full): a #TpContact or %NULL on error.
 * Since: 0.19.1
 */
TpContact *
tp_simple_client_factory_ensure_contact_by_id_finish (
    TpSimpleClientFactory *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_simple_client_factory_ensure_contact_by_id_async, g_object_ref);
}

/**
 * tp_simple_client_factory_dup_contact_features:
 * @self: a #TpSimpleClientFactory object
 * @connection: a #TpConnection
 *
 * Return a #GArray containing the #TpContactFeature that should be prepared on
 * all contacts of @connection.
 *
 * Returns: (transfer full) (element-type TelepathyGLib.ContactFeature): a newly
 *  allocated #GArray
 *
 * Since: 0.15.5
 */
GArray *
tp_simple_client_factory_dup_contact_features (TpSimpleClientFactory *self,
    TpConnection *connection)
{
  g_return_val_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self), NULL);
  g_return_val_if_fail (TP_IS_CONNECTION (connection), NULL);
  g_return_val_if_fail (tp_proxy_get_factory (connection) == self, NULL);

  return TP_SIMPLE_CLIENT_FACTORY_GET_CLASS (self)->dup_contact_features (
      self, connection);
}

/**
 * tp_simple_client_factory_add_contact_features:
 * @self: a #TpSimpleClientFactory object
 * @n_features: The number of features in @features (may be 0)
 * @features: (array length=n_features) (allow-none): an array of desired
 *  features (may be %NULL if @n_features is 0)
 *
 * Add @features to the desired features to be prepared on #TpContact
 * objects. Those features will be added to the features already returned be
 * tp_simple_client_factory_dup_contact_features().
 *
 * Note that these features will not be added to existing #TpContact
 * objects; the user must call tp_connection_upgrade_contacts() themself.
 *
 * Since: 0.15.5
 */
void
tp_simple_client_factory_add_contact_features (TpSimpleClientFactory *self,
    guint n_features, const TpContactFeature *features)
{
  guint i;

  g_return_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self));

  /* Add features into desired_contact_features avoiding dups */
  for (i = 0; i < n_features; i++)
    {
      guint j;
      gboolean found = FALSE;

      for (j = 0; j < self->priv->desired_contact_features->len; j++)
        {
          if (features[i] == g_array_index (
              self->priv->desired_contact_features, TpContactFeature, j))
            {
              found = TRUE;
              break;
            }
        }

      if (!found)
        g_array_append_val (self->priv->desired_contact_features, features[i]);
    }
}

/**
 * tp_simple_client_factory_add_contact_features_varargs: (skip)
 * @self: a #TpSimpleClientFactory
 * @feature: the first feature
 * @...: the second and subsequent features, if any, ending with
 *  %TP_CONTACT_FEATURE_INVALID
 *
 * The same as tp_simple_client_factory_add_contact_features(), but with a
 * more convenient calling convention from C.
 *
 * Since: 0.15.5
 */
void
tp_simple_client_factory_add_contact_features_varargs (
    TpSimpleClientFactory *self,
    TpContactFeature feature,
    ...)
{
  va_list var_args;
  GArray *features;
  TpContactFeature f;

  g_return_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self));

  va_start (var_args, feature);
  features = g_array_new (FALSE, FALSE, sizeof (TpContactFeature));

  for (f = feature; f != TP_CONTACT_FEATURE_INVALID;
      f = va_arg (var_args, TpContactFeature))
    g_array_append_val (features, f);

  tp_simple_client_factory_add_contact_features (self, features->len,
      (TpContactFeature *) features->data);

  g_array_unref (features);
  va_end (var_args);
}

/*
 * _tp_simple_client_factory_ensure_channel_request:
 * @self: a #TpSimpleClientFactory object
 * @object_path: the object path of a channel request
 * @immutable_properties: (transfer none) (element-type utf8 GObject.Value):
 *  the immutable properties of the channel request
 * @error: Used to raise an error if @object_path is not valid
 *
 * Returns a #TpChannelRequest for @object_path. The returned
 * #TpChannelRequest is cached; the same #TpChannelRequest object will be
 * returned by this function repeatedly, as long as at least one reference
 * exists.
 *
 * Note that the returned #TpChannelRequest is not guaranteed to be ready; the
 * caller is responsible for calling tp_proxy_prepare_async().
 *
 * Returns: (transfer full): a reference to a #TpChannelRequest;
 *  see tp_channel_request_new().
 *
 * Since: 0.15.5
 */
TpChannelRequest *
_tp_simple_client_factory_ensure_channel_request (TpSimpleClientFactory *self,
    const gchar *object_path,
    GHashTable *immutable_properties,
    GError **error)
{
  TpChannelRequest *request;

  g_return_val_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self), NULL);
  g_return_val_if_fail (g_variant_is_object_path (object_path), NULL);

  request = lookup_proxy (self, object_path);
  if (request != NULL)
    {
      /* A common usage is request_and_handle, in that case EnsureChannel
       * returns only the object-path of the ChannelRequest but not properties.
       * The TpChannelRequest will be created with no properties, then when
       * handling we get the properties and we reuse the same TpChannelRequest
       * object, and we can give it the immutable-properties. */
      _tp_channel_request_ensure_immutable_properties (request,
          immutable_properties);
      return g_object_ref (request);
    }

  request = _tp_channel_request_new_with_factory (self, self->priv->dbus,
      object_path, immutable_properties, error);
  insert_proxy (self, request);

  return request;
}

/*
 * _tp_simple_client_factory_ensure_channel_dispatch_operation:
 * @self: a #TpSimpleClientFactory object
 * @object_path: the object path of a channel dispatch operation
 * @immutable_properties: (transfer none) (element-type utf8 GObject.Value):
 *  the immutable properties of the channel dispatch operation
 * @error: Used to raise an error if @object_path is not valid
 *
 * Returns a #TpChannelDispatchOperation for @object_path.
 * The returned #TpChannelDispatchOperation is cached; the same
 * #TpChannelDispatchOperation object will be returned by this function
 * repeatedly, as long as at least one reference exists.
 *
 * Note that the returned #TpChannelDispatchOperation is not guaranteed to be
 * ready; the caller is responsible for calling tp_proxy_prepare_async().
 *
 * Returns: (transfer full): a reference to a
 *  #TpChannelDispatchOperation; see tp_channel_dispatch_operation_new().
 *
 * Since: 0.15.5
 */
TpChannelDispatchOperation *
_tp_simple_client_factory_ensure_channel_dispatch_operation (
    TpSimpleClientFactory *self,
    const gchar *object_path,
    GHashTable *immutable_properties,
    GError **error)
{
  TpChannelDispatchOperation *dispatch;

  g_return_val_if_fail (TP_IS_SIMPLE_CLIENT_FACTORY (self), NULL);
  g_return_val_if_fail (g_variant_is_object_path (object_path), NULL);

  dispatch = lookup_proxy (self, object_path);
  if (dispatch != NULL)
    return g_object_ref (dispatch);

  dispatch = _tp_channel_dispatch_operation_new_with_factory (self,
      self->priv->dbus, object_path, immutable_properties, error);
  insert_proxy (self, dispatch);

  return dispatch;
}
