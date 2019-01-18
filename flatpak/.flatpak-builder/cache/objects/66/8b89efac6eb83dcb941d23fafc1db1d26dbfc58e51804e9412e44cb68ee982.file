/*
 * presence-mixin.c - Source for TpPresenceMixin
 * Copyright (C) 2005-2008 Collabora Ltd.
 * Copyright (C) 2005-2007 Nokia Corporation
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
 * SECTION:presence-mixin
 * @title: TpPresenceMixin
 * @short_description: a mixin implementation of the Presence connection
 *  interface
 * @see_also: #TpSvcConnectionInterfacePresence
 *
 * This mixin can be added to a #TpBaseConnection subclass to implement the
 * SimplePresence and/or Presence interfaces. Implementing both interfaces
 * (as described below) is recommended. In particular, you must implement the
 * old-style Presence interface if compatibility with telepathy-glib
 * versions older than 0.11.13 is required.
 *
 * To use the presence mixin, include a #TpPresenceMixinClass somewhere in your
 * class structure and a #TpPresenceMixin somewhere in your instance structure,
 * and call tp_presence_mixin_class_init() from your class_init function,
 * tp_presence_mixin_init() from your init function or constructor, and
 * tp_presence_mixin_finalize() from your dispose or finalize function.
 *
 * <section>
 * <title>Implementing SimplePresence</title>
 * <para>
 *   Since 0.7.13 this mixin supports the entire SimplePresence interface.
 *   You can implement #TpSvcConnectionInterfaceSimplePresence as follows:
 *   <itemizedlist>
 *     <listitem>
 *       <para>use the #TpContactsMixin and
 *        <link linkend="telepathy-glib-dbus-properties-mixin">TpDBusPropertiesMixin</link>;</para>
 *     </listitem>
 *     <listitem>
 *       <para>pass tp_presence_mixin_simple_presence_iface_init() as an
 *         argument to G_IMPLEMENT_INTERFACE(), like so:
 *       </para>
 *       |[
 *       G_DEFINE_TYPE_WITH_CODE (MyConnection, my_connection,
 *           TP_TYPE_BASE_CONNECTION,
 *           // ...
 *           G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE,
 *               tp_presence_mixin_simple_presence_iface_init);
 *           // ...
 *           )
 *       ]|
 *     </listitem>
 *     <listitem>
 *       <para>
 *         call tp_presence_mixin_simple_presence_init_dbus_properties() in the
 *         #GTypeInfo class_init function;
 *       </para>
 *     </listitem>
 *     <listitem>
 *       <para>
 *         call tp_presence_mixin_simple_presence_register_with_contacts_mixin()
 *         in the #GObjectClass constructed function.
 *       </para>
 *     </listitem>
 *   </itemizedlist>
 * </para>
 * </section> <!-- Simple Presence -->
 * <section>
 * <title>Implementing old-style Presence</title>
 * <para>
 *   This mixin also supports a large subset of the deprecated Presence
 *   interface. It does not support protocols where it is possible to set
 *   multiple statuses on yourself at once (all presence statuses will have the
 *   exclusive flag set), or last-activity-time information.
 * </para>
 * <para>
 *   To use the presence mixin as the implementation of
 *   #TpSvcConnectionInterfacePresence, use tp_presence_mixin_iface_init() as
 *   the function you pass to G_IMPLEMENT_INTERFACE(), as in the following
 *   example.  The presence mixin implements all of the D-Bus methods in the
 *   Presence interface.
 * </para>
 * |[
 * G_DEFINE_TYPE_WITH_CODE (MyConnection, my_connection,
 *     TP_TYPE_BASE_CONNECTION,
 *     // ...
 *     G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_CONNECTION_INTERFACE_PRESENCE,
 *         tp_presence_mixin_iface_init);
 *     // ...
 *     )
 * ]|
 * <para>
 *   In telepathy-glib versions older than 0.11.13, every connection
 *   that used the #TpPresenceMixin was required to implement
 *   #TpSvcConnectionInterfacePresence; failing to do so would lead to an
 *   assertion failure. Since 0.11.13, this is no longer required.
 * </para>
 * </section> <!-- complex Presence -->
 *
 * Since: 0.5.13
 */

/**
 * TpPresenceStatusOptionalArgumentSpec:
 * @name: Name of the argument as passed over D-Bus
 * @dtype: D-Bus type signature of the argument
 *
 * Structure specifying a supported optional argument for a presence status.
 *
 * In addition to the fields documented here, there are two gpointer fields
 * which must currently be %NULL. A meaning may be defined for these in a
 * future version of telepathy-glib.
 */

/**
 * TpPresenceStatusSpec:
 * @name: String identifier of the presence status
 * @presence_type: A type value, as specified by #TpConnectionPresenceType
 * @self: Indicates if this status may be set on yourself
 * @optional_arguments: An array of #TpPresenceStatusOptionalArgumentSpec
 *  structures representing the optional arguments for this status, terminated
 *  by a NULL name. If there are no optional arguments for a status, this can
 *  be NULL. In modern Telepathy connection managers, the only optional
 *  argument should be a string (type "s") named "message" on statuses
 *  that have an optional human-readable message. All other optional arguments
 *  are deprecated.
 *
 * Structure specifying a supported presence status.
 *
 * In addition to the fields documented here, there are two gpointer fields
 * which must currently be %NULL. A meaning may be defined for these in a
 * future version of telepathy-glib.
 */

/**
 * TpPresenceStatus:
 * @index: Index of the presence status in the provided supported presence
 *  statuses array
 * @optional_arguments: A GHashTable mapping of string identifiers to GValues
 *  of the optional status arguments, if any. If there are no optional
 *  arguments, this pointer may be NULL.
 *
 * Structure representing a presence status.
 *
 * In addition to the fields documented here, there are two gpointer fields
 * which must currently be %NULL. A meaning may be defined for these in a
 * future version of telepathy-glib.
 *
 * In modern Telepathy connection managers, the only optional
 * argument should be a %G_TYPE_STRING named "message", on statuses
 * that have an optional human-readable message. All other optional arguments
 * are deprecated.
 */

/**
 * TpPresenceMixinStatusAvailableFunc:
 * @obj: An instance of a #TpBaseConnection subclass implementing the presence
 *  interface with this mixin
 * @which: An index into the array of #TpPresenceStatusSpec provided to
 *  tp_presence_mixin_class_init()
 *
 * Signature of a callback to be used to determine if a given presence
 * status can be set on the connection. Most users of this mixin do not need to
 * supply an implementation of this callback: the value of
 * #TpPresenceStatusSpec.self is enough to determine whether this is a
 * user-settable presence, so %NULL should be passed to
 * tp_presence_mixin_class_init() for this callback.
 *
 * One place where this callback may be needed is on XMPP: not all server
 * implementation support the user becoming invisible. So an XMPP
 * implementation would implement this function, so that—once connected—the
 * hidden status is only available if the server supports it. Before the
 * connection is connected, this callback should return %TRUE for every status
 * that might possibly be supported: this allows the user to at least try to
 * sign in as invisible.
 *
 * Returns: %TRUE if the status can be set on this connection; %FALSE if not.
 */

