/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcesearchcontext.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2013-2016 - Sébastien Wilmet <swilmet@gnome.org>
 *
 * GtkSourceView is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GtkSourceView is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcesearchcontext.h"
#include "gtksourcesearchsettings.h"
#include "gtksourcebuffer.h"
#include "gtksourcebuffer-private.h"
#include "gtksourcebufferinternal.h"
#include "gtksourcestyle.h"
#include "gtksourcestylescheme.h"
#include "gtksourceutils.h"
#include "gtksourceregion.h"
#include "gtksourceiter.h"
#include "gtksourceview-i18n.h"
#include "gtksourceview-enumtypes.h"

#include <string.h>

/**
 * SECTION:searchcontext
 * @Short_description: Search context
 * @Title: GtkSourceSearchContext
 * @See_also: #GtkSourceBuffer, #GtkSourceSearchSettings
 *
 * A #GtkSourceSearchContext is used for the search and replace in a
 * #GtkSourceBuffer. The search settings are represented by a
 * #GtkSourceSearchSettings object. There can be a many-to-many relationship
 * between buffers and search settings, with the search contexts in-between: a
 * search settings object can be shared between several search contexts; and a
 * buffer can contain several search contexts at the same time.
 *
 * The total number of search occurrences can be retrieved with
 * gtk_source_search_context_get_occurrences_count(). To know the position of a
 * certain match, use gtk_source_search_context_get_occurrence_position().
 *
 * The buffer is scanned asynchronously, so it doesn't block the user interface.
 * For each search, the buffer is scanned at most once. After that, navigating
 * through the occurrences doesn't require to re-scan the buffer entirely.
 *
 * To search forward, use gtk_source_search_context_forward() or
 * gtk_source_search_context_forward_async() for the asynchronous version.
 * The backward search is done similarly. To replace a search match, or all
 * matches, use gtk_source_search_context_replace() and
 * gtk_source_search_context_replace_all().
 *
 * The search occurrences are highlighted by default. To disable it, use
 * gtk_source_search_context_set_highlight(). You can enable the search
 * highlighting for several #GtkSourceSearchContext<!-- -->s attached to the
 * same buffer. Moreover, each of those #GtkSourceSearchContext<!-- -->s can
 * have a different text style associated. Use
 * gtk_source_search_context_set_match_style() to specify the #GtkSourceStyle
 * to apply on search matches.
 *
 * Note that the #GtkSourceSearchContext:highlight and
 * #GtkSourceSearchContext:match-style properties are in the
 * #GtkSourceSearchContext class, not #GtkSourceSearchSettings. Appearance
 * settings should be tied to one, and only one buffer, as different buffers can
 * have different style scheme associated (a #GtkSourceSearchSettings object
 * can be bound indirectly to several buffers).
 *
 * The concept of "current match" doesn't exist yet. A way to highlight
 * differently the current match is to select it.
 *
 * A search occurrence's position doesn't depend on the cursor position or other
 * parameters. Take for instance the buffer "aaaa" with the search text "aa".
 * The two occurrences are at positions [0:2] and [2:4]. If you begin to search
 * at position 1, you will get the occurrence [2:4], not [1:3]. This is a
 * prerequisite for regular expression searches. The pattern ".*" matches the
 * entire line. If the cursor is at the middle of the line, you don't want the
 * rest of the line as the occurrence, you want an entire line. (As a side note,
 * regular expression searches can also match multiple lines.)
 *
 * In the GtkSourceView source code, there is an example of how to use the
 * search and replace API: see the tests/test-search.c file. It is a mini
 * application for the search and replace, with a basic user interface.
 */

/* Implementation overview:
 *
 * When the state of the search changes (the text to search or the options), we
 * have to update the highlighting and the properties values (the number of
 * occurrences). To do so, a simple solution is to first remove all the
 * found_tag, so we have a clean buffer to analyze. The problem with this
 * solution is that there is some flickering when the user modifies the text to
 * search, because removing all the found_tag's can take some time. So we keep
 * the old found_tag's, and when we must highlight the matches in a certain
 * region, we first remove the found_tag's in this region and then we highlight
 * the newly found matches by applying the found_tag to them.
 *
 * If we only want to highlight the matches, without counting the number of
 * occurrences, a good solution would be to highlight only the visible region of
 * the buffer on the screen. So it would be useless to always scan all the
 * buffer.
 *
 * But we actually want the number of occurrences! So we have to scan all the
 * buffer. When the state of the search changes, an idle callback is installed,
 * which will scan the buffer to highlight the matches. To avoid flickering, the
 * visible region on the screen is put in a higher priority region to highlight,
 * so the idle callback will first scan this region.
 *
 * Why highlighting the non-visible matches? What we want is to (1) highlight
 * the visible matches and (2) count the number of occurrences. The code would
 * indeed be simpler if these two tasks were clearly separated (in two different
 * idle callbacks, with different regions to scan). With this simpler solution,
 * we would always use forward_search() and backward_search() to navigate
 * through the occurrences. But we can do better than that!
 * forward_to_tag_toggle() and backward_to_tag_toggle() are far more efficient:
 * once the buffer has been scanned, going to the previous or the next
 * occurrence is done in O(log n), with n the length of the buffer. We must just
 * pay attention to contiguous matches.
 *
 * While the user is typing the text in the search entry, the buffer is scanned
 * to count the number of occurrences. And when the user wants to do an
 * operation (go to the next occurrence for example), chances are that the
 * buffer has already been scanned entirely, so almost all the operations will
 * be really fast.
 *
 * Extreme example:
 * <occurrence> [1 GB of text] <next-occurrence>
 * Once the buffer is scanned, switching between the occurrences will be almost
 * instantaneous.
 *
 * So how to count the number of occurrences then? Remember that the buffer
 * contents can be modified during the scan, and that we keep the old
 * found_tag's. Moreover, when we encounter an old found_tag region, in the
 * general case we can not say how many occurrences there are in this region,
 * since a found_tag region can contain contiguous matches. Take for example the
 * found_tag region "aa": was it the "aa" search match, or two times "a"?
 * The implemented solution is to set occurrences_count to 0 when the search
 * state changes, even if old matches are still there. Because it is not
 * possible to count the old matches to decrement occurrences_count (and storing
 * the previous search text would not be sufficient, because even older matches
 * can still be there). To increment and decrement occurrences_count, there is
 * the scan_region, the region to scan. If an occurrence is contained in
 * scan_region, it means that it has not already been scanned, so
 * occurrences_count doesn't take into account this occurrence. On the other
 * hand, if we find an occurrence outside scan_region, the occurrence is
 * normally correctly highlighted, and occurrences_count take it into account.
 *
 * So when we highlight or when we remove the highlight of an occurrence (on
 * text insertion, deletion, when scanning, etc.), we increment or decrement
 * occurrences_count depending on whether the occurrence was already taken into
 * account by occurrences_count.
 *
 * If the code seems too complicated and contains strange bugs, you have two
 * choices:
 * - Write more unit tests, understand correctly the code and fix it.
 * - Rewrite the code to implement the simpler solution explained above :-)
 *   But with the simpler solution, multiple-lines regex search matches (see
 *   below) would not be possible for going to the previous occurrence (or the
 *   buffer must always be scanned from the beginning).
 *
 * Known issue
 * -----------
 *
 * Contiguous matches have a performance problem. In some cases it can lead to
 * an O(N^2) time complexity. For example if the buffer is full of contiguous
 * matches, and we want to navigate through all of them. If an iter is in the
 * middle of a found_tag region, we don't know where are the nearest occurrence
 * boundaries. Take for example the buffer "aaaa" with the search text "aa". The
 * two occurrences are at positions [0:2] and [2:4]. If we begin to search at
 * position 1, we can not take [1:3] as an occurrence. So what the code do is to
 * go backward to the start of the found_tag region, and do a basic search
 * inside the found_tag region to find the occurrence boundaries.
 *
 * So this is really a corner case, but it's better to be aware of that.
 * To fix the problem, one solution would be to have two found_tag, and
 * alternate them for contiguous matches.
 */

/* Regex search:
 *
 * With a regex, we don't know how many lines a match can span. A regex will
 * most probably match only one line, but a regex can contain something like
 * "\n*", or the dot metacharacter can also match newlines, with the "?s" option
 * (see G_REGEX_DOTALL).
 * Therefore a simple solution is to always begin the search at the beginning of
 * the document. Only the scan_region is taken into account for scanning the
 * buffer.
 *
 * For non-regex searches, when there is an insertion or deletion in the buffer,
 * we don't need to re-scan all the buffer. If there is an unmodified match in
 * the neighborhood, no need to re-scan it (unless at_word_boundaries is set).
 * For a regex search, it is more complicated. An insertion or deletion outside
 * a match can modify a match located in the neighborhood. Take for example the
 * regex "(aa)+" with the buffer contents "aaa". There is one occurrence: the
 * first two letters. If we insert an extra 'a' at the end of the buffer, the
 * occurrence is modified to take the next two letters. That's why the buffer
 * is re-scanned entirely on each insertion or deletion in the buffer.
 *
 * For searching the matches, the easiest solution is to retrieve all the buffer
 * contents, and search the occurrences on this big string. But it takes a lot
 * of memory space. It is better to do multi-segment matching, also called
 * incremental matching. See the pcrepartial(3) manpage. The matching is done
 * segment by segment, with the G_REGEX_MATCH_PARTIAL_HARD flag (for reasons
 * explained in the manpage). We begin by the first segment of the buffer as the
 * subject string. If a partial match is returned, we append the next segment to
 * the subject string, and we try again to find a complete match. When a
 * complete match is returned, we must continue to search the next occurrences.
 * The max lookbehind of the pattern must be retrieved. The start of the next
 * subject string is located at max_lookbehind characters before the end of the
 * previously found match. Similarly, if no match is found (neither a complete
 * match nor a partial match), we take the next segment, with the last
 * max_lookbehind characters from the previous segment.
 *
 * Improvement idea
 * ----------------
 *
 * What we would like to support in applications is the incremental search:
 * while we type the pattern, the buffer is scanned and the matches are
 * highlighted. When the pattern is not fully typed, strange things can happen,
 * including a pattern that match the entire buffer. And if the user is
 * working on a really big file, catastrophe: the UI is blocked!
 * To avoid this problem, a solution is to search the buffer differently
 * depending on the situation:
 * - First situation: the subject string to scan is small enough, we retrieve it
 *   and scan it directly.
 * - Second situation: the subject string to scan is too big, it will take
 *   too much time to retrieve it and scan it directly. We handle this situation
 *   in three phases: (1) retrieving the subject string, chunks by chunks, in
 *   several idle loop iterations. (2) Once the subject string is retrieved
 *   completely, we launch the regex matching in a thread. (3) Once the thread
 *   is finished, we highlight the matches in the buffer. And voilà.
 *
 * But in practice, when trying a pattern that match the entire buffer, we
 * quickly get an error like:
 *
 * 	Regex matching error: Error while matching regular expression (.*\n)*:
 * 	recursion limit reached
 *
 * It happens with test-search, with this file as the buffer (~3500 lines).
 *
 * Improvement idea
 * ----------------
 *
 * GRegex currently doesn't support JIT pattern compilation:
 * https://bugzilla.gnome.org/show_bug.cgi?id=679155
 *
 * Once available, it can be a nice performance improvement (but it must be
 * measured, since g_regex_new() is slower with JIT enabled).
 *
 * Known issue
 * -----------
 *
 * To search at word boundaries, \b is added at the beginning and at the
 * end of the pattern. But \b is not the same as
 * _gtk_source_iter_starts_extra_natural_word() and
 * _gtk_source_iter_ends_extra_natural_word(). \b for
 * example doesn't take the underscore as a word boundary.
 * Using _gtk_source_iter_starts_extra_natural_word() and ends_word() for regex searches
 * is not easily possible: if the GRegex returns a match, but doesn't
 * start and end a word, maybe a shorter match (for a greedy pattern)
 * start and end a word, or a longer match (for an ungreedy pattern). To
 * be able to use the _gtk_source_iter_starts_extra_natural_word() and ends_word()
 * functions for regex search, g_regex_match_all_full() must be used, to
 * retrieve _all_ matches, and test the word boundaries until a match is
 * found at word boundaries.
 */

/*
#define ENABLE_DEBUG
*/
#undef ENABLE_DEBUG

#ifdef ENABLE_DEBUG
#define DEBUG(x) (x)
#else
#define DEBUG(x)
#endif

/* Maximum number of lines to scan in one batch.
 * A lower value means more overhead when scanning the buffer asynchronously.
 */
#define SCAN_BATCH_SIZE 100

enum
{
	PROP_0,
	PROP_BUFFER,
	PROP_SETTINGS,
	PROP_HIGHLIGHT,
	PROP_MATCH_STYLE,
	PROP_OCCURRENCES_COUNT,
	PROP_REGEX_ERROR
};

struct _GtkSourceSearchContextPrivate
{
	/* Weak ref to the buffer. The buffer has also a weak ref to the search
	 * context. A strong ref in either direction would prevent the pointed
	 * object to be finalized.
	 */
	GtkTextBuffer *buffer;

	GtkSourceSearchSettings *settings;

	/* The tag to apply to search occurrences. Even if the highlighting is
	 * disabled, the tag is applied.
	 */
	GtkTextTag *found_tag;

	/* A reference to the tag table where the found_tag is added. The sole
	 * purpose is to remove the found_tag in dispose(). We can not rely on
	 * 'buffer' since it is a weak reference.
	 */
	GtkTextTagTable *tag_table;

	/* The region to scan and highlight. If NULL, the scan is finished. */
	GtkSourceRegion *scan_region;

	/* The region to scan and highlight in priority. I.e. the visible part
	 * of the buffer on the screen.
	 */
	GtkSourceRegion *high_priority_region;

	/* An asynchronous running task. task_region has a higher priority than
	 * scan_region, but a lower priority than high_priority_region.
	 */
	GTask *task;
	GtkSourceRegion *task_region;

	/* If the regex search is disabled, text_nb_lines is the number of lines
	 * of the search text. It is useful to adjust the region to scan.
	 */
	gint text_nb_lines;

	GRegex *regex;
	GError *regex_error;

	gint occurrences_count;
	gulong idle_scan_id;

	GtkSourceStyle *match_style;
	guint highlight : 1;
};

