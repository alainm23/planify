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

#include "e-credentials-prompter.h"
#include "e-credentials-prompter-impl-oauth2.h"

#ifdef ENABLE_OAUTH2
#include <webkit2/webkit2.h>
#endif /* ENABLE_OAUTH2 */

struct _ECredentialsPrompterImplOAuth2Private {
	GMutex property_lock;

	EOAuth2Services *oauth2_services;

	gpointer prompt_id;
	ESource *auth_source;
	ESource *cred_source;
	EOAuth2Service *service;
	gchar *error_text;
	ENamedParameters *credentials;
	gboolean refresh_failed_with_transport_error;

	GtkDialog *dialog;
#ifdef ENABLE_OAUTH2
	WebKitWebView *web_view;
#endif
	gulong show_dialog_idle_id;

	GCancellable *cancellable;
};

G_DEFINE_TYPE (ECredentialsPrompterImplOAuth2, e_credentials_prompter_impl_oauth2, E_TYPE_CREDENTIALS_PROMPTER_IMPL)

#ifdef ENABLE_OAUTH2

static gboolean
cpi_oauth2_get_debug (void)
{
	static gint oauth2_debug = -1;

	if (oauth2_debug == -1)
		oauth2_debug = g_strcmp0 (g_getenv ("OAUTH2_DEBUG"), "1") == 0 ? 1 : 0;

	return oauth2_debug == 1;
}

static gchar *
cpi_oauth2_create_auth_uri (EOAuth2Service *service,
			    ESource *source)
{
	GHashTable *uri_query;
	SoupURI *soup_uri;
	gchar *uri;

	g_return_val_if_fail (E_IS_OAUTH2_SERVICE (service), NULL);
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	soup_uri = soup_uri_new (e_oauth2_service_get_authentication_uri (service, source));
	g_return_val_if_fail (soup_uri != NULL, NULL);

	uri_query = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);

	e_oauth2_service_prepare_authentication_uri_query (service, source, uri_query);

	soup_uri_set_query_from_form (soup_uri, uri_query);

	uri = soup_uri_to_string (soup_uri, FALSE);

	soup_uri_free (soup_uri);
	g_hash_table_destroy (uri_query);

	return uri;
}

static void
e_credentials_prompter_impl_oauth2_show_html (WebKitWebView *web_view,
					      const gchar *title,
					      const gchar *body_text)
{
	gchar *html;

	g_return_if_fail (WEBKIT_IS_WEB_VIEW (web_view));
	g_return_if_fail (title != NULL);
	g_return_if_fail (body_text != NULL);

	html = g_strdup_printf (
		"<html>"
		"<head><title>%s</title></head>"
		"<body><div style=\"font-size:12pt; font-family:Helvetica,Arial;\">%s</div></body>"
		"</html>",
		title,
		body_text);
	webkit_web_view_load_html (web_view, html, "none-local://");
	g_free (html);
}

static gboolean
e_credentials_prompter_impl_oauth2_finish_dialog_idle_cb (gpointer user_data)
{
	ECredentialsPrompterImplOAuth2 *prompter_oauth2 = user_data;

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_oauth2), FALSE);

	g_mutex_lock (&prompter_oauth2->priv->property_lock);
	if (g_source_get_id (g_main_current_source ()) == prompter_oauth2->priv->show_dialog_idle_id) {
		prompter_oauth2->priv->show_dialog_idle_id = 0;
		g_mutex_unlock (&prompter_oauth2->priv->property_lock);

		g_warn_if_fail (prompter_oauth2->priv->dialog != NULL);

		if (prompter_oauth2->priv->error_text) {
			e_credentials_prompter_impl_oauth2_show_html (prompter_oauth2->priv->web_view,
				"Finished with error", prompter_oauth2->priv->error_text);
		} else {
			gtk_dialog_response (prompter_oauth2->priv->dialog, GTK_RESPONSE_OK);
		}
	} else {
		g_warning ("%s: Source was cancelled? current:%d expected:%d", G_STRFUNC, (gint) g_source_get_id (g_main_current_source ()), (gint) prompter_oauth2->priv->show_dialog_idle_id);
		g_mutex_unlock (&prompter_oauth2->priv->property_lock);
	}

	return FALSE;
}

typedef struct {
	GWeakRef *prompter_oauth2; /* ECredentialsPrompterImplOAuth2 * */
	GCancellable *cancellable;
	ESource *cred_source;
	ESourceRegistry *registry;
	gchar *authorization_code;
	EOAuth2Service *service;
} AccessTokenThreadData;

static void
access_token_thread_data_free (gpointer user_data)
{
	AccessTokenThreadData *td = user_data;

	if (td) {
		e_weak_ref_free (td->prompter_oauth2);
		g_clear_object (&td->cancellable);
		g_clear_object (&td->cred_source);
		g_clear_object (&td->registry);
		g_clear_object (&td->service);
		g_free (td->authorization_code);
		g_free (td);
	}
}

