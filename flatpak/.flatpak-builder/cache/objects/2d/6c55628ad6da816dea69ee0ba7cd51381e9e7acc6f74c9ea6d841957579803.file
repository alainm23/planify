/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 * Copyright (C) 2012 Intel Corporation
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
 * Authors: Rodrigo Moya <rodrigo@ximian.com>
 *          Tristan Van Berkom <tristanvb@openismus.com>
 */

#include "evolution-data-server-config.h"

#include <string.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#ifdef G_OS_WIN32
#include <mbstring.h>
#endif

#include <glib-object.h>

#include "e-source.h"
#include "e-source-authentication.h"
#include "e-source-backend.h"
#include "e-source-collection.h"
#include "e-source-enumtypes.h"
#include "e-source-mail-identity.h"
#include "e-source-mail-submission.h"
#include "e-source-mail-transport.h"
#include "e-source-registry.h"
#include "camel/camel.h"

#include "e-data-server-util.h"

/**
 * e_get_user_cache_dir:
 *
 * Returns a base directory in which to store user-specific,
 * non-essential cached data for Evolution or Evolution-Data-Server.
 *
 * The returned string is owned by libedataserver and must not be
 * modified or freed.
 *
 * Returns: base directory for user-specific, non-essential data
 *
 * Since: 2.32
 **/
const gchar *
e_get_user_cache_dir (void)
{
	static gchar *dirname = NULL;

	if (G_UNLIKELY (dirname == NULL)) {
		const gchar *cache_dir = g_get_user_cache_dir ();
		dirname = g_build_filename (cache_dir, "evolution", NULL);
		g_mkdir_with_parents (dirname, 0700);
	}

	return dirname;
}

/**
 * e_get_user_config_dir:
 *
 * Returns a base directory in which to store user-specific configuration
 * information for Evolution or Evolution-Data-Server.
 *
 * The returned string is owned by libedataserver and must not be
 * modified or freed.
 *
 * Returns: base directory for user-specific configuration information
 *
 * Since: 2.32
 **/
const gchar *
e_get_user_config_dir (void)
{
	static gchar *dirname = NULL;

	if (G_UNLIKELY (dirname == NULL)) {
		const gchar *config_dir = g_get_user_config_dir ();
		dirname = g_build_filename (config_dir, "evolution", NULL);
		g_mkdir_with_parents (dirname, 0700);
	}

	return dirname;
}

/**
 * e_get_user_data_dir:
 *
 * Returns a base directory in which to store user-specific data for
 * Evolution or Evolution-Data-Server.
 *
 * The returned string is owned by libedataserver and must not be
 * modified or freed.
 *
 * Returns: base directory for user-specific data
 *
 * Since: 2.32
 **/
const gchar *
e_get_user_data_dir (void)
{
	static gchar *dirname = NULL;

	if (G_UNLIKELY (dirname == NULL)) {
		const gchar *data_dir = g_get_user_data_dir ();
		dirname = g_build_filename (data_dir, "evolution", NULL);
		g_mkdir_with_parents (dirname, 0700);
	}

	return dirname;
}

/**
 * e_util_strv_equal:
 * @v1: (allow-none): a %NULL-terminated string array, or %NULL
 * @v2: (allow-none): another %NULL-terminated string array, or %NULL
 *
 * Compares @v1 and @v2 for equality, handling %NULL gracefully.
 *
 * The arguments types are generic for compatibility with #GEqualFunc.
 *
 * Returns: whether @v1 and @v2 are identical
 *
 * Since: 3.12
 **/
gboolean
e_util_strv_equal (gconstpointer v1,
                   gconstpointer v2)
{
	gchar **strv1 = (gchar **) v1;
	gchar **strv2 = (gchar **) v2;
	guint length1, length2, ii;

	if (strv1 == strv2)
		return TRUE;

	if (strv1 == NULL || strv2 == NULL)
		return FALSE;

	length1 = g_strv_length (strv1);
	length2 = g_strv_length (strv2);

	if (length1 != length2)
		return FALSE;

	for (ii = 0; ii < length1; ii++) {
		if (!g_str_equal (strv1[ii], strv2[ii]))
			return FALSE;
	}

	return TRUE;
}

/**
 * e_util_strdup_strip:
 * @string: (allow-none): a string value, or %NULL
 *
 * Duplicates @string and strips off any leading or trailing whitespace.
 * The resulting string is returned unless it is empty or %NULL, in which
 * case the function returns %NULL.
 *
 * Free the returned string with g_free().
 *
 * Returns: a newly-allocated, stripped copy of @string, or %NULL
 *
 * Since: 3.6
 **/
gchar *
e_util_strdup_strip (const gchar *string)
{
	gchar *duplicate;

	duplicate = g_strdup (string);
	if (duplicate != NULL) {
		g_strstrip (duplicate);
		if (*duplicate == '\0') {
			g_free (duplicate);
			duplicate = NULL;
		}
	}

	return duplicate;
}

/**
 * e_util_strcmp0:
 * @str1: a C string on %NULL
 * @str2: another C string or %NULL
 *
 * Compares @str1 and @str2 like g_strcmp0(), except it handles %NULL and
 * empty strings as equal.
 *
 * Returns: an integer less than 0 when @str1 is before @str2; 0 when
 *    the strings are equal and an integer greated than 0 when @str1 is after @str2.
 *
 * Since: 3.32
 **/
gint
e_util_strcmp0 (const gchar *str1,
		const gchar *str2)
{
	if (str1 && !*str1)
		str1 = NULL;

	if (str2 && !*str2)
		str2 = NULL;

	return g_strcmp0 (str1, str2);
}

/**
 * e_util_strstrcase:
 * @haystack: The string to search in.
 * @needle: The string to search for.
 *
 * Find the first instance of @needle in @haystack, ignoring case for
 * bytes that are ASCII characters.
 *
 * Returns: A pointer to the start of @needle in @haystack, or NULL if
 *          @needle is not found.
 **/
gchar *
e_util_strstrcase (const gchar *haystack,
                   const gchar *needle)
{
	/* find the needle in the haystack neglecting case */
	const gchar *ptr;
	guint len;

	g_return_val_if_fail (haystack != NULL, NULL);
	g_return_val_if_fail (needle != NULL, NULL);

	len = strlen (needle);
	if (len > strlen (haystack))
		return NULL;

	if (len == 0)
		return (gchar *) haystack;

	for (ptr = haystack; *(ptr + len - 1) != '\0'; ptr++)
		if (!g_ascii_strncasecmp (ptr, needle, len))
			return (gchar *) ptr;

	return NULL;
}

/**
 * e_util_unicode_get_utf8:
 * @text: The string to take the UTF-8 character from.
 * @out: The location to store the UTF-8 character in.
 *
 * Get a UTF-8 character from the beginning of @text.
 *
 * Returns: A pointer to the next character in @text after @out.
 **/
gchar *
e_util_unicode_get_utf8 (const gchar *text,
                         gunichar *out)
{
	g_return_val_if_fail (text != NULL, NULL);
	g_return_val_if_fail (out != NULL, NULL);

	*out = g_utf8_get_char (text);
	return (*out == (gunichar) -1) ? NULL : g_utf8_next_char (text);
}

/**
 * e_util_utf8_strstrcase:
 * @haystack: The string to search in.
 * @needle: The string to search for.
 *
 * Find the first instance of @needle in @haystack, ignoring case. (No
 * proper case folding or decomposing is done.) Both @needle and
 * @haystack are UTF-8 strings.
 *
 * Returns: A pointer to the first instance of @needle in @haystack, or
 *          %NULL if no match is found, or if either of the strings are
 *          not legal UTF-8 strings.
 **/
const gchar *
e_util_utf8_strstrcase (const gchar *haystack,
                        const gchar *needle)
{
	gunichar *nuni, unival;
	gint nlen;
	const gchar *o, *p;

	if (haystack == NULL)
		return NULL;

	if (needle == NULL)
		return NULL;

	if (strlen (needle) == 0)
		return haystack;

	if (strlen (haystack) == 0)
		return NULL;

	nuni = g_alloca (sizeof (gunichar) * strlen (needle));

	nlen = 0;
	for (p = e_util_unicode_get_utf8 (needle, &unival);
	     p && unival;
	     p = e_util_unicode_get_utf8 (p, &unival)) {
		nuni[nlen++] = g_unichar_tolower (unival);
	}
	/* NULL means there was illegal utf-8 sequence */
	if (!p || !nlen)
		return NULL;

	o = haystack;
	for (p = e_util_unicode_get_utf8 (o, &unival);
	     p && unival;
	     p = e_util_unicode_get_utf8 (p, &unival)) {
		gunichar sc;
		sc = g_unichar_tolower (unival);
		/* We have valid stripped gchar */
		if (sc == nuni[0]) {
			const gchar *q = p;
			gint npos = 1;
			while (npos < nlen) {
				q = e_util_unicode_get_utf8 (q, &unival);
				if (!q || !unival) return NULL;
				sc = g_unichar_tolower (unival);
				if (sc != nuni[npos]) break;
				npos++;
			}
			if (npos == nlen) {
				return o;
			}
		}
		o = p;
	}

	return NULL;
}

static gunichar
stripped_char (gunichar ch)
{
	gunichar decomp[4];
	gunichar retval;
	GUnicodeType utype;
	gsize dlen;

	utype = g_unichar_type (ch);

	switch (utype) {
	case G_UNICODE_CONTROL:
	case G_UNICODE_FORMAT:
	case G_UNICODE_UNASSIGNED:
	case G_UNICODE_SPACING_MARK:
		/* Ignore those */
		return 0;
	default:
		/* Convert to lowercase */
		ch = g_unichar_tolower (ch);
		/* falls through */
	case G_UNICODE_LOWERCASE_LETTER:
		if ((dlen = g_unichar_fully_decompose (ch, FALSE, decomp, 4))) {
			retval = decomp[0];
			return retval;
		}
		break;
	}

	return 0;
}

/**
 * e_util_utf8_strstrcasedecomp:
 * @haystack: The string to search in.
 * @needle: The string to search for.
 *
 * Find the first instance of @needle in @haystack, where both @needle
 * and @haystack are UTF-8 strings. Both strings are stripped and
 * decomposed for comparison, and case is ignored.
 *
 * Returns: A pointer to the first instance of @needle in @haystack, or
 *          %NULL if either of the strings are not legal UTF-8 strings.
 **/
const gchar *
e_util_utf8_strstrcasedecomp (const gchar *haystack,
                              const gchar *needle)
{
	gunichar *nuni;
	gunichar unival;
	gint nlen;
	const gchar *o, *p;

	if (haystack == NULL)
		return NULL;

	if (needle == NULL)
		return NULL;

	if (!*needle)
		return haystack;

	if (!*haystack)
		return NULL;

	nuni = g_alloca (sizeof (gunichar) * strlen (needle));

	nlen = 0;
	for (p = e_util_unicode_get_utf8 (needle, &unival);
	     p && unival;
	     p = e_util_unicode_get_utf8 (p, &unival)) {
		gunichar sc;
		sc = stripped_char (unival);
		if (sc) {
		       nuni[nlen++] = sc;
		}
	}
	/* NULL means there was illegal utf-8 sequence */
	if (!p) return NULL;
	/* If everything is correct, we have decomposed,
	 * lowercase, stripped needle */
	if (nlen < 1)
		return haystack;

	o = haystack;
	for (p = e_util_unicode_get_utf8 (o, &unival);
	     p && unival;
	     p = e_util_unicode_get_utf8 (p, &unival)) {
		gunichar sc;
		sc = stripped_char (unival);
		if (sc) {
			/* We have valid stripped gchar */
			if (sc == nuni[0]) {
				const gchar *q = p;
				gint npos = 1;
				while (npos < nlen) {
					q = e_util_unicode_get_utf8 (q, &unival);
					if (!q || !unival) return NULL;
					sc = stripped_char (unival);
					if ((!sc) || (sc != nuni[npos])) break;
					npos++;
				}
				if (npos == nlen) {
					return o;
				}
			}
		}
		o = p;
	}

	return NULL;
}

