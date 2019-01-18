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
 * SECTION:as-checksum
 * @short_description: A single checksum used in a release.
 * @include: appstream.h
 *
 * A checksum for a file referenced in a release.
 *
 * See also: #AsRelease
 */

#include "config.h"
#include "as-checksum-private.h"

typedef struct
{
	AsChecksumKind		 kind;
	gchar			*value;
} AsChecksumPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsChecksum, as_checksum, G_TYPE_OBJECT)

#define GET_PRIVATE(o) (as_checksum_get_instance_private (o))

/**
 * as_checksum_kind_to_string:
 * @kind: the %AsChecksumKind.
 *
 * Converts the enumerated value to an text representation.
 *
 * Returns: string version of @kind
 **/
const gchar*
as_checksum_kind_to_string (AsChecksumKind kind)
{
	if (kind == AS_CHECKSUM_KIND_NONE)
		return "none";
	if (kind == AS_CHECKSUM_KIND_SHA1)
		return "sha1";
	if (kind == AS_CHECKSUM_KIND_SHA256)
		return "sha256";
	return "unknown";
}

/**
 * as_checksum_kind_from_string:
 * @kind_str: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsChecksumKind or %AS_CHECKSUM_KIND_NONE for unknown
 **/
AsChecksumKind
as_checksum_kind_from_string (const gchar *kind_str)
{
	if (g_strcmp0 (kind_str, "none") == 0)
		return AS_CHECKSUM_KIND_NONE;
	if (g_strcmp0 (kind_str, "sha1") == 0)
		return AS_CHECKSUM_KIND_SHA1;
	if (g_strcmp0 (kind_str, "sha256") == 0)
		return AS_CHECKSUM_KIND_SHA256;
	return AS_CHECKSUM_KIND_NONE;
}

static void
as_checksum_finalize (GObject *object)
{
	AsChecksum *cs = AS_CHECKSUM (object);
	AsChecksumPrivate *priv = GET_PRIVATE (cs);

	g_free (priv->value);

	G_OBJECT_CLASS (as_checksum_parent_class)->finalize (object);
}

static void
as_checksum_init (AsChecksum *cs)
{
	AsChecksumPrivate *priv = GET_PRIVATE (cs);
	priv->kind = AS_CHECKSUM_KIND_NONE;
}

static void
as_checksum_class_init (AsChecksumClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_checksum_finalize;
}

/**
 * as_checksum_get_kind:
 * @cs: a #AsChecksum instance.
 *
 * Gets the checksum type.
 *
 * Returns: the #AsChecksumKind
 **/
AsChecksumKind
as_checksum_get_kind (AsChecksum *cs)
{
	AsChecksumPrivate *priv = GET_PRIVATE (cs);
	return priv->kind;
}

/**
 * as_checksum_set_kind:
 * @cs: a #AsChecksum instance.
 * @kind: the #AsChecksumKind, e.g. %AS_CHECKSUM_KIND_SHA256.
 *
 * Sets the checksum type.
 **/
void
as_checksum_set_kind (AsChecksum *cs, AsChecksumKind kind)
{
	AsChecksumPrivate *priv = GET_PRIVATE (cs);
	priv->kind = kind;
}

/**
 * as_checksum_get_value:
 * @cs: a #AsChecksum instance.
 *
 * Gets the checksum, usually in its hexadecimal form.
 *
 * Returns: the checksum.
 **/
const gchar*
as_checksum_get_value (AsChecksum *cs)
{
	AsChecksumPrivate *priv = GET_PRIVATE (cs);
	return priv->value;
}

/**
 * as_checksum_set_value:
 * @cs: a #AsChecksum instance.
 * @value: the new value.
 *
 * Sets the checksum value filename.
 **/
void
as_checksum_set_value (AsChecksum *cs, const gchar *value)
{
	AsChecksumPrivate *priv = GET_PRIVATE (cs);
	g_free (priv->value);
	priv->value = g_strdup (value);
}

/**
 * as_checksum_load_from_xml:
 * @cs: a #AsChecksum instance.
 * @ctx: the AppStream document context.
 * @node: the XML node.
 * @error: a #GError.
 *
 * Loads data from an XML node.
 **/
