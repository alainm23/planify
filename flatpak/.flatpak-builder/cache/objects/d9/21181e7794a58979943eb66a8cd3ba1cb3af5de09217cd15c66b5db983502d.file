/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016 Richard Hughes <richard@hughsie.com>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA
 */

/**
 * SECTION:as-content-rating
 * @short_description: Object representing a content rating
 * @include: appstream.h
 * @stability: Unstable
 *
 * Content ratings are age-specific guidelines for applications.
 *
 * See also: #AsComponent
 */

#include "config.h"

#include "as-content-rating.h"
#include "as-content-rating-private.h"

#include "as-variant-cache.h"

typedef struct
{
	gchar		*kind;
	GPtrArray	*keys; /* of AsContentRatingKey */
} AsContentRatingPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsContentRating, as_content_rating, G_TYPE_OBJECT)

#define GET_PRIVATE(o) (as_content_rating_get_instance_private (o))

static void
as_content_rating_finalize (GObject *object)
{
	AsContentRating *content_rating = AS_CONTENT_RATING (object);
	AsContentRatingPrivate *priv = GET_PRIVATE (content_rating);

	if (priv->kind != NULL)
		g_free (priv->kind);
	g_ptr_array_unref (priv->keys);

	G_OBJECT_CLASS (as_content_rating_parent_class)->finalize (object);
}

static void
as_content_rating_key_free (AsContentRatingKey *key)
{
	if (key->id != NULL)
		g_free (key->id);
	g_slice_free (AsContentRatingKey, key);
}

static void
as_content_rating_init (AsContentRating *content_rating)
{
	AsContentRatingPrivate *priv = GET_PRIVATE (content_rating);
	priv->keys = g_ptr_array_new_with_free_func ((GDestroyNotify) as_content_rating_key_free);
}

static void
as_content_rating_class_init (AsContentRatingClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_content_rating_finalize;
}

/**
 * as_content_rating_get_value:
 * @content_rating: a #AsContentRating
 * @id: A ratings ID, e.g. `violence-bloodshed`.
 *
 * Gets the value of a content rating key.
 *
 * Returns: the #AsContentRatingValue, or %AS_CONTENT_RATING_VALUE_UNKNOWN
 *
 * Since: 0.11.0
 **/
AsContentRatingValue
as_content_rating_get_value (AsContentRating *content_rating, const gchar *id)
{
	AsContentRatingPrivate *priv = GET_PRIVATE (content_rating);
	guint i;
	for (i = 0; i < priv->keys->len; i++) {
		AsContentRatingKey *key = g_ptr_array_index (priv->keys, i);
		if (g_strcmp0 (key->id, id) == 0)
			return key->value;
	}
	return AS_CONTENT_RATING_VALUE_UNKNOWN;
}

/**
 * as_content_rating_set_value:
 * @content_rating: a #AsContentRating
 * @id: A ratings ID, e.g. `violence-bloodshed`.
 * @value: A #AsContentRatingValue, e.g. %AS_CONTENT_RATING_VALUE_INTENSE
 *
 * Sets the value of a content rating key.
 *
 * Since: 0.11.0
 **/
void
as_content_rating_set_value (AsContentRating *content_rating, const gchar *id, AsContentRatingValue value)
{
	AsContentRatingPrivate *priv = GET_PRIVATE (content_rating);
	AsContentRatingKey *key;

	key = g_slice_new0 (AsContentRatingKey);
	key->id = g_strdup (id);
	key->value = value;
	g_ptr_array_add (priv->keys, key);
}

/**
 * as_content_rating_value_to_string:
 * @value: the #AsContentRatingValue.
 *
 * Converts the enumerated value to an text representation.
 *
 * Returns: string version of @value
 *
 * Since: 0.11.0
 **/
const gchar *
as_content_rating_value_to_string (AsContentRatingValue value)
{
	if (value == AS_CONTENT_RATING_VALUE_NONE)
		return "none";
	if (value == AS_CONTENT_RATING_VALUE_MILD)
		return "mild";
	if (value == AS_CONTENT_RATING_VALUE_MODERATE)
		return "moderate";
	if (value == AS_CONTENT_RATING_VALUE_INTENSE)
		return "intense";
	return "unknown";
}

