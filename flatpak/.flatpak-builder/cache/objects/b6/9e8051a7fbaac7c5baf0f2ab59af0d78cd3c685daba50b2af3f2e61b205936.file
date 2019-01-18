/*
 * evolution-source-registry-migrate-sources.c
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

#include "evolution-data-server-config.h"

#include <errno.h>
#include <string.h>
#include <glib/gstdio.h>
#include <camel/camel.h>
#include <libsoup/soup.h>

/* XXX Yeah, yeah... */
#define SECRET_API_SUBJECT_TO_CHANGE

#include <libsecret/secret.h>

#include <libebackend/libebackend.h>

#include "evolution-source-registry-methods.h"

/* These constants are collected from various e-source-*.h files
 * throughout evolution-data-server and known extension packages. */
#define E_SOURCE_GROUP_NAME			"Data Source"
#define E_SOURCE_EXTENSION_CONTACTS_BACKEND	"Contacts Backend"
#define E_SOURCE_EXTENSION_LDAP_BACKEND		"LDAP Backend"
#define E_SOURCE_EXTENSION_LOCAL_BACKEND	"Local Backend"
#define E_SOURCE_EXTENSION_VCF_BACKEND		"VCF Backend"
#define E_SOURCE_EXTENSION_WEATHER_BACKEND	"Weather Backend"
#define E_SOURCE_EXTENSION_WEBDAV_BACKEND	"WebDAV Backend"

/* These constants are copied from e-source-password.c. */
#define KEYRING_ITEM_ATTRIBUTE_NAME		"e-source-uid"
#define KEYRING_ITEM_DISPLAY_FORMAT		"Evolution Data Source %s"

typedef struct _ParseData ParseData;

typedef void		(*PropertyFunc)		(ParseData *parse_data,
						 const gchar *property_name,
						 const gchar *property_value);

typedef enum {
	PARSE_TYPE_MAIL,
	PARSE_TYPE_ADDRESSBOOK,
	PARSE_TYPE_CALENDAR,
	PARSE_TYPE_TASKS,
	PARSE_TYPE_MEMOS
} ParseType;

typedef enum {
	PARSE_STATE_INITIAL,

	PARSE_STATE_IN_GCONF,			/* GConf XML */
	PARSE_STATE_IN_ACCOUNTS_ENTRY,		/* GConf XML */
	PARSE_STATE_IN_ACCOUNTS_VALUE,		/* GConf XML */
	PARSE_STATE_IN_SIGNATURES_ENTRY,	/* GConf XML */
	PARSE_STATE_IN_SIGNATURES_VALUE,	/* GConf XML */
	PARSE_STATE_IN_SOURCES_ENTRY,		/* GConf XML */
	PARSE_STATE_IN_SOURCES_VALUE,		/* GConf XML */

	PARSE_STATE_IN_ACCOUNT,			/* EAccount XML */
	PARSE_STATE_IN_IDENTITY,		/* EAccount XML */
	PARSE_STATE_IN_IDENTITY_NAME,		/* EAccount XML */
	PARSE_STATE_IN_IDENTITY_ADDR_SPEC,	/* EAccount XML */
	PARSE_STATE_IN_IDENTITY_REPLY_TO,	/* EAccount XML */
	PARSE_STATE_IN_IDENTITY_ORGANIZATION,	/* EAccount XML */
	PARSE_STATE_IN_IDENTITY_SIGNATURE,	/* EAccount XML */
	PARSE_STATE_IN_MAIL_SOURCE,		/* EAccount XML */
	PARSE_STATE_IN_MAIL_SOURCE_URL,		/* EAccount XML */
	PARSE_STATE_IN_MAIL_TRANSPORT,		/* EAccount XML */
	PARSE_STATE_IN_MAIL_TRANSPORT_URL,	/* EAccount XML */
	PARSE_STATE_IN_AUTO_CC,			/* EAccount XML */
	PARSE_STATE_IN_AUTO_CC_RECIPIENTS,	/* EAccount XML */
	PARSE_STATE_IN_AUTO_BCC,		/* EAccount XML */
	PARSE_STATE_IN_AUTO_BCC_RECIPIENTS,	/* EAccount XML */
	PARSE_STATE_IN_DRAFTS_FOLDER,		/* EAccount XML */
	PARSE_STATE_IN_SENT_FOLDER,		/* EAccount XML */
	PARSE_STATE_IN_RECEIPT_POLICY,		/* EAccount XML */
	PARSE_STATE_IN_PGP,			/* EAccount XML */
	PARSE_STATE_IN_PGP_KEY_ID,		/* EAccount XML */
	PARSE_STATE_IN_SMIME,			/* EAccount XML */
	PARSE_STATE_IN_SMIME_SIGN_KEY_ID,	/* EAccount XML */
	PARSE_STATE_IN_SMIME_ENCRYPT_KEY_ID,	/* EAccount XML */

	PARSE_STATE_IN_SIGNATURE,		/* ESignature XML */
	PARSE_STATE_IN_FILENAME,		/* ESignature XML */

	PARSE_STATE_IN_GROUP,			/* ESource XML */
	PARSE_STATE_IN_SOURCE,			/* ESource XML */
	PARSE_STATE_IN_PROPERTIES		/* ESource XML */
} ParseState;

struct _ParseData {
	ParseType type;
	ParseState state;

	/* Whether to skip writing a file
	 * for this account information. */
	gboolean skip;

	/* Set by <account>, <source> and <signature> tags. */
	GFile *file;
	GKeyFile *key_file;

	/* Set by <account>/<source> tags. */
	gboolean auto_bcc;
	gboolean auto_cc;

	/* Set by <identity> tags. */
	GFile *identity_file;
	GKeyFile *identity_key_file;

	/* Set by <transport> tags. */
	GFile *transport_file;
	GKeyFile *transport_key_file;

	/* Set by <account> tags. */
	GFile *collection_file;
	GKeyFile *collection_key_file;

	/* Set by <signature> tags. */
	GFile *signature_file;
	gboolean is_script;

	/* Set by <group> tags. */
	gchar *base_uri;

	/* Set by <source> tags. */
	gchar *mangled_uri;
	SoupURI *soup_uri;
	PropertyFunc property_func;
};

/* XXX Probably want to share this with module-online-accounts.c */
static const SecretSchema schema = {
	"org.gnome.Evolution.DataSource",
	SECRET_SCHEMA_DONT_MATCH_NAME,
	{
		{ KEYRING_ITEM_ATTRIBUTE_NAME,
		  SECRET_SCHEMA_ATTRIBUTE_STRING },
		{ NULL, 0 }
	}
};

/* XXX Probably want to share this with e-passwords.c */
static const SecretSchema e_passwords_schema = {
	"org.gnome.Evolution.Password",
	SECRET_SCHEMA_DONT_MATCH_NAME,
	{
		{ "application", SECRET_SCHEMA_ATTRIBUTE_STRING, },
		{ "user", SECRET_SCHEMA_ATTRIBUTE_STRING, },
		{ "server", SECRET_SCHEMA_ATTRIBUTE_STRING, },
		{ "protocol", SECRET_SCHEMA_ATTRIBUTE_STRING, },
	}
};

static ParseData *
parse_data_new (ParseType parse_type)
{
	ParseData *parse_data;

	parse_data = g_slice_new0 (ParseData);
	parse_data->type = parse_type;
	parse_data->state = PARSE_STATE_INITIAL;

	return parse_data;
}

static void
parse_data_free (ParseData *parse_data)
{
	/* Normally the allocated data in ParseData is freed and the
	 * pointers are cleared before we get here.  But if an error
	 * occurred we may leave data behind.  This cleans it up. */

	g_return_if_fail (parse_data != NULL);

	if (parse_data->file != NULL)
		g_object_unref (parse_data->file);

	if (parse_data->key_file != NULL)
		g_key_file_free (parse_data->key_file);

	if (parse_data->identity_file != NULL)
		g_object_unref (parse_data->identity_file);

	if (parse_data->identity_key_file != NULL)
		g_key_file_free (parse_data->identity_key_file);

	if (parse_data->transport_file != NULL)
		g_object_unref (parse_data->transport_file);

	if (parse_data->transport_key_file != NULL)
		g_key_file_free (parse_data->transport_key_file);

	if (parse_data->collection_file != NULL)
		g_object_unref (parse_data->collection_file);

	if (parse_data->collection_key_file != NULL)
		g_key_file_free (parse_data->collection_key_file);

	if (parse_data->signature_file != NULL)
		g_object_unref (parse_data->signature_file);

	g_free (parse_data->base_uri);
	g_free (parse_data->mangled_uri);

	if (parse_data->soup_uri != NULL)
		soup_uri_free (parse_data->soup_uri);

	g_slice_free (ParseData, parse_data);
}

static gboolean
is_true (const gchar *string)
{
	return  (g_ascii_strcasecmp (string, "1") == 0) ||
		(g_ascii_strcasecmp (string, "true") == 0);
}

static gboolean
is_false (const gchar *string)
{
	return  (g_ascii_strcasecmp (string, "0") == 0) ||
		(g_ascii_strcasecmp (string, "false") == 0);
}

static gboolean
base_uri_is_groupware (const gchar *base_uri)
{
	/* Well-known scheme names from various groupware packages. */

	/* We use a limited string comparsion here because the
	 * base_uri string may be 'scheme://' or just 'scheme'. */

	g_return_val_if_fail (base_uri != NULL, FALSE);

	if (g_ascii_strncasecmp (base_uri, "ews", 3) == 0)
		return TRUE;

	if (g_ascii_strncasecmp (base_uri, "exchange", 8) == 0)
		return TRUE;

	if (g_ascii_strncasecmp (base_uri, "groupwise", 9) == 0)
		return TRUE;

	if (g_ascii_strncasecmp (base_uri, "kolab", 5) == 0)
		return TRUE;

	if (g_ascii_strncasecmp (base_uri, "mapi", 4) == 0)
		return TRUE;

	return FALSE;
}

static void
migrate_keyring_entry (const gchar *uid,
                       const gchar *user,
                       const gchar *server,
                       const gchar *protocol)
{
	GHashTable *attributes;
	GList *found_list = NULL;
	gchar *display_name;

	/* Don't migrate entries with empty attributes */
	if (!user || !server || !protocol) {
	      return;
	}

	/* This is a best-effort routine, so we don't really care about
	 * errors.  We leave the old keyring entry in place since it may
	 * be reused for address book or calendar migration. */

	display_name = g_strdup_printf (KEYRING_ITEM_DISPLAY_FORMAT, uid);

	attributes = secret_attributes_build (
		&e_passwords_schema,
		"application", "Evolution",
		"user", user,
		"server", server,
		"protocol", protocol,
		NULL);

	found_list = secret_service_search_sync (
		NULL, &e_passwords_schema, attributes,
		SECRET_SEARCH_ALL |
		SECRET_SEARCH_UNLOCK |
		SECRET_SEARCH_LOAD_SECRETS,
		NULL, NULL);

	/* Pick the first match we find. */
	if (found_list != NULL) {
		SecretItem *item = found_list->data;
		SecretValue *secret = secret_item_get_secret (item);

		/* Sanity check. */
		g_return_if_fail (secret != NULL);

		secret_password_store_sync (
			&schema, SECRET_COLLECTION_DEFAULT, display_name,
			secret_value_get (secret, NULL), NULL, NULL,
			KEYRING_ITEM_ATTRIBUTE_NAME, uid, NULL);

		secret_value_unref (secret);
	}

	g_list_free_full (found_list, g_object_unref);
	g_hash_table_unref (attributes);

	g_free (display_name);
}

static gboolean
migrate_parse_commit_changes (ParseType parse_type,
                              GFile *file,
                              GKeyFile *key_file,
                              const gchar *mangled_uri,
                              GError **error)
{
	const gchar *data_dir;
	const gchar *cache_dir;
	const gchar *component;
	gchar *old_directory;
	gchar *new_directory;
	gchar *contents;
	gchar *uid;
	gsize length;
	gboolean success;
	gboolean old_directory_exists;
	gboolean new_directory_exists;

	data_dir = e_get_user_data_dir ();
	cache_dir = e_get_user_cache_dir ();

	uid = e_server_side_source_uid_from_file (file, error);

	if (uid == NULL)
		return FALSE;

	e_source_registry_debug_print ("  * Source: %s\n", uid);

	e_source_registry_debug_print ("    Writing key file...\n");

	/* Save the key file contents to disk. */
	contents = g_key_file_to_data (key_file, &length, NULL);
	success = g_file_replace_contents (
		file, contents, length, NULL, FALSE,
		G_FILE_CREATE_PRIVATE, NULL, NULL, error);
	g_free (contents);

	if (!success)
		goto exit;

	/* Rename the source's local cache directory from its mangled
	 * URI to its UID.  The key file's basename contains the UID.
	 * All source types but "local" should have cache directories. */

	/* Mail cache directories already use UIDs. */
	switch (parse_type) {
		case PARSE_TYPE_ADDRESSBOOK:
			component = "addressbook";
			break;
		case PARSE_TYPE_CALENDAR:
			component = "calendar";
			break;
		case PARSE_TYPE_TASKS:
			component = "tasks";
			break;
		case PARSE_TYPE_MEMOS:
			component = "memos";
			break;
		default:
			goto exit;
	}

	if (!mangled_uri) {
		g_warn_if_reached ();
		goto exit;
	}

	old_directory = g_build_filename (
		cache_dir, component, mangled_uri, NULL);

	new_directory = g_build_filename (
		cache_dir, component, uid, NULL);

	old_directory_exists = g_file_test (old_directory, G_FILE_TEST_EXISTS);
	new_directory_exists = g_file_test (new_directory, G_FILE_TEST_EXISTS);

	e_source_registry_debug_print (
		"    Checking for old cache dir '%s'... %s\n",
		old_directory,
		old_directory_exists ? "found" : "not found");

	if (old_directory_exists) {
		e_source_registry_debug_print (
			"    Checking for new cache dir '%s'... %s\n",
			new_directory,
			new_directory_exists ? "found" : "not found");

		if (new_directory_exists)
			e_source_registry_debug_print ("    Skipping cache directory rename.\n");
		else {
			e_source_registry_debug_print ("    Renaming old cache directory...\n");
			if (g_rename (old_directory, new_directory) < 0) {
				g_set_error (
					error, G_FILE_ERROR,
					g_file_error_from_errno (errno),
					"%s", g_strerror (errno));
				success = FALSE;
			}
		}
	}

	g_free (old_directory);
	g_free (new_directory);

	if (!success)
		goto exit;

	/* Rename the source's local data directory from its mangled
	 * URI to its UID.  The key file's basename contains the UID.
	 * Only "local" sources have local data directores. */

	old_directory = g_build_filename (
		data_dir, component, mangled_uri, NULL);

	new_directory = g_build_filename (
		data_dir, component, uid, NULL);

	old_directory_exists = g_file_test (old_directory, G_FILE_TEST_EXISTS);
	new_directory_exists = g_file_test (new_directory, G_FILE_TEST_EXISTS);

	e_source_registry_debug_print (
		"    Checking for old data dir '%s'... %s\n",
		old_directory,
		old_directory_exists ? "found" : "not found");

	if (old_directory_exists) {
		e_source_registry_debug_print (
			"    Checking for new data dir '%s'... %s\n",
			new_directory,
			new_directory_exists ? "found" : "not found");

		if (new_directory_exists)
			e_source_registry_debug_print ("    Skipping data directory rename.\n");
		else {
			e_source_registry_debug_print ("    Renaming old data directory...\n");
			if (g_rename (old_directory, new_directory) < 0) {
				g_set_error (
					error, G_FILE_ERROR,
					g_file_error_from_errno (errno),
					"%s", g_strerror (errno));
				success = FALSE;
			}
		}
	}

	g_free (old_directory);
	g_free (new_directory);

exit:
	g_free (uid);

	return success;
}

