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

#include "evolution-data-server-config.h"

#include <string.h>

#include "camel-debug.h"
#include "camel-mime-utils.h"
#include "camel-sasl-anonymous.h"
#include "camel-sasl-cram-md5.h"
#include "camel-sasl-digest-md5.h"
#include "camel-sasl-gssapi.h"
#include "camel-sasl-login.h"
#include "camel-sasl-ntlm.h"
#include "camel-sasl-plain.h"
#include "camel-sasl-popb4smtp.h"
#include "camel-sasl-xoauth2.h"
#include "camel-sasl-xoauth2-google.h"
#include "camel-sasl-xoauth2-outlook.h"
#include "camel-sasl.h"
#include "camel-service.h"

#define CAMEL_SASL_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SASL, CamelSaslPrivate))

#define w(x)

typedef struct _AsyncContext AsyncContext;

struct _CamelSaslPrivate {
	CamelService *service;
	gboolean authenticated;
	gchar *service_name;
	gchar *mechanism;
};

struct _AsyncContext {
	GByteArray *token;
	gchar *base64_token;
};

enum {
	PROP_0,
	PROP_AUTHENTICATED,
	PROP_MECHANISM,
	PROP_SERVICE,
	PROP_SERVICE_NAME
};

G_DEFINE_ABSTRACT_TYPE (CamelSasl, camel_sasl, G_TYPE_OBJECT)

static void
async_context_free (AsyncContext *async_context)
{
	if (async_context->token != NULL)
		g_byte_array_free (async_context->token, TRUE);

	g_free (async_context->base64_token);

	g_slice_free (AsyncContext, async_context);
}

static void
sasl_build_class_table_rec (GType type,
                            GHashTable *class_table)
{
	GType *children;
	guint n_children, ii;

	children = g_type_children (type, &n_children);

	for (ii = 0; ii < n_children; ii++) {
		GType child_type = children[ii];
		CamelSaslClass *sasl_class;
		gpointer key;

		/* Recurse over the child's children. */
		sasl_build_class_table_rec (child_type, class_table);

		/* Skip abstract types. */
		if (G_TYPE_IS_ABSTRACT (child_type))
			continue;

		sasl_class = g_type_class_ref (child_type);

		if (sasl_class->auth_type == NULL) {
			g_critical (
				"%s has an empty CamelServiceAuthType",
				G_OBJECT_CLASS_NAME (sasl_class));
			g_type_class_unref (sasl_class);
			continue;
		}

		key = (gpointer) sasl_class->auth_type->authproto;
		g_hash_table_insert (class_table, key, sasl_class);
	}

	g_free (children);
}

static GHashTable *
sasl_build_class_table (void)
{
	GHashTable *class_table;

	/* Register known types. */
	g_type_ensure (CAMEL_TYPE_SASL_ANONYMOUS);
	g_type_ensure (CAMEL_TYPE_SASL_CRAM_MD5);
	g_type_ensure (CAMEL_TYPE_SASL_DIGEST_MD5);
#ifdef HAVE_KRB5
	g_type_ensure (CAMEL_TYPE_SASL_GSSAPI);
#endif
	g_type_ensure (CAMEL_TYPE_SASL_LOGIN);
	g_type_ensure (CAMEL_TYPE_SASL_NTLM);
	g_type_ensure (CAMEL_TYPE_SASL_PLAIN);
	g_type_ensure (CAMEL_TYPE_SASL_POPB4SMTP);
	g_type_ensure (CAMEL_TYPE_SASL_XOAUTH2);
	g_type_ensure (CAMEL_TYPE_SASL_XOAUTH2_GOOGLE);
	g_type_ensure (CAMEL_TYPE_SASL_XOAUTH2_OUTLOOK);

	class_table = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) NULL,
		(GDestroyNotify) g_type_class_unref);

	sasl_build_class_table_rec (CAMEL_TYPE_SASL, class_table);

	return class_table;
}

