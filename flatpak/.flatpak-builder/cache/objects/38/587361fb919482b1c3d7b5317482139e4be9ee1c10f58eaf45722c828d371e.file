/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2014 Richard Hughes <richard@hughsie.com>
 * Copyright (C) 2014-2016 Matthias Klumpp <matthias@tenstral.net>
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
 * SECTION:as-image
 * @short_description: Object representing a single image used in a screenshot.
 *
 * Screenshot may have multiple versions of an image in different resolutions
 * or aspect ratios. This object allows access to the location and size of a
 * single image.
 *
 * See also: #AsScreenshot
 */

#include "config.h"
#include "as-image.h"
#include "as-image-private.h"
#include "as-variant-cache.h"

typedef struct
{
	AsImageKind	kind;
	gchar		*url;
	guint		width;
	guint		height;
	gchar		*locale;
} AsImagePrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsImage, as_image, G_TYPE_OBJECT)
#define GET_PRIVATE(o) (as_image_get_instance_private (o))

/**
 * as_image_finalize:
 **/
static void
as_image_finalize (GObject *object)
{
	AsImage *image = AS_IMAGE (object);
	AsImagePrivate *priv = GET_PRIVATE (image);

	g_free (priv->url);
	g_free (priv->locale);

	G_OBJECT_CLASS (as_image_parent_class)->finalize (object);
}

/**
 * as_image_init:
 **/
static void
as_image_init (AsImage *image)
{
}

/**
 * as_image_kind_from_string:
 * @kind: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: (transfer full): a #AsImageKind, or %AS_IMAGE_KIND_UNKNOWN for unknown.
 *
 **/
AsImageKind
as_image_kind_from_string (const gchar *kind)
{
	if (g_strcmp0 (kind, "source") == 0)
		return AS_IMAGE_KIND_SOURCE;
	if (g_strcmp0 (kind, "thumbnail") == 0)
		return AS_IMAGE_KIND_THUMBNAIL;
	return AS_IMAGE_KIND_UNKNOWN;
}

/**
 * as_image_kind_to_string:
 * @kind: the #AsImageKind.
 *
 * Converts the enumerated value to an text representation.
 *
 * Returns: string version of @kind
 *
 **/
const gchar *
as_image_kind_to_string (AsImageKind kind)
{
	if (kind == AS_IMAGE_KIND_SOURCE)
		return "source";
	if (kind == AS_IMAGE_KIND_THUMBNAIL)
		return "thumbnail";
	return NULL;
}

/**
 * as_image_set_kind:
 * @image: a #AsImage instance.
 * @kind: the #AsImageKind, e.g. %AS_IMAGE_KIND_THUMBNAIL.
 *
 * Sets the image kind.
 *
 **/
void
as_image_set_kind (AsImage *image, AsImageKind kind)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	priv->kind = kind;
}

/**
 * as_image_get_kind:
 * @image: a #AsImage instance.
 *
 * Gets the image kind.
 *
 * Returns: the #AsImageKind
 *
 **/
AsImageKind
as_image_get_kind (AsImage *image)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	return priv->kind;
}

/**
 * as_image_get_url:
 * @image: a #AsImage instance.
 *
 * Gets the full qualified URL for the image, usually pointing at some mirror.
 *
 * Returns: URL
 *
 **/
const gchar*
as_image_get_url (AsImage *image)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	return priv->url;
}

/**
 * as_image_set_url:
 * @image: a #AsImage instance.
 * @url: the URL.
 *
 * Sets the fully-qualified mirror URL to use for the image.
 *
 **/
void
as_image_set_url (AsImage *image, const gchar *url)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	g_free (priv->url);
	priv->url = g_strdup (url);
}

/**
 * as_image_get_width:
 * @image: a #AsImage instance.
 *
 * Gets the image width.
 *
 * Returns: width in pixels
 *
 **/
guint
as_image_get_width (AsImage *image)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	return priv->width;
}

/**
 * as_image_set_width:
 * @image: a #AsImage instance.
 * @width: the width in pixels.
 *
 * Sets the image width.
 *
 **/
void
as_image_set_width (AsImage *image, guint width)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	priv->width = width;
}

/**
 * as_image_get_height:
 * @image: a #AsImage instance.
 *
 * Gets the image height.
 *
 * Returns: height in pixels
 *
 **/
guint
as_image_get_height (AsImage *image)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	return priv->height;
}

/**
 * as_image_set_height:
 * @image: a #AsImage instance.
 * @height: the height in pixels.
 *
 * Sets the image height.
 *
 **/
void
as_image_set_height (AsImage *image, guint height)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	priv->height = height;
}

/**
 * as_image_get_locale:
 * @image: a #AsImage instance.
 *
 * Get locale for this image.
 *
 * Returns: Locale string
 *
 * Since: 0.9.5
 **/