/**
 * TpPresenceMixinGetContactStatusesFunc:
 * @obj: An object with this mixin.
 * @contacts: An array of #TpHandle for the contacts to get presence status for
 * @error: Used to return a Telepathy D-Bus error if %NULL is returned
 *
 * Signature of the callback used to get the stored presence status of
 * contacts. The returned hash table should have contact handles mapped to
 * their respective presence statuses in #TpPresenceStatus structs.
 *
 * The returned hash table will be freed with g_hash_table_unref. The
 * callback is responsible for ensuring that this does any cleanup that
 * may be necessary.
 *
 * Returns: (transfer full): The contact presence on success, %NULL with
 *  error set on error
 */

/**
 * TpPresenceMixinSetOwnStatusFunc:
 * @obj: An object with this mixin.
 * @status: The status to set, or NULL for whatever the protocol defines as a
 *  "default" status
 * @error: Used to return a Telepathy D-Bus error if %FALSE is returned
 *
 * Signature of the callback used to commit changes to the user's own presence
 * status in SetStatuses. It is also used in ClearStatus and RemoveStatus to
 * reset the user's own status back to the "default" one with a %NULL status
 * argument.
 *
 * The optional_arguments hash table in @status, if not NULL, will have been
 * filtered so it only contains recognised parameters, so the callback
 * need not (and cannot) check for unrecognised parameters. However, the
 * types of the parameters are not currently checked, so the callback is
 * responsible for doing so.
 *
 * The callback is responsible for emitting PresenceUpdate, if appropriate,
 * by calling tp_presence_mixin_emit_presence_update().
 *
 * Returns: %TRUE if the operation was successful, %FALSE if not.
 */

/**
 * TpPresenceMixinGetMaximumStatusMessageLengthFunc:
 * @obj: An object with this mixin.
 *
 * Signature of a callback used to determine the maximum length of status
 * messages. If this callback is provided and returns non-zero, the
 * #TpPresenceMixinSetOwnStatusFunc implementation is responsible for
 * truncating the message to fit this limit, if necessary.
 *
 * Returns: the maximum number of UTF-8 characters which may appear in a status
 * message, or 0 if there is no limit.
 * Since: 0.14.5
 */

/**
 * TpPresenceMixinClass:
 * @status_available: The status-available function that was passed to
 *  tp_presence_mixin_class_init()
 * @get_contact_statuses: The get-contact-statuses function that was passed to
 *  tp_presence_mixin_class_init()
 * @set_own_status: The set-own-status function that was passed to
 *  tp_presence_mixin_class_init()
 * @statuses: The presence statuses array that was passed to
 *  tp_presence_mixin_class_init()
 * @get_maximum_status_message_length: The callback used to discover the
 *  the limit for status messages length, if any. Since: 0.14.5
 *
 * Structure to be included in the class structure of objects that
 * use this mixin. Initialize it with tp_presence_mixin_class_init().
 *
 * If the protocol imposes a limit on the length of status messages, one should
 * implement @get_maximum_status_message_length. If this callback is not
 * implemented, it is assumed that there is no limit. The callback function
 * should be set after calling tp_presence_mixin_class_init(), like so:
 *
 * |[
 * TpPresenceMixinClass *mixin_class;
 *
 * tp_presence_mixin_class_init ((GObjectClass *) klass,
 *     G_STRUCT_OFFSET (SomeObjectClass, presence_mixin));
 * mixin_class = TP_PRESENCE_MIXIN_CLASS (klass);
 * mixin_class->get_maximum_status_message_length =
 *     some_object_get_maximum_status_message_length;
 * ]|
 *
 * All other fields should be considered read-only.
 */

/**
 * TpPresenceMixin:
 *
 * Structure to be included in the instance structure of objects that
 * use this mixin. Initialize it with tp_presence_mixin_init().
 *
 * There are no public fields.
 */

#include "config.h"

#include <telepathy-glib/presence-mixin.h>

#include <dbus/dbus-glib.h>
#include <string.h>

#include <telepathy-glib/base-connection.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/contacts-mixin.h>

#define DEBUG_FLAG TP_DEBUG_PRESENCE

#include "debug-internal.h"


static GHashTable *construct_simple_presence_hash (
  const TpPresenceStatusSpec *supported_statuses,
  GHashTable *contact_statuses);

/*
 * deep_copy_hashtable
 *
 * Make a deep copy of a GHashTable.
 */
static GHashTable *
deep_copy_hashtable (GHashTable *hash_table)
{
  GValue value = {0, };

  if (!hash_table)
    return NULL;

  g_value_init (&value, TP_HASH_TYPE_STRING_VARIANT_MAP);
  g_value_take_boxed (&value, hash_table);
  return g_value_dup_boxed (&value);
}


/**
 * tp_presence_status_new: (skip)
 * @which: Index of the presence status in the provided supported presence
 *  statuses array
 * @optional_arguments: Optional arguments for the presence statuses. Can be
 *  NULL if there are no optional arguments. The presence status object makes a
 *  copy of the hashtable, so you should free the original.
 *
 * Construct a presence status structure. You should free the returned
 * structure with #tp_presence_status_free.
 *
 * In modern Telepathy connection managers, the only optional
 * argument should be a %G_TYPE_STRING named "message", on statuses
 * that have an optional human-readable message. All other optional arguments
 * are deprecated.
 *
 * Returns: A pointer to the newly allocated presence status structure.
 */
TpPresenceStatus *
tp_presence_status_new (guint which,
                        GHashTable *optional_arguments)
{
  TpPresenceStatus *status = g_slice_new (TpPresenceStatus);

  status->index = which;
  status->optional_arguments = deep_copy_hashtable (optional_arguments);

  return status;
}


/**
 * tp_presence_status_free: (skip)
 * @status: A pointer to the presence status structure to free.
 *
 * Deallocate all resources associated with a presence status structure.
 */
void
tp_presence_status_free (TpPresenceStatus *status)
{
  if (!status)
    return;

  if (status->optional_arguments)
    g_hash_table_unref (status->optional_arguments);

  g_slice_free (TpPresenceStatus, status);
}


/**
 * tp_presence_mixin_class_get_offset_quark: (skip)
 *
 * <!--no documentation beyond Returns: needed-->
 *
 * Returns: the quark used for storing mixin offset on a GObjectClass
 */
GQuark
tp_presence_mixin_class_get_offset_quark ()
{
  static GQuark offset_quark = 0;
  if (!offset_quark)
    offset_quark = g_quark_from_static_string ("TpPresenceMixinClassOffsetQuark");
  return offset_quark;
}

/**
 * tp_presence_mixin_get_offset_quark: (skip)
 *
 * <!--no documentation beyond Returns: needed-->
 *
 * Returns: the quark used for storing mixin offset on a GObject
 */
