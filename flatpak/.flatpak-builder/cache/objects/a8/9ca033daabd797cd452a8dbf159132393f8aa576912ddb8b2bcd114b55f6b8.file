/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 *          Veerapuram Varadhan <vvaradhan@novell.com>
 */

#include "evolution-data-server-config.h"

#include <string.h>
#include <stdlib.h>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#ifndef IN6_ARE_ADDR_EQUAL
#define IN6_ARE_ADDR_EQUAL(a, b) \
    (memcmp ((gpointer)(a), (gpointer)(b), sizeof (struct in6_addr)) == 0)
#endif
#else
#include <netinet/in.h>
#include <sys/socket.h>
#endif

#include <libsoup/soup-address.h>
#include <libsoup/soup-uri.h>
#include "e-proxy.h"

#define E_PROXY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_PROXY, EProxyPrivate))

G_DEFINE_TYPE (EProxy, e_proxy, G_TYPE_OBJECT)

/* Debug */
#define d(x)

enum ProxyType {
	PROXY_TYPE_SYSTEM = 0,
	PROXY_TYPE_NO_PROXY,
	PROXY_TYPE_MANUAL,
	PROXY_TYPE_AUTO_URL /* no auto-proxy at the moment */
};

typedef enum {
	E_PROXY_KEY_MODE,
	E_PROXY_KEY_USE_HTTP_PROXY,
	E_PROXY_KEY_HTTP_HOST,
	E_PROXY_KEY_HTTP_PORT,
	E_PROXY_KEY_HTTP_USE_AUTH,
	E_PROXY_KEY_HTTP_AUTH_USER,
	E_PROXY_KEY_HTTP_AUTH_PWD,
	E_PROXY_KEY_HTTP_IGNORE_HOSTS,
	E_PROXY_KEY_HTTPS_HOST,
	E_PROXY_KEY_HTTPS_PORT,
	E_PROXY_KEY_SOCKS_HOST,
	E_PROXY_KEY_SOCKS_PORT,
	E_PROXY_KEY_AUTOCONFIG_URL
} EProxyKey;

struct _EProxyPrivate {
	SoupURI *uri_http, *uri_https, *uri_socks;
	GSList * ign_hosts;	/* List of hostnames. (Strings)		*/
	GSList * ign_addrs;	/* List of hostaddrs. (ProxyHostAddrs)	*/
	gboolean use_proxy;	/* Is our-proxy enabled? */
	enum ProxyType type;
	GSettings *evolution_proxy_settings;
	GSettings *proxy_settings;
	GSettings *proxy_http_settings;
	GSettings *proxy_https_settings;
	GSettings *proxy_socks_settings;
};

/* Enum definition is copied from gnome-vfs/modules/http-proxy.c */
typedef enum {
	PROXY_IPV4 = 4,
	PROXY_IPV6 = 6
} ProxyAddrType;

typedef struct {
	ProxyAddrType type;	/* Specifies whether IPV4 or IPV6 */
	gpointer  addr;		/* Either in_addr * or in6_addr * */
	gpointer  mask;		/* Either in_addr * or in6_addr * */
} ProxyHostAddr;

/* Signals.  */
enum {
	CHANGED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL] = { 0 };

/* Forward declarations.  */

static void	ipv6_network_addr	(const struct in6_addr *addr,
					 const struct in6_addr *mask,
					 struct in6_addr *res);

static void
ep_free_proxy_host_addr (ProxyHostAddr *host)
{
	if (host) {
		if (host->addr) {
			g_free (host->addr);
			host->addr = NULL;
		}
		if (host->mask) {
			g_free (host->mask);
			host->mask = NULL;
		}
		g_free (host);
	}
}

static gboolean
ep_read_key_boolean (EProxy *proxy,
                     EProxyKey key)
{
	gboolean res = FALSE;

	g_return_val_if_fail (E_IS_PROXY (proxy), FALSE);

	switch (key) {
	case E_PROXY_KEY_USE_HTTP_PROXY:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			/* it's not used in the UI, thus behave like always set to TRUE */
			res = TRUE; /* g_settings_get_boolean (proxy->priv->proxy_http_settings, "enabled"); */
		else
			res = g_settings_get_boolean (proxy->priv->evolution_proxy_settings, "use-http-proxy");
		break;
	case E_PROXY_KEY_HTTP_USE_AUTH:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			res = g_settings_get_boolean (proxy->priv->proxy_http_settings, "use-authentication");
		else
			res = g_settings_get_boolean (proxy->priv->evolution_proxy_settings, "use-authentication");
		break;
	default:
		g_warn_if_reached ();
		break;
	}

	return res;
}