/* Data for the asynchronous forward and backward search tasks. */
typedef struct
{
	GtkTextMark *start_at;
	GtkTextIter match_start;
	GtkTextIter match_end;
	guint found : 1;
	guint wrapped_around : 1;

	/* forward or backward */
	guint is_forward : 1;
} ForwardBackwardData;

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceSearchContext, gtk_source_search_context, G_TYPE_OBJECT);

static void		install_idle_scan		(GtkSourceSearchContext *search);

#ifdef ENABLE_DEBUG
static void
print_region (GtkSourceRegion *region)
{
	gchar *str;

	str = gtk_source_region_to_string (region);
	g_print ("%s\n", str);
	g_free (str);
}
#endif

static void
sync_found_tag (GtkSourceSearchContext *search)
{
	GtkSourceStyle *style = search->priv->match_style;
	GtkSourceStyleScheme *style_scheme;

	if (search->priv->buffer == NULL)
	{
		return;
	}

	if (!search->priv->highlight)
	{
		gtk_source_style_apply (NULL, search->priv->found_tag);
		return;
	}

	if (style == NULL)
	{
		style_scheme = gtk_source_buffer_get_style_scheme (GTK_SOURCE_BUFFER (search->priv->buffer));

		if (style_scheme != NULL)
		{
			style = gtk_source_style_scheme_get_style (style_scheme, "search-match");
		}
	}

	if (style == NULL)
	{
		g_warning ("No match style defined nor 'search-match' style available.");
	}

	gtk_source_style_apply (style, search->priv->found_tag);
}

static void
text_tag_set_highest_priority (GtkTextTag    *tag,
			       GtkTextBuffer *buffer)
{
	GtkTextTagTable *table;
	gint n;

	table = gtk_text_buffer_get_tag_table (buffer);
	n = gtk_text_tag_table_get_size (table);
	gtk_text_tag_set_priority (tag, n - 1);
}

/* Sets @start and @end to the first non-empty subregion.
 * Returns FALSE if the region is empty.
 */
static gboolean
get_first_subregion (GtkSourceRegion *region,
		     GtkTextIter     *start,
		     GtkTextIter     *end)
{
	GtkSourceRegionIter region_iter;

	if (region == NULL)
	{
		return FALSE;
	}

	gtk_source_region_get_start_region_iter (region, &region_iter);

	while (!gtk_source_region_iter_is_end (&region_iter))
	{
		if (!gtk_source_region_iter_get_subregion (&region_iter, start, end))
		{
			return FALSE;
		}

		if (!gtk_text_iter_equal (start, end))
		{
			return TRUE;
		}

		gtk_source_region_iter_next (&region_iter);
	}

	return FALSE;
}

/* Sets @start and @end to the last non-empty subregion.
 * Returns FALSE if the region is empty.
 */
static gboolean
get_last_subregion (GtkSourceRegion *region,
		    GtkTextIter     *start,
		    GtkTextIter     *end)
{
	GtkSourceRegionIter region_iter;
	gboolean found = FALSE;

	if (region == NULL)
	{
		return FALSE;
	}

	gtk_source_region_get_start_region_iter (region, &region_iter);

	while (!gtk_source_region_iter_is_end (&region_iter))
	{
		GtkTextIter start_subregion;
		GtkTextIter end_subregion;

		if (!gtk_source_region_iter_get_subregion (&region_iter,
							   &start_subregion,
							   &end_subregion))
		{
			return FALSE;
		}

		if (!gtk_text_iter_equal (&start_subregion, &end_subregion))
		{
			found = TRUE;
			*start = start_subregion;
			*end = end_subregion;
		}

		gtk_source_region_iter_next (&region_iter);
	}

	return found;
}

static void
clear_task (GtkSourceSearchContext *search)
{
	g_clear_object (&search->priv->task_region);

	if (search->priv->task != NULL)
	{
		GCancellable *cancellable = g_task_get_cancellable (search->priv->task);

		if (cancellable != NULL)
		{
			g_cancellable_cancel (cancellable);
			g_task_return_error_if_cancelled (search->priv->task);
		}

		g_clear_object (&search->priv->task);
	}
}

static void
clear_search (GtkSourceSearchContext *search)
{
	g_clear_object (&search->priv->scan_region);
	g_clear_object (&search->priv->high_priority_region);

	if (search->priv->idle_scan_id != 0)
	{
		g_source_remove (search->priv->idle_scan_id);
		search->priv->idle_scan_id = 0;
	}

	if (search->priv->regex_error != NULL)
	{
		g_clear_error (&search->priv->regex_error);
		g_object_notify (G_OBJECT (search), "regex-error");
	}

	clear_task (search);

	search->priv->occurrences_count = 0;
}

static GtkTextSearchFlags
get_text_search_flags (GtkSourceSearchContext *search)
{
	GtkTextSearchFlags flags = GTK_TEXT_SEARCH_TEXT_ONLY | GTK_TEXT_SEARCH_VISIBLE_ONLY;

	if (!gtk_source_search_settings_get_case_sensitive (search->priv->settings))
	{
		flags |= GTK_TEXT_SEARCH_CASE_INSENSITIVE;
	}

	return flags;
}

/* @start_pos is in bytes. */
static void
regex_search_get_real_start (GtkSourceSearchContext *search,
			     const GtkTextIter      *start,
			     GtkTextIter            *real_start,
			     gint                   *start_pos)
{
	gint max_lookbehind = g_regex_get_max_lookbehind (search->priv->regex);
	gint i;
	gchar *text;

	*real_start = *start;

	for (i = 0; i < max_lookbehind; i++)
	{
		if (!gtk_text_iter_backward_char (real_start))
		{
			break;
		}
	}

	text = gtk_text_iter_get_visible_text (real_start, start);
	*start_pos = strlen (text);

	g_free (text);
}

static GRegexMatchFlags
regex_search_get_match_options (const GtkTextIter *real_start,
				const GtkTextIter *end)
{
	GRegexMatchFlags match_options = 0;

	if (!gtk_text_iter_starts_line (real_start))
	{
		match_options |= G_REGEX_MATCH_NOTBOL;
	}

	if (!gtk_text_iter_ends_line (end))
	{
		match_options |= G_REGEX_MATCH_NOTEOL;
	}

	if (!gtk_text_iter_is_end (end))
	{
		match_options |= G_REGEX_MATCH_PARTIAL_HARD;
	}

	return match_options;
}

/* Get the @match_start and @match_end iters of the @match_info.
 * g_match_info_fetch_pos() returns byte positions. To get the iters, we need to
 * know the number of UTF-8 characters. A GMatchInfo can contain several matches
 * (with g_match_info_next()). So instead of calling g_utf8_strlen() each time
 * at the beginning of @subject, @iter and @iter_byte_pos are used to remember
 * where g_utf8_strlen() stopped.
 */
static gboolean
regex_search_fetch_match (GMatchInfo  *match_info,
			  const gchar *subject,
			  gssize       subject_length,
			  GtkTextIter *iter,
			  gint        *iter_byte_pos,
			  GtkTextIter *match_start,
			  GtkTextIter *match_end)
{
	gint start_byte_pos;
	gint end_byte_pos;
	gint nb_chars;

	g_assert (*iter_byte_pos <= subject_length);
	g_assert (match_start != NULL);
	g_assert (match_end != NULL);

	if (!g_match_info_matches (match_info))
	{
		return FALSE;
	}

	if (!g_match_info_fetch_pos (match_info, 0, &start_byte_pos, &end_byte_pos))
	{
		g_warning ("Impossible to fetch regex match position.");
		return FALSE;
	}

	g_assert (start_byte_pos < subject_length);
	g_assert (end_byte_pos <= subject_length);
	g_assert (*iter_byte_pos <= start_byte_pos);
	g_assert (start_byte_pos < end_byte_pos);

	nb_chars = g_utf8_strlen (subject + *iter_byte_pos,
				  start_byte_pos - *iter_byte_pos);

	*match_start = *iter;
	gtk_text_iter_forward_chars (match_start, nb_chars);

	nb_chars = g_utf8_strlen (subject + start_byte_pos,
				  end_byte_pos - start_byte_pos);

	*match_end = *match_start;
	gtk_text_iter_forward_chars (match_end, nb_chars);

	*iter = *match_end;
	*iter_byte_pos = end_byte_pos;

	return TRUE;
}

/* If you retrieve only [match_start, match_end] from the GtkTextBuffer, it
 * does not match the regex if the regex contains look-ahead assertions. For
 * that, get the @real_end. Note that [match_start, real_end] is not the minimum
 * amount of text that still matches the regex, it can contain several
 * occurrences, so you can add the G_REGEX_MATCH_ANCHORED option to match only
 * the first occurrence.
 * Note that @limit is the limit for @match_end, not @real_end.
 */
static gboolean
basic_forward_regex_search (GtkSourceSearchContext *search,
			    const GtkTextIter      *start_at,
			    GtkTextIter            *match_start,
			    GtkTextIter            *match_end,
			    GtkTextIter            *real_end,
			    const GtkTextIter      *limit)
{
	GtkTextIter real_start;
	GtkTextIter end;
	gint start_pos;
	gboolean found = FALSE;
	gint nb_lines = 1;

	if (search->priv->regex == NULL ||
	    search->priv->regex_error != NULL)
	{
		return FALSE;
	}

	regex_search_get_real_start (search, start_at, &real_start, &start_pos);

	if (limit == NULL)
	{
		gtk_text_buffer_get_end_iter (search->priv->buffer, &end);
	}
	else
	{
		end = *limit;
	}

	while (TRUE)
	{
		GRegexMatchFlags match_options;
		gchar *subject;
		gssize subject_length;
		GMatchInfo *match_info;
		GtkTextIter iter;
		gint iter_byte_pos;
		GtkTextIter m_start;
		GtkTextIter m_end;

		match_options = regex_search_get_match_options (&real_start, &end);
		subject = gtk_text_iter_get_visible_text (&real_start, &end);
		subject_length = strlen (subject);

		g_regex_match_full (search->priv->regex,
				    subject,
				    subject_length,
				    start_pos,
				    match_options,
				    &match_info,
				    &search->priv->regex_error);

		iter = real_start;
		iter_byte_pos = 0;

		found = regex_search_fetch_match (match_info,
						  subject,
						  subject_length,
						  &iter,
						  &iter_byte_pos,
						  &m_start,
						  &m_end);

		if (!found && g_match_info_is_partial_match (match_info))
		{
			gtk_text_iter_forward_lines (&end, nb_lines);
			nb_lines <<= 1;

			g_free (subject);
			g_match_info_free (match_info);
			continue;
		}

		/* Check that the match is not beyond the limit. This can happen
		 * if a partial match is found on the first iteration. Then the
		 * partial match was actually not a good match, but a second
		 * good match is found.
		 */
		if (found && limit != NULL && gtk_text_iter_compare (limit, &m_end) < 0)
		{
			found = FALSE;
		}

		if (search->priv->regex_error != NULL)
		{
			g_object_notify (G_OBJECT (search), "regex-error");
			found = FALSE;
		}

		if (found)
		{
			if (match_start != NULL)
			{
				*match_start = m_start;
			}

			if (match_end != NULL)
			{
				*match_end = m_end;
			}

			if (real_end != NULL)
			{
				*real_end = end;
			}
		}

		g_free (subject);
		g_match_info_free (match_info);
		break;
	}

	return found;
}

static gboolean
basic_forward_search (GtkSourceSearchContext *search,
		      const GtkTextIter      *iter,
		      GtkTextIter            *match_start,
		      GtkTextIter            *match_end,
		      const GtkTextIter      *limit)
{
	GtkTextIter begin_search = *iter;
	const gchar *search_text = gtk_source_search_settings_get_search_text (search->priv->settings);
	GtkTextSearchFlags flags;

	if (search_text == NULL)
	{
		return FALSE;
	}

	if (gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		return basic_forward_regex_search (search,
						   iter,
						   match_start,
						   match_end,
						   NULL,
						   limit);
	}

	flags = get_text_search_flags (search);

	while (TRUE)
	{
		gboolean found = gtk_text_iter_forward_search (&begin_search,
							       search_text,
							       flags,
							       match_start,
							       match_end,
							       limit);

		if (!found || !gtk_source_search_settings_get_at_word_boundaries (search->priv->settings))
		{
			return found;
		}

		if (_gtk_source_iter_starts_extra_natural_word (match_start, FALSE) &&
		    _gtk_source_iter_ends_extra_natural_word (match_end, FALSE))
		{
			return TRUE;
		}

		begin_search = *match_end;
	}
}

/* We fake the backward regex search by doing a forward search, and taking the
 * last match.
 */
static gboolean
basic_backward_regex_search (GtkSourceSearchContext *search,
			     const GtkTextIter      *start_at,
			     GtkTextIter            *match_start,
			     GtkTextIter            *match_end,
			     const GtkTextIter      *limit)
{
	GtkTextIter lower_bound;
	GtkTextIter m_start;
	GtkTextIter m_end;
	gboolean found = FALSE;

	if (search->priv->regex == NULL ||
	    search->priv->regex_error != NULL)
	{
		return FALSE;
	}

	if (limit == NULL)
	{
		gtk_text_buffer_get_start_iter (search->priv->buffer, &lower_bound);
	}
	else
	{
		lower_bound = *limit;
	}

	while (basic_forward_regex_search (search, &lower_bound, &m_start, &m_end, NULL, start_at))
	{
		found = TRUE;

		if (match_start != NULL)
		{
			*match_start = m_start;
		}

		if (match_end != NULL)
		{
			*match_end = m_end;
		}

		lower_bound = m_end;
	}

	return found;
}

static gboolean
basic_backward_search (GtkSourceSearchContext *search,
		       const GtkTextIter      *iter,
		       GtkTextIter            *match_start,
		       GtkTextIter            *match_end,
		       const GtkTextIter      *limit)
{
	GtkTextIter begin_search = *iter;
	const gchar *search_text = gtk_source_search_settings_get_search_text (search->priv->settings);
	GtkTextSearchFlags flags;

	if (search_text == NULL)
	{
		return FALSE;
	}

	if (gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		return basic_backward_regex_search (search,
						    iter,
						    match_start,
						    match_end,
						    limit);
	}

	flags = get_text_search_flags (search);

	while (TRUE)
	{
		gboolean found = gtk_text_iter_backward_search (&begin_search,
							        search_text,
							        flags,
							        match_start,
							        match_end,
							        limit);

		if (!found || !gtk_source_search_settings_get_at_word_boundaries (search->priv->settings))
		{
			return found;
		}

		if (_gtk_source_iter_starts_extra_natural_word (match_start, FALSE) &&
		    _gtk_source_iter_ends_extra_natural_word (match_end, FALSE))
		{
			return TRUE;
		}

		begin_search = *match_start;
	}
}

