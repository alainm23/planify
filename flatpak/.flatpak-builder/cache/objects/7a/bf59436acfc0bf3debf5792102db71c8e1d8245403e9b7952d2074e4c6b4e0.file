/*
 * prompt-user-gtk.c
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

#include <glib/gi18n.h>
#include <gtk/gtk.h>

#include <libebackend/libebackend.h>

#include "prompt-user.h"

#define E_USER_PROMPTER_ID_KEY "e-user-prompter-id"

void
prompt_user_init (gint *argc,
                  gchar ***argv)
{
	gtk_init (argc, argv);
}

static void
message_response_cb (GtkWidget *dialog,
                     gint button,
                     EUserPrompterServer *server)
{
	gint prompt_id;

	prompt_id = GPOINTER_TO_INT (g_object_get_data (
		G_OBJECT (dialog), E_USER_PROMPTER_ID_KEY));

	gtk_widget_destroy (dialog);

	g_return_if_fail (E_IS_USER_PROMPTER_SERVER (server));

	e_user_prompter_server_response (server, prompt_id, button, NULL);
}

void
prompt_user_show (EUserPrompterServer *server,
                  gint id,
                  const gchar *type,
                  const gchar *title,
                  const gchar *primary_text,
                  const gchar *secondary_text,
                  gboolean use_markup,
                  const GSList *button_captions)
{
	GtkMessageType ntype = GTK_MESSAGE_OTHER;
	GtkWidget *message;
	gint index = 0;
	const GSList *iter;

	g_return_if_fail (E_IS_USER_PROMPTER_SERVER (server));

	if (primary_text == NULL)
		primary_text = "";

	if (type) {
		if (g_ascii_strcasecmp (type, "info") == 0)
			ntype = GTK_MESSAGE_INFO;
		else if (g_ascii_strcasecmp (type, "warning") == 0)
			ntype = GTK_MESSAGE_WARNING;
		else if (g_ascii_strcasecmp (type, "question") == 0)
			ntype = GTK_MESSAGE_QUESTION;
		else if (g_ascii_strcasecmp (type, "error") == 0)
			ntype = GTK_MESSAGE_ERROR;
	}

	if (use_markup) {
		message = gtk_message_dialog_new_with_markup (
			NULL, 0, ntype, GTK_BUTTONS_NONE, "%s", "");
		gtk_message_dialog_set_markup (
			GTK_MESSAGE_DIALOG (message), primary_text);
	} else {
		message = gtk_message_dialog_new (
			NULL, 0, ntype, GTK_BUTTONS_NONE, "%s", primary_text);
	}

	/* To show dialog on a taskbar */
	gtk_window_set_skip_taskbar_hint (GTK_WINDOW (message), FALSE);
	gtk_window_set_title (GTK_WINDOW (message), title ? title : "");
	gtk_window_set_icon_name (GTK_WINDOW (message), "evolution");

	if (secondary_text && *secondary_text) {
		if (use_markup)
			gtk_message_dialog_format_secondary_markup (
				GTK_MESSAGE_DIALOG (message),
				"%s", secondary_text);
		else
			gtk_message_dialog_format_secondary_text (
				GTK_MESSAGE_DIALOG (message),
				"%s", secondary_text);
	}

	g_object_set (message, "resizable", TRUE, NULL);

	for (iter = button_captions; iter != NULL; iter = iter->next) {
		gtk_dialog_add_button (
			GTK_DIALOG (message), iter->data, index++);
	}

	if (index == 0)
		gtk_dialog_add_button (
			GTK_DIALOG (message), _("_Dismiss"), index);

	g_object_set_data (
		G_OBJECT (message),
		E_USER_PROMPTER_ID_KEY,
		GINT_TO_POINTER (id));

	g_signal_connect (
		message, "response",
		G_CALLBACK (message_response_cb), server);

	gtk_widget_show (message);
}
