/*
 * e-source-openpgp.c
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
 * SECTION: e-source-openpgp
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for OpenPGP settings
 *
 * The #ESourceOpenPGP extension tracks OpenPGP (RFC 4880) settings to be
 * applied to outgoing mail messages.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceOpenPGP *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_OPENPGP);
 * ]|
 **/

#include "e-source-openpgp.h"

#include <libedataserver/e-data-server-util.h>

#define E_SOURCE_OPENPGP_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_OPENPGP, ESourceOpenPGPPrivate))

struct _ESourceOpenPGPPrivate {
	gchar *key_id;
	gchar *signing_algorithm;

	gboolean always_trust;
	gboolean encrypt_to_self;
	gboolean sign_by_default;
	gboolean encrypt_by_default;
	gboolean prefer_inline;
};

enum {
	PROP_0,
	PROP_ALWAYS_TRUST,
	PROP_ENCRYPT_TO_SELF,
	PROP_KEY_ID,
	PROP_SIGNING_ALGORITHM,
	PROP_SIGN_BY_DEFAULT,
	PROP_ENCRYPT_BY_DEFAULT,
	PROP_PREFER_INLINE
};

G_DEFINE_TYPE (
	ESourceOpenPGP,
	e_source_openpgp,
	E_TYPE_SOURCE_EXTENSION)

