/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-stream.c : abstract class for a stream
 *
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

#include <glib/gi18n-lib.h>

#include <camel/camel-debug.h>

#include "camel-stream.h"

#define CAMEL_STREAM_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_STREAM, CamelStreamPrivate))

struct _CamelStreamPrivate {
	GIOStream *base_stream;
	GMutex base_stream_lock;
	gboolean eos;
};

enum {
	PROP_0,
	PROP_BASE_STREAM
};

/* Forward Declarations */
static void	camel_stream_seekable_init	(GSeekableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	CamelStream,
	camel_stream,
	G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_SEEKABLE,
		camel_stream_seekable_init))

static void
stream_set_property (GObject *object,
                     guint property_id,
                     const GValue *value,
                     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_BASE_STREAM:
			camel_stream_set_base_stream (
				CAMEL_STREAM (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
stream_get_property (GObject *object,
                     guint property_id,
                     GValue *value,
                     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_BASE_STREAM:
			g_value_take_object (
				value,
				camel_stream_ref_base_stream (
				CAMEL_STREAM (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
stream_dispose (GObject *object)
{
	CamelStreamPrivate *priv;

	priv = CAMEL_STREAM_GET_PRIVATE (object);

	g_clear_object (&priv->base_stream);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_stream_parent_class)->dispose (object);
}

static void
stream_finalize (GObject *object)
{
	CamelStreamPrivate *priv;

	priv = CAMEL_STREAM_GET_PRIVATE (object);

	g_mutex_clear (&priv->base_stream_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_stream_parent_class)->finalize (object);
}

static gssize
stream_read (CamelStream *stream,
             gchar *buffer,
             gsize n,
             GCancellable *cancellable,
             GError **error)
{
	GIOStream *base_stream;
	gssize n_bytes_read = 0;

	base_stream = camel_stream_ref_base_stream (stream);

	if (base_stream != NULL) {
		GInputStream *input_stream;

		input_stream = g_io_stream_get_input_stream (base_stream);

		n_bytes_read = g_input_stream_read (
			input_stream, buffer, n, cancellable, error);

		g_object_unref (base_stream);
	}

	stream->priv->eos = n_bytes_read <= 0;

	return n_bytes_read;
}

static gssize
stream_write (CamelStream *stream,
              const gchar *buffer,
              gsize n,
              GCancellable *cancellable,
              GError **error)
{
	GIOStream *base_stream;
	gssize n_bytes_written = -1;

	base_stream = camel_stream_ref_base_stream (stream);

	if (base_stream != NULL) {
		GOutputStream *output_stream;
		gsize n_written = 0;

		output_stream = g_io_stream_get_output_stream (base_stream);
		stream->priv->eos = FALSE;

		if (g_output_stream_write_all (output_stream, buffer, n, &n_written, cancellable, error))
			n_bytes_written = (gssize) n_written;
		else
			n_bytes_written = -1;

		g_object_unref (base_stream);
	} else {
		g_set_error_literal (error, G_IO_ERROR, G_IO_ERROR_FAILED, _("Cannot write with no base stream"));
	}

	return n_bytes_written;
}

static gint
stream_close (CamelStream *stream,
              GCancellable *cancellable,
              GError **error)
{
	GIOStream *base_stream;
	gboolean success = TRUE;

	base_stream = camel_stream_ref_base_stream (stream);

	if (base_stream != NULL) {
		success = g_io_stream_close (
			base_stream, cancellable, error);

		g_object_unref (base_stream);
	}

	return success ? 0 : -1;
}

static gint
stream_flush (CamelStream *stream,
              GCancellable *cancellable,
              GError **error)
{
	GIOStream *base_stream;
	gboolean success = TRUE;

	base_stream = camel_stream_ref_base_stream (stream);

	if (base_stream != NULL) {
		GOutputStream *output_stream;

		output_stream = g_io_stream_get_output_stream (base_stream);

		success = g_output_stream_flush (
			output_stream, cancellable, error);

		g_object_unref (base_stream);
	}

	return success ? 0 : -1;
}

static gboolean
stream_eos (CamelStream *stream)
{
	return stream->priv->eos;
}

static goffset
stream_tell (GSeekable *seekable)
{
	CamelStream *stream;
	GIOStream *base_stream;
	goffset position = 0;

	stream = CAMEL_STREAM (seekable);
	base_stream = camel_stream_ref_base_stream (stream);

	if (G_IS_SEEKABLE (base_stream)) {
		position = g_seekable_tell (G_SEEKABLE (base_stream));
	} else if (base_stream != NULL) {
		g_critical (
			"Stream type '%s' is not seekable",
			G_OBJECT_TYPE_NAME (base_stream));
	}

	g_clear_object (&base_stream);

	return position;
}

static gboolean
stream_can_seek (GSeekable *seekable)
{
	CamelStream *stream;
	GIOStream *base_stream;
	gboolean can_seek = FALSE;

	stream = CAMEL_STREAM (seekable);
	base_stream = camel_stream_ref_base_stream (stream);

	if (G_IS_SEEKABLE (base_stream))
		can_seek = g_seekable_can_seek (G_SEEKABLE (base_stream));

	g_clear_object (&base_stream);

	return can_seek;
}

static gboolean
stream_seek (GSeekable *seekable,
             goffset offset,
             GSeekType type,
             GCancellable *cancellable,
             GError **error)
{
	CamelStream *stream;
	GIOStream  *base_stream;
	gboolean success = FALSE;

	stream = CAMEL_STREAM (seekable);
	base_stream = camel_stream_ref_base_stream (stream);

	if (G_IS_SEEKABLE (base_stream)) {
		stream->priv->eos = FALSE;
		success = g_seekable_seek (
			G_SEEKABLE (base_stream),
			offset, type, cancellable, error);
	} else if (base_stream != NULL) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_NOT_SUPPORTED,
			_("Stream type “%s” is not seekable"),
			G_OBJECT_TYPE_NAME (base_stream));
	} else {
		g_warn_if_reached ();
	}

	g_clear_object (&base_stream);

	return success;
}

static gboolean
stream_can_truncate (GSeekable *seekable)
{
	CamelStream *stream;
	GIOStream *base_stream;
	gboolean can_truncate = FALSE;

	stream = CAMEL_STREAM (seekable);
	base_stream = camel_stream_ref_base_stream (stream);

	if (G_IS_SEEKABLE (base_stream))
		can_truncate = g_seekable_can_truncate (
			G_SEEKABLE (base_stream));

	g_clear_object (&base_stream);

	return can_truncate;
}

static gboolean
stream_truncate (GSeekable *seekable,
                 goffset offset,
                 GCancellable *cancellable,
                 GError **error)
{
	CamelStream *stream;
	GIOStream *base_stream;
	gboolean success = FALSE;

	stream = CAMEL_STREAM (seekable);
	base_stream = camel_stream_ref_base_stream (stream);

	if (G_IS_SEEKABLE (base_stream)) {
		success = g_seekable_truncate (
			G_SEEKABLE (base_stream),
			offset, cancellable, error);
	} else if (base_stream != NULL) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_NOT_SUPPORTED,
			_("Stream type “%s” is not seekable"),
			G_OBJECT_TYPE_NAME (base_stream));
	} else {
		g_warn_if_reached ();
	}

	g_clear_object (&base_stream);

	return success;
}

static void
camel_stream_class_init (CamelStreamClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelStreamPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = stream_set_property;
	object_class->get_property = stream_get_property;
	object_class->dispose = stream_dispose;
	object_class->finalize = stream_finalize;

	class->read = stream_read;
	class->write = stream_write;
	class->close = stream_close;
	class->flush = stream_flush;
	class->eos = stream_eos;

	g_object_class_install_property (
		object_class,
		PROP_BASE_STREAM,
		g_param_spec_object (
			"base-stream",
			"Base Stream",
			"The base GIOStream",
			G_TYPE_IO_STREAM,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));
}

static void
camel_stream_seekable_init (GSeekableIface *iface)
{
	iface->tell = stream_tell;
	iface->can_seek = stream_can_seek;
	iface->seek = stream_seek;
	iface->can_truncate = stream_can_truncate;
	iface->truncate_fn = stream_truncate;
}

static void
camel_stream_init (CamelStream *stream)
{
	stream->priv = CAMEL_STREAM_GET_PRIVATE (stream);

	g_mutex_init (&stream->priv->base_stream_lock);
}

/**
 * camel_stream_new:
 * @base_stream: a #GIOStream
 *
 * Creates a #CamelStream as a thin wrapper for @base_stream.
 *
 * Returns: a #CamelStream
 *
 * Since: 3.12
 **/
CamelStream *
camel_stream_new (GIOStream *base_stream)
{
	g_return_val_if_fail (G_IS_IO_STREAM (base_stream), NULL);

	return g_object_new (
		CAMEL_TYPE_STREAM, "base-stream", base_stream, NULL);
}

/**
 * camel_stream_ref_base_stream:
 * @stream: a #CamelStream
 *
 * Returns the #GIOStream for @stream.  This is only valid if @stream was
 * created with camel_stream_new().  For all other #CamelStream subclasses
 * this function returns %NULL.
 *
 * The returned #GIOStream is referenced for thread-safety and should be
 * unreferenced with g_object_unref() when finished with it.
 *
 * Returns: (transfer full) (nullable): a #GIOStream, or %NULL
 *
 * Since: 3.12
 **/
GIOStream *
camel_stream_ref_base_stream (CamelStream *stream)
{
	GIOStream *base_stream = NULL;

	g_return_val_if_fail (CAMEL_IS_STREAM (stream), NULL);

	g_mutex_lock (&stream->priv->base_stream_lock);

	if (stream->priv->base_stream != NULL)
		base_stream = g_object_ref (stream->priv->base_stream);

	g_mutex_unlock (&stream->priv->base_stream_lock);

	return base_stream;
}

/**
 * camel_stream_set_base_stream:
 * @stream: a #CamelStream
 * @base_stream: a #GIOStream
 *
 * Replaces the #GIOStream passed to camel_stream_new() with @base_stream.
 * The new @base_stream should wrap the original #GIOStream, such as when
 * adding Transport Layer Security after issuing a STARTTLS command.
 *
 * Since: 3.12
 **/
void
camel_stream_set_base_stream (CamelStream *stream,
                              GIOStream *base_stream)
{
	g_return_if_fail (CAMEL_IS_STREAM (stream));
	g_return_if_fail (G_IS_IO_STREAM (base_stream));

	g_mutex_lock (&stream->priv->base_stream_lock);

	g_clear_object (&stream->priv->base_stream);
	stream->priv->base_stream = g_object_ref (base_stream);

	g_mutex_unlock (&stream->priv->base_stream_lock);

	g_object_notify (G_OBJECT (stream), "base-stream");
}

/**
 * camel_stream_read:
 * @stream: a #CamelStream object.
 * @buffer: (array length=n) (type gchar): output buffer
 * @n: max number of bytes to read.
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Attempts to read up to @n bytes from @stream into @buffer.
 *
 * Returns: the number of bytes actually read, or -1 on error and set
 * errno.
 **/
gssize
camel_stream_read (CamelStream *stream,
                   gchar *buffer,
                   gsize n,
                   GCancellable *cancellable,
                   GError **error)
{
	CamelStreamClass *class;
	gssize n_bytes;

	g_return_val_if_fail (CAMEL_IS_STREAM (stream), -1);
	g_return_val_if_fail (n == 0 || buffer, -1);

	class = CAMEL_STREAM_GET_CLASS (stream);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->read != NULL, -1);

	n_bytes = class->read (stream, buffer, n, cancellable, error);
	CAMEL_CHECK_GERROR (stream, read, n_bytes >= 0, error);

	return n_bytes;
}

/**
 * camel_stream_write:
 * @stream: a #CamelStream object
 * @buffer: (array length=n) (type gchar): buffer to write.
 * @n: number of bytes to write
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Attempts to write up to @n bytes of @buffer into @stream.
 *
 * Returns: the number of bytes written to the stream, or -1 on error
 * along with setting errno.
 **/
gssize
camel_stream_write (CamelStream *stream,
                    const gchar *buffer,
                    gsize n,
                    GCancellable *cancellable,
                    GError **error)
{
	CamelStreamClass *class;
	gssize n_bytes;

	g_return_val_if_fail (CAMEL_IS_STREAM (stream), -1);
	g_return_val_if_fail (n == 0 || buffer, -1);

	class = CAMEL_STREAM_GET_CLASS (stream);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->write != NULL, -1);

	n_bytes = class->write (stream, buffer, n, cancellable, error);
	CAMEL_CHECK_GERROR (stream, write, n_bytes >= 0, error);

	return n_bytes;
}

