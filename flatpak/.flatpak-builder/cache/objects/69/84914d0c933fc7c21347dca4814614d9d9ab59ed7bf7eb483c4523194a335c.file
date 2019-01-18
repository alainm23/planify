/*
 * contacts-mixin.c - Source for TpContactsMixin
 * Copyright © 2008-2010 Collabora Ltd.
 * Copyright © 2008 Nokia Corporation
 *   @author Sjoerd Simons <sjoerd.simons@collabora.co.uk>
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
 * SECTION:contacts-mixin
 * @title: TpContactsMixin
 * @short_description: a mixin implementation of the contacts connection
 * interface
 * @see_also: #TpSvcConnectionInterfaceContacts
 *
 * This mixin can be added to a #TpBaseConnection subclass to implement the
 * Contacts interface in a generic way.
 *
 * To use the contacts mixin, include a #TpContactsMixinClass somewhere in
 * your class structure and a #TpContactsMixin somewhere in your instance
 * structure, and call tp_contacts_mixin_class_init() from your class_init
 * function, tp_contacts_mixin_init() from your init function or constructor,
 * and tp_contacts_mixin_finalize() from your dispose or finalize function.
 *
 * To use the contacts mixin as the implementation of
 * #TpSvcConnectionInterfaceContacts, in the function you pass to
 * G_IMPLEMENT_INTERFACE, you should call tp_contacts_mixin_iface_init.
 * TpContactsMixin implements all of the D-Bus methods and properties in the
 * Contacts interface.
 *
 * To add interfaces with contact attributes to this interface use
 * tp_contacts_mixin_add_contact_attributes_iface:
 *
 * Since: 0.7.14
 *
 */

#include "config.h"

#include <telepathy-glib/contacts-mixin.h>

#include <dbus/dbus-glib-lowlevel.h>
#include <dbus/dbus-glib.h>

#include <telepathy-glib/base-connection.h>
#include <telepathy-glib/dbus.h>
#include <telepathy-glib/enums.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>

#define DEBUG_FLAG TP_DEBUG_CONNECTION

#include "debug-internal.h"

struct _TpContactsMixinPrivate
{
  /* String interface name -> FillContactAttributes func */
  GHashTable *interfaces;
};

enum {
  MIXIN_DP_CONTACT_ATTRIBUTE_INTERFACES,
  NUM_MIXIN_CONTACTS_DBUS_PROPERTIES
};

static TpDBusPropertiesMixinPropImpl known_contacts_props[] = {
  { "ContactAttributeInterfaces", NULL, NULL },
  { NULL }
};

static const gchar *always_included_interfaces[] = {
  TP_IFACE_CONNECTION,
  NULL
};

static void
tp_presence_mixin_get_contacts_dbus_property (GObject *object,
                                              GQuark interface,
                                              GQuark name,
                                              GValue *value,
                                              gpointer unused
                                              G_GNUC_UNUSED)
{
  static GQuark q[NUM_MIXIN_CONTACTS_DBUS_PROPERTIES] = { 0, };
  TpContactsMixin *self = TP_CONTACTS_MIXIN (object);

  DEBUG ("called.");

  if (G_UNLIKELY (q[0] == 0))
    {
      q[MIXIN_DP_CONTACT_ATTRIBUTE_INTERFACES] =
        g_quark_from_static_string ("ContactAttributeInterfaces");
    }

  g_return_if_fail (object != NULL);

  if (name == q[MIXIN_DP_CONTACT_ATTRIBUTE_INTERFACES])
    {
      gchar **interfaces;
      GHashTableIter iter;
      gpointer key;
      int i = 0;

      g_assert (G_VALUE_HOLDS(value, G_TYPE_STRV));

      /* FIXME, cache this when connected ? */
      interfaces = g_malloc0(
        (g_hash_table_size (self->priv->interfaces) + 1) * sizeof (gchar *));

      g_hash_table_iter_init (&iter, self->priv->interfaces);
      while (g_hash_table_iter_next (&iter, &key, NULL))
          {
            interfaces[i] = g_strdup ((gchar *) key);
            i++;
          }
      g_value_take_boxed (value, interfaces);
    }
  else
    {
      g_assert_not_reached ();
    }
}


/**
 * tp_contacts_mixin_class_get_offset_quark: (skip)
 *
 * <!--no documentation beyond Returns: needed-->
 *
 * Returns: the quark used for storing mixin offset on a GObjectClass
 *
 * Since: 0.7.14
 *
 */
