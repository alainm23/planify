/*
 * camel-imapx-input-stream.h
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
 */

#include "evolution-data-server-config.h"

#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <errno.h>

#include <glib/gi18n-lib.h>

#include <camel/camel.h>

#include "camel-imapx-server.h"
#include "camel-imapx-utils.h"

#include "camel-imapx-input-stream.h"

#define CAMEL_IMAPX_INPUT_STREAM_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_IMAPX_INPUT_STREAM, CamelIMAPXInputStreamPrivate))

struct _CamelIMAPXInputStreamPrivate {
	guchar *buf, *ptr, *end;
	guint literal;

	guint unget;
	camel_imapx_token_t unget_tok;
	guchar *unget_token;
	guint unget_len;

	guchar *tokenbuf;
	guint bufsize;
};

/* Forward Declarations */
static void	camel_imapx_input_stream_pollable_init
				(GPollableInputStreamInterface *iface);

G_DEFINE_TYPE_WITH_CODE (
	CamelIMAPXInputStream,
	camel_imapx_input_stream,
	G_TYPE_FILTER_INPUT_STREAM,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_POLLABLE_INPUT_STREAM,
		camel_imapx_input_stream_pollable_init))

static gint
imapx_input_stream_fill (CamelIMAPXInputStream *is,
                         GCancellable *cancellable,
                         GError **error)
{
	GInputStream *base_stream;
	gint left = 0;

	if (g_cancellable_is_cancelled (cancellable))
		return -1;

	base_stream = g_filter_input_stream_get_base_stream (
		G_FILTER_INPUT_STREAM (is));

	if (error && *error) {
		g_warning ("%s: Avoiding GIO call with a filled error '%s'", G_STRFUNC, (*error)->message);
		error = NULL;
	}

	left = is->priv->end - is->priv->ptr;
	memcpy (is->priv->buf, is->priv->ptr, left);
	is->priv->end = is->priv->buf + left;
	is->priv->ptr = is->priv->buf;
	left = g_input_stream_read (
		base_stream,
		is->priv->end,
		is->priv->bufsize - (is->priv->end - is->priv->buf),
		cancellable, error);
	if (left > 0) {
		is->priv->end += left;
		return is->priv->end - is->priv->ptr;
	} else {
		/* If returning zero, camel_stream_read() doesn't consider
		 * that to be an error. But we do -- we should only be here
		 * if we *know* there are data to receive. So set the error
		 * accordingly */
		if (!left)
			g_set_error (
				error, CAMEL_IMAPX_SERVER_ERROR, CAMEL_IMAPX_SERVER_ERROR_TRY_RECONNECT,
				_("Source stream returned no data"));
		return -1;
	}
}

static void
imapx_input_stream_finalize (GObject *object)
{
	CamelIMAPXInputStreamPrivate *priv;

	priv = CAMEL_IMAPX_INPUT_STREAM_GET_PRIVATE (object);

	g_free (priv->buf);
	g_free (priv->tokenbuf);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_imapx_input_stream_parent_class)->
		finalize (object);
}

static gssize
imapx_input_stream_read (GInputStream *stream,
                         gpointer buffer,
                         gsize count,
                         GCancellable *cancellable,
                         GError **error)
{
	CamelIMAPXInputStreamPrivate *priv;
	GInputStream *base_stream;
	gssize max;

	priv = CAMEL_IMAPX_INPUT_STREAM_GET_PRIVATE (stream);

	base_stream = g_filter_input_stream_get_base_stream (
		G_FILTER_INPUT_STREAM (stream));

	if (priv->literal == 0 || count == 0)
		return 0;

	max = priv->end - priv->ptr;
	if (max > 0) {
		max = MIN (max, priv->literal);
		max = MIN (max, count);
		memcpy (buffer, priv->ptr, max);
		priv->ptr += max;
	} else {
		if (error && *error) {
			g_warning ("%s: Avoiding GIO call with a filled error '%s'", G_STRFUNC, (*error)->message);
			error = NULL;
		}

		max = MIN (priv->literal, count);
		max = g_input_stream_read (
			base_stream, buffer, max, cancellable, error);
		if (max <= 0)
			return max;
	}

	priv->literal -= max;

	return max;
}