static void
migrate_setup_collection (ParseData *parse_data,
                          CamelURL *url)
{
	gchar *collection_uid;
	gchar *display_name;
	gboolean enabled;

	g_return_if_fail (parse_data->key_file != NULL);
	g_return_if_fail (parse_data->identity_key_file != NULL);
	g_return_if_fail (parse_data->transport_key_file != NULL);

	parse_data->collection_file = e_server_side_source_new_user_file (NULL);
	parse_data->collection_key_file = g_key_file_new ();

	collection_uid = e_server_side_source_uid_from_file (
		parse_data->collection_file, NULL);

	/* Copy the display name from the mail account source. */

	display_name = g_key_file_get_string (
		parse_data->key_file,
		E_SOURCE_GROUP_NAME, "DisplayName", NULL);

	g_key_file_set_string (
		parse_data->collection_key_file,
		E_SOURCE_GROUP_NAME, "DisplayName", display_name);

	/* Copy the enabled state from the mail account source. */

	enabled = g_key_file_get_boolean (
		parse_data->key_file,
		E_SOURCE_GROUP_NAME, "Enabled", NULL);

	g_key_file_set_boolean (
		parse_data->collection_key_file,
		E_SOURCE_GROUP_NAME, "Enabled", enabled);

	/* Collection sources are always top-level sources. */

	g_key_file_set_string (
		parse_data->collection_key_file,
		E_SOURCE_GROUP_NAME, "Parent", "");

	/* Collection backend name should match the CamelURL protocol. */

	g_key_file_set_string (
		parse_data->collection_key_file,
		E_SOURCE_EXTENSION_COLLECTION,
		"BackendName", url->protocol);

	g_key_file_set_boolean (
		parse_data->collection_key_file,
		E_SOURCE_EXTENSION_COLLECTION,
		"CalendarEnabled", TRUE);

	g_key_file_set_boolean (
		parse_data->collection_key_file,
		E_SOURCE_EXTENSION_COLLECTION,
		"ContactsEnabled", TRUE);

	g_key_file_set_boolean (
		parse_data->collection_key_file,
		E_SOURCE_EXTENSION_COLLECTION,
		"MailEnabled", TRUE);

	/* Enable all mail sources since we set "MailEnabled=true" above. */

	g_key_file_set_boolean (
		parse_data->key_file,
		E_SOURCE_GROUP_NAME, "Enabled", TRUE);

	g_key_file_set_boolean (
		parse_data->identity_key_file,
		E_SOURCE_GROUP_NAME, "Enabled", TRUE);

	g_key_file_set_boolean (
		parse_data->transport_key_file,
		E_SOURCE_GROUP_NAME, "Enabled", TRUE);

	/* The other mail sources are children of the collection source. */

	g_key_file_set_string (
		parse_data->key_file,
		E_SOURCE_GROUP_NAME,
		"Parent", collection_uid);

	g_key_file_set_string (
		parse_data->identity_key_file,
		E_SOURCE_GROUP_NAME,
		"Parent", collection_uid);

	g_key_file_set_string (
		parse_data->transport_key_file,
		E_SOURCE_GROUP_NAME,
		"Parent", collection_uid);

	/* The collection identity has to be determined case-by-case.
	 * Some are based on user name, some are based on email address. */

	if (g_strcmp0 (url->protocol, "ews") == 0)
		g_key_file_set_string (
			parse_data->collection_key_file,
			E_SOURCE_EXTENSION_COLLECTION,
			"Identity", url->user);

	g_free (collection_uid);
	g_free (display_name);
}

static void
migrate_parse_account (ParseData *parse_data,
                       const gchar *element_name,
                       const gchar **attribute_names,
                       const gchar **attribute_values,
                       GError **error)
{
	const gchar *uid;
	const gchar *name;
	gchar *identity_uid;
	gchar *transport_uid;
	gboolean enabled;
	gboolean success;

	success = g_markup_collect_attributes (
		element_name,
		attribute_names,
		attribute_values,
		error,
		G_MARKUP_COLLECT_STRING,
		"uid", &uid,
		G_MARKUP_COLLECT_STRING,
		"name", &name,
		G_MARKUP_COLLECT_BOOLEAN,
		"enabled", &enabled,
		G_MARKUP_COLLECT_INVALID);

	if (!success)
		return;

	parse_data->file = e_server_side_source_new_user_file (uid);

	/* If the file already exists, skip this source.  It may be that we
	 * already migrated it, in which case we don't want to overwrite it. */
	if (g_file_query_exists (parse_data->file, NULL))
		return;

	parse_data->key_file = g_key_file_new ();

	parse_data->identity_file = e_server_side_source_new_user_file (NULL);
	parse_data->identity_key_file = g_key_file_new ();

	parse_data->transport_file = e_server_side_source_new_user_file (NULL);
	parse_data->transport_key_file = g_key_file_new ();

	identity_uid = e_server_side_source_uid_from_file (
		parse_data->identity_file, NULL);

	transport_uid = e_server_side_source_uid_from_file (
		parse_data->transport_file, NULL);

	g_key_file_set_string (
		parse_data->key_file,
		E_SOURCE_GROUP_NAME,
		"DisplayName", name);

	g_key_file_set_boolean (
		parse_data->key_file,
		E_SOURCE_GROUP_NAME,
		"Enabled", enabled);

	/* Mail account source references the identity source. */
	g_key_file_set_string (
		parse_data->key_file,
		E_SOURCE_EXTENSION_MAIL_ACCOUNT,
		"IdentityUid", identity_uid);

	/* Mail account source references the transport source. */
	g_key_file_set_string (
		parse_data->identity_key_file,
		E_SOURCE_EXTENSION_MAIL_SUBMISSION,
		"TransportUid", transport_uid);

	/* Identity source gets the same display name. */
	g_key_file_set_string (
		parse_data->identity_key_file,
		E_SOURCE_GROUP_NAME,
		"DisplayName", name);

	/* Identity source gets the same enabled state. */
	g_key_file_set_boolean (
		parse_data->identity_key_file,
		E_SOURCE_GROUP_NAME,
		"Enabled", enabled);

	/* Identity source is a child of the mail account. */
	g_key_file_set_string (
		parse_data->identity_key_file,
		E_SOURCE_GROUP_NAME,
		"Parent", uid);

	/* Transport source gets the same display name. */
	g_key_file_set_string (
		parse_data->transport_key_file,
		E_SOURCE_GROUP_NAME,
		"DisplayName", name);

	/* Always enable the transport source, even if the mail account
	 * is disabled.  Evolution does not currently honor the enabled
	 * setting on transports, so disabling the transport would only
	 * confuse matters should Evolution honor it in the future. */
	g_key_file_set_boolean (
		parse_data->transport_key_file,
		E_SOURCE_GROUP_NAME,
		"Enabled", TRUE);

	/* Transport source is a child of the mail account. */
	g_key_file_set_string (
		parse_data->transport_key_file,
		E_SOURCE_GROUP_NAME,
		"Parent", uid);

	g_free (identity_uid);
	g_free (transport_uid);
}

static void
migrate_parse_pgp (ParseData *parse_data,
                   const gchar *element_name,
                   const gchar **attribute_names,
                   const gchar **attribute_values,
                   GError **error)
{
	const gchar *hash_algo;
	gboolean always_sign;
	gboolean always_trust;
	gboolean encrypt_to_self;
	gboolean no_imip_sign;
	gboolean success;

	success = g_markup_collect_attributes (
		element_name,
		attribute_names,
		attribute_values,
		error,
		G_MARKUP_COLLECT_BOOLEAN,
		"always-sign", &always_sign,
		G_MARKUP_COLLECT_BOOLEAN,
		"always-trust", &always_trust,
		G_MARKUP_COLLECT_BOOLEAN,
		"encrypt-to-self", &encrypt_to_self,
		G_MARKUP_COLLECT_BOOLEAN,
		"no-imip-sign", &no_imip_sign,
		G_MARKUP_COLLECT_STRING |
		G_MARKUP_COLLECT_OPTIONAL,
		"hash-algo", &hash_algo,
		G_MARKUP_COLLECT_INVALID);

	if (!success)
		return;

	g_key_file_set_boolean (
		parse_data->identity_key_file,
		E_SOURCE_EXTENSION_OPENPGP,
		"AlwaysSign", always_sign);

	g_key_file_set_boolean (
		parse_data->identity_key_file,
		E_SOURCE_EXTENSION_OPENPGP,
		"AlwaysTrust", always_trust);

	g_key_file_set_boolean (
		parse_data->identity_key_file,
		E_SOURCE_EXTENSION_OPENPGP,
		"EncryptToSelf", encrypt_to_self);

	if (hash_algo != NULL && *hash_algo != '\0')
		g_key_file_set_string (
			parse_data->identity_key_file,
			E_SOURCE_EXTENSION_OPENPGP,
			"SigningAlgorithm", hash_algo);

	/* XXX Don't know why this is under the <pgp>
	 *     element, it applies to S/MIME as well.
	 *     Also note we're inverting the setting. */
	g_key_file_set_boolean (
		parse_data->identity_key_file,
		E_SOURCE_EXTENSION_MAIL_COMPOSITION,
		"SignImip", !no_imip_sign);
}

static void
migrate_parse_recipients (ParseData *parse_data,
                          const gchar *key,
                          const gchar *recipients)
{
	CamelAddress *address;
	CamelInternetAddress *inet_address;
	gchar **string_list;
	gint ii, length;
	gsize index = 0;

	if (recipients == NULL || *recipients == '\0')
		return;

	inet_address = camel_internet_address_new ();
	address = CAMEL_ADDRESS (inet_address);

	if (camel_address_decode (address, recipients) == -1)
		goto exit;

	length = camel_address_length (address);
	string_list = g_new0 (gchar *, length + 1);

	for (ii = 0; ii < length; ii++) {
		const gchar *name, *addr;

		if (!camel_internet_address_get (
			inet_address, ii, &name, &addr))
			continue;

		string_list[index++] =
			camel_internet_address_format_address (name, addr);
	}

	g_key_file_set_string_list (
		parse_data->identity_key_file,
		E_SOURCE_EXTENSION_MAIL_COMPOSITION, key,
		(const gchar *const *) string_list, index);

	g_strfreev (string_list);

exit:
	g_object_unref (inet_address);
}

static void
migrate_parse_smime (ParseData *parse_data,
                     const gchar *element_name,
                     const gchar **attribute_names,
                     const gchar **attribute_values,
                     GError **error)
{
	const gchar *hash_algo;
	gboolean encrypt_default;
	gboolean encrypt_to_self;
	gboolean sign_default;
	gboolean success;

	success = g_markup_collect_attributes (
		element_name,
		attribute_names,
		attribute_values,
		error,
		G_MARKUP_COLLECT_BOOLEAN,
		"encrypt-default", &encrypt_default,
		G_MARKUP_COLLECT_BOOLEAN,
		"encrypt-to-self", &encrypt_to_self,
		G_MARKUP_COLLECT_STRING |
		G_MARKUP_COLLECT_OPTIONAL,
		"hash-algo", &hash_algo,
		G_MARKUP_COLLECT_BOOLEAN,
		"sign-default", &sign_default,
		G_MARKUP_COLLECT_INVALID);

	if (!success)
		return;

	g_key_file_set_boolean (
		parse_data->identity_key_file,
		E_SOURCE_EXTENSION_SMIME,
		"EncryptByDefault", encrypt_default);

	g_key_file_set_boolean (
		parse_data->identity_key_file,
		E_SOURCE_EXTENSION_SMIME,
		"EncryptToSelf", encrypt_to_self);

	if (hash_algo != NULL && *hash_algo != '\0')
		g_key_file_set_string (
			parse_data->identity_key_file,
			E_SOURCE_EXTENSION_SMIME,
			"SigningAlgorithm", hash_algo);

	g_key_file_set_boolean (
		parse_data->identity_key_file,
		E_SOURCE_EXTENSION_SMIME,
		"SignByDefault", sign_default);
}

