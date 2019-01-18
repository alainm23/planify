/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2016 Matthias Klumpp <matthias@tenstral.net>
 * Copyright (C)      2016 Richard Hughes <richard@hughsie.com>
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

#include "as-utils.h"
#include "as-utils-private.h"

#include <config.h>
#include <glib.h>
#include <glib-object.h>
#include <stdlib.h>
#include <gio/gio.h>
#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>
#include <sys/types.h>
#include <libxml/tree.h>
#include <libxml/parser.h>
#include <time.h>
#include <utime.h>
#include <sys/utsname.h>
#include <sys/stat.h>
#include <errno.h>

#include "as-resources.h"
#include "as-category.h"
#include "as-component.h"
#include "as-component-private.h"

/**
 * SECTION:as-utils
 * @short_description: Helper functions that are used inside libappstream
 * @include: appstream.h
 *
 * Functions which are used in libappstream and might be useful for others
 * as well.
 */


/**
 * as_get_appstream_version:
 *
 * Get the version of the AppStream library that is currently used
 * as a string.
 *
 * Returns: The AppStream version.
 */
const gchar*
as_get_appstream_version (void)
{
	return PACKAGE_VERSION;
}

/**
 * as_description_markup_convert_simple:
 * @markup: the text to copy.
 * @error: A #GError or %NULL.
 *
 * Converts an XML description markup into a simple printable form.
 *
 * Returns: (transfer full): a newly allocated %NULL terminated string.
 **/
gchar*
as_markup_convert_simple (const gchar *markup, GError **error)
{
	xmlDoc *doc = NULL;
	xmlNode *root;
	xmlNode *iter;
	gboolean ret = TRUE;
	gchar *xmldata;
	gchar *formatted = NULL;
	GString *str = NULL;

	if (markup == NULL)
		return NULL;

	/* is this actually markup */
	if (g_strrstr (markup, "<") == NULL) {
		formatted = g_strdup (markup);
		goto out;
	}

	/* make XML parser happy by providing a root element */
	xmldata = g_strdup_printf ("<root>%s</root>", markup);

	doc = xmlParseDoc ((xmlChar*) xmldata);
	if (doc == NULL) {
		ret = FALSE;
		goto out;
	}

	root = xmlDocGetRootElement (doc);
	if (root == NULL) {
		/* document was empty */
		ret = FALSE;
		goto out;
	}

	str = g_string_new ("");
	for (iter = root->children; iter != NULL; iter = iter->next) {
		gchar *content;
		xmlNode *iter2;
		/* discard spaces */
		if (iter->type != XML_ELEMENT_NODE)
			continue;

		if (g_strcmp0 ((gchar*) iter->name, "p") == 0) {
			content = (gchar*) xmlNodeGetContent (iter);
			if (str->len > 0)
				g_string_append (str, "\n");
			g_string_append_printf (str, "%s\n", content);
			g_free (content);
		} else if ((g_strcmp0 ((gchar*) iter->name, "ul") == 0) || (g_strcmp0 ((gchar*) iter->name, "ol") == 0)) {
			/* iterate over itemize contents */
			for (iter2 = iter->children; iter2 != NULL; iter2 = iter2->next) {
				if (iter2->type != XML_ELEMENT_NODE)
					continue;
				if (g_strcmp0 ((gchar*) iter2->name, "li") == 0) {
					content = (gchar*) xmlNodeGetContent (iter2);
					g_string_append_printf (str,
								" • %s\n",
								content);
					g_free (content);
				} else {
					/* only <li> is valid in lists */
					ret = FALSE;
					goto out;
				}
			}
		}
	}

	/* success */
	if (str->len > 0)
		g_string_truncate (str, str->len - 1);
out:
	if (doc != NULL)
		xmlFreeDoc (doc);
	if (!ret)
		formatted = g_strdup (markup);
	if (str != NULL) {
		if (!ret)
			g_string_free (str, TRUE);
		else
			formatted = g_string_free (str, FALSE);
	}
	return formatted;
}

/**
 * as_str_empty:
 * @str: The string to test.
 *
 * Test if a C string is NULL or empty (containing only spaces).
 */
gboolean
as_str_empty (const gchar* str)
{
	if ((str == NULL) || (g_strcmp0 (str, "") == 0))
		return TRUE;
	return FALSE;
}

