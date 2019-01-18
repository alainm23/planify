/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcelanguage-parser-2.c
 * Language specification parser for 2.0 version .lang files
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2003 - Gustavo Giráldez <gustavo.giraldez@gmx.net>
 * Copyright (C) 2005, 2006 - Emanuele Aina, Marco Barisione
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

#undef ENABLE_DEBUG

#ifdef ENABLE_DEBUG
#define DEBUG(x) x
#else
#define DEBUG(x)
#endif

#include "gtksourceview-i18n.h"
#include "gtksourcebuffer.h"
#include "gtksourcelanguage.h"
#include "gtksourcelanguage-private.h"
#include "gtksourcecontextengine.h"

#include <glib.h>
#include <glib/gstdio.h>

#include <string.h>
#include <fcntl.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef G_OS_WIN32
#include <io.h>
#endif
#include <libxml/xmlreader.h>

#define PARSER_ERROR (parser_error_quark ())
#define ATTR_NO_STYLE ""

typedef enum _ParserError {
	PARSER_ERROR_CANNOT_OPEN     = 0,
	PARSER_ERROR_CANNOT_VALIDATE,
	PARSER_ERROR_INVALID_DOC,
	PARSER_ERROR_WRONG_VERSION,
	PARSER_ERROR_WRONG_ID,
	PARSER_ERROR_WRONG_STYLE,
	PARSER_ERROR_MALFORMED_REGEX,
	PARSER_ERROR_MALFORMED_MAP_TO
} ParserError;

struct _ParserState
{
	/* The args passed to _file_parse_version2() */
	xmlTextReader *reader;
	char *filename;
	GtkSourceLanguage *language;
	GtkSourceContextData *ctx_data;

	gchar *language_decoration;

	/* A stack of id that representing parent contexts */
	GQueue *curr_parents;

	/* The id of the current language (used to decorate ids) */
	gchar *current_lang_id;

	/* An hash table with the defined regex as strings used to
	 * resolve references (the key is the id) */
	GHashTable *defined_regexes;

	/* Maps style ids to GtkSourceStyleInfo objects.
	 * Contains all the styles defined in the lang files parsed
	 * while parsing the main language file. For example, if the main
	 * language is C, also styles in def.lang, gtk-doc.lang, etc. are
	 * stored in this hash table. For styles defined in language files
	 * different from the main one, the name is _not_ stored, since it
	 * is not used in other places of the code. So, if the main language is
	 * C, only the name of styles defined in c.lang is stored, while for
	 * the styles defined in def.lang, etc. the name is not stored. */
	GHashTable *styles_mapping;

	/* The list of loaded languages (the item are xmlChar pointers),
	 * mapping is id -> id */
	GHashTable *loaded_lang_ids;

	/* The list of replacements. The queue object is owned by the caller,
	 * so parser_state only adds stuff to it */
	GQueue *replacements;

	/* A serial number incremented to get unique generated names */
	guint id_cookie;

	/* The default flags used by the regexes */
	GRegexCompileFlags regex_compile_flags;

	gchar *opening_delimiter;
	gchar *closing_delimiter;

	GError *error;
};

typedef struct _ParserState ParserState;


static GQuark     parser_error_quark           (void);
static gboolean   str_to_bool                  (const xmlChar *string);
static gchar     *generate_new_id              (ParserState *parser_state);
static gboolean   id_is_decorated              (const gchar *id,
                                                gchar **lang_id);
static gchar     *decorate_id                  (ParserState *parser_state,
                                                const gchar *id);

static ParserState *parser_state_new           (GtkSourceLanguage      *language,
                                                GtkSourceContextData   *ctx_data,
                                                GHashTable             *defined_regexes,
                                                GHashTable             *styles_mapping,
						GQueue                 *replacements,
                                                xmlTextReader          *reader,
						const char             *filename,
                                                GHashTable             *loaded_lang_ids);
static void       parser_state_destroy         (ParserState *parser_state);

static gboolean   file_parse                   (gchar                  *filename,
                                                GtkSourceLanguage      *language,
                                                GtkSourceContextData   *ctx_data,
                                                GHashTable             *defined_regexes,
                                                GHashTable             *styles,
                                                GHashTable             *loaded_lang_ids,
						GQueue                 *replacements,
                                                GError                **error);

static GRegexCompileFlags
		  update_regex_flags	       (GRegexCompileFlags flags,
						const xmlChar *option_name,
						const xmlChar *bool_value);

static gboolean   create_definition            (ParserState *parser_state,
                                                gchar *id,
                                                gchar *parent_id,
                                                gchar *style,
                                                GSList *context_classes,
						GError **error);

static void       handle_context_element       (ParserState *parser_state);
static void       handle_language_element      (ParserState *parser_state);
static void       handle_define_regex_element  (ParserState *parser_state);
static void       handle_default_regex_options_element
                                               (ParserState *parser_state);
static void       handle_replace_element       (ParserState *parser_state);
static void       element_start                (ParserState *parser_state);
static void       element_end                  (ParserState *parser_state);
static gboolean   replace_by_id                (const GMatchInfo *match_info,
						GString *expanded_regex,
						gpointer data);
static gchar     *expand_regex                 (ParserState *parser_state,
                                                gchar *regex,
						GRegexCompileFlags flags,
						gboolean do_expand_vars,
						gboolean insert_parentheses,
						GError **error);

static GQuark
parser_error_quark (void)
{
	static GQuark err_q = 0;
	if (err_q == 0)
		err_q = g_quark_from_static_string (
			"parser-error-quark");

	return err_q;
}

static gboolean
str_to_bool (const xmlChar *string)
{
	g_return_val_if_fail (string != NULL, FALSE);
	return g_ascii_strcasecmp ("true", (const gchar *) string) == 0;
}

static gchar *
generate_new_id (ParserState *parser_state)
{
	gchar *id;

	id = g_strdup_printf ("unnamed-%u", parser_state->id_cookie);
	parser_state->id_cookie++;

	DEBUG (g_message ("generated id %s", id));

	return id;
}

static gboolean
id_is_decorated (const gchar *id,
		 gchar      **lang_id)
{
	/* This function is quite simple because the XML validator check for
	 * the correctness of the id with a regex */

	const gchar *colon;
	gboolean is_decorated = FALSE;

	colon = strchr (id, ':');

	if (colon != NULL && strcmp ("*", colon + 1) != 0)
	{
		is_decorated = TRUE;

		if (lang_id != NULL)
			*lang_id = g_strndup (id, colon - id);
	}

	return is_decorated;
}