/**
 * e_util_utf8_strcasecmp:
 * @s1: a UTF-8 string
 * @s2: another UTF-8 string
 *
 * Compares two UTF-8 strings using approximate case-insensitive ordering.
 *
 * Returns: < 0 if @s1 compares before @s2, 0 if they compare equal,
 *          > 0 if @s1 compares after @s2
 **/
gint
e_util_utf8_strcasecmp (const gchar *s1,
                        const gchar *s2)
{
	gchar *folded_s1, *folded_s2;
	gint retval;

	g_return_val_if_fail (s1 != NULL && s2 != NULL, -1);

	if (strcmp (s1, s2) == 0)
		return 0;

	folded_s1 = g_utf8_casefold (s1, -1);
	folded_s2 = g_utf8_casefold (s2, -1);

	retval = g_utf8_collate (folded_s1, folded_s2);

	g_free (folded_s2);
	g_free (folded_s1);

	return retval;
}

/**
 * e_util_utf8_remove_accents:
 * @str: a UTF-8 string, or %NULL
 *
 * Returns a newly-allocated copy of @str with accents removed.
 *
 * Returns: a newly-allocated string
 *
 * Since: 2.28
 **/
gchar *
e_util_utf8_remove_accents (const gchar *str)
{
	gchar *res;
	gint i, j;

	if (str == NULL)
		return NULL;

	res = g_utf8_normalize (str, -1, G_NORMALIZE_NFD);
	if (!res)
		return g_strdup (str);

	for (i = 0, j = 0; res[i]; i++) {
		if ((guchar) res[i] != 0xCC || res[i + 1] == 0) {
			res[j] = res[i];
			j++;
		} else {
			i++;
		}
	}

	res[j] = 0;

	return res;
}

/**
 * e_util_utf8_decompose:
 * @text: a UTF-8 string
 *
 * Converts the @text into a decomposed variant and strips it, which
 * allows also cheap case insensitive comparision afterwards. This
 * produces an output as being used in e_util_utf8_strstrcasedecomp().
 *
 * Returns: (transfer full): A newly allocated string, a decomposed
 *    variant of the @text. Free with g_free(), when no longer needed.
 *
 * Since: 3.26
 **/
gchar *
e_util_utf8_decompose (const gchar *text)
{
	gunichar unival;
	const gchar *p;
	gchar utf8[12];
	GString *decomp;

	if (!text)
		return NULL;

	decomp = g_string_sized_new (strlen (text) + 1);

	for (p = e_util_unicode_get_utf8 (text, &unival);
	     p && unival;
	     p = e_util_unicode_get_utf8 (p, &unival)) {
		gunichar sc;
		sc = stripped_char (unival);
		if (sc) {
			gint ulen = g_unichar_to_utf8 (sc, utf8);
			g_string_append_len (decomp, utf8, ulen);
		}
	}

	/* NULL means there was illegal utf-8 sequence */
	if (!p || !decomp->len) {
		g_string_free (decomp, TRUE);
		return NULL;
	}

	return g_string_free (decomp, FALSE);
}

/**
 * e_util_utf8_make_valid:
 * @str: a UTF-8 string
 *
 * Returns a newly-allocated copy of @str, with invalid characters
 * replaced by Unicode replacement characters (U+FFFD).
 * For %NULL @str returns newly allocated empty string ("").
 *
 * Returns: a newly-allocated string
 *
 * Since: 3.0
 **/
gchar *
e_util_utf8_make_valid (const gchar *str)
{
	if (!str)
		return g_strdup ("");

	return e_util_utf8_data_make_valid (str, strlen (str));
}

/**
 * e_util_utf8_data_make_valid:
 * @data: UTF-8 binary data
 * @data_bytes: length of the binary data
 *
 * Returns a newly-allocated NULL-terminated string with invalid characters
 * replaced by Unicode replacement characters (U+FFFD).
 * For %NULL @data returns newly allocated empty string ("").
 *
 * Returns: a newly-allocated string
 *
 * Since: 3.6
 */
gchar *
e_util_utf8_data_make_valid (const gchar *data,
                             gsize data_bytes)
{
	/* almost identical copy of glib's _g_utf8_make_valid() */
	GString *string;
	const gchar *remainder, *invalid;
	gint remaining_bytes, valid_bytes;

	if (!data)
		return g_strdup ("");

	string = NULL;
	remainder = (gchar *) data,
	remaining_bytes = data_bytes;

	while (remaining_bytes != 0) {
		if (g_utf8_validate (remainder, remaining_bytes, &invalid))
			break;
		valid_bytes = invalid - remainder;

		if (string == NULL)
			string = g_string_sized_new (remaining_bytes);

		g_string_append_len (string, remainder, valid_bytes);
		/* append U+FFFD REPLACEMENT CHARACTER */
		g_string_append (string, "\357\277\275");

		remaining_bytes -= valid_bytes + 1;
		remainder = invalid + 1;
	}

	if (string == NULL)
		return g_strndup ((gchar *) data, data_bytes);

	g_string_append (string, remainder);

	g_warn_if_fail (g_utf8_validate (string->str, -1, NULL));

	return g_string_free (string, FALSE);
}

/**
 * e_util_utf8_normalize:
 * @str: a UTF-8 string
 *
 * Normalizes @str by making it all lower case and removing any accents from it.
 *
 * Returns: The normalized version of @str, or %NULL if @str was not valid UTF-8
 *
 * Since: 3.8
 */
gchar *
e_util_utf8_normalize (const gchar *str)
{
	gchar *valid = NULL;
	gchar *normal, *casefolded = NULL;

	if (str == NULL)
		return NULL;

	if (!g_utf8_validate (str, -1, NULL)) {
		valid = e_util_utf8_make_valid (str);
		str = valid;
	}

	normal = e_util_utf8_remove_accents (str);
	if (normal)
		casefolded = g_utf8_casefold (normal, -1);

	g_free (valid);
	g_free (normal);

	return casefolded;
}

/**
 * e_util_ensure_gdbus_string:
 * @str: a possibly invalid UTF-8 string, or %NULL
 * @gdbus_str: return location for the corrected string
 *
 * If @str is a valid UTF-8 string, the function returns @str and does
 * not set @gdbus_str.
 *
 * If @str is an invalid UTF-8 string, the function calls
 * e_util_utf8_make_valid() and points @gdbus_str to the newly-allocated,
 * valid UTF-8 string, and also returns it.  The caller should free the
 * string pointed to by @gdbus_str with g_free().
 *
 * If @str is %NULL, the function returns an empty string and does not
 * set @gdbus_str.
 *
 * Admittedly, the function semantics are a little awkward.  The example
 * below illustrates the easiest way to cope with the @gdbus_str argument:
 *
 * |[
 *     const gchar *trusted_utf8;
 *     gchar *allocated = NULL;
 *
 *     trusted_utf8 = e_util_ensure_gdbus_string (untrusted_utf8, &allocated);
 *
 *     Do stuff with trusted_utf8, then clear it.
 *
 *     trusted_utf8 = NULL;
 *
 *     g_free (allocated);
 *     allocated = NULL;
 * ]|
 *
 * Returns: a valid UTF-8 string
 *
 * Since: 3.0
 **/
const gchar *
e_util_ensure_gdbus_string (const gchar *str,
                            gchar **gdbus_str)
{
	g_return_val_if_fail (gdbus_str != NULL, NULL);

	*gdbus_str = NULL;

	if (!str || !*str)
		return "";

	if (g_utf8_validate (str, -1, NULL))
		return str;

	*gdbus_str = e_util_utf8_make_valid (str);

	return *gdbus_str;
}

/**
 * e_strftime:
 * @string: The string array to store the result in.
 * @max: The size of array @s.
 * @fmt: The formatting to use on @tm.
 * @tm: The time value to format.
 *
 * This function is a wrapper around the strftime (3) function, which
 * converts the &percnt;l and &percnt;k (12h and 24h) format variables
 * if necessary.
 *
 * Returns: The number of characters placed in @s.
 **/
gsize
e_strftime (gchar *string,
            gsize max,
            const gchar *fmt,
            const struct tm *tm)
{
#ifndef HAVE_LKSTRFTIME
	gchar *c, *ffmt, *ff;
#endif
	gsize ret;

	g_return_val_if_fail (string != NULL, 0);
	g_return_val_if_fail (fmt != NULL, 0);
	g_return_val_if_fail (tm != NULL, 0);

#ifdef HAVE_LKSTRFTIME
	ret = strftime (string, max, fmt, tm);
#else
	ffmt = g_strdup (fmt);
	ff = ffmt;
	while ((c = strstr (ff, "%l")) != NULL) {
		c[1] = 'I';
		ff = c;
	}

	ff = ffmt;
	while ((c = strstr (ff, "%k")) != NULL) {
		c[1] = 'H';
		ff = c;
	}

#ifdef G_OS_WIN32
	/* The Microsoft strftime () doesn't have %e either */
	ff = ffmt;
	while ((c = strstr (ff, "%e")) != NULL) {
		c[1] = 'd';
		ff = c;
	}
#endif

	ret = strftime (string, max, ffmt, tm);
	g_free (ffmt);
#endif

	if (ret == 0 && max > 0)
		string[0] = '\0';

	return ret;
}

/**
 * e_utf8_strftime:
 * @string: The string array to store the result in.
 * @max: The size of array @s.
 * @fmt: The formatting to use on @tm.
 * @tm: The time value to format.
 *
 * The UTF-8 equivalent of e_strftime ().
 *
 * Returns: The number of characters placed in @s.
 **/
gsize
e_utf8_strftime (gchar *string,
                 gsize max,
                 const gchar *fmt,
                 const struct tm *tm)
{
	gsize sz, ret;
	gchar *locale_fmt, *buf;

	g_return_val_if_fail (string != NULL, 0);
	g_return_val_if_fail (fmt != NULL, 0);
	g_return_val_if_fail (tm != NULL, 0);

	locale_fmt = g_locale_from_utf8 (fmt, -1, NULL, &sz, NULL);
	if (!locale_fmt)
		return 0;

	ret = e_strftime (string, max, locale_fmt, tm);
	if (!ret) {
		g_free (locale_fmt);
		return 0;
	}

	buf = g_locale_to_utf8 (string, ret, NULL, &sz, NULL);
	if (!buf) {
		g_free (locale_fmt);
		return 0;
	}

	if (sz >= max) {
		gchar *tmp = buf + max - 1;
		tmp = g_utf8_find_prev_char (buf, tmp);
		if (tmp)
			sz = tmp - buf;
		else
			sz = 0;
	}

	memcpy (string, buf, sz);
	string[sz] = '\0';

	g_free (locale_fmt);
	g_free (buf);

	return sz;
}

