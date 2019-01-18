/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-stream-fs.c : file system based stream
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
 *	    Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <glib/gstdio.h>

#include "camel-file-utils.h"
#include "camel-operation.h"
#include "camel-stream-fs.h"
#include "camel-win32.h"

#define CAMEL_STREAM_FS_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_STREAM_FS, CamelStreamFsPrivate))

struct _CamelStreamFsPrivate {
	gboolean eos;
	gint fd;	/* file descriptor on the underlying file */
};

/* Forward Declarations */
static void camel_stream_fs_seekable_init (GSeekableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	CamelStreamFs, camel_stream_fs, CAMEL_TYPE_STREAM,
	G_IMPLEMENT_INTERFACE (G_TYPE_SEEKABLE, camel_stream_fs_seekable_init))

static void
stream_fs_finalize (GObject *object)
{
	CamelStreamFsPrivate *priv;

	priv = CAMEL_STREAM_FS_GET_PRIVATE (object);

	if (priv->fd != -1)
		close (priv->fd);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_stream_fs_parent_class)->finalize (object);
}

static gssize
stream_fs_read (CamelStream *stream,
                gchar *buffer,
                gsize n,
                GCancellable *cancellable,
                GError **error)
{
	CamelStreamFsPrivate *priv;
	gssize nread;

	priv = CAMEL_STREAM_FS_GET_PRIVATE (stream);

	nread = camel_read (priv->fd, buffer, n, cancellable, error);

	if (nread == 0)
		priv->eos = TRUE;

	return nread;
}

static gssize
stream_fs_write (CamelStream *stream,
                 const gchar *buffer,
                 gsize n,
                 GCancellable *cancellable,
                 GError **error)
{
	CamelStreamFsPrivate *priv;

	priv = CAMEL_STREAM_FS_GET_PRIVATE (stream);

	return camel_write (priv->fd, buffer, n, cancellable, error);
}

static gint
stream_fs_flush (CamelStream *stream,
                 GCancellable *cancellable,
                 GError **error)
{
	CamelStreamFsPrivate *priv;

	priv = CAMEL_STREAM_FS_GET_PRIVATE (stream);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return -1;

	if (fsync (priv->fd) == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			"%s", g_strerror (errno));
		return -1;
	}

	return 0;
}

static gint
stream_fs_close (CamelStream *stream,
                 GCancellable *cancellable,
                 GError **error)
{
	CamelStreamFsPrivate *priv;

	priv = CAMEL_STREAM_FS_GET_PRIVATE (stream);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return -1;

	if (close (priv->fd) == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			"%s", g_strerror (errno));
		return -1;
	}

	priv->fd = -1;

	return 0;
}

static gboolean
stream_fs_eos (CamelStream *stream)
{
	CamelStreamFs *fs = CAMEL_STREAM_FS (stream);

	return fs->priv->eos;
}

static goffset
stream_fs_tell (GSeekable *seekable)
{
	CamelStreamFsPrivate *priv;

	priv = CAMEL_STREAM_FS_GET_PRIVATE (seekable);

	return (goffset) lseek (priv->fd, 0, SEEK_CUR);
}

static gboolean
stream_fs_can_seek (GSeekable *seekable)
{
	return TRUE;
}

static gboolean
stream_fs_seek (GSeekable *seekable,
                goffset offset,
                GSeekType type,
                GCancellable *cancellable,
                GError **error)
{
	CamelStreamFsPrivate *priv;
	goffset real = 0;

	priv = CAMEL_STREAM_FS_GET_PRIVATE (seekable);

	switch (type) {
	case G_SEEK_SET:
		real = offset;
		break;
	case G_SEEK_CUR:
		real = g_seekable_tell (seekable) + offset;
		break;
	case G_SEEK_END:
		real = lseek (priv->fd, offset, SEEK_END);
		if (real == -1) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				"%s", g_strerror (errno));
			return FALSE;
		}
		return TRUE;
	}

	real = lseek (priv->fd, real, SEEK_SET);
	if (real == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			"%s", g_strerror (errno));
		return FALSE;
	}

	priv->eos = FALSE;

	return TRUE;
}

static gboolean
stream_fs_can_truncate (GSeekable *seekable)
{
	return FALSE;
}

static gboolean
stream_fs_truncate_fn (GSeekable *seekable,
                       goffset offset,
                       GCancellable *cancellable,
                       GError **error)
{
	/* XXX Don't bother translating this.  Camel never calls it. */
	g_set_error (
		error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
		"Truncation is not supported");

	return FALSE;
}

static void
camel_stream_fs_class_init (CamelStreamFsClass *class)
{
	GObjectClass *object_class;
	CamelStreamClass *stream_class;

	g_type_class_add_private (class, sizeof (CamelStreamFsPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = stream_fs_finalize;

	stream_class = CAMEL_STREAM_CLASS (class);
	stream_class->read = stream_fs_read;
	stream_class->write = stream_fs_write;
	stream_class->flush = stream_fs_flush;
	stream_class->close = stream_fs_close;
	stream_class->eos = stream_fs_eos;
}

static void
camel_stream_fs_seekable_init (GSeekableIface *iface)
{
	iface->tell = stream_fs_tell;
	iface->can_seek = stream_fs_can_seek;
	iface->seek = stream_fs_seek;
	iface->can_truncate = stream_fs_can_truncate;
	iface->truncate_fn = stream_fs_truncate_fn;
}

static void
camel_stream_fs_init (CamelStreamFs *stream)
{
	stream->priv = CAMEL_STREAM_FS_GET_PRIVATE (stream);
	stream->priv->fd = -1;
	stream->priv->eos = FALSE;
}

/**
 * camel_stream_fs_new_with_fd:
 * @fd: a file descriptor
 *
 * Creates a new fs stream using the given file descriptor @fd as the
 * backing store. When the stream is destroyed, the file descriptor
 * will be closed.
 *
 * Returns: a new #CamelStreamFs
 **/
CamelStream *
camel_stream_fs_new_with_fd (gint fd)
{
	CamelStreamFsPrivate *priv;
	CamelStream *stream;

	if (fd == -1)
		return NULL;

	stream = g_object_new (CAMEL_TYPE_STREAM_FS, NULL);
	priv = CAMEL_STREAM_FS_GET_PRIVATE (stream);

	priv->fd = fd;

	return stream;
}

/**
 * camel_stream_fs_new_with_name:
 * @name: a local filename
 * @flags: flags as in open(2)
 * @mode: (type guint32): a file mode
 * @error: return location for a #GError, or %NULL
 *
 * Creates a new #CamelStreamFs corresponding to the named file, flags,
 * and mode.
 *
 * Returns: the new stream, or %NULL on error.
 **/
CamelStream *
camel_stream_fs_new_with_name (const gchar *name,
                               gint flags,
                               mode_t mode,
                               GError **error)
{
	gint fd;

	fd = g_open (name, flags | O_BINARY, mode);
	if (fd == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			"%s", g_strerror (errno));
		return NULL;
	}

	return camel_stream_fs_new_with_fd (fd);
}

/**
 * camel_stream_fs_get_fd:
 * @stream: a #CamelStream
 *
 * Since: 2.32
 **/
gint
camel_stream_fs_get_fd (CamelStreamFs *stream)
{
	g_return_val_if_fail (CAMEL_IS_STREAM_FS (stream), -1);

	return stream->priv->fd;
}