GQuark
tp_presence_mixin_get_offset_quark ()
{
  static GQuark offset_quark = 0;
  if (!offset_quark)
    offset_quark = g_quark_from_static_string ("TpPresenceMixinOffsetQuark");
  return offset_quark;
}

/**
 * tp_presence_mixin_class_init: (skip)
 * @obj_cls: The class of the implementation that uses this mixin
 * @offset: The byte offset of the TpPresenceMixinClass within the class
 * structure
 * @status_available: A callback to be used to determine if a given presence
 *  status can be set on a particular connection. Should usually be %NULL, to
 *  consider all statuses with #TpPresenceStatusSpec.self set to %TRUE to be
 *  settable.
 * @get_contact_statuses: A callback to be used get the current presence status
 *  for contacts. This is used in implementations of various D-Bus methods and
 *  hence must be provided.
 * @set_own_status: A callback to be used to commit changes to the user's own
 *  presence status to the server. This is used in implementations of various
 *  D-Bus methods and hence must be provided.
 * @statuses: An array of #TpPresenceStatusSpec structures representing all
 *  presence statuses supported by the protocol, terminated by a NULL name.
 *
 * Initialize the presence mixin. Should be called from the implementation's
 * class_init function like so:
 *
 * <informalexample><programlisting>
 * tp_presence_mixin_class_init ((GObjectClass *) klass,
 *                               G_STRUCT_OFFSET (SomeObjectClass,
 *                                                presence_mixin));
 * </programlisting></informalexample>
 */

void
tp_presence_mixin_class_init (GObjectClass *obj_cls,
                              glong offset,
                              TpPresenceMixinStatusAvailableFunc status_available,
                              TpPresenceMixinGetContactStatusesFunc get_contact_statuses,
                              TpPresenceMixinSetOwnStatusFunc set_own_status,
                              const TpPresenceStatusSpec *statuses)
{
  TpPresenceMixinClass *mixin_cls;
  guint i;

  DEBUG ("called.");

  g_assert (get_contact_statuses != NULL);
  g_assert (set_own_status != NULL);
  g_assert (statuses != NULL);

  g_assert (G_IS_OBJECT_CLASS (obj_cls));

  g_type_set_qdata (G_OBJECT_CLASS_TYPE (obj_cls),
      TP_PRESENCE_MIXIN_CLASS_OFFSET_QUARK,
      GINT_TO_POINTER (offset));

  mixin_cls = TP_PRESENCE_MIXIN_CLASS (obj_cls);

  mixin_cls->status_available = status_available;
  mixin_cls->get_contact_statuses = get_contact_statuses;
  mixin_cls->set_own_status = set_own_status;
  mixin_cls->statuses = statuses;
  mixin_cls->get_maximum_status_message_length = NULL;

  for (i = 0; statuses[i].name != NULL; i++)
    {
      if (statuses[i].self)
        {
          switch (statuses[i].presence_type)
            {
            case TP_CONNECTION_PRESENCE_TYPE_OFFLINE:
            case TP_CONNECTION_PRESENCE_TYPE_UNKNOWN:
            case TP_CONNECTION_PRESENCE_TYPE_ERROR:
              WARNING ("Status \"%s\" of type %u should not be available "
                  "to set on yourself", statuses[i].name,
                  statuses[i].presence_type);
              break;

            default:
              break;
            }
        }
    }
}

/**
 * tp_presence_mixin_init: (skip)
 * @obj: An instance of the implementation that uses this mixin
 * @offset: The byte offset of the TpPresenceMixin within the object structure
 *
 * Initialize the presence mixin. Should be called from the implementation's
 * instance init function like so:
 *
 * <informalexample><programlisting>
 * tp_presence_mixin_init ((GObject *) self,
 *                         G_STRUCT_OFFSET (SomeObject, presence_mixin));
 * </programlisting></informalexample>
 */
void
tp_presence_mixin_init (GObject *obj,
                        glong offset)
{
  DEBUG ("called.");

  g_assert (G_IS_OBJECT (obj));

  g_type_set_qdata (G_OBJECT_TYPE (obj),
                    TP_PRESENCE_MIXIN_OFFSET_QUARK,
                    GINT_TO_POINTER (offset));
}

/**
 * tp_presence_mixin_finalize: (skip)
 * @obj: An object with this mixin.
 *
 * Free resources held by the presence mixin.
 */
void
tp_presence_mixin_finalize (GObject *obj)
{
  DEBUG ("%p", obj);

  /* free any data held directly by the object here */
}

static void
construct_presence_hash_foreach (
    GHashTable *presence_hash,
    const TpPresenceStatusSpec *supported_statuses,
    TpHandle handle,
    TpPresenceStatus *status)
{
  GHashTable *parameters;
  GHashTable *contact_status;
  GValueArray *vals;

  contact_status = g_hash_table_new_full (g_str_hash, g_str_equal, NULL,
      (GDestroyNotify) g_hash_table_unref);

  parameters = deep_copy_hashtable (status->optional_arguments);

  if (!parameters)
    parameters = g_hash_table_new_full (g_str_hash, g_str_equal, NULL, NULL);

  g_hash_table_insert (contact_status,
      (gpointer) supported_statuses[status->index].name, parameters);

  vals = tp_value_array_build (2,
      G_TYPE_UINT, 0,
      TP_HASH_TYPE_MULTIPLE_STATUS_MAP, contact_status,
      G_TYPE_INVALID);
  g_hash_table_unref (contact_status);

  g_hash_table_insert (presence_hash, GUINT_TO_POINTER (handle), vals);
}


static GHashTable *
construct_presence_hash (const TpPresenceStatusSpec *supported_statuses,
                         GHashTable *contact_statuses)
{
  GHashTable *presence_hash = g_hash_table_new_full (NULL, NULL, NULL,
      (GDestroyNotify) tp_value_array_free);
  GHashTableIter iter;
  gpointer key, value;

  DEBUG ("called.");

  g_hash_table_iter_init (&iter, contact_statuses);
  while (g_hash_table_iter_next (&iter, &key, &value))
    construct_presence_hash_foreach (presence_hash, supported_statuses,
        GPOINTER_TO_UINT (key), value);

  return presence_hash;
}


/**
 * tp_presence_mixin_emit_presence_update: (skip)
 * @obj: A connection object with this mixin
 * @contact_presences: A mapping of contact handles to #TpPresenceStatus
 *  structures with the presence data to emit
 *
 * Emit the PresenceUpdate signal for multiple contacts. For emitting
 * PresenceUpdate for a single contact, there is a convenience wrapper called
 * #tp_presence_mixin_emit_one_presence_update.
 */
