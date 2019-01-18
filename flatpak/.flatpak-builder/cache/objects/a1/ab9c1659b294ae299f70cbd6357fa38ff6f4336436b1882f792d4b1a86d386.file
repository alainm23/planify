/* Object representing a Telepathy contact
 *
 * Copyright (C) 2008 Collabora Ltd. <http://www.collabora.co.uk/>
 * Copyright (C) 2008 Nokia Corporation
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

#include <telepathy-glib/contact.h>

#include <errno.h>
#include <string.h>

#include <telepathy-glib/capabilities-internal.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CONTACTS
#include "telepathy-glib/base-contact-list-internal.h"
#include "telepathy-glib/connection-contact-list.h"
#include "telepathy-glib/connection-internal.h"
#include "telepathy-glib/contact-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/util-internal.h"
#include "telepathy-glib/variant-util-internal.h"

static const gchar *
nonnull (const gchar *s)
{
  if (s == NULL)
    return "(null)";

  return s;
}

/**
 * SECTION:contact
 * @title: TpContact
 * @short_description: object representing a contact
 * @see_also: #TpConnection
 *
 * #TpContact objects represent the contacts on a particular #TpConnection.
 *
 * Since: 0.7.18
 */

/**
 * TpContact:
 *
 * An object representing a contact on a #TpConnection.
 *
 * Contact objects support tracking a number of attributes of contacts, as
 * described by the #TpContactFeature flags. Features can be specified when
 * instantiating contact objects (with tp_connection_get_contacts_by_id() or
 * tp_connection_get_contacts_by_handle()), or added to an existing contact
 * object with tp_connection_upgrade_contacts(). For example, a client wishing
 * to keep track of a contact's alias would set #TP_CONTACT_FEATURE_ALIAS, and
 * then listen for the "notify::alias" signal, emitted whenever the
 * #TpContact:alias property changes.
 *
 * Note that releasing a #TpContact object might release handle references
 * held by calling tp_cli_connection_call_request_handles(),
 * tp_cli_connection_run_request_handles(),
 * tp_cli_connection_call_hold_handles(),
 * tp_cli_connection_run_hold_handles(),
 * tp_cli_connection_interface_contacts_call_get_contact_attributes() or
 * tp_cli_connection_interface_contacts_run_get_contact_attributes() directly.
 * Those functions should be avoided in favour of using #TpContact,
 * tp_connection_hold_handles(), tp_connection_request_handles() and
 * tp_connection_get_contact_attributes().
 *
 * Since: 0.7.18
 */

struct _TpContactClass {
    /*<private>*/
    GObjectClass parent_class;
};

struct _TpContact {
    /*<private>*/
    GObject parent;
    TpContactPrivate *priv;
};

/**
 * TpContactFeature:
 * @TP_CONTACT_FEATURE_ALIAS: #TpContact:alias
 * @TP_CONTACT_FEATURE_AVATAR_TOKEN: #TpContact:avatar-token
 * @TP_CONTACT_FEATURE_PRESENCE: #TpContact:presence-type,
 *  #TpContact:presence-status and #TpContact:presence-message
 * @TP_CONTACT_FEATURE_LOCATION: #TpContact:location (available since 0.11.1)
 *  and #TpContact:location-vardict (since 0.19.10)
 * @TP_CONTACT_FEATURE_CAPABILITIES: #TpContact:capabilities
 *  (available since 0.11.3)
 * @TP_CONTACT_FEATURE_AVATAR_DATA: #TpContact:avatar-file and
 *  #TpContact:avatar-mime-type. Implies %TP_CONTACT_FEATURE_AVATAR_TOKEN
 *  (available since 0.11.6)
 * @TP_CONTACT_FEATURE_CONTACT_INFO: #TpContact:contact-info
 *  (available since 0.11.7)
 * @TP_CONTACT_FEATURE_CLIENT_TYPES: #TpContact:client-types
 *  (available since 0.13.1)
 * @TP_CONTACT_FEATURE_SUBSCRIPTION_STATES: #TpContact:subscribe-state,
 *  #TpContact:publish-state and #TpContact:publish-request. Require a
 *  Connection implementing the %TP_IFACE_CONNECTION_INTERFACE_CONTACT_LIST
 *  interface. (available since 0.13.12)
 * @TP_CONTACT_FEATURE_CONTACT_GROUPS: #TpContact:contact-groups
 *  (available since 0.13.14)
 * @TP_CONTACT_FEATURE_CONTACT_BLOCKING: #TpContact:is-blocked. Require
 *  Connection implementing the %TP_IFACE_CONNECTION_INTERFACE_CONTACT_BLOCKING
 *  interface. (available since 0.17.0)
 *
 * Enumeration representing the features a #TpContact can optionally support.
 * When requesting a #TpContact, library users specify the desired features;
 * the #TpContact code will only initialize state for those features, to
 * avoid unwanted D-Bus round-trips and signal connections.
 *
 * Since 0.11.5, there is a corresponding #GEnumClass type,
 * %TP_TYPE_CONTACT_FEATURE.
 *
 * Since: 0.7.18
 */

/**
 * TP_NUM_CONTACT_FEATURES:
 *
 * 1 higher than the highest #TpContactFeature supported by this version of
 * telepathy-glib.
 *
 * Since: 0.19.0
 */

/**
 * NUM_TP_CONTACT_FEATURES: (skip)
 *
 * 1 higher than the highest #TpContactFeature supported by this version of
 * telepathy-glib. Use %TP_NUM_CONTACT_FEATURES in new code.
 *
 * Since: 0.7.18
 */

/**
 * TP_CONTACT_FEATURE_INVALID: (skip)
 *
 * An invalid TpContactFeature. Used as list termination. See for example
 * tp_simple_client_factory_add_contact_features_varargs().
 *
 * Since: 0.15.5
 */

/**
 * TP_TYPE_CONTACT_FEATURE:
 *
 * The #GEnumClass type of a #TpContactFeature.
 *
 * Since: 0.11.5
 */

G_DEFINE_TYPE (TpContact, tp_contact, G_TYPE_OBJECT)


enum {
    PROP_CONNECTION = 1,
    PROP_HANDLE,
    PROP_IDENTIFIER,
    PROP_ALIAS,
    PROP_AVATAR_TOKEN,
    PROP_AVATAR_FILE,
    PROP_AVATAR_MIME_TYPE,
    PROP_PRESENCE_TYPE,
    PROP_PRESENCE_STATUS,
    PROP_PRESENCE_MESSAGE,
    PROP_LOCATION,
    PROP_LOCATION_VARDICT,
    PROP_CAPABILITIES,
    PROP_CONTACT_INFO,
    PROP_CLIENT_TYPES,
    PROP_SUBSCRIBE_STATE,
    PROP_PUBLISH_STATE,
    PROP_PUBLISH_REQUEST,
    PROP_CONTACT_GROUPS,
    PROP_IS_BLOCKED,
    N_PROPS
};

enum {
    SIGNAL_PRESENCE_CHANGED,
    SIGNAL_SUBSCRIPTION_STATES_CHANGED,
    SIGNAL_CONTACT_GROUPS_CHANGED,
    N_SIGNALS
};

static guint signals[N_SIGNALS] = {0};

/* The API allows for more than 32 features, but this implementation does
 * not. We can easily expand this later. */
typedef enum {
    CONTACT_FEATURE_FLAG_ALIAS = 1 << TP_CONTACT_FEATURE_ALIAS,
    CONTACT_FEATURE_FLAG_AVATAR_TOKEN = 1 << TP_CONTACT_FEATURE_AVATAR_TOKEN,
    CONTACT_FEATURE_FLAG_PRESENCE = 1 << TP_CONTACT_FEATURE_PRESENCE,
    CONTACT_FEATURE_FLAG_LOCATION = 1 << TP_CONTACT_FEATURE_LOCATION,
    CONTACT_FEATURE_FLAG_CAPABILITIES = 1 << TP_CONTACT_FEATURE_CAPABILITIES,
    CONTACT_FEATURE_FLAG_AVATAR_DATA = 1 << TP_CONTACT_FEATURE_AVATAR_DATA,
    CONTACT_FEATURE_FLAG_CONTACT_INFO = 1 << TP_CONTACT_FEATURE_CONTACT_INFO,
    CONTACT_FEATURE_FLAG_CLIENT_TYPES = 1 << TP_CONTACT_FEATURE_CLIENT_TYPES,
    CONTACT_FEATURE_FLAG_STATES = 1 << TP_CONTACT_FEATURE_SUBSCRIPTION_STATES,
    CONTACT_FEATURE_FLAG_CONTACT_GROUPS = 1 << TP_CONTACT_FEATURE_CONTACT_GROUPS,
    CONTACT_FEATURE_FLAG_CONTACT_BLOCKING = 1 << TP_CONTACT_FEATURE_CONTACT_BLOCKING,
} ContactFeatureFlags;

struct _TpContactPrivate {
    /* basics */
    TpConnection *connection;
    TpHandle handle;
    gchar *identifier;
    ContactFeatureFlags has_features;

    /* aliasing */
    gchar *alias;

    /* avatars */
    gchar *avatar_token;
    GFile *avatar_file;
    gchar *avatar_mime_type;

    /* presence */
    TpConnectionPresenceType presence_type;
    gchar *presence_status;
    gchar *presence_message;

    /* location */
    GHashTable *location;

    /* client types */
    gchar **client_types;

    /* capabilities */
    TpCapabilities *capabilities;

    /* a list of TpContactInfoField */
    GList *contact_info;

    /* Subscribe/Publish states */
    TpSubscriptionState subscribe;
    TpSubscriptionState publish;
    gchar *publish_request;

    /* ContactGroups */
    /* array of dupped strings */
    GPtrArray *contact_groups;

    /* ContactBlocking */
    gboolean is_blocked;
};


/**
 * tp_contact_get_account:
 * @self: a contact
 *
 * Return the #TpAccount of @self's #TpContact:connection.
 * See tp_connection_get_account() for details.
 *
 * Returns: (transfer none): a borrowed reference to @self's account
 *  (it must be referenced with g_object_ref if it must remain valid
 *  longer than the contact)
 *
 * Since: 0.19.0
 */
TpAccount *
tp_contact_get_account (TpContact *self)
{
  g_return_val_if_fail (TP_IS_CONTACT (self), NULL);

  return tp_connection_get_account (self->priv->connection);
}

/**
 * tp_contact_get_connection:
 * @self: a contact
 *
 * <!-- nothing more to say -->
 *
 * Returns: (transfer none): a borrowed reference to the #TpContact:connection
 *  (it must be referenced with g_object_ref if it must remain valid
 *  longer than the contact)
 *
 * Since: 0.7.18
 */
TpConnection *
tp_contact_get_connection (TpContact *self)
{
  g_return_val_if_fail (self != NULL, 0);

  return self->priv->connection;
}

/**
 * tp_contact_get_handle:
 * @self: a contact
 *
 * Return the contact's handle, which is of type %TP_HANDLE_TYPE_CONTACT,
 * or 0 if the #TpContact:connection has become invalid.
 *
 * This handle is referenced using the Telepathy D-Bus API and remains
 * referenced for as long as @self exists and the
 * #TpContact:connection remains valid.
 *
 * However, the caller of this function does not gain an additional reference
 * to the handle.
 *
 * Returns: the same handle as the #TpContact:handle property
 *
 * Since: 0.7.18
 */
TpHandle
tp_contact_get_handle (TpContact *self)
{
  g_return_val_if_fail (self != NULL, 0);

  return self->priv->handle;
}

/**
 * tp_contact_get_identifier:
 * @self: a contact
 *
 * Return the contact's identifier. This remains valid for as long as @self
 * exists; if the caller requires a string that will persist for longer than
 * that, it must be copied with g_strdup().
 *
 * Returns: the same non-%NULL identifier as the #TpContact:identifier property
 *
 * Since: 0.7.18
 */
const gchar *
tp_contact_get_identifier (TpContact *self)
{
  g_return_val_if_fail (self != NULL, NULL);
  /* identifier must be non-NULL by the time we're visible to library-user
   * code */
  g_return_val_if_fail (self->priv->identifier != NULL, NULL);

  return self->priv->identifier;
}

/**
 * tp_contact_has_feature:
 * @self: a contact
 * @feature: a desired feature
 *
 * <!-- -->
 *
 * Returns: %TRUE if @self has been set up to track the feature @feature
 *
 * Since: 0.7.18
 */
gboolean
tp_contact_has_feature (TpContact *self,
                        TpContactFeature feature)
{
  g_return_val_if_fail (self != NULL, FALSE);
  g_return_val_if_fail (feature < TP_NUM_CONTACT_FEATURES, FALSE);

  return ((self->priv->has_features & (1 << feature)) != 0);
}


/**
 * tp_contact_get_alias:
 * @self: a contact
 *
 * Return the contact's alias. This remains valid until the main loop
 * is re-entered; if the caller requires a string that will persist for
 * longer than that, it must be copied with g_strdup().
 *
 * Returns: the same non-%NULL alias as the #TpContact:alias
 *
 * Since: 0.7.18
 */
const gchar *
tp_contact_get_alias (TpContact *self)
{
  g_return_val_if_fail (self != NULL, NULL);
  /* identifier must be non-NULL by the time we're visible to library-user
   * code */
  g_return_val_if_fail (self->priv->identifier != NULL, NULL);

  if (self->priv->alias != NULL)
    return self->priv->alias;

  return self->priv->identifier;
}


/**
 * tp_contact_get_avatar_token:
 * @self: a contact
 *
 * Return the contact's avatar token. This remains valid until the main loop
 * is re-entered; if the caller requires a string that will persist for
 * longer than that, it must be copied with g_strdup().
 *
 * Returns: the same token as the #TpContact:avatar-token property
 *  (possibly %NULL)
 *
 * Since: 0.7.18
 */
const gchar *
tp_contact_get_avatar_token (TpContact *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return self->priv->avatar_token;
}

/**
 * tp_contact_get_avatar_file:
 * @self: a contact
 *
 * Return the contact's avatar file. This remains valid until the main loop
 * is re-entered; if the caller requires a #GFile that will persist for
 * longer than that, it must be reffed with g_object_ref().
 *
 * Returns: (transfer none): the same #GFile as the #TpContact:avatar-file property
 *  (possibly %NULL)
 *
 * Since: 0.11.6
 */
GFile *
tp_contact_get_avatar_file (TpContact *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return self->priv->avatar_file;
}

/**
 * tp_contact_get_avatar_mime_type:
 * @self: a contact
 *
 * Return the contact's avatar MIME type. This remains valid until the main loop
 * is re-entered; if the caller requires a string that will persist for
 * longer than that, it must be copied with g_strdup().
 *
 * Returns: the same MIME type as the #TpContact:avatar-mime-type property
 *  (possibly %NULL)
 *
 * Since: 0.11.6
 */
const gchar *
tp_contact_get_avatar_mime_type (TpContact *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return self->priv->avatar_mime_type;
}

/**
 * tp_contact_get_presence_type:
 * @self: a contact
 *
 * If this object has been set up to track %TP_CONTACT_FEATURE_PRESENCE
 * and the underlying connection supports either the Presence or
 * SimplePresence interfaces, return the type of the contact's presence.
 *
 * Otherwise, return %TP_CONNECTION_PRESENCE_TYPE_UNSET.
 *
 * Returns: the same presence type as the #TpContact:presence-type property
 *
 * Since: 0.7.18
 */
TpConnectionPresenceType
tp_contact_get_presence_type (TpContact *self)
{
  g_return_val_if_fail (self != NULL, TP_CONNECTION_PRESENCE_TYPE_UNSET);

  return self->priv->presence_type;
}


/**
 * tp_contact_get_presence_status:
 * @self: a contact
 *
 * Return the name of the contact's presence status, or an empty string.
 * This remains valid until the main loop is re-entered; if the caller
 * requires a string that will persist for longer than that, it must be
 * copied with g_strdup().
 *
 * Returns: the same non-%NULL status name as the #TpContact:presence-status
 *  property
 *
 * Since: 0.7.18
 */
const gchar *
tp_contact_get_presence_status (TpContact *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return (self->priv->presence_status == NULL ? "" :
      self->priv->presence_status);
}


/**
 * tp_contact_get_presence_message:
 * @self: a contact
 *
 * Return the contact's user-defined status message, or an empty string.
 * This remains valid until the main loop is re-entered; if the caller
 * requires a string that will persist for longer than that, it must be
 * copied with g_strdup().
 *
 * Returns: the same non-%NULL message as the #TpContact:presence-message
 *  property
 *
 * Since: 0.7.18
 */
const gchar *
tp_contact_get_presence_message (TpContact *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return (self->priv->presence_message == NULL ? "" :
      self->priv->presence_message);
}

/**
 * tp_contact_get_location:
 * @self: a contact
 *
 * Return the contact's user-defined location or %NULL if the location is
 * unspecified.
 * This remains valid until the main loop is re-entered; if the caller
 * requires a hash table that will persist for longer than that, it must be
 * reffed with g_hash_table_ref().
 *
 * Returns: (element-type utf8 GObject.Value) (transfer none): the same
 *  #GHashTable (or %NULL) as the #TpContact:location property
 *
 * Since: 0.11.1
 */
GHashTable *
tp_contact_get_location (TpContact *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return self->priv->location;
}

/**
 * tp_contact_dup_location:
 * @self: a contact
 *
 * Return the contact's user-defined location, or %NULL if the location is
 * unspecified.
 *
 * This function returns the same information as tp_contact_get_location(),
 * but in a different format.
 *
 * Returns: a variant of type %G_VARIANT_TYPE_VARDICT, the same as
 *  the #TpContact:location-vardict property
 *
 * Since: 0.19.10
 */
GVariant *
tp_contact_dup_location (TpContact *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  if (self->priv->location == NULL)
    return NULL;

  return _tp_asv_to_vardict (self->priv->location);
}

/**
 * tp_contact_get_client_types:
 * @self: a contact
 *
 * Return the contact's client types or %NULL if the client types are
 * unspecified.
 *
 * Returns: (array zero-terminated=1) (transfer none): the same
 *  #GStrv as the #TpContact:client-types property
 *
 * Since: 0.13.1
 */
const gchar * const *
tp_contact_get_client_types (TpContact *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return (const gchar * const *) self->priv->client_types;
}

/**
 * tp_contact_get_capabilities:
 * @self: a contact
 *
 * <!-- -->
 *
 * Returns: (transfer none): the same #TpCapabilities (or %NULL) as the
 * #TpContact:capabilities property
 *
 * Since: 0.11.3
 */
TpCapabilities *
tp_contact_get_capabilities (TpContact *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return self->priv->capabilities;
}

/**
 * tp_contact_get_contact_info:
 * @self: a #TpContact
 *
 * Returns a newly allocated #GList of contact's vCard fields. The list must be
 * freed with g_list_free() after used.
 *
 * Note that the #TpContactInfoField<!-- -->s in the returned #GList are not
 * dupped before returning from this function. One could copy every item in the
 * list using tp_contact_info_field_copy().
 *
 * Same as the #TpContact:contact-info property.
 *
 * Returns: (element-type TelepathyGLib.ContactInfoField) (transfer container):
 *  a #GList of #TpContactInfoField, or %NULL if the feature is not yet
 *  prepared.
 * Since: 0.11.7
 * Deprecated: Since 0.19.9. New code should use
 *  tp_contact_dup_contact_info() instead.
 */
GList *
tp_contact_get_contact_info (TpContact *self)
{
  g_return_val_if_fail (TP_IS_CONTACT (self), NULL);

  return g_list_copy (self->priv->contact_info);
}

/**
 * tp_contact_dup_contact_info:
 * @self: a #TpContact
 *
 * Returns a newly allocated #GList of contact's vCard fields. The list must be
 * freed with tp_contact_info_list_free() after used.
 *
 * Same as the #TpContact:contact-info property.
 *
 * Returns: (element-type TelepathyGLib.ContactInfoField) (transfer full):
 *  a #GList of #TpContactInfoField, or %NULL if the feature is not yet
 *  prepared.
 * Since: 0.19.9
 */