static gboolean
imapx_input_stream_can_poll (GPollableInputStream *pollable_stream)
{
	GInputStream *base_stream;

	base_stream = g_filter_input_stream_get_base_stream (
		G_FILTER_INPUT_STREAM (pollable_stream));

	pollable_stream = G_POLLABLE_INPUT_STREAM (base_stream);

	return g_pollable_input_stream_can_poll (pollable_stream);
}

static gboolean
imapx_input_stream_is_readable (GPollableInputStream *pollable_stream)
{
	GInputStream *base_stream;

	base_stream = g_filter_input_stream_get_base_stream (
		G_FILTER_INPUT_STREAM (pollable_stream));

	pollable_stream = G_POLLABLE_INPUT_STREAM (base_stream);

	return g_pollable_input_stream_is_readable (pollable_stream);
}

static GSource *
imapx_input_stream_create_source (GPollableInputStream *pollable_stream,
                                  GCancellable *cancellable)
{
	GInputStream *base_stream;

	base_stream = g_filter_input_stream_get_base_stream (
		G_FILTER_INPUT_STREAM (pollable_stream));

	pollable_stream = G_POLLABLE_INPUT_STREAM (base_stream);

	return g_pollable_input_stream_create_source (
		pollable_stream, cancellable);
}

static gssize
imapx_input_stream_read_nonblocking (GPollableInputStream *pollable_stream,
                                     gpointer buffer,
                                     gsize count,
                                     GError **error)
{
	GInputStream *base_stream;

	base_stream = g_filter_input_stream_get_base_stream (
		G_FILTER_INPUT_STREAM (pollable_stream));

	pollable_stream = G_POLLABLE_INPUT_STREAM (base_stream);

	if (error && *error) {
		g_warning ("%s: Avoiding GIO call with a filled error '%s'", G_STRFUNC, (*error)->message);
		error = NULL;
	}

	/* XXX The function takes a GCancellable but the class method
	 *     does not.  Should be okay to pass NULL here since this
	 *     is just a pass-through. */
	return g_pollable_input_stream_read_nonblocking (
		pollable_stream, buffer, count, NULL, error);
}

static void
camel_imapx_input_stream_class_init (CamelIMAPXInputStreamClass *class)
{
	GObjectClass *object_class;
	GInputStreamClass *input_stream_class;

	g_type_class_add_private (
		class, sizeof (CamelIMAPXInputStreamPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = imapx_input_stream_finalize;

	input_stream_class = G_INPUT_STREAM_CLASS (class);
	input_stream_class->read_fn = imapx_input_stream_read;
}

static void
camel_imapx_input_stream_pollable_init (GPollableInputStreamInterface *iface)
{
	iface->can_poll = imapx_input_stream_can_poll;
	iface->is_readable = imapx_input_stream_is_readable;
	iface->create_source = imapx_input_stream_create_source;
	iface->read_nonblocking = imapx_input_stream_read_nonblocking;
}

static void
camel_imapx_input_stream_init (CamelIMAPXInputStream *is)
{
	is->priv = CAMEL_IMAPX_INPUT_STREAM_GET_PRIVATE (is);

	/* +1 is room for appending a 0 if we need to for a token */
	is->priv->bufsize = 4096;
	is->priv->buf = g_malloc (is->priv->bufsize + 1);
	is->priv->ptr = is->priv->end = is->priv->buf;
	is->priv->tokenbuf = g_malloc (is->priv->bufsize + 1);
}

static void
camel_imapx_input_stream_grow (CamelIMAPXInputStream *is,
                               guint len,
                               guchar **bufptr,
                               guchar **tokptr)
{
	guchar *oldtok = is->priv->tokenbuf;
	guchar *oldbuf = is->priv->buf;

	do {
		is->priv->bufsize <<= 1;
	} while (is->priv->bufsize <= len);

	is->priv->tokenbuf = g_realloc (
		is->priv->tokenbuf,
		is->priv->bufsize + 1);
	if (tokptr)
		*tokptr = is->priv->tokenbuf + (*tokptr - oldtok);
	if (is->priv->unget)
		is->priv->unget_token =
			is->priv->tokenbuf +
			(is->priv->unget_token - oldtok);

	is->priv->buf = g_realloc (is->priv->buf, is->priv->bufsize + 1);
	is->priv->ptr = is->priv->buf + (is->priv->ptr - oldbuf);
	is->priv->end = is->priv->buf + (is->priv->end - oldbuf);
	if (bufptr)
		*bufptr = is->priv->buf + (*bufptr - oldbuf);
}

G_DEFINE_QUARK (camel-imapx-error-quark, camel_imapx_error)

/**
 * camel_imapx_input_stream_new:
 * @base_stream: a pollable #GInputStream
 *
 * Creates a new #CamelIMAPXInputStream which wraps @base_stream and
 * parses incoming IMAP lines into tokens.
 *
 * Returns: a #CamelIMAPXInputStream
 *
 * Since: 3.12
 **/
GInputStream *
camel_imapx_input_stream_new (GInputStream *base_stream)
{
	/* We implement GPollableInputStream by forwarding method calls
	 * to the base stream, so the base stream needs to be pollable. */
	g_return_val_if_fail (G_IS_POLLABLE_INPUT_STREAM (base_stream), NULL);

	return g_object_new (
		CAMEL_TYPE_IMAPX_INPUT_STREAM,
		"base-stream", base_stream, NULL);
}

/* Returns if there is any data buffered that is ready for processing */
gint
camel_imapx_input_stream_buffered (CamelIMAPXInputStream *is)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is), 0);

	return is->priv->end - is->priv->ptr;
}

