/*
 * connection-contact-info.c - proxy for a Telepathy connection
 *
 * Copyright (C) 2010 Collabora Ltd. <http://www.collabora.co.uk/>
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

#include "telepathy-glib/connection.h"

#include <string.h>

#include <dbus/dbus-protocol.h>

#include <telepathy-glib/dbus.h>
#include <telepathy-glib/gtypes.h>
#include <telepathy-glib/interfaces.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_CONNECTION
#include "telepathy-glib/connection-internal.h"
#include "telepathy-glib/debug-internal.h"
#include "telepathy-glib/proxy-internal.h"
#include "telepathy-glib/util-internal.h"

/**
 * TpContactInfoFieldSpec:
 * @name: The name of the field; this is the lowercased name of a vCard
 *  field. For example, a field representing a contact's address would be named
 *  "adr".
 * @parameters: The set of vCard type parameters which may be set on this field.
 *  If this list is empty and the #TP_CONTACT_INFO_FIELD_FLAG_PARAMETERS_EXACT
 *  flag is not set, any vCard type parameters may be used. The type parameter
 *  names, and any values that are case-insensitive in vCard, MUST be in lower
 *  case. For example, a contact's preferred home address would have parameters
 *  'type=home' and 'type=pref'.
 * @flags: Flags describing the behaviour of this field.
 * @max: Maximum number of instances of this field which may be set.
 *  #G_MAXUINT32 is used to indicate that there is no limit.
 *
 * A struct describing a vCard field.
 *
 * Since: 0.11.7
 */

/**
 * _tp_contact_info_field_spec_new:
 * @name: The name of the field; this is the lowercased name of a vCard
 *  field. For example, a field representing a contact's address would be named
 *  "adr".
 * @parameters: The set of vCard type parameters which may be set on this field.
 *  If this list is empty and the #TP_CONTACT_INFO_FIELD_FLAG_PARAMETERS_EXACT
 *  flag is not set, any vCard type parameters may be used. The type parameter
 *  names, and any values that are case-insensitive in vCard, MUST be in lower
 *  case. For example, a contact's preferred home address would have parameters
 *  'type=home' and 'type=pref'.
 * @flags: Flags describing the behaviour of this field.
 * @max: Maximum number of instances of this field which may be set.
 *  #G_MAXUINT32 is used to indicate that there is no limit.
 *
 * <!--Returns: says it all-->
 *
 * Returns: a newly allocated #TpContactInfoFieldSpec, free it with
 * tp_contact_info_field_spec_free()
 * Since: 0.11.7
 */
TpContactInfoFieldSpec *
_tp_contact_info_field_spec_new (const gchar *name,
    GStrv parameters,
    TpContactInfoFieldFlags flags,
    guint max)
{
  TpContactInfoFieldSpec *self;
  gchar *empty[] = { NULL };

  self = g_slice_new0 (TpContactInfoFieldSpec);
  self->name = g_strdup (name);
  self->parameters = g_strdupv (parameters ? parameters : empty);
  self->flags = flags;
  self->max = max;

  return self;
}

/**
 * tp_contact_info_field_spec_copy: (skip)
 * @self: a #TpContactInfoFieldSpec
 *
 * <!--Returns: says it all-->
 *
 * Returns: a newly allocated #TpContactInfoFieldSpec, free it with
 *  tp_contact_info_field_spec_free()
 * Since: 0.11.7
 */
TpContactInfoFieldSpec *
tp_contact_info_field_spec_copy (const TpContactInfoFieldSpec *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return _tp_contact_info_field_spec_new (self->name, self->parameters,
      self->flags, self->max);
}

/**
 * tp_contact_info_field_spec_free: (skip)
 * @self: a #TpContactInfoFieldSpec
 *
 * Free all memory used by the #TpContactInfoFieldSpec.
 *
 * Since: 0.11.7
 */
void
tp_contact_info_field_spec_free (TpContactInfoFieldSpec *self)
{
  if (self != NULL)
    {
      g_free (self->name);
      g_strfreev (self->parameters);
      g_slice_free (TpContactInfoFieldSpec, self);
    }
}

/**
 * TP_TYPE_CONTACT_INFO_FIELD_SPEC:
 *
 * The boxed type of a #TpContactInfoFieldSpec.
 *
 * Since: 0.11.7
 */

G_DEFINE_BOXED_TYPE (TpContactInfoFieldSpec, tp_contact_info_field_spec,
    tp_contact_info_field_spec_copy, tp_contact_info_field_spec_free)

/**
 * tp_contact_info_spec_list_copy: (skip)
 * @list: a #GList of #TpContactInfoFieldSpec
 *
 * <!--Returns: says it all-->
 *
 * Returns: a new #GList of newly allocated #TpContactInfoFieldSpec,
 *  free it with tp_contact_info_spec_list_free()
 * Since: 0.11.7
 */