static gchar *
decorate_id (ParserState *parser_state,
	     const gchar *id)
{
	gchar *decorated_id;

	decorated_id = g_strdup_printf ("%s:%s",
			parser_state->current_lang_id, id);

	DEBUG (g_message ("decorated '%s' to '%s'", id, decorated_id));

	return decorated_id;
}

static gboolean
lang_id_is_already_loaded (ParserState *parser_state, gchar *lang_id)
{
	return g_hash_table_lookup (parser_state->loaded_lang_ids, lang_id) != NULL;
}

static GRegexCompileFlags
get_regex_flags (xmlNode             *node,
		 GRegexCompileFlags flags)
{
	xmlAttr *attr;

	for (attr = node->properties; attr != NULL; attr = attr->next)
	{
		g_return_val_if_fail (attr->children != NULL, flags);

		flags = update_regex_flags (flags, attr->name,
					    attr->children->content);
	}

	return flags;
}

static GtkSourceContextFlags
get_context_flags (ParserState *parser_state)
{
	guint i;
	xmlChar *value;
	GtkSourceContextFlags flags = GTK_SOURCE_CONTEXT_EXTEND_PARENT;
	const gchar *names[] = {
		"extend-parent", "end-parent", "end-at-line-end",
		"first-line-only", "once-only", "style-inside"
	};
	GtkSourceContextFlags values[] = {
		GTK_SOURCE_CONTEXT_EXTEND_PARENT,
		GTK_SOURCE_CONTEXT_END_PARENT,
		GTK_SOURCE_CONTEXT_END_AT_LINE_END,
		GTK_SOURCE_CONTEXT_FIRST_LINE_ONLY,
		GTK_SOURCE_CONTEXT_ONCE_ONLY,
		GTK_SOURCE_CONTEXT_STYLE_INSIDE
	};

	g_assert (G_N_ELEMENTS (names) == G_N_ELEMENTS (values));

	for (i = 0; i < G_N_ELEMENTS (names); ++i)
	{
		value = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST names[i]);

		if (value != NULL)
		{
			if (str_to_bool (value))
				flags |= values[i];
			else
				flags &= ~values[i];
		}

		xmlFree (value);
	}

	return flags;
}

static GSList *
add_classes (GSList      *list,
             gchar const *classes,
             gboolean     enabled)
{
	gchar **parts;
	gchar **ptr;
	GSList *newlist = NULL;

	if (classes == NULL)
	{
		return list;
	}

	parts = ptr = g_strsplit (classes, " ", -1);

	while (*ptr)
	{
		GtkSourceContextClass *ctx = gtk_source_context_class_new (*ptr, enabled);
		newlist = g_slist_prepend (newlist, ctx);

		++ptr;
	}

	g_strfreev (parts);
	return g_slist_concat (list, g_slist_reverse (newlist));
}

static GSList *
parse_classes (ParserState *parser_state)
{
	GSList *ret = NULL;
	xmlChar *en = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "class");
	xmlChar *dis = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "class-disabled");

	ret = add_classes (ret, (gchar const *)en, TRUE);
	ret = add_classes (ret, (gchar const *)dis, FALSE);

	xmlFree (en);
	xmlFree (dis);

	return ret;
}

static gboolean
create_definition (ParserState *parser_state,
		   gchar       *id,
		   gchar       *parent_id,
		   gchar       *style,
		   GSList      *context_classes,
		   GError     **error)
{
	gchar *match = NULL, *start = NULL, *end = NULL;
	gchar *prefix = NULL, *suffix = NULL;
	GtkSourceContextFlags flags;

	xmlNode *context_node, *child;

	GString *all_items = NULL;

	GRegexCompileFlags match_flags = 0, start_flags = 0, end_flags = 0;

	GError *tmp_error = NULL;

	g_assert (parser_state->ctx_data != NULL);

	g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

	flags = get_context_flags (parser_state);

	DEBUG (g_message ("creating context %s, child of %s", id, parent_id ? parent_id : "(null)"));

	/* Fetch the content of the sublements using the tree API on
	 * the current node */
	context_node = xmlTextReaderExpand (parser_state->reader);

	/* The file should be validated so this should not happen */
	g_assert (context_node != NULL);

	for (child = context_node->children; child != NULL; child = child->next)
	{
		if (child->type != XML_ELEMENT_NODE)
			continue;

		/* FIXME: add PCRE_EXTRA support in EggRegex
		 * Huh? */

		g_assert (child->name);
		if (xmlStrcmp (BAD_CAST "match", child->name) == 0
				&& child->children != NULL)
		{
			/* <match> */
			match = g_strdup ((gchar *)child->children->content);
			match_flags = get_regex_flags (child, parser_state->regex_compile_flags);
		}
		else if (xmlStrcmp (BAD_CAST "start", child->name) == 0)
		{
			/* <start> */
			if (child->children != NULL)
			{
				start = g_strdup ((gchar *)child->children->content);
			}
			else
			{
				/* If the <start> element is present but
				 * has no content use an empty string */
				start = g_strdup ("");
			}
			start_flags = get_regex_flags (child, parser_state->regex_compile_flags);
		}
		else if (xmlStrcmp (BAD_CAST "end", child->name) == 0)
		{
			/* <end> */
			if (child->children != NULL)
				end = g_strdup ((gchar *)child->children->content);
			else
			{
				/* If the <end> element is present but
				 * has no content use an empty string */
				end = g_strdup ("");
			}
			end_flags = get_regex_flags (child, parser_state->regex_compile_flags);
		}
		else if (xmlStrcmp (BAD_CAST "prefix", child->name) == 0)
		{
			/* <prefix> */
			if (child->children != NULL)
				prefix = g_strdup ((gchar*) child->children->content);
			else
				prefix = g_strdup ("");
		}
		else if (xmlStrcmp (BAD_CAST "suffix", child->name) == 0)
		{
			/* <suffix> */
			if (child->children != NULL)
				suffix = g_strdup ((gchar*) child->children->content);
			else
				suffix = g_strdup ("");
		}
		else if (xmlStrcmp (BAD_CAST "keyword", child->name) == 0 &&
			 child->children != NULL)
		{
			/* FIXME: how to specify regex options for keywords?
			 * They can be specified in prefix, so it's not really
			 * important, but would be nice (case-sensitive). */

			/* <keyword> */
			if (all_items == NULL)
			{
				all_items = g_string_new (NULL);

				if (prefix != NULL)
					g_string_append (all_items, prefix);
				else
					g_string_append (all_items,
							 parser_state->opening_delimiter);

				g_string_append (all_items, "(");
				g_string_append (all_items, (gchar*) child->children->content);
			}
			else
			{
				g_string_append (all_items, "|");
				g_string_append (all_items, (gchar*) child->children->content);
			}
		}
	}

	if (all_items != NULL)
	{
		g_string_append (all_items, ")");

		if (suffix != NULL)
			g_string_append (all_items, suffix);
		else
			g_string_append (all_items,
					 parser_state->closing_delimiter);

		match = g_string_free (all_items, FALSE);
		match_flags = parser_state->regex_compile_flags;
	}

	DEBUG (g_message ("start: '%s'", start ? start : "(null)"));
	DEBUG (g_message ("end: '%s'", end ? end : "(null)"));
	DEBUG (g_message ("match: '%s'", match ? match : "(null)"));


	if (tmp_error == NULL && start != NULL)
	{
		gchar *tmp = start;
		start = expand_regex (parser_state, start, start_flags,
				      TRUE, FALSE, &tmp_error);
		g_free (tmp);
	}
	if (tmp_error == NULL && end != NULL)
	{
		gchar *tmp = end;
		end = expand_regex (parser_state, end, end_flags,
				    TRUE, FALSE, &tmp_error);
		g_free (tmp);
	}
	if (tmp_error == NULL && match != NULL)
	{
		gchar *tmp = match;
		match = expand_regex (parser_state, match, match_flags,
				      TRUE, FALSE, &tmp_error);
		g_free (tmp);
	}

	if (tmp_error == NULL)
	{
		_gtk_source_context_data_define_context (parser_state->ctx_data,
							 id,
							 parent_id,
							 match,
							 start,
							 end,
							 style,
							 context_classes,
							 flags,
							 &tmp_error);
	}

	g_free (match);
	g_free (start);
	g_free (end);
	g_free (prefix);
	g_free (suffix);

	if (tmp_error != NULL)
	{
		g_propagate_error (error, tmp_error);
		return FALSE;
	}

	return TRUE;
}

