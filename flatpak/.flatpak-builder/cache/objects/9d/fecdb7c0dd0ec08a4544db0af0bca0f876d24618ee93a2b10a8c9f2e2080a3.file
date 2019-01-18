/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2017 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "as-yaml.h"
#include "as-utils.h"
#include "as-utils-private.h"

/**
 * SECTION:as-yaml
 * @short_description: Helper functions to parse AppStream YAML data
 * @include: appstream.h
 */

enum YamlNodeKind {
	YAML_VAR,
	YAML_VAL,
	YAML_SEQ
};

/**
 * as_str_is_numeric:
 *
 * Check if string is a number.
 */
static gboolean
as_str_is_numeric (const gchar *s)
{
	gchar *p;

	if (s == NULL || *s == '\0' || g_ascii_isspace (*s))
		return FALSE;
	strtod (s, &p);
	return *p == '\0';
}

/**
 * as_yaml_parse_layer:
 *
 * Create GNode tree from DEP-11 YAML document
 */
void
as_yaml_parse_layer (yaml_parser_t *parser, GNode *data, GError **error)
{
	GNode *last_leaf = data;
	GNode *last_scalar;
	yaml_event_t event;
	gboolean parse = TRUE;
	gboolean in_sequence = FALSE;
	GError *tmp_error = NULL;
	gchar *string_scalar;
	int storage = YAML_VAR; /* the first element must always be of type VAR */

	while (parse) {
		if (!yaml_parser_parse (parser, &event)) {
			g_set_error (error,
					AS_METADATA_ERROR,
					AS_METADATA_ERROR_PARSE,
					"Invalid DEP-11 file found. Could not parse YAML: %s", parser->problem);
			break;
		}

		/* Parse value either as a new leaf in the mapping
		 * or as a leaf value (one of them, in case it's a sequence) */
		switch (event.type) {
			case YAML_SCALAR_EVENT:
				string_scalar = g_strdup ((gchar*) event.data.scalar.value);
				g_strstrip (string_scalar);
				if (storage)
					g_node_append_data (last_leaf, string_scalar);
				else
					last_leaf = g_node_append (data, g_node_new (string_scalar));
				storage ^= YAML_VAL;
				break;
			case YAML_SEQUENCE_START_EVENT:
				storage = YAML_SEQ;
				in_sequence = TRUE;
				break;
			case YAML_SEQUENCE_END_EVENT:
				storage = YAML_VAR;
				in_sequence = FALSE;
				break;
			case YAML_MAPPING_START_EVENT:
				/* depth += 1 */
				last_scalar = last_leaf;
				if (in_sequence)
					last_leaf = g_node_append (last_leaf, g_node_new (NULL));

				as_yaml_parse_layer (parser, last_leaf, &tmp_error);
				if (tmp_error != NULL) {
					g_propagate_error (error, tmp_error);
					parse = FALSE;
				}

				last_leaf = last_scalar;
				storage ^= YAML_VAL; /* Flip VAR/VAL, without touching SEQ */
				break;
			case YAML_MAPPING_END_EVENT:
			case YAML_STREAM_END_EVENT:
			case YAML_DOCUMENT_END_EVENT:
				/* depth -= 1 */
				parse = FALSE;
				break;
			default:
				break;
		}

		yaml_event_delete (&event);
	}
}

/**
 * as_yaml_free_node:
 */
gboolean
as_yaml_free_node (GNode *node, gpointer data)
{
	if (node->data != NULL)
		g_free (node->data);

	return FALSE;
}

/**
 * as_yaml_node_get_key:
 *
 * Helper method to get the key of a node.
 */
const gchar*
as_yaml_node_get_key (GNode *n)
{
	return (const gchar*) n->data;
}

/**
 * as_yaml_node_get_value:
 *
 * Helper method to get the value of a node.
 */
const gchar*
as_yaml_node_get_value (GNode *n)
{
	if (n->children)
		return (const gchar*) n->children->data;
	else
		return NULL;
}

/**
 * as_yaml_print_unknown:
 */
