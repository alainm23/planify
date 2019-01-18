/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2018 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "as-relation-private.h"

#include <config.h>
#include <glib.h>

#include "as-utils.h"
#include "as-variant-cache.h"

/**
 * SECTION:as-relation
 * @short_description: Description of relations a software component has with other items
 * @include: appstream.h
 *
 * A component can have recommends- or requires relations on other components, system properties,
 * other hardware and interfaces.
 * This class contains a representation of those relations.
 *
 * See also: #AsComponent
 */

typedef struct
{
	AsRelationKind kind;
	AsRelationItemKind item_kind;
	AsRelationCompare compare;

	gchar *value;
	gchar *version;
} AsRelationPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsRelation, as_relation, G_TYPE_OBJECT)

#define GET_PRIVATE(o) (as_relation_get_instance_private (o))

/**
 * as_relation_kind_to_string:
 * @kind: the #AsRelationKind.
 *
 * Converts the enumerated value to a text representation.
 *
 * Returns: string version of @kind
 *
 * Since: 0.12.0
 **/
const gchar*
as_relation_kind_to_string (AsRelationKind kind)
{
	if (kind == AS_RELATION_KIND_REQUIRES)
		return "requires";
	if (kind == AS_RELATION_KIND_RECOMMENDS)
		return "recommends";
	return "unknown";
}

/**
 * as_relation_kind_from_string:
 * @kind_str: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsRelationKind or %AS_RELATION_KIND_UNKNOWN for unknown
 *
 * Since: 0.12.0
 **/
AsRelationKind
as_relation_kind_from_string (const gchar *kind_str)
{
	if (g_strcmp0 (kind_str, "requires") == 0)
		return AS_RELATION_KIND_REQUIRES;
	if (g_strcmp0 (kind_str, "recommends") == 0)
		return AS_RELATION_KIND_RECOMMENDS;
	return AS_RELATION_KIND_UNKNOWN;
}

/**
 * as_relation_item_kind_to_string:
 * @kind: the #AsRelationKind.
 *
 * Converts the enumerated value to a text representation.
 *
 * Returns: string version of @kind
 *
 * Since: 0.12.0
 **/
const gchar*
as_relation_item_kind_to_string (AsRelationItemKind kind)
{
	if (kind == AS_RELATION_ITEM_KIND_ID)
		return "id";
	if (kind == AS_RELATION_ITEM_KIND_MODALIAS)
		return "modalias";
	if (kind == AS_RELATION_ITEM_KIND_KERNEL)
		return "kernel";
	if (kind == AS_RELATION_ITEM_KIND_MEMORY)
		return "memory";
	return "unknown";
}

/**
 * as_relation_item_kind_from_string:
 * @kind_str: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsRelationItemKind or %AS_RELATION_ITEM_KIND_UNKNOWN for unknown
 *
 * Since: 0.12.0
 **/
AsRelationItemKind
as_relation_item_kind_from_string (const gchar *kind_str)
{
	if (g_strcmp0 (kind_str, "id") == 0)
		return AS_RELATION_ITEM_KIND_ID;
	if (g_strcmp0 (kind_str, "modalias") == 0)
		return AS_RELATION_ITEM_KIND_MODALIAS;
	if (g_strcmp0 (kind_str, "kernel") == 0)
		return AS_RELATION_ITEM_KIND_KERNEL;
	if (g_strcmp0 (kind_str, "memory") == 0)
		return AS_RELATION_ITEM_KIND_MEMORY;
	return AS_RELATION_ITEM_KIND_UNKNOWN;
}

/**
 * as_relation_compare_from_string:
 * @compare_str: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsRelationCompare, or %AS_RELATION_COMPARE_UNKNOWN for unknown.
 *
 * Since: 0.12.0
 **/