/**
 * e_util_gthread_id:
 * @thread: A #GThread pointer
 *
 * Returns a 64-bit integer hopefully uniquely identifying the
 * thread. To be used in debugging output and logging only.
 * The returned value is just a cast of a pointer to the 64-bit integer.
 *
 * There is no guarantee that calling e_util_gthread_id () on one
 * thread first and later after that thread has dies on another won't
 * return the same integer.
 *
 * On Linux and Win32, known to really return a unique id for each
 * thread existing at a certain time. No guarantee that ids won't be
 * reused after a thread has terminated, though.
 *
 * Returns: A 64-bit integer.
 *
 * Since: 2.32
 */
guint64
e_util_gthread_id (GThread *thread)
{
#if GLIB_SIZEOF_VOID_P == 8
	/* 64-bit Windows */
	return (guint64) thread;
#else
	return (gint) thread;
#endif
}

/* This only makes a filename safe for usage as a filename.
 * It still may have shell meta-characters in it. */

/* This code is rather misguided and mostly pointless, but can't be
 * changed because of backward compatibility, I guess.
 *
 * It replaces some perfectly safe characters like '%' with an
 * underscore. (Recall that on Unix, the only bytes not allowed in a
 * file name component are '\0' and '/'.) On the other hand, the UTF-8
 * for a printable non-ASCII Unicode character (that thus consists of
 * several very nonprintable non-ASCII bytes) is let through as
 * such. But those bytes are of course also allowed in filenames, so
 * it doesn't matter as such...
 */
void
e_filename_make_safe (gchar *string)
{
	gchar *p, *ts;
	gunichar c;
#ifdef G_OS_WIN32
	const gchar *unsafe_chars = " /'\"`&();|<>$%{}!\\:*?#";
#else
	const gchar *unsafe_chars = " /'\"`&();|<>$%{}!#";
#endif

	g_return_if_fail (string != NULL);

	p = string;

	while (p && *p) {
		c = g_utf8_get_char (p);
		ts = p;
		p = g_utf8_next_char (p);
		/* I wonder what this code is supposed to actually
		 * achieve, and whether it does that as currently
		 * written?
		 */
		if (!g_unichar_isprint (c) ||
			(c < 0xff && strchr (unsafe_chars, c & 0xff))) {
			while (ts < p)
				*ts++ = '_';
		}
	}
}

/**
 * e_filename_mkdir_encoded:
 * @basepath: base path of a file name; this is left unchanged
 * @fileprefix: prefix for the filename; this is encoded
 * @filename: file name to use; this is encoded; can be %NULL
 * @fileindex: used when @filename is NULL, then the filename
 *        is generated as "file" + fileindex
 *
 * Creates a local path constructed from @basepath / @fileprefix + "-" + @filename,
 * and makes sure the path @basepath exists. If creation of
 * the path fails, then NULL is returned.
 *
 * Returns: Full local path like g_build_filename() except that @fileprefix
 * and @filename are encoded to create a proper file elements for
 * a file system. Free returned pointer with g_free().
 *
 * Since: 3.4
 **/
gchar *
e_filename_mkdir_encoded (const gchar *basepath,
                          const gchar *fileprefix,
                          const gchar *filename,
                          gint fileindex)
{
	gchar *elem1, *elem2, *res, *fn;

	g_return_val_if_fail (basepath != NULL, NULL);
	g_return_val_if_fail (*basepath != 0, NULL);
	g_return_val_if_fail (fileprefix != NULL, NULL);
	g_return_val_if_fail (*fileprefix != 0, NULL);
	g_return_val_if_fail (!filename || *filename, NULL);

	if (g_mkdir_with_parents (basepath, 0700) < 0)
		return NULL;

	elem1 = g_strdup (fileprefix);
	if (filename)
		elem2 = g_strdup (filename);
	else
		elem2 = g_strdup_printf ("file%d", fileindex);

	e_filename_make_safe (elem1);
	e_filename_make_safe (elem2);

	fn = g_strconcat (elem1, "-", elem2, NULL);

	res = g_build_filename (basepath, fn, NULL);

	g_free (fn);
	g_free (elem1);
	g_free (elem2);

	return res;
}

/**
 * e_util_slist_to_strv:
 * @strings: (element-type utf8): a #GSList of strings (const gchar *)
 *
 * Convert list of strings into NULL-terminates array of strings.
 *
 * Returns: (transfer full): Newly allocated %NULL-terminated array of strings.
 * Returned pointer should be freed with g_strfreev().
 *
 * Note: Pair function for this is e_util_strv_to_slist().
 *
 * Since: 3.4
 **/
gchar **
e_util_slist_to_strv (const GSList *strings)
{
	const GSList *iter;
	GPtrArray *array;

	array = g_ptr_array_sized_new (g_slist_length ((GSList *) strings) + 1);

	for (iter = strings; iter; iter = iter->next) {
		const gchar *str = iter->data;

		if (str)
			g_ptr_array_add (array, g_strdup (str));
	}

	/* NULL-terminated */
	g_ptr_array_add (array, NULL);

	return (gchar **) g_ptr_array_free (array, FALSE);
}

/**
 * e_util_strv_to_slist:
 * @strv: a NULL-terminated array of strings (const gchar *)
 *
 * Convert NULL-terminated array of strings to a list of strings.
 *
 * Returns: (transfer full) (element-type utf8): Newly allocated #GSList of
 * newly allocated strings. The returned pointer should be freed with
 * e_util_free_string_slist().
 *
 * Note: Pair function for this is e_util_slist_to_strv().
 *
 * Since: 3.4
 **/
GSList *
e_util_strv_to_slist (const gchar * const *strv)
{
	GSList *slist = NULL;
	gint ii;

	if (!strv)
		return NULL;

	for (ii = 0; strv[ii]; ii++) {
		slist = g_slist_prepend (slist, g_strdup (strv[ii]));
	}

	return g_slist_reverse (slist);
}

/**
 * e_util_copy_string_slist:
 * @copy_to: (element-type utf8) (allow-none): Where to copy; can be %NULL
 * @strings: (element-type utf8): #GSList of strings to be copied
 *
 * Copies #GSList of strings at the end of @copy_to.
 *
 * Returns: (transfer full) (element-type utf8): New head of @copy_to.
 * Returned pointer can be freed with e_util_free_string_slist().
 *
 * Since: 3.4
 *
 * Deprecated: 3.8: Use g_slist_copy_deep() instead, and optionally
 *                  g_slist_concat() to concatenate the copied list
 *                  to another #GSList.
 **/
GSList *
e_util_copy_string_slist (GSList *copy_to,
                          const GSList *strings)
{
	GSList *copied_list;

	copied_list = g_slist_copy_deep (
		(GSList *) strings, (GCopyFunc) g_strdup, NULL);

	return g_slist_concat (copy_to, copied_list);
}

/**
 * e_util_copy_object_slist:
 * @copy_to: (element-type GObject) (allow-none): Where to copy; can be %NULL
 * @objects: (element-type GObject): #GSList of #GObject<!-- -->s to be copied
 *
 * Copies #GSList of #GObject<!-- -->s at the end of @copy_to.
 *
 * Returns: (transfer full) (element-type GObject): New head of @copy_to.
 * Returned pointer can be freed with e_util_free_object_slist().
 *
 * Since: 3.4
 *
 * Deprecated: 3.8: Use g_slist_copy_deep() instead, and optionally
 *                  g_slist_concat() to concatenate the copied list
 *                  to another #GSList.
 **/
GSList *
e_util_copy_object_slist (GSList *copy_to,
                          const GSList *objects)
{
	GSList *copied_list;

	copied_list = g_slist_copy_deep (
		(GSList *) objects, (GCopyFunc) g_object_ref, NULL);

	return g_slist_concat (copy_to, copied_list);
}

/**
 * e_util_free_string_slist:
 * @strings: (element-type utf8): a #GSList of strings (gchar *)
 *
 * Frees memory previously allocated by e_util_strv_to_slist().
 *
 * Since: 3.4
 *
 * Deprecated: 3.8: Use g_slist_free_full() instead.
 **/
void
e_util_free_string_slist (GSList *strings)
{
	g_slist_free_full (strings, (GDestroyNotify) g_free);
}

/**
 * e_util_free_object_slist:
 * @objects: (element-type GObject): a #GSList of #GObject<!-- -->s
 *
 * Calls g_object_unref() on each member of @objects and then frees
 * also @objects itself.
 *
 * Since: 3.4
 *
 * Deprecated: 3.8: Use g_slist_free_full() instead.
 **/
void
e_util_free_object_slist (GSList *objects)
{
	g_slist_free_full (objects, (GDestroyNotify) g_object_unref);
}

/**
 * e_util_free_nullable_object_slist:
 * @objects: (element-type GObject): a #GSList of nullable #GObject<!-- -->s
 *
 * Calls g_object_unref() on each member of @objects if non-%NULL and then frees
 * also @objects itself.
 *
 * Since: 3.6
 **/
void
e_util_free_nullable_object_slist (GSList *objects)
{
	const GSList *l;
	for (l = objects; l; l = l->next) {
		if (l->data)
			g_object_unref (l->data);
	}
	g_slist_free (objects);
}

/**
 * e_util_safe_free_string:
 * @str: a string to free
 *
 * Calls g_free() on @string, but before it rewrites its content with zeros.
 * This is suitable to free strings with passwords.
 *
 * Since: 3.16
 **/
void
e_util_safe_free_string (gchar *str)
{
	if (!str)
		return;

	if (*str)
		memset (str, 0, sizeof (gchar) * strlen (str));

	g_free (str);
}

/**
 * e_queue_transfer:
 * @src_queue: a source #GQueue
 * @dst_queue: a destination #GQueue
 *
 * Transfers the contents of @src_queue to the tail of @dst_queue.
 * When the operation is complete, @src_queue will be empty.
 *
 * Since: 3.8
 **/
void
e_queue_transfer (GQueue *src_queue,
                  GQueue *dst_queue)
{
	g_return_if_fail (src_queue != NULL);
	g_return_if_fail (dst_queue != NULL);

	dst_queue->head = g_list_concat (dst_queue->head, src_queue->head);
	dst_queue->tail = g_list_last (dst_queue->head);
	dst_queue->length += src_queue->length;

	src_queue->head = NULL;
	src_queue->tail = NULL;
	src_queue->length = 0;
}

/**
 * e_weak_ref_new: (skip)
 * @object: (allow-none): a #GObject or %NULL
 *
 * Allocates a new #GWeakRef and calls g_weak_ref_set() with @object.
 *
 * Free the returned #GWeakRef with e_weak_ref_free().
 *
 * Returns: (transfer full): a new #GWeakRef
 *
 * Since: 3.10
 **/
GWeakRef *
e_weak_ref_new (gpointer object)
{
	GWeakRef *weak_ref;

	weak_ref = g_slice_new0 (GWeakRef);
	g_weak_ref_init (weak_ref, object);

	return weak_ref;
}

/**
 * e_weak_ref_free: (skip)
 * @weak_ref: a #GWeakRef
 *
 * Frees a #GWeakRef created by e_weak_ref_new().
 *
 * Since: 3.10
 **/
