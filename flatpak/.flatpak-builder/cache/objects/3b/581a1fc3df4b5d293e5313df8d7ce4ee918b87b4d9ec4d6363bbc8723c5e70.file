/*
 * properties-mixin.c - Source for TpPropertiesMixin
 * Copyright (C) 2006-2007 Collabora Ltd.
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
 * SECTION:properties-mixin
 * @title: TpPropertiesMixin
 * @short_description: a mixin implementation of the Telepathy.Properties
 *  interface
 * @see_also: #TpSvcPropertiesInterface
 *
 * This mixin can be added to any GObject class to implement the properties
 * interface in a general way.
 *
 * To use the properties mixin, include a #TpPropertiesMixinClass somewhere
 * in your class structure and a #TpPropertiesMixin somewhere in your
 * instance structure, and call tp_properties_mixin_class_init() from your
 * class_init function, tp_properties_mixin_init() from your init function
 * or constructor, and tp_properties_mixin_finalize() from your dispose
 * or finalize function.
 *
 * To use the properties mixin as the implementation of
 * #TpSvcPropertiesInterface, call
 * <literal>G_IMPLEMENT_INTERFACE (TP_TYPE_SVC_PROPERTIES_INTERFACE,
 * tp_properties_mixin_iface_init)</literal> in the fourth argument to
 * <literal>G_DEFINE_TYPE_WITH_CODE</literal>.
 */

#include "config.h"

#include <telepathy-glib/properties-mixin.h>

#include <dbus/dbus-glib.h>
#include <stdio.h>
#include <string.h>

#include <telepathy-glib/debug-ansi.h>
#include <telepathy-glib/errors.h>
#include <telepathy-glib/intset.h>
#include <telepathy-glib/util.h>

#define DEBUG_FLAG TP_DEBUG_PROPERTIES

#include "debug-internal.h"

struct _TpPropertiesContext {
    TpPropertiesMixinClass *mixin_cls;
    TpPropertiesMixin *mixin;

    DBusGMethodInvocation *dbus_ctx;
    TpIntset *remaining;
    GValue **values;
};

struct _TpPropertiesMixinPrivate {
    GObject *object;
    TpPropertiesContext context;
};

/*
 * tp_properties_mixin_class_get_offset_quark:
 *
 * Returns: the quark used for storing mixin offset on a GObjectClass
 */
GQuark
tp_properties_mixin_class_get_offset_quark ()
{
  static GQuark offset_quark = 0;
  if (!offset_quark)
    offset_quark = g_quark_from_static_string (
        "TpPropertiesMixinClassOffsetQuark");
  return offset_quark;
}

/*
 * tp_properties_mixin_get_offset_quark:
 *
 * Returns: the quark used for storing mixin offset on a GObject
 */
GQuark
tp_properties_mixin_get_offset_quark ()
{
  static GQuark offset_quark = 0;
  if (!offset_quark)
    offset_quark = g_quark_from_static_string (
        "TpPropertiesMixinOffsetQuark");
  return offset_quark;
}


/**
 * tp_properties_mixin_class_init:
 * @obj_cls: The class of an object that has this mixin
 * @offset: The offset of the TpPropertiesMixinClass structure in the class
 *          structure
 * @signatures: An array of property signatures
 * @num_properties: The number of entries in @signatures
 * @set_func: Callback used to set the properties
 *
 * Initialize the mixin. Should be called from the implementation's
 * class_init function like so:
 *
 * <informalexample><programlisting>
 * tp_properties_mixin_class_init ((GObjectClass *) klass,
 *                                 G_STRUCT_OFFSET (SomeObjectClass,
 *                                  properties_mixin));
 * </programlisting></informalexample>
 */

void
tp_properties_mixin_class_init (GObjectClass *obj_cls,
                                glong offset,
                                const TpPropertySignature *signatures,
                                guint num_properties,
                                TpPropertiesSetFunc set_func)
{
  TpPropertiesMixinClass *mixin_cls;

  g_assert (G_IS_OBJECT_CLASS (obj_cls));

  g_type_set_qdata (G_OBJECT_CLASS_TYPE (obj_cls),
                    TP_PROPERTIES_MIXIN_CLASS_OFFSET_QUARK,
                    GINT_TO_POINTER (offset));

  mixin_cls = TP_PROPERTIES_MIXIN_CLASS (obj_cls);

  mixin_cls->signatures = signatures;
  mixin_cls->num_props = num_properties;

  mixin_cls->set_properties = set_func;
}