AsRelationCompare
as_relation_compare_from_string (const gchar *compare_str)
{
	if (g_strcmp0 (compare_str, "eq") == 0)
		return AS_RELATION_COMPARE_EQ;
	if (g_strcmp0 (compare_str, "ne") == 0)
		return AS_RELATION_COMPARE_NE;
	if (g_strcmp0 (compare_str, "gt") == 0)
		return AS_RELATION_COMPARE_GT;
	if (g_strcmp0 (compare_str, "lt") == 0)
		return AS_RELATION_COMPARE_LT;
	if (g_strcmp0 (compare_str, "ge") == 0)
		return AS_RELATION_COMPARE_GE;
	if (g_strcmp0 (compare_str, "le") == 0)
		return AS_RELATION_COMPARE_LE;

	/* YAML */
	if (g_strcmp0 (compare_str, "==") == 0)
		return AS_RELATION_COMPARE_EQ;
	if (g_strcmp0 (compare_str, "!=") == 0)
		return AS_RELATION_COMPARE_NE;
	if (g_strcmp0 (compare_str, ">>") == 0)
		return AS_RELATION_COMPARE_GT;
	if (g_strcmp0 (compare_str, "<<") == 0)
		return AS_RELATION_COMPARE_LT;
	if (g_strcmp0 (compare_str, ">=") == 0)
		return AS_RELATION_COMPARE_GE;
	if (g_strcmp0 (compare_str, "<=") == 0)
		return AS_RELATION_COMPARE_LE;

	/* default value */
	if (compare_str == NULL)
		return AS_RELATION_COMPARE_GE;

	return AS_RELATION_COMPARE_UNKNOWN;
}

/**
 * as_relation_compare_to_string:
 * @compare: the #AsRelationCompare.
 *
 * Converts the enumerated value to an text representation.
 * The enum is converted into a two-letter identifier ("eq", "ge", etc.)
 * for use in the XML representation.
 *
 * Returns: string version of @compare
 *
 * Since: 0.12.0
 **/
const gchar*
as_relation_compare_to_string (AsRelationCompare compare)
{
	if (compare == AS_RELATION_COMPARE_EQ)
		return "eq";
	if (compare == AS_RELATION_COMPARE_NE)
		return "ne";
	if (compare == AS_RELATION_COMPARE_GT)
		return "gt";
	if (compare == AS_RELATION_COMPARE_LT)
		return "lt";
	if (compare == AS_RELATION_COMPARE_GE)
		return "ge";
	if (compare == AS_RELATION_COMPARE_LE)
		return "le";
	return NULL;
}

/**
 * as_relation_compare_to_symbols_string:
 * @compare: the #AsRelationCompare.
 *
 * Converts the enumerated value to an text representation.
 * The enum is converted into an identifier consisting of two
 * mathematical comparison operators ("==", ">=", etc.)
 * for use in the YAML representation and user interfaces.
 *
 * Returns: string version of @compare
 *
 * Since: 0.12.0
 **/
const gchar*
as_relation_compare_to_symbols_string (AsRelationCompare compare)
{
	if (compare == AS_RELATION_COMPARE_EQ)
		return "==";
	if (compare == AS_RELATION_COMPARE_NE)
		return "!=";
	if (compare == AS_RELATION_COMPARE_GT)
		return ">>";
	if (compare == AS_RELATION_COMPARE_LT)
		return "<<";
	if (compare == AS_RELATION_COMPARE_GE)
		return ">=";
	if (compare == AS_RELATION_COMPARE_LE)
		return "<=";
	return NULL;
}

/**
 * as_relation_finalize:
 **/
static void
as_relation_finalize (GObject *object)
{
	AsRelation *relation = AS_RELATION (object);
	AsRelationPrivate *priv = GET_PRIVATE (relation);

	g_free (priv->value);
	g_free (priv->version);

	G_OBJECT_CLASS (as_relation_parent_class)->finalize (object);
}

/**
 * as_relation_init:
 **/
static void
as_relation_init (AsRelation *relation)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);

	priv->compare = AS_RELATION_COMPARE_GE; /* greater-or-equal is the default comparison method */
}

/**
 * as_relation_class_init:
 **/
static void
as_relation_class_init (AsRelationClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_relation_finalize;
}

/**
 * as_relation_get_kind:
 * @relation: a #AsRelation instance.
 *
 * The type (and thereby strength) of this #AsRelation.
 *
 * Returns: an enum of type #AsRelationKind
 *
 * Since: 0.12.0
 */