static void
forward_backward_data_free (ForwardBackwardData *data)
{
	if (data->start_at != NULL)
	{
		GtkTextBuffer *buffer = gtk_text_mark_get_buffer (data->start_at);
		gtk_text_buffer_delete_mark (buffer, data->start_at);
	}

	g_slice_free (ForwardBackwardData, data);
}

/* Returns TRUE if finished. */
static gboolean
smart_forward_search_async_step (GtkSourceSearchContext *search,
				 GtkTextIter            *start_at,
				 gboolean               *wrapped_around)
{
	GtkTextIter iter = *start_at;
	GtkTextIter limit;
	GtkTextIter region_start = *start_at;
	GtkSourceRegion *region = NULL;
	ForwardBackwardData *task_data;
	const gchar *search_text = gtk_source_search_settings_get_search_text (search->priv->settings);

	if (gtk_text_iter_is_end (start_at))
	{
		if (search_text != NULL &&
		    !*wrapped_around &&
		    gtk_source_search_settings_get_wrap_around (search->priv->settings))
		{
			gtk_text_buffer_get_start_iter (search->priv->buffer, start_at);
			*wrapped_around = TRUE;
			return FALSE;
		}

		task_data = g_slice_new0 (ForwardBackwardData);
		task_data->found = FALSE;
		task_data->is_forward = TRUE;
		task_data->wrapped_around = *wrapped_around;

		g_task_return_pointer (search->priv->task,
				       task_data,
				       (GDestroyNotify)forward_backward_data_free);

		g_clear_object (&search->priv->task);
		return TRUE;
	}

	if (!gtk_text_iter_has_tag (&iter, search->priv->found_tag))
	{
		gtk_text_iter_forward_to_tag_toggle (&iter, search->priv->found_tag);
	}
	else if (!gtk_text_iter_starts_tag (&iter, search->priv->found_tag))
	{
		gtk_text_iter_backward_to_tag_toggle (&iter, search->priv->found_tag);
		region_start = iter;
	}

	limit = iter;
	gtk_text_iter_forward_to_tag_toggle (&limit, search->priv->found_tag);

	if (search->priv->scan_region != NULL)
	{
		region = gtk_source_region_intersect_subregion (search->priv->scan_region,
								&region_start,
								&limit);
	}

	if (gtk_source_region_is_empty (region))
	{
		GtkTextIter match_start;
		GtkTextIter match_end;

		g_clear_object (&region);

		while (basic_forward_search (search, &iter, &match_start, &match_end, &limit))
		{
			if (gtk_text_iter_compare (&match_start, start_at) < 0)
			{
				iter = match_end;
				continue;
			}

			task_data = g_slice_new0 (ForwardBackwardData);
			task_data->found = TRUE;
			task_data->match_start = match_start;
			task_data->match_end = match_end;
			task_data->is_forward = TRUE;
			task_data->wrapped_around = *wrapped_around;

			g_task_return_pointer (search->priv->task,
					       task_data,
					       (GDestroyNotify)forward_backward_data_free);

			g_clear_object (&search->priv->task);
			return TRUE;
		}

		*start_at = limit;
		return FALSE;
	}

	task_data = g_slice_new0 (ForwardBackwardData);
	task_data->is_forward = TRUE;
	task_data->wrapped_around = *wrapped_around;
	task_data->start_at = gtk_text_buffer_create_mark (search->priv->buffer,
							   NULL,
							   start_at,
							   TRUE);

	g_task_set_task_data (search->priv->task,
			      task_data,
			      (GDestroyNotify)forward_backward_data_free);

	g_clear_object (&search->priv->task_region);
	search->priv->task_region = region;

	install_idle_scan (search);

	/* The idle that scan the task region will call
	 * smart_forward_search_async() to continue the task. But for the
	 * moment, we are done.
	 */
	return TRUE;
}

static void
smart_forward_search_async (GtkSourceSearchContext *search,
			    const GtkTextIter      *start_at,
			    gboolean                wrapped_around)
{
	GtkTextIter iter = *start_at;

	/* A recursive function would have been more natural, but a loop is
	 * better to avoid stack overflows.
	 */
	while (!smart_forward_search_async_step (search, &iter, &wrapped_around));
}


/* Returns TRUE if finished. */
static gboolean
smart_backward_search_async_step (GtkSourceSearchContext *search,
				  GtkTextIter            *start_at,
				  gboolean               *wrapped_around)
{
	GtkTextIter iter = *start_at;
	GtkTextIter limit;
	GtkTextIter region_end = *start_at;
	GtkSourceRegion *region = NULL;
	ForwardBackwardData *task_data;
	const gchar *search_text = gtk_source_search_settings_get_search_text (search->priv->settings);

	if (gtk_text_iter_is_start (start_at))
	{
		if (search_text != NULL &&
		    !*wrapped_around &&
		    gtk_source_search_settings_get_wrap_around (search->priv->settings))
		{
			gtk_text_buffer_get_end_iter (search->priv->buffer, start_at);
			*wrapped_around = TRUE;
			return FALSE;
		}

		task_data = g_slice_new0 (ForwardBackwardData);
		task_data->found = FALSE;
		task_data->is_forward = FALSE;
		task_data->wrapped_around = *wrapped_around;

		g_task_return_pointer (search->priv->task,
				       task_data,
				       (GDestroyNotify)forward_backward_data_free);

		g_clear_object (&search->priv->task);
		return TRUE;
	}

	if (gtk_text_iter_starts_tag (&iter, search->priv->found_tag) ||
	    (!gtk_text_iter_has_tag (&iter, search->priv->found_tag) &&
	     !gtk_text_iter_ends_tag (&iter, search->priv->found_tag)))
	{
		gtk_text_iter_backward_to_tag_toggle (&iter, search->priv->found_tag);
	}
	else if (gtk_text_iter_has_tag (&iter, search->priv->found_tag))
	{
		gtk_text_iter_forward_to_tag_toggle (&iter, search->priv->found_tag);
		region_end = iter;
	}

	limit = iter;
	gtk_text_iter_backward_to_tag_toggle (&limit, search->priv->found_tag);

	if (search->priv->scan_region != NULL)
	{
		region = gtk_source_region_intersect_subregion (search->priv->scan_region,
								&limit,
								&region_end);
	}

	if (gtk_source_region_is_empty (region))
	{
		GtkTextIter match_start;
		GtkTextIter match_end;

		g_clear_object (&region);

		while (basic_backward_search (search, &iter, &match_start, &match_end, &limit))
		{
			if (gtk_text_iter_compare (start_at, &match_end) < 0)
			{
				iter = match_start;
				continue;
			}

			task_data = g_slice_new0 (ForwardBackwardData);
			task_data->found = TRUE;
			task_data->match_start = match_start;
			task_data->match_end = match_end;
			task_data->is_forward = FALSE;
			task_data->wrapped_around = *wrapped_around;

			g_task_return_pointer (search->priv->task,
					       task_data,
					       (GDestroyNotify)forward_backward_data_free);

			g_clear_object (&search->priv->task);
			return TRUE;
		}

		*start_at = limit;
		return FALSE;
	}

	task_data = g_slice_new0 (ForwardBackwardData);
	task_data->is_forward = FALSE;
	task_data->wrapped_around = *wrapped_around;
	task_data->start_at = gtk_text_buffer_create_mark (search->priv->buffer,
							   NULL,
							   start_at,
							   TRUE);

	g_task_set_task_data (search->priv->task,
			      task_data,
			      (GDestroyNotify)forward_backward_data_free);

	g_clear_object (&search->priv->task_region);
	search->priv->task_region = region;

	install_idle_scan (search);

	/* The idle that scan the task region will call
	 * smart_backward_search_async() to continue the task. But for the
	 * moment, we are done.
	 */
	return TRUE;
}

static void
smart_backward_search_async (GtkSourceSearchContext *search,
			     const GtkTextIter      *start_at,
			     gboolean                wrapped_around)
{
	GtkTextIter iter = *start_at;

	/* A recursive function would have been more natural, but a loop is
	 * better to avoid stack overflows.
	 */
	while (!smart_backward_search_async_step (search, &iter, &wrapped_around));
}

/* Adjust the subregion so we are sure that all matches that are visible or
 * partially visible between @start and @end are highlighted.
 */
static void
adjust_subregion (GtkSourceSearchContext *search,
		  GtkTextIter            *start,
		  GtkTextIter            *end)
{
	DEBUG ({
		g_print ("adjust_subregion(), before adjusting: [%u (%u), %u (%u)]\n",
			 gtk_text_iter_get_line (start), gtk_text_iter_get_offset (start),
			 gtk_text_iter_get_line (end), gtk_text_iter_get_offset (end));
	});

	gtk_text_iter_backward_lines (start, MAX (0, search->priv->text_nb_lines - 1));
	gtk_text_iter_forward_lines (end, MAX (0, search->priv->text_nb_lines - 1));

	if (!gtk_text_iter_starts_line (start))
	{
		gtk_text_iter_set_line_offset (start, 0);
	}

	if (!gtk_text_iter_ends_line (end))
	{
		gtk_text_iter_forward_to_line_end (end);
	}

	/* When we are in the middle of a found_tag, a simple solution is to
	 * always backward_to_tag_toggle(). The problem is that occurrences can
	 * be contiguous. So a full scan of the buffer can have a O(n^2) in the
	 * worst case, if we use the simple solution. Therefore we use a more
	 * complicated solution, that checks if we are in an old found_tag or
	 * not.
	 */

	if (gtk_text_iter_has_tag (start, search->priv->found_tag))
	{
		if (gtk_source_region_is_empty (search->priv->scan_region))
		{
			/* 'start' is in a correct match, we can skip it. */
			gtk_text_iter_forward_to_tag_toggle (start, search->priv->found_tag);
		}
		else
		{
			GtkTextIter tag_start = *start;
			GtkTextIter tag_end = *start;
			GtkSourceRegion *region;

			if (!gtk_text_iter_starts_tag (&tag_start, search->priv->found_tag))
			{
				gtk_text_iter_backward_to_tag_toggle (&tag_start, search->priv->found_tag);
			}

			gtk_text_iter_forward_to_tag_toggle (&tag_end, search->priv->found_tag);

			region = gtk_source_region_intersect_subregion (search->priv->scan_region,
									&tag_start,
									&tag_end);

			if (gtk_source_region_is_empty (region))
			{
				/* 'region' has already been scanned, so 'start' is in a
				 * correct match, we can skip it.
				 */
				*start = tag_end;
			}
			else
			{
				/* 'region' has not already been scanned completely, so
				 * 'start' is most probably in an old match that must be
				 * removed.
				 */
				*start = tag_start;
			}

			g_clear_object (&region);
		}
	}

	/* Symmetric for 'end'. */

	if (gtk_text_iter_has_tag (end, search->priv->found_tag))
	{
		if (gtk_source_region_is_empty (search->priv->scan_region))
		{
			/* 'end' is in a correct match, we can skip it. */

			if (!gtk_text_iter_starts_tag (end, search->priv->found_tag))
			{
				gtk_text_iter_backward_to_tag_toggle (end, search->priv->found_tag);
			}
		}
		else
		{
			GtkTextIter tag_start = *end;
			GtkTextIter tag_end = *end;
			GtkSourceRegion *region;

			if (!gtk_text_iter_starts_tag (&tag_start, search->priv->found_tag))
			{
				gtk_text_iter_backward_to_tag_toggle (&tag_start, search->priv->found_tag);
			}

			gtk_text_iter_forward_to_tag_toggle (&tag_end, search->priv->found_tag);

			region = gtk_source_region_intersect_subregion (search->priv->scan_region,
									&tag_start,
									&tag_end);

			if (gtk_source_region_is_empty (region))
			{
				/* 'region' has already been scanned, so 'end' is in a
				 * correct match, we can skip it.
				 */
				*end = tag_start;
			}
			else
			{
				/* 'region' has not already been scanned completely, so
				 * 'end' is most probably in an old match that must be
				 * removed.
				 */
				*end = tag_end;
			}

			g_clear_object (&region);
		}
	}

	DEBUG ({
		g_print ("adjust_subregion(), after adjusting: [%u (%u), %u (%u)]\n",
			 gtk_text_iter_get_line (start), gtk_text_iter_get_offset (start),
			 gtk_text_iter_get_line (end), gtk_text_iter_get_offset (end));
	});
}

/* Do not take into account the scan_region. Take the result with a grain of
 * salt. You should verify before or after calling this function that the
 * region has been scanned, to be sure that the returned occurrence is correct.
 */
static gboolean
smart_forward_search_without_scanning (GtkSourceSearchContext *search,
				       const GtkTextIter      *start_at,
				       GtkTextIter            *match_start,
				       GtkTextIter            *match_end,
				       const GtkTextIter      *stop_at)
{
	GtkTextIter iter;
	const gchar *search_text = gtk_source_search_settings_get_search_text (search->priv->settings);

	g_assert (start_at != NULL);
	g_assert (match_start != NULL);
	g_assert (match_end != NULL);
	g_assert (stop_at != NULL);

	iter = *start_at;

	if (search_text == NULL)
	{
		return FALSE;
	}

	while (gtk_text_iter_compare (&iter, stop_at) < 0)
	{
		GtkTextIter limit;

		if (!gtk_text_iter_has_tag (&iter, search->priv->found_tag))
		{
			gtk_text_iter_forward_to_tag_toggle (&iter, search->priv->found_tag);
		}
		else if (!gtk_text_iter_starts_tag (&iter, search->priv->found_tag))
		{
			gtk_text_iter_backward_to_tag_toggle (&iter, search->priv->found_tag);
		}

		limit = iter;
		gtk_text_iter_forward_to_tag_toggle (&limit, search->priv->found_tag);

		if (gtk_text_iter_compare (stop_at, &limit) < 0)
		{
			limit = *stop_at;
		}

		while (basic_forward_search (search, &iter, match_start, match_end, &limit))
		{
			if (gtk_text_iter_compare (start_at, match_start) <= 0)
			{
				return TRUE;
			}

			iter = *match_end;
		}

		iter = limit;
	}

	return FALSE;
}

/* Remove the occurrences in the range. @start and @end may be adjusted, if they
 * are in a found_tag region.
 */
