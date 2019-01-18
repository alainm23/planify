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

/**
 * SECTION: e-secret-store
 * @include: libedataserver/libedataserver.h
 * @short_description: Interface to store secrets
 *
 * The e-secret-store API provides an interface to store,
 * lookup and delete secrets from the keyring.
 **/

#include "evolution-data-server-config.h"

#include <glib.h>

#ifdef G_OS_WIN32
#include <string.h>
#include <errno.h>
#else
#include <libsecret/secret.h>
#endif

#include "e-data-server-util.h"
#include "e-secret-store.h"

#ifdef G_OS_WIN32

G_LOCK_DEFINE_STATIC (secrets_file);
static GHashTable *session_secrets = NULL;
#define SECRETS_SECTION "Secrets"

static gchar *
encode_secret (const gchar *secret)
{
	return g_base64_encode ((const guchar *) secret, strlen (secret));
}

static gchar *
decode_secret (const gchar *secret)
{
	guchar *decoded;
	gchar *tmp;
	gsize len = 0;

	decoded = g_base64_decode (secret, &len);
	if (!decoded || !len) {
		g_free (decoded);
		return NULL;
	}

	tmp = g_strndup ((const gchar *) decoded, len);
	g_free (decoded);

	return tmp;
}

static gchar *
get_secrets_filename (void)
{
	return g_build_filename (e_get_user_config_dir (), "secrets", NULL);
}

static GKeyFile *
read_secrets_file (GError **error)
{
	gchar *filename;
	GKeyFile *secrets;

	secrets = g_key_file_new ();

	filename = get_secrets_filename ();

	if (g_file_test (filename, G_FILE_TEST_EXISTS | G_FILE_TEST_IS_REGULAR)) {
		if (!g_key_file_load_from_file (secrets, filename, G_KEY_FILE_NONE, error)) {
			g_key_file_free (secrets);
			secrets = NULL;
		}
	}

	g_free (filename);

	return secrets;
}

static gboolean
store_secrets_file (GKeyFile *secrets,
		    GError **error)
{
	gchar *content, *filename;
	gsize length;
	gboolean success;

	g_return_val_if_fail (secrets != NULL, FALSE);

	if (!g_file_test (e_get_user_config_dir (), G_FILE_TEST_EXISTS | G_FILE_TEST_IS_DIR)) {
		if (g_mkdir_with_parents (e_get_user_config_dir (), 0700) == -1) {
			g_set_error_literal (
				error, G_FILE_ERROR,
				g_file_error_from_errno (errno),
				g_strerror (errno));
			return FALSE;
		}
	}

	content = g_key_file_to_data (secrets, &length, error);
	if (!content)
		return FALSE;


	filename = get_secrets_filename ();

	success = g_file_set_contents (filename, content, length, error);

	g_free (filename);
	g_free (content);

	return success;
}

static gboolean
e_win32_secret_store_secret_sync (const gchar *uid,
				  const gchar *secret,
				  gboolean permanently,
				  GError **error)
{
	GKeyFile *secrets;
	gboolean success;

	g_return_val_if_fail (uid != NULL, FALSE);

	G_LOCK (secrets_file);

	if (permanently) {
		secrets = read_secrets_file (error);
		success = secrets != NULL;

		if (secrets) {
			gchar *encoded;

			encoded = secret && *secret ? encode_secret (secret) : g_strdup (secret);

			g_key_file_set_string (secrets, SECRETS_SECTION, uid, encoded);

			success = store_secrets_file (secrets, error);

			g_key_file_free (secrets);
			g_free (encoded);
		}
	} else {
		gchar *encoded;

		if (!session_secrets)
			session_secrets = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, (GDestroyNotify) e_util_safe_free_string);

		encoded = secret && *secret ? encode_secret (secret) : g_strdup (secret);
		if (!encoded)
			g_hash_table_remove (session_secrets, uid);
		else
			g_hash_table_insert (session_secrets, g_strdup (uid), encoded);
	}

	G_UNLOCK (secrets_file);

	return success;
}

static gchar *
e_win32_secret_lookup_secret_sync (const gchar *uid,
				   GError **error)
{
	GKeyFile *secrets;
	gchar *secret = NULL;

	g_return_val_if_fail (uid != NULL, NULL);

	G_LOCK (secrets_file);

	if (session_secrets) {
		const gchar *encoded;

		encoded = g_hash_table_lookup (session_secrets, uid);
		if (encoded)
			secret = decode_secret (encoded);
	}

	if (!secret) {
		secrets = read_secrets_file (error);
		if (secrets) {
			gchar *tmp;

			tmp = g_key_file_get_string (secrets, SECRETS_SECTION, uid, NULL);
			if (tmp) {
				secret = *tmp ? decode_secret (tmp) : g_strdup ("");
				g_free (tmp);
			}

			g_key_file_free (secrets);
		}
	}

	G_UNLOCK (secrets_file);

	return secret;
}

static gboolean
e_win32_secret_delete_secret_sync (const gchar *uid,
				   GError **error)
{
	GKeyFile *secrets;
	gboolean success = FALSE;

	g_return_val_if_fail (uid != NULL, FALSE);

	G_LOCK (secrets_file);

	if (session_secrets) {
		success = g_hash_table_remove (session_secrets, uid);
	}

	secrets = read_secrets_file (error);
	if (secrets) {
		success = TRUE;

		if (g_key_file_remove_key (secrets, SECRETS_SECTION, uid, NULL)) {
			success = store_secrets_file (secrets, error);
		}

		g_key_file_free (secrets);
	}

	G_UNLOCK (secrets_file);

	return success;
}

