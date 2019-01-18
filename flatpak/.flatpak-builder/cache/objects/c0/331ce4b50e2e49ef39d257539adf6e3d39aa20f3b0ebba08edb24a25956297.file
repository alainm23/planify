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

#include <glib/gi18n-lib.h>

#include "camel-cipher-context.h"
#include "camel-debug.h"
#include "camel-session.h"
#include "camel-stream.h"
#include "camel-operation.h"

#include "camel-mime-utils.h"
#include "camel-medium.h"
#include "camel-multipart.h"
#include "camel-multipart-encrypted.h"
#include "camel-multipart-signed.h"
#include "camel-mime-message.h"
#include "camel-mime-filter-canon.h"
#include "camel-stream-filter.h"

#define CAMEL_CIPHER_CONTEXT_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_CIPHER_CONTEXT, CamelCipherContextPrivate))

#define CIPHER_LOCK(ctx) \
	g_mutex_lock (&((CamelCipherContext *) ctx)->priv->lock)
#define CIPHER_UNLOCK(ctx) \
	g_mutex_unlock (&((CamelCipherContext *) ctx)->priv->lock);

#define d(x)

typedef struct _AsyncContext AsyncContext;

struct _CamelCipherContextPrivate {
	CamelSession *session;
	GMutex lock;
};

struct _AsyncContext {
	/* arguments */
	CamelCipherHash hash;
	CamelMimePart *ipart;
	CamelMimePart *opart;
	CamelStream *stream;
	GPtrArray *strings;
	gchar *userid;
};

enum {
	PROP_0,
	PROP_SESSION
};

G_DEFINE_TYPE (CamelCipherContext, camel_cipher_context, G_TYPE_OBJECT)

G_DEFINE_BOXED_TYPE (CamelCipherValidity,
		camel_cipher_validity,
		camel_cipher_validity_clone,
		camel_cipher_validity_free)

static void
async_context_free (AsyncContext *async_context)
{
	if (async_context->ipart != NULL)
		g_object_unref (async_context->ipart);

	if (async_context->opart != NULL)
		g_object_unref (async_context->opart);

	if (async_context->stream != NULL)
		g_object_unref (async_context->stream);

	if (async_context->strings != NULL) {
		g_ptr_array_foreach (
			async_context->strings, (GFunc) g_free, NULL);
		g_ptr_array_free (async_context->strings, TRUE);
	}

	g_free (async_context->userid);

	g_slice_free (AsyncContext, async_context);
}

static void
cipher_context_set_session (CamelCipherContext *context,
                            CamelSession *session)
{
	g_return_if_fail (CAMEL_IS_SESSION (session));
	g_return_if_fail (context->priv->session == NULL);

	context->priv->session = g_object_ref (session);
}