const gchar*
as_image_get_locale (AsImage *image)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	return priv->locale;
}

/**
 * as_image_set_locale:
 * @image: a #AsImage instance.
 * @locale: the locale string.
 *
 * Sets the locale for this image.
 *
 * Since: 0.9.5
 **/
void
as_image_set_locale (AsImage *image, const gchar *locale)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	g_free (priv->locale);
	priv->locale = g_strdup (locale);
}

/**
 * as_image_load_from_xml:
 * @image: a #AsImage instance.
 * @ctx: the AppStream document context.
 * @node: the XML node.
 * @error: a #GError.
 *
 * Loads image data from an XML node.
 **/
gboolean
as_image_load_from_xml (AsImage *image, AsContext *ctx, xmlNode *node, GError **error)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	g_autofree gchar *content = NULL;
	g_autofree gchar *stype = NULL;
	g_autofree gchar *lang = NULL;
	gchar *str;

	content = as_xml_get_node_value (node);
	if (content == NULL)
		return FALSE;

	lang = as_xmldata_get_node_locale (ctx, node);

	/* check if this image is for us */
	if (lang == NULL)
		return FALSE;
	as_image_set_locale (image, lang);

	str = (gchar*) xmlGetProp (node, (xmlChar*) "width");
	if (str == NULL) {
		priv->width = 0;
	} else {
		priv->width = g_ascii_strtoll (str, NULL, 10);
		g_free (str);
	}

	str = (gchar*) xmlGetProp (node, (xmlChar*) "height");
	if (str == NULL) {
		priv->height = 0;
	} else {
		priv->height = g_ascii_strtoll (str, NULL, 10);
		g_free (str);
	}

	stype = (gchar*) xmlGetProp (node, (xmlChar*) "type");
	if (g_strcmp0 (stype, "thumbnail") == 0)
		priv->kind = AS_IMAGE_KIND_THUMBNAIL;
	else
		priv->kind = AS_IMAGE_KIND_SOURCE;

	/* discard invalid elements */
	if (as_context_get_style (ctx) == AS_FORMAT_STYLE_COLLECTION) {
		/* no sizes are okay for upstream XML, but not for distro XML */
		if ((priv->width == 0) || (priv->height == 0)) {
			if (priv->kind != AS_IMAGE_KIND_SOURCE) {
				/* thumbnails w/o size information must never happen */
				g_set_error_literal (error,
						     AS_METADATA_ERROR,
						     AS_METADATA_ERROR_VALUE_MISSING,
						     "Ignored screenshot thumbnail image without size information.");
				return FALSE;
			}
		}
	}

	if (!as_context_has_media_baseurl (ctx)) {
		/* no baseurl, we can just set the value as URL */
		as_image_set_url (image, content);
	} else {
		/* handle the media baseurl */
		g_free (priv->url);
		priv->url = g_build_filename (as_context_get_media_baseurl (ctx), content, NULL);
	}

	return TRUE;
}

/**
 * as_image_to_xml_node:
 * @image: a #AsImage instance.
 * @ctx: the AppStream document context.
 * @root: XML node to attach the new nodes to.
 *
 * Serializes the data to an XML node.
 **/
void
as_image_to_xml_node (AsImage *image, AsContext *ctx, xmlNode *root)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	xmlNode* n_image = NULL;

	n_image = xmlNewTextChild (root, NULL,
				   (xmlChar*) "image",
				   (xmlChar*) priv->url);

	if (priv->kind == AS_IMAGE_KIND_THUMBNAIL)
		xmlNewProp (n_image, (xmlChar*) "type", (xmlChar*) "thumbnail");
	else
		xmlNewProp (n_image, (xmlChar*) "type", (xmlChar*) "source");

	if ((priv->width > 0) && (priv->height > 0)) {
		gchar *size;

		size = g_strdup_printf("%i", priv->width);
		xmlNewProp (n_image, (xmlChar*) "width", (xmlChar*) size);
		g_free (size);

		size = g_strdup_printf("%i", priv->height);
		xmlNewProp (n_image, (xmlChar*) "height", (xmlChar*) size);
		g_free (size);
	}

	if ((priv->locale != NULL) && (g_strcmp0 (priv->locale, "C") != 0)) {
		xmlNewProp (n_image, (xmlChar*) "xml:lang", (xmlChar*) priv->locale);
	}

	xmlAddChild (root, n_image);
}

/**
 * as_image_load_from_yaml:
 * @image: a #AsImage instance.
 * @ctx: the AppStream document context.
 * @node: the YAML node.
 * @error: a #GError.
 *
 * Loads data from a YAML field.
 **/
