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

#include <string.h>

#include <glib.h>
#include <glib/gi18n-lib.h>

#define GCR_API_SUBJECT_TO_CHANGE
#include <gcr/gcr.h>
#undef GCR_API_SUBJECT_TO_CHANGE

#include <camel/camel.h>
#include <libebackend/libebackend.h>
#include <libedataserver/libedataserver.h>

#include "e-trust-prompt.h"

static void
trust_prompt_add_info_line (GtkGrid *grid,
                            const gchar *label_text,
                            const gchar *value_text,
                            gboolean ellipsize,
			    gboolean wrap,
			    gboolean use_bold,
                            gint *at_row)
{
	GtkWidget *widget;
	PangoAttribute *attr;
	PangoAttrList *bold;

	g_return_if_fail (grid != NULL);
	g_return_if_fail (label_text != NULL);
	g_return_if_fail (at_row != NULL);

	if (!value_text || !*value_text)
		return;

	bold = pango_attr_list_new ();
	attr = pango_attr_weight_new (PANGO_WEIGHT_BOLD);
	pango_attr_list_insert (bold, attr);

	widget = gtk_label_new (label_text);
	gtk_misc_set_padding (GTK_MISC (widget), 0, 0);
	gtk_misc_set_alignment (GTK_MISC (widget), 0.0, 0.0);

	gtk_grid_attach (grid, widget, 1, *at_row, 1, 1);

	widget = gtk_label_new (value_text);
	gtk_label_set_line_wrap (GTK_LABEL (widget), wrap);
	g_object_set (
		G_OBJECT (widget),
		"hexpand", TRUE,
		"halign", GTK_ALIGN_FILL,
		"justify", GTK_JUSTIFY_LEFT,
		"attributes", use_bold ? bold : NULL,
		"selectable", TRUE,
		"ellipsize", ellipsize ? PANGO_ELLIPSIZE_END : PANGO_ELLIPSIZE_NONE,
		"width-chars", 60,
		"max-width-chars", 80,
		"xalign", 0.0,
		"yalign", 0.0,
		NULL);

	gtk_grid_attach (grid, widget, 2, *at_row, 1, 1);

	*at_row = (*at_row) + 1;

	pango_attr_list_unref (bold);
}

