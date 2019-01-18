/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016 Matthias Klumpp <matthias@tenstral.net>
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
 * SECTION:as-bundle
 * @short_description: Description of bundles the #AsComponent is shipped with.
 * @include: appstream.h
 *
 * This class provides information contained in an AppStream bundle tag.
 * See https://www.freedesktop.org/software/appstream/docs/chap-CollectionData.html#tag-ct-bundle
 * for more information.
 *
 * See also: #AsComponent
 */

#include "config.h"
#include "as-bundle-private.h"
#include "as-variant-cache.h"

typedef struct
{
	AsBundleKind	kind;
	gchar		*id;
} AsBundlePrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsBundle, as_bundle, G_TYPE_OBJECT)
#define GET_PRIVATE(o) (as_bundle_get_instance_private (o))

/**
 * as_bundle_kind_to_string:
 * @kind: the %AsBundleKind.
 *
 * Converts the enumerated value to an text representation.
 *
 * Returns: string version of @kind
 *
 * Since: 0.8.0
 **/
const gchar*
as_bundle_kind_to_string (AsBundleKind kind)
{
	if (kind == AS_BUNDLE_KIND_PACKAGE)
		return "package";
	if (kind == AS_BUNDLE_KIND_LIMBA)
		return "limba";
	if (kind == AS_BUNDLE_KIND_FLATPAK)
		return "flatpak";
	if (kind == AS_BUNDLE_KIND_APPIMAGE)
		return "appimage";
	if (kind == AS_BUNDLE_KIND_SNAP)
		return "snap";
	return "unknown";
}

/**
 * as_bundle_kind_from_string:
 * @bundle_str: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsBundleKind or %AS_BUNDLE_KIND_UNKNOWN for unknown
 **/
AsBundleKind
as_bundle_kind_from_string (const gchar *bundle_str)
{
	if (g_strcmp0 (bundle_str, "package") == 0)
		return AS_BUNDLE_KIND_PACKAGE;
	if (g_strcmp0 (bundle_str, "limba") == 0)
		return AS_BUNDLE_KIND_LIMBA;
	if (g_strcmp0 (bundle_str, "flatpak") == 0)
		return AS_BUNDLE_KIND_FLATPAK;
	if (g_strcmp0 (bundle_str, "appimage") == 0)
		return AS_BUNDLE_KIND_APPIMAGE;
	if (g_strcmp0 (bundle_str, "snap") == 0)
		return AS_BUNDLE_KIND_SNAP;
	return AS_BUNDLE_KIND_UNKNOWN;
}

static void
as_bundle_finalize (GObject *object)
{
	AsBundle *bundle = AS_BUNDLE (object);
	AsBundlePrivate *priv = GET_PRIVATE (bundle);

	g_free (priv->id);

	G_OBJECT_CLASS (as_bundle_parent_class)->finalize (object);
}

static void
as_bundle_init (AsBundle *bundle)
{
}

static void
as_bundle_class_init (AsBundleClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_bundle_finalize;
}

/**
 * as_bundle_get_id:
 * @bundle: an #AsBundle instance.
 *
 * Gets the ID for this bundle.
 *
 * Returns: ID, e.g. "foobar-1.0.2"
 *
 * Since: 0.10
 **/
const gchar*
as_bundle_get_id (AsBundle *bundle)
{
	AsBundlePrivate *priv = GET_PRIVATE (bundle);
	return priv->id;
}

/**
 * as_bundle_set_id:
 * @bundle: an #AsBundle instance.
 * @id: the URL.
 *
 * Sets the ID for this bundle.
 *
 * Since: 0.10
 **/
void
as_bundle_set_id (AsBundle *bundle, const gchar *id)
{
	AsBundlePrivate *priv = GET_PRIVATE (bundle);
	g_free (priv->id);
	priv->id = g_strdup (id);
}

/**
 * as_bundle_get_kind:
 * @bundle: an #AsBundle instance.
 *
 * Gets the bundle kind.
 *
 * Returns: the #AsBundleKind
 *
 * Since: 0.10
 **/
AsBundleKind
as_bundle_get_kind (AsBundle *bundle)
{
	AsBundlePrivate *priv = GET_PRIVATE (bundle);
	return priv->kind;
}

/**
 * as_bundle_set_kind:
 * @bundle: an #AsBundle instance.
 * @kind: the #AsBundleKind, e.g. %AS_BUNDLE_KIND_LIMBA.
 *
 * Sets the bundle kind.
 *
 * Since: 0.10
 **/
void
as_bundle_set_kind (AsBundle *bundle, AsBundleKind kind)
{
	AsBundlePrivate *priv = GET_PRIVATE (bundle);
	priv->kind = kind;
}

/**
 * as_bundle_load_from_xml:
 * @bundle: a #AsBundle instance.
 * @ctx: the AppStream document context.
 * @node: the XML node.
 * @error: a #GError.
 *
 * Loads data from an XML node.
 **/
