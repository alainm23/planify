/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; fill-column: 160 -*- */
/* camel-stream.h : class for an abstract stream
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

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_STREAM_H
#define CAMEL_STREAM_H

#include <stdarg.h>
#include <unistd.h>

#include <gio/gio.h>

/* Standard GObject macros */
#define CAMEL_TYPE_STREAM \
	(camel_stream_get_type ())
#define CAMEL_STREAM(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_STREAM, CamelStream))
#define CAMEL_STREAM_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_STREAM, CamelStreamClass))
#define CAMEL_IS_STREAM(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_STREAM))
#define CAMEL_IS_STREAM_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_STREAM))
#define CAMEL_STREAM_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_STREAM, CamelStreamClass))

G_BEGIN_DECLS

typedef struct _CamelStream CamelStream;
typedef struct _CamelStreamClass CamelStreamClass;
typedef struct _CamelStreamPrivate CamelStreamPrivate;

struct _CamelStream {
	GObject parent;
	CamelStreamPrivate *priv;
};

struct _CamelStreamClass {
	GObjectClass parent_class;

	gssize		(*read)			(CamelStream *stream,
						 gchar *buffer,
						 gsize n,
						 GCancellable *cancellable,
						 GError **error);
	gssize		(*write)		(CamelStream *stream,
						 const gchar *buffer,
						 gsize n,
						 GCancellable *cancellable,
						 GError **error);
	gint		(*close)		(CamelStream *stream,
						 GCancellable *cancellable,
						 GError **error);
	gint		(*flush)		(CamelStream *stream,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*eos)			(CamelStream *stream);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_stream_get_type		(void);
CamelStream *	camel_stream_new		(GIOStream *base_stream);
GIOStream *	camel_stream_ref_base_stream	(CamelStream *stream);
void		camel_stream_set_base_stream	(CamelStream *stream,
						 GIOStream *base_stream);
gssize		camel_stream_read		(CamelStream *stream,
						 gchar *buffer,
						 gsize n,
						 GCancellable *cancellable,
						 GError **error);
gssize		camel_stream_write		(CamelStream *stream,
						 const gchar *buffer,
						 gsize n,
						 GCancellable *cancellable,
						 GError **error);
gint		camel_stream_flush		(CamelStream *stream,
						 GCancellable *cancellable,
						 GError **error);
gint		camel_stream_close		(CamelStream *stream,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_stream_eos		(CamelStream *stream);

/* utility macros and funcs */
gssize		camel_stream_write_string	(CamelStream *stream,
						 const gchar *string,
						 GCancellable *cancellable,
						 GError **error);

/* Write a whole stream to another stream, until eof or error on
 * either stream.  */
gssize		camel_stream_write_to_stream	(CamelStream *stream,
						 CamelStream *output_stream,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_STREAM_H */
