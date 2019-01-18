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

#include "evolution-data-server-config.h"

#include <ctype.h>

#include "camel-mime-filter-linewrap.h"

#define CAMEL_MIME_FILTER_LINEWRAP_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER_LINEWRAP, CamelMimeFilterLinewrapPrivate))

struct _CamelMimeFilterLinewrapPrivate {
	guint wrap_len;
	guint max_len;
	gchar indent;
	gint nchars;
	guint32 flags;
};

G_DEFINE_TYPE (CamelMimeFilterLinewrap, camel_mime_filter_linewrap, CAMEL_TYPE_MIME_FILTER)

static void
mime_filter_linewrap_filter (CamelMimeFilter *mime_filter,
                             const gchar *in,
                             gsize len,
                             gsize prespace,
                             gchar **out,
                             gsize *outlen,
                             gsize *outprespace)
{
	CamelMimeFilterLinewrapPrivate *priv;
	gchar *q;
	const gchar *inend, *p;
	gint nchars;

	priv = CAMEL_MIME_FILTER_LINEWRAP_GET_PRIVATE (mime_filter);

	nchars = priv->nchars;

	/* we'll be adding chars here so we need a bigger buffer */
	camel_mime_filter_set_size (mime_filter, 3 * len, FALSE);

	p = in;
	q = mime_filter->outbuf;
	inend = in + len;

	while (p < inend) {
		if (*p == '\n') {
			*q++ = *p++;
			nchars = 0;
		} else if (isspace (*p)) {
			if (nchars >= priv->wrap_len) {
				*q++ = '\n';
				while (p < inend && isspace (*p))
					p++;
				nchars = 0;
			} else {
				*q++ = *p++;
				nchars++;
			}
		} else {
			*q++ = *p++;
			nchars++;
		}

		/* line is getting way too long, we must force a wrap here */
		if (nchars >= priv->max_len && *p != '\n') {
			gboolean wrapped = FALSE;

			if (isspace (*p)) {
				while (p < inend && isspace (*p) && *p != '\n')
					p++;
			} else if ((priv->flags & CAMEL_MIME_FILTER_LINEWRAP_WORD) != 0) {
				gchar *r = q - 1;

				/* find the first space backward */
				while (r > mime_filter->outbuf && !isspace (*r))
					r--;

				if (r > mime_filter->outbuf && *r != '\n') {
					/* found some valid */
					*r = '\n';
					wrapped = TRUE;

					if ((priv->flags & CAMEL_MIME_FILTER_LINEWRAP_NOINDENT) == 0) {
						gchar *s = q + 1;

						while (s > r) {
							*s = *(s - 1);
							s--;
						}

						*r = priv->indent;
						q++;
					}

					nchars = q - r - 1;
				}
			}

			if (!wrapped) {
				*q++ = '\n';
				if ((priv->flags & CAMEL_MIME_FILTER_LINEWRAP_NOINDENT) == 0) {
					*q++ = priv->indent;
					nchars = 1;
				} else
					nchars = 0;
			}
		}
	}

	priv->nchars = nchars;

	*out = mime_filter->outbuf;
	*outlen = q - mime_filter->outbuf;
	*outprespace = mime_filter->outpre;
}

static void
mime_filter_linewrap_complete (CamelMimeFilter *mime_filter,
                               const gchar *in,
                               gsize len,
                               gsize prespace,
                               gchar **out,
                               gsize *outlen,
                               gsize *outprespace)
{
	if (len)
		mime_filter_linewrap_filter (
			mime_filter, in, len, prespace,
			out, outlen, outprespace);
}

static void
mime_filter_linewrap_reset (CamelMimeFilter *mime_filter)
{
	CamelMimeFilterLinewrapPrivate *priv;

	priv = CAMEL_MIME_FILTER_LINEWRAP_GET_PRIVATE (mime_filter);

	priv->nchars = 0;
}

static void
camel_mime_filter_linewrap_class_init (CamelMimeFilterLinewrapClass *class)
{
	CamelMimeFilterClass *mime_filter_class;

	g_type_class_add_private (class, sizeof (CamelMimeFilterLinewrapPrivate));

	mime_filter_class = CAMEL_MIME_FILTER_CLASS (class);
	mime_filter_class->filter = mime_filter_linewrap_filter;
	mime_filter_class->complete = mime_filter_linewrap_complete;
	mime_filter_class->reset = mime_filter_linewrap_reset;
}

static void
camel_mime_filter_linewrap_init (CamelMimeFilterLinewrap *filter)
{
	filter->priv = CAMEL_MIME_FILTER_LINEWRAP_GET_PRIVATE (filter);
}

CamelMimeFilter *
camel_mime_filter_linewrap_new (guint preferred_len,
                                guint max_len,
                                gchar indent_char,
                                guint32 flags)
{
	CamelMimeFilter *filter;
	CamelMimeFilterLinewrapPrivate *priv;

	filter = g_object_new (CAMEL_TYPE_MIME_FILTER_LINEWRAP, NULL);
	priv = CAMEL_MIME_FILTER_LINEWRAP_GET_PRIVATE (filter);

	priv->indent = indent_char;
	priv->wrap_len = preferred_len;
	priv->max_len = max_len;
	priv->nchars = 0;

	if (indent_char == 0)
		priv->flags |= CAMEL_MIME_FILTER_LINEWRAP_NOINDENT;

	return filter;
}
