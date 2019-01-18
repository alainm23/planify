/*
 * e-source-smime.c
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
 * SECTION: e-source-smime
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for S/MIME settings
 *
 * The #ESourceSMIME extension tracks Secure/Multipurpose Internet Mail
 * Extensions (S/MIME) settings to be applied to outgoing mail messages.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceSMIME *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_SMIME);
 * ]|
 **/

#include "e-source-smime.h"

#include <libedataserver/e-data-server-util.h>

#define E_SOURCE_SMIME_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_SMIME, ESourceSMIMEPrivate))

struct _ESourceSMIMEPrivate {
	gchar *encryption_certificate;
	gchar *signing_algorithm;
	gchar *signing_certificate;

	gboolean encrypt_by_default;
	gboolean encrypt_to_self;
	gboolean sign_by_default;
};

enum {
	PROP_0,
	PROP_ENCRYPTION_CERTIFICATE,
	PROP_ENCRYPT_BY_DEFAULT,
	PROP_ENCRYPT_TO_SELF,
	PROP_SIGNING_ALGORITHM,
	PROP_SIGNING_CERTIFICATE,
	PROP_SIGN_BY_DEFAULT
};

G_DEFINE_TYPE (
	ESourceSMIME,
	e_source_smime,
	E_TYPE_SOURCE_EXTENSION)

