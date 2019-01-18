/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2017 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * SECTION:as-context
 * @short_description: Context of an AppStream metadata document
 * @include: appstream.h
 *
 * Contains information about the context of AppStream metadata, from the
 * root node of the document.
 * This is a private/internal class.
 */

#include "config.h"
#include "as-context.h"

#include "as-utils-private.h"

typedef struct
{
	AsFormatVersion		format_version;
	AsFormatStyle		style;
	gchar 			*locale;
	gchar 			*origin;
	gchar 			*media_baseurl;
	gchar 			*arch;
	gchar			*fname;
	gint 			priority;

	gboolean		all_locale;
} AsContextPrivate;

G_DEFINE_TYPE_WITH_PRIVATE (AsContext, as_context, G_TYPE_OBJECT)

#define GET_PRIVATE(o) (as_context_get_instance_private (o))

static void
as_context_finalize (GObject *object)
{
	AsContext *ctx = AS_CONTEXT (object);
	AsContextPrivate *priv = GET_PRIVATE (ctx);

	g_free (priv->locale);
	g_free (priv->origin);
	g_free (priv->media_baseurl);
	g_free (priv->arch);
	g_free (priv->fname);

	G_OBJECT_CLASS (as_context_parent_class)->finalize (object);
}

static void
as_context_init (AsContext *ctx)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);

	priv->format_version = AS_CURRENT_FORMAT_VERSION;
	priv->style = AS_FORMAT_STYLE_UNKNOWN;
	priv->fname = g_strdup (":memory:");
	priv->priority = 0;
}

static void
as_context_class_init (AsContextClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);
	object_class->finalize = as_context_finalize;
}

/**
 * as_context_get_format_version:
 * @ctx: a #AsContext instance.
 *
 * Returns: The AppStream format version.
 **/
AsFormatVersion
as_context_get_format_version (AsContext *ctx)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	return priv->format_version;
}

/**
 * as_context_set_format_version:
 * @ctx: a #AsContext instance.
 * @ver: the new format version.
 *
 * Sets the AppStream format version.
 **/
void
as_context_set_format_version (AsContext *ctx, AsFormatVersion ver)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	priv->format_version = ver;
}

/**
 * as_context_get_style:
 * @ctx: a #AsContext instance.
 *
 * Returns: The document style.
 **/
AsFormatStyle
as_context_get_style (AsContext *ctx)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	return priv->style;
}

/**
 * as_context_set_style:
 * @ctx: a #AsContext instance.
 * @style: the new document style.
 *
 * Sets the AppStream document style.
 **/
void
as_context_set_style (AsContext *ctx, AsFormatStyle style)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	priv->style = style;
}

/**
 * as_context_get_priority:
 * @ctx: a #AsContext instance.
 *
 * Returns: The data priority.
 **/
gint
as_context_get_priority (AsContext *ctx)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	return priv->priority;
}

/**
 * as_context_set_priority:
 * @ctx: a #AsContext instance.
 * @priority: the new priority.
 *
 * Sets the data priority.
 **/
void
as_context_set_priority (AsContext *ctx, gint priority)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	priv->priority = priority;
}

/**
 * as_context_get_origin:
 * @ctx: a #AsContext instance.
 *
 * Returns: The data origin.
 **/
const gchar*
as_context_get_origin (AsContext *ctx)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	return priv->origin;
}

/**
 * as_context_set_origin:
 * @ctx: a #AsContext instance.
 * @value: the new value.
 *
 * Sets the data origin.
 **/
void
as_context_set_origin (AsContext *ctx, const gchar *value)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	g_free (priv->origin);
	priv->origin = g_strdup (value);
}

/**
 * as_context_get_locale:
 * @ctx: a #AsContext instance.
 *
 * Returns: The active locale.
 **/
const gchar*
as_context_get_locale (AsContext *ctx)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	return priv->locale;
}

/**
 * as_context_set_locale:
 * @ctx: a #AsContext instance.
 * @value: the new value.
 *
 * Sets the active locale.
 **/
void
as_context_set_locale (AsContext *ctx, const gchar *value)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	g_free (priv->locale);

	priv->all_locale = FALSE;
	if (g_strcmp0 (value, "ALL") == 0) {
		priv->all_locale = TRUE;
		priv->locale = as_get_current_locale ();
	} else {
		priv->locale = g_strdup (value);
	}
}

/**
 * as_context_get_all_locale_enabled:
 * @ctx: a #AsContext instance.
 *
 * Returns: %TRUE if all locale should be parsed.
 **/
gboolean
as_context_get_all_locale_enabled (AsContext *ctx)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	return priv->all_locale;
}

/**
 * as_context_has_media_baseurl:
 * @ctx: a #AsContext instance.
 *
 * Returns: %TRUE if a media base URL is set.
 **/
gboolean
as_context_has_media_baseurl (AsContext *ctx)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	return priv->media_baseurl != NULL;
}

/**
 * as_context_get_media_baseurl:
 * @ctx: a #AsContext instance.
 *
 * Returns: The media base URL.
 **/
const gchar*
as_context_get_media_baseurl (AsContext *ctx)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	return priv->media_baseurl;
}

/**
 * as_context_set_media_baseurl:
 * @ctx: a #AsContext instance.
 * @value: the new value.
 *
 * Sets the media base URL.
 **/
void
as_context_set_media_baseurl (AsContext *ctx, const gchar *value)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	g_free (priv->media_baseurl);
	priv->media_baseurl = g_strdup (value);
}

/**
 * as_context_get_architecture:
 * @ctx: a #AsContext instance.
 *
 * Returns: The current architecture for the document.
 **/
const gchar*
as_context_get_architecture (AsContext *ctx)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	return priv->arch;
}

/**
 * as_context_set_architecture:
 * @ctx: a #AsContext instance.
 * @value: the new value.
 *
 * Sets the current architecture for this document.
 **/
void
as_context_set_architecture (AsContext *ctx, const gchar *value)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	g_free (priv->arch);
	priv->arch = g_strdup (value);
}

/**
 * as_context_get_filename:
 * @ctx: a #AsContext instance.
 *
 * Returns: The name of the file the data originates from.
 **/
const gchar*
as_context_get_filename (AsContext *ctx)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	return priv->fname;
}

/**
 * as_context_set_filename:
 * @ctx: a #AsContext instance.
 * @fname: the new file name.
 *
 * Sets the file name we are loading data from.
 **/
void
as_context_set_filename (AsContext *ctx, const gchar *fname)
{
	AsContextPrivate *priv = GET_PRIVATE (ctx);
	g_free (priv->fname);
	priv->fname = g_strdup (fname);
}

/**
 * as_context_new:
 *
 * Creates a new #AsContext.
 *
 * Returns: (transfer full): an #AsContext
 **/
AsContext*
as_context_new (void)
{
	AsContext *ctx;
	ctx = g_object_new (AS_TYPE_CONTEXT, NULL);
	return AS_CONTEXT (ctx);
}