void
as_yaml_print_unknown (const gchar *root, const gchar *key)
{
	g_debug ("YAML: Unknown field '%s/%s' found.", root, key);
}

/**
 * as_yaml_mapping_start:
 */
void
as_yaml_mapping_start (yaml_emitter_t *emitter)
{
	yaml_event_t event;

	yaml_mapping_start_event_initialize (&event, NULL, NULL, 1, YAML_ANY_MAPPING_STYLE);
	g_assert (yaml_emitter_emit (emitter, &event));
}

/**
 * as_yaml_mapping_end:
 */
void
as_yaml_mapping_end (yaml_emitter_t *emitter)
{
	yaml_event_t event;

	yaml_mapping_end_event_initialize (&event);
	g_assert (yaml_emitter_emit (emitter, &event));
}

/**
 * as_yaml_sequence_start:
 */
void
as_yaml_sequence_start (yaml_emitter_t *emitter)
{
	yaml_event_t event;

	yaml_sequence_start_event_initialize (&event, NULL, NULL, 1, YAML_ANY_SEQUENCE_STYLE);
	g_assert (yaml_emitter_emit (emitter, &event));
}

/**
 * as_yaml_sequence_end:
 */
void
as_yaml_sequence_end (yaml_emitter_t *emitter)
{
	yaml_event_t event;

	yaml_sequence_end_event_initialize (&event);
	g_assert (yaml_emitter_emit (emitter, &event));
}

/**
 * as_yaml_emit_scalar:
 */
void
as_yaml_emit_scalar (yaml_emitter_t *emitter, const gchar *value)
{
	gint ret;
	yaml_event_t event;
	yaml_scalar_style_t style;
	g_assert (value != NULL);

	/* we always want the values to be represented as strings, and not have e.g. Python recognize them as ints later */
	style = YAML_ANY_SCALAR_STYLE;
	if (as_str_is_numeric (value))
		style = YAML_SINGLE_QUOTED_SCALAR_STYLE;

	yaml_scalar_event_initialize (&event,
					NULL,
					NULL,
					(yaml_char_t*) value,
					strlen (value),
					TRUE,
					TRUE,
					style);
	ret = yaml_emitter_emit (emitter, &event);
	g_assert (ret);
}

/**
 * as_yaml_emit_scalar_uint:
 */
void
as_yaml_emit_scalar_uint (yaml_emitter_t *emitter, guint value)
{
	gint ret;
	yaml_event_t event;
	g_autofree gchar *value_str = NULL;

	value_str = g_strdup_printf("%i", value);
	yaml_scalar_event_initialize (&event,
					NULL,
					NULL,
					(yaml_char_t*) value_str,
					strlen (value_str),
					TRUE,
					TRUE,
					YAML_ANY_SCALAR_STYLE);
	ret = yaml_emitter_emit (emitter, &event);
	g_assert (ret);
}

/**
 * as_yaml_emit_scalar_key:
 */
void
as_yaml_emit_scalar_key (yaml_emitter_t *emitter, const gchar *key)
{
	yaml_scalar_style_t keystyle;
	yaml_event_t event;
	gint ret;

	/* Some locale are "no", which - if unquoted - are interpreted as booleans.
	 * Since we hever have boolean keys, we can disallow creating bool keys for all keys. */
	keystyle = YAML_ANY_SCALAR_STYLE;
	if (g_strcmp0 (key, "no") == 0)
		keystyle = YAML_SINGLE_QUOTED_SCALAR_STYLE;
	if (g_strcmp0 (key, "yes") == 0)
		keystyle = YAML_SINGLE_QUOTED_SCALAR_STYLE;

	yaml_scalar_event_initialize (&event,
					NULL,
					NULL,
					(yaml_char_t*) key,
					strlen (key),
					TRUE,
					TRUE,
					keystyle);
	ret = yaml_emitter_emit (emitter, &event);
	g_assert (ret);
}

/**
 * as_yaml_emit_entry:
 */
void
as_yaml_emit_entry (yaml_emitter_t *emitter, const gchar *key, const gchar *value)
{
	if (value == NULL)
		return;

	as_yaml_emit_scalar_key (emitter, key);
	as_yaml_emit_scalar (emitter, value);
}

