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
 */

#include <string.h>

#include "camel-mime-filter-basic.h"
#include "camel-mime-utils.h"

#define CAMEL_MIME_FILTER_BASIC_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER_BASIC, CamelMimeFilterBasicPrivate))

struct _CamelMimeFilterBasicPrivate {
	CamelMimeFilterBasicType type;
	guchar uubuf[60];
	gint state;
	gint save;
};

G_DEFINE_TYPE (CamelMimeFilterBasic, camel_mime_filter_basic, CAMEL_TYPE_MIME_FILTER)

/* here we do all of the basic mime filtering */
static void
mime_filter_basic_filter (CamelMimeFilter *mime_filter,
                          const gchar *in,
                          gsize len,
                          gsize prespace,
                          gchar **out,
                          gsize *outlen,
                          gsize *outprespace)
{
	CamelMimeFilterBasicPrivate *priv;
	gsize newlen;

	priv = CAMEL_MIME_FILTER_BASIC_GET_PRIVATE (mime_filter);

	switch (priv->type) {
	case CAMEL_MIME_FILTER_BASIC_BASE64_ENC:
		/* wont go to more than 2x size (overly conservative) */
		camel_mime_filter_set_size (
			mime_filter, len * 2 + 6, FALSE);
		newlen = g_base64_encode_step (
			(const guchar *) in, len,
			TRUE,
			mime_filter->outbuf,
			&priv->state,
			&priv->save);
		g_return_if_fail (newlen <= len * 2 + 6);
		break;
	case CAMEL_MIME_FILTER_BASIC_QP_ENC:
		/* *4 is overly conservative, but will do */
		camel_mime_filter_set_size (
			mime_filter, len * 4 + 4, FALSE);
		newlen = camel_quoted_encode_step (
			(guchar *) in, len,
			(guchar *) mime_filter->outbuf,
			&priv->state,
			(gint *) &priv->save);
		g_return_if_fail (newlen <= len * 4 + 4);
		break;
	case CAMEL_MIME_FILTER_BASIC_UU_ENC:
		/* won't go to more than 2 * (x + 2) + 62 */
		camel_mime_filter_set_size (
			mime_filter, (len + 2) * 2 + 62, FALSE);
		newlen = camel_uuencode_step (
			(guchar *) in, len,
			(guchar *) mime_filter->outbuf,
			priv->uubuf,
			&priv->state,
			(guint32 *) &priv->save);
		g_return_if_fail (newlen <= (len + 2) * 2 + 62);
		break;
	case CAMEL_MIME_FILTER_BASIC_BASE64_DEC:
		/* output can't possibly exceed the input size */
		camel_mime_filter_set_size (mime_filter, len + 3, FALSE);
		newlen = g_base64_decode_step (
			in, len,
			(guchar *) mime_filter->outbuf,
			&priv->state,
			(guint *) &priv->save);
		g_return_if_fail (newlen <= len + 3);
		break;
	case CAMEL_MIME_FILTER_BASIC_QP_DEC:
		/* output can't possibly exceed the input size */
		camel_mime_filter_set_size (mime_filter, len + 2, FALSE);
		newlen = camel_quoted_decode_step (
			(guchar *) in, len,
			(guchar *) mime_filter->outbuf,
			&priv->state,
			(gint *) &priv->save);
		g_return_if_fail (newlen <= len + 2);
		break;
	case CAMEL_MIME_FILTER_BASIC_UU_DEC:
		if (!(priv->state & CAMEL_UUDECODE_STATE_BEGIN)) {
			const gchar *inptr, *inend;
			gsize left;

			inptr = in;
			inend = inptr + len;

			while (inptr < inend) {
				left = inend - inptr;
				if (left < 6) {
					if (!strncmp (inptr, "begin ", left))
						camel_mime_filter_backup (mime_filter, inptr, left);
					break;
				} else if (!strncmp (inptr, "begin ", 6)) {
					for (in = inptr; inptr < inend && *inptr != '\n'; inptr++);
					if (inptr < inend) {
						inptr++;
						priv->state |= CAMEL_UUDECODE_STATE_BEGIN;
						/* we can start uudecoding... */
						in = inptr;
						len = inend - in;
					} else {
						camel_mime_filter_backup (mime_filter, in, left);
					}
					break;
				}

				/* go to the next line */
				for (; inptr < inend && *inptr != '\n'; inptr++);

				if (inptr < inend)
					inptr++;
			}
		}

		if ((priv->state & CAMEL_UUDECODE_STATE_BEGIN) && !(priv->state & CAMEL_UUDECODE_STATE_END)) {
			/* "begin <mode> <filename>\n" has been
			 * found, so we can now start decoding */
			camel_mime_filter_set_size (
				mime_filter, len + 3, FALSE);
			newlen = camel_uudecode_step (
				(guchar *) in, len,
				(guchar *) mime_filter->outbuf,
				&priv->state,
				(guint32 *) &priv->save);
		} else {
			newlen = 0;
		}
		break;
	default:
		g_warning ("unknown type %u in CamelMimeFilterBasic", priv->type);
		goto donothing;
	}

	*out = mime_filter->outbuf;
	*outlen = newlen;
	*outprespace = mime_filter->outpre;

	return;
donothing:
	*out = (gchar *) in;
	*outlen = len;
	*outprespace = prespace;
}

