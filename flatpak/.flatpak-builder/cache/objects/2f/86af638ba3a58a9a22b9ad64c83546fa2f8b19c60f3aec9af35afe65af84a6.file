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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_MIME_FILTER_YENC_H
#define CAMEL_MIME_FILTER_YENC_H

#include <camel/camel-enums.h>
#include <camel/camel-mime-filter.h>

/* Standard GObject macros */
#define CAMEL_TYPE_MIME_FILTER_YENC \
	(camel_mime_filter_yenc_get_type ())
#define CAMEL_MIME_FILTER_YENC(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MIME_FILTER_YENC, CamelMimeFilterYenc))
#define CAMEL_MIME_FILTER_YENC_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MIME_FILTER_YENC, CamelMimeFilterYencClass))
#define CAMEL_IS_MIME_FILTER_YENC(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MIME_FILTER_YENC))
#define CAMEL_IS_MIME_FILTER_YENC_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MIME_FILTER_YENC))
#define CAMEL_MIME_FILTER_YENC_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MIME_FILTER_YENC, CamelMimeFilterYencClass))

G_BEGIN_DECLS

typedef struct _CamelMimeFilterYenc CamelMimeFilterYenc;
typedef struct _CamelMimeFilterYencClass CamelMimeFilterYencClass;
typedef struct _CamelMimeFilterYencPrivate CamelMimeFilterYencPrivate;

#define CAMEL_MIME_YDECODE_STATE_INIT     (0)
#define CAMEL_MIME_YENCODE_STATE_INIT     (0)

/* first 8 bits are reserved for saving a byte */

/* reserved for use only within camel_mime_ydecode_step */
#define CAMEL_MIME_YDECODE_STATE_EOLN     (1 << 8)
#define CAMEL_MIME_YDECODE_STATE_ESCAPE   (1 << 9)

/* bits 10 and 11 reserved for later uses? */

#define CAMEL_MIME_YDECODE_STATE_BEGIN    (1 << 12)
#define CAMEL_MIME_YDECODE_STATE_PART     (1 << 13)
#define CAMEL_MIME_YDECODE_STATE_DECODE   (1 << 14)
#define CAMEL_MIME_YDECODE_STATE_END      (1 << 15)

#define CAMEL_MIME_YENCODE_CRC_INIT       (~0)
#define CAMEL_MIME_YENCODE_CRC_FINAL(crc) (~crc)

struct _CamelMimeFilterYenc {
	CamelMimeFilter parent;
	CamelMimeFilterYencPrivate *priv;
};

struct _CamelMimeFilterYencClass {
	CamelMimeFilterClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_mime_filter_yenc_get_type	(void);
CamelMimeFilter *
		camel_mime_filter_yenc_new	(CamelMimeFilterYencDirection direction);
void		camel_mime_filter_yenc_set_state (CamelMimeFilterYenc *yenc,
						 gint state);
void		camel_mime_filter_yenc_set_crc	(CamelMimeFilterYenc *yenc,
						 guint32 crc);
guint32		camel_mime_filter_yenc_get_pcrc	(CamelMimeFilterYenc *yenc);
guint32		camel_mime_filter_yenc_get_crc	(CamelMimeFilterYenc *yenc);

gsize		camel_ydecode_step		(const guchar *in,
						 gsize inlen,
						 guchar *out,
						 gint *state,
						 guint32 *pcrc,
						 guint32 *crc);
gsize		camel_yencode_step		(const guchar *in,
						 gsize inlen,
						 guchar *out,
						 gint *state,
						 guint32 *pcrc,
						 guint32 *crc);
gsize		camel_yencode_close		(const guchar *in,
						 gsize inlen,
						 guchar *out,
						 gint *state,
						 guint32 *pcrc,
						 guint32 *crc);

G_END_DECLS

#endif /* CAMEL_MIME_FILTER_YENC_H */
