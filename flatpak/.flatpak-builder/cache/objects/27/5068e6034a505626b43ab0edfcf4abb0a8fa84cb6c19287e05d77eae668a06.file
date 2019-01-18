/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016 Richard Hughes <richard@hughsie.com>
 * Copyright (C) 2016 Matthias Klumpp <matthias@tenstral.net>
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

#include "as-spdx.h"

#include <config.h>
#include <string.h>
#include <gio/gio.h>

#include "as-resources.h"
#include "as-utils-private.h"

/**
 * SECTION:as-spdx
 * @short_description: Helper functions to work with SPDX license descriptions.
 * @include: appstream.h
 *
 */

typedef struct {
	gboolean	 last_token_literal;
	GPtrArray	*array;
	GString		*collect;
} AsSpdxHelper;

static gpointer
_g_ptr_array_last (GPtrArray *array)
{
	return g_ptr_array_index (array, array->len - 1);
}

/**
 * as_spdx_license_tokenize_drop:
 *
 * Helper function for as_spdx_license_tokenize().
 */
static void
as_spdx_license_tokenize_drop (AsSpdxHelper *helper)
{
	const gchar *tmp = helper->collect->str;
	guint i;
	g_autofree gchar *last_literal = NULL;
	struct {
		const gchar	*old;
		const gchar	*new;
	} licenses[] =  {
		{ "CC0",	"CC0-1.0" },
		{ "CC-BY",	"CC-BY-3.0" },
		{ "CC-BY-SA",	"CC-BY-SA-3.0" },
		{ "GFDL",	"GFDL-1.3" },
		{ "GPL-2",	"GPL-2.0" },
		{ "GPL-3",	"GPL-3.0" },
		{ "proprietary", "LicenseRef-proprietary" },
		{ NULL, NULL } };

	/* nothing from last time */
	if (helper->collect->len == 0)
		return;

	/* is license enum */
	if (as_is_spdx_license_id (tmp)) {
		g_ptr_array_add (helper->array, g_strdup_printf ("@%s", tmp));
		helper->last_token_literal = FALSE;
		g_string_truncate (helper->collect, 0);
		return;
	}

	/* is license enum with "+" */
	if (g_str_has_suffix (tmp, "+")) {
		g_autofree gchar *license_id = g_strndup (tmp, strlen (tmp) - 1);
		if (as_is_spdx_license_id (license_id)) {
			g_ptr_array_add (helper->array, g_strdup_printf ("@%s", license_id));
			g_ptr_array_add (helper->array, g_strdup ("+"));
			helper->last_token_literal = FALSE;
			g_string_truncate (helper->collect, 0);
			return;
		}
	}

	/* is old license enum */
	for (i = 0; licenses[i].old != NULL; i++) {
		if (g_strcmp0 (tmp, licenses[i].old) != 0)
			continue;
		g_ptr_array_add (helper->array,
				 g_strdup_printf ("@%s", licenses[i].new));
		helper->last_token_literal = FALSE;
		g_string_truncate (helper->collect, 0);
		return;
	}

	/* is conjunctive */
	if (g_strcmp0 (tmp, "and") == 0 || g_strcmp0 (tmp, "AND") == 0) {
		g_ptr_array_add (helper->array, g_strdup ("&"));
		helper->last_token_literal = FALSE;
		g_string_truncate (helper->collect, 0);
		return;
	}

	/* is disjunctive */
	if (g_strcmp0 (tmp, "or") == 0 || g_strcmp0 (tmp, "OR") == 0) {
		g_ptr_array_add (helper->array, g_strdup ("|"));
		helper->last_token_literal = FALSE;
		g_string_truncate (helper->collect, 0);
		return;
	}

	/* is literal */
	if (helper->last_token_literal) {
		last_literal = g_strdup (_g_ptr_array_last (helper->array));
		g_ptr_array_remove_index (helper->array, helper->array->len - 1);
		g_ptr_array_add (helper->array,
				 g_strdup_printf ("%s %s", last_literal, tmp));
	} else {
		g_ptr_array_add (helper->array, g_strdup (tmp));
		helper->last_token_literal = TRUE;
	}
	g_string_truncate (helper->collect, 0);
}

