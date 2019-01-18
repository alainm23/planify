/*
 * e-source-security.h
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

#ifndef E_SOURCE_SECURITY_H
#define E_SOURCE_SECURITY_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_SECURITY \
	(e_source_security_get_type ())
#define E_SOURCE_SECURITY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_SECURITY, ESourceSecurity))
#define E_SOURCE_SECURITY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_SECURITY, ESourceSecurityClass))
#define E_IS_SOURCE_SECURITY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_SECURITY))
#define E_IS_SOURCE_SECURITY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_SECURITY))
#define E_SOURCE_SECURITY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_SECURITY, ESourceSecurityClass))

/**
 * E_SOURCE_EXTENSION_SECURITY:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceSecurity.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_SECURITY "Security"

G_BEGIN_DECLS

typedef struct _ESourceSecurity ESourceSecurity;
typedef struct _ESourceSecurityClass ESourceSecurityClass;
typedef struct _ESourceSecurityPrivate ESourceSecurityPrivate;

/**
 * ESourceSecurity:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceSecurity {
	/*< private >*/
	ESourceExtension parent;
	ESourceSecurityPrivate *priv;
};

struct _ESourceSecurityClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_security_get_type	(void) G_GNUC_CONST;
const gchar *	e_source_security_get_method	(ESourceSecurity *extension);
gchar *		e_source_security_dup_method	(ESourceSecurity *extension);
void		e_source_security_set_method	(ESourceSecurity *extension,
						 const gchar *method);
gboolean	e_source_security_get_secure	(ESourceSecurity *extension);
void		e_source_security_set_secure	(ESourceSecurity *extension,
						 gboolean secure);

G_END_DECLS

#endif /* E_SOURCE_SECURITY_H */
