/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; -*- */
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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <glib/gi18n-lib.h>

#include "camel-data-wrapper.h"
#include "camel-debug.h"
#include "camel-filter-output-stream.h"
#include "camel-mime-filter-basic.h"
#include "camel-mime-filter-crlf.h"
#include "camel-stream-filter.h"
#include "camel-stream-mem.h"
#include "camel-stream-null.h"

#define d(x)

#define CAMEL_DATA_WRAPPER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_DATA_WRAPPER, CamelDataWrapperPrivate))

typedef struct _AsyncContext AsyncContext;

struct _CamelDataWrapperPrivate {
	GMutex stream_lock;
	GByteArray *byte_array;

	CamelTransferEncoding encoding;

	CamelContentType *mime_type;

	guint offline : 1;
};

struct _AsyncContext {
	CamelStream *stream;
	GInputStream *input_stream;
	GOutputStream *output_stream;
};

G_DEFINE_TYPE (CamelDataWrapper, camel_data_wrapper, G_TYPE_OBJECT)

static void
async_context_free (AsyncContext *async_context)
{
	g_clear_object (&async_context->stream);
	g_clear_object (&async_context->input_stream);
	g_clear_object (&async_context->output_stream);

	g_slice_free (AsyncContext, async_context);
}

static void
data_wrapper_dispose (GObject *object)
{
	CamelDataWrapper *data_wrapper = CAMEL_DATA_WRAPPER (object);

	if (data_wrapper->priv->mime_type != NULL) {
		camel_content_type_unref (data_wrapper->priv->mime_type);
		data_wrapper->priv->mime_type = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_data_wrapper_parent_class)->dispose (object);
}

static void
data_wrapper_finalize (GObject *object)
{
	CamelDataWrapperPrivate *priv;

	priv = CAMEL_DATA_WRAPPER_GET_PRIVATE (object);

	g_mutex_clear (&priv->stream_lock);
	g_byte_array_free (priv->byte_array, TRUE);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_data_wrapper_parent_class)->finalize (object);
}

static void
data_wrapper_set_mime_type (CamelDataWrapper *data_wrapper,
                            const gchar *mime_type)
{
	if (data_wrapper->priv->mime_type)
		camel_content_type_unref (data_wrapper->priv->mime_type);
	data_wrapper->priv->mime_type = camel_content_type_decode (mime_type);
}

static gchar *
data_wrapper_get_mime_type (CamelDataWrapper *data_wrapper)
{
	return camel_content_type_simple (data_wrapper->priv->mime_type);
}

static CamelContentType *
data_wrapper_get_mime_type_field (CamelDataWrapper *data_wrapper)
{
	return data_wrapper->priv->mime_type;
}

static void
data_wrapper_set_mime_type_field (CamelDataWrapper *data_wrapper,
                                  CamelContentType *mime_type)
{
	if (mime_type)
		camel_content_type_ref (mime_type);
	if (data_wrapper->priv->mime_type)
		camel_content_type_unref (data_wrapper->priv->mime_type);
	data_wrapper->priv->mime_type = mime_type;
}

static gboolean
data_wrapper_is_offline (CamelDataWrapper *data_wrapper)
{
	return data_wrapper->priv->offline;
}

static gssize
data_wrapper_write_to_stream_sync (CamelDataWrapper *data_wrapper,
                                   CamelStream *stream,
                                   GCancellable *cancellable,
                                   GError **error)
{
	CamelStream *memory_stream;
	gssize ret;

	g_mutex_lock (&data_wrapper->priv->stream_lock);

	/* Check for cancellation after locking. */
	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		g_mutex_unlock (&data_wrapper->priv->stream_lock);
		return -1;
	}

	memory_stream = camel_stream_mem_new ();

	/* We retain ownership of the byte array. */
	camel_stream_mem_set_byte_array (
		CAMEL_STREAM_MEM (memory_stream),
		data_wrapper->priv->byte_array);

	ret = camel_stream_write_to_stream (
		memory_stream, stream, cancellable, error);

	g_object_unref (memory_stream);

	g_mutex_unlock (&data_wrapper->priv->stream_lock);

	return ret;
}

static gssize
data_wrapper_decode_to_stream_sync (CamelDataWrapper *data_wrapper,
                                    CamelStream *stream,
                                    GCancellable *cancellable,
                                    GError **error)
{
	CamelMimeFilter *filter;
	CamelStream *fstream;
	gssize ret;

	fstream = camel_stream_filter_new (stream);

	switch (data_wrapper->priv->encoding) {
	case CAMEL_TRANSFER_ENCODING_BASE64:
		filter = camel_mime_filter_basic_new (CAMEL_MIME_FILTER_BASIC_BASE64_DEC);
		camel_stream_filter_add (CAMEL_STREAM_FILTER (fstream), filter);
		g_object_unref (filter);
		break;
	case CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE:
		filter = camel_mime_filter_basic_new (CAMEL_MIME_FILTER_BASIC_QP_DEC);
		camel_stream_filter_add (CAMEL_STREAM_FILTER (fstream), filter);
		g_object_unref (filter);
		break;
	case CAMEL_TRANSFER_ENCODING_UUENCODE:
		filter = camel_mime_filter_basic_new (CAMEL_MIME_FILTER_BASIC_UU_DEC);
		camel_stream_filter_add (CAMEL_STREAM_FILTER (fstream), filter);
		g_object_unref (filter);
		break;
	default:
		break;
	}

	ret = camel_data_wrapper_write_to_stream_sync (
		data_wrapper, fstream, cancellable, error);

	camel_stream_flush (fstream, NULL, NULL);
	g_object_unref (fstream);

	return ret;
}

