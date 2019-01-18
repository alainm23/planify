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
 *	    Michael Zucchi <NotZed@Ximian.com>
 */

#include "evolution-data-server-config.h"

/* POSIX requires <sys/types.h> be included before <regex.h> */
#include <sys/types.h>

#include <ctype.h>
#include <regex.h>
#include <stdio.h>
#include <string.h>

#include <glib/gi18n-lib.h>

#include "camel-mime-message.h"
#include "camel-multipart.h"
#include "camel-search-private.h"
#include "camel-stream-mem.h"

#define d(x)

/* builds the regex into pattern */
/* taken from camel-folder-search, with added isregex & exception parameter */
/* Basically, we build a new regex, either based on subset regex's, or
 * substrings, that can be executed once over the whoel body, to match
 * anything suitable.  This is more efficient than multiple searches,
 * and probably most (naive) strstr implementations, over long content.
 *
 * A small issue is that case-insenstivity won't work entirely correct
 * for utf8 strings. */
/**
 * camel_search_build_match_regex: (skip)
 **/
gint
camel_search_build_match_regex (regex_t *pattern,
                                camel_search_flags_t type,
                                gint argc,
                                struct _CamelSExpResult **argv,
                                GError **error)
{
	GString *match = g_string_new ("");
	gint c, i, count = 0, err;
	gchar *word;
	gint flags;

	/* Build a regex pattern we can use to match the words,
	 * we OR them together. */
	if (argc > 1)
		g_string_append_c (match, '(');
	for (i = 0; i < argc; i++) {
		if (argv[i]->type == CAMEL_SEXP_RES_STRING) {
			if (count > 0)
				g_string_append_c (match, '|');

			word = argv[i]->value.string;
			if (type & CAMEL_SEARCH_MATCH_REGEX) {
				/* No need to escape because this
				 * should already be a valid regex. */
				g_string_append (match, word);
			} else {
				/* Escape any special chars (not
				 * sure if this list is complete). */
				if (type & CAMEL_SEARCH_MATCH_START)
					g_string_append_c (match, '^');
				while ((c = *word++)) {
					if (strchr ("*\\.()[]^$+", c) != NULL) {
						g_string_append_c (match, '\\');
					}
					g_string_append_c (match, c);
				}
				if (type & CAMEL_SEARCH_MATCH_END)
					g_string_append_c (match, '^');
			}
			count++;
		} else {
			g_warning ("Invalid type passed to body-contains match function");
		}
	}
	if (argc > 1)
		g_string_append_c (match, ')');
	flags = REG_EXTENDED | REG_NOSUB;
	if (type & CAMEL_SEARCH_MATCH_ICASE)
		flags |= REG_ICASE;
	if (type & CAMEL_SEARCH_MATCH_NEWLINE)
		flags |= REG_NEWLINE;
	err = regcomp (pattern, match->str, flags);
	if (err != 0) {
		/* regerror gets called twice to get the full error
		 * string length to do proper posix error reporting. */
		gint len = regerror (err, pattern, NULL, 0);
		gchar *buffer = g_malloc0 (len + 1);

		regerror (err, pattern, buffer, len);
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Regular expression compilation failed: %s: %s"),
			match->str, buffer);

		regfree (pattern);
	}
	d (printf ("Built regex: '%s'\n", match->str));
	g_string_free (match, TRUE);

	return err;
}

static guchar soundex_table[256] = {
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	  0,  0, 49, 50, 51,  0, 49, 50,  0,  0, 50, 50, 52, 53, 53,  0,
	 49, 50, 54, 50, 51,  0, 49,  0, 50,  0, 50,  0,  0,  0,  0,  0,
	  0,  0, 49, 50, 51,  0, 49, 50,  0,  0, 50, 50, 52, 53, 53,  0,
	 49, 50, 54, 50, 51,  0, 49,  0, 50,  0, 50,  0,  0,  0,  0,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
	  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
};

static void
soundexify (const gchar *sound,
            gchar code[5])
{
	guchar *c, last = '\0';
	gint n;

	for (c = (guchar *) sound; *c && !isalpha (*c); c++);
	code[0] = toupper (*c);
	memset (code + 1, 0, 3);
	for (n = 1; *c && n < 5; c++) {
		guchar ch = soundex_table[*c];

		if (ch && ch != last) {
			code[n++] = ch;
			last = ch;
		}
	}
	code[4] = '\0';
}