static void
migrate_parse_mail_source (ParseData *parse_data,
                           const gchar *element_name,
                           const gchar **attribute_names,
                           const gchar **attribute_values,
                           GError **error)
{
	const gchar *auto_check_timeout;
	glong interval_minutes = 0;
	gboolean auto_check;
	gboolean success;

	/* Disregard "keep-on-server" and "save-passwd" attributes. */
	success = g_markup_collect_attributes (
		element_name,
		attribute_names,
		attribute_values,
		error,
		G_MARKUP_COLLECT_BOOLEAN,
		"auto-check", &auto_check,
		G_MARKUP_COLLECT_STRING,
		"auto-check-timeout", &auto_check_timeout,
		G_MARKUP_COLLECT_BOOLEAN |
		G_MARKUP_COLLECT_OPTIONAL,
		"keep-on-server", NULL,
		G_MARKUP_COLLECT_BOOLEAN |
		G_MARKUP_COLLECT_OPTIONAL,
		"save-passwd", NULL,
		G_MARKUP_COLLECT_INVALID);

	if (!success)
		return;

	if (auto_check_timeout != NULL)
		interval_minutes = strtol (auto_check_timeout, NULL, 10);

	g_key_file_set_boolean (
		parse_data->key_file,
		E_SOURCE_EXTENSION_REFRESH,
		"Enabled", auto_check);

	if (interval_minutes > 0)
		g_key_file_set_integer (
			parse_data->key_file,
			E_SOURCE_EXTENSION_REFRESH,
			"IntervalMinutes", interval_minutes);
}

static void
migrate_parse_url_rename_params (CamelURL *url)
{
	/* This list includes known URL parameters from built-in providers
	 * in Camel, as well as from evolution-exchange/groupwise/mapi/ews.
	 * Add more as needed. */
	static struct {
		const gchar *url_parameter;
		const gchar *property_name;
	} camel_url_conversion[] = {
		{ "account_uid",		"account-uid" },
		{ "ad_auth",			"gc-auth-method" },
		{ "ad_browse",			"gc-allow-browse" },
		{ "ad_expand_groups",		"gc-expand-groups" },
		{ "ad_limit",			"gc-results-limit" },
		{ "ad_server",			"gc-server-name" },
		{ "all_headers",		"fetch-headers" },
		{ "basic_headers",		"fetch-headers" },
		{ "cachedconn"			"concurrent-connections" },
		{ "check_all",			"check-all" },
		{ "check_lsub",			"check-subscribed" },
		{ "command",			"shell-command" },
		{ "delete_after",		"delete-after-days" },
		{ "delete_expunged",		"delete-expunged" },
		{ "disable_extensions",		"disable-extensions" },
		{ "dotfolders",			"use-dot-folders" },
		{ "filter",			"filter-inbox" },
		{ "filter_junk",		"filter-junk" },
		{ "filter_junk_inbox",		"filter-junk-inbox" },
		{ "folder_hierarchy_relative",	"folder-hierarchy-relative" },
		{ "imap_custom_headers",	"fetch-headers-extra" },
		{ "keep_on_server",		"keep-on-server" },
		{ "oab_offline",		"oab-offline" },
		{ "oal_selected",		"oal-selected" },
		{ "offline_sync",		"stay-synchronized" },
		{ "override_namespace",		"use-namespace" },
		{ "owa_path",			"owa-path" },
		{ "owa_url",			"owa-url" },
		{ "password_exp_warn_period",	"password-exp-warn-period" },
		{ "real_junk_path",		"real-junk-path" },
		{ "real_trash_path",		"real-trash-path" },
		{ "show_short_notation",	"short-folder-names" },
		{ "soap_port",			"soap-port" },
		{ "ssl",			"security-method" },
		{ "sync_offline",		"stay-synchronized" },
		{ "use_command",		"use-shell-command" },
		{ "use_idle",			"use-idle" },
		{ "use_lsub",			"use-subscriptions" },
		{ "use_qresync",		"use-qresync" },
		{ "use_ssl",			"security-method" },
		{ "xstatus",			"use-xstatus-headers" }
	};

	const gchar *param;
	const gchar *use_param;
	gint ii;

	for (ii = 0; ii < G_N_ELEMENTS (camel_url_conversion); ii++) {
		const gchar *key;
		gpointer value;

		key = camel_url_conversion[ii].url_parameter;
		value = g_datalist_get_data (&url->params, key);

		if (value == NULL)
			continue;

		g_datalist_remove_no_notify (&url->params, key);

		key = camel_url_conversion[ii].property_name;

		/* Deal with a few special enum cases where
		 * the parameter value also needs renamed. */

		if (strcmp (key, "all_headers") == 0) {
			GEnumClass *enum_class;
			GEnumValue *enum_value;

			enum_class = g_type_class_ref (
				CAMEL_TYPE_FETCH_HEADERS_TYPE);
			enum_value = g_enum_get_value (
				enum_class, CAMEL_FETCH_HEADERS_ALL);
			if (enum_value != NULL) {
				g_free (value);
				value = g_strdup (enum_value->value_nick);
			} else
				g_warn_if_reached ();
			g_type_class_unref (enum_class);
		}

		if (strcmp (key, "basic_headers") == 0) {
			GEnumClass *enum_class;
			GEnumValue *enum_value;

			enum_class = g_type_class_ref (
				CAMEL_TYPE_FETCH_HEADERS_TYPE);
			enum_value = g_enum_get_value (
				enum_class, CAMEL_FETCH_HEADERS_BASIC);
			if (enum_value != NULL) {
				g_free (value);
				value = g_strdup (enum_value->value_nick);
			} else
				g_warn_if_reached ();
			g_type_class_unref (enum_class);
		}

		if (strcmp (key, "imap_custom_headers") == 0)
			g_strdelimit (value, " ", ',');

		if (strcmp (key, "security-method") == 0) {
			CamelNetworkSecurityMethod method;
			GEnumClass *enum_class;
			GEnumValue *enum_value;

			if (strcmp (value, "always") == 0)
				method = CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT;
			else if (strcmp (value, "1") == 0)
				method = CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT;
			else if (strcmp (value, "when-possible") == 0)
				method = CAMEL_NETWORK_SECURITY_METHOD_STARTTLS_ON_STANDARD_PORT;
			else
				method = CAMEL_NETWORK_SECURITY_METHOD_NONE;

			enum_class = g_type_class_ref (
				CAMEL_TYPE_NETWORK_SECURITY_METHOD);
			enum_value = g_enum_get_value (enum_class, method);
			if (enum_value != NULL) {
				g_free (value);
				value = g_strdup (enum_value->value_nick);
			} else
				g_warn_if_reached ();
			g_type_class_unref (enum_class);
		}

		g_datalist_set_data_full (&url->params, key, value, g_free);
	}

	/* Missing "security-method" means STARTTLS,
	 * as it was the default value prior to 3.6. */
	if (!g_datalist_get_data (&url->params, "security-method")) {
		GEnumClass *enum_class;
		GEnumValue *enum_value;
		gchar *value = NULL;

		enum_class = g_type_class_ref (
			CAMEL_TYPE_NETWORK_SECURITY_METHOD);
		enum_value = g_enum_get_value (
			enum_class,
			CAMEL_NETWORK_SECURITY_METHOD_STARTTLS_ON_STANDARD_PORT);
		if (enum_value != NULL) {
			value = g_strdup (enum_value->value_nick);
		} else
			g_warn_if_reached ();
		g_type_class_unref (enum_class);

		g_datalist_set_data_full (
			&url->params, "security-method", value, g_free);
	}

	/* A few more adjustments...
	 *
	 * These are all CAMEL_PROVIDER_CONF_CHECKSPIN settings.  The spin
	 * button value is bound to "param" and the checkbox state is bound
	 * to "use-param".  The "use-param" settings are new.  If "param"
	 * exists but no "use-param", then set "use-param" to "true". */

	param = g_datalist_get_data (&url->params, "gc-results-limit");
	use_param = g_datalist_get_data (&url->params, "use-gc-results-limit");
	if (param != NULL && *param != '\0' && use_param == NULL) {
		g_datalist_set_data_full (
			&url->params, "use-gc-results-limit",
			g_strdup ("true"), (GDestroyNotify) g_free);
	}

	param = g_datalist_get_data (&url->params, "kerberos");
	if (g_strcmp0 (param, "required") == 0) {
		g_datalist_set_data_full (
			&url->params, "kerberos",
			g_strdup ("true"), (GDestroyNotify) g_free);
	}

	param = g_datalist_get_data (
		&url->params, "password-exp-warn-period");
	use_param = g_datalist_get_data (
		&url->params, "use-password-exp-warn-period");
	if (param != NULL && *param != '\0' && use_param == NULL) {
		g_datalist_set_data_full (
			&url->params, "use-password-exp-warn-period",
			g_strdup ("true"), (GDestroyNotify) g_free);
	}

	param = g_datalist_get_data (&url->params, "real-junk-path");
	use_param = g_datalist_get_data (&url->params, "use-real-junk-path");
	if (param != NULL && *param != '\0' && use_param == NULL) {
		g_datalist_set_data_full (
			&url->params, "use-real-junk-path",
			g_strdup ("true"), (GDestroyNotify) g_free);
	}

	param = g_datalist_get_data (&url->params, "real-trash-path");
	use_param = g_datalist_get_data (&url->params, "use-real-trash-path");
	if (param != NULL && *param != '\0' && use_param == NULL) {
		g_datalist_set_data_full (
			&url->params, "use-real-trash-path",
			g_strdup ("true"), (GDestroyNotify) g_free);
	}

	/* Remove an empty "namespace" parameter (if present) to avoid
	 * it being converted to "true" in migrate_parse_url_foreach(). */
	param = g_datalist_get_data (&url->params, "namespace");
	if (param != NULL && *param == '\0')
		g_datalist_remove_data (&url->params, "namespace");
}

static void
migrate_parse_url_foreach (GQuark key_id,
                           const gchar *value,
                           gpointer user_data)
{
	const gchar *param_name;
	const gchar *key;

	struct {
		GKeyFile *key_file;
		const gchar *group_name;
	} *foreach_data = user_data;

	g_return_if_fail (value != NULL);

	param_name = g_quark_to_string (key_id);
	key = e_source_parameter_to_key (param_name);

	/* If the value is empty, then the mere
	 * presence of the parameter implies TRUE. */
	if (*value == '\0')
		value = "true";

	g_key_file_set_string (
		foreach_data->key_file,
		foreach_data->group_name,
		key, value);
}

static void
migrate_parse_url (ParseData *parse_data,
                   GKeyFile *key_file,
                   GFile *file,
                   const gchar *group_name,
                   const gchar *url_string,
                   GError **error)
{
	CamelURL *url;
	GKeyFile *backend_key_file;
	GFile *backend_file;
	const gchar *value;
	gboolean setup_collection;
	gchar *uid;

	struct {
		GKeyFile *key_file;
		const gchar *group_name;
	} foreach_data;

	url = camel_url_new (url_string, error);
	if (url == NULL || url->protocol == NULL)
		return;

	/* Rename URL params as necessary to match
	 * their ESourceExtension property names. */
	migrate_parse_url_rename_params (url);

	setup_collection =
		(key_file == parse_data->key_file) &&
		base_uri_is_groupware (url->protocol);

	if (setup_collection)
		migrate_setup_collection (parse_data, url);

	/* Store backend settings in the collection GKeyFile, if one is
	 * defined.  Otherwise store them in the GKeyFile we were passed.
	 * Same goes for the keyring entry, which uses the GFile. */
	if (parse_data->collection_key_file != NULL) {
		backend_key_file = parse_data->collection_key_file;
		backend_file = parse_data->collection_file;
	} else {
		backend_key_file = key_file;
		backend_file = file;
	}

	/* This is not a backend setting. */
	g_key_file_set_string (
		key_file, group_name,
		"BackendName", url->protocol);

	/* Set authentication details. */

	if (url->host != NULL)
		g_key_file_set_string (
			backend_key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"Host", url->host);

	if (url->authmech != NULL)
		g_key_file_set_string (
			backend_key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"Method", url->authmech);

	if (url->port > 0)
		g_key_file_set_integer (
			backend_key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"Port", url->port);

	if (url->user != NULL)
		g_key_file_set_string (
			backend_key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"User", url->user);

	/* Pick out particular URL parameters we know about. */

	/* If set, this should be "true" or "false",
	 * but we'll just write it like it's a string. */
	value = g_datalist_get_data (&url->params, "stay-synchronized");
	if (value != NULL)
		g_key_file_set_string (
			backend_key_file,
			E_SOURCE_EXTENSION_OFFLINE,
			"StaySynchronized", value);
	g_datalist_set_data (&url->params, "stay-synchronized", NULL);

	value = g_datalist_get_data (&url->params, "security-method");
	if (value != NULL)
		g_key_file_set_string (
			backend_key_file,
			E_SOURCE_EXTENSION_SECURITY,
			"Method", value);
	g_datalist_set_data (&url->params, "security-method", NULL);

	/* If we see a "goa-account-id" parameter, skip the entire
	 * account and let the online-accounts module recreate it. */
	value = g_datalist_get_data (&url->params, "goa-account-id");
	if (value != NULL && *value != '\0')
		parse_data->skip = TRUE;

	/* The rest of the URL parameters go in the backend group. */

	group_name = e_source_camel_get_extension_name (url->protocol);

	foreach_data.key_file = backend_key_file;
	foreach_data.group_name = group_name;

	g_datalist_foreach (
		&url->params, (GDataForeachFunc)
		migrate_parse_url_foreach, &foreach_data);

	/* Local providers store their "path" as the url->path */
	if (g_strcmp0 (url->protocol, "mh") == 0 ||
	    g_strcmp0 (url->protocol, "mbox") == 0 ||
	    g_strcmp0 (url->protocol, "maildir") == 0 ||
	    g_strcmp0 (url->protocol, "spool") == 0 ||
	    g_strcmp0 (url->protocol, "spooldir") == 0)
		g_key_file_set_string (
			backend_key_file,
			group_name,
			"Path", url->path);

	uid = e_server_side_source_uid_from_file (backend_file, error);

	if (uid != NULL) {
		migrate_keyring_entry (
			uid, url->user, url->host, url->protocol);
		g_free (uid);
	}

	camel_url_free (url);
}