static gboolean
data_wrapper_construct_from_stream_sync (CamelDataWrapper *data_wrapper,
                                         CamelStream *stream,
                                         GCancellable *cancellable,
                                         GError **error)
{
	CamelStream *memory_stream;
	gssize bytes_written;

	g_mutex_lock (&data_wrapper->priv->stream_lock);

	/* Check for cancellation after locking. */
	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		g_mutex_unlock (&data_wrapper->priv->stream_lock);
		return FALSE;
	}

	if (G_IS_SEEKABLE (stream)) {
		if (!g_seekable_seek (G_SEEKABLE (stream), 0, G_SEEK_SET, cancellable, error)) {
			g_mutex_unlock (&data_wrapper->priv->stream_lock);
			return FALSE;
		}
	}

	/* Wipe any previous contents from our byte array. */
	g_byte_array_set_size (data_wrapper->priv->byte_array, 0);

	memory_stream = camel_stream_mem_new ();

	/* We retain ownership of the byte array. */
	camel_stream_mem_set_byte_array (
		CAMEL_STREAM_MEM (memory_stream),
		data_wrapper->priv->byte_array);

	/* Transfer incoming contents to our byte array. */
	bytes_written = camel_stream_write_to_stream (
		stream, memory_stream, cancellable, error);

	g_object_unref (memory_stream);

	g_mutex_unlock (&data_wrapper->priv->stream_lock);

	return (bytes_written >= 0);
}

static gssize
data_wrapper_write_to_output_stream_sync (CamelDataWrapper *data_wrapper,
                                          GOutputStream *output_stream,
                                          GCancellable *cancellable,
                                          GError **error)
{
	GInputStream *input_stream;
	gssize bytes_written;

	/* XXX Should keep the internal data as a reference-counted
	 *     GBytes to avoid locking while writing to the stream. */

	g_mutex_lock (&data_wrapper->priv->stream_lock);

	/* We retain ownership of the byte array content. */
	input_stream = g_memory_input_stream_new_from_data (
		data_wrapper->priv->byte_array->data,
		data_wrapper->priv->byte_array->len,
		(GDestroyNotify) NULL);

	bytes_written = g_output_stream_splice (
		output_stream, input_stream,
		G_OUTPUT_STREAM_SPLICE_NONE,
		cancellable, error);

	g_object_unref (input_stream);

	g_mutex_unlock (&data_wrapper->priv->stream_lock);

	return bytes_written;
}

static gssize
data_wrapper_decode_to_output_stream_sync (CamelDataWrapper *data_wrapper,
                                           GOutputStream *output_stream,
                                           GCancellable *cancellable,
                                           GError **error)
{
	CamelMimeFilter *filter = NULL;
	GOutputStream *filter_stream = NULL;
	gboolean content_type_is_text;
	gssize bytes_written;

	switch (data_wrapper->priv->encoding) {
		case CAMEL_TRANSFER_ENCODING_BASE64:
			filter = camel_mime_filter_basic_new (
				CAMEL_MIME_FILTER_BASIC_BASE64_DEC);
			filter_stream = camel_filter_output_stream_new (
				output_stream, filter);
			g_filter_output_stream_set_close_base_stream (
				G_FILTER_OUTPUT_STREAM (filter_stream), FALSE);
			g_object_unref (filter);
			break;
		case CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE:
			filter = camel_mime_filter_basic_new (
				CAMEL_MIME_FILTER_BASIC_QP_DEC);
			filter_stream = camel_filter_output_stream_new (
				output_stream, filter);
			g_filter_output_stream_set_close_base_stream (
				G_FILTER_OUTPUT_STREAM (filter_stream), FALSE);
			g_object_unref (filter);
			break;
		case CAMEL_TRANSFER_ENCODING_UUENCODE:
			filter = camel_mime_filter_basic_new (
				CAMEL_MIME_FILTER_BASIC_UU_DEC);
			filter_stream = camel_filter_output_stream_new (
				output_stream, filter);
			g_filter_output_stream_set_close_base_stream (
				G_FILTER_OUTPUT_STREAM (filter_stream), FALSE);
			g_object_unref (filter);
			break;
		default:
			/* Write directly to the output stream. */
			filter_stream = g_object_ref (output_stream);
			break;
	}

	content_type_is_text =
		camel_content_type_is (data_wrapper->priv->mime_type, "text", "*") &&
		!camel_content_type_is (data_wrapper->priv->mime_type, "text", "pdf");

	if (content_type_is_text) {
		GOutputStream *temp_stream;

		filter = camel_mime_filter_crlf_new (
			CAMEL_MIME_FILTER_CRLF_DECODE,
			CAMEL_MIME_FILTER_CRLF_MODE_CRLF_ONLY);
		temp_stream = camel_filter_output_stream_new (
			filter_stream, filter);
		g_filter_output_stream_set_close_base_stream (
			G_FILTER_OUTPUT_STREAM (temp_stream), FALSE);
		g_object_unref (filter);

		g_object_unref (filter_stream);
		filter_stream = temp_stream;
	}

	bytes_written = camel_data_wrapper_write_to_output_stream_sync (
		data_wrapper, filter_stream, cancellable, error);

	g_object_unref (filter_stream);

	return bytes_written;
}