GList *
tp_contact_dup_contact_info (TpContact *self)
{
  g_return_val_if_fail (TP_IS_CONTACT (self), NULL);

  return _tp_g_list_copy_deep (self->priv->contact_info,
      (GCopyFunc) tp_contact_info_field_copy, NULL);
}

/**
 * tp_contact_get_subscribe_state:
 * @self: a #TpContact
 *
 * Return the state of the local user's subscription to this remote contact's
 * presence.
 *
 * This is set to %TP_SUBSCRIPTION_STATE_UNKNOWN until
 * %TP_CONTACT_FEATURE_SUBSCRIPTION_STATES has been prepared
 *
 * Returns: the value of #TpContact:subscribe-state.
 *
 * Since: 0.13.12
 */
TpSubscriptionState
tp_contact_get_subscribe_state (TpContact *self)
{
  g_return_val_if_fail (TP_IS_CONTACT (self), TP_SUBSCRIPTION_STATE_UNKNOWN);

  return self->priv->subscribe;
}

/**
 * tp_contact_get_publish_state:
 * @self: a #TpContact
 *
 * Return the state of this remote contact's subscription to the local user's
 * presence.
 *
 * This is set to %TP_SUBSCRIPTION_STATE_UNKNOWN until
 * %TP_CONTACT_FEATURE_SUBSCRIPTION_STATES has been prepared
 *
 * Returns: the value of #TpContact:publish-state.
 *
 * Since: 0.13.12
 */
TpSubscriptionState
tp_contact_get_publish_state (TpContact *self)
{
  g_return_val_if_fail (TP_IS_CONTACT (self), TP_SUBSCRIPTION_STATE_UNKNOWN);

  return self->priv->publish;
}

/**
 * tp_contact_get_publish_request:
 * @self: a #TpContact
 *
 * If #TpContact:publish-state is set to %TP_SUBSCRIPTION_STATE_ASK, return the
 * message that this remote contact sent when they requested permission to see
 * the local user's presence, an empty string ("") otherwise. This remains valid
 * until the main loop is re-entered; if the caller requires a string that will
 * persist for longer than that, it must be copied with g_strdup().
 *
 * This is set to %NULL until %TP_CONTACT_FEATURE_SUBSCRIPTION_STATES has been
 * prepared, and it is guaranteed to be non-%NULL afterward.

 * Returns: the value of #TpContact:publish-request.
 *
 * Since: 0.13.12
 */
const gchar *
tp_contact_get_publish_request (TpContact *self)
{
  g_return_val_if_fail (TP_IS_CONTACT (self), NULL);

  return self->priv->publish_request;
}

/**
 * tp_contact_get_contact_groups:
 * @self: a #TpContact
 *
 * Return names of groups of which a contact is a member. It is incorrect to
 * call this method before %TP_CONTACT_FEATURE_CONTACT_GROUPS has been
 * prepared. This remains valid until the main loop is re-entered; if the caller
 * requires a #GStrv that will persist for longer than that, it must be copied
 * with g_strdupv().
 *
 * Returns: (array zero-terminated=1) (transfer none): the same
 *  #GStrv as the #TpContact:contact-groups property
 *
 * Since: 0.13.14
 */
const gchar * const *
tp_contact_get_contact_groups (TpContact *self)
{
  g_return_val_if_fail (TP_IS_CONTACT (self), NULL);

  if (self->priv->contact_groups == NULL)
    return NULL;

  return (const gchar * const *) self->priv->contact_groups->pdata;
}

static void
set_contact_groups_cb (TpConnection *connection,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Failed to set contact groups: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
    }

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/**
 * tp_contact_set_contact_groups_async:
 * @self: a #TpContact
 * @n_groups: the number of groups, or -1 if @groups is %NULL-terminated
 * @groups: (array length=n_groups) (element-type utf8) (allow-none): the set of
 *  groups which the contact should be in (may be %NULL if @n_groups is 0)
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Add @self to the given groups (creating new groups if necessary), and remove
 * it from all other groups. If the user is removed from a group of which they
 * were the only member, the group MAY be removed automatically. You can then
 * call tp_contact_set_contact_groups_finish() to get the result of the
 * operation.
 *
 * If the operation is successful and %TP_CONTACT_FEATURE_CONTACT_GROUPS is
 * prepared, the #TpContact:contact-groups property will be
 * updated (emitting "notify::contact-groups" signal) and
 * #TpContact::contact-groups-changed signal will be emitted before @callback
 * is called. That means you can call tp_contact_get_contact_groups() to get the
 * new contact groups inside @callback.
 *
 * Since: 0.13.14
 */
void
tp_contact_set_contact_groups_async (TpContact *self,
    gint n_groups,
    const gchar * const *groups,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  static const gchar *empty_groups[] = { NULL };
  GSimpleAsyncResult *result;
  gchar **new_groups = NULL;

  g_return_if_fail (TP_IS_CONTACT (self));
  g_return_if_fail (n_groups >= -1);
  g_return_if_fail (n_groups <= 0 || groups != NULL);

  if (groups == NULL)
    {
      groups = empty_groups;
    }
  else if (n_groups > 0)
    {
      /* Create NULL-terminated array */
      new_groups = g_new0 (gchar *, n_groups + 1);
      g_memmove (new_groups, groups, n_groups * sizeof (gchar *));
      groups = (const gchar * const *) new_groups;
    }

  result = g_simple_async_result_new (G_OBJECT (self),
      callback, user_data, tp_contact_set_contact_groups_finish);

  tp_cli_connection_interface_contact_groups_call_set_contact_groups (
      self->priv->connection, -1, self->priv->handle, (const gchar **) groups,
      set_contact_groups_cb, result, NULL, G_OBJECT (self));

  g_free (new_groups);
}

/**
 * tp_contact_set_contact_groups_finish:
 * @self: a #TpContact
 * @result: a #GAsyncResult
 * @error: a #GError to be filled
 *
 * Finishes an async set of @self contact groups.
 *
 * Returns: %TRUE if the request call was successful, otherwise %FALSE
 *
 * Since: 0.13.14
 */
gboolean
tp_contact_set_contact_groups_finish (TpContact *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_contact_set_contact_groups_finish);
}

void
_tp_contact_connection_disposed (TpContact *contact)
{
  /* The connection has gone away, so we no longer have a meaningful handle,
   * and will never have one again. */
  g_assert (contact->priv->handle != 0);
  contact->priv->handle = 0;
  g_object_notify ((GObject *) contact, "handle");
}

static void
tp_contact_dispose (GObject *object)
{
  TpContact *self = TP_CONTACT (object);

  if (self->priv->handle != 0)
    {
      g_assert (self->priv->connection != NULL);

      _tp_connection_remove_contact (self->priv->connection,
          self->priv->handle, self);

      self->priv->handle = 0;
    }

  tp_clear_object (&self->priv->connection);
  tp_clear_pointer (&self->priv->location, g_hash_table_unref);
  tp_clear_object (&self->priv->capabilities);
  tp_clear_object (&self->priv->avatar_file);
  tp_clear_pointer (&self->priv->contact_groups, g_ptr_array_unref);

  ((GObjectClass *) tp_contact_parent_class)->dispose (object);
}


static void
tp_contact_finalize (GObject *object)
{
  TpContact *self = TP_CONTACT (object);

  g_free (self->priv->identifier);
  g_free (self->priv->alias);
  g_free (self->priv->avatar_token);
  g_free (self->priv->avatar_mime_type);
  g_free (self->priv->presence_status);
  g_free (self->priv->presence_message);
  g_strfreev (self->priv->client_types);
  tp_contact_info_list_free (self->priv->contact_info);
  g_free (self->priv->publish_request);

  ((GObjectClass *) tp_contact_parent_class)->finalize (object);
}