static gboolean
add_ref (ParserState               *parser_state,
	 const gchar               *ref,
	 GtkSourceContextRefOptions options,
	 const gchar               *style,
	 GError	                  **error)
{
	gboolean all = FALSE;
	gchar *ref_id;
	gchar *lang_id = NULL;
	GError *tmp_error = NULL;

	/* Return if an error is already set */
	g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

	if (id_is_decorated (ref, &lang_id))
	{
		if (!lang_id_is_already_loaded (parser_state, lang_id))
		{
			GtkSourceLanguageManager *lm;
			GtkSourceLanguage *imported_language;

			lm = _gtk_source_language_get_language_manager (parser_state->language);
			imported_language = gtk_source_language_manager_get_language (lm, lang_id);

			if (imported_language == NULL)
			{
				g_set_error (&tmp_error,
						PARSER_ERROR,
						PARSER_ERROR_WRONG_ID,
						"unable to resolve language '%s' in ref '%s'",
						lang_id, ref);
			}
			else
			{
				file_parse (imported_language->priv->lang_file_name,
					    parser_state->language,
					    parser_state->ctx_data,
					    parser_state->defined_regexes,
					    parser_state->styles_mapping,
					    parser_state->loaded_lang_ids,
					    parser_state->replacements,
					    &tmp_error);

				if (tmp_error != NULL)
				{
					GError *tmp_error2 = NULL;
					g_set_error (&tmp_error2, PARSER_ERROR, tmp_error->code,
						     "In file '%s' referenced from '%s': %s",
						     imported_language->priv->lang_file_name,
						     parser_state->language->priv->lang_file_name,
						     tmp_error->message);
					g_clear_error (&tmp_error);
					tmp_error = tmp_error2;
				}
			}
		}
		ref_id = g_strdup (ref);
	}
	else
	{
		ref_id = decorate_id (parser_state, ref);
	}

	if (tmp_error == NULL && parser_state->ctx_data != NULL)
	{
		if (g_str_has_suffix (ref, ":*"))
		{
			all = TRUE;
			ref_id [strlen (ref_id) - 2] = '\0';
		}

		if (all && (options & (GTK_SOURCE_CONTEXT_IGNORE_STYLE | GTK_SOURCE_CONTEXT_OVERRIDE_STYLE)))
		{
			g_set_error (&tmp_error, PARSER_ERROR,
				     PARSER_ERROR_WRONG_STYLE,
				     "style override used with wildcard context reference"
				     " in language '%s' in ref '%s'",
				     lang_id != NULL ? lang_id : parser_state->current_lang_id, ref);
		}
	}

	if (tmp_error == NULL && parser_state->ctx_data != NULL)
	{
		gchar *container_id;

		container_id = g_queue_peek_head (parser_state->curr_parents);

		/* If the document is validated container_id is never NULL */
		g_assert (container_id);

		_gtk_source_context_data_add_ref (parser_state->ctx_data,
						  container_id,
						  ref_id,
						  options,
						  style,
						  all,
						  &tmp_error);

		DEBUG (g_message ("appended %s in %s", ref_id, container_id));
	}

	g_free (lang_id);
	g_free (ref_id);

	if (tmp_error != NULL)
	{
		g_propagate_error (error, tmp_error);
		return FALSE;
	}

	return TRUE;
}

static gboolean
create_sub_pattern (ParserState  *parser_state,
                    gchar        *id,
                    gchar        *sub_pattern,
                    gchar        *style,
                    GSList       *context_classes,
                    GError      **error)
{
	gchar *container_id;
	xmlChar *where;

	GError *tmp_error = NULL;

	g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

	container_id = g_queue_peek_head (parser_state->curr_parents);

	/* If the document is validated container is never NULL */
	g_assert (container_id);

	where = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "where");

	_gtk_source_context_data_add_sub_pattern (parser_state->ctx_data,
						  id,
						  container_id,
						  sub_pattern,
						  (gchar*) where,
						  style,
						  context_classes,
						  &tmp_error);

	xmlFree (where);

	if (tmp_error != NULL)
	{
		g_propagate_error (error, tmp_error);
		return FALSE;
	}

	return TRUE;
}

