/*
 * trust-prompt-gtk.c
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

#include <gtk/gtk.h>
#include <glib/gi18n-lib.h>

#include <libebackend/libebackend.h>

#include "trust-prompt.h"

static void
trust_prompt_add_info_line (GtkGrid *grid,
                            const gchar *label_text,
                            const gchar *value_text,
                            gboolean ellipsize,
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
	gtk_misc_set_padding (GTK_MISC (widget), 12, 0);
	gtk_misc_set_alignment (GTK_MISC (widget), 0.0, 0.0);

	gtk_grid_attach (grid, widget, 1, *at_row, 1, 1);

	widget = gtk_label_new (value_text);
	gtk_misc_set_alignment (GTK_MISC (widget), 0.0, 0.0);
	g_object_set (
		G_OBJECT (widget),
		"hexpand", TRUE,
		"halign", GTK_ALIGN_FILL,
		"justify", GTK_JUSTIFY_LEFT,
		"attributes", bold,
		"selectable", TRUE,
		"ellipsize", ellipsize ? PANGO_ELLIPSIZE_END : PANGO_ELLIPSIZE_NONE,
		NULL);

	gtk_grid_attach (grid, widget, 2, *at_row, 1, 1);

	*at_row = (*at_row) + 1;

	pango_attr_list_unref (bold);
}

#define TRUST_PROMP_ID_KEY	"ETrustPrompt::prompt-id-key"

static void
trust_prompt_response_cb (GtkWidget *dialog,
                          gint response,
                          EUserPrompterServerExtension *extension)
{
	gint prompt_id;

	prompt_id = GPOINTER_TO_INT (g_object_get_data (G_OBJECT (dialog), TRUST_PROMP_ID_KEY));
	gtk_widget_destroy (dialog);

	if (response == GTK_RESPONSE_REJECT)
		response = TRUST_PROMPT_RESPONSE_REJECT;
	else if (response == GTK_RESPONSE_ACCEPT)
		response = TRUST_PROMPT_RESPONSE_ACCEPT_PERMANENTLY;
	else if (response == GTK_RESPONSE_YES)
		response = TRUST_PROMPT_RESPONSE_ACCEPT_TEMPORARILY;
	else
		response = TRUST_PROMPT_RESPONSE_UNKNOWN;

	e_user_prompter_server_extension_response (extension, prompt_id, response, NULL);
}

gboolean
trust_prompt_show (EUserPrompterServerExtension *extension,
                   gint prompt_id,
                   const gchar *host,
                   const gchar *markup,
                   GcrParsed *parsed,
                   const gchar *reason)
{
	GcrCertificateWidget *certificate_widget;
	GcrCertificate *certificate;
	GckAttributes *attributes;
	GtkWidget *dialog, *widget;
	GtkGrid *grid;
	const guchar *data;
	gsize length;
	gchar *tmp;
	gint row = 0;

	dialog = gtk_dialog_new_with_buttons (
		_("Certificate trust..."), NULL, 0,
		_("_Reject"), GTK_RESPONSE_REJECT,
		_("Accept _Temporarily"), GTK_RESPONSE_YES,
		_("_Accept Permanently"), GTK_RESPONSE_ACCEPT,
		NULL);

	widget = gtk_dialog_get_content_area (GTK_DIALOG (dialog));

	gtk_window_set_icon_name (GTK_WINDOW (dialog), "evolution");
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

	tmp = NULL;
	if (!markup || !*markup) {
		gchar *bhost;

		bhost = g_strconcat ("<b>", host, "</b>", NULL);
		tmp = g_strdup_printf (_("SSL/TLS certificate for “%s” is not trusted. Do you wish to accept it?"), bhost);
		g_free (bhost);

		markup = tmp;
	}

	widget = gtk_label_new (NULL);
	gtk_label_set_markup (GTK_LABEL (widget), markup);
	gtk_misc_set_alignment (GTK_MISC (widget), 0.0, 0.0);

	g_free (tmp);

	gtk_grid_attach (grid, widget, 1, row, 2, 1);
	row++;

	trust_prompt_add_info_line (grid, _("Reason:"), reason, FALSE, &row);

	data = gcr_parsed_get_data (parsed, &length);
	attributes = gcr_parsed_get_attributes (parsed);

	certificate = gcr_simple_certificate_new (data, length);

	certificate_widget = gcr_certificate_widget_new (certificate);
	gcr_certificate_widget_set_attributes (certificate_widget, attributes);

	widget = GTK_WIDGET (certificate_widget);
	gtk_grid_attach (grid, widget, 1, row, 2, 1);
	gtk_widget_show (widget);

	g_clear_object (&certificate);

	g_object_set_data (G_OBJECT (dialog), TRUST_PROMP_ID_KEY, GINT_TO_POINTER (prompt_id));

	g_signal_connect (dialog, "response", G_CALLBACK (trust_prompt_response_cb), extension);

	gtk_widget_show_all (GTK_WIDGET (grid));
	gtk_widget_show (dialog);

	return TRUE;
}