static void
cipher_context_set_property (GObject *object,
                             guint property_id,
                             const GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SESSION:
			cipher_context_set_session (
				CAMEL_CIPHER_CONTEXT (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
cipher_context_get_property (GObject *object,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_SESSION:
			g_value_set_object (
				value, camel_cipher_context_get_session (
				CAMEL_CIPHER_CONTEXT (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
cipher_context_dispose (GObject *object)
{
	CamelCipherContextPrivate *priv;

	priv = CAMEL_CIPHER_CONTEXT_GET_PRIVATE (object);

	if (priv->session != NULL) {
		g_object_unref (priv->session);
		priv->session = NULL;
	}

	/* Chain up to parent's dispose () method. */
	G_OBJECT_CLASS (camel_cipher_context_parent_class)->dispose (object);
}

static void
cipher_context_finalize (GObject *object)
{
	CamelCipherContextPrivate *priv;

	priv = CAMEL_CIPHER_CONTEXT_GET_PRIVATE (object);

	g_mutex_clear (&priv->lock);

	/* Chain up to parent's finalize () method. */
	G_OBJECT_CLASS (camel_cipher_context_parent_class)->finalize (object);
}

static const gchar *
cipher_context_hash_to_id (CamelCipherContext *context,
                           CamelCipherHash hash)
{
	return NULL;
}

static CamelCipherHash
cipher_context_id_to_hash (CamelCipherContext *context,
                           const gchar *id)
{
	return CAMEL_CIPHER_HASH_DEFAULT;
}

static gboolean
cipher_context_sign_sync (CamelCipherContext *ctx,
                          const gchar *userid,
                          CamelCipherHash hash,
                          CamelMimePart *ipart,
                          CamelMimePart *opart,
                          GCancellable *cancellable,
                          GError **error)
{
	g_set_error (
		error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
		_("Signing is not supported by this cipher"));

	return FALSE;
}

static CamelCipherValidity *
cipher_context_verify_sync (CamelCipherContext *context,
                            CamelMimePart *sigpart,
                            GCancellable *cancellable,
                            GError **error)
{
	g_set_error (
		error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
		_("Verifying is not supported by this cipher"));

	return NULL;
}

static gboolean
cipher_context_encrypt_sync (CamelCipherContext *context,
                             const gchar *userid,
                             GPtrArray *recipients,
                             CamelMimePart *ipart,
                             CamelMimePart *opart,
                             GCancellable *cancellable,
                             GError **error)
{
	g_set_error (
		error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
		_("Encryption is not supported by this cipher"));

	return FALSE;
}

static CamelCipherValidity *
cipher_context_decrypt_sync (CamelCipherContext *context,
                             CamelMimePart *ipart,
                             CamelMimePart *opart,
                             GCancellable *cancellable,
                             GError **error)
{
	g_set_error (
		error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
		_("Decryption is not supported by this cipher"));

	return NULL;
}

static void
camel_cipher_context_class_init (CamelCipherContextClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelCipherContextPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = cipher_context_set_property;
	object_class->get_property = cipher_context_get_property;
	object_class->dispose = cipher_context_dispose;
	object_class->finalize = cipher_context_finalize;

	class->hash_to_id = cipher_context_hash_to_id;
	class->id_to_hash = cipher_context_id_to_hash;

	class->sign_sync = cipher_context_sign_sync;
	class->verify_sync = cipher_context_verify_sync;
	class->encrypt_sync = cipher_context_encrypt_sync;
	class->decrypt_sync = cipher_context_decrypt_sync;

	g_object_class_install_property (
		object_class,
		PROP_SESSION,
		g_param_spec_object (
			"session",
			"Session",
			NULL,
			CAMEL_TYPE_SESSION,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY));
}

static void
camel_cipher_context_init (CamelCipherContext *context)
{
	context->priv = CAMEL_CIPHER_CONTEXT_GET_PRIVATE (context);
	g_mutex_init (&context->priv->lock);
}

/* Helper for camel_cipher_context_sign() */
static void
cipher_context_sign_thread (GTask *task,
                            gpointer source_object,
                            gpointer task_data,
                            GCancellable *cancellable)
{
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	success = camel_cipher_context_sign_sync (
		CAMEL_CIPHER_CONTEXT (source_object),
		async_context->userid,
		async_context->hash,
		async_context->ipart,
		async_context->opart,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_cipher_context_sign_sync:
 * @context: a #CamelCipherContext
 * @userid: a private key to use to sign the stream
 * @hash: preferred Message-Integrity-Check hash algorithm
 * @ipart: input #CamelMimePart
 * @opart: output #CamelMimePart
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Converts the (unsigned) part @ipart into a new self-contained MIME
 * part @opart.  This may be a multipart/signed part, or a simple part
 * for enveloped types.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_cipher_context_sign_sync (CamelCipherContext *context,
                                const gchar *userid,
                                CamelCipherHash hash,
                                CamelMimePart *ipart,
                                CamelMimePart *opart,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelCipherContextClass *class;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_CIPHER_CONTEXT (context), FALSE);

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->sign_sync != NULL, FALSE);

	CIPHER_LOCK (context);

	/* Check for cancellation after locking. */
	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		CIPHER_UNLOCK (context);
		return FALSE;
	}

	camel_operation_push_message (cancellable, _("Signing message"));

	success = class->sign_sync (
		context, userid, hash, ipart, opart, cancellable, error);
	CAMEL_CHECK_GERROR (context, sign_sync, success, error);

	camel_operation_pop_message (cancellable);

	CIPHER_UNLOCK (context);

	return success;
}

/**
 * camel_cipher_context_sign:
 * @context: a #CamelCipherContext
 * @userid: a private key to use to sign the stream
 * @hash: preferred Message-Integrity-Check hash algorithm
 * @ipart: input #CamelMimePart
 * @opart: output #CamelMimePart
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously converts the (unsigned) part @ipart into a new
 * self-contained MIME part @opart.  This may be a multipart/signed part,
 * or a simple part for enveloped types.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call camel_cipher_context_sign_finish() to get the result of the operation.
 *
 * Since: 3.0
 **/
void
camel_cipher_context_sign (CamelCipherContext *context,
                           const gchar *userid,
                           CamelCipherHash hash,
                           CamelMimePart *ipart,
                           CamelMimePart *opart,
                           gint io_priority,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_CIPHER_CONTEXT (context));
	g_return_if_fail (CAMEL_IS_MIME_PART (ipart));
	g_return_if_fail (CAMEL_IS_MIME_PART (opart));

	async_context = g_slice_new0 (AsyncContext);
	async_context->userid = g_strdup (userid);
	async_context->hash = hash;
	async_context->ipart = g_object_ref (ipart);
	async_context->opart = g_object_ref (opart);

	task = g_task_new (context, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_cipher_context_sign);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, cipher_context_sign_thread);

	g_object_unref (task);
}

/**
 * camel_cipher_context_sign_finish:
 * @context: a #CamelCipherContext
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_cipher_context_sign().
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_cipher_context_sign_finish (CamelCipherContext *context,
                                  GAsyncResult *result,
                                  GError **error)
{
	g_return_val_if_fail (CAMEL_IS_CIPHER_CONTEXT (context), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, context), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_cipher_context_sign), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_cipher_context_verify_sync:
 * @context: a #CamelCipherContext
 * @ipart: the #CamelMimePart to verify
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Verifies the signature.
 *
 * Returns: a #CamelCipherValidity structure containing information
 * about the integrity of the input stream, or %NULL on failure to
 * execute at all
 **/
CamelCipherValidity *
camel_cipher_context_verify_sync (CamelCipherContext *context,
                                  CamelMimePart *ipart,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelCipherContextClass *class;
	CamelCipherValidity *valid;

	g_return_val_if_fail (CAMEL_IS_CIPHER_CONTEXT (context), NULL);
	g_return_val_if_fail (CAMEL_IS_MIME_PART (ipart), NULL);

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->verify_sync != NULL, NULL);

	CIPHER_LOCK (context);

	/* Check for cancellation after locking. */
	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		CIPHER_UNLOCK (context);
		return NULL;
	}

	valid = class->verify_sync (context, ipart, cancellable, error);
	CAMEL_CHECK_GERROR (context, verify_sync, valid != NULL, error);

	CIPHER_UNLOCK (context);

	return valid;
}

/* Helper for camel_cipher_context_verify() */
static void
cipher_context_verify_thread (GTask *task,
                              gpointer source_object,
                              gpointer task_data,
                              GCancellable *cancellable)
{
	CamelCipherValidity *validity;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	validity = camel_cipher_context_verify_sync (
		CAMEL_CIPHER_CONTEXT (source_object),
		async_context->ipart,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_warn_if_fail (validity == NULL);
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (
			task, validity,
			(GDestroyNotify) camel_cipher_validity_free);
	}
}

/**
 * camel_cipher_context_verify:
 * @context: a #CamelCipherContext
 * @ipart: the #CamelMimePart to verify
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously verifies the signature.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_cipher_context_verify_finish() to get the result of
 * the operation.
 *
 * Since: 3.0
 **/
void
camel_cipher_context_verify (CamelCipherContext *context,
                             CamelMimePart *ipart,
                             gint io_priority,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_CIPHER_CONTEXT (context));
	g_return_if_fail (CAMEL_IS_MIME_PART (ipart));

	async_context = g_slice_new0 (AsyncContext);
	async_context->ipart = g_object_ref (ipart);

	task = g_task_new (context, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_cipher_context_verify);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, cipher_context_verify_thread);

	g_object_unref (task);
}

