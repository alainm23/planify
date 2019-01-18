/*
 * camel-network-settings.c
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

#include "camel-network-settings.h"

#include <camel/camel-enumtypes.h>
#include <camel/camel-settings.h>
#include <camel/camel-net-utils.h>

#define AUTH_MECHANISM_KEY  "CamelNetworkSettings:auth-mechanism"
#define HOST_KEY            "CamelNetworkSettings:host"
#define PORT_KEY            "CamelNetworkSettings:port"
#define SECURITY_METHOD_KEY "CamelNetworkSettings:security-method"
#define USER_KEY            "CamelNetworkSettings:user"

/* XXX Because interfaces have no initialization method, we can't
 *     allocate a per-instance mutex in a thread-safe manner.  So
 *     we have to use a single static mutex for all instances. */
G_LOCK_DEFINE_STATIC (property_lock);

G_DEFINE_INTERFACE (
	CamelNetworkSettings,
	camel_network_settings,
	CAMEL_TYPE_SETTINGS)

static void
camel_network_settings_default_init (CamelNetworkSettingsInterface *iface)
{
	g_object_interface_install_property (
		iface,
		g_param_spec_string (
			"auth-mechanism",
			"Auth Mechanism",
			"Authentication mechanism name",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_STATIC_STRINGS));

	g_object_interface_install_property (
		iface,
		g_param_spec_string (
			"host",
			"Host",
			"Host name for the network service",
			"",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_STATIC_STRINGS));

	g_object_interface_install_property (
		iface,
		g_param_spec_uint (
			"port",
			"Port",
			"Port number for the network service",
			0, G_MAXUINT16, 0,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_STATIC_STRINGS));

	g_object_interface_install_property (
		iface,
		g_param_spec_enum (
			"security-method",
			"Security Method",
			"Method used to establish a network connection",
			CAMEL_TYPE_NETWORK_SECURITY_METHOD,
			CAMEL_NETWORK_SECURITY_METHOD_STARTTLS_ON_STANDARD_PORT,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_STATIC_STRINGS));

	g_object_interface_install_property (
		iface,
		g_param_spec_string (
			"user",
			"User",
			"User name for the network account",
			g_get_user_name (),
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_STATIC_STRINGS));
}

/**
 * camel_network_settings_get_auth_mechanism:
 * @settings: a #CamelNetworkSettings
 *
 * Returns the mechanism name used to authenticate to a network service.
 * Often this refers to a SASL mechanism such as "LOGIN" or "GSSAPI".
 *
 * Returns: the authentication mechanism name
 *
 * Since: 3.4
 **/
const gchar *
camel_network_settings_get_auth_mechanism (CamelNetworkSettings *settings)
{
	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	return g_object_get_data (G_OBJECT (settings), AUTH_MECHANISM_KEY);
}

/**
 * camel_network_settings_dup_auth_mechanism:
 * @settings: a #CamelNetworkSettings
 *
 * Thread-safe variation of camel_network_settings_get_auth_mechanism().
 * Use this function when accessing @settings from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #CamelNetworkSettings:auth-mechanism
 *
 * Since: 3.4
 **/
gchar *
camel_network_settings_dup_auth_mechanism (CamelNetworkSettings *settings)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	G_LOCK (property_lock);

	protected = camel_network_settings_get_auth_mechanism (settings);
	duplicate = g_strdup (protected);

	G_UNLOCK (property_lock);

	return duplicate;
}

/**
 * camel_network_settings_set_auth_mechanism:
 * @settings: a #CamelNetworkSettings
 * @auth_mechanism: an authentication mechanism name, or %NULL
 *
 * Sets the mechanism name used to authenticate to a network service.
 * Often this refers to a SASL mechanism such as "LOGIN" or "GSSAPI".
 * The #CamelNetworkSettings:auth-mechanism property is automatically
 * stripped of leading and trailing whitespace.
 *
 * Since: 3.4
 **/
