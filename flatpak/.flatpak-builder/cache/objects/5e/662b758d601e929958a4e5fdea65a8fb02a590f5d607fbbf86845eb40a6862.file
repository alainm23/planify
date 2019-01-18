/*
 * Copyright (C) 2015 Red Hat, Inc. (www.redhat.com)
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

#include <glib.h>
#include <glib/gi18n-lib.h>

#include <gtk/gtk.h>

#include <libedataserver/libedataserver.h>

#include "e-cell-renderer-color.h"
#include "e-trust-prompt.h"
#include "e-webdav-discover-widget.h"

#define WEBDAV_DISCOVER_CONTENT_KEY		"e-webdav-discover-content-widget-key"
#define WEBDAV_DISCOVER_CONTENT_ENTRY_KEY	"e-webdav-discover-content-widget-entry-key"
#define WEBDAV_DISCOVER_CONTENT_DATA_KEY	"e-webdav-discover-content-widget-data-key"

enum {
	COL_HREF_STRING = 0,
	COL_SUPPORTS_UINT,
	COL_DISPLAY_NAME_STRING,
	COL_COLOR_STRING,
	COL_DESCRIPTION_STRING,
	COL_SUPPORTS_STRING,
	COL_COLOR_GDKRGBA,
	COL_SHOW_COLOR_BOOLEAN,
	N_COLUMNS
};

typedef struct _EWebDAVDiscoverContentData {
	ECredentialsPrompter *credentials_prompter;
	ESource *source;
	gchar *base_url;
	guint supports_filter;

	GtkTreeView *sources_tree_view; /* not referenced */
	GtkComboBox *email_addresses_combo; /* not referenced */
	GtkInfoBar *info_bar; /* not referenced */
} EWebDAVDiscoverContentData;

static void
e_webdav_discover_content_data_free (gpointer ptr)
{
	EWebDAVDiscoverContentData *data = ptr;

	if (data) {
		g_clear_object (&data->credentials_prompter);
		g_clear_object (&data->source);
		g_free (data->base_url);
		g_free (data);
	}
}

/**
 * e_webdav_discover_content_new:
 * @credentials_prompter: an #ECredentialsPrompter to use to ask for credentials
 * @source: (allow-none): optional #ESource to use for authentication, or %NULL
 * @base_url: (allow-none): optional base URL to use for discovery, or %NULL
 * @supports_filter: a bit-or of #EWebDAVDiscoverSupports, a filter to limit what source
 *    types will be shown in the dialog content; use %E_WEBDAV_DISCOVER_SUPPORTS_NONE
 *    to show all
 *
 * Creates a new WebDAV discovery content, which is a #GtkGrid containing necessary
 * widgets to provide a UI interface for a user to search and select for available
 * WebDAV (CalDAV or CardDAV) sources provided by the given server. Do not pack
 * anything into this content, its content can be changed dynamically.
 *
 * Returns: (transfer full): a new WebDAV discovery content widget.
 *
 * Since: 3.18
 **/