gboolean
as_image_load_from_yaml (AsImage *image, AsContext *ctx, GNode *node, AsImageKind kind, GError **error)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	GNode *n;

	priv->kind = kind;
	for (n = node->children; n != NULL; n = n->next) {
		const gchar *key = as_yaml_node_get_key (n);
		const gchar *value = as_yaml_node_get_value (n);

		if (value == NULL)
			continue; /* there should be no key without value */

		if (g_strcmp0 (key, "width") == 0) {
			priv->width = g_ascii_strtoll (value, NULL, 10);
		} else if (g_strcmp0 (key, "height") == 0) {
			priv->height = g_ascii_strtoll (value, NULL, 10);
		} else if (g_strcmp0 (key, "url") == 0) {
			if (as_context_has_media_baseurl (ctx)) {
				/* handle the media baseurl */
				g_free (priv->url);
				priv->url = g_build_filename (as_context_get_media_baseurl (ctx), value, NULL);
			} else {
				/* no baseurl, we can just set the value as URL */
				as_image_set_url (image, value);
			}
		} else if (g_strcmp0 (key, "lang") == 0) {
			as_image_set_locale (image, value);
		} else {
			as_yaml_print_unknown ("image", key);
		}
	}

	return TRUE;
}

/**
 * as_image_emit_yaml:
 * @image: a #AsImage instance.
 * @ctx: the AppStream document context.
 * @emitter: The YAML emitter to emit data on.
 *
 * Emit YAML data for this object.
 **/
void
as_image_emit_yaml (AsImage *image, AsContext *ctx, yaml_emitter_t *emitter)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	g_autofree gchar *url = NULL;

	as_yaml_mapping_start (emitter);
	if (as_context_has_media_baseurl (ctx)) {
		if (g_str_has_prefix (priv->url, as_context_get_media_baseurl (ctx)))
			url = g_strdup (priv->url + strlen (as_context_get_media_baseurl (ctx)));
		else
			url = g_strdup (priv->url);
	} else {
		url = g_strdup (priv->url);
	}
	g_strstrip (url);

	as_yaml_emit_entry (emitter, "url", url);
	if ((priv->width > 0) && (priv->height > 0)) {
		as_yaml_emit_entry_uint (emitter,
					 "width",
					 priv->width);

		as_yaml_emit_entry_uint (emitter,
					 "height",
					 priv->height);
	}
	as_yaml_emit_entry (emitter, "lang", priv->locale);
	as_yaml_mapping_end (emitter);
}

/**
 * as_image_to_variant:
 * @image: An #AsImage instance.
 * @builder: A #GVariantBuilder
 *
 * Serialize the current active state of this object to a GVariant
 * for use in the on-disk binary cache.
 */
void
as_image_to_variant (AsImage *image, GVariantBuilder *builder)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	GVariantBuilder image_b;

	g_variant_builder_init (&image_b, G_VARIANT_TYPE_ARRAY);

	g_variant_builder_add_parsed (&image_b, "{'type', <%u>}", priv->kind);
	g_variant_builder_add_parsed (&image_b, "{'url', <%s>}", priv->url);
	g_variant_builder_add_parsed (&image_b, "{'width', <%i>}", priv->width);
	g_variant_builder_add_parsed (&image_b, "{'height', <%i>}", priv->height);
	g_variant_builder_add_parsed (&image_b, "{'locale', %v}", as_variant_mstring_new (priv->locale));

	g_variant_builder_add_value (builder, g_variant_builder_end (&image_b));
}

/**
 * as_image_set_from_variant:
 * @image: An #AsImage instance.
 * @variant: The #GVariant to read from.
 *
 * Read the active state of this object from a #GVariant serialization.
 * This is used by the on-disk binary cache.
 */
gboolean
as_image_set_from_variant (AsImage *image, GVariant *variant)
{
	AsImagePrivate *priv = GET_PRIVATE (image);
	g_auto(GVariantDict) dict;
	GVariant *tmp;

	g_variant_dict_init (&dict, variant);

	/* kind */
	priv->kind = as_variant_get_dict_uint32 (&dict, "type");

	/* locale */
	as_image_set_locale (image, as_variant_get_dict_mstr (&dict, "locale", &tmp));
	g_variant_unref (tmp);

	/* url */
	as_image_set_url (image, as_variant_get_dict_str (&dict, "url", &tmp));
	g_variant_unref (tmp);

	/* sizes */
	priv->width = as_variant_get_dict_int32 (&dict, "width");
	priv->height = as_variant_get_dict_int32 (&dict, "height");

	return TRUE;
}

/**
 * as_image_class_init:
 **/
static void
as_image_class_init (AsImageClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_image_finalize;
}

/**
 * as_image_new:
 *
 * Creates a new #AsImage.
 *
 * Returns: (transfer full): a #AsImage
 *
 **/
AsImage*
as_image_new (void)
{
	AsImage *image;
	image = g_object_new (AS_TYPE_IMAGE, NULL);
	return AS_IMAGE (image);
}