void
tp_presence_mixin_emit_presence_update (GObject *obj,
                                        GHashTable *contact_statuses)
{
  TpPresenceMixinClass *mixin_cls =
    TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  GHashTable *presence_hash;

  DEBUG ("called.");

  if (g_type_interface_peek (G_OBJECT_GET_CLASS (obj),
      TP_TYPE_SVC_CONNECTION_INTERFACE_PRESENCE) != NULL)
    {
      presence_hash = construct_presence_hash (mixin_cls->statuses,
          contact_statuses);
      tp_svc_connection_interface_presence_emit_presence_update (obj,
          presence_hash);

      g_hash_table_unref (presence_hash);
    }

  if (g_type_interface_peek (G_OBJECT_GET_CLASS (obj),
      TP_TYPE_SVC_CONNECTION_INTERFACE_SIMPLE_PRESENCE) != NULL)
    {
      presence_hash = construct_simple_presence_hash (mixin_cls->statuses,
        contact_statuses);
      tp_svc_connection_interface_simple_presence_emit_presences_changed (obj,
        presence_hash);

      g_hash_table_unref (presence_hash);
    }
}


/**
 * tp_presence_mixin_emit_one_presence_update: (skip)
 * @obj: A connection object with this mixin
 * @handle: The handle of the contact to emit the signal for
 * @status: The new status to emit
 *
 * Emit the PresenceUpdate signal for a single contact. This method is just a
 * convenience wrapper around #tp_presence_mixin_emit_presence_update.
 */
void
tp_presence_mixin_emit_one_presence_update (GObject *obj,
                                            TpHandle handle,
                                            const TpPresenceStatus *status)
{
  GHashTable *contact_statuses;

  DEBUG ("called.");

  contact_statuses = g_hash_table_new (NULL, NULL);
  g_hash_table_insert (contact_statuses, GUINT_TO_POINTER (handle),
      (gpointer) status);
  tp_presence_mixin_emit_presence_update (obj, contact_statuses);

  g_hash_table_unref (contact_statuses);
}


/*
 * tp_presence_mixin_add_status:
 *
 * Implements D-Bus method AddStatus
 * on interface org.freedesktop.Telepathy.Connection.Interface.Presence
 */
static void
tp_presence_mixin_add_status (TpSvcConnectionInterfacePresence *iface,
                              const gchar *status,
                              GHashTable *parms,
                              DBusGMethodInvocation *context)
{
  TpBaseConnection *conn = TP_BASE_CONNECTION (iface);
  GError error = { TP_ERROR, TP_ERROR_NOT_IMPLEMENTED,
    "Only one status is possible at a time with this protocol!" };

  DEBUG ("called.");

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (conn, context);

  dbus_g_method_return_error (context, &error);
}


/*
 * tp_presence_mixin_clear_status:
 *
 * Implements D-Bus method ClearStatus
 * on interface org.freedesktop.Telepathy.Connection.Interface.Presence
 */
static void
tp_presence_mixin_clear_status (TpSvcConnectionInterfacePresence *iface,
                                DBusGMethodInvocation *context)
{
  GObject *obj = (GObject *) iface;
  TpBaseConnection *conn = TP_BASE_CONNECTION (iface);
  TpPresenceMixinClass *mixin_cls =
    TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  GError *error = NULL;

  DEBUG ("called.");

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (conn, context);

  if (!mixin_cls->set_own_status (obj, NULL, &error))
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  tp_svc_connection_interface_presence_return_from_clear_status (context);
}


/*
 * tp_presence_mixin_get_presence:
 *
 * Implements D-Bus method GetPresence
 * on interface org.freedesktop.Telepathy.Connection.Interface.Presence
 */
static void
tp_presence_mixin_get_presence (TpSvcConnectionInterfacePresence *iface,
                                const GArray *contacts,
                                DBusGMethodInvocation *context)
{
  GObject *obj = (GObject *) iface;
  TpBaseConnection *conn = TP_BASE_CONNECTION (obj);
  TpHandleRepoIface *contact_repo = tp_base_connection_get_handles (conn,
      TP_HANDLE_TYPE_CONTACT);
  TpPresenceMixinClass *mixin_cls =
    TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  GHashTable *contact_statuses;
  GHashTable *presence_hash;
  GError *error = NULL;

  DEBUG ("called.");

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (conn, context);

  if (contacts->len == 0)
    {
      presence_hash = g_hash_table_new (g_direct_hash, g_direct_equal);
      tp_svc_connection_interface_presence_return_from_get_presence (context,
          presence_hash);
      g_hash_table_unref (presence_hash);
      return;
    }

  if (!tp_handles_are_valid (contact_repo, contacts, FALSE, &error))
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  contact_statuses = mixin_cls->get_contact_statuses (obj, contacts, &error);

  if (!contact_statuses)
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  presence_hash = construct_presence_hash (mixin_cls->statuses,
      contact_statuses);
  tp_svc_connection_interface_presence_return_from_get_presence (context,
      presence_hash);
  g_hash_table_unref (presence_hash);
  g_hash_table_unref (contact_statuses);
}


static GHashTable *
get_statuses_arguments (const TpPresenceStatusOptionalArgumentSpec *specs)
{
  GHashTable *arguments = g_hash_table_new (g_str_hash, g_str_equal);
  int i;

  for (i=0; specs != NULL && specs[i].name != NULL; i++)
    g_hash_table_insert (arguments, (gchar *) specs[i].name,
        (gchar *) specs[i].dtype);

  return arguments;
}

static gboolean
check_status_available (GObject *object,
                        TpPresenceMixinClass *mixin_cls,
                        guint i,
                        GError **error,
                        gboolean for_self)
{
  if (for_self)
    {
      if (!mixin_cls->statuses[i].self)
        {
          g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
              "cannot set status '%s' on yourself",
              mixin_cls->statuses[i].name);
          return FALSE;
        }

      /* never allow OFFLINE, UNKNOWN or ERROR - if the CM says they're
       * OK to set on yourself, then it's wrong */
      switch (mixin_cls->statuses[i].presence_type)
        {
        case TP_CONNECTION_PRESENCE_TYPE_OFFLINE:
        case TP_CONNECTION_PRESENCE_TYPE_UNKNOWN:
        case TP_CONNECTION_PRESENCE_TYPE_ERROR:
          g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
              "cannot set offline/unknown/error status '%s' on yourself",
              mixin_cls->statuses[i].name);
          return FALSE;

        default:
          break;
        }
    }

  if (mixin_cls->status_available
      && !mixin_cls->status_available (object, i))
    {
      DEBUG ("requested status %s is not available",
          mixin_cls->statuses[i].name);
      g_set_error (error, TP_ERROR, TP_ERROR_NOT_AVAILABLE,
          "requested status '%s' is not available on this connection",
          mixin_cls->statuses[i].name);
      return FALSE;
    }

  return TRUE;
}

/*
 * tp_presence_mixin_get_statuses:
 *
 * Implements D-Bus method GetStatuses
 * on interface org.freedesktop.Telepathy.Connection.Interface.Presence
 */
