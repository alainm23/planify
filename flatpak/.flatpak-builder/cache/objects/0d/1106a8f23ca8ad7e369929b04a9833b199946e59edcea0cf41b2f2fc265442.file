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
 *          Michael Zucchi <notzed@ximian.com>
 */

/* canonicalisation filter, used for secure mime incoming and outgoing */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <string.h>

#include "camel-mime-filter-canon.h"

#define CAMEL_MIME_FILTER_CANON_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER_CANON, CamelMimeFilterCanonPrivate))

struct _CamelMimeFilterCanonPrivate {
	guint32 flags;
};

G_DEFINE_TYPE (
	CamelMimeFilterCanon,
	camel_mime_filter_canon,
	CAMEL_TYPE_MIME_FILTER)

static void
mime_filter_canon_run (CamelMimeFilter *mime_filter,
                       const gchar *in,
                       gsize len,
                       gsize prespace,
                       gchar **out,
                       gsize *outlen,
                       gsize *outprespace,
                       gint last)
{
	CamelMimeFilterCanonPrivate *priv;
	register guchar *inptr, c;
	const guchar *inend, *start;
	gchar *starto;
	register gchar *o;
	gint lf = 0;

	priv = CAMEL_MIME_FILTER_CANON_GET_PRIVATE (mime_filter);

	/* first, work out how much space we need */
	inptr = (guchar *) in;
	inend = (const guchar *) (in + len);
	while (inptr < inend)
		if (*inptr++ == '\n')
			lf++;

	/* worst case, extra 3 chars per line
	 * "From \n" -> "=46rom \r\n"
	 * We add 1 extra incase we're called from complete, when we didn't end in \n */

	camel_mime_filter_set_size (mime_filter, len + lf * 3 + 4, FALSE);

	o = mime_filter->outbuf;
	inptr = (guchar *) in;
	start = inptr;
	starto = o;
	while (inptr < inend) {
		/* first, check start of line, we always start at the start of the line */
		c = *inptr;
		if (priv->flags & CAMEL_MIME_FILTER_CANON_FROM && c == 'F') {
			inptr++;
			if (inptr < inend - 4) {
				if (strncmp ((gchar *) inptr, "rom ", 4) == 0) {
					strcpy (o, "=46rom ");
					inptr+=4;
					o+= 7;
				} else
					*o++ = 'F';
			} else if (last)
				*o++ = 'F';
			else
				break;
		}

		/* now scan for end of line */
		while (inptr < inend) {
			c = *inptr++;
			if (c == '\n') {
				/* check to strip trailing space */
				if (priv->flags & CAMEL_MIME_FILTER_CANON_STRIP) {
					while (o > starto && (o[-1] == ' ' || o[-1] == '\t' || o[-1]=='\r'))
						o--;
				}
				/* check end of line canonicalisation */
				if (o > starto) {
					if (priv->flags & CAMEL_MIME_FILTER_CANON_CRLF) {
						if (o[-1] != '\r')
							*o++ = '\r';
					} else {
						if (o[-1] == '\r')
							o--;
					}
				} else if (priv->flags & CAMEL_MIME_FILTER_CANON_CRLF) {
					/* empty line */
					*o++ = '\r';
				}

				*o++ = c;
				start = inptr;
				starto = o;
				break;
			} else
				*o++ = c;
		}
	}

	/* TODO: We should probably track if we end somewhere in the middle of a line,
	 * otherwise we potentially backup a full line, which could be large */

	/* we got to the end of the data without finding anything, backup to start and re-process next time around */
	if (last) {
		*outlen = o - mime_filter->outbuf;
	} else {
		camel_mime_filter_backup (
			mime_filter, (const gchar *) start, inend - start);
		*outlen = starto - mime_filter->outbuf;
	}

	*out = mime_filter->outbuf;
	*outprespace = mime_filter->outpre;
}

static void
mime_filter_canon_filter (CamelMimeFilter *mime_filter,
                          const gchar *in,
                          gsize len,
                          gsize prespace,
                          gchar **out,
                          gsize *outlen,
                          gsize *outprespace)
{
	mime_filter_canon_run (
		mime_filter, in, len, prespace,
		out, outlen, outprespace, FALSE);
}

static void
mime_filter_canon_complete (CamelMimeFilter *mime_filter,
                            const gchar *in,
                            gsize len,
                            gsize prespace,
                            gchar **out,
                            gsize *outlen,
                            gsize *outprespace)
{
	mime_filter_canon_run (
		mime_filter, in, len, prespace,
		out, outlen, outprespace, TRUE);
}

static void
mime_filter_canon_reset (CamelMimeFilter *mime_filter)
{
	/* no-op */
}

static void
camel_mime_filter_canon_class_init (CamelMimeFilterCanonClass *class)
{
	CamelMimeFilterClass *mime_filter_class;

	g_type_class_add_private (class, sizeof (CamelMimeFilterCanonPrivate));

	mime_filter_class = CAMEL_MIME_FILTER_CLASS (class);
	mime_filter_class->filter = mime_filter_canon_filter;
	mime_filter_class->complete = mime_filter_canon_complete;
	mime_filter_class->reset = mime_filter_canon_reset;
}

static void
camel_mime_filter_canon_init (CamelMimeFilterCanon *filter)
{
	filter->priv = CAMEL_MIME_FILTER_CANON_GET_PRIVATE (filter);
}

/**
 * camel_mime_filter_canon_new:
 * @flags: bitwise flags defining the behaviour of the filter
 *
 * Create a new filter to canonicalise an input stream.
 *
 * Returns: a new #CamelMimeFilterCanon
 **/
CamelMimeFilter *
camel_mime_filter_canon_new (guint32 flags)
{
	CamelMimeFilter *filter;

	filter = g_object_new (CAMEL_TYPE_MIME_FILTER_CANON, NULL);
	CAMEL_MIME_FILTER_CANON (filter)->priv->flags = flags;

	return filter;
}