/**
 * tp_properties_mixin_init:
 * @obj: An object that has this mixin
 * @offset: The offset of the TpPropertiesMixin structure in the object
 *          structure
 *
 * Initialize the mixin. Should be called from the implementation's
 * instance init function like so:
 *
 * <informalexample><programlisting>
 * tp_properties_mixin_init ((GObject *) self,
 *                           G_STRUCT_OFFSET (SomeObject, properties_mixin),
 *                           self->contact_repo);
 * </programlisting></informalexample>
 */

void tp_properties_mixin_init (GObject *obj, glong offset)
{
  TpPropertiesMixinClass *mixin_cls;
  TpPropertiesMixin *mixin;
  TpPropertiesContext *ctx;

  g_assert (G_IS_OBJECT (obj));

  g_assert (TP_IS_SVC_PROPERTIES_INTERFACE (obj));

  g_type_set_qdata (G_OBJECT_TYPE (obj),
                    TP_PROPERTIES_MIXIN_OFFSET_QUARK,
                    GINT_TO_POINTER (offset));

  mixin = TP_PROPERTIES_MIXIN (obj);
  mixin_cls = TP_PROPERTIES_MIXIN_CLASS (G_OBJECT_GET_CLASS (obj));

  mixin->properties = g_new0 (TpProperty, mixin_cls->num_props);

  mixin->priv = g_slice_new0 (TpPropertiesMixinPrivate);
  mixin->priv->object = obj;

  ctx = &mixin->priv->context;
  ctx->mixin_cls = mixin_cls;
  ctx->mixin = mixin;
  ctx->values = g_new0 (GValue *, mixin_cls->num_props);
}

/**
 * tp_properties_mixin_finalize:
 * @obj: An object that has this mixin
 *
 * Free memory used by the TpPropertiesMixin.
 */

void tp_properties_mixin_finalize (GObject *obj)
{
  TpPropertiesMixin *mixin = TP_PROPERTIES_MIXIN (obj);
  TpPropertiesMixinClass *mixin_cls = TP_PROPERTIES_MIXIN_CLASS (
                                            G_OBJECT_GET_CLASS (obj));
  TpPropertiesContext *ctx = &mixin->priv->context;
  guint i;

  for (i = 0; i < mixin_cls->num_props; i++)
    {
      TpProperty *prop = &mixin->properties[i];

      if (prop->value)
        {
          g_value_unset (prop->value);
          g_slice_free (GValue, prop->value);
        }

      if (ctx->values[i])
        {
          g_value_unset (ctx->values[i]);
        }
    }

  g_free (ctx->values);

  g_slice_free (TpPropertiesMixinPrivate, mixin->priv);

  g_free (mixin->properties);
}


/**
 * tp_properties_mixin_list_properties:
 * @obj: An object with this mixin
 * @ret: Output parameter which will be set to a GPtrArray of D-Bus structures
 *       if %TRUE is returned
 * @error: Set to the error if %FALSE is returned
 *
 * List all available properties and their flags, as in the ListProperties
 * D-Bus method.
 *
 * Returns: %TRUE on success
 */
gboolean
tp_properties_mixin_list_properties (GObject *obj,
                                     GPtrArray **ret,
                                     GError **error)
{
  TpPropertiesMixin *mixin = TP_PROPERTIES_MIXIN (obj);
  TpPropertiesMixinClass *mixin_cls = TP_PROPERTIES_MIXIN_CLASS (
                                            G_OBJECT_GET_CLASS (obj));
  GType spec_type = TP_STRUCT_TYPE_PROPERTY_SPEC;
  guint i;

  *ret = g_ptr_array_sized_new (mixin_cls->num_props);

  for (i = 0; i < mixin_cls->num_props; i++)
    {
      const TpPropertySignature *sig = &mixin_cls->signatures[i];
      TpProperty *prop = &mixin->properties[i];
      const gchar *dbus_sig;
      GValue val = { 0, };

      switch (sig->type) {
        case G_TYPE_BOOLEAN:
          dbus_sig = "b";
          break;
        case G_TYPE_INT:
          dbus_sig = "i";
          break;
        case G_TYPE_UINT:
          dbus_sig = "u";
          break;
        case G_TYPE_STRING:
          dbus_sig = "s";
          break;
        default:
          g_assert_not_reached ();
          continue;
      };

      g_value_init (&val, spec_type);
      g_value_take_boxed (&val, dbus_g_type_specialized_construct (spec_type));

      dbus_g_type_struct_set (&val,
          0, i,
          1, sig->name,
          2, dbus_sig,
          3, prop->flags,
          G_MAXUINT);

      g_ptr_array_add (*ret, g_value_get_boxed (&val));
    }

  return TRUE;
}