static void
handle_context_element (ParserState *parser_state)
{
	gchar *id, *parent_id, *style_ref;
	xmlChar *ref, *sub_pattern, *tmp;
	int is_empty;
	gboolean success;
	gboolean ignore_style = FALSE;
	GtkSourceContextRefOptions options = 0;
	GSList *context_classes;

	GError *tmp_error = NULL;

	g_return_if_fail (parser_state->error == NULL);

	ref = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "ref");
	sub_pattern = xmlTextReaderGetAttribute (parser_state->reader,
						 BAD_CAST "sub-pattern");

	tmp = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "ignore-style");
	if (tmp != NULL && str_to_bool (tmp))
		ignore_style = TRUE;
	xmlFree (tmp);

	tmp = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "style-ref");
	if (tmp == NULL || id_is_decorated ((gchar*) tmp, NULL))
		style_ref = g_strdup ((gchar*) tmp);
	else
		style_ref = decorate_id (parser_state, (gchar*) tmp);
	xmlFree (tmp);

	if (ignore_style && ref == NULL)
	{
		g_set_error (&parser_state->error,
			     PARSER_ERROR,
			     PARSER_ERROR_WRONG_STYLE,
			     "ignore-style used not in a reference to context");

		xmlFree (ref);
		g_free (style_ref);

		return;
	}

	if (ignore_style)
	{
		options |= GTK_SOURCE_CONTEXT_IGNORE_STYLE;

		if (style_ref != NULL)
			g_warning ("in file %s: style-ref and ignore-style used simultaneously",
				   parser_state->filename);
	}

	/* XXX */
	if (!ignore_style && style_ref != NULL &&
	    g_hash_table_lookup (parser_state->styles_mapping, style_ref) == NULL)
	{
		g_warning ("in file %s: style '%s' not defined", parser_state->filename, style_ref);
	}

	context_classes = parse_classes (parser_state);

	if (ref != NULL)
	{
		tmp = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "original");
		if (tmp != NULL && str_to_bool (tmp))
			options |= GTK_SOURCE_CONTEXT_REF_ORIGINAL;
		xmlFree (tmp);

		if (style_ref != NULL)
			options |= GTK_SOURCE_CONTEXT_OVERRIDE_STYLE;

		add_ref (parser_state,
		         (gchar*) ref,
		         options,
		         style_ref,
		         &tmp_error);
	}
	else
	{
		char *freeme = NULL;

		tmp = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "id");
		if (tmp == NULL)
		{
			freeme = generate_new_id (parser_state);
			tmp = xmlStrdup (BAD_CAST freeme);
		}

		if (id_is_decorated ((gchar*) tmp, NULL))
			id = g_strdup ((gchar*) tmp);
		else
			id = decorate_id (parser_state, (gchar*) tmp);

		g_free (freeme);
		xmlFree (tmp);

		if (parser_state->ctx_data != NULL)
		{
			if (sub_pattern != NULL)
			{
				create_sub_pattern (parser_state,
				                    id,
				                    (gchar *)sub_pattern,
				                    style_ref,
				                    context_classes,
				                    &tmp_error);
			}
			else
			{
				parent_id = g_queue_peek_head (
						parser_state->curr_parents);

				is_empty = xmlTextReaderIsEmptyElement (
						parser_state->reader);

				if (is_empty)
					success = _gtk_source_context_data_define_context (parser_state->ctx_data,
											   id,
											   parent_id,
											   "$^",
											   NULL,
											   NULL,
											   NULL,
											   NULL,
											   0,
											   &tmp_error);
				else
					success = create_definition (parser_state,
					                             id,
					                             parent_id,
					                             style_ref,
					                             context_classes,
					                             &tmp_error);

				if (success && !is_empty)
				{
					/* Push the new context in the curr_parents
					 * stack only if other contexts can be
					 * defined inside it */
					g_queue_push_head (parser_state->curr_parents,
							   g_strdup (id));
				}
			}
		}

		g_free (id);
	}

	g_slist_free_full (context_classes, (GDestroyNotify)gtk_source_context_class_free);

	g_free (style_ref);
	xmlFree (sub_pattern);
	xmlFree (ref);

	if (tmp_error != NULL)
		g_propagate_error (&parser_state->error, tmp_error);
}

static void
handle_replace_element (ParserState *parser_state)
{
	xmlChar *id, *ref;
	GtkSourceContextReplace *repl;
	gchar *replace_with;

	id = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "id");
	ref = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "ref");

	if (id_is_decorated ((gchar*) ref, NULL))
		replace_with = g_strdup ((gchar *) ref);
	else
		replace_with = decorate_id (parser_state, (gchar*) ref);

	repl = _gtk_source_context_replace_new ((const gchar *) id, replace_with);
	g_queue_push_tail (parser_state->replacements, repl);

	g_free (replace_with);
	xmlFree (ref);
	xmlFree (id);
}

static void
handle_language_element (ParserState *parser_state)
{
	/* FIXME: check that the language name, version, etc. are the
	 * right ones - Paolo */
	xmlChar *lang_id, *lang_version;
	xmlChar *expected_version = BAD_CAST "2.0";

	g_return_if_fail (parser_state->error == NULL);

	lang_version = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "version");

	if (lang_version == NULL ||
	    xmlStrcmp (expected_version, lang_version) != 0)
	{
		g_set_error (&parser_state->error,
			     PARSER_ERROR,
			     PARSER_ERROR_WRONG_VERSION,
			     "wrong language version '%s', expected '%s'",
			     lang_version ? (gchar*) lang_version : "(none)",
			     (gchar*) expected_version);
	}
	else
	{
		lang_id = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "id");
		parser_state->current_lang_id = g_strdup ((gchar *) lang_id);
		g_hash_table_insert (parser_state->loaded_lang_ids, lang_id, lang_id);
	}

	xmlFree (lang_version);
}


struct ReplaceByIdData {
	ParserState *parser_state;
	GError *error;
};

static gboolean
replace_by_id (const GMatchInfo *match_info,
	       GString          *expanded_regex,
	       gpointer          user_data)
{
	gchar *id, *subst, *escapes;
	gchar *tmp;
	GError *tmp_error = NULL;

	struct ReplaceByIdData *data = user_data;

	escapes = g_match_info_fetch (match_info, 1);
	tmp = g_match_info_fetch (match_info, 2);

	g_strstrip (tmp);

	if (id_is_decorated (tmp, NULL))
		id = g_strdup (tmp);
	else
		id = decorate_id (data->parser_state, tmp);
	g_free (tmp);

	subst = g_hash_table_lookup (data->parser_state->defined_regexes, id);
	if (subst == NULL)
		g_set_error (&tmp_error,
			     PARSER_ERROR, PARSER_ERROR_WRONG_ID,
			     _("Unknown id “%s” in regex “%s”"), id,
			     g_match_info_get_string (match_info));

	if (tmp_error == NULL)
	{
		g_string_append (expanded_regex, escapes);
		g_string_append (expanded_regex, subst);
	}

	g_free (escapes);
	g_free (id);

	if (tmp_error != NULL)
	{
		g_propagate_error (&data->error, tmp_error);
		return TRUE;
	}

	return FALSE;
}

