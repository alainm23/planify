/*
 * camel-spool-settings.c
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

#include "camel-spool-settings.h"

#define CAMEL_SPOOL_SETTINGS_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SPOOL_SETTINGS, CamelSpoolSettingsPrivate))

struct _CamelSpoolSettingsPrivate {
	gboolean use_xstatus_headers;
};

enum {
	PROP_0,
	PROP_USE_XSTATUS_HEADERS
};

G_DEFINE_TYPE (
	CamelSpoolSettings,
	camel_spool_settings,
	CAMEL_TYPE_LOCAL_SETTINGS)

static void
spool_settings_set_property (GObject *object,
                             guint property_id,
                             const GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_USE_XSTATUS_HEADERS:
			camel_spool_settings_set_use_xstatus_headers (
				CAMEL_SPOOL_SETTINGS (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
spool_settings_get_property (GObject *object,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_USE_XSTATUS_HEADERS:
			g_value_set_boolean (
				value,
				camel_spool_settings_get_use_xstatus_headers (
				CAMEL_SPOOL_SETTINGS (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
camel_spool_settings_class_init (CamelSpoolSettingsClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelSpoolSettingsPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = spool_settings_set_property;
	object_class->get_property = spool_settings_get_property;

	g_object_class_install_property (
		object_class,
		PROP_USE_XSTATUS_HEADERS,
		g_param_spec_boolean (
			"use-xstatus-headers",
			"Use X-Status Headers",
			"Whether to use X-Status headers",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));
}

static void
camel_spool_settings_init (CamelSpoolSettings *settings)
{
	settings->priv = CAMEL_SPOOL_SETTINGS_GET_PRIVATE (settings);
}

/**
 * camel_spool_settings_get_use_xstatus_headers:
 * @settings: a #CamelSpoolSettings
 *
 * Returns whether to utilize both "Status" and "X-Status" headers for
 * interoperability with mbox-based mail clients like Elm, Pine and Mutt.
 *
 * Returns: whether to use "X-Status" headers
 *
 * Since: 3.2
 **/
gboolean
camel_spool_settings_get_use_xstatus_headers (CamelSpoolSettings *settings)
{
	g_return_val_if_fail (CAMEL_IS_SPOOL_SETTINGS (settings), FALSE);

	return settings->priv->use_xstatus_headers;
}

/**
 * camel_spool_settings_set_use_xstatus_headers:
 * @settings: a #CamelSpoolSettings
 * @use_xstatus_headers: whether to use "X-Status" headers
 *
 * Sets whether to utilize both "Status" and "X-Status" headers for
 * interoperability with mbox-based mail clients like Elm, Pine and Mutt.
 *
 * Since: 3.2
 **/
void
camel_spool_settings_set_use_xstatus_headers (CamelSpoolSettings *settings,
                                              gboolean use_xstatus_headers)
{
	g_return_if_fail (CAMEL_IS_SPOOL_SETTINGS (settings));

	if (settings->priv->use_xstatus_headers == use_xstatus_headers)
		return;

	settings->priv->use_xstatus_headers = use_xstatus_headers;

	g_object_notify (G_OBJECT (settings), "use-xstatus-headers");
}