/**
 * tp_properties_mixin_get_properties:
 * @obj: An object with this mixin
 * @properties: an array of integer property IDs
 * @ret: set to an array of D-Bus structures if %TRUE is returned
 * @error: Set to the error if %FALSE is returned
 *
 * Retrieve the values of the given properties, as in the GetProperties
 * D-Bus method.
 *
 * Returns: %TRUE on success
 */
gboolean
tp_properties_mixin_get_properties (GObject *obj,
                                    const GArray *properties,
                                    GPtrArray **ret,
                                    GError **error)
{
  TpPropertiesMixin *mixin = TP_PROPERTIES_MIXIN (obj);
  TpPropertiesMixinClass *mixin_cls = TP_PROPERTIES_MIXIN_CLASS (
                                            G_OBJECT_GET_CLASS (obj));
  GType value_type = TP_STRUCT_TYPE_PROPERTY_VALUE;
  guint i;

  /* Check input property identifiers */
  for (i = 0; i < properties->len; i++)
    {
      guint prop_id = g_array_index (properties, guint, i);

      /* Valid? */
      if (prop_id >= mixin_cls->num_props)
        {
          g_set_error (error, TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
              "invalid property identifier %d", prop_id);

          return FALSE;
        }

      /* Permitted? */
      if (!tp_properties_mixin_is_readable (obj, prop_id))
        {
          g_set_error (error, TP_ERROR, TP_ERROR_PERMISSION_DENIED,
              "permission denied for property identifier %d", prop_id);

          return FALSE;
        }
    }

  /* If we got this far, return the actual values */
  *ret = g_ptr_array_sized_new (properties->len);

  for (i = 0; i < properties->len; i++)
    {
      guint prop_id = g_array_index (properties, guint, i);
      GValue val_struct = { 0, };

      /* id/value struct */
      g_value_init (&val_struct, value_type);
      g_value_take_boxed (&val_struct,
          dbus_g_type_specialized_construct (value_type));

      dbus_g_type_struct_set (&val_struct,
          0, prop_id,
          1, mixin->properties[prop_id].value,
          G_MAXUINT);

      g_ptr_array_add (*ret, g_value_get_boxed (&val_struct));
    }

  return TRUE;
}


/**
 * tp_properties_mixin_set_properties:
 * @obj: An object with this mixin
 * @properties: An array of D-Bus structures containing property ID and value
 * @context: A D-Bus method invocation context for the SetProperties method
 *
 * Start to change properties in response to user request via D-Bus.
 */
