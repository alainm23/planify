/*
 * camel-filter-input-stream.c
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
 * SECTION: camel-filter-input-stream
 * @short_description: Filtered input stream
 * @include: camel/camel.h
 * @see_also: #GInputStream, #CamelMimeFilter
 *
 * #CamelFilterInputStream is similar to #GConverterInputStream, except it
 * operates on a #CamelMimeFilter instead of a #GConverter.
 *
 * This class is meant to be a temporary solution until all of Camel's MIME
 * filters are ported to the #GConverter interface.
 **/

#include "camel-filter-input-stream.h"

#include <string.h>

#define CAMEL_FILTER_INPUT_STREAM_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_FILTER_INPUT_STREAM, CamelFilterInputStreamPrivate))

#define READ_PAD (128)		/* bytes padded before buffer */
#define READ_SIZE (4096)

struct _CamelFilterInputStreamPrivate {
	CamelMimeFilter *filter;

	gchar real_buffer[READ_SIZE + READ_PAD];
	gchar *buffer;		/* points to real_buffer + READ_PAD */

	gchar *filtered;
	gsize filtered_length;
};

enum {
	PROP_0,
	PROP_FILTER
};

G_DEFINE_TYPE (
	CamelFilterInputStream,
	camel_filter_input_stream,
	G_TYPE_FILTER_INPUT_STREAM)

static void
filter_input_stream_set_filter (CamelFilterInputStream *filter_stream,
                                CamelMimeFilter *filter)
{
	g_return_if_fail (CAMEL_IS_MIME_FILTER (filter));
	g_return_if_fail (filter_stream->priv->filter == NULL);

	filter_stream->priv->filter = g_object_ref (filter);
}

static void
filter_input_stream_set_property (GObject *object,
                                  guint property_id,
                                  const GValue *value,
                                  GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_FILTER:
			filter_input_stream_set_filter (
				CAMEL_FILTER_INPUT_STREAM (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
filter_input_stream_get_property (GObject *object,
                                  guint property_id,
                                  GValue *value,
                                  GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_FILTER:
			g_value_set_object (
				value,
				camel_filter_input_stream_get_filter (
				CAMEL_FILTER_INPUT_STREAM (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
filter_input_stream_dispose (GObject *object)
{
	CamelFilterInputStreamPrivate *priv;

	priv = CAMEL_FILTER_INPUT_STREAM_GET_PRIVATE (object);

	g_clear_object (&priv->filter);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_filter_input_stream_parent_class)->
		dispose (object);
}

static gssize
filter_input_stream_read (GInputStream *stream,
                          gpointer buffer,
                          gsize count,
                          GCancellable *cancellable,
                          GError **error)
{
	CamelFilterInputStreamPrivate *priv;
	CamelMimeFilter *filter;
	GInputStream *base_stream;
	gssize n_bytes_read;
	gsize presize = READ_PAD;

	priv = CAMEL_FILTER_INPUT_STREAM_GET_PRIVATE (stream);

	filter = camel_filter_input_stream_get_filter (
		CAMEL_FILTER_INPUT_STREAM (stream));
	base_stream = g_filter_input_stream_get_base_stream (
		G_FILTER_INPUT_STREAM (stream));

	/* If we already have some filtered data, return it. */
	if (priv->filtered_length > 0)
		goto exit;

	n_bytes_read = g_input_stream_read (
		base_stream, priv->buffer,
		READ_SIZE, cancellable, error);

	if (n_bytes_read == 0) {
		camel_mime_filter_complete (
			filter, priv->filtered, priv->filtered_length, presize,
			&priv->filtered, &priv->filtered_length, &presize);

		n_bytes_read = priv->filtered_length;

		if (n_bytes_read > 0)
			goto exit;
	}

	if (n_bytes_read <= 0)
		return n_bytes_read;

	priv->filtered = priv->buffer;
	priv->filtered_length = n_bytes_read;

	camel_mime_filter_filter (
		filter, priv->filtered, priv->filtered_length, presize,
		&priv->filtered, &priv->filtered_length, &presize);

exit:
	n_bytes_read = MIN (count, priv->filtered_length);
	memcpy (buffer, priv->filtered, n_bytes_read);
	priv->filtered_length -= n_bytes_read;
	priv->filtered += n_bytes_read;

	return n_bytes_read;
}

static void
camel_filter_input_stream_class_init (CamelFilterInputStreamClass *class)
{
	GObjectClass *object_class;
	GInputStreamClass *stream_class;

	g_type_class_add_private (
		class, sizeof (CamelFilterInputStreamPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = filter_input_stream_set_property;
	object_class->get_property = filter_input_stream_get_property;
	object_class->dispose = filter_input_stream_dispose;

	stream_class = G_INPUT_STREAM_CLASS (class);
	stream_class->read_fn = filter_input_stream_read;

	g_object_class_install_property (
		object_class,
		PROP_FILTER,
		g_param_spec_object (
			"filter",
			"Filter",
			"The MIME filter object",
			CAMEL_TYPE_MIME_FILTER,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));
}

static void
camel_filter_input_stream_init (CamelFilterInputStream *filter_stream)
{
	filter_stream->priv =
		CAMEL_FILTER_INPUT_STREAM_GET_PRIVATE (filter_stream);

	filter_stream->priv->buffer =
		filter_stream->priv->real_buffer + READ_PAD;
}

/**
 * camel_filter_input_stream_new:
 * @base_stream: a #GInputStream
 * @filter: a #CamelMimeFilter
 *
 * Creates a new filtered input stream for the @base_stream.
 *
 * Returns: a new #GInputStream
 *
 * Since: 3.12
 **/
GInputStream *
camel_filter_input_stream_new (GInputStream *base_stream,
                               CamelMimeFilter *filter)
{
	g_return_val_if_fail (G_IS_INPUT_STREAM (base_stream), NULL);
	g_return_val_if_fail (CAMEL_IS_MIME_FILTER (filter), NULL);

	return g_object_new (
		CAMEL_TYPE_FILTER_INPUT_STREAM,
		"base-stream", base_stream,
		"filter", filter, NULL);
}

/**
 * camel_filter_input_stream_get_filter:
 * @filter_stream: a #CamelFilterInputStream
 *
 * Gets the #CamelMimeFilter that is used by @filter_stream.
 *
 * Returns: (transfer none): a #CamelMimeFilter
 *
 * Since: 3.12
 **/
CamelMimeFilter *
camel_filter_input_stream_get_filter (CamelFilterInputStream *filter_stream)
{
	g_return_val_if_fail (
		CAMEL_IS_FILTER_INPUT_STREAM (filter_stream), NULL);

	return filter_stream->priv->filter;
}

