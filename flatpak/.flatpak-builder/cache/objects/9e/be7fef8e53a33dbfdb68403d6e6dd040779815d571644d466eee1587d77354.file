/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; -*- */
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
 *          Dan Winship <danw@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <locale.h>
#ifdef HAVE_CODESET
#include <langinfo.h>
#endif
#include <iconv.h>
#include <errno.h>

#include "camel-iconv.h"

/*
 * if you want to build the charset map, compile this with something like:
 *    gcc -DBUILD_MAP camel-charset-map.c `pkg-config --cflags --libs glib-2.0`
 * (plus any -I/-L/-l flags you need for iconv), then run it as
 *    ./a.out > camel-charset-map-private.h
 *
 * Note that the big-endian variant isn't tested...
 *
 * The tables genereated work like this:
 *
 * An indirect array for each page of unicode character
 * Each array element has an indirect pointer to one of the bytes of
 * the generated bitmask.
 */

#ifdef BUILD_MAP

static struct {
	gchar *name;        /* charset name */
	gint multibyte;     /* charset type */
	guint bit;  /* assigned bit */
} tables[] = {
	/* These are the 8bit character sets (other than iso-8859-1,
	 * which is special-cased) which are supported by both other
	 * mailers and the GNOME environment. Note that the order
	 * they're listed in is the order they'll be tried in, so put
	 * the more-popular ones first.
	 */
	{ "iso-8859-2",   0, 0 },  /* Central/Eastern European */
	{ "iso-8859-4",   0, 0 },  /* Baltic */
	{ "koi8-r",       0, 0 },  /* Russian */
	{ "koi8-u",       0, 0 },  /* Ukranian */
	{ "iso-8859-5",   0, 0 },  /* Least-popular Russian encoding */
	{ "iso-8859-6",   0, 0 },  /* Arabic */
	{ "iso-8859-7",   0, 0 },  /* Greek */
	{ "iso-8859-8",   0, 0 },  /* Hebrew; Visual */
	{ "iso-8859-9",   0, 0 },  /* Turkish */
	{ "iso-8859-13",  0, 0 },  /* Baltic again */
	{ "iso-8859-15",  0, 0 },  /* New-and-improved iso-8859-1, but most
				    * programs that support this support UTF8
				    */
	{ "windows-1251", 0, 0 },  /* Russian */

	/* These are the multibyte character sets which are commonly
	 * supported by other mail clients. Note: order for multibyte
	 * charsets does not affect priority unlike the 8bit charsets
	 * listed above.
	 */
	{ "iso-2022-jp",  1, 0 },  /* Japanese designed for use over the Net */
	{ "Shift-JIS",    1, 0 },  /* Japanese as used by Windows and MacOS systems */
	{ "euc-jp",       1, 0 },  /* Japanese traditionally used on Unix systems */
	{ "euc-kr",       1, 0 },  /* Korean */
	{ "iso-2022-kr",  1, 0 },  /* Korean (less popular than euc-kr) */
	{ "gb2312",       1, 0 },  /* Simplified Chinese */
	{ "Big5",         1, 0 },  /* Traditional Chinese */
	{ "euc-tw",       1, 0 },
	{ NULL,           0, 0 }
};

guint encoding_map[256 * 256];

#if G_BYTE_ORDER == G_BIG_ENDIAN
#define UCS "UCS-4BE"
#else
#define UCS "UCS-4LE"
#endif

static guint
block_hash (gconstpointer v)
{
	const gchar *p = v;
	guint32 h = *p++;
	gint i;

	for (i = 0; i < 256; i++)
		h = (h << 5) - h + *p++;

	return h;
}

static gint
block_equal (gconstpointer v1,
             gconstpointer v2)
{
	return !memcmp (v1, v2, 256);
}