void
tp_properties_mixin_set_properties (GObject *obj,
                                    const GPtrArray *properties,
                                    DBusGMethodInvocation *context)
{
  TpPropertiesMixin *mixin = TP_PROPERTIES_MIXIN (obj);
  TpPropertiesMixinClass *mixin_cls = TP_PROPERTIES_MIXIN_CLASS (
                                            G_OBJECT_GET_CLASS (obj));
  TpPropertiesContext *ctx = &mixin->priv->context;
  GError *error = NULL;
  GType value_type = TP_STRUCT_TYPE_PROPERTY_VALUE;
  guint i;

  /* Is another SetProperties request already in progress? */
  if (ctx->dbus_ctx)
    {
      error = g_error_new (TP_ERROR, TP_ERROR_NOT_AVAILABLE,
                           "A SetProperties request is already in progress");
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }

  ctx->dbus_ctx = context;
  ctx->remaining = tp_intset_new ();
  error = NULL;

  if (properties->len == 0)
    {
      DEBUG ("immediately returning from SetProperties with 0 properties");
      tp_properties_context_return (ctx, NULL);
      return;
    }

  /* Check input property identifiers */
  for (i = 0; i < properties->len; i++)
    {
      GValue val_struct = { 0, };
      guint prop_id;
      GValue *prop_val;

      g_value_init (&val_struct, value_type);
      g_value_set_static_boxed (&val_struct,
          g_ptr_array_index (properties, i));

      dbus_g_type_struct_get (&val_struct,
          0, &prop_id,
          1, &prop_val,
          G_MAXUINT);

      /* Valid? */
      if (prop_id >= mixin_cls->num_props)
        {
          g_boxed_free (G_TYPE_VALUE, prop_val);
          error = g_error_new (TP_ERROR, TP_ERROR_INVALID_ARGUMENT,
                               "invalid property identifier %d", prop_id);
          goto ERROR;
        }

      /* Permitted? */
      if (!tp_properties_mixin_is_writable (obj, prop_id))
        {
          g_boxed_free (G_TYPE_VALUE, prop_val);
          error = g_error_new (TP_ERROR, TP_ERROR_PERMISSION_DENIED,
                               "permission denied for property identifier %d",
                               prop_id);
          goto ERROR;
        }

      /* Compatible type? */
      if (!g_value_type_compatible (G_VALUE_TYPE (prop_val),
                                    mixin_cls->signatures[prop_id].type))
        {
          g_boxed_free (G_TYPE_VALUE, prop_val);
          error = g_error_new (TP_ERROR, TP_ERROR_NOT_AVAILABLE,
                               "incompatible value type for property "
                               "identifier %d", prop_id);
          goto ERROR;
        }

      /* Store the value in the context */
      tp_intset_add (ctx->remaining, prop_id);
      ctx->values[prop_id] = prop_val;
    }

  if (mixin_cls->set_properties)
    {
      if (mixin_cls->set_properties (obj, ctx, &error))
        return;
    }
  else
    {
      tp_properties_context_return (ctx, NULL);
      return;
    }

ERROR:
  tp_properties_context_return (ctx, error);
}

/**
 * tp_properties_mixin_has_property:
 * @obj: an object with a properties mixin
 * @name: the string name of the property
 * @property: either %NULL, or a pointer to a location to receive the property
 *            index
 *
 * <!--Returns: says it all; this comment is to keep gtkdoc happy-->
 *
 * Returns: %TRUE, setting @property, if @obj has a property of that name
 */
gboolean
tp_properties_mixin_has_property (GObject *obj, const gchar *name,
                                      guint *property)
{
  TpPropertiesMixinClass *mixin_cls = TP_PROPERTIES_MIXIN_CLASS (
                                            G_OBJECT_GET_CLASS (obj));
  guint i;

  for (i = 0; i < mixin_cls->num_props; i++)
    {
      if (!tp_strdiff (mixin_cls->signatures[i].name, name))
        {
          if (property)
            *property = i;

          return TRUE;
        }
    }

  return FALSE;
}


/**
 * tp_properties_context_has:
 * @ctx: the properties context representing a SetProperties call
 * @property: the property ID
 *
 * <!--Returns: says it all; this comment is to keep gtkdoc happy-->
 *
 * Returns: %TRUE if @ctx indicates that @property still needs to be set on
 * the server.
 */
gboolean
tp_properties_context_has (TpPropertiesContext *ctx, guint property)
{
  g_assert (property < ctx->mixin_cls->num_props);

  return (tp_intset_is_member (ctx->remaining, property));
}


/**
 * tp_properties_context_has_other_than:
 * @ctx: the properties context representing a SetProperties call
 * @property: the property ID
 *
 * <!--Returns: says it all; this comment is to keep gtkdoc happy-->
 *
 * Returns: %TRUE if @ctx has properties other than @property that still
 * need to be set on the server
 */
gboolean
tp_properties_context_has_other_than (TpPropertiesContext *ctx, guint property)
{
  gboolean has = tp_intset_is_member (ctx->remaining, property);

  g_assert (property < ctx->mixin_cls->num_props);

  return (tp_intset_size (ctx->remaining) > (has ? 1 : 0));
}


/**
 * tp_properties_context_get:
 * @ctx: the properties context representing a SetProperties call
 * @property: a property ID
 *
 * <!--Returns: says it all; this comment is to keep gtkdoc happy-->
 *
 * Returns: the value to be set on the server for the property @property
 * in @ctx (whether it has been set already or not)
 */
const GValue *
tp_properties_context_get (TpPropertiesContext *ctx, guint property)
{
  g_assert (property < ctx->mixin_cls->num_props);

  return ctx->values[property];
}


