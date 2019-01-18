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

/* This is *identical* to the camel-nntp-stream, so should probably
 * work out a way to merge them */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <string.h>
#include <errno.h>

#include "camel-pop3-stream.h"

#define dd(x) (camel_debug ("pop3")?(x):0)

#define CAMEL_POP3_STREAM_SIZE (4096)
#define CAMEL_POP3_STREAM_LINE_SIZE (1024) /* maximum line size */

G_DEFINE_TYPE (CamelPOP3Stream, camel_pop3_stream, CAMEL_TYPE_STREAM)

static void
pop3_stream_dispose (GObject *object)
{
	CamelPOP3Stream *stream = CAMEL_POP3_STREAM (object);

	if (stream->source != NULL) {
		g_object_unref (stream->source);
		stream->source = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_pop3_stream_parent_class)->dispose (object);
}

static void
pop3_stream_finalize (GObject *object)
{
	CamelPOP3Stream *stream = CAMEL_POP3_STREAM (object);

	g_free (stream->buf);
	g_free (stream->linebuf);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_pop3_stream_parent_class)->finalize (object);
}

static gint
stream_fill (CamelPOP3Stream *is,
             GCancellable *cancellable,
             GError **error)
{
	gint left = 0;
	GError *local_error = NULL;

	if (is->source) {
		left = is->end - is->ptr;
		memmove (is->buf, is->ptr, left);
		is->end = is->buf + left;
		is->ptr = is->buf;
		left = camel_stream_read (
			is->source, (gchar *) is->end,
			CAMEL_POP3_STREAM_SIZE - (is->end - is->buf),
			cancellable, &local_error);

		/* It's the End Of Stream marker */
		if (left == 0 && !local_error) {
			g_set_error_literal (error, G_IO_ERROR, G_IO_ERROR_BROKEN_PIPE,
				g_strerror (
					#ifdef EPIPE
					EPIPE
					#else
					32 /* Also EPIPE; it should be always available, but just in case it isn't */
					#endif
				));
		} else if (local_error) {
			g_propagate_error (error, local_error);
			left = 0;
		}

		if (left > 0) {
			is->end += left;
			is->end[0] = '\n';
			return is->end - is->ptr;
		} else
			return -1;
	}

	return 0;
}

static gssize
stream_read (CamelStream *stream,
             gchar *buffer,
             gsize n,
             GCancellable *cancellable,
             GError **error)
{
	CamelPOP3Stream *is = (CamelPOP3Stream *) stream;
	gchar *o, *oe;
	guchar *p, *e, c;
	gint state;

	if (is->mode != CAMEL_POP3_STREAM_DATA || n == 0)
		return 0;

	o = buffer;
	oe = buffer + n;
	state = is->state;

	/* Need to copy/strip '.'s and whatnot */
	p = is->ptr;
	e = is->end;

	switch (state) {
	state_0:
	case 0:		/* start of line, always read at least 3 chars */
		while (e - p < 3) {
			is->ptr = p;
			if (stream_fill (is, cancellable, error) == -1)
				return -1;
			p = is->ptr;
			e = is->end;
		}
		if (p[0] == '.') {
			if (p[1] == '\r' && p[2] == '\n') {
				is->ptr = p + 3;
				is->mode = CAMEL_POP3_STREAM_EOD;
				is->state = 0;
				return o - buffer;
			}
			p++;
		}
		state = 1;
		/* FALLS THROUGH */
	case 1:		/* looking for next sol */
		while (o < oe) {
			c = *p++;
			if (c == '\n') {
				/* end of input sentinal check */
				if (p > e) {
					is->ptr = e;
					if (stream_fill (is, cancellable, error) == -1)
						return -1;
					p = is->ptr;
					e = is->end;
				} else {
					*o++ = '\n';
					state = 0;
					goto state_0;
				}
			} else if (c != '\r') {
				*o++ = c;
			}
		}
		break;
	}

	is->ptr = p;
	is->state = state;

	return o - buffer;
}

static gssize
stream_write (CamelStream *stream,
              const gchar *buffer,
              gsize n,
              GCancellable *cancellable,
              GError **error)
{
	CamelPOP3Stream *is = (CamelPOP3Stream *) stream;

	if (strncmp (buffer, "PASS ", 5) != 0)
		dd (printf ("POP3_STREAM_WRITE (%d):\n%.*s\n", (gint) n, (gint) n, buffer));
	else
		dd (printf ("POP3_STREAM_WRITE (%d):\nPASS xxxxxxxx\n", (gint) n));

	return camel_stream_write (is->source, buffer, n, cancellable, error);
}

static gint
stream_close (CamelStream *stream,
              GCancellable *cancellable,
              GError **error)
{
	/* nop? */
	return 0;
}

static gint
stream_flush (CamelStream *stream,
              GCancellable *cancellable,
              GError **error)
{
	/* nop? */
	return 0;
}

static gboolean
stream_eos (CamelStream *stream)
{
	CamelPOP3Stream *is = (CamelPOP3Stream *) stream;

	return is->mode != CAMEL_POP3_STREAM_DATA;
}

static void
camel_pop3_stream_class_init (CamelPOP3StreamClass *class)
{
	GObjectClass *object_class;
	CamelStreamClass *stream_class;

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = pop3_stream_dispose;
	object_class->finalize = pop3_stream_finalize;

	stream_class = CAMEL_STREAM_CLASS (class);
	stream_class->read = stream_read;
	stream_class->write = stream_write;
	stream_class->close = stream_close;
	stream_class->flush = stream_flush;
	stream_class->eos = stream_eos;
}

