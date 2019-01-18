/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; fill-column: 160 -*- */
/* camel-stream-buffer.c : Buffer any other other stream
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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>

#include "camel-stream-buffer.h"

#define CAMEL_STREAM_BUFFER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_STREAM_BUFFER, CamelStreamBufferPrivate))

struct _CamelStreamBufferPrivate {

	CamelStream *stream;

	guchar *buf, *ptr, *end;
	gint size;

	guchar *linebuf;	/* for reading lines at a time */
	gint linesize;

	CamelStreamBufferMode mode;
};

G_DEFINE_TYPE (CamelStreamBuffer, camel_stream_buffer, CAMEL_TYPE_STREAM)

#define BUF_SIZE 1024

/* only returns the number passed in, or -1 on an error */
static gssize
stream_write_all (CamelStream *stream,
                  const gchar *buffer,
                  gsize n,
                  GCancellable *cancellable,
                  GError **error)
{
	gsize left = n, w;

	while (left > 0) {
		w = camel_stream_write (
			stream, buffer, left, cancellable, error);
		if (w == -1)
			return -1;
		left -= w;
		buffer += w;
	}

	return n;
}

static void
set_vbuf (CamelStreamBuffer *stream,
          CamelStreamBufferMode mode)
{
	CamelStreamBufferPrivate *priv;

	priv = CAMEL_STREAM_BUFFER_GET_PRIVATE (stream);

	g_free (priv->buf);

	priv->buf = g_malloc (BUF_SIZE);
	priv->ptr = priv->buf;
	priv->end = priv->buf;
	priv->size = BUF_SIZE;
	priv->mode = mode;
}

static void
stream_buffer_dispose (GObject *object)
{
	CamelStreamBufferPrivate *priv;

	priv = CAMEL_STREAM_BUFFER_GET_PRIVATE (object);

	if (priv->stream != NULL) {
		g_object_unref (priv->stream);
		priv->stream = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_stream_buffer_parent_class)->dispose (object);
}

static void
stream_buffer_finalize (GObject *object)
{
	CamelStreamBufferPrivate *priv;

	priv = CAMEL_STREAM_BUFFER_GET_PRIVATE (object);

	g_free (priv->buf);
	g_free (priv->linebuf);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_stream_buffer_parent_class)->finalize (object);
}

static gssize
stream_buffer_read (CamelStream *stream,
                    gchar *buffer,
                    gsize n,
                    GCancellable *cancellable,
                    GError **error)
{
	CamelStreamBufferPrivate *priv;
	gssize bytes_read = 1;
	gssize bytes_left;
	gchar *bptr = buffer;
	GError *local_error = NULL;

	priv = CAMEL_STREAM_BUFFER_GET_PRIVATE (stream);

	g_return_val_if_fail (
		(priv->mode & CAMEL_STREAM_BUFFER_MODE) ==
		CAMEL_STREAM_BUFFER_READ, 0);

	while (n && bytes_read > 0) {
		bytes_left = priv->end - priv->ptr;
		if (bytes_left < n) {
			if (bytes_left > 0) {
				memcpy (bptr, priv->ptr, bytes_left);
				n -= bytes_left;
				bptr += bytes_left;
				priv->ptr += bytes_left;
			}
			/* if we are reading a lot, then read directly to the destination buffer */
			if (n >= priv->size / 3) {
				bytes_read = camel_stream_read (
					priv->stream, bptr, n,
					cancellable, &local_error);
				if (bytes_read > 0) {
					n -= bytes_read;
					bptr += bytes_read;
				}
			} else {
				bytes_read = camel_stream_read (
					priv->stream, (gchar *) priv->buf,
					priv->size, cancellable, &local_error);
				if (bytes_read > 0) {
					gsize bytes_used = bytes_read > n ? n : bytes_read;
					priv->ptr = priv->buf;
					priv->end = priv->buf + bytes_read;
					memcpy (bptr, priv->ptr, bytes_used);
					priv->ptr += bytes_used;
					bptr += bytes_used;
					n -= bytes_used;
				}
			}
		} else {
			memcpy (bptr, priv->ptr, n);
			priv->ptr += n;
			bptr += n;
			n = 0;
		}
	}

	/* If camel_stream_read() failed but we managed to read some data
	 * before the failure, discard the error and return the number of
	 * bytes read.  If we didn't read any data, propagate the error. */
	if (local_error != NULL) {
		if (bptr > buffer)
			g_clear_error (&local_error);
		else {
			g_propagate_error (error, local_error);
			return -1;
		}
	}

	return (gssize)(bptr - buffer);
}