static gboolean
header_soundex (const gchar *header,
                const gchar *match)
{
	gchar mcode[5], hcode[5];
	const gchar *p;
	gchar c;
	GString *word;
	gint truth = FALSE;

	soundexify (match, mcode);

	/* Split the header into words and soundexify and compare each one. */
	/* FIXME: Should this convert to utf8, and split based on that,
	 *        and what not?
	 *        soundex only makes sense for us-ascii though ... */

	word = g_string_new ("");
	p = header;
	do {
		c = *p++;
		if (c == 0 || isspace (c)) {
			if (word->len > 0) {
				soundexify (word->str, hcode);
				if (strcmp (hcode, mcode) == 0)
					truth = TRUE;
			}
			g_string_truncate (word, 0);
		} else if (isalpha (c))
			g_string_append_c (word, c);
	} while (c && !truth);
	g_string_free (word, TRUE);

	return truth;
}

const gchar *
camel_ustrstrcase (const gchar *haystack,
                   const gchar *needle)
{
	gunichar *nuni, *puni;
	gunichar u;
	const guchar *p;

	g_return_val_if_fail (haystack != NULL, NULL);
	g_return_val_if_fail (needle != NULL, NULL);

	if (strlen (needle) == 0)
		return haystack;
	if (strlen (haystack) == 0)
		return NULL;

	puni = nuni = g_alloca (sizeof (gunichar) * (strlen (needle) + 1));
	nuni[0] = 0;

	p = (const guchar *) needle;
	while ((u = camel_utf8_getc (&p)))
		*puni++ = g_unichar_tolower (u);

	/* NULL means there was illegal utf-8 sequence. */
	if (!p)
		return NULL;

	p = (const guchar *) haystack;
	while ((u = camel_utf8_getc (&p))) {
		gunichar c;

		c = g_unichar_tolower (u);
		/* We have valid stripped gchar. */
		if (c == nuni[0]) {
			const guchar *q = p;
			gint npos = 1;

			while (nuni + npos < puni) {
				u = camel_utf8_getc (&q);
				if (!q || !u)
					return NULL;

				c = g_unichar_tolower (u);
				if (c != nuni[npos])
					break;

				npos++;
			}

			if (nuni + npos == puni)
				return (const gchar *) p;
		}
	}

	return NULL;
}

#define CAMEL_SEARCH_COMPARE(x, y, z) G_STMT_START { \
	if ((x) == (z)) { \
		if ((y) == (z)) \
			return 0; \
		else \
			return -1; \
	} else if ((y) == (z)) \
		return 1; \
} G_STMT_END

static gint
camel_ustrcasecmp (const gchar *ps1,
                   const gchar *ps2)
{
	gunichar u1, u2 = 0;
	const guchar *s1 = (const guchar *) ps1;
	const guchar *s2 = (const guchar *) ps2;

	CAMEL_SEARCH_COMPARE (s1, s2, NULL);

	u1 = camel_utf8_getc (&s1);
	u2 = camel_utf8_getc (&s2);
	while (u1 && u2) {
		u1 = g_unichar_tolower (u1);
		u2 = g_unichar_tolower (u2);
		if (u1 < u2)
			return -1;
		else if (u1 > u2)
			return 1;

		u1 = camel_utf8_getc (&s1);
		u2 = camel_utf8_getc (&s2);
	}

	/* end of one of the strings ? */
	CAMEL_SEARCH_COMPARE (u1, u2, 0);

	/* if we have invalid utf8 sequence ? */
	/* coverity[dead_error_begin] */
	CAMEL_SEARCH_COMPARE (s1, s2, NULL);

	return 0;
}

static gchar *
depunct_string (const gchar *str)
{
	gchar *res;
	gint ii;

	g_return_val_if_fail (str != NULL, NULL);

	res = g_strdup (str);
	for (ii = 0; res[ii]; ii++) {
		if (ispunct (res[ii]))
			res[ii] = ' ';
	}

	return res;
}