/**
 * as_yaml_emit_entry_uint:
 */
void
as_yaml_emit_entry_uint (yaml_emitter_t *emitter, const gchar *key, guint value)
{
	as_yaml_emit_scalar_key (emitter, key);
	as_yaml_emit_scalar_uint (emitter, value);
}

/**
 * as_yaml_emit_entry_timestamp:
 */
void
as_yaml_emit_entry_timestamp (yaml_emitter_t *emitter, const gchar *key, guint64 unixtime)
{
	g_autofree gchar *time_str = NULL;
	yaml_event_t event;
	gint ret;

	as_yaml_emit_scalar_key (emitter, key);

	time_str = g_strdup_printf ("%" G_GUINT64_FORMAT, unixtime);
	yaml_scalar_event_initialize (&event,
					NULL,
					NULL,
					(yaml_char_t*) time_str,
					strlen (time_str),
					TRUE,
					TRUE,
					YAML_ANY_SCALAR_STYLE);
	ret = yaml_emitter_emit (emitter, &event);
	g_assert (ret);

}

/**
 * as_yaml_emit_long_entry:
 */
void
as_yaml_emit_long_entry (yaml_emitter_t *emitter, const gchar *key, const gchar *value)
{
	yaml_event_t event;
	gint ret;

	if (value == NULL)
		return;

	as_yaml_emit_scalar_key (emitter, key);
	yaml_scalar_event_initialize (&event,
					NULL,
					NULL,
					(yaml_char_t*) value,
					strlen (value),
					TRUE,
					TRUE,
					YAML_FOLDED_SCALAR_STYLE);
	ret = yaml_emitter_emit (emitter, &event);
	g_assert (ret);
}

/**
 * as_yaml_emit_sequence:
 */
void
as_yaml_emit_sequence (yaml_emitter_t *emitter, const gchar *key, GPtrArray *list)
{
	guint i;

	if (list == NULL)
		return;
	if (list->len == 0)
		return;

	as_yaml_emit_scalar (emitter, key);

	as_yaml_sequence_start (emitter);
	for (i = 0; i < list->len; i++) {
		const gchar *value = (const gchar *) g_ptr_array_index (list, i);
		as_yaml_emit_scalar (emitter, value);
	}
	as_yaml_sequence_end (emitter);
}

/**
 * as_yaml_get_node_locale:
 * @node: A YAML node
 *
 * Returns: The locale of a node, if the node should be considered for inclusion.
 * %NULL if the node should be ignored due to a not-matching locale.
 */
const gchar*
as_yaml_get_node_locale (AsContext *ctx, GNode *node)
{
	const gchar *key = as_yaml_node_get_key (node);

	if (as_context_get_all_locale_enabled (ctx)) {
		/* we should read all languages */
		return key;
	}

	/* we always include the untranslated strings */
	if (g_strcmp0 (key, "C") == 0) {
		return key;
	}

	if (as_utils_locale_is_compatible (as_context_get_locale (ctx), key)) {
		return key;
	} else {
		/* If we are here, we haven't found a matching locale.
		 * In that case, we return %NULL to indicate that this element should not be added.
		 */
		return NULL;
	}
}

/**
 * as_yaml_set_localized_table:
 *
 * Apply node values to a hash table holding the l10n data.
 */
void
as_yaml_set_localized_table (AsContext *ctx, GNode *node, GHashTable *l10n_table)
{
	GNode *n;

	for (n = node->children; n != NULL; n = n->next) {
		const gchar *locale = as_yaml_get_node_locale (ctx, n);
		if (locale != NULL)
			g_hash_table_insert (l10n_table,
						as_locale_strip_encoding (g_strdup (locale)),
						g_strdup (as_yaml_node_get_value (n)));
	}
}

/**
 * as_yaml_emit_localized_entry_with_func:
 */