static void
mime_filter_basic_complete (CamelMimeFilter *mime_filter,
                            const gchar *in,
                            gsize len,
                            gsize prespace,
                            gchar **out,
                            gsize *outlen,
                            gsize *outprespace)
{
	CamelMimeFilterBasicPrivate *priv;
	gsize newlen = 0;

	priv = CAMEL_MIME_FILTER_BASIC_GET_PRIVATE (mime_filter);

	switch (priv->type) {
	case CAMEL_MIME_FILTER_BASIC_BASE64_ENC:
		/* wont go to more than 2x size (overly conservative) */
		camel_mime_filter_set_size (
			mime_filter, len * 2 + 6, FALSE);
		if (len > 0)
			newlen += g_base64_encode_step (
				(const guchar *) in, len,
				TRUE,
				mime_filter->outbuf,
				&priv->state,
				&priv->save);
		newlen += g_base64_encode_close (
			TRUE,
			mime_filter->outbuf,
			&priv->state,
			&priv->save);
		g_return_if_fail (newlen <= len * 2 + 6);
		break;
	case CAMEL_MIME_FILTER_BASIC_QP_ENC:
		/* *4 is definetly more than needed ... */
		camel_mime_filter_set_size (
			mime_filter, len * 4 + 4, FALSE);
		newlen = camel_quoted_encode_close (
			(guchar *) in, len,
			(guchar *) mime_filter->outbuf,
			&priv->state,
			&priv->save);
		g_return_if_fail (newlen <= len * 4 + 4);
		break;
	case CAMEL_MIME_FILTER_BASIC_UU_ENC:
		/* won't go to more than 2 * (x + 2) + 62 */
		camel_mime_filter_set_size (
			mime_filter, (len + 2) * 2 + 62, FALSE);
		newlen = camel_uuencode_close (
			(guchar *) in, len,
			(guchar *) mime_filter->outbuf,
			priv->uubuf,
			&priv->state,
			(guint32 *) &priv->save);
		g_return_if_fail (newlen <= (len + 2) * 2 + 62);
		break;
	case CAMEL_MIME_FILTER_BASIC_BASE64_DEC:
		/* Output can't possibly exceed the input size, but add 1,
		   to make sure the mime_filter->outbuf will not be NULL,
		   in case the input stream is empty. */
		camel_mime_filter_set_size (mime_filter, len + 1, FALSE);
		newlen = g_base64_decode_step (
			in, len,
			(guchar *) mime_filter->outbuf,
			&priv->state,
			(guint *) &priv->save);
		g_return_if_fail (newlen <= len);
		break;
	case CAMEL_MIME_FILTER_BASIC_QP_DEC:
		/* output can't possibly exceed the input size,
		 * well unless its not really qp, then +2 max */
		camel_mime_filter_set_size (mime_filter, len + 2, FALSE);
		newlen = camel_quoted_decode_step (
			(guchar *) in, len,
			(guchar *) mime_filter->outbuf,
			&priv->state,
			(gint *) &priv->save);
		g_return_if_fail (newlen <= len + 2);
		break;
	case CAMEL_MIME_FILTER_BASIC_UU_DEC:
		if ((priv->state & CAMEL_UUDECODE_STATE_BEGIN) && !(priv->state & CAMEL_UUDECODE_STATE_END)) {
			/* "begin <mode> <filename>\n" has been
			 * found, so we can now start decoding */
			camel_mime_filter_set_size (
				mime_filter, len + 3, FALSE);
			newlen = camel_uudecode_step (
				(guchar *) in, len,
				(guchar *) mime_filter->outbuf,
				&priv->state,
				(guint32 *) &priv->save);
		} else {
			newlen = 0;
		}
		break;
	default:
		g_warning ("unknown type %u in CamelMimeFilterBasic", priv->type);
		goto donothing;
	}

	*out = mime_filter->outbuf;
	*outlen = newlen;
	*outprespace = mime_filter->outpre;

	return;
donothing:
	*out = (gchar *) in;
	*outlen = len;
	*outprespace = prespace;
}