static gpointer
cpi_oauth2_get_access_token_thread (gpointer user_data)
{
	AccessTokenThreadData *td = user_data;
	ECredentialsPrompterImplOAuth2 *prompter_oauth2;
	GError *local_error = NULL;
	gboolean success = FALSE;

	g_return_val_if_fail (td != NULL, NULL);

	if (!g_cancellable_set_error_if_cancelled (td->cancellable, &local_error)) {
		EOAuth2ServiceRefSourceFunc ref_source;

		ref_source = (EOAuth2ServiceRefSourceFunc) e_source_registry_ref_source;

		success = e_oauth2_service_receive_and_store_token_sync (td->service, td->cred_source,
			td->authorization_code, ref_source, td->registry, td->cancellable, &local_error);
	}

	prompter_oauth2 = g_weak_ref_get (td->prompter_oauth2);
	if (prompter_oauth2 && !g_cancellable_is_cancelled (td->cancellable)) {
		g_clear_pointer (&prompter_oauth2->priv->error_text, g_free);

		if (!success) {
			prompter_oauth2->priv->error_text = g_strdup_printf (
				_("Failed to obtain access token from address “%s”: %s"),
				e_oauth2_service_get_refresh_uri (td->service, td->cred_source),
				local_error ? local_error->message : _("Unknown error"));
		}

		g_mutex_lock (&prompter_oauth2->priv->property_lock);
		prompter_oauth2->priv->show_dialog_idle_id = g_idle_add (
			e_credentials_prompter_impl_oauth2_finish_dialog_idle_cb,
			prompter_oauth2);
		g_mutex_unlock (&prompter_oauth2->priv->property_lock);
	}

	g_clear_object (&prompter_oauth2);
	g_clear_error (&local_error);

	access_token_thread_data_free (td);

	return NULL;
}

static void
cpi_oauth2_extract_authentication_code (ECredentialsPrompterImplOAuth2 *prompter_oauth2,
					const gchar *page_title,
					const gchar *page_uri,
					const gchar *page_content)
{
	gchar *authorization_code = NULL;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_oauth2));
	g_return_if_fail (prompter_oauth2->priv->service != NULL);

	if (!e_oauth2_service_extract_authorization_code (prompter_oauth2->priv->service,
		prompter_oauth2->priv->cred_source ? prompter_oauth2->priv->cred_source : prompter_oauth2->priv->auth_source,
		page_title, page_uri, page_content, &authorization_code)) {
		return;
	}

	if (authorization_code) {
		ECredentialsPrompter *prompter;
		ECredentialsPrompterImpl *prompter_impl;
		AccessTokenThreadData *td;
		GThread *thread;

		e_credentials_prompter_impl_oauth2_show_html (prompter_oauth2->priv->web_view,
			"Checking returned code", _("Requesting access token, please wait..."));

		gtk_widget_set_sensitive (GTK_WIDGET (prompter_oauth2->priv->web_view), FALSE);

		e_named_parameters_set (prompter_oauth2->priv->credentials, E_SOURCE_CREDENTIAL_PASSWORD, NULL);

		prompter_impl = E_CREDENTIALS_PROMPTER_IMPL (prompter_oauth2);
		prompter = e_credentials_prompter_impl_get_credentials_prompter (prompter_impl);

		td = g_new0 (AccessTokenThreadData, 1);
		td->prompter_oauth2 = e_weak_ref_new (prompter_oauth2);
		td->service = g_object_ref (prompter_oauth2->priv->service);
		td->cancellable = g_object_ref (prompter_oauth2->priv->cancellable);
		td->cred_source = g_object_ref (prompter_oauth2->priv->cred_source);
		td->registry = g_object_ref (e_credentials_prompter_get_registry (prompter));
		td->authorization_code = authorization_code;

		thread = g_thread_new (G_STRFUNC, cpi_oauth2_get_access_token_thread, td);
		g_thread_unref (thread);
	} else {
		g_cancellable_cancel (prompter_oauth2->priv->cancellable);
		gtk_dialog_response (prompter_oauth2->priv->dialog, GTK_RESPONSE_CANCEL);
	}
}

static void
cpi_oauth2_web_view_resource_get_data_done_cb (GObject *source_object,
					       GAsyncResult *result,
					       gpointer user_data)
{
	ECredentialsPrompterImplOAuth2 *prompter_oauth2 = user_data;
	GByteArray *page_content = NULL;
	const gchar *title, *uri;
	guchar *data;
	gsize len = 0;
	GError *local_error = NULL;

	g_return_if_fail (WEBKIT_IS_WEB_RESOURCE (source_object));
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_oauth2));

	data = webkit_web_resource_get_data_finish (WEBKIT_WEB_RESOURCE (source_object), result, &len, &local_error);
	if (data) {
		page_content = g_byte_array_new_take ((guint8 *) data, len);

		/* NULL-terminate the array, to be able to use it as a string */
		g_byte_array_append (page_content, (const guint8 *) "", 1);
	} else if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
		g_clear_error (&local_error);
		return;
	}

	g_clear_error (&local_error);

	title = webkit_web_view_get_title (prompter_oauth2->priv->web_view);
	uri = webkit_web_view_get_uri (prompter_oauth2->priv->web_view);

	cpi_oauth2_extract_authentication_code (prompter_oauth2, title, uri, page_content ? (const gchar *) page_content->data : NULL);

	if (page_content)
		g_byte_array_free (page_content, TRUE);
}

