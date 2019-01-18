/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2015 Matthias Klumpp <matthias@tenstral.net>
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
 * SECTION: as-icon
 * @short_description: Describes an icon of an application.
 * @include: appstream.h
 */

#include "config.h"

#include "as-icon-private.h"
#include "as-variant-cache.h"

typedef struct
{
	AsIconKind	kind;
	gchar		*name;
	gchar		*url;
	gchar		*filename;
	guint		width;
	guint		height;
	guint		scale;
} AsIconPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsIcon, as_icon, G_TYPE_OBJECT)
#define GET_PRIVATE(o) (as_icon_get_instance_private (o))

/**
 * as_icon_kind_to_string:
 * @kind: the %AsIconKind.
 *
 * Converts the enumerated value to an text representation.
 *
 * Returns: string version of @kind
 **/
const gchar*
as_icon_kind_to_string (AsIconKind kind)
{
	if (kind == AS_ICON_KIND_CACHED)
		return "cached";
	if (kind == AS_ICON_KIND_LOCAL)
		return "local";
	if (kind == AS_ICON_KIND_REMOTE)
		return "remote";
	if (kind == AS_ICON_KIND_STOCK)
		return "stock";
	return "unknown";
}

/**
 * as_icon_kind_from_string:
 * @kind_str: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsIconKind or %AS_ICON_KIND_UNKNOWN for unknown
 **/
AsIconKind
as_icon_kind_from_string (const gchar *kind_str)
{
	if (g_strcmp0 (kind_str, "cached") == 0)
		return AS_ICON_KIND_CACHED;
	if (g_strcmp0 (kind_str, "local") == 0)
		return AS_ICON_KIND_LOCAL;
	if (g_strcmp0 (kind_str, "remote") == 0)
		return AS_ICON_KIND_REMOTE;
	if (g_strcmp0 (kind_str, "stock") == 0)
		return AS_ICON_KIND_STOCK;
	return AS_ICON_KIND_UNKNOWN;
}

/**
 * as_icon_finalize:
 **/
static void
as_icon_finalize (GObject *object)
{
	AsIcon *icon = AS_ICON (object);
	AsIconPrivate *priv = GET_PRIVATE (icon);

	g_free (priv->name);
	g_free (priv->url);
	g_free (priv->filename);

	G_OBJECT_CLASS (as_icon_parent_class)->finalize (object);
}

/**
 * as_icon_init:
 **/
static void
as_icon_init (AsIcon *icon)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	priv->scale = 1;
}

/**
 * as_icon_class_init:
 **/
static void
as_icon_class_init (AsIconClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_icon_finalize;
}

/**
 * as_icon_get_kind:
 * @icon: a #AsIcon instance.
 *
 * Gets the icon kind.
 *
 * Returns: the #AsIconKind
 **/
AsIconKind
as_icon_get_kind (AsIcon *icon)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	return priv->kind;
}

/**
 * as_icon_set_kind:
 * @icon: a #AsIcon instance.
 * @kind: the #AsIconKind, e.g. %AS_ICON_KIND_CACHED.
 *
 * Sets the icon kind.
 **/
void
as_icon_set_kind (AsIcon *icon, AsIconKind kind)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	priv->kind = kind;
}

/**
 * as_icon_get_name:
 * @icon: a #AsIcon instance.
 *
 * Returns: the stock name of the icon. In case the icon is not of kind
 * "stock", the basename of the icon filename or URL is returned.
 **/
const gchar*
as_icon_get_name (AsIcon *icon)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);

	if (priv->name == NULL) {
		if (priv->filename != NULL)
			priv->name = g_path_get_basename (priv->filename);
		else if (priv->url != NULL)
			priv->name = g_path_get_basename (priv->url);
	}

	return priv->name;
}

/**
 * as_icon_set_name:
 * @icon: a #AsIcon instance.
 * @name: the icon stock name, e.g. "gwenview"
 *
 * Sets the stock name or basename to use for the icon.
 **/
void
as_icon_set_name (AsIcon *icon, const gchar *name)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	g_free (priv->name);
	priv->name = g_strdup (name);
}

/**
 * as_icon_get_url:
 * @icon: a #AsIcon instance.
 *
 * Gets the icon URL, pointing at a remote location. HTTPS and FTP urls are allowed.
 * This property is only set for icons of type %AS_ICON_KIND_REMOTE
 *
 * Returns: the URL
 **/
const gchar*
as_icon_get_url (AsIcon *icon)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	if (priv->url == NULL && priv->filename != NULL) {
		priv->url = g_strdup_printf ("file://%s", priv->filename);
	}

	return priv->url;
}

/**
 * as_icon_set_url:
 * @icon: a #AsIcon instance.
 * @url: the new icon URL.
 *
 * Sets the icon URL.
 **/
void
as_icon_set_url (AsIcon *icon, const gchar *url)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	g_free (priv->url);
	priv->url = g_strdup (url);
}

