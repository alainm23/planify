/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_SASL_H
#define CAMEL_SASL_H

#include <camel/camel-service.h>

/* Standard GObject macros */
#define CAMEL_TYPE_SASL \
	(camel_sasl_get_type ())
#define CAMEL_SASL(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SASL, CamelSasl))
#define CAMEL_SASL_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SASL, CamelSaslClass))
#define CAMEL_IS_SASL(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SASL))
#define CAMEL_IS_SASL_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SASL))
#define CAMEL_SASL_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_SASL, CamelSaslClass))

G_BEGIN_DECLS

typedef struct _CamelSasl CamelSasl;
typedef struct _CamelSaslClass CamelSaslClass;
typedef struct _CamelSaslPrivate CamelSaslPrivate;

struct _CamelSasl {
	GObject parent;
	CamelSaslPrivate *priv;
};

struct _CamelSaslClass {
	GObjectClass parent_class;

	/* Auth Mechanism Details */
	CamelServiceAuthType *auth_type;

	/* Synchronous I/O Methods */
	gboolean	(*try_empty_password_sync)
						(CamelSasl *sasl,
						 GCancellable *cancellable,
						 GError **error);
	GByteArray *	(*challenge_sync)	(CamelSasl *sasl,
						 GByteArray *token,
						 GCancellable *cancellable,
						 GError **error);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_sasl_get_type		(void);
CamelSasl *	camel_sasl_new			(const gchar *service_name,
						 const gchar *mechanism,
						 CamelService *service);
gboolean	camel_sasl_try_empty_password_sync
						(CamelSasl *sasl,
						 GCancellable *cancellable,
						 GError **error);
void		camel_sasl_try_empty_password	(CamelSasl *sasl,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_sasl_try_empty_password_finish
						(CamelSasl *sasl,
						 GAsyncResult *result,
						 GError **error);
gboolean	camel_sasl_get_authenticated	(CamelSasl *sasl);
void		camel_sasl_set_authenticated	(CamelSasl *sasl,
						 gboolean authenticated);
const gchar *	camel_sasl_get_mechanism	(CamelSasl *sasl);
CamelService *	camel_sasl_get_service		(CamelSasl *sasl);
const gchar *	camel_sasl_get_service_name	(CamelSasl *sasl);

GByteArray *	camel_sasl_challenge_sync	(CamelSasl *sasl,
						 GByteArray *token,
						 GCancellable *cancellable,
						 GError **error);
void		camel_sasl_challenge		(CamelSasl *sasl,
						 GByteArray *token,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
GByteArray *	camel_sasl_challenge_finish	(CamelSasl *sasl,
						 GAsyncResult *result,
						 GError **error);
gchar *		camel_sasl_challenge_base64_sync
						(CamelSasl *sasl,
						 const gchar *token,
						 GCancellable *cancellable,
						 GError **error);
void		camel_sasl_challenge_base64	(CamelSasl *sasl,
						 const gchar *token,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gchar *		camel_sasl_challenge_base64_finish
						(CamelSasl *sasl,
						 GAsyncResult *result,
						 GError **error);

GList *		camel_sasl_authtype_list	(gboolean include_plain);
CamelServiceAuthType *
		camel_sasl_authtype		(const gchar *mechanism);
gboolean	camel_sasl_is_xoauth2_alias	(const gchar *mechanism);

G_END_DECLS

#endif /* CAMEL_SASL_H */