static void
tp_contact_get_property (GObject *object,
                         guint property_id,
                         GValue *value,
                         GParamSpec *pspec)
{
  TpContact *self = TP_CONTACT (object);

  switch (property_id)
    {
    case PROP_CONNECTION:
      g_value_set_object (value, self->priv->connection);
      break;

    case PROP_HANDLE:
      g_value_set_uint (value, self->priv->handle);
      break;

    case PROP_IDENTIFIER:
      g_assert (self->priv->identifier != NULL);
      g_value_set_string (value, self->priv->identifier);
      break;

    case PROP_ALIAS:
      /* tp_contact_get_alias actually has some logic, so avoid
       * duplicating it */
      g_value_set_string (value, tp_contact_get_alias (self));
      break;

    case PROP_AVATAR_TOKEN:
      g_value_set_string (value, self->priv->avatar_token);
      break;

    case PROP_AVATAR_FILE:
      g_value_set_object (value, self->priv->avatar_file);
      break;

    case PROP_AVATAR_MIME_TYPE:
      g_value_set_string (value, self->priv->avatar_mime_type);
      break;

    case PROP_PRESENCE_TYPE:
      g_value_set_uint (value, self->priv->presence_type);
      break;

    case PROP_PRESENCE_STATUS:
      g_value_set_string (value, tp_contact_get_presence_status (self));
      break;

    case PROP_PRESENCE_MESSAGE:
      g_value_set_string (value, tp_contact_get_presence_message (self));
      break;

    case PROP_LOCATION:
      g_value_set_boxed (value, tp_contact_get_location (self));
      break;

    case PROP_LOCATION_VARDICT:
      g_value_take_variant (value, tp_contact_dup_location (self));
      break;

    case PROP_CAPABILITIES:
      g_value_set_object (value, tp_contact_get_capabilities (self));
      break;

    case PROP_CONTACT_INFO:
      g_value_set_boxed (value, self->priv->contact_info);
      break;

    case PROP_CLIENT_TYPES:
      g_value_set_boxed (value, tp_contact_get_client_types (self));
      break;

    case PROP_SUBSCRIBE_STATE:
      g_value_set_uint (value, tp_contact_get_subscribe_state (self));
      break;

    case PROP_PUBLISH_STATE:
      g_value_set_uint (value, tp_contact_get_publish_state (self));
      break;

    case PROP_PUBLISH_REQUEST:
      g_value_set_string (value, tp_contact_get_publish_request (self));
      break;

    case PROP_CONTACT_GROUPS:
      g_value_set_boxed (value, tp_contact_get_contact_groups (self));
      break;

    case PROP_IS_BLOCKED:
      g_value_set_boolean (value, tp_contact_is_blocked (self));
      break;

    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}


static void
tp_contact_class_init (TpContactClass *klass)
{
  GObjectClass *object_class = (GObjectClass *) klass;
  GParamSpec *param_spec;

  g_type_class_add_private (klass, sizeof (TpContactPrivate));
  object_class->get_property = tp_contact_get_property;
  object_class->dispose = tp_contact_dispose;
  object_class->finalize = tp_contact_finalize;

  /**
   * TpContact:connection:
   *
   * The #TpConnection to which this contact belongs.
   */
  param_spec = g_param_spec_object ("connection", "TpConnection object",
      "Connection object that owns this channel",
      TP_TYPE_CONNECTION,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONNECTION, param_spec);

  /**
   * TpContact:handle:
   *
   * The contact's handle in the Telepathy D-Bus API, a handle of type
   * %TP_HANDLE_TYPE_CONTACT representing the string
   * given by #TpContact:identifier.
   *
   * This handle is referenced using the Telepathy D-Bus API and remains
   * referenced for as long as the #TpContact exists and the
   * #TpContact:connection remains valid.
   *
   * However, getting this property does not cause an additional reference
   * to the handle to be held.
   *
   * If the #TpContact:connection becomes invalid, this property is no longer
   * meaningful and will be set to 0.
   */
  param_spec = g_param_spec_uint ("handle",
      "Handle",
      "The TP_HANDLE_TYPE_CONTACT handle for this contact",
      0, G_MAXUINT32, 0,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_HANDLE, param_spec);

  /**
   * TpContact:identifier:
   *
   * The contact's identifier in the instant messaging protocol (e.g.
   * XMPP JID, SIP URI, AOL screenname or IRC nick - whatever the underlying
   * protocol uses to identify a user).
   *
   * This is never %NULL for contact objects that are visible to library-user
   * code.
   */
  param_spec = g_param_spec_string ("identifier",
      "IM protocol identifier",
      "The contact's identifier in the instant messaging protocol (e.g. "
        "XMPP JID, SIP URI, AOL screenname or IRC nick)",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_IDENTIFIER, param_spec);

  /**
   * TpContact:alias:
   *
   * The contact's alias if available, falling back to their
   * #TpContact:identifier if no alias is available or if the #TpContact has
   * not been set up to track %TP_CONTACT_FEATURE_ALIAS.
   *
   * This alias may have been supplied by the contact themselves, or by the
   * local user, so it does not necessarily unambiguously identify the contact.
   * However, it is suitable for use as a main "display name" for the contact.
   *
   * This is never %NULL for contact objects that are visible to library-user
   * code.
   */
  param_spec = g_param_spec_string ("alias",
      "Alias",
      "The contact's alias (display name)",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_ALIAS, param_spec);

  /**
   * TpContact:avatar-token:
   *
   * An opaque string representing state of the contact's avatar (depending on
   * the protocol, this might be a hash, a timestamp or something else), or
   * an empty string if there is no avatar.
   *
   * This may be %NULL if it is not known whether this contact has an avatar
   * or not (either for network protocol reasons, or because this #TpContact
   * has not been set up to track %TP_CONTACT_FEATURE_AVATAR_TOKEN).
   */
  param_spec = g_param_spec_string ("avatar-token",
      "Avatar token",
      "Opaque string representing the contact's avatar, or \"\", or NULL",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_AVATAR_TOKEN,
      param_spec);

  /**
   * TpContact:avatar-file:
   *
   * #GFile to the latest cached avatar image, or %NULL if this contact has
   * no avatar, or if the avatar data is not yet retrieved.
   *
   * When #TpContact:avatar-token changes, this property is not updated
   * immediately, but will be updated when the new avatar data is retrieved and
   * stored in cache. Until then, the file will keep its old value of the latest
   * cached avatar image.
   *
   * This is set to %NULL if %TP_CONTACT_FEATURE_AVATAR_DATA is not set on this
   * contact. Note that setting %TP_CONTACT_FEATURE_AVATAR_DATA will also
   * implicitly set %TP_CONTACT_FEATURE_AVATAR_TOKEN.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_object ("avatar-file",
      "Avatar file",
      "File to the latest cached avatar image, or %NULL",
      G_TYPE_FILE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_AVATAR_FILE,
      param_spec);

  /**
   * TpContact:avatar-mime-type:
   *
   * MIME type of the latest cached avatar image, or %NULL if this contact has
   * no avatar, or if the avatar data is not yet retrieved.
   *
   * This is always the MIME type of the image given by #TpContact:avatar-file.
   *
   * Since: 0.11.6
   */
  param_spec = g_param_spec_string ("avatar-mime-type",
      "Avatar MIME type",
      "MIME type of the latest cached avatar image, or %NULL",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_AVATAR_MIME_TYPE,
      param_spec);

  /**
   * TpContact:presence-type:
   *
   * The #TpConnectionPresenceType representing the type of presence status
   * for this contact.
   *
   * This is provided so even unknown values for #TpContact:presence-status
   * can be classified into their fundamental types.
   *
   * This may be %TP_CONNECTION_PRESENCE_TYPE_UNSET if this #TpContact
   * has not been set up to track %TP_CONTACT_FEATURE_PRESENCE.
   */
  param_spec = g_param_spec_uint ("presence-type",
      "Presence type",
      "The TpConnectionPresenceType for this contact",
      0, G_MAXUINT32, TP_CONNECTION_PRESENCE_TYPE_UNSET,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PRESENCE_TYPE,
      param_spec);

  /**
   * TpContact:presence-status:
   *
   * A string representing the presence status of this contact. This may be
   * a well-known string from the Telepathy specification, like "available",
   * or a connection-manager-specific string, like "out-to-lunch".
   *
   * This may be an empty string if this #TpContact object has not been set up
   * to track %TP_CONTACT_FEATURE_PRESENCE. It is never %NULL.
   */
  param_spec = g_param_spec_string ("presence-status",
      "Presence status",
      "Possibly connection-manager-specific string representing the "
        "contact's presence status",
      "",
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PRESENCE_STATUS,
      param_spec);

  /**
   * TpContact:presence-message:
   *
   * If this contact has set a user-defined status message, that message;
   * if not, an empty string (which user interfaces may replace with a
   * localized form of the #TpContact:presence-status or
   * #TpContact:presence-type).
   *
   * This may be an empty string even if the contact has set a message,
   * if this #TpContact object has not been set up to track
   * %TP_CONTACT_FEATURE_PRESENCE. It is never %NULL.
   */
  param_spec = g_param_spec_string ("presence-message",
      "Presence message",
      "User-defined status message, or an empty string",
      "",
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PRESENCE_MESSAGE,
      param_spec);

  /**
   * TpContact:location:
   *
   * If this contact has set a user-defined location, a string to
   * #GValue * hash table containing his location. If not, %NULL.
   * tp_asv_get_string() and similar functions can be used to access
   * the contents.
   *
   * This may be %NULL even if the contact has set a location,
   * if this #TpContact object has not been set up to track
   * %TP_CONTACT_FEATURE_LOCATION.
   *
   * Since: 0.11.1
   */
  param_spec = g_param_spec_boxed ("location",
      "Location",
      "User-defined location, or NULL",
      TP_HASH_TYPE_STRING_VARIANT_MAP,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_LOCATION,
      param_spec);

  /**
   * TpContact:location-vardict:
   *
   * If this contact has set a user-defined location, a string to
   * variant map containing his location. If not, %NULL.
   * tp_vardict_get_string() and similar functions can be used to access
   * the contents.
   *
   * This may be %NULL even if the contact has set a location,
   * if this #TpContact object has not been set up to track
   * %TP_CONTACT_FEATURE_LOCATION.
   *
   * This property contains the same information as #TpContact:location,
   * in a different format.
   *
   * Since: 0.19.10
   */
  param_spec = g_param_spec_variant ("location-vardict",
      "Location",
      "User-defined location, or NULL",
      G_VARIANT_TYPE_VARDICT, NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_LOCATION_VARDICT,
      param_spec);

  /**
   * TpContact:capabilities:
   *
   * The capabilities supported by this contact. If the underlying Connection
   * doesn't support the ContactCapabilities interface, this property will
   * contain the capabilities supported by the connection.
   * Use tp_capabilities_is_specific_to_contact() to check if the capabilities
   * are specific to this #TpContact or not.
   *
   * This may be %NULL if this #TpContact object has not been set up to track
   * %TP_CONTACT_FEATURE_CAPABILITIES.
   *
   * Since: 0.11.3
   */
  param_spec = g_param_spec_object ("capabilities",
      "Capabilities",
      "Capabilities of the contact, or NULL",
      TP_TYPE_CAPABILITIES,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CAPABILITIES,
      param_spec);

  /**
   * TpContact:contact-info:
   *
   * A #GList of #TpContactInfoField representing the vCard of this contact.
   *
   * This is set to %NULL if %TP_CONTACT_FEATURE_CONTACT_INFO is not set on this
   * contact.
   *
   * Since: 0.11.7
   */
  param_spec = g_param_spec_boxed ("contact-info",
      "Contact Info",
      "Information of the contact, or NULL",
      TP_TYPE_CONTACT_INFO_LIST,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONTACT_INFO,
      param_spec);

  /**
   * TpContact:client-types:
   *
   * A #GStrv containing the client types of this contact.
   *
   * This is set to %NULL if %TP_CONTACT_FEATURE_CLIENT_TYPES is not
   * set on this contact; it may also be %NULL if that feature is prepared, but
   * the contact's client types are unknown.
   *
   * Since: 0.13.1
   */
  param_spec = g_param_spec_boxed ("client-types",
      "Client types",
      "Client types of the contact, or NULL",
      G_TYPE_STRV,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CLIENT_TYPES,
      param_spec);

  /**
   * TpContact:subscribe-state:
   *
   * A #TpSubscriptionState indicating the state of the local user's
   * subscription to this contact's presence.
   *
   * This is set to %TP_SUBSCRIPTION_STATE_UNKNOWN until
   * %TP_CONTACT_FEATURE_SUBSCRIPTION_STATES has been prepared
   *
   * Since: 0.13.12
   */
  param_spec = g_param_spec_uint ("subscribe-state",
      "Subscribe State",
      "Subscribe state of the contact",
      0,
      G_MAXUINT,
      TP_SUBSCRIPTION_STATE_UNKNOWN,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_SUBSCRIBE_STATE,
      param_spec);

  /**
   * TpContact:publish-state:
   *
   * A #TpSubscriptionState indicating the state of this contact's subscription
   * to the local user's presence.
   *
   * This is set to %TP_SUBSCRIPTION_STATE_UNKNOWN until
   * %TP_CONTACT_FEATURE_SUBSCRIPTION_STATES has been prepared
   *
   * Since: 0.13.12
   */
  param_spec = g_param_spec_uint ("publish-state",
      "Publish State",
      "Publish state of the contact",
      0,
      G_MAXUINT,
      TP_SUBSCRIPTION_STATE_UNKNOWN,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PUBLISH_STATE,
      param_spec);

  /**
   * TpContact:publish-request:
   *
   * The message that contact sent when they requested permission to see the
   * local user's presence, if #TpContact:publish-state is
   * %TP_SUBSCRIPTION_STATE_ASK, an empty string ("") otherwise.
   *
   * This is set to %NULL until %TP_CONTACT_FEATURE_SUBSCRIPTION_STATES has been
   * prepared, and it is guaranteed to be non-%NULL afterward.
   *
   * Since: 0.13.12
   */
  param_spec = g_param_spec_string ("publish-request",
      "Publish Request",
      "Publish request message of the contact",
      NULL,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_PUBLISH_REQUEST,
      param_spec);

  /**
   * TpContact:contact-groups:
   *
   * a #GStrv with names of groups of which a contact is a member.
   *
   * This is set to %NULL if %TP_CONTACT_FEATURE_CONTACT_GROUPS is not prepared
   * on this contact, or if the connection does not implement ContactGroups
   * interface.
   *
   * Since: 0.13.14
   */
  param_spec = g_param_spec_boxed ("contact-groups",
      "Contact Groups",
      "Groups of the contact",
      G_TYPE_STRV,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_CONTACT_GROUPS,
      param_spec);

/**
   * TpContact:is-blocked:
   *
   * %TRUE if the contact has been blocked.
   *
   * This is set to %FALSE if %TP_CONTACT_FEATURE_CONTACT_BLOCKING is not
   * prepared on this contact, or if the connection does not implement
   * ContactBlocking interface.
   *
   * Since: 0.17.0
   */
  param_spec = g_param_spec_boolean ("is-blocked",
      "is blocked",
      "TRUE if contact is blocked",
      FALSE,
      G_PARAM_READABLE | G_PARAM_STATIC_STRINGS);
  g_object_class_install_property (object_class, PROP_IS_BLOCKED, param_spec);

  /**
   * TpContact::contact-groups-changed:
   * @contact: A #TpContact
   * @added: A #GStrv with added contact groups
   * @removed: A #GStrv with removed contact groups
   *
   * Emitted when this contact's groups changes. When this signal is emitted,
   * #TpContact:contact-groups property is already updated.
   *
   * Since: 0.13.14
   */
  signals[SIGNAL_CONTACT_GROUPS_CHANGED] = g_signal_new (
      "contact-groups-changed",
      G_TYPE_FROM_CLASS (object_class),
      G_SIGNAL_RUN_LAST,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 2, G_TYPE_STRV, G_TYPE_STRV);

  /**
   * TpContact::subscription-states-changed:
   * @contact: a #TpContact
   * @subscribe: the new value of #TpContact:subscribe-state
   * @publish: the new value of #TpContact:publish-state
   * @publish_request: the new value of #TpContact:publish-request
   *
   * Emitted when this contact's subscription states changes.
   *
   * Since: 0.13.12
   */
  signals[SIGNAL_SUBSCRIPTION_STATES_CHANGED] = g_signal_new (
      "subscription-states-changed",
      G_TYPE_FROM_CLASS (object_class),
      G_SIGNAL_RUN_LAST,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 3, G_TYPE_UINT, G_TYPE_UINT, G_TYPE_STRING);

  /**
   * TpContact::presence-changed:
   * @contact: a #TpContact
   * @type: The new value of #TpContact:presence-type
   * @status: The new value of #TpContact:presence-status
   * @message: The new value of #TpContact:presence-message
   *
   * Emitted when this contact's presence changes.
   *
   * Since: 0.11.7
   */
  signals[SIGNAL_PRESENCE_CHANGED] = g_signal_new ("presence-changed",
      G_TYPE_FROM_CLASS (object_class),
      G_SIGNAL_RUN_LAST,
      0,
      NULL, NULL, NULL,
      G_TYPE_NONE, 3, G_TYPE_UINT, G_TYPE_STRING, G_TYPE_STRING);
}

TpContact *
_tp_contact_new (TpConnection *connection,
    TpHandle handle,
    const gchar *identifier)
{
  TpContact *self = TP_CONTACT (g_object_new (TP_TYPE_CONTACT, NULL));

  self->priv->connection = g_object_ref (connection);
  self->priv->handle = handle;
  self->priv->identifier = g_strdup (identifier);

  return self;
}

/* FIXME: Ideally this should be replaced with
 *
 * tp_simple_client_factory_ensure_contact (tp_proxy_get_factory (connection),
 *     handle, identifier);
 *
 * but we cannot assert CM has immortal handles (yet). That means we cannot
 * guarantee that all TpContact objects are created through the factory and so
 * let it make TpContact subclasses.
 */
static TpContact *
tp_contact_ensure (TpConnection *connection,
                   TpHandle handle)
{
  TpContact *self = _tp_connection_lookup_contact (connection, handle);

  if (self != NULL)
    {
      g_assert (self->priv->handle == handle);
      return g_object_ref (self);
    }

  self = _tp_contact_new (connection, handle, NULL);
  _tp_connection_add_contact (connection, handle, self);

  return self;
}

/**
 * tp_connection_dup_contact_if_possible:
 * @connection: a connection
 * @handle: a handle of type %TP_HANDLE_TYPE_CONTACT
 * @identifier: (transfer none): the normalized identifier (XMPP JID, etc.)
 *  corresponding to @handle, or %NULL if not known
 *
 * Try to return an existing contact object or create a new contact object
 * immediately.
 *
 * If tp_connection_has_immortal_handles() would return %TRUE and
 * @identifier is non-%NULL, this function always succeeds.
 *
 * On connections without immortal handles, it is not possible to guarantee
 * that @handle remains valid without making asynchronous D-Bus calls, so
 * it might be necessary to delay processing of messages or other events
 * until a #TpContact can be constructed asynchronously, for instance by using
 * tp_connection_get_contacts_by_id().
 *
 * Similarly, if @identifier is %NULL, it might not be possible to find the
 * identifier for @handle without making asynchronous D-Bus calls, so
 * it might be necessary to delay processing of messages or other events
 * until a #TpContact can be constructed asynchronously, for instance by using
 * tp_connection_get_contacts_by_handle().
 *
 * Returns: (transfer full): a contact or %NULL
 *
 * Since: 0.13.9
 */
TpContact *
tp_connection_dup_contact_if_possible (TpConnection *connection,
    TpHandle handle,
    const gchar *identifier)
{
  TpContact *ret;

  g_return_val_if_fail (TP_IS_CONNECTION (connection), NULL);
  g_return_val_if_fail (handle != 0, NULL);

  ret = _tp_connection_lookup_contact (connection, handle);

  if (ret != NULL && ret->priv->identifier != NULL)
    {
      g_object_ref (ret);
    }
  else if (tp_connection_has_immortal_handles (connection) &&
      identifier != NULL)
    {
      ret = tp_contact_ensure (connection, handle);

      if (ret->priv->identifier == NULL)
        {
          /* new object, I suppose we'll have to believe the caller */
          ret->priv->identifier = g_strdup (identifier);
        }
    }
  else
    {
      /* we don't already have a contact, and we can't make one without
       * D-Bus calls (either because we can't rely on the handle staying
       * static, or we don't know the identifier) */
      return NULL;
    }

  g_assert (ret->priv->handle == handle);

  if (G_UNLIKELY (identifier != NULL &&
        tp_strdiff (ret->priv->identifier, identifier)))
    {
      WARNING ("Either this client, or connection manager %s, is broken: "
          "handle %u is thought to be '%s', but we already have "
          "a TpContact that thinks the identifier is '%s'",
          tp_proxy_get_bus_name (connection), handle, identifier,
          ret->priv->identifier);
      g_object_unref (ret);
      return NULL;
    }

  return ret;
}

static void
tp_contact_init (TpContact *self)
{
  self->priv = G_TYPE_INSTANCE_GET_PRIVATE (self, TP_TYPE_CONTACT,
      TpContactPrivate);

  self->priv->client_types = NULL;
}


typedef struct _ContactsContext ContactsContext;
typedef void (*ContactsProc) (ContactsContext *self);
typedef enum { CB_BY_HANDLE, CB_BY_ID, CB_UPGRADE } ContactsSignature;

static const gchar *
contacts_signature_to_string (ContactsSignature sig)
{
  switch (sig)
    {
      case CB_BY_HANDLE:
        return "by handle";
      case CB_BY_ID:
        return "by ID";
      case CB_UPGRADE:
        return "upgrade";
      default:
        return "???";
    }
}

struct _ContactsContext {
    gsize refcount;

    /* owned */
    TpConnection *connection;
    /* array of owned TpContact; preallocated but empty until handles have
     * been held or requested */
    GPtrArray *contacts;
    /* array of handles; empty until RequestHandles has returned, if we
     * started from IDs */
    GArray *handles;
    /* array of handles; empty until RequestHandles has returned, if we
     * started from IDs */
    GArray *invalid;

    /* strv of IDs; NULL unless we started from IDs */
    GPtrArray *request_ids;
    /* ID => GError, NULL unless we started from IDs */
    GHashTable *request_errors;

    /* features we need to get, if possible, before this request can finish */
    ContactFeatureFlags wanted;

    /* features we can expect to get from GetContactAttributes
     * (subset of wanted) */
    ContactFeatureFlags getting;

    /* callback for when we've finished, plus the usual misc */
    ContactsSignature signature;
    union {
        TpConnectionContactsByHandleCb by_handle;
        TpConnectionContactsByIdCb by_id;
        TpConnectionUpgradeContactsCb upgrade;
    } callback;
    gpointer user_data;
    GDestroyNotify destroy;
    GObject *weak_object;

    /* Whether or not our weak object died*/
    gboolean no_purpose_in_life;

    /* queue of ContactsProc */
    GQueue todo;

    /* index into handles or ids, only used when the first HoldHandles call
     * failed with InvalidHandle, or the RequestHandles call failed with
     * NotAvailable */
    guint next_index;

    /* TRUE if all contacts already have IDs */
    gboolean contacts_have_ids;
};

/* This code (and lots of telepathy-glib, really) won't work if this
 * assertion fails, because we put function pointers in a GQueue. If anyone
 * cares about platforms where this fails, fixing this would involve
 * slice-allocating sizeof (GCallback) bytes repeatedly, and putting *those*
 * in the queue. */
G_STATIC_ASSERT (sizeof (GCallback) == sizeof (gpointer));

static void
contacts_context_weak_notify (gpointer data,
  GObject *dead)
{
  ContactsContext *c = data;

  g_assert (c->weak_object == dead);
  c->no_purpose_in_life = TRUE;
  c->weak_object = NULL;
}

static ContactsContext *
contacts_context_new (TpConnection *connection,
                      guint n_contacts,
                      ContactFeatureFlags want_features,
                      ContactsSignature signature,
                      gpointer user_data,
                      GDestroyNotify destroy,
                      GObject *weak_object)
{
  ContactsContext *c = g_slice_new0 (ContactsContext);

  DEBUG ("%p, for %u contacts, %s", c, n_contacts,
      contacts_signature_to_string (signature));

  DEBUG ("want alias: %s",
      (want_features & CONTACT_FEATURE_FLAG_ALIAS) ? "yes" : "no");
  DEBUG ("want avatar token: %s",
      (want_features & CONTACT_FEATURE_FLAG_AVATAR_TOKEN) ? "yes" : "no");
  DEBUG ("want presence: %s",
      (want_features & CONTACT_FEATURE_FLAG_PRESENCE) ? "yes" : "no");
  DEBUG ("want location: %s",
      (want_features & CONTACT_FEATURE_FLAG_LOCATION) ? "yes" : "no");
  DEBUG ("want caps: %s",
      (want_features & CONTACT_FEATURE_FLAG_CAPABILITIES) ? "yes" : "no");
  DEBUG ("want avatar data: %s",
      (want_features & CONTACT_FEATURE_FLAG_AVATAR_DATA) ? "yes" : "no");
  DEBUG ("want contact info: %s",
      (want_features & CONTACT_FEATURE_FLAG_CONTACT_INFO) ? "yes" : "no");
  DEBUG ("want client types: %s",
      (want_features & CONTACT_FEATURE_FLAG_CLIENT_TYPES) ? "yes" : "no");
  DEBUG ("want states: %s",
      (want_features & CONTACT_FEATURE_FLAG_STATES) ? "yes" : "no");
  DEBUG ("want contact groups: %s",
      (want_features & CONTACT_FEATURE_FLAG_CONTACT_GROUPS) ? "yes" : "no");
  DEBUG ("want contact blocking: %s",
      (want_features & CONTACT_FEATURE_FLAG_CONTACT_BLOCKING) ? "yes" : "no");

  c->refcount = 1;
  c->connection = g_object_ref (connection);
  c->contacts = g_ptr_array_sized_new (n_contacts);
  c->handles = g_array_sized_new (FALSE, FALSE, sizeof (TpHandle), n_contacts);
  c->invalid = g_array_sized_new (FALSE, FALSE, sizeof (TpHandle), n_contacts);

  c->wanted = want_features;
  c->signature = signature;
  c->user_data = user_data;
  c->destroy = destroy;
  c->weak_object = weak_object;

  if (c->weak_object != NULL)
    g_object_weak_ref (c->weak_object, contacts_context_weak_notify, c);

  g_queue_init (&c->todo);

  return c;
}


static void
contacts_context_unref (gpointer p)
{
  ContactsContext *c = p;

  if ((--c->refcount) > 0)
    return;

  DEBUG ("last-unref (%p)", c);

  g_assert (c->connection != NULL);
  tp_clear_object (&c->connection);

  g_queue_clear (&c->todo);

  g_assert (c->contacts != NULL);
  g_ptr_array_foreach (c->contacts, (GFunc) g_object_unref, NULL);
  g_ptr_array_unref (c->contacts);
  c->contacts = NULL;

  g_assert (c->handles != NULL);
  g_array_unref (c->handles);
  c->handles = NULL;

  g_assert (c->invalid != NULL);
  g_array_unref (c->invalid);
  c->invalid = NULL;

  if (c->request_ids != NULL)
    g_strfreev ((gchar **) g_ptr_array_free (c->request_ids, FALSE));

  c->request_ids = NULL;

  tp_clear_pointer (&c->request_errors, g_hash_table_unref);

  if (c->destroy != NULL)
    c->destroy (c->user_data);

  c->destroy = NULL;
  c->user_data = NULL;

  if (c->weak_object != NULL)
    g_object_weak_unref (c->weak_object, contacts_context_weak_notify, c);
  c->weak_object = NULL;

  g_slice_free (ContactsContext, c);
}


static void
contacts_context_fail (ContactsContext *c,
                       const GError *error)
{
  guint i;

  switch (c->signature)
    {
    case CB_BY_HANDLE:
      g_array_append_vals (c->invalid, c->handles->data, c->handles->len);

      c->callback.by_handle (c->connection, 0, NULL,
          c->invalid->len, (const TpHandle *) c->invalid->data,
          error, c->user_data, c->weak_object);
      return;
    case CB_BY_ID:
      /* -1 because NULL terminator is explicit */
      for (i = 0; i < c->request_ids->len - 1; i++)
        {
          const gchar *id = g_ptr_array_index (c->request_ids, i);

          if (!g_hash_table_lookup (c->request_errors, id))
            {
              g_hash_table_insert (c->request_errors,
                  g_strdup (id), g_error_copy (error));
            }
        }

      c->callback.by_id (c->connection, 0, NULL, NULL,
          c->request_errors, error, c->user_data, c->weak_object);
      return;
    case CB_UPGRADE:
      c->callback.upgrade (c->connection,
          c->contacts->len, (TpContact * const *) c->contacts->pdata,
          error, c->user_data, c->weak_object);
      return;
    default:
      g_assert_not_reached ();
    }
}


/**
 * TpConnectionContactsByHandleCb:
 * @connection: The connection
 * @n_contacts: The number of TpContact objects successfully created
 *  (one per valid handle), or 0 on unrecoverable errors
 * @contacts: (array length=n_contacts): An array of @n_contacts TpContact
 *  objects (this callback is not given a reference to any of these objects,
 *  and must call g_object_ref() on any that it will keep), or %NULL on
 *  unrecoverable errors
 * @n_failed: The number of invalid handles that were passed to
 *  tp_connection_get_contacts_by_handle() (or on unrecoverable errors,
 *  the total number of handles that were given)
 * @failed: (array length=n_failed): An array of @n_failed handles that were
 *  passed to tp_connection_get_contacts_by_handle() but turned out to be
 *  invalid (or on unrecoverable errors, all the handles that were given)
 * @error: %NULL on success, or an unrecoverable error that caused everything
 *  to fail
 * @user_data: the @user_data that was passed to
 *  tp_connection_get_contacts_by_handle()
 * @weak_object: the @weak_object that was passed to
 *  tp_connection_get_contacts_by_handle()
 *
 * Signature of a callback used to receive the result of
 * tp_connection_get_contacts_by_handle().
 *
 * If an unrecoverable error occurs (for instance, if @connection
 * becomes disconnected) the whole operation fails, and no contacts or
 * invalid handles are returned.
 *
 * If some or even all of the @handles passed to
 * tp_connection_get_contacts_by_handle() were not valid, this is not
 * considered to be a failure. @error will be %NULL in this situation,
 * @contacts will contain contact objects for those handles that were
 * valid (possibly none of them), and @invalid will contain the handles
 * that were not valid.
 *
 * Since: 0.7.18
 */

/**
 * TpConnectionContactsByIdCb:
 * @connection: The connection
 * @n_contacts: The number of TpContact objects successfully created
 *  (one per valid ID), or 0 on unrecoverable errors
 * @contacts: (array length=n_contacts): An array of @n_contacts TpContact
 *  objects (this callback is
 *  not given a reference to any of these objects, and must call
 *  g_object_ref() on any that it will keep), or %NULL on unrecoverable errors
 * @requested_ids: (array length=n_contacts): An array of @n_contacts valid IDs
 *  (JIDs, SIP URIs etc.)
 *  that were passed to tp_connection_get_contacts_by_id(), in an order
 *  corresponding to @contacts, or %NULL on unrecoverable errors
 * @failed_id_errors: (element-type utf8 GLib.Error): A hash table in which
 *  the keys are IDs and the values are errors (#GError)
 * @error: %NULL on success, or an unrecoverable error that caused everything
 *  to fail
 * @user_data: the @user_data that was passed to
 *  tp_connection_get_contacts_by_id()
 * @weak_object: the @weak_object that was passed to
 *  tp_connection_get_contacts_by_id()
 *
 * Signature of a callback used to receive the result of
 * tp_connection_get_contacts_by_id().
 *
 * @requested_ids contains the IDs that were converted to handles successfully.
 * The normalized form of requested_ids[i] is
 * tp_contact_get_identifier (contacts[i]).
 *
 * If some or even all of the @ids passed to
 * tp_connection_get_contacts_by_id() were not valid, this is not
 * considered to be a fatal error. @error will be %NULL in this situation,
 * @contacts will contain contact objects for those IDs that were
 * valid (it may be empty), and @failed_id_errors will map the IDs
 * that were not valid to a corresponding #GError (if the connection manager
 * complies with the Telepathy spec, it will have domain %TP_ERROR and code
 * %TP_ERROR_INVALID_HANDLE).
 *
 * If an unrecoverable error occurs (for instance, if @connection
 * becomes disconnected) the whole operation fails, and no contacts
 * or requested IDs are returned. @failed_id_errors will contain all the IDs
 * that were requested, mapped to a corresponding #GError (either one
 * indicating that the ID was invalid, if that was determined before the
 * fatal error occurred, or a copy of @error).
 *
 * Since: 0.7.18
 */

/**
 * TpConnectionUpgradeContactsCb:
 * @connection: The connection
 * @n_contacts: The number of TpContact objects for which an upgrade was
 *  requested
 * @contacts: (array length=n_contacts): An array of @n_contacts TpContact
 *  objects (this callback is
 *  not given an extra reference to any of these objects, and must call
 *  g_object_ref() on any that it will keep)
 * @error: An unrecoverable error, or %NULL if the connection remains valid
 * @user_data: the @user_data that was passed to
 *  tp_connection_upgrade_contacts()
 * @weak_object: the @weak_object that was passed to
 *  tp_connection_upgrade_contacts()
 *
 * Signature of a callback used to receive the result of
 * tp_connection_upgrade_contacts().
 *
 * If an unrecoverable error occurs (for instance, if @connection becomes
 * disconnected) it is indicated by @error, but the contacts in @contacts
 * are still provided.
 *
 * Since: 0.7.18
 */


static void
contacts_context_continue (ContactsContext *c)
{
  if (c->no_purpose_in_life)
    {
      DEBUG ("%p: no purpose in life", c);
      return;
    }

  if (g_queue_is_empty (&c->todo))
    {
      /* do some final sanity checking then hand over the contacts to the
       * library user */
      guint i;

      DEBUG ("%p: nothing more to do", c);

      g_assert (c->contacts != NULL);
      g_assert (c->invalid != NULL);

      for (i = 0; i < c->contacts->len; i++)
        {
          TpContact *contact = TP_CONTACT (g_ptr_array_index (c->contacts, i));

          g_assert (contact->priv->identifier != NULL);
          g_assert (contact->priv->handle != 0);
        }

      switch (c->signature)
        {
        case CB_BY_HANDLE:
          c->callback.by_handle (c->connection,
              c->contacts->len, (TpContact * const *) c->contacts->pdata,
              c->invalid->len, (const TpHandle *) c->invalid->data,
              NULL, c->user_data, c->weak_object);
          break;
        case CB_BY_ID:
          c->callback.by_id (c->connection,
              c->contacts->len, (TpContact * const *) c->contacts->pdata,
              (const gchar * const *) c->request_ids->pdata,
              c->request_errors, NULL, c->user_data, c->weak_object);
          break;
        case CB_UPGRADE:
          c->callback.upgrade (c->connection,
              c->contacts->len, (TpContact * const *) c->contacts->pdata,
              NULL, c->user_data, c->weak_object);
          break;
        default:
          g_assert_not_reached ();
        }
    }
  else
    {
      /* bah! */
      ContactsProc next = g_queue_pop_head (&c->todo);

      if (G_UNLIKELY (tp_proxy_get_invalidated (c->connection) != NULL))
        {
          DEBUG ("%p: failing due to connection having been invalidated: %s",
              c, tp_proxy_get_invalidated (c->connection)->message);
          contacts_context_fail (c, tp_proxy_get_invalidated (c->connection));
        }
      else
        {
          DEBUG ("%p: on to the next thing", c);
          next (c);
        }
    }
}

static gboolean
contacts_context_idle_continue (gpointer data)
{
  contacts_context_continue (data);
  return FALSE;
}

static void
contacts_held_one (TpConnection *connection,
                   TpHandleType handle_type,
                   guint n_handles,
                   const TpHandle *handles,
                   const GError *error,
                   gpointer user_data,
                   GObject *weak_object)
{
  ContactsContext *c = user_data;

  g_assert (handle_type == TP_HANDLE_TYPE_CONTACT);
  g_assert (c->next_index < c->handles->len);

  if (error == NULL)
    {
      /* I have a handle of my very own. Just what I always wanted! */
      TpContact *contact;

      g_assert (n_handles == 1);
      g_assert (handles[0] != 0);
      g_debug ("%u vs %u", g_array_index (c->handles, TpHandle, c->next_index),
          handles[0]);
      g_assert (g_array_index (c->handles, TpHandle, c->next_index)
          == handles[0]);

      contact = tp_contact_ensure (connection, handles[0]);
      g_ptr_array_add (c->contacts, contact);
      c->next_index++;
    }
  else if (error->domain == TP_ERROR &&
      error->code == TP_ERROR_INVALID_HANDLE)
    {
      g_array_append_val (c->invalid,
          g_array_index (c->handles, TpHandle, c->next_index));
      /* ignore the bad handle - we just won't return a TpContact for it */
      g_array_remove_index_fast (c->handles, c->next_index);
      /* do not increment next_index - another handle has been moved into that
       * position */
    }
  else
    {
      /* the connection fell down a well or something */
      contacts_context_fail (c, error);
      return;
    }

  /* Either continue to hold handles, or proceed along the slow path. */
  contacts_context_continue (c);
}


static void
contacts_hold_one (ContactsContext *c)
{
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  c->refcount++;
  tp_connection_hold_handles (c->connection, -1,
      TP_HANDLE_TYPE_CONTACT, 1,
      &g_array_index (c->handles, TpHandle, c->next_index),
      contacts_held_one, c, contacts_context_unref, c->weak_object);
  G_GNUC_END_IGNORE_DEPRECATIONS
}


static void
contacts_held_handles (TpConnection *connection,
                       TpHandleType handle_type,
                       guint n_handles,
                       const TpHandle *handles,
                       const GError *error,
                       gpointer user_data,
                       GObject *weak_object)
{
  ContactsContext *c = user_data;

  g_assert (handle_type == TP_HANDLE_TYPE_CONTACT);
  g_assert (weak_object == c->weak_object);

  if (error == NULL)
    {
      /* I now own all n handles. It's like Christmas morning! */
      guint i;

      g_assert (n_handles == c->handles->len);
      g_assert (c->contacts->len == 0);

      for (i = 0; i < c->handles->len; i++)
        {
          g_ptr_array_add (c->contacts,
              tp_contact_ensure (connection,
                g_array_index (c->handles, TpHandle, i)));
        }
    }
  else if (error->domain == TP_ERROR &&
      error->code == TP_ERROR_INVALID_HANDLE)
    {
      /* One of the handles is bad. We don't know which one :-( so split
       * the batch into a chain of calls. */
      guint i;

      for (i = 0; i < c->handles->len; i++)
        {
          g_queue_push_head (&c->todo, contacts_hold_one);
        }

      g_assert (c->next_index == 0);
    }
  else
    {
      /* the connection fell down a well or something */
      contacts_context_fail (c, error);
      return;
    }

  /* Either hold the handles individually, or proceed along the slow path. */
  contacts_context_continue (c);
}


static void
contacts_inspected (TpConnection *connection,
                    const gchar **ids,
                    const GError *error,
                    gpointer user_data,
                    GObject *weak_object)
{
  ContactsContext *c = user_data;

  g_assert (weak_object == c->weak_object);
  g_assert (c->handles->len == c->contacts->len);

  if (error != NULL)
    {
      /* the connection fell down a well or something */
      contacts_context_fail (c, error);
      return;
    }
  else if (G_UNLIKELY (g_strv_length ((GStrv) ids) != c->handles->len))
    {
      GError *e = g_error_new (TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
          "Connection manager %s is broken: we inspected %u "
          "handles but InspectHandles returned %u strings",
          tp_proxy_get_bus_name (connection), c->handles->len,
          g_strv_length ((GStrv) ids));

      WARNING ("%s", e->message);
      contacts_context_fail (c, e);
      g_error_free (e);
      return;
    }
  else
    {
      guint i;

      DEBUG ("%p: inspected %u handles", c, c->contacts->len);

      for (i = 0; i < c->contacts->len; i++)
        {
          TpContact *contact = g_ptr_array_index (c->contacts, i);

          g_assert (ids[i] != NULL);

          DEBUG ("- #%u: \"%s\"", contact->priv->handle, ids[i]);

          if (contact->priv->identifier == NULL)
            {
              contact->priv->identifier = g_strdup (ids[i]);
            }
          else if (tp_strdiff (contact->priv->identifier, ids[i]))
            {
              GError *e = g_error_new (TP_DBUS_ERRORS,
                  TP_DBUS_ERROR_INCONSISTENT,
                  "Connection manager %s is broken: contact handle %u "
                  "identifier changed from %s to %s",
                  tp_proxy_get_bus_name (connection), contact->priv->handle,
                  contact->priv->identifier, ids[i]);

              WARNING ("%s", e->message);
              contacts_context_fail (c, e);
              g_error_free (e);
              return;
            }
        }
    }

  contacts_context_continue (c);
}


static void
contacts_inspect (ContactsContext *c)
{
  guint i;

  g_assert (c->handles->len == c->contacts->len);

  for (i = 0; i < c->contacts->len; i++)
    {
      TpContact *contact = g_ptr_array_index (c->contacts, i);

      if (contact->priv->identifier == NULL)
        {
          c->refcount++;
          tp_cli_connection_call_inspect_handles (c->connection, -1,
              TP_HANDLE_TYPE_CONTACT, c->handles, contacts_inspected,
              c, contacts_context_unref, c->weak_object);
          return;
        }
    }

  /* else there's no need to inspect the contacts' handles, because we already
   * know all their identifiers */
  contacts_context_continue (c);
}


static void
contacts_requested_aliases (TpConnection *connection,
                            const gchar **aliases,
                            const GError *error,
                            gpointer user_data,
                            GObject *weak_object)
{
  ContactsContext *c = user_data;

  g_assert (c->handles->len == c->contacts->len);

  if (error == NULL)
    {
      guint i;

      if (G_UNLIKELY (g_strv_length ((GStrv) aliases) != c->contacts->len))
        {
          WARNING ("Connection manager %s is broken: we requested %u "
              "handles' aliases but got %u strings back",
              tp_proxy_get_bus_name (connection), c->contacts->len,
              g_strv_length ((GStrv) aliases));

          /* give up on the possibility of getting aliases, and just
           * move on */
          contacts_context_continue (c);
          return;
        }

      for (i = 0; i < c->contacts->len; i++)
        {
          TpContact *contact = g_ptr_array_index (c->contacts, i);
          const gchar *alias = aliases[i];

          contact->priv->has_features |= CONTACT_FEATURE_FLAG_ALIAS;
          g_free (contact->priv->alias);
          contact->priv->alias = g_strdup (alias);
          g_object_notify ((GObject *) contact, "alias");
        }
    }
  else
    {
      /* never mind, we can live without aliases */
      DEBUG ("GetAliases failed with %s %u: %s",
          g_quark_to_string (error->domain), error->code, error->message);
    }

  contacts_context_continue (c);
}


static void
contacts_got_aliases (TpConnection *connection,
                      GHashTable *handle_to_alias,
                      const GError *error,
                      gpointer user_data,
                      GObject *weak_object)
{
  ContactsContext *c = user_data;

  if (error == NULL)
    {
      guint i;

      for (i = 0; i < c->contacts->len; i++)
        {
          TpContact *contact = g_ptr_array_index (c->contacts, i);
          const gchar *alias = g_hash_table_lookup (handle_to_alias,
              GUINT_TO_POINTER (contact->priv->handle));

          contact->priv->has_features |= CONTACT_FEATURE_FLAG_ALIAS;
          g_free (contact->priv->alias);
          contact->priv->alias = NULL;

          if (alias != NULL)
            {
              contact->priv->alias = g_strdup (alias);
            }
          else
            {
              WARNING ("No alias returned for %u, will use ID instead",
                  contact->priv->handle);
            }

          g_object_notify ((GObject *) contact, "alias");
        }
    }
  else if ((error->domain == TP_ERROR &&
      error->code == TP_ERROR_NOT_IMPLEMENTED) ||
      (error->domain == DBUS_GERROR &&
       error->code == DBUS_GERROR_UNKNOWN_METHOD))
    {
      /* GetAliases not implemented, fall back to (slow?) RequestAliases */
      c->refcount++;
      tp_cli_connection_interface_aliasing_call_request_aliases (connection,
          -1, c->handles, contacts_requested_aliases,
          c, contacts_context_unref, weak_object);
      return;
    }
  else
    {
      /* never mind, we can live without aliases */
      DEBUG ("GetAliases failed with %s %u: %s",
          g_quark_to_string (error->domain), error->code, error->message);
    }

  contacts_context_continue (c);
}


static void
contacts_aliases_changed (TpConnection *connection,
                          const GPtrArray *alias_structs,
                          gpointer user_data G_GNUC_UNUSED,
                          GObject *weak_object G_GNUC_UNUSED)
{
  guint i;

  for (i = 0; i < alias_structs->len; i++)
    {
      GValueArray *pair = g_ptr_array_index (alias_structs, i);
      TpHandle handle = g_value_get_uint (pair->values + 0);
      const gchar *alias = g_value_get_string (pair->values + 1);
      TpContact *contact = _tp_connection_lookup_contact (connection, handle);

      if (contact != NULL)
        {
          contact->priv->has_features |= CONTACT_FEATURE_FLAG_ALIAS;
          DEBUG ("Contact \"%s\" alias changed from \"%s\" to \"%s\"",
              contact->priv->identifier, contact->priv->alias, alias);
          g_free (contact->priv->alias);
          contact->priv->alias = g_strdup (alias);
          g_object_notify ((GObject *) contact, "alias");
        }
    }
}


static void
contacts_bind_to_aliases_changed (TpConnection *connection)
{
  if (!connection->priv->tracking_aliases_changed)
    {
      connection->priv->tracking_aliases_changed = TRUE;

      tp_cli_connection_interface_aliasing_connect_to_aliases_changed (
          connection, contacts_aliases_changed, NULL, NULL, NULL, NULL);
    }
}


static void
contacts_get_aliases (ContactsContext *c)
{
  guint i;

  g_assert (c->handles->len == c->contacts->len);

  contacts_bind_to_aliases_changed (c->connection);

  for (i = 0; i < c->contacts->len; i++)
    {
      TpContact *contact = g_ptr_array_index (c->contacts, i);

      if ((contact->priv->has_features & CONTACT_FEATURE_FLAG_ALIAS) == 0)
        {
          c->refcount++;
          tp_cli_connection_interface_aliasing_call_get_aliases (c->connection,
              -1, c->handles, contacts_got_aliases, c, contacts_context_unref,
              c->weak_object);
          return;
        }
    }

  /* else there's no need to get the contacts' aliases, because we already
   * know them all */
  contacts_context_continue (c);
}


static void
contact_maybe_set_simple_presence (TpContact *contact,
                                   GValueArray *presence)
{
  guint type;
  const gchar *status;
  const gchar *message;

  if (contact == NULL)
    return;

  g_return_if_fail (presence != NULL);
  contact->priv->has_features |= CONTACT_FEATURE_FLAG_PRESENCE;

  tp_value_array_unpack (presence, 3, &type, &status, &message);

  contact->priv->presence_type = type;

  g_free (contact->priv->presence_status);
  contact->priv->presence_status = g_strdup (status);

  g_free (contact->priv->presence_message);
  contact->priv->presence_message = g_strdup (message);

  g_object_notify ((GObject *) contact, "presence-type");
  g_object_notify ((GObject *) contact, "presence-status");
  g_object_notify ((GObject *) contact, "presence-message");

  g_signal_emit (contact, signals[SIGNAL_PRESENCE_CHANGED], 0,
      contact->priv->presence_type,
      contact->priv->presence_status,
      contact->priv->presence_message);
}

static void
contact_maybe_set_location (TpContact *self,
    GHashTable *location)
{
  if (self == NULL)
    return;

  if (self->priv->location != NULL)
    g_hash_table_unref (self->priv->location);

  /* We guarantee that, if we've fetched a location for a contact, the
   * :location property is non-NULL. This is mainly because Empathy assumed
   * this and would crash if not.
   */
  if (location == NULL)
    location = tp_asv_new (NULL, NULL);
  else
    g_hash_table_ref (location);

  self->priv->has_features |= CONTACT_FEATURE_FLAG_LOCATION;
  self->priv->location = location;
  g_object_notify ((GObject *) self, "location");
  g_object_notify ((GObject *) self, "location-vardict");
}

static void
contact_set_capabilities (TpContact *self,
    TpCapabilities *capabilities)
{
  tp_clear_object (&self->priv->capabilities);

  self->priv->has_features |= CONTACT_FEATURE_FLAG_CAPABILITIES;
  self->priv->capabilities = g_object_ref (capabilities);
  g_object_notify ((GObject *) self, "capabilities");
}

static void
contact_maybe_set_capabilities (TpContact *self,
    GPtrArray *arr)
{
  TpCapabilities *capabilities;

  if (self == NULL || arr == NULL)
    return;

  capabilities = _tp_capabilities_new (arr, TRUE);
  contact_set_capabilities (self, capabilities);
  g_object_unref (capabilities);
}


static void
contacts_presences_changed (TpConnection *connection,
                            GHashTable *presences,
                            gpointer user_data G_GNUC_UNUSED,
                            GObject *weak_object G_GNUC_UNUSED)
{
  GHashTableIter iter;
  gpointer key, value;

  g_hash_table_iter_init (&iter, presences);

  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      TpContact *contact = _tp_connection_lookup_contact (connection,
          GPOINTER_TO_UINT (key));

      contact_maybe_set_simple_presence (contact, value);
    }
}