/* FIXME: these should probably handle it themselves,
 * and get rid of the token interface? */
gboolean
camel_imapx_input_stream_atom (CamelIMAPXInputStream *is,
                               guchar **data,
                               guint *lenp,
                               GCancellable *cancellable,
                               GError **error)
{
	camel_imapx_token_t tok;
	guchar *p, c;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is), FALSE);
	g_return_val_if_fail (data != NULL, FALSE);
	g_return_val_if_fail (lenp != NULL, FALSE);

	/* this is only 'approximate' atom */
	tok = camel_imapx_input_stream_token (is, data, lenp, cancellable, error);

	switch (tok) {
		case IMAPX_TOK_ERROR:
			return FALSE;

		case IMAPX_TOK_TOKEN:
			p = *data;
			while ((c = *p))
				*p++ = toupper(c);
			return TRUE;

		case IMAPX_TOK_INT:
			return TRUE;

		default:
			g_set_error (
				error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
				"expecting atom");
			return FALSE;
	}
}

/* gets an atom, a quoted_string, or a literal */
gboolean
camel_imapx_input_stream_astring (CamelIMAPXInputStream *is,
                                  guchar **data,
                                  GCancellable *cancellable,
                                  GError **error)
{
	camel_imapx_token_t tok;
	guchar *p, *e, *start, c;
	guint len, inlen;
	gint ret;

	g_return_val_if_fail (CAMEL_IMAPX_INPUT_STREAM (is), FALSE);
	g_return_val_if_fail (data != NULL, FALSE);

	p = is->priv->ptr;
	e = is->priv->end;

	if (is->priv->unget) {
		tok = camel_imapx_input_stream_token (is, data, &len, cancellable, error);
	} else {
		/* skip whitespace/prefill buffer */
		do {
			while (p >= e ) {
				is->priv->ptr = p;
				if (imapx_input_stream_fill (is, cancellable, error) == IMAPX_TOK_ERROR)
					return FALSE;
				p = is->priv->ptr;
				e = is->priv->end;
			}
			c = *p++;
		} while (c == ' ' || c == '\r');

		if (c == '\"' || c == '{') {
			tok = camel_imapx_input_stream_token (is, data, &len, cancellable, error);
		} else {
			guchar *o, *oe;

			tok = IMAPX_TOK_STRING;

			/* <any %x01-7F except "(){ " / %x00-1F / %x7F > */
			o = is->priv->tokenbuf;
			oe = is->priv->tokenbuf + is->priv->bufsize - 1;
			*o++ = c;
			while (1) {
				while (p < e) {
					c = *p++;
					if (c <= 0x1f || c == 0x7f || c == '(' || c == ')' || c == '{' || c == ' ') {
						if (c == ' ' || c == '\r')
							is->priv->ptr = p;
						else
							is->priv->ptr = p - 1;
						*o = 0;
						*data = is->priv->tokenbuf;
						return TRUE;
					}

					if (o >= oe) {
						camel_imapx_input_stream_grow (is, 0, &p, &o);
						oe = is->priv->tokenbuf + is->priv->bufsize - 1;
						e = is->priv->end;
					}
					*o++ = c;
				}
				is->priv->ptr = p;
				if (imapx_input_stream_fill (is, cancellable, error) == IMAPX_TOK_ERROR)
					return FALSE;
				p = is->priv->ptr;
				e = is->priv->end;
			}
		}
	}

	switch (tok) {
		case IMAPX_TOK_ERROR:
			return FALSE;

		case IMAPX_TOK_TOKEN:
		case IMAPX_TOK_STRING:
		case IMAPX_TOK_INT:
			return TRUE;

		case IMAPX_TOK_LITERAL:
			if (len >= is->priv->bufsize)
				camel_imapx_input_stream_grow (is, len, NULL, NULL);
			p = is->priv->tokenbuf;
			camel_imapx_input_stream_set_literal (is, len);
			do {
				ret = camel_imapx_input_stream_getl (
					is, &start, &inlen, cancellable, error);
				if (ret < 0)
					return FALSE;
				memcpy (p, start, inlen);
				p += inlen;
			} while (ret > 0);
			*p = 0;
			*data = is->priv->tokenbuf;
			return TRUE;

		default:
			g_set_error (
				error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
				"expecting astring");
			return FALSE;
	}
}

