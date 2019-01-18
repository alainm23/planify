/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016 Lucas Moura <lucas.moura128@gmail.com>
 * Copyright (C) 2017 Matthias Klumpp <matthias@tenstral.net>
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

/**
 * SECTION: as-suggested
 * @short_description: Suggestions for other software suggested by a component.
 * @include: appstream.h
 *
 * This class provides a list of other component-ids suggested by a software component, as well
 * as an origin of the suggestion (manually suggested by the upstream project, or
 * automatically determined by heuristics).
 */

#include "config.h"

#include "as-suggested.h"
#include "as-suggested-private.h"
#include "as-variant-cache.h"

typedef struct
{
	AsSuggestedKind kind;
	GPtrArray *cpt_ids; /* of utf8 */
} AsSuggestedPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsSuggested, as_suggested, G_TYPE_OBJECT)
#define GET_PRIVATE(o) (as_suggested_get_instance_private (o))

/**
 * as_suggested_kind_to_string:
 * @kind: the %AsSuggestedKind.
 *
 * Converts the enumerated value to an text representation.
 *
 * Returns: string version of @kind
 **/
const gchar*
as_suggested_kind_to_string (AsSuggestedKind kind)
{
	if (kind == AS_SUGGESTED_KIND_UPSTREAM)
		return "upstream";
	if (kind == AS_SUGGESTED_KIND_HEURISTIC)
		return "heuristic";

	return "unknown";
}

/**
 * as_suggested_kind_from_string:
 * @kind_str: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsSuggestedKind or %AS_SUGGESTED_KIND_UNKNOWN for unknown
 **/
AsSuggestedKind
as_suggested_kind_from_string (const gchar *kind_str)
{
	/* if the kind is not set, we assume upstream */
	if (kind_str == NULL)
		return AS_SUGGESTED_KIND_UPSTREAM;

	if (g_strcmp0 (kind_str, "upstream") == 0)
		return AS_SUGGESTED_KIND_UPSTREAM;
	if (g_strcmp0 (kind_str, "heuristic") == 0)
		return AS_SUGGESTED_KIND_HEURISTIC;

	return AS_SUGGESTED_KIND_UNKNOWN;
}

/**
 * as_suggested_finalize:
 **/
static void
as_suggested_finalize (GObject *object)
{
	AsSuggested *suggested = AS_SUGGESTED (object);
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);

	g_ptr_array_unref (priv->cpt_ids);

	G_OBJECT_CLASS (as_suggested_parent_class)->finalize (object);
}

/**
 * as_suggested_init:
 **/
static void
as_suggested_init (AsSuggested *suggested)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);

	priv->cpt_ids = g_ptr_array_new_with_free_func (g_free);
}

/**
 * as_suggested_get_kind:
 * @suggested: a #AsSuggested instance.
 *
 * Gets the suggested kind.
 *
 * Returns: the #AssuggestedKind
 **/
AsSuggestedKind
as_suggested_get_kind (AsSuggested *suggested)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);
	return priv->kind;
}

/**
 * as_suggested_set_kind:
 * @suggested: a #AsSuggested instance.
 * @kind: the #AsSuggestedKind, e.g. %AS_SUGGESTED_KIND_HEURISTIC.
 *
 * Sets the suggested kind.
 **/
void
as_suggested_set_kind (AsSuggested *suggested, AsSuggestedKind kind)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);
	priv->kind = kind;
}

/**
 * as_suggested_get_ids:
 * @suggested: a #AsSuggested instance.
 *
 * Get a list of components id that generated the suggestion
 *
 * Returns: (transfer none) (element-type utf8): an array of components id
 */
GPtrArray*
as_suggested_get_ids (AsSuggested *suggested)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);
	return priv->cpt_ids;
}


/**
 * as_suggested_add_id:
 * @suggested: a #AsSuggested instance.
 * @cid: The component id to add
 *
 * Add a component id to this suggested object.
 **/
void
as_suggested_add_id (AsSuggested *suggested, const gchar *cid)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);
	g_ptr_array_add (priv->cpt_ids, g_strdup (cid));
}

/**
 * as_suggested_is_valid:
 * @suggested: a #AsSuggested instance.
 *
 * Check if the essential properties of this suggestion are
 * populated with useful data.
 *
 * Returns: %TRUE if we have useful data.
 */
gboolean
as_suggested_is_valid (AsSuggested *suggested)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);

	if (priv->kind == AS_SUGGESTED_KIND_UNKNOWN)
		return FALSE;
	if (priv->cpt_ids->len == 0)
		return FALSE;

	return TRUE;
}

/**
 * as_suggested_load_from_xml:
 * @suggested: a #AsSuggested instance.
 * @ctx: the AppStream document context.
 * @node: the XML node.
 * @error: a #GError.
 *
 * Loads data from an XML node.
 **/
gboolean
as_suggested_load_from_xml (AsSuggested *suggested, AsContext *ctx, xmlNode *node, GError **error)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);
	xmlNode *iter;
	g_autofree gchar *type_str = NULL;

	type_str = (gchar*) xmlGetProp (node, (xmlChar*) "type");
	priv->kind = as_suggested_kind_from_string (type_str);
	if (priv->kind == AS_SUGGESTED_KIND_UNKNOWN) {
		g_debug ("Found suggests tag of unknown type '%s' at %s:%li. Ignoring it.",
			 type_str, as_context_get_filename (ctx), xmlGetLineNo (node));
		return FALSE;
	}

	for (iter = node->children; iter != NULL; iter = iter->next) {
		if (iter->type != XML_ELEMENT_NODE)
			continue;

		if (g_strcmp0 ((gchar*) iter->name, "id") == 0) {
			g_autofree gchar *content = NULL;
			content = as_xml_get_node_value (iter);

			if (content != NULL)
				as_suggested_add_id (suggested, content);
		}
	}

	return priv->cpt_ids->len > 0;
}