static gint
ep_read_key_int (EProxy *proxy,
                 EProxyKey key)
{
	gint res = 0;

	g_return_val_if_fail (E_IS_PROXY (proxy), 0);

	switch (key) {
	case E_PROXY_KEY_HTTP_PORT:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			res = g_settings_get_int (proxy->priv->proxy_http_settings, "port");
		else
			res = g_settings_get_int (proxy->priv->evolution_proxy_settings, "http-port");
		break;
	case E_PROXY_KEY_HTTPS_PORT:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			res = g_settings_get_int (proxy->priv->proxy_https_settings, "port");
		else
			res = g_settings_get_int (proxy->priv->evolution_proxy_settings, "secure-port");
		break;
	case E_PROXY_KEY_SOCKS_PORT:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			res = g_settings_get_int (proxy->priv->proxy_socks_settings, "port");
		else
			res = g_settings_get_int (proxy->priv->evolution_proxy_settings, "socks-port");
		break;
	default:
		g_warn_if_reached ();
		break;
	}

	return res;
}

/* free returned pointer with g_free() */
static gchar *
ep_read_key_string (EProxy *proxy,
                    EProxyKey key)
{
	gchar *res = NULL;

	g_return_val_if_fail (E_IS_PROXY (proxy), NULL);

	switch (key) {
	case E_PROXY_KEY_MODE:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			res = g_settings_get_string (proxy->priv->proxy_settings, "mode");
		else
			g_warn_if_reached ();
		break;
	case E_PROXY_KEY_HTTP_HOST:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			res = g_settings_get_string (proxy->priv->proxy_http_settings, "host");
		else
			res = g_settings_get_string (proxy->priv->evolution_proxy_settings, "http-host");
		break;
	case E_PROXY_KEY_HTTPS_HOST:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			res = g_settings_get_string (proxy->priv->proxy_https_settings, "host");
		else
			res = g_settings_get_string (proxy->priv->evolution_proxy_settings, "secure-host");
		break;
	case E_PROXY_KEY_SOCKS_HOST:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			res = g_settings_get_string (proxy->priv->proxy_socks_settings, "host");
		else
			res = g_settings_get_string (proxy->priv->evolution_proxy_settings, "socks-host");
		break;
	case E_PROXY_KEY_HTTP_AUTH_USER:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			res = g_settings_get_string (proxy->priv->proxy_http_settings, "authentication-user");
		else
			res = g_settings_get_string (proxy->priv->evolution_proxy_settings, "authentication-user");
		break;
	case E_PROXY_KEY_HTTP_AUTH_PWD:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			res = g_settings_get_string (proxy->priv->proxy_http_settings, "authentication-password");
		else
			res = g_settings_get_string (proxy->priv->evolution_proxy_settings, "authentication-password");
		break;
	case E_PROXY_KEY_AUTOCONFIG_URL:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			res = g_settings_get_string (proxy->priv->proxy_settings, "autoconfig-url");
		else
			res = g_settings_get_string (proxy->priv->evolution_proxy_settings, "autoconfig-url");
		break;
	default:
		g_warn_if_reached ();
		break;
	}

	return res;
}

/* list of newly allocated strings, use g_free() for each member and free list itself too */
static GSList *
ep_read_key_list (EProxy *proxy,
                  EProxyKey key)
{
	GSList *res = NULL;
	gchar **strv = NULL;

	g_return_val_if_fail (E_IS_PROXY (proxy), NULL);

	switch (key) {
	case E_PROXY_KEY_HTTP_IGNORE_HOSTS:
		if (proxy->priv->type == PROXY_TYPE_SYSTEM)
			strv = g_settings_get_strv (proxy->priv->proxy_settings, "ignore-hosts");
		else
			strv = g_settings_get_strv (proxy->priv->evolution_proxy_settings, "ignore-hosts");
		break;
	default:
		g_warn_if_reached ();
		break;
	}

	if (strv) {
		gint ii;

		for (ii = 0; strv && strv[ii]; ii++) {
			res = g_slist_prepend (res, g_strdup (strv[ii]));
		}

		g_strfreev (strv);

		res = g_slist_reverse (res);
	}

	return res;
}