static void
contacts_got_simple_presence (TpConnection *connection,
                              GHashTable *presences,
                              const GError *error,
                              gpointer user_data,
                              GObject *weak_object)
{
  ContactsContext *c = user_data;

  if (error == NULL)
    {
      contacts_presences_changed (connection, presences, NULL, NULL);
    }
  else
    {
      /* never mind, we can live without presences */
      DEBUG ("GetPresences failed with %s %u: %s",
          g_quark_to_string (error->domain), error->code, error->message);
    }

  contacts_context_continue (c);
}


static void
contacts_bind_to_presences_changed (TpConnection *connection)
{
  if (!connection->priv->tracking_presences_changed)
    {
      connection->priv->tracking_presences_changed = TRUE;

      tp_cli_connection_interface_simple_presence_connect_to_presences_changed
        (connection, contacts_presences_changed, NULL, NULL, NULL, NULL);
    }
}

static void
contacts_get_simple_presence (ContactsContext *c)
{
  guint i;

  g_assert (c->handles->len == c->contacts->len);

  contacts_bind_to_presences_changed (c->connection);

  for (i = 0; i < c->contacts->len; i++)
    {
      TpContact *contact = g_ptr_array_index (c->contacts, i);

      if ((contact->priv->has_features & CONTACT_FEATURE_FLAG_PRESENCE) == 0)
        {
          c->refcount++;
          tp_cli_connection_interface_simple_presence_call_get_presences (
              c->connection, -1,
              c->handles, contacts_got_simple_presence,
              c, contacts_context_unref, c->weak_object);
          return;
        }
    }

  contacts_context_continue (c);
}