/**
 * camel_cipher_context_verify_finish:
 * @context: a #CamelCipherContext
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_cipher_context_verify().
 *
 * Returns: a #CamelCipherValidity structure containing information
 * about the integrity of the input stream, or %NULL on failure to
 * execute at all
 *
 * Since: 3.0
 **/
CamelCipherValidity *
camel_cipher_context_verify_finish (CamelCipherContext *context,
                                    GAsyncResult *result,
                                    GError **error)
{
	g_return_val_if_fail (CAMEL_IS_CIPHER_CONTEXT (context), NULL);
	g_return_val_if_fail (g_task_is_valid (result, context), NULL);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_cipher_context_verify), NULL);

	return g_task_propagate_pointer (G_TASK (result), error);
}

/**
 * camel_cipher_context_encrypt_sync:
 * @context: a #CamelCipherContext
 * @userid: key ID (or email address) to use when signing, or %NULL to not sign
 * @recipients: (element-type utf8): an array of recipient key IDs and/or email addresses
 * @ipart: clear-text #CamelMimePart
 * @opart: cipher-text #CamelMimePart
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Encrypts (and optionally signs) the clear-text @ipart and writes the
 * resulting cipher-text to @opart.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_cipher_context_encrypt_sync (CamelCipherContext *context,
                                   const gchar *userid,
                                   GPtrArray *recipients,
                                   CamelMimePart *ipart,
                                   CamelMimePart *opart,
                                   GCancellable *cancellable,
                                   GError **error)
{
	CamelCipherContextClass *class;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_CIPHER_CONTEXT (context), FALSE);
	g_return_val_if_fail (CAMEL_IS_MIME_PART (ipart), FALSE);
	g_return_val_if_fail (CAMEL_IS_MIME_PART (opart), FALSE);

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);
	g_return_val_if_fail (class != NULL, FALSE);
	g_return_val_if_fail (class->encrypt_sync != NULL, FALSE);

	CIPHER_LOCK (context);

	/* Check for cancellation after locking. */
	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		CIPHER_UNLOCK (context);
		return FALSE;
	}

	camel_operation_push_message (cancellable, _("Encrypting message"));

	success = class->encrypt_sync (
		context, userid, recipients,
		ipart, opart, cancellable, error);
	CAMEL_CHECK_GERROR (context, encrypt_sync, success, error);

	camel_operation_pop_message (cancellable);

	CIPHER_UNLOCK (context);

	return success;
}

/* Helper for camel_cipher_context_encrypt_thread() */
static void
cipher_context_encrypt_thread (GTask *task,
                               gpointer source_object,
                               gpointer task_data,
                               GCancellable *cancellable)
{
	gboolean success;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	success = camel_cipher_context_encrypt_sync (
		CAMEL_CIPHER_CONTEXT (source_object),
		async_context->userid,
		async_context->strings,
		async_context->ipart,
		async_context->opart,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_task_return_error (task, local_error);
	} else {
		g_task_return_boolean (task, success);
	}
}

/**
 * camel_cipher_context_encrypt:
 * @context: a #CamelCipherContext
 * @userid: key id (or email address) to use when signing, or %NULL to not sign
 * @recipients: (element-type utf8): an array of recipient key IDs and/or email addresses
 * @ipart: clear-text #CamelMimePart
 * @opart: cipher-text #CamelMimePart
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously encrypts (and optionally signs) the clear-text @ipart and
 * writes the resulting cipher-text to @opart.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_cipher_context_encrypt_finish() to get the result of
 * the operation.
 *
 * Since: 3.0
 **/
void
camel_cipher_context_encrypt (CamelCipherContext *context,
                              const gchar *userid,
                              GPtrArray *recipients,
                              CamelMimePart *ipart,
                              CamelMimePart *opart,
                              gint io_priority,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;
	guint ii;

	g_return_if_fail (CAMEL_IS_CIPHER_CONTEXT (context));
	g_return_if_fail (CAMEL_IS_MIME_PART (ipart));
	g_return_if_fail (CAMEL_IS_MIME_PART (opart));

	async_context = g_slice_new0 (AsyncContext);
	async_context->userid = g_strdup (userid);
	async_context->strings = g_ptr_array_new ();
	async_context->ipart = g_object_ref (ipart);
	async_context->opart = g_object_ref (opart);

	for (ii = 0; ii < recipients->len; ii++)
		g_ptr_array_add (
			async_context->strings,
			g_strdup (recipients->pdata[ii]));

	task = g_task_new (context, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_cipher_context_encrypt);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, cipher_context_encrypt_thread);

	g_object_unref (task);
}