/**
 * as_icon_get_filename:
 * @icon: a #AsIcon instance.
 *
 * Returns: The absolute path for the icon on disk.
 * This is only set for icons of kind %AS_ICON_KIND_LOCAL or
 * %AS_ICON_KIND_CACHED.
 **/
const gchar*
as_icon_get_filename (AsIcon *icon)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	return priv->filename;
}

/**
 * as_icon_set_filename:
 * @icon: a #AsIcon instance.
 * @filename: the new icon URL.
 *
 * Sets the icon absolute filename.
 **/
void
as_icon_set_filename (AsIcon *icon, const gchar *filename)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	g_free (priv->filename);
	priv->filename = g_strdup (filename);

	/* invalidate URL */
	if (priv->url != NULL) {
		g_free (priv->url);
		priv->url = NULL;
	}
}

/**
 * as_icon_get_width:
 * @icon: a #AsIcon instance.
 *
 * Returns: The icon width in pixels, or 0 if unknown.
 **/
guint
as_icon_get_width (AsIcon *icon)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	return priv->width;
}

/**
 * as_icon_set_width:
 * @icon: a #AsIcon instance.
 * @width: the width in pixels.
 *
 * Sets the icon width.
 **/
void
as_icon_set_width (AsIcon *icon, guint width)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	priv->width = width;
}

/**
 * as_icon_get_height:
 * @icon: a #AsIcon instance.
 *
 * Returns: The icon height in pixels, or 0 if unknown.
 **/
guint
as_icon_get_height (AsIcon *icon)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	return priv->height;
}

/**
 * as_icon_set_height:
 * @icon: a #AsIcon instance.
 * @height: the height in pixels.
 *
 * Sets the icon height.
 **/
void
as_icon_set_height (AsIcon *icon, guint height)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	priv->height = height;
}

/**
 * as_icon_get_scale:
 * @icon: a #AsIcon instance.
 *
 * Returns: The icon scaling factor.
 *
 * Since: 0.11.0
 **/
guint
as_icon_get_scale (AsIcon *icon)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	return priv->scale;
}

/**
 * as_icon_set_scale:
 * @icon: a #AsIcon instance.
 * @scale: the icon scaling factor.
 *
 * Sets the icon scaling factor used for HiDPI displays.
 *
 * Since: 0.11.0
 **/
void
as_icon_set_scale (AsIcon *icon, guint scale)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	priv->scale = scale;
}

/**
 * as_xml_icon_set_size_from_node:
 */
static void
as_xml_icon_set_size_from_node (xmlNode *node, AsIcon *icon)
{
	gchar *val;

	val = (gchar*) xmlGetProp (node, (xmlChar*) "width");
	if (val != NULL) {
		as_icon_set_width (icon, g_ascii_strtoll (val, NULL, 10));
		g_free (val);
	}
	val = (gchar*) xmlGetProp (node, (xmlChar*) "height");
	if (val != NULL) {
		as_icon_set_height (icon, g_ascii_strtoll (val, NULL, 10));
		g_free (val);
	}
	val = (gchar*) xmlGetProp (node, (xmlChar*) "scale");
	if (val != NULL) {
		as_icon_set_scale (icon, g_ascii_strtoll (val, NULL, 10));
		g_free (val);
	}
}

/**
 * as_icon_load_from_xml:
 * @icon: an #AsIcon
 * @ctx: the AppStream document context.
 * @node: the XML node.
 * @error: a #GError.
 *
 * Loads data from an XML node.
 **/
gboolean
as_icon_load_from_xml (AsIcon *icon, AsContext *ctx, xmlNode *node, GError **error)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	g_autofree gchar *type_str = NULL;
	g_autofree gchar *content = NULL;

	content = as_xml_get_node_value (node);
	if (content == NULL)
		return FALSE;

	type_str = (gchar*) xmlGetProp (node, (xmlChar*) "type");

	if (g_strcmp0 (type_str, "stock") == 0) {
		priv->kind = AS_ICON_KIND_STOCK;
		as_icon_set_name (icon, content);
	} else if (g_strcmp0 (type_str, "cached") == 0) {
		priv->kind = AS_ICON_KIND_CACHED;
		as_icon_set_filename (icon, content);
		as_xml_icon_set_size_from_node (node, icon);
	} else if (g_strcmp0 (type_str, "local") == 0) {
		priv->kind = AS_ICON_KIND_LOCAL;
		as_icon_set_filename (icon, content);
		as_xml_icon_set_size_from_node (node, icon);
	} else if (g_strcmp0 (type_str, "remote") == 0) {
		priv->kind = AS_ICON_KIND_REMOTE;
		if (!as_context_has_media_baseurl (ctx)) {
			/* no baseurl, we can just set the value as URL */
			as_icon_set_url (icon, content);
		} else {
			/* handle the media baseurl */
			g_free (priv->url);
			priv->url = g_build_filename (as_context_get_media_baseurl (ctx), content, NULL);
		}
		as_xml_icon_set_size_from_node (node, icon);
	}

	return TRUE;
}