/**
 * as_iso8601_to_datetime:
 *
 * Helper function to work around a bug in g_time_val_from_iso8601.
 * Can be dropped when the bug gets resolved upstream:
 * https://bugzilla.gnome.org/show_bug.cgi?id=760983
 **/
GDateTime*
as_iso8601_to_datetime (const gchar *iso_date)
{
	GTimeVal tv;
	guint dmy[] = {0, 0, 0};

	/* nothing set */
	if (iso_date == NULL || iso_date[0] == '\0')
		return NULL;

	/* try to parse complete ISO8601 date */
	if (g_strstr_len (iso_date, -1, " ") != NULL) {
		if (g_time_val_from_iso8601 (iso_date, &tv) && tv.tv_sec != 0)
			return g_date_time_new_from_timeval_utc (&tv);
	}

	/* g_time_val_from_iso8601() blows goats and won't
	 * accept a valid ISO8601 formatted date without a
	 * time value - try and parse this case */
	if (sscanf (iso_date, "%u-%u-%u", &dmy[0], &dmy[1], &dmy[2]) != 3)
		return NULL;

	/* create valid object */
	return g_date_time_new_utc (dmy[0], dmy[1], dmy[2], 0, 0, 0);
}

/**
 * as_utils_delete_dir_recursive:
 * @dirname: Directory to remove
 *
 * Remove directory and all its children (like rm -r does).
 *
 * Returns: %TRUE if operation was successful
 */
gboolean
as_utils_delete_dir_recursive (const gchar* dirname)
{
	GError *error = NULL;
	gboolean ret = FALSE;
	GFile *dir;
	GFileEnumerator *enr;
	GFileInfo *info;
	g_return_val_if_fail (dirname != NULL, FALSE);

	if (!g_file_test (dirname, G_FILE_TEST_IS_DIR))
		return TRUE;

	dir = g_file_new_for_path (dirname);
	enr = g_file_enumerate_children (dir, "standard::name", G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS, NULL, &error);
	if (error != NULL)
		goto out;

	if (enr == NULL)
		goto out;
	info = g_file_enumerator_next_file (enr, NULL, &error);
	if (error != NULL)
		goto out;
	while (info != NULL) {
		gchar *path;
		path = g_build_filename (dirname, g_file_info_get_name (info), NULL);
		if (g_file_test (path, G_FILE_TEST_IS_DIR)) {
			as_utils_delete_dir_recursive (path);
		} else {
			g_remove (path);
		}
		g_object_unref (info);
		info = g_file_enumerator_next_file (enr, NULL, &error);
		if (error != NULL)
			goto out;
	}
	if (g_file_test (dirname, G_FILE_TEST_EXISTS)) {
		g_rmdir (dirname);
	}
	ret = TRUE;

out:
	g_object_unref (dir);
	if (enr != NULL)
		g_object_unref (enr);
	if (error != NULL) {
		g_critical ("Could not remove directory: %s", error->message);
		g_error_free (error);
	}
	return ret;
}

/**
 * as_utils_find_files_matching:
 */
GPtrArray*
as_utils_find_files_matching (const gchar* dir, const gchar* pattern, gboolean recursive, GError **error)
{
	GPtrArray *list;
	GFileInfo *file_info;
	GFileEnumerator *enumerator = NULL;
	GFile *fdir;
	GError *tmp_error = NULL;
	g_return_val_if_fail (dir != NULL, NULL);
	g_return_val_if_fail (pattern != NULL, NULL);

	list = g_ptr_array_new_with_free_func (g_free);
	fdir =  g_file_new_for_path (dir);
	enumerator = g_file_enumerate_children (fdir, G_FILE_ATTRIBUTE_STANDARD_NAME, 0, NULL, &tmp_error);
	if (tmp_error != NULL)
		goto out;

	while ((file_info = g_file_enumerator_next_file (enumerator, NULL, &tmp_error)) != NULL) {
		g_autofree gchar *path = NULL;

		if (tmp_error != NULL) {
			g_object_unref (file_info);
			break;
		}
		if (g_file_info_get_is_hidden (file_info)) {
			g_object_unref (file_info);
			continue;
		}

		path = g_build_filename (dir,
					 g_file_info_get_name (file_info),
					 NULL);

		if ((!g_file_test (path, G_FILE_TEST_IS_REGULAR)) && (recursive)) {
			GPtrArray *subdir_list;
			guint i;
			subdir_list = as_utils_find_files_matching (path, pattern, recursive, &tmp_error);
			/* if there was an error, exit */
			if (subdir_list == NULL) {
				g_ptr_array_unref (list);
				list = NULL;
				g_object_unref (file_info);
				break;
			}
			for (i=0; i<subdir_list->len; i++)
				g_ptr_array_add (list,
						 g_strdup ((gchar *) g_ptr_array_index (subdir_list, i)));
			g_ptr_array_unref (subdir_list);
		} else {
			if (!as_str_empty (pattern)) {
				if (!g_pattern_match_simple (pattern, g_file_info_get_name (file_info))) {
					g_object_unref (file_info);
					continue;
				}
			}
			g_ptr_array_add (list, path);
			path = NULL;
		}

		g_object_unref (file_info);
	}


out:
	g_object_unref (fdir);
	if (enumerator != NULL)
		g_object_unref (enumerator);
	if (tmp_error != NULL) {
		if (error == NULL)
			g_debug ("Error while searching for files in %s: %s", dir, tmp_error->message);
		else
			g_propagate_error (error, tmp_error);
		g_ptr_array_unref (list);
		return NULL;
	}

	return list;
}