static void
migrate_parse_account_xml_start_element (GMarkupParseContext *context,
                                         const gchar *element_name,
                                         const gchar **attribute_names,
                                         const gchar **attribute_values,
                                         gpointer user_data,
                                         GError **error)
{
	ParseData *parse_data = user_data;

	if (g_strcmp0 (element_name, "account") == 0) {
		if (parse_data->state != PARSE_STATE_IN_ACCOUNTS_VALUE)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_ACCOUNT;

		migrate_parse_account (
			parse_data,
			element_name,
			attribute_names,
			attribute_values,
			error);

		return;
	}

	if (g_strcmp0 (element_name, "addr-spec") == 0) {
		if (parse_data->state != PARSE_STATE_IN_IDENTITY)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_IDENTITY_ADDR_SPEC;

		return;
	}

	if (g_strcmp0 (element_name, "auto-bcc") == 0) {
		if (parse_data->state != PARSE_STATE_IN_ACCOUNT)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_AUTO_BCC;

		g_markup_collect_attributes (
			element_name,
			attribute_names,
			attribute_values,
			error,
			G_MARKUP_COLLECT_BOOLEAN,
			"always", &parse_data->auto_bcc,
			G_MARKUP_COLLECT_INVALID);

		return;
	}

	if (g_strcmp0 (element_name, "auto-cc") == 0) {
		if (parse_data->state != PARSE_STATE_IN_ACCOUNT)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_AUTO_CC;

		g_markup_collect_attributes (
			element_name,
			attribute_names,
			attribute_values,
			error,
			G_MARKUP_COLLECT_BOOLEAN,
			"always", &parse_data->auto_cc,
			G_MARKUP_COLLECT_INVALID);

		return;
	}

	if (g_strcmp0 (element_name, "drafts-folder") == 0) {
		if (parse_data->state != PARSE_STATE_IN_ACCOUNT)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_DRAFTS_FOLDER;

		return;
	}

	if (g_strcmp0 (element_name, "encrypt-key-id") == 0) {
		if (parse_data->state != PARSE_STATE_IN_SMIME)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_SMIME_ENCRYPT_KEY_ID;

		return;
	}

	if (g_strcmp0 (element_name, "identity") == 0) {
		if (parse_data->state != PARSE_STATE_IN_ACCOUNT)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_IDENTITY;

		return;
	}

	if (g_strcmp0 (element_name, "key-id") == 0) {
		if (parse_data->state != PARSE_STATE_IN_PGP)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_PGP_KEY_ID;

		return;
	}

	if (g_strcmp0 (element_name, "name") == 0) {
		if (parse_data->state != PARSE_STATE_IN_IDENTITY)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_IDENTITY_NAME;

		return;
	}

	if (g_strcmp0 (element_name, "reply-to") == 0) {
		if (parse_data->state != PARSE_STATE_IN_IDENTITY)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_IDENTITY_REPLY_TO;

		return;
	}

	if (g_strcmp0 (element_name, "organization") == 0) {
		if (parse_data->state != PARSE_STATE_IN_IDENTITY)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_IDENTITY_ORGANIZATION;

		return;
	}

	if (g_strcmp0 (element_name, "pgp") == 0) {
		if (parse_data->state != PARSE_STATE_IN_ACCOUNT)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_PGP;

		migrate_parse_pgp (
			parse_data,
			element_name,
			attribute_names,
			attribute_values,
			error);

		return;
	}

	if (g_strcmp0 (element_name, "receipt-policy") == 0) {
		const gchar *policy;
		gboolean success;

		if (parse_data->state != PARSE_STATE_IN_ACCOUNT)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_RECEIPT_POLICY;

		success = g_markup_collect_attributes (
			element_name,
			attribute_names,
			attribute_values,
			error,
			G_MARKUP_COLLECT_STRING,
			"policy", &policy,
			G_MARKUP_COLLECT_INVALID);

		/* The new enum strings match the old ones. */
		if (success && policy != NULL)
			g_key_file_set_string (
				parse_data->key_file,
				E_SOURCE_EXTENSION_MDN,
				"ResponsePolicy", policy);

		return;
	}

	if (g_strcmp0 (element_name, "recipients") == 0) {
		if (parse_data->state == PARSE_STATE_IN_AUTO_BCC) {
			parse_data->state = PARSE_STATE_IN_AUTO_BCC_RECIPIENTS;
			return;
		}

		if (parse_data->state == PARSE_STATE_IN_AUTO_CC) {
			parse_data->state = PARSE_STATE_IN_AUTO_CC_RECIPIENTS;
			return;
		}

		goto invalid_content;
	}

	if (g_strcmp0 (element_name, "sent-folder") == 0) {
		if (parse_data->state != PARSE_STATE_IN_ACCOUNT)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_SENT_FOLDER;

		return;
	}

	if (g_strcmp0 (element_name, "signature") == 0) {
		const gchar *uid;
		gboolean success;

		if (parse_data->state != PARSE_STATE_IN_IDENTITY)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_IDENTITY_SIGNATURE;

		success = g_markup_collect_attributes (
			element_name,
			attribute_names,
			attribute_values,
			error,
			G_MARKUP_COLLECT_STRING,
			"uid", &uid,
			G_MARKUP_COLLECT_INVALID);

		if (success && uid != NULL)
			g_key_file_set_string (
				parse_data->identity_key_file,
				E_SOURCE_EXTENSION_MAIL_IDENTITY,
				"SignatureUid", uid);

		return;
	}

	if (g_strcmp0 (element_name, "sign-key-id") == 0) {
		if (parse_data->state != PARSE_STATE_IN_SMIME)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_SMIME_SIGN_KEY_ID;

		return;
	}

	if (g_strcmp0 (element_name, "smime") == 0) {
		if (parse_data->state != PARSE_STATE_IN_ACCOUNT)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_SMIME;

		migrate_parse_smime (
			parse_data,
			element_name,
			attribute_names,
			attribute_values,
			error);

		return;
	}

	if (g_strcmp0 (element_name, "source") == 0) {
		if (parse_data->state != PARSE_STATE_IN_ACCOUNT)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_MAIL_SOURCE;

		migrate_parse_mail_source (
			parse_data,
			element_name,
			attribute_names,
			attribute_values,
			error);

		return;
	}

	if (g_strcmp0 (element_name, "transport") == 0) {
		if (parse_data->state != PARSE_STATE_IN_ACCOUNT)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_MAIL_TRANSPORT;

		return;
	}

	if (g_strcmp0 (element_name, "url") == 0) {
		if (parse_data->state == PARSE_STATE_IN_MAIL_SOURCE) {
			parse_data->state = PARSE_STATE_IN_MAIL_SOURCE_URL;
			return;
		}

		if (parse_data->state == PARSE_STATE_IN_MAIL_TRANSPORT) {
			parse_data->state = PARSE_STATE_IN_MAIL_TRANSPORT_URL;
			return;
		}

		goto invalid_content;
	}

	g_set_error (
		error, G_MARKUP_ERROR, G_MARKUP_ERROR_UNKNOWN_ELEMENT,
		"Unknown element <%s>", element_name);

	return;

invalid_content:

	g_set_error (
		error, G_MARKUP_ERROR, G_MARKUP_ERROR_INVALID_CONTENT,
		"Element <%s> at unexpected location", element_name);
}

static void
migrate_parse_account_xml_end_element (GMarkupParseContext *context,
                                       const gchar *element_name,
                                       gpointer user_data,
                                       GError **error)
{
	ParseData *parse_data = user_data;

	if (g_strcmp0 (element_name, "account") == 0) {
		if (parse_data->state == PARSE_STATE_IN_ACCOUNT) {
			parse_data->state = PARSE_STATE_IN_ACCOUNTS_VALUE;

			/* Clean up <account> tag data. */

			/* The key file will be NULL if we decided to skip it.
			 * e.g. A file with the same UID may already exist. */
			if (parse_data->key_file != NULL) {
				GError *local_error = NULL;

				if (!parse_data->skip)
					migrate_parse_commit_changes (
						parse_data->type,
						parse_data->file,
						parse_data->key_file,
						NULL, &local_error);

				if (local_error != NULL) {
					g_printerr (
						"  FAILED: %s\n",
						local_error->message);
					g_error_free (local_error);
				}

				g_key_file_free (parse_data->key_file);
				parse_data->key_file = NULL;
			}

			/* Same deal for the identity key file. */
			if (parse_data->identity_key_file != NULL) {
				GError *local_error = NULL;

				if (!parse_data->skip)
					migrate_parse_commit_changes (
						parse_data->type,
						parse_data->identity_file,
						parse_data->identity_key_file,
						NULL, &local_error);

				if (local_error != NULL) {
					g_printerr (
						"  FAILED: %s\n",
						local_error->message);
					g_error_free (local_error);
				}

				g_key_file_free (parse_data->identity_key_file);
				parse_data->identity_key_file = NULL;
			}

			/* Same deal for the transport key file. */
			if (parse_data->transport_key_file != NULL) {
				GError *local_error = NULL;

				if (!parse_data->skip)
					migrate_parse_commit_changes (
						parse_data->type,
						parse_data->transport_file,
						parse_data->transport_key_file,
						NULL, &local_error);

				if (local_error != NULL) {
					g_printerr (
						"  FAILED: %s\n",
						local_error->message);
					g_error_free (local_error);
				}

				g_key_file_free (parse_data->transport_key_file);
				parse_data->transport_key_file = NULL;
			}

			/* The collection key file is optional anyway. */
			if (parse_data->collection_key_file != NULL) {
				GError *local_error = NULL;

				if (!parse_data->skip)
					migrate_parse_commit_changes (
						parse_data->type,
						parse_data->collection_file,
						parse_data->collection_key_file,
						NULL, &local_error);

				if (local_error != NULL) {
					g_printerr (
						"  FAILED: %s\n",
						local_error->message);
					g_error_free (local_error);
				}

				g_key_file_free (parse_data->collection_key_file);
				parse_data->collection_key_file = NULL;
			}

			if (parse_data->file != NULL) {
				g_object_unref (parse_data->file);
				parse_data->file = NULL;
			}

			if (parse_data->identity_file != NULL) {
				g_object_unref (parse_data->identity_file);
				parse_data->identity_file = NULL;
			}

			if (parse_data->transport_file != NULL) {
				g_object_unref (parse_data->transport_file);
				parse_data->transport_file = NULL;
			}

			if (parse_data->collection_file != NULL) {
				g_object_unref (parse_data->collection_file);
				parse_data->collection_file = NULL;
			}

			parse_data->skip = FALSE;
		}
		return;
	}

	if (g_strcmp0 (element_name, "addr-spec") == 0) {
		if (parse_data->state == PARSE_STATE_IN_IDENTITY_ADDR_SPEC)
			parse_data->state = PARSE_STATE_IN_IDENTITY;
		return;
	}

	if (g_strcmp0 (element_name, "auto-bcc") == 0) {
		if (parse_data->state == PARSE_STATE_IN_AUTO_BCC)
			parse_data->state = PARSE_STATE_IN_ACCOUNT;
		return;
	}

	if (g_strcmp0 (element_name, "auto-cc") == 0) {
		if (parse_data->state == PARSE_STATE_IN_AUTO_CC)
			parse_data->state = PARSE_STATE_IN_ACCOUNT;
		return;
	}

	if (g_strcmp0 (element_name, "drafts-folder") == 0) {
		if (parse_data->state == PARSE_STATE_IN_DRAFTS_FOLDER)
			parse_data->state = PARSE_STATE_IN_ACCOUNT;
		return;
	}

	if (g_strcmp0 (element_name, "encrypt-key-id") == 0) {
		if (parse_data->state == PARSE_STATE_IN_SMIME_ENCRYPT_KEY_ID)
			parse_data->state = PARSE_STATE_IN_SMIME;
		return;
	}

	if (g_strcmp0 (element_name, "identity") == 0) {
		if (parse_data->state == PARSE_STATE_IN_IDENTITY)
			parse_data->state = PARSE_STATE_IN_ACCOUNT;
		return;
	}

	if (g_strcmp0 (element_name, "key-id") == 0) {
		if (parse_data->state == PARSE_STATE_IN_PGP_KEY_ID)
			parse_data->state = PARSE_STATE_IN_PGP;
		return;
	}

	if (g_strcmp0 (element_name, "name") == 0) {
		if (parse_data->state == PARSE_STATE_IN_IDENTITY_NAME)
			parse_data->state = PARSE_STATE_IN_IDENTITY;
		return;
	}

	if (g_strcmp0 (element_name, "organization") == 0) {
		if (parse_data->state == PARSE_STATE_IN_IDENTITY_ORGANIZATION)
			parse_data->state = PARSE_STATE_IN_IDENTITY;
		return;
	}

	if (g_strcmp0 (element_name, "pgp") == 0) {
		if (parse_data->state == PARSE_STATE_IN_PGP)
			parse_data->state = PARSE_STATE_IN_ACCOUNT;
		return;
	}

	if (g_strcmp0 (element_name, "receipt-policy") == 0) {
		if (parse_data->state == PARSE_STATE_IN_RECEIPT_POLICY)
			parse_data->state = PARSE_STATE_IN_ACCOUNT;
		return;
	}

	if (g_strcmp0 (element_name, "recipients") == 0) {
		if (parse_data->state == PARSE_STATE_IN_AUTO_BCC_RECIPIENTS)
			parse_data->state = PARSE_STATE_IN_AUTO_BCC;
		if (parse_data->state == PARSE_STATE_IN_AUTO_CC_RECIPIENTS)
			parse_data->state = PARSE_STATE_IN_AUTO_CC;
		return;
	}

	if (g_strcmp0 (element_name, "reply-to") == 0) {
		if (parse_data->state == PARSE_STATE_IN_IDENTITY_REPLY_TO)
			parse_data->state = PARSE_STATE_IN_IDENTITY;
		return;
	}

	if (g_strcmp0 (element_name, "sent-folder") == 0) {
		if (parse_data->state == PARSE_STATE_IN_SENT_FOLDER)
			parse_data->state = PARSE_STATE_IN_ACCOUNT;
		return;
	}

	if (g_strcmp0 (element_name, "signature") == 0) {
		if (parse_data->state == PARSE_STATE_IN_IDENTITY_SIGNATURE)
			parse_data->state = PARSE_STATE_IN_IDENTITY;
		return;
	}

	if (g_strcmp0 (element_name, "sign-key-id") == 0) {
		if (parse_data->state == PARSE_STATE_IN_SMIME_SIGN_KEY_ID)
			parse_data->state = PARSE_STATE_IN_SMIME;
		return;
	}

	if (g_strcmp0 (element_name, "smime") == 0) {
		if (parse_data->state == PARSE_STATE_IN_SMIME)
			parse_data->state = PARSE_STATE_IN_ACCOUNT;
		return;
	}

	if (g_strcmp0 (element_name, "source") == 0) {
		if (parse_data->state == PARSE_STATE_IN_MAIL_SOURCE)
			parse_data->state = PARSE_STATE_IN_ACCOUNT;
		return;
	}

	if (g_strcmp0 (element_name, "transport") == 0) {
		if (parse_data->state == PARSE_STATE_IN_MAIL_TRANSPORT)
			parse_data->state = PARSE_STATE_IN_ACCOUNT;
		return;
	}

	if (g_strcmp0 (element_name, "url") == 0) {
		if (parse_data->state == PARSE_STATE_IN_MAIL_SOURCE_URL)
			parse_data->state = PARSE_STATE_IN_MAIL_SOURCE;
		if (parse_data->state == PARSE_STATE_IN_MAIL_TRANSPORT_URL)
			parse_data->state = PARSE_STATE_IN_MAIL_TRANSPORT;
		return;
	}
}

