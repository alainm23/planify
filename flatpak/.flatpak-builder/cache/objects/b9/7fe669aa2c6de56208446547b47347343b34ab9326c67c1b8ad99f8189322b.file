/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcespacedrawer.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2008, 2011, 2016 - Paolo Borelli <pborelli@gnome.org>
 * Copyright (C) 2008, 2010 - Ignacio Casal Quinteiro <icq@gnome.org>
 * Copyright (C) 2010 - Garret Regier
 * Copyright (C) 2013 - Arpad Borsos <arpad.borsos@googlemail.com>
 * Copyright (C) 2015, 2016 - Sébastien Wilmet <swilmet@gnome.org>
 * Copyright (C) 2016 - Christian Hergert <christian@hergert.me>
 *
 * GtkSourceView is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GtkSourceView is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcespacedrawer.h"
#include "gtksourcespacedrawer-private.h"
#include "gtksourcebuffer.h"
#include "gtksourceiter.h"
#include "gtksourcestylescheme.h"
#include "gtksourcetag.h"

/**
 * SECTION:spacedrawer
 * @Short_description: Represent white space characters with symbols
 * @Title: GtkSourceSpaceDrawer
 * @See_also: #GtkSourceView
 *
 * #GtkSourceSpaceDrawer provides a way to visualize white spaces, by drawing
 * symbols.
 *
 * Call gtk_source_view_get_space_drawer() to get the #GtkSourceSpaceDrawer
 * instance of a certain #GtkSourceView.
 *
 * By default, no white spaces are drawn because the
 * #GtkSourceSpaceDrawer:enable-matrix is %FALSE.
 *
 * To draw white spaces, gtk_source_space_drawer_set_types_for_locations() can
 * be called to set the #GtkSourceSpaceDrawer:matrix property (by default all
 * space types are enabled at all locations). Then call
 * gtk_source_space_drawer_set_enable_matrix().
 *
 * For a finer-grained method, there is also the GtkSourceTag's
 * #GtkSourceTag:draw-spaces property.
 *
 * # Example
 *
 * To draw non-breaking spaces everywhere and draw all types of trailing spaces
 * except newlines:
 * |[
 * gtk_source_space_drawer_set_types_for_locations (space_drawer,
 *                                                  GTK_SOURCE_SPACE_LOCATION_ALL,
 *                                                  GTK_SOURCE_SPACE_TYPE_NBSP);
 *
 * gtk_source_space_drawer_set_types_for_locations (space_drawer,
 *                                                  GTK_SOURCE_SPACE_LOCATION_TRAILING,
 *                                                  GTK_SOURCE_SPACE_TYPE_ALL &
 *                                                  ~GTK_SOURCE_SPACE_TYPE_NEWLINE);
 *
 * gtk_source_space_drawer_set_enable_matrix (space_drawer, TRUE);
 * ]|
 *
 * # Use-case: draw unwanted white spaces
 *
 * A possible use-case is to draw only unwanted white spaces. Examples:
 * - Draw all trailing spaces.
 * - If the indentation and alignment must be done with spaces, draw tabs.
 *
 * And non-breaking spaces can always be drawn, everywhere, to distinguish them
 * from normal spaces.
 */

/* A drawer specially designed for the International Space Station. It comes by
 * default with a DVD of Matrix, in case the astronauts are bored.
 */

/*
#define ENABLE_PROFILE
*/
#undef ENABLE_PROFILE

struct _GtkSourceSpaceDrawerPrivate
{
	GtkSourceSpaceTypeFlags *matrix;
	GdkRGBA *color;
	guint enable_matrix : 1;
};

enum
{
	PROP_0,
	PROP_ENABLE_MATRIX,
	PROP_MATRIX,
	N_PROPERTIES
};

static GParamSpec *properties[N_PROPERTIES];

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceSpaceDrawer, gtk_source_space_drawer, G_TYPE_OBJECT)

static gint
get_number_of_locations (void)
{
	gint num;
	gint flags;

	num = 0;
	flags = GTK_SOURCE_SPACE_LOCATION_ALL;

	while (flags != 0)
	{
		flags >>= 1;
		num++;
	}

	return num;
}

static GVariant *
get_default_matrix (void)
{
	GVariantBuilder builder;
	gint num_locations;
	gint i;

	g_variant_builder_init (&builder, G_VARIANT_TYPE ("au"));

	num_locations = get_number_of_locations ();

	for (i = 0; i < num_locations; i++)
	{
		GVariant *space_types;

		space_types = g_variant_new_uint32 (GTK_SOURCE_SPACE_TYPE_ALL);

		g_variant_builder_add_value (&builder, space_types);
	}

	return g_variant_builder_end (&builder);
}

static gboolean
is_zero_matrix (GtkSourceSpaceDrawer *drawer)
{
	gint num_locations;
	gint i;

	num_locations = get_number_of_locations ();

	for (i = 0; i < num_locations; i++)
	{
		if (drawer->priv->matrix[i] != 0)
		{
			return FALSE;
		}
	}

	return TRUE;
}

static void
set_zero_matrix (GtkSourceSpaceDrawer *drawer)
{
	gint num_locations;
	gint i;
	gboolean changed = FALSE;

	num_locations = get_number_of_locations ();

	for (i = 0; i < num_locations; i++)
	{
		if (drawer->priv->matrix[i] != 0)
		{
			drawer->priv->matrix[i] = 0;
			changed = TRUE;
		}
	}

	if (changed)
	{
		g_object_notify_by_pspec (G_OBJECT (drawer), properties[PROP_MATRIX]);
	}
}