/**
 * camel_stream_flush:
 * @stream: a #CamelStream object
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Flushes any buffered data to the stream's backing store.  Only
 * meaningful for writable streams.
 *
 * Returns: 0 on success or -1 on fail along with setting @error
 **/
gint
camel_stream_flush (CamelStream *stream,
                    GCancellable *cancellable,
                    GError **error)
{
	CamelStreamClass *class;
	gint retval;

	g_return_val_if_fail (CAMEL_IS_STREAM (stream), -1);

	class = CAMEL_STREAM_GET_CLASS (stream);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->flush != NULL, -1);

	retval = class->flush (stream, cancellable, error);
	CAMEL_CHECK_GERROR (stream, flush, retval == 0, error);

	return retval;
}

/**
 * camel_stream_close:
 * @stream: a #CamelStream object
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Closes the stream.
 *
 * Returns: 0 on success or -1 on error.
 **/
gint
camel_stream_close (CamelStream *stream,
                    GCancellable *cancellable,
                    GError **error)
{
	CamelStreamClass *class;
	gint retval;

	g_return_val_if_fail (CAMEL_IS_STREAM (stream), -1);

	class = CAMEL_STREAM_GET_CLASS (stream);
	g_return_val_if_fail (class != NULL, -1);
	g_return_val_if_fail (class->close != NULL, -1);

	retval = class->close (stream, cancellable, error);
	CAMEL_CHECK_GERROR (stream, close, retval == 0, error);

	return retval;
}