static void
contacts_location_updated (TpConnection *connection,
    guint handle,
    GHashTable *location,
    gpointer user_data G_GNUC_UNUSED,
    GObject *weak_object G_GNUC_UNUSED)
{
  TpContact *contact = _tp_connection_lookup_contact (connection,
          GPOINTER_TO_UINT (handle));

  contact_maybe_set_location (contact, location);
}

static void
contacts_bind_to_location_updated (TpConnection *connection)
{
  if (!connection->priv->tracking_location_changed)
    {
      connection->priv->tracking_location_changed = TRUE;

      tp_cli_connection_interface_location_connect_to_location_updated
        (connection, contacts_location_updated, NULL, NULL, NULL, NULL);

      tp_connection_add_client_interest (connection,
          TP_IFACE_CONNECTION_INTERFACE_LOCATION);
    }
}

static void
contact_maybe_set_client_types (TpContact *self,
    const gchar * const *types)
{
  if (self == NULL)
    return;

  if (self->priv->client_types != NULL)
    g_strfreev (self->priv->client_types);

  self->priv->has_features |= CONTACT_FEATURE_FLAG_CLIENT_TYPES;
  self->priv->client_types = g_strdupv ((gchar **) types);
  g_object_notify ((GObject *) self, "client-types");
}

static void
contacts_client_types_updated (TpConnection *connection,
    guint handle,
    const gchar **types,
    gpointer user_data G_GNUC_UNUSED,
    GObject *weak_object G_GNUC_UNUSED)
{
  TpContact *contact = _tp_connection_lookup_contact (connection,
          GPOINTER_TO_UINT (handle));

  contact_maybe_set_client_types (contact, types);
}

static void
contacts_bind_to_client_types_updated (TpConnection *connection)
{
  if (!connection->priv->tracking_client_types_updated)
    {
      connection->priv->tracking_client_types_updated = TRUE;

      tp_cli_connection_interface_client_types_connect_to_client_types_updated
        (connection, contacts_client_types_updated, NULL, NULL, NULL, NULL);
    }
}

static void
set_conn_capabilities_on_contacts (GPtrArray *contacts,
    TpConnection *connection)
{
  guint i;
  TpCapabilities *conn_caps = tp_connection_get_capabilities (connection);
  GPtrArray *rcc;

  /* If the connection has no capabilities then don't bother setting them on
   * the contact and pretend we just don't know.. In practise this will only
   * happen if there was an error in getting the connections capabilities so
   * claiming ignorance seems the most sensible thing to do */
  if (conn_caps == NULL)
     return;

  rcc = tp_capabilities_get_channel_classes (conn_caps);
  if (rcc == NULL || rcc->len == 0)
    return;

  for (i = 0; i < contacts->len; i++)
    {
      TpContact *contact = g_ptr_array_index (contacts, i);

      contact_set_capabilities (contact, conn_caps);
    }
}

static void
connection_capabilities_fetched_cb (GObject *object,
    GAsyncResult *res,
    gpointer user_data)
{
  ContactsContext *c = user_data;

  DEBUG ("Connection capabilities prepared");

  set_conn_capabilities_on_contacts (c->contacts, c->connection);
  contacts_context_continue (c);
  contacts_context_unref (c);
}

static void
contacts_get_conn_capabilities (ContactsContext *c)
{
  g_assert (c->handles->len == c->contacts->len);

  DEBUG ("Getting connection capabilities");

  c->refcount++;
  _tp_connection_get_capabilities_async (c->connection,
    connection_capabilities_fetched_cb, c);
}

static void
contacts_capabilities_updated (TpConnection *connection,
    GHashTable *capabilities,
    gpointer user_data G_GNUC_UNUSED,
    GObject *weak_object G_GNUC_UNUSED)
{
  GHashTableIter iter;
  gpointer handle, value;

  g_hash_table_iter_init (&iter, capabilities);
  while (g_hash_table_iter_next (&iter, &handle, &value))
    {
      TpContact *contact = _tp_connection_lookup_contact (connection,
              GPOINTER_TO_UINT (handle));

      contact_maybe_set_capabilities (contact, value);
    }
}

static void
contacts_bind_to_capabilities_updated (TpConnection *connection)
{
  if (!connection->priv->tracking_contact_caps_changed)
    {
      connection->priv->tracking_contact_caps_changed = TRUE;

      tp_cli_connection_interface_contact_capabilities_connect_to_contact_capabilities_changed
        (connection, contacts_capabilities_updated, NULL, NULL, NULL, NULL);
    }
}

static gboolean
build_avatar_filename (TpConnection *connection,
    const gchar *avatar_token,
    gboolean create_dir,
    gchar **ret_filename,
    gchar **ret_mime_filename)
{
  gchar *dir;
  gchar *token_escaped;
  gboolean success = TRUE;

  token_escaped = tp_escape_as_identifier (avatar_token);
  dir = g_build_filename (g_get_user_cache_dir (),
      "telepathy", "avatars",
      tp_connection_get_cm_name (connection),
      tp_connection_get_protocol_name (connection),
      NULL);

  if (create_dir)
    {
      if (g_mkdir_with_parents (dir, 0700) == -1)
        {
          DEBUG ("Error creating avatar cache dir: %s", g_strerror (errno));
          success = FALSE;
          goto out;
        }
    }

  if (ret_filename != NULL)
    *ret_filename = g_strconcat (dir, G_DIR_SEPARATOR_S, token_escaped, NULL);

  if (ret_mime_filename != NULL)
    *ret_mime_filename = g_strconcat (dir, G_DIR_SEPARATOR_S, token_escaped,
        ".mime", NULL);

out:

  g_free (dir);
  g_free (token_escaped);

  return success;
}

static void contact_set_avatar_token (TpContact *self, const gchar *new_token,
    gboolean request);

typedef struct {
    GWeakRef contact;
    TpConnection *connection;
    gchar *token;
    GFile *file;
    GBytes *data;
    GFile *mime_file;
    gchar *mime_type;
} WriteAvatarData;

static void
write_avatar_data_free (WriteAvatarData *avatar_data)
{
  g_weak_ref_clear (&avatar_data->contact);
  g_clear_object (&avatar_data->connection);
  tp_clear_pointer (&avatar_data->token, g_free);
  g_clear_object (&avatar_data->file);
  tp_clear_pointer (&avatar_data->data, g_bytes_unref);
  g_clear_object (&avatar_data->mime_file);
  tp_clear_pointer (&avatar_data->mime_type, g_free);

  g_slice_free (WriteAvatarData, avatar_data);
}

static void
mime_file_written (GObject *source_object,
    GAsyncResult *res,
    gpointer user_data)
{
  GError *error = NULL;
  WriteAvatarData *avatar_data = user_data;
  GFile *file = G_FILE (source_object);
  TpContact *self;
  gchar *path = g_file_get_path (file);

  g_assert (file == avatar_data->mime_file);

  if (!g_file_replace_contents_finish (file, res, NULL, &error))
    {
      DEBUG ("Failed to store MIME type in cache (%s): %s", path,
          error->message);
      g_clear_error (&error);
    }
  else
    {
      DEBUG ("Contact avatar MIME type stored in cache: %s", path);
    }

  g_free (path);

  self = g_weak_ref_get (&avatar_data->contact);

  if (self == NULL)
    {
      DEBUG ("No relevant TpContact");
    }
  else if (tp_strdiff (avatar_data->token, self->priv->avatar_token))
    {
      DEBUG ("Contact's avatar token has changed from %s to %s, "
          "this avatar is no longer relevant",
          avatar_data->token, nonnull (self->priv->avatar_token));
    }
  else
    {
      gchar *data_path = g_file_get_path (avatar_data->file);

      DEBUG ("Saved avatar '%s' of MIME type '%s' still used by '%s' to '%s'",
          avatar_data->token, avatar_data->mime_type,
          self->priv->identifier, data_path);
      g_clear_object (&self->priv->avatar_file);
      self->priv->avatar_file = g_object_ref (avatar_data->file);

      g_free (self->priv->avatar_mime_type);
      self->priv->avatar_mime_type = g_strdup (avatar_data->mime_type);

      /* Notify both property changes together once both files have been
       * written */
      g_object_notify ((GObject *) self, "avatar-mime-type");
      g_object_notify ((GObject *) self, "avatar-file");

      g_object_unref (self);
      g_free (data_path);
    }

  write_avatar_data_free (avatar_data);
}

static void
avatar_file_written (GObject *source_object,
    GAsyncResult *res,
    gpointer user_data)
{
  GError *error = NULL;
  WriteAvatarData *avatar_data = user_data;
  GFile *file = G_FILE (source_object);
  gchar *path = g_file_get_path (file);

  g_assert (file == avatar_data->file);

  if (!g_file_replace_contents_finish (file, res, NULL, &error))
    {
      DEBUG ("Failed to store avatar in cache (%s): %s",
          path, error->message);
      DEBUG ("Storing the MIME type anyway");
      g_clear_error (&error);
    }
  else
    {
      DEBUG ("Contact avatar stored in cache: %s",
          path);
    }

  g_file_replace_contents_async (avatar_data->mime_file,
      avatar_data->mime_type, strlen (avatar_data->mime_type),
      NULL, FALSE, G_FILE_CREATE_PRIVATE|G_FILE_CREATE_REPLACE_DESTINATION,
      NULL, mime_file_written, avatar_data);

  g_free (path);
}

static void
contact_avatar_retrieved (TpConnection *connection,
    guint handle,
    const gchar *token,
    const GArray *avatar,
    const gchar *mime_type,
    gpointer user_data G_GNUC_UNUSED,
    GObject *weak_object G_GNUC_UNUSED)
{
  TpContact *self = _tp_connection_lookup_contact (connection, handle);
  gchar *filename;
  gchar *mime_filename;
  WriteAvatarData *avatar_data;

  DEBUG ("token '%s', %u bytes, MIME type '%s'",
      token, avatar->len, mime_type);

  if (self == NULL)
    DEBUG ("handle #%u is not associated with any TpContact", handle);
  else
    DEBUG ("used by contact #%u '%s'", handle,
        tp_contact_get_identifier (self));

  if (self != NULL)
    {
      /* Update the avatar token if a newer one is given
       * (this emits notify::avatar-token if needed) */
      contact_set_avatar_token (self, token, FALSE);
    }

  if (!build_avatar_filename (connection, token, TRUE, &filename,
      &mime_filename))
    {
      DEBUG ("failed to set up cache");
      return;
    }

  /* Save avatar in cache, even if the contact is unknown, to avoid as much as
   * possible future avatar requests */
  avatar_data = g_slice_new0 (WriteAvatarData);
  avatar_data->connection = g_object_ref (connection);
  g_weak_ref_set (&avatar_data->contact, self);
  avatar_data->token = g_strdup (token);
  avatar_data->file = g_file_new_for_path (filename);
  /* g_file_replace_contents_async() doesn't copy its argument, see
   * <https://bugzilla.gnome.org/show_bug.cgi?id=690525>, so we have
   * to keep a copy around */
  avatar_data->data = g_bytes_new (avatar->data, avatar->len);
  avatar_data->mime_file = g_file_new_for_path (mime_filename);
  avatar_data->mime_type = g_strdup (mime_type);

  g_file_replace_contents_async (avatar_data->file,
      g_bytes_get_data (avatar_data->data, NULL), avatar->len,
      NULL, FALSE, G_FILE_CREATE_PRIVATE|G_FILE_CREATE_REPLACE_DESTINATION,
      NULL, avatar_file_written, avatar_data);

  g_free (filename);
  g_free (mime_filename);
}

static gboolean
connection_avatar_request_idle_cb (gpointer user_data)
{
  TpConnection *connection = user_data;

  DEBUG ("Request %d avatars", connection->priv->avatar_request_queue->len);

  tp_cli_connection_interface_avatars_call_request_avatars (connection, -1,
      connection->priv->avatar_request_queue, NULL, NULL, NULL, NULL);

  g_array_unref (connection->priv->avatar_request_queue);
  connection->priv->avatar_request_queue = NULL;
  connection->priv->avatar_request_idle_id = 0;

  return FALSE;
}

static void
contact_update_avatar_data (TpContact *self)
{
  TpConnection *connection;
  gchar *filename = NULL;
  gchar *mime_filename = NULL;

  /* If token is NULL, it means that CM doesn't know the token. In that case we
   * have to request the avatar data to get the token. This happens with XMPP
   * for offline contacts. We don't want to bypass the avatar cache, so we won't
   * update avatar. */
  if (self->priv->avatar_token == NULL)
    return;

   /* If token is empty (""), it means the contact has no avatar. */
  if (tp_str_empty (self->priv->avatar_token))
    {
      tp_clear_object (&self->priv->avatar_file);

      g_free (self->priv->avatar_mime_type);
      self->priv->avatar_mime_type = NULL;

      DEBUG ("contact#%u has no avatar", self->priv->handle);

      g_object_notify ((GObject *) self, "avatar-file");
      g_object_notify ((GObject *) self, "avatar-mime-type");

      return;
    }

  /* We have a token, search in cache... */
  if (build_avatar_filename (self->priv->connection, self->priv->avatar_token,
          FALSE, &filename, &mime_filename))
    {
      if (g_file_test (filename, G_FILE_TEST_EXISTS))
        {
          GError *error = NULL;

          tp_clear_object (&self->priv->avatar_file);
          self->priv->avatar_file = g_file_new_for_path (filename);

          g_free (self->priv->avatar_mime_type);
          if (!g_file_get_contents (mime_filename, &self->priv->avatar_mime_type,
              NULL, &error))
            {
              DEBUG ("Error reading avatar MIME type (%s): %s", mime_filename,
                  error ? error->message : "No error message");
              self->priv->avatar_mime_type = NULL;
              g_clear_error (&error);
            }

          DEBUG ("contact#%u avatar found in cache: %s, %s",
              self->priv->handle, filename, self->priv->avatar_mime_type);

          g_object_notify ((GObject *) self, "avatar-file");
          g_object_notify ((GObject *) self, "avatar-mime_type");

          goto out;
        }
    }

  /* Not found in cache, queue this contact. We do this to group contacts
   * for the AvatarRequest call */
  connection = self->priv->connection;
  if (connection->priv->avatar_request_queue == NULL)
    connection->priv->avatar_request_queue = g_array_new (FALSE, FALSE,
        sizeof (TpHandle));

  g_array_append_val (connection->priv->avatar_request_queue,
      self->priv->handle);

  if (connection->priv->avatar_request_idle_id == 0)
    connection->priv->avatar_request_idle_id = g_idle_add (
        connection_avatar_request_idle_cb, connection);

out:

  g_free (filename);
  g_free (mime_filename);
}

static void
contact_maybe_update_avatar_data (TpContact *self)
{
  if ((self->priv->has_features & CONTACT_FEATURE_FLAG_AVATAR_DATA) == 0 &&
      (self->priv->has_features & CONTACT_FEATURE_FLAG_AVATAR_TOKEN) != 0)
    {
      self->priv->has_features |= CONTACT_FEATURE_FLAG_AVATAR_DATA;
      contact_update_avatar_data (self);
    }
}

static void
contacts_bind_to_avatar_retrieved (TpConnection *connection)
{
  if (!connection->priv->tracking_avatar_retrieved)
    {
      connection->priv->tracking_avatar_retrieved = TRUE;

      tp_cli_connection_interface_avatars_connect_to_avatar_retrieved
        (connection, contact_avatar_retrieved, NULL, NULL, NULL, NULL);
    }
}

static void
contacts_get_avatar_data (ContactsContext *c)
{
  guint i;

  g_assert (c->handles->len == c->contacts->len);

  contacts_bind_to_avatar_retrieved (c->connection);

  for (i = 0; i < c->contacts->len; i++)
    contact_maybe_update_avatar_data (g_ptr_array_index (c->contacts, i));

  contacts_context_continue (c);
}

static void
contact_set_avatar_token (TpContact *self, const gchar *new_token,
    gboolean request)
{
  /* A no-op change (specifically from NULL to NULL) is still interesting if we
   * don't have the AVATAR_TOKEN feature yet: it indicates that we've
   * discovered it.
   */
  if ((self->priv->has_features & CONTACT_FEATURE_FLAG_AVATAR_TOKEN) &&
      !tp_strdiff (self->priv->avatar_token, new_token))
    return;

  DEBUG ("contact#%u token is %s", self->priv->handle, new_token);

  self->priv->has_features |= CONTACT_FEATURE_FLAG_AVATAR_TOKEN;
  g_free (self->priv->avatar_token);
  self->priv->avatar_token = g_strdup (new_token);
  g_object_notify ((GObject *) self, "avatar-token");

  if (request && tp_contact_has_feature (self, TP_CONTACT_FEATURE_AVATAR_DATA))
    contact_update_avatar_data (self);
}

static void
contacts_avatar_updated (TpConnection *connection,
                         TpHandle handle,
                         const gchar *new_token,
                         gpointer user_data G_GNUC_UNUSED,
                         GObject *weak_object G_GNUC_UNUSED)
{
  TpContact *contact = _tp_connection_lookup_contact (connection, handle);

  if (contact != NULL)
    contact_set_avatar_token (contact, new_token, TRUE);
}


static void
contacts_got_known_avatar_tokens (TpConnection *connection,
                                  GHashTable *handle_to_token,
                                  const GError *error,
                                  gpointer user_data,
                                  GObject *weak_object)
{
  ContactsContext *c = user_data;
  GHashTableIter iter;
  gpointer key, value;

  if (error == NULL)
    {
      g_hash_table_iter_init (&iter, handle_to_token);

      while (g_hash_table_iter_next (&iter, &key, &value))
        {
          contacts_avatar_updated (connection, GPOINTER_TO_UINT (key), value,
              NULL, NULL);
        }

    }
  /* FIXME: perhaps we could fall back to GetAvatarTokens (which should have
   * been called RequestAvatarTokens, because it blocks on network traffic)
   * if GetKnownAvatarTokens doesn't work? */
  else
    {
      /* never mind, we can live without avatar tokens */
      DEBUG ("GetKnownAvatarTokens failed with %s %u: %s",
          g_quark_to_string (error->domain), error->code, error->message);
    }

  contacts_context_continue (c);
}


static void
contacts_bind_to_avatar_updated (TpConnection *connection)
{
  if (!connection->priv->tracking_avatar_updated)
    {
      connection->priv->tracking_avatar_updated = TRUE;

      tp_cli_connection_interface_avatars_connect_to_avatar_updated
        (connection, contacts_avatar_updated, NULL, NULL, NULL, NULL);
    }
}


static void
contacts_get_avatar_tokens (ContactsContext *c)
{
  guint i;

  g_assert (c->handles->len == c->contacts->len);

  contacts_bind_to_avatar_updated (c->connection);

  for (i = 0; i < c->contacts->len; i++)
    {
      TpContact *contact = g_ptr_array_index (c->contacts, i);

      if ((contact->priv->has_features & CONTACT_FEATURE_FLAG_AVATAR_TOKEN)
          == 0)
        {
          c->refcount++;
          tp_cli_connection_interface_avatars_call_get_known_avatar_tokens (
              c->connection, -1,
              c->handles, contacts_got_known_avatar_tokens,
              c, contacts_context_unref, c->weak_object);
          return;
        }
    }

  contacts_context_continue (c);
}

static void
contact_maybe_set_info (TpContact *self,
    const GPtrArray *contact_info)
{
  guint i;

  if (self == NULL)
    return;

  tp_contact_info_list_free (self->priv->contact_info);
  self->priv->contact_info = NULL;

  self->priv->has_features |= CONTACT_FEATURE_FLAG_CONTACT_INFO;

  if (contact_info != NULL)
    {
      for (i = contact_info->len; i > 0; i--)
        {
          GValueArray *va = g_ptr_array_index (contact_info, i - 1);
          const gchar *field_name;
          GStrv parameters;
          GStrv field_value;

          tp_value_array_unpack (va, 3, &field_name, &parameters, &field_value);
          self->priv->contact_info = g_list_prepend (self->priv->contact_info,
              tp_contact_info_field_new (field_name, parameters, field_value));
        }
    }
  /* else we don't know, but an empty list is perfectly valid. */

  g_object_notify ((GObject *) self, "contact-info");
}