AsRelationKind
as_relation_get_kind (AsRelation *relation)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	return priv->kind;
}

/**
 * as_relation_set_kind:
 * @relation: a #AsRelation instance.
 * @kind: the new #AsRelationKind
 *
 * Set the kind of this #AsRelation.
 *
 * Since: 0.12.0
 */
void
as_relation_set_kind (AsRelation *relation, AsRelationKind kind)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	priv->kind = kind;
}

/**
 * as_relation_get_item_kind:
 * @relation: a #AsRelation instance.
 *
 * The kind of the item of this #AsRelation.
 *
 * Returns: an enum of type #AsRelationItemKind
 *
 * Since: 0.12.0
 */
AsRelationItemKind
as_relation_get_item_kind (AsRelation *relation)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	return priv->item_kind;
}

/**
 * as_relation_set_item_kind:
 * @relation: a #AsRelation instance.
 * @kind: the new #AsRelationItemKind
 *
 * Set the kind of the item this #AsRelation is about.
 *
 * Since: 0.12.0
 */
void
as_relation_set_item_kind (AsRelation *relation, AsRelationItemKind kind)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	priv->item_kind = kind;
}

/**
 * as_relation_get_compare:
 * @relation: a #AsRelation instance.
 *
 * The version comparison type.
 *
 * Returns: an enum of type #AsRelationCompare
 *
 * Since: 0.12.0
 */
AsRelationCompare
as_relation_get_compare (AsRelation *relation)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	return priv->compare;
}

/**
 * as_relation_set_compare:
 * @relation: an #AsRelation instance.
 * @compare: the new #AsRelationCompare
 *
 * Set the version comparison type of this #AsRelation.
 *
 * Since: 0.12.0
 */
void
as_relation_set_compare (AsRelation *relation, AsRelationCompare compare)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	priv->compare = compare;
}

/**
 * as_relation_get_version:
 * @relation: an #AsRelation instance.
 *
 * Returns: The version of the item this #AsRelation is about.
 *
 * Since: 0.12.0
 **/
const gchar*
as_relation_get_version (AsRelation *relation)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	return priv->version;
}

/**
 * as_relation_set_version:
 * @relation: an #AsRelation instance.
 * @version: the new version.
 *
 * Sets the item version.
 *
 * Since: 0.12.0
 **/
void
as_relation_set_version (AsRelation *relation, const gchar *version)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	g_free (priv->version);
	priv->version = g_strdup (version);
}

/**
 * as_relation_get_value:
 * @relation: an #AsRelation instance.
 *
 * Returns: The value of the item this #AsRelation is about.
 *
 * Since: 0.12.0
 **/
const gchar*
as_relation_get_value (AsRelation *relation)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	return priv->value;
}

/**
 * as_relation_get_value_int:
 * @relation: an #AsRelation instance.
 *
 * Returns: The value of the item this #AsRelation is about as integer.
 *
 * Since: 0.12.0
 **/
gint
as_relation_get_value_int (AsRelation *relation)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	if (priv->value == NULL)
		return 0;
	return g_ascii_strtoll (priv->value, NULL, 10);
}

/**
 * as_relation_set_value:
 * @relation: an #AsRelation instance.
 * @value: the new value.
 *
 * Sets the item value.
 *
 * Since: 0.12.0
 **/
void
as_relation_set_value (AsRelation *relation, const gchar *value)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	g_free (priv->value);
	priv->value = g_strdup (value);
}


/**
 * as_relation_version_compare:
 * @relation: an #AsRelation instance.
 * @version: a version number, e.g. `1.2.0`
 * @error: A #GError or %NULL
 *
 * Tests whether the version number of this #AsRelation is fulfilled by
 * @version. Whether the given version is sufficient to fulfill the version
 * requirement of this #AsRelation is determined by its comparison resraint.
 *
 * Returns: %TRUE if the version from the parameter is sufficient.
 *
 * Since: 0.12.0
 **/