GQuark
tp_contacts_mixin_class_get_offset_quark ()
{
  static GQuark offset_quark = 0;

  if (G_UNLIKELY (offset_quark == 0))
    offset_quark = g_quark_from_static_string (
        "TpContactsMixinClassOffsetQuark");

  return offset_quark;
}

/**
 * tp_contacts_mixin_get_offset_quark: (skip)
 *
 * <!--no documentation beyond Returns: needed-->
 *
 * Returns: the quark used for storing mixin offset on a GObject
 *
 * Since: 0.7.14
 *
 */
GQuark
tp_contacts_mixin_get_offset_quark ()
{
  static GQuark offset_quark = 0;

  if (G_UNLIKELY (offset_quark == 0))
    offset_quark = g_quark_from_static_string ("TpContactsMixinOffsetQuark");

  return offset_quark;
}


/**
 * tp_contacts_mixin_class_init: (skip)
 * @obj_cls: The class of the implementation that uses this mixin
 * @offset: The byte offset of the TpContactsMixinClass within the class
 *          structure
 *
 * Initialize the contacts mixin. Should be called from the implementation's
 * class_init function like so:
 *
 * <informalexample><programlisting>
 * tp_contacts_mixin_class_init ((GObjectClass *) klass,
 *                          G_STRUCT_OFFSET (SomeObjectClass, contacts_mixin));
 * </programlisting></informalexample>
 *
 * Since: 0.7.14
 *
 */

void
tp_contacts_mixin_class_init (GObjectClass *obj_cls, glong offset)
{
  g_assert (G_IS_OBJECT_CLASS (obj_cls));

  g_type_set_qdata (G_OBJECT_CLASS_TYPE (obj_cls),
      TP_CONTACTS_MIXIN_CLASS_OFFSET_QUARK,
      GINT_TO_POINTER (offset));

  tp_dbus_properties_mixin_implement_interface (obj_cls,
      TP_IFACE_QUARK_CONNECTION_INTERFACE_CONTACTS,
      tp_presence_mixin_get_contacts_dbus_property,
      NULL, known_contacts_props);
}


/**
 * tp_contacts_mixin_init: (skip)
 * @obj: An instance of the implementation that uses this mixin
 * @offset: The byte offset of the TpContactsMixin within the object structure
 *
 * Initialize the contacts mixin. Should be called from the implementation's
 * instance init function like so:
 *
 * <informalexample><programlisting>
 * tp_contacts_mixin_init ((GObject *) self,
 *                     G_STRUCT_OFFSET (SomeObject, contacts_mixin));
 * </programlisting></informalexample>
 *
 * Since: 0.7.14
 *
 */
void
tp_contacts_mixin_init (GObject *obj, gsize offset)
{
  TpContactsMixin *mixin;

  g_assert (G_IS_OBJECT (obj));

  g_type_set_qdata (G_OBJECT_TYPE (obj),
                    TP_CONTACTS_MIXIN_OFFSET_QUARK,
                    GSIZE_TO_POINTER (offset));

  mixin = TP_CONTACTS_MIXIN (obj);

  mixin->priv = g_slice_new0 (TpContactsMixinPrivate);
  mixin->priv->interfaces = g_hash_table_new_full (g_str_hash, g_str_equal,
    g_free, NULL);
}

/**
 * tp_contacts_mixin_finalize: (skip)
 * @obj: An object with this mixin.
 *
 * Free resources held by the contacts mixin.
 *
 * Since: 0.7.14
 *
 */
void
tp_contacts_mixin_finalize (GObject *obj)
{
  TpContactsMixin *mixin = TP_CONTACTS_MIXIN (obj);

  DEBUG ("%p", obj);

  /* free any data held directly by the object here */
  g_hash_table_unref (mixin->priv->interfaces);
  g_slice_free (TpContactsMixinPrivate, mixin->priv);
}

/**
 * tp_contacts_mixin_get_contact_attributes: (skip)
 * @obj: A connection instance that uses this mixin. The connection must be connected.
 * @handles: List of handles to retrieve contacts for. Any invalid handles will be
 * dropped from the returned mapping.
 * @interfaces: A list of interfaces to retrieve attributes from.
 * @assumed_interfaces: A list of additional interfaces to retrieve attributes
 *  from. This can be used for interfaces documented as automatically included,
 *  like %TP_IFACE_CONNECTION for GetContactAttributes,
 *  or %TP_IFACE_CONNECTION and %TP_IFACE_CONNECTION_INTERFACE_CONTACT_LIST for
 *  GetContactListAttributes.
 * @sender: The DBus client's unique name. If this is not NULL, the requested handles
 * will be held on behalf of this client.
 *
 * Get contact attributes for the given contacts. Provide attributes for all requested
 * interfaces. If contact attributes are not immediately known, the behaviour is defined
 * by the interface; the attribute should either be omitted from the result or replaced
 * with a default value.
 *
 * Returns: A dictionary mapping the contact handles to contact attributes.
 *
 */
