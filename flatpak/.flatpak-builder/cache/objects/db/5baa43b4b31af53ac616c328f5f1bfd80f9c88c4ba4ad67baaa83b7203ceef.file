/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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

#include <errno.h>
#include <string.h>
#include <libxml/parser.h>
#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>
#include "e-data-server-util.h"
#include "e-categories.h"

#include "libedataserver-private.h"

#define d(x)

typedef struct {
	gchar *display_name;  /* localized category name */
	gchar *clocale_name;  /* only for default categories */
	gchar *icon_file;
	gboolean is_default;
	gboolean is_searchable;
} CategoryInfo;

typedef struct {
	const gchar *category;
	const gchar *icon_file;
} DefaultCategory;

static DefaultCategory default_categories[] = {
	{ NC_("CategoryName", "Anniversary") },
	{ NC_("CategoryName", "Birthday"), "category_birthday_16.png" },
	{ NC_("CategoryName", "Business"), "category_business_16.png" },
	{ NC_("CategoryName", "Competition") },
	{ NC_("CategoryName", "Favorites"), "category_favorites_16.png" },
	{ NC_("CategoryName", "Gifts"), "category_gifts_16.png" },
	{ NC_("CategoryName", "Goals/Objectives"), "category_goals_16.png" },
	{ NC_("CategoryName", "Holiday"), "category_holiday_16.png" },
	{ NC_("CategoryName", "Holiday Cards"), "category_holiday-cards_16.png" },
	/* important people (e.g. new business partners) */
	{ NC_("CategoryName", "Hot Contacts"), "category_hot-contacts_16.png" },
	{ NC_("CategoryName", "Ideas"), "category_ideas_16.png" },
	{ NC_("CategoryName", "International"), "category_international_16.png" },
	{ NC_("CategoryName", "Key Customer"), "category_key-customer_16.png" },
	{ NC_("CategoryName", "Miscellaneous"), "category_miscellaneous_16.png" },
	{ NC_("CategoryName", "Personal"), "category_personal_16.png" },
	{ NC_("CategoryName", "Phone Calls"), "category_phonecalls_16.png" },
	/* Translators: "Status" is a category name; it can mean anything user wants to */
	{ NC_("CategoryName", "Status"), "category_status_16.png" },
	{ NC_("CategoryName", "Strategies"), "category_strategies_16.png" },
	{ NC_("CategoryName", "Suppliers"), "category_suppliers_16.png" },
	{ NC_("CategoryName", "Time & Expenses"), "category_time-and-expenses_16.png" },
	{ NC_("CategoryName", "VIP") },
	{ NC_("CategoryName", "Waiting") },
	{ NULL }
};

/* ------------------------------------------------------------------------- */

typedef struct {
	GObject object;
} EChangedListener;

typedef struct {
	GObjectClass parent_class;

	void (* changed) (void);
} EChangedListenerClass;

static GType e_changed_listener_get_type (void);

G_DEFINE_TYPE (EChangedListener, e_changed_listener, G_TYPE_OBJECT)

enum {
	CHANGED,
	LAST_SIGNAL
};

static guint changed_listener_signals[LAST_SIGNAL];