static ETrustPromptResponse
trust_prompt_show (GtkWindow *parent,
		   const gchar *source_extension,
		   const gchar *source_display_name,
		   const gchar *host,
		   const gchar *error_text,
		   GcrParsed *parsed,
		   const gchar *reason,
		   void (* dialog_ready_cb) (GtkDialog *dialog, gpointer user_data),
		   gpointer user_data)
{
	ETrustPromptResponse response;
	GcrCertificateWidget *certificate_widget;
	GcrCertificate *certificate;
	GckAttributes *attributes;
	GtkWidget *dialog, *widget;
	GtkGrid *grid;
	const guchar *data;
	gchar *bhost, *tmp;
	gsize length;
	gint row = 0;

	dialog = gtk_dialog_new_with_buttons (
		_("Certificate trust..."), parent, GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
		_("_Cancel"), GTK_RESPONSE_CANCEL,
		_("_Reject"), GTK_RESPONSE_REJECT,
		_("Accept _Temporarily"), GTK_RESPONSE_YES,
		_("_Accept Permanently"), GTK_RESPONSE_ACCEPT,
		NULL);

	widget = gtk_dialog_get_content_area (GTK_DIALOG (dialog));

	gtk_container_set_border_width (GTK_CONTAINER (dialog), 5);

	grid = g_object_new (
		GTK_TYPE_GRID,
		"orientation", GTK_ORIENTATION_HORIZONTAL,
		"row-homogeneous", FALSE,
		"row-spacing", 6,
		"column-homogeneous", FALSE,
		"column-spacing", 12,
		"hexpand", TRUE,
		"halign", GTK_ALIGN_FILL,
		"vexpand", TRUE,
		"valign", GTK_ALIGN_FILL,
		NULL);

	gtk_container_set_border_width (GTK_CONTAINER (grid), 5);
	gtk_container_add (GTK_CONTAINER (widget), GTK_WIDGET (grid));

	widget = gtk_image_new_from_icon_name ("dialog-warning", GTK_ICON_SIZE_DIALOG);
	g_object_set (
		G_OBJECT (widget),
		"vexpand", FALSE,
		"valign", GTK_ALIGN_START,
		NULL);
	gtk_grid_attach (grid, widget, 0, row, 1, 3);

	tmp = g_markup_escape_text (host, -1);
	bhost = g_strconcat ("<b>", tmp, "</b>", NULL);
	g_free (tmp);
	tmp = NULL;
	if (source_extension && source_display_name) {
		gchar *bsource_display_name = g_strconcat ("<b>", source_display_name, "</b>", NULL);

		if (g_str_equal (source_extension, E_SOURCE_EXTENSION_ADDRESS_BOOK)) {
			tmp = g_strdup_printf (
				"An address book '%s' cannot connect, because an SSL/TLS certificate for '%s' is not trusted. Do you wish to accept it?",
				bsource_display_name, bhost);
		} else if (g_str_equal (source_extension, E_SOURCE_EXTENSION_CALENDAR)) {
			tmp = g_strdup_printf (
				"A calendar '%s' cannot connect, because an SSL/TLS certificate for '%s' is not trusted. Do you wish to accept it?",
				bsource_display_name, bhost);
		} else if (g_str_equal (source_extension, E_SOURCE_EXTENSION_MEMO_LIST)) {
			tmp = g_strdup_printf (
				"A memo list '%s' cannot connect, because an SSL/TLS certificate for '%s' is not trusted. Do you wish to accept it?",
				bsource_display_name, bhost);
		} else if (g_str_equal (source_extension, E_SOURCE_EXTENSION_TASK_LIST)) {
			tmp = g_strdup_printf (
				"A task list '%s' cannot connect, because an SSL/TLS certificate for '%s' is not trusted. Do you wish to accept it?",
				bsource_display_name, bhost);
		} else if (g_str_equal (source_extension, E_SOURCE_EXTENSION_MAIL_ACCOUNT)) {
			tmp = g_strdup_printf (
				"A mail account '%s' cannot connect, because an SSL/TLS certificate for '%s' is not trusted. Do you wish to accept it?",
				bsource_display_name, bhost);
		} else if (g_str_equal (source_extension, E_SOURCE_EXTENSION_MAIL_TRANSPORT)) {
			tmp = g_strdup_printf (
				"A mail transport '%s' cannot connect, because an SSL/TLS certificate for '%s' is not trusted. Do you wish to accept it?",
				bsource_display_name, bhost);
		} else {
			tmp = g_strdup_printf (
				"An account '%s' cannot connect, because an SSL/TLS certificate for '%s' is not trusted. Do you wish to accept it?",
				bsource_display_name, bhost);
		}

		g_free (bsource_display_name);
	}
	if (!tmp)
		tmp = g_strdup_printf (_("SSL/TLS certificate for “%s” is not trusted. Do you wish to accept it?"), bhost);
	g_free (bhost);

	widget = gtk_label_new (NULL);
	gtk_label_set_line_wrap (GTK_LABEL (widget), TRUE);
	gtk_label_set_markup (GTK_LABEL (widget), tmp);
	g_object_set (
		G_OBJECT (widget),
		"hexpand", TRUE,
		"halign", GTK_ALIGN_FILL,
		"valign", GTK_ALIGN_CENTER,
		"width-chars", 60,
		"max-width-chars", 80,
		"xalign", 0.0,
		"yalign", 0.0,
		NULL);

	g_free (tmp);

	gtk_grid_attach (grid, widget, 1, row, 2, 1);
	row++;

	trust_prompt_add_info_line (grid, _("Reason:"), reason, FALSE, FALSE, TRUE, &row);

	if (error_text)
		trust_prompt_add_info_line (grid, _("Detailed error:"), error_text, FALSE, TRUE, FALSE, &row);

	data = gcr_parsed_get_data (parsed, &length);
	attributes = gcr_parsed_get_attributes (parsed);

	certificate = gcr_simple_certificate_new (data, length);

	certificate_widget = gcr_certificate_widget_new (certificate);
	gcr_certificate_widget_set_attributes (certificate_widget, attributes);

	widget = GTK_WIDGET (certificate_widget);
	gtk_grid_attach (grid, widget, 1, row, 2, 1);
	gtk_widget_show (widget);

	g_clear_object (&certificate);

	gtk_widget_show_all (GTK_WIDGET (grid));

	if (dialog_ready_cb)
		dialog_ready_cb (GTK_DIALOG (dialog), user_data);

	switch (gtk_dialog_run (GTK_DIALOG (dialog))) {
	case GTK_RESPONSE_REJECT:
		response = E_TRUST_PROMPT_RESPONSE_REJECT;
		break;
	case GTK_RESPONSE_ACCEPT:
		response = E_TRUST_PROMPT_RESPONSE_ACCEPT;
		break;
	case GTK_RESPONSE_YES:
		response = E_TRUST_PROMPT_RESPONSE_ACCEPT_TEMPORARILY;
		break;
	default:
		response = E_TRUST_PROMPT_RESPONSE_UNKNOWN;
		break;
	}

	gtk_widget_destroy (dialog);

	return response;
}