/* check for NIL or (small) quoted_string or literal */
gboolean
camel_imapx_input_stream_nstring (CamelIMAPXInputStream *is,
                                  guchar **data,
                                  GCancellable *cancellable,
                                  GError **error)
{
	camel_imapx_token_t tok;
	guchar *p, *start;
	guint len, inlen;
	gint ret;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is), FALSE);
	g_return_val_if_fail (data != NULL, FALSE);

	tok = camel_imapx_input_stream_token (is, data, &len, cancellable, error);

	switch (tok) {
		case IMAPX_TOK_ERROR:
			return FALSE;

		case IMAPX_TOK_STRING:
			return TRUE;

		case IMAPX_TOK_LITERAL:
			if (len >= is->priv->bufsize)
				camel_imapx_input_stream_grow (is, len, NULL, NULL);
			p = is->priv->tokenbuf;
			camel_imapx_input_stream_set_literal (is, len);
			do {
				ret = camel_imapx_input_stream_getl (
					is, &start, &inlen, cancellable, error);
				if (ret < 0)
					return FALSE;
				memcpy (p, start, inlen);
				p += inlen;
			} while (ret > 0);
			*p = 0;
			*data = is->priv->tokenbuf;
			return TRUE;

		case IMAPX_TOK_TOKEN:
			p = *data;
			if (toupper (p[0]) == 'N' &&
			    toupper (p[1]) == 'I' &&
			    toupper (p[2]) == 'L' &&
			    p[3] == 0) {
				*data = NULL;
				return TRUE;
			}
			/* fall through */

		default:
			g_set_error (
				error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
				"expecting nstring");
			return FALSE;
	}
}

/* parse an nstring as a GBytes */
gboolean
camel_imapx_input_stream_nstring_bytes (CamelIMAPXInputStream *is,
                                        GBytes **out_bytes,
					gboolean with_progress,
                                        GCancellable *cancellable,
                                        GError **error)
{
	camel_imapx_token_t tok;
	guchar *token;
	guint len;
	GOutputStream *output_stream;
	gssize bytes_written;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is), FALSE);
	g_return_val_if_fail (out_bytes != NULL, FALSE);

	*out_bytes = NULL;

	tok = camel_imapx_input_stream_token (
		is, &token, &len, cancellable, error);

	switch (tok) {
		case IMAPX_TOK_ERROR:
			return FALSE;

		case IMAPX_TOK_STRING:
			*out_bytes = g_bytes_new (token, len);
			return TRUE;

		case IMAPX_TOK_LITERAL:
			/* If len is big, we could
			 * automatically use a file backing. */
			camel_imapx_input_stream_set_literal (is, len);
			output_stream = g_memory_output_stream_new_resizable ();
			if (with_progress && len > 1024) {
				bytes_written = imapx_splice_with_progress (output_stream, G_INPUT_STREAM (is),
					len, cancellable, error);
				if (!g_output_stream_close (output_stream, cancellable, error))
					bytes_written = -1;
			} else {
				bytes_written = g_output_stream_splice (output_stream, G_INPUT_STREAM (is),
					G_OUTPUT_STREAM_SPLICE_CLOSE_TARGET, cancellable, error);
			}
			success = (bytes_written >= 0);
			if (success) {
				*out_bytes =
					g_memory_output_stream_steal_as_bytes (
					G_MEMORY_OUTPUT_STREAM (output_stream));
			}
			g_object_unref (output_stream);
			return success;

		case IMAPX_TOK_TOKEN:
			if (toupper (token[0]) == 'N' &&
			    toupper (token[1]) == 'I' &&
			    toupper (token[2]) == 'L' &&
			    token[3] == 0) {
				*out_bytes = NULL;
				return TRUE;
			}
			/* fall through */

		default:
			g_set_error (
				error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
				"nstring: token not string");
			return FALSE;
	}
}