static gboolean
data_wrapper_construct_from_input_stream_sync (CamelDataWrapper *data_wrapper,
                                               GInputStream *input_stream,
                                               GCancellable *cancellable,
                                               GError **error)
{
	GOutputStream *output_stream;
	gssize bytes_written;
	gboolean success;

	/* XXX Should keep the internal data as a reference-counted
	 *     GBytes to avoid locking while reading from the stream. */

	g_mutex_lock (&data_wrapper->priv->stream_lock);

	/* Check for cancellation after locking. */
	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		g_mutex_unlock (&data_wrapper->priv->stream_lock);
		return FALSE;
	}

	if (G_IS_SEEKABLE (input_stream)) {
		success = g_seekable_seek (
			G_SEEKABLE (input_stream), 0,
			G_SEEK_SET, cancellable, error);
		if (!success) {
			g_mutex_unlock (&data_wrapper->priv->stream_lock);
			return FALSE;
		}
	}

	output_stream = g_memory_output_stream_new_resizable ();

	bytes_written = g_output_stream_splice (
		output_stream, input_stream,
		G_OUTPUT_STREAM_SPLICE_CLOSE_TARGET,
		cancellable, error);

	success = (bytes_written >= 0);

	if (success) {
		GBytes *bytes;

		bytes = g_memory_output_stream_steal_as_bytes (
			G_MEMORY_OUTPUT_STREAM (output_stream));

		g_byte_array_free (data_wrapper->priv->byte_array, TRUE);
		data_wrapper->priv->byte_array = g_bytes_unref_to_array (bytes);
	}

	g_object_unref (output_stream);

	g_mutex_unlock (&data_wrapper->priv->stream_lock);

	return success;
}

static void
camel_data_wrapper_class_init (CamelDataWrapperClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelDataWrapperPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = data_wrapper_dispose;
	object_class->finalize = data_wrapper_finalize;

	class->set_mime_type = data_wrapper_set_mime_type;
	class->get_mime_type = data_wrapper_get_mime_type;
	class->get_mime_type_field = data_wrapper_get_mime_type_field;
	class->set_mime_type_field = data_wrapper_set_mime_type_field;
	class->is_offline = data_wrapper_is_offline;

	class->write_to_stream_sync = data_wrapper_write_to_stream_sync;
	class->decode_to_stream_sync = data_wrapper_decode_to_stream_sync;
	class->construct_from_stream_sync = data_wrapper_construct_from_stream_sync;
	class->write_to_output_stream_sync = data_wrapper_write_to_output_stream_sync;
	class->decode_to_output_stream_sync = data_wrapper_decode_to_output_stream_sync;
	class->construct_from_input_stream_sync = data_wrapper_construct_from_input_stream_sync;
}

static void
camel_data_wrapper_init (CamelDataWrapper *data_wrapper)
{
	data_wrapper->priv = CAMEL_DATA_WRAPPER_GET_PRIVATE (data_wrapper);

	g_mutex_init (&data_wrapper->priv->stream_lock);
	data_wrapper->priv->byte_array = g_byte_array_new ();

	data_wrapper->priv->mime_type = camel_content_type_new ("application", "octet-stream");
	data_wrapper->priv->encoding = CAMEL_TRANSFER_ENCODING_DEFAULT;
	data_wrapper->priv->offline = FALSE;
}

/**
 * camel_data_wrapper_new:
 *
 * Create a new #CamelDataWrapper object.
 *
 * Returns: a new #CamelDataWrapper object
 **/
CamelDataWrapper *
camel_data_wrapper_new (void)
{
	return g_object_new (CAMEL_TYPE_DATA_WRAPPER, NULL);
}

/**
 * camel_data_wrapper_get_byte_array:
 * @data_wrapper: a #CamelDataWrapper
 *
 * Returns the #GByteArray being used to hold the contents of @data_wrapper.
 *
 * Note, it's up to the caller to use this in a thread-safe manner.
 *
 * Returns: (transfer none): the #GByteArray for @data_wrapper
 *
 * Since: 3.2
 **/
GByteArray *
camel_data_wrapper_get_byte_array (CamelDataWrapper *data_wrapper)
{
	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), NULL);

	return data_wrapper->priv->byte_array;
}

/**
 * camel_data_wrapper_get_encoding:
 * @data_wrapper: a #CamelDataWrapper
 *
 * Returns: An encoding (#CamelTransferEncoding) of the @data_wrapper
 *
 * Since: 3.24
 **/
CamelTransferEncoding
camel_data_wrapper_get_encoding (CamelDataWrapper *data_wrapper)
{
	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), CAMEL_TRANSFER_ENCODING_DEFAULT);

	return data_wrapper->priv->encoding;
}

/**
 * camel_data_wrapper_set_encoding:
 * @data_wrapper: a #CamelDataWrapper
 * @encoding: an encoding to set
 *
 * Sets encoding (#CamelTransferEncoding) for the @data_wrapper.
 * It doesn't re-encode the content, if the encoding changes.
 *
 * Since: 3.24
 **/
void
camel_data_wrapper_set_encoding (CamelDataWrapper *data_wrapper,
				 CamelTransferEncoding encoding)
{
	g_return_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper));

	data_wrapper->priv->encoding = encoding;
}

