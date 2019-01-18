/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
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

#include "as-launchable-private.h"

#include <config.h>
#include <glib/gi18n-lib.h>
#include <glib.h>

#include "as-variant-cache.h"

/**
 * SECTION:as-launchable
 * @short_description: Description of launchable entries for a software component
 * @include: appstream.h
 *
 * Components can provide multiple launch-entries to launch the software they belong to.
 * This class describes them.
 *
 * See also: #AsComponent
 */

typedef struct
{
	AsLaunchableKind	kind;
	GPtrArray		*entries;
} AsLaunchablePrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsLaunchable, as_launchable, G_TYPE_OBJECT)

#define GET_PRIVATE(o) (as_launchable_get_instance_private (o))

/**
 * as_launchable_kind_to_string:
 * @kind: the #AsLaunchableKind.
 *
 * Converts the enumerated value to a text representation.
 *
 * Returns: string version of @kind
 *
 * Since: 0.11.0
 **/
const gchar*
as_launchable_kind_to_string (AsLaunchableKind kind)
{
	if (kind == AS_LAUNCHABLE_KIND_DESKTOP_ID)
		return "desktop-id";
	if (kind == AS_LAUNCHABLE_KIND_SERVICE)
		return "service";
	if (kind == AS_LAUNCHABLE_KIND_COCKPIT_MANIFEST)
		return "cockpit-manifest";
	if (kind == AS_LAUNCHABLE_KIND_URL)
		return "url";
	return "unknown";
}

/**
 * as_launchable_kind_from_string:
 * @kind_str: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsLaunchableKind or %AS_LAUNCHABLE_KIND_UNKNOWN for unknown
 *
 * Since: 0.11.0
 **/
AsLaunchableKind
as_launchable_kind_from_string (const gchar *kind_str)
{
	if (g_strcmp0 (kind_str, "desktop-id") == 0)
		return AS_LAUNCHABLE_KIND_DESKTOP_ID;
	if (g_strcmp0 (kind_str, "service") == 0)
		return AS_LAUNCHABLE_KIND_SERVICE;
	if (g_strcmp0 (kind_str, "cockpit-manifest") == 0)
		return AS_LAUNCHABLE_KIND_COCKPIT_MANIFEST;
	if (g_strcmp0 (kind_str, "url") == 0)
		return AS_LAUNCHABLE_KIND_URL;
	return AS_LAUNCHABLE_KIND_UNKNOWN;
}

/**
 * as_launchable_finalize:
 **/
static void
as_launchable_finalize (GObject *object)
{
	AsLaunchable *launch = AS_LAUNCHABLE (object);
	AsLaunchablePrivate *priv = GET_PRIVATE (launch);

	g_ptr_array_unref (priv->entries);

	G_OBJECT_CLASS (as_launchable_parent_class)->finalize (object);
}

/**
 * as_launchable_init:
 **/
static void
as_launchable_init (AsLaunchable *launch)
{
	AsLaunchablePrivate *priv = GET_PRIVATE (launch);

	priv->kind = AS_LAUNCHABLE_KIND_UNKNOWN;
	priv->entries = g_ptr_array_new_with_free_func (g_free);
}

/**
 * as_launchable_class_init:
 **/
static void
as_launchable_class_init (AsLaunchableClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_launchable_finalize;
}

/**
 * as_launchable_get_kind:
 * @launch: a #AsLaunchable instance.
 *
 * The launch system for the entries this #AsLaunchable
 * object stores.
 *
 * Returns: an enum of type #AsLaunchableKind
 *
 * Since: 0.11.0
 */
AsLaunchableKind
as_launchable_get_kind (AsLaunchable *launch)
{
	AsLaunchablePrivate *priv = GET_PRIVATE (launch);
	return priv->kind;
}

/**
 * as_launchable_set_kind:
 * @launch: a #AsLaunchable instance.
 * @kind: the new #AsLaunchableKind
 *
 * Set the launch system for the entries this #AsLaunchable
 * object stores.
 *
 * Since: 0.11.0
 */
void
as_launchable_set_kind (AsLaunchable *launch, AsLaunchableKind kind)
{
	AsLaunchablePrivate *priv = GET_PRIVATE (launch);
	priv->kind = kind;
}

/**
 * as_launchable_get_entries:
 * @launch: a #AsLaunchable instance.
 *
 * Get an array of launchable entries.
 *
 * Returns: (transfer none) (element-type utf8): An string list of launch entries.
 *
 * Since: 0.11.0
 */
GPtrArray*
as_launchable_get_entries (AsLaunchable *launch)
{
	AsLaunchablePrivate *priv = GET_PRIVATE (launch);
	return priv->entries;
}

