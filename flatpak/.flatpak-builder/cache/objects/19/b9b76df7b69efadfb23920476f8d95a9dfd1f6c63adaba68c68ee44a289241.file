/*
 * e-source-webdav.h
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
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_WEBDAV_H
#define E_SOURCE_WEBDAV_H

#include <gio/gio.h>
#include <libsoup/soup.h>
#include <libedataserver/e-source-enums.h>
#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_WEBDAV \
	(e_source_webdav_get_type ())
#define E_SOURCE_WEBDAV(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_WEBDAV, ESourceWebdav))
#define E_SOURCE_WEBDAV_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_WEBDAV, ESourceWebdavClass))
#define E_IS_SOURCE_WEBDAV(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_WEBDAV))
#define E_IS_SOURCE_WEBDAV_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_WEBDAV))
#define E_SOURCE_WEBDAV_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_WEBDAV, ESourceWebdavClass))

/**
 * E_SOURCE_EXTENSION_WEBDAV_BACKEND:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceWebdav.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_WEBDAV_BACKEND "WebDAV Backend"

G_BEGIN_DECLS

/* forward declaration */
struct _ENamedParameters;
struct _ESourceRegistry;

typedef struct _ESourceWebdav ESourceWebdav;
typedef struct _ESourceWebdavClass ESourceWebdavClass;
typedef struct _ESourceWebdavPrivate ESourceWebdavPrivate;

/**
 * ESourceWebdav:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceWebdav {
	/*< private >*/
	ESourceExtension parent;
	ESourceWebdavPrivate *priv;
};

struct _ESourceWebdavClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_webdav_get_type	(void) G_GNUC_CONST;
gboolean	e_source_webdav_get_avoid_ifmatch
						(ESourceWebdav *extension);
void		e_source_webdav_set_avoid_ifmatch
						(ESourceWebdav *extension,
						 gboolean avoid_ifmatch);
gboolean	e_source_webdav_get_calendar_auto_schedule
						(ESourceWebdav *extension);
void		e_source_webdav_set_calendar_auto_schedule
						(ESourceWebdav *extension,
						 gboolean calendar_auto_schedule);
const gchar *	e_source_webdav_get_display_name
						(ESourceWebdav *extension);
gchar *		e_source_webdav_dup_display_name
						(ESourceWebdav *extension);
void		e_source_webdav_set_display_name
						(ESourceWebdav *extension,
						 const gchar *display_name);
const gchar *	e_source_webdav_get_color	(ESourceWebdav *extension);
gchar *		e_source_webdav_dup_color	(ESourceWebdav *extension);
void		e_source_webdav_set_color	(ESourceWebdav *extension,
						 const gchar *color);
const gchar *	e_source_webdav_get_email_address
						(ESourceWebdav *extension);
gchar *		e_source_webdav_dup_email_address
						(ESourceWebdav *extension);
void		e_source_webdav_set_email_address
						(ESourceWebdav *extension,
						 const gchar *email_address);
const gchar *	e_source_webdav_get_resource_path
						(ESourceWebdav *extension);
gchar *		e_source_webdav_dup_resource_path
						(ESourceWebdav *extension);
void		e_source_webdav_set_resource_path
						(ESourceWebdav *extension,
						 const gchar *resource_path);
const gchar *	e_source_webdav_get_resource_query
						(ESourceWebdav *extension);
gchar *		e_source_webdav_dup_resource_query
						(ESourceWebdav *extension);
void		e_source_webdav_set_resource_query
						(ESourceWebdav *extension,
						 const gchar *resource_query);
const gchar *	e_source_webdav_get_ssl_trust	(ESourceWebdav *extension);
gchar *		e_source_webdav_dup_ssl_trust	(ESourceWebdav *extension);
void		e_source_webdav_set_ssl_trust	(ESourceWebdav *extension,
						 const gchar *ssl_trust);
SoupURI *	e_source_webdav_dup_soup_uri	(ESourceWebdav *extension);
void		e_source_webdav_set_soup_uri	(ESourceWebdav *extension,
						 SoupURI *soup_uri);
void		e_source_webdav_update_ssl_trust
						(ESourceWebdav *extension,
						 const gchar *host,
						 GTlsCertificate *cert,
						 ETrustPromptResponse response);
ETrustPromptResponse
		e_source_webdav_verify_ssl_trust
						(ESourceWebdav *extension,
						 const gchar *host,
						 GTlsCertificate *cert,
						 GTlsCertificateFlags cert_errors);
void		e_source_webdav_unset_temporary_ssl_trust
						(ESourceWebdav *extension);

G_END_DECLS

#endif /* E_SOURCE_WEBDAV_H */
