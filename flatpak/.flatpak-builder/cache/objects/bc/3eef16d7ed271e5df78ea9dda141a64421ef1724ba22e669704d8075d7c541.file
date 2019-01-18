/*
 * camel-filter-output-stream.c
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
 * SECTION: camel-filter-output-stream
 * @short_description: Filtered output stream
 * @include: camel/camel.h
 * @see_also: #GOutputStream, #CamelMimeFilter
 *
 * #CamelFilterOutputStream is similar to #GConverterOutputStream, except it
 * operates on a #CamelMimeFilter instead of a #GConverter.
 *
 * This class is meant to be a temporary solution until all of Camel's MIME
 * filters are ported to the #GConverter interface.
 **/

#include "camel-filter-output-stream.h"

#include <string.h>

#define CAMEL_FILTER_OUTPUT_STREAM_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_FILTER_OUTPUT_STREAM, CamelFilterOutputStreamPrivate))

#define READ_PAD (128)		/* bytes padded before buffer */
#define READ_SIZE (4096)

struct _CamelFilterOutputStreamPrivate {
	CamelMimeFilter *filter;
};

enum {
	PROP_0,
	PROP_FILTER
};

G_DEFINE_TYPE (
	CamelFilterOutputStream,
	camel_filter_output_stream,
	G_TYPE_FILTER_OUTPUT_STREAM)

static void
filter_output_stream_set_filter (CamelFilterOutputStream *filter_stream,
                                 CamelMimeFilter *filter)
{
	g_return_if_fail (CAMEL_IS_MIME_FILTER (filter));
	g_return_if_fail (filter_stream->priv->filter == NULL);

	filter_stream->priv->filter = g_object_ref (filter);
}

static void
filter_output_stream_set_property (GObject *object,
                                   guint property_id,
                                   const GValue *value,
                                   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_FILTER:
			filter_output_stream_set_filter (
				CAMEL_FILTER_OUTPUT_STREAM (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
filter_output_stream_get_property (GObject *object,
                                   guint property_id,
                                   GValue *value,
                                   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_FILTER:
			g_value_set_object (
				value,
				camel_filter_output_stream_get_filter (
				CAMEL_FILTER_OUTPUT_STREAM (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
filter_output_stream_dispose (GObject *object)
{
	CamelFilterOutputStreamPrivate *priv;

	priv = CAMEL_FILTER_OUTPUT_STREAM_GET_PRIVATE (object);

	/* XXX GOutputStream calls flush() one last time during
	 *     dispose(), so chain up before clearing our filter. */
	G_OBJECT_CLASS (camel_filter_output_stream_parent_class)->
		dispose (object);

	g_clear_object (&priv->filter);
}

static gssize
filter_output_stream_write (GOutputStream *stream,
                            gconstpointer buffer,
                            gsize count,
                            GCancellable *cancellable,
                            GError **error)
{
	CamelMimeFilter *filter;
	GOutputStream *base_stream;
	gchar real_buffer[READ_SIZE + READ_PAD];
	const gchar *input_buffer = buffer;
	gsize bytes_left = count;

	filter = camel_filter_output_stream_get_filter (
		CAMEL_FILTER_OUTPUT_STREAM (stream));
	base_stream = g_filter_output_stream_get_base_stream (
		G_FILTER_OUTPUT_STREAM (stream));

	while (bytes_left > 0) {
		gsize length;
		gsize presize;
		gchar *bufptr;
		gboolean success;

		bufptr = real_buffer + READ_PAD;
		length = MIN (READ_SIZE, bytes_left);
		memcpy (bufptr, input_buffer, length);
		input_buffer += length;
		bytes_left -= length;

		presize = READ_PAD;

		camel_mime_filter_filter (
			filter, bufptr, length, presize,
			&bufptr, &length, &presize);

		/* XXX The bytes_written argument can be NULL,
		 *     even though the API docs don't say so. */
		success = g_output_stream_write_all (
			base_stream, bufptr, length,
			NULL, cancellable, error);
		if (!success)
			return -1;
	}

	return count;
}

static gboolean
filter_output_stream_flush (GOutputStream *stream,
                            GCancellable *cancellable,
                            GError **error)
{
	CamelMimeFilter *filter;
	GOutputStream *base_stream;
	gchar *bufptr = (gchar *) "";
	gsize length = 0;
	gsize presize = 0;
	gboolean success = TRUE;

	filter = camel_filter_output_stream_get_filter (
		CAMEL_FILTER_OUTPUT_STREAM (stream));
	base_stream = g_filter_output_stream_get_base_stream (
		G_FILTER_OUTPUT_STREAM (stream));

	camel_mime_filter_complete (
		filter, bufptr, length, presize,
		&bufptr, &length, &presize);

	if (length > 0) {
		/* XXX The bytes_written argument can be NULL,
		 *     even though the API docs don't say so. */
		success = g_output_stream_write_all (
			base_stream, bufptr, length,
			NULL, cancellable, error);
	}

	if (success) {
		success = g_output_stream_flush (
			base_stream, cancellable, error);
	}

	return success;
}

static void
camel_filter_output_stream_class_init (CamelFilterOutputStreamClass *class)
{
	GObjectClass *object_class;
	GOutputStreamClass *stream_class;

	g_type_class_add_private (
		class, sizeof (CamelFilterOutputStreamPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = filter_output_stream_set_property;
	object_class->get_property = filter_output_stream_get_property;
	object_class->dispose = filter_output_stream_dispose;

	stream_class = G_OUTPUT_STREAM_CLASS (class);
	stream_class->write_fn = filter_output_stream_write;
	stream_class->flush = filter_output_stream_flush;

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
camel_filter_output_stream_init (CamelFilterOutputStream *filter_stream)
{
	filter_stream->priv =
		CAMEL_FILTER_OUTPUT_STREAM_GET_PRIVATE (filter_stream);
}

/**
 * camel_filter_output_stream_new:
 * @base_stream: a #GOutputStream
 * @filter: a #CamelMimeFilter
 *
 * Creates a new filtered output stream for the @base_stream.
 *
 * Returns: a new #GOutputStream
 *
 * Since: 3.12
 **/
GOutputStream *
camel_filter_output_stream_new (GOutputStream *base_stream,
                                CamelMimeFilter *filter)
{
	g_return_val_if_fail (G_IS_OUTPUT_STREAM (base_stream), NULL);
	g_return_val_if_fail (CAMEL_IS_MIME_FILTER (filter), NULL);

	return g_object_new (
		CAMEL_TYPE_FILTER_OUTPUT_STREAM,
		"base-stream", base_stream,
		"filter", filter, NULL);
}

/**
 * camel_filter_output_stream_get_filter:
 * @filter_stream: a #CamelFilterOutputStream
 *
 * Gets the #CamelMimeFilter that is used by @filter_stream.
 *
 * Returns: (transfer none): a #CamelMimeFilter
 *
 * Since: 3.12
 **/
CamelMimeFilter *
camel_filter_output_stream_get_filter (CamelFilterOutputStream *filter_stream)
{
	g_return_val_if_fail (
		CAMEL_IS_FILTER_OUTPUT_STREAM (filter_stream), NULL);

	return filter_stream->priv->filter;
}