static void
remove_occurrences_in_range (GtkSourceSearchContext *search,
			     GtkTextIter            *start,
			     GtkTextIter            *end)
{
	GtkTextIter iter;
	GtkTextIter match_start;
	GtkTextIter match_end;

	if ((gtk_text_iter_has_tag (start, search->priv->found_tag) &&
	     !gtk_text_iter_starts_tag (start, search->priv->found_tag)) ||
	    (gtk_source_search_settings_get_at_word_boundaries (search->priv->settings) &&
	     gtk_text_iter_ends_tag (start, search->priv->found_tag)))
	{
		gtk_text_iter_backward_to_tag_toggle (start, search->priv->found_tag);
	}

	if ((gtk_text_iter_has_tag (end, search->priv->found_tag) &&
	     !gtk_text_iter_starts_tag (end, search->priv->found_tag)) ||
	    (gtk_source_search_settings_get_at_word_boundaries (search->priv->settings) &&
	     gtk_text_iter_starts_tag (end, search->priv->found_tag)))
	{
		gtk_text_iter_forward_to_tag_toggle (end, search->priv->found_tag);
	}

	iter = *start;

	while (smart_forward_search_without_scanning (search, &iter, &match_start, &match_end, end))
	{
		if (search->priv->scan_region == NULL)
		{
			/* The occurrence has already been scanned, and thus
			 * occurrence_count take it into account. */
			search->priv->occurrences_count--;
		}
		else
		{
			GtkSourceRegion *region;

			region = gtk_source_region_intersect_subregion (search->priv->scan_region,
									&match_start,
									&match_end);

			if (gtk_source_region_is_empty (region))
			{
				search->priv->occurrences_count--;
			}

			g_clear_object (&region);
		}

		iter = match_end;
	}

	gtk_text_buffer_remove_tag (search->priv->buffer,
				    search->priv->found_tag,
				    start,
				    end);
}

static void
scan_subregion (GtkSourceSearchContext *search,
		GtkTextIter            *start,
		GtkTextIter            *end)
{
	GtkTextIter iter;
	GtkTextIter *limit;
	gboolean found = TRUE;
	const gchar *search_text = gtk_source_search_settings_get_search_text (search->priv->settings);

	/* Make sure the 'found' tag has the priority over syntax highlighting
	 * tags. */
	text_tag_set_highest_priority (search->priv->found_tag,
				       search->priv->buffer);

	adjust_subregion (search, start, end);
	remove_occurrences_in_range (search, start, end);

	if (search->priv->scan_region != NULL)
	{
		DEBUG ({
			g_print ("Region to scan, before:\n");
			print_region (search->priv->scan_region);
		});

		gtk_source_region_subtract_subregion (search->priv->scan_region, start, end);

		DEBUG ({
			g_print ("Region to scan, after:\n");
			print_region (search->priv->scan_region);
		});
	}

	if (search->priv->task_region != NULL)
	{
		gtk_source_region_subtract_subregion (search->priv->task_region, start, end);
	}

	if (search_text == NULL)
	{
		/* We have removed the found_tag, we are done. */
		return;
	}

	iter = *start;

	if (gtk_text_iter_is_end (end))
	{
		limit = NULL;
	}
	else
	{
		limit = end;
	}

	do
	{
		GtkTextIter match_start;
		GtkTextIter match_end;

		found = basic_forward_search (search, &iter, &match_start, &match_end, limit);

		if (found)
		{
			gtk_text_buffer_apply_tag (search->priv->buffer,
						   search->priv->found_tag,
						   &match_start,
						   &match_end);

			search->priv->occurrences_count++;
		}

		iter = match_end;

	} while (found);
}

static void
scan_all_region (GtkSourceSearchContext *search,
		 GtkSourceRegion        *region)
{
	GtkSourceRegionIter region_iter;

	gtk_source_region_get_start_region_iter (region, &region_iter);

	while (!gtk_source_region_iter_is_end (&region_iter))
	{
		GtkTextIter subregion_start;
		GtkTextIter subregion_end;

		if (!gtk_source_region_iter_get_subregion (&region_iter,
							   &subregion_start,
							   &subregion_end))
		{
			break;
		}

		scan_subregion (search,
				&subregion_start,
				&subregion_end);

		gtk_source_region_iter_next (&region_iter);
	}
}

/* Scan a chunk of the region. If the region is small enough, all the region
 * will be scanned. But if the region is big, scanning only the chunk will not
 * block the UI normally. Begin the scan at the beginning of the region.
 */
static void
scan_region_forward (GtkSourceSearchContext *search,
		     GtkSourceRegion        *region)
{
	gint nb_remaining_lines = SCAN_BATCH_SIZE;
	GtkTextIter start;
	GtkTextIter end;

	while (nb_remaining_lines > 0 &&
	       get_first_subregion (region, &start, &end))
	{
		GtkTextIter limit = start;
		gint start_line;
		gint limit_line;

		gtk_text_iter_forward_lines (&limit, nb_remaining_lines);

		if (gtk_text_iter_compare (&end, &limit) < 0)
		{
			limit = end;
		}

		scan_subregion (search, &start, &limit);

		gtk_source_region_subtract_subregion (region, &start, &limit);

		start_line = gtk_text_iter_get_line (&start);
		limit_line = gtk_text_iter_get_line (&limit);

		nb_remaining_lines -= limit_line - start_line;
	}
}

/* Same as scan_region_forward(), but begins the scan at the end of the region. */
static void
scan_region_backward (GtkSourceSearchContext *search,
		      GtkSourceRegion        *region)
{
	gint nb_remaining_lines = SCAN_BATCH_SIZE;
	GtkTextIter start;
	GtkTextIter end;

	while (nb_remaining_lines > 0 &&
	       get_last_subregion (region, &start, &end))
	{
		GtkTextIter limit = end;
		gint limit_line;
		gint end_line;

		gtk_text_iter_backward_lines (&limit, nb_remaining_lines);

		if (gtk_text_iter_compare (&limit, &start) < 0)
		{
			limit = start;
		}

		scan_subregion (search, &limit, &end);

		gtk_source_region_subtract_subregion (region, &limit, &end);

		limit_line = gtk_text_iter_get_line (&limit);
		end_line = gtk_text_iter_get_line (&end);

		nb_remaining_lines -= end_line - limit_line;
	}
}

static void
resume_task (GtkSourceSearchContext *search)
{
	ForwardBackwardData *task_data = g_task_get_task_data (search->priv->task);
	GtkTextIter start_at;

	g_clear_object (&search->priv->task_region);

	gtk_text_buffer_get_iter_at_mark (search->priv->buffer,
					  &start_at,
					  task_data->start_at);

	if (task_data->is_forward)
	{
		smart_forward_search_async (search,
					    &start_at,
					    task_data->wrapped_around);
	}
	else
	{
		smart_backward_search_async (search,
					     &start_at,
					     task_data->wrapped_around);
	}
}

static void
scan_task_region (GtkSourceSearchContext *search)
{
	ForwardBackwardData *task_data = g_task_get_task_data (search->priv->task);

	if (task_data->is_forward)
	{
		scan_region_forward (search, search->priv->task_region);
	}
	else
	{
		scan_region_backward (search, search->priv->task_region);
	}

	resume_task (search);
}

static gboolean
idle_scan_normal_search (GtkSourceSearchContext *search)
{
	if (search->priv->high_priority_region != NULL)
	{
		/* Normally the high priority region is not really big, since it
		 * is the visible area on the screen. So we can highlight it in
		 * one batch.
		 */
		scan_all_region (search, search->priv->high_priority_region);

		g_clear_object (&search->priv->high_priority_region);
		return G_SOURCE_CONTINUE;
	}

	if (search->priv->task_region != NULL)
	{
		scan_task_region (search);
		return G_SOURCE_CONTINUE;
	}

	scan_region_forward (search, search->priv->scan_region);

	if (gtk_source_region_is_empty (search->priv->scan_region))
	{
		search->priv->idle_scan_id = 0;

		g_object_notify (G_OBJECT (search), "occurrences-count");

		g_clear_object (&search->priv->scan_region);
		return G_SOURCE_REMOVE;
	}

	return G_SOURCE_CONTINUE;
}

/* Just remove the found_tag's located in the high-priority region. For big
 * documents, if the pattern is modified, it can take some time to re-scan all
 * the buffer, so it's better to clear the highlighting as soon as possible. If
 * the highlighting is not cleared, the user can wrongly think that the new
 * pattern matches the old occurrences.
 * The drawback of clearing the highlighting is that for small documents, there
 * is some flickering.
 */
static void
regex_search_handle_high_priority_region (GtkSourceSearchContext *search)
{
	GtkSourceRegion *region;
	GtkSourceRegionIter region_iter;

	region = gtk_source_region_intersect_region (search->priv->high_priority_region,
						     search->priv->scan_region);

	if (region == NULL)
	{
		return;
	}

	gtk_source_region_get_start_region_iter (region, &region_iter);

	while (!gtk_source_region_iter_is_end (&region_iter))
	{
		GtkTextIter subregion_start;
		GtkTextIter subregion_end;

		if (!gtk_source_region_iter_get_subregion (&region_iter,
							   &subregion_start,
							   &subregion_end))
		{
			break;
		}

		gtk_text_buffer_remove_tag (search->priv->buffer,
					    search->priv->found_tag,
					    &subregion_start,
					    &subregion_end);

		gtk_source_region_iter_next (&region_iter);
	}

	g_clear_object (&region);
}

/* Returns TRUE if the segment is finished, and FALSE on partial match. */
static gboolean
regex_search_scan_segment (GtkSourceSearchContext *search,
			   const GtkTextIter      *segment_start,
			   const GtkTextIter      *segment_end,
			   GtkTextIter            *stopped_at)
{
	GtkTextIter real_start;
	gint start_pos;
	gchar *subject;
	gssize subject_length;
	GRegexMatchFlags match_options;
	GMatchInfo *match_info;
	GtkTextIter iter;
	gint iter_byte_pos;
	gboolean segment_finished;
	GtkTextIter match_start;
	GtkTextIter match_end;

	g_assert (stopped_at != NULL);

	gtk_text_buffer_remove_tag (search->priv->buffer,
				    search->priv->found_tag,
				    segment_start,
				    segment_end);

	if (search->priv->regex == NULL ||
	    search->priv->regex_error != NULL)
	{
		*stopped_at = *segment_end;
		return TRUE;
	}

	regex_search_get_real_start (search,
				     segment_start,
				     &real_start,
				     &start_pos);

	DEBUG ({
	       g_print ("\n*** regex search - scan segment ***\n");
	       g_print ("start position in the subject (in bytes): %d\n", start_pos);
	});

	match_options = regex_search_get_match_options (&real_start, segment_end);

	if (match_options & G_REGEX_MATCH_NOTBOL)
	{
		DEBUG ({
		       g_print ("match notbol\n");
		});
	}

	if (match_options & G_REGEX_MATCH_NOTEOL)
	{
		DEBUG ({
		       g_print ("match noteol\n");
		});
	}

	if (match_options & G_REGEX_MATCH_PARTIAL_HARD)
	{
		DEBUG ({
		       g_print ("match partial hard\n");
		});
	}

	subject = gtk_text_iter_get_visible_text (&real_start, segment_end);
	subject_length = strlen (subject);

	DEBUG ({
	       gchar *subject_escaped = gtk_source_utils_escape_search_text (subject);
	       g_print ("subject (escaped): %s\n", subject_escaped);
	       g_free (subject_escaped);
	});

	g_regex_match_full (search->priv->regex,
			    subject,
			    subject_length,
			    start_pos,
			    match_options,
			    &match_info,
			    &search->priv->regex_error);

	iter = real_start;
	iter_byte_pos = 0;

	while (regex_search_fetch_match (match_info,
					 subject,
					 subject_length,
					 &iter,
					 &iter_byte_pos,
					 &match_start,
					 &match_end))
	{
		gtk_text_buffer_apply_tag (search->priv->buffer,
					   search->priv->found_tag,
					   &match_start,
					   &match_end);

		DEBUG ({
			 gchar *match_text = gtk_text_iter_get_visible_text (&match_start, &match_end);
			 gchar *match_escaped = gtk_source_utils_escape_search_text (match_text);
			 g_print ("match found (escaped): %s\n", match_escaped);
			 g_free (match_text);
			 g_free (match_escaped);
		});

		search->priv->occurrences_count++;

		g_match_info_next (match_info, &search->priv->regex_error);
	}

	if (search->priv->regex_error != NULL)
	{
		g_object_notify (G_OBJECT (search), "regex-error");
	}

	if (g_match_info_is_partial_match (match_info))
	{
		segment_finished = FALSE;

		if (gtk_text_iter_compare (segment_start, &iter) < 0)
		{
			*stopped_at = iter;
		}
		else
		{
			*stopped_at = *segment_start;
		}

		DEBUG ({
		       g_print ("partial match\n");
		});
	}
	else
	{
		*stopped_at = *segment_end;
		segment_finished = TRUE;
	}

	g_free (subject);
	g_match_info_free (match_info);

	return segment_finished;
}

static void
regex_search_scan_chunk (GtkSourceSearchContext *search,
			 const GtkTextIter      *chunk_start,
			 const GtkTextIter      *chunk_end)
{
	GtkTextIter segment_start = *chunk_start;

	while (gtk_text_iter_compare (&segment_start, chunk_end) < 0)
	{
		GtkTextIter segment_end;
		GtkTextIter stopped_at;
		gint nb_lines = 1;

		segment_end = segment_start;
		gtk_text_iter_forward_line (&segment_end);

		while (!regex_search_scan_segment (search,
						   &segment_start,
						   &segment_end,
						   &stopped_at))
		{
			/* TODO: performance improvement. On partial match, use
			 * a GString to grow the subject.
			 */

			segment_start = stopped_at;
			gtk_text_iter_forward_lines (&segment_end, nb_lines);
			nb_lines <<= 1;
		}

		segment_start = stopped_at;
	}

	gtk_source_region_subtract_subregion (search->priv->scan_region,
					      chunk_start,
					      &segment_start);

	if (search->priv->task_region != NULL)
	{
		gtk_source_region_subtract_subregion (search->priv->task_region,
						      chunk_start,
						      &segment_start);
	}
}

static void
regex_search_scan_next_chunk (GtkSourceSearchContext *search)
{
	GtkTextIter chunk_start;
	GtkTextIter chunk_end;

	if (gtk_source_region_is_empty (search->priv->scan_region))
	{
		return;
	}

	if (!gtk_source_region_get_bounds (search->priv->scan_region, &chunk_start, NULL))
	{
		return;
	}

	chunk_end = chunk_start;
	gtk_text_iter_forward_lines (&chunk_end, SCAN_BATCH_SIZE);

	regex_search_scan_chunk (search, &chunk_start, &chunk_end);
}

