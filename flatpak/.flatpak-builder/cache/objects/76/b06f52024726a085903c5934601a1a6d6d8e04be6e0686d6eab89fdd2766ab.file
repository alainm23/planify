/*
 * e-source-weather.c
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

#include "e-source-enumtypes.h"
#include "e-source-weather.h"

#define E_SOURCE_WEATHER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_WEATHER, ESourceWeatherPrivate))

struct _ESourceWeatherPrivate {
	ESourceWeatherUnits units;
	gchar *location;
};

enum {
	PROP_0,
	PROP_LOCATION,
	PROP_UNITS
};

G_DEFINE_TYPE (
	ESourceWeather,
	e_source_weather,
	E_TYPE_SOURCE_EXTENSION)

static void
source_weather_set_property (GObject *object,
                             guint property_id,
                             const GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_LOCATION:
			e_source_weather_set_location (
				E_SOURCE_WEATHER (object),
				g_value_get_string (value));
			return;

		case PROP_UNITS:
			e_source_weather_set_units (
				E_SOURCE_WEATHER (object),
				g_value_get_enum (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_weather_get_property (GObject *object,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_LOCATION:
			g_value_take_string (
				value,
				e_source_weather_dup_location (
				E_SOURCE_WEATHER (object)));
			return;

		case PROP_UNITS:
			g_value_set_enum (
				value,
				e_source_weather_get_units (
				E_SOURCE_WEATHER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_weather_finalize (GObject *object)
{
	ESourceWeatherPrivate *priv;

	priv = E_SOURCE_WEATHER_GET_PRIVATE (object);

	g_free (priv->location);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_weather_parent_class)->finalize (object);
}

static void
e_source_weather_class_init (ESourceWeatherClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceWeatherPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_weather_set_property;
	object_class->get_property = source_weather_get_property;
	object_class->finalize = source_weather_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_WEATHER_BACKEND;

	g_object_class_install_property (
		object_class,
		PROP_LOCATION,
		g_param_spec_string (
			"location",
			"Location",
			"Weather location code",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_UNITS,
		g_param_spec_enum (
			"units",
			"Units",
			"Fahrenheit, Centigrade or Kelvin units",
			E_TYPE_SOURCE_WEATHER_UNITS,
			E_SOURCE_WEATHER_UNITS_CENTIGRADE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_weather_init (ESourceWeather *extension)
{
	extension->priv = E_SOURCE_WEATHER_GET_PRIVATE (extension);
}

const gchar *
e_source_weather_get_location (ESourceWeather *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_WEATHER (extension), NULL);

	return extension->priv->location;
}

gchar *
e_source_weather_dup_location (ESourceWeather *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_WEATHER (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_weather_get_location (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

void
e_source_weather_set_location (ESourceWeather *extension,
                               const gchar *location)
{
	g_return_if_fail (E_IS_SOURCE_WEATHER (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->location, location) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->location);
	extension->priv->location = e_util_strdup_strip (location);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "location");
}

ESourceWeatherUnits
e_source_weather_get_units (ESourceWeather *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_WEATHER (extension), 0);

	return extension->priv->units;
}

void
e_source_weather_set_units (ESourceWeather *extension,
                            ESourceWeatherUnits units)
{
	g_return_if_fail (E_IS_SOURCE_WEATHER (extension));

	if (extension->priv->units == units)
		return;

	extension->priv->units = units;

	g_object_notify (G_OBJECT (extension), "units");
}
