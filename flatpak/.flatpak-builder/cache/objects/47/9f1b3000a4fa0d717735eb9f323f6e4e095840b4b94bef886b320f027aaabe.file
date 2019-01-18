/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-iconv.c
 *
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
 *          Jeffery Stedfast <fejj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <locale.h>

#ifdef HAVE_CODESET
#include <langinfo.h>
#endif

#include "camel-iconv.h"
#include "iconv-detect.h"

#define cd(x)

G_LOCK_DEFINE_STATIC (iconv);

struct _iconv_cache_node {
	struct _iconv_cache *parent;

	gint busy;
	GIConv ip;
};

struct _iconv_cache {
	gchar *conv;
	GQueue open;	/* stores iconv_cache_nodes, busy ones up front */
};

#define E_ICONV_CACHE_SIZE (16)

static GQueue iconv_cache_list = G_QUEUE_INIT;
static GHashTable *iconv_cache;
static GHashTable *iconv_cache_open;

static GHashTable *iconv_charsets = NULL;
static gchar *locale_charset = NULL;
static gchar *locale_lang = NULL;

struct {
	const gchar *charset;
	const gchar *iconv_name;
} known_iconv_charsets[] = {
#if 0
	/* charset name, iconv-friendly charset name */
	{ "iso-8859-1",     "iso-8859-1" },
	{ "iso8859-1",      "iso-8859-1" },
	/* the above mostly serves as an example for iso-style charsets,
	 * but we have code that will populate the iso-*'s if/when they
	 * show up in camel_iconv_charset_name () so I'm
	 * not going to bother putting them all in here... */
	{ "windows-cp1251", "cp1251"     },
	{ "windows-1251",   "cp1251"     },
	{ "cp1251",         "cp1251"     },
	/* the above mostly serves as an example for windows-style
	 * charsets, but we have code that will parse and convert them
	 * to their cp#### equivalents if/when they show up in
	 * camel_iconv_charset_name () so I'm not going to bother
	 * putting them all in here either... */
#endif
	/* charset name (lowercase!), iconv-friendly name (sometimes case sensitive) */
	{ "utf-8",          "UTF-8"      },

	/* 10646 is a special case, its usually UCS-2 big endian */
	/* This might need some checking but should be ok for solaris/linux */
	{ "iso-10646-1",    "UCS-2BE"    },
	{ "iso_10646-1",    "UCS-2BE"    },
	{ "iso10646-1",     "UCS-2BE"    },
	{ "iso-10646",      "UCS-2BE"    },
	{ "iso_10646",      "UCS-2BE"    },
	{ "iso10646",       "UCS-2BE"    },

	{ "ks_c_5601-1987", "EUC-KR"     },

	/* FIXME: Japanese/Korean/Chinese stuff needs checking */
	{ "euckr-0",        "EUC-KR"     },
	{ "5601",           "EUC-KR"     },
	{ "zh_TW-euc",      "EUC-TW"     },
	{ "zh_CN.euc",      "gb18030"    },
	{ "zh_TW-big5",     "BIG5"       },
	{ "euc-cn",         "gb18030"    },
	{ "big5-0",         "BIG5"       },
	{ "big5.eten-0",    "BIG5"       },
	{ "big5hkscs-0",    "BIG5HKSCS"  },
	{ "gb2312-0",       "gb18030"    },
	{ "gb2312.1980-0",  "gb18030"    },
	{ "gb-2312",        "gb18030"    },
	{ "gb2312",         "gb18030"    },
	{ "gb18030-0",      "gb18030"    },
	{ "gbk-0",          "GBK"        },

	{ "eucjp-0",        "eucJP"	 },
	{ "ujis-0",         "ujis"	 },
	{ "jisx0208.1983-0","SJIS"       },
	{ "jisx0212.1990-0","SJIS"       },
	{ "pck",	    "SJIS"       },
	{ NULL,             NULL         }
};

static const gchar *
e_strdown (gchar *str)
{
	register gchar *s = str;

	while (*s) {
		if (*s >= 'A' && *s <= 'Z')
			*s += 0x20;
		s++;
	}

	return str;
}

static const gchar *
e_strup (gchar *str)
{
	register gchar *s = str;

	while (*s) {
		if (*s >= 'a' && *s <= 'z')
			*s -= 0x20;
		s++;
	}

	return str;
}