static void
camel_pop3_stream_init (CamelPOP3Stream *is)
{
	/* +1 is room for appending a 0 if we need to for a line */
	is->ptr = is->end = is->buf = g_malloc (CAMEL_POP3_STREAM_SIZE + 1);
	is->lineptr = is->linebuf = g_malloc (CAMEL_POP3_STREAM_LINE_SIZE + 1);
	is->lineend = is->linebuf + CAMEL_POP3_STREAM_LINE_SIZE;

	/* init sentinal */
	is->ptr[0] = '\n';

	is->state = 0;
	is->mode = CAMEL_POP3_STREAM_LINE;
}

/**
 * camel_pop3_stream_new:
 * @source: a #CamelStream to operate on
 *
 * Creates a new #CamelPOP3Stream which operates on the @source.
 * The @source stream is referenced for later use.
 *
 * Returns: (transfer full): a new #CamelPOP3Stream
 **/
CamelStream *
camel_pop3_stream_new (CamelStream *source)
{
	CamelPOP3Stream *is;

	is = g_object_new (CAMEL_TYPE_POP3_STREAM, NULL);
	is->source = g_object_ref (source);

	return (CamelStream *) is;
}

/* Get one line from the pop3 stream */
gint
camel_pop3_stream_line (CamelPOP3Stream *is,
                        guchar **data,
                        guint *len,
                        GCancellable *cancellable,
                        GError **error)
{
	register guchar c, *p, *o, *oe;
	gint newlen, oldlen;
	guchar *e;

	if (is->mode == CAMEL_POP3_STREAM_EOD) {
		*data = is->linebuf;
		*len = 0;
		return 0;
	}

	o = is->linebuf;
	oe = is->lineend - 1;
	p = is->ptr;
	e = is->end;

	/* Data mode, convert leading '..' to '.',
	 * and stop when we reach a solitary '.' */
	if (is->mode == CAMEL_POP3_STREAM_DATA) {
		/* need at least 3 chars in buffer */
		while (e - p < 3) {
			is->ptr = p;
			if (stream_fill (is, cancellable, error) == -1)
				return -1;
			p = is->ptr;
			e = is->end;
		}

		/* check for isolated '.\r\n' or begging of line '.' */
		if (p[0] == '.') {
			if (p[1] == '\r' && p[2] == '\n') {
				is->ptr = p + 3;
				is->mode = CAMEL_POP3_STREAM_EOD;
				*data = is->linebuf;
				*len = 0;
				is->linebuf[0] = 0;

				dd (printf ("POP3_STREAM_LINE (END)\n"));

				return 0;
			}
			p++;
		}
	}

	while (1) {
		while (o < oe) {
			c = *p++;
			if (c == '\n') {
				/* sentinal? */
				if (p> e) {
					is->ptr = e;
					if (stream_fill (is, cancellable, error) == -1)
						return -1;
					p = is->ptr;
					e = is->end;
				} else {
					is->ptr = p;
					*data = is->linebuf;
					*len = o - is->linebuf;
					*o = 0;

					dd (printf ("POP3_STREAM_LINE (%d): '%s'\n", *len, *data));

					return 1;
				}
			} else if (c != '\r') {
				*o++ = c;
			}
		}

		/* limit this for bad server data? */
		oldlen = o - is->linebuf;
		newlen = (is->lineend - is->linebuf) * 3 / 2;
		is->lineptr = is->linebuf = g_realloc (is->linebuf, newlen);
		is->lineend = is->linebuf + newlen;
		oe = is->lineend - 1;
		o = is->linebuf + oldlen;
	}

	return -1;
}

void
camel_pop3_stream_set_mode (CamelPOP3Stream *is,
                            camel_pop3_stream_mode_t mode)
{
	is->mode = mode;
}

/* returns -1 on erorr, 0 if last data, >0 if more data left */
gint
camel_pop3_stream_getd (CamelPOP3Stream *is,
                        guchar **start,
                        guint *len,
                        GCancellable *cancellable,
                        GError **error)
{
	guchar *p, *e, *s;
	gint state;

	*len = 0;

	if (is->mode == CAMEL_POP3_STREAM_EOD)
		return 0;

	if (is->mode == CAMEL_POP3_STREAM_LINE) {
		g_warning ("pop3_stream reading data in line mode\n");
		return 0;
	}

	state = is->state;
	p = is->ptr;
	e = is->end;

	while (e - p < 3) {
		is->ptr = p;
		if (stream_fill (is, cancellable, error) == -1)
			return -1;
		p = is->ptr;
		e = is->end;
	}

	s = p;

	do {
		switch (state) {
		case 0:
			/* check leading '.', ... */
			if (p[0] == '.') {
				if (p[1] == '\r' && p[2] == '\n') {
					is->ptr = p + 3;
					*len = p-s;
					*start = s;
					is->mode = CAMEL_POP3_STREAM_EOD;
					is->state = 0;

					return 0;
				}

				/* If at start, just skip '.', else
				 * return data upto '.' but skip it. */
				if (p == s) {
					s++;
					p++;
				} else {
					is->ptr = p + 1;
					*len = p-s;
					*start = s;
					is->state = 1;

					return 1;
				}
			}
			state = 1;
			break;
		case 1:
			/* Scan for sentinal */
			while ((*p++) != '\n')
				;

			if (p > e) {
				p = e;
			} else {
				state = 0;
			}
			break;
		}
	} while ((e - p) >= 3);

	is->state = state;
	is->ptr = p;
	*len = p-s;
	*start = s;

	return 1;
}
