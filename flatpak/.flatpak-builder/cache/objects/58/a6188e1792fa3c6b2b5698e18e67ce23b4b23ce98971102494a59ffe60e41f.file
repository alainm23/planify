/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcestyle.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2003 - Paolo Maggi <paolo.maggi@polito.it>
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

#include "gtksourcestyle.h"
#include "gtksourcestyle-private.h"
#include "gtksourceview-i18n.h"

/**
 * SECTION:style
 * @Short_description: Represents a style
 * @Title: GtkSourceStyle
 * @See_also: #GtkSourceStyleScheme, #GtkSourceStyleSchemeManager
 *
 * The #GtkSourceStyle structure is used to describe text attributes
 * which are set when given style is used.
 */

static void	gtk_source_style_set_property	(GObject      *object,
						 guint         prop_id,
						 const GValue *value,
						 GParamSpec   *pspec);

static void	gtk_source_style_get_property	(GObject      *object,
						 guint         prop_id,
						 GValue       *value,
						 GParamSpec   *pspec);

struct _GtkSourceStyleClass
{
	GObjectClass parent_class;
};

G_DEFINE_TYPE (GtkSourceStyle, gtk_source_style, G_TYPE_OBJECT)

enum
{
	PROP_0,
	PROP_LINE_BACKGROUND,
	PROP_LINE_BACKGROUND_SET,
	PROP_BACKGROUND,
	PROP_BACKGROUND_SET,
	PROP_FOREGROUND,
	PROP_FOREGROUND_SET,
	PROP_BOLD,
	PROP_BOLD_SET,
	PROP_ITALIC,
	PROP_ITALIC_SET,
	PROP_UNDERLINE,
	PROP_PANGO_UNDERLINE,
	PROP_UNDERLINE_SET,
	PROP_STRIKETHROUGH,
	PROP_STRIKETHROUGH_SET,
	PROP_SCALE,
	PROP_SCALE_SET,
	PROP_UNDERLINE_COLOR,
	PROP_UNDERLINE_COLOR_SET
};