void
camel_network_settings_set_auth_mechanism (CamelNetworkSettings *settings,
                                           const gchar *auth_mechanism)
{
	gchar *stripped_auth_mechanism = NULL;

	g_return_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings));

	/* Strip leading and trailing whitespace. */
	if (auth_mechanism != NULL)
		stripped_auth_mechanism =
			g_strstrip (g_strdup (auth_mechanism));

	G_LOCK (property_lock);

	g_object_set_data_full (
		G_OBJECT (settings),
		AUTH_MECHANISM_KEY,
		stripped_auth_mechanism,
		(GDestroyNotify) g_free);

	G_UNLOCK (property_lock);

	g_object_notify (G_OBJECT (settings), "auth-mechanism");
}

/**
 * camel_network_settings_get_host:
 * @settings: a #CamelNetworkSettings
 *
 * Returns the host name used to authenticate to a network service.
 *
 * Returns: the host name of a network service
 *
 * Since: 3.4
 **/
const gchar *
camel_network_settings_get_host (CamelNetworkSettings *settings)
{
	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	return g_object_get_data (G_OBJECT (settings), HOST_KEY);
}

/**
 * camel_network_settings_dup_host:
 * @settings: a #CamelNetworkSettings
 *
 * Thread-safe variation of camel_network_settings_get_host().
 * Use this function when accessing @settings from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #CamelNetworkSettings:host
 *
 * Since: 3.4
 **/
gchar *
camel_network_settings_dup_host (CamelNetworkSettings *settings)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	G_LOCK (property_lock);

	protected = camel_network_settings_get_host (settings);
	duplicate = g_strdup (protected);

	G_UNLOCK (property_lock);

	return duplicate;
}

/**
 * camel_network_settings_dup_host_ensure_ascii:
 * @settings: a #CamelNetworkSettings
 *
 * Just like camel_network_settings_dup_host(), only makes sure that
 * the returned host name will be converted into its ASCII form in case
 * of IDNA value.
 *
 * Returns: a newly-allocated copy of #CamelNetworkSettings:host with
 *    only ASCII letters.
 *
 * Since: 3.16
 **/
gchar *
camel_network_settings_dup_host_ensure_ascii (CamelNetworkSettings *settings)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	G_LOCK (property_lock);

	protected = camel_network_settings_get_host (settings);
	if (protected && *protected)
		duplicate = camel_host_idna_to_ascii (protected);
	else
		duplicate = g_strdup (protected);

	G_UNLOCK (property_lock);

	return duplicate;
}

/**
 * camel_network_settings_set_host:
 * @settings: a #CamelNetworkSettings
 * @host: a host name, or %NULL
 *
 * Sets the host name used to authenticate to a network service.  The
 * #CamelNetworkSettings:host property is automatically stripped of
 * leading and trailing whitespace.
 *
 * Since: 3.4
 **/
void
camel_network_settings_set_host (CamelNetworkSettings *settings,
                                 const gchar *host)
{
	gchar *stripped_host = NULL;

	g_return_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings));

	/* Make sure this property is never NULL. */
	if (host == NULL)
		host = "";

	/* Strip leading and trailing whitespace. */
	stripped_host = g_strstrip (g_strdup (host));

	G_LOCK (property_lock);

	g_object_set_data_full (
		G_OBJECT (settings),
		HOST_KEY, stripped_host,
		(GDestroyNotify) g_free);

	G_UNLOCK (property_lock);

	g_object_notify (G_OBJECT (settings), "host");
}

/**
 * camel_network_settings_get_port:
 * @settings: a #CamelNetworkSettings
 *
 * Returns the port number used to authenticate to a network service.
 *
 * Returns: the port number of a network service
 *
 * Since: 3.4
 **/
guint16
camel_network_settings_get_port (CamelNetworkSettings *settings)
{
	gpointer data;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), 0);

	data = g_object_get_data (G_OBJECT (settings), PORT_KEY);

	return (guint16) GPOINTER_TO_UINT (data);
}