GHashTable *
tp_contacts_mixin_get_contact_attributes (GObject *obj,
    const GArray *handles,
    const gchar **interfaces,
    const gchar **assumed_interfaces,
    const gchar *sender)
{
  GHashTable *result;
  guint i;
  TpBaseConnection *conn = TP_BASE_CONNECTION (obj);
  TpContactsMixin *self = TP_CONTACTS_MIXIN (obj);
  TpHandleRepoIface *contact_repo = tp_base_connection_get_handles (conn,
        TP_HANDLE_TYPE_CONTACT);
  GArray *valid_handles;
  TpContactsMixinFillContactAttributesFunc func;

  g_return_val_if_fail (TP_IS_BASE_CONNECTION (obj), NULL);
  g_return_val_if_fail (TP_CONTACTS_MIXIN_OFFSET (obj) != 0, NULL);
  g_return_val_if_fail (tp_base_connection_check_connected (conn, NULL), NULL);

  /* Setup handle array and hash with valid handles, optionally holding them */
  valid_handles = g_array_sized_new (TRUE, TRUE, sizeof (TpHandle),
      handles->len);
  result = g_hash_table_new_full (g_direct_hash, g_direct_equal, NULL,
      (GDestroyNotify) g_hash_table_unref);

  for (i = 0 ; i < handles->len ; i++)
    {
      TpHandle h;
      h = g_array_index (handles, TpHandle, i);
      if (tp_handle_is_valid (contact_repo, h, NULL))
        {
          GHashTable *attr_hash = g_hash_table_new_full (g_str_hash,
              g_str_equal, g_free, (GDestroyNotify) tp_g_value_slice_free);
          g_array_append_val (valid_handles, h);
          g_hash_table_insert (result, GUINT_TO_POINTER(h), attr_hash);
        }
    }

  for (i = 0; assumed_interfaces != NULL && assumed_interfaces[i] != NULL; i++)
    {
      func = g_hash_table_lookup (self->priv->interfaces, assumed_interfaces[i]);

      if (func == NULL)
        DEBUG ("non-inspectable assumed interface %s given; ignoring",
            assumed_interfaces[i]);
      else
        func (obj, valid_handles, result);
    }

  for (i = 0; interfaces != NULL && interfaces[i] != NULL; i++)
    {

      func = g_hash_table_lookup (self->priv->interfaces, interfaces[i]);

      if (func == NULL)
        DEBUG ("non-inspectable interface %s given; ignoring", interfaces[i]);
      else
        func (obj, valid_handles, result);
    }

  g_array_unref (valid_handles);

  return result;
}

static void
tp_contacts_mixin_get_contact_attributes_impl (
  TpSvcConnectionInterfaceContacts *iface,
  const GArray *handles,
  const char **interfaces,
  gboolean hold,
  DBusGMethodInvocation *context)
{
  TpBaseConnection *conn = TP_BASE_CONNECTION (iface);
  GHashTable *result;

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (conn, context);

  result = tp_contacts_mixin_get_contact_attributes (G_OBJECT (conn),
      handles, interfaces, always_included_interfaces, NULL);

  tp_svc_connection_interface_contacts_return_from_get_contact_attributes (
      context, result);

  g_hash_table_unref (result);
}

typedef struct
{
  TpBaseConnection *conn;
  GStrv interfaces;
  DBusGMethodInvocation *context;
} GetContactByIdData;

static void
ensure_handle_cb (GObject *source,
    GAsyncResult *result,
    gpointer user_data)
{
  TpHandleRepoIface *contact_repo = (TpHandleRepoIface *) source;
  GetContactByIdData *data = user_data;
  TpHandle handle;
  GArray *handles;
  GHashTable *attributes;
  GHashTable *ret;
  GError *error = NULL;

  handle = tp_handle_ensure_finish (contact_repo, result, &error);
  if (handle == 0)
    {
      dbus_g_method_return_error (data->context, error);
      g_clear_error (&error);
      goto out;
    }

  handles = g_array_new (FALSE, FALSE, sizeof (TpHandle));
  g_array_append_val (handles, handle);

  attributes = tp_contacts_mixin_get_contact_attributes (G_OBJECT (data->conn),
      handles, (const gchar **) data->interfaces, always_included_interfaces,
      NULL);

  ret = g_hash_table_lookup (attributes, GUINT_TO_POINTER (handle));
  g_assert (ret != NULL);

  tp_svc_connection_interface_contacts_return_from_get_contact_by_id (
      data->context, handle, ret);

  g_array_unref (handles);
  g_hash_table_unref (attributes);

out:
  g_object_unref (data->conn);
  g_strfreev (data->interfaces);
  g_slice_free (GetContactByIdData, data);
}