static void
sasl_set_mechanism (CamelSasl *sasl,
                    const gchar *mechanism)
{
	g_return_if_fail (mechanism != NULL);
	g_return_if_fail (sasl->priv->mechanism == NULL);

	sasl->priv->mechanism = g_strdup (mechanism);
}

static void
sasl_set_service (CamelSasl *sasl,
                  CamelService *service)
{
	g_return_if_fail (!service || CAMEL_IS_SERVICE (service));
	g_return_if_fail (sasl->priv->service == NULL);

	if (service)
		sasl->priv->service = g_object_ref (service);
}

static void
sasl_set_service_name (CamelSasl *sasl,
                       const gchar *service_name)
{
	g_return_if_fail (service_name != NULL);
	g_return_if_fail (sasl->priv->service_name == NULL);

	sasl->priv->service_name = g_strdup (service_name);
}

static void
sasl_set_property (GObject *object,
                   guint property_id,
                   const GValue *value,
                   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_AUTHENTICATED:
			camel_sasl_set_authenticated (
				CAMEL_SASL (object),
				g_value_get_boolean (value));
			return;

		case PROP_MECHANISM:
			sasl_set_mechanism (
				CAMEL_SASL (object),
				g_value_get_string (value));
			return;

		case PROP_SERVICE:
			sasl_set_service (
				CAMEL_SASL (object),
				g_value_get_object (value));
			return;

		case PROP_SERVICE_NAME:
			sasl_set_service_name (
				CAMEL_SASL (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
sasl_get_property (GObject *object,
                   guint property_id,
                   GValue *value,
                   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_AUTHENTICATED:
			g_value_set_boolean (
				value, camel_sasl_get_authenticated (
				CAMEL_SASL (object)));
			return;

		case PROP_MECHANISM:
			g_value_set_string (
				value, camel_sasl_get_mechanism (
				CAMEL_SASL (object)));
			return;

		case PROP_SERVICE:
			g_value_set_object (
				value, camel_sasl_get_service (
				CAMEL_SASL (object)));
			return;

		case PROP_SERVICE_NAME:
			g_value_set_string (
				value, camel_sasl_get_service_name (
				CAMEL_SASL (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
sasl_dispose (GObject *object)
{
	CamelSaslPrivate *priv;

	priv = CAMEL_SASL_GET_PRIVATE (object);

	if (priv->service != NULL) {
		g_object_unref (priv->service);
		priv->service = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_sasl_parent_class)->dispose (object);
}

static void
sasl_finalize (GObject *object)
{
	CamelSaslPrivate *priv;

	priv = CAMEL_SASL_GET_PRIVATE (object);

	g_free (priv->mechanism);
	g_free (priv->service_name);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_sasl_parent_class)->finalize (object);
}

static void
camel_sasl_class_init (CamelSaslClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelSaslPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = sasl_set_property;
	object_class->get_property = sasl_get_property;
	object_class->dispose = sasl_dispose;
	object_class->finalize = sasl_finalize;

	g_object_class_install_property (
		object_class,
		PROP_AUTHENTICATED,
		g_param_spec_boolean (
			"authenticated",
			"Authenticated",
			NULL,
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	g_object_class_install_property (
		object_class,
		PROP_MECHANISM,
		g_param_spec_string (
			"mechanism",
			"Mechanism",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (
		object_class,
		PROP_SERVICE,
		g_param_spec_object (
			"service",
			"Service",
			NULL,
			CAMEL_TYPE_SERVICE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY));

	g_object_class_install_property (
		object_class,
		PROP_SERVICE_NAME,
		g_param_spec_string (
			"service-name",
			"Service Name",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY));
}

static void
camel_sasl_init (CamelSasl *sasl)
{
	sasl->priv = CAMEL_SASL_GET_PRIVATE (sasl);
}

/**
 * camel_sasl_new:
 * @service_name: the SASL service name
 * @mechanism: the SASL mechanism
 * @service: the CamelService that will be using this SASL
 *
 * Returns: (nullable): a new #CamelSasl object for the given @service_name,
 * @mechanism, and @service, or %NULL if the mechanism is not
 * supported.
 **/
CamelSasl *
camel_sasl_new (const gchar *service_name,
                const gchar *mechanism,
                CamelService *service)
{
	GHashTable *class_table;
	CamelSaslClass *sasl_class;
	CamelSasl *sasl = NULL;

	g_return_val_if_fail (service_name != NULL, NULL);
	g_return_val_if_fail (mechanism != NULL, NULL);
	g_return_val_if_fail (CAMEL_IS_SERVICE (service), NULL);

	class_table = sasl_build_class_table ();
	sasl_class = g_hash_table_lookup (class_table, mechanism);

	if (sasl_class != NULL)
		sasl = g_object_new (
			G_OBJECT_CLASS_TYPE (sasl_class),
			"mechanism", mechanism,
			"service", service,
			"service-name", service_name,
			NULL);

	g_hash_table_destroy (class_table);

	return sasl;
}

/**
 * camel_sasl_get_authenticated:
 * @sasl: a #CamelSasl
 *
 * Returns: whether or not @sasl has successfully authenticated the
 * user. This will be %TRUE after it returns the last needed response.
 * The caller must still pass that information on to the server and
 * verify that it has accepted it.
 **/
gboolean
camel_sasl_get_authenticated (CamelSasl *sasl)
{
	g_return_val_if_fail (CAMEL_IS_SASL (sasl), FALSE);

	return sasl->priv->authenticated;
}

/**
 * camel_sasl_try_empty_password_sync:
 * @sasl: a #CamelSasl object
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Returns: whether or not @sasl can attempt to authenticate without a
 * password being provided by the caller. This will be %TRUE for an
 * authentication method which can attempt to use single-sign-on
 * credentials, but which can fall back to using a provided password
 * so it still has the @need_password flag set in its description.
 *
 * Since: 3.2
 **/
gboolean
camel_sasl_try_empty_password_sync (CamelSasl *sasl,
                                    GCancellable *cancellable,
                                    GError **error)
{
	CamelSaslClass *class;

	g_return_val_if_fail (CAMEL_IS_SASL (sasl), FALSE);

	class = CAMEL_SASL_GET_CLASS (sasl);
	g_return_val_if_fail (class != NULL, FALSE);

	if (class->try_empty_password_sync == NULL)
		return FALSE;

	return class->try_empty_password_sync (sasl, cancellable, error);
}

/* Helpder for camel_sasl_try_empty_password() */
static void
sasl_try_empty_password_thread (GTask *task,
                                gpointer source_object,
                                gpointer task_data,
                                GCancellable *cancellable)
{
	gboolean result;
	GError *local_error = NULL;

	result = camel_sasl_try_empty_password_sync (
		CAMEL_SASL (source_object),
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, result);
	}
}

/**
 * camel_sasl_try_empty_password:
 * @sasl: a #CamelSasl
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously determine whether @sasl can be used for password-less
 * authentication, for example single-sign-on using system credentials.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_sasl_try_empty_password_finish() to get the result of the
 * operation.
 *
 * Since: 3.2
 **/
void
camel_sasl_try_empty_password (CamelSasl *sasl,
                               gint io_priority,
                               GCancellable *cancellable,
                               GAsyncReadyCallback callback,
                               gpointer user_data)
{
	GTask *task;

	g_return_if_fail (CAMEL_IS_SASL (sasl));

	task = g_task_new (sasl, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_sasl_try_empty_password);
	g_task_set_priority (task, io_priority);

	g_task_run_in_thread (task, sasl_try_empty_password_thread);

	g_object_unref (task);
}

/**
 * camel_sasl_try_empty_password_finish:
 * @sasl: a #CamelSasl
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_sasl_try_empty_password().
 *
 * Returns: the SASL response.  If an error occurred, @error will also be set.
 *
 * Since: 3.2
 **/
gboolean
camel_sasl_try_empty_password_finish (CamelSasl *sasl,
                                      GAsyncResult *result,
                                      GError **error)
{
	g_return_val_if_fail (CAMEL_IS_SASL (sasl), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, sasl), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_sasl_try_empty_password), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_sasl_set_authenticated:
 * @sasl: a #CamelSasl
 * @authenticated: whether we have successfully authenticated
 *
 * Since: 2.32
 **/
void
camel_sasl_set_authenticated (CamelSasl *sasl,
                              gboolean authenticated)
{
	g_return_if_fail (CAMEL_IS_SASL (sasl));

	if (sasl->priv->authenticated == authenticated)
		return;

	sasl->priv->authenticated = authenticated;

	g_object_notify (G_OBJECT (sasl), "authenticated");
}

/**
 * camel_sasl_get_mechanism:
 * @sasl: a #CamelSasl
 *
 * Since: 2.32
 **/
const gchar *
camel_sasl_get_mechanism (CamelSasl *sasl)
{
	g_return_val_if_fail (CAMEL_IS_SASL (sasl), NULL);

	return sasl->priv->mechanism;
}

/**
 * camel_sasl_get_service:
 * @sasl: a #CamelSasl
 *
 * Returns: (transfer none):
 *
 * Since: 2.32
 **/
CamelService *
camel_sasl_get_service (CamelSasl *sasl)
{
	g_return_val_if_fail (CAMEL_IS_SASL (sasl), NULL);

	return sasl->priv->service;
}

/**
 * camel_sasl_get_service_name:
 * @sasl: a #CamelSasl
 *
 * Since: 2.32
 **/
const gchar *
camel_sasl_get_service_name (CamelSasl *sasl)
{
	g_return_val_if_fail (CAMEL_IS_SASL (sasl), NULL);

	return sasl->priv->service_name;
}

/**
 * camel_sasl_challenge_sync:
 * @sasl: a #CamelSasl
 * @token: a token, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * If @token is %NULL, generate the initial SASL message to send to
 * the server.  (This will be %NULL if the client doesn't initiate the
 * exchange.)  Otherwise, @token is a challenge from the server, and
 * the return value is the response.
 *
 * Free the returned #GByteArray with g_byte_array_free().
 *
 * Returns: (transfer full): the SASL response or %NULL. If an error occurred, @error will
 * also be set.
 **/
GByteArray *
camel_sasl_challenge_sync (CamelSasl *sasl,
                           GByteArray *token,
                           GCancellable *cancellable,
                           GError **error)
{
	CamelSaslClass *class;
	GByteArray *response;

	g_return_val_if_fail (CAMEL_IS_SASL (sasl), NULL);

	class = CAMEL_SASL_GET_CLASS (sasl);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->challenge_sync != NULL, NULL);

	response = class->challenge_sync (sasl, token, cancellable, error);
	if (token != NULL)
		CAMEL_CHECK_GERROR (
			sasl, challenge_sync, response != NULL, error);

	return response;
}

/* Helper for camel_sasl_challenge() */
static void
sasl_challenge_thread (GTask *task,
                       gpointer source_object,
                       gpointer task_data,
                       GCancellable *cancellable)
{
	GByteArray *response;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	response = camel_sasl_challenge_sync (
		CAMEL_SASL (source_object),
		async_context->token,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_warn_if_fail (response == NULL);
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (
			task, response,
			(GDestroyNotify) g_byte_array_unref);
	}
}

/**
 * camel_sasl_challenge:
 * @sasl: a #CamelSasl
 * @token: a token, or %NULL
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * If @token is %NULL, asynchronously generate the initial SASL message
 * to send to the server.  (This will be %NULL if the client doesn't
 * initiate the exchange.)  Otherwise, @token is a challenge from the
 * server, and the asynchronous result is the response.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_sasl_challenge_finish() to get the result of the operation.
 *
 * Since: 3.0
 **/
void
camel_sasl_challenge (CamelSasl *sasl,
                      GByteArray *token,
                      gint io_priority,
                      GCancellable *cancellable,
                      GAsyncReadyCallback callback,
                      gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_SASL (sasl));

	async_context = g_slice_new0 (AsyncContext);
	async_context->token = g_byte_array_new ();

	g_byte_array_append (async_context->token, token->data, token->len);

	task = g_task_new (sasl, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_sasl_challenge);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, sasl_challenge_thread);

	g_object_unref (task);
}

/**
 * camel_sasl_challenge_finish:
 * @sasl: a #CamelSasl
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_sasl_challenge().  Free the
 * returned #GByteArray with g_byte_array_free().
 *
 * Returns: (transfer full): the SASL response or %NULL.  If an error occurred, @error will
 * also be set.
 *
 * Since: 3.0
 **/
GByteArray *
camel_sasl_challenge_finish (CamelSasl *sasl,
                             GAsyncResult *result,
                             GError **error)
{
	g_return_val_if_fail (CAMEL_IS_SASL (sasl), NULL);
	g_return_val_if_fail (g_task_is_valid (result, sasl), NULL);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_sasl_challenge), NULL);

	return g_task_propagate_pointer (G_TASK (result), error);
}

/**
 * camel_sasl_challenge_base64_sync:
 * @sasl: a #CamelSasl
 * @token: a base64-encoded token
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * As with camel_sasl_challenge_sync(), but the challenge @token and the
 * response are both base64-encoded.
 *
 * Returns: (transfer full): the base64-encoded response
 *
 * Since: 3.0
 **/
gchar *
camel_sasl_challenge_base64_sync (CamelSasl *sasl,
                                  const gchar *token,
                                  GCancellable *cancellable,
                                  GError **error)
{
	GByteArray *token_binary;
	GByteArray *response_binary;
	gchar *response;

	g_return_val_if_fail (CAMEL_IS_SASL (sasl), NULL);

	if (token != NULL && *token != '\0') {
		guchar *data;
		gsize length = 0;

		data = g_base64_decode (token, &length);
		token_binary = g_byte_array_new ();
		g_byte_array_append (token_binary, data, length);
		g_free (data);
	} else
		token_binary = NULL;

	response_binary = camel_sasl_challenge_sync (
		sasl, token_binary, cancellable, error);
	if (token_binary)
		g_byte_array_free (token_binary, TRUE);
	if (response_binary == NULL)
		return NULL;

	if (response_binary->len > 0)
		response = g_base64_encode (
			response_binary->data, response_binary->len);
	else
		response = g_strdup ("");

	g_byte_array_free (response_binary, TRUE);

	return response;
}

/* Helper for camel_sasl_challenge_base64() */
static void
sasl_challenge_base64_thread (GTask *task,
                              gpointer source_object,
                              gpointer task_data,
                              GCancellable *cancellable)
{
	gchar *base64_response;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	base64_response = camel_sasl_challenge_base64_sync (
		CAMEL_SASL (source_object),
		async_context->base64_token,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_warn_if_fail (base64_response == NULL);
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (
			task, base64_response,
			(GDestroyNotify) g_free);
	}
}

/**
 * camel_sasl_challenge_base64:
 * @sasl: a #CamelSasl
 * @token: a base64-encoded token
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * As with camel_sasl_challenge(), but the challenge @token and the
 * response are both base64-encoded.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_sasl_challenge_base64_finish() to get the result of
 * the operation.
 *
 * Since: 3.0
 **/
void
camel_sasl_challenge_base64 (CamelSasl *sasl,
                             const gchar *token,
                             gint io_priority,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_SASL (sasl));

	async_context = g_slice_new0 (AsyncContext);
	async_context->base64_token = g_strdup (token);

	task = g_task_new (sasl, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_sasl_challenge_base64);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, sasl_challenge_base64_thread);

	g_object_unref (task);
}

/**
 * camel_sasl_challenge_base64_finish:
 * @sasl: a #CamelSasl
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_sasl_challenge_base64().
 *
 * Returns: the base64-encoded response
 *
 * Since: 3.0
 **/
gchar *
camel_sasl_challenge_base64_finish (CamelSasl *sasl,
                                    GAsyncResult *result,
                                    GError **error)
{
	g_return_val_if_fail (CAMEL_IS_SASL (sasl), NULL);
	g_return_val_if_fail (g_task_is_valid (result, sasl), NULL);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_sasl_challenge_base64), NULL);

	return g_task_propagate_pointer (G_TASK (result), error);
}