static void
tp_presence_mixin_get_statuses (TpSvcConnectionInterfacePresence *iface,
                                DBusGMethodInvocation *context)
{
  TpBaseConnection *conn = TP_BASE_CONNECTION (iface);
  GObject *obj = (GObject *) conn;
  TpPresenceMixinClass *mixin_cls =
    TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  GHashTable *ret;
  GValueArray *status;
  int i;

  DEBUG ("called.");

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (conn, context);

  ret = g_hash_table_new_full (g_str_hash, g_str_equal,
                               NULL, (GDestroyNotify) tp_value_array_free);

  for (i=0; mixin_cls->statuses[i].name != NULL; i++)
    {
      GHashTable *args;

      /* the spec says we include statuses here even if they're not available
       * to set on yourself */
      if (!check_status_available (obj, mixin_cls, i, NULL, FALSE))
        continue;

      args = get_statuses_arguments (mixin_cls->statuses[i].optional_arguments);
      status = tp_value_array_build (4,
          G_TYPE_UINT, (guint) mixin_cls->statuses[i].presence_type,
          G_TYPE_BOOLEAN, mixin_cls->statuses[i].self,
          G_TYPE_BOOLEAN, TRUE, /* exclusive */
          DBUS_TYPE_G_STRING_STRING_HASHTABLE, args,
          G_TYPE_INVALID);
      g_hash_table_unref (args);

      g_hash_table_insert (ret, (gchar *) mixin_cls->statuses[i].name,
          status);
    }

  tp_svc_connection_interface_presence_return_from_get_statuses (context, ret);
  g_hash_table_unref (ret);
}


/*
 * tp_presence_mixin_set_last_activity_time:
 *
 * Implements D-Bus method SetLastActivityTime
 * on interface org.freedesktop.Telepathy.Connection.Interface.Presence
 */
static void
tp_presence_mixin_set_last_activity_time (TpSvcConnectionInterfacePresence *iface,
                                          guint timestamp,
                                          DBusGMethodInvocation *context)
{
  TpBaseConnection *conn = TP_BASE_CONNECTION (iface);

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (conn, context);

  tp_svc_connection_interface_presence_return_from_set_last_activity_time (
      context);
}


/*
 * tp_presence_mixin_remove_status:
 *
 * Implements D-Bus method RemoveStatus
 * on interface org.freedesktop.Telepathy.Connection.Interface.Presence
 */
static void
tp_presence_mixin_remove_status (TpSvcConnectionInterfacePresence *iface,
                                 const gchar *status,
                                 DBusGMethodInvocation *context)
{
  GObject *obj = (GObject *) iface;
  TpBaseConnection *conn = TP_BASE_CONNECTION (iface);
  TpPresenceMixinClass *mixin_cls =
    TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  GArray *self_contacts;
  GError *error = NULL;
  GHashTable *self_contact_statuses;
  TpPresenceStatus *self_status;
  TpHandle self_handle;

  DEBUG ("called.");

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (conn, context);

  self_contacts = g_array_sized_new (TRUE, TRUE, sizeof (TpHandle), 1);
  self_handle = tp_base_connection_get_self_handle (conn);
  g_array_append_val (self_contacts, self_handle);
  self_contact_statuses = mixin_cls->get_contact_statuses (obj, self_contacts,
      &error);

  if (!self_contact_statuses)
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      g_array_unref (self_contacts);
      return;
    }

  self_status = (TpPresenceStatus *) g_hash_table_lookup (self_contact_statuses,
      GUINT_TO_POINTER (tp_base_connection_get_self_handle (conn)));

  if (!self_status)
    {
      DEBUG ("Got no self status, assuming we already have default status");
      g_array_unref (self_contacts);
      g_hash_table_unref (self_contact_statuses);
      tp_svc_connection_interface_presence_return_from_remove_status (context);
      return;
    }

  if (!tp_strdiff (status, mixin_cls->statuses[self_status->index].name))
    {
      if (mixin_cls->set_own_status (obj, NULL, &error))
        {
          tp_svc_connection_interface_presence_return_from_remove_status (context);
        }
      else
        {
          dbus_g_method_return_error (context, error);
          g_error_free (error);
        }
    }
  else
    {
      GError nonexistent = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Attempting to remove non-existent presence." };
      dbus_g_method_return_error (context, &nonexistent);
    }

  g_array_unref (self_contacts);
  g_hash_table_unref (self_contact_statuses);
}


/*
 * tp_presence_mixin_request_presence:
 *
 * Implements D-Bus method RequestPresence
 * on interface org.freedesktop.Telepathy.Connection.Interface.Presence
 */
static void
tp_presence_mixin_request_presence (TpSvcConnectionInterfacePresence *iface,
                                    const GArray *contacts,
                                    DBusGMethodInvocation *context)
{
  GObject *obj = (GObject *) iface;
  TpPresenceMixinClass *mixin_cls =
    TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  TpBaseConnection *conn = TP_BASE_CONNECTION (iface);
  TpHandleRepoIface *contact_repo = tp_base_connection_get_handles (conn,
      TP_HANDLE_TYPE_CONTACT);
  GHashTable *contact_statuses;
  GError *error = NULL;

  DEBUG ("called.");

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (conn, context);

  if (contacts->len == 0)
    {
      tp_svc_connection_interface_presence_return_from_request_presence (context);
      return;
    }

  if (!tp_handles_are_valid (contact_repo, contacts, FALSE, &error))
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  contact_statuses = mixin_cls->get_contact_statuses (obj, contacts, &error);

  if (!contact_statuses)
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  tp_presence_mixin_emit_presence_update (obj, contact_statuses);
  tp_svc_connection_interface_presence_return_from_request_presence (context);

  g_hash_table_unref (contact_statuses);
}

static int
check_for_status (GObject *object, const gchar *status, GError **error)
{
  TpPresenceMixinClass *mixin_cls =
    TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (object));
  int i;

  for (i = 0; mixin_cls->statuses[i].name != NULL; i++)
    {
      if (!tp_strdiff (mixin_cls->statuses[i].name, status))
        break;
    }

  if (mixin_cls->statuses[i].name != NULL)
    {
      DEBUG ("Found status \"%s\", checking if it's available...",
          (const gchar *) status);

      if (!check_status_available (object, mixin_cls, i, error, TRUE))
        return -1;
    }
  else
    {
      DEBUG ("got unknown status identifier %s", status);
      g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "unknown status identifier: %s", status);
      return -1;
    }

  return i;
}

