/*
 * e-source-mail-signature.c
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

/**
 * SECTION: e-source-mail-signature
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for email signatures
 *
 * The #ESourceMailSignature extension refers to a personalized email
 * signature.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceMailSignature *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_MAIL_SIGNATURE);
 * ]|
 **/

#include "evolution-data-server-config.h"

#include <string.h>
#include <glib/gi18n-lib.h>

#include <libedataserver/e-data-server-util.h>

#include "e-source-mail-signature.h"

#define E_SOURCE_MAIL_SIGNATURE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_MAIL_SIGNATURE, ESourceMailSignaturePrivate))

typedef struct _AsyncContext AsyncContext;

struct _ESourceMailSignaturePrivate {
	GFile *file;
	gchar *mime_type;
};

struct _AsyncContext {
	gchar *contents;
	gchar *symlink_target;
	gsize length;
};

enum {
	PROP_0,
	PROP_FILE,
	PROP_MIME_TYPE
};

G_DEFINE_TYPE (
	ESourceMailSignature,
	e_source_mail_signature,
	E_TYPE_SOURCE_EXTENSION)

static void
async_context_free (AsyncContext *async_context)
{
	g_free (async_context->contents);
	g_free (async_context->symlink_target);

	g_slice_free (AsyncContext, async_context);
}