static gboolean
ep_is_in_ignored (EProxy *proxy,
                  const gchar *host)
{
	EProxyPrivate *priv;
	GSList * l;
	gchar *hn;

	g_return_val_if_fail (proxy != NULL, FALSE);
	g_return_val_if_fail (host != NULL, FALSE);

	priv = proxy->priv;
	if (!priv->ign_hosts)
		return FALSE;

	hn = g_ascii_strdown (host, -1);

	for (l = priv->ign_hosts; l; l = l->next) {
		if (*((gchar *) l->data) == '*') {
			if (g_str_has_suffix (hn, ((gchar *) l->data) + 1)) {
				g_free (hn);
				return TRUE;
			}
		} else if (strcmp (hn, l->data) == 0) {
				g_free (hn);
				return TRUE;
		}
	}
	g_free (hn);

	return FALSE;
}

static gboolean
ep_need_proxy_http (EProxy *proxy,
                    const gchar *host)
{
	SoupAddress *addr = NULL;
	EProxyPrivate *priv = proxy->priv;
	ProxyHostAddr *p_addr = NULL;
	GSList *l;
	guint status;

	/* check for ignored first */
	if (ep_is_in_ignored (proxy, host))
		return FALSE;

	addr = soup_address_new (host, 0);
	status = soup_address_resolve_sync (addr, NULL);
	if (status == SOUP_STATUS_OK) {
		gint addr_len;
		struct sockaddr * so_addr = NULL;

		so_addr = soup_address_get_sockaddr (addr, &addr_len);

		/* This will never happen, since we have already called
		 * soup_address_resolve_sync ().
		*/
		if (!so_addr) {
			g_object_unref (addr);
			return TRUE;
		}

		if (so_addr->sa_family == AF_INET) {
			struct in_addr in, *mask, *addr_in;

			in = ((struct sockaddr_in *) so_addr)->sin_addr;
			for (l = priv->ign_addrs; l; l = l->next) {
				p_addr = (ProxyHostAddr *) l->data;
				if (p_addr->type == PROXY_IPV4) {
					addr_in = ((struct in_addr *) p_addr->addr);
					mask = ((struct in_addr *) p_addr->mask);
					if ((in.s_addr & mask->s_addr) == addr_in->s_addr) {
						d (g_print ("Host [%s] doesn't require proxy\n", host));
						g_object_unref (addr);
						return FALSE;
					}
				}
			}
		} else {
			struct in6_addr in6, net6;
			struct in_addr *addr_in, *mask;

			in6 = ((struct sockaddr_in6 *) so_addr)->sin6_addr;
			for (l = priv->ign_addrs; l; l = l->next) {
				p_addr = (ProxyHostAddr *) l->data;
				ipv6_network_addr (&in6, (struct in6_addr *) p_addr->mask, &net6);
				if (p_addr->type == PROXY_IPV6) {
					if (IN6_ARE_ADDR_EQUAL (&net6, (struct in6_addr *) p_addr->addr)) {
						d (g_print ("Host [%s] doesn't require proxy\n", host));
						g_object_unref (addr);
						return FALSE;
					}
				} else if (p_addr->type == PROXY_IPV6 &&
					   IN6_IS_ADDR_V4MAPPED (&net6)) {
					guint32 v4addr;

					addr_in = ((struct in_addr *) p_addr->addr);
					mask = ((struct in_addr *) p_addr->mask);

					v4addr = net6.s6_addr[12] << 24
						| net6.s6_addr[13] << 16
						| net6.s6_addr[14] << 8
						| net6.s6_addr[15];
					if ((v4addr & mask->s_addr) != addr_in->s_addr) {
						d (g_print ("Host [%s] doesn't require proxy\n", host));
						g_object_unref (addr);
						return FALSE;
					}
				}
			}
		}
	}

	d (g_print ("%s needs a proxy to connect to internet\n", host));
	g_object_unref (addr);

	return TRUE;
}

static gboolean
ep_need_proxy_https (EProxy *proxy,
                     const gchar *host)
{
	/* Can we share ignore list from HTTP at all? */
	return !ep_is_in_ignored (proxy, host);
}

static gboolean
ep_need_proxy_socks (EProxy *proxy,
                     const gchar *host)
{
	/* Can we share ignore list from HTTP at all? */
	return !ep_is_in_ignored (proxy, host);
}

/* Apply a prefix-notation @netmask to the given @addr_in, as described in
 * http://tools.ietf.org/html/rfc4632#section-3.1 */