static gboolean
cpi_oauth2_decide_policy_cb (WebKitWebView *web_view,
			     WebKitPolicyDecision *decision,
			     WebKitPolicyDecisionType decision_type,
			     ECredentialsPrompterImplOAuth2 *prompter_oauth2)
{
	WebKitNavigationAction *navigation_action;
	WebKitURIRequest *request;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_oauth2), FALSE);
	g_return_val_if_fail (WEBKIT_IS_POLICY_DECISION (decision), FALSE);

	if (decision_type != WEBKIT_POLICY_DECISION_TYPE_NAVIGATION_ACTION)
		return FALSE;

	navigation_action = webkit_navigation_policy_decision_get_navigation_action (WEBKIT_NAVIGATION_POLICY_DECISION (decision));
	if (!navigation_action)
		return FALSE;

	request = webkit_navigation_action_get_request (navigation_action);
	if (!request || !webkit_uri_request_get_uri (request))
		return FALSE;

	g_return_val_if_fail (prompter_oauth2->priv->service != NULL, FALSE);

	switch (e_oauth2_service_get_authentication_policy (prompter_oauth2->priv->service,
		prompter_oauth2->priv->cred_source ? prompter_oauth2->priv->cred_source : prompter_oauth2->priv->auth_source,
		webkit_uri_request_get_uri (request))) {
	case E_OAUTH2_SERVICE_NAVIGATION_POLICY_DENY:
		webkit_policy_decision_ignore (decision);
		break;
	case E_OAUTH2_SERVICE_NAVIGATION_POLICY_ALLOW:
		webkit_policy_decision_use (decision);
		break;
	case E_OAUTH2_SERVICE_NAVIGATION_POLICY_ABORT:
		g_cancellable_cancel (prompter_oauth2->priv->cancellable);
		gtk_dialog_response (prompter_oauth2->priv->dialog, GTK_RESPONSE_CANCEL);
		break;
	default:
		return FALSE;
	}

	return TRUE;
}

static void
cpi_oauth2_document_load_changed_cb (WebKitWebView *web_view,
				     WebKitLoadEvent load_event,
				     ECredentialsPrompterImplOAuth2 *prompter_oauth2)
{
	const gchar *title, *uri;

	g_return_if_fail (WEBKIT_IS_WEB_VIEW (web_view));
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_oauth2));

	if (load_event != WEBKIT_LOAD_FINISHED)
		return;

	title = webkit_web_view_get_title (web_view);
	uri = webkit_web_view_get_uri (web_view);
	if (!title || !uri)
		return;

	if (cpi_oauth2_get_debug ()) {
		e_util_debug_print ("OAuth2", "Loaded URI: '%s'\n", uri);
	}

	g_return_if_fail (prompter_oauth2->priv->service != NULL);

	if ((e_oauth2_service_get_flags (prompter_oauth2->priv->service) & E_OAUTH2_SERVICE_FLAG_EXTRACT_REQUIRES_PAGE_CONTENT) != 0) {
		WebKitWebResource *main_resource;

		main_resource = webkit_web_view_get_main_resource (web_view);
		if (main_resource) {
			webkit_web_resource_get_data (main_resource, prompter_oauth2->priv->cancellable,
				cpi_oauth2_web_view_resource_get_data_done_cb, prompter_oauth2);
		}
	} else {
		cpi_oauth2_extract_authentication_code (prompter_oauth2, title, uri, NULL);
	}
}

static void
cpi_oauth2_notify_estimated_load_progress_cb (WebKitWebView *web_view,
					      GParamSpec *param,
					      GtkProgressBar *progress_bar)
{
	gboolean visible;
	gdouble progress;

	g_return_if_fail (GTK_IS_PROGRESS_BAR (progress_bar));

	progress = webkit_web_view_get_estimated_load_progress (web_view);
	visible = progress > 1e-9 && progress < 1 - 1e-9;

	gtk_progress_bar_set_fraction (progress_bar, visible ? progress : 0.0);
}