gint main (gint argc, gchar **argv)
{
	guchar *block = NULL;
	guint bit = 0x01;
	GHashTable *table_hash;
	gsize inleft, outleft;
	gchar *inbuf, *outbuf;
	guint32 out[128], c;
	gchar in[128];
	gint i, j, k;
	gint bytes;
	GIConv cd;

	/* dont count the terminator */
	bytes = (G_N_ELEMENTS (tables) + 7 - 1) / 8;
	g_return_val_if_fail (bytes <= 4, -1);

	for (i = 0; i < 128; i++)
		in[i] = i + 128;

	for (j = 0; tables[j].name && !tables[j].multibyte; j++) {
		cd = iconv_open (UCS, tables[j].name);
		inbuf = in;
		inleft = sizeof (in);
		outbuf = (gchar *) out;
		outleft = sizeof (out);
		while (iconv (cd, &inbuf, &inleft, &outbuf, &outleft) == -1) {
			if (errno == EILSEQ) {
				inbuf++;
				inleft--;
			} else {
				g_warning (
					"iconv (%s->UCS4, ..., %d, ..., %d): %s",
					tables[j].name, inleft, outleft,
					g_strerror (errno));
				exit (1);
			}
		}
		iconv_close (cd);

		for (i = 0; i < 128 - outleft / 4; i++) {
			encoding_map[i] |= bit;
			encoding_map[out[i]] |= bit;
		}

		tables[j].bit = bit;
		bit <<= 1;
	}

	/* Mutibyte tables */
	for (; tables[j].name && tables[j].multibyte; j++) {
		cd = iconv_open (tables[j].name, UCS);
		if (cd == (GIConv) -1)
			continue;

		for (c = 128, i = 0; c < 65535 && i < 65535; c++) {
			inbuf = (gchar *) &c;
			inleft = sizeof (c);
			outbuf = in;
			outleft = sizeof (in);

			if (iconv (cd, &inbuf, &inleft, &outbuf, &outleft) != (gsize) -1) {
				/* this is a legal character in charset table[j].name */
				iconv (cd, NULL, NULL, &outbuf, &outleft);
				encoding_map[i++] |= bit;
				encoding_map[c] |= bit;
			} else {
				/* reset the iconv descriptor */
				iconv (cd, NULL, NULL, NULL, NULL);
			}
		}

		iconv_close (cd);

		tables[j].bit = bit;
		bit <<= 1;
	}

	printf ("/* This file is automatically generated: DO NOT EDIT */\n\n");

	table_hash = g_hash_table_new_full (block_hash, block_equal, g_free, g_free);

	for (i = 0; i < 256; i++) {
		for (k = 0; k < bytes; k++) {
			gchar name[32], *alias;
			gint has_bits = FALSE;

			if (!block) {
				/* we reuse malloc'd blocks that are not added to the
				 * hash table to avoid unnecessary malloc/free's */
				block = g_malloc (256);
			}

			for (j = 0; j < 256; j++) {
				if ((block[j] = (encoding_map[i * 256 + j] >> (k * 8)) & 0xff))
					has_bits = TRUE;
			}

			if (!has_bits)
				continue;

			g_snprintf (name, sizeof (name), "m%02x%x", i, k);

			if ((alias = g_hash_table_lookup (table_hash, block))) {
				/* this block is identical to an earlier block, just alias it */
				printf ("#define %s %s\n\n", name, alias);
			} else {
				/* unique block, dump it */
				g_hash_table_insert (table_hash, block, g_strdup (name));

				printf ("static guchar %s[256] = {\n\t", name);
				for (j = 0; j < 256; j++) {
					printf ("0x%02x, ", block[j]);
					if (((j + 1) & 7) == 0 && j < 255)
						printf ("\n\t");
				}
				printf ("\n};\n\n");

				/* force the next loop to malloc a new block */
				block = NULL;
			}
		}
	}

	g_hash_table_destroy (table_hash);
	g_free (block);

	printf ("static const struct {\n");
	for (k = 0; k < bytes; k++)
		printf ("\tconst guchar *bits%d;\n", k);

	printf ("} camel_charmap[256] = {\n\t");
	for (i = 0; i < 256; i++) {
		printf ("{ ");
		for (k = 0; k < bytes; k++) {
			for (j = 0; j < 256; j++) {
				if ((encoding_map[i * 256 + j] & (0xff << (k * 8))) != 0)
					break;
			}

			if (j < 256)
				printf ("m%02x%x, ", i, k);
			else
				printf ("NULL, ");
		}

		printf ("}, ");
		if (((i + 1) & 3) == 0 && i < 255)
			printf ("\n\t");
	}
	printf ("\n};\n\n");

	printf (
		"static const struct {\n"
		"\tconst gchar *name;\n"
		"\tguint bit;\n"
		"} camel_charinfo[] = {\n");
	for (j = 0; tables[j].name; j++)
		printf (
			"\t{ \"%s\", 0x%08x },\n",
			tables[j].name, tables[j].bit);
	printf ("};\n\n");

	printf ("#define charset_mask(x) \\\n");
	for (k = 0; k < bytes; k++) {
		if (k != 0)
			printf ("\t| ");
		else
			printf ("\t");

		printf (
			"(camel_charmap[(x) >> 8].bits%d ? "
			"camel_charmap[(x) >> 8].bits%d[(x) & 0xff] << %d : 0)",
			k, k, k * 8);

		if (k < bytes - 1)
			printf ("\t\\\n");
	}
	printf ("\n\n");

	return 0;
}

#else

#include "camel-charset-map.h"
#include "camel-charset-map-private.h"
#include "camel-utf8.h"

void
camel_charset_init (CamelCharset *c)
{
	c->mask = (guint) ~0;
	c->level = 0;
}