static GRegexCompileFlags
update_regex_flags (GRegexCompileFlags  flags,
		    const xmlChar      *option_name,
		    const xmlChar      *value)
{
	GRegexCompileFlags single_flag;
	gboolean set_flag;

	DEBUG (g_message ("setting the '%s' regex flag to %s", option_name, value));

	set_flag = str_to_bool (value);

	if (xmlStrcmp (BAD_CAST "case-sensitive", option_name) == 0)
	{
		single_flag = G_REGEX_CASELESS;
		set_flag = !set_flag;
	}
	else if (xmlStrcmp (BAD_CAST "extended", option_name) == 0)
	{
		single_flag = G_REGEX_EXTENDED;
	}
	else if (xmlStrcmp (BAD_CAST "dupnames", option_name) == 0)
	{
		single_flag = G_REGEX_DUPNAMES;
	}
	else
	{
		return flags;
	}

	if (set_flag)
		flags |= single_flag;
	else
		flags &= ~single_flag;

	return flags;
}

static gchar *
expand_regex_vars (ParserState *parser_state, gchar *regex, gint len, GError **error)
{
	/* This is the commented regex without the doubled escape needed
	 * in a C string:
	 *
	 * (?<!\\)(\\\\)*\\%\{([^@]*?)\}
	 * |------------||---||------||-|
	 *      |          |      |    |
	 *      |    the string   |   the ending
	 *      |       "\%{"     |   bracket "}"
	 *      |                 |
	 * a even sequence        |
	 * of escapes or      the id of the
	 * a char that        included regex
	 * is not an          (not greedy)
	 * escape (this
	 * is not matched)
	 *
	 * The first block is needed to ensure that the sequence is
	 * not escaped.
	 * Matches with an id containing a "@" sign are ignored and
	 * passed to the engine because they are references to subpatterns
	 * in a different regex (i.e. in the start regex while we are in the
	 * end regex.)
	 * The sub pattern containing the id is the second.
	 */
	const gchar *re = "(?<!\\\\)(\\\\\\\\)*\\\\%\\{([^@]*?)\\}";
	gchar *expanded_regex;
	GRegex *egg_re;
	struct ReplaceByIdData data;

	if (regex == NULL)
		return NULL;

	egg_re = g_regex_new (re, G_REGEX_NEWLINE_LF, 0, NULL);

	data.parser_state = parser_state;
	data.error = NULL;
	expanded_regex = g_regex_replace_eval (egg_re, regex, len, 0, 0,
					       replace_by_id, &data, NULL);

	if (data.error == NULL)
        {
		DEBUG (g_message ("expanded regex vars '%s' to '%s'",
				  regex, expanded_regex));
        }

	g_regex_unref (egg_re);

	if (data.error != NULL)
	{
		g_free (expanded_regex);
		g_propagate_error (error, data.error);
		return NULL;
	}

	return expanded_regex;
}

static gboolean
replace_delimiter (const GMatchInfo *match_info,
		   GString          *expanded_regex,
		   gpointer          data)
{
	gchar *delim, *escapes;
	ParserState *parser_state = data;

	escapes = g_match_info_fetch (match_info, 1);
	g_string_append (expanded_regex, escapes);

	delim = g_match_info_fetch (match_info, 2);
	DEBUG (g_message ("replacing '\\%%%s'", delim));

	switch (delim[0])
	{
		case '[':
			g_string_append (expanded_regex,
					parser_state->opening_delimiter);
			break;
		case ']':
			g_string_append (expanded_regex,
					parser_state->closing_delimiter);
			break;
		default:
			break;
	}

	g_free (delim);
	g_free (escapes);

	return FALSE;
}

static gchar *
expand_regex_delimiters (ParserState *parser_state,
			 gchar       *regex,
			 gint         len)
{
	/* This is the commented regex without the doubled escape needed
	 * in a C string:
	 *
	 * (?<!\\)(\\\\)*\\%(\[|\])
	 * |------------||---------|
	 *      |             |
	 *      |        the strings
	 *      |        "\%[" or "\%]"
	 *      |
	 * a even sequence of escapes or
	 * a char that is not an escape
	 * (this is not matched)
	 *
	 * The first block is needed to ensure that the sequence is
	 * not escaped.
	 */
	const gchar *re = "(?<!\\\\)(\\\\\\\\)*\\\\%(\\[|\\])";
	gchar *expanded_regex;
	static GRegex *egg_re;

	if (regex == NULL)
		return NULL;

	if (egg_re == NULL)
		egg_re = g_regex_new (re, G_REGEX_NEWLINE_LF | G_REGEX_OPTIMIZE, 0, NULL);

	expanded_regex = g_regex_replace_eval (egg_re, regex, len, 0, 0,
					       replace_delimiter, parser_state, NULL);

	DEBUG (g_message ("expanded regex delims '%s' to '%s'",
				regex, expanded_regex));

	return expanded_regex;
}