/**
 * as_content_rating_value_from_string:
 * @value: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsContentRatingValue or %AS_CONTENT_RATING_VALUE_UNKNOWN for unknown
 *
 * Since: 0.11.0
 **/
AsContentRatingValue
as_content_rating_value_from_string (const gchar *value)
{
	if (g_strcmp0 (value, "none") == 0)
		return AS_CONTENT_RATING_VALUE_NONE;
	if (g_strcmp0 (value, "mild") == 0)
		return AS_CONTENT_RATING_VALUE_MILD;
	if (g_strcmp0 (value, "moderate") == 0)
		return AS_CONTENT_RATING_VALUE_MODERATE;
	if (g_strcmp0 (value, "intense") == 0)
		return AS_CONTENT_RATING_VALUE_INTENSE;
	return AS_CONTENT_RATING_VALUE_UNKNOWN;
}

/**
 * as_content_rating_id_value_to_csm_age:
 * @id: the subsection ID e.g. "violence-cartoon"
 * @value: the #AsContentRatingValue, e.g. %AS_CONTENT_RATING_VALUE_INTENSE
 *
 * Gets the Common Sense Media approved age for a specific rating level.
 *
 * Returns: The age in years, or 0 for no details.
 *
 * Since: 0.11.0
 **/
static guint
as_content_rating_id_value_to_csm_age (const gchar *id, AsContentRatingValue value)
{
	guint i;
	struct {
		const gchar		*id;
		AsContentRatingValue	 value;
		guint			 csm_age;
	} to_csm_age[] =  {
	{ "violence-cartoon",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "violence-cartoon",	AS_CONTENT_RATING_VALUE_MILD,		3 },
	{ "violence-cartoon",	AS_CONTENT_RATING_VALUE_MODERATE,	4 },
	{ "violence-cartoon",	AS_CONTENT_RATING_VALUE_INTENSE,	6 },
	{ "violence-fantasy",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "violence-fantasy",	AS_CONTENT_RATING_VALUE_MILD,		3 },
	{ "violence-fantasy",	AS_CONTENT_RATING_VALUE_MODERATE,	7 },
	{ "violence-fantasy",	AS_CONTENT_RATING_VALUE_INTENSE,	8 },
	{ "violence-realistic",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "violence-realistic",	AS_CONTENT_RATING_VALUE_MILD,		4 },
	{ "violence-realistic",	AS_CONTENT_RATING_VALUE_MODERATE,	9 },
	{ "violence-realistic",	AS_CONTENT_RATING_VALUE_INTENSE,	14 },
	{ "violence-bloodshed",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "violence-bloodshed",	AS_CONTENT_RATING_VALUE_MILD,		9 },
	{ "violence-bloodshed",	AS_CONTENT_RATING_VALUE_MODERATE,	11 },
	{ "violence-bloodshed",	AS_CONTENT_RATING_VALUE_INTENSE,	18 },
	{ "violence-sexual",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "violence-sexual",	AS_CONTENT_RATING_VALUE_INTENSE,	18 },
	{ "drugs-alcohol",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "drugs-alcohol",	AS_CONTENT_RATING_VALUE_MILD,		11 },
	{ "drugs-alcohol",	AS_CONTENT_RATING_VALUE_MODERATE,	13 },
	{ "drugs-narcotics",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "drugs-narcotics",	AS_CONTENT_RATING_VALUE_MILD,		12 },
	{ "drugs-narcotics",	AS_CONTENT_RATING_VALUE_MODERATE,	14 },
	{ "drugs-tobacco",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "drugs-tobacco",	AS_CONTENT_RATING_VALUE_MILD,		10 },
	{ "drugs-tobacco",	AS_CONTENT_RATING_VALUE_MODERATE,	13 },
	{ "sex-nudity",		AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "sex-nudity",		AS_CONTENT_RATING_VALUE_MILD,		12 },
	{ "sex-nudity",		AS_CONTENT_RATING_VALUE_MODERATE,	14 },
	{ "sex-themes",		AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "sex-themes",		AS_CONTENT_RATING_VALUE_MILD,		13 },
	{ "sex-themes",		AS_CONTENT_RATING_VALUE_MODERATE,	14 },
	{ "sex-themes",		AS_CONTENT_RATING_VALUE_INTENSE,	15 },
	{ "language-profanity",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "language-profanity",	AS_CONTENT_RATING_VALUE_MILD,		8 },
	{ "language-profanity",	AS_CONTENT_RATING_VALUE_MODERATE,	11 },
	{ "language-profanity",	AS_CONTENT_RATING_VALUE_INTENSE,	14 },
	{ "language-humor",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "language-humor",	AS_CONTENT_RATING_VALUE_MILD,		3 },
	{ "language-humor",	AS_CONTENT_RATING_VALUE_MODERATE,	8 },
	{ "language-humor",	AS_CONTENT_RATING_VALUE_INTENSE,	14 },
	{ "language-discrimination", AS_CONTENT_RATING_VALUE_NONE,	0 },
	{ "language-discrimination", AS_CONTENT_RATING_VALUE_MILD,	9 },
	{ "language-discrimination", AS_CONTENT_RATING_VALUE_MODERATE,	10 },
	{ "language-discrimination", AS_CONTENT_RATING_VALUE_INTENSE,	11 },
	{ "money-advertising",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "money-advertising",	AS_CONTENT_RATING_VALUE_MILD,		7 },
	{ "money-advertising",	AS_CONTENT_RATING_VALUE_MODERATE,	8 },
	{ "money-advertising",	AS_CONTENT_RATING_VALUE_INTENSE,	10 },
	{ "money-gambling",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "money-gambling",	AS_CONTENT_RATING_VALUE_MILD,		7 },
	{ "money-gambling",	AS_CONTENT_RATING_VALUE_MODERATE,	10 },
	{ "money-gambling",	AS_CONTENT_RATING_VALUE_INTENSE,	18 },
	{ "money-purchasing",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "money-purchasing",	AS_CONTENT_RATING_VALUE_INTENSE,	15 },
	{ "social-chat",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "social-chat",	AS_CONTENT_RATING_VALUE_MILD,		4 },
	{ "social-chat",	AS_CONTENT_RATING_VALUE_MODERATE,	10 },
	{ "social-chat",	AS_CONTENT_RATING_VALUE_INTENSE,	13 },
	{ "social-audio",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "social-audio",	AS_CONTENT_RATING_VALUE_INTENSE,	15 },
	{ "social-contacts",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "social-contacts",	AS_CONTENT_RATING_VALUE_INTENSE,	12 },
	{ "social-info",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "social-info",	AS_CONTENT_RATING_VALUE_INTENSE,	13 },
	{ "social-location",	AS_CONTENT_RATING_VALUE_NONE,		0 },
	{ "social-location",	AS_CONTENT_RATING_VALUE_INTENSE,	13 },
	{ NULL, 0, 0 } };
	for (i = 0; to_csm_age[i].id != NULL; i++) {
		if (value == to_csm_age[i].value &&
		    g_strcmp0 (id, to_csm_age[i].id) == 0)
			return to_csm_age[i].csm_age;
	}
	return 0;
}

