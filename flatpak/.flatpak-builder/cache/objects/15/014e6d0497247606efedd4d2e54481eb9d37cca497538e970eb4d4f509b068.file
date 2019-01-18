/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcelanguage-parser-ver1.c
 * Language specification parser for 1.0 version .lang files
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2003 - Paolo Maggi <paolo.maggi@polito.it>
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

#include <libxml/parser.h>
#include "gtksourceview-i18n.h"
#include "gtksourcebuffer.h"
#include "gtksourcelanguage.h"
#include "gtksourcelanguage-private.h"

static gchar *
fix_pattern (const gchar *pattern,
	     gboolean    *end_at_line_end)
{
	char *slash;

	if (pattern == NULL)
		return NULL;

	slash = strchr (pattern, '/');

	if (slash != NULL)
	{
		GString *str;

		str = g_string_new_len (pattern, slash - pattern);
		g_string_append (str, "\\/");
		pattern = slash + 1;

		while ((slash = strchr (pattern, '/')) != NULL)
		{
			g_string_append_len (str, pattern, slash - pattern);
			g_string_append (str, "\\/");
			pattern = slash + 1;
		}

		if (g_str_has_suffix (pattern, "\\n"))
			g_string_append_len (str, pattern, strlen(pattern) - 2);
		else
			g_string_append (str, pattern);

		return g_string_free (str, FALSE);
	}
	else if (g_str_has_suffix (pattern, "\\n"))
	{
		if (end_at_line_end)
			*end_at_line_end = TRUE;
		return g_strndup (pattern, strlen (pattern) - 2);
	}
	else
	{
		return g_strdup (pattern);
	}
}

static gboolean
ctx_data_add_simple_pattern (GtkSourceContextData *ctx_data,
			     GtkSourceLanguage    *language,
			     const gchar          *id,
			     const gchar          *style,
			     const gchar          *pattern)
{
	gboolean result;
	gchar *real_id, *root_id, *fixed;
	GError *error = NULL;

	g_return_val_if_fail (id != NULL, FALSE);

	root_id = g_strdup_printf ("%s:%s", language->priv->id, language->priv->id);
	real_id = g_strdup_printf ("%s:%s", language->priv->id, id);

	fixed = fix_pattern (pattern, NULL);

	result = _gtk_source_context_data_define_context (ctx_data, real_id,
							  root_id,
							  fixed, NULL, NULL,
							  style, NULL,
							  GTK_SOURCE_CONTEXT_EXTEND_PARENT |
								GTK_SOURCE_CONTEXT_END_AT_LINE_END,
							  &error);

	if (error != NULL)
	{
		g_warning ("%s", error->message);
		g_error_free (error);
	}

	g_free (fixed);
	g_free (real_id);
	g_free (root_id);
	return result;
}

static gboolean
ctx_data_add_syntax_pattern (GtkSourceContextData *ctx_data,
			     GtkSourceLanguage    *language,
			     const gchar          *id,
			     const gchar          *style,
			     const gchar          *pattern_start,
			     const gchar          *pattern_end,
			     gboolean              end_at_line_end)
{
	gboolean result;
	gchar *real_id, *root_id;
	gchar *fixed_start, *fixed_end;
	GError *error = NULL;
	GtkSourceContextFlags flags = GTK_SOURCE_CONTEXT_EXTEND_PARENT;

	g_return_val_if_fail (id != NULL, FALSE);

	root_id = g_strdup_printf ("%s:%s", language->priv->id, language->priv->id);
	real_id = g_strdup_printf ("%s:%s", language->priv->id, id);

	fixed_start = fix_pattern (pattern_start, &end_at_line_end);
	fixed_end = fix_pattern (pattern_end, &end_at_line_end);

	if (end_at_line_end)
		flags |= GTK_SOURCE_CONTEXT_END_AT_LINE_END;

	result = _gtk_source_context_data_define_context (ctx_data, real_id, root_id,
							  NULL,
							  pattern_start,
							  pattern_end,
							  style,
							  NULL,
							  flags,
							  &error);

	if (error != NULL)
	{
		g_warning ("%s", error->message);
		g_error_free (error);
	}

	g_free (real_id);
	g_free (root_id);
	g_free (fixed_start);
	g_free (fixed_end);

	return result;
}

