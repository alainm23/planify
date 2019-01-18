/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2017 Matthias Klumpp <matthias@tenstral.net>
 * Copyright (C) 2014 Richard Hughes <richard@hughsie.com>
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
 * SECTION:as-screenshot
 * @short_description: Object representing a single screenshot
 *
 * Screenshots have a localized caption and also contain a number of images
 * of different resolution.
 *
 * See also: #AsImage
 */

#include "as-screenshot.h"
#include "as-screenshot-private.h"

#include "as-utils.h"
#include "as-utils-private.h"
#include "as-image-private.h"
#include "as-variant-cache.h"

typedef struct
{
	AsScreenshotKind kind;
	GHashTable *caption;
	GPtrArray *images;
	GPtrArray *images_lang;

	AsContext *context;
	gchar *active_locale_override;
} AsScreenshotPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsScreenshot, as_screenshot, G_TYPE_OBJECT)
#define GET_PRIVATE(o) (as_screenshot_get_instance_private (o))

/**
 * as_screenshot_finalize:
 **/
static void
as_screenshot_finalize (GObject *object)
{
	AsScreenshot *screenshot = AS_SCREENSHOT (object);
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);

	g_free (priv->active_locale_override);
	g_ptr_array_unref (priv->images);
	g_ptr_array_unref (priv->images_lang);
	g_hash_table_unref (priv->caption);
	if (priv->context != NULL)
		g_object_unref (priv->context);

	G_OBJECT_CLASS (as_screenshot_parent_class)->finalize (object);
}

/**
 * as_screenshot_init:
 **/
static void
as_screenshot_init (AsScreenshot *screenshot)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);

	priv->kind = AS_SCREENSHOT_KIND_EXTRA;
	priv->caption = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);
	priv->images = g_ptr_array_new_with_free_func ((GDestroyNotify) g_object_unref);
	priv->images_lang = g_ptr_array_new_with_free_func ((GDestroyNotify) g_object_unref);
}

/**
 * as_screenshot_class_init:
 **/
static void
as_screenshot_class_init (AsScreenshotClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_screenshot_finalize;
}

/**
 * as_screenshot_kind_from_string:
 * @kind: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a %AsScreenshotKind, or %AS_SCREENSHOT_KIND_UNKNOWN if not known.
 **/
AsScreenshotKind
as_screenshot_kind_from_string (const gchar *kind)
{
	if (g_strcmp0 (kind, "default") == 0)
		return AS_SCREENSHOT_KIND_DEFAULT;
	if (g_strcmp0 (kind, "extra") == 0)
		return AS_SCREENSHOT_KIND_EXTRA;
	if ((g_strcmp0 (kind, "") == 0) || (kind == NULL))
		return AS_SCREENSHOT_KIND_EXTRA;
	return AS_SCREENSHOT_KIND_UNKNOWN;
}

/**
 * as_screenshot_kind_to_string:
 * @kind: the #AsScreenshotKind.
 *
 * Converts the enumerated value to an text representation.
 *
 * Returns: string version of @kind
 **/
const gchar *
as_screenshot_kind_to_string (AsScreenshotKind kind)
{
	if (kind == AS_SCREENSHOT_KIND_DEFAULT)
		return "default";
	if (kind == AS_SCREENSHOT_KIND_EXTRA)
		return "extra";
	return NULL;
}

/**
 * as_screenshot_get_kind:
 * @screenshot: a #AsScreenshot instance.
 *
 * Gets the screenshot kind.
 *
 * Returns: a #AsScreenshotKind
 **/
AsScreenshotKind
as_screenshot_get_kind (AsScreenshot *screenshot)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	return priv->kind;
}

/**
 * as_screenshot_set_kind:
 * @screenshot: a #AsScreenshot instance.
 * @kind: the #AsScreenshotKind.
 *
 * Sets the screenshot kind.
 **/
void
as_screenshot_set_kind (AsScreenshot *screenshot, AsScreenshotKind kind)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	priv->kind = kind;
}