/**
 * as_utils_find_files:
 */
GPtrArray*
as_utils_find_files (const gchar *dir, gboolean recursive, GError **error)
{
	GPtrArray* res = NULL;
	g_return_val_if_fail (dir != NULL, NULL);

	res = as_utils_find_files_matching (dir, "", recursive, error);
	return res;
}

/**
 * as_utils_is_root:
 */
gboolean
as_utils_is_root (void)
{
	uid_t vuid;
	vuid = getuid ();
	return (vuid == ((uid_t) 0));
}

/**
 * as_utils_is_writable:
 * @path: the path to check.
 *
 * Checks if a path is writable.
 */
gboolean
as_utils_is_writable (const gchar *path)
{
	g_autoptr(GFile) file = NULL;
	g_autoptr(GFileInfo) file_info = NULL;

	file = g_file_new_for_path (path);
	file_info = g_file_query_info (
		file,
		G_FILE_ATTRIBUTE_ACCESS_CAN_WRITE,
		G_FILE_QUERY_INFO_NONE,
		NULL,
		NULL);

	if (file_info && g_file_info_has_attribute (file_info, G_FILE_ATTRIBUTE_ACCESS_CAN_WRITE))
		return g_file_info_get_attribute_boolean (file_info, G_FILE_ATTRIBUTE_ACCESS_CAN_WRITE);

	return FALSE;
}

/**
 * as_get_current_locale:
 *
 * Returns a locale string as used in the AppStream specification.
 *
 * Returns: (transfer full): A locale string, free with g_free()
 */
gchar*
as_get_current_locale (void)
{
	const gchar * const *locale_names;
	gchar *tmp;
	gchar *locale;

	locale_names = g_get_language_names ();
	/* set active locale without UTF-8 suffix */
	locale = g_strdup (locale_names[0]);
	tmp = g_strstr_len (locale, -1, ".UTF-8");
	if (tmp != NULL)
		*tmp = '\0';

	return locale;
}

/**
 * as_ptr_array_to_strv:
 * @array: (element-type utf8)
 *
 * Returns: (transfer full): strv of the string array
 */
gchar**
as_ptr_array_to_strv (GPtrArray *array)
{
	gchar **value;
	const gchar *value_temp;
	guint i;

	g_return_val_if_fail (array != NULL, NULL);

	/* copy the array to a strv */
	value = g_new0 (gchar*, array->len + 1);
	for (i = 0; i < array->len; i++) {
		value_temp = (const gchar*) g_ptr_array_index (array, i);
		value[i] = g_strdup (value_temp);
	}

	return value;
}

/**
 * as_gstring_replace:
 * @string: The #GString to operate on
 * @search: The text to search for
 * @replace: The text to use for substitutions
 *
 * Performs multiple search and replace operations on the given string.
 *
 * Returns: the number of replacements done, or 0 if @search is not found.
 **/
