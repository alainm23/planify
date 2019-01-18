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
 *          Jeffrey Stedfast <fejj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/param.h>  /* for MAXHOSTNAMELEN */
#include <sys/stat.h>
#include <unistd.h>
#include <regex.h>
#include <fcntl.h>
#include <errno.h>
#include <ctype.h>
#include <time.h>

#ifndef MAXHOSTNAMELEN
#define MAXHOSTNAMELEN 1024
#endif

#include "camel-charset-map.h"
#include "camel-iconv.h"
#include "camel-mime-utils.h"
#include "camel-net-utils.h"
#include "camel-string-utils.h"
#ifdef G_OS_WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#ifdef HAVE_WSPIAPI_H
#include <wspiapi.h>
#endif
#endif
#include "camel-utf8.h"

#ifdef G_OS_WIN32
#ifdef gmtime_r
#undef gmtime_r
#endif

/* The gmtime() in Microsoft's C library is MT-safe */
#define gmtime_r(tp,tmp) (gmtime(tp)?(*(tmp)=*gmtime(tp),(tmp)):0)
#endif

#if !defined HAVE_LOCALTIME_R && !defined localtime_r
# ifdef _LIBC
#  define localtime_r __localtime_r
# else
/* Approximate localtime_r as best we can in its absence.  */
#  define localtime_r my_localtime_r
static struct tm *localtime_r (const time_t *, struct tm *);
static struct tm *
localtime_r (t,
             tp)
	const time_t *t;
	struct tm *tp;
{
	struct tm *l = localtime (t);
	if (!l)
		return 0;
	*tp = *l;
	return tp;
}
# endif /* !_LIBC */
#endif /* HAVE_LOCALTIME_R && !defined (localtime_r) */

/* for all non-essential warnings ... */
#define w(x)

#define d(x)
#define d2(x)

G_DEFINE_BOXED_TYPE (CamelContentType,
		camel_content_type,
		camel_content_type_ref,
		camel_content_type_unref)

G_DEFINE_BOXED_TYPE (CamelContentDisposition,
		camel_content_disposition,
		camel_content_disposition_ref,
		camel_content_disposition_unref)

G_DEFINE_BOXED_TYPE (CamelHeaderAddress,
		camel_header_address,
		camel_header_address_ref,
		camel_header_address_unref)

/**
 * camel_mktime_utc:
 * @tm: the #tm to convert to a calendar time representation
 *
 * Like mktime(3), but assumes UTC instead of local timezone.
 *
 * Returns: the calendar time representation of @tm
 *
 * Since: 3.4
 **/
time_t
camel_mktime_utc (struct tm *tm)
{
	time_t tt;

	tm->tm_isdst = -1;
	tt = mktime (tm);

#if defined (HAVE_TM_GMTOFF)
	tt += tm->tm_gmtoff;
#elif defined (HAVE_TIMEZONE)
	if (tm->tm_isdst > 0) {
#if defined (HAVE_ALTZONE)
		tt -= altzone;
#else
		tt -= (timezone - 3600);
#endif
	} else
		tt -= timezone;
#endif

	return tt;
}

/**
 * camel_localtime_with_offset:
 * @tt: the #time_t to convert
 * @tm: the #tm to store the result in
 * @offset: the #gint to store the offset in
 *
 * Converts the calendar time representation @tt to a broken-down
 * time representation, stored in @tm, and provides the offset in
 * seconds from UTC time, stored in @offset.
 **/
void
camel_localtime_with_offset (time_t tt,
                             struct tm *tm,
                             gint *offset)
{
	localtime_r (&tt, tm);

#if defined (HAVE_TM_GMTOFF)
	*offset = tm->tm_gmtoff;
#elif defined (HAVE_TIMEZONE)
	if (tm->tm_isdst > 0) {
#if defined (HAVE_ALTZONE)
		*offset = -altzone;
#else
		*offset = -(timezone - 3600);
#endif
	} else
		*offset = -timezone;
#endif
}

#define CAMEL_UUENCODE_CHAR(c)  ((c) ? (c) + ' ' : '`')
#define	CAMEL_UUDECODE_CHAR(c)	(((c) - ' ') & 077)

static const guchar tohex[16] = {
	'0', '1', '2', '3', '4', '5', '6', '7',
	'8', '9', 'A', 'B', 'C', 'D', 'E', 'F'
};

/**
 * camel_uuencode_close:
 * @in: (array length=len): input stream
 * @len: input stream length
 * @out: (inout) (array): output stream
 * @uubuf: (inout) (array fixed-size=60): temporary buffer of 60 bytes
 * @state: (inout): holds the number of bits that are stored in @save
 * @save: (inout) (array length=state): leftover bits that have not yet been encoded
 *
 * Uuencodes a chunk of data. Call this when finished encoding data
 * with camel_uuencode_step() to flush off the last little bit.
 *
 * Returns: the number of bytes encoded
 **/
gsize
camel_uuencode_close (guchar *in,
                      gsize len,
                      guchar *out,
                      guchar *uubuf,
                      gint *state,
                      guint32 *save)
{
	register guchar *outptr, *bufptr;
	register guint32 saved;
	gint uulen, uufill, i;

	outptr = out;

	if (len > 0)
		outptr += camel_uuencode_step (in, len, out, uubuf, state, save);

	uufill = 0;

	saved = *save;
	i = *state & 0xff;
	uulen = (*state >> 8) & 0xff;

	bufptr = uubuf + ((uulen / 3) * 4);

	if (i > 0) {
		while (i < 3) {
			saved <<= 8;
			uufill++;
			i++;
		}

		if (i == 3) {
			/* convert 3 normal bytes into 4 uuencoded bytes */
			guchar b0, b1, b2;

			b0 = (saved >> 16) & 0xff;
			b1 = (saved >> 8) & 0xff;
			b2 = saved & 0xff;

			*bufptr++ = CAMEL_UUENCODE_CHAR ((b0 >> 2) & 0x3f);
			*bufptr++ = CAMEL_UUENCODE_CHAR (((b0 << 4) | ((b1 >> 4) & 0xf)) & 0x3f);
			*bufptr++ = CAMEL_UUENCODE_CHAR (((b1 << 2) | ((b2 >> 6) & 0x3)) & 0x3f);
			*bufptr++ = CAMEL_UUENCODE_CHAR (b2 & 0x3f);

			i = 0;
			saved = 0;
			uulen += 3;
		}
	}

	if (uulen > 0) {
		gint cplen = ((uulen / 3) * 4);

		*outptr++ = CAMEL_UUENCODE_CHAR ((uulen - uufill) & 0xff);
		memcpy (outptr, uubuf, cplen);
		outptr += cplen;
		*outptr++ = '\n';
		uulen = 0;
	}

	*outptr++ = CAMEL_UUENCODE_CHAR (uulen & 0xff);
	*outptr++ = '\n';

	*save = 0;
	*state = 0;

	return outptr - out;
}

/**
 * camel_uuencode_step:
 * @in: (array length=len): input stream
 * @len: input stream length
 * @out: (inout) (array): output stream
 * @uubuf: (inout) (array fixed-size=60): temporary buffer of 60 bytes
 * @state: (inout): holds the number of bits that are stored in @save
 * @save: (inout) (array length=state): leftover bits that have not yet been encoded
 *
 * Uuencodes a chunk of data. Performs an 'encode step', only encodes
 * blocks of 45 characters to the output at a time, saves left-over
 * state in @uubuf, @state and @save (initialize to 0 on first
 * invocation).
 *
 * Returns: the number of bytes encoded
 **/
gsize
camel_uuencode_step (guchar *in,
                     gsize len,
                     guchar *out,
                     guchar *uubuf,
                     gint *state,
                     guint32 *save)
{
	register guchar *inptr, *outptr, *bufptr;
	guchar b0, b1, b2, *inend;
	register guint32 saved;
	gint uulen, i;

	if (len == 0)
		return 0;

	inend = in + len;
	outptr = out;
	inptr = in;

	saved = *save;
	i = *state & 0xff;
	uulen = (*state >> 8) & 0xff;

	if ((len + uulen) < 45) {
		/* not enough input to write a full uuencoded line */
		bufptr = uubuf + ((uulen / 3) * 4);
	} else {
		bufptr = outptr + 1;

		if (uulen > 0) {
			/* copy the previous call's tmpbuf to outbuf */
			memcpy (bufptr, uubuf, ((uulen / 3) * 4));
			bufptr += ((uulen / 3) * 4);
		}
	}

	if (i == 2) {
		b0 = (saved >> 8) & 0xff;
		b1 = saved & 0xff;
		saved = 0;
		i = 0;

		goto skip2;
	} else if (i == 1) {
		if ((inptr + 2) < inend) {
			b0 = saved & 0xff;
			saved = 0;
			i = 0;

			goto skip1;
		}

		while (inptr < inend) {
			saved = (saved << 8) | *inptr++;
			i++;
		}
	}

	while (inptr < inend) {
		while (uulen < 45 && (inptr + 3) <= inend) {
			b0 = *inptr++;
		skip1:
			b1 = *inptr++;
		skip2:
			b2 = *inptr++;

			/* convert 3 normal bytes into 4 uuencoded bytes */
			*bufptr++ = CAMEL_UUENCODE_CHAR ((b0 >> 2) & 0x3f);
			*bufptr++ = CAMEL_UUENCODE_CHAR (((b0 << 4) | ((b1 >> 4) & 0xf)) & 0x3f);
			*bufptr++ = CAMEL_UUENCODE_CHAR (((b1 << 2) | ((b2 >> 6) & 0x3)) & 0x3f);
			*bufptr++ = CAMEL_UUENCODE_CHAR (b2 & 0x3f);

			uulen += 3;
		}

		if (uulen >= 45) {
			*outptr++ = CAMEL_UUENCODE_CHAR (uulen & 0xff);
			outptr += ((45 / 3) * 4) + 1;

			*outptr++ = '\n';
			uulen = 0;

			if ((inptr + 45) <= inend) {
				/* we have enough input to output another full line */
				bufptr = outptr + 1;
			} else {
				bufptr = uubuf;
			}
		} else {
			/* not enough input to continue... */
			for (i = 0, saved = 0; inptr < inend; i++)
				saved = (saved << 8) | *inptr++;
		}
	}

	*save = saved;
	*state = ((uulen & 0xff) << 8) | (i & 0xff);

	return outptr - out;
}

/**
 * camel_uudecode_step:
 * @in: (array length=inlen): input stream
 * @inlen: max length of data to decode
 * @out: (inout) (array): output stream
 * @state: (inout): holds the number of bits that are stored in @save
 * @save: (inout) (array length=state): leftover bits that have not yet been decoded
 *
 * Uudecodes a chunk of data. Performs a 'decode step' on a chunk of
 * uuencoded data. Assumes the "begin mode filename" line has
 * been stripped off.
 *
 * Returns: the number of bytes decoded
 **/
gsize
camel_uudecode_step (guchar *in,
                     gsize len,
                     guchar *out,
                     gint *state,
                     guint32 *save)
{
	register guchar *inptr, *outptr;
	guchar *inend, ch;
	register guint32 saved;
	gboolean last_was_eoln;
	gint uulen, i;

	if (*state & CAMEL_UUDECODE_STATE_END)
		return 0;

	saved = *save;
	i = *state & 0xff;
	uulen = (*state >> 8) & 0xff;
	if (uulen == 0)
		last_was_eoln = TRUE;
	else
		last_was_eoln = FALSE;

	inend = in + len;
	outptr = out;
	inptr = in;

	while (inptr < inend) {
		if (*inptr == '\n') {
			last_was_eoln = TRUE;

			inptr++;
			continue;
		} else if (!uulen || last_was_eoln) {
			/* first octet on a line is the uulen octet */
			uulen = CAMEL_UUDECODE_CHAR (*inptr);
			last_was_eoln = FALSE;
			if (uulen == 0) {
				*state |= CAMEL_UUDECODE_STATE_END;
				break;
			}

			inptr++;
			continue;
		}

		ch = *inptr++;

		if (uulen > 0) {
			/* save the byte */
			saved = (saved << 8) | ch;
			i++;
			if (i == 4) {
				/* convert 4 uuencoded bytes to 3 normal bytes */
				guchar b0, b1, b2, b3;

				b0 = saved >> 24;
				b1 = saved >> 16 & 0xff;
				b2 = saved >> 8 & 0xff;
				b3 = saved & 0xff;

				if (uulen >= 3) {
					*outptr++ = CAMEL_UUDECODE_CHAR (b0) << 2 | CAMEL_UUDECODE_CHAR (b1) >> 4;
					*outptr++ = CAMEL_UUDECODE_CHAR (b1) << 4 | CAMEL_UUDECODE_CHAR (b2) >> 2;
					*outptr++ = CAMEL_UUDECODE_CHAR (b2) << 6 | CAMEL_UUDECODE_CHAR (b3);
					uulen -= 3;
				} else {
					gint orig_uulen = uulen;

					if (orig_uulen >= 1) {
						*outptr++ = CAMEL_UUDECODE_CHAR (b0) << 2 | CAMEL_UUDECODE_CHAR (b1) >> 4;
						uulen--;
					}

					if (orig_uulen >= 2) {
						*outptr++ = CAMEL_UUDECODE_CHAR (b1) << 4 | CAMEL_UUDECODE_CHAR (b2) >> 2;
						uulen--;
					}
				}

				i = 0;
				saved = 0;
			}
		} else {
			break;
		}
	}

	*save = saved;
	*state = (*state & CAMEL_UUDECODE_STATE_MASK) | ((uulen & 0xff) << 8) | (i & 0xff);

	return outptr - out;
}

/**
 * camel_quoted_encode_close:
 * @in: (array length=len): input stream
 * @len: length of the input
 * @out: (inout) (array): output string
 * @state: (inout): holds the number of bits that are stored in @save
 * @save: (inout) (array length=state): leftover bits that have not yet been encoded
 *
 * Quoted-printable encodes a block of text. Call this when finished
 * encoding data with camel_quoted_encode_step() to flush off
 * the last little bit.
 *
 * Returns: the number of bytes encoded
 **/
gsize
camel_quoted_encode_close (guchar *in,
                           gsize len,
                           guchar *out,
                           gint *state,
                           gint *save)
{
	register guchar *outptr = out;
	gint last;

	if (len > 0)
		outptr += camel_quoted_encode_step (in, len, outptr, state, save);

	last = *state;
	if (last != -1) {
		/* space/tab must be encoded if it's the last character on
		 * the line */
		if (camel_mime_is_qpsafe (last) && last != ' ' && last != 9) {
			*outptr++ = last;
		} else {
			*outptr++ = '=';
			*outptr++ = tohex[(last>>4) & 0xf];
			*outptr++ = tohex[last & 0xf];
		}
	}

	*save = 0;
	*state = -1;

	return outptr - out;
}

/**
 * camel_quoted_encode_step:
 * @in: (array length=len): input stream
 * @len: length of the input
 * @out: (inout) (array): output string
 * @state: (inout): holds the number of bits that are stored in @save
 * @save: (inout) (array length=state): leftover bits that have not yet been encoded
 *
 * Quoted-printable encodes a block of text. Performs an 'encode
 * step', saves left-over state in state and save (initialise to -1 on
 * first invocation).
 *
 * Returns: the number of bytes encoded
 **/
gsize
camel_quoted_encode_step (guchar *in,
                          gsize len,
                          guchar *out,
                          gint *statep,
                          gint *save)
{
	register guchar *inptr, *outptr, *inend;
	guchar c;
	register gint sofar = *save;  /* keeps track of how many chars on a line */
	register gint last = *statep; /* keeps track if last gchar to end was a space cr etc */

	#define output_last() \
		if (sofar + 3 > 74) { \
			*outptr++ = '='; \
			*outptr++ = '\n'; \
			sofar = 0; \
		} \
		*outptr++ = '='; \
		*outptr++ = tohex[(last >> 4) & 0xf]; \
		*outptr++ = tohex[last & 0xf]; \
		sofar += 3;

	inptr = in;
	inend = in + len;
	outptr = out;
	while (inptr < inend) {
		c = *inptr++;
		if (c == '\r') {
			if (last != -1) {
				output_last ();
			}
			last = c;
		} else if (c == '\n') {
			if (last != -1 && last != '\r') {
				output_last ();
			}
			*outptr++ = '\n';
			sofar = 0;
			last = -1;
		} else {
			if (last != -1) {
				if (camel_mime_is_qpsafe (last)) {
					*outptr++ = last;
					sofar++;
				} else {
					output_last ();
				}
			}

			if (camel_mime_is_qpsafe (c)) {
				if (sofar > 74) {
					*outptr++ = '=';
					*outptr++ = '\n';
					sofar = 0;
				}

				/* delay output of space gchar */
				if (c == ' ' || c == '\t') {
					last = c;
				} else {
					*outptr++ = c;
					sofar++;
					last = -1;
				}
			} else {
				if (sofar > 72) {
					*outptr++ = '=';
					*outptr++ = '\n';
					sofar = 3;
				} else
					sofar += 3;

				*outptr++ = '=';
				*outptr++ = tohex[(c >> 4) & 0xf];
				*outptr++ = tohex[c & 0xf];
				last = -1;
			}
		}
	}
	*save = sofar;
	*statep = last;

	#undef output_last

	return (outptr - out);
}

/*
 * FIXME: this does not strip trailing spaces from lines (as it should, rfc 2045, section 6.7)
 * Should it also canonicalise the end of line to CR LF??
 *
 * Note: Trailing rubbish (at the end of input), like = or =x or =\r will be lost.
 */

/**
 * camel_quoted_decode_step:
 * @in: (array length=len): input stream
 * @len: max length of data to decode
 * @out: (inout) (array): output stream
 * @savestate: (inout): holds the number of bits that are stored in @saveme
 * @saveme: (inout) (array length=savestate): leftover bits that have not yet been decoded
 *
 * Decodes a block of quoted-printable encoded data. Performs a
 * 'decode step' on a chunk of QP encoded data.
 *
 * Returns: the number of bytes decoded
 **/
