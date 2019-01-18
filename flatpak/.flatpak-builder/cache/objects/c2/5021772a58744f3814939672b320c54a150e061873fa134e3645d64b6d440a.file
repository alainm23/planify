/*
 * e-source-selectable.c
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
 * SECTION: e-source-selectable
 * @include: libedataserver/libedataserver.h
 * @short_description: Base class for selectable data sources
 * @see_also: #ESourceCalendar, #ESourceMemoList, #ESourceTaskList
 *
 * #ESourceSelectable is an abstract base class for data sources
 * that can be selected.
 **/

#include "e-source-selectable.h"

#include <libedataserver/e-data-server-util.h>

#define E_SOURCE_SELECTABLE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_SELECTABLE, ESourceSelectablePrivate))

struct _ESourceSelectablePrivate {
	gchar *color;
	gboolean selected;
};

enum {
	PROP_0,
	PROP_COLOR,
	PROP_SELECTED
};

G_DEFINE_ABSTRACT_TYPE (
	ESourceSelectable,
	e_source_selectable,
	E_TYPE_SOURCE_BACKEND)

static void
source_selectable_set_property (GObject *object,
                                guint property_id,
                                const GValue *value,
                                GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_COLOR:
			e_source_selectable_set_color (
				E_SOURCE_SELECTABLE (object),
				g_value_get_string (value));
			return;

		case PROP_SELECTED:
			e_source_selectable_set_selected (
				E_SOURCE_SELECTABLE (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_selectable_get_property (GObject *object,
                                guint property_id,
                                GValue *value,
                                GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_COLOR:
			g_value_take_string (
				value,
				e_source_selectable_dup_color (
				E_SOURCE_SELECTABLE (object)));
			return;

		case PROP_SELECTED:
			g_value_set_boolean (
				value,
				e_source_selectable_get_selected (
				E_SOURCE_SELECTABLE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_selectable_finalize (GObject *object)
{
	ESourceSelectablePrivate *priv;

	priv = E_SOURCE_SELECTABLE_GET_PRIVATE (object);

	g_free (priv->color);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_selectable_parent_class)->finalize (object);
}

static void
e_source_selectable_class_init (ESourceSelectableClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ESourceSelectablePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_selectable_set_property;
	object_class->get_property = source_selectable_get_property;
	object_class->finalize = source_selectable_finalize;

	/* We do not provide an extension name,
	 * which is why the class is abstract. */

	g_object_class_install_property (
		object_class,
		PROP_COLOR,
		g_param_spec_string (
			"color",
			"Color",
			"Textual specification of a color",
			"#becedd",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_SELECTED,
		g_param_spec_boolean (
			"selected",
			"Selected",
			"Whether the data source is selected",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_selectable_init (ESourceSelectable *extension)
{
	extension->priv = E_SOURCE_SELECTABLE_GET_PRIVATE (extension);
}

/**
 * e_source_selectable_get_color:
 * @extension: an #ESourceSelectable
 *
 * Returns the color specification for the #ESource to which @extension
 * belongs.  A colored block is often displayed next to the data source's
 * display name in user interfaces.
 *
 * Returns: the color specification for the #ESource
 *
 * Since: 3.6
 **/
const gchar *
e_source_selectable_get_color (ESourceSelectable *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_SELECTABLE (extension), NULL);

	return extension->priv->color;
}

/**
 * e_source_selectable_dup_color:
 * @extension: an #ESourceSelectable
 *
 * Thread-safe variation of e_source_selectable_get_color().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceSelectable:color
 *
 * Since: 3.6
 **/
gchar *
e_source_selectable_dup_color (ESourceSelectable *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_SELECTABLE (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_selectable_get_color (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_selectable_set_color:
 * @extension: an #ESourceSelectable
 * @color: (allow-none): a color specification, or %NULL
 *
 * Sets the color specification for the #ESource to which @extension
 * belongs.  A colored block is often displayed next to the data source's
 * display name in user interfaces.
 *
 * The internal copy of @color is automatically stripped of leading and
 * trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.6
 **/
void
e_source_selectable_set_color (ESourceSelectable *extension,
                               const gchar *color)
{
	g_return_if_fail (E_IS_SOURCE_SELECTABLE (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->color, color) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->color);
	extension->priv->color = e_util_strdup_strip (color);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "color");
}

/**
 * e_source_selectable_get_selected:
 * @extension: an #ESourceSelectable
 *
 * Returns the selected state of the #ESource to which @extension belongs.
 * The selected state is often represented as a checkbox next to the data
 * source's display name in user interfaces.
 *
 * Returns: the selected state for the #ESource
 *
 * Since: 3.6
 **/
gboolean
e_source_selectable_get_selected (ESourceSelectable *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_SELECTABLE (extension), FALSE);

	return extension->priv->selected;
}

/**
 * e_source_selectable_set_selected:
 * @extension: an #ESourceSelectable
 * @selected: selected state
 *
 * Sets the selected state for the #ESource to which @extension belongs.
 * The selected state is often represented as a checkbox next to the data
 * source's display name in user interfaces.
 *
 * Since: 3.6
 **/
void
e_source_selectable_set_selected (ESourceSelectable *extension,
                                  gboolean selected)
{
	g_return_if_fail (E_IS_SOURCE_SELECTABLE (extension));

	if (extension->priv->selected == selected)
		return;

	extension->priv->selected = selected;

	g_object_notify (G_OBJECT (extension), "selected");
}

