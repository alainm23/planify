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

#include <stdio.h>
#include <string.h>

#include "camel-mime-filter-progress.h"
#include "camel-operation.h"

#define CAMEL_MIME_FILTER_PROGRESS_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER_PROGRESS, CamelMimeFilterProgressPrivate))

#define d(x)
#define w(x)

struct _CamelMimeFilterProgressPrivate {
	GCancellable *cancellable;
	gsize total;
	gsize count;
};

G_DEFINE_TYPE (CamelMimeFilterProgress, camel_mime_filter_progress, CAMEL_TYPE_MIME_FILTER)

static void
mime_filter_progress_dispose (GObject *object)
{
	CamelMimeFilterProgressPrivate *priv;

	priv = CAMEL_MIME_FILTER_PROGRESS_GET_PRIVATE (object);

	if (priv->cancellable != NULL) {
		g_object_unref (priv->cancellable);
		priv->cancellable = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_mime_filter_progress_parent_class)->dispose (object);
}

static void
mime_filter_progress_filter (CamelMimeFilter *mime_filter,
                             const gchar *in,
                             gsize len,
                             gsize prespace,
                             gchar **out,
                             gsize *outlen,
                             gsize *outprespace)
{
	CamelMimeFilterProgressPrivate *priv;
	gdouble percent;

	priv = CAMEL_MIME_FILTER_PROGRESS_GET_PRIVATE (mime_filter);
	priv->count += len;

	if (priv->count < priv->total)
		percent = ((gdouble) priv->count * 100.0) / ((gdouble) priv->total);
	else
		percent = 100.0;

	camel_operation_progress (priv->cancellable, (gint) percent);

	*outprespace = prespace;
	*outlen = len;
	*out = (gchar *) in;
}

static void
mime_filter_progress_complete (CamelMimeFilter *mime_filter,
                               const gchar *in,
                               gsize len,
                               gsize prespace,
                               gchar **out,
                               gsize *outlen,
                               gsize *outprespace)
{
	mime_filter_progress_filter (
		mime_filter, in, len, prespace,
		out, outlen, outprespace);
}

static void
mime_filter_progress_reset (CamelMimeFilter *mime_filter)
{
	CamelMimeFilterProgressPrivate *priv;

	priv = CAMEL_MIME_FILTER_PROGRESS_GET_PRIVATE (mime_filter);

	priv->count = 0;
}

static void
camel_mime_filter_progress_class_init (CamelMimeFilterProgressClass *class)
{
	GObjectClass *object_class;
	CamelMimeFilterClass *mime_filter_class;

	g_type_class_add_private (class, sizeof (CamelMimeFilterProgressPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = mime_filter_progress_dispose;

	mime_filter_class = CAMEL_MIME_FILTER_CLASS (class);
	mime_filter_class->filter = mime_filter_progress_filter;
	mime_filter_class->complete = mime_filter_progress_complete;
	mime_filter_class->reset = mime_filter_progress_reset;
}

static void
camel_mime_filter_progress_init (CamelMimeFilterProgress *filter)
{
	filter->priv = CAMEL_MIME_FILTER_PROGRESS_GET_PRIVATE (filter);
}

/**
 * camel_mime_filter_progress_new:
 * @cancellable: a #CamelOperation cast as a #GCancellable
 * @total: total number of bytes to report progress on
 *
 * Create a new #CamelMimeFilterProgress object that will report streaming
 * progress.  While the function will silently accept @cancellable being
 * %NULL or a plain #GCancellable for convenience sake, no progress will be
 * reported unless @cancellable is a #CamelOperation.
 *
 * Returns: a new #CamelMimeFilter object
 *
 * Since: 2.24
 **/
CamelMimeFilter *
camel_mime_filter_progress_new (GCancellable *cancellable,
                                gsize total)
{
	CamelMimeFilter *filter;
	CamelMimeFilterProgressPrivate *priv;

	filter = g_object_new (CAMEL_TYPE_MIME_FILTER_PROGRESS, NULL);
	priv = CAMEL_MIME_FILTER_PROGRESS_GET_PRIVATE (filter);

	if (CAMEL_IS_OPERATION (cancellable))
		priv->cancellable = g_object_ref (cancellable);

	priv->total = total;

	return filter;
}