/**
 * as_is_spdx_license_id:
 * @license_id: a single SPDX license ID, e.g. "GPL-3.0"
 *
 * Searches the known list of SPDX license IDs.
 *
 * Returns: %TRUE if the icon is a valid "SPDX license ID"
 *
 * Since: 0.9.8
 **/
gboolean
as_is_spdx_license_id (const gchar *license_id)
{
	g_autoptr(GBytes) data = NULL;
	g_autofree gchar *key = NULL;

	/* handle invalid */
	if (license_id == NULL || license_id[0] == '\0')
		return FALSE;

	/* this is used to map non-SPDX licence-ids to legitimate values */
	if (g_str_has_prefix (license_id, "LicenseRef-"))
		return TRUE;

	/* load the readonly data section and look for the icon name */
	data = g_resource_lookup_data (as_get_resource (),
				       "/org/freedesktop/appstream/spdx-license-ids.txt",
				       G_RESOURCE_LOOKUP_FLAGS_NONE,
				       NULL);
	if (data == NULL)
		return FALSE;
	key = g_strdup_printf ("\n%s\n", license_id);

	return g_strstr_len (g_bytes_get_data (data, NULL), -1, key) != NULL;
}

/**
 * as_is_spdx_license_expression:
 * @license: a SPDX license string, e.g. "CC-BY-3.0 and GFDL-1.3"
 *
 * Checks the licence string to check it being a valid licence.
 * NOTE: SPDX licences can't typically contain brackets.
 *
 * Returns: %TRUE if the icon is a valid "SPDX license"
 *
 * Since: 0.9.8
 **/
gboolean
as_is_spdx_license_expression (const gchar *license)
{
	guint i;
	g_auto(GStrv) tokens = NULL;

	/* handle nothing set */
	if (license == NULL || license[0] == '\0')
		return FALSE;

	/* no license information whatsoever */
	if (g_strcmp0 (license, "NONE") == 0)
		return TRUE;

	/* creator has intentionally provided no information */
	if (g_strcmp0 (license, "NOASSERTION") == 0)
		return TRUE;

	tokens = as_spdx_license_tokenize (license);
	if (tokens == NULL)
		return FALSE;
	for (i = 0; tokens[i] != NULL; i++) {
		if (tokens[i][0] == '@') {
			if (as_is_spdx_license_id (tokens[i] + 1))
				continue;
		}
		if (as_is_spdx_license_id (tokens[i]))
			continue;
		if (g_strcmp0 (tokens[i], "&") == 0)
			continue;
		if (g_strcmp0 (tokens[i], "|") == 0)
			continue;
		if (g_strcmp0 (tokens[i], "+") == 0)
			continue;
		return FALSE;
	}

	return TRUE;
}

/**
 * as_utils_spdx_license_3to2:
 *
 * SPDX decided to rename some of the really common license IDs in v3
 * which broke a lot of tools that we cannot really fix now
 */
static GString*
as_utils_spdx_license_3to2 (const gchar *license3)
{
	GString *license2 = g_string_new (license3);
	as_gstring_replace (license2, "-only", "");
	as_gstring_replace (license2, "-or-later", "+");
	return license2;
}

/**
 * as_spdx_license_tokenize:
 * @license: a license string, e.g. "LGPLv2+ and (QPL or GPLv2) and MIT"
 *
 * Tokenizes the SPDX license string (or any simarly formatted string)
 * into parts. Any licence parts of the string e.g. "LGPL-2.0+" are prefexed
 * with "@", the conjunctive replaced with "&" and the disjunctive replaced
 * with "|". Brackets are added as indervidual tokens and other strings are
 * appended into single tokens where possible.
 *
 * Returns: (transfer full) (nullable): array of strings, or %NULL for invalid
 *
 * Since: 0.9.8
 **/
