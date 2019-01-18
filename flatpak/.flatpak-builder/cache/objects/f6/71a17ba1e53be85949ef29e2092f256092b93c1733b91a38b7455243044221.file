/*
 * e-source-authentication.c
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
 * SECTION: e-source-authentication
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for authentication settings
 *
 * The #ESourceAuthentication extension tracks authentication settings
 * for a user account on a remote server.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceAuthentication *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);
 * ]|
 **/

#include "e-source-authentication.h"

#include <libedataserver/e-data-server-util.h>

#define E_SOURCE_AUTHENTICATION_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_AUTHENTICATION, ESourceAuthenticationPrivate))

struct _ESourceAuthenticationPrivate {
	gchar *host;
	gchar *method;
	guint16 port;
	gchar *proxy_uid;
	gboolean remember_password;
	gchar *user;
	gchar *credential_name;

	/* GNetworkAddress caches data internally, so we maintain the
	 * instance to preserve the cache as opposed to just creating
	 * a new GNetworkAddress instance each time it's requested. */
	GSocketConnectable *connectable;
};

enum {
	PROP_0,
	PROP_CONNECTABLE,
	PROP_HOST,
	PROP_METHOD,
	PROP_PORT,
	PROP_PROXY_UID,
	PROP_REMEMBER_PASSWORD,
	PROP_USER,
	PROP_CREDENTIAL_NAME
};

G_DEFINE_TYPE (
	ESourceAuthentication,
	e_source_authentication,
	E_TYPE_SOURCE_EXTENSION)

static void
source_authentication_update_connectable (ESourceAuthentication *extension)
{
	const gchar *host;
	guint16 port;

	/* This MUST be called with the property_lock acquired. */

	g_clear_object (&extension->priv->connectable);

	host = e_source_authentication_get_host (extension);
	port = e_source_authentication_get_port (extension);

	if (host != NULL) {
		GSocketConnectable *connectable;
		connectable = g_network_address_new (host, port);
		extension->priv->connectable = connectable;
	}
}