static gchar *
expand_regex (ParserState *parser_state,
	      gchar *regex,
	      GRegexCompileFlags flags,
	      gboolean do_expand_vars,
	      gboolean insert_parentheses,
	      GError **error)
{
	gchar *tmp_regex;
	GString *expanded_regex;
	static GRegex *backref_re = NULL;

	g_assert (parser_state != NULL);
	g_return_val_if_fail (error == NULL || *error == NULL, NULL);

	if (regex == NULL)
		return NULL;

	if (backref_re == NULL)
		backref_re = g_regex_new ("(?<!\\\\)(\\\\\\\\)*\\\\[0-9]",
					  G_REGEX_OPTIMIZE | G_REGEX_NEWLINE_LF,
					  0,
					  NULL);

	if (g_regex_match (backref_re, regex, 0, NULL))
	{
		/* This may be a backreference, or it may be an octal character */
		GRegex *compiled;

		compiled = g_regex_new (regex, flags | G_REGEX_NEWLINE_LF, 0, error);

		if (compiled == NULL)
			return NULL;

		if (g_regex_get_max_backref (compiled) > 0)
		{
			g_set_error (error, PARSER_ERROR, PARSER_ERROR_MALFORMED_REGEX,
				     _("in regex “%s”: backreferences are not supported"),
				     regex);
			g_regex_unref (compiled);
			return NULL;
		}

		g_regex_unref (compiled);
	}

	if (do_expand_vars)
	{
		tmp_regex = expand_regex_vars (parser_state, regex, -1, error);

		if (tmp_regex == NULL)
			return NULL;
	}
	else
	{
		tmp_regex = g_strdup (regex);
	}

	regex = tmp_regex;
	tmp_regex = expand_regex_delimiters (parser_state, regex, -1);
	g_free (regex);

	/* Set the options and add not capturing parentheses if
	 * insert_parentheses is TRUE (this is needed for included
	 * regular expressions.) */
	expanded_regex = g_string_new ("");
	if (insert_parentheses)
		g_string_append (expanded_regex, "(?:");
	g_string_append (expanded_regex, "(?");

	if (flags != 0)
	{
		if (flags & G_REGEX_CASELESS)
			g_string_append (expanded_regex, "i");
		if (flags & G_REGEX_EXTENDED)
			g_string_append (expanded_regex, "x");
		/* J is added here if it's used, but -J isn't added
		 * below */
		if (flags & G_REGEX_DUPNAMES)
			g_string_append (expanded_regex, "J");
	}

	if ((flags & (G_REGEX_CASELESS | G_REGEX_EXTENDED)) != (G_REGEX_CASELESS | G_REGEX_EXTENDED))
	{
		g_string_append (expanded_regex, "-");
		if (!(flags & G_REGEX_CASELESS))
			g_string_append (expanded_regex, "i");
		if (!(flags & G_REGEX_EXTENDED))
			g_string_append (expanded_regex, "x");
	}

	g_string_append (expanded_regex, ")");
	g_string_append (expanded_regex, tmp_regex);
	if (insert_parentheses)
	{
		/* The '\n' is needed otherwise, if the regex is "extended"
		 * and it ends with a comment, the ')' is appended inside the
		 * comment itself */
		if (flags & G_REGEX_EXTENDED)
			g_string_append (expanded_regex, "\n");

		/* FIXME: if the regex is not extended this doesn't works */
		g_string_append (expanded_regex, ")");
	}
	g_free (tmp_regex);

	return g_string_free (expanded_regex, FALSE);
}

static void
handle_define_regex_element (ParserState *parser_state)
{
	gchar *id;
	xmlChar *regex;
	xmlChar *tmp;
	gchar *expanded_regex;
	int i;
	const gchar *regex_options[] = {"extended", "case-sensitive", "dupnames", NULL};
	GRegexCompileFlags flags;
	GError *tmp_error = NULL;

	int type;

	g_return_if_fail (parser_state->error == NULL);

	if (parser_state->ctx_data == NULL)
		return;

	tmp = xmlTextReaderGetAttribute (parser_state->reader, BAD_CAST "id");

	/* If the file is validated <define-regex> must have an id
	 * attribute */
	g_assert (tmp != NULL);

	if (id_is_decorated ((gchar *)tmp, NULL))
		id = g_strdup ((gchar *)tmp);
	else
		id = decorate_id (parser_state, (gchar *)tmp);
	xmlFree (tmp);

	flags = parser_state->regex_compile_flags;

	for (i=0; regex_options[i] != NULL; i++)
	{
		tmp = xmlTextReaderGetAttribute (parser_state->reader,
						 BAD_CAST regex_options[i]);
		if (tmp != NULL)
		{
			flags = update_regex_flags (flags,
						    BAD_CAST regex_options[i],
						    tmp);
		}
		xmlFree (tmp);
	}

	xmlTextReaderRead (parser_state->reader);

	type = xmlTextReaderNodeType (parser_state->reader);

	if (type == XML_READER_TYPE_TEXT || type == XML_READER_TYPE_CDATA)
		regex = xmlTextReaderValue (parser_state->reader);
	else
		regex = xmlStrdup (BAD_CAST "");

	expanded_regex = expand_regex (parser_state, (gchar*) regex, flags,
				       TRUE, TRUE, &tmp_error);

	if (tmp_error == NULL)
	{
		DEBUG (g_message ("defined regex %s: \"%s\"", id, (gchar *)regex));
		g_hash_table_insert (parser_state->defined_regexes, id, expanded_regex);
	}
	else
	{
		g_propagate_error (&parser_state->error, tmp_error);
		g_free (id);
	}

	xmlFree (regex);
}

static void
handle_default_regex_options_element (ParserState *parser_state)
{
	xmlNode *elm;

	g_return_if_fail (parser_state->error == NULL);

	if (parser_state->ctx_data == NULL)
		return;

	elm = xmlTextReaderCurrentNode (parser_state->reader);

	parser_state->regex_compile_flags = get_regex_flags (elm, 0);
}

static void
parse_language_with_id (ParserState *parser_state,
			gchar       *lang_id)
{
	GtkSourceLanguageManager *lm;
	GtkSourceLanguage *imported_language;

	g_return_if_fail (parser_state->error == NULL);

	lm = _gtk_source_language_get_language_manager (parser_state->language);
	imported_language = gtk_source_language_manager_get_language (lm, lang_id);

	if (imported_language == NULL)
	{
		g_set_error (&parser_state->error,
			     PARSER_ERROR,
			     PARSER_ERROR_WRONG_ID,
			     "unable to resolve language '%s'",
			     lang_id);
	}
	else
	{
		file_parse (imported_language->priv->lang_file_name,
			    parser_state->language,
			    parser_state->ctx_data,
			    parser_state->defined_regexes,
			    parser_state->styles_mapping,
			    parser_state->loaded_lang_ids,
			    parser_state->replacements,
			    &parser_state->error);
	}
}