static void
contact_info_changed (TpConnection *connection,
    guint handle,
    const GPtrArray *contact_info,
    gpointer user_data G_GNUC_UNUSED,
    GObject *weak_object G_GNUC_UNUSED)
{
  TpContact *self = _tp_connection_lookup_contact (connection, handle);

  contact_maybe_set_info (self, contact_info);
}

static void
contacts_got_contact_info (TpConnection *connection,
    GHashTable *info,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  ContactsContext *c = user_data;

  if (error != NULL)
    {
      DEBUG ("GetContactInfo failed with %s %u: %s",
          g_quark_to_string (error->domain), error->code, error->message);
    }
  else
    {
      GHashTableIter iter;
      gpointer key, value;

      g_hash_table_iter_init (&iter, info);
      while (g_hash_table_iter_next (&iter, &key, &value))
        {
          contact_info_changed (connection, GPOINTER_TO_UINT (key),
              value, NULL, NULL);
        }
    }

  contacts_context_continue (c);
}

static void
contacts_bind_to_contact_info_changed (TpConnection *connection)
{
  if (!connection->priv->tracking_contact_info_changed)
    {
      connection->priv->tracking_contact_info_changed = TRUE;

      tp_cli_connection_interface_contact_info_connect_to_contact_info_changed (
          connection, contact_info_changed, NULL, NULL, NULL, NULL);
    }
}

static void
contacts_get_contact_info (ContactsContext *c)
{
  guint i;

  g_assert (c->handles->len == c->contacts->len);

  contacts_bind_to_contact_info_changed (c->connection);

  for (i = 0; i < c->contacts->len; i++)
    {
      TpContact *contact = g_ptr_array_index (c->contacts, i);

      if ((contact->priv->has_features & CONTACT_FEATURE_FLAG_CONTACT_INFO) == 0)
        {
          c->refcount++;
          tp_cli_connection_interface_contact_info_call_get_contact_info (
              c->connection, -1, c->handles, contacts_got_contact_info,
              c, contacts_context_unref, c->weak_object);
          return;
        }
    }

  contacts_context_continue (c);
}

typedef struct
{
  TpContact *contact;
  GSimpleAsyncResult *result;
  TpProxyPendingCall *call;
  GCancellable *cancellable;
  gulong cancelled_id;
} ContactInfoRequestData;

static void
contact_info_request_data_free (ContactInfoRequestData *data)
{
  if (data != NULL)
    {
      g_object_unref (data->result);

      if (data->cancellable != NULL)
        g_object_unref (data->cancellable);

      g_slice_free (ContactInfoRequestData, data);
    }
}

static void
contact_info_request_cb (TpConnection *connection,
    const GPtrArray *contact_info,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  ContactInfoRequestData *data = user_data;
  TpContact *self = data->contact;

  if (data->cancellable != NULL)
    {
      /* At this point it's too late to cancel the operation. This will block
       * until the signal handler has finished if it's already running, so
       * we're guaranteed to never be in a partially-cancelled state after
       * this call. */
      g_cancellable_disconnect (data->cancellable, data->cancelled_id);

      /* If this is true, the cancelled callback has already run and completed the
       * async result, so just bail. */
      if (data->cancelled_id == 0)
        return;

      data->cancelled_id = 0;
    }

  if (error != NULL)
    {
      DEBUG ("Failed to request ContactInfo: %s", error->message);
      g_simple_async_result_set_from_error (data->result, error);
    }
  else
    {
      contact_maybe_set_info (self, contact_info);
    }

  g_simple_async_result_complete_in_idle (data->result);
  data->call = NULL;
}

static void
contact_info_request_cancelled_cb (GCancellable *cancellable,
    ContactInfoRequestData *data)
{
  GError *error = NULL;
  gboolean was_cancelled;

  /* We disconnect from the signal manually; since we're in the cancelled
   * callback, we hold the cancellable's lock so calling this instead of
   * g_cancellable_disconnect() is fine. We do this here so that
   * g_cancellable_disconnect() isn't called by contact_info_request_data_free()
   * which is called by tp_proxy_pending_call_cancel().
   * cancelled_id might already be 0 if the cancellable was cancelled before
   * we connected to it. */
  if (data->cancelled_id != 0)
    g_signal_handler_disconnect (data->cancellable, data->cancelled_id);
  data->cancelled_id = 0;

  was_cancelled = g_cancellable_set_error_if_cancelled (data->cancellable,
      &error);
  g_assert (was_cancelled);

  DEBUG ("Request ContactInfo cancelled");

  g_simple_async_result_set_from_error (data->result, error);
  g_simple_async_result_complete_in_idle (data->result);
  g_clear_error (&error);

  if (data->call != NULL)
    tp_proxy_pending_call_cancel (data->call);
}

/**
 * tp_contact_request_contact_info_async:
 * @self: a #TpContact
 * @cancellable: optional #GCancellable object, %NULL to ignore.
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous request of the contact info of @self. When
 * the operation is finished, @callback will be called. You can then call
 * tp_contact_request_contact_info_finish() to get the result of the operation.
 *
 * If the operation is successful, the #TpContact:contact-info property will be
 * updated (emitting "notify::contact-info" signal) before @callback is called.
 * That means you can call tp_contact_get_contact_info() to get the new vCard
 * inside @callback.
 *
 * Note that requesting the vCard from the network can take significant time, so
 * a bigger timeout is set on the underlying D-Bus call. @cancellable can be
 * cancelled to free resources used in the D-Bus call if the caller is no longer
 * interested in the vCard.
 *
 * If %TP_CONTACT_FEATURE_CONTACT_INFO is not yet set on @self, it will be
 * set before its property gets updated and @callback is called.
 *
 * Since: 0.11.7
 */
void
tp_contact_request_contact_info_async (TpContact *self,
    GCancellable *cancellable,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  ContactInfoRequestData *data;

  g_return_if_fail (TP_IS_CONTACT (self));

  contacts_bind_to_contact_info_changed (self->priv->connection);

  data = g_slice_new0 (ContactInfoRequestData);

  data->contact = self;
  data->result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_contact_request_contact_info_finish);

  if (cancellable != NULL)
    {
      data->cancellable = g_object_ref (cancellable);
      data->cancelled_id = g_cancellable_connect (data->cancellable,
          G_CALLBACK (contact_info_request_cancelled_cb), data, NULL);

      /* Return early if the cancellable has already been cancelled */
      if (data->cancelled_id == 0)
        return;
    }

  data->call = tp_cli_connection_interface_contact_info_call_request_contact_info (
      self->priv->connection, 60*60*1000, self->priv->handle,
      contact_info_request_cb,
      data, (GDestroyNotify) contact_info_request_data_free,
      NULL);
}

/**
 * tp_contact_request_contact_info_finish:
 * @self: a #TpContact
 * @result: a #GAsyncResult
 * @error: a #GError to be filled
 *
 * Finishes an async request of @self info. If the operation was successful,
 * the contact's vCard can be accessed using tp_contact_get_contact_info().
 *
 * Returns: %TRUE if the request call was successful, otherwise %FALSE
 *
 * Since: 0.11.7
 */
gboolean
tp_contact_request_contact_info_finish (TpContact *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_contact_request_contact_info_finish);
}

/**
 * tp_connection_refresh_contact_info:
 * @self: a #TpConnection
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects
 *  associated with @self
 *
 * Requests to refresh the #TpContact:contact-info property on each contact from
 * @contacts, requesting it from the network if an up-to-date version is not
 * cached locally. "notify::contact-info" will be emitted when the contact's
 * information are updated.
 *
 * If %TP_CONTACT_FEATURE_CONTACT_INFO is not yet set on a contact, it will be
 * set before its property gets updated.
 *
 * Since: 0.11.7
 */
void
tp_connection_refresh_contact_info (TpConnection *self,
    guint n_contacts,
    TpContact * const *contacts)
{
  GArray *handles;
  guint i;

  g_return_if_fail (TP_IS_CONNECTION (self));
  g_return_if_fail (n_contacts >= 1);
  g_return_if_fail (contacts != NULL);

  for (i = 0; i < n_contacts; i++)
    {
      g_return_if_fail (TP_IS_CONTACT (contacts[i]));
      g_return_if_fail (contacts[i]->priv->connection == self);
    }

  contacts_bind_to_contact_info_changed (self);

  handles = g_array_sized_new (FALSE, FALSE, sizeof (TpHandle), n_contacts);
  for (i = 0; i < n_contacts; i++)
    g_array_append_val (handles, contacts[i]->priv->handle);

  tp_cli_connection_interface_contact_info_call_refresh_contact_info (self, -1,
      handles, NULL, NULL, NULL, NULL);

  g_array_unref (handles);
}

static void
contact_set_subscription_states (TpContact *self,
    TpSubscriptionState subscribe,
    TpSubscriptionState publish,
    const gchar *publish_request)
{
  if (publish_request == NULL)
    publish_request = "";

  DEBUG ("contact#%u state changed: subscribe=%c publish=%c '%s'",
      self->priv->handle,
      _tp_base_contact_list_presence_state_to_letter (subscribe),
      _tp_base_contact_list_presence_state_to_letter (publish),
      publish_request);

  self->priv->has_features |= CONTACT_FEATURE_FLAG_STATES;

  g_free (self->priv->publish_request);

  self->priv->subscribe = subscribe;
  self->priv->publish = publish;
  self->priv->publish_request = g_strdup (publish_request);

  g_object_notify ((GObject *) self, "subscribe-state");
  g_object_notify ((GObject *) self, "publish-state");
  g_object_notify ((GObject *) self, "publish-request");

  g_signal_emit (self, signals[SIGNAL_SUBSCRIPTION_STATES_CHANGED], 0,
      self->priv->subscribe, self->priv->publish, self->priv->publish_request);
}

void
_tp_contact_set_subscription_states (TpContact *self,
    GValueArray *value_array)
{
  TpSubscriptionState subscribe;
  TpSubscriptionState publish;
  const gchar *publish_request;

  tp_value_array_unpack (value_array, 3,
      &subscribe, &publish, &publish_request);

  contact_set_subscription_states (self, subscribe, publish, publish_request);
}

static void
contacts_changed_cb (TpConnection *connection,
    GHashTable *changes,
    const GArray *removals,
    gpointer user_data,
    GObject *weak_object)
{
  GHashTableIter iter;
  gpointer key, value;
  guint i;

  g_hash_table_iter_init (&iter, changes);
  while (g_hash_table_iter_next (&iter, &key, &value))
    {
      TpHandle handle = GPOINTER_TO_UINT (key);
      TpContact *contact = _tp_connection_lookup_contact (connection, handle);

      if (contact != NULL)
        _tp_contact_set_subscription_states (contact, value);
    }

  for (i = 0; i < removals->len; i++)
    {
      TpHandle handle = g_array_index (removals, TpHandle, i);
      TpContact *contact = _tp_connection_lookup_contact (connection, handle);

      if (contact == NULL)
        continue;

      contact_set_subscription_states (contact, TP_SUBSCRIPTION_STATE_NO,
          TP_SUBSCRIPTION_STATE_NO, NULL);
    }
}

static void
contacts_bind_to_contacts_changed (TpConnection *connection)
{
  if (!connection->priv->tracking_contacts_changed)
    {
      connection->priv->tracking_contacts_changed = TRUE;

      tp_cli_connection_interface_contact_list_connect_to_contacts_changed
        (connection, contacts_changed_cb, NULL, NULL, NULL, NULL);
    }
}

static void
contact_maybe_set_contact_groups (TpContact *self,
    GStrv contact_groups)
{
  gchar **iter;

  if (self == NULL || contact_groups == NULL)
    return;

  self->priv->has_features |= CONTACT_FEATURE_FLAG_CONTACT_GROUPS;

  tp_clear_pointer (&self->priv->contact_groups, g_ptr_array_unref);
  self->priv->contact_groups = g_ptr_array_new_full (
      g_strv_length (contact_groups) + 1, g_free);

  for (iter = contact_groups; *iter != NULL; iter++)
    g_ptr_array_add (self->priv->contact_groups, g_strdup (*iter));
  g_ptr_array_add (self->priv->contact_groups, NULL);

  g_object_notify ((GObject *) self, "contact-groups");
}

static void
contact_groups_changed_cb (TpConnection *connection,
    const GArray *contacts,
    const gchar **added,
    const gchar **removed,
    gpointer user_data,
    GObject *weak_object)
{
  guint i;

  for (i = 0; i < contacts->len; i++)
    {
      TpHandle handle = g_array_index (contacts, TpHandle, i);
      TpContact *contact = _tp_connection_lookup_contact (connection, handle);
      const gchar **iter;
      guint j;

      if (contact == NULL || contact->priv->contact_groups == NULL)
        continue;

      /* Remove the ending NULL */
      g_ptr_array_remove_index_fast (contact->priv->contact_groups,
          contact->priv->contact_groups->len - 1);

      /* Remove old groups */
      for (iter = removed; *iter != NULL; iter++)
        {
          for (j = 0; j < contact->priv->contact_groups->len; j++)
            {
              const gchar *str;

              str = g_ptr_array_index (contact->priv->contact_groups, j);
              if (!tp_strdiff (str, *iter))
                {
                  g_ptr_array_remove_index_fast (contact->priv->contact_groups, j);
                  break;
                }
            }
        }

      /* Add new groups */
      for (iter = added; *iter != NULL; iter++)
        g_ptr_array_add (contact->priv->contact_groups, g_strdup (*iter));

      /* Add back the ending NULL */
      g_ptr_array_add (contact->priv->contact_groups, NULL);

      g_object_notify ((GObject *) contact, "contact-groups");
      g_signal_emit (contact, signals[SIGNAL_CONTACT_GROUPS_CHANGED], 0,
          added, removed);
    }
}

static void
contacts_bind_to_contact_groups_changed (TpConnection *connection)
{
  if (!connection->priv->tracking_contact_groups_changed)
    {
      connection->priv->tracking_contact_groups_changed = TRUE;

      tp_cli_connection_interface_contact_groups_connect_to_groups_changed
        (connection, contact_groups_changed_cb, NULL, NULL, NULL, NULL);
    }
}

static gboolean
contacts_context_supports_iface (ContactsContext *context,
    GQuark iface)
{
  GArray *contact_attribute_interfaces =
      context->connection->priv->contact_attribute_interfaces;
  guint i;

  if (!tp_proxy_has_interface_by_id (context->connection,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS))
    return FALSE;

  if (contact_attribute_interfaces == NULL)
    return FALSE;

  for (i = 0; i < contact_attribute_interfaces->len; i++)
    {
      GQuark q = g_array_index (contact_attribute_interfaces, GQuark, i);

      if (q == iface)
        return TRUE;
    }

  return FALSE;
}

static void
contacts_context_queue_features (ContactsContext *context)
{
  ContactFeatureFlags feature_flags = context->wanted;

  /* Start slow path for requested features that are not in
   * ContactAttributeInterfaces */

  if ((feature_flags & CONTACT_FEATURE_FLAG_ALIAS) != 0 &&
      !contacts_context_supports_iface (context,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING) &&
      tp_proxy_has_interface_by_id (context->connection,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING))
    {
      g_queue_push_tail (&context->todo, contacts_get_aliases);
    }

  if ((feature_flags & CONTACT_FEATURE_FLAG_PRESENCE) != 0 &&
      !contacts_context_supports_iface (context,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_SIMPLE_PRESENCE))
    {
      if (tp_proxy_has_interface_by_id (context->connection,
            TP_IFACE_QUARK_CONNECTION_INTERFACE_SIMPLE_PRESENCE))
        {
          g_queue_push_tail (&context->todo, contacts_get_simple_presence);
        }
#if 0
      /* FIXME: Before doing this for the first time, we'd need to download
       * from the CM the definition of what each status actually *means* */
      else if (tp_proxy_has_interface_by_id (context->connection,
            TP_IFACE_QUARK_CONNECTION_INTERFACE_PRESENCE))
        {
          g_queue_push_tail (&context->todo, contacts_get_complex_presence);
        }
#endif
    }

  if ((feature_flags & CONTACT_FEATURE_FLAG_AVATAR_TOKEN) != 0 &&
      !contacts_context_supports_iface (context,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS) &&
      tp_proxy_has_interface_by_id (context->connection,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS))
    {
      g_queue_push_tail (&context->todo, contacts_get_avatar_tokens);
    }

  /* There is no contact attribute for avatar data, always use slow path */
  if ((feature_flags & CONTACT_FEATURE_FLAG_AVATAR_DATA) != 0 &&
      tp_proxy_has_interface_by_id (context->connection,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS))
    {
      g_queue_push_tail (&context->todo, contacts_get_avatar_data);
    }

  if ((feature_flags & CONTACT_FEATURE_FLAG_LOCATION) != 0 &&
      !contacts_context_supports_iface (context,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_LOCATION) &&
      tp_proxy_has_interface_by_id (context->connection,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_LOCATION))
    {
      WARNING ("%s supports Location but not Contacts! Where did you find "
          "this CM? TP_CONTACT_FEATURE_LOCATION is not gonna work",
          tp_proxy_get_object_path (context->connection));
    }

  /* Don't implement slow path for ContactCapabilities as Contacts is now
   * mandatory so any CM supporting ContactCapabilities will implement
   * Contacts as well.
   *
   * But if ContactCapabilities is NOT supported, we fallback to connection
   * capabilities.
   * */

  if ((feature_flags & CONTACT_FEATURE_FLAG_CAPABILITIES) != 0 &&
      !tp_proxy_has_interface_by_id (context->connection,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_CAPABILITIES))
    {
      DEBUG ("Connection doesn't support ContactCapabilities; fallback to "
          "connection capabilities");

      g_queue_push_tail (&context->todo, contacts_get_conn_capabilities);
    }

  if ((feature_flags & CONTACT_FEATURE_FLAG_CONTACT_INFO) != 0 &&
      !contacts_context_supports_iface (context,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO) &&
      tp_proxy_has_interface_by_id (context->connection,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO))
    {
      g_queue_push_tail (&context->todo, contacts_get_contact_info);
    }
}

