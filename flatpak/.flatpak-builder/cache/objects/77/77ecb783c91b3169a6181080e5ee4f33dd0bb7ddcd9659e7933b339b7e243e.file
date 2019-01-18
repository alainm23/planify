/*
 * e-free-form-exp.c
 *
 * Copyright (C) 2014 Red Hat, Inc. (www.redhat.com)
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

#include "e-free-form-exp.h"

/* <free-form-expression> := <token> *(" " <token>)
   <token> := <and> | <or> | <not> | <expr>
   <and> := "and:(" <free-form-expression>+ ")"
   <or> := "or:(" <free-form-expression>+ ")"
   <not> := "not:(" <free-form-expression>+ ")"
   <expr> := <name> ["-" <options>] ":" <text>
   <name> := CHAR+
   <options> := CHAR+
   <text> := ANYCHAR-EXCEPT-WHITESPACE | "\"" QUOTEDANYCHAR "\""
*/

static GSList *
ffe_tokenize_words (const gchar *ffe)
{
	GSList *words = NULL;
	const gchar *ptr, *start;
	gboolean in_quotes = FALSE;

	if (!ffe)
		return NULL;

	for (ptr = ffe, start = ptr; ptr == ffe || ptr[-1] != 0; ptr++) {
		if (in_quotes && (*ptr == '\"' || !*ptr)) {
			if (ptr[1] == '\"') {
				ptr++;
			} else {
				gchar *qword;
				gint ii, jj;

				in_quotes = FALSE;

				qword = g_malloc (ptr - start + 2);

				/* tab (\t) as the first character is a marker
				   that the string was quoted */
				qword[0] = '\t';
				jj = 1;

				/* convert double-quotes (\"\") into single quotes (\") */
				for (ii = 0; ii < ptr - start; ii++, jj++) {
					qword[jj] = start[ii];

					if (start[ii] == '\"') {
						if (start[ii + 1] == '\"')
							ii++;
					}
				}

				qword[jj] = '\0';

				words = g_slist_prepend (words, qword);
				start = ptr + 1;
			}
		} else if (*ptr == '\"' && (ptr == ffe ||
					    ptr[-1] == ':' ||
					    ptr[-1] == '(' ||
					    ptr[-1] == ' ' ||
					    ptr[-1] == '\t' ||
					    ptr[-1] == '\n' ||
					    ptr[-1] == '\r')) {
			if (ptr > start) {
				words = g_slist_prepend (words, g_strndup (start, ptr - start));
			}
			in_quotes = TRUE;
			start = ptr + 1;
		} else if (!in_quotes) {
			/* word separators */
			if ((*ptr == '(' && start != ptr) || *ptr == ')' || *ptr == ' ' || *ptr == '\t' || *ptr == '\n' || *ptr == '\r' || !*ptr) {
				if (ptr > start || (ptr >= start && *ptr == '(')) {
					words = g_slist_prepend (words, g_strndup (start, ptr - start + (*ptr == '(' ? 1 : 0)));
				}

				if (*ptr == ')') {
					words = g_slist_prepend (words, g_strdup (")"));
				}

				start = ptr + 1;
			}
		}
	}

	return g_slist_reverse (words);
}

static const EFreeFormExpSymbol *
ffe_find_symbol_for (const EFreeFormExpSymbol *symbols,
		     const gchar *word)
{
	const gchar *colon;
	gint ii, jj, kk;

	g_return_val_if_fail (symbols != NULL, NULL);
	g_return_val_if_fail (word != NULL, NULL);

	colon = strchr (word, ':');

	if (colon <= word && *word)
		return NULL;

	for (ii = 0; symbols[ii].names; ii++) {
		const gchar *names = symbols[ii].names;

		if (!*word && !*names)
			return &(symbols[ii]);

		if (!*word)
			continue;

		for (kk = 0; names[kk]; kk++) {
			for (jj = 0; word[jj] && names[kk + jj] && names[kk + jj] != ':'; jj++) {
				if (g_ascii_toupper (word[jj]) != g_ascii_toupper (names[kk + jj]) || word[jj] == '-' || word[jj] == ':')
					break;
			}

			if ((word[jj] == '-' || word[jj] == ':') && (names[kk + jj] == ':' || !names[kk + jj]))
				return &(symbols[ii]);

			while (names[kk] && names[kk] != ':')
				kk++;

			if (!names[kk])
				break;
		}
	}

	return NULL;
}