/**
 * camel_stream_eos:
 * @stream: a #CamelStream object
 *
 * Tests if there are bytes left to read on the @stream object.
 *
 * Returns: %TRUE on EOS or %FALSE otherwise.
 **/
gboolean
camel_stream_eos (CamelStream *stream)
{
	CamelStreamClass *class;

	g_return_val_if_fail (CAMEL_IS_STREAM (stream), TRUE);

	class = CAMEL_STREAM_GET_CLASS (stream);
	g_return_val_if_fail (class != NULL, TRUE);
	g_return_val_if_fail (class->eos != NULL, TRUE);

	return class->eos (stream);
}

/***************** Utility functions ********************/

/**
 * camel_stream_write_string:
 * @stream: a #CamelStream object
 * @string: a string
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Writes the string to the stream.
 *
 * Returns: the number of characters written or -1 on error.
 **/
gssize
camel_stream_write_string (CamelStream *stream,
                           const gchar *string,
                           GCancellable *cancellable,
                           GError **error)
{
	g_return_val_if_fail (CAMEL_IS_STREAM (stream), -1);
	g_return_val_if_fail (string != NULL, -1);

	return camel_stream_write (
		stream, string, strlen (string), cancellable, error);
}

/**
 * camel_stream_write_to_stream:
 * @stream: source #CamelStream object
 * @output_stream: destination #CamelStream object
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Write all of a stream (until eos) into another stream, in a
 * blocking fashion.
 *
 * Returns: -1 on error, or the number of bytes succesfully
 * copied across streams.
 **/
gssize
camel_stream_write_to_stream (CamelStream *stream,
                              CamelStream *output_stream,
                              GCancellable *cancellable,
                              GError **error)
{
	gchar tmp_buf[4096];
	gssize total = 0;
	gssize nb_read;
	gssize nb_written;

	g_return_val_if_fail (CAMEL_IS_STREAM (stream), -1);
	g_return_val_if_fail (CAMEL_IS_STREAM (output_stream), -1);

	while (!camel_stream_eos (stream)) {
		nb_read = camel_stream_read (
			stream, tmp_buf, sizeof (tmp_buf),
			cancellable, error);
		if (nb_read < 0)
			return -1;
		else if (nb_read > 0) {
			nb_written = 0;

			while (nb_written < nb_read) {
				gssize len = camel_stream_write (
					output_stream,
					tmp_buf + nb_written,
					nb_read - nb_written,
					cancellable, error);
				if (len < 0)
					return -1;
				nb_written += len;
			}
			total += nb_written;
		}
	}
	return total;
}
