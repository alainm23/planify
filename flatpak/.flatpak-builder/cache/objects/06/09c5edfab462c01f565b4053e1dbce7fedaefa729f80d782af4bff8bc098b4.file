/*
 * e-extension.c
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
 * SECTION: e-extension
 * @include: libedataserver/libedataserver.h
 * @short_description: An abstract base class for extensions
 *
 * #EExtension provides a way to extend the functionality of objects
 * that implement the #EExtensible interface.  #EExtension subclasses
 * can target a particular extensible object type.  New instances of
 * an extensible object type get paired with a new instance of each
 * #EExtension subclass that targets the extensible object type.
 *
 * The first steps of writing a new extension are as follows:
 *
 * 1. Subclass #EExtension.
 *
 * 2. In the class initialization function, specify the #GType being
 *    extended.  The #GType must implement the #EExtensible interface.
 *
 * 3. Register the extension's own #GType.  If the extension is to
 *    be loaded dynamically using #GTypeModule, the type should be
 *    registered in the library module's e_module_load() function.
 **/

#include "evolution-data-server-config.h"

#include "e-extension.h"

#define E_EXTENSION_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_EXTENSION, EExtensionPrivate))

struct _EExtensionPrivate {
	gpointer extensible;  /* weak pointer */
};

enum {
	PROP_0,
	PROP_EXTENSIBLE
};

G_DEFINE_ABSTRACT_TYPE (
	EExtension,
	e_extension,
	G_TYPE_OBJECT)

static void
extension_set_extensible (EExtension *extension,
                          EExtensible *extensible)
{
	EExtensionClass *class;
	GType extensible_type;

	g_return_if_fail (E_IS_EXTENSIBLE (extensible));
	g_return_if_fail (extension->priv->extensible == NULL);

	class = E_EXTENSION_GET_CLASS (extension);
	g_return_if_fail (class != NULL);

	extensible_type = G_OBJECT_TYPE (extensible);

	/* Verify the EExtensible object is the type we want. */
	if (!g_type_is_a (extensible_type, class->extensible_type)) {
		g_warning (
			"%s is meant to extend %s but was given an %s",
			G_OBJECT_TYPE_NAME (extension),
			g_type_name (class->extensible_type),
			g_type_name (extensible_type));
		return;
	}

	extension->priv->extensible = extensible;

	g_object_add_weak_pointer (
		G_OBJECT (extensible), &extension->priv->extensible);
}

static void
extension_set_property (GObject *object,
                        guint property_id,
                        const GValue *value,
                        GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_EXTENSIBLE:
			extension_set_extensible (
				E_EXTENSION (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
extension_get_property (GObject *object,
                        guint property_id,
                        GValue *value,
                        GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_EXTENSIBLE:
			g_value_set_object (
				value, e_extension_get_extensible (
				E_EXTENSION (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
extension_dispose (GObject *object)
{
	EExtensionPrivate *priv;

	priv = E_EXTENSION_GET_PRIVATE (object);

	if (priv->extensible != NULL) {
		g_object_remove_weak_pointer (
			G_OBJECT (priv->extensible), &priv->extensible);
		priv->extensible = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_extension_parent_class)->dispose (object);
}

static void
e_extension_class_init (EExtensionClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EExtensionPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = extension_set_property;
	object_class->get_property = extension_get_property;
	object_class->dispose = extension_dispose;

	g_object_class_install_property (
		object_class,
		PROP_EXTENSIBLE,
		g_param_spec_object (
			"extensible",
			"Extensible Object",
			"The object being extended",
			E_TYPE_EXTENSIBLE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY));
}

static void
e_extension_init (EExtension *extension)
{
	extension->priv = E_EXTENSION_GET_PRIVATE (extension);
}

/**
 * e_extension_get_extensible:
 * @extension: an #EExtension
 *
 * Returns the object that @extension extends.
 *
 * Returns: (transfer none): the object being extended
 *
 * Since: 3.4
 **/
EExtensible *
e_extension_get_extensible (EExtension *extension)
{
	g_return_val_if_fail (E_IS_EXTENSION (extension), NULL);

	return E_EXTENSIBLE (extension->priv->extensible);
}