/**
 * camel_sasl_authtype_list:
 * @include_plain: whether or not to include the PLAIN mechanism
 *
 * Returns: (element-type CamelServiceAuthType) (transfer container): a #GList of SASL-supported authtypes. The caller must
 * free the list, but not the contents.
 **/
GList *
camel_sasl_authtype_list (gboolean include_plain)
{
	CamelSaslClass *sasl_class;
	GHashTable *class_table;
	GList *types = NULL;

	/* XXX I guess these are supposed to be common SASL auth types,
	 *     since this is called by the IMAP, POP and SMTP providers.
	 *     The returned list can be extended with other auth types
	 *     by way of camel_sasl_authtype(), so maybe we should just
	 *     drop the ad-hoc "include_plain" parameter? */

	class_table = sasl_build_class_table ();

	sasl_class = g_hash_table_lookup (class_table, "CRAM-MD5");
	g_return_val_if_fail (sasl_class != NULL, types);
	types = g_list_prepend (types, sasl_class->auth_type);

	sasl_class = g_hash_table_lookup (class_table, "DIGEST-MD5");
	g_return_val_if_fail (sasl_class != NULL, types);
	types = g_list_prepend (types, sasl_class->auth_type);

#ifdef HAVE_KRB5
	sasl_class = g_hash_table_lookup (class_table, "GSSAPI");
	g_return_val_if_fail (sasl_class != NULL, types);
	types = g_list_prepend (types, sasl_class->auth_type);
#endif

	sasl_class = g_hash_table_lookup (class_table, "NTLM");
	g_return_val_if_fail (sasl_class != NULL, types);
	types = g_list_prepend (types, sasl_class->auth_type);

	if (include_plain) {
		sasl_class = g_hash_table_lookup (class_table, "PLAIN");
		g_return_val_if_fail (sasl_class != NULL, types);
		types = g_list_prepend (types, sasl_class->auth_type);
	}

	g_hash_table_destroy (class_table);

	return types;
}