/**
 * as_icon_to_xml_node:
 * @icon: an #AsIcon
 * @ctx: the AppStream document context.
 * @root: XML node to attach the new nodes to.
 *
 * Serializes the data to an XML node.
 **/
void
as_icon_to_xml_node (AsIcon *icon, AsContext *ctx, xmlNode *root)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	xmlNode *n;
	const gchar *value;

	if (priv->kind == AS_ICON_KIND_LOCAL)
		value = as_icon_get_filename (icon);
	else if (priv->kind == AS_ICON_KIND_REMOTE)
		value = as_icon_get_url (icon);
	else
		value = as_icon_get_name (icon);

	if (value == NULL)
		return;

	n = xmlNewTextChild (root, NULL, (xmlChar*) "icon", (xmlChar*) value);
	xmlNewProp (n, (xmlChar*) "type",
			(xmlChar*) as_icon_kind_to_string (priv->kind));

	if (priv->kind != AS_ICON_KIND_STOCK) {
		if (priv->width > 0) {
			g_autofree gchar *size = NULL;
			size = g_strdup_printf ("%i", as_icon_get_width (icon));
			xmlNewProp (n, (xmlChar*) "width", (xmlChar*) size);
		}

		if (priv->height > 0) {
			g_autofree gchar *size = NULL;
			size = g_strdup_printf ("%i", as_icon_get_height (icon));
			xmlNewProp (n, (xmlChar*) "height", (xmlChar*) size);
		}

		if (priv->scale > 1) {
			g_autofree gchar *scale = NULL;
			scale = g_strdup_printf ("%i", as_icon_get_scale (icon));
			xmlNewProp (n, (xmlChar*) "scale", (xmlChar*) scale);
		}
	}
}

/**
 * as_icon_to_variant:
 * @icon: an #AsIcon
 * @builder: A #GVariantBuilder
 *
 * Serialize the current active state of this object to a GVariant
 * for use in the on-disk binary cache.
 */
void
as_icon_to_variant (AsIcon *icon, GVariantBuilder *builder)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	GVariantBuilder icon_b;

	g_variant_builder_init (&icon_b, G_VARIANT_TYPE_ARRAY);
	g_variant_builder_add_parsed (&icon_b, "{'type', <%u>}", priv->kind);
	g_variant_builder_add_parsed (&icon_b, "{'width', <%i>}", priv->width);
	g_variant_builder_add_parsed (&icon_b, "{'height', <%i>}", priv->height);
	g_variant_builder_add_parsed (&icon_b, "{'scale', <%i>}", priv->scale);

	if (priv->kind == AS_ICON_KIND_STOCK) {
		g_variant_builder_add_parsed (&icon_b, "{'name', <%s>}", priv->name);
	} else if (priv->kind == AS_ICON_KIND_REMOTE) {
		g_variant_builder_add_parsed (&icon_b, "{'url', <%s>}", priv->url);
	} else {
		/* cached or local icon */
		g_variant_builder_add_parsed (&icon_b, "{'filename', <%s>}", priv->filename);
	}

	g_variant_builder_add_value (builder, g_variant_builder_end (&icon_b));
}

/**
 * as_icon_set_from_variant:
 * @icon: an #AsIcon
 * @variant: The #GVariant to read from.
 *
 * Read the active state of this object from a #GVariant serialization.
 * This is used by the on-disk binary cache.
 */
gboolean
as_icon_set_from_variant (AsIcon *icon, GVariant *variant)
{
	AsIconPrivate *priv = GET_PRIVATE (icon);
	g_auto(GVariantDict) idict;
	g_autoptr(GVariant) ival_var = NULL;

	g_variant_dict_init (&idict, variant);

	priv->kind = as_variant_get_dict_uint32 (&idict, "type");

	priv->width = as_variant_get_dict_int32 (&idict, "width");
	priv->height = as_variant_get_dict_int32 (&idict, "height");
	priv->scale = as_variant_get_dict_int32 (&idict, "scale");

	if (priv->kind == AS_ICON_KIND_STOCK) {
		as_icon_set_name (icon,
				  as_variant_get_dict_str (&idict, "name", &ival_var));
	} else if (priv->kind == AS_ICON_KIND_REMOTE) {
		as_icon_set_url (icon,
				  as_variant_get_dict_str (&idict, "url", &ival_var));
	} else {
		/* cached or local icon */
		as_icon_set_filename (icon,
					as_variant_get_dict_str (&idict, "filename", &ival_var));
	}

	return TRUE;
}

/**
 * as_icon_new:
 *
 * Creates a new #AsIcon.
 *
 * Returns: (transfer full): a #AsIcon
 **/
AsIcon*
as_icon_new (void)
{
	AsIcon *icon;
	icon = g_object_new (AS_TYPE_ICON, NULL);
	return AS_ICON (icon);
}