static void
migrate_parse_account_xml_text (GMarkupParseContext *context,
                                const gchar *text,
                                gsize text_len,
                                gpointer user_data,
                                GError **error)
{
	ParseData *parse_data = user_data;

	switch (parse_data->state) {
		case PARSE_STATE_IN_AUTO_BCC_RECIPIENTS:
			/* Disregard the recipient list if
			 * we're not going to auto-BCC them. */
			if (parse_data->auto_bcc)
				migrate_parse_recipients (
					parse_data, "Bcc", text);
			break;

		case PARSE_STATE_IN_AUTO_CC_RECIPIENTS:
			/* Disregard the recipient list if
			 * we're not going to auto-CC them. */
			if (parse_data->auto_cc)
				migrate_parse_recipients (
					parse_data, "Cc", text);
			break;

		case PARSE_STATE_IN_DRAFTS_FOLDER:
			g_key_file_set_string (
				parse_data->identity_key_file,
				E_SOURCE_EXTENSION_MAIL_COMPOSITION,
				"DraftsFolder", text);
			break;

		case PARSE_STATE_IN_SMIME_ENCRYPT_KEY_ID:
			g_key_file_set_string (
				parse_data->identity_key_file,
				E_SOURCE_EXTENSION_SMIME,
				"EncryptionCertificate", text);
			break;

		case PARSE_STATE_IN_IDENTITY_ADDR_SPEC:
			g_key_file_set_string (
				parse_data->identity_key_file,
				E_SOURCE_EXTENSION_MAIL_IDENTITY,
				"Address", text);
			break;

		case PARSE_STATE_IN_IDENTITY_NAME:
			g_key_file_set_string (
				parse_data->identity_key_file,
				E_SOURCE_EXTENSION_MAIL_IDENTITY,
				"Name", text);
			break;

		case PARSE_STATE_IN_IDENTITY_ORGANIZATION:
			g_key_file_set_string (
				parse_data->identity_key_file,
				E_SOURCE_EXTENSION_MAIL_IDENTITY,
				"Organization", text);
			break;

		case PARSE_STATE_IN_IDENTITY_REPLY_TO:
			g_key_file_set_string (
				parse_data->identity_key_file,
				E_SOURCE_EXTENSION_MAIL_IDENTITY,
				"ReplyTo", text);
			break;

		case PARSE_STATE_IN_MAIL_SOURCE_URL:
			/* XXX Workaround for so-called "send-only"
			 *     accounts, which have no source URL.
			 *     Their backend name is "none". */
			if (text != NULL && *text == '\0')
				text = "none:";

			migrate_parse_url (
				parse_data,
				parse_data->key_file,
				parse_data->file,
				E_SOURCE_EXTENSION_MAIL_ACCOUNT,
				text, error);
			break;

		case PARSE_STATE_IN_MAIL_TRANSPORT_URL:
			migrate_parse_url (
				parse_data,
				parse_data->transport_key_file,
				parse_data->transport_file,
				E_SOURCE_EXTENSION_MAIL_TRANSPORT,
				text, error);
			break;

		case PARSE_STATE_IN_PGP_KEY_ID:
			g_key_file_set_string (
				parse_data->identity_key_file,
				E_SOURCE_EXTENSION_OPENPGP,
				"KeyId", text);
			break;

		case PARSE_STATE_IN_SENT_FOLDER:
			g_key_file_set_string (
				parse_data->identity_key_file,
				E_SOURCE_EXTENSION_MAIL_SUBMISSION,
				"SentFolder", text);
			break;

		case PARSE_STATE_IN_SMIME_SIGN_KEY_ID:
			g_key_file_set_string (
				parse_data->identity_key_file,
				E_SOURCE_EXTENSION_SMIME,
				"SigningCertificate", text);
			break;

		default:
			break;
	}
}

static GMarkupParser account_xml_parser = {
	migrate_parse_account_xml_start_element,
	migrate_parse_account_xml_end_element,
	migrate_parse_account_xml_text,
	NULL,  /* passthrough */
	NULL   /* error */
};

static void
migrate_parse_signature (ParseData *parse_data,
                         const gchar *element_name,
                         const gchar **attribute_names,
                         const gchar **attribute_values,
                         GError **error)
{
	const gchar *uid;
	const gchar *name;
	const gchar *format;
	const gchar *config_dir;
	gchar *directory;
	gchar *absolute_path;
	gboolean autogenerated;
	gboolean success;

	success = g_markup_collect_attributes (
		element_name,
		attribute_names,
		attribute_values,
		error,
		G_MARKUP_COLLECT_STRING,
		"uid", &uid,
		G_MARKUP_COLLECT_STRING,
		"name", &name,
		G_MARKUP_COLLECT_BOOLEAN,
		"auto", &autogenerated,
		G_MARKUP_COLLECT_STRING |
		G_MARKUP_COLLECT_OPTIONAL,
		"format", &format,
		G_MARKUP_COLLECT_INVALID);

	if (!success)
		return;

	/* Skip the "autogenerated" signature. */
	if (autogenerated)
		return;

	parse_data->file = e_server_side_source_new_user_file (uid);

	config_dir = e_get_user_config_dir ();
	directory = g_build_filename (config_dir, "signatures", NULL);
	absolute_path = g_build_filename (directory, uid, NULL);
	parse_data->signature_file = g_file_new_for_path (absolute_path);
	g_mkdir_with_parents (directory, 0700);
	g_free (absolute_path);
	g_free (directory);

	/* If the file already exists, skip this source.  It may be that we
	 * already migrated it, in which case we don't want to overwrite it. */
	if (g_file_query_exists (parse_data->file, NULL))
		return;

	parse_data->key_file = g_key_file_new ();

	g_key_file_set_string (
		parse_data->key_file,
		E_SOURCE_GROUP_NAME,
		"DisplayName", name);

	g_key_file_set_string (
		parse_data->key_file,
		E_SOURCE_EXTENSION_MAIL_SIGNATURE,
		"MimeType", format);
}

static void
migrate_parse_signature_xml_start_element (GMarkupParseContext *context,
                                           const gchar *element_name,
                                           const gchar **attribute_names,
                                           const gchar **attribute_values,
                                           gpointer user_data,
                                           GError **error)
{
	ParseData *parse_data = user_data;

	if (g_strcmp0 (element_name, "filename") == 0) {
		if (parse_data->state != PARSE_STATE_IN_SIGNATURE)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_FILENAME;

		g_markup_collect_attributes (
			element_name,
			attribute_names,
			attribute_values,
			error,
			G_MARKUP_COLLECT_BOOLEAN |
			G_MARKUP_COLLECT_OPTIONAL,
			"script", &parse_data->is_script,
			G_MARKUP_COLLECT_INVALID);

		return;
	}

	if (g_strcmp0 (element_name, "signature") == 0) {
		if (parse_data->state != PARSE_STATE_IN_SIGNATURES_VALUE)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_SIGNATURE;

		migrate_parse_signature (
			parse_data,
			element_name,
			attribute_names,
			attribute_values,
			error);

		return;
	}

	g_set_error (
		error, G_MARKUP_ERROR, G_MARKUP_ERROR_UNKNOWN_ELEMENT,
		"Unknown element <%s>", element_name);

	return;

invalid_content:

	g_set_error (
		error, G_MARKUP_ERROR, G_MARKUP_ERROR_INVALID_CONTENT,
		"Element <%s> at unexpected location", element_name);
}

static void
migrate_parse_signature_xml_end_element (GMarkupParseContext *context,
                                         const gchar *element_name,
                                         gpointer user_data,
                                         GError **error)
{
	ParseData *parse_data = user_data;

	if (g_strcmp0 (element_name, "filename") == 0) {
		if (parse_data->state == PARSE_STATE_IN_FILENAME) {
			parse_data->state = PARSE_STATE_IN_SIGNATURE;

			return;
		}
	}

	if (g_strcmp0 (element_name, "signature") == 0) {
		if (parse_data->state == PARSE_STATE_IN_SIGNATURE) {
			parse_data->state = PARSE_STATE_IN_SIGNATURES_VALUE;

			/* Clean up <signature> tag data. */

			/* The key file will be NULL if we decided to skip it.
			 * e.g. A file with the same UID may already exist. */
			if (parse_data->key_file != NULL) {
				GError *local_error = NULL;

				if (!parse_data->skip)
					migrate_parse_commit_changes (
						parse_data->type,
						parse_data->file,
						parse_data->key_file,
						NULL, &local_error);

				if (local_error != NULL) {
					g_printerr (
						"  FAILED: %s\n",
						local_error->message);
					g_error_free (local_error);
				}

				g_key_file_free (parse_data->key_file);
				parse_data->key_file = NULL;
			}

			if (parse_data->file != NULL) {
				g_object_unref (parse_data->file);
				parse_data->file = NULL;
			}

			parse_data->skip = FALSE;

			return;
		}
	}
}

static void
migrate_parse_signature_xml_text (GMarkupParseContext *context,
                                  const gchar *text,
                                  gsize text_len,
                                  gpointer user_data,
                                  GError **error)
{
	ParseData *parse_data = user_data;

	if (parse_data->state == PARSE_STATE_IN_FILENAME) {
		GFile *old_signature_file;
		GFile *new_signature_file;
		const gchar *data_dir;
		gchar *absolute_path;

		/* Note we're moving the signature files
		 * from $XDG_DATA_HOME to $XDG_CONFIG_HOME. */
		data_dir = e_get_user_data_dir ();

		/* Text should be either an absolute file name
		 * or a base file name with no path components. */
		if (g_path_is_absolute (text))
			absolute_path = g_strdup (text);
		else
			absolute_path = g_build_filename (
				data_dir, "signatures", text, NULL);

		old_signature_file = g_file_new_for_path (absolute_path);
		new_signature_file = parse_data->signature_file;
		parse_data->signature_file = NULL;

		/* If the signature is a script, we symlink to it.
		 * Otherwise we move and rename the regular file.
		 * Also ignore errors here, otherwise it stops whole migration.
		 */
		if (parse_data->is_script)
			g_file_make_symbolic_link (
				new_signature_file,
				absolute_path, NULL, NULL);
		else
			g_file_move (
				old_signature_file,
				new_signature_file,
				G_FILE_COPY_NONE,
				NULL, NULL, NULL, NULL);

		g_object_unref (old_signature_file);
		g_object_unref (new_signature_file);
		g_free (absolute_path);
	}
}

static GMarkupParser signature_xml_parser = {
	migrate_parse_signature_xml_start_element,
	migrate_parse_signature_xml_end_element,
	migrate_parse_signature_xml_text,
	NULL,  /* passthrough */
	NULL   /* error */
};

static void
migrate_parse_local_calendar_property (ParseData *parse_data,
                                       const gchar *property_name,
                                       const gchar *property_value)
{
	if (g_strcmp0 (property_name, "custom-file") == 0) {
		gchar *uri;

		/* Property value is a local filename.  Convert it to a
		 * "file://" URI.
		 *
		 * Note: The key is named "CustomFile" instead of, say,
		 * "CustomURI" because the corresponding ESourceExtension
		 * property is a GFile.  The fact that ESource saves GFile
		 * properties as URI strings is an implementation detail. */
		uri = g_filename_to_uri (property_value, NULL, NULL);
		if (uri != NULL) {
			g_key_file_set_string (
				parse_data->key_file,
				E_SOURCE_EXTENSION_LOCAL_BACKEND,
				"CustomFile", uri);
			g_free (uri);
		}
	}
}

static void
migrate_parse_local_source (ParseData *parse_data)
{
	if (parse_data->type != PARSE_TYPE_ADDRESSBOOK)
		parse_data->property_func =
			migrate_parse_local_calendar_property;

	/* Local ADDRESS BOOK Backend has no special properties to parse. */
}

static void
migrate_parse_caldav_property (ParseData *parse_data,
                               const gchar *property_name,
                               const gchar *property_value)
{
	if (g_strcmp0 (property_name, "autoschedule") == 0) {
		g_key_file_set_boolean (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEBDAV_BACKEND,
			"CalendarAutoSchedule",
			is_true (property_value));

	} else if (g_strcmp0 (property_name, "usermail") == 0) {
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEBDAV_BACKEND,
			"EmailAddress", property_value);
	}
}

static void
migrate_parse_caldav_source (ParseData *parse_data)
{
	if (parse_data->soup_uri->host != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"Host", parse_data->soup_uri->host);

	/* We may override this later if we see an "ssl" property. */
	if (parse_data->soup_uri->port == 0)
		parse_data->soup_uri->port = 80;

	g_key_file_set_integer (
		parse_data->key_file,
		E_SOURCE_EXTENSION_AUTHENTICATION,
		"Port", parse_data->soup_uri->port);

	if (parse_data->soup_uri->user != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"User", parse_data->soup_uri->user);

	if (parse_data->soup_uri->path != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEBDAV_BACKEND,
			"ResourcePath", parse_data->soup_uri->path);

	if (parse_data->soup_uri->query != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEBDAV_BACKEND,
			"ResourceQuery", parse_data->soup_uri->query);

	parse_data->property_func = migrate_parse_caldav_property;
}

static void
migrate_parse_google_calendar_property (ParseData *parse_data,
                                        const gchar *property_name,
                                        const gchar *property_value)
{
	if (g_strcmp0 (property_name, "username") == 0) {
		gchar *path;

		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"User", property_value);

		path = g_strdup_printf (
			"/calendar/dav/%s/events", property_value);

		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEBDAV_BACKEND,
			"ResourcePath", path);

		g_free (path);
	}
}