static gboolean
camel_uwordcase (const gchar *haystack,
                 const gchar *needle)
{
	struct _camel_search_words *hwords, *nwords;
	gchar *copy_haystack, *copy_needle;
	gboolean found_all;
	gint ii, jj;

	g_return_val_if_fail (haystack != NULL, FALSE);
	g_return_val_if_fail (needle != NULL, FALSE);

	if (!*needle)
		return TRUE;
	if (!*haystack)
		return FALSE;

	copy_haystack = depunct_string (haystack);
	copy_needle = depunct_string (needle);
	hwords = camel_search_words_split ((const guchar *) copy_haystack);
	nwords = camel_search_words_split ((const guchar *) copy_needle);
	g_free (copy_haystack);
	g_free (copy_needle);

	found_all = TRUE;
	for (ii = 0; ii < nwords->len && found_all; ii++) {
		found_all = FALSE;

		for (jj = 0; jj < hwords->len; jj++) {
			if (camel_ustrcasecmp (hwords->words[jj]->word, nwords->words[ii]->word) == 0) {
				found_all = TRUE;
				break;
			}
		}
	}

	camel_search_words_free (hwords);
	camel_search_words_free (nwords);

	return found_all;
}

static gint
camel_ustrncasecmp (const gchar *ps1,
                    const gchar *ps2,
                    gsize len)
{
	gunichar u1, u2 = 0;
	const guchar *s1 = (const guchar *) ps1;
	const guchar *s2 = (const guchar *) ps2;

	CAMEL_SEARCH_COMPARE (s1, s2, NULL);

	u1 = camel_utf8_getc (&s1);
	u2 = camel_utf8_getc (&s2);
	while (len > 0 && u1 && u2) {
		u1 = g_unichar_tolower (u1);
		u2 = g_unichar_tolower (u2);
		if (u1 < u2)
			return -1;
		else if (u1 > u2)
			return 1;

		len--;
		u1 = camel_utf8_getc (&s1);
		u2 = camel_utf8_getc (&s2);
	}

	if (len == 0)
		return 0;

	/* end of one of the strings ? */
	CAMEL_SEARCH_COMPARE (u1, u2, 0);

	/* if we have invalid utf8 sequence ? */
	/* coverity[dead_error_begin] */
	CAMEL_SEARCH_COMPARE (s1, s2, NULL);

	return 0;
}

/* Value is the match value suitable for exact match if required. */
static gint
header_match (const gchar *value,
              const gchar *match,
              camel_search_match_t how)
{
	gint vlen, mlen;

	if (how == CAMEL_SEARCH_MATCH_SOUNDEX)
		return header_soundex (value, match);

	vlen = strlen (value);
	mlen = strlen (match);
	if (vlen < mlen)
		return FALSE;

	switch (how) {
	case CAMEL_SEARCH_MATCH_EXACT:
		return camel_ustrcasecmp (value, match) == 0;
	case CAMEL_SEARCH_MATCH_CONTAINS:
		return camel_ustrstrcase (value, match) != NULL;
	case CAMEL_SEARCH_MATCH_WORD:
		return camel_uwordcase (value, match);
	case CAMEL_SEARCH_MATCH_STARTS:
		return camel_ustrncasecmp (value, match, mlen) == 0;
	case CAMEL_SEARCH_MATCH_ENDS:
		return camel_ustrcasecmp (value + vlen - mlen, match) == 0;
	default:
		break;
	}

	return FALSE;
}

/* Searches for match inside value.  If match is mixed
 * case, then use case-sensitive, else insensitive. */
gboolean
camel_search_header_match (const gchar *value,
                           const gchar *match,
                           camel_search_match_t how,
                           camel_search_t type,
                           const gchar *default_charset)
{
	const gchar *name, *addr;
	const guchar *ptr;
	gint truth = FALSE, i;
	CamelInternetAddress *cia;
	gchar *v, *vdom, *mdom, *unfolded;
	gunichar c;

	unfolded = camel_header_unfold (value);
	if (unfolded)
		value = unfolded;

	ptr = (const guchar *) value;
	while ((c = camel_utf8_getc (&ptr)) && g_unichar_isspace (c))
		value = (const gchar *) ptr;

	switch (type) {
	case CAMEL_SEARCH_TYPE_ENCODED:
		/* FIXME Find header charset. */
		v = camel_header_decode_string (value, default_charset);
		truth = header_match (v, match, how);
		g_free (v);
		break;
	case CAMEL_SEARCH_TYPE_MLIST:
		/* Special mailing list old-version domain hack.
		 * If one of the mailing list names doesn't have an @ in it,
		 * its old-style, so only match against the pre-domain part,
		 * which should be common. */
		vdom = strchr (value, '@');
		mdom = strchr (match, '@');
		if (mdom != NULL && mdom != match && vdom == NULL) {
			v = g_alloca (mdom - match + 1);
			memcpy (v, match, mdom - match);
			v[mdom - match] = 0;
			match = (gchar *) v;
		}
		/* Falls through */
	case CAMEL_SEARCH_TYPE_ASIS:
		truth = header_match (value, match, how);
		break;
	case CAMEL_SEARCH_TYPE_ADDRESS_ENCODED:
	case CAMEL_SEARCH_TYPE_ADDRESS:
		/* Possible simple case to save some work if we can. */
		if (header_match (value, match, how)) {
			truth = TRUE;
			break;
		}

		/* Now we decode any addresses, and try
		 * as-is matches on name and address parts. */
		cia = camel_internet_address_new ();
		if (type == CAMEL_SEARCH_TYPE_ADDRESS_ENCODED)
			camel_address_decode ((CamelAddress *) cia, value);
		else
			camel_address_unformat ((CamelAddress *) cia, value);

		for (i = 0; !truth && camel_internet_address_get (cia, i, &name, &addr); i++)
			truth =
				(name && header_match (name, match, how)) ||
				(addr && header_match (addr, match, how));

		g_object_unref (cia);
		break;
	}

	g_free (unfolded);

	return truth;
}