/**
 * as_content_rating_get_minimum_age:
 * @content_rating: a #AsContentRating
 *
 * Gets the lowest Common Sense Media approved age for the content_rating block.
 * NOTE: these numbers are based on the data and descriptions available from
 * https://www.commonsensemedia.org/about-us/our-mission/about-our-ratings and
 * you may disagree with them.
 *
 * You're free to disagree with these, and of course you should use your own
 * brain to work our if your child is able to cope with the concepts enumerated
 * here. Some 13 year olds mey be fine with the concept of mutilation of body
 * parts, others may get nightmares.
 *
 * Returns: The age in years, 0 for no rating, or G_MAXUINT for no details.
 *
 * Since: 0.11.0
 **/
guint
as_content_rating_get_minimum_age (AsContentRating *content_rating)
{
	AsContentRatingPrivate *priv = GET_PRIVATE (content_rating);
	guint i;
	guint csm_age = 0;

	/* check kind */
	if (g_strcmp0 (priv->kind, "oars-1.0") != 0)
		return G_MAXUINT;

	for (i = 0; i < priv->keys->len; i++) {
		AsContentRatingKey *key;
		guint csm_tmp;
		key = g_ptr_array_index (priv->keys, i);
		csm_tmp = as_content_rating_id_value_to_csm_age (key->id, key->value);
		if (csm_tmp > 0 && csm_tmp > csm_age)
			csm_age = csm_tmp;
	}
	return csm_age;
}