gboolean
camel_imapx_input_stream_number (CamelIMAPXInputStream *is,
                                 guint64 *number,
                                 GCancellable *cancellable,
                                 GError **error)
{
	camel_imapx_token_t tok;
	guchar *token;
	guint len;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is), FALSE);
	g_return_val_if_fail (number != NULL, FALSE);

	tok = camel_imapx_input_stream_token (
		is, &token, &len, cancellable, error);

	switch (tok) {
		case IMAPX_TOK_ERROR:
			return FALSE;

		case IMAPX_TOK_INT:
			*number = g_ascii_strtoull ((gchar *) token, 0, 10);
			return TRUE;

		default:
			g_set_error (
				error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED,
				"expecting number");
			return FALSE;
	}
}

gboolean
camel_imapx_input_stream_text (CamelIMAPXInputStream *is,
                               guchar **text,
                               GCancellable *cancellable,
                               GError **error)
{
	GByteArray *build = g_byte_array_new ();
	guchar *token;
	guint len;
	gint tok;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is), FALSE);
	g_return_val_if_fail (text != NULL, FALSE);

	while (is->priv->unget > 0) {
		switch (is->priv->unget_tok) {
			case IMAPX_TOK_TOKEN:
			case IMAPX_TOK_STRING:
			case IMAPX_TOK_INT:
				g_byte_array_append (
					build, (guint8 *)
					is->priv->unget_token,
					is->priv->unget_len);
				g_byte_array_append (
					build, (guint8 *) " ", 1);
			default: /* invalid, but we'll ignore */
				break;
		}
		is->priv->unget--;
	}

	do {
		tok = camel_imapx_input_stream_gets (
			is, &token, &len, cancellable, error);
		if (tok < 0) {
			*text = NULL;
			g_byte_array_free (build, TRUE);
			return FALSE;
		}
		if (len)
			g_byte_array_append (build, token, len);
	} while (tok > 0);

	g_byte_array_append (build, (guint8 *) "", 1);
	*text = build->data;
	g_byte_array_free (build, FALSE);

	return TRUE;
}