/**
 * as_suggested_to_xml_node:
 * @suggested: a #AsSuggested instance.
 * @ctx: the AppStream document context.
 * @root: XML node to attach the new nodes to.
 *
 * Serializes the data to an XML node.
 **/
void
as_suggested_to_xml_node (AsSuggested *suggested, AsContext *ctx, xmlNode *root)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);
	guint j;
	xmlNode *node;

	/* non-upstream tags are not allowed in metainfo files */
	if ((priv->kind != AS_SUGGESTED_KIND_UPSTREAM) && (as_context_get_style (ctx) == AS_FORMAT_STYLE_METAINFO))
		return;

	node = xmlNewChild (root, NULL, (xmlChar*) "suggests", NULL);
	xmlNewProp (node, (xmlChar*) "type",
		    (xmlChar*) as_suggested_kind_to_string (priv->kind));

	for (j = 0; j < priv->cpt_ids->len; j++) {
		const gchar *cid = (const gchar*) g_ptr_array_index (priv->cpt_ids, j);
		xmlNewTextChild (node, NULL,
					(xmlChar*) "id",
					(xmlChar*) cid);
	}
}

/**
 * as_suggested_load_from_yaml:
 * @suggested: a #AsSuggested instance.
 * @ctx: the AppStream document context.
 * @node: the YAML node.
 * @error: a #GError.
 *
 * Loads data from a YAML field.
 **/
gboolean
as_suggested_load_from_yaml (AsSuggested *suggested, AsContext *ctx, GNode *node, GError **error)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);
	GNode *n;

	for (n = node->children; n != NULL; n = n->next) {
		const gchar *key = as_yaml_node_get_key (n);
		const gchar *value = as_yaml_node_get_value (n);

		if (g_strcmp0 (key, "type") == 0) {
			priv->kind = as_suggested_kind_from_string (value);
		} else if (g_strcmp0 (key, "ids") == 0) {
			as_yaml_list_to_str_array (n, priv->cpt_ids);
		} else {
			as_yaml_print_unknown ("Suggests", key);
		}
	}

	return TRUE;
}

/**
 * as_suggested_emit_yaml:
 * @suggested: a #AsSuggested instance.
 * @ctx: the AppStream document context.
 * @emitter: The YAML emitter to emit data on.
 *
 * Emit YAML data for this object.
 **/
void
as_suggested_emit_yaml (AsSuggested *suggested, AsContext *ctx, yaml_emitter_t *emitter)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);

	/* start mapping for this suggestion */
	as_yaml_mapping_start (emitter);

	/* type */
	as_yaml_emit_entry (emitter, "type", as_suggested_kind_to_string (priv->kind));

	/* component-ids */
	as_yaml_emit_sequence (emitter, "ids", priv->cpt_ids);

	/* end mapping for the suggestion */
	as_yaml_mapping_end (emitter);
}

/**
 * as_suggested_to_variant:
 * @suggested: a #AsSuggested instance.
 * @builder: A #GVariantBuilder
 *
 * Serialize the current active state of this object to a GVariant
 * for use in the on-disk binary cache.
 */
void
as_suggested_to_variant (AsSuggested *suggested, GVariantBuilder *builder)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);
	GVariant *sug_var;

	sug_var = g_variant_new ("{uv}", priv->kind, as_variant_from_string_ptrarray (priv->cpt_ids));
	g_variant_builder_add_value (builder, sug_var);
}

/**
 * as_suggested_set_from_variant:
 * @suggested: a #AsSuggested instance.
 * @variant: The #GVariant to read from.
 *
 * Read the active state of this object from a #GVariant serialization.
 * This is used by the on-disk binary cache.
 */
gboolean
as_suggested_set_from_variant (AsSuggested *suggested, GVariant *variant)
{
	AsSuggestedPrivate *priv = GET_PRIVATE (suggested);
	GVariantIter inner_iter;
	GVariant *id_child;
	g_autoptr(GVariant) ids_var = NULL;

	g_variant_get (variant, "{uv}", &priv->kind, &ids_var);

	g_variant_iter_init (&inner_iter, ids_var);
	while ((id_child = g_variant_iter_next_value (&inner_iter))) {
		as_suggested_add_id (suggested,
					g_variant_get_string (id_child, NULL));
		g_variant_unref (id_child);
	}

	return TRUE;
}

/**
 * as_suggested_new:
 *
 * Creates a new #AsSuggested.
 *
 * Returns: (transfer full): a new #AsSuggested
 **/
AsSuggested*
as_suggested_new (void)
{
	AsSuggested *suggested;
	suggested = g_object_new (AS_TYPE_SUGGESTED, NULL);
	return AS_SUGGESTED (suggested);
}

/**
 * as_suggested_class_init:
 **/
static void
as_suggested_class_init (AsSuggestedClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_suggested_finalize;
}