/**
 * camel_network_settings_set_port:
 * @settings: a #CamelNetworkSettings
 * @port: a port number
 *
 * Sets the port number used to authenticate to a network service.
 *
 * Since: 3.4
 **/
void
camel_network_settings_set_port (CamelNetworkSettings *settings,
                                 guint16 port)
{
	g_return_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings));

	g_object_set_data (
		G_OBJECT (settings), PORT_KEY,
		GUINT_TO_POINTER ((guint) port));

	g_object_notify (G_OBJECT (settings), "port");
}

/**
 * camel_network_settings_get_security_method:
 * @settings: a #CamelNetworkSettings
 *
 * Returns the method used to establish a secure (or unsecure) network
 * connection.
 *
 * Returns: the security method
 *
 * Since: 3.2
 **/
CamelNetworkSecurityMethod
camel_network_settings_get_security_method (CamelNetworkSettings *settings)
{
	gpointer data;

	g_return_val_if_fail (
		CAMEL_IS_NETWORK_SETTINGS (settings),
		CAMEL_NETWORK_SECURITY_METHOD_NONE);

	data = g_object_get_data (G_OBJECT (settings), SECURITY_METHOD_KEY);

	return (CamelNetworkSecurityMethod) GPOINTER_TO_INT (data);
}

/**
 * camel_network_settings_set_security_method:
 * @settings: a #CamelNetworkSettings
 * @method: the security method
 *
 * Sets the method used to establish a secure (or unsecure) network
 * connection.  Note that changing this setting has no effect on an
 * already-established network connection.
 *
 * Since: 3.2
 **/
void
camel_network_settings_set_security_method (CamelNetworkSettings *settings,
                                            CamelNetworkSecurityMethod method)
{
	g_return_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings));

	g_object_set_data (
		G_OBJECT (settings),
		SECURITY_METHOD_KEY,
		GINT_TO_POINTER (method));

	g_object_notify (G_OBJECT (settings), "security-method");
}

/**
 * camel_network_settings_get_user:
 * @settings: a #CamelNetworkSettings
 *
 * Returns the user name used to authenticate to a network service.
 *
 * Returns: the user name of a network service
 *
 * Since: 3.4
 **/
const gchar *
camel_network_settings_get_user (CamelNetworkSettings *settings)
{
	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	return g_object_get_data (G_OBJECT (settings), USER_KEY);
}

/**
 * camel_network_settings_dup_user:
 * @settings: a #CamelNetworkSettings
 *
 * Thread-safe variation of camel_network_settings_get_user().
 * Use this function when accessing @settings from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #CamelNetworkSettings:user
 *
 * Since: 3.4
 **/
gchar *
camel_network_settings_dup_user (CamelNetworkSettings *settings)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	G_LOCK (property_lock);

	protected = camel_network_settings_get_user (settings);
	duplicate = g_strdup (protected);

	G_UNLOCK (property_lock);

	return duplicate;
}

/**
 * camel_network_settings_set_user:
 * @settings: a #CamelNetworkSettings
 * @user: a user name, or %NULL
 *
 * Sets the user name used to authenticate to a network service.  The
 * #CamelNetworkSettings:user property is automatically stripped of
 * leading and trailing whitespace.
 *
 * Since: 3.4
 **/
void
camel_network_settings_set_user (CamelNetworkSettings *settings,
                                 const gchar *user)
{
	gchar *stripped_user = NULL;

	g_return_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings));

	/* Make sure this property is never NULL. */
	if (user == NULL)
		user = "";

	/* Strip leading and trailing whitespace. */
	stripped_user = g_strstrip (g_strdup (user));

	G_LOCK (property_lock);

	g_object_set_data_full (
		G_OBJECT (settings),
		USER_KEY, stripped_user,
		(GDestroyNotify) g_free);

	G_UNLOCK (property_lock);

	g_object_notify (G_OBJECT (settings), "user");
}