guint
as_gstring_replace (GString *string, const gchar *search, const gchar *replace)
{
	gchar *tmp;
	guint count = 0;
	gsize search_idx = 0;
	gsize replace_len;
	gsize search_len;

	g_return_val_if_fail (string != NULL, 0);
	g_return_val_if_fail (search != NULL, 0);
	g_return_val_if_fail (replace != NULL, 0);

	/* nothing to do */
	if (string->len == 0)
		return 0;

	search_len = strlen (search);
	replace_len = strlen (replace);

	do {
		tmp = g_strstr_len (string->str + search_idx, -1, search);
		if (tmp == NULL)
			break;

		/* advance the counter in case @replace contains @search */
		search_idx = (gsize) (tmp - string->str);

		/* reallocate the string if required */
		if (search_len > replace_len) {
			g_string_erase (string,
					(gssize) search_idx,
					(gssize) (search_len - replace_len));
			memcpy (tmp, replace, replace_len);
		} else if (search_len < replace_len) {
			g_string_insert_len (string,
					     (gssize) search_idx,
					     replace,
					     (gssize) (replace_len - search_len));
			/* we have to treat this specially as it could have
			 * been reallocated when the insertion happened */
			memcpy (string->str + search_idx, replace, replace_len);
		} else {
			/* just memcmp in the new string */
			memcpy (tmp, replace, replace_len);
		}
		search_idx += replace_len;
		count++;
	} while (TRUE);

	return count;
}

/**
 * as_str_replace:
 * @str: The string to operate on
 * @old_str: The old value to replace.
 * @new_str: The new value to replace @old_str with.
 *
 * Performs search & replace on the given string.
 *
 * Returns: A new string with the characters replaced.
 */
gchar*
as_str_replace (const gchar *str, const gchar *old_str, const gchar *new_str)
{
	GString *gstr;

	gstr = g_string_new (str);
	as_gstring_replace (gstr, old_str, new_str);
	return g_string_free (gstr, FALSE);
}

/**
 * as_touch_location:
 * @fname: The file or directory to touch.
 *
 * Change mtime of a filesystem location.
 */
gboolean
as_touch_location (const gchar *fname)
{
	struct stat sb;
	struct utimbuf new_times;

	if (stat (fname, &sb) < 0)
		return FALSE;

	new_times.actime = sb.st_atime;
	new_times.modtime = time (NULL);
	if (utime (fname, &new_times) < 0)
		return FALSE;

	return TRUE;
}

/**
 * as_reset_umask:
 *
 * Reset umask potentially set by the user to a default value,
 * so we can create files with the correct permissions.
 */
void
as_reset_umask (void)
{
	umask (0022);
}

/**
 * as_copy_file:
 *
 * Copy a file.
 */
gboolean
as_copy_file (const gchar *source, const gchar *destination, GError **error)
{
	FILE *fsrc, *fdest;
	int a;

	fsrc = fopen (source, "rb");
	if (fsrc == NULL) {
		g_set_error (error,
				G_FILE_ERROR,
				G_FILE_ERROR_FAILED,
				"Could not copy file: %s", g_strerror (errno));
		return FALSE;
	}

	fdest = fopen (destination, "wb");
	if (fdest == NULL) {
		g_set_error (error,
				G_FILE_ERROR,
				G_FILE_ERROR_FAILED,
				"Could not copy file: %s", g_strerror (errno));
		fclose (fsrc);
		return FALSE;
	}

	while (TRUE) {
		a = fgetc (fsrc);

		if (!feof (fsrc))
			fputc (a, fdest);
		else
			break;
	}

	fclose (fdest);
	fclose (fsrc);
	return TRUE;
}

/**
 * as_is_cruft_locale:
 *
 * Checks whether the given locale is valid or a cruft or dummy
 * locale.
 */
gboolean
as_is_cruft_locale (const gchar *locale)
{
	if (locale == NULL)
		return FALSE;
	if (g_strcmp0 (locale, "x-test") == 0)
		return TRUE;
	if (g_strcmp0 (locale, "xx") == 0)
		return TRUE;
	return FALSE;
}

/**
 * as_locale_strip_encoding:
 *
 * Remove the encoding from a locale string.
 * The function modifies the string directly.
 */
gchar*
as_locale_strip_encoding (gchar *locale)
{
	gchar *tmp;
	tmp = g_strstr_len (locale, -1, ".UTF-8");
	if (tmp != NULL)
		*tmp = '\0';
	return locale;
}

/**
 * as_get_current_arch:
 *
 * Get the current architecture as vendor strings
 * (e.g. "amd64" instead of "x86_64").
 *
 * Returns: (transfer full): The current OS architecture as string
 */