gsize
camel_quoted_decode_step (guchar *in,
                          gsize len,
                          guchar *out,
                          gint *savestate,
                          gint *saveme)
{
	register guchar *inptr, *outptr;
	guchar *inend, c;
	gint state, save;

	inend = in + len;
	outptr = out;

	d (printf ("quoted-printable, decoding text '%.*s'\n", len, in));

	state = *savestate;
	save = *saveme;
	inptr = in;
	while (inptr < inend) {
		switch (state) {
		case 0:
			while (inptr < inend) {
				c = *inptr++;
				if (c == '=') {
					state = 1;
					break;
				}
#ifdef CANONICALISE_EOL
				/*else if (c=='\r') {
					state = 3;
				} else if (c == '\n') {
					*outptr++ = '\r';
					*outptr++ = c;
					} */
#endif
				else {
					*outptr++ = c;
				}
			}
			break;
		case 1:
			c = *inptr++;
			if (c == '\n') {
				/* soft break ... unix end of line */
				state = 0;
			} else {
				save = c;
				state = 2;
			}
			break;
		case 2:
			c = *inptr++;
			if (isxdigit (c) && isxdigit (save)) {
				c = toupper (c);
				save = toupper (save);
				*outptr++ = (((save>='A'?save-'A'+10:save-'0')&0x0f) << 4)
					| ((c >= 'A' ? c - 'A' + 10 : c - '0') &0x0f);
			} else if (c == '\n' && save == '\r') {
				/* soft break ... canonical end of line */
			} else {
				/* just output the data */
				*outptr++ = '=';
				*outptr++ = save;
				*outptr++ = c;
			}
			state = 0;
			break;
#ifdef CANONICALISE_EOL
		case 3:
			/* convert \r -> to \r\n, leaves \r\n alone */
			c = *inptr++;
			if (c == '\n') {
				*outptr++ = '\r';
				*outptr++ = c;
			} else {
				*outptr++ = '\r';
				*outptr++ = '\n';
				*outptr++ = c;
			}
			state = 0;
			break;
#endif
		}
	}

	*savestate = state;
	*saveme = save;

	return outptr - out;
}

/*
 * this is for the "Q" encoding of international words,
 * which is slightly different than plain quoted-printable (mainly by allowing 0x20 <> _)
*/
static gsize
quoted_decode (const guchar *in,
               gsize len,
               guchar *out)
{
	register const guchar *inptr;
	register guchar *outptr;
	const guchar *inend;
	guchar c, c1;
	gint ret = 0;

	inend = in + len;
	outptr = out;

	d (printf ("decoding text '%.*s'\n", len, in));

	inptr = in;
	while (inptr < inend) {
		c = *inptr++;
		if (c == '=') {
			/* silently ignore truncated data? */
			if (inend - in >= 2) {
				c = toupper (*inptr++);
				c1 = toupper (*inptr++);
				*outptr++ = (((c>='A'?c-'A'+10:c-'0')&0x0f) << 4)
					| ((c1 >= 'A' ? c1 - 'A' + 10 : c1 - '0') &0x0f);
			} else {
				ret = -1;
				break;
			}
		} else if (c == '_') {
			*outptr++ = 0x20;
		} else {
			*outptr++ = c;
		}
	}
	if (ret == 0) {
		return outptr - out;
	}
	return 0;
}

/* rfc2047 version of quoted-printable */
/* safemask is the mask to apply to the camel_mime_special_table to determine what
 * characters can safely be included without encoding */
static gsize
quoted_encode (const guchar *in,
               gsize len,
               guchar *out,
               gushort safemask)
{
	register const guchar *inptr, *inend;
	guchar *outptr;
	guchar c;

	inptr = in;
	inend = in + len;
	outptr = out;
	while (inptr < inend) {
		c = *inptr++;
		if (c == ' ') {
			*outptr++ = '_';
		} else if (camel_mime_special_table[c] & safemask) {
			*outptr++ = c;
		} else {
			*outptr++ = '=';
			*outptr++ = tohex[(c >> 4) & 0xf];
			*outptr++ = tohex[c & 0xf];
		}
	}

	d (printf ("encoding '%.*s' = '%.*s'\n", len, in, outptr - out, out));

	return (outptr - out);
}

static void
header_decode_lwsp (const gchar **in)
{
	const gchar *inptr = *in;
	gchar c;

	d2 (printf ("is ws: '%s'\n", *in));

	while ((camel_mime_is_lwsp (*inptr) || *inptr =='(') && *inptr != '\0') {
		while (camel_mime_is_lwsp (*inptr) && *inptr != '\0') {
			d2 (printf ("(%c)", *inptr));
			inptr++;
		}
		d2 (printf ("\n"));

		/* check for comments */
		if (*inptr == '(') {
			gint depth = 1;
			inptr++;
			while (depth && (c=*inptr) && *inptr != '\0') {
				if (c == '\\' && inptr[1]) {
					inptr++;
				} else if (c == '(') {
					depth++;
				} else if (c == ')') {
					depth--;
				}
				inptr++;
			}
		}
	}
	*in = inptr;
}

static gchar *
camel_iconv_strndup (GIConv cd,
                     const gchar *string,
                     gsize n)
{
	gsize inleft, outleft, converted = 0;
	gchar *out, *outbuf;
	const gchar *inbuf;
	gsize outlen;
	gint errnosav;

	if (cd == (GIConv) -1)
		return g_strndup (string, n);

	outlen = n * 2 + 16;
	out = g_malloc (outlen + 4);

	inbuf = string;
	inleft = n;

	do {
		errno = 0;
		outbuf = out + converted;
		outleft = outlen - converted;

		converted = g_iconv (cd, (gchar **) &inbuf, &inleft, &outbuf, &outleft);
		if (converted == (gsize) -1) {
			if (errno != E2BIG && errno != EINVAL)
				goto fail;
		}

		/*
		 * E2BIG   There is not sufficient room at *outbuf.
		 *
		 * We just need to grow our outbuffer and try again.
		 */

		converted = outbuf - out;
		if (errno == E2BIG) {
			outlen += inleft * 2 + 16;
			out = g_realloc (out, outlen + 4);
			outbuf = out + converted;
		}
	} while (errno == E2BIG && inleft > 0);

	/*
	 * EINVAL  An  incomplete  multibyte sequence has been encoun­
	 *         tered in the input.
	 *
	 * We'll just have to ignore it...
	 */

	/* flush the iconv conversion */
	while (g_iconv (cd, NULL, NULL, &outbuf, &outleft) == (gsize) -1) {
		if (errno != E2BIG)
			break;

		outlen += 16;
		converted = outbuf - out;
		out = g_realloc (out, outlen + 4);
		outleft = outlen - converted;
		outbuf = out + converted;
	}

	/* Note: not all charsets can be nul-terminated with a single
	 * nul byte. UCS2, for example, needs 2 nul bytes and UCS4
	 * needs 4. I hope that 4 nul bytes is enough to terminate all
	 * multibyte charsets? */

	/* nul-terminate the string */
	memset (outbuf, 0, 4);

	/* reset the cd */
	g_iconv (cd, NULL, NULL, NULL, NULL);

	return out;

 fail:

	errnosav = errno;

	w (g_warning ("camel_iconv_strndup: %s at byte %lu", g_strerror (errno), n - inleft));

	g_free (out);

	/* reset the cd */
	g_iconv (cd, NULL, NULL, NULL, NULL);

	errno = errnosav;

	return NULL;
}

#define is_ascii(c) isascii ((gint) ((guchar) (c)))

static gchar *
decode_8bit (const gchar *text,
             gsize len,
             const gchar *default_charset)
{
	const gchar *charsets[4] = { "UTF-8", NULL, NULL, NULL };
	gsize inleft, outleft, outlen, rc, min, n;
	const gchar *locale_charset, *best;
	gchar *out, *outbuf;
	const gchar *inbuf;
	GIConv cd;
	gint i = 1;

	if (default_charset && g_ascii_strcasecmp (default_charset, "UTF-8") != 0)
		charsets[i++] = default_charset;

	locale_charset = camel_iconv_locale_charset ();
	if (locale_charset && g_ascii_strcasecmp (locale_charset, "UTF-8") != 0)
		charsets[i++] = locale_charset;

	min = len;
	best = charsets[0];

	outlen = (len * 2) + 16;
	out = g_malloc (outlen + 1);

	for (i = 0; charsets[i]; i++) {
		if ((cd = camel_iconv_open ("UTF-8", charsets[i])) == (GIConv) -1)
			continue;

		outleft = outlen;
		outbuf = out;
		inleft = len;
		inbuf = text;
		n = 0;

		do {
			rc = g_iconv (cd, (gchar **) &inbuf, &inleft, &outbuf, &outleft);
			if (rc == (gsize) -1) {
				if (errno == EINVAL) {
					/* incomplete sequence at the end of the input buffer */
					n += inleft;
					break;
				}

				if (errno == E2BIG) {
					outlen += (inleft * 2) + 16;
					rc = (gsize) (outbuf - out);
					out = g_realloc (out, outlen + 1);
					outleft = outlen - rc;
					outbuf = out + rc;
				} else {
					inleft--;
					inbuf++;
					n++;
				}
			}
		} while (inleft > 0);

		while ((rc = g_iconv (cd, NULL, NULL, &outbuf, &outleft)) == (gsize) -1) {
			if (errno != E2BIG)
				break;

			outlen += 16;
			rc = (gsize) (outbuf - out);
			out = g_realloc (out, outlen + 1);
			outleft = outlen - rc;
			outbuf = out + rc;
		}

		*outbuf = '\0';

		camel_iconv_close (cd);

		if (rc != (gsize) -1 && n == 0)
			return out;

		if (n < min) {
			best = charsets[i];
			min = n;
		}
	}

	/* if we get here, then none of the charsets fit the 8bit text flawlessly...
	 * try to find the one that fit the best and use that to convert what we can,
	 * replacing any byte we can't convert with a '?' */

	if ((cd = camel_iconv_open ("UTF-8", best)) == (GIConv) -1) {
		/* this shouldn't happen... but if we are here, then
		 * it did...  the only thing we can do at this point
		 * is replace the 8bit garbage and pray */
		register const gchar *inptr = text;
		const gchar *inend = inptr + len;

		outbuf = out;

		while (inptr < inend) {
			if (is_ascii (*inptr))
				*outbuf++ = *inptr++;
			else
				*outbuf++ = '?';
		}

		*outbuf = '\0';

		return out;
	}

	outleft = outlen;
	outbuf = out;
	inleft = len;
	inbuf = text;

	do {
		rc = g_iconv (cd, (gchar **) &inbuf, &inleft, &outbuf, &outleft);
		if (rc == (gsize) -1) {
			if (errno == EINVAL) {
				/* incomplete sequence at the end of the input buffer */
				break;
			}

			if (errno == E2BIG) {
				rc = outbuf - out;
				outlen += inleft * 2 + 16;
				out = g_realloc (out, outlen + 1);
				outleft = outlen - rc;
				outbuf = out + rc;
			} else {
				*outbuf++ = '?';
				outleft--;
				inleft--;
				inbuf++;
			}
		}
	} while (inleft > 0);

	while ((rc = g_iconv (cd, NULL, NULL, &outbuf, &outleft)) == (gsize) -1) {
		if (errno != E2BIG)
			break;

		outlen += 16;
		rc = (gsize) (outbuf - out);
		out = g_realloc (out, outlen + 1);
		outleft = outlen - rc;
		outbuf = out + rc;
	}

	*outbuf = '\0';

	camel_iconv_close (cd);

	return out;
}

#define is_rfc2047_encoded_word(atom, len) (len >= 7 && !strncmp (atom, "=?", 2) && !strncmp (atom + len - 2, "?=", 2))

static void
make_string_utf8_valid (gchar *text,
                        gsize textlen)
{
	gchar *p;
	gsize len;

	p = text;
	len = textlen;

	while (!g_utf8_validate (p, len, (const gchar **) &p)) {
		len = textlen - (p - text);
		*p = '?';
	}
}

static void
sanitize_decoded_text (guchar *text,
		       gssize *inout_textlen)
{
	gssize ii, jj, textlen;

	g_return_if_fail (text != NULL);
	g_return_if_fail (inout_textlen != NULL);

	textlen = *inout_textlen;

	for (ii = 0, jj = 0; ii < textlen; ii++) {
		/* Skip '\0' and '\r' characters */
		if (text[ii] == 0 || text[ii] == '\r')
			continue;

		/* Change '\n' into space */
		if (text[ii] == '\n')
			text[ii] = ' ';

		if (ii != jj)
			text[jj] = text[ii];

		jj++;
	}

	*inout_textlen = jj;
}

/* decode an rfc2047 encoded-word token */
static gchar *
rfc2047_decode_word (const gchar *in,
                     gsize inlen,
                     const gchar *default_charset)
{
	const guchar *instart = (const guchar *) in;
	const guchar *inptr = instart + 2;
	const guchar *inend = instart + inlen - 2;
	guchar *decoded;
	const gchar *charset;
	gchar *charenc, *p;
	guint32 save = 0;
	gssize declen;
	gint state = 0;
	gsize len;
	GIConv cd;
	gchar *buf;

	/* skip over the charset */
	if (inlen < 8 || !(inptr = memchr (inptr, '?', inend - inptr)) || inptr[2] != '?')
		return NULL;

	inptr++;

	switch (*inptr) {
	case 'B':
	case 'b':
		inptr += 2;
		decoded = g_alloca (inend - inptr);
		declen = g_base64_decode_step ((gchar *) inptr, inend - inptr, decoded, &state, &save);
		break;
	case 'Q':
	case 'q':
		inptr += 2;
		decoded = g_alloca (inend - inptr);
		declen = quoted_decode (inptr, inend - inptr, decoded);

		if (declen == -1) {
			d (fprintf (stderr, "encountered broken 'Q' encoding\n"));
			return NULL;
		}
		break;
	default:
		d (fprintf (stderr, "unknown encoding\n"));
		return NULL;
	}

	sanitize_decoded_text (decoded, &declen);

	/* never return empty string, return rather NULL */
	if (!declen)
		return NULL;

	len = (inptr - 3) - (instart + 2);
	charenc = g_alloca (len + 1);
	memcpy (charenc, in + 2, len);
	charenc[len] = '\0';
	charset = charenc;

	/* rfc2231 updates rfc2047 encoded words...
	 * The ABNF given in RFC 2047 for encoded-words is:
	 *   encoded-word := "=?" charset "?" encoding "?" encoded-text "?="
	 * This specification changes this ABNF to:
	 *   encoded-word := "=?" charset ["*" language] "?" encoding "?" encoded-text "?="
	 */

	/* trim off the 'language' part if it's there... */
	if ((p = strchr (charset, '*')))
		*p = '\0';

	/* slight optimization? */
	if (!g_ascii_strcasecmp (charset, "UTF-8"))
		return g_strndup ((gchar *) decoded, declen);

	if (charset[0])
		charset = camel_iconv_charset_name (charset);

	if (!charset[0] || (cd = camel_iconv_open ("UTF-8", charset)) == (GIConv) -1) {
		w (g_warning (
			"Cannot convert from %s to UTF-8, "
			"header display may be corrupt: %s",
			charset[0] ? charset : "unspecified charset",
			g_strerror (errno)));

		return decode_8bit ((gchar *) decoded, declen, default_charset);
	}

	buf = camel_iconv_strndup (cd, (gchar *) decoded, declen);
	camel_iconv_close (cd);

	if (buf != NULL)
		return buf;

	w (g_warning (
		"Failed to convert \"%.*s\" to UTF-8, display may be "
		"corrupt: %s", declen, decoded, g_strerror (errno)));

	return decode_8bit ((gchar *) decoded, declen, charset);
}

/* ok, a lot of mailers are BROKEN, and send iso-latin1 encoded
 * headers, when they should just be sticking to US-ASCII
 * according to the rfc's.  Anyway, since the conversion to utf-8
 * is trivial, just do it here without iconv */
static GString *
append_latin1 (GString *out,
               const gchar *in,
               gsize len)
{
	guint c;

	while (len) {
		c = (guint) * in++;
		len--;
		if (c & 0x80) {
			out = g_string_append_c (out, 0xc0 | ((c >> 6) & 0x3));  /* 110000xx */
			out = g_string_append_c (out, 0x80 | (c & 0x3f));        /* 10xxxxxx */
		} else {
			out = g_string_append_c (out, c);
		}
	}
	return out;
}

static gint
append_8bit (GString *out,
             const gchar *inbuf,
             gsize inlen,
             const gchar *charset)
{
	gchar *outbase, *outbuf;
	gsize outlen;
	GIConv ic;

	ic = camel_iconv_open ("UTF-8", charset);
	if (ic == (GIConv) -1)
		return FALSE;

	outlen = inlen * 6 + 16;
	outbuf = outbase = g_malloc (outlen);

	if (camel_iconv (ic, &inbuf, &inlen, &outbuf, &outlen) == (gsize) -1) {
		w (g_warning ("Conversion to '%s' failed: %s", charset, g_strerror (errno)));
		g_free (outbase);
		camel_iconv_close (ic);
		return FALSE;
	}

	camel_iconv (ic, NULL, NULL, &outbuf, &outlen);

	*outbuf = 0;
	g_string_append (out, outbase);
	g_free (outbase);
	camel_iconv_close (ic);

	return TRUE;

}

static GString *
append_quoted_pair (GString *str,
                    const gchar *in,
                    gsize inlen)
{
	register const gchar *inptr = in;
	const gchar *inend = in + inlen;
	gchar c;

	while (inptr < inend) {
		c = *inptr++;
		if (c == '\\' && inptr < inend)
			g_string_append_c (str, *inptr++);
		else
			g_string_append_c (str, c);
	}

	return str;
}

