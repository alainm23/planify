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

#ifndef E_TRUST_PROMPT_H
#define E_TRUST_PROMPT_H

#include <glib.h>
#include <gio/gio.h>

#include <gtk/gtk.h>

#include <libedataserver/libedataserver.h>

G_BEGIN_DECLS

gchar *		e_trust_prompt_describe_certificate_errors
					(GTlsCertificateFlags flags);
ETrustPromptResponse
		e_trust_prompt_run_modal(GtkWindow *parent,
					 const gchar *source_extension,
					 const gchar *source_display_name,
					 const gchar *host,
					 const gchar *certificate_pem,
					 GTlsCertificateFlags certificate_errors,
					 const gchar *error_text);

void		e_trust_prompt_run_for_source
					(GtkWindow *parent,
					 ESource *source,
					 const gchar *certificate_pem,
					 GTlsCertificateFlags certificate_errors,
					 const gchar *error_text,
					 gboolean allow_source_save,
					 GCancellable *cancellable,
					 GAsyncReadyCallback callback,
					 gpointer user_data);
gboolean	e_trust_prompt_run_for_source_finish
					(ESource *source,
					 GAsyncResult *result,
					 ETrustPromptResponse *response,
					 GError **error);

G_END_DECLS

#endif /* E_TRUST_PROMPT_H */
