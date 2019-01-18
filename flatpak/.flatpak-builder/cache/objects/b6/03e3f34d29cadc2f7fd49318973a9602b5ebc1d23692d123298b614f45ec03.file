/*
 * Copyright (C) 2009 Canonical, Ltd.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License
 * version 3.0 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License version 3.0 for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library. If not, see
 * <http://www.gnu.org/licenses/>.
 *
 * Authored by:
 *               Mikkel Kamstrup Erlandsen <mikkel.kamstrup@canonical.com>
 */

/**
 * SECTION:dee-serializable
 * @short_description: Interface for classes that can serialize to and from #GVariant<!-- -->s
 * @include: dee.h
 *
 * Interface for classes that can serialize to and from #GVariant<!-- -->s.
 *
 * There are two serialization concepts supported by this API:
 * <emphasis>serialization</emphasis> and <emphasis>externalization</emphasis>.
 * A serialized instance is created with dee_serializable_serialize() and can
 * be read back with dee_serializable_parse() provided you know the correct
 * #GType for the serialized data. The #GVariant representation of your
 * serialized data is guaranteed to be exactly as you implement yourself in the
 * @serialize vfunc of the #DeeSerializableIface.
 *
 * With externalized instances you don't have to know the correct GType to
 * recreate the instance. The #GType is encoded in the data itself. When you're
 * using dee_serializable_externalize() your data will be wrapped in a container
 * format with the required object metadata to read it back. For this reason
 * dee_serializable_parse_external() doesn't require you to pass in the #GType
 * you want to deserialize.
 *
 * <refsect2 id="dee-1.0-DeeSerializable.on_subclasses">
 * <title>On Subclasses of DeeSerializable Types</title>
 * <para>
 * As a rule of thumb you need to re-implement the #DeeSerializable interface
 * and install parse functions with dee_serializable_register_parser() every
 * time you create a new class derived from a #DeeSerializable superclass.
 * </para>
 * <para>
 * In case a subclass does not provide it's own serialization interface
 * Dee will recurse upwards in the type hierarchy and use the serialization and
 * parser implementations of the first superclass with the required behaviour.
 * This means that the parsed instance will <emphasis>not</emphasis> be an
 * instance of the subclass but only of the serializable superclass.
 * Caveat emptor.
 * </para>
 * </refsect2>
 */
#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "dee-serializable.h"
#include "dee-serializable-model.h"
#include "dee-sequence-model.h"
#include "dee-shared-model.h"
#include "trace-log.h"

#define DEE_SERIALIZABLE_FORMAT_VERSION 1

typedef struct {
  GType                     type;
  GVariantType             *vtype;
  DeeSerializableParseFunc  parse;
} Parser;

GHashTable *parsers_by_gtype = NULL;

typedef DeeSerializableIface DeeSerializableInterface;
G_DEFINE_INTERFACE (DeeSerializable, dee_serializable, G_TYPE_OBJECT)

static void
dee_serializable_default_init (DeeSerializableInterface *klass)
{
  
}

static void
init_parsers ()
{
  gpointer *cls;

  parsers_by_gtype = g_hash_table_new (g_str_hash, g_str_equal);

  /* Call type initializers for built in DeeSerializables,
   * we need to ref the classes as the parsers are registered in the
   * class_init() functions */
  cls = g_type_class_ref (dee_serializable_model_get_type ());
  g_type_class_unref (cls);
  
  cls = g_type_class_ref (dee_sequence_model_get_type ());
  g_type_class_unref (cls);

  cls = g_type_class_ref (dee_shared_model_get_type ());
  g_type_class_unref (cls);
}

/**
 * dee_serializable_register_parser:
 * @type: The #GType of the object class to register a parser for
 * @vtype: Variants to be converted must have this signature
 * @parse_func: A function to convert #GVariant data into an instance of the
 *              given @type.
 *
 * Register a parser that can convert #GVariant data into an instance of
 * a given #GType. Note that you can register more than one parser for the
 * same #GType provided that you give them different variant type signatures.
 *
 * If there is already a parser registered for the given @type and @vtype
 * it will be silently replaced.
 *
 * The recommended behaviour is that #GObject classes register their parsers in
 * their respective class init functions.
 */