/**
 * tp_properties_context_get_value_count:
 * @ctx: the properties context representing a SetProperties call
 *
 * <!--Returns: says it all; this comment is to keep gtkdoc happy-->
 *
 * Returns: the number of properties in @ctx which still need to be set on
 *          the server, or have already been set
 */
guint
tp_properties_context_get_value_count (TpPropertiesContext *ctx)
{
  guint i, n;

  n = 0;
  for (i = 0; i < ctx->mixin_cls->num_props; i++)
    {
      if (ctx->values[i])
        n++;
    }

  return n;
}


/**
 * tp_properties_context_remove:
 * @ctx: the properties context representing a SetProperties call
 * @property: a property ID
 *
 * Mark the given property as having been set successfully.
 */
void
tp_properties_context_remove (TpPropertiesContext *ctx, guint property)
{
  g_assert (property < ctx->mixin_cls->num_props);

  tp_intset_remove (ctx->remaining, property);
}


/**
 * tp_properties_context_return:
 * @ctx: the properties context representing a SetProperties call
 * @error: If %NULL, return successfully; otherwise return this error
 *
 * Commit the property changes and return from the pending D-Bus call.
 */
void
tp_properties_context_return (TpPropertiesContext *ctx, GError *error)
{
  GObject *obj = ctx->mixin->priv->object;
  TpIntset *changed_props_val, *changed_props_flags;
  guint i;

  DEBUG ("%s", (error) ? "failure" : "success");

  changed_props_val = tp_intset_sized_new (ctx->mixin_cls->num_props);
  changed_props_flags = tp_intset_sized_new (ctx->mixin_cls->num_props);

  for (i = 0; i < ctx->mixin_cls->num_props; i++)
    {
      if (ctx->values[i])
        {
          if (!error)
            {
              tp_properties_mixin_change_value (obj, i, ctx->values[i],
                  changed_props_val);

              tp_properties_mixin_change_flags (obj, i,
                  TP_PROPERTY_FLAG_READ, 0, changed_props_flags);
            }

          g_value_unset (ctx->values[i]);
          ctx->values[i] = NULL;
        }
    }

  if (!error)
    {
      tp_properties_mixin_emit_changed (obj, changed_props_val);
      tp_properties_mixin_emit_flags (obj, changed_props_flags);
      tp_intset_destroy (changed_props_val);
      tp_intset_destroy (changed_props_flags);

      dbus_g_method_return (ctx->dbus_ctx);
    }
  else
    {
      dbus_g_method_return_error (ctx->dbus_ctx, error);
      g_error_free (error);
    }

  ctx->dbus_ctx = NULL;
  tp_intset_destroy (ctx->remaining);
  ctx->remaining = NULL;
  /* The context itself is not freed - it's a static part of the mixin */
}


/**
 * tp_properties_context_return_if_done:
 * @ctx: the properties context representing a SetProperties call
 *
 * Return from the pending D-Bus call if there are no more properties to be
 * dealt with.
 *
 * Returns: %TRUE if we returned from the D-Bus call.
 */
gboolean
tp_properties_context_return_if_done (TpPropertiesContext *ctx)
{
  if (tp_intset_size (ctx->remaining) == 0)
    {
      tp_properties_context_return (ctx, NULL);
      return TRUE;
    }

  return FALSE;
}