static void
as_yaml_emit_localized_entry_with_func (yaml_emitter_t *emitter, const gchar *key, GHashTable *ltab, GHFunc tfunc)
{
	if (ltab == NULL)
		return;
	if (g_hash_table_size (ltab) == 0)
		return;

	as_yaml_emit_scalar (emitter, key);

	/* start mapping for localized entry */
	as_yaml_mapping_start (emitter);
	/* emit entries */
	g_hash_table_foreach (ltab,
				tfunc,
				emitter);
	/* finalize */
	as_yaml_mapping_end (emitter);
}

/**
 * as_yaml_emit_lang_hashtable_entries:
 */
static void
as_yaml_emit_lang_hashtable_entries (gchar *key, gchar *value, yaml_emitter_t *emitter)
{
	if (as_str_empty (value))
		return;

	/* skip cruft */
	if (as_is_cruft_locale (key))
		return;

	g_strstrip (value);
	as_yaml_emit_entry (emitter, key, value);
}

/**
 * as_yaml_emit_localized_entry:
 */
void
as_yaml_emit_localized_entry (yaml_emitter_t *emitter, const gchar *key, GHashTable *ltab)
{
	as_yaml_emit_localized_entry_with_func (emitter,
						key,
						ltab,
						(GHFunc) as_yaml_emit_lang_hashtable_entries);
}

/**
 * as_yaml_emit_lang_hashtable_entries_long:
 */
static void
as_yaml_emit_lang_hashtable_entries_long (gchar *key, gchar *value, yaml_emitter_t *emitter)
{
	if (as_str_empty (value))
		return;

	/* skip cruft */
	if (as_is_cruft_locale (key))
		return;

	g_strstrip (value);
	as_yaml_emit_long_entry (emitter, key, value);
}

/**
 * as_yaml_emit_long_localized_entry:
 */
void
as_yaml_emit_long_localized_entry (yaml_emitter_t *emitter, const gchar *key, GHashTable *ltab)
{
	as_yaml_emit_localized_entry_with_func (emitter,
						key,
						ltab,
						(GHFunc) as_yaml_emit_lang_hashtable_entries_long);
}

/**
 * as_yaml_list_to_str_array:
 */
void
as_yaml_list_to_str_array (GNode *node, GPtrArray *array)
{
	GNode *n;

	for (n = node->children; n != NULL; n = n->next) {
		const gchar *val = as_yaml_node_get_key (n);
		if (val != NULL)
			g_ptr_array_add (array, g_strdup (val));
	}
}

/**
 * as_yaml_emit_sequence_from_str_array:
 */
void
as_yaml_emit_sequence_from_str_array (yaml_emitter_t *emitter, const gchar *key, GPtrArray *array)
{
	guint i;

	if (array == NULL)
		return;
	if (array->len == 0)
		return;

	as_yaml_emit_scalar_key (emitter, key);
	as_yaml_sequence_start (emitter);

	for (i = 0; i < array->len; i++) {
		const gchar *val = (const gchar*) g_ptr_array_index (array, i);
		as_yaml_emit_scalar (emitter, val);
	}

	as_yaml_sequence_end (emitter);
}

/**
 * as_yaml_localized_list_helper:
 */
static void
as_yaml_localized_list_helper (gchar *key, gchar **strv, yaml_emitter_t *emitter)
{
	guint i;
	if (strv == NULL)
		return;

	/* skip cruft */
	if (as_is_cruft_locale (key))
		return;

	as_yaml_emit_scalar (emitter, key);
	as_yaml_sequence_start (emitter);
	for (i = 0; strv[i] != NULL; i++) {
		as_yaml_emit_scalar (emitter, strv[i]);
	}
	as_yaml_sequence_end (emitter);
}

/**
 * as_yaml_emit_localized_strv:
 */
void
as_yaml_emit_localized_strv (yaml_emitter_t *emitter, const gchar *key, GHashTable *ltab)
{
	if (ltab == NULL)
		return;
	if (g_hash_table_size (ltab) == 0)
		return;

	as_yaml_emit_scalar (emitter, key);

	/* start mapping for localized entry */
	as_yaml_mapping_start (emitter);
	/* emit entries */
	g_hash_table_foreach (ltab,
				(GHFunc) as_yaml_localized_list_helper,
				emitter);
	/* finalize */
	as_yaml_mapping_end (emitter);
}