static gboolean
idle_scan_regex_search (GtkSourceSearchContext *search)
{
	if (search->priv->high_priority_region != NULL)
	{
		regex_search_handle_high_priority_region (search);
		g_clear_object (&search->priv->high_priority_region);
		return G_SOURCE_CONTINUE;
	}

	regex_search_scan_next_chunk (search);

	if (search->priv->task != NULL)
	{
		/* Always resume the task, even if the task region has not been
		 * fully scanned. The task region can be huge (the whole
		 * buffer), and an occurrence can be found earlier. Obviously it
		 * would be better to resume the task only if an occurrence has
		 * been found in the task region. But it would be a little more
		 * complicated to implement, for not a big performance
		 * improvement.
		 */
		resume_task (search);
		return G_SOURCE_CONTINUE;
	}

	if (gtk_source_region_is_empty (search->priv->scan_region))
	{
		search->priv->idle_scan_id = 0;

		g_object_notify (G_OBJECT (search), "occurrences-count");

		g_clear_object (&search->priv->scan_region);
		return G_SOURCE_REMOVE;
	}

	return G_SOURCE_CONTINUE;
}

static gboolean
idle_scan_cb (GtkSourceSearchContext *search)
{
	if (search->priv->buffer == NULL)
	{
		search->priv->idle_scan_id = 0;
		clear_search (search);
		return G_SOURCE_REMOVE;
	}

	return gtk_source_search_settings_get_regex_enabled (search->priv->settings) ?
	       idle_scan_regex_search (search) :
	       idle_scan_normal_search (search);
}

static void
install_idle_scan (GtkSourceSearchContext *search)
{
	if (search->priv->idle_scan_id == 0)
	{
		search->priv->idle_scan_id = g_idle_add ((GSourceFunc)idle_scan_cb, search);
	}
}

/* Returns TRUE when finished. */
static gboolean
smart_forward_search_step (GtkSourceSearchContext *search,
			   GtkTextIter            *start_at,
			   GtkTextIter            *match_start,
			   GtkTextIter            *match_end)
{
	GtkTextIter iter = *start_at;
	GtkTextIter limit;
	GtkTextIter region_start = *start_at;
	GtkSourceRegion *region = NULL;

	if (!gtk_text_iter_has_tag (&iter, search->priv->found_tag))
	{
		gtk_text_iter_forward_to_tag_toggle (&iter, search->priv->found_tag);
	}
	else if (!gtk_text_iter_starts_tag (&iter, search->priv->found_tag))
	{
		gtk_text_iter_backward_to_tag_toggle (&iter, search->priv->found_tag);
		region_start = iter;
	}

	limit = iter;
	gtk_text_iter_forward_to_tag_toggle (&limit, search->priv->found_tag);

	if (search->priv->scan_region != NULL)
	{
		region = gtk_source_region_intersect_subregion (search->priv->scan_region,
								&region_start,
								&limit);
	}

	if (gtk_source_region_is_empty (region))
	{
		g_clear_object (&region);

		while (basic_forward_search (search, &iter, match_start, match_end, &limit))
		{
			if (gtk_text_iter_compare (start_at, match_start) <= 0)
			{
				return TRUE;
			}

			iter = *match_end;
		}

		*start_at = limit;
		return FALSE;
	}

	/* Scan a chunk of the buffer, not the whole 'region'. An occurrence can
	 * be found before the 'region' is scanned entirely.
	 */
	if (gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		regex_search_scan_next_chunk (search);
	}
	else
	{
		scan_region_forward (search, region);
	}

	g_clear_object (&region);

	return FALSE;
}

/* Doesn't wrap around. */
static gboolean
smart_forward_search (GtkSourceSearchContext *search,
		      const GtkTextIter      *start_at,
		      GtkTextIter            *match_start,
		      GtkTextIter            *match_end)
{
	GtkTextIter iter = *start_at;
	const gchar *search_text = gtk_source_search_settings_get_search_text (search->priv->settings);

	g_return_val_if_fail (match_start != NULL, FALSE);
	g_return_val_if_fail (match_end != NULL, FALSE);

	if (search_text == NULL)
	{
		return FALSE;
	}

	while (!gtk_text_iter_is_end (&iter))
	{
		if (smart_forward_search_step (search, &iter, match_start, match_end))
		{
			return TRUE;
		}
	}

	return FALSE;
}

/* Returns TRUE when finished. */
static gboolean
smart_backward_search_step (GtkSourceSearchContext *search,
			    GtkTextIter            *start_at,
			    GtkTextIter            *match_start,
			    GtkTextIter            *match_end)
{
	GtkTextIter iter = *start_at;
	GtkTextIter limit;
	GtkTextIter region_end = *start_at;
	GtkSourceRegion *region = NULL;

	if (gtk_text_iter_starts_tag (&iter, search->priv->found_tag) ||
	    (!gtk_text_iter_has_tag (&iter, search->priv->found_tag) &&
	     !gtk_text_iter_ends_tag (&iter, search->priv->found_tag)))
	{
		gtk_text_iter_backward_to_tag_toggle (&iter, search->priv->found_tag);
	}
	else if (gtk_text_iter_has_tag (&iter, search->priv->found_tag))
	{
		gtk_text_iter_forward_to_tag_toggle (&iter, search->priv->found_tag);
		region_end = iter;
	}

	limit = iter;
	gtk_text_iter_backward_to_tag_toggle (&limit, search->priv->found_tag);

	if (search->priv->scan_region != NULL)
	{
		region = gtk_source_region_intersect_subregion (search->priv->scan_region,
								&limit,
								&region_end);
	}

	if (gtk_source_region_is_empty (region))
	{
		g_clear_object (&region);

		while (basic_backward_search (search, &iter, match_start, match_end, &limit))
		{
			if (gtk_text_iter_compare (match_end, start_at) <= 0)
			{
				return TRUE;
			}

			iter = *match_start;
		}

		*start_at = limit;
		return FALSE;
	}

	/* Scan a chunk of the buffer, not the whole 'region'. An occurrence can
	 * be found before the 'region' is scanned entirely.
	 */
	if (gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		regex_search_scan_next_chunk (search);
	}
	else
	{
		scan_region_forward (search, region);
	}

	g_clear_object (&region);

	return FALSE;
}

/* Doesn't wrap around. */
static gboolean
smart_backward_search (GtkSourceSearchContext *search,
		       const GtkTextIter      *start_at,
		       GtkTextIter            *match_start,
		       GtkTextIter            *match_end)
{
	GtkTextIter iter = *start_at;
	const gchar *search_text = gtk_source_search_settings_get_search_text (search->priv->settings);

	g_return_val_if_fail (match_start != NULL, FALSE);
	g_return_val_if_fail (match_end != NULL, FALSE);

	if (search_text == NULL)
	{
		return FALSE;
	}

	while (!gtk_text_iter_is_start (&iter))
	{
		if (smart_backward_search_step (search, &iter, match_start, match_end))
		{
			return TRUE;
		}
	}

	return FALSE;
}

static void
add_subregion_to_scan (GtkSourceSearchContext *search,
		       const GtkTextIter      *subregion_start,
		       const GtkTextIter      *subregion_end)
{
	GtkTextIter start = *subregion_start;
	GtkTextIter end = *subregion_end;

	if (search->priv->scan_region == NULL)
	{
		search->priv->scan_region = gtk_source_region_new (search->priv->buffer);
	}

	DEBUG ({
		g_print ("add_subregion_to_scan(): region to scan, before:\n");
		print_region (search->priv->scan_region);
	});

	gtk_source_region_add_subregion (search->priv->scan_region, &start, &end);

	DEBUG ({
		g_print ("add_subregion_to_scan(): region to scan, after:\n");
		print_region (search->priv->scan_region);
	});

	install_idle_scan (search);
}

static void
update_regex (GtkSourceSearchContext *search)
{
	gboolean regex_error_changed = FALSE;
	const gchar *search_text = gtk_source_search_settings_get_search_text (search->priv->settings);

	if (search->priv->regex != NULL)
	{
		g_regex_unref (search->priv->regex);
		search->priv->regex = NULL;
	}

	if (search->priv->regex_error != NULL)
	{
		g_clear_error (&search->priv->regex_error);
		regex_error_changed = TRUE;
	}

	if (search_text != NULL &&
	    gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		GRegexCompileFlags compile_flags = G_REGEX_OPTIMIZE | G_REGEX_MULTILINE;
		gchar *pattern = (gchar *)search_text;

		search->priv->text_nb_lines = 0;

		if (!gtk_source_search_settings_get_case_sensitive (search->priv->settings))
		{
			compile_flags |= G_REGEX_CASELESS;
		}

		if (gtk_source_search_settings_get_at_word_boundaries (search->priv->settings))
		{
			pattern = g_strdup_printf ("\\b%s\\b", search_text);
		}

		search->priv->regex = g_regex_new (pattern,
						   compile_flags,
						   G_REGEX_MATCH_NOTEMPTY,
						   &search->priv->regex_error);

		if (search->priv->regex_error != NULL)
		{
			regex_error_changed = TRUE;
		}

		if (gtk_source_search_settings_get_at_word_boundaries (search->priv->settings))
		{
			g_free (pattern);
		}
	}

	if (regex_error_changed)
	{
		g_object_notify (G_OBJECT (search), "regex-error");
	}
}

static void
update (GtkSourceSearchContext *search)
{
	GtkTextIter start;
	GtkTextIter end;
	GtkSourceBufferInternal *buffer_internal;

	if (search->priv->buffer == NULL)
	{
		return;
	}

	clear_search (search);
	update_regex (search);

	search->priv->scan_region = gtk_source_region_new (search->priv->buffer);

	gtk_text_buffer_get_bounds (search->priv->buffer, &start, &end);
	add_subregion_to_scan (search, &start, &end);

	/* Notify the GtkSourceViews that the search is starting, so that
	 * _gtk_source_search_context_update_highlight() can be called for the
	 * visible regions of the buffer.
	 */
	buffer_internal = _gtk_source_buffer_internal_get_from_buffer (GTK_SOURCE_BUFFER (search->priv->buffer));
	_gtk_source_buffer_internal_emit_search_start (buffer_internal, search);
}

static void
insert_text_before_cb (GtkSourceSearchContext *search,
		       GtkTextIter            *location,
		       gchar                  *text,
		       gint                    length)
{
	const gchar *search_text = gtk_source_search_settings_get_search_text (search->priv->settings);

	clear_task (search);

	if (search_text != NULL &&
	    !gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		GtkTextIter start = *location;
		GtkTextIter end = *location;

		remove_occurrences_in_range (search, &start, &end);
		add_subregion_to_scan (search, &start, &end);
	}
}

static void
insert_text_after_cb (GtkSourceSearchContext *search,
		      GtkTextIter            *location,
		      gchar                  *text,
		      gint                    length)
{
	if (gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		update (search);
	}
	else
	{
		GtkTextIter start;
		GtkTextIter end;

		start = end = *location;

		gtk_text_iter_backward_chars (&start,
					      g_utf8_strlen (text, length));

		add_subregion_to_scan (search, &start, &end);
	}
}

static void
delete_range_before_cb (GtkSourceSearchContext *search,
			GtkTextIter            *delete_start,
			GtkTextIter            *delete_end)
{
	GtkTextIter start_buffer;
	GtkTextIter end_buffer;
	const gchar *search_text = gtk_source_search_settings_get_search_text (search->priv->settings);

	clear_task (search);

	if (gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		return;
	}

	gtk_text_buffer_get_bounds (search->priv->buffer, &start_buffer, &end_buffer);

	if (gtk_text_iter_equal (delete_start, &start_buffer) &&
	    gtk_text_iter_equal (delete_end, &end_buffer))
	{
		/* Special case when removing all the text. */
		search->priv->occurrences_count = 0;
		return;
	}

	if (search_text != NULL)
	{
		GtkTextIter start = *delete_start;
		GtkTextIter end = *delete_end;

		gtk_text_iter_backward_lines (&start, search->priv->text_nb_lines);
		gtk_text_iter_forward_lines (&end, search->priv->text_nb_lines);

		remove_occurrences_in_range (search, &start, &end);
		add_subregion_to_scan (search, &start, &end);
	}
}

static void
delete_range_after_cb (GtkSourceSearchContext *search,
		       GtkTextIter            *start,
		       GtkTextIter            *end)
{
	if (gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		update (search);
	}
	else
	{
		add_subregion_to_scan (search, start, end);
	}
}

static void
set_buffer (GtkSourceSearchContext *search,
	    GtkSourceBuffer        *buffer)
{
	g_assert (search->priv->buffer == NULL);
	g_assert (search->priv->tag_table == NULL);

	search->priv->buffer = GTK_TEXT_BUFFER (buffer);

	g_object_add_weak_pointer (G_OBJECT (buffer),
				   (gpointer *)&search->priv->buffer);

	search->priv->tag_table = gtk_text_buffer_get_tag_table (search->priv->buffer);
	g_object_ref (search->priv->tag_table);

	g_signal_connect_object (buffer,
				 "insert-text",
				 G_CALLBACK (insert_text_before_cb),
				 search,
				 G_CONNECT_SWAPPED);

	g_signal_connect_object (buffer,
				 "insert-text",
				 G_CALLBACK (insert_text_after_cb),
				 search,
				 G_CONNECT_AFTER | G_CONNECT_SWAPPED);

	g_signal_connect_object (buffer,
				 "delete-range",
				 G_CALLBACK (delete_range_before_cb),
				 search,
				 G_CONNECT_SWAPPED);

	g_signal_connect_object (buffer,
				 "delete-range",
				 G_CALLBACK (delete_range_after_cb),
				 search,
				 G_CONNECT_AFTER | G_CONNECT_SWAPPED);

	search->priv->found_tag = gtk_text_buffer_create_tag (search->priv->buffer, NULL, NULL);
	g_object_ref (search->priv->found_tag);

	sync_found_tag (search);

	g_signal_connect_object (search->priv->buffer,
				 "notify::style-scheme",
				 G_CALLBACK (sync_found_tag),
				 search,
				 G_CONNECT_SWAPPED);

	_gtk_source_buffer_add_search_context (buffer, search);
}