/* Performs a 'slow' content-based match. */
/* There is also an identical copy of this in camel-filter-search.c. */
/**
 * camel_search_message_body_contains: (skip)
 **/
gboolean
camel_search_message_body_contains (CamelDataWrapper *object,
                                    regex_t *pattern)
{
	CamelDataWrapper *containee;
	gint truth = FALSE;
	gint parts, i;

	containee = camel_medium_get_content (CAMEL_MEDIUM (object));

	if (containee == NULL)
		return FALSE;

	/* Using the object types is more accurate than using mime/types. */
	if (CAMEL_IS_MULTIPART (containee)) {
		parts = camel_multipart_get_number (CAMEL_MULTIPART (containee));
		for (i = 0; i < parts && truth == FALSE; i++) {
			CamelDataWrapper *part = (CamelDataWrapper *) camel_multipart_get_part (CAMEL_MULTIPART (containee), i);
			if (part)
				truth = camel_search_message_body_contains (part, pattern);
		}
	} else if (CAMEL_IS_MIME_MESSAGE (containee)) {
		/* For messages we only look at its contents. */
		truth = camel_search_message_body_contains ((CamelDataWrapper *) containee, pattern);
	} else if (camel_content_type_is (camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (containee)), "text", "*")
		|| camel_content_type_is (camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (containee)), "x-evolution", "evolution-rss-feed")) {
		/* For all other text parts we look
		 * inside, otherwise we don't care. */
		CamelStream *stream;
		GByteArray *byte_array;
		const gchar *charset;

		byte_array = g_byte_array_new ();
		stream = camel_stream_mem_new_with_byte_array (byte_array);

		charset = camel_content_type_param (camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (containee)), "charset");
		if (charset && *charset) {
			CamelMimeFilter *filter = camel_mime_filter_charset_new (charset, "UTF-8");
			if (filter) {
				CamelStream *filtered = camel_stream_filter_new (stream);

				if (filtered) {
					camel_stream_filter_add (CAMEL_STREAM_FILTER (filtered), filter);
					g_object_unref (stream);
					stream = filtered;
				}

				g_object_unref (filter);
			}
		}

		camel_data_wrapper_decode_to_stream_sync (
			containee, stream, NULL, NULL);
		camel_stream_write (stream, "", 1, NULL, NULL);
		truth = regexec (pattern, (gchar *) byte_array->data, 0, NULL, 0) == 0;
		g_object_unref (stream);
	}

	return truth;
}

static void
output_c (GString *w,
          guint32 c,
          gint *type)
{
	gint utf8len;
	gchar utf8[8];

	if (!g_unichar_isalnum (c))
		*type = CAMEL_SEARCH_WORD_COMPLEX | (*type & CAMEL_SEARCH_WORD_8BIT);
	else
		c = g_unichar_tolower (c);

	if (c > 0x80)
		*type |= CAMEL_SEARCH_WORD_8BIT;

	/* FIXME: use camel_utf8_putc */
	utf8len = g_unichar_to_utf8 (c, utf8);
	utf8[utf8len] = 0;
	g_string_append (w, utf8);
}

static void
output_w (GString *w,
          GPtrArray *list,
          gint type)
{
	struct _camel_search_word *word;

	if (w->len) {
		word = g_malloc0 (sizeof (*word));
		word->word = g_strdup (w->str);
		word->type = type;
		g_ptr_array_add (list, word);
		g_string_truncate (w, 0);
	}
}

