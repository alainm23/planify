/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2018 Richard Hughes <richard@hughsie.com>
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

/**
 * SECTION:as-agreement
 * @short_description: Object representing a privacy policy
 * @include: appstream-glib.h
 * @stability: Unstable
 *
 * Agreements can be used by components to specify GDPR, EULA or other warnings.
 *
 * See also: #AsAgreementSection
 */

#include "config.h"

#include "as-agreement-private.h"
#include "as-agreement-section-private.h"

typedef struct {
	AsAgreementKind		kind;
	gchar			*version_id;
	GPtrArray		*sections;

	AsContext		*context;
} AsAgreementPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsAgreement, as_agreement, G_TYPE_OBJECT)

#define GET_PRIVATE(o) (as_agreement_get_instance_private (o))

static void
as_agreement_finalize (GObject *object)
{
	AsAgreement *agreement = AS_AGREEMENT (object);
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);

	g_free (priv->version_id);
	g_ptr_array_unref (priv->sections);

	if (priv->context != NULL)
		g_object_unref (priv->context);

	G_OBJECT_CLASS (as_agreement_parent_class)->finalize (object);
}

static void
as_agreement_init (AsAgreement *agreement)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	priv->sections = g_ptr_array_new_with_free_func ((GDestroyNotify) g_object_unref);
}

static void
as_agreement_class_init (AsAgreementClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_agreement_finalize;
}

/**
 * as_agreement_kind_to_string:
 * @value: the #AsAgreementKind.
 *
 * Converts the enumerated value to an text representation.
 *
 * Returns: string version of @value
 *
 * Since: 0.12.1
 **/
const gchar*
as_agreement_kind_to_string (AsAgreementKind value)
{
	if (value == AS_AGREEMENT_KIND_GENERIC)
		return "generic";
	if (value == AS_AGREEMENT_KIND_EULA)
		return "eula";
	if (value == AS_AGREEMENT_KIND_PRIVACY)
		return "privacy";
	return "unknown";
}

/**
 * as_agreement_kind_from_string:
 * @value: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsAgreementKind or %AS_AGREEMENT_KIND_UNKNOWN for unknown
 *
 * Since: 0.12.1
 **/
AsAgreementKind
as_agreement_kind_from_string (const gchar *value)
{
	if (value == NULL || g_strcmp0 (value, "") == 0)
		return AS_AGREEMENT_KIND_GENERIC;
	if (g_strcmp0 (value, "generic") == 0)
		return AS_AGREEMENT_KIND_GENERIC;
	if (g_strcmp0 (value, "eula") == 0)
		return AS_AGREEMENT_KIND_EULA;
	if (g_strcmp0 (value, "privacy") == 0)
		return AS_AGREEMENT_KIND_PRIVACY;
	return AS_AGREEMENT_KIND_UNKNOWN;
}

/**
 * as_agreement_get_kind:
 * @agreement: a #AsAgreement instance.
 *
 * Gets the agreement kind.
 *
 * Returns: a string, e.g. %AS_AGREEMENT_KIND_EULA
 *
 * Since: 0.12.1
 **/
AsAgreementKind
as_agreement_get_kind (AsAgreement *agreement)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	return priv->kind;
}

/**
 * as_agreement_set_kind:
 * @agreement: a #AsAgreement instance.
 * @kind: the agreement kind, e.g. %AS_AGREEMENT_KIND_EULA
 *
 * Sets the agreement kind.
 *
 * Since: 0.12.1
 **/
void
as_agreement_set_kind (AsAgreement *agreement, AsAgreementKind kind)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	priv->kind = kind;
}

/**
 * as_agreement_get_version_id:
 * @agreement: a #AsAgreement instance.
 *
 * Gets the agreement version_id.
 *
 * Returns: a string, e.g. "1.4a", or NULL
 *
 * Since: 0.12.1
 **/
const gchar*
as_agreement_get_version_id (AsAgreement *agreement)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	return priv->version_id;
}

/**
 * as_agreement_set_version_id:
 * @agreement: a #AsAgreement instance.
 * @version_id: the agreement version ID, e.g. "1.4a"
 *
 * Sets the agreement version identifier.
 *
 * Since: 0.12.1
 **/
void
as_agreement_set_version_id (AsAgreement *agreement, const gchar *version_id)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);

	g_free (priv->version_id);
	priv->version_id = g_strdup (version_id);
}

/**
 * as_agreement_get_sections:
 * @agreement: a #AsAgreement instance.
 *
 * Gets all the sections in the agreement.
 *
 * Returns: (transfer container) (element-type AsAgreementSection): array
 *
 * Since: 0.12.1
 **/
GPtrArray*
as_agreement_get_sections (AsAgreement *agreement)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	return priv->sections;
}