static void
locale_parse_lang (const gchar *locale)
{
	gchar *codeset, *lang;

	if ((codeset = strchr (locale, '.')))
		lang = g_strndup (locale, codeset - locale);
	else
		lang = g_strdup (locale);

	/* validate the language */
	if (strlen (lang) >= 2) {
		if (lang[2] == '-' || lang[2] == '_') {
			/* canonicalise the lang */
			e_strdown (lang);

			/* validate the country code */
			if (strlen (lang + 3) > 2) {
				/* invalid country code */
				lang[2] = '\0';
			} else {
				lang[2] = '-';
				e_strup (lang + 3);
			}
		} else if (lang[2] != '\0') {
			/* invalid language */
			g_free (lang);
			lang = NULL;
		}

		locale_lang = lang;
	} else {
		/* invalid language */
		locale_lang = NULL;
		g_free (lang);
	}
}

/* NOTE: Owns the lock on return if keep is TRUE !*/
static void
iconv_init (gint keep)
{
	gchar *from, *to, *locale;
	gint i;

	G_LOCK (iconv);

	if (iconv_charsets != NULL) {
		if (!keep)
			G_UNLOCK (iconv);
		return;
	}

	iconv_charsets = g_hash_table_new (g_str_hash, g_str_equal);

	for (i = 0; known_iconv_charsets[i].charset != NULL; i++) {
		from = g_strdup (known_iconv_charsets[i].charset);
		to = g_strdup (known_iconv_charsets[i].iconv_name);
		e_strdown (from);
		g_hash_table_insert (iconv_charsets, from, to);
	}

	iconv_cache = g_hash_table_new (g_str_hash, g_str_equal);
	iconv_cache_open = g_hash_table_new (NULL, NULL);

#ifndef G_OS_WIN32
	locale = setlocale (LC_ALL, NULL);
#else
	locale = g_win32_getlocale ();
#endif

	if (!locale || !strcmp (locale, "C") || !strcmp (locale, "POSIX")) {
		/* The locale "C"  or  "POSIX"  is  a  portable  locale;  its
		 * LC_CTYPE  part  corresponds  to  the 7-bit ASCII character
		 * set.
		 */

		locale_charset = NULL;
		locale_lang = NULL;
	} else {
#ifdef G_OS_WIN32
		g_get_charset (&locale_charset);
		locale_charset = g_strdup (locale_charset);
		e_strdown (locale_charset);
#else
#ifdef HAVE_CODESET
		locale_charset = g_strdup (nl_langinfo (CODESET));
		e_strdown (locale_charset);
#else
		/* A locale name is typically of  the  form  language[_terri-
		 * tory][.codeset][@modifier],  where  language is an ISO 639
		 * language code, territory is an ISO 3166 country code,  and
		 * codeset  is  a  character  set or encoding identifier like
		 * ISO-8859-1 or UTF-8.
		 */
		gchar *codeset, *p;

		codeset = strchr (locale, '.');
		if (codeset) {
			codeset++;

			/* ; is a hack for debian systems and / is a hack for Solaris systems */
			for (p = codeset; *p && !strchr ("@;/", *p); p++);
			locale_charset = g_strndup (codeset, p - codeset);
			e_strdown (locale_charset);
		} else {
			/* charset unknown */
			locale_charset = NULL;
		}
#endif
#endif	/* !G_OS_WIN32 */

		/* parse the locale lang */
		locale_parse_lang (locale);

	}

#ifdef G_OS_WIN32
	g_free (locale);
#endif
	if (!keep)
		G_UNLOCK (iconv);
}

