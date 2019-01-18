/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2014-2017 Matthias Klumpp <matthias@tenstral.net>
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

#include "as-provided.h"
#include "as-provided-private.h"

#include <config.h>
#include <glib/gi18n-lib.h>
#include <glib.h>
#include <fnmatch.h>

#include "as-utils.h"
#include "as-variant-cache.h"

/**
 * SECTION:as-provided
 * @short_description: Description of the provided-items in components
 * @include: appstream.h
 *
 * Components can provide various items, like libraries, Python-modules,
 * firmware, binaries, etc.
 * Functions to work with these items are provided here.
 *
 * See also: #AsComponent
 */

typedef struct
{
	AsProvidedKind	kind;
	GPtrArray	*items;
} AsProvidedPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsProvided, as_provided, G_TYPE_OBJECT)

#define GET_PRIVATE(o) (as_provided_get_instance_private (o))

/**
 * as_provided_kind_to_string:
 * @kind: the #AsProvidedKind.
 *
 * Converts the enumerated value to a text representation.
 *
 * Returns: string version of @kind
 **/
const gchar*
as_provided_kind_to_string (AsProvidedKind kind)
{
	if (kind == AS_PROVIDED_KIND_LIBRARY)
		return "lib";
	if (kind == AS_PROVIDED_KIND_BINARY)
		return "bin";
	if (kind == AS_PROVIDED_KIND_MIMETYPE)
		return "mimetype";
	if (kind == AS_PROVIDED_KIND_FONT)
		return "font";
	if (kind == AS_PROVIDED_KIND_MODALIAS)
		return "modalias";
	if (kind == AS_PROVIDED_KIND_PYTHON_2)
		return "python2";
	if (kind == AS_PROVIDED_KIND_PYTHON)
		return "python";
	if (kind == AS_PROVIDED_KIND_DBUS_SYSTEM)
		return "dbus:system";
	if (kind == AS_PROVIDED_KIND_DBUS_USER)
		return "dbus:user";
	if (kind == AS_PROVIDED_KIND_FIRMWARE_RUNTIME)
		return "firmware:runtime";
	if (kind == AS_PROVIDED_KIND_FIRMWARE_FLASHED)
		return "firmware:flashed";
	if (kind == AS_PROVIDED_KIND_ID)
		return "id";
	return "unknown";
}

/**
 * as_provided_kind_from_string:
 * @kind_str: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsProvidedKind or %AS_PROVIDED_KIND_UNKNOWN for unknown
 **/
AsProvidedKind
as_provided_kind_from_string (const gchar *kind_str)
{
	if (g_strcmp0 (kind_str, "lib") == 0)
		return AS_PROVIDED_KIND_LIBRARY;
	if (g_strcmp0 (kind_str, "bin") == 0)
		return AS_PROVIDED_KIND_BINARY;
	if (g_strcmp0 (kind_str, "mimetype") == 0)
		return AS_PROVIDED_KIND_MIMETYPE;
	if (g_strcmp0 (kind_str, "font") == 0)
		return AS_PROVIDED_KIND_FONT;
	if (g_strcmp0 (kind_str, "modalias") == 0)
		return AS_PROVIDED_KIND_MODALIAS;
	if (g_strcmp0 (kind_str, "python2") == 0)
		return AS_PROVIDED_KIND_PYTHON_2;
	if (g_strcmp0 (kind_str, "python") == 0)
		return AS_PROVIDED_KIND_PYTHON;
	if (g_strcmp0 (kind_str, "dbus:system") == 0)
		return AS_PROVIDED_KIND_DBUS_SYSTEM;
	if (g_strcmp0 (kind_str, "dbus:user") == 0)
		return AS_PROVIDED_KIND_DBUS_USER;
	if (g_strcmp0 (kind_str, "firmware:runtime") == 0)
		return AS_PROVIDED_KIND_FIRMWARE_RUNTIME;
	if (g_strcmp0 (kind_str, "firmware:flashed") == 0)
		return AS_PROVIDED_KIND_FIRMWARE_FLASHED;
	if (g_strcmp0 (kind_str, "id") == 0)
		return AS_PROVIDED_KIND_ID;
	return AS_PROVIDED_KIND_UNKNOWN;
}

/**
 * as_provided_kind_to_l10n_string:
 * @kind: the #AsProvidedKind.
 *
 * Converts the enumerated value to a localized text representation,
 * using the plural forms (e.g. "Libraries" instead of "Library").
 *
 * This can be useful when displaying provided items in GUI dialogs.
 *
 * Returns: Pluralized, l10n string version of @kind
 **/
const gchar*
as_provided_kind_to_l10n_string (AsProvidedKind kind)
{
	if (kind == AS_PROVIDED_KIND_LIBRARY)
		return _("Libraries");
	if (kind == AS_PROVIDED_KIND_BINARY)
		return _("Binaries");
	if (kind == AS_PROVIDED_KIND_MIMETYPE)
		return _("MIME types");
	if (kind == AS_PROVIDED_KIND_FONT)
		return _("Fonts");
	if (kind == AS_PROVIDED_KIND_MODALIAS)
		return _("Modaliases");
	if (kind == AS_PROVIDED_KIND_PYTHON_2)
		return _("Python (Version 2)");
	if (kind == AS_PROVIDED_KIND_PYTHON)
		return _("Python 3");
	if (kind == AS_PROVIDED_KIND_DBUS_SYSTEM)
		return _("DBus System Services");
	if (kind == AS_PROVIDED_KIND_DBUS_USER)
		return _("DBus Session Services");
	if (kind == AS_PROVIDED_KIND_FIRMWARE_RUNTIME)
		return _("Runtime Firmware");
	if (kind == AS_PROVIDED_KIND_FIRMWARE_FLASHED)
		return _("Flashed Firmware");
	if (kind == AS_PROVIDED_KIND_ID)
		return _("Component");
	return as_provided_kind_to_string (kind);
}

