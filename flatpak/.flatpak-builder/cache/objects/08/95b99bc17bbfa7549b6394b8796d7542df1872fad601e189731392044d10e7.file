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
#include "e-credentials-prompter-impl-password.h"

struct _ECredentialsPrompterImplPasswordPrivate {
	gpointer prompt_id;
	ESource *auth_source;
	ESource *cred_source;
	gchar *error_text;
	ENamedParameters *credentials;

	GtkDialog *dialog;
	gulong show_dialog_idle_id;
};

G_DEFINE_TYPE (ECredentialsPrompterImplPassword, e_credentials_prompter_impl_password, E_TYPE_CREDENTIALS_PROMPTER_IMPL)

static gboolean
password_dialog_map_event_cb (GtkWidget *dialog,
			      GdkEvent *event,
			      GtkWidget *entry)
{
	gtk_widget_grab_focus (entry);

	return FALSE;
}

static void
credentials_prompter_impl_password_get_prompt_strings (ESourceRegistry *registry,
						       ESource *source,
						       gchar **prompt_title,
						       GString **prompt_description)
{
	GString *description;
	const gchar *message;
	gchar *display_name;
	gchar *host_name = NULL;

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

	/* XXX This is kind of a hack but it should work for now.  Build a
	 *     suitable password prompt by checking for various extensions
	 *     in the ESource.  If no recognizable extensions are found, or
	 *     if the result is ambiguous, just refer to the data source as
	 *     an "account". */

	display_name = e_util_get_source_full_name (registry, source);

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
		ESourceAuthentication *extension;

		extension = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);
		host_name = e_source_authentication_dup_host (extension);
	}

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
			message = _("Address book authentication request");
			break;
		case TYPE_CALENDAR:
		case TYPE_MEMO_LIST:
		case TYPE_TASK_LIST:
			message = _("Calendar authentication request");
			break;
		case TYPE_MAIL_ACCOUNT:
		case TYPE_MAIL_TRANSPORT:
			message = _("Mail authentication request");
			break;
		default:  /* generic account prompt */
			message = _("Authentication request");
			break;
	}

	description = g_string_sized_new (256);

	g_string_append_printf (description, "<big><b>%s</b></big>\n\n", message);

	switch (type) {
		case TYPE_ADDRESS_BOOK:
			g_string_append_printf (description,
				_("Please enter the password for address book “%s”."), display_name);
			break;
		case TYPE_CALENDAR:
			g_string_append_printf (description,
				_("Please enter the password for calendar “%s”."), display_name);
			break;
		case TYPE_MAIL_ACCOUNT:
			g_string_append_printf (description,
				_("Please enter the password for mail account “%s”."), display_name);
			break;
		case TYPE_MAIL_TRANSPORT:
			g_string_append_printf (description,
				_("Please enter the password for mail transport “%s”."), display_name);
			break;
		case TYPE_MEMO_LIST:
			g_string_append_printf (description,
				_("Please enter the password for memo list “%s”."), display_name);
			break;
		case TYPE_TASK_LIST:
			g_string_append_printf (description,
				_("Please enter the password for task list “%s”."), display_name);
			break;
		default:  /* generic account prompt */
			g_string_append_printf (description,
				_("Please enter the password for account “%s”."), display_name);
			break;
	}

	if (host_name != NULL)
		g_string_append_printf (
			description, "\n(host: %s)", host_name);

	*prompt_title = g_strdup (message);
	*prompt_description = description;

	g_free (display_name);
	g_free (host_name);
}