/* decodes a simple text, rfc822 + rfc2047 */
static gchar *
header_decode_text (const gchar *in,
                    gint ctext,
                    const gchar *default_charset)
{
	register const gchar *inptr = in;
	gboolean encoded = FALSE;
	const gchar *lwsp, *text;
	gsize nlwsp, n;
	gboolean ascii;
	gchar *decoded;
	GString *out;

	if (in == NULL)
		return g_strdup ("");

	out = g_string_sized_new (strlen (in) + 1);

	while (*inptr != '\0') {
		lwsp = inptr;
		while (camel_mime_is_lwsp (*inptr))
			inptr++;

		nlwsp = (gsize) (inptr - lwsp);

		if (*inptr != '\0') {
			text = inptr;
			ascii = TRUE;

			if (!strncmp (inptr, "=?", 2)) {
				inptr += 2;

				/* skip past the charset (if one is even declared, sigh) */
				while (*inptr && *inptr != '?') {
					ascii = ascii && is_ascii (*inptr);
					inptr++;
				}

				/* sanity check encoding type */
				if (inptr[0] != '?' || !strchr ("BbQq", inptr[1]) || !inptr[1] || inptr[2] != '?')
					goto non_rfc2047;

				inptr += 3;

				/* find the end of the rfc2047 encoded word token */
				while (*inptr && strncmp (inptr, "?=", 2) != 0) {
					ascii = ascii && is_ascii (*inptr);
					inptr++;
				}

				if (!strncmp (inptr, "?=", 2))
					inptr += 2;
			} else {
			non_rfc2047:
				/* stop if we encounter a possible rfc2047 encoded
				 * token even if it's inside another word, sigh. */
				while (*inptr && !camel_mime_is_lwsp (*inptr) &&
				       strncmp (inptr, "=?", 2) != 0) {
					ascii = ascii && is_ascii (*inptr);
					inptr++;
				}
			}

			n = (gsize) (inptr - text);
			if (is_rfc2047_encoded_word (text, n)) {
				if ((decoded = rfc2047_decode_word (text, n, default_charset))) {
					/* rfc2047 states that you must ignore all
					 * whitespace between encoded words */
					if (!encoded)
						g_string_append_len (out, lwsp, nlwsp);

					g_string_append (out, decoded);
					g_free (decoded);

					encoded = TRUE;
				} else {
					/* append lwsp and invalid rfc2047 encoded-word token */
					g_string_append_len (out, lwsp, nlwsp + n);
					encoded = FALSE;
				}
			} else {
				/* append lwsp */
				g_string_append_len (out, lwsp, nlwsp);

				/* append word token */
				if (!ascii) {
					/* *sigh* I hate broken mailers... */
					decoded = decode_8bit (text, n, default_charset);
					n = strlen (decoded);
					text = decoded;
				} else {
					decoded = NULL;
				}

				if (!ctext)
					g_string_append_len (out, text, n);
				else
					append_quoted_pair (out, text, n);

				g_free (decoded);

				encoded = FALSE;
			}
		} else {
			/* appending trailing lwsp */
			g_string_append_len (out, lwsp, nlwsp);
			break;
		}
	}

	decoded = g_string_free (out, FALSE);

	return decoded;
}

/**
 * camel_header_decode_string:
 * @in: input header value string
 * @default_charset: default charset to use if improperly encoded
 *
 * Decodes rfc2047 encoded-word tokens
 *
 * Returns: a string containing the UTF-8 version of the decoded header
 * value
 **/
gchar *
camel_header_decode_string (const gchar *in,
                            const gchar *default_charset)
{
	gchar *res;

	if (in == NULL)
		return NULL;

	res = header_decode_text (in, FALSE, default_charset);

	if (res)
		make_string_utf8_valid (res, strlen (res));

	return res;
}

/**
 * camel_header_format_ctext:
 * @in: input header value string
 * @default_charset: default charset to use if improperly encoded
 *
 * Decodes a header which contains rfc2047 encoded-word tokens that
 * may or may not be within a comment.
 *
 * Returns: a string containing the UTF-8 version of the decoded header
 * value
 **/
gchar *
camel_header_format_ctext (const gchar *in,
                           const gchar *default_charset)
{
	if (in == NULL)
		return NULL;

	return header_decode_text (in, TRUE, default_charset);
}

/* how long a sequence of pre-encoded words should be less than, to attempt to
 * fit into a properly folded word.  Only a guide. */
#define CAMEL_FOLD_PREENCODED (24)

/* FIXME: needs a way to cache iconv opens for different charsets? */
static void
rfc2047_encode_word (GString *outstring,
                     const gchar *in,
                     gsize len,
                     const gchar *type,
                     gushort safemask)
{
	GIConv ic = (GIConv) -1;
	gchar *buffer, *out, *ascii;
	gsize inlen, outlen, enclen, bufflen;
	const gchar *inptr, *p;
	gint first = 1;

	d (printf ("Converting [%d] '%.*s' to %s\n", len, len, in, type));

	/* convert utf8->encoding */
	bufflen = len * 6 + 16;
	buffer = g_alloca (bufflen);
	inlen = len;
	inptr = in;

	ascii = g_alloca (bufflen);

	if (g_ascii_strcasecmp (type, "UTF-8") != 0)
		ic = camel_iconv_open (type, "UTF-8");

	while (inlen) {
		gssize convlen, proclen;
		gint i;

		/* break up words into smaller bits, what we really want is encoded + overhead < 75,
		 * but we'll just guess what that means in terms of input chars, and assume its good enough */

		out = buffer;
		outlen = bufflen;

		if (ic == (GIConv) -1) {
			/* native encoding case, the easy one (?) */
			/* we work out how much we can convert, and still be in length */
			/* proclen will be the result of input characters that we can convert, to the nearest
			 * (approximated) valid utf8 gchar */
			convlen = 0;
			proclen = -1;
			p = inptr;
			i = 0;
			while (p < (in + len) && convlen < (75 - strlen ("=?utf-8?q?\?="))) {
				guchar c = *p++;

				if (c >= 0xc0)
					proclen = i;
				i++;
				if (c < 0x80)
					proclen = i;
				if (camel_mime_special_table[c] & safemask)
					convlen += 1;
				else
					convlen += 3;
			}

			if (proclen >= 0 && proclen < i && convlen < (75 - strlen ("=?utf-8?q?\?=")))
				proclen = i;

			/* well, we probably have broken utf8, just copy it anyway what the heck */
			if (proclen == -1) {
				w (g_warning ("Appear to have truncated utf8 sequence"));
				proclen = inlen;
			}

			memcpy (out, inptr, proclen);
			inptr += proclen;
			inlen -= proclen;
			out += proclen;
		} else {
			/* well we could do similar, but we can't (without undue effort), we'll just break it up into
			 * hopefully-small-enough chunks, and leave it at that */
			convlen = MIN (inlen, CAMEL_FOLD_PREENCODED);
			p = inptr;
			if (camel_iconv (ic, &inptr, (gsize *) &convlen, &out, &outlen) == (gsize) -1 && errno != EINVAL) {
				w (g_warning ("Conversion problem: conversion truncated: %s", g_strerror (errno)));
				/* blah, we include it anyway, better than infinite loop ... */
				inptr += convlen;
			} else {
				/* make sure we flush out any shift state */
				camel_iconv (ic, NULL, NULL, &out, &outlen);
			}
			inlen -= (inptr - p);
		}

		enclen = out - buffer;

		if (enclen) {
			/* create token */
			out = ascii;
			if (first)
				first = 0;
			else
				*out++ = ' ';
			out += sprintf (out, "=?%s?Q?", type);
			out += quoted_encode ((guchar *) buffer, enclen, (guchar *) out, safemask);
			sprintf (out, "?=");

			d (printf ("converted part = %s\n", ascii));

			g_string_append (outstring, ascii);
		}
	}

	if (ic != (GIConv) -1)
		camel_iconv_close (ic);
}

static gchar *
header_encode_string_rfc2047 (const guchar *in,
                              gboolean include_lwsp)
{
	const guchar *inptr = in, *start, *word;
	gboolean last_was_encoded = FALSE;
	gboolean last_was_space = FALSE;
	const gchar *charset;
	gint encoding;
	GString *out;
	gchar *outstr;

	g_return_val_if_fail (g_utf8_validate ((const gchar *) in, -1, NULL), NULL);

	if (in == NULL)
		return NULL;

	/* do a quick us-ascii check (the common case?) */
	while (*inptr) {
		if (*inptr > 127)
			break;
		inptr++;
	}
	if (*inptr == '\0')
		return g_strdup ((gchar *) in);

	/* This gets each word out of the input, and checks to see what charset
	 * can be used to encode it. */
	/* TODO: Work out when to merge subsequent words, or across word-parts */
	out = g_string_new ("");
	inptr = in;
	encoding = 0;
	word = NULL;
	start = inptr;
	while (inptr && *inptr) {
		gunichar c;
		const gchar *newinptr;

		newinptr = g_utf8_next_char (inptr);
		c = g_utf8_get_char ((gchar *) inptr);
		if (newinptr == NULL || !g_unichar_validate (c)) {
			w (g_warning (
				"Invalid UTF-8 sequence encountered "
				"(pos %d, gchar '%c'): %s",
				(inptr - in), inptr[0], in));
			inptr++;
			continue;
		}

		if (c < 256 && !include_lwsp && camel_mime_is_lwsp (c) && !last_was_space) {
			/* we've reached the end of a 'word' */
			if (word && !(last_was_encoded && encoding)) {
				/* output lwsp between non-encoded words */
				g_string_append_len (out, (const gchar *) start, word - start);
				start = word;
			}

			switch (encoding) {
			case 0:
				g_string_append_len (out, (const gchar *) start, inptr - start);
				last_was_encoded = FALSE;
				break;
			case 1:
				if (last_was_encoded)
					g_string_append_c (out, ' ');

				rfc2047_encode_word (out, (const gchar *) start, inptr - start, "ISO-8859-1", CAMEL_MIME_IS_ESAFE);
				last_was_encoded = TRUE;
				break;
			case 2:
				if (last_was_encoded)
					g_string_append_c (out, ' ');

				if (!(charset = camel_charset_best ((const gchar *) start, inptr - start)))
					charset = "UTF-8";
				rfc2047_encode_word (out, (const gchar *) start, inptr - start, charset, CAMEL_MIME_IS_ESAFE);
				last_was_encoded = TRUE;
				break;
			}

			last_was_space = TRUE;
			start = inptr;
			word = NULL;
			encoding = 0;
		} else if (c > 127 && c < 256) {
			encoding = MAX (encoding, 1);
			last_was_space = FALSE;
		} else if (c >= 256) {
			encoding = MAX (encoding, 2);
			last_was_space = FALSE;
		} else if (include_lwsp || !camel_mime_is_lwsp (c)) {
			last_was_space = FALSE;
		}

		if (!(c < 256 && !include_lwsp && camel_mime_is_lwsp (c)) && !word)
			word = inptr;

		inptr = (const guchar *) newinptr;
	}

	if (inptr - start) {
		if (word && !(last_was_encoded && encoding)) {
			g_string_append_len (out, (const gchar *) start, word - start);
			start = word;
		}

		switch (encoding) {
		case 0:
			g_string_append_len (out, (const gchar *) start, inptr - start);
			break;
		case 1:
			if (last_was_encoded)
				g_string_append_c (out, ' ');

			rfc2047_encode_word (out, (const gchar *) start, inptr - start, "ISO-8859-1", CAMEL_MIME_IS_ESAFE);
			break;
		case 2:
			if (last_was_encoded)
				g_string_append_c (out, ' ');

			if (!(charset = camel_charset_best ((const gchar *) start, inptr - start)))
				charset = "UTF-8";
			rfc2047_encode_word (out, (const gchar *) start, inptr - start, charset, CAMEL_MIME_IS_ESAFE);
			break;
		}
	}

	outstr = out->str;
	g_string_free (out, FALSE);

	return outstr;
}

/* TODO: Should this worry about quotes?? */
/**
 * camel_header_encode_string:
 * @in: input string
 *
 * Encodes a 'text' header according to the rules of rfc2047.
 *
 * Returns: the rfc2047 encoded header
 **/
gchar *
camel_header_encode_string (const guchar *in)
{
	return header_encode_string_rfc2047 (in, FALSE);
}

/* apply quoted-string rules to a string */
static void
quote_word (GString *out,
            gboolean do_quotes,
            const gchar *start,
            gsize len)
{
	gint i, c;

	/* TODO: What about folding on long lines? */
	if (do_quotes)
		g_string_append_c (out, '"');
	for (i = 0; i < len; i++) {
		c = *start++;
		if (c == '\"' || c == '\\' || c == '\r')
			g_string_append_c (out, '\\');
		g_string_append_c (out, c);
	}
	if (do_quotes)
		g_string_append_c (out, '"');
}

/* incrementing possibility for the word type */
enum _phrase_word_t {
	WORD_ATOM,
	WORD_QSTRING,
	WORD_2047
};

struct _phrase_word {
	const guchar *start, *end;
	enum _phrase_word_t type;
	gint encoding;
};

static gboolean
word_types_compatable (enum _phrase_word_t type1,
                       enum _phrase_word_t type2)
{
	switch (type1) {
	case WORD_ATOM:
		return type2 == WORD_QSTRING;
	case WORD_QSTRING:
		return type2 != WORD_2047;
	case WORD_2047:
		return type2 == WORD_2047;
	default:
		return FALSE;
	}
}

/* split the input into words with info about each word
 * merge common word types clean up */
static GList *
header_encode_phrase_get_words (const guchar *in)
{
	const guchar *inptr = in, *start, *last;
	struct _phrase_word *word;
	enum _phrase_word_t type;
	gint encoding, count = 0;
	GList *words = NULL;

	/* break the input into words */
	type = WORD_ATOM;
	last = inptr;
	start = inptr;
	encoding = 0;
	while (inptr && *inptr) {
		gunichar c;
		const gchar *newinptr;

		newinptr = g_utf8_next_char (inptr);
		c = g_utf8_get_char ((gchar *) inptr);

		if (!g_unichar_validate (c)) {
			w (g_warning (
				"Invalid UTF-8 sequence encountered "
				"(pos %d, gchar '%c'): %s",
				(inptr - in), inptr[0], in));
			inptr++;
			continue;
		}

		inptr = (const guchar *) newinptr;
		if (g_unichar_isspace (c)) {
			if (count > 0) {
				word = g_new0 (struct _phrase_word, 1);
				word->start = start;
				word->end = last;
				word->type = type;
				word->encoding = encoding;
				words = g_list_append (words, word);
				count = 0;
			}

			start = inptr;
			type = WORD_ATOM;
			encoding = 0;
		} else {
			count++;
			if (c < 128) {
				if (!camel_mime_is_atom (c))
					type = MAX (type, WORD_QSTRING);
			} else if (c > 127 && c < 256) {
				type = WORD_2047;
				encoding = MAX (encoding, 1);
			} else if (c >= 256) {
				type = WORD_2047;
				encoding = MAX (encoding, 2);
			}
		}

		last = inptr;
	}

	if (count > 0) {
		word = g_new0 (struct _phrase_word, 1);
		word->start = start;
		word->end = last;
		word->type = type;
		word->encoding = encoding;
		words = g_list_append (words, word);
	}

	return words;
}

#define MERGED_WORD_LT_FOLDLEN(wordlen, type) ((type) == WORD_2047 ? (wordlen) < CAMEL_FOLD_PREENCODED : (wordlen) < (CAMEL_FOLD_SIZE - 8))

static gboolean
header_encode_phrase_merge_words (GList **wordsp)
{
	GList *wordl, *nextl, *words = *wordsp;
	struct _phrase_word *word, *next;
	gboolean merged = FALSE;

	/* scan the list, checking for words of similar types that can be merged */
	wordl = words;
	while (wordl) {
		word = wordl->data;
		nextl = g_list_next (wordl);

		while (nextl) {
			next = nextl->data;
			/* merge nodes of the same type AND we are not creating too long a string */
			if (word_types_compatable (word->type, next->type)) {
				if (MERGED_WORD_LT_FOLDLEN (next->end - word->start, MAX (word->type, next->type))) {
					/* the resulting word type is the MAX of the 2 types */
					word->type = MAX (word->type, next->type);
					word->encoding = MAX (word->encoding, next->encoding);
					word->end = next->end;
					words = g_list_remove_link (words, nextl);
					g_list_free_1 (nextl);
					g_free (next);

					nextl = g_list_next (wordl);

					merged = TRUE;
				} else {
					/* if it is going to be too long, make sure we include the
					 * separating whitespace */
					word->end = next->start;
					break;
				}
			} else {
				break;
			}
		}

		wordl = g_list_next (wordl);
	}

	*wordsp = words;

	return merged;
}

/* encodes a phrase sequence (different quoting/encoding rules to strings) */
/**
 * camel_header_encode_phrase:
 * @in: header to encode
 *
 * Encodes a 'phrase' header according to the rules in rfc2047.
 *
 * Returns: the encoded 'phrase'
 **/
gchar *
camel_header_encode_phrase (const guchar *in)
{
	struct _phrase_word *word = NULL, *last_word = NULL;
	GList *words, *wordl;
	const gchar *charset;
	GString *out;
	gchar *outstr;

	if (in == NULL)
		return NULL;

	words = header_encode_phrase_get_words (in);
	if (!words)
		return NULL;

	while (header_encode_phrase_merge_words (&words))
		;

	out = g_string_new ("");

	/* output words now with spaces between them */
	wordl = words;
	while (wordl) {
		const gchar *start;
		gsize len;

		word = wordl->data;

		/* append correct number of spaces between words */
		if (last_word && !(last_word->type == WORD_2047 && word->type == WORD_2047)) {
			/* one or both of the words are not encoded so we write the spaces out untouched */
			len = word->start - last_word->end;
			out = g_string_append_len (out, (gchar *) last_word->end, len);
		}

		switch (word->type) {
		case WORD_ATOM:
			out = g_string_append_len (out, (gchar *) word->start, word->end - word->start);
			break;
		case WORD_QSTRING:
			quote_word (out, TRUE, (gchar *) word->start, word->end - word->start);
			break;
		case WORD_2047:
			if (last_word && last_word->type == WORD_2047) {
				/* include the whitespace chars between these 2 words in the
				 * resulting rfc2047 encoded word. */
				len = word->end - last_word->end;
				start = (const gchar *) last_word->end;

				/* encoded words need to be separated by linear whitespace */
				g_string_append_c (out, ' ');
			} else {
				len = word->end - word->start;
				start = (const gchar *) word->start;
			}

			if (word->encoding == 1) {
				rfc2047_encode_word (out, start, len, "ISO-8859-1", CAMEL_MIME_IS_PSAFE);
			} else {
				if (!(charset = camel_charset_best (start, len)))
					charset = "UTF-8";
				rfc2047_encode_word (out, start, len, charset, CAMEL_MIME_IS_PSAFE);
			}
			break;
		}

		g_free (last_word);
		wordl = g_list_next (wordl);

		last_word = word;
	}

	/* and we no longer need the list */
	g_free (word);
	g_list_free (words);

	outstr = out->str;
	g_string_free (out, FALSE);

	return outstr;
}

