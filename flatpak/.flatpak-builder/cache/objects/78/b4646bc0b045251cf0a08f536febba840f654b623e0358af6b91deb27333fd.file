/*
 * evolution-source-registry-migrate-proxies.c
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

#include <glib/gi18n-lib.h>

#include <libebackend/libebackend.h>

#define NETWORK_CONFIG_SCHEMA_ID "org.gnome.evolution.shell.network-config"

#include "evolution-source-registry-methods.h"

void
evolution_source_registry_migrate_proxies (ESourceRegistryServer *server)
{
	GSettings *settings;
	ESource *source;
	ESourceProxy *extension;
	EProxyMethod method;
	const gchar *extension_name;
	const gchar *user_dir;
	gboolean system_proxy_exists;
	gboolean v_bool;
	gchar *filename;
	gchar *string;
	gchar **strv;
	gint v_int;

	g_return_if_fail (E_IS_SOURCE_REGISTRY_SERVER (server));

	/* If a 'system-proxy.source' file already exists, leave it alone.
	 * Otherwise, populate the built-in proxy profile from Evolution's
	 * so-called "network-config" in GSettings. */

	user_dir = e_server_side_source_get_user_dir ();
	filename = g_build_filename (user_dir, "system-proxy.source", NULL);
	system_proxy_exists = g_file_test (filename, G_FILE_TEST_IS_REGULAR);
	g_free (filename);

	if (system_proxy_exists)
		return;

	source = e_source_registry_server_ref_source (server, "system-proxy");
	g_return_if_fail (source != NULL);

	extension_name = E_SOURCE_EXTENSION_PROXY;
	extension = e_source_get_extension (source, extension_name);

	settings = g_settings_new (NETWORK_CONFIG_SCHEMA_ID);

	switch (g_settings_get_int (settings, "proxy-type")) {
		case 1:
			method = E_PROXY_METHOD_NONE;
			break;
		case 2:
			method = E_PROXY_METHOD_MANUAL;
			break;
		default:
			method = E_PROXY_METHOD_DEFAULT;
			break;
	}

	e_source_proxy_set_method (extension, method);

	/* Skip empty strings / zero values from GSettings and
	 * defer to the default values defined by ESourceProxy. */

	string = g_settings_get_string (settings, "autoconfig-url");
	if (string != NULL && *string != '\0')
		e_source_proxy_set_autoconfig_url (extension, string);
	g_free (string);

	strv = g_settings_get_strv (settings, "ignore-hosts");
	if (strv != NULL && *strv != NULL)
		e_source_proxy_set_ignore_hosts (
			extension, (const gchar * const *) strv);
	g_strfreev (strv);

	string = g_settings_get_string (settings, "http-host");
	if (string != NULL && *string != '\0')
		e_source_proxy_set_http_host (extension, string);
	g_free (string);

	v_int = g_settings_get_int (settings, "http-port");
	if (v_int > 0)
		e_source_proxy_set_http_port (extension, (guint16) v_int);

	v_bool = g_settings_get_boolean (settings, "use-authentication");
	e_source_proxy_set_http_use_auth (extension, v_bool);

	string = g_settings_get_string (settings, "authentication-user");
	if (string != NULL && *string != '\0')
		e_source_proxy_set_http_auth_user (extension, string);
	g_free (string);

	string = g_settings_get_string (settings, "authentication-password");
	if (string != NULL && *string != '\0')
		e_source_proxy_set_http_auth_password (extension, string);
	g_free (string);

	string = g_settings_get_string (settings, "secure-host");
	if (string != NULL && *string != '\0')
		e_source_proxy_set_https_host (extension, string);
	g_free (string);

	v_int = g_settings_get_int (settings, "secure-port");
	if (v_int > 0)
		e_source_proxy_set_https_port (extension, (guint16) v_int);

	string = g_settings_get_string (settings, "socks-host");
	if (string != NULL && *string != '\0')
		e_source_proxy_set_socks_host (extension, string);
	g_free (string);

	v_int = g_settings_get_int (settings, "socks-port");
	if (v_int > 0)
		e_source_proxy_set_socks_port (extension, (guint16) v_int);

	g_object_unref (settings);
}