gchar**
as_spdx_license_tokenize (const gchar *license)
{
	AsSpdxHelper helper;
	g_autoptr(GString) license2 = NULL;

	/* handle invalid */
	if (license == NULL)
		return NULL;

	/* SPDX broke the world with v3 */
	license2 = as_utils_spdx_license_3to2 (license);

	helper.last_token_literal = FALSE;
	helper.collect = g_string_new ("");
	helper.array = g_ptr_array_new_with_free_func (g_free);
	for (guint i = 0; i < license2->len; i++) {

		/* handle brackets */
		const gchar tmp = license2->str[i];
		if (tmp == '(' || tmp == ')') {
			as_spdx_license_tokenize_drop (&helper);
			g_ptr_array_add (helper.array, g_strdup_printf ("%c", tmp));
			helper.last_token_literal = FALSE;
			continue;
		}

		/* space, so dump queue */
		if (tmp == ' ') {
			as_spdx_license_tokenize_drop (&helper);
			continue;
		}
		g_string_append_c (helper.collect, tmp);
	}

	/* dump anything remaining */
	as_spdx_license_tokenize_drop (&helper);

	/* return GStrv */
	g_ptr_array_add (helper.array, NULL);
	g_string_free (helper.collect, TRUE);

	return (gchar **) g_ptr_array_free (helper.array, FALSE);
}

/**
 * as_spdx_license_detokenize:
 * @license_tokens: license tokens, typically from as_spdx_license_tokenize()
 *
 * De-tokenizes the SPDX licenses into a string.
 *
 * Returns: (transfer full) (nullable): string, or %NULL for invalid
 *
 * Since: 0.9.8
 **/
gchar*
as_spdx_license_detokenize (gchar **license_tokens)
{
	GString *tmp;
	guint i;

	/* handle invalid */
	if (license_tokens == NULL)
		return NULL;

	tmp = g_string_new ("");
	for (i = 0; license_tokens[i] != NULL; i++) {
		if (g_strcmp0 (license_tokens[i], "&") == 0) {
			g_string_append (tmp, " AND ");
			continue;
		}
		if (g_strcmp0 (license_tokens[i], "|") == 0) {
			g_string_append (tmp, " OR ");
			continue;
		}
		if (g_strcmp0 (license_tokens[i], "+") == 0) {
			g_string_append (tmp, "+");
			continue;
		}
		if (license_tokens[i][0] != '@') {
			g_string_append (tmp, license_tokens[i]);
			continue;
		}
		g_string_append (tmp, license_tokens[i] + 1);
	}

	return g_string_free (tmp, FALSE);
}

/**
 * as_license_to_spdx_id:
 * @license: a not-quite SPDX license string, e.g. "GPLv3+"
 *
 * Converts a non-SPDX license into an SPDX format string where possible.
 *
 * Returns: the best-effort SPDX license string
 *
 * Since: 0.9.8
 **/