gboolean
as_bundle_load_from_xml (AsBundle *bundle, AsContext *ctx, xmlNode *node, GError **error)
{
	AsBundlePrivate *priv = GET_PRIVATE (bundle);
	g_autofree gchar *content = NULL;
	g_autofree gchar *type_str = NULL;

	content = as_xml_get_node_value (node);
	if (content == NULL)
		return FALSE;

	type_str = (gchar*) xmlGetProp (node, (xmlChar*) "type");
	priv->kind = as_bundle_kind_from_string (type_str);
	if (priv->kind == AS_BUNDLE_KIND_UNKNOWN)
		priv->kind = AS_BUNDLE_KIND_LIMBA;

	as_bundle_set_id (bundle, content);

	return TRUE;
}

/**
 * as_bundle_to_xml_node:
 * @bundle: a #AsBundle instance.
 * @ctx: the AppStream document context.
 * @root: XML node to attach the new nodes to.
 *
 * Serializes the data to an XML node.
 **/
void
as_bundle_to_xml_node (AsBundle *bundle, AsContext *ctx, xmlNode *root)
{
	AsBundlePrivate *priv = GET_PRIVATE (bundle);
	xmlNode *n;

	if (priv->id == NULL)
		return;

	n = xmlNewTextChild (root, NULL,
			     (xmlChar*) "bundle",
			     (xmlChar*) priv->id);
	xmlNewProp (n,
		    (xmlChar*) "type",
		    (xmlChar*) as_bundle_kind_to_string (priv->kind));
}

/**
 * as_bundle_load_from_yaml:
 * @bundle: a #AsBundle instance.
 * @ctx: the AppStream document context.
 * @node: the YAML node.
 * @error: a #GError.
 *
 * Loads data from a YAML field.
 **/
gboolean
as_bundle_load_from_yaml (AsBundle *bundle, AsContext *ctx, GNode *node, GError **error)
{
	AsBundlePrivate *priv = GET_PRIVATE (bundle);
	GNode *n;

	for (n = node->children; n != NULL; n = n->next) {
		const gchar *key = as_yaml_node_get_key (n);
		const gchar *value = as_yaml_node_get_value (n);

		if (g_strcmp0 (key, "type") == 0) {
			priv->kind = as_bundle_kind_from_string (value);
		} else if (g_strcmp0 (key, "id") == 0) {
			as_bundle_set_id (bundle, value);
		} else {
			as_yaml_print_unknown ("bundles", key);
		}
	}

	return TRUE;
}

/**
 * as_bundle_emit_yaml:
 * @bundle: a #AsBundle instance.
 * @ctx: the AppStream document context.
 * @emitter: The YAML emitter to emit data on.
 *
 * Emit YAML data for this object.
 **/
void
as_bundle_emit_yaml (AsBundle *bundle, AsContext *ctx, yaml_emitter_t *emitter)
{
	AsBundlePrivate *priv = GET_PRIVATE (bundle);

	/* start mapping for this bundle */
	as_yaml_mapping_start (emitter);

	/* type */
	as_yaml_emit_entry (emitter,
			    "type",
			    as_bundle_kind_to_string (priv->kind));

	/* ID */
	as_yaml_emit_entry (emitter,
			    "id",
			    priv->id);

	/* end mapping for the bundle */
	as_yaml_mapping_end (emitter);
}

/**
 * as_bundle_to_variant:
 * @bundle: a #AsBundle instance.
 * @builder: A #GVariantBuilder
 *
 * Serialize the current active state of this object to a GVariant
 * for use in the on-disk binary cache.
 */
void
as_bundle_to_variant (AsBundle *bundle, GVariantBuilder *builder)
{
	AsBundlePrivate *priv = GET_PRIVATE (bundle);
	GVariantBuilder bundle_b;

	g_variant_builder_init (&bundle_b, G_VARIANT_TYPE_ARRAY);

	g_variant_builder_add_parsed (&bundle_b, "{'type', <%u>}", priv->kind);
	g_variant_builder_add_parsed (&bundle_b, "{'id', <%s>}", priv->id);

	g_variant_builder_add_value (builder, g_variant_builder_end (&bundle_b));
}

/**
 * as_bundle_set_from_variant:
 * @bundle: a #AsBundle instance.
 * @variant: The #GVariant to read from.
 *
 * Read the active state of this object from a #GVariant serialization.
 * This is used by the on-disk binary cache.
 */
gboolean
as_bundle_set_from_variant (AsBundle *bundle, GVariant *variant)
{
	AsBundlePrivate *priv = GET_PRIVATE (bundle);
	GVariantDict tmp_dict;
	GVariant *var2;

	g_variant_dict_init (&tmp_dict, variant);
	priv->kind = as_variant_get_dict_uint32 (&tmp_dict, "type");
	as_bundle_set_id (bundle,
			    as_variant_get_dict_str (&tmp_dict, "id", &var2));
	g_variant_unref (var2);

	return TRUE;
}

/**
 * as_bundle_new:
 *
 * Creates a new #AsBundle.
 *
 * Returns: (transfer full): a #AsBundle
 *
 * Since: 0.10
 **/
AsBundle*
as_bundle_new (void)
{
	AsBundle *bundle;
	bundle = g_object_new (AS_TYPE_BUNDLE, NULL);
	return AS_BUNDLE (bundle);
}