void
e_weak_ref_free (GWeakRef *weak_ref)
{
	g_return_if_fail (weak_ref != NULL);

	g_weak_ref_clear (weak_ref);
	g_slice_free (GWeakRef, weak_ref);
}

/* Helper for e_file_recursive_delete() */
static void
file_recursive_delete_thread (GSimpleAsyncResult *simple,
                              GObject *object,
                              GCancellable *cancellable)
{
	GError *error = NULL;

	e_file_recursive_delete_sync (G_FILE (object), cancellable, &error);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);
}

/**
 * e_file_recursive_delete_sync:
 * @file: a #GFile to delete
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Deletes @file.  If @file is a directory, its contents are deleted
 * recursively before @file itself is deleted.  The recursive delete
 * operation will stop on the first error.
 *
 * If @cancellable is not %NULL, then the operation can be cancelled
 * by triggering the cancellable object from another thread.  If the
 * operation was cancelled, the error #G_IO_ERROR_CANCELLED will be
 * returned.
 *
 * Returns: %TRUE if the file was deleted, %FALSE otherwise
 *
 * Since: 3.6
 **/
gboolean
e_file_recursive_delete_sync (GFile *file,
                              GCancellable *cancellable,
                              GError **error)
{
	GFileEnumerator *file_enumerator;
	GFileInfo *file_info;
	GFileType file_type;
	gboolean success = TRUE;
	GError *local_error = NULL;

	g_return_val_if_fail (G_IS_FILE (file), FALSE);

	file_type = g_file_query_file_type (
		file, G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS, cancellable);

	/* If this is not a directory, delete like normal. */
	if (file_type != G_FILE_TYPE_DIRECTORY)
		return g_file_delete (file, cancellable, error);

	/* Note, G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS is critical here
	 * so we only delete files inside the directory being deleted. */
	file_enumerator = g_file_enumerate_children (
		file, G_FILE_ATTRIBUTE_STANDARD_NAME,
		G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS,
		cancellable, error);

	if (file_enumerator == NULL)
		return FALSE;

	file_info = g_file_enumerator_next_file (
		file_enumerator, cancellable, &local_error);

	while (file_info != NULL) {
		GFile *child;
		const gchar *name;

		name = g_file_info_get_name (file_info);

		/* Here's the recursive part. */
		child = g_file_get_child (file, name);
		success = e_file_recursive_delete_sync (
			child, cancellable, error);
		g_object_unref (child);

		g_object_unref (file_info);

		if (!success)
			break;

		file_info = g_file_enumerator_next_file (
			file_enumerator, cancellable, &local_error);
	}

	if (local_error != NULL) {
		g_propagate_error (error, local_error);
		success = FALSE;
	}

	g_object_unref (file_enumerator);

	if (!success)
		return FALSE;

	/* The directory should be empty now. */
	return g_file_delete (file, cancellable, error);
}

/**
 * e_file_recursive_delete:
 * @file: a #GFile to delete
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously deletes @file.  If @file is a directory, its contents
 * are deleted recursively before @file itself is deleted.  The recursive
 * delete operation will stop on the first error.
 *
 * If @cancellable is not %NULL, then the operation can be cancelled
 * by triggering the cancellable object before the operation finishes.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_file_recursive_delete_finish() to get the result of the operation.
 *
 * Since: 3.6
 **/
void
e_file_recursive_delete (GFile *file,
                         gint io_priority,
                         GCancellable *cancellable,
                         GAsyncReadyCallback callback,
                         gpointer user_data)
{
	GSimpleAsyncResult *simple;

	g_return_if_fail (G_IS_FILE (file));

	simple = g_simple_async_result_new (
		G_OBJECT (file), callback, user_data,
		e_file_recursive_delete);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_run_in_thread (
		simple, file_recursive_delete_thread,
		io_priority, cancellable);

	g_object_unref (simple);
}

/**
 * e_file_recursive_delete_finish:
 * @file: a #GFile to delete
 * @result: (transfer full): a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_file_recursive_delete().
 *
 * If the operation was cancelled, the error #G_IO_ERROR_CANCELLED will be
 * returned.
 *
 * Returns: %TRUE if the file was deleted, %FALSE otherwise
 *
 * Since: 3.6
 **/
gboolean
e_file_recursive_delete_finish (GFile *file,
                                GAsyncResult *result,
                                GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (file), e_file_recursive_delete), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_binding_bind_property:
 * @source: (type GObject.Object): the source #GObject
 * @source_property: the property on @source to bind
 * @target: (type GObject.Object): the target #GObject
 * @target_property: the property on @target to bind
 * @flags: flags to pass to #GBinding
 *
 * Thread safe variant of g_object_bind_property(). See its documentation
 * for more information on arguments and return value.
 *
 * Returns: (transfer none):
 *
 * Since: 3.16
 **/
GBinding *
e_binding_bind_property (gpointer source,
			 const gchar *source_property,
			 gpointer target,
			 const gchar *target_property,
			 GBindingFlags flags)
{
	return camel_binding_bind_property (source, source_property, target, target_property, flags);
}

/**
 * e_binding_bind_property_full:
 * @source: (type GObject.Object): the source #GObject
 * @source_property: the property on @source to bind
 * @target: (type GObject.Object): the target #GObject
 * @target_property: the property on @target to bind
 * @flags: flags to pass to #GBinding
 * @transform_to: (scope notified) (allow-none): the transformation function
 *   from the @source to the @target, or %NULL to use the default
 * @transform_from: (scope notified) (allow-none): the transformation function
 *   from the @target to the @source, or %NULL to use the default
 * @user_data: custom data to be passed to the transformation functions,
 *   or %NULL
 * @notify: function to be called when disposing the binding, to free the
 *   resources used by the transformation functions
 *
 * Thread safe variant of g_object_bind_property_full(). See its documentation
 * for more information on arguments and return value.
 *
 * Return value: (transfer none): the #GBinding instance representing the
 *   binding between the two #GObject instances. The binding is released
 *   whenever the #GBinding reference count reaches zero.
 *
 * Since: 3.16
 **/
GBinding *
e_binding_bind_property_full (gpointer source,
			      const gchar *source_property,
			      gpointer target,
			      const gchar *target_property,
			      GBindingFlags flags,
			      GBindingTransformFunc transform_to,
			      GBindingTransformFunc transform_from,
			      gpointer user_data,
			      GDestroyNotify notify)
{
	return camel_binding_bind_property_full (source, source_property, target, target_property, flags,
		transform_to, transform_from, user_data, notify);
}

/**
 * e_binding_bind_property_with_closures: (rename-to e_binding_bind_property_full)
 * @source: (type GObject.Object): the source #GObject
 * @source_property: the property on @source to bind
 * @target: (type GObject.Object): the target #GObject
 * @target_property: the property on @target to bind
 * @flags: flags to pass to #GBinding
 * @transform_to: a #GClosure wrapping the transformation function
 *   from the @source to the @target, or %NULL to use the default
 * @transform_from: a #GClosure wrapping the transformation function
 *   from the @target to the @source, or %NULL to use the default
 *
 * Thread safe variant of g_object_bind_property_with_closures(). See its
 * documentation for more information on arguments and return value.
 *
 * Return value: (transfer none): the #GBinding instance representing the
 *   binding between the two #GObject instances. The binding is released
 *   whenever the #GBinding reference count reaches zero.
 *
 * Since: 3.16
 **/
GBinding *
e_binding_bind_property_with_closures (gpointer source,
				       const gchar *source_property,
				       gpointer target,
				       const gchar *target_property,
				       GBindingFlags flags,
				       GClosure *transform_to,
				       GClosure *transform_from)
{
	return camel_binding_bind_property_with_closures (source, source_property, target, target_property, flags,
		transform_to, transform_from);
}

/**
 * e_binding_transform_enum_value_to_nick:
 * @binding: a #GBinding
 * @source_value: a #GValue whose type is derived from #G_TYPE_ENUM
 * @target_value: a #GValue of type #G_TYPE_STRING
 * @not_used: not used
 *
 * Transforms an enumeration value to its corresponding nickname.
 *
 * Returns: %TRUE if the enum value has a corresponding nickname
 *
 * Since: 3.4
 **/
gboolean
e_binding_transform_enum_value_to_nick (GBinding *binding,
                                        const GValue *source_value,
                                        GValue *target_value,
                                        gpointer not_used)
{
	GEnumClass *enum_class;
	GEnumValue *enum_value;
	gint value;
	gboolean success = FALSE;

	g_return_val_if_fail (G_IS_BINDING (binding), FALSE);

	enum_class = g_type_class_peek (G_VALUE_TYPE (source_value));
	g_return_val_if_fail (G_IS_ENUM_CLASS (enum_class), FALSE);

	value = g_value_get_enum (source_value);
	enum_value = g_enum_get_value (enum_class, value);
	if (enum_value != NULL) {
		g_value_set_string (target_value, enum_value->value_nick);
		success = TRUE;
	}

	return success;
}

/**
 * e_binding_transform_enum_nick_to_value:
 * @binding: a #GBinding
 * @source_value: a #GValue of type #G_TYPE_STRING
 * @target_value: a #GValue whose type is derived from #G_TYPE_ENUM
 * @not_used: not used
 *
 * Transforms an enumeration nickname to its corresponding value.
 *
 * Returns: %TRUE if the enum nickname has a corresponding value
 *
 * Since: 3.4
 **/
gboolean
e_binding_transform_enum_nick_to_value (GBinding *binding,
                                        const GValue *source_value,
                                        GValue *target_value,
                                        gpointer not_used)
{
	GEnumClass *enum_class;
	GEnumValue *enum_value;
	const gchar *string;
	gboolean success = FALSE;

	g_return_val_if_fail (G_IS_BINDING (binding), FALSE);

	enum_class = g_type_class_peek (G_VALUE_TYPE (target_value));
	g_return_val_if_fail (G_IS_ENUM_CLASS (enum_class), FALSE);

	string = g_value_get_string (source_value);
	enum_value = g_enum_get_value_by_nick (enum_class, string);
	if (enum_value != NULL) {
		g_value_set_enum (target_value, enum_value->value);
		success = TRUE;
	}

	return success;
}

/**
 * e_enum_from_string:
 * @enum_type: The enum type
 * @string: The string containing the enum value or nick
 * @enum_value: A return location to store the result
 *
 * Fetches the appropriate enumeration value for @string in the given
 * enum type @type and stores the result in @enum_value
 *
 * Returns: %TRUE if the string was a valid name or nick
 *        for the given @type, %FALSE if the conversion failed.
 *
 * Since: 3.8
 */
gboolean
e_enum_from_string (GType enum_type,
                    const gchar *string,
                    gint *enum_value)
{
	GEnumClass *enum_class;
	GEnumValue *ev;
	gchar *endptr;
	gint value;
	gboolean retval = TRUE;

	g_return_val_if_fail (G_TYPE_IS_ENUM (enum_type), FALSE);
	g_return_val_if_fail (string != NULL, FALSE);

	value = g_ascii_strtoull (string, &endptr, 0);
	if (endptr != string)
		/* parsed a number */
		*enum_value = value;
	else {
		enum_class = g_type_class_ref (enum_type);
		ev = g_enum_get_value_by_name (enum_class, string);
		if (!ev)
			ev = g_enum_get_value_by_nick (enum_class, string);

		if (ev)
			*enum_value = ev->value;
		else
			retval = FALSE;

		g_type_class_unref (enum_class);
	}

	return retval;
}