/**
 * camel_cipher_context_encrypt_finish:
 * @context: a #CamelCipherContext
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_cipher_context_encrypt().
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.0
 **/
gboolean
camel_cipher_context_encrypt_finish (CamelCipherContext *context,
                                     GAsyncResult *result,
                                     GError **error)
{
	g_return_val_if_fail (CAMEL_IS_CIPHER_CONTEXT (context), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, context), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_cipher_context_encrypt), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

/**
 * camel_cipher_context_decrypt_sync:
 * @context: a #CamelCipherContext
 * @ipart: cipher-text #CamelMimePart
 * @opart: clear-text #CamelMimePart
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Decrypts @ipart into @opart.
 *
 * Returns: a validity/encryption status, or %NULL on error
 *
 * Since: 3.0
 **/
CamelCipherValidity *
camel_cipher_context_decrypt_sync (CamelCipherContext *context,
                                   CamelMimePart *ipart,
                                   CamelMimePart *opart,
                                   GCancellable *cancellable,
                                   GError **error)
{
	CamelCipherContextClass *class;
	CamelCipherValidity *valid;

	g_return_val_if_fail (CAMEL_IS_CIPHER_CONTEXT (context), NULL);
	g_return_val_if_fail (CAMEL_IS_MIME_PART (ipart), NULL);
	g_return_val_if_fail (CAMEL_IS_MIME_PART (opart), NULL);

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->decrypt_sync != NULL, NULL);

	CIPHER_LOCK (context);

	/* Check for cancellation after locking. */
	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		CIPHER_UNLOCK (context);
		return NULL;
	}

	camel_operation_push_message (cancellable, _("Decrypting message"));

	valid = class->decrypt_sync (
		context, ipart, opart, cancellable, error);
	CAMEL_CHECK_GERROR (context, decrypt_sync, valid != NULL, error);

	camel_operation_pop_message (cancellable);

	CIPHER_UNLOCK (context);

	return valid;
}

/* Helper for camel_cipher_context_decrypt() */
static void
cipher_context_decrypt_thread (GTask *task,
                               gpointer source_object,
                               gpointer task_data,
                               GCancellable *cancellable)
{
	CamelCipherValidity *validity;
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = (AsyncContext *) task_data;

	validity = camel_cipher_context_decrypt_sync (
		CAMEL_CIPHER_CONTEXT (source_object),
		async_context->ipart,
		async_context->opart,
		cancellable, &local_error);

	if (local_error != NULL) {
		g_warn_if_fail (validity == NULL);
		g_task_return_error (task, local_error);
	} else {
		g_task_return_pointer (
			task, validity,
			(GDestroyNotify) camel_cipher_validity_free);
	}
}

/**
 * camel_cipher_context_decrypt:
 * @context: a #CamelCipherContext
 * @ipart: cipher-text #CamelMimePart
 * @opart: clear-text #CamelMimePart
 * @io_priority: the I/O priority of the request
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously decrypts @ipart into @opart.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call camel_cipher_context_decrypt_finish() to get the result of
 * the operation.
 *
 * Since: 3.0
 **/
void
camel_cipher_context_decrypt (CamelCipherContext *context,
                              CamelMimePart *ipart,
                              CamelMimePart *opart,
                              gint io_priority,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GTask *task;
	AsyncContext *async_context;

	g_return_if_fail (CAMEL_IS_CIPHER_CONTEXT (context));
	g_return_if_fail (CAMEL_IS_MIME_PART (ipart));
	g_return_if_fail (CAMEL_IS_MIME_PART (opart));

	async_context = g_slice_new0 (AsyncContext);
	async_context->ipart = g_object_ref (ipart);
	async_context->opart = g_object_ref (opart);

	task = g_task_new (context, cancellable, callback, user_data);
	g_task_set_source_tag (task, camel_cipher_context_decrypt);
	g_task_set_priority (task, io_priority);

	g_task_set_task_data (
		task, async_context,
		(GDestroyNotify) async_context_free);

	g_task_run_in_thread (task, cipher_context_decrypt_thread);

	g_object_unref (task);
}

/**
 * camel_cipher_context_decrypt_finish:
 * @context: a #CamelCipherContext
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with camel_cipher_context_decrypt().
 *
 * Returns: a validity/encryption status, or %NULL on error
 *
 * Since: 3.0
 **/
CamelCipherValidity *
camel_cipher_context_decrypt_finish (CamelCipherContext *context,
                                     GAsyncResult *result,
                                     GError **error)
{
	g_return_val_if_fail (CAMEL_IS_CIPHER_CONTEXT (context), NULL);
	g_return_val_if_fail (g_task_is_valid (result, context), NULL);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, camel_cipher_context_decrypt), NULL);

	return g_task_propagate_pointer (G_TASK (result), error);
}

/* a couple of util functions */
CamelCipherHash
camel_cipher_context_id_to_hash (CamelCipherContext *context,
                                 const gchar *id)
{
	CamelCipherContextClass *class;

	g_return_val_if_fail (
		CAMEL_IS_CIPHER_CONTEXT (context),
		CAMEL_CIPHER_HASH_DEFAULT);

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);
	g_return_val_if_fail (class != NULL, CAMEL_CIPHER_HASH_DEFAULT);
	g_return_val_if_fail (class->id_to_hash != NULL, CAMEL_CIPHER_HASH_DEFAULT);

	return class->id_to_hash (context, id);
}