static gboolean
ffe_process_word (const EFreeFormExpSymbol *symbols,
		  const gchar *in_word,
		  const gchar *next_word,
		  GString **psexp)
{
	GString *sexp;
	gchar *options = NULL, *subsexp;
	const EFreeFormExpSymbol *symbol = NULL;
	gboolean used_next_word = FALSE;

	g_return_val_if_fail (symbols != NULL, FALSE);
	g_return_val_if_fail (in_word != NULL, FALSE);
	g_return_val_if_fail (psexp != NULL, FALSE);

	if (*in_word == '\t') {
		/* tab (\t) as the first character is a marker
		   that the string was quoted */
		in_word++;
	} else {
		gchar *word = NULL;
		const gchar *dash, *colon;

		/* <function>[-<options>]:values */
		dash = strchr (in_word, '-');
		colon = strchr (in_word, ':');

		if (colon > in_word) {
			if (dash > in_word && dash < colon) {
				options = g_strndup (dash + 1, colon - dash - 1);
				word = g_strndup (in_word, dash - in_word + 1);
				word[dash - in_word] = ':';
			} else {
				word = g_strndup (in_word, colon - in_word + 1);
			}
		}

		if (word) {
			symbol = ffe_find_symbol_for (symbols, word);
			if (!symbol) {
				g_free (options);
				options = NULL;
			} else if (colon[1]) {
				in_word = colon + 1;
			} else if (next_word) {
				in_word = next_word;
				if (*in_word == '\t')
					in_word++;
				used_next_word = TRUE;
			} else {
				g_free (options);
				options = NULL;
			}

			g_free (word);
		}
	}

	if (!symbol)
		symbol = ffe_find_symbol_for (symbols, "");

	g_return_val_if_fail (symbol != NULL, FALSE);
	g_return_val_if_fail (symbol->build_sexp != NULL, FALSE);

	sexp = *psexp;
	subsexp = symbol->build_sexp (in_word, options, symbol->hint);

	if (subsexp && *subsexp) {
		if (!sexp) {
			sexp = g_string_new (subsexp);
		} else {
			g_string_append (sexp, subsexp);
		}
	}

	g_free (options);
	g_free (subsexp);

	*psexp = sexp;

	return used_next_word;
}

static void
ffe_finish_and_or_not (GString *sexp)
{
	g_return_if_fail (sexp != NULL);

	if (sexp->len > 4) {
		if (g_str_has_suffix (sexp->str + sexp->len - 5, "(and ") ||
		    g_str_has_suffix (sexp->str + sexp->len - 5, "(not ")) {
			g_string_truncate (sexp, sexp->len - 5);
		} else if (g_str_has_suffix (sexp->str + sexp->len - 4, "(or ")) {
			g_string_truncate (sexp, sexp->len - 4);
		} else {
			g_string_append (sexp, ")");
		}
	} else if (sexp->len == 4) {
		if (g_str_has_suffix (sexp->str + sexp->len - 4, "(or ")) {
			g_string_truncate (sexp, sexp->len - 4);
		} else {
			g_string_append (sexp, ")");
		}
	} else {
		g_string_append (sexp, ")");
	}
}

/**
 * e_free_form_exp_to_sexp:
 * @free_form_exp: a Free Form Expression
 * @symbols: known symbols, which can be used in the Free From Expression
 *
 * Converts the @free_form_exp to an S-Expression using the S-Expression
 * builders defined in the @symbols. The @symbols should have one symbol
 * with an empty string as its name, which is used for words which do not
 * have a symbol name prefix.
 *
 * The @symbols is a NULL-terminated array of known symbols. The NULL should
 * be set for the symbol's name.
 *
 * Returns: converted @free_form_exp into S-Expression, %NULL on error.
 *    Free the returned string with a g_free(), when done with it.
 *
 * Since: 3.16
 **/
gchar *
e_free_form_exp_to_sexp (const gchar *free_form_exp,
			 const EFreeFormExpSymbol *symbols)
{
	GSList *raw_words, *link;
	GString *sexp = NULL;
	gint deep_stack = 0;

	g_return_val_if_fail (free_form_exp != NULL, NULL);
	g_return_val_if_fail (symbols != NULL, NULL);

	raw_words = ffe_tokenize_words (free_form_exp);

	for (link = raw_words; link; link = g_slist_next (link)) {
		const gchar *word = link->data;

		if (!word)
			continue;

		if (*word == '\t') {
			/* tab (\t) as the first character is a marker
			   that the string was quoted */
			ffe_process_word (symbols, word + 1, NULL, &sexp);
		} else if (g_ascii_strncasecmp (word, "not:(", 5) == 0 ||
			   g_ascii_strncasecmp (word, "and:(", 5) == 0 ||
			   g_ascii_strncasecmp (word, "or:(", 4) == 0) {
			if (!sexp)
				sexp = g_string_new ("");

			if (g_ascii_tolower (*word) == 'n')
				g_string_append (sexp, "(not ");
			else if (g_ascii_tolower (*word) == 'a')
				g_string_append (sexp, "(and ");
			else
				g_string_append (sexp, "(or ");

			deep_stack++;
		} else if (g_ascii_strcasecmp (word, ")") == 0) {
			if (deep_stack) {
				g_return_val_if_fail (sexp != NULL, NULL);

				ffe_finish_and_or_not (sexp);
				deep_stack--;
			}
		} else {
			if (ffe_process_word (symbols, word, link->next ? link->next->data : NULL, &sexp))
				link = g_slist_next (link);
		}
	}

	g_slist_free_full (raw_words, g_free);

	while (deep_stack > 0) {
		ffe_finish_and_or_not (sexp);
		deep_stack--;
	}

	if (sexp) {
		g_string_prepend (sexp, "(and ");
		g_string_append (sexp, ")");
	}

	return sexp ? g_string_free (sexp, FALSE) : NULL;
}