/**
 * camel_data_wrapper_set_mime_type:
 * @data_wrapper: a #CamelDataWrapper
 * @mime_type: a MIME type
 *
 * This sets the data wrapper's MIME type.
 *
 * It might fail, but you won't know. It will allow you to set
 * Content-Type parameters on the data wrapper, which are meaningless.
 * You should not be allowed to change the MIME type of a data wrapper
 * that contains data, or at least, if you do, it should invalidate the
 * data.
 **/
void
camel_data_wrapper_set_mime_type (CamelDataWrapper *data_wrapper,
                                  const gchar *mime_type)
{
	CamelDataWrapperClass *class;

	g_return_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper));
	g_return_if_fail (mime_type != NULL);

	class = CAMEL_DATA_WRAPPER_GET_CLASS (data_wrapper);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->set_mime_type != NULL);

	class->set_mime_type (data_wrapper, mime_type);
}

/**
 * camel_data_wrapper_get_mime_type:
 * @data_wrapper: a #CamelDataWrapper
 *
 * Returns: the MIME type which must be freed by the caller
 **/
gchar *
camel_data_wrapper_get_mime_type (CamelDataWrapper *data_wrapper)
{
	CamelDataWrapperClass *class;

	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), NULL);

	class = CAMEL_DATA_WRAPPER_GET_CLASS (data_wrapper);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_mime_type != NULL, NULL);

	return class->get_mime_type (data_wrapper);
}

/**
 * camel_data_wrapper_get_mime_type_field:
 * @data_wrapper: a #CamelDataWrapper
 *
 * Returns: (transfer none): the parsed form of the data wrapper's MIME type
 **/
CamelContentType *
camel_data_wrapper_get_mime_type_field (CamelDataWrapper *data_wrapper)
{
	CamelDataWrapperClass *class;

	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), NULL);

	class = CAMEL_DATA_WRAPPER_GET_CLASS (data_wrapper);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_mime_type_field != NULL, NULL);

	return class->get_mime_type_field (data_wrapper);
}

/**
 * camel_data_wrapper_set_mime_type_field:
 * @data_wrapper: a #CamelDataWrapper
 * @mime_type: (nullable): a #CamelContentType
 *
 * This sets the data wrapper's MIME type. It adds its own reference
 * to @mime_type, if not %NULL.
 *
 * It suffers from the same flaws as camel_data_wrapper_set_mime_type().
 **/
void
camel_data_wrapper_set_mime_type_field (CamelDataWrapper *data_wrapper,
                                        CamelContentType *mime_type)
{
	CamelDataWrapperClass *class;

	g_return_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper));
	g_return_if_fail (mime_type != NULL);

	class = CAMEL_DATA_WRAPPER_GET_CLASS (data_wrapper);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->set_mime_type_field != NULL);

	class->set_mime_type_field (data_wrapper, mime_type);
}

/**
 * camel_data_wrapper_take_mime_type_field:
 * @data_wrapper: a #CamelDataWrapper
 * @mime_type: (nullable) (transfer full): a #CamelContentType
 *
 * Sets mime-type filed to be @mime_type and consumes it, aka unlike
 * camel_data_wrapper_set_mime_type_field(), this doesn't add its own
 * reference to @mime_type.
 *
 * It suffers from the same flaws as camel_data_wrapper_set_mime_type().
 *
 * Since: 3.24
 **/
void
camel_data_wrapper_take_mime_type_field (CamelDataWrapper *data_wrapper,
					 CamelContentType *mime_type)
{
	g_return_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper));
	g_return_if_fail (mime_type != NULL);

	camel_data_wrapper_set_mime_type_field (data_wrapper, mime_type);

	if (mime_type)
		camel_content_type_unref (mime_type);
}

/**
 * camel_data_wrapper_is_offline:
 * @data_wrapper: a #CamelDataWrapper
 *
 * Returns: whether @data_wrapper is "offline" (data stored
 * remotely) or not. Some optional code paths may choose to not
 * operate on offline data.
 **/
gboolean
camel_data_wrapper_is_offline (CamelDataWrapper *data_wrapper)
{
	CamelDataWrapperClass *class;

	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), TRUE);

	class = CAMEL_DATA_WRAPPER_GET_CLASS (data_wrapper);
	g_return_val_if_fail (class != NULL, TRUE);
	g_return_val_if_fail (class->is_offline != NULL, TRUE);

	return class->is_offline (data_wrapper);
}

/**
 * camel_data_wrapper_set_offline:
 * @data_wrapper: a #CamelDataWrapper
 * @offline: whether the @data_wrapper is "offline"
 *
 * Sets whether the @data_wrapper is "offline". It applies only to this
 * concrete instance. See camel_data_wrapper_is_offline().
 *
 * Since: 3.24
 **/
void
camel_data_wrapper_set_offline (CamelDataWrapper *data_wrapper,
				gboolean offline)
{
	g_return_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper));

	data_wrapper->priv->offline = offline;
}

/**
 * camel_data_wrapper_write_to_stream_sync:
 * @data_wrapper: a #CamelDataWrapper
 * @stream: a #CamelStream for output
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Writes the content of @data_wrapper to @stream in a machine-independent
 * format appropriate for the data.  It should be possible to construct an
 * equivalent data wrapper object later by passing this stream to
 * camel_data_wrapper_construct_from_stream_sync().
 *
 * <note>
 *   <para>
 *     This function may block even if the given output stream does not.
 *     For example, the content may have to be fetched across a network
 *     before it can be written to @stream.
 *   </para>
 * </note>
 *
 * Returns: the number of bytes written, or -1 on error
 *
 * Since: 3.0
 **/