/**
 * e_trust_prompt_describe_certificate_errors:
 * @flags: a #GTlsCertificateFlags to describe
 *
 * Converts @flags into a localized text description of the set bits, one
 * bit description per line. If no bit is set, then an empty string is
 * returned.
 *
 * Returns: A newly allocated string with text description
 *  of @flags. Free the returned pointer with g_free() when no longer needed.
 *
 * Since: 3.16
 **/
gchar *
e_trust_prompt_describe_certificate_errors (GTlsCertificateFlags flags)
{
	struct _convert_table {
		GTlsCertificateFlags flag;
		const gchar *description;
	} convert_table[] = {
		{ G_TLS_CERTIFICATE_UNKNOWN_CA,
		  N_("The signing certificate authority is not known.") },
		{ G_TLS_CERTIFICATE_BAD_IDENTITY,
		  N_("The certificate does not match the expected identity of the site that it was retrieved from.") },
		{ G_TLS_CERTIFICATE_NOT_ACTIVATED,
		  N_("The certificate’s activation time is still in the future.") },
		{ G_TLS_CERTIFICATE_EXPIRED,
		  N_("The certificate has expired.") },
		{ G_TLS_CERTIFICATE_REVOKED,
		  N_("The certificate has been revoked according to the connection’s certificate revocation list.") },
		{ G_TLS_CERTIFICATE_INSECURE,
		  N_("The certificate’s algorithm is considered insecure.") }
	};

	GString *reason = g_string_new ("");
	gint ii;

	for (ii = 0; ii < G_N_ELEMENTS (convert_table); ii++) {
		if ((flags & convert_table[ii].flag) != 0) {
			if (reason->len > 0)
				g_string_append (reason, "\n");

			g_string_append (reason, _(convert_table[ii].description));
		}
	}

	return g_string_free (reason, FALSE);
}

static void
trust_prompt_parser_parsed_cb (GcrParser *parser,
			       GcrParsed **out_parsed)
{
	GcrParsed *parsed;

	parsed = gcr_parser_get_parsed (parser);
	g_return_if_fail (parsed != NULL);

	*out_parsed = gcr_parsed_ref (parsed);
}

static ETrustPromptResponse
e_trust_prompt_run_with_dialog_ready_callback (GtkWindow *parent,
					       const gchar *source_extension,
					       const gchar *source_display_name,
					       const gchar *host,
					       const gchar *certificate_pem,
					       GTlsCertificateFlags certificate_errors,
					       const gchar *error_text,
					       void (* dialog_ready_cb) (GtkDialog *dialog, gpointer user_data),
					       gpointer user_data)
{
	ETrustPromptResponse response = E_TRUST_PROMPT_RESPONSE_UNKNOWN;
	GcrParser *parser;
	GcrParsed *parsed = NULL;
	GError *local_error = NULL;

	if (parent)
		g_return_val_if_fail (GTK_IS_WINDOW (parent), E_TRUST_PROMPT_RESPONSE_UNKNOWN);
	g_return_val_if_fail (host != NULL, E_TRUST_PROMPT_RESPONSE_UNKNOWN);
	g_return_val_if_fail (certificate_pem != NULL, E_TRUST_PROMPT_RESPONSE_UNKNOWN);

	/* Continue even if PKCS#11 module registration fails.
	 * Certificate details won't display correctly but the
	 * user can still respond to the prompt. */
	gcr_pkcs11_initialize (NULL, &local_error);
	if (local_error != NULL) {
		g_warning ("%s: gcr_pkcs11_initialize() call failed: %s", G_STRFUNC, local_error->message);
		g_clear_error (&local_error);
	}

	parser = gcr_parser_new ();

	g_signal_connect (
		parser, "parsed",
		G_CALLBACK (trust_prompt_parser_parsed_cb), &parsed);

	gcr_parser_parse_data (parser, (const guchar *) certificate_pem, strlen (certificate_pem), &local_error);

	g_object_unref (parser);

	/* Sanity check. */
	g_warn_if_fail (
		((parsed != NULL) && (local_error == NULL)) ||
		((parsed == NULL) && (local_error != NULL)));

	if (parsed != NULL) {
		gchar *reason;

		reason = e_trust_prompt_describe_certificate_errors (certificate_errors);

		response = trust_prompt_show (parent, source_extension, source_display_name, host, error_text, parsed, reason, dialog_ready_cb, user_data);

		gcr_parsed_unref (parsed);
		g_free (reason);
	}

	g_clear_error (&local_error);

	return response;
}

