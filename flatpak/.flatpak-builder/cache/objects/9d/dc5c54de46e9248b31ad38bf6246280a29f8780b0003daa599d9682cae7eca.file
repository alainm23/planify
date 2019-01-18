/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-session.h : Abstract class for an email session
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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_SESSION_H
#define CAMEL_SESSION_H

#include <camel/camel-enums.h>
#include <camel/camel-filter-driver.h>
#include <camel/camel-junk-filter.h>
#include <camel/camel-msgport.h>
#include <camel/camel-provider.h>
#include <camel/camel-service.h>
#include <camel/camel-certdb.h>

/* Standard GObject macros */
#define CAMEL_TYPE_SESSION \
	(camel_session_get_type ())
#define CAMEL_SESSION(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SESSION, CamelSession))
#define CAMEL_SESSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SESSION, CamelSessionClass))
#define CAMEL_IS_SESSION(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SESSION))
#define CAMEL_IS_SESSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SESSION))
#define CAMEL_SESSION_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_SESSION, CamelSessionClass))

G_BEGIN_DECLS

typedef struct _CamelSession CamelSession;
typedef struct _CamelSessionClass CamelSessionClass;
typedef struct _CamelSessionPrivate CamelSessionPrivate;

enum {
	CAMEL_SESSION_PASSWORD_REPROMPT = 1 << 0,
	CAMEL_SESSION_PASSWORD_SECRET = 1 << 2,
	CAMEL_SESSION_PASSWORD_STATIC = 1 << 3,
	CAMEL_SESSION_PASSPHRASE = 1 << 4
};

struct _CamelSession {
	GObject parent;
	CamelSessionPrivate *priv;
};

/**
 * CamelSessionCallback:
 * @session: a #CamelSession
 * @cancellable: a #CamelOperation cast as a #GCancellable
 * @user_data: data passed to camel_session_submit_job()
 * @error: return location for a #GError
 *
 * This is the callback signature for jobs submitted to the CamelSession
 * via camel_session_submit_job().  The @error pointer is always non-%NULL,
 * so it's safe to dereference to check if a #GError has been set.
 *
 * Since: 3.2
 **/
typedef void	(*CamelSessionCallback)		(CamelSession *session,
						 GCancellable *cancellable,
						 gpointer user_data,
						 GError **error);

struct _CamelSessionClass {
	GObjectClass parent_class;

	CamelService *	(*add_service)		(CamelSession *session,
						 const gchar *uid,
						 const gchar *protocol,
						 CamelProviderType type,
						 GError **error);
	void		(*remove_service)	(CamelSession *session,
						 CamelService *service);
	gchar *		(*get_password)		(CamelSession *session,
						 CamelService *service,
						 const gchar *prompt,
						 const gchar *item,
						 guint32 flags,
						 GError **error);
	gboolean	(*forget_password)	(CamelSession *session,
						 CamelService *service,
						 const gchar *item,
						 GError **error);
	CamelCertTrust	(*trust_prompt)		(CamelSession *session,
						 CamelService *service,
						 GTlsCertificate *certificate,
						 GTlsCertificateFlags errors);
	CamelFilterDriver *
			(*get_filter_driver)	(CamelSession *session,
						 const gchar *type,
						 CamelFolder *for_folder,
						 GError **error);
	gboolean	(*lookup_addressbook)	(CamelSession *session,
						 const gchar *name);

	/* Synchronous I/O Methods */
	gboolean	(*authenticate_sync)	(CamelSession *session,
						 CamelService *service,
						 const gchar *mechanism,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*forward_to_sync)	(CamelSession *session,
						 CamelFolder *folder,
						 CamelMimeMessage *message,
						 const gchar *address,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*get_oauth2_access_token_sync)
						(CamelSession *session,
						 CamelService *service,
						 gchar **out_access_token,
						 gint *out_expires_in,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*get_recipient_certificates_sync)
						(CamelSession *session,
						 guint32 flags, /* bit-or of CamelRecipientCertificateFlags */
						 const GPtrArray *recipients, /* gchar * */
						 GSList **out_certificates, /* gchar * */
						 GCancellable *cancellable,
						 GError **error);

	/* Padding for future expansion */
	gpointer reserved_methods[19];

	/* Signals */
	void		(*job_started)		(CamelSession *session,
						 GCancellable *cancellable);
	void		(*job_finished)		(CamelSession *session,
						 GCancellable *cancellable,
						 const GError *error);
	void		(*user_alert)		(CamelSession *session,
						 CamelService *service,
						 CamelSessionAlertType type,
						 const gchar *message);