/* Get one token from the imap stream */
camel_imapx_token_t
camel_imapx_input_stream_token (CamelIMAPXInputStream *is,
                                guchar **data,
                                guint *len,
                                GCancellable *cancellable,
                                GError **error)
{
	register guchar c, *oe;
	guchar *o, *p, *e;
	guint literal;
	gint digits;
	gboolean is_literal8 = FALSE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is), IMAPX_TOK_ERROR);
	g_return_val_if_fail (data != NULL, IMAPX_TOK_ERROR);
	g_return_val_if_fail (len != NULL, IMAPX_TOK_ERROR);

	if (is->priv->unget > 0) {
		is->priv->unget--;
		*data = is->priv->unget_token;
		*len = is->priv->unget_len;
		return is->priv->unget_tok;
	}

	*data = NULL;
	*len = 0;

	if (is->priv->literal > 0 && !g_cancellable_is_cancelled (cancellable))
		g_warning (
			"stream_token called with literal %d",
			is->priv->literal);

	p = is->priv->ptr;
	e = is->priv->end;

	/* skip whitespace/prefill buffer */
	do {
		while (p >= e ) {
			is->priv->ptr = p;
			if (imapx_input_stream_fill (is, cancellable, error) == IMAPX_TOK_ERROR)
				return IMAPX_TOK_ERROR;
			p = is->priv->ptr;
			e = is->priv->end;
		}
		c = *p++;
	} while (c == ' ' || c == '\r');

	if (c == '~') {
		if (p >= e) {
			is->priv->ptr = p;
			if (imapx_input_stream_fill (is, cancellable, error) == IMAPX_TOK_ERROR)
				return IMAPX_TOK_ERROR;
			p = is->priv->ptr;
			e = is->priv->end;
		}

		if (*p == '{') {
			c = *p++;
			is_literal8 = TRUE;
		}
	}

	/*strchr("\n*()[]+", c)*/
	if (imapx_is_token_char (c)) {
		is->priv->ptr = p;
		return c;
	} else if (c == '{') {
		literal = 0;
		*data = p;
		while (1) {
			while (p < e) {
				c = *p++;
				if (isdigit (c) && literal < (UINT_MAX / 10)) {
					literal = literal * 10 + (c - '0');
				} else if (is_literal8 && c == '+') {
					if (p >= e) {
						is->priv->ptr = p;
						if (imapx_input_stream_fill (is, cancellable, error) == IMAPX_TOK_ERROR)
							return IMAPX_TOK_ERROR;
						p = is->priv->ptr;
						e = is->priv->end;
					}

					/* The '+' can be only at the end of the literal8 token */
					if (*p != '}')
						goto protocol_error;
				} else if (c == '}') {
					while (1) {
						while (p < e) {
							c = *p++;
							if (c == '\n') {
								*len = literal;
								is->priv->ptr = p;
								is->priv->literal = literal;
								return IMAPX_TOK_LITERAL;
							}
						}
						is->priv->ptr = p;
						if (imapx_input_stream_fill (is, cancellable, error) == IMAPX_TOK_ERROR)
							return IMAPX_TOK_ERROR;
						p = is->priv->ptr;
						e = is->priv->end;
					}
				} else {
					goto protocol_error;
				}
			}
			is->priv->ptr = p;
			if (imapx_input_stream_fill (is, cancellable, error) == IMAPX_TOK_ERROR)
				return IMAPX_TOK_ERROR;
			p = is->priv->ptr;
			e = is->priv->end;
		}
	} else if (c == '"') {
		o = is->priv->tokenbuf;
		oe = is->priv->tokenbuf + is->priv->bufsize - 1;
		while (1) {
			while (p < e) {
				c = *p++;
				if (c == '\\') {
					while (p >= e) {
						is->priv->ptr = p;
						if (imapx_input_stream_fill (is, cancellable, error) == IMAPX_TOK_ERROR)
							return IMAPX_TOK_ERROR;
						p = is->priv->ptr;
						e = is->priv->end;
					}
					c = *p++;
				} else if (c == '\"') {
					is->priv->ptr = p;
					*o = 0;
					*data = is->priv->tokenbuf;
					*len = o - is->priv->tokenbuf;
					return IMAPX_TOK_STRING;
				}
				if (o >= oe) {
					camel_imapx_input_stream_grow (is, 0, &p, &o);
					oe = is->priv->tokenbuf + is->priv->bufsize - 1;
					e = is->priv->end;
				}
				*o++ = c;
			}
			is->priv->ptr = p;
			if (imapx_input_stream_fill (is, cancellable, error) == IMAPX_TOK_ERROR)
				return IMAPX_TOK_ERROR;
			p = is->priv->ptr;
			e = is->priv->end;
		}
	} else {
		o = is->priv->tokenbuf;
		oe = is->priv->tokenbuf + is->priv->bufsize - 1;
		digits = isdigit (c);
		*o++ = c;
		while (1) {
			while (p < e) {
				c = *p++;
				/*if (strchr(" \r\n*()[]+", c) != NULL) {*/
				if (imapx_is_notid_char (c)) {
					if (c == ' ' || c == '\r')
						is->priv->ptr = p;
					else
						is->priv->ptr = p - 1;
					*o = 0;
					*data = is->priv->tokenbuf;
					*len = o - is->priv->tokenbuf;
					return digits ? IMAPX_TOK_INT : IMAPX_TOK_TOKEN;
				}

				if (o >= oe) {
					camel_imapx_input_stream_grow (is, 0, &p, &o);
					oe = is->priv->tokenbuf + is->priv->bufsize - 1;
					e = is->priv->end;
				}
				digits &= isdigit (c);
				*o++ = c;
			}
			is->priv->ptr = p;
			if (imapx_input_stream_fill (is, cancellable, error) == IMAPX_TOK_ERROR)
				return IMAPX_TOK_ERROR;
			p = is->priv->ptr;
			e = is->priv->end;
		}
	}

protocol_error:

	/* Protocol error, skip until next lf? */
	if (c == '\n')
		is->priv->ptr = p - 1;
	else
		is->priv->ptr = p;

	g_set_error (error, CAMEL_IMAPX_ERROR, CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED, "protocol error");

	return IMAPX_TOK_ERROR;
}