/* AND */
static GtkSourceSpaceTypeFlags
get_types_at_all_locations (GtkSourceSpaceDrawer        *drawer,
			    GtkSourceSpaceLocationFlags  locations)
{
	GtkSourceSpaceTypeFlags ret = GTK_SOURCE_SPACE_TYPE_ALL;
	gint index;
	gint num_locations;
	gboolean found;

	index = 0;
	num_locations = get_number_of_locations ();
	found = FALSE;

	while (locations != 0 && index < num_locations)
	{
		if ((locations & 1) == 1)
		{
			ret &= drawer->priv->matrix[index];
			found = TRUE;
		}

		locations >>= 1;
		index++;
	}

	return found ? ret : GTK_SOURCE_SPACE_TYPE_NONE;
}

/* OR */
static GtkSourceSpaceTypeFlags
get_types_at_any_locations (GtkSourceSpaceDrawer        *drawer,
			    GtkSourceSpaceLocationFlags  locations)
{
	GtkSourceSpaceTypeFlags ret = GTK_SOURCE_SPACE_TYPE_NONE;
	gint index;
	gint num_locations;

	index = 0;
	num_locations = get_number_of_locations ();

	while (locations != 0 && index < num_locations)
	{
		if ((locations & 1) == 1)
		{
			ret |= drawer->priv->matrix[index];
		}

		locations >>= 1;
		index++;
	}

	return ret;
}