static void
e_changed_listener_class_init (EChangedListenerClass *class)
{
	changed_listener_signals[CHANGED] = g_signal_new (
		"changed",
		G_TYPE_FROM_CLASS (class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (EChangedListenerClass, changed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);
}

static void
e_changed_listener_init (EChangedListener *listener)
{
}

/* ------------------------------------------------------------------------- */

/* All the static variables below are protected by a global categories lock. */
G_LOCK_DEFINE_STATIC (categories);

static gboolean initialized = FALSE;
static GHashTable *categories_table = NULL;
static gboolean save_is_pending = FALSE;
static guint idle_id = 0;
static EChangedListener *listeners = NULL;
static gboolean changed = FALSE;

static gchar *
build_categories_filename (void)
{
	const gchar *user_data_dir;
	gchar *filename;

	user_data_dir = e_get_user_data_dir ();
	filename = g_build_filename (user_data_dir, "categories.xml", NULL);

	if (!g_file_test (filename, G_FILE_TEST_IS_REGULAR)) {
		gchar *old_filename;

		/* Try moving the file from its old 2.x location.
		 * This is best effort; don't worry about errors. */
		old_filename = g_build_filename (
			g_get_home_dir (), ".evolution",
			"categories.xml", NULL);
		if (g_rename (old_filename, filename) == -1) {
			g_warning ("%s: Failed to rename '%s' to '%s': %s", G_STRFUNC, old_filename, filename, g_strerror (errno));
		}
		g_free (old_filename);
	}

	return filename;
}

static void
free_category_info (CategoryInfo *cat_info)
{
	g_free (cat_info->display_name);
	g_free (cat_info->clocale_name);
	g_free (cat_info->icon_file);

	g_slice_free (CategoryInfo, cat_info);
}

static gboolean
category_info_equal (const CategoryInfo *cat_info1,
		     const CategoryInfo *cat_info2)
{
	if (!cat_info1 || !cat_info2 || cat_info1 == cat_info2)
		return cat_info1 == cat_info2;

	return g_strcmp0 (cat_info1->display_name, cat_info2->display_name) == 0 &&
		g_strcmp0 (cat_info1->clocale_name, cat_info2->clocale_name) == 0 &&
		g_strcmp0 (cat_info1->icon_file, cat_info2->icon_file) == 0 &&
		(cat_info1->is_default ? 1 : 0) == (cat_info2->is_default ? 1 : 0) &&
		(cat_info1->is_searchable ? 1 : 0) == (cat_info2->is_searchable ? 1 : 0);
}

static gchar *
escape_string (const gchar *source)
{
	GString *buffer;

	buffer = g_string_sized_new (strlen (source));

	while (*source) {
		switch (*source) {
		case '<':
			g_string_append_len (buffer, "&lt;", 4);
			break;
		case '>':
			g_string_append_len (buffer, "&gt;", 4);
			break;
		case '&':
			g_string_append_len (buffer, "&amp;", 5);
			break;
		case '"':
			g_string_append_len (buffer, "&quot;", 6);
			break;
		default:
			g_string_append_c (buffer, *source);
			break;
		}
		source++;
	}

	return g_string_free (buffer, FALSE);
}

/* This must be called with the @categories lock held. */
static void
hash_to_xml_string (gpointer key,
                    gpointer value,
                    gpointer user_data)
{
	CategoryInfo *cat_info = value;
	GString *string = user_data;
	gchar *category;

	g_string_append_len (string, "  <category", 11);

	if (cat_info->is_default && cat_info->clocale_name && *cat_info->clocale_name)
		category = escape_string (cat_info->clocale_name);
	else
		category = escape_string (cat_info->display_name);
	g_string_append_printf (string, " a=\"%s\"", category);
	g_free (category);

	if (cat_info->icon_file != NULL)
		g_string_append_printf (
			string, " icon=\"%s\"", cat_info->icon_file);

	g_string_append_printf (
		string, " default=\"%d\"", cat_info->is_default ? 1 : 0);

	g_string_append_printf (
		string, " searchable=\"%d\"", cat_info->is_searchable ? 1 : 0);

	g_string_append_len (string, "/>\n", 3);
}

/* Called with the @categories lock locked */
static void
idle_saver_save (void)
{
	GString *buffer;
	gchar *contents;
	gchar *filename;
	gchar *pathname;
	EChangedListener *emit_listeners = NULL;  /* owned */
	GError *error = NULL;

	if (!save_is_pending)
		goto exit;

	filename = build_categories_filename ();

	d (g_debug ("Saving categories to \"%s\"", filename));

	/* Build the file contents. */
	buffer = g_string_new ("<categories>\n");
	g_hash_table_foreach (categories_table, hash_to_xml_string, buffer);
	g_string_append_len (buffer, "</categories>\n", 14);
	contents = g_string_free (buffer, FALSE);

	pathname = g_path_get_dirname (filename);
	g_mkdir_with_parents (pathname, 0700);

	if (!g_file_set_contents (filename, contents, -1, &error)) {
		g_warning ("Unable to save categories: %s", error->message);
		g_error_free (error);
	}

	g_free (pathname);
	g_free (contents);
	g_free (filename);
	save_is_pending = FALSE;

	if (changed)
		emit_listeners = g_object_ref (listeners);

	changed = FALSE;
exit:
	idle_id = 0;

	/* Emit the signal with the lock released to avoid re-entrancy
	 * deadlocks. Hold a reference to @listeners until this is complete. */
	if (emit_listeners) {
		G_UNLOCK (categories);

		g_signal_emit_by_name (emit_listeners, "changed");
		g_object_unref (emit_listeners);

		G_LOCK (categories);
	}
}

static gboolean
idle_saver_cb (gpointer user_data)
{
	G_LOCK (categories);

	idle_saver_save ();

	G_UNLOCK (categories);

	return FALSE;
}

/* This must be called with the @categories lock held. */
static void
save_categories (void)
{
	save_is_pending = TRUE;

	if (idle_id == 0)
		idle_id = g_idle_add (idle_saver_cb, NULL);
}

static gchar *
get_collation_key (const gchar *category)
{
	gchar *casefolded, *key;

	g_return_val_if_fail (category != NULL, NULL);

	casefolded = g_utf8_casefold (category, -1);
	g_return_val_if_fail (casefolded != NULL, NULL);

	key = g_utf8_collate_key (casefolded, -1);
	g_free (casefolded);

	return key;
}

/* This must be called with the @categories lock held. */
static void
categories_add_full (const gchar *category,
                     const gchar *icon_file,
                     gboolean is_default,
                     gboolean is_searchable)
{
	CategoryInfo *cat_info, *existing_cat_info;
	gchar *collation_key;

	cat_info = g_slice_new (CategoryInfo);
	if (is_default) {
		const gchar *display_name;
		display_name = g_dpgettext2 (
			GETTEXT_PACKAGE, "CategoryName", category);
		cat_info->display_name = g_strdup (display_name);
		cat_info->clocale_name = g_strdup (category);
	} else {
		cat_info->display_name = g_strdup (category);
		cat_info->clocale_name = NULL;
	}
	cat_info->icon_file = g_strdup (icon_file);
	cat_info->is_default = is_default;
	cat_info->is_searchable = is_default || is_searchable;

	collation_key = get_collation_key (cat_info->display_name);
	existing_cat_info = g_hash_table_lookup (categories_table, collation_key);
	if (category_info_equal (existing_cat_info, cat_info)) {
		free_category_info (cat_info);
		g_free (collation_key);
	} else {
		g_hash_table_insert (categories_table, collation_key, cat_info);
		changed = TRUE;
		save_categories ();
	}
}

/* This must be called with the @categories lock held. */
static CategoryInfo *
categories_lookup (const gchar *category)
{
	CategoryInfo *cat_info;
	gchar *collation_key;

	collation_key = get_collation_key (category);
	cat_info = g_hash_table_lookup (categories_table, collation_key);
	g_free (collation_key);

	return cat_info;
}

/* This must be called with the @categories lock held. */
static gint
parse_categories (const gchar *contents,
                  gsize length)
{
	xmlDocPtr doc;
	xmlNodePtr node;
	gint n_added = 0;

	doc = xmlParseMemory (contents, length);
	if (doc == NULL) {
		g_warning ("Unable to parse categories");
		return 0;
	}

	node = xmlDocGetRootElement (doc);
	if (node == NULL) {
		g_warning ("Unable to parse categories");
		xmlFreeDoc (doc);
		return 0;
	}

	for (node = node->xmlChildrenNode; node != NULL; node = node->next) {
		xmlChar *category, *icon_file, *is_default, *is_searchable;

		category = xmlGetProp (node, (xmlChar *) "a");
		icon_file = xmlGetProp (node, (xmlChar *) "icon");
		is_default = xmlGetProp (node, (xmlChar *) "default");
		is_searchable = xmlGetProp (node, (xmlChar *) "searchable");

		if (category != NULL && *category) {
			categories_add_full (
				(gchar *) category, (gchar *) icon_file,
				g_strcmp0 ((gchar *) is_default, "1") == 0,
				g_strcmp0 ((gchar *) is_searchable, "1") == 0);
			n_added++;
		}

		xmlFree (category);
		xmlFree (icon_file);
		xmlFree (is_default);
		xmlFree (is_searchable);
	}

	xmlFreeDoc (doc);

	return n_added;
}

/* This must be called with the @categories lock held. */
static gint
load_categories (void)
{
	gchar *contents;
	gchar *filename;
	gsize length;
	gint n_added = 0;
	GError *error = NULL;

	contents = NULL;
	filename = build_categories_filename ();

	if (!g_file_test (filename, G_FILE_TEST_EXISTS))
		goto exit;

	d (g_debug ("Loading categories from \"%s\"", filename));

	if (!g_file_get_contents (filename, &contents, &length, &error)) {
		g_warning ("Unable to load categories: %s", error->message);
		g_error_free (error);
		goto exit;
	}

	n_added = parse_categories (contents, length);

exit:
	g_free (contents);
	g_free (filename);

	return n_added;
}

/* This must be called with the @categories lock held. */
static void
load_default_categories (void)
{
	DefaultCategory *cat_info = default_categories;

	while (cat_info->category != NULL) {
		gchar *icon_file = NULL;

		if (cat_info->icon_file != NULL)
			icon_file = g_build_filename (
				E_DATA_SERVER_IMAGESDIR,
				cat_info->icon_file, NULL);

		categories_add_full (cat_info->category, icon_file, TRUE, TRUE);

		g_free (icon_file);
		cat_info++;
	}
}

static void
finalize_categories (void)
{
	G_LOCK (categories);

	if (save_is_pending)
		idle_saver_save ();

	if (idle_id > 0) {
		g_source_remove (idle_id);
		idle_id = 0;
	}

	if (categories_table != NULL) {
		g_hash_table_destroy (categories_table);
		categories_table = NULL;
	}

	if (listeners != NULL) {
		g_object_unref (listeners);
		listeners = NULL;
	}

	initialized = FALSE;

	G_UNLOCK (categories);
}

/* This must be called with the @categories lock held. */
static void
initialize_categories (void)
{
	gint n_added;

	if (initialized)
		return;

	initialized = TRUE;

	bindtextdomain (GETTEXT_PACKAGE, E_DATA_SERVER_LOCALEDIR);

	categories_table = g_hash_table_new_full (
		g_str_hash, g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) free_category_info);

	listeners = g_object_new (e_changed_listener_get_type (), NULL);

	atexit (finalize_categories);

	n_added = load_categories ();
	if (n_added > 0) {
		d (g_debug ("Loaded %d categories", n_added));
		save_is_pending = FALSE;
		return;
	}

	load_default_categories ();
	d (g_debug ("Loaded default categories"));
	save_categories ();
}

/**
 * e_categories_get_list:
 *
 * Returns a sorted list of all the category names currently configured.
 *
 * This function is mostly thread safe, but as the category names are not
 * copied, they may be freed by another thread after being returned by this
 * function. Use e_categories_dup_list() instead.
 *
 * Returns: (transfer container) (element-type utf8): a sorted GList containing
 * the names of the categories. The list should be freed using g_list_free(),
 * but the names of the categories should not be touched at all, they are
 * internal strings.
 *
 * Deprecated: 3.16: This function is not entirely thread safe. Use
 * e_categories_dup_list() instead.
 */
GList *
e_categories_get_list (void)
{
	GHashTableIter iter;
	GList *list = NULL;
	gpointer key, value;

	G_LOCK (categories);

	if (!initialized)
		initialize_categories ();

	g_hash_table_iter_init (&iter, categories_table);

	while (g_hash_table_iter_next (&iter, &key, &value)) {
		CategoryInfo *cat_info = value;
		list = g_list_prepend (list, cat_info->display_name);
	}

	G_UNLOCK (categories);

	return g_list_sort (list, (GCompareFunc) g_utf8_collate);
}

/**
 * e_categories_dup_list:
 *
 * Returns a sorted list of all the category names currently configured.
 *
 * This function is thread safe.
 *
 * Returns: (transfer full) (element-type utf8): a sorted #GList containing
 * the names of the categories. The list should be freed using g_list_free(),
 * and the names of the categories should be freed using g_free(). Everything
 * can be freed simultaneously using g_list_free_full().
 *
 * Since: 3.16
 */
GList *
e_categories_dup_list (void)
{
	GHashTableIter iter;
	GList *list = NULL;
	gpointer key, value;

	G_LOCK (categories);

	if (!initialized)
		initialize_categories ();

	g_hash_table_iter_init (&iter, categories_table);

	while (g_hash_table_iter_next (&iter, &key, &value)) {
		CategoryInfo *cat_info = value;
		list = g_list_prepend (list, g_strdup (cat_info->display_name));
	}

	G_UNLOCK (categories);

	return g_list_sort (list, (GCompareFunc) g_utf8_collate);
}

/**
 * e_categories_add:
 * @category: name of category to add.
 * @unused: DEPRECATED! associated color. DEPRECATED!
 * @icon_file: full path of the icon associated to the category.
 * @searchable: whether the category can be used for searching in the GUI.
 *
 * Adds a new category, with its corresponding icon, to the
 * configuration database.
 *
 * This function is thread safe.
 */
void
e_categories_add (const gchar *category,
                  const gchar *unused,
                  const gchar *icon_file,
                  gboolean searchable)
{
	g_return_if_fail (category != NULL);
	g_return_if_fail (*category);

	G_LOCK (categories);

	if (!initialized)
		initialize_categories ();

	categories_add_full (category, icon_file, FALSE, searchable);

	G_UNLOCK (categories);
}

/**
 * e_categories_remove:
 * @category: category to be removed.
 *
 * Removes the given category from the configuration.
 *
 * This function is thread safe.
 */
void
e_categories_remove (const gchar *category)
{
	gchar *collation_key;

	g_return_if_fail (category != NULL);

	G_LOCK (categories);

	if (!initialized)
		initialize_categories ();

	collation_key = get_collation_key (category);

	if (g_hash_table_remove (categories_table, collation_key)) {
		changed = TRUE;
		save_categories ();
	}

	g_free (collation_key);

	G_UNLOCK (categories);
}

/**
 * e_categories_exist:
 * @category: category to be searched.
 *
 * Checks whether the given category is available in the configuration.
 *
 * This function is thread safe.
 *
 * Returns: %TRUE if the category is available, %FALSE otherwise.
 */
gboolean
e_categories_exist (const gchar *category)
{
	gboolean exists;

	g_return_val_if_fail (category != NULL, FALSE);

	G_LOCK (categories);

	if (!initialized)
		initialize_categories ();

	exists = (!*category) || (categories_lookup (category) != NULL);

	G_UNLOCK (categories);

	return exists;
}

/**
 * e_categories_get_icon_file_for:
 * @category: category to retrieve the icon file for.
 *
 * Gets the icon file associated with the given category.
 *
 * This function is mostly thread safe, but as the icon file name is not
 * copied, it may be freed by another thread after being returned by this
 * function. Use e_categories_dup_icon_file_for() instead.
 *
 * Deprecated: 3.16: This function is not entirely thread safe. Use
 * e_categories_dup_icon_file_for() instead.
 *
 * Returns: icon file name.
 */
const gchar *
e_categories_get_icon_file_for (const gchar *category)
{
	CategoryInfo *cat_info;

	g_return_val_if_fail (category != NULL, NULL);

	G_LOCK (categories);

	if (!initialized)
		initialize_categories ();

	cat_info = categories_lookup (category);

	G_UNLOCK (categories);

	if (cat_info == NULL)
		return NULL;

	return cat_info->icon_file;
}

/**
 * e_categories_dup_icon_file_for:
 * @category: category to retrieve the icon file for.
 *
 * Gets the icon file associated with the given category and returns a copy of
 * it.
 *
 * This function is thread safe.
 *
 * Returns: (transfer full): icon file name; free with g_free().
 *
 * Since: 3.16
 */
gchar *
e_categories_dup_icon_file_for (const gchar *category)
{
	CategoryInfo *cat_info;
	gchar *icon_file = NULL;

	g_return_val_if_fail (category != NULL, NULL);

	G_LOCK (categories);

	if (!initialized)
		initialize_categories ();

	cat_info = categories_lookup (category);

	if (cat_info != NULL)
		icon_file = g_strdup (cat_info->icon_file);

	G_UNLOCK (categories);

	return icon_file;
}

/**
 * e_categories_set_icon_file_for:
 * @category: category to set the icon file for.
 * @icon_file: icon file.
 *
 * Sets the icon file associated with the given category.
 *
 * This function is thread safe.
 */
void
e_categories_set_icon_file_for (const gchar *category,
                                const gchar *icon_file)
{
	CategoryInfo *cat_info;

	g_return_if_fail (category != NULL);

	G_LOCK (categories);

	if (!initialized)
		initialize_categories ();

	cat_info = categories_lookup (category);
	g_return_if_fail (cat_info != NULL);

	g_free (cat_info->icon_file);
	cat_info->icon_file = g_strdup (icon_file);

	changed = TRUE;
	save_categories ();

	G_UNLOCK (categories);
}

/**
 * e_categories_is_searchable:
 * @category: category name.
 *
 * Gets whether the given calendar is to be used for searches in the GUI.
 *
 * This function is thread safe.
 *
 * Return value; %TRUE% if the category is searchable, %FALSE% if not.
 */
gboolean
e_categories_is_searchable (const gchar *category)
{
	CategoryInfo *cat_info;
	gboolean is_searchable = FALSE;

	g_return_val_if_fail (category != NULL, FALSE);

	G_LOCK (categories);

	if (!initialized)
		initialize_categories ();

	cat_info = categories_lookup (category);

	if (cat_info != NULL)
		is_searchable = cat_info->is_searchable;

	G_UNLOCK (categories);

	return is_searchable;
}

/**
 * e_categories_register_change_listener:
 * @listener: (scope async): the callback to be called on any category change.
 * @user_data: used data passed to the @listener when called.
 *
 * Registers callback to be called on change of any category.
 * Pair listener and user_data is used to distinguish between listeners.
 * Listeners can be unregistered with @e_categories_unregister_change_listener.
 *
 * This function is thread safe.
 *
 * Since: 2.24
 **/
void
e_categories_register_change_listener (GCallback listener,
                                       gpointer user_data)
{
	G_LOCK (categories);

	if (!initialized)
		initialize_categories ();

	g_signal_connect (listeners, "changed", listener, user_data);

	G_UNLOCK (categories);
}

/**
 * e_categories_unregister_change_listener:
 * @listener: (scope async): Callback to be removed.
 * @user_data: User data as passed with call to @e_categories_register_change_listener.
 *
 * Removes previously registered callback from the list of listeners on changes.
 * If it was not registered, then does nothing.
 *
 * This function is thread safe.
 *
 * Since: 2.24
 **/
void
e_categories_unregister_change_listener (GCallback listener,
                                         gpointer user_data)
{
	G_LOCK (categories);

	if (initialized)
		g_signal_handlers_disconnect_by_func (listeners, listener, user_data);

	G_UNLOCK (categories);
}
