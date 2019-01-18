/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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

#ifndef E_OAUTH2_SERVICE_H
#define E_OAUTH2_SERVICE_H

#include <glib.h>
#include <libsoup/soup.h>

#include <libedataserver/e-source.h>

/* Standard GObject macros */
#define E_TYPE_OAUTH2_SERVICE \
	(e_oauth2_service_get_type ())
#define E_OAUTH2_SERVICE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_OAUTH2_SERVICE, EOAuth2Service))
#define E_IS_OAUTH2_SERVICE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_OAUTH2_SERVICE))
#define E_OAUTH2_SERVICE_GET_INTERFACE(obj) \
	(G_TYPE_INSTANCE_GET_INTERFACE \
	((obj), E_TYPE_OAUTH2_SERVICE, EOAuth2ServiceInterface))

/* Secret key names, saved by the code; not the names returned by the OAuth2 server */
#define E_OAUTH2_SECRET_REFRESH_TOKEN "refresh_token"
#define E_OAUTH2_SECRET_ACCESS_TOKEN "access_token"
#define E_OAUTH2_SECRET_EXPIRES_AFTER "expires_after"

G_BEGIN_DECLS

/**
 * EOAuth2ServiceFlags:
 * @E_OAUTH2_SERVICE_FLAG_NONE: No flag set
 * @E_OAUTH2_SERVICE_FLAG_EXTRACT_REQUIRES_PAGE_CONTENT: the service requires also page
 *    content to be passed to e_oauth2_service_extract_authorization_code()
 *
 * Flags of the OAuth2 service.
 *
 * Since: 3.28
 **/
typedef enum {
	E_OAUTH2_SERVICE_FLAG_NONE				= 0,
	E_OAUTH2_SERVICE_FLAG_EXTRACT_REQUIRES_PAGE_CONTENT	= (1 << 1)
} EOAuth2ServiceFlags;

/**
 * EOAuth2ServiceNavigationPolicy:
 * @E_OAUTH2_SERVICE_NAVIGATION_POLICY_DENY: Deny navigation to the given web resource
 * @E_OAUTH2_SERVICE_NAVIGATION_POLICY_ALLOW: Allow navigation to the given web resource
 * @E_OAUTH2_SERVICE_NAVIGATION_POLICY_ABORT: Abort authentication processing
 *
 * A value used during querying authentication URI, to decide whether certain
 * resource can be used or not. The @E_OAUTH2_SERVICE_NAVIGATION_POLICY_ABORT
 * can be used to abort the authentication query, like when user cancelled it.
 *
 * Since: 3.28
 **/
typedef enum {
	E_OAUTH2_SERVICE_NAVIGATION_POLICY_DENY,
	E_OAUTH2_SERVICE_NAVIGATION_POLICY_ALLOW,
	E_OAUTH2_SERVICE_NAVIGATION_POLICY_ABORT
} EOAuth2ServiceNavigationPolicy;

/**
 * EOAuth2ServiceRefSourceFunc:
 * @user_data: user data, as passed to e_oauth2_service_get_access_token_sync()
 *    or e_oauth2_service_receive_and_store_token_sync(),
 *    or e_oauth2_service_refresh_and_store_token_sync()
 * @uid: an #ESource UID to return
 *
 * Returns: (transfer full) (nullable): an #ESource with UID @uid, or %NULL, if not found.
 *    Dereference the returned non-NULL #ESource with g_object_unref(), when no longer needed.
 *
 * Since: 3.28
 **/
typedef ESource * (* EOAuth2ServiceRefSourceFunc)	(gpointer user_data,
							 const gchar *uid);

typedef struct _EOAuth2Service EOAuth2Service;
typedef struct _EOAuth2ServiceInterface EOAuth2ServiceInterface;

/**
 * EOAuth2Service:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.28
 **/
struct _EOAuth2ServiceInterface {
	GTypeInterface parent_interface;