/**
 * as_content_rating_get_kind:
 * @content_rating: a #AsContentRating
 *
 * Gets the content_rating kind.
 *
 * Returns: a string, e.g. "oars-1.0", or NULL
 *
 * Since: 0.11.0
 **/
const gchar*
as_content_rating_get_kind (AsContentRating *content_rating)
{
	AsContentRatingPrivate *priv = GET_PRIVATE (content_rating);
	return priv->kind;
}

/**
 * as_content_rating_set_kind:
 * @content_rating: a #AsContentRating
 * @kind: the rating kind, e.g. "oars-1.0"
 *
 * Sets the content rating kind.
 *
 * Since: 0.11.0
 **/
void
as_content_rating_set_kind (AsContentRating *content_rating, const gchar *kind)
{
	AsContentRatingPrivate *priv = GET_PRIVATE (content_rating);
	g_free (priv->kind);
	priv->kind = g_strdup (kind);
}

/**
 * as_content_rating_load_from_xml:
 * @content_rating: a #AsContentRating
 * @ctx: the AppStream document context.
 * @node: the XML node.
 * @error: a #GError.
 *
 * Loads data from an XML node.
 **/
gboolean
as_content_rating_load_from_xml (AsContentRating *content_rating, AsContext *ctx, xmlNode *node, GError **error)
{
	xmlNode *iter;
	g_autofree gchar *type_str = NULL;

	/* set selected content-rating type (usually oars-1.0) */
	type_str = (gchar*) xmlGetProp (node, (xmlChar*) "type");
	as_content_rating_set_kind (content_rating, (gchar*) type_str);

	/* read attributes */
	for (iter = node->children; iter != NULL; iter = iter->next) {
		g_autofree gchar *attr_id = NULL;
		AsContentRatingValue attr_value;
		g_autofree gchar *str_value = NULL;

		if (iter->type != XML_ELEMENT_NODE)
			continue;
		if (g_strcmp0 ((gchar*) iter->name, "content_attribute") != 0)
			continue;

		attr_id = (gchar*) xmlGetProp (iter, (xmlChar*) "id");
		str_value = as_xml_get_node_value (iter);
		attr_value = as_content_rating_value_from_string (str_value);
		if ((attr_value == AS_CONTENT_RATING_VALUE_UNKNOWN) || (attr_id == NULL))
			continue; /* this rating attribute is invalid */

		as_content_rating_set_value (content_rating, attr_id, attr_value);
	}

	return TRUE;
}

/**
 * as_content_rating_to_xml_node:
 * @content_rating: a #AsContentRating
 * @ctx: the AppStream document context.
 * @root: XML node to attach the new nodes to.
 *
 * Serializes the data to an XML node.
 **/
void
as_content_rating_to_xml_node (AsContentRating *content_rating, AsContext *ctx, xmlNode *root)
{
	AsContentRatingPrivate *priv = GET_PRIVATE (content_rating);
	guint i;
	xmlNode *rnode;

	rnode = xmlNewChild (root, NULL, (xmlChar*) "content_rating", NULL);
	xmlNewProp (rnode,
		    (xmlChar*) "type",
		    (xmlChar*) priv->kind);

	for (i = 0; i < priv->keys->len; i++) {
		xmlNode *anode;
		AsContentRatingKey *key = (AsContentRatingKey*) g_ptr_array_index (priv->keys, i);

		anode = xmlNewTextChild (rnode,
					 NULL,
					 (xmlChar*) "content_attribute",
					 (xmlChar*) as_content_rating_value_to_string (key->value));
		xmlNewProp (anode,
			    (xmlChar*) "id",
			    (xmlChar*) key->id);
	}
}

/**
 * as_content_rating_load_from_yaml:
 * @content_rating: a #AsContentRating
 * @ctx: the AppStream document context.
 * @node: the YAML node.
 * @error: a #GError.
 *
 * Loads data from a YAML field.
 **/
gboolean
as_content_rating_load_from_yaml (AsContentRating *content_rating, AsContext *ctx, GNode *node, GError **error)
{
	GNode *n;

	as_content_rating_set_kind (content_rating,
				    as_yaml_node_get_key (node));
	for (n = node->children; n != NULL; n = n->next) {
		AsContentRatingValue attr_value;

		attr_value = as_content_rating_value_from_string (as_yaml_node_get_value (n));
		if (attr_value == AS_CONTENT_RATING_VALUE_UNKNOWN)
			continue;

		as_content_rating_set_value (content_rating,
					     as_yaml_node_get_key (n),
					     attr_value);
	}

	return TRUE;
}