	/* Padding for future expansion */
	gpointer reserved_signals[20];
};

GType		camel_session_get_type		(void);
GMainContext *	camel_session_ref_main_context	(CamelSession *session);
const gchar *	camel_session_get_user_data_dir	(CamelSession *session);
const gchar *	camel_session_get_user_cache_dir
						(CamelSession *session);
void		camel_session_set_network_monitor
						(CamelSession *session,
						 GNetworkMonitor *network_monitor);
GNetworkMonitor *
		camel_session_ref_network_monitor
						(CamelSession *session);
CamelService *	camel_session_add_service	(CamelSession *session,
						 const gchar *uid,
						 const gchar *protocol,
						 CamelProviderType type,
						 GError **error);
void		camel_session_remove_service	(CamelSession *session,
						 CamelService *service);
CamelService *	camel_session_ref_service	(CamelSession *session,
						 const gchar *uid);
CamelService *	camel_session_ref_service_by_url
						(CamelSession *session,
						 CamelURL *url,
						 CamelProviderType type);
GList *		camel_session_list_services	(CamelSession *session);
void		camel_session_remove_services	(CamelSession *session);
gchar *		camel_session_get_password	(CamelSession *session,
						 CamelService *service,
						 const gchar *prompt,
						 const gchar *item,
						 guint32 flags,
						 GError **error);
gboolean	camel_session_forget_password	(CamelSession *session,
						 CamelService *service,
						 const gchar *item,
						 GError **error);
CamelCertTrust	camel_session_trust_prompt	(CamelSession *session,
						 CamelService *service,
						 GTlsCertificate *certificate,
						 GTlsCertificateFlags errors);
void		camel_session_user_alert	(CamelSession *session,
						 CamelService *service,
						 CamelSessionAlertType type,
						 const gchar *message);
gboolean	camel_session_get_online	(CamelSession *session);
void		camel_session_set_online	(CamelSession *session,
						 gboolean online);
CamelFilterDriver *
		camel_session_get_filter_driver	(CamelSession *session,
						 const gchar *type,
						 CamelFolder *for_folder,
						 GError **error);
CamelJunkFilter *
		camel_session_get_junk_filter	(CamelSession *session);
void		camel_session_set_junk_filter	(CamelSession *session,
						 CamelJunkFilter *junk_filter);
guint		camel_session_idle_add		(CamelSession *session,
						 gint priority,
						 GSourceFunc function,
						 gpointer data,
						 GDestroyNotify notify);
void		camel_session_submit_job	(CamelSession *session,
						 const gchar *description,
						 CamelSessionCallback callback,
						 gpointer user_data,
						 GDestroyNotify notify);
const GHashTable *
		camel_session_get_junk_headers	(CamelSession *session);
void		camel_session_set_junk_headers	(CamelSession *session,
						 const gchar **headers,
						 const gchar **values,
						 gint len);
gboolean	camel_session_lookup_addressbook (CamelSession *session,
						 const gchar *name);

gboolean	camel_session_authenticate_sync	(CamelSession *session,
						 CamelService *service,
						 const gchar *mechanism,
						 GCancellable *cancellable,
						 GError **error);
void		camel_session_authenticate	(CamelSession *session,
						 CamelService *service,
						 const gchar *mechanism,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_session_authenticate_finish
						(CamelSession *session,
						 GAsyncResult *result,
						 GError **error);
gboolean	camel_session_forward_to_sync	(CamelSession *session,
						 CamelFolder *folder,
						 CamelMimeMessage *message,
						 const gchar *address,
						 GCancellable *cancellable,
						 GError **error);
void		camel_session_forward_to	(CamelSession *session,
						 CamelFolder *folder,
						 CamelMimeMessage *message,
						 const gchar *address,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_session_forward_to_finish	(CamelSession *session,
						 GAsyncResult *result,
						 GError **error);
gboolean	camel_session_get_oauth2_access_token_sync
						(CamelSession *session,
						 CamelService *service,
						 gchar **out_access_token,
						 gint *out_expires_in,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_session_get_recipient_certificates_sync
						(CamelSession *session,
						 guint32 flags, /* bit-or of CamelRecipientCertificateFlags */
						 const GPtrArray *recipients, /* gchar * */
						 GSList **out_certificates, /* gchar * */
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_SESSION_H */