/**
 * as_provided_finalize:
 **/
static void
as_provided_finalize (GObject *object)
{
	AsProvided *prov = AS_PROVIDED (object);
	AsProvidedPrivate *priv = GET_PRIVATE (prov);

	g_ptr_array_unref (priv->items);

	G_OBJECT_CLASS (as_provided_parent_class)->finalize (object);
}

/**
 * as_provided_init:
 **/
static void
as_provided_init (AsProvided *prov)
{
	AsProvidedPrivate *priv = GET_PRIVATE (prov);

	priv->kind = AS_PROVIDED_KIND_UNKNOWN;
	priv->items = g_ptr_array_new_with_free_func (g_free);
}

/**
 * as_provided_class_init:
 **/
static void
as_provided_class_init (AsProvidedClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_provided_finalize;
}

/**
 * as_provided_get_kind:
 * @prov: a #AsProvided instance.
 *
 * The kind of items this #AsProvided object stores.
 *
 * Returns: an enum of type #AsProvidedKind
 */
AsProvidedKind
as_provided_get_kind (AsProvided *prov)
{
	AsProvidedPrivate *priv = GET_PRIVATE (prov);
	return priv->kind;
}

/**
 * as_provided_set_kind:
 * @prov: a #AsProvided instance.
 * @kind: the new #AsProvidedKind
 *
 * Set the kind of items this #AsProvided object stores.
 */
void
as_provided_set_kind (AsProvided *prov, AsProvidedKind kind)
{
	AsProvidedPrivate *priv = GET_PRIVATE (prov);
	priv->kind = kind;
}

/**
 * as_provided_has_item:
 * @prov: a #AsProvided instance.
 * @item: the name of a provided item, e.g. "audio/x-vorbis" (in case the provided kind is a mimetype)
 *
 * Check if the current #AsProvided contains an item
 * of the given name.
 *
 * Returns: %TRUE if found.
 */
gboolean
as_provided_has_item (AsProvided *prov, const gchar *item)
{
	AsProvidedPrivate *priv = GET_PRIVATE (prov);
	guint i;

	for (i = 0; i < priv->items->len; i++) {
		const gchar *pitem = (const gchar*) g_ptr_array_index (priv->items, i);
		if (g_strcmp0 (pitem, item) == 0)
			return TRUE;

		/* modalias entries may provide wildcards, we match them by default */
		if (priv->kind == AS_PROVIDED_KIND_MODALIAS) {
			if (fnmatch (pitem, item, FNM_NOESCAPE) == 0)
				return TRUE;
		}
	}

	return FALSE;
}

/**
 * as_provided_get_items:
 * @prov: a #AsProvided instance.
 *
 * Get an array of provided data.
 *
 * Returns: (transfer none) (element-type utf8): An string list of provided items.
 */
GPtrArray*
as_provided_get_items (AsProvided *prov)
{
	AsProvidedPrivate *priv = GET_PRIVATE (prov);
	return priv->items;
}

/**
 * as_provided_add_item:
 * @prov: a #AsProvided instance.
 *
 * Add a new provided item.
 */
void
as_provided_add_item (AsProvided *prov, const gchar *item)
{
	AsProvidedPrivate *priv = GET_PRIVATE (prov);
	g_ptr_array_add (priv->items, g_strdup (item));
}

/**
 * as_provided_to_variant:
 * @prov: a #AsProvided instance.
 * @builder: A #GVariantBuilder
 *
 * Serialize the current active state of this object to a GVariant
 * for use in the on-disk binary cache.
 */
void
as_provided_to_variant (AsProvided *prov, GVariantBuilder *builder)
{
	AsProvidedPrivate *priv = GET_PRIVATE (prov);
	GVariant *prov_var;

	prov_var = g_variant_new ("{uv}",
				  priv->kind,
				  as_variant_from_string_ptrarray (priv->items));
	g_variant_builder_add_value (builder, prov_var);
}

/**
 * as_provided_set_from_variant:
 * @prov: a #AsProvided instance.
 * @variant: The #GVariant to read from.
 *
 * Read the active state of this object from a #GVariant serialization.
 * This is used by the on-disk binary cache.
 */
gboolean
as_provided_set_from_variant (AsProvided *prov, GVariant *variant)
{
	AsProvidedPrivate *priv = GET_PRIVATE (prov);
	GVariantIter inner_iter;
	GVariant *item_child;
	g_autoptr(GVariant) items_var = NULL;

	g_variant_get (variant, "{uv}", &priv->kind, &items_var);

	g_variant_iter_init (&inner_iter, items_var);
	while ((item_child = g_variant_iter_next_value (&inner_iter))) {
		as_provided_add_item (prov, g_variant_get_string (item_child, NULL));
		g_variant_unref (item_child);
	}

	return TRUE;
}

/**
 * as_provided_new:
 *
 * Creates a new #AsProvided.
 *
 * Returns: (transfer full): a #AsProvided
 **/
AsProvided*
as_provided_new (void)
{
	AsProvided *prov;
	prov = g_object_new (AS_TYPE_PROVIDED, NULL);
	return AS_PROVIDED (prov);
}