/* these are all internal parser functions */

static gchar *
decode_token (const gchar **in)
{
	const gchar *inptr = *in;
	const gchar *start;

	header_decode_lwsp (&inptr);
	start = inptr;
	while (camel_mime_is_ttoken (*inptr))
		inptr++;
	if (inptr > start) {
		*in = inptr;
		return g_strndup (start, inptr - start);
	} else {
		return NULL;
	}
}

/**
 * camel_header_token_decode:
 * @in: input string
 *
 * Gets the first token in the string according to the rules of
 * rfc0822.
 *
 * Returns: a new string containing the first token in @in
 **/
gchar *
camel_header_token_decode (const gchar *in)
{
	if (in == NULL)
		return NULL;

	return decode_token (&in);
}

/*
 * <"> * ( <any gchar except <"> \, cr  /  \ <any char> ) <">
*/
static gchar *
header_decode_quoted_string (const gchar **in)
{
	const gchar *inptr = *in;
	gchar *out = NULL, *outptr;
	gsize outlen;
	gint c;

	header_decode_lwsp (&inptr);
	if (*inptr == '"') {
		const gchar *intmp;
		gint skip = 0;

		/* first, calc length */
		inptr++;
		intmp = inptr;
		while ( (c = *intmp++) && c!= '"') {
			if (c == '\\' && *intmp) {
				intmp++;
				skip++;
			} else if (c == '\n') {
				skip++;
			}
		}
		outlen = intmp - inptr - skip;
		out = outptr = g_malloc (outlen + 1);
		while ( (c = *inptr) && c!= '"') {
			inptr++;
			if (c == '\\' && *inptr) {
				c = *inptr++;
			} else if (c == '\n') {
				continue;
			}
			*outptr++ = c;
		}
		if (c)
			inptr++;
		*outptr = '\0';
	}
	*in = inptr;
	return out;
}

static gchar *
header_decode_atom (const gchar **in)
{
	const gchar *inptr = *in, *start;

	header_decode_lwsp (&inptr);
	start = inptr;
	while (camel_mime_is_atom (*inptr))
		inptr++;
	*in = inptr;
	if (inptr > start)
		return g_strndup (start, inptr - start);
	else
		return NULL;
}

static gboolean
extract_rfc2047_encoded_word (const gchar **in,
                              gchar **word)
{
	const gchar *inptr = *in, *start;

	header_decode_lwsp (&inptr);
	start = inptr;

	if (!strncmp (inptr, "=?", 2)) {
		inptr += 2;

		/* skip past the charset (if one is even declared, sigh) */
		while (*inptr && *inptr != '?') {
			inptr++;
		}

		/* sanity check encoding type */
		if (inptr[0] != '?' || !strchr ("BbQq", inptr[1]) || !inptr[1] || inptr[2] != '?')
			return FALSE;

		inptr += 3;

		/* find the end of the rfc2047 encoded word token */
		while (*inptr && strncmp (inptr, "?=", 2) != 0) {
			inptr++;
		}

		if (!strncmp (inptr, "?=", 2)) {
			inptr += 2;

			*in = inptr;
			*word = g_strndup (start, inptr - start);

			return TRUE;
		}
	}

	return FALSE;
}

static gchar *
header_decode_word (const gchar **in)
{
	const gchar *inptr = *in;
	gchar *word = NULL;

	header_decode_lwsp (&inptr);
	*in = inptr;

	if (*inptr == '"') {
		return header_decode_quoted_string (in);
	} else if (*inptr == '=' && inptr[1] == '?' && extract_rfc2047_encoded_word (in, &word) && word) {
		return word;
	} else {
		return header_decode_atom (in);
	}
}

static gchar *
header_decode_value (const gchar **in)
{
	const gchar *inptr = *in;

	header_decode_lwsp (&inptr);
	if (*inptr == '"') {
		d (printf ("decoding quoted string\n"));
		return header_decode_quoted_string (in);
	} else if (camel_mime_is_ttoken (*inptr)) {
		d (printf ("decoding token\n"));
		/* this may not have the right specials for all params? */
		return decode_token (in);
	}
	return NULL;
}

/* should this return -1 for no int? */

/**
 * camel_header_decode_int:
 * @in: pointer to input string
 *
 * Extracts an integer token from @in and updates the pointer to point
 * to after the end of the integer token (sort of like strtol).
 *
 * Returns: the gint value
 **/
gint
camel_header_decode_int (const gchar **in)
{
	const gchar *inptr = *in;
	gint c, v = 0;

	header_decode_lwsp (&inptr);
	while ( (c=*inptr++ & 0xff)
		&& isdigit (c) ) {
		v = v * 10 + (c - '0');
	}
	*in = inptr-1;
	return v;
}

#define HEXVAL(c) (isdigit (c) ? (c) - '0' : tolower (c) - 'a' + 10)

static gchar *
hex_decode (const gchar *in,
            gsize len)
{
	const guchar *inend = (const guchar *) (in + len);
	guchar *inptr, *outptr;
	gchar *outbuf;

	outbuf = (gchar *) g_malloc (len + 1);
	outptr = (guchar *) outbuf;

	inptr = (guchar *) in;
	while (inptr < inend) {
		if (*inptr == '%') {
			if (isxdigit (inptr[1]) && isxdigit (inptr[2])) {
				*outptr++ = HEXVAL (inptr[1]) * 16 + HEXVAL (inptr[2]);
				inptr += 3;
			} else
				*outptr++ = *inptr++;
		} else
			*outptr++ = *inptr++;
	}

	*outptr = '\0';

	return outbuf;
}

/* Tries to convert @in @from charset @to charset.  Any failure, we get no data out rather than partial conversion */
static gchar *
header_convert (const gchar *to,
                const gchar *from,
                const gchar *in,
                gsize inlen)
{
	GIConv ic;
	gsize outlen, ret;
	gchar *outbuf, *outbase, *result = NULL;

	ic = camel_iconv_open (to, from);
	if (ic == (GIConv) -1)
		return NULL;

	outlen = inlen * 6 + 16;
	outbuf = outbase = g_malloc (outlen);

	ret = camel_iconv (ic, &in, &inlen, &outbuf, &outlen);
	if (ret != (gsize) -1) {
		camel_iconv (ic, NULL, NULL, &outbuf, &outlen);
		*outbuf = '\0';
		result = g_strdup (outbase);
	}
	camel_iconv_close (ic);
	g_free (outbase);

	return result;
}

/* an rfc2184 encoded string looks something like:
 * us-ascii'en'This%20is%20even%20more%20
 */

static gchar *
rfc2184_decode (const gchar *in,
                gsize len)
{
	const gchar *inptr = in;
	const gchar *inend = in + len;
	const gchar *charset;
	gchar *decoded, *decword, *encoding;

	inptr = memchr (inptr, '\'', len);
	if (!inptr)
		return NULL;

	encoding = g_alloca (inptr - in + 1);
	memcpy (encoding, in, inptr - in);
	encoding[inptr - in] = 0;
	charset = camel_iconv_charset_name (encoding);

	inptr = memchr (inptr + 1, '\'', inend - inptr - 1);
	if (!inptr)
		return NULL;
	inptr++;
	if (inptr >= inend)
		return NULL;

	decword = hex_decode (inptr, inend - inptr);
	decoded = header_convert ("UTF-8", charset, decword, strlen (decword));
	g_free (decword);

	return decoded;
}

/**
 * camel_header_param:
 * @params: parameters
 * @name: name of param to find
 *
 * Searches @params for a param named @name and gets the value.
 *
 * Returns: the value of the @name param
 **/
gchar *
camel_header_param (struct _camel_header_param *params,
                    const gchar *name)
{
	while (params && params->name &&
	       g_ascii_strcasecmp (params->name, name) != 0)
		params = params->next;
	if (params)
		return params->value;

	return NULL;
}

/**
 * camel_header_set_param:
 * @paramsp: poinetr to a list of params
 * @name: name of param to set
 * @value: value to set
 *
 * Set a parameter in the list.
 *
 * Returns: (transfer none): the set param
 **/
struct _camel_header_param *
camel_header_set_param (struct _camel_header_param **l,
                        const gchar *name,
                        const gchar *value)
{
	struct _camel_header_param *p = (struct _camel_header_param *) l, *pn;

	if (name == NULL)
		return NULL;

	while (p->next) {
		pn = p->next;
		if (!g_ascii_strcasecmp (pn->name, name)) {
			g_free (pn->value);
			if (value) {
				pn->value = g_strdup (value);
				return pn;
			} else {
				p->next = pn->next;
				g_free (pn->name);
				g_free (pn);
				return NULL;
			}
		}
		p = pn;
	}

	if (value == NULL)
		return NULL;

	pn = g_malloc (sizeof (*pn));
	pn->next = NULL;
	pn->name = g_strdup (name);
	pn->value = g_strdup (value);
	p->next = pn;

	return pn;
}

/**
 * camel_content_type_param:
 * @content_type: a #CamelContentType
 * @name: name of param to find
 *
 * Searches the params on s #CamelContentType for a param named @name
 * and gets the value.
 *
 * Returns: the value of the @name param
 **/
const gchar *
camel_content_type_param (CamelContentType *t,
                          const gchar *name)
{
	if (t == NULL)
		return NULL;
	return camel_header_param (t->params, name);
}

/**
 * camel_content_type_set_param:
 * @content_type: a #CamelContentType
 * @name: name of param to set
 * @value: value of param to set
 *
 * Set a parameter on @content_type.
 **/
void
camel_content_type_set_param (CamelContentType *t,
                              const gchar *name,
                              const gchar *value)
{
	g_return_if_fail (t != NULL);

	camel_header_set_param (&t->params, name, value);
}

/**
 * camel_content_type_is:
 * @content_type: A content type specifier, or %NULL.
 * @type: A type to check against.
 * @subtype: A subtype to check against, or "*" to match any subtype.
 *
 * The subtype of "*" will match any subtype.  If @ct is %NULL, then
 * it will match the type "text/plain".
 *
 * Returns: %TRUE if the content type @ct is of type @type/@subtype or
 * %FALSE otherwise
 **/
gboolean
camel_content_type_is (const CamelContentType *ct,
                       const gchar *type,
                       const gchar *subtype)
{
	/* no type == text/plain or text/"*" */
	if (ct == NULL || (ct->type == NULL && ct->subtype == NULL)) {
		return (!g_ascii_strcasecmp (type, "text")
			&& (!g_ascii_strcasecmp (subtype, "plain")
			|| !strcmp (subtype, "*")));
	}

	return (ct->type != NULL
		&& (!g_ascii_strcasecmp (ct->type, type)
		&& ((ct->subtype != NULL
		&& !g_ascii_strcasecmp (ct->subtype, subtype))
			|| !strcmp ("*", subtype))));
}

/**
 * camel_header_param_list_free:
 * @params: a list of params
 *
 * Free the list of params.
 **/
void
camel_header_param_list_free (struct _camel_header_param *p)
{
	struct _camel_header_param *n;

	while (p) {
		n = p->next;
		g_free (p->name);
		g_free (p->value);
		g_free (p);
		p = n;
	}
}

/**
 * camel_content_type_new:
 * @type: the major type of the new content-type
 * @subtype: the subtype
 *
 * Create a new #CamelContentType.
 *
 * Returns: the new #CamelContentType
 **/
CamelContentType *
camel_content_type_new (const gchar *type,
                        const gchar *subtype)
{
	CamelContentType *t;

	t = g_slice_new (CamelContentType);
	t->type = g_strdup (type);
	t->subtype = g_strdup (subtype);
	t->params = NULL;
	t->refcount = 1;

	return t;
}

/**
 * camel_content_type_ref:
 * @content_type: a #CamelContentType
 *
 * Refs the content type.
 **/
CamelContentType *
camel_content_type_ref (CamelContentType *ct)
{
	if (ct)
		ct->refcount++;

	return ct;
}

/**
 * camel_content_type_unref:
 * @content_type: a #CamelContentType
 *
 * Unrefs, and potentially frees, the content type.
 **/
void
camel_content_type_unref (CamelContentType *ct)
{
	if (ct) {
		if (ct->refcount <= 1) {
			camel_header_param_list_free (ct->params);
			g_free (ct->type);
			g_free (ct->subtype);
			g_slice_free (CamelContentType, ct);
			ct = NULL;
		} else {
			ct->refcount--;
		}
	}
}

/* for decoding email addresses, canonically */
static gchar *
header_decode_domain (const gchar **in)
{
	const gchar *inptr = *in;
	gint go = TRUE;
	gchar *ret;
	GString *domain = g_string_new ("");

	/* domain ref | domain literal */
	header_decode_lwsp (&inptr);
	while (go) {
		if (*inptr == '[') { /* domain literal */
			domain = g_string_append_c (domain, '[');
			inptr++;
			header_decode_lwsp (&inptr);
			while (*inptr && camel_mime_is_dtext (*inptr)) {
				domain = g_string_append_c (domain, *inptr);
				inptr++;
			}
			if (*inptr == ']') {
				domain = g_string_append_c (domain, ']');
				inptr++;
			} else {
				w (g_warning ("closing ']' not found in domain: %s", *in));
			}
		} else {
			gchar *a = header_decode_atom (&inptr);
			if (a) {
				domain = g_string_append (domain, a);
				g_free (a);
			} else {
				w (g_warning ("missing atom from domain-ref"));
				break;
			}
		}
		header_decode_lwsp (&inptr);
		if (*inptr == '.') { /* next sub-domain? */
			domain = g_string_append_c (domain, '.');
			inptr++;
			header_decode_lwsp (&inptr);
		} else
			go = FALSE;
	}

	*in = inptr;

	ret = domain->str;
	g_string_free (domain, FALSE);
	return ret;
}

static gchar *
header_decode_addrspec (const gchar **in)
{
	const gchar *inptr = *in;
	gchar *word;
	GString *addr = g_string_new ("");

	header_decode_lwsp (&inptr);

	/* addr-spec */
	word = header_decode_word (&inptr);
	if (word) {
		addr = g_string_append (addr, word);
		header_decode_lwsp (&inptr);
		g_free (word);
		while (*inptr == '.' && word) {
			inptr++;
			addr = g_string_append_c (addr, '.');
			word = header_decode_word (&inptr);
			if (word) {
				addr = g_string_append (addr, word);
				header_decode_lwsp (&inptr);
				g_free (word);
			} else {
				w (g_warning ("Invalid address spec: %s", *in));
			}
		}
		if (*inptr == '@') {
			inptr++;
			addr = g_string_append_c (addr, '@');
			word = header_decode_domain (&inptr);
			if (word) {
				addr = g_string_append (addr, word);
				g_free (word);
			} else {
				w (g_warning ("Invalid address, missing domain: %s", *in));
			}
		} else {
			w (g_warning ("Invalid addr-spec, missing @: %s", *in));
		}
	} else {
		w (g_warning ("invalid addr-spec, no local part"));
		g_string_free (addr, TRUE);

		return NULL;
	}

	/* FIXME: return null on error? */

	*in = inptr;
	word = addr->str;
	g_string_free (addr, FALSE);
	return word;
}

/*
 * address:
 * word *('.' word) @ domain |
 * *(word) '<' [ *('@' domain ) ':' ] word *( '.' word) @ domain |
 *
 * 1 * word ':'[ word ... etc (mailbox, as above) ] ';'
 */

/* mailbox:
 * word *( '.' word ) '@' domain
 * *(word) '<' [ *('@' domain ) ':' ] word *( '.' word) @ domain
 * */