/**
 * as_launchable_add_entry:
 * @launch: a #AsLaunchable instance.
 *
 * Add a new launchable entry.
 *
 * Since: 0.11.0
 */
void
as_launchable_add_entry (AsLaunchable *launch, const gchar *entry)
{
	AsLaunchablePrivate *priv = GET_PRIVATE (launch);
	g_ptr_array_add (priv->entries, g_strdup (entry));
}

/**
 * as_launchable_to_xml_node:
 * @launchable: an #AsLaunchable
 * @ctx: the AppStream document context.
 * @root: XML node to attach the new nodes to.
 *
 * Serializes the data to an XML node.
 **/
void
as_launchable_to_xml_node (AsLaunchable *launchable, AsContext *ctx, xmlNode *root)
{
	AsLaunchablePrivate *priv = GET_PRIVATE (launchable);
	guint i;

	for (i = 0; i < priv->entries->len; i++) {
		xmlNode *n;
		const gchar *entry = g_ptr_array_index (priv->entries, i);
		if (entry == NULL)
			continue;

		n = xmlNewTextChild (root, NULL,
				     (xmlChar*) "launchable",
				     (xmlChar*) entry);
		xmlNewProp (n, (xmlChar*) "type",
			    (xmlChar*) as_launchable_kind_to_string (priv->kind));
	}
}

/**
 * as_launchable_load_from_yaml:
 * @launchable: an #AsLaunchable
 * @ctx: the AppStream document context.
 * @node: the YAML node.
 * @error: a #GError.
 *
 * Loads data from a YAML field.
 **/
gboolean
as_launchable_load_from_yaml (AsLaunchable *launch, AsContext *ctx, GNode *node, GError **error)
{
	AsLaunchablePrivate *priv = GET_PRIVATE (launch);
	GNode *n;

	priv->kind = as_launchable_kind_from_string (as_yaml_node_get_key (node));
	for (n = node->children; n != NULL; n = n->next) {
		const gchar *entry = as_yaml_node_get_key (n);
		if (entry == NULL)
			continue;
		as_launchable_add_entry (launch, entry);
	}

	return TRUE;
}

/**
 * as_launchable_emit_yaml:
 * @launchable: an #AsLaunchable
 * @ctx: the AppStream document context.
 * @emitter: The YAML emitter to emit data on.
 *
 * Emit YAML data for this object.
 **/
void
as_launchable_emit_yaml (AsLaunchable *launch, AsContext *ctx, yaml_emitter_t *emitter)
{
	AsLaunchablePrivate *priv = GET_PRIVATE (launch);

	as_yaml_emit_sequence (emitter,
			       as_launchable_kind_to_string (priv->kind),
			       priv->entries);
}

/**
 * as_launchable_to_variant:
 * @launchable: an #AsLaunchable
 * @builder: A #GVariantBuilder
 *
 * Serialize the current active state of this object to a GVariant
 * for use in the on-disk binary cache.
 */
void
as_launchable_to_variant (AsLaunchable *launch, GVariantBuilder *builder)
{
	AsLaunchablePrivate *priv = GET_PRIVATE (launch);

	GVariant *var = g_variant_new ("{uv}", priv->kind, as_variant_from_string_ptrarray (priv->entries));
	g_variant_builder_add_value (builder, var);
}

/**
 * as_launchable_set_from_variant:
 * @launchable: an #AsLaunchable
 * @variant: The #GVariant to read from.
 *
 * Read the active state of this object from a #GVariant serialization.
 * This is used by the on-disk binary cache.
 */
gboolean
as_launchable_set_from_variant (AsLaunchable *launch, GVariant *variant)
{
	AsLaunchablePrivate *priv = GET_PRIVATE (launch);
	GVariantIter inner_iter;
	GVariant *entry_child;
	g_autoptr(GVariant) entries_var = NULL;

	g_variant_get (variant, "{uv}", &priv->kind, &entries_var);

	g_variant_iter_init (&inner_iter, entries_var);
	while ((entry_child = g_variant_iter_next_value (&inner_iter))) {
		as_launchable_add_entry (launch, g_variant_get_string (entry_child, NULL));
		g_variant_unref (entry_child);
	}

	return TRUE;
}

/**
 * as_launchable_new:
 *
 * Creates a new #AsLaunchable.
 *
 * Returns: (transfer full): a #AsLaunchable
 *
 * Since: 0.11.0
 **/
AsLaunchable*
as_launchable_new (void)
{
	AsLaunchable *launch;
	launch = g_object_new (AS_TYPE_LAUNCHABLE, NULL);
	return AS_LAUNCHABLE (launch);
}