static void
credentials_prompter_impl_oauth2_get_prompt_strings (ESourceRegistry *registry,
						     ESource *source,
						     const gchar *service_display_name,
						     gchar **prompt_title,
						     GString **prompt_description)
{
	GString *description;
	gchar *message;
	gchar *display_name;

	/* Known types */
	enum {
		TYPE_UNKNOWN,
		TYPE_AMBIGUOUS,
		TYPE_ADDRESS_BOOK,
		TYPE_CALENDAR,
		TYPE_MAIL_ACCOUNT,
		TYPE_MAIL_TRANSPORT,
		TYPE_MEMO_LIST,
		TYPE_TASK_LIST
	} type = TYPE_UNKNOWN;

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_ADDRESS_BOOK)) {
		type = TYPE_ADDRESS_BOOK;
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_CALENDAR)) {
		if (type == TYPE_UNKNOWN)
			type = TYPE_CALENDAR;
		else
			type = TYPE_AMBIGUOUS;
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_MAIL_ACCOUNT)) {
		if (type == TYPE_UNKNOWN)
			type = TYPE_MAIL_ACCOUNT;
		else
			type = TYPE_AMBIGUOUS;
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_MAIL_TRANSPORT)) {
		if (type == TYPE_UNKNOWN)
			type = TYPE_MAIL_TRANSPORT;
		else
			type = TYPE_AMBIGUOUS;
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_MEMO_LIST)) {
		if (type == TYPE_UNKNOWN)
			type = TYPE_MEMO_LIST;
		else
			type = TYPE_AMBIGUOUS;
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_TASK_LIST)) {
		if (type == TYPE_UNKNOWN)
			type = TYPE_TASK_LIST;
		else
			type = TYPE_AMBIGUOUS;
	}

	switch (type) {
		case TYPE_ADDRESS_BOOK:
			/* Translators: The %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
			   thus it can form a string like "Google Address Book authentication request". */
			message = g_strdup_printf (_("%s Address Book authentication request"), service_display_name);
			break;
		case TYPE_CALENDAR:
			/* Translators: The %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
			   thus it can form a string like "Google Calendar authentication request". */
			message = g_strdup_printf (_("%s Calendar authentication request"), service_display_name);
			break;
		case TYPE_MEMO_LIST:
			/* Translators: The %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
			   thus it can form a string like "Google Memo List authentication request". */
			message = g_strdup_printf (_("%s Memo List authentication request"), service_display_name);
			break;
		case TYPE_TASK_LIST:
			/* Translators: The %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
			   thus it can form a string like "Google Task List authentication request". */
			message = g_strdup_printf (_("%s Task List authentication request"), service_display_name);
			break;
		case TYPE_MAIL_ACCOUNT:
		case TYPE_MAIL_TRANSPORT:
			/* Translators: The %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
			   thus it can form a string like "Google Mail authentication request". */
			message = g_strdup_printf (_("%s Mail authentication request"), service_display_name);
			break;
		default:  /* generic account prompt */
			/* Translators: The %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
			   thus it can form a string like "Google account authentication request". */
			message = g_strdup_printf (_("%s account authentication request"), service_display_name);
			break;
	}

	display_name = e_util_get_source_full_name (registry, source);
	description = g_string_sized_new (256);

	g_string_append_printf (description, "<big><b>%s</b></big>\n\n", message);
	switch (type) {
		case TYPE_ADDRESS_BOOK:
			g_string_append_printf (description,
				/* Translators: The first %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
				   thus it can form a string like "Login to your Google account and...". The second %s is the actual source display name,
				   like "On This Computer : Personal". */
				_("Login to your %s account and accept conditions in order to access your address book “%s”."), service_display_name, display_name);
			break;
		case TYPE_CALENDAR:
			g_string_append_printf (description,
				/* Translators: The first %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
				   thus it can form a string like "Login to your Google account and...". The second %s is the actual source display name,
				   like "On This Computer : Personal". */
				_("Login to your %s account and accept conditions in order to access your calendar “%s”."), service_display_name, display_name);
			break;
		case TYPE_MAIL_ACCOUNT:
			g_string_append_printf (description,
				/* Translators: The first %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
				   thus it can form a string like "Login to your Google account and...". The second %s is the actual source display name,
				   like "On This Computer : Personal". */
				_("Login to your %s account and accept conditions in order to access your mail account “%s”."), service_display_name, display_name);
			break;
		case TYPE_MAIL_TRANSPORT:
			g_string_append_printf (description,
				/* Translators: The first %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
				   thus it can form a string like "Login to your Google account and...". The second %s is the actual source display name,
				   like "On This Computer : Personal". */
				_("Login to your %s account and accept conditions in order to access your mail transport “%s”."), service_display_name, display_name);
			break;
		case TYPE_MEMO_LIST:
			g_string_append_printf (description,
				/* Translators: The first %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
				   thus it can form a string like "Login to your Google account and...". The second %s is the actual source display name,
				   like "On This Computer : Personal". */
				_("Login to your %s account and accept conditions in order to access your memo list “%s”."), service_display_name, display_name);
			break;
		case TYPE_TASK_LIST:
			g_string_append_printf (description,
				/* Translators: The first %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
				   thus it can form a string like "Login to your Google account and...". The second %s is the actual source display name,
				   like "On This Computer : Personal". */
				_("Login to your %s account and accept conditions in order to access your task list “%s”."), service_display_name, display_name);
			break;
		default:  /* generic account prompt */
			g_string_append_printf (description,
				/* Translators: The first %s is replaced with an OAuth2 service display name, like the strings from "OAuth2Service" translation context,
				   thus it can form a string like "Login to your Google account and...". The second %s is the actual source display name,
				   like "On This Computer : Personal". */
				_("Login to your %s account and accept conditions in order to access your account “%s”."), service_display_name, display_name);
			break;
	}

	*prompt_title = message;
	*prompt_description = description;

	g_free (display_name);
}
#endif /* ENABLE_OAUTH2 */

