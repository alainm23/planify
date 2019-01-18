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

#ifndef CAMEL_SEARCH_PRIVATE_H
#define CAMEL_SEARCH_PRIVATE_H

/* POSIX requires <sys/types.h> be included before <regex.h> */
#include <sys/types.h>

#include <regex.h>

#include <camel/camel.h>

G_BEGIN_DECLS

typedef enum {
	CAMEL_SEARCH_MATCH_START = 1 << 0,
	CAMEL_SEARCH_MATCH_END = 1 << 1,
	CAMEL_SEARCH_MATCH_REGEX = 1 << 2, /* disables the first 2 */
	CAMEL_SEARCH_MATCH_ICASE = 1 << 3,
	CAMEL_SEARCH_MATCH_NEWLINE = 1 << 4
} camel_search_flags_t;

typedef enum {
	CAMEL_SEARCH_MATCH_EXACT,
	CAMEL_SEARCH_MATCH_CONTAINS,
	CAMEL_SEARCH_MATCH_WORD,
	CAMEL_SEARCH_MATCH_STARTS,
	CAMEL_SEARCH_MATCH_ENDS,
	CAMEL_SEARCH_MATCH_SOUNDEX
} camel_search_match_t;

typedef enum {
	CAMEL_SEARCH_TYPE_ASIS,
	CAMEL_SEARCH_TYPE_ENCODED,
	CAMEL_SEARCH_TYPE_ADDRESS,
	CAMEL_SEARCH_TYPE_ADDRESS_ENCODED,
	CAMEL_SEARCH_TYPE_MLIST /* its a mailing list pseudo-header */
} camel_search_t;

/* builds a regex that represents a string search */
gint		camel_search_build_match_regex	(regex_t *pattern,
						 camel_search_flags_t type,
						 gint argc,
						 CamelSExpResult **argv,
						 GError **error);
gboolean	camel_search_message_body_contains
						(CamelDataWrapper *object,
						 regex_t *pattern);

gboolean	camel_search_header_match	(const gchar *value,
						 const gchar *match,
						 camel_search_match_t how,
						 camel_search_t type,
						 const gchar *default_charset);
gboolean	camel_search_camel_header_soundex
						(const gchar *header,
						 const gchar *match);

/* TODO: replace with a real search function */
const gchar *	camel_ustrstrcase		(const gchar *haystack,
						 const gchar *needle);

/* Some crappy utility functions for handling multiple search words */
typedef enum _camel_search_word_t {
	CAMEL_SEARCH_WORD_SIMPLE = 1,
	CAMEL_SEARCH_WORD_COMPLEX = 2,
	CAMEL_SEARCH_WORD_8BIT = 4
} camel_search_word_t;

struct _camel_search_word {
	camel_search_word_t type;
	gchar *word;
};

struct _camel_search_words {
	gint len;
	camel_search_word_t type;	/* OR of all word types in list */
	struct _camel_search_word **words;
};

struct _camel_search_words *
		camel_search_words_split	(const guchar *in);
struct _camel_search_words *
		camel_search_words_simple	(struct _camel_search_words *words);
void		camel_search_words_free		(struct _camel_search_words *words);

gboolean	camel_search_header_is_address	(const gchar *header_name);
const gchar *	camel_search_get_default_charset_from_message
						(CamelMimeMessage *message);
const gchar *	camel_search_get_default_charset_from_headers
						(const CamelNameValueArray *headers);
gchar *		camel_search_get_header_decoded	(const gchar *header_name,
						 const gchar *header_value,
						 const gchar *default_charset);
gchar *		camel_search_get_headers_decoded(const CamelNameValueArray *headers,
						 const gchar *default_charset);
gchar *		camel_search_get_all_headers_decoded
						(CamelMimeMessage *message);

G_END_DECLS

#endif /* CAMEL_SEARCH_PRIVATE_H */