const gchar *
camel_iconv_charset_name (const gchar *charset)
{
	gchar *name, *ret, *tmp;
	gsize name_len;

	if (charset == NULL)
		return NULL;

	name_len = strlen (charset) + 1;
	name = g_alloca (name_len);
	g_strlcpy (name, charset, name_len);
	e_strdown (name);

	iconv_init (TRUE);
	ret = g_hash_table_lookup (iconv_charsets, name);
	if (ret != NULL) {
		G_UNLOCK (iconv);
		return ret;
	}

	/* Unknown, try canonicalise some basic charset types to something that should work */
	if (strncmp (name, "iso", 3) == 0) {
		/* Convert iso-nnnn-n or isonnnn-n or iso_nnnn-n to iso-nnnn-n or isonnnn-n */
		gint iso, codepage;
		gchar *p;

		tmp = name + 3;
		if (*tmp == '-' || *tmp == '_')
			tmp++;

		iso = strtoul (tmp, &p, 10);

		if (iso == 10646) {
			/* they all become ICONV_10646 */
			ret = g_strdup (ICONV_10646);
		} else {
			tmp = p;
			if (*tmp == '-' || *tmp == '_')
				tmp++;

			codepage = strtoul (tmp, &p, 10);

			if (p > tmp) {
				/* codepage is numeric */
#ifdef __aix__
				if (codepage == 13)
					ret = g_strdup ("IBM-921");
				else
#endif /* __aix__ */
					ret = g_strdup_printf (ICONV_ISO_D_FORMAT, iso, codepage);
			} else {
				/* codepage is a string - probably iso-2022-jp or something */
				ret = g_strdup_printf (ICONV_ISO_S_FORMAT, iso, p);
			}
		}
	} else if (strncmp (name, "windows-", 8) == 0) {
		/* Convert windows-nnnnn or windows-cpnnnnn to cpnnnn */
		tmp = name + 8;
		if (!strncmp (tmp, "cp", 2))
			tmp+=2;
		ret = g_strdup_printf ("CP%s", tmp);
	} else if (strncmp (name, "microsoft-", 10) == 0) {
		/* Convert microsoft-nnnnn or microsoft-cpnnnnn to cpnnnn */
		tmp = name + 10;
		if (!strncmp (tmp, "cp", 2))
			tmp+=2;
		ret = g_strdup_printf ("CP%s", tmp);
	} else {
		/* Just assume its ok enough as is, case and all */
		ret = g_strdup (charset);
	}

	g_hash_table_insert (iconv_charsets, g_strdup (name), ret);
	G_UNLOCK (iconv);

	return ret;
}

static void
flush_entry (struct _iconv_cache *ic)
{
	struct _iconv_cache_node *in;

	while ((in = g_queue_pop_head (&ic->open)) != NULL) {
		if (in->ip != (GIConv) -1) {
			g_hash_table_remove (iconv_cache_open, in->ip);
			g_iconv_close (in->ip);
		}
		g_free (in);
	}

	g_free (ic->conv);
	g_free (ic);
}

/**
 * camel_iconv_open: (skip)
 * @to: charset to convert to
 * @from: charset to covert from
 *
 * Returns: a #GIConv for the conversion from charset @from to charset @to, or (GIConv) -1 on error.
 **/