static void
parse_style (ParserState *parser_state)
{
	gchar *id;
	xmlChar *name, *map_to;
	xmlChar *tmp;
	gchar *lang_id = NULL;

	g_return_if_fail (parser_state->error == NULL);

	tmp = xmlTextReaderGetAttribute (parser_state->reader,
					 BAD_CAST "id");

	if (id_is_decorated ((gchar*) tmp, NULL))
		id = g_strdup ((gchar*) tmp);
	else
		id = decorate_id (parser_state, (gchar*) tmp);

	xmlFree (tmp);

	name = xmlTextReaderGetAttribute (parser_state->reader,
					  BAD_CAST "_name");

	if (name != NULL)
	{
		gchar *tmp2 = _gtk_source_language_translate_string (parser_state->language,
								     (gchar*) name);
		tmp = xmlStrdup (BAD_CAST tmp2);
		xmlFree (name);
		name = tmp;
		g_free (tmp2);
	}
	else
	{
		name = xmlTextReaderGetAttribute (parser_state->reader,
						  BAD_CAST "name");
	}

	map_to = xmlTextReaderGetAttribute (parser_state->reader,
					    BAD_CAST "map-to");

	if (map_to != NULL && !id_is_decorated ((gchar*) map_to, &lang_id))
	{
		g_set_error (&parser_state->error,
			     PARSER_ERROR,
			     PARSER_ERROR_MALFORMED_MAP_TO,
			     "the map-to attribute '%s' for the style '%s' lacks the prefix",
			     map_to, id);
	}

	if (parser_state->error == NULL && lang_id != NULL && lang_id[0] == 0)
	{
		g_free (lang_id);
		lang_id = NULL;
	}

	if (parser_state->error == NULL && lang_id != NULL &&
	    !lang_id_is_already_loaded (parser_state, lang_id))
	{
		parse_language_with_id (parser_state, lang_id);
	}

	DEBUG (g_message ("style %s (%s) to be mapped to '%s'",
			  name, id, map_to ? (char*) map_to : "(null)"));

	if (map_to != NULL &&
	    g_hash_table_lookup (parser_state->styles_mapping, map_to) == NULL)
	{
		g_warning ("in file %s: style '%s' not defined", parser_state->filename, map_to);
	}

	if (parser_state->error == NULL)
	{

		GtkSourceStyleInfo *info;

		/* Remember the style name only if the style has been defined in
		 * the lang file we are parsing */
		if (g_str_has_prefix (id, parser_state->language_decoration))
			info = _gtk_source_style_info_new ((gchar *) name,
							   (gchar *) map_to);
		else
			info = _gtk_source_style_info_new (NULL,
							   (gchar *) map_to);

		g_hash_table_insert (parser_state->styles_mapping, g_strdup (id), info);
	}

	g_free (lang_id);
	g_free (id);
	xmlFree (name);
	xmlFree (map_to);
}

static void
handle_keyword_char_class_element (ParserState *parser_state)
{
	xmlChar *char_class;
	int ret, type;

	g_return_if_fail (parser_state->error == NULL);

	if (parser_state->ctx_data == NULL)
		return;

	do {
		ret = xmlTextReaderRead (parser_state->reader);
		g_assert (ret == 1);
		type = xmlTextReaderNodeType (parser_state->reader);
	}
	while (type != XML_READER_TYPE_TEXT && type != XML_READER_TYPE_CDATA);

	char_class = xmlTextReaderValue (parser_state->reader);

	g_free (parser_state->opening_delimiter);
	g_free (parser_state->closing_delimiter);

	parser_state->opening_delimiter = g_strdup_printf ("(?<!%s)(?=%s)",
							   char_class, char_class);
	parser_state->closing_delimiter = g_strdup_printf ("(?<=%s)(?!%s)",
							   char_class, char_class);

	xmlFree (char_class);
}

static void
handle_styles_element (ParserState *parser_state)
{
	int type;
	const xmlChar *tag_name;

	g_return_if_fail (parser_state->error == NULL);

	while (parser_state->error == NULL)
	{
		/* FIXME: is xmlTextReaderIsValid call needed here or
		 * error func will be called? */
		xmlTextReaderRead (parser_state->reader);
		xmlTextReaderIsValid (parser_state->reader);

		if (parser_state->error != NULL)
			break;

		tag_name = xmlTextReaderConstName (parser_state->reader);
		type = xmlTextReaderNodeType  (parser_state->reader);

		/* End at the closing </styles> tag */
		if (tag_name && type == XML_READER_TYPE_END_ELEMENT &&
		    !xmlStrcmp (BAD_CAST "styles", tag_name))
			break;

		/* Skip nodes that aren't <style> elements */
		if (tag_name == NULL || xmlStrcmp (BAD_CAST "style", tag_name))
			continue;

		/* Handle <style> elements */
		parse_style (parser_state);
	}
}


static void
element_start (ParserState *parser_state)
{
	const xmlChar *name;

	g_return_if_fail (parser_state->error == NULL);

	/* TODO: check the namespace and ignore everithing is not in our namespace */
	name = xmlTextReaderConstName (parser_state->reader);

	if (xmlStrcmp (BAD_CAST "context", name) == 0)
		handle_context_element (parser_state);
	else if (xmlStrcmp (BAD_CAST "replace", name) == 0)
		handle_replace_element (parser_state);
	else if (xmlStrcmp (BAD_CAST "define-regex", name) == 0)
		handle_define_regex_element (parser_state);
	else if (xmlStrcmp (BAD_CAST "language", name) == 0)
		handle_language_element (parser_state);
	else if (xmlStrcmp (BAD_CAST "styles", name) == 0)
		handle_styles_element (parser_state);
	else if (xmlStrcmp (BAD_CAST "keyword-char-class", name) == 0)
		handle_keyword_char_class_element (parser_state);
	else if (xmlStrcmp (BAD_CAST "default-regex-options", name) == 0)
		handle_default_regex_options_element (parser_state);
}

static void
element_end (ParserState *parser_state)
{
	const xmlChar *name;
	gchar *popped_id;

	name = xmlTextReaderConstName (parser_state->reader);

	if (xmlStrcmp (name, BAD_CAST "context") == 0)
	{
		/* pop the first element in the curr_parents list */
		popped_id = g_queue_pop_head (parser_state->curr_parents);
		g_free (popped_id);
	}
}

static void
text_reader_structured_error_func (ParserState *parser_state,
				   xmlErrorPtr  error)
{
	/* FIXME: does someone know how to use libxml api? */

	if (parser_state->error == NULL)
		g_set_error (&parser_state->error,
			     PARSER_ERROR,
			     PARSER_ERROR_INVALID_DOC,
			     "in file %s on line %d: %s\n",
			     error->file,
			     error->line,
			     error->message);
	else
		/* extra warning won't hurt and it could give a clue about what's wrong */
		g_warning ("in file %s on line %d: %s\n", error->file, error->line, error->message);
}