static CamelHeaderAddress *
header_decode_mailbox (const gchar **in,
                       const gchar *charset)
{
	const gchar *inptr = *in;
	gchar *pre;
	gint closeme = FALSE;
	GString *addr;
	GString *name = NULL;
	CamelHeaderAddress *address = NULL;
	const gchar *comment = NULL;

	addr = g_string_new ("");

 start:
	/* for each address */
	pre = header_decode_word (&inptr);
	header_decode_lwsp (&inptr);
	if (!(*inptr == '.' || *inptr == '@' || *inptr == ',' || *inptr == '\0')) {
		/* ',' and '\0' required incase it is a simple address, no @ domain part (buggy writer) */
		if (!name)
			name = g_string_new ("");
		while (pre) {
			gchar *text, *last;

			/* perform internationalised decoding, and append */
			text = header_decode_text (pre, FALSE, charset);
			g_string_append (name, text);
			last = pre;
			g_free (text);

			pre = header_decode_word (&inptr);
			if (pre) {
				gsize l = strlen (last);
				gsize p = strlen (pre);

				/* dont append ' ' between sucsessive encoded words */
				if ((l > 6 && last[l - 2] == '?' && last[l - 1] == '=')
				    && (p > 6 && pre[0] == '=' && pre[1] == '?')) {
					/* dont append ' ' */
				} else {
					name = g_string_append_c (name, ' ');
				}
			} else {
				/* Fix for stupidly-broken-mailers that like to put '.''s in names unquoted */
				/* see bug #8147 */
				while (!pre && *inptr && *inptr != '<') {
					w (g_warning ("Working around stupid mailer bug #5: unescaped characters in names"));
					name = g_string_append_c (name, *inptr++);
					pre = header_decode_word (&inptr);
				}
			}
			g_free (last);
		}
		header_decode_lwsp (&inptr);
		if (*inptr == '<') {
			closeme = TRUE;
		try_address_again:
			inptr++;
			header_decode_lwsp (&inptr);
			if (*inptr == '@') {
				while (*inptr == '@') {
					inptr++;
					header_decode_domain (&inptr);
					header_decode_lwsp (&inptr);
					if (*inptr == ',') {
						inptr++;
						header_decode_lwsp (&inptr);
					}
				}
				if (*inptr == ':') {
					inptr++;
				} else {
					w (g_warning ("broken route-address, missing ':': %s", *in));
				}
			}
			pre = header_decode_word (&inptr);
			/*header_decode_lwsp(&inptr);*/
		} else {
			w (g_warning ("broken address? %s", *in));
		}
	}

	if (pre) {
		addr = g_string_append (addr, pre);
	} else {
		w (g_warning ("No local-part for email address: %s", *in));
	}

	/* should be at word '.' localpart */
	while (*inptr == '.' && pre) {
		inptr++;
		g_free (pre);
		pre = header_decode_word (&inptr);
		addr = g_string_append_c (addr, '.');
		if (pre)
			addr = g_string_append (addr, pre);
		comment = inptr;
		header_decode_lwsp (&inptr);
	}
	g_free (pre);

	/* now at '@' domain part */
	if (*inptr == '@') {
		gchar *dom;

		inptr++;
		addr = g_string_append_c (addr, '@');
		comment = inptr;
		dom = header_decode_domain (&inptr);
		addr = g_string_append (addr, dom);
		g_free (dom);
	} else if (*inptr != '>' || !closeme) {
		/* If we get a <, the address was probably a name part, lets try again shall we? */
		/* Another fix for seriously-broken-mailers */
		if (*inptr && *inptr != ',') {
			gchar *text;
			const gchar *name_part;
			gboolean in_quote;

			w (g_warning ("We didn't get an '@' where we expected in '%s', trying again", *in));
			w (g_warning ("Name is '%s', Addr is '%s' we're at '%s'\n", name ? name->str:"<UNSET>", addr->str, inptr));

			/* need to keep *inptr, as try_address_again will drop the current character */
			if (*inptr == '<')
				closeme = TRUE;
			else
				g_string_append_c (addr, *inptr);

			name_part = *in;
			in_quote = FALSE;
			while (*name_part && *name_part != ',') {
				if (*name_part == '\"')
					in_quote = !in_quote;
				else if (!in_quote && *name_part == '<')
					break;
				name_part++;
			}

			if (*name_part == '<' && ((!strchr (name_part, ',') && strchr (name_part, '>')) || (strchr (name_part, ',') > strchr (name_part, '>')))) {
				/* it's of a form "display-name <addr-spec>" */
				if (name)
					g_string_free (name, TRUE);
				name = NULL;
				g_string_free (addr, TRUE);

				if (name_part == *in)
					addr = g_string_new ("");
				else
					addr = g_string_new_len (*in, name_part - *in - (camel_mime_is_lwsp (name_part[-1]) ? 1 : 0));
			}

			/* check for address is encoded word ... */
			text = header_decode_text (addr->str, FALSE, charset);
			if (name == NULL) {
				name = addr;
				addr = g_string_new ("");
				if (text) {
					g_string_truncate (name, 0);
					g_string_append (name, text);
				}
			}/* else {
				g_string_append (name, text ? text : addr->str);
				g_string_truncate (addr, 0);
			}*/
			g_free (text);

			/* or maybe that we've added up a bunch of broken bits to make an encoded word */
			if ((text = rfc2047_decode_word (name->str, name->len, charset))) {
				g_string_truncate (name, 0);
				g_string_append (name, text);
				g_free (text);
			}

			goto try_address_again;
		}
		w (g_warning ("invalid address, no '@' domain part at %c: %s", *inptr, *in));
	}

	if (closeme) {
		header_decode_lwsp (&inptr);
		if (*inptr == '>') {
			inptr++;
		} else {
			w (g_warning ("invalid route address, no closing '>': %s", *in));
		}
	} else if (name == NULL && comment != NULL && inptr>comment) { /* check for comment after address */
		gchar *text, *tmp;
		const gchar *comstart, *comend;

		/* this is a bit messy, we go from the last known position, because
		 * decode_domain/etc skip over any comments on the way */
		/* FIXME: This wont detect comments inside the domain itself,
		 * but nobody seems to use that feature anyway ... */

		d (printf ("checking for comment from '%s'\n", comment));

		comstart = strchr (comment, '(');
		if (comstart) {
			comstart++;
			header_decode_lwsp (&inptr);
			comend = inptr - 1;
			while (comend > comstart && comend[0] != ')')
				comend--;

			if (comend > comstart) {
				d (printf ("  looking at subset '%.*s'\n", comend - comstart, comstart));
				tmp = g_strndup (comstart, comend - comstart);
				text = header_decode_text (tmp, FALSE, charset);
				name = g_string_new (text);
				g_free (tmp);
				g_free (text);
			}
		}
	}

	header_decode_lwsp (&inptr);

	if (*inptr && *inptr != ',') {
		if (addr->len > 0) {
			if (!name) {
				name = g_string_sized_new (addr->len + 5);
			} else {
				g_string_append_c (name, ' ');
			}

			g_string_append_c (name, '<');
			g_string_append (name, addr->str);
			g_string_append_c (name, '>');
			g_string_append_c (name, ' ');

			g_string_truncate (addr, 0);
		}

		goto start;
	}

	*in = inptr;

	if (name) {
		/* Trim any trailing spaces */
		while (name->len > 0 && name->str[name->len - 1] == ' ') {
			g_string_truncate (name, name->len - 1);
		}
	}

	if (addr->len > 0) {
		if (!g_utf8_validate (addr->str, addr->len, NULL)) {
			/* workaround for invalid addr-specs containing 8bit chars (see bug #42170 for details) */
			const gchar *locale_charset;
			GString *out;

			locale_charset = camel_iconv_locale_charset ();

			out = g_string_new ("");

			if ((charset == NULL || !append_8bit (out, addr->str, addr->len, charset))
			    && (locale_charset == NULL || !append_8bit (out, addr->str, addr->len, locale_charset)))
				append_latin1 (out, addr->str, addr->len);

			g_string_free (addr, TRUE);
			addr = out;
		}

		if (!name) {
			gchar *text;

			text = rfc2047_decode_word (addr->str, addr->len, charset);
			if (text) {
				g_string_truncate (addr, 0);
				g_string_append (addr, text);
				g_free (text);

				make_string_utf8_valid (addr->str, addr->len);
			}

		} else {
			make_string_utf8_valid (name->str, name->len);
		}

		address = camel_header_address_new_name (name ? name->str : "", addr->str);
	} else if (name) {
		/* A name-only address, might be something wrong, but include it anyway */
		make_string_utf8_valid (name->str, name->len);
		address = camel_header_address_new_name (name->str, "");
	}

	d (printf ("got mailbox: %s\n", addr->str));

	g_string_free (addr, TRUE);
	if (name)
		g_string_free (name, TRUE);

	return address;
}

static CamelHeaderAddress *
header_decode_address (const gchar **in,
                       const gchar *charset)
{
	const gchar *inptr = *in;
	gchar *pre;
	GString *group = g_string_new ("");
	CamelHeaderAddress *addr = NULL, *member;

	/* pre-scan, trying to work out format, discard results */
	header_decode_lwsp (&inptr);
	while ((pre = header_decode_word (&inptr))) {
		group = g_string_append (group, pre);
		group = g_string_append (group, " ");
		g_free (pre);
	}
	header_decode_lwsp (&inptr);
	if (*inptr == ':') {
		d (printf ("group detected: %s\n", group->str));
		addr = camel_header_address_new_group (group->str);
		/* that was a group spec, scan mailbox's */
		inptr++;
		/* FIXME: check rfc 2047 encodings of words, here or above in the loop */
		header_decode_lwsp (&inptr);
		if (*inptr != ';') {
			gint go = TRUE;
			do {
				member = header_decode_mailbox (&inptr, charset);
				if (member)
					camel_header_address_add_member (addr, member);
				header_decode_lwsp (&inptr);
				if (*inptr == ',')
					inptr++;
				else
					go = FALSE;
			} while (go);
			if (*inptr == ';') {
				inptr++;
			} else {
				w (g_warning ("Invalid group spec, missing closing ';': %s", *in));
			}
		} else {
			inptr++;
		}
		*in = inptr;
	} else {
		addr = header_decode_mailbox (in, charset);
	}

	g_string_free (group, TRUE);

	return addr;
}

static gchar *
header_msgid_decode_internal (const gchar **in)
{
	const gchar *inptr = *in;
	gchar *msgid = NULL;

	d (printf ("decoding Message-ID: '%s'\n", *in));

	header_decode_lwsp (&inptr);
	if (*inptr == '<') {
		inptr++;
		header_decode_lwsp (&inptr);
		msgid = header_decode_addrspec (&inptr);
		if (msgid) {
			header_decode_lwsp (&inptr);
			if (*inptr == '>') {
				inptr++;
			} else {
				w (g_warning ("Missing closing '>' on message id: %s", *in));
			}
		} else {
			w (g_warning ("Cannot find message id in: %s", *in));
		}
	} else {
		w (g_warning ("missing opening '<' on message id: %s", *in));
	}
	*in = inptr;

	return msgid;
}

/**
 * camel_header_msgid_decode:
 * @in: input string
 *
 * Extract a message-id token from @in.
 *
 * Returns: the msg-id
 **/
gchar *
camel_header_msgid_decode (const gchar *in)
{
	if (in == NULL)
		return NULL;

	return header_msgid_decode_internal (&in);
}

/**
 * camel_header_contentid_decode:
 * @in: input string
 *
 * Extract a content-id from @in.
 *
 * Returns: the extracted content-id
 **/
gchar *
camel_header_contentid_decode (const gchar *in)
{
	const gchar *inptr = in;
	gboolean at = FALSE;
	GString *addr;
	gchar *buf;

	d (printf ("decoding Content-ID: '%s'\n", in));

	header_decode_lwsp (&inptr);

	/* some lame mailers quote the Content-Id */
	if (*inptr == '"')
		inptr++;

	/* make sure the content-id is not "" which can happen if we get a
	 * content-id such as <.@> (which Eudora likes to use...) */
	if ((buf = camel_header_msgid_decode (inptr)) != NULL && *buf)
		return buf;

	g_free (buf);

	/* ugh, not a valid msg-id - try to get something useful out of it then? */
	inptr = in;
	header_decode_lwsp (&inptr);
	if (*inptr == '<') {
		inptr++;
		header_decode_lwsp (&inptr);
	}

	/* Eudora has been known to use <.@> as a content-id */
	if (!(buf = header_decode_word (&inptr)) && (*inptr == '\0' || !strchr (".@", *inptr)))
		return NULL;

	addr = g_string_new ("");
	header_decode_lwsp (&inptr);
	while (buf != NULL || *inptr == '.' || (*inptr == '@' && !at)) {
		if (buf != NULL) {
			g_string_append (addr, buf);
			g_free (buf);
			buf = NULL;
		}

		if (!at) {
			if (*inptr == '.') {
				g_string_append_c (addr, *inptr++);
				buf = header_decode_word (&inptr);
			} else if (*inptr == '@') {
				g_string_append_c (addr, *inptr++);
				buf = header_decode_word (&inptr);
				at = TRUE;
			}
		} else if (*inptr != '\0' && strchr (".[]", *inptr)) {
			g_string_append_c (addr, *inptr++);
			buf = header_decode_atom (&inptr);
		}

		header_decode_lwsp (&inptr);
	}

	buf = addr->str;
	g_string_free (addr, FALSE);

	return buf;
}

static void
header_references_decode_single (const gchar **in, GSList **list)
{
	const gchar *inptr = *in;
	gchar *id, *word;

	while (*inptr) {
		header_decode_lwsp (&inptr);
		if (*inptr == '<') {
			id = header_msgid_decode_internal (&inptr);
			if (id) {
				*list = g_slist_prepend (*list, id);
				break;
			}
		} else {
			word = header_decode_word (&inptr);
			if (word)
				g_free (word);
			else if (*inptr != '\0')
				inptr++; /* Stupid mailer tricks */
		}
	}

	*in = inptr;
}

/**
 * camel_header_references_decode:
 * @in: References header value
 *
 * Generate a list of references, from most recent up.
 *
 * Returns: (element-type utf8) (transfer full): a list of references decoedd from @in
 **/
GSList *
camel_header_references_decode (const gchar *in)
{
	GSList *refs = NULL;

	if (in == NULL || in[0] == '\0')
		return NULL;

	while (*in)
		header_references_decode_single (&in, &refs);

	return refs;
}

CamelHeaderAddress *
camel_header_mailbox_decode (const gchar *in,
                             const gchar *charset)
{
	if (in == NULL)
		return NULL;

	return header_decode_mailbox (&in, charset);
}

CamelHeaderAddress *
camel_header_address_decode (const gchar *in,
                             const gchar *charset)
{
	const gchar *inptr = in, *last;
	CamelHeaderAddress *list = NULL, *addr;

	d (printf ("decoding To: '%s'\n", in));

	if (in == NULL)
		return NULL;

	header_decode_lwsp (&inptr);
	if (*inptr == 0)
		return NULL;

	do {
		last = inptr;
		addr = header_decode_address (&inptr, charset);
		if (addr)
			camel_header_address_list_append (&list, addr);
		header_decode_lwsp (&inptr);
		if (*inptr == ',')
			inptr++;
		else
			break;
	} while (inptr != last);

	if (*inptr) {
		w (g_warning ("Invalid input detected at %c (%d): '%s'\n or at: '%s'", *inptr, (gint) (inptr - in), in, inptr));
	}

	if (inptr == last) {
		w (g_warning ("detected invalid input loop at : '%s' for '%s'", last, in));
	}

	return list;
}

/**
 * camel_header_newsgroups_decode:
 * @in:
 *
 * Returns: (element-type utf8) (transfer full):
 **/
GSList *
camel_header_newsgroups_decode (const gchar *in)
{
	const gchar *inptr = in;
	register gchar c;
	GSList *list = NULL;
	const gchar *start;

	do {
		header_decode_lwsp (&inptr);
		start = inptr;
		while ((c = *inptr++) && !camel_mime_is_lwsp (c) && c != ',')
			;
		if (start != inptr - 1) {
			list = g_slist_prepend (list, g_strndup (start, inptr - start - 1));
		}
	} while (c);

	return list;
}

/* this must be kept in sync with the header */
static const gchar *encodings[] = {
	"",
	"7bit",
	"8bit",
	"base64",
	"quoted-printable",
	"binary",
	"x-uuencode",
};

const gchar *
camel_transfer_encoding_to_string (CamelTransferEncoding encoding)
{
	if (encoding >= G_N_ELEMENTS (encodings))
		encoding = 0;

	return encodings[encoding];
}

CamelTransferEncoding
camel_transfer_encoding_from_string (const gchar *string)
{
	gint i;

	if (string != NULL) {
		for (i = 0; i < G_N_ELEMENTS (encodings); i++)
			if (!g_ascii_strcasecmp (string, encodings[i]))
				return i;
	}

	return CAMEL_TRANSFER_ENCODING_DEFAULT;
}

void
camel_header_mime_decode (const gchar *in,
                          gint *maj,
                          gint *min)
{
	const gchar *inptr = in;
	gint major=-1, minor=-1;

	d (printf ("decoding MIME-Version: '%s'\n", in));

	if (in != NULL) {
		header_decode_lwsp (&inptr);
		if (isdigit (*inptr)) {
			major = camel_header_decode_int (&inptr);
			header_decode_lwsp (&inptr);
			if (*inptr == '.') {
				inptr++;
				header_decode_lwsp (&inptr);
				if (isdigit (*inptr))
					minor = camel_header_decode_int (&inptr);
			}
		}
	}

	if (maj)
		*maj = major;
	if (min)
		*min = minor;

	d (printf ("major = %d, minor = %d\n", major, minor));
}

struct _rfc2184_param {
	struct _camel_header_param param;
	gint index;
};

static gint
rfc2184_param_cmp (gconstpointer ap,
                   gconstpointer bp)
{
	const struct _rfc2184_param *a = *(gpointer *) ap;
	const struct _rfc2184_param *b = *(gpointer *) bp;
	gint res;

	res = strcmp (a->param.name, b->param.name);
	if (res == 0) {
		if (a->index > b->index)
			res = 1;
		else if (a->index < b->index)
			res = -1;
	}

	return res;
}

/* NB: Steals name and value */
static struct _camel_header_param *
header_append_param (struct _camel_header_param *last,
                     gchar *name,
                     gchar *value)
{
	struct _camel_header_param *node;

	/* This handles -
	 *  8 bit data in parameters, illegal, tries to convert using locale, or just safens it up.
	 *  rfc2047 ecoded parameters, illegal, decodes them anyway.  Some Outlook & Mozilla do this?
	*/
	node = g_malloc (sizeof (*node));
	last->next = node;
	node->next = NULL;
	node->name = name;
	if (strncmp (value, "=?", 2) == 0
	    && (node->value = header_decode_text (value, FALSE, NULL))) {
		g_free (value);
	} else if (g_ascii_strcasecmp (name, "boundary") != 0 && !g_utf8_validate (value, -1, NULL)) {
		const gchar *charset = camel_iconv_locale_charset ();

		if ((node->value = header_convert ("UTF-8", charset ? charset:"ISO-8859-1", value, strlen (value)))) {
			g_free (value);
		} else {
			node->value = value;
			for (;*value; value++)
				if (!isascii ((guchar) * value))
					*value = '_';
		}
	} else
		node->value = value;

	return node;
}

