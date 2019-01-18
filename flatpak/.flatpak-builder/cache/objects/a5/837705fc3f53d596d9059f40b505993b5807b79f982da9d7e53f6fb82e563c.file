/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-service.h : Abstract class for an email service
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
 *          Michael Zucchi <notzed@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_SERVICE_H
#define CAMEL_SERVICE_H

#include <camel/camel-enums.h>
#include <camel/camel-object.h>
#include <camel/camel-url.h>
#include <camel/camel-provider.h>
#include <camel/camel-operation.h>
#include <camel/camel-settings.h>

/* Standard GObject macros */
#define CAMEL_TYPE_SERVICE \
	(camel_service_get_type ())
#define CAMEL_SERVICE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SERVICE, CamelService))
#define CAMEL_SERVICE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SERVICE, CamelServiceClass))
#define CAMEL_IS_SERVICE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SERVICE))
#define CAMEL_IS_SERVICE_CLASS(obj) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SERVICE))
#define CAMEL_SERVICE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_SERVICE, CamelServiceClass))
#define CAMEL_TYPE_SERVICE_AUTH_TYPE \
	(camel_service_auth_type_get_type ())

/**
 * CAMEL_SERVICE_ERROR:
 *
 * Since: 2.32
 **/
#define CAMEL_SERVICE_ERROR \
	(camel_service_error_quark ())

G_BEGIN_DECLS

struct _CamelSession;

typedef struct _CamelService CamelService;
typedef struct _CamelServiceClass CamelServiceClass;
typedef struct _CamelServicePrivate CamelServicePrivate;

/**
 * CamelServiceError:
 * @CAMEL_SERVICE_ERROR_INVALID: a generic service error code
 * @CAMEL_SERVICE_ERROR_URL_INVALID: the URL for the service is invalid
 * @CAMEL_SERVICE_ERROR_UNAVAILABLE: the service is unavailable
 * @CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE: failed to authenitcate
 * @CAMEL_SERVICE_ERROR_NOT_CONNECTED: the service is not connected
 *
 * Since: 2.32
 **/
typedef enum {
	CAMEL_SERVICE_ERROR_INVALID,
	CAMEL_SERVICE_ERROR_URL_INVALID,
	CAMEL_SERVICE_ERROR_UNAVAILABLE,
	CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
	CAMEL_SERVICE_ERROR_NOT_CONNECTED
} CamelServiceError;

struct _CamelService {
	CamelObject parent;
	CamelServicePrivate *priv;
};

struct _CamelServiceClass {
	CamelObjectClass parent_class;

	GType settings_type;

	/* Non-Blocking Methods */
	gchar *		(*get_name)		(CamelService *service,
						 gboolean brief);

	/* Synchronous I/O Methods */
	gboolean	(*connect_sync)		(CamelService *service,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*disconnect_sync)	(CamelService *service,
						 gboolean clean,
						 GCancellable *cancellable,
						 GError **error);
	CamelAuthenticationResult
			(*authenticate_sync)	(CamelService *service,
						 const gchar *mechanism,
						 GCancellable *cancellable,
						 GError **error);
	GList *		(*query_auth_types_sync)
						(CamelService *service,
						 GCancellable *cancellable,
						 GError **error);

	/* Padding for future expansion */
	gpointer reserved[20];
};

/* query_auth_types returns a GList of these */
typedef struct {
	const gchar *name;               /* user-friendly name */
	const gchar *description;
	const gchar *authproto;

	gboolean need_password;   /* needs a password to authenticate */
} CamelServiceAuthType;

GType		camel_service_get_type		(void);
GQuark		camel_service_error_quark	(void) G_GNUC_CONST;
void		camel_service_migrate_files	(CamelService *service);
CamelURL *	camel_service_new_camel_url	(CamelService *service);
CamelServiceConnectionStatus
		camel_service_get_connection_status
						(CamelService *service);
const gchar *	camel_service_get_display_name	(CamelService *service);
gchar *		camel_service_dup_display_name	(CamelService *service);
void		camel_service_set_display_name	(CamelService *service,
						 const gchar *display_name);
const gchar *	camel_service_get_password	(CamelService *service);
gchar *		camel_service_dup_password	(CamelService *service);
void		camel_service_set_password	(CamelService *service,
						 const gchar *password);
const gchar *	camel_service_get_user_data_dir	(CamelService *service);
const gchar *	camel_service_get_user_cache_dir
						(CamelService *service);
gchar *		camel_service_get_name		(CamelService *service,
						 gboolean brief);
CamelProvider *	camel_service_get_provider	(CamelService *service);
GProxyResolver *
		camel_service_ref_proxy_resolver
						(CamelService *service);
void		camel_service_set_proxy_resolver
						(CamelService *service,
						 GProxyResolver *proxy_resolver);
struct _CamelSession *
		camel_service_ref_session	(CamelService *service);
CamelSettings *	camel_service_ref_settings	(CamelService *service);
void		camel_service_set_settings	(CamelService *service,
						 CamelSettings *settings);
const gchar *	camel_service_get_uid		(CamelService *service);
void		camel_service_queue_task	(CamelService *service,
						 GTask *task,
						 GTaskThreadFunc task_func);
gboolean	camel_service_connect_sync	(CamelService *service,
						 GCancellable *cancellable,
						 GError **error);
void		camel_service_connect		(CamelService *service,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_service_connect_finish	(CamelService *service,
						 GAsyncResult *result,
						 GError **error);
gboolean	camel_service_disconnect_sync	(CamelService *service,
						 gboolean clean,
						 GCancellable *cancellable,
						 GError **error);
void		camel_service_disconnect	(CamelService *service,
						 gboolean clean,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_service_disconnect_finish	(CamelService *service,
						 GAsyncResult *result,
						 GError **error);
CamelAuthenticationResult
		camel_service_authenticate_sync	(CamelService *service,
						 const gchar *mechanism,
						 GCancellable *cancellable,
						 GError **error);
void		camel_service_authenticate	(CamelService *service,
						 const gchar *mechanism,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
CamelAuthenticationResult
		camel_service_authenticate_finish
						(CamelService *service,
						 GAsyncResult *result,
						 GError **error);
GList *		camel_service_query_auth_types_sync
						(CamelService *service,
						 GCancellable *cancellable,
						 GError **error);
void		camel_service_query_auth_types	(CamelService *service,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
GList *		camel_service_query_auth_types_finish
						(CamelService *service,
						 GAsyncResult *result,
						 GError **error);

GType		camel_service_auth_type_get_type(void);
CamelServiceAuthType *
		camel_service_auth_type_copy	(const CamelServiceAuthType *service_auth_type);
void		camel_service_auth_type_free	(CamelServiceAuthType *service_auth_type);

G_END_DECLS

#endif /* CAMEL_SERVICE_H */
