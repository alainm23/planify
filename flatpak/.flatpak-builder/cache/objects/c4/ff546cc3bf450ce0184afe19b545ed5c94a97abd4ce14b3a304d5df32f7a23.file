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

#include "evolution-data-server-config.h"

#include <string.h>

#include "camel-mime-filter-from.h"

#define CAMEL_MIME_FILTER_FROM_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER_FROM, CamelMimeFilterFromPrivate))

#define d(x)

struct _CamelMimeFilterFromPrivate {
	gboolean midline;	/* are we between lines? */
};

struct fromnode {
	struct fromnode *next;
	const gchar *pointer;
};

G_DEFINE_TYPE (CamelMimeFilterFrom, camel_mime_filter_from, CAMEL_TYPE_MIME_FILTER)

/* Yes, it is complicated ... */
static void
mime_filter_from_filter (CamelMimeFilter *mime_filter,
                         const gchar *in,
                         gsize len,
                         gsize prespace,
                         gchar **out,
                         gsize *outlen,
                         gsize *outprespace)
{
	CamelMimeFilterFromPrivate *priv;
	const gchar *inptr, *inend;
	gint left;
	gint fromcount = 0;
	struct fromnode *head = NULL, *tail = (struct fromnode *) &head, *node;
	gchar *outptr;

	priv = CAMEL_MIME_FILTER_FROM_GET_PRIVATE (mime_filter);

	inptr = in;
	inend = inptr + len;

	d (printf ("Filtering '%.*s'\n", len, in));

	/* first, see if we need to escape any from's */
	while (inptr < inend) {
		register gint c = -1;

		if (priv->midline)
			while (inptr < inend && (c = *inptr++) != '\n')
				;

		if (c == '\n' || !priv->midline) {
			left = inend - inptr;
			if (left > 0) {
				priv->midline = TRUE;
				if (left < 5) {
					if (inptr[0] == 'F') {
						camel_mime_filter_backup (mime_filter, inptr, left);
						priv->midline = FALSE;
						inend = inptr;
						break;
					}
				} else {
					if (!strncmp (inptr, "From ", 5)) {
						fromcount++;
						/* yes, we do alloc them on the stack ... at most we're going to get
						 * len / 7 of them anyway */
						node = alloca (sizeof (*node));
						node->pointer = inptr;
						node->next = NULL;
						tail->next = node;
						tail = node;
						inptr += 5;
					}
				}
			} else {
				/* \n is at end of line, check next buffer */
				priv->midline = FALSE;
			}
		}
	}

	if (fromcount > 0) {
		camel_mime_filter_set_size (mime_filter, len + fromcount, FALSE);
		node = head;
		inptr = in;
		outptr = mime_filter->outbuf;
		while (node) {
			memcpy (outptr, inptr, node->pointer - inptr);
			outptr += node->pointer - inptr;
			*outptr++ = '>';
			inptr = node->pointer;
			node = node->next;
		}
		memcpy (outptr, inptr, inend - inptr);
		outptr += inend - inptr;
		*out = mime_filter->outbuf;
		*outlen = outptr - mime_filter->outbuf;
		*outprespace = mime_filter->outbuf - mime_filter->outreal;

		d (printf ("Filtered '%.*s'\n", *outlen, *out));
	} else {
		*out = (gchar *) in;
		*outlen = inend - in;
		*outprespace = prespace;

		d (printf ("Filtered '%.*s'\n", *outlen, *out));
	}
}

static void
mime_filter_from_complete (CamelMimeFilter *mime_filter,
                           const gchar *in,
                           gsize len,
                           gsize prespace,
                           gchar **out,
                           gsize *outlen,
                           gsize *outprespace)
{
	*out = (gchar *) in;
	*outlen = len;
	*outprespace = prespace;
}

static void
camel_mime_filter_from_class_init (CamelMimeFilterFromClass *class)
{
	CamelMimeFilterClass *mime_filter_class;

	g_type_class_add_private (class, sizeof (CamelMimeFilterFromPrivate));

	mime_filter_class = CAMEL_MIME_FILTER_CLASS (class);
	mime_filter_class->filter = mime_filter_from_filter;
	mime_filter_class->complete = mime_filter_from_complete;
}

static void
camel_mime_filter_from_init (CamelMimeFilterFrom *filter)
{
	filter->priv = CAMEL_MIME_FILTER_FROM_GET_PRIVATE (filter);
}

/**
 * camel_mime_filter_from_new:
 *
 * Create a new #CamelMimeFilterFrom object.
 *
 * Returns: a new #CamelMimeFilterFrom object
 **/
CamelMimeFilter *
camel_mime_filter_from_new (void)
{
	return g_object_new (CAMEL_TYPE_MIME_FILTER_FROM, NULL);
}

#if 0

#include <stdio.h>

gint main (gint argc, gchar **argv)
{
	CamelMimeFilterFrom *f;
	gchar *buffer;
	gint len, prespace;

	g_tk_init (&argc, &argv);

	f = camel_mime_filter_from_new ();

	buffer = "This is a test\nFrom Someone\nTo someone. From Someone else, From\n From blah\nFromblah\nBye! \nFrom ";
	len = strlen (buffer);
	prespace = 0;

	printf ("input = '%.*s'\n", len, buffer);
	camel_mime_filter_filter (f, buffer, len, prespace, &buffer, &len, &prespace);
	printf ("output = '%.*s'\n", len, buffer);
	buffer = "";
	len = 0;
	prespace = 0;
	camel_mime_filter_complete (f, buffer, len, prespace, &buffer, &len, &prespace);
	printf ("complete = '%.*s'\n", len, buffer);

	return 0;
}

#endif
