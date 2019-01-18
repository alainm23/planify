/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "camel-charset-map.h"
#include "camel-mime-filter-windows.h"

#define CAMEL_MIME_FILTER_WINDOWS_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER_WINDOWS, CamelMimeFilterWindowsPrivate))

#define d(x)
#define w(x)

struct _CamelMimeFilterWindowsPrivate {
	gboolean is_windows;
	gchar *claimed_charset;
};

G_DEFINE_TYPE (CamelMimeFilterWindows, camel_mime_filter_windows, CAMEL_TYPE_MIME_FILTER)

static void
mime_filter_windows_finalize (GObject *object)
{
	CamelMimeFilterWindowsPrivate *priv;

	priv = CAMEL_MIME_FILTER_WINDOWS_GET_PRIVATE (object);

	g_free (priv->claimed_charset);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_mime_filter_windows_parent_class)->finalize (object);
}

static void
mime_filter_windows_filter (CamelMimeFilter *mime_filter,
                            const gchar *in,
                            gsize len,
                            gsize prespace,
                            gchar **out,
                            gsize *outlen,
                            gsize *outprespace)
{
	CamelMimeFilterWindowsPrivate *priv;
	register guchar *inptr;
	guchar *inend;

	priv = CAMEL_MIME_FILTER_WINDOWS_GET_PRIVATE (mime_filter);

	if (!priv->is_windows) {
		inptr = (guchar *) in;
		inend = inptr + len;

		while (inptr < inend) {
			register guchar c = *inptr++;

			if (c >= 128 && c <= 159) {
				w (g_warning (
					"Encountered Windows "
					"charset masquerading as %s",
					priv->claimed_charset));
				priv->is_windows = TRUE;
				break;
			}
		}
	}

	*out = (gchar *) in;
	*outlen = len;
	*outprespace = prespace;
}

static void
mime_filter_windows_complete (CamelMimeFilter *mime_filter,
                              const gchar *in,
                              gsize len,
                              gsize prespace,
                              gchar **out,
                              gsize *outlen,
                              gsize *outprespace)
{
	mime_filter_windows_filter (
		mime_filter, in, len, prespace,
		out, outlen, outprespace);
}

static void
mime_filter_windows_reset (CamelMimeFilter *mime_filter)
{
	CamelMimeFilterWindowsPrivate *priv;

	priv = CAMEL_MIME_FILTER_WINDOWS_GET_PRIVATE (mime_filter);

	priv->is_windows = FALSE;
}

static void
camel_mime_filter_windows_class_init (CamelMimeFilterWindowsClass *class)
{
	GObjectClass *object_class;
	CamelMimeFilterClass *mime_filter_class;

	g_type_class_add_private (class, sizeof (CamelMimeFilterWindowsPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = mime_filter_windows_finalize;

	mime_filter_class = CAMEL_MIME_FILTER_CLASS (class);
	mime_filter_class->filter = mime_filter_windows_filter;
	mime_filter_class->complete = mime_filter_windows_complete;
	mime_filter_class->reset = mime_filter_windows_reset;
}

static void
camel_mime_filter_windows_init (CamelMimeFilterWindows *filter)
{
	filter->priv = CAMEL_MIME_FILTER_WINDOWS_GET_PRIVATE (filter);
}

/**
 * camel_mime_filter_windows_new:
 * @claimed_charset: ISO charset name
 *
 * Create a new #CamelMimeFilterWindows object that will analyse
 * whether or not the text is really encoded in @claimed_charset.
 *
 * Returns: a new #CamelMimeFilter object
 **/
CamelMimeFilter *
camel_mime_filter_windows_new (const gchar *claimed_charset)
{
	CamelMimeFilter *filter;
	CamelMimeFilterWindowsPrivate *priv;

	g_return_val_if_fail (claimed_charset != NULL, NULL);

	filter = g_object_new (CAMEL_TYPE_MIME_FILTER_WINDOWS, NULL);
	priv = CAMEL_MIME_FILTER_WINDOWS_GET_PRIVATE (filter);

	priv->claimed_charset = g_strdup (claimed_charset);

	return filter;
}

/**
 * camel_mime_filter_windows_is_windows_charset:
 * @filter: a #CamelMimeFilterWindows object
 *
 * Get whether or not the textual content filtered by @filter is
 * really in a Microsoft Windows charset rather than the claimed ISO
 * charset.
 *
 * Returns: %TRUE if the text was found to be in a Microsoft Windows
 * CP125x charset or %FALSE otherwise.
 **/
gboolean
camel_mime_filter_windows_is_windows_charset (CamelMimeFilterWindows *filter)
{
	g_return_val_if_fail (CAMEL_IS_MIME_FILTER_WINDOWS (filter), FALSE);

	return filter->priv->is_windows;
}

/**
 * camel_mime_filter_windows_real_charset:
 * @filter: a #CamelMimeFilterWindows object
 *
 * Get the name of the actual charset used to encode the textual
 * content filtered by @filter (it will either be the original
 * claimed_charset passed in at creation time or the Windows-CP125x
 * equivalent).
 *
 * Returns: the name of the actual charset
 **/
const gchar *
camel_mime_filter_windows_real_charset (CamelMimeFilterWindows *filter)
{
	const gchar *charset;

	g_return_val_if_fail (CAMEL_IS_MIME_FILTER_WINDOWS (filter), NULL);

	charset = filter->priv->claimed_charset;

	if (filter->priv->is_windows)
		charset = camel_charset_iso_to_windows (charset);

	return charset;
}