void
camel_imapx_input_stream_ungettoken (CamelIMAPXInputStream *is,
                                     camel_imapx_token_t tok,
                                     guchar *token,
                                     guint len)
{
	g_return_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is));

	is->priv->unget_tok = tok;
	is->priv->unget_token = token;
	is->priv->unget_len = len;
	is->priv->unget++;
}

/* returns -1 on error, 0 if last lot of data, >0 if more remaining */
gint
camel_imapx_input_stream_gets (CamelIMAPXInputStream *is,
                               guchar **start,
                               guint *len,
                               GCancellable *cancellable,
                               GError **error)
{
	gint max;
	guchar *end;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is), -1);
	g_return_val_if_fail (start != NULL, -1);
	g_return_val_if_fail (len != NULL, -1);

	*len = 0;

	max = is->priv->end - is->priv->ptr;
	if (max == 0) {
		max = imapx_input_stream_fill (is, cancellable, error);
		if (max <= 0)
			return max;
	}

	*start = is->priv->ptr;
	end = memchr (is->priv->ptr, '\n', max);
	if (end)
		max = (end - is->priv->ptr) + 1;
	*start = is->priv->ptr;
	*len = max;
	is->priv->ptr += max;

	return end == NULL ? 1 : 0;
}

void
camel_imapx_input_stream_set_literal (CamelIMAPXInputStream *is,
                                      guint literal)
{
	g_return_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is));

	is->priv->literal = literal;
}

/* returns -1 on erorr, 0 if last data, >0 if more data left */
gint
camel_imapx_input_stream_getl (CamelIMAPXInputStream *is,
                               guchar **start,
                               guint *len,
                               GCancellable *cancellable,
                               GError **error)
{
	gint max;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is), -1);
	g_return_val_if_fail (start != NULL, -1);
	g_return_val_if_fail (len != NULL, -1);

	*len = 0;

	if (is->priv->literal > 0) {
		max = is->priv->end - is->priv->ptr;
		if (max == 0) {
			max = imapx_input_stream_fill (is, cancellable, error);
			if (max <= 0)
				return max;
		}

		max = MIN (max, is->priv->literal);
		*start = is->priv->ptr;
		*len = max;
		is->priv->ptr += max;
		is->priv->literal -= max;
	}

	if (is->priv->literal > 0)
		return 1;

	return 0;
}

/* skip the rest of the line of tokens */
gboolean
camel_imapx_input_stream_skip (CamelIMAPXInputStream *is,
                               GCancellable *cancellable,
                               GError **error)
{
	camel_imapx_token_t tok;
	guchar *token;
	guint len;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is), FALSE);

	do {
		tok = camel_imapx_input_stream_token (
			is, &token, &len, cancellable, error);

		if (tok == IMAPX_TOK_ERROR)
			return FALSE;

		if (tok == IMAPX_TOK_LITERAL) {
			camel_imapx_input_stream_set_literal (is, len);
			do {
				tok = camel_imapx_input_stream_getl (
					is, &token, &len, cancellable, error);
			} while (tok > 0);
		}
	} while (tok != '\n' && tok >= 0);

	return (tok != IMAPX_TOK_ERROR);
}

gboolean
camel_imapx_input_stream_skip_until (CamelIMAPXInputStream *is,
                                     const gchar *delimiters,
                                     GCancellable *cancellable,
                                     GError **error)
{
	register guchar c;
	guchar *p, *e;

	g_return_val_if_fail (CAMEL_IS_IMAPX_INPUT_STREAM (is), FALSE);

	if (is->priv->unget > 0) {
		is->priv->unget--;
		return TRUE;
	}

	if (is->priv->literal > 0) {
		is->priv->literal--;
		return TRUE;
	}

	p = is->priv->ptr;
	e = is->priv->end;

	do {
		while (p >= e ) {
			is->priv->ptr = p;
			if (imapx_input_stream_fill (is, cancellable, error) == IMAPX_TOK_ERROR)
				return FALSE;
			p = is->priv->ptr;
			e = is->priv->end;
		}
		c = *p++;
	} while (c && c != ' ' && c != '\r' && c != '\n' && (!delimiters || !strchr (delimiters, c)));

	is->priv->ptr = p;

	return TRUE;
}