	gboolean	(* can_process)			(EOAuth2Service *service,
							 ESource *source);
	gboolean	(* guess_can_process)		(EOAuth2Service *service,
							 const gchar *protocol,
							 const gchar *hostname);
	guint32		(* get_flags)			(EOAuth2Service *service);
	const gchar *	(* get_name)			(EOAuth2Service *service);
	const gchar *	(* get_display_name)		(EOAuth2Service *service);
	const gchar *	(* get_client_id)		(EOAuth2Service *service,
							 ESource *source);
	const gchar *	(* get_client_secret)		(EOAuth2Service *service,
							 ESource *source);
	const gchar *	(* get_authentication_uri)	(EOAuth2Service *service,
							 ESource *source);
	const gchar *	(* get_refresh_uri)		(EOAuth2Service *service,
							 ESource *source);
	const gchar *	(* get_redirect_uri)		(EOAuth2Service *service,
							 ESource *source);
	void		(* prepare_authentication_uri_query)
							(EOAuth2Service *service,
							 ESource *source,
							 GHashTable *uri_query);
	EOAuth2ServiceNavigationPolicy
			(* get_authentication_policy)	(EOAuth2Service *service,
							 ESource *source,
							 const gchar *uri);
	gboolean	(* extract_authorization_code)	(EOAuth2Service *service,
							 ESource *source,
							 const gchar *page_title,
							 const gchar *page_uri,
							 const gchar *page_content,
							 gchar **out_authorization_code);
	void		(* prepare_get_token_form)	(EOAuth2Service *service,
							 ESource *source,
							 const gchar *authorization_code,
							 GHashTable *form);
	void		(* prepare_get_token_message)	(EOAuth2Service *service,
							 ESource *source,
							 SoupMessage *message);
	void		(* prepare_refresh_token_form)	(EOAuth2Service *service,
							 ESource *source,
							 const gchar *refresh_token,
							 GHashTable *form);
	void		(* prepare_refresh_token_message)
							(EOAuth2Service *service,
							 ESource *source,
							 SoupMessage *message);

	/* Padding for future expansion */
	gpointer reserved[10];
};

GType		e_oauth2_service_get_type		(void) G_GNUC_CONST;
gboolean	e_oauth2_service_can_process		(EOAuth2Service *service,
							 ESource *source);
gboolean	e_oauth2_service_guess_can_process	(EOAuth2Service *service,
							 const gchar *protocol,
							 const gchar *hostname);
guint32		e_oauth2_service_get_flags		(EOAuth2Service *service);
const gchar *	e_oauth2_service_get_name		(EOAuth2Service *service);
const gchar *	e_oauth2_service_get_display_name	(EOAuth2Service *service);
const gchar *	e_oauth2_service_get_client_id		(EOAuth2Service *service,
							 ESource *source);
const gchar *	e_oauth2_service_get_client_secret	(EOAuth2Service *service,
							 ESource *source);
const gchar *	e_oauth2_service_get_authentication_uri	(EOAuth2Service *service,
							 ESource *source);
const gchar *	e_oauth2_service_get_refresh_uri	(EOAuth2Service *service,
							 ESource *source);
const gchar *	e_oauth2_service_get_redirect_uri	(EOAuth2Service *service,
							 ESource *source);
void		e_oauth2_service_prepare_authentication_uri_query
							(EOAuth2Service *service,
							 ESource *source,
							 GHashTable *uri_query);
EOAuth2ServiceNavigationPolicy
		e_oauth2_service_get_authentication_policy
							(EOAuth2Service *service,
							 ESource *source,
							 const gchar *uri);
gboolean	e_oauth2_service_extract_authorization_code
							(EOAuth2Service *service,
							 ESource *source,
							 const gchar *page_title,
							 const gchar *page_uri,
							 const gchar *page_content,
							 gchar **out_authorization_code);
void		e_oauth2_service_prepare_get_token_form	(EOAuth2Service *service,
							 ESource *source,
							 const gchar *authorization_code,
							 GHashTable *form);
void		e_oauth2_service_prepare_get_token_message
							(EOAuth2Service *service,
							 ESource *source,
							 SoupMessage *message);
void		e_oauth2_service_prepare_refresh_token_form
							(EOAuth2Service *service,
							 ESource *source,
							 const gchar *refresh_token,
							 GHashTable *form);
void		e_oauth2_service_prepare_refresh_token_message
							(EOAuth2Service *service,
							 ESource *source,
							 SoupMessage *message);

gboolean	e_oauth2_service_receive_and_store_token_sync
							(EOAuth2Service *service,
							 ESource *source,
							 const gchar *authorization_code,
							 EOAuth2ServiceRefSourceFunc ref_source,
							 gpointer ref_source_user_data,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_oauth2_service_refresh_and_store_token_sync
							(EOAuth2Service *service,
							 ESource *source,
							 const gchar *refresh_token,
							 EOAuth2ServiceRefSourceFunc ref_source,
							 gpointer ref_source_user_data,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_oauth2_service_delete_token_sync	(EOAuth2Service *service,
							 ESource *source,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_oauth2_service_get_access_token_sync	(EOAuth2Service *service,
							 ESource *source,
							 EOAuth2ServiceRefSourceFunc ref_source,
							 gpointer ref_source_user_data,
							 gchar **out_access_token,
							 gint *out_expires_in,
							 GCancellable *cancellable,
							 GError **error);

void		e_oauth2_service_util_set_to_form	(GHashTable *form,
							 const gchar *name,
							 const gchar *value);
void		e_oauth2_service_util_take_to_form	(GHashTable *form,
							 const gchar *name,
							 gchar *value);

G_END_DECLS

#endif /* E_OAUTH2_SERVICE_H */