static struct _camel_header_param *
header_decode_param_list (const gchar **in)
{
	struct _camel_header_param *head = NULL, *last = (struct _camel_header_param *) &head;
	GPtrArray *split = NULL;
	const gchar *inptr = *in;
	struct _rfc2184_param *work;
	gchar *tmp;

	/* Dump parameters into the output list, in the order found.  RFC 2184 split parameters are kept in an array */
	header_decode_lwsp (&inptr);
	while (*inptr == ';') {
		gchar *name;
		gchar *value = NULL;

		inptr++;
		name = decode_token (&inptr);
		header_decode_lwsp (&inptr);
		if (*inptr == '=') {
			inptr++;
			value = header_decode_value (&inptr);
		}

		if (name && value) {
			gchar *index = strchr (name, '*');

			if (index) {
				if (index[1] == 0) {
					/* VAL*="foo", decode immediately and append */
					*index = 0;
					tmp = rfc2184_decode (value, strlen (value));
					if (tmp) {
						g_free (value);
						value = tmp;
					}
					last = header_append_param (last, name, value);
				} else {
					/* VAL*1="foo", save for later */
					*index++ = 0;
					work = g_malloc (sizeof (*work));
					work->param.name = name;
					work->param.value = value;
					work->index = atoi (index);
					if (split == NULL)
						split = g_ptr_array_new ();
					g_ptr_array_add (split, work);
				}
			} else {
				last = header_append_param (last, name, value);
			}
		} else {
			g_free (name);
			g_free (value);
		}

		header_decode_lwsp (&inptr);
	}

	/* Rejoin any RFC 2184 split parameters in the proper order */
	/* Parameters with the same index will be concatenated in undefined order */
	if (split) {
		GString *value = g_string_new ("");
		struct _rfc2184_param *first;
		gint i;

		qsort (split->pdata, split->len, sizeof (split->pdata[0]), rfc2184_param_cmp);
		first = split->pdata[0];
		for (i = 0; i < split->len; i++) {
			work = split->pdata[i];
			if (split->len - 1 == i)
				g_string_append (value, work->param.value);
			if (split->len - 1 == i || strcmp (work->param.name, first->param.name) != 0) {
				tmp = rfc2184_decode (value->str, value->len);
				if (tmp == NULL)
					tmp = g_strdup (value->str);

				last = header_append_param (last, g_strdup (first->param.name), tmp);
				g_string_truncate (value, 0);
				first = work;
			}
			if (split->len - 1 != i)
				g_string_append (value, work->param.value);
		}
		g_string_free (value, TRUE);
		for (i = 0; i < split->len; i++) {
			work = split->pdata[i];
			g_free (work->param.name);
			g_free (work->param.value);
			g_free (work);
		}
		g_ptr_array_free (split, TRUE);
	}

	*in = inptr;

	return head;
}

/**
 * camel_header_param_list_decode:
 * @in: (nullable): a header param value to decode
 *
 * Returns: (nullable) (transfer full): Decode list of parameters.
 *    Free with camel_header_param_list_free() when done with it.
 **/
struct _camel_header_param *
camel_header_param_list_decode (const gchar *in)
{
	if (in == NULL)
		return NULL;

	return header_decode_param_list (&in);
}

static gchar *
header_encode_param (const guchar *in,
                     gboolean *encoded,
                     gboolean is_filename)
{
	const guchar *inptr = in;
	guchar *outbuf = NULL;
	const gchar *charset;
	GString *out;
	guint32 c;
	gchar *str;

	*encoded = FALSE;

	g_return_val_if_fail (in != NULL, NULL);

	if (is_filename) {
		if (!g_utf8_validate ((gchar *) inptr, -1, NULL)) {
			GString *buff = g_string_new ("");

			for (; inptr && *inptr; inptr++) {
				if (*inptr < 32)
					g_string_append_printf (buff, "%%%02X", (*inptr) & 0xFF);
				else
					g_string_append_c (buff, *inptr);
			}

			outbuf = (guchar *) g_string_free (buff, FALSE);
			inptr = outbuf;
		}

		/* do not set encoded flag for file names */
		str = header_encode_string_rfc2047 (inptr, TRUE);
		g_free (outbuf);

		return str;
	}

	/* if we have really broken utf8 passed in, we just treat it as binary data */

	charset = camel_charset_best ((gchar *) in, strlen ((gchar *) in));
	if (charset == NULL) {
		return g_strdup ((gchar *) in);
	}

	if (g_ascii_strcasecmp (charset, "UTF-8") != 0) {
		if ((outbuf = (guchar *) header_convert (charset, "UTF-8", (const gchar *) in, strlen ((gchar *) in))))
			inptr = outbuf;
		else
			return g_strdup ((gchar *) in);
	}

	/* FIXME: set the 'language' as well, assuming we can get that info...? */
	out = g_string_new (charset);
	g_string_append (out, "''");

	while ((c = *inptr++)) {
		if (camel_mime_is_attrchar (c))
			g_string_append_c (out, c);
		else
			g_string_append_printf (out, "%%%c%c", tohex[(c >> 4) & 0xf], tohex[c & 0xf]);
	}
	g_free (outbuf);

	str = out->str;
	g_string_free (out, FALSE);
	*encoded = TRUE;

	return str;
}

/* HACK: Set to non-zero when you want the 'filename' and 'name' headers encoded in RFC 2047 way,
 * otherwise they will be encoded in the correct RFC 2231 way. It's because Outlook and GMail
 * do not understand the correct standard and refuse attachments with localized name sent
 * from evolution. This seems to have been fixed in Exchange 2007 at least - not sure about
 * standalone Outlook. */
gint camel_header_param_encode_filenames_in_rfc_2047 = 0;

void
camel_header_param_list_format_append (GString *out,
                                       struct _camel_header_param *p)
{
	gint used = out->len;

	while (p) {
		gboolean is_filename = camel_header_param_encode_filenames_in_rfc_2047 && (g_ascii_strcasecmp (p->name, "filename") == 0 || g_ascii_strcasecmp (p->name, "name") == 0);
		gboolean encoded = FALSE;
		gboolean quote = FALSE;
		gint here = out->len;
		gsize nlen, vlen;
		gchar *value;

		if (!p->value) {
			p = p->next;
			continue;
		}

		value = header_encode_param ((guchar *) p->value, &encoded, is_filename);
		if (!value) {
			w (g_warning ("appending parameter %s=%s violates rfc2184", p->name, p->value));
			value = g_strdup (p->value);
		}

		if (!encoded) {
			gchar *ch;

			for (ch = value; ch && *ch; ch++) {
				if (camel_mime_is_tspecial (*ch) || camel_mime_is_lwsp (*ch))
					break;
			}

			quote = ch && *ch;
		}

		quote = quote || is_filename;
		nlen = strlen (p->name);
		vlen = strlen (value);

		/* do not fold file names */
		if (!is_filename && used + nlen + vlen > CAMEL_FOLD_SIZE - 8) {
			out = g_string_append (out, ";\n\t");
			here = out->len;
			used = 0;
		} else
			out = g_string_append (out, "; ");

		if (!is_filename && nlen + vlen > CAMEL_FOLD_SIZE - 8) {
			/* we need to do special rfc2184 parameter wrapping */
			gint maxlen = CAMEL_FOLD_SIZE - (nlen + 8);
			gchar *inptr, *inend;
			gint i = 0;

			inptr = value;
			inend = value + vlen;

			while (inptr < inend) {
				gchar *ptr = inptr + MIN (inend - inptr, maxlen);

				if (encoded && ptr < inend) {
					/* be careful not to break an encoded gchar (ie %20) */
					gchar *q = ptr;
					gint j = 2;

					for (; j > 0 && q > inptr && *q != '%'; j--, q--);
					if (*q == '%')
						ptr = q;
				}

				if (i != 0) {
					g_string_append (out, ";\n\t");
					here = out->len;
					used = 0;
				}

				g_string_append_printf (out, "%s*%d%s=", p->name, i++, encoded ? "*" : "");
				if (encoded || !quote)
					g_string_append_len (out, inptr, ptr - inptr);
				else
					quote_word (out, TRUE, inptr, ptr - inptr);

				d (printf ("wrote: %s\n", out->str + here));

				used += (out->len - here);

				inptr = ptr;
			}
		} else {
			g_string_append_printf (out, "%s%s=", p->name, encoded ? "*" : "");

			/* Quote even if we don't need to in order to
			 * work around broken mail software like the
			 * Jive Forums' NNTP gateway */
			if (encoded /*|| !quote */)
				g_string_append (out, value);
			else
				quote_word (out, TRUE, value, vlen);

			used += (out->len - here);
		}

		g_free (value);

		p = p->next;
	}
}

gchar *
camel_header_param_list_format (struct _camel_header_param *p)
{
	GString *out = g_string_new ("");
	gchar *ret;

	camel_header_param_list_format_append (out, p);
	ret = out->str;
	g_string_free (out, FALSE);
	return ret;
}

CamelContentType *
camel_content_type_decode (const gchar *in)
{
	const gchar *inptr = in;
	gchar *type, *subtype = NULL;
	CamelContentType *t = NULL;

	if (in == NULL)
		return NULL;

	type = decode_token (&inptr);
	header_decode_lwsp (&inptr);
	if (type) {
		if  (*inptr == '/') {
			inptr++;
			subtype = decode_token (&inptr);
		}
		if (subtype == NULL && (!g_ascii_strcasecmp (type, "text"))) {
			w (g_warning ("text type with no subtype, resorting to text/plain: %s", in));
			subtype = g_strdup ("plain");
		}
		if (subtype == NULL) {
			w (g_warning ("MIME type with no subtype: %s", in));
		}

		t = camel_content_type_new (type, subtype);
		t->params = header_decode_param_list (&inptr);
		g_free (type);
		g_free (subtype);
	} else {
		g_free (type);
		d (printf ("cannot find MIME type in header (2) '%s'", in));
	}
	return t;
}

void
camel_content_type_dump (CamelContentType *ct)
{
	struct _camel_header_param *p;

	printf ("Content-Type: ");
	if (ct == NULL) {
		printf ("<NULL>\n");
		return;
	}
	printf ("%s / %s", ct->type, ct->subtype);
	p = ct->params;
	if (p) {
		while (p) {
			printf (";\n\t%s=\"%s\"", p->name, p->value);
			p = p->next;
		}
	}
	printf ("\n");
}

gchar *
camel_content_type_format (CamelContentType *ct)
{
	GString *out;
	gchar *ret;

	if (ct == NULL)
		return NULL;

	out = g_string_new ("");
	if (ct->type == NULL) {
		g_string_append_printf (out, "text/plain");
		w (g_warning ("Content-Type with no main type"));
	} else if (ct->subtype == NULL) {
		w (g_warning ("Content-Type with no sub type: %s", ct->type));
		if (!g_ascii_strcasecmp (ct->type, "multipart"))
			g_string_append_printf (out, "%s/mixed", ct->type);
		else
			g_string_append_printf (out, "%s", ct->type);
	} else {
		g_string_append_printf (out, "%s/%s", ct->type, ct->subtype);
	}
	camel_header_param_list_format_append (out, ct->params);

	ret = out->str;
	g_string_free (out, FALSE);

	return ret;
}

gchar *
camel_content_type_simple (CamelContentType *ct)
{
	if (!ct)
		return NULL;

	if (ct->type == NULL) {
		w (g_warning ("Content-Type with no main type"));
		return g_strdup ("text/plain");
	} else if (ct->subtype == NULL) {
		w (g_warning ("Content-Type with no sub type: %s", ct->type));
		if (!g_ascii_strcasecmp (ct->type, "multipart"))
			return g_strdup_printf ("%s/mixed", ct->type);
		else
			return g_strdup (ct->type);
	} else
		return g_strdup_printf ("%s/%s", ct->type, ct->subtype);
}

gchar *
camel_content_transfer_encoding_decode (const gchar *in)
{
	if (in)
		return decode_token (&in);

	return NULL;
}

CamelContentDisposition *
camel_content_disposition_new (void)
{
	CamelContentDisposition *dd;

	dd = g_malloc0 (sizeof (CamelContentDisposition));
	dd->refcount = 1;
	dd->disposition = NULL;
	dd->params = NULL;

	return dd;
}

CamelContentDisposition *
camel_content_disposition_decode (const gchar *in)
{
	CamelContentDisposition *d = NULL;
	const gchar *inptr = in;

	if (in == NULL)
		return NULL;

	d = camel_content_disposition_new ();
	d->disposition = decode_token (&inptr);
	if (d->disposition == NULL) {
		w (g_warning ("Empty disposition type"));
	}
	d->params = header_decode_param_list (&inptr);
	return d;
}

CamelContentDisposition *
camel_content_disposition_ref (CamelContentDisposition *d)
{
	if (d)
		d->refcount++;

	return d;
}

void
camel_content_disposition_unref (CamelContentDisposition *d)
{
	if (d) {
		if (d->refcount <= 1) {
			camel_header_param_list_free (d->params);
			g_free (d->disposition);
			g_free (d);
		} else {
			d->refcount--;
		}
	}
}

gchar *
camel_content_disposition_format (CamelContentDisposition *d)
{
	GString *out;
	gchar *ret;

	if (d == NULL)
		return NULL;

	out = g_string_new ("");
	if (d->disposition)
		out = g_string_append (out, d->disposition);
	else
		out = g_string_append (out, "attachment");
	camel_header_param_list_format_append (out, d->params);

	ret = out->str;
	g_string_free (out, FALSE);
	return ret;
}

gboolean
camel_content_disposition_is_attachment (const CamelContentDisposition *disposition,
					 const CamelContentType *content_type)
{
	return camel_content_disposition_is_attachment_ex (disposition, content_type, NULL);
}

gboolean
camel_content_disposition_is_attachment_ex (const CamelContentDisposition *disposition,
					    const CamelContentType *content_type,
					    const CamelContentType *parent_content_type)
{
	if (content_type && (
	    camel_content_type_is (content_type, "application", "xpkcs7mime") ||
	    camel_content_type_is (content_type, "application", "x-pkcs7-mime") ||
	    camel_content_type_is (content_type, "application", "pkcs7-mime")))
		return FALSE;

	if (content_type && (
	    camel_content_type_is (content_type, "application", "pgp-encrypted")))
		return !parent_content_type || !camel_content_type_is (parent_content_type, "multipart", "encrypted");

	if (content_type && camel_content_type_is (content_type, "application", "octet-stream") &&
	    parent_content_type && camel_content_type_is (parent_content_type, "multipart", "encrypted"))
		return FALSE;

	if (content_type && (
	    camel_content_type_is (content_type, "application", "pkcs7-signature") ||
	    camel_content_type_is (content_type, "application", "xpkcs7-signature") ||
	    camel_content_type_is (content_type, "application", "x-pkcs7-signature") ||
	    camel_content_type_is (content_type, "application", "pkcs7-signature") ||
	    camel_content_type_is (content_type, "application", "pgp-signature")))
		return !parent_content_type || !camel_content_type_is (parent_content_type, "multipart", "signed");

	if (parent_content_type && content_type && camel_content_type_is (content_type, "message", "rfc822"))
		return TRUE;

	if (!disposition)
		return FALSE;

	if (disposition->disposition && g_ascii_strcasecmp (disposition->disposition, "attachment") == 0)
		return TRUE;

	/* If the Content-Disposition isn't an attachment, then call everything with a "filename"
	   parameter an attachment, but only if there is no Content-Disposition header, or it's
	   not the "inline" or it's neither text/... nor image/... Content-Type, which can be usually
	   shown in the UI inline.

	   The test for Content-Type was added for Apple Mail, which marks also for example .pdf
	   attachments as 'inline', which broke the previous logic here.
	*/
	if (!disposition->disposition ||
	    g_ascii_strcasecmp (disposition->disposition, "inline") != 0 ||
	    (content_type && !camel_content_type_is (content_type, "text", "*") && !camel_content_type_is (content_type, "image", "*"))) {
		const struct _camel_header_param *param;

		for (param = disposition->params; param; param = param->next) {
			if (param->name && param->value && *param->value && g_ascii_strcasecmp (param->name, "filename") == 0)
				return TRUE;
		}
	}

	return FALSE;
}

/* date parser macros */
#define NUMERIC_CHARS          "1234567890"
#define WEEKDAY_CHARS          "SundayMondayTuesdayWednesdayThursdayFridaySaturday"
#define MONTH_CHARS            "JanuaryFebruaryMarchAprilMayJuneJulyAugustSeptemberOctoberNovemberDecember"
#define TIMEZONE_ALPHA_CHARS   "UTCGMTESTEDTCSTCDTMSTPSTPDTZAMNY()"
#define TIMEZONE_NUMERIC_CHARS "-+1234567890"
#define TIME_CHARS             "1234567890:"

#define DATE_TOKEN_NON_NUMERIC          (1 << 0)
#define DATE_TOKEN_NON_WEEKDAY          (1 << 1)
#define DATE_TOKEN_NON_MONTH            (1 << 2)
#define DATE_TOKEN_NON_TIME             (1 << 3)
#define DATE_TOKEN_HAS_COLON            (1 << 4)
#define DATE_TOKEN_NON_TIMEZONE_ALPHA   (1 << 5)
#define DATE_TOKEN_NON_TIMEZONE_NUMERIC (1 << 6)
#define DATE_TOKEN_HAS_SIGN             (1 << 7)

static guchar camel_datetok_table[256] = {
	128,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,
	111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,
	111,111,111,111,111,111,111,111, 79, 79,111,175,111,175,111,111,
	 38, 38, 38, 38, 38, 38, 38, 38, 38, 38,119,111,111,111,111,111,
	111, 75,111, 79, 75, 79,105, 79,111,111,107,111,111, 73, 75,107,
	 79,111,111, 73, 77, 79,111,109,111, 79, 79,111,111,111,111,111,
	111,105,107,107,109,105,111,107,105,105,111,111,107,107,105,105,
	107,111,105,105,105,105,107,111,111,105,111,111,111,111,111,111,
	111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,
	111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,
	111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,
	111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,
	111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,
	111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,
	111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,
	111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,111,
};

static struct {
	const gchar *name;
	gint offset;
} tz_offsets[] = {
	{ "UT", 0 },
	{ "GMT", 0 },
	{ "EST", -500 },	/* these are all US timezones.  bloody yanks */
	{ "EDT", -400 },
	{ "CST", -600 },
	{ "CDT", -500 },
	{ "MST", -700 },
	{ "MDT", -600 },
	{ "PST", -800 },
	{ "PDT", -700 },
	{ "Z", 0 },
	{ "A", -100 },
	{ "M", -1200 },
	{ "N", 100 },
	{ "Y", 1200 },
};