/**
 * e_trust_prompt_run_modal:
 * @parent: A #GtkWindow to use as a parent for the trust prompt dialog
 * @source_extension: (allow-none): an #ESource extension, to identify a kind of the source; or %NULL
 * @source_display_name: (allow-none): an #ESource display name, to identify what prompts; or %NULL
 * @host: a host name to which the certificate belongs
 * @certificate_pem: a PEM-encoded certificate for which to show the trust prompt
 * @certificate_errors: errors of the @certificate_pem
 * @error_text: (allow-none): an optional error text to show in the dialog; can be %NULL
 *
 * Runs modal (doesn't return until the dialog is closed) a trust prompt dialog,
 * it is a prompt whether a user wants to accept or reject the @certificate_pem
 * for the @host due to the @certificate_errors errors.
 *
 * The pair @source_extension and @source_display_name influences the trust prompt message.
 * If both are set, then the message also contains which source failed to connect according
 * to these two arguments.
 *
 * The dialog can contain a custom error text, passed in as @error_text.
 * The error might be a detailed error string returned by the server. If set,
 * it is prefixed with "Detailed error:" string.
 *
 * Returns: A code of the user's choice. The #E_TRUST_PROMPT_RESPONSE_UNKNOWN
 *    is returned, when the user cancelled the trust prompt dialog.
 *
 * Since: 3.16
 **/
ETrustPromptResponse
e_trust_prompt_run_modal (GtkWindow *parent,
			  const gchar *source_extension,
			  const gchar *source_display_name,
			  const gchar *host,
			  const gchar *certificate_pem,
			  GTlsCertificateFlags certificate_errors,
			  const gchar *error_text)
{
	if (parent)
		g_return_val_if_fail (GTK_IS_WINDOW (parent), E_TRUST_PROMPT_RESPONSE_UNKNOWN);
	g_return_val_if_fail (host != NULL, E_TRUST_PROMPT_RESPONSE_UNKNOWN);
	g_return_val_if_fail (certificate_pem != NULL, E_TRUST_PROMPT_RESPONSE_UNKNOWN);

	return e_trust_prompt_run_with_dialog_ready_callback (parent, source_extension, source_display_name, host,
		certificate_pem, certificate_errors, error_text, NULL, NULL);
}

static void
source_connection_status_changed_cb (ESource *source,
				     GParamSpec *param,
				     GtkDialog *dialog)
{
	g_return_if_fail (GTK_IS_DIALOG (dialog));

	/* Do not close the prompt when the source is still waiting for the credentials. */
	if (e_source_get_connection_status (source) != E_SOURCE_CONNECTION_STATUS_AWAITING_CREDENTIALS &&
	    e_source_get_connection_status (source) != E_SOURCE_CONNECTION_STATUS_SSL_FAILED)
		gtk_dialog_response (dialog, GTK_RESPONSE_CANCEL);
}

static void
trust_prompt_listen_for_source_changes_cb (GtkDialog *dialog,
					   gpointer user_data)
{
	ESource *source = user_data;

	g_return_if_fail (GTK_IS_DIALOG (dialog));
	g_return_if_fail (E_IS_SOURCE (source));

	g_signal_connect (source, "notify::connection-status",
		G_CALLBACK (source_connection_status_changed_cb), dialog);
}

typedef struct _SaveSourceData {
	ETrustPromptResponse response;
	gboolean call_save;
	GError *error;
} SaveSourceData;

static void
save_source_data_free (gpointer ptr)
{
	SaveSourceData *data = ptr;

	if (data) {
		g_clear_error (&data->error);
		g_free (data);
	}
}