/**
 * as_agreement_get_section_default:
 * @agreement: a #AsAgreement instance.
 *
 * Gets the first section in the agreement.
 *
 * Returns: (transfer none) (nullable): agreement section, or %NULL
 *
 * Since: 0.12.1
 **/
AsAgreementSection *
as_agreement_get_section_default (AsAgreement *agreement)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	if (priv->sections->len == 0)
		return NULL;
	return AS_AGREEMENT_SECTION (g_ptr_array_index (priv->sections, 0));
}

/**
 * as_agreement_add_detail:
 * @agreement: a #AsAgreement instance.
 * @agreement_section: a #AsAgreementSection instance.
 *
 * Adds a section to the agreement.
 *
 * Since: 0.12.1
 **/
void
as_agreement_add_section (AsAgreement *agreement, AsAgreementSection *agreement_section)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	g_ptr_array_add (priv->sections, g_object_ref (agreement_section));
}

/**
 * as_agreement_get_context:
 * @agreement: An instance of #AsAgreement.
 *
 * Returns: the #AsContext associated with this agreement.
 * This function may return %NULL if no context is set.
 *
 * Since: 0.12.1
 */
AsContext*
as_agreement_get_context (AsAgreement *agreement)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	return priv->context;
}

/**
 * as_agreement_set_context:
 * @agreement: An instance of #AsAgreement.
 * @context: the #AsContext.
 *
 * Sets the document context this agreement is associated
 * with.
 *
 * Since: 0.12.1
 */
void
as_agreement_set_context (AsAgreement *agreement, AsContext *context)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	if (priv->context != NULL)
		g_object_unref (priv->context);
	priv->context = g_object_ref (context);
}

/**
 * as_agreement_load_from_xml:
 * @agreement: an #AsAgreement
 * @ctx: the AppStream document context.
 * @node: the XML node.
 * @error: a #GError.
 *
 * Loads data from an XML node.
 **/
gboolean
as_agreement_load_from_xml (AsAgreement *agreement, AsContext *ctx, xmlNode *node, GError **error)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	xmlNode *iter;
	gchar *prop;

	/* propagate context */
	as_agreement_set_context (agreement, ctx);

	prop = (gchar*) xmlGetProp (node, (xmlChar*) "type");
	if (prop != NULL) {
		priv->kind = as_agreement_kind_from_string (prop);
		g_free (prop);
	}

	prop = (gchar*) xmlGetProp (node, (xmlChar*) "version_id");
	if (prop != NULL) {
		as_agreement_set_version_id (agreement, prop);
		g_free (prop);
	}

	/* read agreement sections */
	for (iter = node->children; iter != NULL; iter = iter->next) {
		if (iter->type != XML_ELEMENT_NODE)
			continue;

		if (g_strcmp0 ((gchar*) iter->name, "agreement_section") == 0) {
			g_autoptr(AsAgreementSection) asection = as_agreement_section_new ();

			if (!as_agreement_section_load_from_xml (asection, priv->context, iter, error))
				return FALSE;
			as_agreement_add_section (agreement, asection);
		}
	}

	return TRUE;
}

/**
 * as_agreement_to_xml_node:
 * @agreement: an #AsAgreement
 * @ctx: the AppStream document context.
 * @root: XML node to attach the new nodes to.
 *
 * Serializes the data to an XML node.
 **/
void
as_agreement_to_xml_node (AsAgreement *agreement, AsContext *ctx, xmlNode *root)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	xmlNode *agnode;
	guint i;

	agnode = xmlNewChild (root, NULL, (xmlChar*) "agreement", (xmlChar*) "");
	xmlNewProp (agnode, (xmlChar*) "type",
		    (xmlChar*) as_agreement_kind_to_string (priv->kind));
	xmlNewProp (agnode, (xmlChar*) "version_id", (xmlChar*) priv->version_id);

	for (i = 0; i < priv->sections->len; i++) {
		AsAgreementSection *agsec = AS_AGREEMENT_SECTION (g_ptr_array_index (priv->sections, i));
		as_agreement_section_to_xml_node (agsec, ctx, agnode);
	}
}

/**
 * as_agreement_load_from_yaml:
 * @agreement: an #AsAgreement
 * @ctx: the AppStream document context.
 * @node: the YAML node.
 * @error: a #GError.
 *
 * Loads data from a YAML field.
 **/