gssize
camel_data_wrapper_write_to_stream_sync (CamelDataWrapper *data_wrapper,
                                         CamelStream *stream,
                                         GCancellable *cancellable,
                                         GError **error)
{
	CamelDataWrapperClass *class;
	gssize bytes_written;

	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), -1);
	g_return_val_if_fail (CAMEL_IS_STREAM (stream), -1);

	class = CAMEL_DATA_WRAPPER_GET_CLASS (data_wrapper);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->write_to_stream_sync != NULL, -1);

	bytes_written = class->write_to_stream_sync (
		data_wrapper, stream, cancellable, error);
	CAMEL_CHECK_GERROR (
		data_wrapper, write_to_stream_sync,
		bytes_written >= 0, error);

	return bytes_written;
}

/* Helper for camel_data_wrapper_write_to_stream() */
static void
data_wrapper_write_to_stream_thread (GTask *task,
                                     gpointer source_object,
                                     gpointer task_data,
                                     GCancellable *cancellable)
{
	gssize bytes_written;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	bytes_written = camel_data_wrapper_write_to_stream_sync (
		CAMEL_DATA_WRAPPER (source_object),
		async_context->stream,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_int (task, bytes_written);
	}
}

/**
 * camel_data_wrapper_write_to_stream:
 * @data_wrapper: a #CamelDataWrapper
 * @stream: a #CamelStream for writed data to be written to
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously writes the content of @data_wrapper to @stream in a
 * machine-independent format appropriate for the data.  It should be
 * possible to construct an equivalent data wrapper object later by
 * passing this stream to camel_data_wrapper_construct_from_stream().
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_data_wrapper_write_to_stream_finish() to get the result of
 * the operation.
 *
 * Since: 3.0
 **/
void
camel_data_wrapper_write_to_stream (CamelDataWrapper *data_wrapper,
                                    CamelStream *stream,
                                    gint io_priority,
                                    GCancellable *cancellable,
                                    GAsyncReadyCallback callback,
                                    gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper));
	g_return_if_fail (CAMEL_IS_STREAM (stream));

	async_context = g_slice_new0 (AsyncContext);
	async_context->stream = g_object_ref (stream);

	task = g_task_new (data_wrapper, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_data_wrapper_write_to_stream);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, data_wrapper_write_to_stream_thread);

	g_object_unref (task);
}

/**
 * camel_data_wrapper_write_to_stream_finish:
 * @data_wrapper: a #CamelDataWrapper
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_data_wrapper_write_to_stream().
 *
 * Returns: the number of bytes written, or -1 or error
 *
 * Since: 3.0
 **/
gssize
camel_data_wrapper_write_to_stream_finish (CamelDataWrapper *data_wrapper,
                                           GAsyncResult *result,
                                           GError **error)
{
	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), -1);
	g_return_val_if_fail (g_task_is_valid (result, data_wrapper), -1);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_data_wrapper_write_to_stream), -1);

	return g_task_propagate_int (G_TASK (result), error);
}

/**
 * camel_data_wrapper_decode_to_stream_sync:
 * @data_wrapper: a #CamelDataWrapper
 * @stream: a #CamelStream for decoded data to be written to
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Writes the decoded data content to @stream.
 *
 * <note>
 *   <para>
 *     This function may block even if the given output stream does not.
 *     For example, the content may have to be fetched across a network
 *     before it can be written to @stream.
 *   </para>
 * </note>
 *
 * Returns: the number of bytes written, or -1 on error
 *
 * Since: 3.0
 **/
gssize
camel_data_wrapper_decode_to_stream_sync (CamelDataWrapper *data_wrapper,
                                          CamelStream *stream,
                                          GCancellable *cancellable,
                                          GError **error)
{
	CamelDataWrapperClass *class;
	gssize bytes_written;

	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), -1);
	g_return_val_if_fail (CAMEL_IS_STREAM (stream), -1);

	class = CAMEL_DATA_WRAPPER_GET_CLASS (data_wrapper);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->decode_to_stream_sync != NULL, -1);

	bytes_written = class->decode_to_stream_sync (
		data_wrapper, stream, cancellable, error);
	CAMEL_CHECK_GERROR (
		data_wrapper, decode_to_stream_sync,
		bytes_written >= 0, error);

	return bytes_written;
}

/* Helper for camel_data_wrapper_decode_to_stream() */
static void
data_wrapper_decode_to_stream_thread (GTask *task,
                                      gpointer source_object,
                                      gpointer task_data,
                                      GCancellable *cancellable)
{
	gssize bytes_written;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	bytes_written = camel_data_wrapper_decode_to_stream_sync (
		CAMEL_DATA_WRAPPER (source_object),
		async_context->stream,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_int (task, bytes_written);
	}
}

/**
 * camel_data_wrapper_decode_to_stream:
 * @data_wrapper: a #CamelDataWrapper
 * @stream: a #CamelStream for decoded data to be written to
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously writes the decoded data content to @stream.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_data_wrapper_decode_to_stream_finish() to get the result of
 * the operation.
 *
 * Since: 3.0
 **/