/**
 * e_enum_to_string:
 * @enum_type: An enum type
 * @enum_value: The enum value to convert
 *
 * Converts an enum value to a string using strings from the GType system.
 *
 * Returns: the string representing @eval
 *
 * Since: 3.8
 */
const gchar *
e_enum_to_string (GType enum_type,
                  gint enum_value)
{
	GEnumClass *enum_class;
	const gchar *string = NULL;
	guint i;

	enum_class = g_type_class_ref (enum_type);

	g_return_val_if_fail (enum_class != NULL, NULL);

	for (i = 0; i < enum_class->n_values; i++) {
		if (enum_value == enum_class->values[i].value) {
			string = enum_class->values[i].value_nick;
			break;
		}
	}

	g_type_class_unref (enum_class);

	return string;
}

/**
 * EAsyncClosure:
 *
 * #EAsyncClosure provides a simple way to run an asynchronous function
 * synchronously without blocking a running #GMainLoop or using threads.
 *
 * 1) Create an #EAsyncClosure with e_async_closure_new().
 *
 * 2) Call the asynchronous function passing e_async_closure_callback() as
 *    the #GAsyncReadyCallback argument and the #EAsyncClosure as the data
 *    argument.
 *
 * 3) Call e_async_closure_wait() and collect the #GAsyncResult.
 *
 * 4) Call the corresponding asynchronous "finish" function, passing the
 *    #GAsyncResult returned by e_async_closure_wait().
 *
 * 5) If needed, repeat steps 2-4 for additional asynchronous functions
 *    using the same #EAsyncClosure.
 *
 * 6) Finally, free the #EAsyncClosure with e_async_closure_free().
 *
 * Since: 3.6
 **/
struct _EAsyncClosure {
	GMainLoop *loop;
	GMainContext *context;
	GAsyncResult *result;
	gboolean finished;
	GMutex lock;
};

/**
 * e_async_closure_new: (skip)
 *
 * Creates a new #EAsyncClosure for use with asynchronous functions.
 *
 * Returns: a new #EAsyncClosure
 *
 * Since: 3.6
 **/
EAsyncClosure *
e_async_closure_new (void)
{
	EAsyncClosure *closure;

	closure = g_slice_new0 (EAsyncClosure);
	closure->context = g_main_context_new ();
	closure->loop = g_main_loop_new (closure->context, FALSE);
	closure->finished = FALSE;
	g_mutex_init (&closure->lock);

	g_main_context_push_thread_default (closure->context);

	return closure;
}

static gboolean
e_async_closure_unlock_mutex_cb (gpointer user_data)
{
	EAsyncClosure *closure = user_data;

	g_return_val_if_fail (closure != NULL, FALSE);

	g_mutex_unlock (&closure->lock);

	return FALSE;
}

/**
 * e_async_closure_wait: (skip)
 * @closure: an #EAsyncClosure
 *
 * Call this function immediately after starting an asynchronous operation.
 * The function waits for the asynchronous operation to complete and returns
 * its #GAsyncResult to be passed to the operation's "finish" function.
 *
 * This function can be called repeatedly on the same #EAsyncClosure to
 * easily string together multiple asynchronous operations.
 *
 * Returns: (transfer none): a #GAsyncResult which is owned by the closure
 *
 * Since: 3.6
 **/
GAsyncResult *
e_async_closure_wait (EAsyncClosure *closure)
{
	g_return_val_if_fail (closure != NULL, NULL);

	g_mutex_lock (&closure->lock);
	if (closure->finished) {
		g_mutex_unlock (&closure->lock);
	} else {
		GSource *idle_source;

		/* Unlock the closure->lock in the main loop, to ensure thread safety.
		   It should be processed before anything else, otherwise deadlock happens. */
		idle_source = g_idle_source_new ();
		g_source_set_callback (idle_source, e_async_closure_unlock_mutex_cb, closure, NULL);
		g_source_set_priority (idle_source, G_PRIORITY_HIGH * 2);
		g_source_attach (idle_source, closure->context);
		g_source_unref (idle_source);

		g_main_loop_run (closure->loop);
	}

	return closure->result;
}

/**
 * e_async_closure_free: (skip)
 * @closure: an #EAsyncClosure
 *
 * Frees the @closure and the resources it holds.
 *
 * Since: 3.6
 **/
void
e_async_closure_free (EAsyncClosure *closure)
{
	g_return_if_fail (closure != NULL);

	g_main_context_pop_thread_default (closure->context);

	g_main_loop_unref (closure->loop);
	g_main_context_unref (closure->context);

	g_mutex_lock (&closure->lock);
	g_clear_object (&closure->result);
	g_mutex_unlock (&closure->lock);
	g_mutex_clear (&closure->lock);

	g_slice_free (EAsyncClosure, closure);
}

/**
 * e_async_closure_callback: (skip)
 * @object: a #GObject or %NULL, it is not used by the function at all
 * @result: a #GAsyncResult
 * @closure: an #EAsyncClosure
 *
 * Pass this function as the #GAsyncReadyCallback argument of an asynchronous
 * function, and the #EAsyncClosure as the data argument.
 *
 * This causes e_async_closure_wait() to terminate and return @result.
 *
 * Since: 3.6
 **/
void
e_async_closure_callback (GObject *object,
                          GAsyncResult *result,
                          gpointer closure)
{
	EAsyncClosure *real_closure;

	g_return_if_fail (G_IS_ASYNC_RESULT (result));
	g_return_if_fail (closure != NULL);

	real_closure = closure;

	g_mutex_lock (&real_closure->lock);

	/* Replace any previous result. */
	if (real_closure->result != NULL)
		g_object_unref (real_closure->result);
	real_closure->result = g_object_ref (result);
	real_closure->finished = TRUE;

	g_mutex_unlock (&real_closure->lock);

	g_main_loop_quit (real_closure->loop);
}

#ifdef G_OS_WIN32

#include <windows.h>
#include <stdio.h>
#include <conio.h>
#include <io.h>

#ifndef PROCESS_DEP_ENABLE
#define PROCESS_DEP_ENABLE 0x00000001
#endif
#ifndef PROCESS_DEP_DISABLE_ATL_THUNK_EMULATION
#define PROCESS_DEP_DISABLE_ATL_THUNK_EMULATION 0x00000002
#endif

static const gchar *prefix = NULL;
static const gchar *cp_prefix;

static const gchar *localedir;
static const gchar *imagesdir;
static const gchar *credentialmoduledir;
static const gchar *uimoduledir;

static HMODULE hmodule;
G_LOCK_DEFINE_STATIC (mutex);

/* Silence gcc with a prototype. Yes, this is silly. */
BOOL WINAPI DllMain (HINSTANCE hinstDLL,
		     DWORD     fdwReason,
		     LPVOID    lpvReserved);

/* Minimal DllMain that just tucks away the DLL's HMODULE */
BOOL WINAPI
DllMain (HINSTANCE hinstDLL,
         DWORD fdwReason,
         LPVOID lpvReserved)
{
	switch (fdwReason) {
	case DLL_PROCESS_ATTACH:
		hmodule = hinstDLL;
		break;
	}
	return TRUE;
}

gchar *
e_util_replace_prefix (const gchar *configure_time_prefix,
                       const gchar *runtime_prefix,
                       const gchar *configure_time_path)
{
	gchar *c_t_prefix_slash;
	gchar *retval;

	c_t_prefix_slash = g_strconcat (configure_time_prefix, "/", NULL);

	if (runtime_prefix &&
	    !g_str_has_prefix (configure_time_path, c_t_prefix_slash)) {
		gint ii;
		gchar *path;

		path = g_strdup (configure_time_path);

		for (ii = 0; ii < 3; ii++) {
			const gchar *pos;
			gchar *last_slash;

			last_slash = strrchr (path, '/');
			if (!last_slash)
				break;

			*last_slash = '\0';

			pos = strstr (configure_time_prefix, path);
			if (pos && pos[strlen(path)] == '/') {
				g_free (c_t_prefix_slash);
				c_t_prefix_slash = g_strconcat (configure_time_prefix + (pos - configure_time_prefix), "/", NULL);
				break;
			}
		}

		g_free (path);
	}

	if (runtime_prefix &&
	    g_str_has_prefix (configure_time_path, c_t_prefix_slash)) {
		retval = g_strconcat (
			runtime_prefix,
			configure_time_path + strlen (c_t_prefix_slash) - 1,
			NULL);
	} else
		retval = g_strdup (configure_time_path);

	g_free (c_t_prefix_slash);

	return retval;
}

static gchar *
replace_prefix (const gchar *runtime_prefix,
                const gchar *configure_time_path)
{
	return e_util_replace_prefix (
		E_DATA_SERVER_PREFIX, runtime_prefix, configure_time_path);
}

static void
setup (void)
{
	gchar *full_pfx;
	gchar *cp_pfx;

	G_LOCK (mutex);
	if (prefix != NULL) {
		G_UNLOCK (mutex);
		return;
	}

	/* This requires that the libedataserver DLL is installed in $bindir */
	full_pfx = g_win32_get_package_installation_directory_of_module (hmodule);
	cp_pfx = g_win32_locale_filename_from_utf8 (full_pfx);

	prefix = g_strdup (full_pfx);
	cp_prefix = g_strdup (cp_pfx);

	g_free (full_pfx);
	g_free (cp_pfx);

	localedir = replace_prefix (cp_prefix, E_DATA_SERVER_LOCALEDIR);
	imagesdir = replace_prefix (prefix, E_DATA_SERVER_IMAGESDIR);
	credentialmoduledir = replace_prefix (prefix, E_DATA_SERVER_CREDENTIALMODULEDIR);
	uimoduledir = replace_prefix (prefix, E_DATA_SERVER_UIMODULEDIR);

	G_UNLOCK (mutex);
}

#include "libedataserver-private.h" /* For prototypes */

#define GETTER_IMPL(varbl) \
{ \
	setup (); \
	return varbl; \
}

#define PRIVATE_GETTER(varbl) \
const gchar * \
_libedataserver_get_##varbl (void) \
	GETTER_IMPL (varbl)

#define PUBLIC_GETTER(varbl) \
const gchar * \
e_util_get_##varbl (void) \
	GETTER_IMPL (varbl)

PRIVATE_GETTER (imagesdir)
PRIVATE_GETTER (credentialmoduledir);
PRIVATE_GETTER (uimoduledir);

PUBLIC_GETTER (prefix)
PUBLIC_GETTER (cp_prefix)
PUBLIC_GETTER (localedir)

/**
 * e_util_win32_initialize:
 *
 * Initializes win32 environment. This might be called in main().
 **/