/**
 * as_screenshot_get_images:
 * @screenshot: a #AsScreenshot instance.
 *
 * Gets the images for this screenshots. Only images valid for the current
 * language are returned. We return all sizes.
 *
 * Returns: (transfer none) (element-type AsImage): an array
 **/
GPtrArray*
as_screenshot_get_images (AsScreenshot *screenshot)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	if (priv->images_lang->len == 0)
		return as_screenshot_get_images_all (screenshot);
	return priv->images_lang;
}

/**
 * as_screenshot_add_image:
 * @screenshot: a #AsScreenshot instance.
 * @image: a #AsImage instance.
 *
 * Adds an image to the screenshot.
 **/
void
as_screenshot_add_image (AsScreenshot *screenshot, AsImage *image)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	g_ptr_array_add (priv->images, g_object_ref (image));

	if (as_utils_locale_is_compatible (as_image_get_locale (image), as_screenshot_get_active_locale (screenshot)))
		g_ptr_array_add (priv->images_lang, g_object_ref (image));
}

/**
 * as_screenshot_get_caption:
 * @screenshot: a #AsScreenshot instance.
 *
 * Gets the image caption
 *
 * Returns: the caption
 **/
const gchar*
as_screenshot_get_caption (AsScreenshot *screenshot)
{
	const gchar *caption;
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);

	caption = g_hash_table_lookup (priv->caption,
					as_screenshot_get_active_locale (screenshot));
	if (caption == NULL) {
		/* fall back to untranslated / default */
		caption = g_hash_table_lookup (priv->caption, "C");
	}

	return caption;
}

/**
 * as_screenshot_set_caption:
 * @screenshot: a #AsScreenshot instance.
 * @caption: the caption text.
 *
 * Sets a caption on the screenshot
 **/
void
as_screenshot_set_caption (AsScreenshot *screenshot, const gchar *caption, const gchar *locale)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);

	if (locale == NULL)
		locale = as_screenshot_get_active_locale (screenshot);

	g_hash_table_insert (priv->caption,
				as_locale_strip_encoding (g_strdup (locale)),
				g_strdup (caption));
}

/**
 * as_screenshot_is_valid:
 * @screenshot: a #AsScreenshot instance.
 *
 * Performs a quick validation on this screenshot
 *
 * Returns: TRUE if the screenshot is a complete #AsScreenshot
 **/
gboolean
as_screenshot_is_valid (AsScreenshot *screenshot)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	return priv->images->len > 0;
}

/**
 * as_screenshot_rebuild_suitable_images_list:
 * @screenshot: a #AsScreenshot instance.
 *
 * Rebuild list of images suitable for the selected locale.
 */
static void
as_screenshot_rebuild_suitable_images_list (AsScreenshot *screenshot)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	guint i;

	/* rebuild our list of images suitable for the current locale */
	g_ptr_array_unref (priv->images_lang);
	priv->images_lang = g_ptr_array_new_with_free_func ((GDestroyNotify) g_object_unref);
	for (i = 0; i < priv->images->len; i++) {
		AsImage *img = AS_IMAGE (g_ptr_array_index (priv->images, i));
		if (!as_utils_locale_is_compatible (as_image_get_locale (img), as_screenshot_get_active_locale (screenshot)))
			continue;
		g_ptr_array_add (priv->images_lang, g_object_ref (img));
	}
}

/**
 * as_screenshot_get_active_locale:
 *
 * Get the current active locale, which
 * is used to get localized messages.
 */
const gchar*
as_screenshot_get_active_locale (AsScreenshot *screenshot)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	const gchar *locale;

	/* return context locale, if the locale isn't explicitly overridden for this component */
	if ((priv->context != NULL) && (priv->active_locale_override == NULL)) {
		locale = as_context_get_locale (priv->context);
	} else {
		locale = priv->active_locale_override;
	}

	if (locale == NULL)
		return "C";
	else
		return locale;
}

/**
 * as_screenshot_set_active_locale:
 *
 * Set the current active locale, which
 * is used to get localized messages.
 * If the #AsComponent linking this #AsScreenshot was fetched
 * from a localized database, usually only
 * one locale is available.
 */
