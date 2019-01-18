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

#include <stdio.h>
#include <string.h>

#include "camel-mime-filter-bestenc.h"

#define CAMEL_MIME_FILTER_BESTENC_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER_BESTENC, CamelMimeFilterBestencPrivate))

struct _CamelMimeFilterBestencPrivate {

	guint flags;	/* our creation flags */

	guint count0;	/* count of NUL characters */
	guint count8;	/* count of 8 bit characters */
	guint total;	/* total characters read */

	guint lastc;	/* the last character read */
	gint crlfnoorder;	/* if crlf's occurred where they shouldn't have */

	gint startofline;	/* are we at the start of a new line? */

	gint fromcount;
	gchar fromsave[6];	/* save a few characters if we found an \n near the end of the buffer */
	gint hadfrom;		/* did we encounter a "\nFrom " in the data? */

	guint countline;	/* current count of characters on a given line */
	guint maxline;	/* max length of any line */

	CamelCharset charset;	/* used to determine the best charset to use */
};

G_DEFINE_TYPE (CamelMimeFilterBestenc, camel_mime_filter_bestenc, CAMEL_TYPE_MIME_FILTER)

static void
mime_filter_bestenc_filter (CamelMimeFilter *mime_filter,
                            const gchar *in,
                            gsize len,
                            gsize prespace,
                            gchar **out,
                            gsize *outlen,
                            gsize *outprespace)
{
	CamelMimeFilterBestencPrivate *priv;
	register guchar *p, *pend;

	priv = CAMEL_MIME_FILTER_BESTENC_GET_PRIVATE (mime_filter);

	if (len == 0)
		goto donothing;

	if (priv->flags & CAMEL_BESTENC_GET_ENCODING) {
		register guint /* hopefully reg's are assinged in the order they appear? */
			c,
			lastc = priv->lastc,
			countline = priv->countline,
			count0 = priv->count0,
			count8 = priv->count8;

		/* Check ^From  lines first call, or have the start of a new line waiting? */
		if ((priv->flags & CAMEL_BESTENC_NO_FROM) && !priv->hadfrom
		    && (priv->fromcount > 0 || priv->startofline)) {
			if (priv->fromcount + len >=5) {
				memcpy (&priv->fromsave[priv->fromcount], in, 5 - priv->fromcount);
				priv->hadfrom = strncmp (priv->fromsave, "From ", 5) == 0;
				priv->fromcount = 0;
			} else {
				memcpy (&priv->fromsave[priv->fromcount], in, len);
				priv->fromcount += len;
			}
		}

		priv->startofline = FALSE;

		/* See rfc2045 section 2 for definitions of 7bit/8bit/binary */
		p = (guchar *) in;
		pend = p + len;
		while (p < pend) {
			c = *p++;
			/* check for 8 bit characters */
			if (c & 0x80)
				count8++;

			/* check for nul's */
			if (c == 0)
				count0++;

			/* check for wild '\r's in a unix format stream */
			if (c == '\r' && (priv->flags & CAMEL_BESTENC_LF_IS_CRLF)) {
				priv->crlfnoorder = TRUE;
			}

			/* check for end of line */
			if (c == '\n') {
				/* check for wild '\n's in canonical format stream */
				if (lastc == '\r' || (priv->flags & CAMEL_BESTENC_LF_IS_CRLF)) {
					if (countline > priv->maxline)
						priv->maxline = countline;
					countline = 0;

					/* Check for "^From " lines */
					if ((priv->flags & CAMEL_BESTENC_NO_FROM) && !priv->hadfrom) {
						if (pend - p >= 5) {
							priv->hadfrom = strncmp ((gchar *) p, (gchar *) "From ", 5) == 0;
						} else if (pend - p == 0) {
							priv->startofline = TRUE;
						} else {
							priv->fromcount = pend - p;
							memcpy (priv->fromsave, p, pend - p);
						}
					}
				} else {
					priv->crlfnoorder = TRUE;
				}
			} else {
				countline++;
			}
			lastc = c;
		}
		priv->count8 = count8;
		priv->count0 = count0;
		priv->countline = countline;
		priv->lastc = lastc;
	}

	priv->total += len;

	if (priv->flags & CAMEL_BESTENC_GET_CHARSET)
		camel_charset_step (&priv->charset, in, len);

donothing:
	*out = (gchar *) in;
	*outlen = len;
	*outprespace = prespace;
}

static void
mime_filter_bestenc_complete (CamelMimeFilter *mime_filter,
                              const gchar *in,
                              gsize len,
                              gsize prespace,
                              gchar **out,
                              gsize *outlen,
                              gsize *outprespace)
{
	CamelMimeFilterBestencPrivate *priv;

	priv = CAMEL_MIME_FILTER_BESTENC_GET_PRIVATE (mime_filter);

	mime_filter_bestenc_filter (
		mime_filter, in, len, prespace, out, outlen, outprespace);

	if (priv->countline > priv->maxline)
		priv->maxline = priv->countline;
	priv->countline = 0;
}

static void
mime_filter_bestenc_reset (CamelMimeFilter *mime_filter)
{
	CamelMimeFilterBestencPrivate *priv;

	priv = CAMEL_MIME_FILTER_BESTENC_GET_PRIVATE (mime_filter);

	priv->count0 = 0;
	priv->count8 = 0;
	priv->countline = 0;
	priv->total = 0;
	priv->lastc = ~0;
	priv->crlfnoorder = FALSE;
	priv->fromcount = 0;
	priv->hadfrom = FALSE;
	priv->startofline = TRUE;

	camel_charset_init (&priv->charset);
}