void
e_util_win32_initialize (void)
{
	gchar module_filename[2048 + 1];
	DWORD chars;

	/* Reduce risks */
	{
		typedef BOOL (WINAPI *t_SetDllDirectoryA) (LPCSTR lpPathName);
		t_SetDllDirectoryA p_SetDllDirectoryA;

		p_SetDllDirectoryA = GetProcAddress (
			GetModuleHandle ("kernel32.dll"),
			"SetDllDirectoryA");

		if (p_SetDllDirectoryA != NULL)
			p_SetDllDirectoryA ("");
	}
#ifndef _WIN64
	{
		typedef BOOL (WINAPI *t_SetProcessDEPPolicy) (DWORD dwFlags);
		t_SetProcessDEPPolicy p_SetProcessDEPPolicy;

		p_SetProcessDEPPolicy = GetProcAddress (
			GetModuleHandle ("kernel32.dll"),
			"SetProcessDEPPolicy");

		if (p_SetProcessDEPPolicy != NULL)
			p_SetProcessDEPPolicy (
				PROCESS_DEP_ENABLE |
				PROCESS_DEP_DISABLE_ATL_THUNK_EMULATION);
	}
#endif

	if (fileno (stdout) != -1 && _get_osfhandle (fileno (stdout)) != -1) {
		/* stdout is fine, presumably redirected to a file or pipe */
	} else {
		typedef BOOL (* WINAPI AttachConsole_t) (DWORD);

		AttachConsole_t p_AttachConsole =
			(AttachConsole_t) GetProcAddress (
			GetModuleHandle ("kernel32.dll"), "AttachConsole");

		if (p_AttachConsole && p_AttachConsole (ATTACH_PARENT_PROCESS)) {
			freopen ("CONOUT$", "w", stdout);
			dup2 (fileno (stdout), 1);
			freopen ("CONOUT$", "w", stderr);
			dup2 (fileno (stderr), 2);
		}
	}

	chars = GetModuleFileNameA (hmodule, module_filename, 2048);
	if (chars > 0) {
		gchar *path;

		module_filename[chars] = '\0';

		path = strrchr (module_filename, '\\');
		if (path)
			path[1] = '\0';

		path = g_build_path (";", module_filename, g_getenv ("PATH"), NULL);

		if (!g_setenv ("PATH", path, TRUE))
			g_warning ("Could not set PATH for Evolution and its child processes");

		g_free (path);
	}

	/* Make sure D-Bus is running. The executable makes sure the daemon
	   is not restarted, thus it's safe to be called witn D-Bus already
	   running. */
	if (system ("dbus-launch.exe") != 0) {
		/* Ignore, just to mute compiler warning */;
	}
}

#endif	/* G_OS_WIN32 */

static gint default_dbus_timeout = -1;

/**
 * e_data_server_util_set_dbus_call_timeout:
 * @timeout_msec: default timeout for D-Bus calls in miliseconds
 *
 * Sets default timeout, in milliseconds, for calls of g_dbus_proxy_call()
 * family functions.
 *
 * -1 means the default value as set by D-Bus itself.
 * G_MAXINT means no timeout at all.
 *
 * Default value is set also by configure option --with-dbus-call-timeout=ms
 * and -1 is used when not set.
 *
 * Since: 3.0
 *
 * Deprecated: 3.8: This value is not used anywhere.
 **/
void
e_data_server_util_set_dbus_call_timeout (gint timeout_msec)
{
	default_dbus_timeout = timeout_msec;
}

/**
 * e_data_server_util_get_dbus_call_timeout:
 *
 * Returns the value set by e_data_server_util_set_dbus_call_timeout().
 *
 * Returns: the D-Bus call timeout in milliseconds
 *
 * Since: 3.0
 *
 * Deprecated: 3.8: This value is not used anywhere.
 **/
gint
e_data_server_util_get_dbus_call_timeout (void)
{
	return default_dbus_timeout;
}

/**
 * e_named_parameters_new:
 *
 * Creates a new instance of an #ENamedParameters. This should be freed
 * with e_named_parameters_free(), when no longer needed. Names are
 * compared case insensitively.
 *
 * The structure is not thread safe, if the caller requires thread safety,
 * then it should provide it on its own.
 *
 * Returns: newly allocated #ENamedParameters
 *
 * Since: 3.8
 **/
ENamedParameters *
e_named_parameters_new (void)
{
	return (ENamedParameters *) g_ptr_array_new_with_free_func ((GDestroyNotify) e_util_safe_free_string);
}

/**
 * e_named_parameters_new_strv:
 * @strv: NULL-terminated string array to be used as a content of a newly
 *     created #ENamedParameters
 *
 * Creates a new instance of an #ENamedParameters, with initial content
 * being taken from @strv. This should be freed with e_named_parameters_free(),
 * when no longer needed. Names are compared case insensitively.
 *
 * The structure is not thread safe, if the caller requires thread safety,
 * then it should provide it on its own.
 *
 * Returns: newly allocated #ENamedParameters
 *
 * Since: 3.8
 **/
ENamedParameters *
e_named_parameters_new_strv (const gchar * const *strv)
{
	ENamedParameters *parameters;
	gint ii;

	g_return_val_if_fail (strv != NULL, NULL);

	parameters = e_named_parameters_new ();
	for (ii = 0; strv[ii]; ii++) {
		g_ptr_array_add ((GPtrArray *) parameters, g_strdup (strv[ii]));
	}

	return parameters;
}

/**
 * e_named_parameters_new_string:
 * @str: a string to be used as a content of a newly created #ENamedParameters
 *
 * Creates a new instance of an #ENamedParameters, with initial content being
 * taken from @str. This should be freed with e_named_parameters_free(),
 * when no longer needed. Names are compared case insensitively.
 *
 * The @str should be created with e_named_parameters_to_string(), to be
 * properly encoded.
 *
 * The structure is not thread safe, if the caller requires thread safety,
 * then it should provide it on its own.
 *
 * Returns: (transfer full): newly allocated #ENamedParameters
 *
 * Since: 3.18
 **/
ENamedParameters *
e_named_parameters_new_string (const gchar *str)
{
	ENamedParameters *parameters;
	gchar **split;
	gint ii;

	g_return_val_if_fail (str != NULL, NULL);

	split = g_strsplit (str, "\n", -1);

	parameters = e_named_parameters_new ();
	for (ii = 0; split && split[ii]; ii++) {
		g_ptr_array_add ((GPtrArray *) parameters, g_strcompress (split[ii]));
	}

	g_strfreev (split);

	return parameters;
}

/**
 * e_named_parameters_new_clone:
 * @parameters: an #ENamedParameters to be used as a content of a newly
 *    created #ENamedParameters
 *
 * Creates a new instance of an #ENamedParameters, with initial content
 * being taken from @parameters. This should be freed with e_named_parameters_free(),
 * when no longer needed. Names are compared case insensitively.
 *
 * The structure is not thread safe, if the caller requires thread safety,
 * then it should provide it on its own.
 *
 * Returns: newly allocated #ENamedParameters
 *
 * Since: 3.16
 **/
ENamedParameters *
e_named_parameters_new_clone (const ENamedParameters *parameters)
{
	ENamedParameters *clone;

	clone = e_named_parameters_new ();
	if (parameters)
		e_named_parameters_assign (clone, parameters);

	return clone;
}

/**
 * e_named_parameters_free:
 * @parameters: (nullable): an #ENamedParameters
 *
 * Frees an instance of #ENamedParameters, previously allocated
 * with e_named_parameters_new(). Function does nothing, if
 * @parameters is %NULL.
 *
 * Since: 3.8
 **/
void
e_named_parameters_free (ENamedParameters *parameters)
{
	if (!parameters)
		return;

	g_ptr_array_unref ((GPtrArray *) parameters);
}

/**
 * e_named_parameters_clear:
 * @parameters: an #ENamedParameters
 *
 * Removes all stored parameters from @parameters.
 *
 * Since: 3.8
 **/
void
e_named_parameters_clear (ENamedParameters *parameters)
{
	GPtrArray *array;
	g_return_if_fail (parameters != NULL);

	array = (GPtrArray *) parameters;

	if (array->len)
		g_ptr_array_remove_range (array, 0, array->len);
}

/**
 * e_named_parameters_assign:
 * @parameters: an #ENamedParameters to assign values to
 * @from: (allow-none): an #ENamedParameters to get values from, or %NULL
 *
 * Makes content of the @parameters the same as @from.
 * Functions clears content of @parameters if @from is %NULL.
 *
 * Since: 3.8
 **/
void
e_named_parameters_assign (ENamedParameters *parameters,
                           const ENamedParameters *from)
{
	g_return_if_fail (parameters != NULL);

	e_named_parameters_clear (parameters);

	if (from) {
		gint ii;
		GPtrArray *from_array = (GPtrArray *) from;

		for (ii = 0; ii < from_array->len; ii++) {
			g_ptr_array_add (
				(GPtrArray *) parameters,
				g_strdup (from_array->pdata[ii]));
		}
	}
}

static gint
get_parameter_index (const ENamedParameters *parameters,
                     const gchar *name)
{
	GPtrArray *array;
	gint ii, name_len;

	g_return_val_if_fail (parameters != NULL, -1);
	g_return_val_if_fail (name != NULL, -1);

	name_len = strlen (name);

	array = (GPtrArray *) parameters;

	for (ii = 0; ii < array->len; ii++) {
		const gchar *name_and_value = g_ptr_array_index (array, ii);

		if (name_and_value == NULL || strlen (name_and_value) <= name_len)
			continue;

		if (name_and_value[name_len] != ':')
			continue;

		if (g_ascii_strncasecmp (name_and_value, name, name_len) == 0)
			return ii;
	}

	return -1;
}

/**
 * e_named_parameters_set:
 * @parameters: an #ENamedParameters
 * @name: name of a parameter to set
 * @value: (allow-none): value to set, or %NULL to unset
 *
 * Sets parameter named @name to value @value. If @value is NULL,
 * then the parameter is removed. @value can be an empty string.
 *
 * Note: There is a restriction on parameter names, it cannot be empty or
 * contain a colon character (':'), otherwise it can be pretty much anything.
 *
 * Since: 3.8
 **/
void
e_named_parameters_set (ENamedParameters *parameters,
                        const gchar *name,
                        const gchar *value)
{
	GPtrArray *array;
	gint index;
	gchar *name_and_value;

	g_return_if_fail (parameters != NULL);
	g_return_if_fail (name != NULL);
	g_return_if_fail (strchr (name, ':') == NULL);
	g_return_if_fail (*name != '\0');

	array = (GPtrArray *) parameters;

	index = get_parameter_index (parameters, name);
	if (!value) {
		if (index != -1)
			g_ptr_array_remove_index (array, index);
		return;
	}

	name_and_value = g_strconcat (name, ":", value, NULL);
	if (index != -1) {
		g_free (array->pdata[index]);
		array->pdata[index] = name_and_value;
	} else {
		g_ptr_array_add (array, name_and_value);
	}
}

/**
 * e_named_parameters_get:
 * @parameters: an #ENamedParameters
 * @name: name of a parameter to get
 *
 * Returns current value of a parameter with name @name. If not such
 * exists, then returns %NULL.
 *
 * Returns: value of a parameter named @name, or %NULL.
 *
 * Since: 3.8
 **/
const gchar *
e_named_parameters_get (const ENamedParameters *parameters,
                        const gchar *name)
{
	gint index;
	const gchar *name_and_value;

	g_return_val_if_fail (parameters != NULL, NULL);
	g_return_val_if_fail (name != NULL, NULL);

	index = get_parameter_index (parameters, name);
	if (index == -1)
		return NULL;

	name_and_value = g_ptr_array_index ((GPtrArray *) parameters, index);

	return name_and_value + strlen (name) + 1;
}