static gboolean
e_credentials_prompter_impl_oauth2_show_dialog (ECredentialsPrompterImplOAuth2 *prompter_oauth2)
{
#ifdef ENABLE_OAUTH2
	GtkWidget *dialog, *content_area, *widget, *progress_bar, *vbox;
	GtkGrid *grid;
	GtkScrolledWindow *scrolled_window;
	GtkWindow *dialog_parent;
	ECredentialsPrompter *prompter;
	WebKitSettings *webkit_settings;
	gchar *title, *uri;
	GString *info_markup;
	gint row = 0;
	gboolean success;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_oauth2), FALSE);
	g_return_val_if_fail (prompter_oauth2->priv->prompt_id != NULL, FALSE);
	g_return_val_if_fail (prompter_oauth2->priv->dialog == NULL, FALSE);
	g_return_val_if_fail (prompter_oauth2->priv->service != NULL, FALSE);

	prompter = e_credentials_prompter_impl_get_credentials_prompter (E_CREDENTIALS_PROMPTER_IMPL (prompter_oauth2));
	g_return_val_if_fail (prompter != NULL, FALSE);

	dialog_parent = e_credentials_prompter_get_dialog_parent (prompter);

	credentials_prompter_impl_oauth2_get_prompt_strings (e_credentials_prompter_get_registry (prompter),
		prompter_oauth2->priv->auth_source,
		e_oauth2_service_get_display_name (prompter_oauth2->priv->service),
		&title, &info_markup);
	if (prompter_oauth2->priv->error_text && *prompter_oauth2->priv->error_text) {
		gchar *escaped = g_markup_printf_escaped ("%s", prompter_oauth2->priv->error_text);

		g_string_append_printf (info_markup, "\n\n%s", escaped);
		g_free (escaped);
	}

	dialog = gtk_dialog_new_with_buttons (title, dialog_parent, GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
		_("_Cancel"), GTK_RESPONSE_CANCEL,
		NULL);

	gtk_window_set_default_size (GTK_WINDOW (dialog), 320, 480);

	prompter_oauth2->priv->dialog = GTK_DIALOG (dialog);
	gtk_window_set_resizable (GTK_WINDOW (dialog), TRUE);
	if (dialog_parent)
		gtk_window_set_transient_for (GTK_WINDOW (dialog), dialog_parent);
	gtk_window_set_position (GTK_WINDOW (dialog), GTK_WIN_POS_CENTER_ON_PARENT);
	gtk_container_set_border_width (GTK_CONTAINER (dialog), 12);

	content_area = gtk_dialog_get_content_area (prompter_oauth2->priv->dialog);

	/* Override GtkDialog defaults */
	gtk_box_set_spacing (GTK_BOX (content_area), 12);
	gtk_container_set_border_width (GTK_CONTAINER (content_area), 0);

	grid = GTK_GRID (gtk_grid_new ());
	gtk_grid_set_column_spacing (grid, 12);
	gtk_grid_set_row_spacing (grid, 6);

	gtk_box_pack_start (GTK_BOX (content_area), GTK_WIDGET (grid), FALSE, TRUE, 0);

	/* Info Label */
	widget = gtk_label_new (NULL);
	gtk_label_set_line_wrap (GTK_LABEL (widget), TRUE);
	gtk_label_set_markup (GTK_LABEL (widget), info_markup->str);
	g_object_set (
		G_OBJECT (widget),
		"hexpand", TRUE,
		"vexpand", FALSE,
		"halign", GTK_ALIGN_FILL,
		"valign", GTK_ALIGN_CENTER,
		"width-chars", 60,
		"max-width-chars", 80,
		"xalign", 0.0,
		NULL);

	gtk_grid_attach (grid, widget, 0, row, 1, 1);
	row++;

	vbox = gtk_box_new (GTK_ORIENTATION_VERTICAL, 1);
	g_object_set (
		G_OBJECT (vbox),
		"hexpand", TRUE,
		"vexpand", TRUE,
		"halign", GTK_ALIGN_FILL,
		"valign", GTK_ALIGN_FILL,
		NULL);

	gtk_grid_attach (grid, vbox, 0, row, 1, 1);

	widget = gtk_scrolled_window_new (NULL, NULL);
	g_object_set (
		G_OBJECT (widget),
		"hexpand", TRUE,
		"vexpand", TRUE,
		"halign", GTK_ALIGN_FILL,
		"valign", GTK_ALIGN_FILL,
		"hscrollbar-policy", GTK_POLICY_AUTOMATIC,
		"vscrollbar-policy", GTK_POLICY_AUTOMATIC,
		NULL);

	gtk_box_pack_start (GTK_BOX (vbox), widget, TRUE, TRUE, 0);

	scrolled_window = GTK_SCROLLED_WINDOW (widget);

	webkit_settings = webkit_settings_new_with_settings (
		"auto-load-images", TRUE,
		"default-charset", "utf-8",
		"enable-html5-database", FALSE,
		"enable-dns-prefetching", FALSE,
		"enable-html5-local-storage", FALSE,
		"enable-offline-web-application-cache", FALSE,
		"enable-page-cache", FALSE,
		"enable-plugins", FALSE,
		"media-playback-allows-inline", FALSE,
		NULL);

	widget = webkit_web_view_new_with_settings (webkit_settings);
	g_object_set (
		G_OBJECT (widget),
		"hexpand", TRUE,
		"vexpand", TRUE,
		"halign", GTK_ALIGN_FILL,
		"valign", GTK_ALIGN_FILL,
		NULL);
	gtk_container_add (GTK_CONTAINER (scrolled_window), widget);
	g_object_unref (webkit_settings);

	prompter_oauth2->priv->web_view = WEBKIT_WEB_VIEW (widget);

	progress_bar = gtk_progress_bar_new ();
	g_object_set (
		G_OBJECT (progress_bar),
		"hexpand", TRUE,
		"vexpand", FALSE,
		"halign", GTK_ALIGN_FILL,
		"valign", GTK_ALIGN_START,
		"orientation", GTK_ORIENTATION_HORIZONTAL,
		"ellipsize", PANGO_ELLIPSIZE_END,
		"fraction", 0.0,
		NULL);
	gtk_style_context_add_class (gtk_widget_get_style_context (progress_bar), GTK_STYLE_CLASS_OSD);

	gtk_box_pack_start (GTK_BOX (vbox), progress_bar, FALSE, FALSE, 0);

	gtk_widget_show_all (GTK_WIDGET (grid));

	uri = cpi_oauth2_create_auth_uri (prompter_oauth2->priv->service, prompter_oauth2->priv->cred_source);
	if (!uri) {
		success = FALSE;
	} else {
		WebKitWebView *web_view = prompter_oauth2->priv->web_view;
		gulong decide_policy_handler_id, load_finished_handler_id, progress_handler_id;

		decide_policy_handler_id = g_signal_connect (web_view, "decide-policy",
			G_CALLBACK (cpi_oauth2_decide_policy_cb), prompter_oauth2);
		load_finished_handler_id = g_signal_connect (web_view, "load-changed",
			G_CALLBACK (cpi_oauth2_document_load_changed_cb), prompter_oauth2);
		progress_handler_id = g_signal_connect (web_view, "notify::estimated-load-progress",
			G_CALLBACK (cpi_oauth2_notify_estimated_load_progress_cb), progress_bar);

		webkit_web_view_load_uri (web_view, uri);

		success = gtk_dialog_run (prompter_oauth2->priv->dialog) == GTK_RESPONSE_OK;

		if (decide_policy_handler_id)
			g_signal_handler_disconnect (web_view, decide_policy_handler_id);
		if (load_finished_handler_id)
			g_signal_handler_disconnect (web_view, load_finished_handler_id);
		if (progress_handler_id)
			g_signal_handler_disconnect (web_view, progress_handler_id);
	}

	if (prompter_oauth2->priv->cancellable)
		g_cancellable_cancel (prompter_oauth2->priv->cancellable);

	prompter_oauth2->priv->web_view = NULL;
	prompter_oauth2->priv->dialog = NULL;
	gtk_widget_destroy (dialog);

	g_string_free (info_markup, TRUE);
	g_free (title);

	return success;