static gboolean
tp_contact_set_attributes (TpContact *contact,
    GHashTable *asv,
    ContactFeatureFlags wanted,
    ContactFeatureFlags getting,
    GError **error)
{
  TpConnection *connection = tp_contact_get_connection (contact);
  const gchar *s;
  gpointer boxed;

  /* Identifier */
  s = tp_asv_get_string (asv, TP_TOKEN_CONNECTION_CONTACT_ID);

  if (s == NULL)
    {
       g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
          "Connection manager %s is broken: contact #%u in the "
          "GetContactAttributes result has no contact-id",
          tp_proxy_get_bus_name (connection), contact->priv->handle);

      return FALSE;
    }

  DEBUG ("#%u: \"%s\"", contact->priv->handle, s);

  {
    GHashTableIter iter;
    gpointer k, v;

    g_hash_table_iter_init (&iter, asv);

    while (g_hash_table_iter_next (&iter, &k, &v))
      {
        gchar *str = g_strdup_value_contents (v);

        DEBUG ("- %s => %s", (const gchar *) k, str);
        g_free (str);
      }
  }

  if (contact->priv->identifier == NULL)
    {
      contact->priv->identifier = g_strdup (s);
    }
  else if (tp_strdiff (contact->priv->identifier, s))
    {
      g_set_error (error, TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
          "Connection manager %s is broken: contact #%u identifier "
          "changed from %s to %s",
          tp_proxy_get_bus_name (connection), contact->priv->handle,
          contact->priv->identifier, s);

      return FALSE;
    }

  /* Alias */
  if (wanted & CONTACT_FEATURE_FLAG_ALIAS)
    {
      s = tp_asv_get_string (asv,
          TP_TOKEN_CONNECTION_INTERFACE_ALIASING_ALIAS);

      if (s == NULL)
        {
          if (getting & CONTACT_FEATURE_FLAG_ALIAS)
            {
              WARNING ("%s supposedly implements Contacts and Aliasing, but "
                  "omitted " TP_TOKEN_CONNECTION_INTERFACE_ALIASING_ALIAS,
                  tp_proxy_get_object_path (connection));
            }
        }
      else
        {
          contact->priv->has_features |= CONTACT_FEATURE_FLAG_ALIAS;
          g_free (contact->priv->alias);
          contact->priv->alias = g_strdup (s);
          g_object_notify ((GObject *) contact, "alias");
        }
    }

  /* Avatar */
  if (wanted & CONTACT_FEATURE_FLAG_AVATAR_TOKEN)
    {
      s = tp_asv_get_string (asv,
          TP_TOKEN_CONNECTION_INTERFACE_AVATARS_TOKEN);
      contact_set_avatar_token (contact, s, TRUE);
    }

  if (wanted & CONTACT_FEATURE_FLAG_AVATAR_DATA)
    {
      /* There is no attribute for the avatar data, this will set the avatar
       * from cache or start the avatar request if its missing from cache. */
      contact_maybe_update_avatar_data (contact);
    }

  /* Presence */
  if (wanted & CONTACT_FEATURE_FLAG_PRESENCE)
    {
      boxed = tp_asv_get_boxed (asv,
          TP_TOKEN_CONNECTION_INTERFACE_SIMPLE_PRESENCE_PRESENCE,
          TP_STRUCT_TYPE_SIMPLE_PRESENCE);

      if (boxed == NULL)
        {
          if (getting & CONTACT_FEATURE_FLAG_PRESENCE)
            {
              WARNING ("%s supposedly implements Contacts and SimplePresence, "
                  "but omitted the mandatory "
                  TP_TOKEN_CONNECTION_INTERFACE_SIMPLE_PRESENCE_PRESENCE
                  " attribute",
                  tp_proxy_get_object_path (connection));
            }
        }
      else
        {
          contact_maybe_set_simple_presence (contact, boxed);
        }
    }

  /* Location */
  if (wanted & CONTACT_FEATURE_FLAG_LOCATION)
    {
      boxed = tp_asv_get_boxed (asv,
          TP_TOKEN_CONNECTION_INTERFACE_LOCATION_LOCATION,
          TP_HASH_TYPE_LOCATION);
      contact_maybe_set_location (contact, boxed);
    }

  /* Capabilities */
  if (wanted & CONTACT_FEATURE_FLAG_CAPABILITIES)
    {
      boxed = tp_asv_get_boxed (asv,
          TP_TOKEN_CONNECTION_INTERFACE_CONTACT_CAPABILITIES_CAPABILITIES,
          TP_ARRAY_TYPE_REQUESTABLE_CHANNEL_CLASS_LIST);
      contact_maybe_set_capabilities (contact, boxed);
    }

  /* ContactInfo */
  if (wanted & CONTACT_FEATURE_FLAG_CONTACT_INFO)
    {
      boxed = tp_asv_get_boxed (asv,
          TP_TOKEN_CONNECTION_INTERFACE_CONTACT_INFO_INFO,
          TP_ARRAY_TYPE_CONTACT_INFO_FIELD_LIST);
      contact_maybe_set_info (contact, boxed);
    }

  /* ClientTypes */
  if (wanted & CONTACT_FEATURE_FLAG_CLIENT_TYPES)
    {
      boxed = tp_asv_get_boxed (asv,
          TP_TOKEN_CONNECTION_INTERFACE_CLIENT_TYPES_CLIENT_TYPES,
          G_TYPE_STRV);
      contact_maybe_set_client_types (contact, boxed);
    }

  /* ContactList subscription states */
  if (wanted & CONTACT_FEATURE_FLAG_STATES)
    {
      TpSubscriptionState subscribe;
      TpSubscriptionState publish;
      const gchar *publish_request;
      gboolean subscribe_valid = FALSE;
      gboolean publish_valid = FALSE;

      subscribe = tp_asv_get_uint32 (asv,
            TP_TOKEN_CONNECTION_INTERFACE_CONTACT_LIST_SUBSCRIBE,
            &subscribe_valid);
      publish = tp_asv_get_uint32 (asv,
            TP_TOKEN_CONNECTION_INTERFACE_CONTACT_LIST_PUBLISH,
            &publish_valid);
      publish_request = tp_asv_get_string (asv,
            TP_TOKEN_CONNECTION_INTERFACE_CONTACT_LIST_PUBLISH_REQUEST);

      if (subscribe_valid && publish_valid)
        {
          contact_set_subscription_states (contact, subscribe, publish,
              publish_request);
        }
    }

  /* ContactGroups */
  if (wanted & CONTACT_FEATURE_FLAG_CONTACT_GROUPS)
    {
      boxed = tp_asv_get_boxed (asv,
          TP_TOKEN_CONNECTION_INTERFACE_CONTACT_GROUPS_GROUPS,
          G_TYPE_STRV);
      contact_maybe_set_contact_groups (contact, boxed);
    }

  /* ContactBlocking */
  if (wanted & CONTACT_FEATURE_FLAG_CONTACT_BLOCKING)
    {
      gboolean is_blocked, valid;

      is_blocked = tp_asv_get_boolean (asv,
          TP_TOKEN_CONNECTION_INTERFACE_CONTACT_BLOCKING_BLOCKED, &valid);

      if (valid)
        _tp_contact_set_is_blocked (contact, is_blocked);
    }

  return TRUE;
}

static gboolean get_feature_flags (guint n_features,
    const TpContactFeature *features, ContactFeatureFlags *flags);

gboolean
_tp_contact_set_attributes (TpContact *contact,
    GHashTable *asv,
    guint n_features,
    const TpContactFeature *features,
    GError **error)
{
  ContactFeatureFlags feature_flags = 0;

  if (!get_feature_flags (n_features, features, &feature_flags))
    return FALSE;

  return tp_contact_set_attributes (contact, asv, feature_flags,
      0 /* can't know what we expected to get */, error);
}

static void
contacts_got_attributes (TpConnection *connection,
                         GHashTable *attributes,
                         const GError *error,
                         gpointer user_data,
                         GObject *weak_object)
{
  ContactsContext *c = user_data;
  guint i;

  DEBUG ("%p: reply from GetContactAttributes: %s",
      c, (error == NULL ? "OK" : error->message));

  if (error != NULL)
    {
      contacts_context_fail (c, error);
      return;
    }

  i = 0;

  if (c->signature == CB_BY_HANDLE && c->contacts->len == 0)
    {
      while (i < c->handles->len)
        {
          TpHandle handle = g_array_index (c->handles, guint, i);
          GHashTable *asv = g_hash_table_lookup (attributes,
              GUINT_TO_POINTER (handle));

          if (asv == NULL)
            {
              /* not in the hash table => not valid */
              g_array_append_val (c->invalid, handle);
              g_array_remove_index_fast (c->handles, i);
            }
          else
            {
              TpContact *contact = tp_contact_ensure (connection, handle);

              g_ptr_array_add (c->contacts, contact);
              i++;
            }
        }
    }

  g_assert (c->contacts->len == c->handles->len);

  for (i = 0; i < c->handles->len; i++)
    {
      TpContact *contact = g_ptr_array_index (c->contacts, i);
      GHashTable *asv = g_hash_table_lookup (attributes,
          GUINT_TO_POINTER (contact->priv->handle));
      GError *e = NULL;

      if (asv == NULL)
        {
          g_set_error (&e, TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
              "We hold a ref to handle #%u but it appears to be invalid",
              contact->priv->handle);
        }
      else
        {
          /* set up the contact with its attributes */
          tp_contact_set_attributes (contact, asv, c->wanted, c->getting, &e);
        }

      if (e != NULL)
        {
          contacts_context_fail (c, e);
          g_error_free (e);
          return;
        }
    }

  contacts_context_continue (c);
}

static const gchar **
contacts_bind_to_signals (TpConnection *connection,
    ContactFeatureFlags wanted,
    ContactFeatureFlags *getting)
{
  GArray *contact_attribute_interfaces =
      connection->priv->contact_attribute_interfaces;
  GPtrArray *array;
  guint i;
  guint len = 0;

  if (getting != NULL)
    *getting = 0;

  if (contact_attribute_interfaces != NULL)
      len = contact_attribute_interfaces->len;

  g_assert (tp_proxy_has_interface_by_id (connection,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS));

  array = g_ptr_array_sized_new (len);

  for (i = 0; i < len; i++)
    {
      GQuark q = g_array_index (contact_attribute_interfaces, GQuark, i);

      if (q == TP_IFACE_QUARK_CONNECTION_INTERFACE_ALIASING)
        {
          if ((wanted & CONTACT_FEATURE_FLAG_ALIAS) != 0)
            {
              g_ptr_array_add (array,
                  TP_IFACE_CONNECTION_INTERFACE_ALIASING);
              contacts_bind_to_aliases_changed (connection);

              if (getting != NULL)
                *getting |= CONTACT_FEATURE_FLAG_ALIAS;
            }
        }
      else if (q == TP_IFACE_QUARK_CONNECTION_INTERFACE_AVATARS)
        {
          if ((wanted & CONTACT_FEATURE_FLAG_AVATAR_TOKEN) != 0)
            {
              g_ptr_array_add (array,
                  TP_IFACE_CONNECTION_INTERFACE_AVATARS);
              contacts_bind_to_avatar_updated (connection);

              if (getting != NULL)
                *getting |= CONTACT_FEATURE_FLAG_AVATAR_TOKEN;
            }

          if ((wanted & CONTACT_FEATURE_FLAG_AVATAR_DATA) != 0)
            {
              contacts_bind_to_avatar_retrieved (connection);
            }
        }
      else if (q == TP_IFACE_QUARK_CONNECTION_INTERFACE_SIMPLE_PRESENCE)
        {
          if ((wanted & CONTACT_FEATURE_FLAG_PRESENCE) != 0)
            {
              g_ptr_array_add (array,
                  TP_IFACE_CONNECTION_INTERFACE_SIMPLE_PRESENCE);
              contacts_bind_to_presences_changed (connection);

              if (getting != NULL)
                *getting |= CONTACT_FEATURE_FLAG_PRESENCE;
            }
        }
      else if (q == TP_IFACE_QUARK_CONNECTION_INTERFACE_LOCATION)
        {
          if ((wanted & CONTACT_FEATURE_FLAG_LOCATION) != 0)
            {
              g_ptr_array_add (array,
                  TP_IFACE_CONNECTION_INTERFACE_LOCATION);
              contacts_bind_to_location_updated (connection);

              if (getting != NULL)
                *getting |= CONTACT_FEATURE_FLAG_LOCATION;
            }
        }
      else if (q == TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_CAPABILITIES)
        {
          if ((wanted & CONTACT_FEATURE_FLAG_CAPABILITIES) != 0)
            {
              g_ptr_array_add (array,
                  TP_IFACE_CONNECTION_INTERFACE_CONTACT_CAPABILITIES);
              contacts_bind_to_capabilities_updated (connection);

              if (getting != NULL)
                *getting |= CONTACT_FEATURE_FLAG_CAPABILITIES;
            }
        }
      else if (q == TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_INFO)
        {
          if ((wanted & CONTACT_FEATURE_FLAG_CONTACT_INFO) != 0)
            {
              g_ptr_array_add (array,
                  TP_IFACE_CONNECTION_INTERFACE_CONTACT_INFO);
              contacts_bind_to_contact_info_changed (connection);

              if (getting != NULL)
                *getting |= CONTACT_FEATURE_FLAG_CONTACT_INFO;
            }
        }
      else if (q == TP_IFACE_QUARK_CONNECTION_INTERFACE_CLIENT_TYPES)
        {
          if ((wanted & CONTACT_FEATURE_FLAG_CLIENT_TYPES) != 0)
            {
              g_ptr_array_add (array,
                  TP_IFACE_CONNECTION_INTERFACE_CLIENT_TYPES);
              contacts_bind_to_client_types_updated (connection);

              if (getting != NULL)
                *getting |= CONTACT_FEATURE_FLAG_CLIENT_TYPES;
            }
        }
      else if (q == TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_LIST)
        {
          if ((wanted & CONTACT_FEATURE_FLAG_STATES) != 0)
            {
              g_ptr_array_add (array,
                  TP_IFACE_CONNECTION_INTERFACE_CONTACT_LIST);
              contacts_bind_to_contacts_changed (connection);

              if (getting != NULL)
                *getting |= CONTACT_FEATURE_FLAG_STATES;
            }
        }
      else if (q == TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_GROUPS)
        {
          if ((wanted & CONTACT_FEATURE_FLAG_CONTACT_GROUPS) != 0)
            {
              g_ptr_array_add (array,
                  TP_IFACE_CONNECTION_INTERFACE_CONTACT_GROUPS);
              contacts_bind_to_contact_groups_changed (connection);

              if (getting != NULL)
                *getting |= CONTACT_FEATURE_FLAG_CONTACT_GROUPS;
            }
        }
      else if (q == TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACT_BLOCKING)
        {
          if ((wanted & CONTACT_FEATURE_FLAG_CONTACT_BLOCKING) != 0)
            {
              GQuark features[] = { TP_CONNECTION_FEATURE_CONTACT_BLOCKING, 0 };

              g_ptr_array_add (array,
                  TP_IFACE_CONNECTION_INTERFACE_CONTACT_BLOCKING);

              /* The BlockedContactsChanged signal is already handled by
               * connection-contact-list.c so we just have to prepare
               * TP_CONNECTION_FEATURE_CONTACT_BLOCKING to make sure it's
               * connected. */
              if (!tp_proxy_is_prepared (connection,
                    TP_CONNECTION_FEATURE_CONTACT_BLOCKING))
                {
                  tp_proxy_prepare_async (connection, features, NULL, NULL);
                }

              if (getting != NULL)
                *getting |= CONTACT_FEATURE_FLAG_CONTACT_BLOCKING;
            }
        }
    }

  g_ptr_array_add (array, NULL);
  return (const gchar **) g_ptr_array_free (array, FALSE);
}

/*
 * The connection must implement Contacts.
 */
const gchar **
_tp_contacts_bind_to_signals (TpConnection *connection,
    guint n_features,
    const TpContactFeature *features)
{
  ContactFeatureFlags feature_flags = 0;

  if (!get_feature_flags (n_features, features, &feature_flags))
    return NULL;

  return contacts_bind_to_signals (connection, feature_flags, NULL);
}

static void
contacts_get_attributes (ContactsContext *context)
{
  const gchar **supported_interfaces;
  guint i;

  /* tp_connection_get_contact_attributes insists that you have at least one
   * handle; skip it if we don't (can only happen if we started from IDs) */
  if (context->handles->len == 0)
    {
      contacts_context_continue (context);
      return;
    }

  supported_interfaces = contacts_bind_to_signals (context->connection,
      context->wanted, &context->getting);

  if (supported_interfaces[0] == NULL &&
      !(context->signature == CB_BY_HANDLE && context->contacts->len == 0) &&
      context->contacts_have_ids)
    {
      /* We're not going to do anything useful: we're not holding/inspecting
       * the handles, and we're not inspecting any extended interfaces
       * either. Skip it. */
      g_free (supported_interfaces);
      contacts_context_continue (context);
      return;
    }

  /* The Hold parameter is only true if we started from handles, and we don't
   * already have all the contacts we need. */
  context->refcount++;
  DEBUG ("calling GetContactAttributes");

  for (i = 0; supported_interfaces[i] != NULL; i++)
    DEBUG ("- %s", supported_interfaces[i]);

  tp_cli_connection_interface_contacts_call_get_contact_attributes (
      context->connection, -1, context->handles, supported_interfaces,
      (context->signature == CB_BY_HANDLE && context->contacts->len == 0),
      contacts_got_attributes,
      context, contacts_context_unref, context->weak_object);
  g_free (supported_interfaces);
}

/*
 * Returns a new GPtrArray of borrowed references to TpContacts,
 * or NULL if any contacts could not be found.
 */
static GPtrArray *
lookup_all_contacts (ContactsContext *context)
{
  GPtrArray *contacts = g_ptr_array_new ();
  guint i;

  for (i = 0; i < context->handles->len; i++)
    {
      TpContact *contact = _tp_connection_lookup_contact (context->connection,
          g_array_index (context->handles, TpHandle, i));
      if (contact != NULL)
        {
          g_ptr_array_add (contacts, contact);
        }
      else
        {
          g_ptr_array_unref (contacts);
          contacts = NULL;
          break;
        }
    }

  return contacts;
}

static gboolean
get_feature_flags (guint n_features,
    const TpContactFeature *features,
    ContactFeatureFlags *flags)
{
  ContactFeatureFlags feature_flags = 0;
  guint i;

  for (i = 0; i < n_features; i++)
    {
      g_return_val_if_fail (features[i] < TP_NUM_CONTACT_FEATURES, FALSE);
      feature_flags |= (1 << features[i]);
    }

  /* Force AVATAR_TOKEN if we have AVATAR_DATA */
  if ((feature_flags & CONTACT_FEATURE_FLAG_AVATAR_DATA) != 0)
    feature_flags |= CONTACT_FEATURE_FLAG_AVATAR_TOKEN;

  *flags = feature_flags;

  return TRUE;
}

static void
contacts_context_remove_common_features (ContactsContext *context)
{
  ContactFeatureFlags minimal_feature_flags = 0xFFFFFFFF;
  guint i;

  context->contacts_have_ids = TRUE;

  for (i = 0; i < context->contacts->len; i++)
    {
      TpContact *contact = g_ptr_array_index (context->contacts, i);

      minimal_feature_flags &= contact->priv->has_features;

      if (contact->priv->identifier == NULL)
        context->contacts_have_ids = FALSE;
    }

  context->wanted &= (~minimal_feature_flags);
}


/**
 * tp_connection_get_contacts_by_handle:
 * @self: A connection, which must have the %TP_CONNECTION_FEATURE_CONNECTED
 *  feature prepared
 * @n_handles: The number of handles in @handles (must be at least 1)
 * @handles: (array length=n_handles) (element-type uint): An array of handles
 *  of type %TP_HANDLE_TYPE_CONTACT representing the desired contacts
 * @n_features: The number of features in @features (may be 0)
 * @features: (array length=n_features) (allow-none) (element-type uint): An array of features that
 *  must be ready for use (if supported) before the callback is called (may
 *  be %NULL if @n_features is 0)
 * @callback: A user callback to call when the contacts are ready
 * @user_data: Data to pass to the callback
 * @destroy: Called to destroy @user_data either after @callback has been
 *  called, or if the operation is cancelled
 * @weak_object: (allow-none): An object to pass to the callback, which will be
 *  weakly referenced; if this object is destroyed, the operation will be
 *  cancelled
 *
 * Create a number of #TpContact objects and make asynchronous method calls
 * to hold their handles and ensure that all the features specified in
 * @features are ready for use (if they are supported at all).
 *
 * It is not an error to put features in @features even if the connection
 * manager doesn't support them - users of this method should have a static
 * list of features they would like to use if possible, and use it for all
 * connection managers.
 *
 * Since: 0.7.18
 * Deprecated: Use tp_simple_client_factory_ensure_contact() instead.
 */