void
camel_data_wrapper_decode_to_stream (CamelDataWrapper *data_wrapper,
                                     CamelStream *stream,
                                     gint io_priority,
                                     GCancellable *cancellable,
                                     GAsyncReadyCallback callback,
                                     gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper));
	g_return_if_fail (CAMEL_IS_STREAM (stream));

	async_context = g_slice_new0 (AsyncContext);
	async_context->stream = g_object_ref (stream);

	task = g_task_new (data_wrapper, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_data_wrapper_decode_to_stream);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, data_wrapper_decode_to_stream_thread);

	g_object_unref (task);
}

/**
 * camel_data_wrapper_decode_to_stream_finish:
 * @data_wrapper: a #CamelDataWrapper
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_data_wrapper_decode_to_stream().
 *
 * Returns: the number of bytes written, or -1 on error
 *
 * Since: 3.0
 **/
gssize
camel_data_wrapper_decode_to_stream_finish (CamelDataWrapper *data_wrapper,
                                            GAsyncResult *result,
                                            GError **error)
{
	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), -1);
	g_return_val_if_fail (g_task_is_valid (result, data_wrapper), -1);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_data_wrapper_decode_to_stream), -1);

	return g_task_propagate_int (G_TASK (result), error);
}

/**
 * camel_data_wrapper_construct_from_stream_sync:
 * @data_wrapper: a #CamelDataWrapper
 * @stream: an input #CamelStream
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Constructs the content of @data_wrapper from the given @stream.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_data_wrapper_construct_from_stream_sync (CamelDataWrapper *data_wrapper,
                                               CamelStream *stream,
                                               GCancellable *cancellable,
                                               GError **error)
{
	CamelDataWrapperClass *class;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), FALSE);
	g_return_val_if_fail (CAMEL_IS_STREAM (stream), FALSE);

	class = CAMEL_DATA_WRAPPER_GET_CLASS (data_wrapper);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->construct_from_stream_sync != NULL, FALSE);

	success = class->construct_from_stream_sync (
		data_wrapper, stream, cancellable, error);
	CAMEL_CHECK_GERROR (
		data_wrapper, construct_from_stream_sync, success, error);

	return success;
}

/* Helper for camel_data_wrapper_construct_from_stream() */
static void
data_wrapper_construct_from_stream_thread (GTask *task,
                                           gpointer source_object,
                                           gpointer task_data,
                                           GCancellable *cancellable)
{
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	success = camel_data_wrapper_construct_from_stream_sync (
		CAMEL_DATA_WRAPPER (source_object),
		async_context->stream,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_data_wrapper_construct_from_stream:
 * @data_wrapper: a #CamelDataWrapper
 * @stream: an input #CamelStream
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously constructs the content of @data_wrapper from the given
 * @stream.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_data_wrapper_construct_from_stream_finish() to get the result
 * of the operation.
 *
 * Since: 3.0
 **/
void
camel_data_wrapper_construct_from_stream (CamelDataWrapper *data_wrapper,
                                          CamelStream *stream,
                                          gint io_priority,
                                          GCancellable *cancellable,
                                          GAsyncReadyCallback callback,
                                          gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper));
	g_return_if_fail (CAMEL_IS_STREAM (stream));

	async_context = g_slice_new0 (AsyncContext);
	async_context->stream = g_object_ref (stream);

	task = g_task_new (data_wrapper, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_data_wrapper_construct_from_stream);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, data_wrapper_construct_from_stream_thread);

	g_object_unref (task);
}

/**
 * camel_data_wrapper_construct_from_stream_finish:
 * @data_wrapper: a #CamelDataWrapper
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with
 * camel_data_wrapper_construct_from_stream().
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_data_wrapper_construct_from_stream_finish (CamelDataWrapper *data_wrapper,
                                                 GAsyncResult *result,
                                                 GError **error)
{
	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, data_wrapper), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_data_wrapper_construct_from_stream), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_data_wrapper_write_to_output_stream_sync:
 * @data_wrapper: a #CamelDataWrapper
 * @output_stream: a #GOutputStream
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Writes the content of @data_wrapper to @output_stream in a
 * machine-independent format appropriate for the data.
 *
 * <note>
 *   <para>
 *     This function may block even if the given output stream does not.
 *     For example, the content may have to be fetched across a network
 *     before it can be written to @output_stream.
 *   </para>
 * </note>
 *
 * Returns: the number of bytes written, or -1 on error
 *
 * Since: 3.12
 **/
gssize
camel_data_wrapper_write_to_output_stream_sync (CamelDataWrapper *data_wrapper,
                                                GOutputStream *output_stream,
                                                GCancellable *cancellable,
                                                GError **error)
{
	CamelDataWrapperClass *class;
	gssize bytes_written;

	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), -1);
	g_return_val_if_fail (G_IS_OUTPUT_STREAM (output_stream), -1);

	class = CAMEL_DATA_WRAPPER_GET_CLASS (data_wrapper);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->write_to_output_stream_sync != NULL, -1);

	bytes_written = class->write_to_output_stream_sync (
		data_wrapper, output_stream, cancellable, error);
	CAMEL_CHECK_GERROR (
		data_wrapper, write_to_output_stream_sync,
		bytes_written >= 0, error);

	if (bytes_written >= 0) {
		if (!g_output_stream_flush (output_stream, cancellable, error))
			bytes_written = -1;
	}

	return bytes_written;
}

