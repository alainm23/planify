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
#include <stdlib.h>
#include <string.h>

#include "camel-mime-filter-enriched.h"
#include "camel-string-utils.h"

#define CAMEL_MIME_FILTER_ENRICHED_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER_ENRICHED, CamelMimeFilterEnrichedPrivate))

struct _CamelMimeFilterEnrichedPrivate {
	guint32 flags;
	gint nofill;
};

/* text/enriched is rfc1896 */

typedef gchar * (*EnrichedParamParser) (const gchar *inptr, gint inlen);

static gchar *param_parse_color (const gchar *inptr, gint inlen);
static gchar *param_parse_font (const gchar *inptr, gint inlen);
static gchar *param_parse_lang (const gchar *inptr, gint inlen);

static struct {
	const gchar *enriched;
	const gchar *html;
	gboolean needs_param;
	EnrichedParamParser parse_param; /* parses *and * validates the input */
} enriched_tags[] = {
	{ "bold",        "<b>",                 FALSE, NULL               },
	{ "/bold",       "</b>",                FALSE, NULL               },
	{ "italic",      "<i>",                 FALSE, NULL               },
	{ "/italic",     "</i>",                FALSE, NULL               },
	{ "fixed",       "<tt>",                FALSE, NULL               },
	{ "/fixed",      "</tt>",               FALSE, NULL               },
	{ "smaller",     "<font size=-1>",      FALSE, NULL               },
	{ "/smaller",    "</font>",             FALSE, NULL               },
	{ "bigger",      "<font size=+1>",      FALSE, NULL               },
	{ "/bigger",     "</font>",             FALSE, NULL               },
	{ "underline",   "<u>",                 FALSE, NULL               },
	{ "/underline",  "</u>",                FALSE, NULL               },
	{ "center",      "<p align=center>",    FALSE, NULL               },
	{ "/center",     "</p>",                FALSE, NULL               },
	{ "flushleft",   "<p align=left>",      FALSE, NULL               },
	{ "/flushleft",  "</p>",                FALSE, NULL               },
	{ "flushright",  "<p align=right>",     FALSE, NULL               },
	{ "/flushright", "</p>",                FALSE, NULL               },
	{ "excerpt",     "<blockquote>",        FALSE, NULL               },
	{ "/excerpt",    "</blockquote>",       FALSE, NULL               },
	{ "paragraph",   "<p>",                 FALSE, NULL               },
	{ "signature",   "<address>",           FALSE, NULL               },
	{ "/signature",  "</address>",          FALSE, NULL               },
	{ "comment",     "<!-- ",               FALSE, NULL               },
	{ "/comment",    " -->",                FALSE, NULL               },
	{ "np",          "<hr>",                FALSE, NULL               },
	{ "fontfamily",  "<font face=\"%s\">",  TRUE,  param_parse_font   },
	{ "/fontfamily", "</font>",             FALSE, NULL               },
	{ "color",       "<font color=\"%s\">", TRUE,  param_parse_color },
	{ "/color",      "</font>",             FALSE, NULL               },
	{ "lang",        "<span lang=\"%s\">",  TRUE,  param_parse_lang   },
	{ "/lang",       "</span>",             FALSE, NULL               },

	/* don't handle this tag yet... */
	{ "paraindent",  "<!-- ",               /* TRUE */ FALSE, NULL    },
	{ "/paraindent", " -->",                FALSE, NULL               },

	/* as soon as we support all the tags that can have a param
	 * tag argument, these should be unnecessary, but we'll keep
	 * them anyway just in case? */
	{ "param",       "<!-- ",               FALSE, NULL               },
	{ "/param",      " -->",                FALSE, NULL               },
};

static GHashTable *enriched_hash = NULL;

G_DEFINE_TYPE (CamelMimeFilterEnriched, camel_mime_filter_enriched, CAMEL_TYPE_MIME_FILTER)

#if 0
static gboolean
enriched_tag_needs_param (const gchar *tag)
{
	gint i;

	for (i = 0; i < G_N_ELEMENTS (enriched_tags); i++)
		if (!g_ascii_strcasecmp (tag, enriched_tags[i].enriched))
			return enriched_tags[i].needs_param;

	return FALSE;
}
#endif

static gboolean
html_tag_needs_param (const gchar *tag)
{
	return strstr (tag, "%s") != NULL;
}

static const gchar *valid_colors[] = {
	"red", "green", "blue", "yellow", "cyan", "magenta", "black", "white"
};