/**
 * e_named_parameters_test:
 * @parameters: an #ENamedParameters
 * @name: name of a parameter to test
 * @value: value to test
 * @case_sensitively: whether to compare case sensitively
 *
 * Compares current value of parameter named @name with given @value
 * and returns whether they are equal, either case sensitively or
 * insensitively, based on @case_sensitively argument. Function
 * returns %FALSE, if no such parameter exists.
 *
 * Returns: Whether parameter of given name has stored value of given value.
 *
 * Since: 3.8
 **/
gboolean
e_named_parameters_test (const ENamedParameters *parameters,
                         const gchar *name,
                         const gchar *value,
                         gboolean case_sensitively)
{
	const gchar *stored_value;

	g_return_val_if_fail (parameters != NULL, FALSE);
	g_return_val_if_fail (name != NULL, FALSE);
	g_return_val_if_fail (value != NULL, FALSE);

	stored_value = e_named_parameters_get (parameters, name);
	if (!stored_value)
		return FALSE;

	if (case_sensitively)
		return strcmp (stored_value, value) == 0;

	return g_ascii_strcasecmp (stored_value, value) == 0;
}

/**
 * e_named_parameters_to_strv:
 * @parameters: an #ENamedParameters
 *
 * Returns: (transfer full): Contents of @parameters as a null-terminated strv
 *
 * Since: 3.8
 */
gchar **
e_named_parameters_to_strv (const ENamedParameters *parameters)
{
	GPtrArray *array = (GPtrArray *) parameters;
	GPtrArray *ret = g_ptr_array_new ();

	if (array) {
		guint i;
		for (i = 0; i < array->len; i++) {
			g_ptr_array_add (ret, g_strdup (array->pdata[i]));
		}
	}

	g_ptr_array_add (ret, NULL);

	return (gchar **) g_ptr_array_free (ret, FALSE);
}

/**
 * e_named_parameters_to_string:
 * @parameters: an #ENamedParameters
 *
 * Returns: (transfer full): Contents of @parameters as a string
 *
 * Since: 3.18
 */
gchar *
e_named_parameters_to_string (const ENamedParameters *parameters)
{
	gchar **strv, *str;
	gint ii;

	strv = e_named_parameters_to_strv (parameters);
	if (!strv)
		return NULL;

	for (ii = 0; strv[ii]; ii++) {
		gchar *name_and_value = strv[ii];

		strv[ii] = g_strescape (name_and_value, "");
		g_free (name_and_value);
	}

	str = g_strjoinv ("\n", strv);

	g_strfreev (strv);

	return str;
}

/**
 * e_named_parameters_exists:
 * @parameters: an #ENamedParameters
 * @name: name of the parameter whose existence to check
 *
 * Returns: Whether @parameters holds a parameter named @name
 *
 * Since: 3.18
 **/
gboolean
e_named_parameters_exists (const ENamedParameters *parameters,
			   const gchar *name)
{
	g_return_val_if_fail (parameters != NULL, FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	return get_parameter_index (parameters, name) != -1;
}

/**
 * e_named_parameters_count:
 * @parameters: an #ENamedParameters
 *
 * Returns: The number of stored named parameters in @parameters
 *
 * Since: 3.18
 **/
guint
e_named_parameters_count (const ENamedParameters *parameters)
{
	g_return_val_if_fail (parameters != NULL, 0);

	return ((GPtrArray *) parameters)->len;
}

/**
 * e_named_parameters_get_name:
 * @parameters: an #ENamedParameters
 * @index: an index of the parameter whose name to retrieve
 *
 * Returns: (transfer full): The name of the parameters at index @index,
 *    or %NULL, of the @index is out of bounds or other error. The returned
 *    string should be freed with g_free() when done with it.
 *
 * Since: 3.18
 **/
gchar *
e_named_parameters_get_name (const ENamedParameters *parameters,
			     gint index)
{
	const gchar *name_and_value, *colon;

	g_return_val_if_fail (parameters != NULL, NULL);
	g_return_val_if_fail (index >= 0 && index < e_named_parameters_count (parameters), NULL);

	name_and_value = g_ptr_array_index ((GPtrArray *) parameters, index);
	colon = name_and_value ? strchr (name_and_value, ':') : NULL;

	if (!colon || colon == name_and_value)
		return NULL;

	return g_strndup (name_and_value, colon - name_and_value);
}

static ENamedParameters *
e_named_parameters_ref (ENamedParameters *params)
{
	return (ENamedParameters *) g_ptr_array_ref ((GPtrArray *) params);
}

static void
e_named_parameters_unref (ENamedParameters *params)
{
	g_ptr_array_unref ((GPtrArray *) params);
}

G_DEFINE_BOXED_TYPE (
	ENamedParameters,
	e_named_parameters,
	e_named_parameters_ref,
	e_named_parameters_unref);

/**
 * e_named_timeout_add:
 * @interval: the time between calls to the function, in milliseconds
 *            (1/1000ths of a second)
 * @function: function to call
 * @data: data to pass to @function
 *
 * Similar to g_timeout_add(), but also names the #GSource for use in
 * debugging and profiling.  The name is formed from @function and the
 * <literal>PACKAGE</literal> definintion from a &lt;config.h&gt; file.
 *
 * Returns: the ID (greater than 0) of the event source
 *
 * Since: 3.12
 **/

/**
 * e_named_timeout_add_full:
 * @priority: the priority of the timeout source, typically in the
 *            range between #G_PRIORITY_DEFAULT and #G_PRIORITY_HIGH
 * @interval: the time between calls to the function, in milliseconds
 *            (1/1000ths of a second)
 * @function: function to call
 * @data: data to pass to @function
 * @notify: function to call when the timeout is removed, or %NULL
 *
 * Similar to g_timeout_add_full(), but also names the #GSource for use
 * in debugging and profiling.  The name is formed from @function and the
 * <literal>PACKAGE</literal> definition from a &lt;config.h&gt; file.
 *
 * Returns: the ID (greater than 0) of the event source
 *
 * Since: 3.12
 **/

/**
 * e_named_timeout_add_seconds:
 * @interval: the time between calls to the function, in seconds
 * @function: function to call
 * @data: data to pass to @function
 *
 * Similar to g_timeout_add_seconds(), but also names the #GSource for use
 * in debugging and profiling.  The name is formed from @function and the
 * <literal>PACKAGE</literal> definition from a &lt;config.h&gt; file.
 *
 * Returns: the ID (greater than 0) of the event source
 *
 * Since: 3.12
 **/

/**
 * e_named_timeout_add_seconds_full:
 * @priority: the priority of the timeout source, typically in the
 *            range between #G_PRIORITY_DEFAULT and #G_PRIORITY_HIGH
 * @interval: the time between calls to the function, in seconds
 * @function: function to call
 * @data: data to pass to @function
 * @notify: function to call when the timeout is removed, or %NULL
 *
 * Similar to g_timeout_add_seconds_full(), but also names the #GSource for
 * use in debugging and profiling.  The name is formed from @function and the
 * <literal>PACKAGE</literal> definition from a &lt;config.h&gt; file.
 *
 * Returns: the ID (greater than 0) of the event source
 *
 * Since: 3.12
 **/

/**
 * e_timeout_add_with_name:
 * @priority: the priority of the timeout source, typically in the
 *            range between #G_PRIORITY_DEFAULT and #G_PRIORITY_HIGH
 * @interval: the time between calls to the function, in milliseconds
 *            (1/1000ths of a second)
 * @name: (allow-none): debug name for the source
 * @function: function to call
 * @data: data to pass to @function
 * @notify: (allow-none): function to call when the timeout is removed,
 *          or %NULL
 *
 * Similar to g_timeout_add_full(), but also names the #GSource as @name.
 *
 * You might find e_named_timeout_add() or e_named_timeout_add_full() more
 * convenient.  Those macros name the #GSource implicitly.
 *
 * Returns: the ID (greather than 0) of the event source
 *
 * Since: 3.12
 **/
guint
e_timeout_add_with_name (gint priority,
                         guint interval,
                         const gchar *name,
                         GSourceFunc function,
                         gpointer data,
                         GDestroyNotify notify)
{
	guint tag;

	g_return_val_if_fail (function != NULL, 0);

	tag = g_timeout_add_full (
		priority, interval, function, data, notify);
	g_source_set_name_by_id (tag, name);

	return tag;
}

/**
 * e_timeout_add_seconds_with_name:
 * @priority: the priority of the timeout source, typically in the
 *            range between #G_PRIORITY_DEFAULT and #G_PRIORITY_HIGH
 * @interval: the time between calls to the function, in seconds
 * @name: (allow-none): debug name for the source
 * @function: function to call
 * @data: data to pass to @function
 * @notify: (allow-none): function to call when the timeout is removed,
 *          or %NULL
 *
 * Similar to g_timeout_add_seconds_full(), but also names the #GSource as
 * @name.
 *
 * You might find e_named_timeout_add_seconds() or
 * e_named_timeout_add_seconds_full() more convenient.  Those macros name
 * the #GSource implicitly.
 *
 * Returns: the ID (greater than 0) of the event source
 *
 * Since: 3.12
 **/
guint
e_timeout_add_seconds_with_name (gint priority,
                                 guint interval,
                                 const gchar *name,
                                 GSourceFunc function,
                                 gpointer data,
                                 GDestroyNotify notify)
{
	guint tag;

	g_return_val_if_fail (function != NULL, 0);

	tag = g_timeout_add_seconds_full (
		priority, interval, function, data, notify);
	g_source_set_name_by_id (tag, name);

	return tag;
}

/**
 * e_source_registry_debug_enabled:
 *
 * Returns: Whether debugging is enabled, that is,
 * whether e_source_registry_debug_print() will produce any output.
 *
 * Since: 3.16
 **/
gboolean
e_source_registry_debug_enabled (void)
{
	static gint esr_debug = -1;

	if (esr_debug == -1)
		esr_debug = g_strcmp0 (g_getenv ("ESR_DEBUG"), "1") == 0 ? 1 : 0;

	return esr_debug == 1;
}

/**
 * e_source_registry_debug_print:
 * @format: a format string to print
 * @...: other arguments for the format
 *
 * Prints the text only if a debugging is enabled with an environment
 * variable ESR_DEBUG=1.
 *
 * Since: 3.16
 **/
void
e_source_registry_debug_print (const gchar *format,
			       ...)
{
	va_list args;

	if (!e_source_registry_debug_enabled ())
		return;

	va_start (args, format);
	e_util_debug_printv ("ESR", format, args);
	va_end (args);
}

/**
 * e_util_debug_print:
 * @domain: a debug domain
 * @format: a printf-like format
 * @...: arguments for the @format
 *
 * Prints a text according to @format and its arguments to stdout
 * prefixed with @domain in brackets [] and the current date and time.
 * This function doesn't check whether the logging is enabled, it's up
 * to the caller to determine it, the function only prints the information
 * in a consistent format:
 * [domain] YYYY-MM-DD hh:mm:ss.ms - format
 *
 * See: e_util_debug_printv()
 *
 * Since: 3.30
 **/
void
e_util_debug_print (const gchar *domain,
		    const gchar *format,
		    ...)
{
	va_list args;

	va_start (args, format);
	e_util_debug_printv (domain, format, args);
	va_end (args);
}

/**
 * e_util_debug_printv:
 * @domain: a debug domain
 * @format: a printf-like format
 * @args: arguments for the @format
 *
 * Prints a text according to @format and its @args to stdout
 * prefixed with @domain in brackets [] and the current date and time.
 * This function doesn't check whether the logging is enabled, it's up
 * to the caller to determine it, the function only prints the information
 * in a consistent form:
 * [@domain] YYYY-MM-DD hh:mm:ss.ms - @format
 *
 * See: e_util_debug_print()
 *
 * Since: 3.30
 **/
void
e_util_debug_printv (const gchar *domain,
		     const gchar *format,
		     va_list args)
{
	GString *str;
	GDateTime *dt;

	if (!domain)
		domain = "???";

	str = g_string_new ("");
	g_string_vprintf (str, format, args);
	dt = g_date_time_new_now_local ();

	if (dt) {
		g_print ("[%s] %04d-%02d-%02d %02d:%02d:%02d.%03d - %s",
			domain,
			g_date_time_get_year (dt),
			g_date_time_get_month (dt),
			g_date_time_get_day_of_month (dt),
			g_date_time_get_hour (dt),
			g_date_time_get_minute (dt),
			g_date_time_get_second (dt),
			g_date_time_get_microsecond (dt) / 1000,
			str->str);
		g_date_time_unref (dt);
	} else {
		g_print ("[%s] %s", domain, str->str);
	}

	g_string_free (str, TRUE);
}

/**
 * e_type_traverse:
 * @parent_type: the root #GType to traverse from
 * @func: (scope call): the function to call for each visited #GType
 * @user_data: user data to pass to the function
 *
 * Calls @func for all instantiable subtypes of @parent_type.
 *
 * This is often useful for extending functionality by way of #EModule.
 * A module may register a subtype of @parent_type in its e_module_load()
 * function.  Then later on the application will call e_type_traverse()
 * to instantiate all registered subtypes of @parent_type.
 *
 * Since: 3.4
 **/
void
e_type_traverse (GType parent_type,
                 ETypeFunc func,
                 gpointer user_data)
{
	GType *children;
	guint n_children, ii;

	g_return_if_fail (func != NULL);

	children = g_type_children (parent_type, &n_children);

	for (ii = 0; ii < n_children; ii++) {
		GType type = children[ii];

		/* Recurse over the child's children. */
		e_type_traverse (type, func, user_data);

		/* Skip abstract types. */
		if (G_TYPE_IS_ABSTRACT (type))
			continue;

		func (type, user_data);
	}

	g_free (children);
}

/**
 * e_util_get_source_full_name:
 * @registry: an #ESourceRegistry
 * @source: an #ESource
 *
 * Constructs a full name of the @source with all of its parents
 * of the form: "&lt;account-name&gt; : &lt;parent&gt;/&lt;source&gt;" where
 * the "&lt;parent&gt;/" part can be repeated zero or more times, depending
 * on the deep level of the @source.
 *
 * Returns: (transfer full): Full name of the @source as a newly allocated
 *    string, which should be freed with g_free() when done with it.
 *
 * Since 3.18
 **/
gchar *
e_util_get_source_full_name (ESourceRegistry *registry,
			     ESource *source)
{
	GString *fullname;
	GSList *parts, *link;

	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	if (!registry)
		return g_strdup (e_source_get_display_name (source));

	parts = NULL;

	parts = g_slist_prepend (parts, g_strdup (e_source_get_display_name (source)));

	g_object_ref (source);
	while (source) {
		const gchar *parent_id;
		ESource *parent;

		parent_id = e_source_get_parent (source);
		if (!parent_id || !*parent_id)
			break;

		parent = e_source_registry_ref_source (registry, parent_id);
		g_object_unref (source);
		source = parent;

		if (source) {
			const gchar *display_name = e_source_get_display_name (source);

			if (!display_name || !*display_name)
				break;

			parts = g_slist_prepend (parts, g_strdup (display_name));
		}
	}

	g_object_unref (source);

	fullname = g_string_new ("");

	for (link = parts; link; link = link->next) {
		const gchar *part = link->data;

		if (fullname->len) {
			if (link == parts->next)
				g_string_append (fullname, " : ");
			else
				g_string_append_c (fullname, '/');
		}

		g_string_append (fullname, part);
	}

	g_slist_free_full (parts, g_free);

	return g_string_free (fullname, FALSE);
}

static gpointer
unref_object_in_thread (gpointer ptr)
{
	GObject *object = ptr;

	g_return_val_if_fail (object != NULL, NULL);

	g_object_unref (object);

	return NULL;
}

/**
 * e_util_unref_in_thread:
 * @object: a #GObject
 *
 * Unrefs the given @object in a dedicated thread. This is useful when unreffing
 * object deep in call stack when the caller might still use the object and
 * this being the last reference to it.
 *
 * Since: 3.26
 **/
void
e_util_unref_in_thread (gpointer object)
{
	GThread *thread;
	GError *error = NULL;

	if (!object)
		return;

	g_return_if_fail (G_IS_OBJECT (object));

	thread = g_thread_try_new (NULL, unref_object_in_thread, object, &error);
	if (thread) {
		g_thread_unref (thread);
	} else {
		g_warning ("%s: Failed to run thread: %s", G_STRFUNC, error ? error->message : "Unknown error");
		g_object_unref (object);
	}

	g_clear_error (&error);
}

/**
 * e_util_generate_uid:
 *
 * Generates a unique identificator, which can be used as part of
 * the Message-ID header, or iCalendar component UID, or vCard UID.
 * The resulting string doesn't contain any host name, it's
 * a hexa-decimal string with no particular meaning.
 *
 * Free the returned string with g_free(), when no longer needed.
 *
 * Returns: (transfer full): generated unique identificator as
 *    a newly allocated string
 *
 * Since: 3.26
 **/
gchar *
e_util_generate_uid (void)
{
	static volatile gint counter = 0;
	gchar *uid;
	GChecksum *checksum;

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

	add_str (g_get_host_name (), "localhost");
	add_str (g_get_user_name (), "user");
	add_str (g_get_real_name (), "User");

	#undef add_i64
	#undef add_str

	uid = g_strdup (g_checksum_get_string (checksum));

	g_checksum_free (checksum);

	return uid;
}

/**
 * e_util_identity_can_send:
 * @registry: an #ESourceRegistry
 * @identity_source: an #ESource with mail identity extension
 *
 * Checks whether the @identity_source can be used for sending, which means
 * whether it has configures send mail source.
 *
 * Returns: Whether @identity_source can be used to send messages
 *
 * Since: 3.26
 **/
gboolean
e_util_identity_can_send (ESourceRegistry *registry,
			  ESource *identity_source)
{
	ESourceMailSubmission *mail_submission;
	ESource *transport_source = NULL;
	const gchar *transport_uid;
	gboolean can_send = FALSE;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY (registry), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (identity_source), FALSE);

	if (!e_source_has_extension (identity_source, E_SOURCE_EXTENSION_MAIL_IDENTITY) ||
	    !e_source_has_extension (identity_source, E_SOURCE_EXTENSION_MAIL_SUBMISSION))
		return FALSE;

	mail_submission = e_source_get_extension (identity_source, E_SOURCE_EXTENSION_MAIL_SUBMISSION);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (mail_submission));

	transport_uid = e_source_mail_submission_get_transport_uid (mail_submission);
	if (transport_uid && *transport_uid)
		transport_source = e_source_registry_ref_source (registry, transport_uid);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (mail_submission));

	if (!transport_source)
		return FALSE;

	if (e_source_has_extension (transport_source, E_SOURCE_EXTENSION_MAIL_TRANSPORT)) {
		ESourceMailTransport *mail_transport;
		const gchar *backend_name;

		mail_transport = e_source_get_extension (transport_source, E_SOURCE_EXTENSION_MAIL_TRANSPORT);

		e_source_extension_property_lock (E_SOURCE_EXTENSION (mail_transport));

		backend_name = e_source_backend_get_backend_name (E_SOURCE_BACKEND (mail_transport));
		can_send = backend_name && *backend_name && g_strcmp0 (backend_name, "none") != 0;

		e_source_extension_property_unlock (E_SOURCE_EXTENSION (mail_transport));
	}

	g_object_unref (transport_source);

	return can_send;
}