static void
source_openpgp_set_property (GObject *object,
                             guint property_id,
                             const GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ALWAYS_TRUST:
			e_source_openpgp_set_always_trust (
				E_SOURCE_OPENPGP (object),
				g_value_get_boolean (value));
			return;

		case PROP_ENCRYPT_TO_SELF:
			e_source_openpgp_set_encrypt_to_self (
				E_SOURCE_OPENPGP (object),
				g_value_get_boolean (value));
			return;

		case PROP_KEY_ID:
			e_source_openpgp_set_key_id (
				E_SOURCE_OPENPGP (object),
				g_value_get_string (value));
			return;

		case PROP_SIGNING_ALGORITHM:
			e_source_openpgp_set_signing_algorithm (
				E_SOURCE_OPENPGP (object),
				g_value_get_string (value));
			return;

		case PROP_SIGN_BY_DEFAULT:
			e_source_openpgp_set_sign_by_default (
				E_SOURCE_OPENPGP (object),
				g_value_get_boolean (value));
			return;

		case PROP_ENCRYPT_BY_DEFAULT:
			e_source_openpgp_set_encrypt_by_default (
				E_SOURCE_OPENPGP (object),
				g_value_get_boolean (value));
			return;

		case PROP_PREFER_INLINE:
			e_source_openpgp_set_prefer_inline (
				E_SOURCE_OPENPGP (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_openpgp_get_property (GObject *object,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ALWAYS_TRUST:
			g_value_set_boolean (
				value,
				e_source_openpgp_get_always_trust (
				E_SOURCE_OPENPGP (object)));
			return;

		case PROP_ENCRYPT_TO_SELF:
			g_value_set_boolean (
				value,
				e_source_openpgp_get_encrypt_to_self (
				E_SOURCE_OPENPGP (object)));
			return;

		case PROP_KEY_ID:
			g_value_take_string (
				value,
				e_source_openpgp_dup_key_id (
				E_SOURCE_OPENPGP (object)));
			return;

		case PROP_SIGNING_ALGORITHM:
			g_value_take_string (
				value,
				e_source_openpgp_dup_signing_algorithm (
				E_SOURCE_OPENPGP (object)));
			return;

		case PROP_SIGN_BY_DEFAULT:
			g_value_set_boolean (
				value,
				e_source_openpgp_get_sign_by_default (
				E_SOURCE_OPENPGP (object)));
			return;

		case PROP_ENCRYPT_BY_DEFAULT:
			g_value_set_boolean (
				value,
				e_source_openpgp_get_encrypt_by_default (
				E_SOURCE_OPENPGP (object)));
			return;

		case PROP_PREFER_INLINE:
			g_value_set_boolean (
				value,
				e_source_openpgp_get_prefer_inline (
				E_SOURCE_OPENPGP (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_openpgp_finalize (GObject *object)
{
	ESourceOpenPGPPrivate *priv;

	priv = E_SOURCE_OPENPGP_GET_PRIVATE (object);

	g_free (priv->key_id);
	g_free (priv->signing_algorithm);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_openpgp_parent_class)->finalize (object);
}

static void
e_source_openpgp_class_init (ESourceOpenPGPClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceOpenPGPPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_openpgp_set_property;
	object_class->get_property = source_openpgp_get_property;
	object_class->finalize = source_openpgp_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_OPENPGP;

	g_object_class_install_property (
		object_class,
		PROP_ALWAYS_TRUST,
		g_param_spec_boolean (
			"always-trust",
			"Always Trust",
			"Always trust keys in my keyring",
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
		PROP_KEY_ID,
		g_param_spec_string (
			"key-id",
			"Key ID",
			"PGP/GPG Key ID",
			NULL,
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
		PROP_PREFER_INLINE,
		g_param_spec_boolean (
			"prefer-inline",
			"Prefer inline",
			"Prefer inline sign/encrypt",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_openpgp_init (ESourceOpenPGP *extension)
{
	extension->priv = E_SOURCE_OPENPGP_GET_PRIVATE (extension);
}

/**
 * e_source_openpgp_get_always_trust:
 * @extension: an #ESourceOpenPGP
 *
 * Returns whether to skip key validation and assume that used keys are
 * always fully trusted.
 *
 * Returns: whether used keys are always fully trusted
 *
 * Since: 3.6
 **/
gboolean
e_source_openpgp_get_always_trust (ESourceOpenPGP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_OPENPGP (extension), FALSE);

	return extension->priv->always_trust;
}

/**
 * e_source_openpgp_set_always_trust:
 * @extension: an #ESourceOpenPGP
 * @always_trust: whether used keys are always fully trusted
 *
 * Sets whether to skip key validation and assume that used keys are
 * always fully trusted.
 *
 * Since: 3.6
 **/
void
e_source_openpgp_set_always_trust (ESourceOpenPGP *extension,
                                   gboolean always_trust)
{
	g_return_if_fail (E_IS_SOURCE_OPENPGP (extension));

	if (extension->priv->always_trust == always_trust)
		return;

	extension->priv->always_trust = always_trust;

	g_object_notify (G_OBJECT (extension), "always-trust");
}

/**
 * e_source_openpgp_get_encrypt_to_self:
 * @extension: an #ESourceOpenPGP
 *
 * Returns whether to "encrypt-to-self" when sending encrypted messages.
 *
 * Returns: whether to "encrypt-to-self"
 *
 * Since: 3.6
 **/
gboolean
e_source_openpgp_get_encrypt_to_self (ESourceOpenPGP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_OPENPGP (extension), FALSE);

	return extension->priv->encrypt_to_self;
}

/**
 * e_source_openpgp_set_encrypt_to_self:
 * @extension: an #ESourceOpenPGP
 * @encrypt_to_self: whether to "encrypt-to-self"
 *
 * Sets whether to "encrypt-to-self" when sending encrypted messages.
 *
 * Since: 3.6
 **/
void
e_source_openpgp_set_encrypt_to_self (ESourceOpenPGP *extension,
                                      gboolean encrypt_to_self)
{
	g_return_if_fail (E_IS_SOURCE_OPENPGP (extension));

	if (extension->priv->encrypt_to_self == encrypt_to_self)
		return;

	extension->priv->encrypt_to_self = encrypt_to_self;

	g_object_notify (G_OBJECT (extension), "encrypt-to-self");
}

/**
 * e_source_openpgp_get_key_id:
 * @extension: an #ESourceOpenPGP
 *
 * Returns the OpenPGP key ID used to sign and encrypt messages.
 *
 * Returns: the key ID used to sign and encrypt messages
 *
 * Since: 3.6
 **/
const gchar *
e_source_openpgp_get_key_id (ESourceOpenPGP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_OPENPGP (extension), NULL);

	return extension->priv->key_id;
}

/**
 * e_source_openpgp_dup_key_id:
 * @extension: an #ESourceOpenPGP
 *
 * Thread-safe variation of e_source_openpgp_get_key_id().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceOpenPGP:key-id
 *
 * Since: 3.6
 **/
gchar *
e_source_openpgp_dup_key_id (ESourceOpenPGP *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_OPENPGP (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_openpgp_get_key_id (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_openpgp_set_key_id:
 * @extension: an #ESourceOpenPGP
 * @key_id: the key ID used to sign and encrypt messages
 *
 * Sets the OpenPGP key ID used to sign and encrypt messages.
 *
 * The internal copy of @key_id is automatically stripped of leading and
 * trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.6
 **/
void
e_source_openpgp_set_key_id (ESourceOpenPGP *extension,
                             const gchar *key_id)
{
	g_return_if_fail (E_IS_SOURCE_OPENPGP (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->key_id, key_id) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->key_id);
	extension->priv->key_id = e_util_strdup_strip (key_id);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "key-id");
}

/**
 * e_source_openpgp_get_signing_algorithm:
 * @extension: an #ESourceOpenPGP
 *
 * Returns the name of the hash algorithm used to digitally sign outgoing
 * messages.
 *
 * Returns: the signing algorithm for outgoing messages
 *
 * Since: 3.6
 **/
const gchar *
e_source_openpgp_get_signing_algorithm (ESourceOpenPGP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_OPENPGP (extension), NULL);

	return extension->priv->signing_algorithm;
}

/**
 * e_source_openpgp_dup_signing_algorithm:
 * @extension: an #ESourceOpenPGP
 *
 * Thread-safe variation of e_source_openpgp_get_signing_algorithm().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceOpenPGP:signing-algorithm
 *
 * Since: 3.6
 **/
gchar *
e_source_openpgp_dup_signing_algorithm (ESourceOpenPGP *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_OPENPGP (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_openpgp_get_signing_algorithm (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_openpgp_set_signing_algorithm:
 * @extension: an #ESourceOpenPGP
 * @signing_algorithm: the signing algorithm for outgoing messages
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
e_source_openpgp_set_signing_algorithm (ESourceOpenPGP *extension,
                                        const gchar *signing_algorithm)
{
	g_return_if_fail (E_IS_SOURCE_OPENPGP (extension));

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
 * e_source_openpgp_get_sign_by_default:
 * @extension: an #ESourceOpenPGP
 *
 * Returns whether to digitally sign outgoing messages by default using
 * OpenPGP-compliant software such as GNU Privacy Guard (GnuPG).
 *
 * Returns: whether to sign outgoing messages by default
 *
 * Since: 3.6
 **/
gboolean
e_source_openpgp_get_sign_by_default (ESourceOpenPGP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_OPENPGP (extension), FALSE);

	return extension->priv->sign_by_default;
}

/**
 * e_source_openpgp_set_sign_by_default:
 * @extension: an #ESourceOpenPGP
 * @sign_by_default: whether to sign outgoing messages by default
 *
 * Sets whether to digitally sign outgoing messages by default using
 * OpenPGP-compliant software such as GNU Privacy Guard (GnuPG).
 *
 * Since: 3.6
 **/
void
e_source_openpgp_set_sign_by_default (ESourceOpenPGP *extension,
                                      gboolean sign_by_default)
{
	g_return_if_fail (E_IS_SOURCE_OPENPGP (extension));

	if (extension->priv->sign_by_default == sign_by_default)
		return;

	extension->priv->sign_by_default = sign_by_default;

	g_object_notify (G_OBJECT (extension), "sign-by-default");
}

/**
 * e_source_openpgp_get_encrypt_by_default:
 * @extension: an #ESourceOpenPGP
 *
 * Returns whether to digitally encrypt outgoing messages by default using
 * OpenPGP-compliant software such as GNU Privacy Guard (GnuPG).
 *
 * Returns: whether to encrypt outgoing messages by default
 *
 * Since: 3.18
 **/
gboolean
e_source_openpgp_get_encrypt_by_default (ESourceOpenPGP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_OPENPGP (extension), FALSE);

	return extension->priv->encrypt_by_default;
}

/**
 * e_source_openpgp_set_encrypt_by_default:
 * @extension: an #ESourceOpenPGP
 * @encrypt_by_default: whether to encrypt outgoing messages by default
 *
 * Sets whether to digitally encrypt outgoing messages by default using
 * OpenPGP-compliant software such as GNU Privacy Guard (GnuPG).
 *
 * Since: 3.18
 **/
void
e_source_openpgp_set_encrypt_by_default (ESourceOpenPGP *extension,
                                         gboolean encrypt_by_default)
{
	g_return_if_fail (E_IS_SOURCE_OPENPGP (extension));

	if (extension->priv->encrypt_by_default == encrypt_by_default)
		return;

	extension->priv->encrypt_by_default = encrypt_by_default;

	g_object_notify (G_OBJECT (extension), "encrypt-by-default");
}

/**
 * e_source_openpgp_get_prefer_inline:
 * @extension: an #ESourceOpenPGP
 *
 * Returns whether to prefer inline sign/encrypt of the text/plain messages.
 *
 * Returns: whether to prefer inline sign/encrypt of the text/plain messages
 *
 * Since: 3.20
 **/
gboolean
e_source_openpgp_get_prefer_inline (ESourceOpenPGP *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_OPENPGP (extension), FALSE);

	return extension->priv->prefer_inline;
}

/**
 * e_source_openpgp_set_prefer_inline:
 * @extension: an #ESourceOpenPGP
 * @prefer_inline: whether to prefer inline sign/encrypt of the text/plain messages
 *
 * Sets whether to prefer inline sign/encrypt of the text/plain messages.
 *
 * Since: 3.20
 **/
void
e_source_openpgp_set_prefer_inline (ESourceOpenPGP *extension,
				    gboolean prefer_inline)
{
	g_return_if_fail (E_IS_SOURCE_OPENPGP (extension));

	if (extension->priv->prefer_inline == prefer_inline)
		return;

	extension->priv->prefer_inline = prefer_inline;

	g_object_notify (G_OBJECT (extension), "prefer-inline");
}