static gboolean
ep_manipulate_ipv4 (ProxyHostAddr *host_addr,
                    struct in_addr *addr_in,
                    gchar *netmask)
{
	gboolean has_error = FALSE;
	struct in_addr *addr, *mask;

	if (!addr_in)
		return has_error;

	host_addr->type = PROXY_IPV4;
	addr = g_new0 (struct in_addr, 1);
	memcpy (addr, addr_in, sizeof (struct in_addr));
	mask = g_new0 (struct in_addr, 1);

	if (netmask) {
		gchar *endptr;
		gint width = strtol (netmask, &endptr, 10);

		if (*endptr != '\0' || width < 0 || width > 32) {
			has_error = TRUE;
			mask->s_addr = 0xFFFFFFFF;
		} else if (width == 32) {
			mask->s_addr = 0;
			addr->s_addr = 0;
		} else {
			mask->s_addr = htonl (~0U << width);
			addr->s_addr &= mask->s_addr;
		}
	} else {
		mask->s_addr = 0xFFFFFFFF;
	}

	host_addr->addr = addr;
	host_addr->mask = mask;

	return has_error;
}

static void
ipv6_network_addr (const struct in6_addr *addr,
                   const struct in6_addr *mask,
                   struct in6_addr *res)
{
	gint i;

	for (i = 0; i < 16; ++i) {
		res->s6_addr[i] = addr->s6_addr[i] & mask->s6_addr[i];
	}
}

static gboolean
ep_manipulate_ipv6 (ProxyHostAddr *host_addr,
                    struct in6_addr *addr_in6,
                    gchar *netmask)
{
	gboolean has_error = FALSE;
	struct in6_addr *addr, *mask;
	gint i;

	if (!addr_in6)
		return has_error;

	host_addr->type = PROXY_IPV6;

	addr = g_new0 (struct in6_addr, 1);
	mask = g_new0 (struct in6_addr, 1);

	for (i = 0; i < 16; ++i) {
		addr->s6_addr[i] = addr_in6->s6_addr[i];
	}
	if (netmask) {
		gchar *endptr;
		gint width = strtol (netmask, &endptr, 10);

		if (*endptr != '\0' || width < 0 || width > 128) {
			has_error = TRUE;
		}
		for (i = 0; i < 16; ++i) {
			mask->s6_addr[i] = 0;
		}
		for (i = 0; i < width / 8; i++) {
			mask->s6_addr[i] = 0xff;
		}
		mask->s6_addr[i] = (0xff << (8 - width % 8)) & 0xff;
		ipv6_network_addr (addr, mask, addr);
	} else {
		for (i = 0; i < 16; ++i) {
			mask->s6_addr[i] = 0xff;
		}
	}

	host_addr->addr = addr;
	host_addr->mask = mask;

	return has_error;
}

static void
ep_parse_ignore_host (gpointer data,
                      gpointer user_data)
{
	EProxy * proxy = (EProxy *) user_data;
	EProxyPrivate * priv = NULL;
	SoupAddress *addr;
	guint status;
	gchar *input, *netmask, *hostname;
	gboolean has_error = FALSE;

	if (!proxy || !proxy->priv)
		return;

	priv = proxy->priv;
	input = (gchar *) data;

	if ((netmask = strrchr (input, '/')) != NULL) {
		hostname = g_strndup (input, netmask - input);
		++netmask;
	} else {
		hostname = g_ascii_strdown (input, -1);
	}

	addr = soup_address_new (hostname, 0);
	status = soup_address_resolve_sync (addr, NULL);
	if (status == SOUP_STATUS_OK) {
		ProxyHostAddr *host_addr;
		gint addr_len;
		struct sockaddr * so_addr = NULL;

		host_addr = g_new0 (ProxyHostAddr, 1);

		so_addr = soup_address_get_sockaddr (addr, &addr_len);

		/* This will never happen, since we have already called
		 * soup_address_resolve_sync ().
		*/
		if (!so_addr) {
			ep_free_proxy_host_addr (host_addr);
			goto error;
		}

		if (so_addr->sa_family == AF_INET)
			has_error = ep_manipulate_ipv4 (
				host_addr,
				&((struct sockaddr_in *) so_addr)->sin_addr,
				netmask);
		else
			has_error = ep_manipulate_ipv6 (
				host_addr,
				&((struct sockaddr_in6 *) so_addr)->sin6_addr,
				netmask);

		if (!has_error) {
			priv->ign_addrs = g_slist_append (
				priv->ign_addrs, host_addr);
			priv->ign_hosts = g_slist_append (
				priv->ign_hosts, hostname);
		} else {
			ep_free_proxy_host_addr (host_addr);
			g_free (hostname);
		}
	} else {
		d (g_print ("Unable to resolve %s\n", hostname));
		priv->ign_hosts = g_slist_append (priv->ign_hosts, hostname);
	}
 error:
	g_object_unref (addr);
}