static gssize
stream_buffer_write (CamelStream *stream,
                     const gchar *buffer,
                     gsize n,
                     GCancellable *cancellable,
                     GError **error)
{
	CamelStreamBufferPrivate *priv;
	gssize total = n;
	gssize left, todo;

	priv = CAMEL_STREAM_BUFFER_GET_PRIVATE (stream);

	g_return_val_if_fail (
		(priv->mode & CAMEL_STREAM_BUFFER_MODE) ==
		CAMEL_STREAM_BUFFER_WRITE, 0);

	/* first, copy as much as we can */
	left = priv->size - (priv->ptr - priv->buf);
	todo = MIN (left, n);

	memcpy (priv->ptr, buffer, todo);
	n -= todo;
	buffer += todo;
	priv->ptr += todo;

	/* if we've filled the buffer, write it out, reset buffer */
	if (left == todo) {
		if (stream_write_all (
			priv->stream, (gchar *) priv->buf,
			priv->size, cancellable, error) == -1)
			return -1;

		priv->ptr = priv->buf;
	}

	/* if we still have more, write directly, or copy to buffer */
	if (n > 0) {
		if (n >= priv->size / 3) {
			if (stream_write_all (
				priv->stream, buffer, n,
				cancellable, error) == -1)
				return -1;
		} else {
			memcpy (priv->ptr, buffer, n);
			priv->ptr += n;
		}
	}

	return total;
}

static gint
stream_buffer_flush (CamelStream *stream,
                     GCancellable *cancellable,
                     GError **error)
{
	CamelStreamBufferPrivate *priv;

	priv = CAMEL_STREAM_BUFFER_GET_PRIVATE (stream);

	if ((priv->mode & CAMEL_STREAM_BUFFER_MODE) == CAMEL_STREAM_BUFFER_WRITE) {
		gsize len = priv->ptr - priv->buf;

		if (camel_stream_write (
			priv->stream, (gchar *) priv->buf,
			len, cancellable, error) == -1)
			return -1;

		priv->ptr = priv->buf;
	} else {
		/* nothing to do for read mode 'flush' */
	}

	return camel_stream_flush (priv->stream, cancellable, error);
}

static gint
stream_buffer_close (CamelStream *stream,
                     GCancellable *cancellable,
                     GError **error)
{
	CamelStreamBufferPrivate *priv;

	priv = CAMEL_STREAM_BUFFER_GET_PRIVATE (stream);

	if (stream_buffer_flush (stream, cancellable, error) == -1)
		return -1;

	return camel_stream_close (priv->stream, cancellable, error);
}

static gboolean
stream_buffer_eos (CamelStream *stream)
{
	CamelStreamBufferPrivate *priv;

	priv = CAMEL_STREAM_BUFFER_GET_PRIVATE (stream);

	return camel_stream_eos (priv->stream) && priv->ptr == priv->end;
}

static void
stream_buffer_init_method (CamelStreamBuffer *stream,
                           CamelStream *other_stream,
                           CamelStreamBufferMode mode)
{
	CamelStreamBufferPrivate *priv;

	priv = CAMEL_STREAM_BUFFER_GET_PRIVATE (stream);

	set_vbuf (stream, mode);

	if (priv->stream != NULL)
		g_object_unref (priv->stream);

	priv->stream = g_object_ref (other_stream);
}

