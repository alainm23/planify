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

/* Abstract class for non-copying filters */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_MIME_FILTER_H
#define CAMEL_MIME_FILTER_H

#include <sys/types.h>

#include <glib-object.h>

/* Standard GObject macros */
#define CAMEL_TYPE_MIME_FILTER \
	(camel_mime_filter_get_type ())
#define CAMEL_MIME_FILTER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj),  CAMEL_TYPE_MIME_FILTER, CamelMimeFilter))
#define CAMEL_MIME_FILTER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MIME_FILTER, CamelMimeFilterClass))
#define CAMEL_IS_MIME_FILTER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MIME_FILTER))
#define CAMEL_IS_MIME_FILTER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MIME_FILTER))
#define CAMEL_MIME_FILTER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MIME_FILTER, CamelMimeFilterClass))

G_BEGIN_DECLS

typedef struct _CamelMimeFilter CamelMimeFilter;
typedef struct _CamelMimeFilterClass CamelMimeFilterClass;
typedef struct _CamelMimeFilterPrivate CamelMimeFilterPrivate;

struct _CamelMimeFilter {
	GObject parent;
	CamelMimeFilterPrivate *priv;

	gchar *outreal;		/* real malloc'd buffer */
	gchar *outbuf;		/* first 'writable' position allowed (outreal + outpre) */
	gchar *outptr;
	gsize outsize;
	gsize outpre;		/* prespace of this buffer */

	gchar *backbuf;
	gsize backsize;
	gsize backlen;		/* significant data there */
};

struct _CamelMimeFilterClass {
	GObjectClass parent_class;

	void		(*filter)		(CamelMimeFilter *filter,
						 const gchar *in,
						 gsize len,
						 gsize prespace,
						 gchar **out,
						 gsize *outlen,
						 gsize *outprespace);
	void		(*complete)		(CamelMimeFilter *filter,
						 const gchar *in,
						 gsize len,
						 gsize prespace,
						 gchar **out,
						 gsize *outlen,
						 gsize *outprespace);
	void		(*reset)		(CamelMimeFilter *filter);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_mime_filter_get_type	(void);
CamelMimeFilter *
		camel_mime_filter_new		(void);
void		camel_mime_filter_filter	(CamelMimeFilter *filter,
						 const gchar *in,
						 gsize len,
						 gsize prespace,
						 gchar **out,
						 gsize *outlen,
						 gsize *outprespace);
void		camel_mime_filter_complete	(CamelMimeFilter *filter,
						 const gchar *in,
						 gsize len,
						 gsize prespace,
						 gchar **out,
						 gsize *outlen,
						 gsize *outprespace);
void		camel_mime_filter_reset		(CamelMimeFilter *filter);

/* sets/returns number of bytes backed up on the input */
void		camel_mime_filter_backup	(CamelMimeFilter *filter,
						 const gchar *data,
						 gsize length);

/* ensure this much size available for filter output */
void		camel_mime_filter_set_size	(CamelMimeFilter *filter,
						 gsize size,
						 gint keep);

G_END_DECLS

#endif /* CAMEL_MIME_FILTER_H */
