/*
 * e-source-autoconfig.c
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
 * SECTION: e-source-autoconfig
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for autoconfig settings
 *
 * The #ESourceAutoconfig extension keeps a mapping between user-specific
 * sources and system-wide ones.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceAutoconfig *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTOCONFIG);
 * ]|
 **/

#include "e-source-autoconfig.h"

#define E_SOURCE_AUTOCONFIG_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_AUTOCONFIG, ESourceAutoconfigPrivate))

struct _ESourceAutoconfigPrivate {
	gchar *revision;
};

enum {
	PROP_0,
	PROP_REVISION
};

G_DEFINE_TYPE (
	ESourceAutoconfig,
	e_source_autoconfig,
	E_TYPE_SOURCE_EXTENSION)

static void
source_autoconfig_get_property (GObject *object,
                                guint property_id,
                                GValue *value,
                                GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_REVISION:
			g_value_take_string (
				value,
				e_source_autoconfig_dup_revision (
				E_SOURCE_AUTOCONFIG (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_autoconfig_set_property (GObject *object,
                                guint property_id,
                                const GValue *value,
                                GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_REVISION:
			e_source_autoconfig_set_revision (
				E_SOURCE_AUTOCONFIG (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_autoconfig_finalize (GObject *object)
{
	ESourceAutoconfigPrivate *priv;

	priv = E_SOURCE_AUTOCONFIG_GET_PRIVATE (object);

	g_free (priv->revision);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_autoconfig_parent_class)->finalize (object);
}

static void
e_source_autoconfig_class_init (ESourceAutoconfigClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceAutoconfigPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_autoconfig_set_property;
	object_class->get_property = source_autoconfig_get_property;
	object_class->finalize = source_autoconfig_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_AUTOCONFIG;

	g_object_class_install_property (
		object_class,
		PROP_REVISION,
		g_param_spec_string (
			"revision",
			"Revision",
			"Identifier to map a particular version of a system-wide source to a user-specific source",
			"",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_autoconfig_init (ESourceAutoconfig *extension)
{
	extension->priv = E_SOURCE_AUTOCONFIG_GET_PRIVATE (extension);
}

/**
 * e_source_autoconfig_get_revision:
 * @extension: an #ESourceAutoconfig
 *
 * Returns the revision of a data source. This maps a particular version of a
 * system-wide source to a user-specific source.
 *
 * If doesn't match, the system-wide source will be copied to the user-specific
 * evolution config directory, preserving the already present fields that are
 * not defined by the system-wide source.
 *
 * If it matches, no copying is done.
 *
 * Returns: revision of the data source
 *
 * Since: 3.24
 **/
const gchar *
e_source_autoconfig_get_revision (ESourceAutoconfig *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_AUTOCONFIG (extension), NULL);

	return extension->priv->revision;
}

/**
 * e_source_autoconfig_dup_revision:
 * @extension: an #ESourceAutoconfig
 *
 * Thread-safe variation of e_source_autoconfig_get_revision().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: (transfer full): a newly-allocated copy of #ESourceAutoconfig:revision
 *
 * Since: 3.24
 **/
gchar *
e_source_autoconfig_dup_revision (ESourceAutoconfig *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_AUTOCONFIG (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_autoconfig_get_revision (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_autoconfig_set_revision:
 * @extension: an #ESourceAutoconfig
 * @revision: a revision
 *
 * Sets the revision used to map a particular version of a system-wide source
 * to a user-specific source.
 *
 * If doesn't match, the system-wide source will be copied to the user-specific
 * evolution config directory, preserving the already present fields that are
 * not defined by the system-wide source.
 *
 * If it matches, no copying is done.
 *
 * The internal copy of @revision is automatically stripped of leading and
 * trailing whitespace.
 *
 * Since: 3.24
 **/
void
e_source_autoconfig_set_revision (ESourceAutoconfig *extension,
                                  const gchar *revision)
{
	g_return_if_fail (E_IS_SOURCE_AUTOCONFIG (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->revision, revision) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->revision);
	extension->priv->revision = e_util_strdup_strip (revision);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "revision");
}