static gboolean
set_status (
    GObject *obj,
    const gchar *status_name,
    GHashTable *provided_arguments,
    GError **error)
{
  TpPresenceMixinClass *mixin_cls =
    TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  TpPresenceStatus status_to_set = { 0, };
  int status;
  GHashTable *optional_arguments = NULL;
  gboolean ret = TRUE;

  DEBUG ("called.");

  /* This function will actually only be invoked once for one SetStatus request,
   * since we check that the hash table has size 1 in
   * tp_presence_mixin_set_status(). Therefore there are no problems with
   * sharing the foreach data like this.
   */
  status = check_for_status (obj, status_name, error);

  if (status == -1)
    return FALSE;

  DEBUG ("The status is available.");

  if (provided_arguments != NULL)
    {
      int j;
      const TpPresenceStatusOptionalArgumentSpec *specs =
        mixin_cls->statuses[status].optional_arguments;

      for (j=0; specs != NULL && specs[j].name != NULL; j++)
        {
          GValue *provided_value =
            g_hash_table_lookup (provided_arguments, specs[j].name);
          GValue *new_value;

          if (!provided_value)
            continue;
          new_value = tp_g_value_slice_dup (provided_value);

          if (!optional_arguments)
            optional_arguments =
              g_hash_table_new_full (g_str_hash, g_str_equal, NULL,
                  (GDestroyNotify) tp_g_value_slice_free);

          if (DEBUGGING)
            {
              gchar *value_contents = g_strdup_value_contents (new_value);
              DEBUG ("Got optional argument (\"%s\", %s)", specs[j].name,
                  value_contents);
              g_free (value_contents);
            }

          g_hash_table_insert (optional_arguments,
              (gpointer) specs[j].name, new_value);
        }
    }

  status_to_set.index = status;
  status_to_set.optional_arguments = optional_arguments;

  DEBUG ("About to try setting status \"%s\"",
      mixin_cls->statuses[status].name);

  ret = mixin_cls->set_own_status (obj, &status_to_set, error);

  if (optional_arguments)
    g_hash_table_unref (optional_arguments);

  return ret;
}


/*
 * tp_presence_mixin_set_status:
 *
 * Implements D-Bus method SetStatus
 * on interface org.freedesktop.Telepathy.Connection.Interface.Presence
 */
static void
tp_presence_mixin_set_status (TpSvcConnectionInterfacePresence *iface,
                              GHashTable *statuses,
                              DBusGMethodInvocation *context)
{
  GObject *obj = (GObject *) iface;
  TpBaseConnection *conn = TP_BASE_CONNECTION (iface);
  GHashTableIter iter;
  gpointer key, value;
  GError *error = NULL;

  DEBUG ("called.");

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (conn, context);

  g_hash_table_iter_init (&iter, statuses);
  if (!g_hash_table_iter_next (&iter, &key, &value) ||
      g_hash_table_iter_next (&iter, NULL, NULL))
    {
      GError invalid = { TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
          "Only one status may be set at a time in this protocol" };
      DEBUG ("got more than one status");
      dbus_g_method_return_error (context, &invalid);
      return;
    }

  if (set_status (obj, key, value, &error))
    {
      tp_svc_connection_interface_presence_return_from_set_status (context);
    }
  else
    {
      DEBUG ("failed: %s", error->message);
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
}


/**
 * tp_presence_mixin_iface_init: (skip)
 * @g_iface: A pointer to the #TpSvcConnectionInterfacePresenceClass in an
 *  object class
 * @iface_data: Ignored
 *
 * Fill in the vtable entries needed to implement the presence interface using
 * this mixin. This function should usually be called via G_IMPLEMENT_INTERFACE.
 */
void
tp_presence_mixin_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcConnectionInterfacePresenceClass *klass = g_iface;

#define IMPLEMENT(x) tp_svc_connection_interface_presence_implement_##x (klass,\
    tp_presence_mixin_##x)
  IMPLEMENT(add_status);
  IMPLEMENT(clear_status);
  IMPLEMENT(get_presence);
  IMPLEMENT(get_statuses);
  IMPLEMENT(remove_status);
  IMPLEMENT(request_presence);
  IMPLEMENT(set_last_activity_time);
  IMPLEMENT(set_status);
#undef IMPLEMENT
}

enum {
  MIXIN_DP_SIMPLE_STATUSES,
  MIXIN_DP_SIMPLE_MAX_STATUS_MESSAGE_LENGTH,
  NUM_MIXIN_SIMPLE_DBUS_PROPERTIES
};

static TpDBusPropertiesMixinPropImpl known_simple_presence_props[] = {
  { "Statuses", NULL, NULL },
  { "MaximumStatusMessageLength", NULL, NULL },
  { NULL }
};

static void
tp_presence_mixin_get_simple_presence_dbus_property (GObject *object,
                                                     GQuark interface,
                                                     GQuark name,
                                                     GValue *value,
                                                     gpointer unused
                                                       G_GNUC_UNUSED)
{
  TpPresenceMixinClass *mixin_cls =
      TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (object));
  static GQuark q[NUM_MIXIN_SIMPLE_DBUS_PROPERTIES] = { 0, };

  DEBUG ("called.");

  if (G_UNLIKELY (q[0] == 0))
    {
      q[MIXIN_DP_SIMPLE_STATUSES] = g_quark_from_static_string ("Statuses");
      q[MIXIN_DP_SIMPLE_MAX_STATUS_MESSAGE_LENGTH] =
          g_quark_from_static_string ("MaximumStatusMessageLength");
    }

  g_return_if_fail (object != NULL);

  if (name == q[MIXIN_DP_SIMPLE_STATUSES])
    {
      GHashTable *ret;
      GValueArray *status;
      int i;

      g_return_if_fail (G_VALUE_HOLDS_BOXED (value));

      ret = g_hash_table_new_full (g_str_hash, g_str_equal,
                               NULL, (GDestroyNotify) tp_value_array_free);

      for (i=0; mixin_cls->statuses[i].name != NULL; i++)
        {
          gboolean message;

          /* we include statuses here even if they're not available
           * to set on yourself */
          if (!check_status_available (object, mixin_cls, i, NULL, FALSE))
            continue;

          message = tp_presence_status_spec_has_message (
              &mixin_cls->statuses[i]);

          status = tp_value_array_build (3,
             G_TYPE_UINT, (guint) mixin_cls->statuses[i].presence_type,
             G_TYPE_BOOLEAN, mixin_cls->statuses[i].self,
             G_TYPE_BOOLEAN, message,
             G_TYPE_INVALID);

         g_hash_table_insert (ret, (gchar *) mixin_cls->statuses[i].name,
             status);
       }
       g_value_take_boxed (value, ret);
    }
  else if (name == q[MIXIN_DP_SIMPLE_MAX_STATUS_MESSAGE_LENGTH])
    {
      guint max_status_message_length = 0;

      g_assert (G_VALUE_HOLDS (value, G_TYPE_UINT));

      if (mixin_cls->get_maximum_status_message_length != NULL)
        max_status_message_length =
            mixin_cls->get_maximum_status_message_length (object);

      g_value_set_uint (value, max_status_message_length);
    }
  else
    {
      g_return_if_reached ();
    }

}

/**
 * tp_presence_mixin_simple_presence_init_dbus_properties: (skip)
 * @cls: The class of an object with this mixin
 *
 * Set up #TpDBusPropertiesMixinClass to use this mixin's implementation of
 * the SimplePresence interface's properties.
 *
 * This automatically sets up a list of the supported properties for the
 * SimplePresence interface.
 *
 * Since: 0.7.13
 */
