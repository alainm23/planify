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
 * Authors: Michael Zucchi <notzed@ximian.com>
 *          Jeffrey Stedfast <fejj@ximian.com>
 *          Dan Winship <danw@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <glib/gi18n-lib.h>

#include "camel-file-utils.h"
#include "camel-object.h"
#include "camel-operation.h"
#include "camel-url.h"

#ifdef G_OS_WIN32
#include <winsock2.h>
#ifndef EWOULDBLOCK
#define EWOULDBLOCK EAGAIN
#endif
#endif

#define IO_TIMEOUT (60*4)

#define CHECK_CALL(x) G_STMT_START { \
	if ((x) == -1) { \
		g_debug ("%s: Call of '" #x "' failed: %s", G_STRFUNC, g_strerror (errno)); \
	} \
	} G_STMT_END

/**
 * camel_file_util_encode_uint32:
 * @out: file to output to
 * @value: value to output
 *
 * Utility function to save an uint32 to a file.
 *
 * Returns: 0 on success, -1 on error.
 **/
gint
camel_file_util_encode_uint32 (FILE *out,
                               guint32 value)
{
	gint i;

	for (i = 28; i > 0; i -= 7) {
		if (value >= (1 << i)) {
			guint c = (value >> i) & 0x7f;
			if (fputc (c, out) == -1)
				return -1;
		}
	}
	return fputc (value | 0x80, out);
}

/**
 * camel_file_util_decode_uint32:
 * @in: file to read from
 * @dest: pointer to a variable to store the value in
 *
 * Retrieve an encoded uint32 from a file.
 *
 * Returns: 0 on success, -1 on error.  @*dest will contain the
 * decoded value.
 **/
gint
camel_file_util_decode_uint32 (FILE *in,
                               guint32 *dest)
{
	guint32 value = 0;
	gint v;

        /* until we get the last byte, keep decoding 7 bits at a time */
	while ( ((v = fgetc (in)) & 0x80) == 0 && v != EOF) {
		value |= v;
		value <<= 7;
	}
	if (v == EOF) {
		*dest = value >> 7;
		return -1;
	}
	*dest = value | (v & 0x7f);

	return 0;
}

/**
 * camel_file_util_encode_fixed_int32:
 * @out: file to output to
 * @value: value to output
 *
 * Encode a gint32, performing no compression, but converting
 * to network order.
 *
 * Returns: 0 on success, -1 on error.
 **/
gint
camel_file_util_encode_fixed_int32 (FILE *out,
                                    gint32 value)
{
	guint32 save;

	save = g_htonl (value);
	if (fwrite (&save, sizeof (save), 1, out) != 1)
		return -1;
	return 0;
}

/**
 * camel_file_util_decode_fixed_int32:
 * @in: file to read from
 * @dest: pointer to a variable to store the value in
 *
 * Retrieve a gint32.
 *
 * Returns: 0 on success, -1 on error.
 **/
gint
camel_file_util_decode_fixed_int32 (FILE *in,
                                    gint32 *dest)
{
	guint32 save;

	if (fread (&save, sizeof (save), 1, in) == 1) {
		*dest = g_ntohl (save);
		return 0;
	} else {
		return -1;
	}
}

#define CFU_ENCODE_T(type) \
gint \
camel_file_util_encode_##type (FILE *out, type value) \
{ \
	gint i; \
 \
	for (i = sizeof (type) - 1; i >= 0; i--) { \
		if (fputc ((value >> (i * 8)) & 0xff, out) == -1) \
			return -1; \
	} \
	return 0; \
}

#define CFU_DECODE_T(type) \
gint \
camel_file_util_decode_##type (FILE *in, type *dest) \
{ \
	type save = 0; \
	gint i = sizeof (type) - 1; \
	gint v = EOF; \
 \
	while (i >= 0 && (v = fgetc (in)) != EOF) { \
		save |= ((type) v) << (i * 8); \
		i--; \
	} \
	*dest = save; \
	if (v == EOF) \
		return -1; \
	return 0; \
}

/**
 * camel_file_util_encode_time_t:
 * @out: file to output to
 * @value: value to output
 *
 * Encode a time_t value to the file.
 *
 * Returns: 0 on success, -1 on error.
 **/
CFU_ENCODE_T (time_t)

/**
 * camel_file_util_decode_time_t:
 * @in: file to read from
 * @dest: pointer to a variable to store the value in
 *
 * Decode a time_t value.
 *
 * Returns: 0 on success, -1 on error.
 **/
CFU_DECODE_T (time_t)

/**
 * camel_file_util_encode_off_t:
 * @out: file to output to
 * @value: value to output
 *
 * Encode an off_t type.
 *
 * Returns: 0 on success, -1 on error.
 **/
CFU_ENCODE_T (off_t)

/**
 * camel_file_util_decode_off_t:
 * @in: file to read from
 * @dest: pointer to a variable to put the value in
 *
 * Decode an off_t type.
 *
 * Returns: 0 on success, -1 on failure.
 **/