static void
source_mail_signature_set_property (GObject *object,
                                    guint property_id,
                                    const GValue *value,
                                    GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_MIME_TYPE:
			e_source_mail_signature_set_mime_type (
				E_SOURCE_MAIL_SIGNATURE (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_mail_signature_get_property (GObject *object,
                                    guint property_id,
                                    GValue *value,
                                    GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_FILE:
			g_value_set_object (
				value,
				e_source_mail_signature_get_file (
				E_SOURCE_MAIL_SIGNATURE (object)));
			return;

		case PROP_MIME_TYPE:
			g_value_take_string (
				value,
				e_source_mail_signature_dup_mime_type (
				E_SOURCE_MAIL_SIGNATURE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_mail_signature_dispose (GObject *object)
{
	ESourceMailSignaturePrivate *priv;

	priv = E_SOURCE_MAIL_SIGNATURE_GET_PRIVATE (object);

	if (priv->file != NULL) {
		g_object_unref (priv->file);
		priv->file = NULL;
	}

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_source_mail_signature_parent_class)->
		dispose (object);
}

static void
source_mail_signature_finalize (GObject *object)
{
	ESourceMailSignaturePrivate *priv;

	priv = E_SOURCE_MAIL_SIGNATURE_GET_PRIVATE (object);

	g_free (priv->mime_type);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_mail_signature_parent_class)->
		finalize (object);
}

static void
source_mail_signature_constructed (GObject *object)
{
	ESourceMailSignaturePrivate *priv;
	ESourceExtension *extension;
	ESource *source;
	const gchar *config_dir;
	const gchar *uid;
	gchar *base_dir;
	gchar *path;

	priv = E_SOURCE_MAIL_SIGNATURE_GET_PRIVATE (object);

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_source_mail_signature_parent_class)->constructed (object);

	extension = E_SOURCE_EXTENSION (object);
	source = e_source_extension_ref_source (extension);
	uid = e_source_get_uid (source);

	config_dir = e_get_user_config_dir ();
	base_dir = g_build_filename (config_dir, "signatures", NULL);
	path = g_build_filename (base_dir, uid, NULL);
	priv->file = g_file_new_for_path (path);
	g_mkdir_with_parents (base_dir, 0700);
	g_free (base_dir);
	g_free (path);

	g_object_unref (source);
}

static void
e_source_mail_signature_class_init (ESourceMailSignatureClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (
		class, sizeof (ESourceMailSignaturePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_mail_signature_set_property;
	object_class->get_property = source_mail_signature_get_property;
	object_class->dispose = source_mail_signature_dispose;
	object_class->finalize = source_mail_signature_finalize;
	object_class->constructed = source_mail_signature_constructed;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_MAIL_SIGNATURE;

	g_object_class_install_property (
		object_class,
		PROP_FILE,
		g_param_spec_object (
			"file",
			"File",
			"File containing signature content",
			G_TYPE_FILE,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_MIME_TYPE,
		g_param_spec_string (
			"mime-type",
			"MIME Type",
			"MIME type of the signature content",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_mail_signature_init (ESourceMailSignature *extension)
{
	extension->priv = E_SOURCE_MAIL_SIGNATURE_GET_PRIVATE (extension);
}

/**
 * e_source_mail_signature_get_file:
 * @extension: an #ESourceMailSignature
 *
 * Returns a #GFile instance pointing to the signature file for @extension.
 * The signature file may be a regular file containing the static signature
 * content, or it may be a symbolic link to an executable file that produces
 * the signature content.
 *
 * e_source_mail_signature_load() uses this to load the signature content.
 *
 * Returns: (transfer none): a #GFile
 *
 * Since: 3.6
 **/
GFile *
e_source_mail_signature_get_file (ESourceMailSignature *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_SIGNATURE (extension), NULL);

	return extension->priv->file;
}

/**
 * e_source_mail_signature_get_mime_type:
 * @extension: an #ESourceMailSignature
 *
 * Returns the MIME type of the signature content for @extension, or %NULL
 * if it has not yet been determined.
 *
 * e_source_mail_signature_load() sets this automatically if the MIME type
 * has not yet been determined.
 *
 * Returns: (nullable): the MIME type of the signature content, or %NULL
 *
 * Since: 3.6
 **/
const gchar *
e_source_mail_signature_get_mime_type (ESourceMailSignature *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_SIGNATURE (extension), NULL);

	return extension->priv->mime_type;
}

/**
 * e_source_mail_signature_dup_mime_type:
 * @extension: an #ESourceMailSignature
 *
 * Thread-safe variation of e_source_mail_signature_get_mime_type().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: (nullable): a newly-allocated copy of #ESourceMailSignature:mime-type,
 *    or %NULL
 *
 * Since: 3.6
 **/
gchar *
e_source_mail_signature_dup_mime_type (ESourceMailSignature *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_SIGNATURE (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_mail_signature_get_mime_type (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_mail_signature_set_mime_type:
 * @extension: an #ESourceMailSignature
 * @mime_type: (allow-none): a MIME type, or %NULL
 *
 * Sets the MIME type of the signature content for @extension.
 *
 * e_source_mail_signature_load() sets this automatically if the MIME type
 * has not yet been determined.
 *
 * The internal copy of @mime_type is automatically stripped of leading
 * and trailing whitespace.  If the resulting string is empty, %NULL is
 * set instead.
 *
 * Since: 3.6
 **/
void
e_source_mail_signature_set_mime_type (ESourceMailSignature *extension,
                                       const gchar *mime_type)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_SIGNATURE (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->mime_type, mime_type) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->mime_type);
	extension->priv->mime_type = e_util_strdup_strip (mime_type);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "mime-type");
}

/********************** e_source_mail_signature_load() ***********************/

/* Helper for e_source_mail_signature_load() */
static void
source_mail_signature_load_thread (GSimpleAsyncResult *simple,
                                   GObject *object,
                                   GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	e_source_mail_signature_load_sync (
		E_SOURCE (object),
		&async_context->contents,
		&async_context->length,
		cancellable, &error);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);
}

/**
 * e_source_mail_signature_load_sync:
 * @source: an #ESource
 * @contents: (out): return location for the signature content
 * @length: (allow-none) (out): return location for the length of the signature
 *          content, or %NULL if the length is not needed
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Loads a signature from the signature file for @source, which is
 * given by e_source_mail_signature_get_file().  The signature contents
 * are placed in @contents, and @length is set to the size of the @contents
 * string.  The @contents string should be freed with g_free() when no
 * longer needed.
 *
 * If the signature file is executable, it will be executed and its output
 * captured as the email signature content.  If the signature file is not
 * executable, the email signature content is read directly from the file.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
e_source_mail_signature_load_sync (ESource *source,
                                   gchar **contents,
                                   gsize *length,
                                   GCancellable *cancellable,
                                   GError **error)
{
	ESourceMailSignature *extension;
	GFileInfo *file_info;
	GFile *file;
	const gchar *content_type;
	const gchar *extension_name;
	gchar *local_contents = NULL;
	gboolean can_execute;
	gboolean success;
	gchar *guessed_content_type;
	gchar *command_line;
	gchar *mime_type;
	gchar *path;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (contents != NULL, FALSE);

	extension_name = E_SOURCE_EXTENSION_MAIL_SIGNATURE;
	extension = e_source_get_extension (source, extension_name);
	file = e_source_mail_signature_get_file (extension);

	file_info = g_file_query_info (
		file,
		G_FILE_ATTRIBUTE_ACCESS_CAN_EXECUTE ","
		G_FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE,
		G_FILE_QUERY_INFO_NONE,
		cancellable, error);

	if (file_info == NULL)
		return FALSE;

	can_execute = g_file_info_get_attribute_boolean (
		file_info, G_FILE_ATTRIBUTE_ACCESS_CAN_EXECUTE);

	content_type = g_file_info_get_content_type (file_info);
	mime_type = g_content_type_get_mime_type (content_type);

	if (can_execute)
		goto execute;

	/*** Load signature file contents ***/

	success = g_file_load_contents (
		file, cancellable, &local_contents, NULL, NULL, error);

	if (!success)
		goto exit;

	g_return_val_if_fail (local_contents != NULL, FALSE);

	/* Signatures are saved as UTF-8, but we still need to check that
	 * the signature is valid UTF-8 because the user may be opening a
	 * signature file this is in his/her locale character set.  If it
	 * is not UTF-8 then try converting from the current locale. */
	if (!g_utf8_validate (local_contents, -1, NULL)) {
		gchar *utf8;

		utf8 = g_locale_to_utf8 (
			local_contents, -1, NULL, NULL, error);

		if (utf8 == NULL) {
			success = FALSE;
			goto exit;
		}

		g_free (local_contents);
		local_contents = utf8;
	}

	goto exit;

execute:

	/*** Execute signature file and capture output ***/

	path = g_file_get_path (file);

	if (path == NULL) {
		g_set_error (
			error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED,
			_("Signature script must be a local file"));
		success = FALSE;
		goto exit;
	}

	/* Enclose the path in single-quotes for compatibility on Windows.
	 * (See g_spawn_command_line_sync() documentation for rationale.) */
	command_line = g_strdup_printf ("'%s'", path);

	success = g_spawn_command_line_sync (
		command_line, &local_contents, NULL, NULL, error);

	g_free (command_line);
	g_free (path);

	/* Check if we failed to spawn the script. */
	if (!success)
		goto exit;

	/* Check if we were cancelled while the script was running. */
	if (g_cancellable_set_error_if_cancelled (cancellable, error)) {
		success = FALSE;
		goto exit;
	}

	g_return_val_if_fail (local_contents != NULL, FALSE);

	/* Signature scripts are supposed to generate UTF-8 content, but
	 * because users are known to never read the manual, we try to do
	 * our best if the content isn't valid UTF-8 by assuming that the
	 * content is in the user's locale character set. */
	if (!g_utf8_validate (local_contents, -1, NULL)) {
		gchar *utf8;

		utf8 = g_locale_to_utf8 (
			local_contents, -1, NULL, NULL, error);

		if (utf8 == NULL) {
			success = FALSE;
			goto exit;
		}

		g_free (local_contents);
		local_contents = utf8;
	}

	g_free (mime_type);

	/* Try and guess the content type of the script output
	 * so it can be applied correctly to the mail message. */
	guessed_content_type = g_content_type_guess (
		NULL, (guchar *) local_contents,
		strlen (local_contents), NULL);
	mime_type = g_content_type_get_mime_type (guessed_content_type);
	g_free (guessed_content_type);

exit:
	if (success) {
		const gchar *ext_mime_type;

		if (length != NULL)
			*length = strlen (local_contents);

		*contents = local_contents;
		local_contents = NULL;

		ext_mime_type =
			e_source_mail_signature_get_mime_type (extension);

		/* Don't override the MIME type if it's already set. */
		if (ext_mime_type == NULL || *ext_mime_type == '\0')
			e_source_mail_signature_set_mime_type (
				extension, mime_type);
	}

	g_object_unref (file_info);
	g_free (local_contents);
	g_free (mime_type);

	return success;
}

/**
 * e_source_mail_signature_load:
 * @source: an #ESource
 * @io_priority: the I/O priority of the request
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously loads a signature from the signature file for @source,
 * which is given by e_source_mail_signature_get_file().
 *
 * If the signature file is executable, it will be executed and its output
 * captured as the email signature content.  If the signature file is not
 * executable, the email signature content is read directly from the file.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call e_source_mail_signature_load_finish() to get the result of
 * the operation.
 *
 * Since: 3.6
 **/
void
e_source_mail_signature_load (ESource *source,
                              gint io_priority,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_SOURCE (source));

	async_context = g_slice_new0 (AsyncContext);

	simple = g_simple_async_result_new (
		G_OBJECT (source), callback, user_data,
		e_source_mail_signature_load);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, source_mail_signature_load_thread,
		io_priority, cancellable);

	g_object_unref (simple);
}

/**
 * e_source_mail_signature_load_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @contents: (out): return location for the signature content
 * @length: (allow-none) (out): return location for the length of the signature
 *          content, or %NULL if the length is not needed
 * @error: return location for a #GError, or %NULL
 *
 * Finishes an operation started with e_source_mail_signature_load().  The
 * signature file contents are placed in @contents, and @length is set to
 * the size of the @contents string.  The @contents string should be freed
 * with g_free() when no longer needed.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
e_source_mail_signature_load_finish (ESource *source,
                                     GAsyncResult *result,
                                     gchar **contents,
                                     gsize *length,
                                     GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (source),
		e_source_mail_signature_load), FALSE);

	g_return_val_if_fail (contents != NULL, FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	g_return_val_if_fail (async_context->contents != NULL, FALSE);

	*contents = async_context->contents;
	async_context->contents = NULL;

	if (length != NULL)
		*length = async_context->length;

	return TRUE;
}

/********************* e_source_mail_signature_replace() *********************/

/* Helper for e_source_mail_signature_replace() */
static void
source_mail_signature_replace_thread (GSimpleAsyncResult *simple,
                                      GObject *object,
                                      GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	e_source_mail_signature_replace_sync (
		E_SOURCE (object), async_context->contents,
		async_context->length, cancellable, &error);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);
}

/**
 * e_source_mail_signature_replace_sync:
 * @source: an #ESource
 * @contents: the signature contents
 * @length: the length of @contents in bytes
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Replaces the signature file for @source with the given @contents
 * of @length bytes.  The signature file for @source is given by
 * e_source_mail_signature_get_file().
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
e_source_mail_signature_replace_sync (ESource *source,
                                      const gchar *contents,
                                      gsize length,
                                      GCancellable *cancellable,
                                      GError **error)
{
	ESourceMailSignature *extension;
	const gchar *extension_name;
	GFile *file;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (contents != NULL, FALSE);

	extension_name = E_SOURCE_EXTENSION_MAIL_SIGNATURE;
	extension = e_source_get_extension (source, extension_name);
	file = e_source_mail_signature_get_file (extension);

	return g_file_replace_contents (
		file, contents, length, NULL, FALSE,
		G_FILE_CREATE_REPLACE_DESTINATION,
		NULL, cancellable, error);
}

/**
 * e_source_mail_signature_replace:
 * @source: an #ESource
 * @contents: the signature contents
 * @length: the length of @contents in bytes
 * @io_priority: the I/O priority of the request
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchrously replaces the signature file for @source with the given
 * @contents of @length bytes.  The signature file for @source is given
 * by e_source_mail_signature_get_file().
 *
 * When the operation is finished, @callback will be called.  You can
 * then call e_source_mail_signature_replace_finish() to get the result
 * of the operation.
 *
 * Since: 3.6
 **/
void
e_source_mail_signature_replace (ESource *source,
                                 const gchar *contents,
                                 gsize length,
                                 gint io_priority,
                                 GCancellable *cancellable,
                                 GAsyncReadyCallback callback,
                                 gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (contents != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->contents = g_strdup (contents);
	async_context->length = length;

	simple = g_simple_async_result_new (
		G_OBJECT (source), callback, user_data,
		e_source_mail_signature_replace);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, source_mail_signature_replace_thread,
		io_priority, cancellable);

	g_object_unref (simple);
}

/**
 * e_source_mail_signature_replace_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes an operation started with e_source_mail_signature_replace().
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
e_source_mail_signature_replace_finish (ESource *source,
                                        GAsyncResult *result,
                                        GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (source),
		e_source_mail_signature_replace), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/********************* e_source_mail_signature_symlink() *********************/

/* Helper for e_source_mail_signature_symlink() */
static void
source_mail_signature_symlink_thread (GSimpleAsyncResult *simple,
                                      GObject *object,
                                      GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	e_source_mail_signature_symlink_sync (
		E_SOURCE (object),
		async_context->symlink_target,
		cancellable, &error);

	if (error != NULL)
		g_simple_async_result_take_error (simple, error);
}

/**
 * e_source_mail_signature_symlink_sync:
 * @source: an #ESource
 * @symlink_target: executable filename to link to
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Replaces the signature file for @source with a symbolic link to
 * @symlink_target, which should be an executable file that prints
 * a mail signature to standard output.  The signature file for
 * @source is given by e_source_mail_signature_get_file().
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
e_source_mail_signature_symlink_sync (ESource *source,
                                      const gchar *symlink_target,
                                      GCancellable *cancellable,
                                      GError **error)
{
	ESourceMailSignature *extension;
	const gchar *extension_name;
	GFile *file;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (symlink_target != NULL, FALSE);

	extension_name = E_SOURCE_EXTENSION_MAIL_SIGNATURE;
	extension = e_source_get_extension (source, extension_name);
	file = e_source_mail_signature_get_file (extension);

	/* The file may not exist, so we don't care if this fails.
	 * If it fails for a different reason than G_IO_ERROR_NOT_FOUND
	 * then the next step will probably also fail and we'll capture
	 * THAT error. */
	g_file_delete (file, cancellable, NULL);

	return g_file_make_symbolic_link (
		file, symlink_target, cancellable, error);
}

/**
 * e_source_mail_signature_symlink:
 * @source: an #ESource
 * @symlink_target: executable filename to link to
 * @io_priority: the I/O priority of the request
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously replaces the signature file for @source with a symbolic
 * link to @symlink_target, which should be an executable file that prints
 * a mail signature to standard output.  The signature file for @source
 * is given by e_source_mail_signature_get_file().
 *
 * When the operation is finished, @callback will be called.  You can
 * then call e_source_mail_signature_symlink_finish() to get the result
 * of the operation.
 *
 * Since: 3.6
 **/
void
e_source_mail_signature_symlink (ESource *source,
                                 const gchar *symlink_target,
                                 gint io_priority,
                                 GCancellable *cancellable,
                                 GAsyncReadyCallback callback,
                                 gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (symlink_target != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->symlink_target = g_strdup (symlink_target);

	simple = g_simple_async_result_new (
		G_OBJECT (source), callback, user_data,
		e_source_mail_signature_symlink);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, source_mail_signature_symlink_thread,
		io_priority, cancellable);

	g_object_unref (simple);
}

/**
 * e_source_mail_signature_symlink_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes an operation started with e_source_mail_signature_symlink().
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.6
 **/
gboolean
e_source_mail_signature_symlink_finish (ESource *source,
                                        GAsyncResult *result,
                                        GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (source),
		e_source_mail_signature_symlink), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

