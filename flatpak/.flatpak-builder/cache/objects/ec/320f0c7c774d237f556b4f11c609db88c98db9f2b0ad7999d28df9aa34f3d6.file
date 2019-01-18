/*
 * e-source-proxy.c
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
 * SECTION: e-source-proxy
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for network proxy settings
 *
 * The #ESourceProxy extension defines a network proxy profile.
 *
 * An #ESource instance with this extension can serve as a #GProxyResolver.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceProxy *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_PROXY);
 * ]|
 **/

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include <libedataserver/e-source-enumtypes.h>
#include <libedataserver/e-data-server-util.h>

#include "e-source-proxy.h"

#define E_SOURCE_PROXY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_PROXY, ESourceProxyPrivate))

typedef struct _AsyncContext AsyncContext;

struct _ESourceProxyPrivate {
	EProxyMethod method;
	gchar *autoconfig_url;
	gchar **ignore_hosts;

	gchar *ftp_host;
	guint16 ftp_port;

	gchar *http_host;
	guint16 http_port;
	gboolean http_use_auth;
	gchar *http_auth_user;
	gchar *http_auth_password;

	gchar *https_host;
	guint16 https_port;

	gchar *socks_host;
	guint16 socks_port;
};

struct _AsyncContext {
	gchar *uri;
	gchar **proxies;
};

enum {
	PROP_0,
	PROP_AUTOCONFIG_URL,
	PROP_FTP_HOST,
	PROP_FTP_PORT,
	PROP_HTTP_AUTH_PASSWORD,
	PROP_HTTP_AUTH_USER,
	PROP_HTTP_HOST,
	PROP_HTTP_PORT,
	PROP_HTTP_USE_AUTH,
	PROP_HTTPS_HOST,
	PROP_HTTPS_PORT,
	PROP_IGNORE_HOSTS,
	PROP_METHOD,
	PROP_SOCKS_HOST,
	PROP_SOCKS_PORT
};

G_DEFINE_TYPE (
	ESourceProxy,
	e_source_proxy,
	E_TYPE_SOURCE_EXTENSION)

static void
async_context_free (AsyncContext *async_context)
{
	g_free (async_context->uri);
	g_strfreev (async_context->proxies);

	g_slice_free (AsyncContext, async_context);
}

static gchar **
source_proxy_direct (void)
{
	gchar **proxies;

	proxies = g_new (gchar *, 2);
	proxies[0] = g_strdup ("direct://");
	proxies[1] = NULL;

	return proxies;
}

static gchar *
source_proxy_dup_http_proxy (ESourceProxy *extension,
                             const gchar *http_host,
                             guint16 http_port)
{
	GString *http_proxy = g_string_new ("http://");

	if (e_source_proxy_get_http_use_auth (extension)) {
		gchar *http_user;
		gchar *http_pass;
		gchar *enc_http_user;
		gchar *enc_http_pass;

		http_user = e_source_proxy_dup_http_auth_user (extension);
		http_pass = e_source_proxy_dup_http_auth_password (extension);

		enc_http_user = g_uri_escape_string (http_user, NULL, TRUE);
		enc_http_pass = g_uri_escape_string (http_pass, NULL, TRUE);

		g_string_append (http_proxy, enc_http_user);
		g_string_append_c (http_proxy, ':');
		g_string_append (http_proxy, enc_http_pass);
		g_string_append_c (http_proxy, '@');

		g_free (enc_http_user);
		g_free (enc_http_pass);

		g_free (http_user);
		g_free (http_pass);
	}

	g_string_append_printf (http_proxy, "%s:%u", http_host, http_port);

	return g_string_free (http_proxy, FALSE);
}

static gchar **
source_proxy_lookup_pacrunner (ESource *source,
                               const gchar *uri,
                               GCancellable *cancellable,
                               GError **error)
{
	GDBusProxy *pacrunner;
	ESourceProxy *extension;
	const gchar *extension_name;
	gchar *autoconfig_url;
	gchar **proxies = NULL;

	extension_name = E_SOURCE_EXTENSION_PROXY;
	extension = e_source_get_extension (source, extension_name);
	autoconfig_url = e_source_proxy_dup_autoconfig_url (extension);

	if (autoconfig_url == NULL) {
		proxies = source_proxy_direct ();
		goto exit;
	}

	pacrunner = g_dbus_proxy_new_for_bus_sync (
		G_BUS_TYPE_SESSION,
		G_DBUS_PROXY_FLAGS_DO_NOT_LOAD_PROPERTIES |
		G_DBUS_PROXY_FLAGS_DO_NOT_CONNECT_SIGNALS,
		NULL,
		"org.gtk.GLib.PACRunner",
		"/org/gtk/GLib/PACRunner",
		"org.gtk.GLib.PACRunner",
		cancellable, error);

	if (pacrunner != NULL) {
		GVariant *variant_proxies;

		variant_proxies = g_dbus_proxy_call_sync (
			pacrunner, "Lookup",
			g_variant_new ("(ss)", autoconfig_url, uri),
			G_DBUS_CALL_FLAGS_NONE, -1,
			cancellable, error);

		if (variant_proxies != NULL) {
			g_variant_get (variant_proxies, "(^as)", &proxies);
			g_variant_unref (variant_proxies);
		}

		g_object_unref (pacrunner);
	}

exit:
	g_free (autoconfig_url);

	return proxies;
}