#define RPTS_APPEND_FLAG_IF_SET(flag) \
  if (flags & flag) \
    { \
      if (i++ > 0) \
        g_string_append (str, "|"); \
      g_string_append (str, #flag + 17); \
    }

static gchar *
property_flags_to_string (TpPropertyFlags flags)
{
  gint i = 0;
  GString *str;

  str = g_string_new ("[");

  RPTS_APPEND_FLAG_IF_SET (TP_PROPERTY_FLAG_READ);
  RPTS_APPEND_FLAG_IF_SET (TP_PROPERTY_FLAG_WRITE);

  g_string_append (str, "]");

  return g_string_free (str, FALSE);
}

static gboolean
values_are_equal (const GValue *v1, const GValue *v2)
{
  GType type = G_VALUE_TYPE (v1);

  switch (type) {
    case G_TYPE_BOOLEAN:
      return (g_value_get_boolean (v1) == g_value_get_boolean (v2));

    case G_TYPE_STRING:
      return !tp_strdiff (g_value_get_string (v1), g_value_get_string (v2));

    case G_TYPE_UINT:
      return (g_value_get_uint (v1) == g_value_get_uint (v2));

    case G_TYPE_INT:
      return (g_value_get_int (v1) == g_value_get_int (v2));
  }

  return FALSE;
}


/**
 * tp_properties_mixin_change_value:
 * @obj: An object with the properties mixin
 * @prop_id: A property ID on which to act
 * @new_value: Property value
 * @props: either %NULL, or a pointer to a TpIntset
 *
 * Change the value of the given property ID in response to a server state
 * change.
 *
 * If the old and new values match, nothing happens; no signal is emitted and
 * @props is ignored. Otherwise, the following applies:
 *
 * If @props is %NULL the PropertiesChanged signal is emitted for this one
 * property.
 *
 * Otherwise, the property ID is added to the set; the caller is responsible
 * for passing the set to tp_properties_mixin_emit_changed() once a batch of
 * properties have been changed.
 */
void
tp_properties_mixin_change_value (GObject *obj,
                                  guint prop_id,
                                  const GValue *new_value,
                                  TpIntset *props)
{
  TpPropertiesMixin *mixin = TP_PROPERTIES_MIXIN (obj);
  TpPropertiesMixinClass *mixin_cls = TP_PROPERTIES_MIXIN_CLASS (
      G_OBJECT_GET_CLASS (obj));
  TpProperty *prop;

  g_assert (prop_id < mixin_cls->num_props);

  prop = &mixin->properties[prop_id];

  if (prop->value)
    {
      if (values_are_equal (prop->value, new_value))
        return;
    }
  else
    {
      prop->value = tp_g_value_slice_new (mixin_cls->signatures[prop_id].type);
    }

  g_value_copy (new_value, prop->value);

  if (props)
    {
      tp_intset_add (props, prop_id);
    }
  else
    {
      TpIntset *changed_props = tp_intset_sized_new (prop_id + 1);

      tp_intset_add (changed_props, prop_id);
      tp_properties_mixin_emit_changed (obj, changed_props);
      tp_intset_destroy (changed_props);
    }
}


/**
 * tp_properties_mixin_change_flags:
 * @obj: An object with the properties mixin
 * @prop_id: A property ID on which to act
 * @add: Property flags to be added via bitwise OR
 * @del: Property flags to be removed via bitwise AND
 * @props: either %NULL, or a pointer to a TpIntset
 *
 * Change the flags for the given property ID in response to a server state
 * change.
 *
 * Flags removed by @del override flags added by @add. This should not be
 * relied upon.
 *
 * If @props is %NULL the PropertyFlagsChanged signal is emitted for this
 * single property.
 *
 * Otherwise, the property ID is added to the set; the caller is responsible
 * for passing the set to tp_properties_mixin_emit_flags() once a batch of
 * properties have been changed.
 */
void
tp_properties_mixin_change_flags (GObject *obj,
                                  guint prop_id,
                                  TpPropertyFlags add,
                                  TpPropertyFlags del,
                                  TpIntset *props)
{
  TpPropertiesMixin *mixin = TP_PROPERTIES_MIXIN (obj);
  TpPropertiesMixinClass *mixin_cls = TP_PROPERTIES_MIXIN_CLASS (
                                            G_OBJECT_GET_CLASS (obj));
  TpProperty *prop;
  guint prev_flags;

  g_assert (prop_id < mixin_cls->num_props);

  prop = &mixin->properties[prop_id];

  prev_flags = prop->flags;

  prop->flags |= add;
  prop->flags &= ~del;

  if (prop->flags == prev_flags)
    return;

  if (props)
    {
      tp_intset_add (props, prop_id);
    }
  else
    {
      TpIntset *changed_props = tp_intset_sized_new (prop_id + 1);

      tp_intset_add (changed_props, prop_id);
      tp_properties_mixin_emit_flags (obj, changed_props);
      tp_intset_destroy (changed_props);
    }
}

/**
 * tp_properties_mixin_emit_changed:
 * @obj: an object with the properties mixin
 * @props: a set of property IDs
 *
 * Emit the PropertiesChanged signal to indicate that the values of the
 * given property IDs have changed; the actual values are automatically
 * added using their stored values.
 */
void
tp_properties_mixin_emit_changed (GObject *obj, const TpIntset *props)
{
  TpPropertiesMixin *mixin = TP_PROPERTIES_MIXIN (obj);
  TpPropertiesMixinClass *mixin_cls = TP_PROPERTIES_MIXIN_CLASS (
      G_OBJECT_GET_CLASS (obj));
  GPtrArray *prop_arr;
  GValue prop_list = { 0, };
  TpIntsetFastIter iter;
  guint len = tp_intset_size (props);
  guint prop_id;

  if (len == 0)
    {
      return;
    }

  prop_arr = g_ptr_array_sized_new (len);

  DEBUG ("emitting properties changed for propert%s:\n",
      (len > 1) ? "ies" : "y");

  tp_intset_fast_iter_init (&iter, props);

  while (tp_intset_fast_iter_next (&iter, &prop_id))
    {
      GValue prop_val = { 0, };

      g_value_init (&prop_val, TP_STRUCT_TYPE_PROPERTY_VALUE);
      g_value_take_boxed (&prop_val,
          dbus_g_type_specialized_construct (TP_STRUCT_TYPE_PROPERTY_VALUE));

      dbus_g_type_struct_set (&prop_val,
          0, prop_id,
          1, mixin->properties[prop_id].value,
          G_MAXUINT);

      g_ptr_array_add (prop_arr, g_value_get_boxed (&prop_val));

      DEBUG ("  %s\n", mixin_cls->signatures[prop_id].name);
    }

  tp_svc_properties_interface_emit_properties_changed (
      (TpSvcPropertiesInterface *) obj, prop_arr);

  g_value_init (&prop_list, TP_ARRAY_TYPE_PROPERTY_VALUE_LIST);
  g_value_take_boxed (&prop_list, prop_arr);
  g_value_unset (&prop_list);
}


/**
 * tp_properties_mixin_emit_flags:
 * @obj: an object with the properties mixin
 * @props: a set of property IDs
 *
 * Emit the PropertyFlagsChanged signal to indicate that the flags of the
 * given property IDs have changed; the actual flags are automatically
 * added using their stored values.
 */
void
tp_properties_mixin_emit_flags (GObject *obj, const TpIntset *props)
{
  TpPropertiesMixin *mixin = TP_PROPERTIES_MIXIN (obj);
  TpPropertiesMixinClass *mixin_cls = TP_PROPERTIES_MIXIN_CLASS (
      G_OBJECT_GET_CLASS (obj));
  GPtrArray *prop_arr;
  GValue prop_list = { 0, };
  TpIntsetFastIter iter;
  guint len = tp_intset_size (props);
  guint prop_id;

  if (len == 0)
    {
      return;
    }

  prop_arr = g_ptr_array_sized_new (len);

  DEBUG ("emitting properties flags changed for propert%s:\n",
      (len > 1) ? "ies" : "y");

  tp_intset_fast_iter_init (&iter, props);

  while (tp_intset_fast_iter_next (&iter, &prop_id))
    {
      GValue prop_val = { 0, };
      guint prop_flags;

      prop_flags = mixin->properties[prop_id].flags;

      g_value_init (&prop_val, TP_STRUCT_TYPE_PROPERTY_FLAGS_CHANGE);
      g_value_take_boxed (&prop_val,
          dbus_g_type_specialized_construct
              (TP_STRUCT_TYPE_PROPERTY_FLAGS_CHANGE));

      dbus_g_type_struct_set (&prop_val,
          0, prop_id,
          1, prop_flags,
          G_MAXUINT);

      g_ptr_array_add (prop_arr, g_value_get_boxed (&prop_val));

      if (DEBUGGING)
        {
          gchar *str_flags = property_flags_to_string (prop_flags);

          DEBUG ("  %s's flags now: %s\n",
                  mixin_cls->signatures[prop_id].name, str_flags);

          g_free (str_flags);
        }
    }

  tp_svc_properties_interface_emit_property_flags_changed (
      (TpSvcPropertiesInterface *) obj, prop_arr);

  g_value_init (&prop_list, TP_ARRAY_TYPE_PROPERTY_FLAGS_CHANGE_LIST);
  g_value_take_boxed (&prop_list, prop_arr);
  g_value_unset (&prop_list);
}


/**
 * tp_properties_mixin_is_readable:
 * @obj: an object with this mixin
 * @prop_id: an integer property ID
 *
 * <!--Returns: says it all; this comment is to keep gtkdoc happy-->
 *
 * Returns: %TRUE if the given property has the READ flag
 */
gboolean
tp_properties_mixin_is_readable (GObject *obj, guint prop_id)
{
  TpPropertiesMixin *mixin = TP_PROPERTIES_MIXIN (obj);
  TpPropertiesMixinClass *mixin_cls = TP_PROPERTIES_MIXIN_CLASS (
                                            G_OBJECT_GET_CLASS (obj));

  if (prop_id >= mixin_cls->num_props)
    return FALSE;

  return ((mixin->properties[prop_id].flags & TP_PROPERTY_FLAG_READ) != 0);
}


/**
 * tp_properties_mixin_is_writable:
 * @obj: an object with this mixin
 * @prop_id: an integer property ID
 *
 * <!--Returns: says it all; this comment is to keep gtkdoc happy-->
 *
 * Returns: %TRUE if the given property has the WRITE flag
 */
gboolean
tp_properties_mixin_is_writable (GObject *obj, guint prop_id)
{
  TpPropertiesMixin *mixin = TP_PROPERTIES_MIXIN (obj);
  TpPropertiesMixinClass *mixin_cls = TP_PROPERTIES_MIXIN_CLASS (
                                            G_OBJECT_GET_CLASS (obj));

  if (prop_id >= mixin_cls->num_props)
    return FALSE;

  return ((mixin->properties[prop_id].flags & TP_PROPERTY_FLAG_WRITE) != 0);
}


/*
 * get_properties
 *
 * Implements D-Bus method GetProperties
 * on interface org.freedesktop.Telepathy.Properties
 *
 * @error: Used to return a pointer to a GError detailing any error
 *         that occurred, D-Bus will throw the error only if this
 *         function returns FALSE.
 *
 * Returns: TRUE if successful, FALSE if an error was thrown.
 */
static void
get_properties (TpSvcPropertiesInterface *iface,
                const GArray *properties,
                DBusGMethodInvocation *context)
{
  GPtrArray *ret;
  GError *error = NULL;
  gboolean ok = tp_properties_mixin_get_properties (G_OBJECT (iface),
      properties, &ret, &error);
  if (!ok)
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
      return;
    }
  tp_svc_properties_interface_return_from_get_properties (
      context, ret);
  g_ptr_array_unref (ret);
}


