/*
 * e-source-ldap.h
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

#ifndef E_SOURCE_LDAP_H
#define E_SOURCE_LDAP_H

#include <libedataserver/e-source-extension.h>
#include <libedataserver/e-source-enums.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_LDAP \
	(e_source_ldap_get_type ())
#define E_SOURCE_LDAP(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_LDAP, ESourceLDAP))
#define E_SOURCE_LDAP_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_LDAP, ESourceLDAPClass))
#define E_IS_SOURCE_LDAP(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_LDAP))
#define E_IS_SOURCE_LDAP_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_LDAP))
#define E_SOURCE_LDAP_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_LDAP, ESourceLDAPClass))

/**
 * E_SOURCE_EXTENSION_LDAP_BACKEND:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceLDAP.  This is also used as a group name in key files.
 *
 * Since: 3.18
 **/
#define E_SOURCE_EXTENSION_LDAP_BACKEND "LDAP Backend"

G_BEGIN_DECLS

typedef struct _ESourceLDAP ESourceLDAP;
typedef struct _ESourceLDAPClass ESourceLDAPClass;
typedef struct _ESourceLDAPPrivate ESourceLDAPPrivate;

struct _ESourceLDAP {
	/*< private >*/
	ESourceExtension parent;
	ESourceLDAPPrivate *priv;
};

struct _ESourceLDAPClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_ldap_get_type		(void);
ESourceLDAPAuthentication
		e_source_ldap_get_authentication
						(ESourceLDAP *extension);
void		e_source_ldap_set_authentication
						(ESourceLDAP *extension,
						 ESourceLDAPAuthentication authentication);
gboolean	e_source_ldap_get_can_browse	(ESourceLDAP *extension);
void		e_source_ldap_set_can_browse	(ESourceLDAP *extension,
						 gboolean can_browse);
const gchar *	e_source_ldap_get_filter	(ESourceLDAP *extension);
gchar *		e_source_ldap_dup_filter	(ESourceLDAP *extension);
void		e_source_ldap_set_filter	(ESourceLDAP *extension,
						 const gchar *filter);
guint		e_source_ldap_get_limit		(ESourceLDAP *extension);
void		e_source_ldap_set_limit		(ESourceLDAP *extension,
						 guint limit);
const gchar *	e_source_ldap_get_root_dn	(ESourceLDAP *extension);
gchar *		e_source_ldap_dup_root_dn	(ESourceLDAP *extension);
void		e_source_ldap_set_root_dn	(ESourceLDAP *extension,
						 const gchar *root_dn);
ESourceLDAPScope
		e_source_ldap_get_scope		(ESourceLDAP *extension);
void		e_source_ldap_set_scope		(ESourceLDAP *extension,
						 ESourceLDAPScope scope);
ESourceLDAPSecurity
		e_source_ldap_get_security	(ESourceLDAP *extension);
void		e_source_ldap_set_security	(ESourceLDAP *extension,
						 ESourceLDAPSecurity security);

G_END_DECLS

#endif /* E_SOURCE_LDAP_H */
