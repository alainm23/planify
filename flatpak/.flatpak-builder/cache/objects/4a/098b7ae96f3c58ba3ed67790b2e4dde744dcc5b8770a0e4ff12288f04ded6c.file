/*
 * e-extensible.c
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 */

/**
 * SECTION: e-extensible
 * @include: libedataserver/libedataserver.h
 * @short_description: An interface for extending objects
 *
 * #EExtension objects can be tacked on to any #GObject instance that
 * implements the #EExtensible interface.  A #GObject type can be made
 * extensible in two steps:
 *
 * 1. Add the #EExtensible interface when registering the #GType.
 *    There are no methods to implement.
 *
 * |[
 * #include <libedataserver/libedataserver.h>
 *
 * G_DEFINE_TYPE_WITH_CODE (
 *         ECustomWidget, e_custom_widget, GTK_TYPE_WIDGET,
 *         G_IMPLEMENT_INTERFACE (E_TYPE_EXTENSIBLE, NULL))
 * ]|
 *
 * 2. Load extensions for the class at some point during #GObject
 *    initialization.  Generally this should be done toward the end of
 *    the initialization code, so extensions get a fully initialized
 *    object to work with.
 *
 * |[
 * static void
 * e_custom_widget_constructed (ECustomWidget *widget)
 * {
 *         Construction code goes here, same as call to parent's 'constructed'...
 *
 *         e_extensible_load_extensions (E_EXTENSIBLE (widget));
 * }
 * ]|
 **/

#include "evolution-data-server-config.h"

#include "e-extension.h"
#include "e-data-server-util.h"

#include "e-extensible.h"

#define IS_AN_EXTENSION_TYPE(type) \
	(g_type_is_a ((type), E_TYPE_EXTENSION))

static GQuark extensible_quark;

G_DEFINE_INTERFACE (
	EExtensible,
	e_extensible,
	G_TYPE_OBJECT)

static GPtrArray *
extensible_get_extensions (EExtensible *extensible)
{
	return g_object_get_qdata (G_OBJECT (extensible), extensible_quark);
}

static void
extensible_load_extension (GType extension_type,
                           EExtensible *extensible)
{
	EExtensionClass *extension_class;
	GType extensible_type;
	GPtrArray *extensions;
	EExtension *extension;

	extensible_type = G_OBJECT_TYPE (extensible);
	extension_class = g_type_class_ref (extension_type);

	/* Only load extensions that extend the given extensible object. */
	if (!g_type_is_a (extensible_type, extension_class->extensible_type))
		goto exit;

	extension = g_object_new (
		extension_type, "extensible", extensible, NULL);

	extensions = extensible_get_extensions (extensible);
	g_ptr_array_add (extensions, extension);

exit:
	g_type_class_unref (extension_class);
}

static void
e_extensible_default_init (EExtensibleInterface *iface)
{
	extensible_quark = g_quark_from_static_string ("e-extensible-quark");
}

/**
 * e_extensible_load_extensions:
 * @extensible: an #EExtensible
 *
 * Creates an instance of all instantiable subtypes of #EExtension which
 * target the class of @extensible.  The lifetimes of these newly created
 * #EExtension objects are bound to @extensible such that they are finalized
 * when @extensible is finalized.
 *
 * Since: 3.4
 **/
void
e_extensible_load_extensions (EExtensible *extensible)
{
	GPtrArray *extensions;

	g_return_if_fail (E_IS_EXTENSIBLE (extensible));

	if (extensible_get_extensions (extensible) != NULL)
		return;

	extensions = g_ptr_array_new_with_free_func (
		(GDestroyNotify) g_object_unref);

	g_object_set_qdata_full (
		G_OBJECT (extensible), extensible_quark,
		g_ptr_array_ref (extensions),
		(GDestroyNotify) g_ptr_array_unref);

	e_type_traverse (
		E_TYPE_EXTENSION, (ETypeFunc)
		extensible_load_extension, extensible);

	/* If the extension array is still empty, remove it from the
	 * extensible object.  It may be that no extension types have
	 * been registered yet, so this allows for trying again later. */
	if (extensions->len == 0)
		g_object_set_qdata (
			G_OBJECT (extensible),
			extensible_quark, NULL);

	g_ptr_array_unref (extensions);
}

/**
 * e_extensible_list_extensions:
 * @extensible: an #EExtensible
 * @extension_type: the type of extensions to list
 *
 * Returns a list of #EExtension objects bound to @extensible whose
 * types are ancestors of @extension_type.  For a complete list of
 * extension objects bound to @extensible, pass %E_TYPE_EXTENSION.
 *
 * The list itself should be freed with g_list_free().  The extension
 * objects are owned by @extensible and should not be unreferenced.
 *
 * Returns: (element-type EExtension) (transfer container): a list of extension objects derived from @extension_type
 *
 * Since: 3.4
 **/
GList *
e_extensible_list_extensions (EExtensible *extensible,
                              GType extension_type)
{
	GPtrArray *extensions;
	GList *list = NULL;
	guint ii;

	g_return_val_if_fail (E_IS_EXTENSIBLE (extensible), NULL);
	g_return_val_if_fail (IS_AN_EXTENSION_TYPE (extension_type), NULL);

	e_extensible_load_extensions (extensible);

	extensions = extensible_get_extensions (extensible);

	/* This will be NULL if no extensions are present. */
	if (extensions == NULL)
		return NULL;

	for (ii = 0; ii < extensions->len; ii++) {
		GObject *object;

		object = g_ptr_array_index (extensions, ii);
		if (g_type_is_a (G_OBJECT_TYPE (object), extension_type))
			list = g_list_prepend (list, object);
	}

	return g_list_reverse (list);
}