GtkWidget *
e_webdav_discover_content_new (ECredentialsPrompter *credentials_prompter,
			       ESource *source,
			       const gchar *base_url,
			       guint supports_filter)
{
	EWebDAVDiscoverContentData *data;
	GtkWidget *content, *scrolled_window, *tree_view;
	GtkTreeViewColumn *column;
	GtkCellRenderer *renderer;
	GtkListStore *list_store;
	GtkGrid *grid;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER (credentials_prompter), NULL);
	g_return_val_if_fail (base_url != NULL, NULL);

	data = g_new0 (EWebDAVDiscoverContentData, 1);
	data->credentials_prompter = g_object_ref (credentials_prompter);
	data->source = source ? g_object_ref (source) : NULL;
	data->base_url = g_strdup (base_url);
	data->supports_filter = supports_filter;

	content = gtk_grid_new ();
	grid = GTK_GRID (content);
	gtk_container_set_border_width (GTK_CONTAINER (grid), 4);
	gtk_grid_set_row_spacing (grid, 4);
	gtk_grid_set_column_spacing (grid, 4);

	g_object_set_data_full (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY, data, e_webdav_discover_content_data_free);

	list_store = gtk_list_store_new (N_COLUMNS,
					 G_TYPE_STRING, /* COL_HREF_STRING */
					 G_TYPE_UINT, /* COL_SUPPORTS_UINT */
					 G_TYPE_STRING, /* COL_DISPLAY_NAME_STRING */
					 G_TYPE_STRING, /* COL_COLOR_STRING */
					 G_TYPE_STRING, /* COL_DESCRIPTION_STRING */
					 G_TYPE_STRING, /* COL_SUPPORTS_STRING */
					 GDK_TYPE_RGBA, /* COL_COLOR_GDKRGBA */
					 G_TYPE_BOOLEAN); /* COL_SHOW_COLOR_BOOLEAN */

	tree_view = gtk_tree_view_new_with_model (GTK_TREE_MODEL (list_store));
	g_object_unref (list_store);

	g_object_set (G_OBJECT (tree_view),
		"hexpand", TRUE,
		"vexpand", TRUE,
		"halign", GTK_ALIGN_FILL,
		"valign", GTK_ALIGN_FILL,
		NULL);

	scrolled_window = gtk_scrolled_window_new (NULL, NULL);
	gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW (scrolled_window),
		GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);

	gtk_container_add (GTK_CONTAINER (scrolled_window), tree_view);
	gtk_grid_attach (grid, scrolled_window, 0, 0, 1, 1);

	data->sources_tree_view = GTK_TREE_VIEW (tree_view);

	renderer = e_cell_renderer_color_new ();
	g_object_set (G_OBJECT (renderer), "mode", GTK_CELL_RENDERER_MODE_ACTIVATABLE, NULL);

	column = gtk_tree_view_column_new_with_attributes (_("Name"), renderer, "rgba", COL_COLOR_GDKRGBA, "visible", COL_SHOW_COLOR_BOOLEAN, NULL);
	gtk_tree_view_append_column (data->sources_tree_view, column);

	renderer = gtk_cell_renderer_text_new ();
	gtk_tree_view_column_pack_start (column, renderer, FALSE);
	gtk_tree_view_column_add_attribute (column, renderer, "markup", COL_DESCRIPTION_STRING);
	g_object_set (G_OBJECT (renderer),
		"max-width-chars", 60,
		"wrap-mode", PANGO_WRAP_WORD_CHAR,
		"wrap-width", 640,
		NULL);

	renderer = gtk_cell_renderer_text_new ();
	column = gtk_tree_view_column_new_with_attributes (_("Supports"), renderer, "text", COL_SUPPORTS_STRING, NULL);
	gtk_tree_view_append_column (data->sources_tree_view, column);

	if (!supports_filter || (supports_filter & (E_WEBDAV_DISCOVER_SUPPORTS_EVENTS |
	    E_WEBDAV_DISCOVER_SUPPORTS_MEMOS | E_WEBDAV_DISCOVER_SUPPORTS_TASKS)) != 0) {
		GtkWidget *widget, *box;

		widget = gtk_combo_box_text_new ();
		data->email_addresses_combo = GTK_COMBO_BOX (widget);

		box = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 2);
		widget = gtk_label_new_with_mnemonic (_("_User mail:"));
		gtk_label_set_mnemonic_widget (GTK_LABEL (widget), GTK_WIDGET (data->email_addresses_combo));

		gtk_container_add (GTK_CONTAINER (box), widget);
		gtk_container_add (GTK_CONTAINER (box), GTK_WIDGET (data->email_addresses_combo));

		g_object_set (G_OBJECT (widget),
			"hexpand", FALSE,
			"vexpand", FALSE,
			"halign", GTK_ALIGN_START,
			"valign", GTK_ALIGN_CENTER,
			NULL);

		g_object_set (G_OBJECT (data->email_addresses_combo),
			"hexpand", TRUE,
			"vexpand", FALSE,
			"halign", GTK_ALIGN_FILL,
			"valign", GTK_ALIGN_START,
			NULL);

		g_object_set (G_OBJECT (box),
			"hexpand", TRUE,
			"vexpand", FALSE,
			"halign", GTK_ALIGN_FILL,
			"valign", GTK_ALIGN_START,
			NULL);

		gtk_grid_attach (grid, box, 0, 1, 1, 1);
	}

	gtk_widget_show_all (content);

	return content;
}

/**
 * e_webdav_discover_content_get_tree_selection:
 * @content: a WebDAV discovery content, created by e_webdav_discover_content_new()
 *
 * Returns inner #GtkTreeViewSelection. This is meant to be able to connect
 * to its "changed" signal and update other parts of the parent widgets accordingly.
 *
 * Returns: (transfer none): inner #GtkTreeViewSelection
 *
 * Since: 3.18
 **/