static const gchar tm_months[][4] = {
	"Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};

static const gchar tm_days[][4] = {
	"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
};

/**
 * camel_header_format_date:
 * @date: time_t date representation
 * @tz_offset: Timezone offset
 *
 * Allocates a string buffer containing the rfc822 formatted date
 * string represented by @time and @tz_offset.
 *
 * Returns: a valid string representation of the date.
 **/
gchar *
camel_header_format_date (time_t date,
                          gint tz_offset)
{
	struct tm tm;

	d (printf ("offset = %d\n", tz_offset));

	d (printf ("converting date %s", ctime (&date)));

	date += ((tz_offset / 100) * (60 * 60)) + (tz_offset % 100) * 60;

	d (printf ("converting date %s", ctime (&date)));

	gmtime_r (&date, &tm);

	return g_strdup_printf (
		"%s, %02d %s %04d %02d:%02d:%02d %+05d",
		tm_days[tm.tm_wday],
		tm.tm_mday,
		tm_months[tm.tm_mon],
		tm.tm_year + 1900,
		tm.tm_hour,
		tm.tm_min,
		tm.tm_sec,
		tz_offset);
}

/* This is where it gets ugly... */

struct _date_token {
	struct _date_token *next;
	guchar mask;
	const gchar *start;
	gsize len;
};

static struct _date_token *
datetok (const gchar *date)
{
	struct _date_token *tokens = NULL, *token, *tail = (struct _date_token *) &tokens;
	const gchar *start, *end;
	guchar mask;

	start = date;
	while (*start) {
		/* kill leading whitespace */
		while (*start == ' ' || *start == '\t')
			start++;

		if (*start == '\0')
			break;

		mask = camel_datetok_table[(guchar) *start];

		/* find the end of this token */
		end = start + 1;
		while (*end && !strchr ("-/,\t\r\n ", *end))
			mask |= camel_datetok_table[(guchar) *end++];

		if (end != start) {
			token = g_malloc (sizeof (struct _date_token));
			token->next = NULL;
			token->start = start;
			token->len = end - start;
			token->mask = mask;

			tail->next = token;
			tail = token;
		}

		if (*end)
			start = end + 1;
		else
			break;
	}

	return tokens;
}

static gint
decode_int (const gchar *in,
            gsize inlen)
{
	register const gchar *inptr;
	gint sign = 1, val = 0;
	const gchar *inend;

	inptr = in;
	inend = in + inlen;

	if (*inptr == '-') {
		sign = -1;
		inptr++;
	} else if (*inptr == '+')
		inptr++;

	for (; inptr < inend; inptr++) {
		if (!(*inptr >= '0' && *inptr <= '9'))
			return -1;
		else
			val = (val * 10) + (*inptr - '0');
	}

	val *= sign;

	return val;
}

#if 0
static gint
get_days_in_month (gint month,
                   gint year)
{
	switch (month) {
	case 1:
	case 3:
	case 5:
	case 7:
	case 8:
	case 10:
	case 12:
		return 31;
	case 4:
	case 6:
	case 9:
	case 11:
		return 30;
	case 2:
		if (g_date_is_leap_year (year))
			return 29;
		else
			return 28;
	default:
		return 0;
	}
}
#endif

static gint
get_wday (const gchar *in,
          gsize inlen)
{
	gint wday;

	g_return_val_if_fail (in != NULL, -1);

	if (inlen < 3)
		return -1;

	for (wday = 0; wday < 7; wday++) {
		if (!g_ascii_strncasecmp (in, tm_days[wday], 3))
			return wday;
	}

	return -1;  /* unknown week day */
}

static gint
get_mday (const gchar *in,
          gsize inlen)
{
	gint mday;

	g_return_val_if_fail (in != NULL, -1);

	mday = decode_int (in, inlen);

	if (mday < 0 || mday > 31)
		mday = -1;

	return mday;
}

static gint
get_month (const gchar *in,
           gsize inlen)
{
	gint i;

	g_return_val_if_fail (in != NULL, -1);

	if (inlen < 3)
		return -1;

	for (i = 0; i < 12; i++) {
		if (!g_ascii_strncasecmp (in, tm_months[i], 3))
			return i;
	}

	return -1;  /* unknown month */
}

static gint
get_year (const gchar *in,
          gsize inlen)
{
	gint year;

	g_return_val_if_fail (in != NULL, -1);

	if ((year = decode_int (in, inlen)) == -1)
		return -1;

	if (year < 100)
		year += (year < 70) ? 2000 : 1900;

	if (year < 1969)
		return -1;

	return year;
}

static gboolean
get_time (const gchar *in,
          gsize inlen,
          gint *hour,
          gint *min,
          gint *sec)
{
	register const gchar *inptr;
	gint *val, colons = 0;
	const gchar *inend;

	*hour = *min = *sec = 0;

	inend = in + inlen;
	val = hour;
	for (inptr = in; inptr < inend; inptr++) {
		if (*inptr == ':') {
			colons++;
			switch (colons) {
			case 1:
				val = min;
				break;
			case 2:
				val = sec;
				break;
			default:
				return FALSE;
			}
		} else if (!(*inptr >= '0' && *inptr <= '9'))
			return FALSE;
		else
			*val = (*val * 10) + (*inptr - '0');
	}

	return TRUE;
}

static gint
get_tzone (struct _date_token **token)
{
	const gchar *inptr, *inend;
	gsize inlen;
	gint i, t;

	for (i = 0; *token && i < 2; *token = (*token)->next, i++) {
		inptr = (*token)->start;
		inlen = (*token)->len;
		inend = inptr + inlen;

		if (*inptr == '+' || *inptr == '-') {
			return decode_int (inptr, inlen);
		} else {
			if (*inptr == '(') {
				inptr++;
				if (*(inend - 1) == ')')
					inlen -= 2;
				else
					inlen--;
			}

			for (t = 0; t < 15; t++) {
				gsize len = strlen (tz_offsets[t].name);

				if (len != inlen)
					continue;

				if (!strncmp (inptr, tz_offsets[t].name, len))
					return tz_offsets[t].offset;
			}
		}
	}

	return -1;
}

static time_t
parse_rfc822_date (struct _date_token *tokens,
                   gint *tzone)
{
	gint hour, min, sec, offset, n;
	struct _date_token *token;
	struct tm tm;
	time_t t;

	g_return_val_if_fail (tokens != NULL, (time_t) 0);

	token = tokens;

	memset ((gpointer) &tm, 0, sizeof (struct tm));

	if ((n = get_wday (token->start, token->len)) != -1) {
		/* not all dates may have this... */
		tm.tm_wday = n;
		token = token->next;
	}

	/* get the mday */
	if (!token || (n = get_mday (token->start, token->len)) == -1)
		return (time_t) 0;

	tm.tm_mday = n;
	token = token->next;

	/* get the month */
	if (!token || (n = get_month (token->start, token->len)) == -1)
		return (time_t) 0;

	tm.tm_mon = n;
	token = token->next;

	/* get the year */
	if (!token || (n = get_year (token->start, token->len)) == -1)
		return (time_t) 0;

	tm.tm_year = n - 1900;
	token = token->next;

	/* get the hour/min/sec */
	if (!token || !get_time (token->start, token->len, &hour, &min, &sec))
		return (time_t) 0;

	tm.tm_hour = hour;
	tm.tm_min = min;
	tm.tm_sec = sec;
	token = token->next;

	if (token && token->start && (
	    g_ascii_strncasecmp (token->start, "AM", 2) == 0 ||
	    g_ascii_strncasecmp (token->start, "PM", 2) == 0)) {
		/* not a valid RFC 822 time representation */
		return 0;
	}

	/* get the timezone */
	if (!token || (n = get_tzone (&token)) == -1) {
		/* I guess we assume tz is GMT? */
		offset = 0;
	} else {
		offset = n;
	}

	t = camel_mktime_utc (&tm);

	/* t is now GMT of the time we want, but not offset by the timezone ... */

	/* this should convert the time to the GMT equiv time */
	t -= ((offset / 100) * 60 * 60) + (offset % 100) * 60;

	if (tzone)
		*tzone = offset;

	return t;
}

#define date_token_mask(t)  (((struct _date_token *) t)->mask)
#define is_numeric(t)       ((date_token_mask (t) & DATE_TOKEN_NON_NUMERIC) == 0)
#define is_weekday(t)       ((date_token_mask (t) & DATE_TOKEN_NON_WEEKDAY) == 0)
#define is_month(t)         ((date_token_mask (t) & DATE_TOKEN_NON_MONTH) == 0)
#define is_time(t)          (((date_token_mask (t) & DATE_TOKEN_NON_TIME) == 0) && (date_token_mask (t) & DATE_TOKEN_HAS_COLON))
#define is_tzone_alpha(t)   ((date_token_mask (t) & DATE_TOKEN_NON_TIMEZONE_ALPHA) == 0)
#define is_tzone_numeric(t) (((date_token_mask (t) & DATE_TOKEN_NON_TIMEZONE_NUMERIC) == 0) && (date_token_mask (t) & DATE_TOKEN_HAS_SIGN))
#define is_tzone(t)         (is_tzone_alpha (t) || is_tzone_numeric (t))

static time_t
parse_broken_date (struct _date_token *tokens,
                   gint *tzone)
{
	gboolean got_wday, got_month, got_tzone, is_pm;
	gint hour, min, sec, offset, n;
	struct _date_token *token;
	struct tm tm;
	time_t t;

	memset ((gpointer) &tm, 0, sizeof (struct tm));
	got_wday = got_month = got_tzone = FALSE;
	is_pm = FALSE;
	offset = 0;

	token = tokens;
	while (token) {
		if (is_weekday (token) && !got_wday) {
			if ((n = get_wday (token->start, token->len)) != -1) {
				d (printf ("weekday; "));
				got_wday = TRUE;
				tm.tm_wday = n;
				goto next;
			}
		}

		if (is_month (token) && !got_month) {
			if ((n = get_month (token->start, token->len)) != -1) {
				d (printf ("month; "));
				got_month = TRUE;
				tm.tm_mon = n;
				goto next;
			}
		}

		if (is_time (token) && !tm.tm_hour && !tm.tm_min && !tm.tm_sec) {
			if (get_time (token->start, token->len, &hour, &min, &sec)) {
				d (printf ("time; "));
				tm.tm_hour = hour;
				tm.tm_min = min;
				tm.tm_sec = sec;
				goto next;
			}
		}

		if (!got_tzone && token->start && (
		    g_ascii_strncasecmp (token->start, "AM", 2) == 0 ||
		    g_ascii_strncasecmp (token->start, "PM", 2) == 0)) {
			is_pm = g_ascii_strncasecmp (token->start, "PM", 2) == 0;

			goto next;
		}

		if (is_tzone (token) && !got_tzone) {
			struct _date_token *t = token;

			if ((n = get_tzone (&t)) != -1) {
				d (printf ("tzone; "));
				got_tzone = TRUE;
				offset = n;
				goto next;
			}
		}

		if (is_numeric (token)) {
			if (token->len == 4 && !tm.tm_year) {
				if ((n = get_year (token->start, token->len)) != -1) {
					d (printf ("year; "));
					tm.tm_year = n - 1900;
					goto next;
				}
			} else {
				/* Note: assumes MM-DD-YY ordering if '0 < MM < 12' holds true */
				if (!got_month && token->next && is_numeric (token->next)) {
					if ((n = decode_int (token->start, token->len)) > 12) {
						goto mday;
					} else if (n > 0) {
						d (printf ("mon; "));
						got_month = TRUE;
						tm.tm_mon = n - 1;
					}
					goto next;
				} else if (!tm.tm_mday && (n = get_mday (token->start, token->len)) != -1) {
				mday:
					d (printf ("mday; "));
					tm.tm_mday = n;
					goto next;
				} else if (!tm.tm_year) {
					if ((n = get_year (token->start, token->len)) != -1) {
						d (printf ("2-digit year; "));
						tm.tm_year = n - 1900;
					}
					goto next;
				}
			}
		}

		d (printf ("???; "));

	next:

		token = token->next;
	}

	d (printf ("\n"));

	t = camel_mktime_utc (&tm);

	/* t is now GMT of the time we want, but not offset by the timezone ... */

	/* this should convert the time to the GMT equiv time */
	t -= ((offset / 100) * 60 * 60) + (offset % 100) * 60;

	if (is_pm)
		t += 12 * 60 * 60;

	if (tzone)
		*tzone = offset;

	return t;
}

/**
 * camel_header_decode_date:
 * @str: input date string
 * @tz_offset: timezone offset
 *
 * Decodes the rfc822 date string and saves the GMT offset into
 * @tz_offset if non-NULL.
 *
 * Returns: the time_t representation of the date string specified by
 * @str or (time_t) 0 on error. If @tz_offset is non-NULL, the value
 * of the timezone offset will be stored.
 **/
time_t
camel_header_decode_date (const gchar *str,
                          gint *tz_offset)
{
	struct _date_token *token, *tokens;
	time_t date;

	if (!str || !(tokens = datetok (str))) {
		if (tz_offset)
			*tz_offset = 0;

		return (time_t) 0;
	}

	if (!(date = parse_rfc822_date (tokens, tz_offset)))
		date = parse_broken_date (tokens, tz_offset);

	/* cleanup */
	while (tokens) {
		token = tokens;
		tokens = tokens->next;
		g_free (token);
	}

	return date;
}

gchar *
camel_header_location_decode (const gchar *in)
{
	gint quote = 0;
	GString *out = g_string_new ("");
	gchar c, *res;

	/* Sigh. RFC2557 says:
	 *   content-location =   "Content-Location:" [CFWS] URI [CFWS]
	 *      where URI is restricted to the syntax for URLs as
	 *      defined in Uniform Resource Locators [URL] until
	 *      IETF specifies other kinds of URIs.
	 *
	 * But Netscape puts quotes around the URI when sending web
	 * pages.
	 *
	 * Which is required as defined in rfc2017 [3.1].  Although
	 * outlook doesn't do this.
	 *
	 * Since we get headers already unfolded, we need just drop
	 * all whitespace.  URL's cannot contain whitespace or quoted
	 * characters, even when included in quotes.
	 */

	header_decode_lwsp (&in);
	if (*in == '"') {
		in++;
		quote = 1;
	}

	while ((c = *in++)) {
		if (quote && c == '"')
			break;
		if (!camel_mime_is_lwsp (c))
			g_string_append_c (out, c);
	}

	res = g_strdup (out->str);
	g_string_free (out, TRUE);

	return res;
}

/**
 * camel_header_msgid_generate:
 * @domain: domain to use (like "example.com") for the ID suffix; can be NULL
 *
 * Either the @domain is used, or the user's local hostname,
 * in case it's NULL or empty.
 *
 * Returns: Unique message ID.
 **/
gchar *
camel_header_msgid_generate (const gchar *domain)
{
	static GMutex count_lock;
#define LOOKUP_LOCK() g_mutex_lock (&count_lock)
#define LOOKUP_UNLOCK() g_mutex_unlock (&count_lock)
	static volatile gint counter = 0;
	static gchar *cached_hostname = NULL;
	struct addrinfo *ai = NULL;
	GChecksum *checksum;
	gchar *msgid;

	LOOKUP_LOCK ();
	if (!cached_hostname && (!domain || !*domain)) {
		gchar host[MAXHOSTNAMELEN];
		struct addrinfo hints = { 0 };
		const gchar *name;
		gint retval;

		domain = NULL;

		retval = gethostname (host, sizeof (host));
		if (retval == 0 && *host) {
			hints.ai_flags = AI_CANONNAME;
			ai = camel_getaddrinfo (
				host, NULL, &hints, NULL, NULL);
			if (ai && ai->ai_canonname)
				name = ai->ai_canonname;
			else
				name = host;
		} else
			name = "localhost.localdomain";

		cached_hostname = g_strdup (name);
	}

	checksum = g_checksum_new (G_CHECKSUM_SHA1);

	#define add_i64(_x) G_STMT_START { \
		gint64 i64 = (_x); \
		g_checksum_update (checksum, (const guchar *) &i64, sizeof (gint64)); \
	} G_STMT_END

	#define add_str(_x, _def) G_STMT_START { \
		const gchar *str = (_x); \
		if (!str) \
			str = (_def); \
		g_checksum_update (checksum, (const guchar *) str, strlen (str)); \
	} G_STMT_END

	add_i64 (g_get_monotonic_time ());
	add_i64 (g_get_real_time ());
	add_i64 (getpid ());
	add_i64 (getgid ());
	add_i64 (getppid ());
	add_i64 (g_atomic_int_add (&counter, 1));

	add_str (domain, "localhost");
	add_str (cached_hostname, "localhost");
	add_str (g_get_host_name (), "localhost");
	add_str (g_get_user_name (), "user");
	add_str (g_get_real_name (), "User");

	#undef add_i64
	#undef add_str

	msgid = g_strdup_printf ("%s.camel@%s", g_checksum_get_string (checksum), domain ? domain : cached_hostname);

	g_checksum_free (checksum);

	LOOKUP_UNLOCK ();

	if (ai)
		camel_freeaddrinfo (ai);

	return msgid;
}