static void
camel_mime_filter_bestenc_class_init (CamelMimeFilterBestencClass *class)
{
	CamelMimeFilterClass *mime_filter_class;

	g_type_class_add_private (class, sizeof (CamelMimeFilterBestencPrivate));

	mime_filter_class = CAMEL_MIME_FILTER_CLASS (class);
	mime_filter_class->filter = mime_filter_bestenc_filter;
	mime_filter_class->complete = mime_filter_bestenc_complete;
	mime_filter_class->reset = mime_filter_bestenc_reset;
}

static void
camel_mime_filter_bestenc_init (CamelMimeFilterBestenc *filter)
{
	filter->priv = CAMEL_MIME_FILTER_BESTENC_GET_PRIVATE (filter);

	mime_filter_bestenc_reset (CAMEL_MIME_FILTER (filter));
}

/**
 * camel_mime_filter_bestenc_new:
 * @flags: a bitmask of data required.
 *
 * Create a new #CamelMimeFilterBestenc object.
 *
 * Returns: a new #CamelMimeFilterBestenc object
 **/
CamelMimeFilter *
camel_mime_filter_bestenc_new (guint flags)
{
	CamelMimeFilter *new;

	new = g_object_new (CAMEL_TYPE_MIME_FILTER_BESTENC, NULL);
	CAMEL_MIME_FILTER_BESTENC (new)->priv->flags = flags;

	return new;
}

/**
 * camel_mime_filter_bestenc_get_best_encoding:
 * @filter: a #CamelMimeFilterBestenc object
 * @required: maximum level of output encoding allowed.
 *
 * Get the best encoding, given specific constraints, that can be used to
 * encode a stream of bytes.
 *
 * Returns: the best encoding to use
 **/
CamelTransferEncoding
camel_mime_filter_bestenc_get_best_encoding (CamelMimeFilterBestenc *filter,
                                             CamelBestencEncoding required)
{
	CamelMimeFilterBestencPrivate *priv;
	CamelTransferEncoding bestenc;
	gint istext;

	priv = CAMEL_MIME_FILTER_BESTENC_GET_PRIVATE (filter);

	istext = (required & CAMEL_BESTENC_TEXT) ? 1 : 0;
	required = required & ~CAMEL_BESTENC_TEXT;

#if 0
	printf ("count0 = %d, count8 = %d, total = %d\n", priv->count0, priv->count8, priv->total);
	printf ("maxline = %d, crlfnoorder = %s\n", priv->maxline, priv->crlfnoorder?"TRUE":"FALSE");
	printf (" %d%% require encoding?\n", (priv->count0 + priv->count8) * 100 / priv->total);
#endif

	/* if we're not allowed to have From lines and we had one, use an encoding
	 * that will never let it show.  Unfortunately only base64 can at present,
	 * although qp could be modified to allow it too */
	if ((priv->flags & CAMEL_BESTENC_NO_FROM) && priv->hadfrom)
		return CAMEL_TRANSFER_ENCODING_BASE64;

	/* if we need to encode, see how we do it */
	if (required == CAMEL_BESTENC_BINARY)
		bestenc = CAMEL_TRANSFER_ENCODING_BINARY;
	else if (istext && (priv->count0 == 0 && priv->count8 < (priv->total * 17 / 100)))
		bestenc = CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE;
	else
		bestenc = CAMEL_TRANSFER_ENCODING_BASE64;

	/* if we have nocrlf order, or long lines, we need to encode always */
	if (priv->crlfnoorder || priv->maxline >= 998)
		return bestenc;

	/* if we have no 8 bit chars or nul's, we can just use 7 bit */
	if (priv->count8 + priv->count0 == 0)
		return CAMEL_TRANSFER_ENCODING_7BIT;

	/* otherwise, we see if we can use 8 bit, or not */
	switch (required) {
	case CAMEL_BESTENC_7BIT:
		return bestenc;
	case CAMEL_BESTENC_8BIT:
	case CAMEL_BESTENC_BINARY:
	default:
		if (priv->count0 == 0)
			return CAMEL_TRANSFER_ENCODING_8BIT;
		else
			return bestenc;
	}

}

/**
 * camel_mime_filter_bestenc_get_best_charset:
 * @filter: a #CamelMimeFilterBestenc object
 *
 * Gets the best charset that can be used to contain this content.
 *
 * Returns: the name of the best charset to use to encode the input
 * text filtered by @filter
 **/
const gchar *
camel_mime_filter_bestenc_get_best_charset (CamelMimeFilterBestenc *filter)
{
	g_return_val_if_fail (CAMEL_IS_MIME_FILTER_BESTENC (filter), NULL);

	return camel_charset_best_name (&filter->priv->charset);
}

/**
 * camel_mime_filter_bestenc_set_flags:
 * @filter: a #CamelMimeFilterBestenc object
 * @flags: bestenc filter flags
 *
 * Set the flags for subsequent operations.
 **/
void
camel_mime_filter_bestenc_set_flags (CamelMimeFilterBestenc *filter,
                                     guint flags)
{
	g_return_if_fail (CAMEL_IS_MIME_FILTER_BESTENC (filter));

	filter->priv->flags = flags;
}