static gchar *
param_parse_color (const gchar *inptr,
                   gint inlen)
{
	const gchar *inend, *end;
	guint32 rgb = 0;
	guint v;
	gint i;

	for (i = 0; i < G_N_ELEMENTS (valid_colors); i++) {
		if (!g_ascii_strncasecmp (inptr, valid_colors[i], inlen))
			return g_strdup (valid_colors[i]);
	}

	/* check for numeric r/g/b in the format: ####,####,#### */
	if (inptr[4] != ',' || inptr[9] != ',') {
		/* okay, mailer must have used a string name that
		 * rfc1896 did not specify? do some simple scanning
		 * action, a color name MUST be [a-zA-Z] */
		end = inptr;
		inend = inptr + inlen;
		while (end < inend && ((*end >= 'a' && *end <= 'z') || (*end >= 'A' && *end <= 'Z')))
			end++;

		return g_strndup (inptr, end - inptr);
	}

	for (i = 0; i < 3; i++) {
		v = strtoul (inptr, (gchar **) &end, 16);
		if (end != inptr + 4)
			goto invalid_format;

		v >>= 8;
		rgb = (rgb << 8) | (v & 0xff);

		inptr += 5;
	}

	return g_strdup_printf ("#%.6X", rgb);

 invalid_format:

	/* default color? */
	return g_strdup ("black");
}

static gchar *
param_parse_font (const gchar *fontfamily,
                  gint inlen)
{
	register const gchar *inptr = fontfamily;
	const gchar *inend = inptr + inlen;

	/* don't allow any of '"', '<', nor '>' */
	while (inptr < inend && *inptr != '"' && *inptr != '<' && *inptr != '>')
		inptr++;

	return g_strndup (fontfamily, inptr - fontfamily);
}

static gchar *
param_parse_lang (const gchar *lang,
                  gint inlen)
{
	register const gchar *inptr = lang;
	const gchar *inend = inptr + inlen;

	/* don't allow any of '"', '<', nor '>' */
	while (inptr < inend && *inptr != '"' && *inptr != '<' && *inptr != '>')
		inptr++;

	return g_strndup (lang, inptr - lang);
}

static gchar *
param_parse (const gchar *enriched,
             const gchar *inptr,
             gint inlen)
{
	gint i;

	for (i = 0; i < G_N_ELEMENTS (enriched_tags); i++) {
		if (!g_ascii_strcasecmp (enriched, enriched_tags[i].enriched))
			return enriched_tags[i].parse_param (inptr, inlen);
	}

	g_warn_if_reached ();

	return NULL;
}

#define IS_RICHTEXT CAMEL_MIME_FILTER_ENRICHED_IS_RICHTEXT

