/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourceregex.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2003 - Gustavo Giráldez <gustavo.giraldez@gmx.net>
 * Copyright (C) 2005, 2006 - Marco Barisione, Emanuele Aina
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

#include <string.h>
#include <glib.h>
#include "gtksourceview-i18n.h"
#include "gtksourceview-utils.h"
#include "gtksourceregex.h"

/*
 * GRegex wrapper which adds a few features needed for syntax highlighting,
 * in particular resolving "\%{...@start}" and forbidding the use of \C.
 */

/* Regex used to match "\%{...@start}". */
static GRegex *
get_start_ref_regex (void)
{
	static GRegex *start_ref_regex = NULL;

	if (start_ref_regex == NULL)
	{
		start_ref_regex = g_regex_new ("(?<!\\\\)(\\\\\\\\)*\\\\%\\{(.*?)@start\\}",
					       G_REGEX_OPTIMIZE, 0, NULL);
	}

	return start_ref_regex;
}

struct _GtkSourceRegex
{
	union {
		struct {
			gchar *pattern;
			GRegexCompileFlags flags;
		} info;
		struct {
			GRegex *regex;
			GMatchInfo *match;
		} regex;
	} u;

	guint ref_count;
	guint resolved : 1;
};

/* Check whether pattern contains \C escape sequence,
 * which means "single byte" in pcre and naturally leads
 * to crash if used for highlighting.
 */
static gboolean
find_single_byte_escape (const gchar *string)
{
	const char *p = string;

	while ((p = strstr (p, "\\C")))
	{
		const char *slash;
		gboolean found;

		if (p == string)
			return TRUE;

		found = TRUE;
		slash = p - 1;

		while (slash >= string && *slash == '\\')
		{
			found = !found;
			slash--;
		}

		if (found)
			return TRUE;

		p += 2;
	}

	return FALSE;
}

/**
 * gtk_source_regex_new:
 * @pattern: the regular expression.
 * @flags: compile options for @pattern.
 * @error: location to store the error occuring, or %NULL to ignore errors.
 *
 * Creates a new regex.
 *
 * Returns: a newly-allocated #GtkSourceRegex.
 */
GtkSourceRegex *
_gtk_source_regex_new (const gchar           *pattern,
		       GRegexCompileFlags     flags,
		       GError               **error)
{
	GtkSourceRegex *regex;

	g_return_val_if_fail (pattern != NULL, NULL);
	g_return_val_if_fail (error == NULL || *error == NULL, NULL);

	if (find_single_byte_escape (pattern))
	{
		g_set_error_literal (error, G_REGEX_ERROR,
		                     G_REGEX_ERROR_COMPILE,
		                     _("using \\C is not supported in language definitions"));
		return NULL;
	}

	regex = g_slice_new0 (GtkSourceRegex);
	regex->ref_count = 1;

	if (g_regex_match (get_start_ref_regex (), pattern, 0, NULL))
	{
		regex->resolved = FALSE;
		regex->u.info.pattern = g_strdup (pattern);
		regex->u.info.flags = flags;
	}
	else
	{
		regex->resolved = TRUE;
		regex->u.regex.regex = g_regex_new (pattern,
						    flags | G_REGEX_OPTIMIZE | G_REGEX_NEWLINE_LF, 0,
						    error);

		if (regex->u.regex.regex == NULL)
		{
			g_slice_free (GtkSourceRegex, regex);
			regex = NULL;
		}
	}

	return regex;
}

GtkSourceRegex *
_gtk_source_regex_ref (GtkSourceRegex *regex)
{
	if (regex != NULL)
		regex->ref_count++;
	return regex;
}

void
_gtk_source_regex_unref (GtkSourceRegex *regex)
{
	if (regex != NULL && --regex->ref_count == 0)
	{
		if (regex->resolved)
		{
			g_regex_unref (regex->u.regex.regex);
			if (regex->u.regex.match)
				g_match_info_free (regex->u.regex.match);
		}
		else
		{
			g_free (regex->u.info.pattern);
		}
		g_slice_free (GtkSourceRegex, regex);
	}
}

struct RegexResolveData {
	GtkSourceRegex *start_regex;
	const gchar *matched_text;
};

static gboolean
replace_start_regex (const GMatchInfo *match_info,
		     GString          *expanded_regex,
		     gpointer          user_data)
{
	gchar *num_string, *subst, *subst_escaped, *escapes;
	gint num;
	struct RegexResolveData *data = user_data;

	escapes = g_match_info_fetch (match_info, 1);
	num_string = g_match_info_fetch (match_info, 2);
	num = _gtk_source_string_to_int (num_string);

	if (num < 0)
	{
		subst = g_match_info_fetch_named (data->start_regex->u.regex.match,
						  num_string);
	}
	else
	{
		subst = g_match_info_fetch (data->start_regex->u.regex.match,
					    num);
	}

	if (subst != NULL)
	{
		subst_escaped = g_regex_escape_string (subst, -1);
	}
	else
	{
		g_warning ("Invalid group: %s", num_string);
		subst_escaped = g_strdup ("");
	}

	g_string_append (expanded_regex, escapes);
	g_string_append (expanded_regex, subst_escaped);

	g_free (escapes);
	g_free (num_string);
	g_free (subst);
	g_free (subst_escaped);

	return FALSE;
}