#else /* G_OS_WIN32 */

#define KEYRING_ITEM_ATTRIBUTE_UID	"e-source-uid"
#define KEYRING_ITEM_ATTRIBUTE_ORIGIN	"eds-origin"

#ifdef DBUS_SERVICES_PREFIX
#define ORIGIN_KEY DBUS_SERVICES_PREFIX "." PACKAGE
#else
#define ORIGIN_KEY PACKAGE
#endif

static SecretSchema password_schema = {
	"org.gnome.Evolution.Data.Source",
	SECRET_SCHEMA_DONT_MATCH_NAME,
	{
		{ KEYRING_ITEM_ATTRIBUTE_UID, SECRET_SCHEMA_ATTRIBUTE_STRING },
		{ KEYRING_ITEM_ATTRIBUTE_ORIGIN, SECRET_SCHEMA_ATTRIBUTE_STRING },
		{ NULL, 0 }
	}
};

#endif /* G_OS_WIN32 */

/**
 * e_secret_store_store_sync:
 * @uid: a unique identifier of the secret
 * @secret: the secret to store
 * @label: human readable description of the secret
 * @permanently: store permanently or just for the session
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Stores the @secret for the @uid.
 *
 * If @permanently is %TRUE, the secret is stored in the default keyring.
 * Otherwise the secret is stored in the memory-only session keyring. If
 * an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.18
 **/
gboolean
e_secret_store_store_sync (const gchar *uid,
			   const gchar *secret,
			   const gchar *label,
			   gboolean permanently,
			   GCancellable *cancellable,
			   GError **error)
{
	gboolean success;
#ifndef G_OS_WIN32
	const gchar *collection;
#endif

	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (secret != NULL, FALSE);

#ifndef G_OS_WIN32
	if (permanently)
		collection = SECRET_COLLECTION_DEFAULT;
	else
		collection = SECRET_COLLECTION_SESSION;
#endif

#ifdef G_OS_WIN32
	success = e_win32_secret_store_secret_sync (uid, secret, permanently, error);
#else
	success = secret_password_store_sync (
		&password_schema,
		collection, label, secret,
		cancellable, error,
		KEYRING_ITEM_ATTRIBUTE_UID, uid,
		KEYRING_ITEM_ATTRIBUTE_ORIGIN, ORIGIN_KEY,
		NULL);
#endif

	return success;
}

/**
 * e_secret_store_lookup_sync:
 * @uid: a unique identifier of the secret
 * @out_secret: (out): return location for the secret, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Looks up a secret for the @uid. Both the default and session keyrings
 * are queried.
 *
 * Note the boolean return value indicates whether the lookup operation
 * itself completed successfully, not whether the secret was found. If
 * no secret was found, the function will set @out_secret to %NULL,
 * but still return %TRUE. If an error occurs, the function sets @error
 * and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.18
 **/
gboolean
e_secret_store_lookup_sync (const gchar *uid,
			    gchar **out_secret,
			    GCancellable *cancellable,
			    GError **error)
{
	gchar *temp = NULL;
	gboolean success = TRUE;
	GError *local_error = NULL;

	g_return_val_if_fail (uid != NULL, FALSE);

#ifdef G_OS_WIN32
	temp = e_win32_secret_lookup_secret_sync (uid, &local_error);
#else
	temp = secret_password_lookup_sync (
		&password_schema,
		cancellable, &local_error,
		KEYRING_ITEM_ATTRIBUTE_UID, uid,
		NULL);
#endif

	if (local_error != NULL) {
		g_warn_if_fail (temp == NULL);
		g_propagate_error (error, local_error);
		success = FALSE;
	} else if (out_secret != NULL) {
		*out_secret = temp;  /* takes ownership */
	} else {
		e_util_safe_free_string (temp);
	}

	return success;
}

/**
 * e_secret_store_delete_sync:
 * @uid: a unique identifier of the secret
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Deletes the secret for @uid from either the default keyring or
 * session keyring.
 *
 * Note the boolean return value indicates whether the delete operation
 * itself completed successfully, not whether the secret was found and
 * deleted. If no such secret was found, the function will still return
 * %TRUE. If an error occurs, the function sets @error and returns %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on error
 *
 * Since: 3.18
 **/
gboolean
e_secret_store_delete_sync (const gchar *uid,
			    GCancellable *cancellable,
			    GError **error)
{
	gboolean success = TRUE;
	GError *local_error = NULL;

	g_return_val_if_fail (uid != NULL, FALSE);

#ifdef G_OS_WIN32
	e_win32_secret_delete_secret_sync (uid, &local_error);
#else
	/* The return value indicates whether any passwords were removed,
	 * not whether the operation completed successfully.  So we have
	 * to check the GError directly. */
	secret_password_clear_sync (
		&password_schema,
		cancellable, &local_error,
		KEYRING_ITEM_ATTRIBUTE_UID, uid,
		NULL);
#endif

	if (local_error != NULL) {
		g_propagate_error (error, local_error);
		success = FALSE;
	}

	return success;
}