static gboolean
file_parse (gchar                     *filename,
	    GtkSourceLanguage         *language,
	    GtkSourceContextData      *ctx_data,
	    GHashTable                *defined_regexes,
	    GHashTable                *styles,
	    GHashTable                *loaded_lang_ids,
	    GQueue                    *replacements,
	    GError                   **error)
{
	ParserState *parser_state;
	xmlTextReader *reader = NULL;
	int fd = -1;
	GError *tmp_error = NULL;
	GtkSourceLanguageManager *lm;
	const gchar *rng_lang_schema;

	g_return_val_if_fail (error == NULL || *error == NULL, FALSE);

	DEBUG (g_message ("loading file '%s'", filename));

	/*
	 * Use fd instead of filename so that it's utf8 safe on w32.
	 */
	fd = g_open (filename, O_RDONLY, 0);

	if (fd != -1)
		reader = xmlReaderForFd (fd, filename, NULL, 0);

	if (reader == NULL)
	{
		g_set_error (&tmp_error,
			     PARSER_ERROR,
			     PARSER_ERROR_CANNOT_OPEN,
			     "unable to open the file");
		goto error;
	}

	lm = _gtk_source_language_get_language_manager (language);
	rng_lang_schema = _gtk_source_language_manager_get_rng_file (lm);

	if (rng_lang_schema == NULL)
	{
		g_set_error (&tmp_error,
			     PARSER_ERROR,
			     PARSER_ERROR_CANNOT_VALIDATE,
			     "could not find the RelaxNG schema file");
		goto error;
	}

	if (xmlTextReaderRelaxNGValidate (reader, rng_lang_schema))
	{
		g_set_error (&tmp_error,
			     PARSER_ERROR,
			     PARSER_ERROR_CANNOT_VALIDATE,
			     "unable to load the RelaxNG schema '%s'",
			     rng_lang_schema);
		goto error;
	}

	parser_state = parser_state_new (language, ctx_data,
					 defined_regexes, styles,
					 replacements, reader,
					 filename, loaded_lang_ids);
	xmlTextReaderSetStructuredErrorHandler (reader,
						(xmlStructuredErrorFunc) text_reader_structured_error_func,
						parser_state);

	while ((parser_state->error == NULL) &&
	        (1 == xmlTextReaderRead (parser_state->reader)))
	{
		int type;

		/* FIXME: does xmlTextReaderRead already do it? */
		xmlTextReaderIsValid (parser_state->reader);

		if (parser_state->error != NULL)
			break;

		type = xmlTextReaderNodeType (parser_state->reader);

		switch (type)
		{
			case XML_READER_TYPE_ELEMENT:
				element_start (parser_state);
				break;
			case XML_READER_TYPE_END_ELEMENT:
				element_end (parser_state);
				break;
			default:
				break;
		}
	}

	if (parser_state->error != NULL)
	{
		g_propagate_error (&tmp_error, parser_state->error);
		parser_state->error = NULL;
	}

	parser_state_destroy (parser_state);

	if (tmp_error != NULL)
		goto error;

	close (fd);

	return TRUE;

error:
	if (fd != -1)
		close (fd);
	g_propagate_error (error, tmp_error);
	return FALSE;
}

static ParserState *
parser_state_new (GtkSourceLanguage       *language,
		  GtkSourceContextData    *ctx_data,
		  GHashTable              *defined_regexes,
		  GHashTable              *styles_mapping,
		  GQueue                  *replacements,
		  xmlTextReader	          *reader,
		  const char              *filename,
		  GHashTable              *loaded_lang_ids)
{
	ParserState *parser_state;
	parser_state = g_slice_new0 (ParserState);

	parser_state->language = language;
	parser_state->ctx_data = ctx_data;

	g_return_val_if_fail (language->priv->id != NULL, NULL);
	parser_state->language_decoration = g_strdup_printf ("%s:", language->priv->id);

	parser_state->current_lang_id = NULL;

	parser_state->id_cookie = 0;
	parser_state->regex_compile_flags = 0;

	parser_state->reader = reader;
	parser_state->filename = g_filename_display_name (filename);
	parser_state->error = NULL;

	parser_state->defined_regexes = defined_regexes;
	parser_state->styles_mapping = styles_mapping;
	parser_state->replacements = replacements;

	parser_state->loaded_lang_ids = loaded_lang_ids;

	parser_state->curr_parents = g_queue_new ();

	parser_state->opening_delimiter = g_strdup ("\\b");
	parser_state->closing_delimiter = g_strdup ("\\b");

	return parser_state;
}

static void
parser_state_destroy (ParserState *parser_state)
{
	if (parser_state->reader != NULL)
		xmlFreeTextReader (parser_state->reader);

	g_clear_error (&parser_state->error);

	g_queue_free (parser_state->curr_parents);
	g_free (parser_state->current_lang_id);

	g_free (parser_state->opening_delimiter);
	g_free (parser_state->closing_delimiter);

	g_free (parser_state->language_decoration);
	g_free (parser_state->filename);

	g_slice_free (ParserState, parser_state);
}

static gboolean
steal_styles_mapping (gchar              *style_id,
		      GtkSourceStyleInfo *info,
		      GHashTable         *styles)
{
	g_hash_table_insert (styles, style_id, info);
	return TRUE;
}

gboolean
_gtk_source_language_file_parse_version2 (GtkSourceLanguage       *language,
					  GtkSourceContextData    *ctx_data)
{
	GHashTable *defined_regexes, *styles;
	gboolean success;
	GError *error = NULL;
	gchar *filename;
	GHashTable *loaded_lang_ids;
	GQueue *replacements;

	g_return_val_if_fail (ctx_data != NULL, FALSE);

	filename = language->priv->lang_file_name;

	/* TODO: as an optimization tell the parser to merge CDATA
	 * as text nodes (XML_PARSE_NOCDATA), and to ignore blank
	 * nodes (XML_PARSE_NOBLANKS), if it is possible with
	 * xmlTextReader. */
	xmlKeepBlanksDefault (0);
	xmlLineNumbersDefault (1);
	xmlSubstituteEntitiesDefault (1);
	DEBUG (xmlPedanticParserDefault (1));

	defined_regexes = g_hash_table_new_full (g_str_hash, g_str_equal,
						 g_free, g_free);
	styles = g_hash_table_new_full (g_str_hash,
					g_str_equal,
					g_free,
					(GDestroyNotify) _gtk_source_style_info_free);
	loaded_lang_ids = g_hash_table_new_full (g_str_hash, g_str_equal,
						 (GDestroyNotify) xmlFree,
						 NULL);
	replacements = g_queue_new ();

	success = file_parse (filename, language, ctx_data,
			      defined_regexes, styles,
			      loaded_lang_ids, replacements,
			      &error);

	if (success)
		success = _gtk_source_context_data_finish_parse (ctx_data, replacements->head, &error);

	if (success)
		g_hash_table_foreach_steal (styles,
					    (GHRFunc) steal_styles_mapping,
					    language->priv->styles);

	g_queue_foreach (replacements, (GFunc) _gtk_source_context_replace_free, NULL);
	g_queue_free (replacements);
	g_hash_table_destroy (loaded_lang_ids);
	g_hash_table_destroy (defined_regexes);
	g_hash_table_destroy (styles);

	if (!success)
	{
		g_warning ("Failed to load '%s': %s",
			   filename, error->message);
		g_clear_error (&error);
		return FALSE;
	}

	return TRUE;
}