static void
save_source_thread (GTask *task,
		    gpointer source_object,
		    gpointer task_data,
		    GCancellable *cancellable)
{
	ESource *source = source_object;
	SaveSourceData *data = task_data;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (data != NULL);

	if (data->error)
		local_error = g_error_copy (data->error);
	else if (data->call_save)
		e_source_write_sync (source, cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, TRUE);
	}
}

static gchar *
trust_prompt_get_host_from_url (const gchar *url)
{
	SoupURI *suri;
	gchar *host;

	if (!url || !*url)
		return NULL;

	suri = soup_uri_new (url);
	if (!suri)
		return NULL;

	host = g_strdup (soup_uri_get_host (suri));

	if (!host || !*host) {
		g_free (host);
		host = NULL;
	}

	soup_uri_free (suri);

	return host;
}

/**
 * e_trust_prompt_run_for_source:
 * @parent: A #GtkWindow to use as a parent for the trust prompt dialog
 * @source: an #ESource, with %E_SOURCE_EXTENSION_AUTHENTICATION
 * @certificate_pem: a PEM-encoded certificate for which to show the trust prompt
 * @certificate_errors: errors of the @certificate_pem
 * @error_text: (allow-none): an optional error text to show in the dialog; can be %NULL
 * @allow_source_save: whether can also save any @source changes
 * @cancellable: (allow-none): a #GCancellable, or %NULL
 * @callback: a callback to call, when the prompt (an @source save) is done
 * @user_data: user data passed into @callback
 *
 * Similar to e_trust_prompt_run_modal(), except it also manages all the necessary things
 * around the @source<!-- -->'s SSL/TLS trust properties when it also contains %E_SOURCE_EXTENSION_WEBDAV,
 * thus the SSL/TLS trust on the WebDAV @source is properly updated based on the user's choice.
 * The call is finished with e_trust_prompt_run_for_source_finish(),
 * which also returns the user's choice. The finish happens in the @callback.
 * This is necessary, because the @source can be also saved.
 *
 * The function fails, if the @source doesn't contain the %E_SOURCE_EXTENSION_AUTHENTICATION.
 *
 * Note: The dialog is not shown when the stored certificate trust in the WebDAV @source
 *    matches the @certificate_pem and the stored result is #E_TRUST_PROMPT_RESPONSE_REJECT.
 *
 * Since: 3.16
 **/