/*
 * list_properties
 *
 * Implements D-Bus method ListProperties
 * on interface org.freedesktop.Telepathy.Properties
 *
 * @error: Used to return a pointer to a GError detailing any error
 *         that occurred, D-Bus will throw the error only if this
 *         function returns false.
 *
 * Returns: TRUE if successful, FALSE if an error was thrown.
 */
static void
list_properties (TpSvcPropertiesInterface *iface,
                 DBusGMethodInvocation *context)
{
  GPtrArray *ret;
  GError *error = NULL;
  gboolean ok = tp_properties_mixin_list_properties (G_OBJECT (iface), &ret,
      &error);
  guint i;

  if (!ok)
    {
      dbus_g_method_return_error (context, error);
      g_error_free (error);
    }
  tp_svc_properties_interface_return_from_list_properties (
      context, ret);

  for (i = 0; i < ret->len; i++)
    g_boxed_free (TP_STRUCT_TYPE_PROPERTY_SPEC, ret->pdata[i]);

  g_ptr_array_unref (ret);
}


/*
 * set_properties
 *
 * Implements D-Bus method SetProperties
 * on interface org.freedesktop.Telepathy.Properties
 *
 * @context: The D-Bus invocation context to use to return values
 *           or throw an error.
 */
static void
set_properties (TpSvcPropertiesInterface *iface,
                const GPtrArray *properties,
                DBusGMethodInvocation *context)
{
  tp_properties_mixin_set_properties (G_OBJECT (iface), properties, context);
}


/**
 * tp_properties_mixin_iface_init:
 * @g_iface: A pointer to the #TpSvcPropertiesInterfaceClass in an object class
 * @iface_data: Ignored
 *
 * Fill in this mixin's method implementations in the given interface vtable.
 * This function should usually be called via G_IMPLEMENT_INTERFACE
 * inside the G_DEFINE_TYPE_WITH_CODE macro.
 */
void
tp_properties_mixin_iface_init (gpointer g_iface, gpointer iface_data)
{
  TpSvcPropertiesInterfaceClass *klass = g_iface;

#define IMPLEMENT(x) tp_svc_properties_interface_implement_##x (klass, x)
  IMPLEMENT(get_properties);
  IMPLEMENT(list_properties);
  IMPLEMENT(set_properties);
#undef IMPLEMENT
}