#else /* ENABLE_OAUTH2 */
	return FALSE;
#endif /* ENABLE_OAUTH2 */
}

static void
e_credentials_prompter_impl_oauth2_free_prompt_data (ECredentialsPrompterImplOAuth2 *prompter_oauth2)
{
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_oauth2));

	prompter_oauth2->priv->prompt_id = NULL;

	g_clear_object (&prompter_oauth2->priv->auth_source);
	g_clear_object (&prompter_oauth2->priv->cred_source);
	g_clear_object (&prompter_oauth2->priv->service);

	g_free (prompter_oauth2->priv->error_text);
	prompter_oauth2->priv->error_text = NULL;

	e_named_parameters_free (prompter_oauth2->priv->credentials);
	prompter_oauth2->priv->credentials = NULL;
}

static gboolean
e_credentials_prompter_impl_oauth2_manage_dialog_idle_cb (gpointer user_data)
{
	ECredentialsPrompterImplOAuth2 *prompter_oauth2 = user_data;

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_oauth2), FALSE);

	g_mutex_lock (&prompter_oauth2->priv->property_lock);
	if (g_source_get_id (g_main_current_source ()) == prompter_oauth2->priv->show_dialog_idle_id) {
		gboolean success, has_service;

		prompter_oauth2->priv->show_dialog_idle_id = 0;
		has_service = prompter_oauth2->priv->service != NULL;

		g_mutex_unlock (&prompter_oauth2->priv->property_lock);

		g_warn_if_fail (prompter_oauth2->priv->dialog == NULL);

		if (has_service)
			success = e_credentials_prompter_impl_oauth2_show_dialog (prompter_oauth2);
		else
			success = FALSE;

		e_credentials_prompter_impl_prompt_finish (
			E_CREDENTIALS_PROMPTER_IMPL (prompter_oauth2),
			prompter_oauth2->priv->prompt_id,
			success ? prompter_oauth2->priv->credentials : NULL);

		e_credentials_prompter_impl_oauth2_free_prompt_data (prompter_oauth2);
	} else {
		gpointer prompt_id = prompter_oauth2->priv->prompt_id;

		g_warning ("%s: Prompt's %p source cancelled? current:%d expected:%d", G_STRFUNC, prompt_id, (gint) g_source_get_id (g_main_current_source ()), (gint) prompter_oauth2->priv->show_dialog_idle_id);

		if (!prompter_oauth2->priv->show_dialog_idle_id)
			e_credentials_prompter_impl_oauth2_free_prompt_data (prompter_oauth2);

		g_mutex_unlock (&prompter_oauth2->priv->property_lock);

		if (prompt_id)
			e_credentials_prompter_impl_prompt_finish (E_CREDENTIALS_PROMPTER_IMPL (prompter_oauth2), prompt_id, NULL);
	}

	return FALSE;
}