/**
 * _gtk_source_regex_resolve:
 * @regex: a #GtkSourceRegex.
 * @start_regex: a #GtkSourceRegex.
 * @matched_text: the text matched against @start_regex.
 *
 * If the regular expression does not contain references to the start
 * regular expression, the functions increases the reference count
 * of @regex and returns it.
 *
 * If the regular expression contains references to the start regular
 * expression in the form "\%{start_sub_pattern@start}", it replaces
 * them (they are extracted from @start_regex and @matched_text) and
 * returns the new regular expression.
 *
 * Returns: a #GtkSourceRegex.
 */
GtkSourceRegex *
_gtk_source_regex_resolve (GtkSourceRegex *regex,
			   GtkSourceRegex *start_regex,
			   const gchar    *matched_text)
{
	gchar *expanded_regex;
	GtkSourceRegex *new_regex;
	struct RegexResolveData data;

	if (regex == NULL || regex->resolved)
		return _gtk_source_regex_ref (regex);

	data.start_regex = start_regex;
	data.matched_text = matched_text;
	expanded_regex = g_regex_replace_eval (get_start_ref_regex (),
					       regex->u.info.pattern,
					       -1, 0, 0,
					       replace_start_regex,
					       &data, NULL);
	new_regex = _gtk_source_regex_new (expanded_regex, regex->u.info.flags, NULL);
	if (new_regex == NULL || !new_regex->resolved)
	{
		_gtk_source_regex_unref (new_regex);
		g_warning ("Regular expression %s cannot be expanded.",
			   regex->u.info.pattern);
		/* Returns a regex that nevers matches. */
		new_regex = _gtk_source_regex_new ("$never-match^", 0, NULL);
	}

	g_free (expanded_regex);

	return new_regex;
}

gboolean
_gtk_source_regex_is_resolved (GtkSourceRegex *regex)
{
	return regex->resolved;
}

gboolean
_gtk_source_regex_match (GtkSourceRegex *regex,
			 const gchar    *line,
			 gint             byte_length,
			 gint             byte_pos)
{
	gboolean result;

	g_assert (regex->resolved);

	if (regex->u.regex.match)
	{
		g_match_info_free (regex->u.regex.match);
		regex->u.regex.match = NULL;
	}

	result = g_regex_match_full (regex->u.regex.regex, line,
				     byte_length, byte_pos,
				     0, &regex->u.regex.match,
				     NULL);

	return result;
}

gchar *
_gtk_source_regex_fetch (GtkSourceRegex *regex,
		         gint            num)
{
	g_assert (regex->resolved);

	return g_match_info_fetch (regex->u.regex.match, num);
}

void
_gtk_source_regex_fetch_pos (GtkSourceRegex *regex,
			     const gchar    *text,
			     gint            num,
			     gint           *start_pos, /* character offsets */
			     gint           *end_pos)   /* character offsets */
{
	gint byte_start_pos, byte_end_pos;

	g_assert (regex->resolved);

	if (!g_match_info_fetch_pos (regex->u.regex.match, num, &byte_start_pos, &byte_end_pos))
	{
		if (start_pos != NULL)
			*start_pos = -1;
		if (end_pos != NULL)
			*end_pos = -1;
	}
	else
	{
		if (start_pos != NULL)
			*start_pos = g_utf8_pointer_to_offset (text, text + byte_start_pos);
		if (end_pos != NULL)
			*end_pos = g_utf8_pointer_to_offset (text, text + byte_end_pos);
	}
}

void
_gtk_source_regex_fetch_pos_bytes (GtkSourceRegex *regex,
				   gint            num,
				   gint           *start_pos_p, /* byte offsets */
				   gint           *end_pos_p)   /* byte offsets */
{
	gint start_pos;
	gint end_pos;

	g_assert (regex->resolved);

	if (!g_match_info_fetch_pos (regex->u.regex.match, num, &start_pos, &end_pos))
	{
		start_pos = -1;
		end_pos = -1;
	}

	if (start_pos_p != NULL)
		*start_pos_p = start_pos;
	if (end_pos_p != NULL)
		*end_pos_p = end_pos;
}

void
_gtk_source_regex_fetch_named_pos (GtkSourceRegex *regex,
				   const gchar    *text,
				   const gchar    *name,
				   gint           *start_pos, /* character offsets */
				   gint           *end_pos)   /* character offsets */
{
	gint byte_start_pos, byte_end_pos;

	g_assert (regex->resolved);

	if (!g_match_info_fetch_named_pos (regex->u.regex.match, name, &byte_start_pos, &byte_end_pos))
	{
		if (start_pos != NULL)
			*start_pos = -1;
		if (end_pos != NULL)
			*end_pos = -1;
	}
	else
	{
		if (start_pos != NULL)
			*start_pos = g_utf8_pointer_to_offset (text, text + byte_start_pos);
		if (end_pos != NULL)
			*end_pos = g_utf8_pointer_to_offset (text, text + byte_end_pos);
	}
}

const gchar *
_gtk_source_regex_get_pattern (GtkSourceRegex *regex)
{
	g_assert (regex->resolved);

	return g_regex_get_pattern (regex->u.regex.regex);
}