static gint
compute_number_of_lines (const gchar *text)
{
	const gchar *p;
	gint len;
	gint nb_of_lines = 1;

	if (text == NULL)
	{
		return 0;
	}

	len = strlen (text);
	p = text;

	while (len > 0)
	{
		gint delimiter;
		gint next_paragraph;

		pango_find_paragraph_boundary (p, len, &delimiter, &next_paragraph);

		if (delimiter == next_paragraph)
		{
			/* not found */
			break;
		}

		p += next_paragraph;
		len -= next_paragraph;
		nb_of_lines++;
	}

	return nb_of_lines;
}

static void
search_text_updated (GtkSourceSearchContext *search)
{
	if (gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		search->priv->text_nb_lines = 0;
	}
	else
	{
		const gchar *text = gtk_source_search_settings_get_search_text (search->priv->settings);
		search->priv->text_nb_lines = compute_number_of_lines (text);
	}
}

static void
settings_notify_cb (GtkSourceSearchContext  *search,
		    GParamSpec              *pspec,
		    GtkSourceSearchSettings *settings)
{
	const gchar *property = g_param_spec_get_name (pspec);

	if (g_str_equal (property, "search-text"))
	{
		search_text_updated (search);
	}

	update (search);
}

static void
gtk_source_search_context_dispose (GObject *object)
{
	GtkSourceSearchContext *search = GTK_SOURCE_SEARCH_CONTEXT (object);

	clear_search (search);

	if (search->priv->found_tag != NULL &&
	    search->priv->tag_table != NULL)
	{
		gtk_text_tag_table_remove (search->priv->tag_table,
					   search->priv->found_tag);

		g_clear_object (&search->priv->found_tag);
		g_clear_object (&search->priv->tag_table);
	}

	if (search->priv->buffer != NULL)
	{
		g_object_remove_weak_pointer (G_OBJECT (search->priv->buffer),
					      (gpointer *)&search->priv->buffer);

		search->priv->buffer = NULL;
	}

	g_clear_object (&search->priv->settings);

	G_OBJECT_CLASS (gtk_source_search_context_parent_class)->dispose (object);
}

static void
gtk_source_search_context_finalize (GObject *object)
{
	GtkSourceSearchContext *search = GTK_SOURCE_SEARCH_CONTEXT (object);

	if (search->priv->regex != NULL)
	{
		g_regex_unref (search->priv->regex);
	}

	g_clear_error (&search->priv->regex_error);

	G_OBJECT_CLASS (gtk_source_search_context_parent_class)->finalize (object);
}

static void
gtk_source_search_context_get_property (GObject    *object,
					guint       prop_id,
					GValue     *value,
					GParamSpec *pspec)
{
	GtkSourceSearchContext *search;

	g_return_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (object));

	search = GTK_SOURCE_SEARCH_CONTEXT (object);

	switch (prop_id)
	{
		case PROP_BUFFER:
			g_value_set_object (value, search->priv->buffer);
			break;

		case PROP_SETTINGS:
			g_value_set_object (value, search->priv->settings);
			break;

		case PROP_HIGHLIGHT:
			g_value_set_boolean (value, search->priv->highlight);
			break;

		case PROP_MATCH_STYLE:
			g_value_set_object (value, search->priv->match_style);
			break;

		case PROP_OCCURRENCES_COUNT:
			g_value_set_int (value, gtk_source_search_context_get_occurrences_count (search));
			break;

		case PROP_REGEX_ERROR:
			g_value_set_pointer (value, gtk_source_search_context_get_regex_error (search));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_search_context_set_property (GObject      *object,
					guint         prop_id,
					const GValue *value,
					GParamSpec   *pspec)
{
	GtkSourceSearchContext *search;

	g_return_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (object));

	search = GTK_SOURCE_SEARCH_CONTEXT (object);

	switch (prop_id)
	{
		case PROP_BUFFER:
			set_buffer (search, g_value_get_object (value));
			break;

		case PROP_SETTINGS:
			G_GNUC_BEGIN_IGNORE_DEPRECATIONS;
			gtk_source_search_context_set_settings (search, g_value_get_object (value));
			G_GNUC_END_IGNORE_DEPRECATIONS;
			break;

		case PROP_HIGHLIGHT:
			gtk_source_search_context_set_highlight (search, g_value_get_boolean (value));
			break;

		case PROP_MATCH_STYLE:
			gtk_source_search_context_set_match_style (search, g_value_get_object (value));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_search_context_class_init (GtkSourceSearchContextClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->dispose = gtk_source_search_context_dispose;
	object_class->finalize = gtk_source_search_context_finalize;
	object_class->get_property = gtk_source_search_context_get_property;
	object_class->set_property = gtk_source_search_context_set_property;

	/**
	 * GtkSourceSearchContext:buffer:
	 *
	 * The #GtkSourceBuffer associated to the search context.
	 *
	 * Since: 3.10
	 */
	g_object_class_install_property (object_class,
					 PROP_BUFFER,
					 g_param_spec_object ("buffer",
							      "Buffer",
							      "The associated GtkSourceBuffer",
							      GTK_SOURCE_TYPE_BUFFER,
							      G_PARAM_READWRITE |
							      G_PARAM_CONSTRUCT_ONLY |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceSearchContext:settings:
	 *
	 * The #GtkSourceSearchSettings associated to the search context.
	 *
	 * Since: 3.10
	 */
	g_object_class_install_property (object_class,
					 PROP_SETTINGS,
					 g_param_spec_object ("settings",
							      "Settings",
							      "The associated GtkSourceSearchSettings",
							      GTK_SOURCE_TYPE_SEARCH_SETTINGS,
							      G_PARAM_READWRITE |
							      G_PARAM_CONSTRUCT |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceSearchContext:highlight:
	 *
	 * Highlight the search occurrences.
	 *
	 * Since: 3.10
	 */
	g_object_class_install_property (object_class,
					 PROP_HIGHLIGHT,
					 g_param_spec_boolean ("highlight",
							       "Highlight",
							       "Highlight search occurrences",
							       TRUE,
							       G_PARAM_READWRITE |
							       G_PARAM_CONSTRUCT |
							       G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceSearchContext:match-style:
	 *
	 * A #GtkSourceStyle, or %NULL for theme's scheme default style.
	 *
	 * Since: 3.16
	 */
	g_object_class_install_property (object_class,
					 PROP_MATCH_STYLE,
					 g_param_spec_object ("match-style",
							      "Match style",
							      "The text style for matches",
							      GTK_SOURCE_TYPE_STYLE,
							      G_PARAM_READWRITE |
							      G_PARAM_CONSTRUCT |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceSearchContext:occurrences-count:
	 *
	 * The total number of search occurrences. If the search is disabled,
	 * the value is 0. If the buffer is not already fully scanned, the value
	 * is -1.
	 *
	 * Since: 3.10
	 */
	g_object_class_install_property (object_class,
					 PROP_OCCURRENCES_COUNT,
					 g_param_spec_int ("occurrences-count",
							   "Occurrences count",
							   "Total number of search occurrences",
							   -1,
							   G_MAXINT,
							   0,
							   G_PARAM_READABLE |
							   G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceSearchContext:regex-error:
	 *
	 * If the regex search pattern doesn't follow all the rules, this
	 * property will be set. If the pattern is valid, the value is %NULL.
	 *
	 * Free with g_error_free().
	 *
	 * Since: 3.10
	 */
	g_object_class_install_property (object_class,
					 PROP_REGEX_ERROR,
					 g_param_spec_pointer ("regex-error",
							       "Regex error",
							       "Regular expression error",
							       G_PARAM_READABLE |
							       G_PARAM_STATIC_STRINGS));
}

static void
gtk_source_search_context_init (GtkSourceSearchContext *search)
{
	search->priv = gtk_source_search_context_get_instance_private (search);
}

/**
 * gtk_source_search_context_new:
 * @buffer: a #GtkSourceBuffer.
 * @settings: (nullable): a #GtkSourceSearchSettings, or %NULL.
 *
 * Creates a new search context, associated with @buffer, and customized with
 * @settings. If @settings is %NULL, a new #GtkSourceSearchSettings object will
 * be created, that you can retrieve with
 * gtk_source_search_context_get_settings().
 *
 * Returns: a new search context.
 * Since: 3.10
 */
GtkSourceSearchContext *
gtk_source_search_context_new (GtkSourceBuffer         *buffer,
			       GtkSourceSearchSettings *settings)
{
	g_return_val_if_fail (GTK_SOURCE_IS_BUFFER (buffer), NULL);
	g_return_val_if_fail (settings == NULL || GTK_SOURCE_IS_SEARCH_SETTINGS (settings), NULL);

	return g_object_new (GTK_SOURCE_TYPE_SEARCH_CONTEXT,
			     "buffer", buffer,
			     "settings", settings,
			     NULL);
}

/**
 * gtk_source_search_context_get_buffer:
 * @search: a #GtkSourceSearchContext.
 *
 * Returns: (transfer none): the associated buffer.
 * Since: 3.10
 */
GtkSourceBuffer *
gtk_source_search_context_get_buffer (GtkSourceSearchContext *search)
{
	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), NULL);

	return GTK_SOURCE_BUFFER (search->priv->buffer);
}

/**
 * gtk_source_search_context_get_settings:
 * @search: a #GtkSourceSearchContext.
 *
 * Returns: (transfer none): the search settings.
 * Since: 3.10
 */
GtkSourceSearchSettings *
gtk_source_search_context_get_settings (GtkSourceSearchContext *search)
{
	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), NULL);

	return search->priv->settings;
}

/**
 * gtk_source_search_context_set_settings:
 * @search: a #GtkSourceSearchContext.
 * @settings: (nullable): the new #GtkSourceSearchSettings, or %NULL.
 *
 * Associate a #GtkSourceSearchSettings with the search context. If @settings is
 * %NULL, a new one will be created.
 *
 * The search context holds a reference to @settings.
 *
 * Since: 3.10
 * Deprecated: 3.24: The #GtkSourceSearchContext:settings property will become a
 * construct-only property in a future version. Create a new
 * #GtkSourceSearchContext instead, or change the #GtkSourceSearchSettings
 * properties. When the #GtkSourceSearchContext:settings property will become
 * construct-only, it will be possible to simplify some code that needed to
 * listen to the notify::settings signal.
 */
void
gtk_source_search_context_set_settings (GtkSourceSearchContext  *search,
					GtkSourceSearchSettings *settings)
{
	g_return_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search));
	g_return_if_fail (settings == NULL || GTK_SOURCE_IS_SEARCH_SETTINGS (settings));

	if (search->priv->settings != NULL)
	{
		g_warning ("%s() is deprecated, the GtkSourceSearchContext:settings property "
			   "will become a construct-only property in a future version.",
			   G_STRFUNC);

		g_signal_handlers_disconnect_by_func (search->priv->settings,
						      settings_notify_cb,
						      search);

		g_object_unref (search->priv->settings);
	}

	if (settings != NULL)
	{
		search->priv->settings = g_object_ref (settings);
	}
	else
	{
		search->priv->settings = gtk_source_search_settings_new ();
	}

	g_signal_connect_object (search->priv->settings,
				 "notify",
				 G_CALLBACK (settings_notify_cb),
				 search,
				 G_CONNECT_SWAPPED);

	search_text_updated (search);
	update (search);

	g_object_notify (G_OBJECT (search), "settings");
}

/**
 * gtk_source_search_context_get_highlight:
 * @search: a #GtkSourceSearchContext.
 *
 * Returns: whether to highlight the search occurrences.
 * Since: 3.10
 */
gboolean
gtk_source_search_context_get_highlight (GtkSourceSearchContext *search)
{
	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), FALSE);

	return search->priv->highlight;
}

/**
 * gtk_source_search_context_set_highlight:
 * @search: a #GtkSourceSearchContext.
 * @highlight: the setting.
 *
 * Enables or disables the search occurrences highlighting.
 *
 * Since: 3.10
 */
void
gtk_source_search_context_set_highlight (GtkSourceSearchContext *search,
					 gboolean                highlight)
{
	g_return_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search));

	highlight = highlight != FALSE;

	if (search->priv->highlight != highlight)
	{
		search->priv->highlight = highlight;
		sync_found_tag (search);

		g_object_notify (G_OBJECT (search), "highlight");
	}
}

/**
 * gtk_source_search_context_get_match_style:
 * @search: a #GtkSourceSearchContext.
 *
 * Returns: (transfer none): the #GtkSourceStyle to apply on search matches.
 *
 * Since: 3.16
 */
GtkSourceStyle *
gtk_source_search_context_get_match_style (GtkSourceSearchContext *search)
{
	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), NULL);

	return search->priv->match_style;
}

/**
 * gtk_source_search_context_set_match_style:
 * @search: a #GtkSourceSearchContext.
 * @match_style: (nullable): a #GtkSourceStyle, or %NULL.
 *
 * Set the style to apply on search matches. If @match_style is %NULL, default
 * theme's scheme 'match-style' will be used.
 * To enable or disable the search highlighting, use
 * gtk_source_search_context_set_highlight().
 *
 * Since: 3.16
 */
void
gtk_source_search_context_set_match_style (GtkSourceSearchContext *search,
					   GtkSourceStyle         *match_style)
{
	g_return_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search));
	g_return_if_fail (match_style == NULL || GTK_SOURCE_IS_STYLE (match_style));

	if (search->priv->match_style == match_style)
	{
		return;
	}

	if (search->priv->match_style != NULL)
	{
		g_object_unref (search->priv->match_style);
	}

	search->priv->match_style = match_style;

	if (match_style != NULL)
	{
		g_object_ref (match_style);
	}

	g_object_notify (G_OBJECT (search), "match-style");
}

/**
 * gtk_source_search_context_get_regex_error:
 * @search: a #GtkSourceSearchContext.
 *
 * Regular expression patterns must follow certain rules. If
 * #GtkSourceSearchSettings:search-text breaks a rule, the error can be retrieved
 * with this function. The error domain is #G_REGEX_ERROR.
 *
 * Free the return value with g_error_free().
 *
 * Returns: (nullable): the #GError, or %NULL if the pattern is valid.
 * Since: 3.10
 */
GError *
gtk_source_search_context_get_regex_error (GtkSourceSearchContext *search)
{
	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), NULL);

	if (search->priv->regex_error == NULL)
	{
		return NULL;
	}

	return g_error_copy (search->priv->regex_error);
}

/**
 * gtk_source_search_context_get_occurrences_count:
 * @search: a #GtkSourceSearchContext.
 *
 * Gets the total number of search occurrences. If the buffer is not already
 * fully scanned, the total number of occurrences is unknown, and -1 is
 * returned.
 *
 * Returns: the total number of search occurrences, or -1 if unknown.
 * Since: 3.10
 */
