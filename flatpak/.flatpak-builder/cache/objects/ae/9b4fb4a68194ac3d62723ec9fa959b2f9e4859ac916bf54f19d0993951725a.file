/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourceutils.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2005 - Paolo Borelli
 * Copyright (C) 2013 - Sébastien Wilmet <swilmet@gnome.org>
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

/**
 * SECTION:utils
 * @title: GtkSourceUtils
 * @short_description: Utilities functions
 *
 * Utilities functions.
 */

#include "gtksourceutils.h"
#include <string.h>

/**
 * gtk_source_utils_unescape_search_text:
 * @text: the text to unescape.
 *
 * Use this function before gtk_source_search_settings_set_search_text(), to
 * unescape the following sequences of characters: `\n`, `\r`, `\t` and `\\`.
 * The purpose is to easily write those characters in a search entry.
 *
 * Note that unescaping the search text is not needed for regular expression
 * searches.
 *
 * See also: gtk_source_utils_escape_search_text().
 *
 * Returns: the unescaped @text.
 * Since: 3.10
 */
gchar *
gtk_source_utils_unescape_search_text (const gchar *text)
{
	GString *str;
	gint length;
	gboolean drop_prev = FALSE;
	const gchar *cur;
	const gchar *end;
	const gchar *prev;

	if (text == NULL)
	{
		return NULL;
	}

	length = strlen (text);

	str = g_string_new ("");

	cur = text;
	end = text + length;
	prev = NULL;

	while (cur != end)
	{
		const gchar *next;
		next = g_utf8_next_char (cur);

		if (prev && (*prev == '\\'))
		{
			switch (*cur)
			{
				case 'n':
					str = g_string_append (str, "\n");
					break;
				case 'r':
					str = g_string_append (str, "\r");
					break;
				case 't':
					str = g_string_append (str, "\t");
					break;
				case '\\':
					str = g_string_append (str, "\\");
					drop_prev = TRUE;
					break;
				default:
					str = g_string_append (str, "\\");
					str = g_string_append_len (str, cur, next - cur);
					break;
			}
		}
		else if (*cur != '\\')
		{
			str = g_string_append_len (str, cur, next - cur);
		}
		else if ((next == end) && (*cur == '\\'))
		{
			str = g_string_append (str, "\\");
		}

		if (!drop_prev)
		{
			prev = cur;
		}
		else
		{
			prev = NULL;
			drop_prev = FALSE;
		}

		cur = next;
	}

	return g_string_free (str, FALSE);
}

/**
 * gtk_source_utils_escape_search_text:
 * @text: the text to escape.
 *
 * Use this function to escape the following characters: `\n`, `\r`, `\t` and `\`.
 *
 * For a regular expression search, use g_regex_escape_string() instead.
 *
 * One possible use case is to take the #GtkTextBuffer's selection and put it in a
 * search entry. The selection can contain tabulations, newlines, etc. So it's
 * better to escape those special characters to better fit in the search entry.
 *
 * See also: gtk_source_utils_unescape_search_text().
 *
 * <warning>
 * Warning: the escape and unescape functions are not reciprocal! For example,
 * escape (unescape (\)) = \\. So avoid cycles such as: search entry -> unescape
 * -> search settings -> escape -> search entry. The original search entry text
 * may be modified.
 * </warning>
 *
 * Returns: the escaped @text.
 * Since: 3.10
 */
gchar *
gtk_source_utils_escape_search_text (const gchar* text)
{
	GString *str;
	gint length;
	const gchar *p;
	const gchar *end;

	if (text == NULL)
	{
		return NULL;
	}

	length = strlen (text);

	str = g_string_new ("");

	p = text;
	end = text + length;

	while (p != end)
	{
		const gchar *next = g_utf8_next_char (p);

		switch (*p)
		{
			case '\n':
				g_string_append (str, "\\n");
				break;
			case '\r':
				g_string_append (str, "\\r");
				break;
			case '\t':
				g_string_append (str, "\\t");
				break;
			case '\\':
				g_string_append (str, "\\\\");
				break;
			default:
				g_string_append_len (str, p, next - p);
				break;
		}

		p = next;
	}

	return g_string_free (str, FALSE);
}