static gboolean
e_credentials_prompter_impl_password_show_dialog (ECredentialsPrompterImplPassword *prompter_password)
{
	GtkWidget *dialog, *content_area, *widget;
	GtkGrid *grid;
	GtkEntry *username_entry = NULL;
	GtkEntry *password_entry;
	GtkToggleButton *remember_toggle = NULL;
	GtkWindow *dialog_parent;
	ECredentialsPrompter *prompter;
	gchar *title;
	GString *info_markup;
	gint row = 0;
	ESourceAuthentication *auth_extension = NULL;
	gboolean success, is_scratch_source = TRUE;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_PASSWORD (prompter_password), FALSE);
	g_return_val_if_fail (prompter_password->priv->prompt_id != NULL, FALSE);
	g_return_val_if_fail (prompter_password->priv->dialog == NULL, FALSE);

	prompter = e_credentials_prompter_impl_get_credentials_prompter (E_CREDENTIALS_PROMPTER_IMPL (prompter_password));
	g_return_val_if_fail (prompter != NULL, FALSE);

	dialog_parent = e_credentials_prompter_get_dialog_parent (prompter);

	credentials_prompter_impl_password_get_prompt_strings (
		e_credentials_prompter_get_registry (prompter),
		prompter_password->priv->auth_source, &title, &info_markup);
	if (prompter_password->priv->error_text && *prompter_password->priv->error_text) {
		gchar *escaped = g_markup_printf_escaped ("%s", prompter_password->priv->error_text);

		g_string_append_printf (info_markup, "\n\n%s", escaped);
		g_free (escaped);
	}

	dialog = gtk_dialog_new_with_buttons (title, dialog_parent, GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
		_("_Cancel"), GTK_RESPONSE_CANCEL,
		_("_OK"), GTK_RESPONSE_OK,
		NULL);

	prompter_password->priv->dialog = GTK_DIALOG (dialog);
	gtk_dialog_set_default_response (prompter_password->priv->dialog, GTK_RESPONSE_OK);
	gtk_window_set_resizable (GTK_WINDOW (dialog), FALSE);
	if (dialog_parent)
		gtk_window_set_transient_for (GTK_WINDOW (dialog), dialog_parent);
	gtk_window_set_position (GTK_WINDOW (dialog), GTK_WIN_POS_CENTER_ON_PARENT);
	gtk_container_set_border_width (GTK_CONTAINER (dialog), 12);

	content_area = gtk_dialog_get_content_area (prompter_password->priv->dialog);

	/* Override GtkDialog defaults */
	gtk_box_set_spacing (GTK_BOX (content_area), 12);
	gtk_container_set_border_width (GTK_CONTAINER (content_area), 0);

	grid = GTK_GRID (gtk_grid_new ());
	gtk_grid_set_column_spacing (grid, 12);
	gtk_grid_set_row_spacing (grid, 6);

	gtk_box_pack_start (GTK_BOX (content_area), GTK_WIDGET (grid), FALSE, TRUE, 0);

	/* Password Image */
	widget = gtk_image_new_from_icon_name ("dialog-password", GTK_ICON_SIZE_DIALOG);
	g_object_set (
		G_OBJECT (widget),
		"halign", GTK_ALIGN_START,
		"vexpand", TRUE,
		"valign", GTK_ALIGN_START,
		NULL);

	gtk_grid_attach (grid, widget, 0, row, 1, 1);

	/* Password Label */
	widget = gtk_label_new (NULL);
	gtk_label_set_line_wrap (GTK_LABEL (widget), TRUE);
	gtk_label_set_markup (GTK_LABEL (widget), info_markup->str);
	g_object_set (
		G_OBJECT (widget),
		"hexpand", TRUE,
		"halign", GTK_ALIGN_FILL,
		"valign", GTK_ALIGN_CENTER,
		"width-chars", 60,
		"max-width-chars", 80,
		"xalign", 0.0,
		NULL);

	gtk_grid_attach (grid, widget, 1, row, 1, 1);
	row++;

	if (e_source_has_extension (prompter_password->priv->cred_source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
		GDBusObject *dbus_object;

		dbus_object = e_source_ref_dbus_object (prompter_password->priv->cred_source);
		is_scratch_source = !dbus_object;
		g_clear_object (&dbus_object);

		auth_extension = e_source_get_extension (prompter_password->priv->cred_source, E_SOURCE_EXTENSION_AUTHENTICATION);

		if (is_scratch_source || e_source_get_writable (prompter_password->priv->cred_source)) {
			gchar *username;

			username = e_source_authentication_dup_user (auth_extension);
			if ((!username || !*username) &&
			    e_source_has_extension (prompter_password->priv->cred_source, E_SOURCE_EXTENSION_COLLECTION)) {
				ESourceCollection *collection_extension;
				gchar *tmp;

				collection_extension = e_source_get_extension (prompter_password->priv->cred_source, E_SOURCE_EXTENSION_COLLECTION);

				tmp = e_source_collection_dup_identity (collection_extension);
				if (tmp && *tmp) {
					g_free (username);
					username = tmp;
					tmp = NULL;
				}

				g_free (tmp);
			}

			username_entry = GTK_ENTRY (gtk_entry_new ());
			g_object_set (
				G_OBJECT (username_entry),
				"hexpand", TRUE,
				"halign", GTK_ALIGN_FILL,
				NULL);

			gtk_grid_attach (grid, GTK_WIDGET (username_entry), 1, row, 1, 1);
			row++;

			if (username && *username) {
				gtk_entry_set_text (username_entry, username);
			}

			g_free (username);
		}
	}

	password_entry = GTK_ENTRY (gtk_entry_new ());
	gtk_entry_set_visibility (password_entry, FALSE);
	gtk_entry_set_activates_default (password_entry, TRUE);
	g_object_set (
		G_OBJECT (password_entry),
		"hexpand", TRUE,
		"halign", GTK_ALIGN_FILL,
		NULL);
	if (e_named_parameters_get (prompter_password->priv->credentials, E_SOURCE_CREDENTIAL_PASSWORD))
		gtk_entry_set_text (password_entry, e_named_parameters_get (prompter_password->priv->credentials, E_SOURCE_CREDENTIAL_PASSWORD));

	g_signal_connect (dialog, "map-event", G_CALLBACK (password_dialog_map_event_cb),
		(username_entry && g_strcmp0 (gtk_entry_get_text (GTK_ENTRY (username_entry)), "") == 0) ? username_entry : password_entry);

	gtk_grid_attach (grid, GTK_WIDGET (password_entry), 1, row, 1, 1);
	row++;

	if (username_entry && password_entry) {
		widget = gtk_label_new_with_mnemonic (_("_User Name:"));
		g_object_set (
			G_OBJECT (widget),
			"hexpand", FALSE,
			"vexpand", FALSE,
			"halign", GTK_ALIGN_END,
			"valign", GTK_ALIGN_CENTER,
			NULL);

		gtk_label_set_mnemonic_widget (GTK_LABEL (widget), GTK_WIDGET (username_entry));
		gtk_grid_attach (grid, widget, 0, row - 2, 1, 1);

		widget = gtk_label_new_with_mnemonic (_("_Password:"));
		g_object_set (
			G_OBJECT (widget),
			"hexpand", FALSE,
			"vexpand", FALSE,
			"halign", GTK_ALIGN_END,
			"valign", GTK_ALIGN_CENTER,
			NULL);

		gtk_label_set_mnemonic_widget (GTK_LABEL (widget), GTK_WIDGET (password_entry));

		gtk_grid_attach (grid, widget, 0, row - 1, 1, 1);
	}

	if (auth_extension && !is_scratch_source) {
		/* Remember password check */
		widget = gtk_check_button_new_with_mnemonic (_("_Add this password to your keyring"));
		remember_toggle = GTK_TOGGLE_BUTTON (widget);
		gtk_toggle_button_set_active (remember_toggle, e_source_authentication_get_remember_password (auth_extension));
		g_object_set (
			G_OBJECT (widget),
			"hexpand", TRUE,
			"halign", GTK_ALIGN_FILL,
			"valign", GTK_ALIGN_FILL,
			"margin-top", 12,
			NULL);

		gtk_grid_attach (grid, widget, 1, row, 1, 1);
	}

	gtk_widget_show_all (GTK_WIDGET (grid));

	success = gtk_dialog_run (prompter_password->priv->dialog) == GTK_RESPONSE_OK;

	if (success) {
		if (username_entry)
			e_named_parameters_set (prompter_password->priv->credentials,
				E_SOURCE_CREDENTIAL_USERNAME, gtk_entry_get_text (username_entry));
		e_named_parameters_set (prompter_password->priv->credentials,
			E_SOURCE_CREDENTIAL_PASSWORD, gtk_entry_get_text (password_entry));

		if (auth_extension && remember_toggle) {
			e_source_authentication_set_remember_password (auth_extension,
				gtk_toggle_button_get_active (remember_toggle));
		}
	}

	gtk_widget_destroy (dialog);
	prompter_password->priv->dialog = NULL;

	g_string_free (info_markup, TRUE);
	g_free (title);

	return success;
}