/**
 * camel_sasl_authtype:
 * @mechanism: the SASL mechanism to get an authtype for
 *
 * Returns: a #CamelServiceAuthType for the given mechanism, if
 * it is supported.
 **/
CamelServiceAuthType *
camel_sasl_authtype (const gchar *mechanism)
{
	GHashTable *class_table;
	CamelSaslClass *sasl_class;
	CamelServiceAuthType *auth_type;

	g_return_val_if_fail (mechanism != NULL, NULL);

	class_table = sasl_build_class_table ();
	sasl_class = g_hash_table_lookup (class_table, mechanism);
	auth_type = (sasl_class != NULL) ? sasl_class->auth_type : NULL;
	g_hash_table_destroy (class_table);

	return auth_type;
}

/**
 * camel_sasl_is_xoauth2_alias:
 * @mechanism: (nullable): an authentication mechanism
 *
 * Checks whether exists a #CamelSasl method for the @mechanism and
 * whether it derives from #CamelSaslXOAuth2. Such mechanisms are
 * also treated as XOAUTH2, even their real name is different.
 *
 * Returns: whether exists #CamelSasl for the given @mechanism,
 *    which also derives from #CamelSaslXOAuth2.
 *
 * Since: 3.28
 **/
gboolean
camel_sasl_is_xoauth2_alias (const gchar *mechanism)
{
	GHashTable *class_table;
	CamelSaslClass *sasl_class;
	gboolean exists = FALSE;

	if (!mechanism || !*mechanism)
		return FALSE;

	class_table = sasl_build_class_table ();
	sasl_class = g_hash_table_lookup (class_table, mechanism);
	if (sasl_class) {
		gpointer parent_class = sasl_class;

		while (parent_class = g_type_class_peek_parent (parent_class), parent_class) {
			if (CAMEL_IS_SASL_XOAUTH2_CLASS (parent_class)) {
				exists = TRUE;
				break;
			}
		}
	}

	g_hash_table_destroy (class_table);

	return exists;
}