static void
migrate_parse_google_contacts_property (ParseData *parse_data,
                                        const gchar *property_name,
                                        const gchar *property_value)
{
	if (g_strcmp0 (property_name, "refresh-interval") == 0) {
		guint64 interval_seconds;

		interval_seconds =
			g_ascii_strtoull (property_value, NULL, 10);

		if (interval_seconds >= 60) {
			g_key_file_set_boolean (
				parse_data->key_file,
				E_SOURCE_EXTENSION_REFRESH,
				"Enabled", TRUE);
			g_key_file_set_uint64 (
				parse_data->key_file,
				E_SOURCE_EXTENSION_REFRESH,
				"IntervalMinutes",
				interval_seconds / 60);
		}

	} else if (g_strcmp0 (property_name, "username") == 0) {
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"User", property_value);
	}
}

static void
migrate_parse_google_source (ParseData *parse_data)
{
	if (parse_data->type == PARSE_TYPE_ADDRESSBOOK)
		parse_data->property_func =
			migrate_parse_google_contacts_property;

	else {
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"Host", "www.google.com");

		g_key_file_set_integer (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"Port", 443);

		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_SECURITY,
			"Method", "tls");

		parse_data->property_func =
			migrate_parse_google_calendar_property;
	}
}

static void
migrate_parse_ldap_property (ParseData *parse_data,
                             const gchar *property_name,
                             const gchar *property_value)
{
	if (g_strcmp0 (property_name, "can-browse") == 0) {
		g_key_file_set_boolean (
			parse_data->key_file,
			E_SOURCE_EXTENSION_LDAP_BACKEND,
			"CanBrowse",
			is_true (property_value));

	/* This is an integer value, but we can use the string as is. */
	} else if (g_strcmp0 (property_name, "limit") == 0) {
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_LDAP_BACKEND,
			"Limit", property_value);
	}
}

static void
migrate_parse_ldap_source (ParseData *parse_data)
{
	if (parse_data->soup_uri->host != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"Host", parse_data->soup_uri->host);

	if (parse_data->soup_uri->port != 0)
		g_key_file_set_integer (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"Port", parse_data->soup_uri->port);

	if (parse_data->soup_uri->user != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"User", parse_data->soup_uri->user);

	/* Skip the leading slash on the URI path to get the RootDn. */
	if (parse_data->soup_uri->path != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_LDAP_BACKEND,
			"RootDn", parse_data->soup_uri->path + 1);

	if (g_strcmp0 (parse_data->soup_uri->query, "?sub?") == 0)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_LDAP_BACKEND,
			"Scope", "subtree");

	if (g_strcmp0 (parse_data->soup_uri->query, "?one?") == 0)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_LDAP_BACKEND,
			"Scope", "onelevel");

	parse_data->property_func = migrate_parse_ldap_property;
}

static void
migrate_parse_vcf_source (ParseData *parse_data)
{
	if (parse_data->soup_uri->path != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_VCF_BACKEND,
			"Path", parse_data->soup_uri->path);

	/* VCF Backend has no special properties to parse. */
}

static void
migrate_parse_weather_property (ParseData *parse_data,
                                const gchar *property_name,
                                const gchar *property_value)
{
	/* XXX Temperature property was replaced by units... I think. */
	if (g_strcmp0 (property_name, "temperature") == 0) {
		gboolean metric;

		metric = (g_strcmp0 (property_value, "fahrenheit") != 0);

		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEATHER_BACKEND,
			"Units", metric ? "metric" : "imperial");

	} else if (g_strcmp0 (property_name, "units") == 0) {
		gboolean metric;

		metric = (g_strcmp0 (property_value, "metric") == 0);

		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEATHER_BACKEND,
			"Units", metric ? "metric" : "imperial");
	}
}

static void
migrate_parse_weather_source (ParseData *parse_data)
{
	/* Oh man, we actually try to shove a weather location into
	 * a URI!  The station code winds up as the host component,
	 * and the location name winds up as the path component. */
	if (parse_data->soup_uri->host != NULL) {
		gchar *location;

		if (parse_data->soup_uri->path != NULL)
			location = g_strconcat (
				parse_data->soup_uri->host,
				parse_data->soup_uri->path, NULL);
		else
			location = g_strdup (parse_data->soup_uri->host);

		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEATHER_BACKEND,
			"Location", location);

		g_free (location);
	}

	parse_data->property_func = migrate_parse_weather_property;
}

static void
migrate_parse_webcal_source (ParseData *parse_data)
{
	if (parse_data->soup_uri->host != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"Host", parse_data->soup_uri->host);

	/* We may override this later if we see an "ssl" property. */
	if (parse_data->soup_uri->port == 0)
		parse_data->soup_uri->port = 80;

	g_key_file_set_integer (
		parse_data->key_file,
		E_SOURCE_EXTENSION_AUTHENTICATION,
		"Port", parse_data->soup_uri->port);

	if (parse_data->soup_uri->user != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"User", parse_data->soup_uri->user);

	if (parse_data->soup_uri->path != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEBDAV_BACKEND,
			"ResourcePath", parse_data->soup_uri->path);

	if (parse_data->soup_uri->query != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEBDAV_BACKEND,
			"ResourceQuery", parse_data->soup_uri->query);

	/* Webcal Backend has no special properties to parse. */
}

static void
migrate_parse_webdav_property (ParseData *parse_data,
                               const gchar *property_name,
                               const gchar *property_value)
{
	if (g_strcmp0 (property_name, "avoid_ifmatch") == 0) {
		g_key_file_set_boolean (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEBDAV_BACKEND,
			"AvoidIfmatch",
			is_true (property_value));
	}
}

static void
migrate_parse_webdav_source (ParseData *parse_data)
{
	if (parse_data->soup_uri->host != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"Host", parse_data->soup_uri->host);

	if (parse_data->soup_uri->port != 0)
		g_key_file_set_integer (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"Port", parse_data->soup_uri->port);

	if (parse_data->soup_uri->user != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"User", parse_data->soup_uri->user);

	if (parse_data->soup_uri->path != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEBDAV_BACKEND,
			"ResourcePath", parse_data->soup_uri->path);

	if (parse_data->soup_uri->query != NULL)
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_WEBDAV_BACKEND,
			"ResourceQuery", parse_data->soup_uri->query);

	parse_data->property_func = migrate_parse_webdav_property;
}

static void
migrate_parse_group (ParseData *parse_data,
                     const gchar *element_name,
                     const gchar **attribute_names,
                     const gchar **attribute_values,
                     GError **error)
{
	const gchar *base_uri;
	gboolean success;

	success = g_markup_collect_attributes (
		element_name,
		attribute_names,
		attribute_values,
		error,
		G_MARKUP_COLLECT_STRING,
		"uid", NULL,
		G_MARKUP_COLLECT_STRING,
		"name", NULL,
		G_MARKUP_COLLECT_STRING,
		"base_uri", &base_uri,
		G_MARKUP_COLLECT_BOOLEAN |
		G_MARKUP_COLLECT_OPTIONAL,
		"readonly", NULL,
		G_MARKUP_COLLECT_INVALID);

	if (!success)
		return;

	/* Convert "file://" schemes to "local:". */
	if (g_strcmp0 (base_uri, "file://") == 0)
		base_uri = "local:";

	parse_data->base_uri = g_strdup (base_uri);
}

static void
migrate_parse_source (ParseData *parse_data,
                      const gchar *element_name,
                      const gchar **attribute_names,
                      const gchar **attribute_values,
                      GError **error)
{
	const gchar *uid;
	const gchar *name;
	const gchar *color_spec;
	const gchar *group_name;
	const gchar *absolute_uri;
	const gchar *relative_uri;
	gchar *backend_name;
	gchar *parent_name;
	gchar *uri_string;
	gchar *cp;
	gboolean success;
	gboolean is_google_calendar;

	success = g_markup_collect_attributes (
		element_name,
		attribute_names,
		attribute_values,
		error,
		G_MARKUP_COLLECT_STRING,
		"uid", &uid,
		G_MARKUP_COLLECT_STRING,
		"name", &name,
		G_MARKUP_COLLECT_STRING |
		G_MARKUP_COLLECT_OPTIONAL,
		"color_spec", &color_spec,
		G_MARKUP_COLLECT_STRING,
		"relative_uri", &relative_uri,
		G_MARKUP_COLLECT_STRING |
		G_MARKUP_COLLECT_OPTIONAL,
		"uri", &absolute_uri,
		G_MARKUP_COLLECT_INVALID);

	if (!success)
		return;

	/* Don't try and migrate the "system" sources, as
	 * we'll defer to the built-in "system-*" key files. */
	if (g_strcmp0 (relative_uri, "system") == 0)
		return;

	/* Also skip any sources with a "contacts://" base URI, which
	 * should just be "Birthdays & Anniversaries".  We'll reset to
	 * the built-in key file. */
	if (g_strcmp0 (parse_data->base_uri, "contacts://") == 0)
		return;

	/* Also skip any sources for groupware extensions, as these are
	 * no longer saved to disk.  We do have a mechanism in place for
	 * remembering the UIDs of memory-only sources so that cached
	 * data can be reused, but let's not bother with it here.  Let
	 * the sources be set up fresh. */
	if (base_uri_is_groupware (parse_data->base_uri))
		return;

	switch (parse_data->type) {
		case PARSE_TYPE_ADDRESSBOOK:
			group_name = E_SOURCE_EXTENSION_ADDRESS_BOOK;
			break;
		case PARSE_TYPE_CALENDAR:
			group_name = E_SOURCE_EXTENSION_CALENDAR;
			break;
		case PARSE_TYPE_TASKS:
			group_name = E_SOURCE_EXTENSION_TASK_LIST;
			break;
		case PARSE_TYPE_MEMOS:
			group_name = E_SOURCE_EXTENSION_MEMO_LIST;
			break;
		default:
			g_return_if_reached ();
	}

	parse_data->file = e_server_side_source_new_user_file (uid);

	/* If the file already exists, skip this source.  It may be that we
	 * already migrated it, in which case we don't want to overwrite it. */
	if (g_file_query_exists (parse_data->file, NULL))
		return;

	parse_data->key_file = g_key_file_new ();

	/* Trim ':' or '://' off the base_uri to get the backend name. */
	backend_name = g_strdup (parse_data->base_uri);
	if ((cp = strchr (backend_name, ':')) != NULL)
		*cp = '\0';

	/* The parent name is generally the backend name + "-stub". */
	parent_name = g_strdup_printf ("%s-stub", backend_name);

	g_key_file_set_string (
		parse_data->key_file,
		E_SOURCE_GROUP_NAME,
		"DisplayName", name);

	g_key_file_set_string (
		parse_data->key_file,
		E_SOURCE_GROUP_NAME,
		"Parent", parent_name);

	if (color_spec != NULL)
		g_key_file_set_string (
			parse_data->key_file, group_name,
			"Color", color_spec);

	is_google_calendar =
		(parse_data->type == PARSE_TYPE_CALENDAR) &&
		(g_strcmp0 (parse_data->base_uri, "google://") == 0);

	/* For Google Calendar sources we override the backend name. */
	if (is_google_calendar)
		g_key_file_set_string (
			parse_data->key_file, group_name,
			"BackendName", "caldav");
	else
		g_key_file_set_string (
			parse_data->key_file, group_name,
			"BackendName", backend_name);

	g_free (backend_name);
	g_free (parent_name);

	/* Prefer absolute URIs over relative URIs.  All these
	 * other strange rules are for backward-compatibility. */
	if (absolute_uri != NULL)
		uri_string = g_strdup (absolute_uri);
	else if (g_str_has_suffix (parse_data->base_uri, "/"))
		uri_string = g_strconcat (
			parse_data->base_uri, relative_uri, NULL);
	else if (g_strcmp0 (parse_data->base_uri, "local:") == 0)
		uri_string = g_strconcat (
			parse_data->base_uri, relative_uri, NULL);
	else
		uri_string = g_strconcat (
			parse_data->base_uri, "/", relative_uri, NULL);

	parse_data->soup_uri = soup_uri_new (uri_string);

	/* Mangle the URI to not contain invalid characters.  We'll need
	 * this later to rename the source's cache and data directories. */
	parse_data->mangled_uri = g_strdelimit (uri_string, ":/", '_');

	/* g_strdelimit() modifies the input string in place, so ParseData
	 * now owns 'uri_string'.  Clear the pointer to emphasize that. */
	uri_string = NULL;

	if (parse_data->soup_uri == NULL) {
		g_warning (
			"  Failed to parse source URI: %s",
			(absolute_uri != NULL) ? absolute_uri : relative_uri);
		g_key_file_free (parse_data->key_file);
		parse_data->key_file = NULL;
		return;
	}

	if (g_strcmp0 (parse_data->base_uri, "local:") == 0)
		migrate_parse_local_source (parse_data);

	else if (g_strcmp0 (parse_data->base_uri, "caldav://") == 0)
		migrate_parse_caldav_source (parse_data);

	else if (g_strcmp0 (parse_data->base_uri, "google://") == 0)
		migrate_parse_google_source (parse_data);

	else if (g_strcmp0 (parse_data->base_uri, "ldap://") == 0)
		migrate_parse_ldap_source (parse_data);

	else if (g_strcmp0 (parse_data->base_uri, "vcf://") == 0)
		migrate_parse_vcf_source (parse_data);

	else if (g_strcmp0 (parse_data->base_uri, "weather://") == 0)
		migrate_parse_weather_source (parse_data);

	else if (g_strcmp0 (parse_data->base_uri, "webcal://") == 0)
		migrate_parse_webcal_source (parse_data);

	else if (g_strcmp0 (parse_data->base_uri, "webdav://") == 0)
		migrate_parse_webdav_source (parse_data);

	migrate_keyring_entry (
		uid,
		parse_data->soup_uri->user,
		parse_data->soup_uri->host,
		parse_data->soup_uri->scheme);
}