void
tp_presence_mixin_simple_presence_init_dbus_properties (GObjectClass *cls)
{

  tp_dbus_properties_mixin_implement_interface (cls,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_SIMPLE_PRESENCE,
      tp_presence_mixin_get_simple_presence_dbus_property,
      NULL, known_simple_presence_props);
}

/*
 * tp_presence_mixin_simple_presence_set_presence:
 *
 * Implements D-Bus method SetPresence
 * on interface org.freedesktop.Telepathy.Connection.Interface.SimplePresence
 */
static void
tp_presence_mixin_simple_presence_set_presence (
    TpSvcConnectionInterfaceSimplePresence *iface,
    const gchar *status,
    const gchar *message,
    DBusGMethodInvocation *context)
{
  GObject *obj = (GObject *) iface;
  TpPresenceMixinClass *mixin_cls =
    TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  TpPresenceStatus status_to_set = { 0, };
  int s;
  GError *error = NULL;
  GHashTable *optional_arguments = NULL;

  DEBUG ("called.");

  s = check_for_status (obj, status, &error);
  if (s == -1)
    goto out;

  status_to_set.index = s;

  if (*message != '\0')
    {
      optional_arguments = g_hash_table_new_full (g_str_hash, g_str_equal,
          NULL, (GDestroyNotify) tp_g_value_slice_free);
      g_hash_table_insert (optional_arguments, "message",
          tp_g_value_slice_new_string (message));
      status_to_set.optional_arguments = optional_arguments;
    }

  mixin_cls->set_own_status (obj, &status_to_set, &error);

out:
  if (error == NULL)
    {
      tp_svc_connection_interface_simple_presence_return_from_set_presence (
          context);
    }
  else
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }

  if (optional_arguments != NULL)
    g_hash_table_unref (optional_arguments);
}

static GValueArray *
construct_simple_presence_value_array (TpPresenceStatus *status,
    const TpPresenceStatusSpec *supported_statuses)
{
  TpConnectionPresenceType status_type;
  const gchar *status_name;
  const gchar *message = NULL;
  GValueArray *presence;

  status_name = supported_statuses[status->index].name;
  status_type = supported_statuses[status->index].presence_type;

  if (status->optional_arguments != NULL)
    {
      GValue *val;
      val = g_hash_table_lookup (status->optional_arguments, "message");
      if (val != NULL)
        message = g_value_get_string (val);
    }

  if (message == NULL)
    message = "";

  presence = tp_value_array_build (3,
      G_TYPE_UINT, status_type,
      G_TYPE_STRING, status_name,
      G_TYPE_STRING, message,
      G_TYPE_INVALID);

  return presence;
}

static void
construct_simple_presence_hash_foreach (
    GHashTable *presence_hash,
    const TpPresenceStatusSpec *supported_statuses,
    TpHandle handle,
    TpPresenceStatus *status)
{
  GValueArray *presence;

  presence = construct_simple_presence_value_array (status, supported_statuses);
  g_hash_table_insert (presence_hash, GUINT_TO_POINTER (handle), presence);
}

static GHashTable *
construct_simple_presence_hash (const TpPresenceStatusSpec *supported_statuses,
                         GHashTable *contact_statuses)
{
  GHashTable *presence_hash = g_hash_table_new_full (NULL, NULL, NULL,
      (GDestroyNotify) tp_value_array_free);
  GHashTableIter iter;
  gpointer key, value;

  DEBUG ("called.");

  g_hash_table_iter_init (&iter, contact_statuses);
  while (g_hash_table_iter_next (&iter, &key, &value))
    construct_simple_presence_hash_foreach (presence_hash, supported_statuses,
        GPOINTER_TO_UINT (key), value);

  return presence_hash;
}

/*
 * tp_presence_mixin_get_simple_presence:
 *
 * Implements D-Bus method GetPresence
 * on interface org.freedesktop.Telepathy.Connection.Interface.SimplePresence
 */
static void
tp_presence_mixin_simple_presence_get_presences (
    TpSvcConnectionInterfaceSimplePresence *iface,
    const GArray *contacts,
    DBusGMethodInvocation *context)
{
  GObject *obj = (GObject *) iface;
  TpBaseConnection *conn = TP_BASE_CONNECTION (obj);
  TpHandleRepoIface *contact_repo = tp_base_connection_get_handles (conn,
      TP_HANDLE_TYPE_CONTACT);
  TpPresenceMixinClass *mixin_cls =
    TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  GHashTable *contact_statuses;
  GHashTable *presence_hash;
  GError *error = NULL;

  DEBUG ("called.");

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (conn, context);

  if (contacts->len == 0)
    {
      presence_hash = g_hash_table_new (g_direct_hash, g_direct_equal);
      tp_svc_connection_interface_simple_presence_return_from_get_presences (
        context, presence_hash);
      g_hash_table_unref (presence_hash);
      return;
    }

  if (!tp_handles_are_valid (contact_repo, contacts, FALSE, &error))
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  contact_statuses = mixin_cls->get_contact_statuses (obj, contacts, &error);

  if (!contact_statuses)
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  presence_hash = construct_simple_presence_hash (mixin_cls->statuses,
      contact_statuses);
  tp_svc_connection_interface_simple_presence_return_from_get_presences (
      context, presence_hash);
  g_hash_table_unref (presence_hash);
  g_hash_table_unref (contact_statuses);
}

/**
 * tp_presence_mixin_simple_presence_iface_init: (skip)
 * @g_iface: A pointer to the #TpSvcConnectionInterfaceSimplePresenceClass in
 * an object class
 * @iface_data: Ignored
 *
 * Fill in the vtable entries needed to implement the simple presence interface
 * using this mixin. This function should usually be called via
 * G_IMPLEMENT_INTERFACE.
 *
 * Since: 0.7.13
 */
void
tp_presence_mixin_simple_presence_iface_init (gpointer g_iface,
                                              gpointer iface_data)
{
  TpSvcConnectionInterfaceSimplePresenceClass *klass = g_iface;

#define IMPLEMENT(x) tp_svc_connection_interface_simple_presence_implement_##x\
 (klass, tp_presence_mixin_simple_presence_##x)
  IMPLEMENT(set_presence);
  IMPLEMENT(get_presences);
#undef IMPLEMENT
}

static void
tp_presence_mixin_simple_presence_fill_contact_attributes (GObject *obj,
  const GArray *contacts, GHashTable *attributes_hash)
{
  TpPresenceMixinClass *mixin_cls =
    TP_PRESENCE_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));
  GHashTable *contact_statuses;
  GError *error = NULL;

  contact_statuses = mixin_cls->get_contact_statuses (obj, contacts, &error);

  if (contact_statuses == NULL)
    {
      DEBUG ("get_contact_statuses failed: %s", error->message);
      g_error_free (error);
    }
  else
    {
      GHashTableIter iter;
      gpointer key, value;
      G_GNUC_BEGIN_IGNORE_DEPRECATIONS
      GType type = G_TYPE_VALUE_ARRAY;
      G_GNUC_END_IGNORE_DEPRECATIONS

      g_hash_table_iter_init (&iter, contact_statuses);
      while (g_hash_table_iter_next (&iter, &key, &value))
        {
          TpHandle handle = GPOINTER_TO_UINT (key);
          TpPresenceStatus *status = value;
          GValueArray *presence = construct_simple_presence_value_array (
              status, mixin_cls->statuses);

          tp_contacts_mixin_set_contact_attribute (attributes_hash, handle,
              TP_TOKEN_CONNECTION_INTERFACE_SIMPLE_PRESENCE_PRESENCE,
              tp_g_value_slice_new_take_boxed (type, presence));
        }

      g_hash_table_unref (contact_statuses);
    }
}