struct _camel_search_words *
camel_search_words_split (const guchar *in)
{
	gint type = CAMEL_SEARCH_WORD_SIMPLE, all = 0;
	GString *w;
	struct _camel_search_words *words;
	GPtrArray *list = g_ptr_array_new ();
	guint32 c;
	gint inquote = 0;

	words = g_malloc0 (sizeof (*words));
	w = g_string_new ("");

	do {
		c = camel_utf8_getc (&in);

		if (c == 0
		    || (inquote && c == '"')
		    || (!inquote && g_unichar_isspace (c))) {
			output_w (w, list, type);
			all |= type;
			type = CAMEL_SEARCH_WORD_SIMPLE;
			inquote = 0;
		} else {
			if (c == '\\') {
				c = camel_utf8_getc (&in);
				if (c)
					output_c (w, c, &type);
				else {
					output_w (w, list, type);
					all |= type;
				}
			} else if (c == '\"') {
				inquote = 1;
			} else {
				output_c (w, c, &type);
			}
		}
	} while (c);

	g_string_free (w, TRUE);
	words->len = list->len;
	words->words = (struct _camel_search_word **) list->pdata;
	words->type = all;
	g_ptr_array_free (list, FALSE);

	return words;
}

/* Takes an existing 'words' list, and converts it to another consisting
 * of only simple words, with any punctuation, etc stripped. */
struct _camel_search_words *
camel_search_words_simple (struct _camel_search_words *wordin)
{
	gint i;
	const guchar *ptr, *start, *last;
	gint type = CAMEL_SEARCH_WORD_SIMPLE, all = 0;
	GPtrArray *list = g_ptr_array_new ();
	struct _camel_search_word *word;
	struct _camel_search_words *words;
	guint32 c;

	words = g_malloc0 (sizeof (*words));

	for (i = 0; i < wordin->len; i++) {
		if ((wordin->words[i]->type & CAMEL_SEARCH_WORD_COMPLEX) == 0) {
			word = g_malloc0 (sizeof (*word));
			word->type = wordin->words[i]->type;
			word->word = g_strdup (wordin->words[i]->word);
			g_ptr_array_add (list, word);
		} else {
			ptr = (const guchar *) wordin->words[i]->word;
			start = last = ptr;
			do {
				c = camel_utf8_getc (&ptr);
				if (c == 0 || !g_unichar_isalnum (c)) {
					if (last > start) {
						word = g_malloc0 (sizeof (*word));
						word->word = g_strndup ((gchar *) start, last - start);
						word->type = type;
						g_ptr_array_add (list, word);
						all |= type;
						type = CAMEL_SEARCH_WORD_SIMPLE;
					}
					start = ptr;
				}
				if (c > 0x80)
					type = CAMEL_SEARCH_WORD_8BIT;
				last = ptr;
			} while (c);
		}
	}

	words->len = list->len;
	words->words = (struct _camel_search_word **) list->pdata;
	words->type = all;
	g_ptr_array_free (list, FALSE);

	return words;
}

void
camel_search_words_free (struct _camel_search_words *words)
{
	gint i;

	for (i = 0; i < words->len; i++) {
		struct _camel_search_word *word = words->words[i];

		g_free (word->word);
		g_free (word);
	}
	g_free (words->words);
	g_free (words);
}

/**
 * camel_search_header_is_address:
 * @header_name: A header name, like "Subject"
 *
 * Returns: Whether the @header_name is a header with a mail address
 *
 * Since: 3.22
 **/
gboolean
camel_search_header_is_address (const gchar *header_name)
{
	const gchar *headers[] = {
		"Reply-To",
		"From",
		"To",
		"Cc",
		"Bcc",
		"Resent-From",
		"Resent-To",
		"Resent-Cc",
		"Resent-Bcc",
		NULL };
	gint ii;

	if (!header_name || !*header_name)
		return FALSE;

	for (ii = 0; headers[ii]; ii++) {
		if (g_ascii_strcasecmp (headers[ii], header_name) == 0)
			return TRUE;
	}

	return FALSE;
}

/**
 * camel_search_get_default_charset_from_message:
 * @message: a #CamelMimeMessage
 *
 * Returns: Default charset of the @message; if none cannot be determined,
 *    UTF-8 is returned.
 *
 * Since: 3.22
 **/