static void
gtk_source_space_drawer_get_property (GObject    *object,
				      guint       prop_id,
				      GValue     *value,
				      GParamSpec *pspec)
{
	GtkSourceSpaceDrawer *drawer = GTK_SOURCE_SPACE_DRAWER (object);

	switch (prop_id)
	{
		case PROP_ENABLE_MATRIX:
			g_value_set_boolean (value, gtk_source_space_drawer_get_enable_matrix (drawer));
			break;

		case PROP_MATRIX:
			g_value_set_variant (value, gtk_source_space_drawer_get_matrix (drawer));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_space_drawer_set_property (GObject      *object,
				      guint         prop_id,
				      const GValue *value,
				      GParamSpec   *pspec)
{
	GtkSourceSpaceDrawer *drawer = GTK_SOURCE_SPACE_DRAWER (object);

	switch (prop_id)
	{
		case PROP_ENABLE_MATRIX:
			gtk_source_space_drawer_set_enable_matrix (drawer, g_value_get_boolean (value));
			break;

		case PROP_MATRIX:
			gtk_source_space_drawer_set_matrix (drawer, g_value_get_variant (value));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_space_drawer_finalize (GObject *object)
{
	GtkSourceSpaceDrawer *drawer = GTK_SOURCE_SPACE_DRAWER (object);

	g_free (drawer->priv->matrix);

	if (drawer->priv->color != NULL)
	{
		gdk_rgba_free (drawer->priv->color);
	}

	G_OBJECT_CLASS (gtk_source_space_drawer_parent_class)->finalize (object);
}

static void
gtk_source_space_drawer_class_init (GtkSourceSpaceDrawerClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->get_property = gtk_source_space_drawer_get_property;
	object_class->set_property = gtk_source_space_drawer_set_property;
	object_class->finalize = gtk_source_space_drawer_finalize;

	/**
	 * GtkSourceSpaceDrawer:enable-matrix:
	 *
	 * Whether the #GtkSourceSpaceDrawer:matrix property is enabled.
	 *
	 * Since: 3.24
	 */
	properties[PROP_ENABLE_MATRIX] =
		g_param_spec_boolean ("enable-matrix",
				      "Enable Matrix",
				      "",
				      FALSE,
				      G_PARAM_READWRITE |
				      G_PARAM_CONSTRUCT |
				      G_PARAM_STATIC_STRINGS);

	/**
	 * GtkSourceSpaceDrawer:matrix:
	 *
	 * The :matrix property is a #GVariant property to specify where and
	 * what kind of white spaces to draw.
	 *
	 * The #GVariant is of type `"au"`, an array of unsigned integers. Each
	 * integer is a combination of #GtkSourceSpaceTypeFlags. There is one
	 * integer for each #GtkSourceSpaceLocationFlags, in the same order as
	 * they are defined in the enum (%GTK_SOURCE_SPACE_LOCATION_NONE and
	 * %GTK_SOURCE_SPACE_LOCATION_ALL are not taken into account).
	 *
	 * If the array is shorter than the number of locations, then the value
	 * for the missing locations will be %GTK_SOURCE_SPACE_TYPE_NONE.
	 *
	 * By default, %GTK_SOURCE_SPACE_TYPE_ALL is set for all locations.
	 *
	 * Since: 3.24
	 */
	properties[PROP_MATRIX] =
		g_param_spec_variant ("matrix",
				      "Matrix",
				      "",
				      G_VARIANT_TYPE ("au"),
				      get_default_matrix (),
				      G_PARAM_READWRITE |
				      G_PARAM_CONSTRUCT |
				      G_PARAM_STATIC_STRINGS);

	g_object_class_install_properties (object_class, N_PROPERTIES, properties);
}

static void
gtk_source_space_drawer_init (GtkSourceSpaceDrawer *drawer)
{
	drawer->priv = gtk_source_space_drawer_get_instance_private (drawer);

	drawer->priv->matrix = g_new0 (GtkSourceSpaceTypeFlags, get_number_of_locations ());
}

/**
 * gtk_source_space_drawer_new:
 *
 * Creates a new #GtkSourceSpaceDrawer object. Useful for storing space drawing
 * settings independently of a #GtkSourceView.
 *
 * Returns: a new #GtkSourceSpaceDrawer.
 * Since: 3.24
 */
GtkSourceSpaceDrawer *
gtk_source_space_drawer_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_SPACE_DRAWER, NULL);
}

static GtkSourceSpaceLocationFlags
get_nonzero_locations_for_draw_spaces_flags (GtkSourceSpaceDrawer *drawer)
{
	GtkSourceSpaceLocationFlags locations = GTK_SOURCE_SPACE_LOCATION_NONE;
	GtkSourceSpaceTypeFlags types;

	types = gtk_source_space_drawer_get_types_for_locations (drawer, GTK_SOURCE_SPACE_LOCATION_LEADING);
	if (types != GTK_SOURCE_SPACE_TYPE_NONE)
	{
		locations |= GTK_SOURCE_SPACE_LOCATION_LEADING;
	}

	types = gtk_source_space_drawer_get_types_for_locations (drawer, GTK_SOURCE_SPACE_LOCATION_INSIDE_TEXT);
	if (types != GTK_SOURCE_SPACE_TYPE_NONE)
	{
		locations |= GTK_SOURCE_SPACE_LOCATION_INSIDE_TEXT;
	}

	types = gtk_source_space_drawer_get_types_for_locations (drawer, GTK_SOURCE_SPACE_LOCATION_TRAILING);
	if (types != GTK_SOURCE_SPACE_TYPE_NONE)
	{
		locations |= GTK_SOURCE_SPACE_LOCATION_TRAILING;
	}

	return locations;
}

GtkSourceDrawSpacesFlags
_gtk_source_space_drawer_get_flags (GtkSourceSpaceDrawer *drawer)
{
	GtkSourceSpaceLocationFlags locations;
	GtkSourceSpaceTypeFlags common_types;
	GtkSourceDrawSpacesFlags flags = 0;

	g_return_val_if_fail (GTK_SOURCE_IS_SPACE_DRAWER (drawer), 0);

	if (!drawer->priv->enable_matrix)
	{
		return 0;
	}

	locations = get_nonzero_locations_for_draw_spaces_flags (drawer);
	common_types = gtk_source_space_drawer_get_types_for_locations (drawer, locations);

	if (locations & GTK_SOURCE_SPACE_LOCATION_LEADING)
	{
		flags |= GTK_SOURCE_DRAW_SPACES_LEADING;
	}
	if (locations & GTK_SOURCE_SPACE_LOCATION_INSIDE_TEXT)
	{
		flags |= GTK_SOURCE_DRAW_SPACES_TEXT;
	}
	if (locations & GTK_SOURCE_SPACE_LOCATION_TRAILING)
	{
		flags |= GTK_SOURCE_DRAW_SPACES_TRAILING;
	}

	if (common_types & GTK_SOURCE_SPACE_TYPE_SPACE)
	{
		flags |= GTK_SOURCE_DRAW_SPACES_SPACE;
	}
	if (common_types & GTK_SOURCE_SPACE_TYPE_TAB)
	{
		flags |= GTK_SOURCE_DRAW_SPACES_TAB;
	}
	if (common_types & GTK_SOURCE_SPACE_TYPE_NEWLINE)
	{
		flags |= GTK_SOURCE_DRAW_SPACES_NEWLINE;
	}
	if (common_types & GTK_SOURCE_SPACE_TYPE_NBSP)
	{
		flags |= GTK_SOURCE_DRAW_SPACES_NBSP;
	}

	return flags;
}

static GtkSourceSpaceLocationFlags
get_locations_from_draw_spaces_flags (GtkSourceDrawSpacesFlags flags)
{
	GtkSourceSpaceLocationFlags locations = GTK_SOURCE_SPACE_LOCATION_NONE;

	if (flags & GTK_SOURCE_DRAW_SPACES_LEADING)
	{
		locations |= GTK_SOURCE_SPACE_LOCATION_LEADING;
	}
	if (flags & GTK_SOURCE_DRAW_SPACES_TEXT)
	{
		locations |= GTK_SOURCE_SPACE_LOCATION_INSIDE_TEXT;
	}
	if (flags & GTK_SOURCE_DRAW_SPACES_TRAILING)
	{
		locations |= GTK_SOURCE_SPACE_LOCATION_TRAILING;
	}

	if (locations == GTK_SOURCE_SPACE_LOCATION_NONE)
	{
		locations = (GTK_SOURCE_SPACE_LOCATION_LEADING |
			     GTK_SOURCE_SPACE_LOCATION_INSIDE_TEXT |
			     GTK_SOURCE_SPACE_LOCATION_TRAILING);
	}

	return locations;
}

static GtkSourceSpaceTypeFlags
get_space_types_from_draw_spaces_flags (GtkSourceDrawSpacesFlags flags)
{
	GtkSourceSpaceTypeFlags types = GTK_SOURCE_SPACE_TYPE_NONE;

	if (flags & GTK_SOURCE_DRAW_SPACES_SPACE)
	{
		types |= GTK_SOURCE_SPACE_TYPE_SPACE;
	}
	if (flags & GTK_SOURCE_DRAW_SPACES_TAB)
	{
		types |= GTK_SOURCE_SPACE_TYPE_TAB;
	}
	if (flags & GTK_SOURCE_DRAW_SPACES_NEWLINE)
	{
		types |= GTK_SOURCE_SPACE_TYPE_NEWLINE;
	}
	if (flags & GTK_SOURCE_DRAW_SPACES_NBSP)
	{
		types |= GTK_SOURCE_SPACE_TYPE_NBSP;
	}

	return types;
}

void
_gtk_source_space_drawer_set_flags (GtkSourceSpaceDrawer     *drawer,
				    GtkSourceDrawSpacesFlags  flags)
{
	GtkSourceSpaceLocationFlags locations;
	GtkSourceSpaceTypeFlags types;

	g_return_if_fail (GTK_SOURCE_IS_SPACE_DRAWER (drawer));

	gtk_source_space_drawer_set_types_for_locations (drawer,
							 GTK_SOURCE_SPACE_LOCATION_ALL,
							 GTK_SOURCE_SPACE_TYPE_NONE);

	locations = get_locations_from_draw_spaces_flags (flags);
	types = get_space_types_from_draw_spaces_flags (flags);
	gtk_source_space_drawer_set_types_for_locations (drawer, locations, types);

	gtk_source_space_drawer_set_enable_matrix (drawer, TRUE);
}

/**
 * gtk_source_space_drawer_get_types_for_locations:
 * @drawer: a #GtkSourceSpaceDrawer.
 * @locations: one or several #GtkSourceSpaceLocationFlags.
 *
 * If only one location is specified, this function returns what kind of
 * white spaces are drawn at that location. The value is retrieved from the
 * #GtkSourceSpaceDrawer:matrix property.
 *
 * If several locations are specified, this function returns the logical AND for
 * those locations. Which means that if a certain kind of white space is present
 * in the return value, then that kind of white space is drawn at all the
 * specified @locations.
 *
 * Returns: a combination of #GtkSourceSpaceTypeFlags.
 * Since: 3.24
 */
GtkSourceSpaceTypeFlags
gtk_source_space_drawer_get_types_for_locations (GtkSourceSpaceDrawer        *drawer,
						 GtkSourceSpaceLocationFlags  locations)
{
	g_return_val_if_fail (GTK_SOURCE_IS_SPACE_DRAWER (drawer), GTK_SOURCE_SPACE_TYPE_NONE);

	return get_types_at_all_locations (drawer, locations);
}

/**
 * gtk_source_space_drawer_set_types_for_locations:
 * @drawer: a #GtkSourceSpaceDrawer.
 * @locations: one or several #GtkSourceSpaceLocationFlags.
 * @types: a combination of #GtkSourceSpaceTypeFlags.
 *
 * Modifies the #GtkSourceSpaceDrawer:matrix property at the specified
 * @locations.
 *
 * Since: 3.24
 */
void
gtk_source_space_drawer_set_types_for_locations (GtkSourceSpaceDrawer        *drawer,
						 GtkSourceSpaceLocationFlags  locations,
						 GtkSourceSpaceTypeFlags      types)
{
	gint index;
	gint num_locations;
	gboolean changed = FALSE;

	g_return_if_fail (GTK_SOURCE_IS_SPACE_DRAWER (drawer));

	index = 0;
	num_locations = get_number_of_locations ();

	while (locations != 0 && index < num_locations)
	{
		if ((locations & 1) == 1 &&
		    drawer->priv->matrix[index] != types)
		{
			drawer->priv->matrix[index] = types;
			changed = TRUE;
		}

		locations >>= 1;
		index++;
	}

	if (changed)
	{
		g_object_notify_by_pspec (G_OBJECT (drawer), properties[PROP_MATRIX]);
	}
}

/**
 * gtk_source_space_drawer_get_matrix:
 * @drawer: a #GtkSourceSpaceDrawer.
 *
 * Gets the value of the #GtkSourceSpaceDrawer:matrix property, as a #GVariant.
 * An empty array can be returned in case the matrix is a zero matrix.
 *
 * The gtk_source_space_drawer_get_types_for_locations() function may be more
 * convenient to use.
 *
 * Returns: the #GtkSourceSpaceDrawer:matrix value as a new floating #GVariant
 *   instance.
 * Since: 3.24
 */
GVariant *
gtk_source_space_drawer_get_matrix (GtkSourceSpaceDrawer *drawer)
{
	GVariantBuilder builder;
	gint num_locations;
	gint i;

	g_return_val_if_fail (GTK_SOURCE_IS_SPACE_DRAWER (drawer), NULL);

	if (is_zero_matrix (drawer))
	{
		return g_variant_new ("au", NULL);
	}

	g_variant_builder_init (&builder, G_VARIANT_TYPE ("au"));

	num_locations = get_number_of_locations ();

	for (i = 0; i < num_locations; i++)
	{
		GVariant *space_types;

		space_types = g_variant_new_uint32 (drawer->priv->matrix[i]);

		g_variant_builder_add_value (&builder, space_types);
	}

	return g_variant_builder_end (&builder);
}

/**
 * gtk_source_space_drawer_set_matrix:
 * @drawer: a #GtkSourceSpaceDrawer.
 * @matrix: (transfer floating) (nullable): the new matrix value, or %NULL.
 *
 * Sets a new value to the #GtkSourceSpaceDrawer:matrix property, as a
 * #GVariant. If @matrix is %NULL, then an empty array is set.
 *
 * If @matrix is floating, it is consumed.
 *
 * The gtk_source_space_drawer_set_types_for_locations() function may be more
 * convenient to use.
 *
 * Since: 3.24
 */
void
gtk_source_space_drawer_set_matrix (GtkSourceSpaceDrawer *drawer,
				    GVariant             *matrix)
{
	gint num_locations;
	gint index;
	GVariantIter iter;
	gboolean changed = FALSE;

	g_return_if_fail (GTK_SOURCE_IS_SPACE_DRAWER (drawer));

	if (matrix == NULL)
	{
		set_zero_matrix (drawer);
		return;
	}

	g_return_if_fail (g_variant_is_of_type (matrix, G_VARIANT_TYPE ("au")));

	g_variant_iter_init (&iter, matrix);

	num_locations = get_number_of_locations ();
	index = 0;
	while (index < num_locations)
	{
		GVariant *child;
		guint32 space_types;

		child = g_variant_iter_next_value (&iter);
		if (child == NULL)
		{
			break;
		}

		space_types = g_variant_get_uint32 (child);

		if (drawer->priv->matrix[index] != space_types)
		{
			drawer->priv->matrix[index] = space_types;
			changed = TRUE;
		}

		g_variant_unref (child);
		index++;
	}

	while (index < num_locations)
	{
		if (drawer->priv->matrix[index] != 0)
		{
			drawer->priv->matrix[index] = 0;
			changed = TRUE;
		}

		index++;
	}

	if (changed)
	{
		g_object_notify_by_pspec (G_OBJECT (drawer), properties[PROP_MATRIX]);
	}

	if (g_variant_is_floating (matrix))
	{
		g_variant_ref_sink (matrix);
		g_variant_unref (matrix);
	}
}

/**
 * gtk_source_space_drawer_get_enable_matrix:
 * @drawer: a #GtkSourceSpaceDrawer.
 *
 * Returns: whether the #GtkSourceSpaceDrawer:matrix property is enabled.
 * Since: 3.24
 */
gboolean
gtk_source_space_drawer_get_enable_matrix (GtkSourceSpaceDrawer *drawer)
{
	g_return_val_if_fail (GTK_SOURCE_IS_SPACE_DRAWER (drawer), FALSE);

	return drawer->priv->enable_matrix;
}

/**
 * gtk_source_space_drawer_set_enable_matrix:
 * @drawer: a #GtkSourceSpaceDrawer.
 * @enable_matrix: the new value.
 *
 * Sets whether the #GtkSourceSpaceDrawer:matrix property is enabled.
 *
 * Since: 3.24
 */
void
gtk_source_space_drawer_set_enable_matrix (GtkSourceSpaceDrawer *drawer,
					   gboolean              enable_matrix)
{
	g_return_if_fail (GTK_SOURCE_IS_SPACE_DRAWER (drawer));

	enable_matrix = enable_matrix != FALSE;

	if (drawer->priv->enable_matrix != enable_matrix)
	{
		drawer->priv->enable_matrix = enable_matrix;
		g_object_notify_by_pspec (G_OBJECT (drawer), properties[PROP_ENABLE_MATRIX]);
	}
}

static gboolean
matrix_get_mapping (GValue   *value,
		    GVariant *variant,
		    gpointer  user_data)
{
	g_value_set_variant (value, variant);
	return TRUE;
}

static GVariant *
matrix_set_mapping (const GValue       *value,
		    const GVariantType *expected_type,
		    gpointer            user_data)
{
	return g_value_dup_variant (value);
}

/**
 * gtk_source_space_drawer_bind_matrix_setting:
 * @drawer: a #GtkSourceSpaceDrawer object.
 * @settings: a #GSettings object.
 * @key: the @settings key to bind.
 * @flags: flags for the binding.
 *
 * Binds the #GtkSourceSpaceDrawer:matrix property to a #GSettings key.
 *
 * The #GSettings key must be of the same type as the
 * #GtkSourceSpaceDrawer:matrix property, that is, `"au"`.
 *
 * The g_settings_bind() function cannot be used, because the default GIO
 * mapping functions don't support #GVariant properties (maybe it will be
 * supported by a future GIO version, in which case this function can be
 * deprecated).
 *
 * Since: 3.24
 */
void
gtk_source_space_drawer_bind_matrix_setting (GtkSourceSpaceDrawer *drawer,
					     GSettings            *settings,
					     const gchar          *key,
					     GSettingsBindFlags    flags)
{
	GVariant *value;

	g_return_if_fail (GTK_SOURCE_IS_SPACE_DRAWER (drawer));
	g_return_if_fail (G_IS_SETTINGS (settings));
	g_return_if_fail (key != NULL);
	g_return_if_fail ((flags & G_SETTINGS_BIND_INVERT_BOOLEAN) == 0);

	value = g_settings_get_value (settings, key);
	if (!g_variant_is_of_type (value, G_VARIANT_TYPE ("au")))
	{
		g_warning ("%s(): the GSettings key must be of type \"au\".", G_STRFUNC);
		g_variant_unref (value);
		return;
	}
	g_variant_unref (value);

	g_settings_bind_with_mapping (settings, key,
				      drawer, "matrix",
				      flags,
				      matrix_get_mapping,
				      matrix_set_mapping,
				      NULL, NULL);
}

void
_gtk_source_space_drawer_update_color (GtkSourceSpaceDrawer *drawer,
				       GtkSourceView        *view)
{
	GtkSourceBuffer *buffer;
	GtkSourceStyleScheme *style_scheme;

	g_return_if_fail (GTK_SOURCE_IS_SPACE_DRAWER (drawer));
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	if (drawer->priv->color != NULL)
	{
		gdk_rgba_free (drawer->priv->color);
		drawer->priv->color = NULL;
	}

	buffer = GTK_SOURCE_BUFFER (gtk_text_view_get_buffer (GTK_TEXT_VIEW (view)));
	style_scheme = gtk_source_buffer_get_style_scheme (buffer);

	if (style_scheme != NULL)
	{
		GtkSourceStyle *style;

		style = _gtk_source_style_scheme_get_draw_spaces_style (style_scheme);

		if (style != NULL)
		{
			gchar *color_str = NULL;
			gboolean color_set;
			GdkRGBA color;

			g_object_get (style,
				      "foreground", &color_str,
				      "foreground-set", &color_set,
				      NULL);

			if (color_set &&
			    color_str != NULL &&
			    gdk_rgba_parse (&color, color_str))
			{
				drawer->priv->color = gdk_rgba_copy (&color);
			}

			g_free (color_str);
		}
	}

	if (drawer->priv->color == NULL)
	{
		GtkStyleContext *context;
		GdkRGBA color;

		context = gtk_widget_get_style_context (GTK_WIDGET (view));
		gtk_style_context_save (context);
		gtk_style_context_set_state (context, GTK_STATE_FLAG_INSENSITIVE);
		gtk_style_context_get_color (context,
					     gtk_style_context_get_state (context),
					     &color);
		gtk_style_context_restore (context);

		drawer->priv->color = gdk_rgba_copy (&color);
	}
}

static inline gboolean
is_tab (gunichar ch)
{
	return ch == '\t';
}

static inline gboolean
is_nbsp (gunichar ch)
{
	return g_unichar_break_type (ch) == G_UNICODE_BREAK_NON_BREAKING_GLUE;
}

static inline gboolean
is_narrowed_nbsp (gunichar ch)
{
	return ch == 0x202F;
}

static inline gboolean
is_space (gunichar ch)
{
	return g_unichar_type (ch) == G_UNICODE_SPACE_SEPARATOR;
}

static gboolean
is_newline (const GtkTextIter *iter)
{
	if (gtk_text_iter_is_end (iter))
	{
		GtkSourceBuffer *buffer;

		buffer = GTK_SOURCE_BUFFER (gtk_text_iter_get_buffer (iter));

		return gtk_source_buffer_get_implicit_trailing_newline (buffer);
	}

	return gtk_text_iter_ends_line (iter);
}

static inline gboolean
is_whitespace (gunichar ch)
{
	return (g_unichar_isspace (ch) || is_nbsp (ch) || is_space (ch));
}

static void
draw_space_at_pos (cairo_t      *cr,
		   GdkRectangle  rect)
{
	gint x, y;
	gdouble w;

	x = rect.x;
	y = rect.y + rect.height * 2 / 3;

	w = rect.width;

	cairo_save (cr);
	cairo_move_to (cr, x + w * 0.5, y);
	cairo_arc (cr, x + w * 0.5, y, 0.8, 0, 2 * G_PI);
	cairo_stroke (cr);
	cairo_restore (cr);
}

static void
draw_tab_at_pos (cairo_t      *cr,
		 GdkRectangle  rect)
{
	gint x, y;
	gdouble w, h;

	x = rect.x;
	y = rect.y + rect.height * 2 / 3;

	w = rect.width;
	h = rect.height;

	cairo_save (cr);
	cairo_move_to (cr, x + w * 1 / 8, y);
	cairo_rel_line_to (cr, w * 6 / 8, 0);
	cairo_rel_line_to (cr, -h * 1 / 4, -h * 1 / 4);
	cairo_rel_move_to (cr, +h * 1 / 4, +h * 1 / 4);
	cairo_rel_line_to (cr, -h * 1 / 4, +h * 1 / 4);
	cairo_stroke (cr);
	cairo_restore (cr);
}

static void
draw_newline_at_pos (cairo_t      *cr,
		     GdkRectangle  rect)
{
	gint x, y;
	gdouble w, h;

	x = rect.x;
	y = rect.y + rect.height / 3;

	w = 2 * rect.width;
	h = rect.height;

	cairo_save (cr);

	if (gtk_widget_get_default_direction () == GTK_TEXT_DIR_LTR)
	{
		cairo_move_to (cr, x + w * 7 / 8, y);
		cairo_rel_line_to (cr, 0, h * 1 / 3);
		cairo_rel_line_to (cr, -w * 6 / 8, 0);
		cairo_rel_line_to (cr, +h * 1 / 4, -h * 1 / 4);
		cairo_rel_move_to (cr, -h * 1 / 4, +h * 1 / 4);
		cairo_rel_line_to (cr, +h * 1 / 4, +h * 1 / 4);
	}
	else
	{
		cairo_move_to (cr, x + w * 1 / 8, y);
		cairo_rel_line_to (cr, 0, h * 1 / 3);
		cairo_rel_line_to (cr, w * 6 / 8, 0);
		cairo_rel_line_to (cr, -h * 1 / 4, -h * 1 / 4);
		cairo_rel_move_to (cr, +h * 1 / 4, +h * 1 / 4);
		cairo_rel_line_to (cr, -h * 1 / 4, -h * 1 / 4);
	}

	cairo_stroke (cr);
	cairo_restore (cr);
}

static void
draw_nbsp_at_pos (cairo_t      *cr,
		  GdkRectangle  rect,
		  gboolean      narrowed)
{
	gint x, y;
	gdouble w, h;

	x = rect.x;
	y = rect.y + rect.height / 2;

	w = rect.width;
	h = rect.height;

	cairo_save (cr);
	cairo_move_to (cr, x + w * 1 / 6, y);
	cairo_rel_line_to (cr, w * 4 / 6, 0);
	cairo_rel_line_to (cr, -w * 2 / 6, +h * 1 / 4);
	cairo_rel_line_to (cr, -w * 2 / 6, -h * 1 / 4);

	if (narrowed)
	{
		cairo_fill (cr);
	}
	else
	{
		cairo_stroke (cr);
	}

	cairo_restore (cr);
}

static void
draw_whitespace_at_iter (GtkTextView *text_view,
			 GtkTextIter *iter,
			 cairo_t     *cr)
{
	gunichar ch;
	GdkRectangle rect;

	gtk_text_view_get_iter_location (text_view, iter, &rect);

	/* If the space is at a line-wrap position, or if the character is a
	 * newline, we get 0 width so we fallback to the height.
	 */
	if (rect.width == 0)
	{
		rect.width = rect.height;
	}

	ch = gtk_text_iter_get_char (iter);

	if (is_tab (ch))
	{
		draw_tab_at_pos (cr, rect);
	}
	else if (is_nbsp (ch))
	{
		draw_nbsp_at_pos (cr, rect, is_narrowed_nbsp (ch));
	}
	else if (is_space (ch))
	{
		draw_space_at_pos (cr, rect);
	}
	else if (is_newline (iter))
	{
		draw_newline_at_pos (cr, rect);
	}
}

static void
draw_spaces_tag_foreach (GtkTextTag *tag,
			 gboolean   *found)
{
	if (*found)
	{
		return;
	}

	if (GTK_SOURCE_IS_TAG (tag))
	{
		gboolean draw_spaces_set;

		g_object_get (tag,
			      "draw-spaces-set", &draw_spaces_set,
			      NULL);

		if (draw_spaces_set)
		{
			*found = TRUE;
		}
	}
}

static gboolean
buffer_has_draw_spaces_tag (GtkTextBuffer *buffer)
{
	GtkTextTagTable *table;
	gboolean found = FALSE;

	table = gtk_text_buffer_get_tag_table (buffer);
	gtk_text_tag_table_foreach (table,
				    (GtkTextTagTableForeach) draw_spaces_tag_foreach,
				    &found);

	return found;
}

static void
space_needs_drawing_according_to_tag (const GtkTextIter *iter,
				      gboolean          *has_tag,
				      gboolean          *needs_drawing)
{
	GSList *tags;
	GSList *l;

	*has_tag = FALSE;
	*needs_drawing = FALSE;

	tags = gtk_text_iter_get_tags (iter);
	tags = g_slist_reverse (tags);

	for (l = tags; l != NULL; l = l->next)
	{
		GtkTextTag *tag = l->data;

		if (GTK_SOURCE_IS_TAG (tag))
		{
			gboolean draw_spaces_set;
			gboolean draw_spaces;

			g_object_get (tag,
				      "draw-spaces-set", &draw_spaces_set,
				      "draw-spaces", &draw_spaces,
				      NULL);

			if (draw_spaces_set)
			{
				*has_tag = TRUE;
				*needs_drawing = draw_spaces;
				break;
			}
		}
	}

	g_slist_free (tags);
}

static GtkSourceSpaceLocationFlags
get_iter_locations (const GtkTextIter *iter,
		    const GtkTextIter *leading_end,
		    const GtkTextIter *trailing_start)
{
	GtkSourceSpaceLocationFlags iter_locations = GTK_SOURCE_SPACE_LOCATION_NONE;

	if (gtk_text_iter_compare (iter, leading_end) < 0)
	{
		iter_locations |= GTK_SOURCE_SPACE_LOCATION_LEADING;
	}

	if (gtk_text_iter_compare (trailing_start, iter) <= 0)
	{
		iter_locations |= GTK_SOURCE_SPACE_LOCATION_TRAILING;
	}

	/* Neither leading nor trailing, must be in text. */
	if (iter_locations == GTK_SOURCE_SPACE_LOCATION_NONE)
	{
		iter_locations = GTK_SOURCE_SPACE_LOCATION_INSIDE_TEXT;
	}

	return iter_locations;
}

static GtkSourceSpaceTypeFlags
get_iter_space_type (const GtkTextIter *iter)
{
	gunichar ch;

	ch = gtk_text_iter_get_char (iter);

	if (is_tab (ch))
	{
		return GTK_SOURCE_SPACE_TYPE_TAB;
	}
	else if (is_nbsp (ch))
	{
		return GTK_SOURCE_SPACE_TYPE_NBSP;
	}
	else if (is_space (ch))
	{
		return GTK_SOURCE_SPACE_TYPE_SPACE;
	}
	else if (is_newline (iter))
	{
		return GTK_SOURCE_SPACE_TYPE_NEWLINE;
	}

	return GTK_SOURCE_SPACE_TYPE_NONE;
}

static gboolean
space_needs_drawing_according_to_matrix (GtkSourceSpaceDrawer *drawer,
					 const GtkTextIter    *iter,
					 const GtkTextIter    *leading_end,
					 const GtkTextIter    *trailing_start)
{
	GtkSourceSpaceLocationFlags iter_locations;
	GtkSourceSpaceTypeFlags iter_space_type;
	GtkSourceSpaceTypeFlags allowed_space_types;

	iter_locations = get_iter_locations (iter, leading_end, trailing_start);
	iter_space_type = get_iter_space_type (iter);
	allowed_space_types = get_types_at_any_locations (drawer, iter_locations);

	return (iter_space_type & allowed_space_types) != 0;
}

static gboolean
space_needs_drawing (GtkSourceSpaceDrawer *drawer,
		     const GtkTextIter    *iter,
		     const GtkTextIter    *leading_end,
		     const GtkTextIter    *trailing_start)
{
	gboolean has_tag;
	gboolean needs_drawing;

	/* Check the GtkSourceTag:draw-spaces property (higher priority) */
	space_needs_drawing_according_to_tag (iter, &has_tag, &needs_drawing);
	if (has_tag)
	{
		return needs_drawing;
	}

	/* Check the matrix */
	return (drawer->priv->enable_matrix &&
		space_needs_drawing_according_to_matrix (drawer, iter, leading_end, trailing_start));
}

static void
get_line_end (GtkTextView       *text_view,
	      const GtkTextIter *start_iter,
	      GtkTextIter       *line_end,
	      gint               max_x,
	      gint               max_y,
	      gboolean           is_wrapping)
{
	gint min;
	gint max;
	GdkRectangle rect;

	*line_end = *start_iter;
	if (!gtk_text_iter_ends_line (line_end))
	{
		gtk_text_iter_forward_to_line_end (line_end);
	}

	/* Check if line_end is inside the bounding box anyway. */
	gtk_text_view_get_iter_location (text_view, line_end, &rect);
	if (( is_wrapping && rect.y < max_y) ||
	    (!is_wrapping && rect.x < max_x))
	{
		return;
	}

	min = gtk_text_iter_get_line_offset (start_iter);
	max = gtk_text_iter_get_line_offset (line_end);

	while (max >= min)
	{
		gint i;

		i = (min + max) >> 1;
		gtk_text_iter_set_line_offset (line_end, i);
		gtk_text_view_get_iter_location (text_view, line_end, &rect);

		if (( is_wrapping && rect.y < max_y) ||
		    (!is_wrapping && rect.x < max_x))
		{
			min = i + 1;
		}
		else if (( is_wrapping && rect.y > max_y) ||
			 (!is_wrapping && rect.x > max_x))
		{
			max = i - 1;
		}
		else
		{
			break;
		}
	}
}

void
_gtk_source_space_drawer_draw (GtkSourceSpaceDrawer *drawer,
			       GtkSourceView        *view,
			       cairo_t              *cr)
{
	GtkTextView *text_view;
	GtkTextBuffer *buffer;
	GdkRectangle clip;
	gint min_x;
	gint min_y;
	gint max_x;
	gint max_y;
	GtkTextIter start;
	GtkTextIter end;
	GtkTextIter iter;
	GtkTextIter leading_end;
	GtkTextIter trailing_start;
	GtkTextIter line_end;
	gboolean is_wrapping;

#ifdef ENABLE_PROFILE
	static GTimer *timer = NULL;
	if (timer == NULL)
	{
		timer = g_timer_new ();
	}

	g_timer_start (timer);
#endif

	g_return_if_fail (GTK_SOURCE_IS_SPACE_DRAWER (drawer));
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));
	g_return_if_fail (cr != NULL);

	if (drawer->priv->color == NULL)
	{
		g_warning ("GtkSourceSpaceDrawer: color not set.");
		return;
	}

	text_view = GTK_TEXT_VIEW (view);
	buffer = gtk_text_view_get_buffer (text_view);

	if ((!drawer->priv->enable_matrix || is_zero_matrix (drawer)) &&
	    !buffer_has_draw_spaces_tag (buffer))
	{
		return;
	}

	if (!gdk_cairo_get_clip_rectangle (cr, &clip))
	{
		return;
	}

	is_wrapping = gtk_text_view_get_wrap_mode (text_view) != GTK_WRAP_NONE;

	min_x = clip.x;
	min_y = clip.y;
	max_x = min_x + clip.width;
	max_y = min_y + clip.height;

	gtk_text_view_get_iter_at_location (text_view, &start, min_x, min_y);
	gtk_text_view_get_iter_at_location (text_view, &end, max_x, max_y);

	cairo_save (cr);
	gdk_cairo_set_source_rgba (cr, drawer->priv->color);
	cairo_set_line_width (cr, 0.8);
	cairo_translate (cr, -0.5, -0.5);

	iter = start;
	_gtk_source_iter_get_leading_spaces_end_boundary (&iter, &leading_end);
	_gtk_source_iter_get_trailing_spaces_start_boundary (&iter, &trailing_start);
	get_line_end (text_view, &iter, &line_end, max_x, max_y, is_wrapping);

	while (TRUE)
	{
		gunichar ch = gtk_text_iter_get_char (&iter);
		gint ly;

		/* Allow end iter, to draw implicit trailing newline. */
		if ((is_whitespace (ch) || gtk_text_iter_is_end (&iter)) &&
		    space_needs_drawing (drawer, &iter, &leading_end, &trailing_start))
		{
			draw_whitespace_at_iter (text_view, &iter, cr);
		}

		if (gtk_text_iter_is_end (&iter) ||
		    gtk_text_iter_compare (&iter, &end) >= 0)
		{
			break;
		}

		gtk_text_iter_forward_char (&iter);

		if (gtk_text_iter_compare (&iter, &line_end) > 0)
		{
			GtkTextIter next_iter = iter;

			/* Move to the first iter in the exposed area of the
			 * next line.
			 */
			if (!gtk_text_iter_starts_line (&next_iter))
			{
				/* We're trying to move forward on the last
				 * line of the buffer, so we can stop now.
				 */
				if (!gtk_text_iter_forward_line (&next_iter))
				{
					break;
				}
			}

			gtk_text_view_get_line_yrange (text_view, &next_iter, &ly, NULL);
			gtk_text_view_get_iter_at_location (text_view, &next_iter, min_x, ly);

			/* Move back one char otherwise tabs may not be redrawn. */
			if (!gtk_text_iter_starts_line (&next_iter))
			{
				gtk_text_iter_backward_char (&next_iter);
			}

			/* Ensure that we have actually advanced, since the
			 * above backward_char() is dangerous and can lead to
			 * infinite loops.
			 */
			if (gtk_text_iter_compare (&next_iter, &iter) > 0)
			{
				iter = next_iter;
			}

			_gtk_source_iter_get_leading_spaces_end_boundary (&iter, &leading_end);
			_gtk_source_iter_get_trailing_spaces_start_boundary (&iter, &trailing_start);
			get_line_end (text_view, &iter, &line_end, max_x, max_y, is_wrapping);
		}
	};

	cairo_restore (cr);

#ifdef ENABLE_PROFILE
	g_timer_stop (timer);

	/* Same indentation as similar features in gtksourceview.c. */
	g_print ("    %s time: %g (sec * 1000)\n",
		 G_STRFUNC,
		 g_timer_elapsed (timer, NULL) * 1000);
#endif
}