CFU_DECODE_T (off_t)

/**
 * camel_file_util_encode_gsize:
 * @out: file to output to
 * @value: value to output
 *
 * Encode an gsize type.
 *
 * Returns: 0 on success, -1 on error.
 **/
CFU_ENCODE_T (gsize)

/**
 * camel_file_util_decode_gsize:
 * @in: file to read from
 * @dest: pointer to a variable to put the value in
 *
 * Decode an gsize type.
 *
 * Returns: 0 on success, -1 on failure.
 **/
CFU_DECODE_T (gsize)

/**
 * camel_file_util_encode_string:
 * @out: file to output to
 * @str: value to output
 *
 * Encode a normal string and save it in the output file.
 *
 * Returns: 0 on success, -1 on error.
 **/
gint
camel_file_util_encode_string (FILE *out,
                               const gchar *str)
{
	register gint len;

	if (str == NULL)
		return camel_file_util_encode_uint32 (out, 1);

	if ((len = strlen (str)) > 65536)
		len = 65536;

	if (camel_file_util_encode_uint32 (out, len + 1) == -1)
		return -1;
	if (len == 0 || fwrite (str, sizeof (gchar), len, out) == len)
		return 0;
	return -1;
}

/**
 * camel_file_util_decode_string:
 * @in: file to read from
 * @str: pointer to a variable to store the value in
 *
 * Decode a normal string from the input file.
 *
 * Returns: 0 on success, -1 on error.
 **/
gint
camel_file_util_decode_string (FILE *in,
                               gchar **str)
{
	guint32 len;
	register gchar *ret;

	if (camel_file_util_decode_uint32 (in, &len) == -1) {
		*str = NULL;
		return -1;
	}

	len--;
	if (len > 65536) {
		*str = NULL;
		return -1;
	}

	ret = g_malloc (len + 1);
	if (len > 0 && fread (ret, sizeof (gchar), len, in) != len) {
		g_free (ret);
		*str = NULL;
		return -1;
	}

	ret[len] = 0;
	*str = ret;
	return 0;
}

/**
 * camel_file_util_encode_fixed_string:
 * @out: file to output to
 * @str: value to output
 * @len: total-len of str to store
 *
 * Encode a normal string and save it in the output file.
 * Unlike @camel_file_util_encode_string, it pads the
 * @str with "NULL" bytes, if @len is > strlen(str)
 *
 * Returns: 0 on success, -1 on error.
 **/
gint
camel_file_util_encode_fixed_string (FILE *out,
                                     const gchar *str,
                                     gsize len)
{
	gint retval = -1;

	/* Max size is 64K */
	if (len > 65536)
		len = 65536;

	/* Don't allow empty strings to be written. */
	if (len > 0) {
		gchar *buf;

		buf = g_malloc0 (len);
		g_strlcpy (buf, str, len);

		if (fwrite (buf, sizeof (gchar), len, out) == len)
			retval = 0;

		g_free (buf);
	}

	return retval;
}

/**
 * camel_file_util_decode_fixed_string:
 * @in: file to read from
 * @str: pointer to a variable to store the value in
 * @len: total-len to decode.
 *
 * Decode a normal string from the input file.
 *
 * Returns: 0 on success, -1 on error.
 **/
gint
camel_file_util_decode_fixed_string (FILE *in,
                                     gchar **str,
                                     gsize len)
{
	register gchar *ret;

	if (len > 65536) {
		*str = NULL;
		return -1;
	}

	ret = g_malloc (len + 1);
	if (len > 0 && fread (ret, sizeof (gchar), len, in) != len) {
		g_free (ret);
		*str = NULL;
		return -1;
	}

	ret[len] = 0;
	*str = ret;
	return 0;
}

/**
 * camel_file_util_safe_filename:
 * @name: string to 'flattened' into a safe filename
 *
 * 'Flattens' @name into a safe filename string by hex encoding any
 * chars that may cause problems on the filesystem.
 *
 * Returns: a safe filename string.
 **/
gchar *
camel_file_util_safe_filename (const gchar *name)
{
#ifdef G_OS_WIN32
	const gchar *unsafe_chars = "/?()'*<>:\"\\|";
#else
	const gchar *unsafe_chars = "/?()'*";
#endif

	if (name == NULL)
		return NULL;

	return camel_url_encode (name, unsafe_chars);
}

/* FIXME: poll() might be more efficient and more portable? */

/**
 * camel_read:
 * @fd: file descriptor
 * @buf: buffer to fill
 * @n: number of bytes to read into @buf
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Cancellable libc read() replacement.
 *
 * Code that intends to be portable to Win32 should call this function
 * only on file descriptors returned from open(), not on sockets.
 *
 * Returns: number of bytes read or -1 on fail. On failure, errno will
 * be set appropriately.
 **/