static struct {
	const gchar *name;
	const gchar *pattern;
	regex_t regex;
} mail_list_magic[] = {
	/* List-Post: <mailto:gnome-hackers@gnome.org> */
	/* List-Post: <mailto:gnome-hackers> */
	{ "List-Post", "[ \t]*<mailto:([^@>]+)@?([^ \n\t\r>]*)" },
	/* List-Id: GNOME stuff <gnome-hackers.gnome.org> */
	/* List-Id: <gnome-hackers.gnome.org> */
	/* List-Id: <gnome-hackers> */
	/* This old one wasn't very useful: { "List-Id", " *([^<]+)" },*/
	{ "List-Id", "[^<]*<([^\\.>]+)\\.?([^ \n\t\r>]*)" },
	/* Mailing-List: list gnome-hackers@gnome.org; contact gnome-hackers-owner@gnome.org */
	{ "Mailing-List", "[ \t]*list ([^@]+)@?([^ \n\t\r>;]*)" },
	/* Originator: gnome-hackers@gnome.org */
	{ "Originator", "[ \t]*([^@]+)@?([^ \n\t\r>]*)" },
	/* X-Mailing-List: <gnome-hackers@gnome.org> arcive/latest/100 */
	/* X-Mailing-List: gnome-hackers@gnome.org */
	/* X-Mailing-List: gnome-hackers */
	/* X-Mailing-List: <gnome-hackers> */
	{ "X-Mailing-List", "[ \t]*<?([^@>]+)@?([^ \n\t\r>]*)" },
	/* X-Loop: gnome-hackers@gnome.org */
	{ "X-Loop", "[ \t]*([^@]+)@?([^ \n\t\r>]*)" },
	/* X-List: gnome-hackers */
	/* X-List: gnome-hackers@gnome.org */
	{ "X-List", "[ \t]*([^@]+)@?([^ \n\t\r>]*)" },
	/* Sender: owner-gnome-hackers@gnome.org */
	/* Sender: owner-gnome-hacekrs */
	{ "Sender", "[ \t]*owner-([^@]+)@?([^ @\n\t\r>]*)" },
	/* Sender: gnome-hackers-owner@gnome.org */
	/* Sender: gnome-hackers-owner */
	{ "Sender", "[ \t]*([^@]+)-owner@?([^ @\n\t\r>]*)" },
	/* Delivered-To: mailing list gnome-hackers@gnome.org */
	/* Delivered-To: mailing list gnome-hackers */
	{ "Delivered-To", "[ \t]*mailing list ([^@]+)@?([^ \n\t\r>]*)" },
	/* Sender: owner-gnome-hackers@gnome.org */
	/* Sender: <owner-gnome-hackers@gnome.org> */
	/* Sender: owner-gnome-hackers */
	/* Sender: <owner-gnome-hackers> */
	{ "Return-Path", "[ \t]*<?owner-([^@>]+)@?([^ \n\t\r>]*)" },
	/* X-BeenThere: gnome-hackers@gnome.org */
	/* X-BeenThere: gnome-hackers */
	{ "X-BeenThere", "[ \t]*([^@]+)@?([^ \n\t\r>]*)" },
	/* List-Unsubscribe:  <mailto:gnome-hackers-unsubscribe@gnome.org> */
	{ "List-Unsubscribe", "<mailto:(.+)-unsubscribe@([^ \n\t\r>]*)" },
};

static gpointer
mailing_list_init (gpointer param)
{
	gint i, errcode, failed = 0;

	/* precompile regex's for speed at runtime */
	for (i = 0; i < G_N_ELEMENTS (mail_list_magic); i++) {
		errcode = regcomp (&mail_list_magic[i].regex, mail_list_magic[i].pattern, REG_EXTENDED | REG_ICASE);
		if (errcode != 0) {
			gchar *errstr;
			gsize len;

			len = regerror (errcode, &mail_list_magic[i].regex, NULL, 0);
			errstr = g_malloc0 (len + 1);
			regerror (errcode, &mail_list_magic[i].regex, errstr, len);

			g_warning ("Internal error, compiling regex failed: %s: %s", mail_list_magic[i].pattern, errstr);
			g_free (errstr);
			failed++;
		}
	}

	g_warn_if_fail (failed == 0);

	return NULL;
}

/**
 * camel_headers_dup_mailing_list:
 * @headers: a #CamelNameValueArray with headers
 *
 * Searches for a mailing list information among known headers and returns
 * a newly allocated string with its value.
 *
 * Returns: (nullable) (transfer full): The mailing list header, or %NULL, if none is found
 **/
gchar *
camel_headers_dup_mailing_list (const CamelNameValueArray *headers)
{
	static GOnce once = G_ONCE_INIT;
	const gchar *v;
	regmatch_t match[3];
	gint i, j;

	g_once (&once, mailing_list_init, NULL);

	for (i = 0; i < G_N_ELEMENTS (mail_list_magic); i++) {
		v = camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, mail_list_magic[i].name);
		for (j = 0; j < 3; j++) {
			match[j].rm_so = -1;
			match[j].rm_eo = -1;
		}
		if (v != NULL && regexec (&mail_list_magic[i].regex, v, 3, match, 0) == 0 && match[1].rm_so != -1) {
			gint len1, len2;
			gchar *mlist;

			len1 = match[1].rm_eo - match[1].rm_so;
			len2 = match[2].rm_eo - match[2].rm_so;

			mlist = g_malloc (len1 + len2 + 2);
			memcpy (mlist, v + match[1].rm_so, len1);
			if (len2) {
				mlist[len1] = '@';
				memcpy (mlist + len1 + 1, v + match[2].rm_so, len2);
				mlist[len1 + len2 + 1] = '\0';
			} else {
				mlist[len1] = '\0';
			}

			return mlist;
		}
	}

	return NULL;
}

/* ok, here's the address stuff, what a mess ... */
CamelHeaderAddress *
camel_header_address_new (void)
{
	CamelHeaderAddress *h;
	h = g_malloc0 (sizeof (*h));
	h->type = CAMEL_HEADER_ADDRESS_NONE;
	h->refcount = 1;
	return h;
}

CamelHeaderAddress *
camel_header_address_new_name (const gchar *name,
                               const gchar *addr)
{
	CamelHeaderAddress *h;
	h = camel_header_address_new ();
	h->type = CAMEL_HEADER_ADDRESS_NAME;
	h->name = g_strdup (name);
	h->v.addr = g_strdup (addr);
	return h;
}

CamelHeaderAddress *
camel_header_address_new_group (const gchar *name)
{
	CamelHeaderAddress *h;

	h = camel_header_address_new ();
	h->type = CAMEL_HEADER_ADDRESS_GROUP;
	h->name = g_strdup (name);
	return h;
}

CamelHeaderAddress *
camel_header_address_ref (CamelHeaderAddress *addrlist)
{
	if (addrlist)
		addrlist->refcount++;

	return addrlist;
}

void
camel_header_address_unref (CamelHeaderAddress *addrlist)
{
	if (addrlist) {
		if (addrlist->refcount <= 1) {
			if (addrlist->type == CAMEL_HEADER_ADDRESS_GROUP) {
				camel_header_address_list_clear (&addrlist->v.members);
			} else if (addrlist->type == CAMEL_HEADER_ADDRESS_NAME) {
				g_free (addrlist->v.addr);
			}
			g_free (addrlist->name);
			g_free (addrlist);
		} else {
			addrlist->refcount--;
		}
	}
}

void
camel_header_address_set_name (CamelHeaderAddress *addrlist,
                               const gchar *name)
{
	if (addrlist) {
		g_free (addrlist->name);
		addrlist->name = g_strdup (name);
	}
}

void
camel_header_address_set_addr (CamelHeaderAddress *addrlist,
                               const gchar *addr)
{
	if (addrlist) {
		if (addrlist->type == CAMEL_HEADER_ADDRESS_NAME
		    || addrlist->type == CAMEL_HEADER_ADDRESS_NONE) {
			addrlist->type = CAMEL_HEADER_ADDRESS_NAME;
			g_free (addrlist->v.addr);
			addrlist->v.addr = g_strdup (addr);
		} else {
			g_warning ("Trying to set the address on a group");
		}
	}
}

/**
 * camel_header_address_set_members:
 * @addrlist: a #CamelHeaderAddress object
 * @group: (array zero-terminated=1): a NULL-terminated list of #CamelHeaderAddress
 *
 * TODO: Document me.
 *
 **/
void
camel_header_address_set_members (CamelHeaderAddress *addrlist,
                                  CamelHeaderAddress *group)
{
	if (addrlist) {
		if (addrlist->type == CAMEL_HEADER_ADDRESS_GROUP
		    || addrlist->type == CAMEL_HEADER_ADDRESS_NONE) {
			addrlist->type = CAMEL_HEADER_ADDRESS_GROUP;
			camel_header_address_list_clear (&addrlist->v.members);
			/* should this ref them? */
			addrlist->v.members = group;
		} else {
			g_warning ("Trying to set the members on a name, not group");
		}
	}
}

void
camel_header_address_add_member (CamelHeaderAddress *addrlist,
                                 CamelHeaderAddress *member)
{
	if (addrlist) {
		if (addrlist->type == CAMEL_HEADER_ADDRESS_GROUP
		    || addrlist->type == CAMEL_HEADER_ADDRESS_NONE) {
			addrlist->type = CAMEL_HEADER_ADDRESS_GROUP;
			camel_header_address_list_append (&addrlist->v.members, member);
		}
	}
}

/**
 * camel_header_address_list_append_list:
 * @addrlistp: (array zero-terminated=1): a NULL-terminated list of #CamelHeaderAddress objects
 * @addrs: (array zero-terminated=1): a NULL-terminated list of #CamelHeaderAddress to add
 *
 * TODO: Document me.
 *
 **/
void
camel_header_address_list_append_list (CamelHeaderAddress **addrlistp,
                                       CamelHeaderAddress **addrs)
{
	if (addrlistp) {
		CamelHeaderAddress *n = (CamelHeaderAddress *) addrlistp;

		while (n->next)
			n = n->next;
		n->next = *addrs;
	}
}

/**
 * camel_header_address_list_append:
 * @addrlistp: (array zero-terminated=1): a NULL-terminated list of #CamelHeaderAddress objects
 * @addr: the #CamelHeaderAddress to add
 *
 * TODO: Document me.
 *
 **/
void
camel_header_address_list_append (CamelHeaderAddress **addrlistp,
                                  CamelHeaderAddress *addr)
{
	if (addr) {
		camel_header_address_list_append_list (addrlistp, &addr);
		addr->next = NULL;
	}
}

/**
 * camel_header_address_list_clear:
 * @addrlistp: (array zero-terminated=1): a NULL-terminated list of #CamelHeaderAddress objects
 *
 * TODO: Document me.
 *
 **/
void
camel_header_address_list_clear (CamelHeaderAddress **addrlistp)
{
	CamelHeaderAddress *a, *n;
	a = *addrlistp;
	while (a) {
		n = a->next;
		camel_header_address_unref (a);
		a = n;
	}
	*addrlistp = NULL;
}

static gchar *
maybe_quote_name (const gchar *name,
		  gboolean *out_free_result)
{
	if (out_free_result)
		*out_free_result = FALSE;

	if (name && *name && (strchr (name, ',') || strchr (name, ';') || strchr (name, '\"') || strchr (name, '<') || strchr (name, '>'))) {
		GString *quoted;

		if (out_free_result)
			*out_free_result = TRUE;

		quoted = g_string_sized_new (strlen (name) + 2);
		g_string_append_c (quoted, '\"');

		while (*name) {
			if (*name != '\"')
				g_string_append_c (quoted, *name);
			name++;
		}

		g_string_append_c (quoted, '\"');

		return g_string_free (quoted, FALSE);
	}

	return (gchar *) name;
}

/* if encode is true, then the result is suitable for mailing, otherwise
 * the result is suitable for display only (and may not even be re-parsable) */
static void
header_address_list_encode_append (GString *out,
                                   gint encode,
                                   CamelHeaderAddress *a)
{
	while (a) {
		gchar *text = NULL;
		gboolean free_text = FALSE;

		switch (a->type) {
		case CAMEL_HEADER_ADDRESS_NAME:
			if (encode)
				text = camel_header_encode_phrase ((guchar *) a->name);
			else
				text = maybe_quote_name (a->name, &free_text);
			if (text && *text)
				g_string_append_printf (out, "%s <%s>", text, a->v.addr);
			else
				g_string_append (out, a->v.addr);
			if (encode)
				g_free (text);
			break;
		case CAMEL_HEADER_ADDRESS_GROUP:
			if (encode)
				text = camel_header_encode_phrase ((guchar *) a->name);
			else
				text = maybe_quote_name (a->name, &free_text);
			g_string_append_printf (out, "%s: ", text);
			header_address_list_encode_append (out, encode, a->v.members);
			g_string_append_printf (out, ";");
			if (encode)
				g_free (text);
			break;
		default:
			g_warning ("Invalid address type");
			break;
		}

		a = a->next;
		if (a)
			g_string_append (out, ", ");

		if (free_text)
			g_free (text);
	}
}

/**
 * camel_header_address_list_encode:
 * @addrlist: (array zero-terminated=1): a NULL-terminated list of #CamelHeaderAddress objects
 *
 * TODO: Document me.
 *
 **/
gchar *
camel_header_address_list_encode (CamelHeaderAddress *addrlist)
{
	GString *out;
	gchar *ret;

	if (!addrlist)
		return NULL;

	out = g_string_new ("");
	header_address_list_encode_append (out, TRUE, addrlist);
	ret = out->str;
	g_string_free (out, FALSE);

	return ret;
}

/**
 * camel_header_address_list_format:
 * @addrlist: (array zero-terminated=1): a NULL-terminated list of #CamelHeaderAddress objects
 *
 * TODO: Document me.
 *
 **/
gchar *
camel_header_address_list_format (CamelHeaderAddress *addrlist)
{
	GString *out;
	gchar *ret;

	if (!addrlist)
		return NULL;

	out = g_string_new ("");

	header_address_list_encode_append (out, FALSE, addrlist);
	ret = out->str;
	g_string_free (out, FALSE);

	return ret;
}

gchar *
camel_header_address_fold (const gchar *in,
                           gsize headerlen)
{
	gsize len, outlen;
	const gchar *inptr = in, *space, *p, *n;
	GString *out;
	gchar *ret;
	gint i, needunfold = FALSE;

	if (in == NULL)
		return NULL;

	/* first, check to see if we even need to fold */
	len = headerlen + 2;
	p = in;
	while (*p) {
		n = strchr (p, '\n');
		if (n == NULL) {
			len += strlen (p);
			break;
		}

		needunfold = TRUE;
		len += n - p;

		if (len >= CAMEL_FOLD_SIZE)
			break;
		len = 0;
		p = n + 1;
	}
	if (len < CAMEL_FOLD_SIZE)
		return g_strdup (in);

	/* we need to fold, so first unfold (if we need to), then process */
	if (needunfold)
		inptr = in = camel_header_unfold (in);

	out = g_string_new ("");
	outlen = headerlen + 2;
	while (*inptr) {
		space = strchr (inptr, ' ');
		if (space) {
			len = space - inptr + 1;
		} else {
			len = strlen (inptr);
		}

		d (printf ("next word '%.*s'\n", len, inptr));

		if (outlen + len > CAMEL_FOLD_SIZE) {
			d (printf ("outlen = %d wordlen = %d\n", outlen, len));
			/* strip trailing space */
			if (out->len > 0 && out->str[out->len - 1] == ' ')
				g_string_truncate (out, out->len - 1);
			g_string_append (out, "\n\t");
			outlen = 1;
		}

		outlen += len;
		for (i = 0; i < len; i++) {
			g_string_append_c (out, inptr[i]);
		}

		inptr += len;
	}
	ret = out->str;
	g_string_free (out, FALSE);

	if (needunfold)
		g_free ((gchar *) in);

	return ret;
}

/* simple header folding */
/* will work even if the header is already folded */
gchar *
camel_header_fold (const gchar *in,
                   gsize headerlen)
{
	gsize len, outlen, tmplen;
	const gchar *inptr = in, *space, *p, *n;
	GString *out;
	gchar *ret;
	gint needunfold = FALSE;
	gchar spc;

	if (in == NULL)
		return NULL;

	/* first, check to see if we even need to fold */
	len = headerlen + 2;
	p = in;
	while (*p) {
		n = strchr (p, '\n');
		if (n == NULL) {
			len += strlen (p);
			break;
		}

		needunfold = TRUE;
		len += n - p;

		if (len >= CAMEL_FOLD_SIZE)
			break;
		len = 0;
		p = n + 1;
	}
	if (len < CAMEL_FOLD_SIZE)
		return g_strdup (in);

	/* we need to fold, so first unfold (if we need to), then process */
	if (needunfold)
		inptr = in = camel_header_unfold (in);

	out = g_string_new ("");
	outlen = headerlen + 2;
	while (*inptr) {
		space = inptr;
		while (*space && *space != ' ' && *space != '\t')
			space++;

		if (*space)
			len = space - inptr + 1;
		else
			len = space - inptr;

		d (printf ("next word '%.*s'\n", len, inptr));
		if (outlen + len > CAMEL_FOLD_SIZE) {
			d (printf ("outlen = %d wordlen = %d\n", outlen, len));
			/* strip trailing space */
			if (out->len > 0 && (out->str[out->len - 1] == ' ' || out->str[out->len - 1] == '\t')) {
				spc = out->str[out->len - 1];
				g_string_truncate (out, out->len - 1);
				g_string_append_c (out, '\n');
				g_string_append_c (out, spc);
				outlen = 1;
			}

			/* check for very long words, just cut them up */
			while (outlen + len > CAMEL_FOLD_MAX_SIZE) {
				tmplen = CAMEL_FOLD_MAX_SIZE - outlen;
				g_string_append_len (out, inptr, tmplen);
				g_string_append (out, "\n\t");
				inptr += tmplen;
				len -= tmplen;
				outlen = 1;
			}
		}

		g_string_append_len (out, inptr, len);
		outlen += len;
		inptr += len;
	}
	ret = out->str;
	g_string_free (out, FALSE);

	if (needunfold)
		g_free ((gchar *) in);

	return ret;
}

gchar *
camel_header_unfold (const gchar *in)
{
	const gchar *inptr = in;
	gchar c, *o, *out;

	if (in == NULL)
		return NULL;

	out = g_malloc (strlen (in) + 1);

	o = out;
	while ((c = *inptr++)) {
		if (c == '\n') {
			if (camel_mime_is_lwsp (*inptr)) {
				do {
					inptr++;
				} while (camel_mime_is_lwsp (*inptr));
				*o++ = ' ';
			} else {
				*o++ = c;
			}
		} else {
			*o++ = c;
		}
	}
	*o = 0;

	return out;
}
