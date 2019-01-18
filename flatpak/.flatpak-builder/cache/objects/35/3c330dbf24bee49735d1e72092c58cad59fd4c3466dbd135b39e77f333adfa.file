/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* e-url.h
 *
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
 * Authors: Jon Trowbridge <trow@ximian.com>
 *          Rodrigo Moya <rodrigo@ximian.com>
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef EDS_DISABLE_DEPRECATED

/* Do not generate bindings. */
#ifndef __GI_SCANNER__

#ifndef E_URL_H
#define E_URL_H

#include <glib.h>

G_BEGIN_DECLS

typedef struct _EUri EUri;

/**
 * EUri:
 * @protocol: The protocol to use.
 * @user: A user name.
 * @authmech: The authentication mechanism.
 * @passwd: The connection password.
 * @host: The host name.
 * @port: The port number.
 * @path: The file path on the host.
 * @params: Additional parameters.
 * @query: The URI query.
 * @fragment: The URI fragment.
 *
 * A structure representing a URI.
 **/
struct _EUri {
	gchar *protocol;
	gchar *user;
	gchar *authmech;
	gchar *passwd;
	gchar *host;
	gint port;
	gchar *path;
	GData *params;
	gchar *query;
	gchar *fragment;
};

EUri *		e_uri_new			(const gchar *uri_string);
void		e_uri_free			(EUri *uri);
const gchar *	e_uri_get_param			(EUri *uri,
						 const gchar *name);
EUri *		e_uri_copy			(EUri *uri);
gchar *		e_uri_to_string			(EUri *uri,
						 gboolean show_password);
gchar *		e_url_shroud			(const gchar *url);
gboolean	e_url_equal			(const gchar *url1,
						 const gchar *url2);

G_END_DECLS

#endif /* E_URL_H */

#endif /* __GI_SCANNER__ */

#endif /* EDS_DISABLE_DEPRECATED */