static void
gtk_source_style_class_init (GtkSourceStyleClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->set_property = gtk_source_style_set_property;
	object_class->get_property = gtk_source_style_get_property;

	/* All properties are CONSTRUCT_ONLY so we can safely return references
	 * from style_scheme_get_style(). But style scheme is of course cheating
	 * and sets everything after construction (but nobody can notice it). */

	g_object_class_install_property (object_class,
					 PROP_LINE_BACKGROUND,
					 g_param_spec_string ("line-background",
							      "Line background",
							      "Line background color",
							      NULL,
							      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_BACKGROUND,
					 g_param_spec_string ("background",
							      "Background",
							      "Background color",
							      NULL,
							      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_FOREGROUND,
					 g_param_spec_string ("foreground",
							      "Foreground",
							      "Foreground color",
							      NULL,
							      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_BOLD,
					 g_param_spec_boolean ("bold",
							       "Bold",
							       "Bold",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_ITALIC,
					 g_param_spec_boolean ("italic",
							       "Italic",
							       "Italic",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	/**
	 * GtkSourceStyle:underline
	 *
	 * Deprecated: 3.18: Use pango-underline.
	 */
	g_object_class_install_property (object_class,
					 PROP_UNDERLINE,
					 g_param_spec_boolean ("underline",
							       "Underline",
							       "Underline",
							       FALSE,
							       G_PARAM_READWRITE |
							       G_PARAM_CONSTRUCT_ONLY |
							       G_PARAM_DEPRECATED));

	g_object_class_install_property (object_class,
					 PROP_PANGO_UNDERLINE,
					 g_param_spec_enum ("pango-underline",
							    "Pango Underline",
							    "Pango Underline",
							    PANGO_TYPE_UNDERLINE,
							    PANGO_UNDERLINE_NONE,
							    G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_STRIKETHROUGH,
					 g_param_spec_boolean ("strikethrough",
							       "Strikethrough",
							       "Strikethrough",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_SCALE,
					 g_param_spec_string ("scale",
							      "Scale",
							      "Text scale factor",
							      NULL,
							      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_UNDERLINE_COLOR,
					 g_param_spec_string ("underline-color",
							      "Underline Color",
							      "Underline color",
							      NULL,
							      G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_LINE_BACKGROUND_SET,
					 g_param_spec_boolean ("line-background-set",
							       "Line background set",
							       "Whether line background color is set",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_FOREGROUND_SET,
					 g_param_spec_boolean ("foreground-set",
							       "Foreground set",
							       "Whether foreground color is set",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_BACKGROUND_SET,
					 g_param_spec_boolean ("background-set",
							       "Background set",
							       "Whether background color is set",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_BOLD_SET,
					 g_param_spec_boolean ("bold-set",
							       "Bold set",
							       "Whether bold attribute is set",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_ITALIC_SET,
					 g_param_spec_boolean ("italic-set",
							       "Italic set",
							       "Whether italic attribute is set",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_UNDERLINE_SET,
					 g_param_spec_boolean ("underline-set",
							       "Underline set",
							       "Whether underline attribute is set",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_STRIKETHROUGH_SET,
					 g_param_spec_boolean ("strikethrough-set",
							       "Strikethrough set",
							       "Whether strikethrough attribute is set",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_SCALE_SET,
					 g_param_spec_boolean ("scale-set",
							       "Scale set",
							       "Whether scale attribute is set",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (object_class,
					 PROP_UNDERLINE_COLOR_SET,
					 g_param_spec_boolean ("underline-color-set",
							       "Underline color set",
							       "Whether underline color attribute is set",
							       FALSE,
							       G_PARAM_READWRITE | G_PARAM_CONSTRUCT_ONLY));
}

static void
gtk_source_style_init (GtkSourceStyle *style)
{
	style->foreground = NULL;
	style->background = NULL;
	style->line_background = NULL;
}

#define SET_MASK(style,name) (style)->mask |= (GTK_SOURCE_STYLE_USE_##name)
#define UNSET_MASK(style,name) (style)->mask &= (GTK_SOURCE_STYLE_USE_##name)

#define MODIFY_MASK(style,value,name)		\
G_STMT_START {					\
	if (g_value_get_boolean (value))	\
		SET_MASK (style, name);		\
	else					\
		UNSET_MASK (style, name);	\
} G_STMT_END

#define GET_MASK(style,value,name)		\
	g_value_set_boolean (value, ((style)->mask & GTK_SOURCE_STYLE_USE_##name) != 0)

static void
gtk_source_style_set_property (GObject      *object,
			       guint         prop_id,
			       const GValue *value,
			       GParamSpec   *pspec)
{
	GtkSourceStyle *style = GTK_SOURCE_STYLE (object);
	const gchar *string;

	switch (prop_id)
	{
		case PROP_FOREGROUND:
			string = g_value_get_string (value);
			if (string != NULL)
			{
				style->foreground = g_intern_string (string);
				SET_MASK (style, FOREGROUND);
			}
			else
			{
				style->foreground = NULL;
				UNSET_MASK (style, FOREGROUND);
			}
			break;

		case PROP_BACKGROUND:
			string = g_value_get_string (value);
			if (string != NULL)
			{
				style->background = g_intern_string (string);
				SET_MASK (style, BACKGROUND);
			}
			else
			{
				style->background = NULL;
				UNSET_MASK (style, BACKGROUND);
			}
			break;

		case PROP_LINE_BACKGROUND:
			string = g_value_get_string (value);
			if (string != NULL)
			{
				style->line_background = g_intern_string (string);
				SET_MASK (style, LINE_BACKGROUND);
			}
			else
			{
				style->line_background = NULL;
				UNSET_MASK (style, LINE_BACKGROUND);
			}
			break;

		case PROP_BOLD:
			style->bold = g_value_get_boolean (value) != 0;
			SET_MASK (style, BOLD);
			break;

		case PROP_ITALIC:
			style->italic = g_value_get_boolean (value) != 0;
			SET_MASK (style, ITALIC);
			break;

		case PROP_UNDERLINE:
			style->underline = g_value_get_boolean (value) ? PANGO_UNDERLINE_SINGLE : PANGO_UNDERLINE_NONE;
			SET_MASK (style, UNDERLINE);
			break;

		case PROP_PANGO_UNDERLINE:
			style->underline = (PangoUnderline) g_value_get_enum (value);
			SET_MASK (style, UNDERLINE);
			break;

		case PROP_STRIKETHROUGH:
			style->strikethrough = g_value_get_boolean (value) != 0;
			SET_MASK (style, STRIKETHROUGH);
			break;

		case PROP_SCALE:
			string = g_value_get_string (value);
			if (string != NULL)
			{
				style->scale = g_intern_string (string);
				SET_MASK (style, SCALE);
			}
			else
			{
				style->scale = NULL;
				UNSET_MASK (style, SCALE);
			}
			break;

		case PROP_UNDERLINE_COLOR:
			string = g_value_get_string (value);
			if (string != NULL)
			{
				style->underline_color = g_intern_string (string);
				SET_MASK (style, UNDERLINE_COLOR);
			}
			else
			{
				style->underline_color = NULL;
				UNSET_MASK (style, UNDERLINE_COLOR);
			}
			break;

		case PROP_FOREGROUND_SET:
			MODIFY_MASK (style, value, FOREGROUND);
			break;

		case PROP_BACKGROUND_SET:
			MODIFY_MASK (style, value, BACKGROUND);
			break;

		case PROP_LINE_BACKGROUND_SET:
			MODIFY_MASK (style, value, LINE_BACKGROUND);
			break;

		case PROP_BOLD_SET:
			MODIFY_MASK (style, value, BOLD);
			break;

		case PROP_ITALIC_SET:
			MODIFY_MASK (style, value, ITALIC);
			break;

		case PROP_UNDERLINE_SET:
			MODIFY_MASK (style, value, UNDERLINE);
			break;

		case PROP_STRIKETHROUGH_SET:
			MODIFY_MASK (style, value, STRIKETHROUGH);
			break;

		case PROP_SCALE_SET:
			MODIFY_MASK (style, value, SCALE);
			break;

		case PROP_UNDERLINE_COLOR_SET:
			MODIFY_MASK (style, value, UNDERLINE_COLOR);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_style_get_property (GObject      *object,
			       guint         prop_id,
			       GValue       *value,
			       GParamSpec   *pspec)
{
	GtkSourceStyle *style = GTK_SOURCE_STYLE (object);

	switch (prop_id)
	{
		case PROP_FOREGROUND:
			g_value_set_string (value, style->foreground);
			break;

		case PROP_BACKGROUND:
			g_value_set_string (value, style->background);
			break;

		case PROP_LINE_BACKGROUND:
			g_value_set_string (value, style->line_background);
			break;

		case PROP_BOLD:
			g_value_set_boolean (value, style->bold);
			break;

		case PROP_ITALIC:
			g_value_set_boolean (value, style->italic);
			break;

		case PROP_UNDERLINE:
			g_value_set_boolean (value, style->underline != PANGO_UNDERLINE_NONE);
			break;

		case PROP_PANGO_UNDERLINE:
			g_value_set_enum (value, style->underline);
			break;

		case PROP_STRIKETHROUGH:
			g_value_set_boolean (value, style->strikethrough);
			break;

		case PROP_SCALE:
			g_value_set_string (value, style->scale);
			break;

		case PROP_UNDERLINE_COLOR:
			g_value_set_string (value, style->underline_color);
			break;

		case PROP_FOREGROUND_SET:
			GET_MASK (style, value, FOREGROUND);
			break;

		case PROP_BACKGROUND_SET:
			GET_MASK (style, value, BACKGROUND);
			break;

		case PROP_LINE_BACKGROUND_SET:
			GET_MASK (style, value, LINE_BACKGROUND);
			break;

		case PROP_BOLD_SET:
			GET_MASK (style, value, BOLD);
			break;

		case PROP_ITALIC_SET:
			GET_MASK (style, value, ITALIC);
			break;

		case PROP_UNDERLINE_SET:
			GET_MASK (style, value, UNDERLINE);
			break;

		case PROP_STRIKETHROUGH_SET:
			GET_MASK (style, value, STRIKETHROUGH);
			break;

		case PROP_SCALE_SET:
			GET_MASK (style, value, SCALE);
			break;

		case PROP_UNDERLINE_COLOR_SET:
			GET_MASK (style, value, UNDERLINE_COLOR);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

/**
 * gtk_source_style_copy:
 * @style: a #GtkSourceStyle structure to copy.
 *
 * Creates a copy of @style, that is a new #GtkSourceStyle instance which
 * has the same attributes set.
 *
 * Returns: (transfer full): copy of @style, call g_object_unref()
 * when you are done with it.
 *
 * Since: 2.0
 */
GtkSourceStyle *
gtk_source_style_copy (const GtkSourceStyle *style)
{
	GtkSourceStyle *copy;

	g_return_val_if_fail (style != NULL, NULL);

	copy = g_object_new (GTK_SOURCE_TYPE_STYLE, NULL);

	copy->foreground = style->foreground;
	copy->background = style->background;
	copy->line_background = style->line_background;
	copy->italic = style->italic;
	copy->bold = style->bold;
	copy->underline = style->underline;
	copy->underline_color = style->underline_color;
	copy->strikethrough = style->strikethrough;
	copy->mask = style->mask;
	copy->scale = style->scale;

	return copy;
}

/**
 * gtk_source_style_apply:
 * @style: (nullable): a #GtkSourceStyle to apply, or %NULL.
 * @tag: a #GtkTextTag to apply styles to.
 *
 * This function modifies the #GtkTextTag properties that are related to the
 * #GtkSourceStyle properties. Other #GtkTextTag properties are left untouched.
 *
 * If @style is non-%NULL, applies @style to @tag.
 *
 * If @style is %NULL, the related *-set properties of #GtkTextTag are set to
 * %FALSE.
 *
 * Since: 3.22
 */
void
gtk_source_style_apply (const GtkSourceStyle *style,
			GtkTextTag           *tag)
{
	g_return_if_fail (GTK_IS_TEXT_TAG (tag));

	if (style != NULL)
	{
		g_object_freeze_notify (G_OBJECT (tag));

		if (style->mask & GTK_SOURCE_STYLE_USE_BACKGROUND)
		{
			g_object_set (tag, "background", style->background, NULL);
		}
		else
		{
			g_object_set (tag, "background-set", FALSE, NULL);
		}

		if (style->mask & GTK_SOURCE_STYLE_USE_FOREGROUND)
		{
			g_object_set (tag, "foreground", style->foreground, NULL);
		}
		else
		{
			g_object_set (tag, "foreground-set", FALSE, NULL);
		}

		if (style->mask & GTK_SOURCE_STYLE_USE_LINE_BACKGROUND)
		{
			g_object_set (tag, "paragraph-background", style->line_background, NULL);
		}
		else
		{
			g_object_set (tag, "paragraph-background-set", FALSE, NULL);
		}

		if (style->mask & GTK_SOURCE_STYLE_USE_ITALIC)
		{
			g_object_set (tag, "style", style->italic ? PANGO_STYLE_ITALIC : PANGO_STYLE_NORMAL, NULL);
		}
		else
		{
			g_object_set (tag, "style-set", FALSE, NULL);
		}

		if (style->mask & GTK_SOURCE_STYLE_USE_BOLD)
		{
			g_object_set (tag, "weight", style->bold ? PANGO_WEIGHT_BOLD : PANGO_WEIGHT_NORMAL, NULL);
		}
		else
		{
			g_object_set (tag, "weight-set", FALSE, NULL);
		}

		if (style->mask & GTK_SOURCE_STYLE_USE_UNDERLINE)
		{
			g_object_set (tag, "underline", style->underline, NULL);
		}
		else
		{
			g_object_set (tag, "underline-set", FALSE, NULL);
		}

		if (style->mask & GTK_SOURCE_STYLE_USE_UNDERLINE_COLOR)
		{
			GdkRGBA underline_rgba;

			gdk_rgba_parse (&underline_rgba, style->underline_color);
			g_object_set (tag, "underline-rgba", &underline_rgba, NULL);
		}
		else
		{
			g_object_set (tag, "underline-rgba-set", FALSE, NULL);
		}

		if (style->mask & GTK_SOURCE_STYLE_USE_STRIKETHROUGH)
		{
			g_object_set (tag, "strikethrough", style->strikethrough != 0, NULL);
		}
		else
		{
			g_object_set (tag, "strikethrough-set", FALSE, NULL);
		}

		if (style->mask & GTK_SOURCE_STYLE_USE_SCALE)
		{
			if (g_ascii_strcasecmp (style->scale, "large") == 0)
			{
				g_object_set (tag, "scale", PANGO_SCALE_LARGE, NULL);
			}
			else if (g_ascii_strcasecmp (style->scale, "x-large") == 0)
			{
				g_object_set (tag, "scale", PANGO_SCALE_X_LARGE, NULL);
			}
			else if (g_ascii_strcasecmp (style->scale, "xx-large") == 0)
			{
				g_object_set (tag, "scale", PANGO_SCALE_XX_LARGE, NULL);
			}
			else if (g_ascii_strcasecmp (style->scale, "small") == 0)
			{
				g_object_set (tag, "scale", PANGO_SCALE_SMALL, NULL);
			}
			else if (g_ascii_strcasecmp (style->scale, "x-small") == 0)
			{
				g_object_set (tag, "scale", PANGO_SCALE_X_SMALL, NULL);
			}
			else if (g_ascii_strcasecmp (style->scale, "xx-small") == 0)
			{
				g_object_set (tag, "scale", PANGO_SCALE_XX_SMALL, NULL);
			}
			else if (g_ascii_strcasecmp (style->scale, "medium") == 0)
			{
				g_object_set (tag, "scale", PANGO_SCALE_MEDIUM, NULL);
			}
			else if (g_ascii_strtod (style->scale, NULL) > 0)
			{
				g_object_set (tag, "scale", g_ascii_strtod (style->scale, NULL), NULL);
			}
			else
			{
				g_object_set (tag, "scale-set", FALSE, NULL);
			}
		}
		else
		{
			g_object_set (tag, "scale-set", FALSE, NULL);
		}

		g_object_thaw_notify (G_OBJECT (tag));
	}
	else
	{
		g_object_set (tag,
			      "background-set", FALSE,
			      "foreground-set", FALSE,
			      "paragraph-background-set", FALSE,
			      "style-set", FALSE,
			      "weight-set", FALSE,
			      "underline-set", FALSE,
			      "underline-rgba-set", FALSE,
			      "strikethrough-set", FALSE,
			      "scale-set", FALSE,
			      NULL);
	}
}