/**
 * camel_charset_step:
 * @cc: a #CamelCharset
 * @in: (array length=len) (type gchar): input text
 * @len: length of the input text
 *
 * Processes more input text with the @cc.
 **/
void
camel_charset_step (CamelCharset *cc,
                    const gchar *in,
                    gint len)
{
	const guchar *inptr = (const guchar *) in;
	const guchar *inend = inptr + len;
	register guint mask;
	register gint level;
	register guint32 c;

	mask = cc->mask;
	level = cc->level;

	/* check what charset a given string will fit in */
	while ((c = camel_utf8_getc_limit (&inptr, inend)) != 0xffff) {
		if (c < 0xffff) {
			mask &= charset_mask (c);

			if (c >= 128 && c < 256)
				level = MAX (level, 1);
			else if (c >= 256)
				level = 2;
		} else {
			mask = 0;
			level = 2;
			break;
		}
	}

	cc->mask = mask;
	cc->level = level;
}

/* gets the best charset from the mask of chars in it */
static const gchar *
camel_charset_best_mask (guint mask)
{
	const gchar *locale_lang, *lang;
	gint i;

	locale_lang = camel_iconv_locale_language ();
	for (i = 0; i < G_N_ELEMENTS (camel_charinfo); i++) {
		if (camel_charinfo[i].bit & mask) {
			lang = camel_iconv_charset_language (camel_charinfo[i].name);

			if (!locale_lang || (lang && !strncmp (locale_lang, lang, 2)))
				return camel_charinfo[i].name;
		}
	}

	return "UTF-8";
}

const gchar *
camel_charset_best_name (CamelCharset *charset)
{
	if (charset->level == 1)
		return "ISO-8859-1";
	else if (charset->level == 2)
		return camel_charset_best_mask (charset->mask);
	else
		return NULL;
}

/**
 * camel_charset_best:
 * @in: (array length=len) (type gchar): input text
 * @len: length of the input text
 *
 * Finds the minimum charset for this string NULL means US-ASCII.
 *
 * Returns: (nullable): the minimum charset or NULL for US_ASCII.
 **/
const gchar *
camel_charset_best (const gchar *in,
                    gint len)
{
	CamelCharset charset;

	camel_charset_init (&charset);
	camel_charset_step (&charset, in, len);
	return camel_charset_best_name (&charset);
}

/**
 * camel_charset_iso_to_windows:
 * @isocharset: a canonicalised ISO charset
 *
 * Returns: the equivalent Windows charset.
 **/
const gchar *
camel_charset_iso_to_windows (const gchar *isocharset)
{
	/* According to http://czyborra.com/charsets/codepages.html,
	 * the charset mapping is as follows:
	 *
	 * us-ascii    maps to windows-cp1252
	 * iso-8859-1  maps to windows-cp1252
	 * iso-8859-2  maps to windows-cp1250
	 * iso-8859-3  maps to windows-cp????
	 * iso-8859-4  maps to windows-cp????
	 * iso-8859-5  maps to windows-cp1251
	 * iso-8859-6  maps to windows-cp1256
	 * iso-8859-7  maps to windows-cp1253
	 * iso-8859-8  maps to windows-cp1255
	 * iso-8859-9  maps to windows-cp1254
	 * iso-8859-10 maps to windows-cp????
	 * iso-8859-11 maps to windows-cp????
	 * iso-8859-12 maps to windows-cp????
	 * iso-8859-13 maps to windows-cp1257
	 *
	 * Assumptions:
	 *  - I'm going to assume that since iso-8859-4 and
	 *    iso-8859-13 are Baltic that it also maps to
	 *    windows-cp1257.
	 */

	if (!g_ascii_strcasecmp (isocharset, "iso-8859-1") || !g_ascii_strcasecmp (isocharset, "us-ascii"))
		return "windows-cp1252";
	else if (!g_ascii_strcasecmp (isocharset, "iso-8859-2"))
		return "windows-cp1250";
	else if (!g_ascii_strcasecmp (isocharset, "iso-8859-4"))
		return "windows-cp1257";
	else if (!g_ascii_strcasecmp (isocharset, "iso-8859-5"))
		return "windows-cp1251";
	else if (!g_ascii_strcasecmp (isocharset, "iso-8859-6"))
		return "windows-cp1256";
	else if (!g_ascii_strcasecmp (isocharset, "iso-8859-7"))
		return "windows-cp1253";
	else if (!g_ascii_strcasecmp (isocharset, "iso-8859-8"))
		return "windows-cp1255";
	else if (!g_ascii_strcasecmp (isocharset, "iso-8859-9"))
		return "windows-cp1254";
	else if (!g_ascii_strcasecmp (isocharset, "iso-8859-13"))
		return "windows-cp1257";

	return isocharset;
}

#endif /* BUILD_MAP */
