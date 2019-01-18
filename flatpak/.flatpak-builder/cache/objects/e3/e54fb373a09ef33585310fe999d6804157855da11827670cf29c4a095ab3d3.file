/*
 * camel-settings.c
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

#include "camel-settings.h"

#include <stdlib.h>

/* Needed for CamelSettings <--> CamelURL conversions. */
#include "camel-local-settings.h"
#include "camel-network-settings.h"

G_DEFINE_TYPE (CamelSettings, camel_settings, G_TYPE_OBJECT)

static GParamSpec **
settings_list_settings (CamelSettingsClass *class,
                        guint *n_settings)
{
	GObjectClass *object_class = G_OBJECT_CLASS (class);

	return g_object_class_list_properties (object_class, n_settings);
}

static CamelSettings *
settings_clone (CamelSettings *settings)
{
	CamelSettingsClass *class;
	GParamSpec **properties;
	GParameter *parameters;
	CamelSettings *clone;
	guint ii, n_properties;

	class = CAMEL_SETTINGS_GET_CLASS (settings);
	g_return_val_if_fail (class != NULL, NULL);

	properties = camel_settings_class_list_settings (class, &n_properties);

	parameters = g_new0 (GParameter, n_properties);

	for (ii = 0; ii < n_properties; ii++) {
		parameters[ii].name = properties[ii]->name;
		g_value_init (
			&parameters[ii].value,
			properties[ii]->value_type);
		g_object_get_property (
			G_OBJECT (settings),
			parameters[ii].name,
			&parameters[ii].value);
	}

	clone = g_object_newv (
		G_OBJECT_TYPE (settings),
		n_properties, parameters);

	for (ii = 0; ii < n_properties; ii++)
		g_value_unset (&parameters[ii].value);

	g_free (parameters);
	g_free (properties);

	return clone;
}

static gboolean
settings_equal (CamelSettings *settings_a,
                CamelSettings *settings_b)
{
	CamelSettingsClass *class;
	GParamSpec **properties;
	GValue *value_a;
	GValue *value_b;
	guint ii, n_properties;
	gboolean equal = TRUE;

	/* Make sure both instances are of the same type. */
	if (G_OBJECT_TYPE (settings_a) != G_OBJECT_TYPE (settings_b))
		return FALSE;

	value_a = g_slice_new0 (GValue);
	value_b = g_slice_new0 (GValue);

	class = CAMEL_SETTINGS_GET_CLASS (settings_a);
	g_return_val_if_fail (class != NULL, FALSE);

	properties = camel_settings_class_list_settings (class, &n_properties);

	for (ii = 0; equal && ii < n_properties; ii++) {
		GParamSpec *pspec = properties[ii];

		g_value_init (value_a, pspec->value_type);
		g_value_init (value_b, pspec->value_type);

		g_object_get_property (
			G_OBJECT (settings_a),
			pspec->name, value_a);

		g_object_get_property (
			G_OBJECT (settings_b),
			pspec->name, value_b);

		equal = (g_param_values_cmp (pspec, value_a, value_b) == 0);

		g_value_unset (value_a);
		g_value_unset (value_b);
	}

	g_free (properties);

	g_slice_free (GValue, value_a);
	g_slice_free (GValue, value_b);

	return equal;
}

static void
camel_settings_class_init (CamelSettingsClass *class)
{
	class->list_settings = settings_list_settings;
	class->clone = settings_clone;
	class->equal = settings_equal;
}

static void
camel_settings_init (CamelSettings *settings)
{
}

/**
 * camel_settings_class_list_settings:
 * @settings_class: a #CamelSettingsClass
 * @n_settings: return location for the length of the returned array
 *
 * Returns an array of #GParamSpec for properties of @class which are
 * considered to be settings.  By default all properties are considered
 * to be settings, but subclasses may wish to exclude certain properties.
 * Free the returned array with g_free().
 *
 * Returns: (transfer full): an array of #GParamSpec which should be freed after use
 *
 * Since: 3.2
 **/
GParamSpec **
camel_settings_class_list_settings (CamelSettingsClass *settings_class,
                                    guint *n_settings)
{
	g_return_val_if_fail (CAMEL_IS_SETTINGS_CLASS (settings_class), NULL);
	g_return_val_if_fail (settings_class->list_settings != NULL, NULL);

	return settings_class->list_settings (settings_class, n_settings);
}

/**
 * camel_settings_clone:
 * @settings: a #CamelSettings
 *
 * Creates an copy of @settings, such that passing @settings and the
 * copied instance to camel_settings_equal() would return %TRUE.
 *
 * By default, this creates a new settings instance with the same #GType
 * as @settings, and copies all #GObject property values from @settings
 * to the new instance.
 *
 * Returns: (transfer full): a newly-created copy of @settings
 *
 * Since: 3.2
 **/
CamelSettings *
camel_settings_clone (CamelSettings *settings)
{
	CamelSettingsClass *class;
	CamelSettings *clone;

	g_return_val_if_fail (CAMEL_IS_SETTINGS (settings), NULL);

	class = CAMEL_SETTINGS_GET_CLASS (settings);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->clone != NULL, NULL);

	clone = class->clone (settings);

	/* Make sure the documented invariant is satisfied. */
	g_warn_if_fail (camel_settings_equal (settings, clone));

	return clone;
}

/**
 * camel_settings_equal:
 * @settings_a: a #CamelSettings
 * @settings_b: another #CamelSettings
 *
 * Returns %TRUE if @settings_a and @settings_b are equal.
 *
 * By default, equality requires both instances to have the same #GType
 * with the same set of #GObject properties, and each property value in
 * @settings_a is equal to the corresponding value in @settings_b.
 *
 * Returns: %TRUE if @settings_a and @settings_b are equal
 *
 * Since: 3.2
 **/
gboolean
camel_settings_equal (CamelSettings *settings_a,
                      CamelSettings *settings_b)
{
	CamelSettingsClass *class;

	g_return_val_if_fail (CAMEL_IS_SETTINGS (settings_a), FALSE);
	g_return_val_if_fail (CAMEL_IS_SETTINGS (settings_b), FALSE);

	class = CAMEL_SETTINGS_GET_CLASS (settings_a);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->equal != NULL, FALSE);

	return class->equal (settings_a, settings_b);
}

