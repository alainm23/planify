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
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_MIME_FILTER_BESTENC_H
#define CAMEL_MIME_FILTER_BESTENC_H

#include <camel/camel-mime-filter.h>
#include <camel/camel-mime-part.h>
#include <camel/camel-charset-map.h>

/* Standard GObject macros */
#define CAMEL_TYPE_MIME_FILTER_BESTENC \
	(camel_mime_filter_bestenc_get_type ())
#define CAMEL_MIME_FILTER_BESTENC(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MIME_FILTER_BESTENC, CamelMimeFilterBestenc))
#define CAMEL_MIME_FILTER_BESTENC_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MIME_FILTER_BESTENC, CamelMimeFilterBestencClass))
#define CAMEL_IS_MIME_FILTER_BESTENC(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MIME_FILTER_BESTENC))
#define CAMEL_IS_MIME_FILTER_BESTENC_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MIME_FILTER_BESTENC))
#define CAMEL_MIME_FILTER_BESTENC_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MIME_FILTER_BESTENC, CamelMimeFilterBestencClass))

G_BEGIN_DECLS

typedef struct _CamelMimeFilterBestenc CamelMimeFilterBestenc;
typedef struct _CamelMimeFilterBestencClass CamelMimeFilterBestencClass;
typedef struct _CamelMimeFilterBestencPrivate CamelMimeFilterBestencPrivate;

typedef enum _CamelBestencRequired {
	CAMEL_BESTENC_GET_ENCODING = 1 << 0,
	CAMEL_BESTENC_GET_CHARSET = 1 << 1,

	/* do we treat 'lf' as if it were crlf? */
	CAMEL_BESTENC_LF_IS_CRLF = 1 << 8,
	/* do we not allow "From " to appear at the start of a line in any part? */
	CAMEL_BESTENC_NO_FROM = 1 << 9
} CamelBestencRequired;

typedef enum _CamelBestencEncoding {
	CAMEL_BESTENC_7BIT,
	CAMEL_BESTENC_8BIT,
	CAMEL_BESTENC_BINARY,

	/* is the content stream to be treated as text? */
	CAMEL_BESTENC_TEXT = 1 << 8
} CamelBestencEncoding;

struct _CamelMimeFilterBestenc {
	CamelMimeFilter parent;
	CamelMimeFilterBestencPrivate *priv;
};

struct _CamelMimeFilterBestencClass {
	CamelMimeFilterClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_mime_filter_bestenc_get_type (void);
CamelMimeFilter *
		camel_mime_filter_bestenc_new	(guint flags);
CamelTransferEncoding
		camel_mime_filter_bestenc_get_best_encoding
						(CamelMimeFilterBestenc *filter,
						 CamelBestencEncoding required);
const gchar *	camel_mime_filter_bestenc_get_best_charset
						(CamelMimeFilterBestenc *filter);
void		camel_mime_filter_bestenc_set_flags
						(CamelMimeFilterBestenc *filter,
						 guint flags);

G_END_DECLS

#endif /* CAMEL_MIME_FILTER_BESTENC_H */
