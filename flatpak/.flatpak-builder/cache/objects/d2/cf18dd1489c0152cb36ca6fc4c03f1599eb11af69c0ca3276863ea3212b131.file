/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
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
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOUP_SESSION_H
#define E_SOUP_SESSION_H

#include <glib.h>
#include <libsoup/soup.h>

#include <libedataserver/e-data-server-util.h>
#include <libedataserver/e-source.h>

/* Standard GObject macros */
#define E_TYPE_SOUP_SESSION \
	(e_soup_session_get_type ())
#define E_SOUP_SESSION(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOUP_SESSION, ESoupSession))
#define E_SOUP_SESSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOUP_SESSION, ESoupSessionClass))
#define E_IS_SOUP_SESSION(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOUP_SESSION))
#define E_IS_SOUP_SESSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOUP_SESSION))
#define E_SOUP_SESSION_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOUP_SESSION, ESoupSessionClass))

G_BEGIN_DECLS

typedef struct _ESoupSession ESoupSession;
typedef struct _ESoupSessionClass ESoupSessionClass;
typedef struct _ESoupSessionPrivate ESoupSessionPrivate;

/**
 * ESoupSession:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.26
 **/
struct _ESoupSession {
	/*< private >*/
	SoupSession parent;
	ESoupSessionPrivate *priv;
};

struct _ESoupSessionClass {
	SoupSessionClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[10];
};

GType		e_soup_session_get_type			(void) G_GNUC_CONST;

ESoupSession *	e_soup_session_new			(ESource *source);
void		e_soup_session_setup_logging		(ESoupSession *session,
							 const gchar *logging_level);
SoupLoggerLogLevel
		e_soup_session_get_log_level		(ESoupSession *session);
ESource *	e_soup_session_get_source		(ESoupSession *session);
void		e_soup_session_set_credentials		(ESoupSession *session,
							 const ENamedParameters *credentials);
ENamedParameters *
		e_soup_session_dup_credentials		(ESoupSession *session);
gboolean	e_soup_session_get_authentication_requires_credentials
							(ESoupSession *session);
gboolean	e_soup_session_get_ssl_error_details	(ESoupSession *session,
							 gchar **out_certificate_pem,
							 GTlsCertificateFlags *out_certificate_errors);
SoupRequestHTTP *
		e_soup_session_new_request		(ESoupSession *session,
							 const gchar *method,
							 const gchar *uri_string,
							 GError **error);
SoupRequestHTTP *
		e_soup_session_new_request_uri		(ESoupSession *session,
							 const gchar *method,
							 SoupURI *uri,
							 GError **error);
gboolean	e_soup_session_check_result		(ESoupSession *session,
							 SoupRequestHTTP *request,
							 gconstpointer read_bytes,
							 gsize bytes_length,
							 GError **error);
GInputStream *	e_soup_session_send_request_sync	(ESoupSession *session,
							 SoupRequestHTTP *request,
							 GCancellable *cancellable,
							 GError **error);
GByteArray *	e_soup_session_send_request_simple_sync	(ESoupSession *session,
							 SoupRequestHTTP *request,
							 GCancellable *cancellable,
							 GError **error);
const gchar *	e_soup_session_util_status_to_string	(guint status_code,
							 const gchar *reason_phrase);

G_END_DECLS

#endif /* E_SOUP_SESSION_H */
