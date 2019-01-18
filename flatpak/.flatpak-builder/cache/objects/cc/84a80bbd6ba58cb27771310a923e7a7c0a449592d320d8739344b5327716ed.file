/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016-2017 Matthias Klumpp <matthias@tenstral.net>
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

#include "as-translation.h"
#include "as-translation-private.h"

#include <config.h>
#include <glib.h>

/**
 * SECTION:as-translation
 * @short_description: Description of translation domains for an upstream component.
 * @include: appstream.h
 *
 * Describes the translation domain and translation system used by the upstream component.
 * See [the specification](https://www.freedesktop.org/software/appstream/docs/chap-Metadata.html#tag-translation) for
 * more information on the corresponding XML tag.
 *
 * See also: #AsComponent
 */

typedef struct
{
	AsTranslationKind	kind;
	gchar			*id;
} AsTranslationPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsTranslation, as_translation, G_TYPE_OBJECT)
#define GET_PRIVATE(o) (as_translation_get_instance_private (o))

/**
 * as_translation_kind_to_string:
 * @kind: the #AsTranslationKind.
 *
 * Converts the enumerated value to a text representation.
 *
 * Returns: string version of @kind
 **/
const gchar*
as_translation_kind_to_string (AsTranslationKind kind)
{
	if (kind == AS_TRANSLATION_KIND_GETTEXT)
		return "gettext";
	if (kind == AS_TRANSLATION_KIND_QT)
		return "qt";
	return "unknown";
}

/**
 * as_translation_kind_from_string:
 * @kind_str: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsTranslationKind or %AS_TRANSLATION_KIND_UNKNOWN for unknown
 **/
AsTranslationKind
as_translation_kind_from_string (const gchar *kind_str)
{
	if (g_strcmp0 (kind_str, "gettext") == 0)
		return AS_TRANSLATION_KIND_GETTEXT;
	if (g_strcmp0 (kind_str, "qt") == 0)
		return AS_TRANSLATION_KIND_QT;
	return AS_TRANSLATION_KIND_UNKNOWN;
}

/**
 * as_translation_init:
 **/
static void
as_translation_init (AsTranslation *tr)
{
	AsTranslationPrivate *priv = GET_PRIVATE (tr);
	priv->kind = AS_TRANSLATION_KIND_UNKNOWN;
}

/**
 * as_translation_finalize:
 **/
static void
as_translation_finalize (GObject *object)
{
	G_OBJECT_CLASS (as_translation_parent_class)->finalize (object);
}

/**
 * as_translation_class_init:
 **/
static void
as_translation_class_init (AsTranslationClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_translation_finalize;
}

/**
 * as_translation_get_kind:
 * @tr: a #AsTranslation instance.
 *
 * The translation system type.
 *
 * Returns: an enum of type #AsTranslationKind
 */
AsTranslationKind
as_translation_get_kind (AsTranslation *tr)
{
	AsTranslationPrivate *priv = GET_PRIVATE (tr);
	return priv->kind;
}

/**
 * as_translation_set_kind:
 * @tr: a #AsTranslation instance.
 * @kind: the new #AsTranslationKind
 *
 * Set the translation system type.
 */
void
as_translation_set_kind (AsTranslation *tr, AsTranslationKind kind)
{
	AsTranslationPrivate *priv = GET_PRIVATE (tr);
	priv->kind = kind;
}

/**
 * as_translation_get_id:
 * @tr: a #AsTranslation instance.
 *
 * The ID (e.g. Gettext translation domain) of this translation.
 */
const gchar*
as_translation_get_id (AsTranslation *tr)
{
	AsTranslationPrivate *priv = GET_PRIVATE (tr);
	return priv->id;
}

/**
 * as_translation_set_id:
 * @tr: a #AsTranslation instance.
 * @id: The ID of this translation.
 *
 * Set the ID (e.g. Gettext domain) of this translation.
 */
void
as_translation_set_id (AsTranslation *tr, const gchar *id)
{
	AsTranslationPrivate *priv = GET_PRIVATE (tr);
	g_free (priv->id);
	priv->id = g_strdup (id);
}

/**
 * as_translation_load_from_xml:
 * @tr: a #AsTranslation instance.
 * @ctx: the AppStream document context.
 * @node: the XML node.
 * @error: a #GError.
 *
 * Loads data from an XML node.
 **/
gboolean
as_translation_load_from_xml (AsTranslation *tr, AsContext *ctx, xmlNode *node, GError **error)
{
	AsTranslationPrivate *priv = GET_PRIVATE (tr);
	g_autofree gchar *prop = NULL;
	g_autofree gchar *content = NULL;

	prop = (gchar*) xmlGetProp (node, (xmlChar*) "type");
	priv->kind = as_translation_kind_from_string (prop);
	if (priv->kind == AS_TRANSLATION_KIND_UNKNOWN)
		return FALSE;

	content = as_xml_get_node_value (node);
	as_translation_set_id (tr, content);

	return TRUE;
}

/**
 * as_translation_to_xml_node:
 * @tr: a #AsTranslation instance.
 * @ctx: the AppStream document context.
 * @root: XML node to attach the new nodes to.
 *
 * Serializes the data to an XML node.
 **/
void
as_translation_to_xml_node (AsTranslation *tr, AsContext *ctx, xmlNode *root)
{
	AsTranslationPrivate *priv = GET_PRIVATE (tr);
	xmlNode *n;

	/* the translations tag is only valid in metainfo files */
	if (as_context_get_style (ctx) != AS_FORMAT_STYLE_METAINFO)
		return;

	n = xmlNewTextChild (root, NULL, (xmlChar*) "translation", (xmlChar*) priv->id);
	xmlNewProp (n, (xmlChar*) "type",
			(xmlChar*) as_translation_kind_to_string (priv->kind));
}

/**
 * as_translation_new:
 *
 * Creates a new #AsTranslation.
 *
 * Returns: (transfer full): a #AsTranslation
 **/
AsTranslation*
as_translation_new (void)
{
	AsTranslation *tr;
	tr = g_object_new (AS_TYPE_TRANSLATION, NULL);
	return AS_TRANSLATION (tr);
}