gssize
camel_read (gint fd,
            gchar *buf,
            gsize n,
            GCancellable *cancellable,
            GError **error)
{
	gssize nread;
	gint cancel_fd;

	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		errno = EINTR;
		return -1;
	}

	cancel_fd = g_cancellable_get_fd (cancellable);

	if (cancel_fd == -1) {
		do {
			nread = read (fd, buf, n);
		} while (nread == -1 && (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK));
	} else {
#ifndef G_OS_WIN32
		gint errnosav, flags, fdmax;
		fd_set rdset;

		flags = fcntl (fd, F_GETFL);
		CHECK_CALL (fcntl (fd, F_SETFL, flags | O_NONBLOCK));

		do {
			struct timeval tv;
			gint res;

			FD_ZERO (&rdset);
			FD_SET (fd, &rdset);
			FD_SET (cancel_fd, &rdset);
			fdmax = MAX (fd, cancel_fd) + 1;
			tv.tv_sec = IO_TIMEOUT;
			tv.tv_usec = 0;
			nread = -1;

			res = select (fdmax, &rdset, 0, 0, &tv);
			if (res == -1)
				;
			else if (res == 0)
				errno = ETIMEDOUT;
			else if (FD_ISSET (cancel_fd, &rdset)) {
				errno = EINTR;
				goto failed;
			} else {
				do {
					nread = read (fd, buf, n);
				} while (nread == -1 && errno == EINTR);
			}
		} while (nread == -1 && (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK));
	failed:
		errnosav = errno;
		CHECK_CALL (fcntl (fd, F_SETFL, flags));
		errno = errnosav;
#endif
	}

	g_cancellable_release_fd (cancellable);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return -1;

	if (nread == -1)
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			"%s", g_strerror (errno));

	return nread;
}

/**
 * camel_write:
 * @fd: file descriptor
 * @buf: buffer to write
 * @n: number of bytes of @buf to write
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Cancellable libc write() replacement.
 *
 * Code that intends to be portable to Win32 should call this function
 * only on file descriptors returned from open(), not on sockets.
 *
 * Returns: number of bytes written or -1 on fail. On failure, errno will
 * be set appropriately.
 **/
gssize
camel_write (gint fd,
             const gchar *buf,
             gsize n,
             GCancellable *cancellable,
             GError **error)
{
	gssize w, written = 0;
	gint cancel_fd;

	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		errno = EINTR;
		return -1;
	}

	cancel_fd = g_cancellable_get_fd (cancellable);

	if (cancel_fd == -1) {
		do {
			do {
				w = write (fd, buf + written, n - written);
			} while (w == -1 && (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK));
			if (w > 0)
				written += w;
		} while (w != -1 && written < n);
	} else {
#ifndef G_OS_WIN32
		gint errnosav, flags, fdmax;
		fd_set rdset, wrset;

		flags = fcntl (fd, F_GETFL);
		CHECK_CALL (fcntl (fd, F_SETFL, flags | O_NONBLOCK));

		fdmax = MAX (fd, cancel_fd) + 1;
		do {
			struct timeval tv;
			gint res;

			FD_ZERO (&rdset);
			FD_ZERO (&wrset);
			FD_SET (fd, &wrset);
			FD_SET (cancel_fd, &rdset);
			tv.tv_sec = IO_TIMEOUT;
			tv.tv_usec = 0;
			w = -1;

			res = select (fdmax, &rdset, &wrset, 0, &tv);
			if (res == -1) {
				if (errno == EINTR)
					w = 0;
			} else if (res == 0)
				errno = ETIMEDOUT;
			else if (FD_ISSET (cancel_fd, &rdset))
				errno = EINTR;
			else {
				do {
					w = write (fd, buf + written, n - written);
				} while (w == -1 && errno == EINTR);

				if (w == -1) {
					if (errno == EAGAIN || errno == EWOULDBLOCK)
						w = 0;
				} else
					written += w;
			}
		} while (w != -1 && written < n);

		errnosav = errno;
		CHECK_CALL (fcntl (fd, F_SETFL, flags));
		errno = errnosav;
#endif
	}

	g_cancellable_release_fd (cancellable);

	if (g_cancellable_set_error_if_cancelled (cancellable, error))
		return -1;

	if (w == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			"%s", g_strerror (errno));
		return -1;
	}

	return written;
}

/**
 * camel_file_util_savename:
 * @filename: a pathname
 *
 * Builds a pathname where the basename is of the form ".#" + the
 * basename of @filename, for instance used in a two-stage commit file
 * write.
 *
 * Returns: The new pathname.  It must be free'd with g_free().
 **/
gchar *
camel_file_util_savename (const gchar *filename)
{
	gchar *dirname, *retval;

	dirname = g_path_get_dirname (filename);

	if (strcmp (dirname, ".") == 0) {
		retval = g_strconcat (".#", filename, NULL);
	} else {
		gchar *basename = g_path_get_basename (filename);
		gchar *newbasename = g_strconcat (".#", basename, NULL);

		retval = g_build_filename (dirname, newbasename, NULL);

		g_free (newbasename);
		g_free (basename);
	}
	g_free (dirname);

	return retval;
}