gboolean
as_agreement_load_from_yaml (AsAgreement *agreement, AsContext *ctx, GNode *node, GError **error)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	GNode *n;

	/* propagate context */
	as_agreement_set_context (agreement, ctx);

	for (n = node->children; n != NULL; n = n->next) {
		const gchar *key = as_yaml_node_get_key (n);
		const gchar *value = as_yaml_node_get_value (n);

		if (g_strcmp0 (key, "type") == 0) {
			priv->kind = as_agreement_kind_from_string (value);
		} else if (g_strcmp0 (key, "version_id") == 0) {
			as_agreement_set_version_id (agreement, value);
		} else if (g_strcmp0 (key, "sections") == 0) {
			GNode *sn;

			for (sn = n->children; sn != NULL; sn = sn->next) {
				g_autoptr(AsAgreementSection) asec = as_agreement_section_new ();

				if (!as_agreement_section_load_from_yaml (asec, ctx, sn, error))
					return FALSE;
				as_agreement_add_section (agreement, asec);
			}
		} else {
			as_yaml_print_unknown ("agreement", key);
		}
	}

	return TRUE;
}

/**
 * as_agreement_emit_yaml:
 * @agreement: an #AsAgreement
 * @ctx: the AppStream document context.
 * @emitter: The YAML emitter to emit data on.
 *
 * Emit YAML data for this object.
 **/
void
as_agreement_emit_yaml (AsAgreement *agreement, AsContext *ctx, yaml_emitter_t *emitter)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);

	/* start mapping for this agreement */
	as_yaml_mapping_start (emitter);

	/* type */
	as_yaml_emit_entry (emitter, "type", as_agreement_kind_to_string (priv->kind));

	/* version */
	as_yaml_emit_entry (emitter, "version_id", priv->version_id);



	as_yaml_emit_scalar (emitter, "sections");
	as_yaml_sequence_start (emitter);
	for (guint i = 0; i < priv->sections->len; i++) {
		AsAgreementSection *asec = AS_AGREEMENT_SECTION (g_ptr_array_index (priv->sections, i));
		as_agreement_section_emit_yaml (asec, ctx, emitter);
	}
	as_yaml_sequence_end (emitter);

	/* end mapping for the agreement */
	as_yaml_mapping_end (emitter);
}

/**
 * as_agreement_to_variant:
 * @agreement: an #AsAgreement
 * @builder: A #GVariantBuilder
 *
 * Serialize the current active state of this object to a GVariant
 * for use in the on-disk binary cache.
 */
void
as_agreement_to_variant (AsAgreement *agreement, GVariantBuilder *builder)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	GVariantBuilder sections_b;
	GVariantBuilder agreement_b;

	g_variant_builder_init (&agreement_b, G_VARIANT_TYPE_ARRAY);
	g_variant_builder_add_parsed (&agreement_b, "{'kind', <%u>}", priv->kind);
	g_variant_builder_add_parsed (&agreement_b, "{'version_id', %v}", as_variant_mstring_new (priv->version_id));

	g_variant_builder_init (&sections_b, (const GVariantType *) "aa{sv}");
	for (guint i = 0; i < priv->sections->len; i++) {
		as_agreement_section_to_variant (AS_AGREEMENT_SECTION (g_ptr_array_index (priv->sections, i)), &sections_b);
	}

	as_variant_builder_add_kv (&agreement_b, "sections", g_variant_builder_end (&sections_b));
	g_variant_builder_add_value (builder, g_variant_builder_end (&agreement_b));
}

/**
 * as_agreement_set_from_variant:
 * @agreement: an #AsAgreement
 * @variant: The #GVariant to read from.
 *
 * Read the active state of this object from a #GVariant serialization.
 * This is used by the on-disk binary cache.
 */
gboolean
as_agreement_set_from_variant (AsAgreement *agreement, GVariant *variant, const gchar *locale)
{
	AsAgreementPrivate *priv = GET_PRIVATE (agreement);
	GVariant *tmp;
	GVariantDict adict;

	g_variant_dict_init (&adict, variant);

	priv->kind = as_variant_get_dict_uint32 (&adict, "kind");

	as_agreement_set_version_id (agreement, as_variant_get_dict_mstr (&adict, "version_id", &tmp));
	g_variant_unref (tmp);

	/* sizes */
	tmp = g_variant_dict_lookup_value (&adict, "sections", G_VARIANT_TYPE_ARRAY);
	if (tmp != NULL) {
		GVariant *inner_child;
		GVariantIter siter;

		g_variant_iter_init (&siter, tmp);
		while ((inner_child = g_variant_iter_next_value (&siter))) {
			g_autoptr(AsAgreementSection) asec = as_agreement_section_new ();

			if (!as_agreement_section_set_from_variant (asec, inner_child, locale))
				return FALSE;
			as_agreement_add_section (agreement, asec);

			g_variant_unref (inner_child);
		}
		g_variant_unref (tmp);
	}

	return TRUE;
}

/**
 * as_agreement_new:
 *
 * Creates a new #AsAgreement.
 *
 * Returns: (transfer full): a #AsAgreement
 *
 * Since: 0.12.1
 **/
AsAgreement*
as_agreement_new (void)
{
	AsAgreement *agreement;
	agreement = g_object_new (AS_TYPE_AGREEMENT, NULL);
	return AS_AGREEMENT (agreement);
}