static void
tp_contacts_mixin_get_contact_by_id_impl (
  TpSvcConnectionInterfaceContacts *iface,
  const gchar *id,
  const gchar **interfaces,
  DBusGMethodInvocation *context)
{
  TpBaseConnection *conn = TP_BASE_CONNECTION (iface);
  TpHandleRepoIface *contact_repo = tp_base_connection_get_handles (conn,
      TP_HANDLE_TYPE_CONTACT);
  GetContactByIdData *data;

  TP_BASE_CONNECTION_ERROR_IF_NOT_CONNECTED (conn, context);

  data = g_slice_new0 (GetContactByIdData);
  data->conn = g_object_ref (conn);
  data->interfaces = g_strdupv ((gchar **) interfaces);
  data->context = context;

  tp_handle_ensure_async (contact_repo, conn, id, NULL,
      ensure_handle_cb, data);
}

/**
 * tp_contacts_mixin_iface_init: (skip)
 * @g_iface: A pointer to the #TpSvcConnectionInterfaceContacts in an object
 * class
 * @iface_data: Ignored
 *
 * Fill in the vtable entries needed to implement the contacts interface
 * using this mixin. This function should usually be called via
 * G_IMPLEMENT_INTERFACE.
 *
 * Since: 0.7.14
 *
 */
void
tp_contacts_mixin_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcConnectionInterfaceContactsClass *klass =
    (TpSvcConnectionInterfaceContactsClass *) g_iface;

#define IMPLEMENT(x) tp_svc_connection_interface_contacts_implement_##x ( \
    klass, tp_contacts_mixin_##x##_impl)
  IMPLEMENT(get_contact_attributes);
  IMPLEMENT(get_contact_by_id);
#undef IMPLEMENT
}

/**
 * tp_contacts_mixin_add_contact_attributes_iface: (skip)
 * @obj: An instance of the implementation that uses this mixin
 * @interface: Name of the interface that has ContactAttributes
 * @fill_contact_attributes: Contact attribute filler function
 *
 * Declare that the given interface has contact attributes which can be added
 * to the attributes hash using the filler function. All the handles in the
 * handle array passed to the filler function are guaranteed to be valid and
 * referenced.
 *
 * Since: 0.7.14
 *
 */

void
tp_contacts_mixin_add_contact_attributes_iface (GObject *obj,
    const gchar *interface,
    TpContactsMixinFillContactAttributesFunc fill_contact_attributes)
{
  TpContactsMixin *self = TP_CONTACTS_MIXIN (obj);

  g_assert (g_hash_table_lookup (self->priv->interfaces, interface) == NULL);
  g_assert (fill_contact_attributes != NULL);

  g_hash_table_insert (self->priv->interfaces, g_strdup (interface),
    fill_contact_attributes);
}

/**
 * tp_contacts_mixin_set_contact_attribute: (skip)
 * @contact_attributes: contacts attribute hash as passed to
 *   TpContactsMixinFillContactAttributesFunc
 * @handle: Handle to set the attribute on
 * @attribute: attribute name
 * @value: slice allocated GValue containing the value of the attribute, for
 * instance with tp_g_value_slice_new. Ownership of the GValue is taken over by
 * the mixin
 *
 * Utility function to set attribute for handle to value in the attributes hash
 * as passed to a TpContactsMixinFillContactAttributesFunc.
 *
 * Since: 0.7.14
 *
 */

void
tp_contacts_mixin_set_contact_attribute (GHashTable *contact_attributes,
    TpHandle handle, const gchar *attribute, GValue *value)
{
  GHashTable *attributes;

  attributes = g_hash_table_lookup (contact_attributes,
    GUINT_TO_POINTER (handle));

  g_assert (attributes != NULL);
  g_assert (G_IS_VALUE (value));

  g_hash_table_insert (attributes, g_strdup (attribute), value);
}

