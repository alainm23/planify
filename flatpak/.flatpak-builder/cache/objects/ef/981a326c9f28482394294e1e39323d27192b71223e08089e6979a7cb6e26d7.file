/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcetag.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2015 - Université Catholique de Louvain
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
 *
 * Author: Sébastien Wilmet
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcetag.h"

/**
 * SECTION:tag
 * @Short_description: A tag that can be applied to text in a GtkSourceBuffer
 * @Title: GtkSourceTag
 * @See_also: #GtkSourceBuffer
 *
 * #GtkSourceTag is a subclass of #GtkTextTag that adds properties useful for
 * the GtkSourceView library.
 *
 * If, for a certain tag, #GtkTextTag is sufficient, it's better that you create
 * a #GtkTextTag, not a #GtkSourceTag.
 */

typedef struct _GtkSourceTagPrivate GtkSourceTagPrivate;

struct _GtkSourceTagPrivate
{
	guint draw_spaces : 1;
	guint draw_spaces_set : 1;
};

enum
{
	PROP_0,
	PROP_DRAW_SPACES,
	PROP_DRAW_SPACES_SET,
};

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceTag, gtk_source_tag, GTK_TYPE_TEXT_TAG)

static void
gtk_source_tag_get_property (GObject    *object,
			     guint       prop_id,
			     GValue     *value,
			     GParamSpec *pspec)
{
	GtkSourceTagPrivate *priv;

	priv = gtk_source_tag_get_instance_private (GTK_SOURCE_TAG (object));

	switch (prop_id)
	{
		case PROP_DRAW_SPACES:
			g_value_set_boolean (value, priv->draw_spaces);
			break;

		case PROP_DRAW_SPACES_SET:
			g_value_set_boolean (value, priv->draw_spaces_set);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_tag_set_property (GObject      *object,
			     guint         prop_id,
			     const GValue *value,
			     GParamSpec   *pspec)
{
	GtkSourceTag *tag;
	GtkSourceTagPrivate *priv;
	gboolean size_changed = FALSE;

	tag = GTK_SOURCE_TAG (object);
	priv = gtk_source_tag_get_instance_private (tag);

	switch (prop_id)
	{
		case PROP_DRAW_SPACES:
			priv->draw_spaces = g_value_get_boolean (value);
			priv->draw_spaces_set = TRUE;
			g_object_notify (object, "draw-spaces-set");
			break;

		case PROP_DRAW_SPACES_SET:
			priv->draw_spaces_set = g_value_get_boolean (value);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}

	gtk_text_tag_changed (GTK_TEXT_TAG (tag), size_changed);
}

static void
gtk_source_tag_class_init (GtkSourceTagClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->get_property = gtk_source_tag_get_property;
	object_class->set_property = gtk_source_tag_set_property;

	/**
	 * GtkSourceTag:draw-spaces:
	 *
	 * Whether to draw white spaces. This property takes precedence over the value
	 * defined by the GtkSourceSpaceDrawer's #GtkSourceSpaceDrawer:matrix property
	 * (only where the tag is applied).
	 *
	 * Setting this property also changes #GtkSourceTag:draw-spaces-set to
	 * %TRUE.
	 *
	 * Since: 3.20
	 */
	g_object_class_install_property (object_class,
					 PROP_DRAW_SPACES,
					 g_param_spec_boolean ("draw-spaces",
							       "Draw Spaces",
							       "",
							       FALSE,
							       G_PARAM_READWRITE |
							       G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceTag:draw-spaces-set:
	 *
	 * Whether the #GtkSourceTag:draw-spaces property is set and must be
	 * taken into account.
	 *
	 * Since: 3.20
	 */
	g_object_class_install_property (object_class,
					 PROP_DRAW_SPACES_SET,
					 g_param_spec_boolean ("draw-spaces-set",
							       "Draw Spaces Set",
							       "",
							       FALSE,
							       G_PARAM_READWRITE |
							       G_PARAM_STATIC_STRINGS));
}

static void
gtk_source_tag_init (GtkSourceTag *tag)
{
}

/**
 * gtk_source_tag_new:
 * @name: (nullable): tag name, or %NULL.
 *
 * Creates a #GtkSourceTag. Configure the tag using object arguments,
 * i.e. using g_object_set().
 *
 * For usual cases, gtk_source_buffer_create_source_tag() is more convenient to
 * use.
 *
 * Returns: a new #GtkSourceTag.
 * Since: 3.20
 */
GtkTextTag *
gtk_source_tag_new (const gchar *name)
{
	return g_object_new (GTK_SOURCE_TYPE_TAG,
			     "name", name,
			     NULL);
}