static void
source_smime_set_property (GObject *object,
                           guint property_id,
                           const GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ENCRYPTION_CERTIFICATE:
			e_source_smime_set_encryption_certificate (
				E_SOURCE_SMIME (object),
				g_value_get_string (value));
			return;

		case PROP_ENCRYPT_BY_DEFAULT:
			e_source_smime_set_encrypt_by_default (
				E_SOURCE_SMIME (object),
				g_value_get_boolean (value));
			return;

		case PROP_ENCRYPT_TO_SELF:
			e_source_smime_set_encrypt_to_self (
				E_SOURCE_SMIME (object),
				g_value_get_boolean (value));
			return;

		case PROP_SIGNING_ALGORITHM:
			e_source_smime_set_signing_algorithm (
				E_SOURCE_SMIME (object),
				g_value_get_string (value));
			return;

		case PROP_SIGNING_CERTIFICATE:
			e_source_smime_set_signing_certificate (
				E_SOURCE_SMIME (object),
				g_value_get_string (value));
			return;

		case PROP_SIGN_BY_DEFAULT:
			e_source_smime_set_sign_by_default (
				E_SOURCE_SMIME (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_smime_get_property (GObject *object,
                           guint property_id,
                           GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ENCRYPTION_CERTIFICATE:
			g_value_take_string (
				value,
				e_source_smime_dup_encryption_certificate (
				E_SOURCE_SMIME (object)));
			return;

		case PROP_ENCRYPT_BY_DEFAULT:
			g_value_set_boolean (
				value,
				e_source_smime_get_encrypt_by_default (
				E_SOURCE_SMIME (object)));
			return;

		case PROP_ENCRYPT_TO_SELF:
			g_value_set_boolean (
				value,
				e_source_smime_get_encrypt_to_self (
				E_SOURCE_SMIME (object)));
			return;

		case PROP_SIGNING_ALGORITHM:
			g_value_take_string (
				value,
				e_source_smime_dup_signing_algorithm (
				E_SOURCE_SMIME (object)));
			return;

		case PROP_SIGNING_CERTIFICATE:
			g_value_take_string (
				value,
				e_source_smime_dup_signing_certificate (
				E_SOURCE_SMIME (object)));
			return;

		case PROP_SIGN_BY_DEFAULT:
			g_value_set_boolean (
				value,
				e_source_smime_get_sign_by_default (
				E_SOURCE_SMIME (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_smime_finalize (GObject *object)
{
	ESourceSMIMEPrivate *priv;

	priv = E_SOURCE_SMIME_GET_PRIVATE (object);

	g_free (priv->encryption_certificate);
	g_free (priv->signing_algorithm);
	g_free (priv->signing_certificate);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_smime_parent_class)->finalize (object);
}

static void
e_source_smime_class_init (ESourceSMIMEClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceSMIMEPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_smime_set_property;
	object_class->get_property = source_smime_get_property;
	object_class->finalize = source_smime_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_SMIME;

	g_object_class_install_property (
		object_class,
		PROP_ENCRYPTION_CERTIFICATE,
		g_param_spec_string (
			"encryption-certificate",
			"Encryption Certificate",
			"S/MIME certificate for encrypting messages",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_ENCRYPT_BY_DEFAULT,
		g_param_spec_boolean (
			"encrypt-by-default",
			"Encrypt By Default",
			"Encrypt outgoing messages by default",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_ENCRYPT_TO_SELF,
		g_param_spec_boolean (
			"encrypt-to-self",
			"Encrypt To Self",
			"Always encrypt to myself",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_SIGNING_ALGORITHM,
		g_param_spec_string (
			"signing-algorithm",
			"Signing Algorithm",
			"Hash algorithm used to sign messages",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_SIGNING_CERTIFICATE,
		g_param_spec_string (
			"signing-certificate",
			"Signing Certificate",
			"S/MIME certificate for signing messages",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_SIGN_BY_DEFAULT,
		g_param_spec_boolean (
			"sign-by-default",
			"Sign By Default",
			"Sign outgoing messages by default",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_smime_init (ESourceSMIME *extension)
{
	extension->priv = E_SOURCE_SMIME_GET_PRIVATE (extension);
}

/**
 * e_source_smime_get_encryption_certificate:
 * @extension: an #ESourceSMIME
 *
 * Returns the S/MIME certificate name used to encrypt messages.
 *
 * Returns: the certificate name used to encrypt messages
 *
 * Since: 3.6
 **/
const gchar *
e_source_smime_get_encryption_certificate (ESourceSMIME *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_SMIME (extension), NULL);

	return extension->priv->encryption_certificate;
}

/**
 * e_source_smime_dup_encryption_certificate:
 * @extension: an #ESourceSMIME
 *
 * Thread-safe variation of e_source_smime_get_encryption_certificate().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceSMIME:encryption-certificate
 *
 * Since: 3.6
 **/
gchar *
e_source_smime_dup_encryption_certificate (ESourceSMIME *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_SMIME (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_smime_get_encryption_certificate (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_smime_set_encryption_certificate:
 * @extension: an #ESourceSMIME
 * @encryption_certificate: (allow-none): the certificate name used to encrypt
 *                          messages, or %NULL
 *
 * Sets the certificate name used to encrypt messages.
 *
 * If the @encryption_certificate string is empty, %NULL is set instead.
 *
 * Since: 3.6
 **/
void
e_source_smime_set_encryption_certificate (ESourceSMIME *extension,
                                           const gchar *encryption_certificate)
{
	g_return_if_fail (E_IS_SOURCE_SMIME (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (g_strcmp0 (
		extension->priv->encryption_certificate,
		encryption_certificate) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	if (encryption_certificate && !*encryption_certificate)
		encryption_certificate = NULL;

	g_free (extension->priv->encryption_certificate);
	extension->priv->encryption_certificate = g_strdup (encryption_certificate);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "encryption-certificate");
}

/**
 * e_source_smime_get_encrypt_by_default:
 * @extension: an #ESourceSMIME
 *
 * Returns whether to encrypt outgoing messages by default using S/MIME
 * software such as Mozilla Network Security Services (NSS).
 *
 * Returns: whether to encrypt outgoing messages by default
 *
 * Since: 3.6
 **/
gboolean
e_source_smime_get_encrypt_by_default (ESourceSMIME *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_SMIME (extension), FALSE);

	return extension->priv->encrypt_by_default;
}

/**
 * e_source_smime_set_encrypt_by_default:
 * @extension: an #ESourceSMIME
 * @encrypt_by_default: whether to encrypt outgoing messages by default
 *
 * Sets whether to encrypt outgoing messages by default using S/MIME
 * software such as Mozilla Network Security Services (NSS).
 *
 * Since: 3.6
 **/
void
e_source_smime_set_encrypt_by_default (ESourceSMIME *extension,
                                       gboolean encrypt_by_default)
{
	g_return_if_fail (E_IS_SOURCE_SMIME (extension));

	if (extension->priv->encrypt_by_default == encrypt_by_default)
		return;

	extension->priv->encrypt_by_default = encrypt_by_default;

	g_object_notify (G_OBJECT (extension), "encrypt-by-default");
}

/**
 * e_source_smime_get_encrypt_to_self:
 * @extension: an #ESourceSMIME
 *
 * Returns whether to "encrypt-to-self" when sending encrypted messages.
 *
 * Returns: whether to "encrypt-to-self"
 *
 * Since: 3.6
 **/
gboolean
e_source_smime_get_encrypt_to_self (ESourceSMIME *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_SMIME (extension), FALSE);

	return extension->priv->encrypt_to_self;
}

/**
 * e_source_smime_set_encrypt_to_self:
 * @extension: an #ESourceSMIME
 * @encrypt_to_self: whether to "encrypt-to-self"
 *
 * Sets whether to "encrypt-to-self" when sending encrypted messages.
 *
 * Since: 3.6
 **/
void
e_source_smime_set_encrypt_to_self (ESourceSMIME *extension,
                                    gboolean encrypt_to_self)
{
	g_return_if_fail (E_IS_SOURCE_SMIME (extension));

	if (extension->priv->encrypt_to_self == encrypt_to_self)
		return;

	extension->priv->encrypt_to_self = encrypt_to_self;

	g_object_notify (G_OBJECT (extension), "encrypt-to-self");
}

/**
 * e_source_smime_get_signing_algorithm:
 * @extension: an #ESourceSMIME
 *
 * Returns the name of the hash algorithm used to digitally sign outgoing
 * messages.
 *
 * Returns: the signing algorithm for outgoing messages
 *
 * Since: 3.6
 **/
const gchar *
e_source_smime_get_signing_algorithm (ESourceSMIME *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_SMIME (extension), NULL);

	return extension->priv->signing_algorithm;
}

/**
 * e_source_smime_dup_signing_algorithm:
 * @extension: an #ESourceSMIME
 *
 * Thread-safe variation of e_source_smime_get_signing_algorithm().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceSMIME:signing-algorithm
 *
 * Since: 3.6
 **/
gchar *
e_source_smime_dup_signing_algorithm (ESourceSMIME *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_SMIME (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_smime_get_signing_algorithm (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_smime_set_signing_algorithm:
 * @extension: an #ESourceSMIME
 * @signing_algorithm: (allow-none): the signing algorithm for outgoing
 *                     messages, or %NULL
 *
 * Sets the name of the hash algorithm used to digitally sign outgoing
 * messages.
 *
 * The internal copy of @signing_algorithm is automatically stripped of
 * leading and trailing whitespace.  If the resulting string is empty,
 * %NULL is set instead.
 *
 * Since: 3.6
 **/
void
e_source_smime_set_signing_algorithm (ESourceSMIME *extension,
                                      const gchar *signing_algorithm)
{
	g_return_if_fail (E_IS_SOURCE_SMIME (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->signing_algorithm, signing_algorithm) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->signing_algorithm);
	extension->priv->signing_algorithm =
		e_util_strdup_strip (signing_algorithm);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "signing-algorithm");
}

/**
 * e_source_smime_get_signing_certificate:
 * @extension: an #ESourceSMIME
 *
 * Returns the S/MIME certificate name used to sign messages.
 *
 * Returns: the certificate name used to sign messages
 *
 * Since: 3.6
 **/
const gchar *
e_source_smime_get_signing_certificate (ESourceSMIME *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_SMIME (extension), NULL);

	return extension->priv->signing_certificate;
}

/**
 * e_source_smime_dup_signing_certificate:
 * @extension: an #ESourceSMIME
 *
 * Thread-safe variation of e_source_smime_get_signing_certificate().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceSMIME:signing-certificate
 *
 * Since: 3.6
 **/
gchar *
e_source_smime_dup_signing_certificate (ESourceSMIME *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_SMIME (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_smime_get_signing_certificate (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_smime_set_signing_certificate:
 * @extension: an #ESourceSMIME
 * @signing_certificate: (allow-none): the certificate name used to sign
 *                       messages, or %NULL
 *
 * Sets the S/MIME certificate name used to sign messages.
 *
 * If the @signing_certificate string is empty, %NULL is set instead.
 *
 * Since: 3.6
 **/
void
e_source_smime_set_signing_certificate (ESourceSMIME *extension,
                                        const gchar *signing_certificate)
{
	g_return_if_fail (E_IS_SOURCE_SMIME (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (g_strcmp0 (extension->priv->signing_certificate, signing_certificate) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	if (signing_certificate && !*signing_certificate)
		signing_certificate = NULL;

	g_free (extension->priv->signing_certificate);
	extension->priv->signing_certificate = g_strdup (signing_certificate);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "signing-certificate");
}

/**
 * e_source_smime_get_sign_by_default:
 * @extension: an #ESourceSMIME
 *
 * Returns whether to digitally sign outgoing messages by default using
 * S/MIME software such as Mozilla Network Security Services (NSS).
 *
 * Returns: whether to sign outgoing messages by default
 *
 * Since: 3.6
 **/
gboolean
e_source_smime_get_sign_by_default (ESourceSMIME *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_SMIME (extension), FALSE);

	return extension->priv->sign_by_default;
}

/**
 * e_source_smime_set_sign_by_default:
 * @extension: an #ESourceSMIME
 * @sign_by_default: whether to sign outgoing messages by default
 *
 * Sets whether to digitally sign outgoing messages by default using
 * S/MIME software such as Mozilla Network Security Services (NSS).
 *
 * Since: 3.6
 **/
void
e_source_smime_set_sign_by_default (ESourceSMIME *extension,
                                    gboolean sign_by_default)
{
	g_return_if_fail (E_IS_SOURCE_SMIME (extension));

	if (extension->priv->sign_by_default == sign_by_default)
		return;

	extension->priv->sign_by_default = sign_by_default;

	g_object_notify (G_OBJECT (extension), "sign-by-default");
}

