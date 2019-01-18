/*
 * camel-mh-settings.c
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

#include "camel-mh-settings.h"

#define CAMEL_MH_SETTINGS_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MH_SETTINGS, CamelMhSettingsPrivate))

struct _CamelMhSettingsPrivate {
	gboolean use_dot_folders;
};

enum {
	PROP_0,
	PROP_USE_DOT_FOLDERS
};

G_DEFINE_TYPE (
	CamelMhSettings,
	camel_mh_settings,
	CAMEL_TYPE_LOCAL_SETTINGS)

static void
mh_settings_set_property (GObject *object,
                             guint property_id,
                             const GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_USE_DOT_FOLDERS:
			camel_mh_settings_set_use_dot_folders (
				CAMEL_MH_SETTINGS (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
mh_settings_get_property (GObject *object,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_USE_DOT_FOLDERS:
			g_value_set_boolean (
				value,
				camel_mh_settings_get_use_dot_folders (
				CAMEL_MH_SETTINGS (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
camel_mh_settings_class_init (CamelMhSettingsClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelMhSettingsPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = mh_settings_set_property;
	object_class->get_property = mh_settings_get_property;

	g_object_class_install_property (
		object_class,
		PROP_USE_DOT_FOLDERS,
		g_param_spec_boolean (
			"use-dot-folders",
			"Use Dot Folders",
			"Update the exmh .folders file",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));
}

static void
camel_mh_settings_init (CamelMhSettings *settings)
{
	settings->priv = CAMEL_MH_SETTINGS_GET_PRIVATE (settings);
}

/**
 * camel_mh_settings_get_use_dot_folders:
 * @settings: a #CamelMhSettings
 *
 * Returns whether @settings should keep the .folders summary file used by
 * the exmh (http://www.beedub.com/exmh/) mail client updated as it makes
 * changes to the MH folders.
 *
 * Returns: whether to use exmh's .folders file
 *
 * Since: 3.2
 **/
gboolean
camel_mh_settings_get_use_dot_folders (CamelMhSettings *settings)
{
	g_return_val_if_fail (CAMEL_IS_MH_SETTINGS (settings), FALSE);

	return settings->priv->use_dot_folders;
}

/**
 * camel_mh_settings_set_use_dot_folders:
 * @settings: a #CamelMhSettings
 * @use_dot_folders: whether to use exmh's .folders file
 *
 * Sets whether @settings should keep the .folders summary file used by
 * the exmh (http://www.beedub.com/exmh/) mail client updated as it makes
 * changes to the MH folders.
 *
 * Since: 3.2
 **/
void
camel_mh_settings_set_use_dot_folders (CamelMhSettings *settings,
                                       gboolean use_dot_folders)
{
	g_return_if_fail (CAMEL_IS_MH_SETTINGS (settings));

	if (settings->priv->use_dot_folders == use_dot_folders)
		return;

	settings->priv->use_dot_folders = use_dot_folders;

	g_object_notify (G_OBJECT (settings), "use-dot-folders");
}