gchar*
as_license_to_spdx_id (const gchar *license)
{
	GString *str;
	guint i;
	guint j;
	guint license_len;
	struct {
		const gchar	*old;
		const gchar	*new;
	} convert[] =  {
		{ " with exceptions",		NULL },
		{ " with advertising",		NULL },
		{ " and ",			" AND " },
		{ " or ",			" OR " },
		{ "AGPLv3+",			"AGPL-3.0" },
		{ "AGPLv3",			"AGPL-3.0" },
		{ "Artistic 2.0",		"Artistic-2.0" },
		{ "Artistic clarified",		"Artistic-2.0" },
		{ "Artistic",			"Artistic-1.0" },
		{ "ASL 1.1",			"Apache-1.1" },
		{ "ASL 2.0",			"Apache-2.0" },
		{ "Boost",			"BSL-1.0" },
		{ "BSD",			"BSD-3-Clause" },
		{ "CC0",			"CC0-1.0" },
		{ "CC-BY-SA",			"CC-BY-SA-3.0" },
		{ "CC-BY",			"CC-BY-3.0" },
		{ "CDDL",			"CDDL-1.0" },
		{ "CeCILL-C",			"CECILL-C" },
		{ "CeCILL",			"CECILL-2.0" },
		{ "CPAL",			"CPAL-1.0" },
		{ "CPL",			"CPL-1.0" },
		{ "EPL",			"EPL-1.0" },
		{ "Free Art",			"ClArtistic" },
		{ "GFDL",			"GFDL-1.3" },
		{ "GPL+",			"GPL-1.0+" },
		{ "GPLv2+",			"GPL-2.0+" },
		{ "GPLv2",			"GPL-2.0" },
		{ "GPLv3+",			"GPL-3.0+" },
		{ "GPLv3",			"GPL-3.0" },
		{ "IBM",			"IPL-1.0" },
		{ "LGPL+",			"LGPL-2.1+" },
		{ "LGPLv2.1",			"LGPL-2.1" },
		{ "LGPLv2+",			"LGPL-2.1+" },
		{ "LGPLv2",			"LGPL-2.1" },
		{ "LGPLv3+",			"LGPL-3.0+" },
		{ "LGPLv3",			"LGPL-3.0" },
		{ "LPPL",			"LPPL-1.3c" },
		{ "MPLv1.0",			"MPL-1.0" },
		{ "MPLv1.1",			"MPL-1.1" },
		{ "MPLv2.0",			"MPL-2.0" },
		{ "Netscape",			"NPL-1.1" },
		{ "OFL",			"OFL-1.1" },
		{ "Python",			"Python-2.0" },
		{ "QPL",			"QPL-1.0" },
		{ "SPL",			"SPL-1.0" },
		{ "zlib",			"Zlib" },
		{ "ZPLv2.0",			"ZPL-2.0" },
		{ "Unlicense",			"CC0-1.0" },
		{ "Public Domain",		"LicenseRef-public-domain" },
		{ "Copyright only",		"LicenseRef-public-domain" },
		{ "Proprietary",		"LicenseRef-proprietary" },
		{ "Commercial",			"LicenseRef-proprietary" },
		{ NULL, NULL } };

	/* nothing set */
	if (license == NULL)
		return NULL;

	/* already in SPDX format */
	if (as_is_spdx_license_id (license))
		return g_strdup (license);

	/* go through the string looking for case-insensitive matches */
	str = g_string_new ("");
	license_len = strlen (license);
	for (i = 0; i < license_len; i++) {
		gboolean found = FALSE;
		for (j = 0; convert[j].old != NULL; j++) {
			guint old_len = strlen (convert[j].old);
			if (g_ascii_strncasecmp (license + i,
						 convert[j].old,
						 old_len) != 0)
				continue;
			if (convert[j].new != NULL)
				g_string_append (str, convert[j].new);
			i += old_len - 1;
			found = TRUE;
		}
		if (!found)
			g_string_append_c (str, license[i]);
	}

	return g_string_free (str, FALSE);
}

static gboolean
as_validate_is_content_license_id (const gchar *license_id)
{
	if (g_strcmp0 (license_id, "@FSFAP") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@MIT") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@0BSD") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@CC0-1.0") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@CC-BY-3.0") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@CC-BY-4.0") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@CC-BY-SA-3.0") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@CC-BY-SA-4.0") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@GFDL-1.1") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@GFDL-1.2") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@GFDL-1.3") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@BSL-1.0") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@FTL") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "@FSFUL") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "&") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "|") == 0)
		return TRUE;
	if (g_strcmp0 (license_id, "+") == 0)
		return TRUE;
	return FALSE;
}

/**
 * as_license_is_metadata_license:
 * @license: The SPDX license string to test.
 *
 * Check if the metadata license is suitable for mixing with other
 * metadata and redistributing the bundled result (this means we
 * prefer permissive licenses here, to not require people shipping
 * catalog metadata to perform a full license review).
 *
 * This method checks against a hardcoded list of permissive licenses
 * commonly used to license metadata under.
 *
 * Retrurns: %TRUE if the license contains only permissive licenses suitable
 * as metadata license.
 */
gboolean
as_license_is_metadata_license (const gchar *license)
{
	guint i;
	g_auto(GStrv) tokens = NULL;

	tokens = as_spdx_license_tokenize (license);
	if (tokens == NULL)
		return FALSE;

	for (i = 0; tokens[i] != NULL; i++) {
		if (!as_validate_is_content_license_id (tokens[i]))
			return FALSE;
	}

	return TRUE;
}