/**
 * as_content_rating_emit_yaml:
 * @content_rating: a #AsContentRating
 * @ctx: the AppStream document context.
 * @emitter: The YAML emitter to emit data on.
 *
 * Emit YAML data for this object.
 **/
void
as_content_rating_emit_yaml (AsContentRating *content_rating, AsContext *ctx, yaml_emitter_t *emitter)
{
	AsContentRatingPrivate *priv = GET_PRIVATE (content_rating);
	guint j;

	if (priv->kind == NULL)
		return; /* we need to check for null to not mess up the YAML sequence */
	as_yaml_emit_scalar (emitter, priv->kind);

	as_yaml_mapping_start (emitter);
	for (j = 0; j < priv->keys->len; j++) {
		AsContentRatingKey *key = (AsContentRatingKey*) g_ptr_array_index (priv->keys, j);

		as_yaml_emit_entry (emitter,
				    key->id,
				    as_content_rating_value_to_string (key->value));
	}
	as_yaml_mapping_end (emitter);
}

/**
 * as_content_rating_to_variant:
 * @content_rating: a #AsContentRating
 * @builder: A #GVariantBuilder
 *
 * Serialize the current active state of this object to a GVariant
 * for use in the on-disk binary cache.
 */
void
as_content_rating_to_variant (AsContentRating *content_rating, GVariantBuilder *builder)
{
	AsContentRatingPrivate *priv = GET_PRIVATE (content_rating);
	GVariantBuilder values_b;
	GVariantBuilder rating_b;
	guint j;

	g_variant_builder_init (&values_b, (const GVariantType *) "a{su}");
	for (j = 0; j < priv->keys->len; j++) {
		AsContentRatingKey *key = (AsContentRatingKey*) g_ptr_array_index (priv->keys, j);
		g_variant_builder_add (&values_b, "{su}", key->id, key->value);
	}

	g_variant_builder_init (&rating_b, G_VARIANT_TYPE_ARRAY);
	g_variant_builder_add_parsed (&rating_b, "{'type', %v}", as_variant_mstring_new (priv->kind));
	g_variant_builder_add_parsed (&rating_b, "{'values', %v}", g_variant_builder_end (&values_b));

	g_variant_builder_add_value (builder, g_variant_builder_end (&rating_b));
}

/**
 * as_content_rating_set_from_variant:
 * @content_rating: a #AsContentRating
 * @variant: The #GVariant to read from.
 *
 * Read the active state of this object from a #GVariant serialization.
 * This is used by the on-disk binary cache.
 */
gboolean
as_content_rating_set_from_variant (AsContentRating *content_rating, GVariant *variant)
{
	GVariantIter inner_iter;
	g_auto(GVariantDict) idict;
	GVariant *tmp;
	GVariant *v_child;
	g_autoptr(GVariant) values_var = NULL;

	g_variant_dict_init (&idict, variant);

	as_content_rating_set_kind (content_rating, as_variant_get_dict_mstr (&idict, "type", &tmp));
	g_variant_unref (tmp);

	values_var = g_variant_dict_lookup_value (&idict, "values", G_VARIANT_TYPE_ARRAY);
	if (values_var == NULL)
		return FALSE;

	g_variant_iter_init (&inner_iter, values_var);

	while ((v_child = g_variant_iter_next_value (&inner_iter))) {
		AsContentRatingValue val;
		g_autofree gchar *id_str = NULL;

		g_variant_get (v_child, "{su}", &id_str, &val);
		as_content_rating_set_value (content_rating, id_str, val);

		g_variant_unref (v_child);
	}

	return TRUE;
}

/**
 * as_content_rating_new:
 *
 * Creates a new #AsContentRating.
 *
 * Returns: (transfer full): a #AsContentRating
 *
 * Since: 0.11.0
 **/
AsContentRating*
as_content_rating_new (void)
{
	AsContentRating *content_rating;
	content_rating = g_object_new (AS_TYPE_CONTENT, NULL);
	return AS_CONTENT_RATING (content_rating);
}
