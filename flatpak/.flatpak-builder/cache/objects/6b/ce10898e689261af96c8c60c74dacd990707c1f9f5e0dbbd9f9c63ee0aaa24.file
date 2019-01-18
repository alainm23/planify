/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- *
 * gtksourcecompletionwordsutils.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2009 - Jesse van den Kieboom
 * Copyright (C) 2013 - Sébastien Wilmet
 *
 * gtksourceview is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * gtksourceview is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "gtksourcecompletionwordsutils.h"
#include <string.h>

/* Here, we work on strings. It is more efficient than working with
 * GtkTextIters to traverse the text (~3x faster). Both techniques are equally
 * difficult to implement.
 */

static gboolean
valid_word_char (gunichar ch)
{
	return g_unichar_isprint (ch) && (ch == '_' || g_unichar_isalnum (ch));
}

static gboolean
valid_start_char (gunichar ch)
{
	return !g_unichar_isdigit (ch);
}

/* Find the next word in @text, beginning at the index @start_idx.
 * Use only valid_word_char() to find the word boundaries.
 * Store in @start_idx and @end_idx the word boundaries. The character at
 * @start_idx is included in the word, but the character at @end_idx is not
 * included in the word (it is the next char, or '\0').
 *
 * Returns %TRUE if a word has been found.
 */
static gboolean
find_next_word (gchar *text,
		guint *start_idx,
		guint *end_idx)
{
	gchar *cur_char;

	/* Find the start of the next word */

	cur_char = text + *start_idx;

	while (TRUE)
	{
		gunichar ch = g_utf8_get_char (cur_char);

		if (ch == '\0')
		{
			return FALSE;
		}

		if (valid_word_char (ch))
		{
			*start_idx = cur_char - text;
			break;
		}

		cur_char = g_utf8_next_char (cur_char);
	}

	/* Find the end of the word */

	while (TRUE)
	{
		gunichar ch;

		cur_char = g_utf8_next_char (cur_char);
		ch = g_utf8_get_char (cur_char);

		if (ch == '\0' ||
		    !valid_word_char (ch))
		{
			*end_idx = cur_char - text;
			return TRUE;
		}
	}
}

/* Get the list of words in @text.
 * You must free the data with g_free(), and free the list with
 * g_slist_free().
 */
GSList *
_gtk_source_completion_words_utils_scan_words (gchar *text,
					       guint  minimum_word_size)
{
	GSList *words = NULL;
	guint start_idx = 0;
	guint end_idx = 0;

	while (find_next_word (text, &start_idx, &end_idx))
	{
		guint word_size;
		gunichar ch;

		g_assert (end_idx >= start_idx);

		word_size = end_idx - start_idx;
		ch = g_utf8_get_char (text + start_idx);

		if (word_size >= minimum_word_size &&
		    valid_start_char (ch))
		{
			gchar *new_word = g_strndup (text + start_idx, word_size);
			words = g_slist_prepend (words, new_word);
		}

		start_idx = end_idx;
	}

	return words;
}

/* Get the word at the end of @text.
 * Returns %NULL if not found.
 * Free the return value with g_free().
 */
gchar *
_gtk_source_completion_words_utils_get_end_word (gchar *text)
{
	gchar *cur_char = text + strlen (text);
	gboolean word_found = FALSE;
	gunichar ch;

	while (TRUE)
	{
		gchar *prev_char = g_utf8_find_prev_char (text, cur_char);

		if (prev_char == NULL)
		{
			break;
		}

		ch = g_utf8_get_char (prev_char);

		if (!valid_word_char (ch))
		{
			break;
		}

		word_found = TRUE;
		cur_char = prev_char;
	}

	if (!word_found)
	{
		return NULL;
	}

	ch = g_utf8_get_char (cur_char);

	if (!valid_start_char (ch))
	{
		return NULL;
	}

	return g_strdup (cur_char);
}

/* Adjust @start and @end to word boundaries, if they touch or are inside a
 * word. Uses only valid_word_char().
 */
void
_gtk_source_completion_words_utils_adjust_region (GtkTextIter *start,
						  GtkTextIter *end)
{
	g_return_if_fail (gtk_text_iter_compare (start, end) <= 0);

	while (TRUE)
	{
		GtkTextIter iter = *start;

		if (!gtk_text_iter_backward_char (&iter))
		{
			break;
		}

		if (!valid_word_char (gtk_text_iter_get_char (&iter)))
		{
			break;
		}

		*start = iter;
	}

	while (valid_word_char (gtk_text_iter_get_char (end)))
	{
		gtk_text_iter_forward_char (end);
	}
}

/* @iter here is a vertical bar between two characters, not the character
 * pointed by @iter. So "inside word" means really "inside word", not the
 * definition used by gtk_text_iter_inside_word().
 */
static gboolean
iter_inside_word (const GtkTextIter *iter)
{
	GtkTextIter prev;

	if (gtk_text_iter_is_start (iter) || gtk_text_iter_is_end (iter))
	{
		return FALSE;
	}

	prev = *iter;
	gtk_text_iter_backward_char (&prev);

	return (valid_word_char (gtk_text_iter_get_char (&prev)) &&
		valid_word_char (gtk_text_iter_get_char (iter)));
}

/* Checks if @start and @end are well placed for scanning the region between the
 * two iters.
 * If an iter isn't well placed, then the library of words will maybe be
 * inconsistent with the words present in the text buffer.
 */
void
_gtk_source_completion_words_utils_check_scan_region (const GtkTextIter *start,
						      const GtkTextIter *end)
{
	g_return_if_fail (gtk_text_iter_compare (start, end) <= 0);

	if (iter_inside_word (start))
	{
		g_warning ("Words completion: 'start' iter not well placed.");
	}

	if (iter_inside_word (end))
	{
		g_warning ("Words completion: 'end' iter not well placed.");
	}
}
