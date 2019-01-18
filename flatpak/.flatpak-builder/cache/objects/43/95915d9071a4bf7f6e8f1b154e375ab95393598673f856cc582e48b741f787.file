/*
 * e-source-proxy.h
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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#define "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_PROXY_H
#define E_SOURCE_PROXY_H

#include <libedataserver/e-source-enums.h>
#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_PROXY \
	(e_source_proxy_get_type ())
#define E_SOURCE_PROXY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_PROXY, ESourceProxy))
#define E_SOURCE_PROXY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_PROXY, ESourceProxyClass))
#define E_IS_SOURCE_PROXY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_PROXY))
#define E_IS_SOURCE_PROXY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_PROXY))
#define E_SOURCE_PROXY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_PROXY, ESourceProxyClass))

/**
 * E_SOURCE_EXTENSION_PROXY:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceProxy.  This is also used as a group name in key files.
 *
 * Since: 3.12
 **/
#define E_SOURCE_EXTENSION_PROXY "Proxy"

G_BEGIN_DECLS

typedef struct _ESourceProxy ESourceProxy;
typedef struct _ESourceProxyClass ESourceProxyClass;
typedef struct _ESourceProxyPrivate ESourceProxyPrivate;

/**
 * ESourceProxy:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.12
 **/
struct _ESourceProxy {
	/*< private >*/
	ESourceExtension parent;
	ESourceProxyPrivate *priv;
};

struct _ESourceProxyClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_proxy_get_type		(void) G_GNUC_CONST;
EProxyMethod	e_source_proxy_get_method	(ESourceProxy *extension);
void		e_source_proxy_set_method	(ESourceProxy *extension,
						 EProxyMethod method);
const gchar *	e_source_proxy_get_autoconfig_url
						(ESourceProxy *extension);
gchar *		e_source_proxy_dup_autoconfig_url
						(ESourceProxy *extension);
void		e_source_proxy_set_autoconfig_url
						(ESourceProxy *extension,
						 const gchar *autoconfig_url);
const gchar * const *
		e_source_proxy_get_ignore_hosts	(ESourceProxy *extension);
gchar **	e_source_proxy_dup_ignore_hosts	(ESourceProxy *extension);
void		e_source_proxy_set_ignore_hosts	(ESourceProxy *extension,
						 const gchar * const *ignore_hosts);
const gchar *	e_source_proxy_get_ftp_host	(ESourceProxy *extension);
gchar *		e_source_proxy_dup_ftp_host	(ESourceProxy *extension);
void		e_source_proxy_set_ftp_host	(ESourceProxy *extension,
						 const gchar *ftp_host);
guint16		e_source_proxy_get_ftp_port	(ESourceProxy *extension);
void		e_source_proxy_set_ftp_port	(ESourceProxy *extension,
						 guint16 ftp_port);
const gchar *	e_source_proxy_get_http_host	(ESourceProxy *extension);
gchar *		e_source_proxy_dup_http_host	(ESourceProxy *extension);
void		e_source_proxy_set_http_host	(ESourceProxy *extension,
						 const gchar *http_host);
guint16		e_source_proxy_get_http_port	(ESourceProxy *extension);
void		e_source_proxy_set_http_port	(ESourceProxy *extension,
						 guint16 http_port);
gboolean	e_source_proxy_get_http_use_auth
						(ESourceProxy *extension);
void		e_source_proxy_set_http_use_auth
						(ESourceProxy *extension,
						 gboolean http_use_auth);
const gchar *	e_source_proxy_get_http_auth_user
						(ESourceProxy *extension);
gchar *		e_source_proxy_dup_http_auth_user
						(ESourceProxy *extension);
void		e_source_proxy_set_http_auth_user
						(ESourceProxy *extension,
						 const gchar *http_auth_user);
const gchar *	e_source_proxy_get_http_auth_password
						(ESourceProxy *extension);
gchar *		e_source_proxy_dup_http_auth_password
						(ESourceProxy *extension);
void		e_source_proxy_set_http_auth_password
						(ESourceProxy *extension,
						 const gchar *http_auth_password);
const gchar *	e_source_proxy_get_https_host	(ESourceProxy *extension);
gchar *		e_source_proxy_dup_https_host	(ESourceProxy *extension);
void		e_source_proxy_set_https_host	(ESourceProxy *extension,
						 const gchar *https_host);
guint16		e_source_proxy_get_https_port	(ESourceProxy *extension);
void		e_source_proxy_set_https_port	(ESourceProxy *extension,
						 guint16 https_port);
const gchar *	e_source_proxy_get_socks_host	(ESourceProxy *extension);
gchar *		e_source_proxy_dup_socks_host	(ESourceProxy *extension);
void		e_source_proxy_set_socks_host	(ESourceProxy *extension,
						 const gchar *socks_host);
guint16		e_source_proxy_get_socks_port	(ESourceProxy *extension);
void		e_source_proxy_set_socks_port	(ESourceProxy *extension,
						 guint16 socks_port);

gchar **	e_source_proxy_lookup_sync	(ESource *source,
						 const gchar *uri,
						 GCancellable *cancellable,
						 GError **error);
void		e_source_proxy_lookup		(ESource *source,
						 const gchar *uri,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gchar **	e_source_proxy_lookup_finish	(ESource *source,
						 GAsyncResult *result,
						 GError **error);

G_END_DECLS

#endif /* E_SOURCE_PROXY_H */