gboolean
as_checksum_load_from_xml (AsChecksum *cs, AsContext *ctx, xmlNode *node, GError **error)
{
	AsChecksumPrivate *priv = GET_PRIVATE (cs);
	g_autofree gchar *prop = NULL;
	g_autofree gchar *content = NULL;

	prop = (gchar*) xmlGetProp (node, (xmlChar*) "type");
	priv->kind = as_checksum_kind_from_string (prop);
	if (priv->kind == AS_CHECKSUM_KIND_NONE)
		return FALSE;

	content = as_xml_get_node_value (node);
	as_checksum_set_value (cs, content);

	return TRUE;
}

/**
 * as_checksum_to_xml_node:
 * @cs: a #AsChecksum instance.
 * @ctx: the AppStream document context.
 * @root: XML node to attach the new nodes to.
 *
 * Serializes the data to an XML node.
 **/
void
as_checksum_to_xml_node (AsChecksum *cs, AsContext *ctx, xmlNode *root)
{
	AsChecksumPrivate *priv = GET_PRIVATE (cs);
	xmlNode *n;

	if (priv->kind == AS_CHECKSUM_KIND_NONE)
		return;

	n = xmlNewTextChild (root, NULL,
			     (xmlChar*) "checksum",
			     (xmlChar*) priv->value);
	xmlNewProp (n,
		    (xmlChar*) "type",
		    (xmlChar*) as_checksum_kind_to_string (priv->kind));
}

/**
 * as_checksum_load_from_yaml:
 * @cs: a #AsChecksum instance.
 * @ctx: the AppStream document context.
 * @node: the YAML node.
 * @error: a #GError.
 *
 * Loads data from a YAML field.
 **/
gboolean
as_checksum_load_from_yaml (AsChecksum *cs, AsContext *ctx, GNode *node, GError **error)
{
	AsChecksumPrivate *priv = GET_PRIVATE (cs);
	const gchar *key = as_yaml_node_get_key (node);
	const gchar *value = as_yaml_node_get_value (node);

	priv->kind = as_checksum_kind_from_string (key);
	if (priv->kind == AS_CHECKSUM_KIND_NONE)
		return FALSE;

	as_checksum_set_value (cs, value);

	return TRUE;
}

/**
 * as_checksum_emit_yaml:
 * @cs: a #AsChecksum instance.
 * @ctx: the AppStream document context.
 * @emitter: The YAML emitter to emit data on.
 *
 * Emit YAML data for this object.
 **/
void
as_checksum_emit_yaml (AsChecksum *cs, AsContext *ctx, yaml_emitter_t *emitter)
{
	AsChecksumPrivate *priv = GET_PRIVATE (cs);
	if (priv->kind == AS_CHECKSUM_KIND_NONE)
		return;

	as_yaml_emit_entry (emitter, as_checksum_kind_to_string (priv->kind), priv->value);
}

/**
 * as_checksum_to_variant:
 * @cs: a #AsChecksum instance.
 * @builder: A #GVariantBuilder
 *
 * Serialize the current active state of this object to a GVariant
 * for use in the on-disk binary cache.
 */
void
as_checksum_to_variant (AsChecksum *cs, GVariantBuilder *builder)
{
	AsChecksumPrivate *priv = GET_PRIVATE (cs);

	g_variant_builder_add (builder, "{us}", priv->kind, priv->value);
}

/**
 * as_checksum_set_from_variant:
 * @cs: a #AsChecksum instance.
 * @variant: The #GVariant to read from.
 *
 * Read the active state of this object from a #GVariant serialization.
 * This is used by the on-disk binary cache.
 */
gboolean
as_checksum_set_from_variant (AsChecksum *cs, GVariant *variant)
{
	AsChecksumPrivate *priv = GET_PRIVATE (cs);

	g_free (priv->value);
	priv->value = NULL;
	g_variant_get (variant, "{us}", &priv->kind, &priv->value);

	return TRUE;
}

/**
 * as_checksum_new:
 *
 * Creates a new #AsChecksum.
 *
 * Returns: (transfer full): an #AsChecksum
 **/
AsChecksum*
as_checksum_new (void)
{
	AsChecksum *cs;
	cs = g_object_new (AS_TYPE_CHECKSUM, NULL);
	return AS_CHECKSUM (cs);
}
