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
 * Authors: Matt Brown <matt@mattb.net.nz>
 *          Jeffrey Stedfast <fejj@novell.com>
 */

/* Strips PGP message headers from the input stream and also performs
 * pgp decoding as described in section 7.1 of RFC2440 */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <string.h>

#include "camel-mime-filter-pgp.h"
#include "camel-mime-utils.h"

#define CAMEL_MIME_FILTER_PGP_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER_PGP, CamelMimeFilterPgpPrivate))

#define BEGIN_PGP_SIGNED_MESSAGE "-----BEGIN PGP SIGNED MESSAGE-----"
#define BEGIN_PGP_SIGNATURE      "-----BEGIN PGP SIGNATURE-----"
#define END_PGP_SIGNATURE        "-----END PGP SIGNATURE-----"

#define BEGIN_PGP_SIGNED_MESSAGE_LEN (sizeof (BEGIN_PGP_SIGNED_MESSAGE) - 1)
#define BEGIN_PGP_SIGNATURE_LEN      (sizeof (BEGIN_PGP_SIGNATURE) - 1)
#define END_PGP_SIGNATURE_LEN        (sizeof (END_PGP_SIGNATURE) - 1)

struct _CamelMimeFilterPgpPrivate {
	gint state;
};

enum {
	PGP_PREFACE,
	PGP_HEADER,
	PGP_MESSAGE,
	PGP_FOOTER
};

G_DEFINE_TYPE (CamelMimeFilterPgp, camel_mime_filter_pgp, CAMEL_TYPE_MIME_FILTER)

static void
mime_filter_pgp_run (CamelMimeFilter *mime_filter,
                     const gchar *in,
                     gsize inlen,
                     gsize prespace,
                     gchar **out,
                     gsize *outlen,
                     gsize *outprespace,
                     gint last)
{
	CamelMimeFilterPgpPrivate *priv;
	const gchar *start, *inend = in + inlen;
	register const gchar *inptr = in;
	register gchar *o;
	gboolean blank;
	gsize len;

	priv = CAMEL_MIME_FILTER_PGP_GET_PRIVATE (mime_filter);

	/* only need as much space as the input, we're stripping chars */
	camel_mime_filter_set_size (mime_filter, inlen, FALSE);

	o = mime_filter->outbuf;

	while (inptr < inend) {
		start = inptr;

		blank = TRUE;
		while (inptr < inend && *inptr != '\n') {
			if (blank && !strchr (" \t\r", *inptr))
				blank = FALSE;
			inptr++;
		}

		if (inptr == inend) {
			if (!last) {
				camel_mime_filter_backup (mime_filter, start, inend - start);
				inend = start;
			}
			break;
		}

		len = inptr - start;
		if (len > 0 && inptr[-1] == '\r')
			len--;

		while (len > 0 && camel_mime_is_lwsp (start[len - 1]))
			len--;

		inptr++;

		switch (priv->state) {
		case PGP_PREFACE:
			/* check for the beginning of the pgp block */
			if (len == BEGIN_PGP_SIGNED_MESSAGE_LEN && !strncmp (start, BEGIN_PGP_SIGNED_MESSAGE, len)) {
				priv->state++;
				break;
			}

			memcpy (o, start, inptr - start);
			o += (inptr - start);
			break;
		case PGP_HEADER:
			/* pgp headers (Hash: SHA1, etc) end with a blank (zero-length,
			 * or containing only whitespace) line; see RFC2440 */
			if (blank)
				priv->state++;
			break;
		case PGP_MESSAGE:
			/* check for beginning of the pgp signature block */
			if (len == BEGIN_PGP_SIGNATURE_LEN && !strncmp (start, BEGIN_PGP_SIGNATURE, len)) {
				priv->state++;
				break;
			}

			/* do dash decoding */
			if (!strncmp (start, "- ", 2)) {
				/* Dash encoded line found, skip encoding */
				start += 2;
			}

			memcpy (o, start, inptr - start);
			o += (inptr - start);
			break;
		case PGP_FOOTER:
			if (len == END_PGP_SIGNATURE_LEN && !strncmp (start, END_PGP_SIGNATURE, len))
				priv->state = PGP_PREFACE;
			break;
		}
	}

	*out = mime_filter->outbuf;
	*outlen = o - mime_filter->outbuf;
	*outprespace = mime_filter->outpre;
}

static void
mime_filter_pgp_filter (CamelMimeFilter *mime_filter,
                        const gchar *in,
                        gsize len,
                        gsize prespace,
                        gchar **out,
                        gsize *outlen,
                        gsize *outprespace)
{
	mime_filter_pgp_run (
		mime_filter, in, len, prespace,
		out, outlen, outprespace, FALSE);
}

static void
mime_filter_pgp_complete (CamelMimeFilter *mime_filter,
                          const gchar *in,
                          gsize len,
                          gsize prespace,
                          gchar **out,
                          gsize *outlen,
                          gsize *outprespace)
{
	mime_filter_pgp_run (
		mime_filter, in, len, prespace,
		out, outlen, outprespace, TRUE);
}

static void
mime_filter_pgp_reset (CamelMimeFilter *mime_filter)
{
	CamelMimeFilterPgpPrivate *priv;

	priv = CAMEL_MIME_FILTER_PGP_GET_PRIVATE (mime_filter);

	priv->state = PGP_PREFACE;
}

static void
camel_mime_filter_pgp_class_init (CamelMimeFilterPgpClass *class)
{
	CamelMimeFilterClass *mime_filter_class;

	g_type_class_add_private (class, sizeof (CamelMimeFilterPgpPrivate));

	mime_filter_class = CAMEL_MIME_FILTER_CLASS (class);
	mime_filter_class->filter = mime_filter_pgp_filter;
	mime_filter_class->complete = mime_filter_pgp_complete;
	mime_filter_class->reset = mime_filter_pgp_reset;
}

static void
camel_mime_filter_pgp_init (CamelMimeFilterPgp *filter)
{
	filter->priv = CAMEL_MIME_FILTER_PGP_GET_PRIVATE (filter);
}

CamelMimeFilter *
camel_mime_filter_pgp_new (void)
{
	return g_object_new (CAMEL_TYPE_MIME_FILTER_PGP, NULL);
}