GList *
tp_contact_info_spec_list_copy (GList *list)
{
  return _tp_g_list_copy_deep (list,
      (GCopyFunc) tp_contact_info_field_spec_copy, NULL);
}

/**
 * tp_contact_info_spec_list_free: (skip)
 * @list: a #GList of #TpContactInfoFieldSpec
 *
 * Free all memory used by the #GList and its elements.
 *
 * Since: 0.11.7
 */
void
tp_contact_info_spec_list_free (GList *list)
{
  g_list_free_full (list, (GDestroyNotify) tp_contact_info_field_spec_free);
}

/**
 * TP_TYPE_CONTACT_INFO_SPEC_LIST:
 *
 * The boxed type of a #GList of #TpContactInfoFieldSpec.
 *
 * Since: 0.11.7
 */

G_DEFINE_BOXED_TYPE (TpContactInfoSpecList, tp_contact_info_spec_list,
    tp_contact_info_spec_list_copy, tp_contact_info_spec_list_free)

/**
 * TpContactInfoField:
 * @field_name: The name of the field; this is the lowercased name of a vCard
 *  field. For example, a field representing a contact's address would be named
 *  "adr".
 * @parameters: A list of vCard type parameters applicable to this field,
 *  with their values. The type parameter names, and any values that are
 *  case-insensitive in vCard, MUST be in lower case. For example, a contact's
 *  preferred home address would have parameters 'type=home' and 'type=pref'.
 * @field_value: For unstructured vCard fields (such as 'fn', a formatted name
 *  field), a single-element array containing the field's value. For structured
 *  fields (such as 'adr', an address field), an array corresponding to the
 *  semicolon-separated elements of the field (with empty strings for empty
 *  elements).
 *
 * A structure representing an information about a contact. Similar to a vCard
 * field.
 *
 * Since: 0.11.7
 */

/**
 * tp_contact_info_field_new:
 * @field_name: The name of the field; this is the lowercased name of a vCard
 *  field. For example, a field representing a contact's address would be named
 *  "adr".
 * @parameters: A list of vCard type parameters applicable to this field,
 *  with their values. The type parameter names, and any values that are
 *  case-insensitive in vCard, MUST be in lower case. For example, a contact's
 *  preferred home address would have parameters 'type=home' and 'type=pref'.
 * @field_value: For unstructured vCard fields (such as 'fn', a formatted name
 *  field), a single-element array containing the field's value. For structured
 *  fields (such as 'adr', an address field), an array corresponding to the
 *  semicolon-separated elements of the field (with empty strings for empty
 *  elements).
 *
 * <!--Returns: says it all-->
 *
 * Returns: a newly allocated #TpContactInfoField, free it with
 * tp_contact_info_field_free()
 * Since: 0.11.7
 */
TpContactInfoField *
tp_contact_info_field_new (const gchar *field_name,
    GStrv parameters,
    GStrv field_value)
{
  TpContactInfoField *self;
  gchar *empty[] = { NULL };

  self = g_slice_new0 (TpContactInfoField);
  self->field_name = g_strdup (field_name);
  self->parameters = g_strdupv (parameters ? parameters : empty);
  self->field_value = g_strdupv (field_value ? field_value : empty);

  return self;
}

/**
 * tp_contact_info_field_copy: (skip)
 * @self: a #TpContactInfoField
 *
 * <!--Returns: says it all-->
 *
 * Returns: a newly allocated #TpContactInfoField, free it with
 *  tp_contact_info_field_free()
 * Since: 0.11.7
 */
TpContactInfoField *
tp_contact_info_field_copy (const TpContactInfoField *self)
{
  g_return_val_if_fail (self != NULL, NULL);

  return tp_contact_info_field_new (self->field_name, self->parameters,
      self->field_value);
}

/**
 * tp_contact_info_field_free: (skip)
 * @self: a #TpContactInfoField
 *
 * Free all memory used by the #TpContactInfoField.
 *
 * Since: 0.11.7
 */
void
tp_contact_info_field_free (TpContactInfoField *self)
{
  if (self != NULL)
    {
      g_free (self->field_name);
      g_strfreev (self->parameters);
      g_strfreev (self->field_value);
      g_slice_free (TpContactInfoField, self);
    }
}

/**
 * TP_TYPE_CONTACT_INFO_FIELD:
 *
 * The boxed type of a #TpContactInfoField.
 *
 * Since: 0.11.7
 */

G_DEFINE_BOXED_TYPE (TpContactInfoField, tp_contact_info_field,
    tp_contact_info_field_copy, tp_contact_info_field_free)