/* should this 'flush' outstanding state/data bytes? */
static void
mime_filter_basic_reset (CamelMimeFilter *mime_filter)
{
	CamelMimeFilterBasicPrivate *priv;

	priv = CAMEL_MIME_FILTER_BASIC_GET_PRIVATE (mime_filter);

	switch (priv->type) {
	case CAMEL_MIME_FILTER_BASIC_QP_ENC:
		priv->state = -1;
		break;
	default:
		priv->state = 0;
	}
	priv->save = 0;
}

static void
camel_mime_filter_basic_class_init (CamelMimeFilterBasicClass *class)
{
	CamelMimeFilterClass *mime_filter_class;

	g_type_class_add_private (class, sizeof (CamelMimeFilterBasicPrivate));

	mime_filter_class = CAMEL_MIME_FILTER_CLASS (class);
	mime_filter_class->filter = mime_filter_basic_filter;
	mime_filter_class->complete = mime_filter_basic_complete;
	mime_filter_class->reset = mime_filter_basic_reset;
}

static void
camel_mime_filter_basic_init (CamelMimeFilterBasic *filter)
{
	filter->priv = CAMEL_MIME_FILTER_BASIC_GET_PRIVATE (filter);
}

/**
 * camel_mime_filter_basic_new:
 * @type: a #CamelMimeFilterBasicType type
 *
 * Create a new #CamelMimeFilterBasic object of type @type.
 *
 * Returns: a new #CamelMimeFilterBasic object
 **/
CamelMimeFilter *
camel_mime_filter_basic_new (CamelMimeFilterBasicType type)
{
	CamelMimeFilter *new;

	switch (type) {
	case CAMEL_MIME_FILTER_BASIC_BASE64_ENC:
	case CAMEL_MIME_FILTER_BASIC_QP_ENC:
	case CAMEL_MIME_FILTER_BASIC_BASE64_DEC:
	case CAMEL_MIME_FILTER_BASIC_QP_DEC:
	case CAMEL_MIME_FILTER_BASIC_UU_ENC:
	case CAMEL_MIME_FILTER_BASIC_UU_DEC:
		new = g_object_new (CAMEL_TYPE_MIME_FILTER_BASIC, NULL);
		CAMEL_MIME_FILTER_BASIC (new)->priv->type = type;
		break;
	default:
		g_warning ("Invalid type of CamelMimeFilterBasic requested: %u", type);
		new = NULL;
		break;
	}
	camel_mime_filter_reset (new);

	return new;
}

