/*
 * e-source-mail-identity.c
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
 * SECTION: e-source-mail-identity
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for an email identity
 *
 * The #ESourceMailIdentity extension describes an "identity" for a mail
 * account, which is the information that other people see when they read
 * your messages.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceMailIdentity *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_MAIL_IDENTITY);
 * ]|
 **/

#include "evolution-data-server-config.h"

#include "camel/camel.h"

#include "e-data-server-util.h"

#include "e-source-mail-identity.h"

#define E_SOURCE_MAIL_IDENTITY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_MAIL_IDENTITY, ESourceMailIdentityPrivate))

struct _ESourceMailIdentityPrivate {
	gchar *address;
	gchar *name;
	gchar *organization;
	gchar *reply_to;
	gchar *signature_uid;
	gchar *aliases;
};

enum {
	PROP_0,
	PROP_ADDRESS,
	PROP_ALIASES,
	PROP_NAME,
	PROP_ORGANIZATION,
	PROP_REPLY_TO,
	PROP_SIGNATURE_UID
};

G_DEFINE_TYPE (
	ESourceMailIdentity,
	e_source_mail_identity,
	E_TYPE_SOURCE_EXTENSION)

static void
source_mail_identity_set_property (GObject *object,
                                   guint property_id,
                                   const GValue *value,
                                   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ADDRESS:
			e_source_mail_identity_set_address (
				E_SOURCE_MAIL_IDENTITY (object),
				g_value_get_string (value));
			return;

		case PROP_ALIASES:
			e_source_mail_identity_set_aliases (
				E_SOURCE_MAIL_IDENTITY (object),
				g_value_get_string (value));
			return;

		case PROP_NAME:
			e_source_mail_identity_set_name (
				E_SOURCE_MAIL_IDENTITY (object),
				g_value_get_string (value));
			return;

		case PROP_ORGANIZATION:
			e_source_mail_identity_set_organization (
				E_SOURCE_MAIL_IDENTITY (object),
				g_value_get_string (value));
			return;

		case PROP_REPLY_TO:
			e_source_mail_identity_set_reply_to (
				E_SOURCE_MAIL_IDENTITY (object),
				g_value_get_string (value));
			return;

		case PROP_SIGNATURE_UID:
			e_source_mail_identity_set_signature_uid (
				E_SOURCE_MAIL_IDENTITY (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_mail_identity_get_property (GObject *object,
                                   guint property_id,
                                   GValue *value,
                                   GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ADDRESS:
			g_value_take_string (
				value,
				e_source_mail_identity_dup_address (
				E_SOURCE_MAIL_IDENTITY (object)));
			return;

		case PROP_ALIASES:
			g_value_take_string (
				value,
				e_source_mail_identity_dup_aliases (
				E_SOURCE_MAIL_IDENTITY (object)));
			return;

		case PROP_NAME:
			g_value_take_string (
				value,
				e_source_mail_identity_dup_name (
				E_SOURCE_MAIL_IDENTITY (object)));
			return;

		case PROP_ORGANIZATION:
			g_value_take_string (
				value,
				e_source_mail_identity_dup_organization (
				E_SOURCE_MAIL_IDENTITY (object)));
			return;

		case PROP_REPLY_TO:
			g_value_take_string (
				value,
				e_source_mail_identity_dup_reply_to (
				E_SOURCE_MAIL_IDENTITY (object)));
			return;

		case PROP_SIGNATURE_UID:
			g_value_take_string (
				value,
				e_source_mail_identity_dup_signature_uid (
				E_SOURCE_MAIL_IDENTITY (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_mail_identity_finalize (GObject *object)
{
	ESourceMailIdentityPrivate *priv;

	priv = E_SOURCE_MAIL_IDENTITY_GET_PRIVATE (object);

	g_free (priv->address);
	g_free (priv->name);
	g_free (priv->organization);
	g_free (priv->reply_to);
	g_free (priv->signature_uid);
	g_free (priv->aliases);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_mail_identity_parent_class)->finalize (object);
}

static void
e_source_mail_identity_class_init (ESourceMailIdentityClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceMailIdentityPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_mail_identity_set_property;
	object_class->get_property = source_mail_identity_get_property;
	object_class->finalize = source_mail_identity_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_MAIL_IDENTITY;

	g_object_class_install_property (
		object_class,
		PROP_ADDRESS,
		g_param_spec_string (
			"address",
			"Address",
			"Sender's email address",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_ALIASES,
		g_param_spec_string (
			"aliases",
			"Aliases",
			"Sender's email address aliases",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_NAME,
		g_param_spec_string (
			"name",
			"Name",
			"Sender's name",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_ORGANIZATION,
		g_param_spec_string (
			"organization",
			"Organization",
			"Sender's organization",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_REPLY_TO,
		g_param_spec_string (
			"reply-to",
			"Reply-To",
			"Sender's reply-to address",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_SIGNATURE_UID,
		g_param_spec_string (
			"signature-uid",
			"Signature UID",
			"ESource UID of the sender's signature",
			"none",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_mail_identity_init (ESourceMailIdentity *extension)
{
	extension->priv = E_SOURCE_MAIL_IDENTITY_GET_PRIVATE (extension);
}

/**
 * e_source_mail_identity_get_address:
 * @extension: an #ESourceMailIdentity
 *
 * Returns the email address for this identity from which to send messages.
 * This may be an empty string but will never be %NULL.
 *
 * Returns: the sender's email address
 *
 * Since: 3.6
 **/
const gchar *
e_source_mail_identity_get_address (ESourceMailIdentity *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	return extension->priv->address;
}

/**
 * e_source_mail_identity_dup_address:
 * @extension: an #ESourceMailIdentity
 *
 * Thread-safe variation of e_source_mail_identity_get_address().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceMailIdentity:address
 *
 * Since: 3.6
 **/
gchar *
e_source_mail_identity_dup_address (ESourceMailIdentity *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_mail_identity_get_address (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_mail_identity_set_address:
 * @extension: an #ESourceMailIdentity
 * @address: (allow-none): the sender's email address, or %NULL
 *
 * Sets the email address for this identity from which to send messages.
 *
 * The internal copy of @address is automatically stripped of leading and
 * trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.6
 **/
void
e_source_mail_identity_set_address (ESourceMailIdentity *extension,
                                    const gchar *address)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->address, address) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->address);
	extension->priv->address = e_util_strdup_strip (address);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "address");
}

/**
 * e_source_mail_identity_get_name:
 * @extension: an #ESourceMailIdentity
 *
 * Returns the sender's name for this identity.
 *
 * Returns: the sender's name
 *
 * Since: 3.6
 **/
const gchar *
e_source_mail_identity_get_name (ESourceMailIdentity *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	return extension->priv->name;
}

/**
 * e_source_mail_identity_dup_name:
 * @extension: an #ESourceMailIdentity
 *
 * Thread-safe variation of e_source_mail_identity_get_name().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceMailIdentity:name
 *
 * Since: 3.6
 **/
gchar *
e_source_mail_identity_dup_name (ESourceMailIdentity *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_mail_identity_get_name (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_mail_identity_set_name:
 * @extension: an #ESourceMailIdentity
 * @name: (allow-none): the sender's name, or %NULL
 *
 * Sets the sender's name for this identity.
 *
 * The internal copy of @name is automatically stripped of leading and
 * trailing whitespace.
 *
 * Since: 3.6
 **/
void
e_source_mail_identity_set_name (ESourceMailIdentity *extension,
                                 const gchar *name)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->name, name) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->name);
	extension->priv->name = e_util_strdup_strip (name);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "name");
}

/**
 * e_source_mail_identity_get_organization:
 * @extension: an #ESourceMailIdentity
 *
 * Returns the sender's organization for this identity.
 *
 * Returns: the sender's organization
 *
 * Since: 3.6
 **/
const gchar *
e_source_mail_identity_get_organization (ESourceMailIdentity *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	return extension->priv->organization;
}

/**
 * e_source_mail_identity_dup_organization:
 * @extension: an #ESourceMailIdentity
 *
 * Thread-safe variation of e_source_mail_identity_dup_organization().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceMailIdentity:organization
 *
 * Since: 3.6
 **/
gchar *
e_source_mail_identity_dup_organization (ESourceMailIdentity *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_mail_identity_get_organization (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_mail_identity_set_organization:
 * @extension: an #ESourceMailIdentity
 * @organization: (allow-none): the sender's organization, or %NULL
 *
 * Sets the sender's organization for this identity.
 *
 * The internal copy of @organization is automatically stripped of leading
 * and trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.6
 **/
void
e_source_mail_identity_set_organization (ESourceMailIdentity *extension,
                                         const gchar *organization)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->organization, organization) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->organization);
	extension->priv->organization = e_util_strdup_strip (organization);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "organization");
}

/**
 * e_source_mail_identity_get_reply_to:
 * @extension: an #ESourceMailIdentity
 *
 * Returns the email address for this identity to which recipients should
 * send replies.
 *
 * Returns: the sender's reply-to address
 *
 * Since: 3.6
 **/
const gchar *
e_source_mail_identity_get_reply_to (ESourceMailIdentity *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	return extension->priv->reply_to;
}

/**
 * e_source_mail_identity_dup_reply_to:
 * @extension: an #ESourceMailIdentity
 *
 * Thread-safe variation of e_source_mail_identity_get_reply_to().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceMailIdentity:reply-to
 *
 * Since: 3.6
 **/
gchar *
e_source_mail_identity_dup_reply_to (ESourceMailIdentity *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_mail_identity_get_reply_to (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_mail_identity_set_reply_to:
 * @extension: an #ESourceMailIdentity
 * @reply_to: (allow-none): the sender's reply-to address, or %NULL
 *
 * Sets the email address for this identity to which recipients should
 * send replies.
 *
 * The internal copy of @reply_to is automatically stripped of leading
 * and trailing whitespace.  If the resulting string is empty, %NULL is
 * set instead.
 *
 * Since: 3.6
 **/
void
e_source_mail_identity_set_reply_to (ESourceMailIdentity *extension,
                                     const gchar *reply_to)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->reply_to, reply_to) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->reply_to);
	extension->priv->reply_to = e_util_strdup_strip (reply_to);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "reply-to");
}

/**
 * e_source_mail_identity_get_signature_uid:
 * @extension: an #ESourceMailIdentity
 *
 * Returns the #ESource:uid of an #ESource describing a mail signature.
 *
 * If the user does not want to use a signature for this identity, the
 * convention is to set the #ESourceMailIdentity:signature-uid property
 * to "none".
 *
 * Returns: the sender's signature ID, or "none"
 *
 * Since: 3.6
 **/
const gchar *
e_source_mail_identity_get_signature_uid (ESourceMailIdentity *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	return extension->priv->signature_uid;
}

/**
 * e_source_mail_identity_dup_signature_uid:
 * @extension: an #ESourceMailIdentity
 *
 * Thread-safe variation of e_source_mail_identity_get_signature_uid().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceMailIdentity:signature-uid
 *
 * Since: 3.6
 **/
gchar *
e_source_mail_identity_dup_signature_uid (ESourceMailIdentity *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_mail_identity_get_signature_uid (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_mail_identity_set_signature_uid:
 * @extension: an #ESourceMailIdentity
 * @signature_uid: (allow-none): the sender's signature ID, or %NULL
 *
 * Sets the #ESource:uid of an #ESource describing a mail signature.
 *
 * If the user does not want to use a signature for this identity, the
 * convention is to set the #ESourceMailIdentity:signature-uid property
 * to "none".  In keeping with that convention, the property will be set
 * to "none" if @signature is %NULL or an empty string.
 *
 * Since: 3.6
 **/
void
e_source_mail_identity_set_signature_uid (ESourceMailIdentity *extension,
                                          const gchar *signature_uid)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension));

	/* Convert empty strings to "none". */
	if (signature_uid == NULL || *signature_uid == '\0')
		signature_uid = "none";

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (g_strcmp0 (extension->priv->signature_uid, signature_uid) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->signature_uid);
	extension->priv->signature_uid = g_strdup (signature_uid);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "signature-uid");
}

/**
 * e_source_mail_identity_get_aliases:
 * @extension: an #ESourceMailIdentity
 *
 * Returns the email address aliases for this identity. These are comma-separated
 * email addresses which may or may not contain also different name.
 * This may be an empty string, but will never be %NULL.
 * There can be used camel_address_decode() on a #CamelInternetAddress
 * to decode the list of aliases.
 *
 * Returns: (transfer none): the sender's email address aliases
 *
 * Since: 3.24
 **/
const gchar *
e_source_mail_identity_get_aliases (ESourceMailIdentity *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	return extension->priv->aliases;
}

/**
 * e_source_mail_identity_dup_aliases:
 * @extension: an #ESourceMailIdentity
 *
 * Thread-safe variation of e_source_mail_identity_get_aliases().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: (transfer full): a newly-allocated copy of #ESourceMailIdentity:aliases
 *
 * Since: 3.24
 **/
gchar *
e_source_mail_identity_dup_aliases (ESourceMailIdentity *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_mail_identity_get_aliases (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_mail_identity_set_aliases:
 * @extension: an #ESourceMailIdentity
 * @aliases: (allow-none): the sender's email address aliases, or %NULL
 *
 * Sets the email address aliases for this identity. These are comma-separated
 * email addresses which may or may not contain also different name.
 *
 * The internal copy of @aliases is automatically stripped of leading and
 * trailing whitespace. If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.24
 **/
void
e_source_mail_identity_set_aliases (ESourceMailIdentity *extension,
                                    const gchar *aliases)
{
	g_return_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->aliases, aliases) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->aliases);
	extension->priv->aliases = e_util_strdup_strip (aliases);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "aliases");
}

/**
 * e_source_mail_identity_get_aliases_as_hash_table:
 * @extension: an #ESourceMailIdentity
 *
 * Returns a set aliases as a hash table with address as key and
 * name as value of the hash table. The name can be sometimes
 * empty or NULL, thus rather use g_hash_table_contains() when
 * checking for particular address. The addresses are
 * compared case insensitively. The same addresses with a different
 * name are included only once, the last variant of it. Use
 * e_source_mail_identity_get_aliases() if you need more fine-grained
 * control on the list of aliases.
 *
 * Returns: (transfer full) (element-type utf8 utf8) (nullable): A newly created
 *   #GHashTable will all the aliases. Returns %NULL if there are none set.
 *   Use g_hash_table_destroy() to free the returned hash table.
 *
 * Since: 3.24
 **/
GHashTable *
e_source_mail_identity_get_aliases_as_hash_table (ESourceMailIdentity *extension)
{
	GHashTable *aliases = NULL;

	g_return_val_if_fail (E_IS_SOURCE_MAIL_IDENTITY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (extension->priv->aliases && *extension->priv->aliases) {
		CamelInternetAddress *inet_address;
		gint ii, len;

		inet_address = camel_internet_address_new ();
		len = camel_address_decode (CAMEL_ADDRESS (inet_address), extension->priv->aliases);

		if (len > 0) {
			aliases = g_hash_table_new_full (camel_strcase_hash, camel_strcase_equal, g_free, g_free);

			for (ii = 0; ii < len; ii++) {
				const gchar *name = NULL, *address = NULL;

				if (camel_internet_address_get (inet_address, ii, &name, &address) && address && *address) {
					g_hash_table_insert (aliases, g_strdup (address), g_strdup (name));
				}
			}
		}

		g_clear_object (&inet_address);
	}

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return aliases;
}