gchar*
as_get_current_arch (void)
{
	gchar *arch;
	struct utsname uts;

	uname (&uts);

	if (g_strcmp0 (uts.machine, "x86_64") == 0) {
		arch = g_strdup ("amd64");
	} else if (g_pattern_match_simple ("i?86", uts.machine)) {
		arch = g_strdup ("ia32");
	} else if (g_strcmp0 (uts.machine, "aarch64")) {
		arch = g_strdup ("arm64");
	} else {
		arch = g_strdup (uts.machine);
	}

	return arch;
}

/**
 * as_arch_compatible:
 * @arch1: Architecture 1
 * @arch2: Architecture 2
 *
 * Compares two architectures and returns %TRUE if they are compatible.
 */
gboolean
as_arch_compatible (const gchar *arch1, const gchar *arch2)
{
	if (g_strcmp0 (arch1, arch2) == 0)
		return TRUE;
	if (g_strcmp0 (arch1, "all") == 0)
		return TRUE;
	if (g_strcmp0 (arch2, "all") == 0)
		return TRUE;
	return FALSE;
}

/**
 * as_utils_locale_to_language:
 * @locale: The locale string.
 *
 * Get language part from a locale string.
 */
gchar*
as_utils_locale_to_language (const gchar *locale)
{
	gchar *tmp;
	gchar *country_code;

	/* invalid */
	if (locale == NULL)
		return NULL;

	/* return the part before the _ (not always 2 chars!) */
	country_code = g_strdup (locale);
	tmp = g_strstr_len (country_code, -1, "_");
	if (tmp != NULL)
		*tmp = '\0';
	return country_code;
}

/**
 * as_ptr_array_find_string:
 * @array: gchar* array
 * @value: string to find
 *
 * Finds a string in a pointer array.
 *
 * Returns: (nullable): the const string, or %NULL if not found
 **/
const gchar*
as_ptr_array_find_string (GPtrArray *array, const gchar *value)
{
	const gchar *tmp;
	guint i;
	for (i = 0; i < array->len; i++) {
		tmp = g_ptr_array_index (array, i);
		if (g_strcmp0 (tmp, value) == 0)
			return tmp;
	}
	return NULL;
}


/**
 * as_hash_table_keys_to_array:
 * @table: The hash table.
 * @array: The pointer array.
 *
 * Add keys of a hash table to a pointer array.
 * The hash table keys must be strings.
 */
void
as_hash_table_string_keys_to_array (GHashTable *table, GPtrArray *array)
{
	GHashTableIter iter;
	gpointer value;

	g_hash_table_iter_init (&iter, table);
	while (g_hash_table_iter_next (&iter, NULL, &value)) {
		const gchar *str = (const gchar*) value;
		g_ptr_array_add (array, g_strdup (str));
	}
}

/**
 * as_utils_locale_is_compatible:
 * @locale1: a locale string, or %NULL
 * @locale2: a locale string, or %NULL
 *
 * Calculates if one locale is compatible with another.
 * When doing the calculation the locale and language code is taken into
 * account if possible.
 *
 * Returns: %TRUE if the locale is compatible.
 *
 * Since: 0.9.5
 **/
gboolean
as_utils_locale_is_compatible (const gchar *locale1, const gchar *locale2)
{
	g_autofree gchar *lang1 = as_utils_locale_to_language (locale1);
	g_autofree gchar *lang2 = as_utils_locale_to_language (locale2);

	/* we've specified "don't care" and locale unspecified */
	if (locale1 == NULL && locale2 == NULL)
		return TRUE;

	/* forward */
	if (locale1 == NULL && locale2 != NULL) {
		const gchar *const *locales = g_get_language_names ();
		return g_strv_contains (locales, locale2) ||
		       g_strv_contains (locales, lang2);
	}

	/* backwards */
	if (locale1 != NULL && locale2 == NULL) {
		const gchar *const *locales = g_get_language_names ();
		return g_strv_contains (locales, locale1) ||
		       g_strv_contains (locales, lang1);
	}

	/* both specified */
	if (g_strcmp0 (locale1, locale2) == 0)
		return TRUE;
	if (g_strcmp0 (locale1, lang2) == 0)
		return TRUE;
	if (g_strcmp0 (lang1, locale2) == 0)
		return TRUE;
	return FALSE;
}