const gchar *
camel_cipher_context_hash_to_id (CamelCipherContext *context,
                                 CamelCipherHash hash)
{
	CamelCipherContextClass *class;

	g_return_val_if_fail (CAMEL_IS_CIPHER_CONTEXT (context), NULL);

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->hash_to_id != NULL, NULL);

	return class->hash_to_id (context, hash);
}

/* Cipher Validity stuff */
static void
ccv_certinfo_property_free (gpointer ptr)
{
	CamelCipherCertInfoProperty *property = ptr;

	if (property) {
		g_free (property->name);
		if (property->value_free)
			property->value_free (property->value);
		g_free (property);
	}
}

static void
ccv_certinfo_free (CamelCipherCertInfo *info)
{
	g_return_if_fail (info != NULL);

	g_free (info->name);
	g_free (info->email);

	if (info->cert_data && info->cert_data_free)
		info->cert_data_free (info->cert_data);

	g_slist_free_full (info->properties, ccv_certinfo_property_free);
	g_free (info);
}

CamelCipherValidity *
camel_cipher_validity_new (void)
{
	CamelCipherValidity *validity;

	validity = g_malloc (sizeof (*validity));
	camel_cipher_validity_init (validity);

	return validity;
}

void
camel_cipher_validity_init (CamelCipherValidity *validity)
{
	g_return_if_fail (validity != NULL);

	memset (validity, 0, sizeof (*validity));
	g_queue_init (&validity->children);
	g_queue_init (&validity->sign.signers);
	g_queue_init (&validity->encrypt.encrypters);
}

gboolean
camel_cipher_validity_get_valid (CamelCipherValidity *validity)
{
	return validity != NULL
		&& validity->sign.status == CAMEL_CIPHER_VALIDITY_SIGN_GOOD;
}

void
camel_cipher_validity_set_valid (CamelCipherValidity *validity,
                                 gboolean valid)
{
	g_return_if_fail (validity != NULL);

	validity->sign.status = valid ? CAMEL_CIPHER_VALIDITY_SIGN_GOOD : CAMEL_CIPHER_VALIDITY_SIGN_BAD;
}

gchar *
camel_cipher_validity_get_description (CamelCipherValidity *validity)
{
	g_return_val_if_fail (validity != NULL, NULL);

	return validity->sign.description;
}

void
camel_cipher_validity_set_description (CamelCipherValidity *validity,
                                       const gchar *description)
{
	g_return_if_fail (validity != NULL);

	g_free (validity->sign.description);
	validity->sign.description = g_strdup (description);
}

void
camel_cipher_validity_clear (CamelCipherValidity *validity)
{
	g_return_if_fail (validity != NULL);

	/* TODO: this doesn't free children/clear key lists */
	g_free (validity->sign.description);
	g_free (validity->encrypt.description);
	camel_cipher_validity_init (validity);
}

CamelCipherValidity *
camel_cipher_validity_clone (CamelCipherValidity *vin)
{
	CamelCipherValidity *vo;
	GList *head, *link;

	g_return_val_if_fail (vin != NULL, NULL);

	vo = camel_cipher_validity_new ();
	vo->sign.status = vin->sign.status;
	vo->sign.description = g_strdup (vin->sign.description);
	vo->encrypt.status = vin->encrypt.status;
	vo->encrypt.description = g_strdup (vin->encrypt.description);

	head = g_queue_peek_head_link (&vin->sign.signers);
	for (link = head; link != NULL; link = g_list_next (link)) {
		CamelCipherCertInfo *info = link->data;
		gint index;

		if (info->cert_data && info->cert_data_clone && info->cert_data_free)
			index = camel_cipher_validity_add_certinfo_ex (
				vo, CAMEL_CIPHER_VALIDITY_SIGN,
				info->name,
				info->email,
				info->cert_data_clone (info->cert_data),
				info->cert_data_free,
				info->cert_data_clone);
		else
			index = camel_cipher_validity_add_certinfo (
				vo, CAMEL_CIPHER_VALIDITY_SIGN,
				info->name,
				info->email);

		if (index != -1 && info->properties) {
			GSList *link;

			for (link = info->properties; link; link = g_slist_next (link)) {
				CamelCipherCertInfoProperty *property = link->data;
				gpointer value;

				if (!property)
					continue;

				value = property->value_clone ? property->value_clone (property->value) : property->value;
				camel_cipher_validity_set_certinfo_property (vo, CAMEL_CIPHER_VALIDITY_SIGN, index,
					property->name, value, property->value_free, property->value_clone);
			}
		}
	}

	head = g_queue_peek_head_link (&vin->encrypt.encrypters);
	for (link = head; link != NULL; link = g_list_next (link)) {
		CamelCipherCertInfo *info = link->data;
		gint index;

		if (info->cert_data && info->cert_data_clone && info->cert_data_free)
			index = camel_cipher_validity_add_certinfo_ex (
				vo, CAMEL_CIPHER_VALIDITY_SIGN,
				info->name,
				info->email,
				info->cert_data_clone (info->cert_data),
				info->cert_data_free,
				info->cert_data_clone);
		else
			index = camel_cipher_validity_add_certinfo (
				vo, CAMEL_CIPHER_VALIDITY_ENCRYPT,
				info->name,
				info->email);

		if (index != -1 && info->properties) {
			GSList *link;

			for (link = info->properties; link; link = g_slist_next (link)) {
				CamelCipherCertInfoProperty *property = link->data;
				gpointer value;

				if (!property)
					continue;

				value = property->value_clone ? property->value_clone (property->value) : property->value;
				camel_cipher_validity_set_certinfo_property (vo, CAMEL_CIPHER_VALIDITY_ENCRYPT, index,
					property->name, value, property->value_free, property->value_clone);
			}
		}
	}

	return vo;
}