/* Helper for camel_data_wrapper_write_to_output_stream() */
static void
data_wrapper_write_to_output_stream_thread (GTask *task,
                                            gpointer source_object,
                                            gpointer task_data,
                                            GCancellable *cancellable)
{
	gssize bytes_written;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	bytes_written = camel_data_wrapper_write_to_output_stream_sync (
		CAMEL_DATA_WRAPPER (source_object),
		async_context->output_stream,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_int (task, bytes_written);
	}
}

/**
 * camel_data_wrapper_write_to_output_stream:
 * @data_wrapper: a #CamelDataWrapper
 * @output_stream: a #GOutputStream
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously writes the content of @data_wrapper to @output_stream in
 * a machine-independent format appropriate for the data.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_data_wrapper_write_to_output_stream_finish() to get the result
 * of the operation.
 *
 * Since: 3.12
 **/
void
camel_data_wrapper_write_to_output_stream (CamelDataWrapper *data_wrapper,
                                           GOutputStream *output_stream,
                                           gint io_priority,
                                           GCancellable *cancellable,
                                           GAsyncReadyCallback callback,
                                           gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper));
	g_return_if_fail (G_IS_OUTPUT_STREAM (output_stream));

	async_context = g_slice_new0 (AsyncContext);
	async_context->output_stream = g_object_ref (output_stream);

	task = g_task_new (data_wrapper, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_data_wrapper_write_to_output_stream);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (
		task, data_wrapper_write_to_output_stream_thread);

	g_object_unref (task);
}

/**
 * camel_data_wrapper_write_to_output_stream_finish:
 * @data_wrapper: a #CamelDataWrapper
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with
 * camel_data_wrapper_write_to_output_stream().
 *
 * Returns: the number of bytes written, or -1 on error
 *
 * Since: 3.12
 **/
gssize
camel_data_wrapper_write_to_output_stream_finish (CamelDataWrapper *data_wrapper,
                                                  GAsyncResult *result,
                                                  GError **error)
{
	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), -1);
	g_return_val_if_fail (g_task_is_valid (result, data_wrapper), -1);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_data_wrapper_write_to_output_stream), -1);

	return g_task_propagate_int (G_TASK (result), error);
}

/**
 * camel_data_wrapper_decode_to_output_stream_sync:
 * @data_wrapper: a #CamelDataWrapper
 * @output_stream: a #GOutputStream
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Writes the decoded data content to @output_stream.
 *
 * <note>
 *   <para>
 *     This function may block even if the given output stream does not.
 *     For example, the content may have to be fetched across a network
 *     before it can be written to @output_stream.
 *   </para>
 * </note>
 *
 * Returns: the number of bytes written, or -1 on error
 *
 * Since: 3.12
 **/
gssize
camel_data_wrapper_decode_to_output_stream_sync (CamelDataWrapper *data_wrapper,
                                                 GOutputStream *output_stream,
                                                 GCancellable *cancellable,
                                                 GError **error)
{
	CamelDataWrapperClass *class;
	gssize bytes_written;

	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), -1);
	g_return_val_if_fail (G_IS_OUTPUT_STREAM (output_stream), -1);

	class = CAMEL_DATA_WRAPPER_GET_CLASS (data_wrapper);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->decode_to_output_stream_sync != NULL, -1);

	bytes_written = class->decode_to_output_stream_sync (
		data_wrapper, output_stream, cancellable, error);
	CAMEL_CHECK_GERROR (
		data_wrapper, decode_to_output_stream_sync,
		bytes_written >= 0, error);

	return bytes_written;
}

/* Helper for camel_data_wrapper_decode_to_output_stream() */
static void
data_wrapper_decode_to_output_stream_thread (GTask *task,
                                             gpointer source_object,
                                             gpointer task_data,
                                             GCancellable *cancellable)
{
	gssize bytes_written;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	bytes_written = camel_data_wrapper_decode_to_output_stream_sync (
		CAMEL_DATA_WRAPPER (source_object),
		async_context->output_stream,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_int (task, bytes_written);
	}
}

/**
 * camel_data_wrapper_decode_to_output_stream:
 * @data_wrapper: a #CamelDataWrapper
 * @output_stream: a #GOutputStream
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously writes the decoded data content to @output_stream.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_data_wrapper_decode_to_output_stream_finish() to get the result
 * of the operation.
 *
 * Since: 3.12
 **/
void
camel_data_wrapper_decode_to_output_stream (CamelDataWrapper *data_wrapper,
                                            GOutputStream *output_stream,
                                            gint io_priority,
                                            GCancellable *cancellable,
                                            GAsyncReadyCallback callback,
                                            gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper));
	g_return_if_fail (G_IS_OUTPUT_STREAM (output_stream));

	async_context = g_slice_new0 (AsyncContext);
	async_context->output_stream = g_object_ref (output_stream);

	task = g_task_new (data_wrapper, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_data_wrapper_decode_to_output_stream);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (
		task, data_wrapper_decode_to_output_stream_thread);

	g_object_unref (task);
}

/**
 * camel_data_wrapper_decode_to_output_stream_finish:
 * @data_wrapper: a #CamelDataWrapper
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with
 * camel_data_wrapper_decode_to_output_stream().
 *
 * Returns: the number of bytes written, or -1 on error
 *
 * Since: 3.12
 **/