static void
migrate_parse_property (ParseData *parse_data,
                        const gchar *element_name,
                        const gchar **attribute_names,
                        const gchar **attribute_values,
                        GError **error)
{
	const gchar *property_name;
	const gchar *property_value;
	gboolean success;

	success = g_markup_collect_attributes (
		element_name,
		attribute_names,
		attribute_values,
		error,
		G_MARKUP_COLLECT_STRING,
		"name", &property_name,
		G_MARKUP_COLLECT_STRING,
		"value", &property_value,
		G_MARKUP_COLLECT_INVALID);

	if (!success)
		return;

	if (g_strcmp0 (property_name, "alarm") == 0) {
		g_key_file_set_boolean (
			parse_data->key_file,
			E_SOURCE_EXTENSION_ALARMS,
			"IncludeMe",
			is_true (property_value));

	} else if (g_strcmp0 (property_name, "auth") == 0) {
		if (is_true (property_value))
			g_key_file_set_string (
				parse_data->key_file,
				E_SOURCE_EXTENSION_AUTHENTICATION,
				"Method", "plain/password");
		else if (is_false (property_value))
			g_key_file_set_string (
				parse_data->key_file,
				E_SOURCE_EXTENSION_AUTHENTICATION,
				"Method", "none");
		else
			g_key_file_set_string (
				parse_data->key_file,
				E_SOURCE_EXTENSION_AUTHENTICATION,
				"Method", property_value);

	} else if (g_strcmp0 (property_name, "completion") == 0) {
		g_key_file_set_boolean (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTOCOMPLETE,
			"IncludeMe",
			is_true (property_value));

	/* If we see a "goa-account-id" property, skip the entire
	 * source and let the online-accounts module recreate it. */
	} else if (g_strcmp0 (property_name, "goa-account-id") == 0) {
		parse_data->skip = TRUE;

	} else if (g_strcmp0 (property_name, "last-notified") == 0) {
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_ALARMS,
			"LastNotified", property_value);

	} else if (g_strcmp0 (property_name, "offline_sync") == 0) {
		g_key_file_set_boolean (
			parse_data->key_file,
			E_SOURCE_EXTENSION_OFFLINE,
			"StaySynchronized",
			is_true (property_value));

	} else if (g_strcmp0 (property_name, "refresh") == 0) {
		g_key_file_set_boolean (
			parse_data->key_file,
			E_SOURCE_EXTENSION_REFRESH,
			"Enabled", TRUE);
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_REFRESH,
			"IntervalMinutes", property_value);

	} else if (g_strcmp0 (property_name, "remember_password") == 0) {
		g_key_file_set_boolean (
			parse_data->key_file,
			E_SOURCE_EXTENSION_AUTHENTICATION,
			"RememberPassword",
			is_true (property_value));

	} else if (g_strcmp0 (property_name, "ssl") == 0) {
		if (is_true (property_value))
			g_key_file_set_string (
				parse_data->key_file,
				E_SOURCE_EXTENSION_SECURITY,
				"Method", "tls");
		else if (is_false (property_value))
			g_key_file_set_string (
				parse_data->key_file,
				E_SOURCE_EXTENSION_SECURITY,
				"Method", "none");

		/* These next two are LDAP-specific. */
		else if (g_strcmp0 (property_value, "always") == 0)
			g_key_file_set_string (
				parse_data->key_file,
				E_SOURCE_EXTENSION_SECURITY,
				"Method", "starttls");
		else if (g_strcmp0 (property_value, "whenever_possible") == 0)
			g_key_file_set_string (
				parse_data->key_file,
				E_SOURCE_EXTENSION_SECURITY,
				"Method", "ldaps");

		/* For WebDAV-based backends we set the port to 80
		 * (http://) by default.  If we see that and we're
		 * using a secure connection, bump the port to 443
		 * (https://). */
		if (parse_data->soup_uri->port == 80)
			if (is_true (property_value))
				g_key_file_set_integer (
					parse_data->key_file,
					E_SOURCE_EXTENSION_AUTHENTICATION,
					"Port", 443);

	} else if (g_strcmp0 (property_name, "use_ssl") == 0) {
		g_key_file_set_string (
			parse_data->key_file,
			E_SOURCE_EXTENSION_SECURITY,
			"Method",
			is_true (property_value) ?
			"tls" : "none");

		/* For WebDAV-based backends we set the port to 80
		 * (http://) by default.  If we see that and we're
		 * using a secure connection, bump the port to 443
		 * (https://). */
		if (parse_data->soup_uri->port == 80)
			if (is_true (property_value))
				g_key_file_set_integer (
					parse_data->key_file,
					E_SOURCE_EXTENSION_AUTHENTICATION,
					"Port", 443);

	} else if (g_strcmp0 (property_name, "use-in-contacts-calendar") == 0) {
		g_key_file_set_boolean (
			parse_data->key_file,
			E_SOURCE_EXTENSION_CONTACTS_BACKEND,
			"IncludeMe",
			is_true (property_value));

	} else if (parse_data->property_func != NULL) {
		parse_data->property_func (
			parse_data, property_name, property_value);
	}
}

static void
migrate_parse_source_xml_start_element (GMarkupParseContext *context,
                                        const gchar *element_name,
                                        const gchar **attribute_names,
                                        const gchar **attribute_values,
                                        gpointer user_data,
                                        GError **error)
{
	ParseData *parse_data = user_data;

	if (g_strcmp0 (element_name, "group") == 0) {
		if (parse_data->state != PARSE_STATE_IN_SOURCES_VALUE)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_GROUP;

		migrate_parse_group (
			parse_data,
			element_name,
			attribute_names,
			attribute_values,
			error);

		return;
	}

	if (g_strcmp0 (element_name, "source") == 0) {
		if (parse_data->state != PARSE_STATE_IN_GROUP)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_SOURCE;

		migrate_parse_source (
			parse_data,
			element_name,
			attribute_names,
			attribute_values,
			error);

		return;
	}

	if (g_strcmp0 (element_name, "properties") == 0) {
		/* Disregard group properties, we're only
		 * interested in source properties. */
		if (parse_data->state == PARSE_STATE_IN_GROUP)
			return;

		if (parse_data->state != PARSE_STATE_IN_SOURCE)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_PROPERTIES;

		return;
	}

	if (g_strcmp0 (element_name, "property") == 0) {
		/* Disregard group properties, we're only
		 * interested in source properties. */
		if (parse_data->state == PARSE_STATE_IN_GROUP)
			return;

		if (parse_data->state != PARSE_STATE_IN_PROPERTIES)
			goto invalid_content;

		/* The key file will be NULL if we decided to skip it.
		 * e.g. A file with the same UID may already exist. */
		if (parse_data->key_file != NULL)
			migrate_parse_property (
				parse_data,
				element_name,
				attribute_names,
				attribute_values,
				error);

		return;
	}

	g_set_error (
		error, G_MARKUP_ERROR, G_MARKUP_ERROR_UNKNOWN_ELEMENT,
		"Unknown element <%s>", element_name);

	return;

invalid_content:

	g_set_error (
		error, G_MARKUP_ERROR, G_MARKUP_ERROR_INVALID_CONTENT,
		"Element <%s> at unexpected location", element_name);
}

static void
migrate_parse_source_xml_end_element (GMarkupParseContext *context,
                                      const gchar *element_name,
                                      gpointer user_data,
                                      GError **error)
{
	ParseData *parse_data = user_data;

	if (g_strcmp0 (element_name, "group") == 0) {
		if (parse_data->state == PARSE_STATE_IN_GROUP) {
			parse_data->state = PARSE_STATE_IN_SOURCES_VALUE;

			/* Clean up <group> tag data. */

			g_free (parse_data->base_uri);
			parse_data->base_uri = NULL;
		}
		return;
	}

	if (g_strcmp0 (element_name, "source") == 0) {
		if (parse_data->state == PARSE_STATE_IN_SOURCE) {
			parse_data->state = PARSE_STATE_IN_GROUP;

			/* Clean up <source> tag data. */

			/* The key file will be NULL if we decided to skip it.
			 * e.g. A file with the same UID may already exist. */
			if (parse_data->key_file != NULL) {
				GError *local_error = NULL;

				if (!parse_data->skip)
					migrate_parse_commit_changes (
						parse_data->type,
						parse_data->file,
						parse_data->key_file,
						parse_data->mangled_uri,
						&local_error);

				if (local_error != NULL) {
					g_printerr (
						"  FAILED: %s\n",
						local_error->message);
					g_error_free (local_error);
				}

				g_key_file_free (parse_data->key_file);
				parse_data->key_file = NULL;
			}

			if (parse_data->file != NULL) {
				g_object_unref (parse_data->file);
				parse_data->file = NULL;
			}

			g_free (parse_data->mangled_uri);
			parse_data->mangled_uri = NULL;

			if (parse_data->soup_uri != NULL) {
				soup_uri_free (parse_data->soup_uri);
				parse_data->soup_uri = NULL;
			}

			parse_data->property_func = NULL;

			parse_data->skip = FALSE;
		}
		return;
	}

	if (g_strcmp0 (element_name, "properties") == 0) {
		if (parse_data->state == PARSE_STATE_IN_PROPERTIES)
			parse_data->state = PARSE_STATE_IN_SOURCE;
		return;
	}
}

static GMarkupParser source_xml_parser = {
	migrate_parse_source_xml_start_element,
	migrate_parse_source_xml_end_element,
	NULL,  /* text */
	NULL,  /* passthrough */
	NULL   /* error */
};

static void
migrate_parse_gconf_xml_start_element (GMarkupParseContext *context,
                                       const gchar *element_name,
                                       const gchar **attribute_names,
                                       const gchar **attribute_values,
                                       gpointer user_data,
                                       GError **error)
{
	ParseData *parse_data = user_data;

	/* Only seen in merged XML files. */
	if (g_strcmp0 (element_name, "dir") == 0)
		return;

	if (g_strcmp0 (element_name, "gconf") == 0) {
		if (parse_data->state != PARSE_STATE_INITIAL)
			goto invalid_content;

		parse_data->state = PARSE_STATE_IN_GCONF;

		return;
	}

	if (g_strcmp0 (element_name, "entry") == 0) {
		const gchar *name;
		gboolean success;

		if (parse_data->state != PARSE_STATE_IN_GCONF)
			goto invalid_content;

		success = g_markup_collect_attributes (
			element_name,
			attribute_names,
			attribute_values,
			error,
			G_MARKUP_COLLECT_STRING,
			"name", &name,
			G_MARKUP_COLLECT_STRING,
			"mtime", NULL,
			G_MARKUP_COLLECT_STRING |
			G_MARKUP_COLLECT_OPTIONAL,
			"muser", NULL,
			G_MARKUP_COLLECT_STRING |
			G_MARKUP_COLLECT_OPTIONAL,
			"type", NULL,
			G_MARKUP_COLLECT_STRING |
			G_MARKUP_COLLECT_OPTIONAL,
			"ltype", NULL,
			G_MARKUP_COLLECT_STRING |
			G_MARKUP_COLLECT_OPTIONAL,
			"schema", NULL,
			G_MARKUP_COLLECT_STRING |
			G_MARKUP_COLLECT_OPTIONAL,
			"value", NULL,
			G_MARKUP_COLLECT_INVALID);

		if (success && g_strcmp0 (name, "accounts") == 0)
			parse_data->state = PARSE_STATE_IN_ACCOUNTS_ENTRY;

		if (success && g_strcmp0 (name, "signatures") == 0)
			parse_data->state = PARSE_STATE_IN_SIGNATURES_ENTRY;

		if (success && g_strcmp0 (name, "sources") == 0)
			parse_data->state = PARSE_STATE_IN_SOURCES_ENTRY;

		return;
	}

	if (g_strcmp0 (element_name, "li") == 0)
		return;

	if (g_strcmp0 (element_name, "stringvalue") == 0) {
		if (parse_data->state == PARSE_STATE_IN_ACCOUNTS_ENTRY)
			parse_data->state = PARSE_STATE_IN_ACCOUNTS_VALUE;

		if (parse_data->state == PARSE_STATE_IN_SIGNATURES_ENTRY)
			parse_data->state = PARSE_STATE_IN_SIGNATURES_VALUE;

		if (parse_data->state == PARSE_STATE_IN_SOURCES_ENTRY)
			parse_data->state = PARSE_STATE_IN_SOURCES_VALUE;

		return;
	}

	g_set_error (
		error, G_MARKUP_ERROR, G_MARKUP_ERROR_UNKNOWN_ELEMENT,
		"Unknown element <%s>", element_name);

	return;

invalid_content:

	g_set_error (
		error, G_MARKUP_ERROR, G_MARKUP_ERROR_INVALID_CONTENT,
		"Element <%s> at unexpected location", element_name);
}

static void
migrate_parse_gconf_xml_end_element (GMarkupParseContext *context,
                                     const gchar *element_name,
                                     gpointer user_data,
                                     GError **error)
{
	ParseData *parse_data = user_data;

	if (g_strcmp0 (element_name, "gconf") == 0) {
		if (parse_data->state == PARSE_STATE_IN_GCONF)
			parse_data->state = PARSE_STATE_INITIAL;

		return;
	}

	if (g_strcmp0 (element_name, "entry") == 0) {
		if (parse_data->state == PARSE_STATE_IN_ACCOUNTS_ENTRY)
			parse_data->state = PARSE_STATE_IN_GCONF;

		if (parse_data->state == PARSE_STATE_IN_SIGNATURES_ENTRY)
			parse_data->state = PARSE_STATE_IN_GCONF;

		if (parse_data->state == PARSE_STATE_IN_SOURCES_ENTRY)
			parse_data->state = PARSE_STATE_IN_GCONF;

		return;
	}

	if (g_strcmp0 (element_name, "stringvalue") == 0) {
		if (parse_data->state == PARSE_STATE_IN_ACCOUNTS_VALUE)
			parse_data->state = PARSE_STATE_IN_ACCOUNTS_ENTRY;

		if (parse_data->state == PARSE_STATE_IN_SIGNATURES_VALUE)
			parse_data->state = PARSE_STATE_IN_SIGNATURES_ENTRY;

		if (parse_data->state == PARSE_STATE_IN_SOURCES_VALUE)
			parse_data->state = PARSE_STATE_IN_SOURCES_ENTRY;

		return;
	}
}