gint
gtk_source_search_context_get_occurrences_count (GtkSourceSearchContext *search)
{
	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), -1);

	if (!gtk_source_region_is_empty (search->priv->scan_region))
	{
		return -1;
	}

	return search->priv->occurrences_count;
}

/**
 * gtk_source_search_context_get_occurrence_position:
 * @search: a #GtkSourceSearchContext.
 * @match_start: the start of the occurrence.
 * @match_end: the end of the occurrence.
 *
 * Gets the position of a search occurrence. If the buffer is not already fully
 * scanned, the position may be unknown, and -1 is returned. If 0 is returned,
 * it means that this part of the buffer has already been scanned, and that
 * @match_start and @match_end don't delimit an occurrence.
 *
 * Returns: the position of the search occurrence. The first occurrence has the
 * position 1 (not 0). Returns 0 if @match_start and @match_end don't delimit
 * an occurrence. Returns -1 if the position is not yet known.
 *
 * Since: 3.10
 */
gint
gtk_source_search_context_get_occurrence_position (GtkSourceSearchContext *search,
						   const GtkTextIter      *match_start,
						   const GtkTextIter      *match_end)
{
	GtkTextIter m_start;
	GtkTextIter m_end;
	GtkTextIter iter;
	gboolean found;
	gint position = 0;
	GtkSourceRegion *region;
	gboolean empty;

	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), -1);
	g_return_val_if_fail (match_start != NULL, -1);
	g_return_val_if_fail (match_end != NULL, -1);

	if (search->priv->buffer == NULL)
	{
		return -1;
	}

	/* Verify that the [match_start; match_end] region has been scanned. */

	if (search->priv->scan_region != NULL)
	{
		region = gtk_source_region_intersect_subregion (search->priv->scan_region,
								match_start,
								match_end);

		empty = gtk_source_region_is_empty (region);

		g_clear_object (&region);

		if (!empty)
		{
			return -1;
		}
	}

	/* Verify that the occurrence is correct. */

	found = smart_forward_search_without_scanning (search,
						       match_start,
						       &m_start,
						       &m_end,
						       match_end);

	if (!found ||
	    !gtk_text_iter_equal (match_start, &m_start) ||
	    !gtk_text_iter_equal (match_end, &m_end))
	{
		return 0;
	}

	/* Verify that the scan region is empty between the start of the buffer
	 * and the end of the occurrence.
	 */

	gtk_text_buffer_get_start_iter (search->priv->buffer, &iter);

	if (search->priv->scan_region != NULL)
	{
		region = gtk_source_region_intersect_subregion (search->priv->scan_region,
								&iter,
								match_end);

		empty = gtk_source_region_is_empty (region);

		g_clear_object (&region);

		if (!empty)
		{
			return -1;
		}
	}

	/* Everything is fine, count the number of previous occurrences. */

	while (smart_forward_search_without_scanning (search, &iter, &m_start, &m_end, match_start))
	{
		position++;
		iter = m_end;
	}

	return position + 1;
}

/**
 * gtk_source_search_context_forward:
 * @search: a #GtkSourceSearchContext.
 * @iter: start of search.
 * @match_start: (out) (optional): return location for start of match, or %NULL.
 * @match_end: (out) (optional): return location for end of match, or %NULL.
 *
 * Synchronous forward search. It is recommended to use the asynchronous
 * functions instead, to not block the user interface. However, if you are sure
 * that the @buffer is small, this function is more convenient to use.
 *
 * Returns: whether a match was found.
 * Since: 3.10
 * Deprecated: 3.22: Use gtk_source_search_context_forward2() instead.
 */
gboolean
gtk_source_search_context_forward (GtkSourceSearchContext *search,
				   const GtkTextIter      *iter,
				   GtkTextIter            *match_start,
				   GtkTextIter            *match_end)
{
	return gtk_source_search_context_forward2 (search,
						   iter,
						   match_start,
						   match_end,
						   NULL);
}

/**
 * gtk_source_search_context_forward2:
 * @search: a #GtkSourceSearchContext.
 * @iter: start of search.
 * @match_start: (out) (optional): return location for start of match, or %NULL.
 * @match_end: (out) (optional): return location for end of match, or %NULL.
 * @has_wrapped_around: (out) (optional): return location to know whether the
 *   search has wrapped around, or %NULL.
 *
 * Synchronous forward search. It is recommended to use the asynchronous
 * functions instead, to not block the user interface. However, if you are sure
 * that the @buffer is small, this function is more convenient to use.
 *
 * The difference with gtk_source_search_context_forward() is that the
 * @has_wrapped_around out parameter has been added for convenience.
 *
 * If the #GtkSourceSearchSettings:wrap-around property is %FALSE, this function
 * doesn't try to wrap around.
 *
 * The @has_wrapped_around out parameter is set independently of whether a match
 * is found. So if this function returns %FALSE, @has_wrapped_around will have
 * the same value as the #GtkSourceSearchSettings:wrap-around property.
 *
 * Returns: whether a match was found.
 * Since: 3.22
 */
gboolean
gtk_source_search_context_forward2 (GtkSourceSearchContext *search,
				    const GtkTextIter      *iter,
				    GtkTextIter            *match_start,
				    GtkTextIter            *match_end,
				    gboolean               *has_wrapped_around)
{
	GtkTextIter m_start;
	GtkTextIter m_end;
	gboolean found;

	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);

	if (has_wrapped_around != NULL)
	{
		*has_wrapped_around = FALSE;
	}

	if (search->priv->buffer == NULL)
	{
		return FALSE;
	}

	found = smart_forward_search (search, iter, &m_start, &m_end);

	if (!found && gtk_source_search_settings_get_wrap_around (search->priv->settings))
	{
		GtkTextIter start_iter;
		gtk_text_buffer_get_start_iter (search->priv->buffer, &start_iter);

		found = smart_forward_search (search, &start_iter, &m_start, &m_end);

		if (has_wrapped_around != NULL)
		{
			*has_wrapped_around = TRUE;
		}
	}

	if (found && match_start != NULL)
	{
		*match_start = m_start;
	}

	if (found && match_end != NULL)
	{
		*match_end = m_end;
	}

	return found;
}

/**
 * gtk_source_search_context_forward_async:
 * @search: a #GtkSourceSearchContext.
 * @iter: start of search.
 * @cancellable: (nullable): a #GCancellable, or %NULL.
 * @callback: a #GAsyncReadyCallback to call when the operation is finished.
 * @user_data: the data to pass to the @callback function.
 *
 * The asynchronous version of gtk_source_search_context_forward2().
 *
 * See the documentation of gtk_source_search_context_forward2() for more
 * details.
 *
 * See the #GAsyncResult documentation to know how to use this function.
 *
 * If the operation is cancelled, the @callback will only be called if
 * @cancellable was not %NULL. gtk_source_search_context_forward_async() takes
 * ownership of @cancellable, so you can unref it after calling this function.
 *
 * Since: 3.10
 */
void
gtk_source_search_context_forward_async (GtkSourceSearchContext *search,
					 const GtkTextIter      *iter,
					 GCancellable           *cancellable,
					 GAsyncReadyCallback     callback,
					 gpointer                user_data)
{
	g_return_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search));
	g_return_if_fail (iter != NULL);

	if (search->priv->buffer == NULL)
	{
		return;
	}

	clear_task (search);
	search->priv->task = g_task_new (search, cancellable, callback, user_data);

	smart_forward_search_async (search, iter, FALSE);
}

/**
 * gtk_source_search_context_forward_finish:
 * @search: a #GtkSourceSearchContext.
 * @result: a #GAsyncResult.
 * @match_start: (out) (optional): return location for start of match, or %NULL.
 * @match_end: (out) (optional): return location for end of match, or %NULL.
 * @error: a #GError, or %NULL.
 *
 * Finishes a forward search started with
 * gtk_source_search_context_forward_async().
 *
 * Returns: whether a match was found.
 * Since: 3.10
 * Deprecated: 3.22: Use gtk_source_search_context_forward_finish2() instead.
 */
gboolean
gtk_source_search_context_forward_finish (GtkSourceSearchContext  *search,
					  GAsyncResult            *result,
					  GtkTextIter             *match_start,
					  GtkTextIter             *match_end,
					  GError                 **error)
{
	return gtk_source_search_context_forward_finish2 (search,
							  result,
							  match_start,
							  match_end,
							  NULL,
							  error);
}

/**
 * gtk_source_search_context_forward_finish2:
 * @search: a #GtkSourceSearchContext.
 * @result: a #GAsyncResult.
 * @match_start: (out) (optional): return location for start of match, or %NULL.
 * @match_end: (out) (optional): return location for end of match, or %NULL.
 * @has_wrapped_around: (out) (optional): return location to know whether the
 *   search has wrapped around, or %NULL.
 * @error: a #GError, or %NULL.
 *
 * Finishes a forward search started with
 * gtk_source_search_context_forward_async().
 *
 * See the documentation of gtk_source_search_context_forward2() for more
 * details.
 *
 * Returns: whether a match was found.
 * Since: 3.22
 */
gboolean
gtk_source_search_context_forward_finish2 (GtkSourceSearchContext  *search,
					   GAsyncResult            *result,
					   GtkTextIter             *match_start,
					   GtkTextIter             *match_end,
					   gboolean                *has_wrapped_around,
					   GError                 **error)
{
	ForwardBackwardData *data;
	gboolean found;

	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), FALSE);

	if (has_wrapped_around != NULL)
	{
		*has_wrapped_around = FALSE;
	}

	if (search->priv->buffer == NULL)
	{
		return FALSE;
	}

	g_return_val_if_fail (g_task_is_valid (result, search), FALSE);

	data = g_task_propagate_pointer (G_TASK (result), error);

	if (data == NULL)
	{
		return FALSE;
	}

	found = data->found;

	if (found)
	{
		if (match_start != NULL)
		{
			*match_start = data->match_start;
		}

		if (match_end != NULL)
		{
			*match_end = data->match_end;
		}
	}

	if (has_wrapped_around != NULL)
	{
		*has_wrapped_around = data->wrapped_around;
	}

	forward_backward_data_free (data);
	return found;
}

/**
 * gtk_source_search_context_backward:
 * @search: a #GtkSourceSearchContext.
 * @iter: start of search.
 * @match_start: (out) (optional): return location for start of match, or %NULL.
 * @match_end: (out) (optional): return location for end of match, or %NULL.
 *
 * Synchronous backward search. It is recommended to use the asynchronous
 * functions instead, to not block the user interface. However, if you are sure
 * that the @buffer is small, this function is more convenient to use.
 *
 * Returns: whether a match was found.
 * Since: 3.10
 * Deprecated: 3.22: Use gtk_source_search_context_backward2() instead.
 */
gboolean
gtk_source_search_context_backward (GtkSourceSearchContext *search,
				    const GtkTextIter      *iter,
				    GtkTextIter            *match_start,
				    GtkTextIter            *match_end)
{
	return gtk_source_search_context_backward2 (search,
						    iter,
						    match_start,
						    match_end,
						    NULL);
}

/**
 * gtk_source_search_context_backward2:
 * @search: a #GtkSourceSearchContext.
 * @iter: start of search.
 * @match_start: (out) (optional): return location for start of match, or %NULL.
 * @match_end: (out) (optional): return location for end of match, or %NULL.
 * @has_wrapped_around: (out) (optional): return location to know whether the
 *   search has wrapped around, or %NULL.
 *
 * Synchronous backward search. It is recommended to use the asynchronous
 * functions instead, to not block the user interface. However, if you are sure
 * that the @buffer is small, this function is more convenient to use.
 *
 * The difference with gtk_source_search_context_backward() is that the
 * @has_wrapped_around out parameter has been added for convenience.
 *
 * If the #GtkSourceSearchSettings:wrap-around property is %FALSE, this function
 * doesn't try to wrap around.
 *
 * The @has_wrapped_around out parameter is set independently of whether a match
 * is found. So if this function returns %FALSE, @has_wrapped_around will have
 * the same value as the #GtkSourceSearchSettings:wrap-around property.
 *
 * Returns: whether a match was found.
 * Since: 3.22
 */
gboolean
gtk_source_search_context_backward2 (GtkSourceSearchContext *search,
				     const GtkTextIter      *iter,
				     GtkTextIter            *match_start,
				     GtkTextIter            *match_end,
				     gboolean               *has_wrapped_around)
{
	GtkTextIter m_start;
	GtkTextIter m_end;
	gboolean found;

	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);

	if (has_wrapped_around != NULL)
	{
		*has_wrapped_around = FALSE;
	}

	if (search->priv->buffer == NULL)
	{
		return FALSE;
	}

	found = smart_backward_search (search, iter, &m_start, &m_end);

	if (!found && gtk_source_search_settings_get_wrap_around (search->priv->settings))
	{
		GtkTextIter end_iter;

		gtk_text_buffer_get_end_iter (search->priv->buffer, &end_iter);

		found = smart_backward_search (search, &end_iter, &m_start, &m_end);

		if (has_wrapped_around != NULL)
		{
			*has_wrapped_around = TRUE;
		}
	}

	if (found && match_start != NULL)
	{
		*match_start = m_start;
	}

	if (found && match_end != NULL)
	{
		*match_end = m_end;
	}

	return found;
}

/**
 * gtk_source_search_context_backward_async:
 * @search: a #GtkSourceSearchContext.
 * @iter: start of search.
 * @cancellable: (nullable): a #GCancellable, or %NULL.
 * @callback: a #GAsyncReadyCallback to call when the operation is finished.
 * @user_data: the data to pass to the @callback function.
 *
 * The asynchronous version of gtk_source_search_context_backward2().
 *
 * See the documentation of gtk_source_search_context_backward2() for more
 * details.
 *
 * See the #GAsyncResult documentation to know how to use this function.
 *
 * If the operation is cancelled, the @callback will only be called if
 * @cancellable was not %NULL. gtk_source_search_context_backward_async() takes
 * ownership of @cancellable, so you can unref it after calling this function.
 *
 * Since: 3.10
 */
void
gtk_source_search_context_backward_async (GtkSourceSearchContext *search,
					  const GtkTextIter      *iter,
					  GCancellable           *cancellable,
					  GAsyncReadyCallback     callback,
					  gpointer                user_data)
{
	g_return_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search));
	g_return_if_fail (iter != NULL);

	if (search->priv->buffer == NULL)
	{
		return;
	}

	clear_task (search);
	search->priv->task = g_task_new (search, cancellable, callback, user_data);

	smart_backward_search_async (search, iter, FALSE);
}