void
as_screenshot_set_active_locale (AsScreenshot *screenshot, const gchar *locale)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);

	g_free (priv->active_locale_override);
	priv->active_locale_override = g_strdup (locale);

	/* rebuild our list of images suitable for the current locale */
	as_screenshot_rebuild_suitable_images_list (screenshot);
}

/**
 * as_screenshot_get_images_all:
 * @screenshot: an #AsScreenshot instance.
 *
 * Returns an array of all images we have, regardless of their
 * size and language.
 *
 * Returns: (transfer none) (element-type AsImage): an array
 *
 * Since: 0.10
 **/
GPtrArray*
as_screenshot_get_images_all (AsScreenshot *screenshot)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	return priv->images;
}

/**
 * as_screenshot_get_context:
 * @screenshot: an #AsScreenshot instance.
 *
 * Returns: the #AsContext associated with this screenshot.
 * This function may return %NULL if no context is set.
 *
 * Since: 0.11.2
 */
AsContext*
as_screenshot_get_context (AsScreenshot *screenshot)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	return priv->context;
}

/**
 * as_screenshot_set_context:
 * @screenshot: an #AsScreenshot instance.
 * @context: the #AsContext.
 *
 * Sets the document context this screenshot is associated
 * with.
 *
 * Since: 0.11.2
 */
void
as_screenshot_set_context (AsScreenshot *screenshot, AsContext *context)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	if (priv->context != NULL)
		g_object_unref (priv->context);
	priv->context = g_object_ref (context);

	/* reset individual properties, so the new context overrides them */
	g_free (priv->active_locale_override);
	priv->active_locale_override = NULL;

	as_screenshot_rebuild_suitable_images_list (screenshot);
}

/**
 * as_screenshot_load_from_xml:
 * @screenshot: an #AsScreenshot instance.
 * @ctx: the AppStream document context.
 * @node: the XML node.
 * @error: a #GError.
 *
 * Loads data from an XML node.
 **/
gboolean
as_screenshot_load_from_xml (AsScreenshot *screenshot, AsContext *ctx, xmlNode *node, GError **error)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	xmlNode *iter;
	g_autofree gchar *prop = NULL;
	gboolean children_found = FALSE;

	prop = (gchar*) xmlGetProp (node, (xmlChar*) "type");
	if (g_strcmp0 (prop, "default") == 0)
		priv->kind = AS_SCREENSHOT_KIND_DEFAULT;
	else
		priv->kind = AS_SCREENSHOT_KIND_EXTRA;

	for (iter = node->children; iter != NULL; iter = iter->next) {
		const gchar *node_name;
		/* discard spaces */
		if (iter->type != XML_ELEMENT_NODE)
			continue;
		node_name = (const gchar*) iter->name;
		children_found = TRUE;

		if (g_strcmp0 (node_name, "image") == 0) {
			g_autoptr(AsImage) image = as_image_new ();
			if (as_image_load_from_xml (image, ctx, iter, NULL))
				as_screenshot_add_image (screenshot, image);
		} else if (g_strcmp0 (node_name, "caption") == 0) {
			g_autofree gchar *content = NULL;
			g_autofree gchar *lang = NULL;

			content = as_xml_get_node_value (iter);
			if (content == NULL)
				continue;

			lang = as_xmldata_get_node_locale (ctx, iter);
			if (lang != NULL)
				as_screenshot_set_caption (screenshot, content, lang);
		}
	}

	if (!children_found) {
		/* we are likely dealing with a legacy screenshot node, which does not have <image/> children,
		 * but instead contains the screenshot URL as text. This was briefly supported in an older AppStream
		 * version for metainfo files, but it should no longer be used.
		 * We support it here only for legacy compatibility. */
		g_autoptr(AsImage) image = as_image_new ();

		if (as_image_load_from_xml (image, ctx, node, NULL))
			as_screenshot_add_image (screenshot, image);
		else
			return FALSE; /* this screenshot is invalid */
	}

	/* propagate context - we do this last so the image list for the selected locale is rebuilt properly */
	as_screenshot_set_context (screenshot, ctx);

	return TRUE;
}