static void
e_credentials_prompter_impl_oauth2_process_prompt (ECredentialsPrompterImpl *prompter_impl,
						   gpointer prompt_id,
						   ESource *auth_source,
						   ESource *cred_source,
						   const gchar *error_text,
						   const ENamedParameters *credentials)
{
	ECredentialsPrompterImplOAuth2 *prompter_oauth2;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_impl));

	prompter_oauth2 = E_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_impl);
	g_return_if_fail (prompter_oauth2->priv->prompt_id == NULL);

	g_mutex_lock (&prompter_oauth2->priv->property_lock);
	if (prompter_oauth2->priv->show_dialog_idle_id != 0) {
		g_mutex_unlock (&prompter_oauth2->priv->property_lock);
		g_warning ("%s: Already processing other prompt", G_STRFUNC);
		return;
	}
	g_mutex_unlock (&prompter_oauth2->priv->property_lock);

	prompter_oauth2->priv->prompt_id = prompt_id;
	prompter_oauth2->priv->auth_source = g_object_ref (auth_source);
	prompter_oauth2->priv->cred_source = g_object_ref (cred_source);
	prompter_oauth2->priv->service = e_oauth2_services_find (prompter_oauth2->priv->oauth2_services, cred_source);
	prompter_oauth2->priv->error_text = g_strdup (error_text);
	prompter_oauth2->priv->credentials = e_named_parameters_new_clone (credentials);
	prompter_oauth2->priv->cancellable = g_cancellable_new ();

	g_mutex_lock (&prompter_oauth2->priv->property_lock);
	prompter_oauth2->priv->refresh_failed_with_transport_error = FALSE;
	prompter_oauth2->priv->show_dialog_idle_id = g_idle_add (
		e_credentials_prompter_impl_oauth2_manage_dialog_idle_cb,
		prompter_oauth2);
	g_mutex_unlock (&prompter_oauth2->priv->property_lock);
}

static void
e_credentials_prompter_impl_oauth2_cancel_prompt (ECredentialsPrompterImpl *prompter_impl,
						  gpointer prompt_id)
{
	ECredentialsPrompterImplOAuth2 *prompter_oauth2;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_impl));

	prompter_oauth2 = E_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (prompter_impl);
	g_return_if_fail (prompter_oauth2->priv->prompt_id == prompt_id);

	if (prompter_oauth2->priv->cancellable)
		g_cancellable_cancel (prompter_oauth2->priv->cancellable);

	/* This also closes the dialog. */
	if (prompter_oauth2->priv->dialog)
		gtk_dialog_response (prompter_oauth2->priv->dialog, GTK_RESPONSE_CANCEL);
}