/**
 * tp_contact_info_list_copy: (skip)
 * @list: a #GList of #TpContactInfoField
 *
 * <!--Returns: says it all-->
 *
 * Returns: a new #GList of newly allocated #TpContactInfoField, free it with
 *  tp_contact_info_list_free()
 * Since: 0.11.7
 */
GList *
tp_contact_info_list_copy (GList *list)
{
  return _tp_g_list_copy_deep (list,
      (GCopyFunc) tp_contact_info_field_copy, NULL);
}

/**
 * tp_contact_info_list_free: (skip)
 * @list: a #GList of #TpContactInfoField
 *
 * Free all memory used by the #GList and its elements.
 *
 * Since: 0.11.7
 */
void
tp_contact_info_list_free (GList *list)
{
  g_list_free_full (list, (GDestroyNotify) tp_contact_info_field_free);
}

/**
 * TP_TYPE_CONTACT_INFO_LIST:
 *
 * The boxed type of a #GList of #TpContactInfoField.
 *
 * Since: 0.11.7
 */

G_DEFINE_BOXED_TYPE (TpContactInfoList, tp_contact_info_list,
    tp_contact_info_list_copy, tp_contact_info_list_free)

/**
 * TP_CONNECTION_FEATURE_CONTACT_INFO:
 *
 * Expands to a call to a function that returns a #GQuark representing the
 * "contact-info" feature.
 *
 * When this feature is prepared, the ContactInfoFlags and SupportedFields of
 * the Connection has been retrieved. Use tp_connection_get_contact_info_flags()
 * and tp_connection_dup_contact_info_supported_fields() to get them once
 * prepared.
 *
 * One can ask for a feature to be prepared using the
 * tp_proxy_prepare_async() function, and waiting for it to callback.
 *
 * Since: 0.11.7
 */

GQuark
tp_connection_get_feature_quark_contact_info (void)
{
  return g_quark_from_static_string ("tp-connection-feature-contact-info");
}


static void
tp_connection_get_contact_info_cb (TpProxy *proxy,
    GHashTable *properties,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result = user_data;
  GPtrArray *specs;
  gboolean valid;
  guint i;

  if (error != NULL)
    {
      DEBUG ("Failed to get contact info properties: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
      goto finally;
    }

  g_assert (self->priv->contact_info_supported_fields == NULL);

  self->priv->contact_info_flags = tp_asv_get_uint32 (properties,
      "ContactInfoFlags", &valid);

  specs = tp_asv_get_boxed (properties, "SupportedFields",
      TP_ARRAY_TYPE_FIELD_SPECS);

  if (!valid || specs == NULL)
    {
      DEBUG ("Some properties are missing on the ContactInfo interface");
      g_simple_async_result_set_error (result, TP_ERROR, TP_ERROR_CONFUSED,
          "Some properties are missing on the ContactInfo interface");
      goto finally;
    }

  DEBUG ("CONTACT INFO ready");

  for (i = 0; i < specs->len; i++)
    {
      GValueArray *va = g_ptr_array_index (specs, i);
      const gchar *name;
      GStrv parameters;
      TpContactInfoFieldFlags flags;
      guint max;

      tp_value_array_unpack (va, 4, &name, &parameters, &flags, &max);
      self->priv->contact_info_supported_fields = g_list_prepend (
          self->priv->contact_info_supported_fields,
          _tp_contact_info_field_spec_new (name, parameters, flags, max));
    }

finally:
  g_simple_async_result_complete_in_idle (result);
}

void
_tp_connection_prepare_contact_info_async (TpProxy *proxy,
    const TpProxyFeature *feature,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  TpConnection *self = (TpConnection *) proxy;
  GSimpleAsyncResult *result;

  result = g_simple_async_result_new ((GObject *) proxy, callback, user_data,
      _tp_connection_prepare_contact_info_async);

  tp_cli_dbus_properties_call_get_all (self, -1,
      TP_IFACE_CONNECTION_INTERFACE_CONTACT_INFO,
      tp_connection_get_contact_info_cb, result, g_object_unref, NULL);
}

/**
 * tp_connection_get_contact_info_flags:
 * @self: a connection
 *
 * Returns the flags describing how contact info (vCards) behaves on this
 * connection
 *
 * To wait for valid contact info flags, call tp_proxy_prepare_async()
 * with the feature %TP_CONNECTION_FEATURE_CONTACT_INFO.
 *
 * This property cannot change after @self goes to the Connected state.
 *
 * Returns: a set of #TpContactInfoFlags
 * Since: 0.11.7
 */
TpContactInfoFlags
tp_connection_get_contact_info_flags (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), 0);

  return self->priv->contact_info_flags;
}