/**
 * as_utils_search_token_valid:
 * @token: the search token
 *
 * Checks the search token if it is valid. Valid tokens are at least 3 chars in
 * length, not common words like "and", and do not contain markup.
 *
 * Returns: %TRUE is the search token was valid.
 **/
gboolean
as_utils_search_token_valid (const gchar *token)
{
	guint i;
	/* TODO: Localize this list */
	const gchar *blacklist[] = {
		"and", "the", "application", "for", "you", "your",
		"with", "can", "are", "from", "that", "use", "allows", "also",
		"this", "other", "all", "using", "has", "some", "like", "them",
		"well", "not", "using", "not", "but", "set", "its", "into",
		"such", "was", "they", "where", "want", "only", "about",
		"uses", "font", "features", "designed", "provides", "which",
		"many", "used", "org", "fonts", "open", "more", "based",
		"different", "including", "will", "multiple", "out", "have",
		"each", "when", "need", "most", "both", "their", "even",
		"way", "several", "been", "while", "very", "add", "under",
		"what", "those", "much", "either", "currently", "one",
		"support", "make", "over", "these", "there", "without", "etc",
		"main",
		NULL };
	if (strlen (token) < 3)
		return FALSE;
	if (g_strstr_len (token, -1, "<") != NULL)
		return FALSE;
	if (g_strstr_len (token, -1, ">") != NULL)
		return FALSE;
	if (g_strstr_len (token, -1, "(") != NULL)
		return FALSE;
	if (g_strstr_len (token, -1, ")") != NULL)
		return FALSE;
	for (i = 0; blacklist[i] != NULL; i++)  {
		if (g_strcmp0 (token, blacklist[i]) == 0)
			return FALSE;
	}

	return TRUE;
}

/**
 * as_utils_is_category_id:
 * @category_name: an XDG category name, e.g. "ProjectManagement"
 *
 * Searches the known list of registered XDG category names.
 * See https://specifications.freedesktop.org/menu-spec/menu-spec-1.0.html#category-registry
 * for a reference.
 *
 * Returns: %TRUE if the category name is valid
 *
 * Since: 0.9.7
 **/
gboolean
as_utils_is_category_name (const gchar *category_name)
{
	g_autoptr(GBytes) data = NULL;
	g_autofree gchar *key = NULL;

	/* custom spec-extensions are generally valid if prefixed correctly */
	if (g_str_has_prefix (category_name, "X-"))
		return TRUE;

	/* load the readonly data section and look for the category name */
	data = g_resource_lookup_data (as_get_resource (),
				       "/org/freedesktop/appstream/xdg-category-names.txt",
				       G_RESOURCE_LOOKUP_FLAGS_NONE,
				       NULL);
	if (data == NULL)
		return FALSE;
	key = g_strdup_printf ("\n%s\n", category_name);
	return g_strstr_len (g_bytes_get_data (data, NULL), -1, key) != NULL;
}

/**
 * as_utils_is_tld:
 * @tld: a top-level domain without dot, e.g. "de", "org", "name"
 *
 * Searches the known list of TLDs we allow for AppStream IDs.
 * This excludes internationalized names.
 *
 * Returns: %TRUE if the TLD is valid
 *
 * Since: 0.9.8
 **/
gboolean
as_utils_is_tld (const gchar *tld)
{
	g_autoptr(GBytes) data = NULL;
	g_autofree gchar *key = NULL;

	/* load the readonly data section and look for the TLD */
	data = g_resource_lookup_data (as_get_resource (),
				       "/org/freedesktop/appstream/iana-filtered-tld-list.txt",
				       G_RESOURCE_LOOKUP_FLAGS_NONE,
				       NULL);
	if (data == NULL)
		return FALSE;
	key = g_strdup_printf ("\n%s\n", tld);
	return g_strstr_len (g_bytes_get_data (data, NULL), -1, key) != NULL;
}

/**
 * as_utils_is_desktop_environment:
 * @desktop: a desktop environment id.
 *
 * Searches the known list of desktop environments AppStream
 * knows about.
 *
 * Returns: %TRUE if the desktop-id is valid
 *
 * Since: 0.10.0
 **/