/**
 * camel_cipher_validity_add_certinfo:
 * @vin: a #CamelCipherValidity
 * @mode: a #CamelCipherValidityMode, where to add the additional certificate information
 * @name: a name to add
 * @email: an e-mail address to add
 *
 * Add a cert info to the signer or encrypter info.
 *
 * Returns: Index of the added certinfo; -1 on error
 **/
gint
camel_cipher_validity_add_certinfo (CamelCipherValidity *vin,
                                    CamelCipherValidityMode mode,
                                    const gchar *name,
                                    const gchar *email)
{
	return camel_cipher_validity_add_certinfo_ex (vin, mode, name, email, NULL, NULL, NULL);
}

/**
 * camel_cipher_validity_add_certinfo_ex:
 * @vin: a #CamelCipherValidity
 * @mode: a #CamelCipherValidityMode, where to add the additional certificate information
 * @name: a name to add
 * @email: an e-mail address to add
 * @cert_data: (nullable) (destroy cert_data_free): a certificate data, or %NULL
 * @cert_data_free: (nullable): a destroy function for @cert_data; required, when @cert_data is not %NULL
 * @cert_data_clone: (nullable) (scope call): a copy function for @cert_data, to copy the data; required, when @cert_data is not %NULL
 *
 * Add a cert info to the signer or encrypter info, with extended data set.
 *
 * Returns: Index of the added certinfo; -1 on error
 *
 * Since: 2.30
 **/
gint
camel_cipher_validity_add_certinfo_ex (CamelCipherValidity *vin,
                                       CamelCipherValidityMode mode,
                                       const gchar *name,
                                       const gchar *email,
                                       gpointer cert_data,
                                       GDestroyNotify cert_data_free,
                                       CamelCipherCloneFunc cert_data_clone)
{
	CamelCipherCertInfo *info;
	GQueue *queue;

	g_return_val_if_fail (vin != NULL, -1);
	if (cert_data) {
		g_return_val_if_fail (cert_data_free != NULL, -1);
		g_return_val_if_fail (cert_data_clone != NULL, -1);
	}

	info = g_malloc0 (sizeof (*info));
	info->name = g_strdup (name);
	info->email = g_strdup (email);
	if (cert_data) {
		info->cert_data = cert_data;
		info->cert_data_free = cert_data_free;
		info->cert_data_clone = cert_data_clone;
	}

	if (mode == CAMEL_CIPHER_VALIDITY_SIGN)
		queue = &vin->sign.signers;
	else
		queue = &vin->encrypt.encrypters;

	g_queue_push_tail (queue, info);

	return (gint) (g_queue_get_length (queue) - 1);
}

/**
 * camel_cipher_validity_get_certinfo_property:
 * @vin: a #CamelCipherValidity
 * @mode: which cipher validity part to use
 * @info_index: a 0-based index of the requested #CamelCipherCertInfo
 * @name: a property name
 *
 * Gets a named property @name value for the given @info_index of the @mode validity part.
 *
 * Returns: (transfer none) (nullable): Value of a named property of a #CamelCipherCertInfo, or %NULL when no such
 *    property exists. The returned value is owned by the associated #CamelCipherCertInfo
 *    and is valid until the cert info is freed.
 *
 * Since: 3.22
 **/
gpointer
camel_cipher_validity_get_certinfo_property (CamelCipherValidity *vin,
					     CamelCipherValidityMode mode,
					     gint info_index,
					     const gchar *name)
{
	GQueue *queue;
	CamelCipherCertInfo *cert_info;

	g_return_val_if_fail (vin != NULL, NULL);
	g_return_val_if_fail (name != NULL, NULL);

	if (mode == CAMEL_CIPHER_VALIDITY_SIGN)
		queue = &vin->sign.signers;
	else
		queue = &vin->encrypt.encrypters;

	g_return_val_if_fail (info_index >= 0 && info_index < g_queue_get_length (queue), NULL);

	cert_info = g_queue_peek_nth (queue, info_index);

	g_return_val_if_fail (cert_info != NULL, NULL);

	return camel_cipher_certinfo_get_property (cert_info, name);
}

/**
 * camel_cipher_validity_set_certinfo_property:
 * @vin: a #CamelCipherValidity
 * @mode: which cipher validity part to use
 * @info_index: a 0-based index of the requested #CamelCipherCertInfo
 * @name: a property name
 * @value: (nullable) (destroy value_free): a property value, or %NULL
 * @value_free: (nullable): a free function for the @value
 * @value_clone: (nullable) (scope call): a clone function for the @value
 *
 * Sets a named property @name value @value for the given @info_index
 * of the @mode validity part. If the @value is %NULL, then the property
 * is removed. With a non-%NULL @value also @value_free and @value_clone
 * functions cannot be %NULL.
 *
 * Since: 3.22
 **/