/**
 * gtk_source_search_context_backward_finish:
 * @search: a #GtkSourceSearchContext.
 * @result: a #GAsyncResult.
 * @match_start: (out) (optional): return location for start of match, or %NULL.
 * @match_end: (out) (optional): return location for end of match, or %NULL.
 * @error: a #GError, or %NULL.
 *
 * Finishes a backward search started with
 * gtk_source_search_context_backward_async().
 *
 * Returns: whether a match was found.
 * Since: 3.10
 * Deprecated: 3.22: Use gtk_source_search_context_backward_finish2() instead.
 */
gboolean
gtk_source_search_context_backward_finish (GtkSourceSearchContext  *search,
					   GAsyncResult            *result,
					   GtkTextIter             *match_start,
					   GtkTextIter             *match_end,
					   GError                 **error)
{
	return gtk_source_search_context_forward_finish2 (search,
							  result,
							  match_start,
							  match_end,
							  NULL,
							  error);
}

/**
 * gtk_source_search_context_backward_finish2:
 * @search: a #GtkSourceSearchContext.
 * @result: a #GAsyncResult.
 * @match_start: (out) (optional): return location for start of match, or %NULL.
 * @match_end: (out) (optional): return location for end of match, or %NULL.
 * @has_wrapped_around: (out) (optional): return location to know whether the
 *   search has wrapped around, or %NULL.
 * @error: a #GError, or %NULL.
 *
 * Finishes a backward search started with
 * gtk_source_search_context_backward_async().
 *
 * See the documentation of gtk_source_search_context_backward2() for more
 * details.
 *
 * Returns: whether a match was found.
 * Since: 3.22
 */
gboolean
gtk_source_search_context_backward_finish2 (GtkSourceSearchContext  *search,
					    GAsyncResult            *result,
					    GtkTextIter             *match_start,
					    GtkTextIter             *match_end,
					    gboolean                *has_wrapped_around,
					    GError                 **error)
{
	return gtk_source_search_context_forward_finish2 (search,
							  result,
							  match_start,
							  match_end,
							  has_wrapped_around,
							  error);
}

/* If correctly replaced, returns %TRUE and @match_end is updated to point to
 * the replacement end.
 */
static gboolean
regex_replace (GtkSourceSearchContext  *search,
	       const GtkTextIter       *match_start,
	       GtkTextIter             *match_end,
	       const gchar             *replace,
	       GError                 **error)
{
	GtkTextIter real_start;
	GtkTextIter real_end;
	GtkTextIter match_start_check;
	GtkTextIter match_end_check;
	GtkTextIter match_start_copy;
	gint start_pos;
	gchar *subject;
	gchar *suffix;
	gchar *subject_replaced;
	GRegexMatchFlags match_options;
	GError *tmp_error = NULL;
	gboolean replaced = FALSE;

	if (search->priv->regex == NULL ||
	    search->priv->regex_error != NULL)
	{
		return FALSE;
	}

	regex_search_get_real_start (search, match_start, &real_start, &start_pos);
	g_assert_cmpint (start_pos, >=, 0);

	if (!basic_forward_regex_search (search,
					 match_start,
					 &match_start_check,
					 &match_end_check,
					 &real_end,
					 match_end))
	{
		g_assert_not_reached ();
	}

	g_assert (gtk_text_iter_equal (match_start, &match_start_check));
	g_assert (gtk_text_iter_equal (match_end, &match_end_check));

	subject = gtk_text_iter_get_visible_text (&real_start, &real_end);

	suffix = gtk_text_iter_get_visible_text (match_end, &real_end);
	if (suffix == NULL)
	{
		suffix = g_strdup ("");
	}

	match_options = regex_search_get_match_options (&real_start, &real_end);
	match_options |= G_REGEX_MATCH_ANCHORED;

	subject_replaced = g_regex_replace (search->priv->regex,
					    subject,
					    -1,
					    start_pos,
					    replace,
					    match_options,
					    &tmp_error);

	if (tmp_error != NULL)
	{
		g_propagate_error (error, tmp_error);
		goto end;
	}

	g_return_val_if_fail (g_str_has_suffix (subject_replaced, suffix), FALSE);

	/* Truncate subject_replaced to not contain the suffix, so we can
	 * replace only [match_start, match_end], not [match_start, real_end].
	 * The first solution is slightly simpler, and avoids the need to
	 * re-scan [match_end, real_end] for matches, which is convenient for a
	 * replace all.
	 */
	subject_replaced[strlen (subject_replaced) - strlen (suffix)] = '\0';
	g_return_val_if_fail (strlen (subject_replaced) >= (guint)start_pos, FALSE);

	match_start_copy = *match_start;

	gtk_text_buffer_begin_user_action (search->priv->buffer);
	gtk_text_buffer_delete (search->priv->buffer, &match_start_copy, match_end);
	gtk_text_buffer_insert (search->priv->buffer, match_end, subject_replaced + start_pos, -1);
	gtk_text_buffer_end_user_action (search->priv->buffer);

	replaced = TRUE;

end:
	g_free (subject);
	g_free (suffix);
	g_free (subject_replaced);
	return replaced;
}

/**
 * gtk_source_search_context_replace:
 * @search: a #GtkSourceSearchContext.
 * @match_start: the start of the match to replace.
 * @match_end: the end of the match to replace.
 * @replace: the replacement text.
 * @replace_length: the length of @replace in bytes, or -1.
 * @error: location to a #GError, or %NULL to ignore errors.
 *
 * Replaces a search match by another text. If @match_start and @match_end
 * doesn't correspond to a search match, %FALSE is returned.
 *
 * For a regular expression replacement, you can check if @replace is valid by
 * calling g_regex_check_replacement(). The @replace text can contain
 * backreferences; read the g_regex_replace() documentation for more details.
 *
 * Returns: whether the match has been replaced.
 * Since: 3.10
 * Deprecated: 3.22: Use gtk_source_search_context_replace2() instead.
 */
gboolean
gtk_source_search_context_replace (GtkSourceSearchContext  *search,
				   const GtkTextIter       *match_start,
				   const GtkTextIter       *match_end,
				   const gchar             *replace,
				   gint                     replace_length,
				   GError                 **error)
{
	GtkTextIter start;
	GtkTextIter end;

	g_return_val_if_fail (match_start != NULL, FALSE);
	g_return_val_if_fail (match_end != NULL, FALSE);

	start = *match_start;
	end = *match_end;

	return gtk_source_search_context_replace2 (search,
						   &start,
						   &end,
						   replace,
						   replace_length,
						   error);
}

/**
 * gtk_source_search_context_replace2:
 * @search: a #GtkSourceSearchContext.
 * @match_start: the start of the match to replace.
 * @match_end: the end of the match to replace.
 * @replace: the replacement text.
 * @replace_length: the length of @replace in bytes, or -1.
 * @error: location to a #GError, or %NULL to ignore errors.
 *
 * Replaces a search match by another text. If @match_start and @match_end
 * doesn't correspond to a search match, %FALSE is returned.
 *
 * Unlike with gtk_source_search_context_replace(), the @match_start and
 * @match_end iters are revalidated to point to the replacement text boundaries.
 *
 * For a regular expression replacement, you can check if @replace is valid by
 * calling g_regex_check_replacement(). The @replace text can contain
 * backreferences; read the g_regex_replace() documentation for more details.
 *
 * Returns: whether the match has been replaced.
 * Since: 3.22
 */
gboolean
gtk_source_search_context_replace2 (GtkSourceSearchContext  *search,
				    GtkTextIter             *match_start,
				    GtkTextIter             *match_end,
				    const gchar             *replace,
				    gint                     replace_length,
				    GError                 **error)
{
	GtkTextIter start;
	GtkTextIter end;
	GtkTextMark *start_mark;
	gboolean replaced = FALSE;

	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), FALSE);
	g_return_val_if_fail (match_start != NULL, FALSE);
	g_return_val_if_fail (match_end != NULL, FALSE);
	g_return_val_if_fail (replace != NULL, FALSE);
	g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

	if (search->priv->buffer == NULL)
	{
		return FALSE;
	}

	if (!smart_forward_search (search, match_start, &start, &end))
	{
		return FALSE;
	}

	if (!gtk_text_iter_equal (match_start, &start) ||
	    !gtk_text_iter_equal (match_end, &end))
	{
		return FALSE;
	}

	start_mark = gtk_text_buffer_create_mark (search->priv->buffer, NULL, &start, TRUE);

	if (gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		replaced = regex_replace (search, &start, &end, replace, error);
	}
	else
	{
		gtk_text_buffer_begin_user_action (search->priv->buffer);
		gtk_text_buffer_delete (search->priv->buffer, &start, &end);
		gtk_text_buffer_insert (search->priv->buffer, &end, replace, replace_length);
		gtk_text_buffer_end_user_action (search->priv->buffer);

		replaced = TRUE;
	}

	if (replaced)
	{
		gtk_text_buffer_get_iter_at_mark (search->priv->buffer, match_start, start_mark);
		*match_end = end;
	}

	gtk_text_buffer_delete_mark (search->priv->buffer, start_mark);

	return replaced;
}

/**
 * gtk_source_search_context_replace_all:
 * @search: a #GtkSourceSearchContext.
 * @replace: the replacement text.
 * @replace_length: the length of @replace in bytes, or -1.
 * @error: location to a #GError, or %NULL to ignore errors.
 *
 * Replaces all search matches by another text. It is a synchronous function, so
 * it can block the user interface.
 *
 * For a regular expression replacement, you can check if @replace is valid by
 * calling g_regex_check_replacement(). The @replace text can contain
 * backreferences; read the g_regex_replace() documentation for more details.
 *
 * Returns: the number of replaced matches.
 * Since: 3.10
 */
guint
gtk_source_search_context_replace_all (GtkSourceSearchContext  *search,
				       const gchar             *replace,
				       gint                     replace_length,
				       GError                 **error)
{
	GtkTextIter iter;
	GtkTextIter match_start;
	GtkTextIter match_end;
	guint nb_matches_replaced = 0;
	gboolean highlight_matching_brackets;
	gboolean has_regex_references = FALSE;

	g_return_val_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search), 0);
	g_return_val_if_fail (replace != NULL, 0);
	g_return_val_if_fail (error == NULL || *error == NULL, 0);

	if (search->priv->buffer == NULL)
	{
		return 0;
	}

	if (gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		GError *tmp_error = NULL;

		if (search->priv->regex == NULL ||
		    search->priv->regex_error != NULL)
		{
			return 0;
		}

		g_regex_check_replacement (replace,
					   &has_regex_references,
					   &tmp_error);

		if (tmp_error != NULL)
		{
			g_propagate_error (error, tmp_error);
			return 0;
		}
	}

	g_signal_handlers_block_by_func (search->priv->buffer, insert_text_before_cb, search);
	g_signal_handlers_block_by_func (search->priv->buffer, insert_text_after_cb, search);
	g_signal_handlers_block_by_func (search->priv->buffer, delete_range_before_cb, search);
	g_signal_handlers_block_by_func (search->priv->buffer, delete_range_after_cb, search);

	highlight_matching_brackets =
		gtk_source_buffer_get_highlight_matching_brackets (GTK_SOURCE_BUFFER (search->priv->buffer));

	gtk_source_buffer_set_highlight_matching_brackets (GTK_SOURCE_BUFFER (search->priv->buffer),
							   FALSE);

	_gtk_source_buffer_save_and_clear_selection (GTK_SOURCE_BUFFER (search->priv->buffer));

	gtk_text_buffer_get_start_iter (search->priv->buffer, &iter);

	gtk_text_buffer_begin_user_action (search->priv->buffer);

	while (smart_forward_search (search, &iter, &match_start, &match_end))
	{
		if (has_regex_references)
		{
			if (!regex_replace (search, &match_start, &match_end, replace, error))
			{
				break;
			}
		}
		else
		{
			gtk_text_buffer_delete (search->priv->buffer, &match_start, &match_end);
			gtk_text_buffer_insert (search->priv->buffer, &match_end, replace, replace_length);
		}

		nb_matches_replaced++;
		iter = match_end;
	}

	gtk_text_buffer_end_user_action (search->priv->buffer);

	_gtk_source_buffer_restore_selection (GTK_SOURCE_BUFFER (search->priv->buffer));

	gtk_source_buffer_set_highlight_matching_brackets (GTK_SOURCE_BUFFER (search->priv->buffer),
							   highlight_matching_brackets);

	g_signal_handlers_unblock_by_func (search->priv->buffer, insert_text_before_cb, search);
	g_signal_handlers_unblock_by_func (search->priv->buffer, insert_text_after_cb, search);
	g_signal_handlers_unblock_by_func (search->priv->buffer, delete_range_before_cb, search);
	g_signal_handlers_unblock_by_func (search->priv->buffer, delete_range_after_cb, search);

	update (search);

	return nb_matches_replaced;
}

/* Highlight the [start,end] region in priority. */
void
_gtk_source_search_context_update_highlight (GtkSourceSearchContext *search,
					     const GtkTextIter      *start,
					     const GtkTextIter      *end,
					     gboolean                synchronous)
{
	GtkSourceRegion *region_to_highlight = NULL;

	g_return_if_fail (GTK_SOURCE_IS_SEARCH_CONTEXT (search));
	g_return_if_fail (start != NULL);
	g_return_if_fail (end != NULL);

	if (search->priv->buffer == NULL ||
	    gtk_source_region_is_empty (search->priv->scan_region) ||
	    !search->priv->highlight)
	{
		return;
	}

	region_to_highlight = gtk_source_region_intersect_subregion (search->priv->scan_region,
								     start,
								     end);

	if (gtk_source_region_is_empty (region_to_highlight))
	{
		goto out;
	}

	if (!synchronous)
	{
		if (search->priv->high_priority_region == NULL)
		{
			search->priv->high_priority_region = region_to_highlight;
			region_to_highlight = NULL;
		}
		else
		{
			gtk_source_region_add_region (search->priv->high_priority_region,
						      region_to_highlight);
		}

		install_idle_scan (search);
		goto out;
	}

	if (gtk_source_search_settings_get_regex_enabled (search->priv->settings))
	{
		GtkTextIter region_start;

		if (!gtk_source_region_get_bounds (search->priv->scan_region,
						   &region_start,
						   NULL))
		{
			goto out;
		}

		regex_search_scan_chunk (search, &region_start, end);
	}
	else
	{
		scan_all_region (search, region_to_highlight);
	}

out:
	g_clear_object (&region_to_highlight);
}