static void
enriched_to_html (CamelMimeFilter *mime_filter,
                  const gchar *in,
                  gsize inlen,
                  gsize prespace,
                  gchar **out,
                  gsize *outlen,
                  gsize *outprespace,
                  gboolean flush)
{
	CamelMimeFilterEnrichedPrivate *priv;
	const gchar *tag, *inend, *outend;
	register const gchar *inptr;
	register gchar *outptr;

	priv = CAMEL_MIME_FILTER_ENRICHED_GET_PRIVATE (mime_filter);

	camel_mime_filter_set_size (mime_filter, inlen * 2 + 6, FALSE);

	inptr = in;
	inend = in + inlen;
	outptr = mime_filter->outbuf;
	outend = mime_filter->outbuf + mime_filter->outsize;

 retry:
	do {
		while (inptr < inend && outptr < outend && !strchr (" <>&\n", *inptr)) {
			*outptr = *inptr;

			outptr++;
			inptr++;
		}

		if (outptr == outend)
			goto backup;

		if ((inptr + 1) >= inend)
			break;

		switch (*inptr++) {
		case ' ':
			while (inptr < inend && (outptr + 7) < outend && *inptr == ' ') {
				memcpy (outptr, "&nbsp;", 6);
				outptr += 6;
				inptr++;
			}

			if (outptr < outend)
				*outptr++ = ' ';

			break;
		case '\n':
			if (!(priv->flags & IS_RICHTEXT)) {
				/* text/enriched */
				if (priv->nofill > 0) {
					if ((outptr + 4) < outend) {
						memcpy (outptr, "<br>", 4);
						outptr += 4;
					} else {
						inptr--;
						goto backup;
					}
				} else if (*inptr == '\n') {
					if ((outptr + 4) >= outend) {
						inptr--;
						goto backup;
					}

					while (inptr < inend && (outptr + 4) < outend && *inptr == '\n') {
						memcpy (outptr, "<br>", 4);
						outptr += 4;
						inptr++;
					}
				} else {
					*outptr++ = ' ';
				}
			} else {
				/* text/richtext */
				*outptr++ = ' ';
			}
			break;
		case '>':
			if ((outptr + 4) < outend) {
				memcpy (outptr, "&gt;", 4);
				outptr += 4;
			} else {
				inptr--;
				goto backup;
			}
			break;
		case '&':
			if ((outptr + 5) < outend) {
				memcpy (outptr, "&amp;", 5);
				outptr += 5;
			} else {
				inptr--;
				goto backup;
			}
			break;
		case '<':
			if (!(priv->flags & IS_RICHTEXT)) {
				/* text/enriched */
				if (*inptr == '<') {
					if ((outptr + 4) < outend) {
						memcpy (outptr, "&lt;", 4);
						outptr += 4;
						inptr++;
						break;
					} else {
						inptr--;
						goto backup;
					}
				}
			} else {
				/* text/richtext */
				if ((inend - inptr) >= 3 && (outptr + 4) < outend) {
					if (strncmp (inptr, "lt>", 3) == 0) {
						memcpy (outptr, "&lt;", 4);
						outptr += 4;
						inptr += 3;
						break;
					} else if (strncmp (inptr, "nl>", 3) == 0) {
						memcpy (outptr, "<br>", 4);
						outptr += 4;
						inptr += 3;
						break;
					}
				} else {
					inptr--;
					goto backup;
				}
			}

			tag = inptr;
			while (inptr < inend && *inptr != '>')
				inptr++;

			if (inptr == inend) {
				inptr = tag - 1;
				goto need_input;
			}

			if (!g_ascii_strncasecmp (tag, "nofill>", 7)) {
				if ((outptr + 5) < outend) {
					priv->nofill++;
				} else {
					inptr = tag - 1;
					goto backup;
				}
			} else if (!g_ascii_strncasecmp (tag, "/nofill>", 8)) {
				if ((outptr + 6) < outend) {
					priv->nofill--;
				} else {
					inptr = tag - 1;
					goto backup;
				}
			} else {
				const gchar *html_tag;
				gchar *enriched_tag;
				gint len;

				len = inptr - tag;
				enriched_tag = g_alloca (len + 1);
				memcpy (enriched_tag, tag, len);
				enriched_tag[len] = '\0';

				html_tag = g_hash_table_lookup (enriched_hash, enriched_tag);

				if (html_tag) {
					if (html_tag_needs_param (html_tag)) {
						const gchar *start;
						gchar *param;

						while (inptr < inend && *inptr != '<')
							inptr++;

						if (inptr == inend || (inend - inptr) <= 15) {
							inptr = tag - 1;
							goto need_input;
						}

						if (g_ascii_strncasecmp (inptr, "<param>", 7) != 0) {
							/* ignore the enriched command tag... */
							inptr -= 1;
							goto loop;
						}

						inptr += 7;
						start = inptr;

						while (inptr < inend && *inptr != '<')
							inptr++;

						if (inptr == inend || (inend - inptr) <= 8) {
							inptr = tag - 1;
							goto need_input;
						}

						if (g_ascii_strncasecmp (inptr, "</param>", 8) != 0) {
							/* ignore the enriched command tag... */
							inptr += 7;
							goto loop;
						}

						len = inptr - start;
						param = param_parse (enriched_tag, start, len);
						len = strlen (param);

						inptr += 7;

						len += strlen (html_tag);

						if ((outptr + len) < outend) {
							outptr += snprintf (outptr, len, html_tag, param);
							g_free (param);
						} else {
							g_free (param);
							inptr = tag - 1;
							goto backup;
						}
					} else {
						len = strlen (html_tag);
						if ((outptr + len) < outend) {
							memcpy (outptr, html_tag, len);
							outptr += len;
						} else {
							inptr = tag - 1;
							goto backup;
						}
					}
				}
			}

		loop:
			inptr++;
			break;
		default:
			break;
		}
	} while (inptr < inend);

 need_input:

	/* the reason we ignore @flush here is because if there isn't
	 * enough input to parse a tag, then there's nothing we can
	 * do. */

	if (inptr < inend)
		camel_mime_filter_backup (mime_filter, inptr, (unsigned) (inend - inptr));

	*out = mime_filter->outbuf;
	*outlen = outptr - mime_filter->outbuf;
	*outprespace = mime_filter->outpre;

	return;

 backup:

	if (flush) {
		gsize offset, grow;

		grow = (inend - inptr) * 2 + 20;
		offset = outptr - mime_filter->outbuf;
		camel_mime_filter_set_size (mime_filter, mime_filter->outsize + grow, TRUE);
		outend = mime_filter->outbuf + mime_filter->outsize;
		outptr = mime_filter->outbuf + offset;

		goto retry;
	} else {
		camel_mime_filter_backup (mime_filter, inptr, (unsigned) (inend - inptr));
	}

	*out = mime_filter->outbuf;
	*outlen = outptr - mime_filter->outbuf;
	*outprespace = mime_filter->outpre;
}