gboolean
as_relation_version_compare (AsRelation *relation, const gchar *version, GError **error)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	gint rc;

	/* if we have no version set, any version checked against is satisfactory */
	if (priv->version == NULL)
		return TRUE;

	switch (priv->compare) {
	case AS_RELATION_COMPARE_EQ:
		rc = as_utils_compare_versions (priv->version, version);
		return rc == 0;
	case AS_RELATION_COMPARE_NE:
		rc = as_utils_compare_versions (priv->version, version);
		return rc != 0;
	case AS_RELATION_COMPARE_LT:
		rc = as_utils_compare_versions (priv->version, version);
		return rc > 0;
	case AS_RELATION_COMPARE_GT:
		rc = as_utils_compare_versions (priv->version, version);
		return rc < 0;
	case AS_RELATION_COMPARE_LE:
		rc = as_utils_compare_versions (priv->version, version);
		return rc >= 0;
	case AS_RELATION_COMPARE_GE:
		rc = as_utils_compare_versions (priv->version, version);
		return rc <= 0;
	default:
		return FALSE;
	}
}

/**
 * as_relation_load_from_xml:
 * @relation: a #AsRelation instance.
 * @ctx: the AppStream document context.
 * @node: the XML node.
 * @error: a #GError.
 *
 * Loads #AsRelation data from an XML node.
 **/
gboolean
as_relation_load_from_xml (AsRelation *relation, AsContext *ctx, xmlNode *node, GError **error)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	gchar *content = NULL;

	content = as_xml_get_node_value (node);
	if (content == NULL)
		return FALSE;
	g_free (priv->value);
	priv->value = content;

	priv->item_kind = as_relation_item_kind_from_string ((const gchar*) node->name);

	g_free (priv->version);
	priv->version = (gchar*) xmlGetProp (node, (xmlChar*) "version");

	if (priv->version != NULL) {
		g_autofree gchar *compare_str = (gchar*) xmlGetProp (node, (xmlChar*) "compare");
		priv->compare = as_relation_compare_from_string (compare_str);
	}

	return TRUE;
}

/**
 * as_relation_to_xml_node:
 * @relation: an #AsRelation
 * @ctx: the AppStream document context.
 * @root: XML node to attach the new node to.
 *
 * Serializes the data to a XML node.
 * @root should be a <requires/> or <recommends/> root node.
 **/
void
as_relation_to_xml_node (AsRelation *relation, AsContext *ctx, xmlNode *root)
{

	AsRelationPrivate *priv = GET_PRIVATE (relation);
	xmlNode *n;

	if (priv->item_kind == AS_RELATION_ITEM_KIND_UNKNOWN)
		return;

	n = xmlNewTextChild (root, NULL,
			     (xmlChar*) as_relation_item_kind_to_string (priv->item_kind),
			     (xmlChar*) priv->value);
	if (priv->version != NULL) {
		xmlNewProp (n, (xmlChar*) "version",
			    (xmlChar*) priv->version);
		xmlNewProp (n, (xmlChar*) "compare",
			    (xmlChar*) as_relation_compare_to_string (priv->compare));
	}
}

/**
 * as_relation_load_from_yaml:
 * @relation: an #AsRelation
 * @ctx: the AppStream document context.
 * @node: the YAML node.
 * @error: a #GError.
 *
 * Loads data from a YAML field.
 **/
gboolean
as_relation_load_from_yaml (AsRelation *relation, AsContext *ctx, GNode *node, GError **error)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	GNode *n;

	if (node->children == NULL)
		return FALSE;

	for (n = node->children; n != NULL; n = n->next) {
		const gchar *entry = as_yaml_node_get_key (n);
		if (entry == NULL)
			continue;

		if (g_strcmp0 (entry, "version") == 0) {
			g_autofree gchar *compare_str = NULL;
			g_autofree gchar *ver_str = g_strdup (as_yaml_node_get_value (n));
			if (strlen (ver_str) <= 2)
				continue; /* this string is too short to contain any valid version */
			compare_str = g_strndup (ver_str, 2);
			priv->compare = as_relation_compare_from_string (compare_str);
			g_free (priv->version);
			priv->version = g_strdup (ver_str + 2);
			g_strstrip (priv->version);
		} else {
			AsRelationItemKind kind = as_relation_item_kind_from_string (entry);
			if (kind != AS_RELATION_ITEM_KIND_UNKNOWN) {
				priv->item_kind = kind;
				g_free (priv->value);
				priv->value = g_strdup (as_yaml_node_get_value (n));
			} else {
				g_debug ("Unknown Requires/Recommends YAML field: %s", entry);
			}
		}
	}

	return TRUE;
}