void
camel_cipher_validity_set_certinfo_property (CamelCipherValidity *vin,
					     CamelCipherValidityMode mode,
					     gint info_index,
					     const gchar *name,
					     gpointer value,
					     GDestroyNotify value_free,
					     CamelCipherCloneFunc value_clone)
{
	GQueue *queue;
	CamelCipherCertInfo *cert_info;

	g_return_if_fail (vin != NULL);
	g_return_if_fail (name != NULL);

	if (mode == CAMEL_CIPHER_VALIDITY_SIGN)
		queue = &vin->sign.signers;
	else
		queue = &vin->encrypt.encrypters;

	g_return_if_fail (info_index >= 0 && info_index < g_queue_get_length (queue));

	cert_info = g_queue_peek_nth (queue, info_index);

	g_return_if_fail (cert_info != NULL);

	camel_cipher_certinfo_set_property (cert_info, name, value, value_free, value_clone);
}

/**
 * camel_cipher_validity_envelope:
 * @parent: a #CamelCipherValidity
 * @valid: a new #CamelCipherValidity to conglomerate the @parent with
 *
 * Calculate a conglomerate validity based on wrapping one secure part inside
 * another one.
 **/
void
camel_cipher_validity_envelope (CamelCipherValidity *parent,
                                CamelCipherValidity *valid)
{

	g_return_if_fail (parent != NULL);
	g_return_if_fail (valid != NULL);

	if (parent->sign.status != CAMEL_CIPHER_VALIDITY_SIGN_NONE
	    && parent->encrypt.status == CAMEL_CIPHER_VALIDITY_ENCRYPT_NONE
	    && valid->sign.status == CAMEL_CIPHER_VALIDITY_SIGN_NONE
	    && valid->encrypt.status != CAMEL_CIPHER_VALIDITY_ENCRYPT_NONE) {
		GList *head, *link;

		/* case 1: only signed inside only encrypted -> merge both */
		parent->encrypt.status = valid->encrypt.status;
		parent->encrypt.description = g_strdup (valid->encrypt.description);

		head = g_queue_peek_head_link (&valid->encrypt.encrypters);
		for (link = head; link != NULL; link = g_list_next (link)) {
			CamelCipherCertInfo *info = link->data;
			camel_cipher_validity_add_certinfo (
				parent, CAMEL_CIPHER_VALIDITY_ENCRYPT,
				info->name, info->email);
		}
	} else if (parent->sign.status == CAMEL_CIPHER_VALIDITY_SIGN_NONE
		   && parent->encrypt.status != CAMEL_CIPHER_VALIDITY_ENCRYPT_NONE
		   && valid->sign.status != CAMEL_CIPHER_VALIDITY_SIGN_NONE
		   && valid->encrypt.status == CAMEL_CIPHER_VALIDITY_ENCRYPT_NONE) {
		GList *head, *link;

		/* case 2: only encrypted inside only signed */
		parent->sign.status = valid->sign.status;
		parent->sign.description = g_strdup (valid->sign.description);

		head = g_queue_peek_head_link (&valid->sign.signers);
		for (link = head; link != NULL; link = g_list_next (link)) {
			CamelCipherCertInfo *info = link->data;
			camel_cipher_validity_add_certinfo (
				parent, CAMEL_CIPHER_VALIDITY_SIGN,
				info->name, info->email);
		}
	}
	/* Otherwise, I dunno - what do you do? */
}

void
camel_cipher_validity_free (CamelCipherValidity *validity)
{
	CamelCipherValidity *child;
	CamelCipherCertInfo *info;
	GQueue *queue;

	if (validity == NULL)
		return;

	queue = &validity->children;
	while ((child = g_queue_pop_head (queue)) != NULL)
		camel_cipher_validity_free (child);

	queue = &validity->sign.signers;
	while ((info = g_queue_pop_head (queue)) != NULL)
		ccv_certinfo_free (info);

	queue = &validity->encrypt.encrypters;
	while ((info = g_queue_pop_head (queue)) != NULL)
		ccv_certinfo_free (info);

	camel_cipher_validity_clear (validity);
	g_free (validity);
}

/* ********************************************************************** */

/**
 * camel_cipher_certinfo_get_property:
 * @cert_info: a #CamelCipherCertInfo
 * @name: a property name
 *
 * Gets a named property @name value for the given @cert_info.
 *
 * Returns: (transfer none) (nullable): Value of a named property of the @cert_info,
 *    or %NULL when no such property exists. The returned value is owned by
 *    the @cert_info and is valid until the @cert_info is freed.
 *
 * Since: 3.22
 **/
gpointer
camel_cipher_certinfo_get_property (CamelCipherCertInfo *cert_info,
				    const gchar *name)
{
	GSList *link;

	g_return_val_if_fail (cert_info != NULL, NULL);
	g_return_val_if_fail (name != NULL, NULL);

	for (link = cert_info->properties; link; link = g_slist_next (link)) {
		CamelCipherCertInfoProperty *property = link->data;

		if (property && g_ascii_strcasecmp (property->name, name) == 0)
			return property->value;
	}

	return NULL;
}

/**
 * camel_cipher_certinfo_set_property:
 * @cert_info: a #CamelCipherCertInfo
 * @name: a property name
 * @value: (nullable) (destroy value_free): a property value, or %NULL
 * @value_free: (nullable): a free function for the @value
 * @value_clone: (nullable) (scope call): a clone function for the @value
 *
 * Sets a named property @name value @value for the given @cert_info.
 * If the @value is %NULL, then the property is removed. With a non-%NULL
 * @value also @value_free and @value_clone functions cannot be %NULL.
 *
 * Since: 3.22
 **/