static gchar *
build_keyword_list (const GSList *keywords,
		    gboolean      case_sensitive,
		    gboolean      match_empty_string_at_beginning,
		    gboolean      match_empty_string_at_end,
		    const gchar  *beginning_regex,
		    const gchar  *end_regex)
{
	GString *str;

	g_return_val_if_fail (keywords != NULL, NULL);

	str =  g_string_new ("");

	if (keywords != NULL)
	{
		if (match_empty_string_at_beginning)
			g_string_append (str, "\\b");

		if (beginning_regex != NULL)
			g_string_append (str, beginning_regex);

		if (case_sensitive)
			g_string_append (str, "(?:");
		else
			g_string_append (str, "(?i:");

		/* TODO Make sure pcre can handle big lists, and split lists if necessary.
		 * See #110991 */
		while (keywords != NULL)
		{
			g_string_append (str, (gchar*) keywords->data);

			keywords = g_slist_next (keywords);

			if (keywords != NULL)
				g_string_append (str, "|");
		}
		g_string_append (str, ")");

		if (end_regex != NULL)
			g_string_append (str, end_regex);

		if (match_empty_string_at_end)
			g_string_append (str, "\\b");
	}

	return g_string_free (str, FALSE);
}

static void
parseLineComment (xmlNodePtr            cur,
		  gchar                *id,
		  xmlChar              *style,
		  GtkSourceContextData *ctx_data,
		  GtkSourceLanguage    *language)
{
	xmlNodePtr child;

	child = cur->xmlChildrenNode;

	if ((child != NULL) && !xmlStrcmp (child->name, (const xmlChar *)"start-regex"))
	{
		xmlChar *start_regex;

		start_regex = xmlNodeListGetString (child->doc, child->xmlChildrenNode, 1);

		ctx_data_add_syntax_pattern (ctx_data, language, id,
					     (gchar*) style,
					     (gchar*) start_regex,
					     NULL, TRUE);

		xmlFree (start_regex);
	}
	else
	{
		g_warning ("Missing start-regex in tag 'line-comment' (%s, line %ld)",
			   child->doc->name, xmlGetLineNo (child));
	}
}

static void
parseBlockComment (xmlNodePtr            cur,
		   gchar                *id,
		   xmlChar              *style,
		   GtkSourceContextData *ctx_data,
		   GtkSourceLanguage    *language)
{
	xmlChar *start_regex = NULL;
	xmlChar *end_regex = NULL;

	xmlNodePtr child;

	child = cur->xmlChildrenNode;

	while (child != NULL)
	{
		if (!xmlStrcmp (child->name, (const xmlChar *)"start-regex"))
		{
			start_regex = xmlNodeListGetString (child->doc, child->xmlChildrenNode, 1);
		}
		else
		if (!xmlStrcmp (child->name, (const xmlChar *)"end-regex"))
		{
			end_regex = xmlNodeListGetString (child->doc, child->xmlChildrenNode, 1);
		}

		child = child->next;
	}

	if (start_regex == NULL)
	{
		g_warning ("Missing start-regex in tag 'block-comment' (%s, line %ld)",
			   child->doc->name, xmlGetLineNo (cur));

		return;
	}

	if (end_regex == NULL)
	{
		xmlFree (start_regex);

		g_warning ("Missing end-regex in tag 'block-comment' (%s, line %ld)",
			   child->doc->name, xmlGetLineNo (cur));

		return;
	}

	ctx_data_add_syntax_pattern (ctx_data, language, id,
				     (gchar*) style,
				     (gchar*) start_regex,
				     (gchar*) end_regex,
				     FALSE);

	xmlFree (start_regex);
	xmlFree (end_regex);
}

