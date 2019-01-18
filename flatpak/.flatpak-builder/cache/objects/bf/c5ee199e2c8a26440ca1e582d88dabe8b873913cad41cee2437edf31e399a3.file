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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#include "camel-mime-filter-index.h"
#include "camel-text-index.h"

#define CAMEL_MIME_FILTER_INDEX_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER_INDEX, CamelMimeFilterIndexPrivate))

struct _CamelMimeFilterIndexPrivate {
	CamelIndex *index;
	CamelIndexName *name;
};

G_DEFINE_TYPE (CamelMimeFilterIndex, camel_mime_filter_index, CAMEL_TYPE_MIME_FILTER)

static void
mime_filter_index_dispose (GObject *object)
{
	CamelMimeFilterIndexPrivate *priv;

	priv = CAMEL_MIME_FILTER_INDEX_GET_PRIVATE (object);

	if (priv->name != NULL) {
		g_object_unref (priv->name);
		priv->name = NULL;
	}

	if (priv->index != NULL) {
		g_object_unref (priv->index);
		priv->index = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_mime_filter_index_parent_class)->dispose (object);
}

static void
mime_filter_index_filter (CamelMimeFilter *mime_filter,
                          const gchar *in,
                          gsize len,
                          gsize prespace,
                          gchar **out,
                          gsize *outlenptr,
                          gsize *outprespace)
{
	CamelMimeFilterIndexPrivate *priv;

	priv = CAMEL_MIME_FILTER_INDEX_GET_PRIVATE (mime_filter);

	if (priv->index == NULL || priv->name == NULL) {
		goto donothing;
	}

	camel_index_name_add_buffer (priv->name, in, len);

donothing:
	*out = (gchar *) in;
	*outlenptr = len;
	*outprespace = prespace;
}

static void
mime_filter_index_complete (CamelMimeFilter *mime_filter,
                            const gchar *in,
                            gsize len,
                            gsize prespace,
                            gchar **out,
                            gsize *outlenptr,
                            gsize *outprespace)
{
	CamelMimeFilterIndexPrivate *priv;

	priv = CAMEL_MIME_FILTER_INDEX_GET_PRIVATE (mime_filter);

	if (priv->index == NULL || priv->name == NULL) {
		goto donothing;
	}

	camel_index_name_add_buffer (priv->name, in, len);
	camel_index_name_add_buffer (priv->name, NULL, 0);

donothing:
	*out = (gchar *) in;
	*outlenptr = len;
	*outprespace = prespace;
}

static void
camel_mime_filter_index_class_init (CamelMimeFilterIndexClass *class)
{
	GObjectClass *object_class;
	CamelMimeFilterClass *mime_filter_class;

	g_type_class_add_private (class, sizeof (CamelMimeFilterIndexPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = mime_filter_index_dispose;

	mime_filter_class = CAMEL_MIME_FILTER_CLASS (class);
	mime_filter_class->filter = mime_filter_index_filter;
	mime_filter_class->complete = mime_filter_index_complete;
}

static void
camel_mime_filter_index_init (CamelMimeFilterIndex *filter)
{
	filter->priv = CAMEL_MIME_FILTER_INDEX_GET_PRIVATE (filter);
}

/**
 * camel_mime_filter_index_new:
 * @index: a #CamelIndex object
 *
 * Create a new #CamelMimeFilterIndex based on @index.
 *
 * Returns: a new #CamelMimeFilterIndex object
 **/
CamelMimeFilter *
camel_mime_filter_index_new (CamelIndex *index)
{
	CamelMimeFilter *new;
	CamelMimeFilterIndexPrivate *priv;

	new = g_object_new (CAMEL_TYPE_MIME_FILTER_INDEX, NULL);

	priv = CAMEL_MIME_FILTER_INDEX_GET_PRIVATE (new);

	if (index != NULL)
		priv->index = g_object_ref (index);

	return new;
}

/* Set the match name for any indexed words */

/**
 * camel_mime_filter_index_set_name:
 * @filter: a #CamelMimeFilterIndex object
 * @name: a #CamelIndexName object
 *
 * Set the match name for any indexed words.
 **/
void
camel_mime_filter_index_set_name (CamelMimeFilterIndex *filter,
                                  CamelIndexName *name)
{
	g_return_if_fail (CAMEL_IS_MIME_FILTER_INDEX (filter));

	if (name != NULL) {
		g_return_if_fail (CAMEL_IS_INDEX_NAME (name));
		g_object_ref (name);
	}

	if (filter->priv->name != NULL)
		g_object_unref (filter->priv->name);

	filter->priv->name = name;
}

/**
 * camel_mime_filter_index_set_index:
 * @filter: a #CamelMimeFilterIndex object
 * @index: a #CamelIndex object
 *
 * Set @index on @filter.
 **/
void
camel_mime_filter_index_set_index (CamelMimeFilterIndex *filter,
                                   CamelIndex *index)
{
	g_return_if_fail (CAMEL_IS_MIME_FILTER_INDEX (filter));

	if (index != NULL) {
		g_return_if_fail (CAMEL_IS_INDEX (index));
		g_object_ref (index);
	}

	if (filter->priv->index) {
		gchar *out;
		gsize outlen, outspace;

		camel_mime_filter_complete (
			CAMEL_MIME_FILTER (filter),
			"", 0, 0, &out, &outlen, &outspace);
		g_object_unref (filter->priv->index);
	}

	filter->priv->index = index;
}