static void
camel_stream_buffer_class_init (CamelStreamBufferClass *class)
{
	GObjectClass *object_class;
	CamelStreamClass *stream_class;

	g_type_class_add_private (class, sizeof (CamelStreamBufferPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = stream_buffer_dispose;
	object_class->finalize = stream_buffer_finalize;

	stream_class = CAMEL_STREAM_CLASS (class);
	stream_class->read = stream_buffer_read;
	stream_class->write = stream_buffer_write;
	stream_class->flush = stream_buffer_flush;
	stream_class->close = stream_buffer_close;
	stream_class->eos = stream_buffer_eos;

	class->init = stream_buffer_init_method;
}

static void
camel_stream_buffer_init (CamelStreamBuffer *stream)
{
	stream->priv = CAMEL_STREAM_BUFFER_GET_PRIVATE (stream);
	stream->priv->size = BUF_SIZE;
	stream->priv->buf = g_malloc (BUF_SIZE);
	stream->priv->ptr = stream->priv->buf;
	stream->priv->end = stream->priv->buf;
	stream->priv->mode =
		CAMEL_STREAM_BUFFER_READ |
		CAMEL_STREAM_BUFFER_BUFFER;
	stream->priv->stream = NULL;
	stream->priv->linesize = 80;
	stream->priv->linebuf = g_malloc (stream->priv->linesize);
}

/**
 * camel_stream_buffer_new:
 * @stream: a #CamelStream object to buffer
 * @mode: Operational mode of buffered stream.
 *
 * Create a new buffered stream of another stream.  A default
 * buffer size (1024 bytes), automatically managed will be used
 * for buffering.
 *
 * The following values are available for @mode:
 *
 * #CAMEL_STREAM_BUFFER_BUFFER, Buffer the input/output in blocks.
 * #CAMEL_STREAM_BUFFER_NEWLINE, Buffer on newlines (for output).
 * #CAMEL_STREAM_BUFFER_NONE, Perform no buffering.
 *
 * Note that currently this is ignored and #CAMEL_STREAM_BUFFER_BUFFER
 * is always used.
 *
 * In addition, one of the following mode options should be or'd
 * together with the buffering mode:
 *
 * #CAMEL_STREAM_BUFFER_WRITE, Buffer in write mode.
 * #CAMEL_STREAM_BUFFER_READ, Buffer in read mode.
 *
 * Buffering can only be done in one direction for any
 * buffer instance.
 *
 * Returns: a newly created buffered stream.
 **/
CamelStream *
camel_stream_buffer_new (CamelStream *stream,
                         CamelStreamBufferMode mode)
{
	CamelStreamBuffer *sbf;
	CamelStreamBufferClass *class;

	g_return_val_if_fail (CAMEL_IS_STREAM (stream), NULL);

	sbf = g_object_new (CAMEL_TYPE_STREAM_BUFFER, NULL);

	class = CAMEL_STREAM_BUFFER_GET_CLASS (sbf);
	g_return_val_if_fail (class->init != NULL, NULL);

	class->init (sbf, stream, mode);

	return CAMEL_STREAM (sbf);
}

/**
 * camel_stream_buffer_gets:
 * @sbf: a #CamelStreamBuffer object
 * @buf: (array length=max) (type gchar): Memory to write the string to.
 * @max: Maxmimum number of characters to store.
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Read a line of characters up to the next newline character or
 * @max-1 characters.
 *
 * If the newline character is encountered, then it will be
 * included in the buffer @buf.  The buffer will be %NULL terminated.
 *
 * Returns: the number of characters read, or 0 for end of file,
 * and -1 on error.
 **/
gint
camel_stream_buffer_gets (CamelStreamBuffer *sbf,
                          gchar *buf,
                          guint max,
                          GCancellable *cancellable,
                          GError **error)
{
	register gchar *outptr, *inptr, *inend, c, *outend;
	gint bytes_read;
	GError *local_error = NULL;

	outptr = buf;
	inptr = (gchar *) sbf->priv->ptr;
	inend = (gchar *) sbf->priv->end;
	outend = buf + max-1;	/* room for NUL */

	do {
		while (inptr < inend && outptr < outend) {
			c = *inptr++;
			*outptr++ = c;
			if (c == '\n') {
				*outptr = 0;
				sbf->priv->ptr = (guchar *) inptr;
				return outptr - buf;
			}
		}
		if (outptr == outend)
			break;

		bytes_read = camel_stream_read (
			sbf->priv->stream, (gchar *) sbf->priv->buf,
			sbf->priv->size, cancellable, &local_error);
		if (bytes_read == -1) {
			if (buf == outptr) {
				if (local_error)
					g_propagate_error (error, local_error);
				return -1;
			} else
				bytes_read = 0;
		}
		sbf->priv->ptr = sbf->priv->buf;
		sbf->priv->end = sbf->priv->buf + bytes_read;
		inptr = (gchar *) sbf->priv->ptr;
		inend = (gchar *) sbf->priv->end;
	} while (bytes_read > 0);

	sbf->priv->ptr = (guchar *) inptr;
	*outptr = 0;

	g_clear_error (&local_error);

	return (gint)(outptr - buf);
}

/**
 * camel_stream_buffer_read_line:
 * @sbf: a #CamelStreamBuffer object
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a @GError, or %NULL
 *
 * This function reads a complete newline-terminated line from the stream
 * and returns it in allocated memory. The trailing newline (and carriage
 * return if any) are not included in the returned string.
 *
 * Returns: (nullable): the line read, which the caller must free when done with,
 * or %NULL on eof. If an error occurs, @error will be set.
 **/
gchar *
camel_stream_buffer_read_line (CamelStreamBuffer *sbf,
                               GCancellable *cancellable,
                               GError **error)
{
	guchar *p;
	gint nread;
	GError *local_error = NULL;

	p = sbf->priv->linebuf;

	while (1) {
		nread = camel_stream_buffer_gets (
			sbf, (gchar *) p, sbf->priv->linesize -
			(p - sbf->priv->linebuf), cancellable, &local_error);
		if (nread <= 0) {
			if (p > sbf->priv->linebuf)
				break;
			if (local_error)
				g_propagate_error (error, local_error);
			return NULL;
		}

		p += nread;
		if (p[-1] == '\n')
			break;

		nread = p - sbf->priv->linebuf;
		sbf->priv->linesize *= 2;
		sbf->priv->linebuf = g_realloc (
			sbf->priv->linebuf, sbf->priv->linesize);
		p = sbf->priv->linebuf + nread;
	}

	p--;
	if (p > sbf->priv->linebuf && p[-1] == '\r')
		p--;
	p[0] = 0;

	g_clear_error (&local_error);

	return g_strdup ((gchar *) sbf->priv->linebuf);
}
