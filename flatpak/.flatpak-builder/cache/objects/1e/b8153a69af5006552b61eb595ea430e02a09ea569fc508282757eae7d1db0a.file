/*
 * e-source-autocomplete.c
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
 * SECTION: e-source-autocomplete
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for autocomplete settings
 *
 * The #ESourceAutocomplete extension tracks contact autocompletion
 * settings for an address book.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceAutocomplete *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTOCOMPLETE);
 * ]|
 **/

#include "e-source-autocomplete.h"

#define E_SOURCE_AUTOCOMPLETE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_AUTOCOMPLETE, ESourceAutocompletePrivate))

struct _ESourceAutocompletePrivate {
	gboolean include_me;
};

enum {
	PROP_0,
	PROP_INCLUDE_ME
};

G_DEFINE_TYPE (
	ESourceAutocomplete,
	e_source_autocomplete,
	E_TYPE_SOURCE_EXTENSION)

static void
source_autocomplete_set_property (GObject *object,
                                    guint property_id,
                                    const GValue *value,
                                    GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_INCLUDE_ME:
			e_source_autocomplete_set_include_me (
				E_SOURCE_AUTOCOMPLETE (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_autocomplete_get_property (GObject *object,
                                    guint property_id,
                                    GValue *value,
                                    GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_INCLUDE_ME:
			g_value_set_boolean (
				value,
				e_source_autocomplete_get_include_me (
				E_SOURCE_AUTOCOMPLETE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_source_autocomplete_class_init (ESourceAutocompleteClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceAutocompletePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_autocomplete_set_property;
	object_class->get_property = source_autocomplete_get_property;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_AUTOCOMPLETE;

	g_object_class_install_property (
		object_class,
		PROP_INCLUDE_ME,
		g_param_spec_boolean (
			"include-me",
			"IncludeMe",
			"Include this source when autocompleting",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_autocomplete_init (ESourceAutocomplete *extension)
{
	extension->priv = E_SOURCE_AUTOCOMPLETE_GET_PRIVATE (extension);
}

/**
 * e_source_autocomplete_get_include_me:
 * @extension: an #ESourceAutocomplete
 *
 * Returns whether the address book described by the #ESource to which
 * @extension belongs should be queried when the user inputs a partial
 * contact name or email address.
 *
 * Returns: whether to use the autocomplete feature
 *
 * Since: 3.6
 **/
gboolean
e_source_autocomplete_get_include_me (ESourceAutocomplete *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_AUTOCOMPLETE (extension), FALSE);

	return extension->priv->include_me;
}

/**
 * e_source_autocomplete_set_include_me:
 * @extension: an #ESourceAutocomplete
 * @include_me: whether to use the autocomplete feature
 *
 * Sets whether the address book described by the #ESource to which
 * @extension belongs should be queried when the user inputs a partial
 * contact name or email address.
 *
 * Since: 3.6
 **/
void
e_source_autocomplete_set_include_me (ESourceAutocomplete *extension,
                                      gboolean include_me)
{
	g_return_if_fail (E_IS_SOURCE_AUTOCOMPLETE (extension));

	if (extension->priv->include_me == include_me)
		return;

	extension->priv->include_me = include_me;

	g_object_notify (G_OBJECT (extension), "include-me");
}