GIConv
camel_iconv_open (const gchar *to,
                  const gchar *from)
{
	const gchar *nto, *nfrom;
	gchar *tofrom;
	gsize tofrom_len;
	struct _iconv_cache *ic;
	struct _iconv_cache_node *in;
	gint errnosav;
	GIConv ip;

	if (to == NULL || from == NULL) {
		errno = EINVAL;
		return (GIConv) -1;
	}

	nto = camel_iconv_charset_name (to);
	nfrom = camel_iconv_charset_name (from);
	tofrom_len = strlen (nto) + strlen (nfrom) + 2;
	tofrom = g_alloca (tofrom_len);
	g_snprintf (tofrom, tofrom_len, "%s%%%s", nto, nfrom);

	G_LOCK (iconv);

	ic = g_hash_table_lookup (iconv_cache, tofrom);
	if (ic) {
		g_queue_remove (&iconv_cache_list, ic);
	} else {
		GList *link;

		link = g_queue_peek_tail_link (&iconv_cache_list);

		while (link != NULL && iconv_cache_list.length > E_ICONV_CACHE_SIZE) {
			GList *prev = g_list_previous (link);

			ic = (struct _iconv_cache *) link->data;
			in = g_queue_peek_head (&ic->open);

			if (in != NULL && !in->busy) {
				cd (printf ("Flushing iconv converter '%s'\n", ic->conv));
				g_queue_delete_link (&iconv_cache_list, link);
				g_hash_table_remove (iconv_cache, ic->conv);
				flush_entry (ic);
			}

			link = prev;
		}

		ic = g_malloc (sizeof (*ic));
		g_queue_init (&ic->open);
		ic->conv = g_strdup (tofrom);
		g_hash_table_insert (iconv_cache, ic->conv, ic);

		cd (printf ("Creating iconv converter '%s'\n", ic->conv));
	}

	g_queue_push_head (&iconv_cache_list, ic);

	/* If we have a free iconv, use it */
	in = g_queue_peek_tail (&ic->open);
	if (in != NULL && !in->busy) {
		cd (printf ("using existing iconv converter '%s'\n", ic->conv));
		ip = in->ip;
		if (ip != (GIConv) -1) {
			/* work around some broken iconv implementations
			 * that die if the length arguments are NULL
			 */
			gsize buggy_iconv_len = 0;
			gchar *buggy_iconv_buf = NULL;

			/* resets the converter */
			g_iconv (ip, &buggy_iconv_buf, &buggy_iconv_len, &buggy_iconv_buf, &buggy_iconv_len);
			in->busy = TRUE;
			g_queue_remove (&ic->open, in);
			g_queue_push_head (&ic->open, in);
		}
	} else {
		cd (printf ("creating new iconv converter '%s'\n", ic->conv));
		ip = g_iconv_open (nto, nfrom);
		in = g_malloc (sizeof (*in));
		in->ip = ip;
		in->parent = ic;
		g_queue_push_head (&ic->open, in);
		if (ip != (GIConv) -1) {
			g_hash_table_insert (iconv_cache_open, ip, in);
			in->busy = TRUE;
		} else {
			errnosav = errno;
			g_warning ("Could not open converter for '%s' to '%s' charset", nfrom, nto);
			in->busy = FALSE;
			errno = errnosav;
		}
	}

	G_UNLOCK (iconv);

	return ip;
}

gsize
camel_iconv (GIConv cd,
             const gchar **inbuf,
             gsize *inbytesleft,
             gchar **outbuf,
             gsize *outbytesleft)
{
	return g_iconv (cd, (gchar **) inbuf, inbytesleft, outbuf, outbytesleft);
}

void
camel_iconv_close (GIConv ip)
{
	struct _iconv_cache_node *in;

	if (ip == (GIConv) -1)
		return;

	G_LOCK (iconv);
	in = g_hash_table_lookup (iconv_cache_open, ip);
	if (in) {
		cd (printf ("closing iconv converter '%s'\n", in->parent->conv));
		g_queue_remove (&in->parent->open, in);
		in->busy = FALSE;
		g_queue_push_tail (&in->parent->open, in);
	} else {
		g_warning ("trying to close iconv i dont know about: %p", ip);
		g_iconv_close (ip);
	}
	G_UNLOCK (iconv);
}

const gchar *
camel_iconv_locale_charset (void)
{
	iconv_init (FALSE);

	return locale_charset;
}

const gchar *
camel_iconv_locale_language (void)
{
	iconv_init (FALSE);

	return locale_lang;
}

/* map CJKR charsets to their language code */
/* NOTE: only support charset names that will be returned by
 * camel_iconv_charset_name() so that we don't have to keep track of all
 * the aliases too. */
static struct {
	const gchar *charset;
	const gchar *lang;
} cjkr_lang_map[] = {
	{ "Big5",        "zh" },
	{ "BIG5HKSCS",   "zh" },
	{ "gb2312",      "zh" },
	{ "gb18030",     "zh" },
	{ "gbk",         "zh" },
	{ "euc-tw",      "zh" },
	{ "iso-2022-jp", "ja" },
	{ "sjis",        "ja" },
	{ "ujis",        "ja" },
	{ "eucJP",       "ja" },
	{ "euc-jp",      "ja" },
	{ "euc-kr",      "ko" },
	{ "koi8-r",      "ru" },
	{ "koi8-u",      "uk" }
};

const gchar *
camel_iconv_charset_language (const gchar *charset)
{
	gint i;

	if (!charset)
		return NULL;

	charset = camel_iconv_charset_name (charset);
	for (i = 0; i < G_N_ELEMENTS (cjkr_lang_map); i++) {
		if (!g_ascii_strcasecmp (cjkr_lang_map[i].charset, charset))
			return cjkr_lang_map[i].lang;
	}

	return NULL;
}