/**
 * as_relation_emit_yaml:
 * @relation: an #AsRelation
 * @ctx: the AppStream document context.
 * @emitter: The YAML emitter to emit data on.
 *
 * Emit YAML data for this object.
 **/
void
as_relation_emit_yaml (AsRelation *relation, AsContext *ctx, yaml_emitter_t *emitter)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);

	if ((priv->item_kind <= AS_RELATION_ITEM_KIND_UNKNOWN) || (priv->item_kind >= AS_RELATION_ITEM_KIND_LAST))
		return;

	as_yaml_mapping_start (emitter);

	as_yaml_emit_entry (emitter,
			    as_relation_item_kind_to_string (priv->item_kind),
			    priv->value);

	if (priv->version != NULL) {
		g_autofree gchar *ver_str = g_strdup_printf ("%s %s",
							     as_relation_compare_to_symbols_string (priv->compare),
							     priv->version);
		as_yaml_emit_entry (emitter, "version", ver_str);
	}

	as_yaml_mapping_end (emitter);
}

/**
 * as_relation_to_variant:
 * @relation: an #AsRelation
 * @builder: A #GVariantBuilder
 *
 * Serialize the current active state of this object to a GVariant
 * for use in the on-disk binary cache.
 */
void
as_relation_to_variant (AsRelation *relation, GVariantBuilder *builder)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	GVariantBuilder rel_dict;

	g_variant_builder_init (&rel_dict, G_VARIANT_TYPE_VARDICT);

	as_variant_builder_add_kv (&rel_dict, "kind",
				g_variant_new_uint32 (priv->kind));
	as_variant_builder_add_kv (&rel_dict, "item_kind",
				g_variant_new_uint32 (priv->item_kind));
	as_variant_builder_add_kv (&rel_dict, "compare",
				g_variant_new_uint32 (priv->compare));

	as_variant_builder_add_kv (&rel_dict, "version",
				as_variant_mstring_new (priv->version));
	as_variant_builder_add_kv (&rel_dict, "value",
				as_variant_mstring_new (priv->value));

	g_variant_builder_add_value (builder, g_variant_builder_end (&rel_dict));
}

/**
 * as_relation_set_from_variant:
 * @relation: an #AsRelation
 * @variant: The #GVariant to read from.
 *
 * Read the active state of this object from a #GVariant serialization.
 * This is used by the on-disk binary cache.
 */
gboolean
as_relation_set_from_variant (AsRelation *relation, GVariant *variant)
{
	AsRelationPrivate *priv = GET_PRIVATE (relation);
	GVariantDict dict;
	GVariant *var;

	g_variant_dict_init (&dict, variant);

	priv->kind = as_variant_get_dict_uint32 (&dict, "kind");
	priv->item_kind = as_variant_get_dict_uint32 (&dict, "item_kind");
	priv->compare = as_variant_get_dict_uint32 (&dict, "compare");

	as_relation_set_version (relation,
				as_variant_get_dict_mstr (&dict, "version", &var));
	g_variant_unref (var);

	as_relation_set_value (relation,
				as_variant_get_dict_mstr (&dict, "value", &var));
	g_variant_unref (var);

	return TRUE;
}

/**
 * as_relation_new:
 *
 * Creates a new #AsRelation.
 *
 * Returns: (transfer full): a #AsRelation
 *
 * Since: 0.11.0
 **/
AsRelation*
as_relation_new (void)
{
	AsRelation *relation;
	relation = g_object_new (AS_TYPE_RELATION, NULL);
	return AS_RELATION (relation);
}
