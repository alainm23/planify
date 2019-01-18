/*
 * e-source-local.c
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

#include "evolution-data-server-config.h"

#include "e-source-local.h"

#define E_SOURCE_LOCAL_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_LOCAL, ESourceLocalPrivate))

struct _ESourceLocalPrivate {
	GFile *custom_file;
};

enum {
	PROP_0,
	PROP_CUSTOM_FILE
};

G_DEFINE_TYPE (
	ESourceLocal,
	e_source_local,
	E_TYPE_SOURCE_EXTENSION)

static void
source_local_set_property (GObject *object,
                           guint property_id,
                           const GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CUSTOM_FILE:
			e_source_local_set_custom_file (
				E_SOURCE_LOCAL (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_local_get_property (GObject *object,
                           guint property_id,
                           GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CUSTOM_FILE:
			g_value_take_object (
				value,
				e_source_local_dup_custom_file (
				E_SOURCE_LOCAL (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_local_finalize (GObject *object)
{
	ESourceLocalPrivate *priv;

	priv = E_SOURCE_LOCAL_GET_PRIVATE (object);

	if (priv->custom_file != NULL) {
		g_object_unref (priv->custom_file);
		priv->custom_file = NULL;
	}

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_local_parent_class)->finalize (object);
}

static void
e_source_local_class_init (ESourceLocalClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceLocalPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_local_set_property;
	object_class->get_property = source_local_get_property;
	object_class->finalize = source_local_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_LOCAL_BACKEND;

	g_object_class_install_property (
		object_class,
		PROP_CUSTOM_FILE,
		g_param_spec_object (
			"custom-file",
			"Custom File",
			"Custom iCalendar file",
			G_TYPE_FILE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_local_init (ESourceLocal *extension)
{
	extension->priv = E_SOURCE_LOCAL_GET_PRIVATE (extension);
}

/**
 * e_source_local_get_custom_file:
 * @extension: an #ESourceLocal
 *
 * Returns: (transfer none): the #GFile instance
 **/
GFile *
e_source_local_get_custom_file (ESourceLocal *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_LOCAL (extension), NULL);

	return extension->priv->custom_file;
}

/**
 * e_source_local_dup_custom_file:
 * @extension: an #ESourceLocal
 *
 * Returns: (transfer full): the #GFile instance
 **/
GFile *
e_source_local_dup_custom_file (ESourceLocal *extension)
{
	GFile *protected;
	GFile *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_LOCAL (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_local_get_custom_file (extension);
	duplicate = (protected != NULL) ? g_file_dup (protected) : NULL;

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

void
e_source_local_set_custom_file (ESourceLocal *extension,
                                GFile *custom_file)
{
	g_return_if_fail (E_IS_SOURCE_LOCAL (extension));

	if (custom_file != NULL) {
		g_return_if_fail (G_IS_FILE (custom_file));
		g_object_ref (custom_file);
	}

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (extension->priv->custom_file != NULL)
		g_object_unref (extension->priv->custom_file);

	extension->priv->custom_file = custom_file;

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "custom-file");
}
