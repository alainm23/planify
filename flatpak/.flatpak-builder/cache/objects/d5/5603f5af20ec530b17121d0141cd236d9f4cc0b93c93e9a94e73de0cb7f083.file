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

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_FILE_UTILS_H
#define CAMEL_FILE_UTILS_H

#include <gio/gio.h>
#include <stdio.h>
#include <sys/types.h>
#include <time.h>
#include <fcntl.h>

#ifndef O_BINARY
#define O_BINARY 0
#endif

G_BEGIN_DECLS

gint camel_file_util_encode_fixed_int32 (FILE *out, gint32 value);
gint camel_file_util_decode_fixed_int32 (FILE *in, gint32 *dest);
gint camel_file_util_encode_uint32 (FILE *out, guint32 value);
gint camel_file_util_decode_uint32 (FILE *in, guint32 *dest);
gint camel_file_util_encode_time_t (FILE *out, time_t value);
gint camel_file_util_decode_time_t (FILE *in, time_t *dest);
gint camel_file_util_encode_off_t (FILE *out, off_t value);
gint camel_file_util_decode_off_t (FILE *in, off_t *dest);
gint camel_file_util_encode_gsize (FILE *out, gsize value);
gint camel_file_util_decode_gsize (FILE *in, gsize *dest);
gint camel_file_util_encode_string (FILE *out, const gchar *str);
gint camel_file_util_decode_string (FILE *in, gchar **str);
gint camel_file_util_encode_fixed_string (FILE *out, const gchar *str, gsize len);
gint camel_file_util_decode_fixed_string (FILE *in, gchar **str, gsize len);

gchar *camel_file_util_safe_filename (const gchar *name);

/* Code that intends to be portable to Win32 should use camel_read()
 * and camel_write() only on file descriptors returned from open(),
 * creat(), pipe() or fileno(). On Win32 camel_read() and
 * camel_write() calls will not be cancellable.
 */
gssize		camel_read			(gint fd,
						 gchar *buf,
						 gsize n,
						 GCancellable *cancellable,
						 GError **error);
gssize		camel_write			(gint fd,
						 const gchar *buf,
						 gsize n,
						 GCancellable *cancellable,
						 GError **error);

gchar *		camel_file_util_savename	(const gchar *filename);

G_END_DECLS

#endif /* CAMEL_FILE_UTILS_H */