static void
mime_filter_enriched_filter (CamelMimeFilter *mime_filter,
                             const gchar *in,
                             gsize len,
                             gsize prespace,
                             gchar **out,
                             gsize *outlen,
                             gsize *outprespace)
{
	enriched_to_html (
		mime_filter, in, len, prespace,
		out, outlen, outprespace, FALSE);
}

static void
mime_filter_enriched_complete (CamelMimeFilter *mime_filter,
                               const gchar *in,
                               gsize len,
                               gsize prespace,
                               gchar **out,
                               gsize *outlen,
                               gsize *outprespace)
{
	enriched_to_html (
		mime_filter, in, len, prespace,
		out, outlen, outprespace, TRUE);
}

static void
mime_filter_enriched_reset (CamelMimeFilter *mime_filter)
{
	CamelMimeFilterEnrichedPrivate *priv;

	priv = CAMEL_MIME_FILTER_ENRICHED_GET_PRIVATE (mime_filter);

	priv->nofill = 0;
}

static void
camel_mime_filter_enriched_class_init (CamelMimeFilterEnrichedClass *class)
{
	CamelMimeFilterClass *mime_filter_class;
	gint i;

	g_type_class_add_private (class, sizeof (CamelMimeFilterEnrichedPrivate));

	mime_filter_class = CAMEL_MIME_FILTER_CLASS (class);
	mime_filter_class->filter = mime_filter_enriched_filter;
	mime_filter_class->complete = mime_filter_enriched_complete;
	mime_filter_class->reset = mime_filter_enriched_reset;

	enriched_hash = g_hash_table_new (
		camel_strcase_hash, camel_strcase_equal);
	for (i = 0; i < G_N_ELEMENTS (enriched_tags); i++)
		g_hash_table_insert (
			enriched_hash,
			(gpointer) enriched_tags[i].enriched,
			(gpointer) enriched_tags[i].html);
}

static void
camel_mime_filter_enriched_init (CamelMimeFilterEnriched *filter)
{
	filter->priv = CAMEL_MIME_FILTER_ENRICHED_GET_PRIVATE (filter);
}

/**
 * camel_mime_filter_enriched_new:
 * @flags: bitwise set of flags to specify filter behaviour
 *
 * Create a new #CamelMimeFilterEnriched object to convert input text
 * streams from text/plain into text/enriched or text/richtext.
 *
 * Returns: a new #CamelMimeFilterEnriched object
 **/
CamelMimeFilter *
camel_mime_filter_enriched_new (guint32 flags)
{
	CamelMimeFilter *new;
	CamelMimeFilterEnrichedPrivate *priv;

	new = g_object_new (CAMEL_TYPE_MIME_FILTER_ENRICHED, NULL);
	priv = CAMEL_MIME_FILTER_ENRICHED_GET_PRIVATE (new);

	priv->flags = flags;

	return new;
}

/**
 * camel_enriched_to_html:
 * @in: input textual string
 * @flags: flags specifying filter behaviour
 *
 * Convert @in from text/plain into text/enriched or text/richtext
 * based on @flags.
 *
 * Returns: a newly allocated string containing the enriched or
 * richtext version of @in.
 **/
gchar *
camel_enriched_to_html (const gchar *in,
                        guint32 flags)
{
	CamelMimeFilter *filter;
	gsize outlen, outpre;
	gchar *outbuf;

	if (in == NULL)
		return NULL;

	filter = camel_mime_filter_enriched_new (flags);

	camel_mime_filter_complete (filter, (gchar *) in, strlen (in), 0, &outbuf, &outlen, &outpre);
	outbuf = g_strndup (outbuf, outlen);
	g_object_unref (filter);

	return outbuf;
}