static void
parseString (xmlNodePtr            cur,
	     gchar                *id,
	     xmlChar              *style,
	     GtkSourceContextData *ctx_data,
	     GtkSourceLanguage    *language)
{
	xmlChar *start_regex = NULL;
	xmlChar *end_regex = NULL;

	xmlChar *prop = NULL;
	gboolean end_at_line_end = TRUE;

	xmlNodePtr child;

	prop = xmlGetProp (cur, BAD_CAST "end-at-line-end");
	if (prop != NULL)
	{
		if (!xmlStrcasecmp (prop, (const xmlChar *)"TRUE") ||
		    !xmlStrcmp (prop, (const xmlChar *)"1"))

				end_at_line_end = TRUE;
			else
				end_at_line_end = FALSE;

		xmlFree (prop);
	}

	child = cur->xmlChildrenNode;

	while (child != NULL)
	{
		if (!xmlStrcmp (child->name, (const xmlChar *)"start-regex"))
		{
			start_regex = xmlNodeListGetString (child->doc, child->xmlChildrenNode, 1);
		}
		else
		if (!xmlStrcmp (child->name, (const xmlChar *)"end-regex"))
		{
			end_regex = xmlNodeListGetString (child->doc, child->xmlChildrenNode, 1);
		}

		child = child->next;
	}

	if (start_regex == NULL)
	{
		g_warning ("Missing start-regex in tag 'string' (%s, line %ld)",
			   child->doc->name, xmlGetLineNo (cur));

		return;
	}

	if (end_regex == NULL)
	{
		xmlFree (start_regex);

		g_warning ("Missing end-regex in tag 'string' (%s, line %ld)",
			   child->doc->name, xmlGetLineNo (cur));

		return;
	}

	ctx_data_add_syntax_pattern (ctx_data, language, id,
				     (gchar*) style,
				     (gchar*) start_regex,
				     (gchar*) end_regex,
				     end_at_line_end);

	xmlFree (start_regex);
	xmlFree (end_regex);
}

static void
parseKeywordList (xmlNodePtr            cur,
		  gchar                *id,
		  xmlChar              *style,
		  GtkSourceContextData *ctx_data,
		  GtkSourceLanguage    *language)
{
	gboolean case_sensitive = TRUE;
	gboolean match_empty_string_at_beginning = TRUE;
	gboolean match_empty_string_at_end = TRUE;
	gchar  *beginning_regex = NULL;
	gchar  *end_regex = NULL;

	GSList *list = NULL;
	gchar *regex;

	xmlChar *prop;

	xmlNodePtr child;

	prop = xmlGetProp (cur, BAD_CAST "case-sensitive");
	if (prop != NULL)
	{
		if (!xmlStrcasecmp (prop, (const xmlChar *)"TRUE") ||
		    !xmlStrcmp (prop, (const xmlChar *)"1"))

				case_sensitive = TRUE;
			else
				case_sensitive = FALSE;

		xmlFree (prop);
	}

	prop = xmlGetProp (cur, BAD_CAST "match-empty-string-at-beginning");
	if (prop != NULL)
	{
		if (!xmlStrcasecmp (prop, (const xmlChar *)"TRUE") ||
		    !xmlStrcmp (prop, (const xmlChar *)"1"))

				match_empty_string_at_beginning = TRUE;
			else
				match_empty_string_at_beginning = FALSE;

		xmlFree (prop);
	}

	prop = xmlGetProp (cur, BAD_CAST "match-empty-string-at-end");
	if (prop != NULL)
	{
		if (!xmlStrcasecmp (prop, (const xmlChar *)"TRUE") ||
		    !xmlStrcmp (prop, (const xmlChar *)"1"))

				match_empty_string_at_end = TRUE;
			else
				match_empty_string_at_end = FALSE;

		xmlFree (prop);
	}

	prop = xmlGetProp (cur, BAD_CAST "beginning-regex");
	if (prop != NULL)
	{
		beginning_regex = g_strdup ((gchar *)prop);

		xmlFree (prop);
	}

	prop = xmlGetProp (cur, BAD_CAST "end-regex");
	if (prop != NULL)
	{
		end_regex = g_strdup ((gchar *)prop);

		xmlFree (prop);
	}

	child = cur->xmlChildrenNode;

	while (child != NULL)
	{
		if (!xmlStrcmp (child->name, BAD_CAST "keyword"))
		{
			xmlChar *keyword;
			keyword = xmlNodeListGetString (child->doc, child->xmlChildrenNode, 1);
			list = g_slist_prepend (list, keyword);
		}

		child = child->next;
	}

	list = g_slist_reverse (list);

	if (list == NULL)
	{
		g_warning ("No keywords in tag 'keyword-list' (%s, line %ld)",
			   child->doc->name, xmlGetLineNo (cur));

		g_free (beginning_regex),
		g_free (end_regex);

		return;
	}

	regex = build_keyword_list (list,
				    case_sensitive,
				    match_empty_string_at_beginning,
				    match_empty_string_at_end,
				    beginning_regex,
				    end_regex);

	g_free (beginning_regex),
	g_free (end_regex);

	g_slist_free_full (list, (GDestroyNotify)xmlFree);

	ctx_data_add_simple_pattern (ctx_data, language, id, (gchar*) style, regex);

	g_free (regex);
}