void
e_trust_prompt_run_for_source (GtkWindow *parent,
			       ESource *source,
			       const gchar *certificate_pem,
			       GTlsCertificateFlags certificate_errors,
			       const gchar *error_text,
			       gboolean allow_source_save,
			       GCancellable *cancellable,
			       GAsyncReadyCallback callback,
			       gpointer user_data)
{
	ESourceAuthentication *extension_authentication = NULL;
	ESourceWebdav *extension_webdav = NULL;
	SaveSourceData *save_data;
	GTlsCertificate *certificate;
	gchar *host;
	GTask *task;

	if (parent)
		g_return_if_fail (GTK_IS_WINDOW (parent));
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (certificate_pem != NULL);

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_GOA) ||
	    e_source_has_extension (source, E_SOURCE_EXTENSION_UOA)) {
		/* Make sure that GOA/UOA collection sources contain these extensions too */
		g_warn_if_fail (e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION));
		g_warn_if_fail (e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND));
	}

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION))
		extension_authentication = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);
	if (e_source_has_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND))
		extension_webdav = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);

	save_data = g_new0 (SaveSourceData, 1);
	save_data->response = E_TRUST_PROMPT_RESPONSE_UNKNOWN;
	save_data->call_save = FALSE;

	/* Lookup used host name */
	if (extension_authentication)
		host = e_source_authentication_dup_host (extension_authentication);
	else
		host = NULL;

	if (!host || !*host) {
		g_free (host);
		host = NULL;

		if (e_source_has_extension (source, E_SOURCE_EXTENSION_GOA)) {
			ESourceGoa *goa_extension;
			gchar *url;

			goa_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_GOA);

			url = e_source_goa_dup_calendar_url (goa_extension);
			host = trust_prompt_get_host_from_url (url);
			g_free (url);

			if (!host) {
				url = e_source_goa_dup_contacts_url (goa_extension);
				host = trust_prompt_get_host_from_url (url);
				g_free (url);
			}
		}
	}

	certificate = g_tls_certificate_new_from_pem (certificate_pem, -1, &save_data->error);
	if (certificate) {
		if (extension_webdav && host)
			save_data->response = e_source_webdav_verify_ssl_trust (extension_webdav, host, certificate, 0);
		else
			save_data->response = E_TRUST_PROMPT_RESPONSE_REJECT_TEMPORARILY;

		if (save_data->response != E_TRUST_PROMPT_RESPONSE_REJECT) {
			const gchar *source_extension = NULL;

			if (e_source_has_extension (source, E_SOURCE_EXTENSION_ADDRESS_BOOK))
				source_extension = E_SOURCE_EXTENSION_ADDRESS_BOOK;

			if (e_source_has_extension (source, E_SOURCE_EXTENSION_CALENDAR)) {
				if (!source_extension)
					source_extension = E_SOURCE_EXTENSION_CALENDAR;
				else
					source_extension = E_SOURCE_EXTENSION_COLLECTION;
			}

			if (e_source_has_extension (source, E_SOURCE_EXTENSION_MEMO_LIST)) {
				if (!source_extension)
					source_extension = E_SOURCE_EXTENSION_MEMO_LIST;
				else
					source_extension = E_SOURCE_EXTENSION_COLLECTION;
			}

			if (e_source_has_extension (source, E_SOURCE_EXTENSION_TASK_LIST)) {
				if (!source_extension)
					source_extension = E_SOURCE_EXTENSION_TASK_LIST;
				else
					source_extension = E_SOURCE_EXTENSION_COLLECTION;
			}

			if (e_source_has_extension (source, E_SOURCE_EXTENSION_MAIL_ACCOUNT)) {
				if (!source_extension)
					source_extension = E_SOURCE_EXTENSION_MAIL_ACCOUNT;
				else
					source_extension = E_SOURCE_EXTENSION_COLLECTION;
			}

			if (e_source_has_extension (source, E_SOURCE_EXTENSION_MAIL_TRANSPORT)) {
				if (!source_extension)
					source_extension = E_SOURCE_EXTENSION_MAIL_TRANSPORT;
				else
					source_extension = E_SOURCE_EXTENSION_COLLECTION;
			}

			save_data->response = e_trust_prompt_run_with_dialog_ready_callback (parent,
				source_extension, e_source_get_display_name (source), host,
				certificate_pem, certificate_errors, error_text,
				trust_prompt_listen_for_source_changes_cb, source);
		}
	}

	g_signal_handlers_disconnect_matched (source, G_SIGNAL_MATCH_FUNC, 0, 0, NULL,
		source_connection_status_changed_cb, NULL);

	if (save_data->response != E_TRUST_PROMPT_RESPONSE_UNKNOWN) {
		if (certificate && extension_webdav) {
			e_source_webdav_update_ssl_trust (extension_webdav, host, certificate, save_data->response);
			save_data->call_save = allow_source_save;
		}
	}

	g_clear_object (&certificate);
	g_free (host);

	task = g_task_new (source, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_trust_prompt_run_for_source);
	g_task_set_task_data (task, save_data, save_source_data_free);

	g_task_run_in_thread (task, save_source_thread);

	g_object_unref (task);
}

/**
 * e_trust_prompt_run_for_source_finish:
 * @source: an #ESource which was used with e_trust_prompt_run_for_source()
 * @result: a #GAsyncResult
 * @response: an output argument, user's response to the trust prompt
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_trust_prompt_run_for_source().
 * The @response will contain a code of the user's choice.
 * The #E_TRUST_PROMPT_RESPONSE_UNKNOWN is used, when the user cancelled the trust
 * prompt dialog and no changes are made with the @source.
 *
 * If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.16
 **/
gboolean
e_trust_prompt_run_for_source_finish (ESource *source,
				      GAsyncResult *result,
				      ETrustPromptResponse *response,
				      GError **error)
{
	gboolean success;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, source), FALSE);
	g_return_val_if_fail (response != NULL, FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_trust_prompt_run_for_source), FALSE);

	success = g_task_propagate_boolean (G_TASK (result), error);

	if (success) {
		SaveSourceData *save_data;

		save_data = g_task_get_task_data (G_TASK (result));
		g_return_val_if_fail (save_data != NULL, FALSE);

		*response = save_data->response;
	}

	return success;
}