void
dee_serializable_register_parser (GType                     type,
                                  const GVariantType       *vtype,
                                  DeeSerializableParseFunc  parse_func)
{
  GSList      *parsers, *iter;
  Parser      *parser;
  const gchar *gtype_name;

  g_return_if_fail (G_TYPE_IS_OBJECT (type));
  g_return_if_fail (vtype != NULL);
  g_return_if_fail (parse_func != NULL);
  
  if (G_UNLIKELY (parsers_by_gtype == NULL))
    {
      init_parsers ();
    }

  gtype_name = g_type_name (type);
  parsers = g_hash_table_lookup (parsers_by_gtype, gtype_name);

  trace ("Registering DeeSerializable parser for type %s with signature %s",
         gtype_name, g_variant_type_peek_string (vtype));

  /* Update existing parser if we have one */
  for (iter = parsers; iter != NULL; iter = iter->next)
    {
      parser = (Parser *) iter->data;
      if (g_variant_type_equal (parser->vtype, vtype))
        {
          /* Parser for this type-vtype combo already registered.
           * Override the current parser as documented and return */
          parser->parse = parse_func;
          return;
        }
    }

  /* Invariant: Beyond this point we don't have the parser registered */
  parser = g_new0 (Parser, 1);
  parser->type = type;
  parser->vtype = g_variant_type_copy (vtype);
  parser->parse = parse_func;

  parsers = g_slist_prepend (parsers, parser);
  g_hash_table_insert (parsers_by_gtype, g_strdup (gtype_name), parsers);

  return;
}

static GObject*
_parse_type (GVariant *data,
             GType     type,
             gboolean *found_parser)
{
  GObject             *object = NULL;
  GSList              *parsers, *iter;
  Parser              *parser;
  const GVariantType  *vtype;
  const gchar         *gtype_name = NULL;

  g_return_val_if_fail (data != NULL, NULL);

  vtype = g_variant_get_type (data);
  gtype_name = g_type_name (type);

  if (found_parser) *found_parser = FALSE;

  trace ("Looking up parser for DeeSerializable of type %s with signature %s",
         gtype_name, g_variant_type_peek_string (vtype));

  /* Find the right parser and apply it */
  parsers = g_hash_table_lookup (parsers_by_gtype, gtype_name);
  for (iter = parsers; iter != NULL; iter = iter->next)
    {
      parser = (Parser *) iter->data;
      if (g_variant_type_equal (parser->vtype, vtype))
        {
          if (found_parser) *found_parser = TRUE;
          object = parser->parse (data);
          if (G_UNLIKELY (object == NULL))
            {
              g_critical ("Parser for GType %s signature %s returned NULL. This is not allowed by the contract for DeeSerializableParseFunc.",
                          gtype_name, g_variant_type_peek_string (vtype));
            }
          else if (G_UNLIKELY (!g_type_is_a (G_OBJECT_TYPE (object), parser->type)))
            {
              g_critical ("Parser for GType %s signature %s returned instance of type %s which is not a subtype of %s",
                          gtype_name, g_variant_type_peek_string (vtype), G_OBJECT_TYPE_NAME (object), gtype_name);
              g_object_unref (object);
              object = NULL;
            }

          break;
        }
    }

  if (object == NULL)
    trace ("No parser registered for GType %s with signature %s",
           gtype_name, g_variant_type_peek_string (vtype));

  return object;
}

/**
 * dee_serializable_parse_external:
 * @data: The #GVariant data to parse
 *
 * Reconstruct a #DeeSerializable from #GVariant data. For this function
 * to work you need to register a parser with
 * dee_serializable_register_parser(). Any native Dee class will do so
 * automatically.
 *
 * This method only works on data created with dee_serializable_externalize()
 * and <emphasis>not</emphasis> with data from  dee_serializable_serialize().
 *
 * Since a #DeeSerializableParseFunc is not allowed to fail - by contract -
 * it can be guaranteed that this function only returns %NULL in case there
 * is no known parser for the #GType or #GVariant signature of @data.
 *
 * Return value: (transfer full): A newly constructed #GObject build from @data
 *               or %NULL in case no parser has been registered for the given
 *               #GType or variant signature. Free with g_object_unref().
 */
GObject*
dee_serializable_parse_external (GVariant *data)
{
  GObject             *object = NULL;
  guint32             *version;
  GVariant            *headers, *payload, *payloadv;
  gchar               *gtype_name = NULL;
  GType                gtype_id;

  g_return_val_if_fail (data != NULL, NULL);
  g_return_val_if_fail (g_variant_type_equal (g_variant_get_type (data), G_VARIANT_TYPE ("(ua{sv}v)")), NULL);

  if (G_UNLIKELY (parsers_by_gtype == NULL))
    {
      init_parsers ();
    }

  g_variant_ref_sink (data);

  /* Unpack the serialized data */
  g_variant_get_child (data, 0, "u", &version);
  headers = g_variant_get_child_value (data, 1);
  payloadv = g_variant_get_child_value (data, 2);
  payload = g_variant_get_variant (payloadv);

  if (!g_variant_lookup (headers, "GType", "s", &gtype_name))
    {
      g_critical ("Unable to parse DeeSerializable data: 'GType' header not present in serialized data");
      goto out;
    }

  gtype_id = g_type_from_name (gtype_name);
  if (gtype_id == 0)
    {
      g_critical ("No known GType for type name %s. Perhaps it is not "
                  "registered with serialization subsystem yet?", gtype_name);
      goto out;
    }

  object = dee_serializable_parse (payload, gtype_id);

  out:
    g_variant_unref (data);
    g_variant_unref (headers);
    g_variant_unref (payloadv);
    g_variant_unref (payload);
    g_free (gtype_name);

    return object;
}