static void
source_authentication_set_property (GObject *object,
                                    guint property_id,
                                    const GValue *value,
                                    GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_HOST:
			e_source_authentication_set_host (
				E_SOURCE_AUTHENTICATION (object),
				g_value_get_string (value));
			return;

		case PROP_METHOD:
			e_source_authentication_set_method (
				E_SOURCE_AUTHENTICATION (object),
				g_value_get_string (value));
			return;

		case PROP_PORT:
			e_source_authentication_set_port (
				E_SOURCE_AUTHENTICATION (object),
				g_value_get_uint (value));
			return;

		case PROP_PROXY_UID:
			e_source_authentication_set_proxy_uid (
				E_SOURCE_AUTHENTICATION (object),
				g_value_get_string (value));
			return;

		case PROP_REMEMBER_PASSWORD:
			e_source_authentication_set_remember_password (
				E_SOURCE_AUTHENTICATION (object),
				g_value_get_boolean (value));
			return;

		case PROP_USER:
			e_source_authentication_set_user (
				E_SOURCE_AUTHENTICATION (object),
				g_value_get_string (value));
			return;

		case PROP_CREDENTIAL_NAME:
			e_source_authentication_set_credential_name (
				E_SOURCE_AUTHENTICATION (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_authentication_get_property (GObject *object,
                                    guint property_id,
                                    GValue *value,
                                    GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONNECTABLE:
			g_value_take_object (
				value,
				e_source_authentication_ref_connectable (
				E_SOURCE_AUTHENTICATION (object)));
			return;

		case PROP_HOST:
			g_value_take_string (
				value,
				e_source_authentication_dup_host (
				E_SOURCE_AUTHENTICATION (object)));
			return;

		case PROP_METHOD:
			g_value_take_string (
				value,
				e_source_authentication_dup_method (
				E_SOURCE_AUTHENTICATION (object)));
			return;

		case PROP_PORT:
			g_value_set_uint (
				value,
				e_source_authentication_get_port (
				E_SOURCE_AUTHENTICATION (object)));
			return;

		case PROP_PROXY_UID:
			g_value_take_string (
				value,
				e_source_authentication_dup_proxy_uid (
				E_SOURCE_AUTHENTICATION (object)));
			return;

		case PROP_REMEMBER_PASSWORD:
			g_value_set_boolean (
				value,
				e_source_authentication_get_remember_password (
				E_SOURCE_AUTHENTICATION (object)));
			return;

		case PROP_USER:
			g_value_take_string (
				value,
				e_source_authentication_dup_user (
				E_SOURCE_AUTHENTICATION (object)));
			return;

		case PROP_CREDENTIAL_NAME:
			g_value_take_string (
				value,
				e_source_authentication_dup_credential_name (
				E_SOURCE_AUTHENTICATION (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_authentication_dispose (GObject *object)
{
	ESourceAuthenticationPrivate *priv;

	priv = E_SOURCE_AUTHENTICATION_GET_PRIVATE (object);

	g_clear_object (&priv->connectable);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_source_authentication_parent_class)->dispose (object);
}

static void
source_authentication_finalize (GObject *object)
{
	ESourceAuthenticationPrivate *priv;

	priv = E_SOURCE_AUTHENTICATION_GET_PRIVATE (object);

	g_free (priv->host);
	g_free (priv->method);
	g_free (priv->proxy_uid);
	g_free (priv->user);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_authentication_parent_class)->finalize (object);
}

static void
e_source_authentication_class_init (ESourceAuthenticationClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceAuthenticationPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_authentication_set_property;
	object_class->get_property = source_authentication_get_property;
	object_class->dispose = source_authentication_dispose;
	object_class->finalize = source_authentication_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_AUTHENTICATION;

	g_object_class_install_property (
		object_class,
		PROP_CONNECTABLE,
		g_param_spec_object (
			"connectable",
			"Connectable",
			"A GSocketConnectable constructed "
			"from the host and port properties",
			G_TYPE_SOCKET_CONNECTABLE,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_HOST,
		g_param_spec_string (
			"host",
			"Host",
			"Host name for the remote account",
			"",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_METHOD,
		g_param_spec_string (
			"method",
			"Method",
			"Authentication method",
			"none",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_PORT,
		g_param_spec_uint (
			"port",
			"Port",
			"Port number for the remote account",
			0, G_MAXUINT16, 0,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_PROXY_UID,
		g_param_spec_string (
			"proxy-uid",
			"Proxy UID",
			"ESource UID of a proxy profile",
			"system-proxy",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_REMEMBER_PASSWORD,
		g_param_spec_boolean (
			"remember-password",
			"Remember Password",
			"Whether to offer to remember the "
			"password by default when prompted",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_USER,
		g_param_spec_string (
			"user",
			"User",
			"User name for the remote account",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	/* An empty string or NULL means to use E_SOURCE_CREDENTIAL_PASSWORD to pass
	   the stored "password" into the backend with e_source_invoke_authenticate()/_sync() */
	g_object_class_install_property (
		object_class,
		PROP_CREDENTIAL_NAME,
		g_param_spec_string (
			"credential-name",
			"Credential Name",
			"What name to use for the authentication method in credentials for authentication",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_authentication_init (ESourceAuthentication *extension)
{
	extension->priv = E_SOURCE_AUTHENTICATION_GET_PRIVATE (extension);
}

/**
 * e_source_authentication_required:
 * @extension: an #ESourceAuthentication
 *
 * This is a convenience function which returns whether authentication
 * is required at all, regardless of the method used.  This relies on
 * the convention of setting #ESourceAuthentication:method to "none"
 * when authentication is <emphasis>not</emphasis> required.
 *
 * Returns: whether authentication is required at all
 *
 * Since: 3.6
 **/
gboolean
e_source_authentication_required (ESourceAuthentication *extension)
{
	const gchar *method;

	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), FALSE);

	method = e_source_authentication_get_method (extension);
	g_return_val_if_fail (method != NULL && *method != '\0', FALSE);

	return (g_strcmp0 (method, "none") != 0);
}

/**
 * e_source_authentication_ref_connectable:
 * @extension: an #ESourceAuthentication
 *
 * Returns a #GSocketConnectable instance constructed from @extension's
 * #ESourceAuthentication:host and #ESourceAuthentication:port properties,
 * or %NULL if the #ESourceAuthentication:host is not set.
 *
 * The returned #GSocketConnectable is referenced for thread-safety and must
 * be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: (transfer full): a #GSocketConnectable, or %NULL
 *
 * Since: 3.8
 **/
GSocketConnectable *
e_source_authentication_ref_connectable (ESourceAuthentication *extension)
{
	GSocketConnectable *connectable = NULL;

	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (extension->priv->connectable != NULL)
		connectable = g_object_ref (extension->priv->connectable);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return connectable;
}

/**
 * e_source_authentication_get_host:
 * @extension: an #ESourceAuthentication
 *
 * Returns the host name used to authenticate to a remote account.
 *
 * Returns: the host name of a remote account
 *
 * Since: 3.6
 **/
const gchar *
e_source_authentication_get_host (ESourceAuthentication *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), NULL);

	return extension->priv->host;
}

/**
 * e_source_authentication_dup_host:
 * @extension: an #ESourceAuthentication
 *
 * Thread-safe variation of e_source_authentication_get_host().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceAuthentication:host
 *
 * Since: 3.6
 **/
gchar *
e_source_authentication_dup_host (ESourceAuthentication *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_authentication_get_host (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_authentication_set_host:
 * @extension: an #ESourceAuthentication
 * @host: (allow-none): a host name, or %NULL
 *
 * Sets the host name used to authenticate to a remote account.
 *
 * The internal copy of @host is automatically stripped of leading and
 * trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.6
 **/
void
e_source_authentication_set_host (ESourceAuthentication *extension,
                                  const gchar *host)
{
	g_return_if_fail (E_IS_SOURCE_AUTHENTICATION (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->host, host) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->host);
	extension->priv->host = e_util_strdup_strip (host);

	source_authentication_update_connectable (extension);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "host");

	/* Changing the host also changes the connectable. */
	g_object_notify (G_OBJECT (extension), "connectable");
}

/**
 * e_source_authentication_get_method:
 * @extension: an #ESourceAuthentication
 *
 * Returns the authentication method for a remote account.  There are
 * no pre-defined method names; backends are free to set this however
 * they wish.  If authentication is not required for a remote account,
 * the convention is to set #ESourceAuthentication:method to "none".
 *
 * Returns: the authentication method for a remote account
 *
 * Since: 3.6
 **/
const gchar *
e_source_authentication_get_method (ESourceAuthentication *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), NULL);

	return extension->priv->method;
}

/**
 * e_source_authentication_dup_method:
 * @extension: an #ESourceAuthentication
 *
 * Thread-safe variation of e_source_authentication_get_method().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceAuthentication:method
 *
 * Since: 3.6
 **/
gchar *
e_source_authentication_dup_method (ESourceAuthentication *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_authentication_get_method (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_authentication_set_method:
 * @extension: an #ESourceAuthentication
 * @method: (allow-none): authentication method, or %NULL
 *
 * Sets the authentication method for a remote account.  There are no
 * pre-defined method names; backends are free to set this however they
 * wish.  If authentication is not required for a remote account, the
 * convention is to set the method to "none".  In keeping with that
 * convention, #ESourceAuthentication:method will be set to "none" if
 * @method is %NULL or an empty string.
 *
 * Since: 3.6
 **/
void
e_source_authentication_set_method (ESourceAuthentication *extension,
                                    const gchar *method)
{
	g_return_if_fail (E_IS_SOURCE_AUTHENTICATION (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->method, method) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->method);
	extension->priv->method = e_util_strdup_strip (method);

	if (extension->priv->method == NULL)
		extension->priv->method = g_strdup ("none");

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "method");
}

/**
 * e_source_authentication_get_port:
 * @extension: an #ESourceAuthentication
 *
 * Returns the port number used to authenticate to a remote account.
 *
 * Returns: the port number of a remote account
 *
 * Since: 3.6
 **/
guint16
e_source_authentication_get_port (ESourceAuthentication *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), 0);

	return extension->priv->port;
}

/**
 * e_source_authentication_set_port:
 * @extension: an #ESourceAuthentication
 * @port: a port number
 *
 * Sets the port number used to authenticate to a remote account.
 *
 * Since: 3.6
 **/
void
e_source_authentication_set_port (ESourceAuthentication *extension,
                                  guint16 port)
{
	g_return_if_fail (E_SOURCE_AUTHENTICATION (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (extension->priv->port == port) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	extension->priv->port = port;

	source_authentication_update_connectable (extension);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "port");

	/* Changing the port also changes the connectable. */
	g_object_notify (G_OBJECT (extension), "connectable");
}

/**
 * e_source_authentication_get_proxy_uid:
 * @extension: an #ESourceAuthentication
 *
 * Returns the #ESource:uid of the #ESource that holds network proxy
 * settings for use when connecting to a remote account.
 *
 * Returns: the proxy profile #ESource:uid
 *
 * Since: 3.12
 **/
const gchar *
e_source_authentication_get_proxy_uid (ESourceAuthentication *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), NULL);

	return extension->priv->proxy_uid;
}

/**
 * e_source_authentication_dup_proxy_uid:
 * @extension: an #ESourceAuthentication
 *
 * Thread-safe variation of e_source_authentication_get_proxy_uid().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceAuthentication:proxy-uid
 *
 * Since: 3.12
 **/
gchar *
e_source_authentication_dup_proxy_uid (ESourceAuthentication *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_authentication_get_proxy_uid (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_authentication_set_proxy_uid:
 * @extension: an #ESourceAuthentication
 * @proxy_uid: the proxy profile #ESource:uid
 *
 * Sets the #ESource:uid of the #ESource that holds network proxy settings
 * for use when connecting to a remote account.
 *
 * Since: 3.12
 **/
void
e_source_authentication_set_proxy_uid (ESourceAuthentication *extension,
                                       const gchar *proxy_uid)
{
	g_return_if_fail (E_IS_SOURCE_AUTHENTICATION (extension));
	g_return_if_fail (proxy_uid != NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (g_strcmp0 (proxy_uid, extension->priv->proxy_uid) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->proxy_uid);
	extension->priv->proxy_uid = g_strdup (proxy_uid);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "proxy-uid");
}

/**
 * e_source_authentication_get_remember_password:
 * @extension: an #ESourceAuthentication
 *
 * Returns whether to offer to remember the provided password by default
 * in password prompts.  This way, if the user unchecks the option it will
 * be unchecked by default in future password prompts.
 *
 * Returns: whether to offer to remember the password by default
 *
 * Since: 3.10
 **/
gboolean
e_source_authentication_get_remember_password (ESourceAuthentication *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), FALSE);

	return extension->priv->remember_password;
}

/**
 * e_source_authentication_set_remember_password:
 * @extension: an #ESourceAuthentication
 * @remember_password: whether to offer to remember the password by default
 *
 * Sets whether to offer to remember the provided password by default in
 * password prompts.  This way, if the user unchecks the option it will be
 * unchecked by default in future password prompts.
 *
 * Since: 3.10
 **/
void
e_source_authentication_set_remember_password (ESourceAuthentication *extension,
                                               gboolean remember_password)
{
	g_return_if_fail (E_IS_SOURCE_AUTHENTICATION (extension));

	if (extension->priv->remember_password == remember_password)
		return;

	extension->priv->remember_password = remember_password;

	g_object_notify (G_OBJECT (extension), "remember-password");
}

/**
 * e_source_authentication_get_user:
 * @extension: an #ESourceAuthentication
 *
 * Returns the user name used to authenticate to a remote account.
 *
 * Returns: the user name of a remote account
 *
 * Since: 3.6
 **/
const gchar *
e_source_authentication_get_user (ESourceAuthentication *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), NULL);

	return extension->priv->user;
}

/**
 * e_source_authentication_dup_user:
 * @extension: an #ESourceAuthentication
 *
 * Thread-safe variation of e_source_authentication_get_user().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceAuthentication:user
 *
 * Since: 3.6
 **/
gchar *
e_source_authentication_dup_user (ESourceAuthentication *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_authentication_get_user (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_authentication_set_user:
 * @extension: an #ESourceAuthentication
 * @user: (allow-none): a user name, or %NULL
 *
 * Sets the user name used to authenticate to a remote account.
 *
 * The internal copy of @user is automatically stripped of leading and
 * trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.6
 **/
void
e_source_authentication_set_user (ESourceAuthentication *extension,
                                  const gchar *user)
{
	g_return_if_fail (E_IS_SOURCE_AUTHENTICATION (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->user, user) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->user);
	extension->priv->user = e_util_strdup_strip (user);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "user");
}

/**
 * e_source_authentication_get_credential_name:
 * @extension: an #ESourceAuthentication
 *
 * Returns the credential name used to pass the stored or gathered credential
 * (like password) into the e_source_invoke_authenticate(). This is
 * a counterpart of the authentication method. The %NULL means to use
 * the default name, which is #E_SOURCE_CREDENTIAL_PASSWORD.
 *
 * Returns: the credential name to use for authentication, or %NULL
 *
 * Since: 3.16
 **/
const gchar *
e_source_authentication_get_credential_name (ESourceAuthentication *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), NULL);

	return extension->priv->credential_name;
}

/**
 * e_source_authentication_dup_credential_name:
 * @extension: an #ESourceAuthentication
 *
 * Thread-safe variation of e_source_authentication_get_credential_name().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceAuthentication:credential-name
 *
 * Since: 3.16
 **/
gchar *
e_source_authentication_dup_credential_name (ESourceAuthentication *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_AUTHENTICATION (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_authentication_get_credential_name (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_authentication_set_credential_name:
 * @extension: an #ESourceAuthentication
 * @credential_name: (allow-none): a credential name, or %NULL
 *
 * Sets the credential name used to pass the stored or gathered credential
 * (like password) into the e_source_invoke_authenticate(). This is
 * a counterpart of the authentication method. The %NULL means to use
 * the default name, which is #E_SOURCE_CREDENTIAL_PASSWORD.
 *
 * The internal copy of @credential_name is automatically stripped
 * of leading and trailing whitespace. If the resulting string is
 * empty, %NULL is set instead.
 *
 * Since: 3.16
 **/
void
e_source_authentication_set_credential_name (ESourceAuthentication *extension,
					     const gchar *credential_name)
{
	g_return_if_fail (E_IS_SOURCE_AUTHENTICATION (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->credential_name, credential_name) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->credential_name);
	extension->priv->credential_name = e_util_strdup_strip (credential_name);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "credential-name");
}