static void
source_proxy_set_property (GObject *object,
                           guint property_id,
                           const GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_AUTOCONFIG_URL:
			e_source_proxy_set_autoconfig_url (
				E_SOURCE_PROXY (object),
				g_value_get_string (value));
			return;

		case PROP_FTP_HOST:
			e_source_proxy_set_ftp_host (
				E_SOURCE_PROXY (object),
				g_value_get_string (value));
			return;

		case PROP_FTP_PORT:
			e_source_proxy_set_ftp_port (
				E_SOURCE_PROXY (object),
				g_value_get_uint (value));
			return;

		case PROP_HTTP_AUTH_PASSWORD:
			e_source_proxy_set_http_auth_password (
				E_SOURCE_PROXY (object),
				g_value_get_string (value));
			return;

		case PROP_HTTP_AUTH_USER:
			e_source_proxy_set_http_auth_user (
				E_SOURCE_PROXY (object),
				g_value_get_string (value));
			return;

		case PROP_HTTP_HOST:
			e_source_proxy_set_http_host (
				E_SOURCE_PROXY (object),
				g_value_get_string (value));
			return;

		case PROP_HTTP_PORT:
			e_source_proxy_set_http_port (
				E_SOURCE_PROXY (object),
				g_value_get_uint (value));
			return;

		case PROP_HTTP_USE_AUTH:
			e_source_proxy_set_http_use_auth (
				E_SOURCE_PROXY (object),
				g_value_get_boolean (value));
			return;

		case PROP_HTTPS_HOST:
			e_source_proxy_set_https_host (
				E_SOURCE_PROXY (object),
				g_value_get_string (value));
			return;

		case PROP_HTTPS_PORT:
			e_source_proxy_set_https_port (
				E_SOURCE_PROXY (object),
				g_value_get_uint (value));
			return;

		case PROP_IGNORE_HOSTS:
			e_source_proxy_set_ignore_hosts (
				E_SOURCE_PROXY (object),
				g_value_get_boxed (value));
			return;

		case PROP_METHOD:
			e_source_proxy_set_method (
				E_SOURCE_PROXY (object),
				g_value_get_enum (value));
			return;

		case PROP_SOCKS_HOST:
			e_source_proxy_set_socks_host (
				E_SOURCE_PROXY (object),
				g_value_get_string (value));
			return;

		case PROP_SOCKS_PORT:
			e_source_proxy_set_socks_port (
				E_SOURCE_PROXY (object),
				g_value_get_uint (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_proxy_get_property (GObject *object,
                           guint property_id,
                           GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_AUTOCONFIG_URL:
			g_value_take_string (
				value,
				e_source_proxy_dup_autoconfig_url (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_FTP_HOST:
			g_value_take_string (
				value,
				e_source_proxy_dup_ftp_host (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_FTP_PORT:
			g_value_set_uint (
				value,
				e_source_proxy_get_ftp_port (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_HTTP_AUTH_PASSWORD:
			g_value_take_string (
				value,
				e_source_proxy_dup_http_auth_password (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_HTTP_AUTH_USER:
			g_value_take_string (
				value,
				e_source_proxy_dup_http_auth_user (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_HTTP_HOST:
			g_value_take_string (
				value,
				e_source_proxy_dup_http_host (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_HTTP_PORT:
			g_value_set_uint (
				value,
				e_source_proxy_get_http_port (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_HTTP_USE_AUTH:
			g_value_set_boolean (
				value,
				e_source_proxy_get_http_use_auth (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_HTTPS_HOST:
			g_value_take_string (
				value,
				e_source_proxy_dup_https_host (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_HTTPS_PORT:
			g_value_set_uint (
				value,
				e_source_proxy_get_https_port (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_IGNORE_HOSTS:
			g_value_take_boxed (
				value,
				e_source_proxy_dup_ignore_hosts (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_METHOD:
			g_value_set_enum (
				value,
				e_source_proxy_get_method (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_SOCKS_HOST:
			g_value_take_string (
				value,
				e_source_proxy_dup_socks_host (
				E_SOURCE_PROXY (object)));
			return;

		case PROP_SOCKS_PORT:
			g_value_set_uint (
				value,
				e_source_proxy_get_socks_port (
				E_SOURCE_PROXY (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_proxy_finalize (GObject *object)
{
	ESourceProxyPrivate *priv;

	priv = E_SOURCE_PROXY_GET_PRIVATE (object);

	g_free (priv->autoconfig_url);
	g_strfreev (priv->ignore_hosts);
	g_free (priv->ftp_host);
	g_free (priv->http_host);
	g_free (priv->http_auth_user);
	g_free (priv->http_auth_password);
	g_free (priv->https_host);
	g_free (priv->socks_host);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_proxy_parent_class)->finalize (object);
}

static void
e_source_proxy_class_init (ESourceProxyClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceProxyPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_proxy_set_property;
	object_class->get_property = source_proxy_get_property;
	object_class->finalize = source_proxy_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_PROXY;

	g_object_class_install_property (
		object_class,
		PROP_AUTOCONFIG_URL,
		g_param_spec_string (
			"autoconfig-url",
			"Autoconfig URL",
			"Proxy autoconfiguration URL",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_FTP_HOST,
		g_param_spec_string (
			"ftp-host",
			"FTP Host",
			"FTP proxy host name",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_FTP_PORT,
		g_param_spec_uint (
			"ftp-port",
			"FTP Port",
			"FTP proxy port",
			0, G_MAXUINT16, 0,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_HTTP_AUTH_PASSWORD,
		g_param_spec_string (
			"http-auth-password",
			"HTTP Auth Password",
			"HTTP proxy password",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_HTTP_AUTH_USER,
		g_param_spec_string (
			"http-auth-user",
			"HTTP Auth User",
			"HTTP proxy username",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_HTTP_HOST,
		g_param_spec_string (
			"http-host",
			"HTTP Host",
			"HTTP proxy host name",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_HTTP_PORT,
		g_param_spec_uint (
			"http-port",
			"HTTP Port",
			"HTTP proxy port",
			0, G_MAXUINT16, 8080,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_HTTP_USE_AUTH,
		g_param_spec_boolean (
			"http-use-auth",
			"HTTP Use Auth",
			"Whether HTTP proxy server "
			"connections require authentication",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_HTTPS_HOST,
		g_param_spec_string (
			"https-host",
			"HTTPS Host",
			"Secure HTTP proxy host name",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_HTTPS_PORT,
		g_param_spec_uint (
			"https-port",
			"HTTPS Port",
			"Secure HTTP proxy port",
			0, G_MAXUINT16, 0,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_IGNORE_HOSTS,
		g_param_spec_boxed (
			"ignore-hosts",
			"Ignore Hosts",
			"Hosts to connect directly",
			G_TYPE_STRV,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_METHOD,
		g_param_spec_enum (
			"method",
			"Method",
			"Proxy configuration method",
			E_TYPE_PROXY_METHOD,
			E_PROXY_METHOD_DEFAULT,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_SOCKS_HOST,
		g_param_spec_string (
			"socks-host",
			"SOCKS Host",
			"SOCKS proxy host name",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_SOCKS_PORT,
		g_param_spec_uint (
			"socks-port",
			"SOCKS Port",
			"SOCKS proxy port",
			0, G_MAXUINT16, 0,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_proxy_init (ESourceProxy *extension)
{
	extension->priv = E_SOURCE_PROXY_GET_PRIVATE (extension);
}

/**
 * e_source_proxy_get_method:
 * @extension: an #ESourceProxy
 *
 * Returns the proxy configuration method for @extension.
 *
 * The proxy configuration method determines the behavior of
 * e_source_proxy_lookup().
 *
 * Returns: the proxy configuration method
 *
 * Since: 3.12
 **/
EProxyMethod
e_source_proxy_get_method (ESourceProxy *extension)
{
	g_return_val_if_fail (
		E_IS_SOURCE_PROXY (extension),
		E_PROXY_METHOD_DEFAULT);

	return extension->priv->method;
}

/**
 * e_source_proxy_set_method:
 * @extension: an #ESourceProxy
 * @method: the proxy configuration method
 *
 * Sets the proxy configuration method for @extension.
 *
 * The proxy configuration method determines the behavior of
 * e_source_proxy_lookup().
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_method (ESourceProxy *extension,
                           EProxyMethod method)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	if (method == extension->priv->method)
		return;

	extension->priv->method = method;

	g_object_notify (G_OBJECT (extension), "method");
}

/**
 * e_source_proxy_get_autoconfig_url:
 * @extension: an #ESourceProxy
 *
 * Returns the URL that provides proxy configuration values.  When the
 * @extension's #ESourceProxy:method is @E_PROXY_METHOD_AUTO, this URL
 * is used to look up proxy information for all protocols.
 *
 * Returns: the autoconfiguration URL
 *
 * Since: 3.12
 **/
const gchar *
e_source_proxy_get_autoconfig_url (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	return extension->priv->autoconfig_url;
}

/**
 * e_source_proxy_dup_autoconfig_url:
 * @extension: an #ESourceProxy
 *
 * Thread-safe variation of e_source_proxy_get_autoconfig_url().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceProxy:autoconfig-url
 *
 * Since: 3.12
 **/
gchar *
e_source_proxy_dup_autoconfig_url (ESourceProxy *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_proxy_get_autoconfig_url (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_proxy_set_autoconfig_url:
 * @extension: an #ESourceProxy
 * @autoconfig_url: an autoconfiguration URL
 *
 * Sets the URL that provides proxy configuration values.  When the
 * @extension's #ESourceProxy:method is @E_PROXY_METHOD_AUTO, this URL
 * is used to look up proxy information for all protocols.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_autoconfig_url (ESourceProxy *extension,
                                   const gchar *autoconfig_url)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (autoconfig_url, extension->priv->autoconfig_url) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->autoconfig_url);
	extension->priv->autoconfig_url = e_util_strdup_strip (autoconfig_url);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "autoconfig-url");
}

/**
 * e_source_proxy_get_ignore_hosts:
 * @extension: an #ESourceProxy
 *
 * Returns a %NULL-terminated string array of hosts which are connected to
 * directly, rather than via the proxy (if it is active).  The array elements
 * can be hostnames, domains (using an initial wildcard like *.foo.com), IP
 * host addresses (both IPv4 and IPv6) and network addresses with a netmask
 * (something like 192.168.0.0/24).
 *
 * The returned array is owned by @extension and should not be modified or
 * freed.
 *
 * Returns: (transfer none): a %NULL-terminated string array of hosts
 *
 * Since: 3.12
 **/
const gchar * const *
e_source_proxy_get_ignore_hosts (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	return (const gchar * const *) extension->priv->ignore_hosts;
}

/**
 * e_source_proxy_dup_ignore_hosts:
 * @extension: an #ESourceProxy
 *
 * Thread-safe variation of e_source_proxy_get_ignore_hosts().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string array should be freed with g_strfreev() when no
 * longer needed.
 *
 * Returns: (transfer full): a newly-allocated copy of
 *          #ESourceProxy:ignore-hosts
 *
 * Since: 3.12
 **/
gchar **
e_source_proxy_dup_ignore_hosts (ESourceProxy *extension)
{
	const gchar * const *protected;
	gchar **duplicate;

	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_proxy_get_ignore_hosts (extension);
	duplicate = g_strdupv ((gchar **) protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_proxy_set_ignore_hosts:
 * @extension: an #ESourceProxy
 * @ignore_hosts: a %NULL-terminated string array of hosts
 *
 * Sets the hosts which are connected to directly, rather than via the proxy
 * (if it is active).  The array elements can be hostnames, domains (using an
 * initial wildcard like *.foo.com), IP host addresses (both IPv4 and IPv6)
 * and network addresses with a netmask (something like 192.168.0.0/24).
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_ignore_hosts (ESourceProxy *extension,
                                 const gchar * const *ignore_hosts)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strv_equal (ignore_hosts, extension->priv->ignore_hosts)) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_strfreev (extension->priv->ignore_hosts);
	extension->priv->ignore_hosts = g_strdupv ((gchar **) ignore_hosts);

	/* Strip leading and trailing whitespace from each element. */
	if (extension->priv->ignore_hosts != NULL) {
		guint length, ii;

		length = g_strv_length (extension->priv->ignore_hosts);
		for (ii = 0; ii < length; ii++)
			g_strstrip (extension->priv->ignore_hosts[ii]);
	}

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "ignore-hosts");
}

/**
 * e_source_proxy_get_ftp_host:
 * @extension: an #ESourceProxy
 *
 * Returns the machine name to proxy FTP through when @extension's
 * #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Returns: FTP proxy host name
 *
 * Since: 3.12
 **/
const gchar *
e_source_proxy_get_ftp_host (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	return extension->priv->ftp_host;
}

/**
 * e_source_proxy_dup_ftp_host:
 * @extension: an #ESourceProxy
 *
 * Thread-safe variation of e_source_proxy_get_ftp_host().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceProxy:ftp-host
 *
 * Since: 3.12
 **/
gchar *
e_source_proxy_dup_ftp_host (ESourceProxy *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_proxy_get_ftp_host (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_proxy_set_ftp_host:
 * @extension: an #ESourceProxy
 * @ftp_host: FTP proxy host name
 *
 * Sets the machine name to proxy FTP through when @extension's
 * #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_ftp_host (ESourceProxy *extension,
                             const gchar *ftp_host)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (ftp_host, extension->priv->ftp_host) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->ftp_host);
	extension->priv->ftp_host = e_util_strdup_strip (ftp_host);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "ftp-host");
}

/**
 * e_source_proxy_get_ftp_port:
 * @extension: an #ESourceProxy
 *
 * Returns the port on the machine defined by #ESourceProxy:ftp-host to proxy
 * through when @extension's #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Returns: FTP proxy port
 *
 * Since: 3.12
 **/
guint16
e_source_proxy_get_ftp_port (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), 0);

	return extension->priv->ftp_port;
}

/**
 * e_source_proxy_set_ftp_port:
 * @extension: an #ESourceProxy
 * @ftp_port: FTP proxy port
 *
 * Sets the port on the machine defined by #ESourceProxy:ftp-host to proxy
 * through when @extension's #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_ftp_port (ESourceProxy *extension,
                             guint16 ftp_port)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	if (ftp_port == extension->priv->ftp_port)
		return;

	extension->priv->ftp_port = ftp_port;

	g_object_notify (G_OBJECT (extension), "ftp-port");
}

/**
 * e_source_proxy_get_http_host:
 * @extension: an #ESourceProxy
 *
 * Returns the machine name to proxy HTTP through when @extension's
 * #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Returns: HTTP proxy host name
 *
 * Since: 3.12
 **/
const gchar *
e_source_proxy_get_http_host (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	return extension->priv->http_host;
}

/**
 * e_source_proxy_dup_http_host:
 * @extension: an #ESourceProxy
 *
 * Thread-safe variation of e_source_proxy_get_http_host().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceProxy:http-host
 *
 * Since: 3.12
 **/
gchar *
e_source_proxy_dup_http_host (ESourceProxy *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_proxy_get_http_host (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_proxy_set_http_host:
 * @extension: an #ESourceProxy
 * @http_host: HTTP proxy host name
 *
 * Sets the machine name to proxy HTTP through when @extension's
 * #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_http_host (ESourceProxy *extension,
                              const gchar *http_host)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (http_host, extension->priv->http_host) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->http_host);
	extension->priv->http_host = e_util_strdup_strip (http_host);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "http-host");
}

/**
 * e_source_proxy_get_http_port:
 * @extension: an #ESourceProxy
 *
 * Returns the port on the machine defined by #ESourceProxy:http-host to proxy
 * through when @extension's #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Returns: HTTP proxy port
 *
 * Since: 3.12
 **/
guint16
e_source_proxy_get_http_port (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), 0);

	return extension->priv->http_port;
}

/**
 * e_source_proxy_set_http_port:
 * @extension: an #ESourceProxy
 * @http_port: HTTP proxy port
 *
 * Sets the port on the machine defined by #ESourceProxy:http-host to proxy
 * through when @extension's #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_http_port (ESourceProxy *extension,
                              guint16 http_port)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	if (http_port == extension->priv->http_port)
		return;

	extension->priv->http_port = http_port;

	g_object_notify (G_OBJECT (extension), "http-port");
}

/**
 * e_source_proxy_get_http_use_auth:
 * @extension: an #ESourceProxy
 *
 * Returns whether the HTTP proxy server at #ESourceProxy:http-host and
 * #ESourceProxy:http-port requires authentication.
 *
 * The username/password combo is defined by #ESourceProxy:http-auth-user
 * and #ESourceProxy:http-auth-password, but only applies when @extension's
 * #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Returns: whether to authenticate HTTP proxy connections
 *
 * Since: 3.12
 **/
gboolean
e_source_proxy_get_http_use_auth (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), FALSE);

	return extension->priv->http_use_auth;
}

/**
 * e_source_proxy_set_http_use_auth:
 * @extension: an #ESourceProxy
 * @http_use_auth: whether to authenticate HTTP proxy connections
 *
 * Sets whether the HTTP proxy server at #ESourceProxy:http-host and
 * #ESourceProxy:http-port requires authentication.
 *
 * The username/password combo is defined by #ESourceProxy:http-auth-user
 * and #ESourceProxy:http-auth-password, but only applies when @extension's
 * #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_http_use_auth (ESourceProxy *extension,
                                  gboolean http_use_auth)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	if (http_use_auth == extension->priv->http_use_auth)
		return;

	extension->priv->http_use_auth = http_use_auth;

	g_object_notify (G_OBJECT (extension), "http-use-auth");
}

/**
 * e_source_proxy_get_http_auth_user:
 * @extension: an #ESourceProxy
 *
 * Returns the user name to pass as authentication when doing HTTP proxying
 * and #ESourceProxy:http-use-auth is %TRUE.
 *
 * Returns: HTTP proxy username
 *
 * Since: 3.12
 **/
const gchar *
e_source_proxy_get_http_auth_user (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	return extension->priv->http_auth_user;
}

/**
 * e_source_proxy_dup_http_auth_user:
 * @extension: an #ESourceProxy
 *
 * Thread-safe variation of e_source_proxy_get_http_auth_user().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceProxy:http-auth-user
 *
 * Since: 3.12
 **/
gchar *
e_source_proxy_dup_http_auth_user (ESourceProxy *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_proxy_get_http_auth_user (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_proxy_set_http_auth_user:
 * @extension: an #ESourceProxy
 * @http_auth_user: HTTP proxy username
 *
 * Sets the user name to pass as authentication when doing HTTP proxying
 * and #ESourceProxy:http-use-auth is %TRUE.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_http_auth_user (ESourceProxy *extension,
                                   const gchar *http_auth_user)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (http_auth_user, extension->priv->http_auth_user) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->http_auth_user);
	extension->priv->http_auth_user = e_util_strdup_strip (http_auth_user);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "http-auth-user");
}

/**
 * e_source_proxy_get_http_auth_password:
 * @extension: an #ESourceProxy
 *
 * Returns the password to pass as authentication when doing HTTP proxying
 * and #ESourceProxy:http-use-auth is %TRUE.
 *
 * Returns: HTTP proxy password
 *
 * Since: 3.12
 **/
const gchar *
e_source_proxy_get_http_auth_password (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	return extension->priv->http_auth_password;
}

/**
 * e_source_proxy_dup_http_auth_password:
 * @extension: an #ESourceProxy
 *
 * Thread-safe variation of e_source_proxy_get_http_auth_password().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceProxy:http-auth-password
 *
 * Since: 3.12
 **/
gchar *
e_source_proxy_dup_http_auth_password (ESourceProxy *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_proxy_get_http_auth_password (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_proxy_set_http_auth_password:
 * @extension: an #ESourceProxy
 * @http_auth_password: HTTP proxy password
 *
 * Sets the password to pass as authentication when doing HTTP proxying
 * and #ESourceProxy:http-use-auth is %TRUE.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_http_auth_password (ESourceProxy *extension,
                                       const gchar *http_auth_password)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (http_auth_password, extension->priv->http_auth_password) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->http_auth_password);
	extension->priv->http_auth_password = e_util_strdup_strip (http_auth_password);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "http-auth-password");
}

/**
 * e_source_proxy_get_https_host:
 * @extension: an #ESourceProxy
 *
 * Returns the machine name to proxy secure HTTP through when @extension's
 * #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Returns: secure HTTP proxy host name
 *
 * Since: 3.12
 **/
const gchar *
e_source_proxy_get_https_host (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	return extension->priv->https_host;
}

/**
 * e_source_proxy_dup_https_host:
 * @extension: an #ESourceProxy
 *
 * Threads-safe variation of e_source_proxy_get_https_host().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceProxy:https-host
 *
 * Since: 3.12
 **/
gchar *
e_source_proxy_dup_https_host (ESourceProxy *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_proxy_get_https_host (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_proxy_set_https_host:
 * @extension: an #ESourceProxy
 * @https_host: secure HTTP proxy host name
 *
 * Sets the machine name to proxy secure HTTP through when @extension's
 * #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_https_host (ESourceProxy *extension,
                               const gchar *https_host)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (https_host, extension->priv->https_host) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->https_host);
	extension->priv->https_host = e_util_strdup_strip (https_host);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "https-host");
}

/**
 * e_source_proxy_get_https_port:
 * @extension: an #ESourceProxy
 *
 * Returns the port on the machine defined by #ESourceProxy:https-host to proxy
 * through when @extension's #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Returns: secure HTTP proxy port
 *
 * Since: 3.12
 **/
guint16
e_source_proxy_get_https_port (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), 0);

	return extension->priv->https_port;
}

/**
 * e_source_proxy_set_https_port:
 * @extension: an #ESourceProxy
 * @https_port: secure HTTP proxy port
 *
 * Sets the port on the machine defined by #ESourceProxy:https-host to proxy
 * through when @extension's #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_https_port (ESourceProxy *extension,
                               guint16 https_port)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	if (https_port == extension->priv->https_port)
		return;

	extension->priv->https_port = https_port;

	g_object_notify (G_OBJECT (extension), "https-port");
}

/**
 * e_source_proxy_get_socks_host:
 * @extension: an #ESourceProxy
 *
 * Returns the machine name to use as a SOCKS proxy when @extension's
 * #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Returns: SOCKS proxy host name
 *
 * Since: 3.12
 **/
const gchar *
e_source_proxy_get_socks_host (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	return extension->priv->socks_host;
}

/**
 * e_source_proxy_dup_socks_host:
 * @extension: an #ESourceProxy
 *
 * Thread-safe variation of e_source_proxy_get_socks_host().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceProxy:socks-host
 *
 * Since: 3.12
 **/
gchar *
e_source_proxy_dup_socks_host (ESourceProxy *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_proxy_get_socks_host (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_proxy_set_socks_host:
 * @extension: an #ESourceProxy
 * @socks_host: SOCKS proxy host name
 *
 * Sets the machine name to use as a SOCKS proxy when @extension's
 * #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_socks_host (ESourceProxy *extension,
                               const gchar *socks_host)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (socks_host, extension->priv->socks_host) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->socks_host);
	extension->priv->socks_host = e_util_strdup_strip (socks_host);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "socks-host");
}

/**
 * e_source_proxy_get_socks_port:
 * @extension: an #ESourceProxy
 *
 * Returns the port on the machine defined by #ESourceProxy:socks-host to proxy
 * through when @extension's #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Returns: SOCKS proxy port
 *
 * Since: 3.12
 **/
guint16
e_source_proxy_get_socks_port (ESourceProxy *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_PROXY (extension), 0);

	return extension->priv->socks_port;
}

/**
 * e_source_proxy_set_socks_port:
 * @extension: an #ESourceProxy
 * @socks_port: SOCKS proxy port
 *
 * Sets the port on the machine defined by #ESourceProxy:socks-host to proxy
 * through when @extension's #ESourceProxy:method is @E_PROXY_METHOD_MANUAL.
 *
 * Since: 3.12
 **/
void
e_source_proxy_set_socks_port (ESourceProxy *extension,
                               guint16 socks_port)
{
	g_return_if_fail (E_IS_SOURCE_PROXY (extension));

	if (socks_port == extension->priv->socks_port)
		return;

	extension->priv->socks_port = socks_port;

	g_object_notify (G_OBJECT (extension), "socks-port");
}

/**
 * e_source_proxy_lookup_sync:
 * @source: an #ESource
 * @uri: a URI representing the destination to connect to
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Looks into @source's #ESourceProxy extension to determine what proxy,
 * if any, to use to connect to @uri.  The returned proxy URIs are of the
 * same form described by g_proxy_resolver_lookup().
 *
 * The proxy extension's #ESourceProxy:method controls how proxy URIs are
 * determined:
 *
 * When using @E_PROXY_METHOD_DEFAULT, the function will defer to the
 * #GProxyResolver returned by g_proxy_resolver_get_default().
 *
 * When using @E_PROXY_METHOD_MANUAL, the function will configure a
 * #GSimpleProxyResolver from the HTTP, HTTPS, FTP and SOCKS properties,
 * as well as #ESourceProxy:ignore-hosts.
 *
 * When using @E_PROXY_METHOD_AUTO, the function will execute a proxy
 * auto-config (PAC) file at #ESourceProxy:autoconfig-url.
 *
 * When using @E_PROXY_METHOD_NONE, the function will only return
 * <literal>direct://</literal>.
 *
 * If @source does not have an #ESourceProxy extension, the function sets
 * @error to @G_IO_ERROR_NOT_SUPPORTED and returns %NULL.
 *
 * Free the returned proxy URIs with g_strfreev() when finished with them.
 *
 * Returns: (transfer full): a %NULL-terminated array of proxy URIs, or %NULL
 *
 * Since: 3.12
 **/
gchar **
e_source_proxy_lookup_sync (ESource *source,
                            const gchar *uri,
                            GCancellable *cancellable,
                            GError **error)
{
	GProxyResolver *resolver = NULL;
	ESourceProxy *extension;
	EProxyMethod method;
	const gchar *extension_name;
	gchar **proxies;

	g_return_val_if_fail (E_IS_SOURCE (source), NULL);
	g_return_val_if_fail (uri != NULL, NULL);

	extension_name = E_SOURCE_EXTENSION_PROXY;

	if (!e_source_has_extension (source, extension_name)) {
		g_set_error (
			error, G_IO_ERROR,
			G_IO_ERROR_NOT_SUPPORTED,
			_("Source “%s” does not support proxy lookups"),
			e_source_get_display_name (source));
		return NULL;
	}

	extension = e_source_get_extension (source, extension_name);
	method = e_source_proxy_get_method (extension);

	if (method == E_PROXY_METHOD_DEFAULT) {
		resolver = g_proxy_resolver_get_default ();
		if (resolver != NULL)
			g_object_ref (resolver);
	}

	if (method == E_PROXY_METHOD_MANUAL) {
		gchar *ftp_proxy = NULL;
		gchar *http_proxy = NULL;
		gchar *https_proxy = NULL;
		gchar *socks_proxy = NULL;
		gchar **ignore_hosts;
		gchar *host;
		guint16 port;

		host = e_source_proxy_dup_ftp_host (extension);
		port = e_source_proxy_get_ftp_port (extension);
		if (host != NULL && port > 0) {
			ftp_proxy = g_strdup_printf (
				"ftp://%s:%u", host, port);
		}
		g_free (host);

		host = e_source_proxy_dup_http_host (extension);
		port = e_source_proxy_get_http_port (extension);
		if (host != NULL && port > 0) {
			/* This one is a little more complicated. */
			http_proxy = source_proxy_dup_http_proxy (
				extension, host, port);
		}
		g_free (host);

		host = e_source_proxy_dup_https_host (extension);
		port = e_source_proxy_get_https_port (extension);
		if (host != NULL && port > 0) {
			https_proxy = g_strdup_printf (
				"http://%s:%u", host, port);
		}
		g_free (host);

		host = e_source_proxy_dup_socks_host (extension);
		port = e_source_proxy_get_socks_port (extension);
		if (host != NULL && port > 0) {
			socks_proxy = g_strdup_printf (
				"socks://%s:%u", host, port);
		}
		g_free (host);

		ignore_hosts = e_source_proxy_dup_ignore_hosts (extension);
		resolver = g_simple_proxy_resolver_new (NULL, ignore_hosts);
		g_strfreev (ignore_hosts);

		if (ftp_proxy != NULL) {
			g_simple_proxy_resolver_set_uri_proxy (
				G_SIMPLE_PROXY_RESOLVER (resolver),
				"ftp", ftp_proxy);
			g_free (ftp_proxy);
		}

		if (https_proxy != NULL) {
			g_simple_proxy_resolver_set_uri_proxy (
				G_SIMPLE_PROXY_RESOLVER (resolver),
				"https", https_proxy);
			g_free (https_proxy);
		} else if (http_proxy != NULL) {
			g_simple_proxy_resolver_set_uri_proxy (
				G_SIMPLE_PROXY_RESOLVER (resolver),
				"https", http_proxy);
		}

		if (http_proxy != NULL) {
			g_simple_proxy_resolver_set_uri_proxy (
				G_SIMPLE_PROXY_RESOLVER (resolver),
				"http", http_proxy);
			g_free (http_proxy);
		}

		if (socks_proxy != NULL) {
			g_simple_proxy_resolver_set_uri_proxy (
				G_SIMPLE_PROXY_RESOLVER (resolver),
				"socks", socks_proxy);
			g_simple_proxy_resolver_set_default_proxy (
				G_SIMPLE_PROXY_RESOLVER (resolver),
				socks_proxy);
			g_free (socks_proxy);
		}
	}

	if (method == E_PROXY_METHOD_AUTO) {
		proxies = source_proxy_lookup_pacrunner (
			source, uri, cancellable, error);

	} else if (resolver != NULL) {
		proxies = g_proxy_resolver_lookup (
			resolver, uri, cancellable, error);

	} else {
		proxies = source_proxy_direct ();
	}

	g_clear_object (&resolver);

	return proxies;
}

/* Helper for e_source_proxy_lookup() */
static void
source_proxy_lookup_thread (GSimpleAsyncResult *simple,
                            GObject *object,
                            GCancellable *cancellable)
{
	AsyncContext *async_context;
	GError *local_error = NULL;

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	async_context->proxies = e_source_proxy_lookup_sync (
		E_SOURCE (object),
		async_context->uri,
		cancellable, &local_error);

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/**
 * e_source_proxy_lookup:
 * @source: an #ESource
 * @uri: a URI representing the destination to connect to
 * @cancellable: (allow-none): optional #GCancellable object, or %NULL
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request
 *            is satisfied
 * @user_data: (closure): data to pass to the callback function
 *
 * Asynchronously determines what proxy, if any, to use to connect to @uri.
 * See e_source_proxy_lookup_sync() for more details.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_source_proxy_lookup_finish() to get the result of the operation.
 *
 * Since: 3.12
 **/
void
e_source_proxy_lookup (ESource *source,
                       const gchar *uri,
                       GCancellable *cancellable,
                       GAsyncReadyCallback callback,
                       gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (uri != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->uri = g_strdup (uri);

	simple = g_simple_async_result_new (
		G_OBJECT (source), callback,
		user_data, e_source_proxy_lookup);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	g_simple_async_result_run_in_thread (
		simple, source_proxy_lookup_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_source_proxy_lookup_finish:
 * @source: an #ESource
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_source_proxy_lookup().
 *
 * Free the returned proxy URIs with g_strfreev() when finished with them.
 *
 * Returns: (transfer full): a %NULL-terminated array of proxy URIs, or %NULL
 *
 * Since: 3.12
 **/
gchar **
e_source_proxy_lookup_finish (ESource *source,
                              GAsyncResult *result,
                              GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	gchar **proxies;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (source), e_source_proxy_lookup), NULL);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return NULL;

	g_return_val_if_fail (async_context->proxies != NULL, NULL);

	proxies = async_context->proxies;
	async_context->proxies = NULL;

	return proxies;
}