/**
 * tp_presence_mixin_simple_presence_register_with_contacts_mixin: (skip)
 * @obj: An instance that of the implementation that uses both the Contacts
 * mixin and this mixin
 *
 * Register the SimplePresence interface with the Contacts interface to make it
 * inspectable. The Contacts mixin should be initialized before this function
 * is called
 */
void
tp_presence_mixin_simple_presence_register_with_contacts_mixin (GObject *obj)
{
  tp_contacts_mixin_add_contact_attributes_iface (obj,
      TP_IFACE_CONNECTION_INTERFACE_SIMPLE_PRESENCE,
      tp_presence_mixin_simple_presence_fill_contact_attributes);
}

/* For now, self->priv is just self if heap-allocated, NULL if not. */
static gboolean
_tp_presence_status_spec_is_heap_allocated (const TpPresenceStatusSpec *self)
{
  return (self->priv == (TpPresenceStatusSpecPrivate *) self);
}

/**
 * tp_presence_status_spec_get_presence_type:
 * @self: a presence status specification
 *
 * Return the category into which this presence type falls. For instance,
 * for XMPP's "" (do not disturb) status, this would return
 * %TP_CONNECTION_PRESENCE_TYPE_BUSY.
 *
 * Returns: a #TpConnectionPresenceType
 * Since: 0.23.1
 */
TpConnectionPresenceType
tp_presence_status_spec_get_presence_type (const TpPresenceStatusSpec *self)
{
  g_return_val_if_fail (self != NULL, TP_CONNECTION_PRESENCE_TYPE_UNSET);

  return self->presence_type;
}

/**
 * tp_presence_status_spec_get_name:
 * @self: a presence status specification
 *
 * <!-- -->
 *
 * Returns: (transfer none): the name of this presence status,
 *  such as "available" or "out-to-lunch".
 * Since: 0.23.1
 */
const gchar *
tp_presence_status_spec_get_name (const TpPresenceStatusSpec *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return self->name;
}

/**
 * tp_presence_status_spec_can_set_on_self:
 * @self: a presence status specification
 *
 * <!-- -->
 *
 * Returns: %TRUE if the user can set this presence status on themselves (most
 *  statuses), or %FALSE if they cannot directly set it on
 *  themselves (typically used for %TP_CONNECTION_PRESENCE_TYPE_OFFLINE
 *  and %TP_CONNECTION_PRESENCE_TYPE_ERROR)
 * Since: 0.23.1
 */
gboolean
tp_presence_status_spec_can_set_on_self (const TpPresenceStatusSpec *self)
{
  g_return_val_if_fail (self != NULL, FALSE);

  return self->self;
}

/**
 * tp_presence_status_spec_has_message:
 * @self: a presence status specification
 *
 * <!-- -->
 *
 * Returns: %TRUE if this presence status is accompanied by an optional
 *  human-readable message
 * Since: 0.23.1
 */
gboolean
tp_presence_status_spec_has_message (const TpPresenceStatusSpec *self)
{
  const TpPresenceStatusOptionalArgumentSpec *arg;

  g_return_val_if_fail (self != NULL, FALSE);

  if (self->optional_arguments == NULL)
    return FALSE;

  for (arg = self->optional_arguments; arg->name != NULL; arg++)
    {
      if (!tp_strdiff (arg->name, "message") && !tp_strdiff (arg->dtype, "s"))
        return TRUE;
    }

  return FALSE;
}

/**
 * tp_presence_status_spec_new:
 * @name: the name of the new presence status
 * @type: the category into which this presence status falls
 * @can_set_on_self: %TRUE if the user can set this presence status
 *  on themselves
 * @has_message: %TRUE if this presence status is accompanied by an
 *  optional human-readable message
 *
 * <!-- -->
 *
 * Returns: (transfer full): a new #TpPresenceStatusSpec
 * Since: 0.23.1
 */
TpPresenceStatusSpec *
tp_presence_status_spec_new (const gchar *name,
    TpConnectionPresenceType type,
    gboolean can_set_on_self,
    gboolean has_message)
{
  TpPresenceStatusSpec *ret;
  static const TpPresenceStatusOptionalArgumentSpec yes_it_has_a_message[] = {
        { "message", "s" },
        { NULL }
  };

  g_return_val_if_fail (!tp_str_empty (name), NULL);
  g_return_val_if_fail (type >= 0 && type < TP_NUM_CONNECTION_PRESENCE_TYPES,
      NULL);

  ret = g_slice_new0 (TpPresenceStatusSpec);

  ret->name = g_strdup (name);
  ret->presence_type = type;
  ret->self = can_set_on_self;

  if (has_message)
    ret->optional_arguments = yes_it_has_a_message;
  else
    ret->optional_arguments = NULL;

  /* dummy marker for "this is on the heap" rather than a real struct */
  ret->priv = (TpPresenceStatusSpecPrivate *) ret;

  return ret;
}

/**
 * tp_presence_status_spec_copy:
 * @self: a presence status specification
 *
 * Copy a presence status specification.
 *
 * If @self has optional arguments other than a string named "message",
 * they are not copied. Optional arguments with other names or types
 * are deprecated.
 *
 * Returns: (transfer full): a new #TpPresenceStatusSpec resembling @self
 * Since: 0.23.1
 */
TpPresenceStatusSpec *
tp_presence_status_spec_copy (const TpPresenceStatusSpec *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return tp_presence_status_spec_new (self->name, self->presence_type,
      self->self, tp_presence_status_spec_has_message (self));
}

/**
 * tp_presence_status_spec_free:
 * @self: (transfer full): a presence status specification
 *
 * Free a presence status specification produced by
 * tp_presence_status_spec_new() or tp_presence_status_spec_copy().
 *
 * Since: 0.23.1
 */
void
tp_presence_status_spec_free (TpPresenceStatusSpec *self)
{
  g_return_if_fail (_tp_presence_status_spec_is_heap_allocated (self));

  /* This struct was designed to always be on the stack, so freeing this
   * needs a non-const-correct cast */
  g_free ((gchar *) self->name);

  g_slice_free (TpPresenceStatusSpec, self);
}

G_DEFINE_BOXED_TYPE (TpPresenceStatusSpec, tp_presence_status_spec,
    tp_presence_status_spec_copy, tp_presence_status_spec_free)