static void
migrate_parse_gconf_xml_text (GMarkupParseContext *context,
                              const gchar *text,
                              gsize length,
                              gpointer user_data,
                              GError **error)
{
	ParseData *parse_data = user_data;

	/* The account and signature data is encoded XML stuffed into
	 * GConf XML (yuck!).  Fortunately GMarkupParseContext decodes
	 * the XML for us, so we just have to feed it to a nested
	 * GMarkupParseContext. */

	switch (parse_data->state) {
		case PARSE_STATE_IN_ACCOUNTS_VALUE:
			context = g_markup_parse_context_new (
				&account_xml_parser, 0, parse_data, NULL);
			break;

		case PARSE_STATE_IN_SIGNATURES_VALUE:
			context = g_markup_parse_context_new (
				&signature_xml_parser, 0, parse_data, NULL);
			break;

		case PARSE_STATE_IN_SOURCES_VALUE:
			context = g_markup_parse_context_new (
				&source_xml_parser, 0, parse_data, NULL);
			break;

		default:
			return;
	}

	if (g_markup_parse_context_parse (context, text, length, error))
		g_markup_parse_context_end_parse (context, error);

	g_markup_parse_context_free (context);
}

static GMarkupParser gconf_xml_parser = {
	migrate_parse_gconf_xml_start_element,
	migrate_parse_gconf_xml_end_element,
	migrate_parse_gconf_xml_text,
	NULL,  /* passthrough */
	NULL   /* error */
};

static gboolean
migrate_parse_gconf_xml (ParseType parse_type,
                         const gchar *contents,
                         gsize length,
                         GError **error)
{
	GMarkupParseContext *context;
	ParseData *parse_data;
	gboolean success = FALSE;

	parse_data = parse_data_new (parse_type);

	context = g_markup_parse_context_new (
		&gconf_xml_parser, 0, parse_data,
		(GDestroyNotify) parse_data_free);

	if (g_markup_parse_context_parse (context, contents, length, error))
		if (g_markup_parse_context_end_parse (context, error))
			success = TRUE;

	g_markup_parse_context_free (context);

	return success;
}

static gboolean
migrate_parse_gconf_tree_xml_in_evolution (GQueue *dir_stack)
{
	if (g_strcmp0 (g_queue_peek_nth (dir_stack, 0), "apps") != 0)
		return FALSE;

	if (g_strcmp0 (g_queue_peek_nth (dir_stack, 1), "evolution") != 0)
		return FALSE;

	return TRUE;
}

static void
migrate_parse_gconf_tree_xml_start_element (GMarkupParseContext *context,
                                            const gchar *element_name,
                                            const gchar **attribute_names,
                                            const gchar **attribute_values,
                                            gpointer user_data,
                                            GError **error)
{
	GQueue *dir_stack = user_data;

	if (g_strcmp0 (element_name, "dir") == 0) {
		ParseData *parse_data = NULL;
		gchar *dir_name = NULL;

		g_markup_collect_attributes (
			element_name,
			attribute_names,
			attribute_values,
			error,
			G_MARKUP_COLLECT_STRDUP,
			"name", &dir_name,
			G_MARKUP_COLLECT_INVALID);

		if (dir_name != NULL) {
			/* Takes ownership of the string. */
			g_queue_push_tail (dir_stack, dir_name);
			dir_name = NULL;
		}

		/* Push a sub-parser to handle the <entry> tag. */

		if (migrate_parse_gconf_tree_xml_in_evolution (dir_stack))
			dir_name = g_queue_peek_tail (dir_stack);

		if (g_strcmp0 (dir_name, "mail") == 0)
			parse_data = parse_data_new (PARSE_TYPE_MAIL);

		if (g_strcmp0 (dir_name, "addressbook") == 0)
			parse_data = parse_data_new (PARSE_TYPE_ADDRESSBOOK);

		if (g_strcmp0 (dir_name, "calendar") == 0)
			parse_data = parse_data_new (PARSE_TYPE_CALENDAR);

		if (g_strcmp0 (dir_name, "tasks") == 0)
			parse_data = parse_data_new (PARSE_TYPE_TASKS);

		if (g_strcmp0 (dir_name, "memos") == 0)
			parse_data = parse_data_new (PARSE_TYPE_MEMOS);

		if (parse_data != NULL) {
			/* Pretend like we saw a <gconf> tag. */
			parse_data->state = PARSE_STATE_IN_GCONF;

			g_markup_parse_context_push (
				context, &gconf_xml_parser, parse_data);
		}
	}
}

static void
migrate_parse_gconf_tree_xml_end_element (GMarkupParseContext *context,
                                          const gchar *element_name,
                                          gpointer user_data,
                                          GError **error)
{
	GQueue *dir_stack = user_data;

	if (g_strcmp0 (element_name, "dir") == 0) {
		gboolean pop_parse_context = FALSE;

		/* Figure out if we need to pop the parse context. */

		if (migrate_parse_gconf_tree_xml_in_evolution (dir_stack)) {
			const gchar *dir_name;

			dir_name = g_queue_peek_tail (dir_stack);

			if (g_strcmp0 (dir_name, "mail") == 0)
				pop_parse_context = TRUE;

			if (g_strcmp0 (dir_name, "addressbook") == 0)
				pop_parse_context = TRUE;

			if (g_strcmp0 (dir_name, "calendar") == 0)
				pop_parse_context = TRUE;

			if (g_strcmp0 (dir_name, "tasks") == 0)
				pop_parse_context = TRUE;

			if (g_strcmp0 (dir_name, "memos") == 0)
				pop_parse_context = TRUE;
		}

		if (pop_parse_context) {
			ParseData *parse_data;

			parse_data = g_markup_parse_context_pop (context);
			parse_data_free (parse_data);
		}

		g_free (g_queue_pop_tail (dir_stack));
	}
}

static GMarkupParser gconf_tree_xml_parser = {
	migrate_parse_gconf_tree_xml_start_element,
	migrate_parse_gconf_tree_xml_end_element,
	NULL,  /* text */
	NULL,  /* passthrough */
	NULL   /* error */
};

static gboolean
migrate_parse_gconf_tree_xml (const gchar *contents,
                              gsize length,
                              GError **error)
{
	GMarkupParseContext *context;
	GQueue dir_stack = G_QUEUE_INIT;
	gboolean success = FALSE;

	context = g_markup_parse_context_new (
		&gconf_tree_xml_parser, 0,
		&dir_stack, (GDestroyNotify) NULL);

	if (g_markup_parse_context_parse (context, contents, length, error))
		if (g_markup_parse_context_end_parse (context, error))
			success = TRUE;

	g_markup_parse_context_free (context);

	g_warn_if_fail (g_queue_is_empty (&dir_stack));

	return success;
}

static void
migrate_remove_gconf_key (const gchar *gconf_key,
                          const gchar *gconf_xml)
{
	/* Remove the GConf string list so the user is not haunted by
	 * old data sources being resurrected from leftover GConf data.
	 * Also delete the %gconf.xml file itself.  If gconfd is running
	 * then it will just recreate the file from memory when it exits
	 * (which is why we invoke gconftool-2), otherwise the file will
	 * stay deleted. */

	gchar *path_to_program;

	path_to_program = g_find_program_in_path ("gconftool-2");

	if (path_to_program != NULL) {
		gchar *command_line;
		GError *error = NULL;

		command_line = g_strjoin (
			" ",
			path_to_program,
			"--set",
			"--type=list",
			"--list-type=string",
			gconf_key, "[]", NULL);

		/* We don't really care if the command worked or not,
		 * just check that the program got spawned successfully. */
		if (!g_spawn_command_line_async (command_line, &error)) {
			g_printerr (
				"Failed to spawn '%s': %s\n",
				path_to_program, error->message);
			g_error_free (error);
		}

		g_free (path_to_program);
		g_free (command_line);
	}

	/* This will be NULL when parsing a merged XML tree. */
	if (gconf_xml != NULL) {
		if (g_file_test (gconf_xml, G_FILE_TEST_IS_REGULAR)) {
			if (g_remove (gconf_xml) == -1) {
				g_printerr (
					"Failed to remove '%s': %s\n",
					gconf_xml, g_strerror (errno));
			}
		}
	}
}

static gboolean
migrate_get_file_contents_allow_noent (const gchar *path,
                                       gchar **out_contents,
                                       gsize *out_length,
                                       GError **error)
{
	gboolean success;
	GError *local_error = NULL;

	success = g_file_get_contents (
		path, out_contents, out_length, &local_error);

	/* Sanity check. */
	g_return_val_if_fail (
		(success && (local_error == NULL)) ||
		(!success && (local_error != NULL)), FALSE);

	if (g_error_matches (local_error, G_FILE_ERROR, G_FILE_ERROR_NOENT)) {
		g_clear_error (&local_error);
		success = TRUE;
	}

	if (local_error != NULL)
		g_propagate_error (error, local_error);

	return success;
}

static void
migrate_merged_gconf_tree (const gchar *gconf_tree_xml)
{
	const gchar *gconf_key;
	gchar *contents = NULL;
	gsize length;
	GError *local_error = NULL;

	migrate_get_file_contents_allow_noent (
		gconf_tree_xml, &contents, &length, &local_error);

	if (contents != NULL) {
		migrate_parse_gconf_tree_xml (
			contents, length, &local_error);

		if (local_error == NULL) {
			gconf_key = "/apps/evolution/mail/accounts";
			migrate_remove_gconf_key (gconf_key, NULL);

			gconf_key = "/apps/evolution/addressbook/sources";
			migrate_remove_gconf_key (gconf_key, NULL);

			gconf_key = "/apps/evolution/calendar/sources";
			migrate_remove_gconf_key (gconf_key, NULL);

			gconf_key = "/apps/evolution/tasks/sources";
			migrate_remove_gconf_key (gconf_key, NULL);

			gconf_key = "/apps/evolution/memos/sources";
			migrate_remove_gconf_key (gconf_key, NULL);
		}

		g_free (contents);
	}

	if (local_error != NULL) {
		g_printerr (
			"Migration of '%s' failed: %s",
			gconf_tree_xml, local_error->message);
		g_error_free (local_error);
	}
}

static void
migrate_and_remove_key (const gchar *filename,
                        const gchar *migrate_type_name,
                        ParseType parse_type,
                        const gchar *key_to_remove)
{
	gchar *contents = NULL;
	gsize length;
	GError *local_error = NULL;

	migrate_get_file_contents_allow_noent (
		filename, &contents, &length, &local_error);

	if (contents != NULL) {
		e_source_registry_debug_print ("Migrating %s from GConf...\n", migrate_type_name);

		migrate_parse_gconf_xml (
			parse_type, contents, length, &local_error);

		if (local_error == NULL)
			migrate_remove_gconf_key (key_to_remove, filename);

		g_free (contents);
	}

	if (local_error != NULL) {
		g_printerr (
			"Failed to migrate '%s': %s",
			filename, local_error->message);
		g_error_free (local_error);
	}
}

static void
migrate_normal_gconf_tree (const gchar *gconf_base_dir)
{
	gchar *base_dir;
	gchar *gconf_xml;

	base_dir = g_build_filename (
		gconf_base_dir, "apps", "evolution", NULL);

	/* ------------------------------------------------------------------*/

	gconf_xml = g_build_filename (
		base_dir, "mail", "%gconf.xml", NULL);
	migrate_and_remove_key (
		gconf_xml, "mail accounts",
		PARSE_TYPE_MAIL,
		"/apps/evolution/mail/accounts");
	g_free (gconf_xml);

	/* ------------------------------------------------------------------*/

	gconf_xml = g_build_filename (
		base_dir, "addressbook", "%gconf.xml", NULL);
	migrate_and_remove_key (
		gconf_xml, "addressbook sources",
		PARSE_TYPE_ADDRESSBOOK,
		"/apps/evolution/addressbook/sources");
	g_free (gconf_xml);

	/* ------------------------------------------------------------------*/

	gconf_xml = g_build_filename (
		base_dir, "calendar", "%gconf.xml", NULL);
	migrate_and_remove_key (
		gconf_xml, "calendar sources",
		PARSE_TYPE_CALENDAR,
		"/apps/evolution/calendar/sources");
	g_free (gconf_xml);

	/* ------------------------------------------------------------------*/

	gconf_xml = g_build_filename (
		base_dir, "tasks", "%gconf.xml", NULL);
	migrate_and_remove_key (
		gconf_xml, "task list sources",
		PARSE_TYPE_TASKS,
		"/apps/evolution/tasks/sources");
	g_free (gconf_xml);

	/* ------------------------------------------------------------------*/

	gconf_xml = g_build_filename (
		base_dir, "memos", "%gconf.xml", NULL);
	migrate_and_remove_key (
		gconf_xml, "memo list sources",
		PARSE_TYPE_MEMOS,
		"/apps/evolution/memos/sources");
	g_free (gconf_xml);

	/* ------------------------------------------------------------------*/

	g_free (base_dir);
}

void
evolution_source_registry_migrate_sources (void)
{
	gchar *gconf_base_dir;
	gchar *gconf_tree_xml;

	/* If the GConf is configured to follow XDG settings, then its root
	 * data folder is ~/.config/gconf/, thus try this first and fallback
	 * to the default non-XDG path ~/.gconf/ if it doesn't exist. */
	gconf_base_dir = g_build_filename (g_get_user_config_dir (), "gconf", NULL);
	if (!g_file_test (gconf_base_dir, G_FILE_TEST_EXISTS)) {
		g_free (gconf_base_dir);
		gconf_base_dir = g_build_filename (g_get_home_dir (), ".gconf", NULL);
	}

	gconf_tree_xml = g_build_filename (gconf_base_dir, "%gconf-tree.xml", NULL);

	/* Handle a merged GConf tree file if present (mainly for
	 * Debian), otherwise assume a normal GConf directory tree. */
	if (g_file_test (gconf_tree_xml, G_FILE_TEST_IS_REGULAR))
		migrate_merged_gconf_tree (gconf_tree_xml);
	else
		migrate_normal_gconf_tree (gconf_base_dir);

	g_free (gconf_base_dir);
	g_free (gconf_tree_xml);
}

gboolean
evolution_source_registry_migrate_gconf_tree_xml (const gchar *filename,
                                                  GError **error)
{
	gchar *contents;
	gsize length;
	gboolean success = FALSE;

	/* Extracts account info from an arbitrary merged XML file. */

	if (g_file_get_contents (filename, &contents, &length, error)) {
		success = migrate_parse_gconf_tree_xml (
			contents, length, error);
		g_free (contents);
	}

	return success;
}