GtkTreeSelection *
e_webdav_discover_content_get_tree_selection (GtkWidget *content)
{
	EWebDAVDiscoverContentData *data;

	g_return_val_if_fail (GTK_IS_GRID (content), NULL);

	data = g_object_get_data (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
	g_return_val_if_fail (data != NULL, NULL);

	return gtk_tree_view_get_selection (data->sources_tree_view);
}

/**
 * e_webdav_discover_content_set_multiselect:
 * @content: a WebDAV discovery content, created by e_webdav_discover_content_new()
 * @multiselect: whether multiselect is allowed
 *
 * Sets whether the WebDAV discovery content allows multiselect.
 *
 * Since: 3.18
 **/
void
e_webdav_discover_content_set_multiselect (GtkWidget *content,
					   gboolean multiselect)
{
	EWebDAVDiscoverContentData *data;
	GtkTreeSelection *selection;

	g_return_if_fail (GTK_IS_GRID (content));

	data = g_object_get_data (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
	g_return_if_fail (data != NULL);

	selection = gtk_tree_view_get_selection (data->sources_tree_view);
	gtk_tree_selection_set_mode (selection, multiselect ? GTK_SELECTION_MULTIPLE : GTK_SELECTION_SINGLE);
}

/**
 * e_webdav_discover_content_get_multiselect:
 * @content: a WebDAV discovery content, created by e_webdav_discover_content_new()
 *
 * Returns: whether multiselect is allowed for the @content.
 *
 * Since: 3.18
 **/
gboolean
e_webdav_discover_content_get_multiselect (GtkWidget *content)
{
	EWebDAVDiscoverContentData *data;
	GtkTreeSelection *selection;

	g_return_val_if_fail (GTK_IS_GRID (content), FALSE);

	data = g_object_get_data (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
	g_return_val_if_fail (data != NULL, FALSE);

	selection = gtk_tree_view_get_selection (data->sources_tree_view);
	return gtk_tree_selection_get_mode (selection) == GTK_SELECTION_MULTIPLE;
}

/**
 * e_webdav_discover_content_set_base_url:
 * @content: a WebDAV discovery content, created by e_webdav_discover_content_new()
 *
 * Sets base URL for the @content. This is used to overwrite the one set on
 * the #ESource from the creation time. The URL can be either a full URL, a path
 * or even a %NULL.
 *
 * Since: 3.18
 **/
void
e_webdav_discover_content_set_base_url (GtkWidget *content,
					const gchar *base_url)
{
	EWebDAVDiscoverContentData *data;

	g_return_if_fail (GTK_IS_GRID (content));
	g_return_if_fail (base_url != NULL);

	data = g_object_get_data (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
	g_return_if_fail (data != NULL);

	if (g_strcmp0 (base_url, data->base_url) != 0) {
		g_free (data->base_url);
		data->base_url = g_strdup (base_url);
	}
}

/**
 * e_webdav_discover_content_get_base_url:
 * @content: a WebDAV discovery content, created by e_webdav_discover_content_new()
 *
 * Returns currently set base URL for the @content. This is used to overwrite the one
 * set on the #ESource from the creation time. The URL can be either a full URL, a path
 * or even a %NULL.
 *
 * Returns: currently set base URL for the @content.
 *
 * Since: 3.18
 **/
const gchar *
e_webdav_discover_content_get_base_url (GtkWidget *content)
{
	EWebDAVDiscoverContentData *data;

	g_return_val_if_fail (GTK_IS_GRID (content), NULL);

	data = g_object_get_data (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
	g_return_val_if_fail (data != NULL, NULL);

	return data->base_url;
}

/**
 * e_webdav_discover_content_get_selected:
 * @content: a WebDAV discovery content, created by e_webdav_discover_content_new()
 * @index: an index of the selected source; counts from 0
 * @out_href: (out): an output location for the URL of the selected source
 * @out_supports: (out): an output location of a bit-or of #EWebDAVDiscoverSupports, the set
 *    of source types this server source location supports
 * @out_display_name: (out): an output location of the sources display name
 * @out_color: (out): an output location of the string representation of the color
 *    for the source, as set on the server
 *
 * Returns information about selected source at index @index. The function can be called
 * multiple times, with the index starting at zero and as long as it doesn't return %FALSE.
 * If the @content doesn't have allowed multiselection, then the only valid @index is 0.
 *
 * All the @out_href, @out_display_name and @out_color are newly allocated strings, which should
 * be freed with g_free(), when no longer needed.
 *
 * Returns: %TRUE, when a selected source of index @index exists, %FALSE otherwise.
 *
 * Since: 3.18
 **/
gboolean
e_webdav_discover_content_get_selected (GtkWidget *content,
					gint index,
					gchar **out_href,
					guint *out_supports,
					gchar **out_display_name,
					gchar **out_color)
{
	EWebDAVDiscoverContentData *data;
	GtkTreeSelection *selection;
	GtkTreeModel *model = NULL;
	GList *selected_rows, *link;
	gboolean success = FALSE;

	g_return_val_if_fail (GTK_IS_GRID (content), FALSE);
	g_return_val_if_fail (index >= 0, FALSE);
	g_return_val_if_fail (out_href != NULL, FALSE);
	g_return_val_if_fail (out_supports != NULL, FALSE);
	g_return_val_if_fail (out_display_name != NULL, FALSE);
	g_return_val_if_fail (out_color != NULL, FALSE);

	data = g_object_get_data (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
	g_return_val_if_fail (data != NULL, FALSE);

	selection = gtk_tree_view_get_selection (data->sources_tree_view);
	selected_rows = gtk_tree_selection_get_selected_rows (selection, &model);

	for (link = selected_rows; link && index > 0; link = g_list_next (link)) {
		index--;
	}

	if (index == 0 && link) {
		GtkTreePath *path = link->data;

		if (path) {
			GtkTreeIter iter;

			success = gtk_tree_model_get_iter (model, &iter, path);
			if (success) {
				gtk_tree_model_get (model, &iter,
					COL_HREF_STRING, out_href,
					COL_SUPPORTS_UINT, out_supports,
					COL_DISPLAY_NAME_STRING, out_display_name,
					COL_COLOR_STRING, out_color,
					-1);
			}
		}
	}

	g_list_free_full (selected_rows, (GDestroyNotify) gtk_tree_path_free);

	return success;
}

/**
 * e_webdav_discover_content_get_user_address:
 * @content: a WebDAV discovery content, created by e_webdav_discover_content_new()
 *
 * Get currently selected user address in the @content, if the server returned any.
 * This value has meaning only with calendar sources.
 *
 * Returns: (transfer full): currently selected user address. The returned string
 *   is newly allocated and should be freed with g_free() when no longer needed.
 *   If there are none addresses provided by the server, or no calendar sources
 *   were found, then %NULL is returned instead.
 *
 * Since: 3.18
 **/
gchar *
e_webdav_discover_content_get_user_address (GtkWidget *content)
{
	EWebDAVDiscoverContentData *data;
	gchar *active_text;

	g_return_val_if_fail (GTK_IS_GRID (content), NULL);

	data = g_object_get_data (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
	g_return_val_if_fail (data != NULL, NULL);

	if (!data->email_addresses_combo)
		return NULL;

	active_text = gtk_combo_box_text_get_active_text (GTK_COMBO_BOX_TEXT (data->email_addresses_combo));
	if (active_text && !*active_text) {
		g_free (active_text);
		active_text = NULL;
	}

	return active_text;
}

static void
e_webdav_discover_content_fill_discovered_sources (GtkTreeView *tree_view,
						   guint supports_filter,
						   GSList *discovered_sources)
{
	GtkListStore *list_store;
	GtkTreeModel *model;
	GtkTreeIter iter;
	GSList *link;

	/* It's okay to pass NULL here */
	if (!tree_view)
		return;

	g_return_if_fail (GTK_IS_TREE_VIEW (tree_view));

	model = gtk_tree_view_get_model (tree_view);
	list_store = GTK_LIST_STORE (model);
	gtk_list_store_clear (list_store);

	for (link = discovered_sources; link; link = g_slist_next (link)) {
		const EWebDAVDiscoveredSource *source = link->data;
		guint supports_bits;
		GString *supports;
		gchar *description_markup, *colorstr = NULL;
		gboolean show_color = FALSE;
		GdkRGBA rgba;

		if (!source || (supports_filter && (source->supports & supports_filter) == 0) || !source->display_name)
			continue;

		if (source->color && *source->color) {
			gint rr, gg, bb;

			if (gdk_rgba_parse (&rgba, source->color)) {
				show_color = TRUE;
			} else if (sscanf (source->color, "#%02x%02x%02x", &rr, &gg, &bb) == 3) {
				rgba.red = ((gdouble) rr) / 255.0;
				rgba.green = ((gdouble) gg) / 255.0;
				rgba.blue = ((gdouble) bb) / 255.0;
				rgba.alpha = 1.0;

				show_color = TRUE;
			}

			if (show_color) {
				rr = 0xFF * rgba.red;
				gg = 0xFF * rgba.green;
				bb = 0xFF * rgba.blue;

				colorstr = g_strdup_printf ("#%02x%02x%02x", rr & 0xFF, gg & 0xFF, bb & 0xFF);
			}
		}

		if (source->description && *source->description) {
			description_markup = g_markup_printf_escaped ("<b>%s</b>\n<small>%s</small>",
				source->display_name, source->description);
		} else {
			description_markup = g_markup_printf_escaped ("<b>%s</b>",
				source->display_name);
		}

		supports_bits = source->supports;
		supports = g_string_new ("");

		#define addbit(flg, cpt) { \
			if (((flg) & supports_bits) != 0) { \
				if (supports->len) \
					g_string_append (supports, ", "); \
				g_string_append (supports, cpt); \
			} \
		}

		addbit (E_WEBDAV_DISCOVER_SUPPORTS_CONTACTS, C_("WebDAVDiscover", "Contacts"));
		addbit (E_WEBDAV_DISCOVER_SUPPORTS_EVENTS, C_("WebDAVDiscover", "Events"));
		addbit (E_WEBDAV_DISCOVER_SUPPORTS_MEMOS, C_("WebDAVDiscover", "Memos"));
		addbit (E_WEBDAV_DISCOVER_SUPPORTS_TASKS, C_("WebDAVDiscover", "Tasks"));

		#undef addbit

		gtk_list_store_append (list_store, &iter);
		gtk_list_store_set (list_store, &iter,
			COL_HREF_STRING, source->href,
			COL_SUPPORTS_UINT, source->supports,
			COL_DISPLAY_NAME_STRING, source->display_name,
			COL_COLOR_STRING, colorstr,
			COL_DESCRIPTION_STRING, description_markup,
			COL_SUPPORTS_STRING, supports->str,
			COL_COLOR_GDKRGBA, show_color ? &rgba : NULL,
			COL_SHOW_COLOR_BOOLEAN, show_color,
			-1);

		g_free (description_markup);
		g_free (colorstr);
		g_string_free (supports, TRUE);
	}
}

static void
e_webdav_discover_content_fill_calendar_emails (GtkComboBox *combo_box,
						GSList *calendar_user_addresses)
{
	GtkComboBoxText *text_combo;
	gboolean any_added = FALSE;
	GSList *link;

	/* It's okay to pass NULL here */
	if (!combo_box)
		return;

	g_return_if_fail (GTK_IS_COMBO_BOX_TEXT (combo_box));

	text_combo = GTK_COMBO_BOX_TEXT (combo_box);

	gtk_combo_box_text_remove_all (text_combo);

	for (link = calendar_user_addresses; link; link = g_slist_next (link)) {
		const gchar *address = link->data;

		if (address && *address) {
			gtk_combo_box_text_append_text (text_combo, address);
			any_added = TRUE;
		}
	}

	if (any_added)
		gtk_combo_box_set_active (combo_box, 0);
}

typedef struct _RefreshData {
	GtkWidget *content;
	GCancellable *cancellable;
	GSimpleAsyncResult *simple;
	gchar *base_url;
	ENamedParameters *credentials;
	ESourceRegistry *registry;
} RefreshData;

static void
refresh_data_free (gpointer ptr)
{
	RefreshData *rd = ptr;

	if (rd) {
		if (rd->content) {
			EWebDAVDiscoverContentData *data;

			data = g_object_get_data (G_OBJECT (rd->content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);

			if (data) {
				if (data->info_bar && gtk_info_bar_get_message_type (data->info_bar) == GTK_MESSAGE_INFO) {
					gtk_widget_destroy (GTK_WIDGET (data->info_bar));
					data->info_bar = NULL;
				}

				gtk_widget_set_sensitive (GTK_WIDGET (data->sources_tree_view), TRUE);
				if (data->email_addresses_combo)
					gtk_widget_set_sensitive (GTK_WIDGET (data->email_addresses_combo), TRUE);
			}
		}

		g_clear_object (&rd->content);
		g_clear_object (&rd->cancellable);
		g_clear_object (&rd->simple);
		g_clear_object (&rd->registry);
		g_free (rd->base_url);
		e_named_parameters_free (rd->credentials);
		g_free (rd);
	}
}

static void
e_webdav_discover_content_refresh_done_cb (GObject *source_object,
					   GAsyncResult *result,
					   gpointer user_data);

static void
e_webdav_discover_content_trust_prompt_done_cb (GObject *source_object,
						GAsyncResult *result,
						gpointer user_data)
{
	ETrustPromptResponse response = E_TRUST_PROMPT_RESPONSE_UNKNOWN;
	ESource *source;
	RefreshData *rd = user_data;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_SOURCE (source_object));
	g_return_if_fail (rd != NULL);

	source = E_SOURCE (source_object);
	if (!e_trust_prompt_run_for_source_finish (source, result, &response, &local_error)) {
		g_simple_async_result_take_error (rd->simple, local_error);
		local_error = NULL;
		g_simple_async_result_complete (rd->simple);
		refresh_data_free (rd);
	} else if (response == E_TRUST_PROMPT_RESPONSE_ACCEPT || response == E_TRUST_PROMPT_RESPONSE_ACCEPT_TEMPORARILY) {
		/* Use NULL credentials to reuse those from the last time. */
		e_webdav_discover_sources_full (source, rd->base_url, E_WEBDAV_DISCOVER_SUPPORTS_NONE, rd->credentials,
			rd->registry ? (EWebDAVDiscoverRefSourceFunc) e_source_registry_ref_source : NULL, rd->registry,
			rd->cancellable, e_webdav_discover_content_refresh_done_cb, rd);
	} else {
		g_cancellable_cancel (rd->cancellable);
		g_warn_if_fail (g_cancellable_set_error_if_cancelled (rd->cancellable, &local_error));
		g_simple_async_result_take_error (rd->simple, local_error);
		local_error = NULL;
		g_simple_async_result_complete (rd->simple);
		refresh_data_free (rd);
	}

	g_clear_error (&local_error);
}

static void
e_webdav_discover_content_credentials_prompt_done_cb (GObject *source_object,
						      GAsyncResult *result,
						      gpointer user_data)
{
	RefreshData *rd = user_data;
	ENamedParameters *credentials = NULL;
	ESource *source = NULL;
	GError *local_error = NULL;

	g_return_if_fail (rd != NULL);
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER (source_object));

	if (!e_credentials_prompter_prompt_finish (E_CREDENTIALS_PROMPTER (source_object), result,
		&source, &credentials, &local_error)) {
		g_simple_async_result_take_error (rd->simple, local_error);
		local_error = NULL;
		g_simple_async_result_complete (rd->simple);
		refresh_data_free (rd);
	} else {
		e_named_parameters_free (rd->credentials);
		rd->credentials = credentials;
		credentials = NULL;

		if (e_source_has_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION) &&
		    rd->credentials && e_named_parameters_exists (rd->credentials, E_SOURCE_CREDENTIAL_USERNAME)) {
			ESourceAuthentication *auth_extension;

			auth_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);
			e_source_authentication_set_user (auth_extension, e_named_parameters_get (rd->credentials, E_SOURCE_CREDENTIAL_USERNAME));
		}

		e_webdav_discover_sources_full (source, rd->base_url, E_WEBDAV_DISCOVER_SUPPORTS_NONE, rd->credentials,
			rd->registry ? (EWebDAVDiscoverRefSourceFunc) e_source_registry_ref_source : NULL, rd->registry,
			rd->cancellable, e_webdav_discover_content_refresh_done_cb, rd);
	}

	e_named_parameters_free (credentials);
	g_clear_object (&source);
	g_clear_error (&local_error);
}

static void
e_webdav_discover_content_refresh_done_cb (GObject *source_object,
					   GAsyncResult *result,
					   gpointer user_data)
{
	RefreshData *rd = user_data;
	ESource *source;
	gchar *certificate_pem = NULL;
	GTlsCertificateFlags certificate_errors = 0;
	GSList *discovered_sources = NULL;
	GSList *calendar_user_addresses = NULL;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_SOURCE (source_object));
	g_return_if_fail (rd != NULL);

	source = E_SOURCE (source_object);

	if (!e_webdav_discover_sources_finish (source, result,
		&certificate_pem, &certificate_errors, &discovered_sources,
		&calendar_user_addresses, &local_error)) {
		if (!g_cancellable_is_cancelled (rd->cancellable) && certificate_pem &&
		    g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_SSL_FAILED)) {
			GtkWindow *parent;
			GtkWidget *widget;

			widget = gtk_widget_get_toplevel (rd->content);
			parent = widget ? GTK_WINDOW (widget) : NULL;

			e_trust_prompt_run_for_source (parent, source, certificate_pem, certificate_errors,
				NULL, FALSE, rd->cancellable, e_webdav_discover_content_trust_prompt_done_cb, rd);
			rd = NULL;
		} else if (g_cancellable_is_cancelled (rd->cancellable) ||
		    (!g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_PERMISSION_DENIED) &&
		    !g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND) &&
		    !g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_UNAUTHORIZED) &&
		    !g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_FORBIDDEN))) {
			g_simple_async_result_take_error (rd->simple, local_error);
			local_error = NULL;
			g_simple_async_result_complete (rd->simple);
		} else {
			EWebDAVDiscoverContentData *data;

			data = g_object_get_data (G_OBJECT (rd->content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
			g_return_if_fail (data != NULL);

			e_credentials_prompter_prompt (data->credentials_prompter, source,
				local_error ? local_error->message : NULL,
				rd->credentials ? E_CREDENTIALS_PROMPTER_PROMPT_FLAG_NONE:
				E_CREDENTIALS_PROMPTER_PROMPT_FLAG_ALLOW_STORED_CREDENTIALS,
				e_webdav_discover_content_credentials_prompt_done_cb, rd);
			rd = NULL;
		}
	} else {
		EWebDAVDiscoverContentData *data;

		data = g_object_get_data (G_OBJECT (rd->content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
		g_warn_if_fail (data != NULL);

		if (data) {
			e_webdav_discover_content_fill_discovered_sources (data->sources_tree_view,
				data->supports_filter, discovered_sources);
			e_webdav_discover_content_fill_calendar_emails (data->email_addresses_combo,
				calendar_user_addresses);
		}

		g_simple_async_result_set_op_res_gboolean (rd->simple, TRUE);
		g_simple_async_result_complete (rd->simple);
	}

	g_free (certificate_pem);
	e_webdav_discover_free_discovered_sources (discovered_sources);
	g_slist_free_full (calendar_user_addresses, g_free);
	refresh_data_free (rd);
	g_clear_error (&local_error);
}

static void
e_webdav_discover_info_bar_response_cb (GtkInfoBar *info_bar,
					gint response_id,
					RefreshData *rd)
{
	if (response_id == GTK_RESPONSE_CANCEL) {
		g_return_if_fail (rd != NULL);
		g_return_if_fail (rd->cancellable != NULL);

		g_cancellable_cancel (rd->cancellable);
	}
}

/**
 * e_webdav_discover_content_refresh:
 * @content: a WebDAV discovery content, created by e_webdav_discover_content_new()
 * @display_name: (allow-none): optional display name to use for scratch sources
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously starts refresh of the @content. This means to access the server
 * and search it for available sources. The @content shows a feedback and a Cancel
 * button during the operation.
 *
 * The @display_name is used only if the @content wasn't created with an #ESource and
 * it's shown in the password prompts, if there are required any.
 *
 * When the operation is finished, @callback will be called. You can then
 * call e_webdav_discover_content_refresh_finish() to get the result of the operation.
 *
 * Since: 3.18
 **/
void
e_webdav_discover_content_refresh (GtkWidget *content,
				   const gchar *display_name,
				   GCancellable *cancellable,
				   GAsyncReadyCallback callback,
				   gpointer user_data)
{
	EWebDAVDiscoverContentData *data;
	RefreshData *rd;
	ESource *source;
	SoupURI *soup_uri;
	GtkWidget *label;

	g_return_if_fail (GTK_IS_GRID (content));

	data = g_object_get_data (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
	g_return_if_fail (data != NULL);
	g_return_if_fail (data->base_url != NULL);

	soup_uri = soup_uri_new (data->base_url);
	if (!soup_uri) {
		GSimpleAsyncResult *simple;

		simple = g_simple_async_result_new (G_OBJECT (content), callback, user_data, e_webdav_discover_content_refresh);
		g_simple_async_result_set_error (simple, G_IO_ERROR, G_IO_ERROR_INVALID_ARGUMENT,
			_("Invalid URL"));
		g_simple_async_result_complete_in_idle (simple);
		g_object_unref (simple);

		return;
	}

	rd = g_new0 (RefreshData, 1);
	rd->content = g_object_ref (content);
	rd->cancellable = cancellable ? g_object_ref (cancellable) : g_cancellable_new ();
	rd->simple = g_simple_async_result_new (G_OBJECT (content), callback, user_data, e_webdav_discover_content_refresh);
	rd->base_url = g_strdup (data->base_url);
	rd->credentials = NULL;
	rd->registry = e_credentials_prompter_get_registry (data->credentials_prompter);

	if (rd->registry)
		g_object_ref (rd->registry);

	if (data->source) {
		source = g_object_ref (data->source);
	} else {
		ESourceWebdav *webdav_extension;
		ESourceAuthentication *auth_extension;

		source = e_source_new_with_uid (data->base_url, NULL, NULL);
		g_return_if_fail (source != NULL);

		webdav_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
		auth_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);

		if (display_name && *display_name)
			e_source_set_display_name (source, display_name);
		e_source_webdav_set_soup_uri (webdav_extension, soup_uri);
		e_source_authentication_set_host (auth_extension, soup_uri_get_host (soup_uri));
		e_source_authentication_set_port (auth_extension, soup_uri_get_port (soup_uri));
		e_source_authentication_set_user (auth_extension, soup_uri_get_user (soup_uri));
	}

	gtk_list_store_clear (GTK_LIST_STORE (gtk_tree_view_get_model (data->sources_tree_view)));
	if (data->email_addresses_combo)
		gtk_combo_box_text_remove_all (GTK_COMBO_BOX_TEXT (data->email_addresses_combo));

	if (data->info_bar)
		gtk_widget_destroy (GTK_WIDGET (data->info_bar));

	data->info_bar = GTK_INFO_BAR (gtk_info_bar_new_with_buttons (_("Cancel"), GTK_RESPONSE_CANCEL, NULL));
	gtk_info_bar_set_message_type (data->info_bar, GTK_MESSAGE_INFO);
	gtk_info_bar_set_show_close_button (data->info_bar, FALSE);
	label = gtk_label_new (_("Searching server sources..."));
	gtk_container_add (GTK_CONTAINER (gtk_info_bar_get_content_area (data->info_bar)), label);
	gtk_widget_show (label);
	gtk_widget_show (GTK_WIDGET (data->info_bar));

	g_signal_connect (data->info_bar, "response", G_CALLBACK (e_webdav_discover_info_bar_response_cb), rd);

	gtk_widget_set_sensitive (GTK_WIDGET (data->sources_tree_view), FALSE);
	if (data->email_addresses_combo)
		gtk_widget_set_sensitive (GTK_WIDGET (data->email_addresses_combo), FALSE);

	gtk_grid_attach (GTK_GRID (content), GTK_WIDGET (data->info_bar), 0, 2, 1, 1);

	e_webdav_discover_sources_full (source, rd->base_url, E_WEBDAV_DISCOVER_SUPPORTS_NONE, rd->credentials,
		rd->registry ? (EWebDAVDiscoverRefSourceFunc) e_source_registry_ref_source : NULL, rd->registry,
		rd->cancellable, e_webdav_discover_content_refresh_done_cb, rd);

	g_object_unref (source);
	soup_uri_free (soup_uri);
}

/**
 * e_webdav_discover_content_refresh_finish:
 * @content: a WebDAV discovery content, created by e_webdav_discover_content_new()
 * @result: a #GAsyncResult
 * @error: (allow-none): return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_webdav_discover_content_refresh(). If an
 * error occurred, the function will set @error and return %FALSE. There is
 * available e_webdav_discover_content_show_error() for convenience, which
 * shows the error within @content and takes care of it when refreshing
 * the content.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.18
 **/
gboolean
e_webdav_discover_content_refresh_finish (GtkWidget *content,
					  GAsyncResult *result,
					  GError **error)
{
	EWebDAVDiscoverContentData *data;
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (GTK_IS_GRID (content), FALSE);

	data = g_object_get_data (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
	g_return_val_if_fail (data != NULL, FALSE);
	g_return_val_if_fail (g_simple_async_result_is_valid (
		result, G_OBJECT (content), e_webdav_discover_content_refresh), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	return g_simple_async_result_get_op_res_gboolean (simple);
}

static void
e_webdav_discover_info_bar_error_response_cb (GtkInfoBar *info_bar,
					      gint response_id,
					      GtkWidget *content)
{
	EWebDAVDiscoverContentData *data;

	g_return_if_fail (GTK_IS_GRID (content));

	data = g_object_get_data (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
	g_return_if_fail (data != NULL);

	if (data->info_bar == info_bar) {
		gtk_widget_destroy (GTK_WIDGET (data->info_bar));
		data->info_bar = NULL;
	}
}

/**
 * e_webdav_discover_content_show_error:
 * @content: a WebDAV discovery content, created by e_webdav_discover_content_new()
 * @error: (allow-none): a #GError to show in the UI, or %NULL
 *
 * Shows the @error within @content, unless it's a #G_IO_ERROR_CANCELLED, or %NULL,
 * which are safely ignored. The advantage of this function is that the error
 * message is removed when the refresh operation is started.
 *
 * Since: 3.18
 **/
void
e_webdav_discover_content_show_error (GtkWidget *content,
				      const GError *error)
{
	EWebDAVDiscoverContentData *data;
	GtkWidget *label;

	g_return_if_fail (GTK_IS_GRID (content));

	data = g_object_get_data (G_OBJECT (content), WEBDAV_DISCOVER_CONTENT_DATA_KEY);
	g_return_if_fail (data != NULL);

	if (data->info_bar) {
		gtk_widget_destroy (GTK_WIDGET (data->info_bar));
		data->info_bar = NULL;
	}

	if (!error || g_error_matches (error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
		return;

	data->info_bar = GTK_INFO_BAR (gtk_info_bar_new ());
	gtk_info_bar_set_message_type (data->info_bar, GTK_MESSAGE_ERROR);
	gtk_info_bar_set_show_close_button (data->info_bar, TRUE);

	label = gtk_label_new (error->message);
	gtk_label_set_max_width_chars (GTK_LABEL (label), 120);
	gtk_label_set_line_wrap (GTK_LABEL (label), TRUE);
	gtk_label_set_selectable (GTK_LABEL (label), TRUE);
	gtk_container_add (GTK_CONTAINER (gtk_info_bar_get_content_area (data->info_bar)), label);
	gtk_widget_show (label);
	gtk_widget_show (GTK_WIDGET (data->info_bar));

	g_signal_connect (data->info_bar, "response", G_CALLBACK (e_webdav_discover_info_bar_error_response_cb), content);

	gtk_grid_attach (GTK_GRID (content), GTK_WIDGET (data->info_bar), 0, 2, 1, 1);
}

static void
e_webdav_discover_content_dialog_refresh_done_cb (GObject *source_object,
						  GAsyncResult *result,
						  gpointer user_data)
{
	GError *local_error = NULL;

	if (!e_webdav_discover_content_refresh_finish (GTK_WIDGET (source_object), result, &local_error)) {
		e_webdav_discover_content_show_error (GTK_WIDGET (source_object), local_error);
	}

	g_clear_error (&local_error);
}

static void
e_webdav_discover_content_selection_changed_cb (GtkTreeSelection *selection,
						GtkDialog *dialog)
{
	g_return_if_fail (GTK_IS_TREE_SELECTION (selection));
	g_return_if_fail (GTK_IS_DIALOG (dialog));

	gtk_dialog_set_response_sensitive (dialog, GTK_RESPONSE_ACCEPT,
		gtk_tree_selection_count_selected_rows (selection) > 0);
}

/**
 * e_webdav_discover_dialog_new:
 * @parent: a #GtkWindow parent for the dialog
 * @title: title of the window
 * @credentials_prompter: an #ECredentialsPrompter to use to ask for credentials
 * @source: an #ESource to use for authentication
 * @base_url: (allow-none): optional base URL to use for discovery, or %NULL
 * @supports_filter: a bit-or of #EWebDAVDiscoverSupports, a filter to limit what source
 *    types will be shown in the dialog content; use %E_WEBDAV_DISCOVER_SUPPORTS_NONE
 *    to show all
 *
 * Creates a new #GtkDialog which has as its content a WebDAV discovery widget,
 * created with e_webdav_discover_content_new(). This dialog can be shown to a user
 * and when its final response is %GTK_RESPONSE_ACCEPT, then the inner content
 * can be asked for currently selected source(s).
 *
 * Returns: (transfer full): a newly created #GtkDialog, which should be freed
 * with gtk_widget_destroy(), when no longer needed.
 *
 * Since: 3.18
 **/
GtkDialog *
e_webdav_discover_dialog_new (GtkWindow *parent,
			      const gchar *title,
			      ECredentialsPrompter *credentials_prompter,
			      ESource *source,
			      const gchar *base_url,
			      guint supports_filter)
{
	GtkWidget *dialog, *container, *widget;
	GtkTreeSelection *selection;

	dialog = gtk_dialog_new_with_buttons (title, parent, GTK_DIALOG_DESTROY_WITH_PARENT,
		_("_Cancel"), GTK_RESPONSE_REJECT,
		_("_OK"), GTK_RESPONSE_ACCEPT,
		NULL);

	widget = e_webdav_discover_content_new (credentials_prompter, source, base_url, supports_filter);

	g_object_set (G_OBJECT (widget),
		"hexpand", TRUE,
		"vexpand", TRUE,
		"halign", GTK_ALIGN_FILL,
		"valign", GTK_ALIGN_FILL,
		NULL);

	container = gtk_dialog_get_content_area (GTK_DIALOG (dialog));

	gtk_container_add (GTK_CONTAINER (container), widget);

	g_object_set_data (G_OBJECT (dialog), WEBDAV_DISCOVER_CONTENT_KEY, widget);

	gtk_window_set_default_size (GTK_WINDOW (dialog), 400, 400);

	selection = e_webdav_discover_content_get_tree_selection (widget);
	g_signal_connect (selection, "changed", G_CALLBACK (e_webdav_discover_content_selection_changed_cb), dialog);
	e_webdav_discover_content_selection_changed_cb (selection, GTK_DIALOG (dialog));

	return GTK_DIALOG (dialog);
}

/**
 * e_webdav_discover_dialog_get_content:
 * @dialog: a #GtkDialog returned by e_webdav_discover_dialog_new()
 *
 * Returns inner WebDAV discovery content, which can be further manipulated.
 *
 * Returns: (transfer none): inner WebDAV discovery content
 *
 * Since: 3.18
 **/
GtkWidget *
e_webdav_discover_dialog_get_content (GtkDialog *dialog)
{
	GtkWidget *content;

	g_return_val_if_fail (GTK_IS_DIALOG (dialog), NULL);

	content = g_object_get_data (G_OBJECT (dialog), WEBDAV_DISCOVER_CONTENT_KEY);
	g_return_val_if_fail (content != NULL, NULL);

	return content;
}

/**
 * e_webdav_discover_dialog_refresh:
 * @dialog: a #GtkDialog returned by e_webdav_discover_dialog_new()
 *
 * Invokes refresh of the inner content of the WebDAV discovery dialog.
 *
 * Since: 3.18
 **/
void
e_webdav_discover_dialog_refresh (GtkDialog *dialog)
{
	GtkWidget *content;

	g_return_if_fail (GTK_IS_DIALOG (dialog));

	content = g_object_get_data (G_OBJECT (dialog), WEBDAV_DISCOVER_CONTENT_KEY);
	g_return_if_fail (content != NULL);

	e_webdav_discover_content_refresh (content, gtk_window_get_title (GTK_WINDOW (dialog)),
		NULL, e_webdav_discover_content_dialog_refresh_done_cb, NULL);
}