void
tp_connection_get_contacts_by_handle (TpConnection *self,
                                      guint n_handles,
                                      const TpHandle *handles,
                                      guint n_features,
                                      const TpContactFeature *features,
                                      TpConnectionContactsByHandleCb callback,
                                      gpointer user_data,
                                      GDestroyNotify destroy,
                                      GObject *weak_object)
{
  ContactFeatureFlags feature_flags = 0;
  ContactsContext *context;
  GPtrArray *contacts;

  /* As an implementation detail, this method actually starts working slightly
   * before we're officially ready. We use this to get the TpContact for the
   * Connection. */
  g_return_if_fail (self->priv->ready_enough_for_contacts);

  g_return_if_fail (tp_proxy_get_invalidated (self) == NULL);
  g_return_if_fail (n_handles >= 1);
  g_return_if_fail (handles != NULL);
  g_return_if_fail (n_features == 0 || features != NULL);
  g_return_if_fail (callback != NULL);

  if (!get_feature_flags (n_features, features, &feature_flags))
    return;

  context = contacts_context_new (self, n_handles, feature_flags,
      CB_BY_HANDLE, user_data, destroy, weak_object);
  context->callback.by_handle = callback;

  g_array_append_vals (context->handles, handles, n_handles);

  contacts = lookup_all_contacts (context);

  if (contacts != NULL)
    {
      /* We have already held (and possibly inspected) handles, so we can
       * skip that. */

      g_ptr_array_foreach (contacts, (GFunc) g_object_ref, NULL);
      tp_g_ptr_array_extend (context->contacts, contacts);

      contacts_context_remove_common_features (context);

      /* We do need to retrieve any features that aren't there yet, though. */
      if (tp_proxy_has_interface_by_id (self,
            TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS))
        {
          g_queue_push_head (&context->todo, contacts_get_attributes);
        }

      contacts_context_queue_features (context);

      g_idle_add_full (G_PRIORITY_DEFAULT_IDLE,
          contacts_context_idle_continue, context, contacts_context_unref);

      g_ptr_array_unref (contacts);
      return;
    }

  if (tp_proxy_has_interface_by_id (self,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS))
    {
      /* we support the Contacts interface, so we can hold the handles and
       * simultaneously inspect them. After that, we'll fill in any
       * features that are necessary (this becomes a no-op if Contacts
       * will give us everything). */
      g_queue_push_head (&context->todo, contacts_get_attributes);
      contacts_context_queue_features (context);
      g_idle_add_full (G_PRIORITY_DEFAULT_IDLE,
          contacts_context_idle_continue, context, contacts_context_unref);
      return;
    }

  /* if we haven't already returned, we're on the slow path */
  DEBUG ("slow path");

  /* Before we return anything we'll want to inspect the handles */
  g_queue_push_head (&context->todo, contacts_inspect);

  /* After that we'll get the features */
  contacts_context_queue_features (context);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  /* but first, we need to hold onto them */
  tp_connection_hold_handles (self, -1,
      TP_HANDLE_TYPE_CONTACT, n_handles, handles,
      contacts_held_handles, context, contacts_context_unref, weak_object);
  G_GNUC_END_IGNORE_DEPRECATIONS
}


/**
 * tp_connection_upgrade_contacts:
 * @self: A connection, which must have the %TP_CONNECTION_FEATURE_CONNECTED
 *  feature prepared
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects
 *  associated with @self
 * @n_features: The number of features in @features (must be at least 1)
 * @features: (array length=n_features): An array of features that must be
 *  ready for use (if supported) before the callback is called
 * @callback: A user callback to call when the contacts are ready
 * @user_data: Data to pass to the callback
 * @destroy: Called to destroy @user_data either after @callback has been
 *  called, or if the operation is cancelled
 * @weak_object: (allow-none): An object to pass to the callback, which will be
 *  weakly referenced; if this object is destroyed, the operation will be
 *  cancelled
 *
 * Given several #TpContact objects, make asynchronous method calls
 * ensure that all the features specified in @features are ready for use
 * (if they are supported at all).
 *
 * It is not an error to put features in @features even if the connection
 * manager doesn't support them - users of this method should have a static
 * list of features they would like to use if possible, and use it for all
 * connection managers.
 *
 * Since: 0.7.18
 * Deprecated: Use tp_connection_upgrade_contacts_async() instead.
 */
void
tp_connection_upgrade_contacts (TpConnection *self,
                                guint n_contacts,
                                TpContact * const *contacts,
                                guint n_features,
                                const TpContactFeature *features,
                                TpConnectionUpgradeContactsCb callback,
                                gpointer user_data,
                                GDestroyNotify destroy,
                                GObject *weak_object)
{
  ContactFeatureFlags feature_flags = 0;
  ContactsContext *context;
  guint i;

  /* As an implementation detail, this method actually starts working slightly
   * before we're officially ready. We use this to get the TpContact for the
   * Connection. */
  g_return_if_fail (self->priv->ready_enough_for_contacts);
  g_return_if_fail (n_contacts >= 1);
  g_return_if_fail (contacts != NULL);
  g_return_if_fail (n_features == 0 || features != NULL);
  g_return_if_fail (callback != NULL);

  for (i = 0; i < n_contacts; i++)
    {
      g_return_if_fail (contacts[i]->priv->connection == self);
      g_return_if_fail (contacts[i]->priv->identifier != NULL);
    }

  if (!get_feature_flags (n_features, features, &feature_flags))
    return;

  context = contacts_context_new (self, n_contacts, feature_flags,
      CB_UPGRADE, user_data, destroy, weak_object);
  context->callback.upgrade = callback;

  for (i = 0; i < n_contacts; i++)
    {
      g_ptr_array_add (context->contacts, g_object_ref (contacts[i]));
      g_array_append_val (context->handles, contacts[i]->priv->handle);
    }

  g_assert (context->handles->len == n_contacts);

  contacts_context_remove_common_features (context);

  if (tp_proxy_has_interface_by_id (self,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS))
    {
      g_queue_push_head (&context->todo, contacts_get_attributes);
    }

  contacts_context_queue_features (context);

  /* use an idle to make sure the callback is called after we return,
   * even if all the contacts actually have all the features, just to be
   * consistent */
  g_idle_add_full (G_PRIORITY_DEFAULT_IDLE,
      contacts_context_idle_continue, context, contacts_context_unref);
}


static void
contacts_requested_one_handle (TpConnection *connection,
                               TpHandleType handle_type,
                               guint n_handles,
                               const TpHandle *handles,
                               const gchar * const *ids,
                               const GError *error,
                               gpointer user_data,
                               GObject *weak_object)
{
  ContactsContext *c = user_data;

  if (error == NULL)
    {
      TpContact *contact;

      g_assert (handle_type == TP_HANDLE_TYPE_CONTACT);
      /* -1 because NULL terminator is explicit */
      g_assert (c->next_index < c->request_ids->len - 1);

      g_assert (n_handles == 1);
      g_assert (handles[0] != 0);

      contact = tp_contact_ensure (connection, handles[0]);
      g_array_append_val (c->handles, handles[0]);
      g_ptr_array_add (c->contacts, contact);
      c->next_index++;
    }
  else if (error->domain == TP_ERROR &&
      (error->code == TP_ERROR_INVALID_HANDLE ||
       error->code == TP_ERROR_NOT_AVAILABLE ||
       error->code == TP_ERROR_INVALID_ARGUMENT))
    {
      g_hash_table_insert (c->request_errors,
          g_ptr_array_index (c->request_ids, c->next_index),
          g_error_copy (error));
      /* shift the rest of the IDs down one and do not increment next_index */
      g_ptr_array_remove_index (c->request_ids, c->next_index);
    }
  else
    {
      contacts_context_fail (c, error);
      return;
    }

  contacts_context_continue (c);
}


static void
contacts_request_one_handle (ContactsContext *c)
{
  const gchar *ids[] = { NULL, NULL };

  ids[0] = g_ptr_array_index (c->request_ids, c->next_index);
  g_assert (ids[0] != NULL);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  c->refcount++;
  tp_connection_request_handles (c->connection, -1,
      TP_HANDLE_TYPE_CONTACT, ids,
      contacts_requested_one_handle, c, contacts_context_unref,
      c->weak_object);
  G_GNUC_END_IGNORE_DEPRECATIONS
}


static void
contacts_requested_handles (TpConnection *connection,
                            TpHandleType handle_type,
                            guint n_handles,
                            const TpHandle *handles,
                            const gchar * const *ids,
                            const GError *error,
                            gpointer user_data,
                            GObject *weak_object)
{
  ContactsContext *c = user_data;

  g_assert (handle_type == TP_HANDLE_TYPE_CONTACT);
  g_assert (weak_object == c->weak_object);

  if (error == NULL)
    {
      guint i;

      for (i = 0; i < n_handles; i++)
        {
          TpContact *contact = tp_contact_ensure (connection, handles[i]);

          g_array_append_val (c->handles, handles[i]);
          g_ptr_array_add (c->contacts, contact);
        }
    }
  else if (error->domain == TP_ERROR &&
      (error->code == TP_ERROR_INVALID_HANDLE ||
       error->code == TP_ERROR_NOT_AVAILABLE ||
       error->code == TP_ERROR_INVALID_ARGUMENT))
    {
      /* One of the strings is bad. We don't know which, so split them. */
      guint i;

      DEBUG ("A handle was bad, trying to recover: %s %u: %s",
          g_quark_to_string (error->domain), error->code, error->message);

      /* -1 because NULL terminator is explicit */
      for (i = 0; i < c->request_ids->len - 1; i++)
        {
          g_queue_push_head (&c->todo, contacts_request_one_handle);
        }

      g_assert (c->next_index == 0);
    }
  else
    {
      DEBUG ("RequestHandles failed: %s %u: %s",
          g_quark_to_string (error->domain), error->code, error->message);
      contacts_context_fail (c, error);
      return;
    }

  contacts_context_continue (c);
}


/**
 * tp_connection_get_contacts_by_id:
 * @self: A connection, which must have the %TP_CONNECTION_FEATURE_CONNECTED
 *  feature prepared
 * @n_ids: The number of IDs in @ids (must be at least 1)
 * @ids: (array length=n_ids) (transfer none): An array of strings representing
 *  the desired contacts by their
 *  identifiers in the IM protocol (XMPP JIDs, SIP URIs, MSN Passports,
 *  AOL screen-names etc.)
 * @n_features: The number of features in @features (may be 0)
 * @features: (array length=n_features) (allow-none): An array of features
 *  that must be ready for use (if supported)
 *  before the callback is called (may be %NULL if @n_features is 0)
 * @callback: A user callback to call when the contacts are ready
 * @user_data: Data to pass to the callback
 * @destroy: Called to destroy @user_data either after @callback has been
 *  called, or if the operation is cancelled
 * @weak_object: (allow-none): An object to pass to the callback, which will
 *  be weakly referenced; if this object is destroyed, the operation will be
 *  cancelled
 *
 * Create a number of #TpContact objects and make asynchronous method calls
 * to obtain their handles and ensure that all the features specified in
 * @features are ready for use (if they are supported at all).
 *
 * It is not an error to put features in @features even if the connection
 * manager doesn't support them - users of this method should have a static
 * list of features they would like to use if possible, and use it for all
 * connection managers.
 *
 * Since: 0.7.18
 * Deprecated: Use tp_connection_dup_contact_by_id_async() instead.
 */
void
tp_connection_get_contacts_by_id (TpConnection *self,
                                  guint n_ids,
                                  const gchar * const *ids,
                                  guint n_features,
                                  const TpContactFeature *features,
                                  TpConnectionContactsByIdCb callback,
                                  gpointer user_data,
                                  GDestroyNotify destroy,
                                  GObject *weak_object)
{
  ContactFeatureFlags feature_flags = 0;
  ContactsContext *context;
  guint i;

  g_return_if_fail (tp_proxy_is_prepared (self,
        TP_CONNECTION_FEATURE_CONNECTED));
  g_return_if_fail (n_ids >= 1);
  g_return_if_fail (ids != NULL);
  g_return_if_fail (ids[0] != NULL);
  g_return_if_fail (n_features == 0 || features != NULL);
  g_return_if_fail (callback != NULL);

  if (!get_feature_flags (n_features, features, &feature_flags))
    return;

  context = contacts_context_new (self, n_ids, feature_flags,
      CB_BY_ID, user_data, destroy, weak_object);
  context->callback.by_id = callback;
  context->request_errors = g_hash_table_new_full (g_str_hash, g_str_equal,
      g_free, (GDestroyNotify) g_error_free);

  context->request_ids = g_ptr_array_sized_new (n_ids);

  for (i = 0; i < n_ids; i++)
    {
      g_return_if_fail (ids[i] != NULL);
      g_ptr_array_add (context->request_ids, g_strdup (ids[i]));
    }

  g_ptr_array_add (context->request_ids, NULL);

  /* set up the queue of feature introspection */

  if (tp_proxy_has_interface_by_id (self,
        TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS))
    {
      g_queue_push_head (&context->todo, contacts_get_attributes);
    }
  else
    {
      g_queue_push_head (&context->todo, contacts_inspect);
    }

  contacts_context_queue_features (context);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  /* but first, we need to get the handles in the first place */
  tp_connection_request_handles (self, -1,
      TP_HANDLE_TYPE_CONTACT,
      (const gchar * const *) context->request_ids->pdata,
      contacts_requested_handles, context, contacts_context_unref,
      weak_object);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

static void
got_contact_by_id_fallback_cb (TpConnection *self,
    guint n_contacts,
    TpContact * const *contacts,
    const gchar * const *requested_ids,
    GHashTable *failed_id_errors,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  const gchar *id = user_data;
  GSimpleAsyncResult *result = (GSimpleAsyncResult *) weak_object;
  GError *e = NULL;

  if (error != NULL)
    {
      g_simple_async_result_set_from_error (result, error);
    }
  else if (g_hash_table_size (failed_id_errors) > 0)
    {
      e = g_hash_table_lookup (failed_id_errors, id);

      if (e == NULL)
        {
          g_set_error (&e, TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
              "We requested 1 id, and got an error for another id - Broken CM");
          g_simple_async_result_take_error (result, e);
        }
      else
        {
          g_simple_async_result_set_from_error (result, e);
        }
    }
  else if (n_contacts != 1 || contacts[0] == NULL)
    {
      g_set_error (&e, TP_DBUS_ERRORS, TP_DBUS_ERROR_INCONSISTENT,
          "We requested 1 id, but no contacts and no error - Broken CM");
      g_simple_async_result_take_error (result, e);
    }
  else
    {
      g_simple_async_result_set_op_res_gpointer (result,
          g_object_ref (contacts[0]), g_object_unref);
    }

  g_simple_async_result_complete_in_idle (result);
  g_object_unref (result);
}

/**
 * tp_connection_dup_contact_by_id_async:
 * @self: A connection, which must have the %TP_CONNECTION_FEATURE_CONNECTED
 *  feature prepared
 * @id: A strings representing the desired contact by its
 *  identifier in the IM protocol (an XMPP JID, SIP URI, MSN Passport,
 *  AOL screen-name etc.)
 * @n_features: The number of features in @features (may be 0)
 * @features: (array length=n_features) (allow-none): An array of features
 *  that must be ready for use (if supported)
 *  before the callback is called (may be %NULL if @n_features is 0)
 * @callback: A user callback to call when the contact is ready
 * @user_data: Data to pass to the callback
 *
 * Create a #TpContact object and make any asynchronous method calls necessary
 * to ensure that all the features specified in @features are ready for use
 * (if they are supported at all).
 *
 * It is not an error to put features in @features even if the connection
 * manager doesn't support them - users of this method should have a static
 * list of features they would like to use if possible, and use it for all
 * connection managers.
 *
 * Since: 0.19.0
 */
void
tp_connection_dup_contact_by_id_async (TpConnection *self,
    const gchar *id,
    guint n_features,
    const TpContactFeature *features,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      tp_connection_dup_contact_by_id_async);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  tp_connection_get_contacts_by_id (self,
      1, &id,
      n_features, features,
      got_contact_by_id_fallback_cb,
      g_strdup (id), g_free, G_OBJECT (result));
  G_GNUC_END_IGNORE_DEPRECATIONS
}

/**
 * tp_connection_dup_contact_by_id_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to fill
 *
 * Finishes tp_connection_dup_contact_by_id_async().
 *
 * Returns: (transfer full): a #TpContact or %NULL on error.
 * Since: 0.19.0
 */
TpContact *
tp_connection_dup_contact_by_id_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_return_copy_pointer (self,
      tp_connection_dup_contact_by_id_async, g_object_ref);
}

static void
upgrade_contacts_fallback_cb (TpConnection *connection,
    guint n_contacts,
    TpContact * const *contacts,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;
  GPtrArray *contacts_array;
  guint i;

  contacts_array = g_ptr_array_new_full (n_contacts, g_object_unref);
  for (i = 0; i < n_contacts; i++)
    g_ptr_array_add (contacts_array, g_object_ref (contacts[i]));

  g_simple_async_result_set_op_res_gpointer (result, contacts_array,
      (GDestroyNotify) g_ptr_array_unref);

  if (error != NULL)
    g_simple_async_result_set_from_error (result, error);

  g_simple_async_result_complete_in_idle (result);
}

/**
 * tp_connection_upgrade_contacts_async:
 * @self: A connection, which must have the %TP_CONNECTION_FEATURE_CONNECTED
 *  feature prepared
 * @n_contacts: The number of contacts in @contacts (must be at least 1)
 * @contacts: (array length=n_contacts): An array of #TpContact objects
 *  associated with @self
 * @n_features: The number of features in @features (must be at least 1)
 * @features: (array length=n_features): An array of features that must be
 *  ready for use (if supported) before the callback is called
 * @callback: A user callback to call when the contacts are ready
 * @user_data: Data to pass to the callback
 *
 * Given several #TpContact objects, make asynchronous method calls
 * ensure that all the features specified in @features are ready for use
 * (if they are supported at all).
 *
 * It is not an error to put features in @features even if the connection
 * manager doesn't support them - users of this method should have a static
 * list of features they would like to use if possible, and use it for all
 * connection managers.
 *
 * Since: 0.19.0
 */
void
tp_connection_upgrade_contacts_async (TpConnection *self,
    guint n_contacts,
    TpContact * const *contacts,
    guint n_features,
    const TpContactFeature *features,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;

  result = g_simple_async_result_new ((GObject *) self, callback, user_data,
      tp_connection_upgrade_contacts_async);

  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  tp_connection_upgrade_contacts (self,
      n_contacts, contacts,
      n_features, features,
      upgrade_contacts_fallback_cb,
      result, g_object_unref, NULL);
  G_GNUC_END_IGNORE_DEPRECATIONS
}

/**
 * tp_connection_upgrade_contacts_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @contacts: (element-type TelepathyGLib.Contact) (transfer container) (out) (allow-none):
 *  a location to set a #GPtrArray of upgraded #TpContact, or %NULL.
 * @error: a #GError to fill
 *
 * Finishes tp_connection_upgrade_contacts_async().
 *
 * Returns: %TRUE on success, %FALSE otherwise.
 * Since: 0.19.0
 */
gboolean
tp_connection_upgrade_contacts_finish (TpConnection *self,
    GAsyncResult *result,
    GPtrArray **contacts,
    GError **error)
{
  _tp_implement_finish_copy_pointer (self,
      tp_connection_upgrade_contacts_async, g_ptr_array_ref, contacts);
}

void
_tp_contact_set_is_blocked (TpContact *self,
    gboolean is_blocked)
{
  if (self == NULL)
    return;

  self->priv->has_features |= CONTACT_FEATURE_FLAG_CONTACT_BLOCKING;

  if (self->priv->is_blocked == is_blocked)
    return;

  self->priv->is_blocked = is_blocked;

  g_object_notify ((GObject *) self, "is-blocked");
}

/**
 * tp_contact_is_blocked:
 * @self: a #TpContact
 *
 * <!-- -->

 * Returns: the value of #TpContact:is-blocked.
 *
 * Since: 0.17.0
 */
gboolean
tp_contact_is_blocked (TpContact *self)
{
  g_return_val_if_fail (TP_IS_CONTACT (self), FALSE);

  return self->priv->is_blocked;
}