/**
 * tp_connection_get_contact_info_supported_fields:
 * @self: a connection
 *
 * Returns a newly allocated #GList of supported contact info fields for this
 * connection. The list must be freed with g_list_free() after used.
 *
 * Note that the #TpContactInfoFieldSpec<!-- -->s in the returned #GList are not
 * dupped before returning from this function. One could copy every item in the
 * list using tp_contact_info_field_spec_copy().
 *
 * To wait for valid supported fields, call tp_proxy_prepare_async() with the
 * feature %TP_CONNECTION_FEATURE_CONTACT_INFO.
 *
 * This property cannot change after @self goes to the Connected state.
 *
 * Returns: (element-type TelepathyGLib.ContactInfoFieldSpec) (transfer container):
 *  a #GList of #TpContactInfoFieldSpec struct, or %NULL if the feature is not
 *  yet prepared or the connection doesn't have the necessary properties.
 * Since: 0.11.7
 * Deprecated: Since 0.19.9. New code should use
 *  tp_connection_dup_contact_info_supported_fields() instead.
 */
GList *
tp_connection_get_contact_info_supported_fields (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);

  return g_list_copy (self->priv->contact_info_supported_fields);
}

/**
 * tp_connection_dup_contact_info_supported_fields:
 * @self: a connection
 *
 * Returns a newly allocated #GList of supported contact info fields for this
 * connection. The list must be freed with tp_contact_info_spec_list_free().
 *
 * To wait for valid supported fields, call tp_proxy_prepare_async() with the
 * feature %TP_CONNECTION_FEATURE_CONTACT_INFO.
 *
 * This property cannot change after @self goes to the Connected state.
 *
 * Returns: (element-type TelepathyGLib.ContactInfoFieldSpec) (transfer full):
 *  a #GList of #TpContactInfoFieldSpec struct, or %NULL if the feature is not
 *  yet prepared or the connection doesn't have the necessary properties.
 * Since: 0.19.9
 */
GList *
tp_connection_dup_contact_info_supported_fields (TpConnection *self)
{
  g_return_val_if_fail (TP_IS_CONNECTION (self), NULL);

  return _tp_g_list_copy_deep (self->priv->contact_info_supported_fields,
      (GCopyFunc) tp_contact_info_field_spec_copy, NULL);
}

static void
set_info_cb (TpConnection *self,
    const GError *error,
    gpointer user_data,
    GObject *weak_object)
{
  GSimpleAsyncResult *result = user_data;

  if (error != NULL)
    {
      DEBUG ("Failed to set ContactInfo: %s", error->message);
      g_simple_async_result_set_from_error (result, error);
    }

  g_simple_async_result_complete (result);
}

/**
 * tp_connection_set_contact_info_async:
 * @self: a #TpConnection
 * @info: (element-type TelepathyGLib.ContactInfoField): a #GList of
 *  #TpContactInfoField
 * @callback: a callback to call when the request is satisfied
 * @user_data: data to pass to @callback
 *
 * Requests an asynchronous set of the contact info of @self. When
 * the operation is finished, @callback will be called. You can then call
 * tp_connection_set_contact_info_finish() to get the result of the operation.
 *
 * This method should not be expected to succeed if the result of
 * tp_connection_get_contact_info_flags() does not include
 * %TP_CONTACT_INFO_FLAG_CAN_SET.
 * Since: 0.11.7
 */
void
tp_connection_set_contact_info_async (TpConnection *self,
    GList *info,
    GAsyncReadyCallback callback,
    gpointer user_data)
{
  GSimpleAsyncResult *result;
  GPtrArray *contact_info;

  g_return_if_fail (TP_IS_CONNECTION (self));

  result = g_simple_async_result_new (G_OBJECT (self), callback,
      user_data, tp_connection_set_contact_info_finish);

  contact_info = g_ptr_array_new ();
  while (info != NULL)
    {
      TpContactInfoField *field = info->data;
      GValueArray *va;

      va = tp_value_array_build (3,
          G_TYPE_STRING, field->field_name,
          G_TYPE_STRV, field->parameters,
          G_TYPE_STRV, field->field_value,
          G_TYPE_INVALID);

      g_ptr_array_add (contact_info, va);
      info = info->next;
    }

  tp_cli_connection_interface_contact_info_call_set_contact_info (self, -1,
      contact_info, set_info_cb, result, g_object_unref, NULL);

  g_ptr_array_foreach (contact_info, (GFunc) tp_value_array_free, NULL);
  g_ptr_array_unref (contact_info);
}

/**
 * tp_connection_set_contact_info_finish:
 * @self: a #TpConnection
 * @result: a #GAsyncResult
 * @error: a #GError to be filled
 *
 * Finishes an async set of @self info.
 *
 * Returns: %TRUE if the request call was successful, otherwise %FALSE
 *
 * Since: 0.11.7
 */
gboolean
tp_connection_set_contact_info_finish (TpConnection *self,
    GAsyncResult *result,
    GError **error)
{
  _tp_implement_finish_void (self, tp_connection_set_contact_info_finish);
}