gssize
camel_data_wrapper_decode_to_output_stream_finish (CamelDataWrapper *data_wrapper,
                                                   GAsyncResult *result,
                                                   GError **error)
{
	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), -1);
	g_return_val_if_fail (g_task_is_valid (result, data_wrapper), -1);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_data_wrapper_decode_to_output_stream), -1);

	return g_task_propagate_int (G_TASK (result), error);
}

/**
 * camel_data_wrapper_construct_from_input_stream_sync:
 * @data_wrapper: a #CamelDataWrapper
 * @input_stream: a #GInputStream
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Constructs the content of @data_wrapper from @input_stream.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.12
 **/
gboolean
camel_data_wrapper_construct_from_input_stream_sync (CamelDataWrapper *data_wrapper,
                                                     GInputStream *input_stream,
                                                     GCancellable *cancellable,
                                                     GError **error)
{
	CamelDataWrapperClass *class;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), FALSE);
	g_return_val_if_fail (G_IS_INPUT_STREAM (input_stream), FALSE);

	class = CAMEL_DATA_WRAPPER_GET_CLASS (data_wrapper);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->construct_from_input_stream_sync != NULL, FALSE);

	success = class->construct_from_input_stream_sync (
		data_wrapper, input_stream, cancellable, error);
	CAMEL_CHECK_GERROR (
		data_wrapper, construct_from_input_stream_sync, success, error);

	return success;
}

/* Helper for camel_data_wrapper_construct_from_input_stream() */
static void
data_wrapper_construct_from_input_stream_thread (GTask *task,
                                                 gpointer source_object,
                                                 gpointer task_data,
                                                 GCancellable *cancellable)
{
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	success = camel_data_wrapper_construct_from_input_stream_sync (
		CAMEL_DATA_WRAPPER (source_object),
		async_context->input_stream,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_data_wrapper_construct_from_input_stream:
 * @data_wrapper: a #CamelDataWrapper
 * @input_stream: a #GInputStream
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously constructs the content of @data_wrapper from @input_stream.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_data_wrapper_construct_from_input_stream_finish() to get the
 * result of the operation.
 *
 * Since: 3.12
 **/
void
camel_data_wrapper_construct_from_input_stream (CamelDataWrapper *data_wrapper,
                                                GInputStream *input_stream,
                                                gint io_priority,
                                                GCancellable *cancellable,
                                                GAsyncReadyCallback callback,
                                                gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper));
	g_return_if_fail (G_IS_INPUT_STREAM (input_stream));

	async_context = g_slice_new0 (AsyncContext);
	async_context->input_stream = g_object_ref (input_stream);

	task = g_task_new (data_wrapper, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_data_wrapper_construct_from_input_stream);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, data_wrapper_construct_from_input_stream_thread);

	g_object_unref (task);
}

/**
 * camel_data_wrapper_construct_from_input_stream_finish:
 * @data_wrapper: a #CamelDataWrapper
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with
 * camel_data_wrapper_construct_from_input_stream().
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.12
 **/
gboolean
camel_data_wrapper_construct_from_input_stream_finish (CamelDataWrapper *data_wrapper,
                                                       GAsyncResult *result,
                                                       GError **error)
{
	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, data_wrapper), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_data_wrapper_construct_from_input_stream), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_data_wrapper_calculate_size_sync:
 * @data_wrapper: a #CamelDataWrapper
 * @cancellable: a #GCancellable, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Calculates size of the @data_wrapper by saving it to a null-stream
 * and returns how many bytes had been written. It's using
 * camel_data_wrapper_write_to_stream_sync() internally.
 *
 * Returns: how many bytes the @data_wrapper would use when saved,
 *   or -1 on error.
 *
 * Since: 3.24
 **/
gsize
camel_data_wrapper_calculate_size_sync (CamelDataWrapper *data_wrapper,
					GCancellable *cancellable,
					GError **error)
{
	CamelStream *stream;
	gsize bytes_written = -1;

	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), -1);

	stream = camel_stream_null_new ();

	if (camel_data_wrapper_write_to_stream_sync (data_wrapper, stream, cancellable, error))
		bytes_written = camel_stream_null_get_bytes_written (CAMEL_STREAM_NULL (stream));

	g_object_unref (stream);

	return bytes_written;
}

/**
 * camel_data_wrapper_calculate_decoded_size_sync:
 * @data_wrapper: a #CamelDataWrapper
 * @cancellable: a #GCancellable, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Calculates decoded size of the @data_wrapper by saving it to a null-stream
 * and returns how many bytes had been written. It's using
 * camel_data_wrapper_decode_to_stream_sync() internally.
 *
 * Returns: how many bytes the @data_wrapper would use when saved,
 *   or -1 on error.
 *
 * Since: 3.24
 **/
gsize
camel_data_wrapper_calculate_decoded_size_sync (CamelDataWrapper *data_wrapper,
						GCancellable *cancellable,
						GError **error)
{
	CamelStream *stream;
	gsize bytes_written = -1;

	g_return_val_if_fail (CAMEL_IS_DATA_WRAPPER (data_wrapper), -1);

	stream = camel_stream_null_new ();

	if (camel_data_wrapper_decode_to_stream_sync (data_wrapper, stream, cancellable, error))
		bytes_written = camel_stream_null_get_bytes_written (CAMEL_STREAM_NULL (stream));

	g_object_unref (stream);

	return bytes_written;
}