/**
 * e_util_can_use_collection_as_credential_source:
 * @collection_source: (nullable): a collection #ESource, or %NULL
 * @child_source: a children of @collection_source
 *
 * Checks whether the @collection_source can be used as a credential source
 * for the @child_source. The relationship is not tested in the function.
 * When the @collection_source is %NULL, then it simply returns %FALSE.
 *
 * Returns: whether @collection_source can be used as a credential source
 *    for @child_source, that is, whether they share credentials.
 *
 * Since: 3.28
 **/
gboolean
e_util_can_use_collection_as_credential_source (ESource *collection_source,
						ESource *child_source)
{
	gboolean can_use_collection = FALSE;

	if (collection_source)
		g_return_val_if_fail (E_IS_SOURCE (collection_source), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (child_source), FALSE);

	if (collection_source && e_source_has_extension (collection_source, E_SOURCE_EXTENSION_COLLECTION)) {
		/* Use the found parent collection source for credentials store only if
		   the child source doesn't have any authentication information, or this
		   information is not filled, or if either the host name or the user name
		   are the same with the collection source.

		   This allows to create a collection of sources which has one source
		   (like message send) on a different server, thus this source uses
		   its own credentials.
		*/
		if (!e_source_has_extension (child_source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
			can_use_collection = TRUE;
		} else if (e_source_has_extension (collection_source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
			ESourceAuthentication *auth_source, *auth_collection;
			gchar *host_source, *host_collection;

			auth_source = e_source_get_extension (child_source, E_SOURCE_EXTENSION_AUTHENTICATION);
			auth_collection = e_source_get_extension (collection_source, E_SOURCE_EXTENSION_AUTHENTICATION);

			host_source = e_source_authentication_dup_host (auth_source);
			host_collection = e_source_authentication_dup_host (auth_collection);

			if (host_source && host_collection && g_ascii_strcasecmp (host_source, host_collection) == 0) {
				can_use_collection = TRUE;
			} else {
				/* Only one of them is filled, then use the collection; otherwise
				   both are filled and they do not match, thus do not use collection. */
				can_use_collection = (host_collection && *host_collection && (!host_source || !*host_source)) ||
						     (host_source && *host_source && (!host_collection || !*host_collection));
			}

			g_free (host_source);
			g_free (host_collection);

			if (can_use_collection) {
				gchar *username_source, *username_collection;

				username_source = e_source_authentication_dup_user (auth_source);
				username_collection = e_source_authentication_dup_user (auth_collection);

				/* Check user name similarly as host name */
				if (username_source && username_collection && g_ascii_strcasecmp (username_source, username_collection) == 0) {
					can_use_collection = TRUE;
				} else {
					can_use_collection = !username_source || !*username_source;
				}

				g_free (username_source);
				g_free (username_collection);
			}

			if (can_use_collection) {
				gchar *method_source, *method_collection;

				/* Also check the method; if different, then rather not use the collection.
				   Consider 'none' method on the child as the same as the collection method. */
				method_source = e_source_authentication_dup_method (auth_source);
				method_collection = e_source_authentication_dup_method (auth_collection);

				can_use_collection = !method_source || !method_collection ||
					g_ascii_strcasecmp (method_source, "none") == 0 ||
					g_ascii_strcasecmp (method_source, method_collection) == 0;

				g_free (method_source);
				g_free (method_collection);
			}
		}
	}

	return can_use_collection;
}
