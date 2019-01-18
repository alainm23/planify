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

#include <stdio.h>
#include <string.h>

#include "camel-mime-filter-tohtml.h"
#include "camel-url-scanner.h"
#include "camel-utf8.h"

#define CAMEL_MIME_FILTER_TOHTML_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER_TOHTML, CamelMimeFilterToHTMLPrivate))

struct _CamelMimeFilterToHTMLPrivate {

	CamelUrlScanner *scanner;

	CamelMimeFilterToHTMLFlags flags;
	guint32 color;

	guint blockquote_depth;

	guint32 column : 31;
	guint32 pre_open : 1;
};

/*
 * TODO: convert common text/plain 'markup' to html. eg.:
 *
 * _word_ -> <u>_word_</u>
 * *word* -> <b>*word*</b>
 * /word/ -> <i>/word/</i>
 */

#define d(x)

#define FOOLISHLY_UNMUNGE_FROM 0

#define CONVERT_WEB_URLS  CAMEL_MIME_FILTER_TOHTML_CONVERT_URLS
#define CONVERT_ADDRSPEC  CAMEL_MIME_FILTER_TOHTML_CONVERT_ADDRESSES

static struct {
	CamelMimeFilterToHTMLFlags mask;
	CamelUrlPattern pattern;
} patterns[] = {
	{ CONVERT_WEB_URLS, { "file://",   "",        camel_url_file_start,     camel_url_file_end     } },
	{ CONVERT_WEB_URLS, { "ftp://",    "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "sftp://",   "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "http://",   "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "https://",  "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "news://",   "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "nntp://",   "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "telnet://", "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "webcal://", "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "mailto:",   "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "callto:",   "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "h323:",     "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "sip:",      "",        camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "www.",      "http://", camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_WEB_URLS, { "ftp.",      "ftp://",  camel_url_web_start,      camel_url_web_end      } },
	{ CONVERT_ADDRSPEC, { "@",         "mailto:", camel_url_addrspec_start, camel_url_addrspec_end } },
};

G_DEFINE_TYPE (CamelMimeFilterToHTML, camel_mime_filter_tohtml, CAMEL_TYPE_MIME_FILTER)

static gchar *
check_size (CamelMimeFilter *mime_filter,
            gchar *outptr,
            gchar **outend,
            gsize len)
{
	gsize offset;

	if (*outend - outptr >= len)
		return outptr;

	offset = outptr - mime_filter->outbuf;

	camel_mime_filter_set_size (
		mime_filter, mime_filter->outsize + len, TRUE);

	*outend = mime_filter->outbuf + mime_filter->outsize;

	return mime_filter->outbuf + offset;
}

static gchar *
append_string_verbatim (CamelMimeFilter *mime_filter,
                        const gchar *str,
                        gchar *outptr,
                        gchar **outend)
{
	gsize len = strlen (str);

	outptr = check_size (mime_filter, outptr, outend, len);
	memcpy (outptr, str, len);
	outptr += len;

	return outptr;
}

static gint
citation_depth (const gchar *in,
                const gchar *inend,
                goffset *out_skip)
{
	register const gchar *inptr = in;
	gint depth = 0;
	goffset skip = 0;

	if (out_skip != NULL)
		*out_skip = 0;

	if (!strchr (">|", *inptr++))
		goto exit;

#if FOOLISHLY_UNMUNGE_FROM
	/* check that it isn't an escaped From line */
	if (!strncmp (inptr, "From", 4)) {
		goto exit;
#endif

	depth = 1;
	skip = 1;

	while (inptr < inend && *inptr != '\n') {
		if (*inptr == ' ') {
			inptr++;
			skip++;
		}

		if (inptr >= inend || !strchr (">|", *inptr++))
			break;

		depth++;
		skip++;
	}

exit:
	if (out_skip != NULL)
		*out_skip = (depth > 0) ? skip : 0;

	return depth;
}

static gchar *
writeln (CamelMimeFilter *mime_filter,
         const guchar *in,
         const guchar *inend,
         gchar *outptr,
         gchar **outend)
{
	CamelMimeFilterToHTMLPrivate *priv;
	const guchar *inptr = in;

	priv = CAMEL_MIME_FILTER_TOHTML_GET_PRIVATE (mime_filter);

	while (inptr < inend) {
		guint32 u;

		outptr = check_size (mime_filter, outptr, outend, 16);

		u = camel_utf8_getc_limit (&inptr, inend);
		switch (u) {
		case 0xffff:
			g_warning (
				"Truncated UTF-8 buffer (The cause might "
				"be missing character encoding information "
				"in the message header. Try a different "
				"character encoding.)");
			return outptr;
		case '<':
			outptr = g_stpcpy (outptr, "&lt;");
			priv->column++;
			break;
		case '>':
			outptr = g_stpcpy (outptr, "&gt;");
			priv->column++;
			break;
		case '&':
			outptr = g_stpcpy (outptr, "&amp;");
			priv->column++;
			break;
		case '"':
			outptr = g_stpcpy (outptr, "&quot;");
			priv->column++;
			break;
		case '\t':
			if (priv->flags & (CAMEL_MIME_FILTER_TOHTML_CONVERT_SPACES)) {
				do {
					outptr = check_size (mime_filter, outptr, outend, 7);
					outptr = g_stpcpy (outptr, "&nbsp;");
					priv->column++;
				} while (priv->column % 8);
				break;
			}
			/* falls through */
		case ' ':
			if (priv->flags & CAMEL_MIME_FILTER_TOHTML_CONVERT_SPACES
			    && ((inptr == (in + 1) || (inptr < inend && (*inptr == ' ' || *inptr == '\t'))))) {
				outptr = g_stpcpy (outptr, "&nbsp;");
				priv->column++;
				break;
			}
			/* falls through */
		default:
			if (u == '\r' && inptr >= inend) {
				/* This constructs \r\n sequence at the end of the line, thus pass it in
				   only if not converting the new-line breaks */
				if (!(priv->flags & CAMEL_MIME_FILTER_TOHTML_CONVERT_NL))
					*outptr++ = u;
			} else if (u >= 20 && u <0x80) {
				*outptr++ = u;
			} else {
				if (priv->flags & CAMEL_MIME_FILTER_TOHTML_ESCAPE_8BIT)
					*outptr++ = '?';
				else
					outptr += sprintf (outptr, "&#%u;", u);
			}
			priv->column++;
			break;
		}
	}

	return outptr;
}

static void
html_convert (CamelMimeFilter *mime_filter,
              const gchar *in,
              gsize inlen,
              gsize prespace,
              gchar **out,
              gsize *outlen,
              gsize *outprespace,
              gboolean flush)
{
	CamelMimeFilterToHTMLPrivate *priv;
	const gchar *inptr;
	gchar *outptr, *outend;
	const gchar *start;
	const gchar *inend;
	gint depth;

	priv = CAMEL_MIME_FILTER_TOHTML_GET_PRIVATE (mime_filter);

	if (inlen == 0) {
		if (!priv->pre_open && priv->blockquote_depth == 0) {
			/* No closing tags needed. */
			*out = (gchar *) in;
			*outlen = 0;
			*outprespace = 0;
			return;
		}

		outptr = mime_filter->outbuf;
		outend = mime_filter->outbuf + mime_filter->outsize;

		while (priv->blockquote_depth > 0) {
			outptr = check_size (mime_filter, outptr, &outend, 15);
			outptr = g_stpcpy (outptr, "</blockquote>");
			priv->blockquote_depth--;
		}

		if (priv->pre_open) {
			/* close the pre-tag */
			outptr = check_size (mime_filter, outptr, &outend, 10);
			outptr = g_stpcpy (outptr, "</pre>");
			priv->pre_open = FALSE;
		}

		*out = mime_filter->outbuf;
		*outlen = outptr - mime_filter->outbuf;
		*outprespace = mime_filter->outpre;

		return;
	}

	camel_mime_filter_set_size (mime_filter, inlen * 2 + 6, FALSE);

	inptr = in;
	inend = in + inlen;
	outptr = mime_filter->outbuf;
	outend = mime_filter->outbuf + mime_filter->outsize;

	if (priv->flags & CAMEL_MIME_FILTER_TOHTML_PRE && !priv->pre_open) {
		outptr = check_size (mime_filter, outptr, &outend, 6);
		outptr = g_stpcpy (outptr, "<pre>");
		priv->pre_open = TRUE;
	}

	start = inptr;
	do {
		while (inptr < inend && *inptr != '\n')
			inptr++;

		if (inptr >= inend && !flush)
			break;

		priv->column = 0;
		depth = 0;

		if (priv->flags & CAMEL_MIME_FILTER_TOHTML_MARK_CITATION) {
			depth = citation_depth (start, inend, NULL);

			if (depth > 0) {
				/* FIXME: we could easily support multiple color depths here */

				outptr = check_size (mime_filter, outptr, &outend, 25);
				outptr += sprintf (outptr, "<font color=\"#%06x\">", (priv->color & 0xffffff));
			}
#if FOOLISHLY_UNMUNGE_FROM
			else if (*start == '>') {
				/* >From line */
				start++;
			}
#endif

		} else if (priv->flags & CAMEL_MIME_FILTER_TOHTML_QUOTE_CITATION) {
			goffset skip = 0;

			depth = citation_depth (start, inend, &skip);
			while (priv->blockquote_depth < depth) {
				outptr = check_size (mime_filter, outptr, &outend, 25);
				outptr = g_stpcpy (outptr, "<blockquote type=\"cite\">");
				priv->blockquote_depth++;
			}
			while (priv->blockquote_depth > depth) {
				outptr = check_size (mime_filter, outptr, &outend, 14);
				outptr = g_stpcpy (outptr, "</blockquote>");
				priv->blockquote_depth--;
			}
#if FOOLISHLY_UNMUNGE_FROM
			if (depth == 0 && *start == '>') {
				/* >From line */
				skip = 1;
			}
#endif
			start += skip;

		} else if (priv->flags & CAMEL_MIME_FILTER_TOHTML_CITE) {
			outptr = check_size (mime_filter, outptr, &outend, 6);
			outptr = g_stpcpy (outptr, "&gt; ");
			priv->column += 2;
		}

#define CONVERT_URLS (CAMEL_MIME_FILTER_TOHTML_CONVERT_URLS | CAMEL_MIME_FILTER_TOHTML_CONVERT_ADDRESSES)
		if (priv->flags & CONVERT_URLS) {
			gsize matchlen, len;
			CamelUrlMatch match;

			len = inptr - start;

			do {
				if (camel_url_scanner_scan (priv->scanner, start, len - (len > 0 && start[len - 1] == 0 ? 1 : 0), &match)) {
					/* write out anything before the first regex match */
					outptr = writeln (
						mime_filter,
						(const guchar *) start,
						(const guchar *) start +
						match.um_so,
						outptr, &outend);

					start += match.um_so;
					len -= match.um_so;

					matchlen = match.um_eo - match.um_so;

					/* write out the href tag */
					outptr = append_string_verbatim (mime_filter, "<a href=\"", outptr, &outend);
					/* prefix shouldn't need escaping, but let's be safe */
					outptr = writeln (
						mime_filter,
						(const guchar *) match.prefix,
						(const guchar *) match.prefix +
						strlen (match.prefix),
						outptr, &outend);
					outptr = writeln (
						mime_filter,
						(const guchar *) start,
						(const guchar *) start +
						matchlen,
						outptr, &outend);
					outptr = append_string_verbatim (
						mime_filter, "\">",
						outptr, &outend);

					/* now write the matched string */
					outptr = writeln (
						mime_filter,
						(const guchar *) start,
						(const guchar *) start +
						matchlen,
						outptr, &outend);
					priv->column += matchlen;
					start += matchlen;
					len -= matchlen;

					/* close the href tag */
					outptr = append_string_verbatim (
						mime_filter, "</a>",
						outptr, &outend);
				} else {
					/* nothing matched so write out the remainder of this line buffer */
					outptr = writeln (
						mime_filter,
						(const guchar *) start,
						(const guchar *) start + len,
						outptr, &outend);
					break;
				}
			} while (len > 0);
		} else {
			outptr = writeln (
				mime_filter,
				(const guchar *) start,
				(const guchar *) inptr,
				outptr, &outend);
		}

		if ((priv->flags & CAMEL_MIME_FILTER_TOHTML_MARK_CITATION) && depth > 0) {
			outptr = check_size (mime_filter, outptr, &outend, 8);
			outptr = g_stpcpy (outptr, "</font>");
		}

		if (inptr < inend) {
			if (priv->flags & CAMEL_MIME_FILTER_TOHTML_CONVERT_NL) {
				outptr = check_size (mime_filter, outptr, &outend, 5);
				outptr = g_stpcpy (outptr, "<br>");
			}

			outptr = append_string_verbatim (mime_filter, "\n", outptr, &outend);
		}

		start = ++inptr;
	} while (inptr < inend);

	if (flush) {
		/* flush the rest of our input buffer */
		if (start < inend)
			outptr = writeln (
				mime_filter,
				(const guchar *) start,
				(const guchar *) inend,
				outptr, &outend);

		while (priv->blockquote_depth > 0) {
			outptr = check_size (mime_filter, outptr, &outend, 14);
			outptr = g_stpcpy (outptr, "</blockquote>");
			priv->blockquote_depth--;
		}

		if (priv->pre_open) {
			/* close the pre-tag */
			outptr = check_size (mime_filter, outptr, &outend, 7);
			outptr = g_stpcpy (outptr, "</pre>");
			priv->pre_open = FALSE;
		}
	} else if (start < inend) {
		/* backup */
		camel_mime_filter_backup (
			mime_filter, start, (gsize) (inend - start));
	}

	*out = mime_filter->outbuf;
	*outlen = outptr - mime_filter->outbuf;
	*outprespace = mime_filter->outpre;
}

static void
mime_filter_tohtml_finalize (GObject *object)
{
	CamelMimeFilterToHTMLPrivate *priv;

	priv = CAMEL_MIME_FILTER_TOHTML_GET_PRIVATE (object);

	camel_url_scanner_free (priv->scanner);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_mime_filter_tohtml_parent_class)->finalize (object);
}

static void
mime_filter_tohtml_filter (CamelMimeFilter *mime_filter,
                           const gchar *in,
                           gsize len,
                           gsize prespace,
                           gchar **out,
                           gsize *outlen,
                           gsize *outprespace)
{
	html_convert (
		mime_filter, in, len, prespace,
		out, outlen, outprespace, FALSE);
}

static void
mime_filter_tohtml_complete (CamelMimeFilter *mime_filter,
                             const gchar *in,
                             gsize len,
                             gsize prespace,
                             gchar **out,
                             gsize *outlen,
                             gsize *outprespace)
{
	html_convert (
		mime_filter, in, len, prespace,
		out, outlen, outprespace, TRUE);
}

static void
mime_filter_tohtml_reset (CamelMimeFilter *mime_filter)
{
	CamelMimeFilterToHTMLPrivate *priv;

	priv = CAMEL_MIME_FILTER_TOHTML_GET_PRIVATE (mime_filter);

	priv->column = 0;
	priv->pre_open = FALSE;
}

static void
camel_mime_filter_tohtml_class_init (CamelMimeFilterToHTMLClass *class)
{
	GObjectClass *object_class;
	CamelMimeFilterClass *filter_class;

	g_type_class_add_private (class, sizeof (CamelMimeFilterToHTMLPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = mime_filter_tohtml_finalize;

	filter_class = CAMEL_MIME_FILTER_CLASS (class);
	filter_class->filter = mime_filter_tohtml_filter;
	filter_class->complete = mime_filter_tohtml_complete;
	filter_class->reset = mime_filter_tohtml_reset;
}

static void
camel_mime_filter_tohtml_init (CamelMimeFilterToHTML *filter)
{
	filter->priv = CAMEL_MIME_FILTER_TOHTML_GET_PRIVATE (filter);
	filter->priv->scanner = camel_url_scanner_new ();
}

/**
 * camel_mime_filter_tohtml_new:
 * @flags: bitwise flags defining the behaviour
 * @color: color to use when highlighting quoted text
 *
 * Create a new #CamelMimeFilterToHTML object to convert plain text
 * into HTML.
 *
 * Returns: a new #CamelMimeFilterToHTML object
 **/
CamelMimeFilter *
camel_mime_filter_tohtml_new (CamelMimeFilterToHTMLFlags flags,
                              guint32 color)
{
	CamelMimeFilter *filter;
	CamelMimeFilterToHTMLPrivate *priv;
	gint i;

	filter = g_object_new (CAMEL_TYPE_MIME_FILTER_TOHTML, NULL);
	priv = CAMEL_MIME_FILTER_TOHTML_GET_PRIVATE (filter);

	priv->flags = flags;
	priv->color = color;

	for (i = 0; i < G_N_ELEMENTS (patterns); i++) {
		if (patterns[i].mask & flags)
			camel_url_scanner_add (
				priv->scanner, &patterns[i].pattern);
	}

	return filter;
}

/**
 * camel_text_to_html:
 * @in: input text
 * @flags: bitwise flags defining the html conversion behaviour
 * @color: color to use when syntax highlighting
 *
 * Convert @in from plain text into HTML.
 *
 * Returns: a newly allocated string containing the HTMLified version
 * of @in
 **/
gchar *
camel_text_to_html (const gchar *in,
                    CamelMimeFilterToHTMLFlags flags,
                    guint32 color)
{
	CamelMimeFilter *filter;
	gsize outlen, outpre;
	gchar *outbuf;

	g_return_val_if_fail (in != NULL, NULL);

	filter = camel_mime_filter_tohtml_new (flags, color);

	camel_mime_filter_complete (
		filter, (gchar *) in, strlen (in), 0,
		&outbuf, &outlen, &outpre);

	outbuf = g_strndup (outbuf, outlen);

	g_object_unref (filter);

	return outbuf;
}