static void
e_credentials_prompter_impl_oauth2_constructed (GObject *object)
{
	ECredentialsPrompterImplOAuth2 *prompter_oauth2 = E_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (object);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_credentials_prompter_impl_oauth2_parent_class)->constructed (object);

	if (prompter_oauth2->priv->oauth2_services) {
		ECredentialsPrompter *prompter;
		ECredentialsPrompterImpl *prompter_impl;
		GSList *services, *link;

		prompter_impl = E_CREDENTIALS_PROMPTER_IMPL (prompter_oauth2);
		prompter = E_CREDENTIALS_PROMPTER (e_extension_get_extensible (E_EXTENSION (prompter_impl)));

		services = e_oauth2_services_list (prompter_oauth2->priv->oauth2_services);

		for (link = services; link; link = g_slist_next (link)) {
			EOAuth2Service *service = link->data;

			if (service && e_oauth2_service_get_name (service)) {
				e_credentials_prompter_register_impl (prompter, e_oauth2_service_get_name (service), prompter_impl);
			}
		}

		g_slist_free_full (services, g_object_unref);
	}
}

static void
e_credentials_prompter_impl_oauth2_dispose (GObject *object)
{
	ECredentialsPrompterImplOAuth2 *prompter_oauth2 = E_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (object);

	g_mutex_lock (&prompter_oauth2->priv->property_lock);
	if (prompter_oauth2->priv->show_dialog_idle_id) {
		g_source_remove (prompter_oauth2->priv->show_dialog_idle_id);
		prompter_oauth2->priv->show_dialog_idle_id = 0;
	}
	g_mutex_unlock (&prompter_oauth2->priv->property_lock);

	if (prompter_oauth2->priv->cancellable) {
		g_cancellable_cancel (prompter_oauth2->priv->cancellable);
		g_clear_object (&prompter_oauth2->priv->cancellable);
	}

	g_warn_if_fail (prompter_oauth2->priv->prompt_id == NULL);
	g_warn_if_fail (prompter_oauth2->priv->dialog == NULL);

	e_credentials_prompter_impl_oauth2_free_prompt_data (prompter_oauth2);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_credentials_prompter_impl_oauth2_parent_class)->dispose (object);
}

static void
e_credentials_prompter_impl_oauth2_finalize (GObject *object)
{
	ECredentialsPrompterImplOAuth2 *prompter_oauth2 = E_CREDENTIALS_PROMPTER_IMPL_OAUTH2 (object);

	g_clear_object (&prompter_oauth2->priv->oauth2_services);
	g_mutex_clear (&prompter_oauth2->priv->property_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_credentials_prompter_impl_oauth2_parent_class)->finalize (object);
}

static void
e_credentials_prompter_impl_oauth2_class_init (ECredentialsPrompterImplOAuth2Class *class)
{
	/* No static known, rather figure them out in runtime */
	static const gchar *authentication_methods[] = {
		NULL
	};

	GObjectClass *object_class;
	ECredentialsPrompterImplClass *prompter_impl_class;

	g_type_class_add_private (class, sizeof (ECredentialsPrompterImplOAuth2Private));

	object_class = G_OBJECT_CLASS (class);
	object_class->constructed = e_credentials_prompter_impl_oauth2_constructed;
	object_class->dispose = e_credentials_prompter_impl_oauth2_dispose;
	object_class->finalize = e_credentials_prompter_impl_oauth2_finalize;

	prompter_impl_class = E_CREDENTIALS_PROMPTER_IMPL_CLASS (class);
	prompter_impl_class->authentication_methods = (const gchar * const *) authentication_methods;
	prompter_impl_class->process_prompt = e_credentials_prompter_impl_oauth2_process_prompt;
	prompter_impl_class->cancel_prompt = e_credentials_prompter_impl_oauth2_cancel_prompt;
}

static void
e_credentials_prompter_impl_oauth2_init (ECredentialsPrompterImplOAuth2 *prompter_oauth2)
{
	prompter_oauth2->priv = G_TYPE_INSTANCE_GET_PRIVATE (prompter_oauth2,
		E_TYPE_CREDENTIALS_PROMPTER_IMPL_OAUTH2, ECredentialsPrompterImplOAuth2Private);

	g_mutex_init (&prompter_oauth2->priv->property_lock);

	prompter_oauth2->priv->oauth2_services = e_oauth2_services_new ();
}

/**
 * e_credentials_prompter_impl_oauth2_new:
 *
 * Creates a new instance of an #ECredentialsPrompterImplOAuth2.
 *
 * Returns: (transfer full): a newly created #ECredentialsPrompterImplOAuth2,
 *    which should be freed with g_object_unref() when no longer needed.
 *
 * Since: 3.28
 **/
ECredentialsPrompterImpl *
e_credentials_prompter_impl_oauth2_new (void)
{
	return g_object_new (E_TYPE_CREDENTIALS_PROMPTER_IMPL_OAUTH2, NULL);
}
