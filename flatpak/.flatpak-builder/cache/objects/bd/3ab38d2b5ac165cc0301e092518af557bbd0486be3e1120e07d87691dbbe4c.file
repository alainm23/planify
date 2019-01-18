/*
 * e-source-authentication.h
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

#ifndef E_SOURCE_AUTHENTICATION_H
#define E_SOURCE_AUTHENTICATION_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_AUTHENTICATION \
	(e_source_authentication_get_type ())
#define E_SOURCE_AUTHENTICATION(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_AUTHENTICATION, ESourceAuthentication))
#define E_SOURCE_AUTHENTICATION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_AUTHENTICATION, ESourceAuthenticationClass))
#define E_IS_SOURCE_AUTHENTICATION(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_AUTHENTICATION))
#define E_IS_SOURCE_AUTHENTICATION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_AUTHENTICATION))
#define E_SOURCE_AUTHENTICATION_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_AUTHENTICATION, ESourceAuthenticationClass))

/**
 * E_SOURCE_EXTENSION_AUTHENTICATION:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceAuthentication.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_AUTHENTICATION "Authentication"

G_BEGIN_DECLS

typedef struct _ESourceAuthentication ESourceAuthentication;
typedef struct _ESourceAuthenticationClass ESourceAuthenticationClass;
typedef struct _ESourceAuthenticationPrivate ESourceAuthenticationPrivate;

/**
 * ESourceAuthentication:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceAuthentication {
	/*< private >*/
	ESourceExtension parent;
	ESourceAuthenticationPrivate *priv;
};

struct _ESourceAuthenticationClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_authentication_get_type
					(void) G_GNUC_CONST;
gboolean	e_source_authentication_required
					(ESourceAuthentication *extension);
GSocketConnectable *
		e_source_authentication_ref_connectable
					(ESourceAuthentication *extension);
const gchar *	e_source_authentication_get_host
					(ESourceAuthentication *extension);
gchar *		e_source_authentication_dup_host
					(ESourceAuthentication *extension);
void		e_source_authentication_set_host
					(ESourceAuthentication *extension,
					 const gchar *host);
const gchar *	e_source_authentication_get_method
					(ESourceAuthentication *extension);
gchar *		e_source_authentication_dup_method
					(ESourceAuthentication *extension);
void		e_source_authentication_set_method
					(ESourceAuthentication *extension,
					 const gchar *method);
guint16		e_source_authentication_get_port
					(ESourceAuthentication *extension);
void		e_source_authentication_set_port
					(ESourceAuthentication *extension,
					 guint16 port);
const gchar *	e_source_authentication_get_proxy_uid
					(ESourceAuthentication *extension);
gchar *		e_source_authentication_dup_proxy_uid
					(ESourceAuthentication *extension);
void		e_source_authentication_set_proxy_uid
					(ESourceAuthentication *extension,
					 const gchar *proxy_uid);
gboolean	e_source_authentication_get_remember_password
					(ESourceAuthentication *extension);
void		e_source_authentication_set_remember_password
					(ESourceAuthentication *extension,
					 gboolean remember_password);
const gchar *	e_source_authentication_get_user
					(ESourceAuthentication *extension);
gchar *		e_source_authentication_dup_user
					(ESourceAuthentication *extension);
void		e_source_authentication_set_user
					(ESourceAuthentication *extension,
					 const gchar *user);
const gchar *	e_source_authentication_get_credential_name
					(ESourceAuthentication *extension);
gchar *		e_source_authentication_dup_credential_name
					(ESourceAuthentication *extension);
void		e_source_authentication_set_credential_name
					(ESourceAuthentication *extension,
					 const gchar *credential_name);

G_END_DECLS

#endif /* E_SOURCE_AUTHENTICATION_H */