static gboolean
ep_change_uri (SoupURI **soup_uri,
               const gchar *uri)
{
	gboolean changed = FALSE;

	g_return_val_if_fail (soup_uri != NULL, FALSE);

	if (!uri || !*uri) {
		if (*soup_uri) {
			soup_uri_free (*soup_uri);
			*soup_uri = NULL;
			changed = TRUE;
		}
	} else if (*soup_uri) {
		gchar *old = soup_uri_to_string (*soup_uri, FALSE);

		if (old && *old) {
			gint len = strlen (old);

			/* remove ending slash, if there */
			if (old[len - 1] == '/')
				old[len - 1] = 0;
		}

		changed = old && uri && g_ascii_strcasecmp (old, uri) != 0;
		if (changed) {
			soup_uri_free (*soup_uri);
			*soup_uri = soup_uri_new (uri);
		}

		g_free (old);
	} else {
		*soup_uri = soup_uri_new (uri);
		changed = TRUE;
	}

	return changed;
}

static gchar *
update_proxy_uri (const gchar *uri,
                  const gchar *proxy_user,
                  const gchar *proxy_pw)
{
	gchar *res, *user = NULL, *pw = NULL;
	gboolean is_https;

	g_return_val_if_fail (uri != NULL, NULL);

	if (proxy_user && *proxy_user) {
		user = soup_uri_encode (proxy_user, ":/;#@?\\");
		if (proxy_pw)
			pw = soup_uri_encode (proxy_pw, ":/;#@?\\");
	}

	if (!user)
		return g_strdup (uri);

	/*  here can be only http or https and nothing else */
	is_https = g_str_has_prefix (uri, "https://");

	res = g_strdup_printf (
		"%s://%s%s%s@%s",
		is_https ? "https" : "http",
		user,
		pw ? ":" : "",
		pw ? pw : "",
		uri + strlen ("http://") + (is_https ? 1 : 0));

	g_free (user);
	g_free (pw);

	return res;
}