static void
e_credentials_prompter_impl_password_free_prompt_data (ECredentialsPrompterImplPassword *prompter_password)
{
	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_PASSWORD (prompter_password));

	prompter_password->priv->prompt_id = NULL;

	g_clear_object (&prompter_password->priv->auth_source);
	g_clear_object (&prompter_password->priv->cred_source);

	g_free (prompter_password->priv->error_text);
	prompter_password->priv->error_text = NULL;

	e_named_parameters_free (prompter_password->priv->credentials);
	prompter_password->priv->credentials = NULL;
}

static gboolean
e_credentials_prompter_impl_password_show_dialog_idle_cb (gpointer user_data)
{
	ECredentialsPrompterImplPassword *prompter_password = user_data;

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_return_val_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_PASSWORD (prompter_password), FALSE);

	if (g_source_get_id (g_main_current_source ()) == prompter_password->priv->show_dialog_idle_id) {
		gboolean success;

		prompter_password->priv->show_dialog_idle_id = 0;

		g_warn_if_fail (prompter_password->priv->dialog == NULL);

		success = e_credentials_prompter_impl_password_show_dialog (prompter_password);

		e_credentials_prompter_impl_prompt_finish (
			E_CREDENTIALS_PROMPTER_IMPL (prompter_password),
			prompter_password->priv->prompt_id,
			success ? prompter_password->priv->credentials : NULL);

		e_credentials_prompter_impl_password_free_prompt_data (prompter_password);
	}

	return FALSE;
}