/**
 * dee_serializable_parse:
 * @data: The #GVariant data to parse. If this is a floating reference it will
 *        be consumed
 * @type: The #GType of the class to instantiate from @data
 *
 * Reconstruct a #DeeSerializable from #GVariant data. For this function
 * to work you need to register a parser with
 * dee_serializable_register_parser(). Any native Dee class will do so
 * automatically.
 *
 * This method only works on data created with dee_serializable_serialize()
 * and <emphasis>not</emphasis> with data from dee_serializable_externalize().
 *
 * Since a #DeeSerializableParseFunc is not allowed to fail - by contract -
 * it can be guaranteed that this function only returns %NULL in case there
 * is no known parser for @type and #GVariant signature of @data.
 *
 * Return value: (transfer full): A newly constructed #GObject build from @data
 *               or %NULL in case no parser has been registered for the given
 *               #GType or variant signature. Free with g_object_unref().
 */
GObject*
dee_serializable_parse (GVariant *data,
                        GType     type)
{
  GObject *object = NULL;
  GType    orig_type;
  gboolean parser_found = FALSE;
  gboolean parsed = FALSE;

  g_return_val_if_fail (data != NULL, NULL);
  g_return_val_if_fail (g_type_is_a (type, DEE_TYPE_SERIALIZABLE), NULL);

  if (G_UNLIKELY (parsers_by_gtype == NULL))
    {
      init_parsers ();
    }

  orig_type = type;
  g_variant_ref_sink (data);

  while (g_type_is_a (type, DEE_TYPE_SERIALIZABLE))
    {
      object = _parse_type (data, type, &parser_found);
      parsed |= parser_found;

      if (object != NULL)
        break;

      type = g_type_parent (type);
    }

  if (!parsed)
    g_critical ("No parser registered for GType %s with signature %s",
                g_type_name (orig_type), g_variant_get_type_string (data));

  g_variant_unref (data);

  return object;
}

/**
 * dee_serializable_externalize:
 * @self: The instance to externalize
 *
 * Build an externalized form of @self which can be used together with
 * dee_serializable_parse_external() to rebuild a copy of @self.
 *
 * It is important to note that the variant returned from this method does
 * not have the same type signature as returned from a call to
 * dee_serializable_serialize(). Externalization will wrap the serialized data
 * in a container format with versioning information and headers with type
 * information.
 *
 * Return value: A floating reference to a #GVariant with the externalized data.
 */
GVariant*
dee_serializable_externalize (DeeSerializable *self)
{
  GVariant             *payload;
  GVariantBuilder       b;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE (self), NULL);

  payload = dee_serializable_serialize (self);
  g_variant_builder_init (&b, G_VARIANT_TYPE ("(ua{sv}v)"));
  g_variant_builder_add (&b, "u", DEE_SERIALIZABLE_FORMAT_VERSION);

  g_variant_builder_open (&b, G_VARIANT_TYPE ("a{sv}"));
  g_variant_builder_add (&b, "{sv}", "GType", g_variant_new_string (G_OBJECT_TYPE_NAME (self)));
  g_variant_builder_close (&b);

  g_variant_builder_add_value (&b, g_variant_new_variant (payload));

  g_variant_unref (payload);

  return g_variant_builder_end (&b);
}

/**
 * dee_serializable_serialize:
 * @self: The instance to serialize
 *
 * Build a clean serialized representation of @self. The signature of the
 * returned variant is entirely determined by the underlying implementation.
 * You can recreate a serialized instance by calling dee_serializable_parse()
 * provided that you know the correct #GType for the serialized instance.
 *
 * Return value: (transfer full): A reference to a #GVariant with
 *               the serialized data. The variants type signature is entirely
 *               dependent of the underlying implementation. Free using
 *               g_variant_unref().
 */
GVariant*
dee_serializable_serialize (DeeSerializable *self)
{
  DeeSerializableIface *iface;
  GVariant *result;

  g_return_val_if_fail (DEE_IS_SERIALIZABLE (self), NULL);

  iface = DEE_SERIALIZABLE_GET_IFACE (self);

  result = iface->serialize (self);
  /* Make sure we return a real reference
   * FIXME: just use g_variant_take_ref once we depend on glib 2.30 */
  if (g_variant_is_floating (result)) return g_variant_ref_sink (result);

  return result;
}