/**
 * as_screenshot_to_xml_node:
 * @screenshot: an #AsScreenshot instance.
 * @ctx: the AppStream document context.
 * @root: XML node to attach the new nodes to.
 *
 * Serializes the data to an XML node.
 **/
void
as_screenshot_to_xml_node (AsScreenshot *screenshot, AsContext *ctx, xmlNode *root)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	xmlNode *subnode;
	guint i;

	subnode = xmlNewChild (root, NULL, (xmlChar*) "screenshot", NULL);
	if (priv->kind == AS_SCREENSHOT_KIND_DEFAULT)
		xmlNewProp (subnode, (xmlChar*) "type", (xmlChar*) "default");

	as_xml_add_localized_text_node (subnode, "caption", priv->caption);

	for (i = 0; i < priv->images->len; i++) {
		AsImage *image = AS_IMAGE (g_ptr_array_index (priv->images, i));
		as_image_to_xml_node (image, ctx, subnode);
	}
}

/**
 * as_screenshot_load_from_yaml:
 * @screenshot: an #AsScreenshot instance.
 * @ctx: the AppStream document context.
 * @node: the YAML node.
 * @error: a #GError.
 *
 * Loads data from a YAML field.
 **/
gboolean
as_screenshot_load_from_yaml (AsScreenshot *screenshot, AsContext *ctx, GNode *node, GError **error)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	GNode *n;

	for (n = node->children; n != NULL; n = n->next) {
		GNode *in;
		const gchar *key = as_yaml_node_get_key (n);
		const gchar *value = as_yaml_node_get_value (n);

		if (g_strcmp0 (key, "default") == 0) {
			if (g_strcmp0 (value, "yes") == 0)
				priv->kind = AS_SCREENSHOT_KIND_DEFAULT;
			else
				priv->kind = AS_SCREENSHOT_KIND_EXTRA;
		} else if (g_strcmp0 (key, "caption") == 0) {
			/* the caption is a localized element */
			as_yaml_set_localized_table (ctx, n, priv->caption);
		} else if (g_strcmp0 (key, "source-image") == 0) {
			/* there can only be one source image */
			g_autoptr(AsImage) image = as_image_new ();
			if (as_image_load_from_yaml (image, ctx, n, AS_IMAGE_KIND_SOURCE, NULL))
				as_screenshot_add_image (screenshot, image);
		} else if (g_strcmp0 (key, "thumbnails") == 0) {
			/* the thumbnails are a list of images */
			for (in = n->children; in != NULL; in = in->next) {
				g_autoptr(AsImage) image = as_image_new ();
				if (as_image_load_from_yaml (image, ctx, in, AS_IMAGE_KIND_THUMBNAIL, NULL))
					as_screenshot_add_image (screenshot, image);
			}
		} else {
			as_yaml_print_unknown ("screenshot", key);
		}
	}

	/* propagate context - we do this last so the image list for the selected locale is rebuilt properly */
	as_screenshot_set_context (screenshot, ctx);

	return TRUE;
}

/**
 * as_screenshot_emit_yaml:
 * @screenshot: an #AsScreenshot instance.
 * @ctx: the AppStream document context.
 * @emitter: The YAML emitter to emit data on.
 *
 * Emit YAML data for this object.
 **/