static void
parsePatternItem (xmlNodePtr            cur,
		  gchar                *id,
		  xmlChar              *style,
		  GtkSourceContextData *ctx_data,
		  GtkSourceLanguage    *language)
{
	xmlNodePtr child;

	child = cur->xmlChildrenNode;

	if ((child != NULL) && !xmlStrcmp (child->name, (const xmlChar *)"regex"))
	{
		xmlChar *regex;

		regex = xmlNodeListGetString (child->doc, child->xmlChildrenNode, 1);

		ctx_data_add_simple_pattern (ctx_data, language, id,
					     (gchar*) style,
					     (gchar*) regex);

		xmlFree (regex);
	}
	else
	{
		g_warning ("Missing regex in tag 'pattern-item' (%s, line %ld)",
			   child->doc->name, xmlGetLineNo (child));
	}
}

static void
parseSyntaxItem (xmlNodePtr            cur,
		 const gchar          *id,
		 xmlChar              *style,
		 GtkSourceContextData *ctx_data,
		 GtkSourceLanguage    *language)
{
	xmlChar *start_regex = NULL;
	xmlChar *end_regex = NULL;

	xmlNodePtr child;

	child = cur->xmlChildrenNode;

	while (child != NULL)
	{
		if (!xmlStrcmp (child->name, (const xmlChar *)"start-regex"))
		{
			start_regex = xmlNodeListGetString (child->doc, child->xmlChildrenNode, 1);
		}
		else
		if (!xmlStrcmp (child->name, (const xmlChar *)"end-regex"))
		{
			end_regex = xmlNodeListGetString (child->doc, child->xmlChildrenNode, 1);
		}

		child = child->next;
	}

	if (start_regex == NULL)
	{
		g_warning ("Missing start-regex in tag 'syntax-item' (%s, line %ld)",
			   child->doc->name, xmlGetLineNo (cur));

		return;
	}

	if (end_regex == NULL)
	{
		xmlFree (start_regex);

		g_warning ("Missing end-regex in tag 'syntax-item' (%s, line %ld)",
			   child->doc->name, xmlGetLineNo (cur));

		return;
	}

	ctx_data_add_syntax_pattern (ctx_data, language, id,
				     (gchar*) style,
				     (gchar*) start_regex,
				     (gchar*) end_regex,
				     FALSE);

	xmlFree (start_regex);
	xmlFree (end_regex);
}

static void
parseTag (GtkSourceLanguage    *language,
	  xmlNodePtr            cur,
	  GtkSourceContextData *ctx_data)
{
	xmlChar *name;
	xmlChar *style;
	xmlChar *id;

	name = xmlGetProp (cur, BAD_CAST "_name");
	if (name == NULL)
	{
		name = xmlGetProp (cur, BAD_CAST "name");
		id = xmlStrdup (name);
	}
	else
	{
		gchar *tmp1 = _gtk_source_language_translate_string (language, (gchar*) name);
		xmlChar *tmp2 = xmlStrdup (BAD_CAST tmp1);
		id = name;
		name = tmp2;
		g_free (tmp1);
	}

	if (name == NULL)
	{
		return;
	}

	style = xmlGetProp (cur, BAD_CAST "style");

	if (!xmlStrcmp (cur->name, (const xmlChar*) "line-comment"))
	{
		parseLineComment (cur, (gchar*) id, style, ctx_data, language);
	}
	else if (!xmlStrcmp (cur->name, (const xmlChar*) "block-comment"))
	{
		parseBlockComment (cur, (gchar*) id, style, ctx_data, language);
	}
	else if (!xmlStrcmp (cur->name, (const xmlChar*) "string"))
	{
		parseString (cur, (gchar*) id, style, ctx_data, language);
	}
	else if (!xmlStrcmp (cur->name, (const xmlChar*) "keyword-list"))
	{
		parseKeywordList (cur, (gchar*) id, style, ctx_data, language);
	}
	else if (!xmlStrcmp (cur->name, (const xmlChar*) "pattern-item"))
	{
		parsePatternItem (cur, (gchar*) id, style, ctx_data, language);
	}
	else if (!xmlStrcmp (cur->name, (const xmlChar*) "syntax-item"))
	{
		parseSyntaxItem (cur, (gchar*) id, style, ctx_data, language);
	}
	else
	{
		g_print ("Unknown tag: %s\n", cur->name);
	}

	xmlFree (name);
	xmlFree (style);
	xmlFree (id);
}