static void
ep_set_proxy (EProxy *proxy,
              gboolean regen_ign_host_list)
{
	gchar *proxy_server, *uri_http = NULL, *uri_https = NULL, *uri_socks = NULL;
	gint proxy_port, old_type;
	EProxyPrivate * priv = proxy->priv;
	GSList *ignore;
	gboolean changed = FALSE, sys_manual = TRUE;

	old_type = priv->type;
	priv->type = g_settings_get_int (priv->evolution_proxy_settings, "proxy-type");
	if (priv->type > PROXY_TYPE_AUTO_URL)
		priv->type = PROXY_TYPE_SYSTEM;
	changed = priv->type != old_type;

	if (priv->type == PROXY_TYPE_SYSTEM) {
		gchar *mode = ep_read_key_string (proxy, E_PROXY_KEY_MODE);

		/* supporting only manual system proxy setting */
		sys_manual = mode && g_str_equal (mode, "manual");

		g_free (mode);
	}

	priv->use_proxy = ep_read_key_boolean (proxy, E_PROXY_KEY_USE_HTTP_PROXY);
	if (!priv->use_proxy || priv->type == PROXY_TYPE_NO_PROXY || !sys_manual) {
		changed = ep_change_uri (&priv->uri_http, NULL) || changed;
		changed = ep_change_uri (&priv->uri_https, NULL) || changed;
		changed = ep_change_uri (&priv->uri_socks, NULL) || changed;
		goto emit_signal;
	}

	proxy_server = ep_read_key_string (proxy, E_PROXY_KEY_HTTP_HOST);
	proxy_port = ep_read_key_int (proxy, E_PROXY_KEY_HTTP_PORT);
	if (proxy_server != NULL && *proxy_server && !g_ascii_isspace (*proxy_server)) {
		if (proxy_port > 0)
			uri_http = g_strdup_printf ("http://%s:%d", proxy_server, proxy_port);
		else
			uri_http = g_strdup_printf ("http://%s", proxy_server);
	} else
		uri_http = NULL;
	g_free (proxy_server);
	d (g_print ("ep_set_proxy: uri_http: %s\n", uri_http));

	proxy_server = ep_read_key_string (proxy, E_PROXY_KEY_HTTPS_HOST);
	proxy_port = ep_read_key_int (proxy, E_PROXY_KEY_HTTPS_PORT);
	if (proxy_server != NULL && *proxy_server && !g_ascii_isspace (*proxy_server)) {
		if (proxy_port > 0)
			uri_https = g_strdup_printf ("https://%s:%d", proxy_server, proxy_port);
		else
			uri_https = g_strdup_printf ("https://%s", proxy_server);
	} else
		uri_https = NULL;
	g_free (proxy_server);
	d (g_print ("ep_set_proxy: uri_https: %s\n", uri_https));

	proxy_server = ep_read_key_string (proxy, E_PROXY_KEY_SOCKS_HOST);
	proxy_port = ep_read_key_int (proxy, E_PROXY_KEY_SOCKS_PORT);
	if (proxy_server != NULL && *proxy_server && !g_ascii_isspace (*proxy_server)) {
		if (proxy_port > 0)
			uri_socks = g_strdup_printf ("socks://%s:%d", proxy_server, proxy_port);
		else
			uri_socks = g_strdup_printf ("socks://%s", proxy_server);
	} else
		uri_socks = NULL;
	g_free (proxy_server);
	d (g_print ("ep_set_proxy: uri_socks: %s\n", uri_socks));

	if (regen_ign_host_list) {
		if (priv->ign_hosts) {
			g_slist_foreach (priv->ign_hosts, (GFunc) g_free, NULL);
			g_slist_free (priv->ign_hosts);
			priv->ign_hosts = NULL;
		}

		if (priv->ign_addrs) {
			g_slist_foreach (priv->ign_addrs, (GFunc) ep_free_proxy_host_addr, NULL);
			g_slist_free (priv->ign_addrs);
			priv->ign_addrs = NULL;
		}

		ignore = ep_read_key_list (proxy, E_PROXY_KEY_HTTP_IGNORE_HOSTS);
		if (ignore) {
			g_slist_foreach (ignore, (GFunc) ep_parse_ignore_host, proxy);
			g_slist_foreach (ignore, (GFunc) g_free, NULL);
			g_slist_free (ignore);
		}
	}

	if (ep_read_key_boolean (proxy, E_PROXY_KEY_HTTP_USE_AUTH)) {
		gchar *proxy_user, *proxy_pw, *tmp = NULL, *tmps = NULL;

		proxy_user = ep_read_key_string (proxy, E_PROXY_KEY_HTTP_AUTH_USER);
		proxy_pw = ep_read_key_string (proxy, E_PROXY_KEY_HTTP_AUTH_PWD);

		if (uri_http && proxy_user && *proxy_user) {
			tmp = uri_http;
			uri_http = update_proxy_uri (uri_http, proxy_user, proxy_pw);
		}

		if (uri_https && proxy_user && *proxy_user) {
			tmps = uri_https;
			uri_https = update_proxy_uri (uri_https, proxy_user, proxy_pw);
		}

		g_free (proxy_user);
		g_free (proxy_pw);
		g_free (tmp);
		g_free (tmps);
	}

	changed = ep_change_uri (&priv->uri_http, uri_http) || changed;
	changed = ep_change_uri (&priv->uri_https, uri_https) || changed;
	changed = ep_change_uri (&priv->uri_socks, uri_socks) || changed;

 emit_signal:
	d (g_print (
		"%s: changed:%d "
		"uri_http: %s; "
		"uri_https: %s; "
		"uri_socks: %s\n",
		G_STRFUNC, changed ? 1 : 0,
		uri_http ? uri_http : "[null]",
		uri_https ? uri_https : "[null]",
		uri_socks ? uri_socks : "[null]"));
	if (changed)
		g_signal_emit (proxy, signals[CHANGED], 0);

	g_free (uri_http);
	g_free (uri_https);
	g_free (uri_socks);
}

static void
ep_evo_proxy_changed_cb (GSettings *settings,
                         const gchar *key,
                         EProxy *proxy)
{
	EProxyPrivate *priv;

	g_return_if_fail (E_IS_PROXY (proxy));

	priv = proxy->priv;

	d (g_print ("%s: proxy settings changed, key '%s'\n", G_STRFUNC, key ? key : "NULL"));
	if (g_strcmp0 (key, "proxy-type") == 0) {
		ep_set_proxy (proxy, TRUE);
	} else if (priv->type == PROXY_TYPE_SYSTEM) {
		return;
	}

	ep_set_proxy (proxy, g_strcmp0 (key, "ignore-hosts") == 0);
}

