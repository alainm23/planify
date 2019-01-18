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

#if !defined (__LIBEDATASERVERUI_H_INSIDE__) && !defined (LIBEDATASERVERUI_COMPILATION)
#error "Only <libedataserverui/libedataserverui.h> should be included directly."
#endif

#ifndef E_WEBDAV_DISCOVER_WIDGET_H
#define E_WEBDAV_DISCOVER_WIDGET_H

#include <gio/gio.h>

#include <gtk/gtk.h>

#include <libedataserver/libedataserver.h>
#include <libedataserverui/e-credentials-prompter.h>

G_BEGIN_DECLS

GtkWidget *	e_webdav_discover_content_new		(ECredentialsPrompter *credentials_prompter,
							 ESource *source,
							 const gchar *base_url,
							 guint supports_filter);
GtkTreeSelection *
		e_webdav_discover_content_get_tree_selection
							(GtkWidget *content);
gboolean	e_webdav_discover_content_get_multiselect
							(GtkWidget *content);
void		e_webdav_discover_content_set_multiselect
							(GtkWidget *content,
							 gboolean multiselect);
const gchar *	e_webdav_discover_content_get_base_url	(GtkWidget *content);
void		e_webdav_discover_content_set_base_url	(GtkWidget *content,
							 const gchar *base_url);
gboolean	e_webdav_discover_content_get_selected	(GtkWidget *content,
							 gint index,
							 gchar **out_href,
							 guint *out_supports,
							 gchar **out_display_name,
							 gchar **out_color);
gchar *		e_webdav_discover_content_get_user_address
							(GtkWidget *content);
void		e_webdav_discover_content_refresh	(GtkWidget *content,
							 const gchar *display_name,
							 GCancellable *cancellable,
							 GAsyncReadyCallback callback,
							 gpointer user_data);
gboolean	e_webdav_discover_content_refresh_finish
							(GtkWidget *content,
							 GAsyncResult *result,
							 GError **error);
void		e_webdav_discover_content_show_error	(GtkWidget *content,
							 const GError *error);

GtkDialog *	e_webdav_discover_dialog_new		(GtkWindow *parent,
							 const gchar *title,
							 ECredentialsPrompter *credentials_prompter,
							 ESource *source,
							 const gchar *base_url,
							 guint supports_filter);

GtkWidget *	e_webdav_discover_dialog_get_content	(GtkDialog *dialog);
void		e_webdav_discover_dialog_refresh	(GtkDialog *dialog);

G_END_DECLS

#endif /* E_WEBDAV_DISCOVER_WIDGET_H */