static gboolean
define_root_context (GtkSourceContextData *ctx_data,
		     GtkSourceLanguage    *language)
{
	gboolean result;
	gchar *id;
	GError *error = NULL;

	g_return_val_if_fail (language->priv->id != NULL, FALSE);

	id = g_strdup_printf ("%s:%s", language->priv->id, language->priv->id);
	result = _gtk_source_context_data_define_context (ctx_data, id,
							  NULL, NULL, NULL, NULL,
							  NULL, NULL,
							  GTK_SOURCE_CONTEXT_EXTEND_PARENT,
							  &error);

	if (error != NULL)
	{
		g_warning ("%s", error->message);
		g_error_free (error);
	}

	g_free (id);
	return result;
}

gboolean
_gtk_source_language_file_parse_version1 (GtkSourceLanguage    *language,
					  GtkSourceContextData *ctx_data)
{
	xmlDocPtr doc;
	xmlNodePtr cur;
	GMappedFile *mf;
	gunichar esc_char = 0;
	xmlChar *lang_version = NULL;

	xmlKeepBlanksDefault (0);

	mf = g_mapped_file_new (language->priv->lang_file_name, FALSE, NULL);

	if (mf == NULL)
	{
		doc = NULL;
	}
	else
	{
		doc = xmlParseMemory (g_mapped_file_get_contents (mf),
				      g_mapped_file_get_length (mf));

		g_mapped_file_unref (mf);
	}

	if (doc == NULL)
	{
		g_warning ("Impossible to parse file '%s'",
			   language->priv->lang_file_name);
		return FALSE;
	}

	cur = xmlDocGetRootElement (doc);

	if (cur == NULL)
	{
		g_warning ("The lang file '%s' is empty",
			   language->priv->lang_file_name);
		goto error;
	}

	if (xmlStrcmp (cur->name, (const xmlChar *) "language") != 0)
	{
		g_warning ("File '%s' is of the wrong type",
			   language->priv->lang_file_name);
		goto error;
	}

	lang_version = xmlGetProp (cur, BAD_CAST "version");

	if (lang_version == NULL || strcmp ("1.0", (char*) lang_version) != 0)
	{
		if (lang_version != NULL)
			g_warning ("Wrong language version '%s' in file '%s', expected '%s'",
				   (char*) lang_version, language->priv->lang_file_name, "1.0");
		else
			g_warning ("Language version missing in file '%s'",
				   language->priv->lang_file_name);
		goto error;
	}

	if (!define_root_context (ctx_data, language))
	{
		g_warning ("Could not create root context for file '%s'",
			   language->priv->lang_file_name);
		goto error;
	}

	/* FIXME: check that the language name, version, etc. are the
	 * right ones - Paolo */

	cur = xmlDocGetRootElement (doc);
	cur = cur->xmlChildrenNode;
	g_return_val_if_fail (cur != NULL, FALSE);

	while (cur != NULL)
	{
		if (!xmlStrcmp (cur->name, (const xmlChar *)"escape-char"))
		{
			xmlChar *escape;

			escape = xmlNodeListGetString (doc, cur->xmlChildrenNode, 1);
			esc_char = g_utf8_get_char_validated ((gchar*) escape, -1);

			if (esc_char == (gunichar) -1 || esc_char == (gunichar) -2)
			{
				g_warning ("Invalid (non UTF8) escape character in file '%s'",
					   language->priv->lang_file_name);
				esc_char = 0;
			}

			xmlFree (escape);
		}
		else
		{
			parseTag (language, cur, ctx_data);
		}

		cur = cur->next;
	}

	if (esc_char != 0)
		_gtk_source_context_data_set_escape_char (ctx_data, esc_char);

	_gtk_source_context_data_finish_parse (ctx_data, NULL, NULL);
	_gtk_source_language_define_language_styles (language);

	xmlFreeDoc (doc);
	xmlFree (lang_version);
	return TRUE;

error:
	if (doc)
		xmlFreeDoc (doc);
	xmlFree (lang_version);
	return FALSE;
}