gboolean
as_utils_is_desktop_environment (const gchar *desktop)
{
	g_autoptr(GBytes) data = NULL;
	g_autofree gchar *key = NULL;

	/* load the readonly data section and look for the TLD */
	data = g_resource_lookup_data (as_get_resource (),
				       "/org/freedesktop/appstream/desktop-environments.txt",
				       G_RESOURCE_LOOKUP_FLAGS_NONE,
				       NULL);
	if (data == NULL)
		return FALSE;
	key = g_strdup_printf ("\n%s\n", desktop);
	return g_strstr_len (g_bytes_get_data (data, NULL), -1, key) != NULL;
}

/**
 * as_utils_sort_components_into_categories:
 * @cpts: (element-type AsComponent): List of components.
 * @categories: (element-type AsCategory): List of categories to sort components into.
 * @check_duplicates: Whether to check for duplicates.
 *
 * Sorts all components in @cpts into the #AsCategory categories listed in @categories.
 */
void
as_utils_sort_components_into_categories (GPtrArray *cpts, GPtrArray *categories, gboolean check_duplicates)
{
	guint i;

	for (i = 0; i < cpts->len; i++) {
		guint j;
		AsComponent *cpt = AS_COMPONENT (g_ptr_array_index (cpts, i));

		for (j = 0; j < categories->len; j++) {
			guint k;
			GPtrArray *children;
			gboolean added_to_main = FALSE;
			AsCategory *main_cat = AS_CATEGORY (g_ptr_array_index (categories, j));

			if (as_component_is_member_of_category (cpt, main_cat)) {
				if (!check_duplicates || !as_category_has_component (main_cat, cpt)) {
					as_category_add_component (main_cat, cpt);
					added_to_main = TRUE;
				}
			}

			/* fortunately, categories are only nested one level deep in all known cases.
			 * if this will ever change, we will need to adjust this code to go through
			 * a whole tree of categories, eww... */
			children = as_category_get_children (main_cat);
			for (k = 0; k < children->len; k++) {
				AsCategory *subcat = AS_CATEGORY (g_ptr_array_index (children, k));

				/* skip duplicates */
				if (check_duplicates && as_category_has_component (subcat, cpt))
					continue;

				if (as_component_is_member_of_category (cpt, subcat)) {
					as_category_add_component (subcat, cpt);
					if (!added_to_main) {
						if (!check_duplicates || !as_category_has_component (main_cat, cpt)) {
							as_category_add_component (main_cat, cpt);
						}
					}
				}
			}
		}
	}
}

/**
 * as_utils_compare_versions:
 *
 * Compare alpha and numeric segments of two versions.
 * The version compare algorithm is also used by RPM.
 *
 * Returns: 1: a is newer than b
 *	    0: a and b are the same version
 *	   -1: b is newer than a
 */