static void
ep_sys_proxy_changed_cb (GSettings *settings,
                         const gchar *key,
                         EProxy *proxy)
{
	g_return_if_fail (proxy != NULL);

	if (proxy->priv->type != PROXY_TYPE_SYSTEM)
		return;

	ep_set_proxy (proxy, g_strcmp0 (key, "ignore-hosts") == 0);
}

static void
ep_sys_proxy_http_changed_cb (GSettings *settings,
                              const gchar *key,
                              EProxy *proxy)
{
	g_return_if_fail (proxy != NULL);

	if (proxy->priv->type != PROXY_TYPE_SYSTEM)
		return;

	ep_set_proxy (proxy, FALSE);
}

static void
ep_sys_proxy_https_changed_cb (GSettings *settings,
                               const gchar *key,
                               EProxy *proxy)
{
	g_return_if_fail (proxy != NULL);

	if (proxy->priv->type != PROXY_TYPE_SYSTEM)
		return;

	ep_set_proxy (proxy, FALSE);
}

static void
ep_sys_proxy_socks_changed_cb (GSettings *settings,
                               const gchar *key,
                               EProxy *proxy)
{
	g_return_if_fail (proxy != NULL);

	if (proxy->priv->type != PROXY_TYPE_SYSTEM)
		return;

	ep_set_proxy (proxy, FALSE);
}

static void
e_proxy_dispose (GObject *object)
{
	EProxy *proxy;
	EProxyPrivate *priv;

	proxy = E_PROXY (object);
	priv = proxy->priv;

	if (priv->evolution_proxy_settings) {
		g_signal_handlers_disconnect_by_func (priv->evolution_proxy_settings, ep_evo_proxy_changed_cb, proxy);
		g_object_unref (priv->evolution_proxy_settings);
		priv->evolution_proxy_settings = NULL;
	}

	if (priv->proxy_settings) {
		g_signal_handlers_disconnect_by_func (priv->proxy_settings, ep_sys_proxy_changed_cb, proxy);
		g_object_unref (priv->proxy_settings);
		priv->proxy_settings = NULL;
	}

	if (priv->proxy_http_settings) {
		g_signal_handlers_disconnect_by_func (priv->proxy_http_settings, ep_sys_proxy_http_changed_cb, proxy);
		g_object_unref (priv->proxy_http_settings);
		priv->proxy_http_settings = NULL;
	}

	if (priv->proxy_https_settings) {
		g_signal_handlers_disconnect_by_func (priv->proxy_https_settings, ep_sys_proxy_https_changed_cb, proxy);
		g_object_unref (priv->proxy_https_settings);
		priv->proxy_https_settings = NULL;
	}

	if (priv->proxy_socks_settings) {
		g_signal_handlers_disconnect_by_func (priv->proxy_socks_settings, ep_sys_proxy_socks_changed_cb, proxy);
		g_object_unref (priv->proxy_socks_settings);
		priv->proxy_socks_settings = NULL;
	}

	if (priv->uri_http)
		soup_uri_free (priv->uri_http);

	if (priv->uri_https)
		soup_uri_free (priv->uri_https);

	if (priv->uri_socks)
		soup_uri_free (priv->uri_socks);

	g_slist_foreach (priv->ign_hosts, (GFunc) g_free, NULL);
	g_slist_free (priv->ign_hosts);

	g_slist_foreach (priv->ign_addrs, (GFunc) ep_free_proxy_host_addr, NULL);
	g_slist_free (priv->ign_addrs);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_proxy_parent_class)->dispose (object);
}