const gchar *
camel_search_get_default_charset_from_message (CamelMimeMessage *message)
{
	CamelContentType *ct;
	const gchar *charset;

	g_return_val_if_fail (CAMEL_IS_MIME_MESSAGE (message), NULL);

	ct = camel_mime_part_get_content_type (CAMEL_MIME_PART (message));
	charset = camel_content_type_param (ct, "charset");
	if (!charset)
		charset = "utf-8";

	charset = camel_iconv_charset_name (charset);

	return charset;
}

/**
 * camel_search_get_default_charset_from_headers:
 * @headers: a #CamelNameValueArray
 *
 * Returns: Default charset from the Content-Type header of the @headers; if none cannot be determined,
 *    UTF-8 is returned.
 *
 * Since: 3.28
 **/
const gchar *
camel_search_get_default_charset_from_headers (const CamelNameValueArray *headers)
{
	CamelContentType *ct = NULL;
	const gchar *content, *charset = NULL;

	if ((content = headers ? camel_name_value_array_get_named (headers, CAMEL_COMPARE_CASE_INSENSITIVE, "Content-Type") : NULL)
	     && (ct = camel_content_type_decode (content)))
		charset = camel_content_type_param (ct, "charset");

	if (!charset)
		charset = "utf-8";

	charset = camel_iconv_charset_name (charset);

	if (ct)
		camel_content_type_unref (ct);

	return charset;
}

/**
 * camel_search_get_header_decoded:
 * @header_name: the header name
 * @header_value: the header value
 * @default_charset: (nullable): the default charset to use for the decode, or %NULL
 *
 * Decodes @header_value, if needed, either from an address header
 * or the Subject header. Other @header_name headers are returned
 * as is.
 *
 * Returns: (transfer full): decoded header value, suitable for text comparison.
 *    Free the returned pointer with g_free() when done with it.
 *
 * Since: 3.22
 **/
gchar *
camel_search_get_header_decoded (const gchar *header_name,
				 const gchar *header_value,
				 const gchar *default_charset)
{
	gchar *unfold, *decoded;

	if (!header_value || !*header_value)
		return NULL;

	unfold = camel_header_unfold (header_value);

	if (g_ascii_strcasecmp (header_name, "Subject") == 0 ||
	    camel_search_header_is_address (header_name)) {
		decoded = camel_header_decode_string (unfold, default_charset);
	} else {
		decoded = unfold;
		unfold = NULL;
	}

	g_free (unfold);

	return decoded;
}

/**
 * camel_search_get_headers_decoded:
 * @headers: a #CamelNameValueArray
 * @default_charset: (nullable): default charset to use; or %NULL, to detect from Content-Type of @headers
 *
 * Returns: (transfer full): The @headers, decoded where needed.
 *    Free the returned pointer with g_free() when done with it.
 *
 * Since: 3.28
 **/
gchar *
camel_search_get_headers_decoded (const CamelNameValueArray *headers,
				  const gchar *default_charset)
{
	GString *str;
	guint ii, length;

	if (!headers)
		return NULL;

	if (!default_charset)
		default_charset = camel_search_get_default_charset_from_headers (headers);

	str = g_string_new ("");

	length = camel_name_value_array_get_length (headers);
	for (ii = 0; ii < length; ii++) {
		gchar *content;
		const gchar *header_name = NULL;
		const gchar *header_value = NULL;

		if (!camel_name_value_array_get (headers, ii, &header_name, &header_value))
			continue;

		if (!header_name || !header_value)
			continue;

		content = camel_search_get_header_decoded (header_name, header_value, default_charset);
		if (!content)
			continue;

		g_string_append (str, header_name);
		if (isspace (content[0]))
			g_string_append (str, ":");
		else
			g_string_append (str, ": ");
		g_string_append (str, content);
		g_string_append_c (str, '\n');

		g_free (content);
	}

	return g_string_free (str, FALSE);
}

/**
 * camel_search_get_all_headers_decoded:
 * @message: a #CamelMessage
 *
 * Returns: (transfer full): All headers of the @message, decoded where needed.
 *    Free the returned pointer with g_free() when done with it.
 *
 * Since: 3.22
 **/
gchar *
camel_search_get_all_headers_decoded (CamelMimeMessage *message)
{
	g_return_val_if_fail (CAMEL_IS_MIME_MESSAGE (message), NULL);

	return camel_search_get_headers_decoded (camel_medium_get_headers (CAMEL_MEDIUM (message)),
		camel_search_get_default_charset_from_message (message));
}