gint
as_utils_compare_versions (const gchar* a, const gchar *b)
{
	/* easy comparison to see if versions are identical */
	if (g_strcmp0 (a, b) == 0)
		return 0;

	if (a == NULL)
		return -1;
	if (b == NULL)
		return 1;

	gchar oldch1, oldch2;
	gchar abuf[strlen(a)+1], bbuf[strlen(b)+1];
	gchar *str1 = abuf, *str2 = bbuf;
	gchar *one, *two;
	int rc;
	gboolean isnum;

	strcpy (str1, a);
	strcpy (str2, b);

	one = str1;
	two = str2;

	/* loop through each version segment of str1 and str2 and compare them */
	while (*one || *two) {
		while (*one && !g_ascii_isalnum (*one) && *one != '~') one++;
		while (*two && !g_ascii_isalnum (*two) && *two != '~') two++;

		/* handle the tilde separator, it sorts before everything else */
		if (*one == '~' || *two == '~') {
			if (*one != '~') return 1;
			if (*two != '~') return -1;
			one++;
			two++;
			continue;
		}

		/* If we ran to the end of either, we are finished with the loop */
		if (!(*one && *two)) break;

		str1 = one;
		str2 = two;

		/* grab first completely alpha or completely numeric segment */
		/* leave one and two pointing to the start of the alpha or numeric */
		/* segment and walk str1 and str2 to end of segment */
		if (g_ascii_isdigit (*str1)) {
			while (*str1 && g_ascii_isdigit (*str1)) str1++;
			while (*str2 && g_ascii_isdigit (*str2)) str2++;
			isnum = TRUE;
		} else {
			while (*str1 && g_ascii_isalpha (*str1)) str1++;
			while (*str2 && g_ascii_isalpha (*str2)) str2++;
			isnum = FALSE;
		}

		/* save character at the end of the alpha or numeric segment */
		/* so that they can be restored after the comparison */
		oldch1 = *str1;
		*str1 = '\0';
		oldch2 = *str2;
		*str2 = '\0';

		/* this cannot happen, as we previously tested to make sure that */
		/* the first string has a non-null segment */
		if (one == str1) return -1;	/* arbitrary */

		/* take care of the case where the two version segments are */
		/* different types: one numeric, the other alpha (i.e. empty) */
		/* numeric segments are always newer than alpha segments */
		if (two == str2) return (isnum ? 1 : -1);

		if (isnum) {
			size_t onelen, twolen;
			/* this used to be done by converting the digit segments */
			/* to ints using atoi() - it's changed because long  */
			/* digit segments can overflow an int - this should fix that. */

			/* throw away any leading zeros - it's a number, right? */
			while (*one == '0') one++;
			while (*two == '0') two++;

			/* whichever number has more digits wins */
			onelen = strlen (one);
			twolen = strlen (two);
			if (onelen > twolen) return 1;
			if (twolen > onelen) return -1;
		}

		/* strcmp will return which one is greater - even if the two */
		/* segments are alpha or if they are numeric.  don't return  */
		/* if they are equal because there might be more segments to */
		/* compare */
		rc = strcmp (one, two);
		if (rc) return (rc < 1 ? -1 : 1);

		/* restore character that was replaced by null above */
		*str1 = oldch1;
		one = str1;
		*str2 = oldch2;
		two = str2;
	}

	/* this catches the case where all numeric and alpha segments have */
	/* compared identically but the segment sepparating characters were */
	/* different */
	if ((!*one) && (!*two)) return 0;

	/* whichever version still has characters left over wins */
	if (!*one) return -1; else return 1;
}

/**
 * as_utils_build_data_id:
 *
 * Builds the unique metadata ID using the supplied information.
 */
gchar*
as_utils_build_data_id (AsComponentScope scope,
			const gchar *origin,
			AsBundleKind bundle_kind,
			const gchar *cid)
{
	/* build the data-id */
	return g_strdup_printf ("%s/%s/%s/%s",
				as_component_scope_to_string (scope),
				origin,
				as_bundle_kind_to_string (bundle_kind),
				cid);
}

/**
 * as_utils_data_id_get_cid:
 * @data_id: The data-id.
 *
 * Get the component-id part of the data-id.
 */
gchar*
as_utils_data_id_get_cid (const gchar *data_id)
{
	g_auto(GStrv) parts = NULL;

	parts = g_strsplit (data_id, "/", 4);
	if (g_strv_length (parts) != 4)
		return NULL;
	return g_strdup (parts[3]);
}

/**
 * as_utils_get_component_bundle_kind:
 *
 * Check which bundling system the component uses.
 */
AsBundleKind
as_utils_get_component_bundle_kind (AsComponent *cpt)
{
	GPtrArray *bundles;
	AsBundleKind bundle_kind;

	/* determine bundle - what should we do if there are multiple bundles of different types
	 * defined for one component? */
	bundle_kind = AS_BUNDLE_KIND_PACKAGE;
	bundles = as_component_get_bundles (cpt);
	if (bundles->len > 0)
		bundle_kind = as_bundle_get_kind (AS_BUNDLE (g_ptr_array_index (bundles, 0)));

	return bundle_kind;
}

/**
 * as_utils_build_data_id_for_cpt:
 * @cpt: The component to build the ID for.
 *
 * Builds the unique metadata ID for component @cpt.
 */
gchar*
as_utils_build_data_id_for_cpt (AsComponent *cpt)
{
	const gchar *origin;
	AsBundleKind bundle_kind;

	/* determine bundle - what should we do if there are multiple bundles of different types
	 * defined for one component? */
	bundle_kind = as_utils_get_component_bundle_kind (cpt);

	/* NOTE: packages share one namespace, therefore we edit the origin here for now. */
	if (bundle_kind == AS_BUNDLE_KIND_PACKAGE)
		origin = "os";
	else
		origin = as_component_get_origin (cpt);

	/* build the data-id */
	return as_utils_build_data_id (as_component_get_scope (cpt),
					origin,
					bundle_kind,
					as_component_get_id (cpt));
}