static void
e_proxy_class_init (EProxyClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EProxyPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = e_proxy_dispose;

	/**
	 * EProxy::changed:
	 * @proxy: the #EProxy which emitted the signal
	 *
	 * Emitted when proxy settings changes.
	 **/
	signals[CHANGED] = g_signal_new (
		"changed",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (EProxyClass, changed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);

}

static void
e_proxy_init (EProxy *proxy)
{
	proxy->priv = E_PROXY_GET_PRIVATE (proxy);

	proxy->priv->type = PROXY_TYPE_SYSTEM;

	proxy->priv->evolution_proxy_settings = g_settings_new ("org.gnome.evolution.shell.network-config");
	proxy->priv->proxy_settings = g_settings_new ("org.gnome.system.proxy");
	proxy->priv->proxy_http_settings = g_settings_get_child (proxy->priv->proxy_settings, "http");
	proxy->priv->proxy_https_settings = g_settings_get_child (proxy->priv->proxy_settings, "https");
	proxy->priv->proxy_socks_settings = g_settings_get_child (proxy->priv->proxy_settings, "socks");

	g_signal_connect (proxy->priv->evolution_proxy_settings, "changed", G_CALLBACK (ep_evo_proxy_changed_cb), proxy);
	g_signal_connect (proxy->priv->proxy_settings, "changed", G_CALLBACK (ep_sys_proxy_changed_cb), proxy);
	g_signal_connect (proxy->priv->proxy_http_settings, "changed", G_CALLBACK (ep_sys_proxy_http_changed_cb), proxy);
	g_signal_connect (proxy->priv->proxy_https_settings, "changed", G_CALLBACK (ep_sys_proxy_https_changed_cb), proxy);
	g_signal_connect (proxy->priv->proxy_socks_settings, "changed", G_CALLBACK (ep_sys_proxy_socks_changed_cb), proxy);
}

/**
 * e_proxy_new:
 *
 * Returns: (transfer full): a new instance of an #EProxy
 *
 * Since: 2.24
 **/
EProxy *
e_proxy_new (void)
{
	return g_object_new (E_TYPE_PROXY, NULL);
}

/**
 * e_proxy_setup_proxy:
 * @proxy: an #EProxy
 *
 * Sets up internal structure members and reads the proxy settings.
 *
 * Since: 2.24
 **/
void
e_proxy_setup_proxy (EProxy *proxy)
{
	g_return_if_fail (E_IS_PROXY (proxy));

	/* We get the evolution-shell proxy keys here
	 * set soup up to use the proxy,
	 * and listen to any changes */

	/* XXX Why can't we do this automatically in constructed() ? */

	ep_set_proxy (proxy, TRUE);
}

/**
 * e_proxy_peek_uri_for:
 * @proxy: an #EProxy
 * @uri: a URI
 *
 * Returns: (transfer none): A proxy URI (as a #SoupURI) which the given @uri
 *   may use, based on its scheme
 *
 * Since: 2.26
 **/
SoupURI *
e_proxy_peek_uri_for (EProxy *proxy,
                      const gchar *uri)
{
	SoupURI *res = NULL;
	SoupURI *soup_uri;

	g_return_val_if_fail (E_IS_PROXY (proxy), NULL);
	g_return_val_if_fail (uri != NULL, NULL);

	soup_uri = soup_uri_new (uri);
	if (soup_uri == NULL)
		return NULL;

	if (soup_uri->scheme == SOUP_URI_SCHEME_HTTP)
		res = proxy->priv->uri_http;
	else if (soup_uri->scheme == SOUP_URI_SCHEME_HTTPS)
		res = proxy->priv->uri_https;
	else if (soup_uri->scheme && g_ascii_strcasecmp (soup_uri->scheme, "socks") == 0)
		res = proxy->priv->uri_socks;

	soup_uri_free (soup_uri);

	return res;
}

/**
 * e_proxy_require_proxy_for_uri:
 * @proxy: an #EProxy
 * @uri: a URI
 *
 * Returns: Whether the @uri requires proxy to connect to it
 *
 * Since: 2.24
 **/
gboolean
e_proxy_require_proxy_for_uri (EProxy *proxy,
                               const gchar *uri)
{
	SoupURI *soup_uri = NULL;
	gboolean need_proxy = FALSE;

	g_return_val_if_fail (E_IS_PROXY (proxy), FALSE);
	g_return_val_if_fail (uri != NULL, FALSE);

	if (!proxy->priv->use_proxy || proxy->priv->type == PROXY_TYPE_NO_PROXY) {
		d (g_print ("[%s] don't need a proxy to connect to internet\n", uri));
		return FALSE;
	}

	soup_uri = soup_uri_new (uri);
	if (soup_uri == NULL)
		return FALSE;

	if (soup_uri->scheme == SOUP_URI_SCHEME_HTTP)
		need_proxy = ep_need_proxy_http (proxy, soup_uri->host);
	else if (soup_uri->scheme == SOUP_URI_SCHEME_HTTPS)
		need_proxy = ep_need_proxy_https (proxy, soup_uri->host);
	else if (soup_uri->scheme && g_ascii_strcasecmp (soup_uri->scheme, "socks") == 0)
		need_proxy = ep_need_proxy_socks (proxy, soup_uri->host);

	soup_uri_free (soup_uri);

	return need_proxy;
}