void
as_screenshot_emit_yaml (AsScreenshot *screenshot, AsContext *ctx, yaml_emitter_t *emitter)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	guint i;
	AsImage *source_img = NULL;

	as_yaml_mapping_start (emitter);

	if (priv->kind == AS_SCREENSHOT_KIND_DEFAULT)
		as_yaml_emit_entry (emitter, "default", "true");

	as_yaml_emit_localized_entry (emitter, "caption", priv->caption);

	as_yaml_emit_scalar (emitter, "thumbnails");
	as_yaml_sequence_start (emitter);
	for (i = 0; i < priv->images->len; i++) {
		AsImage *img = AS_IMAGE (g_ptr_array_index (priv->images, i));

		if (as_image_get_kind (img) == AS_IMAGE_KIND_SOURCE) {
			source_img = img;
			continue;
		}

		as_image_emit_yaml (img, ctx, emitter);
	}
	as_yaml_sequence_end (emitter);

	/* we *must* have a source-image by now if the data follows the spec, but better be safe... */
	if (source_img != NULL) {
		as_yaml_emit_scalar (emitter, "source-image");
		as_image_emit_yaml (source_img, ctx, emitter);
	}

	as_yaml_mapping_end (emitter);
}

/**
 * as_screenshot_to_variant:
 * @screenshot: an #AsScreenshot instance.
 * @builder: A #GVariantBuilder
 *
 * Serialize the current active state of this object to a GVariant
 * for use in the on-disk binary cache.
 *
 * Returns: %TRUE if a screenhot was added to the @builder
 */
gboolean
as_screenshot_to_variant (AsScreenshot *screenshot, GVariantBuilder *builder)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	guint i;
	GVariantBuilder images_b;
	GVariantBuilder scr_b;

	/* do not add screenshot without images to the cache */
	if (priv->images->len == 0)
		return FALSE;

	g_variant_builder_init (&images_b, (const GVariantType *) "aa{sv}");
	for (i = 0; i < priv->images->len; i++)
		as_image_to_variant (AS_IMAGE (g_ptr_array_index (priv->images, i)), &images_b);

	g_variant_builder_init (&scr_b, G_VARIANT_TYPE_ARRAY);
	g_variant_builder_add_parsed (&scr_b, "{'type', <%u>}", priv->kind);
	g_variant_builder_add_parsed (&scr_b, "{'caption', %v}", as_variant_mstring_new (as_screenshot_get_caption (screenshot)));
	g_variant_builder_add_parsed (&scr_b, "{'images', %v}", g_variant_builder_end (&images_b));

	g_variant_builder_add_value (builder, g_variant_builder_end (&scr_b));

	return TRUE;
}

/**
 * as_screenshot_set_from_variant:
 * @screenshot: an #AsScreenshot instance.
 * @variant: The #GVariant to read from.
 *
 * Read the active state of this object from a #GVariant serialization.
 * This is used by the on-disk binary cache.
 */
gboolean
as_screenshot_set_from_variant (AsScreenshot *screenshot, GVariant *variant, const gchar *locale)
{
	AsScreenshotPrivate *priv = GET_PRIVATE (screenshot);
	GVariantIter inner_iter;
	g_auto(GVariantDict) idict;
	GVariant *tmp;
	g_autoptr(GVariant) images_var = NULL;

	as_screenshot_set_active_locale (screenshot, locale);
	g_variant_dict_init (&idict, variant);

	priv->kind = as_variant_get_dict_uint32 (&idict, "type");
	as_screenshot_set_caption (screenshot,
				   as_variant_get_dict_mstr (&idict, "caption", &tmp),
				   locale);
	g_variant_unref (tmp);

	images_var = g_variant_dict_lookup_value (&idict, "images", G_VARIANT_TYPE_ARRAY);
	if (images_var != NULL) {
		GVariant *img_child;
		g_variant_iter_init (&inner_iter, images_var);

		while ((img_child = g_variant_iter_next_value (&inner_iter))) {
			g_autoptr(AsImage) img = as_image_new ();
			if (as_image_set_from_variant (img, img_child))
				as_screenshot_add_image (screenshot, img);
			g_variant_unref (img_child);
		}
	}

	return priv->images->len != 0;
}

/**
 * as_screenshot_new:
 *
 * Creates a new #AsScreenshot.
 *
 * Returns: (transfer full): a #AsScreenshot
 **/
AsScreenshot*
as_screenshot_new (void)
{
	AsScreenshot *screenshot;
	screenshot = g_object_new (AS_TYPE_SCREENSHOT, NULL);
	return AS_SCREENSHOT (screenshot);
}