void
camel_cipher_certinfo_set_property (CamelCipherCertInfo *cert_info,
				    const gchar *name,
				    gpointer value,
				    GDestroyNotify value_free,
				    CamelCipherCloneFunc value_clone)
{
	CamelCipherCertInfoProperty *property;
	GSList *link;

	g_return_if_fail (cert_info != NULL);
	g_return_if_fail (name != NULL);

	if (value) {
		g_return_if_fail (value_free != NULL);
		g_return_if_fail (value_clone != NULL);
	}

	for (link = cert_info->properties; link; link = g_slist_next (link)) {
		property = link->data;

		if (property && g_ascii_strcasecmp (property->name, name) == 0) {
			if (value && property->value != value) {
				/* Replace current value with the new value. */
				property->value_free (property->value);

				property->value = value;
				property->value_free = value_free;
				property->value_clone = value_clone;
			} else if (!value) {
				cert_info->properties = g_slist_remove (cert_info->properties, property);
				ccv_certinfo_property_free (property);
			}
			break;
		}
	}

	if (value && !link) {
		property = g_new0 (CamelCipherCertInfoProperty, 1);
		property->name = g_strdup (name);
		property->value = value;
		property->value_free = value_free;
		property->value_clone = value_clone;

		cert_info->properties = g_slist_prepend (cert_info->properties, property);
	}
}

/* ********************************************************************** */

/**
 * camel_cipher_context_new:
 * @session: a #CamelSession
 *
 * This creates a new CamelCipherContext object which is used to sign,
 * verify, encrypt and decrypt streams.
 *
 * Returns: the new CamelCipherContext
 **/
CamelCipherContext *
camel_cipher_context_new (CamelSession *session)
{
	g_return_val_if_fail (session != NULL, NULL);

	return g_object_new (
		CAMEL_TYPE_CIPHER_CONTEXT,
		"session", session, NULL);
}

/**
 * camel_cipher_context_get_session:
 * @context: a #CamelCipherContext
 *
 * Returns: (transfer none):
 *
 * Since: 2.32
 **/
CamelSession *
camel_cipher_context_get_session (CamelCipherContext *context)
{
	g_return_val_if_fail (CAMEL_IS_CIPHER_CONTEXT (context), NULL);

	return context->priv->session;
}

/* See rfc3156, section 2 and others */
/* We do this simply: Anything not base64 must be qp
 * This is so that we can safely translate any occurance of "From "
 * into the quoted-printable escaped version safely. */
static void
cc_prepare_sign (CamelMimePart *part)
{
	CamelDataWrapper *dw;
	CamelTransferEncoding encoding;
	gint parts, i;

	dw = camel_medium_get_content ((CamelMedium *) part);
	if (!dw)
		return;

	/* should not change encoding for these, they have the right encoding set already */
	if (CAMEL_IS_MULTIPART_SIGNED (dw) || CAMEL_IS_MULTIPART_ENCRYPTED (dw))
		return;

	if (CAMEL_IS_MULTIPART (dw)) {
		parts = camel_multipart_get_number ((CamelMultipart *) dw);
		for (i = 0; i < parts; i++)
			cc_prepare_sign (camel_multipart_get_part ((CamelMultipart *) dw, i));
	} else if (CAMEL_IS_MIME_MESSAGE (dw)) {
		cc_prepare_sign ((CamelMimePart *) dw);
	} else {
		encoding = camel_mime_part_get_encoding (part);

		if (encoding != CAMEL_TRANSFER_ENCODING_BASE64
		    && encoding != CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE) {
			camel_mime_part_set_encoding (part, CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE);
		}
	}
}

/**
 * camel_cipher_canonical_to_stream:
 * @part: Part to write.
 * @flags: flags for the canonicalisation filter (CamelMimeFilterCanon)
 * @ostream: stream to write canonicalised output to.
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Writes a part to a stream in a canonicalised format, suitable for signing/encrypting.
 *
 * The transfer encoding paramaters for the part may be changed by this function.
 *
 * Returns: -1 on error;
 **/
gint
camel_cipher_canonical_to_stream (CamelMimePart *part,
                                  guint32 flags,
                                  CamelStream *ostream,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelStream *filter;
	CamelMimeFilter *canon;
	gint res = -1;

	g_return_val_if_fail (CAMEL_IS_MIME_PART (part), -1);
	g_return_val_if_fail (CAMEL_IS_STREAM (ostream), -1);

	if (flags & (CAMEL_MIME_FILTER_CANON_FROM | CAMEL_MIME_FILTER_CANON_STRIP))
		cc_prepare_sign (part);

	filter = camel_stream_filter_new (ostream);
	canon = camel_mime_filter_canon_new (flags);
	camel_stream_filter_add (CAMEL_STREAM_FILTER (filter), canon);
	g_object_unref (canon);

	if (camel_data_wrapper_write_to_stream_sync (
		CAMEL_DATA_WRAPPER (part), filter, cancellable, error) != -1
	    && camel_stream_flush (filter, cancellable, error) != -1)
		res = 0;

	g_object_unref (filter);

	/* Reset stream position to beginning. */
	if (G_IS_SEEKABLE (ostream))
		g_seekable_seek (
			G_SEEKABLE (ostream), 0,
			G_SEEK_SET, NULL, NULL);

	return res;
}

/**
 * camel_cipher_can_load_photos:
 *
 * Returns: Whether ciphers can load photos, as being setup by the user.
 *
 * Since: 3.22
 **/
gboolean
camel_cipher_can_load_photos (void)
{
	GSettings *settings;
	gboolean load_photos;

	settings = g_settings_new ("org.gnome.evolution-data-server");
	load_photos = g_settings_get_boolean (settings, "camel-cipher-load-photos");
	g_clear_object (&settings);

	return load_photos;
}