static void
e_credentials_prompter_impl_password_process_prompt (ECredentialsPrompterImpl *prompter_impl,
						     gpointer prompt_id,
						     ESource *auth_source,
						     ESource *cred_source,
						     const gchar *error_text,
						     const ENamedParameters *credentials)
{
	ECredentialsPrompterImplPassword *prompter_password;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_PASSWORD (prompter_impl));

	prompter_password = E_CREDENTIALS_PROMPTER_IMPL_PASSWORD (prompter_impl);
	g_return_if_fail (prompter_password->priv->prompt_id == NULL);
	g_return_if_fail (prompter_password->priv->show_dialog_idle_id == 0);

	prompter_password->priv->prompt_id = prompt_id;
	prompter_password->priv->auth_source = g_object_ref (auth_source);
	prompter_password->priv->cred_source = g_object_ref (cred_source);
	prompter_password->priv->error_text = g_strdup (error_text);
	prompter_password->priv->credentials = e_named_parameters_new_clone (credentials);
	prompter_password->priv->show_dialog_idle_id = g_idle_add (
		e_credentials_prompter_impl_password_show_dialog_idle_cb,
		prompter_password);
}

static void
e_credentials_prompter_impl_password_cancel_prompt (ECredentialsPrompterImpl *prompter_impl,
						    gpointer prompt_id)
{
	ECredentialsPrompterImplPassword *prompter_password;

	g_return_if_fail (E_IS_CREDENTIALS_PROMPTER_IMPL_PASSWORD (prompter_impl));

	prompter_password = E_CREDENTIALS_PROMPTER_IMPL_PASSWORD (prompter_impl);
	g_return_if_fail (prompter_password->priv->prompt_id == prompt_id);

	/* This also closes the dialog. */
	gtk_dialog_response (prompter_password->priv->dialog, GTK_RESPONSE_CANCEL);
}

static void
e_credentials_prompter_impl_password_dispose (GObject *object)
{
	ECredentialsPrompterImplPassword *prompter_password = E_CREDENTIALS_PROMPTER_IMPL_PASSWORD (object);

	if (prompter_password->priv->show_dialog_idle_id) {
		g_source_remove (prompter_password->priv->show_dialog_idle_id);
		prompter_password->priv->show_dialog_idle_id = 0;
	}

	g_warn_if_fail (prompter_password->priv->prompt_id == NULL);
	g_warn_if_fail (prompter_password->priv->dialog == NULL);

	e_credentials_prompter_impl_password_free_prompt_data (prompter_password);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_credentials_prompter_impl_password_parent_class)->dispose (object);
}

static void
e_credentials_prompter_impl_password_class_init (ECredentialsPrompterImplPasswordClass *class)
{
	static const gchar *authentication_methods[] = {
		"",  /* register as the default credentials prompter */
		NULL
	};

	GObjectClass *object_class;
	ECredentialsPrompterImplClass *prompter_impl_class;

	g_type_class_add_private (class, sizeof (ECredentialsPrompterImplPasswordPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = e_credentials_prompter_impl_password_dispose;

	prompter_impl_class = E_CREDENTIALS_PROMPTER_IMPL_CLASS (class);
	prompter_impl_class->authentication_methods = (const gchar * const *) authentication_methods;
	prompter_impl_class->process_prompt = e_credentials_prompter_impl_password_process_prompt;
	prompter_impl_class->cancel_prompt = e_credentials_prompter_impl_password_cancel_prompt;
}

static void
e_credentials_prompter_impl_password_init (ECredentialsPrompterImplPassword *prompter_password)
{
	prompter_password->priv = G_TYPE_INSTANCE_GET_PRIVATE (prompter_password,
		E_TYPE_CREDENTIALS_PROMPTER_IMPL_PASSWORD, ECredentialsPrompterImplPasswordPrivate);
}

/**
 * e_credentials_prompter_impl_password_new:
 *
 * Creates a new instance of an #ECredentialsPrompterImplPassword.
 *
 * Returns: (transfer full): a newly created #ECredentialsPrompterImplPassword,
 *    which should be freed with g_object_unref() when no longer needed.
 *
 * Since: 3.16
 **/
ECredentialsPrompterImpl *
e_credentials_prompter_impl_password_new (void)
{
	return g_object_new (E_TYPE_CREDENTIALS_PROMPTER_IMPL_PASSWORD, NULL);
}
